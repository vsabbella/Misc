@isTest	
public class ReceivingDocumentAccountingTest {
	
	public class TestReceiptData{
		public TestDataForFinance data = new TestDataForFinance();
		public List<Receiving_Document__c> receivingDocList = new List<Receiving_Document__c>(); 
		public Receiving_Document__c receivingdocument1, receivingdocument2, receivingdocument3;
		public List<Receipt_Line__c> receiptinvoicelineList = new List<Receipt_Line__c>();
		public Receipt_Line__c receiptinvoiceline1, receiptinvoiceline2, receiptinvoiceline3, receiptinvoiceline4, receiptinvoiceline5;
		
		public TestReceiptData(){
			generateData();
		}
		
		public void generateData(){
	        
	        receivingdocument1=new Receiving_Document__c();
	        receivingdocument1.Company__c=data.company.Id;
	        receivingdocument1.Supplier__c=data.supplier.Id;
	        receivingdocument1.Status__c = 'Open'; 
            //FIN-566 fix -ASN Accounting	        
            receivingdocument1.Type__c = 'Purchase Order Receipt';	        
	        receivingdocument1.Date_Received__c = System.now();
	        //receivingdocument1.Finalized__c = true;
	        receivingdocument1.Transaction_Date__c = system.now();
	        //receivingdocument1.Finalized_Date__c = system.now();
	        receivingdocument1.Currency__c = TestFuel.currencyUSD.id;
	        //insert receivingdocument1;
	        receivingDocList.add(receivingdocument1);
	                
	        receivingdocument2=new Receiving_Document__c();
	        receivingdocument2.Company__c=data.company.Id;
	        receivingdocument2.Supplier__c=data.supplier.Id;
	        receivingdocument2.Status__c = 'Open';   
            //FIN-566 fix -ASN Accounting	        
            receivingdocument2.Type__c = 'Advanced Shipment Notice';	             
	        receivingdocument2.Date_Received__c = System.now();
	        //receivingdocument2.Finalized__c = true;
	        receivingdocument2.Transaction_Date__c = system.now();
	        //receivingdocument2.Finalized_Date__c = system.now();
	        receivingdocument2.Currency__c = TestFuel.currencyUSD.id;
	        //insert receivingdocument2;
	        receivingDocList.add(receivingdocument2);
	        
	        receivingdocument3=new Receiving_Document__c();
	        receivingdocument3.Company__c=data.company.Id;
	        receivingdocument3.Supplier__c=data.supplier.Id;
	        receivingdocument3.Status__c = 'Open';     
            //FIN-566 fix -ASN Accounting	        
            receivingdocument3.Type__c = 'Advanced Shipment Notice';	           
	        receivingdocument3.Date_Received__c = System.now();
	        //receivingdocument3.Finalized__c = true;
	        receivingdocument3.Transaction_Date__c = system.now();
	        //receivingdocument3.Finalized_Date__c = system.now();
	        receivingdocument3.Currency__c = TestFuel.currencyUSD.id;        
	        //insert receivingdocument3;
	        receivingDocList.add(receivingdocument3);      
	        
	        insert receivingDocList;      
	            
	            
	        List<Purchase_Order_Line__c> polineList = [select Id, Purchase_Order__c, Item__c,Unit_Price__c,Order_Quantity__c  
	                                                    from Purchase_Order_Line__c 
	                                                    where Purchase_Order__c  in (:data.purchaseOrder1.id, :data.purchaseOrder2.id, :data.purchaseOrder3.id)];
	                                                         
			
			receiptinvoiceline1 = new Receipt_Line__c();
			receiptinvoiceline1.Item__c = data.itemList[0].id;
			receiptinvoiceline1.Company__c = data.company.id;
			receiptinvoiceline1.Supplier__c=data.supplier.Id;
			receiptinvoiceline1.Status__c = 'Open';     
			receiptinvoiceline1.Receiving_Document__c=receivingdocument1.Id;
			receiptinvoiceline1.Location__c = data.location.id;
			receiptinvoiceline1.Unit_Price__c = 15;
			receiptinvoiceline1.Purchase_Order__c = data.purchaseOrder1.id;
			receiptinvoiceline1.Purchase_Order_Line__c = polineList[0].ID;
			receiptinvoiceline1.Quantity_Received__c = 6;
			receiptinvoiceline1.Extended_Cost__c = 70;
			receiptinvoiceline1.Subtransaction_Type__c = 'Goods';		
			receiptinvoicelineList.add(receiptinvoiceline1); 
	                
	        receiptinvoiceline2 = new Receipt_Line__c();
	        receiptinvoiceline2.Item__c = data.itemList[0].id;
	        receiptinvoiceline2.Company__c = data.company.id;
	        receiptinvoiceline2.Supplier__c=data.supplier.Id;
	        receiptinvoiceline2.Status__c = 'Open';     
	        receiptinvoiceline2.Receiving_Document__c=receivingdocument2.Id;
	        receiptinvoiceline2.Location__c = data.location.id;
	        receiptinvoiceline2.Unit_Price__c = 15;
	        receiptinvoiceline2.Purchase_Order__c = data.purchaseOrder2.id;
	        receiptinvoiceline2.Purchase_Order_Line__c = polineList[1].ID;
	        receiptinvoiceline2.Quantity_Received__c = 6;
	        receiptinvoiceline2.Extended_Cost__c = 70;
	        receiptinvoiceline2.Subtransaction_Type__c = 'Goods';
	        receiptinvoicelineList.add(receiptinvoiceline2);
	                
	        receiptinvoiceline3 = new Receipt_Line__c();
	        receiptinvoiceline3.Item__c = data.itemList[0].id;
	        receiptinvoiceline3.Company__c = data.company.id;
	        receiptinvoiceline3.Supplier__c=data.supplier.Id;
	        receiptinvoiceline3.Status__c = 'Open';     
	        receiptinvoiceline3.Receiving_Document__c=receivingdocument2.Id;
	        receiptinvoiceline3.Location__c = data.location.id;
	        receiptinvoiceline3.Unit_Price__c = 15;
	        receiptinvoiceline3.Purchase_Order__c = data.purchaseOrder2.id;
	        receiptinvoiceline3.Purchase_Order_Line__c = polineList[2].ID;
	        receiptinvoiceline3.Quantity_Received__c = 6;
	        receiptinvoiceline3.Extended_Cost__c = 70;
	        receiptinvoiceline3.Subtransaction_Type__c = 'Goods';
	        receiptinvoicelineList.add(receiptinvoiceline3);
	                
	        receiptinvoiceline4 = new Receipt_Line__c();
	        receiptinvoiceline4.Item__c = data.itemList[0].id;
	        receiptinvoiceline4.Company__c = data.company.id;
	        receiptinvoiceline4.Supplier__c=data.supplier.Id;
	        receiptinvoiceline4.Status__c = 'Open';     
	        receiptinvoiceline4.Receiving_Document__c=receivingdocument3.Id;
	        receiptinvoiceline4.Location__c = data.location.id;
	        receiptinvoiceline4.Unit_Price__c = 15;
	        receiptinvoiceline4.Purchase_Order__c = data.purchaseOrder3.id;
	        receiptinvoiceline4.Purchase_Order_Line__c = polineList[3].ID;
	        receiptinvoiceline4.Quantity_Received__c = 6;
	        receiptinvoiceline4.Extended_Cost__c = 70;
	        receiptinvoiceline4.Subtransaction_Type__c = 'Goods';
	        receiptinvoicelineList.add(receiptinvoiceline4);
	                
	        receiptinvoiceline5 = new Receipt_Line__c();
	        receiptinvoiceline5.Item__c = data.itemList[0].id;
	        receiptinvoiceline5.Company__c = data.company.id;
	        receiptinvoiceline5.Supplier__c=data.supplier.Id;
	        receiptinvoiceline5.Status__c = 'Open';     
	        receiptinvoiceline5.Receiving_Document__c=receivingdocument3.Id;
	        receiptinvoiceline5.Location__c = data.location.id;
	        receiptinvoiceline5.Unit_Price__c = 15;
	        receiptinvoiceline5.Purchase_Order__c = data.purchaseOrder3.id;
	        receiptinvoiceline5.Purchase_Order_Line__c = polineList[4].ID;
	        receiptinvoiceline5.Quantity_Received__c = 6;
	        receiptinvoiceline5.Extended_Cost__c = 70;
	        receiptinvoiceline5.Subtransaction_Type__c = 'Goods';
	        receiptinvoicelineList.add(receiptinvoiceline5);
	                
			insert receiptinvoicelineList;
		}
	} 
		
