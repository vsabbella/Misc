/**
 *  @description This class consists of all the unit tests related to the Accounting Entry object and the required data.
 **/
@isTest
public class AccountingEntryServiceTest {
     
     static testMethod void testAEDelete(){
        TestFuel fuel = new TestFuel();
     	List<Period__c> periodList = fuel.periodList;
     	List<Accounting_Rule__c> acctRules = fuel.AccountingRuleList;
     	
        List<Journal_Entry__c> JEList = new List<Journal_Entry__c>();
        Journal_Entry__c je1 = new Journal_Entry__c();
    		je1.name = 'JE001';
    	    je1.Company__c = fuel.company.id;	
    	    je1.type__c = 'Manual';   
    	    je1.Transaction_Type__c = 'Manual';
    	    je1.Transaction_Date__c = System.now();  
    		je1.Currency__c = TestFuel.currencyUSD.id;
    		JEList.add(je1);
	    insert JEList;
	   
		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
	    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
    	    jeLine1.Journal_Entry__c = JEList[0].id;
    		jeLine1.Amount_CR__c = -5;
    		jeLine1.Amount_DR__c = 0;
    		jeLine1.Subtransaction_Type__c = 'Write Off';
    		jeLine1.GL_Account__c = fuel.cashGL.id;
    	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
    	    jeLine2.Journal_Entry__c = JEList[0].id;
    		jeLine2.Amount_CR__c = 0;
    		jeLine2.Amount_DR__c = -5;
    		jeLine2.Subtransaction_Type__c = 'Write Off';
    		jeLine2.GL_Account__c = fuel.receivablesGL.id;
    	    jeLineList.add(jeLine2); 
		
		insert jeLineList;
		
		je1.finalized__c = true;
		update je1;
	 
		AccountingService jea = new JournalEntryAccounting();
        jea.execute(jeLineList);
		
		List<Accounting_Entry__c> aeList = [Select id, Name, Related_Accounting_Entry__c, Total_Lines__c,Void__c, has_Exceptions__c, Line_exceptions__c,
							(Select id, Name, Amount_CR__c, Amount_DR__c, GL_Account__c from Accounting_Entry_Lines__r)
     						from Accounting_Entry__c
     						where journal_entry__c = :je1.id];
        	
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(aeList[0]); 
        AccountingEntryVoidExt AESExt = new AccountingEntryVoidExt(sc);
        AccountingEntryVoidExt AESExt2 = new AccountingEntryVoidExt();
        AESExt.doCancel();
        System.assertEquals(null, AESExt.deleteAECheck(), Apexpages.getMessages());
        System.assertEquals(null, AESExt.deleteAccountingEntry(), Apexpages.getMessages());
       
     }    
     
