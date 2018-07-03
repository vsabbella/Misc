/*** 
        //This code can be used to debug any exceptions
        Map<Id, Set<Task>> mapExceptionTasks = ExceptionService.fetchExceptionTasks(new Set<Id> {si_mrl.Id ,sil_mrl.Id});
        system.debug(LoggingLevel.Error, '>>>mapExceptionTasks:' + mapExceptionTasks);
        if (mapExceptionTasks.containsKey(si_mrl.Id)){  
            Set<Task> exceptions = mapExceptionTasks.get(si_mrl.Id);
            for (Task t: exceptions){
                system.debug(LoggingLevel.Error, '>>>SI Exception Task t:' + t);
            }
        }
        if (mapExceptionTasks.containsKey(si_mrl.Id)){  
            Set<Task> exceptions = mapExceptionTasks.get(sil_mrl.Id);
            for (Task t: exceptions){
                system.debug(LoggingLevel.Error, '>>>SIL Exception Task t:' + t);
            }
        }
***/
@isTest 
public with sharing class PTPCleanupTest {
    private static Testfuel globaltestdata;
    private static List<Period__c> periodList;
    static{
        globaltestdata = new testFuel();
        periodList = globaltestdata.periodList;
    }
    
	public static testmethod void cleanUp_3WayPOL_WithReceiptsAndSI(){
    	List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>();
    	for(integer i=0;i<24;i++) {
	    	Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
	            POLine1.Company__c = globalTestData.company.Id;
	            POLine1.Item__c = globalTestData.itemlist[1].Id;
	            POLine1.Order_Quantity__c = 100;
	            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
	            POLine1.Unit_Price__c = 10;
	            POLine1.Need_Date__c = System.today();
	            POLine1.Quantity_Received__c = 12345;
	            //POLine1.Quantity_Uninvoiced__c = 6789;
	        
	            polList.add(POLine1);
	        }
    	}
    	insert polList;
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            receivingDocument1.Date_Created__c = system.today();
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = polList[0].Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            //receiptLine1.Quantity_Declared__c = POLine.Order_Quantity__c;
            receiptLine1.Quantity_Received__c = 10;
            receiptLine1.Uninvoiced_Quantity__c = 6789;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
        }  
        
        Receipt_Line__c receiptLine2 = new Receipt_Line__c();{
            receiptLine2.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine2.Purchase_Order_Line__c = polList[0].Id;
            receiptLine2.Item__c = globalTestData.itemList[1].Id;
            receiptLine2.Company__c = globalTestData.company.Id;
            receiptLine2.Supplier__c = globalTestData.supplier.Id;
            //receiptLine2.Quantity_Declared__c = POLine.Order_Quantity__c;
            receiptLine2.Quantity_Received__c = 10;
            receiptLine2.Uninvoiced_Quantity__c = 6789;
            receiptLine2.Facility__c = globalTestData.facility.Id;
            receiptLine2.Location__c = globalTestData.location.Id;
            receiptLine2.Receiving_Document__c = receivingDocument1.Id;
        }
        List<Receipt_Line__c> RecLineList = new List<Receipt_Line__c>();
        RecLineList.add(receiptLine1);
        RecLineList.add(receiptLine2);
        insert RecLineList;
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
	        si_mrl.Company__c = globalTestData.company.id;
	        si_mrl.Supplier__c = globalTestData.remittosupplier.id;
	        si_mrl.Invoice_Type__c = 'Invoice';
	        si_mrl.Date_Invoiced__c = system.now();
	        si_mrl.Supplier_Invoice__c = '987612';
	        si_mrl.Payment_Term__c = globalTestData.terms.Id;
	        si_mrl.Invoice_Amount__c = 200;
	        si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
	        si_mrl.Status__c = 'Draft';
	        si_mrl.exception__c = false;
	        si_mrl.exception_Details__c = null;
	        si_mrl.hold__c = false;
	        si_mrl.Currency__c = TestFuel.currencyUSD.id;
        	insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
	        sil_mrl.Purchase_Order_Line__c = polList[0].Id;
	        sil_mrl.Item__c = globalTestData.itemList[1].id;
	        sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
	        sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
	        sil_mrl.Description__c = 'test';
	        sil_mrl.Invoice_Quantity__c = 20;
	        sil_mrl.Unit_Price__c = 10;//KNDY-14371
	        sil_mrl.Supplier_Invoice__c = si_mrl.id;
	        sil_mrl.segment_exception__c = false;
	        sil_mrl.price_exception__c = false;
			sil_mrl.Quantity_Received__c = 12345;
	        sil_mrl.matched__c = false;
	        insert sil_mrl;   
        } 
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(globaltestdata.company);
		PTPCleanup cleanupBatch = new PTPCleanup(sc);
		cleanupBatch.startBatch();
		Test.stopTest();
		receiptLine1 = [SELECT Id, Quantity_Received__c, Uninvoiced_Quantity__c, Purchase_Order_Line__c, Matched__c FROM Receipt_Line__c WHERE Id = :receiptLine1.Id];
		receiptLine2 = [SELECT Id, Quantity_Received__c, Uninvoiced_Quantity__c, Purchase_Order_Line__c, Matched__c FROM Receipt_Line__c WHERE Id = :receiptLine2.Id];
		
		Purchase_Order_Line__c POLine = [SELECT Id, Quantity_Received__c FROM Purchase_Order_Line__c WHERE Id = :receiptLine1.Purchase_Order_Line__c];
		
		System.AssertEquals([Select Count() FROM Purchase_Order_Line__c WHERE Quantity_Received__c != 12345],25);

		sil_mrl = [SELECT Id, Invoice_Quantity__c, Quantity_Received__c, Matched__c FROM Supplier_Invoice_Line__c WHERE Id = :sil_mrl.Id];
		
		System.AssertEquals(POLine.Quantity_Received__c, 20,'1');
		//System.AssertEquals(POLine.Quantity_Uninvoiced__c, 80,'POLQtyUninvoiced expected/actual : 80/'+ POLine.Quantity_Uninvoiced__c);
		
		System.AssertEquals(receiptLine1.Quantity_Received__c, 10,'3');
		System.AssertEquals(receiptLine1.Uninvoiced_Quantity__c, 0,'4');
		System.AssertEquals(receiptLine1.Matched__c, true,'5');
		
		System.AssertEquals(receiptLine2.Quantity_Received__c, 10,'6');
		System.AssertEquals(receiptLine2.Uninvoiced_Quantity__c, 0,'7');
		System.AssertEquals(receiptLine2.Matched__c, true,'8');
		
		System.AssertEquals(sil_mrl.Invoice_Quantity__c, 20,'9');
		System.AssertEquals(sil_mrl.Quantity_Received__c, 20,'10');
		System.AssertEquals(sil_mrl.Matched__c, true,'11');
		
	}
	
    public static testmethod void cleanUp_3WayPOL_WithReceiptsOnly_ASN(){
        List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>();
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            polList.add(POLine1);
        insert polList;
        Purchase_Order_Line__c POLine = [SELECT Id, Order_Quantity__c FROM Purchase_Order_Line__c WHERE Id = :POLine1.Id];
        //system.assertEquals(POLine.Quantity_Uninvoiced__c, POLine.Order_Quantity__c);
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Type__c = 'In Transit';
            receivingDocument1.Date_Created__c = system.today();
        }
        Receiving_Document__c receivingDocument2 = new Receiving_Document__c();{
            receivingDocument2 = new Receiving_Document__c();
            receivingDocument2.Company__c = globalTestData.company.Id;
            receivingDocument2.Supplier__c = globalTestData.supplier.Id;
            receivingDocument2.Status__c = 'Open';
            receivingDocument2.Type__c = 'Purchase Order Receipt';
            receivingDocument2.Date_Created__c = system.today();
        }
        List<Receiving_Document__c> rds = new List<Receiving_Document__c>{receivingDocument1, receivingDocument2};           
        insert rds;       
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = polList[0].Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = -100;
            receiptLine1.Uninvoiced_Quantity__c = null;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;            
        }  
        Receipt_Line__c receiptLine2 = new Receipt_Line__c();{
            receiptLine2.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine2.Purchase_Order_Line__c = POLine1.Id;
            receiptLine2.Item__c = globalTestData.itemList[1].Id;
            receiptLine2.Company__c = globalTestData.company.Id;
            receiptLine2.Supplier__c = globalTestData.supplier.Id;
            receiptLine2.Quantity_Received__c = 100;
            receiptLine2.Uninvoiced_Quantity__c = 100;
            receiptLine2.Facility__c = globalTestData.facility.Id;
            receiptLine2.Location__c = globalTestData.location.Id;
            receiptLine2.Receiving_Document__c = receivingDocument2.Id;
        } 
        List<Receipt_Line__c>  receiptLines = new List<Receipt_Line__c>{receiptLine1, receiptLine2}; 
        insert receiptLines;
                
        Test.startTest();
        POLine1.Quantity_Received__c = 12345;
        //POLine1.Quantity_Uninvoiced__c = 6789;
        update POLine1;
        PTPCleanup.doReset(new Set<Id>{POLine1.Id}, true);
        Test.stopTest();
        
        POLine = [SELECT Id, Order_Quantity__c, Quantity_Received__c  
                  FROM Purchase_Order_Line__c WHERE Id = :polList[0].Id];
        System.Assert(POLine.Quantity_Received__c != 12345);
        System.Assert(POLine.Quantity_Received__c == 100);
        //system.assertEquals(POLine.Quantity_Uninvoiced__c, POLine.Order_Quantity__c);  
    }
   
    static testMethod void cleanUp_3WayPOL_WithReceiptsAndDraftSI_ASN(){
        Purchase_Order__c po = globalTestData.purchaseOrder;       
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Purchase_Order__c = po.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }

        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'In Transit';
        }
        Receiving_Document__c receivingDocument2 = new Receiving_Document__c();{
            receivingDocument2 = new Receiving_Document__c();
            receivingDocument2.Company__c = globalTestData.company.Id;
            receivingDocument2.Supplier__c = globalTestData.supplier.Id;
            receivingDocument2.Status__c = 'Open';
            receivingDocument2.Date_Created__c = system.today();
            receivingDocument2.Type__c = 'Purchase Order Receipt';
        }
        List<Receiving_Document__c> rds = new List<Receiving_Document__c>{receivingDocument1, receivingDocument2};           
        insert rds;
                
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = po.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = -100;
            receiptLine1.Uninvoiced_Quantity__c = null;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
        }
                
        Receipt_Line__c receiptLine2 = new Receipt_Line__c();{
            receiptLine2.Purchase_Order__c = po.Id;
            receiptLine2.Purchase_Order_Line__c = POLine1.Id;
            receiptLine2.Item__c = globalTestData.itemList[1].Id;
            receiptLine2.Company__c = globalTestData.company.Id;
            receiptLine2.Supplier__c = globalTestData.supplier.Id;
            receiptLine2.Quantity_Received__c = 2;
            receiptLine2.Uninvoiced_Quantity__c = 2;
            receiptLine2.Facility__c = globalTestData.facility.Id;
            receiptLine2.Location__c = globalTestData.location.Id;
            receiptLine2.Receiving_Document__c = receivingDocument2.Id;
        } 
        List<Receipt_Line__c>  receiptLines = new List<Receipt_Line__c>{receiptLine1, receiptLine2}; 
        insert receiptLines;

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Supplier_Invoice__c = '987612ASN';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 4;
            si_mrl.Purchase_Order__c = po.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Quantity_Received__c = 1234;
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c();{
            sil_mrl2.Purchase_Order_Line__c = POLine1.id;
            sil_mrl2.Item__c = globalTestData.itemList[1].id;
            sil_mrl2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl2.Description__c = 'test';
            sil_mrl2.Invoice_Quantity__c = 1;
            sil_mrl2.Unit_Price__c = 1;//KNDY-14371
            sil_mrl2.Quantity_Received__c = 1234;
            sil_mrl2.Supplier_Invoice__c = si_mrl.id;
            sil_mrl2.segment_exception__c = false;
            sil_mrl2.price_exception__c = false;
            sil_mrl2.quantity_exception__c = false;
            sil_mrl2.exception_details__c = null;
            sil_mrl2.matched__c = false;
        }        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl2};
        insert supILs; 
        
        Test.startTest(); 
        POLine1.Quantity_Received__c = 1234; 
        //POLine1.Quantity_Uninvoiced__c = 1234;
        update POLine1; 
        PTPCleanup.doReset(new Set<Id>{POLine1.Id}, true);
        
        // Asserts after PTPCleanup run 
        Purchase_Order_Line__c pol = [Select Id, Quantity_Received__c
                                        from Purchase_Order_Line__c where Id = :POLine1.Id];
        //system.assertEquals(pol.Quantity_Uninvoiced__c, 96);
        system.assertEquals(pol.Quantity_Received__c, 2);       
        Supplier_Invoice__c si = [select id, name, exception__c, status__c,
                                    (select id, Exceptions_Count__c, matched__c,  
                                     Quantity_Received__c,Purchase_Order_Line__c 
                                     from Supplier_Invoice_lines__r) 
                                  from Supplier_Invoice__c where id =: si_mrl.id];    
        system.assertEquals('Draft',si.status__c);
        Decimal silQtyReceived = 0;
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
               if (sil.Quantity_Received__c != null){
                   silQtyReceived += sil.Quantity_Received__c;
               }
        }
        system.assertEquals(silQtyReceived, 2);
      

        Test.stopTest();   
    }
    
    public static testmethod void cleanUp_2WayPOL_WithSIOnly(){
        List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>();
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
            polList.add(POLine1);
        insert polList;
        Purchase_Order_Line__c POLine = [SELECT Id, Order_Quantity__c FROM Purchase_Order_Line__c WHERE Id = :POLine1.Id];
        //system.assertEquals(POLine.Quantity_Uninvoiced__c, POLine.Order_Quantity__c);
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 200;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            insert si_mrl;

        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();
            sil_mrl.Purchase_Order_Line__c = polList[0].Id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 20;
            sil_mrl.Unit_Price__c = 10;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.Quantity_Received__c = 12345; // correct value should be 0
            sil_mrl.matched__c = false;
        insert sil_mrl;
        
        Test.startTest();
        //POLine1.Quantity_Uninvoiced__c = 12345;
        POLine1.Quantity_Received__c = 12345;
        update POLine1;
        ApexPages.StandardController sc = new ApexPages.StandardController(globaltestdata.company);
        PTPCleanup cleanupBatch = new PTPCleanup(sc);
        cleanupBatch.startBatch();
        Test.stopTest();
        
        POLine = [SELECT Id, Order_Quantity__c, Quantity_Received__c 
                  FROM Purchase_Order_Line__c WHERE Id = :polList[0].Id];
        System.Assert(POLine.Quantity_Received__c != 12345);
        System.Assert(POLine.Quantity_Received__c == 0); // No receipts
        //system.assertNotEquals(POLine.Quantity_Uninvoiced__c, POLine.Order_Quantity__c);
        
        sil_mrl = [SELECT Id, Invoice_Quantity__c, Quantity_Received__c, Matched__c 
                   FROM Supplier_Invoice_Line__c WHERE Id = :sil_mrl.Id];
        
        //System.AssertEquals(POLine.Quantity_Uninvoiced__c, 80,'POLQtyUninvoiced expected/actual : 80/'+ POLine.Quantity_Uninvoiced__c);
        System.AssertEquals(sil_mrl.Invoice_Quantity__c, 20,'9');
        System.AssertEquals(sil_mrl.Quantity_Received__c, 0,'Incorrect Two Way SIL Quantity Received: ' +sil_mrl.Quantity_Received__c);
        System.AssertEquals(sil_mrl.Matched__c, true,'11');	
    }
    
    public static testmethod void cleanUp_2WayPOL_WithReceiptsOnly(){
        List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>();
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
            polList.add(POLine1);
        insert polList;
        Purchase_Order_Line__c POLine = [SELECT Id, Order_Quantity__c FROM Purchase_Order_Line__c WHERE Id = :POLine1.Id];
        //system.assertEquals(POLine.Quantity_Uninvoiced__c, POLine.Order_Quantity__c);
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            receivingDocument1.Date_Created__c = system.today();
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = polList[0].Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 10;
            receiptLine1.Uninvoiced_Quantity__c = 10;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            insert receiptLine1;
        }  
        
        Test.startTest();
        //POLine1.Quantity_Uninvoiced__c = 1234;
        POLine1.Quantity_Received__c = 1234;
        update POLine1;
        PTPCleanup.doReset(new Set<Id>{POLine1.Id}, true);
        Test.stopTest();
        
        POLine = [SELECT Id, Order_Quantity__c, Quantity_Received__c 
                  FROM Purchase_Order_Line__c WHERE Id = :polList[0].Id];
        System.Assert(POLine.Quantity_Received__c != 12345);
        System.Assert(POLine.Quantity_Received__c == 10);
        //system.assertEquals(POLine.Quantity_Uninvoiced__c, POLine.Order_Quantity__c);
    }
    
    public static testmethod void cleanupQuantities_ApprovedSI_3Way(){
        List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>();
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Quantity_Received__c = 100;
            POLine1.Need_Date__c = System.today();
            polList.add(POLine1);
        insert polList;
        Purchase_Order_Line__c POLine = [SELECT Id, Order_Quantity__c, Quantity_Received__c FROM Purchase_Order_Line__c WHERE Id = :POLine1.Id];
        //system.assertEquals(POLine.Quantity_Uninvoiced__c, POLine.Order_Quantity__c);
        system.assertEquals(POLine.Quantity_Received__c, 100);
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'Purchase Order Receipt';
        }
        Receiving_Document__c receivingDocument2 = new Receiving_Document__c();{
            receivingDocument2 = new Receiving_Document__c();
            receivingDocument2.Company__c = globalTestData.company.Id;
            receivingDocument2.Supplier__c = globalTestData.supplier.Id;
            receivingDocument2.Status__c = 'Open';
            receivingDocument2.Type__c = 'Purchase Order Receipt';
            receivingDocument2.Date_Created__c = system.today();
        }
        List<Receiving_Document__c> rds = new List<Receiving_Document__c>{ receivingDocument1,receivingDocument2};
        insert rds;
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 50;
            receiptLine1.Uninvoiced_Quantity__c = 50;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
        }
        Receipt_Line__c receiptLine2 = new Receipt_Line__c();{
            receiptLine2.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine2.Purchase_Order_Line__c = POLine1.Id;
            receiptLine2.Item__c = globalTestData.itemList[1].Id;
            receiptLine2.Company__c = globalTestData.company.Id;
            receiptLine2.Supplier__c = globalTestData.supplier.Id;
            receiptLine2.Quantity_Received__c = 50;
            receiptLine2.Uninvoiced_Quantity__c = 50;
            receiptLine2.Facility__c = globalTestData.facility.Id;
            receiptLine2.Location__c = globalTestData.location.Id;
            receiptLine2.Receiving_Document__c = receivingDocument2.Id;
        } 
        List<Receipt_Line__c>  receiptLines = new List<Receipt_Line__c>{receiptLine1,receiptLine2}; 
        insert receiptLines;
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 100;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = polList[0].Id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 100;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Unit_Price__c = 1;
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.Quantity_Received__c = 0;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        }
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>{si_mrl};
        supplierInvoiceService.inspectDraftInvoices(sup);

        sil_mrl = [SELECT Id, Invoice_Quantity__c, Quantity_Received__c, Matched__c, Supplier_Invoice__r.Status__c FROM Supplier_Invoice_Line__c WHERE Id = :sil_mrl.Id];
        system.assertEquals (sil_mrl.Quantity_Received__c, 100 );
        system.assertEquals(sil_mrl.Matched__c, true);
        system.assertEquals(sil_mrl.Supplier_Invoice__r.Status__c, 'Approved');

        List<Receipt_Line__c> rlList = [SELECT Id, Quantity_Received__c, Uninvoiced_Quantity__c, Purchase_Order_Line__c, Matched__c FROM Receipt_Line__c WHERE Id in :receiptLines];
        for (Receipt_Line__c rl : rlList){
            System.AssertEquals(rl.Uninvoiced_Quantity__c, 0,'Post Inspect - Expected rl uninvoiced qty - 0');
            System.AssertEquals(rl.Matched__c, true,'Post Inspect - Expected rl matched - true');
        }

        Test.startTest();
        //POLine1.Quantity_Uninvoiced__c = 1234;
        POLine1.Quantity_Received__c = 1234;
        update POLine1;
        
        receiptLine2.Uninvoiced_Quantity__c = 1234;
        receiptLine1.Uninvoiced_Quantity__c = 1234;
        update receiptLines;
        sil_mrl.Quantity_Received__c = 1234;
        update sil_mrl;
        
        PTPCleanup cleanupBatch = new PTPCleanup(new Set<Id> {POLine1.Id});
        cleanupBatch.startBatch();
        Test.stopTest();
        
        POLine = [SELECT Id, Quantity_Received__c FROM Purchase_Order_Line__c WHERE Id = :POLine.Id];
        System.AssertEquals(POLine.Quantity_Received__c, 100,'1');
        //System.AssertEquals(POLine.Quantity_Uninvoiced__c, 0,'POLQtyUninvoiced expected/actual : 0/'+ POLine.Quantity_Uninvoiced__c);

        rlList = [SELECT Id, Quantity_Received__c, Uninvoiced_Quantity__c, Purchase_Order_Line__c, Matched__c FROM Receipt_Line__c WHERE Id in :receiptLines];
        for (Receipt_Line__c rl : rlList){
           System.AssertEquals(rl.Quantity_Received__c, 50,'6');
           System.AssertEquals(rl.Uninvoiced_Quantity__c, 0,'7');
           System.AssertEquals(rl.Matched__c, true,'8');
        } 

        sil_mrl = [SELECT Id, Invoice_Quantity__c, Quantity_Received__c, Matched__c FROM Supplier_Invoice_Line__c WHERE Id = :sil_mrl.Id];
        System.AssertEquals(sil_mrl.Invoice_Quantity__c, 100,'9');
        System.AssertEquals(sil_mrl.Quantity_Received__c, 100,'10');
        System.AssertEquals(sil_mrl.Matched__c, true,'11');
        
    }
   
    public static testmethod void cleanupFlags_ApprovedSI_3Way(){
        List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>();
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Quantity_Received__c = 100;
            POLine1.Need_Date__c = System.today();
            polList.add(POLine1);
        insert polList;
        Purchase_Order_Line__c POLine = [SELECT Id, Order_Quantity__c, Quantity_Received__c FROM Purchase_Order_Line__c WHERE Id = :POLine1.Id];
        //system.assertEquals(POLine.Quantity_Uninvoiced__c, POLine.Order_Quantity__c);
        system.assertEquals(POLine.Quantity_Received__c, 100);
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'Purchase Order Receipt';
        }
        Receiving_Document__c receivingDocument2 = new Receiving_Document__c();{
            receivingDocument2 = new Receiving_Document__c();
            receivingDocument2.Company__c = globalTestData.company.Id;
            receivingDocument2.Supplier__c = globalTestData.supplier.Id;
            receivingDocument2.Status__c = 'Open';
            receivingDocument2.Type__c = 'Purchase Order Receipt';
            receivingDocument2.Date_Created__c = system.today();
        }
        List<Receiving_Document__c> rds = new List<Receiving_Document__c>{ receivingDocument1,receivingDocument2};
        insert rds;
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 50;
            receiptLine1.Uninvoiced_Quantity__c = 50;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
        }
        Receipt_Line__c receiptLine2 = new Receipt_Line__c();{
            receiptLine2.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine2.Purchase_Order_Line__c = POLine1.Id;
            receiptLine2.Item__c = globalTestData.itemList[1].Id;
            receiptLine2.Company__c = globalTestData.company.Id;
            receiptLine2.Supplier__c = globalTestData.supplier.Id;
            receiptLine2.Quantity_Received__c = 50;
            receiptLine2.Uninvoiced_Quantity__c = 50;
            receiptLine2.Facility__c = globalTestData.facility.Id;
            receiptLine2.Location__c = globalTestData.location.Id;
            receiptLine2.Receiving_Document__c = receivingDocument2.Id;
        } 
        List<Receipt_Line__c>  receiptLines = new List<Receipt_Line__c>{receiptLine1,receiptLine2}; 
        insert receiptLines;
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 100;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = polList[0].Id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 100;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Unit_Price__c = 1;
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.Quantity_Received__c = 0;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        } 
        
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>{si_mrl};
        supplierInvoiceService.inspectDraftInvoices(sup);

        sil_mrl = [SELECT Id, Invoice_Quantity__c, Quantity_Received__c, Matched__c, Supplier_Invoice__r.Status__c FROM Supplier_Invoice_Line__c WHERE Id = :sil_mrl.Id];
        system.assertEquals (sil_mrl.Quantity_Received__c, 100 );
        system.assertEquals(sil_mrl.Matched__c, true);
        system.assertEquals(sil_mrl.Supplier_Invoice__r.Status__c, 'Approved');

        List<Receipt_Line__c> rlList = [SELECT Id, Quantity_Received__c, Invoiced__c, Uninvoiced_Quantity__c, Purchase_Order_Line__c, Matched__c FROM Receipt_Line__c WHERE Id in :receiptLines];
        for (Receipt_Line__c rl : rlList){
            System.AssertEquals(rl.Uninvoiced_Quantity__c, 0,'Post Inspect - Expected rl uninvoiced qty - 0');
            System.AssertEquals(rl.Matched__c, true,'Post Inspect - Expected rl matched - true');
            System.AssertEquals(rl.Invoiced__c, true,'Post Inspect - Expected rl Invoiced in full - true');

        }

        Test.startTest();
        //POLine1.Quantity_Uninvoiced__c = 1234;
        POLine1.Quantity_Received__c = 1234;
        update POLine1;
        
        receiptLine2.Invoiced__c = false;
        receiptLine2.Matched__c = false;
        receiptLine1.Invoiced__c = false;
        update receiptLines;
        sil_mrl.Matched__c = true;
        update sil_mrl;
        
        PTPCleanup cleanupBatch = new PTPCleanup(new Set<Id> {POLine1.Id});
        cleanupBatch.startBatch();
        Test.stopTest();
        
        POLine = [SELECT Id, Quantity_Received__c FROM Purchase_Order_Line__c WHERE Id = :POLine.Id];
        System.AssertEquals(POLine.Quantity_Received__c, 100,'1');
        //System.AssertEquals(POLine.Quantity_Uninvoiced__c, 0,'POLQtyUninvoiced expected/actual : 0/'+ POLine.Quantity_Uninvoiced__c);

        rlList = [SELECT Id, Quantity_Received__c, Uninvoiced_Quantity__c, Invoiced__c, Matched__c FROM Receipt_Line__c WHERE Id in :receiptLines];
        for (Receipt_Line__c rl : rlList){
           System.AssertEquals(rl.Quantity_Received__c, 50,'6');
           System.AssertEquals(rl.Uninvoiced_Quantity__c, 0,'7');
           System.AssertEquals(rl.Matched__c, true,'8');
           System.AssertEquals(rl.Invoiced__c, true, '8.1');
        } 

        sil_mrl = [SELECT Id, Invoice_Quantity__c, Quantity_Received__c, Matched__c FROM Supplier_Invoice_Line__c WHERE Id = :sil_mrl.Id];
        System.AssertEquals(sil_mrl.Invoice_Quantity__c, 100,'9');
        System.AssertEquals(sil_mrl.Quantity_Received__c, 100,'10');
        System.AssertEquals(sil_mrl.Matched__c, true,'11');
        
    }

    public static testmethod void cleanupQuantities_ApprovedSI_2Way(){
        List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>();
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Quantity_Received__c = 100;
            POLine1.Need_Date__c = System.today();
            polList.add(POLine1);
        insert polList;
        Purchase_Order_Line__c POLine = [SELECT Id, Order_Quantity__c, Quantity_Received__c FROM Purchase_Order_Line__c WHERE Id = :POLine1.Id];
        //system.assertEquals(POLine.Quantity_Uninvoiced__c, POLine.Order_Quantity__c);
        system.assertEquals(POLine.Quantity_Received__c, 100);
        
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Approval_Status__c = 'Approved';
        update po;
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 100;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = polList[0].Id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 100;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Unit_Price__c = 1;
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.Quantity_Received__c = 0;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        } 
        Test.startTest();
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>{si_mrl};
        supplierInvoiceService.inspectDraftInvoices(sup);

        //POLine1.Quantity_Uninvoiced__c = 1234;
        POLine1.Quantity_Received__c = 1234;
        update POLine1;
        
        sil_mrl.Quantity_Received__c = 1234;
        update sil_mrl;
        
        PTPCleanup cleanupBatch = new PTPCleanup(new Set<Id> {POLine1.Id});
        cleanupBatch.startBatch();
        Test.stopTest();
        
        POLine = [SELECT Id, Quantity_Received__c FROM Purchase_Order_Line__c WHERE Id = :POLine.Id];
        System.AssertEquals(POLine.Quantity_Received__c, 0,'1');
        //System.AssertEquals(POLine.Quantity_Uninvoiced__c, 0,'POLQtyUninvoiced expected/actual : 0/'+ POLine.Quantity_Uninvoiced__c);

        sil_mrl = [SELECT Id, Invoice_Quantity__c, Quantity_Received__c, Matched__c FROM Supplier_Invoice_Line__c WHERE Id = :sil_mrl.Id];
        System.AssertEquals(sil_mrl.Invoice_Quantity__c, 100,'9');
        System.AssertEquals(sil_mrl.Quantity_Received__c, 100,'10');
        System.AssertEquals(sil_mrl.Matched__c, true,'11');
    }
    
    public static testmethod void cleanupFlags_ApprovedSI_2Way(){
        List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>();
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Quantity_Received__c = 100;
            POLine1.Need_Date__c = System.today();
            polList.add(POLine1);
        insert polList;
        Purchase_Order_Line__c POLine = [SELECT Id, Order_Quantity__c, Quantity_Received__c FROM Purchase_Order_Line__c WHERE Id = :POLine1.Id];
        //system.assertEquals(POLine.Quantity_Uninvoiced__c, POLine.Order_Quantity__c);
        system.assertEquals(POLine.Quantity_Received__c, 100);
        
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Approval_Status__c = 'Approved';
        update po;
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 100;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = polList[0].Id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 50;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Unit_Price__c = 1;
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.Quantity_Received__c = 0;
            sil_mrl.matched__c = false;
        } 
        
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c();{
            sil_mrl2.Purchase_Order_Line__c = polList[0].Id;
            sil_mrl2.Item__c = globalTestData.itemList[1].id;
            sil_mrl2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl2.Description__c = 'test';
            sil_mrl2.Invoice_Quantity__c = 50;
            sil_mrl2.Unit_Price__c = 1;//KNDY-14371
            sil_mrl2.Unit_Price__c = 1;
            sil_mrl2.Supplier_Invoice__c = si_mrl.id;
            sil_mrl2.segment_exception__c = false;
            sil_mrl2.price_exception__c = false;
            sil_mrl2.Quantity_Received__c = 0;
            sil_mrl2.matched__c = false;
        }
        
        List<Supplier_Invoice_Line__c> sils = new List<Supplier_Invoice_Line__c>{sil_mrl, sil_mrl2};
        insert sils;
        
        Test.startTest();
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>{si_mrl};
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        //POLine1.Quantity_Uninvoiced__c = 1234;
        POLine1.Quantity_Received__c = 1234;
        update POLine1;
        
        sil_mrl.Matched__c = false;
        sil_mrl2.Matched__c = false;
        sil_mrl.Quantity_Received__c = 1234;
        sil_mrl2.Quantity_Received__c = 1234;
        update sils;
        
        PTPCleanup cleanupBatch = new PTPCleanup(new Set<Id> {POLine1.Id});
        cleanupBatch.startBatch();
        Test.stopTest();
        
        POLine = [SELECT Id, Quantity_Received__c FROM Purchase_Order_Line__c WHERE Id = :POLine.Id];
        System.AssertEquals(POLine.Quantity_Received__c, 0,'1');
        //System.AssertEquals(POLine.Quantity_Uninvoiced__c, 0,'POLQtyUninvoiced expected/actual : 0/'+ POLine.Quantity_Uninvoiced__c);

        sils = [SELECT Id, Invoice_Quantity__c, Quantity_Received__c, Matched__c FROM Supplier_Invoice_Line__c WHERE Id in : sils];
        for (Supplier_Invoice_Line__c sil : sils){
            System.AssertEquals(sil_mrl.Quantity_Received__c, 1234,'10');// 2-Way SIL Qty Received is not updated
            System.AssertEquals(sil.Matched__c, true,'11');
        }
    }

    public static testmethod void cleanupQuantities_ClosedSI_3Way(){
        List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>();
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 10;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Quantity_Received__c = 1234;
            POLine1.Need_Date__c = System.today();
            polList.add(POLine1);
        insert polList;

        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'Purchase Order Receipt';
        }
        Receiving_Document__c receivingDocument2 = new Receiving_Document__c();{
            receivingDocument2 = new Receiving_Document__c();
            receivingDocument2.Company__c = globalTestData.company.Id;
            receivingDocument2.Supplier__c = globalTestData.supplier.Id;
            receivingDocument2.Status__c = 'Open';
            receivingDocument2.Type__c = 'Purchase Order Receipt';
            receivingDocument2.Date_Created__c = system.today();
        }
        
        Receiving_Document__c receivingDocument3 = new Receiving_Document__c();{
            receivingDocument3 = new Receiving_Document__c();
            receivingDocument3.Company__c = globalTestData.company.Id;
            receivingDocument3.Supplier__c = globalTestData.supplier.Id;
            receivingDocument3.Status__c = 'Open';
            receivingDocument3.Type__c = 'Purchase Order Receipt';
            receivingDocument3.Date_Created__c = system.today();
        }
        List<Receiving_Document__c> rds = new List<Receiving_Document__c>{ receivingDocument1,receivingDocument2,receivingDocument3};
        insert rds;
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 4;
            receiptLine1.Uninvoiced_Quantity__c = 1234;
            receiptLine1.Invoiced__c = true;
            receiptLine1.Matched__c = true;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
        }
        Receipt_Line__c receiptLine2 = new Receipt_Line__c();{
            receiptLine2.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine2.Purchase_Order_Line__c = POLine1.Id;
            receiptLine2.Item__c = globalTestData.itemList[1].Id;
            receiptLine2.Company__c = globalTestData.company.Id;
            receiptLine2.Supplier__c = globalTestData.supplier.Id;
            receiptLine2.Quantity_Received__c = 4;
            receiptLine2.Uninvoiced_Quantity__c = 1234;
            receiptLine2.Facility__c = globalTestData.facility.Id;
            receiptLine2.Location__c = globalTestData.location.Id;
            receiptLine2.Receiving_Document__c = receivingDocument2.Id;
        }
        Receipt_Line__c receiptLine3 = new Receipt_Line__c();{
            receiptLine3.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine3.Purchase_Order_Line__c = POLine1.Id;
            receiptLine3.Item__c = globalTestData.itemList[1].Id;
            receiptLine3.Company__c = globalTestData.company.Id;
            receiptLine3.Supplier__c = globalTestData.supplier.Id;
            receiptLine3.Quantity_Received__c = 2;
            receiptLine3.Uninvoiced_Quantity__c = 1234;
            receiptLine3.Facility__c = globalTestData.facility.Id;
            receiptLine3.Location__c = globalTestData.location.Id;
            receiptLine3.Receiving_Document__c = receivingDocument2.Id;
        }
        List<Receipt_Line__c>  receiptLines = new List<Receipt_Line__c>{receiptLine1,receiptLine2,receiptLine3}; 
        insert receiptLines;
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612-0';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 3;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
        }
        Supplier_Invoice__c si_mrl2 = new Supplier_Invoice__c();{
            si_mrl2.Company__c = globalTestData.company.id;
            si_mrl2.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl2.Invoice_Type__c = 'Invoice';
            si_mrl2.Date_Invoiced__c = system.now();
            si_mrl2.Supplier_Invoice__c = '987612-2';
            si_mrl2.Payment_Term__c = globalTestData.terms.Id;
            si_mrl2.Invoice_Amount__c = 4;
            si_mrl2.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl2.Status__c = 'Incomplete';
            si_mrl2.exception__c = false;
            si_mrl2.exception_Details__c = null;
            si_mrl2.hold__c = false;
            si_mrl2.Currency__c = TestFuel.currencyUSD.id;
        }
        Supplier_Invoice__c si_mrl3 = new Supplier_Invoice__c();{
            si_mrl3.Company__c = globalTestData.company.id;
            si_mrl3.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl3.Invoice_Type__c = 'Invoice';
            si_mrl3.Date_Invoiced__c = system.now();
            si_mrl3.Supplier_Invoice__c = '987612-1';
            si_mrl3.Payment_Term__c = globalTestData.terms.Id;
            si_mrl3.Invoice_Amount__c = 3;
            si_mrl3.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl3.Status__c = 'Draft';
            si_mrl3.exception__c = false;
            si_mrl3.exception_Details__c = null;
            si_mrl3.hold__c = false;
            si_mrl3.Currency__c = TestFuel.currencyUSD.id;
        }
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>{si_mrl,si_mrl2,si_mrl3};
        insert sup;
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = polList[0].Id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Unit_Price__c = 1;
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.Quantity_Received__c = 1234;
            sil_mrl.Matched__c = false;
        }
        
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c();{
            sil_mrl2.Purchase_Order_Line__c = polList[0].Id;
            sil_mrl2.Item__c = globalTestData.itemList[1].id;
            sil_mrl2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl2.Description__c = 'test';
            sil_mrl2.Invoice_Quantity__c = 4;
            sil_mrl2.Unit_Price__c = 1;//KNDY-14371
            sil_mrl2.Unit_Price__c = 1;
            sil_mrl2.Supplier_Invoice__c = si_mrl2.id;
            sil_mrl2.segment_exception__c = false;
            sil_mrl2.price_exception__c = false;
            sil_mrl2.Quantity_Received__c = 1234;
            sil_mrl2.Matched__c = false;
        }
        
        Supplier_Invoice_Line__c sil_mrl3 = new Supplier_Invoice_Line__c();{
            sil_mrl3.Purchase_Order_Line__c = polList[0].Id;
            sil_mrl3.Item__c = globalTestData.itemList[1].id;
            sil_mrl3.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl3.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl3.Description__c = 'test';
            sil_mrl3.Invoice_Quantity__c = 3;
            sil_mrl3.Unit_Price__c = 1;//KNDY-14371
            sil_mrl3.Unit_Price__c = 1;
            sil_mrl3.Supplier_Invoice__c = si_mrl3.id;
            sil_mrl3.segment_exception__c = false;
            sil_mrl3.price_exception__c = false;
            sil_mrl3.Quantity_Received__c = 1234;
            sil_mrl3.Matched__c = true;
        }
        
        List<Supplier_Invoice_Line__c> supLines = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl2,sil_mrl3};
        insert supLines;
        
        supplierInvoiceService.inspectDraftInvoices(sup);

        Test.startTest();
        //POLine1.Quantity_Uninvoiced__c = 1234;
        POLine1.Quantity_Received__c = 1234;
        update POLine1;

        receiptLine2.Uninvoiced_Quantity__c = 1234;
        receiptLine1.Uninvoiced_Quantity__c = 1234;
        receiptLine3.Uninvoiced_Quantity__c = 1234;
        update receiptLines;
        
        sil_mrl.Quantity_Received__c = 1234;
        sil_mrl2.Quantity_Received__c = 1234;
        sil_mrl3.Quantity_Received__c = 1234;
        update supLines;
       
        PTPCleanup cleanupBatch = new PTPCleanup(new Set<Id> {POLine1.Id});
        cleanupBatch.startBatch();
        Test.stopTest();
        
        Purchase_Order_Line__c POLine = [SELECT Id, Quantity_Received__c FROM Purchase_Order_Line__c WHERE Id = :POLine1.Id];
        System.AssertEquals(POLine.Quantity_Received__c, 10,'1');
        //System.AssertEquals(POLine.Quantity_Uninvoiced__c, 0,'POLQtyUninvoiced expected/actual : 0/'+ POLine.Quantity_Uninvoiced__c);
        
        Decimal matchedRLQty = 0;
        receiptLines = [SELECT Id, Quantity_Received__c, Uninvoiced_Quantity__c, Purchase_Order_Line__c, Matched__c FROM Receipt_Line__c WHERE Id in :receiptLines];
        for (Receipt_Line__c rl : receiptLines){
            system.assert(rl.Uninvoiced_Quantity__c <= rl.Quantity_Received__c);
            matchedRLQty += (rl.Quantity_Received__c - rl.Uninvoiced_Quantity__c);
            if (rl.Uninvoiced_Quantity__c == 0){
                rl.Matched__c = true;
                rl.Invoiced__c = true;
            }
        }
         
        Decimal matchedSILQty = 0;
        supLines = [SELECT Id, Invoice_Quantity__c, Quantity_Received__c, Matched__c FROM Supplier_Invoice_Line__c WHERE Id in :supLines];
        for (Supplier_Invoice_Line__c sil : supLines){
            system.assert(sil.Quantity_Received__c <= sil.Invoice_Quantity__c);
            matchedSILQty += sil.Quantity_Received__c;
            if (sil.Quantity_Received__c == sil.Invoice_Quantity__c){
                sil.Matched__c = true;
            }
        }
        system.assert(  matchedRLQty == matchedSILQty);
    }
}