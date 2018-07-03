public with sharing class CustomerService {
	
	public static map<Id,CustomerService.RunningAverage> runningAverages;
	public static set<Id> manualCICustomers = new set<Id>();
	public static set<Id> manualCICorpCustomers = new set<Id>();
	public static boolean CorpParentAlreadyExists = false;

	public static final String CUST_STATUS_APPROVED = 'Approved';
	public static final String CUST_STATUS_INACTIVE = 'Inactive';

	public static final String CUST_TYPE_CORP_PARENT = 'Corporate_Parent';
	public static final String CUST_TYPE_BILL_TO = 'Bill_To';
	public static final String CUST_TYPE_SOLD_TO = 'Sold_To';
	public static final String CUST_TYPE_SHIP_TO = 'Ship_To';
	public static final String CUST_TYPE_SITE = 'Site';

	// OTC-442 Validate 'Use Fixed Pricing' changes on Customer Record 
	public static void validateUseFixedPricing(){
    	if (trigger.isBefore && trigger.isUpdate){
    		
			Set<Id> customerIds = new Set<Id>();
    			    	
    		for (Customer__c c : (List<Customer__c>) trigger.new) {  	
				if (KSE.isFieldChanging('Use_Fixed_Pricing__c', c, trigger.oldMap)) { 
					customerIds.add(c.Id);	
				} 
    		}
			
			if (customerIds.size() > 0){
				// Need to query for all the RecordType
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','RecordType.DeveloperName'
				});
				soql.setWhereClause('Id IN :customerIds AND RecordType.DeveloperName <> \'Sold_To\'');
				for ( Customer__c cust : Database.query(soql.getQuery())) {
					// Only allow Sold To
					cust.Use_Fixed_Pricing__c.addError(Label.Requires_Sold_To_Customer);
				}
			}

        }
    	
    }
    
    public static void setOutstandingBalance() {
    	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
    		for(Customer__c c : (list<Customer__c>)trigger.new) {
    			c.Outstanding_Balance2__c = 0;
    			c.Outstanding_Balance2__c = KSE.addQuantityToField(c.Outstanding_Balance2__c, c.Open_Sales_Orders__c);
    			c.Outstanding_Balance2__c = KSE.addQuantityToField(c.Outstanding_Balance2__c, c.Uninvoiced_Shipments__c);
    			c.Outstanding_Balance2__c = KSE.addQuantityToField(c.Outstanding_Balance2__c, c.Open_Invoices__c);
    			c.Outstanding_Balance2__c = KSE.addQuantityToField(c.Outstanding_Balance2__c, c.Open_Credits__c);
    			
    		}
    	}
    }
    
    //KNDY-15842: Account to customer
    //Function to check if a corp customer already exists for the given account and company combination
    //If yes, CorpParentAlreadyExists flag is set to true
    public static boolean checkforExistingCorpParent(Customer__c cust){

		if (cust.CRM_Account__c != null){
		    SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Name'
			});
			soql.setWhereClause('RecordTypeId ='+'\''+cust.RecordTypeId+'\''+ ' AND Company__c ='+'\''+cust.Company__c+'\''+' AND CRM_Account__c =' +'\''+cust.CRM_Account__c+'\'');
			List<Customer__c> customerList = Database.query(soql.getQuery());
			
			if (customerList.size() > 0){
			    CorpParentAlreadyExists = true;
			}
		}
		return CorpParentAlreadyExists;
    }
   
    public class RunningAverage {
    	
    	public decimal Average;
    	public decimal recordCount;
    	public Id customerId;
    	
    	public RunningAverage(Id customerId, decimal Average, decimal recordCount) {
    		this.customerId = customerId;
    		this.recordCount = recordCount == null ? 0 : recordCount;
    		this.average = average == null ? 0 : average;
    	}
    	
    	public RunningAverage(id customerId) {
    		this.customerId = customerId;
    		this.recordCount = 0;
    		this.average = 0;
    	}
    	
    	//https://en.wikipedia.org/wiki/Moving_average : Cumulative moving average
    	//This method claculates and returns the new average. 
    	public Decimal calculateNewAverage(Decimal newNumberTotal, Decimal newRecordCount) {
    		
    		Decimal newAverage = 0;
    		newNumberTotal = newNumberTotal == null ? 0 : newNumberTotal;
    		newRecordCount = newRecordCount == null ? 0 : newRecordCount;
    		Decimal totalRecordCount = recordCount + newRecordCount;
    		newAverage =  totalRecordCount == 0 ? 0 : (newNumberTotal + (recordCount * average))/(totalRecordCount);
    		setValues(newAverage, totalRecordCount);
    		
    		return newAverage;
    		
    	}
    	private void setValues(Decimal newAverage, Decimal newRecordCount) {
    		this.average = newAverage;
    		this.recordCount = newRecordCount;
    	}
    	
    }
    
    
}