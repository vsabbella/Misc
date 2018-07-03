@istest
public class BankTransactionGroupAccountingTest {
    public class TestDataForBankTxns{
        public Testfuel fuel = new Testfuel();
        public Bank_Transaction_Group__c BankTxnGrp  = new Bank_Transaction_Group__c();            
        public List<Bank_Transaction__c> BankTxnList = new list<Bank_Transaction__c>();

        public TestDataForBankTxns(){
  
            system.assert(fuel.periodList.size()>0);

 
            Bank_account__c ba= fuel.bankAccount;
            ba.Opening_balance__C = 100;
            ba.Balance_offset__c=50;
            ba.opening_balance_date__c = system.now().adddays(-30);
            update ba;
            
            Customer_Receipt__c custReceipt = new Customer_Receipt__c();
            custReceipt.Company__c = fuel.company.Id;
            custReceipt.Customer__c = fuel.customerParent.Id;
            custReceipt.Amount_Received__c = 100;
            custReceipt.bank_Account_2__c = ba.Id;
            custReceipt.Payment_Method_G__c = 'Check';
            custReceipt.Reference_Number__c = '1234';
            custReceipt.Date_Received__c = system.now();
            custReceipt.Type__c = 'Receipt';
            custReceipt.Currency__c = TestFuel.currencyUSD.id;
            insert custReceipt; 
            
            Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();
            additionalPayment.Amount__c = 100;
            additionalPayment.Customer_Receipt__c = custReceipt.Id;
            additionalPayment.Type__c = PaymentService.TYPE_PREPAYMENT;
            insert additionalPayment;
            
            custReceipt.Finalized__c = true;
            update custReceipt;
        
            Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = custReceipt.Date_Received__c , 
                                                           Bank_Account__c = ba.Id,subtransaction_type__c ='Credit');
            insert bt;
            BT = [Select id,name,bank_transaction_group__c from Bank_Transaction__c where id = :bt.id];
           BankTxnList.add(bt);
       
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Customer_Receipt__c = custReceipt.Id, Amount__c = 100);
        insert btm;
            