     static testmethod void testReverseAE(){
     	
     	TestFuel fuel = new TestFuel();
     	List<Period__c> periodList = fuel.periodList;
     	
     	List<Accounting_Rule__c> CustInvAcctRulesList = new List<Accounting_Rule__c>();
            
        Accounting_Rule__c custInvGoodsCR = new Accounting_Rule__c();
        custInvGoodsCR.Object_Name__c = 'Customer_Invoice__c';
        custInvGoodsCR.Accounting_Standard__c = fuel.accountingStandard.Id;
        //custInvGoodsCR.Company__c = fuel.company.Id;
        custInvGoodsCR.Transaction__c = 'Ship Invoice';
        custInvGoodsCR.SubTransaction_Type__c = 'Goods';
        //custInvAcctCR.Segment_Name__c = 'GL_Account__c';
        custInvGoodsCR.Rule_Type__c = 'CR';
        //custInvAcctCR.Criteria__c = 'Customer Type';
        custInvGoodsCR.Default_GL_Account__c = true;
        custInvGoodsCR.GL_Account_Reference_Value__c = null;
        custInvGoodsCR.GL_Account__c = fuel.revenueGL.id;
        custInvGoodsCR.Effective_Start_Date__c=fuel.effStartDate;
        CustInvAcctRulesList.add(custInvGoodsCR);
     	
        Accounting_Rule__c custInvGoodsDR = new Accounting_Rule__c();
        custInvGoodsDR.Object_Name__c = 'Customer_Invoice__c';
        custInvGoodsDR.Accounting_Standard__c = fuel.accountingStandard.Id;
        //custInvGoodsDR.Company__c = fuel.company.Id;
        custInvGoodsDR.Transaction__c = 'Ship Invoice';
        custInvGoodsDR.SubTransaction_Type__c = 'Goods';
        //custInvAcctDR.Segment_Name__c = 'GL_Account__c';
        custInvGoodsDR.Rule_Type__c = 'DR';
        //custInvAcctDR.Criteria__c = 'Customer Type';
        custInvGoodsDR.Default_GL_Account__c = true;
        custInvGoodsDR.GL_Account_Reference_Value__c = null;
        custInvGoodsDR.GL_Account__c = fuel.receivablesGL.id;
        custInvGoodsDR.Effective_Start_Date__c=fuel.effStartDate;
        
        CustInvAcctRulesList.add(custInvGoodsDR);
            
        insert CustInvAcctRulesList;
        
     	Sales_Order__c so = fuel.salesOrder;
            
        Customer_Invoice__c ci = new Customer_Invoice__c();
        ci.Status__c = 'Open';
        ci.Sold_to_Customer__c = fuel.customerSoldTo.Id;
        ci.Invoice_Type__c = 'Ship Invoice';
        ci.Currency__c = so.Currency__c;
        ci.Transaction_Date__c = system.now().addMinutes(-1);
        ci.Date_Invoiced__c = system.now().addMinutes(-1);
        ci.Company__c = fuel.company.Id;
        ci.Bill_to_Customer__c = so.Bill_to__c;
        ci.Customer__c = fuel.customerParent.Id;
        
        insert ci;
        
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        for(Sales_Order_Line__c sol : fuel.salesOrderLines){
            Customer_Invoice_Line__c iCIL = new Customer_Invoice_Line__c();
            iCIL.Company__c = so.Company__c;
            iCIL.Customer_Invoice__c = ci.id;
			iCIL.Product__c = fuel.product.Id;
			iCIL.Sales_Order__c = so.Id;
			iCIL.Sales_Order_Line__c = sol.Id;
            iCIL.Unit_Price__c = 10;
            iCIL.Quantity_Shipped__c = sol.Quantity_Ordered__c;
            iCIL.Discount_Percent__c = sol.Discount_Percent__c; 
            iCIL.Line_Type__c = sol.Line_Type__c;
            iCIL.Extended_Price__c = 10 *  sol.Quantity_Ordered__c;
            iCIL.Quantity_From_Stock__c = sol.Quantity_From_Stock__c;
            cils.add(iCIL);
        }
        insert cils;
        
        ci.finalized__c = true;
        update ci;
        
        AccountingService cia = new CustomerInvoiceAccounting();
        list <Customer_Invoice_line__c> cilines = new List<Customer_Invoice_line__c>();
        cilines.addall(cils);
      	test.startTest();
        cia.execute(cilines);
     	/*
	    TestData data = new TestData();
	    Test.startTest();
	    Customer_Invoice__c custInv = new Customer_Invoice__c();
	    custInv.Company__c = data.company.id;
	    custInv.Invoice_Type__c = 'Manual';
	    insert custInv;
	    
	    List<Accounting_Entry__c> aeList = new List<Accounting_Entry__c>();
     	Accounting_Entry__c acctEntry = new Accounting_Entry__c();
        acctEntry.company__c = data.company.id; 
        acctEntry.Transaction_Date__c = system.now();
        acctEntry.Finalized_Date__c = system.now();
        //acctEntry.GL_Date__c = system.today();
        //acctEntry.Period__c = data.periodList[0].Id;
        acctEntry.Transaction_Type__c = 'Customer Invoice';
        acctEntry.Source_Document_Object_Name__c = 'Customer_Invoice__c';
        acctEntry.Currency__c = TestFuel.currencyUSD.id;
        acctEntry.Customer_Invoice__c = custInv.id;
        
        insert acctEntry;
        aeList.add(acctEntry);
        
        List<Accounting_Entry_Line__c> acctEntryLineList = new List<Accounting_Entry_Line__c>();
        
        Accounting_Entry_Line__c acctEntryLineCR = new Accounting_Entry_Line__c();
        acctEntryLineCR.Amount_CR__c = 50;
        acctEntryLineCR.GL_Account__c = data.Acctdata.PropertyGL.id; 
        acctEntryLineCR.Transaction_Date__c = system.today();
        acctEntryLineCR.Accounting_Entry__c = acctEntry.id;
        acctEntryLineCR.Accounting_Rule__c = data.acctData.CustInvAcctRulesList[0].Id;
        acctEntryLineList.add(acctEntryLineCR);
        
        Accounting_Entry_Line__c acctEntryLineDR = new Accounting_Entry_Line__c();
        acctEntryLineDR.Amount_DR__c = 125;
        acctEntryLineDR.GL_Account__c = data.Acctdata.cashGL.id;
        acctEntryLineDR.Transaction_Date__c = system.today();
        acctEntryLineDR.Accounting_Entry__c = acctEntry.id;   
        acctEntryLineDR.Accounting_Rule__c = data.acctData.CustInvAcctRulesList[1].Id;
        acctEntryLineList.add(acctEntryLineDR);
     	
     	insert acctEntryLineList;
     	*/
     	List<Accounting_Entry__c> aeList = [Select id, Name, Related_Accounting_Entry__c, Void__c, has_Exceptions__c
     						from Accounting_Entry__c
     						where customer_invoice__c = :ci.id];
     	
     	system.debug(logginglevel.info,'aeList : '+aeList);
     	
     	system.assertNotEquals(true, aeList[0].has_Exceptions__c, aeList);
     	Accounting_Entry__c acctEntry = aeList[0];
     	//AccountingEntryService.getInstance().reverseAccountingEntryXXX(aeList);
     	AccountingEntryService.getInstance().AccountingEntryreversal(AccountingEntryService.AEReverseType.AEReverse,aeList);
     	
     	aeList = [Select id, Name, Related_Accounting_Entry__c,
     				(Select id, Name, Amount_CR__c, Amount_DR__c, GL_Account__c from Accounting_Entry_Lines__r)
     				from Accounting_Entry__c
     				where Customer_Invoice__c = :ci.id
     				and Related_Accounting_Entry__c != null
     				order by id ASC];
     				
     	system.debug(logginglevel.info,'after - aeList :'+aeList);
     	Test.stopTest();
     	system.assertEquals(acctEntry.id, aeList[0].Related_Accounting_Entry__c)	;		
     	
     }
     
