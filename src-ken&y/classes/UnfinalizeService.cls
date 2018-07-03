/*
* without sharing is intentional.  Unfinalizing needs to be run in system mode.
*/
public without sharing class UnfinalizeService {
    
    //TODO: Cache data via constructor where possible
    
    //KNDY-4570
    //This response wrapper can be used directly from the unfinalize pages, or from a trigger using the .addError if necessary
    public class UnfinalizeResponse{
        public Id recordId;
        public boolean success;
        public string message;
        
        public UnfinalizeResponse(){}
        public UnfinalizeResponse(Id recordId, boolean success, string message){
            this.recordId = recordId;
            this.success = success;
            this.message = message;
        }
    }
    
    public class UnfinalizeDetail{
    	public Id recordId;
    	public boolean isUnfinalizable;
    	public string message;
    	
    	public UnfinalizeDetail(){}
    	public UnfinalizeDetail(Id recordId, boolean isUnfinalizable, string message){
    		this.recordId = recordId;
    		this.isUnfinalizable = isUnfinalizable;
    		this.message = message;
    	}
    }
    
    @TestVisible
    private static DateTime currDt = system.now();
    public static set<Datetime> slcDates = new set<Datetime>();
    private static List<Accounting_Entry__c> returnAccountingEntries(List<sObject> sObjRecs){
    	
    	set<Id> sObjIds = new set<Id>(new map<Id, sObject>(sObjRecs).keyset());
        system.debug(sObjIds);
        //string wherestr = String.join(SchemaUtil.getInstance().relatedCustomObjects('Accounting_Entry__c'), ' in :sObjIds OR ') +' in :sObjIds ';
        
       // List<String> sObjects = SchemaUtil.getInstance().getFieldsFromFieldSetString(Accounting_Entry__c.getSobjectType(), 'Source_Documents');
        set<String> sObjectsReq = new set<String>();
        for(Id sobjId : sObjIds)
        {
        	sObjectsReq.add(String.valueOf(sobjId.getSobjectType()));
        }
        system.debug(sObjectsReq);
       
       if(sObjRecs.isEmpty())
       		return new list<Accounting_Entry__c>();
        string wherestr ='('+ String.join(new list<String>(sObjectsReq), ' in :sObjIds OR ') +' in :sObjIds '+')';
 	    
 	    
 	    /*string q = SchemaUtil.getInstance().generateQueryFromFieldSet( 'Accounting_Entry__c',
		new set<string>{'Source_Documents'},
		new set<string>{'id', 'Period__c' ,'Period__r.Open__c', 'Period__r.Closed__c', 'Period__r.Type__c', 'Source_Document_Object_Name__c', 'Period__r.AR_Subledger_Cutoff__c', 'Period__r.Period_Cut_Off__c',
							'Period__r.AP_Subledger_Cutoff__c', 'Period__r.Shipment_Subledger_Cutoff__c', 'Period__r.Receiving_Subledger_Cutoff__c','Period__r.FA_Subledger_Closed__c','Period__r.Receiving_Subledger_Closed__c',
							'Period__r.FA_Subledger_Cutoff__c', 'Period__r.Inventory_Subledger_Cutoff__c', 'Period__r.GL_Close__c', 'Period__r.Period_End__c','Period__r.Inventory_Subledger_Closed__c',
							'Transaction_Date__c', 'Finalized_Date__c', 'Has_Exceptions__c', 'status__c', 'Total_Lines__c','Period__r.AP_Subledger_Closed__c','Period__r.AR_Subledger_Closed__c','Period__r.Shipment_Subledger_Closed__c',
							'Period__r.InterCompany_Subledger_Closed__c'}, 
		wherestr+' AND Related_Accounting_Entry__c = null AND Status__c = \'Active\'' +  ' ORDER BY GL_Date_Time__c '); //TODO: Add void/reverse etc filter?*/
		
		Set<String> setFieldSets = new set<string>{'Source_Documents'} ;
		Set<String> addlFields = new set<string>{'id', 'Period__c' ,'Period__r.Open__c', 'Period__r.Closed__c', 'Period__r.Type__c', 'Source_Document_Object_Name__c', 'Period__r.AR_Subledger_Cutoff__c','Period__r.JE_Cutoff__c',
							'Period__r.AP_Subledger_Cutoff__c', 'Period__r.Shipment_Subledger_Cutoff__c', 'Period__r.Receiving_Subledger_Cutoff__c','Period__r.FA_Subledger_Closed__c','Period__r.Receiving_Subledger_Closed__c',
							'Period__r.FA_Subledger_Cutoff__c', 'Period__r.Inventory_Subledger_Cutoff__c', 'Period__r.GL_Close__c', 'Period__r.Period_End__c','Period__r.Inventory_Subledger_Closed__c',
							'Transaction_Date__c', 'Finalized_Date__c', 'Has_Exceptions__c', 'status__c', 'Total_Lines__c','Period__r.AP_Subledger_Closed__c','Period__r.AR_Subledger_Closed__c','Period__r.Shipment_Subledger_Closed__c',
							'Period__r.InterCompany_Subledger_Closed__c'} ;
		String whereClause = wherestr+' AND Related_Accounting_Entry__c = null AND Status__c = \'Active\'' +  ' ORDER BY GL_Date_Time__c ' ;

		List<Accounting_Entry__c> originalAEList = new List<Accounting_Entry__c>();
		
		//system.debug('query: ' + q);
		return database.query ( SchemaUtil.getInstance().generateQueryFromFieldSet( 'Accounting_Entry__c', setFieldSets, addlFields , whereClause ) );
    }
    
    public static Map<Id, UnfinalizeResponse> unfinalizeSourceDocs(List<sObject> sObjRecs){
    	return unfinalizeSourceDocs(sObjRecs, false);
    }
    
    public static Map<Id, UnfinalizeResponse> unfinalizeSourceDocs(List<sObject> sObjRecs, boolean isCancel){
        
        Map<Id, UnfinalizeResponse> mResponses = new Map<Id, UnfinalizeResponse>();
        List<Accounting_Entry__c> deleteAEs = new List<Accounting_Entry__c>();
        List<sObject> updateRecs = new List<sObject>();
		List<Accounting_Entry__c> originalAEList = returnAccountingEntries(sObjRecs);
		set<Id> largeDataIds = new set<Id>();
		List<Accounting_Entry__c> updateUnfinalizedAEs = new List<Accounting_Entry__c>();
		
		//Collect all the accounting entries and organize by source doc ids
		Map<Id, List<Accounting_Entry__c>> mSourceDocAEs = new Map<Id, List<Accounting_Entry__c>>();
		for(Accounting_Entry__c ae : originalAEList){
		    if(AccountingEntryService.SourceDocPathMap.containsKey(ae.source_document_object_name__c)){
		        Id sourceDocId = (Id)ae.get(AccountingEntryService.SourceDocPathMap.get(ae.source_document_object_name__c));
		        if(mSourceDocAEs.containsKey(sourceDocId)){
		             mSourceDocAEs.get(sourceDocId).add(ae);
		        }else{
		            mSourceDocAEs.put(sourceDocId, new List<Accounting_Entry__c>{ae});
		        }
		    }
		}
		
		Map<string, string> mSubledgerCutoffs = AccountingEntryService.buildSubledgerNameMap();
		Map<string, string> mSubledgerClosedDates = AccountingEntryService.buildSubledgerCloseMap();

		for(sObject sObjRec : sObjRecs){

			//KNDY-7410
			//boolean hasStatus = sObjRec.getSobjectType().getDescribe().fields.getMap().containsKey('status__c');
			SchemaUtil util = SchemaUtil.getInstance();
			Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(sObjRec.getSobjectType().getDescribe().fields.getMap());
			boolean hasStatus = fieldsMap.containsKey('status__c');     		    
		    
		    //Assign critical dates for reference
	        Datetime trxnDt = (Datetime)sObjRec.get('Transaction_Date__c');
	        Datetime finalDt = (Datetime)sObjRec.get('Finalized_Date__c');
	        Datetime postDt = (Datetime)sObjRec.get('Posting_Date__c');
	        postDt = postDt == null ? finalDt : postDt;
	        
		    if(mSourceDocAEs.containsKey(sObjRec.Id)){
		        
		        //Check if there is any Active accounting
		        boolean noneActive = true;
		        Accounting_Entry__c sourceAE;
		        for(Accounting_Entry__c ae : mSourceDocAEs.get(sObjRec.Id)){
		            if(ae.status__c == 'Active'){
		                sourceAE = ae;
		                DateTime slcDt;
		                if(sourceAE.getSobject('Period__r') != null ){
		        			slcDt = (DateTime)sourceAE.getSobject('Period__r').get(mSubledgerClosedDates.get(sourceAE.source_document_object_name__c));
		        			if(slcDt != null){
		        				slcDates.add(slcDt);
		        			}
		                }
		                
		                noneActive = false;
		                break;
		            }
		        }
		        
		        //If there is no Active accounting, it's the same as if no accounting exists - just unfinalize and move on
		        if(noneActive){
		        	for(Accounting_Entry__c ae : mSourceDocAEs.get(sObjRec.Id)){
		        		if(ae.Total_Lines__c > 200){
		        			ae.Status__c = 'Obsolete';
		        			updateUnfinalizedAEs.add(ae);
		        			largeDataIds.add(ae.Id);
		        		}else{
		        			deleteAEs.add(ae);
		        		}
		        	}
		            
		            sObjRec.put('finalized__c', false);
		            sObjRec.put('finalized_hidden__c', false);
		            sObjRec.put('finalized_date__c',null);
		           	sObjRec.put('posting_date__c',null);
		           
		            if(isCancel && hasStatus){
		            	sObjRec.put('status__c', 'Cancelled');
		            }
		            mResponses.put(sObjRec.Id, new UnfinalizeResponse(sObjRec.Id, true, 'Success'));
		            updateRecs.add(sObjRec);
		            continue;
		        }
		        
		        
		        //Grab the source doc subledger cutoff, if not specified, use the period end
		        //DateTime slcDt = (DateTime)sourceAE.getSobject('Period__r').get(mSubledgerCutoffs.get(sourceAE.source_document_object_name__c)) == null ? (Datetime)sourceAE.getSobject('Period__r').get('Period_End__c') : (DateTime)sourceAE.getSobject('Period__r').get(mSubledgerCutoffs.get(sourceAE.source_document_object_name__c));
		        if(sourceAE.getSobject('Period__r') != null ){
		        
			        DateTime slcDt = (DateTime)sourceAE.getSobject('Period__r').get(mSubledgerClosedDates.get(sourceAE.source_document_object_name__c));
/*			        if(slcDt == null){
			        	slcDt = (Datetime)sourceAE.getSobject('Period__r').get('Period_End__c');
			        }	
			        //Grab the GL close date, if not specified, use the period end
			        Datetime glcDt = (Datetime)sourceAE.getSobject('Period__r').get('GL_Close__c');
			        if(glcDt == null){
			        	glcDt = (Datetime)sourceAE.getSobject('Period__r').get('Period_End__c');
					}
			        
*/			        system.debug('trxnDt: ' + trxnDt);
			        system.debug('finalDt: ' + finalDt);
			        system.debug('postDt: ' + postDt);
			        system.debug('slcDt: ' + mSubledgerClosedDates.get(sourceAE.source_document_object_name__c) + ' - '  + slcDt);
//			        system.debug('glcDt: ' + glcDt);
			        
			        //As long as the finalized date is less than the accounting entry's period subledger cutoff, then the record can be unfinalized
			        if(slcDt == null){
			        	system.debug( 'FD < SLC');
			        	for(Accounting_Entry__c ae : mSourceDocAEs.get(sObjRec.Id)){
			        		if(ae.Total_Lines__c > 200){
			        			ae.Status__c = 'Obsolete';
			        			updateUnfinalizedAEs.add(ae);
			        			largeDataIds.add(ae.Id);
			        		}else{
			        			deleteAEs.add(ae);
			        		}
			        	}
			            
			            sObjRec.put('finalized__c', false);
			            sObjRec.put('finalized_hidden__c', false);
			            sObjRec.put('finalized_date__c',null);
			            sObjRec.put('posting_date__c',null);
			           
			            if(isCancel && hasStatus){
			            	sObjRec.put('status__c', 'Cancelled');
			            }
			            mResponses.put(sObjRec.Id, new UnfinalizeResponse(sObjRec.Id, true, 'Success'));
			            updateRecs.add(sObjRec);
			        }else{
			        	system.debug('SLC = null');
			        	mResponses.put(sObjRec.Id, new UnfinalizeResponse(sObjRec.Id, false, Label.Document_cannot_be_unfinalized_because_Subledger_is_closed));
			        }
	
		    	}    
		    	else if(sourceAE.has_exceptions__c){
		        	//FIN-491
		        	//Allow the unfinalize on any doc with Exceptions
		        	for(Accounting_Entry__c ae : mSourceDocAEs.get(sObjRec.Id)){
		        		if(ae.Total_Lines__c > 200){
		        			ae.Status__c = 'Obsolete';
		        			updateUnfinalizedAEs.add(ae);
		        			largeDataIds.add(ae.Id);
		        		}else{
		        			deleteAEs.add(ae);
		        		}
		        	}
		            sObjRec.put('finalized__c', false);
		            sObjRec.put('finalized_hidden__c', false);
		            sObjRec.put('finalized_date__c',null);
		            sObjRec.put('posting_date__c',null);
		           
		            if(isCancel && hasStatus){
		            	sObjRec.put('status__c', 'Cancelled');
		            }
		            mResponses.put(sObjRec.Id, new UnfinalizeResponse(sObjRec.Id, true, 'Success'));
		            updateRecs.add(sObjRec);
		        }
		    }else{
				//KNDY-7410
				//boolean hasHistorical = sObjRec.getSobjectType().getDescribe().fields.getMap().containsKey('historical__c');
				util = SchemaUtil.getInstance();
				fieldsMap = util.addNoNSfieldsToMap(sObjRec.getSobjectType().getDescribe().fields.getMap());
				boolean hasHistorical = fieldsMap.containsKey('historical__c');  
				Schema.sObjectType iSObjType = sObjRec.getSObjectType();
            	String sObjectName = iSObjType.getDescribe().getLocalName();
            	String Company;
            	if(sObjectName.equalsIgnoreCase('Invoice__c') || sObjectName.equalsIgnoreCase('Payment__c')){
            		Company = 'From_Company__c';
            	}else{
            		Company = 'Company__c';
            	}
			    if(hasHistorical){
			    	if((Boolean)sObjRec.get('historical__c')){
			    		Map<Id, List<Period__c>> mHistoricalPeriods = PeriodService.getHistoricalPeriods();
			    		if(mHistoricalPeriods.containsKey((Id)sObjRec.get(Company))){
				    		for(Period__c p : mHistoricalPeriods.get((Id)sObjRec.get(Company))){
				    			if(p.period_start__c <= trxnDt && trxnDt < p.period_end__c){
				    				if(p.closed__c || p.permanently_closed__c){
				    					mResponses.put(sObjRec.Id, new UnfinalizeResponse(sObjRec.Id, false, 'Cannot Cancel, this ' + sObjRec.getSobjectType().getDescribe().getLabel() + ' is in a closed Historical Period'));
				    				}
				    			}
				    		}
			    		}
		    			
		    			//We didn't assign a response - assume you can Unfinalize this historical doc
		    			if(!mResponses.containsKey(sObjRec.Id)){
		    				mResponses.put(sObjRec.Id, new UnfinalizeResponse(sObjRec.Id, true, 'Success'));
		    				sObjRec.put('finalized__c', false);
				            sObjRec.put('finalized_hidden__c', false);
				            sObjRec.put('finalized_date__c',null);
				            sObjRec.put('posting_date__c',null);
		    			}
		    			updateRecs.add(sObjRec);
		    			continue;
			    	}
			    }		      
		        
		        if(isCancel && hasStatus){
	            	sObjRec.put('status__c', 'Cancelled');
	            }
		        
		        //Just unfinalize, no accounting has been created yet
		        sObjRec.put('finalized__c', false);
	            sObjRec.put('finalized_hidden__c', false);
	            sObjRec.put('finalized_date__c',null);
	            sObjRec.put('posting_date__c',null);
	            mResponses.put(sObjRec.Id, new UnfinalizeResponse(sObjRec.Id, true, 'Success'));
	            updateRecs.add(sObjRec);
		    }
		}
		
		Savepoint sp = Database.setSavepoint();
		try{
			if(deleteAEs.size() > 0){
		    	//We are now marking the unfinalized AEs as Obsolete
		    	for(Accounting_Entry__c ae : deleteAEs){
		    		ae.Status__c = 'Obsolete';
		    	}
		    	DML.updateAsSystem(deleteAEs);
			}
			if(largeDataIds.size() > 0){
				//We are now marking the unfinalized AEs as Obsolete
				DML.updateAsSystem(updateUnfinalizedAEs);
				//Database.ExecuteBatch(new AccountingEntryLineDeleteBatch(largeDataIds), 2000);
			}
		    DML.updateAsSystem(updateRecs);
		}catch(Exception ex){
		    database.rollback(sp);
		    throw ex;
		}
		return mResponses;
    }
    
    public static Map<Id, UnfinalizeDetail> checkUnfinalize(List<sObject> sObjRecs){
    	
    	Map<Id, UnfinalizeDetail> mUnfinalize = new Map<Id, UnfinalizeDetail>();
    	List<Accounting_Entry__c> originalAEList = returnAccountingEntries(sObjRecs);
		
		//Collect all the accounting entries and organize by source doc ids
		Map<Id, List<Accounting_Entry__c>> mSourceDocAEs = new Map<Id, List<Accounting_Entry__c>>();
		for(Accounting_Entry__c ae : originalAEList){
		    if(AccountingEntryService.SourceDocPathMap.containsKey(ae.source_document_object_name__c)){
		        Id sourceDocId = (Id)ae.get(AccountingEntryService.SourceDocPathMap.get(ae.source_document_object_name__c));
		        if(mSourceDocAEs.containsKey(sourceDocId)){
		             mSourceDocAEs.get(sourceDocId).add(ae);
		        }else{
		            mSourceDocAEs.put(sourceDocId, new List<Accounting_Entry__c>{ae});
		        }
		    }
		}
		
		Map<string, string> mSubledgerCutoffs = AccountingEntryService.buildSubledgerNameMap();
		Map<string, string> mSubledgerClosedDates = AccountingEntryService.buildSubledgerCloseMap();
		for(sObject sObjRec : sObjRecs){
			
			//Assign critical dates for reference
	        Datetime trxnDt = (Datetime)sObjRec.get('Transaction_Date__c');
	        Datetime finalDt = (Datetime)sObjRec.get('Finalized_Date__c');
	        DateTime postDt = (Datetime)sObjRec.get('Posting_Date__c');
	        postDt = postDt == null ? finalDt : postDt;
	        
			//KNDY-7410
			//boolean hasStatus = sObjRec.getSobjectType().getDescribe().fields.getMap().containsKey('status__c');
			SchemaUtil util = SchemaUtil.getInstance();
			Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(sObjRec.getSobjectType().getDescribe().fields.getMap());
			boolean hasStatus = fieldsMap.containsKey('status__c');   		    
		    
		    if(hasStatus){
		    	if(sObjRec.get('status__c') == 'Cancelled'){
		    		mUnfinalize.put(sObjRec.Id, new UnfinalizeDetail(sObjRec.Id, false, 'Cannot Cancel, this ' + sObjRec.getSobjectType().getDescribe().getLabel() + ' is already Cancelled'));
		    		//No need to look any further, this is a cancelled document already
		    		continue;
		    	}
		    }
		    
		    //KNDY-7410
		    //boolean hasHistorical = sObjRec.getSobjectType().getDescribe().fields.getMap().containsKey('historical__c');
		    boolean hasHistorical = fieldsMap.containsKey('historical__c'); 
		    Schema.sObjectType iSObjType = sObjRec.getSObjectType();
        	String sObjectName = iSObjType.getDescribe().getLocalName();
        	String Company;
        	if(sObjectName.equalsIgnoreCase('Invoice__c') || sObjectName.equalsIgnoreCase('Payment__c')){
        		Company = 'From_Company__c';
        	}else{
        		Company = 'Company__c';
        	}
		    
		    if(hasHistorical){
		    	if((Boolean)sObjRec.get('historical__c')){
		    		Map<Id, List<Period__c>> mHistoricalPeriods = PeriodService.getHistoricalPeriods();
		    		if(mHistoricalPeriods.containsKey((Id)sObjRec.get(Company))){
			    		for(Period__c p : mHistoricalPeriods.get((Id)sObjRec.get(Company))){
			    			if(p.period_start__c <= trxnDt && trxnDt < p.period_end__c){
			    				if(p.closed__c || p.permanently_closed__c){
			    					mUnfinalize.put(sObjRec.Id, new UnfinalizeDetail(sObjRec.Id, false, 'Cannot Cancel, this ' + sObjRec.getSobjectType().getDescribe().getLabel() + ' is in a closed Historical Period'));
			    				}
			    			}
			    		}
		    		}
	    			
	    			//We didn't assign a response - assume you can Unfinalize this historical doc
	    			if(!mUnfinalize.containsKey(sObjRec.Id)){
	    				mUnfinalize.put(sObjRec.Id, new UnfinalizeDetail(sObjRec.Id, true, null));
	    			}
	    			continue;
		    	}
		    }
		    
		    if(mSourceDocAEs.containsKey(sObjRec.Id)){
		        
		    	//Check if there is any Active accounting
		        boolean noneActive = true;
		        Accounting_Entry__c sourceAE;
		        for(Accounting_Entry__c ae : mSourceDocAEs.get(sObjRec.Id)){
		            if(ae.status__c == 'Active'){
		                sourceAE = ae;
		                noneActive = false;
		                break;
		            }
		        }
		        
		        //If there is no Active accounting, it's the same as if no accounting exists - just unfinalize and move on
		        if(noneActive){
		            mUnfinalize.put(sObjRec.Id, new UnfinalizeDetail(sObjRec.Id, true, null));
		            continue;
		        }
		        
		        //Grab the source doc subledger cutoff, if not specified, use the period end
		        //DateTime slcDt = (DateTime)sourceAE.getSobject('Period__r').get(mSubledgerCutoffs.get(sourceAE.source_document_object_name__c)) == null ? (Datetime)sourceAE.getSobject('Period__r').get('Period_End__c') : (DateTime)sourceAE.getSobject('Period__r').get(mSubledgerCutoffs.get(sourceAE.source_document_object_name__c));
		        DateTime slcDt;
		        //Grab the GL close date, if not specified, use the period end
		        Datetime glcDt;
		        if(sourceAE.getSobject('Period__r') != null){
		        	slcDt = (DateTime)sourceAE.getSobject('Period__r').get(mSubledgerClosedDates.get(sourceAE.source_document_object_name__c));
/*		        	glcDt = (Datetime)sourceAE.getSobject('Period__r').get('GL_Close__c');
		        	
		        	if(slcDt == null){
			        	slcDt = (Datetime)sourceAE.getSobject('Period__r').get('Period_End__c');
			        }		
			        if(glcDt == null){
			        	glcDt = (Datetime)sourceAE.getSobject('Period__r').get('Period_End__c');
					}
*/		        }
		        
		        		        
		        system.debug('trxnDt: ' + trxnDt);
		        system.debug('finalDt: ' + finalDt);
		        system.debug('postDt: ' + postDt);
		        system.debug('slcDt: ' + mSubledgerClosedDates.get(sourceAE.source_document_object_name__c) + ' - '  + slcDt);
//		        system.debug('glcDt: ' + glcDt);
		        
		        //Requirements have simplified - as long as the finalized date is less than the accounting entry's period subledger cutoff, then the record can be unfinalized
		        /*if(slcDt == null){
		        	system.debug( 'FD < SLC');
		            mUnfinalize.put(sObjRec.Id, new UnfinalizeDetail(sObjRec.Id, true, null));
		        }else{
		        	system.debug('SLC <= FD');
		        	mUnfinalize.put(sObjRec.Id, new UnfinalizeDetail(sObjRec.Id, false,sObjRec.get('Name') + ':' + label.Document_cannot_be_unfinalized_because_Subledger_is_closed));
		        }*/
		        if(slcDates.size() == 0){
		        	system.debug( 'FD < SLC');
		            mUnfinalize.put(sObjRec.Id, new UnfinalizeDetail(sObjRec.Id, true, null));
		        }else{
		        	system.debug('SLC <= FD');
		        	mUnfinalize.put(sObjRec.Id, new UnfinalizeDetail(sObjRec.Id, false,sObjRec.get('Name') + ':' + label.Document_cannot_be_unfinalized_because_Subledger_is_closed));
		        }
		    }else{
		        //Just unfinalize, no accounting has been created yet
				mUnfinalize.put(sObjRec.Id, new UnfinalizeDetail(sObjRec.Id, true, null));
		    }
		}
		
		return mUnfinalize;
    }
}