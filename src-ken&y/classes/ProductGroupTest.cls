/**
 * This class contains unit tests for validating the behavior of ProductGroup trigger
 */
@isTest
private class ProductGroupTest {

    static testMethod void ensureProductGroupCanFindHierarchyByCode() {
        TestFuel data = new TestFuel();
        Hierarchy__c h1 = data.hierarchy1;
        Product_Group__c pg1 = data.productGroup;
        Company__c co = data.company;
        
        pg1 = [ select id, Hierarchy__c from Product_Group__c where id = :pg1.id limit 1];
        system.assertEquals( h1.id,  pg1.Hierarchy__c , ' epxected the new product group to join in the hierarchy via trigger');

		// if we set company identifer we expect an update to link it to company, test that trigger
    		pg1.Company_Identifier__c = data.company.Company_Identifier__c;//'KEN';
    		pg1.Primary_Key__c = 'PG23';
		update pg1; 
		pg1 = [ select id, Company__c from Product_Group__c where id = :pg1.id limit 1];
 		//system.debug(logginglevel.INFO, pg1 );
 		system.assertEquals( co.id,  pg1.Company__c , ' epxected the new product group to join to a company');
		    
    		
    		// check that we can insert a product and it finds a group by setting the prod grp code
    		Product__c p1 = data.product; 
    		p1.Product_Group_Code__c = 'PG23';
    		update p1;	
    		p1 = [ select id, Company__c, Product_Group__c from Product__c where id = :p1.id limit 1];
    		system.assertEquals( pg1.id,  p1.Product_Group__c, ' expected the product to be a member of product group '+pg1.id );
    		system.assertEquals( co.id,  p1.Company__c, ' expected the product to be  '+pg1.id );
    		
    		// test the loading of products with Sales Hierarchy Code
    		p1.Sales_Hierarchy_Code__c = 'H1111';
    		update p1;
    		p1 = [ select id, Sales_Hierarchy__c from Product__c where id = :p1.id limit 1];
    		system.assertEquals( h1.id,  p1.Sales_Hierarchy__c, ' expected the product to be a member of sales hierarchy '+h1.id );
    		
    		
    }
}