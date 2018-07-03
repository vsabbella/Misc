@isTest
private class BudgetDeleteExtTest {
    //----# Verify the budget and its lines re deleted-------#
    static testMethod void testDeleteBudgetNdLines() {
        TestFuel testData           = new TestFuel();
        List<Period__c> periodList = testData.periodList;
        
        test.startTest();
        
            Budget__c bdjToDelete = new Budget__c(Company__c=TestData.company.Id,
                                          Budget_From__c=periodList[0].Id,Budget_To__c=periodList[1].Id);
            insert bdjToDelete;
            Apexpages.StandardController budgetCon        
                                         = new Apexpages.StandardController(bdjToDelete);
            test.setCurrentPage(page.BudgetDelete);
            BudgetDeleteExt deleteObj = new BudgetDeleteExt(budgetCon); 
            deleteObj.deletebudget();
            
            
            
        test.stopTest();
        
      List<Budget__c> budgets =   [SELECT id,name,Company__c 
                                          FROM Budget__c 
                                          WHERE Id=:bdjToDelete.Id];
                                          
      system.assert(budgets.size()==0, 'Expected the  Budget record to be removed');    
    }
    
    
 }