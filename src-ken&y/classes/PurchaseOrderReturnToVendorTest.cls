/**
 * This class contains unit tests for validating the behavior of Apex classes
 *  PurchaseOrderReceiptExt
 *
 */
@isTest
public class PurchaseOrderReturnToVendorTest {
        
    //Tests for PurchaseOrderReturnToVendorExt class
    public class testData{
        Testfuel t = new TestFuel();
        List<Period__c> periodList = t.periodList;
       
        Source_Document_Approval__c sd = new Source_Document_Approval__c();{
            sd.Name = 'Purchase Order';
            sd.Allow_Approval__c = true;
            insert sd;
        }

        Purchase_Order__c p1, p2;
        {
            
            p1  = new Purchase_Order__c();
            p2  = new Purchase_Order__c();
            
            p1.Company__c = t.company.id;
            p1.Supplier__c = t.supplier.id;
            p1.Remit_To_Supplier__c =  t.remittosupplier.id; 
            p1.Currency__c = TestFuel.currencyUSD.id;           
            p2.Company__c = t.company.id;
            p2.Supplier__c = t.supplier.id;
            p2.Remit_To_Supplier__c =  t.remittosupplier.id;
            p2.Currency__c = TestFuel.currencyUSD.id;           
            p1.Type__c = 'Production';
            p2.Type__c = 'Production';
            
            //insert p1;insert p2;
            insert new List<Purchase_Order__c>{p1, p2};
        }
        
        List< Purchase_Order__c > poList = new List< Purchase_Order__c >();
        { 
            poList.add( p1 );
            poList.add( p2 );
        }
        Purchase_Order_Line__c pol1, pol2;
        {
            pol1 = new Purchase_Order_Line__c();
            pol2 = new Purchase_Order_Line__c();
            
            pol1.Company__c = t.company.id;
            pol1.Purchase_Order__c = p1.id;
            pol1.Item__c = t.itemlist[0].id;
            pol1.Order_Quantity__c = 500;
            pol1.Unit_Price__c = 2;
            pol1.Date_Added__c = system.today();
            pol1.Need_Date__c = system.today();
            pol1.Line__c = 1;
            pol1.Supplier__c = t.supplier.id;
            pol1.Delivery_Facility__c = t.facility.id;
            pol1.Delivery_Location__c = t.location.id;
            //insert pol1;
            
            pol2.Company__c = t.company.id;
            pol2.Purchase_Order__c = p2.id;
            pol2.Item__c = t.itemList[0].id;
            pol2.Order_Quantity__c = 500;
            pol2.Unit_Price__c = 2;
            pol2.Date_Added__c = system.today();
            pol2.Need_Date__c = system.today();
            pol2.Line__c = 2;
            pol2.Supplier__c = t.supplier.id;
            //insert pol2;
            
            insert new List<Purchase_Order_Line__c>{pol1, pol2};
        }

    }
    
