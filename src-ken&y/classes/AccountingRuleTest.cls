@isTest
private class AccountingRuleTest {
	@testSetup static void ts() { 
		TestFuel data = new TestFuel();	
		// these asserts cause TestFuelQuery to insert data
 		Accounting_Rule__c arHdrApCR = new Accounting_Rule__c();
 		arHdrApCR.Accounting_Standard__c = data.accountingStandard.Id;
 		arHdrApCR.Object_Name__c = 'Customer_Invoice__c';
 		arHdrApCR.transaction__c = 'Ship Invoice';
 		arHdrApCR.Rule_Type__c = 'CR';
 		arHdrApCR.GL_Account__c = data.receivablesGL.Id;
 		arHdrApCR.Effective_Start_Date__c = system.now().addmonths(-1);
 		arHdrApCR.Default_GL_Account__c = true;
 		
 		Accounting_Rule__c arHdrApDR = new Accounting_Rule__c();
 		arHdrApDR.Accounting_Standard__c = data.accountingStandard.Id;
 		arHdrApDR.Object_Name__c = 'Customer_Invoice__c'; 
 		arHdrApDR.transaction__c = 'Ship Invoice';
 		arHdrApDR.Rule_Type__c = 'DR';
 		arHdrApDR.Default_GL_Account__c = true;
 		arHdrApDR.Effective_Start_Date__c = system.now().addmonths(-1); 		
 		arHdrApDR.GL_Account__c = data.receivablesGL.Id;
 		
 		Accounting_Rule__c arLineApCR = new Accounting_Rule__c();
 		arLineApCR.Accounting_Standard__c = data.accountingStandard.Id;
 		arLineApCR.Object_Name__c = 'Customer_Invoice__c';
 		arLineApCR.transaction__c = 'Ship Invoice';
 		arLineApCR.subtransaction_type__c = 'Goods';
 		arLineApCR.Rule_Type__c = 'CR';
 		arLineApCR.GL_Account__c = data.receivablesGL.Id;
 		arLineApCR.Effective_Start_Date__c = system.now().addmonths(-1); 				
 		arLineApCR.Default_GL_Account__c = true;
 		
 		
 		Accounting_Rule__c arLineApDR = new Accounting_Rule__c();
 		arLineApDR.Accounting_Standard__c = data.accountingStandard.Id;
 		arLineApDR.Object_Name__c = 'Customer_Invoice__c';
 		arLineApDR.transaction__c = 'Ship Invoice';
 		arLineApDR.subtransaction_type__c = 'Goods';
 		arLineApDR.Rule_Type__c = 'DR';
 		arLineApDR.Default_GL_Account__c = true;
 		arLineApDR.Effective_Start_Date__c = system.now().addmonths(-1); 				 		
 		arLineApDR.GL_Account__c = data.receivablesGL.Id;
 		
 		insert new List<Accounting_Rule__c>{arHdrApCR, arHdrApDR, arLineApCR, arLineApDR};
 		
 		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = system.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
  		test.starttest();
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 1;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 0;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Sales_Tax__c = null;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
        insert ciLine1;
  		test.stoptest();

		system.assert(		
			data.company != null &&
			data.purchaseOrder != null &&
			data.purchaseOrderLines != null &&
			data.remittosupplier != null &&
			data.periodList != null &&
			data.itemList != null &&
			data.cashGL != null &&
			data.receivablesGL != null &&
			data.accountingStandard != null &&
			data.expenseGL != null &&
			data.FGInventoryGL != null
		);
	}
	static testmethod void testAccountingRuleExt()  { 
		AccountingRuleExt ext = new AccountingRuleExt( new Apexpages.Standardcontroller(new Accounting_Rule__c()));
		Accounting_Standard__c acctStd = new Accounting_Standard__c(name = 'US GAAP');
		insert acctStd;
  		Accounting_Rule__c shipacctRule1 = new Accounting_Rule__c();
  		shipacctRule1.Accounting_Standard__c = acctStd.Id;
        shipacctRule1.Object_Name__c = 'Shipment__c';
        shipacctRule1.Transaction__c = 'Shipment';
        shipacctRule1.SubTransaction_Type__c = 'Goods';
        shipacctRule1.Line_Type__c = null;
        //shipacctRule1.Segment_Name__c = 'GL_Account__c';
        shipacctRule1.Rule_Type__c = 'CR';
        //shipacctRule1.Criteria__c = 'Item Class';
        shipacctRule1.Default_GL_Account__c = false;
        shipacctRule1.GL_Account_Reference_Value__c = 'Product__r.Item__r.class__r.Inventory_GL_Account__c';
        shipacctRule1.GL_Account__c = null;
        shipacctRule1.Amount_Reference__c = null;  
        shipacctRule1.Effective_start_date__c= system.now().date().addMonths(-5);          
		insert shipacctRule1; 
		
		ext = new AccountingRuleExt( new Apexpages.Standardcontroller( shipacctRule1 ) );
		system.assert( ext.thewrap.exceptionMsg == '' ,ext.thewrap.exceptionMsg); 
		
		Apexpages.Standardsetcontroller setc = new Apexpages.StandardSetController(
		 	new List<Accounting_Rule__c>{shipacctRule1} );
		 	
		setc.setSelected(new List<Accounting_Rule__c>{shipacctRule1});
		
		ext = new AccountingRuleExt( new Apexpages.Standardsetcontroller( 
			new List<Accounting_Rule__c>{shipacctRule1} ) );
			           
		system.assert( ext.errcount == 0);
	}


	static testmethod void t1()  { 
		AccountingRuleExt ext = new AccountingRuleExt( new Apexpages.Standardcontroller(new Accounting_Rule__c()));
		Accounting_Standard__c acctStd = new Accounting_Standard__c(name = 'US GAAP');
		insert acctStd;
		List<Accounting_Rule__c> ShipmentAcctRulesList = new List<Accounting_Rule__c>();
	    Accounting_Rule__c shipacctRule1 = new Accounting_Rule__c(); 
	    shipacctRule1.Accounting_Standard__c = acctStd.Id;           
        shipacctRule1.Object_Name__c = 'Shipment__c';
        shipacctRule1.Transaction__c = 'Shipment';
        shipacctRule1.SubTransaction_Type__c = 'Goods';
        shipacctRule1.Line_Type__c = null;
        //shipacctRule1.Segment_Name__c = 'GL_Account__c';
        shipacctRule1.Rule_Type__c = 'CR';
        //shipacctRule1.Criteria__c = 'Item Class';
        shipacctRule1.Default_GL_Account__c = false;
        shipacctRule1.GL_Account_Reference_Value__c = 'Product__r.Item__r.class__r.Inventory_GL_Account__c';
        shipacctRule1.GL_Account__c = null;
        shipacctRule1.Amount_Reference__c = null;     
        shipacctRule1.Effective_start_date__c= system.now().date().addMonths(-5);                         
        ShipmentAcctRulesList.add(shipacctRule1);
        
        Accounting_Rule__c shipacctRule2 = new Accounting_Rule__c();
        shipacctRule2.Accounting_Standard__c = acctStd.Id;
        shipacctRule2.Object_Name__c = 'Shipment__c';
        shipacctRule2.Transaction__c = 'Shipment';
        shipacctRule2.SubTransaction_Type__c = 'Goods';
        shipacctRule2.Line_Type__c = null;
        //shipacctRule2.Segment_Name__c = 'GL_Account__c';
        shipacctRule2.Rule_Type__c = 'DR';
        //shipacctRule2.Criteria__c = 'Accounting Default';
        shipacctRule2.Default_GL_Account__c = true;
        shipacctRule2.GL_Account_Reference_Value__c = 'Product__r.Item__r.class__r.Inventory_GL_Account__c';
        shipacctRule2.GL_Account__c = null;
        shipacctRule2.Amount_Reference__c = null;        
        shipacctRule2.Effective_start_date__c= system.now().date().addMonths(-5);                         
        ShipmentAcctRulesList.add(shipacctRule2);  
        
        insert ShipmentAcctRulesList;
	
		
		
		ext = new AccountingRuleExt( new Apexpages.Standardcontroller( shipacctRule1 ));
		system.assert( ext.thewrap.exceptionMsg == '' , ' expected no errors ' ); 
		
		ext = new AccountingRuleExt( new Apexpages.Standardcontroller( shipacctRule2 ));
		system.assert( ext.thewrap.exceptionMsg != '' , ' expected one errors ' ); 
		
		
		Apexpages.Standardsetcontroller setc = new Apexpages.StandardSetController(
		 	new List<Accounting_Rule__c>{shipacctRule1} );
		 	
		setc.setSelected(new List<Accounting_Rule__c>{shipacctRule1});
		
		ext = new AccountingRuleExt( new Apexpages.Standardsetcontroller( 
			new List<Accounting_Rule__c>{shipacctRule1} ) );
			           
		system.assert( ext.errcount == 0);
	}
    //KNDY-1126 Security scanner -Test method with no asserts.Commenting the below empty test methods
    
	//static testmethod void t2()  { 
	
		
		// this rule has a default, but no actual default, should be invalid (negitive test)
		
		//No Longer relevant.  Probably going to be replaced by a journal extries
		/*
		Accounting_Rule__c accRule = new Accounting_Rule__c();
	    accRule.Transaction__c = 'Adjustment';
	    accRule.Segment_Name__c = 'GL_Account__c';
	    accRule.Debit_Credit__c = 'DR';
	    accRule.Criteria__c = 'Item Class';
	    accRule.Default_Segment_Value__c = true;
		insert accRule; 
		
		AccountingRuleExt ext = new AccountingRuleExt( new Apexpages.StandardController( accRule ));
			           
		system.assert( ext.hasErrors == true, ' show me the error when default is set but segment missing');
		*/
	
		
		// TODO add a positive test for default_segment_value set correctly
	//}
	
	
	//static testmethod void t3()  { 
	
