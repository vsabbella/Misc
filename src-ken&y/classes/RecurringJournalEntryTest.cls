@isTest
private class RecurringJournalEntryTest {

    public class SampleData{
        
        public TestFuel fuel = new TestFuel();
        public Period__c p, startPeriod, EndPeriod;
        public Recurring_Template__c rt1, rt2, rt3, rt4, rt5, rt6, rt7;
        public List<Recurring_Template__c> rtList;
        public SampleData(){
        	List<Accounting_Rule__c> acctRulesList = fuel.AccountingRuleList;
            updatePeriod();
            updateRT();
        }
        
        public void updatePeriod(){ 
            List<Period__c> periods = fuel.periodList;
            List<Period__c> periodList = fuel.periodList;
	    	for(Period__c thisPeriod: periodList){
	    		thisPeriod.Open__c = true;
	    	}
	    	update periodList;
        }
        
        public void updateRT(){
        	set<Id> companyIds = new set<Id>();
        	companyIds.add(fuel.company.id);
        	Map<Id, List<Period__c>> mCompanyPeriods = PeriodService.getAllPeriodsMap(companyIds);
        	Datetime currDate = system.now();
    		Period__c currentPeriod = RecurringJournalEntryService.returnTransactionPeriod(mCompanyPeriods, fuel.company.id,currDate);
    		currentPeriod.JE_Cutoff__c = currentPeriod.JE_Cutoff__c.addDays(1);
    		update currentPeriod;
    		
    		Period__c priorPeriod, priorPriorPeriod;
    		if(currentPeriod != null && currentPeriod.prior_period__c != null){
    			priorPeriod = RecurringJournalEntryService.returnTransactionPeriod(mCompanyPeriods, fuel.company.id,currentPeriod.Period_End__c.addDays(-1));
    			if(priorPeriod != null){
    				priorPeriod.JE_Cutoff__c = currentPeriod.JE_Cutoff__c.addDays(1);
    				update priorPeriod;
    			}
    		}
    		if (priorPeriod != null) {
	    		if(priorPeriod.prior_period__c != null){
	    			priorPriorPeriod = RecurringJournalEntryService.returnTransactionPeriod(mCompanyPeriods, fuel.company.id,priorPeriod.Period_End__c.addDays(-1));
	    			if(priorPriorPeriod != null){
	    				priorPriorPeriod.JE_Cutoff__c = currentPeriod.JE_Cutoff__c.addDays(1);
	    				update priorPriorPeriod;
	    			}
	    		}
    		}
    		
        	rtList = new List<Recurring_Template__c>();
            rt1 = new Recurring_Template__c();
            rt1.Company__c = fuel.company.id;
            rt1.Currency__c = TestFuel.currencyUSD.id;
            rt1.Type__c = 'Journal Entry';
            rt1.status__c = 'Draft';
            rt1.frequency__c = 'Daily';
            rt1.recurring_transaction_start_date__c = currentPeriod.period_start__c;
            rt1.start_period__c = priorPeriod != null ? priorPeriod.id : currentPeriod.id;
            rt1.end_period__c = currentPeriod.id;
            rt1.template_end_date__c = system.now();//rt1.recurring_transaction_start_date__c.addDays(1);
            rtList.add(rt1);
            
            rt2 = new Recurring_Template__c();
            rt2.Company__c = fuel.company.id;
            rt2.Currency__c = TestFuel.currencyUSD.id;
            rt2.Type__c = 'Journal Entry';
            rt2.status__c = 'Draft';
            rt2.frequency__c = 'Weekly';
            rt2.recurring_transaction_start_date__c = currentPeriod.period_start__c;
            rt2.start_period__c =  priorPeriod != null ? priorPeriod.id : currentPeriod.id;
            rt2.end_period__c = currentPeriod.id;
            rtList.add(rt2);
            
            rt3 = new Recurring_Template__c();
            rt3.Company__c = fuel.company.id;
            rt3.Currency__c = TestFuel.currencyUSD.id;
            rt3.Type__c = 'Journal Entry';
            rt3.status__c = 'Draft';
            rt3.frequency__c = 'Bi Weekly';
            rt3.recurring_transaction_start_date__c = currentPeriod.period_start__c;
            rt3.start_period__c =  priorPeriod != null ? priorPeriod.id : currentPeriod.id;
            rt3.end_period__c = currentPeriod.id;
            rtList.add(rt3);
            
            rt4 = new Recurring_Template__c();
            rt4.Company__c = fuel.company.id;
            rt4.Currency__c = TestFuel.currencyUSD.id;
            rt4.Type__c = 'Journal Entry';
            rt4.status__c = 'Draft';
            rt4.frequency__c = 'Monthly';
            rt4.recurring_transaction_start_date__c = currentPeriod.period_start__c;
            rt4.start_period__c = priorPriorPeriod != null ? priorPriorPeriod.id : currentPeriod.id;
            rt4.end_period__c = currentPeriod.id;
            rtList.add(rt4);
            
            rt5 = new Recurring_Template__c();
            rt5.Company__c = fuel.company.id;
            rt5.Currency__c = TestFuel.currencyUSD.id;
            rt5.Type__c = 'Journal Entry';
            rt5.status__c = 'Draft';
            rt5.frequency__c = 'Beginning of Period';
            rt5.recurring_transaction_start_date__c = currentPeriod.period_start__c;
            rt5.start_period__c =currentPeriod.id;
            rt5.end_period__c = currentPeriod.id;
            rtList.add(rt5);
            
            /*rt6 = new Recurring_Template__c();
            rt6.Company__c = fuel.company.id;
            rt6.Currency__c = TestFuel.currencyUSD.id;
            rt6.Type__c = 'Journal Entry';
            rt6.status__c = 'Draft';
            rt6.frequency__c = 'Middle of Period';
            rt6.recurring_transaction_start_date__c = currentPeriod.period_start__c;
            rt6.start_period__c = currentPeriod.id;
            rt6.end_period__c = currentPeriod.id;
            rtList.add(rt6);*/
            
            rt7 = new Recurring_Template__c();
            rt7.Company__c = fuel.company.id;
            rt7.Currency__c = TestFuel.currencyUSD.id;
            rt7.Type__c = 'Journal Entry';
            rt7.status__c = 'Draft';
            rt7.frequency__c = 'Quarterly';
            rt7.recurring_transaction_start_date__c = currentPeriod.period_start__c;
            rt7.start_period__c = priorPriorPeriod != null ? priorPriorPeriod.id : currentPeriod.id;
            rt7.end_period__c = currentPeriod.id;
            rtList.add(rt7);
            
            insert rtList;
            
            List<Recurring_template_Line__c> rtLineList = new List<Recurring_Template_Line__c>();
            Recurring_template_Line__c rtLine1 = new Recurring_Template_Line__c();
            rtLine1.recurring_template__c = rt1.id;
            rtLine1.Amount_CR__c = 10;
            rtLine1.Amount_DR__c = 0;
            rtLine1.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine1);
            
