@isTest
public class BankTransactionMatchingRulesExtTest {
    public void  BankTransactionMatchingRulesExtTest(){}
    static TestFuel fuel = new TestFuel();
    
    Class BTMRData{
        List<Transaction_Matching_Rule__c> btmrList { 
            get{
                btmrList = new list<Transaction_Matching_Rule__c> ();
                Transaction_Matching_Rule__c btmr1 = new Transaction_Matching_Rule__c();
                btmr1.Company__c = fuel.company.id;
                btmr1.Bank_Account__c = fuel.bankAccount.id;
                btmr1.Documents__c = 'Customer Receipts, Supplier Payments';
                btmr1.Start_Date__c = system.today()+2;
                btmr1.Amount__c = true;
                btmr1.Amount_Threshold__c = 100.00;
                btmr1.Transaction_Date__c = True;
                btmr1.Date_Threshold__c	 = 5;
                btmr1.Reference__c  = True;
                btmr1.Keep_In_Match_Pool__c = True;
                btmr1.Auto_Approve__c = False;
                btmrList.add(btmr1);
                
                Transaction_Matching_Rule__c btmr2 = new Transaction_Matching_Rule__c();
                btmr2.Company__c = fuel.company.id;
                btmr2.Bank_Account__c = fuel.bankAccount.id;
                btmr2.Documents__c = 'Customer Receipts';
                btmr2.Start_Date__c = system.today();
                btmr2.Amount__c = true;
                btmr2.Amount_Threshold__c = 100.00;
                btmr2.Transaction_Date__c = true;
                btmr2.Date_Threshold__c	 = 5;
                btmr2.Transacted_With__c  = True;
                btmr2.Keep_In_Match_Pool__c = False;
                btmr2.Auto_Approve__c = True;
                btmrList.add(btmr2);
                
                insert btmrList; 
                
                return btmrList;
            }
            set;
        }
    }
    
    static testMethod void insertMultipleAtATime() {
    	list<Transaction_Matching_Rule__c> btmrList = new list<Transaction_Matching_Rule__c> ();
                Transaction_Matching_Rule__c btmr1 = new Transaction_Matching_Rule__c();
                btmr1.Company__c = fuel.company.id;
                btmr1.Bank_Account__c = fuel.bankAccount.id;
                btmr1.Documents__c = 'Customer Receipts, Supplier Payments';
                btmr1.Start_Date__c = system.today()-50;
                btmr1.End_Date__c = system.today()-20;
                btmr1.Amount__c = true;
                btmr1.Amount_Threshold__c = 100.00;
                btmr1.Transaction_Date__c = True;
                btmr1.Date_Threshold__c	 = 5;
                btmr1.Reference__c  = True;
                btmr1.Keep_In_Match_Pool__c = True;
                btmr1.Auto_Approve__c = False;
                btmrList.add(btmr1);
                
                Transaction_Matching_Rule__c btmr2 = new Transaction_Matching_Rule__c();
                btmr2.Company__c = fuel.company.id;
                btmr2.Bank_Account__c = fuel.bankAccount.id;
                btmr2.Documents__c = 'Customer Receipts';
                btmr2.Start_Date__c = system.today()-3;
                btmr2.End_Date__c = system.today()+20;
                btmr2.Amount__c = true;
                btmr2.Amount_Threshold__c = 100.00;
                btmr2.Transaction_Date__c = true;
                btmr2.Date_Threshold__c	 = 5;
                btmr2.Reference__c  = True;
                btmr2.Keep_In_Match_Pool__c = True;
                btmr2.Auto_Approve__c = False;
                btmrList.add(btmr2);
                
                JSONResult result=  BankTransactionMatchingRulesExt.upsertRule(btmrList,new List<String>());        
        		system.assertEquals(result.success,true, result.messages);
                btmrList = [Select Id from Transaction_Matching_Rule__c];
                system.assertEquals(2,btmrList.size());
    }
    
