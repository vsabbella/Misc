public with sharing class BankTransactionMatchingRuleService {
    
    private static BankTransactionMatchingRuleService instance = null;
    public class BankTransactionMatchingRuleServiceException extends Exception{}
    public static boolean requestFromUI = false;   //KNDY-15794
    public static BankTransactionMatchingRuleService getInstance(){
        if ( instance == null ) instance = new BankTransactionMatchingRuleService();
        return instance;
    } 
    
    public class SoqlStructure{
    	//KNDY-15788
        Set<string> fieldsGrouped =  new Set<String> {
		'Amount_Threshold__c','Amount__c','Auto_Approve__c','Bank_Account__c','Company__c','Date_Threshold__c','Description__c',
		'Documents__c','End_Date__c','ExtId__c','For_Amount_Threshold__c','For_Date_Threshold_Days__c'
		,'Keep_In_Match_Pool__c','Rank_Key__c','Reference__c','Start_Date__c','Transacted_With__c','Transaction_Date__c'};
        String soql='';
   }
   //KNDY-15788 bank transaction wrapper to check duplicates
   public class BankTransactionRuleWrapper{
		
		String groupingCriteriaStr ;
		DateTime startDate;
		DateTime endDate;
		decimal amountThreshHold;
		decimal dateThreshHold;
		Transaction_Matching_Rule__c btrRecord;
		Id btrId;
		Set<string> fordocuments = new set<string>();
		
		
		public BankTransactionRuleWrapper(Transaction_Matching_Rule__c btr){
			startDate = btr.Start_Date__c;
			endDate = btr.End_Date__c;
			btrId = btr.Id;		
			amountThreshHold = btr.Amount_Threshold__c;
			dateThreshHold = btr.Date_Threshold__c;
			btrRecord = btr;
			groupingCriteriaStr = getGroupingCriteriaDescription(btr);
			for (string docs :btr.Documents__c.split(';')){
				fordocuments.add(docs);
			}
		}
	}
	
    
    SchemaUtil util = SchemaUtil.getInstance();
	private dateTime timeNow = system.now();
    
    public static void setRankKey() {
        list<Transaction_Matching_Rule__c> tmrsToSetRownums= new list<Transaction_Matching_Rule__c>();
		if(trigger.isBefore && trigger.isUpdate) {
			for(Transaction_Matching_Rule__c tmr : (list<Transaction_Matching_Rule__c>) trigger.new) {
                if( ( (Transaction_Matching_Rule__c)trigger.oldmap.get(tmr.id)).Is_Active__c ==False  && tmr.Is_Active__c  == true ){
                   tmrsToSetRownums.add(tmr);
                }else{
				tmr.Rank_Key__c = tmr.is_Active__c  == true ? tmr.Company__c+'|'+tmr.Bank_Account__c+'|'+tmr.Rank__c : null; 
				tmr.Rank__c = tmr.Is_Active__c  == true ? tmr.Rank__c : null;  
                }
				system.debug('tmr.Rank_Key__c '+tmr.Rank_Key__c); 
			}
            if(tmrsToSetRownums.size()>0){
            	system.debug(logginglevel.error,'tmrsToSetRownums '+tmrsToSetRownums);
                setLineNumbers(tmrsToSetRownums);
            }
		}
		else if(trigger.isBefore && trigger.isInsert) {
			setLineNumbers((list<Transaction_Matching_Rule__c>) trigger.new);
		}
	}
    
    public static void setLineNumbers(List<Transaction_Matching_Rule__c> matchLines) {
        
        
        SOQLUtil soql = new SOQLUtil('Transaction_Matching_Rule__c', true,true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'MAX(Rank__c) rankMax'
		});
        List<AggregateResult> aggResults = Database.query(soql.getQuery());
		System.debug(logginglevel.error,'Max is: ' + aggResults[0].get('rankMax'));
        Decimal rankMax = (aggResults != null && aggResults[0].get('rankMax') != null) ? (Decimal)aggResults[0].get('rankMax') : Decimal.valueOf('0');
       System.debug(logginglevel.error,'rankMax: ' + rankMax);
        // Assign line numbers
        Decimal val = rankMax;
        for (Transaction_Matching_Rule__c rule : matchLines) {
        	system.debug(logginglevel.error,'rule rank '+rule.rank__c);
        	if((boolean)rule.get('Is_Active__c') != true) {
        		rule.put('Rank_Key__c',null);
        	}else if(rule.get('Rank__c') == null || rule.get('Rank__c') == 0) {
               
                if(val != null){
	              rule.put('Rank__c', ++val);
	              rule.put('Rank_Key__c', rule.Company__c+'|'+rule.Bank_Account__c+'|'+val);
                }
			}else {
				rule.put('Rank_Key__c', rule.Company__c+'|'+rule.Bank_Account__c+'|'+rule.get('Rank__c'));
			}
		}
		system.debug(LoggingLevel.Error,'matchLines '+matchLines);
	}
    //KNDY-15788 - modified to add more duplication criteria
    public static void checkDuplicates() {
        boolean changed = false;
        Transaction_Matching_Rule__c errRec;
        if(trigger.isbefore && (trigger.isUpdate || trigger.isInsert) ){
           	system.debug('checkDuplicates called new map'+trigger.new);
         	SoqlStructure soqlStruct = new SoqlStructure();
         	Set<String> btrFields;
            for( sobject rec:trigger.new ){
                btrFields = new Set<String>();
                btrFields.addAll(soqlStruct.fieldsGrouped);
                system.debug('btrFields=='+btrFields);
                for(String pStringField: btrFields){ 
                  if(trigger.isInsert){
                    changed=true;
                    }
                    else{
                    	system.debug('pStringField='+pStringField + '==oldmap=='+trigger.oldmap);
                  	changed=  KSE.isFieldChanging(pStringField, rec, trigger.oldmap);
                }
                
                if(changed){
                        errRec= (Transaction_Matching_Rule__c)rec; 
                	break;
                }
            }
            }
            system.debug('checkDuplicates changed '+changed);
         	if(changed){
	            /*List<AggregateResult> countlst = Database.query(soqlStruct.soql); //running in system mode
	            if(countlst.size()>0){
	                system.debug(' Duplicate found!!');
	            	errRec.addError(Label.Duplicate_Bank_Transaction_Matching_Rule);
	            }*/
	            system.debug('Check Duplicates called' + errRec);
	            String error = validateBTRs(errRec);
                if (!String.isBlank(error)){
                    errRec.addError(error);
	            }
	      
	        }
        }
    }
    
    public static SoqlStructure createSoql(){
        SoqlStructure soqlStruct= new SoqlStructure();
        Transaction_Matching_Rule__c tmr = new Transaction_Matching_Rule__c();
        String retStr= '';
        Map<String, Schema.SobjectField> fields = tmr.getSObjectType().getDescribe().fields.getMap();
        for (String s : fields.keySet()) {
            if (fields.get(s).getDescribe().isCustom() && !(s.toLowerCase().contains('rank') || s.toLowerCase().equals('amount_threshold__c') || s.toLowerCase().equals('date_threshold__c')) 
               && fields.get(s).getDescribe().isGroupable()
               && !(fields.get(s).getDescribe().isCalculated())) {
               retStr= retStr + ','+ s ;
				soqlStruct.fieldsGrouped.add(s);
            }
        }
        retStr= 'select count(id) from  ' + tmr.getSObjectType().getDescribe().getName()+ ' group by ' + retstr.removeStart(',') + ' having count(id) >1 ';
        soqlStruct.soql=retStr;
        return soqlStruct;
    }
    //KNDY-15788 - fetch all BTMRs
    public static SoqlStructure createSoqlForValidation(){
        SoqlStructure soqlStruct= new SoqlStructure();
        Transaction_Matching_Rule__c tmr = new Transaction_Matching_Rule__c();
        String retStr= '';
        String fieldsToQuery = '';
        for (String s : soqlStruct.fieldsGrouped){
            fieldsToQuery += ',' + s;
        }
        retStr = 'Select Id,Name, Rank__c ' + fieldsToQuery + ' from ' + tmr.getSObjectType().getDescribe().getName();
        system.debug(LoggingLevel.Debug,'retStr validation=='+retStr);
        soqlStruct.soql=retStr;
        return soqlStruct;
    }
	
	
	//KNDY-15788 Check for duplicates among all existing BTRs
    public static String validateBTRs(Transaction_Matching_Rule__c newBTR){
         String error = '';
         SoqlStructure soqlStruct = createSoqlForValidation();
         system.debug('validateBTRs called ==' +soqlStruct);
         // query all BTRs
         List<Transaction_Matching_Rule__c> btrs = Database.query(soqlStruct.soql);//running in system mode
         system.debug(LoggingLevel.Error, '>>> query BTRs: ' + BTRs);
         Map<Id, BankTransactionRuleWrapper> btrWrapperMap = new Map<Id, BankTransactionRuleWrapper>();
         Map<Id, BankTransactionRuleWrapper> existingDuplicateBTRWrapperMap = new Map<Id, BankTransactionRuleWrapper>();
         		
         for (Transaction_Matching_Rule__c btr :btrs){
         	system.debug('btr=='+btr);
         	BankTransactionRuleWrapper btrWrapper = new BankTransactionRuleWrapper(btr);
         	system.debug('btrWrapper=='+btrWrapper +'=btrWrapperMap='+btrWrapperMap);
         	btrWrapperMap.put(btr.Id, btrWrapper);
         }
         system.debug(LoggingLevel.Debug, '>>> btrWrapperMap: ' + btrWrapperMap);

         BankTransactionRuleWrapper newBTRWrapper = new BankTransactionRuleWrapper(newBTR);
         
         // get existing BTRs for same grouping criteria
         String newBTRGroupingCriteria = newBTRWrapper.groupingCriteriaStr;
         for (BankTransactionRuleWrapper btrWrapper :btrWrapperMap.values()){
             if (btrWrapper.btrRecord.Id != newBTR.Id){
             	system.debug('btrWrapper.groupingCriteriaStr='+btrWrapper.groupingCriteriaStr + '=newBTRGroupingCriteria='+newBTRGroupingCriteria);
                if (btrWrapper.groupingCriteriaStr == newBTRGroupingCriteria){
                    existingDuplicateBTRWrapperMap.put(btrWrapper.btrRecord.Id, btrWrapper);
                    system.debug('newBTRWrapper.company='+newBTRWrapper.btrRecord.Company__c+'btrWrapper.btrRecord.Bank_Account__c='+btrWrapper.btrRecord.Company__c);
                    system.debug('newBTRWrapper.bank='+newBTRWrapper.btrRecord.Bank_Account__c+'btrWrapper.btrRecord.Bank_Account__c='+btrWrapper.btrRecord.Bank_Account__c);
					system.debug('newBTRWrapper.amountThreshHold='+newBTRWrapper.amountThreshHold+'btrWrapper.amountThreshHold='+btrWrapper.amountThreshHold);
					system.debug('newBTRWrapper.dateThreshHold='+newBTRWrapper.dateThreshHold +' btrWrapper.dateThreshHold= '+btrWrapper.dateThreshHold);
					system.debug('newBTRWrapper.btrRecord.Transacted_With__c='+newBTRWrapper.btrRecord.Transacted_With__c+'btrWrapper.btrRecord.Transacted_With__c='+btrWrapper.btrRecord.Transacted_With__c);
                    system.debug('newBTRWrapper.btrRecord.Reference__c='+newBTRWrapper.btrRecord.Reference__c+'=btrWrapper.btrRecord.Reference__c='+btrWrapper.btrRecord.Reference__c);
                    system.debug('newBTRWrapper.btrRecord.Keep_In_Match_Pool__c ='+newBTRWrapper.btrRecord.Keep_In_Match_Pool__c +'btrWrapper.btrRecord.Keep_In_Match_Pool__c='+btrWrapper.btrRecord.Keep_In_Match_Pool__c);
                    system.debug('newBTRWrapper.btrRecord.Auto_Approve__c='+newBTRWrapper.btrRecord.Auto_Approve__c+'btrWrapper.btrRecord.Auto_Approve__c='+btrWrapper.btrRecord.Auto_Approve__c);
                    
                    if (newBTRGroupingCriteria.contains('By Company') && ( newBTRWrapper.btrRecord.Company__c != null &&  btrWrapper.btrRecord.Company__c != null &&
                    newBTRWrapper.btrRecord.Company__c != btrWrapper.btrRecord.Company__c)){
                        system.debug(LoggingLevel.Error,'>>> by company BTR');
                        existingDuplicatebtrWrapperMap.remove(btrWrapper.btrRecord.Id);
                    }
                    else if (newBTRGroupingCriteria.contains('By Bank') && (newBTRWrapper.btrRecord.Bank_Account__c != null &&  btrWrapper.btrRecord.Bank_Account__c != null
                    && newBTRWrapper.btrRecord.Bank_Account__c != btrWrapper.btrRecord.Bank_Account__c)){
                        system.debug(LoggingLevel.Error,'>>> by bank BTR');
                        existingDuplicatebtrWrapperMap.remove(btrWrapper.btrRecord.Id);
                    }
                    else if (newBTRGroupingCriteria.contains('By Amount') && newBTRWrapper.amountThreshHold != btrWrapper.amountThreshHold){
                        system.debug(LoggingLevel.Error,'>>> by amount BTR');
                        existingDuplicatebtrWrapperMap.remove(btrWrapper.btrRecord.Id);
                    }

                    else if (newBTRGroupingCriteria.contains('By Date') && newBTRWrapper.dateThreshHold != btrWrapper.dateThreshHold){
                        system.debug(LoggingLevel.Error,'>>> by date BTR');
                        existingDuplicateBTRWrapperMap.remove(btrWrapper.btrRecord.Id);
                    }                                    
                }
             }
         }
         
         // KNDY-15788 validate dates
         if (existingDuplicateBTRWrapperMap.size() > 0){
            for (BankTransactionRuleWrapper btrWrapper : existingDuplicateBTRWrapperMap.values()){
                error = validateBTRDates(btrWrapper, newBTRWrapper);
                if (!String.isBlank(error)){
                    break;
                }
            }
         }
         return error;
    }
    //KNDY-15788 -date range validation
    public static String validateBTRDates(BankTransactionRuleWrapper existingBTRWrapper, 
                                          BankTransactionRuleWrapper newBTRWrapper){
        String error = '';
        DateTime existingBTREndDate = existingBTRWrapper.EndDate;
        DateTime existingBTRStartDate = existingBTRWrapper.StartDate;
        DateTime newBTRStartDate = newBTRWrapper.startDate;
        DateTime newBTREndDate = newBTRWrapper.endDate;
        system.debug(LoggingLevel.Error, '>>>newBTRStartDate BTR wrapper: ' + newBTRStartDate);
        system.debug(LoggingLevel.Error, '>>>newBTREndDate  BTR wrapper: ' + newBTREndDate);
        system.debug(LoggingLevel.Error, '>>>existingBTRStartDate: ' + existingBTRStartDate);
        system.debug(LoggingLevel.Error, '>>>existingBTREndDate: ' + existingBTREndDate);
        if (newBTREndDate == null){
            if (existingBTREndDate == null){
                return getErrorMessage(existingBTRWrapper);
            }
            else{//start date exists, end date not null
                error = checkDuplicateBTRDates(existingBTRWrapper,newBTRWrapper);
                if (!String.isBlank(error)){
                    return error;
                }
            }
         }
         else{//newBTREndDate is not null
            if (existingBTREndDate != null){
                error = checkDuplicateBTRDates(existingBTRWrapper,newBTRWrapper);
                if (!String.isBlank(error)){
                    return error;
                }
            }
            else{//existingBTREndDate is null
                if (newBTREndDate > existingBTRStartDate ){
                    return getErrorMessage(existingBTRWrapper);
                }
            }
         }
         return error;
    }
   //KNDY-15788 grouping criteria description   
    public static String getGroupingCriteriaDescription(Transaction_Matching_Rule__c groupingObj){
        String ruleText = '';
		ruleText +=  ', By Company' ;
		ruleText +=  ', By Bank';
        ruleText += (groupingObj.Amount__c) ? ', By Amount' : '';
        ruleText += (groupingObj.Transaction_Date__c) ? ', By Date' : '';
        ruleText += (groupingObj.Transacted_With__c) ? ', By Transacted With' : '';
        ruleText += (groupingObj.Reference__c) ? ', By Reference' : '';
        ruleText += (groupingObj.Keep_In_Match_Pool__c) ? ', By Match pool' : '';            
        ruleText += (groupingObj.Auto_Approve__c) ? ', By Auto Approval' : '';
        system.debug('ruleText='+ruleText);
        return ruleText;
    }
    //KNDY-15788 - date range checks
     private static String checkDuplicateBTRDates(BankTransactionRuleWrapper existingBTRWrapper,
                                                 BankTransactionRuleWrapper newBTRWrapper) {
        String error = '';
        DateTime newBTRStartDate = newBTRWrapper.startDate;
        DateTime newBTREndDate = newBTRWrapper.endDate;
        DateTime existingBTRStartDate = existingBTRWrapper.StartDate;
        DateTime existingBTREndDate = existingBTRWrapper.EndDate;
        system.assert(existingBTREndDate != null);
        
        if(newBTREndDate == null){
            if(newBTRStartDate < existingBTREndDate){
                return getErrorMessage(existingBTRWrapper);
            }
        }
        //start and end dates overlap with another BTR
        if (newBTRStartDate >= existingBTRStartDate && newBTREndDate <= existingBTREndDate){
            return getErrorMessage(existingBTRWrapper);
        }
        //  start date or end date period is between a period not covered by other other BTRs
        // btr1 ------          btr2---------
        // newbtr     ----------
        if (newBTRStartDate >= existingBTREndDate || newBTREndDate <= existingBTRStartDate){
            //valid dates
        }
        else{
            return getErrorMessage(existingBTRWrapper);
        }
        return error;
    }
    private static String getErrorMessage(BankTransactionRuleWrapper existingBTRWrapper){
       String hyperlink = '<a href="/'+ existingBTRWrapper.btrId + '">' + existingBTRWrapper.btrRecord.Name + '</a>';
       String error = Label.Change_dates_on_IGR  + hyperlink ; 
       return error;
    }
    public static void populateThresholdValues(){
        if(trigger.isBefore && (trigger.IsInsert || trigger.isUpdate)) {
			
			for(Transaction_Matching_Rule__c tmr : (List<Transaction_Matching_Rule__c>)trigger.new) {
					tmr.For_Amount_Threshold__c  = String.valueOf(tmr.Amount_Threshold__c);
					tmr.For_Date_Threshold_Days__c   = String.valueOf(tmr.Date_Threshold__c);
			}
            
		}
    }

	 //KNDY-15794
    public static void restrictUpdationAndDeletionOfBTMR(){
    	if(trigger.isBefore && trigger.isUpdate && !requestFromUI){
			restrictUpdationAndDeletionOfBTMR((list<Transaction_Matching_Rule__c>)trigger.new);
    	}else if(trigger.isBefore && trigger.isDelete){
    		restrictUpdationAndDeletionOfBTMR((list<Transaction_Matching_Rule__c>)trigger.old);
    	}
    }
    
    public static void restrictUpdationAndDeletionOfBTMR(list<Transaction_Matching_Rule__c> lstBTMR){
    	if(!lstBTMR.isEmpty()){
			for(Transaction_Matching_Rule__c igr : lstBTMR){
				igr.addError(Label.Can_t_update_delete_BTMR);
			}
     	}
     }
}