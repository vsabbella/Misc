/**
 * This class covers the AccountingEntryLine.Trigger 
 */
@isTest
private class AccountingEntryLineTriggerTest {
    // TODO: SK - Manual Accounting Entries test data need to be revisited once the journal entries are enforced to use instead of manual AEs.
    // TODO: SK - asserts related to Credit_Debit_unmatched__c are commented out as this works on the debit and credit for the ledgers and for manual AEs those fields will not be populated.
    static TestDataForFinance testData = new TestDataForFinance(); 
        
    static testMethod void myUnitTest() {
        Test.startTest();
        Segment_Validation__c sv1, sv2;
    	List<Segment_Validation__c> svList = new List<Segment_Validation__c>();{
            sv1 = new Segment_Validation__c();
            sv1.segment_1__c ='*';
            sv1.segment_2__c = '*';
            sv1.active__c = true;
            svList.add(sv1);
             
            insert svList;
        
        }
        
        Accounting_Standard__c acctStd = [Select id from Accounting_Standard__c LIMIT 1];
        List<Accounting_Rule__c> arList = new List<Accounting_Rule__c>();
        Accounting_Rule__c ar1 = new Accounting_Rule__c(Name = 'Rule0001', Accounting_Standard__c = acctStd.id, Object_Name__c = 'Accounting_Entry__c',Company__c = testData.company.id,Transaction__c = 'Manual',Rule_Type__c='CR',Expected_Sign__c='Positive',GL_Account__c=testData.Acctdata.cashGL.id,Effective_Start_Date__c=TestData.AcctData.effStartDate);
        arList.add(ar1);
        Accounting_Rule__c ar2 = new Accounting_Rule__c(Name = 'Rule0002', Accounting_Standard__c = acctStd.id, Object_Name__c = 'Accounting_Entry__c',Company__c = testData.company.id,Transaction__c = 'Manual',Rule_Type__c='DR',Expected_Sign__c='Positive',GL_Account__c=testData.Acctdata.cashGL.id,Effective_Start_Date__c=TestData.AcctData.effStartDate);
        arList.add(ar2);
        insert arList;
        Accounting_Entry_Line__c acctEntryLineCR, acctEntryLineDR;
        
        Decimal manyDigits = 125.123456789;
        Decimal storedDigits =   manyDigits.setScale(6,RoundingMode.FLOOR); // test for FIN-852
        
        Accounting_Entry__c accountingEntryObj = new Accounting_Entry__c();{
            accountingEntryObj =new Accounting_Entry__c();
            //accountingEntryObj.Period__c = testData.periodList[0].Id; 
            accountingEntryObj.Transaction_Date__c = system.now();
            accountingEntryObj.Finalized_Date__c = system.now();
            //accountingEntryObj.GL_Date__c = system.today();
            accountingEntryObj.Transaction_Type__c = 'Manual';
            accountingEntryObj.Source_Document_Object_Name__c = 'Manual';
            accountingEntryObj.Company__c = testData.company.id;
            accountingEntryObj.Currency__c = TestFuel.currencyUSD.id;
            insert accountingEntryObj;
            List<Accounting_Entry_Line__c> acctEntryLineList = new List<Accounting_Entry_Line__c>();
            acctEntryLineCR = new Accounting_Entry_Line__c();
            acctEntryLineCR.Amount_CR__c = manyDigits;
            acctEntryLineCR.Amount_DR__c = 0;
            acctEntryLineCR.GL_Account__c = testData.Acctdata.cashGL.id; 
            acctEntryLineCR.Transaction_Date__c = system.today();
            acctEntryLineCR.Accounting_Entry__c = accountingEntryObj.id;
            acctEntryLineCR.Company__c = accountingEntryObj.Company__c;
            acctEntryLineList.add(acctEntryLineCR);
            acctEntryLineCR.Accounting_rule__c = ar1.id;
            acctEntryLineDR = new Accounting_Entry_Line__c();
            acctEntryLineDR.Amount_DR__c = manyDigits;
            acctEntryLineDR.Amount_CR__c = 0;
            acctEntryLineDR.GL_Account__c = testData.Acctdata.cashGL.id;
            acctEntryLineDR.Transaction_Date__c = system.today();
            acctEntryLineDR.Accounting_Entry__c = accountingEntryObj.id;        
            acctEntryLineDR.Company__c = accountingEntryObj.Company__c;
            acctEntryLineDR.Accounting_rule__c = ar2.id;
            acctEntryLineList.add(acctEntryLineDR);  
            
            insert acctEntryLineList;         
        }
        
        List<Accounting_Entry_Line__c> acctEntryLineList = [Select id, Name,  Period_Name__c, Company_Name__c, Accounting_Entry__c,
                                                            Amount_CR__c,Amount_DR__c
                                                            from Accounting_Entry_Line__c
                                                            where Accounting_Entry__c = :accountingEntryObj.id ];
                                                            
        accountingEntryObj = [Select id, Name, Period__c, Company__c, has_exceptions__c, Line_Exceptions__c
                             from Accounting_Entry__c where id = :accountingEntryObj.id limit 1];       
                                                                        
        List<Period__c> periodList = [Select id, Name from Period__c where id = :accountingEntryObj.Period__c];                                                         
        
        List<Company__c> companyList = [Select id, Name from Company__c where id = :accountingEntryObj.Company__c];
        
        system.assertEquals(testData.company.id , accountingEntryObj.Company__c );
        
        for ( Accounting_Entry_Line__c line: acctEntryLineList ) {  // test for FIN-852
            system.assert( line.Amount_CR__c == 0 || line.Amount_CR__c == storedDigits,'expected 6 decimal places');
            system.assert( line.Amount_DR__c == 0 || line.Amount_DR__c == storedDigits,'expected 6 decimal places');
        }
        /* SK - this test is no longer eligible as the exchange rate calculation stuff is moved to accounting engine. More test around this can be found in AccountingServiceTest.cls
        system.assertEquals(testData.company.Functional_Currency__c, acctEntryLineList[0].Functional_currency__c);
        system.assertEquals(testData.company.Corporate_currency__c, acctEntryLineList[0].Corporate_Currency__c);
        system.assertEquals(testData.company.Reporting_currency__c, acctEntryLineList[0].Reporting_Currency__c);
        system.assertEquals(testData.company.Functional_Currency__c, acctEntryLineList[1].Functional_currency__c);
        system.assertEquals(testData.company.Corporate_currency__c, acctEntryLineList[1].Corporate_Currency__c);
        system.assertEquals(testData.company.Reporting_currency__c, acctEntryLineList[1].Reporting_Currency__c);
        
        system.assertEquals(testData.Acctdata.exchangeRateList[0].Multiplier_Exchange_Rate__c, acctEntryLineList[0].Functional_Currency_Conversion_Rate__c);
        system.assertEquals(testData.Acctdata.exchangeRateList[2].Multiplier_Exchange_Rate__c, acctEntryLineList[0].Corporate_Currency_Conversion_Rate__c);
        system.assertEquals(testData.Acctdata.exchangeRateList[1].Multiplier_Exchange_Rate__c, acctEntryLineList[0].Reporting_Currency_Conversion_Rate__c);
        system.assertEquals(testData.Acctdata.exchangeRateList[0].Multiplier_Exchange_Rate__c, acctEntryLineList[1].Functional_Currency_Conversion_Rate__c);
        system.assertEquals(testData.Acctdata.exchangeRateList[2].Multiplier_Exchange_Rate__c, acctEntryLineList[1].Corporate_Currency_Conversion_Rate__c);
        system.assertEquals(testData.Acctdata.exchangeRateList[1].Multiplier_Exchange_Rate__c, acctEntryLineList[1].Reporting_Currency_Conversion_Rate__c);
        
        system.assertEquals(152.4125, acctEntryLineList[0].Functional_Currency_Amount_CR__c);
        system.assertEquals(96.3125, acctEntryLineList[0].Corporate_Currency_Amount_CR__c);
        system.assertEquals(77.75, acctEntryLineList[0].Reporting_Currency_Amount_CR__c);
        system.assertEquals(152.4125, acctEntryLineList[1].Functional_Currency_Amount_DR__c);
        system.assertEquals(96.3125, acctEntryLineList[1].Corporate_Currency_Amount_DR__c);
        system.assertEquals(77.75, acctEntryLineList[1].Reporting_Currency_Amount_DR__c);
        */
        system.assertEquals(periodList[0].Name,acctEntryLineList[0].Period_Name__c);
        system.assertEquals(periodList[0].Name,acctEntryLineList[1].Period_Name__c);
        
        system.assertEquals(companyList[0].Name,acctEntryLineList[0].Company_Name__c);
        system.assertEquals(companyList[0].Name,acctEntryLineList[1].Company_Name__c);
 
        /* test 
         * AccountingEntryLineEditExt
         */
        AccountingEntryLineEditExt ext = new AccountingEntryLineEditExt(new Apexpages.Standardcontroller(acctEntryLineList[0] ));
        system.assert( ext.doRedirect() != null,' expected valid page');
        
        // Create Accounting Entry
        // Create Accounting Entry Lines with CR = DR
        // Create Accounting Entry Lines with CR != DR (update / insert / delete) and check if the exception is flagged
        accountingEntryObj = [Select id, Name, Period__c, Company__c, has_Exceptions__c, Line_Exceptions__c
                             from Accounting_Entry__c where id = :accountingEntryObj.id limit 1];       
                             
        update accountingEntryObj;
        //system.assertEquals(false, accountingEntryObj.has_Exceptions__c );
        //system.assertEquals(0,accountingEntryObj.Line_Exceptions__c,'accountingEntryObj:'+accountingEntryObj);
        //system.assertEquals(false, accountingEntryObj.Credit_Debit_unmatched__c);
        //system.assertEquals(false, accountingEntryObj.Period_Exception__c );
        
        acctEntryLineCR.Amount_CR__c = 100;
        
        update acctEntryLineCR;
        List<Accounting_Entry__c> accountingEntryList = [Select id, Name, has_exceptions__c  from Accounting_Entry__c where id = :accountingEntryObj.id ];
        //system.assertEquals(true, accountingEntryList[0].Exception__c );
        //system.assertEquals(true, accountingEntryList[0].Credit_Debit_unmatched__c);
        
        acctEntryLineDR.Amount_DR__c = 100;
        update acctEntryLineDR;
        accountingEntryList = [Select id, Name, has_exceptions__c from Accounting_Entry__c where id = :accountingEntryObj.id ];
        //system.assertEquals(false, accountingEntryList[0].Exception__c );
        //system.assertEquals(false, accountingEntryList[0].Credit_Debit_unmatched__c);
        
        acctEntryLineDR.GL_Account__c = null;
        
        update acctEntryLineDR;
        accountingEntryList = [Select id, Name,  Has_Exceptions__c, Line_Exceptions__c,(Select id, Mandatory_Segment_Exception__c from Accounting_Entry_Lines__r)
                                from Accounting_Entry__c where id = :accountingEntryObj.id ];
        
        
        system.assertEquals(true, accountingEntryList[0].Has_Exceptions__c );
        //system.assertEquals(1,accountingEntryList[0].Line_Exceptions__c);
        
        delete acctEntryLineDR;
        
        //accountingEntryList = [Select id, Name, Exception__c, Credit_Debit_unmatched__c from Accounting_Entry__c where id = :accountingEntryObj.id ];
        //system.assertEquals(true, accountingEntryList[0].Exception__c );
        //system.assertEquals(true, accountingEntryList[0].Credit_Debit_unmatched__c);
    }
    
