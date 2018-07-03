/** 
 * @description test method for various purchase order triggers and controllers and service class
 */
@isTest 
public with sharing class PurchaseOrderTest {
    @testSetup static void testSetupforPOTest() { 
        TestFuel data = new TestFuel(); 
        // these asserts cause TestFuelQuery to insert data
        system.assert(      
            data.company != null &&
            data.supplier != null &&
            data.purchaseOrder != null && 
            data.purchaseOrderLines != null &&
            data.remitToSupplier != null &&
            data.itemList != null &&
            data.ItemNoClassType != null &&
            data.facility2 != null &&
            data.location2 != null &&
            data.location != null &&
            data.cashGL != null &&
            data.fobTerm != null &&
            data.terms != null 

        );
    }
    
    private static Purchase_Order__c fetchPO( id poid )  { 
        return [ Select id,Company__c, Supplier__c, Need_Date__c,Delivery_Location__c, SystemModStamp, (Select Id, IsDeleted, Name, Purchase_Order__c, Company__c, Date_Added__c,  SystemModStamp,
                                            Date_Closed__c, Date_Last_Changed__c, Description__c, Item__c, Latest_Promise_Date__c, Line_Value__c, Line__c,  Supplier__c,
                                            MRP_Plan__c, Manufacturers_Part__c, Need_Date__c, Order_Quantity__c, Overage_Percentage__c, 
                                            Promise_Date__c, Purchase_UOM__c, Quantity_Returned_to_Supplier__c, Quantity_Still_Due__c,Delivery_facility__c, Delivery_Location__c, 
                                            Requisition_Number__c, Rush_Line__c, Special_Notes__c, Status__c, Supplier_Part__c, Suppliers_Part_Description__c,
                                            Unit_Price__c From Purchase_Order_Lines__r) 
                                        From Purchase_Order__c p 
                                        where p.id = :poid limit 1];
    }

    public static testMethod void test_polineTrigger() {
        /***
        cover PO line trigger features 
        set the Line__c variable for each new line added
        prevent delete if a line has received quantity
        remove the related skid if the line is deleted
        create a single new on-order skid for each po line that is created ( or does not have a matching skid ) this holds the quantity_still_due in the skid quantity field
        */
        TestFuelQuery fuel = new TestFuelQuery();
        Purchase_Order__c po = fuel.purchaseOrder;
        Test.startTest();
        Decimal linenumber = 0; 
        for (Purchase_Order_Line__c pol: po.Purchase_Order_Lines__r ) {
            system.assert( pol.Line__c > linenumber);
            linenumber = pol.Line__c;
        }

        // add a few more lines
        List<Purchase_Order_Line__c>tmp = new List<Purchase_Order_Line__c>(); 
        
        Purchase_Order_Line__c objPODetail = new Purchase_Order_Line__c();
        objPODetail.Purchase_Order__c = po.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = fuel.itemList[0].id;
        objPODetail.Status__c = Label.Open;    
        objPODetail.Need_Date__c = System.today();
        objPODetail.Company__c = fuel.company.id;
        objPODetail.Supplier__c = fuel.supplier.id;
        objPODetail.Delivery_Location__c = fuel.location2.ID;
        objPODetail.Delivery_facility__c = fuel.location2.facility__c;
        tmp.add(objPODetail); 

        objPODetail = new Purchase_Order_Line__c();
        objPODetail.Purchase_Order__c = po.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = fuel.itemList[1].id;
        objPODetail.Status__c = Label.Open;    
        objPODetail.Need_Date__c = System.today().addDays(12);
        objPODetail.Company__c = fuel.company.id;
        objPODetail.Supplier__c = fuel.supplier.id;
        objPODetail.Delivery_Location__c = fuel.location2.ID;
        objPODetail.Delivery_facility__c = fuel.location2.facility__c;
        tmp.add(objPODetail);     

        insert tmp; 

        po = [Select (Select Id, Line__c From Purchase_Order_Lines__r order by Line__c ASC)  
                        From Purchase_Order__c po
                        where po.id = :po.id limit 1];
        // test line numbers again
        linenumber = 0; 
        for (Purchase_Order_Line__c pol: [select ID, Line__c from Purchase_Order_Line__c 
              where Purchase_Order__c =: po.id order by Line__c ASC] ) {
            system.assert( pol.Line__c > linenumber);
            linenumber = pol.Line__c;
            // .debug( LoggingLevel.INFO, pol.Line__c );
        }
        system.assertEquals( 3, linenumber );
        //// .debug( LoggingLevel.INFO, 'line number is '+linenumber );

        
        //  verify that a single "PO Supply" type skid was created for each po line
        List<SKID__c> sk = [ select id, type__c, Purchase_Order_Line__c from SKID__c
                             where type__c = :SKIDService.SKID_TYPE_PO_SUPPLY
                             AND Purchase_Order_Line__r.Purchase_Order__c =: po.id];
        // .debug( LoggingLevel.INFO, sk);
        system.assertEquals(3, sk.size() );
        for ( SKID__c s : sk) {
            system.assertEquals(SKIDService.SKID_TYPE_PO_SUPPLY, s.Type__c);
            system.assert( s.Purchase_Order_Line__c != null );
        }

        // TODO receive quantity against a po Line and attetmp to delete it

        // TODO receive quantity and check that the related SKID was removed 
		Test.stopTest();

    }
    // PTP-274
    public static testMethod void test_poApprovalStatus() {
        TestFuelQuery fuel = new TestFuelQuery();
    	Test.startTest();
    	Purchase_Order__c po = fuel.purchaseOrder;
    	po.Memo__c = '1234';
    	update po;
    	Purchase_Order__c po1 = [SELECT Id, Memo__c, Approval_Status__c FROM Purchase_Order__c WHERE Id =:po.id];
    	system.assertEquals('Approved', po1.Approval_Status__c); 
    	Test.stopTest();
    }
   
    // PTP-461
    public static testMethod void test_closeApprovedPO_ApprovalStatus() { 	
        TestFuelQuery fuel = new TestFuelQuery();

        Purchase_Order__c approvedPO = fuel.purchaseOrder;
        approvedPO.Approval_Status__c = 'Approved';
        approvedPO.Status__c = 'Open';
        update approvedPO;
        	  	
        PageReference pref = Page.PurchaseOrderClose;
        pref.getParameters().put('id',approvedPO.id);
        Test.setCurrentPage(pref);
        ApexPages.StandardController con = new ApexPages.StandardController(approvedPO);
        PurchaseOrderCloseExt ext = new PurchaseOrderCloseExt(con);
          	
        Test.startTest();
        ext.Close(); 
        Purchase_Order__c po1 = [SELECT Id, Approval_Status__c, Status__c FROM Purchase_Order__c WHERE Id =:approvedPO.id];
        system.assertEquals('Closed', po1.Status__c);
        system.assertEquals('Approved', po1.Approval_Status__c); 
        Test.stopTest();
    }
    // PTP-461
    public static testMethod void test_closeOpenPO_ApprovalStatus() { 	
        TestFuelQuery fuel = new TestFuelQuery();
        Purchase_Order__c openPO = fuel.purchaseOrder;
        openPO.Approval_Status__c = 'Pending Authorization';
        openPO.Status__c = 'Open';
        update openPO;
        	  	
        PageReference pref = Page.PurchaseOrderClose;
        pref.getParameters().put('id',openPO.id);
        Test.setCurrentPage(pref);
        ApexPages.StandardController con = new ApexPages.StandardController(openPO);
        PurchaseOrderCloseExt ext = new PurchaseOrderCloseExt(con);
        	  	
        Test.startTest();
        ext.Close(); 
        	Purchase_Order__c po1 = [SELECT Id, Approval_Status__c, Status__c FROM Purchase_Order__c WHERE Id =:openPO.id];
        system.assertEquals('Closed', po1.Status__c);
        	system.assertEquals('Pending Authorization', po1.Approval_Status__c); 
        	Test.stopTest();
    }

    public static testMethod void test_po_line_c() {
        TestFuelQuery fuel = new TestFuelQuery();
        Test.startTest();
        Purchase_Order__c po2 = fuel.purchaseOrder.clone();
        insert po2;

        //  verify that we can add multiple lines at a time for multiple PO's and the line numbers come out correct
        List<Purchase_Order_Line__c>tmp = new List<Purchase_Order_Line__c>(); 
        
        Purchase_Order_Line__c objPODetail = new Purchase_Order_Line__c();
        objPODetail.Purchase_Order__c = fuel.purchaseOrder.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = fuel.itemList[0].id;
        objPODetail.Status__c = Label.Open;    
        objPODetail.Need_Date__c = System.today();
        objPODetail.Company__c = fuel.company.id;
        objPODetail.Supplier__c = fuel.supplier.id;
        objPODetail.Delivery_Location__c = fuel.location2.ID;
        objPODetail.Delivery_facility__c = fuel.location2.facility__c;
        tmp.add(objPODetail);     
        objPODetail = new Purchase_Order_Line__c();
        objPODetail.Purchase_Order__c = fuel.purchaseOrder2.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = fuel.itemList[1].id;
        objPODetail.Status__c = Label.Open;    
        objPODetail.Need_Date__c = System.today().addDays(12);
        objPODetail.Company__c = fuel.company.id;
        objPODetail.Supplier__c = fuel.supplier.id;
        objPODetail.Delivery_Location__c = fuel.location2.ID;
        objPODetail.Delivery_facility__c = fuel.location2.facility__c;
        tmp.add(objPODetail);    


        objPODetail = new Purchase_Order_Line__c();
        objPODetail.Purchase_Order__c = po2.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = fuel.itemList[0].id;
        objPODetail.Status__c = Label.Open;    
        objPODetail.Need_Date__c = System.today();
        objPODetail.Company__c = fuel.company.id;
        objPODetail.Supplier__c = fuel.supplier.id;
        objPODetail.Delivery_Location__c = fuel.location2.ID;
        objPODetail.Delivery_facility__c = fuel.location2.facility__c;
        tmp.add(objPODetail);     
        objPODetail = new Purchase_Order_Line__c();
        objPODetail.Purchase_Order__c = po2.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = fuel.itemList[1].id;
        objPODetail.Status__c = Label.Open;    
        objPODetail.Need_Date__c = System.today().addDays(12);
        objPODetail.Company__c = fuel.company.id;
        objPODetail.Supplier__c = fuel.supplier.id;
        objPODetail.Delivery_Location__c = fuel.location2.ID;
        objPODetail.Delivery_facility__c = fuel.location2.facility__c;
        tmp.add(objPODetail);    

        insert tmp;


        objPODetail = new Purchase_Order_Line__c();
        objPODetail.Purchase_Order__c = fuel.purchaseOrder.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = fuel.itemList[0].id;
        objPODetail.Status__c = Label.Open;    
        objPODetail.Need_Date__c = System.today();
        objPODetail.Company__c = fuel.company.id;
        objPODetail.Supplier__c = fuel.supplier.id;
        objPODetail.Delivery_Location__c = fuel.location2.ID;
        objPODetail.Delivery_facility__c = fuel.location2.facility__c;
        tmp.add(objPODetail);     
        objPODetail = new Purchase_Order_Line__c();
        objPODetail.Purchase_Order__c = fuel.purchaseOrder.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = fuel.itemList[1].id;
        objPODetail.Status__c = Label.Open;    
        objPODetail.Need_Date__c = System.today().addDays(12);
        objPODetail.Company__c = fuel.company.id;
        objPODetail.Supplier__c = fuel.supplier.id;
        objPODetail.Delivery_Location__c = fuel.location2.ID;
        objPODetail.Delivery_facility__c = fuel.location2.facility__c;
        tmp.add(objPODetail);    


        objPODetail = new Purchase_Order_Line__c();
        objPODetail.Purchase_Order__c = po2.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = fuel.itemList[0].id;
        objPODetail.Status__c = Label.Open;    
        objPODetail.Need_Date__c = System.today();
        objPODetail.Company__c = fuel.company.id;
        objPODetail.Supplier__c = fuel.supplier.id;
        objPODetail.Delivery_Location__c = fuel.location2.ID;
        objPODetail.Delivery_facility__c = fuel.location2.facility__c;
        tmp.add(objPODetail);     
        objPODetail = new Purchase_Order_Line__c();
        objPODetail.Purchase_Order__c = po2.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = fuel.itemList[1].id;
        objPODetail.Status__c = Label.Open;    
        objPODetail.Need_Date__c = System.today().addDays(12);
        objPODetail.Company__c = fuel.company.id;
        objPODetail.Supplier__c = fuel.supplier.id;
        objPODetail.Delivery_Location__c = fuel.location2.ID;
        objPODetail.Delivery_facility__c = fuel.location2.facility__c;
        tmp.add(objPODetail);    

        upsert tmp;

        for ( Purchase_Order__c p : [Select (Select Id, Line__c From Purchase_Order_Lines__r order by Line__c ASC)  
                                From Purchase_Order__c p]) {
                // .debug(LoggingLevel.INFO, 'the PO '+p);
                Decimal linenumber = 0; 
                system.assert( p.Purchase_Order_Lines__r.size() > 0 );
                for ( Purchase_Order_Line__c pol : p.Purchase_Order_Lines__r) {
                    // .debug(LoggingLevel.INFO, pol);
                    system.assert( pol.Line__c > linenumber, 'expected line number to be greater than prior lines'+pol);
                    linenumber = pol.Line__c;
                }
                
            }
            Test.stopTest();
        }

    /** 
     * test for purchase order clone       
      */
      public static testMethod void test_poclone() {
        TestFuelQuery data = new TestFuelQuery();
        data.PurchaseOrder.Need_Date__c= System.today()+2;
        Test.startTest();
        PurchaseOrderCloneExt poc = new PurchaseOrderCloneExt(new Apexpages.Standardcontroller(data.purchaseOrder) );
        Pagereference p0 = poc.Save();
        system.assert(p0!=null,apexpages.getmessages());
        String url = p0.getUrl();
        
        url = url.replaceAll('/','');
        system.assert( [select id from Purchase_Order__c where id = :url limit 1].size() == 1 ); 
        
        PurchaseOrderCloneExt poc1 = new PurchaseOrderCloneExt(new Apexpages.Standardcontroller(data.purchaseOrder) );
        //poc1.DoCancelOrder();
        
        PurchaseOrderCloneExt poc2 = new PurchaseOrderCloneExt(new Apexpages.Standardcontroller(data.purchaseOrder) );
        //poc2.CancelOrder();
        Test.stopTest();
     
     	// add a segment to one line
     	Accounting_Default__c segment = new Accounting_Default__c( company__c = data.company.id, 
     		GL_Account__c = data.cashGL.id);
     	insert segment;
     	data.purchaseOrder.Status__c = 'Open';
     	update data.purchaseOrder;
     	data.purchaseOrderLines[0].Accounting_Segment__c = segment.id;
     	update data.purchaseOrderLines[0];
     	
     	// clone and ensure the new order has the same value in an accounting segment
     	poc = new PurchaseOrderCloneExt(new Apexpages.Standardcontroller(data.purchaseOrder) );
        p0 = poc.Save();
        url = p0.getUrl();
        url = url.replaceAll('/','');
        Purchase_Order__c cloned = [select id, Need_Date__c, 
                                                        (select id, Accounting_Segment__c,Need_Date__c, Standard_Cost__c  from Purchase_Order_Lines__r ) 
										     		from Purchase_Order__c where id = :url limit 1];
     	system.assert( cloned != null );
     	system.assert( cloned.Purchase_Order_Lines__r.size() > 0 );
     	system.assert( cloned.Purchase_Order_Lines__r.size() == 1);
        system.assertEquals(cloned.Need_Date__c, System.Today()+2);
       
     	id newad = null; 
     	for (  Purchase_Order_Line__c pol : cloned.Purchase_Order_Lines__r ) {
     		if ( pol.Accounting_Segment__c != null ) newad = pol.Accounting_Segment__c;
            system.assert(pol.Standard_Cost__c != null, 'Standard Cost not being cloned or is null');
     	}
     	system.assert( newad != null, ' show me the new AD' ); 
     	system.assert( newad != segment.id, ' show me the new AD has changed' ); 
     	
     }
    public static boolean hasMessage(string matching) {
        boolean ret = false; 
        system.assert( matching != null );
        for ( Apexpages.Message m: Apexpages.getMessages() ) { 
            if ( m.getDetail().contains(matching) ) 
                ret = true;
        }
        return ret;

    }

    public static testMethod void test_IndirectPOLine(){
    
   //     This checks to see that skids are not created for PO lines flagged as indirect
        TestFuelQuery fuel = new TestFuelQuery();
        Test.startTest();
        Purchase_Order__c po2 = fuel.purchaseOrder.clone();
        insert po2;
        
        Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
    
        poLine = new Purchase_Order_Line__c();
        poLine.Purchase_Order__c = fuel.purchaseOrder.Id;
        poLine.Order_Quantity__c = 10;        
        poLine.Unit_Price__c = 12;
        poLine.Type__c='Goods';
        poLine.Indirect__c = true;
        poLine.Item__c = fuel.itemList[1].id;
        poLine.Status__c = Label.Open;    
        poLine.Need_Date__c = System.today().addDays(12);
        poLine.Company__c = fuel.company.id;
        poLine.Supplier__c = fuel.supplier.id;
        poLine.Delivery_Location__c = fuel.location2.Id;
        poLine.Delivery_Facility__c = fuel.facility2.Id;
        insert poLine;
        
        List<SKID__c> sk = new list<SKID__c>();
        sk = [ select id, type__c, Purchase_Order_Line__c from SKID__c where Purchase_Order_Line__c=:poLine.id];
        system.assertequals(0, sk.size());
        Test.stopTest();
    }
    
    public static testMethod void test_DirectPOLine(){
    
     //   This checks to see that skids are created for PO lines flagged as direct
         
        TestFuelQuery fuel = new TestFuelQuery();
        Test.startTest();
        Purchase_Order__c po2 = fuel.purchaseOrder.clone();
         system.debug(po2);
        insert po2;
        
        Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
    
        poLine = new Purchase_Order_Line__c();
        poLine.Purchase_Order__c = fuel.purchaseOrder.Id;
        poLine.Order_Quantity__c = 10;        
        poLine.Unit_Price__c = 12;
        poLine.Type__c='Goods';
        poLine.Indirect__c = false;
        poLine.Item__c = fuel.itemList[1].id;
        poLine.Status__c = Label.Open;    
        poLine.Need_Date__c = System.today().addDays(12);
        poLine.Company__c = fuel.company.id;
        poLine.Supplier__c = fuel.supplier.id;
        poLine.Delivery_Location__c = fuel.location.Id;
        poLine.Delivery_Facility__c = fuel.location.facility__c;
        insert poLine;
        
        List<SKID__c> sk = new list<SKID__c>();
        sk = [ select id, type__c, Purchase_Order_Line__c from SKID__c where Purchase_Order_Line__c=:poLine.id];
        system.assertequals(1, sk.size());
        Test.stopTest();
    }



	static  testMethod void PurchaseOrderSplitExt_test() { 
		PurchaseOrderSplitExt ext ;
		POTestData data = new POTestData();
		
		ext = new PurchaseOrderSplitExt( new Apexpages.Standardcontroller( data.purchaseOrder ));
		system.assert( ext != null );
		
		ext.OrderLines[0].Quantity_To_Split = 1.0;
		ext.OrderLines[1].Quantity_To_Split = 1.0;
		ext.saveChild();
		
		system.assert( Apexpages.hasMessages() == false,   Apexpages.getMessages() );		
		
		ext = new PurchaseOrderSplitExt( new Apexpages.Standardcontroller(new Purchase_Order__c() ));
		system.assert( ext != null );
		ext.saveChild();
		 
	}
	
	//KNDY-1874 Make sure PO Supply SKIDs don't get deleted when a change is made to PO lines after initial SKID creation
	static  testMethod void POSupplySKIDDisappeareance_test() { 
        TestFuelQuery fuel = new TestFuelQuery();
		Test.startTest();
        Purchase_Order__c po = fuel.purchaseOrder;
        
        Purchase_Order_Line__c pol = new Purchase_Order_Line__c();
        pol.Purchase_Order__c = po.Id;
        pol.Order_Quantity__c = 10;        
        pol.Unit_Price__c = 12;
        pol.Item__c = fuel.itemList[2].Id;
        pol.Description__c = fuel.itemList[2].Description__c;
        pol.Purchase_UOM__c = fuel.itemList[2].Purchasing_UOM__c;
        pol.Company__c = fuel.company.id;
        pol.Supplier__c = fuel.supplier.id;
        pol.Need_Date__c = system.today() + 7;
        pol.Delivery_Location__c = fuel.location2.ID;
        pol.Delivery_facility__c = fuel.facility2.ID;
        insert pol;

        Purchase_Order_Line__c pol1 = new Purchase_Order_Line__c();
        pol1.Purchase_Order__c = po.Id;
        pol1.Order_Quantity__c = 10;        
        pol1.Unit_Price__c = 12;
        pol1.Item__c = fuel.itemList[2].Id;
        pol1.Description__c = fuel.itemList[2].Description__c;
        pol1.Purchase_UOM__c = fuel.itemList[2].Purchasing_UOM__c;
        pol1.Company__c = fuel.company.id;
        pol1.Supplier__c = fuel.supplier.id;
        pol1.Need_Date__c = system.today() + 7;
        pol1.Delivery_Location__c = fuel.location2.Id;
        pol1.Delivery_facility__c = fuel.facility2.Id;

         
        fuel.purchaseOrder =fetchPO( po.id ); 
        List<SKID__c> skids = new List<SKID__c>();
        
        for(Purchase_Order_Line__c poLine : [select Id, Quantity_Received__c,
        									(Select Id, Quantity__c, Type__c from SKIDs__r where Type__c = :SKIDService.SKID_TYPE_PO_SUPPLY) 
        									from Purchase_Order_Line__c where Purchase_Order__c = :po.id]){
        	if (poLine.SKIDS__r.size() != 0){
	        	for (SKID__c skid: poLine.SKIDS__r){
	        		skids.add(skid);
	        	}
        	} 
        }
        system.assertEquals(2, skids.size()); // Found 2 SKIDs, one for each PO line.
        
        /*
        poc.poLineList[0].poLine.status__c = 'Closed';
        
        system.assertEquals(poc.save(), Null, ' expected Null');
        system.assert(poc.saveAndReturn()!=null, ' expected record id');
        */
        fuel.purchaseorder.Purchase_Order_Lines__r[0].Status__c = 'Closed';
        update fuel.purchaseorder.Purchase_Order_Lines__r[0];

        skids = new List<SKID__c>();
        fuel.purchaseOrder =fetchPO( fuel.purchaseOrder.id ); 
        for(Purchase_Order_Line__c poLine : [select Id, Quantity_Received__c,
        									(Select Id, Quantity__c, Type__c from SKIDs__r where Type__c = :SKIDService.SKID_TYPE_PO_SUPPLY) 
        									from Purchase_Order_Line__c where Purchase_Order__c = :po.id]){
        	if (poLine.SKIDS__r.size() != 0){
	        	for (SKID__c skid: poLine.SKIDS__r){
	        		skids.add(skid);
	        	}
        	} 
        }
        system.assertEquals(1, skids.size()); // 1 SKID will be deleted tied to the closed PO line but able to find the other SKID tied to the remaining PO line
        		 
	}
	
	public static testmethod void test_PurchaseOrderExtNew() {
     
        PurchaseOrderNewExt con = new PurchaseOrderNewExt ( 
            new Apexpages.Standardcontroller( new Purchase_Order__c() ));
        system.assert( con != null );
             
    }
    
    
    //PTP-567 Remit To Supplier on Purchase Order is derived from its supplier
    public static testmethod void testRemitToSupplier_NewPurchaseOrder(){
        TestFuelQuery fuel = new TestFuelQuery();
        map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c'); 
        //Create and insert Remit-To Suppliers
        Supplier__c remittosupplier1 = new Supplier__c();
        remittosupplier1.Name = 'Test Remit To 1';
        remittosupplier1.Status__c = 'Active';
        remittosupplier1.Type__c = 'Remit-To';
        remittosupplier1.RecordTypeId = rtMap.get('Remit_To');
        remittosupplier1.company__c = fuel.company.id;
        
        Supplier__c remittosupplier2 = new Supplier__c();
        remittosupplier2.Name = 'Test Remit To 2';
        remittosupplier2.Status__c = 'Active';
        remittosupplier2.Type__c = 'Remit-To';
        remittosupplier2.RecordTypeId = rtMap.get('Remit_To');
        remittosupplier2.company__c = fuel.company.id;
        
        List<Supplier__c> remittosuppliers = new List<Supplier__c>{remittosupplier1, remittosupplier2};
        insert remittosuppliers;
        
        //Create and insert Purchasing Suppliers
        Supplier__c supplier1 = new Supplier__c();
        supplier1.Name = 'Test1';
        supplier1.Status__c = 'Active';
        supplier1.Type__c = 'Purchasing';
        supplier1.RecordTypeId = rtMap.get('Purchase_From');
        supplier1.Remit_To__c =  remittosupplier1.id;
        supplier1.company__c = fuel.company.id;
       
        Supplier__c supplier2 = new Supplier__c();
        supplier2.Name = 'Test2';
        supplier2.Status__c = 'Active';
        supplier2.Type__c = 'Purchasing';
        supplier2.RecordTypeId = rtMap.get('Purchase_From');
        supplier2.Remit_To__c =  remittosupplier2.id;
        supplier2.company__c = fuel.company.id;
         
        List<Supplier__c> suppliers = new List<Supplier__c>{supplier1, supplier2};
        insert suppliers;
        
        // Create new purchase order with mismatching remit-to supplier
        Purchase_Order__c purchaseOrderNew = new Purchase_Order__c();{
            purchaseOrderNew.Supplier__c = supplier1.id; 
            purchaseOrderNew.Remit_To_Supplier__c = remittosupplier2.id; 
            purchaseOrderNew.Company__c = fuel.company.id;
            purchaseOrderNew.Type__c = 'Production';
        }
        PurchaseOrderNewExt con = new PurchaseOrderNewExt ( 
            new Apexpages.Standardcontroller( purchaseOrderNew ));
        Test.startTest();
        // Get new PO id
        PageReference newPOUrl = con.SavePO();
        system.assert(newPOUrl != null);
        String newPOUrlStr = newPOUrl.getUrl();
        String poId = newPOUrlStr.substring(newPOUrlStr.lastIndexOf('/') + 1);
        // Check remit to supplier on new PO
        Purchase_Order__c po = [Select Supplier__c, Remit_To_Supplier__c 
                                from Purchase_Order__c where Id =: poId];
        system.assertEquals(po.Supplier__c, supplier1.Id);
        system.assertEquals(po.Remit_To_Supplier__c, remittosupplier1.Id);
        Test.stopTest();
    }
    
    public static testmethod void test_failedPurchaseOrderCreations(){
        POTestData data = new POTestData();
        map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c'); 
        
        //Create and insert Remit-To Suppliers
        Supplier__c remittosupplier1 = new Supplier__c();
        remittosupplier1.Name = 'Test Remit To 1';
        remittosupplier1.Status__c = 'Active';
        remittosupplier1.Type__c = 'Remit-To';
        remittosupplier1.RecordTypeId = rtMap.get('Remit_To');
        remittosupplier1.company__c = data.company.id;
        
        List<Supplier__c> remittosuppliers = new List<Supplier__c>{remittosupplier1};
        insert remittosuppliers;
        
        //Create and insert Purchasing Suppliers
        Supplier__c supplier1 = new Supplier__c();
        supplier1.Name = 'Test1';
        supplier1.Status__c = 'Active';
        supplier1.Type__c = 'Purchasing';
        supplier1.RecordTypeId = rtMap.get('Purchase_From');
        supplier1.Remit_To__c =  remittosupplier1.id;
        supplier1.company__c = data.company1.id;
        
        Supplier__c supplier2 = new Supplier__c();
        supplier2.Name = 'Test2';
        supplier2.Status__c = 'Active';
        supplier2.Type__c = 'Purchasing';
        supplier2.RecordTypeId = rtMap.get('Purchase_From');
        supplier2.Remit_To__c =  remittosupplier1.id;
        supplier2.company__c = data.company1.id;
        supplier2.Hold_Purchasing__c = true;
       
        List<Supplier__c> suppliers = new List<Supplier__c>{supplier1,supplier2};
        insert suppliers;
        
        // Create new purchase order with mismatching companies on the supplier
        Purchase_Order__c purchaseOrderNew = new Purchase_Order__c();{
            purchaseOrderNew.Supplier__c = supplier1.id; 
            purchaseOrderNew.Remit_To_Supplier__c = remittosupplier1.id; 
            purchaseOrderNew.Company__c = data.company.id;
            purchaseOrderNew.Type__c = 'Production';
        }
        
        PurchaseOrderNewExt con = new PurchaseOrderNewExt ( 
            new Apexpages.Standardcontroller( purchaseOrderNew ));
            
        // Create new purchase order with hold on Purchasing set to true
        Purchase_Order__c purchaseOrderNew1 = new Purchase_Order__c();{
            purchaseOrderNew1.Supplier__c = supplier2.id; 
            purchaseOrderNew1.Remit_To_Supplier__c = remittosupplier1.id; 
            purchaseOrderNew1.Company__c = data.company1.id;
            purchaseOrderNew1.Type__c = 'Production';
        }
        
        PurchaseOrderNewExt con1 = new PurchaseOrderNewExt ( 
            new Apexpages.Standardcontroller( purchaseOrderNew1 ));
            
        Test.startTest();
      
        PageReference newPOUrl = con.SavePO();
        system.assert(newPOUrl == null);
        system.assertEquals(Apexpages.getMessages()[0].getdetail().contains(Label.Purchase_from_Supplier_not_tagged_to_the_Company),True); 
        
        PageReference newPOUrl1 = con1.SavePO();
        System.debug(logginglevel.info,'Messages-->>'+Apexpages.getMessages() );
        system.assert(newPOUrl1 == null);
        system.assertEquals(Apexpages.getMessages()[1].getDetail().contains(Label.Purchase_Order_creation_failed),True); 
        
        Test.stopTest();
    }
  
    //PTP-567 Remit To Supplier on Purchase Order is derived from its supplier
    public static testmethod void testRemitToSupplier_ClonePurchaseOrder(){
        TestFuelQuery fuel = new TestFuelQuery();
        map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c'); 
        //Create and insert Remit-To Suppliers
        Supplier__c remittosupplier1 = new Supplier__c();
        remittosupplier1.Name = 'Test Remit To 1';
        remittosupplier1.Status__c = 'Active';
        remittosupplier1.Type__c = 'Remit-To';
        remittosupplier1.RecordTypeId = rtMap.get('Remit_To');
        remittosupplier1.company__c = fuel.company.id;
        
        Supplier__c remittosupplier2 = new Supplier__c();
        remittosupplier2.Name = 'Test Remit To 2';
        remittosupplier2.Status__c = 'Active';
        remittosupplier2.Type__c = 'Remit-To';
        remittosupplier2.RecordTypeId = rtMap.get('Remit_To');
        remittosupplier2.company__c = fuel.company.id;
         
        List<Supplier__c> remittosuppliers = new List<Supplier__c>{remittosupplier1, remittosupplier2};
        insert remittosuppliers;
        
        //Create and insert Purchasing Suppliers
        Supplier__c supplier1 = new Supplier__c();
        supplier1.Name = 'Test1';
        supplier1.Status__c = 'Active';
        supplier1.Type__c = 'Purchasing';
        supplier1.RecordTypeId = rtMap.get('Purchase_From');
        supplier1.Remit_To__c =  remittosupplier1.id;
        supplier1.company__c =  fuel.company.id;
        
        
        Supplier__c supplier2 = new Supplier__c();
        supplier2.Name = 'Test2';
        supplier2.Status__c = 'Active';
        supplier2.Type__c = 'Purchasing';
        supplier2.RecordTypeId = rtMap.get('Purchase_From');
        supplier2.Remit_To__c =  remittosupplier2.id;
        supplier2.company__c =  fuel.company.id;
        
        List<Supplier__c> suppliers = new List<Supplier__c>{supplier1, supplier2};
        insert suppliers;
        
        // Create new purchase order with mismatching remit-to supplier
        Purchase_Order__c purchaseOrderNew = new Purchase_Order__c();{
            purchaseOrderNew.Supplier__c = supplier1.id; 
            purchaseOrderNew.Remit_To_Supplier__c = remittosupplier1.id; 
            purchaseOrderNew.Company__c = fuel.company.id;
            purchaseOrderNew.Type__c = 'Production';
        }
        insert purchaseOrderNew;
        
        Test.startTest();
        // Change supplier on PO loaded on clone page
        purchaseOrderNew.Supplier__c = supplier2.id; 
        PurchaseOrderCloneExt con = new PurchaseOrderCloneExt ( 
            new Apexpages.Standardcontroller( purchaseOrderNew ));
        
        // Get new PO id
        PageReference newPOUrl = con.save();
        system.assert(newPOUrl != null);
        String newPOUrlStr = newPOUrl.getUrl();
        String poId = newPOUrlStr.substring(newPOUrlStr.lastIndexOf('/') + 1);
        system.assert(poId != String.ValueOf(purchaseOrderNew.Id));
        // Check remit to supplier on new PO
        Purchase_Order__c po = [Select Supplier__c, Remit_To_Supplier__c 
                                from Purchase_Order__c where Id =: poId];
        system.assertEquals(po.Supplier__c, supplier2.Id);
        system.assertEquals(po.Remit_To_Supplier__c, remittosupplier2.Id);
        Test.stopTest();
    }
    
    public static testmethod void testRemitToSupplier_UpdatePurchaseOrder(){
        TestFuelQuery fuel = new TestFuelQuery(); 
        map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c'); 
        //Create and insert Remit-To Suppliers
        Supplier__c remittosupplier1 = new Supplier__c();
        remittosupplier1.Name = 'Test Remit To 1';
        remittosupplier1.Status__c = 'Active';
        remittosupplier1.Type__c = 'Remit-To';
        remittosupplier1.RecordTypeId = rtMap.get('Remit_To');
        remittosupplier1.company__c = fuel.company.id;
        
        Supplier__c remittosupplier2 = new Supplier__c();
        remittosupplier2.Name = 'Test Remit To 2';
        remittosupplier2.Status__c = 'Active';
        remittosupplier2.Type__c = 'Remit-To';
        remittosupplier2.RecordTypeId = rtMap.get('Remit_To');
        remittosupplier2.company__c = fuel.company.id;
        
        List<Supplier__c> remittosuppliers = new List<Supplier__c>{remittosupplier1, remittosupplier2};
        insert remittosuppliers;
        
        //Create and insert Purchasing Suppliers
        Supplier__c supplier1 = new Supplier__c();
        supplier1.Name = 'Test1';
        supplier1.Status__c = 'Active';
        supplier1.Type__c = 'Purchasing';
        supplier1.RecordTypeId = rtMap.get('Purchase_From');
        supplier1.Remit_To__c =  remittosupplier1.id;
        supplier1.company__c = fuel.company.id;
        
        Supplier__c supplier2 = new Supplier__c();
        supplier2.Name = 'Test2';
        supplier2.Status__c = 'Active';
        supplier2.Type__c = 'Purchasing';
        supplier2.RecordTypeId = rtMap.get('Purchase_From');
        supplier2.Remit_To__c =  remittosupplier2.id;
        supplier2.company__c = fuel.company.id;
        
        List<Supplier__c> suppliers = new List<Supplier__c>{supplier1, supplier2};
        insert suppliers;

        Purchase_Order__c po = new Purchase_Order__c();{
            po.Supplier__c = supplier1.id; 
            po.Remit_To_Supplier__c = remittosupplier1.Id;
            po.Company__c = fuel.company.id;
            po.Type__c = 'Production';
        }
        insert po;
        Test.startTest();
        // Change supplier
        po.Supplier__c = supplier2.Id;
        update po;
        // Check remit to supplier
        po = [Select Supplier__c, Remit_To_Supplier__c 
              from Purchase_Order__c where Id =: po.Id];
        system.assertEquals(po.Supplier__c, supplier2.Id);
        system.assertEquals(po.Remit_To_Supplier__c, remittosupplier2.Id);
        Test.stopTest();
    }
    
	public static testMethod void test_PurchaseOrderCreationwSupplierHold() {
        TestFuelQuery fuel = new TestFuelQuery(); 
		Supplier__c supplier = new Supplier__c();{
			supplier.hold_purchasing__c = true;
		}
		insert supplier;
		
		Purchase_Order__c purchaseOrderNew = new Purchase_Order__c();{
			purchaseOrderNew.Supplier__c = supplier.id; 
	        purchaseOrderNew.Company__c = fuel.company.id;
	        purchaseOrderNew.Type__c = 'Production';
		}     
		PurchaseOrderNewExt con = new PurchaseOrderNewExt ( 
        		new Apexpages.Standardcontroller( purchaseOrderNew ));
		Test.startTest();
			 system.assert( con.SavePO() == null );      
        Test.stopTest();
         	
        
	}
	
	class POTestData { 
        TestFuelQuery fuel = new TestFuelQuery(); 		
		public Purchase_Order__c purchaseOrder = new Purchase_Order__c();
		public Supplier__c supplier = new Supplier__c(); 
		public Class__c clsObj=new Class__c();
		public List<Item__c> itemList=new List<Item__c>();
	    public Facility__c facility = new Facility__c();
		public Location__c location1 = new Location__c(facility__c = facility.Id);  
	    public Location__c location2 = new Location__c(); 
	    public Location__c location3 = new Location__c();
	   // public UOM__c uomObj = new UOM__c();
    	public Company__c company = new Company__c();
    	public Company__c company1 = new Company__c();
	    
		List<Account> account_list = new List<Account>(); 
        Account account = new Account();
        {
	        account.name = 'Kenandy';
	        account.billingstreet = '303 Twin Dolphin Drive, Suite 500';
	        account.billingcity = 'Redwood City';
	        account.billingstate = 'CA';
	        account.billingpostalcode = '94065';
	        account.billingcountry = 'USA';
	        account.shippingstreet = '303 Twin Dolphin Drive, Suite 500';
	        account.shippingcity = 'Redwood City';
	        account.shippingstate = 'CA';
	        account.shippingpostalcode = '94065';
	        account.shippingcountry = 'USA';
	        account.phone = '650-468-2000';
	        account.fax = '650-468-2010';
	        account.website = 'kenandy.com';
	        insert account;

	        company.name = 'Kenandy';
	        company.Address__c = account.ID;
            company.Comp_Currency__c = fuel.currencyUSD.id;
            company.Consol_Currency__c = fuel.currencyUSD.id;
            company.Stat_Currency__c = fuel.currencyUSD.id;
            company.Subs_Currency__c = fuel.currencyUSD.id;
            company.Default_Transaction_Currency__c = fuel.currencyUSD.id;            
	        insert company;
	        
	        company1.name = 'Kenandy PTP';
            company1.Address__c = account.ID;
            company1.Comp_Currency__c = fuel.currencyUSD.id;
            company1.Consol_Currency__c = fuel.currencyUSD.id;
            company1.Stat_Currency__c = fuel.currencyUSD.id;
            company1.Subs_Currency__c = fuel.currencyUSD.id;
            company1.Default_Transaction_Currency__c = fuel.currencyUSD.id;            
            insert company1;
	        
	        facility.Company__c = company.Id;
	        insert facility;
	        
	        location1.facility__c = facility.Id;
	        insert location1;
	        
	        clsObj.name = 'Class-1';
	  
	        insert clsObj; 
	        
    	   //   uomObj.Name = 'EA';
    	   //   insert uomObj;
	        
		  	purchaseOrder.Supplier__c = supplier.id; 
	        purchaseOrder.Company__c = company.id;
	        purchaseOrder.Type__c = 'Production';
	        insert purchaseOrder;
	        
	        for(integer i=10;i<21;i++){
                Item__c item = new Item__c();
                item.name= company.Name + ' Item-'+i;
                item.Description__c='Item-'+i;
                if (i == 10 || i == 15) {
                    item.Source__c = 'Manufactured';
                    item.Class__c = clsobj.ID;
                    item.Lead_Time__c = i/2;
                    if (i == 10) item.ABC_Code__c = 'A';
                    else item.ABC_Code__c = 'B';
                } 
                else {
                    item.Source__c = 'Purchased';
                    item.Supplier__c = supplier.ID;
                    item.Class__c = clsobj.ID;
                    item.Purchasing_UOM__c = fuel.uomList[8].id;
                    item.Stocking_UOM__c = fuel.uomList[8].Id;
                    item.Lead_Time__c = i/5;
                }
                item.company__c = company.id;
                item.Active__c = true;
                item.Packaging_UOM__c = JSON.serialize( new List<ID> {fuel.uomList[8].id});
                item.Stocking_UOM__c = fuel.uomList[8].id;
                itemList.add(item);
            }
            insert itemList;
	        Purchase_Order_Line__c objPODetail = new Purchase_Order_Line__c();
	        objPODetail.Purchase_Order__c = purchaseOrder.Id;
	        objPODetail.Order_Quantity__c = 10;        
	        objPODetail.Unit_Price__c = 12;
	        objPODetail.Item__c = itemList[2].Id;
	        objPODetail.Description__c = itemList[2].Description__c;
	        objPODetail.Purchase_UOM__c = itemList[2].Purchasing_UOM__c;
	        objPODetail.Company__c = company.id;
	        objPODetail.Supplier__c = supplier.id;
	        objPODetail.Need_Date__c = system.today() + 7;
	        objPODetail.Delivery_Location__c = location1.ID;
	        objPODetail.Delivery_facility__c = location1.facility__c;
	        insert objPODetail;
	        
	        objPODetail = new Purchase_Order_Line__c();
	        objPODetail.Purchase_Order__c = purchaseOrder.Id;
	        objPODetail.Order_Quantity__c = 10;        
	        objPODetail.Unit_Price__c = 12;
	        objPODetail.Item__c = itemList[2].Id;
	        objPODetail.Description__c = itemList[2].Description__c;
	        objPODetail.Purchase_UOM__c = itemList[2].Purchasing_UOM__c;
	        objPODetail.Company__c = company.id;
	        objPODetail.Supplier__c = supplier.id;
	        objPODetail.Need_Date__c = system.today() + 7;
	        objPODetail.Delivery_Location__c = location1.ID;
	        objPODetail.Delivery_facility__c = location1.facility__c;
	        insert objPODetail;
	        
	
	        purchaseOrder = [   Select k.Type__c, k.SystemModstamp, k.Delivery_Location__c, k.Delivery_facility__c, k.Production_Purchase_Order__c, k.OwnerId, k.Name, k.LastModifiedDate, 
							        k.LastModifiedById, k.Currency__c, k.Supplier__c, k.Status__c, k.Ship_Via__c, k.Rush_Order__c, k.Quantity_Released__c, 
							        k.Purchase_Order_Value__c, k.Purchase_Order_Number__c, k.Payment_Term__c, k.Order_Date__c, k.Open_Purchase_Order_Lines__c,
							        k.Deliver_to__c, k.Date_Closed__c, k.Company__c, k.Company_Identifier__c, k.Buyer__c, k.Bill_to_Zip_Code__c,
							         k.Bill_to_Street__c, k.Bill_to_State__c, k.Bill_to_Country__c, k.Bill_to_City__c, k.Approval_Status__c, k.Acknowledge_Via__c, k.IsDeleted, k.Id, k.CreatedDate, 
							         k.CreatedById, 
									      (Select Id, IsDeleted, Name,  CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Purchase_Order__c, 
									         Company_Identifier__c, Company__c, Date_Added__c, Date_Closed__c, Date_Last_Changed__c, Delivery_Location__c, Description__c, Indirect__c, Item_Name__c,
									          Item__c, Latest_Promise_Date__c, Line_Value__c, Line__c, MRP_Plan__c, Manufacturers_Part__c, Need_Date__c, 
									          Order_Quantity__c, Overage_Percentage__c, Overage_Quantity__c, Primary_Key__c, Promise_Date__c, Purchase_Order_Number__c, Purchase_UOM__c, 
									          Quantity_Received__c, Quantity_Returned_to_Supplier__c, Quantity_Returned_to_Supplier_for_Credit__c, Quantity_Still_Due__c, Requisition_Number__c, 
									          Rush_Line__c, Special_Notes__c, Status__c, Supplier_Part__c, Suppliers_Part_Description__c, Currency__c, Type__c, Unit_Price__c, 
									          Days_from_Promised__c 
									     From Purchase_Order_Lines__r) 
									 From Purchase_Order__c k
	                        		where k.id = :purchaseOrder.id limit 1];
    	}
	}

	//PTP-123 Verify if the PO's FOB terms is defaulted from the Purchasing supplier
    static  testMethod void testPOFOBDefault() { 
        
        TestFuelQuery fuel = new TestFuelQuery();
    	fuel.supplier.fob_term__c = fuel.fobTerm.id;
    	update fuel.supplier;
    	Purchase_Order__c purchaseOrder = new Purchase_Order__c();
    	purchaseOrder.Supplier__c = fuel.supplier.id; 
        purchaseOrder.Company__c = fuel.company.id;
        purchaseOrder.Delivery_Facility__c = fuel.facility2.id;
        purchaseOrder.Delivery_Location__c = fuel.location2.ID;
        purchaseOrder.Remit_To_Supplier__c = fuel.remitToSupplier.id;
        purchaseOrder.Approval_Status__c = 'Approved';
        purchaseOrder.Status__c = 'Open';
		insert purchaseOrder;
		
		purchase_order__c po = [select id, name, fob_term__c from purchase_order__c where id = :purchaseOrder.id];
		system.assertEquals(po.fob_term__c, fuel.supplier.fob_term__c);
		
    } 
    
    //PTP-218 Defaulting Pymt terms from Remit-To supplier via Purchasing supplier given
     static  testMethod void testPOPymtTermsDefault() { 
        
        TestFuelQuery fuel = new TestFuelQuery();
    	Test.startTest();
    	Purchase_Order__c purchaseOrder = new Purchase_Order__c();
    	purchaseOrder.Supplier__c = fuel.supplier.id; 
        purchaseOrder.Company__c = fuel.company.id;
        purchaseOrder.Delivery_Facility__c = fuel.facility2.id;
        purchaseOrder.Delivery_Location__c = fuel.location2.ID;
        purchaseOrder.Remit_To_Supplier__c = fuel.remitToSupplier.id;
        purchaseOrder.Approval_Status__c = 'Approved';
        purchaseOrder.Status__c = 'Open';
		insert purchaseOrder;
		
		purchase_order__c po = [select id, name, fob_term__c, Supplier__r.fob_term__c, Payment_Term__c from purchase_order__c where id = :purchaseOrder.id];
		system.assertEquals(po.Payment_Term__c, fuel.remittosupplier.Payment_Term__c);
		system.assertEquals(po.fob_term__c, fuel.supplier.fob_term__c);
		
    } 
    
    //KNDY-8790
	static  testMethod void testQtyMatchedBucketonPOLine() { 
     
    	TestFuelQuery fuel = new TestFuelQuery();

    	Purchase_Order__c purchaseOrder = new Purchase_Order__c();
    	purchaseOrder.Supplier__c = fuel.supplier.id; 
        purchaseOrder.Company__c = fuel.company.id;
        purchaseOrder.Delivery_Facility__c = fuel.facility2.id;
        purchaseOrder.Delivery_Location__c = fuel.location2.ID;
        purchaseOrder.Remit_To_Supplier__c = fuel.remitToSupplier.id;
        purchaseOrder.Status__c = 'Open';
        purchaseOrder.Currency__c = fuel.currencyUSD.id;
		insert purchaseOrder;
		
		Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = fuel.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = fuel.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Status__c = 'Open';
            insert POLine1;
        }
        
        purchaseOrder.Approval_Status__c = 'Approved';
        update purchaseOrder;
        Test.startTest();
		purchase_order__c po = [select id, name, status__c, approval_status__c from purchase_order__c where id = :purchaseOrder.id];
    
    	system.assert(po.status__c == 'Open', 'PO not open');
		system.assert(po.approval_status__c == 'Approved', 'PO not approved');
		
		Purchase_Order_Line__c pol = [select id, invoice_matching__c, invoice_status__c, quantity_matched__c, amount_matched__c, Order_Quantity__c from Purchase_Order_Line__c where purchase_Order__c = :po.id];
		system.assert(pol.quantity_matched__c == 0, 'POL Qty matched is not 0');
		system.assert(pol.amount_matched__c == 0, 'POL Amt matched is not 0');
		system.assert(pol.invoice_status__c == 'Open for Invoicing', 'POL is not open for invoicing');
		//system.assert(pol.Quantity_Uninvoiced__c == pol.Order_Quantity__c, 'POL Uninvoiced qty is not set to order qty');
		
		Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = fuel.company.id;
            si_mrl.Supplier__c = fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 20;
            si_mrl.Purchase_Order__c = po.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            si_mrl.Currency__c = fuel.currencyUSD.id;
			insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = pol.id;
            sil_mrl.Item__c = fuel.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= fuel.itemList[1].id, Source__c = fuel.itemList[1].Source__c, Class__c = fuel.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = fuel.clsObj.id, type__c = fuel.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 20;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        // Exception as Invoice quanity is higher than 103
        // No Amount Exception
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, Quantity_Exception__c, Price_Exception__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Approved',si.status__c); 
		Test.stopTest();
    } 
	
}