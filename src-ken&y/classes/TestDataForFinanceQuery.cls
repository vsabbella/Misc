@isTest
public class TestDataForFinanceQuery {

/*
 * This class is used in conjunction with TestDataForFinance to provide a simple way to 
 * create data in a test class using @testSetup notation, and then to query 
 * that same data in individual test methods without re-creating the data that TestDataForFinance generates 
 * To make this work, the queries here should look for identifying information that 
 * is created by TestDataForFinance, so these two files should be complementary and a change in TestDataForFinance
 * may require a change in this file.  There is a lazy-load, bulkified pattern in place to query the 
 * data based on that identifying information, making sure only 1 match exists.
*/ 
	
	//this holds all the lazy loaded lists of sObjects we query with TestQueryService
	Map<String, List<sObject>> sObjListMap = new Map<String, List<sObject>>();
	
    
    public Company__c company {
        get {return (Company__c)TestQueryService.getSobjFromVal(sObjListMap, company, 'companyList', 'Name', TestQueryService.matchMethod.EQ, '100');}
        set;
    }   


	//customers
    public Customer__c customer_corp {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customer_corp, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'TestCustomer-Corporate');}
        set;
    }
    public Customer__c customer_billto {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customer_billto, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'TestCustomer-BillTo');}
        set;
    }    
    public Customer__c customer_billto1 {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customer_billto1, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'TestCustomer-BillTo1');}
        set;
    }    
    public Customer__c customer_billto2 {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customer_billto2, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'TestCustomer-BillTo2');}
        set;
    } 
    public Customer__c customer_billto3 {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customer_billto3, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'TestCustomer-BillTo3');}
        set;
    }    
    public Customer__c customer1 {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customer1, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'TestCustomer1');}
        set;
    }    
    public Customer__c customer2 {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customer2, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'TestCustomer2');}
        set;
    }        
    public Customer__c customer3 {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customer3, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'TestCustomer3');}
        set;
    }    
    public Customer__c customer_shipto {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customer_shipto, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'TestCustomer-ShipTo');}
        set;
    }    
    public Customer__c customer_shipto1 {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customer_shipto1, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'TestCustomer-ShipTo1');}
        set;
    } 
    public Customer__c customer_shipto2 {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customer_shipto2, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'TestCustomer-ShipTo2');}
        set;
    }    

	
	//SOs
    public Sales_Order__c salesOrder1  {
		get {return (Sales_Order__c)TestQueryService.getSobjFromVal(sObjListMap, salesOrder1, 'soList', 'Original_Sales_Order__c', TestQueryService.matchMethod.EQ, 'salesOrder1');}
    	set;  
    }  
    public Sales_Order__c salesOrder2  {
		get {return (Sales_Order__c)TestQueryService.getSobjFromVal(sObjListMap, salesOrder2, 'soList', 'Original_Sales_Order__c', TestQueryService.matchMethod.EQ, 'salesOrder2');}
    	set;  
    }  
    public Sales_Order__c salesOrder3  {
		get {return (Sales_Order__c)TestQueryService.getSobjFromVal(sObjListMap, salesOrder3, 'soList', 'Original_Sales_Order__c', TestQueryService.matchMethod.EQ, 'salesOrder3');}
    	set;  
    }      
    
    
    public List<Sales_Order_Line__c> SalesOrderLineList {
        get {return (List<Sales_Order_Line__c>)TestQueryService.getSobjList(sObjListMap, 'solList');}
        set;
    }    


    //POs
    public Purchase_Order__c purchaseOrder1 {
    	get {return (Purchase_Order__c)TestQueryService.getSobjFromVal(sObjListMap, purchaseOrder1, 'poList', 'Memo__c', TestQueryService.matchMethod.EQ, 'purchaseOrder1');}        	
        set;
    }   


    //products
    public Product__c product {
        get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, product, 'productList', 'Name', TestQueryService.matchMethod.EQ, 'Test Product');}        
        set;
    }


	//GLs
    public GL_Account__c revenueGL { 
    	get {return (GL_Account__c)TestQueryService.getSobjFromVal(sObjListMap, revenueGL, 'glList', 'Name', TestQueryService.matchMethod.EQ, '41000 - Revenue');}        
        set;
	}	
    public GL_Account__c receivablesGL { 
    	get {return (GL_Account__c)TestQueryService.getSobjFromVal(sObjListMap, receivablesGL, 'glList', 'Name', TestQueryService.matchMethod.EQ, '11000 - Accounts Receivable');}        
        set;
	}

    public GL_Account__c inventoryGL {
        get {
            return (GL_Account__c)TestQueryService.getSobjFromVal(sObjListMap,inventoryGL,'glList','Name',TestQueryService.matchMethod.EQ,'42000 - Revenue');
        } set;
    }
    
    public Facility__c facility {
        get {
            if (facility == null) {
                SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
                facilityQuery.addAllCustomFields();
                facilityQuery.setWhereClause('Name = \'Test Facility\'');
                facility = Database.query(facilityQuery.getQuery());
            }
            return facility;
        } set;
    }

    public Location__c location {
        get {
            if (location == null) {
                SOQLUtil locationQuery = new SOQLUtil('Location__c');
                locationQuery.addAllCustomFields();
                locationQuery.addAllCustomFields(Facility__c.sObjectType,'Facility__r');
                locationQuery.setWhereClause('Name = \'Test Location\'');
                location = Database.query(locationQuery.getQuery());

                facility = location.Facility__r;
                location.Facility__r = null;
            }
            return location;
        } set;
    }

    public List<Item__c> itemList  {
        get {
            if (itemList == null) {
                SOQLUtil itemQuery = new SOQLUtil('Item__c');
                itemQuery.addAllCustomFields();
                itemQuery.setOrderByClause('Id ASC');
                itemList = Database.query(itemQuery.getQuery());
            }
            return itemList;
        } set;
    }
}