            Recurring_template_Line__c rtLine2 = new Recurring_Template_Line__c();
            rtLine2.recurring_template__c = rt1.id;
            rtLine2.Amount_DR__c = 10;
            rtLine2.Amount_CR__c = 0;
            rtLine2.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine2);
            
            Recurring_template_Line__c rtLine3 = new Recurring_Template_Line__c();
            rtLine3.recurring_template__c = rt2.id;
            rtLine3.Amount_CR__c = 10;
            rtLine3.Amount_DR__c = 0;
            rtLine3.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine3);
            
            Recurring_template_Line__c rtLine4 = new Recurring_Template_Line__c();
            rtLine4.recurring_template__c = rt2.id;
            rtLine4.Amount_DR__c = 10;
            rtLine4.Amount_CR__c = 0;
            rtLine4.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine4);
            
            Recurring_template_Line__c rtLine5 = new Recurring_Template_Line__c();
            rtLine5.recurring_template__c = rt3.id;
            rtLine5.Amount_CR__c = 10;
            rtLine5.Amount_DR__c = 0;
            rtLine5.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine5);
            
            Recurring_template_Line__c rtLine6 = new Recurring_Template_Line__c();
            rtLine6.recurring_template__c = rt3.id;
            rtLine6.Amount_DR__c = 10;
            rtLine6.Amount_CR__c = 0;
            rtLine6.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine6);
            
            Recurring_template_Line__c rtLine7 = new Recurring_Template_Line__c();
            rtLine7.recurring_template__c = rt4.id;
            rtLine7.Amount_CR__c = 10;
            rtLine7.Amount_DR__c = 0;
            rtLine7.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine7);
            
            Recurring_template_Line__c rtLine8 = new Recurring_Template_Line__c();
            rtLine8.recurring_template__c = rt4.id;
            rtLine8.Amount_DR__c = 10;
            rtLine8.Amount_CR__c = 0;
            rtLine8.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine8);
            
            Recurring_template_Line__c rtLine9 = new Recurring_Template_Line__c();
            rtLine9.recurring_template__c = rt5.id;
            rtLine9.Amount_CR__c = 10;
            rtLine9.Amount_DR__c = 0;
            rtLine9.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine9);
            
            Recurring_template_Line__c rtLine10 = new Recurring_Template_Line__c();
            rtLine10.recurring_template__c = rt5.id;
            rtLine10.Amount_DR__c = 10;
            rtLine10.Amount_CR__c = 0;
            rtLine10.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine10);
            
            /*Recurring_template_Line__c rtLine11 = new Recurring_Template_Line__c();
            rtLine11.recurring_template__c = rt6.id;
            rtLine11.Amount_CR__c = 10;
            rtLine11.Amount_DR__c = 0;
            rtLine11.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine11);
            
            Recurring_template_Line__c rtLine12 = new Recurring_Template_Line__c();
            rtLine12.recurring_template__c = rt6.id;
            rtLine12.Amount_DR__c = 10;
            rtLine12.Amount_CR__c = 0;
            rtLine12.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine12);*/
            
            Recurring_template_Line__c rtLine13 = new Recurring_Template_Line__c();
            rtLine13.recurring_template__c = rt7.id;
            rtLine13.Amount_CR__c = 10;
            rtLine13.Amount_DR__c = 0;
            rtLine13.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine13);
            
            Recurring_template_Line__c rtLine14 = new Recurring_Template_Line__c();
            rtLine14.recurring_template__c = rt7.id;
            rtLine14.Amount_DR__c = 10;
            rtLine14.Amount_CR__c = 0;
            rtLine14.GL_Account__c = fuel.CashGL.id;
            rtLineList.add(rtLine14);
            
            insert rtLineList;
            
            for(Recurring_Template__c thisRT: rtList){
            	thisRT.status__c = 'Active';
            }
            update rtList;
            
        }
    }
    
    public static testMethod void testBatch(){
        
        SampleData sd = new SampleData();
        //Testfuel fuel = new TestFuel();
        
        test.startTest();
            RecurringJournalEntryBatch batch = new RecurringJournalEntryBatch(new set<Id> {sd.fuel.company.Id});
            batch.currDate = system.now().addSeconds(1);
            database.executebatch(batch);
        test.stopTest();
        
        List<Recurring_Template__c> rtList = [Select id, Name, Frequency__c,
        							(select id, Name from journal_entries__r)
        							from Recurring_Template__c
        							where id in :sd.rtList Order by id];
                            
        system.assert(rtList != null,'rtList is not expected to be null');
        system.assert(rtList.size() > 0,'rtList is expected to have elements');
                           
        for(Integer i=0;i< rtList.size(); i++ ){
        	system.assertNotEquals(0,rtList[i].journal_entries__r.size(),'i:'+i+' rtList[i]:'+rtList[i]);
        }
        boolean sawException = false;
        String exMsg;
        try{
        	delete rtList[0];
        } catch(Exception e){
        	sawException = true;
        	exMsg = e.getMessage();
        }
        system.assertEquals(true,sawException,'exMsg:'+exMsg);
        sawException = false;
        exMsg = '';
        try{
        	delete rtList[0].Journal_Entries__r[0];
        }catch(Exception e){
        	sawException = true;
        	exMsg = e.getMessage();
        }
        system.assertEquals(true,sawException,'exMsg:'+exMsg);
        sawException = false;
        exMsg = '';
        
        Recurring_Template__c rt = [Select id, Name, Status__c from Recurring_template__c where id = :sd.rt1.id];
        system.assert(rt.status__c.equals('Closed'),'Expected to see the status as Closed');
        try{
        	rt.status__c = 'Active';
        	update rt;
        }catch (Exception e){
        	sawException = true;
        	exMsg = e.getMessage();
    }
        system.assertEquals(true,sawException,'Expected to see exception while changing the closed status to active : exMsg:'+exMsg);
    }
    
    public class SampleDataforTrigger{
    	TestFuel fuel = new testFuel();
    	Company__c myComp = new Company__c();       
    	List<Period__c> periodList = fuel.periodList;
    	{
    	for(Period__c thisPeriod: periodList){
    		thisPeriod.Open__c = true;
    	}
    	update periodList;
    	}
    	
    	
    	Datetime currDate;
    	{
    	if(currDate == null){
    		currDate = system.now();
    	}
    	}
    	set<Id> companyIds = new set<Id>();
    	{
    	companyIds.add(fuel.company.id);
    	}
    	Map<Id, List<Period__c>> mCompanyPeriods = PeriodService.getAllPeriodsMap(companyIds);
    	Period__c currentPeriod = RecurringJournalEntryService.returnTransactionPeriod(mCompanyPeriods, fuel.company.id,currDate);
    	// create RT and test if the data is defaulted as expected and throws errors when necessary
    	Recurring_Template__c rt;
    	{
    	rt = new Recurring_Template__c();
    	rt.type__c = 'Journal Entry';
    	rt.Company__c = fuel.company.id;
    	rt.frequency__c = 'Daily';
    	rt.status__c = 'Draft';
    	rt.start_period__c = currentPeriod.id;
    	rt.end_period__c = currentPeriod.id;
    	rt.description__c = 'Rent';
    	rt.recurring_transaction_start_date__c = currDate;
		
		insert rt;
    	}
    }
    
    public static testMethod void testTrigger(){
    	SampleDataforTrigger sdt = new SampleDataforTrigger();
		
		Recurring_Template__c rt = [Select id, Name, Company__c, Frequency__c, status__c, start_period__c, end_period__c, 
				description__c, recurring_transaction_start_date__c, template_end_date__c, Currency__c, type__c
				from Recurring_Template__c
				where id = :sdt.rt.id];
				
		system.assert(rt != null,'Expected to insert the Recurring Template'+rt);
		
		
		List<Recurring_Template_Line__c> rtLineList = new List<Recurring_Template_Line__c>();
		
		Recurring_Template_Line__c rtLine1 = new Recurring_Template_Line__c();
		rtLine1.Amount_DR__c = 10;
		rtLine1.GL_Account__c = sdt.fuel.CashGL.id;
		rtLine1.Recurring_Template__c = sdt.rt.id;
		rtLineList.add(rtLine1);
		Recurring_Template_Line__c rtLine2 = new Recurring_Template_Line__c();
		rtLine2.Amount_CR__c = 10;
		rtLine2.GL_Account__c = sdt.fuel.receivablesGL.id;
		rtLine2.Recurring_Template__c = sdt.rt.id;
		rtLineList.add(rtLine2);
	
        Recurring_template_Line__c rtLine15 = new Recurring_Template_Line__c();
        rtLine15.recurring_template__c = sdt.rt.id;
        rtLine15.Amount_DR__c = 10;
        rtLine15.Amount_CR__c = 0;
        rtLine15.GL_Account__c = sdt.fuel.CashGL.id;
		rtLineList.add(rtLine15);
            
 		insert rtLineList;
 
          	List<Task> exceptionList = [select Id
										from Task
										WHERE WhatId =: sdt.rt.id and Status != 'Closed'];
									 
			system.assert(exceptionList.size() != 0,'exceptionList'+exceptionList);
  		          
            
		
		system.assert(rtLineList.size() == 3,'Expected 3 lines to be inserted for the recurring template'+rtLineList);
		boolean sawException = false;
        String exMsg;
		try{
			rt.template_end_date__c = rt.recurring_transaction_start_date__c.addseconds(-1) ;
			update rt;
		}catch(Exception e){
			sawException = true;
        	exMsg = e.getMessage();
        }
        system.assertEquals(true,sawException,'Expected to see exception while setting the template end date before the start date : exMsg:'+exMsg);
        sawException = false;
        exMsg = '';
		try{
			rt.template_end_date__c = sdt.rt.template_end_date__c.addSeconds(1);
			update rt;
		}catch(Exception e){
			sawException = true;
        	exMsg = e.getMessage();
        }
        system.assertEquals(true,sawException,'Expected to see exception while setting the template end date beyond the end period : exMsg:'+exMsg+'---rt:'+rt);
    }
   
   	static testMethod void testExtension() {
        SampleDataforTrigger sdt = new SampleDataforTrigger();
        
     	Recurring_Template__c rt = sdt.rt;
        test.startTest();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(rt);
        RecurringTemplateLinesAddManageExt ext = new RecurringTemplateLinesAddManageExt(con);
        system.assertEquals(ext.disableAction, false, 'This recurring transaction should be editable');
        system.assert(rt != null,'Recurring Template not expected to be null'+rt);
        
        List<Recurring_Template_Line__c> rtLineList = new List<Recurring_Template_Line__c>();
		
		Recurring_Template_Line__c rtLine1 = new Recurring_Template_Line__c();
		rtLine1.Amount_DR__c = 10;
		rtLine1.GL_Account__c = sdt.fuel.CashGL.id;
		rtLine1.Recurring_Template__c = sdt.rt.id;
		rtLineList.add(rtLine1);
		Recurring_Template_Line__c rtLine2 = new Recurring_Template_Line__c();
		rtLine2.Amount_CR__c = 10;
		rtLine2.GL_Account__c = sdt.fuel.receivablesGL.id;
		rtLine2.Recurring_Template__c = sdt.rt.id;
		rtLineList.add(rtLine2);
		
		insert rtLineList;
        
        rt.status__c = 'Active';
        update rt;
        
        ext.validateRecord();
        system.assertEquals(ext.disableAction, true, 'This recurring transaction should not be editable');
        
        test.stopTest();
    }
    
    static testMethod void testIncrementalJE() {
    	TestFuel fuel = new TestFuel();
    	
    	Configuration__c cutoffsConfig = new Configuration__c();
        cutoffsConfig.Name = 'EnableCutoffs';
        cutoffsConfig.Value__c = 'Yes';
        insert cutoffsConfig;
        
    	RecurringJournalEntryService RJES = new RecurringJournalEntryService();
    	
    	List<Period__c> periodList = new List<Period__c>();	
    	// create a period with PS = system.now()-2 PE = system.now()-1, PCOFF = system.now();
    	// create a period with PS = system.now()-1 PE = system.now(), PCOFF = system.now();
    	Integer year = system.now().year();
    	Datetime currentDatetime = system.now();
    	Datetime ps1 = currentDatetime.addDays(-2);
    	Datetime pe1 = ps1.addDays(1);
    	system.debug(logginglevel.info,'ps1:'+ps1+'--- pe1:'+pe1+'---currentDatetime'+currentDatetime);
    	
    	Period__c iPeriod = new Period__c();
	    iPeriod.Name = 'P1';
	    iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
	    iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
	    iPeriod.Period_Start__c = ps1;
	    iPeriod.Period_End__c = pe1;
	    iPeriod.Period_Number__c = 1;
	    iPeriod.Quarter_Number__c = 1;
	    
	    iPeriod.Fiscal_Year__c = String.valueOf(year);
	    iPeriod.Company__c = fuel.company.Id;
	    iPeriod.Adjustment_Period__c = false;
	    iPeriod.Closed__c = false;
	    iPeriod.Open__c = true;
	    iPeriod.Fiscal__c = true;
	    iPeriod.Corporate__c = false;
	    iPeriod.Tax__c = false;
	    iPeriod.Permanently_Closed__c = false;
	    iPeriod.Adjustment_Period__c = false;
	    
	    iPeriod.AP_Subledger_Cutoff__c = iPeriod.Period_End__c;
	    iPeriod.AR_Subledger_Cutoff__c = iPeriod.Period_End__c;
	    iPeriod.Shipment_Subledger_Cutoff__c = iPeriod.Period_End__c;
	    iPeriod.Receiving_Subledger_Cutoff__c = iPeriod.Period_End__c;
	    iPeriod.FA_Subledger_Cutoff__c = iPeriod.Period_End__c;
	    iPeriod.Inventory_Subledger_Cutoff__c = iPeriod.Period_End__c;
	    iPeriod.JE_Cutoff__c = system.now().addDays(1);
	    system.debug(logginglevel.info,'iPeriod:'+iPeriod);
	    periodList.add(iPeriod);
    
    	Period__c jPeriod = new Period__c();
	    jPeriod.Name = 'P2';
	    jPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
	    jPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
	    jPeriod.Period_Start__c = pe1;
	    jPeriod.Period_End__c = jPeriod.Period_Start__c.addDays(1);
	    jPeriod.Period_Number__c = 2;
	    jPeriod.Quarter_Number__c = 1;
	    
	    jPeriod.Fiscal_Year__c = String.valueOf(year);
	    jPeriod.Company__c = fuel.company.Id;
	    jPeriod.Adjustment_Period__c = false;
	    jPeriod.Closed__c = false;
	    jPeriod.Open__c = true;
	    jPeriod.Fiscal__c = true;
	    jPeriod.Corporate__c = false;
	    jPeriod.Tax__c = false;
	    jPeriod.Permanently_Closed__c = false;
	    jPeriod.Adjustment_Period__c = false;
	    
	    jPeriod.AP_Subledger_Cutoff__c = jPeriod.Period_End__c;
	    jPeriod.AR_Subledger_Cutoff__c = jPeriod.Period_End__c;
	    jPeriod.Shipment_Subledger_Cutoff__c = jPeriod.Period_End__c;
	    jPeriod.Receiving_Subledger_Cutoff__c = jPeriod.Period_End__c;
	    jPeriod.FA_Subledger_Cutoff__c = jPeriod.Period_End__c;
	    jPeriod.Inventory_Subledger_Cutoff__c = jPeriod.Period_End__c;
	    jPeriod.JE_Cutoff__c = system.now().addDays(1);
	    system.debug(logginglevel.info,'jPeriod:'+jPeriod);
	    periodList.add(jPeriod);
		Fiscal_Year__c fy = new Fiscal_Year__c();
		fy.company__c = fuel.company.Id;
		fy.fiscal_year_start_date__c = periodList[0].period_start__c;
		fy.fiscal_year_end_date__c = periodList[periodList.size()-1].period_end__c.addMonths(3);
		
		insert fy;

    	for(Period__c p : periodList){
			p.fiscalyear__c = fy.Id;
    	}
	    insert periodList;
	    system.debug(logginglevel.info,'periodList:'+periodList+'----periodList size:'+periodList.size());
	    
    	// create a RT with SP = system.now()-2 and EP = system.now()  and frequency = 'Beginning of Period'
    	List<Recurring_Template__c> rtList = new List<Recurring_Template__c>();
    	Recurring_Template__c rt5 = new Recurring_Template__c();
        rt5.Company__c = fuel.company.id;
        rt5.Currency__c = TestFuel.currencyUSD.id;
        rt5.Type__c = 'Journal Entry';
        rt5.status__c = 'Draft';
        rt5.frequency__c = 'Beginning of Period';
        rt5.recurring_transaction_start_date__c = iPeriod.period_start__c;
        rt5.template_end_date__c = jperiod.period_end__c;
        rt5.start_period__c =iPeriod.id;
        rt5.end_period__c = jPeriod.id;
        rtList.add(rt5);
        insert rtList;    
        
        List<Recurring_template_Line__c> rtLineList = new List<Recurring_template_Line__c>();
        Recurring_template_Line__c rtLine9 = new Recurring_Template_Line__c();
        rtLine9.recurring_template__c = rt5.id;
        rtLine9.Amount_CR__c = 10;
        rtLine9.Amount_DR__c = 0;
        rtLine9.GL_Account__c = fuel.CashGL.id;
        rtLineList.add(rtLine9);
        
        Recurring_template_Line__c rtLine10 = new Recurring_Template_Line__c();
        rtLine10.recurring_template__c = rt5.id;
        rtLine10.Amount_DR__c = 10;
        rtLine10.Amount_CR__c = 0;
        rtLine10.GL_Account__c = fuel.CashGL.id;
        rtLineList.add(rtLine10);
        
        insert rtLineList;
        
        rt5.status__c = 'Active';
        update rt5;
        system.debug(logginglevel.info,'rt5:'+rt5);
        
        test.startTest();
        //Call createIncrementalJEs(List<Recurring_Template__c> rtList, Datetime currDate) with currDate = system.now()-1
    	//check if 1 JE is created
        Datetime currDate = system.now().addDays(-1).addSeconds(-10);
        //system.debug(logginglevel.info,'currDate :'+currDate);
        RJES.createIncrementalJEs(rtList, currDate);
        
        List<Journal_Entry__c> jeList = [Select id, Name, type__c, Transaction_Date__c, finalized_date__c, recurring_template__c from Journal_entry__c where recurring_template__c = :rt5.id];
       	//system.debug(logginglevel.info, 'jeList:'+jeList);
       	system.assert(jeList != null,'jeList:'+jeList);
       	system.assert(jeList.size() == 1,'jeList:'+jeList);
       	
       	//Call createIncrementalJEs(List<Recurring_Template__c> rtList, Datetime currDate) with currDate = system.now()
    	//check if 2 JEs are created
       	currDate = system.now();
        system.debug(logginglevel.info,'currDate:'+currDate);
        RJES.createIncrementalJEs(rtList, currDate);
        
        jeList = [Select id, Name, type__c, Transaction_Date__c, finalized_date__c, recurring_template__c from Journal_entry__c where recurring_template__c = :rt5.id];
       	system.debug(logginglevel.info, 'jeList:'+jeList);
       	system.assert(jeList != null,'jeList:'+jeList);
       	system.assert(jeList.size() == 2,'jeList:'+jeList);
    	test.stopTest();
    }
    
}