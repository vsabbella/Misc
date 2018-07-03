trigger ProcessJob on Process_Job__c (before insert, before update) {
	
	if(DML.checkTriggerDispatch(Process_Job__c.getSobjectType())){return;}
	
	/***
	 * validate the preffered run hour field contains a valid string, so that 
	 * we do not have to check this in the master control program where bad data
	 * can cause more serious problems.
	 */
    Pattern singleHourMin = Pattern.compile('\\d{1,2}:\\d{1,2}'); 	// matches ===> 09:45
    Pattern ranges = Pattern.compile('((\\d{1,2}|\\d{1,2}-\\d{1,2}),?)*');	// matches ===> 3  | 3,4,5  | 10,11,12-13,22
    
    for ( Process_Job__c job : Trigger.new ) {
        if ( job.Preferred_Run_Hour__c != null ) {
            string hours = job.Preferred_Run_Hour__c.replaceAll('\\s','');
            if (singleHourMin.matcher( hours).matches() != true &&
                ranges.matcher( hours ).matches() != true ) 
            {
                job.Preferred_Run_Hour__c.addError(Label.Invalid_data);
            } 
        }
    }
	
}