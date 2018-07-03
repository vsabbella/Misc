public with sharing class JournalEntryLinesManageExt extends GridRelatedListController{
	public GridRelatedListConfig journalEntryLinesConfig {get; set;}
    public string journalEntryLineFieldList = null;
    public static SchemaUtil util = SchemaUtil.getInstance();
    public SchemaUtil su = SchemaUtil.getInstance();

    ApexPages.StandardController controller;
    public Journal_Entry__c journal {get; set;} //controller record
    public string JERecJSON {get; set;} //controller record
    public string ReturnUrl{set;}
    public string GenerateAccountingUrl{get;set;}        
    public string jeHeaderFields{set;}
    public string jeAddlHeaderFields{set;}
    public string pageTitle{get;set;}
     
    public Boolean pgError { get; set;}
    public JournalEntryService JES = JournalEntryService.getInstance();
    
    public List<Integer> selected_indexes {     
        get {
            String selected_indexes = Apexpages.currentPage().getParameters().get('selected_indexes');
            return ArrayUtils.getIntegerList( selected_indexes );
        }
    }

    public static String KNDO_PAGE_HEADER_ERROR_MSG { 
        get { 
            return 'One or more Journal Entry lines has errors.'; 
        } 
    }

    public static String KNDO_PAGE_HEADER_GENERAL_EXCEPTION_MSG { 
        get { 
            return Label.Unexpected_exception_message + Label.Contact_support_message; 
        } 
    }
               
    public JournalEntryLinesManageExt(ApexPages.StandardController sc){
        try{ 
            controller = sc;
            pgError = false;
            journal = (Journal_Entry__c) sc.getRecord();
            Id jeid = journal.Id;
            system.debug('Inside journal');
 
 			pageTitle = 'Journal Entry ' ;
            
            if(journal != null && journal.Id != null){
                  /* journal = [select Id, Name, Company__c,Company__r.name,Transaction_Date__c,Currency__c,Type__c,
                            Period__c, Period__r.Period_Start__c, Period__r.Period_End__c,
                            Period__r.Open__c, Period__r.Name, Status__c,Finalized__c                            
                            from Journal_Entry__c where id=:journal.Id limit 1];*/
                    
                    
                    String objectName = 'Journal_Entry__c';
                    set<String> queryFields = new set<String>();
                    Set<String> addlFields = new Set<String> { 'name','Company__c', 'Status__c','Finalized__c', 'Currency__c' };
                    
                    queryFields.addAll(addlFields);
                    queryFields.AddAll(su.getFieldsFromFieldSetString(objectName,'Journal_Entry_Header'));
                    queryFields.AddAll(su.getFieldsFromFieldSetString(objectName,'Journal_Entry_Additional_Info'));
				    
				    //String queryString = util.generateQueryFromFieldSet(objectName, new Set<string>{ headerFieldset, addlHeaderFieldset }, addlFields, whereClause);
					GenerateAccountingUrl= '/apex/JournalEntryAEPreview?id='+jeid;
					SOQLUtil soql = new SOQLUtil(objectName);
				    soql.addFields(queryFields);
				    soql.setWhereClause('id=:jeid limit 1');
				    system.debug('soql query:'+soql.getQuery());
				    journal = Database.query(soql.getQuery());
				    
			        pageTitle = 'Journal Entry ' +  ': ' + journal.Name;
				    
				    
					if (ApexPages.currentPage().getParameters().containsKey('clone') && 
			            ApexPages.currentPage().getParameters().get('clone') == '1'){ 
			            pageTitle = 'Clone of ' +  ': ' + journal.Name;			            	
				      	//journal.name = journal.name ;
				    	journal.Status__c = 'Open';  
				    	journal.Finalized__c = false;
			        }
			        
                }
            else{
		        CompanyService compServ = new CompanyService(controller);
		        journal = new Journal_Entry__c();
		        journal.Company__c = CompanyService.getDefaultCompanyId();
		        journal.Company__r = compServ.Company;
		        journal.Currency__r = CompanyService.defaultTransactionCurrencyRec(journal.Company__c);
		        if(journal.Currency__r != null)
		        	journal.Currency__c = CompanyService.defaultTransactionCurrencyRec(journal.Company__c).id;
		        journal.Transaction_Date__c=system.now();
		        journal.Type__c='Manual';
            }
           /* string q = util.generateQueryFromFieldSet( 'Journal_Entry__c',
                                              new set<string>{'Journal_Entry_Edit'}, 
                                              null)+ ' limit 10000';                */
            JERecJSON = JSON.Serialize(journal);
         
            journalEntryLinesConfig = new GridRelatedListConfig();
	        journalEntryLinesConfig.uniqueId = 'GridAddManageJournalEntryLines';
	        journalEntryLinesConfig.parentRecord = journal;
	        journalEntryLinesConfig.objectName = 'Journal_Entry_Line__c';  
	        journalEntryLinesConfig.parentField = 'Journal_Entry__c';
	        journalEntryLinesConfig.fieldset = 'Journal_Entry_Line_Edit';
	        if(journal.finalized__c==true){
	         journalEntryLinesConfig.buttons = 'search, columnmenu,';	        	
	        }
	        else{
	         journalEntryLinesConfig.buttons = 'create, delete, search, clone, columnmenu,';	        	
	        }
	        //journalEntryLinesConfig.additionalFields = 'Has_Exceptions__c';
            
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, e);
            ApexPages.addMessages(e);
        }
        
    }
    
    public String getReturnUrl(){
        PageReference pageRef;
        
        if (journal != null && journal.id != null ){
            pageRef =  new PageReference('/' + journal.Id);
        }
        else{
            Schema.DescribeSObjectResult dsr = Journal_Entry__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        }
        
        return pageRef.getUrl();
    }
	public String getJournalEntryLinesConfigJson() {
        String configStr = JSON.serialize(this.journalEntryLinesConfig);
          
        return configStr;
    }
    

   //Get the JE fields JSON
    public String getjeHeaderFields(){
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Journal_Entry__c', 'Journal_Entry_Header'); 
        List<FieldInfo> fieldInfoListForManualJE = FieldInfo.fetchJsonFieldInfos('Journal_Entry__c', 'Journal_Entry_Header'); 
        set<string> totalFields      = new set<string>{'Total_Debit__c','Total_Credit__c'}; 
        FieldInfo outOfBalanaceField  = new FieldInfo('Out_Of_Balance','Out of Balance By:','String');  
        set<string> fieldsLockedInHdr = new set<string>{'Status__c','Posting_Date__c'}; 
        
        //------For all JEs make Status__c','Posting_Date__c ready only && all finalized field set to read only
        for (Integer i = 0; i <fieldInfoList.size(); i++){
              if( fieldsLockedInHdr.contains(fieldInfoList[i].field)  == TRUE || journal.Finalized__c == TRUE ){ 
                  fieldInfoList[i].editable = false ;
              }
         }
         
        //------For all JEs make Status__c','Posting_Date__c ready only && all finalized field set to read only
        for (Integer i = 0; i <fieldInfoListForManualJE.size(); i++){
              if( fieldsLockedInHdr.contains(fieldInfoListForManualJE[i].field)  == TRUE || journal.Finalized__c == TRUE ){ 
                  fieldInfoListForManualJE[i].editable = false ;
              }
         }
       
        
         if( journal.Finalized__c == FALSE){// (journal.Type__c=='Manual' || journal.Type__c=='Accrual - Manual' ) &&){ 
           
            //-------First remove the Total CR and DR if the JE is not finalized and is  manual
            for (Integer i = 0; i <fieldInfoListForManualJE.size(); i++){ 
                //------Remove totals from fieldset---------------//
                if(totalFields.contains(fieldInfoListForManualJE[i].field)){
    	 	        fieldInfoListForManualJE.remove(i);
    	 	     }
            }
           
          fieldInfoListForManualJE.add(outOfBalanaceField); 
        } 
      
       
        //FieldInfo totalDR             = new FieldInfo('Running_Total_DR','Total DR','String',false);
        //FieldInfo totalCR             = new FieldInfo('Running_Total_CR','Total CR','String',false);
        //fieldInfoList.add(totalDR); 
        //fieldInfoList.add(totalCR);
     
         
  	  fieldInfoList.remove(0); // Remove Id field from the list  */
  	  fieldInfoListForManualJE.remove(0); // Remove Id field from the list  */
  	  if(journal.Finalized__c == FALSE ){
  	       return JSON.serialize(fieldInfoListForManualJE);  
  	  }else{
  	       return JSON.serialize(fieldInfoList);  
  	  }
          	
    }
    public String getjeAddlHeaderFields(){

        List<FieldInfo> AddlfieldInfoList = FieldInfo.fetchJsonFieldInfos('Journal_Entry__c', 'Journal_Entry_Additional_Info');
 	        for (Integer i = 0; i < AddlfieldInfoList.size(); i++){
	        	AddlfieldInfoList[i].editable = false;
	        }       
  		AddlfieldInfoList.remove(0); // Remove Id field from the list
        return JSON.serialize(AddlfieldInfoList);    	
    }
    //Get the JE Line fields JSON
    public string getJournalEntryLineFieldList() {
        if (journalEntryLineFieldList == null && journalEntryLinesConfig != null) {
            // get the JE lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(journalEntryLinesConfig.objectName, journalEntryLinesConfig.fieldset);
                    
            // set the wrapper class prefix
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                fieldInfoList[i].field = 'jeLine.' + fieldInfoList[i].field;                
            }
             //Add error column to the grid
            FieldInfo fi =new FieldInfo('errors', 'Errors', 'rowinfo');
            fieldInfoList.add(0,fi);
            fieldInfoList.add(new FieldInfo('rowGUID', 'Row ID', 'string', true));
            
            journalEntryLineFieldList = JSON.serialize(fieldInfoList);
        }
        system.debug(LoggingLevel.Info, 'FIELDS:' + journalEntryLineFieldList);
        return journalEntryLineFieldList;
    }
  
    //Get the Exception fields JSON
     public String getExceptionFieldList() {
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Task', new String[] {'Subject', 'Exception_Code__c', 'Description'});
        
        for (Integer i = 0; i < fieldInfoList.size(); i++){  
        	fieldInfoList[i].editable = false;
        }
        
        return JSON.serialize(fieldInfoList);
    }       
     
    @RemoteAction
    public static JsonResult getJournalEntryDetails(Id JEId,String clone) { 
        String objectName = 'Journal_Entry__c';
        Set<String> addlFields = new Set<String> { 'name','Company__c', 'Currency__c','Status__c','Finalized_Hidden__c','Finalized_Date__c','Finalized__c' };
        string whereClause = 'Id  = :JEId LIMIT 1';
        
        //String queryString = util.generateQueryFromFieldSet(objectName, new Set<string>{ headerFieldset, addlHeaderFieldset }, addlFields, whereClause);
        set<String> queryFields = new set<String>();
        queryFields.AddAll(util.getFieldsFromFieldSetString(objectName,'Journal_Entry_Header'));
        queryFields.AddAll(util.getFieldsFromFieldSetString(objectName,'Journal_Entry_Additional_Info'));
        queryFields.AddAll(addlFields);
	    
	    //String queryString = util.generateQueryFromFieldSet(objectName, new Set<string>{ headerFieldset, addlHeaderFieldset }, addlFields, whereClause);
		
		SOQLUtil soql = new SOQLUtil(objectName);
	    soql.addFields(queryFields);
	    soql.setWhereClause(whereClause);		

	    
        List<Journal_Entry__c> je = Database.query(soql.getQuery());
        if ( clone != null && clone == '1'){ 
            // Copy the JE        	
	      	Journal_Entry__c jeClone = je[0].Clone(false,true);
            // reset fields for clone.	      	
	      	jeClone.name=null;
        	jeClone.finalized__c = false;
        	jeClone.Status__c = 'Open';  
            jeClone.Finalized_Hidden__c = false;
            jeClone.Finalized_Date__c = null;  
            jeClone.period__r = null;
            jeClone.period__c = null;
            jeclone.posting_date__c=null;
            jeclone.void__c=false;  
            jeclone.void_date__c=null;
            jeclone.Auto_Reverse__c=false;
                      
            je.clear();
            je.add(jeClone);	
        }      
        return new JsonResult(je, je.size());
    }
       
    //Query JE Line data along with Exception task details and build the JELineWrapper.
    @RemoteAction 
    public static JsonResult getJournalEntryLines(GridRelatedListConfig config,String clone) {
        list<JournalEntryLineWrapper> result = new list<JournalEntryLineWrapper>();
        system.debug('config:'+config);
        Id parentId = (config.parentRecord != null && String.isNotBlank(config.parentRecord.Id)) ? config.parentRecord.Id : '';
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        set<string> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
        String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';
        
        string whereClause = parentfield + ' = :parentId';
        
        if(String.isNotBlank(config.sortField)){
            whereClause += ' ORDER BY ' + config.sortField;
            if(String.isNotBlank(config.sortOrder)){
                whereClause += ' ' + config.sortOrder;
            }
        }
        
        if (String.isNotBlank(config.namespace)) {
                util.namespace = config.namespace;
        }
        set<Id> jeLineIds = new set<Id>();
        //String queryString = util.generateQueryFromFieldSet(config.objectName, new Set<string>{ fieldset }, addlFields, whereClause);
        
        SOQLUtil soql = new SOQLUtil(config.objectName);
	    soql.addFields(fieldset);
	    //soql.addFields(addlFields);
	    soql.setWhereClause(whereClause);
	    soql.addField('gl_account__r.Active__c');
	    system.debug('soql:'+soql);
        List<Journal_Entry_Line__c> jeLinesList = Database.query(soql.getQuery());   
        if ( clone != null && clone == '1'){
            List<Journal_Entry_Line__c> clonedJELines = new List<Journal_Entry_Line__c>();
            for (Journal_Entry_Line__c jel : jeLinesList){
                // Copy the line
                Journal_Entry_Line__c cloneJEL = jel.clone(false,true);
                if(jel.gl_account__r.active__c != true){
                
                	cloneJEL.gl_account__c = null;
                	cloneJEL.gl_account__r = null;
                }
                clonedJELines.add(cloneJEL);
            }
            jeLinesList.clear();
            jeLinesList.addAll(clonedJELines);                
        }
        for (Integer i = 0; i< jeLinesList.size() ; i++) {
            jeLineIds.add(jeLinesList[i].id);
        }
        
        map<id,List<Task>> jeLineTask = getJournalEntryLineTaskDetails(jeLineIds);
        for (Integer i = 0; i< jeLinesList.size() ; i++) {
            result.add(new JournalEntryLineWrapper(jeLinesList[i], jeLineTask.get(jeLinesList[i].id)));
        }
        system.debug(Logginglevel.info, result);
        
        return new JsonResult(result, result.size());
    }
    
    public static Map<id, List<Task>> getJournalEntryLineTaskDetails(set<Id> jeLineIds){
    	Map <id, List<Task>> mJELineTask = new Map<id, List<Task>>();
    	List<Task> TaskList= [Select Id, createdDate, what.Name, Subject, ActivityDate, priority, Status, Exception_Code__c, Description, WhatId
                FROM Task 
    			where whatId in :jeLineIds
    			and whatId != null
    			and Type = 'Exception'];
    	for(Task thisTask: TaskList){
    		if(mJELineTask.containsKey(thisTask.whatId)){
    			List<Task> oldList = (List<Task>) mJELineTask.get(thisTask.whatId);
    			oldList.add(thisTask);
    			mJELineTask.put(thisTask.whatId,oldList);
    		}else{
    			List<Task> newList = new List<Task>();
    			newList.add(thisTask);
    			mJELineTask.put(thisTask.whatId, newList);
    		}
    	}		
    	return mJELineTask;
    }
    
    //Company change event
    @RemoteAction
    public static JsonResult getCompanyDetails(String companyId,String JEId) {
    	List<Company__c> companies = new List<Company__c>();
    	Journal_Entry__c JE = new Journal_Entry__c();
    	List<Journal_Entry_Line__c> JELs = new List<Journal_Entry_Line__c>();
        JsonResult Result;  	
    	//String queryString = 'SELECT Default_Transaction_Currency__c FROM Company__c WHERE Id =:companyId LIMIT 1';
	    Savepoint sp =Database.setSavepoint() ;			   
    	try{
	    	SOQLUtil soql = new SOQLUtil('Company__c');
		    soql.addFields(new Set<String>{'Default_Transaction_Currency__c'});
		    soql.setWhereClause('Id =:companyId');		    
	    	companies = Database.query(soql.getQuery()); 
	    	   		
	    	if(JEId !=null){
 			    
		     	SOQLUtil soql1 = new SOQLUtil('Journal_Entry__c');
			    soql1.addFields(new Set<String>{'Id','Name','Company__c'});
			    soql1.setWhereClause('id =:JeId'); 

		     	SOQLUtil soql2 = new SOQLUtil('Journal_Entry_Line__c');
			    soql2.addFields(new Set<String>{'Id','Name','Company__c'});
			    soql2.setWhereClause('Journal_Entry__c =:JeId');
			    			   
			    JE=	Database.query(soql1.getQuery());    	
		        JE.company__c=companyId;
		        JE.Currency__c=companies[0].Default_Transaction_Currency__c;
			    DML.checkUpsertAsUser(JE); upsert JE;
			    
	        	JELs = Database.query(soql2.getQuery());	        		       
		        if(JELs.size()>0){
		          for(Journal_Entry_Line__c JEL:JELs){
		          	JEL.Company__c=companyId;
		          }
		          DML.checkUpsertAsUser(JELs); upsert JELs;
		        }
			    	      		
	    	}

	    	Result =new JsonResult(companies, companies.size()) ;
    	    	
    	}
    	catch(Exception ex){
    		Database.rollback(sp);
    		Result =new JsonResult();
    		Result.success= false;
    		Result.message= ex.getMessage();
    	}
    	return Result;
    }
   //Save action on header.
      @RemoteAction    
     public static JsonResult saveAction(Journal_Entry__c je, List<String> headerDateFields,
                                        List<JournalEntryLineWrapper> updatedList, List<JournalEntryLineWrapper> newList, 
                                        List<JournalEntryLineWrapper> deletedList, List<string> dateFields) {
        KendoUtils.UpdateDateFields(je,headerDateFields);
        system.debug('inside save Action');
        system.debug('updatedList:'+updatedList);
        system.debug('newList:'+newList);
        system.debug('je:'+je);
        
        JsonResult result = new JsonResult();
        result.records = new list<object>();
        Savepoint sp = Database.setSavepoint();
        list<Journal_Entry__c> records = new list<Journal_Entry__c>();
        Journal_Entry__c Journal = new Journal_Entry__c();
        Journal.Finalized__c = false;
        //Error message map
        Map<String, List<String>> rowErrors = new Map<String, List<String>>();                
        //RowGUID list  is for hooking up the DML error messages to the correct row in the UI
        List<String> rowGuidSegments = new List<String>();           
        List<Sobject> updateSobjects = new List<Sobject>();  
        List<Sobject> insertSobjects = new List<Sobject>();  
        List<Sobject> deleteSobjects = new List<Sobject>();  
        List<Sobject> AllSobjects       = new List<Sobject>();
        Boolean hasException = false;
        Boolean isFinalizedFlagSet = false;
        try {    
            if(je.id!=null){
            	Journal =[select id,name,Finalized__c from Journal_Entry__c where id =:je.id];
            }
            //The flag will be ONLY set for transition of finalized__c falg from false to true.
			isFinalizedFlagSet = (je.Finalized__c && !Journal.Finalized__c) ? true:false;
			if(isFinalizedFlagSet){
				//Temporarily reset the flag to enable insertion of Lines.
				je.Finalized__c=false;
				if(je.Type__c.equalsIgnoreCase('Year End Adjustment')){
										
					je.Posting_date__c = je.transaction_date__c;
					je.gl_date_time__c = je.transaction_date__c;
					je.Finalized_date__c = system.now();
				}
	            DML.checkUpsertAsUser(je); upsert je;
			}
			else{
				if(je.Type__c.equalsIgnoreCase('Year End Adjustment')){
					SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
					soql.addFields(new set<string>{
						'Id','FiscalYear__r.Fiscal_Year_End_Date__c'
					});
					soql.setWhereClause('Id = \''+je.Period__c +'\' AND (Type__c = \'Zero\' OR Type__c = \'Period 13\')');
					soql.setLimit(1);
					Period__c zeroPeriod = Database.query(soql.getQuery());
					if(zeroPeriod != null)
					
					je.transaction_date__c = zeroPeriod.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1);
				}
	            DML.checkUpsertAsUser(je); upsert je;
			    result.records.add(je);				
			}
			
            system.debug('je:'+je);

             rowGuidSegments = new List<String>();
  			//Update DML Operation.          
            try{
           	
            	for(JournalEntryLineWrapper updateWrapper :updatedList){
            		KendoUtils.UpdateDateFields(updateWrapper.jeLine, dateFields);           		
            		updateSobjects.add(updateWrapper.jeLine);   
            		rowGuidSegments.add(updateWrapper.rowGuid);       		            		
            	}
            	system.debug('rowGuidSegments:'+rowGuidSegments);                
            	DML.updateAsUser(updateSobjects); 
            	
            }
            catch(DMLException de){
                    Integer numErrors = de.getNumDml();

                    for(Integer i=0; i<numErrors; i++) {

                        rowErrors.putAll(addRowErrors(rowErrors, rowGuidSegments[de.getDmlIndex(i)], de.getDmlMessage(i)));

                     } 
             	system.debug('rowGuidSegments:'+rowGuidSegments);                
                                	
            }
            catch(Exception e){
	            Database.rollback(sp);
	            result.success = false;
	            result.addMessage(Label.An_error_occurred + e.getMessage() +e.getLineNumber(), ApexPages.Severity.ERROR);            	
            }
 
 			//Insert DML Operation.
 			            
            try{
            	rowGuidSegments = new List<String>();
           	
            	for(JournalEntryLineWrapper insertWrapper :newList){
            		KendoUtils.UpdateDateFields(insertWrapper.jeLine, dateFields);     
            		insertWrapper.jeLine.journal_Entry__c=je.Id;      		
            		insertSobjects.add(insertWrapper.jeLine);   
            		rowGuidSegments.add(insertWrapper.rowGuid);       		            		
            	}
            	                
            	DML.insertAsUser(insertSobjects); 
            	
            }
            catch(DMLException de){
                    Integer numErrors = de.getNumDml();

                    for(Integer i=0; i<numErrors; i++) {

                        rowErrors.putAll(addRowErrors(rowErrors, rowGuidSegments[de.getDmlIndex(i)], de.getDmlMessage(i)));

                     }            	
            }
            catch(Exception e){
	            hasException = true;
	            System.debug(e.getMessage());
	        	result.success = false;
	            result.addMessage(Label.An_error_occurred + e.getMessage() +e.getLineNumber(), ApexPages.Severity.ERROR);            	
            }      
            
            //Delete DML Operation.
            try{
            	rowGuidSegments = new List<String>();
           	
            	for(JournalEntryLineWrapper delWrapper :deletedList){
            		KendoUtils.UpdateDateFields(delWrapper.jeLine, dateFields);  
            		if(delWrapper.jeLine.id !=null){         		
	            		deleteSobjects.add(delWrapper.jeLine);   
	            		rowGuidSegments.add(delWrapper.rowGuid);  
            		}     		            		
            	}
            	                
            	new DML.WithoutSharing().sobjectDel( deleteSobjects );
            	
            }
            catch(DMLException de){
                    Integer numErrors = de.getNumDml();

                    for(Integer i=0; i<numErrors; i++) {

                        rowErrors.putAll(addRowErrors(rowErrors, rowGuidSegments[de.getDmlIndex(i)], de.getDmlMessage(i)));

                     }            	
            }
            catch(Exception e){
	            hasException = true;
	            System.debug(e.getMessage());
    	        result.success = false;
	            result.addMessage(Label.An_error_occurred + e.getMessage() +e.getLineNumber(), ApexPages.Severity.ERROR);            	
            }          
            //    
 			if(isFinalizedFlagSet){
 				//Set the flag back to true as DML on lines is successful.
				je.Finalized__c=true;
	            DML.checkUpsertAsUser(je); upsert je;
				result.records.add(je);
	            
			}
			
            AllSobjects.addAll(updateSobjects);
            AllSobjects.addAll(insertSobjects);
            AllSobjects.addAll(deleteSobjects);
            
            result.records.addAll((list<object>)updatedList);
            result.records.addAll((list<object>)newList);
            result.records.addAll((list<object>)deletedList);


        } 
        catch (DMLException De) {
            hasException = true;
            result.success = false;            
            //Header upsert failed.
            if(De.getDMLMessage(0).contains(Label.JournalEntries_with_exceptions_cannot_be_Finalized)){
              set<string> exceptionList = new set<string>();
              list<Task> jeHeaderExceptions =	[select description from task where whatid = :je.id];
              for(task t:jeHeaderExceptions){
              	exceptionList.add(t.description);
              }
               result.addMessage('Journal Entry cannot be Finalized.It has following Exceptions.' , ApexPages.Severity.ERROR);            	
               result.addMessage(String.join(new list<string>(exceptionList),','), ApexPages.Severity.ERROR);            	
              
            }
            else{
              result.addMessage(Label.An_error_occurred + De.getdmlMessage(0) , ApexPages.Severity.ERROR);            	
            }
        }
        catch (Exception e) {
            hasException = true;
            System.debug(e.getMessage());
            result.success = false;
            result.addMessage(Label.An_error_occurred + e.getMessage() +e.getLineNumber(), ApexPages.Severity.ERROR);
        }

        result = updateJSONResult(result, rowErrors, AllSobjects.size(), hasException);
        if(!result.success){
            //Rollback all DB changes
            Database.rollback(sp);
        }


        return result;
     }   
     
   //TODO : Move updateJSONResult,convertRowErrorsToWrapperList,addRowErrors to Service cls.
   
    private static JSONResult updateJSONResult(JSONResult jsonResult, 
                                               Map<String, List<String>> rowErrors, 
                                               Integer rowsSucceeded,
                                               Boolean hasException){
        system.debug('rowErrors :'+rowErrors);
        List<JELineErrorWrapper> rowErrorList = new List<JELineErrorWrapper>();

        if(rowErrors.size() > 0){

            rowErrorList = convertRowErrorsToWrapperList(rowErrors);
        }
        system.debug('rowErrorList :'+rowErrorList);
        
        //Show user friendly errors on screen
        if(rowErrors.size() == 0 && !hasException){
            jsonResult.success = true;
            jsonResult.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
            jsonResult.total = rowsSucceeded;

        } else if(rowErrorList.size() > 0 && !hasException){

            jsonResult.success = false;
            jsonResult.records = rowErrorList;
            jsonResult.addMessage(KNDO_PAGE_HEADER_ERROR_MSG, ApexPages.Severity.ERROR); 

        } else if(hasException){

            jsonResult.success = false;

            if(rowErrorList.size() > 0){
                jsonResult.records = rowErrorList;
            }

            //jsonResult.addMessage(KNDO_PAGE_HEADER_GENERAL_EXCEPTION_MSG, ApexPages.Severity.ERROR);
        }

        return jsonResult;
    }


     private static List<JELineErrorWrapper> convertRowErrorsToWrapperList(Map<String, List<String>> rowErrors){

        List<JELineErrorWrapper> rowErrorWrapperList = new List<JELineErrorWrapper>();
        
        if(rowErrors.size() > 0){

            for (String rGUID : rowErrors.keySet()){

                rowErrorWrapperList.add(new JELineErrorWrapper(rGUID, rowErrors.get(rGUID)));

            }

        }

        return rowErrorWrapperList;
     }
     
     private static Map<String, List<String>> addRowErrors(Map<String, List<String>> rowErrors, String rowGUID, String errorMessage){

        if(rowErrors.containsKey(rowGUID)){
            rowErrors.get(rowGUID).add(errorMessage);
        } else {
            List<String> errorMessages = new List<String>();
            errorMessages.add(errorMessage);
            rowErrors.put(rowGUID, errorMessages);

        }

        return rowErrors;
    }   
    
    public class JournalEntryLineWrapper {
        public Journal_Entry_Line__c jeLine { get; set; }
        public boolean hasExceptions { get; set; } { hasExceptions = false; }
        public List<Task> exceptions { get; set; }
        public String rowGUID =''; 
        public string errors { get; set; }//Corresponds to fieldinfo of type rowinfo which is of type string.
        
        public JournalEntryLineWrapper(boolean hasExceptions, List<Task> exceptions) {
            this.hasExceptions = hasExceptions;
            this.exceptions = exceptions;   
    }
    
        public JournalEntryLineWrapper(Journal_Entry_Line__c jeLine, List<Task> exceptions) {
            this.jeLine = jeLine;
            this.hasExceptions = jeLine.Has_Exceptions__c;
            this.exceptions = exceptions;
        }
     }
    public class JELineErrorWrapper {
        public String rowGUID { get; set; }
        public List<String> errors { get; set; }

        //Constructor 1
        public JELineErrorWrapper(String rowGUID, List<String> errors) {

            this.rowGUID = rowGUID;
            this.errors = errors;
        }
    }
}