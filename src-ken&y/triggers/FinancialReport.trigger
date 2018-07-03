trigger FinancialReport on Financial_Report__c (before insert, before update) {
	if(DML.checkTriggerDispatch(Financial_Report__c.getSobjectType())){return;}
	// KNDY-3520
    if ( trigger.isBefore && ( trigger.isInsert || trigger.isUpdate)) {
        for ( Financial_Report__c c: trigger.new ) {     
            if ( ! CompanyService.checkValidName(c.Introduction__c ) ) {
            	c.Introduction__c.addError(Label.Only_alphanumeric_characters_allowed); 
            }
            if ( ! CompanyService.checkValidName(c.Period_Name__c ) ) {
            	c.Period_Name__c.addError(Label.Only_alphanumeric_characters_allowed); 
            }
            if ( ! CompanyService.checkValidName(c.Name ) ) {
            	c.Name.addError(Label.Only_alphanumeric_characters_allowed); 
            }
        }
    }
}