public with sharing class AgreementReviseLinesCon {
    
    public Apexpages.Standardcontroller con {get;set;}
    public List<LineWrapper> lws {get;set;}
    public boolean renderGrid  {get;set;}
    public boolean disableButton {get;set;}
    public integer revNumber {get; set;}
    public boolean isSuccess {get;set;}
    public String errorMsg{get;set;}
    public List<Agreement_line__c> agreementLine{get;set;}
    
    public AgreementReviseLinesCon(){
        system.debug('no args specified');
        ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'No agreement is specified.'));
    }
    
    public AgreementReviseLinesCon(Apexpages.Standardcontroller controller){
        
        system.debug('this con: ' + controller);
        
        this.con = controller;
        Agreement__c a  = (Agreement__c) con.getRecord(); 

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Agreement__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','status__c'
        });
        Id aid = a.id;
        soql.setWhereClause('id = :aid');
        a = Database.query(soql.getQuery());
        
        if(a.Status__c != 'Approved'){
            renderGrid = false;
            disableButton = true;
           ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.WARNING, 'Can Only Revise Approved Agreement ')); 
        }else{
           renderGrid = true;
           disableButton = false; 
        }
        updateLines();
        
    }
    
    public void updateLines(){
        lws = new List<LineWrapper>();
        revNumber = 0;
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
        //string status = 'Pending Approval';//Revision_Status__c != :status
        SOQLUtil soql = new SOQLUtil('Agreement_Line__c', TRUE);
        soql.addFields(allFields);
        soql.setWhereClause('Agreement__c = \'' + con.getId() + '\'AND Revision_Status__c NOT IN :statusList AND Revised__c = false');
        soql.setOrderByClause('NAME');
        for(Agreement_Line__c al : Database.query(soql.getQuery())){
            lws.add(new LineWrapper(al));
        }
        
        for(LineWrapper lw : lws){
            if(lw.selected ){
                if(lw.al.Revision_Number__c == null || lw.al.Revision_Number__c == 0){
                    revNumber = 1;
                }else{
                    revNumber = lw.al.Revision_Number__c.intValue() + 1;
                }
            }
        }
        
        if(lws.size() == 0){
            renderGrid = false;
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.WARNING, 'There are no lines for this agreement.'));
        }
    }
    
    public void revise(){
        
        Savepoint sp = Database.setSavepoint();
        set<id> revId = new set<id>();
        set<id> alId = new set<id>();
        try{
            boolean hasLines = false;
            Agreement__c a = (Agreement__c)con.getRecord();

            list <Agreement_Line__c> alList = new list <Agreement_Line__c>();
            map<Id, Agreement_Line__c> m = new map<Id, Agreement_Line__c>();
            map<id,id> M1 = new map<id,id>();//map <Child.Id --> Parent.ID> M1
            map<id,id> M2 = new map<id,id>();//map <Old.Id -- > Rev.Id>; M2
            list<Agreement_Line__c> newAl = new list<Agreement_Line__c>();
            set<id> parentId = new set<id>();
            for(LineWrapper lw : lws){
                if(lw.selected){
                   parentId.add(lw.al.id); 
                }
                if(lw.al.Parent_Agreement_Line__c != null){
                   M1.put(lw.al.id,lw.al.Parent_Agreement_Line__c);
                   
                }
            }
            //system.debug('M1 '+M1);
            //system.debug('parentId'+parentId);
            for(LineWrapper lw : lws){
                if(lw.selected && (lw.revAl.Sales_Agreement_Quantity__c != null ||lw.revAl.Agreement_Price__c != null || lw.revAl.Start_Date__c != null || lw.revAl.End_Date__c != null) ){
                  Agreement_Line__c aline = new  Agreement_Line__c();
                  aline = lw.al.clone(false,true);
                  aline.Agreement__c = a.id;
                  aline.Revision_Number__c =  revNumber;  
                  aline.Revised_Agreement_Line__c = lw.al.id;
                  aline.Sales_Agreement_Quantity__c = lw.revAl.Sales_Agreement_Quantity__c;
                  aline.Remaining_Quantity__c = lw.revAl.Sales_Agreement_Quantity__c;
                  aline.Agreement_Price__c = lw.revAl.Agreement_Price__c;
                  aline.Start_Date__c = lw.revAl.Start_Date__c;
                  aline.End_Date__c = lw.revAl.End_Date__c;
                  aline.Updatable__c = true;     
                  aline.Revision_Status__c = 'Pending Approval' ; 
                  aline.Revision_Approval_date__c = null; //need to set it null because cloning set it to previous record Revision_Approval_date__c
                  aline.Revised__c = false;  //need to set to default because cloning set it to previous record Revised__c
                  aline.Parent_Agreement_Line__c = null;  //need to set it null because cloning set it to previous record Parent_Agreement_Line__c
                  aline.Line__c = null; //need to set to null so trigger can set the appropriate line number

                 if(!parentId.contains(lw.al.Parent_Agreement_Line__c)){
                      aline.Parent_Agreement_Line__c = lw.al.Parent_Agreement_Line__c;  
                 }
                  alList.add(aline);    
                }
              
            }
                 DML.insertAsUser(alList);
            for(Agreement_Line__c al : alList){
              alId.add(al.id);  
              revId.add(al.Revised_Agreement_Line__c);  
              M2.put(al.Revised_Agreement_Line__c,al.id); 
            }
  
            Map<id,Agreement_Line__c> revIdToOldLine = new Map<id,Agreement_Line__c>();
            list<Agreement_Line__c> oldList = new list<Agreement_Line__c>();
            
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            SOQLUtil soql = new SOQLUtil('Agreement_Line__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'ID','Revised_Agreement_Line__c'
            });
            soql.setWhereClause('Revision_Status__c = \'Pending Approval\' AND Revised_Agreement_Line__c IN :revId AND ID NOT IN :alId');
            List<Agreement_Line__c> agreList = Database.query(soql.getQuery());

            for(Agreement_Line__c agr:agreList){
                if(agr.Revised_Agreement_Line__c !=null){
                   revIdToOldLine.put(agr.Revised_Agreement_Line__c, agr);   
                }
            }
            if(!revIdToOldLine.values().isEmpty()){
                for(Agreement_Line__c agg:revIdToOldLine.values()){
                    agg.Revision_Status__c = 'Rejected';
                    oldList.add(agg);
                }
            }
           DML.updateAsUser(oldList);

            system.debug('M2 '+M2);
            for(Agreement_Line__c al : alList) {
                //system.debug('al '+al);
                //system.debug('M1.get(al.Revised_Agreement_Line__c) '+M1.get(al.Revised_Agreement_Line__c));
                //system.debug('M2.get(M1.get(al.Revised_Agreement_Line__c)) '+M2.get(M1.get(al.Revised_Agreement_Line__c)));
                if(al.Parent_Agreement_Line__c == null){
                    newAl.add(new Agreement_Line__c(Id = al.Id, Parent_Agreement_Line__c = M2.get(M1.get(al.Revised_Agreement_Line__c))));
                }
                
            }
              DML.updateAsUser(newAl);
              isSuccess = true;    
              errorMsg = 'Agreement Lines Revised'; 
                   
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
        public Agreement_Line__c revAl {get;set;}

        public LineWrapper(Agreement_Line__c al){
            
            this.al = al;
            this.revAl = new Agreement_Line__c();
            revAl.Start_Date__c = al.Start_Date__c;
            revAl.End_Date__c = al.End_Date__c;
            revAl.Sales_Agreement_Quantity__c = al.Sales_Agreement_Quantity__c;
            revAl.Agreement_Price__c = al.Agreement_Price__c;
            this.selected = true;
           
        }
        
    }
    
    
   
       
}