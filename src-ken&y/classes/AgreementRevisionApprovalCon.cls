public with sharing class AgreementRevisionApprovalCon {
    
    public Apexpages.Standardcontroller con {get;set;}
    public List<LineWrapper> lws {get;set;}
    public boolean renderGrid  {get;set;}
    public boolean disableButton {get;set;}
    
    public boolean isSuccess {get;set;}
    public String errorMsg{get;set;}
    
    
    public AgreementRevisionApprovalCon(){
        system.debug('no args specified');
        ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'No agreement is specified.'));
    }
    
    public AgreementRevisionApprovalCon(Apexpages.Standardcontroller controller){
        
        system.debug('this con: ' + controller);
        
        this.con = controller;
                                   
        if(this.con == null){
            system.debug('no id specified');
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'No agreement is specified.'));
        }else{
            renderGrid = true;
            disableButton = false;            
        }
        Agreement__c a  = (Agreement__c) con.getRecord();   
        updateLines();
        
    }
    
    public void updateLines(){
        lws = new List<LineWrapper>();
        string status = 'Pending Approval';
        
        //get all fields from object 
        SchemaUtil util = SchemaUtil.getInstance();
        set<String> allFields = new set<String>();
        Schema.DescribesobjectResult obj = util.getGlobalDescribe('Agreement_Line__c').getDescribe();
        for(Schema.sObjectField fieldapi: obj.fields.getMap().values()) {
            if(!fieldapi.getDescribe().isUnique()){
                allFields.add(string.valueof(fieldAPI) ); 
            }
        }

        SOQLUtil soql = new SOQLUtil('Agreement_Line__c', TRUE);
        soql.addFields(allFields);
        soql.setWhereClause('Agreement__c = \'' + con.getId() + '\' AND Revision_Status__c = :status');
        soql.setOrderByClause('NAME');
        for(Agreement_Line__c al : Database.query(soql.getQuery())){
            lws.add(new LineWrapper(al));
        }

        if(lws.size() == 0){
            renderGrid = false;
            disableButton = true;
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.WARNING, 'There are no Pending Revision for this agreement.'));
        }
    }

    
    public void approve(){
        list <Agreement_Line__c> aList = new list <Agreement_Line__c>();
        Savepoint sp = Database.setSavepoint();
        try{
            boolean hasLines = false;
           
           Set<id> revAgLinesId = new  set<id>();
           Set<id> prodId = new  set<id>(); 
           List<LineWrapper>  wpList = new List<LineWrapper>();
            for(LineWrapper lw : lws){
                if(lw.selected ){
                 prodId.add(lw.al.product__c);   
                 revAgLinesId.add(lw.al.Revised_Agreement_Line__c);
                 wpList.add(lw);   
                }  
            } 
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Agreement_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'ID','Revised_Agreement_Line__c'
			});
			soql.setWhereClause('ID IN :revAgLinesId');
			List<Agreement_Line__c> prevAgList = Database.query(soql.getQuery());
            
            for(Agreement_Line__c pA:prevAgList){
               pA.Updatable__c = true; 
            }
            DML.updateAsUser(prevAgList);
            for(LineWrapper lw : lws){
                if(lw.selected ){
                    if((prodId.size() != wpList.size())&& (revAgLinesId.size() != wpList.size())){
                       isSuccess = false; 
                       ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.WARNING, 'Cannot Approve Same Agreement Lines Revision')); 
                    }else{
                      isSuccess = true;   
                   lw.al.Revision_Status__c = 'Approved';
                   aList.add(lw.al);  
                } 
            }
            }
              
             DML.updateAsUser(aList);
              errorMsg = 'Revision Approved'; 
                    
                }
            catch(Exception ex){
                Database.rollback(sp);
                ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
                System.debug(LoggingLevel.ERROR, ex.getStackTraceString() + ' ' + ex.getMessage());
        }
       finally {
         set<Id> arlId = KSE.grepRelatedIdSetFromList(aList,'Id',true); 
		AgreementLineService.setUpdatableAsync(arlId) ;
        }

    }
    public void reject(){
        
        Savepoint sp = Database.setSavepoint();
        try{
            boolean hasLines = false;
           list <Agreement_Line__c> aList = new list <Agreement_Line__c>();
            for(LineWrapper lw : lws){
                if(lw.selected && (lw.al.Revision_Status__c == 'Pending Approval')){
                   
                   aList.add(lw.al);  
                } 
            }
              
             DML.deleteAsUser(aList);
              isSuccess = true;    
              errorMsg = 'Revision Rejected'; 
                    
                }
            catch(Exception ex){
                Database.rollback(sp);
                ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
                System.debug(LoggingLevel.ERROR, ex.getStackTraceString() + ' ' + ex.getMessage());
        }
    }
    
    public class LineWrapper{
        
        public Agreement_Line__c al {get;set;}
        public boolean selected {get;set;}
       
        public LineWrapper(Agreement_Line__c al){
            this.al = al;
            this.selected = true;
           
        }
        
    }
    
    
   
       
}