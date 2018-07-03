public with sharing class JournalEntryVoidCancelExt extends VoidCancelBaseExt{
	
	public VoidCancelService voidCancelSvc {get;private set;}
	public Apexpages.Standardcontroller con {get;set;}
	
    public boolean AlreadyVoided{get;set;}
    
	
	public string namespace {get;set;}
    @testvisible public integer reverseSize{get;set;}
    @testvisible public string reverseChunkMap{get;set;}	
    @testvisible public ID voidAEId{get;set;} 
    @testvisible public decimal AELineCount{get;set;} 
    @testvisible public list<sObject> voidJE{get;set;} 
    @testvisible public string voidJESer{get;set;}
    public boolean periodOpen{get;set;}
    public boolean subledgerOpen{get;set;}

    public JournalEntryVoidCancelExt(Apexpages.Standardcontroller controller){
        this.con = controller;
        if (!Test.isRunningTest()){
        	con.addFields(new List<String>{'Company__c'});}
        this.namespace = KSE.NamespaceUU;
        voidJE= new list<sObject>();
        voidJE.add(con.getrecord());
        voidJESer = json.serialize(voidJE);
        Journal_Entry__c je = (Journal_Entry__c)con.getrecord();
        voidCancelSvc = new JournalEntryVoidCancelService(new List<sObject>{con.getRecord()});
        if(!getDisableVoid()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, label.Void_date_Info)); 
            
           if(je.void_date__c == null)
        	je.void_date__c = system.now();
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
		VoidCancelService.VoidCancelDetail detail = voidCancelSvc.getVoidCancelDetails().get(con.getId());
		list<String> lWarnings = getBankTransactionMatchesErrors();
		detail.voidMessages.addAll(lWarnings);
		detail.cancelMessages.addAll(lWarnings);
		
		return detail;
	}
	
	public list<String> getBankTransactionMatchesErrors(){
		return BankTransactionMatchService.getMatchesErrors('Journal_Entry_Line__c', con.getId());
	}

	public pageReference voidDocs(){
		String message = '';
		try{
            if(getDisableVoid()){
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, label.Cannot_Void_this_Journal_Entry)); 
            }else{
            

            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            //V1
            SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','name','Accounting_Entry__c'
            });
            id rId = con.getRecord().id;                
            soql.setWhereClause('Accounting_Entry__c IN (select Id from Accounting_Entry__c where Journal_Entry__c =:rId )');
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
		}
		catch(Exception e){
			if(apexPages.getMessages().size()==0)
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
                system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
		}
		if (message.length()>0)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, message));
		voidCancelSvc = new JournalEntryVoidCancelService(new List<sObject>{con.getRecord()});
		return null;
	}
	
	public pageReference cancelDocs(){
		Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = voidCancelSvc.cancelSourceDocuments(new List<sObject>{con.getRecord()});
		String message = '';
		for(String m :  VoidCancelResponses.get(con.getId()).messages) {
			message += m;
		}
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, message));
		voidCancelSvc = new JournalEntryVoidCancelService(new List<sObject>{con.getRecord()});
		return null;
	}
    
    public void prepreVoid(){
    	

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','name','void__c'
        });
        id cId = con.getid();
        soql.setWhereClause('id =:cId ');
        Journal_Entry__c je = Database.query(soql.getQuery());



        if(je.void__c == true){
           AlreadyVoided = true;
        }else{
            ChunkReverseResult obj =  prepreVoidDoc(con.getId()); 
            if(obj.allDone == false){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, obj.messages));
                
            }else{
            reverseSize = obj.reverseSize;
            reverseChunkMap = obj.reverseChunkMap;
            AELineCount = obj.AELineCount; 
            voidAEId = obj.voidedAEId;} 
        }   
    }
    
    @RemoteAction
    public static boolean getstopRetry(id voidAEId){
    	boolean stopRetry = false;
    	


        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','name','void__c'
        });
               
        soql.setWhereClause('id =: voidAEId');
        Journal_Entry__c je = Database.query(soql.getQuery());



        if(je.void__c == true){
           stopRetry = true;      
        }
        return stopRetry;
	    	
    }
}