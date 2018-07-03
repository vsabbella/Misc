public with sharing class CustomerInvoiceVoidCancelExt extends VoidCancelBaseExt {
	
	public VoidCancelService voidCancelSvc {get;private set;}
	public Apexpages.Standardcontroller con {get;set;}
	
	public string namespace {get;set;}
    public boolean AlreadyVoided{get;set;}
    @testvisible public integer reverseSize{get;set;}
    @testvisible public string reverseChunkMap{get;set;}	
    @testvisible public ID voidAEId{get;set;} 
    @testvisible public decimal AELineCount{get;set;} 
    @testvisible public list<sObject> voidCI{get;set;} 
    @testvisible public string voidCISer{get;set;} 

	public CustomerInvoiceVoidCancelExt(Apexpages.Standardcontroller controller)
	{
		this.con = controller;
		this.namespace = KSE.NamespaceUU;
		
		voidCI= new list<sObject>();
		voidCI.add(con.getrecord());
		voidCISer = json.serialize(voidCI);
		Customer_Invoice__c ci = (Customer_Invoice__c)con.getrecord();
		voidCancelSvc = new CustomerInvoiceVoidCancelService(new List<sObject>{con.getRecord()}, true); //Calling from UI
		if(!getDisableVoid()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, label.Void_date_Info)); 
            
           if(ci.void_date__c == null)
             ci.void_date__c = system.now();
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
	
	public void voidDetails()
	{
		VoidCancelService.VoidCancelDetail details =  voidCancelSvc.getVoidCancelDetails().get(con.getId());
		for(String message: details.voidMessages)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(message)));
		}
		
	}
	public void cancelDetails()
	{
		VoidCancelService.VoidCancelDetail details =  voidCancelSvc.getVoidCancelDetails().get(con.getId());
		for(String message: details.cancelMessages)
		{
			system.debug('Cancel Messages: '+message);
			if(message != null) //since accountingcancel will retun null
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(message)));
		}
		
	}
	
	public pageReference voidDocs(){
		String message = '';
        if(getDisableVoid()){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This Customer Invoice cannot be voided')); 
        }
        else
        {
			Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = voidCancelSvc.voidSourceDocuments(new List<sObject>{con.getRecord()});
			for(String m :  VoidCancelResponses.get(con.getId()).messages) {
				message += m;
			}
		}
       
		if (message.length()>0)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, MessageUtil.toFriendlyErrorMessage(message)));
		if(!test.isRunningTest())
			con.reset();
		voidCancelSvc = new CustomerInvoiceVoidCancelService(new List<sObject>{con.getRecord()});
		//TODO: Process results and display to user
		return null;
	}
	
	public pageReference cancelDocs(){
		if(getDisableCancel()){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This Customer Invoice cannot be voided')); 
        }
        else
        {
			Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = voidCancelSvc.cancelSourceDocuments(new List<sObject>{con.getRecord()});
			String message = '';
			for(String m :  VoidCancelResponses.get(con.getId()).messages) {
				message += m;
			}
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, MessageUtil.toFriendlyErrorMessage(message)));
			if(!test.isRunningTest())
				con.reset();
			voidCancelSvc = new CustomerInvoiceVoidCancelService(new List<sObject>{con.getRecord()});
			//TODO: Process results and display to user
        }
		return null;
	}

    public void prepreVoid(){
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','void__c'
		});
		Id recordId = con.getid();
		soql.setWhereClause('id =: recordId');
		Customer_Invoice__c sp = Database.query(soql.getQuery());

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
		SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','void__c'
		});
		soql.setWhereClause('id =: voidAEId');
		Customer_Invoice__c ci = Database.query(soql.getQuery());

        if(ci.void__c == true){
           stopRetry = true;      
        }
        return stopRetry;
	    	
    }
}