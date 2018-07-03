public with sharing class CustomerQuickCreateExt {

	public Customer__c corpParent {get;set;}
	public Customer__c billTo {get;set;}
	public Customer__c soldTo {get;set;}
	public Customer__c shipTo {get;set;}
	public Customer__c site {get;set;}
	public Id defaultCompany {get; set;}
	public Map<String, Id> recordTypeInfo{get; set;}
	public Id accID {get; set;}
	public String returnUrl {get; set;}
	public Boolean createSite {get; set;}

	public static String CORPORATE_PARENT_CUSTOMER_RECORD_TYPE = 'Corporate Parent';
    public static String BILL_TO_CUSTOMER_RECORD_TYPE = 'Bill To';
    public static String SOLD_TO_CUSTOMER_RECORD_TYPE = 'Sold To';
    public static String SHIP_TO_CUSTOMER_RECORD_TYPE = 'Ship To';
    public static String SITE_CUSTOMER_RECORD_TYPE = 'Site';

	public CustomerQuickCreateExt(Apexpages.StandardsetController con) {
		this.corpParent = new Customer__c();
		this.billTo = new Customer__c();
		this.soldTo = new Customer__c();
		this.shipTo = new Customer__c();
		this.site = new Customer__c();

		createSite = false;
		Configuration__c c = Configuration__c.getValues('CustomerQuickCreate_Site');
		if (c != null){
			createSite = true;
		}

		Schema.DescribeSObjectResult dsr = Customer__c.SObjectType.getDescribe();
		returnUrl = '/' + dsr.getKeyPrefix();

		//KNDY-15842 - Account to Customer - Validate if this is valid and also if it is from Account
		try{
			accId = ApexPages.currentPage().getParameters().get('accid');
			if (accId != null){
				if (Schema.Account.SObjectType == accid.getSobjectType()){
					initializeData();
				}
				else{
		            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid ID'));
				}
			}else{
				initializeData();
			}
		}catch(Exception e){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage()));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            ApexPages.addMessage(myMsg);
		}
	}

	public void initializeData(){

		this.defaultCompany = getDefaultCompany();
		recordTypeInfo = getCustomerRecordTypeInfo();
		List<Account> accountList = new List<Account>();

		if (accId != null){
			SOQLUtil soql = new SOQLUtil('Account', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Name', 'BillingCity', 'BillingCountry', 'BillingPostalCode', 'BillingState', 'BillingStreet', 'ShippingCity', 'ShippingCountry', 'ShippingPostalCode', 'ShippingState', 'ShippingStreet'
			});
			soql.setWhereClause('id = :accID');
			accountList = Database.query(soql.getQuery());
		}

		corpParent.Company__c = this.defaultCompany;
		if(recordTypeInfo.containsKey(CustomerQuickCreateExt.CORPORATE_PARENT_CUSTOMER_RECORD_TYPE)){

			corpParent.RecordTypeId = recordTypeInfo.get(CustomerQuickCreateExt.CORPORATE_PARENT_CUSTOMER_RECORD_TYPE);
			if (accId != null){
				setCustomerAddress(corpParent, accountList);
			}
		}

		//billTo.Company__c = defaultCompany;
		if(recordTypeInfo.containsKey(CustomerQuickCreateExt.BILL_TO_CUSTOMER_RECORD_TYPE)){

			billTo.RecordTypeId = recordTypeInfo.get(CustomerQuickCreateExt.BILL_TO_CUSTOMER_RECORD_TYPE);
			if (accId != null){
				setCustomerAddress(billTo, accountList);
			}
		}

		//soldTo.Company__c = defaultCompany;
		if(recordTypeInfo.containsKey(CustomerQuickCreateExt.SOLD_TO_CUSTOMER_RECORD_TYPE)){

			soldTo.RecordTypeId = recordTypeInfo.get(CustomerQuickCreateExt.SOLD_TO_CUSTOMER_RECORD_TYPE);
			if (accId != null){
				setCustomerAddress(soldTo, accountList);
			}
		}

		//shipTo.Company__c = defaultCompany;
		if(recordTypeInfo.containsKey(CustomerQuickCreateExt.SHIP_TO_CUSTOMER_RECORD_TYPE)){

			shipTo.RecordTypeId = recordTypeInfo.get(CustomerQuickCreateExt.SHIP_TO_CUSTOMER_RECORD_TYPE);
			if (accId != null){
				setCustomerAddress(shipTo, accountList);
			}
		}

		if(recordTypeInfo.containsKey(CustomerQuickCreateExt.SITE_CUSTOMER_RECORD_TYPE)){

			site.RecordTypeId = recordTypeInfo.get(CustomerQuickCreateExt.SITE_CUSTOMER_RECORD_TYPE);
			if (accId != null){
				setCustomerAddress(shipTo, accountList);
			}
		}
		setDefaultCompanyFromCorp();
	}

	private Map<String, Id> getCustomerRecordTypeInfo(){

		Map<String, Id> recordTypeId = new Map<String, Id>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('RecordType', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name'
		});
		String cpName = CustomerQuickCreateExt.CORPORATE_PARENT_CUSTOMER_RECORD_TYPE;
		String btName = CustomerQuickCreateExt.BILL_TO_CUSTOMER_RECORD_TYPE;
		String stName = CustomerQuickCreateExt.SOLD_TO_CUSTOMER_RECORD_TYPE;
		String shipName = CustomerQuickCreateExt.SHIP_TO_CUSTOMER_RECORD_TYPE;
		String siteName = CustomerQuickCreateExt.SITE_CUSTOMER_RECORD_TYPE;
		soql.setWhereClause('Name IN (:cpName, :btName, :stName, :shipName, :siteName)');
		List<Recordtype> recordTypes = Database.query(soql.getQuery());
		
		for(Recordtype rType: recordTypes) {
			recordTypeId.put(rType.Name, rType.Id);
		}

		return recordTypeId;
	
	}

	private Id getDefaultCompany(){

		if(this.defaultCompany == null){

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('User_Preference__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Default_Company__c'
			});
			String userId = String.valueOf(UserInfo.getUserId());
			soql.setWhereClause('User__c = :userId');
			soql.setLimit(1);
			List<User_Preference__c> uPreference = Database.query(soql.getQuery());

			if(uPreference.size() > 0){

				this.defaultCompany = uPreference[0].Default_Company__c;
			}
			
		} 

		return this.defaultCompany;
	}

	public boolean save(){

		Savepoint sp = Database.setSavepoint();
		
		//KNDY-15842: Account to customer - check if a corp parent already exists for the account company combination
		if (CustomerService.checkforExistingCorpParent(corpParent)){
		    Database.rollback(sp);
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,Label.Cannot_create_corp_parent_customer);
    		ApexPages.addMessage(myMsg);
    		return null;
		}
		
		try {
			DML.checkUpsertAsUser(new List<Customer__c>{corpParent, billTo, soldTo, shipTo});
			DML.insertAsUser(corpParent);
			if(setDefaultCompanyFromCorp()){
				billTo.Top_Parent_Customer__c = corpParent.Id;
				billTo.Parent_Customer__c = corpParent.Id;
				DML.insertAsUser(billTo);

				soldTo.Parent_Customer__c = billTo.Id;
				soldTo.Top_Parent_Customer__c = corpParent.Id;
				DML.insertAsUser(soldTo);

				shipTo.Parent_Customer__c = soldTo.Id;
				shipTo.Top_Parent_Customer__c = corpParent.Id;
				DML.insertAsUser(shipTo);
				
				if (createSite){ //KNDY-20263
					site.Parent_Customer__c = shipTo.Id;
					site.Top_Parent_Customer__c = corpParent.Id;
					DML.insertAsUser(site);
				}
			} else{
				Database.rollback(sp);
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Unknown error. Please contact support.');
        		ApexPages.addMessage(myMsg);
			}
			//Redirect to Customer list
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'Customers created successfully.'));
			return null;
		} catch(Exception e) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage()));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            ApexPages.addMessage(myMsg);
			Database.rollback(sp);	
            return null;
		}
		
		
	}

	public Boolean setDefaultCompanyFromCorp(){
		this.defaultCompany = this.corpParent.Company__c;
		this.billTo.Company__c = this.defaultCompany;
		this.soldTo.Company__c = this.defaultCompany;
		this.shipTo.Company__c = this.defaultCompany;
		this.site.Company__c = this.defaultCompany;
		return true;
	}

	//KNDY-15842 - Account to Customer - Set the address values
	public void setCustomerAddress(Customer__c customer, List<Account> acct){

		customer.CRM_Account__c = accID;
		if (customer.RecordTypeId == recordTypeInfo.get(CustomerQuickCreateExt.SHIP_TO_CUSTOMER_RECORD_TYPE)){
			customer.Customer_Street__c = acct[0].ShippingStreet;
            customer.Customer_City__c = acct[0].ShippingCity;
            customer.Customer_State__c = acct[0].ShippingState;
            customer.Customer_Zip_Code__c = acct[0].ShippingPostalCode;
            customer.Customer_Country__c = acct[0].ShippingCountry;
		}
		else{
			customer.Customer_Street__c = acct[0].BillingStreet;
            customer.Customer_City__c = acct[0].BillingCity;
            customer.Customer_State__c = acct[0].BillingState;
            customer.Customer_Zip_Code__c = acct[0].BillingPostalCode;
            customer.Customer_Country__c = acct[0].BillingCountry;
		}
	}


}
