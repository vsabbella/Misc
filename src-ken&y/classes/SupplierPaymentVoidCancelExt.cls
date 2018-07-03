public with sharing class SupplierPaymentVoidCancelExt extends VoidCancelBaseExt {
	
	public VoidCancelService voidCancelSvc {get;private set;}
	public Apexpages.Standardcontroller con {get;set;}
	
	public string namespace {get;set;}
    public boolean AlreadyVoided{get;set;}
    @testvisible public integer reverseSize{get;set;}
    @testvisible public string reverseChunkMap{get;set;}	
    @testvisible public ID voidAEId{get;set;} 
    @testvisible public ID supplierPaymentID{get;set;}     
    @testvisible public decimal AELineCount{get;set;} 
    @testvisible public list<sObject> voidSI{get;set;} 
    @testvisible public string voidSISer{get;set;} 

	public SupplierPaymentVoidCancelExt(Apexpages.Standardcontroller controller){
		this.con = controller;
		this.namespace = KSE.NamespaceUU;
		voidSI= new list<sObject>();
		voidSI.add(con.getrecord());
		supplierPaymentID = con.getID();
		voidSISer = json.serialize(voidSI);
		
		Supplier_Payment__c sp = (Supplier_Payment__c)con.getrecord();
        voidCancelSvc = new SupplierPaymentVoidCancelService(new List<sObject>{con.getRecord()});
        if(!getDisableVoid()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, label.Void_date_Info)); 
            
           if(sp.void_date__c == null)
             sp.void_date__c = system.now();
        }
        getguid();
	}	
	
	public boolean getDisableVoid(){
		return !voidCancelSvc.getVoidCancelDetails().get(con.getId()).isVoidable;
	}
	
	public boolean getDisableCancel(){
		return !voidCancelSvc.getVoidCancelDetails().get(con.getId()).isCancellable;
	}
	
	public list<String> getBankTransactionMatchesErrors(){
		return BankTransactionMatchService.getMatchesErrors('Supplier_Payment__c', con.getId());
	}
	
	
	public VoidCancelService.VoidCancelDetail getVoidCancelDetails(){
		VoidCancelService.VoidCancelDetail detail = voidCancelSvc.getVoidCancelDetails().get(con.getId());
		list<String> lWarnings = getBankTransactionMatchesErrors();
		detail.voidMessages.addAll(lWarnings);
		lWarnings = SupplierPaymentService.getSPVoidCancelErrors(con.getId()); //KNDY-13854
		detail.voidMessages.addAll(lWarnings);
		if (lWarnings != null && lWarnings.size() > 0){ //KNDY-13654
			 // disable the void button on page
			detail.isVoidable = false; 
		}
		//detail.cancelMessages.addAll(lWarnings);
		
		return detail;
	}

	public pageReference voidDocs(){
 		String message = '';
        if(getDisableVoid()){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This Supplier Invoice Payment cannot be voided')); 
        }else{
        	
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','Accounting_Entry__c'
			});
			soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where supplier_Payment__c =: con.getRecord().id )');
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
		voidCancelSvc = new SupplierPaymentVoidCancelService(new List<sObject>{con.getRecord()});
		//TODO: Process results and display to user
		return null;
	}
	
	public pageReference cancelDocs(){
	    System.debug(logginglevel.error,'Inside the method cancelDocs');
	    String message = '';
	    
        if(getDisableCancel()){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This Supplier Invoice Payment cannot be cancelled')); 
        }else{
		Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = voidCancelSvc.cancelSourceDocuments(new List<sObject>{con.getRecord()});
		for(String m :  VoidCancelResponses.get(con.getId()).messages) {
			message += m;
		}
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, MessageUtil.toFriendlyErrorMessage(message)));
	    }
		if(!Test.isRunningTest()){
		   con.reset();
		}      
		voidCancelSvc = new SupplierPaymentVoidCancelService(new List<sObject>{con.getRecord()});
		//TODO: Process results and display to user
		return null;
	}
    public void prepreVoid(){
    	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        //ID spID = con.getID();		
		SOQLUtil soql = new SOQLUtil('supplier_Payment__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','void__c'
		});
        soql.setWhereClause('id = :supplierPaymentID');

		supplier_Payment__c sp = Database.query(soql.getQuery());

        if(sp.void__c == true){
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
		
		SOQLUtil soql = new SOQLUtil('supplier_Payment__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','void__c'
		});
		soql.setWhereClause('id = :voidAEId');

		supplier_Payment__c sp = Database.query(soql.getQuery());

        if(sp.void__c == true){
           stopRetry = true;      
        }
        return stopRetry;
	    	
    }
}