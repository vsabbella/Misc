public with sharing class SourceDocumentUnfinalize {

	public string SourceDocName { get; private set; }
	ApexPages.StandardController stdcon;
	ApexPages.StandardSetController setcon;
	private SchemaUtil util = SchemaUtil.getInstance();
	public string theSourceDocId;
    public string theSourceDocType;
	List<Accounting_Entry__c> relatedAEList = new List<Accounting_Entry__c>();
	Accounting_Entry__c relatedAE = new Accounting_Entry__c();
	Map<Id, Accounting_Entry__c> SourceDocAEMap = new Map<Id, Accounting_Entry__c>();
	sObject sObj; 
	public boolean unfinalize {get; set;} {unfinalize = true;}
	public List<Sobject> sObjList {get; set;}
	Set<Id> sObjIds = new Set<Id>();
	public String objName;
	private String namespace = Kse.NamespaceUU;
	public Integer sObjListSize {get; set;}
    public Boolean isBankTransaction=false;
    public boolean validFadExists = false; 
    public list<Bank_Transaction__c> BTs = new list<Bank_Transaction__c>();
	AccountingEntryService AES = AccountingEntryService.getInstance();
	
	// standard controller constructor for detail page
	public SourceDocumentUnfinalize(Apexpages.standardcontroller controller) {
		this.stdcon = controller;
        theSourceDocType = ((Id)stdcon.getId()).getSobjectType().getDescribe().getLocalName();
        system.debug('theSourceDocType :'+theSourceDocType);
        if(theSourceDocType=='Bank_Transaction__c'){
         isBankTransaction = true;           
        }
         system.debug('isBankTransaction '+isBankTransaction);
       
        if(!test.isRunningTest() && !isBankTransaction){
			this.stdcon.addFields(new List<string>{'posting_date__c'});
		}
		sObject tmpsObj;
		tmpsObj = stdcon.getRecord() ;
        
        if(theSourceDocType=='Bank_Transaction_Group__c'){
            //Get BT details for display and redirect on UI .
            BTs =[select id,name ,Bank_Transaction_Group__c 
                  from Bank_Transaction__c where Bank_Transaction_Group__c=:tmpsObj.id];
        }


        if(isBankTransaction){
 				//Querying to ensure we have Bank_Transaction_Group__c as it will not be in layout and hence not in standard controller fields.
                BTs =[select id,name ,Bank_Transaction_Group__c 
                                                from Bank_Transaction__c where id=:tmpsObj.id];
    
                if(BTS.size()>0){
                    if(BTS[0].Bank_Transaction_Group__c!=null){
                        theSourceDocId = BTS[0].Bank_Transaction_Group__c;
                    }
                    else{
                        pageMessages('Need to have Bank Transaction group to unfinalize.','FATAL');                                           
                    }
                }
                else{
                    pageMessages('Bank transaction does not exist.','FATAL');
                }              
            
 
            
        }
        else{
	    	theSourceDocId = String.valueof((Id) tmpsObj.get('Id'));            
        }
		if ( theSourceDocId == '' || theSourceDocId == null   ) pageMessages(Label.No_record_ID_found, 'FATAL');
	} 

	// standard set controller constructor for list view page	
	public SourceDocumentUnfinalize(Apexpages.standardsetcontroller controller) {
		
		this.setcon = controller;
		if(!test.isRunningTest()){
			this.setcon.addFields(new List<string>{'posting_date__c'});
		}
		
		List<sObject> tmpsObjList;
		tmpsObjList =  setcon.getSelected() ;
		
		theSourceDocId = String.valueof((Id) tmpsObjList[0].get('Id'));
		
		if ( theSourceDocId == '' || theSourceDocId == null   ) pageMessages(Label.No_record_ID_found, 'FATAL');
		
		for(Integer i=1;i<tmpsObjList.size();i++){
			theSourceDocId += '-'+String.valueof((Id) tmpsObjList[i].get('Id'));
		}

	} 
	
	public List<Schema.FieldSetMember> sObjFields { get; set; } {
        sObjFields = new List<Schema.FieldSetMember>(); 
    } 
    
	// Constructor to perform basic checks
	public SourceDocumentUnfinalize() {
		// Get the String of Ids ( could be one id or more )
		theSourceDocId = ApexPages.currentPage().getParameters().get('id');
		if ( theSourceDocId == '' || theSourceDocId == null   ) pageMessages(Label.No_record_ID_found, 'FATAL');
		
		String[] RefStringArray = theSourceDocId.split('-');
		String firstField = RefStringArray[0];
		Integer arraylength = RefStringArray.size();
		for(Integer i= 0; i< arraylength ;i++){
			sObjIds.add((Id) RefStringArray[i]);
		}
		// assign first field from the list of Ids
		theSourceDocId = String.escapeSingleQuotes(firstField);
        theSourceDocType = ((Id)theSourceDocId).getSobjectType().getDescribe().getLocalName();
        if(theSourceDocType=='Bank_Transaction__c'){
         isBankTransaction = true;           
        }
        if(theSourceDocType=='Bank_Transaction_Group__c'){
            //Get BT details for display and redirect on UI .
             BTs =[select id,name ,Bank_Transaction_Group__c, Reconciled_As_Of_Date__c, Match_Approved__c 
                  from Bank_Transaction__c where Bank_Transaction_Group__c=:theSourceDocId];
            if(!BTs.isEmpty()){
            	if(BTs[0].Reconciled_As_Of_Date__c != null){
            		pageMessages(Label.transaction_has_been_reconciled,'INFO');      
            	}else if(BTs[0].Match_Approved__c){
            		pageMessages(Label.Existing_approved_matches_will_be_deleted,'INFO');    
            	}else{
            		pageMessages(Label.Existing_matches_will_be_deleted,'INFO');
            	}
            }
        }
        
        
        if(isBankTransaction){
            //Querying to ensure we have Bank_Transaction_Group__c as it will not be in layout and hence not in standard controller fields.
            BTs =[select id,name ,Bank_Transaction_Group__c, Reconciled_As_Of_Date__c, Match_Approved__c 
                                                from Bank_Transaction__c where id=:theSourceDocId];
    
                if(BTS.size()>0){
                    if(BTS[0].Bank_Transaction_Group__c!=null){
                        theSourceDocId = BTS[0].Bank_Transaction_Group__c;
                        if(BTs[0].Reconciled_As_Of_Date__c != null){
		            		pageMessages(Label.transaction_has_been_reconciled,'INFO');      
		            	}else if(BTs[0].Match_Approved__c){
		            		pageMessages(Label.Existing_approved_matches_will_be_deleted,'INFO');    
		            	}else{
		            		pageMessages(Label.Existing_matches_will_be_deleted,'INFO');
		            	}
                    }
                    else{
                        pageMessages('Need to have Bank Transaction group to unfinalize.','FATAL');                                           
                    }
                }
                else{
                    pageMessages('Bank transaction does not exist.','FATAL');
                }               
        }
	}
	
	
	// function to show page messages
	void pageMessages( string msg , String severityLevel) {
		system.debug('msg: ' + msg + ' - sev: ' + severityLevel);
		if(severityLevel.equalsIgnoreCase('FATAL')){
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.FATAL, MessageUtil.toFriendlyErrorMessage(msg)));
		}else if(severityLevel.equalsIgnoreCase('ERROR')){
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(msg)));
		}else if(severityLevel.equalsIgnoreCase('WARNING') ){
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.WARNING, MessageUtil.toFriendlyErrorMessage(msg)));
		}else if(severityLevel.equalsIgnoreCase('INFO') ){
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.INFO, MessageUtil.toFriendlyErrorMessage(msg)));
		}
	}
	
	// Query the source docs and create the sObject / sObject list to pass to the unFinalizeSourceDocument from service class
	public void unfinalizeSourceDoc() {
		DescribesObjectResult sObjDescResult;
		Schema.Sobjecttype sType =util.getSObjectType(theSourceDocId);
		sObjDescResult =  sType.getDescribe();
		objName = sObjDescResult.getLocalName();
		Boolean hasVoid = false;
        Boolean hasHistorical = false;
        //FIN-397 Void Doc cannot be Unfinalized
        set<string> fldSet = util.getAllCustomFieldsFromObject(null,objName);
		
		//---KNDY-10996 -----FAA can not be unfinalized if the FAD for that Fixed Asset exists and Date Last Depreciated > Transaction Date ( FAA's TD)-
         system.debug('theSourceDocType :'+theSourceDocType); 
         if(theSourceDocType=='Fixed_Asset_Adjustment__c'){ 
         	// Get the Fixed Asset Adjustment with its Transaction_Date__c 
         	Fixed_Asset_Adjustment__c faa =
     							[select id,Transaction_Date__c ,Fixed_Asset__r.Id 
    										from Fixed_Asset_Adjustment__c
     									where id=:theSourceDocId]; 
     		System.debug('Fixed Asset Adjustment with its Transaction_Date__c'+faa);
     		
     		// Fetch the corresponding Fixed Asset
 			Fixed_Asset__c fa =  [select id ,name ,Date_Last_Depreciated__c ,
                      						(select id from Fixed_Asset_Depreciations__r )
  										from Fixed_Asset__c 
          								where id = :faa.Fixed_Asset__r.Id];
          	System.debug('Fixed Asset with Date_Last_Depreciated__c '+fa);
            	
           	// Check if fixed asset depreciations exists
           	if(fa.Fixed_Asset_Depreciations__r.size() >0){
           		System.debug(' Fixed asset depreciations exists');
           		if(fa.Date_Last_Depreciated__c>faa.Transaction_Date__c){
     				validFadExists = true;		 
 				} 
           	} 
        }  
 
         

        String historyField = 'Historical__c';
        String voidField ='Void__c';

        
        if(fldSet.contains('historical__c')){
            hasHistorical = true;
        }
        if(fldSet.contains('void__c')){
            hasVoid = true;
        }        
		Map<String, Schema.FieldSet> FieldsetMap = util.generateFieldSetsFromObjectName(objName);
		
		// Each source document has the fieldset with name Unfinalize which can be utilized to display record details on the page
		if (objName != null) {
            sObjFields =  FieldsetMap.get( namespace + 'Unfinalize').getFields();
        }
        set<string> finalizeFields = new set<string>(schemaUtil.getInstance().getFieldsFromFieldSetString(objName,'Unfinalize'));
        //TODO:Usage of set to restrict duplicates becomes ineffective due to case senstivity.Enhance to make it case-insensitive.
        set<string> requiredFieldsForFinalize = new set<string>{'Id','Name','Finalized__c', 'Transaction_Date__c', 'Finalized_Date__c', 'Posting_Date__c'};
        finalizeFields.addAll(requiredFieldsForFinalize);
        id rid = theSourceDocId; 
		//FIN-397 Void Doc cannot be Unfinalized 


	    String whereClause = 'id in :sObjIds and finalized__c = true';  
    
	    SOQLUtil soql = new SOQLUtil(objName);
       
        if(objName.equalsIgnoreCase('Invoice__c') || objName.equalsIgnoreCase('Payment__c')){
	    	finalizeFields.add('From_Company__c');        	
        }
        else{
  	    	finalizeFields.add('Company__c');        	       	
        }
        
  	    // all accounting source documents have these fields       
	    soql.addFields(finalizeFields);
        

            
	    if(hasHistorical){
	    	soql.addField('Historical__c');
	    }
	    
	    if(hasVoid){
	    	soql.addField('Void__c');
	    }
	    
	    soql.setWhereClause(whereClause);
	    
	    sObjList = Database.query(soql.getQuery());
	    /*
		'select id, name, finalized__c, Company__c, void__c, transaction_date__c, finalized_date__c, posting_date__c ' + historyField + ' from ' +
		objName + ' where id in :sObjIds and finalized__c = true');
		*/
        

		if(sObjList != null)
        {
			sObjListSize = sObjList.size();
			if(sObjListSize > 0)
            {  
                sObj = sObjList[0];
                
                 // #KNDY-10996 -- If Valid fixed asset depreciations exists , dont unfinalize Fixed Asset Adjustments  
      			  if(validFadExists == true){  
         			pageMessages( label.Cannot_Unfinalize_FAA,'FATAL');  
            			unfinalize = false;//Disable unfinalize button 
            			SourceDocName = 'Return to ' + (string) sObj.get('Name');    
            			return;
        			 } 
  		 		
  		 		//FIN-397 Void Doc cannot be Unfinalized               
                if(hasVoid)
                {
                for(sObject s :sObjList)
                {
                    if(hasVoid && s.get('void__c')==true)
                    {
                        pageMessages( Label.Cannot_Unfinalize_Void_Doc,'FATAL');
                        unfinalize = false;//Disable unfinalize button
                        //Determine the source doc name for the return button
                        if(sObjListSize < 2)
                        { 
                            if(theSourceDocType == 'Bank_Transaction_Group__c'){
                               SourceDocName = 'Return to ' + BTs[0].name;                              
                            }
                            else{
                               SourceDocName = 'Return to ' + (string) sObj.get('Name');                              
                            }

                        }
                        else
                        {
	                      SourceDocName='Return'  ;
                        }
                        return;                        
                    }
        
                    }                
                }                
            }
		}else{
			pageMessages( Label.Record_not_finalized,'FATAL');
			return;
		}
                
		// assign first field from the source document sObj list to find out the source doc name for the return button.	
		
		if( sObjListSize < 2 && sObjListSize > 0){
            if(theSourceDocType == 'Bank_Transaction_Group__c'){
                SourceDocName = 'Return to ' + BTs[0].name;                              
            }
            else{
                SourceDocName = 'Return to ' + (string) sObj.get('Name');                              
            }
            // Query the related Accounting Entry sort by GL Date ASC and limit 1 ( This should give you only 1 or 0 AE )
			//KNDY-3369 
				/*string wherestr = String.join(util.relatedCustomObjects('Accounting_Entry__c'), ' in :sObjIds OR ') +' in :sObjIds ';
		 		string q = util.generateQueryFromFieldSet( 'Accounting_Entry__c',
					new set<string>{'Source_Documents'}, 
					new set<string>{'id', 'Period__c' ,'Period__r.Open__c'}, 
					'('+ wherestr +')' + ' ORDER BY GL_Date_Time__c ASC limit 1');*/ 
					List<Accounting_Entry__c> originalAEList = new List<Accounting_Entry__c>();
					
					Accounting_Entry__c originalAE;
				try{
					whereClause = '(' + String.join(util.relatedCustomObjects('Accounting_Entry__c'), ' in :sObjIds OR ') + ' in :sObjIds ' + ')' 
											 + ' ORDER BY GL_Date_Time__c ASC limit 1'; 
        
				    soql = new SOQLUtil('Accounting_Entry__c');
				    soql.addFields('Source_Documents');
				    soql.addFields(new set<string>{'id', 'Period__c', 'Period__r.Open__c', 'Period_Status__c'});
				    soql.setWhereClause(whereClause);
	    	
					originalAEList = Database.query(soql.getQuery());
				}catch(Exception e){
					pageMessages( Label.Accounting_entry_not_queried +e,'FATAL');
				}
				//system.debug('originalAE :'+originalAE);
				if(originalAEList != null && originalAEList.size() > 0){
					originalAE = originalAEList[0];
				}
				if(originalAE != null){
/*				if ( originalAE.Period__c == null){
					pageMessages( Label.AE_period_missing,'FATAL');
					unfinalize = false;
					return;
				}
*/				//Let the UnfinalizeService make this determination
				/*
				  else if(!AES.isInPeriod (new Period__c (id =  originalAE.Period__c)) ){
					pageMessages( 'Record can not be unfinalized as the period is not open','FATAL');
					unfinalize = false;
					return;
				}
				*/
			}
			
		}else{
			SourceDocName = 'Return';
		}	
		// Query the related Accounting Entry sort by GL Date ASC and limit 1 ( This should give you only 1 or 0 AE )
		
		/*string wherestr = String.join(util.relatedCustomObjects('Accounting_Entry__c'), ' in :sObjIds OR ') +' in :sObjIds ';
 		string q = util.generateQueryFromFieldSet( 'Accounting_Entry__c',
			new set<string>{'Source_Documents'}, 
			new set<string>{'id','Period__r.Open__c','Period_Status__c'}, 
			'('+ wherestr +')' + ' and Related_Accounting_Entry__c = null and Void__c = false'); */
		
		whereClause = '('+ String.join(util.relatedCustomObjects('Accounting_Entry__c'), ' in :sObjIds OR ') + ' in :sObjIds ' +')' 
								+ ' and Related_Accounting_Entry__c = null and Void__c = false';
        
	    soql = new SOQLUtil('Accounting_Entry__c');
	    soql.addFields('Source_Documents');
	    soql.addFields(new set<string>{'id','Period__r.Open__c','Period_Status__c'});
	    soql.setWhereClause(whereClause);
	    	
		relatedAEList = Database.query(soql.getQuery());
		Integer relatedAEListSize;
		
		if(relatedAEList != null){
			relatedAEListSize = relatedAEList.size();
		}
		if( relatedAEListSize > 0){
			relatedAE = relatedAEList[0];
		}else{
			relatedAE = null;
		}
		
		// populate the sourceDoc, relatedAccountingEntryObj Map to pass to the AES.unFinalizeDocument() function
		if( relatedAEListSize > 0){
			for(Accounting_Entry__c aeObj: relatedAEList){
				
				//if((objName == 'Customer_Invoice__c' || objName == 'Supplier_Invoice__c') && aeObj.get(objName) == null){
				//	objName = (objName).split('_')[0] + '_Credit_Memo__c';
				//}
				if(aeObj.get(objName) != null ){
					SourceDocAEMap.put((Id) aeObj.get(objName), aeObj);
				}
					
				
			}
		}
		
		
		if(sObjListSize < 2 && sObjListSize > 0){ // If single record selected.
			if ( (boolean) sObj.get('Finalized__c') == false ) {
				pageMessages( Label.Record_not_finalized,'FATAL');
				unfinalize = false;
				return;
			}
			//PTP-272 Cannot unfinalize a supplier invoice with a valid payment 
			else if(sObjList.getSobjectType().getDescribe().getLocalName() == 'Supplier_Invoice__c'){
				Supplier_Invoice__c siToCheck = [select id, name, invoice_type__c, Amount_Paid__c, Credit_Memo_Amount__c, Credit_Memo_Balance__c from Supplier_Invoice__c where id = :sObjList[0].id];
				if (((siToCheck.invoice_type__c == 'Invoice' || siToCheck.invoice_type__c == 'Prepayment') && siToCheck.Amount_Paid__c > 0) || 
					(siToCheck.invoice_type__c == 'Credit Memo' && siToCheck.Credit_Memo_Balance__c != siToCheck.Credit_Memo_Amount__c)){
					pagemessages(Label.Unfinalizing_Paid_Invoice , 'ERROR');
					unfinalize = false;
					return;
				}
				
			} else if(sObjList.getSobjectType().getDescribe().getLocalName() == 'Journal_Entry__c'){
				Journal_Entry__c jeToCheck = [select id, name, Type__c,period__c from Journal_Entry__c where id = :sObjList[0].id];
				//KNDY-10174
				for(String warnings : BankTransactionMatchService.getMatchesErrors('Journal_Entry_Line__c', sObjList[0].id)) {
					pagemessages(warnings, 'WARNING');
					unfinalize = true;
				}
				if(jeToCheck.Type__c.equalsIgnoreCase('Year End Adjustment')){
			        id periodId = jeToCheck.period__c;
			        SOQLUtil jeSoql = new SOQLUtil ( 'Journal_Entry__c' ) ;
			        jeSoql.addFields ( new Set<String> { 'Id','Name','period__c' } ) ;
			        jeSoql.setWhereClause ( 'Type__c = \'Year End\' AND Period__c = : periodId AND Finalized__c = true AND Void__c = false' ) ;
			        jeSoql.setLimit (1);
			        
			        List<Journal_Entry__c> yearEndJournals = Database.query ( jeSoql.getQuery () ) ;
			        if(yearEndJournals != null && yearEndJournals.size()>0){
						pagemessages('You cannot Unfinalize adjusting journal entries for this year because net income has already been transferred to retained earnings. To unfinalize adjusting entries, you must first cancel the balance transfer in the Fiscal Year Close window', 'ERROR');
						unfinalize = false;}
					//return;
				}
				
				if(jeToCheck.Type__c == 'Year End'){
					pagemessages('Cannot unfinalize a Year End journal entry', 'ERROR');
					unfinalize = false;
					//return;
				}
					return;
				}
			else if(sObjList.getSobjectType().getDescribe().getLocalName() == 'Customer_Invoice__c')//AR-87 From the UI block unfinalize of all non manual CIs
			{
				Customer_Invoice__c ci = [select id, name, Invoice_Type__c from Customer_Invoice__c where id = :sObjList[0].id];
				if(ci.Invoice_Type__c != CustomerInvoiceService.TYPE_MANUAL){
					pageMessages(Label.Can_only_unfinalize_Manual_Customer_Invoices, 'ERROR');
					unfinalize = false;
					return;
				}
			}
			else if(sObjList.getSobjectType().getDescribe().getLocalName() == 'Customer_Receipt__c') { //KNDY-7701 block unfinalize of Claim Settlement CR from UI
					Customer_Receipt__c cr = [select id, Type__c,Payment_Method_3__c, (Select Id,Bank_Transaction__r.Name, Bank_Transaction__r.Match_Approved__c, Bank_Transaction__r.Reconciled_As_Of_Date__c, Bank_Transaction__r.Finalized__c 
															   from Bank_Transaction_Match__r 
                        									    ) 
                        			      from Customer_Receipt__c where id = :sObjList[0].id];

				if(cr.Type__c == CustomerReceiptService.TYPE_CLAIM_SETTLEMENT) {
					pageMessages('Cannot Unfinalize Claim Settlement Customer Receipts. These can only be void/cancelled.', 'ERROR');
					unfinalize = false;
					return;
				}

				if(cr.Payment_Method_3__c != null) {
					pageMessages('Cannot Unfinalize payments via Credit Cards.', 'ERROR');
					unfinalize = false;
					return;
				}

				if(cr.Type__c == CustomerReceiptService.TYPE_REFUND) {
                    pageMessages( Label.Cannot_Unfinalize_Refund_Customer_Receipts, 'ERROR');
                    unfinalize = false;  
                    return;
                }

				if(cr.Bank_Transaction_Match__r.size() > 0) {
					for(String warnings : BankTransactionMatchService.getMatchesErrors(cr.Bank_Transaction_Match__r, 'Customer_Receipt__c', sObjList[0].id))
						pageMessages(warnings, 'WARNING');
					unfinalize = true;
				}
				return;

			}else if(sObjList.getSobjectType().getDescribe().getLocalName() == 'Payment__c') {
				Payment__c p = [select id, (Select Id,Bank_Transaction__r.Name, Bank_Transaction__r.Match_Approved__c, Bank_Transaction__r.Reconciled_As_Of_Date__c, Bank_Transaction__r.Finalized__c 
															   from Bank_Transaction_Match__r) 
                        			      from Payment__c where id = :sObjList[0].id];
                if(p.Bank_Transaction_Match__r.size() > 0) {
					for(String warnings : BankTransactionMatchService.getMatchesErrors(p.Bank_Transaction_Match__r, 'Payment__c', sObjList[0].id))
						pageMessages(warnings, 'WARNING');
					unfinalize = true;
				}
				return;
			}
			else {

				//Let the UnfinalizeService make this determination
				/*
				if(relatedAE != null && ! relatedAE.Period_Status__c.equalsIgnoreCase('Open')){
					pageMessages( 'Can not unfinalize the documents in non open period.','FATAL');
					unfinalize = false;
					return;
				}else{
				*/
					pageMessages( Label.Posted_AE_voided_or_deleted,'INFO');
				//}
			} 
		}else if(sObjListSize > 2){ // If called thru the list view
			pageMessages( Label.Posted_AE_voided_or_deleted,'INFO');
		}else{
			pageMessages( Label.No_records_to_unfinalize,'FATAL');
			unfinalize = false;
			return;
		}

		if ( Apexpages.hasMessages(Apexpages.severity.FATAL)|| Apexpages.hasMessages(Apexpages.severity.WARNING)) {
			unfinalize = false;
			return;
		}

	}
	
	// cliking of unfinalize button calls the unfinalize from the service class ( AccountingEntryService.cls)
	public PageReference unfinalize(){
		try{
			//AES.unFinalizeSourceDocument(sObjList, SourceDocAEMap);
			Savepoint sp = Database.setSavepoint();
			Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(sObjList);
			/*
			//RS - I'm breaking this for now - need to come up with a better alternative
			//OTC-301 we place the exceptionservice check after every menthod logic. this will check for exception, paste it on the VF page and exit the method. 
			if(ExceptionService.hasErrors)
			{
				system.debug('ExceptionService has error '+ExceptionService.messages);
				database.rollback(sp);
				for(Map<String,String> message : ExceptionService.messages)
					pageMessages( message.get('message'), message.get('severity')) ;
					
				return null;
			} 
			*/
			for(sObject sObjRec : sObjList){
				if(mResponses.containsKey(sObjRec.Id)){
					if(!mResponses.get(sObjRec.Id).Success){
						pageMessages(mResponses.get(sObjRec.Id).message ,'FATAL');
					}
				}else{
					pageMessages(Label.Unfinalize_not_completed ,'FATAL');
				}
			}
			
			//This is logic specific to supplier invoices only and should be move to a trigger
			List<Supplier_Invoice__c> supplierInvoices = new List<Supplier_Invoice__c>();
			for(Id sourceDocId : mResponses.keySet()){
				if(sourceDocId.getSobjectType().getDescribe().getLocalName() == 'Supplier_Invoice__c' && mResponses.get(sourceDocId).Success){
					Supplier_Invoice__c iSI = new Supplier_Invoice__c(Id = sourceDocId, status__c = 'Incomplete');		
					supplierInvoices.add(iSI);			
				}	
			}
			if(supplierInvoices.size() > 0){
				DML.updateAsUser(supplierInvoices);
			}
			
			return close();
		}catch(Exception e){
			String msg = e.getMessage();
			if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
				String[] msgArray = msg.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,',2);
				msg = msgArray[1];
			}
			pageMessages(msg ,'FATAL');
			unfinalize = false;
			return null;
		}
	}
	// return behaves different on standardcontroller(detail page) and setcontroller(list view)
	public Pagereference close() { 
		
		if ( Apexpages.hasMessages(Apexpages.severity.FATAL)|| Apexpages.hasMessages(Apexpages.severity.WARNING) || Apexpages.hasMessages(Apexpages.severity.ERROR)) { //KNDY-2914
				unfinalize = false;
				return null;
		}else{
			if(sObjListSize < 2 ){
                if(theSourceDocType=='Bank_Transaction_Group__c'){
 					return new PageReference( '/' +BTs[0].Id );	//Redirect back to BT from where user navigated for unfinalize.                   
                }
                else{
  			    	return new PageReference( '/' +theSourceDocId );	                  
                }
			}else{
				DescribesObjectResult sObjDescResult;//No changes for BT here as we do not support unfinalize on list view for Bank Transactions.
				Schema.Sobjecttype sType =util.getSObjectType(theSourceDocId);
				system.debug('theSourceDocId=='+theSourceDocId+ 'sType=='+sType +'theSourceDocType :'+theSourceDocType);
				sObjDescResult =  sType.getDescribe();
				if(theSourceDocType == 'Invoice__c'){//KNDY-11086
 					return new PageReference( '/' +theSourceDocId );	//Redirect back to BT from where user navigated for unfinalize.                   
                }else{
				return new PageReference('/' + sObjDescResult.getKeyPrefix());	
				}
			}
		}
	}
	
	// pass the id ( one or more ) as parameter to the navigated Page
	public PageReference navigateToUnfinalize() { 
		
		PageReference p = Page.SourceDocumentUnfinalize;
	    system.debug('theSourceDocId'+theSourceDocId);
		if(stdcon != null || setcon != null){
			p.getParameters().put('id', theSourceDocId);
		}
			return p.setRedirect(false);
	}
	//KNDY-11086 - just for intercompany invoices
	public PageReference validateAndnavigateToUnfinalize(){
		SOQLUtil soql = new SOQLUtil('Payment_Match__c', false); //enforceFLS=false, running in system mode
		soql.addFields(new set<string>{'Id'});
		soql.setWhereClause('Invoice__c =:theSourceDocId');
		List<Payment_Match__c> paymentMatchList = Database.query(soql.getQuery());
		if (paymentMatchList.size() > 0){
			pageMessages(Label.Cannot_unfinalize_IntercoInvoice_included_Payment ,'FATAL');
			return null;
		}
		PageReference p = Page.SourceDocumentUnfinalize;
	    system.debug('theSourceDocId'+theSourceDocId);
		if(stdcon != null || setcon != null){
			p.getParameters().put('id', theSourceDocId);
		}
		return p.setRedirect(false);
	}

}