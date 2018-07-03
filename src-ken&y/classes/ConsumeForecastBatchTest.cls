/**
 * This class contains unit tests for validating the behavior ofc Apex classes
 * and triggers.
 */
@isTest
private class ConsumeForecastBatchTest {

    static testMethod void batchTestWithCust() {
       
       TestData data = new TestData();
        
        Location__c location = data.location; 
        Order_Forecast__c ofc = new Order_Forecast__c();
        ofc.Company__c = data.company.id;
        ofc.Customer__c = data.customerSoldTo.id;
        ofc.Consumed_Quantity__c = 0;
        ofc.Consumption_End_Date__c = system.today() + 30;
        ofc.Consumption_Start_Date__c = system.today();
        ofc.Forecast_Quantity__c = 1234;
        ofc.Item__c = data.itemList[0].ID;
        ofc.Plan_Date__c = system.today() + 10 ;
        insert ofc;
        
        
      
        Sales_Order__c so = new Sales_Order__c();
        so.Company__c = data.company.id;
        so.Customer__c = data.customerSoldTo.id;
        so.Ship_To__c = data.customerShipTo.Id;
        so.Payment_Term__c = data.terms.id;
        so.Required_Date__c = System.today()+ 5 ;
        insert so;
        so.Status__c = 'Open';
        update so;
        
        Sales_Order_Line__c sol = new Sales_Order_Line__c();
        sol.Product__c = data.product.Id;
        sol.Description__c = data.product.Description__c;
        sol.Company__c = data.company.id;
        sol.Sales_Order__c = so.Id;
        sol.Unit_Price__c = 10;
        sol.Quantity_Ordered__c = 100;
        sol.Ship_From_Location__c = location.Id;
        sol.Required_Date__c = System.today() + 5 ;
        
        insert sol;
        
        test.startTest();
        
        ConsumeForecastBatch batchInstance = new ConsumeForecastBatch(data.company.Id);
        List <Sales_Order_Line__c> solList = [select ID, Product__r.Item__c, Quantity_Ordered__c, Required_Date__c,Sales_Order__r.Customer__c 
                                                from Sales_Order_Line__c 
                                                where Company__c  =: data.company.id and 
                                                Quantity_Ordered__c > 0 and 
                                                Sales_Order__r.Status__c != 'Draft' and 
                                                Required_Date__c != null
                                              and Product__r.Item__c = :data.itemList[0].ID];
        
         
        //Database.BatchableContext info;
        //batchInstance.execute(info, solList);
        Database.executeBatch(new ConsumeForecastBatch(data.company.Id));
        test.stopTest();
        
        system.assert(batchInstance.messages.size() == 0);
        ofc = [select ID, Consumed_Quantity__c, Consumption_End_Date__c,
                                             Consumption_Start_Date__c, Forecast_Quantity__c, Item__c 
                                             from Order_Forecast__c
                                             WHERE id = :ofc.id];
        
        system.assertEquals(100,ofc.Consumed_Quantity__c);

    }
    