    public static testMethod void poReturnToVendorTest(){
        
        testData t = new testData();
        
        test.startTest();
        
        List< Purchase_Order__c > poTestList = new List< Purchase_Order__c >();
        ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(poTestList); 
        setcon.setSelected(poTestList);
        PurchaseOrderReturnToVendorExt rtv = new PurchaseOrderReturnToVendorExt(setCon);
        
        rtv.retrievePOLines();
        
        system.assert(ApexPages.getMessages().size() ==1);
        
        poTestList = t.poList;
        setCon = new Apexpages.StandardSetController(poTestList); 
        setcon.setSelected(poTestList);
        rtv = new PurchaseOrderReturnToVendorExt(setCon);
        
        rtv.retrievePOLines();
        
        system.assert( rtv.POLinesForDisplay.size() == 0, rtv.POLinesForDisplay.size() ); // displays no lines because quantity received is 0 on both lines
        
        rtv.cancel();
        
        t.pol1.Quantity_Received__c = 500;
        t.pol2.Quantity_Received__c = 500;
        
        update t.pol1;
        update t.pol2;
        
        rtv = new PurchaseOrderReturnToVendorExt(setCon);
        
        rtv.retrievePOLines();
        
        system.assert( rtv.POLinesForDisplay.size() == 2, rtv.POLinesForDisplay.size() ); // displays two lines available for return
        
        rtv.POLinesForDisplay[0].newPolRecord.Quantity_Returned_To_Supplier__c = 400;
        rtv.POLinesForDisplay[0].newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c = 100;
        rtv.POLinesForDisplay[0].newPolRecord.Need_Date__c = system.today()+2;
        
        rtv.POLinesForDisplay[1].newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c = 500;
        
        rtv.save();
        
        test.stopTest();
        
        system.assert( rtv.newPOLines.size() == 1 ); // we returned to supplier not for credit only on one line
        //KNDY-5486 RTV process should default the delivery location on the new po
        system.assertNotEquals(Null,rtv.newPOLinesForDisplay[0].Delivery_Location__c);
        system.assertEquals(t.pol1.Delivery_Location__c,rtv.newPOLinesForDisplay[0].Delivery_Location__c);
        system.assert( rtv.oldPOLines.size() == 2 ); // 2 lines were updated with the updated return quantities
        system.assert( rtv.creditMemos.size() == 2 ); // credit memos for each type of return on two lines
        system.assertEquals( rtv.newPOHeader.Need_Date__c, system.today()+2); //PTP-100 Need date on the new PO should be considered from the RTV Screen
        system.assertNotEquals(t.pol1.Need_Date__c, rtv.newPOHeader.Need_Date__c);
        List<id> cmIds = new List<id>();
        for (Supplier_Invoice__c cm: rtv.creditMemos){
            system.assert(cm.Status__c == 'Incomplete');
            cmIds.add(cm.id);
        }
        //KNDY-4036 : The supplier on the RTV Credit Memo should be the remit to supplier of PO
        List<Supplier_Invoice__c> cmsCreated = [Select id, name, Supplier_Invoice__c, Supplier__c, AutoNumber__c from Supplier_Invoice__c where id in :cmIds];
        for (Supplier_Invoice__c cm: cmsCreated){
            system.assertEquals(cm.Supplier__c, rtv.POLinesForDisplay[0].newPolRecord.Purchase_Order__r.Remit_To_Supplier__c);
            system.assertEquals(cm.Supplier_Invoice__c, 'RTV-'+cm.AutoNumber__c);
        }
        //PTP-101 Receipt Line from RTV process should have the delivery location and facility from the PO
        List<Receipt_Line__c> rLineList = new List<Receipt_Line__c>();
        rLineList = [select id, name, location__c, facility__c from Receipt_Line__c where purchase_order__c = :t.p1.id];
        for (Receipt_Line__c rl :  rLineList){
            system.assertEquals(rl.location__c , t.pol1.Delivery_Location__c);
            system.assertEquals(rl.facility__c, t.pol1.Delivery_Facility__c);
        }
   }
   //PTP-288 Create new Replacement PO on RTV
   //Original PO quantity is 500 and Qty Received = 100
   //Expected Results : New PO to be created, Existing PO Quantity Still Due = 400
   public static testMethod void NewReplacementPOonRTVTest(){
        
        testData t = new testData();
        
        Supplier__c supplier = new Supplier__c(); 
        supplier.Name = t.t.company.Name + ' Supplier-RTV';
        supplier.Company__c = t.t.company.ID;
        supplier.Tax_ID__c = 'tax ID';
        supplier.Address__c = t.t.account.ID;  // remittoaccount ?? TODO 
        supplier.Status__c = 'Active';
        supplier.FOB_Term__c = t.t.fobTerm.id;
        supplier.Type__c = 'Purchasing';
        supplier.RecordTypeId = t.t.SupplierRecordTypes.get('Purchase_From');
        supplier.Remit_To__c =  t.t.remittosupplier.id;
        supplier.Default_Receiving_Tolerance__c = 3;
        supplier.Create_RTV_PO__c = true;
        supplier.Currency__c = TestFuel.currencyUSD.id;
        insert supplier;
        
        t.p1.Supplier__c = supplier.id;
        update t.poList;
        
        // Insert uom conversion
        UOM_Conversion_Details__c uomConversion = new UOM_Conversion_Details__c();
        uomConversion.Name=String.valueOf(t.t.itemList[1].Id).substring(3,15) + string.valueof(t.t.uomList[1].Id).substring(3,15) + string.valueof(t.t.itemList[1].Stocking_UOM__c).substring(3,15);
        uomConversion.UOM_1__c = t.t.uomList[1].Id;
        uomConversion.UOM_1_Quantity__c=12;
        uomConversion.UOM_2__c = t.t.itemList[1].Stocking_UOM__c;
        uomConversion.UOM_2_Quantity__c=1;
        uomConversion.Item__c=t.t.itemList[1].Id;
        upsert uomConversion;
        
        test.startTest();
        
        List< Purchase_Order__c > poTestList = new List< Purchase_Order__c >();
        ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(poTestList); 
        setcon.setSelected(poTestList);
        PurchaseOrderReturnToVendorExt rtv = new PurchaseOrderReturnToVendorExt(setCon);
        
        rtv.retrievePOLines();
        
        system.assert(ApexPages.getMessages().size() ==1);
        
        poTestList = t.poList;
        setCon = new Apexpages.StandardSetController(poTestList); 
        setcon.setSelected(poTestList);
        rtv = new PurchaseOrderReturnToVendorExt(setCon);
        


        t.pol1.Quantity_Received__c = 100; 

        //Change item to purchased item and set uom on poline
        t.pol1.Item__c = t.t.itemList[1].Id;
        t.pol1.Purchase_UOM__c =t.t.uomList[1].Id;// uom different from item`s purchasing uom

        update t.pol1;
        
        rtv = new PurchaseOrderReturnToVendorExt(setCon);
    	
    	rtv.retrievePOLines();
    	
    	system.assertEquals( 1, rtv.POLinesForDisplay.size() ); 
    	
    	rtv.POLinesForDisplay[0].newPolRecord.Quantity_Returned_To_Supplier__c = 10; 
    	rtv.POLinesForDisplay[0].newPolRecord.Need_Date__c = system.today()+2;
    	
    	rtv.save();
    	
    	test.stopTest();
    	
    	system.assertEquals( rtv.newPOLines.size(),  1 ); 
    	system.assertNotEquals(Null,rtv.newPOLinesForDisplay[0].Delivery_Location__c);
    	system.assertEquals( rtv.newPOHeader.Need_Date__c, system.today()+2); 
    	system.assertNotEquals(t.pol1.Need_Date__c, rtv.newPOHeader.Need_Date__c);
    	
		 //KNDY-11328	 On the newly created POline, Purchase UOM should be same as POLine that was rtv-ed
    	// and should be different from Item`s Purchasing UOM
    	system.assertEquals(rtv.newPOLinesForDisplay[0].Purchase_UOM__c, t.pol1.Purchase_UOM__c);
    	system.assertNotEquals(rtv.newPOLinesForDisplay[0].Purchase_UOM__c,t.t.itemList[1].Purchasing_UOM__c);
		//KNDY-14213
		Purchase_Order_Line__c newPOLine = [select id, name, Order_Quantity__c, Quantity_Matched__c, Invoice_Status__c from Purchase_Order_Line__c where id = :rtv.newPOLinesForDisplay[0].id];
        system.assertEquals(newPOLine.Invoice_Status__c, 'Closed for Invoicing');
        system.assertEquals(newPOLine.Quantity_Matched__c, newPOLine.Order_Quantity__c);

        Purchase_Order_Line__c oldPOLine = [select id, name, Order_Quantity__c, Quantity_Received__c, Quantity_Still_Due__c, Quantity_Returned_to_Supplier__c from Purchase_Order_Line__c where id = :t.pol1.id];
        system.assertEquals(oldPOLine.Quantity_Still_Due__c, oldPOLine.Order_Quantity__c - oldPOLine.Quantity_Received__c + oldPOLine.Quantity_Returned_to_Supplier__c); //410

   }
   
