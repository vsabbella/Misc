public with sharing class CriteriaService {
	
	private static final set<string> textFieldTypes = new set<string>{'COMBOBOX', 'EMAIL', 'ENCRYPTEDSTRING', 'ID', 'MULTIPICKLIST', 'PHONE', 'PICKLIST', 'REFERENCE', 'STRING', 'TEXTAREA', 'URL', 'BOOLEAN'};
	private static final set<string> numberFieldTypes = new set<string>{'CURRENCY', 'DOUBLE', 'INTEGER', 'PERCENT'};
	private static final set<string> dateFieldTypes = new set<string>{'DATE'};
	private static final set<string> dateTimeFieldTypes = new set<string>{'DATETIME'};
	
	private static map<string, map<string, Schema.sObjectField>> mObjectFields = new map<string, map<string, Schema.sObjectField>>();
	
	public class CriteriaException extends Exception{}
	
	public static boolean evaluateCriteria(List<Criteria__c> criteria, sObject rec){
		//TODO: Criteria Evaluation needs massive expansion in flexibility via factories or other loosely coupled components for various comparison operators
		//TODO: Support grouped criteria via (1 AND 2) OR 3
		//This is just an initial pass at resolving criteria
		
		if(criteria == null){
			return true;
		}
		
		boolean isValid = true;
		
		
		for(Criteria__c c : criteria){
			
			system.debug('c.field__c: ' + c.Id + ' - ' + c.field__c);
			
			sObject refObj = getRefObject(c.field__c, rec);
			set<string> queryFields = returnQueryFields(rec);
			
			system.debug('queryFields: ' + queryFields);
			system.debug('refObj: ' + refObj);
			
			string fieldPath = c.field__c.contains('.') ? c.field__c.substringAfterLast('.').toLowerCase() : c.field__c.toLowerCase();
			system.debug('queryFields contains ' + fieldPath + ': ' + queryFields.contains(fieldPath));
			
			if((refObj == null || !queryFields.contains(fieldPath)) && fieldPath != 'LastActivityDate'){ //LastActivityDate is a special case
				//Null pointer from relative reference on object field - ex: Reason_Code__r.Name
				isValid = false;
				break;
			}
			
			string objName = refObj.getSObjectType().getDescribe().getName();
			system.debug('objName: ' + objName);
			
			Map<string, Schema.SObjectField> mFields = SchemaUtil.getInstance().getFieldsMap(objName);
			string fieldName = c.field__c.contains('.') ? c.field__c.substringAfterLast('.').toLowerCase() : c.field__c.toLowerCase();
			system.debug('fieldName: ' + fieldName);
			
			//Cleanup the namespace for the fields map - doesn't return namespace context
			fieldName = fieldName.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(), '');
			if(!mFields.containsKey(fieldName)){
				isValid = false;
				break;
			}
			
			Schema.Describefieldresult field = mFields.get(fieldName).getDescribe();
			string fieldType = string.valueOf(field.getType());
			system.debug('fieldType: ' + fieldType);
			
			//Evaluate variable type specific conditions, throwing exceptions with incompatible comparison operators
			if(textFieldTypes.contains(fieldType)){
				isValid = evaluateTextField(fieldType, c, rec);		
			}else if(numberFieldTypes.contains(fieldType)){
				isValid = evaluateNumberField(fieldType, c, rec);			
			}else if(dateFieldTypes.contains(fieldType)){
				isValid = evaluateDateField(fieldType, c, rec);			
			}else if(dateTimeFieldTypes.contains(fieldType)){
				isValid = evaluateDateTimeField(fieldType, c, rec);			
			}else{
				//TODO: Throw error?
				isValid = false;
			}
			system.debug('isValid: ' + c.Id + ' - ' +  isValid);
			if(!isValid){
				break;
			}
		}
		system.debug('return isValid: ' +  isValid);
		return isValid;
	}
	
	public static boolean evaluateOpenProcess(Step__c referenceStep, Step__c activeStep){
		boolean isOpen = true;
		if(referenceStep.Sequence__c != null && activeStep.Sequence__c != null){
			isOpen = (referenceStep.Sequence__c < activeStep.Sequence__c);
		}
		return isOpen;
	}
	
	

	/* -------------------- */
	/* Process Availability */
	/* -------------------- */
	
	public static List<Process.ProcessFlow> findProcesses(string sObjectName){
		return Process.returnObjectFlows(sObjectName);
	}

	public static Map<Id, sObject> returnCriteriaEvalRecs(string sObjectName, string sObjectStep, List<Criteria__c> criteria, List<sObject> records){
		
		set<string> fieldPaths = new set<string>();
		
		if(sObjectStep != null){
			fieldPaths.add(sObjectStep.toLowerCase());
		}
		fieldPaths.addAll(returnQueryFields(records[0]));
		
		for(Criteria__c c : criteria){
			if(c.field__c != null){
				fieldPaths.add(c.field__c.toLowerCase());
			}
			
			if(c.value_field__c == 'Field' && c.reference__c != null && c.reference__c != ''  && c.reference__c != 'null'){
				if(c.reference__c != null){
					fieldPaths.add(c.reference__c.toLowerCase());
				}
			}
		}
		
		system.debug('fieldPaths: ' + fieldPaths);
		
		SOQLUtil soql = new SOQLUtil(sObjectName, TRUE);
		soql.addFields(fieldPaths);
		soql.setWhereClause('Id IN :records');

		system.debug('query: ' + soql.getQuery());
		List<sObject> criteriaRecs = Database.query(soql.getQuery());
		Map<Id, sObject> mRecs = new Map<Id, sObject>(criteriaRecs);
		
		return mRecs;
	}
	
	public static set<string> returnQueryFields(sObject sObj){
		
		String sObjectName = sobj.getSObjectType().getDescribe().getName();
		
		if(mObjectFields.containsKey(sObjectName) == false){
			mObjectFields.put(sObjectName, sobj.getSObjectType().getDescribe().fields.getMap());
		}
		
		//KNDY-7410
		//loop through all the fields in this object, create a copy with the ns removed
		String nsUUlCase = KSE.NamespaceUU.toLowerCase();
		set<string> queryFieldWithAndWithoutNS = new set<string>(mObjectFields.get(sObjectName).keySet());
		for (String f: queryFieldWithAndWithoutNS) {
			queryFieldWithAndWithoutNS.add(f.removeStart(nsUUlCase));	
		}
		
		return queryFieldWithAndWithoutNS;
		/*
		map<string,object> objmap = (map<string,object>) Json.deserializeuntyped(JSON.serialize(sObj));
		////system.debug('objMap.keySet(): ' + objMap.keySet());
		//Cleanup
		//set<string> cleanKeys = objMap.keySet().clone();
		set<string> cleanKeys = new set<string>();
		for(string key : objMap.keySet()){
			if(key != null && key != '' && key != 'attributes'){
				string iKey = key.toLowerCase();
				iKey = iKey.replace(KSE.NamespaceUU.toLowerCase(),'');
				if(iKey.right(3) == '__r'){
					iKey += '.name';
				}
				cleanKeys.add(iKey);
			}
		}
		
		return cleanKeys;*/
	}
	
	/* ----------- */
	/* Comparisons */
	/* ----------- */
	
	private static boolean evaluateTextField(string fieldType, Criteria__c c, sObject rec){
		boolean isValid = false;
		system.debug('inside criteria service, field type: '+fieldType);
		if(fieldType == 'REFERENCE' && c.Operator__c.toLowerCase() == 'equals'){
			c.operator__c = 'starts with'; //OTC-466 
		}
		else if(fieldType == 'REFERENCE' && c.Operator__c.toLowerCase() == 'not equal to')
		{
			c.operator__c = 'does not start with';
			
		}
		system.debug('inside criteria service: '+ c.operator__c );
		if(c.Operator__c.toLowerCase() == 'equals'){
			isValid = checkEquals(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'not equal to'){
			isValid = checkNotEqualTo(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'starts with'){
			isValid = checkStartsWith(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'does not start with'){
			isValid = checkNotStartWith(c, rec);
		}
		else if(c.Operator__c.toLowerCase() == 'contains'){
			isValid = checkContains(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'does not contain'){
			isValid = checkNotContains(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'is changing'){
			isValid = checkIsChanging(c, rec);
		}else{
			throw new CriteriaException(fieldType + Label.Cannot_be_compared_with_an_operator + c.Operator__c + '"');
		}
		return isValid;
			
	}
	
	private static boolean evaluateNumberField(string fieldType, Criteria__c c, sObject rec){
		boolean isValid = false;
		if(c.Operator__c.toLowerCase() == 'equals'){
			isValid = checkNumberEquals(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'not equal to'){
			isValid = checkNumberNotEqualTo(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'less than'){
			isValid = checkLessThan(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'greater than'){
			isValid = checkGreaterThan(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'less or equal'){
			isValid = checkLessEqual(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'greater or equal'){
			isValid = checkGreaterEqual(c, rec);
		}else{
			throw new CriteriaException(fieldType + Label.Cannot_be_compared_with_an_operator + c.Operator__c + '"');
		}
		return isValid;
	}
	
	private static boolean evaluateDateField(string fieldType, Criteria__c c, sObject rec){
		boolean isValid = false;
		if(c.Operator__c.toLowerCase() == 'equals'){
			isValid = checkEquals(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'not equal to'){
			isValid = checkNotEqualTo(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'less than'){
			isValid = checkDateLessThan(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'greater than'){
			isValid = checkDateGreaterThan(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'less or equal'){
			isValid = checkDateLessEqual(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'greater or equal'){
			isValid = checkDateGreaterEqual(c, rec);
		}else{
			throw new CriteriaException(fieldType + Label.Cannot_be_compared_with_an_operator + c.Operator__c + '"');
		}
		return isValid;
	}
	
	private static boolean evaluateDateTimeField(string fieldType, Criteria__c c, sObject rec){
		boolean isValid = false;
		if(c.Operator__c.toLowerCase() == 'equals'){
			isValid = checkEquals(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'not equal to'){
			isValid = checkNotEqualTo(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'less than'){
			isValid = checkDateTimeLessThan(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'greater than'){
			isValid = checkDateTimeGreaterThan(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'less or equal'){
			isValid = checkDateTimeLessEqual(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'greater or equal'){
			isValid = checkDateTimeGreaterEqual(c, rec);
		}else{
			throw new CriteriaException(fieldType + Label.Cannot_be_compared_with_an_operator + c.Operator__c + '"');
		}
		return isValid;
	}
	
	/* ---------------------------------- */
	/* Criteria Evaluation worker methods */
	/* ---------------------------------- */
	
	// TODO
	private static boolean checkIsChanging(Criteria__c c, sObject rec){
		boolean isValid = false;
		if(c.Value_Field__c == 'Field'){
			if(trigger.isExecuting){
				isValid = KSE.isFieldChanging(c.field__c, rec, trigger.oldMap);
			}else{
				system.debug(LoggingLevel.ERROR, Label.This_criteria_cannot_be_used_out_of_trigger_context + c.Name);
			}
		}else{
			system.debug(LoggingLevel.ERROR, Label.Criteria_Value_Field_must_be_field + c.Name);
		}
		return isValid;
	}
	
	private static boolean checkEquals(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			system.debug('inside criteeria service: '+String.valueOf(getValue(c.field__c, rec)));
			system.debug('inside criteeria service: '+String.valueOf(c.reference__c));
			isValid = (String.valueOf(getValue(c.field__c, rec)) == String.valueOf(c.reference__c));
		}else if(c.Value_Field__c == 'Field'){
			isValid = (getValue(c.field__c, rec) == getValue(c.reference__c, rec));
		}
		return isValid;
	}
	
	private static boolean checkNotEqualTo(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			isValid = (getValue(c.field__c, rec) != c.reference__c);
		}else if(c.Value_Field__c == 'Field'){
			isValid = (getValue(c.field__c, rec) != getValue(c.reference__c, rec));
		}
		return isValid;
	}
	private static boolean checkNotStartWith(Criteria__c c, sObject rec){ 
		boolean isValid = true;
		system.debug('fields: '+c.field__c+ ' '+ c.reference__c);
		system.debug('fields: '+((string)getValue(c.field__c, rec)));
		
		if(c.Value_Field__c == 'Value'){
			string val = (string)getValue(c.field__c, rec);
			string ref = c.reference__c;
			isValid = val == null || val.trim() == '' ? false : !val.startswith(ref);
		}else if(c.Value_Field__c == 'Field'){
			string val = (string)getValue(c.field__c, rec);
			string ref = (string)getValue(c.reference__c, rec);
			isValid = val == null || val.trim() == '' ? false : !val.startswith(ref);
		}
		return isValid;
	}
	private static boolean checkStartsWith(Criteria__c c, sObject rec){ //OTC-466
		boolean isValid = true;
		system.debug('fields: '+c.field__c+ ' '+ c.reference__c);
		//system.debug('fields: '+((string)getValue(c.field__c, rec)).startswith(c.reference__c));
		if(c.Value_Field__c == 'Value'){
			string val = (string)getValue(c.field__c, rec);
			string ref = c.reference__c;
			isValid = val == null || val.trim() == '' ? false : val.startswith(ref);
		}else if(c.Value_Field__c == 'Field'){
			string val = (string)getValue(c.field__c, rec);
			string ref = (string)getValue(c.reference__c, rec);
			isValid = val == null || val.trim() == '' ? false : val.startswith(ref);
		}
		return isValid;
	}
	
	private static boolean checkNumberEquals(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			isValid = (decimal.valueOf(getStringValue(c.field__c, rec)) == decimal.valueOf(c.reference__c));
		}else if(c.Value_Field__c == 'Field'){
			isValid = (decimal.valueOf(getStringValue(c.field__c, rec)) == decimal.valueOf(getStringValue(c.reference__c, rec)));
		}
		return isValid;
	}
	
	private static boolean checkNumberNotEqualTo(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			isValid = (decimal.valueOf(getStringValue(c.field__c, rec)) != decimal.valueOf(c.reference__c));
		}else if(c.Value_Field__c == 'Field'){
			isValid = (decimal.valueOf(getStringValue(c.field__c, rec)) != decimal.valueOf(getStringValue(c.reference__c, rec)));
		}
		return isValid;
	}
	
	private static boolean checkContains(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			string val = (string)getValue(c.field__c, rec);
			string ref = c.reference__c;
			isValid = val.contains(ref);
		}else if(c.Value_Field__c == 'Field'){
			string val = (string)getValue(c.field__c, rec);
			string ref = (string)getValue(c.reference__c, rec);
			isValid = val.contains(ref);
		}
		return isValid;
	}
	
	private static boolean checkNotContains(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			string val = (string)getValue(c.field__c, rec);
			string ref = c.reference__c;
			isValid = !val.contains(ref);
		}else if(c.Value_Field__c == 'Field'){
			string val = (string)getValue(c.field__c, rec);
			string ref = (string)getValue(c.reference__c, rec);
			isValid = !val.contains(ref);
		}
		return isValid;
	}
	
	private static boolean checkGreaterThan(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			decimal val = decimal.valueOf(getStringValue(c.field__c, rec));
			decimal ref = decimal.valueOf(c.reference__c);
			isValid = (val > ref);
		}else if(c.Value_Field__c == 'Field'){
			decimal val = decimal.valueOf(getStringValue(c.field__c, rec));
			decimal ref = decimal.valueOf(getStringValue(c.reference__c, rec));			
			isValid = (val > ref);
		}
		return isValid;
	}
	
	private static boolean checkLessThan(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			decimal val = decimal.valueOf(getStringValue(c.field__c, rec));
			decimal ref = decimal.valueOf(c.reference__c);
			isValid = (val < ref);
		}else if(c.Value_Field__c == 'Field'){
			decimal val = decimal.valueOf(getStringValue(c.field__c, rec));
			decimal ref = decimal.valueOf(getStringValue(c.reference__c, rec));			
			isValid = (val < ref);
		}
		return isValid;
	}
	
	private static boolean checkGreaterEqual(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			decimal val = decimal.valueOf(getStringValue(c.field__c, rec));
			decimal ref = decimal.valueOf(c.reference__c);
			isValid = (val >= ref);
		}else if(c.Value_Field__c == 'Field'){
			decimal val = decimal.valueOf(getStringValue(c.field__c, rec));
			decimal ref = decimal.valueOf(getStringValue(c.reference__c, rec));
			isValid = (val >= ref);
		}
		return isValid;
	}
	
	private static boolean checkLessEqual(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			decimal val = decimal.valueOf(getStringValue(c.field__c, rec));
			decimal ref = decimal.valueOf(c.reference__c);
			isValid = (val <= ref);
		}else if(c.Value_Field__c == 'Field'){
			decimal val = decimal.valueOf(getStringValue(c.field__c, rec));
			decimal ref = decimal.valueOf(getStringValue(c.reference__c, rec));
			isValid = (val <= ref);
		}
		return isValid;
	}
	
	private static boolean checkDateGreaterThan(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			date val = date.valueOf(getValue(c.field__c, rec));
			date ref = date.valueOf(c.reference__c);
			isValid = (val > ref);
		}else if(c.Value_Field__c == 'Field'){
			date val = date.valueOf(getValue(c.field__c, rec));
			date ref = date.valueOf(getValue(c.reference__c, rec));
			isValid = (val > ref);
		}
		return isValid;
	}
	
	private static boolean checkDateLessThan(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			date val = date.valueOf(getValue(c.field__c, rec));
			date ref = date.valueOf(c.reference__c);
			isValid = (val < ref);
		}else if(c.Value_Field__c == 'Field'){
			date val = date.valueOf(getValue(c.field__c, rec));
			date ref = date.valueOf(getValue(c.reference__c, rec));
			isValid = (val < ref);
		}
		return isValid;
	}
	
	private static boolean checkDateGreaterEqual(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			date val = date.valueOf(getValue(c.field__c, rec));
			date ref = date.valueOf(c.reference__c);
			isValid = (val >= ref);
		}else if(c.Value_Field__c == 'Field'){
			date val = date.valueOf(getValue(c.field__c, rec));
			date ref = date.valueOf(getValue(c.reference__c, rec));
			isValid = (val >= ref);
		}
		return isValid;
	}
	
	private static boolean checkDateLessEqual(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			date val = date.valueOf(getValue(c.field__c, rec));
			date ref = date.valueOf(c.reference__c);
			isValid = (val <= ref);
		}else if(c.Value_Field__c == 'Field'){
			date val = date.valueOf(getValue(c.field__c, rec));
			date ref = date.valueOf(getValue(c.reference__c, rec));
			isValid = (val <= ref);
		}
		return isValid;
	}
	
	private static boolean checkDateTimeGreaterThan(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			datetime val = datetime.valueOf(getValue(c.field__c, rec));
			datetime ref = datetime.valueOf(c.reference__c);
			isValid = (val > ref);
		}else if(c.Value_Field__c == 'Field'){
			datetime val = datetime.valueOf(getValue(c.field__c, rec));
			datetime ref = datetime.valueOf(getValue(c.reference__c, rec));
			isValid = (val > ref);
		}
		return isValid;
	}
	
	private static boolean checkDateTimeLessThan(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			datetime val = datetime.valueOf(getValue(c.field__c, rec));
			datetime ref = datetime.valueOf(c.reference__c);
			isValid = (val < ref);
		}else if(c.Value_Field__c == 'Field'){
			datetime val = datetime.valueOf(getValue(c.field__c, rec));
			datetime ref = datetime.valueOf(getValue(c.reference__c, rec));
			isValid = (val < ref);
		}
		return isValid;
	}
	
	private static boolean checkDateTimeGreaterEqual(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			datetime val = datetime.valueOf(getValue(c.field__c, rec));
			datetime ref = datetime.valueOf(c.reference__c);
			isValid = (val >= ref);
		}else if(c.Value_Field__c == 'Field'){
			datetime val = datetime.valueOf(getValue(c.field__c, rec));
			datetime ref = datetime.valueOf(getValue(c.reference__c, rec));
			isValid = (val >= ref);
		}
		return isValid;
	}
	
	private static boolean checkDateTimeLessEqual(Criteria__c c, sObject rec){
		boolean isValid = true;
		if(c.Value_Field__c == 'Value'){
			datetime val = datetime.valueOf(getValue(c.field__c, rec));
			datetime ref = datetime.valueOf(c.reference__c);
			isValid = (val <= ref);
		}else if(c.Value_Field__c == 'Field'){
			datetime val = datetime.valueOf(getValue(c.field__c, rec));
			datetime ref = datetime.valueOf(getValue(c.reference__c, rec));
			isValid = (val <= ref);
		}
		return isValid;
	}
	
	private static object getValue(String refString, sObject inputObject){
	 	
		if ( refString == null || String.isBlank(refString) == true ) {
			return null;		
		}

		String[] RefStringArray = refString.split('\\.');
		String lastField = RefStringArray.get(RefStringArray.size()-1);

		for(Integer i=0;i<RefStringArray.size()-1; ++i) {
			if ( inputObject != null )
				inputObject = inputObject.getSObject(RefStringArray[i]);	
		}
				
		return (inputObject != null) ? inputObject.get(lastField) : null ; 
	}
	
	private static string getStringValue(string refString, sObject inputObject){
		return string.valueOf(getValue(refString, inputObject));
	}
	
	private static sObject getRefObject(String refString, sObject inputObject){
	 	
		if ( refString == null || String.isBlank(refString) == true ) {
			return null;		
		}

		String[] RefStringArray = refString.split('\\.');
		String lastField = RefStringArray.get(RefStringArray.size()-1);

		for(Integer i=0;i<RefStringArray.size()-1; ++i) {
			if ( inputObject != null )
				inputObject = inputObject.getSObject(RefStringArray[i]);	
		}
		return inputObject;
	}
	
	/*
	boolean isValid = false;
		if(c.Operator__c.toLowerCase() == 'equals'){
			isValid = checkEquals(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'not equal to'){
			isValid = checkNotEqualTo(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'starts with'){
			isValid = checkNotEqualTo(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'contains'){
			isValid = checkNotEqualTo(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'does not contain'){
			isValid = checkNotEqualTo(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'less than'){
			isValid = checkLessThan(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'greater than'){
			isValid = checkGreaterThan(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'less or equal'){
			isValid = checkLessEqual(c, rec);
		}else if(c.Operator__c.toLowerCase() == 'greater or equal'){
			isValid = checkGreaterEqual(c, rec);
		}else{
			throw new CriteriaException('You cannot compare ' + fieldType + ' with an operator of "' + c.Operator__c + '"');
		}
		return isValid;
	*/
}