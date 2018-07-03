public with sharing class TestDataForAllowanceQuery {

	TestFuelQuery fuelQuery = new TestFuelQuery();


	public Account account {
		get {return fuelQuery.account;}
		set;
	}

	public Product_Group__c productgroup {
		get {return fuelQuery.productgroup;}
		set;
	}

	public List<UOM__c> uomList {
		get { return fuelQuery.uomList;}
		set;
	}

	public Location__c location2 {
		get {return fuelQuery.location2;}
		set;
	}

	public Customer__c customerParent {
		get {return fuelQuery.customerParent;}
		set;
	}

	public Customer__c customerBillTo {
		get {return fuelQuery.customerBillTo;}
		set;
	}

	public Customer__c customerSoldTo {
		get {return fuelQuery.customerSoldTo;}
		set;
	}
	public Customer__c customerShipTo {
		get {return fuelQuery.customerShipTo;}
		set;
	}
	public Payment_Term__c terms {
		get {return fuelQuery.terms;}
		set;
	}
	public Company__c company {
		get {return fuelQuery.company;}
		set;
	}
	
	public UOM__c CALENDAR_MONTH {
		get {return (UOM__c)TestQueryService.getSobjFromVal(sObjListMap, CALENDAR_MONTH, 'uomList', 'Recurrence__c', TestQueryService.matchMethod.EQ, 'Month(s)');}
		set;
	}

	Map<String, List<sObject>> sObjListMap = new Map<String, List<sObject>>();

	public Sales_Order__c salesOrder  {
		get {return (Sales_Order__c)TestQueryService.getSobjFromVal(sObjListMap, salesOrder, 'soList', 'Original_Sales_Order__c', TestQueryService.matchMethod.EQ, 'salesOrder');}
		set;
	}

	public Currency__c currencyUSD {
		get {return (Currency__c)TestQueryService.getSobjFromVal(sObjListMap, currencyUSD, 'currencyList', 'ISO_Code__c', TestQueryService.matchMethod.EQ, 'USD');}
		set;
	}

	public Hierarchy__c l2Hierarchy1 {
		get {return (Hierarchy__c)TestQueryService.getSobjFromVal(sObjListMap, l2Hierarchy1, 'hierarchyList', 'Code__c', TestQueryService.matchMethod.EQ, 'H1110');}
		set;
	}

	public Product__c product {
		get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, product, 'productList', 'Name', TestQueryService.matchMethod.EQ, 'Product-10');}
		set;
	}

	public Product__c product2 {
		get {return (Product__c)TestQueryService.getSobjFromVal(sObjListMap, product2, 'productList', 'Name', TestQueryService.matchMethod.EQ, 'Product-15');}
		set;
	}

	public List<Customer_Group__c> customerGroupList {
		get {return (List<Customer_Group__c>)TestQueryService.getSobjList(sObjListMap, 'customerGroupList');}
		set;
	}

	public List <Sales_Order_Line__c> solList  {
		get {
			if (solList == null) {
				SOQLUtil solListQuery = new SOQLUtil('Sales_Order_Line__c');
				solListQuery.addFields(new Set<String> {'Product__c', 'Company__c', 'Sales_Order__c', 'Quantity_Ordered__c', 'Required_Date__c', 'Weight_UOM__c'});
				solListQuery.addFields(new Set<String> {'Product__r.Product_Group__c'});
				solListQuery.setWhereClause('Sales_Order__c = \'' + salesOrder.Id + '\'');
				solList =  Database.query(solListQuery.getQuery());
			}
			return solList;
		}
		set;
	}

	public Map<String,String> CustomerRecordTypes = fuelQuery.CustomerRecordTypes;
}