@isTest
private class ProductTest {
 class TData {
         TestFuel fuel = new TestFuel();
         
         Item__c item10 = new Item__c(
                             name = fuel.company.Name + ' Item-10',
                             Description__c='Item-10',
                             Source__c = 'Manufactured',
                             Class__c = fuel.clsobj.ID,
                             Lead_Time__c = 5,
                             ABC_Code__c = 'A',
                             company__c = fuel.company.id,
                             Active__c = true,
                             Stocking_UOM__c = fuel.uomObj.ID,
                             Dimension_UOM__c = fuel.uomInch.ID,
                             Length__c = 11,
                             Width__c = 11,
                             Height__c = 11
                         );    
         Item__c item11 = new Item__c(
                             name = fuel.company.Name + ' Item-11',
                             Description__c='Item-11',
                             Source__c = 'Purchased',
                             Purchasing_UOM__c = fuel.uomObj.id,
                             Lead_Time__c = 2,
                             ABC_Code__c = 'B',
                             company__c = fuel.company.id,
                             Active__c = true,
                             Stocking_UOM__c = fuel.uomObj.ID,
                             Dimension_UOM__c = null, // keep it blank to test
                             Length__c = 12,
                             Width__c = 12,
                             Height__c = 12
                         );                             
         
         
         TData() {
             
         }
         
         void create() {
             insert new Item__c[] {item10, item11};
         }
     }
    
     testmethod static void testProductCopyExtension() {
        TData data = new TData();
        data.create();
        
        Product__c p10 = new Product__c(
                                company__c = data.fuel.company.id,
                                Name = 'Product 1' ,
                                Item__c  = data.item10.ID,
                                Description__c = 'Product-10',
                                Selling_UOM__c = data.fuel.uomObj.ID,
                                Weight__c = 13,
                                Weight_UOM__c = data.fuel.uomList[0].ID,
                                UPC_Code__c = '123456789123',  
                                Primary_Key__c = '123456',
                                Dimension_UOM__c = data.fuel.uomObj.Id // this shouldn't get overriden
                        ); 
        insert p10;
        
        ProductCopyFromItemExt ext = new ProductCopyFromItemExt(new ApexPages.StandardController(p10));
        // this extension was menat to update obsolete old data in org. Its not possible to create such data now, as trigger will 
        // always update the missing dimension fields on product. So writing this test for coverage only
        ext.onInit();
        
            Map<Id, Product__c> productsById = new Map<Id, Product__c> ([
                                            SELECT Length__c, Width__c, Height__c, Dimension_UOM__c from Product__c 
                                        ]);
        
        System.assertNotEquals(null, productsById.get(p10.Id), 'Should be created fine');
        
        System.assertEquals(data.item10.Length__c, productsById.get(p10.Id).Length__c, 'Should be copied as its missing on product');
        System.assertEquals(data.item10.Width__c, productsById.get(p10.Id).Width__c, 'Should be copied as its missing on product');
        System.assertEquals(data.item10.Height__c, productsById.get(p10.Id).Height__c, 'Should be copied as its missing on product');
        System.assertNotEquals(data.item10.Dimension_UOM__c, productsById.get(p10.Id).Dimension_UOM__c, 'Should NOT be copied as its their on product');
        
     }
     
