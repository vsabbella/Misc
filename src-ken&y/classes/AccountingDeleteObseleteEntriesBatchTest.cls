@isTest
private class AccountingDeleteObseleteEntriesBatchTest {
  
    
     static testMethod void DeletionTest() {
        TestFuel fuel = new TestFuel();     
        
        Account testAccount = new Account();
        testAccount.name = 'KenandyTestFuel'+ '-' + String.ValueOf((Integer) (Math.random () * 999));
        testAccount.billingstreet = '303 Twin Dolphin Drive, Suite 500';
        testAccount.billingcity = 'Redwood City';
        testAccount.billingstate = 'CA';
        testAccount.billingpostalcode = '94065';
        testAccount.billingcountry = 'USA';
        testAccount.shippingstreet = '303 Twin Dolphin Drive, Suite 500';
        testAccount.shippingcity = 'Redwood City';
        testAccount.shippingstate = 'CA';
        testAccount.shippingpostalcode = '94065';
        testAccount.shippingcountry = 'USA';
        testAccount.phone = '650-468-2000';
        testAccount.fax = '650-468-2010';
        testAccount.website = 'kenandy.com';
        insert testAccount;

        Company__c testCompany = new Company__c();
        testCompany.name = 'KenandyTestFuel'+ '-' + String.ValueOf((Integer) (Math.random () * 999));
        testCompany.Address__c = testAccount.ID;
        testCompany.A_Days__c = 30;
        testCompany.B_Days__c = 60;
        testCompany.C_Days__c = 180;
        testCompany.Company_Identifier__c = 'KEN' + '-' + String.ValueOf((Integer) (Math.random () * 999));
        testCompany.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        testCompany.Consol_Currency__c = TestFuel.currencyEUR.id;
        testCompany.Stat_Currency__c = TestFuel.currencyGBP.id;
        testCompany.Subs_Currency__c = TestFuel.currencyUSD.id;
        testCompany.Comp_Currency__c = TestFuel.currencySGD.id; 
        //testCompany.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        insert testCompany;

        Fiscal_Year__c testFiscalYear = new Fiscal_Year__c();
        testFiscalYear.Company__c = testCompany.id;
        testFiscalYear.Fiscal_Year_End_Date__c = system.now().addDays(200);
        testFiscalYear.Fiscal_Year_Start_Date__c = system.now().addDays(-30);
        insert testFiscalYear;

        Period__c testPeriod1 = new Period__c();
        testPeriod1.Period_Start__c = system.now();
        testPeriod1.Open__c = True;
        testPeriod1.Period_End__c = system.now().addDays(10);
        testPeriod1.Company__c = testCompany.id;                    
        testPeriod1.Name = string.valueOf(1)+ '-' + String.ValueOf((Integer) (Math.random () * 999) + system.now().getTime());
        testPeriod1.Year_Start_Date__c = date.newInstance(system.now().year(), 1, 1);
        testPeriod1.Year_End_Date__c = date.newInstance(system.now().year() + 1, 1, 1);
        testPeriod1.Period_Number__c = 1;
        testPeriod1.FiscalYear__c = testFiscalYear.id;
        testPeriod1.Delete_ObsoleteAEs__c = TRUE;
        insert testPeriod1;

        Journal_Entry__c je = new Journal_Entry__c();
            je.name = 'JE001';
            je.Company__c = testCompany.id; 
            je.Transaction_Date__c = System.now();  
            je.Currency__c = TestFuel.currencyUSD.id;
            je.type__c = 'Accrual - Manual'; 
            //FIN-954 we are using transaction_type__c for accounting on all source docs.Trigger defaults  transaction_type__c from type__c. 
            //TODO: Add the below line once we deprecate type__c  
            //je1.transaction_type__c = 'Accrual - Manual';  
            insert je;
            //JEList_Accrual.add(je);
            
            list<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
            
            Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
            jeLine1.Journal_Entry__c = je.id;
            jeLine1.Amount_CR__c = 5;
            jeLine1.Amount_DR__c = 0;
            jeLine1.GL_Account__c = fuel.cashGL.id;
            jeLineList.add(jeLine1); 
            
            Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
            jeLine2.Journal_Entry__c = je.id;
            jeLine2.Amount_CR__c = 0;
            jeLine2.Amount_DR__c = 5;
            jeLine2.GL_Account__c = fuel.receivablesGL.id;
            jeLineList.add(jeLine2); 
            
            insert jeLineList;
    
            je.finalized__c = true;
            update je;   


            JournalEntryAccounting jea = new JournalEntryAccounting();
            jea.execute(jeLineList);

        Test.startTest();

        system.assert(testPeriod1.Delete_ObsoleteAEs__c == TRUE);
        List<Accounting_Entry__c> aeList = [SELECT Id, has_exceptions__c, Period__c 
                                            FROM Accounting_Entry__c 
                                            WHERE Period__c = : testPeriod1.id];


        system.assert(aeList.size() > 0);
        system.debug('Does this accounting entry have exceptions? ' + aeList[0].has_exceptions__c);
        system.assert(aeList[0].period__C == testPeriod1.id);
        for(Accounting_Entry__c aeToObsolete : aeList){
            aeToObsolete.Status__c = 'Obsolete';
            update aeToObsolete;
        } 
 system.assert(aeList.size() > 0);
    List<Accounting_Entry__c>  aeInContext = new List<Accounting_Entry__c>();
        aeInContext = [SELECT Id, Status__c, Period__r.Delete_ObsoleteAEs__c, Period__c FROM Accounting_Entry__c WHERE Status__c = 'Obsolete' AND  Period__r.Delete_ObsoleteAEs__c = TRUE];
        system.debug('aeInContext' + aeInContext[0].period__C);
        system.assertEquals( aeInContext[0].status__c, 'Obsolete');     
        system.assertEquals( aeInContext[0].Period__r.Delete_ObsoleteAEs__c, TRUE); 
        Integer aeIncontextSize = aeInContext.size();
        AccountingDeleteObseleteEntriesBatch aeob = new AccountingDeleteObseleteEntriesBatch();
        system.assertEquals( aeIncontext.size(), database.query(aeob.query).size());    
        Process_Job__c job = new Process_Job__c( Company__c = testCompany.id);
        job.Batch_Size__c = 10;
        aeob.runBatch(job);        
        Test.stopTest();
      
        aeInContext = [SELECT Id, Status__c, Period__r.Delete_ObsoleteAEs__c, isDeleted FROM Accounting_Entry__c WHERE Status__c = 'Obsolete' limit 1];
        system.assertEquals( aeInContext.size(), 0 );
        System.assertEquals(1, [SELECT COUNT() FROM Accounting_Entry__c WHERE isDeleted = TRUE ALL ROWS]);  


 

            
    }
    
}