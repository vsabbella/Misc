@isTest
private class SupplierInvoiceTest {
	static TestDataForFinance data = new TestDataForFinance();
        
    public class SupplierInvoiceData{
        Accounting_Default__c testDefault = new Accounting_Default__c();{
        	testDefault.Company__c = data.company.id;
        	testDefault.GL_Account__c = data.Acctdata.CashGl.id;
            DML.insertAsUser( new list<sobject>{testDefault} );//KNDY-1751
            //insert testDefault;
        }
        
        
        List<Purchase_Order__c> poList = [Select   p.Supplier__c,         p.Status__c, 
                                p.Payment_Term__c, p.Order_Date__c, 
                                p.Name, p.Id, p.Deliver_to__c, p.Date_Closed__c, 
                                p.Company__c, p.Buyer__c, p.Approval_Status__c, p.Acknowledge_Via__c, 
                                (Select Id, IsDeleted, Name, Purchase_Order__c, Company__c, 
                                    Date_Added__c, Date_Closed__c, Date_Last_Changed__c, Description__c,  
                                    Item__c, Latest_Promise_Date__c, Line_Value__c, Line__c,  Manufacturers_Part__c, 
                                    Need_Date__c, Order_Quantity__c, Overage_Percentage__c, 
                                    Promise_Date__c, Purchase_UOM__c, Quantity_Returned_to_Supplier__c, 
                                    Quantity_Still_Due__c, Requisition_Number__c, Rush_Line__c, Special_Notes__c, Status__c, 
                                    Supplier_Part__c, Suppliers_Part_Description__c, Unit_Price__c 
                                    From Purchase_Order_Lines__r order by Line__c ASC) 
                                From Purchase_Order__c p
                                where p.id in (:data.purchaseOrder1.id, :data.purchaseOrder2.id, :data.purchaseOrder3.id, :data.purchaseOrder4.id)];
                                
        List<Supplier_Invoice_Line__c> suppInvLineList = new List<Supplier_Invoice_Line__c>();
        
        Supplier_Invoice__c suppInv1, suppInv2,suppInv3,suppInv4;
        
