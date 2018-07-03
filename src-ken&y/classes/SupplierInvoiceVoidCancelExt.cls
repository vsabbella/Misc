public with sharing class SupplierInvoiceVoidCancelExt extends VoidCancelBaseExt {
	
	public VoidCancelService voidCancelSvc {get;private set;}
	@testvisible public Apexpages.Standardcontroller con {get;set;}
    public static integer intg= 0;
    public boolean AlreadyVoided{get;set;}
    
	
	public string namespace {get;set;}
    @testvisible public integer reverseSize{get;set;}
    @testvisible public string reverseChunkMap{get;set;}	
    @testvisible public ID voidAEId{get;set;} 
    @testvisible public ID supplierInvoiceID{get;set;}     
    @testvisible public decimal AELineCount{get;set;} 
    @testvisible public list<sObject> voidSI{get;set;} 
    @testvisible public string voidSISer{get;set;} 
    
    public SupplierInvoiceVoidCancelExt(Apexpages.Standardcontroller controller){
		this.con = controller;
		this.namespace = KSE.NamespaceUU;
		voidSI= new list<sObject>();
		voidSI.add(con.getrecord());
		voidSISer = json.serialize(voidSI);
		supplierInvoiceID = con.getid();
		
		Supplier_Invoice__c si = (Supplier_Invoice__c)con.getrecord();
		voidCancelSvc = new SupplierInvoiceVoidCancelService(new List<sObject>{con.getRecord()});
		if(!getDisableVoid()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, label.Void_date_Info)); 
            
           if(si.void_date__c == null)
             si.void_date__c = system.now();
        }
        getguid();
	}	
	
	public boolean getDisableVoid(){
		return !voidCancelSvc.getVoidCancelDetails().get(con.getId()).isVoidable;
	}
	
	public boolean getDisableCancel(){
		return !voidCancelSvc.getVoidCancelDetails().get(con.getId()).isCancellable;
	}
	
	public VoidCancelService.VoidCancelDetail getVoidCancelDetails(){
		return voidCancelSvc.getVoidCancelDetails().get(con.getId());
	}

	public pageReference voidDocs(){
		String message = '';
        if(getDisableVoid()){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This Supplier Invoice cannot be voided')); 
        }else{
        	
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','Accounting_Entry__c'
			});
			soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where supplier_Invoice__c = :con.getRecord().id )');
			soql.setLimit(200);

			list<Accounting_Entry_Line__c> AELList = Database.query(soql.getQuery());

			if(AELList.size() > 100){
    			Id jobId = Database.Executebatch(new AccountingEntryVoidBatch(new set<Id>{AELList[0].Accounting_Entry__c}));					
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'There is a large volume of lines for this source document. Batch Process '+jobid+' has been initiated'));
        	}
			else{
				Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = voidCancelSvc.voidSourceDocuments(new List<sObject>{con.getRecord()});
				for(String m :  VoidCancelResponses.get(con.getId()).messages) {
					message += m;
				}
			}
        }
		if (message.length()>0)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, MessageUtil.toFriendlyErrorMessage(message)));
		con.reset();
		voidCancelSvc = new SupplierInvoiceVoidCancelService(new List<sObject>{con.getRecord()});
		//TODO: Process results and display to user
		return null;
	}
	
	public pageReference cancelDocs(){

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('supplier_invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','void__c'
		});

		soql.setWhereClause('id = :supplierInvoiceID');


		supplier_invoice__c si = Database.query(soql.getQuery());

        if(si.void__c == true){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'This document is already voided'));
    	}else{
			Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = voidCancelSvc.cancelSourceDocuments(new List<sObject>{con.getRecord()});
			String message = '';
			for(String m :  VoidCancelResponses.get(con.getId()).messages) {
				message += m;
			}
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, MessageUtil.toFriendlyErrorMessage(message)));
			if(!Test.isRunningTest()){
				con.reset();
			}
			voidCancelSvc = new SupplierInvoiceVoidCancelService(new List<sObject>{con.getRecord()});
			//TODO: Process results and display to user
        }
		return null;
       
	}
	
    public void prepreVoid(){
    	
    	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id conId = con.getid();
		SOQLUtil soql = new SOQLUtil('supplier_invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','void__c'
		});
		soql.setWhereClause('id = :conId');

		supplier_invoice__c si = Database.query(soql.getQuery());
    	
        system.debug('si.void__c ****' + si.void__c);
        
        if(si.void__c == true){
           AlreadyVoided = true;
    	}else{
			ChunkReverseResult obj =  prepreVoidDoc(con.getId()); 
			reverseSize = obj.reverseSize;
			reverseChunkMap = obj.reverseChunkMap;
			AELineCount = obj.AELineCount; 
			voidAEId = obj.voidedAEId;	
        }	
    }
    
    @RemoteAction
    public static boolean getstopRetry(id voidAEId){
    	boolean stopRetry = false;

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('supplier_invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','void__c'
		});
		soql.setWhereClause('id =: voidAEId');

		supplier_invoice__c si = Database.query(soql.getQuery());

        if(si.void__c == true){
           stopRetry = true;      
        }
        return stopRetry;
	    	
    }
}