		// this rule has a default, but no actual default, should be invalid (negitive test)
		//No Longer relevant.  Probably going to be replaced by a journal extries
		/*
		Accounting_Rule__c accRule = new Accounting_Rule__c();
	    accRule.Transaction__c = 'Adjustment_bad';
	    accRule.Segment_Name__c = 'GL_Account__c';
	    accRule.Debit_Credit__c = 'PR';
	    accRule.Criteria__c = 'Item Class';
	    accRule.Default_Segment_Value__c = true;
		insert accRule; 
		
		AccountingRuleExt ext = new AccountingRuleExt( new Apexpages.StandardController( accRule ));
			           
		system.assert( ext.hasErrors == true, ' show me the error when transaction is bad');
		*/
	//}	
	//static testmethod void t4()  { 
	
		// this rule has a default, but no actual default, should be invalid (negitive test)
		
		//No Longer relevant.  Probably going to be replaced by a journal extries
		/*		
		Accounting_Rule__c accRule = new Accounting_Rule__c();
	   // accRule.Transaction__c = 'Adjustment_bad';
	    accRule.Segment_Name__c = 'GL_Account__c';
	    accRule.Debit_Credit__c = 'DR';
	    accRule.Criteria__c = 'Item Class';
	    accRule.Default_Segment_Value__c = false;
		insert accRule; 
		
		AccountingRuleExt ext = new AccountingRuleExt( new Apexpages.StandardController( accRule ));
			           
		system.assert( ext.hasErrors == true, ' show me the error when transaction is missing');
		*/
//	}	
    
    static testmethod void testInvalidTransactionTypeObjectCombination()
    {
        //FIN-1085 Assert if any invalid combination is erroring out.
        Accounting_Standard__c acctStd = new Accounting_Standard__c(name = 'US GAAP');
		insert acctStd;
        Accounting_Rule__c invalidRule = new Accounting_Rule__c(Accounting_Standard__c = acctStd.id ,name='Invalid Rule',rule_type__c='CR',
                                                           Object_Name__c='Journal_Entry__c',Transaction__c='Credit Memo',Raise_Exceptions_for_Blank_Amounts__c=false,Suppress_Zero_Amount_Lines__c = true,
                                                           GL_Account_Reference_Value__c='GL_Account__c',Effective_start_date__c= system.now().date().addMonths(-5));
        insert invalidRule;
        Test.setCurrentPage( Page.AccountingRuleValidRule);
        ApexPages.StandardController sc = new ApexPages.StandardController(invalidRule);
        AccountingRuleExt ruleExt = new AccountingRuleExt(sc);
        system.debug('ruleExt.thewrap.exceptionMsg'+ruleExt.thewrap.exceptionMsg);
        //Commenting below as we are not validating Object-TT Combo till all SDs start using new Transaction_Type__c field
        //system.assert(ruleExt.thewrap.exceptionMsg.contains('Invalid Transaction Type'),'Expecting Error due to invalid transaction type');
        system.assert(ruleExt.thewrap.exceptionMsg=='','Expecting No Error due to invalid transaction type');

    }
    static testmethod void testEffdateOnNewRules()
    {
    	TestFuelQuery fuel = new TestfuelQuery();       	
    	Date dateFrom = system.now().date();
    	Date dateTo  = dateFrom.addMonths(10);
    	list<accounting_rule__c> validRuleList = new list<accounting_rule__c>();
    	list<accounting_rule__c> invalidRuleList = new list<accounting_rule__c>();
    	
        Test.starttest();
    	//BulkInsert

	    Accounting_Rule__c RuleWithoutEffDateTo       = new Accounting_Rule__c(name='RuleWithoutEffDateTo',rule_type__c='CR',transaction__c='Manual',accounting_standard__c = fuel.accountingStandard.Id,Raise_Exceptions_for_Blank_Amounts__c=false,Suppress_Zero_Amount_Lines__c = true,
	                                                                            Object_Name__c='Journal_Entry__c',GL_Account_Reference_Value__c='GL_Account__c',Line_Type__c='Standard',Effective_Start_Date__c=dateFrom
	                                                                            );    
	    Accounting_Rule__c RuleWithEffDate            = new Accounting_Rule__c(name='RuleWithEffDate',rule_type__c='CR',transaction__c='Manual',accounting_standard__c = fuel.accountingStandard.Id,Raise_Exceptions_for_Blank_Amounts__c=false,Suppress_Zero_Amount_Lines__c = true,
	                                                   							Object_Name__c='Journal_Entry__c',GL_Account_Reference_Value__c='GL_Account__c',Effective_Start_Date__c=dateFrom,Effective_End_Date__c=dateTo
	                                                                            );    
	                                                                            
	    Accounting_Rule__c RuleWithoutEffDate         = new Accounting_Rule__c(name='RuleWithoutEffDate',rule_type__c='CR',transaction__c='Manual',accounting_standard__c = fuel.accountingStandard.Id,Raise_Exceptions_for_Blank_Amounts__c=false,Suppress_Zero_Amount_Lines__c = true,
	                                                                            Object_Name__c='Journal_Entry__c',GL_Account_Reference_Value__c='GL_Account__c',Effective_Start_Date__c=null
	                                                                           );                                                                        
        Accounting_Rule__c RuleWithOverLappingEffDate = new Accounting_Rule__c(name='RuleWithOverLappingEffDate',rule_type__c='CR',transaction__c='Manual',accounting_standard__c = fuel.accountingStandard.Id,Raise_Exceptions_for_Blank_Amounts__c=false,Suppress_Zero_Amount_Lines__c = true,
                                                   							    Object_Name__c='Journal_Entry__c',GL_Account_Reference_Value__c='GL_Account__c',Effective_Start_Date__c=dateFrom.addDays(2),Effective_End_Date__c=dateTo
                                                                               );  
        Accounting_Rule__c RuleWithEffEndDateB4StartDate = new Accounting_Rule__c(name='RuleWithEffEndDateB4StartDate',rule_type__c='CR',transaction__c='Manual',accounting_standard__c = fuel.accountingStandard.Id,Raise_Exceptions_for_Blank_Amounts__c=false,Suppress_Zero_Amount_Lines__c = true,
                                                   							    Object_Name__c='Journal_Entry__c',GL_Account_Reference_Value__c='GL_Account__c',Effective_Start_Date__c=dateTo.addDays(2),Effective_End_Date__c=dateTo.addDays(-1)
                                                                               );  
                                                                                                                                                                                                                                                                                                          
        validRuleList.add(RuleWithoutEffDateTo) ;
        validRuleList.add(RuleWithEffDate) ;
        
        invalidRuleList.add(RuleWithoutEffDate) ;
        invalidRuleList.add(RuleWithOverLappingEffDate) ;
        Boolean sawException = false;
        Boolean sawInvalidException = false;
        try
        {
           insert validRuleList;       
        	
        }
        catch(Exception ex)
        {
        	sawException=true;
        	system.assert(SawException==false,'Expecting no Exception'+Ex.getMessage());
        }
        Accounting_Rule__c RuleUniqueKeyCheck = [select id ,name,unique_key__c 
                                                       from accounting_rule__c
                                                      where id=:validRuleList[0].id];
        System.assertEquals(RuleUniqueKeyCheck.unique_key__c.countmatches('|'),AccountingRuleService.TOTAL_NUM_KEYS_WITHOUTALLOCATION,'Expecting 9 parameters  with 8 Seperators exclusive of Alloc and AllocTYpe');
        System.assertEquals(AccountingRuleService.NUM_KEYS_BEFORE_RULETYPE,6,'Expecting 6 parameters before Ruletype');

        /*try
        {
           insert RuleWithoutEffDate;       
        	
        }
        catch(Exception ex)
        {
        	system.assert(Ex.getMessage().contains('Please Enter Effective Date From'),'Expecting correct Exception');
        }
        try
        {
           insert RuleWithOverLappingEffDate;       
        	
        }
        catch(Exception ex)
        {
        	system.assert(Ex.getMessage().contains('with overlapping Date ranges.'),'Expecting correct Exception');
        }*/
        //system.assertEquals(sawException,false,'Expecting No Exception');
        
        Database.SaveResult[] ruleListResult = Database.insert(invalidRuleList, false);
        
        for(Database.SaveResult sr:ruleListResult)
        {
        	if(sr.isSuccess())
        	{
    	          system.assertEquals(sawInvalidException,true,'Expecting Exception');      		
        	}
        	else
        	{
        		for(Database.Error err : sr.getErrors())
        		{
        			sawInvalidException=false;
        			//TODO :Put flag for each exception and assert.Change text to label.
        			if((err.getMessage().contains(Label.Please_enter_effective_start_date) )
        			   || (err.getMessage().contains(Label.Overlapping_Effective_Date_Range) ) )
        			   {
        			   	 sawInvalidException=true;
        			   }
        			 else 
        			 {
        			 	system.assert(sawInvalidException==true,'UnExpected Exception'+err.getMessage());
        			 }
        			
        		}
        	}
        }                                          
    	 system.assertEquals(sawInvalidException,true,'Expecting Exception');
		 list<journal_entry_line__c> jeLineList = new list<journal_entry_line__c>(createJEs(fuel));
		 JournalEntryAccounting jea = new JournalEntryAccounting();
		 jea.execute(jeLineList); 
		 list<accounting_entry_line__c> AELsforJE= [select id,name,accounting_rule__c,accounting_entry__r.period__r.name from accounting_entry_line__c
		 											where journal_entry_line__c in :jeLineList and amount_CR__c !=0];
		 											
	     //system.assertEquals(AELsforJE[0],null,'Expecting AELS for the JE');
	     //list<task> exceptionje = [select id,description from task where whatid in :AELsforJE];
	     //system.assertEquals(exceptionje,null,'exception for AEs');
	     
         Test.stoptest();
		 system.assertEquals(AELsforJE[0].accounting_rule__c,RuleWithEffDate.id,'Expecting the expected rule to be used.');
		 RuleWithEffDate.Effective_Start_Date__c = system.now();
		 Boolean sawUpdateException = false;
		 try
		 {
		 	update RulewithEffDate;
		 }
		 catch(Exception ex)
		 {
		 	sawUpdateException=true;
		 	system.assert(ex.getMessage().contains(Label.Cannot_change_effective_dates_once_transactions_have_been_recorded),ex.getMessage());
		 }
		 system.assertEquals(sawUpdateException,true,'Expecting update exception');
		 
    	
    }
    public static list<journal_entry_line__c> createJEs(TestFuelQuery fuel)
    {
		List<Period__c> periodList = fuel.periodList;
		  	
    	Journal_Entry__c je1 = new Journal_Entry__c();
		je1.name = 'JE001';
		je1.Company__c = fuel.company.id;	
		je1.type__c = 'Manual';   
		je1.Transaction_Type__c = 'Manual';
		je1.Transaction_Date__c = System.now();  
		je1.Currency__c = fuel.company.Default_Transaction_Currency__c;
		insert je1;
		
		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = je1.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = fuel.cashGL.id;
		jeLine1.Subtransaction_Type__c = null;
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = je1.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = fuel.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = null;
	    jeLineList.add(jeLine2); 
		    
		 insert jeLineList;
		 
		 je1.finalized__c = true;
		 update je1;
		 
		 return jeLineList;

    } 
    public static list<supplier_invoice_line__c> createSI(testFuelQuery fuel,date TxnDate,string LineType)
    {
    	    Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();
    	    list<supplier_invoice_line__c> suppInvLineList = new list<supplier_invoice_line__c>();
    	    purchase_order__c purchaseOrder = [select id,name,purchase_order_value__c from purchase_order__c where id=:fuel.purchaseOrder.id];
    	    
            suppInv1.Company__c = fuel.company.id;
            suppInv1.Invoice_Type__c = 'Invoice';
            suppInv1.Date_Invoiced__c = TxnDate;
            suppInv1.Currency__c = fuel.company.Default_Transaction_Currency__c;
            suppInv1.Transaction_Date__c = TxnDate;
            suppInv1.Supplier__c = fuel.remittosupplier.id;
            suppInv1.Amount_Due__c = purchaseOrder.Purchase_Order_Value__c;
            suppInv1.Invoice_Amount__c = purchaseOrder.Purchase_Order_Value__c;
            suppInv1.Supplier_Invoice__c = 'SI -'+TxnDate+LineType;
            suppInv1.historical__c = false;
            system.assertNotEquals(purchaseOrder.Purchase_Order_Value__c, null);
            insert suppInv1;
                
            Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); 
            suppInvLine1.Supplier_Invoice__c = suppInv1.id;
            suppInvLine1.Invoice_Quantity__c = 10;
            suppInvLine1.Invoice_Quantity_to_Stock__c = 10;
            suppInvLine1.Unit_Price__c = 12; //KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price
            suppInvLine1.Item__c = fuel.itemlist[0].id;
            suppInvLine1.Purchase_Order__c = fuel.purchaseOrder.id;
            suppInvLine1.Purchase_Order_Line__c = fuel.purchaseOrderLines[0].id;
            suppInvLine1.Quantity_Received__c = 10;
            suppInvLine1.Unit_Price__c = 12; 
            suppInvLine1.subtransaction_type__c=null;
            suppInvLine1.line_type__c = LineType;           
            suppInvLineList.add(suppInvLine1);
        