        List<Supplier_Invoice__c> suppInvAEList = new List<Supplier_Invoice__c>();{
            suppInv1 = new Supplier_Invoice__c();
            suppInv1.Company__c = data.company.id;
            suppInv1.Invoice_Type__c = 'Invoice';
            suppInv1.Date_Invoiced__c = System.now();
            suppInv1.transaction_date__c = system.now();
            suppInv1.Currency__c = TestFuel.currencyUSD.id;
            suppInv1.Supplier__c = data.remittosupplier.id;
            //suppInv1.Amount_Due__c = data.purchaseOrder2.Purchase_Order_Value__c;
            suppInv1.Invoice_Amount__c = 160;
            suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
            suppInv1.Finalized__c = false;
            suppInvAEList.add(suppInv1);
            
            suppInv2 = new Supplier_Invoice__c();
            suppInv2.Company__c = data.company.id;
            suppInv2.Invoice_Type__c = 'Invoice';
            suppInv2.Date_Invoiced__c = System.now();
            suppInv2.transaction_date__c = system.now();
            suppInv2.Currency__c = TestFuel.currencyUSD.id;
            suppInv2.Supplier__c = data.remittosupplier.id;
            //suppInv2.Amount_Due__c = data.purchaseOrder3.Purchase_Order_Value__c;
            suppInv2.Invoice_Amount__c = 160;
            suppInv2.Supplier_Invoice__c = String.valueOfGmt(system.today()+1);
            suppInv2.Finalized__c = false;
            suppInvAEList.add(suppInv2);
            
            suppInv3 = new Supplier_Invoice__c();
            suppInv3.Company__c = data.company.id;
            suppInv3.Invoice_Type__c = 'Credit Memo';
            suppInv3.Date_Invoiced__c = System.now();
            suppInv3.transaction_date__c = system.now();
            suppInv3.Currency__c = TestFuel.currencyUSD.id;
            suppInv3.Supplier__c = data.remittosupplier.id;
            suppInv3.Credit_Memo_Amount__c = -500;
            suppInv3.Invoice_Amount__c = -500;
            suppInv3.Supplier_Invoice__c = String.valueOfGmt(system.today()+2);
            suppInv3.Finalized__c = false;
            suppInv3.Accounting_Default_CR__c = testDefault.id;
            suppInvAEList.add(suppInv3);
            
            suppInv4 = new Supplier_Invoice__c();
            suppInv4.Company__c = data.company.id;
            suppInv4.Invoice_Type__c = 'Invoice';
            suppInv4.Date_Invoiced__c = System.now();
            suppInv4.Currency__c = TestFuel.currencyUSD.id;
            suppInv4.Supplier__c = data.remittosupplier.id;
            //suppInv4.Amount_Due__c = data.purchaseOrder4.Purchase_Order_Value__c;
            suppInv4.Invoice_Amount__c = 240;
            suppInv4.Supplier_Invoice__c = String.valueOfGmt(system.today()+3);
            suppInv4.Finalized__c = false;
            suppInvAEList.add(suppInv4);
            DML.insertAsUser( suppInvAEList );//KNDY-1751
            //insert suppInvAEList;
        }
        List<Purchase_Order_Line__c> poLineList = [Select id, Name, Item__c from Purchase_Order_Line__c where Purchase_Order__c in (:data.purchaseOrder2.id, :data.purchaseOrder3.id, :data.purchaseOrder4.id)];
        
        Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); {
            //suppInvLine1.Supplier__c = data.remittosupplier.id;
            suppInvLine1.Supplier_Invoice__c = suppInvAEList[0].id;
            suppInvLine1.Extended_Cost__c = 50;
            suppInvLine1.Invoice_Quantity__c = 4;
            suppInvLine1.Item__c = data.itemList[0].id;
            //suppInvLine1.Location__c = data.location.id;
            suppInvLine1.Purchase_Order__c = data.purchaseOrder2.id;
            suppInvLine1.Purchase_Order_Line__c = poLineList[0].id;
            suppInvLine1.Quantity_Received__c = 4;
            suppInvLine1.Unit_Price__c = 20; 
            suppInvLineList.add(suppInvLine1);
            
            Supplier_Invoice_Line__c suppInvLine2 = new Supplier_Invoice_Line__c();
            //suppInvLine2.Supplier__c = data.remittosupplier.id;
            suppInvLine2.Supplier_Invoice__c = suppInvAEList[0].id;
            suppInvLine2.Extended_Cost__c = 50;
            suppInvLine2.Invoice_Quantity__c = 4;
            suppInvLine2.Item__c = data.itemList[0].id;
            //suppInvLine2.Location__c = data.location.id;
            suppInvLine2.Purchase_Order__c = data.purchaseOrder2.id;
            suppInvLine2.Purchase_Order_Line__c = poLineList[1].id;
            suppInvLine2.Quantity_Received__c = 4;
            suppInvLine2.Unit_Price__c = 20; 
            suppInvLineList.add(suppInvLine2);
    
            Supplier_Invoice_Line__c suppInvLine3 = new Supplier_Invoice_Line__c();
            //suppInvLine3.Supplier__c = data.remittosupplier.id;
            suppInvLine3.Supplier_Invoice__c = suppInvAEList[1].id;
            suppInvLine3.Extended_Cost__c = 50;
            suppInvLine3.Invoice_Quantity__c = 4;
            suppInvLine3.Item__c = data.itemList[0].id;
            //suppInvLine3.Location__c = data.location.id;
            suppInvLine3.Purchase_Order__c = data.purchaseOrder3.id;
            suppInvLine3.Purchase_Order_Line__c = poLineList[2].id;
            suppInvLine3.Quantity_Received__c = 4;
            suppInvLine3.Unit_Price__c = 20; 
            suppInvLineList.add(suppInvLine3);
            
            Supplier_Invoice_Line__c suppInvLine4 = new Supplier_Invoice_Line__c();
            //suppInvLine4.Supplier__c = data.remittosupplier.id;
            suppInvLine4.Supplier_Invoice__c = suppInvAEList[1].id;
            suppInvLine4.Extended_Cost__c = 50;
            suppInvLine4.Invoice_Quantity__c = 4;
            suppInvLine4.Item__c = data.itemList[0].id;
            //suppInvLine4.Location__c = data.location.id;
            suppInvLine4.Purchase_Order__c = data.purchaseOrder3.id;
            suppInvLine4.Purchase_Order_Line__c = poLineList[3].id;
            suppInvLine4.Quantity_Received__c = 4;
            suppInvLine4.Unit_Price__c = 20; 
            suppInvLineList.add(suppInvLine4);
            
            Supplier_Invoice_Line__c suppInvLine5 = new Supplier_Invoice_Line__c();
            //suppInvLine5.Supplier__c = data.remittosupplier.id;
            suppInvLine5.Supplier_Invoice__c = suppInvAEList[3].id;
            suppInvLine5.Extended_Cost__c = 50;
            suppInvLine5.Invoice_Quantity__c = 4;
            suppInvLine5.Item__c = poLineList[4].Item__c;
            //suppInvLine5.Location__c = data.location.id;
            suppInvLine5.Purchase_Order__c = data.purchaseOrder4.id;
            suppInvLine5.Purchase_Order_Line__c = poLineList[4].id;
            suppInvLine5.Quantity_Received__c = 4;
            suppInvLine5.Unit_Price__c = 20; 
            suppInvLineList.add(suppInvLine5);
            
            Supplier_Invoice_Line__c suppInvLine6 = new Supplier_Invoice_Line__c();
            //suppInvLine6.Supplier__c = data.remittosupplier.id;
            suppInvLine6.Supplier_Invoice__c = suppInvAEList[3].id;
            suppInvLine6.Extended_Cost__c = 50;
            suppInvLine6.Invoice_Quantity__c = 4;
            suppInvLine6.Item__c = poLineList[5].Item__c;
            //suppInvLine6.Location__c = data.location.id;
            suppInvLine6.Purchase_Order__c = data.purchaseOrder4.id;
            suppInvLine6.Purchase_Order_Line__c = poLineList[5].id;
            suppInvLine6.Quantity_Received__c = 4;
            suppInvLine6.Unit_Price__c = 20; 
            suppInvLineList.add(suppInvLine6);
            
            Supplier_Invoice_Line__c suppInvLine7 = new Supplier_Invoice_Line__c();
            //suppInvLine7.Supplier__c = data.remittosupplier.id;
            suppInvLine7.Supplier_Invoice__c = suppInvAEList[3].id;
            suppInvLine7.Extended_Cost__c = 50;
            suppInvLine7.Invoice_Quantity__c = 4;
            suppInvLine7.Item__c = poLineList[6].Item__c;
            //suppInvLine7.Location__c = data.location.id;
            suppInvLine7.Purchase_Order__c = data.purchaseOrder4.id;
            suppInvLine7.Purchase_Order_Line__c = poLineList[6].id;
            suppInvLine7.Quantity_Received__c = 4;
            suppInvLine7.Unit_Price__c = 20; 
            suppInvLineList.add(suppInvLine7);
                
            
            DML.insertAsUser( suppInvLineList );//KNDY-1751
            //insert suppInvLineList;
            

            
            Supplier_Invoice_Line__c rilt1 = new Supplier_Invoice_Line__c();
            rilt1.Item__c = data.itemList[0].id;
            rilt1.Item__r = new Item__c( id= data.itemList[0].id );
            rilt1.Description__c = 'test';
            rilt1.Invoice_Quantity__c = -1; 
            rilt1.Accounting_Segment__c = testDefault.Id;
            rilt1.Unit_Price__c = 500;//KNDY-14371
            rilt1.Supplier_Invoice__c = suppInv3.id;
            rilt1.Subtransaction_Type__c = 'On Account';
            rilt1.Accounting_Segment__c = testDefault.Id;
            //rilt1.Invoice_Line__c = suppInvLine4.id;
            //rilt1.Invoice_Line__r = [ select id, Extended_Price__c from Supplier_Invoice_Line__c where id=:suppInvLine4.id ];  
            
            insert rilt1;
            
            suppInv1.Finalized__c = true;
            suppInv2.Finalized__c = true;
            suppInv3.Finalized__c = true;
			suppInv4.Finalized__c = true;
            
            DML.allowUpdateFields( new list<string>{'Finalized__c'}, Supplier_Invoice__c.SObjectType );
            DML.sobjectUpdate( suppInvAEList );    
            //update suppInvAEList;
        }
    
