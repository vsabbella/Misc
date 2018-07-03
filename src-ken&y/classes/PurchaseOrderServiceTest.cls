/**
 * This class contains unit tests for validating the behavior of methods in PurchaseOrderService.cls
 */
@isTest
private class PurchaseOrderServiceTest {
	 @testSetup static void ts() { 
        TestFuel data = new TestFuel(); 
        // these asserts cause TestFuelQuery to insert data
        system.assert(      
            data.company != null &&
            data.supplier != null &&
            data.purchaseOrder != null && 
            data.purchaseOrderLines != null &&
            data.supplier != null &&
            data.itemList != null &&
            data.ItemNoClassType != null &&
            data.facility2 != null &&
            data.location2 != null
            
        );
    }
     static testMethod void testPOLinePriceChangeNew() {
        TestFuelQuery fuel = new TestFuelQuery();
        Purchase_Order__c po = fuel.purchaseOrder;

        PurchaseOrderService pos = new PurchaseOrderService();
        Purchase_Order__c purchaseOrder = new Purchase_Order__c(
                                        Supplier__c = fuel.supplier.id, 
                                        Company__c = fuel.company.id,
                                        Delivery_Facility__c = fuel.facility2.id,
                                        Delivery_Location__c = fuel.location2.ID,
                                        Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                        Approval_Status__c = 'Approved',
                                        Acknowledge_Via__c = 'Email',
                                        Status__c = 'Open',
                                        Memo__c = 'purchaseOrder',
                                        Currency__c = fuel.currencyUSD.id
                            );
      insert purchaseOrder;
      
      Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
        poLine.Purchase_Order__c = purchaseOrder.Id;
        poLine.Order_Quantity__c = 10;     
        poLine.Unit_Price__c = 12;
        poLine.Item__c = fuel.ItemNoClassType.Id;
        poLine.Description__c = 'purchaseOrderLine0';
        poLine.Purchase_UOM__c = fuel.ItemNoClassType.Purchasing_UOM__c;
        poLine.Company__c = fuel.company.id;
        poLine.Need_Date__c = system.today() + 7;
        poLine.Delivery_Facility__c = fuel.facility2.id;
        poLine.Delivery_Location__c = fuel.location2.ID;
        poLine.Supplier__c = fuel.supplier.Id;
        poLine.Line__c = 1;
        poLine.Quantity_Matched__c = 0;
        poLine.Amount_Matched__c = 0;
        insert poline;
        purchaseOrder.Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_APPROVED;
        update purchaseOrder;
	  
        Test.startTest();
        
        JsonResult result = PurchaseOrderReceiveExtV2.getList(po.Id);
        List<ReceivingWrapper> polWrapperList = (List<ReceivingWrapper>)result.records;
        polWrapperList[0].serialWrapperList[0].skid.Quantity__c = 10;
        result = PurchaseOrderReceiveExtV2.receivePurchaseOrders(polWrapperList);
        
        //After receiving to po line, try to update the price to propagate the change to the receipt lines
        List<Purchase_Order_Line__c> polinesToUpdate = new List<Purchase_Order_Line__c>();
        for(Purchase_Order_Line__c pol:[select Id from Purchase_Order_Line__c where Purchase_Order__c = :purchaseOrder.Id]){
        	
        	pol.Status__c = 'Open';
        	pol.Unit_Price__c = 5;
        	polinesToUpdate.add(pol);
        	
        }
        
        purchaseOrder.Status__c = 'Open';
        update purchaseOrder;
        
        update polinesToUpdate;
        
        //Select the receipt lines and cerify that the unit price have change accordingly
        for(Receipt_Line__c receipt:[select Id, Unit_Price__c from Receipt_Line__c where Purchase_Order__c = :purchaseOrder.Id]){
        	
        	System.assertEquals(5,receipt.Unit_Price__c);
        	
        }
        
        Test.stopTest();
       
        
    }
    static testMethod void testupdateSupplieronPOL() {
        TestFuelQuery fuel = new TestFuelQuery();
    	PurchaseOrderService pos = new purchaseOrderService();
    	List<Purchase_Order_Line__c> pollist = new List<Purchase_Order_Line__c>();
    	
    	FOB_Terms__c fobTerm1  = new FOB_Terms__c();
    	fobTerm1.Name = 'test term Origin';
    	fobTerm1.FOB_Point__c = 'Origin';
    	insert fobTerm1;
   
        Source_Document_Approval__c sd = new Source_Document_Approval__c();{
            sd.Name = 'Purchase Order';
            sd.Allow_Approval__c = true;
            insert sd;
        }
   
    	Supplier__c sup = new Supplier__c();
    	sup.Name = fuel.company.Name + ' Supplier-2';
		sup.Company__c = fuel.company.ID;
		sup.Tax_ID__c = 'tax ID';
		sup.Address__c = fuel.account.ID;  // remittoaccount ?? TODO 
		sup.Status__c = 'Active';
		sup.Payment_Term__c = fuel.terms.ID;
		sup.FOB_Term__c = fuel.fobTerm.id;
		sup.Type__c = 'Purchasing';
		sup.RecordTypeId = fuel.SupplierRecordTypes.get('Purchase_From');
	    sup.Remit_To__c =  fuel.remittosupplier.id;
	    sup.Default_Receiving_Tolerance__c = 3;
        sup.Create_RTV_Credit_Memo__c = true;
	    insert sup;
    	
    	Purchase_Order__c po = new Purchase_Order__c();
    	po.Company__c = fuel.Company.id;
    	po.Supplier__c = fuel.Supplier.id;
    	po.Payment_Term__c = fuel.terms.id;
    	po.Delivery_Facility__c = fuel.facility2.id;
        po.Delivery_Location__c = fuel.location2.iD;
    	po.Remit_To_Supplier__c = fuel.remitToSupplier.id;
    	po.Approval_Status__c = 'Pending Authorization';
    	po.fob_term__c = fuel.fobTerm.id;
    	po.Type__c = 'Standard';
    	po.Status__c = 'Open';
    	insert po;
    	
    	Purchase_Order_Line__c poLine1 = new Purchase_Order_Line__c();
        poLine1.Purchase_Order__c = po.Id;
        poLine1.Order_Quantity__c = 10;     
        poLine1.Unit_Price__c = 12;
        poLine1.Item__c = fuel.itemList[2].Id;
        poLine1.Description__c = fuel.itemList[2].Description__c;
        poLine1.Purchase_UOM__c = fuel.itemList[2].Purchasing_UOM__c;
        poLine1.Company__c = fuel.company.id;
        poLine1.Need_Date__c = system.today() + 7;
        poLine1.Delivery_Facility__c = fuel.facility2.id;
        poLine1.Delivery_Location__c = fuel.location2.ID;
        poLine1.Supplier__c = fuel.supplier.Id;
        poLine1.Invoice_Matching__c = '';
        poLine1.Line__c = 1;
    	pollist.add(poLine1);
    	
    	
    	Purchase_Order_Line__c poLine2 = new Purchase_Order_Line__c();
    	poLine2.Purchase_Order__c = po.id;
    	poLine2.Order_Quantity__c = 12;
    	poLine2.Unit_Price__c = 10;
    	poLine2.Item__c = fuel.itemList[1].id;
    	poLine2.Description__c = fuel.itemList[1].Description__c;
    	poLine2.Purchase_UOM__c = fuel.itemList[1].Purchasing_UOM__c;
    	poLine2.Company__c = fuel.company.id;
    	poLine2.Need_Date__c = system.today() + 7;
        poLine2.Delivery_Facility__c = fuel.facility2.id;
        poLine2.Delivery_Location__c = fuel.location2.ID;
        poLine2.Supplier__c = fuel.supplier.Id;
        poLine2.Line__c = 2;
    	pollist.add(poLine2);
    	insert pollist;
    	
    	Purchase_Order_Line__c pol = [Select id, name, Supplier__c, Supplier__r.Invoice_Matching__c, Invoice_Matching__c from Purchase_Order_Line__c where Id =:poline1.id];
    	system.assert(pol.Supplier__r.Invoice_Matching__c == 'Three Way');
    	system.assertEquals(pol.supplier__r.Invoice_Matching__c, pol.Invoice_Matching__c); //KNDY-12006 Defaulting the Invoice Matching on PO with Supplier's Invoice Matching if it is blanked out
    	
    	po.Supplier__c = sup.id;
    	update po;
    	    	
    	Purchase_Order__c po1 = [Select id, name, Supplier__c from Purchase_Order__c where Id = :po.id Limit 1];
    	system.assertEquals(po1.Supplier__c, sup.id,'supplier is updated on po with sup');
    	
    	List<purchase_Order_Line__c> pols = [Select id, name, Supplier__c from Purchase_Order_Line__c where Purchase_Order__c =:po.Id Limit 2];
    	system.assertEquals(pols[0].Supplier__c, sup.id, 'supplier is updated on purchase order line with sup');
    	system.assertEquals(pols[1].Supplier__c, sup.id, 'supplier is updated on purchase order line with sup');
    	
    	po.Approval_Status__c = 'Approved';
    	update po;
    	
    	po.Supplier__c = fuel.Supplier.id;
    	try {
    		update po;	
    	}catch(Exception e){
    		system.assertEquals(e.getMessage().contains ('Cannot change Supplier for Approved Purchase Orders.'), true);
    		Purchase_Order__c po2 = [Select id, name, Supplier__c,Type__c, FOB_Term__c from Purchase_Order__c where Id = :po.id Limit 1];
    		system.assertEquals(po2.Supplier__c, sup.id, 'Supplier on PO remains unchanged.');
    	
    		List<purchase_Order_Line__c> pols1 = [Select id, name, Approved__c, Supplier__c from Purchase_Order_Line__c where Purchase_Order__c =:po.Id Limit 2];
    	
    		system.assertEquals(pols1[0].Supplier__c, sup.id, 'Supplier on POL remains unchanged.');
    		system.assertEquals(true, pols1[0].Approved__c,  'Approved flag on POL changes to true after the PO is approved');
    	}
    	po.FOB_Term__c = fobTerm1.id;
    	
    	try {
    		update po;	
    	}catch(Exception e){
    		system.assertEquals(e.getMessage().contains ('Cannot change FOB Term for Approved Purchase Orders.'),true);
    	} 
    	Purchase_Order__c po3 = [Select id, name, Supplier__c,Type__c, FOB_Term__c from Purchase_Order__c where Id = :po.id Limit 1];
    	po3.Type__c = 'Shipment';
    	
    	try {
    		update po3;
    	}catch(Exception e){
    		system.assertEquals(e.getMessage().contains ('Cannot change Type for Approved Purchase Orders.'),true);
    		
    	}	
    	
    	
    }
    
