@isTest
private with sharing class BankTransactionVoidCancelTest {
 
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
            custReceipt.Date_Received__c = system.now() - 25;
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
            
         
            BankTxnGrp =[select id,name,finalized__c,void_date__c from Bank_Transaction_Group__c where id in  (select bank_transaction_group__c from Bank_Transaction__c where ID IN :BankTxnList) LIMIT 1];
            system.assertEquals(BankTxnGrp.finalized__c,true,'Expecting BTB to be succesfully finalized.');             
        }
    }
       
    public static testMethod void testCanVoidBTG() {
         
        TestDataForBankTxns testData = new TestDataForBankTxns();
       // TestFuel fuel = new TestFuel();
        
        //Generate Accounting
        BankTransactionGroupAccounting btga = new BankTransactionGroupAccounting();
     
        Test.startTest();
        //Create Rules in testfuel
        system.assert(testData.fuel.BankTxnGrpAcctRulesList.size()>0);
        //Generate Accounting 
        //Reset mrules map so that it is repopulated with new rules giving correct segmentrefernces.
        AccountingRuleService.mAccountingRules  =  new Map<string, List<Accounting_Rule__c>>();
        btga = new BankTransactionGroupAccounting();//Load segment references again.
        btga.execute(testData.BankTxnList);
        List<Accounting_Entry__c> newAEs = new list<Accounting_Entry__c>(); 
       
        newAEs = [select id,name from Accounting_Entry__c 
               where Bank_Transaction_Group__c = :testData.BankTxnGrp.Id 
               and status__c='Active'
               and Has_Exceptions__c = false];
        system.assertNotEquals(newAEs.size(),0,'Expecting no exceptions rules are created.');    
        //Bank_transaction__c bt = [select bank_Transaction_group__c ,Amount__c, id,finalized__c from bank_transaction__c where id =:testData.BankTxnList[0].id ];
        Bank_transaction_group__c btg = [select id , finalized__c,Void_Date__c from bank_transaction_group__c where id =:testData.BankTxnGrp.Id  ];
        
         Test.stoptest();

         BankTransactionVoidCancelExt ext = new BankTransactionVoidCancelExt(new ApexPages.standardsetController(testData.BankTxnList));
         BankTransactionVoidCancelExt.voidCancelBankTransactionGroup(testData.BankTxnList[0].id, 'void',String.valueOf((System.now() - 10) .format('yyyy-MM-dd HH:mm:ss')));
         Bank_transaction_group__c BankTransactionGroup = [select id , finalized__c,status__c,Void__c, void_date__c from bank_transaction_group__c where id =:testData.BankTxnGrp.Id  ];
         system.assertEquals( 'Void',BankTransactionGroup.Status__c,'**'+testData.BankTxnList[0]);
            system.assertEquals(BankTransactionGroup.Void__c, true);
         system.assertEquals(BankTransactionGroup.Void_date__c.date(), System.today() - 10);
    }
        
    public static testMethod void testCannotCancelBTG() {
         
        TestDataForBankTxns testData = new TestDataForBankTxns();
       // TestFuel fuel = new TestFuel();
        
        //Generate Accounting
        BankTransactionGroupAccounting btga = new BankTransactionGroupAccounting();
     
        Test.startTest();
        //Create Rules in testfuel
        system.assert(testData.fuel.BankTxnGrpAcctRulesList.size()>0);
        //Generate Accounting 
        //Reset mrules map so that it is repopulated with new rules giving correct segmentrefernces.
        AccountingRuleService.mAccountingRules  =  new Map<string, List<Accounting_Rule__c>>();
        btga = new BankTransactionGroupAccounting();//Load segment references again.
        btga.execute(testData.BankTxnList);
        List<Accounting_Entry__c> newAEs = new list<Accounting_Entry__c>(); 
       
        newAEs = [select id,name from Accounting_Entry__c 
               where Bank_Transaction_Group__c = :testData.BankTxnGrp.Id 
               and status__c='Active'
               and Has_Exceptions__c = false];
        system.assertNotEquals(newAEs.size(),0,'Expecting no exceptions rules are created.');    
        Bank_transaction_group__c btg = [select id , finalized__c from bank_transaction_group__c where id =:testData.BankTxnGrp.Id  ];
        
        Test.stoptest();
        BankTransactionVoidCancelExt ext = new BankTransactionVoidCancelExt(new ApexPages.standardsetController(testData.BankTxnList));
        BankTransactionVoidCancelExt.voidCancelBankTransactionGroup(testData.BankTxnList[0].id, 'void',String.valueOf(System.now().format('yyyy-MM-dd HH:mm:ss')));
        Bank_transaction_group__c BankTransactionGroup = [select id , finalized__c,status__c,Void__c from bank_transaction_group__c where id =:testData.BankTxnGrp.Id  ];
            system.assertNotEquals( 'Cancelled',BankTransactionGroup.Status__c,'Cannot cancel because of accouting entry available.');
    }
        
        public static testMethod void testCanNotVoidBTG() {
         
        TestDataForBankTxns testData = new TestDataForBankTxns();
       // TestFuel fuel = new TestFuel();
        
        //Generate Accounting
        BankTransactionGroupAccounting btga = new BankTransactionGroupAccounting();
     
        Test.startTest();
        //Create Rules in testfuel
       
        List<Accounting_Entry__c> newAEs = new list<Accounting_Entry__c>(); 
       
        newAEs = [select id,name from Accounting_Entry__c 
               where Bank_Transaction_Group__c = :testData.BankTxnGrp.Id 
               and status__c='Active'
               and Has_Exceptions__c = false];
        system.assertEquals(newAEs.size(),0,'Expecting no accouting rules.');    
      
        Test.stoptest();
         BankTransactionVoidCancelExt ext = new BankTransactionVoidCancelExt(new ApexPages.standardsetController(testData.BankTxnList));
        testData.BankTxnList[0].Transaction_Date__c = System.now()-10;
        BankTransactionVoidCancelExt.voidCancelBankTransactionGroup(testData.BankTxnList[0].id, 'void',String.valueOf(System.now().format('yyyy-MM-dd HH:mm:ss')));
        Bank_transaction_group__c BankTransactionGroup = [select id , finalized__c,status__c,Void__c from bank_transaction_group__c where id =:testData.BankTxnGrp.Id  ];
            system.assertNOTEquals( 'Void',BankTransactionGroup.Status__c,'**'+testData.BankTxnList[0]);
            system.assertEquals(BankTransactionGroup.Void__c, false);
    }
        
    public static testMethod void testCanCancelBTG() {
         
        TestDataForBankTxns testData = new TestDataForBankTxns();
       // TestFuel fuel = new TestFuel();
        
        //Generate Accounting
        BankTransactionGroupAccounting btga = new BankTransactionGroupAccounting();
     
        Test.startTest();
       
        List<Accounting_Entry__c> newAEs = new list<Accounting_Entry__c>(); 
       
        newAEs = [select id,name from Accounting_Entry__c 
               where Bank_Transaction_Group__c = :testData.BankTxnGrp.Id 
               and status__c='Active'
               and Has_Exceptions__c = false];
        system.assertEquals(newAEs.size(),0,'Expecting no accouting rules.');    
      
        Test.stoptest();
         BankTransactionVoidCancelExt ext = new BankTransactionVoidCancelExt(new ApexPages.standardsetController(testData.BankTxnList));
           BankTransactionVoidCancelExt.voidCancelBankTransactionGroup(testData.BankTxnList[0].id, 'void',String.valueOf(System.now().format('yyyy-MM-dd HH:mm:ss')));
        Bank_transaction_group__c BankTransactionGroup = [select id , finalized__c,status__c,Void__c from bank_transaction_group__c where id =:testData.BankTxnGrp.Id  ];
            system.assertNOTEquals( 'Cancelled',BankTransactionGroup.Status__c,'**'+testData.BankTxnList[0]);
        
       
    }

}