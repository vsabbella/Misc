trigger AccountingEntry on Accounting_Entry__c (after update, before insert, before update, before delete, after insert) {
    
    if(DML.checkTriggerDispatch(Accounting_Entry__c.getSobjectType())){return;}
    
    if(ExceptionService.ignoreTrigger('Accounting_Entry__c')){return;}
    AccountingEntryService AES = AccountingEntryService.getInstance();
    
	Set<Id> companyIds = new set<Id>();
	Set<Date> periodStartDates = new Set<Date>();
   
        
    if(trigger.isAfter){
    	if(Trigger.isInsert || Trigger.isUpdate){
	        AccountingEntryService.ValidateAEFields(trigger.new);
	        AccountingEntryService.exService.finishTasks();
    	}
        
    	if(trigger.isUpdate){
    		for(Accounting_Entry__c thisAE: Trigger.new){
	        	if((KSE.isFieldChanging('status__c',thisAE,trigger.oldMap)) 
	        			&& (((Accounting_Entry__c) trigger.oldMap.get(thisAE.id)).get('status__c') == '' || ((Accounting_Entry__c) trigger.oldMap.get(thisAE.id)).get('status__c') == null)
	        			&& thisAE.status__c.equalsIgnoreCase('Active')
	        	){
	        		continue;
	        	}else if((thisAE.status__c == 'Active' || ((Accounting_Entry__c) trigger.oldMap.get(thisAE.id)).get('status__c') == 'Active') && thisAE.Subledger_Closed__c){
	        		thisAE.addError('You cannot update records in closed areas.');
	        	}
    		}
    	}
    	
    	if(trigger.isInsert){
    		for(Accounting_Entry__c thisAE: Trigger.new){
	    		if((thisAE.status__c == 'Active' || thisAE.status__c == 'Draft')
	    				&& thisAE.Subledger_Closed__c){
	    			thisAE.addError('You cannot insert records in closed areas.');
	    		}
    		}
    	}
       
    }
    
    // Logic to set exception flags on the header
    if(trigger.isBefore  ){
    	
        if(Trigger.isInsert || Trigger.isUpdate){
        	//List<Accounting_Entry__c> JEList = new List<Accounting_Entry__c>();
            List<Accounting_Entry__c> YearEndJEList = new List<Accounting_Entry__c>();
        	List<Accounting_Entry__c> nonYearEndJEList = new List<Accounting_Entry__c>();
        	AES.assignSourceKey(trigger.new);
			for(Accounting_Entry__c thisAE: Trigger.new){
				if(thisAE.Journal_Entry__c != null){
                    if(thisAE.Transaction_Type__c.equalsIgnoreCase('Year End') || thisAE.Transaction_Type__c.equalsIgnoreCase('Year End Adjustment')){
                        YearEndJEList.add(thisAE);
                    }else{
						nonYearEndJEList.add(thisAE);
                    }
				}else{
					nonYearEndJEList.add(thisAE);
				}
			}
			//KNDY-10186 - No spl casing for period assignment on JEs.			
			/*if(JEList != null && JEList.size() > 0){
            	PeriodService.assignGLDatePeriodJE(JEList);
			}*/
			
			if(nonYearEndJEList != null && nonYearEndJEList.size() > 0){
				PeriodService.assignGLDatePeriod(nonYearEndJEList);
			}
        }
        
        if(trigger.isUpdate){
        	
        	List<Accounting_Entry__c> originalAEList = new List<Accounting_Entry__c>();
        	for(Accounting_Entry__c ae: Trigger.new){
        		if( KSE.isFieldChanging('status__c',ae,Trigger.oldMap) && ae.status__c == 'Obsolete'){
        			originalAEList.add(ae);
        		}
        	}
        	AES.ObsoleteRelatedAEs(originalAEList);
			
        }
        if(trigger.isDelete){
        	for(Accounting_Entry__c thisAE: Trigger.old){
        		if((thisAE.status__c == 'Active'
        				&& (thisAE.Period_Status__c.equalsIgnoreCase('Closed') || thisAE.Period_Status__c.equalsIgnoreCase('Permanently closed')))){
        			thisAE.addError(Label.Cannot_delete_AccountingEntries_for_closed_period);
        		}
        	}
        	// if the AE to be deleted has the related AE then related AE should also be deleted
        	AES.CleanRelatedAEs(Trigger.old);
        }
        
    }
    
    if(trigger.isBefore && trigger.isDelete){
		for(Accounting_Entry__c ae : trigger.old){
			if((ae.Subledger_Closed__c 
					&& (ae.status__c == 'Active' || ae.status__c == '' || ae.status__c == null))){
				ae.addError('You cannot delete records in closed areas.');
			}
		}
	}  
}