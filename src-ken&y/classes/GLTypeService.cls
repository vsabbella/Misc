public with sharing class GLTypeService {

	public void validateGLTypeWithGLTypeRange(List<GL_Type__c> GLTypeList){
		
		List<String> typeRangeList;

		/*
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		*/
		SOQLUtil soql = new SOQLUtil('GL_Type__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','account_range_from__c','account_range_to__c'
		});
		soql.setWhereClause('account_range_from__c != null AND account_range_to__c != null and id not in :GLTypeList');
		List<GL_Type__c> existingGLTypes = Database.query(soql.getQuery());

		for(GL_Type__c thisGLtype: GLTypeList){
			for(GL_Type__c gt: existingGLTypes){	
				if(thisGLtype.account_range_from__c != null && thisGLtype.account_range_from__c == gt.account_range_from__c && thisGLtype.id != gt.id){
					thisGLtype.addError(label.This_GL_Type_has_Account_Range_From_which_has_been_used_earlier);
						break;
				}
				if(thisGLtype.account_range_to__c != null && thisGLtype.account_range_to__c == gt.account_range_to__c && thisGLtype.id != gt.id){
					thisGLtype.addError(label.This_GL_Type_has_Account_Range_To_which_has_been_used_earlier);
						break;
				}
				if(thisGLtype.account_range_from__c != null ){
					typeRangeList = new List<String>();
					typeRangeList.add(thisGLtype.account_range_from__c);
					typeRangeList.add(gt.account_range_from__c);
					typeRangeList.add(gt.account_range_to__c);
					typeRangeList.sort();
					Integer lastElementIndex = typeRangeList.size()-1;
					if((typeRangeList[0] == gt.account_range_from__c && typeRangeList[lastElementIndex] == gt.account_range_to__c) && (!(thisGLtype.id != null && thisGLtype.id == gt.id))){
						thisGLtype.addError(label.This_GL_Type_has_Account_Range_From_which_falls_in_range_that_has_been_used_ea);
						break;
					}
				}
				if(thisGLtype.account_range_to__c != null){
					typeRangeList = new List<String>();
					typeRangeList.add(thisGLtype.account_range_to__c);
					typeRangeList.add(gt.account_range_from__c);
					typeRangeList.add(gt.account_range_to__c);
					typeRangeList.sort();
					Integer lastElementIndex = typeRangeList.size()-1;
					if((typeRangeList[0] == gt.account_range_from__c && typeRangeList[lastElementIndex] == gt.account_range_to__c)  && (!(thisGLtype.id != null && thisGLtype.id == gt.id))){
						thisGLtype.addError(label.This_GL_Type_has_Account_Range_To_which_falls_in_range_that_has_been_used);
						break;
					}
				}
			}
			
		}
	
	}
	
	public void validateGLTypeWithGLAccount(map<id,GL_Type__c> GLTypeMap){
	
		list<GL_Account__c> GLAccountList = new list<GL_Account__c>();
		map<id,list<GL_Account__c>> GLAccountMap = new map <id,list<GL_Account__c>>();
		list<GL_Type__c> GLTypeList = new list<GL_Type__c>(GLTypeMap.values());

		/*
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		*/
		SOQLUtil soql = new SOQLUtil('GL_Account__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','GL_Type__c', 'GL_Type__r.Account_Range_To__c','GL_Account_Number__c'
		});
		soql.setWhereClause('GL_Type__c in: GLTypeList');

        for(GL_Account__c gla: Database.query(soql.getQuery())){
			gl_type__c gltype = GLTypeMap.get(gla.gl_type__c);
			if(gla.GL_Account_Number__c.isNumeric() && gltype.Account_Range_To__c.isNumeric()){
				integer acctnum = integer.valueOF(gla.GL_Account_Number__c);
				integer rangeto = integer.valueOf(gltype.Account_Range_To__c);
				system.debug('acctnum:    ' + acctnum);
				system.debug('rangeto:    ' + rangeto);
				if (acctnum > rangeto){
					system.debug('I came in if first  ' + '');
					if(!GLAccountMap.containskey(gla.id)){
						GLAccountMap.put(gla.gl_Type__c,new List<GL_Account__c>{gla});
					}
					else{
						GLAccountMap.get(gla.gl_Type__c).add(gla);
						
					}
				}
				
			}else{
				system.debug('gla.GL_Account_Number__c:    ' + gla.GL_Account_Number__c);
				system.debug('gltype.Account_Range_To__c:    ' + gltype.Account_Range_To__c);
				if (gla.GL_Account_Number__c > gltype.Account_Range_To__c){
					system.debug('I came in if  ' + '');
					if(!GLAccountMap.containskey(gla.id)){
						GLAccountMap.put(gla.gl_Type__c,new List<GL_Account__c>{gla});
					}
					else{
						GLAccountMap.get(gla.gl_Type__c).add(gla);
						
					}
				}
			}
		
		}
		
		for(GL_Type__c glType: GLTypeMap.values()){
			if(GLAccountMap.containskey(glType.id)){
				glType.addError(Label.account_range_cannot_be_modified);
			}
		}
		
	}
	
	public void validateGLTypeDeleteWithGLAccount(List<GL_Type__c> GLTypeList){
	
		list<GL_Account__c> GLAccountList = new list<GL_Account__c>();
		map<id,list<GL_Account__c>> GLAccountMap = new map <id,list<GL_Account__c>>();
		
        SOQLUtil soql = new SOQLUtil('GL_Account__c');
        soql.addFields(new set<string>{'Id','Name','GL_Type__c'});
        soql.setWhereClause('GL_Type__c in: GLTypeList');
		
		for(GL_Account__c gla: Database.query(soql.getQuery())){
			if(!GLAccountMap.containskey(gla.id)){
				GLAccountMap.put(gla.gl_Type__c,new List<GL_Account__c>{gla});
			}
			else{
				GLAccountMap.get(gla.gl_Type__c).add(gla);
				
			}
		
		}
		
		for(GL_Type__c glType: GLTypeList){
			if(GLAccountMap.containskey(glType.id)){
				glType.addError(Label.GL_Type_cannot_be_deleted);							
			}
		}
		
	}
}