   //KNDY-11234 Create new Credit Memo on RTV for Credit
   //Original PO quantity is 500 , Qty Received = 100, Return for Credit 10
   //Expected Results : New Credit Memo is created
   public static testMethod void returnForCreditPOonRTVTest(){
        
        testData t = new testData();
        
        Supplier__c supplier = new Supplier__c(); 
        supplier.Name = t.t.company.Name + ' Supplier-RTV';
        supplier.Company__c = t.t.company.ID;
        supplier.Tax_ID__c = 'tax ID';
        supplier.Address__c = t.t.account.ID; 
        supplier.Status__c = 'Active';
        supplier.FOB_Term__c = t.t.fobTerm.id;
        supplier.Type__c = 'Purchasing';
        supplier.RecordTypeId = t.t.SupplierRecordTypes.get('Purchase_From');
        supplier.Remit_To__c =  t.t.remittosupplier.id;
        supplier.Default_Receiving_Tolerance__c = 3;
        supplier.Create_RTV_PO__c = true;
        supplier.Create_RTV_Credit_Memo__c = true;
        insert supplier;
        
        t.p1.Supplier__c = supplier.id;
        update t.poList;
        test.startTest();
        
        List< Purchase_Order__c > poTestList = new List< Purchase_Order__c >();
        poTestList = t.poList;
        ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(poTestList); 
        setCon = new Apexpages.StandardSetController(poTestList); 
        setcon.setSelected(poTestList);
        PurchaseOrderReturnToVendorExt rtv = new PurchaseOrderReturnToVendorExt(setCon);
        rtv = new PurchaseOrderReturnToVendorExt(setCon);
        
        t.pol1.Quantity_Received__c = 100;
        //Change item to purchased item and set uom on poline
        t.pol1.Item__c = t.t.itemList[1].Id;
        t.pol1.Purchase_UOM__c =t.t.uomList[8].Id;
        update t.pol1;
        
        rtv = new PurchaseOrderReturnToVendorExt(setCon);
        
        rtv.retrievePOLines();
        
        system.assertEquals( 1, rtv.POLinesForDisplay.size() ); 
        
        rtv.POLinesForDisplay[0].newPolRecord.Quantity_Returned_to_Supplier_for_Credit__c = 10;
        system.assertNotEquals( null, rtv.POLinesForDisplay[0].newPolRecord.Purchase_UOM__c);
        
        rtv.save();
        
        test.stopTest();
        
        system.assertEquals( rtv.creditMemos.size(),  1 ); 
        system.assertEquals( rtv.creditMemoLines.size(),  1 );
        system.assertNotEquals(null, rtv.creditMemoLines[0].Purchase_UOM__c);
        system.assertNotEquals(null, rtv.creditMemoLines[0].Id);
        system.assertEquals( rtv.creditMemoLines[0].Purchase_UOM__c, rtv.POLinesForDisplay[0].newPolRecord.Purchase_UOM__c); 
   }