     testmethod static void testProductInsertTrigger() {
        TData data = new TData();
        data.create();
        
        Product__c p10 = new Product__c(
                                company__c = data.fuel.company.id,
                                Name = 'Product 1' ,
                                //Item__c  = data.item10.ID,
            					Item_Identifier__c = data.item10.name,// test trigger to match up
                                Description__c = 'Product-10',
                                Selling_UOM__c = data.fuel.uomObj.ID,
                                Weight__c = 13,
                                Weight_UOM__c = data.fuel.uomList[0].ID,
                                UPC_Code__c = '123456789123',  
                                Primary_Key__c = '123456',
                                Dimension_UOM__c = data.fuel.uomObj.Id // this shouldn't get overriden
                        );  
        // second product which has some details, which shouldn't get overriden                        
        Product__c p10_2 = new Product__c(
                                company__c = data.fuel.company.id,
                                Name = 'Product 10_2' ,
                                Item__c  = data.item10.ID,
                                Description__c = 'Product-10_2',
                                Selling_UOM__c = data.fuel.uomObj.ID,
                                Weight__c = 13,
                                Weight_UOM__c = data.fuel.uomList[0].ID,
                                UPC_Code__c = '123456789123',  
                                Length__c = 10, // this shouldn't get overriden
                                Width__c = 10, // this shouldn't get overriden
                                Height__c = 10 // this shouldn't get overriden
                        );  
                        
        Product__c p11 = new Product__c(
                                company__c = data.fuel.company.id,
                                Name = 'Product 11' ,
                                Item__c  = data.item11.ID,
                                Description__c = 'Product-11',
                                Selling_UOM__c = data.fuel.uomObj.ID,
                                Weight__c = 13,
                                Weight_UOM__c = data.fuel.uomList[0].ID,
                                UPC_Code__c = '234567891234'
                        );                          
        insert new Product__c[] { p10, p10_2, p11 };
        
        Map<Id, Product__c> productsById = new Map<Id, Product__c> ([
            // can do an open query, as I dont see any other products in system :)
            SELECT Length__c, Item__c, Width__c, Height__c, Dimension_UOM__c from Product__c 
        ]);
        
        System.assertNotEquals(null, productsById.get(p10.Id), 'Should be created fine');
        System.assertNotEquals(null, productsById.get(p10_2.Id), 'Should be created fine');
        System.assertNotEquals(null, productsById.get(p11.Id), 'Should be created fine');
        System.assertNotEquals(null, productsById.get(p10.Id).Item__c, 'Should be linked fine');
        
        System.assertEquals(data.item10.Length__c, productsById.get(p10.Id).Length__c, 'Should be copied as its missing on product');
        System.assertEquals(data.item10.Width__c, productsById.get(p10.Id).Width__c, 'Should be copied as its missing on product');
        System.assertEquals(data.item10.Height__c, productsById.get(p10.Id).Height__c, 'Should be copied as its missing on product');
        System.assertNotEquals(data.item10.Dimension_UOM__c, productsById.get(p10.Id).Dimension_UOM__c, 'Should NOT be copied as its their on product');
        
        System.assertNotEquals(data.item10.Length__c, productsById.get(p10_2.Id).Length__c, 'Should NOT be copied as its their on product');
        System.assertNotEquals(data.item10.Width__c, productsById.get(p10_2.Id).Width__c, 'Should NOT be copied as its their on product');
        System.assertNotEquals(data.item10.Height__c, productsById.get(p10_2.Id).Height__c, 'Should NOT be copied as its their on product');
        System.assertEquals(data.item10.Dimension_UOM__c, productsById.get(p10_2.Id).Dimension_UOM__c, 'Should be copied as its missing on product');
        
        System.assertEquals(data.item11.Length__c, productsById.get(p11.Id).Length__c, 'Should be copied as its missing on product');
        System.assertEquals(data.item11.Width__c, productsById.get(p11.Id).Width__c, 'Should be copied as its missing on product');
        System.assertEquals(data.item11.Height__c, productsById.get(p11.Id).Height__c, 'Should be copied as its missing on product');
        System.assertEquals(data.item11.Dimension_UOM__c, productsById.get(p11.Id).Dimension_UOM__c, 'Should be copied as its missing on product');
      
        Product__c p10Reload = productsById.get(p10.Id);
        p10Reload.Dimension_UOM__c = null; // now it should get copied on update
        update p10Reload;
        
        p10Reload = [Select Dimension_UOM__c from Product__c Where Id =:p10Reload.Id];
        System.assertEquals(data.item10.Dimension_UOM__c, p10Reload.Dimension_UOM__c, 'Should be copied as its missing on product');
          
     }

}