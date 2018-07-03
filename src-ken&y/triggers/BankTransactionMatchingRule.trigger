trigger BankTransactionMatchingRule on Transaction_Matching_Rule__c (after delete, after insert, after undelete, 
                             after update, before delete, before insert, before update) {
        
        if(DML.checkTriggerDispatch(Transaction_Matching_Rule__c.getSobjectType())){return;}
        
        BankTransactionMatchingRuleService.populateThresholdValues();
        BankTransactionMatchingRuleService.checkDuplicates();                
        BankTransactionMatchingRuleService.setRankKey(); 
        BankTransactionMatchingRuleService.restrictUpdationAndDeletionOfBTMR();    //KNDY-15794
}