   public static testMethod void poRTV_CheckReceiptLineExtdCostCalculation(){ //PTP-283
        
        testData t = new testData();
        
        test.startTest();
        
        List< Purchase_Order__c > poTestList = new List< Purchase_Order__c >();
        poTestList = t.poList;
        t.pol1.Quantity_Received__c = 500;
        t.pol2.Quantity_Received__c = 500;
        
        update t.pol1;
        update t.pol2;
        
        ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(poTestList); 
        setcon.setSelected(poTestList);
        PurchaseOrderReturnToVendorExt rtv = new PurchaseOrderReturnToVendorExt(setCon);
        
        rtv.retrievePOLines();
        
        system.assert( rtv.POLinesForDisplay.size() == 2, rtv.POLinesForDisplay.size() ); // displays two lines available for return
        system.debug('Period open: ' + PeriodService.getAvailablePeriodOpen());
        rtv.POLinesForDisplay[0].newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c = 100;
        rtv.save();
        
        test.stopTest();
        Purchase_Order_Line__c pol = [select id, name, unit_price__c, Quantity_Returned_To_Supplier_For_Credit__c, Quantity_Returned_To_Supplier__c from Purchase_Order_Line__c where id =:t.pol1.id];
        
        List<Receipt_Line__c> rLineList = new List<Receipt_Line__c>();
        rLineList = [select id, name, Extended_Cost__c, Unit_Price__c from Receipt_Line__c where purchase_order__c = :t.p1.id];
        
        for (Receipt_Line__c rl :  rLineList){
            system.assert(rl.Extended_Cost__c != 0, 'Extended cost is zero');
            system.assert(rl.Extended_Cost__c != (rl.Unit_Price__c * pol.Quantity_Returned_To_Supplier_For_Credit__c), 'Extended cost on receipt line matches Extended price calculation');
        }
   }   
   public static testMethod void PORTV_save(){ //PTP-298
        
        testData t = new testData();
        
        test.startTest();
        
        List< Purchase_Order__c > poTestList = new List< Purchase_Order__c >();
        poTestList = t.poList;
        t.pol1.Quantity_Received__c = 400;
        update t.pol1;
        
        
        ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(poTestList); 
        setcon.setSelected(poTestList);
        PurchaseOrderReturnToVendorExt rtv = new PurchaseOrderReturnToVendorExt(setCon);
        
        rtv.retrievePOLines();
        
        system.assert( rtv.POLinesForDisplay.size() == 1, rtv.POLinesForDisplay.size() ); 
        rtv.save();
      
        test.stopTest();
        system.assert(ApexPages.getMessages().size() ==1);
        system.assert( ApexPages.getMessages()[0].getDetail()  == 'Quantity to return must be specified with a value greater than zero.', ApexPages.getMessages());
       
   }
   
   //PTP-635 RTV should not pick up lines of type 2 way matching
   public static testMethod void PORTV_2WayMatchCheck(){ 
        
        testData t = new testData();
        
        test.startTest();
        
        List< Purchase_Order__c > poTestList = new List< Purchase_Order__c >();
        poTestList = t.poList;
        t.pol1.Quantity_Received__c = 400;
        t.pol1.Invoice_Matching__c = 'Two Way';
        update t.pol1;
        
        
        ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(poTestList); 
        setcon.setSelected(poTestList);
        PurchaseOrderReturnToVendorExt rtv = new PurchaseOrderReturnToVendorExt(setCon);
        
        rtv.retrievePOLines();
        
        system.assert( rtv.POLinesForDisplay.size() == 1, rtv.POLinesForDisplay.size() );  //KNDY-11056
      
        test.stopTest();
       
   }
}