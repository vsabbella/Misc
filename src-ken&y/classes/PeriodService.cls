/**
 * @description: This class serves the purpose of service for Period__c object.
 */
 
 //just adding dummy comment
public with sharing class PeriodService {
	
	public PeriodService(){}
	static Schemautil util = schemautil.getInstance();
    
	public static list<String> SLCList{
    	
     	get{
     		List<String> SLCList = new List<String>();
    		if(SLCList.size() < 1){
    			for(String str: util.getFieldsFromFieldSetString( Period__c.sObjectType , 'SubledgerCutOffs')){
					SLCList.add(str);
    			}
    		}
    		return SLCList;
    	}
    	set;
    }
    
    public static Map< String, String > getSLCCloseMap(){
		
		map<String, String> SLCCloseMap = new map<String, String>();
		
		SLCCloseMap.put( 'AR_Subledger_Cutoff__c', 'AR_Subledger_Closed__c');
		SLCCloseMap.put( 'AP_Subledger_Cutoff__c', 'AP_Subledger_Closed__c');
		SLCCloseMap.put( 'FA_Subledger_Cutoff__c', 'FA_Subledger_Closed__c');
		SLCCloseMap.put( 'Shipment_Subledger_Cutoff__c', 'Shipment_Subledger_Closed__c');
		SLCCloseMap.put( 'Receiving_Subledger_Cutoff__c', 'Receiving_Subledger_Closed__c');
		SLCCloseMap.put( 'Inventory_Subledger_Cutoff__c', 'Inventory_Subledger_Closed__c');
		SLCCloseMap.put( 'InterCompany_Subledger_Cutoff__c', 'InterCompany_Subledger_Closed__c');
		//KNDY-10186
		SLCCloseMap.put( 'JE_Cutoff__c', 'GL_Close__c');

		return SLCCloseMap;
	}
	public static map<String, String> SLCCloseMap = getSLCCloseMap();
    
    
    public static void setDefaults(List<Period__c> periodList){
    	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
    		Boolean isCutoffsEnabled = FALSE;
            if(Configuration__c.getValues('EnableCutoffs') != NULL 
            		&& String.isNotBlank(Configuration__c.getValues('EnableCutoffs').Value__c)
            		&& Configuration__c.getValues('EnableCutoffs').Value__c.equalsignorecase('yes')){
            	isCutoffsEnabled = TRUE;
            }
            for(Period__c p : periodList){
	    		if(p.Type__c != 'Zero' && p.Type__c != 'Period 13'){
					if(isCutoffsEnabled){//Allow cutoff overriding if enable-cutoffs is set to true.
							p.AR_Subledger_Cutoff__c = p.AR_Subledger_Cutoff__c == null ? p.period_end__c : p.AR_Subledger_Cutoff__c;
							p.AP_Subledger_Cutoff__c = p.AP_Subledger_Cutoff__c == null ? p.period_end__c : p.AP_Subledger_Cutoff__c;
							p.Receiving_Subledger_Cutoff__c = p.Receiving_Subledger_Cutoff__c == null ? p.period_end__c : p.Receiving_Subledger_Cutoff__c;
							p.Shipment_Subledger_Cutoff__c = p.Shipment_Subledger_Cutoff__c == null ? p.period_end__c : p.Shipment_Subledger_Cutoff__c;
							p.Inventory_Subledger_Cutoff__c = p.Inventory_Subledger_Cutoff__c == null ? p.period_end__c : p.Inventory_Subledger_Cutoff__c;
							p.InterCompany_Subledger_Cutoff__c = p.InterCompany_Subledger_Cutoff__c == null ? p.period_end__c : p.InterCompany_Subledger_Cutoff__c;
							p.FA_Subledger_Cutoff__c = p.FA_Subledger_Cutoff__c == null ? p.period_end__c : p.FA_Subledger_Cutoff__c;
							p.JE_Cutoff__c = p.JE_Cutoff__c == null ? p.period_end__c : p.JE_Cutoff__c;
						
					}else{
						p.AR_Subledger_Cutoff__c =  p.period_end__c;
						p.AP_Subledger_Cutoff__c = p.period_end__c ;
						p.Receiving_Subledger_Cutoff__c = p.period_end__c ;
						p.Shipment_Subledger_Cutoff__c = p.period_end__c ;
						p.Inventory_Subledger_Cutoff__c = p.period_end__c ;
						p.InterCompany_Subledger_Cutoff__c = p.period_end__c ;
						p.FA_Subledger_Cutoff__c = p.period_end__c ;
						p.JE_Cutoff__c = p.period_end__c ;
					}
					/*//TODO:Temporary fix to support data migration from Period cutoff to JE cutoff.
					if(trigger.isUpdate && KSE.isfieldChanging('Open__c', p, trigger.oldMap)){
					 //If user is reopening old periods use existing period cutoff for JE cutoff if null.
					    p.JE_Cutoff__c = p.JE_Cutoff__c == null ?((p.Period_Cut_off__c == null)? p.period_end__c:p.Period_Cut_off__c) : p.JE_Cutoff__c;
					}
					else{//User is inserting/updating already open periods.Default JE Cutoff from period end if not present.
					    p.JE_Cutoff__c = p.JE_Cutoff__c == null ? p.period_end__c : p.JE_Cutoff__c;
					}
                   p.Period_Cut_off__c = p.Period_Cut_off__c == null ? p.period_end__c : p.Period_Cut_off__c;
					*/

					//Sets default valid after date to later of subledger cutoff date or period end date.
					

                    if(trigger.isInsert){
                        //setting the default date
						p.AR_Valid_After__c = (p.AR_Subledger_Cutoff__c > p.period_end__c ? p.AR_Subledger_Cutoff__c : p.period_end__c);
						p.AP_Valid_After__c = (p.AP_Subledger_Cutoff__c > p.period_end__c ? p.AP_Subledger_Cutoff__c : p.period_end__c);
						p.FA_Valid_After__c = (p.FA_Subledger_Cutoff__c > p.period_end__c ? p.FA_Subledger_Cutoff__c : p.period_end__c);
						p.Inventory_Valid_After__c = (p.Inventory_Subledger_Cutoff__c > p.period_end__c ? p.Inventory_Subledger_Cutoff__c : p.period_end__c);
						p.InterCompany_Valid_After__c = (p.InterCompany_Subledger_Cutoff__c > p.period_end__c ? p.InterCompany_Subledger_Cutoff__c : p.period_end__c);
						p.Receiving_Valid_After__c = (p.Receiving_Subledger_Cutoff__c > p.period_end__c ? p.Receiving_Subledger_Cutoff__c : p.period_end__c);
						p.Shipment_Valid_After__c = (p.Shipment_Subledger_Cutoff__c > p.period_end__c ? p.Shipment_Subledger_Cutoff__c : p.period_end__c);
						p.JE_Valid_After__c = (p.JE_Cutoff__c > p.period_end__c ? p.JE_Cutoff__c : p.period_end__c);
                    }else if(isCutoffsEnabled){
                        //if cutoff changes set the valid after to the latest of Period End or Cutoff
                        if(p.AR_Subledger_Cutoff__c != ((Period__c)trigger.oldMap.get(p.Id)).AR_Subledger_Cutoff__c){
                            p.AR_Valid_After__c = (p.AR_Subledger_Cutoff__c > p.period_end__c ? p.AR_Subledger_Cutoff__c : p.period_end__c);
                        }

                        if(p.AP_Subledger_Cutoff__c != ((Period__c)trigger.oldMap.get(p.Id)).AP_Subledger_Cutoff__c){
                        	p.AP_Valid_After__c = (p.AP_Subledger_Cutoff__c > p.period_end__c ? p.AP_Subledger_Cutoff__c : p.period_end__c);
                        }
                        
                        if(p.FA_Subledger_Cutoff__c != ((Period__c)trigger.oldMap.get(p.Id)).FA_Subledger_Cutoff__c){
                        	p.FA_Valid_After__c = (p.FA_Subledger_Cutoff__c > p.period_end__c ? p.FA_Subledger_Cutoff__c : p.period_end__c);
                        }
                        
                        if(p.Inventory_Subledger_Cutoff__c != ((Period__c)trigger.oldMap.get(p.Id)).Inventory_Subledger_Cutoff__c){
                        	p.Inventory_Valid_After__c = (p.Inventory_Subledger_Cutoff__c > p.period_end__c ? p.Inventory_Subledger_Cutoff__c : p.period_end__c);
                        }
                        
                        if(p.InterCompany_Subledger_Cutoff__c != ((Period__c)trigger.oldMap.get(p.Id)).InterCompany_Subledger_Cutoff__c){
                        	p.InterCompany_Valid_After__c = (p.InterCompany_Subledger_Cutoff__c > p.period_end__c ? p.InterCompany_Subledger_Cutoff__c : p.period_end__c);
                        }
                        
                        if(p.Receiving_Subledger_Cutoff__c != ((Period__c)trigger.oldMap.get(p.Id)).Receiving_Subledger_Cutoff__c){
                        	p.Receiving_Valid_After__c = (p.Receiving_Subledger_Cutoff__c > p.period_end__c ? p.Receiving_Subledger_Cutoff__c : p.period_end__c);
                        }
                        
                        if(p.Shipment_Subledger_Cutoff__c != ((Period__c)trigger.oldMap.get(p.Id)).Shipment_Subledger_Cutoff__c){
                        	p.Shipment_Valid_After__c = (p.Shipment_Subledger_Cutoff__c > p.period_end__c ? p.Shipment_Subledger_Cutoff__c : p.period_end__c);
                        }
                        
                        if(p.JE_Cutoff__c != ((Period__c)trigger.oldMap.get(p.Id)).JE_Cutoff__c){
                        	p.JE_Valid_After__c = (p.JE_Cutoff__c > p.period_end__c ? p.JE_Cutoff__c : p.period_end__c);   
                        }
                    }
				}
	    	}
    	}
    }
    
    
    public static set<Id> systemEditable = new set<Id>();
    //The following fields are used to validate system assignment of field values by the subledger close process
	public static void validateSystemFields(){
	    if(trigger.isExecuting){
	        if(trigger.isInsert){
	            for(Period__c p : (List<Period__c>)Trigger.new){
	                if(p.AR_Subledger_Closed__c != null){
	                    p.AR_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                if(p.AP_Subledger_Closed__c != null){
	                    p.AP_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                if(p.Shipment_Subledger_Closed__c != null){
	                    p.Shipment_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                if(p.Receiving_Subledger_Closed__c != null){
	                    p.Receiving_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                if(p.Inventory_Subledger_Closed__c != null){
	                    p.Inventory_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                if(p.FA_Subledger_Closed__c != null){
	                    p.FA_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                if(p.InterCompany_Subledger_Closed__c != null){
	                    p.InterCompany_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                if(p.GL_Close__c != null){
	                    p.GL_Close__c.addError(Label.System_Specified_Field);
	                }
	                
	            }
	        }else if(trigger.isUpdate){
	            for(Period__c p : (List<Period__c>)Trigger.new){
	                if(KSE.isFieldChanging('AR_Subledger_Closed__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.AR_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                
	                if(KSE.isFieldChanging('AR_Subledger_Job__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.AR_Subledger_Job__c.addError(Label.System_Specified_Field);
	                }
	                
                    if(KSE.isFieldChanging('AP_Subledger_Closed__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.AP_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                
	                if(KSE.isFieldChanging('AP_Subledger_Job__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.AP_Subledger_Job__c.addError(Label.System_Specified_Field);
	                }
	                
	                if(KSE.isFieldChanging('Shipment_Subledger_Closed__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.Shipment_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                
	                if(KSE.isFieldChanging('Shipment_Subledger_Job__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.Shipment_Subledger_Job__c.addError(Label.System_Specified_Field);
	                }
	                
                    if(KSE.isFieldChanging('Receiving_Subledger_Closed__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.Receiving_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                
	                if(KSE.isFieldChanging('Receiving_Subledger_Job__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.Receiving_Subledger_Job__c.addError(Label.System_Specified_Field);
	                }
	                
	                if(KSE.isFieldChanging('Inventory_Subledger_Closed__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.Inventory_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                
	                if(KSE.isFieldChanging('Inventory_Subledger_Job__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.Inventory_Subledger_Job__c.addError(Label.System_Specified_Field);
	                }
	                
 	                if(KSE.isFieldChanging('InterCompany_Subledger_Closed__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.InterCompany_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                
	                if(KSE.isFieldChanging('InterCompany_Subledger_Job__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.InterCompany_Subledger_Job__c.addError(Label.System_Specified_Field);
	                }
	                
                    if(KSE.isFieldChanging('FA_Subledger_Closed__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.FA_Subledger_Closed__c.addError(Label.System_Specified_Field);
	                }
	                
	                if(KSE.isFieldChanging('FA_Subledger_Job__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.FA_Subledger_Job__c.addError(Label.System_Specified_Field);
	                }
	                
	                if(KSE.isFieldChanging('GL_Close__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.GL_Close__c.addError(Label.System_Specified_Field);
	                }
	                
	                if(KSE.isFieldChanging('JE_Subledger_Job__c', p, trigger.oldMap) && !systemEditable.contains(p.Id)){
                        p.JE_Subledger_Job__c.addError(Label.System_Specified_Field);
	                }
	                
	               	
	                
	            }
	        }
	    }
	}
	
	public static void SLCValidationAgainstPeriodCutOff(){
		if(trigger.isExecuting){
	        if(trigger.isInsert || trigger.isUpdate){
	            for(Period__c p : (List<Period__c>)Trigger.new){
	                for(String slcField: SLCList){
	                	String slcLabel = (slcField.substring(0,slcField.length()-1)).replaceAll('_',' ');
	                	if(p.JE_cutoff__c < (Datetime) p.get(slcField)){
	                		p.addError(slcLabel+Label.Cannot_be_after_JE_cutoff); 
	                	}
	                }
	            }
	        	
	        }
		}
	                }
	                
	public static void SLCValidation(){
		if(trigger.isExecuting){
	        if(trigger.isUpdate){
	        	for(Period__c p : (List<Period__c>)Trigger.new){
	               	Period__c currentPeriod = p;
	               	Datetime currentDatetime = system.now();
	                Period__c currentPeriodOldValue = (Period__c) trigger.oldMap.get(p.id);
	                List<String> SLCFieldList = SLCList;
	                //SLCFieldList.add('Period_Cut_off__c');
	                SLCFieldList.add('JE_Cutoff__c');
	                
	                for(String slcField: SLCFieldList){
	                	String slcLabel = (slcField.substring(0,slcField.length()-1)).replaceAll('_',' ');
	                	String slcClosefield;
	                	
	                	slcClosefield = SLCCloseMap.get(slcField);
	                	
	                	if(slcClosefield != null && ((Datetime) currentPeriod.get(slcClosefield) != null)){
			                if(KSE.isFieldChanging(slcField, p, trigger.oldMap)){
		                       p.addError(slcLabel+Label.Cannot_be_changed_after_the_subledger_is_closed);
			                }
		                }else{
		                	if(slcField.equalsIgnoreCase('JE_Cutoff__c')){
		                		if(KSE.isFieldChanging(slcField, p, trigger.oldMap)){
		                			if((Datetime) p.get(slcField) < (Datetime) currentPeriodOldValue.get(slcField)){
			                		 	if((Datetime) p.get(slcField) < currentDatetime){
				                        	p.addError(slcLabel+Label.Cannot_be_moved_back_in_time);
			                		 	}
			                }
				                }
		                }else{
		                	if(KSE.isFieldChanging(slcField, p, trigger.oldMap) && ((Datetime) p.get(slcField) < (Datetime) currentPeriodOldValue.get(slcField))){
			                        p.addError(slcLabel+Label.can_only_be_moved_for_a_future_datetime);
			                }
		                }
	                }
	                
	            }
	        }
	    }
	}
	
	}
	
	public static void PeriodDeleteValidation(){
		if(trigger.isBefore && trigger.isDelete){
			map<Id,Integer> mAEperiod = new map<Id, Integer>();
			map<Id,Integer> mJEperiod = new map<Id, Integer>();
			List<Period__c> periodList = [Select id, Name, (Select id from Accounting_Entries__r LIMIT 1),(Select id from Journal_Entries__r LIMIT 1)
											from Period__c
											where id in :trigger.old];
			
			for(Period__c thisPeriod: periodList){
				mAEperiod.put(thisPeriod.id, thisPeriod.accounting_entries__r.size());
				mJEperiod.put(thisPeriod.id, thisPeriod.journal_entries__r.size());
			}
			
			for(Period__c p : (List<Period__c>)Trigger.old){
				if(mAEperiod.get(p.id) > 0 || mJEperiod.get(p.id) > 0 )
                {
                    p.addError('Cannot delete period which has transactions recorded');
                }
            	
			}
		}
	}
    
	public static void PeriodOpenValidation(){
		if(trigger.isBefore && trigger.isUpdate){
			map<Id,Integer> mAEperiod = new map<Id, Integer>();
			map<Id,Integer> mJEperiod = new map<Id, Integer>();
			List<Period__c> periodList = [Select id, Name,
											 (Select id from Accounting_Entries__r 
											            where Status__c = 'Active' LIMIT 1),
											 (Select id from Journal_Entries__r LIMIT 1)
										  from Period__c
										  where id in :trigger.new];
			
			for(Period__c thisPeriod: periodList){
				mAEperiod.put(thisPeriod.id, thisPeriod.accounting_entries__r.size());
				mJEperiod.put(thisPeriod.id, thisPeriod.journal_entries__r.size());
			}
			
			for(Period__c p : (List<Period__c>)Trigger.new){
              
                //FIN-213 Prevent Period Type change for periods which have transactions recorded
                if(KSE.isFieldChanging('Type__c', p, trigger.oldMap) )
                {
                    //FIN-1055 Allow users to change period type from null to any value.
                    if(trigger.oldmap.get(p.id).get('Type__c')!=null)//Check if old value is null
                    {
                        if(mAEperiod.get(p.id) > 0 || mJEperiod.get(p.id) > 0 )
                        {
                            p.addError(Label.Cannot_change_type_for_a_period_which_has_transactions_recorded );
                        }                  
                    }
                    else
                    {
                        //Allow user to change period type from null to any value irrespective of whether if transactions are recorded or not.
                        //Faciliates old entries before FIN-213 validation check to be backdated.
                    }

				                    
                }
                
                if(trigger.oldMap.get(p.id).get('Fiscalyear__c') != null && KSE.isFieldChanging('FiscalYear__c', p, trigger.oldMap) )
                {
                	system.debug(logginglevel.error,'mJEperiod:'+mJEperiod);
                    if(mAEperiod.get(p.id) > 0 || mJEperiod.get(p.id) > 0 )
                    {
                    	system.debug(logginglevel.error,'mJEperiod.get(p.id):'+mJEperiod.get(p.id));
                        //p.addError('Cannot change the Fiscal Year for a period which has transactions recorded');
                    }
				                    
                }

				if( KSE.isFieldChanging('Open__c', p, trigger.oldMap) 
					&& !p.Open__c  
					&& !p.Permanently_Closed__c 
					&& !p.closed__c 
					&& (mAEperiod.get(p.id) > 0 || mJEperiod.get(p.id) > 0 )
					)
				{
					p.addError(Label.Period_Open_cannot_be_unchecked);
				}
			}
		}
	}

	public static void zeroPeriodValidation(){
		if(trigger.isBefore && trigger.isUpdate){
			Set <Id> pIds = new Set<Id>();
			Set <Id> fyIds = new Set<Id>();
			Set <Id> cIds = new Set<Id>();
			Map<Id,List<Period__c>> mFiscalYearIDPeriod = new Map<Id,List<Period__c>>();
			Map<Id,Period__c> mFiscalYearIDZeroPeriod = new Map<Id,Period__c>();
			List<Period__c> fiscalYearPeriods = new List<Period__c>();
	        for(Period__c p :  (List<Period__c>)Trigger.new){
	            pIds.add(p.ID);
	            fyIds.add(p.FiscalYear__c);
	            cIds.add(p.Company__c); 
	        }
	        List<Period__c> periods = [SELECT id, Name,Period_Start__c, Period_End__c, Open__c ,Company__c, Period_Number__c ,
		 										Type__c,
		 										next_period__c, next_period__r.period_start__c, next_period__r.period_end__c,
		     									next_period__r.next_period__c, next_period__r.next_period__r.next_period__r.period_start__c, 
		 										Closed__c,Permanently_Closed__c,
												InterCompany_Subledger_CutOff__c, Prior_Period__r.InterCompany_Subledger_CutOff__c,
												AR_Subledger_CutOff__c, Prior_Period__r.AR_subledger_Cutoff__c,
												AP_Subledger_CutOff__c, Prior_Period__r.AP_subledger_Cutoff__c,
												FA_Subledger_CutOff__c, Prior_Period__r.FA_subledger_Cutoff__c,
												Inventory_Subledger_CutOff__c, Prior_Period__r.Inventory_subledger_Cutoff__c,
												Shipment_Subledger_CutOff__c,FiscalYear__c, Prior_Period__r.Shipment_subledger_Cutoff__c,
												JE_Cutoff__c,Prior_Period__r.JE_Cutoff__c,
												Receiving_Subledger_CutOff__c, Prior_Period__r.Receiving_subledger_Cutoff__c
											from Period__c
											where FiscalYear__c in :fyIds];
	        for(Period__c p : periods){
		    	if(mFiscalYearIDPeriod.containsKey(p.FiscalYear__c)){
		    		List<Period__c> periodList = new List<Period__c> ();
		    		periodList = mFiscalYearIDPeriod.get(p.FiscalYear__c);
		    		periodList.add(p);
		    	}else{
		    		mFiscalYearIDPeriod.put(p.FiscalYear__c,new List<Period__c> {p});
		    	}
		    	if(p.Type__c =='Zero' || p.Type__c =='Period 13'){
		    		mFiscalYearIDZeroPeriod.put(p.FiscalYear__c,p);
		    	}
		    }  
			for(Period__c p :  (List<Period__c>)Trigger.new){
				if(trigger.oldMap.containsKey(p.ID)){
				    		
					Period__c localPeriod = new Period__c();
					Period__c zeroPeriod = new Period__c();
	
			    	if(p.type__c != 'Zero' && p.Type__c !='Period 13'){
						localPeriod = p;
			    	}
			    	if(mFiscalYearIDZeroPeriod.containsKey(p.FiscalYear__c)){
						zeroPeriod = mFiscalYearIDZeroPeriod.get(p.FiscalYear__c);
			    	}
			    	if(localPeriod.ID!= null && (localPeriod.type__c != 'Zero' && localPeriod.type__c != 'Period 13')){
			    			if(KSE.isFieldChanging('Open__c', localPeriod, trigger.oldMap)){
				    		if(localPeriod!=null&& zeroPeriod!=null){
				    			if(zeroPeriod.Closed__c == true && (localPeriod.type__c != 'Zero' && localPeriod.type__c != 'Period 13')){
				    				p.addError('The Period 13 Period associated with the fiscal year is Closed' );
				    			}
				    		}
				        }
			    	}
			    	if(zeroPeriod!= null && (p.Type__c =='Zero' || p.Type__c =='Period 13')){
						if(KSE.isFieldChanging('Closed__c', p, trigger.oldMap)||KSE.isFieldChanging('Permanently_Closed__c', p, trigger.oldMap)){
						  	fiscalYearPeriods = mFiscalYearIDPeriod.get(p.FiscalYear__c);
						  	for(Period__c locp : fiscalYearPeriods){
					    		if(locp.Open__c == true && (locp.Type__c!='Zero' && locp.Type__c!='Period 13')){
					    			p.addError('The Period 13 Period can be closed only if all the periods associated with the Fiscal period is closed' );
					    		}
					    	}
						}
					}
				}
			} 
		}
	}




    static map < Id, Period__c> periodMap = new Map <Id, Period__c>();
	
	public static void priorPeriodValidation(){
		if(trigger.isafter && (trigger.isInsert || trigger.isUpdate)){
            if ( periodMap.size()== 0 ) {
            	for(Period__c p: [Select id, Name, Company__c, prior_period__r.company__c, Period_Start__c, Period_End__c,prior_period__r.InterCompany_Subledger_CutOff__c,
							Prior_Period__c, Prior_Period__r.Period_End__c,prior_Period__r.JE_Cutoff__c, prior_period__r.ar_subledger_cutOff__c,
							prior_period__r.ap_subledger_cutOff__c, prior_period__r.fa_subledger_cutOff__c, prior_period__r.shipment_subledger_cutOff__c, 
							prior_period__r.receiving_subledger_cutOff__c,	prior_period__r.inventory_subledger_cutOff__c, prior_period__r.type__c,//FIN-1160
							ar_subledger_cutOff__c, ap_subledger_cutOff__c, fa_subledger_cutOff__c, shipment_subledger_cutOff__c, receiving_subledger_cutOff__c, inventory_subledger_cutoff__c, 
							next_Period__c, next_period__r.Period_End__c, Type__c
							from Period__c
                            where id in :trigger.new
                            ]) 
                {
                	if(p.Type__c != 'Zero' && p.Type__c !='Period 13'){
                		periodMap.put(p.Id, p);
                	}
                }
            }
			for(Period__c p : (List<Period__c>) trigger.new){
				Period__c mPeriod;
				if(periodMap.containsKey(p.id) && (p.Type__c != 'Zero' && p.Type__c !='Period 13')){
					mPeriod = periodMap.get(p.id);
						Datetime priorPeriodEndDate;
						Id priorPeriodCompany;
						if(mPeriod.Prior_Period__c != null && mPeriod.Prior_Period__r != null){
							priorPeriodEndDate = mPeriod.Prior_Period__r.Period_End__c ;
							priorPeriodCompany = mPeriod.prior_period__r.Company__c;
						}
						//system.debug(logginglevel.info,'priorPeriodEndDate:'+priorPeriodEndDate+'   mPeriod.Period_Start__c:'+mPeriod.Period_Start__c);
						if(mPeriod.prior_Period__c != null && mPeriod.Prior_Period__r != null && priorPeriodEndDate != null && mPeriod.Period_Start__c <> priorPeriodEndDate){
							//FIN-946 - Removing log info in  error message if user gives incorrect prior period.
							//If user gives null values the system prepopulates them as part validatePeriodDates method.
							p.addError(Label.Prior_Period_End_match_current_Period_Start);
						}
						if( mPeriod.prior_Period__c != null && mPeriod.Prior_Period__r != null && priorPeriodCompany!= null &&  (priorPeriodCompany != mPeriod.Company__c) ){
							p.addError(Label.Prior_Period_company_match_current_period_company);
					}
					    //FIN-1160 - Cannot add Hist/Adj periods inbetween fiscal periods.
					    if(mPeriod.prior_Period__c != null && mPeriod.Prior_Period__r != null && (mperiod.type__c=='Adjustment'))
					    {
					    	if(mPeriod.Prior_Period__r.type__c=='Fiscal')
					    	{
							  p.addError(Label.Cannot_add_Adjustment_period_in_between_fiscal_periods);
					    		
					    	}
					    	
					    }
						for(String slcField: SLCList){
							String slcLabel = (slcField.substring(0,slcField.length()-1)).replaceAll('_',' ');
							Datetime priorPeriodSLC;
							if(mPeriod.prior_Period__c != null && mPeriod.Prior_Period__r != null){
								priorPeriodSLC = (Datetime) mPeriod.getSObject('prior_period__r').get(slcfield);
							}
							if(priorPeriodSLC != null &&  priorPeriodSLC >= mPeriod.Period_End__c){
								
								p.addError(Label.Period_end_should_be_greater+slcLabel);
							}
							
							Datetime nextPeriodEndDate;	
							if(mPeriod.next_Period__c != null && mPeriod.next_Period__r != null) 
							{
								nextPeriodEndDate = mPeriod.next_Period__r.Period_End__c;
							}
							
							if(nextPeriodEndDate != null && DateTime.valueof(mPeriod.get(slcfield)) > nextPeriodEndDate){
								
								p.addError(slcLabel+Label.Less_than_next_period_end_of_the_period);
							}
							
							if( DateTime.valueof(mPeriod.get(slcfield)) < mPeriod.Period_Start__c ){
								
								p.addError(slcLabel+Label.Greater_than_period_start);
							}
					}
				}
			}
		}
	}
	
	public static void assignGLDatePeriodJE(List<sObject> sObjRecs){
		
    	set<Id> companyIds = new Set<Id>();
    	Set<Period__c> openPeriodSet = new set<Period__c>();
        for(sObject sObj : sObjRecs ){
            companyIds.add((Id)sObj.get('Company__c'));
        }
        
 		Map<Id, List<Period__c>> mPeriods = getPeriodsMap(companyIds);
 		
 		for(sObject sObj : sObjRecs){
 			
 			Id companyId = (Id)sObj.get('Company__c');
			//Assign the Transaction Date Finalized Date from the Source Doc 
    		DateTime trxnDate = (DateTime)sObj.get('Transaction_Date__c');
    		DateTime finalDate = (DateTime)sObj.get('Finalized_Date__c');
    		boolean inClosedPeriod = true, inFuturePeriod = true, inOpenPeriod = false; 
        	//system.debug(logginglevel.info,'trxnDate:'+trxnDate);
        	//system.debug(logginglevel.info,'finalDate:'+finalDate);
 			
 			if(mPeriods.containsKey(companyId)){
 				
 				Map<Id, Period__c> iMPeriods = new Map<Id, Period__c>(mPeriods.get(companyId));
 				
 				//Check if this is a balance transfer journal entry - assign zero period from the balance transfer reference
 				//Anchana Changing below.
                //if(sObj.getSObjectType() == journal_entry__c.getSobjectType()){
                /*if(sObj.getSObjectType() == Accounting_Entry__c.getSobjectType()){
		 		//	if((string)sObj.get('Balance_Transfer__c') != null
		 		//			&& Transfer_Balance__c.getAll().containsKey((string)sObj.get('Balance_Transfer__c'))){
                       if((string)sObj.get('transaction_type__c')=='Year End')	
                       {
 		 		          id jeid=(id)sObj.get('journal_entry__c');
                         journal_entry__c je=[select id,name,period__C from journal_entry__C where id=:jeid];
		 				
		 			// Period__c iZeroPeriod = iMPeriods.get(Transfer_Balance__c.getAll().get((string)sObj.get('Balance_Transfer__c')).periodId__c);
		 			    id iZeroPeriodid=(id)sObj.get('period__c');
                        period__C iZeroPeriod=[select id,name,Period_start__c,period_end__c from period__c where id=:je.period__C];
		 				if(iZeroPeriod != null){
		 					Schema.sObjectType sType = sObj.getSObjectType();
		 					if(sType == Journal_Entry__c.getsObjectType()){
		 						if((boolean)sObj.get('Finalized__c')){
		 							assignGLDate(trxnDate, finalDate, sObj, iZeroPeriod);
		 							continue;		
		 						}
		 					}else if(sType == Accounting_Entry__c.getSobjectType()){
		 						assignGLDate(trxnDate, finalDate, sObj, iZeroPeriod);
		 						continue;
		 					}
		 				}
		 				
		 			}
	 				
	 			}*/
	 			
 				//Otherwise, period assignment logic as usual
        		for(Period__c thisPeriod : iMPeriods.values()){
        			if (trxnDate >= thisPeriod.Period_start__c && trxnDate < thisPeriod.Period_end__c && (thisPeriod.Type__c != 'Zero' && thisPeriod.Type__c != 'Period 13')) { 
        				//system.debug(logginglevel.info,' Inside if TD falls in this Period:'+trxnDate+'   thisPeriod.Period_start__c:'+thisPeriod.Period_start__c+'   thisPeriod.Period_end__c:'+thisPeriod.Period_end__c);
        				Datetime iCutoff = thisPeriod.JE_Cutoff__c == null ? thisPeriod.period_end__c : thisPeriod.JE_Cutoff__c;
        				if(finalDate <= iCutoff){
        					//system.debug(logginglevel.info,'iCutoff:'+iCutoff);
        					assignGLDate(trxnDate, finalDate, sObj, thisPeriod);
        					//system.debug('sObj: ' + sobj);
        				}
        			}
        		}
        		
 				
  
        	}
 		}
	}
	
	public static void assignGLDatePeriod(List<sObject> sObjRecs){
		
    	set<Id> companyIds = new Set<Id>();
    	Set<Period__c> openPeriodSet = new set<Period__c>();
        for(sObject sObj : sObjRecs ){
            companyIds.add((Id)sObj.get('Company__c'));
        }
        
 		Map<Id, List<Period__c>> mPeriods = getPeriodsMap(companyIds);
        Map<String, String> ObjectToSLCMap = AccountingEntryService.buildSubledgerNameMap();
        
        for(sObject sObj : sObjRecs){
        	

    		Schema.SObjectType objectSchema= sObj.getSObjectType();
    		Schema.DescribeSObjectResult sObjectResult = objectSchema.getDescribe();
            String objectName = sObjectResult.getLocalName();
    		if(objectName.equalsIgnoreCase('Journal_Entry__c')){ // Logic is only for JEsfor year end adjustment JE perid should not be erased if it already exists at finalize
				string typestr = (string) sObj.get('type__c');
				if(typestr.equalsIgnoreCase('Year End Adjustment')){
					continue;
				
				}
    		}
        	//system.debug('sObj: ' + sObj);
			Id companyId = (Id)sObj.get('Company__c');
			//Assign the Transaction Date Finalized Date from the Source Doc 
    		DateTime trxnDate = (DateTime)sObj.get('Transaction_Date__c');
    		DateTime finalDate = (DateTime)sObj.get('Finalized_Date__c');
    		DateTime postDate = (DateTime)sObj.get('Posting_Date__c');
    		postDate = postDate == null ? finalDate : postDate;
    		
            Boolean isVoid = false;
            Datetime voidDate;
    		if(objectName.equalsIgnoreCase('Journal_Entry__c')){ // Logic is only for JEs as JEs gets updated with void flag and void date after the finalization.
				isVoid = (Boolean) sObj.get('Void__c');
				voidDate = (Datetime) sObj.get('Void_Date__c');
			}
			if(isVoid || voidDate != null){ // If the transaction is void then break no need to continue and assign the date again.
				//break;
				continue;
			}
    		
    		boolean inClosedPeriod = true, inFuturePeriod = true, inOpenPeriod = false; 
        	
        	if(mPeriods.containsKey(companyId)){
        		
        		String subledgerfield, srcDocObjName;
        	
	       	 	srcDocObjName = (String)sObj.get('source_document_object_name__c');
	        	
	        	if(ObjectToSLCMap.containsKey(srcDocObjName)){
	        		subledgerfield = ObjectToSLCMap.get(srcDocObjName); // to get the subledger field name from the period for different source documents associated with AE
	        	}
	        	
	        	for(Period__c thisPeriod : mPeriods.get(companyId)){
        			
        			if(thisPeriod.Type__c == 'Zero' || thisPeriod.Type__c == 'Historical' || thisPeriod.Type__c =='Period 13'){
        				continue;
        			}
        			
        			//Assign Current Subledger Cutoff based on the type of Source Doc
	          		DateTime currentPeriodSubledgerCutOff = (DateTime)thisPeriod.get(subledgerfield);
	          		if(currentPeriodSubledgerCutOff == null){
        				currentPeriodSubledgerCutOff = thisPeriod.Period_End__c; 
        			}
        			
        			//Assign the Prior Subledger Cutoff based on the type of Source Doc
	          		DateTime priorPeriodSubledgerCutOff;
        			if(thisPeriod.Prior_Period__c != null){
        				priorPeriodSubledgerCutoff = (DateTime)thisPeriod.getSobject('Prior_Period__r').get(subledgerfield);
        				if(priorPeriodSubledgerCutoff == null){
        					priorPeriodSubledgerCutOff = thisPeriod.Period_Start__c;
        				}
        			}else{
        				priorPeriodSubledgerCutOff = thisPeriod.Period_Start__c; // TODO: Revisit this logic after Period object field validations.
        			}
	        		
	        			
	        		if (trxnDate < thisPeriod.Period_start__c) { 
	        			inFuturePeriod = false; 
	        		} // Means it is in closed period -- inClosedPeriod = true && inOpenPeriod = false 
	        		else if (thisPeriod.Period_end__c <= trxnDate) { 
	        			inClosedPeriod = false; 
	        		} // Means it is in future period -- inFuturePeriod = true && inOpenPeriod = false 
	  				
	  				if (trxnDate < thisPeriod.Period_end__c) {
	  					//system.debug('potentially in this period - can’t be after period end to be in this period: ' + thisPeriod);
	    				// need to check two cases
	      				// case 1: when transaction date is before the finalized date, just need to pick up the right period finalized
						
	      				/*if (trxnDate <= finalDate 
		      					&& priorPeriodSubledgerCutOff <= finalDate 
		      					&& finalDate < currentPeriodSubledgerCutOff){
	      						
	        				system.debug('Inside the TD <= FD if loop');
	        				assignGLDate(trxnDate, finalDate, sObj, thisPeriod);
	        				inOpenPeriod = true;
	    					break;
	     					
	           			}*/
	           			//FIN-290
	           			if(trxnDate <= postDate){
	           				if(thisPeriod.Period_start__c <= trxnDate
	           					&& postDate < priorPeriodSubledgerCutOff )
	           				{
	           					assignGLDate(trxnDate, postDate, sObj, thisPeriod);
	        				 	inOpenPeriod = true;
	      						break;
	      						
	           				}else if(priorPeriodSubledgerCutOff <= postDate
	           					&& postDate < currentPeriodSubledgerCutOff )
	           				{
	           					assignGLDate(trxnDate, postDate, sObj, thisPeriod);
	        				 	inOpenPeriod = true;
	      						break;
	      						
	           			}
	           			}
	         			// case 2: when transaction date if after the finalized date, check 2 subcases
	         			else if(postDate < trxnDate){
	         				
	         				//system.debug('Inside the FD < TD if loop');
         				   	// case 2a: if in prior period, needs to be after prior period subledger cutoff
	        				if(priorPeriodSubledgerCutOff <= postDate 
	        						&& postDate < thisPeriod.Period_start__c) {
	        							
	        				 	assignGLDate(trxnDate, postDate, sObj, thisPeriod);
	        				 	inOpenPeriod = true;
	      						break;
        				 	}
	        				// case 2b: if in this period, needs to be before subledger cutoff	
	        				else if (thisPeriod.Period_start__c <= trxnDate
	        						&& postDate < currentPeriodSubledgerCutOff){
	        							
	        					assignGLDate(trxnDate, postDate, sObj, thisPeriod);
	        					inOpenPeriod = true;
	     						break;
	           				}
	        			}
	
	        		} //End trxnDate < period end
	        		
	        	} // End of period for loop
	        	
	        	//TODO: If a period hasn't been assigned by now - throw an exception?
        	
        	}//End if mPeriods.containsKey(companyId)
        	else{
        		//TODO: THROW EXCEPTION NO PERIODS
        	}
        	
        	// TODO: Debugs in below logic need to be replaced by .... The exception framework tasks (CONTACT SUPPORT IMMEDIATELY)
        	if(!inOpenPeriod){
				if(inClosedPeriod){
					//system.debug(logginglevel.info,'This record is in closed period'); 
				}else if(inFuturePeriod){
					//system.debug(logginglevel.info,'This record is in future period');
				}else{
					//system.debug(logginglevel.info,'Unexpected error occurred !!');
				}
        	}
    	} // End of sObj for loop
	}
	
	/* 
		@Description: This private method is used to choose the most appropriate 
		GL Date given the proper period and the Transaction/Posting Dates
	*/
	private static void assignGLDate(DateTime trxnDate, DateTime postingDate, sObject sObj, Period__c period){
		
		system.debug(logginglevel.info,'Period in assignGLDate'+period);
		
		If (period.Period_start__c  <= trxnDate){
		    sObj.put('GL_Date_Time__c', trxnDate); 
		    sObj.put('Period__c', period.Id);
		}else if(period.Period_start__c > postingDate){
		    sObj.put('GL_Date_Time__c', period.Period_start__c); 
		    sObj.put('Period__c', period.Id);
		}else if(period.Period_end__c >postingDate){
		   sObj.put('GL_Date_Time__c', postingDate);  
		    sObj.put('Period__c', period.Id);
		}else{
		   //sObj.put('GL_Date_Time__c', period.Period_end__c);
		     sObj.put('GL_Date_Time__c', (period.Period_end__c).addSeconds(-1));  
		    sObj.put('Period__c', period.Id);
		}
			            
			// 		if (period.Period_start__c <= trxnDate) {
			// 			sObj.put('GL_Date_Time__c', trxnDate); 
			// 			sObj.put('Period__c', period.Id);
			//     	}else if (period.Period_start__c <= postingDate){
			//  			sObj.put('GL_Date_Time__c', postingDate); 
			//  			sObj.put('Period__c', period.id);
			//  		}else { 	
			//  			sObj.put('GL_Date_Time__c', period.Period_start__c); 
			//  			sObj.put('Period__c', period.Id);
			// 		}
	}
	//  FIN-610 Allow only 1 Historical period and 1 Adjustment period.
 	/* 	@Description
 		This method prevents adding a additional historical or adjustment period for a same company.
 	*/ 	
 	public static void validatePeriodTypes(List<Period__c> periods){
 		Map<string, Integer> mCompanyNumOfNonFiscalPeriods = new Map<string, Integer>();
 		set<Id> compIdsWithChgs = new set<Id>();
 		set<Id> periodIdsWithChgs = new set<Id>();		
 		
 		//Collect the Non-Fiscal Period count at company level Including the periods in trigger scope.
		for(period__c p:periods)
		{
            if(p.Type__c=='Historical' || p.Type__c == 'Adjustment')
            {
            	String Key = p.company__c+'-'+p.type__c;            	
            	if(mCompanyNumOfNonFiscalPeriods.containskey(key))
            	{
            		Integer currCount=mCompanyNumOfNonFiscalPeriods.get(Key);
            		mCompanyNumOfNonFiscalPeriods.put(Key,currCount+1);
            		
            	}
            	else
            	{
             		mCompanyNumOfNonFiscalPeriods.put(Key,1);
            		
            	}
                compIdsWithChgs.add(p.company__c);
                if(p.Id!=null)//Indicates period rec update as it called from Before Event.
                {
                 	periodIdsWithChgs.add(p.Id) ;          	              	
                }

            }
		}
		if(compIdsWithChgs.size()>0)
		{
			mCompanyNumOfNonFiscalPeriods=PeriodService.addExistingNonFiscalPeriodCount(compIdsWithChgs,periodIdsWithChgs,mCompanyNumOfNonFiscalPeriods);
			
		}		
		//Validate the Non-Fiscal period count for the periods' in current scope.
		for(period__c p:periods)
		{
			string key = p.company__c +'-'+ p.type__c;
			
			//TODO:Move to custom label.
			if(p.type__c=='Historical')
			{
				if(mCompanyNumOfNonFiscalPeriods.get(key)>1)
				{
				      p.addError(Label.Cannot_have_more_than_one_Historical_Period_for_the_company);											
					
				}
				
			}
			if(p.type__c=='Adjustment')
			{
				if(mCompanyNumOfNonFiscalPeriods.get(key)>1)
				{
				      p.addError(Label.Cannot_have_more_than_one_Adjustment_Period_for_the_company);																
				}				
			}
		}

		

 	}
 	
	
 	/* 	@Description
 		This method is intended to be used with before insert/update and after delete
 		Sequential periods should begin and end at the same Date/Time for each company
 	*/ 
 	public static void validatePeriodDates(List<Period__c> periods){
 		
 		Set<Id> periodIds = new Set<Id>();
 		Period__c currentPeriod;
 	 	Period__c firstPeriod;
 	 	List<Period__c> priorPeriods = new List<Period__c>();
 		id firstRecordId;
 		
 		Map<Id, List<PeriodComparable>> mCompanyPeriods = new Map<Id, List<PeriodComparable>>();
 		//Loop through the periods provided, organize them by company as periodcomparables
 		for(Period__c p : periods){
 			periodIds.add(p.Id);
            //FIN-213 Prevent gap between periods by addding changing period type
            //Comparables are checked only for Fiscal and Adjustment periods      
            //Historical periods can float across the year.     
            if(p.Type__c!='Historical' && p.Type__c != 'Zero' && p.Type__c != 'Period 13')
            {
                if(trigger.isInsert || trigger.isUpdate){
                    PeriodComparable pc = new PeriodComparable(p);
                    if(mCompanyPeriods.containsKey(p.company__c)){
                        mCompanyPeriods.get(p.company__c).add(pc);
                    }else{
                        mCompanyPeriods.put(p.company__c, new List<PeriodComparable>{pc});
                    }
                }else{
                    if(!mCompanyPeriods.containsKey(p.company__c)){
                        mCompanyPeriods.put(p.company__c, new List<PeriodComparable>());
                    }
                }                
            }
            //FIN-213 Prevent gap between periods due to change in period type
            else
            {
                mCompanyPeriods.put(p.company__c, new List<PeriodComparable>());
   
            }

 		}
 		//Add all other existing periods from the database in to the comparables
 		for(Period__c p : PeriodService.returnPeriodsWithExclusions(periodIds, mCompanyPeriods.keySet())){
 			PeriodComparable pc = new PeriodComparable(p);
 			if(mCompanyPeriods.containsKey(p.company__c)){
 				mCompanyPeriods.get(p.company__c).add(pc);
 			}else{
 				mCompanyPeriods.put(p.company__c, new List<PeriodComparable>{pc});
 			}
 		}
 		
 		for(List<PeriodComparable> periodComparables : mCompanyPeriods.values()){
	 		if(periodComparables.size() > 0){
	 			
	 			//Sort based on comparable implementation, then loop through and validate period dates
		 		periodComparables.sort();
		 		
	 			//Assign entry criteria from the first record if there are no records returned from the database
		 		Datetime endDate = periodComparables[0].period.period_start__c;
	 			Id prevPeriodId;
	 			Id nextPeriodId;
	 			
	 			//system.debug(logginglevel.info,'endDate before for loop:' + endDate);
	 			for(Integer i= 0 ; i < periodComparables.size(); ++i){	
	 				//system.debug(logginglevel.info,'i:'+i);
	 				//system.debug(logginglevel.info,'endDate:' + endDate + ' name' + periodComparables[i].period.name);
                    
                    if(periodComparables[i].period.type__c == 'Zero' || periodComparables[i].period.Type__c == 'Period 13'){
                    	continue;
                    }
                    
	 				if(periodComparables[i].period.period_start__c != endDate){
                        //There is a problem, we need the period start and end to match
	 					if(trigger.isExecuting){
		 					//if(trigger.isInsert || trigger.isUpdate){
		 					//KNDY-5404
		 					if(trigger.isInsert){
		 						trigger.new[0].addError(Label.Each_period_must_end_at_the_next_period_start);
		 					}
		 					else if(trigger.isUpdate){	
		 						
			 					if(trigger.newMap.containsKey(periodComparables[i].period.Id)){
			 						//system.debug(logginglevel.info,'Inside isUpdate if loop');
			 						trigger.newMap.get(periodComparables[i].period.Id).addError(Label.Each_period_must_end_at_the_next_period_start);
			 					}else{
			 						//system.debug(logginglevel.info,'Inside isUpdate else loop');
			 						trigger.new[0].addError(Label.Each_period_must_end_at_the_next_period_start);
			 					}
		 					}else if(trigger.isAfter && trigger.isDelete){
		 						//system.debug(logginglevel.info,'Inside isDelete');
		 						trigger.old[0].addError(Label.Each_period_must_end_at_the_next_period_start);
		 					}
	 					}
	 				}
	 			
	 				//If we are updating, go ahead assign the the prior and next period while we have it available	 	
	 				//Primary key workflow rule on Period obj triggers an update action and execution flow comes to this code block .
	 				//Thereby ,newly inserted periods with null prior and next periods also get  populated with appropriate dates.			
	 				if(trigger.isExecuting){
		 				if(trigger.isBefore && trigger.isUpdate){		 					
		 					if(i < periodComparables.size()-1) {
		 						nextPeriodId = periodComparables[i+1].period.Id;
		 					}else{
		 						nextPeriodId = null;
                            }
                            
		 					if(trigger.newMap.containsKey(periodComparables[i].period.Id)){
		 						
		 						trigger.newMap.get(periodComparables[i].period.Id).put('prior_period__c', prevPeriodId);
		 						trigger.newMap.get(periodComparables[i].period.Id).put('next_period__c', nextPeriodId);
		 	
		 					}
		 				}
	 				}
	 				
	 				prevPeriodId = periodComparables[i].period.Id;
	 				//system.debug(logginglevel.info,'periodComparables[i].period.period_end__c: '+periodComparables[i].period.period_end__c);
	 				endDate = periodComparables[i].period.period_end__c;
	 			}
	 			
	 		} 
	 		
 		}
 		
 	}
 	
 	//Returns all periods to scrub and validate date intervals
 	public static List<Period__c> returnPeriodsWithExclusions(Set<Id> excludePeriods, Set<Id> companyIds){
 		return [SELECT Id, name, period_start__c, period_end__c, open__c, closed__c, permanently_closed__c, type__c, InterCompany_Subledger_CutOff__c,
 					fiscal__c, fiscal_year__c, year_start_date__c, year_end_date__c, period_number__c, quarter_number__c,
 					company__c,company__r.Name,JE_Cutoff__c,Prior_Period__c,AR_Subledger_Cutoff__c,Shipment_Subledger_Cutoff__c,
 					AP_Subledger_Cutoff__c,Receiving_Subledger_Cutoff__c,FA_Subledger_Cutoff__c,Inventory_Subledger_Cutoff__c
				FROM Period__c
				WHERE Id NOT IN :excludePeriods
				AND company__c IN :companyIds
                and Type__c != 'Historical' 
                and (Type__c != 'Zero' AND Type__c != 'Period 13')];//FIN-213 Historical periods are not included in comparision as they can float
 	}
 	
 	//Get already existing Non-Fiscal period outside Trigger scope.
 	public static map<string,integer> addExistingNonFiscalPeriodCount(Set<Id> companyIds,set<Id> excludePeriodIds,map<string,integer> mCompNumofFiscalPeriods){
 		list<period__c> nonFiscalPeriodsOutsideScope= [SELECT Id, name, period_start__c, period_end__c, open__c, closed__c, permanently_closed__c, type__c, 
									 					fiscal__c, fiscal_year__c, year_start_date__c, year_end_date__c, period_number__c, quarter_number__c,
									 					company__c,company__r.Name,JE_Cutoff__c,Prior_Period__c,AR_Subledger_Cutoff__c,Shipment_Subledger_Cutoff__c,
									 					AP_Subledger_Cutoff__c,Receiving_Subledger_Cutoff__c,FA_Subledger_Cutoff__c,Inventory_Subledger_Cutoff__c,InterCompany_Subledger_CutOff__c
													FROM Period__c
													WHERE  company__c IN :companyIds
													and Id not IN :excludePeriodIds
									                and Type__c != 'Fiscal' 
									                and (Type__c != 'Zero' AND Type__c != 'Period 13')];
	  for(period__c p:nonFiscalPeriodsOutsideScope)
	  {
	  	String Key = p.company__c+'-'+p.type__c;
	  	Integer CurrCount=mCompNumofFiscalPeriods.get(key);
	  	If(CurrCount!=null)
	  	{
	  	  mCompNumofFiscalPeriods.put(key,CurrCount+1);	  		
	  	}	  	
	  }
	  return mCompNumofFiscalPeriods;
 	} 	
 	/*
 		@Description
 		Returns a map of the companyId to it's respective open or future periods, ordered by period end date
 	*/
 	private static DateTime currDt = system.now();
 	public static Map<Id, List<Period__c>> getPeriodsMap(set<Id> companyIds) {
     
     	Map<Id, List<Period__c>> mCompanyPeriods = new Map<Id, List<Period__c>>();
     	List<Period__c> periods = [SELECT id, Name,Period_Start__c, Period_End__c, Open__c ,Company__c, Period_Number__c ,
 										Type__c, InterCompany_Subledger_CutOff__c,
										AR_Subledger_CutOff__c, Prior_Period__r.AR_subledger_Cutoff__c,
										AP_Subledger_CutOff__c, Prior_Period__r.AP_subledger_Cutoff__c,
										FA_Subledger_CutOff__c, Prior_Period__r.FA_subledger_Cutoff__c,Prior_Period__r.InterCompany_Subledger_CutOff__c,
										Inventory_Subledger_CutOff__c, Prior_Period__r.Inventory_subledger_Cutoff__c,
										Shipment_Subledger_CutOff__c, Prior_Period__r.Shipment_subledger_Cutoff__c,
										Receiving_Subledger_CutOff__c, Prior_Period__r.Receiving_subledger_Cutoff__c,
                                   		JE_CutOff__c, Prior_Period__r.JE_Cutoff__c

                    					FROM Period__c 
                    					WHERE (Open__c = true OR Period_Start__c >= :currDt)
                    					AND Company__c IN :companyIds
                    					AND Type__c != 'Historical'
                    					ORDER BY period_end__c asc];
     	for(Period__c p : periods){
                        						
     		if(mCompanyPeriods.containsKey(p.company__c)){
 				mCompanyPeriods.get(p.company__c).add(p);
 			}else{
 				mCompanyPeriods.put(p.company__c, new List<Period__c>{p});
 			}
     	}
     	return mCompanyPeriods;
     }
 	
     public static Map<Id, List<Period__c>> getAllPeriodsMap(set<Id> companyIds) {
     
     	Map<Id, List<Period__c>> mCompanyPeriods = new Map<Id, List<Period__c>>();
     	List<Period__c> periods = [SELECT id, Name,Period_Start__c, Period_End__c, Open__c ,Company__c, Period_Number__c ,
 										Type__c,
 										next_period__c, next_period__r.period_start__c, next_period__r.period_end__c,
     									next_period__r.next_period__c, next_period__r.next_period__r.next_period__r.period_start__c, 
 										Closed__c,Permanently_Closed__c,
										AR_Subledger_CutOff__c, Prior_Period__r.AR_subledger_Cutoff__c,prior_Period__r.InterCompany_Subledger_CutOff__c,
										AP_Subledger_CutOff__c, Prior_Period__r.AP_subledger_Cutoff__c,InterCompany_Subledger_CutOff__c,
										FA_Subledger_CutOff__c, Prior_Period__r.FA_subledger_Cutoff__c,
										Inventory_Subledger_CutOff__c, Prior_Period__r.Inventory_subledger_Cutoff__c,
										Shipment_Subledger_CutOff__c,FiscalYear__c, Prior_Period__r.Shipment_subledger_Cutoff__c,
										Receiving_Subledger_CutOff__c, Prior_Period__r.Receiving_subledger_Cutoff__c,
										AR_Subledger_Closed__c, AP_Subledger_Closed__c, Shipment_Subledger_Closed__c, Receiving_Subledger_Closed__c,
										Inventory_Subledger_Closed__c, FA_Subledger_Closed__c, GL_Close__c,InterCompany_Subledger_Closed__c,
                                        JE_CutOff__c, Prior_Period__r.JE_Cutoff__c

                    					FROM Period__c 
                    					WHERE Company__c IN :companyIds
                    					AND Type__c != 'Historical'
                    					ORDER BY period_end__c asc];
     	for(Period__c p : periods){
                        						
     		if(mCompanyPeriods.containsKey(p.company__c)){
 				mCompanyPeriods.get(p.company__c).add(p);
 			}else{
 				mCompanyPeriods.put(p.company__c, new List<Period__c>{p});
 			}
     	}
     	return mCompanyPeriods;
	}
	
	private static map<Id, List<Period__c>> mHistoricalPeriods;
	public static Map<Id, List<Period__c>> getHistoricalPeriods(){
		
		if(mHistoricalPeriods == null){
			mHistoricalPeriods = new Map<Id, List<Period__c>>();
	     	List<Period__c> periods = [SELECT id, Name,Period_Start__c, Period_End__c, Open__c ,Company__c, Period_Number__c ,
	 										Type__c, Closed__c, Permanently_Closed__c, 	 										
	 										next_period__c, next_period__r.period_start__c, next_period__r.period_end__c,
	     									next_period__r.next_period__c, next_period__r.next_period__r.next_period__r.period_start__c, 
	 										InterCompany_Subledger_CutOff__c,Prior_Period__r.InterCompany_Subledger_CutOff__c,
											AR_Subledger_CutOff__c, Prior_Period__r.AR_subledger_Cutoff__c,
											AP_Subledger_CutOff__c, Prior_Period__r.AP_subledger_Cutoff__c,
											FA_Subledger_CutOff__c, Prior_Period__r.FA_subledger_Cutoff__c,
											Inventory_Subledger_CutOff__c, Prior_Period__r.Inventory_subledger_Cutoff__c,
											Shipment_Subledger_CutOff__c, Prior_Period__r.Shipment_subledger_Cutoff__c,
											Receiving_Subledger_CutOff__c, Prior_Period__r.Receiving_subledger_Cutoff__c,
								 		    JE_CutOff__c, Prior_Period__r.JE_Cutoff__c
											
	                    					FROM Period__c 
	                    					WHERE Type__c = 'Historical'
	                    					//AND Company__c IN :companyIds
	                    					ORDER BY period_end__c asc];
	     	for(Period__c p : periods){
	                        						
	     		if(mHistoricalPeriods.containsKey(p.company__c)){
	 				mHistoricalPeriods.get(p.company__c).add(p);
	 			}else{
	 				mHistoricalPeriods.put(p.company__c, new List<Period__c>{p});
	 			}
	     	}
	     	
	     	
		}
     	return mHistoricalPeriods;
	}
 	
 	private static DateTime availablePeriodOpen;
 	public static DateTime getAvailablePeriodOpen(){
 		if(availablePeriodOpen == null){
 			AggregateResult arOpenPeriod = [SELECT MIN(Period_Start__c) periodStart
 												FROM Period__c
 												WHERE (Type__c != 'Zero' AND Type__c != 'Period 13')
 												AND Type__c != 'Historical'
 												AND Open__c = true
 												//AND Closed__c = false
 												//AND Permanently_Closed__c = false
 												AND Period_Start__c != null];
 			availablePeriodOpen = (DateTime)arOpenPeriod.get('periodStart');
 		}
 		return availablePeriodOpen;
 	}
 	
 	public class PeriodComparable implements Comparable{
 		
 		public PeriodComparable(Period__c inPeriod){
 			period = inPeriod;
 		}
 		
 		public Period__c period;
 		
 		public integer compareTo(Object compareTo){
 			PeriodComparable periodComp = (PeriodComparable)compareTo;
 			
 			if(period.Period_End__c == periodComp.period.Period_End__c){
 				return 0;
 			}else if(period.Period_End__c > periodComp.period.Period_End__c){
 				return 1;
 			}else{
 				return -1;
 			}
 		}
 	}
 	public class PeriodRetrievalDefinition{
 		public Id SDId {get;set;}
 		public string inputDateType {get;set;}
 		
 		public PeriodRetrievalDefinition(Id SDID,String inputDateType){
 			  this.SDId=SDID;
 			  this.inputDateType = inputDateType;
 		}
 	}
 	public class PeriodDateDefinition {
         sobject sobj {get;set;}
 		 String Datetype {get;set;} //-- Void/Transaction
 		 Datetime FD {get;set;}
 		 Datetime td {get;set;}
 		 DateTime pd {get;set;}

    }

    public class checkPeriodResult {
         public boolean periodOpen {get;set;}
         public boolean subledgerOpen {get;set;}

    }    
    
    public static map<string, list<map<datetime,checkPeriodResult>>> checkOpenPeriodAndSubledgerForDate(map<string,list<datetime>> mInputData,id companyId){
        
		map<string, list<map<datetime,checkPeriodResult>>> resultMap = new map<string, list<map<datetime,checkPeriodResult>>>();
        SOQLUtil soql = new SOQLUtil('Period__c');
        Set<String> Fields = new set<string>{'id','Open__c','AP_Subledger_Closed__c','AR_Subledger_Closed__c','FA_Subledger_Closed__c','Inventory_Subledger_Closed__c','Period_Closed__c','Receiving_Subledger_Closed__c','Intercompany_Subledger_Closed__c',
                                             'AP_Subledger_Cutoff__c','AR_Subledger_Cutoff__c','FA_Subledger_Cutoff__c','InterCompany_Subledger_Cutoff__c','JE_Cutoff__c','Receiving_Subledger_Cutoff__c','Inventory_Subledger_Cutoff__c',
                                             'Prior_Period__r.AP_Subledger_Cutoff__c','Prior_Period__r.AR_Subledger_Cutoff__c','Prior_Period__r.FA_Subledger_Cutoff__c','Prior_Period__r.InterCompany_Subledger_Cutoff__c','Prior_Period__r.JE_Cutoff__c','Prior_Period__r.Receiving_Subledger_Cutoff__c','Prior_Period__r.Inventory_Subledger_Cutoff__c'} ;
        String whereClause = 'Company__c =: companyId';
        soql.addFields(Fields);
        soql.setWhereClause(whereClause);
        list<period__c> periods = Database.query(soql.getQuery());
        period__c selectedPeriod = new period__c();
        for(string objectName:mInputData.keyset()){
        	list<datetime> dateTimeList = mInputData.get(objectName);
        	for(datetime inputDate:dateTimeList){
    			checkPeriodResult result = new checkPeriodResult();
		        map<datetime,checkPeriodResult> inputDateMap = new map<datetime,checkPeriodResult>();
        		for(period__c p:periods){
			        if(inputDate == null){
			            result.periodOpen = false;
			            result.subledgerOpen = false;
			            inputDateMap.put(inputDate,result);
						if(!resultMap.containskey(objectName)){
							resultMap.put(objectName,new list <map<datetime,checkPeriodResult>>{inputDateMap});
						}
						else{
							resultMap.get(objectName).add(inputDateMap);
						}
			        	continue;        
			        }
		            else if (new Set<string>(SubledgerService.mSubledgerObjects.get(SubledgerService.Subledger.AP)).contains(objectName) && (inputDate >= p.Prior_Period__r.AP_Subledger_Cutoff__c &&  inputDate <= p.AP_Subledger_Cutoff__c)  && p.AP_Subledger_Closed__c != null){
		               	result.subledgerOpen = true;
				        if( p.open__c != true){
				            result.periodOpen = false;
				        }else{
				            
				            result.periodOpen = true;            
				        }
			            inputDateMap.put(inputDate,result);
						if(!resultMap.containskey(objectName)){
							resultMap.put(objectName,new list <map<datetime,checkPeriodResult>>{inputDateMap});
						}
						else{
							resultMap.get(objectName).add(inputDateMap);
						}
		               	continue;
		            }
		            else if (new Set<string>(SubledgerService.mSubledgerObjects.get(SubledgerService.Subledger.AR)).contains(objectName) && (inputDate >= p.Prior_Period__r.AR_Subledger_Cutoff__c &&  inputDate <= p.AR_Subledger_Cutoff__c)  && p.AR_Subledger_Closed__c != null){
		               	result.subledgerOpen = true;
				        if( p.open__c != true){
				            result.periodOpen = false;
				        }else{
				            
				            result.periodOpen = true;            
				        }
			            inputDateMap.put(inputDate,result);
						if(!resultMap.containskey(objectName)){
							resultMap.put(objectName,new list <map<datetime,checkPeriodResult>>{inputDateMap});
						}
						else{
							resultMap.get(objectName).add(inputDateMap);
						}
		               	continue;
		            }
		            else if (new Set<string>(SubledgerService.mSubledgerObjects.get(SubledgerService.Subledger.FA)).contains(objectName) && (inputDate >= p.Prior_Period__r.FA_Subledger_Cutoff__c &&  inputDate <= p.FA_Subledger_Cutoff__c)  && p.FA_Subledger_Closed__c != null){
		                
		               	result.subledgerOpen = true;
				        if( p.open__c != true){
				            result.periodOpen = false;
				        }else{
				            
				            result.periodOpen = true;            
				        }
			            inputDateMap.put(inputDate,result);
						if(!resultMap.containskey(objectName)){
							resultMap.put(objectName,new list <map<datetime,checkPeriodResult>>{inputDateMap});
						}
						else{
							resultMap.get(objectName).add(inputDateMap);
						}
		               	continue;
		            }
		            else if (new Set<string>(SubledgerService.mSubledgerObjects.get(SubledgerService.Subledger.PERIOD)).contains(objectName) && (inputDate >= p.Prior_Period__r.JE_Cutoff__c &&  inputDate <= p.JE_Cutoff__c)  && p.Period_Closed__c != null){
		                
		               	result.subledgerOpen = true;
				        if( p.open__c != true){
				            result.periodOpen = false;
				        }else{
				            
				            result.periodOpen = true;            
				        }
			            inputDateMap.put(inputDate,result);
						if(!resultMap.containskey(objectName)){
							resultMap.put(objectName,new list <map<datetime,checkPeriodResult>>{inputDateMap});
						}
						else{
							resultMap.get(objectName).add(inputDateMap);
						}
		              	continue;
		           }
		            else if (new Set<string>(SubledgerService.mSubledgerObjects.get(SubledgerService.Subledger.INTERCOMPANY)).contains(objectName) && (inputDate >= p.Prior_Period__r.Intercompany_Subledger_Cutoff__c &&  inputDate <= p.Intercompany_Subledger_Cutoff__c)  && p.Intercompany_Subledger_Closed__c != null){
		                
		               	result.subledgerOpen = true;
				        if( p.open__c != true){
				            result.periodOpen = false;
				        }else{
				            
				            result.periodOpen = true;            
				        }
			            inputDateMap.put(inputDate,result);
						if(!resultMap.containskey(objectName)){
							resultMap.put(objectName,new list <map<datetime,checkPeriodResult>>{inputDateMap});
						}
						else{
							resultMap.get(objectName).add(inputDateMap);
						}
		               	continue;
		            }
		            else if (new Set<string>(SubledgerService.mSubledgerObjects.get(SubledgerService.Subledger.INVENTORY)).contains(objectName) && (inputDate >= p.Prior_Period__r.Inventory_Subledger_Cutoff__c &&  inputDate <= p.Inventory_Subledger_Cutoff__c)  && p.Inventory_Subledger_Closed__c != null){
		                
		               	result.subledgerOpen = true;
				        if( p.open__c != true){
				            result.periodOpen = false;
				        }else{
				            
				            result.periodOpen = true;            
				        }
			            inputDateMap.put(inputDate,result);
						if(!resultMap.containskey(objectName)){
							resultMap.put(objectName,new list <map<datetime,checkPeriodResult>>{inputDateMap});
						}
						else{
							resultMap.get(objectName).add(inputDateMap);
						}
		               	continue;
		            }
		            else if (new Set<string>(SubledgerService.mSubledgerObjects.get(SubledgerService.Subledger.RECEIVING)).contains(objectName) && (inputDate >= p.Prior_Period__r.Receiving_Subledger_Cutoff__c &&  inputDate <= p.Receiving_Subledger_Cutoff__c)  && p.Receiving_Subledger_Closed__c != null){
		                
		               	result.subledgerOpen = true;
				        if( p.open__c != true){
				            result.periodOpen = false;
				        }else{
				            
				            result.periodOpen = true;            
				        }
			            inputDateMap.put(inputDate,result);
						if(!resultMap.containskey(objectName)){
							resultMap.put(objectName,new list <map<datetime,checkPeriodResult>>{inputDateMap});
						}
						else{
							resultMap.get(objectName).add(inputDateMap);
						}
		               	continue;
		            }
            	}
            }
        }
        
        return resultmap;
        
    }
    public static Map<PeriodRetrievalDefinition,period__c> getPeriodsForSDs(list<sObject> sourceDocumentsRecs){
        String sObjName = sourceDocumentsRecs[0].ID.getSObjectType().getDescribe().getName();  
        map<PeriodRetrievalDefinition,period__c> sourceDocPeriods = new map<PeriodRetrievalDefinition,period__c>();
        if(sObjName.equalsIgnoreCase('Journal_Entry__c') == TRUE){
            return sourceDocPeriods;
        }
        set<string> queryFields = new set<string>{'Id', 'Company__c', 'Finalized_Date__c', 'Transaction_Date__c', 'Posting_Date__c', 'Void__c', 'Void_Date__c'};
        String whereClause = 'ID IN : sourceDocumentsRecs';
        if(sObjName.equalsIgnoreCase('Journal_Entry__c') == FALSE){
        	SOQLUtil soql = new SOQLUtil(sObjName);
        	soql.addFields(queryFields);
        	soql.setWhereClause(whereClause);
        	sourceDocumentsRecs = Database.query(soql.getQuery());
        //sourceDocumentsRecs = database.query(queryFieldSet + sObjName + whereClause);
        }
        //to check sourceDocumentsRecs are finalized
        list<PeriodDateDefinition> periodDateDefinitionList = new list<PeriodDateDefinition>();
        set<Id> companyIds = new Set<Id>();
        //set
        Set<Period__c> openPeriodSet = new set<Period__c>();
          Map<String, String> ObjectToSLCMap = AccountingEntryService.buildSubledgerNameMap();
        //if((String)sObj.get('source_document_object_name__c') != 'Journal_Entry__c' ){}
        for(sObject sObj : sourceDocumentsRecs ){
            sObjName = sObj.id.getSObjectType().getDescribe().getName();

            //if(sObjName != 'Journal_Entry__c' ) {
                
            
           //companyIds.add((Id)sObj.get('Company__c'));
           DateTime voidDate = (Datetime) sObj.get('Void_Date__c');
           PeriodDateDefinition pddInContext = new PeriodDateDefinition(); 
           ID sdCompanyID = (Id)sObj.get('Company__c');
            companyIds.add(sdCompanyID);
            pddInContext.sobj = sobj;
            if((Datetime) sObj.get('Void_Date__c') == NULL){
            pddInContext.Datetype = 'Transaction';     
            }else{
            pddInContext.Datetype = 'Void';                 
            }
            if(pddInContext.Datetype == 'Transaction'){
                pddInContext.FD = (DateTime)sObj.get('Finalized_Date__c');
                pddInContext.TD = (DateTime)sObj.get('Transaction_Date__c');
                pddInContext.PD = (DateTime)sObj.get('Posting_Date__c');
            }else{
                pddInContext.FD = voiddate==null?system.now():voiddate;
                pddInContext.TD = voiddate==null?system.now():voiddate;
                pddInContext.PD = voiddate==null?system.now():voiddate;
            }
            PeriodDateDefinitionList.add(pddInContext);

           // }

        }   
        system.debug('PeriodDateDefinitionList :'+PeriodDateDefinitionList);
        system.debug('companyIds :'+companyIds);

        Map<Id, List<Period__c>> mPeriods = getAllPeriodsMap(companyIds);
        
        //PeriodDateDefinition pdd = new PeriodDateDefinition();


       for(PeriodDateDefinition perioddef : PeriodDateDefinitionList) {
            
            Schema.SObjectType objectSchema= perioddef.sObj.getSObjectType();
            Schema.DescribeSObjectResult sObjectResult = objectSchema.getDescribe();
            String objectName = sObjectResult.getLocalName();
           // if(objectName != 'Journal_Entry__c') {
                
            DateTime trxnDate;
            DateTime finalDate;
            DateTime postDate;
            Boolean isVoid = false;
            Datetime voidDate;
            //Schema.SObjectType objectSchema= perioddef.sObj.getSObjectType();
            //Schema.DescribeSObjectResult sObjectResult = objectSchema.getDescribe();
      //      String objectName = sObjectResult.getLocalName();            
//          if(objectName.equalsIgnoreCase('Journal_Entry__c')){ // Logic is only for JEs as JEs gets updated with void flag and void date after the finalization.
//              isVoid = (Boolean) perioddef.sObj.get('Void__c');
//              voidDate = (Datetime) perioddef.sObj.get('Void_Date__c');
//          }
            // if((Boolean) perioddef.sObj.get('Void__c') == TRUE || (Datetime) perioddef.sObj.get('Void_Date__c') != null){ // If the transaction is void then break no need to continue and assign the date again.
            //  //voidDate = system.now();
            //  break;
            //  //continue;
            // }
            //if(  (Datetime) perioddef.sObj.get('Void_Date__c') == NULL ){
            isVoid = (Boolean) perioddef.sObj.get('Void__c');
            voidDate = system.Now();
           // }else{
            //voidDate =  (Datetime) perioddef.sObj.get('Void_Date__c') ;
           // }
            
   //       //system.debug('sObj: ' + sObj);
            Id companyId = (Id)perioddef.sObj.get('Company__c');
            system.debug('Company__c'+companyId);
            system.debug('mPeriods'+mPeriods);

            //Assign the Transaction Date Finalized Date from the Source Doc 
            if(perioddef.Datetype== 'Void'){
             trxnDate = voiddate==null?system.now():voiddate;
             finalDate = voiddate==null?system.now():voiddate;
             postDate = voiddate==null?system.now():voiddate;
            }
            else{
             trxnDate = (DateTime)perioddef.sobj.get('Transaction_Date__c');
             finalDate = (DateTime)perioddef.sObj.get('Finalized_Date__c');
             postDate = (DateTime)perioddef.sObj.get('Posting_Date__c');
            }



            system.debug('trxnDate'+trxnDate + 'finalDate :'+finalDate + 'postDate :'+postDate);
            
            boolean inClosedPeriod, inFuturePeriod, inOpenPeriod; 
            
            if(mPeriods.containsKey(companyId)){
                
                String subledgerfield, srcDocObjName;
            
                srcDocObjName = sObjectResult.getLocalName();
                
                if(ObjectToSLCMap.containsKey(srcDocObjName)){
                    subledgerfield = ObjectToSLCMap.get(srcDocObjName); // to get the subledger field name from the period for different source documents associated with AE
                }
                Period__c selectedPeriod = new Period__c();
                for(Period__c thisPeriod : mPeriods.get(companyId)){
                    
                    
                    PeriodRetrievalDefinition retrievedPeriodDef =  new PeriodRetrievalDefinition((Id)perioddef.sObj.get('Id'),perioddef.Datetype);
                    retrievedPeriodDef.SDId = (Id)perioddef.sObj.get('Id');
                    if(perioddef.Datetype=='Void' ){
                        retrievedPeriodDef.inputDateType =   'Void';                
                    }
                    else{
                        retrievedPeriodDef.inputDateType =   'Transaction';                

                    }
                    system.debug('Make Sure Dates Are working: ' + 'thisPeriod.Period_end__c' + thisPeriod.Period_end__c + 'thisPeriod.Period_start__c' + thisPeriod.Period_start__c + 'VoidDate' + VoidDate);
    
                    if(thisPeriod.Type__c == 'Zero' || thisPeriod.Type__c == 'Historical'){
                        continue;
                    }
                    system.debug('postDate'+ postDate);


                    //System.Now() date refrence Logic
                    if(srcDocObjName != 'Journal_Entry__c'){
                    if(( ( voidDate < thisPeriod.Period_end__c  && voidDate < thisPeriod.JE_Cutoff__c) && voidDate > thisPeriod.Period_start__c) && thisPeriod.Open__c == TRUE){
                            inOpenPeriod = TRUE;
                            inClosedPeriod = FALSE;
                            inFuturePeriod = FALSE;
                            sourceDocPeriods.put(retrievedPeriodDef, thisPeriod);
                             
                            
                           break;
                   }

                } 

                } // End of period for loop

                system.debug('inClosedPeriod:' + inClosedPeriod + 'inFuturePeriod:' + inFuturePeriod + 'inOpenPeriod:' + inOpenPeriod);

            }
    
        //}    
    }           
                system.debug('sourceDocPeriods' + sourceDocPeriods);

                return sourceDocPeriods;

    }   	
    public static void checkYearEndAdjustmentJEExixts(list<Period__c> periodList){
    	list<Period__c> periodListsearch =  periodList ;
    	SOQLUtil soql = new SOQLUtil('journal_Entry__c');
    	soql.addFields ( new Set<String> { 'Id','Name','period__c' } ) ;
    	soql.setWhereClause('Period__c in:periodListsearch AND Id NOT IN (SELECT Journal_Entry__c FROM Accounting_Entry__c  where has_exceptions__c = false  AND status__c = \'Active\' AND Journal_Entry__c != null AND Period__c in: periodListsearch)');
    	list<Journal_Entry__c> JEList = Database.query(soql.getQuery());
    	map<Id,Journal_Entry__c> JEMap = new map<id, Journal_Entry__c>();
    	
 		for(Journal_Entry__c je :JEList){
			JEMap.put(je.period__c, je);
		}
    	
		for(Period__c p :periodList){
			if(jemap.containskey(p.id)){
				p.addError('You cannot close this period because there it has unaccounted journal entries.');
			}
		}
    
    }
 	
 	
}