@isTest
private class ProductGroupManageExtTest {
    
    static testMethod void testInit() {
        TestFuel fuel = new TestFuel();
        // setup defaults
        insert new User_Preference__c( ownerid = UserInfo.getUserId(), name = 'my preference', default_company__c = fuel.company.id );
        
        List<Product__c> products = new List<Product__c>{fuel.product, fuel.product2};
        Id prodGrpId = fuel.productGroup.Id;
        
        Test.startTest();
        ProductGroupManageExt pgm = new ProductGroupManageExt(new ApexPages.StandardSetController(products));    
        // Should pick company from product
        System.assertEquals(fuel.company.Id, pgm.companyId);
        System.assertEquals(ProductGroupManageExt.Product_FieldSet_Name, pgm.config.fieldSet);
        System.assertEquals('Product__c', pgm.config.objectName);
        
        // Give a product group id and see if its loaded
        ApexPages.currentPage().getParameters().put('id', prodGrpId);
        pgm = new ProductGroupManageExt(new ApexPages.StandardSetController(products));    
        // Should pick company which is default 
        System.assertEquals(fuel.company.Id, pgm.companyId);
        System.assertEquals(fuel.productGroup.Id, pgm.productGroup.Id);
        
        Test.stopTest();
        
    }
 
    static testMethod void testLoadProducts() {
        TestFuel fuel = new TestFuel();
        Product__c product = fuel.newProduct();
        product.Sales_hierarchy__c = fuel.hierarchy1.id;
        product.Product_Group__c = fuel.productGroup.Id;
        insert product;
        
        DataSourceResult result = ProductGroupManageExt.loadProducts(fuel.company.id, 
                                    fuel.hierarchy1.id, // hierarchy
                                    fuel.productGroup.Id,
                                    product.Item__c,
                                    product.Name,
                                    product.Description__c
                                    );       
        // 1 product should match                                    
        System.assertEquals(1, result.total);    
        System.assertEquals(product.Id, result.records[0].Id);
                                            
    }
}