        Set<Id> invoiceIds = new Set<Id>();
        {
            for(Supplier_Invoice__c invoice: suppInvAEList){
                invoiceIds.add(invoice.id);
            }
        }
    
    }
    
    static testMethod void myUnitTest1() {
        Test.startTest();
        SupplierInvoiceAccountingExt GAEC;
        SupplierInvoiceData suppInvData = new SupplierInvoiceData();
       
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(suppInvData.suppInvAEList );
        setcon.setSelected(suppInvData.suppInvAEList);
        GAEC = new SupplierInvoiceAccountingExt(setcon);
       
        GAEC.GenerateSupplierInvAccounting();
        
        test.stopTest();
              
        List<Accounting_Entry__c> acctEntryList = [Select id, Name, Supplier_Invoice__c
                                                    from Accounting_Entry__c
                                                    where (Supplier_Invoice__c in :suppInvData.invoiceIds)]; 
        system.assertNotEquals(null,acctEntryList);
        List<Supplier_Invoice__c> suppInvoicesAfter = [Select id, Name, (Select id, Name from Accounting_Entries__r where void__c = false) from Supplier_Invoice__c where id in (:suppInvData.suppInv1.id,:suppInvData.suppInv2.id,:suppInvData.suppInv4.id )]; 
        system.debug(suppInvoicesAfter);
        
        system.assert(GAEC.selecterror==false, 'Error Found ' );
        
        for(integer i=0;i<suppInvoicesAfter.size(); i++){
            system.assertNotEquals(0,suppInvoicesAfter[i].Accounting_Entries__r.size());
        }
        
        
        List<Accounting_Entry__c> acctEntryListNew = [Select id, Name,
        											(Select id, Name, SubTransaction_Type__c from Accounting_Entry_Lines__r) 
                                                      from Accounting_Entry__c
                                                      where Supplier_Invoice__c = :suppInvData.suppInvAEList[3].id];
		/*
        String SubTrans;                                                      	
		for(Accounting_Entry_Line__c aeline: acctEntryListNew[0].Accounting_Entry_Lines__r){
			SubTrans = SubTrans+','+aeline.SubTransaction_Type__c;
		}
		*/
		/*
		//TODO: Consider pushing override info to an attribute of the accounting entry line
		system.assertEquals(true, SubTrans.contains('Purchase Price Variance'), subtrans);
		system.assertEquals(true, SubTrans.contains('Invoice Price Variance'), subtrans);
      	*/                                           
    }

    static testMethod void myUnitTest2() {
        Test.startTest();
        SupplierInvoiceAccountingExt GAEC;
        SupplierInvoiceData suppInvData = new SupplierInvoiceData();
        
        boolean sawException = false;
        try{
	       	suppInvData.suppInvAEList[0].Date_Invoiced__c = null;
	       	update suppInvData.suppInvAEList[0];
        }catch(Exception ex){
        	sawException = true;
        }
        system.assert(sawException, 'We are expecting to see an exception while attempting to change the date invoiced once finalized');
        /*
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(suppInvData.suppInvAEList );
        
        setcon.setSelected(suppInvData.suppInvAEList);
        GAEC = new SupplierInvoiceAccountingExt(setcon);
       
        GAEC.GenerateSupplierInvAccounting();
        */
        Test.stopTest();      
        //system.assertEquals(true,GAEC.requiredFielderror);
    } 
	
	static testMethod void myUnitTest3() {
        Test.startTest();
        SupplierInvoiceAccountingExt GAEC;
        SupplierInvoiceData suppInvData = new SupplierInvoiceData();
        
        boolean sawException = false;
        try{       
		    suppInvData.suppInvAEList[0].Company__c = null;
	       	update suppInvData.suppInvAEList[0];
        }catch(Exception ex){
        	sawException = true;
        }
        system.assert(sawException, 'We are expecting to see an exception while attempting to change the company once finalized');
        /*
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(suppInvData.suppInvAEList );
        
        setcon.setSelected(suppInvData.suppInvAEList);
        GAEC = new SupplierInvoiceAccountingExt(setcon);
       
        GAEC.GenerateSupplierInvAccounting();
        */
        Test.stopTest();        
        //system.assertEquals(true,GAEC.requiredFielderror);
	}
	
	static testMethod void myUnitTest4() {
        Test.startTest();
        SupplierInvoiceAccountingExt GAEC;
        SupplierInvoiceData suppInvData = new SupplierInvoiceData();
         boolean sawException = false;
        try{   
	        suppInvData.suppInvAEList[0].Currency__c = null;
	       	update suppInvData.suppInvAEList[0];
         }catch(Exception ex){
        	sawException = true;
        }
        system.assert(sawException, 'We are expecting to see an exception while attempting to change the transaction currency once finalized');
        
        /*
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(suppInvData.suppInvAEList );
        
        setcon.setSelected(suppInvData.suppInvAEList);
        GAEC = new SupplierInvoiceAccountingExt(setcon);
       
        GAEC.GenerateSupplierInvAccounting();
        */
        Test.stopTest();       
        //system.assertEquals(true,GAEC.requiredFielderror);
        
    }
    
    static testMethod void myUnitTest5() {
        Test.startTest();
        SupplierInvoiceAccountingExt GAEC;
        SupplierInvoiceData suppInvData = new SupplierInvoiceData();
        
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(suppInvData.suppInvAEList );
        
        setcon.setSelected(suppInvData.suppInvAEList);
        GAEC = new SupplierInvoiceAccountingExt(setcon);
       
        GAEC.GenerateSupplierInvAccounting();
        Test.stopTest();   
        Accounting_Entry__c acctEntry = [Select id, Name, (Select id, Name, Amount_CR__c, Amount_DR__c, Subtransaction_Type__c, Line_Type__c, GL_Account__c from Accounting_Entry_Lines__r) 
        								from Accounting_Entry__c where Supplier_Invoice__c = :suppInvData.suppInv3.id ];
        system.assertNotEquals(null, acctEntry);
       	//system.assertNotEquals(null, acctEntry.Accounting_Entry_Lines__r[0].GL_Account__c, acctEntry.Accounting_Entry_Lines__r[0]);
       	//system.assertNotEquals(null, acctEntry.Accounting_Entry_Lines__r[1].GL_Account__c, acctEntry.Accounting_Entry_Lines__r[1]);
 
    }
    /*Simulating below scenarios and asserting:
     *Clicking on 'Generate Accounting' list view button with no finalized invoice available.
     *Clicking on 'Generate Accounting' button where Date_Invoice__c = NULL on Supplier_Invoice__c.
     *Entering accounting page by an user with no invoice creation permissions.
     */
    static testMethod void myUnitTest6() {
        Test.startTest();
        SupplierInvoiceAccountingExt GAEC;
        SupplierInvoiceData suppInvData = new SupplierInvoiceData();
        List<Supplier_Invoice__c> siList = [Select Id, Date_Invoiced__c from Supplier_Invoice__c];
        for(Supplier_Invoice__c si: siList){
            si.Finalized_hidden__c = false;
            si.Finalized__c = false;
        }
        update siList;

        //To simulate condition with no finalized supplier invoices on the page.
        Apexpages.StandardSetController setcon0 = new Apexpages.StandardSetController(suppInvData.suppInvAEList );        
        setcon0.setSelected(suppInvData.suppInvAEList);
        GAEC = new SupplierInvoiceAccountingExt(setcon0);
        List<Apexpages.Message> allMsgs0 = ApexPages.getMessages();
        boolean noRecMsgFound = false;
        for(Apexpages.Message msg:allMsgs0){
            if (msg.getDetail().contains(Label.No_eligible_records_to_process)) noRecMsgFound = true;
        }
        system.assert(noRecMsgFound);

        for(Supplier_Invoice__c si: siList){
            si.Date_Invoiced__c = null;
        }
        update siList;
        for(Supplier_Invoice__c si: siList){
            si.Finalized__c = true;
        }
        update siList;
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(suppInvData.suppInvAEList );        
        setcon.setSelected(suppInvData.suppInvAEList);
        GAEC = new SupplierInvoiceAccountingExt(setcon);        
        List<Apexpages.Message> allMsgs = ApexPages.getMessages();
        boolean msgFound = false;
        for(Apexpages.Message msg:allMsgs){
            if (msg.getDetail().contains(Label.Date_Invoiced_is_blank)) msgFound = true;
        }
        system.assert(msgFound);

        Profile supportprofile = [SELECT Id FROM Profile WHERE Name='Custom: Support Profile']; 
        User supportUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                  EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                  LocaleSidKey='en_US', ProfileId = supportprofile.Id, 
                                  TimeZoneSidKey='America/Los_Angeles', UserName=string.valueOf(math.random()) + '@t' + string.valueOf(math.random()) + '.com');
        insert supportUser;        
        System.runAs(supportUser){
            Apexpages.StandardSetController supportCtrl = new Apexpages.StandardSetController(suppInvData.suppInvAEList );
            supportCtrl.setSelected(suppInvData.suppInvAEList);
            SupplierInvoiceAccountingExt GAEC12 = new SupplierInvoiceAccountingExt(supportCtrl);         
            List<Apexpages.Message> allExcMsgs = ApexPages.getMessages();
            boolean noPreviligesMsgFound = false;
            for(Apexpages.Message msg:allExcMsgs){
                if (msg.getDetail().contains(Label.Insufficient_access_to_create_a_supplier_invoice)) noPreviligesMsgFound = true;
            }
            system.assert(noPreviligesMsgFound);
        } 
        Test.stopTest();        
    }

    /*Simulating below scenario and asserting:
     *Clicking on 'Generate Accounting' button when there are no matching Accounting Rules.
     *Clicking on 'Generate Accounting' button without selecting invoices to process.
     */
    static testMethod void myUnitTest7() {
        Test.startTest();
        SupplierInvoiceAccountingExt GAEC;
        SupplierInvoiceData suppInvData = new SupplierInvoiceData();
        List<Accounting_Rule__c> allARS = [select Id from Accounting_Rule__c];
        delete allARS;
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(suppInvData.suppInvAEList );        
        setcon.setSelected(suppInvData.suppInvAEList);
        GAEC = new SupplierInvoiceAccountingExt(setcon);        
        List<Apexpages.Message> allMsgs = ApexPages.getMessages();
        boolean msgFound = false;
        for(Apexpages.Message msg:allMsgs){
            if (msg.getDetail().contains(Label.Create_Accounting_Rules)) msgFound = true;
        }
        system.assert(msgFound);
        Apexpages.StandardSetController setcon1 = new Apexpages.StandardSetController(suppInvData.suppInvAEList );        
        GAEC = new SupplierInvoiceAccountingExt(setcon1);  
        GAEC.GenerateSupplierInvAccounting();
        Test.stopTest();
    }
    
    static testMethod void testEntryGeneration() {
    	Test.startTest();
        
        SupplierInvoiceData suppInvData = new SupplierInvoiceData();
       
        	List<Supplier_Invoice__c> supplierInvoices = [Select id, Company__c, Name from Supplier_Invoice__c where id in :suppInvData.invoiceIds]; 
			Set<Id> companyIds = new Set<Id>();
			for(Supplier_Invoice__c si : supplierInvoices){
				companyIds.add(si.company__c);
			}
			database.executebatch(new SupplierInvoiceAccountingBatch(companyIds));
			
		Test.stopTest();
			
		
		supplierInvoices = [Select id, Company__c, Name,(Select id, Name from Accounting_Entries__r where void__c = false) from Supplier_Invoice__c where id in (:suppInvData.suppInv1.id,:suppInvData.suppInv2.id,:suppInvData.suppInv4.id )]; 
		
		for(integer i=0;i<supplierInvoices.size(); i++){
            system.assertNotEquals(0,supplierInvoices[i].Accounting_Entries__r.size());
        }
    
		
			
				
    }

        //PTP-69 Test method to verify the Payment Due date
    static testMethod void testPaymentDuedateonInvoice() {
    	
    	Payment_Term__c paymentTermInfo = new Payment_Term__c();
    	paymentTermInfo.Name = '1/5 Net 10';
    	paymentTermInfo.Description__c = '2% discount in 10 days, due 30 days';
    	paymentTermInfo.Discount_Days__c = 5;
    	paymentTermInfo.Discount_Percent__c = 1.0;
    	paymentTermInfo.Due_Days__c = 10;
        insert paymentTermInfo;
    	
    	Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();
        suppInv1.Company__c = data.company.id;
        suppInv1.Invoice_Type__c = 'Credit Memo';
        suppInv1.Date_Invoiced__c = System.now();
        suppInv1.transaction_date__c = system.now();
        suppInv1.Currency__c = TestFuel.currencyUSD.id;
        suppInv1.Supplier__c = data.remittosupplier.id;
        suppInv1.Invoice_Amount__c = 160;
        suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
        suppInv1.Finalized__c = false;
        suppInv1.Payment_Term__c = paymentTermInfo.id;
        insert suppInv1;
        //KNDY-17277 - discount earned deprecated
        Supplier_Invoice__c supInv = [Select id, Name, Date_Invoiced__c, Payment_Term__r.Due_Days__c, Payment_Due_Date__c from Supplier_Invoice__c where id = :suppInv1.id];
        
        system.assertEquals(supInv.Payment_Due_Date__c, (supInv.Date_Invoiced__c+supInv.Payment_Term__r.Due_Days__c).DATE());
        //KNDY-17277 - discount earned deprecated
        //system.assertEquals(0, supInv.Discount_Earned__c, 'This field should always be 0');
        paymentTermInfo.Due_Days__c = 20;
        
        suppInv1.Invoice_Type__c = 'Prepayment';
        update suppInv1;
        //KNDY-17277 - discount earned deprecated
         supInv = [Select id, Name, Date_Invoiced__c, Payment_Term__r.Due_Days__c, Payment_Due_Date__c from Supplier_Invoice__c where id = :suppInv1.id];
        
        //system.assertEquals(supInv.Payment_Due_Date__c, (supInv.Date_Invoiced__c+supInv.Payment_Term__r.Due_Days__c).DATE());
        //KNDY-17277 - discount earned deprecated
        //system.assertEquals(0, supInv.Discount_Earned__c, 'This field should always be 0');
        
       // update paymentTermInfo;//AR-2
        //system.assertEquals(supInv.Payment_Due_Date__c, (supInv.Date_Invoiced__c+supInv.Payment_Term__r.Due_Days__c).DATE());
        
    }


}