    // Test the posted AE changes KNDY 1627
    //KNDY-1126 Security scanner -Test method with no asserts.
    //Commenting this out as it no longer relevant
    /*
    static testMethod void myUnitTest2() {
        Test.startTest();
        Accounting_Entry_Line__c acctEntryLineCR, acctEntryLineDR;

            List<Accounting_Rule__c> arList = new List<Accounting_Rule__c>();
            Accounting_Rule__c ar1 = new Accounting_Rule__c(Name = 'Rule0001', Object_Name__c = 'Accounting_Entry__c',Company__c = testData.company.id,Transaction__c = 'Manual',Rule_Type__c='CR',Expected_Sign__c='Positive',GL_Account__c=testData.Acctdata.cashGL.id);
            arList.add(ar1);
            Accounting_Rule__c ar2 = new Accounting_Rule__c(Name = 'Rule0002', Object_Name__c = 'Accounting_Entry__c',Company__c = testData.company.id,Transaction__c = 'Manual',Rule_Type__c='DR',Expected_Sign__c='Positive',GL_Account__c=testData.Acctdata.cashGL.id);
            arList.add(ar2);
            insert arList;
        Accounting_Entry__c accountingEntryObj = new Accounting_Entry__c();{
            accountingEntryObj =new Accounting_Entry__c();
            //accountingEntryObj.Period__c = testData.periodList[0].Id; 
            //accountingEntryObj.GL_Date__c = system.today();
            accountingEntryObj.Transaction_Date__c = system.now();
            accountingEntryObj.Finalized_Date__c = system.now();
            accountingEntryObj.Transaction_Type__c = 'Manual';
            accountingEntryObj.Source_Document_Object_Name__c = 'Manual';
            accountingEntryObj.Company__c = testData.company.id;
            //accountingEntryObj.Ready_To_Post__c = true;
            accountingEntryObj.Currency__c = TestFuel.currencyUSD.id;
            insert accountingEntryObj;
            List<Accounting_Entry_Line__c> acctEntryLineList = new List<Accounting_Entry_Line__c>();
            acctEntryLineCR = new Accounting_Entry_Line__c();
            acctEntryLineCR.Amount_CR__c = 125;
            acctEntryLineCR.GL_Account__c = testData.Acctdata.cashGL.id; 
            acctEntryLineCR.Transaction_Date__c = system.today();
            acctEntryLineCR.Accounting_Entry__c = accountingEntryObj.id;
            acctEntryLineCR.Company__c = accountingEntryObj.Company__c;
            acctEntryLineCR.Accounting_rule__c = ar1.id;
            acctEntryLineList.add(acctEntryLineCR);
            acctEntryLineDR = new Accounting_Entry_Line__c();
            acctEntryLineDR.Amount_DR__c = 125;
            acctEntryLineDR.GL_Account__c = testData.Acctdata.cashGL.id;
            acctEntryLineDR.Transaction_Date__c = system.today();
            acctEntryLineDR.Accounting_Entry__c = accountingEntryObj.id;    
            acctEntryLineDR.Company__c = accountingEntryObj.Company__c;   
            acctEntryLineDR.Accounting_rule__c = ar2.id;
            acctEntryLineList.add(acctEntryLineDR);  
            
            insert acctEntryLineList;         
        }
        
        List<Accounting_Entry_Line__c> acctEntryLineList = [Select id, Name, Period_Name__c, Company_Name__c,
                                                             Accounting_Entry__c
                                                            from Accounting_Entry_Line__c
                                                            where Accounting_Entry__c = :accountingEntryObj.id ];
        
        Integer aeLineListsize = acctEntryLineList.size();
        //KNDY-1126 Security scanner -Test method with no asserts.
        system.assertNotequals(aeLineListsize,0,'Expecting AEs to be generated')  ;                                           
        accountingEntryObj = [Select id, Name, Period__c, Company__c, Exception__c, Line_Exceptions__c, 
        						Credit_Debit_unmatched__c, Period_Exception__c, Total_Lines__c
                             from Accounting_Entry__c where id = :accountingEntryObj.id limit 1]; 
        //system.debug(Logginglevel.info+'Total_Lines__c :'+accountingEntryObj.Total_Lines__c+');                           
       
       /* KNDY-2223 this is an exception on modifying a posted AE.  Not relevant right now since we are removing posting.
        boolean exceptionOccurred = false;
        try{
            acctEntryLineDR.GL_Account__c = testData.Acctdata.allowanceExpGL.id;
            update acctEntryLineDR;
        }catch(Exception e){
            system.debug('exceptionOccurred: '+e.getMessage());
            exceptionOccurred = true; // Expected to see exception as posted AE should not be modified
        }                        
        
        system.assertEquals(true, exceptionOccurred);
        */
  /*  }
    */
    
