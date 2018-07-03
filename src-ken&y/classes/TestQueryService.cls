@isTest
public class TestQueryService {
    
    public enum matchMethod {EQ, STARTSWITH, ENDSWITH}

    
    /*
    * These queries are shared between TestDataQuery and TestFuelQuery.  I noticed a lot of dupes so I just consolidated to one place.
    */
    public static String getQuery(string sObjListName) {
        Map<String, String> queryMap = new Map<String, String>();
        
        //Add as many queries as you wish here
        queryMap.put('accountingStandardList', 'Select Id, Name From Accounting_Standard__c ');
        queryMap.put('agreementList',     'SELECT Id, Name, Activation_Date__c from Agreement__c ORDER BY Id');        
        queryMap.put('agreementLineList',     'SELECT Id, Name, Description__c, Occurrence__c, Rate_Basis__c from Agreement_Line__c ORDER BY Id');        

        queryMap.put('currencyList',    'SELECT Id, Name, ISO_Code__c, Currency__c FROM Currency__c ORDER BY Id');           
        
        queryMap.put('companyList',     'SELECT Id, Name, Company_Identifier__c, Serial_Control__c, C_Days__c,Default_Transaction_Currency__c, Comp_Currency__c, Comp_Currency__r.ISO_Code__c, Stat_Currency__c, Subs_Currency__c, Consol_Currency__c FROM Company__c ORDER BY Id');        
        queryMap.put('customerList',    'SELECT Id, Name, Parent_Customer__c, recordTypeId, Company__c, Currency__c, Address__c, Customer_Identifier__c, Status__c FROM Customer__c ORDER BY Id');           
        queryMap.put('supplierList',    'SELECT Id, Name, Alternate_Name__c,fob_term__c, Company__c, Tax_ID__c, Status__c, Payment_Term__c, Type__c, RecordTypeId FROM Supplier__c ORDER BY Id');
        queryMap.put('productList',     'SELECT Id, Name, company__c, UPC_Code__c, Weight__c, Weight_UOM__c, Description__c, Item__c, Item__r.Non_Shippable__c, Product_Group__c, ' + 
                                        'Dimension_UOM__c, Selling_UOM__c, Item__r.Packaging_UOM__c FROM Product__c ORDER BY Id');
        queryMap.put('facilityList',    'SELECT Id, Name, Default_Sales_Order_Ship_From_Location__c, company__c, Primary_Key__c, Facility_IDentifier__c FROM Facility__c ORDER BY Id');
        queryMap.put('binList',         'SELECT Id, Name, Description__c, Location__c, Max_Capacity__c, Packaging_UOM__c FROM Bin__c ORDER BY Id');
        queryMap.put('packageClassList','SELECT Id, Name, Parent_Package_Class__c, Fractional_Quantities_Allowed__c, Level__c, Default_Container_Item__c FROM Package_Class__c ORDER BY Id');
        queryMap.put('uomcList',        'SELECT Id, Name, uom_1__c, Item__c, uom_1_Quantity__c, uom_2__c, uom_2_Quantity__c, Key_1__c, Key_2__c, Facility_Identifier__c FROM UOM_Conversion_Details__c ORDER BY Id');
	    queryMap.put('pricebookList',   'SELECT Id, name, Currency__c, Primary_Key__c, Company__c FROM Pricebook__c ORDER BY Id');
		queryMap.put('pricebookLineList',   'SELECT Id, Product__c, Pricebook__c, Pricing_UOM__c, price__c, Start_Date__c, End_Date__c, Price_Type__c, Pricebook__r.Primary_Key__c FROM Pricebook_Line__c');
        queryMap.put('skidList',        'SELECT Id, location__c, Company__c, Quantity__c,Quantity_Stocking_UOM__c, Packaging_UOM__c, Stocking_UOM__c, Item__c, Type__c, Expiration_Date__c, Container_Item__c FROM Skid__c ORDER BY Id');
        queryMap.put('smrsList',        'SELECT Id, Name, Stock_Movement_Rule_Field__c, Source_Document__c, Source_Document_Path__c, Source_Document_Path_Putaway__c FROM Stock_Movement_Rule_Settings__c ORDER BY Id');
        queryMap.put('smrList',         'SELECT Id, Name, Rule_Type__c, Company__c, Facility__c, Class__c, Item__c, Customer__c, Source_Document__c, Priority__c, Location_List__c, Active__c ' + 
                                        'from Stock_Movement_Rule__c ORDER BY Id');
         queryMap.put('polList',         'SELECT Id, Name, Description__c, Order_Quantity__c, Purchase_Order__c,Unit_Price__c, Item__c, Purchase_UOM__c,Company__c, Item__r.Packaging_UOM__c, Item__r.Stocking_UOM__c, ' +
        									' Need_Date__c,Delivery_Facility__c, Delivery_Facility__r.Facility_IDentifier__c, Delivery_Location__c, Supplier__c, Line__c, Quantity_Matched__c, Amount_Matched__c FROM Purchase_Order_Line__c ORDER BY Id');

        queryMap.put('classList',       'SELECT Id, Name, Inventory_GL_Account__c, Description__c, Type__c, Revenue_GL_Account__c, class_unique__c FROM Class__c ORDER BY Id');

        queryMap.put('accountList',     'SELECT Id, Name, phone, fax FROM Account ORDER BY Id');        
        queryMap.put('locationList',    'SELECT Id, Name, Facility__c, Bin_Tracked__c, Nettable__c, Facility__r.Name, facility__r.company__c, Facility__r.Facility_IDentifier__c, Primary_Key__c, Description__c FROM Location__c ORDER BY Id');

        queryMap.put('itemAttrList',    'SELECT Id, Name, Serial_Number__c, Rental__c, Used__c, Date_Received__c, Lot_Number__c, Expiration_Date__c, Minimum_Shelf_Life_In_Days__c, License_Plate_Number__c FROM Item_Attribute__c ORDER BY Id');      
        queryMap.put('invoiceList',     'SELECT Id, Name, Type__c,From_Company__c,To_Company__c,Currency__c,Transaction_Date__c,Transaction_Type__c FROM Invoice__c ORDER BY Id');  

        queryMap.put('uomList',         'SELECT Id, Name, Package_Class__c, Package_Class__r.Level__c, Type__c, Every__c, Recurrence__c, Description__c FROM UOM__c ORDER BY Id');
        queryMap.put('bankTransactionList','Select Id, Name, Bank_Account__c, Currency__c,Company__c,Transaction_Type__c,Reference_Number__c,Source__c,Transacted_With__c ,Transaction_Date__c,Payment_Method__c,SubTransaction_Type__c FROM Bank_Transaction__c ORDER BY Id');
        queryMap.put('customerReceiptList','Select Id, Name,Amount_Received__c, Balance__c,' +
                                       'Amount_Unapplied__c,Payment_Method_G__c, ' +
                                       'Company__c,Customer__c,Date_Received__c,Currency__c, ' +
                                       'exception__c,Reference_Number__c,Bank_Account_2__c, ' +
                                       'Type__c ,transaction_date__c FROM Customer_Receipt__c ORDER BY Id');
        queryMap.put('customerReceiptLineList','Select Id, Name,Amount__c,Customer_Receipt__c,Type__c FROM Customer_Receipt_Line__c ORDER BY Id');
        queryMap.put('accountingEntryList','Select Id, Name,Company__c,Customer_Receipt__c,Status__c,Transaction_Type__c FROM Accounting_Entry__c ORDER BY Id');
        queryMap.put('journalEntryLineList','Select Id, Name,Journal_Entry__c,Amount_CR__c,GL_Account__c,Bank_Transaction__c,Subtransaction_Type__c FROM Journal_Entry_Line__c ORDER BY Id');
        queryMap.put('JEAccountingEntryLineList', 'Select Id, Name,Amount_CR__c,Amount_DR__c,GL_Account__c,Transaction_Date__c,Accounting_Entry__c,Journal_Entry_Line__c,Company__c FROM Accounting_Entry_Line__c Order by Id');
        queryMap.put('AccountingRuleList', 'Select Id, Name, Object_Name__c,Transaction__c,SubTransaction_Type__c ,Line_Type__c,Rule_Type__c,Default_GL_Account__c,GL_Account_Reference_Value__c,GL_Account__c,Amount_Reference__c,Company_Ledger__c FROM Accounting_Rule__c Order by Id');

        queryMap.put('glList',          'SELECT Id, Name FROM GL_Account__c ORDER BY Id');      
        queryMap.put('soList',          'SELECT Id, Name, Original_Sales_Order__c, Pricebook__c, Total_Weight__c, Allowances__c, company__c, Customer__c, Order_Total__c, Customer__r.Top_Parent_Customer__c, ' +
                                        'Total_Quantity_Shipped__c, Total_Quantity_Ordered__c, Subtotal__c, Status__c, Ship_Complete__c, Quote__c, Primary_Contact__c, Payment_Term__c, Bill_to__c, Ship_to__c,' +
                                        'Open_Sales_Order_Lines__c, Required_Date__c, Date_Time_Ordered__c, Ship_From_Location__c, Customer_Purchase_Order__c, Backorder_Value__c, ' +
                                        '(SELECT Id, Name, Product__c, Pricebook__c, Product__r.Sales_Hierarchy__c, Product__r.Product_Group__c, Sales_Order__c, Backorder_Value__c,  ' +
                                        'Company__c, Description__c, Discount_Percent__c, Extended_Price__c, Line__c, Quantity_Backordered__c, Quantity_Ordered__c, ' +
                                        'Weight_UOM__c, Dimension_UOM__c, Product__r.Weight_UOM__c, Product__r.Dimension_UOM__c, Ship_From_Location__c, Memo__c, ' +
                                        'Quantity_Shipped__c, Required_Date__c, Status__c, Unit_Price__c, Accounting_Segment__c, Accounting_Segment__r.GL_Account__c,Product__r.Item__r.Purchasing_UOM__c ' + 
                                        'FROM Sales_Order_Lines__r) FROM Sales_Order__c ORDER BY Id');
        queryMap.put('solList',         'SELECT Id, Name, Sales_Order__c, Pricebook__c, Sales_Order__r.Original_Sales_Order__c, Quantity_Ordered__c, Quantity_Shipped__c, Unit_Price__c, Discount_Percent__c, Product__r.Item__r.Packaging_UOM__c, Product__r.Item__c, ' +
                                        'Memo__c, Accounting_Segment__c, Product__c FROM Sales_Order_Line__c ORDER BY Id');
        queryMap.put('poList',          'SELECT Id, Name, status__c, Supplier__c, Company__c, Currency__c, Payment_Term__c, Delivery_Facility__c, Delivery_Facility__r.Facility_IDentifier__c, Delivery_Location__c, Remit_To_Supplier__c, Memo__c, ' +
                                        '(SELECT Id, Name, Line__c, Purchase_Order__c, Order_Quantity__c, Unit_Price__c, Item__c, Status__c, Need_Date__c, Company__c, Delivery_Location__c, Delivery_facility__c, ' + 
                                        'Supplier__c FROM Purchase_Order_Lines__r) ' +
                                        'FROM Purchase_Order__c ORDER BY Id');

        queryMap.put('glTypeList',      'SELECT Id, Name, Normal_Balance__c, Accounting_Type__c, Statement_Type__c, Account_Range_From__c, Account_Range_To__c, Primary_Key__c FROM GL_Type__c ORDER BY Id');
        queryMap.put('glAccountList',   'SELECT Id, Name, GL_Account_Number__c, GL_Account_Name__c, GL_Type_Code__c, Active__c, FX_Type__c FROM GL_Account__c ORDER BY Id');
        queryMap.put('stockMoveList',   'SELECT Id, Name, Rule_Type__c, Company__c, Facility__c, Class__c, Item__c, Customer__c, Source_Document__c, Priority__c, Location_List__c, Active__c ' + 
                                        'FROM Stock_Movement_Rule__c ORDER BY Id');
        queryMap.put('itemList',        'SELECT Id, Name, Description__c, source__c, Class__c, Lead_Time__c, active__c, Supplier__c, company__c, Purchasing_UOM__c, Stocking_UOM__c, Weight__c, Packaging_UOM__c,'+ 
                                        'Item_Attribute__c, Non_Inventory__c FROM Item__c ORDER BY Id');
        queryMap.put('hierarchyList',   'SELECT Code__c, Primary_Key__c, Type__c, Parent_Code__c, Level__c from Hierarchy__c ORDER BY Id');
        queryMap.put('customerGroupList', 'SELECT id, Name from Customer_Group__c ORDER BY Id');
        queryMap.put('resonCodeList', 'SELECT id, Name, Type__c, Company__c from Reason_Code__c ORDER BY Id');
        queryMap.put('crossReferenceList', 'SELECT id, Name  from Cross_Reference__c ORDER BY Id');
        queryMap.put('contractList', 'select id, name, Contract_Start__c, Approval_Status__c, Status__c, ExtId__c from Contract__c ORDER BY Id');
        queryMap.put('contractLineList', 'select id, name, Type__c, Negotiated_Price__c, Minimum_Order_Quantity__c, Line__c, ExtId__c, Status__c, Quantity_Received__c,PurchasedValue__c, Approved__c from Contract_Line__c ORDER BY Id');

        if (queryMap.containsKey(sObjListName)) {
            return queryMap.get(sObjListName);
        } else {
            throw new testQueryException(sObjListName + ' not found in map.');  
        }
    }

