public with sharing class BankTransactionVoidCancelService extends VoidCancelService{
    public list<Bank_Transaction_Group__c> lstBTG = new list<Bank_Transaction_Group__c>();
  
    
	//public boolean calledFromUI;
	public BankTransactionVoidCancelService(list<Bank_Transaction_Group__c> sObjects)
	{
		super(sObjects);
		lstBTG = new list<Bank_Transaction_Group__c>();  
    
		//calledFromUI = false;
	}
	
	//AR-75
   /*	public BankTransactionVoidCancelService(list<Bank_Transaction_Group__c> sObjects, boolean calledFromUI) // This constructor would be called from the UI controller and will set the boolena to true. 
	{
		super(sObjects);
		lstBTG = new list<Bank_Transaction_Group__c>();
     
		this.calledFromUI = calledFromUI;
	}     */
	
    public BankTransactionVoidCancelService(){
    }

	 public override Map<Id, VoidCancelService.VoidCancelDetail> getBusinessVoidCancelDetails(List<sObject> sObjRecs){
	 	Map<Id, VoidCancelService.VoidCancelDetail> mBusinessVoidCancelDetails = new Map<Id, VoidCancelService.VoidCancelDetail>();
	 	set<Id> sourceDocIds = new set<id>();
	 	if(!sObjRecs.isEmpty()){
	 		for(sObject sObjRec: sObjRecs){
	 			sourceDocIds.add(sObjRec.Id);
	 		}
	 	}	 		
     	lstBTG = [Select Id, Company__c, Exceptions_Count__c, Finalized__c, Finalized_Date__c, name, Void__c, Void_Date__c, Historical__c, Status__c,              
     					(Select Id from Bank_Transactions__r),
                		(select id, name from Accounting_Entries__r  where status__c = 'Active' and Has_Exceptions__c != true) 
                		From Bank_Transaction_Group__c where id in : sourceDocIds];
     
			     for(Bank_Transaction_Group__c btg : lstBTG){
			                VoidCancelDetail iVCD = new VoidCancelDetail();
			                iVCD.recordId = btg.Id;
			                iVCD.recordName = btg.Name;
			                iVCD.isVoidable = true;
			                iVCD.isCancellable = true;
			                iVCD.voidMessages = new List<string>();
			                iVCD.cancelMessages = new List<string>();
			                list<Accounting_Entry__c> aelist = btg.Accounting_Entries__r;

			                if(btg.Void__c == true){
			                    iVCD.cancelMessages.add( btg.Name + ': Cannot Cancel, this Bank Transaction is already Void');
			                }
			                if(btg.Status__c == 'Cancelled'){
			                    iVCD.voidMessages.add(btg.Name + ': Cannot Void, this Bank Transaction is already Cancelled');
			                }
			                if(!(aelist.size()> 0)){
			                    iVCD.voidMessages.add(btg.Name + ': Cannot Void, this Bank Transaction does not have Accounting Entry generated or have Exceptions'); 
			                }
			                if(iVCD.voidMessages.size() > 0) {
			                iVCD.isVoidable = false;
			                }
			                if(iVCD.cancelMessages.size() > 0) {
			                    iVCD.isCancellable = false;
			                }
			                
			                
			                mBusinessVoidCancelDetails.put(btg.Id, iVCD);    
			     }
	 
	 	return mBusinessVoidCancelDetails; 	 
	 }
	 
	 public override Map<Id, VoidCancelService.VoidCancelResponse> businessVoid(List<sObject> sObjRecs){
    	Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
    	Savepoint sp = Database.setSavepoint();
    	try {
    		
    		businessVoidCancel(lstBTG);
    		List<String> messages = new List<String>{'Successfully Voided!'};	
    		for(sObject sObj : sObjRecs)
	    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.VOIDDOC));
    	}
    	catch(Exception ex){
        //if(calledFromUI)    Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, ex.getMessage()));
            for(sObject sObj : sObjRecs){
            	mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), false, new List<String>{ex.getMessage()}, VoidCancelService.Action.VOIDDOC));
            }
            Database.rollback(sp);  
            return mResponses;
        }
    	return mResponses;
	 }
	 
	 public override Map<Id, VoidCancelService.VoidCancelResponse> businessCancel(List<sObject> sObjRecs){
    	Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
    	try {
    		
    		businessVoidCancel(lstBTG);
    		List<String> messages = new List<String>{'Successfully Cancelled!'};	
	    	for(sObject sObj : sObjRecs)
	    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.CANCELDOC));
    	}
    	catch(Exception ex){
        //if(calledFromUI)     Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, ex.getMessage()));
            for(sObject sObj : sObjRecs){
            	mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), false, new List<String>{ex.getMessage()}, VoidCancelService.Action.CANCELDOC));
            }
            Database.rollback(sp);  
            return mResponses;
        }
    	return mResponses;
	 }
	 
	 public void businessVoidCancel(list<Bank_Transaction_Group__c> lstBTG){
	 	list<Bank_Transaction_Match__c> lstBTMtoDel = returnBankTransactionMatches(lstBTG);
	 	DML.deleteAsUser(lstBTMtoDel);	 	
	 }
	 public list<Bank_Transaction_Match__c> returnBankTransactionMatches(list<Bank_Transaction_Group__c> lstBTG) {
	 	list<Bank_Transaction__c> lstBT = new list<Bank_Transaction__c>();
	 	boolean isReconciled = false;
	 	list<Bank_Transaction_Match__c> lstBTMtoDel = new list<Bank_Transaction_Match__c>();
	 	if(!lstBTG.isEmpty()){
	 		/*lstBT = [Select Id, Reconciled_As_Of_Date__c, Reconciled_Hidden__c,Bank_Transaction_Group__c,
 				     (Select Id from Bank_Transaction_Match__r)
 				     From Bank_Transaction__c where Bank_Transaction_Group__c in : lstBTG];
            */
            SOQLUtil soql = new SOQLUtil('Bank_Transaction__c', TRUE);
            soql.addFields('Bank_Transaction__c');
            soql.addFields(new Set<String>{'Id', 'Reconciled_As_Of_Date__c', 'Reconciled_Hidden__c','Bank_Transaction_Group__c'});
            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Bank_Transaction_Match__r');
       	    childRel.addField('Id');
            soql.addChildRelationship(childRel);
            soql.setWhereClause('Bank_Transaction_Group__c in : lstBTG'); 
            lstBT = database.query(soql.getQuery());
            
 			if(!lstBT.isEmpty()){
 				for(Bank_Transaction__c bt: lstBT){
 					if(!bt.Bank_Transaction_Match__r.isEmpty()){
 						lstBTMtoDel.addAll(bt.Bank_Transaction_Match__r);
 					}
 					if(bt.Reconciled_As_Of_Date__c != null){
	 					bt.Reconciled_As_Of_Date__c = null;
	 					bt.Reconciled_Hidden__c = false;
	 					isReconciled = true;
 					}
 				}
 			}
 			if(isReconciled){	
	 			DML.updateAsUser(lstBT);
 			}
	 	}
	 	return lstBTMtoDel;
	 }
	 
	 public map<Id,string> voidCancelBankTransactionGroup(list<Bank_Transaction_Group__c> lstBTG, string action, string voidDate){
        Map<Id, VoidCancelService.VoidCancelDetail> vcd = getBusinessVoidCancelDetails(lstBTG); 
        Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = new Map<Id, VoidCancelService.VoidCancelResponse>() ;  
         
        map<Id,string> mapBTGMessages = new map<Id,string>();
        if(!lstBTG.isEmpty() && action != null && action != '' && voidDate != null){
        	 list<Bank_Transaction_Group__c> lstValidatedBTG = new list<Bank_Transaction_Group__c>();
        	set<Id> invalidBTGIds = new set<Id>();
        	System.debug(logginglevel.error,'voidDate--->'+voidDate);
            //Datetime dt = (datetime)JSON.deserialize(voidDate, Datetime.class);
            Datetime dt = DateTime.valueof(voidDate.replace('T',' '));
	         for(Bank_Transaction_Group__c btg: lstBTG){
	            if(vcd.get(btg.id).cancelMessages.size()==0 && action.equalsIgnoreCase('cancel')){
	                lstValidatedBTG.add(btg);
	            }else if(vcd.get(btg.id).voidMessages.size()==0  && action.equalsIgnoreCase('void')){
	                btg.Void_Date__c = dt;
	                System.debug(logginglevel.error,'btg.Void_Date__c--->'+btg.Void_Date__c);
                    System.debug(logginglevel.error,'btg.Transaction_Date__c--->'+btg.Transaction_Date__c);
	                if(btg.Void_Date__c < btg.Transaction_Date__c){
	                  invalidBTGIds.add(btg.Id);  
	                }else{
	                lstValidatedBTG.add(btg);
	            }
	         }
	         }
	         
	         System.debug(logginglevel.error,'invalidBTGIds--->'+invalidBTGIds);
	         System.debug(logginglevel.error,'lstValidatedBTG--->'+lstValidatedBTG);
	         if(action.equalsIgnoreCase('cancel') && !lstValidatedBTG.isEmpty()){
                 VoidCancelResponses = CancelSourceDocuments (lstValidatedBTG);
        	 }else if(action.equalsIgnoreCase('void')&& !lstValidatedBTG.isEmpty()){
            	VoidCancelResponses = VoidSourceDocuments (lstValidatedBTG);
        	 }
        	 for(Bank_Transaction_Group__c btg: lstBTG){
        	 	list<String> messagesforBTG=new list<String>();
	            if(action.equalsIgnoreCase('cancel') && vcd.containsKey(btg.id)){
	                messagesforBTG= vcd.get(btg.id).cancelMessages; 
	            }else if(action.equalsIgnoreCase('void')&& vcd.containsKey(btg.id) ){
	                messagesforBTG=  vcd.get(btg.id).voidMessages ;
	            }
	            if(VoidCancelResponses.containsKey(btg.id)){
	                messagesforBTG.addAll(VoidCancelResponses.get(btg.id).messages);
	            }
	            if(!messagesforBTG.isEmpty()){
	            	string tempmsg='';
	            	for(string msg: messagesforBTG){ 
                        if(!tempmsg.contains(msg))// dont add duplicate messages
	            		tempmsg = tempmsg +', ' + msg;
	            	}
                    tempmsg = tempmsg.removeStart(', ');
	            	mapBTGMessages.put(btg.Id,tempmsg);
	            }
	            if(!invalidBTGIds.isEmpty()){
                    string tempmsg = Label.Void_date_cannot_before_Transaction_date;
                    if(invalidBTGIds.contains(btg.Id)){ 
                       mapBTGMessages.put(btg.Id,tempmsg);  
                    }
                }
            }
        }
        return mapBTGMessages;
	 }
}