public with sharing class BankTransactionMatchExt extends GridRelatedListController{
     private ApexPages.StandardController controller;
    public string namespace{get;set; }
    public Integer BTMChunkSize{get; private set;}
    public string rulesListJson{get;set;}
  
    public Bank_Transaction_Match__c btm;
    public string categoryToStt {get {return JSON.serialize(BT_Category_to_Journal_Entry_STT__c.getAll());}
                                                                          }
     public GridRelatedListController.GridRelatedListConfig bankTransactionGridConfig {get; set;}
     public GridRelatedListController.GridRelatedListConfig matchedChildRecordGridConfig {get; set;}
     public GridRelatedListController.GridRelatedListConfig searchedResultGridConfig {get; set;}
     //public static list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntry{get;set;}
     //public static list<BankTransactionMatchService.MatchingWrapper> lstSearchedReceiptSupplierPaymentJournalEntry{get;set;}
	Public static DateTime StDateTime{get;set;} 
	public boolean loadScreen {get;set;}
    public static string company{get;set;}
  //Bank Recon Summary Page
    public static Bank_account__c bankAccount{get;Set;}
    
    public Bank_Transaction__c getLastTransaction (Id BankAccountid){
      return  [select id,Reconciled_As_Of_Date__c from Bank_Transaction__c where Bank_Account__c = :BankAccountid and Reconciled_Hidden__c =true order by Reconciled_As_Of_Date__c desc limit 1 ];
    }
    public static Bank_account__c getBankAccount(String bid){
        Bank_account__c bankAcct = [select id,GL_Account__c,Company__c,Opening_Balance__c,Opening_Balance_date__c, Active__c from bank_account__c where id= :bid];
        if(bankAcct!=null ){
            if( bankAcct.Opening_Balance_date__c !=null)
            bankAcct.Opening_Balance_date__c = Datetime.newInstance(bankAcct.Opening_Balance_date__c.date(),Time.newInstance(0,0,0,0)).addDays(1);
        }
        return bankAcct;
    }
    
     public string bankTranSummarySelectQry{get{
        return getSelectQuery(BankReconciliationService.getBankTransactionsFields(),'Bank_Transaction__c'); }}
     public string baseFilterReconciledTransactions{get{
        Datetime dtm=StDateTime==null ?DateTime.now():stDateTime;
        return BankReconciliationService.getAllBankTransactionsWhereClause( dtm ,  bankAccount.id,  company,bankAccount.opening_balance_date__c==null?system.now():bankAccount.opening_balance_date__c );
     }}
    
  
    
     public string bankTransactionFieldList;
     public string matchedRecordFieldList;
     public string searchResultRecordFieldList;
     public String getReturnUrl(){
		PageReference pageRef;
        pageRef = new PageReference('/' + controller.getRecord().Id);    
        
        
        return pageRef.getUrl();	
	}
    public Date stdate{get;set;}
     public BankTransactionMatchExt(ApexPages.StandardController c) {
       namespace=KSE.Namespace;
         
         // get btm Chunk Size
         Map<String,Configuration__c> configs = Configuration__c.getall();
         for (Configuration__c config : configs.values()){
             if (config.Name == 'BTMChunkSize'){
                 if (config.Value__c != null){
                     BTMChunkSize = Integer.ValueOf(config.Value__c);
                     break;
                 }
             }
         }


        // c.addFields(new List<String> {'GL_Account__c'});
 		controller = c;
 		loadScreen = true;
         if(c.getRecord().id!=null){
            bankAccount = getBankAccount(c.getRecord().id);
               
         }
       
         try{
         Bank_Transaction__c Lastbt =getLastTransaction(c.getrecord().id) ;
                 stDate =Date.valueof(Lastbt.Reconciled_As_Of_Date__c);
        
         }
         catch(QueryException qe){// if no record found then use op bal date
             stDate = Date.valueof(bankAccount.Opening_Balance_Date__c);
             //stDate = bankAccount.Opening_Balance_Date__c.date();
         }
         system.debug('stDate=='+stDate );
       rulesListJson = JSON.serialize(getMatchingRules(bankAccount.id,bankAccount.company__c).records); 
         if(bankAccount != null && !bankAccount.Active__c){
         	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.Label.Inactive_Bank_Account));
    		loadScreen =false;
         }
         if(bankAccount != null && (bankAccount.Opening_Balance__c == null || bankAccount.Opening_Balance_date__c == null)) {
         	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter the opening balance and date before managing transactions.'));
         	loadScreen =false;
         }
         if(!loadScreen)
    		return; 
        // Bank Transaction Config Grid
         bankTransactionGridConfig = new GridRelatedListController.GridRelatedListConfig();
        bankTransactionGridConfig.uniqueId = 'bankTransactionGrid';
        bankTransactionGridConfig.title = 'Bank Transaction';
        bankTransactionGridConfig.objectName = 'Bank_Transaction__c'; 
        bankTransactionGridConfig.fieldset = 'Match_Bank_Transactions_Columns';
        bankTransactionGridConfig.alwaysUseFullDateTimeFormat = true;
        
        //matched child record of Supplier payment, customer receipt, journal receipt line for related bank transaction
        matchedChildRecordGridConfig = new GridRelatedListController.GridRelatedListConfig();
        matchedChildRecordGridConfig.uniqueId = 'matchedChildRecordGrid';
        matchedChildRecordGridConfig.title = '';
        matchedChildRecordGridConfig.objectName = ''; 
        matchedChildRecordGridConfig.fieldset = '';
        matchedChildRecordGridConfig.alwaysUseFullDateTimeFormat = true;
        
        //searched result grid open in the popup
        searchedResultGridConfig = new GridRelatedListController.GridRelatedListConfig();
        searchedResultGridConfig.uniqueId = 'searchedResultRecordGrid';
        searchedResultGridConfig.title = '';
        searchedResultGridConfig.objectName = ''; 
        searchedResultGridConfig.fieldset = '';
        searchedResultGridConfig.alwaysUseFullDateTimeFormat = true;
        
     }  
     public string getbankTransactionGridConfigJson() {
        string bankTransactionConfigString = JSON.serialize(bankTransactionGridConfig);
        return bankTransactionConfigString;
     }  
   
 public String getSelectQuery(List<String> ListFields, String ObjName ){
        String qry='';
        for(String s:ListFields){
            if(String.isNotBlank(qry)){
                qry=','+ qry ;
            }
            qry=s+ qry;
        }
        system.debug('query : ' + qry);
        
    system.debug('glAccountId' + bankAccount.GL_Account__c);
        return 'SELECT '+ qry +' FROM '+ ObjName + ' ' ;
    }
    
     public String getbankTransactionFieldList() {
        if (String.isBlank(bankTransactionFieldList) && bankTransactionGridConfig != null) {                
            // get the Bank Transaction field set information.
            list<FieldInfo> lstfieldInfo = FieldInfo.fetchJsonFieldInfos(bankTransactionGridConfig.objectName, bankTransactionGridConfig.fieldset);
            Set<String> hiddenFields = new Set<String> {'Id'};
            
            for(Integer counter = 0; counter < lstfieldInfo.size(); counter++){
                String fieldtitle = lstfieldInfo[counter].title;
                String fieldName = lstfieldInfo[counter].field;
                lstfieldInfo[counter].title = fieldtitle == 'Finalized'?'Approved':fieldtitle;
                lstfieldInfo[counter].field = 'bankTransaction.' + fieldName;
                lstfieldInfo[counter].editable = false;
                lstfieldInfo[counter].hidden = hiddenFields.contains(fieldName);   
                
                if(lstfieldInfo[counter].field =='bankTransaction.Name'){
                  lstfieldInfo[counter].referenceTo = 'bankTransaction.Id';
                  lstfieldInfo[counter].fieldtype ='Name';
             }
                lstfieldInfo[counter].filterable = true;    
                
            }           
            bankTransactionFieldList = JSON.serialize(lstfieldInfo);
        }       
        return bankTransactionFieldList;
    }
  
    @RemoteAction
    public static JsonResult getBankTransactionAndMatches(date startDate, date endDate, id bankAccountId){
    	list<BankTransactionMatchService.transactionWithMatchesWrapper> lstTransactionWithMatchesWrapper = 
    	new list<BankTransactionMatchService.transactionWithMatchesWrapper>();
        Bank_account__c  bankAcct =getBankAccount(bankAccountId);
    	dateTime startDateTime = dateTime.newInstance(startDate,time.newInstance(0,0,0,0));
        StDateTime = startDateTime;//Begining Balance
    	dateTime endDT = dateTime.newInstance(endDate.addDays(1),time.newInstance(0,0,0,0));//KNDY-15576 
    	system.debug('startDateTime=='+startDateTime + ' endDT=='+endDT);
    	lstTransactionWithMatchesWrapper.addAll(BankTransactionMatchService.getBankTransactionsAndMatches(startDateTime,endDT,bankAccountId ,bankAcct.opening_balance_date__c)); 
        JsonResult result = new JsonResult();
        result.records = lstTransactionWithMatchesWrapper;
        result.total = lstTransactionWithMatchesWrapper.size();
        if(lstTransactionWithMatchesWrapper.size() == 0){
        	result.message = System.Label.No_BTs_Found;
        }else{
        	if(result.total == 10000){
                result.message = System.Label.Too_Many_Records;
            }
            if(Test.isRunningTest()){
                if(result.total == 2003){
                    result.message = System.Label.Too_Many_Records;
                }
            }
        }
        return result;   
    }
    
     @RemoteAction @readonly
    public static JsonResult getAllBankTransactions( id bankAccountId){
   list<BankTransactionMatchService.transactionWithMatchesWrapper> lstTransactionWithMatchesWrapper = 
    	new list<BankTransactionMatchService.transactionWithMatchesWrapper>();
         Bank_account__c  bankAcct =getBankAccount(bankAccountId);
         lstTransactionWithMatchesWrapper.addAll(BankTransactionMatchService.getAllBankTransactions(bankAccountId,bankAcct.Opening_Balance_Date__c)); 
        JsonResult result = new JsonResult();
        result.records = lstTransactionWithMatchesWrapper;
        result.total = lstTransactionWithMatchesWrapper.size();
        if(lstTransactionWithMatchesWrapper.size() == 0){
        	result.message = System.Label.No_BTs_Found;
        }
        return result;   
    }
   
    
    @remoteAction
    public Static JSONResult getMatchingRules(String bankId, String CompanyId){
        string bid= bankId;
        string cId = companyId;
        JsonResult jr = new JsonResult();
        Soqlutil soql = new Soqlutil('Transaction_Matching_Rule__c');
        soql.addFields('MatchingRuleQuery');
        soql.setWhereClause('(Bank_Account__c =:bid or bank_Account__c =null ) and (company__c =:cid or Company__c=null) and Is_Active__c = true');

        soql.setOrderByClause('rank__c asc');
        jr.records =Database.query(soql.getQuery());
        jr.success=true;
        return jr;
    }
    
    public string getmatchedChildRecordGridConfigJson() {
        string matchedChildRecordConfigString = JSON.serialize(matchedChildRecordGridConfig);
        return matchedChildRecordConfigString;
    }
    
    public FieldInfo addFields(string field, string title, string fieldType, boolean isEditable, boolean isHidden,boolean isFilterable,
    							boolean isSortable){
        FieldInfo fieldInfoItem = new FieldInfo();
        fieldInfoItem.field = field;
        fieldInfoItem.title = title;
        fieldInfoItem.fieldtype = fieldType;
        fieldInfoItem.editable = isEditable;
        fieldInfoItem.hidden = isHidden; 
        fieldInfoItem.filterable = isFilterable;
        fieldInfoItem.sortable = isSortable;
        return fieldInfoItem;
    }
    
    public String getmatchedRecordFieldList() {
          list<FieldInfo> lstfieldInfo = new list<FieldInfo>();
         list<FieldInfo> lstfieldInforet = new list<FieldInfo>();
        if (String.isBlank(matchedRecordFieldList) && matchedChildRecordGridConfig != null) {               
          
            FieldInfo fieldInfoAmount = new FieldInfo();
            // Add column to the field info list.       
            lstfieldInfo.add(addFields('recordId','Record Id','id',false,true,false,false));
            lstfieldInfo.add(addFields('recordName','Name','string',false,false,false,false));
            lstfieldInfo.add(addFields('transactionDate','Transaction Date','datetime',false,false,false,false));
            lstfieldInfo.add(addFields('referenceNumber','Reference Number','string',false,false,false,false));
            lstfieldInfo.add(addFields('transactedWithName','Transacted With','string',false,false,false,false));
            fieldInfoAmount = addFields('amountMatched',Label.Amount,'decimal',false,false,false,false);
            fieldInfoAmount.scale = 2;
            lstfieldInfo.add(fieldInfoAmount);
            lstfieldInfo.add(addFields('bankTransactionMatchId','Id','text',false,true,false,false));
            lstfieldInfo.add(addFields('description','Description','string',false,false,false,false));            
            lstfieldInfo.add(addFields('transactedWithId','Transacted With Id','Id',false,true,false,false));
            lstfieldInfo.add(addFields('aliases','aliases','text',false,true,false,false));
            lstfieldInfo.add(addFields('IsPotentialMatch','Potential Match','text',false,true,false,false));
            lstfieldInfo.add(addFields('ruleRecordId','Rule Id','id',false,true,false,false));
            lstfieldInfo.add(addFields('ruleRecordName','Rule','string',false,false,false,false));
            lstfieldInfo.add(addFields('KeepInMatchPool','Keep In Match Pool','text',false,true,false,false));
        }       
        for(Fieldinfo lf : lstfieldInfo){
          if(lf.field =='recordName'){
                  lf.referenceTo = 'recordId';
                  lf.fieldtype ='Name';
           }
           if(lf.field =='ruleRecordName'){
                  lf.referenceTo = 'ruleRecordId';
                  lf.fieldtype ='Name';
           }
            lstfieldInforet.add(lf);
        }
        
          matchedRecordFieldList = JSON.serialize(lstfieldInforet);
        return matchedRecordFieldList;
    }