     static testmethod void testReverseAENegativeNumbers(){
     	
     	TestFuel fuel = new TestFuel();
     	List<Period__c> periodList = fuel.periodList;
     	List<Accounting_Rule__c> acctRules = fuel.AccountingRuleList;
     	
        List<Journal_Entry__c> JEList = new List<Journal_Entry__c>();
        Journal_Entry__c je1 = new Journal_Entry__c();
		je1.name = 'JE001';
	    je1.Company__c = fuel.company.id;	
	    je1.type__c = 'Manual';   
	    je1.Transaction_Type__c = 'Manual';
	    je1.Transaction_Date__c = System.now();  
		je1.Currency__c = TestFuel.currencyUSD.id;
		JEList.add(je1);
	    insert JEList;
	   
		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
	    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = JEList[0].id;
		jeLine1.Amount_CR__c = -5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.Subtransaction_Type__c = 'Write Off';
		jeLine1.GL_Account__c = fuel.cashGL.id;
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = JEList[0].id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = -5;
		jeLine2.Subtransaction_Type__c = 'Write Off';
		jeLine2.GL_Account__c = fuel.receivablesGL.id;
	    jeLineList.add(jeLine2); 
		
		insert jeLineList;
		
		je1.finalized__c = true;
		update je1;
		Test.startTest();
		AccountingService jea = new JournalEntryAccounting();
        jea.execute(jeLineList);
		
		List<Accounting_Entry__c> aeList = [Select id, Name, Related_Accounting_Entry__c, Void__c, has_Exceptions__c, Line_exceptions__c,
							(Select id, Name, Amount_CR__c, Amount_DR__c, GL_Account__c from Accounting_Entry_Lines__r)
     						from Accounting_Entry__c
     						where journal_entry__c = :je1.id];
		system.assert(aeList != null);
		system.assert(aeList.size() == 1,'aeList:'+aeList);
		system.assert(aeList[0].accounting_entry_lines__r.size() == 2);
		
		List<Task> exceptionList = [select Id,
										   (select Id, Exception_Code__c, Status, Type 
										      from Tasks
							      	 		 where isClosed = false) 
									  from Accounting_Entry_Line__c 
									 where Id = :aeList[0].Accounting_Entry_Lines__r[1].id].Tasks;
									 
		system.assert(exceptionList.size() == 0,'exceptionList'+exceptionList);
		// expected exceptions: JE_MISSING_TRANSACTION_DATE, JE_MISSING_COMPANY, JE_MISSING_TRANSACTION_CURRENCY
		
		system.assertNotEquals(true, aeList[0].has_Exceptions__c, 'aeList[0].Accounting_Entry_Lines__r:'+aeList[0].Accounting_Entry_Lines__r);
		
		Double oldAmountCR, oldAmountDR;
     	for(Accounting_Entry_Line__c ael: aeList[0].accounting_entry_lines__r){
     		if(ael.GL_Account__c == fuel.receivablesGL.id){
     			oldAmountDR = ael.Amount_DR__c;
     		}else{
     			oldAmountCR = ael.Amount_CR__c;
     		}
     	}
     	Accounting_Entry__c acctEntry = aeList[0];
     	
     	AccountingEntryService.getInstance().AccountingEntryreversal(AccountingEntryService.AEReverseType.AEReverse,aeList);
     	
     	aeList = [Select id, Name, Related_Accounting_Entry__c, Void__c, has_Exceptions__c,
							(Select id, Name, Amount_CR__c, Amount_DR__c, GL_Account__c from Accounting_Entry_Lines__r)
     						from Accounting_Entry__c
     						where journal_entry__c = :je1.id
     						and Related_Accounting_Entry__c != null
     						order by id ASC];
		
		system.debug(logginglevel.info,'after - aeList :'+aeList);
     	Test.stopTest();
     	system.assertEquals(acctEntry.id, aeList[0].Related_Accounting_Entry__c)	;	
		system.assert(aeList != null);
		system.assert(aeList.size() == 1,'aeList:'+aeList);
		system.assert(aeList[0].accounting_entry_lines__r.size() == 2);
     	
     	Double newAmountCR, newAmountDR;
     	for(Accounting_Entry_Line__c ael: aeList[0].accounting_entry_lines__r){
     		if(ael.GL_Account__c == fuel.receivablesGL.id){
     			newAmountCR = ael.Amount_CR__c;
     		}else{
     			newAmountDR = ael.Amount_DR__c;
     		}
     	}
     	
     	system.assert(oldAmountDR == newAmountCR,'oldAmountDR:'+oldAmountDR+'	---newAmountCR:'+newAmountCR);
     	system.assert(oldAmountCR == newAmountDR,'oldAmountCR:'+oldAmountCR+'	---newAmountDR:'+newAmountDR);
     }
     
