public with sharing class SegmentValidationService {
	
	//Use to enable/disable throwing errors vs setting exceptions on the accounting entries
	public boolean exceptionOnly = false;
	public class SegmentValidationServiceException extends Exception{}
	private static SegmentValidationService instance;
	
	private SegmentValidationService(){
		//Singleton
	}
	
	public static SegmentValidationService getInstance(){
		if(instance == null){
			instance = new SegmentValidationService();
		}
		return instance;
	}
	
	public List<SegmentValidationResponse> beforeValidateAccountingDefaults(List<Accounting_Default__c> accountingDefaults){
		
		List<SegmentDefinition> segmentDefinitions = new List<SegmentDefinition>();
		List<Accounting_Default_Segment_Definition__c> segDefs = Accounting_Default_Segment_Definition__c.getAll().Values();
		Map<String, Set<Id>> mSegmentIds = new Map<String, Set<Id>>(); // 
		Map<String, Map<Id, sObject>> mSegmentToRecs = new Map<String, Map<Id, sObject>>();
		
		for(Accounting_Default_Segment_Definition__c sd : segDefs){
			Set<Id> recordSet = new Set<Id>(); // set to collect the segment object ids
			for(Accounting_Default__c ad : accountingDefaults){
				recordSet.add((Id)ad.get(sd.accounting_default_field__c));
			}

			String ObjAPIName = sd.Object_API_Name__c;
			if(ObjAPIName.equalsIgnoreCase('Intercompany__c')){
	        	ObjAPIName = 'Company__c';
	        }
			
			
			//string iQuery = 'SELECT Id, name FROM ' + ObjAPIName + ' WHERE Id IN :recordSet';
			
			SOQLUtil soql = new SOQLUtil(ObjAPIName, false); //KNDY-14593 we should always run segment validation service in system mode. 
		    	soql.addFields(new Set<String>{'Id', 'Name'});
		    	soql.setWhereClause('Id IN :recordSet');
	    
			Map<Id, sObject> mRecs = new Map<Id, sObject>(Database.query(soql.getQuery())); // Map to store SObject(with fields queried) for the object ids
			
			mSegmentToRecs.put(sd.accounting_default_field__c, mRecs); // Map of Segment Name to mRecs ( Object Query fields)
		}
		
		integer counter = 0;
		for(sObject ad : accountingDefaults){
			
			SegmentDefinition iSD = new SegmentDefinition();
			iSD.recordId = string.valueOf(counter);
			
			for(Accounting_Default_Segment_Definition__c sd : segDefs){
				
				if(mSegmentToRecs.containsKey(sd.accounting_default_field__c)){ // if the segment name is found in the mSegmentToRecs 
					
					Map<Id, sObject> mRecs = mSegmentToRecs.get(sd.accounting_default_field__c); // get the query record from the mRecs map
					
					string segmentValue;
					if(mRecs.containsKey((Id)ad.get(sd.accounting_default_field__c))){
						segmentValue = (string)mRecs.get((Id)ad.get(sd.accounting_default_field__c)).get('name'); // map.get() == > sObject.get('Name')
						
						if(sd.Segment_Number__c == 1){
							iSD.segment1 = segmentValue;
						}else if(sd.Segment_Number__c == 2){
							iSD.segment2 = segmentValue;
						}else if(sd.Segment_Number__c == 3){
							iSD.segment3 = segmentValue;
						}else if(sd.Segment_Number__c == 4){
							iSD.segment4 = segmentValue;
						}else if(sd.Segment_Number__c == 5){
							iSD.segment5 = segmentValue;
						}else if(sd.Segment_Number__c == 6){
							iSD.segment6 = segmentValue;
						}else if(sd.Segment_Number__c == 7){
							iSD.segment7 = segmentValue;
						}else if(sd.Segment_Number__c == 8){
							iSD.segment8 = segmentValue;
						}else if(sd.Segment_Number__c == 9){
							iSD.segment9 = segmentValue;
						}else if(sd.Segment_Number__c == 10){
							iSD.segment10 = segmentValue;
						}
					}
					
				}
			}
			system.debug('iSD: ' + iSD);
			segmentDefinitions.add(iSD);	
			counter++;
		}
		
		return validateSegments(segmentDefinitions);
	}
	
	// stub for the accounting code validation
	public List<SegmentValidationResponse> beforeValidateAccountingCodes(List<Accounting_Code__c> accountingCodes){
		
		List<SegmentDefinition> segmentDefinitions = new List<SegmentDefinition>();
		List<Segment_Definition__c> segDefs = Segment_Definition__c.getAll().Values();
		Map<String, Set<Id>> mSegmentIds = new Map<String, Set<Id>>(); // 
		Map<String, Map<Id, sObject>> mSegmentToRecs = new Map<String, Map<Id, sObject>>();
		
		for(Segment_Definition__c sd : segDefs){
			Set<Id> recordSet = new Set<Id>(); // set to collect the segment object ids
			for(Accounting_Code__c ac : accountingCodes){
				recordSet.add((Id)ac.get(sd.accounting_entry_field__c));
			}

			String ObjAPIName = sd.Object_API_Name__c;
			if(ObjAPIName.equalsIgnoreCase('Intercompany__c')){
	        	ObjAPIName = 'Company__c';
	        }
		
			
			//string iQuery = 'SELECT Id, name FROM ' + sd.Object_API_Name__c + ' WHERE Id IN :recordSet';

			
			SOQLUtil soql = new SOQLUtil(ObjAPIName);
		    	soql.addFields(new Set<String>{'Id', 'Name'});
		    	soql.setWhereClause('Id IN :recordSet');
	    
			Map<Id, sObject> mRecs = new Map<Id, sObject>(Database.query(soql.getQuery())); // Map to store SObject(with fields queried) for the object ids
			
			mSegmentToRecs.put(sd.accounting_entry_field__c, mRecs); // Map of Segment Name to mRecs ( Object Query fields)
		}
		
		integer counter = 0;
		for(sObject ac : accountingCodes){
			
			SegmentDefinition iSD = new SegmentDefinition();
			iSD.recordId = string.valueOf(counter);
			
			for(Segment_Definition__c sd : segDefs){
				
				if(mSegmentToRecs.containsKey(sd.accounting_entry_field__c)){ // if the segment name is found in the mSegmentToRecs 
					
					Map<Id, sObject> mRecs = mSegmentToRecs.get(sd.accounting_entry_field__c); // get the query record from the mRecs map
					
					string segmentValue;
					if(mRecs.containsKey((Id)ac.get(sd.accounting_entry_field__c))){
						segmentValue = (string)mRecs.get((Id)ac.get(sd.accounting_entry_field__c)).get('name'); // map.get() == > sObject.get('Name')
						
						if(sd.Segment_Number__c == 1){
							iSD.segment1 = segmentValue;
						}else if(sd.Segment_Number__c == 2){
							iSD.segment2 = segmentValue;
						}else if(sd.Segment_Number__c == 3){
							iSD.segment3 = segmentValue;
						}else if(sd.Segment_Number__c == 4){
							iSD.segment4 = segmentValue;
						}else if(sd.Segment_Number__c == 5){
							iSD.segment5 = segmentValue;
						}else if(sd.Segment_Number__c == 6){
							iSD.segment6 = segmentValue;
						}else if(sd.Segment_Number__c == 7){
							iSD.segment7 = segmentValue;
						}else if(sd.Segment_Number__c == 8){
							iSD.segment8 = segmentValue;
						}else if(sd.Segment_Number__c == 9){
							iSD.segment9 = segmentValue;
						}else if(sd.Segment_Number__c == 10){
							iSD.segment10 = segmentValue;
						}
					}
					
				}
			}
			system.debug('iSD: ' + iSD);
			segmentDefinitions.add(iSD);	
			counter++;
		}
		
		return validateSegments(segmentDefinitions);
	}
	
	public List<SegmentValidationResponse> afterValidateAccountingEntries(List<Accounting_Entry_Line__c> accountingEntryLines){
		List<SegmentDefinition> segmentDefinitions = new List<SegmentDefinition>();
		//KNDY-1870 Making a call to the SegmentService class instead to retrieve segment list
		SegmentService SS = new SegmentService();
		List<Segment_Definition__c> segDefs = SS.segments; 
		Map<String, Map<Id, sObject>> mSegmentToRecs = new Map<String, Map<Id, sObject>>();
		Map<id,string> mIdToName=new map<id,string>();
		
		set<string> queryFields=new set<String>();
		
		//string queryBuilder='';
		
		for(Segment_Definition__c sd : segDefs){
			
			if(!string.isEmpty(sd.Accounting_Entry_Field__c)){
				queryFields.add(sd.Accounting_Entry_Field__c );
				queryFields.add(sd.Accounting_Entry_Field__c.replace('__c','__r.Name'));
			}
		}	
		
		/*if(sQuery.size()>1)
			queryBuilder = string.join(new List<string>(sQuery),', ');
		
		if(string.isempty(queryBuilder))
			queryBuilder = 'select Id,Name ' + queryBuilder;
		else
			queryBuilder = 'select Id,Name, ' + queryBuilder;
		
		queryBuilder += ' from Accounting_Entry_Line__c where id in :accountingEntryLines';
		*/
		
		SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c');
	    soql.addFields(queryFields);
	    soql.addFields(new Set<String>{'Id', 'Name'});
	    soql.setWhereClause('id in :accountingEntryLines');
	    
		Map<Id, sObject> aelinesObj = new Map<Id, sObject>(Database.query(soql.getQuery())); 
		
		Map<Id, sObject> msRecs ;
		for(Segment_Definition__c sd : segDefs)
		{	
			msRecs = new Map<Id, sObject>();
	
			for(sObject aelObj: aelinesObj.values())
			{	
				if(aelObj.get(sd.accounting_entry_field__c)!=null)
					msRecs.put((Id)aelObj.get(sd.accounting_entry_field__c),aelObj.getSObject(sd.accounting_entry_field__c.replace('__c','__r')));
					
			}
			mSegmentToRecs.put(sd.accounting_entry_field__c, msRecs);
		}
		
		integer counter = 0;
		for(Accounting_Entry_Line__c aeLine : accountingEntryLines){
			SegmentDefinition iSD = new SegmentDefinition();
			iSD.recordId = aeLine.Id;
			for(Segment_Definition__c sd : segDefs){
				if(mSegmentToRecs.containsKey(sd.accounting_entry_field__c)){ // if the segment name is found in the mSegmentToRecs 
					
					Map<Id, sObject> mRecs = mSegmentToRecs.get(sd.accounting_entry_field__c); // get the query record from the mRecs map
					string segmentValue;
					if(mRecs.containsKey((Id)aeLine.get(sd.accounting_entry_field__c))){
						segmentValue = (string)mRecs.get((Id)aeLine.get(sd.accounting_entry_field__c)).get('Name'); // map.get() == > sObject.get('Name')
						
						if(sd.Segment_Number__c == 1){
							iSD.segment1 = segmentValue;
						}else if(sd.Segment_Number__c == 2){
							iSD.segment2 = segmentValue;
						}else if(sd.Segment_Number__c == 3){
							iSD.segment3 = segmentValue;
						}else if(sd.Segment_Number__c == 4){
							iSD.segment4 = segmentValue;
						}else if(sd.Segment_Number__c == 5){
							iSD.segment5 = segmentValue;
						}else if(sd.Segment_Number__c == 6){
							iSD.segment6 = segmentValue;
						}else if(sd.Segment_Number__c == 7){
							iSD.segment7 = segmentValue;
						}else if(sd.Segment_Number__c == 8){
							iSD.segment8 = segmentValue;
						}else if(sd.Segment_Number__c == 9){
							iSD.segment9 = segmentValue;
						}else if(sd.Segment_Number__c == 10){
							iSD.segment10 = segmentValue;
						}
						
					}
					
				}
			}
			segmentDefinitions.add(iSD);	
			counter++;
		}
		
		return validateSegments(segmentDefinitions);
	}
	
	public List<SegmentValidationResponse> afterValidateAEsOrJEs(List<sObject> linesList){
		List<SegmentDefinition> segmentDefinitions = new List<SegmentDefinition>();
		SegmentService SS = new SegmentService();
		// TODO: SK-  confirm the comment below.
		// Assign the first element from the list to the sObject to determine the Type of the sObject passed in ( assuming the sObject passed in are of only one Type and not mixed in the input list)
		sObject sObj = linesList[0]; 
		Schema.SObjectType objectSchema= sObj.getSObjectType();
    	Schema.DescribeSObjectResult sObjectResult = objectSchema.getDescribe();
    	String sObjectName = sObjectResult.getLocalName();

		List<Segment_Definition__c> segDefs = SS.segments; 
		Map<String, Map<Id, sObject>> mSegmentToRecs = new Map<String, Map<Id, sObject>>();
		Map<id,string> mIdToName=new map<id,string>();
		
		set<string> queryFields = new set<String>();
		
		//string queryBuilder='';
		
		for(Segment_Definition__c sd : segDefs){
			if(!string.isEmpty(sd.Accounting_Entry_Field__c)){
				queryFields.add(sd.Accounting_Entry_Field__c );
				queryFields.add(sd.Accounting_Entry_Field__c.replace('__c','__r.Name'));
			}
		}	
		
		/*if(queryFields.size()>1)
			queryBuilder = string.join(new List<string>(queryFields),', ');
		
		if(string.isempty(queryBuilder))
			queryBuilder = 'select Id,Name ' + queryBuilder;
		else
			queryBuilder = 'select Id,Name, ' + queryBuilder;
		
		queryBuilder += ' from '+ sObjectName + ' where id in :linesList';*/
		
		SOQLUtil soql = new SOQLUtil(sObjectName);
	    	soql.addFields(queryFields);
	    	soql.addFields(new Set<String>{'Id', 'Name'});
	    	soql.setWhereClause('id in :linesList');
		
		Map<Id, sObject> mlinesObj = new Map<Id, sObject>(Database.query(soql.getQuery())); 
		
		Map<Id, sObject> msRecs ;
		for(Segment_Definition__c sd : segDefs)
		{	
			msRecs = new Map<Id, sObject>();
	
			for(sObject lineObj: mlinesObj.values())
			{	
				if(lineObj.get(sd.accounting_entry_field__c)!=null)
					msRecs.put((Id)lineObj.get(sd.accounting_entry_field__c),lineObj.getSObject(sd.accounting_entry_field__c.replace('__c','__r')));
					
			}
			mSegmentToRecs.put(sd.accounting_entry_field__c, msRecs);
		}
		
		integer counter = 0;
		for(SObject line : linesList){
			SegmentDefinition iSD = new SegmentDefinition();
			iSD.recordId = Line.Id;
			for(Segment_Definition__c sd : segDefs){
				if(mSegmentToRecs.containsKey(sd.accounting_entry_field__c)){ // if the segment name is found in the mSegmentToRecs 
					
					Map<Id, sObject> mRecs = mSegmentToRecs.get(sd.accounting_entry_field__c); // get the query record from the mRecs map
					string segmentValue;
					if(mRecs.containsKey((Id)Line.get(sd.accounting_entry_field__c))){
						segmentValue = (string)mRecs.get((Id)Line.get(sd.accounting_entry_field__c)).get('Name'); // map.get() == > sObject.get('Name')
						
						if(sd.Segment_Number__c == 1){
							iSD.segment1 = segmentValue;
						}else if(sd.Segment_Number__c == 2){
							iSD.segment2 = segmentValue;
						}else if(sd.Segment_Number__c == 3){
							iSD.segment3 = segmentValue;
						}else if(sd.Segment_Number__c == 4){
							iSD.segment4 = segmentValue;
						}else if(sd.Segment_Number__c == 5){
							iSD.segment5 = segmentValue;
						}else if(sd.Segment_Number__c == 6){
							iSD.segment6 = segmentValue;
						}else if(sd.Segment_Number__c == 7){
							iSD.segment7 = segmentValue;
						}else if(sd.Segment_Number__c == 8){
							iSD.segment8 = segmentValue;
						}else if(sd.Segment_Number__c == 9){
							iSD.segment9 = segmentValue;
						}else if(sd.Segment_Number__c == 10){
							iSD.segment10 = segmentValue;
						}
						
					}
					
				}
			}
			segmentDefinitions.add(iSD);	
			counter++;
		}
		
		return validateSegments(segmentDefinitions);
	}
	
	
	private set<string> validSCOAs = new set<string>();
	private set<string> invalidSCOAs = new set<string>();
	
	public List<SegmentValidationResponse> validateSegments(List<SegmentDefinition> segmentDefinitions){
		
		system.debug(logginglevel.error,'CPU LIMIT: ' + LIMITS.getCpuTime());
		long cpuX = LIMITS.getCpuTime();
		//integer loopCounter = 0;
		
		List<Segment_Validation__c> wildCardValidations = new List<Segment_Validation__c>();
		Map<string, List<Segment_Validation__c>> mSeg1 = new Map<string, List<Segment_Validation__c>>();
		Map<string, List<Segment_Validation__c>> mSeg2 = new Map<string, List<Segment_Validation__c>>();
		Map<string, List<Segment_Validation__c>> mSeg3 = new Map<string, List<Segment_Validation__c>>();
		Map<string, List<Segment_Validation__c>> mSeg4 = new Map<string, List<Segment_Validation__c>>();
		Map<string, List<Segment_Validation__c>> mSeg5 = new Map<string, List<Segment_Validation__c>>();
		Map<string, List<Segment_Validation__c>> mSeg6 = new Map<string, List<Segment_Validation__c>>();
		Map<string, List<Segment_Validation__c>> mSeg7 = new Map<string, List<Segment_Validation__c>>();
		Map<string, List<Segment_Validation__c>> mSeg8 = new Map<string, List<Segment_Validation__c>>();
		Map<string, List<Segment_Validation__c>> mSeg9 = new Map<string, List<Segment_Validation__c>>();
		Map<string, List<Segment_Validation__c>> mSeg10 = new Map<string, List<Segment_Validation__c>>();
		
		List<SegmentValidationResponse> responses = new List<SegmentValidationResponse>();
		
		List<Segment_Validation__c> segmentValidations = returnSegmentValidations(segmentDefinitions);
		
		for(Segment_Validation__c sv : segmentValidations){
			
			//loopCounter++;
			boolean hasWildcard = false;
			
		    if(checkWildcard(sv.segment_1__c)){
		    	hasWildcard = true;
		    }else{
		    	if(mSeg1.containsKey(sv.segment_1__c)){
		            mSeg1.get(sv.segment_1__c).add(sv);
		        }else{
		            mSeg1.put(sv.segment_1__c, new List<Segment_Validation__c>{sv});   
		        }
		    }
		    
		    if(checkWildcard(sv.segment_2__c)){
		    	hasWildcard = true;
		    }else{
		    	 if(mSeg2.containsKey(sv.segment_2__c)){
		            mSeg2.get(sv.segment_2__c).add(sv);
		        }else{
		            mSeg2.put(sv.segment_2__c, new List<Segment_Validation__c>{sv});   
		        }
		    }
		    
		    if(checkWildcard(sv.segment_3__c)){
		        hasWildcard = true;
		    }else{
		    	if(mSeg3.containsKey(sv.segment_3__c)){
		            mSeg3.get(sv.segment_3__c).add(sv);
		        }else{
		            mSeg3.put(sv.segment_3__c, new List<Segment_Validation__c>{sv});   
		        }
		    }
		    
		    if(checkWildcard(sv.segment_4__c)){
		    	hasWildcard = true;
		    }else{
		    	if(mSeg4.containsKey(sv.segment_4__c)){
		            mSeg4.get(sv.segment_4__c).add(sv);
		        }else{
		            mSeg4.put(sv.segment_4__c, new List<Segment_Validation__c>{sv});   
		        }
		    }
		    
		    if(checkWildcard(sv.segment_5__c)){
		        hasWildcard = true;
		    }else{
		    	if(mSeg5.containsKey(sv.segment_5__c)){
		            mSeg5.get(sv.segment_5__c).add(sv);
		        }else{
		            mSeg5.put(sv.segment_5__c, new List<Segment_Validation__c>{sv});   
		        }
		    }
		    
		    if(checkWildcard(sv.segment_6__c)){
		    	hasWildcard = true;
		    }else{
		    	if(mSeg6.containsKey(sv.segment_6__c)){
		            mSeg6.get(sv.segment_6__c).add(sv);
		        }else{
		            mSeg6.put(sv.segment_6__c, new List<Segment_Validation__c>{sv});   
		        }
		    }
		    
		    if(checkWildcard(sv.segment_7__c)){
		        hasWildcard = true;
		    }else{
		    	if(mSeg7.containsKey(sv.segment_7__c)){
		            mSeg7.get(sv.segment_7__c).add(sv);
		        }else{
		            mSeg7.put(sv.segment_7__c, new List<Segment_Validation__c>{sv});   
		        }
		    }
		    
		    if(checkWildcard(sv.segment_8__c)){
		    	hasWildcard = true;
		    }else{
		    	 if(mSeg8.containsKey(sv.segment_8__c)){
		            mSeg8.get(sv.segment_8__c).add(sv);
		        }else{
		            mSeg8.put(sv.segment_8__c, new List<Segment_Validation__c>{sv});   
		        }
		    }
		    
		    if(checkWildcard(sv.segment_9__c)){
		    	hasWildcard = true;
		    }else{
		    	if(mSeg9.containsKey(sv.segment_9__c)){
		            mSeg9.get(sv.segment_9__c).add(sv);
		        }else{
		            mSeg9.put(sv.segment_9__c, new List<Segment_Validation__c>{sv});   
		        }
		    }
		    
		    if(checkWildcard(sv.segment_10__c)){
		    	hasWildcard = true;
		    }else{
		    	if(mSeg10.containsKey(sv.segment_10__c)){
		            mSeg10.get(sv.segment_10__c).add(sv);
		        }else{
		            mSeg10.put(sv.segment_10__c, new List<Segment_Validation__c>{sv});   
		        }
		    }
		    
		    if(hasWildcard){
		    	wildCardValidations.add(sv);
		    }
		}
		
        system.debug(logginglevel.error,'CPU LIMIT: ' + LIMITS.getCpuTime());
        //system.debug(logginglevel.error,'loopCounter: ' + loopCounter);

        //list<integer> loopTimes = new list<integer>();
        
		//Loop through the provided SegmentDefitions, compare to Segment Validations												
		for(SegmentDefinition sd : segmentDefinitions){
			
			integer cpuStart = limits.getCPUtime();
			
			//loopCounter++;
			system.debug(logginglevel.error,'CPU LIMIT: ' + LIMITS.getCpuTime());
			
			SegmentValidationResponse iSVR = new SegmentValidationResponse();
			//Default to reject for now - may need to modify this to default to accept, or follow accept/reject logic
			iSVR.isValid = false;
			iSVR.recordId = sd.recordId;
			
			//Check to see if we have already run through validations for this combination, and return the predetermined result
			string iSCOA = returnSCOA(sd);
			if(validSCOAs.contains(iSCOA)){
				iSVR.isValid = true;
				responses.add(iSVR);
				continue;
			}else if(invalidSCOAs.contains(iSCOA)){
				iSVR.isValid = false;
				responses.add(iSVR);
				continue;
			}
			
			List<Segment_Validation__c> refSegVals;
			
			if(!string.isEmpty(sd.segment1) && mSeg1.containsKey(sd.segment1)){
				refSegVals = mSeg1.get(sd.segment1);
				if(runValidation(sd, refSegVals)){
					iSVR.isValid = true;
					responses.add(iSVR);
					continue;	
				}
			}
			
			if(!string.isEmpty(sd.segment2) && mSeg2.containsKey(sd.segment2)){
				refSegVals = mSeg2.get(sd.segment2);
				if(runValidation(sd, refSegVals)){
					iSVR.isValid = true;
					responses.add(iSVR);
					continue;	
				}
			}
			
			if(!string.isEmpty(sd.segment3) && mSeg3.containsKey(sd.segment3)){
				refSegVals = mSeg3.get(sd.segment3);
				if(runValidation(sd, refSegVals)){
					iSVR.isValid = true;
					responses.add(iSVR);
					continue;	
				}
			}
			
			if(!string.isEmpty(sd.segment4) && mSeg4.containsKey(sd.segment4)){
				refSegVals = mSeg4.get(sd.segment4);
				if(runValidation(sd, refSegVals)){
					iSVR.isValid = true;
					responses.add(iSVR);
					continue;	
				}
			}
			
			if(!string.isEmpty(sd.segment5) && mSeg5.containsKey(sd.segment5)){
				refSegVals = mSeg5.get(sd.segment5);
				if(runValidation(sd, refSegVals)){
					iSVR.isValid = true;
					responses.add(iSVR);
					continue;	
				}
			}
			
			if(!string.isEmpty(sd.segment6) && mSeg6.containsKey(sd.segment6)){
				refSegVals = mSeg6.get(sd.segment6);
				if(runValidation(sd, refSegVals)){
					iSVR.isValid = true;
					responses.add(iSVR);
					continue;	
				}
			}
			
			if(!string.isEmpty(sd.segment7) && mSeg7.containsKey(sd.segment7)){
				refSegVals = mSeg7.get(sd.segment7);
				if(runValidation(sd, refSegVals)){
					iSVR.isValid = true;
					responses.add(iSVR);
					continue;	
				}
			}
			
			if(!string.isEmpty(sd.segment8) && mSeg8.containsKey(sd.segment8)){
				refSegVals = mSeg8.get(sd.segment8);
				if(runValidation(sd, refSegVals)){
					iSVR.isValid = true;
					responses.add(iSVR);
					continue;	
				}
			}
			
			if(!string.isEmpty(sd.segment9) && mSeg9.containsKey(sd.segment9)){
				refSegVals = mSeg9.get(sd.segment9);
				if(runValidation(sd, refSegVals)){
					iSVR.isValid = true;
					responses.add(iSVR);
					continue;	
				}
			}
			
			if(!string.isEmpty(sd.segment10) && mSeg10.containsKey(sd.segment10)){
				refSegVals = mSeg10.get(sd.segment10);
				if(runValidation(sd, refSegVals)){
					iSVR.isValid = true;
					responses.add(iSVR);
					continue;	
				}
			}
			
			//system.debug('calling wildcards ' + sd + ' ' +wildCardValidations);
			//Nothing on exact matches... now try wildcards...
			if(runValidation(sd, wildCardValidations)){
				iSVR.isValid = true;
				responses.add(iSVR);
				continue;	
			}else{
				iSVR.isValid = false;
				responses.add(iSVR);
				invalidSCOAs.add(returnSCOA(sd));
			}
			
			//loopTimes.add(limits.getCPUTime() - cpuStart);
			if(iSVR.isValid == false){
				iSVR.compare.segment1 = sd.segment1;
				iSVR.compare.segment2 = sd.segment2;
				iSVR.compare.segment3 = sd.segment3;
				iSVR.compare.segment4 = sd.segment4;
				iSVR.compare.segment5 = sd.segment5;
				iSVR.compare.segment6 = sd.segment6;
				iSVR.compare.segment7 = sd.segment7;
				iSVR.compare.segment8 = sd.segment8;
				iSVR.compare.segment9 = sd.segment9;
				iSVR.compare.segment10 = sd.segment10;
				system.debug('I am here iSVR **** ' + iSVR + 'sd  ' + sd);						
			}
				responses.add(iSVR);
		}
		
		long cpuY = LIMITS.getCpuTime();
		long cpuTime = cpuY - cpuX;
		
		//system.debug(logginglevel.error, 'loopTimes: ' + loopTimes);
		system.debug(logginglevel.error, 'validSCOAs: ' + validSCOAs);
		system.debug(logginglevel.error, 'invalidSCOAs: ' + invalidSCOAs);
		//system.debug('segment validation responses: ' + responses);
		system.debug(logginglevel.error,'CPU LIMIT: ' + LIMITS.getCpuTime());
		
		system.debug(logginglevel.error,'cpuTime: ' + cpuTime);
		//system.debug(logginglevel.error,'loopCounter: ' + loopCounter);
		//system.debug(logginglevel.info+'responses :'+responses);
		return responses;
	}
	
	private string cleanString(string input){
		//If returning '' for null, all values as null, * or '' will be treated as '' - effectively accepting any value in the compare
		if(input == null || input == ''){
			return null;
		}else{
			return input.replace('*','');
		}

	}
	
	private boolean checkWildcard(string input){
	    if(input == null){
	        return false;
	    }else{
	        return input.contains('*');
	    }
	}
	
	private string compareString(string input, string compare){
		if(compare == null){
			return input;
		}else if(input == null){
			return null;
		}else{
			return input.left(compare.length());
		}
	}
	
	private boolean runValidation(SegmentDefinition sd, List<Segment_Validation__c> validations){
		
		boolean isValid = false;
		for(Segment_Validation__c sv : validations){
			CompareSegment compare = new CompareSegment();
			compare.segment1 = cleanString(sv.Segment_1__c);
			compare.segment2 = cleanString(sv.Segment_2__c);
			compare.segment3 = cleanString(sv.Segment_3__c);
			compare.segment4 = cleanString(sv.Segment_4__c);
			compare.segment5 = cleanString(sv.Segment_5__c);
			compare.segment6 = cleanString(sv.Segment_6__c);
			compare.segment7 = cleanString(sv.Segment_7__c);
			compare.segment8 = cleanString(sv.Segment_8__c);
			compare.segment9 = cleanString(sv.Segment_9__c);
			compare.segment10 = cleanString(sv.Segment_10__c);
			//system.debug(logginglevel.info+'compare :'+compare);
			
			CompareSegment definition = new CompareSegment();
			definition.segment1 = compareString(sd.segment1, compare.segment1);
			definition.segment2 = compareString(sd.segment2, compare.segment2);
			definition.segment3 = compareString(sd.segment3, compare.segment3);
			definition.segment4 = compareString(sd.segment4, compare.segment4);
			definition.segment5 = compareString(sd.segment5, compare.segment5);
			definition.segment6 = compareString(sd.segment6, compare.segment6);
			definition.segment7 = compareString(sd.segment7, compare.segment7);
			definition.segment8 = compareString(sd.segment8, compare.segment8);
			definition.segment9 = compareString(sd.segment9, compare.segment9);
			definition.segment10 = compareString(sd.segment10, compare.segment10);
			//system.debug(logginglevel.info+'definition :'+definition);
			
			if(definition.equals(compare)){
				//Allowable, set boolean, break loop to move on to next SegmentDefinition
				validSCOAs.add(returnSCOA(sd));
				isValid = true;
				break;
			}
		}
		return isValid;
	}
	
	
	
	/*
		Wrappers
	*/
	
	/*
		Description: Generic Segment wrapper that uses an inner method to compare, allow for simple comparison within core validation
					This may be modified or extended for more complex comparisons
	*/
	public class CompareSegment{
		
		public string segment1;
		public string segment2;
		public string segment3;
		public string segment4;
		public string segment5;
		public string segment6;
		public string segment7;
		public string segment8;
		public string segment9;
		public string segment10;
		
		public boolean equals(Object obj){
			CompareSegment compare = (CompareSegment)obj;
			//system.debug('this: ' + this);
			//system.debug('compare: ' + compare);
			boolean isEquals = false;
			if((segment1 == compare.segment1 || compare.segment1 =='')
					&& (segment2 == compare.segment2 || compare.segment2 == '' )
					&& (segment3 == compare.segment3 || compare.segment3 == '')
					&& (segment4 == compare.segment4 || compare.segment4 == '')
					&& (segment5 == compare.segment5 || compare.segment5 == '')
					&& (segment6 == compare.segment6 || compare.segment6 == '')
					&& (segment7 == compare.segment7 || compare.segment7 == '')
					&& (segment8 == compare.segment8 || compare.segment8 == '')
					&& (segment9 == compare.segment9 || compare.segment9 == '')
					&& (segment10 == compare.segment10 || compare.segment10 == '')){
				isEquals = true;			
			}
			return isEquals;
		}
		
	}
	
	
	/* 
		Description: This class becomes the inner interface to the validation processor 
	*/
	public class SegmentDefinition{
		
		//Leave recordId as string, if Ids are not available, the calling process can create their own key to pass in and out of the validation process
		public string recordId;
		
		public string segment1;
		public string segment2;
		public string segment3;
		public string segment4;
		public string segment5;
		public string segment6;
		public string segment7;
		public string segment8;
		public string segment9;
		public string segment10;
		
	}
	
	private string returnSCOA(SegmentDefinition sd){
		return sd.segment1 + '|' + sd.segment2 + '|' + sd.segment3 + '|' + sd.segment4 + '|' + sd.segment5 + '|' + sd.segment6 + '|' + sd.segment7 + '|' + sd.segment8 + '|' + sd.segment9 + '|' + sd.segment10;
	}
	
	/* 
		Description: This class is returned by the validation processor. It provides the originating recordId and boolean to indicate if there were validation issues
	*/
	public class SegmentValidationResponse{
		public CompareSegment compare;
		public string recordId;
		public string recordName;
		public boolean isValid;
		
		public SegmentValidationResponse(){
			compare = new CompareSegment();
		}
		
		//TODO: Add string or List<String> to provide further details as needed
	}
	
    @TestVisible
	private List<Segment_Validation__c> returnSegmentValidations(List<SegmentDefinition> segmentDefinitions){
		
		set<boolean> compare1 = new set <Boolean>{false};
		set<boolean> compare2 = new set <Boolean>{false};
		set<boolean> compare3 = new set <Boolean>{false};
		set<boolean> compare4 = new set <Boolean>{false};
		set<boolean> compare5 = new set <Boolean>{false};
		set<boolean> compare6 = new set <Boolean>{false};
		set<boolean> compare7 = new set <Boolean>{false};
		set<boolean> compare8 = new set <Boolean>{false};
		set<boolean> compare9 = new set <Boolean>{false};
		set<boolean> compare10 = new set <Boolean>{false};
		
		for(SegmentDefinition sd : segmentDefinitions){
			if(sd.segment1 != null ){ //|| sd.segment1 != ''){
				compare1.add(true);
			}if(sd.segment2 != null ){ //|| sd.segment2 != '' ){
				compare2.add(true);
			}if(sd.segment3 != null ){ //|| sd.segment3 != '' ){
				compare3.add(true);
			}if(sd.segment4 != null ){ //|| sd.segment4 != '' ){
				compare4.add(true);
			}if(sd.segment5 != null ){ //|| sd.segment5 != '' ){
				compare5.add(true);
			}if(sd.segment6 != null ){ //|| sd.segment6 != '' ){
				compare6.add(true);
			}if(sd.segment7 != null ){ //|| sd.segment7 != '' ){
				compare7.add(true);
			}if(sd.segment8 != null ){ //|| sd.segment8 != '' ){
				compare8.add(true);
			}if(sd.segment9 != null ){ //|| sd.segment9 != '' ){
				compare9.add(true);
			}if(sd.segment10 != null ){ //|| sd.segment10 != '' ){
				compare10.add(true);
			}
		}																

		//TODO: Add logic to limit the scope of the query based on populated segments in the provided SegmentDefinitions
		//Consider boolean formula on segment validation to limit results based on populated segment constraints
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Segment_Validation__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name','Segment_1__c','Segment_2__c','Segment_3__c','Segment_4__c','Segment_5__c','Segment_6__c','Segment_7__c','Segment_8__c',
			'Segment_9__c','Segment_10__c'
		});
		soql.setWhereClause('active__c = true AND (compare_1__c IN :compare1 OR segment_1__c = \'*\') AND (compare_2__c IN :compare2 OR segment_2__c = \'*\') AND (compare_3__c IN :compare3 OR segment_3__c = \'*\') AND (compare_4__c IN :compare4 OR segment_4__c = \'*\') AND (compare_5__c IN :compare5 OR segment_5__c = \'*\') AND (compare_6__c IN :compare6 OR segment_6__c = \'*\') AND (compare_7__c IN :compare7 OR segment_7__c = \'*\') AND (compare_8__c IN :compare8 OR segment_8__c = \'*\') AND (compare_9__c IN :compare9 OR segment_9__c = \'*\') AND (compare_10__c IN :compare10 OR segment_10__c = \'*\')');
		soql.setOrderByClause('sort_1__c, sort_2__c, sort_3__c, sort_4__c, sort_5__c, sort_6__c, sort_7__c, sort_8__c, sort_9__c, sort_10__c');
		soql.setLimit(10000);
		
		return Database.query(soql.getQuery());

	}

}