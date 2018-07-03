/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class AccountingCodeService {
	static Map<String,Segment_Definition__c> segmentDefinition;
	static Datetime currDate = system.now();
	public static set<String> systemEditable = new set<String>();
	public static SegmentService SS = new SegmentService();
	public static boolean isInvokedfromBatch = false;
	
	//The following fields are used to validate system assignment of field values by the subledger close process
	// Keep the insert commented and use it for update only for now
	public static void validateSystemFields(){
	    if(trigger.isExecuting){
	        if(/*trigger.isInsert ||*/ trigger.isUpdate){

	            for(Accounting_Code__c acctCode : (List<Accounting_Code__c>)Trigger.new){
	            	/*Schema.SObjectType sType = acctCode.getSObjectType();
	            	Map<String,Schema.SObjectField> mFields = sType.getDescribe().fields.getMap();
					for(Schema.SObjectField sfield :  mFields.values())
					{
						Schema.DescribeFieldResult dfr = sfield.getDescribe();
						system.debug(logginglevel.info,'acctCode.scoa_key__c'+acctCode.scoa_key__c+'------- systemEditable:'+AccountingCodeService.systemEditable);
						if(dfr.isCustom() && KSE.isFieldChanging(dfr.getName() , acctCode, trigger.oldMap) && !systemEditable.contains(acctCode.scoa_key__c)){ 
		                    	acctCode.addError(Label.System_Specified_Field);
		                }
					}*/
					for(segment_definition__c sd: SS.segments){
	            		if(KSE.isFieldChanging(sd.Accounting_entry_field__c, acctCode, trigger.oldMap) && !systemEditable.contains(acctCode.scoa_key__c)){ 
		                    	acctCode.addError(Label.System_Specified_Field);
		                }
	                	
	            	}
	            	if(KSE.isFieldChanging('Valid__c', acctCode, trigger.oldMap) && !systemEditable.contains(acctCode.scoa_key__c)){
		            		acctCode.addError(Label.System_Specified_Field);
		            }
		            if(KSE.isFieldChanging('Last_Validated__c', acctCode, trigger.oldMap) && !systemEditable.contains(acctCode.scoa_key__c)){
		            		acctCode.addError(Label.System_Specified_Field);
		            }
	            	
	            }
	        }
	    }
	}
	 
	public static void generateSCOAKey(List<sObject> sObjList){
		
		segmentDefinition = Segment_Definition__c.getAll();
		map<Double, String> mSegmentNumberAndName = new map<Double, String>();
		List<Double> segmentNumberList = new List<Double>();
		for(Segment_Definition__c segment: segmentDefinition.values()){
			mSegmentNumberAndName.put(segment.segment_number__c ,segment.Accounting_Entry_Field__c);
			segmentNumberList.add(segment.segment_number__c);
		}
		segmentNumberList.sort();
		
		for(sObject thisObj: sObjList){
			List<String> iSCOAKey = new List<String>();
			for(Double thisSegNum: segmentNumberList){
				iSCOAKey.add(String.valueof(thisObj.get(mSegmentNumberAndName.get(thisSegNum)))); 
			}
			thisObj.put('SCOA_Key__c', String.join(iSCOAKey,'|'));
		}
		
	}

	public static void segmentValidation(List<Accounting_Code__c> acctCodeList){
		List<SegmentValidationService.SegmentValidationResponse> responses = SegmentValidationService.getInstance().beforeValidateAccountingCodes(acctCodeList);
		for(SegmentValidationService.SegmentValidationResponse resp : responses){
			integer i = integer.valueOf(resp.recordId);
			if(!resp.isValid){
				string errorMessage = 'There is one or more segments with validation exceptions. No segment validation exists for: ';
				if(resp.compare != null){
					errorMessage += (resp.compare.segment1==null?'':'(Segment 1: ' + (resp.compare.segment1==''?'*':resp.compare.segment1) + ') - ');
					errorMessage += (resp.compare.segment2==null?'':'(Segment 2: ' + (resp.compare.segment2==''?'*':resp.compare.segment2) + ') - ');
					errorMessage += (resp.compare.segment3==null?'':'(Segment 3: ' + (resp.compare.segment3==''?'*':resp.compare.segment3) + ') - ');
					errorMessage += (resp.compare.segment4==null?'':'(Segment 4: ' + (resp.compare.segment4==''?'*':resp.compare.segment4) + ') - ');
					errorMessage += (resp.compare.segment5==null?'':'(Segment 5: ' + (resp.compare.segment5==''?'*':resp.compare.segment5) + ') - ');
					errorMessage += (resp.compare.segment6==null?'':'(Segment 6: ' + (resp.compare.segment6==''?'*':resp.compare.segment6) + ') - ');
					errorMessage += (resp.compare.segment7==null?'':'(Segment 7: ' + (resp.compare.segment7==''?'*':resp.compare.segment7) + ') - ');
					errorMessage += (resp.compare.segment8==null?'':'(Segment 8: ' + (resp.compare.segment8==''?'*':resp.compare.segment8) + ') - ');
					errorMessage += (resp.compare.segment9==null?'':'(Segment 9: ' + (resp.compare.segment9==''?'*':resp.compare.segment9) + ') - ');
					errorMessage += (resp.compare.segment10==null?'':'(Segment 10: ' + (resp.compare.segment10==''?'*':resp.compare.segment10) + ') - ');
				}
				acctCodeList[i].put('valid__c', false);
				acctCodeList[i].put('Last_Validated__c',currDate);
				
			} else{
				acctCodeList[i].put('valid__c', true);
				acctCodeList[i].put('Last_Validated__c',currDate);
			}
		}
		
		if(isInvokedfromBatch){ // Update the list only if it is invoked from a batch else before insert trigger context will take care 
			for(Accounting_Code__c thisCode : acctCodeList){
				//system.debug(logginglevel.info,'thisCode.SCOA_Key__c:'+thisCode.SCOA_Key__c);
				AccountingCodeService.systemEditable.add(thisCode.SCOA_Key__c);
			}
			DML.updateAsSystem(acctCodeList);
		}
	}
	
	
	public static void generateSCOACode(List<SObject> sObjList){
		//system.debug(logginglevel.info,'inside the generateSCOACode');
		//map<String, Accounting_Code__c> mlineSCOA = new map<String, Accounting_Code__c>(); 
		segmentDefinition = Segment_Definition__c.getAll();
		map<Double, String> mSegmentNumberAndName = new map<Double, String>();
		List<Double> segmentNumberList = new List<Double>();
		for(Segment_Definition__c segment: segmentDefinition.values()){
			mSegmentNumberAndName.put(segment.segment_number__c ,segment.Accounting_Entry_Field__c);
			segmentNumberList.add(segment.segment_number__c);
		}
		segmentNumberList.sort();
		
		map<String, Accounting_Code__c> m1 = new map<String, Accounting_Code__c>();
		map<String, List<sObject>> m2 = new map<String, List<sObject>>();
		
		for(sObject thisObj: sObjList){
			List<String> iSCOAKeyList = new List<String>();
			for(Double thisSegNum: segmentNumberList){
				iSCOAKeyList.add(String.valueof(thisObj.get(mSegmentNumberAndName.get(thisSegNum)))); 
			}
			List<sObject> aeList;
			String iSCOAKey = String.join(iSCOAKeyList,'|');
			if(!m1.containsKey(iSCOAKey)){
				Accounting_Code__c newAcctCode = new Accounting_Code__c();
				
				for(Double thisSegNum: segmentNumberList){
					newAcctCode.put( mSegmentNumberAndName.get(thisSegNum), (Id) thisObj.get(mSegmentNumberAndName.get(thisSegNum)));
				}	
				newAcctCode.SCOA_Key__c = iSCOAKey;
				m1.put(iSCOAKey, newAcctCode);
				AccountingCodeService.systemEditable.add(iSCOAKey);
				
			}
			//system.debug(logginglevel.info,'iSCOAKey'+iSCOAKey+'----m1:'+m1+' --- aeList:'+aeList);
			
			if(m2.containsKey(iSCOAKey)){
				aeList = m2.get(iSCOAKey);
				aeList.add(thisObj);
				m2.put(iSCOAKey,aeList);
			}else{
				aeList = new List<sObject>();
				aeList.add(thisObj);
				m2.put(iSCOAKey, aeList);
			}
			//system.debug(logginglevel.info,'m2:'+m2);
		}

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Accounting_Code__c', false); //enforceFLS=false, running in system mode
		soql.addFields(new set<string>{
			'Id','SCOA_Key__c'
		});
		Set<String> sKeys = m1.keySet();
		soql.setWhereClause('SCOA_Key__c IN :sKeys');
		List<Accounting_Code__c> existingAccountingCodes = Database.query(soql.getQuery());

        Map<string, Accounting_Code__c> masterAccountingCodes = new Map<string, Accounting_Code__c>();
		
        for(Accounting_Code__c ac : existingAccountingCodes){
        	m1.remove(ac.scoa_key__c);
        	masterAccountingCodes.put(ac.SCOA_Key__c, ac);
        }
		DML.upsertAsSystem(); upsert m1.values() SCOA_Key__c;
        masterAccountingCodes.putAll(m1);              
		
		// TODO: When the SCOA combination is null 
		for(String thisSCOAKey: m2.keyset()){
			for(sObject thisObj: m2.get(thisSCOAKey)){
				if(masterAccountingCodes.get(thisSCOAKey) != null){
					thisObj.put('Accounting_Code__c',masterAccountingCodes.get(thisSCOAKey).id );
				}
				//system.debug(logginglevel.info,'thisObj:'+thisObj);
			}
		}
		
		
	}
}