public with sharing class SourceDocumentPostCon {
	
	public Period__c p {get;set;}
	public DateTime pSLC {get;set;}
	public Apexpages.StandardSetController ssCon {get;set;}
	public integer pageNo {get;set;}
	public integer noPages {get;set;}
	public List<SelectOption> pageOptions {get;set;}
	public List<SourceDoc> sourceDocs {get;set;}
	public DateTime postingDate {get; set;}
	public string pd {get;set;}
	public Apexpages.Standardcontroller con {get;set;}
	public string selectedSourceDocument {get;set;}
	public boolean blockPost {get;private set;}
	public list<Accounting_Entry__c> aeListToUpdate = new List<Accounting_Entry__c>();
	public String HelpURL{get;set;}
	
	public SourceDocumentPostCon(Apexpages.Standardcontroller controller){
		
		this.con = controller;
		HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpBackdateSourceDocuments';
		p = (Period__c)con.getRecord();
		updateGrid();
		
	}
	
	public List<SelectOption> getSourceDocumentOptions(){
		List<SelectOption> options = new List<SelectOption>{new SelectOption('', '-Select One-')};
		for(Schema.FieldSetMember field : schemaUtil.getInstance().getFieldsFromFieldSet(Accounting_Entry__c.getSObjectType(), 'Source_Documents')){
			if(!field.getFieldPath().contains('Fixed_Asset_Depreciation__c') ){
				options.add(new SelectOption(field.getFieldPath(), field.getLAbel()));
			}
		}
		return options;
	}
	
	
	public void updateGrid(){
		
		blockPost = false;
		
		if(selectedSourceDocument == '' || selectedSourceDocument == null){
			blockPost = true;
			return;
		}
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id recordId = con.getId();
		
		SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','period_start__c','period_end__c','Open__c','Type__c','ar_subledger_cutoff__c','ap_subledger_cutoff__c','inventory_subledger_cutoff__c',
			'receiving_subledger_cutoff__c','fa_subledger_cutoff__c','shipment_subledger_cutoff__c','JE_Cutoff__c','ar_subledger_job__c',
			'ap_subledger_job__c','inventory_subledger_job__c','receiving_subledger_job__c','fa_subledger_job__c','shipment_subledger_job__c',
			'je_subledger_job__c','ar_subledger_closed__c','ap_subledger_closed__c','inventory_subledger_closed__c','receiving_subledger_closed__c',
			'fa_subledger_closed__c','shipment_subledger_closed__c','period_closed__c','je_Cutoff__c','gl_close__c'
		});
		soql.setWhereClause('Id = :recordId');
		p = Database.query(soql.getQuery());

		system.debug('p: ' + p);
						
		string sourceDoc = selectedSourceDocument.replace(KSE.NamespaceUU, '');
		DateTime slc;
		DateTime ps = p.period_start__c;
		DateTime pe = p.period_end__c;
		
		//--------Fix for  Null Pointer issue -- KNDY-10619--------
		
		if(p.Type__c==null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,
					   'Period Type is missing' ));	
			blockPost = true;	
		}
		else{
			if(!p.Type__c.equalsIgnoreCase('fiscal')){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
						'Can not post documents to a Period which is not fiscal' ));
				blockPost = true;
			}
		} 
		
		
		if(p.Open__c != true){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
						'Unable to post documents once the Period is closed' ));
			blockPost = true;
		}
		
		//KNDY-10268 - deprecating bank file and bank file line objects
		//|| sourceDoc == 'Bank_File__c'
		if(sourceDoc == 'Customer_Invoice__c' || sourceDoc == 'Customer_Receipt__c' 
		                                      || sourceDoc == 'Bank_Transaction_Group__c'){
		    
			slc = p.ar_subledger_cutoff__c;
			if(p.ar_subledger_closed__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
							Label.Unable_to_post_documents_once_the_area_is_closed));
				blockPost = true;	
			}else if(p.ar_subledger_job__c != '' && p.ar_subledger_job__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
							Label.Unable_to_post_docs_job_running));
				blockPost = true;
			}
			
		}else if(sourceDoc == 'Supplier_Invoice__c' || sourceDoc == 'Supplier_Payment__c' || sourceDoc == 'Purchase_Order__c'){
			slc = p.ap_subledger_cutoff__c;
			if(p.ap_subledger_closed__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
							Label.Unable_to_post_documents_once_the_area_is_closed));
				blockPost = true;	
			}else if(p.ap_subledger_job__c != '' && p.ap_subledger_job__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
							Label.Unable_to_post_docs_job_running));
				blockPost = true;
			}
			
		}else if(sourceDoc == 'Receiving_Document__c'){
			slc = p.receiving_subledger_cutoff__c;
			if(p.receiving_subledger_closed__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,
							 Label.Unable_to_post_documents_once_the_area_is_closed));
				blockPost = true;	
			}else if(p.receiving_subledger_job__c != '' && p.receiving_subledger_job__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
							Label.Unable_to_post_docs_job_running));
				blockPost = true;
			}
			
		}else if(sourceDoc == 'Shipment__c'){
			slc = p.shipment_subledger_cutoff__c;
			if(p.shipment_subledger_closed__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
							Label.Unable_to_post_documents_once_the_area_is_closed));
				blockPost = true;	
			}else if(p.shipment_subledger_job__c != '' && p.shipment_subledger_job__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
							Label.Unable_to_post_docs_job_running));
				blockPost = true;
			}
			
		}else if(/*sourceDoc == 'Fixed_Asset_Depreciation__c' ||*/ sourceDoc == 'Fixed_Asset_Adjustment__c'){
			slc = p.fa_subledger_cutoff__c;
			if(p.fa_subledger_closed__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
							Label.Unable_to_post_documents_once_the_area_is_closed));
				blockPost = true;	
			}else if(p.fa_subledger_job__c != '' && p.fa_subledger_job__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
							Label.Unable_to_post_docs_job_running));
				blockPost = true;
			}
			
		}else if(sourceDoc == 'Work_Order__c' || sourceDoc == 'Inventory_Change__c'){
			slc = p.inventory_subledger_cutoff__c;
			if(p.inventory_subledger_closed__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
							Label.Unable_to_post_documents_once_the_area_is_closed));
				blockPost = true;	
			}else if(p.inventory_subledger_job__c != '' && p.inventory_subledger_job__c != null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
							Label.Unable_to_post_docs_job_running));
				blockPost = true;
			}
		}else if(sourceDoc == 'Journal_Entry__c'){
 			slc = p.JE_cutoff__c;
 			if(p.GL_close__c != null){
 				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
 							Label.Unable_to_post_documents_once_the_area_is_closed));
 				blockPost = true;	
 			}else if(p.je_subledger_job__c != '' && p.je_subledger_job__c != null){
 				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
 							Label.Unable_to_post_docs_job_running));
 				blockPost = true;
 			}
  		}
		//TODO: Update the query special casing for void__c field when we implement OTC order to cash / rest of the source documents
		String QueryString;
		if(sourceDoc == 'Supplier_Invoice__c' 
								|| sourceDoc == 'Supplier_Payment__c' 
								|| sourceDoc == 'Purchase_Order__c'
								|| sourceDoc == 'Receiving_Document__c'
								|| sourceDoc == 'Journal_Entry__c'){
			QueryString = 'SELECT Id, Name, transaction_date__c, currency__c, finalized__c, finalized_date__c, posting_date__c ,'
						+ ' (Select id, status__c from accounting_entries__r where status__c = \'Active\')'
						+ ' FROM ' + sourceDoc
						+ ' WHERE Finalized__c = true ' 
						+ ' AND void__c = false '
						+ ' AND Transaction_Date__c >= :ps ' 
						+ ' AND Transaction_Date__c < :pe '
						+ ' AND Finalized_Date__c >= :slc '
						+ ' AND (Posting_Date__c >= :slc OR Posting_Date__c = null) '
						+ ' ORDER BY Transaction_Date__c asc' ;
		}else{
			QueryString = 'SELECT Id, Name, transaction_date__c, currency__c, finalized__c, finalized_date__c, posting_date__c,'
						+ ' (Select id, status__c from accounting_entries__r where status__c = \'Active\')'
						+ ' FROM ' + sourceDoc
						+ ' WHERE Finalized__c = true ' 
						+ ' AND Transaction_Date__c >= :ps ' 
						+ ' AND Transaction_Date__c < :pe '
						+ ' AND Finalized_Date__c >= :slc '
						+ ' AND (Posting_Date__c >= :slc OR Posting_Date__c = null) '
						+ ' ORDER BY Transaction_Date__c asc' ;
		}
		
		ssCon = new Apexpages.StandardSetController(
				Database.getQueryLocator(QueryString));

		if(ssCon.getRecords().size() == 0){
			blockPost = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'There are no candidates for accrual' ));
		}else{
			
			pageNo = 1;
			ssCon.setPageSize(25);
			integer pages = getNumberOfPages();
			system.debug('pages: ' + pages);
			pageOptions = new List<SelectOption>();
			for(integer i=1; i<=pages; i++){
				pageOptions.add(new SelectOption(string.valueOf(i), string.valueOf(i)));
			}
			updateSourceDocs();	
			pSLC = slc;
		}
		
		
	}
	
	public void assign(){
		List<sObject> sObjRecs = new List<sObject>(); 
		Boolean isBTG = false;
		for(SourceDoc sd : sourceDocs){
			if(sd.selected){
				if(sd.sObj != null){
    				FinalizeService.postingIds.add(sd.sObj.Id);
    				Datetime td = (Datetime) sd.sObj.get('Transaction_Date__c');
    				sd.sObj.put('Posting_Date__c', td < pSLC.addSeconds(-1) ? td : pSLC.addSeconds(-1) );
    				
    			   
    			   String sobjectType = ''+sd.sObj.getSobjectType();
    			   
    			   system.debug('sd name--->'+sobjectType); 
    			   
    				if(sobjectType.equals('Bank_Transaction_Group__c')){
    				    isBTG = true;
    				 
                      // ASK SK
                      //FinalizeService.postingIds.add(sd.sObj.Id);
                      
                      //sObjRecs.add(currBTS[0]);
    				}
    				
    				
    				sObjRecs.add(sd.sObj);
    				system.debug('sObjRecs'+sObjRecs); 
    			 
					List<Accounting_Entry__c> aeList = sd.sObj.getsObjects('accounting_entries__r');
					if(aeList != null){
						for(Accounting_Entry__c ae: aeList){
							if(ae.status__c == 'Active'){
								ae.status__c = 'Obsolete';
								aeListToUpdate.add(ae);
							}
						}
					}
				}
			}
		}
		
		if(sObjRecs.size() > 0){
		    List<Bank_Transaction__c> btsToUpdate =  new List<Bank_Transaction__c>();
		    
		    try{
		        DML.updateAsUser(sObjRecs);
    		 
    			if(isBTG==true){
    			   
                    SoqlUtil currenBTGsQuery = new SoqlUtil('Bank_Transaction_Group__c',true);
                		currenBTGsQuery.addFields(new Set<String>{'Id','Posting_Date__c'});
                		currenBTGsQuery.setWhereClause('Id in:sObjRecs');
                	
                	SoqlUtil.ChildRelationship currentBtsQuery = new SoqlUtil.ChildRelationship(currenBTGsQuery, 'Bank_Transactions__r');
		                currentBtsQuery.addFields(new Set<String>{'Id', 'Post_Date__c', 'Transaction_Date__c'});
		                
		            currenBTGsQuery.addChildRelationship(currentBtsQuery);
		            
		             List<Bank_Transaction_Group__c> currenBTGs = Database.Query(currenBTGsQuery.getQuery());  
		          
                    for(Bank_Transaction_Group__c eachBTG: currenBTGs){
                        //List<Bank_Transaction__c> bts = eachBTG.bank_transactions__r;
                        for(Bank_Transaction__c eachBT:eachBTG.bank_transactions__r ){
                           eachBT.Post_Date__c =  eachBTG.Posting_Date__c;
                           btsToUpdate.add(eachBT);
                        }
                        
                    }
                    DML.updateAsUser(btsToUpdate); 
    			} 
    			 
    			if(aeListToUpdate.size() > 0){
    				DML.updateAsUser(aeListToUpdate);
    			}
		    }catch(Exception exe){
		        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(exe.getMessage())));
				system.debug(LoggingLevel.Error, 'EXCEPTION: ' + exe.getMessage() + ' ' + exe.getStackTraceString());
		    }
		
			updateSourceDocs();
			updateGrid();
		}else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No records selected' ));
		}
	}
	
	public void updateSourceDocs(){
		sourceDocs = new List<SourceDoc>();
		for(sObject s : ssCon.getRecords()){
			sourceDocs.add(new SourceDoc(false, s));
		}
	}
	
	public boolean getHasNext(){
		return ssCon.getHasNext();
	}
	
	public boolean getHasPrevious(){
		return ssCon.getHasPrevious();
	}
	
	public void jumpPage(){
		system.debug('pageNo: ' + pageNo);
		ssCon.setPageNumber(pageNo);
		system.debug('get pageNo: ' + ssCon.getPageNumber());
		updateSourceDocs();
	}
	
	public integer getNumberOfPages(){
		decimal noPages = (decimal)ssCon.getResultSize();
		noPages = noPages.divide(ssCon.getPageSize(),0, System.RoundingMode.UP);
		return (integer)noPages;
	}
	
	public void first(){
		ssCon.first();
		pageNo = ssCon.getPageNumber();
		updateSourceDocs();
	}
	
	public void previous(){
		ssCon.previous();
		pageNo = ssCon.getPageNumber();
		updateSourceDocs();
	}
	
	public void next(){
		ssCon.next();
		pageNo = ssCon.getPageNumber();
		updateSourceDocs();
	}
	
	public void last(){
		ssCon.last();
		pageNo = ssCon.getPageNumber();
		updateSourceDocs();
	}
	
	public class SourceDoc{
		public boolean selected {get;set;}
		public sObject sObj {get;set;}
		
		public SourceDoc(boolean selected, sObject sObj){
			this.selected = selected;
			this.sObj = sObj;
		}
	}
}