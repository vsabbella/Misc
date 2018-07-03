@isTest
private class BudgetCloneExtTest {
    //----# Verify the budget clone-------#
    static testMethod void testBudgetClone() {
       test.startTest();
            Apexpages.StandardController budgetCon        
                                         = new Apexpages.StandardController(new Budget__c());
            test.setCurrentPage(Page.BudgetClone);
            BudgetCloneExt budObj = new BudgetCloneExt(budgetCon);  
            
            budObj.errMsg();
            system.assert( Apexpages.hasMessages() == true , Apexpages.getMessages() );
             
      test.stopTest();
    }
}