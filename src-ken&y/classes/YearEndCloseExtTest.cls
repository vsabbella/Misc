@isTest
public with sharing class YearEndCloseExtTest {
	@testSetup static void JournalEntries() {
        TestFuel fuel = new TestFuel();
        Datetime currentDate = system.now();
        Segment_Validation__c sv1, sv2;
        List<Segment_Validation__c> svList = new List<Segment_Validation__c>();{
        sv1 = new Segment_Validation__c();
        sv1.segment_1__c = '*';
        sv1.segment_2__c = '*';
        sv1.active__c = true;
        svList.add(sv1);
        insert svList;
        } 
            
        
        Fiscal_Year__c fy = new Fiscal_Year__c();{
        	fy.Name = 'My Year';
			fy.company__c = fuel.company.Id;
			fy.fiscal_year_start_date__c = currentDate.addDays(-30);
			fy.fiscal_year_end_date__c = currentDate.addDays(+30);
			
			insert fy;
        }
        
        Period__c zeroPeriod = new Period__c();{
	    	Integer year = system.now().year();
	        zeroPeriod.Name = 'P1';
	        zeroPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
	        zeroPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
	        zeroPeriod.Type__c = 'Period 13';
	        zeroPeriod.Period_Number__c = 2;
	        zeroPeriod.Quarter_Number__c = 1;
	        zeroPeriod.Company__c = fuel.company.Id;
	        zeroPeriod.fiscalYear__c = fy.id;
            zeroPeriod.Open__c = 1 >= system.now().month();
	        insert zeroPeriod;
        }
	        
        List<Accounting_Rule__c> AccountingRuleList = fuel.AccountingRuleList;
        
        Period__c myPeriod;
        {
        	myPeriod = new Period__c();
            myPeriod.Name = 'Period1';
            myPeriod.Period_Start__c = system.now().addDays(-10);
            myPeriod.Period_End__c = fy.fiscal_year_end_date__c;
            myPeriod.Open__c = true;
            myPeriod.Period_Number__c = 1;
            myPeriod.Quarter_Number__c = 1;
            myPeriod.type__c = 'Fiscal';
            myPeriod.Company__c = fuel.company.id;
            myPeriod.fiscalYear__c = fy.Id;
            insert myPeriod;
            
        }
        
        
        List<Journal_Entry_Line__c> jeLineList;
        List<Journal_Entry__c> JEList = new List<Journal_Entry__c>(); {
 		    list<GL_Type__c> gltypelist = new list<GL_Type__c>();
  		    list<GL_Account__c> glAccountlist = new list<GL_Account__c>();
 		    GL_Type__c revenue = new GL_Type__c();
    	    revenue.Name  = 'Revenue';
			revenue.Normal_Balance__c  = 'Credit';
			revenue.Accounting_Type__c  = 'Revenue';
			revenue.Statement_Type__c  = 'Income Statement';
			revenue.Account_Range_From__c = '40000';
			revenue.Account_Range_To__c ='49999';
	    	gltypelist.add(revenue);
 		
			GL_Type__c operatingExpense = new GL_Type__c();
			operatingExpense.Name  = 'Other Operating Expense';
			operatingExpense.Normal_Balance__c  = 'Debit';
			operatingExpense.Accounting_Type__c  = 'Operating Expenses';
			operatingExpense.Statement_Type__c  = 'Income Statement';
			operatingExpense.Account_Range_From__c = '60000';
			operatingExpense.Account_Range_To__c ='79999';
	    	gltypelist.add(operatingExpense);

			GL_Type__c currentAssets = new GL_Type__c();
			currentAssets.Name  = 'Current Assets';
    		currentAssets.Normal_Balance__c  = 'Debit';
    		currentAssets.Accounting_Type__c  = 'Assets';
    		currentAssets.Statement_Type__c  = 'Balance Sheet';
    		currentAssets.Account_Range_From__c = '10000';
    		currentAssets.Account_Range_To__c ='14999';
 	    	gltypelist.add(currentAssets);

			GL_Type__c equity = new GL_Type__c();
			equity.Name  = 'Equity';
	    	equity.Normal_Balance__c  = 'Credit';
	    	equity.Accounting_Type__c  = 'Equity';
	    	equity.Statement_Type__c  = 'Balance Sheet';
	    	equity.Account_Range_From__c = '30000';
	    	equity.Account_Range_To__c ='39999';
 	    	gltypelist.add(equity);
 	    	
    		insert gltypelist;

			GL_Account__c expenseGL = new GL_Account__c();
			expenseGL.Name = '65000 - Office Expense';
			expenseGL.GL_Account_Number__c = '65000';
			expenseGL.GL_Account_Name__c = 'Office Expense';
			expenseGL.active__c = true;
			expenseGL.Report_Section__c = 'Current Assets';  
			expenseGL.Normal_Balance__c = 'Debit';
			expenseGL.Statement_Type__c = 'Income Statement';
			expenseGL.Report_Section_Grouping__c = 'Assets';
			expenseGL.Cash_Flow_Report_Section_Grouping__c = 'Operating Cash Flow';
			expenseGL.non_cash__c = true;
			expenseGL.GL_Account_Unique__c = expenseGL.Name;
			expenseGL.GL_type__c = operatingExpense.id; 
 	    	glAccountlist.add(expenseGL);
			
			GL_Account__c revenueGL = new GL_Account__c();
			revenueGL.Name = '42000 - Revenue';
			revenueGL.GL_Account_Number__c = '42000';
			revenueGL.GL_Account_Name__c = 'Revenue';
			revenueGL.active__c = true;
			revenueGL.Report_Section__c = 'Current Assets';  
			revenueGL.Normal_Balance__c = 'Credit';
			revenueGL.Statement_Type__c = 'Income Statement';
			revenueGL.Report_Section_Grouping__c = 'Assets';
			revenueGL.Cash_Flow_Report_Section_Grouping__c = 'Operating Cash Flow';
			revenueGL.non_cash__c = true;
			revenueGL.GL_Account_Unique__c = revenueGL.Name;
			revenueGL.GL_type__c = revenue.id;
 	    	glAccountlist.add(revenueGL);
				
			GL_Account__c cashGL = new GL_Account__c();
			cashGL.Name = '12000 - Cash';
			cashGL.GL_Account_Number__c = '12000';
			cashGL.GL_Account_Name__c = 'Cash';
			cashGL.active__c = true;
			cashGL.Report_Section__c = 'Current Assets';  
			cashGL.Normal_Balance__c = 'Debit';
			cashGL.Statement_Type__c = 'Balance Sheet';
			cashGL.Report_Section_Grouping__c = 'Assets';
			cashGL.Cash_Flow_Report_Section_Grouping__c = 'Operating Cash Flow';
			cashGL.non_cash__c = true;
			cashGL.GL_Account_Unique__c = cashGL.Name;
			cashGL.GL_Type__c = currentAssets.id;
 	    	glAccountlist.add(cashGL);
 	    	
			GL_Account__c retainedEarningsGL = new GL_Account__c();
			retainedEarningsGL.Name = '39000 - Retained Earnings';
			retainedEarningsGL.GL_Account_Number__c = '39000';
			retainedEarningsGL.GL_Account_Name__c = 'Retained Earnings';
			retainedEarningsGL.active__c = true;
			retainedEarningsGL.Type__c = 'Equity';
			retainedEarningsGL.Report_Section__c = 'Current Assets';  
			retainedEarningsGL.Normal_Balance__c = 'Debit';
			retainedEarningsGL.Statement_Type__c = 'Balance Sheet';
			retainedEarningsGL.Report_Section_Grouping__c = 'Assets';
			retainedEarningsGL.Cash_Flow_Report_Section_Grouping__c = 'Operating Cash Flow';
			retainedEarningsGL.non_cash__c = true;
			retainedEarningsGL.GL_Account_Unique__c = retainedEarningsGL.Name;
			retainedEarningsGL.GL_type__c = equity.id;
 	    	glAccountlist.add(retainedEarningsGL);
			
			insert glAccountlist ;

	        Journal_Entry__c je1 = new Journal_Entry__c();
	        je1.name = 'JE001';
	        je1.Company__c = fuel.company.id;    
	        je1.type__c = 'Manual';   
		    je1.Transaction_Date__c = fy.fiscal_year_end_date__c.addSeconds(-1);  
		    je1.gl_date_time__c = je1.Transaction_Date__c;  
		    je1.posting_Date__c = je1.Transaction_Date__c;  
	        je1.Transaction_Currency__c = 'USD';
	        JEList.add(je1);
	        
			Journal_Entry__c je2 = new Journal_Entry__c();
			je2.name = 'JE001';
		    je2.Company__c = fuel.company.id;	
		    je2.type__c = 'Year End Adjustment';   
		    je2.Transaction_Type__c = 'Year End Adjustment';
		    je1.Transaction_Date__c = fy.fiscal_year_end_date__c.addSeconds(-1);  
		    je2.gl_date_time__c = je2.Transaction_Date__c;  
		    je2.posting_Date__c = je2.Transaction_Date__c;  
			je2.Currency__c = TestFuel.currencyUSD.id;
			je2.period__c = Zeroperiod.id;
	        JEList.add(je2);
			
	        insert JEList;    
	        
	        jeLineList = new List<Journal_Entry_Line__c>();
	        
	        Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	        jeLine1.Journal_Entry__c = JEList[0].id;
	        jeLine1.Amount_CR__c = 500;
	        jeLine1.Amount_DR__c = 0;
	        jeLine1.GL_Account__c = cashGL.id;
	        jeLineList.add(jeLine1); 
	        
	        Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	        jeLine2.Journal_Entry__c = JEList[0].id;
	        jeLine2.Amount_CR__c = 0;
	        jeLine2.Amount_DR__c = 200;
	        jeLine2.GL_Account__c = revenueGL.id;
	        jeLineList.add(jeLine2); 
	        
	        Journal_Entry_Line__c jeLine3 = new Journal_Entry_Line__c(); 
	        jeLine3.Journal_Entry__c = JEList[0].id;
	        jeLine3.Amount_CR__c = 0;
	        jeLine3.Amount_DR__c = 300;
	        jeLine3.GL_Account__c = expenseGL.id;
	        jeLineList.add(jeLine3); 
	    
		    Journal_Entry_Line__c jeLine11 = new Journal_Entry_Line__c(); 
		    jeLine11.Journal_Entry__c = JEList[1].id;
			jeLine11.Amount_CR__c = 5;
			jeLine11.Amount_DR__c = 0;
			jeLine11.GL_Account__c = revenueGL.id;
			//jeLine11.Subtransaction_Type__c = 'Write Off';
		    jeLineList.add(jeLine11); 
		    
		    Journal_Entry_Line__c jeLine22 = new Journal_Entry_Line__c(); 
		    jeLine22.Journal_Entry__c = JEList[1].id;
			jeLine22.Amount_CR__c = 0;
			jeLine22.Amount_DR__c = 10;
			jeLine22.GL_Account__c = expenseGL.id;
			//jeLine22.Subtransaction_Type__c = 'Write Off';
		    jeLineList.add(jeLine22); 

	        insert jeLineList;
	        
	        JEList[0].finalized__c = true;
	        update JEList;
	        system.assert(fuel.AccountingRuleList.size() > 0);
	        JournalEntryAccounting jea = new JournalEntryAccounting();
            jea.execute(jeLineList);
            
            Journal_Entry__c jeData = [Select id, Name, Period__c, Type__c, Status__c, 
                                    (Select id, Status__c, Period__c, has_exceptions__c from Accounting_Entries__r) 
                                    from Journal_Entry__c where id = :JEList[0].id ];
			system.assert(jeData != null,'Expected to see the JE created');
			system.assert(jeData.period__c != null,'Expected to see period assigned to the  JE');
			system.assert(jeData.accounting_Entries__r.size() > 0,'Expected to have accounting entry created for JE');
			List<Accounting_Entry_Line__c> aels = [Select id, Name, Accounting_Code__c, GL_Account__c 
			                                    from Accounting_Entry_Line__c where Accounting_Entry__c in :jeData.Accounting_Entries__r];
			
			system.assert(jeData.accounting_Entries__r[0].has_exceptions__c == false,'Not expected to get exception on the accounting entry');
			system.assert(jeData.accounting_Entries__r[0].Period__c == jeData.period__c,'Expected to get the period from JE');
			
			
			for(Accounting_Entry_Line__c ael: aels){
				system.assert(ael.Accounting_Code__c != null, 'ael.Accounting_Code__c:'+ael.Accounting_Code__c);
			}
			
			myPeriod.AR_Subledger_Closed__c =  System.now().addseconds(1);
			myPeriod.AP_Subledger_Closed__c = System.now().addseconds(1);
			myPeriod.FA_Subledger_Closed__c = System.now().addseconds(1);
			myPeriod.Inventory_Subledger_Closed__c = System.now().addseconds(1);
			myPeriod.Receiving_Subledger_Closed__c = System.now().addseconds(1);
			myPeriod.Shipment_Subledger_Closed__c = System.now().addseconds(1);
			myPeriod.GL_Close__c = system.now().addseconds(2);
			myPeriod.Open__c = false;
			myPeriod.Closed__c = true;
			
			PeriodService.systemEditable.add(myPeriod.Id);
			update myPeriod;
        }
        
    
    }
     
   
     static testmethod void testYearEndClose(){
        	//JournalEntries JE = new JournalEntries();
        	 test.startTest();
			Fiscal_Year__c fy = [select id, name, fiscal_year_start_date__c,
			                            fiscal_year_end_date__c, company__c,GL_Account__c 
			                            from fiscal_year__c where name ='My Year'];
			system.debug('fy :' + fy);
			
			GL_Account__c retainedEarningsGL = [select id, name from GL_Account__c where name  = '39000 - Retained Earnings'];
			Period__c iPeriod = [Select id, name, type__c, company__c, fiscalYear__c from Period__c where type__c = 'Period 13'];
			system.debug('retainedEarningsGL :' + retainedEarningsGL);
			
	
            Apexpages.standardcontroller con = new Apexpages.Standardcontroller(fy);
            pageReference pr = page.YearEndClose;
            Test.setCurrentPage(pr);
            YearEndCloseExt ext = new YearEndCloseExt(con);
            
            ext.initialValidations();
            system.assert(YearEndCloseExt.YECFlag == false,'Expected to see the flag set to false as there is no Period 13 period for the fiscal year'); 
            integer year = system.now().year();
            /*Period__c iPeriod = new Period__c();
            iPeriod.Name = 'Period' + string.valueOf(year);
            iPeriod.Period_Number__c = 2;
            iPeriod.Quarter_Number__c = 1;
            iPeriod.type__c = 'Period 13';
            iPeriod.Company__c = fy.company__c;
            iPeriod.Open__c = 1 >= system.now().month();
            iPeriod.fiscalYear__c = fy.Id;
            insert iPeriod;*/
        
            // String min = YearEndCloseExt.findMin(fy.id);
            // String max = YearEndCloseExt.findMax(fy.id);
          
			ext.initialValidations();
			system.assert(YearEndCloseExt.YECFlag == false,'Expected to see the flag set to false as there is no gl account on the fiscal year');
			
			system.assert(fy.GL_Account__c == null,'Not expected to have a GL Account associated');
			fy.GL_Account__c = retainedEarningsGL.id;
			update fy;
			
// 			boolean fiscalYearDeleteError = false;
// 			try{
// 				delete fy;
// 			}catch(Exception ex){
// 				fiscalYearDeleteError = true;
// 			}
			
// 			system.assert(fiscalYearDeleteError, 'We should not be able to delete a fiscal year with related periods.');
			
			//YearEndCloseExt.chunkPeriodRange(min,max);
			
// 			Map<String, String> autoNumRange = new Map<String, String>();
// 			autoNumRange.put('first',min);
// 			autoNumRange.put('last',max);
			
// 			List<AggregateResult> resultList = YearEndCloseExt.getRecentDataSOQL(autoNumRange, fy.id);
// 			system.assert(resultList != null,'Not expected to get the resultList null');
// 			system.assert(resultList.size() == 2,'Expected to get 2 unique accounting codes for the Income Statement GLs so 2 records in aggregate results'+resultList);
			
			Id JEId = YearEndCloseExt.createYearEndJournalEntry(fy.id);
			
			
			system.debug('query'+ext.scoaQuery); 
			
			String scoaWhereClause = ' WHERE Accounting_Entry__r.Status__c = \'Active\' AND Accounting_Entry__r.Has_Exceptions__c = false AND (GL_Account__r.Statement_Type__c = \'Income Statement\' OR GL_Account__r.GL_Type__r.Statement_Type__c  = \'Income Statement\')' + 
                                                     ' AND accounting_entry__r.period__r.fiscalyear__c ='+ '\'' +fy.id +'\''+ 
                                                     ' AND COMP_Functional_Currency_Amount_DR__c != null'+
                                                     ' AND COMP_Functional_Currency_Amount_CR__c != null';

			
			String query = ext.scoaQuery+ scoaWhereClause;
			
			List<Accounting_Entry_Line__c> scoaAElines= Database.query(query);
			
			system.debug('soaAels'+scoaAElines);
			
			List<YearEndCloseExt.JELConfig2> jelcList = new List<YearEndCloseExt.JELConfig2>();
			YearEndCloseExt.JELConfig2 jelc;
			for(Accounting_Entry_Line__c ael: scoaAElines){
				jelc = new YearEndCloseExt.JELConfig2();
				jelc.balance = (Decimal)ael.get('COMP_Functional_Currency_Amount_DR__c') - (Decimal)ael.get('COMP_Functional_Currency_Amount_CR__c') ; 
				jelc.accountingCodeId = ael.Accounting_Code__c; 
				jelcList.add(jelc);
			}
			system.debug('jelcList'+jelcList);
  		    system.assert(jelcList.size() == 2,'Expected to have 2 records in the JEConfig List');
			
// 			Boolean isDataCreated = YearEndCloseExt.createJournalEntryData(jelcList);
	        Boolean isDataCreated = (YearEndCloseExt.createJournalEntryData2(jelcList,JEId)).success;

			system.assert(isDataCreated = true,'Expected to have the Journal Entry data created'); 
			//YearEndCloseExt.createRetainedEarnings(JEId, fy.GL_Account__c, fy.id); 
			String returnSuccess = YearEndCloseExt.createRetainedEarnings(JEId, fy.GL_Account__c, fy.id);
			
			system.debug('RetainedEarnings created Successfully: '+returnSuccess); 
			
			System.assertEquals(returnSuccess, 'Success'); 
 		
 			Journal_Entry__c yearEndJE = [Select id, Name, Period__c, Type__c, Status__c, 
 			                                     Total_Credit__c,Total_Debit__c,
			                                     Posting_date__c, Transaction_date__c,	
			                                     (Select id, Journal_Entry__c,GL_Account__c,GL_Account__r.name,
			                                        Amount_DR__c,Amount_CR__c from Journal_Entry_Lines__r) 
			                                     from Journal_Entry__c 
			                                     where type__c = 'Year End']; 
			 system.debug('jelines on yearEndJE'+yearEndJE.Journal_Entry_Lines__r);
			 
			JournalEntryAccounting jea = new JournalEntryAccounting();
  			jea.execute(yearEndJE.journal_entry_lines__r);
			
			yearEndJE = [Select id, Name, Period__c, Type__c, Status__c, 
			                              Posting_date__c, Transaction_date__c,
			                              (Select id, Status__c, Period__c from Accounting_Entries__r) 
			                              from Journal_Entry__c 
			                              where type__c = 'Year End']; 
			system.assert(yearEndJE != null,'Expected to see the year end JE created');
			system.assert(yearEndJE.period__c == iPeriod.id,'Expected to see Period 13 period assigned to the year end JE');
			system.assert(yearEndJE.accounting_Entries__r.size() > 0,'Expected to have accounting entry created for year end JE');
			system.assert(yearEndJE.accounting_Entries__r[0].Period__c == yearEndJE.Period__c,'Expected to have same period on Year End JE and AE');
			system.assert(yearEndJE.Posting_date__c == yearEndJE.Transaction_date__c,'Expected to have posting date on Year End JE');
  
 			//ext.initialValidations();
			//System.assertEquals(ext.existingYEJournal, true);
			
			period__c prd = [Select Id,FiscalYear__r.Fiscal_Year_End_Date__c 
			                        from period__c 
			                        where id =: iPeriod.id];
			system.assert(yearEndJE.Transaction_Date__c == prd.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1), 
			                        'yearEndJE.Transaction_Date__c = ' + yearEndJE.Transaction_Date__c + 
			                        'prd.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1)  =  ' + prd.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1)); 
			ext.cancelExistingYearEndJournal();
		 	yearEndJE = [Select id, Name, Period__c, Type__c, Status__c, 
		 	                        (Select id, Status__c, Period__c from Accounting_Entries__r) 
		 	                        from Journal_Entry__c where type__c = 'Year End'];
			system.assert(yearEndJE.status__c == 'Cancelled');
			system.assert(yearEndJE.Accounting_Entries__r[0].status__c == 'Obsolete');
			 
        Test.stopTest();
        
        
    }
    
    
     static testmethod void fiscalYearRetainedEarningsChange(){
			Fiscal_Year__c fy = [select id, name, fiscal_year_start_date__c, fiscal_year_end_date__c, company__c,GL_Account__c from fiscal_year__c where name ='My Year'];
			GL_Account__c retainedEarningsGL = [select id, name from GL_Account__c where name  = '39000 - Retained Earnings'];
			GL_Account__c cashGL = [select id, name from GL_Account__c where name  = '12000 - Cash'];
			period__c myPeriod = [select id, name, Open__c, Closed__c from period__c where name = 'Period1'];
		
			Test.startTest();
            Apexpages.standardcontroller con = new Apexpages.Standardcontroller(fy);
            pageReference pr = page.YearEndClose;
            Test.setCurrentPage(pr);
            YearEndCloseExt ext = new YearEndCloseExt(con);
            ext.getPeriods();
            
            //ext.initialValidations();
            //system.assert(ext.YECFlag == false,'Expected to see the flag set to false as there is no Period 13 period for the fiscal year');
            
            integer year = system.now().year();
            Period__c iPeriod = new Period__c();
            iPeriod.Name = 'Period' + string.valueOf(year);
            iPeriod.Period_Number__c = 2;
            iPeriod.Quarter_Number__c = 1;
            iPeriod.type__c = 'Period 13';
            iPeriod.Company__c = fy.company__c;
            iPeriod.Open__c = 1 >= system.now().month();
            iPeriod.fiscalYear__c = fy.Id;
 			myPeriod.Open__c = false;
			myPeriod.Closed__c = true;
           insert iPeriod;

			fy.GL_Account__c = retainedEarningsGL.id;
			update fy;
			
			//update myPeriod;
			iPeriod.Open__c = false;
			iPeriod.Closed__c = true;
			list<period__C> plist = [select id, name, closed__c, open__c,period_start__c, Period_End__c from period__c where fiscalyear__c =: fy.id  and type__c != 'Period 13'];
			
			update iPeriod;
			fy.GL_Account__c = cashGL.id;
			
			
			boolean fiscalYearUpdate= false;
			try{
				update fy;
			}catch(Exception ex){
				fiscalYearUpdate = true;
			}
			
			system.assert(fiscalYearUpdate, 'We should not be able to update a fiscal year after Period 13 period is closed');
			
	
        Test.stopTest();
        
        
    }
   //KNDY-9906 
 public static testMethod void testCompanyValidationRule(){
			Fiscal_Year__c fy = [select id, name, fiscal_year_start_date__c, fiscal_year_end_date__c, company__c,GL_Account__c from fiscal_year__c where name ='My Year'];
            
        Test.startTest();
            Apexpages.standardcontroller con = new Apexpages.Standardcontroller(fy);
            pageReference pr = page.YearEndClose;
            Test.setCurrentPage(pr);
            YearEndCloseExt ext = new YearEndCloseExt(con);
            Boolean sawException = false;
            String eMsg;
            Integer vFPErrorSize;

            fy.Company__c = NULL;


        try{

        Update fy;    
        }catch(Exception ex){
            sawException = true;
            eMsg = ex.getMessage();
            vFPErrorSize = ApexPages.getMessages().size();

        }
        
        system.assert(sawException == true, eMsg);
        system.assert(eMsg.contains('Please specify a company for this fiscal year.'));
        system.assertNotEquals(vFPErrorSize, 0);
        system.assert(YearEndCloseExt.YECFlag == false,'Please specify a company for this Fiscal Year');        
        Test.stopTest();
   }   
    
}