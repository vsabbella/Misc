@isTest
Public with sharing class  APForecastExtTest{

    static testMethod void testCurrentScope(){
    	        TestFuel fuel = new TestFuel();     
        
        Company__c testComp = fuel.Company; 
        Account testAccount = fuel.account; 
        GL_Type__c testExpenseGLType = fuel.expense; 
        Supplier__c testSupplier = fuel.supplier; 
        Supplier__c testSupplierRemitTo = fuel.supplier; 
        testSupplierRemitTo.Type__c = 'Remit To';
        List<Accounting_Rule__c> testAccRule = fuel.SuppInvAcctRulesList;
        Period__c testPeriod = fuel.periodList[0];
        update testSupplierRemitTo;

        Bank_Account__c bankAccount = new Bank_Account__c();
        bankAccount.Name = 'TESTBNK';
        bankAccount.Company__c = testComp.Id;
        insert bankAccount;



        List<GL_Type__c> glTypeList = new List<GL_Type__c>();
        GL_Type__c glType1 = fuel.otherIncome_expense;


        GL_Type__c glType2 = fuel.operatingExpense;
    
        
        List<GL_Account__c> glList = new List<GL_Account__c>();
        GL_Account__c glAccountRevenueA = new GL_Account__c();
        glAccountRevenueA.GL_Account_Number__c = '80003';
        glAccountRevenueA.GL_Account_Name__c = 'Revenue-A';
        glAccountRevenueA.active__c = true;
        glAccountRevenueA.Normal_Balance__c = 'Credit';
        glAccountRevenueA.Statement_Type__c = 'Income Statement';
        glAccountRevenueA.non_cash__c = false;
        glAccountRevenueA.gl_type__c = glType1.id;
        
        insert glAccountRevenueA;


        GL_Account__c glAccountRevenueB = new GL_Account__c();
        glAccountRevenueB.GL_Account_Number__c = '80002';
        glAccountRevenueB.GL_Account_Name__c = 'Revenue-A';
        glAccountRevenueB.active__c = true;
        glAccountRevenueB.Normal_Balance__c = 'Credit';
        glAccountRevenueB.Statement_Type__c = 'Income Statement';
        glAccountRevenueB.non_cash__c = false;
        glAccountRevenueB.gl_type__c = glType1.id;
        
        insert glAccountRevenueB;

        glList.add(glAccountRevenueA);
        glList.add(glAccountRevenueB);


        Accounting_Default__c testAccountingDefault = new Accounting_Default__c();
        testAccountingDefault.GL_Account__c = glAccountRevenueA.Id;
        insert testAccountingDefault;


        Supplier_Invoice__c testSIcurrent = new Supplier_Invoice__c();
        testSIcurrent.Company__c = testComp.id;
        testSIcurrent.Supplier__c = testSupplierRemitTo.id;
        testSIcurrent.Invoice_Amount__c = 350;
        testSIcurrent.Currency__c = TestFuel.currencyUSD.id;
        testSIcurrent.Invoice_Type__c = 'Invoice';
        testSIcurrent.Supplier_Invoice__c = system.today() + ': 123';
        testSIcurrent.Date_Invoiced__c = system.today().addDays(5);
        testSIcurrent.Payment_Due_Override_Date__c = system.today().addDays(5);
        system.debug('THIS IS THE DUE DATE'+ testSIcurrent.Payment_Due_Date__c);

        insert testSIcurrent;

        Supplier_Invoice_Line__c testSILineCurrent = new Supplier_Invoice_Line__c();
        testSILineCurrent.Supplier_Invoice__c = testSIcurrent.id;
        testSILineCurrent.Invoice_Quantity__c = 1;
        testSILineCurrent.Unit_Price__c = testSIcurrent.Invoice_Amount__c; //KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price
        testSILineCurrent.Accounting_Segment__c = testAccountingDefault.id;
        testSILineCurrent.Item__c = fuel.itemList[1].id; 
        insert testSILineCurrent;



        Supplier_Invoice__c testSIprevious = new Supplier_Invoice__c();
        testSIprevious.Company__c = testComp.id;
        testSIprevious.Supplier__c = testSupplierRemitTo.id;
        testSIprevious.Invoice_Amount__c = 70;
        testSIprevious.Currency__c = TestFuel.currencyUSD.id;
        testSIprevious.Invoice_Type__c = 'Invoice';
        testSIprevious.Supplier_Invoice__c = system.today() + ': 456';
        testSIprevious.Date_Invoiced__c = system.today().addDays(-7);
        testSIprevious.Payment_Due_Override_Date__c = system.today().addDays(-5);

        insert testSIprevious;

        Supplier_Invoice_Line__c testSILinePrevious = new Supplier_Invoice_Line__c();
        testSILinePrevious.Supplier_Invoice__c = testSIprevious.id;
        testSILinePrevious.Invoice_Quantity__c = 1;
        testSILinePrevious.Unit_Price__c = 70;//KNDY-14371
        testSILinePrevious.Accounting_Segment__c = testAccountingDefault.id;
        testSILinePrevious.Item__c = fuel.itemList[1].id; 
        insert testSILinePrevious;        


        Supplier_Invoice__c testSIprior = new Supplier_Invoice__c();
        testSIprior.Company__c = testComp.id;
        testSIprior.Supplier__c = testSupplierRemitTo.id;
        testSIprior.Invoice_Amount__c = 500;
        testSIprior.Currency__c = TestFuel.currencyUSD.id;
        testSIprior.Invoice_Type__c = 'Invoice';
        testSIprior.Supplier_Invoice__c = system.today() + ': 789';
        testSIprior.Date_Invoiced__c = system.today().addDays(-40);
        testSIprior.Payment_Due_Override_Date__c = system.today().addDays(-30);


        insert testSIprior; 

        Supplier_Invoice_Line__c testSILinePrior = new Supplier_Invoice_Line__c();
        testSILinePrior.Supplier_Invoice__c = testSIprior.id;
        testSILinePrior.Invoice_Quantity__c = 1;
        testSILinePrior.Unit_Price__c = 500;//KNDY-14371
        testSILinePrior.Accounting_Segment__c = testAccountingDefault.id;
        testSILinePrior.Item__c = fuel.itemList[1].id; 
        insert testSILinePrior; 


        Supplier_Invoice__c testSIlater = new Supplier_Invoice__c();
        testSIlater.Company__c = testComp.id;
        testSIlater.Supplier__c = testSupplierRemitTo.id;
        testSIlater.Invoice_Amount__c = 2000;
        testSIlater.Currency__c = TestFuel.currencyUSD.id;
        testSIlater.Invoice_Type__c = 'Invoice';
        testSIlater.Supplier_Invoice__c = system.today() + ': 147';
        testSIlater.Date_Invoiced__c = system.today().addDays(95);
        testSIlater.Payment_Due_Override_Date__c = system.today().addDays(100);

        insert testSIlater; 

        Supplier_Invoice_Line__c testSILineLater = new Supplier_Invoice_Line__c();
        testSILineLater.Supplier_Invoice__c = testSIlater.id;
        testSILineLater.Invoice_Quantity__c = 1;
        testSILineLater.Unit_Price__c = 2000;//KNDY-14371
        testSILineLater.Accounting_Segment__c = testAccountingDefault.id;
        testSILineLater.Item__c = fuel.itemList[1].id; 
        
        insert testSILineLater; 
    	//APForecastExtTestData();
    	APForecastExt con = new APForecastExt();
    	pageReference pr = page.APForecast;
    	test.startTest();
    	 Test.setCurrentPage(pr);
    	 //APForecastExtTestData();
    	 con.getAPForecastData();    	
    	 system.assertEquals(con.currentTotal, 350);
    	system.assertEquals(con.laterTotal,2000);
    	system.assertEquals(con.previousTotal, 70);
    	system.assertEquals(con.priorAmountTotal, 500);
    	test.stopTest();

    }

    static testMethod void testCustomReportGen(){
    	        TestFuel fuel = new TestFuel();     
        
        Company__c testComp = fuel.Company; 
        Account testAccount = fuel.account; 
        GL_Type__c testExpenseGLType = fuel.expense; 
        Supplier__c testSupplier = fuel.supplier; 
        Supplier__c testSupplierRemitTo = fuel.supplier; 
        testSupplierRemitTo.Type__c = 'Remit To';
        List<Accounting_Rule__c> testAccRule = fuel.SuppInvAcctRulesList;
        Period__c testPeriod = fuel.periodList[0];
        update testSupplierRemitTo;

        Bank_Account__c bankAccount = new Bank_Account__c();
        bankAccount.Name = 'TESTBNK';
        bankAccount.Company__c = testComp.Id;
        insert bankAccount;



        List<GL_Type__c> glTypeList = new List<GL_Type__c>();
        GL_Type__c glType1 = fuel.otherIncome_expense;


        GL_Type__c glType2 = fuel.operatingExpense;
    
        
        List<GL_Account__c> glList = new List<GL_Account__c>();
        GL_Account__c glAccountRevenueA = new GL_Account__c();
        glAccountRevenueA.GL_Account_Number__c = '80003';
        glAccountRevenueA.GL_Account_Name__c = 'Revenue-A';
        glAccountRevenueA.active__c = true;
        glAccountRevenueA.Normal_Balance__c = 'Credit';
        glAccountRevenueA.Statement_Type__c = 'Income Statement';
        glAccountRevenueA.non_cash__c = false;
        glAccountRevenueA.gl_type__c = glType1.id;
        
        insert glAccountRevenueA;


        GL_Account__c glAccountRevenueB = new GL_Account__c();
        glAccountRevenueB.GL_Account_Number__c = '80002';
        glAccountRevenueB.GL_Account_Name__c = 'Revenue-A';
        glAccountRevenueB.active__c = true;
        glAccountRevenueB.Normal_Balance__c = 'Credit';
        glAccountRevenueB.Statement_Type__c = 'Income Statement';
        glAccountRevenueB.non_cash__c = false;
        glAccountRevenueB.gl_type__c = glType1.id;
        
        insert glAccountRevenueB;

        glList.add(glAccountRevenueA);
        glList.add(glAccountRevenueB);


        Accounting_Default__c testAccountingDefault = new Accounting_Default__c();
        testAccountingDefault.GL_Account__c = glAccountRevenueA.Id;
        insert testAccountingDefault;

        Supplier_Invoice__c testSIcurrent = new Supplier_Invoice__c();
        testSIcurrent.Company__c = testComp.id;
        testSIcurrent.Supplier__c = testSupplierRemitTo.id;
        testSIcurrent.Invoice_Amount__c = 350;
        testSIcurrent.Currency__c = TestFuel.currencyUSD.id;
        testSIcurrent.Invoice_Type__c = 'Invoice';
        testSIcurrent.Supplier_Invoice__c = system.today() + ': 123';
        testSIcurrent.Date_Invoiced__c = system.today();
        //testSIcurrent.Payment_Due_Date__c = system.today().addDays(5);

        insert testSIcurrent;

        Supplier_Invoice_Line__c testSILineCurrent = new Supplier_Invoice_Line__c();
        testSILineCurrent.Supplier_Invoice__c = testSIcurrent.id;
        testSILineCurrent.Invoice_Quantity__c = 1;
        testSILineCurrent.Unit_Price__c = 350;//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price
        testSILineCurrent.Accounting_Segment__c = testAccountingDefault.id;
        testSILineCurrent.Item__c = fuel.itemList[1].id; 
        insert testSILineCurrent;



        Supplier_Invoice__c testSIprevious = new Supplier_Invoice__c();
        testSIprevious.Company__c = testComp.id;
        testSIprevious.Supplier__c = testSupplierRemitTo.id;
        testSIprevious.Invoice_Amount__c = 70;
        testSIprevious.Currency__c = TestFuel.currencyUSD.id;
        testSIprevious.Invoice_Type__c = 'Invoice';
        testSIprevious.Supplier_Invoice__c = system.today() + ': 456';
        testSIprevious.Date_Invoiced__c = system.today().addDays(-7);
        //testSIprevious.Payment_Due_Date__c = system.today().addDays(-5);

        insert testSIprevious;

        Supplier_Invoice_Line__c testSILinePrevious = new Supplier_Invoice_Line__c();
        testSILinePrevious.Supplier_Invoice__c = testSIprevious.id;
        testSILinePrevious.Invoice_Quantity__c = 1;
        testSILinePrevious.Unit_Price__c = 70;
        testSILinePrevious.Accounting_Segment__c = testAccountingDefault.id;
        testSILinePrevious.Item__c = fuel.itemList[1].id; 
        insert testSILinePrevious;        


        Supplier_Invoice__c testSIprior = new Supplier_Invoice__c();
        testSIprior.Company__c = testComp.id;
        testSIprior.Supplier__c = testSupplierRemitTo.id;
        testSIprior.Invoice_Amount__c = 500;
        testSIprior.Currency__c = TestFuel.currencyUSD.id;
        testSIprior.Invoice_Type__c = 'Invoice';
        testSIprior.Supplier_Invoice__c = system.today() + ': 789';
        testSIprior.Date_Invoiced__c = system.today().addDays(-20);
        //testSIprior.Payment_Due_Date__c = system.today().addDays(-20);


        insert testSIprior; 

        Supplier_Invoice_Line__c testSILinePrior = new Supplier_Invoice_Line__c();
        testSILinePrior.Supplier_Invoice__c = testSIprior.id;
        testSILinePrior.Invoice_Quantity__c = 1;
        testSILinePrior.Unit_Price__c = 500;
        testSILinePrior.Accounting_Segment__c = testAccountingDefault.id;
        testSILinePrior.Item__c = fuel.itemList[1].id; 
        insert testSILinePrior; 


        Supplier_Invoice__c testSIlater = new Supplier_Invoice__c();
        testSIlater.Company__c = testComp.id;
        testSIlater.Supplier__c = testSupplierRemitTo.id;
        testSIlater.Invoice_Amount__c = 2000;
        testSIlater.Currency__c = TestFuel.currencyUSD.id;
        testSIlater.Invoice_Type__c = 'Invoice';
        testSIlater.Supplier_Invoice__c = system.today() + ': abc';
        testSIlater.Date_Invoiced__c = system.today().addDays(45);
        //testSIlater.Payment_Due_Date__c = system.today().addDays(45);

        insert testSIlater; 

        Supplier_Invoice_Line__c testSILineLater = new Supplier_Invoice_Line__c();
        testSILineLater.Supplier_Invoice__c = testSIlater.id;
        testSILineLater.Invoice_Quantity__c = 1;
        testSILineLater.Unit_Price__c = 2000;
        testSILineLater.Accounting_Segment__c = testAccountingDefault.id;
        testSILineLater.Item__c = fuel.itemList[1].id; 
        
        insert testSILineLater; 
    	
    	APForecastExt con = new APForecastExt();
    	pageReference pr = page.APForecast;
    	test.startTest();
    	 Test.setCurrentPage(pr);
    	 //con.getAPForecastData();

    	con.customPreviousInteger = 45;
    	con.customFutureInteger = 45;
    	system.debug('MAKE SURE DATE IS SET: '+con.customPriorDate);
        //Test setting custom filters 

    	con.customDateGen();

    	system.assertEquals(con.enddate, system.today().addDays(45));
    	system.assertEquals(con.prevexpdate, system.today().addDays(-45));
        //Test setting filters back to normal/ out of the box
        con.resetCustomDateGenFilter();
        system.assertEquals(con.enddate, system.today().addDays(26));
        system.assertEquals(con.prevexpdate, system.today().addDays(-6));        
    	test.stopTest();
    }


}