    static testMethod void batchTestWithoutCust() {
        
        TestData data = new TestData();
        
        Location__c location = data.location;
        Order_Forecast__c ofc = new Order_Forecast__c();
        ofc.Company__c = data.company.id;
        ofc.Customer__c = null;
        ofc.Consumed_Quantity__c = 0;
        ofc.Consumption_End_Date__c = system.today() + 30;
        ofc.Consumption_Start_Date__c = system.today();
        ofc.Forecast_Quantity__c = 1234;
        ofc.Item__c = data.itemList[0].ID;
        ofc.Plan_Date__c = system.today() + 10;
        insert ofc;
        
        Sales_Order__c so = new Sales_Order__c();
        so.Company__c = data.company.id;
        so.Customer__c = data.customerSoldTo.id;
        so.Ship_To__c = data.customerShipTo.Id;
        so.Payment_Term__c = data.terms.id;
        so.Required_Date__c = System.today()+ 5 ;
        insert so;
        so.Status__c = 'Open';
        update so;
        Sales_Order_Line__c sol = new Sales_Order_Line__c();
        sol.Product__c = data.product.Id;
        sol.Description__c = data.product.Description__c;
        sol.Company__c = data.company.id;
        sol.Sales_Order__c = so.Id;
        sol.Unit_Price__c = 10;
        sol.Quantity_Ordered__c = 100;
        sol.Ship_From_Location__c = location.Id;
        sol.Required_Date__c = System.today()+ 5 ;
        insert sol;
        
        test.startTest();
        
        ConsumeForecastBatch batchInstance = new ConsumeForecastBatch(data.company.Id);
        List <Sales_Order_Line__c> tempList = [select ID, Product__r.Item__c, Quantity_Ordered__c, Required_Date__c,Sales_Order__r.Customer__c 
                                                from Sales_Order_Line__c 
                                                where Company__c  =: data.company.id and 
                                                Quantity_Ordered__c > 0 and 
                                                Sales_Order__r.Status__c != 'Draft' and 
                                                Required_Date__c != null
                                              and Product__r.Item__c = :data.itemList[0].ID
                                              ];
       // Database.BatchableContext info;
        //batchInstance.execute(info, tempList);
        Database.executeBatch(new ConsumeForecastBatch(data.company.Id));
        
        test.stopTest();
        
        system.assert(batchInstance.messages.size() == 0);
        List <Order_Forecast__c> oFList = [select ID, Consumed_Quantity__c, Consumption_End_Date__c,
                                             Consumption_Start_Date__c, Forecast_Quantity__c, Item__c 
                                             from Order_Forecast__c
                                             where ID = :ofc.id ];
        system.assertEquals(100,oFList[0].Consumed_Quantity__c);
        

    }
       static testMethod void batchTestWithCustAndNoCust() {
       
       TestData data = new TestData();
        
        Location__c location = data.location; 
        Order_Forecast__c ofc = new Order_Forecast__c();
        ofc.Company__c = data.company.id;
        ofc.Customer__c = data.customerSoldTo.id;
        ofc.Consumed_Quantity__c = 0;
        ofc.Consumption_End_Date__c = system.today() + 30;
        ofc.Consumption_Start_Date__c = system.today();
        ofc.Forecast_Quantity__c = 1234;
        ofc.Item__c = data.itemList[0].ID;
        ofc.Plan_Date__c = system.today() + 10 ;
        insert ofc;
        Order_Forecast__c ofc1 = new Order_Forecast__c();
        ofc1.Company__c = data.company.id;
        ofc1.Customer__c = null;
        ofc1.Consumed_Quantity__c = 0;
        ofc1.Consumption_End_Date__c = system.today() + 30;
        ofc1.Consumption_Start_Date__c = system.today();
        ofc1.Forecast_Quantity__c = 1234;
        ofc1.Item__c = data.itemList[0].ID;
        ofc1.Plan_Date__c = system.today() + 10 ;
        insert ofc1;
        
      
        Sales_Order__c so = new Sales_Order__c();
        so.Company__c = data.company.id;
        so.Customer__c = data.customerSoldTo.id;
        so.Ship_To__c = data.customerShipTo.Id;
        so.Payment_Term__c = data.terms.id;
        so.Required_Date__c = System.today()+ 5 ;
        insert so;
        so.Status__c = 'Open';
        update so;
        
        Sales_Order_Line__c sol = new Sales_Order_Line__c();
        sol.Product__c = data.product.Id;
        sol.Description__c = data.product.Description__c;
        sol.Company__c = data.company.id;
        sol.Sales_Order__c = so.Id;
        sol.Unit_Price__c = 10;
        sol.Quantity_Ordered__c = 100;
        sol.Ship_From_Location__c = location.Id;
        sol.Required_Date__c = System.today() + 5 ;
        
        insert sol;
        
        test.startTest();
        
        ConsumeForecastBatch batchInstance = new ConsumeForecastBatch(data.company.Id);
        List <Sales_Order_Line__c> solList = [select ID, Product__r.Item__c, Quantity_Ordered__c, Required_Date__c,Sales_Order__r.Customer__c 
                                                from Sales_Order_Line__c 
                                                where Company__c  =: data.company.id and 
                                                Quantity_Ordered__c > 0 and 
                                                Sales_Order__r.Status__c != 'Draft' and 
                                                Required_Date__c != null
                                              and Product__r.Item__c = :data.itemList[0].ID];
        
         
        //Database.BatchableContext info;
        //batchInstance.execute(info, solList);
        Database.executeBatch(new ConsumeForecastBatch(data.company.Id));
        test.stopTest();
        
        system.assert(batchInstance.messages.size() == 0);
         ofc = [select ID, Consumed_Quantity__c, Consumption_End_Date__c,
                                             Consumption_Start_Date__c, Forecast_Quantity__c, Item__c 
                                             from Order_Forecast__c where
                                             id = :ofc.id];
        
        system.assertEquals(100,ofc.Consumed_Quantity__c);
        ofc1 = [select ID, Consumed_Quantity__c, Consumption_End_Date__c,
                                             Consumption_Start_Date__c, Forecast_Quantity__c, Item__c 
                                             from Order_Forecast__c where
                                             id = :ofc1.id];   
           
           
        system.assertEquals(0,ofc1.Consumed_Quantity__c);   

    }
    
