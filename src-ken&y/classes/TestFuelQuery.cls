@isTest
public class TestFuelQuery {

/*
 * This class is used in conjunction with TestFuel to provide a simple way to 
 * create data in a test class using @testSetup notation, and then to query 
 * that same data in individual test methods without re-creating the data that TestFuel generates 
 * To make this work, the queries here should look for identifying information that 
 * is created by TestFuel, so these two files should be complementary and a change in Fuel
 * may require a change in this file.  There is a lazy-load, bulkified pattern in place to query the 
 * data based on that identifying information, making sure only 1 match exists.
*/ 
	 
	//this holds all the lazy loaded lists of sObjects we query with TestQueryService
	Map<String, List<sObject>> sObjListMap = new Map<String, List<sObject>>();	
	SchemaUtil util = SchemaUtil.getInstance(); 

    public Accounting_Standard__c accountingStandard {
        get {return (Accounting_Standard__c)TestQueryService.getSobjFromVal(sObjListMap, accountingStandard, 'accountingStandardList', 'Name', TestQueryService.matchMethod.EQ, 'US GAAP');}        
        set;
    }
    
    public Account account {
        get {return (Account)TestQueryService.getSobjFromVal(sObjListMap, account, 'accountList', 'Name', TestQueryService.matchMethod.STARTSWITH, 'KenandyTestFuel');}        
        set;
    }
    
    public Company__c company {
		get {
			return (Company__c) TestQueryService.getSobjFromVal(sObjListMap, company, 'companyList', 'Name', TestQueryService.matchMethod.STARTSWITH, 'Kenandy');
		}
        set;
    }
    
    public Company__c altCompany {
        get {return (Company__c)TestQueryService.getSobjFromVal(sObjListMap, altCompany, 'companyList', 'Name', TestQueryService.matchMethod.STARTSWITH, 'AltKenandyTestFuel');}
        set;
    }
    
    public Item_Attribute__c itemAttrObj{
    	get {return (Item_Attribute__c)TestQueryService.getSobjFromVal(sObjListMap, itemAttrObj, 'itemAttrList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Attribute-1');}
        set;           
    }
    
    public Item_Attribute__c itemAttrObj2{
    	get {return (Item_Attribute__c)TestQueryService.getSobjFromVal(sObjListMap, itemAttrObj2, 'itemAttrList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Attribute-2');}
        set;           
    }

    public Item_Attribute__c lpnAttribute{
        get {return (Item_Attribute__c)TestQueryService.getSobjFromVal(sObjListMap, lpnAttribute, 'itemAttrList', 'Name', TestQueryService.matchMethod.EQ, 'LPN');}
        set;
    }
   
    //Currnecy
    public Currency__c currencyUSD {
        get {return (Currency__c)TestQueryService.getSobjFromVal(sObjListMap, currencyUSD, 'currencyList', 'ISO_Code__c', TestQueryService.matchMethod.EQ, 'USD');}
        set;
    }

    public Currency__c currencyGBP {
        get {return (Currency__c)TestQueryService.getSobjFromVal(sObjListMap, null, 'currencyList', 'ISO_Code__c', TestQueryService.matchMethod.EQ, 'GBP');}
        set;
    }

