@isTest
public with sharing class SourceDocumentUnfinalizeTest {
	
	static testMethod void cannotUnfinalizeNonManaulCI()
	{
		TestData data = new TestData();
		List<Customer_Invoice__c> custInvoiceListForAE = new List<Customer_Invoice__c>();
		List<Customer_Invoice__c> custInvoiceList = new List<Customer_Invoice__c>();
		List<Customer_Invoice_Line__c> custInvoiceLineList = new List<Customer_Invoice_Line__c>();
		
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
        custInvoice1.Bill_To_Customer__c = data.customerBillTo.id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Subtotal__c = 0;
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Overpayment';
        
        custInvoiceList.add(custInvoice1);
        
        insert custInvoice1;
        
        Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
        custInvLine1.Quantity_Shipped__c = 5;
        custInvLine1.Unit_Price__c = 10;
        custInvLine1.Extended_Price__c = 50;
        custInvLine1.Product__c = data.product.id ; 
        custInvLine1.Discount_Percent__c = 0;
        custInvLine1.Customer_Invoice__c = custInvoice1.Id; 
        custInvoiceLineList.add(custInvLine1);
        
        insert custInvLine1;
        
        custInvoice1.finalized__c = true;
        update custInvoice1;
        
        String tmpId = custInvoice1.id;
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', tmpId );
		SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
		ExceptionService.messages.clear();
		try
		{
			srcDocUnfinalizeExt1.unfinalizeSourceDoc();
		}catch(Exception ex)
		{
			system.assert(ex.getMessage().contains(Label.Can_only_unfinalize_Manual_Customer_Invoices)); //AR-87
		}
		custInvoice1 = [select id, Finalized__c from Customer_Invoice__c where id = :custInvoice1.id limit 1];
		system.assertEquals(true, custInvoice1.Finalized__c);
		//srcDocUnfinalizeExt1.unfinalize();
       
        
	}
	static testMethod void canUnfinalizeManaulCI()
	{
		TestData data = new TestData();
		List<Customer_Invoice__c> custInvoiceListForAE = new List<Customer_Invoice__c>();
		List<Customer_Invoice__c> custInvoiceList = new List<Customer_Invoice__c>();
		List<Customer_Invoice_Line__c> custInvoiceLineList = new List<Customer_Invoice_Line__c>();
		
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
        custInvoice1.Bill_To_Customer__c = data.customerBillTo.id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Subtotal__c = 0;
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Manual';
        
        custInvoiceList.add(custInvoice1);
        
        insert custInvoice1;
        
        Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
        custInvLine1.Quantity_Shipped__c = 5;
        custInvLine1.Unit_Price__c = 10;
        custInvLine1.Extended_Price__c = 50;
        custInvLine1.Product__c = data.product.id ; 
        custInvLine1.Discount_Percent__c = 0;
        custInvLine1.Customer_Invoice__c = custInvoice1.Id; 
        custInvoiceLineList.add(custInvLine1);
        
        insert custInvLine1;
        
        custInvoice1.finalized__c = true;
        update custInvoice1;
        
        String tmpId = custInvoice1.id;
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', tmpId );
		SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
		ExceptionService.messages.clear();
		
		srcDocUnfinalizeExt1.unfinalizeSourceDoc();
		srcDocUnfinalizeExt1.unfinalize();
		system.assertEquals(srcDocUnfinalizeExt1.unfinalize, true,'the boolean should be true => can unfunalize'); //AR-127
		custInvoice1 = [select id, Finalized__c from Customer_Invoice__c where id = :custInvoice1.id limit 1];
		system.assertEquals(false, custInvoice1.Finalized__c);
		//srcDocUnfinalizeExt1.unfinalize();
       
        
	}
	
	
	static testmethod void testController1() {
		TestData data = new TestData();
		
		string custInvName = SchemaUtil.getInstance().getLocalNameFromObject(new Customer_Invoice__c());
		Map<String, String> mRecTypes = KSE.RecordTypeDevNameMap(custInvName);
		Id invRecTypeId = mRecTypes.get('Invoice');
		Id cmRecTypeId = mRecTypes.get('Credit_Memo'); 		
		
		Test.startTest();
		//GenerateAccountingService GAS = new GenerateAccountingService();
		CustomerReceiptAccounting cra = new CustomerReceiptAccounting();
		
		List<Customer_Invoice__c> custInvoiceListForAE = new List<Customer_Invoice__c>();
		List<Customer_Invoice__c> custInvoiceList = new List<Customer_Invoice__c>();{
			
			List<Customer_Invoice_Line__c> custInvoiceLineList = new List<Customer_Invoice_Line__c>();
			
			Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
            custInvoice1.Company__c = data.company.id;
            custInvoice1.Bill_To_Customer__c = data.customerBillTo.id;
            custInvoice1.Date_Invoiced__c = System.now();
            custInvoice1.transaction_date__c = system.now();
            custInvoice1.status__c = 'Open';
            custInvoice1.Subtotal__c = 0;
            custInvoice1.Currency__c = TestFuel.currencyUSD.id;
            custInvoice1.Invoice_Type__c = 'Manual';
            
            custInvoiceList.add(custInvoice1);
            
            Customer_Invoice__c custInvoice2 = new Customer_Invoice__c();
            custInvoice2.Company__c = data.company.id;
            custInvoice2.Bill_To_Customer__c = data.customerBillTo.id;
            custInvoice2.Date_Invoiced__c = System.now();
            custInvoice2.transaction_date__c = system.now();
            custInvoice2.status__c = 'Open';
            custInvoice2.Subtotal__c = 0;
            custInvoice2.Currency__c = TestFuel.currencyUSD.id;
            custInvoice2.Invoice_Type__c = 'Manual';
            
            custInvoiceList.add(custInvoice2);
            custInvoiceListForAE.add(custInvoice2);
            
            Customer_Invoice__c custInvoice3 = new Customer_Invoice__c();
            custInvoice3.Company__c = data.company.id;
            custInvoice3.Bill_To_Customer__c = data.customerBillTo.id;
            custInvoice3.Date_Invoiced__c = System.now();
            custInvoice3.transaction_date__c = system.now();
            custInvoice3.status__c = 'Open';
            custInvoice3.Subtotal__c = 0;
            custInvoice3.Currency__c = TestFuel.currencyUSD.id;
            custInvoice3.Invoice_Type__c = 'Manual';
            
            custInvoiceList.add(custInvoice3);
            custInvoiceListForAE.add(custInvoice3);
            
            Customer_Invoice__c custInvoice4 = new Customer_Invoice__c();
            custInvoice4.Company__c = data.company.id;
            custInvoice4.Date_Invoiced__c = System.now();
            custInvoice4.transaction_date__c = system.now();
            custInvoice4.status__c = 'Open';
            custInvoice4.Subtotal__c = 0;
            custInvoice4.Currency__c = TestFuel.currencyUSD.id;
            custInvoice4.Invoice_Type__c = 'Settlement'; //OTC-656 CI of Settlement without Bill To Customer
            
            custInvoiceList.add(custInvoice4);
            custInvoiceListForAE.add(custInvoice4);
            
            insert custInvoiceList;
            
            Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
            custInvLine1.Quantity_Shipped__c = 5;
            custInvLine1.Unit_Price__c = 10;
            custInvLine1.Extended_Price__c = 50;
            custInvLine1.Product__c = data.product.id ; 
            custInvLine1.Discount_Percent__c = 0;
            custInvLine1.Customer_Invoice__c = custInvoice1.Id; 
            custInvoiceLineList.add(custInvLine1);
            
            Customer_Invoice_Line__c custInvLine2 = new Customer_Invoice_Line__c();
            custInvLine2.Quantity_Shipped__c = 5;
            custInvLine2.Unit_Price__c = 10;
            custInvLine2.Extended_Price__c = 50;
            custInvLine2.Product__c = data.product.id ; 
            custInvLine2.Discount_Percent__c = 0;
            custInvLine2.Customer_Invoice__c = custInvoice2.Id; 
            custInvoiceLineList.add(custInvLine2);
            
            Customer_Invoice_Line__c custInvLine3 = new Customer_Invoice_Line__c();
            custInvLine3.Quantity_Shipped__c = 5;
            custInvLine3.Unit_Price__c = 10;
            custInvLine3.Extended_Price__c = 50;
            custInvLine3.Product__c = data.product.id ; 
            custInvLine3.Discount_Percent__c = 0;
            custInvLine3.Customer_Invoice__c = custInvoice3.Id; 
            custInvoiceLineList.add(custInvLine3);
            
            Customer_Invoice_Line__c custInvLine4 = new Customer_Invoice_Line__c();
            custInvLine4.Quantity_Shipped__c = 5;
            custInvLine4.Unit_Price__c = 10;
            custInvLine4.Extended_Price__c = 50;
            custInvLine4.Product__c = data.product.id ; 
            custInvLine4.Discount_Percent__c = 0;
            custInvLine4.Customer_Invoice__c = custInvoice4.Id; 
            custInvoiceLineList.add(custInvLine4);
            
            insert custInvoiceLineList;
            
            for(Customer_Invoice__c custInv: custInvoiceList){
            	custInv.Finalized__c = true;
            	custInv.finalized_date__c = system.now();
            }
            update custInvoiceList;
            
            system.assertEquals(4,custInvoiceList.size());
            	
            try{
	            //GAS.createCustInvoiceAccounting(custInvoiceListForAE);
	            CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
	            cia.execute(custInvoiceLineList);
	            
	            
	            //update custInvoiceListForAE;
            }catch(Exception e){
            	throw e;
            }
            
		}    
        system.assertEquals(4,custInvoiceList.size());
        system.debug('custInvoiceList size:'+custInvoiceList.size());
        String tmpId = custInvoiceList[0].id +'-'+ custInvoiceList[1].id + '-' + custInvoiceList[2].id+ '-' + custInvoiceList[3].id;
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', tmpId );
		SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
		ExceptionService.messages.clear();
		srcDocUnfinalizeExt1.unfinalizeSourceDoc();
		srcDocUnfinalizeExt1.unfinalize();
		
		List<Customer_Invoice__c> custInvList = [Select id, Name, Finalized__c , Invoice_Type__c
												from Customer_Invoice__c
												where id in :custInvoiceList ];
			
		// TODO: SK: works totally fine and as expected in the application and UI. Need to revisit during the redesign of unfinalize feature.											
		for(Integer i= 0; i < custInvList.size(); i++){
			system.assertEquals( false, custInvList[i].Finalized__c, 'the one that did not finalize: '+custInvList[i]);
		}
		Test.stopTest();	
	} 
	
	

	static testmethod void testController2() {
		//TestData data = new TestData();
		Testfuel data = new Testfuel();
		List<Accounting_Rule__c> crAccountingRuleList = data.crAccountingRuleList;
		//testdata.accounting testAccounting = new testdata.accounting(data.company.Id);
		List<Period__c> periodList = data.periodList;
		
		string custInvName = SchemaUtil.getInstance().getLocalNameFromObject(new Customer_Invoice__c());
		Map<String, String> mRecTypes = KSE.RecordTypeDevNameMap(custInvName);
		
		Bank_Account__c bankAccount = new Bank_Account__c();{
	        bankAccount.Name = 'Test BOFA';
	        bankAccount.account_type__c = 'Checking';
	        bankAccount.GL_Account__c = data.cashGL.id;
	        bankAccount.active__c = true;
            bankAccount.Currency__c = TestFuel.currencyUSD.id;
	        insert bankAccount;
    	}
 
		// Create a customer Receipt and call standard controller to unfinalize
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();{
            custInvoice1.Company__c = data.company.id;
            custInvoice1.Bill_To_Customer__c = data.customerBillTo.id;
            custInvoice1.Date_Invoiced__c = System.now();
            custInvoice1.transaction_date__c = system.now();
            custInvoice1.status__c = 'Open';
            custInvoice1.Subtotal__c = 0;
            custInvoice1.Currency__c = TestFuel.currencyUSD.id;
            custInvoice1.Invoice_Type__c = 'Manual';
            
            insert custInvoice1;
            
            Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
            custInvLine1.Quantity_Shipped__c = 5;
            custInvLine1.Unit_Price__c = 10;
            custInvLine1.Product__c = data.product.id ; 
            custInvLine1.Discount_Percent__c = 0;
            custInvLine1.Customer_Invoice__c = custInvoice1.Id; 
            insert custInvLine1;
            
            custInvoice1.Finalized__c = true;
            update custInvoice1;
		}
            
    	Customer_Receipt__c custReceipt1 = new Customer_Receipt__c();
		List <Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();{
            //custReceipt1.Amount_Received__c = 50;
            custReceipt1.Company__c = data.company.Id;
            //custReceipt1.Bank_Account__c = bankAccount.id;
            custReceipt1.Customer__c = data.customerBillTo.Id;
            custReceipt1.Date_Received__c = system.now();
            custReceipt1.Transaction_Date__c = system.now();
            custReceipt1.Currency__c = TestFuel.currencyUSD.id;
            custReceipt1.exception__c = false;
            insert custReceipt1;
         	custReceiptList.add(custReceipt1);
         	
         Customer_Receipt_Line__c payment1 = new Customer_Receipt_Line__c();
            payment1.Amount__c = 50;
            payment1.Type__c = 'Payment';
            payment1.Customer_Receipt__c = custReceipt1.id;
            payment1.Customer_Invoice__c = custInvoice1.id;
            payment1.Currency__c = TestFuel.currencyUSD.id;
            payment1.line_Number__c ='1';   
            
            insert payment1;
            
 			
 			custReceipt1.Amount_unapplied__c = 0;
            custReceipt1.Finalized__c = true;
            //custReceipt1.Finalized_Date__c = system.now();
            update custReceipt1;
            
			Test.startTest();
			CustomerReceiptAccounting cra = new CustomerReceiptAccounting();
            try{
            	cra.execute(custReceiptList);
            	
            	update custReceipt1;
            }catch(Exception e){
            	system.debug('Exception:'+e.getMessage());
            }
   			List<Accounting_Entry__c> custRcptAEList = [Select id, Name, Period__c, GL_Date_Time__c, Transaction_Date__c, Finalized_Date__c, Has_Exceptions__c,
   															(SELECT Id, amount_dr__c, amount_cr__c FROM Accounting_Entry_Lines__r)
   														from Accounting_Entry__c where Customer_Receipt__c = :custReceipt1.id];
   			
   			
		}  
		
		
		Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', custReceiptList[0].id );
		SourceDocumentUnfinalize srcDocUnfinalizeExt = new SourceDocumentUnfinalize();
		ExceptionService.messages.clear();
		srcDocUnfinalizeExt.unfinalizeSourceDoc();
		srcDocUnfinalizeExt.unfinalize();
		
 		system.debug(logginglevel.info,'testData.custReceiptList[0].id :'+custReceiptList[0].id);
 		List<Customer_Receipt__c> custReceiptList2 = [Select id, Name, Finalized__c ,
 						(Select id, Name, Transaction_Date__c, Finalized_Date__c, GL_Date_Time__c, Period__c
 						from Accounting_Entries__r where Customer_Receipt__c = :custReceiptList[0].id)
 						from Customer_Receipt__c 
 						where id = :custReceiptList[0].id ];
 		system.debug(logginglevel.info,'after query - custReceiptList :'+custReceiptList2);
 		system.debug(logginglevel.info,'after query - Accounting_Entries__r :'+custReceiptList2[0].Accounting_Entries__r);
        // TODO: SK: works totally fine and as expected in the application and UI. Need to revisit during the redesign of unfinalize feature.
        system.assertEquals(false,custReceiptList2[0].Finalized__c);
		system.assert(custReceiptList2[0].Finalized__c == false, custReceiptList2[0].Accounting_Entries__r);
        
        
		Test.stopTest();
		
 
		
		
		//Removed from here -1
		
		
		
		
		
		
            // SK : below logic is no longer valid as there is no posting process in the system now.
            /*
            List<Accounting_Entry__c> AEtoPostList = [Select id, Name, Exception__c, Total_Lines__c,
            											( Select id, Name, GL_Account__c from Accounting_Entry_Lines__r)
            											from Accounting_Entry__c
            											where Customer_Invoice__c = :custInvoice3.id];
            											
        	List<Accounting_Entry_Line__c> AElines = new List<Accounting_Entry_Line__c>();
		
			Accounting_Entry_Line__c AELineCR = new Accounting_Entry_Line__c();
			AELineCR.Accounting_Entry__c = AEtoPostList[0].Id;
			AELineCR.Amount_CR__c = 50;
			AELineCR.Exception__c = false;
			AELineCR.Company__c = data.company.Id;
		    AELineCR.GL_Account__c = data.acctData.cashGL.id;
		    AELineCR.Transaction_Date__c = system.today();
		    
		    AElines.add(AELineCR);
		    
		    Accounting_Entry_Line__c AELineDR = new Accounting_Entry_Line__c();
		    AELineDR.Accounting_Entry__c = AEtoPostList[0].Id;
		    AELineDR.Amount_DR__c = 50;
			AELineDR.Exception__c = false;
			AELineDR.Company__c = data.company.Id;
		    AELineDR.GL_Account__c = data.acctData.cashGL.id;
		    AELineDR.Transaction_Date__c = system.today();
			
			AElines.add(AELineDR);
			insert AElines;
		
        	update AEtoPostList;
        	
        	AEtoPostList = [Select id, Name, Exception__c, Line_Exceptions__c, Total_Lines__c,
            											( Select id, Name, GL_Account__c, Exception__c, Error_Message__c, Mandatory_Segment_Exception__c from Accounting_Entry_Lines__r)
            											from Accounting_Entry__c
            											where Customer_Invoice__c = :custInvoice3.id];
            											
            system.debug(logginglevel.info, 'AEtoPostList: '+ AEtoPostList);
            system.debug(logginglevel.info, 'AELines: ' + AEtoPostList[0].Accounting_Entry_Lines__r);
            //for(Accounting_Entry_Line__c ael : AEtoPostList[0].Accounting_Entry_Lines__r){
            //	system.debug(logginglevel.info, ael.error_message__c);
            //}
            
            
            TODO: RS 2-10-2014 Fix or modify this assertion
            system.assertEquals(false, AEtoPostList[0].Exception__c);											
            system.assertEquals(2 ,AEtoPostList[0].Total_Lines__c );
			
            ApexPages.StandardController AEcon;
        	
        	AEcon = new ApexPages.StandardController(AEtoPostList[0]);
        	
        	AEtoPostList = [Select id, Name, Exception__c, Total_Lines__c,
            											( Select id, Name, GL_Account__c, Exception__c, Error_Message__c, Mandatory_Segment_Exception__c from Accounting_Entry_Lines__r)
            											from Accounting_Entry__c
            											where Customer_Invoice__c = :custInvoice3.id];			
			*/
		

	
	}	
	
	
	
	
	
	
	
	
	static testmethod void testTriggers() {
		// Insert Customer Invoice and set Finalized flag and check if the finalized_hidden flag is also set.
		TestData data = new TestData();

		string custInvName = SchemaUtil.getInstance().getLocalNameFromObject(new Customer_Invoice__c());
		Map<String, String> mRecTypes = KSE.RecordTypeDevNameMap(custInvName);
		Id invRecTypeId = mRecTypes.get('Invoice');
		Id cmRecTypeId = mRecTypes.get('Credit_Memo'); 		
		
		Test.startTest();
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
		custInvoice1.Company__c = data.company.id;
        custInvoice1.Bill_To_Customer__c = data.customerBillTo.id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.Transaction_Date__c = System.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Subtotal__c = 0;
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Manual';
        insert custInvoice1;
        
        Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
        custInvLine1.Quantity_Shipped__c = 5;
        custInvLine1.Unit_Price__c = 10;
        custInvLine1.Product__c = data.product.id ; 
        custInvLine1.Discount_Percent__c = 0;
        custInvLine1.Customer_Invoice__c = custInvoice1.Id; 
        insert custInvLine1;
        
        custInvoice1.Finalized__c = true;
        update custInvoice1;
        
        custInvoice1 = [Select id, Name, Finalized__c, Finalized_hidden__c 
        				from Customer_Invoice__c
        				where id = :custInvoice1.id];
        system.assertEquals( true , custInvoice1.Finalized__c);
        system.assertEquals( true , custInvoice1.Finalized_hidden__c);
		// remove the finalized flag and try to save you should get exception
		custInvoice1.Finalized__c = false;
		
		Boolean sawException = false;
		try{
        	update custInvoice1;
		}catch(Exception e){
			sawException = true;
		}
		system.assertEquals(true, sawException);
		Test.stopTest();
	}
	
	//PTP-402 Unfinalize an SI matched by Two Way Matching Algo
	static testMethod void test2WayMutipleSILsUnfinalize(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            //POLine1.Quantity_Uninvoiced__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 6;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
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
            sil_mrl.Invoice_Quantity__c = 1; 
            sil_mrl.Unit_Price__c = 1; //KNDY-14371
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
            sil_mrl2.Invoice_Quantity__c = 2; 
            sil_mrl2.Unit_Price__c = 1;//KNDY-14371
            sil_mrl2.Supplier_Invoice__c = si_mrl.id;
            sil_mrl2.segment_exception__c = false;
            sil_mrl2.price_exception__c = false;
            sil_mrl2.quantity_exception__c = false;
            sil_mrl2.exception_details__c = null;
            sil_mrl2.matched__c = false;
        }
        Supplier_Invoice_Line__c sil_mrl3 = new Supplier_Invoice_Line__c();{
            sil_mrl3.Purchase_Order_Line__c = POLine1.id;
            sil_mrl3.Item__c = globalTestData.itemList[1].id;
            sil_mrl3.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl3.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl3.Description__c = 'test';
            sil_mrl3.Invoice_Quantity__c = 3; 
            sil_mrl3.Unit_Price__c = 1;//KNDY-14371
            sil_mrl3.Supplier_Invoice__c = si_mrl.id;
            sil_mrl3.segment_exception__c = false;
            sil_mrl3.price_exception__c = false;
            sil_mrl3.quantity_exception__c = false;
            sil_mrl3.exception_details__c = null;
            sil_mrl3.matched__c = false;
        } 
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl2,sil_mrl3};
        insert supILs;
        
        //POLine1.Quantity_Uninvoiced__c = 14;
        //update POLine1;
        
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);

        Supplier_Invoice__c si = [select id, name, status__c, Finalized__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, 
              Invoice_Quantity__c from Supplier_Invoice_lines__r) 
             from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Approved',si.status__c);
        system.assert(si.Finalized__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, true);
        }

        // Unfinalizing the SI should not change POL`s Quanity Uninvoiced
        Test.startTest();
        String tmpId = si_mrl.id;
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
        Apexpages.currentPage().getParameters().put('id', tmpId );
        SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
        ExceptionService.messages.clear();
        try
        {
            srcDocUnfinalizeExt1.unfinalizeSourceDoc();
            srcDocUnfinalizeExt1.unfinalize();
        }catch(Exception ex)
        {
            system.assertNotEquals(1,1,'Unexpected Exception: ' + ex.getMessage());
        }
        si = [select id, name, status__c, Finalized__c, 
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c from Supplier_Invoice_lines__r) 
             from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertNotEquals('Approved',si.status__c);
        system.assert(!si.Finalized__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assert(!sil.matched__c);
            system.assertEquals(sil.Exceptions_Count__c, null);
            // all sils are for same POL
            //system.assertEquals(sil.Purchase_Order_Line__r.Quantity_Uninvoiced__c, 14);
        }
        Test.stopTest();
    } 
   
    // KNDY-8139 - Unfinalize an SI matched by Three Way Matching Algo with ASN Receipts
    static testMethod void test3Way_ASNReceipts_Unfinalize(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 0; 
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
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
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
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
        // Receive POL order quantity in full
        POLine1.Quantity_Received__c = 100; 
        update POLine1; 
        
        // Insert SI and SILs
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Supplier_Invoice__c = '987612ASN';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 100;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
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
            sil_mrl.Invoice_Quantity__c = 100;
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

        Test.startTest();
        // Inspect SI, Run Matching Algorithm       
        supplierInvoiceService.inspectDraftInvoices(sup);
        Supplier_Invoice__c si = [select id, name, exception__c, status__c,
                                    (select id, Exceptions_Count__c, matched__c,  
                                     Quantity_Received__c,Purchase_Order_Line__c 
                                     from Supplier_Invoice_lines__r) 
                                  from Supplier_Invoice__c where id =: si_mrl.id];    
        system.assertEquals('Approved',si.status__c);
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, true);
            system.assertEquals(sil.Exceptions_Count__c, null);
            system.assertEquals(sil.Quantity_Received__c,100, '3 Way Matching - expected 100 Qty Received on SIL');
        
        }
        
        List<Receipt_Line__c> rls = [Select id, Name, Matched__c, Purchase_Order_Line__c, Quantity_Received__c,
                                     Uninvoiced_Quantity__c, Receiving_Document__r.Type__c  
                                     From Receipt_Line__c where Id in :receiptLines];
        for (Receipt_Line__c rl: rls){                                    
            if (rl.Receiving_Document__r.Type__c == 'Purchase Order Receipt'){
                   system.assert(rl.Uninvoiced_Quantity__c == 0);
                   system.assert(rl.Matched__c);
            }
            else if (rl.Receiving_Document__r.Type__c == 'In Transit'){
               system.assert(!rl.Matched__c);
               system.assert(rl.Uninvoiced_Quantity__c == null);
            }
        }
        
        // Unfinalize the SI
        String tmpId = si_mrl.id;
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
        Apexpages.currentPage().getParameters().put('id', tmpId );
        SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
        ExceptionService.messages.clear();
        try
        {
            srcDocUnfinalizeExt1.unfinalizeSourceDoc();
            srcDocUnfinalizeExt1.unfinalize();
        }catch(Exception ex)
        {
            system.assertNotEquals(1,1,'Unexpected Exception: ' + ex.getMessage());
        }
        si = [select id, name, status__c, Finalized__c, 
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c from Supplier_Invoice_lines__r) 
             from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertNotEquals('Approved',si.status__c);
        system.assert(!si.Finalized__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assert(!sil.matched__c);
            system.assertEquals(sil.Exceptions_Count__c, null);
            //system.assertEquals(sil.Purchase_Order_Line__r.Quantity_Uninvoiced__c, 100);
        }
       
        rls = [Select id, Name, Matched__c, Purchase_Order_Line__c, Quantity_Received__c,
                                     Uninvoiced_Quantity__c, Receiving_Document__r.Type__c  
                                     From Receipt_Line__c where Id in :receiptLines];
        for (Receipt_Line__c rl: rls){                                    
            if (rl.Receiving_Document__r.Type__c == 'Purchase Order Receipt'){
                   system.assert(rl.Uninvoiced_Quantity__c == 100);
                   system.assert(!rl.Matched__c);
            }
            else if (rl.Receiving_Document__r.Type__c == 'In Transit'){
               system.assert(!rl.Matched__c);
               system.assert(rl.Uninvoiced_Quantity__c == null);
            }
        }
        Test.stopTest();
    } 
    //KNDY-11086
    static testMethod void testValidateAndnavigateToUnfinalize()
    {
    	Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        List<Period__c> periodaltList = globaltestdata.altCompanyPeriodList;
        Company__c company = globaltestdata.company;
        Company__c altCompany = globaltestdata.altCompany;
        Invoice__c inv = globaltestdata.intercompanyInvestmentInvoice;
        
		Payment__c intercompanyPayment = globaltestdata.intercompanyPayment;
		Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', inv.Id );
		SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
		PageReference p = srcDocUnfinalizeExt1.validateAndnavigateToUnfinalize();
		system.assertEquals(p, null);
		List<Apexpages.Message> msgs = ApexPages.getMessages();
		string msg = msgs[0].getDetail();
		
		system.assertEquals(msg,Label.Cannot_unfinalize_IntercoInvoice_included_Payment);
		srcDocUnfinalizeExt1.close();
		
		Invoice__c intercompanyInvestmentInv = new Invoice__c();
        intercompanyInvestmentInv.From_Company__c = altCompany.Id;
        intercompanyInvestmentInv.To_Company__c = company.Id;
        intercompanyInvestmentInv.Currency__c = TestFuel.currencyUSD.id;
        intercompanyInvestmentInv.Transaction_Date__c = system.now();
        intercompanyInvestmentInv.Type__c = 'Intercompany Investment';
        intercompanyInvestmentInv.Transaction_Type__c = 'Intercompany Investment';
        
        insert intercompanyInvestmentInv;
        
        Invoice_Line__c invLine = new Invoice_Line__c();
        invLine.Invoice__c = intercompanyInvestmentInv.Id;
        invLine.Extended_Amount__c = 10000;
        
        insert invLine;
        intercompanyInvestmentInv.Finalized__C = true;
        update intercompanyInvestmentInv;
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
        Apexpages.currentPage().getParameters().put('id', intercompanyInvestmentInv.Id );
        SourceDocumentUnfinalize srcDocUnfinalizeExt2 = new SourceDocumentUnfinalize();
        PageReference p1 = srcDocUnfinalizeExt2.validateAndnavigateToUnfinalize();
		system.assertEquals(p1 != null, true);
		srcDocUnfinalizeExt2.close();
    }
}