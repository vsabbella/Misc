@isTest
public with sharing class ShipLineTriggerTest {
/*
    static testMethod void test_with_shipline_trigger() {
    		TestFuel fuel = new TestFuel();
            List<Period__c> periodList = fuel.periodList;
            
            UOM__c uomObj = new UOM__c(); 
            uomObj.Name = 'LB';
            uomObj.Description__c = 'Pound';
            insert uomObj;
                     
            // Test Product on Insert
            Product__c Product = new Product__c(); 
            Product__c Product2 = new Product__c();
                
            product.Name = 'Product 1' ;
            product.Weight__c = 13;
            product.Description__c = 'Product-10';
            //product.company__c = company.id;
            product.Weight_UOM__c = uomObj.id; 
            product.UPC_Code__c = '123456789123';  
            insert product;
            
            product2.Name =  ' Product-15';
            product2.Description__c = 'Product-15';
            product2.Weight__c = 5;
            //product2.company__c = company.id;
            product.Weight_UOM__c = uomObj.id; 
            product2.UPC_code__c = '234567891234'; 
            insert product2;    

            //Test Shipment on Insert 
            Shipment__c shipment = new Shipment__c();
            
            shipment.Date_Shipped__c = system.now(); 
            //shipment.status__c = 'Confirmed'; SK- shipment should be not be confirmed when we need to add lines / update lines to that shipment
            shipment.Tracking_ID__c = '12345678';
            shipment.Currency__c = TestFuel.currencyUSD.id;
            shipment.Company__c = fuel.company.id;
            //shipment.Finalized__c = true;  -- This test does not need the source doc to be finalized hence commenting out the line
            //KNDY-3369 shipment.Accounted__c = false;
            insert shipment;
           
            system.assertEquals(null, shipment.Total_Shipment_Weight__c, 'expected null weight');

            //Test Shipment Line on insert
            Shipment_Line__c shipLine = new Shipment_Line__c();
            shipLine.Shipment__c = shipment.Id;
            shipLine.product__c = Product.id;
            shipLine.Quantity_Shipped__c = 10;
            shipLine.Extended_Cost__c = 5;
            shipLine.Unit_Price__c = 12.0;
            shipLine.Discount_Percent__c = 2; // 2% == 0.02 decimal 
            insert shipLine;
           
            // Testing Ship Invoice Line - Weight after Insert
            Shipment_Line__c SIL1 = [select Weight__c, Total_Weight__c, Extended_price__c
                                                        from Shipment_Line__c 
                                                        where Id = :shipLine.Id limit 1];
            
            system.assertEquals( 130,   SIL1.Total_Weight__c , ' weight did not match ');
            
            system.assertEquals( 117.6,   SIL1.Extended_price__c , ' extended price did not match ');   // 10 * 12 - ( 4% * 120) == 115.2
            
            // Comparing Shipment(with one Ship Invoice Line) and Ship Invoice Line Weights
            Shipment__c ship1 = [select Total_Shipment_Weight__c from Shipment__c where Id = :shipment.Id];
            system.assertEquals(ship1.Total_Shipment_Weight__c, SIL1.Total_Weight__c);
            system.assertEquals(ship1.Total_Shipment_Weight__c, 130);

            // Test Ship Invoice Line Weight after Updating the Product Weight
            Product__c productUpdate = [select Weight__c from Product__c where Id = :Product.id];
            product.Weight__c = 15;
            update productUpdate;
            
            Shipment_Line__c SIL1u = [select Total_Weight__c, Quantity_Shipped__c from Shipment_Line__c where Id = :shipLine.Id];
            SIL1u.Quantity_Shipped__c = 20;
            update SIL1u;
            
            Shipment__c Ship2 = [select Total_Shipment_Weight__c from Shipment__c where Id = :shipment.Id];
            Shipment_Line__c SIL2 = [select Total_Weight__c, Quantity_Shipped__c from Shipment_Line__c where Id = :shipLine.Id];

            system.assertEquals(SIL2.Total_Weight__c, Ship2.Total_Shipment_Weight__c);

            //Test Ship Invoice Line on second/Third insert
            Shipment_Line__c shipLine2 = new Shipment_Line__c();
            
            shipLine2.Shipment__c = shipment.Id;
            //shipLine2.company__c = company.id;
            shipLine2.product__c = product2.id;
            shipLine2.Quantity_Shipped__c = 100;
            insert shipLine2;
       
            
            Shipment_Line__c shipLine3 = new Shipment_Line__c();
           
            shipLine3.Shipment__c = shipment.Id;
            //shipLine3.company__c = company.id;
            shipLine3.product__c = product.id;
            shipLine3.Quantity_Shipped__c = 10;
            insert shipLine3;
         
            
            // Aggregating the Weight on Single Shipment
            AggregateResult ag1 = [select sum(Total_Weight__c) from Shipment_Line__c where Shipment__c = :shipment.Id];
            
            Shipment__c Ship3 = [select Total_Shipment_Weight__c from Shipment__c where Id = :shipment.Id];
            system.assertEquals(Ship3.Total_Shipment_Weight__c, ag1.get('expr0'));

            shipLine2.Description__c = 'Description';
            integer i = Limits.getQueries();
            
            update shipLine2;
            integer i2 = Limits.getQueries();
            
            system.assertEquals( i, i2, 'Expected no Additional Queries on SalesOrderLine Trigger' );
            
            // Test Ship Invoice Line on delete
            delete shipLine2;

            AggregateResult ag2 = [select sum(Total_Weight__c) from Shipment_Line__c where Shipment__c = :shipment.Id];
                        
            Shipment__c Ship4 = [select Total_Shipment_Weight__c from Shipment__c where Id = :shipment.Id];
            system.assertEquals(Ship4.Total_Shipment_Weight__c, ag2.get('expr0'));
    }
*/
    /********** Test for the rollup fields and formula fields in the shipment line and header************/
/*
    static testMethod void testShipLineRollup() {
        testdata data = new testdata();
        
             //Test Item on insert 
            Item__c  objItem = new Item__c ();
            objItem.Name = 'Test Item';
            objItem.Company__c = data.company.Id;
            objItem.Weight__c = 100;
            insert objItem;
        
             //Test Product on Insert
            Product__c product = new Product__c(); 
            product.Name = 'Product 1';
            product.Weight__c = 4;
            product.Description__c = 'Product-10'; 
            product.UPC_Code__c = '12345643289';  
            product.Units_per_Layer__c = 20;
            product.Layers_per_Pallet__c = 5;
            product.Item__c = objItem.Id;
            product.company__c = data.company.Id;
            insert product;
            
            Customer__c custship = data.customerShipTo;
            custship.Pallet_Product__c = product.Id;
            update custship;
            
             //Test Shipment on Insert 
            Shipment__c shipment = new Shipment__c();
            shipment.Date_Shipped__c = system.now(); 
            //shipment.Status__c = 'Confirmed'; SK- shipment should be not be confirmed when we need to add lines / update lines to that shipment
            shipment.Tracking_ID__c = '12345890';
            shipment.Currency__c = TestFuel.currencyUSD.id;
            shipment.company__c = data.company.id;
            //shipment.Finalized__c = true;  -- This test does not need the source doc to be finalized hence commenting out the line
            shipment.Customer__c = custship.Id;
            insert shipment;

             //Test Shipment Line on insert
            Shipment_Line__c shipLine = new Shipment_Line__c();
            shipLine.Shipment__c = shipment.Id;
            shipLine.Product__c = Product.id;
            shipLine.Quantity_Planned__c = 20;
            shipLine.Extended_Cost__c = 5;
            shipLine.Unit_Price__c = 12.0;
            shipLine.Discount_Percent__c = 2; // 2% == 0.02 decimal
            insert shipLine;            
            
             //Test Shipment Line on insert
            Shipment_Line__c shipLine1 = new Shipment_Line__c();
            shipLine1.Shipment__c = shipment.Id;
            shipLine1.product__c = Product.id;
            shipLine1.Quantity_Planned__c = 40;
            shipLine1.Extended_Cost__c = 5;
            shipLine1.Unit_Price__c = 12.0;
            shipLine1.Discount_Percent__c = 2; // 2% == 0.02 decimal 
            insert shipLine1;

            Shipment__c Ship2 = [select Number_of_Pallets_Planned__c,Total_Product_Weight__c,Total_Pallet_Weight_Planned__c,Total_Weight_Planned__c from Shipment__c where Id = :shipment.Id limit 1];
            Shipment_Line__c SIL1 = [select Number_of_Pallets_Planned__c,Product_weight__c ,Quantity_Planned__c from Shipment_Line__c where Id = :shipLine.Id limit 1];
            Shipment_Line__c SIL2 = [select Number_of_Pallets_Planned__c, Product_weight__c,Quantity_Planned__c from Shipment_Line__c where Id = :shipLine1.Id limit 1];
            
            system.assertEquals(.2, SIL1.Number_of_Pallets_Planned__c);
            system.assertEquals(.4, SIL2.Number_of_Pallets_Planned__c);
            system.assertEquals(.6, Ship2.Number_of_Pallets_Planned__c);
            system.assertEquals(80, SIL1.Product_weight__c);
            system.assertEquals(160, SIL2.Product_weight__c);
            system.assertEquals(240, Ship2.Total_Product_Weight__c);
            system.assertEquals(100, Ship2.Total_Pallet_Weight_Planned__c);
            system.assertEquals(340, Ship2.Total_Weight_Planned__c);        
    }
    */
}