            /*insert suppInvLineList;
            
            suppInv1.Status__c = 'Approved';
            suppInv1.finalized__c = true;           
            update suppInv1;     */
               
            return suppInvLineList;
    }
    static testmethod void testAEGenUsingEffDates()
    {
    	TestFuelQuery fuel = new TestFuelQuery();
		List<Period__c> periodList = fuel.periodList;
    	
    	Date EffStartDate = system.now().date();
    	Date EffEndDate  = EffStartDate.addMonths(10);
        Boolean sawEffRuleMissingException = false;
        //Boolean sawRuleMissingException = false;

    	list<accounting_rule__c> ruleList = new list<accounting_rule__c>();
    	Accounting_Rule__c SIRule1CR = new Accounting_Rule__c(name='CRRuleWithSI',rule_type__c='CR',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Invoice',subtransaction_type__c=null,line_type__c=null,GL_Account__c=fuel.expenseGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate,Effective_End_Date__c=EffEndDate
                                                          ); 
     	Accounting_Rule__c SIRule2DR = new Accounting_Rule__c(name='DRRuleWithSI',rule_type__c='DR',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Invoice',subtransaction_type__c=null,line_type__c=null,GL_Account__c=fuel.FGInventoryGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate,Effective_End_Date__c=EffEndDate
                                                           );
     	Accounting_Rule__c SIRule3CR = new Accounting_Rule__c(name='CRRuleWithSISTT',rule_type__c='CR',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Invoice',subtransaction_type__c=null,line_type__c='Expense',GL_Account__c=fuel.expenseGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate,Effective_End_Date__c=EffEndDate
                                                          ); 
     	Accounting_Rule__c SIRule4DR = new Accounting_Rule__c(name='DRRuleWithSISTT',rule_type__c='DR',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Invoice',subtransaction_type__c=null,line_type__c='Expense',GL_Account__c=fuel.FGInventoryGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate,Effective_End_Date__c=EffEndDate
                                                          );                                                           
        
        //KNDY-12704
        Accounting_Rule__c sinvacctRule912CR = new Accounting_Rule__c();
        sinvacctRule912CR.Object_Name__c = 'Supplier_Invoice__c';
        sinvacctRule912CR.Transaction__c = 'Supplier Invoice';
        sinvacctRule912CR.SubTransaction_Type__c = 'Goods - Purchase Order';
        sinvacctRule912CR.Rule_Type__c = 'CR';
        sinvacctRule912CR.Default_GL_Account__c = true;
        sinvacctRule912CR.GL_Account_Reference_Value__c = null;
        sinvacctRule912CR.GL_Account__c = fuel.expenseGL.Id;
        sinvacctRule912CR.Amount_Reference__c = 'Purchase_Price__c';
        sinvacctRule912CR.Effective_Start_Date__c = EffStartDate;
        sinvacctRule912CR.Accounting_Standard__c = fuel.accountingStandard.Id;
 
        Accounting_Rule__c sinvacctRule912DR = new Accounting_Rule__c();
        sinvacctRule912DR.Object_Name__c = 'Supplier_Invoice__c';
        sinvacctRule912DR.Transaction__c = 'Supplier Invoice';
        sinvacctRule912DR.SubTransaction_Type__c = 'Goods - Purchase Order';
        sinvacctRule912DR.Rule_Type__c = 'DR';
        sinvacctRule912DR.Default_GL_Account__c = true;
        sinvacctRule912DR.GL_Account_Reference_Value__c = null;
        sinvacctRule912DR.GL_Account__c = fuel.FGInventoryGL.Id;
        sinvacctRule912DR.Effective_Start_Date__c = EffStartDate;
        sinvacctRule912DR.Accounting_Standard__c = fuel.accountingStandard.Id;
        
        Accounting_Rule__c sinvacctRule912CRA = new Accounting_Rule__c();
        sinvacctRule912CRA.Object_Name__c = 'Supplier_Invoice__c';
        sinvacctRule912CRA.Transaction__c = 'Invoice';
        sinvacctRule912CRA.SubTransaction_Type__c = 'Goods - Purchase Order';
        sinvacctRule912CRA.Rule_Type__c = 'CR';
        sinvacctRule912CRA.Default_GL_Account__c = true;
        sinvacctRule912CRA.GL_Account_Reference_Value__c = null;
        sinvacctRule912CRA.GL_Account__c = fuel.expenseGL.Id;
        sinvacctRule912CRA.Amount_Reference__c = 'Purchase_Price__c';
        sinvacctRule912CRA.Effective_Start_Date__c = EffStartDate;
        sinvacctRule912CRA.Accounting_Standard__c = fuel.accountingStandard.Id;
 
        Accounting_Rule__c sinvacctRule912DRA = new Accounting_Rule__c();
        sinvacctRule912DRA.Object_Name__c = 'Supplier_Invoice__c';
        sinvacctRule912DRA.Transaction__c = 'Invoice';
        sinvacctRule912DRA.SubTransaction_Type__c = 'Goods - Purchase Order';
        sinvacctRule912DRA.Rule_Type__c = 'DR';
        sinvacctRule912DRA.Default_GL_Account__c = true;
        sinvacctRule912DRA.GL_Account_Reference_Value__c = null;
        sinvacctRule912DRA.GL_Account__c = fuel.FGInventoryGL.Id;
        sinvacctRule912DRA.Effective_Start_Date__c = EffStartDate;
        sinvacctRule912DRA.Accounting_Standard__c = fuel.accountingStandard.Id;
        
        ruleList.add(SIRule1CR);
        ruleList.add(SIRule2DR);
        ruleList.add(SIRule3CR);
        ruleList.add(SIRule4DR);        
        ruleList.add(sinvacctRule912CR);
        ruleList.add(sinvacctRule912DR);
        ruleList.add(sinvacctRule912CRA);
        ruleList.add(sinvacctRule912DRA);
        insert ruleList;
        
    	//SI with TD in Eff Date
      	//SI with same rule Def but TD outside Eff Date   	 	   	
    	//SI with same rule Def and TD on Eff date range boundary.  
    	//SI with diff rule def and outside Eff Date.  
    	//SI with no rules defined .  
    	
    	list<Supplier_Invoice_Line__c> SIlinesWithTDWithinEffDt     =  createSI(fuel,EffStartDate.addDays(1),null);
    	list<Supplier_Invoice_Line__c> SIlinesWithTDOutsideEffDt    =  createSI(fuel,EffEndDate.addDays(2),null);
    	list<Supplier_Invoice_Line__c> SIlinesWithTDOnEffDtBoundary =  createSI(fuel,EffStartDate,null);
    	list<Supplier_Invoice_Line__c> SIlinesWithNoRules           =  createSI(fuel,EffStartDate,'Misc');
    	list<Supplier_Invoice_Line__c> SIlinesWithLTTTDOutsideEffDt =  createSI(fuel,EffEndDate.addDays(2),'Expense');
    	
    	list<Supplier_Invoice_Line__c> AllSILs = new list<Supplier_Invoice_Line__c>();
    	AllSILs.addAll(SIlinesWithTDWithinEffDt);
    	AllSILs.addAll(SIlinesWithTDOutsideEffDt);
    	AllSILs.addAll(SIlinesWithTDOnEffDtBoundary);
      	AllSILs.addAll(SIlinesWithNoRules);
    	AllSILs.addAll(SIlinesWithLTTTDOutsideEffDt);
    	
		Test.startTest();
    	insert AllSILS;

    	//KNDY-12704 reset subtransaction type on SIL
    	// whose values were set by field update
    	//Valid SILines
    SIlinesWithTDWithinEffDt[0].SubTransaction_Type__c = 'Goods - Purchase Order';
    SIlinesWithTDOnEffDtBoundary[0].SubTransaction_Type__c = 'Goods - Purchase Order';
    	//Invalid SILines
    	SIlinesWithLTTTDOutsideEffDt[0].SubTransaction_Type__c = null;
    	SIlinesWithNoRules[0].SubTransaction_Type__c = null;
    	SIlinesWithTDOutsideEffDt[0].SubTransaction_Type__c = null;
    	
    	update ALLSILs;
		//99 queries here...
		system.debug(logginglevel.INFO, 'QUERIES BEFORE START:' + Limits.getQueries());

    	//list<supplier_invoice_line__c> silsmisc = [select id,subtransaction_type__c,line_type__c from supplier_invoice_line__c where id in :SIlinesWithLTTTDOutsideEffDt];
    	//system.assertEquals(silsmisc,null,silsmisc);
    	set<supplier_invoice__c> SIInScope = new set<Supplier_Invoice__c>();
    	for(supplier_invoice__c si : [select id,name,status__c,finalized__c,(select id,name from supplier_invoice_lines__r where id in :AllSILs) from supplier_invoice__c ])
    	{
    		si.status__c = 'Approved';
    		si.finalized__c = true;
    		SIInScope.add(si);
    	}
    	system.assertNotEquals(SIInScope.size(),0);
    	update new list<supplier_invoice__c>(SIInScope);
    	
      	list<Supplier_Invoice_Line__c> ValidSILs = new list<Supplier_Invoice_Line__c>();
      	ValidSILs.addAll(SIlinesWithTDWithinEffDt) ;
      	ValidSILs.addAll(SIlinesWithTDOnEffDtBoundary);

      	list<Supplier_Invoice_Line__c> InValidSILs = new list<Supplier_Invoice_Line__c>();      	
      	InvalidSILs.addAll(SIlinesWithTDOutsideEffDt);
      	InvalidSILs.addAll(SIlinesWithNoRules);
      	InvalidSILs.addAll(SIlinesWithLTTTDOutsideEffDt);
        SupplierInvoiceAccounting sia = new SupplierInvoiceAccounting();
        sia.execute(AllSILs) ; 	
        
        /*Debugging TT-STT-LT-EffDate Combo

        supplier_invoice__c si = [select id,name,transaction_date__c from supplier_invoice__c where  id = :validsils[0].supplier_invoice__c];
        Datetime td = si.transaction_date__c;        
        list<accounting_rule__c> rulesInScope = [select id,name,transaction__c,subtransaction_type__c,line_type__c,effective_start_date__c,effective_end_date__c
        										 from accounting_rule__c
        									    ];
       //system.assertEquals(rulesInScope,null,'debugging rules for TD--'+TD);
        									     
        list<accounting_entry_line__c> siLAEL = [ select id,name,subtransaction_type__c,line_type__c 
        														  from accounting_entry_line__c where supplier_invoice_line__c in :ValidSILs];
        list<accounting_entry__c> siAE = [select id,name,transaction_type__c from accounting_entry__c where supplier_invoice__c = :si.id];														  
        //system.assertEquals(AELsForSIWithinEffDate,null,'debugging AELs');
        system.assertEquals(rulesInScope[0].transaction__c,siAE[0].transaction_type__c);
        system.assertEquals(rulesInScope[0].subtransaction_type__c,siLAEL[0].subtransaction_type__c);
        system.assertEquals(rulesInScope[0].line_type__c,siLAEL[0].line_type__c);*/
 
        list<accounting_entry_line__c> AELsforSIL = [ select id,name,subtransaction_type__c,line_type__c 
        											  from accounting_entry_line__c where supplier_invoice_line__c in :ValidSILs];        
        list<task> exceptionListForValidSIs = [select id,description from task where whatid in :AELsforSIL];
        system.assertEquals(exceptionListForValidSIs.size(),0,'Expecting no AEL Exceptions'+exceptionListForValidSIs);
         
        list<accounting_entry_line__c> AELsForSIOutsideEffDate = [ select id,name,accounting_entry__r.transaction_type__c,subtransaction_type__c,line_type__c,error_message__c,supplier_invoice_line__r.supplier_invoice__c 
        														   from accounting_entry_line__c where supplier_invoice_line__c in :InValidSILs];
  
        list<task> exceptionListForInValidSIs = [select id,description from task where whatid in :AELsForSIOutsideEffDate];       
        system.assertNotEquals(exceptionListForInValidSIs.size(),0,'Expecting  AEL Exceptions');


		system.debug(logginglevel.INFO, 'QUERIES BEFORE STOP:' + Limits.getQueries());
        Test.stopTest();
        //system.assertEquals(exceptionListForInValidSIs,null,'Expecting  AEL Exceptions');
        
        //Exception task will be created with old missing rule message as we are not making no chg to exception framework call from AEL trigger.
        /*for(task exceptionTask:exceptionListForInValidSIs)
        {
        	if(exceptionTask.description.contains('Effective Accounting rule'))
        	{
        		sawEffRuleMissingException=true;
        	}
        }*/
          
        for(accounting_entry_line__c aelSI:AELsForSIOutsideEffDate)
        {
        	system.assertNotEquals(aelSI.error_message__c,null,aelSI);
        	if(aelSI.error_message__c.contains('Missing accounting rule'))
        	{
        		sawEffRuleMissingException=true;
        	}
        	/*else if(aelSI.error_message__c.contains('accounting rule could not be found.'))
        	{
        		sawRuleMissingException=true;
        		System.assertEquals(aelSI.Supplier_Invoice_Line__r.supplier_invoice__c,SIlinesWithNoRules[0].supplier_invoice__c,'Expecting this msg for only SI with no matching rules.');
        	}*/
        }      
    	system.assertEquals(sawEffRuleMissingException,true,'Expecting missing eff rule exception');
    	//system.assertEquals(sawRuleMissingException,true,'Expecting missing  rule exception');
    	//Customer Invoice with allocation rule 
    }
    static testmethod void testRulesFailingNAValidation(){
    	
    	TestfuelQuery fuel = new TestFuelQuery();
    	Boolean sawException,sawNoException;
    	DateTime EffStartDate = System.now();
    	//Create Existing DR/CR rules.
    	list<accounting_rule__c> ExistingDRCRList = new list<accounting_rule__c>();
    	ExistingDRCRList.add( new Accounting_Rule__c(name='CRRuleWithSI',rule_type__c='CR',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Supplier Invoice',subtransaction_type__c=null,line_type__c=null,GL_Account__c=fuel.expenseGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate,Effective_End_Date__c=EffStartDate.addhours(1)
                                                          )); 
     	ExistingDRCRList.add(new Accounting_Rule__c(name='DRRuleWithSI',rule_type__c='DR',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Supplier Invoice',subtransaction_type__c=null,line_type__c=null,GL_Account__c=fuel.FGInventoryGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate,Effective_End_Date__c=EffStartDate.addhours(1)
                                                           ));
        insert ExistingDRCRList;
        //Need to directly set the ExistingRulesForUniqueKey static list as the testdata is specific to this static context and visible in the existingrule query in getExistingRulesForUniqueKeySubstr() method. 
        AccountingRuleService.ExistingRulesForUniqueKey = [select id,name,Effective_End_Date__c,Effective_Start_Date__c,unique_key__c,rule_type__c from accounting_rule__c where id in :ExistingDRCRList];
                
     	Accounting_Rule__c SIRule1NA = new Accounting_Rule__c(name='SIRule1NA',rule_type__c='NA',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Supplier Invoice',subtransaction_type__c=null,line_type__c=null,GL_Account__c=fuel.expenseGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate                                                    
                                                           ); 
                                                           
        try{
       	 insert SIRule1NA;
        }
        catch(Exception ex){
          sawException = true;
          System.assert(ex.getMessage().contains(Label.NA_Rule_overlapping_with_Existing_DR_CR_Rule),'Expecting Validation error as DR/CR rules exist for effective dates.'+Ex.getmessage());
        }
        System.assertEquals(sawException,true,'Expecting Validation error as DR/CR rules exist for effective dates.');
        
        SIRule1NA.Effective_Start_Date__c = EffStartDate.addhours(2);
        SIRule1NA.Effective_End_Date__c   = SIRule1NA.Effective_Start_Date__c.addhours(1) ;
        
        sawException= false;
        try{
          insert SIRule1NA;        
        }
        catch(Exception ex){
        	sawException= true;
        	
        }
        System.assertEquals(sawException,false,'Expecting NO Validation error as NA rules have diff effectivity.');
        AccountingRuleService.ExistingRulesForUniqueKey.add([select id,name,Effective_Start_Date__c,Effective_End_Date__c,Unique_Key__c,Rule_Type__c from Accounting_Rule__c where id=:SIRule1NA.Id]);
        //Creating a new DR Rule which is same eff range as NA rule
     	Accounting_Rule__c SIRuleOverlapDR = new Accounting_Rule__c(name='OverlappingRule',rule_type__c='DR',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Supplier Invoice',subtransaction_type__c=null,line_type__c=null,GL_Account__c=fuel.FGInventoryGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate.addhours(2)
                                              );
        try{
          insert SIRuleOverlapDR;        
        }
        catch(Exception ex){
        	sawException= true;
        	System.assert(ex.getMessage().contains(Label.DR_CR_Rule_overlapping_with_existing_NA_Rule),'Expecting Validation error as NA rules exist for effective dates.'+Ex.getmessage());
        	
        }
        System.assertEquals(sawException,true,'Expecting  Validation error as DR rule is in same eff range.');     
                
        SIRuleOverlapDR.effective_start_date__c = EffStartDate.addhours(3);
         	
        sawException= false;
                
        try{
          insert SIRuleOverlapDR;        
        }
        catch(Exception ex){
        	sawException= true;
        }
        System.assertNotEquals(sawException,true,'Expecting  NO Validation error as DR rule is in same eff range.');                                             
    	
    }
    static testmethod void testRulesBoundaryPassingNAValidation(){
    	TestfuelQuery fuel = new TestFuelQuery();
    	Boolean sawException=false;
    	DateTime EffStartDate = System.now();
    	//Create DR CR NA Rule with Non-Overlapping Effective Dates but on boundary.
    	list<accounting_rule__c> ExistingDRCRList = new list<accounting_rule__c>();
    	ExistingDRCRList.add( new Accounting_Rule__c(name='ExistingCRRule',rule_type__c='CR',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Supplier Invoice',subtransaction_type__c=null,line_type__c=null,GL_Account__c=fuel.expenseGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate
                                                          )); 
     	ExistingDRCRList.add(new Accounting_Rule__c(name='ExistingNARule',rule_type__c='NA',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Supplier Invoice',subtransaction_type__c='Payment',line_type__c=null,GL_Account__c=fuel.FGInventoryGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate,Effective_End_Date__c=EffStartDate.addhours(1)
                                                           ));
        insert ExistingDRCRList;
        //Need to directly set the ExistingRulesForUniqueKey static list as the testdata is specific to this static context and visible in the existingrule query in getExistingRulesForUniqueKeySubstr() method. 
        AccountingRuleService.ExistingRulesForUniqueKey = [select id,name,Effective_End_Date__c,Effective_Start_Date__c,unique_key__c,rule_type__c from accounting_rule__c where id in :ExistingDRCRList];
    	
    	//Insert In one shot.
    	list<accounting_rule__c> newRulesOnExistingBoundary = new list<accounting_rule__c>();
    	newRulesOnExistingBoundary.add( new Accounting_Rule__c(name='newNARuleOnCRBoundary',rule_type__c='NA',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Supplier Invoice',subtransaction_type__c=null,line_type__c=null,GL_Account__c=fuel.expenseGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate.addhours(-1),Effective_End_Date__c=EffStartDate
                                                          )); 
     	newRulesOnExistingBoundary.add(new Accounting_Rule__c(name='newCRRuleOnNABoundary',rule_type__c='CR',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Supplier Invoice',subtransaction_type__c='Payment',line_type__c=null,GL_Account__c=fuel.FGInventoryGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate.addhours(1),Effective_End_Date__c=EffStartDate.addhours(1)
              
                                                         ));
        try{
         insert newRulesOnExistingBoundary;
        }
        catch(Exception ex){
        	sawException = true;
        	system.assertEquals(sawException,false,'Expecting no exception but got --'+ex.getmessage());
        }
        system.assertEquals(sawException,false,'Expecting no exception');
    }  

    static testmethod void testRuleBulkUpdateProfiling(){
    	TestfuelQuery fuel = new TestFuelQuery();
    	Boolean sawException=false;
    	Datetime EffStartDate = DateTime.newInstanceGMT(2015, 01, 01, 3, 3, 3);
    	list<accounting_rule__c> bulkRules = new list<accounting_rule__c>();

  	   system.debug('Current CPU time before DML--'+LIMITS.getCpuTime() + ' --Total Limt CPU Time-- '+LIMITS.getLimitCpuTime());
    	
    	for(integer i=0;i<201;i++){
    		
        	bulkRules.add( new Accounting_Rule__c(name='newNARuleOnCRBoundary',rule_type__c='DR',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Supplier Invoice',subtransaction_type__c=null,line_type__c=null,GL_Account__c=fuel.expenseGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=EffStartDate,Effective_End_Date__c=EffStartDate.addhours(5)
                                                          ));  		
            EffStartDate = EffStartDate.adddays(1);
    	}
    	try{
    	insert bulkRules;
    	}
    	catch(Exception ex){
         	sawException = true;
        	system.assertEquals(sawException,false,'Expecting no exception but got --'+ex.getmessage());   		
    	}
        system.debug('Current CPU time AFTER insert--'+LIMITS.getCpuTime() + ' --Total Limt CPU Time-- '+LIMITS.getLimitCpuTime());
    	
       	for(Accounting_Rule__c rule:bulkRules){
    		
			rule.rule_type__c = 'NA';
    	} 	
        system.debug('Current CPU time AFTER UPDATE--'+LIMITS.getCpuTime() + ' --Total Limt CPU Time-- '+LIMITS.getLimitCpuTime());
    	
    	try{
    	update bulkRules;
    	}
    	catch(Exception ex){
          	sawException = true;
        	system.assertEquals(sawException,false,'Expecting no exception but got --'+ex.getmessage());   	   		
    	}
    	
       system.assertEquals(sawException,false,'Expecting no exception');   	   		
       system.assert(LIMITS.getCpuTime() < LIMITS.getLimitCpuTime(),'Expecting CPU TIME to be within governor limits' + 'Current:'+ LIMITS.getCpuTime() +'Limit:'+ LIMITS.getLimitCpuTime());   	   		
   	
    
    	
    }
	static testmethod void testAccounting_SupressZeros_SI()  {
	
    	TestfuelQuery data = new TestFuelQuery();
       	Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();
        suppInv1.Company__c = data.company.id;
        suppInv1.Invoice_Type__c = 'Invoice';
        suppInv1.Date_Invoiced__c = System.now();
        suppInv1.Currency__c = data.company.Default_Transaction_Currency__c;
        suppInv1.Transaction_Date__c = system.now();
        suppInv1.Supplier__c = data.remittosupplier.id;
        suppInv1.Amount_Due__c = 0;
        suppInv1.Invoice_Amount__c =0;
        suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
        suppInv1.historical__c = false;
	
		insert suppInv1;
		
        Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); 
        suppInvLine1.Supplier_Invoice__c = suppInv1.id;
        suppInvLine1.Invoice_Quantity__c = 3;
        suppInvLine1.Invoice_Quantity_to_Stock__c = 8;
        suppInvLine1.Item__c = data.itemList[0].id;
        suppInvLine1.Quantity_Received__c = 4;
        suppInvLine1.Unit_Price__c = 0; 
        suppInvLine1.Line_Type__c = 'Item';
        
        insert suppInvLine1;
        suppInv1.finalized__c = true;
        update suppInv1;
        
        
		
		List<Accounting_Rule__c> SuppInvAcctRulesList = new List<Accounting_Rule__c>();
        Accounting_Rule__c sinvacctRule1New = new Accounting_Rule__c();
        sinvacctRule1New.Object_Name__c = 'Supplier_Invoice__c';
        sinvacctRule1New.Transaction__c = 'Invoice';
        sinvacctRule1New.SubTransaction_Type__c = 'Goods';
        sinvacctRule1New.Rule_Type__c = 'DR';
        sinvacctRule1New.Default_GL_Account__c = true;
        sinvacctRule1New.GL_Account_Reference_Value__c = null;
        sinvacctRule1New.GL_Account__c = data.FGInventoryGL.Id;
        sinvacctRule1New.Line_Type__c = 'Item';
        sinvacctRule1New.Company_Ledger__c = true;
        sinvacctRule1New.Effective_Start_Date__c= system.now().addmonths(-1);
        sinvacctRule1New.Accounting_Standard__c = data.accountingStandard.Id;
        SuppInvAcctRulesList.add(sinvacctRule1New);
                 
        Accounting_Rule__c sinvacctRule2New = new Accounting_Rule__c();
        sinvacctRule2New.Object_Name__c = 'Supplier_Invoice__c';
        sinvacctRule2New.Transaction__c = 'Invoice';
        sinvacctRule2New.SubTransaction_Type__c = 'Goods';
        sinvacctRule2New.Rule_Type__c = 'CR';
        sinvacctRule2New.Default_GL_Account__c = true;
        sinvacctRule2New.GL_Account_Reference_Value__c = null;
        sinvacctRule2New.GL_Account__c = data.FGInventoryGL.Id;
        sinvacctRule2New.Line_Type__c = 'Item';
        sinvacctRule2New.Company_Ledger__c = true;
        sinvacctRule2New.Effective_Start_Date__c= system.now().addmonths(-1);
        sinvacctRule2New.Accounting_Standard__c = data.accountingStandard.Id;
        SuppInvAcctRulesList.add(sinvacctRule2New);
                 
        insert SuppInvAcctRulesList;
	    SupplierInvoiceAccounting sia = new SupplierInvoiceAccounting();
		test.starttest();
        sia.execute(new list<Supplier_Invoice_Line__c> {suppInvLine1});
        
        
	    List<Accounting_Entry__c> acctEntry = [Select id, Name, Supplier_Invoice__c, Supplier__c,has_exceptions__c,status__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c, Accounting_Rule__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Supplier_Invoice__c =: suppInv1.id and status__c = 'Active') ];
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 2);
        system.assert(acctEntry[0].Accounting_Entry_Lines__r[0].Amount_CR__c == 0 );
        system.assert(acctEntry[0].Accounting_Entry_Lines__r[0].Amount_DR__c == 0 );
        system.assert(acctEntry[0].Accounting_Entry_Lines__r[1].Amount_CR__c == 0);
        system.assert(acctEntry[0].Accounting_Entry_Lines__r[1].Amount_DR__c == 0);
        String excMsg = '';
        try{
        	delete new Accounting_Rule__c(Id = acctEntry[0].Accounting_Entry_Lines__r[0].Accounting_Rule__c);
        }catch(Exception e){
        	excMsg = e.getMessage();
        }
        System.assert(excMsg.contains(Label.Cannot_delete_Accounting_Rule));
        AccountingRuleService.getTranscationTypeToObjectMap();
        AccountingRuleService accService = new AccountingRuleService();
        System.assert(accService.isRuleDefined(new List<String>{'Invoice'})); 
        System.assert(accService.isRuleDefined(new List<String>{'Supplier_Invoice__c'}, new List<String>{'Invoice'})); 
        System.assert(accService.objectHasRules('Supplier_Invoice__c')); 
        System.assert(AccountingRuleService.getAccountingRulesByTransaction('Supplier_Invoice__c', new List<String>{'Invoice'}).size() > 0); 
        AccountingRuleService.getRuleDefsForObject('Supplier_Invoice__c');
        sinvacctRule1New.Suppress_Zero_Amount_Lines__c = true;        
        sinvacctRule2New.Suppress_Zero_Amount_Lines__c = true; 
        update SuppInvAcctRulesList;
        sia.execute(new list<Supplier_Invoice_Line__c> {suppInvLine1});
		test.stopTest();
	    acctEntry = [Select id, Name, Supplier_Invoice__c, Supplier__c,has_exceptions__c,status__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Supplier_Invoice__c =: suppInv1.id  and status__c = 'Active')];
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 0);
               
	}
	static testmethod void testAccounting_SupressZeros_JE()  {
    	TestfuelQuery fuel = new TestFuelQuery();
    	Journal_Entry__c je1 = new Journal_Entry__c();
		je1.name = 'JE001';
		je1.Company__c = fuel.company.id;	
		je1.type__c = 'Manual';   
		je1.Transaction_Type__c = 'Manual';
		je1.Transaction_Date__c = System.now();  
		je1.Currency__c = fuel.company.Default_Transaction_Currency__c;
		insert je1;
		
		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = je1.id;
		jeLine1.Amount_CR__c = 0;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = fuel.cashGL.id;
		jeLine1.Subtransaction_Type__c = null;
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = je1.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 0;
		jeLine2.GL_Account__c = fuel.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = null;
	    jeLineList.add(jeLine2); 
		    
		test.starttest();
		insert jeLineList;
		je1.finalized__c = true;
		update je1;
		 
		List<Accounting_Rule__c> jenvacctRulesList = new List<Accounting_Rule__c>();
		Accounting_Rule__c jenvacctCR  = new Accounting_Rule__c(name='jenvacctCR',rule_type__c='CR',transaction__c='Manual',accounting_standard__c = fuel.accountingStandard.Id,
		                                      Object_Name__c='Journal_Entry__c',GL_Account_Reference_Value__c='GL_Account__c',Effective_Start_Date__c=system.now().addmonths(-1));    
		                                                                        
		Accounting_Rule__c jenvacctDR  = new Accounting_Rule__c(name='jenvacctCR',rule_type__c='DR',transaction__c='Manual',accounting_standard__c = fuel.accountingStandard.Id,
		                                      Object_Name__c='Journal_Entry__c',GL_Account_Reference_Value__c='GL_Account__c',Effective_Start_Date__c=system.now().addmonths(-1));    
		
		jenvacctRulesList.add(jenvacctCR);
		jenvacctRulesList.add(jenvacctDR);
    	boolean sawException = false;
    	try{
			insert jenvacctRulesList;
    	}
    	catch(Exception ex){
          	sawException = true;
    	}
    	
        system.assertEquals(sawException,true,'Expecting exception');
          	   		
		jenvacctCR.Suppress_Zero_Amount_Lines__c = true;
		jenvacctCR.Raise_Exceptions_for_Blank_Amounts__c = false;
		jenvacctDR.Suppress_Zero_Amount_Lines__c = true;
		jenvacctDR.Raise_Exceptions_for_Blank_Amounts__c = false;
		
		insert jenvacctRulesList;

		JournalEntryAccounting jea = new JournalEntryAccounting();
		jea.execute(jeLineList);
		test.stoptest(); 
	    list <Accounting_Entry__c> acctEntry = [Select id, Name, Supplier_Invoice__c, Supplier__c,has_exceptions__c,status__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (journal_entry__c =: je1.id  and status__c = 'Active')];
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 0);

	
	
	
	
	}
	static testmethod void testAccounting_SupressZeros_CI()  {
		test.starttest();
 		Customer_Invoice__c custInvoice1 = [select id, name,(select id, name,Customer_Invoice__c from Customer_Invoice_Lines__r) from Customer_Invoice__c limit 1];
		list<customer_invoice_line__c> ciLine1 = custInvoice1.customer_invoice_lines__r;    
		custInvoice1.finalized__c = true;
		update custInvoice1;
        CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
        cia.execute(ciLine1);
        
        List<Accounting_Entry_Line__c> aeLines = [SELECT Id, accounting_rule__c, customer_invoice_line__c, accounting_rule__r.allocation_type__c
        												FROM Accounting_Entry_Line__c
        												WHERE Accounting_Entry__r.Customer_Invoice__c = :custInvoice1.Id];
		
         list<id> ARIdList = new list<id>(); 	   		
		for(accounting_entry_line__c ael:aelines){
			ARIdList.add(ael.accounting_rule__c);
		}
	    list <Accounting_Entry__c> acctEntry = [Select id, Name, has_exceptions__c,status__c,transaction_type__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Customer_Invoice__c =: custInvoice1.id  and status__c = 'Active')];
	     list<task> tasks = [Select subject, description from task where whatid in:aeLines];
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 2);
        system.debug(logginglevel.error,'acctEntry' + acctEntry + ' tasks : ' + tasks + ' acctEntry lines: ' + acctEntry[0].Accounting_Entry_Lines__r);

	    list <Accounting_Rule__c> acctrules = [Select id, Name, Suppress_Zero_Amount_Lines__c
	                                            from Accounting_Rule__c 
	                                            where id in : ARIdList];

		test.stoptest();
		
		for(Accounting_Rule__c ar:acctrules){
			ar.Suppress_Zero_Amount_Lines__c = true;
		}
		update acctrules;
        cia.execute(ciLine1);
	 	acctEntry = [Select id, Name, has_exceptions__c,status__c,transaction_type__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Customer_Invoice__c =: custInvoice1.id  and status__c = 'Active')];
        system.debug(logginglevel.error,'acctEntry now ' + acctEntry + ' acctEntry lines: ' + acctEntry[0].Accounting_Entry_Lines__r);
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 0);
	
	
	
	}
	static testmethod void testAccounting_SupressZeros_IC()  {
 		Company__c thisCompany = [SELECT ID, Name FROM Company__c LIMIT 1];
        item__c item1 = [SELECT ID, Name, Stocking_UOM__c FROM item__c LIMIT 1];
        location__c loc = [SELECT ID, Name FROM location__c LIMIT 1];
        gl_account__c GRNIGL = [SELECT ID, Name FROM gl_account__c LIMIT 1];
        Accounting_Standard__c acctStd = [SELECT ID, Name FROM Accounting_Standard__c LIMIT 1];
        
        List<Period__c> periodList = [SELECT ID, Name, open__c FROM Period__c];
        item_cost__C itemcostTemp = [SELECT ID, Name,start_Date__c FROM item_cost__C LIMIT 1];
        item_cost__C itemcost1 = itemcostTemp.clone(false,true,false,false);
        itemcost1.status__c = 'Proposed' ; 
        itemcost1.Item__c = item1.id;
        itemcost1.Company__c = thisCompany.id;
        itemcost1.start_Date__c = system.now().addDays(-1);
        insert itemcost1;
         
        ItemService.allowItemCostUpdate = true;
        itemcost1.status__c = 'Approved' ; 
        itemcost1.Date_Approved__c = DateTime.now();
        itemcost1.On_hand_Revaluation__c = true; 
        update itemcost1;

        Inventory_Change__c ic = new Inventory_Change__c();
        ic.company__c = thisCompany.id;
        ic.item__c = item1.id;
        ic.type__c = 'Purchase Order Receipt';
        ic.count_quantity__c = 1;
        ic.transaction_date__c = system.now();
        
        insert ic;
	
        Inventory_Transaction__c it = new Inventory_Transaction__c();
        it.item__c = item1.Id;
        it.quantity__c = 1;
        it.quantity_Stocking_UOM__c =1;
        it.Packaging_UOM__c = item1.Stocking_UOM__c;
        it.Stocking_UOM__c = item1.Stocking_UOM__c;
        it.standard_cost__c = 0;
        it.transaction_date__c = system.now();
        it.type__c = 'Purchase Order Receipt';
        it.to_location__c = loc.Id;
        it.inventory_change__c = ic.Id;
        it.Subtransaction_Type__c = 'Purchase Order Receipt';
        it.Company__c = thisCompany.Id;
        
        insert it;
		test.starttest();
        ic.finalized__c = true;
		update ic;
        list<Accounting_Rule__c> icnvacctRuleList = new list<Accounting_Rule__c>();
        Accounting_Rule__c icnvacctRuleDR = new Accounting_Rule__c();
        icnvacctRuleDR.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleDR.Transaction__c = 'Purchase Order Receipt';
        icnvacctRuleDR.SubTransaction_Type__c = 'Purchase Order Receipt';
        icnvacctRuleDR.Rule_Type__c = 'DR';
        icnvacctRuleDR.Default_GL_Account__c = true;
        icnvacctRuleDR.GL_Account_Reference_Value__c = null;
        icnvacctRuleDR.Amount_Reference__c = 'standard_cost__c';
        icnvacctRuleDR.GL_Account__c = GRNIGL.id;            
        icnvacctRuleDR.Company_Ledger__c = true;           
        icnvacctRuleDR.Effective_Start_Date__c= system.now().addDays(-3);
       	icnvacctRuleDR.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleDR);
        
        Accounting_Rule__c icnvacctRuleCR = new Accounting_Rule__c();
        icnvacctRuleCR.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleCR.Transaction__c = 'Purchase Order Receipt';
        icnvacctRuleCR.SubTransaction_Type__c = 'Purchase Order Receipt';
        icnvacctRuleCR.Amount_Reference__c = 'standard_cost__c';
        icnvacctRuleCR.Rule_Type__c = 'CR';
        icnvacctRuleCR.Default_GL_Account__c = true;
        icnvacctRuleCR.GL_Account_Reference_Value__c = null;
        icnvacctRuleCR.GL_Account__c = GRNIGL.id;            
        icnvacctRuleCR.Company_Ledger__c = true;           
        icnvacctRuleCR.Effective_Start_Date__c= system.now().addDays(-3);
       	icnvacctRuleCR.Accounting_Standard__c = acctStd.Id; 
        icnvacctRuleList.add(icnvacctRuleCR);
        
        insert icnvacctRuleList;
        InventoryChangeAccounting ica = new InventoryChangeAccounting();
        
        ica.execute(new list<Inventory_Transaction__c> {it});
	 	list<Accounting_Entry__c> acctEntry = [Select id, Name, has_exceptions__c,status__c,transaction_type__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Inventory_change__c =: ic.id  and status__c = 'Active')];
        system.debug(logginglevel.error,'acctEntry ' + acctEntry + ' acctEntry lines: ' + acctEntry[0].Accounting_Entry_Lines__r );
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 2);
			icnvacctRuleDR.Suppress_Zero_Amount_Lines__c = true;
			icnvacctRuleCR.Suppress_Zero_Amount_Lines__c = true;
	    update icnvacctRuleList;
        ica.execute(new list<Inventory_Transaction__c> {it});
		test.stoptest();
	 	acctEntry = [Select id, Name, has_exceptions__c,status__c,transaction_type__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Inventory_change__c =: ic.id  and status__c = 'Active')];
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 0);
        system.debug(logginglevel.error,'acctEntry now ' + acctEntry + ' acctEntry lines: ' + acctEntry[0].Accounting_Entry_Lines__r );
	}

	
	static testmethod void testAccounting_RaiseExceptions_SI()  {
	
    	TestfuelQuery data = new TestFuelQuery();
       	Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();
        suppInv1.Company__c = data.company.id;
        suppInv1.Invoice_Type__c = 'Invoice';
        suppInv1.Date_Invoiced__c = System.now();
        suppInv1.Currency__c = data.company.Default_Transaction_Currency__c;
        suppInv1.Transaction_Date__c = system.now();
        suppInv1.Supplier__c = data.remittosupplier.id;
        suppInv1.Amount_Due__c = 0;
        suppInv1.Invoice_Amount__c = 0;
        suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
        suppInv1.historical__c = false;
	
		insert suppInv1;
		
        Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); 
        suppInvLine1.Supplier_Invoice__c = suppInv1.id;
        suppInvLine1.Invoice_Quantity__c = 3;
        suppInvLine1.Invoice_Quantity_to_Stock__c = 8;
        suppInvLine1.Item__c = data.itemList[0].id;
        suppInvLine1.Quantity_Received__c = 4;
        suppInvLine1.Unit_Price__c = 0; 
        suppInvLine1.Line_Type__c = 'Item';
        
        insert suppInvLine1;
        suppInv1.finalized__c = true;
        update suppInv1;
        
        
		
		List<Accounting_Rule__c> SuppInvAcctRulesList = new List<Accounting_Rule__c>();
        Accounting_Rule__c sinvacctRule1New = new Accounting_Rule__c();
        sinvacctRule1New.Object_Name__c = 'Supplier_Invoice__c';
        sinvacctRule1New.Transaction__c = 'Invoice';
        sinvacctRule1New.SubTransaction_Type__c = 'Goods';
        sinvacctRule1New.Rule_Type__c = 'DR';
        sinvacctRule1New.Default_GL_Account__c = true;
        sinvacctRule1New.GL_Account_Reference_Value__c = null;
        sinvacctRule1New.GL_Account__c = data.FGInventoryGL.Id;
        sinvacctRule1New.Line_Type__c = 'Item';
        sinvacctRule1New.Company_Ledger__c = true;
        sinvacctRule1New.Effective_Start_Date__c= system.now().addmonths(-1);
        sinvacctRule1New.Accounting_Standard__c = data.accountingStandard.Id;
        SuppInvAcctRulesList.add(sinvacctRule1New);
                 
        Accounting_Rule__c sinvacctRule2New = new Accounting_Rule__c();
        sinvacctRule2New.Object_Name__c = 'Supplier_Invoice__c';
        sinvacctRule2New.Transaction__c = 'Invoice';
        sinvacctRule2New.SubTransaction_Type__c = 'Goods';
        sinvacctRule2New.Rule_Type__c = 'CR';
        sinvacctRule2New.Default_GL_Account__c = true;
        sinvacctRule2New.GL_Account_Reference_Value__c = null;
        sinvacctRule2New.GL_Account__c = data.FGInventoryGL.Id;
        sinvacctRule2New.Line_Type__c = 'Item';
        sinvacctRule2New.Company_Ledger__c = true;
        sinvacctRule2New.Effective_Start_Date__c= system.now().addmonths(-1);
        sinvacctRule2New.Accounting_Standard__c = data.accountingStandard.Id;
        SuppInvAcctRulesList.add(sinvacctRule2New);
                 
        insert SuppInvAcctRulesList;
	    SupplierInvoiceAccounting sia = new SupplierInvoiceAccounting();
		test.starttest();
        sia.execute(new list<Supplier_Invoice_Line__c> {suppInvLine1});
        
        
	    List<Accounting_Entry__c> acctEntry = [Select id, Name, Supplier_Invoice__c, Supplier__c,has_exceptions__c,status__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Supplier_Invoice__c =: suppInv1.id and status__c = 'Active') ];
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 2);
        system.assert(acctEntry[0].Accounting_Entry_Lines__r[0].Amount_CR__c == 0 );
        system.assert(acctEntry[0].Accounting_Entry_Lines__r[0].Amount_DR__c == 0 );
        system.assert(acctEntry[0].Accounting_Entry_Lines__r[1].Amount_CR__c == 0);
        system.assert(acctEntry[0].Accounting_Entry_Lines__r[1].Amount_DR__c == 0);
        
        sinvacctRule1New.Raise_Exceptions_for_Blank_Amounts__c = true;        
        sinvacctRule2New.Raise_Exceptions_for_Blank_Amounts__c = true; 
		//system.assert(1==2,'queries: ' + limits.getqueries());
        update SuppInvAcctRulesList;
        sia.execute(new list<Supplier_Invoice_Line__c> {suppInvLine1});
	    acctEntry = [Select id, Name, Supplier_Invoice__c, Supplier__c,has_exceptions__c,status__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Supplier_Invoice__c =: suppInv1.id  and status__c = 'Active')];
        system.assert(acctEntry[0].has_exceptions__c == false);
		test.stopTest();
               
	}
	
	static testmethod void SupplierPaymentAcctRuleTest()  { 
	    
	    gl_account__c GRNIGL = [SELECT ID, Name FROM gl_account__c LIMIT 1];
        AccountingRuleExt ext = new AccountingRuleExt( new Apexpages.Standardcontroller(new Accounting_Rule__c()));
        Accounting_Standard__c acctStd = new Accounting_Standard__c(name = 'US GAAP');
        insert acctStd;
        List<Accounting_Rule__c> SPAcctRulesList = new List<Accounting_Rule__c>();
        Accounting_Rule__c spacctRule1 = new Accounting_Rule__c(); 
        spacctRule1.Accounting_Standard__c = acctStd.Id;           
        spacctRule1.Object_Name__c = 'Supplier_Payment__c';
        spacctRule1.Transaction__c = 'Supplier Payment';
        spacctRule1.SubTransaction_Type__c = 'Credit Memo';
        spacctRule1.Line_Type__c = null;
        spacctRule1.Rule_Type__c = 'CR';
        spacctRule1.Default_GL_Account__c = true;
        spacctRule1.Company_Ledger__c = true;
        spacctRule1.GL_Account__c = GRNIGL.id;
        spacctRule1.Amount_Reference__c = null;     
        spacctRule1.Effective_start_date__c= system.now().date().addMonths(-5);                         
        SPAcctRulesList.add(spacctRule1);
        
        Accounting_Rule__c spacctRule2 = new Accounting_Rule__c();
        spacctRule2.Accounting_Standard__c = acctStd.Id;
        spacctRule2.Object_Name__c = 'Supplier_Payment__c';
        spacctRule2.Transaction__c = 'Supplier Payment';
        spacctRule2.SubTransaction_Type__c = 'Credit Memo';
        spacctRule2.Line_Type__c = null;
        spacctRule2.Rule_Type__c = 'DR';
        spacctRule2.Default_GL_Account__c = true;
        spacctRule2.GL_Account__c = GRNIGL.id;
        spacctRule2.Amount_Reference__c = null;        
        spacctRule2.Effective_start_date__c= system.now().date().addMonths(-5);                         
        SPAcctRulesList.add(spacctRule2);  
        
        insert SPAcctRulesList;
    
        ext = new AccountingRuleExt( new Apexpages.Standardcontroller( spacctRule1 ));
        system.assert( ext.thewrap.exceptionMsg == '' , ' expected no errors ' ); 
        
        ext = new AccountingRuleExt( new Apexpages.Standardcontroller( spacctRule2 ));
        system.assert( ext.thewrap.exceptionMsg == '' , ' expected one errors ' ); 
        
        
        Apexpages.Standardsetcontroller setc = new Apexpages.StandardSetController(
            new List<Accounting_Rule__c>{spacctRule1,spacctRule2} );
            
        setc.setSelected(new List<Accounting_Rule__c>{spacctRule1,spacctRule2});
        
        ext = new AccountingRuleExt( new Apexpages.Standardsetcontroller( 
            new List<Accounting_Rule__c>{spacctRule1,spacctRule2} ) );
                       
        system.assert( ext.errcount == 0);
    }
    
	static testmethod void testAccounting_RaiseExceptions_CI()  {
		test.starttest();
 		Customer_Invoice__c custInvoice1 = [select id, name,(select id, name,Customer_Invoice__c from Customer_Invoice_Lines__r) from Customer_Invoice__c limit 1];
		list<customer_invoice_line__c> ciLine1 = custInvoice1.customer_invoice_lines__r;    
		custInvoice1.finalized__c = true;
		update custInvoice1;
        CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
        cia.execute(ciLine1);
        
        List<Accounting_Entry_Line__c> aeLines = [SELECT Id, accounting_rule__c, customer_invoice_line__c, accounting_rule__r.allocation_type__c
        												FROM Accounting_Entry_Line__c
        												WHERE Accounting_Entry__r.Customer_Invoice__c = :custInvoice1.Id];
		
         list<id> ARIdList = new list<id>(); 	   		
		for(accounting_entry_line__c ael:aelines){
			ARIdList.add(ael.accounting_rule__c);
		}
	    list <Accounting_Entry__c> acctEntry = [Select id, Name, has_exceptions__c,status__c,transaction_type__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Customer_Invoice__c =: custInvoice1.id  and status__c = 'Active')];
	     list<task> tasks = [Select subject, description from task where whatid in:aeLines];
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 2);
        system.debug(logginglevel.error,'acctEntry' + acctEntry + ' tasks : ' + tasks + ' acctEntry lines: ' + acctEntry[0].Accounting_Entry_Lines__r);

	    list <Accounting_Rule__c> acctrules = [Select id, Name, Suppress_Zero_Amount_Lines__c, amount_reference__c
	                                            from Accounting_Rule__c 
	                                            where id in : ARIdList];

		test.stoptest();
		
		for(Accounting_Rule__c ar:acctrules){
			ar.Raise_Exceptions_for_Blank_Amounts__c = true;
			ar.amount_reference__c = 'Sales_Tax__c';
		}
		update acctrules;
        cia.execute(ciLine1);
	 	acctEntry = [Select id, Name, has_exceptions__c,status__c,transaction_type__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Customer_Invoice__c =: custInvoice1.id  and status__c = 'Active')];
        system.debug(logginglevel.error,'acctEntry now ' + acctEntry + ' acctEntry lines: ' + acctEntry[0].Accounting_Entry_Lines__r);
        system.assert(acctEntry[0].has_exceptions__c == true);
	
	
	
	}
	
	static testmethod void testAccounting_RaiseExceptions_Neg_CI()  {
		test.starttest();
 		Customer_Invoice__c custInvoice1 = [select id, name,(select id, name,Customer_Invoice__c from Customer_Invoice_Lines__r) from Customer_Invoice__c limit 1];
		list<customer_invoice_line__c> ciLine1 = custInvoice1.customer_invoice_lines__r;    
		custInvoice1.finalized__c = true;
		update custInvoice1;
        CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
        cia.execute(ciLine1);
        
        List<Accounting_Entry_Line__c> aeLines = [SELECT Id, accounting_rule__c, customer_invoice_line__c, accounting_rule__r.allocation_type__c
        												FROM Accounting_Entry_Line__c
        												WHERE Accounting_Entry__r.Customer_Invoice__c = :custInvoice1.Id];
		
         list<id> ARIdList = new list<id>(); 	   		
		for(accounting_entry_line__c ael:aelines){
			ARIdList.add(ael.accounting_rule__c);
		}
	    list <Accounting_Entry__c> acctEntry = [Select id, Name, has_exceptions__c,status__c,transaction_type__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Customer_Invoice__c =: custInvoice1.id  and status__c = 'Active')];
	     list<task> tasks = [Select subject, description from task where whatid in:aeLines];
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 2);
        system.debug(logginglevel.error,'acctEntry' + acctEntry + ' tasks : ' + tasks + ' acctEntry lines: ' + acctEntry[0].Accounting_Entry_Lines__r);

	    list <Accounting_Rule__c> acctrules = [Select id, Name, Suppress_Zero_Amount_Lines__c, amount_reference__c
	                                            from Accounting_Rule__c 
	                                            where id in : ARIdList];
	
		test.stoptest();
	
		for(Accounting_Rule__c ar:acctrules){
			ar.Suppress_Zero_Amount_Lines__c = true;
			ar.Raise_Exceptions_for_Blank_Amounts__c = false;
			ar.amount_reference__c = 'Sales_Tax__c';
		}
		update acctrules;
        cia.execute(ciLine1);
	 	acctEntry = [Select id, Name, has_exceptions__c,status__c,transaction_type__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Customer_Invoice__c =: custInvoice1.id  and status__c = 'Active')];
        system.debug(logginglevel.error,'acctEntry now ' + acctEntry + ' acctEntry lines: ' + acctEntry[0].Accounting_Entry_Lines__r);
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 0);
	
	}
	static testmethod void testAccounting_RaiseExceptions_IC()  {
 		Company__c thisCompany = [SELECT ID, Name FROM Company__c LIMIT 1];
        item__c item1 = [SELECT ID, Name, Stocking_UOM__c FROM item__c LIMIT 1];
        location__c loc = [SELECT ID, Name FROM location__c LIMIT 1];
        gl_account__c GRNIGL = [SELECT ID, Name FROM gl_account__c LIMIT 1];
        Accounting_Standard__c acctStd = [SELECT ID, Name FROM Accounting_Standard__c LIMIT 1];
        
        List<Period__c> periodList = [SELECT ID, Name, open__c FROM Period__c];
        item_cost__C itemcostTemp = [SELECT ID, Name,start_Date__c FROM item_cost__C LIMIT 1];
        item_cost__C itemcost1 = itemcostTemp.clone(false,true,false,false);
        itemcost1.status__c = 'Proposed' ; 
        itemcost1.Item__c = item1.id;
        itemcost1.Company__c = thisCompany.id;
        itemcost1.start_Date__c = system.now().addDays(-1);
        insert itemcost1;
         
        ItemService.allowItemCostUpdate = true;
        itemcost1.status__c = 'Approved' ; 
        itemcost1.Date_Approved__c = DateTime.now();
        itemcost1.On_hand_Revaluation__c = true; 
        update itemcost1;

        Inventory_Change__c ic = new Inventory_Change__c();
        ic.company__c = thisCompany.id;
        ic.item__c = item1.id;
        ic.type__c = 'Purchase Order Receipt';
        ic.count_quantity__c = 1;
        ic.transaction_date__c = system.now();
        
        insert ic;
	
        Inventory_Transaction__c it = new Inventory_Transaction__c();
        it.item__c = item1.Id;
        it.quantity__c = 1;
        it.quantity_Stocking_UOM__c =1;
        it.Packaging_UOM__c = item1.Stocking_UOM__c;
        it.Stocking_UOM__c = item1.Stocking_UOM__c;
        it.standard_cost__c = 0;
        it.transaction_date__c = system.now();
        it.type__c = 'Purchase Order Receipt';
        it.to_location__c = loc.Id;
        it.inventory_change__c = ic.Id;
        it.Subtransaction_Type__c = 'Purchase Order Receipt';
        it.Company__c = thisCompany.Id;
        
        insert it;
		test.starttest();
        ic.finalized__c = true;
		update ic;
        list<Accounting_Rule__c> icnvacctRuleList = new list<Accounting_Rule__c>();
        Accounting_Rule__c icnvacctRuleDR = new Accounting_Rule__c();
        icnvacctRuleDR.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleDR.Transaction__c = 'Purchase Order Receipt';
        icnvacctRuleDR.SubTransaction_Type__c = 'Purchase Order Receipt';
        icnvacctRuleDR.Rule_Type__c = 'DR';
        icnvacctRuleDR.Default_GL_Account__c = true;
        icnvacctRuleDR.GL_Account_Reference_Value__c = null;
        icnvacctRuleDR.Amount_Reference__c = 'standard_cost__c';
        icnvacctRuleDR.GL_Account__c = GRNIGL.id;            
        icnvacctRuleDR.Company_Ledger__c = true;           
        icnvacctRuleDR.Effective_Start_Date__c= system.now().addDays(-3);
       	icnvacctRuleDR.Accounting_Standard__c = acctStd.Id;
        icnvacctRuleList.add(icnvacctRuleDR);
        
        Accounting_Rule__c icnvacctRuleCR = new Accounting_Rule__c();
        icnvacctRuleCR.Object_Name__c = 'Inventory_Change__c';
        icnvacctRuleCR.Transaction__c = 'Purchase Order Receipt';
        icnvacctRuleCR.SubTransaction_Type__c = 'Purchase Order Receipt';
        icnvacctRuleCR.Amount_Reference__c = 'standard_cost__c';
        icnvacctRuleCR.Rule_Type__c = 'CR';
        icnvacctRuleCR.Default_GL_Account__c = true;
        icnvacctRuleCR.GL_Account_Reference_Value__c = null;
        icnvacctRuleCR.GL_Account__c = GRNIGL.id;            
        icnvacctRuleCR.Company_Ledger__c = true;           
        icnvacctRuleCR.Effective_Start_Date__c= system.now().addDays(-3);
       	icnvacctRuleCR.Accounting_Standard__c = acctStd.Id; 
        icnvacctRuleList.add(icnvacctRuleCR);
        
        insert icnvacctRuleList;
        InventoryChangeAccounting ica = new InventoryChangeAccounting();
        
        ica.execute(new list<Inventory_Transaction__c> {it});
	 	list<Accounting_Entry__c> acctEntry = [Select id, Name, has_exceptions__c,status__c,transaction_type__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Inventory_change__c =: ic.id  and status__c = 'Active')];
        system.debug(logginglevel.error,'acctEntry ' + acctEntry + ' acctEntry lines: ' + acctEntry[0].Accounting_Entry_Lines__r );
        system.assert(acctEntry[0].Accounting_Entry_Lines__r.size() == 2);
		icnvacctRuleDR.Raise_Exceptions_for_Blank_Amounts__c = true;
		icnvacctRuleCR.Raise_Exceptions_for_Blank_Amounts__c = true;
	    update icnvacctRuleList;
        ica.execute(new list<Inventory_Transaction__c> {it});
		test.stoptest();
	 	acctEntry = [Select id, Name, has_exceptions__c,status__c,transaction_type__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Inventory_change__c =: ic.id  and status__c = 'Active')];
        system.assert(acctEntry[0].has_exceptions__c == false);
        system.debug(logginglevel.error,'acctEntry now ' + acctEntry + ' acctEntry lines: ' + acctEntry[0].Accounting_Entry_Lines__r );
	}

    static testmethod void testRulesWithLongAmountReference(){
    	TestfuelQuery fuel = new TestFuelQuery();
		Accounting_Rule__c newAR = new Accounting_Rule__c(name='CRRuleWithSI',rule_type__c='CR',accounting_standard__c = fuel.accountingStandard.Id,
                                                           Object_Name__c='Supplier_Invoice__c',Transaction__c = 'Supplier Invoice',subtransaction_type__c=null,line_type__c=null,GL_Account__c=fuel.expenseGL.Id,default_GL_Account__c=true,
                                                           Effective_Start_Date__c=system.now().addmonths(-1),Effective_End_Date__c=system.now().addmonths(1)
                                                          ); 
        for(integer i=0;i<50;i++){
        	newAR.Amount_Reference__c = newAR.Amount_Reference__c + string.valueof(i);
        }  
    	
    	insert newAR;
    	Accounting_Rule__c ARnow = [select id from Accounting_Rule__c where id =: newAR.id];
    	system.assert(ARnow != null, 'AR inserted without any errors');
    }
}