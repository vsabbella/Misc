public with sharing class RecurringTemplateService {
	public static final string STATUS_CLOSED = 'Closed';
	public static final string STATUS_ACTIVE = 'Active';
	public static final string STATUS_DRAFT = 'Draft';
	public class RTSException extends Exception{}
	public static SegmentService SS = new SegmentService();
	public static List<Segment_Definition__c> segments = SS.segments;
	
	public static Set<String> segmentQueryStr(List<Segment_Definition__c> segmentsDef){
		Set<String> segFields = new Set<String>();
		for(Segment_Definition__c sd : segmentsDef){
			segFields.add(sd.accounting_entry_field__c);
		}
		return segFields;
	}
	
	
	public void setOrClearInformation(List<Recurring_Template__c> newRTList){
		if(trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
			set<Id> PeriodIds = new set<Id>();	
			set<String> frequencyString = new set<String>{'Daily','Monthly','Bi Weekly','Weekly', 'Quarterly','Beginning of Period','Middle of Period'};
			
			for(Recurring_Template__c thisRT: newRTList){
				PeriodIds.add(thisRT.start_period__c);
				PeriodIds.add(thisRT.end_period__c);
			}
			
			Map<Id,Period__c> mPeriods = new Map<ID,Period__c>();

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Name','Period_Start__c','Period_End__c','JE_Cutoff__c',
				'Prior_period__c','next_period__c','next_period__r.period_start__c',
				'next_period__r.period_end__c','next_period__r.JE_Cutoff__c'
			});
			soql.setWhereClause('id in :PeriodIds');
			
			for(Period__c p: Database.query(soql.getQuery())){
				mPeriods.put(p.id, p);
			}
			
			Map<Id,String> companyTransactionCurrencyMap = new Map<Id,Id>();
			
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			soql = new SOQLUtil('Recurring_Template__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Name','company__c','company__r.Default_Transaction_Currency__c'
			});
			soql.setWhereClause('id in :newRTList');
			
			for(Recurring_Template__c thisRT: Database.query(soql.getQuery())){
				companyTransactionCurrencyMap.put(thisRT.id, thisRT.Company__r.Default_Transaction_Currency__c);
			}
			
			for(Recurring_Template__c thisRT: newRTList){
				// default the type to Journal Entry always until other types are introduced
				thisRT.Type__c = 'Journal Entry';
				if(thisRT.Frequency__c != null && !frequencyString.contains(thisRT.Frequency__c)){
					thisRT.addError('Selected frequency is not a supported at the moment:'+thisRT.Frequency__c );
				}
				if(companyTransactionCurrencyMap.containsKey(thisRT.id) && thisRT.currency__c == null){
					thisRT.currency__c = companyTransactionCurrencyMap.get(thisRT.id);
				}
				
				if(thisRT.Start_Period__c == null ){
					thisRT.addError('Please specify Start Period for this template');
				}
				if(thisRT.End_Period__c == null){
					thisRT.addError('Please specify End Period for this template');
				}
				if(thisRT.Frequency__c == null){
					thisRT.addError('Please specify the frequency for this template.');
				}
				if(thisRT.status__c == null){
					thisRT.Status__c = 'Draft';
				}
				
				if(thisRT.Frequency__c.equalsIgnoreCase('Monthly') || thisRT.Frequency__c.equalsIgnoreCase('Bi-Weekly') || thisRT.Frequency__c.equalsIgnoreCase('Weekly') || thisRT.Frequency__c.equalsIgnoreCase('Daily')){
					if(thisRT.Recurring_transaction_start_date__c == null){
						thisRT.addError('Recurring Transaction date is required for the selected frequency');
					}
				}
				if(thisRT.template_end_date__c == null){ // if template end date is null populate the date as end date of the end period
					thisRT.template_end_date__c = mPeriods.get(thisRT.end_period__c).get('Period_End__c') != null ? Datetime.valueof(mPeriods.get(thisRT.end_period__c).get('Period_End__c')) : null;
				}
				if(thisRT.template_end_date__c > Datetime.valueof(mPeriods.get(thisRT.end_period__c).get('Period_End__c'))){
					thisRT.addError('Template end date can not be beyond the End Period');
				}
				if(thisRT.Frequency__c.equalsIgnoreCase('Beginning of Period')){
					// default the recurring transaction start date to the start period's PS
					thisRT.Recurring_transaction_start_date__c = mPeriods.get(thisRT.start_period__c).get('Period_Start__c') != null? Datetime.valueof(mPeriods.get(thisRT.start_period__c).get('Period_Start__c')) : null ;
				}
				if(thisRT.Frequency__c.equalsIgnoreCase('Quarterly')){
					// default the recurring transaction start date to the start period's PS
					thisRT.Recurring_transaction_start_date__c = mPeriods.get(thisRT.start_period__c).get('Period_Start__c') != null? Datetime.valueof(mPeriods.get(thisRT.start_period__c).get('Period_Start__c')) : null ;
				}
				if(thisRT.Frequency__c.equalsIgnoreCase('Middle of Period')){
					Datetime PS = (Datetime) mPeriods.get(thisRT.start_period__c).get('Period_start__c');
					Datetime PE = (Datetime) mPeriods.get(thisRT.start_period__c).get('Period_end__c');
					system.debug(logginglevel.info,'PS:'+PS+'		PE:'+PE);
					Integer diff = PS.date().daysbetween(PE.date());
					system.debug(logginglevel.info,'diff:'+diff);
					// default the recurring transaction start date to the start period's PS
					thisRT.Recurring_transaction_start_date__c =  PS.addDays(diff/2);
					system.debug(logginglevel.info,'thisRT.Recurring_transaction_start_date__c:'+thisRT.Recurring_transaction_start_date__c);
				}
			}
		}
	}
		
		
	public void validateRecurringTemplate(List<Recurring_Template__c> newRTList, Map<Id,Recurring_Template__c> oldMap){
		if(trigger.isBefore && (Trigger.isUpdate)){
			Map<Id, Integer> mJEs = new Map<Id, Integer>();
			
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Recurring_Template__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Name'
			});
			soql.setWhereClause('id in :newRTList');

			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'journal_entries__r');
			childRel.addFields(new set<string>{
				'id','Name'
			});

			soql.addChildRelationship(childRel);
			
			for(Recurring_Template__c thisRT: Database.query(soql.getQuery())){
				mJEs.put(thisRT.id, thisRT.journal_entries__r.size());
			}
			
			for(Recurring_Template__c thisRT: newRTList){
				
				if(mJEs.containsKey(thisRT.id)){
					if(mJEs.get(thisRT.id) > 0 && KSE.isFieldChanging('Status__c',thisRT,oldMap) && thisRT.Status__c.equalsIgnoreCase('Draft')){
						thisRT.addError('Status can not be moved to draft once the journal entries are crated for the template');
					}
					if(mJEs.get(thisRT.id) > 0){
						thisRT.isJECreated__c = true;
					}else{
						thisRT.isJECreated__c = false;
					}
				}
				if(thisRT.Template_end_date__c < thisRT.recurring_transaction_start_date__c){
					thisRT.addError('Template end date can not be prior to the start date');
				}
				if(thisRT.Template_end_date__c > thisRT.end_period__r.period_end__c){
					thisRT.addError('Template end date can not be beyond the end period');
				}
				if(KSE.isFieldChanging('Status__c', thisRT, oldMap) && oldMap.get(thisRT.id).status__c.equalsIgnoreCase('Closed')){
					thisRT.addError('Closed template status can not be edited');
				}
				if(thisRT.Status__c.equalsIgnoreCase('Active') || thisRT.Status__c.equalsIgnoreCase('Closed')){
					if(	KSE.isFieldChanging('Type__c', thisRT, oldMap)
					|| 	KSE.isFieldChanging('Currency__c', thisRT, oldMap)
					||	KSE.isFieldChanging('start_period__c', thisRT, oldMap)
					||	KSE.isFieldChanging('end_period__c', thisRT, oldMap)
					||	KSE.isFieldChanging('frequency__c', thisRT, oldMap)
					||	KSE.isFieldChanging('recurring_transaction_start_date__c', thisRT, oldMap)
					||	KSE.isFieldChanging('company__c', thisRT, oldMap)
					){
						thisRT.addError('Fields can not be modified on active or closed Template.');
					}
				}
			}
		}
	}
	
	public static List<Recurring_Template__c> returnRTDetails(set<Id> rtIds){
 		List<Recurring_Template__c> rtDetails = new List<Recurring_Template__c>();
 		String queryStr = 'SELECT Id, name, status__c, Company__c, currency__c, template_end_date__c, start_period__c, end_period__c, '
        		+ 'type__c, frequency__c, recurring_transaction_start_date__c, '
                + ' (SELECT Id, name, Amount_DR__c, Amount_CR__c '
                + segmentQueryStr(segments)
                + ' FROM Recurring_Template_Lines__r) '
                + ' FROM Recurring_Template__c '
                + ' WHERE Id IN :rtIds  ';
        try{
        	
        	String whereClause = 'Id in :rtIds';
        
		    SOQLUtil soql = new SOQLUtil('Recurring_Template__c');
		    soql.addFields(new Set<String>{'id', 'name', 'company__c', 'currency__c', 'recurring_transaction_start_date__c',
		    								'start_period__c', 'end_period__c', 'frequency__c', 'status__c', 'type__c', 'template_end_date__c'});
		    soql.setWhereClause(whereClause);
	    	
	    	SOQLUtil.ChildRelationship templateLines = new SOQLUtil.ChildRelationship(soql, 'Recurring_Template_Lines__r');
		    templateLines.addFields(new Set<String>{'id', 'name', 'amount_cr__c', 'amount_dr__c', 'recurring_template__c'});
		    templateLines.addFields(segmentQueryStr(segments));
		    soql.addChildRelationship(templateLines);
		    
        	rtDetails = Database.query(soql.getQuery());    
        }catch(Exception e){
        	throw new RTSException('Recurring Template Query Exception:' + e.getMessage());
        }   
    	return rtDetails;
    }
	
}