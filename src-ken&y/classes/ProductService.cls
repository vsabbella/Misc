public with sharing class ProductService {

    /*
        Update Length, Width, Height and Dimension UOM from Item, in case its missing on product record
        @return Products which are missing this information and needs to be updated
    */
    public static Set<Product__c> populateMissingDimensionInfoInProductsFromItems(Product__c[] products) {
        // K: Inbound Product V: Item ID
        Map<Product__c, Id> productItemMap = new Map<Product__c, Id>();
        for (Product__c prd : products) {
            // if product has valid item, 
            if (prd.Item__c != null &&
                (prd.Height__c == null || prd.Height__c == 0 || prd.Length__c == null || prd.Length__c == 0 
                || prd.Width__c == null || prd.Width__c == 0 || prd.Dimension_UOM__c == null)){
                    productItemMap.put(prd, prd.Item__c);
                }
        }													
		
		if (!productItemMap.isEmpty()) {
		    
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			List<Id> itemIds = productItemMap.values();
			SOQLUtil soql = new SOQLUtil('Item__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Length__c','Width__c','Height__c','Dimension_UOM__c'
			});
			soql.setWhereClause('Id IN :itemIds');

			Map<Id, Item__c> itemsById = new Map<Id, Item__c>((List<Item__c>)Database.query(soql.getQuery()));

            for (Product__c prd : productItemMap.keySet()) {
                Item__c item = itemsById.get(prd.Item__c);
                if (item != null) {
                    if (prd.Height__c == null || prd.Height__c == 0) prd.Height__c = item.Height__c;
                    if (prd.Width__c == null || prd.Width__c == 0) prd.Width__c = item.Width__c;
                    if (prd.Length__c == null || prd.Length__c == 0) prd.Length__c = item.Length__c;
                    if (prd.Dimension_UOM__c == null) prd.Dimension_UOM__c = item.Dimension_UOM__c;
                }
            }		                                
		}
		return productItemMap.keySet();
    }
}