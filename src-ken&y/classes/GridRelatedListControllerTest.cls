/*
*   Test methods for GridRelatedListController
*/
@isTest
public with sharing class GridRelatedListControllerTest {
    static TestData globalTestData = new TestData();
    
    static testMethod void testGetFieldList() {
        // Arrange
        GridRelatedListController con = new GridRelatedListController();
        con.config = getGridRelatedListConfig();
        
        // Act
        string result = con.getFieldList();
        
        // Assert
        System.assertEquals(result, con.fieldList);
    }
    
    static testMethod void testGetChildMap(){
       Set<String> masterDetailChildren = new Set<String> { 'Customer_Invoice_Line__c'};
       Customer_Invoice__c parentRecord = getCustomerInvoice();
       Map<String,String> childMap = GridRelatedListController.childObjectMap(parentRecord);
       system.assertEquals(childMap.size(), masterDetailChildren.size());
       for(String type : childMap.keyset()) {
            system.assertEquals(childMap.get(type), 'Customer_Invoice__c', '>>> childMap: ' + childMap);
            system.assert(masterDetailChildren.contains(type), '>>> childMap: ' + childMap);
       }
    }
    
    
    static testMethod void testGetConfigJson() {
        // Arrange
        GridRelatedListController con = new GridRelatedListController();
        con.config = getGridRelatedListConfig();
        
        // Act
        string result = con.getConfigJson();
        
        // Assert
        System.assertEquals(result, JSON.serialize(con.config));
    }
    
    static testMethod void testGetRelatedList(){
        Test.startTest();
        
        // Arrange
        Customer_Invoice__c custInvoice = getCustomerInvoice();
        
        Customer_Invoice_Line__c shipInvoiceLine = new Customer_Invoice_Line__c();
        shipInvoiceLine.Customer_Invoice__c = custInvoice.Id;
        shipInvoiceLine.Line_Type__c = null;
        shipInvoiceLine.Description__c = 'test description';
        
        insert shipInvoiceLine;
        
        GridRelatedListController.GridRelatedListConfig config = new GridRelatedListController.GridRelatedListConfig();
        config.parentRecord = custInvoice;
        config.objectName = 'Customer_Invoice_Line__c';
        config.fieldSet = 'Line_Edit';
        config.parentField = 'Customer_Invoice__c';
        config.additionalFields = 'Name';
        
        // Act
        DataSourceResult result = GridRelatedListController.getRelatedList(config);
        
        // Assert
        System.assertNotEquals(0, result.total);
        
        Test.stopTest();
    }

    // Sample class to test DataSourceResult exceptions
    class TestDataSourceResultException extends Exception{}
    // Added support for ApexPageMessages style messages to DataSourceResult class
    static testMethod void testDataSourceResultMessages()  {
        DataSourceResult dsr = new DataSourceResult();
        
        // Info message test
        String infoMsg = 'Info Message';
        dsr.addMessage(infoMsg, ApexPages.Severity.Info);
        System.assertEquals(1, dsr.messages.size()); // should be one

        Map<String, String> expectedMsg = new Map<String, String> {                                 
                'message' => infoMsg,
                'severity' => String.valueOf(ApexPages.Severity.Info)                    
            };
        System.assertEquals(expectedMsg, dsr.messages[0]);

        // Exception test
        dsr = new DataSourceResult();
        String exceptionMsg = 'Bad bad data' ;
        dsr.addMessage(new TestDataSourceResultException(exceptionMsg), ApexPages.Severity.Error);

        expectedMsg = new Map<String, String> {                                 
                'message' => exceptionMsg,
                'severity' => String.valueOf(ApexPages.Severity.Error)                    
            };
        System.assertEquals(1, dsr.messages.size()); // should be one            
        System.assertEquals(expectedMsg, dsr.messages[0]);


        // DMLException test
        dsr = new DataSourceResult();
        // Bad Pricebook line with start date after end date
        Pricebook_Line__c testPriceLine1 = new Pricebook_Line__c( pricebook__c = globalTestData.pricebook.id, 
                                            Product__c = globalTestData.product.id, Price__c = 5.000000, 
                                            Start_date__c = Date.today(), End_Date__c = Date.today() - 10);
        try {
            insert testPriceLine1;
        } catch (DmlException dmle) {
            System.debug(dmle);
            dsr.addMessage(dmle, ApexPages.Severity.Error);
            System.assertEquals(1, dsr.messages.size()); // should be one
            System.debug(dsr.messages[0]);
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', dsr.messages[0].get('code'));
        }   

    }
    
    static Customer_Invoice__c getCustomerInvoice() {
        Customer_Invoice__c custInvoice = new Customer_Invoice__c();
        custInvoice.Date_Invoiced__c = System.now();
        
        insert custInvoice;
        
        return custInvoice;
    }
    
    static GridRelatedListController.GridRelatedListConfig getGridRelatedListConfig() {
        GridRelatedListController.GridRelatedListConfig config = new GridRelatedListController.GridRelatedListConfig();
        config.parentRecord = getCustomerInvoice();
        config.objectName = 'Customer_Invoice_Line__c';
        config.fieldSet = 'Line_Edit';
        config.parentField = 'Customer_Invoice__c';
        config.additionalFields = 'Name';
        config.alwaysUseFullDateTimeFormat = true;
        return config;
    }
}