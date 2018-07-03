public with sharing class CustomerReceiptVoidCancelExt extends VoidCancelBaseExt{
	
	public VoidCancelService voidCancelSvc {get;private set;}
	public Apexpages.Standardcontroller con {get;set;}
	public string namespace {get;set;}
    public boolean AlreadyVoided{get;set;}
    @testvisible public integer reverseSize{get;set;}
    @testvisible public string reverseChunkMap{get;set;}	
    @testvisible public ID voidAEId{get;set;} 
    @testvisible public decimal AELineCount{get;set;} 
    @testvisible public list<sObject> voidCR{get;set;} 
    @testvisible public string voidCRSer{get;set;} 
	
	public CustomerReceiptVoidCancelExt(Apexpages.Standardcontroller controller)
	{
		this.con = controller;
		this.namespace = KSE.NamespaceUU;
		voidCR= new list<sObject>();
		voidCR.add(con.getrecord());
		voidCRSer = json.serialize(voidCR);
		voidCancelSvc = new CustomerReceiptVoidCancelService(new List<sObject>{con.getRecord()}, true); //Calling from UI
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
	
	public list<String> getBankTransactionMatchesErrors(){
		return BankTransactionMatchService.getMatchesErrors('Customer_Receipt__c', con.getId());
	}
	
	public void voidDetails()
	{
		Customer_Receipt__c cr = (Customer_Receipt__c)con.getrecord();
		if(!getDisableVoid()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, label.Void_date_Info)); 
            
           if(cr.void_date__c == null)
             cr.void_date__c = system.now();
        }
		
		VoidCancelService.VoidCancelDetail details =  voidCancelSvc.getVoidCancelDetails().get(con.getId());
		for(String message: details.voidMessages)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, message)); 
		}
		for(String warning : getBankTransactionMatchesErrors()) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, warning));
		}
		
	}
	public void cancelDetails()
	{
		VoidCancelService.VoidCancelDetail details =  voidCancelSvc.getVoidCancelDetails().get(con.getId());
		for(String message: details.cancelMessages)
		{
			system.debug(logginglevel.error,'Cancel Messages: '+message);
			if(message != null) //since accountingcancel will retun null
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, message)); 
		}
		for(String warning : getBankTransactionMatchesErrors()) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, warning));
		}
		
	}
	
	public pageReference voidDocs(){
		if(getDisableVoid()){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This Customer Receipt cannot be voided')); 
        }
        else
        {
			Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = voidCancelSvc.voidSourceDocuments(new List<sObject>{con.getRecord()});
			VoidCancelService.VoidCancelResponse response = VoidCancelResponses.get(con.getId());
			if(response.success)
			{
				for(String m :  VoidCancelResponses.get(con.getId()).messages) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, m));
				}
			}
			else
			{
				for(String m :  VoidCancelResponses.get(con.getId()).messages) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, m));
				}
			}
			
		}
       	if(!test.isRunningTest())
			con.reset();
		voidCancelSvc = new CustomerReceiptVoidCancelService(new List<sObject>{con.getRecord()});
		return null;
	}
	
	public pageReference cancelDocs(){
		if(getDisableCancel()){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This Customer Receipt cannot be cancelled')); 
        }
        else
        {
        	try {
        		Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = voidCancelSvc.cancelSourceDocuments(new List<sObject>{con.getRecord()});
				VoidCancelService.VoidCancelResponse response = VoidCancelResponses.get(con.getId());
				if(response.success)
				{
					for(String m :  VoidCancelResponses.get(con.getId()).messages) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, m));
					}
				}
				else
				{
					for(String m :  VoidCancelResponses.get(con.getId()).messages) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, m));
					}
				}
			
        		
        	}catch(DmlException ex) { //AR-130
                for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getDmlMessage(idx))));
					system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getDmlMessage(idx) + ' ' + ex.getStackTraceString());
                }
        		
        	}
        }
        if(!test.isRunningTest())
			con.reset();
		voidCancelSvc = new CustomerReceiptVoidCancelService(new List<sObject>{con.getRecord()});
		return null;
	}

    public void prepreVoid(){
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','void__c'
		});
		Id recordId = con.getid();
		soql.setWhereClause('id =: recordId');
		Customer_Receipt__c cr = ((List<Customer_Receipt__c>)Database.query(soql.getQuery()))[0];

        if(cr.void__c == true){
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
		SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','void__c'
		});
		soql.setWhereClause('id =: voidAEId');
		Customer_Receipt__c cr = ((List<Customer_Receipt__c>)Database.query(soql.getQuery()))[0];

        if(cr.void__c == true){
           stopRetry = true;      
        }
        return stopRetry;
	    	
    }
    
    @RemoteAction
    public static JSONResult voidTransaction(Id crId, String transactionId) {
    	JSONResult result = new JSONResult();
    	Service_Configuration__c sc = Service_Configuration__c.getAll().get('AuthorizeNetV1');
    	if(sc != null && !String.isBlank(transactionId)) {
    		PaymentHandler ph = new PaymentHandler();
	    	result.success = false;
	    	
	    	try {
	    		result.success = ph.voidTransaction(crId, transactionId);
		    	if(result.success) 
		    		result.addMessage('Transaction successfully voided at the gaetway. ',ApexPages.Severity.CONFIRM);
		    	else
		    		result.addMessage('Unable to void transaction at the gateway.',ApexPages.Severity.ERROR);
	    		return result;  
	    	}catch(Exception ex) {
	    		result.addMessage( ex.getMessage(), ApexPages.severity.ERROR);
				return result;
	    	}
    	}else {
    		result.success = true;
    		return result;
    	}
    	
    	                                                                                       
    }
}