            //Create BT
            /*BankTxnList = fuel.bankTransactions;
            system.assertNotEquals(BankTxnList.size(),0,'Expecting Bank txns.');
            
            
            for(Bank_Transaction__c bt:BankTxnList){
                bt.Bank_Transaction_Group__c=BankTxnGrp.Id;
            }
            update BankTxnList;*/
                //Create BTG
                //Commenting this flow as BT insert automatically BTG.
           /* BankTxnGrp.name = 'BTG-01';
            BankTxnGrp.Transaction_Type__c = 'Standard';
            BankTxnGrp.Currency__c = TestFuel.currencyUSD.id;
            BankTxnGrp.Transaction_Date__c=system.now();
            BankTxnGrp.Company__c=fuel.company.id;
            insert BankTxnGrp;
            
            bt.Bank_Transaction_Group__c = BankTxnGrp.Id;
            update bt; 
            BankTxnList.add(bt);
          
            BankTxnGrp.Finalized__c=true;
            update BankTxnGrp;*/
            BankTxnGrp =[select id,name,finalized__c from Bank_Transaction_Group__c where id in  (select bank_transaction_group__c from Bank_Transaction__c where ID IN :BankTxnList) LIMIT 1];
            system.assertEquals(BankTxnGrp.finalized__c,true,'Expecting BTB to be succesfully finalized.');             
        }
       
    }
    public static testMethod void testBTGAccounting() {
         
        TestDataForBankTxns testData = new TestDataForBankTxns();
   
        Test.startTest();
        //Generate Accounting
        BankTransactionGroupAccounting btga = new BankTransactionGroupAccounting();
        btga.execute(testData.BankTxnList);
        List<Accounting_Entry__c> AEs = new list<Accounting_Entry__c>(); 
        AEs = [select id,name from Accounting_Entry__c 
               where Bank_Transaction_Group__c = :testData.BankTxnGrp.Id 
               and status__c='Active'
               and Has_Exceptions__c = true];
        system.assertNotEquals(AEs.size(),0,'Expecting excpetions as no rules are created.');
        
        //Create Rules in testfuel
        system.assert(testData.fuel.BankTxnGrpAcctRulesList.size()>0);
        //Generate Accounting 
        //Reset mrules map so that it is repopulated with new rules giving correct segmentrefernces.
        AccountingRuleService.mAccountingRules  =  new Map<string, List<Accounting_Rule__c>>();
        btga = new BankTransactionGroupAccounting();//Load segment references again.
        btga.execute(testData.BankTxnList);
        List<Accounting_Entry__c> newAEs = new list<Accounting_Entry__c>(); 
       /* list<task> exceptiontasks = [select id,description from task where whatid in :newAEs];
        system.assertEqual(exceptiontasks,null);*/
        newAEs = [select id,name from Accounting_Entry__c 
               where Bank_Transaction_Group__c = :testData.BankTxnGrp.Id 
               and status__c='Active'
               and Has_Exceptions__c = false];
        system.assertNotEquals(newAEs.size(),0,'Expecting no exceptions rules are created.');    
        Test.stoptest();
    }
    public static testMethod void testBTAccountingListView(){
        testDataForBankTxns testData = new testDataForBankTxns();
         system.assert(testData.fuel.BankTxnGrpAcctRulesList.size()>0);        
         Test.startTest();
            Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(testdata.BankTxnList);        
            setcon.setSelected(testdata.BankTxnList);
           BankTransactionAccountingExt BAcctExt = new BankTransactionAccountingExt(setcon);
            BAcctExt.generateBankTransactionAccounting();
        Test.stoptest();
        List<Accounting_Entry__c> newAEs = new list<Accounting_Entry__c>(); 
        newAEs = [select id,name from Accounting_Entry__c 
                   where Bank_Transaction_Group__c = :testData.BankTxnGrp.Id 
                   and status__c='Active'
                   and Has_Exceptions__c = false];
        system.assertNotEquals(newAEs.size(),0,'Expecting no exceptions as rules are created.');    
    }
    public static testMethod void testBTGAccountingListView(){
        testDataForBankTxns testData = new testDataForBankTxns();
         system.assert(testData.fuel.BankTxnGrpAcctRulesList.size()>0);        
         Test.startTest();
            Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(new list<Bank_Transaction_Group__c>{testdata.BankTxnGrp});        
            setcon.setSelected(new list<Bank_Transaction_Group__c>{testdata.BankTxnGrp});
            BankTransactionGroupAccountingExt BAcctExt = new BankTransactionGroupAccountingExt(setcon);
            BAcctExt.generateBankTransactionGroupAccounting();
        Test.stoptest();
        List<Accounting_Entry__c> newAEs = new list<Accounting_Entry__c>(); 
        newAEs = [select id,name from Accounting_Entry__c 
                   where Bank_Transaction_Group__c = :testData.BankTxnGrp.Id 
                   and status__c='Active'
                   and Has_Exceptions__c = false];
        system.assertNotEquals(newAEs.size(),0,'Expecting no exceptions as rules are created.');    
    }
    public static testMethod void testBTGAccountingBatch(){
        TestDataForBankTxns testData = new TestDataForBankTxns();
        system.assert(testData.fuel.BankTxnGrpAcctRulesList.size()>0);        
        Test.startTest();        
            BankTransactionGroupAccountingBatch BTGBatch = new BankTransactionGroupAccountingBatch(new set<id>{testData.fuel.company.id});
            Database.executeBatch(BTGBatch);
        Test.stoptest();
       
        List<Accounting_Entry__c> newAEs = new list<Accounting_Entry__c>(); 
        newAEs = [select id,name from Accounting_Entry__c 
                   where Bank_Transaction_Group__c = :testData.BankTxnGrp.Id 
                   and status__c='Active'
                   and Has_Exceptions__c = false];
        system.assertNotEquals(newAEs.size(),0,'Expecting no exceptions as  rules are created.');    
    }   
      
}