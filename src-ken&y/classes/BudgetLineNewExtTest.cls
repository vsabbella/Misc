@isTest
private class BudgetLineNewExtTest {
    //----# Verify the budget Line is created-------#
    static testMethod void testNewBudgetLine() {
        TestFuel testData           = new TestFuel();
        List<Period__c> periodList = testData.periodList;
        
        test.startTest();
            
            Budget__c newBudget = new Budget__c(Company__c=TestData.company.Id,
                                          Budget_From__c=periodList[0].Id,Budget_To__c=periodList[1].Id);
            insert newBudget;
            Apexpages.StandardController budgetLineCon        
                                         = new Apexpages.StandardController(new Budget_Line1__c(Budget__c=newBudget.Id));
            test.setCurrentPage(page.BudgetLineNew);
            BudgetLineNewExt budLineObj = new BudgetLineNewExt(budgetLineCon); 
            budLineObj.save();
            
            List<Budget_Line1__c> budgetLines =   [SELECT id,name
                                                      FROM Budget_Line1__c 
                                                      WHERE Company__r.Id=:TestData.company.Id];   
        test.stopTest();
        
         system.assertEquals(budgetLines.size()>0,true);
          
    }
}