    //takes in a map of all the lists of sObjects, if the list we want isn't in the map, query for it.  Add to the map by reference.
    //return the complete list of sObjects
    public static List<sObject> getSobjList(Map<String, List<sObject>> sObjListMap, String sObjListName) {
        if (!sObjListMap.containsKey(sObjListName)) {
            sObjListMap.put(sObjListName, Database.query(getQuery(sObjListName)));  
        }
        return sObjListMap.get(sObjListName);
    }
    
    //takes in a map of all the lists of sObjects, if the list we want isn't in the map, query for it.  Add to the map by reference.
    //return the list of sObjects filtered by the match criteria    
    public static List<sObject> getSobjListFromVal(Map<String, List<sObject>> sObjListMap, String sObjListName, String matchField, matchMethod mm, String matchVal) {
        List<sObject> sObjListFiltered = new List<sObject>();
        for (sObject sObj: getSobjList(sObjListMap, sObjListName)) {
            if (checkMatch(sObj, matchField, mm, matchVal)) {
                sObjListFiltered.add(sObj); 
            }       
        }       
        return sObjListFiltered;
    }   
    
    //takes in a map of all the lists of sObjects, if the list we want isn't in the map, query for it.  Add to the map by reference.
    //find the single sObject we want by in the list by matching on some criteria and return it. 
    public static sObject getSobjFromVal(Map<String, List<sObject>> sObjListMap, sObject sObjIn, String sObjListName, String matchField, matchMethod mm, String matchVal) {
        if (sObjIn != null) {
            return sObjIn;
        }

        sObject retObj;
        
        if (!sObjListMap.containsKey(sObjListName)) {
            sObjListMap.put(sObjListName, Database.query(getQuery(sObjListName)));  
        }
        
        if (sObjListMap.containsKey(sObjListName)) {
            List<sObject> sobjList = sObjListMap.get(sObjListName);
            Set<sObject> matchedObjSet = new Set<sObject>();
            for (sObject sObj: sobjList) {
                if (checkMatch(sObj, matchField, mm, matchVal)) {
                    matchedObjSet.add(sObj);    
                }
            }
            if (matchedObjSet.size() == 0) {
                throw new testQueryException('No records found for: ' + sObjListName + ', ' +  matchField + ', ' + matchVal); 
            }
            if (matchedObjSet.size() > 1) {
                throw new testQueryException('More than one matching record found for: ' + sObjListName + ', ' +  matchField + ', ' + matchVal + '.  ' + JSON.serialize(matchedObjSet));  
            }           
            if (matchedObjSet.size() == 1) {
                for (sObject s: matchedObjSet) {
                    retObj = s; 
                }
            }    
        } else {
            throw new testQueryException('Object not in Map: ' + sObjListName + ', ' +  matchField + ', ' + matchVal);
        }
        
        if (retObj == null) {
            throw new testQueryException('Object not found: ' + sObjListName + ', ' +  matchField + ', ' + matchVal);
        }
        
        return retObj;
    }    