     static testmethod void testsetFinalizedDate(){
     	//TestData data = new TestData();
     	TestFuel data = new TestFuel();
     	List<Period__c> periodList = data.periodList;
		/*Company__c company = new Company__c();
        company = new Company__c();
        company.name = '100';
        company.A_Days__c = 6;
        company.B_Days__c = 20;
        company.C_Days__c = 90;
        company.Functional_Currency__c = TestFuel.currencySGD.id;
        company.Corporate_Currency__c = 'EUR';
        company.Reporting_Currency__c = 'GBP';
            
        insert company;
        
        Item__c ItemObj2=new Item__c();
        ItemObj2.name='HP Printer';
        ItemObj2.Description__c='It is a Test item';
        ItemObj2.Source__c=Label.Source_field_of_ItemP;
        ItemObj2.Company__c = company.id;
        
        insert ItemObj2;
        
        Product__c product = new Product__c();
                        
        product.company__c = company.id;
        product.Name = 'Test Product';
        product.Item__c = ItemObj2.id;
        
        insert product;*/
		Test.startTest();
	    Customer_Invoice__c custInv = new Customer_Invoice__c();
	    custInv.Company__c = data.company.id;
	    custInv.Invoice_Type__c = 'Manual';
	    custInv.Date_Invoiced__c = system.now();
	    custInv.Transaction_Date__c = system.now();
	    custInv.Currency__c = TestFuel.currencyUSD.id;
	    insert custInv;
	    
	    Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c ();
	    custInvLine1.Customer_Invoice__c = custInv.id;
	    custInvLine1.Product__c = data.product.id;
	    custInvLine1.Unit_Price__c = 100;
	    custInvLine1.Quantity_Shipped__c = 10;
	    
	    insert custInvLine1;
	    
	    custInv.Finalized__c = true;
	    update custInv;
	    Test.stopTest();
	    
	    system.assertNotEquals(null, custInv);
	    system.assertNotEquals(null, custInvLine1);
	    
	    custInv = [Select id, Name, Finalized_Date__c, Finalized__c, Transaction_Date__c , Date_Invoiced__c
	    			from Customer_Invoice__c
	    			where id = :custInv.id];
	    			
	    system.assertEquals(custInv.Date_Invoiced__c, custInv.Transaction_Date__c );
	    system.assertNotEquals( null ,custInv.Finalized_Date__c);
	    
	    custInv.Finalized__c = false;
	    custInv.Finalized_hidden__c = false;
	    update custInv;
	    
	    custInv = [Select id, Name, Finalized_Date__c, Finalized__c, Transaction_Date__c , Date_Invoiced__c
	    			from Customer_Invoice__c
	    			where id = :custInv.id];
	    
	    system.assertEquals( null ,custInv.Finalized_Date__c);
	    
	    custInv.Date_Invoiced__c = system.now() - 45;
	    custInv.Finalized__c = true;
	    update custInv;
	    
	    custInv = [Select id, Name, Finalized_Date__c, Finalized__c, Transaction_Date__c , Date_Invoiced__c
	    			from Customer_Invoice__c
	    			where id = :custInv.id];
	    
	    KSE.dateTimeCloseResult closeResult = KSE.areDateTimesClose(system.now(), custInv.Finalized_Date__c); //KNDY-3707    
	    system.assert(closeResult.bCloseEnough, closeResult); //KNDY-3707
	    
	   
     
     }
     
