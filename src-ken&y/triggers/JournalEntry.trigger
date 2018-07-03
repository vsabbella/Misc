trigger JournalEntry on Journal_Entry__c (before insert, before update, before delete, after insert, after update) {
	
	if(DML.checkTriggerDispatch(Journal_Entry__c.getSobjectType())){return;}
	
	if(ExceptionService.ignoreTrigger('Journal_Entry__c')){return;}
	JournalEntryService JES = JournalEntryService.getInstance();
	
	//system.debug(logginglevel.info,'Inside the Trigger');
	if(trigger.isBefore ){
	    //system.debug(logginglevel.info,'Inside the isBefore loop in Trigger');
        if(Trigger.isInsert || Trigger.isUpdate){
            JES.setOrClearJEInformation(Trigger.new, trigger.oldmap);
           
            // set finalized hidden flag and validate user action of unfinalize
       		KSE.setValidateFinalizedFlagonSD();
       	
            // set finalized date on the journal entry
            //FIN-209 set finalized date on the customer invoice
			FinalizeService.setFinalizedDate(Trigger.new);
            
			
       	 	// This method also sets the Period on JEs
            List<Journal_Entry__c> JEList = new List<Journal_Entry__c>();
            List<Journal_Entry__c> YearEndJEList = new List<Journal_Entry__c>();
            List<Journal_Entry__c> YearEndAdjustmentJEList = new List<Journal_Entry__c>();

            
            for(Journal_Entry__c thisJE: Trigger.new){
       			Journal_Entry__c oldJE;
       			if(trigger.oldmap != null && trigger.oldmap.containskey(thisJE.id)){
       				oldJE = trigger.oldmap.get(thisJE.id);}
                if(thisJE.Type__c.equalsIgnoreCase('Year End') ||thisJE.Type__c.equalsIgnoreCase('Year End Adjustment')){
                    YearEndJEList.add(thisJE);
                }else{
                    JEList.add(thisJE);
                }
                
                if(thisJE.Type__c.equalsIgnoreCase('Year End Adjustment') && thisJE.finalized__c ){
                    YearEndAdjustmentJEList.add(thisJE);
                
                }

            }
			//KNDY-10186 - No spl casing for period assignment on JEs.
			if(JEList != null && JEList.size() > 0){
                PeriodService.assignGLDatePeriod(JEList);
            }
            
			if(YearEndAdjustmentJEList != null && YearEndAdjustmentJEList.size() > 0){
                JES.CheckYearEndEntry(YearEndAdjustmentJEList);
            }
        }

        if( Trigger.isUpdate ){
        	JES.ValidateJE((List<Journal_Entry__c> )Trigger.new, (List<Journal_Entry__c>) Trigger.old, (Map<Id,Journal_Entry__c>) Trigger.oldMap, Trigger.isUpdate, Trigger.isInsert);
			JournalEntryService.validateJEStatus(Trigger.old,Trigger.newMap);
		}
        
		if(trigger.isUpdate || trigger.isDelete){
       		//FIN-209 validate the header for finalize
			FinalizeService.validateHeaderFinalize();
		}
		if(trigger.isDelete){
			for(Journal_Entry__c thisJE: Trigger.old){
				if(thisJE.Type__c.equalsIgnoreCase('Recurring Journal') && thisJE.Recurring_Template__c != null){
					thisJE.addError('Recurring Journal can not be deleted');
				}
			}
		}
	}
        
	
	//FIN-329
	if(trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
    
        JournalEntryService.ValidateJEFields(trigger.new);
        JournalEntryService.OnUnfinalize();
        JournalEntryService.exService.finishTasks();
        
        JournalEntryService.validateJEFinalize(Trigger.new, (Map<Id,Journal_Entry__c>) Trigger.oldMap);
    }

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Journal_Entry__c> recWithoutCurrency = new List<Journal_Entry__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Journal_Entry__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Journal_Entry__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }    

}