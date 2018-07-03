@isTest
private class RollUpSummaryUtilityTest {

 
    static testMethod void RollUpSummaryUtility_UnitTest() {
 
             TestData data = new TestData(); 
             Sales_Order_Line__c salesOrderLine1 = data.SalesOrderLines[0];
             Sales_Order_Line__c salesOrderLine2 = data.SalesOrderLines[1];
             List<sObject> SalesOrderLines = (List<Sobject>) data.SalesOrderLines;

            Sales_Order_Line__c SalesOrderLine = new Sales_Order_Line__c();
            SalesOrderLine.Product__c = data.product.Id;
            SalesOrderLine.Description__c = data.product.Description__c;
            SalesOrderLine.Company__c = data.company.id;
            SalesOrderLine.Sales_Order__c = null;
            SalesOrderLine.Quantity_Ordered__c = 100;
            SalesOrderLine.Required_Date__c = System.today()+5;
            SalesOrderLine.Weight_UOM__c = data.uomList[0].ID;
            SalesOrderLine.Discount_Percent__c = 2;
            SalesOrderLine.Ship_From_Location__c = data.location10.ID;

             
             Sales_Order__c salesorder = data.SalesOrder;

            Test.startTest();
            system.assert( salesOrderLine1.id != null , ' expected valid sales order lines');
            system.assert( salesOrderLine2.id != null , ' expected valid sales order lines');
            system.assert( salesOrderLines != null );
            
            list<RollUpSummaryUtility.fieldDefinition> fieldDefinitions = 
            new list<RollUpSummaryUtility.fieldDefinition> {
                new RollUpSummaryUtility.fieldDefinition('SUM', 'Discount_Percent__c', 'Total_Order_Volume__c')};
            
                        
            SalesOrderLines.add( SalesOrderLine);        
            RollUpSummaryUtility.rollUpTrigger(fieldDefinitions, SalesOrderLines, 'Sales_Order_Line__c', 'Sales_Order__c', 'Sales_Order__c', '');
            
            system.assertEquals( salesOrderLine1.Discount_Percent__c, 2);
            system.assertEquals( salesOrderLine2.Discount_Percent__c, 2);

            salesOrder = [Select Total_Order_Volume__c From Sales_Order__c where id=:salesOrder.id limit 1];
                    
            system.assertEquals( salesOrder.Total_Order_Volume__c, 4);

 
    }
 
}