public with sharing class FacilityItemNewExt {
    
    private ApexPages.StandardController con;

    public FacilityItemNewExt(ApexPages.StandardController controller) {
        
        con = controller;
    }
    
    public Pagereference SaveFI() {
        
        Facility_Item__c fiObj = (Facility_Item__c) con.getRecord();
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Item__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Name','Active__c','Aggregation_Days__c','Description__c','EOQ__c','Lead_Time__c','Ordering_Multiple__c','Safety_Stock__c',
			'Shrinkage__c','Source__c','Use_Lot_Sizing__c'
		});
		Id itemId = fiObj.Item__c;
		soql.setWhereClause('ID =: itemId');
		Item__c iObj = Database.query(soql.getQuery());
                        
        fiObj.Active__c = iObj.Active__c;
        fiObj.Aggregation_Days__c = iObj.Aggregation_Days__c;
        fiObj.Description__c = iObj.Description__c;
        fiObj.EOQ__c = iObj.EOQ__c;
        fiObj.Lead_Time__c = iObj.Lead_Time__c;
        fiobj.Name = iObj.Name;
        fiObj.Ordering_Multiple__c = iObj.Ordering_Multiple__c;
        fiObj.Safety_Stock__c = iObj.Safety_Stock__c;
        fiObj.Shrinkage__c = iObj.Shrinkage__c;
        fiObj.Source__c = iObj.Source__c;
        fiObj.Use_Lot_Sizing__c = iObj.Use_Lot_Sizing__c;
        
        try {
                DML.insertAsUser(fiObj);
        }
        catch (DmlException e) {
            ApexPages.addMessages(e);
            return null;
        }  
        
        PageReference FIPage = new PageReference('/'+fiObj.ID);
        FIPage.setRedirect(true);
        return FIPage;

    }
}