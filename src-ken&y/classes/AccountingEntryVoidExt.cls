public with sharing class AccountingEntryVoidExt {
    
    private ApexPages.StandardController controller;
    
    public Accounting_Entry__c oldAE {get; set;}
    //public Boolean boolVoid{get;set;}
    public Boolean boolDelete{get;set;}

    public AccountingEntryVoidExt(){}
    AccountingEntryService AES = AccountingEntryService.getInstance();
    	
    
    public AccountingEntryVoidExt(ApexPages.StandardController c) {
        controller = c;
        //boolVoid = True;
        boolDelete = False;
        oldAE = (Accounting_Entry__c) controller.getRecord();
        if(oldAE != null && oldAE.Id != null){
        	Id oldAEId = oldAE.ID;

            SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', FALSE);
            soql.addAllFields();
            soql.addFields(new Set<String>{ 'Period__r.Open__c', 'Period__r.Period_Start__c', 'Period__r.Period_End__c'});
        	soql.setWhereClause('Id = :oldAEId');
        						
            oldAE = Database.Query(soql.getQuery());
        }
    }
    
    // Used to go back to the Right Accounting Entry
    public pagereference doCancel(){
        PageReference AEPage = new PageReference('/'+oldAE.ID);
                    AEPage.setRedirect(true);
                    return AEPage;
    }
  /** -----------------------KNDY-8827 Remove void capability on an Accounting Entry (AE)-----------------//
    // Validate the Void Fuctionality Conditions before Voiding
    public void voidAccountingEntryCheck() { // Changed from pagereference to void as anyway it was returning null;
    	
    	String allowVoidforSourceDocs = ApexPages.currentPage().getParameters().get('allowVoid') ;
    	
    	// KNDY - 1645  - Commented below line to work the functionality for AEs with or without source documents
        //if((OldAE.Posted__c != True) || (OldAE.Period__r.Open__c != true) || (OldAE.Transaction_Type__c != 'Manual') || (OldAE.Related_Accounting_Entry__c != Null) ){
        
        if((OldAE.Period__r.Open__c != true) || 
        	(OldAE.Related_Accounting_Entry__c != Null) ||
        	!AES.isInPeriod(new list<period__c>{new Period__c ( Id = OldAE.Period__c) }))
        {
    		
    		// KNDY - 1645  - Commented below lines to work the functionality for AEs with or without source documents
            /*if(OldAE.Transaction_Type__c != 'Manual' && allowVoidforSourceDocs != '1'){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'You can Only Void Manual Accounting Entry'));
                boolVoid = False;
                boolDelete = False;
                }  
                */ /*
				if(OldAE.Period__r.Open__c != true){
				    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Cannot_void_AccountingEntries_with_closed_period));
				    boolVoid = false;
				    boolDelete = false;
				    return ;
				}
				if(OldAE.Related_Accounting_Entry__c != Null){
				    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Cannot_void_AccountingEntries_with_related_entries));
				    boolVoid = false;
				    boolDelete = false;
				    return ;
				}  
				//FIN-1125 Security Scanner -Bulkify Apex methods.				
				if(!AES.isInPeriod(new list<period__c>{new Period__c ( Id = OldAE.Period__c)})){
				 	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Cannot_void_AccountingEntries_once_period_ended));
				    boolVoid = false;
				    boolDelete = false;
				    return ;	
				}              
          }
          return ;
      }
    
     // Void Manual Accounting Entry
	public Pagereference voidAccountingEntry() {
		boolean isSuccess = false;
		
		voidAccountingEntryCheck(); // perform check before voiding AE
		// If any exception occurs the transaction should be rolled back ( to avoid creating an AE header without lines)
		Savepoint sp = Database.setSavepoint();
		try{
			if(boolVoid == true){ // void AE only if the boolVoid is true
		 		isSuccess = AES.AccountingEntryVoid(new List<Accounting_Entry__c> {oldAE});
			}

			 }
		catch(Exception ex){
		 isSuccess = false;
		 Database.rollback(sp);
		 ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
		}
		 
		pageReference newPage;
		if(isSuccess){
		 newPage = controller.view();
		}
		return newPage;
    }
*/

    public Pagereference deleteAECheck(){
        boolDelete = True;
        if((OldAE.Related_Accounting_Entry__c != Null)){
            if(OldAE.Related_Accounting_Entry__c != Null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Cannot_delete_AccountingEntries_related_to_voided_entries));
                boolDelete = False;
            }                 
        }
        return Null;
    }
    
	
	//public  boolean isdeleteException; 
	
    public Pagereference deleteAccountingEntry() {
        //isdeleteException = false;
        try{      
            Schema.DescribeSObjectResult R = Accounting_Entry__c.SObjectType.getDescribe();
            ID id = ApexPages.currentPage().getParameters().get('Id');

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Name','void__c','total_lines__c'
			});
			soql.setWhereClause('id =:id');
			Accounting_Entry__c OldAEDel = Database.query(soql.getQuery());

            if(oldAEDel.void__c){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Cannot_delete_voided_Accounting_Entries));
                return null;
            }
            
            if(OldAEDel.Total_Lines__c < 500){
            	DML.deleteAsSystem(OldAEDel);
            }else{
            	OldAEDel.Status__c = 'Obsolete';
            	DML.updateAsSystem(OldAEDel);
            	AccountingEntryLineDeleteBatch delBatch = new AccountingEntryLineDeleteBatch(new set<Id>{OldAEDel.Id});
            	Database.ExecuteBatch(delBatch, 2000);
            }
            PageReference AEPage = new PageReference('/'+R.getKeyPrefix() + '/o');
            AEPage.setRedirect(true);
            return AEPage;
        }catch(Exception e) { // could be caused by validations
        	//isdeleteException = true;
            Apexpages.addMessages(e);
            return null;
        }  
    }

}