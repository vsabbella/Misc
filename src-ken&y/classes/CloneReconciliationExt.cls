public class CloneReconciliationExt{/*
        
    public Apexpages.Standardcontroller con {get;set;}
    public string namespace {get;set;}        
    public Reconciliation__c thisRecon {get;set;}
    public list<Reconciliation_Topic__c> reconTopicList {get;set;}
    public boolean disableCloneRecon {get;set;}
    public id conID {get;set;}    
    //public company__c thisReconCompany {get;set;}
    //public Period__c periodToAssign {get;set;}
    //public String helpURl {get;set;}
    
    public cloneReconciliationExt(Apexpages.Standardcontroller controller){
        disableCloneRecon = false; 
        thisRecon = new Reconciliation__c();
        reconTopicList = new list<Reconciliation_Topic__c>();        
        this.con = controller;
        this.namespace = KSE.NamespaceUU; 
        conID = con.getID();
        //periodToAssign =  getPeriodInScope(System.now());
         SOQLUtil soql = new SOQLUtil('Reconciliation__c', true);
         soql.addFields(new set<string>{'ID', 'Company__c', 'Company__r.name', 'Batch_Job_ID__c', 'Beginning_Balance__c', 'Ending_Balance__c', 'GL_Account__c', 'Name', 'Period__c'}); 
         SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Reconciliation_Topics__r');
         childRel.addFields(new Set<String>{ 'ID', 'Accounting_Rule__c' , 'Action__c' , 'Amount_Reference__c', 'Filter__c', 'GL_Amount__c', 'Reconciliation_Section__c', 'Source_Amount__c', 'Type__c'});
            childRel.setWhereClause('Reconciliation__c = : conID');
            childRel.setLimit(501);
            soql.addChildRelationship(childRel);        
         soql.setWhereClause('ID = : conID');
         
         thisRecon = ((List<Reconciliation__c>)Database.query(soql.getQuery()))[0];
         reconTopicList = thisRecon.Reconciliation_Topics__r;
       // thisRecon = [SELECT ID, Company__c, Company__r.name, Batch_Job_ID__c, Beginning_Balance__c, Ending_Balance__c, GL_Account__c, Name, Period__c FROM Reconciliation__c WHERE ID = : con.getID()];
        
        //reconTopicList = [SELECT ID, Accounting_Rule__c, Action__c, Amount_Reference__c, Filter__c, GL_Amount__c, Reconciliation_Section__c, Source_Amount__c, Type__c FROM Reconciliation_Topic__c WHERE Reconciliation__c = : thisRecon.id LIMIT 501];
        //thisReconCompany = thisRecon.Company__c; 

    }


     //public period__c getPeriodInScope(DateTime pointInTime){
     //      period__c returnPeriod = new period__c();
     //      list<period__c> findPeriod = new list<period__c>();
           
     //      findPeriod = [SELECT ID, Period_Start__c, Period_End__c FROM Period__c WHERE (Period_Start__c <= : pointInTime AND Period_End__c >= : pointInTime) AND Open__c = TRUE AND Company__c = : thisReconCompany LIMIT 1];
           
     //      if(findPeriod.size() > 0){
     //          returnPeriod = findPeriod[0];
     //      }
     //      return returnPeriod;
     //  } 
        
        
    public PageReference cloneSingleReconHeaderandTopics(){
        ID reconToRedirect;
        String monthString = string.ValueOF(system.now().format('MMMMM'));
        list<Reconciliation__c> reconDMLInsertList = new list<Reconciliation__c>();
        list<sObject> sObjectInsertList = new list<sObject>();
        list<Reconciliation_Topic__c> reconTopicDMLInsertList = new list<Reconciliation_Topic__c>();
        //Limiting users to only limit recon's with recon topics list less than or eqaul to 500
            if(reconTopicList.size() > 500){
                ApexPages.Message NORT = new ApexPages.Message(ApexPages.Severity.FATAL, 'Unable to clone Reconcilation with Topics exceeding 500 records') ;
                disableCloneRecon = true;         
                }else if(thisRecon.Company__c == NULL){
                ApexPages.Message NORT = new ApexPages.Message(ApexPages.Severity.FATAL, 'A Company must be defined before cloning this Reconciliation') ;
                disableCloneRecon = true; 
        
                }else if(thisRecon.GL_Account__c == NULL){
                ApexPages.Message NORT = new ApexPages.Message(ApexPages.Severity.FATAL, 'A GL Account must be defined before cloning this Reconciliation') ;
                disableCloneRecon = true; 
        
                }//else if(periodToAssign == NULL){
                // ApexPages.Message NORT = new ApexPages.Message(ApexPages.Severity.FATAL, 'An open period is required to clone a Reconciliation') ;
                //disableCloneRecon = true;         
                //}
        //Clears validation, Able to insert records
            else{
            Reconciliation__c newRecon = new reconciliation__c();
            newRecon.Company__c = thisRecon.company__c;
            newRecon.Batch_Job_ID__c = thisRecon.Batch_Job_ID__c;
            newRecon.GL_Account__c = thisRecon.GL_Account__c;
            newRecon.Name = thisRecon.name + ' - Clone'; 
            newRecon.Period__c = thisRecon.Period__c; 
            insert newRecon;
        
            for(Reconciliation_Topic__c reconTopic : reconTopicList){
                Reconciliation_Topic__c newReconTopic = new Reconciliation_Topic__c();
                newReconTopic.Accounting_Rule__c = reconTopic.Accounting_Rule__c;
                newReconTopic.Action__c = reconTopic.Action__c;
                newReconTopic.Amount_Reference__c = reconTopic.Amount_Reference__c;
                newReconTopic.Filter__c = reconTopic.Filter__c;
                newReconTopic.GL_Amount__c = reconTopic.GL_Amount__c;
                newReconTopic.Reconciliation__c = newRecon.ID;
                newReconTopic.Type__c = reconTopic.Type__c;
                reconTopicDMLInsertList.add(newReconTopic);

        
            } 
            DML.insertAsUser(reconTopicDMLInsertList);
            reconToRedirect = newRecon.id;


          }
            PageReference p = new PageReference('/' + reconToRedirect );
            return p.setRedirect(false); 

        
    }
    
    


*/}