	// Test Receiving Document Accounting
	public static testmethod void testRDAccounting(){
		
		TestReceiptData td = new TestReceiptData();
		
		
		for(Receiving_Document__c rd : td.receivingDocList){
			rd.finalized__c = true;
		}
		
		update td.receivingDocList;
		
        Test.startTest();
        
        //loop throught the receiptlines and null out the line types so it matches with the accounting rules in the test data
        //it was defaulted to the PO line's line type
        
        Receiving_Document__c rd1 = [Select id, Name, Finalized__c, Finalized_hidden__c
                                from Receiving_Document__c 
                                where id = :td.receivingdocument1.id];
            
        system.assertEquals(true, rd1.Finalized__c);
        system.assertEquals(true, rd1.Finalized_hidden__c);
            
        List<Receipt_Line__c> rdLines = [Select id, Name, Item__c, Supplier__c, Status__c, Receiving_Document__c, Purchase_Order__c,Purchase_Price__c,(select id from Inventory_Transactions__r) from Receipt_Line__c where Receiving_Document__c in :td.receivingDocList]; 
            
        boolean sawException = false;
        try{
            rd1.Finalized__c = false;
            update rd1;
        }catch(Exception e){
            sawException = true;
        }
            
		system.assertEquals(true, sawException);
	    ReceivingDocumentAccounting rda = new ReceivingDocumentAccounting();
	    //rda.execute(td.receivingDocList);	
	    rda.execute(rdLines);	
            
	    Set<Id> RcptIds = new Set<Id>();
	    for(Receiving_Document__c rcpt: td.receivingDocList){
	        RcptIds.add(rcpt.id);
	    }

              
        List<Accounting_Entry__c> accountingEntryListPOReceipt = [Select id, Name, Receiving_Document__c,(select Amount_CR__c, Amount_DR__c, Receipt_Line__c, Receipt_Line__r.Purchase_price__c from Accounting_Entry_Lines__r ) 
                                                                    from Accounting_Entry__c
                                                                    where Receiving_Document__c in :RcptIds];
        list<Accounting_Entry_line__c> aellist = new list<Accounting_Entry_line__c>();
        for(Accounting_Entry__c ae:accountingEntryListPOReceipt) {
        	
        	for(Accounting_Entry_line__c ael :ae.Accounting_Entry_Lines__r){
         		system.assert((ael.Amount_CR__c == ael.Receipt_Line__r.Purchase_price__c || ael.Amount_DR__c == ael.Receipt_Line__r.Purchase_price__c), 'aellist:  ' + aellist );
        		aellist.add(ael);
        	}
        
        }                                                           
                                                                    
        Test.stopTest();                                                        
      	system.debug('accountingEntryListPOReceipt: '+ accountingEntryListPOReceipt);     
        system.assertNotEquals(null, accountingEntryListPOReceipt);
        system.assertEquals(3, accountingEntryListPOReceipt.size());
		
	}	
	
