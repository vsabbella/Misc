public with sharing class BudgetLineTriggerHandler {
    public static void assignBudgetLineUniqueKeys(){
    	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
    		BudgetLineService.assignBudgetLineUniqueKeys(trigger.new);
    	}
    }
}