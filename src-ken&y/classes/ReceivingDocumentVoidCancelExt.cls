public with sharing class ReceivingDocumentVoidCancelExt extends VoidCancelBaseExt {
	
	public VoidCancelService voidCancelSvc {get;private set;}
	public Apexpages.Standardcontroller con {get;set;}
	
	public string namespace {get;set;}
    public boolean AlreadyVoided{get;set;}
    @testvisible public integer reverseSize{get;set;}
    @testvisible public string reverseChunkMap{get;set;}	
    @testvisible public ID voidAEId{get;set;} 
    @testvisible public decimal AELineCount{get;set;} 
    @testvisible public list<sObject> voidRD{get;set;} 
    @testvisible public string voidRDSer{get;set;} 
	public ReceivingDocumentVoidCancelExt(Apexpages.Standardcontroller controller){
		this.con = controller;
		this.namespace = KSE.NamespaceUU;
		voidCancelSvc = new ReceivingDocumentVoidCancelService(new List<sObject>{con.getRecord()});
		voidRD= new list<sObject>();
		voidRD.add(con.getrecord());
		voidRDSer = json.serialize(voidRD);
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
		Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = voidCancelSvc.voidSourceDocuments(new List<sObject>{con.getRecord()});
		String message = '';
		for(String m :  VoidCancelResponses.get(con.getId()).messages) {
			message += m;
		}
		
		ApexPages.severity severity = ApexPages.severity.INFO;
		if(VoidCancelResponses.get(con.getId()).success == false){
		    severity = ApexPages.severity.ERROR;
		}
		
		ApexPages.addMessage(new ApexPages.Message(severity, message));
		if(!test.isrunningtest())
		    con.reset();
		
		voidCancelSvc = new ReceivingDocumentVoidCancelService(new List<sObject>{con.getRecord()});
		//TODO: Process results and display to user
		return null;
	}
	
	public pageReference cancelDocs(){
		Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = voidCancelSvc.cancelSourceDocuments(new List<sObject>{con.getRecord()});
		String message = '';
		for(String m :  VoidCancelResponses.get(con.getId()).messages) {
			message += m;
		}
		
		ApexPages.severity severity = ApexPages.severity.INFO;
		if(VoidCancelResponses.get(con.getId()).success == false){
		    severity = ApexPages.severity.ERROR;
		}
		
		ApexPages.addMessage(new ApexPages.Message(severity, message));
		if(!test.isrunningtest())
		    con.reset();
		
		voidCancelSvc = new ReceivingDocumentVoidCancelService(new List<sObject>{con.getRecord()});
		//TODO: Process results and display to user
		return null;
	}
    public void prepreVoid(){
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id conId = con.getid();
		
		SOQLUtil soql = new SOQLUtil('Receiving_Document__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','void__c'
		});
		soql.setWhereClause('id = :conId');

		Receiving_Document__c rd = Database.query(soql.getQuery());

        if(rd.void__c == true){
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
		
		SOQLUtil soql = new SOQLUtil('Receiving_Document__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','void__c'
		});
		soql.setWhereClause('id = :voidAEId');

		Receiving_Document__c rd = Database.query(soql.getQuery());

        if(rd.void__c == true){
           stopRetry = true;      
        }
        return stopRetry;
	    	
    }
}