	public static testmethod void testFinalizeHeaderValidation(){
		
		TestReceiptData td = new TestReceiptData();
		
		for(Receiving_Document__c rd : td.receivingDocList){
			rd.finalized__c = true;
		}
		
		update td.receivingDocList;
		
		Test.startTest();
		string trxnCurr = td.receivingDocList[0].Currency__c;
        boolean sawException = false;
        string exMsg;
        try{
            td.receivingDocList[0].Currency__c = null;
            update td.receivingDocList[0];
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to edit a finalized doc ' + exMsg );
        
        sawException = false;
        exMsg = null;
        td.receivingDocList[0].Currency__c = trxnCurr;
        try{
            delete td.receivingDocList;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to delete a finalized doc ' + exMsg );
		Test.stopTest();   
		
		
	}
	
	public static testMethod void testFinalizeLineEditValidation(){
    	
        TestReceiptData td = new TestReceiptData();
		
		for(Receiving_Document__c rd : td.receivingDocList){
			rd.finalized__c = true;
		}
		
		update td.receivingDocList;
        
        test.startTest();
        
        
	    for(Receipt_Line__c rl : td.receiptinvoicelineList){
		    rl.Subtransaction_type__c = 'Change';
		}
		
		boolean sawException = false;
        string exMsg = null;
        try{
        	update td.receiptinvoicelineList;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to edit finalized doc lines ' + exMsg );
    }
    
        
    public static testMethod void testFinalizeLineDeleteValidation(){
    	
    	TestReceiptData td = new TestReceiptData();
		
		for(Receiving_Document__c rd : td.receivingDocList){
			rd.finalized__c = true;
		}
		
		update td.receivingDocList;
        
        test.startTest();
    	    
        boolean sawException = false;
        string exMsg = null;
        try{
        	delete td.receiptinvoicelineList;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to delete finalized doc lines ' + exMsg );
    }
 	
 	public static testMethod void testFinalizeLineAddValidation(){
    	
    	TestReceiptData td = new TestReceiptData();
		
		for(Receiving_Document__c rd : td.receivingDocList){
			rd.finalized__c = true;
		}
		
		update td.receivingDocList;
		
    	test.startTest();
 	
        boolean sawException = false;
        string exMsg = null;
        try{
        	List<Receipt_Line__c> newRLs = new List<Receipt_Line__c>();
        	for(Receipt_Line__c rl : td.receiptinvoicelineList){
			    newRLs.add(rl.clone(false, true));
			}
        	insert newRLs;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
     	
     	test.stopTest();
        system.assert(sawException, 'We are expecting to see an exception for attempting to add lines to a finalized doc ' + exMsg );
 	}
 	
 	public static testMethod void testFinalizeLineUndeleteValidation(){
    	
    	TestReceiptData td = new TestReceiptData();
		
		
    	test.startTest();
        
    	List<Receipt_Line__c> newRLs = new List<Receipt_Line__c>();
    	for(Receipt_Line__c rl : td.receiptinvoicelineList){
		    newRLs.add(rl.clone(false, true));
		}
    	insert newRLs;
    	
    	delete newRLs;
       
       	for(Receiving_Document__c rd : td.receivingDocList){
			rd.finalized__c = true;
		}
		
		update td.receivingDocList;
		
		boolean sawException = false;
        string exMsg = null;
		
		try{
			undelete newRLs;
     	}catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
     	test.stopTest();
        system.assert(sawException, 'We are expecting to see an exception for attempting to undelete lines on a finalized doc ' + exMsg );
 	}
 	
 	public static testMethod void testPPV(){
 		TestReceiptData td = new TestReceiptData();
		
		for(Receiving_Document__c rd : td.receivingDocList){
			rd.finalized__c = true;
		}
		
		update td.receivingDocList;
		
        Test.startTest();
        
        Receiving_Document__c rd1 = [Select id, Name, Finalized__c, Finalized_hidden__c, 
        								(SELECT Id, name, subtransaction_type__c, line_type__c FROM Receipt_Lines__r)
                                from Receiving_Document__c 
                                where id = :td.receivingdocument1.id];
            
        system.assertEquals(true, rd1.Finalized__c);
        system.assertEquals(true, rd1.Finalized_hidden__c);
            
        List<Receipt_Line__c> rdLines = [Select id, Name, Item__c, Supplier__c, Status__c, Receiving_Document__c, Purchase_Order__c from Receipt_Line__c where Receiving_Document__c = :rd1.id]; 
             
	    ReceivingDocumentAccounting rda = new ReceivingDocumentAccounting();
	    rda.execute(rdLines);		
            
	    Set<Id> RcptIds = new Set<Id>();
	    for(Receiving_Document__c rcpt: td.receivingDocList){
	        RcptIds.add(rcpt.id);
	    }

              
        List<Accounting_Entry__c> accountingEntryListPOReceipt = [Select id, Name, Receiving_Document__c, transaction_type__c,
        															(SELECT Id, GL_Account__c, GL_Account__r.Name, 
        															subtransaction_type__c, line_type__c, description__c, accounting_rule__c
        															FROM Accounting_Entry_Lines__r)
                                                                    from Accounting_Entry__c
                                                                    where Receiving_Document__c in :RcptIds];
                                                                    
        Test.stopTest();                                                        
      	system.debug('accountingEntryListPOReceipt: '+ accountingEntryListPOReceipt);     
        system.assertNotEquals(null, accountingEntryListPOReceipt);
        system.assertEquals(1, accountingEntryListPOReceipt.size());
        
        for(Accounting_Entry__c ae : accountingEntryListPOReceipt){
        	boolean hasPPV = false;
        	system.assertNotEquals(0, ae.Accounting_Entry_Lines__r.size(), 'We should see lines for this Accounting Entry');
        	for(Accounting_Entry_Line__c ael : ae.Accounting_Entry_Lines__r){
        		if(ael.gl_account__c == td.data.acctData.PPVGL.Id){
        			hasPPV = true;
        		}
        	}
        	system.assert(hasPPV, 'We are expecting to see PPV booked to this receiving document ' + ae + ' - ' + ae.Accounting_Entry_Lines__r);
        }
 	}
 	
 	//Test missing item cost missing on receiving document accounting
/* 	public static testmethod void testItemCostMissing(){
		
		TestReceiptData td = new TestReceiptData();
		
        Test.startTest();
        
        //loop throught the receiptlines and null out the line types so it matches with the accounting rules in the test data
        //it was defaulted to the PO line's line type
        
        Receiving_Document__c rd1 = [Select id, Name, Finalized__c, Finalized_hidden__c
                                from Receiving_Document__c 
                                where id = :td.receivingdocument1.id];
            
            
        List<Receipt_Line__c> rdLines = [Select id, Name, Company__c, Item__c, Supplier__c, Status__c, Receiving_Document__c, Purchase_Order__c from Receipt_Line__c where Receiving_Document__c in :td.receivingDocList]; 
        
        Item__c NocostItem=new Item__c();
        NocostItem.name='HP Printer - No Cost';
        NocostItem.Description__c='It is a Test item with no cost';
        NocostItem.Source__c=Label.Source_field_of_ItemP;
        NocostItem.Company__c =rdLines[0].company__c;
        //NocostItem.Class__c = itemClass1.id;
        insert NocostItem;
        
        for(Receipt_Line__c rdl:rdLines){
        	rdl.Item__c = NocostItem.id;  
        }
        
        update rdLines;
        
        for(Receiving_Document__c rd : td.receivingDocList){
			rd.finalized__c = true;
        }
            
		update td.receivingDocList;
		
	    ReceivingDocumentAccounting rda = new ReceivingDocumentAccounting();
	    //rda.execute(td.receivingDocList);	
	    rda.execute(rdLines);	
            
	    Set<Id> RcptIds = new Set<Id>();
	    for(Receiving_Document__c rcpt: td.receivingDocList){
	        RcptIds.add(rcpt.id);
	    }

              
        List<Accounting_Entry__c> accountingEntryListPOReceipt = [Select id, Name, Receiving_Document__c,
        															(Select id, Name, item_cost_missing__c from Accounting_entry_lines__r)
                                                                    from Accounting_Entry__c
                                                                    where Receiving_Document__c in :RcptIds];
                                                                    
        Test.stopTest();                                                        
      	system.debug('accountingEntryListPOReceipt: '+ accountingEntryListPOReceipt);     
        system.assertNotEquals(null, accountingEntryListPOReceipt);
        system.assertEquals(3, accountingEntryListPOReceipt.size());
        for(Accounting_Entry__c ae : accountingEntryListPOReceipt){
        	for(Accounting_entry_line__c ael: ae.Accounting_entry_lines__r){
//        		system.assert(ael.item_cost_missing__c == true);
        	}
        }
		
	}
*/}