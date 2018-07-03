public with sharing class PurchaseAgreementCloneExt {
	
	ID oldISID;
    private ApexPages.StandardController controller;
    public Boolean isVisible { get; set;}
    private static SchemaUtil util = SchemaUtil.getInstance();
	
    public PurchaseAgreementCloneExt (ApexPages.StandardController c) {
        controller = c;
        oldISID = controller.getRecord().id;
        isVisible = true;
    }
    
     public Pagereference Save(){
     	Contract__c oldPA = new Contract__c();
        Contract__c newPA = new Contract__c();
        List<Contract_Line__c> PALList = new List<Contract_Line__c> ();
        
        oldPA = (Contract__c)controller.getRecord();    
        if (oldPA.id == null){
        	ApexPages.addMessage( new Apexpages.Message(ApexPages.severity.FATAL,
                    Label.Purchase_Agreement_clone_failed));
            isVisible = false;
            return null;
        }else{
        	newPA = oldPA.clone(false,true);
	        newPA.Status__c = 'Draft';
	        Savepoint sp = Database.setSavepoint();
	        
	        try {
	            DML.insertAsUser( new list<sobject>{ newPA });

				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				Id newPAId = newPA.id;
				
				SOQLUtil soql = new SOQLUtil('Contract__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','Name','Company__c','Contract_Start__c','Contract_End__c','Supplier__c','Contract_Number__c','Payment_Term__c','FOB_Term__c',
					'Ship_to_Facility__c','Transportation_Mode__c'
				});
				soql.setWhereClause('id = :newPAId');

				Contract__c retrievedNewPA = Database.query(soql.getQuery());

	        	id oid = oldPA.id; 
	        	
	        	String whereClause = 'Contract__c = :oid Order By CreatedDate Desc' ;
        
			    soql = new SOQLUtil('Contract_Line__c');
			    soql.addFields('Manage_Lines');
			    soql.addFields('Tiers');
			    soql.addFields(new set<string>{ 'Id','Line__c','Purchased_Quantity__c','PurchasedValue__c','Quantity_Received__c','Remaining_Quantity__c',
					        					'Remaining_Value__c','Remaining_Value_Percent__c', 'ValueReceived__c', 'ASL_Override__c', 'CPC_Code__c', 
					        					'Contract__r.Contract_Number__c', 'Contract__r.Contract_Number__c', 'Type__c','Contract__r.Supplier__c', 'Status__c'
        		});
			    soql.setWhereClause(whereClause);
	    
        		for (Contract_Line__c oldPALObject: Database.query(soql.getQuery())){ //KNDY-7997 - Changed the Field reference from Purchased_Value__c to PurchasedValue__c and Value_Received__c to ValueReceived__c  
        					
        		    Contract_Line__c newPALObject = new Contract_Line__c();          
		            newPALObject = oldPALObject.clone(false,true);
		            //PTP-68 Remove Active flag from Purchase Agreement
		            //Set status to Open and Company on New agreement line 
		            newPALObject.Status__c = 'Draft';//PTP-306 Setting the PA Line as Draft in order to trigger an AVL validation
		            newPALObject.ASL_Override__c = false; //PTP-306 Wiping out ASL override and CPC code fields on newly cloned PA lines
		            newPALObject.CPC_Code__c = ''; //PTP-306
		            newPALObject.Company__c = retrievedNewPA.Company__c;
		            newPALObject.Purchased_Quantity__c = 0;
		            // newPALObject.PurchasedValue__c = 0; //KNDY-7997 - Changed the Field reference from Purchased_Value__c to PurchasedValue__c
		            newPALObject.Quantity_Received__c = 0;
		            newPALObject.Approved__c = false;
		            //newPALObject.Value_Received__c = 0; //KNDY-7997 - Changed the Field reference from Value_Received__c to ValueReceived__c          
		            newPALObject.Contract_Start__c = retrievedNewPA.Contract_Start__c;
		            newPALObject.Contract_End__c = retrievedNewPA.Contract_End__c;
		            newPALObject.Contract__c = retrievedNewPA.ID;
		            //newPALObject.Unique_Key_For_Blanket__c = retrievedNewPA.Contract_Number__c;//PTP-306 Making it in sync with Add manage functionality
		            PALList.add(newPALObject);
				}
				 
        		DML.insertAsUser(  PALList );
	        } 
	        catch (DmlException e) {
	           ApexPages.addMessages(e);
	           Database.rollback(sp);
	          // isVisible = false; //PTP-172
	           return null;
	        }          
	
	        PageReference PAPage = new PageReference('/'+newPA.Id);
	        PAPage.setRedirect(true);
	        return PAPage;
        }
            
    }

    public Boolean hasErrors { get { return ApexPages.hasMessages(); } }
    
}