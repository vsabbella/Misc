@isTest
public class TestDataQuery {

/*
 * This class is used in conjunction with TestData to provide a simple way to 
 * create data in a test class using @testSetup notation, and then to query 
 * that same data in individual test methods without re-creating the data that TestData generates 
 * To make this work, the queries here should look for identifying information that 
 * is created by TestData, so these two files should be complementary and a change in TestData
 * may require a change in this file.  There is a lazy-load, bulkified pattern in place to query the 
 * data based on that identifying information, making sure only 1 match exists.
*/ 
	
	//this holds all the lazy loaded lists of sObjects we query with TestQueryService
	Map<String, List<sObject>> sObjListMap = new Map<String, List<sObject>>();
	
    
    public Company__c company {
        get {return (Company__c)TestQueryService.getSobjFromVal(sObjListMap, company, 'companyList', 'Company_Identifier__c', TestQueryService.matchMethod.EQ, 'KEN');}
        set;
    }   
    
	
	//suppliers
    public Supplier__c remitToSupplier { 
		get {return (Supplier__c)TestQueryService.getSobjFromVal(sObjListMap, remitToSupplier, 'supplierList', 'Alternate_Name__c', TestQueryService.matchMethod.EQ, 'Remit to Supplier');}
		set; 
    }         
    
    public Supplier__c supplier { 
		get {return (Supplier__c)TestQueryService.getSobjFromVal(sObjListMap, supplier, 'supplierList', 'Alternate_Name__c', TestQueryService.matchMethod.EQ, 'Test Supplier');}
		set; 
    } 

	//customers
    public Customer__c customerParent {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerParent, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Customer Corp Parent 1');}
        set;
    }
    
    public Customer__c customerBillTo {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerBillTo, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Customer Bill To 1');}
        set;
    }    

    public Customer__c customerSoldTo {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerSoldTo, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Customer Sold To 1');}
        set;
    }    
    
    public Customer__c customer {
		//just an alias for the sold to cust above
        get {return customerSoldTo;}
        set;
    }      

