/*
* without sharing is intentional.  Void / Cancel needs to be run in system mode.
*/
public without sharing abstract class VoidCancelService {
	
    public enum Action {VOIDDOC, CANCELDOC}
    
    public static map<string, string> mVoidCancelServices = new map<string, string> {
        'Receiving_Document__c' => 'ReceivingDocumentVoidCancelService',
        'Supplier_Invoice__c' => 'SupplierInvoiceVoidCancelService',
        'Supplier_Payment__c' => 'SupplierPaymentVoidCancelService',
        'Journal_Entry__c' => 'JournalEntryVoidCancelService',
        'Customer_Invoice__c' => 'CustomerInvoiceVoidCancelService',
        'Customer_Receipt__c' => 'CustomerReceiptVoidCancelService',
        'Bank_Transaction_Group__c' => 'BankTransactionVoidCancelService'
    };
    
    public static DateTime voidDate;
    
    public abstract Map<Id, VoidCancelDetail> getBusinessVoidCancelDetails(List<sObject> sObjRecs);
    public abstract Map<Id, VoidCancelResponse> businessVoid(List<sObject> sObjRecs);
    public abstract Map<Id, VoidCancelResponse> businessCancel(List<sObject> sObjRecs);
    public virtual Map<Id, VoidCancelResponse> prepForCancel(List<sObject> sObjRecs) {
		Map<Id, VoidCancelResponse> responses = new Map<Id, VoidCancelResponse>();
		
		for(sObject sObj : sObjRecs) {
			VoidCancelResponse iVCR = new VoidCancelResponse();
            iVCR.recordId = sObj.Id;
            iVCR.recordName = (string)sObj.get('Name');
            iVCR.Action = Action.CANCELDOC;
            iVCR.Success = true;
            responses.put(sObj.Id, iVCR);
		}
		return responses;
	}
	
	public virtual Map<Id, VoidCancelResponse> prepForVoid(List<sObject> sObjRecs) {
		Map<Id, VoidCancelResponse> responses = new Map<Id, VoidCancelResponse>();
		
		for(sObject sObj : sObjRecs) {
			VoidCancelResponse iVCR = new VoidCancelResponse();
            iVCR.recordId = sObj.Id;
            iVCR.recordName = (string)sObj.get('Name');
            iVCR.Action = Action.VOIDDOC;
            iVCR.Success = true;
            responses.put(sObj.Id, iVCR);
		}
		return responses;
	}
    
    public class VoidCancelException extends Exception{}
    
    public Savepoint sp;
    
    public List<sObject> sourceDocuments;
    
    private map<Id, VoidCancelDetail> mVoidCancelDetail;
    private Map<Id, VoidCancelDetail> mBusinessVoidCancel;
    private Map<Id, VoidCancelDetail> mAccountingVoidCancel;
    
    private map<string, AccountingService> mAccountingWorkers = new map<string, AccountingService>();
    
    public VoidCancelService(List<sObject> sObjRecs){
    	if(voidDate == null){
            voidDate = system.now();
        }
    	this.sourceDocuments = sObjRecs;
    }
    
    public VoidCancelService(){
    	if(voidDate == null){
            voidDate = system.now();
        }
    }
    
    public void setSourceDocuments(List<sObject> sObjRecs){
    	this.sourceDocuments = sObjRecs;
    }
    
    public Map<Id, VoidCancelResponse> voidSourceDocuments(List<sObject> sObjRecs){
    	if(voidDate == null){
            voidDate = system.now();
        }
    	
        Map<Id, VoidCancelResponse> mResponses = new Map<Id, VoidCancelResponse>();
        sp = Database.setSavepoint();
        try{
        	
        	Map<String,List<sObject>> mObjectRecs = new Map<String,List<sObject>> ();
        	
        	for(sObject s : sObjRecs){
        		
	            Schema.SObjectType objectSchema= s.getSObjectType();
	            Schema.DescribeSObjectResult sObjectResult = objectSchema.getDescribe();
	            String objectName = sObjectResult.getLocalName();
	            
				//KNDY-7410
				//boolean hasFinalized = s.getSobjectType().getDescribe().fields.getMap().containsKey('void__c');
				SchemaUtil util = SchemaUtil.getInstance();
				Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(s.getSobjectType().getDescribe().fields.getMap());
				boolean hasFinalized = fieldsMap.containsKey('void__c');   
	            
	            
	            if(hasFinalized){
	            	if((Boolean)s.get('finalized__c')){
			            if(mObjectRecs.containsKey(objectName)){
			                mObjectRecs.get(objectName).add(s);
			            }else{
			                mObjectRecs.put(objectName, new List<sObject>{s});
			            }
	            	}
	            }
	        }
			Map<Id, Accounting_Entry__c> mFinishedEntries = new Map<ID, Accounting_Entry__c>();
	        for(String sObjectName : mObjectRecs.keySet()){
	            if(AccountingService.mAccountingWorkers.containsKey(sObjectName)){
	            	AccountingService accserv;
	                String factoryClassName = AccountingService.mAccountingWorkers.get(sObjectName);
	                if(mAccountingWorkers.containsKey(factoryClassName)){
	                	accserv = mAccountingWorkers.get(factoryClassName);
	                }else{
	                	Type t = Type.ForName(factoryClassName);
	                	accserv = (AccountingService)t.newInstance();
	                }
	                
		    	
		    		//TODO: As we move finish transitioning docs to large data, make this generic
                    if(sObjectName == 'Journal_Entry__c'){
            			
						//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
						List<Journal_Entry__c> jeList = mObjectRecs.get(sObjectName);
						
						SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
						soql.addFields(new set<string>{
							'id','name'
						});
						soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Journal_Entry__c IN :jeList)');
						soql.setLimit(200);
						
						list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());

                       	AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
	            	}
                    else if(sObjectName == 'Supplier_Invoice__c'){
            			
						//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
						List<Supplier_Invoice__c> siList = mObjectRecs.get(sObjectName);
						
						SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
						soql.addFields(new set<string>{
							'id','name'
						});
						soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Supplier_Invoice__c IN :siList)');
						soql.setLimit(200);

						list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());

                       	AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
	            	}
                    else if(sObjectName == 'Supplier_Payment__c'){
            			
						//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
						List<Supplier_Payment__c> spList = mObjectRecs.get(sObjectName);
						
						SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
						soql.addFields(new set<string>{
							'id','name'
						});
						soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Supplier_Payment__c IN :spList)');
						soql.setLimit(200);

						list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());

                       	AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
	            	}

	            	else if(sObjectName == 'Customer_Invoice__c'){
            			
						//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
						List<Customer_Invoice__c> ciList = mObjectRecs.get(sObjectName);
						
						SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
						soql.addFields(new set<string>{
							'id','name'
						});
						soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Customer_Invoice__c IN :ciList)');
						soql.setLimit(200);
						
						list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());

            			AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
	            	}
	            	
	            	else if(sObjectName == 'Customer_Receipt__c'){
            			
						//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
						List<Customer_Receipt__c> crList = mObjectRecs.get(sObjectName);
						
						SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
						soql.addFields(new set<string>{
							'id','name'
						});
						soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Customer_Receipt__c IN :crList)');
						soql.setLimit(200);
						
						list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());
						
						AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
	            	}

	            	else if(sObjectName == 'Receiving_Document__c'){
            			
						//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
						List<Receiving_Document__c> rdList =  mObjectRecs.get(sObjectName);
						
						SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
						soql.addFields(new set<string>{
							'id','name'
						});
						soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Receiving_Document__c IN :rdList)');
						soql.setLimit(200);
						list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());

                       	AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
	            	}
                    else if(sObjectName == 'Bank_Transaction_Group__c'){
                        list<Accounting_Entry_Line__c> AELList = [select id, name from Accounting_Entry_Line__c where Accounting_Entry__c IN (select Id from Accounting_Entry__c where Bank_Transaction_Group__c IN: mObjectRecs.get(sObjectName)) limit 200];

                        AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
                    }                    
					else{	
	                	accserv.execute(mObjectRecs.get(sObjectName));
		                for(Accounting_Entry__c ae : accserv.getFinishedAccountingEntries()){
		                	if(ae.related_accounting_entry__c == null){
		                		mFinishedEntries.put((Id)ae.get(AccountingEntryService.SourceDocPathMap.get(ae.Source_Document_Object_Name__c)), ae);
		                	}
		                }
	                }
	                //finishedAccountingEntries.addAll(accserv.getFinishedAccountingEntries());
	            }
	        }
        	
            List<sObject> voidSourceDocs = new List<sObject>();
            set<Id> voidIds = new set<Id>();
            for(sObject sObj : sObjRecs){
                if(getVoidCancelDetails().get(sObj.Id).isVoidable){
                	
                	if(mFinishedEntries.containsKey(sObj.Id)){
                		if(mFinishedEntries.get(sObj.Id).has_exceptions__c){
                			VoidCancelResponse iVCR = new VoidCancelResponse();
		                    iVCR.recordId = sObj.Id;
		                    iVCR.recordName = (string)sObj.get('Name');
		                    iVCR.Action = Action.VOIDDOC;
		                    iVCR.Success = false;
		                    iVCR.messages.add('This document cannot be voided because there are exceptions on the related Accounting Entry');
		                    mResponses.put(sObj.Id, iVCR);
		                    continue;
                		}
                	}
                	
                	sObj.put('Finalized__c', true);
                    sObj.put('Void__c', true);
		    		//sObj.put('Void_Date__c', system.now());
		    		if(sObj.get('Void_Date__c') == null)
		    			sObj.put('Void_Date__c', voidDate);
		    		sObj.put('Status__c', 'Void');
		    		voidIds.add(sObj.Id);
		    		voidSourceDocs.add(sObj);
                }else{
                    VoidCancelResponse iVCR = new VoidCancelResponse();
                    iVCR.recordId = sObj.Id;
                    iVCR.recordName = (string)sObj.get('Name');
                    iVCR.Action = Action.VOIDDOC;
                    iVCR.Success = false;
                    iVCR.messages.add('This document cannot be voided');
                    mResponses.put(sObj.Id, iVCR);
                }
            }

            voidCancelTaxes(voidSourceDocs, mResponses);

            FinalizeService.voidIds.addAll(voidIds);
            
            //PTP-422
            List<sObject> tasksToClose = new List<sObject>();
            for(sObject sObj : sObjRecs){
            	for(sObject ex : ExceptionService.getTaskRelatedList(sObj)) {
            		ex.put('Status', 'Closed');
            		tasksToClose.add(ex);
            	}
            }
            
            DML.updateAsSystem(tasksToClose);
            
            system.debug('VCS voidDocs: '+voidSourceDocs);
            
            DML.updateAsSystem(voidSourceDocs);
            
            List<sObject> businessVoidSourceDocs = new List<sObject>();
			Map<Id, VoidCancelResponse> mAccountingVoidResponses = accountingVoid(voidSourceDocs);
            for(sObject sObj : voidSourceDocs){
        		VoidCancelResponse iVCR = new VoidCancelResponse();
                iVCR.recordId = sObj.Id;
                iVCR.recordName = (string)sObj.get('Name');
                iVCR.Action = Action.VOIDDOC;
                if(mAccountingVoidResponses.containsKey(sObj.Id)){
                    iVCR.Success = mAccountingVoidResponses.get(sObj.Id).Success;
                    if(iVCR.success){
                    	businessVoidSourceDocs.add(sObj);
                    }
                    else {
                    	Database.rollback(sp); 
                    }
                    iVCR.messages.addAll(mAccountingVoidResponses.get(sObj.Id).messages);
                }else{
                	Database.rollback(sp); 
                	iVCR.Success = false;
                	iVCR.messages.add('Unable to perform void for ' + iVCR.recordId.getSObjectType().getDescribe().getLabel() + ' ' + iVCR.recordName);
                    //Throw exception to force a rollback - something didn't work correctly across the business and accounting processes
                    //throw new VoidCancelException('Unable to perform void for ' + iVCR.recordId.getSObjectType().getDescribe().getLabel() + ' ' + iVCR.recordName);
                }
                mResponses.put(sObj.Id, iVCR);
            }
            system.debug(logginglevel.info, 'mResponses: ' + mResponses);
            system.debug(logginglevel.info, 'mAccountingVoidResponses: ' + mAccountingVoidResponses);
            system.debug(logginglevel.info, 'businessVoidSourceDocs: ' + businessVoidSourceDocs);
            Map<Id, VoidCancelResponse> mBusinessVoidResponses = businessVoid(businessVoidSourceDocs);
        	//List<sObject> accountingVoidSourceDocs = new List<sObject>();
        	for(sObject sObj : voidSourceDocs){
            	VoidCancelResponse iVCR = mResponses.get(sObj.Id);
                if(mBusinessVoidResponses.containsKey(sObj.Id)){
                	//TODO: Transaction control for partial completion
                    iVCR.success = mBusinessVoidResponses.get(sObj.Id).Success && iVCR.success;
                    //if(iVCR.success){
                    //	accountingVoidSourceDocs.add(sObj);
                    //}
                    if(!iVCR.success) {
                    	Database.rollback(sp); 
                    }
                    iVCR.messages.addAll(mBusinessVoidResponses.get(sObj.Id).messages);
                }else{
                	Database.rollback(sp); 
                	iVCR.success = false;
                	iVCR.messages.add('Unable to perform void for ' + iVCR.recordId.getSObjectType().getDescribe().getLabel() + ' ' + iVCR.recordName);
                    //Throw exception to force a rollback - something didn't work correctly across the business and accounting processes
                    //throw new VoidCancelException('Unable to perform void for ' + iVCR.recordId.getSObjectType().getDescribe().getLabel() + ' ' + iVCR.recordName);
                }
                mResponses.put(sObj.Id, iVCR);
            }
            /*
            set<Id> cleanUpAccountingEntryVoids = new set<Id>();
			Map<Id, VoidCancelResponse> mAccountingVoidResponses = accountingVoid(accountingVoidSourceDocs);
            for(sObject sObj : voidSourceDocs){
            	VoidCancelResponse iVCR = mResponses.get(sObj.Id);
                if(mAccountingVoidResponses.containsKey(sObj.Id) && mBusinessVoidResponses.containsKey(sObj.Id)){
                    iVCR.Success = mAccountingVoidResponses.get(sObj.Id).Success && mBusinessVoidResponses.get(sObj.Id).Success;
                    if(!iVCR.Success){
                    	cleanupAccountingEntryVoids.add(iVCR.recordId);
                    }
                    iVCR.messages.addAll(mAccountingVoidResponses.get(sObj.Id).messages);
                }else{
                    //Throw exception to force a rollback - something didn't work correctly across the business and accounting processes
                    //throw new VoidCancelException('Unable to perform void for ' + iVCR.recordId.getSObjectType().getDescribe().getLabel() + ' ' + iVCR.recordName);
                }
                mResponses.put(sObj.Id, iVCR);
            }
            */
            //Delete the voiding AEs 
			//cleanupVoid(cleanupAccountingEntryVoids);            
            
        }catch(Exception ex){
        	Database.rollback(sp);  
            throw ex;
        }
        
        return mResponses;
    }

    private void voidCancelTaxes(List<SObject>cancelSourceDocs, Map<Id, VoidCancelResponse> mResponses){
        TaxService tService = TaxService.getInstance();

        if(tService.HasTaxService){
            List<TaxService.TaxResult> tResults = tService.voidTaxes(cancelSourceDocs);

            if(tResults != null){
                for(TaxService.TaxResult tr : tResults){
                    if(tr.isSuccess == false){

                        for(integer i=0;i<cancelSourceDocs.size();i++){
                            if(tr.obj.Id == cancelSourceDocs.get(i).Id){
                                cancelSourceDocs.remove(i);
                                mResponses.get(tr.obj.Id).Success = false;
                                mResponses.get(tr.obj.Id).messages.add(tr.message);
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
    public Map<Id, VoidCancelResponse> cancelSourceDocuments(List<sObject> sObjRecs){
        
        Map<Id, VoidCancelResponse> mResponses = new Map<Id, VoidCancelResponse>();
       
        try{
            
            List<sObject> cancelSourceDocs = new List<sObject>();
            for(sObject sObj : sObjRecs){ // create the map of responses if its cancellabel success will be true, else false and give error message!
                    VoidCancelResponse iVCR = new VoidCancelResponse();
                    iVCR.recordId = sObj.Id;
                    iVCR.recordName = (string)sObj.get('Name');
                    iVCR.Action = Action.CANCELDOC;
              
                if(getVoidCancelDetails().get(sObj.Id).isCancellable){
                	iVCR.Success = true;
                    cancelSourceDocs.add(sObj);
                }else{
                    iVCR.Success = false;
                    iVCR.messages.add('This document cannot be cancelled');
                }
                    mResponses.put(sObj.Id, iVCR);
                }
            system.debug('mResponses '+mResponses);
            Map<Id, VoidCancelResponse> mPrepCancelResponses = prepForCancel(cancelSourceDocs);
            sp = Database.setSavepoint();
            system.debug('mPrepCancelResponses '+mPrepCancelResponses);
            list<sObject> preppedDocs = new list<sObject>();
            
            //now go through our mResponses  and compare against responses from prepCancel. if prepcancel says false, then final response is false, add all the messages and collect all successfully prepped docs for accountingcancel
            for(sObject sObj : cancelSourceDocs){
            	VoidCancelResponse iVCR = mResponses.get(sObj.Id);
                if(mPrepCancelResponses.containsKey(sObj.Id)){
                	iVCR.success = mPrepCancelResponses.get(sObj.Id).Success; 
                    iVCR.messages.addAll(mPrepCancelResponses.get(sObj.Id).messages); //add all the messages.
                    if(iVCR.success){
                    	preppedDocs.add(sObj);
                    }
                    iVCR.messages.addAll(mPrepCancelResponses.get(sObj.Id).messages);
                }else{
                	//Database.rollback(sp); 
                	iVCR.success = false;
                	iVCR.messages.add('Unable to perform prep cancel for ' + iVCR.recordId.getSObjectType().getDescribe().getLabel() + ' ' + iVCR.recordName);
                }
                mResponses.put(sObj.Id, iVCR);
            }
             system.debug('mResponses '+mResponses);

             voidCancelTaxes(cancelSourceDocs, mResponses);


            //PTP-422
            sp = Database.setSavepoint();
            List<sObject> tasksToClose = new List<sObject>();
            for(sObject sObj : preppedDocs){ //only close tasks for prepped docs
            	for(sObject ex : ExceptionService.getTaskRelatedList(sObj)) {
            		ex.put('Status', 'Closed');
            		tasksToClose.add(ex);
            	}
            }
            
            DML.updateAsSystem(tasksToClose);

            Map<Id, VoidCancelResponse> mAccountingCancelResponses = accountingCancel(preppedDocs); //only cancel prepped docs

            List<sObject> accountingCancelSourceDocs = new List<sObject>();
        	for(sObject sObj : preppedDocs){
            	VoidCancelResponse iVCR = mResponses.get(sObj.Id);
                iVCR.messages.addAll(mAccountingCancelResponses.get(sObj.Id).messages);
                if(mAccountingCancelResponses.containsKey(sObj.Id)){
                    iVCR.success = mAccountingCancelResponses.get(sObj.Id).Success;
                    if(iVCR.success){
                    	accountingCancelSourceDocs.add(sObj);
                    }
                    else {
                    	Database.rollback(sp); 
                    }
                    iVCR.messages.addAll(mAccountingCancelResponses.get(sObj.Id).messages);
                }else{
                	Database.rollback(sp); 
                	iVCR.success = false;
                	iVCR.messages.add('Unable to perform cancel for ' + iVCR.recordId.getSObjectType().getDescribe().getLabel() + ' ' + iVCR.recordName);
                    //Throw exception to force a rollback - something didn't work correctly across the business and accounting processes
                    //throw new VoidCancelException('Unable to perform void for ' + iVCR.recordId.getSObjectType().getDescribe().getLabel() + ' ' + iVCR.recordName);
                }
                mResponses.put(sObj.Id, iVCR);
            }
             system.debug('mResponses '+mResponses);
			Map<Id, VoidCancelResponse> mBusinessCancelResponses = businessCancel(accountingCancelSourceDocs);
            for(sObject sObj : accountingCancelSourceDocs){
                VoidCancelResponse iVCR = mResponses.get(sObj.Id);
                    iVCR.messages.addAll(mBusinessCancelResponses.get(sObj.Id).messages);
                if(mBusinessCancelResponses.containsKey(sObj.Id)){
                	iVCR.success = mBusinessCancelResponses.get(sObj.Id).Success;
                    
                    if(!iVCR.success) {
                    	Database.rollback(sp); 
                    }
                }else{
                	iVCR.success = false;
                	Database.rollback(sp); 
                    //Throw exception to force a rollback - something didn't work correctly across the business and accounting processes
                    //throw new VoidCancelException('Unable to perform cancel for ' + iVCR.recordId.getSObjectType().getDescribe().getLabel() + ' ' + iVCR.recordName);
                }
                mResponses.put(sObj.Id, iVCR);
            }
             system.debug('mResponses '+mResponses);
        }catch(Exception ex){
        	system.debug('cancel docs exception '+ex.getMessage()+ ' stacktrace '+ex.getStackTraceString());
        	Database.rollback(sp);
            throw ex;
        }
        return mResponses;
    }
    
    public Map<Id, VoidCancelDetail> getVoidCancelDetailsWithDates(){
    	
    	if(this.sourceDocuments == null){
    		throw new VoidCancelException('You must provide source documents to void or cancel');
    	}
    	
    	if(mVoidCancelDetail == null){
            mVoidCancelDetail = new Map<Id, VoidCancelDetail>();
            mBusinessVoidCancel = getBusinessVoidCancelDetails(sourceDocuments);
        	mAccountingVoidCancel = getAccountingVoidCancelDetails(sourceDocuments);
        	id companyId;
        	map<string,list<datetime>> inputMap = new map <string,list<datetime>>();
        	for(sObject sObj : sourceDocuments){
				companyId = (Id)sObj.get('Company__c');
            	string objectName = sObj.getSObjectType().getDescribe().getLocalName();
			    datetime voidDateTime = (datetime)sObj.get('void_date__c');
				if(!inputMap.containskey(objectName)){
					inputMap.put(objectName,new list <datetime>{voidDateTime});
				}
				else{
					inputMap.get(objectName).add(voidDate);
				}
        	}
        	
			map<string, list<map<datetime,PeriodService.checkPeriodResult>>> resultMap = periodService.checkOpenPeriodAndSubledgerForDate(inputMap,companyId);
        	
    		for(sObject sObj : sourceDocuments){
    			VoidCancelDetail iVCD = new VoidCancelDetail();
    			iVCD.recordId = sObj.Id;
    			iVCD.recordName = (string)sObj.get('Name');
    			if(mBusinessVoidCancel.containsKey(sObj.Id) && mAccountingVoidCancel.containsKey(sObj.Id)){
    				iVCD.isVoidable = mBusinessVoidCancel.get(sObj.Id).isVoidable && mAccountingVoidCancel.get(sObj.Id).isVoidable;
    				iVCD.isCancellable = mBusinessVoidCancel.get(sObj.Id).isCancellable && mAccountingVoidCancel.get(sObj.Id).isCancellable;
    				iVCD.voidMessages.addAll(mBusinessVoidCancel.get(sObj.Id).voidMessages);
    				iVCD.cancelMessages.addAll(mBusinessVoidCancel.get(sObj.Id).cancelMessages);
    				iVCD.voidMessages.addAll(mAccountingVoidCancel.get(sObj.Id).voidMessages);
    				iVCD.cancelMessages.addAll(mAccountingVoidCancel.get(sObj.Id).cancelMessages);
			        datetime tranDate = (datetime)sObj.get('transaction_date__c');
			    	datetime voidDateTime = (datetime)sObj.get('void_date__c');
            		string objectName = sObj.getSObjectType().getDescribe().getLocalName();
            		list<map<datetime,PeriodService.checkPeriodResult>> result = resultMap.get(objectName);
            		PeriodService.checkPeriodResult newResult = new PeriodService.checkPeriodResult();
            		for(map<datetime,PeriodService.checkPeriodResult> rmap: result){
            			if (rmap.containsKey(voidDateTime)){
            				newResult = rmap.get(voidDateTime);
            				break;
            			}
            		}
			        if( newResult != null && voidDate != null && newResult.periodOpen != true){
			        	iVCD.isVoidable =false;
			    		iVCD.voidMessages.add(label.Void_Date_Period_not_open);
			        	
			        }
			        else if( newResult != null && voidDate != null && newResult.subledgerOpen != true){
			        	iVCD.isVoidable=false;
			    		iVCD.voidMessages.add(label.void_date_Subledger_not_open);
			        	
			        }
			 	    else if(tranDate!= null && voidDate != null && voidDate < tranDate ){
				    	iVCD.isVoidable=false;
			            iVCD.voidMessages.add(label.Void_date_cannot_before_Transaction_date);
				            	
				    }
                
    			}else{
    				iVCD.isVoidable = false;
    				iVCD.isCancellable = false;
    				iVCD.voidMessages.add('Unable to determine void behavior for ' + iVCD.recordName);
    				iVCD.cancelMessages.add('Unable to determine cancel behavior for ' + iVCD.recordName);
    			}
                mVoidCancelDetail.put(sObj.Id, iVCD);
    		}
    	}
    	return mVoidCancelDetail;
    }

    public Map<Id, VoidCancelDetail> getVoidCancelDetails(){
    	
    	if(this.sourceDocuments == null){
    		throw new VoidCancelException('You must provide source documents to void or cancel');
    	}
    	
    	if(mVoidCancelDetail == null){
            mVoidCancelDetail = new Map<Id, VoidCancelDetail>();
            mBusinessVoidCancel = getBusinessVoidCancelDetails(sourceDocuments);
        	mAccountingVoidCancel = getAccountingVoidCancelDetails(sourceDocuments);
    		for(sObject sObj : sourceDocuments){
    			VoidCancelDetail iVCD = new VoidCancelDetail();
    			iVCD.recordId = sObj.Id;
    			iVCD.recordName = (string)sObj.get('Name');
    			if(mBusinessVoidCancel.containsKey(sObj.Id) && mAccountingVoidCancel.containsKey(sObj.Id)){
    				iVCD.isVoidable = mBusinessVoidCancel.get(sObj.Id).isVoidable && mAccountingVoidCancel.get(sObj.Id).isVoidable;
    				iVCD.isCancellable = mBusinessVoidCancel.get(sObj.Id).isCancellable && mAccountingVoidCancel.get(sObj.Id).isCancellable;
    				iVCD.voidMessages.addAll(mBusinessVoidCancel.get(sObj.Id).voidMessages);
    				iVCD.cancelMessages.addAll(mBusinessVoidCancel.get(sObj.Id).cancelMessages);
    				iVCD.voidMessages.addAll(mAccountingVoidCancel.get(sObj.Id).voidMessages);
    				iVCD.cancelMessages.addAll(mAccountingVoidCancel.get(sObj.Id).cancelMessages);
    			}else{
    				iVCD.isVoidable = false;
    				iVCD.isCancellable = false;
    				iVCD.voidMessages.add('Unable to determine void behavior for ' + iVCD.recordName);
    				iVCD.cancelMessages.add('Unable to determine cancel behavior for ' + iVCD.recordName);
    			}
                mVoidCancelDetail.put(sObj.Id, iVCD);
    		}
    	}
    	return mVoidCancelDetail;
    }
    
    public Map<Id, VoidCancelDetail> getAccountingVoidCancelDetails(List<sObject> sObjRecs){
    	if(mAccountingVoidCancel == null){
    		mAccountingVoidCancel = new Map<Id, VoidCancelDetail>();
    		Map<Id, UnfinalizeService.UnfinalizeDetail> mUnfinalize = UnfinalizeService.checkUnfinalize(sObjRecs);                 
    		//Would accounting ever deny the void of a finalized source doc?
    		for(sObject sObj : sourceDocuments){
    			VoidCancelDetail iVCD = new VoidCancelDetail();
    			iVCD.recordId = sObj.Id;
    			iVCD.recordName = (string)sObj.get('Name');
    			
    			//KNDY-7410
    			//boolean hasHistorical = sObj.getSobjectType().getDescribe().fields.getMap().containsKey('historical__c');                
				SchemaUtil util = SchemaUtil.getInstance();
				Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(sObj.getSobjectType().getDescribe().fields.getMap());
				boolean hasHistorical = fieldsMap.containsKey('historical__c');      
				
    			boolean isHistorical = false;
    			if(hasHistorical){
    				if((Boolean)sObj.get('Historical__c')){
    					isHistorical = true;
    				}
    			}
    			if(isHistorical){
    				iVCD.isvoidable = false;
    				iVCD.voidMessages.add('Unable to void a ' + iVCD.recordId.getSObjectType().getDescribe().getLabel() + ' that is Historical');
    			}else if(!(Boolean)sObj.get('Finalized__c')){
    				iVCD.isVoidable = false;
					iVCD.voidMessages.add('Unable to void a ' + iVCD.recordId.getSObjectType().getDescribe().getLabel() + ' that is not Finalized');
    			}else if((Boolean)sObj.get('Void__c')){
    				iVCD.isVoidable = false;
					iVCD.voidMessages.add('Unable to void a ' + iVCD.recordId.getSObjectType().getDescribe().getLabel() + ' that is already Void');
    			}else{
    				iVCD.isVoidable = true;
    			}
                String sObjName = sObj.ID.getSObjectType().getDescribe().getName();
                if(sObjName.equalsIgnoreCase(KSE.NamespaceUU + 'Journal_Entry__c') == FALSE){
                    Map<Periodservice.PeriodRetrievalDefinition,period__c> mapInCOntext =  Periodservice.getPeriodsForSDs(new list<sObject>{sObj});    
                    system.debug('Period Validation Logic: Map<Periodservice.PeriodRetrievalDefinition,period__c> mapInCOntext -- ' + mapInCOntext); 
                    if(mapInCOntext.isEmpty() == TRUE){
                            iVCD.isVoidable = false;
                            iVCD.voidMessages.add('Unable to void a ' + iVCD.recordId.getSObjectType().getDescribe().getLabel() + '. To void a document, an open period must be associated with it.');
                            
                    }
                }   
    			
    			iVCD.isCancellable = mUnfinalize.get(sObj.Id).isUnfinalizable;
    			if(isHistorical){
    				iVCD.isCancellable = false;
    				iVCD.cancelMessages.add('Cannot Cancel, this is a Historical ' + sObj.getSobjectType().getDescribe().getLabel());
    			}else{
					if(mUnfinalize.get(sObj.Id).message != null){
    					iVCD.cancelMessages.add(mUnfinalize.get(sObj.Id).message);
    				}
    			}
				mAccountingVoidCancel.put(sObj.Id, iVCD);
    		}
    	}
    	return mAccountingVoidCancel;
    }
    
    private Map<Id, VoidCancelResponse> accountingVoid(List<sObject> sObjRecs){
    	
        Map<Id, VoidCancelResponse> mResponses = new Map<Id, VoidCancelResponse>();
        Map<String,List<sObject>> mObjectRecs = new Map<String,List<sObject>> ();
		List<Accounting_Entry__c> finishedAccountingEntries = new List<Accounting_Entry__c>();
		set<Id> voidIds = new set<Id>();
		
        for(sObject s : sObjRecs){
        	voidIds.add(s.Id);
            Schema.SObjectType objectSchema= s.getSObjectType();
            Schema.DescribeSObjectResult sObjectResult = objectSchema.getDescribe();
            String objectName = sObjectResult.getLocalName();
             if(mObjectRecs.containsKey(objectName)){
                mObjectRecs.get(objectName).add(s);
            }else{
                mObjectRecs.put(objectName, new List<sObject>{s});
            }
            
        }
		
        for(String sObjectName : mObjectRecs.keySet()){
            if(AccountingService.mAccountingWorkers.containsKey(sObjectName)){
                AccountingService accserv;
                String factoryClassName = AccountingService.mAccountingWorkers.get(sObjectName);
                if(mAccountingWorkers.containsKey(factoryClassName)){
                	accserv = mAccountingWorkers.get(factoryClassName);
                }else{
                	Type t = Type.ForName(factoryClassName);
                	accserv = (AccountingService)t.newInstance();
                }
                if(sObjectName == 'Journal_Entry__c'){
                	
					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					List<Journal_Entry__c> jeList = mObjectRecs.get(sObjectName);
					
					SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', false); //enforceFLS=false, running in system mode
					soql.addFields(new set<string>{
						'Id'
					});
					soql.setWhereClause('Journal_Entry__c IN :jeList  and status__c = \'Active\' and has_exceptions__c = false and total_lines__c = 0');
					
					list<Accounting_Entry__c> aeList = Database.query(soql.getQuery());

                	if(aeList.size() > 0){
                		AccountingEntryService.getInstance().AccountingEntryReversal(AccountingEntryService.AEReverseType.AEVoid, aeList);
                	}
        			
					soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
					soql.addFields(new set<string>{
						'id','name'
					});
					soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Journal_Entry__c IN :jeList)');

					list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());

                   	AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
            	}
                else if(sObjectName == 'Supplier_Invoice__c'){
                	
					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					List<Supplier_Invoice__c> siList = mObjectRecs.get(sObjectName);
					
					SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', false); //enforceFLS=false, running in system mode
					soql.addFields(new set<string>{
						'Id'
					});
					soql.setWhereClause('Supplier_Invoice__c IN :siList and status__c = \'Active\' and has_exceptions__c = false and total_lines__c = 0');

					list<Accounting_Entry__c> aeList = Database.query(soql.getQuery());

                	if(aeList.size() > 0){
                		AccountingEntryService.getInstance().AccountingEntryReversal(AccountingEntryService.AEReverseType.AEVoid, aeList);
                	}
        			
        			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					
					soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
					soql.addFields(new set<string>{
						'id','name'
					});
					soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Supplier_Invoice__c IN :siList)');

					list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());

                   	AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
            	}
                else if(sObjectName == 'Supplier_Payment__c'){
        			
					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					List<Supplier_Payment__c> spList = mObjectRecs.get(sObjectName);
					
					SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', false); //enforceFLS=false, running in system mode
					soql.addFields(new set<string>{
						'Id'
					});
					soql.setWhereClause('Supplier_Payment__c IN :spList and status__c = \'Active\' and has_exceptions__c = false and total_lines__c = 0');

					list<Accounting_Entry__c> aeList = Database.query(soql.getQuery());

                	if(aeList.size() > 0){
                		AccountingEntryService.getInstance().AccountingEntryReversal(AccountingEntryService.AEReverseType.AEVoid, aeList);
                	}
        			
					soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
					soql.addFields(new set<string>{
						'id','name'
					});
					soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Supplier_Payment__c IN :spList)');
					
					list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());

                   	AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
            	}

            	else if(sObjectName == 'Customer_Invoice__c'){
        			List<Customer_Invoice__c> ciList = mObjectRecs.get(sObjectName);
					
					SOQLUtil soql1 = new SOQLUtil('Accounting_Entry__c', false); //enforceFLS=false, running in system mode
					soql1.addFields(new set<string>{
						'Id'
					});
					soql1.setWhereClause('Customer_Invoice__c IN :ciList  and status__c = \'Active\' and has_exceptions__c = false and total_lines__c = 0');
 					list<Accounting_Entry__c> aeList = Database.query(soql1.getQuery());
					if(aeList.size() > 0){
                		AccountingEntryService.getInstance().AccountingEntryReversal(AccountingEntryService.AEReverseType.AEVoid, aeList);
                	}
                	       			
                   	SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
					soql.addFields(new set<string>{
						'id','name'
					});
					soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Customer_Invoice__c IN :ciList)');
					soql.setLimit(200);
					
					list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());
                   	
                   	AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
            	}
            	
            	else if(sObjectName == 'Customer_Receipt__c'){
            		
            		List<Customer_Receipt__c> crList = mObjectRecs.get(sObjectName);
   					
   					SOQLUtil soql1 = new SOQLUtil('Accounting_Entry__c', false); //enforceFLS=false, running in system mode
					soql1.addFields(new set<string>{
						'Id'
					});
					soql1.setWhereClause('Customer_Receipt__c IN :crList  and status__c = \'Active\' and has_exceptions__c = false and total_lines__c = 0');
 					list<Accounting_Entry__c> aeList = Database.query(soql1.getQuery());
					if(aeList.size() > 0){
                		AccountingEntryService.getInstance().AccountingEntryReversal(AccountingEntryService.AEReverseType.AEVoid, aeList);
                	}         		
                	
        			SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
					soql.addFields(new set<string>{
						'id','name'
					});
					soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Customer_Receipt__c IN :crList)');
					soql.setLimit(200);
					
					list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());
					
        			AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
            	}
                else if(sObjectName == 'Bank_Transaction_Group__c'){
                	List<Bank_Transaction_Group__c> btgList = mObjectRecs.get(sObjectName);
   					
   					SOQLUtil soql1 = new SOQLUtil('Accounting_Entry__c', false); //enforceFLS=false, running in system mode
					soql1.addFields(new set<string>{
						'Id'
					});
					soql1.setWhereClause('Bank_Transaction_Group__c IN :btgList  and status__c = \'Active\' and has_exceptions__c = false and total_lines__c = 0');
 					list<Accounting_Entry__c> aeList = Database.query(soql1.getQuery());
					if(aeList.size() > 0){
                		AccountingEntryService.getInstance().AccountingEntryReversal(AccountingEntryService.AEReverseType.AEVoid, aeList);
                	}    
                	
                    list<Accounting_Entry_Line__c> AELList = [select id, name from Accounting_Entry_Line__c where Accounting_Entry__c IN (select Id from Accounting_Entry__c where Bank_Transaction_Group__c IN: mObjectRecs.get(sObjectName)) limit 200];
                    AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
                }

            	else if(sObjectName == 'Receiving_Document__c'){
            		
					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					List<Receiving_Document__c> rdList = mObjectRecs.get(sObjectName);
					
					SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', false); //enforceFLS=false, running in system mode
					soql.addFields(new set<string>{
						'Id'
					});
					soql.setWhereClause('Receiving_Document__c IN :rdList and status__c = \'Active\' and has_exceptions__c = false and total_lines__c = 0');
					
					list<Accounting_Entry__c> aeList = Database.query(soql.getQuery());

                	if(aeList.size() > 0){
                		AccountingEntryService.getInstance().AccountingEntryReversal(AccountingEntryService.AEReverseType.AEVoid, aeList);
                	}
            		
            		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					
					soql = new SOQLUtil('Accounting_Entry_Line__c', false); //enforceFLS=false, running in system mode
					soql.addFields(new set<string>{
						'id','name'
					});
					soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Receiving_Document__c IN :rdList)');
					
					list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());
					
                   	AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELList);
	            }

				else{	                
                	accserv.execute(mObjectRecs.get(sObjectName));
                }
                //finishedAccountingEntries.addAll(accserv.getFinishedAccountingEntries());
              
            }else{
                throw new VoidCancelException(sObjectName + ' is not a valid source document');
            }
        }
        
        string wherestr = String.join(SchemaUtil.getInstance().relatedCustomObjects('Accounting_Entry__c'),' IN :voidIds OR ') +' IN :voidIds ';
		string q = SchemaUtil.getInstance().generateQueryFromFieldSet( 'Accounting_Entry__c',
			new set<string>{'Source_Documents'}, 
			new set<string>{'id','Source_Document_Object_Name__c','Transaction_Type__c', 'Company__c', 'Company__r.Id', 'Company__r.Name'}, '(' + wherestr + ') and Status__c=\'Active\' ');
		
		system.debug('q: ' + q);
		finishedAccountingEntries = database.query ( q );
        
        Map<Id, List<Accounting_Entry__c>> mAEs = new Map<Id, List<Accounting_Entry__c>>();
        for(Accounting_Entry__c ae : finishedAccountingEntries){
        	Id sourceDocId = (Id)ae.get(AccountingEntryService.SourceDocPathMap.get(ae.Source_Document_Object_Name__c));
        	if(mAEs.containsKey(sourceDocId)){
        		mAEs.get(sourceDocId).add(ae);
        	}else{
        		mAEs.put(sourceDocId, new List<Accounting_Entry__c>{ae});
        	}
        }
        
        for(sObject s : sObjRecs){
        	VoidCancelResponse iVCR = new VoidCancelResponse();
        	iVCR.recordId = s.Id;
        	iVCR.recordName = (string)s.get('Name');
        	iVCR.action = Action.VOIDDOC;
        	
        	if(mAEs.containsKey(s.Id)){
	        	//simple test, each SD should have 2 AEs, the original and the voiding entry
	        	iVCR.success = mAEs.get(s.Id).size() == 2;
        	}else{
        		iVCR.success = false;
        	}
        	
        	if(!iVCR.success){
        		iVCR.messages.add('Unable to complete accounting void');
        		Database.rollback(sp); 
        	}
        	mResponses.put(iVCR.recordId, iVCR);
        }
        
        
        return mResponses;
    } 
    
    private Map<Id, VoidCancelResponse> accountingCancel(List<sObject> sObjRecs){
        Map<Id, VoidCancelResponse> mResponses = new Map<Id, VoidCancelResponse>();
        Map<Id, UnfinalizeService.UnfinalizeResponse> mUnfinalizeResponses = UnfinalizeService.unfinalizeSourceDocs(sObjRecs, true);
        for(sObject sObj : sObjRecs){
        	VoidCancelResponse iVCR = new VoidCancelResponse();
        	iVCR.recordId = sObj.Id;
        	iVCR.recordName = (string)sObj.get('Name');
        	iVCR.action = Action.CANCELDOC;
        	if(mUnfinalizeResponses.containsKey(sObj.Id)){
        		iVCR.success = mUnfinalizeResponses.get(sObj.Id).success;
        		if(!iVCR.success){
        			iVCR.messages.add(mUnfinalizeResponses.get(sObj.Id).message);
        		}
        	}else{
        		iVCR.success = false;
        		iVCR.messages.add('Unable to cancel ' + iVCR.recordName);
        		Database.rollback(sp); 
        	}
        	mResponses.put(sObj.ID, iVCR);
        }
        return mResponses; 
    } 
    
    
    public class VoidCancelDetail { 
    	
    	public Id recordId {get;set;}
    	public string recordName {get;set;}
    	public boolean isCancellable  {get;set;}
    	public boolean isVoidable  {get;set;}
        public list<string> cancelMessages {get;set;}
        public list<string> voidMessages {get;set;}
        
        public VoidCancelDetail(){
        	this.voidMessages = new List<string>();
        	this.cancelMessages = new List<string>();
        }
        
        public VoidCancelDetail(Id recordId, string recordName, boolean isCancellable, boolean isVoidable, list<string> cancelMessages, list<string> voidMessages){
        	this();
        	this.recordId = recordId;
        	this.recordName = recordName;
        	this.isCancellable = isCancellable;
        	this.isVoidable = isVoidable;
        	this.cancelMessages = cancelMessages;
        	this.voidMessages = voidMessages;
        }
    }
    
    public class VoidCancelResponse {
        public Id recordId;
        public string recordName;
        public boolean success;
        public list<string> messages {get;set;}
        public Action action;
        
        public VoidCancelResponse() {
        	this.messages = new list<string>();
        }
        
        public VoidCancelResponse(Id recordId, string recordName, boolean success, list<string> messages, Action action) {
            this();
            this.recordId = recordId;
            this.success = success;
            this.messages = messages;
            this.action = action;
        }
    }
    
    
    public static final string VALIDATE_FIELD_SET = 'Void_Cancel';
    public static final string VOID_STATUS = 'Void';
    public static final string CANCELLED_STATUS = 'Cancelled';
    public static final Set<String> REOPEN_SERVICE = new Set<String>{'Purchase_Order__c','Purchase_Order_Line__c','Contract__c'};
    
    
    private static map<Schema.sObjectType, map<string, string>> mValidateFields = new map<Schema.sObjectType, map<string, string>>();
    public static map<string, string> sObjectValidateFields(Schema.sObjectType sObjectType){
       system.debug( mValidateFields);
        map<string, string> mFieldLabel = new map<string, string>();
        if(mValidateFields.containsKey(sObjectType)){
            mFieldLabel = mValidateFields.get(sObjectType);

        }else{
        	system.debug(SchemaUtil.getInstance().getFieldsFromFieldSet(sObjectType, VALIDATE_FIELD_SET));
        	for( Schema.FieldSetMember fsm : SchemaUtil.getInstance().getFieldsFromFieldSet(sObjectType, VALIDATE_FIELD_SET) ){  
        		  system.debug( fsm);
	            mFieldLabel.put(fsm.getFieldPath(), fsm.getLabel());
        	}
        	mValidateFields.put(sObjectType, mFieldLabel);
        }
        return mFieldLabel; 
    }
    
