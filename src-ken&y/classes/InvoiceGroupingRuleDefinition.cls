public with sharing class InvoiceGroupingRuleDefinition implements Comparable {
	/*
	WE use this class to compress our Invoice grouping Rule. 
	*/
	public Id companyId; //for a particular company id
	public String groupByCustomers;
	public boolean groupByAgreements;
	public boolean groupBySalesOrders;
	public boolean groupBySalesOrderTypes;
	public String groupSOIf;
	public boolean groupByShipments;
	public boolean groupByCategory;
	public boolean groupByProduct;
	public decimal rank;
	public Date recurrenceStartDate;
	public String periodicity;
	public Id groupingRule;
	public boolean UseBillingFromFulfillment;
	public integer everyPeriodicity;
    public Set<Id> forAgreements;
    public Set<Id> forCategories;
    public Set<Id> forCustomers;
    public Set<Id> forProducts;
	public DateTime recurrenceStartDatetime;
	
	public static final string CUSTOMER_BILL_TO = 'Bill To';
	//CONSTRUCTOR
	public InvoiceGroupingRuleDefinition (Invoice_Grouping_Rule__c igr) {
		
		 this.companyId = igr.Company__c; //for a particular company id
		 this.groupByCustomers = igr.Group_By_Customer_Hierarchy__c;
		 this.groupByAgreements = igr.Group_By_Agreements__c;
		 this.groupBySalesOrders  = igr.Group_By_Sales_Orders__c;
		 this.groupBySalesOrderTypes  = igr.Group_By_Sales_Order_Types__c;
		 this.groupSOIf = igr.Group_By_Sales_Order_If__c;
		 this.groupByShipments  = igr.Group_By_Shipments__c;
		 this.groupByProduct = igr.Group_By_Product__c;
		 this.groupByCategory = igr.Group_By_Category__c;
		 this.rank  = igr.Rank__c;
		 this.periodicity = igr.Billing_UOM__c  == null ? FrequencyService.FREQUENCY_PERIOD_IMMEDIATE : igr.Billing_UOM__r.Recurrence__c; 
		 this.recurrenceStartDate = this.periodicity ==  FrequencyService.FREQUENCY_PERIOD_IMMEDIATE ? null : igr.Recurrence_Start_Date__c.date(); 
		 this.recurrenceStartDatetime = this.periodicity ==  FrequencyService.FREQUENCY_PERIOD_IMMEDIATE ? null : igr.Recurrence_Start_Date__c;
		 this.everyPeriodicity = Integer.valueOf(igr.Billing_UOM__r.Every__c);
		 this.groupingRule = igr.id;
		 this.UseBillingFromFulfillment = igr.Use_Billing_Frequency_on_Fulfillment__c == null ? false: igr.Use_Billing_Frequency_on_Fulfillment__c;

         
         this.forAgreements = (igr.For_Agreements__c != null) ? (Set<Id>)JSON.deserialize(String.valueOf(igr.For_Agreements__c), Set<Id>.Class) : null;
         this.forCategories = (igr.For_Categories__c != null) ? (Set<Id>)JSON.deserialize(String.valueOf(igr.For_Categories__c), Set<Id>.Class) : null;
         this.forCustomers =  (igr.For_Customers__c != null) ? (Set<Id>)JSON.deserialize(String.valueOf(igr.For_Customers__c), Set<Id>.Class) : null;
         this.forProducts =   (igr.For_Products__c != null) ? (Set<Id>)JSON.deserialize(String.valueOf(igr.For_Products__c), Set<Id>.Class)  : null;
        
	}
	public InvoiceGroupingRuleDefinition() {
		//EMPTY Constructor
	}
	
	public static InvoiceGroupingRuleDefinition createRuleForSObject(Id companyId, String objectName) {
		
		InvoiceGroupingRuleDefinition ruleDef = new InvoiceGroupingRuleDefinition();
		ruleDef.companyId = companyId;
		if(objectName.equalsIgnoreCase('Agreement__c')) {
			ruleDef.groupByAgreements = true;
			ruleDef.groupBySalesOrderTypes = true;
			ruleDef.groupByCustomers = 'Corporate Parent';
		}
			
		else {
			ruleDef.groupByCustomers = 'Bill To';
		if(objectName.equalsIgnoreCase('Sales_Order__c'))
			ruleDef.groupBySalesOrders = true;
			else if(objectName.equalsIgnoreCase('Shipment__c')) {
			ruleDef.groupByShipments = true;
				ruleDef.groupBySalesOrderTypes = true;
			}else {
				ruleDef.groupBySalesOrderTypes = true;
			}
		}
		 
		
		ruleDef.rank = 1;
		ruleDef.periodicity =FrequencyService.FREQUENCY_PERIOD_IMMEDIATE;
		ruleDef.recurrenceStartDate = null;
		ruleDef.recurrenceStartDatetime = null;
		ruleDef.UseBillingFromFulfillment = false;
		return ruleDef;
	}
	
	//Currently the ranking is explicit, based on the rank (user specified) field. TODO: could have an implicit ranking based on the granular level specified. 
	public integer compareTo(Object compareTo) { //SORTS IN DESCENDING ORDER
		
		InvoiceGroupingRuleDefinition ruleDef = (InvoiceGroupingRuleDefinition) compareTo;
		if(rank == ruleDef.rank) return 0;
		else if(rank > ruleDef.rank) return 1;
		else return -1;
	}
	
	public integer hashCode(){
		return HashCodeGenerator.getHashCode(this);  
	}
	
	public boolean equals(object obj){
		InvoiceGroupingRuleDefinition compare = (InvoiceGroupingRuleDefinition)obj;
        if(this.companyId == compare.companyId &&
           this.groupByCustomers == compare.groupByCustomers &&
		   this.groupByAgreements == compare.groupByAgreements &&
		   this.groupBySalesOrders  == compare.groupBySalesOrders &&
		   this.groupBySalesOrderTypes  == compare.groupBySalesOrderTypes &&
		   this.groupSOIf == compare.groupSOIf &&
		   this.groupByShipments  == compare.groupByShipments &&
		   this.groupByProduct == compare.groupByProduct &&
		   this.groupByCategory == compare.groupByCategory &&
		   this.rank  == compare.rank &&
		   this.recurrenceStartDate == compare.recurrenceStartDate &&
		   this.periodicity == compare.periodicity &&
		   this.groupingRule == compare.groupingRule &&
		   this.UseBillingFromFulfillment == compare.UseBillingFromFulfillment &&
		   this.everyPeriodicity == compare.everyPeriodicity && 
           this.forAgreements == compare.forAgreements &&
           this.forCategories == compare.forCategories &&
           this.forCustomers == compare.forCustomers &&
           this.forProducts == compare.forProducts)
		  	
	  	{
	  		return true;
	  	}else{
			return false;
		}
	}
	
	public class status{

           public boolean qualifies;
           public string message;
           public status(){}
           public status(boolean qualifies, string message){
               this.qualifies= qualifies;
               this.message = message;
           }
    }
	
	//added as a part of KNDY-9741
    public static status isQualifiedWithMessage(Fulfillment__c f, InvoiceGroupingRuleDefinition ruleDef) {
            system.debug(logginglevel.error,ruleDef);
            system.debug(logginglevel.error,f);
            if(f.Type__c == AllowanceRuleService.ALLOWANCE_ACCRUAL){ //KNDY-14713
                return new status(true,'Success'); 
            }
            if(ruleDef.companyId != f.Company__c) {
                system.debug('company didnt match');
                return new status(false,'Company not matching');
            }else if((f.Agreement_Line__r.Agreement__c != null && (f.Agreement_Line__r.Agreement__r.Activation_Date__c == null || f.Agreement_Line__r.Agreement__r.Activation_Date__c > system.today()))){
                system.debug('agreement date issue: '+(f.Agreement_Line__r.Agreement__c != null && (f.Agreement_Line__r.Agreement__r.Activation_Date__c == null || f.Agreement_Line__r.Agreement__r.Activation_Date__c > system.today()))); 
                return new status(false,'Agreement Activation Date is incorrect');
            }else if((f.Sales_Order_Line__c != null && f.Sales_Order_Line__r.Sales_Order__r.Has_Exceptions__c == true)){
                system.debug(logginglevel.error,'SO issue: '+(f.Sales_Order_Line__c != null && f.Sales_Order_Line__r.Sales_Order__r.Has_Exceptions__c == true));
                return new status(false,'Related Sales Order is having exceptions');
            }else if((f.Shipment_Line__c != null && f.Shipment_Line__r.Shipment__r.Has_Exceptions__c == true)){
                system.debug('SH issue: '+(f.Shipment_Line__c != null && f.Shipment_Line__r.Shipment__r.Has_Exceptions__c == true));
                return new status(false,'Related Shipment is having exceptions');
            }else if(ruleDef.groupByCustomers != null && !InvoiceGroupingRuleDefinition.isWithinHierarchy(ruleDef.groupByCustomers, f)) {
                system.debug('groupBy Cust didnt match');
                return new status(false,'Group By Customers not matching');
            }else if(ruleDef.groupByAgreements == true && f.Agreement_Line__r.Agreement__c == null) {//KNDY-8667
                system.debug('groupByAgreements didnt match');
                return new status(false,'Group By Agreements not matching');
            }else if((ruleDef.groupBySalesOrders == true || ruleDef.groupBySalesOrderTypes == true) && f.Sales_Order_Line__c == null) { //KNDY-8634
                system.debug('groupBySalesOrders didnt match');
                return new status(false,'Group By SalesOrders not matching');
            }else if(ruleDef.groupSOIf == InvoiceGroupingRuleService.GROUP_ENTIRE_SO && f.Sales_Order_Line__r.Sales_Order__r.Status__c != 'Closed') {
                system.debug('groupSOIf entire so didnt match');
                return new status(false,'Entire SO not matching');
            }else if(ruleDef.groupSOIf == InvoiceGroupingRuleService.GROUP_ENTIRE_SOL && f.Sales_Order_Line__r.Status__c != 'Closed') {
                system.debug('groupSOIf entire sol didnt match');
                return new status(false,'Entire SOL not matching');
            }else if(ruleDef.groupByShipments == true && f.Shipment_Line__c == null) {
                system.debug('groupByShipments didnt match');
                return new status(false,'Group By Shipments not matching');
            }else if(ruleDef.groupByCategory == true && f.Category__c == null) {
                system.debug('groupByCategory didnt match');
                return new status(false,'Group By Category not matching');
            }else if(ruleDef.groupByProduct == true && f.Product__c == null) {
                system.debug('groupByProduct didnt match');
                return new status(false,'Group By Product not matching');
            }else if(ruleDef.forAgreements != null && !ruleDef.forAgreements.contains(f.Agreement_Line__r.Agreement__c)){
                system.debug('forAgreements didnt match');
                return new status(false,'Agreements not matching');  
            }else if(ruleDef.forCategories != null && !ruleDef.forCategories.contains(f.Category__c)){
               system.debug('forCategories didnt match');
                return new status(false,'Categories not matching');
            }else if(ruleDef.forProducts != null && !ruleDef.forProducts.contains(f.Product__c)){
                system.debug('forProducts didnt match');
                return new status(false,'Products not matching');
            }else if(ruleDef.forCustomers != null && !ruleDef.forCustomers.contains(f.Customer__c)){
                system.debug('forCustomers didnt match');
                return new status(false,'Customers not matching');
            }else {
                return new status(true,'Success'); 
            }           
    }
	
	private static boolean isWithinHierarchy (String hierarchy, Fulfillment__c f) {
		system.debug('hierarchy '+hierarchy);
		system.debug('f.Customer__r.RecordType.DeveloperName '+f.Customer__r.RecordType.DeveloperName);
		
		if(hierarchy == 'Corporate Parent' && (f.Customer__r.RecordType.DeveloperName == 'Corporate_Parent' || f.Customer__r.RecordType.DeveloperName == 'Bill_To' || f.Customer__r.RecordType.DeveloperName == 'Sold_To' || f.Customer__r.RecordType.DeveloperName == 'Ship_To' || f.Customer__r.RecordType.DeveloperName == 'Site' ))
			return true;
		else if(hierarchy == 'Bill To' && (f.Customer__r.RecordType.DeveloperName == 'Bill_To' || f.Customer__r.RecordType.DeveloperName == 'Sold_To' || f.Customer__r.RecordType.DeveloperName == 'Ship_To'|| f.Customer__r.RecordType.DeveloperName == 'Site'))
			return true;
		else if(hierarchy == 'Sold To' && (f.Customer__r.RecordType.DeveloperName == 'Sold_To' || f.Customer__r.RecordType.DeveloperName == 'Ship_To' || f.Customer__r.RecordType.DeveloperName == 'Site')) 
			return true;
		else if(hierarchy == 'Ship To' && (f.Customer__r.RecordType.DeveloperName == 'Ship_To' || f.Customer__r.RecordType.DeveloperName == 'Site'))
			return true;
		else if(hierarchy == 'Site' && f.Customer__r.RecordType.DeveloperName == 'Site')
			return true;
		else 
			return false;
		
	}
	 

}