    static testMethod void myUnitTest3() {
        Test.startTest();
        
        ApexPages.StandardController con;
        
        con = new ApexPages.StandardController(new Accounting_Entry__c());

        //Create accounting entry
		Accounting_Entry__c AE = new Accounting_Entry__c();
		AE.Company__c = testData.company.id;
		AE.Transaction_Type__c = 'Manual';
		AE.Source_Document_Object_Name__c = 'Manual';
		AE.Currency__c = TestFuel.currencyUSD.id;
//		AE.has_exceptions__c = false;
		AE.Transaction_Date__c = system.now();
		AE.Finalized_Date__c = system.now();
		//AE.Period_Exception__c = false;
		//AE.Period__c = testData.periodList[0].id;
		//AE.GL_Date__c = System.today();
		insert AE;
		
		List<Accounting_Entry_Line__c> AElines = new List<Accounting_Entry_Line__c>();
		
		Accounting_Entry_Line__c AELineCR = new Accounting_Entry_Line__c();
		AELineCR.Accounting_Entry__c = AE.Id;
		AELineCR.Amount_CR__c = 125;
//		AELineCR.has_exceptions__c = false;
	    AELineCR.GL_Account__c = testData.Acctdata.cashGL.id;
	    AELineCR.Transaction_Date__c = system.today();
	    
	    AElines.add(AELineCR);
	    
	    Accounting_Entry_Line__c AELineDR = new Accounting_Entry_Line__c();
	    AELineDR.Accounting_Entry__c = AE.Id;
	    AELineDR.Amount_DR__c = 125;
//		AELineDR.has_exceptions__c = false;
	    AELineDR.GL_Account__c = testData.Acctdata.cashGL.id;
	    AELineDR.Transaction_Date__c = system.today();
		
		AElines.add(AELineDR);
		insert AElines;
		//Deprecated PeriodStartDate and PeriodEndDate and used Period_Start__c and Period_End__c
        /*
		List<Period__c> periodList = [select id, Name, Adjustment_Period__c, Corporate__c, Fiscal__c, Fiscal_Year__c, Period_End__c,
                            Period_Number__c, Period_Start__c, Primary_key__c, Quarter_Number__c, Year_End_Date__c, Year_Start_Date__c
                            from Period__c where open__c = true];
        */
        List<Period__c> periodList = [select id, Name, Adjustment_Period__c, Corporate__c, Fiscal__c, Fiscal_Year__c, Period_End__c,
                            Period_Number__c, Period_Start__c, Primary_key__c, Quarter_Number__c, Year_End_Date__c, Year_Start_Date__c
                            from Period__c where open__c = true];
                                                
		AE.Period__c = periodList[0].id;
		update AE;
		Accounting_Entry__c postedAE = [select id, Period__c, has_exceptions__c, Total_Lines__c from Accounting_Entry__c where id = :AE.id];
		List<Accounting_Entry_Line__c> postedAELines = [Select id, Name, Company__c 
														from Accounting_Entry_Line__c
														where Accounting_Entry__c = :postedAE.id];
		
		postedAELines[0].Company__c = null;
		postedAELines[1].Company__c = null;
		update postedAELines;
		
		system.assertEquals(2, postedAE.Total_Lines__c);
		List<Accounting_Entry_Line__c> accLines = [select id from Accounting_Entry_Line__c where Accounting_Entry__c = :postedAE.id];
		
		con = new ApexPages.StandardController(postedAE);
		postedAE = [select id, Period__c, has_exceptions__c, Total_Lines__c from Accounting_Entry__c where id = :postedAE.id];
        
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(postedAE); 
        AccountingEntryVoidExt AESExt = new AccountingEntryVoidExt(sc);
        //system.assertNotEquals(null, AESExt.voidAccountingEntry(), Apexpages.getMessages());
        
        postedAE = [Select id, Name, Related_Accounting_Entry__c
                             from Accounting_Entry__c where id = :postedAE.id limit 1]; 
        
        Id AEtoCheck = postedAE.Related_Accounting_Entry__c;
        
        List<Accounting_Entry_Line__c> AELinestoCheck = [Select id, Name, Company__c
        												from Accounting_Entry_Line__c
        												where Accounting_Entry__c = :AEtoCheck];
        // KNDY - 2362 : Commented test case for this JIRA												
        //system.assertEquals(null, AELinestoCheck[0].Company__c);
        //system.assertEquals(null, AELinestoCheck[1].Company__c);
        
        //TODO: RS 8/1/2014 Refactor this test - There will no longer be manual accounting entries
        //system.assertNotEquals(null, AELinestoCheck[0].Company__c);
        //system.assertNotEquals(null, AELinestoCheck[1].Company__c);
        
    }
}