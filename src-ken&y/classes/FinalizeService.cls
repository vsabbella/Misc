public with sharing class FinalizeService {
    
    public class FinalizeException extends Exception{}
    
    public static final string VALIDATE_FIELD_SET = 'Finalize';
    public static Map<string, string> mSubledgerCutoffs = AccountingEntryService.buildSubledgerNameMap();
	public static Map<string, string> mSubledgerClosed= AccountingEntryService.buildSubledgerCloseMap();
    
    /*
 		@Description: This method is for private use and uses the results from PeriodService.getPeriodsMap to determine the appropriate transaction period
 	*/
 	private static Period__c returnTransactionPeriod(Map<Id, List<Period__c>> mCompanyPeriods, Id companyId, DateTime transactionDate){
 		Period__c transactionPeriod;
 		if(mCompanyPeriods.containsKey(companyId)){
 			for(Period__c p : mCompanyPeriods.get(companyId)){
 				if(p.period_start__c <= transactionDate && transactionDate < p.period_end__c){
 					transactionPeriod = p;
 					break;
 				}			
 			}
 		}else{
 			//throw exception - no periods found for given company
 			throw new FinalizeException(Label.No_available_periods_for_company_to_assign_FinalizedDate);
 		}
 		
 		return transactionPeriod;
 	}
 	
 	@TestVisible
 	private static DateTime currDt = system.now();
 	//This set of Ids is used to specify the Ids of the source documents that are being voided during this apex transaction
 	@TestVisible
 	public static set<Id> voidIds = new set<Id>();
 	public static set<Id> postingIds = new set<Id>();
 	
 	/*
 		@Description: This function is to set the Finalized Date on the source document 
 						It is called by before insert / update Trigger of any source document by passing Trigger.New
 	*/
 	public static void setFinalizedDate(List<sObject> sObjectList){
 		
 		try {
			set<Id> companyIds = new set<Id>();
			//set<DateTime> TransactionDateSet = new set<DateTime>();
			//system.debug(logginglevel.INFO,'SOBJECT LIST: '+sObjectList);
			for (sObject sObj: sObjectList) {
				if ((Boolean) sObj.get('Finalized__c')) {
					companyIds.add((Id) sObj.get('Company__c'));
				}
			}

			Map<Id, List<Period__c>> mCompanyPeriods;
			if (companyIds.size() > 0) {
				mCompanyPeriods = PeriodService.getAllPeriodsMap(companyIds);
			}

			for (integer i = 0; i < sObjectList.size(); i++) {

				sObject sObj = sObjectList[i];
				//system.debug(logginglevel.INFO,'SOBJECT : '+sObj);
				if (postingIds.contains(sObj.Id)) {
					continue;
				}

				//KNDY-7410
				//boolean hasHistorical = sObj.getSobjectType().getDescribe().fields.getMap().containsKey('historical__c');
				//boolean hasVoid = sObj.getSobjectType().getDescribe().fields.getMap().containsKey('void__c');
				//boolean hasStatus = sObj.getSobjectType().getDescribe().fields.getMap().containsKey('status__c');
				Schema.sObjectType iSObjType = sObj.getSObjectType();
				String sObjectName = iSObjType.getDescribe().getLocalName();
				SchemaUtil util = SchemaUtil.getInstance();
				Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(sObj.getSobjectType().getDescribe().fields.getMap());

				boolean hasHistorical = fieldsMap.containsKey('historical__c');
				boolean hasVoid = fieldsMap.containsKey('void__c');
				boolean hasStatus = fieldsMap.containsKey('status__c');

				if ((Boolean) sObj.get('Finalized__c')) {

					DateTime FinalizedDate = (DateTime) sObj.get('Finalized_Date__c');
					DateTime TransactionDate = (DateTime) sObj.get('Transaction_Date__c');
					DateTime PostingDate = (DateTime) sObj.get('Posting_Date__c');
					PostingDate = PostingDate == null ? FinalizedDate : PostingDate;

					//system.debug(logginglevel.info,'FinalizedDate:'+FinalizedDate);
					//system.debug(logginglevel.info,'TransactionDate:'+TransactionDate);
					//system.debug(logginglevel.info,'PostingDate:'+PostingDate);

					Id companyId = (Id) sObj.get('Company__c');


					if (hasHistorical) {
						Boolean isHistorical = (Boolean) sObj.get('historical__c');
						Boolean historicalPresent = false;
						system.debug('has - is historical: ' + hasHistorical + ' ' + isHistorical);
						if (isHistorical) {
							Map<Id, List<Period__c>> mHistoricalPeriods = PeriodService.getHistoricalPeriods();
							if (mHistoricalPeriods.containsKey((Id) sObj.get('Company__c'))) {
								List<Period__c> histPeriods = mHistoricalPeriods.get((Id) sObj.get('Company__c'));
								if (histPeriods.size() > 0) {
									historicalPresent = true;
								}
								for (Period__c p : histPeriods) {
									if (p.period_start__c <= TransactionDate
											&& TransactionDate < p.period_end__c
											&& p.open__c) {
										sObj.put('Finalized_Date__c', transactionDate);
										sObj.put('Posting_Date__c', transactionDate);
										break;
									}
								}
							}

							if (sObj.get('Finalized_Date__c') == null) { // ||  sObj.get('Posting_Date__c') == null OTC-742 removed this condition
								string errMsg;
								if (historicalPresent) {
									errMsg = 'The Historical Period is not open for a Transaction Date of ' + TransactionDate.format('MM/dd/yyyy h:mm a', UserInfo.getTimeZone().toString());
								} else {
									errMsg = 'Unable to identify a Historical Period for a Transaction Date of ' + TransactionDate.format('MM/dd/yyyy h:mm a', UserInfo.getTimeZone().toString());
								}
								trigger.new[i].addError(errMsg);
							}
							continue;
						}
					}

					//FIN-411 Void Checks

					if (hasVoid
							&& trigger.isBefore
							&& trigger.isUpdate) {
						Boolean isVoid = (Boolean) sObj.get('void__c');
						Boolean wasVoid = (Boolean) trigger.oldMap.get(sObj.Id).get('void__c');
						if (!isVoid && wasVoid) {
							trigger.new[i].addError('You cannot undo a void');
						}

						if (isVoid && !wasVoid
								&& !voidIds.contains(sObj.Id)) {
							sObj.put('Void_Date__c', null);
							trigger.new[i].addError('You can only void a document by clicking on the Void/Cancel button');
						}

						if (isVoid && wasVoid
								&& KSE.isFieldChanging('void_date__c', sObj, trigger.oldMap)) {
							sObj.put('void_date__c', trigger.oldMap.get(sObj.Id).get('void_date__c'));
						}

						if (isVoid && hasStatus) {
							sObj.put('status__c', 'Void');
						}

						if (!isVoid) {
							sObj.put('Void_Date__c', null);
						}
					}

					Period__c TrxnDatePeriod;

					Schema.SObjectType objectSchema = sObj.getSObjectType();
					Schema.DescribeSObjectResult sObjectResult = objectSchema.getDescribe();
					String objectName = sObjectResult.getLocalName();

					if (!objectName.equalsignorecase('Fixed_Asset_Adjustment__c')
							&& !objectName.equalsignorecase('Fixed_Asset_Depreciation__c')) {

						if ((Decimal) sObj.get('Total_Number_Of_Lines__c') == 0 || sObj.get('Total_Number_Of_Lines__c') == null) {
							trigger.new[i].addError(Label.Document_cannot_be_finalized_without_lines);
						}
					}

					if (companyId == null) {
						trigger.new[i].addError(Label.Company_is_required_to_finalize);
					}

					if (string.isEmpty((string) sObj.get('Currency__c'))) {
						trigger.new[i].addError(Label.Transaction_Currency_is_required_to_finalize);
					}

					//FIN-591 fix Unable to finalize historical source docs
					if (TransactionDate == null) {
						//Unfortunately, generic sObjects don't support field level error contexts
						trigger.new[i].addError(Label.Transaction_Date_is_required_to_finalize + ' ' + sObj.getSobjectType().getDescribe().getLabel());
						continue;
					}
					Configuration__c c = Configuration__c.getValues('AutoBackdateToOpenSubledgers');

					if (trigger.isInsert || sObj.get('Finalized_Date__c') == null) {
						sObj.put('Finalized_Date__c', currDt);
						if (!postingIds.contains(sObj.Id)) {
							//sObj.put('Posting_Date__c', currDt); // KNDY-7697 SK - Change this to Max(TD,FD)
							Datetime TD = (Datetime) sObj.get('Transaction_Date__c');
							//KNDY-12201 Changing default behaviour to be autobackdating.
							if (c == null || (c.Value__c.equalsIgnoreCase('Yes'))) { // c == null means custom setting is not set use the default behaviour-Autobackdating
								//if(c.Value__c.equalsIgnoreCase('Yes')){ // If the custom setting exists with value "Yes" then go to quikbooks mode
								TrxnDatePeriod = returnTransactionPeriod(mCompanyPeriods, companyId, TransactionDate);
								if (TrxnDatePeriod != null) { // if transaction period's SLClose == null
									String SLcutOffField = mSubledgerCutoffs.get(sObjectName);
									String SLclosedField = mSubledgerClosed.get(sObjectName);
									if ((Datetime) TrxnDatePeriod.get(SLclosedField) == null) { // Subledger is still open
										Datetime tmpSLCutoff = ((Datetime) TrxnDatePeriod.get(SLcutOffField)).addSeconds(-1);
										// Posting_Date__c == Min ( TD, (Datetime) AccountingEntryService.buildSubledgerNameMap.get(sObjectName) - 1 )
										sObj.put('Posting_Date__c', TD < tmpSLCutoff ? TD : tmpSLCutoff);
									} else {
										sObj.put('Posting_Date__c', TD > currDt ? TD : currDt);
									}
								} else {
									sObj.put('Posting_Date__c', currDt);
								}
 							/*}else{ // if custom setting value is != Yes means go back to default behaviour
 							sObj.put('Posting_Date__c', TD > currDt ? TD : currDt);
 							}*/
							} else if ((c.Value__c.equalsIgnoreCase('No'))) { // custom setting exists with value No.
								sObj.put('Posting_Date__c', TD > currDt ? TD : currDt);
							}
						}
					} else {
						if (trigger.isBefore && trigger.isUpdate) {
							if (trigger.oldMap.containsKey(sObj.Id)
									&& (Boolean) trigger.oldMap.get(sObj.Id).get('Finalized__c')
									&& KSE.isFieldChanging('Finalized_Date__c', trigger.newMap.get(sObj.Id), trigger.oldMap)
									&& trigger.oldMap.get(sObj.Id).get('Finalized_Date__c') != null) {
								//KNDY-5394 - Add logic to prevent changes to FD
								//Reassign the old value - prevent someone from changing this value
								sObj.put('Finalized_Date__c', trigger.oldMap.get(sObj.Id).get('Finalized_Date__c'));
							}
							if (trigger.oldMap.containsKey(sObj.Id)
									&& (Boolean) trigger.oldMap.get(sObj.Id).get('Finalized__c')
									&& KSE.isFieldChanging('Posting_Date__c', trigger.newMap.get(sObj.Id), trigger.oldMap)
									&& trigger.oldMap.get(sObj.Id).get('Posting_Date__c') != null) {
								if (!postingIds.contains(sObj.Id)) {
									sObj.put('Posting_Date__c', trigger.oldMap.get(sObj.Id).get('Posting_Date__c'));
								}
							}
						}
					}

					FinalizedDate = (DateTime) sObj.get('Finalized_Date__c');
					PostingDate = (DateTime) sObj.get('Posting_Date__c');
					PostingDate = PostingDate == null ? FinalizedDate : PostingDate;

					//FIN-591 fix Unable to finalize historical source docs
					//Historical doc will always have FD >TD
					if ((TransactionDate != null && FinalizedDate != null) && (FinalizedDate < TransactionDate)) {

						TrxnDatePeriod = returnTransactionPeriod(mCompanyPeriods, companyId, TransactionDate);
						if (TrxnDatePeriod == null) {
							trigger.new[i].addError(Label.No_available_periods_for_this_company + ' ' + TransactionDate.format('MM/dd/yyyy h:mm a', UserInfo.getTimeZone().toString()));
							continue;
						} else if (FinalizedDate < TrxnDatePeriod.Period_Start__c) {
							//sObj.put('Finalized_Date__c', TrxnDatePeriod.Period_Start__c);
							//Posting Date now assigned to TD where FD < TD - which assigns the period that the TD falls within
							if (!postingIds.contains(sObj.Id)) {
								sObj.put('Posting_Date__c', TransactionDate);
							}
						}
					}
				} else {
					if (trigger.isBefore && trigger.isUpdate) {
						sObj.put('Finalized_Date__c', null);
						sObj.put('Posting_Date__c', null);
						if (hasVoid) {
							sObj.put('Void__c', false);
							sObj.put('Void_Date__c', null);
						}

						if (hasStatus && trigger.oldMap.containsKey(sObj.Id)) {
							if ((string) trigger.oldMap.get(sObj.Id).get('status__c') == 'Cancelled') {
								sObj.put('status__c', 'Cancelled');
							}
						}
					}
				}
			}
		}catch(Exception ex) {
			for(Sobject sobj : sObjectList) {
				sobj.addError(ex.getMessage());
			}

		}
 	}
    
    private static map<Schema.sObjectType, map<string, string>> mValidateFields = new map<Schema.sObjectType, map<string, string>>();
    public static map<string, string> sObjectValidateFields(Schema.sObjectType sObjectType){
        map<string, string> mFieldLabel = new map<string, string>();
        if(mValidateFields.containsKey(sObjectType)){
            mFieldLabel = mValidateFields.get(sObjectType);
        }else{
        	for( Schema.FieldSetMember fsm : SchemaUtil.getInstance().getFieldsFromFieldSet(sObjectType, VALIDATE_FIELD_SET) ){  
	            //validateFields.addAll(SchemaUtil.getInstance().getFieldsFromFieldSetString(sObjectType, VALIDATE_FIELD_SET));
	            mFieldLabel.put(fsm.getFieldPath(), fsm.getLabel());
        	}
        	mValidateFields.put(sObjectType, mFieldLabel);
        }
        return mFieldLabel; 
    }
    
	
    
    //before update considerations
    public static void validateHeaderFinalize(){
        
        List<sObject> sObjRecs = new List<sObject>();
        if(trigger.isBefore && trigger.isUpdate){
        	sObjRecs = trigger.new;
        }else if(trigger.isBefore && trigger.isDelete){
        	sObjRecs = trigger.old;
        }
        
        if(trigger.isBefore){
            for(integer i = 0; i< sObjRecs.size(); i++){
                
                sObject sObj = sObjRecs[i];
                
                Schema.sObjectType iSObjType = sObj.getSObjectType();
                String sObjectName = iSObjType.getDescribe().getLocalName();

                Boolean isFinalized = false;

                if(sObjectName == 'Shipment__c'){

                    isFinalized = (Boolean)sObj.get('Finalized__c') ? ((Boolean)sObj.get('Finalized__c') && (Boolean)trigger.old[i].get('Finalized__c')) : 
                                        ((Boolean)sObj.get('Locked__c') && (Boolean)trigger.old[i].get('Locked__c'));

                } else {

                    isFinalized = ((Boolean)sObj.get('Finalized__c') && (Boolean)trigger.old[i].get('Finalized__c')) ? true : false;
                }
                

                if (isFinalized == true && (AccountingService.mAccountingWorkers.containsKey(sObjectName) == true || sObjectName == 'Shipment__c')) {
                    
                    map<string, string> validateFields = sObjectValidateFields(iSObjType);
                    
                    if(trigger.isBefore && trigger.isUpdate){
                        //The record exists and is being updated - make sure the vital fields aren't changing
                        for(string field : validateFields.keySet()){
                            if(trigger.new[i].get(field) != trigger.old[i].get(field)){

                                if(sObjectName == 'Shipment__c' && (Boolean)trigger.old[i].get('Locked__c')){
                                    trigger.new[i].addError(validateFields.get(field) + ' ' + Label.Cannot_be_changed_on_a_locked + ' ' + iSObjType.getDescribe().getLabel());
                                } else {
                                    trigger.new[i].addError(validateFields.get(field) + ' ' + Label.Cannot_be_changed_on_a_finalized + ' ' + iSObjType.getDescribe().getLabel());
                                }
                                
                            }
                        }
                        
                    }
                    if(trigger.isBefore && trigger.isDelete){
                    	// The record exists and is being deleted - prevent delete of a finalize doc
                    	trigger.old[i].addError(Label.You_cannot_delete_a_Finalized +' '+ iSObjType.getDescribe().getLabel());
                    }
                }
            }
        }
    }
    
    //before insert, update, delete & after undelete considerations
    public static void validateLineFinalize(){
    	
        List<sObject> lines = new List<sObject>();
        if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
        	lines = trigger.new;
        }else if(trigger.isBefore && trigger.isDelete){
        	lines = trigger.old;
        }else if(trigger.isAfter && trigger.isUndelete){
        	lines = trigger.new;
        }
        
        
    	if((trigger.isAfter && (trigger.isInsert || trigger.isUpdate)
	    	 	|| (trigger.isBefore && trigger.isDelete))
	        	|| (trigger.isAfter && trigger.isUndelete)){
            
            for(integer i = 0; i< lines.size(); i++){
                
                sObject line = lines[i];
                
                Schema.sObjectType lineSObjType = line.getSObjectType();
                string sObjectName = lineSObjType.getDescribe().getLocalName();
                string sObjectLabel = lineSObjType.getDescribe().getLabel();
                if(AccountingService.mLinesToHeader.keyset().contains(sObjectName)){
                boolean iFinalized;

                if(sObjectName == 'Inventory_Transaction__c'){

                	iFinalized = (Boolean)line.get('isFinalized__c');

                } else if(sObjectName == 'Shipment_Line__c'){

                    iFinalized = (Boolean)line.get('Finalized__c') ? (Boolean)line.get('Finalized__c') : (Boolean)line.get('Locked__c');
                } else{

                	iFinalized = (Boolean)line.get('Finalized__c');
                }
                
                if(iFinalized){
                    //The record is new and the header is finalized - this is a problem
                    if(trigger.isInsert){
                        trigger.new[i].addError(Label.Cannot_add_lines_to_a_finalized_SourceDoc);
                    }
                    
                    //The record exists and is being updated - make sure the vital fields aren't changing
                    if(trigger.isUpdate){
                    	
                        map<string, string> validateFields = sObjectValidateFields(lineSObjType);
                    
                        for(string field : validateFields.keySet()){
                        	system.debug(trigger.new[i].get(field) + ' - ' +  trigger.old[i].get(field));
                            if(trigger.new[i].get(field) != trigger.old[i].get(field)){

                                if(sObjectName == 'Shipment_Line__c' && (Boolean)line.get('Locked__c')){

                                    trigger.new[i].addError(validateFields.get(field) + ' ' + Label.Cannot_be_changed_on_a_locked + ' '+ sObjectLabel );
                                    
                                } else{

                                    trigger.new[i].addError(validateFields.get(field) + ' ' + Label.Cannot_be_changed_on_a_finalized + ' '+ sObjectLabel );    
                                }
                                
                            }
                        }
                    }
                    
                    if(trigger.isDelete){
                        trigger.old[i].addError(Label.Cannot_delete_lines_from_finalized_SourceDoc);
                    }
                    
                    if(trigger.isUnDelete){
                        trigger.old[i].addError(Label.Cannot_undelete_lines_with_finalized_SourceDoc);
                    }
                }
                    
            }
            } // if contains
        }
        
    }
    
    /*
    //This method was abandoned in favor of using a Finalized formula checkbox on the lines
    private static map<Id, sObject> returnHeaders(List<sObject> lines){
    	
    	Map<Id, sObject> mRecs = new Map<Id, sObject>();
    	set<string> headerSobjectNames = new set<string>();
    	set<Id> headerIds = new set<Id>();
    	
    	for(sObject sObj : lines){
    		string sObjName = sObj.getSObjectType().getDescribe().getLocalName();
    		set<string> iHeaderSobjectNames = AccountingService.mLinesToHeader.get(sObjName);
    		for(string headerRef : iHeaderSobjectNames){
    			Id headerId = (Id)sObj.get(headerRef);
    			if(headerId != null){
    				headerIds.add(headerId);
    				headerSobjectNames.add(headerId.getSobjectType().getDescribe().getLocalName());
    			}
    		}
    		
    		
    	}
    	
    	//Loop through each type of header and collect all the available records
    	for(string s : headerSobjectNames){
    		if(s != null && s != ''){
    			mRecs.putAll(Database.query('SELECT Id, finalized__c, finalized_date__c FROM ' + s + ' WHERE Id IN :headerIds'));
    		}
    	}
    	return mRecs;
    }
    */
    
   	// SK - KNDY-10570
 	public static void setFinalizedDate_SD(List<sObject> sObjectList){
 		set<Id> companyIds = new set<Id>();
 		for(sObject sObj: sObjectList){
 			if((Boolean) sObj.get('Finalized__c')){
	 			companyIds.add((Id) sObj.get('From_Company__c'));
	 			if(sObj.get('To_Company__c') != null){
	 				companyIds.add((Id) sObj.get('To_Company__c'));
	 			}
	 		}
 		}
 		
 		Map<Id, List<Period__c>> mCompanyPeriods;
 		if(companyIds.size() > 0){
 			mCompanyPeriods = PeriodService.getAllPeriodsMap(companyIds);
 		}
 		
 		for(integer i=0; i<sObjectList.size(); i++){
 			
 			sObject sObj = sObjectList[i];	
 			if(postingIds.contains(sObj.Id)){
 				continue;
 			}
 			
 			Schema.sObjectType iSObjType = sObj.getSObjectType();
            String sObjectName = iSObjType.getDescribe().getLocalName();
			SchemaUtil util = SchemaUtil.getInstance();
			Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(sObj.getSobjectType().getDescribe().fields.getMap());      			
 			
 			boolean hasHistorical = false;
 			hasHistorical = fieldsMap.containsKey('historical__c');
 			boolean hasVoid = false;
 			hasVoid = fieldsMap.containsKey('void__c');
 			boolean hasStatus = false;
 			hasStatus = fieldsMap.containsKey('status__c'); 			
 			    
 			if((Boolean) sObj.get('Finalized__c')){ 
 				
 				DateTime FinalizedDate = (DateTime) sObj.get('Finalized_Date__c');
	  			DateTime TransactionDate = (DateTime) sObj.get('Transaction_Date__c');
	  			DateTime PostingDate = (DateTime) sObj.get('Posting_Date__c');
	  			PostingDate = PostingDate == null ? FinalizedDate : PostingDate;
	  			
	 			Id companyId = (Id) sObj.get('From_Company__c');
	 			Id TocompanyId = (Id) sObj.get('To_Company__c');
 				
 				
 				if(hasHistorical){
 					Boolean isHistorical = (Boolean)sObj.get('historical__c');
 					Boolean historicalPresent = false;
 					system.debug('has - is historical: ' + hasHistorical + ' ' + isHistorical);
 					if(isHistorical){
 						Map<Id, List<Period__c>> mHistoricalPeriods = PeriodService.getHistoricalPeriods();
			    		if(mHistoricalPeriods.containsKey((Id)sObj.get('From_Company__c'))){
			    		    List<Period__c> histPeriods = mHistoricalPeriods.get((Id)sObj.get('From_Company__c'));
			    		    if(histPeriods.size() > 0){
			    		        historicalPresent = true;
			    		    }
				    		for(Period__c p : histPeriods){
				    			if(p.period_start__c <= TransactionDate 
				    					&& TransactionDate < p.period_end__c
				    					&& p.open__c){
				    				sObj.put('Finalized_Date__c', transactionDate);
 									sObj.put('Posting_Date__c', transactionDate);	
 									break;	
				    			}
				    		}
			    		}
 						
 						if(sObj.get('Finalized_Date__c') == null ) { // ||  sObj.get('Posting_Date__c') == null OTC-742 removed this condition
 						    string errMsg;
 						    if(historicalPresent){
 						        errMsg = 'The Historical Period is not open for a Transaction Date of ' + TransactionDate.format('MM/dd/yyyy h:mm a', UserInfo.getTimeZone().toString());
 						    }else{
 						        errMsg = 'Unable to identify a Historical Period for a Transaction Date of ' + TransactionDate.format('MM/dd/yyyy h:mm a', UserInfo.getTimeZone().toString());
 						    }
 							trigger.new[i].addError(errMsg);
 						}
 						continue;
 					}
 				}
 			    
 			    //FIN-411 Void Checks
 			    
 			    if(hasVoid 
 			            && trigger.isBefore
 			            && trigger.isUpdate){
 			        Boolean isVoid = (Boolean)sObj.get('void__c');
 			        Boolean wasVoid = (Boolean)trigger.oldMap.get(sObj.Id).get('void__c');
 			        if(!isVoid && wasVoid){
 			            trigger.new[i].addError('You cannot undo a void');
 			        }
 			        
 			        if(isVoid && !wasVoid
 			        		&& !voidIds.contains(sObj.Id)){
 			        	sObj.put('Void_Date__c', null);
 			        	trigger.new[i].addError('You can only void a document by clicking on the Void/Cancel button');
 			        }
 			        
 			        if(isVoid && wasVoid
 			                && KSE.isFieldChanging('void_date__c', sObj, trigger.oldMap)){
 			            sObj.put('void_date__c', trigger.oldMap.get(sObj.Id).get('void_date__c'));
 			        }
 			        
 			        if(isVoid && hasStatus){
 			            sObj.put('status__c', 'Void');
 			        }
 			        
 			        if(!isVoid){
 			        	sObj.put('Void_Date__c', null);
 			        }
 			    }
 				
	 			Period__c TrxnDatePeriod_FromCompany, TrxnDatePeriod_ToCompany;
	 			
	 			Schema.SObjectType objectSchema= sObj.getSObjectType();
            	Schema.DescribeSObjectResult sObjectResult = objectSchema.getDescribe();
            	String objectName = sObjectResult.getLocalName();
	 			
	 			if( !objectName.equalsignorecase('Fixed_Asset_Adjustment__c') 
                		&& !objectName.equalsignorecase('Fixed_Asset_Depreciation__c')){
                	
                	if((Decimal) sObj.get('Total_Number_Of_Lines__c') == 0 || sObj.get('Total_Number_Of_Lines__c') == null){           	
                		trigger.new[i].addError(Label.Document_cannot_be_finalized_without_lines);
                	}
                }
                
	 			if(companyId == null || TocompanyId == null){
	 				trigger.new[i].addError(Label.Company_is_required_to_finalize);
	 			}
	 			
	 			if(string.isEmpty((string)sObj.get('Currency__c'))){
	 				trigger.new[i].addError(Label.Transaction_Currency_is_required_to_finalize);
	 			}
 				
 				//FIN-591 fix Unable to finalize historical source docs
                if(TransactionDate == null)
                {		
	 				//Unfortunately, generic sObjects don't support field level error contexts
	 				trigger.new[i].addError(Label.Transaction_Date_is_required_to_finalize +' '+ sObj.getSobjectType().getDescribe().getLabel());
	 				continue;
	 			}
	 			//Commenting this as it not used.
				//Configuration__c c = Configuration__c.getValues('AutoBackdateToOpenSubledgers');
 				
 				if(trigger.isInsert || sObj.get('Finalized_Date__c') == null){
 			 		sObj.put('Finalized_Date__c', currDt);
 					assignPostingDate (sObj, sObjectName, mCompanyPeriods);
 				}else{
 					if(trigger.isBefore && trigger.isUpdate){
 						if( trigger.oldMap.containsKey(sObj.Id)
 								&& (Boolean)trigger.oldMap.get(sObj.Id).get('Finalized__c')
 								&& KSE.isFieldChanging('Finalized_Date__c', trigger.newMap.get(sObj.Id), trigger.oldMap)
 								&& trigger.oldMap.get(sObj.Id).get('Finalized_Date__c') != null){
 							//KNDY-5394 - Add logic to prevent changes to FD
 							//Reassign the old value - prevent someone from changing this value
							sObj.put('Finalized_Date__c', trigger.oldMap.get(sObj.Id).get('Finalized_Date__c'));
						}
						if( trigger.oldMap.containsKey(sObj.Id)
 								&& (Boolean)trigger.oldMap.get(sObj.Id).get('Finalized__c')
 								&& KSE.isFieldChanging('Posting_Date__c', trigger.newMap.get(sObj.Id), trigger.oldMap)
 								&& trigger.oldMap.get(sObj.Id).get('Posting_Date__c') != null){
							if(!postingIds.contains(sObj.Id)){
								sObj.put('Posting_Date__c', trigger.oldMap.get(sObj.Id).get('Posting_Date__c'));
							}
 						}
					}
 				}
 				
 				FinalizedDate = (DateTime) sObj.get('Finalized_Date__c');
 				PostingDate = (DateTime) sObj.get('Posting_Date__c');
 				PostingDate = PostingDate == null ? FinalizedDate : PostingDate;
 				
  					//FIN-591 fix Unable to finalize historical source docs
  					//Historical doc will always have FD >TD
                if ( (TransactionDate != null && FinalizedDate != null) && (FinalizedDate <  TransactionDate ) )
                {

                    TrxnDatePeriod_FromCompany = returnTransactionPeriod(mCompanyPeriods, companyId, TransactionDate);
                    TrxnDatePeriod_ToCompany = returnTransactionPeriod(mCompanyPeriods, companyId, TransactionDate);
	 				if(TrxnDatePeriod_FromCompany == null || TrxnDatePeriod_ToCompany == null)
                    {
	 					trigger.new[i].addError(Label.No_available_periods_for_this_company +' '+ TransactionDate.format('MM/dd/yyyy h:mm a', UserInfo.getTimeZone().toString()));
	 					continue;
	 				}
                    else if(FinalizedDate < TrxnDatePeriod_FromCompany.Period_Start__c)
                    {
                        //sObj.put('Finalized_Date__c', TrxnDatePeriod_FromCompany.Period_Start__c);
                        //Posting Date now assigned to TD where FD < TD - which assigns the period that the TD falls within
                        if(!postingIds.contains(sObj.Id)){
                        	sObj.put('Posting_Date__c', TransactionDate);           
                        }            
                    }
 				}
 			}else{
 				if(trigger.isBefore && trigger.isUpdate){
	 				sObj.put('Finalized_Date__c', null);
	 				sObj.put('Posting_Date__c', null);
	 				if(hasVoid){
	 					sObj.put('Void__c', false);
	 					sObj.put('Void_Date__c', null);
	 				}
	 				
	 				if(hasStatus && trigger.oldMap.containsKey(sObj.Id)){
	                    if((string)trigger.oldMap.get(sObj.Id).get('status__c') == 'Cancelled'){
	                        sObj.put('status__c', 'Cancelled');
	                    }
	 				}
 				}
 			}
 		}
 	}
 	
 	// SK - NOTE: This method to be used only with new objects Invoice and Payment due to multiple company fields and posting date logic dependent on multiple calendars
 	private static void assignPostingDate(sObject sObj, String sObjectName, Map<Id, List<Period__c>> mCompanyPeriods){
 	
 		Id companyId_FromCompany = (Id) sObj.get('From_Company__c');	
 		Id companyId_ToCompany = (Id) sObj.get('To_Company__c');
 		Datetime TransactionDate = (Datetime) sObj.get('Transaction_Date__c');
 		String TransactionType = (String) sObj.get('Transaction_Type__c');
 		set<String> TransactionTypeSet = PostingDateLogicTTMap.get(sObjectName);
 		String SLcutOffField_FromCompany, SLclosedField_FromCompany, SLcutOffField_ToCompany, SLclosedField_ToCompany;
 		Period__c TrxnDatePeriod_FromCompany, TrxnDatePeriod_ToCompany;
 		
 		if(TransactionTypeSet.contains(TransactionType)){
 			TrxnDatePeriod_FromCompany = returnTransactionPeriod(mCompanyPeriods, companyId_FromCompany, TransactionDate);
 			if(TrxnDatePeriod_FromCompany != null){
 				SLcutOffField_FromCompany = mSubledgerCutoffs.get(sObjectName);
 				SLclosedField_FromCompany = mSubledgerClosed.get(sObjectName);
 				system.debug(logginglevel.info,'TrxnDatePeriod_FromCompany:'+TrxnDatePeriod_FromCompany);
 			}else{
 				system.debug(logginglevel.info,'TrxnDatePeriod_FromCompany is null:'+TrxnDatePeriod_FromCompany);
 				throw new FinalizeException(Label.No_available_periods_for_company_to_assign_FinalizedDate);
 			}
 			
 			TrxnDatePeriod_ToCompany = returnTransactionPeriod(mCompanyPeriods, companyId_ToCompany, TransactionDate);
 			if(TrxnDatePeriod_ToCompany != null){
 				SLcutOffField_ToCompany = mSubledgerCutoffs.get(sObjectName);
 				SLclosedField_ToCompany = mSubledgerClosed.get(sObjectName);
 				system.debug(logginglevel.info,'TrxnDatePeriod_ToCompany:'+TrxnDatePeriod_ToCompany);
 			}else{
 				system.debug(logginglevel.info,'TrxnDatePeriod_ToCompany is null:'+TrxnDatePeriod_ToCompany);
 				throw new FinalizeException(Label.No_available_periods_for_company_to_assign_FinalizedDate);
 			}
 			
 			if(((Datetime) TrxnDatePeriod_FromCompany.get(SLclosedField_FromCompany) != null || (Datetime) TrxnDatePeriod_ToCompany.get(SLclosedField_ToCompany) != null)){
 				sObj.addError(Label.Cannot_Finalize_as_one_or_more_Intercompany_Subledgers_Closed);
 			}else{
 				sObj.put('Posting_Date__c', TransactionDate );
 			}
 		}else{
 			sObj.put('Posting_Date__c', TransactionDate > currDt ? TransactionDate : currDt);
 		}
 	
 	}
 	// TODO: Revisit this code while working on business entity model
 	public static final map <String, set<String>> PostingDateLogicTTMap = new map<String, set<String>> {
		'Invoice__c'		=> new set<string>{'Intercompany Investment','Intercompany Cross Charge'}	,
		'Payment__c'		=> new set<string>{'Intercompany Payment'}
	};
}