/*     public static void validateHeader() {
    	List<sObject> sObjRecs = new List<sObject>();
        if(trigger.isBefore && trigger.isUpdate){
        	sObjRecs = trigger.new;
        }else if(trigger.isBefore && trigger.isDelete){
        	sObjRecs = trigger.old;
        }
		
		if(sObjRecs != null && sObjRecs.size() > 0) {
	        Schema.sObjectType sObjectType = sObjRecs[0].getSObjectType();
	        
	        map<string, string> validateFields = sObjectValidateFields(sObjectType);
	        Map<String,String> objectFields = SchemaUtil.getInstance().getFieldNamesMap(sObjectType.getDescribe().getName());
	        
	        if(trigger.isBefore){
	            for(integer i = 0; i< sObjRecs.size(); i++){
	                sObject sObj = sObjRecs[i];
	                SchemaUtil util = SchemaUtil.getInstance();
	                String objectName = sObjectType.getDescribe().getLocalName();
	                if(!REOPEN_SERVICE.contains(objectName)) {
		                if (util.fieldExists(objectName,'Void__c') && (Boolean) trigger.old[i].get('Void__c') && !(Boolean) sObj.get('Void__c')){
		                
		            		 trigger.new[i].addError(objectFields.get('Void__c') + ' cannot be changed on a ' + (String) trigger.old[i].get('Status__c') + ' ' + sObjectType.getDescribe().getLabel());                  
			            }
			            if ((String) trigger.old[i].get('Status__c') == CANCELLED_STATUS && (String) sObj.get('Status__c') != CANCELLED_STATUS){
			            	
		            		 trigger.new[i].addError(objectFields.get('Status__c') + ' cannot be changed on a ' + (String) trigger.old[i].get('Status__c') + ' ' + sObjectType.getDescribe().getLabel());                 
			            }
	                }
	                
	                if((Boolean) trigger.old[i].get('Void__c') || (String) trigger.old[i].get('Status__c') == CANCELLED_STATUS){
	
	                    for(String f : validateFields.keySet()) {
	                    	objectFields.remove(f);
	                    }
	                    
	                    if(trigger.isBefore && trigger.isUpdate){
	                        for(string field : objectFields.keyset()){
	                            if(trigger.new[i].get(field) != trigger.old[i].get(field)){
	                                trigger.new[i].addError(objectFields.get(field) + ' cannot be changed on a ' + (String) trigger.old[i].get('Status__c') + ' ' + sObjectType.getDescribe().getLabel());
	                            }
	                        }
	                        
	                    }
	                    if(trigger.isBefore && trigger.isDelete){
	                    	trigger.old[i].addError(Label.You_cannot_delete_a_Finalized.replace('finalized',(String) trigger.old[i].get('Status__c')) +' '+ sObjectType.getDescribe().getLabel());
	                    }
	                }
	            }
	        }
        }
    }*/
    
    public static void validateLines() {
    	List<sObject> sObjRecs = new List<sObject>();
        if(trigger.isBefore && trigger.isUpdate){
        	sObjRecs = trigger.new;
        }else if(trigger.isBefore && trigger.isDelete){
        	sObjRecs = trigger.old;
        }
        
		if(sObjRecs != null && sObjRecs.size() > 0) {
	        Schema.sObjectType sObjectType = sObjRecs[0].getSObjectType();
	        
	        map<string, string> validateFields = sObjectValidateFields(sObjectType);
	        Map<String,String> objectFields = SchemaUtil.getInstance().getFieldNamesMap(sObjectType.getDescribe().getName());
	        
	        if(trigger.isBefore){
	            for(integer i = 0; i< sObjRecs.size(); i++){
	                
	                sObject sObj = sObjRecs[i];
	                if(!REOPEN_SERVICE.contains(sObjectType.getDescribe().getLocalName())) {
		                if ((String) trigger.old[i].get('Status__c') == VOID_STATUS && (String) sObj.get('Status__c') != VOID_STATUS){
		            		 trigger.new[i].addError(objectFields.get('Status__c') + ' cannot be changed on a ' + (String) trigger.old[i].get('Status__c') + ' ' + sObjectType.getDescribe().getLabel());                  
			            }
			            if ((String) trigger.old[i].get('Status__c') == CANCELLED_STATUS && (String) sObj.get('Status__c') != CANCELLED_STATUS){
			            	
		            		 trigger.new[i].addError(objectFields.get('Status__c') + ' cannot be changed on a ' + (String) trigger.old[i].get('Status__c') + ' ' + sObjectType.getDescribe().getLabel());                 
			            }
	                }
	                
	                if((String) trigger.old[i].get('Status__c') == VOID_STATUS || (String) trigger.old[i].get('Status__c') == CANCELLED_STATUS){
	
	                    for(String f : validateFields.keySet()) {
	                    	objectFields.remove(f);
	                    }
	                    
	                    if(trigger.isBefore && trigger.isUpdate){
	                        for(string field : objectFields.keyset()){
	                            if(trigger.new[i].get(field) != trigger.old[i].get(field)){
	                                trigger.new[i].addError(objectFields.get(field) + ' cannot be changed on a ' + (String) trigger.old[i].get('Status__c') + ' ' + sObjectType.getDescribe().getLabel());
	                            }
	                        }
	                        
	                    }
	                    if(trigger.isBefore && trigger.isDelete){
	                    	trigger.old[i].addError(Label.You_cannot_delete_a_Finalized.replace('finalized',(String) trigger.old[i].get('Status__c')) +' '+ sObjectType.getDescribe().getLabel());
	                    }
	                }
	            }
	        }
    	}
    }
 
}