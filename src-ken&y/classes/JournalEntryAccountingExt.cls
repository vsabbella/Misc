public with sharing class JournalEntryAccountingExt {

    public ApexPages.StandardSetController setcon{get; set;}
    public Boolean selecterror {get; set;} { selecterror = false; } 
    public Boolean requiredFielderror {get; set;} { requiredFielderror = false; }
    public list<Journal_Entry__c> objectList {get;set;}
    set<ID> JEIDs = new set<ID>();
    //JournalEntryAccounting jea = new JournalEntryAccounting();
    
    List<Accounting_Entry__c> acctEntryList = new List<Accounting_Entry__c>();
    AccountingRuleService ARS = new AccountingRuleService();
    
    public JournalEntryAccountingExt(ApexPages.StandardSetController controller) {     
        
        setcon = controller;
        if ( ! Schema.sObjectType.Journal_Entry__c.isCreateable() ) {
		      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
	                                               	Label.Insufficient_access_to_create_Customer_Receipt));
			requiredFielderror = true;
			return;
	    }
        
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_records_selected) );
            selecterror = true;
            return;
        }
        
        for (Journal_Entry__c je: (List<Journal_Entry__c>)setCon.getSelected() ) {      
            JEIDs.add(je.ID);
        }
        
        /* 
        String objectQuery = 'select ID, Name, Finalized__c, Company__c, GL_Date_Time__c ,Currency__c,  Transaction_date__c, Finalized_Date__c, '+
        		' Period__c, Period__r.Period_Start__c, Period__r.Period_End__c' +
              	' from Journal_Entry__c where Id in :JEIDs and Finalized__c = true and Type__c != null ' +
              	' and id not in (Select Journal_Entry__c from Accounting_Entry__c where Journal_Entry__c in :JEIDs and void__c = false AND (period__r.closed__c = true OR period__r.permanently_closed__c = true) AND status__c=\'Draft\') ' ;*/
       
		String whereClause = 'Id in :JEIDs and Finalized__c = true and Type__c != null ' +
              	 			 ' and id not in (Select Journal_Entry__c from Accounting_Entry__c where Journal_Entry__c in :JEIDs and void__c = false AND (period__r.closed__c = true OR period__r.permanently_closed__c = true) AND status__c=\'Draft\') ';
        
	    SOQLUtil soql = new SOQLUtil('Journal_Entry__c');
	    soql.addFields(new Set<String>{ 'ID', 'Name', 'Finalized__c', 'Company__c', 'GL_Date_Time__c', 'Currency__c', 'Transaction_date__c', 'Finalized_Date__c', 
	    								'Period__c', 'Period__r.Period_Start__c', 'Period__r.Period_End__c','Period__r.JE_Cutoff__c'});
	    soql.setWhereClause(whereClause);
	         
        objectList = Database.query(soql.getQuery());
        
        if (selecterror ) {
            return ;
        }
  
        if(objectList == null || objectList.size() < 1){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_eligible_records_to_process ) );
          	requiredFielderror = true;
          	selecterror = true;
        	return;
        }
        // Check if the Document Date is in the specified period if not check if the Date Finalized is before the cut off date else throw error msg
 	
        for(integer i = 0; i < objectList.size(); i++){
        	
         	if(objectList[i].Transaction_Date__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Transaction_Date_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        	if(objectList[i].Finalized_Date__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Finalized_Date_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        	if(objectList[i].Currency__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Transaction_Currency_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        	if(objectList[i].Company__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Company_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        }
        
    } // End of Constructor
    
    
    //Function to generate the accounting entries for the invoice lines
    public pagereference GenerateJournalEntryAccounting() {
        
        If(objectList != null && objectList.size() > 0){
            Savepoint sp = Database.setSavepoint();
            try{
                //system.debug(logginglevel.info,'sp:'+sp);
                //jea.execute(objectList);
                set<Id> sourceDocIds = new set<Id>();
                set<Id> companyIds = new set<Id>();
                for(Journal_Entry__c je : objectList){
                	companyIds.add(je.company__c);
                	sourceDocIds.add(je.Id);
                }
                
                JournalEntryAccountingBatch batch = new JournalEntryAccountingBatch(companyIds);
                batch.setSourceDocId(sourceDocIds);
                batch.setuseSuperWhere(true);
                Database.ExecuteBatch(batch);
                
            }catch(Exception e){
                Database.rollback(sp);
                String errorMessage = e.getMessage();
                //system.debug(logginglevel.info,'errorMessage :'+errorMessage);
                ApexPages.addMessages(e);
                return null;
            }
        }

        //KNDY-2020 Checking for Pg msgs before moving the page forward. Hiding the button if any error or fatal msgs
        if (Apexpages.hasMessages(ApexPages.Severity.FATAL) || Apexpages.hasMessages(ApexPages.Severity.ERROR)){
        	requiredFielderror = true;
        	selecterror = true;
        	
        }
        return (Apexpages.hasMessages() ? null : this.setcon.cancel() ); 
        //return setcon.cancel();
    } 
    
    
}