     static testMethod void batchTestWithCustFacility() {
       
       TestData data = new TestData();
        Facility__c facility = data.facility; 
        Location__c location = data.location; 
        Order_Forecast__c ofc = new Order_Forecast__c();
        ofc.Company__c = data.company.id;
        ofc.Customer__c = data.customerSoldTo.id;
        ofc.Facility__c = data.facility.id; 
        ofc.Consumed_Quantity__c = 0;
        ofc.Consumption_End_Date__c = system.today() + 30;
        ofc.Consumption_Start_Date__c = system.today();
        ofc.Forecast_Quantity__c = 1234;
        ofc.Item__c = data.itemList[0].ID;
        ofc.Plan_Date__c = system.today() + 10 ;
        insert ofc;
        Order_Forecast__c ofc1 = new Order_Forecast__c();
        ofc1.Company__c = data.company.id;
        ofc1.Customer__c = null;
        ofc1.Facility__c = null;
        ofc1.Consumed_Quantity__c = 0;
        ofc1.Consumption_End_Date__c = system.today() + 30;
        ofc1.Consumption_Start_Date__c = system.today();
        ofc1.Forecast_Quantity__c = 1234;
        ofc1.Item__c = data.itemList[0].ID;
        ofc1.Plan_Date__c = system.today() + 10 ;
        insert ofc1;
        
      
        Sales_Order__c so = new Sales_Order__c();
        so.Company__c = data.company.id;
        so.Customer__c = data.customerSoldTo.id;
        so.Ship_To__c = data.customerShipTo.Id;
        so.Payment_Term__c = data.terms.id;
        so.Required_Date__c = System.today()+ 5 ;
        insert so;
        so.Status__c = 'Open';
        update so;
        
        Sales_Order_Line__c sol = new Sales_Order_Line__c();
        sol.Product__c = data.product.Id;
        sol.Description__c = data.product.Description__c;
        sol.Company__c = data.company.id;
        sol.Sales_Order__c = so.Id;
        sol.Unit_Price__c = 10;
        sol.Quantity_Ordered__c = 100;
        sol.Ship_From_Location__c = location.Id;
        sol.Required_Date__c = System.today() + 5 ;
        
        insert sol;
        
        test.startTest();
        
        ConsumeForecastBatch batchInstance = new ConsumeForecastBatch(data.company.Id);
        List <Sales_Order_Line__c> solList = [select ID, Product__r.Item__c, Quantity_Ordered__c, Required_Date__c,Sales_Order__r.Customer__c 
                                                from Sales_Order_Line__c 
                                                where Company__c  =: data.company.id and 
                                                Quantity_Ordered__c > 0 and 
                                                Sales_Order__r.Status__c != 'Draft' and 
                                                Required_Date__c != null
                                              and Product__r.Item__c = :data.itemList[0].ID];
        
         
        
        Database.executeBatch(new ConsumeForecastBatch(data.company.Id));
        test.stopTest();
        
        system.assert(batchInstance.messages.size() == 0);
        ofc = [select ID, Consumed_Quantity__c, Consumption_End_Date__c,
                                             Consumption_Start_Date__c, Forecast_Quantity__c, Item__c 
                                             from Order_Forecast__c where
                                             id = :ofc.id];
        
        system.assertEquals(100,ofc.Consumed_Quantity__c);
        ofc1 = [select ID, Consumed_Quantity__c, Consumption_End_Date__c,
                                             Consumption_Start_Date__c, Forecast_Quantity__c, Item__c 
                                             from Order_Forecast__c where
                                             id = :ofc1.id];   
           
           
        system.assertEquals(0,ofc1.Consumed_Quantity__c);   

    }
    static testMethod void batchTestWithnoCustnoFacility() {
       
       TestData data = new TestData();
        Facility__c facility = data.facility; 
        Location__c location = data.location; 

        Order_Forecast__c ofc1 = new Order_Forecast__c();
        ofc1.Company__c = data.company.id;
        ofc1.Customer__c = null;
        ofc1.Facility__c = null;
        ofc1.Consumed_Quantity__c = 0;
        ofc1.Consumption_End_Date__c = system.today() + 30;
        ofc1.Consumption_Start_Date__c = system.today();
        ofc1.Forecast_Quantity__c = 1234;
        ofc1.Item__c = data.itemList[0].ID;
        ofc1.Plan_Date__c = system.today() + 10 ;
        insert ofc1;
        
      
        Sales_Order__c so = new Sales_Order__c();
        so.Company__c = data.company.id;
        so.Customer__c = data.customerSoldTo.id;
        so.Ship_To__c = data.customerShipTo.Id;
        so.Payment_Term__c = data.terms.id;
        so.Required_Date__c = System.today()+ 5 ;
        insert so;
        so.Status__c = 'Open';
        update so;
        
        Sales_Order_Line__c sol = new Sales_Order_Line__c();
        sol.Product__c = data.product.Id;
        sol.Description__c = data.product.Description__c;
        sol.Company__c = data.company.id;
        sol.Sales_Order__c = so.Id;
        sol.Unit_Price__c = 10;
        sol.Quantity_Ordered__c = 100;
        sol.Ship_From_Location__c = location.Id;
        sol.Required_Date__c = System.today() + 5 ;
        
        insert sol;
        
        test.startTest();
        
        ConsumeForecastBatch batchInstance = new ConsumeForecastBatch(data.company.Id);
        List <Sales_Order_Line__c> solList = [select ID, Product__r.Item__c, Quantity_Ordered__c, Required_Date__c,Sales_Order__r.Customer__c 
                                                from Sales_Order_Line__c 
                                                where Company__c  =: data.company.id and 
                                                Quantity_Ordered__c > 0 and 
                                                Sales_Order__r.Status__c != 'Draft' and 
                                                Required_Date__c != null
                                              and Product__r.Item__c = :data.itemList[0].ID];
        
         
        
        Database.executeBatch(new ConsumeForecastBatch(data.company.Id));
        test.stopTest();
        
        system.assert(batchInstance.messages.size() == 0);
        
        ofc1 = [select ID, Consumed_Quantity__c, Consumption_End_Date__c,
                                             Consumption_Start_Date__c, Forecast_Quantity__c, Item__c 
                                             from Order_Forecast__c where
                                             id = :ofc1.id];   
           
           
        system.assertEquals(100,ofc1.Consumed_Quantity__c);   

    }
}