    static testMethod void insertMultipleAtATime_oneWithRankSpecified() {
    	list<Transaction_Matching_Rule__c> btmrList = new list<Transaction_Matching_Rule__c> ();
                Transaction_Matching_Rule__c btmr1 = new Transaction_Matching_Rule__c();
                btmr1.Company__c = fuel.company.id;
                btmr1.Bank_Account__c = fuel.bankAccount.id;
                btmr1.Documents__c = 'Customer Receipts, Supplier Payments';
                btmr1.Start_Date__c = system.today()-1;
                btmr1.Amount__c = true;
                btmr1.Amount_Threshold__c = 100.00;
                btmr1.Transaction_Date__c = True;
                btmr1.Date_Threshold__c	 = 5;
                btmr1.Reference__c  = True;
                btmr1.Keep_In_Match_Pool__c = True;
                btmr1.Auto_Approve__c = False;
                btmr1.Rank__c = 2;
                btmrList.add(btmr1);
                
                Transaction_Matching_Rule__c btmr2 = new Transaction_Matching_Rule__c();
                btmr2.Company__c = fuel.company.id;
                btmr2.Bank_Account__c = fuel.bankAccount.id;
                btmr2.Documents__c = 'Customer Receipts';
                btmr2.Start_Date__c = system.today()-3;
                btmr2.Amount__c = true;
                btmr2.Amount_Threshold__c = 100.00;
                btmr2.Transaction_Date__c = true;
                btmr2.Date_Threshold__c	 = 5;
                btmr2.Transacted_With__c  = True;
                btmr2.Keep_In_Match_Pool__c = False;
                btmr2.Auto_Approve__c = True;
                btmrList.add(btmr2);
                
                insert btmrList; 
                btmrList = [Select Id, Rank__c, is_active__c from Transaction_Matching_Rule__c order by Rank__c desc];
                system.assertEquals(2,btmrList.size());
                 system.assertEquals(true,  btmrList[0].is_active__c);
                system.assertEquals(2, btmrList[0].Rank__c,  btmrList[0].is_active__c);
                
    }
    
    static testMethod void dummyTestForCoverage(){

		BTMRData data = new BTMRData();
		ApexPages.StandardController setCon = new Apexpages.StandardController(data.btmrList[1]); 
		BankTransactionMatchingRulesExt bnkTrnMatch = new BankTransactionMatchingRulesExt(setCon);
		bnkTrnMatch.getbtmrFieldList();
        bnkTrnMatch.getBTMrGridConfigJson();
        bnkTrnMatch.getRuleHeaderFieldList();
        bnkTrnMatch.getRuleMatchingFieldList();
        bnkTrnMatch.getRuleAdditionalFieldList();
		Test.startTest();
		Transaction_Matching_Rule__c btmr = new Transaction_Matching_Rule__c(Company__c = fuel.company.id,Bank_Account__c = fuel.bankAccount.id,Start_Date__c = System.Today()-10,
                                                                             Reference__c  = True,Documents__c = 'Customer Receipts, Supplier Payments',Auto_Approve__c = True);
        insert btmr;
        JsonResult result = BankTransactionMatchingRulesExt.getRule(btmr.Id);
        
		List<String> dateFields = new List<String>();
        {
			dateFields.add('Start_Date__c');
            dateFields.add('End_Date__c');
        }
        
        JsonResult jr = BankTransactionMatchingRulesExt.getBTMRs(); 
        DataSourceResult dsresult = new DataSourceResult();
        List<BankTransactionMatchingRulesExt.BankTransactionMatchingRule> lstBTMRWrapper =  (List<BankTransactionMatchingRulesExt.BankTransactionMatchingRule>)jr.records;
        dsresult = BankTransactionMatchingRulesExt.saveBTMRs(lstBTMRWrapper, dateFields);
        Test.stopTest();
	}
    