     static testMethod void testTriggerDispatch(){
     	 //KNDY-7099
	    system.assert(!DML.checkTriggerDispatch(Accounting_Entry__c.getSobjectType()));
	    
	    Configuration__c aeconfig = new Configuration__c(name = Accounting_Entry__c.getSobjectType().getDescribe().getLocalName() + '-' + Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), value__c = userInfo.getUserId());
	    insert aeconfig;
	    system.assert(DML.checkTriggerDispatch(Accounting_Entry__c.getSobjectType()));	 
	    
	    DML.systemTime = system.now().addHours(48);
	    system.assert(!DML.checkTriggerDispatch(Accounting_Entry__c.getSobjectType())); 
	    
	    system.assertEquals(0, [select id from Configuration__c where id = :aeconfig.id].size(), 'DML should clean out old configs');
	    
	    aeconfig = new Configuration__c(name = Accounting_Entry__c.getSobjectType().getDescribe().getLocalName() + '-' + Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), value__c = userInfo.getUserId());
	    insert aeconfig;
	    
	    DML.systemTime = system.now();
	    system.assert(DML.checkTriggerDispatch(Accounting_Entry__c.getSobjectType()));   
     	
     	aeconfig.value__c = 'baddata';
     	update aeconfig;
     	
     	system.assert(!DML.checkTriggerDispatch(Accounting_Entry__c.getSobjectType()));
     	system.assertEquals(1, [select id from Configuration__c where id = :aeconfig.id].size(), 'DML will leave bad configs');
     }
     
     static testMethod void testGlobalTriggerDispatch(){
     	 
	    system.assert(!DML.checkTriggerDispatch(Accounting_Entry__c.getSobjectType()));
	    
	    Configuration__c globalconfig = new Configuration__c(name = DML.globalDispatch, value__c = DML.globalDispatchDisable);
	    insert globalconfig;
	    system.assert(DML.checkTriggerDispatch(Accounting_Entry__c.getSobjectType()));	 
	    
	    DML.systemTime = system.now().addHours(48);
	    system.assert(!DML.checkTriggerDispatch(Accounting_Entry__c.getSobjectType()));
	    
	    system.assertEquals(0, [select id from Configuration__c where id = :globalconfig.id].size(), 'DML should clean out old configs'); 
	    
	    globalconfig = new Configuration__c(name = DML.globalDispatch, value__c = DML.globalDispatchDisable);
	    insert globalconfig;
	    
	    DML.systemTime = system.now();
	    system.assert(DML.checkTriggerDispatch(Accounting_Entry__c.getSobjectType()));   
     	
     	globalconfig.value__c = 'baddata';
     	update globalconfig;
     	
     	system.assert(!DML.checkTriggerDispatch(Accounting_Entry__c.getSobjectType()));
     	system.assertEquals(1, [select id from Configuration__c where id = :globalconfig.id].size(), 'DML will leave bad configs');
     }
     
     
     
     
}