/*    This code is not required
    @RemoteAction
    public static JsonResult getMatchedTransactions(Id bankTransactionId){
        JsonResult result = new JsonResult();
        if(bankTransactionId != null){ 
	        list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntry = new list<BankTransactionMatchService.MatchingWrapper>();
	        lstmatchedReceiptSupplierPaymentJournalEntry.addAll(BankTransactionMatchService.getMatchingTransactions(bankTransactionId));
	        result.records = lstmatchedReceiptSupplierPaymentJournalEntry;
	        result.total = lstmatchedReceiptSupplierPaymentJournalEntry.size();
	        result.success = true;
        }
        return result;   
    }
 */   
    public string getsearchedResultGridConfigJson() {
        string searchedResultConfigString = JSON.serialize(searchedResultGridConfig);
        return searchedResultConfigString;
    }
    
    public String getSearchResultRecordFieldList() {
        if (String.isBlank(searchResultRecordFieldList) && searchedResultGridConfig != null) {               
            list<FieldInfo> lstfieldInfo = new list<FieldInfo>();
            FieldInfo fieldInfoAmount = new FieldInfo();
            FieldInfo fieldRecordName = new FieldInfo();
            // Add column to the field info list.      
            lstfieldInfo.add(addFields('recordId','Record Id','id',false,true,false,false));
            
            fieldRecordName = addFields('recordName','Record Name','Name',false,false,true,true);
            fieldRecordName.referenceTo = 'recordId';
            lstfieldInfo.add(fieldRecordName);
            
            lstfieldInfo.add(addFields('transactionDate','Transaction Date','datetime',false,false,true,true));
            lstfieldInfo.add(addFields('referenceNumber','Reference Number','string',false,false,true,true));
            lstfieldInfo.add(addFields('transactedWithName','Transacted With','string',false,false,true,true));
            fieldInfoAmount = addFields('amountMatched',Label.Amount,'decimal',false,false,true,true);
            fieldInfoAmount.scale = 2;
            lstfieldInfo.add(fieldInfoAmount);
            lstfieldInfo.add(addFields('description','Description','string',false,false,true,true));
			lstfieldInfo.add(addFields('depositId', 'Deposit Identifier','string',false,false,true,true));
			searchResultRecordFieldList = JSON.serialize(lstfieldInfo);
        }       
        return searchResultRecordFieldList;
    }
                                                                                  
    @RemoteAction
    public static JsonResult getMatchingTransactions(Date startDate, Date endDate, Id bankAccountId,  
													 String referenceNumber, Double startAmountMatched, 
													 Double EndAmountMatched, String transactedWithName, String depositId,
													 list<string> lstsObjectTypes, ID bankTransactionID,boolean ignoreAmountRange,
																 boolean isDateUpdated, boolean isAmtUpdated){
			    system.debug('***in getMatchingTransactions*** '+startDate+':'+endDate+':'+bankAccountId+':'+
					    			referenceNumber+':'+startAmountMatched+':'+EndAmountMatched+':'+transactedWithName+':'+
					    			lstsObjectTypes+':'+':'+bankTransactionID+':'+ignoreAmountRange+':'+':'+isDateUpdated+':'+isAmtUpdated);
	    system.debug('bankTransactionID '+bankTransactionID);

    	JsonResult result = new JsonResult();
    	list<BankTransactionMatchService.MatchingWrapper> lstSearchedReceiptSupplierPaymentJournalEntry = new list<BankTransactionMatchService.MatchingWrapper>();
    	set<String> sObjectTypes = new set<String>();
    	sObjectTypes.addAll(lstsObjectTypes);
    	dateTime startDateTime = dateTime.newInstance(startDate,time.newInstance(0,0,0,0));

		dateTime endDateTime = dateTime.newInstance(endDate.addDays(1),time.newInstance(0,0,0,0));
		system.debug('startDateTime=='+startDateTime + 'endDateTime=='+endDateTime);
		if(!isDateUpdated){
			startDateTime = null;
			endDateTime = null;
		}
		if(!isAmtUpdated){
			startAmountMatched = null;
			EndAmountMatched = null;
		}
		system.debug(LoggingLevel.Error,'startDateTime '+startDateTime);
		system.debug(LoggingLevel.Error,'endDateTime '+endDateTime);
		system.debug(LoggingLevel.Error,'startAmountMatched '+startAmountMatched);
		system.debug(LoggingLevel.Error,'EndAmountMatched '+EndAmountMatched);
		system.debug(LoggingLevel.Error,'transactedWithName '+transactedWithName);
		system.debug(LoggingLevel.Error,'referenceNumber '+referenceNumber);
		system.debug(LoggingLevel.Error,'depositId '+depositId);
    	lstSearchedReceiptSupplierPaymentJournalEntry.addAll(BankTransactionMatchService.filterSearchRecordForFindLookup(bankTransactionID,BankTransactionMatchService.getMatchingTransactions(startDateTime, endDateTime, bankAccountId, referenceNumber, startAmountMatched,EndAmountMatched, transactedWithName, depositId, sObjectTypes, bankAccountId,ignoreAmountRange)));//
		result.records = lstSearchedReceiptSupplierPaymentJournalEntry;
		result.total = lstSearchedReceiptSupplierPaymentJournalEntry.size();
        system.debug('***out getMatchingTransactions*** '+lstSearchedReceiptSupplierPaymentJournalEntry);
	return result;
}
      
     @readonly
     @RemoteAction 
    public static JsonResult getMatchingTransactionsforAutoMatch( Id bankAccountId, 
													 String sObjectType){
    	JsonResult result = new JsonResult();
    	list<BankTransactionMatchService.MatchingWrapper> lstSearchedReceiptSupplierPaymentJournalEntry = new list<BankTransactionMatchService.MatchingWrapper>();
    	lstSearchedReceiptSupplierPaymentJournalEntry.addAll(BankTransactionMatchService.getMatchingTransactionsforAutoMatch(system.now(), system.now(), bankAccountId, '', 0,
    														0, '' , sObjectType,  bankAccountId,true));
    	result.records = lstSearchedReceiptSupplierPaymentJournalEntry;
        result.total = lstSearchedReceiptSupplierPaymentJournalEntry.size();
        return result; 
    }
    
    @RemoteAction
    public static JsonResult save(list<BankTransactionMatchService.MatchingWrapper> 
    							  lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords,
                                  Bank_Transaction__c bankTransaction){
        JsonResult result = new JsonResult();
        if(!lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords.isEmpty()){
            list<sObject> lstSobject = new list<sObject>();
            try{
            	lstSobject = BankTransactionService.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords,
            											 bankTransaction);
				result.success = true;
                result.records = lstSobject;    
                result.total = lstSobject.size();         
            }catch(exception ex){
            	string errorMessage = ex.getMessage();
         		integer location;
        		if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                	location = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
                	errorMessage = errorMessage.mid(location, errorMessage.length());
                	location = errorMessage.lastIndexOf(':');
                	errorMessage = errorMessage.mid(0, location);
        	    } else {
                	errorMessage = ex.getMessage();
                }
        		result.success  = false;
        		result.addMessage(errorMessage, ApexPages.Severity.ERROR);
        	}
        }
        return result;   
    }  
    @remoteAction
    public static JsonResult saveAutoMatches(List<Bank_Transaction_Match__c> btms){
      	List<Bank_Transaction_Match__c> successBTMs = new List<Bank_Transaction_Match__c>();
    JsonResult jr = new JsonResult();
	List<Database.SaveResult> srList = DML.insertAsSystem(btms,false) ;
		system.debug('btms='+ btms);
		//get only successful btm records
		for (Bank_Transaction_Match__c btmRec :btms){
			if (btmRec.id != null)
				successBTMs.add(btmRec);
		}
		if (successBTMs.isEmpty()){
			jr.success = false;
		}else if (!successBTMs.isEmpty() && successBTMs.size() >=0){
			jr.success = true;
			jr.records = successBTMs;
		}
		system.debug('successBTMs='+ successBTMs);
		// Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                
            }
            else {
                // Operation failed, so get all errors  
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    if (err.getStatusCode() != null && !String.valueOf(err.getStatusCode()).contains('DUPLICATE_VALUE')){
                    jr.addMessage(err.getStatusCode() + ': ' + err.getMessage() + ' : ' + err.getFields(),ApexPages.Severity.ERROR);
                    }
                    System.debug(' fields that affected this error: ' + err.getFields());
                }
            }
        }
        if (jr.success == false && jr.messages.isEmpty()){
        	jr.addMessage(Label.No_Match_Results_Are_Found,ApexPages.Severity.Info);
        }
        return jr;
    }
    
    @remoteAction
    public static JsonResult deletepotentialMatches(List<Bank_Transaction_Match__c> btms){
      
    JsonResult jr = new JsonResult();
	List<Database.DeleteResult> srList = DML.deleteAsSystem(btms) ;
		// Iterate through each returned result
        for (Database.DeleteResult sr : srList) {
            if (sr.isSuccess()) {
                jr.success=true;
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully deleted ID: ' + sr.getId());
                jr.records = btms;
            }
            else {
                // Operation failed, so get all errors  
                jr.success=false;              
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    jr.addMessage(err.getStatusCode() + ': ' + err.getMessage() + ' : ' + err.getFields(),ApexPages.Severity.ERROR);
                    System.debug(' fields that affected this error: ' + err.getFields());
                }
            }
        }
        return jr;
    }
    
    @remoteAction @readonly
    public static JsonResult getDeletionList(List<String> bts,List<String> CRs,List<String> SPs,List<String> PMTs ,List<String> JELs){
         List<String> btsList =bts;
         List<String> crsList =crs;
         List<String> spsList =sps;
         List<String> pmtsList =pmts; 
         List<String> jelsList =jels;
    JsonResult jr = new JsonResult();
            SOQLUtil soql = new SOQLUtil('Bank_Transaction_Match__c', false); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{'id'});
			soql.setWhereClause('(Bank_Transaction__c in :btsList or customer_Receipt__c in :CRsList or Supplier_Payment__c in :SPsList or Journal_Entry_Line__c in :JELsList or Payment__c in :PMTsList) And Is_Potential_match__c =true');
			List<Bank_Transaction_MAtch__c>  btms = Database.query(soql.getQuery());
     	    jr.success=true;
            jr.records =btms;
            return jr;
    }
    
    @RemoteAction
    public static JsonResult approvedMatchedBankTransaction(list<Id> lstBankTransactionId){
    	JsonResult result = new JsonResult();
        if(!lstBankTransactionId.isEmpty()){
        	list<Bank_Transaction__c> lstBankTransaction = new list<Bank_Transaction__c>();
        	list<Bank_Transaction__c> lstBankTransactionTobeApproved = new list<Bank_Transaction__c>();
            map<id,Bank_Transaction__c> mapBankTransactions = new map<Id,Bank_Transaction__c>([Select Id, Amount__c, Match_Approved__c, (Select Id, Amount__c from Bank_Transaction_Match__r) from Bank_Transaction__c 
                                                                              where id in :lstBankTransactionId
   	                                                                          and Match_Approved__c = false]);
			if(!mapBankTransactions.isEmpty()){
				for(Bank_Transaction__c bankTransaction: mapBankTransactions.values()){
					if(!bankTransaction.Bank_Transaction_Match__r.isEmpty()){
						double bankTransactionAmount = bankTransaction.Amount__c;
						double sumBankTransMatchAmount = 0;
						for(Bank_Transaction_Match__c bankTransMatch: bankTransaction.Bank_Transaction_Match__r){
							sumBankTransMatchAmount = sumBankTransMatchAmount + bankTransMatch.Amount__c;
						}
						if(bankTransactionAmount == sumBankTransMatchAmount){
							lstBankTransactionTobeApproved.add(bankTransaction);
						}
					}
				}
	        	Savepoint sp = Database.setSavepoint();
	        	try{
	        		lstBankTransaction = BankTransactionService.approvedMatchedBankTransaction(lstBankTransactionTobeApproved);
	        		result.records = lstBankTransaction;
	            	result.total = lstBankTransaction.size();
	            	result.success  = true;           
	        	}catch(exception ex){
	        		Database.rollback(sp);
	        		string errorMessage = ex.getMessage();
	         		integer location;
	        		if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
	                	location = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
	                	errorMessage = errorMessage.mid(location, errorMessage.length());
	                	location = errorMessage.lastIndexOf(':');
	                	errorMessage = errorMessage.mid(0, location);
	        	    } else {
	                	errorMessage = ex.getMessage();
	                }
	        		result.success  = false;
	        		result.addMessage(errorMessage, ApexPages.Severity.ERROR);
	        	}   
        	}        
        }
        return result; 
    } 
    
    @RemoteAction
    public static JsonResult unMatchedBankTransaction(list<Id> lstBankTransactionMatchId){
    	JsonResult result = new JsonResult();
        if(!lstBankTransactionMatchId.isEmpty()){
        	list<Bank_Transaction_Match__c> lstBankTransactionMatch = new list<Bank_Transaction_Match__c>();
        	set<Id> setBankTransactionMatchId = new set<Id>();
        	setBankTransactionMatchId.addAll(lstBankTransactionMatchId);
        	Savepoint sp = Database.setSavepoint();
        	try{
        		lstBankTransactionMatch = BankTransactionMatchService.unMatchedBankTransaction(setBankTransactionMatchId);
        		result.records = lstBankTransactionMatch;
            	result.total = lstBankTransactionMatch.size();
            	result.success  = true;           
        	}catch(exception ex){
        		Database.rollback(sp);
         		string errorMessage = ex.getMessage();
         		integer location;
        		if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                	location = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
                	errorMessage = errorMessage.mid(location, errorMessage.length());
                	location = errorMessage.lastIndexOf(':');
                	errorMessage = errorMessage.mid(0, location);
        	    } else {
                	errorMessage = ex.getMessage();
                }
        		result.success  = false;
        		result.addMessage(errorMessage, ApexPages.Severity.ERROR);
        	}           
        }
        return result; 
    }  
    
    @RemoteAction
    public static JSONResult reconcileBankTransactions(list<String> lBTs, String reconcileDate, Id bankAccountId) {
    	system.debug('reconcileDate=='+reconcileDate);
    	Date dt =  Date.parse(reconcileDate);
    	DateTime reconcileDateTime = datetime.newInstance(dt.year(),dt.month(),dt.day(),0,0,0);
    	system.debug('reconcileDateTime=='+reconcileDateTime);
        JSONResult result = new JSONResult();
    	try {
    		BankReconciliationService.updateBankTransactionsAsReconciled(lBTS, reconcileDateTime, bankAccountId);
    		result.success = true;
    		result.addMessage('Successfully Reconciled!', ApexPages.Severity.CONFIRM);
    		
    	}catch(Exception ex) {
    		result.success = false;
    		result.addMessage(ex, ApexPages.Severity.ERROR);
    	}
    	
    	return result;
    } 
    
    @RemoteAction
    public static JSONResult getLatestReconciledDate(Id BankAccountId) {
    	JSONResult result = new JSONResult();
    	try {
    		DateTime reconciledDate = bankReconciliationService.getLastReconciledDate(BankAccountId);
    		result.success = true;
    		result.records  = new list<DateTime>{reconciledDate};
    	}catch(Exception ex) {
    		result.success = false;
    		result.addMessage(ex, ApexPages.Severity.ERROR);
    	}
    	return result;
    }
    
     @RemoteAction
    public static JSONResult getWhereClause( String beginingBalanceDate, string bankacctid, string comp) {
    	Datetime dt =  System.DateTime.newInstance(Date.parse(beginingBalanceDate), Time.newInstance(0,0,0,0));
     
        JSONResult result = new JSONResult();
    	try {
    		result.success = true;
        
            result.records  = new List<Object>();
            Bank_Account__c bacct =getBankAccount(bankacctid);
                system.debug('getwhere clause ' + bankacctid + ' '+ comp + ' =' + dt );
            
              result.records.add(BankReconciliationService.getAllBankTransactionsWhereClause( dt ,  bankacctid,  comp, bacct.opening_balance_date__c));
    		
    	}catch(Exception ex) {
    		result.success = false;
    		result.addMessage(ex, ApexPages.Severity.ERROR);
    	}
    	
    	return result;
    } 
    
    @RemoteAction 
    public static JSONResult learnAlias(List<String> btmId){
        JSONResult jr= new JSONResult();
        list<BankTransactionMatchService.messageWrapper> lstMessageWrapper = BankTransactionMatchService.learnTransactedwith(btmId);
		// Iterate through each returned result
		if(lstMessageWrapper.isEmpty()){
			 jr.success=true;
		}else{
			 jr.success=false;
			 list<string> lstCompany = new list<string>();
			 list<string> lstSupplier = new list<string>();
			 list<string> lstCustomer = new list<string>();
			 list<string> lstOtherErrorCompany = new list<string>();
			 list<string> lstOtherErrorSupplier = new list<string>();
			 list<string> lstOtherErrorCustomer = new list<string>();
			 for(BankTransactionMatchService.messageWrapper message :lstMessageWrapper){
			 	if(message.errorCode.equalsIgnoreCase('STRING_TOO_LONG')){
			 		if(message.objectType.equalsIgnoreCase('Company'))
			 			lstCompany.add('<a href="/'+message.recordId+'">' + message.recordName + '</a>'); 
			 		else if(message.objectType.equalsIgnoreCase('Supplier'))
			 			lstSupplier.add('<a href="/'+message.recordId+'">' + message.recordName + '</a>');
			 		else if(message.objectType.equalsIgnoreCase('Customer'))
			 			lstCustomer.add('<a href="/'+message.recordId+'">' + message.recordName + '</a>');
			 	}else{
			 		if(message.objectType.equalsIgnoreCase('Company'))
			 			lstOtherErrorCompany.add('<a href="/'+message.recordId+'">' + message.recordName + '</a>' + ': ' + message.errorCode);
			 		else if(message.objectType.equalsIgnoreCase('Supplier'))
			 			lstOtherErrorSupplier.add('<a href="/'+message.recordId+'">' + message.recordName + '</a>' + ': ' + message.errorCode);
			 		else if(message.objectType.equalsIgnoreCase('Customer'))
			 			lstOtherErrorCustomer.add('<a href="/'+message.recordId+'">' + message.recordName + '</a>' + ': ' + message.errorCode);
			 	}
			 }
			 if(!lstCompany.isEmpty() || !lstSupplier.isEmpty() || !lstCustomer.isEmpty()){
				 string errorMsg = 'The Alias field for ';
				 if(!lstCompany.isEmpty()){
				 	errorMsg = errorMsg + 'Company ' + string.join(lstCompany,',') + ', ';
				 }
				 if(!lstSupplier.isEmpty()){
				 	errorMsg = errorMsg + 'Supplier ' + string.join(lstSupplier,',') + ', ';
				 }
				 if(!lstCustomer.isEmpty()){
				 	errorMsg = errorMsg + 'Customer ' + string.join(lstCustomer,',') + ' ';
				 }
				 errorMsg = errorMsg.removeEnd(',');
				 errorMsg = errorMsg + 'has no space for additional names. To make more space, you can change or delete data in this field that is less relevant for bank transaction matching.';
				 jr.addMessage(errorMsg, ApexPages.Severity.ERROR);
			 }else if(!lstOtherErrorCompany.isEmpty() || !lstOtherErrorSupplier.isEmpty() || !lstOtherErrorCustomer.isEmpty()){
			 	string errorMsg = 'Following error occured while updating ';
				 if(!lstOtherErrorCompany.isEmpty()){
				 	errorMsg = errorMsg + 'Company ' + string.join(lstOtherErrorCompany,',') + ', ';
				 }
				 if(!lstOtherErrorSupplier.isEmpty()){
				 	errorMsg = errorMsg + 'Supplier ' + string.join(lstOtherErrorSupplier,',') + ', ';
				 }
				 if(!lstOtherErrorCustomer.isEmpty()){
				 	errorMsg = errorMsg + 'Customer ' + string.join(lstOtherErrorCustomer,',') + ' ';
				 }
				 errorMsg = errorMsg.removeEnd(',');
				 jr.addMessage(errorMsg, ApexPages.Severity.ERROR);
			 }
			 
		}
         return jr;
    }
    
  /*  @RemoteAction
    public static JSONResult unlearnAlias(List<String> btmId){
          JSONResult jr= new JSONResult();
	List<Database.SaveResult> srlist=	BankTransactionMatchservice.unlearnTransactedWith(btmId);
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                jr.success=true;
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully updated entiry' + sr.getId());
                //jr.records = sr.getId();
            }
            else {
                // Operation failed, so get all errors  
                jr.success=false;              
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    jr.addMessage(err.getStatusCode() + ': ' + err.getMessage() + ' : ' + err.getFields(),ApexPages.Severity.ERROR);
                    System.debug(' fields that affected this error: ' + err.getFields());
                }
            }
        }
        return jr;
    }*/
    
     @RemoteAction
    public static JSONResult ConfirmMatchAndDeleteOthers(List<String> btmIds ) {
         List<String> btsList =new List<String>();
         List<String> crsList =new List<String>();
         List<String> spsList =new List<String>();
         List<String> pmtsList =new List<String>(); 
         List<String> jelsList =new List<String>();
         for(Bank_Transaction_Match__c btm:	BankTransactionMatchservice.confirmMatch(btmIds)){
            btsList.add(btm.bank_transaction__c);
            if( !String.isBlank(btm.customer_Receipt__c) ){
                    crsList.add(btm.customer_Receipt__c);
            }else if(!String.isBlank(btm.Supplier_Payment__c)){
                    spsList.add(btm.Supplier_Payment__c);
                  }else if(!String.isBlank(btm.Payment__c)){
                        pmtsList.add(btm.Payment__c);
                        }else if(!String.isBlank(btm.Journal_Entry_Line__c)){
                        jelsList.add(btm.Journal_Entry_Line__c);
                        }
           }
            
    List<Bank_Transaction_Match__c> btmListToDelete=(List<Bank_Transaction_Match__c>) getDeletionList(btsList,crsList,spsList,pmtsList ,jelsList).records;
    return deletepotentialMatches(btmListToDelete);
    }
        
     @RemoteAction
    public static JSONResult createJournalEntry(Journal_Entry__c je , list<Journal_Entry_Line__c> jelsList ) {
     JSONResult jr =new JSONResult(); 
     try{
       Database.insert(je);
        List<Journal_entry_Line__c> jelforAcct = new List<Journal_entry_Line__c>();
        for(Journal_Entry_Line__c jel :jelsList){
            jel.journal_entry__c=je.id;
            jel.transaction_Date__c = je.transaction_Date__c.Date();
        }
         Database.insert(jelsList);
         system.debug('jelsList@@@@* inserted ' + jelsList[0].Id );
         // had to serialize and deserialize because of the un clear error message received with directly using the list and generating accounting.
         jelsList  = (List<Journal_entry_Line__c>) JSON.deserialize( Json.serialize(jelsList) , List<Journal_entry_Line__c>.class);
         je.finalized__c=true;
         //je.finalized_date__c=datetime.now();
         Database.update(je);
         JournalEntryAccounting jea = new JournalEntryAccounting(); 
         jea.execute(jelsList);
        }catch(DMLException dmlex){
             jr.success=false;
             jr.addMessage(dmlex.getDmlMessage(0),ApexPages.Severity.ERROR);
        return jr;     
        }catch (Exception ex){
             jr.success=false;
             jr.addMessage(ex.getmessage(),ApexPages.Severity.ERROR);
               return jr;
             } 
		    Id jeid = je.id;
            SOQLUtil soql = new SOQLUtil('Journal_Entry__c', false); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','Name','Finalized_Date__c','Transaction_Date__c','Finalized__c'
            });
            soql.setWhereClause('id = :jeid');
            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
            childRel.addFields(new set<string>{'id','Name'});
			childRel.setWhereClause('status__c = \'Active\' and Has_Exceptions__c=false');
			soql.addChildRelationship(childRel);
            system.debug( '@@' + soql.getQuery() );

		    List<Journal_Entry__c> journalEntryList= Database.query(soql.getQuery());
                            String hyperlink = '<a href="/'+journalEntryList[0].Id+'">' + journalEntryList[0].Name + '</a>';
            
            if(!journalEntryList[0].Finalized__c)  {
               jr.success=false;
               jr.addMessage( hyperlink +': Journal Entry Created but could not be finalized , Please fix the record and match.'   ,ApexPages.Severity.Error);
            }else if(journalEntryList[0].Accounting_Entries__r.size()==0){
               jr.success=false;
               jr.addMessage( hyperlink +': Journal Entry Created but issues encountered while generating accounting, Please fix the record and match.'   ,ApexPages.Severity.Error);
            }else{
                List<Bank_Transaction_Match__c> btmlist= createBTMsForJE(jelsList);
                 Database.insert(btmlist);
                 jr.success =true;
                 jr.records=journalEntryList;  
                 jr.addMessage( journalEntryList[0].Name +': Journal Entry Created Successfully. '  ,ApexPages.Severity.CONFIRM);
            }
        return jr;
    }
    
    public static List<Bank_Transaction_Match__c> createBTMsForJE(list<Journal_Entry_Line__c> jelsList ) {
        List<Bank_Transaction_Match__c> btmlist = new List<Bank_Transaction_Match__c>();
        list<Journal_Entry_Line__c> lstJEL = new list<Journal_Entry_Line__c>();
        Soqlutil soql = new Soqlutil('Journal_Entry_Line__c');
        soql.addFields(new set<string>{'Id','Bank_Transaction__c','Bank_Transaction__r.Transaction_Date__c',
        								'Amount_DR__c','Amount_CR__c','Journal_Entry__r.Transaction_Date__c'});
        soql.setWhereClause('Id in:jelsList');

        lstJEL = Database.query(soql.getQuery());
        if(!lstJEL.isEmpty()){
	        for( Journal_Entry_Line__c jel : lstJEL ){
	            if(!String.IsBlank(jel.bank_Transaction__c)){
	            	Bank_Transaction_Match__c btm = (Bank_Transaction_Match__c) 
	             							     BankTransactionService.createBankTransactionMatching(
	             							     new Bank_Transaction__c(Id=jel.Bank_Transaction__c), 
	             							     'Journal_Entry_Line__c',
	             							     jel.Journal_Entry__r.Transaction_Date__c,
	             							     jel.Bank_Transaction__r.Transaction_Date__c,
	             							     jel.id,jel.Amount_DR__c +jel.Amount_CR__c);
	             	btmlist.add(btm);
	            }
	        }
        }
        return btmlist;
    }
    
    public String getJournalEntryLineFieldList() {
            list<FieldInfo> lstfieldInfo = new list<FieldInfo>();
            // Add column to the field info list. 
            lstfieldInfo.add(addFields(Label.Amount,Label.Amount,'decimal',false,false,true,true));//KNDY-16112
          
            lstfieldInfo.add(addFields('Amount_DR__c','Debit Amount','decimal',false,true,true,true));
            lstfieldInfo.add(addFields('Amount_CR__c','Credit Amount','decimal',false,true,true,true));
            FieldInfo fi=  FieldInfo.getfieldInfo(Journal_Entry_Line__c.Subtransaction_Type__c.getDescribe());
            fi.title = 'Subtransaction Type';
            fi.required=true;
            lstfieldInfo.add(fi);
            FieldInfo fdesc=addFields('Description__c','Description','string',true,false,true,true);
            fdesc.width =300;
            lstfieldInfo.add(fdesc); 
          FieldInfo Bt=  FieldInfo.getfieldInfo(Journal_Entry_Line__c.Bank_Transaction__c.getDescribe());
            Bt.hidden=true;
            Bt.referenceTo = 'Bank_Transaction__c';
            Bt.editable =false;
			lstfieldInfo.add(Bt);

        return JSON.serialize(lstfieldInfo);
    }
    
    public String getTransactionTypeDescribe() {
    	return JSON.serialize(Accounting_Rule__c.Transaction__c.getDescribe());
    }
    //KNDY-16543
    @RemoteAction
    public static JsonResult fetchSubTransactionTypes(dateTime transactionDate) {
    	List<Map<String,String>> STT = new List<Map<String,String>>();
    	Map<String,String> STTMap = new Map<String,String> ();
    	JsonResult result = new JsonResult();
    	List<Accounting_Rule__c>  accRuleList = AccountingRuleService.getEffectiveAccountingRulesByObjectAndTransaction ('Journal_Entry__c','Bank Transaction',new List<DateTime>{transactionDate});
    	system.debug('accRuleList='+accRuleList);
    	set<string> STTSet = new set<String>();
    	for (Accounting_Rule__c accRule :accRuleList){
    		STTSet.add(accRule.SubTransaction_Type__c);
    	}
    	if (STTSet.size() >0){
	    	for (string sttStr :STTSet){
	    		STTMap = new Map<String,String> ();
		    	STTMap.put('value', sttStr); 
		    	STTMap.put('text', sttStr);
		    	STT.add(STTMap);
	    	}
	    	
	    	
	        result.records = STT;
	        result.success = true;
    	}else if(STTSet.size() == 0){
           result.success=false;
           result.addMessage(Label.Can_not_Create_JE_Accounting_Rule_missing   ,ApexPages.Severity.Error);
        }

    	return result;    	
    }      
    public String getJournalEntryLinesConfigJson() {
            GridRelatedListConfig journalEntryLinesConfig;
             journalEntryLinesConfig = new GridRelatedListConfig();
	        journalEntryLinesConfig.uniqueId = 'GridAddManageJournalEntryLines';
	        journalEntryLinesConfig.objectName = 'Journal_Entry_Line__c';  
	        journalEntryLinesConfig.parentField = 'Journal_Entry__c';
	        journalEntryLinesConfig.fieldset = 'Journal_Entry_Line_Edit';
        String configStr = JSON.serialize(journalEntryLinesConfig);
        return configStr;
    }
}