public with sharing class PurchaseAgreementNewExt {
	
	private ApexPages.StandardController controller;
	public Boolean isVisible { get; set;}
	public Contract__c newPA {get;set;}
    
    public PurchaseAgreementNewExt(ApexPages.StandardController c) {
		controller = c;
        newPA = (Contract__c) controller.getRecord();        
        // use the existing record that the controller has created for us
        newPA.put('Corporate_Buyer__c', UserInfo.getUserId());   
        newPA.Company__c = CompanyService.getDefaultCompanyId(); 
        isVisible = true; 
        assigndefault();       
    }
    public void assigndefault(){
    	//Contract__c pa = (Contract__c)controller.getRecord();
    	if(newPA.company__c!=null){

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			Id companyId = newPA.company__c;
			SOQLUtil soql = new SOQLUtil('company__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Default_Amount_Tolerance__c','Default_Quantity_Tolerance_Over__c','Default_Unit_Price_Tolerance_Over__c',
				'Default_Purchasing_Deliver_To_Facility__c'
			});
			soql.setWhereClause('id= :companyId');
	
			company__c com = Database.query(soql.getQuery());
	
	    	newPA.Amount_Tolerance__c = com.Default_Amount_Tolerance__c;
	    	newPA.Quantity_Tolerance_Over__c = com.Default_Quantity_Tolerance_Over__c;	
	    	//newPA.Quantity_Tolerance_Under__c = com.Default_Quantity_Tolerance_Under__c;
	    	newPA.Unit_Price_Tolerance_Over__c =  com.Default_Unit_Price_Tolerance_Over__c;
	    	//newPA.Unit_Price_Tolerance_Under__c = com.Default_Unit_Price_Tolerance_Under__c;
	    	newPA.Ship_to_Facility__c = com.Default_Purchasing_Deliver_To_Facility__c;
    	}
    }
    
     public Pagereference SavePA(){ //KNDY-2113
     	
            newPA.Status__c = 'Draft';
	        
	        Savepoint sp = Database.setSavepoint();
	        try {
            	DML.insertAsUser(newPA);
	        }catch (DmlException e) {
	           ApexPages.addMessages(e);
	           Database.rollback(sp);
	          // isVisible = false; //KNDY-3735 taking care of save button to not disappear
	           return null;
	        }          
	
	        PageReference PAPage = new PageReference('/'+newPA.Id);
	        PAPage.setRedirect(true);
	        return PAPage;
	        
    }
     
}