public with sharing class AgreementCloneCon {
    
    public Apexpages.Standardcontroller con {get;set;}
    public List<LineWrapper> lws {get;set;}
    public boolean renderGrid  {get;set;}
    public boolean disableButton {get;set;}
    public boolean isSuccess {get;set;}
    public String errorMsg{get;set;}
    public List<Agreement_line__c> agreementLine{get;set;}
    public Agreement__c agrm {get;set;}
    public Agreement__c agreement {get;set;}
    
    public AgreementCloneCon(){
        //system.debug('no args specified');
        ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'No agreement is specified.'));
    }
    
    public AgreementCloneCon(Apexpages.Standardcontroller controller){
        this.con = controller;
        agrm  = (Agreement__c) con.getRecord(); 
        agreement = (Agreement__c) con.getRecord(); 
        
        Agreement__c ag = [SELECT Id, Status__c, Start_Date__c, End_Date__c FROM Agreement__c WHERE id = :agrm.id ];
            if(ag.Start_Date__c < System.now())
        	    agrm.Start_Date__c = System.now();
        
            if(ag.End_Date__c < System.now())
                agrm.End_Date__c = null;
            else{
                agrm.End_Date__c = ag.End_Date__c;
            }
     
        updateLines();
        renderGrid = true;
    }
    
    public void updateLines(){
        lws = new List<LineWrapper>();
       
        List<String> statusList = new List<String>();
        statusList.add('Pending Approval');
        statusList.add('Rejected');
        
        //get all fields from object for cloning 
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
        soql.setWhereClause('Agreement__c = \'' + con.getId() + '\'');
        soql.setOrderByClause('NAME');
        for(Agreement_Line__c al : Database.query(soql.getQuery())){
        	if(al.start_Date__c < system.now()){ 
        		al.start_Date__c = system.now();
        	}
        	if(al.End_Date__c < system.now()){
        		al.End_Date__c = null;
        	}
            lws.add(new LineWrapper(al));
        }
        //get agreement fields
        set<String> aFields = new set<String>();
        Schema.DescribesobjectResult o = util.getGlobalDescribe('Agreement__c').getDescribe();
        for(Schema.sObjectField fieldapi: o.fields.getMap().values()) {
            if(!fieldapi.getDescribe().isUnique()){
                aFields.add(string.valueof(fieldAPI) ); 
            }
        }
        
        soql = new SOQLUtil('Agreement__c', TRUE);
        soql.addFields(aFields);
        string  agreementId = con.getId();
        soql.setWhereClause('ID = :agreementId');
        agreement = Database.query(soql.getQuery());
        
        if(lws.size() == 0){
            renderGrid = false;
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.WARNING, 'There are no lines for this agreement.'));
        }
    }
    
    public void agmtClone(){
        
        Savepoint sp = Database.setSavepoint();
        list <Agreement__c> agmtList = new list <Agreement__c>();
        try{
            boolean hasLines = false;
            Agreement__c a = (Agreement__c)con.getRecord();
            Agreement__c agmt = new  Agreement__c();
            agmt = agreement.clone(false,true);
            agmt.name = agreement.name;
            agmt.Status__c = 'Draft';
            agmt.Agreement_Code__c  = null ;
            agmt.Customer__c = agreement.Customer__c;
            agmt.Bill_To__c = agreement.Bill_To__c;
            agmt.Sold_To__c = agreement.Sold_To__c;
            agmt.Ship_To__c = agreement.Ship_To__c;
            agmt.Start_date__c = agrm.Start_Date__c;
            agmt.End_date__c = agrm.End_Date__c;
            agmt.Activation_Date__c =  null;
            agmt.Recurrence_Start_Date__c =  null;
            agmt.Company__c = agreement.Company__c;
            agmt.Approval_Date__c   = null;
            
            agmtList.add(agmt);
            DML.insertAsUser(agmt);
            list <Agreement_Line__c> alList = new list <Agreement_Line__c>();
            Map<id, Agreement_Line__c> oldToNewAgreementLineMap = new Map<id,Agreement_Line__c>();
            

            for(LineWrapper lw : lws){
                if(lw.selected  ){
                  Agreement_Line__c aline = new  Agreement_Line__c();
                  aline = lw.al.clone(false,true);
                  aline.Agreement__c = agmt.id;
                  aline.Product__c = lw.al.Product__c;  
                  aline.Sales_Agreement_Quantity__c = lw.al.Sales_Agreement_Quantity__c;
                  aline.Agreement_Price__c = lw.al.Agreement_Price__c;
                  aline.Start_Date__c = lw.al.Start_Date__c;
                  aline.End_Date__c = lw.al.End_Date__c;
                  aline.Approval_Required__c  = false;   
                  aline.Updatable__c = true; 
                  aline.Remaining_Quantity__c = lw.al.Sales_Agreement_Quantity__c;
                  aline.Revised_Agreement_Line__c = null;  
                  aline.Revision_Status__c = null ; 
                  aline.Revision_Approval_date__c = null; //need to set it null because cloning set it to previous record Revision_Approval_date__c
                  aline.Revised__c = false;  //need to set to default because cloning set it to previous record Revised__c
                  aline.Parent_Agreement_Line__c = null;  //need to set it null because cloning set it to previous record Parent_Agreement_Line__c
                  aline.Line__c = null; //need to set it to null so trigger can set the appropriate line number
                  alList.add(aline);    
                  oldToNewAgreementLineMap.put(lw.al.id, aline);
                }
              
            }
			DML.insertAsUser(alList);

            alList.clear();
            for(LineWrapper lw : lws){
                if(lw.selected){
                    if (lw.al.Parent_Agreement_Line__c != NULL){
                        Agreement_Line__c tmp = oldToNewAgreementLineMap.get(lw.al.id);
                        tmp.Parent_Agreement_Line__c = oldToNewAgreementLineMap.get(lw.al.Parent_Agreement_Line__c).id;
                        alList.add(tmp);
                    }
                }
            }
			
			if (alList.size() > 0){
            	DML.updateAsUser(alList);
			}

              isSuccess = true;
              errorMsg = '<a href="/'+ agmt.Id+'">' + agmt.Name + '</a>' + ' was cloned successfully'; 
                   
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