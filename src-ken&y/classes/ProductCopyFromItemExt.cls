public with sharing class ProductCopyFromItemExt {
    Id productId ;
    public ProductCopyFromItemExt(ApexPages.StandardController con) {
        productId = con.getId();
    }

    public PageReference onInit() {
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Product__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Item__c','Length__c','Width__c','Height__c','Dimension_UOM__c'
		});
		soql.setWhereClause('Id = :productId');

		Product__c[] products = Database.query(soql.getQuery());

        Set<Product__c> changedProducts = ProductService.populateMissingDimensionInfoInProductsFromItems(products);
        if (!changedProducts.isEmpty()) {
            DML.updateAsUser(new List<Product__c>(changedProducts));
        }
        return new PageReference( '/' + productId );
    }    
}