public with sharing class FacilityAssignmentManageExt {
    
    private ApexPages.StandardController controller;
    public Facility_Assignment__c fa { get;set;}
    public list<Facility_Assignment__c> FAList { get;set;}
    private SchemaUtil util = SchemaUtil.getInstance();
    Set<ID> faSet = new Set<ID>();
    public List<Facility_Assignment__c> createList = new List<Facility_Assignment__c>();
    public List<Facility_Assignment__c> updateList = new List<Facility_Assignment__c>();
    public List<Facility_Assignment__c> deleteList = new List<Facility_Assignment__c>();        
    
    public FacilityAssignmentManageExt(ApexPages.StandardController c) {
    
        controller = c;
        fa = (Facility_Assignment__c)controller.getRecord();
        fa.Company__c =  CompanyService.getDefaultCompanyId(); 

    }
    
    public Pagereference FASearch() {
    
        string whereClause;
        
        ID cid = fa.Company__c;
        whereClause = ' Company__c =: cid ';
        if (fa.Start_Date__c != null) {
            Date edat = fa.Start_Date__c;
            whereClause = whereClause +'and Start_Date__c =: edat ';
        }
        if (fa.Facility__c != null) {
            ID fid = fa.Facility__c;
            whereClause = whereClause +'and Facility__c =: fid ';
        }
        if (fa.Product_Group__c != null) {
            ID pid = fa.Product_Group__c;
            whereClause = whereClause +'and Product_Group__c =: pid ';
        }
        if (fa.Ship_to_Customer__c != null) {
            ID sid = fa.Ship_to_Customer__c;
            whereClause = whereClause +'and Ship_to_Customer__c =: sid ';
        }
        if (fa.Top_Parent_Customer__c != null) {
            ID tid = fa.Top_Parent_Customer__c;
            whereClause = whereClause +'and Ship_to_Customer__r.Top_Parent_Customer__c =: tid ';
        }
         if (fa.Customer_Identifier__c != null) {
            String ci = fa.Customer_Identifier__c;
            whereClause = whereClause +'and Ship_to_Customer__r.Customer_Identifier__c like: ci ';
        }
        
        
      
        SOQLUtil soql = new SOQLUtil('Facility_Assignment__c',true);//KNDY-10473
        soql.addFields('ListFA');
        soql.addFields('Id');
        soql.setWhereClause(whereClause);
        faList = database.query(soql.getQuery());
        return null;
    }
    
    Boolean checkinput() {
        
        if (fa.Create_Replace_Start_Date__c == null && fa.Create_Replace_Facility__c == null &&
            fa.Create_Product_Group__c == null && fa.Create_Ship_to_Customer__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_Replacement_Values_Set));
            return true;
        }
        
        if (fa.Create_Replace_Start_Date__c != null && fa.Create_Replace_Start_Date__c < system.today()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Start_Date_must_be_greater_than_or_equal_to_todays_date) );
            return true;
        }
        
        
        faSet = new Set<ID>();
        String selected_indexes = Apexpages.currentPage().getParameters().get('selected_indexes');
        for (Integer i : ArrayUtils.getIntegerList(selected_indexes) ) { 
            faSet.add(faList[i].ID);
        }
        return false;
    }
    
    public Pagereference FACreate() {
        
        if (checkinput()) return null;

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Facility_Assignment__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Active__c','Company__c','Start_Date__c','Facility__c','Product_Group__c','Ship_to_Customer__c'
		});
		soql.setWhereClause('ID in: faSet');
		for (Facility_Assignment__c obj : Database.query(soql.getQuery())) {

            Facility_Assignment__c newobj = new Facility_Assignment__c();          
            newObj = obj.clone(false,true);
            if (fa.Create_Replace_Start_Date__c != null) newObj.Start_Date__c = fa.Create_Replace_Start_Date__c;
            if (fa.Create_Replace_Facility__c != null) newObj.Facility__c = fa.Create_Replace_Facility__c;
            if (fa.Create_Product_Group__c != null) newObj.Product_Group__c = fa.Create_Product_Group__c;
            if (fa.Create_Ship_to_Customer__c != null) newObj.Ship_to_Customer__c = fa.Create_Ship_to_Customer__c;
            createList.add(newObj);
        }
        try {
            DML.insertAsUser(createList);
        } 
        catch(Exception e) {
             ApexPages.addMessages(e);
        }
        
        faSearch();
        return null;
    }
    
    public Pagereference FAReplace() {
        
        if (checkinput()) return null;
        
        if (fa.Create_Product_Group__c != null || fa.Create_Ship_to_Customer__c != null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Cannot_replace_ProductGroup_or_ShipToCustomer));
            return null;
        }
        
        SOQLUtil soql = new SOQLUtil('Facility_Assignment__c');
        soql.addFields(new set<string>{
			'ID','Active__c','Company__c','Start_Date__c','Facility__c',
			'Product_Group__c','Ship_to_Customer__c'        
        });
        soql.setWhereClause('ID in: faSet');
        
        for (Facility_Assignment__c obj : Database.query(soql.getQuery())) {
            if (fa.Create_Replace_Start_Date__c != null) obj.Start_Date__c = fa.Create_Replace_Start_Date__c;
            if (fa.Create_Replace_Facility__c != null) obj.Facility__c = fa.Create_Replace_Facility__c;
            if (fa.Create_Product_Group__c != null) obj.Product_Group__c = fa.Create_Product_Group__c;
            if (fa.Create_Ship_to_Customer__c != null) obj.Ship_to_Customer__c = fa.Create_Ship_to_Customer__c;
            updateList.add(obj);
        }
        
        try {
            DML.updateAsUser(updateList);
        } 
        catch(Exception e) {
             ApexPages.addMessages(e);
        }

        faSearch();
        return null;
            
    }
    
     public Pagereference FADelete() {
        
        String selected_indexes = Apexpages.currentPage().getParameters().get('selected_indexes');
        for (Integer i : ArrayUtils.getIntegerList(selected_indexes) ) { 
            if (faList[i].ID!= null) deleteList.add(faList[i]); 
        }
        
        try {
            DML.deleteAsUser(deleteList);
        } 
        catch(Exception e) {
             ApexPages.addMessages(e);
        }
        
        faSearch();
        return null;
            
    }

}