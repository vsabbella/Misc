public with sharing class TransitRouteNewExt{
    public Transit_Route__c newobj{get;set;}{newObj = new Transit_Route__c();}
    public ApexPages.Standardcontroller con;
    
    public TransitRouteNewExt(ApexPages.StandardController controller) {
        con = controller;
        newObj = (Transit_Route__c) controller.getRecord();
    }
    public PageReference save(){
        newObj.Name = 'temp';
        try {
            DML.insertAsUser(newobj); 
            return new PageReference('/'+newObj.Id); 
        } catch (Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            return null;

        }
        
    }
    
    public PageReference saveandnew(){
        newObj.Name = 'temp1';
        DML.insertAsUser(newobj); 
        PageReference PageRef = Page.TransitRouteNew;
        PageRef.setredirect(true);
        return PageRef;      
    }
    
    public PageReference deleteRoute() { 
        // custom delete method to ensure that we can remove routes even if they are created by other users
        // KNDY-6157        
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id newObjId = newObj.Id;
		
		SOQLUtil soql = new SOQLUtil('Transit_Route__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id'
		});
		soql.setWhereClause('id = :newObjId');
		soql.setLimit(1);

		Transit_Route__c[] gonner = Database.query(soql.getQuery());

        try { 
            new DML.WithoutSharing().sobjectDel( gonner );
        } catch( Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Insufficient_access_contact_administrator_for_permissions));
            return null;
        }
        Schema.DescribeSObjectResult r = Transit_Route__c.sObjectType.getDescribe();
        String keyPrefix = r.getKeyPrefix();
    	return new PageReference('/'+keyPrefix);
    } 

}