    //PTP-402 PTP-634 POLs with Supplier Invoices cannot be cancelled.
    static testMethod void testCancelPO_Failure(){
        TestFuelQuery fuel = new TestFuelQuery();
        List<Period__c> periodList = fuel.periodList;
        Purchase_Order__c po = fuel.purchaseOrder;
        
        // Three Way pol exists
        List<Purchase_Order_Line__c> purchaseOrderLines = fuel.purchaseOrderLines;
        system.assert(purchaseOrderLines.size() == 1);
        Purchase_Order_Line__c pol3Way = purchaseOrderLines[0];
        
        // Create Two Way POL
        Purchase_Order_Line__c pol2Way_WithReceipts = new Purchase_Order_Line__c();{
            pol2Way_WithReceipts.Company__c = fuel.company.Id;
            pol2Way_WithReceipts.Invoice_Matching__c = 'Two Way';
            pol2Way_WithReceipts.Item__c = fuel.itemlist[1].Id;
            pol2Way_WithReceipts.Order_Quantity__c = 20;
            pol2Way_WithReceipts.Quantity_Matched__c = 0;
            //pol2Way_WithReceipts.Quantity_Uninvoiced__c = 0;            
            pol2Way_WithReceipts.Quantity_Received__c = 0;
            pol2Way_WithReceipts.Purchase_Order__c = fuel.purchaseOrder.Id;
            pol2Way_WithReceipts.Unit_Price__c = 1;
            pol2Way_WithReceipts.Need_Date__c = System.today();
        }
        
        Purchase_Order_Line__c pol2Way = new Purchase_Order_Line__c();{
            pol2Way.Company__c = fuel.company.Id;
            pol2Way.Invoice_Matching__c = 'Two Way';
            pol2Way.Item__c = fuel.itemlist[1].Id;
            pol2Way.Order_Quantity__c = 20;
            pol2Way.Quantity_Matched__c = 0;
            //pol2Way.Quantity_Uninvoiced__c = 0;            
            pol2Way.Quantity_Received__c = 0;
            pol2Way.Purchase_Order__c = fuel.purchaseOrder.Id;
            pol2Way.Unit_Price__c = 1;
            pol2Way.Need_Date__c = System.today();
        }
        
        List<Purchase_Order_Line__c> pols = new List<Purchase_Order_Line__c> { pol2Way_WithReceipts,pol2Way};
        insert pols;
        
        // Invoice for Two Way POL
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = fuel.company.id;
            si_mrl.Supplier__c = fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 3;
            si_mrl.Purchase_Order__c = fuel.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        }
        // Invoice for Three Way POL
        Supplier_Invoice__c si_mrl1 = new Supplier_Invoice__c();{
            si_mrl1.Company__c = fuel.company.id;
            si_mrl1.Supplier__c = fuel.remittosupplier.id;
            si_mrl1.Invoice_Type__c = 'Invoice';
            si_mrl1.Date_Invoiced__c = system.now();
            si_mrl1.Supplier_Invoice__c = '987612Test';
            si_mrl1.Payment_Term__c = fuel.terms.Id;
            si_mrl1.Invoice_Amount__c = 3;
            si_mrl1.Purchase_Order__c = fuel.PurchaseOrder.id;
            si_mrl1.Status__c = 'Draft';
            si_mrl1.exception__c = false;
            si_mrl1.exception_Details__c = null;
            si_mrl1.hold__c = false;
        }
        List<Supplier_Invoice__c> supInvoices = new List<Supplier_Invoice__c>{si_mrl,si_mrl1};
        insert supInvoices;
        