    static testMethod void TestgetBTMRs(){
        BTMRData i = new BTMRData();
        Integer countRecs = i.btmrList.size();
        JsonResult jr =  BankTransactionMatchingRulesExt.getBTMRs();
        system.assertequals( jr.records.size(),countRecs );
      
        // check rank should not be assigned to inactive rule
        decimal rankassigned = 100;
        boolean flagInactiverecordavailable = false;
        Test.startTest();
        for(BankTransactionMatchingRulesExt.BankTransactionMatchingRule   tmr:(List<BankTransactionMatchingRulesExt.BankTransactionMatchingRule>)jr.records){
            System.debug(logginglevel.info,'Active/Not-->'+tmr.banktransactionmatchingrule.is_active__c);
            if(tmr.banktransactionmatchingrule.is_active__c == false){
                rankassigned= tmr.banktransactionmatchingrule.rank__c;
                flagInactiverecordavailable = true; 
                break;
            }
        }
        system.assertequals(flagInactiverecordavailable,true); 
        system.assertequals(rankassigned,null);
        Test.stopTest();
    }
    static testMethod void TestsaveBTMRs(){
        BTMRData i = new BTMRData();
        Integer countRecs = i.btmrList.size();
        JsonResult jr =  BankTransactionMatchingRulesExt.getBTMRs();
        decimal  count = 100;
        Test.startTest();
        List<BankTransactionMatchingRulesExt.BankTransactionMatchingRule> tmrListtoIns = new List<BankTransactionMatchingRulesExt.BankTransactionMatchingRule>();
        for(BankTransactionMatchingRulesExt.BankTransactionMatchingRule   tmr:(List<BankTransactionMatchingRulesExt.BankTransactionMatchingRule>)jr.records){
            tmr.banktransactionmatchingrule.rank__c = count;
            count=count+1;       
            tmrListtoIns.add(tmr);
        }
        
        DataSourceResult result=  BankTransactionMatchingRulesExt.saveBTMRs(tmrListtoIns, new list<String> {'Start_Date__c','End_Date__c'});
        system.assertEquals(true,result.success);
        Test.stopTest();
    } 

    static testMethod void TestUpsertBTMR(){
        BTMRData i = new BTMRData();
        Integer countRecs = i.btmrList.size();
        JsonResult jr =  BankTransactionMatchingRulesExt.getBTMRs();
        Transaction_Matching_Rule__c   tmr1 = ((BankTransactionMatchingRulesExt.BankTransactionMatchingRule)(jr.records[0])).banktransactionmatchingrule;
        tmr1.Transacted_With__c = false;
        Test.startTest();
        list<Transaction_Matching_Rule__c> lBTMRs = (new list<Transaction_Matching_Rule__c> {tmr1});
        JSONResult upsertResult =  BankTransactionMatchingRulesExt.upsertRule(lBTMRs,new List<String>());
        system.assert(upsertResult.success,true);
        Test.stopTest();
      }

      static testMethod void BankTransaction_RuleCreation_Fail1() {
          Transaction_Matching_Rule__c btmr = new Transaction_Matching_Rule__c(Company__c = fuel.company.id,Bank_Account__c = fuel.bankAccount.id,
                                                                              Documents__c = 'Customer Receipts, Supplier Payments',Start_Date__c = system.today(),
                                                                              Auto_Approve__c = True,Keep_In_Match_Pool__c = True);
          try {
              insert btmr;
          }catch(Exception ex) {
              system.assert(ex.getMessage().contains('Cannot set both Keep in Match Pool and Auto Approve')); 
          }
          
          
          list<Transaction_Matching_Rule__c> ltmr = [select Id, Is_Active__c from Transaction_Matching_Rule__c where id = :btmr.Id];
          system.assertEquals(0, ltmr.size());
      }  
    
