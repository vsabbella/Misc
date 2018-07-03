public with sharing class BankTransactionVoidCancelExt extends VoidCancelBaseExt{
    public VoidCancelService voidCancelSvc {get;private set;}
    public Apexpages.Standardcontroller con {get;set;}
    ApexPages.StandardSetController setcon;
    
    public Bank_Transaction_Group__c btg{get;set;}{
        btg = new Bank_Transaction_Group__c();
        btg.Void_Date__c = system.now();    
    }
    public Bank_Transaction__c bt{get;set;}
    public static list<Bank_Transaction__c> lstBT{get;set;}
    public list<Bank_Transaction_Group__c>lstBTG{get;set;}
    
    public String lstBTJson{get{
        return JSON.serialize(lstBT);}}
    public string namespace {get;set;}
    
    public BankTransactionVoidCancelExt(Apexpages.Standardcontroller controller)
    {
        this.con = controller;
        this.namespace = KSE.NamespaceUU;
        list<Id> btIds = new list<Id>(); // contains only one record
        btIds.add(con.getId());
        
        lstBT = new list<Bank_Transaction__c>();
        system.debug(logginglevel.error,'controller:' + controller + 'con.getId() :' + con.getId());
        
        SOQLUtil soql = new SOQLUtil('Bank_Transaction__c', TRUE);
        soql.addFields(new Set<String>{'Id','Name','Finalized_2__c','Transaction_Date__c', 'Bank_Transaction_Group__c',
              'Bank_Transaction_Group__r.Finalized_Date__c','Bank_Transaction_Group__r.Posting_Date__c',
              'Bank_Transaction_Group__r.Void__c' , 'Bank_Transaction_Group__r.Status__c', 'Bank_Transaction_Group__r.Void_Date__c',
              'Historical__c' ,'company__c','Match_Approved__c' ,'Reconciled_Hidden__c' ,'Amount__c'
              ,'Payment_Method__c','Reference_Number__c'});
        soql.setWhereClause('id in :btIds');
        lstBT = database.query(soql.getQuery());
        System.debug(logginglevel.error,'lstBT--->'+lstBT);
              
        lstBTG = new list<Bank_Transaction_Group__c>();
        list<Id> btgIds = new list<Id>();
        btgIds.add(lstBT[0].Bank_Transaction_Group__c);
        
        soql = new SOQLUtil('Bank_Transaction_Group__c', TRUE);
        soql.addFields(new Set<String>{'Id', 'Company__c', 'Exceptions_Count__c', 'Finalized__c',
              'Finalized_Date__c', 'Transaction_Date__c', 'Posting_Date__c', 'Void__c', 'Void_Date__c', 'Status__c', 'Historical__c', 'Name'});
        soql.setWhereClause('id in :btgIds');
        lstBTG = database.query(soql.getQuery());                                 
        btg  = lstBTG[0];
        System.debug(logginglevel.error,'btg--->'+btg);  
        
          voidCancelSvc = new BankTransactionVoidCancelService(new List<sObject>{btg}); //Calling from UI
    }
    // standard set controller constructor for list view page	
    public BankTransactionVoidCancelExt(Apexpages.standardsetcontroller controller) {
        this.setcon = controller;
         list<Bank_Transaction__c> btCon = setcon.getSelected();
        lstBT = new list<Bank_Transaction__c>();
        
            SOQLUtil soql = new SOQLUtil('Bank_Transaction__c', TRUE);
            soql.addFields('Match_Bank_Transactions_Columns');
            soql.addFields(new Set<String>{'Id','Name','Finalized_2__c','Transaction_Date__c', 'Bank_Transaction_Group__c',
                  'Bank_Transaction_Group__r.Finalized_Date__c','Bank_Transaction_Group__r.Posting_Date__c',
                  'Historical__c' ,'company__c','Match_Approved__c' ,'Reconciled_Hidden__c' ,'Amount__c'
                  ,'Payment_Method__c','Reference_Number__c'});
            soql.setWhereClause('id in :btCon');
        lstBT = database.query(soql.getQuery());
    } 
    public void pageMessages( string msg , String severityLevel) {
        system.debug('msg: ' + msg + ' - sev: ' + severityLevel);
        msg = MessageUtil.toFriendlyErrorMessage(msg);
        if(severityLevel.equalsIgnoreCase('FATAL')){
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.FATAL,msg));
        }else if(severityLevel.equalsIgnoreCase('ERROR')){
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR,msg));
        }else if(severityLevel.equalsIgnoreCase('WARNING') ){
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.WARNING,msg));
        }else if(severityLevel.equalsIgnoreCase('INFO') ){
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.INFO,msg));
        }
    }
    
    
  
    public boolean getDisableVoid(){
        if(voidCancelSvc.getVoidCancelDetails()==null || lstBT == null) return false;
		return !voidCancelSvc.getVoidCancelDetails().get(lstBT[0].bank_Transaction_Group__c).isVoidable;
	}
    
	public boolean getDisableCancel(){
        if(voidCancelSvc.getVoidCancelDetails()==null || lstBT == null) return false;
        
		return !voidCancelSvc.getVoidCancelDetails().get(lstBT[0].bank_Transaction_Group__c).isCancellable;
	}
	
	public VoidCancelService.VoidCancelDetail getVoidCancelDetails(){
		return voidCancelSvc.getVoidCancelDetails().get(lstBT[0].bank_Transaction_Group__c);
	}
    
    public List<string> getVoidDetails(){
        List<String> voidMessages = new List<String>();
        map<String,string> mapBTGNameAndBTName = new map<String,string>();
        if (lstBT==null) return null;
          List<Bank_Transaction__c>   lstQueriedBT = [Select Id, Name, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Name,Amount__c 
                            from Bank_Transaction__c where Id = :lstBT[0].id];
            for(Bank_Transaction__c bt: lstQueriedBT){
                mapBTGNameAndBTName.put(bt.Bank_Transaction_Group__r.Name,bt.Name);
            }
         mapBTGNameAndBTName.put('Bank Transaction Group','Bank Transaction');
        for(String strVmsg: (voidCancelSvc.getVoidCancelDetails().get(lstBT[0].bank_Transaction_Group__c)).voidMessages){
             if(String.isnotBlank(strVmsg)){
                    for(String btgname :mapBTGNameAndBTName.keySet()){
                        if(strVmsg.contains(btgname)) voidMessages.add(strVmsg.replace(btgname,mapBTGNameAndBTName.get(btgname)));
                    }
             }
        }
		return voidMessages;
	}
    
    public List<string> getCancelDetails(){
        List<String> cancelMessages = new List<String>();
        map<String,string> mapBTGNameAndBTName = new map<String,string>();
         if (lstBT==null) return null;
          List<Bank_Transaction__c>   lstQueriedBT = [Select Id, Name, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Name,Amount__c 
                            from Bank_Transaction__c where Id = :lstBT[0].id];
            for(Bank_Transaction__c bt: lstQueriedBT){
                mapBTGNameAndBTName.put(bt.Bank_Transaction_Group__r.Name,bt.Name);
            }
         mapBTGNameAndBTName.put('Bank Transaction Group','Bank Transaction');
        for(String strVmsg: (voidCancelSvc.getVoidCancelDetails().get(lstBT[0].bank_Transaction_Group__c)).cancelMessages){
            if(String.isnotBlank(strVmsg)){
                for(String btgname :mapBTGNameAndBTName.keySet()){
                if(strVmsg.contains(btgname) )  cancelMessages.add(strVmsg.replace(btgname,mapBTGNameAndBTName.get(btgname)));
                }
            }
        }
		return cancelMessages;
	}
    @RemoteAction
    public static JsonResult voidCancelBankTransactionGroup(Id listBT, string action, string voidDate){
        JSONResult result = new JSONResult();  
        if(!String.isBlank(listBT) && !String.isBlank(action) && !String.isBlank(voidDate) ){
            map<Id,string> mapBTGMessages = new map<Id,string>();
            map<Id,Id> mapBTGIdAndBTId = new map<Id,Id>();
            map<string,string> mapBTGNameAndBTName = new map<string,string>();
            map<Id,string> mapBTGIdAndBTGName = new map<Id,string>();
            list<Bank_Transaction__c> lstQueriedBT = new list<Bank_Transaction__c>();
            lstQueriedBT = [Select Id, Name, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Name,Amount__c 
                            from Bank_Transaction__c where Id = :listBT];
            for(Bank_Transaction__c bt: lstQueriedBT){
                mapBTGIdAndBTId.put(bt.Bank_Transaction_Group__c,bt.Id);
                mapBTGNameAndBTName.put(bt.Bank_Transaction_Group__r.Name,bt.Name);
                mapBTGIdAndBTGName.put(bt.Bank_Transaction_Group__c,bt.Bank_Transaction_Group__r.Name);
            }
            if(!mapBTGIdAndBTId.isEmpty() && !mapBTGNameAndBTName.isEmpty()){
                //add void fields in the query.
                /*list<Bank_Transaction_Group__c>  lstBTG = [Select Id, Company__c, Exceptions_Count__c, Finalized__c, Finalized_Date__c,Transaction_date__c,Posting_date__c, name, Void__c, Void_Date__c, Historical__c, Status__c,                
                                                           (Select Id from Bank_Transactions__r),
                                                           (select id, name from Accounting_Entries__r  where status__c = 'Active' and Has_Exceptions__c != true) 
                                                           From Bank_Transaction_Group__c where id  in: mapBTGIdAndBTId.keyset()];*/
               Set<id> btgids =  mapBTGIdAndBTId.keyset();
                 SOQLUtil soql = new SOQLUtil('Bank_Transaction_Group__c', TRUE);
                string status='Active';
            soql.addFields('Match_Bank_Transactions_Columns');
            soql.addFields(new Set<String>{'Id', 'Company__c', 'Exceptions_Count__c', 'Finalized__c', 'Finalized_Date__c','Transaction_date__c','Posting_date__c', 
                							'name', 'Void__c', 'Void_Date__c', 'Historical__c', 'Status__c'});
            soql.setWhereClause('id in :btgids');     
        list<Bank_Transaction_Group__c>  lstBTG = database.query(soql.getQuery());
               Datetime dateTimeInFormat = null;
               dateTimeInFormat = (datetime)JSON.deserialize(voidDate, Datetime.class);
               //dateTimeInFormat = DateTime.valueOf(voidDate);
            mapBTGMessages = new BankTransactionVoidCancelService(lstBTG).voidCancelBankTransactionGroup(lstBTG,action,voidDate);
                if(!mapBTGMessages.isEmpty()){
                    for(Id btgId: mapBTGMessages.keyset()){
                        if(mapBTGIdAndBTId.containsKey(btgId)){
                            string msg = mapBTGMessages.get(btgId);
                            
                            if(!string.isblank(msg)){
                                if(msg.contains(btgId)){
                                    msg = mapBTGMessages.get(btgId).replaceAll(btgId,mapBTGIdAndBTId.get(btgId));
                                }
                                if( msg.contains('Bank Transaction Group')){
                                    msg = msg.replaceAll('Bank Transaction Group','Bank Transaction');
                                }
                                
                                if( msg.contains(mapBTGIdAndBTGName.get(btgId))){
                                    msg = msg.replaceAll(mapBTGIdAndBTGName.get(btgId),mapBTGNameAndBTName.get(mapBTGIdAndBTGName.get(btgId)));
                                }else {
                                    msg =mapBTGNameAndBTName.get(mapBTGIdAndBTGName.get(btgId))+ ': ' + msg;
                                }
                                if(msg.contains('Successfully')){
                                    result.addmessage(msg,ApexPages.severity.Confirm);
                                    result.success=true;
                                }else{
                                    result.addmessage(msg,ApexPages.severity.Error);
                                    result.success = false; 
                                }                                
                            }
                        }
                    }
                }
            }
        }
        return result;
    }
}