        // Invoice Lines for 2Way 
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = pol2Way.id;
            sil_mrl.Item__c = fuel.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= fuel.itemList[1].id, Source__c = fuel.itemList[1].Source__c, Class__c = fuel.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = fuel.clsObj.id, type__c = fuel.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 1;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }

        // Invoice Lines for 3Way        
        Supplier_Invoice_Line__c sil_mrl1 = new Supplier_Invoice_Line__c();{
            sil_mrl1.Purchase_Order_Line__c = pol3Way.id;
            sil_mrl1.Item__c = fuel.itemList[1].id;
            sil_mrl1.Item__r = new Item__c( id= fuel.itemList[1].id, Source__c = fuel.itemList[1].Source__c, Class__c = fuel.itemList[1].Class__c );
            sil_mrl1.Item__r.Class__r = new Class__c( id = fuel.clsObj.id, type__c = fuel.clsObj.type__c );
            sil_mrl1.Description__c = 'test';
            sil_mrl1.Invoice_Quantity__c = 1;
            sil_mrl1.Unit_Price__c = 1;//KNDY-14371
            sil_mrl1.Supplier_Invoice__c = si_mrl1.id;
            sil_mrl1.segment_exception__c = false;
            sil_mrl1.price_exception__c = false;
            sil_mrl1.quantity_exception__c = false;
            sil_mrl1.exception_details__c = null;
            sil_mrl1.matched__c = false;
        }       
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl1};
        insert supILs;
     
        pols.add(pol3Way);       
        // reset POL qty uninvoiced
        pols = [Select Id, Status__c, Name from Purchase_Order_Line__c
                where Id in :pols];
        for (Purchase_Order_Line__c pol: pols){
            if (pol.Id == pol2Way.Id){
                pol.Quantity_Matched__c = sil_mrl.Invoice_Quantity__c;
                pol2Way = pol;
            }
            else if (pol.Id == pol3Way.Id){
                pol.Quantity_Matched__c = sil_mrl1.Invoice_Quantity__c;
                pol3Way = pol;            
            }
            else{
            	   pol2Way_WithReceipts = pol;
            }
        }
        update pols;
        
        Test.startTest();
        
        // Cancel PO
        PurchaseOrderCloneExt poc = new PurchaseOrderCloneExt(new apexpages.standardController(po));
        poc.CancelOrder();
         
        system.assertEquals(Apexpages.getMessages().size(), 1);
        system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(Label.Cannot_cancel_Purchase_Order));
        system.assert(Apexpages.getMessages()[0].getdetail().contains(pol2Way.Name));
        system.assert(Apexpages.getMessages()[0].getdetail().contains(pol3Way.Name));
        system.assert(!Apexpages.getMessages()[0].getdetail().contains(pol2Way_WithReceipts.Name));    
        Test.stopTest();
    }

    //PTP-402 PTP-634 POLs without Supplier Invoices and Receipts can be cancelled.
    static testMethod void testCancelPO_Success(){
        TestFuelQuery fuel = new TestFuelQuery();
        List<Period__c> periodList = fuel.periodList;
        Purchase_Order__c po = fuel.purchaseOrder;
        
        // Three Way pol exists
        List<Purchase_Order_Line__c> purchaseOrderLines = fuel.purchaseOrderLines;
        system.assert(purchaseOrderLines.size() == 1);
        Purchase_Order_Line__c pol3Way = purchaseOrderLines[0];
        
        // Create Two Way POL       
        Purchase_Order_Line__c pol2Way = new Purchase_Order_Line__c();{
            pol2Way.Company__c = fuel.company.Id;
            pol2Way.Invoice_Matching__c = 'Two Way';
            pol2Way.Item__c = fuel.itemlist[1].Id;
            pol2Way.Order_Quantity__c = 20;
            pol2Way.Quantity_Matched__c = 0;
            //pol2Way.Quantity_Uninvoiced__c = 0;            
            pol2Way.Quantity_Received__c = 0;
            pol2Way.Purchase_Order__c = fuel.purchaseOrder.Id;
            pol2Way.Unit_Price__c = 1;
            pol2Way.Need_Date__c = System.today();
        }
        insert pol2Way;
        
        // No receipts or invoices on POLs
        Test.startTest();
        
        // Cancel PO
        PurchaseOrderCloneExt poc = new PurchaseOrderCloneExt(new apexpages.standardController(po));
        poc.CancelOrder();         
        system.assertEquals(Apexpages.getMessages().size(), 0);
        Test.stopTest();
    }   
}