      static testMethod void startDateIsRequired() {
          boolean exceptionflag = false;
          Transaction_Matching_Rule__c btmr = new Transaction_Matching_Rule__c(Company__c = fuel.company.id,Bank_Account__c = fuel.bankAccount.id,
                                                                             Documents__c = 'Customer Receipts, Supplier Payments',Auto_Approve__c = True);
          try {
              insert btmr;
          }catch(Exception ex) {
              system.assert(ex.getMessage().contains('Start Date is required'));
             exceptionflag=true;
         }
         system.assertEquals(true, exceptionflag);
      }
      //KNDY-15788
      static testMethod void checkDuplicates_Amount() {
      	String expectedErrorMessage = Label.Change_dates_on_IGR;
    	list<Transaction_Matching_Rule__c> btmrList = new list<Transaction_Matching_Rule__c> ();
        Transaction_Matching_Rule__c btmr1 = new Transaction_Matching_Rule__c();
        btmr1.Company__c = fuel.company.id;
        btmr1.Bank_Account__c = fuel.bankAccount.id;
        btmr1.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr1.Start_Date__c = system.today()-1;
        btmr1.Amount__c = true;
        btmr1.Amount_Threshold__c = 100.00;
        btmr1.Rank__c = 2;
        
        insert btmr1;
        
        Test.startTest();
        Transaction_Matching_Rule__c btmr2 = new Transaction_Matching_Rule__c();
        btmr2.Company__c = fuel.company.id;
        btmr2.Bank_Account__c = fuel.bankAccount.id;
        btmr2.Documents__c = 'Customer Receipts';
        btmr2.Start_Date__c = system.today()-10;
        btmr2.Amount__c = true;
        btmr2.Amount_Threshold__c = 100.00;
        btmrList.add(btmr2);
        
        JSONResult result=  BankTransactionMatchingRulesExt.upsertRule(btmrList,new List<String>());
        
        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage), result.messages);
        }
        btmrList = [Select Id, Rank__c, is_active__c from Transaction_Matching_Rule__c order by Rank__c desc];
        system.assertEquals(1,btmrList.size());
        system.assertEquals(true,  btmrList[0].is_active__c);
        system.assertEquals(2, btmrList[0].Rank__c,  btmrList[0].is_active__c);
        Test.stopTest();       
    }
    //KNDY-15788
    static testMethod void checkDuplicates_ReferenceDateKeepinTouch() {
    	BTMRData data = new BTMRData();
    	list<Transaction_Matching_Rule__c> btmrList = new list<Transaction_Matching_Rule__c> ();
    	btmrList = [Select Id, Rank__c, is_active__c from Transaction_Matching_Rule__c order by Rank__c desc];
    	Integer countRecs = data.btmrList.size();
        system.assertEquals(2, countRecs);
        
      	String expectedErrorMessage = Label.Change_dates_on_IGR;
    	btmrList = new list<Transaction_Matching_Rule__c> ();
        Transaction_Matching_Rule__c btmr1 = new Transaction_Matching_Rule__c();
        btmr1.Company__c = fuel.company.id;
        btmr1.Bank_Account__c = fuel.bankAccount.id;
        btmr1.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr1.Start_Date__c = system.today()-30;
        btmr1.End_Date__c = system.today()+10;
        btmr1.Amount__c = true;
        btmr1.Amount_Threshold__c = 100.00;
        btmr1.Transaction_Date__c = True;
        btmr1.Date_Threshold__c	 = 5;
        btmr1.Reference__c  = True;
        btmr1.Keep_In_Match_Pool__c = True;
        btmr1.Auto_Approve__c = False;
        
        btmrList.add( btmr1);
        
        Test.startTest();
        
        
        JSONResult result=  BankTransactionMatchingRulesExt.upsertRule(btmrList,new List<String>());
        
        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage), result.messages);
        }
        btmrList = [Select Id, Rank__c, is_active__c from Transaction_Matching_Rule__c order by Rank__c desc];
        system.assertEquals(2,btmrList.size());
        Test.stopTest();       
    }
    //KNDY-15788
    static testMethod void checkDuplicates_ReferenceDateKeepinTouch1() {
    	list<Transaction_Matching_Rule__c> btmrList = new list<Transaction_Matching_Rule__c> ();
    
      	String expectedErrorMessage = Label.Change_dates_on_IGR;
    	btmrList = new list<Transaction_Matching_Rule__c> ();
        Transaction_Matching_Rule__c btmr1 = new Transaction_Matching_Rule__c();
        btmr1.Company__c = fuel.company.id;
        btmr1.Bank_Account__c = fuel.bankAccount.id;
        btmr1.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr1.Start_Date__c = system.today()-30;
        btmr1.End_Date__c = system.today()+10;
        btmr1.Amount__c = true;
        btmr1.Amount_Threshold__c = 100.00;
        btmr1.Transaction_Date__c = True;
        btmr1.Date_Threshold__c	 = 5;
        btmr1.Reference__c  = True;
        btmr1.Keep_In_Match_Pool__c = True;
        btmr1.Auto_Approve__c = False;
        
        insert btmr1;
        
        Transaction_Matching_Rule__c btmr2 = new Transaction_Matching_Rule__c();
        btmr2.Company__c = fuel.company.id;
        btmr2.Bank_Account__c = fuel.bankAccount.id;
        btmr2.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr2.Start_Date__c = system.today()-10;
        btmr2.End_Date__c = null;
        btmr2.Amount__c = false;
        btmr2.Transaction_Date__c = false;
        btmr2.Reference__c  = false;
        btmr2.Keep_In_Match_Pool__c = false;
        btmr2.Auto_Approve__c = true;
        btmrList.add( btmr2);
        Test.startTest();
        
        
        JSONResult result=  BankTransactionMatchingRulesExt.upsertRule(btmrList,new List<String>());
        
       
        //btmrList = [Select Id, Rank__c, is_active__c from Transaction_Matching_Rule__c order by Rank__c desc];
        //system.assertEquals(2,btmrList.size());
        
        btmr2 = btmrList[0];
        btmr2.End_Date__c = system.today()+10;
        btmr2.Amount__c = true;
        btmr2.Amount_Threshold__c = 100.00;
        btmr2.Transaction_Date__c = True;
        btmr2.Date_Threshold__c	 = 5;
        btmr2.Reference__c  = True;
        btmr2.Keep_In_Match_Pool__c = True;
        btmr2.Auto_Approve__c = False;
        btmrList = new list<Transaction_Matching_Rule__c> ();
        btmrList.add(btmr2);
        result=  BankTransactionMatchingRulesExt.upsertRule(btmrList,new List<String>());
        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage), result.messages);
        }
        Test.stopTest();       
    }
    //KNDY-15788
    static testMethod void checkDuplicatesByCriteria() {
    	list<Transaction_Matching_Rule__c> btmrList = new list<Transaction_Matching_Rule__c> ();
    
      	String expectedErrorMessage = Label.Change_dates_on_IGR;
    	btmrList = new list<Transaction_Matching_Rule__c> ();
        Transaction_Matching_Rule__c btmr1 = new Transaction_Matching_Rule__c();
        btmr1.Company__c = fuel.company.id;
        btmr1.Bank_Account__c = fuel.bankAccount.id;
        btmr1.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr1.Start_Date__c = system.today()-30;
        btmr1.Amount__c = true;
        btmr1.Amount_Threshold__c = 100.00;
        btmr1.Transaction_Date__c = True;
        btmr1.Date_Threshold__c	 = 5;
        btmr1.Reference__c  = True;
        btmr1.Keep_In_Match_Pool__c = false;
        btmr1.Auto_Approve__c = false;
        
        insert btmr1;
        //test for diff input for amount threshold
        Transaction_Matching_Rule__c btmr2 = new Transaction_Matching_Rule__c();
        btmr2.Company__c = fuel.company.id;
        btmr2.Bank_Account__c = fuel.bankAccount.id;
        btmr2.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr2.Start_Date__c = system.today()-10;
        btmr2.End_Date__c = null;
        btmr2.Amount__c = true;
        btmr2.Amount_Threshold__c = 101.00;   
        btmr2.Transaction_Date__c = true;    
        btmr2.Date_Threshold__c	 = 5;
        btmr2.Reference__c  = true;
        btmr2.Keep_In_Match_Pool__c = false;
        btmr2.Auto_Approve__c = false;
        btmrList.add( btmr2);
        
        Test.startTest();
        JSONResult result=  BankTransactionMatchingRulesExt.upsertRule(btmrList,new List<String>());
        system.assertEquals(result.success,true, result.messages);
        system.debug('btmr2='+btmr2);
      
		//test for diff transaction date criteria
        btmr2 = btmrList[0];
        system.debug('btmr2**1='+btmr2);
        btmr2.Amount_Threshold__c = 100.00;
        btmr2.Transaction_Date__c = true;
        btmr2.Date_Threshold__c	 = 4;
        btmrList = new list<Transaction_Matching_Rule__c> ();
        btmrList.add(btmr2);
        result=  BankTransactionMatchingRulesExt.upsertRule(btmrList,new List<String>());
        system.assertEquals(result.success,true, result.messages);
        
        //test for diff reference criteria
        btmr2.Transaction_Date__c = true;
        btmr2.Date_Threshold__c	 = 5;
        result=  BankTransactionMatchingRulesExt.upsertRule(new list<Transaction_Matching_Rule__c> {btmr2},new List<String>());
        system.assertEquals(result.success,false, result.messages);
        
        
        
        Test.stopTest();       
    }
    //KNDY-15788
    static testMethod void checkDuplicatesOnDates() {
    	list<Transaction_Matching_Rule__c> btmrList = new list<Transaction_Matching_Rule__c> ();
    
      	String expectedErrorMessage = Label.Change_dates_on_IGR;
    	btmrList = new list<Transaction_Matching_Rule__c> ();
        Transaction_Matching_Rule__c btmr1 = new Transaction_Matching_Rule__c();
        btmr1.Company__c = fuel.company.id;
        btmr1.Bank_Account__c = fuel.bankAccount.id;
        btmr1.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr1.Start_Date__c = system.today()-30;
        btmr1.End_Date__c = system.today()+10;
        btmr1.Amount__c = true;
        btmr1.Amount_Threshold__c = 100.00;
        btmr1.Transaction_Date__c = True;
        btmr1.Date_Threshold__c	 = 5;
        btmr1.Reference__c  = True;
        btmr1.Keep_In_Match_Pool__c = True;
        btmr1.Auto_Approve__c = False;
        
        insert btmr1;
        
        Transaction_Matching_Rule__c btmr2 = new Transaction_Matching_Rule__c();
        btmr2.Company__c = fuel.company.id;
        btmr2.Bank_Account__c = fuel.bankAccount.id;
        btmr2.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr2.Start_Date__c = system.today()-10;
        btmr2.End_Date__c = null;
        btmr2.Amount__c = true;
        btmr2.Amount_Threshold__c = 100.00;
        btmr2.Transaction_Date__c = true;
        btmr2.Date_Threshold__c	 = 5;
        btmr2.Reference__c  = true;
        btmr2.Keep_In_Match_Pool__c = true;
        btmr2.Auto_Approve__c = false;
        btmrList.add( btmr2);
        Test.startTest();
        
        
        JSONResult result=  BankTransactionMatchingRulesExt.upsertRule(btmrList,new List<String>());

        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage), result.messages);
        }
        Test.stopTest();       
    }
             
    //KNDY-15788
    static testMethod void checkDuplicatesOnCompanyBank() {
    	list<Transaction_Matching_Rule__c> btmrList = new list<Transaction_Matching_Rule__c> ();
    
      	String expectedErrorMessage = Label.Change_dates_on_IGR;
      	
    	btmrList = new list<Transaction_Matching_Rule__c> ();
    	//without company and bank
    	Transaction_Matching_Rule__c btmr0 = new Transaction_Matching_Rule__c();   
        btmr0.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr0.Start_Date__c = system.today()-30;
        btmr0.End_Date__c = system.today()-20;
        btmr0.Amount__c = true;
        btmr0.Amount_Threshold__c = 100.00;
        btmr0.Transaction_Date__c = True;
        btmr0.Date_Threshold__c	 = 5;
        btmr0.Reference__c  = True;
        btmr0.Keep_In_Match_Pool__c = True;
        btmr0.Auto_Approve__c = False;
        
        insert btmr0;
        
    	//accross bank in same company
        Transaction_Matching_Rule__c btmr1 = new Transaction_Matching_Rule__c();
        btmr1.Company__c = fuel.company.id;        
        btmr1.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr1.Start_Date__c = system.today()-20;
        btmr1.End_Date__c = system.today()+10;
        btmr1.Amount__c = true;
        btmr1.Amount_Threshold__c = 100.00;
        btmr1.Transaction_Date__c = True;
        btmr1.Date_Threshold__c	 = 5;
        btmr1.Reference__c  = True;
        btmr1.Keep_In_Match_Pool__c = True;
        btmr1.Auto_Approve__c = False;
        
        btmrList.add( btmr1);
       
        Test.startTest();
        
        
        JSONResult result=  BankTransactionMatchingRulesExt.upsertRule(btmrList,new List<String>());
		system.assertEquals(result.success,true, result.messages);
		//with company and bank account
 		Transaction_Matching_Rule__c btmr2 = new Transaction_Matching_Rule__c();
        btmr2.Company__c = fuel.company.id;
        btmr2.Bank_Account__c = fuel.bankAccount.id;
        btmr2.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr2.Start_Date__c = system.today()-10;
        btmr2.End_Date__c = null;
        btmr2.Amount__c = true;
        btmr2.Amount_Threshold__c = 100.00;
        btmr2.Transaction_Date__c = true;
        btmr2.Date_Threshold__c	 = 5;
        btmr2.Reference__c  = true;
        btmr2.Keep_In_Match_Pool__c = true;
        btmr2.Auto_Approve__c = false;        
        result =  BankTransactionMatchingRulesExt.upsertRule( new List<Transaction_Matching_Rule__c>{btmr2},new List<String>());
        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage), result.messages);
        }
        
        //by diff company AND bank account
        Bank_Account__c altBA = new Bank_Account__c();
		altBA.Name = 'Test BOFA Savings';
		altBA.account_type__c = 'Saving';
		altBA.GL_Account__c = fuel.PPVGL.id;
		altBA.Company__c = fuel.altCompany.Id;
		altBA.Active__c = true;
		altBA.Currency__c = TestFuel.currencyUSD.id;
		
		insert altBA; 
        btmr2 = new Transaction_Matching_Rule__c();
        btmr2.Company__c = fuel.altCompany.id;
        btmr2.Bank_Account__c = altBA.id;
        btmr2.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr2.Start_Date__c = system.today()-10;
        btmr2.End_Date__c = null;
        btmr2.Amount__c = true;
        btmr2.Amount_Threshold__c = 100.00;
        btmr2.Transaction_Date__c = true;
        btmr2.Date_Threshold__c	 = 5;
        btmr2.Reference__c  = true;
        btmr2.Keep_In_Match_Pool__c = true;
        btmr2.Auto_Approve__c = false;    
        result =  BankTransactionMatchingRulesExt.upsertRule( new List<Transaction_Matching_Rule__c>{btmr2},new List<String>());
        system.assertEquals(result.success,true, result.messages);
        
        //by same company AND diff bank account
        Bank_Account__c bankAccount1 = new Bank_Account__c();
		bankAccount1.Name = 'Test BOFA Savings';
		bankAccount1.account_type__c = 'Saving';
		bankAccount1.GL_Account__c = fuel.allowanceExpGL.id;
		bankAccount1.Company__c = fuel.company.Id;
		bankAccount1.Active__c = true;
		bankAccount1.Currency__c = TestFuel.currencyUSD.id;
		
		insert bankAccount1; 
        btmr2 = new Transaction_Matching_Rule__c();
        btmr2.Company__c = fuel.Company.id;
        btmr2.Bank_Account__c = bankAccount1.id;
        btmr2.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr2.Start_Date__c = system.today()+10;
        btmr2.End_Date__c = null;
        btmr2.Amount__c = true;
        btmr2.Amount_Threshold__c = 100.00;
        btmr2.Transaction_Date__c = true;
        btmr2.Date_Threshold__c	 = 5;
        btmr2.Reference__c  = true;
        btmr2.Keep_In_Match_Pool__c = true;
        btmr2.Auto_Approve__c = false;    
        result =  BankTransactionMatchingRulesExt.upsertRule( new List<Transaction_Matching_Rule__c>{btmr2},new List<String>());
        system.assertEquals(result.success,true, result.messages);
        
        Test.stopTest();       
    }
    //KNDY-16113
    static testMethod void getCompanyInfofrombankTest() {
    	
        JSONResult result = null;
        Test.startTest(); 
        result=  BankTransactionMatchingRulesExt.getCompanyInfoFromBank(fuel.bankAccount.id);

        system.assertEquals(result.success,true, result.messages);
        system.assertEquals(result.records.size() ,1,result.records);
        Bank_Account__c  bankAcc = (Bank_Account__c) result.records[0];
        system.assertEquals(bankAcc.company__c ,fuel.company.id,result);
        result=  BankTransactionMatchingRulesExt.getCompanyInfoFromBank(null);

        system.assertEquals(result.success,false, result.messages);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(Label.No_records_found), result.messages);
        }
        Test.stopTest();       
    }
    
    static testMethod void UpdateDelBTMR_Fail(){ //KNDY-15794
        JSONResult result = null;
        Transaction_Matching_Rule__c btmr = new Transaction_Matching_Rule__c();
        btmr.Company__c = fuel.company.id;
        btmr.Bank_Account__c = fuel.bankAccount.id;
        btmr.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr.Start_Date__c = system.today()-10;
        btmr.End_Date__c = null;
        btmr.Amount__c = true;
        btmr.Amount_Threshold__c = 100.00;
        btmr.Transaction_Date__c = true;
        btmr.Date_Threshold__c	 = 5;
        btmr.Reference__c  = true;
        btmr.Keep_In_Match_Pool__c = true;
        btmr.Auto_Approve__c = false;        
        result = BankTransactionMatchingRulesExt.upsertRule( new List<Transaction_Matching_Rule__c>{btmr},new List<String>());
        system.assertEquals(result.success,true, result.messages);
        system.assert(result.messages.size() == 1);
        boolean error = false;
        BankTransactionMatchingRuleService.requestFromUI = false;
        Test.startTest();
        try{
        	btmr.Start_Date__c = system.today()-15;
        	update btmr;
        }catch(exception ex){
        	if(ex.getMessage().contains(Label.Can_t_update_delete_BTMR)){
        		error = true;
        	}
        }
        system.assert(error);
        error = false;
        
        try{
        	delete btmr;
        }catch(exception ex){
        	if(ex.getMessage().contains(Label.Can_t_update_delete_BTMR)){
        		error = true;
        	}
        }
        system.assert(error);
        
        result = new JsonResult();
        result = BankTransactionMatchingRulesExt.IsBTMRuleUsedForAutoMatch(btmr.Id);
        system.assertEquals(0,result.total);
        
        result = new JsonResult();
        result = BankTransactionMatchingRulesExt.IsBTMRuleUsedForAutoMatch(null);
        system.assertEquals(false,result.success);
        Test.stopTest();
	}    
	
	 static testMethod void UpdateDelBTMR_Success(){ //KNDY-15794
        JSONResult result = null;
        Transaction_Matching_Rule__c btmr = new Transaction_Matching_Rule__c();
        btmr.Company__c = fuel.company.id;
        btmr.Bank_Account__c = fuel.bankAccount.id;
        btmr.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr.Start_Date__c = system.today()-10;
        btmr.End_Date__c = null;
        btmr.Amount__c = true;
        btmr.Amount_Threshold__c = 100.00;
        btmr.Transaction_Date__c = true;
        btmr.Date_Threshold__c	 = 5;
        btmr.Reference__c  = true;
        btmr.Keep_In_Match_Pool__c = true;
        btmr.Auto_Approve__c = false;        
        result = BankTransactionMatchingRulesExt.upsertRule( new List<Transaction_Matching_Rule__c>{btmr},new List<String>());
        system.assertEquals(result.success,true, result.messages);
        system.assert(result.messages.size() == 1);
        boolean error = false;
        
        Test.startTest();
        btmr.Start_Date__c = system.today()-15;
        result = BankTransactionMatchingRulesExt.upsertRule( new List<Transaction_Matching_Rule__c>{btmr},new List<String>());
        system.assertEquals(result.success,true, result.messages);
        system.assert(result.messages.size() == 1);
        system.assert(!error);
        
        try{
        	delete btmr;
        }catch(exception ex){
        	if(ex.getMessage().contains(Label.Can_t_update_delete_BTMR)){
        		error = true;
        	}
        }
        system.assert(error);
        Test.stopTest();
	}   
}