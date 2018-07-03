trigger PeriodTrigger on Period__c (before insert, before update, after insert, after update, before delete, after delete) {
	
	if(DML.checkTriggerDispatch(Period__c.getSobjectType())){return;}
	
	List<Period__c> checkPeriods = new List<Period__c>();
	
	
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
			list<Period__c> periodList = new list<Period__c>();
		for(Period__c p : Trigger.new){
			String type = p.Type__c;
			if(p.type__c != 'Zero' && p.type__c != 'Period 13') {
				if(p.Period_Start__c == null){
					p.addError('Period Start is required field for '+ type +' Period record');
				}else if(p.Period_End__c == null){
					p.addError('Period End is required field for '+ type +' Period record');
				}
			}else{
				if(p.Period_Start__c != null){
					p.addError('Period Start is not required field for '+ type +' Period record');
				}else if(p.Period_End__c != null){
					p.addError('Period End is not required field for '+ type +' Period record');
				}
			}
			
			if((p.closed__c == true || p.Permanently_Closed__c == true) && p.type__c == 'Period 13'){
				periodList.add(p);
			}
			
		}
	    if(periodList != null && periodList.size()>0){
	    	PeriodService.checkYearEndAdjustmentJEExixts(periodList);
	    }

	    PeriodService.validateSystemFields();
	    //Check for subledger cutoff assignment / valid after dates, defaulting where necessary
		PeriodService.setDefaults(Trigger.new);	
	    
	    for(Period__c p : trigger.new){
	    	
	    	
			if(trigger.isInsert){
					checkPeriods.add(p);
			}else if(trigger.isUpdate){
				if(KSE.isFieldChanging('Period_Start__c', p, trigger.oldMap)
						|| KSE.isFieldChanging('Period_End__c', p, trigger.oldMap)
						|| KSE.isFieldChanging('Prior_Period__c', p, trigger.oldMap)
						|| KSE.isFieldChanging('Type__c', p, trigger.oldMap)//FIN-213 Prevent gap in periods to period type change                   
						|| p.Prior_Period__c == null
						|| p.next_Period__c == null){
					checkPeriods.add(p);
				}
			}
			
		}
		
		// Validate the subledger cut off dates
		PeriodService.SLCValidation();
		PeriodService.SLCValidationAgainstPeriodCutOff();
		
		if(checkPeriods.size() > 0){
			PeriodService.validatePeriodDates(checkPeriods);
			PeriodService.validatePeriodTypes(checkPeriods);
		}	
		
		//BalanceTransferService.checkBalanceTransfers();
		//BalanceTransferService.checkIncrementalBalanceTransfers();
	}	
	
	if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
		PeriodService.priorPeriodValidation();
	}
	
	if(Trigger.isBefore && (Trigger.isUpdate)){
		// If the Period record is being updated it need to be validated against if any change in dates or calendar type, if the Accounting Entries already exists.
		Set<Id> PeriodIds = new Set<Id>();
		Set<Id> CompanyIds = new Set<Id>();
		
		for(Period__c thisPeriod : Trigger.New){
			PeriodIds.add(thisPeriod.id);
			CompanyIds.add(thisPeriod.Company__c);
		}
		// Check if the period was open and transactions are recorded and then the period Open is unchecked ( Closed and permanently closed = false)
		//FIN-213 Also,Adding validation to prevent changing period type.
        PeriodService.PeriodOpenValidation();
        PeriodService.zeroPeriodValidation();
  
		//TODO: RS
		//PeriodService PS = PeriodService.getInstance(CompanyIds);
		//PS.periodValidation(Trigger.New, Trigger.oldMap, PeriodIds);
	}
	
	if(trigger.isBefore && trigger.isDelete){
		PeriodService.PeriodDeleteValidation();
		for(Period__c p : trigger.old){
			if((p.Type__c =='Zero' && p.Closed__c == true) || (p.Type__c =='Period 13' && p.Closed__c == true)){
	    		p.addError('You cannot delete a Period 13 period that is closed' );
	    	}
		}
	}
	
	if(trigger.isAfter && trigger.isDelete){
		 for(Period__c p : trigger.old){
		 	checkPeriods.add(p);
		 }
		 if(checkPeriods.size() > 0){
		 	PeriodService.validatePeriodDates(checkPeriods);
		 }
	}

}