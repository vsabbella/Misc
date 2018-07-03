public with sharing class ProductGroupManageExt  extends GridRelatedListController {
    @TestVisible static final String Product_FieldSet_Name = 'Manage_Products';
        
    public Id companyId {get;set;}
    public Product_Group__c productGroup {get;set;} 
    
    
    
    public ProductGroupManageExt(ApexPages.StandardSetController con) {
        /*if (con.getRecords() != null && !con.getRecords().isEmpty()) {
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			List<Product__c> productList = con.getRecords();
			SOQLUtil soql = new SOQLUtil('Product__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Company__c'
			});
			soql.setWhereClause('Id IN :productList');
			soql.setLimit(1);
			
			productList = Database.query(soql.getQuery());
			companyId = productList[0].Company__c;

        } else {
            // use default company id
            companyId = CompanyService.getDefaultCompanyId();
        }*/
        
        companyId = CompanyService.getDefaultCompanyId();
        
        Id productGrpId = ApexPages.currentPage().getParameters().get('id');
        if (productGrpId != null) {
            //try {
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('Product_Group__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Name'
				});
				soql.setWhereClause('Id = :productGrpId');

				productGroup = Database.query(soql.getQuery());
            //} catch (Exception e){
            
            //}
        }
        
        config.uniqueId = 'matchingProductsDiv';
        config.title = Label.Matching_Products;
        config.objectName = 'Product__c';
        config.fieldset = Product_FieldSet_Name;
        config.buttons = 'save,cancel,search';
    }
    
    @RemoteAction 
    public static DataSourceResult loadProducts(Id companyId, Id hierarchyId, Id productGroupId, Id itemId, String name, String description) {
       
        Set<Id> productIds = new Set<Id>();
        Set<Id> productGroupIds = new Set<Id>();
        String productSoqlWhereClause = ' Company__c = :companyId ';
        
        if (!String.isBlank(productGroupId)) {
            productSoqlWhereClause += ' AND Product_Group__c =:productGroupId ';    
        } 
        
        if (!String.isBlank(hierarchyId)) {
            productSoqlWhereClause += ' AND Sales_Hierarchy__c =:hierarchyId ';    
        } 
        
        if (!String.isBlank(itemId)) {
            productSoqlWhereClause += ' AND Item__c =:itemId ';    
        }         
        
        if (!String.isBlank(name)) {
            name = '%' + name + '%';
            productSoqlWhereClause += ' AND Name like :name ';    
        }         
        
        if (!String.isBlank(description)) {
            description = '%' + description + '%';
            productSoqlWhereClause += ' AND Description__c like :description ';    
        }         
        
	    SOQLUtil soql = new SOQLUtil('Product__c');
	    soql.addFields(Product_FieldSet_Name);
	    soql.setWhereClause(productSoqlWhereClause);
	    
	    List<sObject> result = Database.query(soql.getQuery());   

        return new DataSourceResult(result, result.size());
    }
    
    
}