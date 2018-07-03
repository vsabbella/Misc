public with sharing class BudgetImportCon {
	
    public Boolean disableFileUpload {get;set;}
    private static Map<String, Set<String>> exceptionMessages = new Map<String, Set<String>>();
    private static List<Budget_Line1__c> budgetLines;
    public String NamespaceUU { get { return KSE.NamespaceUU; } }
    
    public class BudgetImportConException extends Exception{}
    
    public static String segmentsJSON {
        get{
            if(String.isBlank(segmentsJSON)){
                segmentsJSON = JSON.serialize(getSegmentInfo());
            }
            return segmentsJSON;
        }
    }
    
    public BudgetImportCon(ApexPages.StandardController scon){
        if(scon.getId() == null){
        	disableFileUpload = true;
        	String errorMessage = String.format(Label.No_record_selected, new String[]{Budget__c.sObjectType.getDescribe().getLabel()});
        	ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.FATAL,  errorMessage ));
        }
        
        if(getSegmentInfo().values().size() == 0){
        	disableFileUpload = true;
        	ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.FATAL,  Label.No_segments_defined ));
        }
    }
    
    // NOTE: Had to convert from List<Budget_Line1__c> to List<Map<String, String>> due to a salesforce bug that appends extra characters to values in id fields.
    @RemoteAction
    public static JSONResult saveBudgetLines(String budgetReference, List<String> headerNames, List<Map<String, String>> budgetLinesData){
        
        JsonResult result = new JsonResult();
        FieldInfo periodInfo = FieldInfo.fetchJsonFieldInfos('Budget_Line1__c', new List<String>{'Period__c'})[0];
        
        Map<String, FieldInfo> segmentInfoMap = getSegmentInfo();
        segmentInfoMap.put('Period', periodInfo);
        
        Budget__c budget;
        
        if(!String.isBlank(budgetReference)){
        	SOQLUtil soql = new SOQLUtil('Budget__c');
        	soql.addFields(new set<string>{'Id', 'Company__c'});
        	soql.setWhereClause('Id = :budgetReference');
        	soql.setLimit(1);
        	
            budget = (Budget__c) Database.query(soql.getQuery())[0];    
        }
        
        try{
            // Initializing budget lines
         	budgetLines = new List<Budget_Line1__c>();
         	
            for(Integer i=0; i < budgetLinesData.size(); i++){
            	Decimal budgetAmount = String.isBlank(budgetLinesData[i].get('Budget_Amount__c')) ? 0 : Decimal.valueOf(budgetLinesData[i].get('Budget_Amount__c')) ;
            	budgetLines.add(new Budget_Line1__c(Budget__c = budget.Id, Company__c = budget.Company__c, Budget_Amount__c = budgetAmount));
            }
            
            for(FieldInfo segmentInfo : segmentInfoMap.values()){
            	String sObjectType = segmentInfo.referenceTo;
            	
            	if(!String.isBlank(sObjectType)){
            		String[] types = new String[]{sObjectType};
					Schema.DescribeSObjectResult[] results = Schema.describeSObjects(types);
					
					Boolean hasCompany = results[0].fields.getMap().containsKey('Company__c') ? results[0].fields.getMap().containsKey(KSE.NamespaceUU + 'Company__c') : false;
				  	
	            	if(hasCompany){
	            		populateSegmentId(segmentInfo.field, budgetLinesData, budget.Company__c);
	            	}else{
	            		populateSegmentId(segmentInfo.field, budgetLinesData, '');
	            	}
            	}
            }
            
            BudgetLineService.assignBudgetLineUniqueKeys(budgetLines);
            
            DML.checkUpsertAsUser(budgetLines);
            
            List<Database.UpsertResult> upsertResults = Database.upsert(budgetLines, Budget_Line1__c.fields.ExtId__c, false);
            	
            for(Integer i=0; i < upsertResults.size(); i++){
            	
            	if(! upsertResults[i].isSuccess()){
            		
	        		result.success = false;
	        		
	        		String recordValues = '';
            		
            		for(String headerName : headerNames){ //KNDY-13288
            			FieldInfo segmentInfo = segmentInfoMap.get(headerName);
		        		
	        			if(segmentInfo != null && segmentInfo.title != 'Period'){
	            			recordValues += segmentInfo.title + ' = ' + budgetLinesData[i].get(segmentInfo.field) + ', ';
	        			}
            		}
	            	recordValues = recordValues.removeEnd(', ');
	            	
	            	for(Database.Error error : upsertResults[i].getErrors()){
	            		String exceptionMessage = '';
            			
            			if(error.getStatusCode() == StatusCode.DUPLICATE_VALUE){
	            			exceptionMessage += String.format(Label.Duplicate_combination_found, new String[]{Label.Segments});
	            		}
	            		else
	            		if(error.getStatusCode() == StatusCode.MALFORMED_ID){
	            			String[] errorParts = error.getMessage().split(':');
	            			String segmentName = errorParts[0].trim().replace('__c', '').replace('_', ' ');
	            			String segmentValue = errorParts[2].trim();
	            			
	            			exceptionMessage += String.format(Label.No_record_with_name_found, new String[]{segmentName, segmentValue});
	            		}else{
	            			exceptionMessage += error.getMessage();
	            		}
	            		
	            		if(exceptionMessages.containsKey(exceptionMessage) == false){
	            			exceptionMessages.put(exceptionMessage, new Set<String>());
	            		}
	            		
            			exceptionMessages.get(exceptionMessage).add(recordValues);
	            	}
	        	}            	
            }
            
            for(String exceptionMessage : exceptionMessages.keySet()){
    			result.addMessage(exceptionMessage, ApexPages.Severity.ERROR);
    			result.addMessage('\n', ApexPages.Severity.ERROR);
    			
    			for(String recordValue : exceptionMessages.get(exceptionMessage)){
    				result.addMessage(recordValue, ApexPages.Severity.ERROR);
    			}
    			result.addMessage('\n', ApexPages.Severity.ERROR);
    		}
            
        }catch(Exception ex){
            result.success = false;
            result.addMessage(ex.getMessage() + '\n', ApexPages.Severity.ERROR);
        }
        
        return result;
    }
    
    private static void populateSegmentId(String segmentField, List<Map<String, String>> budgetLinesData, String companyId){
        
        Set<String> recordNames = new Set<String>();
        SchemaUtil util = new SchemaUtil();
        Map<String, sObjectField> fieldsMap = util.getFieldsMap('Budget_Line1__c');
        
        for(Map<String, String> budgetLineWrapper : budgetLinesData){
    		String budgetLineFieldReference = budgetLineWrapper.get(segmentField);
            if(! String.isBlank(budgetLineFieldReference)){
                recordNames.add(budgetLineFieldReference);
            }
        }
        
        //TODO: Check if the field is a lookup to a sobject.
        String sObjectName = fieldsMap.get(segmentField).getDescribe().getReferenceTo()[0].getDescribe().getLocalName();
        
        Map<String, SObject> records = getRecordsByName(sObjectName, recordNames, companyId);
        
        for(Integer j=0; j < budgetLinesData.size(); j++){
        	Map<String, String> budgetLineWrapper = budgetLinesData[j];
        	String budgetLineFieldReference = budgetLineWrapper.get(segmentField);
            
            if( ! String.isBlank(budgetLineFieldReference)){
                SObject record = records.get(budgetLineFieldReference);
                
                if(record != null){
                    budgetLines[j].put(segmentField, record.Id) ;
                }else{
                	// This will throw a dml exception when tried to be upserted.
                	budgetLines[j].put(segmentField, budgetLineFieldReference) ;
                }
            }else{
                // Ignore missing segment values.
                budgetLines[j].put(segmentField, null) ;
            }
        }
    }
    
    private static Map<String, SObject> getRecordsByName(String objectName, Set<String> recordNames, String companyId){
        
        String whereClause = ' Name IN :recordNames ';
        
        if(!String.isBlank(companyId)){
        	whereClause += ' AND Company__c = :companyId ';
        }
        
        SOQLUtil soql = new SOQLUtil(objectName);
        soql.addField('Id');
        soql.addField('Name');
        soql.setWhereClause(whereClause);
        
        Map<String, SObject> records = new Map<String, SObject>();
        for(SObject record : Database.query(soql.getQuery())){
        	String recordName = record.get('Name') != null ? (String)record.get('Name') : '';
        	if(! records.containsKey(recordName)){
            	records.put((String)record.get('Name'), record);
        	}else{
        		String errorMessage = String.format(Label.Duplicate_records_with_name, new String[]{objectName.replace('__c', ''), recordName});
        		throw new BudgetImportConException(errorMessage);
        	}
        }
        
        return records;
    }
    
    private static Map<String, FieldInfo> getSegmentInfo(){
        Map<String, FieldInfo> segmentInfoMap = new Map<String, FieldInfo>();
        
        SegmentService segServ = new SegmentService();
		List<String> segmentList = segServ.getSegmentFields();
        
        Set<String> segments = new Set<String>();
        for(String segmentField : segmentList){ 
            if (segmentField != null && ! segmentField.contains('Company__c')){ // KNDY-12795: Skip the company segment since it won't be in the CSV File.
                segments.add(segmentField);
            }
        }
        
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Budget_Line1__c', new List<String>(segments));
        
        for(FieldInfo field : fieldInfoList){
        	segmentInfoMap.put(field.title, field);
        }
        return segmentInfoMap;
    }
}