    public static Boolean checkMatch(sObject sObj, String matchField, matchMethod mm, String matchVal) {
        Boolean matched = false;
        String fieldVal = (String)sObj.get(matchField);
        if (fieldVal == null) {
            return false;
        }
        if (mm == matchMethod.EQ) {
            if (fieldVal == matchVal) {
                matched = true;
            }
        }
        if (mm == matchMethod.ENDSWITH) {
            if (fieldVal.endsWith(matchVal)) {
                matched = true; 
            }
        }               
        if (mm == matchMethod.STARTSWITH) {
            if (fieldVal.startsWith(matchVal)) {
                matched = true; 
            }
        }   
        return matched;
    }

    

    public static Item_Specification__c getItemSpec(String revision) {
        SOQLUtil itemSpecQuery = new SOQLUtil('Item_Specification__c');
        itemSpecQuery.addAllCustomFields();
        itemSpecQuery.setWhereClause('Revision__c = \'' + revision + '\'');

        SOQLUtil.ChildRelationship componentQuery = new SOQLUtil.ChildRelationship(itemSpecQuery,'Components__r');
        componentQuery.addAllCustomFields();
        componentQuery.setOrderByClause('Component_Sequence__c ASC');
        itemSpecQuery.addChildRelationship(componentQuery);

        SOQLUtil.ChildRelationship routingQuery = new SOQLUtil.ChildRelationship(itemSpecQuery,'Routings__r');
        routingQuery.addAllCustomFields();
        routingQuery.setOrderByClause('Resource_Sequence__c ASC');
        itemSpecQuery.addChildRelationship(routingQuery);

        return Database.query(itemSpecQuery.getQuery());
    }

    public static Work_Order__c getWorkOrder(String notes) {
        SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
        woQuery.addAllCustomFields();
        woQuery.setWhereClause('Notes__c = \'' + notes + '\'');
        return Database.query(woQuery.getQuery());
    }

    public class TestQueryException extends Exception { }
}