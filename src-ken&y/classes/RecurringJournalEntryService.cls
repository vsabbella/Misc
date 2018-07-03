public with sharing class RecurringJournalEntryService {
	
	public static SegmentService SS = new SegmentService();
	public static List<Segment_Definition__c> segments = SS.segments;
	public class RJESException extends Exception{}
    public static ExceptionService exService = new ExceptionService();
	
	public static Set<String> segmentQueryStr(List<Segment_Definition__c> segmentsDef){
		Set<String> segFields = new Set<String>();
		for(Segment_Definition__c sd : segmentsDef){
			segFields.add(sd.accounting_entry_field__c);
		}
		return segFields;
	}
	
		
	public void createIncrementalJEs(List<Recurring_Template__c> rtList, Datetime currDate){
		//system.debug(logginglevel.info,'inside function createIncrementalJEs');
		set<Id> companyIds = new set<Id>(); 
		List<Period__c> periodList = new List<Period__c>();
		map<Id,DateTime> mRTLastTD = new map<Id, DateTime>();
		Map<Id,Recurring_Template__c> mUpdateRT = new map<Id, Recurring_Template__c>();
		List<Journal_Entry_Line__c> jeLineListToInsert;
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true, true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Recurring_Template__c','Max(transaction_date__c) lastTD'
		});
		soql.setWhereClause('Recurring_Template__c != null AND Recurring_Template__c in :rtList GROUP BY Recurring_Template__c');

		AggregateResult[] groupedResults = Database.query(soql.getQuery());

		for(AggregateResult ar: groupedResults){
			mRTLastTD.put((Id) ar.get(KSE.NamespaceUU+'Recurring_Template__c'),(Datetime) ar.get('lastTD'));
			//companyIds.add((Id) ar.get('Company__c'));
		}
		
		for(Recurring_template__c rt: rtList){
			companyIds.add(rt.Company__c);
		}
		
		
		Map<Id, List<Period__c>> mCompanyPeriods = new Map<Id, List<Period__c>>();
 		if(companyIds.size() > 0){
 			mCompanyPeriods = PeriodService.getAllPeriodsMap(companyIds);
 		}
		
		try{
			String whereClause = 'id in :rtList';
        
		    soql = new SOQLUtil('recurring_template__c');
		    soql.addFields(new Set<String>{'id', 'name', 'company__c', 'currency__c', 'recurring_transaction_start_date__c',
		    								+ 'start_period__c', 'end_period__c', 'frequency__c', 'status__c', 'type__c', 'template_end_date__c'});
		    soql.setWhereClause(whereClause);
	    	
	    	SOQLUtil.ChildRelationship templateLines = new SOQLUtil.ChildRelationship(soql, 'recurring_template_lines__r');
		    templateLines.addFields(new Set<String>{'id', 'name', 'bank_account__c', 'amount_cr__c', 'amount_dr__c', 'recurring_template__c'});
		    templateLines.addFields(segmentQueryStr(segments));
		    soql.addChildRelationship(templateLines);
	    
			rtList = Database.query(soql.getQuery());
		}catch(Exception e){
			//system.debug(logginglevel.info,'Exception:'+e.getMessage());
			throw e;
		}
		
		List<Journal_Entry__c> newJEList, jesToInsert;
		map<Id,List<Journal_Entry__c>> mJEs = new map<Id, List<Journal_Entry__c>>();
		
		for(Recurring_Template__c thisRT: rtList){
			Datetime incrementalDate;
			newJEList = new List<Journal_Entry__c>();
			
			if(mRTLastTD.containsKey(thisRT.id)){
				Datetime lastTD = (Datetime) mRTLastTD.get(thisRT.id);
				//system.debug(logginglevel.info,'lastTD:'+lastTD);
				incrementalDate = incrementDate(lastTD, thisRT, mCompanyPeriods);
			}else{ // set does not contain the key means it is the first record to be created hence the first date is set to the start date of the recurring transaction
				incrementalDate = thisRT.recurring_transaction_start_date__c;
			}
			
			system.debug(logginglevel.info,'thisRT.Name:'+thisRT.Name);
			system.debug(logginglevel.info,'incrementalDate:'+incrementalDate);
			system.debug(logginglevel.info,'currDate:'+currDate);
			system.debug(logginglevel.info,'thisRT.template_end_date__c:'+thisRT.template_end_date__c);
			
			if(incrementalDate != null){
				while(incrementalDate <= currDate && incrementalDate < thisRT.template_end_date__c){ 
					Journal_Entry__c newJE = new Journal_entry__c();
					newJE.Type__c = 'Recurring Journal';
					newJE.company__c = thisRT.Company__c;
					newJE.currency__c = thisRT.currency__c;
					
					newJE.transaction_date__c = incrementalDate;
					newJE.recurring_template__c = thisRT.id;
					newJEList.add(newJE);
					incrementalDate = incrementDate(incrementalDate, thisRT, mCompanyPeriods);
					if(incrementalDate == null){
						break;
					}
				}
				if(incrementalDate >= thisRT.template_end_date__c){
					mUpdateRT.put(thisRT.id,new Recurring_Template__c(id = thisRT.id, status__c = 'Closed'));
				}
				
				mJEs.put(thisRT.id, newJEList);
			}else{
				mUpdateRT.put(thisRT.id,new Recurring_Template__c(id = thisRT.id, status__c = 'Closed'));
			}
		}
		jesToInsert = new List<Journal_Entry__c>();
		for(Id rtId: mJEs.keyset()){
			jesToInsert.addAll(mJEs.get(rtId));
		}
		Savepoint sp = Database.setSavepoint();
		try{
			
			DML.insertAsUser(jesToInsert); 
			jeLineListToInsert = new List<Journal_Entry_Line__c>();
			for(Recurring_Template__c thisRT: rtList){
				List<journal_entry_line__c> newJELineList;
				if(mJEs.containsKey(thisRT.id)){
					List<Journal_Entry__c> jeList = mJEs.get(thisRT.id);
					for(Integer i=0; i< jeList.size(); i++){
						newJELineList = new List<journal_entry_line__c>();
						for(Recurring_Template_Line__c rtLine: thisRT.Recurring_Template_Lines__r){
							journal_entry_line__c newJELine = new journal_entry_line__c();
							newJELine.Journal_Entry__c = jeList[i].id;
							newJELine.Amount_CR__c = rtLine.Amount_CR__c;
							newJELine.Amount_DR__c = rtLine.Amount_DR__c;
							newJELine.Bank_Account__c = rtLine.Bank_Account__c; 
							// copy the segments from RTL to JEL	
							for(Segment_Definition__c sgd: segments){
	            				newJELine.put(sgd.Accounting_Entry_Field__c, rtLine.get(sgd.Accounting_Entry_Field__c));
							}
							newJELineList.add(newJELine);
						}
						jeLineListToInsert.addAll(newJELineList);
					}
				}
				
			}
			DML.insertAsUser(jeLineListToInsert);
			for(Journal_Entry__c je:jesToInsert){
				je.finalized__c = true;
			}
			
			 DML.updateAsUser(mUpdateRT.values());
			
		}catch(Exception e){
			system.debug(logginglevel.info,'Exception:'+e.getMessage());
        	Database.rollback(sp);
        	throw e;
		}								      
		if(jesToInsert.size() > 0){
			DML.updateAsUser(jesToInsert, false);
		}
		
										      
	}
	
	public Datetime incrementDate(Datetime oldDate, Recurring_template__c thisRT,Map<Id, List<Period__c>> mCompanyPeriods){ 
		Map<Id,Period__c> mPeriod = new map<Id,Period__c>(mCompanyPeriods.get(thisRT.company__c));
		//system.debug(logginglevel.info,'mPeriod:'+mPeriod);
		if(thisRT.frequency__c.equalsIgnoreCase('Monthly')){
			return oldDate.addmonths(1);
		}else if(thisRT.frequency__c.equalsIgnoreCase('Bi Weekly')){
			return oldDate.addDays(14);
		}
		else if(thisRT.frequency__c.equalsIgnoreCase('Weekly')){
			return oldDate.addDays(7);
		}
		else if(thisRT.frequency__c.equalsIgnoreCase('Daily')){
			return oldDate.addDays(1);
		}
		else if(thisRT.frequency__c.equalsIgnoreCase('Quarterly')){
			Period__c currentPeriod = returnTransactionPeriod( mCompanyPeriods, thisRT.Company__c, oldDate);
			Period__c next1stPeriod, next2ndPeriod;
			if(currentPeriod!= null){
			if(currentPeriod.Next_Period__c != null){
				next1stPeriod = returnTransactionPeriod( mCompanyPeriods, thisRT.Company__c, currentPeriod.Period_end__c);
			}
			}
			if(next1stPeriod != null){
				next2ndPeriod = returnTransactionPeriod( mCompanyPeriods, thisRT.Company__c, next1stPeriod.Period_end__c);
			}
			DateTime nextIDate = next2ndPeriod != null ? next2ndPeriod.period_end__c : null;
			return nextIDate;
		}
		else if(thisRT.frequency__c.equalsIgnoreCase('Beginning of Period')){
			system.debug(logginglevel.info,'oldDate:'+oldDate);
			Period__c currentPeriod = returnTransactionPeriod( mCompanyPeriods, thisRT.Company__c, oldDate);
			system.debug(logginglevel.info,'currentPeriod:'+currentPeriod);
			system.debug(logginglevel.info,'currentPeriod.period_end__c:'+currentPeriod.period_end__c);
			Datetime nextIDate = currentPeriod != null ? currentPeriod.period_end__c : null;
			system.debug(logginglevel.info,'nextIDate:'+nextIDate);
			return nextIDate;
		}
		else if(thisRT.frequency__c.equalsIgnoreCase('Middle of Period')){
			Period__c currentPeriod = returnTransactionPeriod( mCompanyPeriods, thisRT.Company__c, oldDate);
			Period__c nextPeriod;
			if(currentPeriod != null){
				nextPeriod = returnTransactionPeriod( mCompanyPeriods, thisRT.Company__c, currentPeriod.Period_End__c);
			}
			Datetime nextPSDT,nextPEDT, nextIDate;
			if(nextPeriod != null){
				nextPSDT = nextPeriod.period_start__c;
				nextPEDT = nextPeriod.period_end__c;
			}
			
			if(nextPSDT!= null && nextPEDT != null){
				Integer diff = nextPSDT.Date().daysBetween(nextPEDT.Date());
				nextIDate = nextPSDT.addDays(diff/2);
			}else{
				nextIDate = null;
			}
			return nextIDate;
		}
		else{
			return null;
		}
	}
	
	public static Period__c returnTransactionPeriod(Map<Id, List<Period__c>> mCompanyPeriods, Id companyId, DateTime transactionDate){
 		Period__c transactionPeriod;
 		if(mCompanyPeriods.containsKey(companyId)){
 			for(Period__c p : mCompanyPeriods.get(companyId)){
 				if(p.period_start__c <= transactionDate && transactionDate < p.period_end__c){
 					transactionPeriod = p;
 					break;
 				}			
 			}
 		}else{
 			throw new RJESException('There are no available periods for this company');
 		}
 		return transactionPeriod;
 	}
 	
    public static void ValidateRJEFields(list<Recurring_Template__c> RTList){
    	
    	// Query for parent source docs and set exception based on hasExceptions
    	
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Recurring_Template__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name'
		});
		soql.setWhereClause('Id IN :RTList');

		Map<Id, Recurring_Template__c> mRJEs = new Map<Id, Recurring_Template__c>((List<Recurring_Template__c>)Database.query(soql.getQuery()));

    	for(Recurring_Template__c rje : RTList){
    		
    		if(rje.Total_Debit__c != rje.Total_Credit__c)
    			exService.setException(rje, ExceptionUtil.JE_CREDIT_DEBIT_UNMATCHED);
    		else
    			exService.clearException(rje, ExceptionUtil.JE_CREDIT_DEBIT_UNMATCHED);
    			    			
    		// TODO: check for appropriate source document when the Accrual for source document is implemented
    		
    	}
    }  
 	
	
}