@isTest
private class BudgetNewExtTest {
    //----# Verify the budget is created-------#
    static testMethod void testNewBudget() {
        TestFuel testData           = new TestFuel();
        List<Period__c> periodList = testData.periodList;
        
        test.startTest();
        
            Apexpages.StandardController budgetCon        
                                         = new Apexpages.StandardController(new Budget__c());
            test.setCurrentPage(page.BudgetNew);
            BudgetNewExt budObj = new BudgetNewExt(budgetCon); 
            budObj.newObj = new Budget__c(Company__c=TestData.company.Id,
                                          Budget_From__c=periodList[0].Id,Budget_To__c=periodList[1].Id);
            budObj.save();
            
        test.stopTest();
        
      	List<Budget__c> budgets =   [SELECT id,name,Company__c 
                                          FROM Budget__c 
                                          WHERE Company__r.Id=:TestData.company.Id];
      	system.assert(budgets.size()>0, 'Expected a Budget record to be created');    
    } 
}