	//UOMs
    public UOM__c uomObj {
    	get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, uomObj, 'uomList', 'Name', TestQueryService.matchMethod.EQ, 'EA');}
        set;          
    }
    
    public UOM__c uomInch {
    	get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, uomInch, 'uomList', 'Name', TestQueryService.matchMethod.EQ, 'IN');}
        set;   
    }
    
    public UOM__c uomPallet {
    	get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, uomPallet, 'uomList', 'Name', TestQueryService.matchMethod.EQ, 'PT');}
        set;   
    }
    
    public UOM__c RentalMonth {
    	get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, null, 'uomList', 'Name', TestQueryService.matchMethod.EQ, 'Rental Month');}
        set;   
    }
    public UOM__c CalendarMonth {
        get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, null, 'uomList', 'Name', TestQueryService.matchMethod.EQ, 'Calendar Month');}
        set;   
    }
    public UOM__c CalendarQuarter {
        get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, null, 'uomList', 'Name', TestQueryService.matchMethod.EQ, 'Calendar Quarter');}
        set;   
    }
    public UOM__c Week{
        get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, null, 'uomList', 'Name', TestQueryService.matchMethod.EQ, 'Week');}
        set;   
    }
    public List<UOM_Conversion_Details__c> uomcList{
        get {return (List<UOM_Conversion_Details__c>)TestQueryService.getSobjList(sObjListMap, 'uomcList');}
        set;
    }
    public List<UOM__c> uomList {
        get {return (List<UOM__c>)TestQueryService.getSobjList(sObjListMap, 'uomList');}
        set;
    }
    
    public List<Package_Class__c> packageClassList {
        get {return (List<Package_Class__c>)TestQueryService.getSobjList(sObjListMap, 'packageClassList');}
        set;
    }

    public list<Bank_Transaction__c> bankTransactionList {
        get {return (list<Bank_Transaction__c>)TestQueryService.getSobjList(sObjListMap, 'bankTransactionList');}
        set;
    }
    
    public list<Customer_Receipt__c> customerReceiptList {
        get {return (list<Customer_Receipt__c>)TestQueryService.getSobjList(sObjListMap, 'customerReceiptList');}
        set;
    }
    public list<Customer_Receipt_Line__c> customerReceiptLineList {
        get {return (list<Customer_Receipt_Line__c>)TestQueryService.getSobjList(sObjListMap, 'customerReceiptLineList');}
        set;
    }
    public list<Journal_Entry_Line__c> journalEntryLineList {
        get {return (list<Journal_Entry_Line__c>)TestQueryService.getSobjList(sObjListMap, 'journalEntryLineList');}
        set;
    }
    public list<Accounting_Entry__c> accountingEntryList {
        get {return (list<Accounting_Entry__c>)TestQueryService.getSobjList(sObjListMap, 'accountingEntryList');}
        set;
    }
    public list<Accounting_Entry_Line__c> JEAccountingEntryLineList {
        get {return (list<Accounting_Entry_Line__c>)TestQueryService.getSobjList(sObjListMap, 'JEAccountingEntryLineList');}
        set;
    }
    
    public list<Accounting_Rule__c> AccountingRuleList {
        get {return (list<Accounting_Rule__c>)TestQueryService.getSobjList(sObjListMap, 'AccountingRuleList');}
        set;
    }
    
    public List<Stock_Movement_Rule_Settings__c> smrsList {
        get {return (List<Stock_Movement_Rule_Settings__c>)TestQueryService.getSobjList(sObjListMap, 'smrsList');}
        set;
    }
    /*
    public List<UOM_Conversion__c> uomcList {
        get {
            if (uomcList == null) {
                uomcList = [ select id from UOM_Conversion__c];
            }
            return uomcList;
        } 
        set;
    }    
    */

    public List<Item_Cost__c> costList {
    	get{
    		if(costList == null) {
    			costList = [ select id,Item__c, Facility__c, Company__c, status__c, On_Hand_Revaluation__c, Start_Date__c, Invalid_Flag__c from Item_Cost__c];	    		
    		}
    		return costList;
    	}
    	set;
    }
       
    
    public List<Work_Center_Resource__c> wcResources {
    	get{
    		if(wcResources == null) {
    			wcResources = [ select id,Work_Center__c from Work_Center_Resource__c];	    		
    		}
    		return wcResources;
    	}
    	set;
    }
    
       
    public Payment_Term__c terms {
        get {
            if (terms == null) {
                terms = [ select id from  Payment_Term__c 
						where  name = '2/10 Net 30'];
            }
            return terms;
        } 
        set;
    }    
   
   
    //products
    public Product__c product {
        get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, product, 'productList', 'Name', TestQueryService.matchMethod.EQ, 'Product 1');}        
        set;        
    }
    
    public Product__c product2 {
        get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, product2, 'productList', 'Name', TestQueryService.matchMethod.EQ, 'Product-15');}        
        set;        
    }    

    public Product__c product3 {
        get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, product3, 'productList', 'Name', TestQueryService.matchMethod.ENDSWITH, 'Product-25');}
        set;
    }

    public Product__c product_Misc {
        get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, product_Misc, 'productList', 'Name', TestQueryService.matchMethod.EQ, 'Product-Misc');}        
        set;                
    }        

    public Pricebook__c pricebook {
        get {return (Pricebook__c)TestQueryService.getSobjFromVal(sObjListMap, pricebook, 'pricebookList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'NATBOOK');}
        set;
    }    

	//customers
    public Customer__c customerParent {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerParent, 'customerList', 'Customer_Identifier__c', TestQueryService.matchMethod.EQ, 'CPTEST123');}
        set;
    }
    
    public Customer__c customerBillTo {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerBillTo, 'customerList', 'Customer_Identifier__c', TestQueryService.matchMethod.EQ, 'BDTEST123');}
        set;
    }    

    public Customer__c customerSoldTo {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerSoldTo, 'customerList', 'Customer_Identifier__c', TestQueryService.matchMethod.EQ, 'SDTEST123');}
        set;
    }    

    public Customer__c customerShipTo {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerShipTo, 'customerList', 'Customer_Identifier__c', TestQueryService.matchMethod.EQ, 'SHTEST123');}
        set;
    }     

    public Customer__c customerSite {
        get {return (Customer__c)TestQueryService.getSobjFromVal(sObjListMap, customerShipTo, 'customerList', 'Customer_Identifier__c', TestQueryService.matchMethod.EQ, 'SGTEST123');}
        set;
    }     

	
    //facilities
    public Facility__c facility {
    	get {return (Facility__c)TestQueryService.getSobjFromVal(sObjListMap, facility, 'facilityList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'FA01');}
        set;        
    }
    
    public Facility__c facility2 {
    	get {return (Facility__c)TestQueryService.getSobjFromVal(sObjListMap, facility2, 'facilityList', 'Primary_Key__c', TestQueryService.matchMethod.EQ, 'FA02');}
        set;
    }
      

	//locations      
    public Location__c location { 
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location, 'locationList', 'Description__c', TestQueryService.matchMethod.EQ, 'location');}        
        set;		
    }
  
    public Location__c location2 { 
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location2, 'locationList', 'Description__c', TestQueryService.matchMethod.EQ, 'location2');}        
        set;	
    }
    
    public Location__c location3 { 
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location3, 'locationList', 'Description__c', TestQueryService.matchMethod.EQ, 'location3');}        
        set;	
    }
    
    public Location__c location4 { 
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location4, 'locationList', 'Description__c', TestQueryService.matchMethod.EQ, 'location4');}        
        set;	
    }
    
    public Location__c location5 { 
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location5, 'locationList', 'Description__c', TestQueryService.matchMethod.EQ, 'location5');}        
        set;	
    }
    
    public Location__c location6 { 
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location6, 'locationList', 'Description__c', TestQueryService.matchMethod.EQ, 'location6');}        
        set;	
    }
    
    public Location__c location7 { 
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location7, 'locationList', 'Description__c', TestQueryService.matchMethod.EQ, 'location7');}        
        set;	
    }

    public Location__c location8 { 
    	get {return (Location__c)TestQueryService.getSobjFromVal(sObjListMap, location8, 'locationList', 'Description__c', TestQueryService.matchMethod.EQ, 'location8');}        
        set;	
    }
    
    //just an alias for location 7.  not sure why it exists.
    public Location__c location9 {
    	get {return location7;}        
        set;	    
    }
    
    //bins
    public Bin__c bin { 
    	get {return (Bin__c)TestQueryService.getSobjFromVal(sObjListMap, bin, 'binList', 'Description__c', TestQueryService.matchMethod.EQ, 'bin');}        
        set;	
    }
    
 	
	//GLs    
    public GL_Account__c cashGL { 
    	get {return (GL_Account__c)TestQueryService.getSobjFromVal(sObjListMap, cashGL, 'glList', 'Name', TestQueryService.matchMethod.EQ, '12000 - Cash');}        
        set;
	}
    
	public GL_Account__c receivablesGL { 
    	get {return (GL_Account__c)TestQueryService.getSobjFromVal(sObjListMap, receivablesGL, 'glList', 'Name', TestQueryService.matchMethod.EQ, '11000 - Accounts Receivable');}
        set;		
	} 
	
	public GL_Account__c expenseGL { 
    	get {return (GL_Account__c)TestQueryService.getSobjFromVal(sObjListMap, cashGL, 'glList', 'Name', TestQueryService.matchMethod.EQ, '55100 - Expense');}        
        set;		
	} 
    
	public GL_Account__c FGInventoryGL { 
    	get {return (GL_Account__c)TestQueryService.getSobjFromVal(sObjListMap, cashGL, 'glList', 'Name', TestQueryService.matchMethod.EQ, '15000 - Finished Goods Inventory');}        
        set;		
	} 

	public GL_Account__c UnappliedCashGL { 
    	get {return (GL_Account__c)TestQueryService.getSobjFromVal(sObjListMap, UnappliedCashGL, 'glList', 'Name', TestQueryService.matchMethod.EQ, '12100 - Unapplied Cash');}        
        set;		
	} 
	
    public Bank_Account__c bankAccount {
		get {
			if (bankAccount == null) {
    			bankAccount = [select id,GL_Account__c,account_type__c,active__c from  Bank_Account__c where Name = 'Test BOFA'];
			}
			return bankAccount;
		}
		set; 
    } 
  
    public FOB_Terms__c fobTerm {
    	get {
    	    if ( fobTerm == null  ) {
    	    	 fobTerm = [ select id from  FOB_Terms__c where 
    										 Name = 'test term destination'];
    	    }
			return fobTerm;
    	}
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

	    
    public Hierarchy__c hierarchy1 { 
		get {
			if (hierarchy1 == null  ) {
				hierarchy1 = [ select id , name , code__c from  Hierarchy__c where Primary_Key__c = 'H1111' ]; 
			}
			return hierarchy1;
		}
		set; 
    }
    
    public Product_Group__c productGroup { 
		get {
			if ( productGroup == null  ) {
				productGroup = [select id , name, primary_key__c,Hierarchy_Code__c from Product_Group__c
                                where 	Primary_Key__c = 'PG23'];
			}
			return productGroup;
		}
		set; 
    }
       
    public List<SKID__c> skids {
        get {return (List<Skid__c>)TestQueryService.getSobjList(sObjListMap, 'skidList');}
        set;
                }

    public Class__c clsObj {
        get {return (Class__c)TestQueryService.getSobjFromVal(sObjListMap, clsObj, 'classList', 'Type__c', TestQueryService.matchMethod.EQ, 'Goods');}
        set;
    }
    public Item__c ItemNoClassType {
        get {return (Item__c)TestQueryService.getSobjFromVal(sObjListMap, null, 'itemList', 'Name', TestQueryService.matchMethod.ENDSWITH, '-ItemNoClassType');}
        set;
    }

    public Agreement__c agreement  {
        get {return (Agreement__c)TestQueryService.getSobjFromVal(sObjListMap, agreement, 'agreementList', 'Name', TestQueryService.matchMethod.EQ, 'Sample Agreement');}
        set;  
    }   

    public Agreement_Line__c agreementLine {
        get {return (Agreement_Line__c)TestQueryService.getSobjFromVal(sObjListMap, agreementLine, 'agreementLineList', 'Description__c', TestQueryService.matchMethod.EQ, 'Sample Agreement Line 1');}
        set;  
    }  
    
    public Sales_Order__c salesOrder  {
		get {return (Sales_Order__c)TestQueryService.getSobjFromVal(sObjListMap, salesOrder, 'soList', 'Original_Sales_Order__c', TestQueryService.matchMethod.EQ, 'so123');}
       	set;  
    }   

    public Sales_Order_Line__c salesOrderLine {
		get {return (Sales_Order_Line__c)TestQueryService.getSobjFromVal(sObjListMap, salesOrderLine, 'solList', 'Memo__c', TestQueryService.matchMethod.EQ, 'salesOrderLine');}
    	set;  
    }   

    public Cross_Reference__c customerProdRef {
    	get { return (Cross_Reference__c) TestQueryService.getSobjFromVal(sObjListMap, customerProdRef, 'crossReferenceList', 'Name', TestQueryService.matchMethod.EQ, 'CR01');}
    	set;
    }  

    public Sales_Order_Line__c salesOrderLine2 {
		get {return (Sales_Order_Line__c)TestQueryService.getSobjFromVal(sObjListMap, salesOrderLine2, 'solList', 'Memo__c', TestQueryService.matchMethod.EQ, 'salesOrderLine2');}
    	set;  
    }   

	public Receiving_Document__c receivingDocumentASN { 
		get {
			if ( receivingDocumentASN == null  ) {
				receivingDocumentASN = [ select id ,status__c, name 
                                        from Receiving_Document__c 
                                        where type__c = 'Advanced Shipment Notice'];
			}
			return receivingDocumentASN;
		}
		set; 
    }
    
    public List<Receipt_Line__c> receivingDocumentASNLines {
		get{
			if(receivingDocumentASNLines == null){
				receivingDocumentASNLines = [ select id,Line_Type__c,name from Receipt_Line__c ];
	        }
			return receivingDocumentASNLines;
		}
		set;
	}
	
    public List<Stock_Movement_Rule__c> stockMovementRuleList{
        get {return (List<Stock_Movement_Rule__c>)TestQueryService.getSobjList(sObjListMap, 'smrList');}
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
    public Stock_Movement_Rule__c stockMovementRule6 {
    	get {return (Stock_Movement_Rule__c)TestQueryService.getSobjFromVal(sObjListMap, stockMovementRule6, 'stockMoveList', 'Name', TestQueryService.matchMethod.EQ, 'Putaway rule3');}    	
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
	
	public Means_of_Transport__c meansOfTransport {
		get{
			if(meansOfTransport == null){
				meansOfTransport = [select id,code__c,Maximum_Cube__c,Maximum_Weight__c from Means_of_Transport__c 
                                    where code__c = 'LAND'];
			}
			return meansOfTransport;
		}
		set;
	}
	
	public Transit_Route__c transitRoute {
		get{
			if(transitRoute == null){
				transitRoute = [ select id , Destination__c, Origin__c, Means_of_Transport__c, Transit_Time__c, Delivery_Method__c
                                from Transit_Route__c where Delivery_Method__c = 'Delivery'];
			}
			return transitRoute;
		}
		set;	
	}
	
    public List<Period__c> periodList {
        get {
            if (periodList == null) {
       			periodList = [ select id from Period__c ];	
            }
            return periodList;
        } 
        set;
    }

    public Contract__c contractAM {
        get {return (Contract__c)TestQueryService.getSobjFromVal(sObjListMap, contractAM, 'contractList', 'ExtId__c', TestQueryService.matchMethod.EQ, 'TestContract');}
        set;
    }

    public Contract_Line__c contractLine {
        get {return (Contract_Line__c)TestQueryService.getSobjFromVal(sObjListMap, contractLine, 'contractLineList', 'ExtId__c', TestQueryService.matchMethod.EQ, 'TestContractLine');}
        set;
    }

    //POs
    public Purchase_Order__c purchaseOrder {
    	get {return (Purchase_Order__c)TestQueryService.getSobjFromVal(sObjListMap, purchaseOrder, 'poList', 'Memo__c', TestQueryService.matchMethod.EQ, 'purchaseOrder');}        	
        set;
    }    	    
    
    public Purchase_Order__c purchaseOrder2 {
        get {return (Purchase_Order__c)TestQueryService.getSobjFromVal(sObjListMap, purchaseOrder, 'poList', 'Memo__c', TestQueryService.matchMethod.EQ, 'purchaseOrder2');}         
        set;
    }
    
    public Purchase_Order__c subContractedPurchaseOrder {
    	get {return (Purchase_Order__c)TestQueryService.getSobjFromVal(sObjListMap, purchaseOrder, 'poList', 'Memo__c', TestQueryService.matchMethod.EQ, 'subContractedPurchaseOrder');}        	
        set;
    }

	//POLs
    public List<Purchase_Order_Line__c> purchaseOrderLines {
    	get {return (List<Purchase_Order_Line__c>)TestQueryService.getSobjListFromVal(sObjListMap, 'polList', 'Description__c', TestQueryService.matchMethod.EQ, 'purchaseOrderLine0');}        	
        set;
    }
    public Reason_Code__c resolutionCode {
    	get {return (Reason_Code__c)TestQueryService.getSobjFromVal(sObjListMap, null, 'resonCodeList', 'Type__c', TestQueryService.matchMethod.EQ, 'Resolution');}
        set;  
    }
    public Reason_Code__c deductionCode {
    	get {return (Reason_Code__c)TestQueryService.getSobjFromVal(sObjListMap, null, 'resonCodeList', 'Type__c', TestQueryService.matchMethod.EQ, 'Deductions');}
        set;  
    }
    
     public Payment_Profile__c paymentProfile {
     	get {
     		if(paymentProfile == null) {
     			paymentProfile = [select Id, Customer__c, Gateway__c, Payment_Profile_ID__c from Payment_Profile__c where Gateway__c = 'Authorize.net'];
     		}
     		return paymentProfile;
     	}
     	set;
     }
     
     public Payment_Method__c paymentMethod {
     	get {
     		if(paymentMethod == null) {
     			paymentMethod = [select Id, Payment_Profile__c, Payment_Method_ID__c from Payment_Method__c where Payment_Method_ID__c = 'abc123'];
     		}
     		return paymentMethod;
     	}
     	set;
     }
     
     public Customer_Invoice__c custInv1 {
     	get {
     		if(custInv1 == null ) {
     			custInv1 = [Select Id, Company__c, Invoice_Type__c, Status__c, Bill_To_Customer__c, Sold_To_Customer__c from Customer_Invoice__c where Invoice_Type__c = 'Ship Invoice'];
     			
     		}
     		return custInv1;
     		
     	}
     	set;
     }
     
     
     
     

    //Create a map between the Record Type Name and Id for easy retrieval
    public Map<String,String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
    public Map<String,String> SupplierRecordTypes = KSE.RecordTypeDevNameMap('Supplier__c');


    

    public Order__c transferOrder {
        get {
            if (transferOrder == null) {
                Date orderDate = System.today() - 10;

                SOQLUtil orderQuery = new SOQLUtil('Order__c');
                orderQuery.addAllCustomFields();
                orderQuery.setWhereClause('Order_Date__c = :orderDate');

                SOQLUtil.ChildRelationship olQuery = new SOQLUtil.ChildRelationship(orderQuery,'Order_Lines__r');
                olQuery.addAllCustomFields();
                olQuery.setOrderByClause('Autonumber__c ASC');
                orderQuery.addChildRelationship(olQuery);

                transferOrder = Database.query(orderQuery.getQuery());
                transferOrderLines = transferOrder.Order_Lines__r;
            }
            return transferOrder;
        } set;
    }

    public List<Order_Line__c> transferOrderLines {
        get {
            if (transferOrderLines == null) {
                transferOrderLines = transferOrder.Order_Lines__r;
            }
            return transferOrderLines;
        } set;
    }
    
    public Order__c packageTransferOrder {
        get {
            if (packageTransferOrder == null) {
                Date orderDate = System.today() - 12;

                SOQLUtil orderQuery = new SOQLUtil('Order__c');
                orderQuery.addAllCustomFields();
                orderQuery.setWhereClause('Order_Date__c = :orderDate');

                SOQLUtil.ChildRelationship olQuery = new SOQLUtil.ChildRelationship(orderQuery,'Order_Lines__r');
                olQuery.addAllCustomFields();
                olQuery.setOrderByClause('Autonumber__c ASC');
                orderQuery.addChildRelationship(olQuery);

                packageTransferOrder = Database.query(orderQuery.getQuery());
                packageTransferOrderLines = packageTransferOrder.Order_Lines__r;
            }
            return packageTransferOrder;
        } set;
    }

    public List<Order_Line__c> packageTransferOrderLines {
        get {
            if (packageTransferOrderLines == null) {
                packageTransferOrderLines = packageTransferOrder.Order_Lines__r;
            }
            return packageTransferOrderLines;
        } set;
    }


    public Map<String,Reason_Code__c> reasonCodes {
        get {
            if (reasonCodes == null) {
                reasonCodes = new Map<String,Reason_Code__c>();
                for (Reason_Code__c rc:[SELECT Id,Name,Type__c FROM Reason_Code__c WHERE Name IN ('Change','Transfer','Cycle')]) {
                    reasonCodes.put(rc.Name,rc);
                }
            }
            return reasonCodes;
        } set;
    }

    public List<Item__c> itemList  {
        get {
            if (itemList == null) {
                SOQLUtil itemQuery = new SOQLUtil('Item__c');
                itemQuery.addAllCustomFields();
                itemQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item_Attribute__r');
                itemQuery.addFields(new Set<String>{ 'Class__r.Minimum_Shelf_Life_In_Days__c' });
                itemQuery.setWhereClause('Name LIKE \'' + company.Name + ' Item-%\'');
                itemList = Database.query(itemQuery.getQuery()); 
            }
            return itemList;
        } set;
    }
    
    public Item_Specification__c itemSpec {
        get {
            if (itemSpec == null) {
                itemSpec = TestQueryService.getItemSpec('IS');
            }
            return itemSpec;
        } set;
    }
    
    public Invoice__c intercompanyInvestmentInvoice {
        get {return (Invoice__c)TestQueryService.getSobjFromVal(sObjListMap, intercompanyInvestmentInvoice, 'invoiceList', 'Type__c', TestQueryService.matchMethod.EQ, 'Intercompany Investment');}
        set;
    }
    
    public List<Component__c> components {
        get {
            if (components == null) {
                components = itemSpec.Components__r;
            }
            return components;
        } set;
    }

    public List<Routing__c> routings {
        get {
            if (routings == null) {
                routings = itemSpec.Routings__r;
            }
            return routings;
        } set;
    }

    public Item_Specification__c assembly {
        get {
            if (assembly == null) {
                assembly = TestQueryService.getItemSpec('A1');
            }
            return assembly;
        } set;
    }

    public List<Component__c> assemblyComponents {
        get {
            if (assemblyComponents == null) {
                assemblyComponents = assembly.Components__r;
            }
            return assemblyComponents;
        } set;
    }

    public List<Routing__c> assemblyRoutings {
        get {
            if (assemblyRoutings == null) {
                assemblyRoutings = assembly.Routings__r;
            }
            return assemblyRoutings;
        } set;
    }

    public Item_Specification__c assembly2 {
        get {
            if (assembly2 == null) {
                assembly2 = TestQueryService.getItemSpec('A2');
            }
            return assembly2;
        } set;
    }

    public List<Component__c> assembly2Components {
        get {
            if (assembly2Components == null) {
                assembly2Components = assembly2.Components__r;
            }
            return assembly2Components;
        } set;
    }

    public List<Routing__c> assembly2Routings {
        get {
            if (assembly2Routings == null) {
                assembly2Routings = assembly2.Routings__r;
            }
            return assembly2Routings;
        } set;
    }

    public Work_Order__c workOrder {
        get {
            if (workOrder == null) {
                workOrder = TestQueryService.getWorkOrder('workorder');
            }
            return workOrder;
        } set;
    }

    public Work_Order__c phantomWorkOrder {
        get {
            if (phantomWorkOrder == null) {
                phantomWorkOrder = TestQueryService.getWorkOrder('phantomworkorder');
            }
            return phantomWorkOrder;
        } set;
    }

    public Sales_Order__c packageSalesOrder {
        get {
            if (packageSalesOrder == null) {
                SOQLUtil soQuery = new SOQLUtil('Sales_Order__c');
                soQuery.addAllCustomFields();
                soQuery.setWhereClause('Original_Sales_Order__c = \'packageSalesOrder\'');

                SOQLUtil.ChildRelationship solQuery = new SOQLUtil.ChildRelationship(soQuery, 'Sales_Order_Lines__r');
                solQuery.addAllCustomFields();
                solQuery.addFields(new Set<String>{ 'Product__r.Item__c', 'Product__r.Item__r.Stocking_UOM__c' });
                soQuery.addChildRelationship(solQuery);

                packageSalesOrder = Database.query(soQuery.getQuery());
            }
            return packageSalesOrder;
        } set;
    }

    public void setupInventory() { setupInventory(false, false, false); }
    public void setupInventory(Boolean attributes) { setupInventory(attributes, false, false); }
    public void setupInventory(Boolean attributes, Boolean serials) { setupInventory(attributes, serials, false); }
    public void setupInventory(Boolean attributes, Boolean serials, Boolean packaging) {
        Map<Id,Lot__c> lots = new Map<Id,Lot__c>();
        Map<String, LPN__c> lpnMap = new Map<String, LPN__c>();
        List<SKID__c> skids = new List<SKID__c>();
        for (Integer i = 0; i < itemList.size(); i++) {
            Item__c item = itemList[i];

            SKID__c skid1 = new SKID__c(
                Company__c = item.Company__c,
                Type__c = SkidService3.SKID_TYPE_LOCATION,
                Quantity__c = 100,
                Quantity_Stocking_UOM__c = 100,
                Stocking_UOM__c = item.Stocking_UOM__c,
                Packaging_UOM__c = item.Stocking_UOM__c,
                Item__c = item.Id,
                Facility2__c = location3.Facility__c,
                Location__c = location3.Id,
                Container_Item__c = item.id
            );

            if (!attributes) {
                item.Item_Attribute__c = null;
            } else {
                lots.put(item.Id, new Lot__c(Name = 'LOT1', Item__c = item.Id, Company__c = item.Company__c, Expiration_Date__c = System.today() + 365));
                skid1.Expiration_Date__c = System.today() + 365;

                if (serials) {
                    item.Item_Attribute__c = itemAttrObj2.Id;
                    skid1.Quantity__c = 10;
                    skid1.Quantity_Stocking_UOM__c = 10;
                } else if (packaging) {
                    if (i == 12 || i == 13) {
                        lots.remove(item.Id);
                        skid1 = null;
                    } else if (i == 14 || i == 15 || i == 16) {
                        lpnMap.put('LPN' + item.Name, new LPN__c(Name = 'LPN' + item.Name));
                        lpnMap.put('Part LPN' + item.Name, new LPN__c(Name = 'Part LPN' + item.Name));
                        
                        List<Id> uoms = (List<Id>)JSON.deserialize(item.Packaging_UOM__c, List<Id>.Class);

                        SKID__c caseSkid = skid1.clone(false, true);
                        caseSkid.Quantity_Stocking_UOM__c = 200;
                        caseSkid.Packaging_UOM__c = uoms[1];
                        caseSkid.Container_Item__c = itemList[12].Id;
                        skids.add(caseSkid);

                        SKID__c palletSkid = skid1.clone(false, true);
                        palletSkid.Quantity__c = 1;
                        palletSkid.Quantity_Stocking_UOM__c = 6;
                        palletSkid.Packaging_UOM__c = uoms[2];
                        palletSkid.Container_Item__c = itemList[13].Id;
                        palletSkid.Temporary_LPN_Holder__c = 'LPN' + item.Name;
                        skids.add(palletSkid);
                        
                        SKID__c partPalletSkid = skid1.clone(false, true);
                        partPalletSkid.Quantity__c = 1;
                        partPalletSkid.Quantity_Stocking_UOM__c = 2;
                        partPalletSkid.Packaging_UOM__c = uoms[1];
                        partPalletSkid.Container_Item__c = itemList[13].Id;
                        partPalletSkid.Temporary_LPN_Holder__c = 'Part LPN' + item.Name;
                        skids.add(partPalletSkid);
                        
                        skid1.Quantity__c = 5;
                    }
                }
            }

            if (skid1 != null) {
                SKID__c skid2 = skid1.clone(false, true);
                skid2.Location__c = location5.Id;

                skids.add(skid1);
                skids.add(skid2);
            }
        }

        if (lots.size() > 0) insert lots.values();
        if (lpnMap.size() > 0) insert lpnMap.values();
        if (!attributes || serials) {
            update itemList;
            insert skids;
        }

        if (attributes) {
            List<Serial__c> serialsToInsert = new List<Serial__c>();
            for (SKID__c skid:skids) {
                Lot__c lot = lots.get(skid.Item__c);
                skid.Lot__c = lot.Id;
                skid.Lot_Number__c = lot.Name;
                if (skid.Temporary_LPN_Holder__c != null ){
                    
                    skid.License_Plate_Number__c = lpnMap.get(skid.Temporary_LPN_Holder__c).Id;
                    skid.Temporary_LPN_Holder__c = null;
                } 

                if (serials) {
                    for (Integer i = 0; i < skid.Quantity__c; i++) {
                        serialsToInsert.add(new Serial__c(
                            Name = '' + skid.Id + i,
                            Company__c = skid.Company__c,
                            Item__c = skid.Item__c,
                            SKID__c = skid.Id,
                            Unique_Key2__c = '' + skid.Company__c + '-' + skid.Item__c + '-' + skid.Id + i
                        ));
                    }
                }
            }

            upsert skids;
            if (serialsToInsert.size() > 0) insert serialsToInsert;
        }
    }
}