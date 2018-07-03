public with sharing class AccountingEntryService {   
    
	public static boolean VoidAE = false;  // Set this flag when the accounting entry is about to be voided - KNDY 1692 
    public static boolean ReverseAE = false;  // Set this flag when the accounting entry is about to be voided - KNDY 1692 
    private Date todaysDate = system.today(); 
    public class AESException extends Exception {}
    public static ExceptionService exService = new ExceptionService();
    public enum AEReverseType { AEReverse, AEVoid }
   	Schemautil util = schemautil.getInstance();
    @TestVisible
    public static DateTime VoidDate;
    
    
    public list<String> sourceDocsList{
    	
     	get{
     		List<String> SDList = new List<String>();
    		if(SDList.size() < 1){
    			for(String str: util.getFieldsFromFieldSetString( Accounting_Entry__c.sObjectType , 'Source_documents')){
    				//system.debug(logginglevel.info,'str:'+ str);
					SDList.add(str);
					//system.debug(logginglevel.info,'SDList Inside for loop:'+SDList);
    			}
    		}
    		//system.debug(logginglevel.info,'SDList :'+SDList);
    		return SDList;
    	}
    	set;
    }
    
    public void setDateforTest(Date inputDate){
    	//TODO: Move this to @TestVisible
    	if(Test.isRunningTest()){
    		todaysDate = inputDate;	
    	}
    }
    //Chopping block
    //TODO:Check with SK:Is below valid candidate for dummy bulkify or can we revisit the method usage?
    public boolean isInPeriod(list<Period__c> inputPeriodList){
    	Period__c inputPeriod =inputPeriodList[0];
    	//Datetime VoidDate = system.now();
    	if(inputPeriod != null){
    		//Deprecated PeriodStartDate and PeriodEndDate and used Period_Start__c and Period_End__c
       		
	    	inputPeriod = [Select id, Name, Period_Start__c, Period_End__c
	    					from Period__c where id = :inputPeriod.id];
	    					
	        if(VoidDate >= inputPeriod.Period_Start__c && voidDate < inputPeriod.Period_End__c){
	    		return true;
	    	}else{
	    		return false;
	    	}
    	}else{
    		return false;
    	}
    }
    
    private Map<String,String> AELinesListOfFields = new Map<String,String>{
		'Void__c' => 'Void__c',
		'Period_Name__c' => 'Period_Name__c',
		'Name' => 'Name',
		'GL_Account__c' => 'GL_Account__c',
//		'Exception__c' => 'Exception__c',
		'Company_Name__c' => 'Company_Name__c',
		'Amount_DR__c' => 'Amount_DR__c',
		'Amount_CR__c' => 'Amount_CR__c',
		'Source_ID__c' => 'Source_ID__c',
		'Source_Name__c' => 'Source_Name__c',
		'Accounting_Entry__c' => 'Accounting_Entry__c'
	};
    
    private Map<String,Segment_Definition__c> segmentDefinition;
    private Map<String, Schema.SObjectField> RAELineFieldsMap;
    private static AccountingEntryService instance = null;
    
   
    private AccountingEntryService(){
    	this.segmentDefinition = Segment_Definition__c.getAll();
    	//this.RAELineFieldsMap = Schema.SObjectType.Recurring_Accounting_Entry_Line__c.fields.getMap();
    	//this.RAELineFieldsMap = SchemaUtil.getInstance().getFieldsMap('Recurring_Accounting_Entry_Line__c');
    }
    
    public static AccountingEntryService getInstance(){
    	if(instance == null){
    		instance = new AccountingEntryService();
    	}
    	return instance;
    }
    
    public void assignSourceKey(List<Accounting_Entry__c> accountingEntries){
        for(Accounting_Entry__c ae : accountingEntries){
            if(ae.source_document_object_name__c != null && ae.source_document_object_name__c != ''){
            	if(ae.source_document_object_name__c == 'Manual' || ae.source_document_object_name__c == '' || ae.source_document_object_name__c == null){
            		ae.source_key__c = null;
            		ae.source_reference__c = null;
            	}else{
	                string sourceDocPath = SourceDocPathMap.get(ae.source_document_object_name__c);
	                if(sourceDocPath != null && sourceDocPath != ''){
		                string sourceDocID = string.valueOf(ae.get(sourceDocPath));
		                if( ae.related_accounting_entry__c != null){
		                	//FIN-904 Adding original AE stamp to source key as additional check to support  replayability  and avoid duplicate source key issues
		                    if(ae.Status__c == 'Active'){
		                    	ae.source_key__c = 'REVERSE|' + sourceDocID + '|' + ae.related_accounting_entry__c+'|'+ae.status__c  ;
                            }else{
 		                    	ae.source_key__c = 'REVERSE|' + sourceDocID + '|' + ae.status__c + '|' + ae.batchJobId__c;                               
                            }
                                ae.source_reference__c = 'REVERSE|'+ sourceDocID; 
		                }else {
		                    //ae.source_key__c = sourceDocID;
		                    if(ae.Status__c == 'Active'){
		                        ae.source_key__c = sourceDocID + '|' + ae.status__c ;
		                    }else{
		                        ae.source_key__c = sourceDocID + '|' + ae.status__c + '|' + ae.batchJobId__c;
		                    }
		                    ae.source_reference__c = sourceDocID;
		                }
		                
	                 	if(ae.status__c == 'Obsolete'){
                    		ae.source_key__c += string.valueOf(ae.createddate);
	                    }
	                }
            	}
            	if(ae.source_document_object_name__c ==  'Invoice__c' || ae.source_document_object_name__c == 'Payment__c'){
            		 ae.source_key__c = ae.source_key__c + '|' + ae.company__c;
		             ae.source_reference__c = ae.source_reference__c + '|' + ae.company__c;
            	}
            }
        }
    }
    
    public void ObsoleteRelatedAEs(List<Accounting_Entry__c> AEList){
    	List<Accounting_Entry__c> relatedAEstoObsolete = new List<Accounting_Entry__c>();
    	relatedAEstoObsolete = [Select id, Name, status__c 
								from Accounting_Entry__c 
								where related_accounting_entry__c in :AEList
								and id not in :AEList];
		for(Accounting_Entry__c ae: relatedAEstoObsolete){
			ae.status__c = 'Obsolete';
		}
    	DML.updateAsSystem(relatedAEstoObsolete);
    }
    
    public void CleanRelatedAEs(List<Accounting_Entry__c> AEList){
    	List<Accounting_Entry__c> relatedAEstoDelete = new List<Accounting_Entry__c>();
    	relatedAEstoDelete = [Select id, Name 
								from Accounting_Entry__c where 
								related_accounting_entry__c in :AEList
								and id not in :AEList];
    	DML.deleteAsSystem(relatedAEstoDelete);
    }
    
    public boolean AccountingEntryVoid (List<Accounting_Entry__c> AEList) {
        boolean isSuccess = true;
        VoidAE = true; // KNDY 1692
        Set<ID> aeIds = new Set<ID>();
        List<Accounting_Entry_Line__c> insertAELines = new List<Accounting_Entry_Line__c> ();
        
         //map of old accounting entry id to new accounting entry that voids the old
        Map<Id, Accounting_Entry__c> mNewAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mOldAELines = new Map<Id, List<Accounting_Entry_Line__c>>();
        
        Map<Id, Accounting_Entry__c> mAEs = new Map<Id, Accounting_Entry__c>(AEList);
        
        Map<Id, Accounting_Entry__c> mOldAEs = 
        		new Map<Id, Accounting_Entry__c>([SELECT Work_Order__c, Transaction_Type__c, Currency__c, 
									                Supplier_Payment__c, Supplier_Invoice__c, 
									                Shipment__c, Period__c, Period__r.Open__c,
									                Name, Id,  Customer_Receipt__c, Customer_Invoice__c, 
									                Company__c, Void__c, Related_Accounting_Entry__c, Receiving_Document__c, 
									                Transaction_date__c, finalized_date__c, source_document_object_name__c
							                	FROM Accounting_Entry__c
							                	WHERE Id IN :mAEs.keySet()]);
        
        //Base query string
        Set<String> queryStr = new Set<String>();
        
        for(String fieldName : AELinesListOfFields.values()){
			queryStr.add(fieldName);
		}
        
        //Pull segment definitions
		for(Segment_Definition__c segment:this.segmentDefinition.values()){
			
			if(!AELinesListOfFields.containsKey(segment.Accounting_Entry_Field__c)){
						
				queryStr.add(segment.Accounting_Entry_Field__c);
			
			}
			
		}

        SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', TRUE);
        soql.addFields(queryStr);
        soql.setWhereClause('Accounting_Entry__c IN :AEList');
        
        List<Accounting_Entry_Line__c> oldAELineList = Database.query(soql.getQuery());
        for(Accounting_Entry_Line__c ael : oldAELineList){
        	if(mOldAELines.containsKey(ael.accounting_entry__c)){
        		mOldAELines.get(ael.accounting_entry__c).add(ael);
        	}else{
        		mOldAELines.put(ael.accounting_entry__c, new List<Accounting_Entry_Line__c>{ael});
        	}
        }
        
        for(Accounting_Entry__c oldAE : mOldAEs.values()){
        	
        	if(oldAE.Related_Accounting_Entry__c == null){
        		Accounting_Entry__c iAE = oldAE.clone(false, true);
        		iAE.Related_Accounting_Entry__c = oldAE.Id;
        		//TODO: Assigning the Transaction Date and Finalized date as current may change depending on the new void process design hence this need to be revisited
        		iAE.Transaction_Date__c = system.now(); // assign the datetime when the void AE transaction occurs.
        		iAE.Finalized_Date__c = system.now(); // assign the datetime when the void AE transaction occurs.
        		//system.debug(logginglevel.info,'iAE.Source_Document_Object_Name__c:'+iAE.Source_Document_Object_Name__c);
        		//iAE.Source_Document_Object_Name__c = oldAE.Source_Document_Object_Name__c;
        		iAE.Void__c = false;
        		mNewAEs.put(oldAE.Id, iAE);
        		
        	}
        	
        }
        
        Savepoint sp = Database.setSavepoint();
        
        try{
	        DML.insertAsUser( mNewAEs.values() );
	        
	        for(Accounting_Entry__c oldAE : mOldAEs.values()){
	        	
	        	if(mNewAEs.containsKey(oldAE.Id)){
	        		
	        		Accounting_Entry__c iNewAE = mNewAEs.get(oldAE.Id);
	        		oldAE.Void__c = true;
	        		//oldAE.Related_Accounting_Entry__c = iNewAE.Id;
	        		
	        		if(mOldAELines.containsKey(oldAE.Id)){
	        			
		        		//Process the new Accounting Entry Lines while we have the context of the new and old accounting entries available
		        		List<Accounting_Entry_Line__c> iOldAELs = mOldAELines.get(oldAE.Id);
		        		List<Accounting_Entry_Line__c> iNewAELs = iOldAELs.deepClone(false, false, false);
		        		
		        		for(Accounting_Entry_Line__c ael : iNewAELs){
		        			ael.source_key__c = null;
		        			if(ael.Amount_DR__c != null){
		        				ael.Amount_DR__c = (-1)*ael.Amount_DR__c;
		        			}
		        			if(ael.Amount_CR__c != null){
		        				ael.Amount_CR__c = (-1)*ael.Amount_CR__c;
		        			}
		        			
				            ael.Accounting_Entry__c = iNewAE.id;
		        		}
		        		
		        		insertAELines.addAll(iNewAELs);
	        		} 
	        	}
	        	
	        }
	        
	        DML.updateAsUser( mOldAEs.values() );
	        DML.insertAsUser( insertAELines );
	        
	        VoidAE = false; // Reset the flag once the Voided AEs are inserted
	    }
        catch(Exception ex){
        	VoidAE = false;
        	
        	Database.rollback(sp);
        	isSuccess = false;
        	throw new AESException(ex.getMessage(), ex);
        	
        }
        finally{
        	VoidAE = false;
        }
        
        return isSuccess;
    }
    
    public void voidSourceDocuments(List<sObject> sObjRecs){
    	//TODO: RS This is almost the same as what is in UnfinalizeService.returnAccountingEntries, may need to consolidate logic to simplify later on
    	map<Id, sObject> sObjRecsMap = new map<Id, sObject>();
        sObjRecsMap.putAll(sObjRecs);
    	set<Id> sObjIds = new set<Id>(sObjRecsMap.keyset());
        
        string wherestr = String.join(SchemaUtil.getInstance().relatedCustomObjects('Accounting_Entry__c'), ' in :sObjIds OR ') +' in :sObjIds ';

		string whereClause = '('+ wherestr +')' + ' AND related_accounting_entry__c = null AND Status__c = \'Active\' ORDER BY GL_Date_Time__c ASC '; //limit 1

		SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', TRUE);
		soql.addFields('Source_Documents');
		soql.addFields(new set<string>{'id', 'Period__c' ,'Period__r.Open__c', 'Source_Document_Object_Name__c','Period__r.JE_Cutoff__c','Period__r.AR_Subledger_Cutoff__c','Period__r.AP_Subledger_Closed__c',
							'Period__r.AP_Subledger_Cutoff__c', 'Period__r.Shipment_Subledger_Cutoff__c', 'Period__r.Receiving_Subledger_Cutoff__c','Period__r.AR_Subledger_Closed__c',
							'Period__r.FA_Subledger_Cutoff__c', 'Period__r.Inventory_Subledger_Cutoff__c', 'Period__r.GL_Close__c', 'Period__r.Period_End__c','Period__r.FA_Subledger_Closed__c',
							'Transaction_Date__c', 'Finalized_Date__c','Period__r.Inventory_Subledger_Closed__c','Period__r.Receiving_Subledger_Closed__c','Period__r.Shipment_Subledger_Closed__c'});
		soql.setWhereClause(whereClause);
		List<Accounting_Entry__c> aes = database.query(soql.getQuery());
    	AccountingEntryReversal(AEReverseType.AEVoid, aes);
    }
    
    // Generic method to reverse any accounting entry for reverse / void purpose
    public void AccountingEntryReversal(AEReverseType art, List<Accounting_Entry__c> AEListtoVoid){
        AccountingEntryReversal(art,AEListtoVoid, null);
        
    }
    public void AccountingEntryReversal(AEReverseType art, List<Accounting_Entry__c> AEListtoVoid, string guid){

    	VoidAE = true;
    	if(VoidDate == null){
        	VoidDate = system.now();
        }
        //FIN-903 Make reversal AE with exceptions as obsolete to faciliate regeneration of Reversal AEs
		list<Accounting_Entry__c> reversalAEListWithExceptions =[select id,name from Accounting_Entry__c
																	 where related_accounting_entry__c in :AEListtoVoid
																	 and status__c = 'Active' 
																	 and has_exceptions__c = true ];//Check with SP:Add OR conditions to AEs with Line exceptions NOT needed as this field reflects
		for(Accounting_Entry__c ae : reversalAEListWithExceptions){
		ae.Status__c = 'Obsolete';
	    }
	    system.debug('reversalAEListWithExceptions'+reversalAEListWithExceptions);
	    DML.updateAsSystem(reversalAEListWithExceptions);
	    
	    list<accounting_entry__c> existingReverseAE = new list<accounting_entry__c>();
	    existingReverseAE = [select id,name,related_accounting_entry__c from accounting_entry__c
							   where related_accounting_entry__c in :AEListtoVoid
							   and status__c='Active'
							   and has_exceptions__c=false];
							   
		set<id> existingAEwithValidReversals = new set<id>();
		for(accounting_entry__c ae:existingReverseAE)
		{
			existingAEwithValidReversals.add(ae.related_accounting_entry__c);
		}
	    
    	Map<Id, Accounting_Entry__c> originalAEandReversedAEMap = new Map<Id, Accounting_Entry__c>();
    	Map<Id, List<Accounting_Entry_Line__c>> originalAEandReversedAELinesMap = new Map<Id, List<Accounting_Entry_Line__c>>();
		Savepoint sp = Database.setSavepoint();
		try{
	    	SegmentService SS = new SegmentService();
			List<Segment_Definition__c> segDefs = SS.segments; 
			//Add all configured segments to the query
			Set<String> segFields = new Set<String>();
			for(Segment_Definition__c sd : segDefs){
				segFields.add(sd.accounting_entry_field__c);
			}
			
			Set<String> sourceDocs = new Set<String>();
	
			for(String str: sourceDocsList){
				sourceDocs.add(str);
			}

			SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', TRUE);
			soql.addFields(new Set<String>{'Id', 'Name', 'Company__c', 'Currency__c', 'Status__c', 'Period__r.Period_Start__c', 'Period__r.Period_End__c', 'Has_Exceptions__c',
				'Transaction_Type__c', 'Reversed_Journal__c', 'Related_Accounting_Entry__c', 'Transaction_Date__c', 'Finalized_Date__c', 'Posting_Date__c', 'Source_Document_Object_Name__c',
				'Supplier_Invoice__r.Void_Date__c', 'Supplier_Payment__r.Void_Date__c', 'Receiving_Document__r.Void_Date__c', 'Journal_Entry__r.Void_Date__c', 'Customer_Invoice__r.Void_Date__c',
				'Customer_Receipt__r.Void_Date__c ', 'Bank_Transaction_Group__r.Void_Date__c'});
			soql.addFields(sourceDocs);
			soql.setWhereClause('Id IN :AEListtoVoid and Id NOT IN :existingAEwithValidReversals AND Related_Accounting_Entry__c = null AND status__c = \'Active\'');
			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entry_Lines__r');
			//KNDY-10268 - deprecating bank file and bank file line objects - removed references //'bank_file_line__c',
			childRel.addFields(new Set<String>{'amount_dr__c', 'amount_cr__c', 'source_id__c', 'source_name__c' , 'customer_invoice_line__c', 'customer_receipt_line__c', 
												'inventory_transaction__c','supplier_invoice_line__c', 'supplier_payment_line__c', 'shipment_line__c', 'receipt_line__c', 'journal_entry_line__c',
												'COMP_Functional_Conversion_Rate__c', 'COMP_Functional_Currency__c', 'COMP_Functional_Currency_Amount_CR__c', 'COMP_Functional_Currency_Amount_DR__c',
												'COMP_Transaction_Currency__c', 'COMP_Transaction_Currency_Amount_CR__c', 'COMP_Transaction_Currency_Amount_DR__c', 'CONSOL_Functional_Conversion_Rate__c',
												'CONSOL_Functional_Currency__c', 'CONSOL_Functional_Currency_Amount_CR__c','CONSOL_Functional_Currency_Amount_DR__c', 'CONSOL_Reporting_Conversion_Rate__c',
												'CONSOL_Reporting_Currency__c', 'CONSOL_Reporting_Currency_Amount_CR__c', 'CONSOL_Reporting_Currency_Amount_DR__c', 'CONSOL_Transaction_Currency__c',
												'CONSOL_Transaction_Currency_Amount_CR__c', 'CONSOL_Transaction_Currency_Amount_DR__c', 'STAT_Functional_Conversion_Rate__c', 'STAT_Functional_Currency__c',
												'STAT_Functional_Currency_Amount_CR__c','STAT_Functional_Currency_Amount_DR__c', 'STAT_Reporting_Conversion_Rate__c', 'STAT_Reporting_Currency__c',
												'STAT_Reporting_Currency_Amount_CR__c', 'STAT_Reporting_Currency_Amount_DR__c', 'STAT_Transaction_Currency__c', 'STAT_Transaction_Currency_Amount_CR__c',
												'STAT_Transaction_Currency_Amount_DR__c', 'SUB_Functional_Conversion_Rate__c', 'SUB_Functional_Currency__c', 'SUB_Functional_Currency_Amount_CR__c',
												'SUB_Functional_Currency_Amount_DR__c', 'SUB_Reporting_Conversion_Rate__c', 'SUB_Reporting_Currency__c', 'SUB_Reporting_Currency_Amount_CR__c',
												'SUB_Reporting_Currency_Amount_DR__c', 'SUB_Transaction_Currency__c', 'SUB_Transaction_Currency_Amount_CR__c', 'SUB_Transaction_Currency_Amount_DR__c',
												'accounting_code__c'});
			childRel.addFields(segFields);

			soql.addChildRelationship(childRel);

			//system.debug(logginglevel.info,'query:' +query);
	
	    	List<Accounting_Entry__c> originalAEList = database.query(soql.getQuery());
			//system.debug(logginglevel.info,'originalAEList:' +originalAEList);
			for(Accounting_Entry__c originalAE : originalAEList){
				
				if(originalAE.has_exceptions__c){
					continue;
				}
				
				DateTime iVoidDate;

				//KNDY-7410
				//boolean hasVoidDate = ((Id)originalAE.get(AccountingEntryService.SourceDocPathMap.get(originalAE.Source_Document_Object_Name__c))).getSobjectType().getDescribe().fields.getMap().containsKey('void_date__c');
				SchemaUtil util = SchemaUtil.getInstance();
				Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(((Id)originalAE.get(AccountingEntryService.SourceDocPathMap.get(originalAE.Source_Document_Object_Name__c))).getSobjectType().getDescribe().fields.getMap());
				boolean hasVoidDate = fieldsMap.containsKey('void_date__c');     
		        
		        system.debug('hasVoidDate: ' + hasVoidDate);
		        if(hasVoidDate && originalAE.Source_Document_Object_Name__c != null 
		        		&& originalAE.Source_Document_Object_Name__c != '' 
		        		&& originalAE.Source_Document_Object_Name__c != 'Manual'){
		        			
		        	string sourceDocumentObjectName = AccountingEntryService.SourceDocPathMap.get(originalAE.Source_Document_Object_Name__c);
		        	string voidDatePath = sourceDocumentObjectName.replace('__c', '__r.') + 'void_date__c'; 
		        	if(AccountingRuleService.getValue(voidDatePath, originalAE) != null){
		        		iVoidDate = getLocalDateTime(datetime.valueOf(AccountingRuleService.getValue(voidDatePath, originalAE)));
		        	}
		        	system.debug(iVoidDate);
		        	iVoidDate = iVoidDate == null ? VoidDate : iVoidDate;
		        }else{
		        	iVoidDate = VoidDate;
		        }
	    		
				//Clone the original accounting entry without id
				system.debug('cloning entry ****');
                Accounting_Entry__c reversedAE = originalAE.clone(false, true, false, false);
	
				reversedAE.Related_Accounting_Entry__c = originalAE.id;
				reversedAE.Period__c = null;
				if(guid != null){
					reversedAE.batchjobid__c = guid;
					reversedAE.status__c = 'Draft';
				}
				if(art == AEReverseType.AEVoid){ // For Void, the TD and FD should be the datetime when user performs void
					reversedAE.Transaction_Date__c = iVoidDate;
					reversedAE.Finalized_Date__c = iVoidDate;
					reversedAE.Posting_Date__c = iVoidDate; 
				} else { // For Reverse, the TD, FD should be the first day of the next period which is nothing but the last day of the current open period
					reversedAE.Transaction_Date__c = originalAE.Period__r.Period_End__c;
					reversedAE.Finalized_Date__c = originalAE.Period__r.Period_End__c;
					reversedAE.Posting_Date__c = originalAE.Period__r.Period_End__c;
				}
				system.debug(logginglevel.info,'reversedAE.Transaction_Date__c:'+reversedAE.Transaction_Date__c+'  reversedAE.Finalized_Date__c:'+reversedAE.Finalized_Date__c);
				//Deep clone the ae lines 
				List<Accounting_Entry_Line__c> reversedAELines = originalAE.Accounting_Entry_Lines__r.deepClone(false, false, false);
				
				//Reverse the CR/DR amounts
				for(Accounting_Entry_Line__c reversedAEL : reversedAELines){
					reversedAEL.accounting_entry__c = null;
					if(reversedAEL.amount_cr__c != 0 || reversedAEL.COMP_Functional_Currency_Amount_CR__c != 0){
						reversedAEL.amount_dr__c = reversedAEL.amount_cr__c;
						reversedAEL.amount_cr__c = 0;
						
						reversedAEL.COMP_Transaction_Currency_Amount_DR__c = reversedAEL.COMP_Transaction_Currency_Amount_CR__c;
						reversedAEL.COMP_Transaction_Currency_Amount_CR__c = 0;
						reversedAEL.COMP_Functional_Currency_Amount_DR__c = reversedAEL.COMP_Functional_Currency_Amount_CR__c;
						reversedAEL.COMP_Functional_Currency_Amount_CR__c = 0;
						
						reversedAEL.CONSOL_Transaction_Currency_Amount_DR__c = reversedAEL.CONSOL_Transaction_Currency_Amount_CR__c;
						reversedAEL.CONSOL_Transaction_Currency_Amount_CR__c = 0;
						reversedAEL.CONSOL_Functional_Currency_Amount_DR__c = reversedAEL.CONSOL_Functional_Currency_Amount_CR__c;
						reversedAEL.CONSOL_Functional_Currency_Amount_CR__c = 0;
						reversedAEL.CONSOL_Reporting_Currency_Amount_DR__c = reversedAEL.CONSOL_Reporting_Currency_Amount_CR__c;
						reversedAEL.CONSOL_Reporting_Currency_Amount_CR__c = 0;
						
						reversedAEL.STAT_Transaction_Currency_Amount_DR__c = reversedAEL.STAT_Transaction_Currency_Amount_CR__c;
						reversedAEL.STAT_Transaction_Currency_Amount_CR__c = 0;
						reversedAEL.STAT_Functional_Currency_Amount_DR__c = reversedAEL.STAT_Functional_Currency_Amount_CR__c;
						reversedAEL.STAT_Functional_Currency_Amount_CR__c = 0;
						reversedAEL.STAT_Reporting_Currency_Amount_DR__c = reversedAEL.STAT_Reporting_Currency_Amount_CR__c;
						reversedAEL.STAT_Reporting_Currency_Amount_CR__c = 0;
											
						reversedAEL.SUB_Transaction_Currency_Amount_DR__c = reversedAEL.SUB_Transaction_Currency_Amount_CR__c;
						reversedAEL.SUB_Transaction_Currency_Amount_CR__c = 0;
						reversedAEL.SUB_Functional_Currency_Amount_DR__c = reversedAEL.SUB_Functional_Currency_Amount_CR__c;
						reversedAEL.SUB_Functional_Currency_Amount_CR__c = 0;
						reversedAEL.SUB_Reporting_Currency_Amount_DR__c = reversedAEL.SUB_Reporting_Currency_Amount_CR__c;
						reversedAEL.SUB_Reporting_Currency_Amount_CR__c = 0;
						
					}
					else if(reversedAEL.amount_dr__c != 0 || reversedAEL.COMP_Functional_Currency_Amount_DR__c != 0){
						reversedAEL.amount_cr__c = reversedAEL.amount_dr__c;
						reversedAEL.amount_dr__c = 0;
						
						reversedAEL.COMP_Transaction_Currency_Amount_CR__c = reversedAEL.COMP_Transaction_Currency_Amount_DR__c;
						reversedAEL.COMP_Transaction_Currency_Amount_DR__c = 0;
						reversedAEL.COMP_Functional_Currency_Amount_CR__c = reversedAEL.COMP_Functional_Currency_Amount_DR__c;
						reversedAEL.COMP_Functional_Currency_Amount_DR__c = 0;
						
						reversedAEL.CONSOL_Transaction_Currency_Amount_CR__c = reversedAEL.CONSOL_Transaction_Currency_Amount_DR__c;
						reversedAEL.CONSOL_Transaction_Currency_Amount_DR__c = 0;
						reversedAEL.CONSOL_Functional_Currency_Amount_CR__c = reversedAEL.CONSOL_Functional_Currency_Amount_DR__c;
						reversedAEL.CONSOL_Functional_Currency_Amount_DR__c = 0;
						reversedAEL.CONSOL_Reporting_Currency_Amount_CR__c = reversedAEL.CONSOL_Reporting_Currency_Amount_DR__c;
						reversedAEL.CONSOL_Reporting_Currency_Amount_DR__c = 0;
						
						reversedAEL.STAT_Transaction_Currency_Amount_CR__c = reversedAEL.STAT_Transaction_Currency_Amount_DR__c;
						reversedAEL.STAT_Transaction_Currency_Amount_DR__c = 0;
						reversedAEL.STAT_Functional_Currency_Amount_CR__c = reversedAEL.STAT_Functional_Currency_Amount_DR__c;
						reversedAEL.STAT_Functional_Currency_Amount_DR__c = 0;
						reversedAEL.STAT_Reporting_Currency_Amount_CR__c = reversedAEL.STAT_Reporting_Currency_Amount_DR__c;
						reversedAEL.STAT_Reporting_Currency_Amount_DR__c = 0;
											
						reversedAEL.SUB_Transaction_Currency_Amount_CR__c = reversedAEL.SUB_Transaction_Currency_Amount_DR__c;
						reversedAEL.SUB_Transaction_Currency_Amount_DR__c = 0;
						reversedAEL.SUB_Functional_Currency_Amount_CR__c = reversedAEL.SUB_Functional_Currency_Amount_DR__c;
						reversedAEL.SUB_Functional_Currency_Amount_DR__c = 0;
						reversedAEL.SUB_Reporting_Currency_Amount_CR__c = reversedAEL.SUB_Reporting_Currency_Amount_DR__c;
						reversedAEL.SUB_Reporting_Currency_Amount_DR__c = 0;
					}
		            
				}
				
				//Store in a map for later access
				originalAEandReversedAEMap.put(originalAE.Id, reversedAE);
				originalAEandReversedAELinesMap.put(originalAE.Id, reversedAELines);
			}
		
			if(originalAEandReversedAEMap.keySet().size() > 0){
					
				//Update the accounting entries with the credit memo relationship before inserting
				assignSourceKey(originalAEandReversedAEMap.values());
				DML.upsertAsSystem(); upsert originalAEandReversedAEMap.values() Source_key__c;
				//system.debug(logginglevel.info,'originalAEandReversedAEMap :'+originalAEandReversedAEMap.values());
				
				
				//Run through the records and attach the cloned lines to the new counter accounting entry
				List<Accounting_Entry_Line__c> insertReversedAELines = new List<Accounting_Entry_Line__c>();
				List<Accounting_Entry__c> originalAEUpdList = new List<Accounting_Entry__c>();
				
				for(Id aeId : originalAEandReversedAEMap.keySet()){
					Accounting_Entry__c originalAE = new Accounting_Entry__c(Id = aeId);
					Accounting_Entry__c reversedAE = originalAEandReversedAEMap.get(aeId);
					
					if(originalAEandReversedAELinesMap.containsKey(aeId)){
						
						List<Accounting_Entry_Line__c> reversedAELs = originalAEandReversedAELinesMap.get(aeId);
						
						for(Accounting_Entry_Line__c reversedAEL : reversedAELs){
							reversedAEL.Accounting_Entry__c = reversedAE.Id;
							reversedAEL.Transaction_Date__c = reversedAE.Transaction_Date__c.date();
						}
						
						insertReversedAELines.addAll(reversedAELs);
						
					}
					
				}
				system.debug(logginglevel.info,'voidDate in AES.accountingentryreversal:'+voidDate);
				if(insertReversedAELines.size() > 0){
					DML.insertAsSystem(insertReversedAELines);
				}
			  //FIN-903 Swap draft status to Active for completed Reversal AEs
			  validateCompletedReversalAccounting(originalAEandReversedAEMap);
				
			}
			
		}catch(Exception ex){
			VoidAE = false;
			Database.rollback(sp);
			system.debug(logginglevel.info,'ex.getMessage() : '+ex.getMessage());
          	throw new AESException(ex.getMessage(), ex);
          	
		}
    }
    //FIN-903 Adding replaybility logic for reversal lines    
   	public void validateCompletedReversalAccounting(map<Id, sobject> originalAEandReversedAEMap){
		
				map<id,accounting_entry__c> mCompletedReverseAEs = new map<id,accounting_entry__c>();
				list<accounting_entry__c> FinalReversalAEs = [select id,name,total_lines__c,related_accounting_entry__r.total_lines__c,source_key__c
															  from accounting_entry__c 
				                                              where id in :originalAEandReversedAEMap.values() ];
			    for(accounting_entry__c reversalAE:FinalReversalAEs)				
				{
					if(reversalAE.total_lines__c==reversalAE.related_accounting_entry__r.total_lines__c)
					{
						reversalAE.status__c='Active';
						mCompletedReverseAEs.put(reversalAE.id,reversalAE);
					}
				}	
	    system.debug('reversalAEsbeforeAssign'+mCompletedReverseAEs);
		assignSourceKey(mCompletedReverseAEs.values());
	    system.debug('reversalAEsafterAssign'+mCompletedReverseAEs);
				
	    DML.updateAsSystem(mCompletedReverseAEs.values());
	} 
    // Generic method to reverse incremental lines from a voided source doc
    public void AccountingEntryLineReversal(AEReverseType art, List<Accounting_Entry_Line__c> AELineListtoVoid){
		AccountingEntryLineReversal( art,AELineListtoVoid, null);   	
    
    }
    
    public void AccountingEntryLineReversal(AEReverseType art, List<Accounting_Entry_Line__c> AELineListtoVoid, string guid){
    	VoidAE = true;
    	if(VoidDate == null){
        	VoidDate = system.now();
        }
        
    	Map<Id, Accounting_Entry__c> originalAEandReversedAEMap = new Map<Id, Accounting_Entry__c>();
    	Map<Id, List<Accounting_Entry_Line__c>> originalAEandReversedAELinesMap = new Map<Id, List<Accounting_Entry_Line__c>>();
		Savepoint sp = Database.setSavepoint();
		try{
	    	SegmentService SS = new SegmentService();
			List<Segment_Definition__c> segDefs = SS.segments; 
			//Add all configured segments to the query
			Set<String> segFields = new Set<String>();
			for(Segment_Definition__c sd : segDefs){
				segFields.add(sd.accounting_entry_field__c);
			}
			
			Set<String> sourceDocs = new Set<String>();
	
			for(String str: sourceDocsList){
				sourceDocs.add(str);
			}
			//FIN-903 Make reversal AE with exceptions as obsolete to faciliate regeneration of Reversal AEs
			list<Accounting_Entry__c> reversalAEListWithExceptions =[select id,name from Accounting_Entry__c
																		 where related_accounting_entry__c in (select accounting_entry__c from accounting_entry_line__c where id in :AELineListtoVoid )
																		 and status__c = 'Active' 
																		 and has_exceptions__c = true ];//Check with SP:Add OR conditions to AEs with Line exceptions NOT needed as this field reflects
			for(Accounting_Entry__c ae : reversalAEListWithExceptions){
			ae.Status__c = 'Obsolete';
		    }
		    system.debug('reversalAEListWithExceptions'+reversalAEListWithExceptions);
		    DML.updateAsSystem(reversalAEListWithExceptions);
		   
			 List<Accounting_Entry_Line__c> reversalAELs = [SELECT Id, Related_Accounting_Entry_Line__c 
														   FROM Accounting_Entry_Line__c 
														   WHERE Related_Accounting_Entry_Line__c IN :AELineListtoVoid 
														   and accounting_entry__r.status__c='Active'
														   and accounting_entry__r.has_exceptions__c=false];
			 system.debug('existing reversal aels: ' + reversalAELs);
			 set<Id> reversalAELIDs = new set<Id>();
			 for(Accounting_Entry_Line__c ael : reversalAELs){

				reversalAELIDs.add(ael.Related_Accounting_Entry_Line__c);
			}

			SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', false);//KNDY-20410 need to clone AE in system mode.
			soql.addFields(new Set<String>{'Id', 'company__c', 'Currency__c', 'status__c', 'Period__r.Period_Start__c' , 'Period__r.Period_End__c', 'Has_Exceptions__c', 'transaction_type__c',
											'Reversed_Journal__c', 'Related_Accounting_Entry__c', 'Transaction_Date__c', 'Finalized_Date__c', 'posting_date__c', 'Source_Document_Object_Name__c',
											'supplier_invoice__r.void_date__c', 'supplier_payment__r.void_date__c', 'receiving_document__r.void_date__c','journal_entry__r.void_date__c',
											'customer_invoice__r.void_date__c', 'customer_receipt__r.void_date__c', 'Bank_Transaction_Group__r.Void_Date__c'});
			soql.addFields(sourceDocs);
			soql.setWhereClause('Id IN (Select Accounting_Entry__c from Accounting_Entry_Line__c where id IN :AELineListtoVoid) and Related_Accounting_Entry__c = null AND status__c = \'Active\'');
			
			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entry_Lines__r');
			//KNDY-10268 - deprecating bank file and bank file line objects - removed references 'bank_file_line__c', 
			childRel.addFields(new Set<String>{ 'Id', 'subtransaction_type__c', 'line_type__c', 'accounting_rule__c', 'amount_dr__c', 'amount_cr__c', 'source_id__c', 'source_name__c' ,
												'customer_invoice_line__c', 'customer_receipt_line__c', 'inventory_transaction__c', 'supplier_invoice_line__c', 'supplier_payment_line__c',
												'shipment_line__c', 'receipt_line__c', 'journal_entry_line__c', 'COMP_Functional_Conversion_Rate__c', 'COMP_Functional_Currency__c',
												'COMP_Functional_Currency_Amount_CR__c', 'COMP_Functional_Currency_Amount_DR__c', 'COMP_Transaction_Currency__c', 'COMP_Transaction_Currency_Amount_CR__c',
												'COMP_Transaction_Currency_Amount_DR__c', 'CONSOL_Functional_Conversion_Rate__c', 'CONSOL_Functional_Currency__c', 'CONSOL_Functional_Currency_Amount_CR__c',
												'CONSOL_Functional_Currency_Amount_DR__c', 'CONSOL_Reporting_Conversion_Rate__c', 'CONSOL_Reporting_Currency__c', 'CONSOL_Reporting_Currency_Amount_CR__c',
												'CONSOL_Reporting_Currency_Amount_DR__c','CONSOL_Transaction_Currency__c', 'CONSOL_Transaction_Currency_Amount_CR__c',
												'CONSOL_Transaction_Currency_Amount_DR__c', 'STAT_Functional_Conversion_Rate__c', 'STAT_Functional_Currency__c', 'STAT_Functional_Currency_Amount_CR__c',
												'STAT_Functional_Currency_Amount_DR__c', 'STAT_Reporting_Conversion_Rate__c', 'STAT_Reporting_Currency__c', 'STAT_Reporting_Currency_Amount_CR__c',
												'STAT_Reporting_Currency_Amount_DR__c','STAT_Transaction_Currency__c', 'STAT_Transaction_Currency_Amount_CR__c', 'STAT_Transaction_Currency_Amount_DR__c',
												'SUB_Functional_Conversion_Rate__c', 'SUB_Functional_Currency__c', 'SUB_Functional_Currency_Amount_CR__c', 'SUB_Functional_Currency_Amount_DR__c',
												'SUB_Reporting_Conversion_Rate__c', 'SUB_Reporting_Currency__c', 'SUB_Reporting_Currency_Amount_CR__c', 'SUB_Reporting_Currency_Amount_DR__c',
												'SUB_Transaction_Currency__c', 'SUB_Transaction_Currency_Amount_CR__c', 'SUB_Transaction_Currency_Amount_DR__c', 'accounting_code__c'});
			childRel.addFields(segFields);
			childRel.setWhereClause(' Id IN :AELineListtoVoid AND Id NOT IN :reversalAELIDs ');

			soql.addChildRelationship(childRel);

			//system.debug(logginglevel.info,'query:' +query);

	    	List<Accounting_Entry__c> originalAEList = database.query(soql.getQuery());
			system.debug(logginglevel.info,'originalAEList:' +originalAEList);
			for(Accounting_Entry__c originalAE : originalAEList){
				
				//If we find there are exceptions, or that no lines are returned for reversal, just move on to the next entry
				if(originalAE.has_exceptions__c || originalAE.Accounting_Entry_Lines__r.size() == 0){
					continue;
				}
				
				DateTime iVoidDate;
                //KNDY-11461
				//boolean hasVoidDate = ((Id)originalAE.get(AccountingEntryService.SourceDocPathMap.get(originalAE.Source_Document_Object_Name__c))).getSobjectType().getDescribe().fields.getMap().containsKey('void_date__c');
		        Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(((Id)originalAE.get(AccountingEntryService.SourceDocPathMap.get(originalAE.Source_Document_Object_Name__c))).getSobjectType().getDescribe().fields.getMap());
                boolean hasVoidDate = fieldsMap.containsKey('void_date__c');  
                system.debug('hasVoidDate: ' + hasVoidDate);
		        if(hasVoidDate && originalAE.Source_Document_Object_Name__c != null 
		        		&& originalAE.Source_Document_Object_Name__c != '' 
		        		&& originalAE.Source_Document_Object_Name__c != 'Manual'){
		        			
		        	string sourceDocumentObjectName = AccountingEntryService.SourceDocPathMap.get(originalAE.Source_Document_Object_Name__c);
		        	string voidDatePath = sourceDocumentObjectName.replace('__c', '__r.') + 'void_date__c'; 
		        	if(AccountingRuleService.getValue(voidDatePath, originalAE) != null){
		        		iVoidDate = getLocalDateTime(datetime.valueOf(AccountingRuleService.getValue(voidDatePath, originalAE)));
		        	}
		        	system.debug(iVoidDate);
		        	iVoidDate = iVoidDate == null ? VoidDate : iVoidDate;
		        }else{
		        	iVoidDate = VoidDate;
		        }
	    		
				//Clone the original accounting entry without id
				Accounting_Entry__c reversedAE = originalAE.clone(false, true, false, false);
	
				reversedAE.Related_Accounting_Entry__c = originalAE.id;
				reversedAE.Period__c = null;
				reversedAE.status__c = 'Active';
				
                system.debug('the guid inside reversal ****' + guid);
				if(guid != null){
					reversedAE.batchjobid__c = guid;
					reversedAE.status__c = 'Draft';
				}
				if(art == AEReverseType.AEVoid){ // For Void, the TD and FD should be the datetime when user performs void
					reversedAE.Transaction_Date__c = iVoidDate;
					reversedAE.Finalized_Date__c = iVoidDate;
					reversedAE.Posting_Date__c = iVoidDate; 
				} else { // For Reverse, the TD, FD should be the first day of the next period which is nothing but the last day of the current open period
					reversedAE.Transaction_Date__c = originalAE.Period__r.Period_End__c;
					reversedAE.Finalized_Date__c = originalAE.Period__r.Period_End__c;
					reversedAE.Posting_Date__c = originalAE.Period__r.Period_End__c;
				}
				system.debug(logginglevel.info,'reversedAE.Transaction_Date__c:'+reversedAE.Transaction_Date__c+'  reversedAE.Finalized_Date__c:'+reversedAE.Finalized_Date__c);
				//Deep clone the ae lines 
				List<Accounting_Entry_Line__c> reversedAELines = new List<Accounting_Entry_Line__c>();//originalAE.Accounting_Entry_Lines__r.deepClone(false, false, false);
				
				//Reverse the CR/DR amounts
				for(Accounting_Entry_Line__c sourceAEL : originalAE.Accounting_Entry_Lines__r){
					Accounting_Entry_Line__c reversedAEL = sourceAEL.clone(false, true, false, false);
					reversedAEL.accounting_entry__c = null;
					reversedAEL.related_accounting_entry_line__c = sourceAEL.Id;
					if(reversedAEL.amount_cr__c != 0 || reversedAEL.COMP_Functional_Currency_Amount_CR__c != 0){
						reversedAEL.amount_dr__c = reversedAEL.amount_cr__c;
						reversedAEL.amount_cr__c = 0;
						
						reversedAEL.COMP_Transaction_Currency_Amount_DR__c = reversedAEL.COMP_Transaction_Currency_Amount_CR__c;
						reversedAEL.COMP_Transaction_Currency_Amount_CR__c = 0;
						reversedAEL.COMP_Functional_Currency_Amount_DR__c = reversedAEL.COMP_Functional_Currency_Amount_CR__c;
						reversedAEL.COMP_Functional_Currency_Amount_CR__c = 0;
						
						reversedAEL.CONSOL_Transaction_Currency_Amount_DR__c = reversedAEL.CONSOL_Transaction_Currency_Amount_CR__c;
						reversedAEL.CONSOL_Transaction_Currency_Amount_CR__c = 0;
						reversedAEL.CONSOL_Functional_Currency_Amount_DR__c = reversedAEL.CONSOL_Functional_Currency_Amount_CR__c;
						reversedAEL.CONSOL_Functional_Currency_Amount_CR__c = 0;
						reversedAEL.CONSOL_Reporting_Currency_Amount_DR__c = reversedAEL.CONSOL_Reporting_Currency_Amount_CR__c;
						reversedAEL.CONSOL_Reporting_Currency_Amount_CR__c = 0;
						
						reversedAEL.STAT_Transaction_Currency_Amount_DR__c = reversedAEL.STAT_Transaction_Currency_Amount_CR__c;
						reversedAEL.STAT_Transaction_Currency_Amount_CR__c = 0;
						reversedAEL.STAT_Functional_Currency_Amount_DR__c = reversedAEL.STAT_Functional_Currency_Amount_CR__c;
						reversedAEL.STAT_Functional_Currency_Amount_CR__c = 0;
						reversedAEL.STAT_Reporting_Currency_Amount_DR__c = reversedAEL.STAT_Reporting_Currency_Amount_CR__c;
						reversedAEL.STAT_Reporting_Currency_Amount_CR__c = 0;
											
						reversedAEL.SUB_Transaction_Currency_Amount_DR__c = reversedAEL.SUB_Transaction_Currency_Amount_CR__c;
						reversedAEL.SUB_Transaction_Currency_Amount_CR__c = 0;
						reversedAEL.SUB_Functional_Currency_Amount_DR__c = reversedAEL.SUB_Functional_Currency_Amount_CR__c;
						reversedAEL.SUB_Functional_Currency_Amount_CR__c = 0;
						reversedAEL.SUB_Reporting_Currency_Amount_DR__c = reversedAEL.SUB_Reporting_Currency_Amount_CR__c;
						reversedAEL.SUB_Reporting_Currency_Amount_CR__c = 0;
						
					}
					else if(reversedAEL.amount_dr__c != 0 || reversedAEL.COMP_Functional_Currency_Amount_DR__c != 0){
						reversedAEL.amount_cr__c = reversedAEL.amount_dr__c;
						reversedAEL.amount_dr__c = 0;
						
						reversedAEL.COMP_Transaction_Currency_Amount_CR__c = reversedAEL.COMP_Transaction_Currency_Amount_DR__c;
						reversedAEL.COMP_Transaction_Currency_Amount_DR__c = 0;
						reversedAEL.COMP_Functional_Currency_Amount_CR__c = reversedAEL.COMP_Functional_Currency_Amount_DR__c;
						reversedAEL.COMP_Functional_Currency_Amount_DR__c = 0;
						
						reversedAEL.CONSOL_Transaction_Currency_Amount_CR__c = reversedAEL.CONSOL_Transaction_Currency_Amount_DR__c;
						reversedAEL.CONSOL_Transaction_Currency_Amount_DR__c = 0;
						reversedAEL.CONSOL_Functional_Currency_Amount_CR__c = reversedAEL.CONSOL_Functional_Currency_Amount_DR__c;
						reversedAEL.CONSOL_Functional_Currency_Amount_DR__c = 0;
						reversedAEL.CONSOL_Reporting_Currency_Amount_CR__c = reversedAEL.CONSOL_Reporting_Currency_Amount_DR__c;
						reversedAEL.CONSOL_Reporting_Currency_Amount_DR__c = 0;
						
						reversedAEL.STAT_Transaction_Currency_Amount_CR__c = reversedAEL.STAT_Transaction_Currency_Amount_DR__c;
						reversedAEL.STAT_Transaction_Currency_Amount_DR__c = 0;
						reversedAEL.STAT_Functional_Currency_Amount_CR__c = reversedAEL.STAT_Functional_Currency_Amount_DR__c;
						reversedAEL.STAT_Functional_Currency_Amount_DR__c = 0;
						reversedAEL.STAT_Reporting_Currency_Amount_CR__c = reversedAEL.STAT_Reporting_Currency_Amount_DR__c;
						reversedAEL.STAT_Reporting_Currency_Amount_DR__c = 0;
											
						reversedAEL.SUB_Transaction_Currency_Amount_CR__c = reversedAEL.SUB_Transaction_Currency_Amount_DR__c;
						reversedAEL.SUB_Transaction_Currency_Amount_DR__c = 0;
						reversedAEL.SUB_Functional_Currency_Amount_CR__c = reversedAEL.SUB_Functional_Currency_Amount_DR__c;
						reversedAEL.SUB_Functional_Currency_Amount_DR__c = 0;
						reversedAEL.SUB_Reporting_Currency_Amount_CR__c = reversedAEL.SUB_Reporting_Currency_Amount_DR__c;
						reversedAEL.SUB_Reporting_Currency_Amount_DR__c = 0;
					}
		            reversedAELines.add(reversedAEL);
				}
				
				//Store in a map for later access
				originalAEandReversedAEMap.put(originalAE.Id, reversedAE);
				originalAEandReversedAELinesMap.put(originalAE.Id, reversedAELines);
			}
			
			if(originalAEandReversedAEMap.keySet().size() > 0){
				
				//Update the accounting entries with the credit memo relationship before inserting
				assignSourceKey(originalAEandReversedAEMap.values());
				DML.upsertAsSystem(); upsert originalAEandReversedAEMap.values() Source_key__c;
				//system.debug(logginglevel.info,'originalAEandReversedAEMap :'+originalAEandReversedAEMap.values());
				
				
				//Run through the records and attach the cloned lines to the new counter accounting entry
				List<Accounting_Entry_Line__c> insertReversedAELines = new List<Accounting_Entry_Line__c>();
				List<Accounting_Entry__c> originalAEUpdList = new List<Accounting_Entry__c>();
				
				for(Id aeId : originalAEandReversedAEMap.keySet()){
					Accounting_Entry__c originalAE = new Accounting_Entry__c(Id = aeId);
					Accounting_Entry__c reversedAE = originalAEandReversedAEMap.get(aeId);
					
					if(originalAEandReversedAELinesMap.containsKey(aeId)){
						
						List<Accounting_Entry_Line__c> reversedAELs = originalAEandReversedAELinesMap.get(aeId);
						
						for(Accounting_Entry_Line__c reversedAEL : reversedAELs){
							reversedAEL.Accounting_Entry__c = reversedAE.Id;
							reversedAEL.Transaction_Date__c = reversedAE.Transaction_Date__c.date();
						}
						
						insertReversedAELines.addAll(reversedAELs);
						
					}
					
				}
				system.debug(logginglevel.info,'voidDate in AES.accountingentryreversal:'+voidDate);
				if(insertReversedAELines.size() > 0){
					DML.insertAsSystem(insertReversedAELines);
				}
				//FIN-903 Swap draft status to Active for completed Reversal AEs
			    validateCompletedReversalAccounting(originalAEandReversedAEMap);
			}
		}catch(Exception ex){
			VoidAE = false;
			Database.rollback(sp);
			system.debug(logginglevel.info,'ex.getMessage() : '+ex.getMessage());
          	throw new AESException(ex.getMessage(), ex);
		}
    }
    
    public Accounting_Entry__c AccountingEntryReversal(AEReverseType art, Accounting_Entry__c AEtoVoid, sObject SOtoVoid){
    	VoidAE = true;
		Accounting_Entry__c insertReversedAE = new Accounting_Entry__c();
    	if(VoidDate == null){
        	VoidDate = system.now();			
			DateTime iVoidDate;
			
			//KNDY-7410
			//boolean hasVoidDate = ((Id)originalAE.get(AccountingEntryService.SourceDocPathMap.get(originalAE.Source_Document_Object_Name__c))).getSobjectType().getDescribe().fields.getMap().containsKey('void_date__c');
			SchemaUtil util = SchemaUtil.getInstance();
			Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(((Id)AEtoVoid.get(AccountingEntryService.SourceDocPathMap.get(AEtoVoid.Source_Document_Object_Name__c))).getSobjectType().getDescribe().fields.getMap());
			boolean hasVoidDate = fieldsMap.containsKey('void_date__c');     	        
	        
	        if(hasVoidDate && AEtoVoid.Source_Document_Object_Name__c != null 
	        		&& AEtoVoid.Source_Document_Object_Name__c != '' 
	        		&& AEtoVoid.Source_Document_Object_Name__c != 'Manual'){
	        			
	        	if(DateTime.valueOf(SOtoVoid.get('Void_date__c')) != null){
	        		iVoidDate = getLocalDateTime(DateTime.valueOf(SOtoVoid.get('Void_date__c')));
	        	}
	        	system.debug(iVoidDate);
	        	iVoidDate = iVoidDate == null ? VoidDate : iVoidDate;
	        }else{
	        	iVoidDate = VoidDate;
	        }
    		
			//Clone the original accounting entry without id
			Accounting_Entry__c reversedAE = AEtoVoid.clone(false, true, false, false);

			reversedAE.Related_Accounting_Entry__c = AEtoVoid.id;
			reversedAE.Period__c = null;
			if(art == AEReverseType.AEVoid){ // For Void, the TD and FD should be the datetime when user performs void
				reversedAE.Transaction_Date__c = iVoidDate;
				reversedAE.Finalized_Date__c = iVoidDate;
			} else { // For Reverse, the TD, FD should be the first day of the next period which is nothing but the last day of the current open period
				reversedAE.Transaction_Date__c = AEtoVoid.Period__r.Period_End__c;
				reversedAE.Finalized_Date__c = AEtoVoid.Period__r.Period_End__c;
			}
			system.debug(logginglevel.info,'reversedAE.Transaction_Date__c:'+reversedAE.Transaction_Date__c+'  reversedAE.Finalized_Date__c:'+reversedAE.Finalized_Date__c);
			insertReversedAE = reversedAE;
        }        
		return insertReversedAE; 	
    }   
    
    public List<Accounting_Entry_Line__c> AccountingEntryLineReversal(AEReverseType art, Accounting_Entry__c AEtoVoid, List<Accounting_Entry_Line__c> AELineListtoVoid){
		List<Accounting_Entry_Line__c> reversedAELines = AELineListtoVoid.deepClone(false, false, false);
		List<Accounting_Entry_Line__c> insertReversedAELines = new List<Accounting_Entry_Line__c>();
		for(Accounting_Entry_Line__c reversedAEL : reversedAELines){
			if(reversedAEL.amount_cr__c != 0 || reversedAEL.COMP_Functional_Currency_Amount_CR__c != 0){
				reversedAEL.amount_dr__c = reversedAEL.amount_cr__c;
				reversedAEL.amount_cr__c = 0;
				
				reversedAEL.COMP_Transaction_Currency_Amount_DR__c = reversedAEL.COMP_Transaction_Currency_Amount_CR__c;
				reversedAEL.COMP_Transaction_Currency_Amount_CR__c = 0;
				reversedAEL.COMP_Functional_Currency_Amount_DR__c = reversedAEL.COMP_Functional_Currency_Amount_CR__c;
				reversedAEL.COMP_Functional_Currency_Amount_CR__c = 0;
				
				reversedAEL.CONSOL_Transaction_Currency_Amount_DR__c = reversedAEL.CONSOL_Transaction_Currency_Amount_CR__c;
				reversedAEL.CONSOL_Transaction_Currency_Amount_CR__c = 0;
				reversedAEL.CONSOL_Functional_Currency_Amount_DR__c = reversedAEL.CONSOL_Functional_Currency_Amount_CR__c;
				reversedAEL.CONSOL_Functional_Currency_Amount_CR__c = 0;
				reversedAEL.CONSOL_Reporting_Currency_Amount_DR__c = reversedAEL.CONSOL_Reporting_Currency_Amount_CR__c;
				reversedAEL.CONSOL_Reporting_Currency_Amount_CR__c = 0;
				
				reversedAEL.STAT_Transaction_Currency_Amount_DR__c = reversedAEL.STAT_Transaction_Currency_Amount_CR__c;
				reversedAEL.STAT_Transaction_Currency_Amount_CR__c = 0;
				reversedAEL.STAT_Functional_Currency_Amount_DR__c = reversedAEL.STAT_Functional_Currency_Amount_CR__c;
				reversedAEL.STAT_Functional_Currency_Amount_CR__c = 0;
				reversedAEL.STAT_Reporting_Currency_Amount_DR__c = reversedAEL.STAT_Reporting_Currency_Amount_CR__c;
				reversedAEL.STAT_Reporting_Currency_Amount_CR__c = 0;
									
				reversedAEL.SUB_Transaction_Currency_Amount_DR__c = reversedAEL.SUB_Transaction_Currency_Amount_CR__c;
				reversedAEL.SUB_Transaction_Currency_Amount_CR__c = 0;
				reversedAEL.SUB_Functional_Currency_Amount_DR__c = reversedAEL.SUB_Functional_Currency_Amount_CR__c;
				reversedAEL.SUB_Functional_Currency_Amount_CR__c = 0;
				reversedAEL.SUB_Reporting_Currency_Amount_DR__c = reversedAEL.SUB_Reporting_Currency_Amount_CR__c;
				reversedAEL.SUB_Reporting_Currency_Amount_CR__c = 0;
				
			}
			else if(reversedAEL.amount_dr__c != 0 || reversedAEL.COMP_Functional_Currency_Amount_DR__c != 0){
				reversedAEL.amount_cr__c = reversedAEL.amount_dr__c;
				reversedAEL.amount_dr__c = 0;
				
				reversedAEL.COMP_Transaction_Currency_Amount_CR__c = reversedAEL.COMP_Transaction_Currency_Amount_DR__c;
				reversedAEL.COMP_Transaction_Currency_Amount_DR__c = 0;
				reversedAEL.COMP_Functional_Currency_Amount_CR__c = reversedAEL.COMP_Functional_Currency_Amount_DR__c;
				reversedAEL.COMP_Functional_Currency_Amount_DR__c = 0;
				
				reversedAEL.CONSOL_Transaction_Currency_Amount_CR__c = reversedAEL.CONSOL_Transaction_Currency_Amount_DR__c;
				reversedAEL.CONSOL_Transaction_Currency_Amount_DR__c = 0;
				reversedAEL.CONSOL_Functional_Currency_Amount_CR__c = reversedAEL.CONSOL_Functional_Currency_Amount_DR__c;
				reversedAEL.CONSOL_Functional_Currency_Amount_DR__c = 0;
				reversedAEL.CONSOL_Reporting_Currency_Amount_CR__c = reversedAEL.CONSOL_Reporting_Currency_Amount_DR__c;
				reversedAEL.CONSOL_Reporting_Currency_Amount_DR__c = 0;
				
				reversedAEL.STAT_Transaction_Currency_Amount_CR__c = reversedAEL.STAT_Transaction_Currency_Amount_DR__c;
				reversedAEL.STAT_Transaction_Currency_Amount_DR__c = 0;
				reversedAEL.STAT_Functional_Currency_Amount_CR__c = reversedAEL.STAT_Functional_Currency_Amount_DR__c;
				reversedAEL.STAT_Functional_Currency_Amount_DR__c = 0;
				reversedAEL.STAT_Reporting_Currency_Amount_CR__c = reversedAEL.STAT_Reporting_Currency_Amount_DR__c;
				reversedAEL.STAT_Reporting_Currency_Amount_DR__c = 0;
									
				reversedAEL.SUB_Transaction_Currency_Amount_CR__c = reversedAEL.SUB_Transaction_Currency_Amount_DR__c;
				reversedAEL.SUB_Transaction_Currency_Amount_DR__c = 0;
				reversedAEL.SUB_Functional_Currency_Amount_CR__c = reversedAEL.SUB_Functional_Currency_Amount_DR__c;
				reversedAEL.SUB_Functional_Currency_Amount_DR__c = 0;
				reversedAEL.SUB_Reporting_Currency_Amount_CR__c = reversedAEL.SUB_Reporting_Currency_Amount_DR__c;
				reversedAEL.SUB_Reporting_Currency_Amount_DR__c = 0;
			}
            
			reversedAEL.Accounting_Entry__c  = AEtoVoid.id;
			reversedAEL.Transaction_Date__c  = AEtoVoid.Transaction_Date__c.date();
			insertReversedAELines.add(reversedAEL);
		}
		return insertReversedAELines;
	
	    
    }
    //Chopping Block
    // This function takes the AE to adjust and reverse the AE and creates a new AE from the original AE and return it
    public Accounting_Entry__c adjustAE(Accounting_Entry__c AEtoAdjust){
    	SegmentService SS = new SegmentService();
		List<Segment_Definition__c> segDefs = SS.segments; 
		//Add all configured segments to the query
		Set<String> segFields = new Set<String>();
		for(Segment_Definition__c sd : segDefs){
			segFields.add(sd.accounting_entry_field__c);
		}
		
		Id AEID = AEtoAdjust.id;
    	// TODO: build a query from source documents field set on AE so that it can be used for reversal of AE for any source document
    	SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', TRUE);
    	soql.addFields(new Set<String>{ 'Id', 'name', 'company__c', 'Currency__c', 'transaction_type__c', 'Period__c', 'Period__r.Open__c', 'Period__r.Closed__c', 'Customer__c', 'Supplier__c',
    									'Shipment__c', 'Customer_Invoice__c', 'Customer_Receipt__c', 'Receiving_Document__c', 'Supplier_Invoice__c', 'Supplier_Payment__c' , 'Inventory_Change__c',
    									'Work_Order__c', 'Reversed_Journal__c', 'Related_Accounting_Entry__c'});
    	soql.setWhereClause('Id = :AEID');
    	SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entry_Lines__r');
    	childRel.addFields(new Set<String>{ 'Id', 'subtransaction_type__c', 'line_type__c', 'amount_dr__c', 'amount_cr__c', 'source_id__c', 'source_name__c'});
    	childRel.addFields('segFields');

    	soql.addChildRelationship(childRel);
    	
    	AEtoAdjust =  database.query(soql.getQuery());

    	List<Accounting_Entry__c> AEListtoReverse = new List<Accounting_Entry__c>();
    	AEListtoReverse.add(AEtoAdjust);
    	Savepoint sp = Database.setSavepoint();
    	try{
	    	AccountingEntryReversal(AEReverseType.AEReverse, AEListtoReverse);
	    	
	    	Accounting_Entry__c AEtoNavigate = AEtoAdjust.clone(false, true, false, false);
	    	
	    	//system.debug(logginglevel.info, 'AEtoAdjust.Accounting_Entry_Lines__r'+AEtoAdjust.Accounting_Entry_Lines__r);
	    	//system.assertNotEquals(0,AEtoAdjust.Accounting_Entry_Lines__r.size());
    	
	    	DML.insertAsSystem(AEtoNavigate);
	    	
	    	//Deep clone the ae lines 
			List<Accounting_Entry_Line__c> AEtoNavigateLines = AEtoAdjust.Accounting_Entry_Lines__r.deepClone(false, false, false);
			for(Accounting_Entry_Line__c newAEL : AEtoNavigateLines){
					newAEL.accounting_entry__c = AEtoNavigate.id;
			}	

	    	DML.insertAsSystem(AEtoNavigateLines);
	    	
	    	return AEtoNavigate;
    	} catch(Exception ex){
    		Database.rollback(sp);
          	throw new AESException(ex.getMessage(), ex);
    	}
    }
    
    public void accountingEntryReverse(List<Accounting_Entry__c> accountingEntries, Map<Id, Customer_Invoice__c> mCreditMemos){
    	
    	SegmentService SS = new SegmentService();
		List<Segment_Definition__c> segDefs = SS.segments; 
		//Add all configured segments to the query
		Set<String> segFields = new Set<String>();
		for(Segment_Definition__c sd : segDefs){
			segFields.add(sd.accounting_entry_field__c) ;
		}
    	
    	SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', TRUE);
    	soql.addFields(new Set<String>{ 'Id', 'name', 'company__c', 'Currency__c', 'transaction_type__c', 'customer_invoice__c', 'customer_invoice__r.bill_to_customer__c',
    									'transaction_date__c', 'finalized_date__c', 'source_document_object_name__c'});
    	soql.setWhereClause('Id IN :accountingEntries');
    	SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entry_Lines__r');
    	childRel.addFields(new Set<String>{ 'Id', 'subtransaction_type__c', 'line_type__c', 'accounting_rule__c', 'amount_dr__c', 'amount_cr__c', 'source_id__c', 'source_name__c'});
    	childRel.addFields(segFields);

    	soql.addChildRelationship(childRel);

		//system.debug('query: ' + query);
						
    	//NOTE: this query will have to change to support additional fields for other processes aside from credit/rebill during the reversal process
    	List<Accounting_Entry__c> aes = database.query(soql.getQuery());
		
		processReversedAccountingEntries(aes, mCreditMemos);
		
    }
    
    public void accountingEntryLineReverse(List<Accounting_Entry_Line__c> accountingEntryLines, Map<Id, Customer_Invoice__c> mCreditMemos){
    	List<Accounting_Entry_Line__c> aels = [SELECT Id, accounting_entry__c, name, gl_account__c, subtransaction_type__c, line_type__c,
    												amount_dr__c, amount_cr__c, source_id__c, source_name__c, accounting_rule__c
    											FROM Accounting_Entry_Line__c
    											WHERE id IN :accountingEntryLines];
		Set<Id> aeIds = new Set<Id>();
		for(Accounting_Entry_Line__c ael : aels){
			aeIds.add(ael.accounting_entry__c);
		}	
		
		//NOTE: this query will have to change to support additional fields for other processes aside from credit/rebill during the reversal process
		List<Accounting_Entry__c> aes = [SELECT Id, name, company__c, Currency__c, 
    										transaction_type__c, customer_invoice__c, customer_invoice__r.bill_to_customer__c,
    										(SELECT Id, gl_account__c, subtransaction_type__c, line_type__c,
    										amount_dr__c, amount_cr__c, source_id__c, source_name__c,accounting_rule__c
    										FROM Accounting_Entry_Lines__r
    										WHERE Id IN :accountingEntryLines)
										FROM Accounting_Entry__c
										WHERE Id IN :aeIds];
										
		processReversedAccountingEntries(aes, mCreditMemos);
		
    }
    
    //Private generic processor utilized by other reversal methods
    private void processReversedAccountingEntries(List<Accounting_Entry__c> accountingEntries, Map<Id, Customer_Invoice__c> mCreditMemos){
    	
    	Map<Id, Accounting_Entry__c> mSourceAccountingEntries = new Map<Id, Accounting_Entry__c>(accountingEntries);
    	Map<Id, Accounting_Entry__c> mAccountingEntries = new Map<Id, Accounting_Entry__c>();
    	Map<Id, List<Accounting_Entry_Line__c>> mAccountingEntryLines = new Map<Id, List<Accounting_Entry_Line__c>>();
    	
    	
    	for(Accounting_Entry__c ae : accountingEntries){
    		//Track the total credited amount for the credit memo
    		decimal totalCredit = 0;
    		
			//Clone the original accounting entry without id
			Accounting_Entry__c iAE = ae.clone(false, true, false, false);
			iAE.reversed_journal__c = ae.Id;
			iAE.Customer_Invoice__c = mCreditMemos.get(ae.customer_invoice__c).Id;
			iAE.Transaction_Type__c = 'Credit Memo';
			
			//Deep clone the ae lines 
			List<Accounting_Entry_Line__c> iAELines = ae.Accounting_Entry_Lines__r.deepClone(false, false, false);
			
			//Reverse the CR/DR amounts
			for(Accounting_Entry_Line__c ael : iAELines){
 				ael.accounting_entry__c = null;
				if(ael.amount_cr__c > 0){
					totalCredit += ael.amount_cr__c;
					ael.amount_dr__c = ael.amount_cr__c;
					ael.amount_cr__c = 0;
				}
				else if(ael.amount_dr__c > 0){
					ael.amount_cr__c = ael.amount_dr__c;
					ael.amount_dr__c = 0;
				}
				
				if(ael.Company__c == null){
					ael.Company__c = ae.Company__c;
				}
			}
			
			//Store in a map for later access
			mAccountingEntries.put(ae.Id, iAE);
			mAccountingEntryLines.put(ae.Id, iAELines);
		}
		
		if(mAccountingEntries.keySet().size() > 0){
			
			//Update the accounting entries with the credit memo relationship before inserting
			DML.insertAsUser( mAccountingEntries.values() );
			
			//Run through the records and attach the cloned lines to the new counter accounting entry
			List<Accounting_Entry_Line__c> insertAELines = new List<Accounting_Entry_Line__c>();
			for(Id aeId : mAccountingEntries.keySet()){
				Accounting_Entry__c counterAE = mAccountingEntries.get(aeId);
				
				if(mAccountingEntryLines.containsKey(aeId)){
					
					List<Accounting_Entry_Line__c> aels = mAccountingEntryLines.get(aeId);
					
					for(Accounting_Entry_Line__c ael : aels){
						ael.Accounting_Entry__c = counterAE.Id;
					}
					insertAELines.addAll(aels);
				}
				
			}
			
			if(insertAELines.size() > 0){
				DML.insertAsUser( insertAELines );
			}
		}
    }
        
    //Streamline AE/AEL Exceptions KNDY-10534
    public static void ValidateAEFields(List<Accounting_Entry__c> lstAccountingEntry){
        
        // Query for parent source docs and set exception based on hasExceptions
        Map<Id, Accounting_Entry__c> mAEs = new Map<Id, Accounting_Entry__c>([SELECT Id, name, customer_invoice__r.has_exceptions__c, customer_receipt__r.has_exceptions__c,
                                                                            shipment__r.has_exceptions__c, supplier_invoice__r.has_exceptions__c
                                                                            FROM Accounting_Entry__c
                                                                            WHERE Id IN :lstAccountingEntry]);
        for(Accounting_Entry__c ae : lstAccountingEntry){
            
            
            if(ae.Company__c==null)
                exService.setException(ae, ExceptionUtil.AE_MISSING_COMPANY);
            //else
            //  exService.clearException(ae, ExceptionUtil.AE_MISSING_COMPANY);
            
            if(string.isEmpty(ae.Transaction_Type__c))
                exService.setException(ae, ExceptionUtil.AE_MISSING_TRANSACTION_TYPE);
            //else
            //  exService.clearException(ae, ExceptionUtil.AE_MISSING_TRANSACTION_TYPE);
                
            if(ae.Transaction_Date__c==null) // Changing exception logic based on #KNDY-10534
            {
                exService.setException(ae, ExceptionUtil.AE_MISSING_TRANSACTION_DATE);
            }
            else
            {
            	if( ae.Posting_Date__c==null  )
            	{          
               		exService.setException(ae, ExceptionUtil.AE_MISSING_POSTING_DATE);
                }
                else
                {
            	
            	 	if(  ae.Period__c==null )
            	 	{
            	 		exService.setException(ae, ExceptionUtil.AE_MISSING_PERIOD);
            	 		
                 	}
                 	else
                 	{
           		 		if( ae.GL_Date_Time__c==null)
                 		exService.setException(ae, ExceptionUtil.AE_MISSING_GL_DATE_TIME);
                 	}
                 }
            }
            //else
            //  exService.clearException(ae, ExceptionUtil.AE_MISSING_TRANSACTION_DATE);
                
            if(ae.Currency__c==null)
                exService.setException(ae, ExceptionUtil.AE_MISSING_TRANSACTION_CURRENCY);
            //else
            //  exService.clearException(ae, ExceptionUtil.AE_MISSING_TRANSACTION_CURRENCY);
                
           /* if(ae.Finalized_Date__c==null)
                exService.setException(ae, ExceptionUtil.AE_MISSING_FINALIZED_DATE);*/
            
           /* if(ae.Posting_Date__c==null)
                exService.setException(ae, ExceptionUtil.AE_MISSING_POSTING_DATE);*/
                  
            //else
            //  exService.clearException(ae, ExceptionUtil.AE_MISSING_FINALIZED_DATE);
              //else
            //  exService.clearException(ae, ExceptionUtil.AE_MISSING_PERIOD);
            
            //------------KNDY-10121---------------   
            
            //Compare Transactional currency balances to zero if Active
            if(ae.Status__c=='Active'){//Create DR/CR mismacth task only when AE status is swapped to Active
	            if(!KSE.isEqualDecimal(ae.COMP_Total_Credit__c, ae.COMP_Total_Debit__c))
	            {          
	                exService.setException(ae, ExceptionUtil.AE_TRANSACTIONAL_CREDIT_DEBIT_UNMATCHED);
	            }   
	            else
	            {
	            	 //KNDY-12369 As Accounting happens in chunks,Clear the premature exception created in initial chunks.
	                 exService.clearException(ae, ExceptionUtil.AE_Transactional_CREDIT_DEBIT_UNMATCHED);//Only if task  already exists update happens.Validation rule on Task Object will ensure that tasks with status 'closed' are NOT inserted.                
	                
		        	 //Compare Functional currency balances to zero 
		        	 if(!KSE.isEqualDecimal(ae.COMP_Functional_Total_CR__c, ae.COMP_Functional_Total_DR__c)){
		              	exService.setException(ae, ExceptionUtil.AE_FUNCTIONAL_CREDIT_DEBIT_UNMATCHED);
		              } 
		             else{//KNDY-12369 As Accounting happens in chunks,Clear the premature exception created in initial chunks.
	                    exService.clearException(ae, ExceptionUtil.AE_FUNCTIONAL_CREDIT_DEBIT_UNMATCHED);	             	
		             }	             
	                 
	            }            	
          	  }

            
            /*if(ae.COMP_Total_Credit__c != ae.COMP_Total_Debit__c 
                    ||  ae.CONSOL_Total_Credit__c != ae.CONSOL_Total_Debit__c )
    			exService.setException(ae, ExceptionUtil.AE_CREDIT_DEBIT_UNMATCHED);
    		else
    			exService.clearException(ae, ExceptionUtil.AE_CREDIT_DEBIT_UNMATCHED);
    		*/	
    			
    			
    		//system.debug('Inside SourceDocPathMap.get(ae.Source_Document_Object_Name__c) '   + SourceDocPathMap.get(ae.Source_Document_Object_Name__c));
    		if(!string.isEmpty(SourceDocPathMap.get(ae.Source_Document_Object_Name__c)))		
    		{
    			//system.debug('Inside if of ae.getSObject(ae.Source_Document_Object_Name__c) '   + ae.get(ae.Source_Document_Object_Name__c));
    		
    			if(ae.get(ae.Source_Document_Object_Name__c)==null)
    			{
    				ExceptionUtil.AE_MISSING_SOURCEDOCUMENT.label = Label.Missing_Source_Document + ae.Source_Document_Object_Name__c ;
    				ExceptionUtil.AE_MISSING_SOURCEDOCUMENT.description = '('+ ae.Source_Document_Object_Name__c + ')'+ Label.Source_Document_value_is_missing;
    				exService.setException(ae, ExceptionUtil.AE_MISSING_SOURCEDOCUMENT);
    			}
    			//else
    			//	exService.clearException(ae, ExceptionUtil.AE_MISSING_SOURCEDOCUMENT);
    		}	
    		
    		if(mAEs.containsKey(ae.Id)){
    			
    			Accounting_Entry__c refAE = mAEs.get(ae.Id);
    			
    			if(refAE.customer_invoice__r.has_exceptions__c
    					|| refAE.customer_receipt__r.has_exceptions__c
    					|| refAE.shipment__r.has_exceptions__c
    					|| refAE.supplier_invoice__r.has_exceptions__c){
    				exService.setException(ae, ExceptionUtil.AE_SOURCE_DOC_EXCEPTION);		
				}
				//else{
				//	exService.clearException(ae, ExceptionUtil.AE_SOURCE_DOC_EXCEPTION);
				//}
    			
    		}
    	}
    }  
    
     // Create a map of companyId, Periods for all periods in the system
     public map<Id, Set<Period__c>> getcompanyPeriodsMap() {
     
     	map<Id, Set<Period__c>> companyPeriodsMap = new map<Id, Set<Period__c>>();
     	
     	for(Period__c thisPeriod: [Select id, Name,Period_Start__c, Period_End__c, Open__c ,Company__c, Period_Number__c , 
     										AP_Subledger_Closed__c,AR_Subledger_Closed__c,GL_Close__c,JE_CutOff__c,
    										AR_Subledger_CutOff__c, Prior_Period__r.AR_subledger_Cutoff__c,FA_Subledger_Closed__c,
    										AP_Subledger_CutOff__c, Prior_Period__r.AP_subledger_Cutoff__c,Inventory_Subledger_Closed__c,
    										FA_Subledger_CutOff__c, Prior_Period__r.FA_subledger_Cutoff__c,Receiving_Subledger_Closed__c,
    										Inventory_Subledger_CutOff__c, Prior_Period__r.Inventory_subledger_Cutoff__c,
    										Shipment_Subledger_CutOff__c, Prior_Period__r.Shipment_subledger_Cutoff__c,Shipment_Subledger_Closed__c,
    										Receiving_Subledger_CutOff__c, Prior_Period__r.Receiving_subledger_Cutoff__c,
    										Closed__c, Permanently_Closed__c,Prior_Period__r.JE_CutOff__c
                        					from Period__c 
                        					where Open__c = true] ){
     		if(companyPeriodsMap.containsKey(thisPeriod.company__c)){
 				companyPeriodsMap.get(thisPeriod.company__c).add(thisPeriod);
 			}else{
 				companyPeriodsMap.put(thisPeriod.company__c, new set<Period__c>{thisPeriod});
 			}
     	}
     	return companyPeriodsMap;
     }
    //TODO: Need to assign using PeriodService.getOpenPeriodsMap
    public map <Id,set<Period__c>> companyPeriodsMap = getcompanyPeriodsMap();
     
    
    /** As per KNDY-11526 - This is not used anywhere
    //Chopping block
    private map<Period__c, Period__c> getenclosingPeriodMap ( set<DateTime> DateFinalized, 
 														set<Period__c> openPeriods ) {
 		Map<Period__c, Period__c> enclosingPeriodMap = new Map<Period__c, Period__c>();
 		
 		for(DateTime thisDate: DateFinalized){
 			Datetime inputDate = thisDate;
 			for(Period__c thisPeriod : openPeriods ){
	 			if(	inputDate <= thisPeriod.Period_Cut_Off__c ) 
	        	{
	        		enclosingPeriodMap.put(new Period__c (Company__c = thisPeriod.Company__c, Period_Start__c = inputDate) , thisPeriod);
	        	}
 			}
 		}
 															
  		return enclosingPeriodMap;
 	}**/
 	
 	//Chopping block
 	private map<Period__c, Period__c> getenclosingPeriodMapTrxDate ( set<DateTime> TransactionDate, 
 														set<Period__c> openPeriods ) {
 		Map<Period__c, Period__c> enclosingPeriodMap = new Map<Period__c, Period__c>();
 		
 		for(DateTime thisDate: TransactionDate){
 			Datetime inputDate = thisDate;
 			for(Period__c thisPeriod : openPeriods ){
	 			if(	inputDate >= thisPeriod.Period_Start__c && inputDate < thisPeriod.Period_End__c ) 
	        	{
	        		enclosingPeriodMap.put(new Period__c (Company__c = thisPeriod.Company__c, Period_Start__c = inputDate) , thisPeriod);
	        	}
 			}
 		}
 															
  		return enclosingPeriodMap;
 	}
 	
 	// This function is to set the Finalized Date on the source document 
 	// This function to be called in the before insert / update Trigger of any source document by passing Trigger.New
 	public void setFinalizedDate(List<sObject> sObjectList){
 		Set<Id> CompanyIds = new Set<Id>();
 		set<DateTime> TransactionDateSet = new set<DateTime>();
 		
 		for(sObject sObj: sObjectList){
 			CompanyIds.add((Id) sObj.get('Company__c'));
 			TransactionDateSet.add((DateTime) sObj.get('Transaction_Date__c'));
 		}
 		
 		//Set<Period__c> openPeriods = getOpenPeriods(CompanyIds);
 		Set<Period__c> openPeriods= new set<Period__c>();
 		for(Set<Period__c> thisPeriodList: companyPeriodsMap.values()){
 			for(Period__c thisPeriod: thisPeriodList){
 				//system.debug(logginglevel.info,'thisPeriod:'+thisPeriod);
 				openPeriods.add(thisPeriod);
 			}
 		}
 		 		
 		map<Period__c, Period__c> getenclosingPeriodMapTrxDate = getenclosingPeriodMapTrxDate(TransactionDateSet,openPeriods);
 		//system.debug(logginglevel.info,'openPeriods:'+openPeriods);
 		//system.debug(logginglevel.info,'getenclosingPeriodMapTrxDate:'+getenclosingPeriodMapTrxDate.values());
 		
 		for(sObject sObj: sObjectList){
 			DateTime FinalizedDate = (DateTime) sObj.get('Finalized_Date__c');
  			DateTime TransactionDate = (DateTime) sObj.get('Transaction_Date__c');
 			Id Company = (Id) sObj.get('Company__c');
 			Period__c TrxDatePeriod;
 			DateTime PeriodStart;
 			
 			if(TransactionDate != null){
 				TrxDatePeriod = getenclosingPeriodMapTrxDate.get(new Period__c(Company__c = Company, Period_Start__c = TransactionDate));
 			}
 			if(TrxDatePeriod != null){
 				PeriodStart = (DateTime) TrxDatePeriod.get('Period_Start__c');
  			}
  			
  			
 			//system.debug(logginglevel.info,'FinalizedDate:'+FinalizedDate);
 			//system.debug(logginglevel.info,'TransactionDate:'+TransactionDate);
 			//system.debug(logginglevel.info,'TrxDatePeriod:'+TrxDatePeriod);
 			//system.debug(logginglevel.info,'PeriodStart:'+PeriodStart);
 			
 			if((Boolean) sObj.get('Finalized__c')){ 			
 				if( sObj.get('Finalized_Date__c') == null){
 					sObj.put('Finalized_Date__c',system.now());
 				}
 				FinalizedDate = (DateTime) sObj.get('Finalized_Date__c');
 				//system.debug(logginglevel.info,'FinalizedDate:'+FinalizedDate);	
 				if ( (TransactionDate != null && FinalizedDate != null) && (FinalizedDate <  TransactionDate && FinalizedDate < PeriodStart) ){
  					sObj.put('Finalized_Date__c',PeriodStart);
 				}
 			}else{
 				sObj.put('Finalized_Date__c',null);	
 			}
 		}
 	}
    
    // TODO: This may be moved to Custom Settings when we get more on custom settings security.
    //KNDY-10268 - deprecating bank file and bank file line objects - removed references
    public static Map< String, String > SourceDocPathMap {
        get{
			SourceDocPathMap = new map<String, String>();
			SourceDocPathMap.put( 'Shipment__c','Shipment__c');
			//SourceDocPathMap.put( 'Bank_File__c','Bank_File__c');
 			SourceDocPathMap.put( 'Bank_Transaction_Group__c','Bank_Transaction_Group__c');           
			SourceDocPathMap.put( 'Customer_Invoice__c','Customer_Invoice__c');
			SourceDocPathMap.put( 'Customer_Receipt__c','Customer_Receipt__c');
			SourceDocPathMap.put( 'Receiving_Document__c','Receiving_Document__c');
			SourceDocPathMap.put( 'Supplier_Invoice__c','Supplier_Invoice__c');
			SourceDocPathMap.put( 'Invoice__c','Invoice__c');
			SourceDocPathMap.put( 'Supplier_Payment__c','Supplier_Payment__c');
			SourceDocPathMap.put( 'Fixed_Asset_Adjustment__c','Fixed_Asset_Adjustment__c');
			SourceDocPathMap.put( 'Fixed_Asset_Depreciation__c','Fixed_Asset_Depreciation__c');
			SourceDocPathMap.put( 'Work_Order__c','Work_Order__c');
			SourceDocPathMap.put( 'Inventory_Change__c','Inventory_Change__c');
			SourceDocPathMap.put( 'Journal_Entry__c','Journal_Entry__c');
			SourceDocPathMap.put( 'Payment__c', 'Payment__c');
			//TODO: Need to remove Manual when JEs take over
			SourceDocPathMap.put( 'Manual', '');
			return SourceDocPathMap;
        }
	}

    // TODO: This may be moved to Custom Settings when we get more on custom settings security.
    //KNDY-10268 - deprecating bank file and bank file line objects - removed references
    public static Map< String, String > buildSubledgerNameMap(){
		map<String, String> ObjectToSubledgerMap = new map<String, String>();
		ObjectToSubledgerMap.put( 'Shipment__c','Shipment_Subledger_Cutoff__c');
		//ObjectToSubledgerMap.put( 'Bank_File__c','AR_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Bank_Transaction_Group__c','AR_Subledger_Cutoff__c');        
		ObjectToSubledgerMap.put( 'Customer_Invoice__c','AR_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Customer_Receipt__c','AR_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Receiving_Document__c','Receiving_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Invoice__c','InterCompany_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Payment__c','InterCompany_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Supplier_Invoice__c','AP_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Supplier_Payment__c','AP_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Fixed_Asset_Adjustment__c','FA_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Fixed_Asset_Depreciation__c','FA_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Work_Order__c','Inventory_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Inventory_Change__c','Inventory_Subledger_Cutoff__c');
		ObjectToSubledgerMap.put( 'Manual','JE_CutOff__c'); // TODO: when the journal entries replace the manual AE this record in the map will change accordingly
		ObjectToSubledgerMap.put( 'Journal_Entry__c','JE_CutOff__c');
//		ObjectToSubledgerMap.put( 'Purchase_Order__c', 'AP_Subledger_CutOff__c');

		return ObjectToSubledgerMap;
	}
	//KNDY-10268 - deprecating bank file and bank file line objects - removed references
    public static Map< String, String > buildSubledgerCloseMap(){
		map<String, String> ObjectToSubledgerMap = new map<String, String>();
		ObjectToSubledgerMap.put( 'Shipment__c','Shipment_Subledger_Closed__c');
		//ObjectToSubledgerMap.put( 'Bank_File__c','AR_Subledger_Closed__c');
 		ObjectToSubledgerMap.put( 'Bank_Transaction_Group__c','AR_Subledger_Closed__c');       
		ObjectToSubledgerMap.put( 'Customer_Invoice__c','AR_Subledger_Closed__c');
		ObjectToSubledgerMap.put( 'Customer_Receipt__c','AR_Subledger_Closed__c');
		ObjectToSubledgerMap.put( 'Receiving_Document__c','Receiving_Subledger_Closed__c');
		ObjectToSubledgerMap.put( 'Invoice__c','InterCompany_Subledger_Closed__c');
		ObjectToSubledgerMap.put( 'Payment__c','InterCompany_Subledger_Closed__c');
		ObjectToSubledgerMap.put( 'Supplier_Invoice__c','AP_Subledger_Closed__c');
		ObjectToSubledgerMap.put( 'Supplier_Payment__c','AP_Subledger_Closed__c');
		ObjectToSubledgerMap.put( 'Fixed_Asset_Adjustment__c','FA_Subledger_Closed__c');
		ObjectToSubledgerMap.put( 'Fixed_Asset_Depreciation__c','FA_Subledger_Closed__c');
		ObjectToSubledgerMap.put( 'Work_Order__c','Inventory_Subledger_Closed__c');
		ObjectToSubledgerMap.put( 'Inventory_Change__c','Inventory_Subledger_Closed__c');
		ObjectToSubledgerMap.put( 'Journal_Entry__c','GL_CLose__c');
		ObjectToSubledgerMap.put( 'Purchase_Order__c', 'AP_Subledger_Closed__c');

		return ObjectToSubledgerMap;
	}

	//RS: 2014-5-16 I'm concerned about this function with regard to daylight savings time - although it seems to work fine right now
	public Datetime getLocalDateTime(Datetime gmtDt){
	    //Date currDate = gmtDt.date();
	    //Time currTime = gmtDt.time();
	    //return Datetime.newInstance(currDate, currTime);
	    if(gmtDt == null){
	    	return null;
	    }
	    
	    TimeZone tz = UserInfo.getTimeZone();
	    integer seconds = tz.getOffset(gmtDt)/1000;
	    return gmtDt.addSeconds(seconds);
	}	
	/*
	This method was moved to the PeriodService as PeriodService.assignGLDatePeriod
    // Method created on sObject so that same method can be used on Accounting Entry as well as Journal Entry
    public void setGLDateTime(List<sObject> sObjectListNew){
 
    	set<Id> AEIds = new Set<Id>();
    	set<Id> CompanyIds = new Set<Id>();
    	Set<Period__c> openPeriodSet = new set<Period__c>();
        for(sObject thisAE: sObjectListNew ){
            AEIds.add(thisAE.Id);
            companyIds.add((Id) thisAE.get('Company__c'));
        }
        
        //openPeriodSet = getOpenPeriods(companyIds);
        for(Set<Period__c> thisPeriodList: companyPeriodsMap.values()){
 			for(Period__c thisPeriod: thisPeriodList){
 				openPeriodSet.add(thisPeriod);
 			}
 		}
        
        boolean inClosedPeriod = true, inFuturePeriod = true, inOpenPeriod = false; 

        //system.debug(logginglevel.info,'openPeriodSet in setGLDateNew function:'+openPeriodSet);
        Map<String, String> ObjectToSLCMap = new Map<String, String>();
        ObjectToSLCMap = buildSubledgerNameMap();
        //system.debug(logginglevel.info,'ObjectToSLCMap:'+ObjectToSLCMap);
        
        for(sObject thisAE: sObjectListNew){
        	//system.debug(logginglevel.info,'thisAE:'+thisAE);
        	//system.debug(logginglevel.info,'thisAE.source_document_object_name__c:'+thisAE.get('source_document_object_name__c'));

        	String subledgerfield, srcDocObjName;
        	
       	 	srcDocObjName = (String) thisAE.get('source_document_object_name__c');
        	
        	if(ObjectToSLCMap.containsKey(srcDocObjName)){
        		subledgerfield =  ObjectToSLCMap.get(srcDocObjName); // to get the subledger field name from the period for different source documents associated with AE
        	}
        	
        	for(Period__c thisPeriod: openPeriodSet){
        		
          		DateTime currentPeriodSubledgerCutOff, priorPeriodSubledgerCutOff;
         		
        		// get the priorperiod SLC and current period SLC beforehand to avoid making big if loop
				if(thisPeriod != null){
        			currentPeriodSubledgerCutOff = (DateTime) thisPeriod.get(subledgerfield); 
        			// SK - TODO: Check with Rod on below if loop for currentPeriodSubledgerCutOff being null
        			// KNDY - 3825 
        			if(currentPeriodSubledgerCutOff == null){
        				currentPeriodSubledgerCutOff = thisPeriod.Period_End__c; 
        			}
        			if(thisPeriod.Prior_Period__c != null){
        				priorPeriodSubledgerCutOff = ( DateTime.valueof(AccountingRuleService.getValue('Prior_Period__r.'+subledgerfield,thisPeriod) ));
        			}else{
        				priorPeriodSubledgerCutOff = thisPeriod.Period_Start__c; // TODO: Revisit this logic after Period object field validations.
        			}
				}
        		
        		//system.debug(logginglevel.info,'priorPeriodSubledgerCutOff:'+priorPeriodSubledgerCutOff);
      			//system.debug(logginglevel.info,'currentPeriodSubledgerCutOff:'+currentPeriodSubledgerCutOff);
        		if ((DateTime) thisAE.get('Transaction_Date__c') < thisPeriod.Period_start__c) { 
        			inFuturePeriod = false; 
        		} // Means it is in closed period -- inClosedPeriod = true && inOpenPeriod = false 
        		else if (thisPeriod.Period_end__c <= (DateTime) thisAE.get('Transaction_Date__c')) { 
        			inClosedPeriod = false; 
        		} // Means it is in future period -- inFuturePeriod = true && inOpenPeriod = false 
  				
    			// need to check two cases
      				// case 1: when transaction date is before the finalized date, just need to pick up the right period finalized
      				inOpenPeriod = true;

      				//system.debug(logginglevel.info,'thisAE.Transaction_Date__c:'+thisAE.get('Transaction_Date__c'));
      				//system.debug(logginglevel.info,'thisAE.Finalized_Date__c:'+thisAE.get('Finalized_Date__c'));
        				
      				if ((DateTime) thisAE.get('Transaction_Date__c') <= (DateTime) thisAE.get('Finalized_Date__c') && 
      					priorPeriodSubledgerCutOff <= (DateTime) thisAE.get('Finalized_Date__c') && 
      					(DateTime) thisAE.get('Finalized_Date__c') < currentPeriodSubledgerCutOff)
      				{
        				//system.debug(logginglevel.info,'Inside the TD <= FD if loop');
        				        				
        				if (thisPeriod.Period_start__c <= (DateTime) thisAE.get('Transaction_Date__c')) { 	
        					thisAE.put('GL_Date_Time__c',(DateTime) thisAE.get('Transaction_Date__c')); 
        					thisAE.put('Period__c', thisPeriod.id);
        				}
     					else if (thisPeriod.Period_start__c <= (DateTime) thisAE.get('Finalized_Date__c')) { 	
     						thisAE.put('GL_Date_Time__c', (DateTime) thisAE.get('Finalized_Date__c')); 
     						thisAE.put('Period__c', thisPeriod.id);
     					}
     					else { 		
     						thisAE.put('GL_Date_Time__c', thisPeriod.Period_start__c); 
     						thisAE.put('Period__c', thisPeriod.id);
    					}
     					
           			}
         			// case 2: when transaction date if after the finalized date, check 2 subcases
         			else if((DateTime) thisAE.get('Finalized_Date__c') < (DateTime) thisAE.get('Transaction_Date__c'))
         			{
         				//system.debug(logginglevel.info,'Inside the FD < TD if loop');
        				if(priorPeriodSubledgerCutOff <= (DateTime) thisAE.get('Finalized_Date__c') &&
        				 	(DateTime) thisAE.get('Finalized_Date__c') < thisPeriod.Period_start__c) {
        				 	if (thisPeriod.Period_start__c <= (DateTime) thisAE.get('Transaction_Date__c')) { 
        						thisAE.put('GL_Date_Time__c', (DateTime) thisAE.get('Transaction_Date__c')); 
        						thisAE.put('Period__c', thisPeriod.id);
        					}
     						else if (thisPeriod.Period_start__c <= (DateTime) thisAE.get('Finalized_Date__c')) { 
     							thisAE.put('GL_Date_Time__c', (DateTime) thisAE.get('Finalized_Date__c')); 
     							thisAE.put('Period__c', thisPeriod.id);
      						}
     						else { 
     							thisAE.put('GL_Date_Time__c', thisPeriod.Period_start__c); 
     							thisAE.put('Period__c', thisPeriod.id);
      						}
        				 	}
        					
        				else if (thisPeriod.Period_start__c <= (DateTime)thisAE.get('Finalized_Date__c') && 
        					(DateTime) thisAE.get('Finalized_Date__c') < currentPeriodSubledgerCutOff) 
           				{
        					if (thisPeriod.Period_start__c <= (DateTime) thisAE.get('Transaction_Date__c')) { 
        						thisAE.put('GL_Date_Time__c', (DateTime) thisAE.get('Transaction_Date__c')); 
        						thisAE.put('Period__c', thisPeriod.id);
        					}
     						else if (thisPeriod.Period_start__c <= (DateTime) thisAE.get('Finalized_Date__c')) { 
     							thisAE.put('GL_Date_Time__c', (DateTime) thisAE.get('Finalized_Date__c')); 
     							thisAE.put('Period__c', thisPeriod.id);
       						}
     						else { 
     							thisAE.put('GL_Date_Time__c', thisPeriod.Period_start__c);
     							thisAE.put('Period__c', thisPeriod.id);
      						}
     						
           				}
        			}else{
        				//TODO: 8/1/2014 This is a catch all for passing test failures - this whole method needs to be refactored immediately!
        				thisAE.put('GL_Date_Time__c', (DateTime) thisAE.get('Transaction_Date__c')); 
 						thisAE.put('Period__c', thisPeriod.prior_period__c);
        			}

        		}
        		// TODO: Debugs in below logic need to be replaced by .... ?
        		
        	} // End of period for loop
        	if(!inOpenPeriod){
        			if(inClosedPeriod){
        				system.debug(logginglevel.info,'This record is in closed period'); 
        			}else if(inFuturePeriod){
        				system.debug(logginglevel.info,'This record is in future period');
        			}else{
        				system.debug(logginglevel.info,'Unexpected error occurred !!');
        			}
        	}
    	} // End of AE for loop
    } // End of function setGLDateTime
    */
    
}