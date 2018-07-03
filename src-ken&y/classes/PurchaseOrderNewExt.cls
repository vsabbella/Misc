public with sharing class PurchaseOrderNewExt {
	
	private ApexPages.StandardController controller;
	public Boolean isVisible { get; set;}
	
    public PurchaseOrderNewExt(ApexPages.StandardController c) {
		controller = c;
        Sobject newObj = controller.getRecord();        
        // use the existing record that the controller has created for us
        newObj.put('Buyer__c', UserInfo.getUserId());   
        isVisible = true; 
        assigndefault();       
    }
    public void assigndefault(){
    	Purchase_Order__c po = (Purchase_Order__c)controller.getRecord();
    	if(po.company__c!=null){
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			Id companyId = po.company__c;
			
			SOQLUtil soql = new SOQLUtil('company__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Default_Purchasing_Deliver_To_Facility__c','Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__c'
			});
			soql.setWhereClause('id=:companyId');
	
			company__c com = Database.query(soql.getQuery());
	
	    	po.Delivery_Facility__c = com.Default_Purchasing_Deliver_To_Facility__c;
	    	po.Delivery_Location__c = com.Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__c;					
    	}
    }
    
    public Pagereference SavePO(){ //KNDY-2113
     	Purchase_Order__c po = (Purchase_Order__c)controller.getRecord();
    
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id supplierId = po.Supplier__c;
		
		SOQLUtil soql = new SOQLUtil('Supplier__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Remit_To__c','Hold_Purchasing__c','RecordType.Name','RecordType.DeveloperName','RecordTypeId','Company__c'
		});
		soql.setWhereClause('id =:supplierId');
		soql.setLimit(1);

		Supplier__c supplier = Database.query(soql.getQuery());

        //PTP-652
        if(!String.isBlank(supplier.Company__c) 
        	&& (po.Company__c != supplier.Company__c)){
            
            ApexPages.addMessage( new Apexpages.Message(ApexPages.severity.FATAL,
                    Label.Purchase_from_Supplier_not_tagged_to_the_Company));
            return null;
        }
       
        if (supplier.Hold_Purchasing__c){
        	ApexPages.addMessage( new Apexpages.Message(ApexPages.severity.FATAL,
                    Label.Purchase_Order_creation_failed));
            isVisible = false;        
            return null;
        }else if (po.Type__c == 'Drop Ship'){
        	ApexPages.addMessage( new Apexpages.Message(ApexPages.severity.FATAL,Label.Purchase_Order_creation_failed_Cannot_create_Drop_Ship_PO));      
            return null;
        }
        else {
	        po.Approval_Status__c = 'Pending Authorization';
	        po.Date_Closed__c = null;
	        po.Order_Date__c = system.today();
	        po.Status__c = 'Open';        
	        po.Remit_To_Supplier__c = supplier.Remit_To__c;// PTP-567
	        
	        Savepoint sp = Database.setSavepoint();
	        try {
            	DML.insertAsUser(po);
	        }catch (DmlException e) {
	           ApexPages.addMessages(e);
	           Database.rollback(sp);
	          // isVisible = false; //KNDY-3735 taking care of save button to not disappear
	           return null;
	        }          
	
	        PageReference POPage = new PageReference('/'+po.Id);
	        POPage.setRedirect(true);
	        return POPage;
	        
        }
     }
}