    public Customer__c customerShipTo {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerShipTo, 'customerList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Customer Ship To 1');}
        set;
    }            
    
    public Pricebook__c pricebook {
        get {return (Pricebook__c)TestQueryService.getSobjFromVal(sObjListMap, pricebook, 'pricebookList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Orange Pricebook');}
        set;
    }
    
    public Item_Attribute__c itemAttrObj{
        get {
            if( itemAttrObj == null ) {
                itemAttrObj = [ select id , name from  Item_Attribute__c where  Name = 'Attribute-1'];
            }
            return itemAttrObj;
        } 
        set;
    }
    
    
    public Item_Specification__c assembly {
    	get {return (Item_Specification__c)TestQueryService.getItemSpec('A');}
        set;      	
    }

    
    //Items
    public Item__c item1 {
    	get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item1, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-10');}
        set;      	
    }    
    public Item__c item2 {
    	get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item2, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-11');}
        set;      	
    }   
    public Item__c item3 {
    	get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item3, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-12');}
        set;      	
    }    
    public Item__c item4 {
    	get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item4, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-13');}
        set;      	
    }   
    public Item__c item5 {
    	get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item5, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-14');}
        set;      	
    }    
    public Item__c item6 {
    	get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item6, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-15');}
        set;      	
    }   
    public Item__c item7 {
    	get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item7, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-16');}
        set;      	
    }    
    public Item__c item8 {
    	get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item8, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-17');}
        set;      	
    }   
    public Item__c item9 {
    	get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item9, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-18');}
        set;      	
    }    
    public Item__c item10 {
    	get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item10, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-19');}
        set;      	
    }               
    public Item__c item11 {
    	get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, item10, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-20');}
        set;      	
    }  
    public Item__c consignedItem {
        get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, consignedItem, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Item-Consigned');}
        set;        
    }  
    public List<Item__c> itemList {
        get {return (List<Item__c>)TestQueryService.getSobjList(sObjListMap, 'itemList');}        
        set;
    }    

    //products
    public Product__c product {
        get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, product, 'productList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Product-10');}        
        set;
    }
    public Product__c product2 {
        get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, product2, 'productList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Product-15');}             
        set;
    }    

    public Product_Group__c productgroup {
        get {
            if (productgroup == null) {
                productgroup = [ select id from Product_Group__c where Name =:company.Name +' ProductGroup-1'];
            }
            return productgroup;
        }
        set;
    }    
    
    
    public Facility__c facility {
    	get {return (Facility__c)TestQueryService.getSobjFromVal(sObjListMap, facility, 'facilityList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'FA01');}
        set;
    }      
    public Facility__c facility2 {
    	get {return (Facility__c)TestQueryService.getSobjFromVal(sObjListMap, facility2, 'facilityList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'FA02');}
        set;
    }    

    
    public Work_Order__c workOrder  {
    	get {return (Work_Order__c)TestQueryService.getSobjFromVal(sObjListMap, workOrder, 'workOrderList', 'Notes__c', TestQueryService.matchMethod.EQ, 'workorder');}
        set;        
    }
    
    
    public bin__c bin1 {
    	get {return (bin__c)TestQueryService.getSobjFromVal(sObjListMap, bin1, 'binList', 'Name', TestQueryService.matchMethod.EQ, 'Stock-Bin-1');}    	
		set;
    }
    public bin__c bin3 { 		
    	get {return (bin__c)TestQueryService.getSobjFromVal(sObjListMap, bin3, 'binList', 'Name', TestQueryService.matchMethod.EQ, 'Stock-Bin-3');}    	
		set;
    }
    

    //Stock Movement Rules
    public Stock_Movement_Rule__c stockMovementRule1 {
    	get {return (Stock_Movement_Rule__c)TestQueryService.getSobjFromVal(sObjListMap, stockMovementRule1, 'stockMoveList', 'Name', TestQueryService.matchMethod.EQ, 'Putaway rule1');}    	
		set;
    }
    public Stock_Movement_Rule__c stockMovementRule2 {
    	get {return (Stock_Movement_Rule__c)TestQueryService.getSobjFromVal(sObjListMap, stockMovementRule2, 'stockMoveList', 'Name', TestQueryService.matchMethod.EQ, 'Putaway rule2');}    	
		set;
    }
    public Stock_Movement_Rule__c stockMovementRule3 {
    	get {return (Stock_Movement_Rule__c)TestQueryService.getSobjFromVal(sObjListMap, stockMovementRule3, 'stockMoveList', 'Name', TestQueryService.matchMethod.EQ, 'Pick rule1');}    	
		set;
    }
    public Stock_Movement_Rule__c stockMovementRule4 {
    	get {return (Stock_Movement_Rule__c)TestQueryService.getSobjFromVal(sObjListMap, stockMovementRule4, 'stockMoveList', 'Name', TestQueryService.matchMethod.EQ, 'Pick rule2');}    	
		set;
    }
    public Stock_Movement_Rule__c stockMovementRule5 {
    	get {return (Stock_Movement_Rule__c)TestQueryService.getSobjFromVal(sObjListMap, stockMovementRule5, 'stockMoveList', 'Name', TestQueryService.matchMethod.EQ, 'Pick rule3');}    	
		set;
    }
    public Stock_Movement_Rule__c stockMovementRule7 {
    	get {return (Stock_Movement_Rule__c)TestQueryService.getSobjFromVal(sObjListMap, stockMovementRule7, 'stockMoveList', 'Name', TestQueryService.matchMethod.EQ, 'Transfer Order Pick rule');}    	
		set;
    }
    public Stock_Movement_Rule__c stockMovementRule8 {
    	get {return (Stock_Movement_Rule__c)TestQueryService.getSobjFromVal(sObjListMap, stockMovementRule8, 'stockMoveList', 'Name', TestQueryService.matchMethod.EQ, 'Transfer Order Putaway rule');}    	
		set;
    }


    //POs
    public Purchase_Order__c purchaseOrder {
    	get {return (Purchase_Order__c)TestQueryService.getSobjFromVal(sObjListMap, purchaseOrder, 'poList', 'Memo__c', TestQueryService.matchMethod.EQ, 'PurchaseOrder');}        	
        set;
    }    	

    public Purchase_Order__c purchaseOrder2 {
    	get {return (Purchase_Order__c)TestQueryService.getSobjFromVal(sObjListMap, purchaseOrder2, 'poList', 'Memo__c', TestQueryService.matchMethod.EQ, 'PurchaseOrder2');}        	
        set;    	
    }  

    public Purchase_Order__c purchaseOrder3 {
    	get {return (Purchase_Order__c)TestQueryService.getSobjFromVal(sObjListMap, purchaseOrder3, 'poList', 'Memo__c', TestQueryService.matchMethod.EQ, 'PurchaseOrder3');}        	
        set;            
    }    	

    public Purchase_Order__c purchaseOrder4 {
    	get {return (Purchase_Order__c)TestQueryService.getSobjFromVal(sObjListMap, purchaseOrder4, 'poList', 'Memo__c', TestQueryService.matchMethod.EQ, 'PurchaseOrder4');}        	
        set;  
    }  

    public Purchase_Order__c purchaseOrder5 {
        get {return (Purchase_Order__c)TestQueryService.getSobjFromVal(sObjListMap, purchaseOrder5, 'poList', 'Memo__c', TestQueryService.matchMethod.EQ, 'PurchaseOrder5');}           
        set;  
    }
    
	//classes
    public Class__c clsObj {
    	get {return (Class__c)TestQueryService.getSobjFromVal(sObjListMap, clsObj, 'classList', 'Name', TestQueryService.matchMethod.EQ, 'Class-1');}    
        set;
    }  
    public Class__c c2 {
    	get {return (Class__c)TestQueryService.getSobjFromVal(sObjListMap, c2, 'classList', 'Name', TestQueryService.matchMethod.EQ, 'Class Labor');}
    	set;    
    }  
    public Class__c c3 {
    	get {return (Class__c)TestQueryService.getSobjFromVal(sObjListMap, c3, 'classList', 'Name', TestQueryService.matchMethod.EQ, 'Class Services');}
    	set;       	
    }      
    public Class__c c4 {
    	get {return (Class__c)TestQueryService.getSobjFromVal(sObjListMap, c4, 'classList', 'Name', TestQueryService.matchMethod.EQ, 'Class Miscellaneous');}
    	set;        
    }   

    
    public Sales_Order__c salesOrder  {
		get {return (Sales_Order__c)TestQueryService.getSobjFromVal(sObjListMap, salesOrder, 'soList', 'Original_Sales_Order__c', TestQueryService.matchMethod.EQ, 'so123');}
    	set;  
    }    
    
    

    public List <Sales_Order_Line__c> SalesOrderLines  {
        get {
            if (SalesOrderLines== null ) {                
                SalesOrderLines = [	select id, Product__c, Company__c, Sales_Order__c, Quantity_Ordered__c, Required_Date__c, Weight_UOM__c,
                					Product__r.Product_Group__c
                					from Sales_Order_Line__c where Sales_Order__r.Name = 'so123'];
            }
            return SalesOrderLines;
        } set;
    }   
    

	//accounts
    public Account billtoaccount  {
    	get {return (Account)TestQueryService.getSobjFromVal(sObjListMap, billtoaccount, 'accountList', 'Name', TestQueryService.matchMethod.EQ, 'Bill-to Account');}
    	set;     	
    }    
    public Account shiptoaccount  {
    	get {return (Account)TestQueryService.getSobjFromVal(sObjListMap, shiptoaccount, 'accountList', 'Name', TestQueryService.matchMethod.EQ, 'Ship-to Account');}
    	set;      	
    }    
    public Account soldtoaccount  {
    	get {return (Account)TestQueryService.getSobjFromVal(sObjListMap, soldtoaccount, 'accountList', 'Name', TestQueryService.matchMethod.EQ, 'Sold-to Account');}
    	set;      	
    }    


    public Payment_Term__c terms  {
        get {
            if (terms== null ) {                
                terms = [select id from Payment_Term__c where Name=:'2/10 Net 30'];
            }
            return terms;
        } set;
    }    
         
         
    public List<UOM__c> uomList  {
        get {
            if (uomList== null ) {                
                uomList = [select id, Name, Description__c from UOM__c];
            }
            return uomList;
        } set;
    }

    //locations
    public Location__c location {
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location, 'locationList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'loc');}        
        set;
    }    
    public Location__c location1 {
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location1, 'locationList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'loc1');}        
        set;
    }
    public Location__c location2 {
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location2, 'locationList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'loc2');}        
        set;    	
    }
    public Location__c location3 {
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location3, 'locationList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'loc3');}        
        set;           
    }
    public Location__c location4 {
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location4, 'locationList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'loc4');}        
        set;  
    }
    public Location__c location5 {
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location5, 'locationList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'loc5');}        
        set;  
    }
    public Location__c location6 {
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location6, 'locationList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'loc6');}        
        set;  
    }
    public Location__c location7 {
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location7, 'locationList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'loc7');}        
        set;      	
    }
    public Location__c location8 {
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location8, 'locationList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'loc8');}        
        set;      
    }                            
    public Location__c location9 {
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location9, 'locationList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'loc9');}        
        set;     	
    }
    public Location__c location10 {
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location10, 'locationList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'loc10');}        
        set;     	
    }        
    
    
    public List<Period__c> periodList  {
        get {
            if (periodList== null ) {                
                periodList = [select id from Period__c];
            }
            return periodList;
        } set;
    }   



    //Create a map between the Record Type Name and Id for easy retrieval
    public Map<String,String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
    public Map<String,String> SupplierRecordTypes = KSE.RecordTypeDevNameMap('Supplier__c');
    

}