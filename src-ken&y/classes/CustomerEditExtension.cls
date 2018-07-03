public with sharing class CustomerEditExtension {
	
	public Customer__c customer {get;set;} {customer = new Customer__c(); }
    public Customer__c changedCustomer {get;set;} {changedCustomer = new Customer__c(); }
    public Customer__c oldCustomer = new Customer__c();
    
    public Contact theContact {get; set; } { theContact = new Contact(); }
    public Contact changedContact {get; set; } { changedContact = new Contact(); } 
    public Contact oldContact = new Contact();
    
    public Account theAccount {get; set; } { theAccount = new Account(); }
    public Account changedAccount {get; set; } { changedAccount = new Account(); } 
    public Account oldAccount = new Account();

    public Boolean showApproveButton { get; set; }
    public String pageMode { get; set; }
    private String namespace = Kse.NamespaceUU;
    
    public static map<String,Schema.DisplayType> fieldSetMemberTypeMap = new Map<String,Schema.DisplayType>();
    public map<String,Schema.FieldSetMember> nonUpdateableMap = new map<String,Schema.FieldSetMember>();
    
    public List<Customer__c> customersList = new List<Customer__c>();
    
    public Set<String> ChangedFields = new Set<String>();
    public Set<String> ChangedAddressFields = new Set<String>();
    public Set<String> ChangedContactFields = new Set<String>();
    public Set<String> ContactFields = new Set<String>();
    public Set<String> AccountFields = new Set<String>();
    
    public Boolean displayPopup {get;set;}
    //public Boolean displayAddressPopUp {get;set;}
    public String displayText{get;set;}
    public String sectionHeaderText{get;set;} {sectionHeaderText = Label.Edit_Customer;}
    
    public List<Customer__c> customers {get;set;} {customers = new List<Customer__c>(); }
    
    private final static String PGE_MODE_EDIT = 'edit';
    private final static String PGE_MODE_CLONE = 'clone';

    public List<Schema.FieldSetMember> customerFields { get; set; } {
        customerFields = new List<Schema.FieldSetMember>(); 
    } 
    
    /*public List<Schema.FieldSetMember> readOnlyCustomerFields { get; set; } {
        readOnlyCustomerFields = new List<Schema.FieldSetMember>(); 
    }*/
    
    
    public CustomerEditExtension(Apexpages.standardController cust)
    {
        
        if ( cust.getRecord().Id != null ) {
        	Id recordTypeId = Apexpages.currentPage().getParameters().get('RecordType');
            customer = (Customer__c) getRecordById( cust.getRecord().Id );
            pageMode = CustomerEditExtension.PGE_MODE_EDIT;

            if(customer.Status__c == CustomerService.CUST_STATUS_APPROVED){
                showApproveButton = false;
            } else {
                showApproveButton = true;
            }

            if(recordTypeId != null){
            	customer.recordTypeId = recordTypeId;
            }
        }
        
        if( ApexPages.currentPage().getParameters().get('clone') == '1' ){
        	
        	sectionHeaderText = Label.Clone_Customer;
        	customer = customer.clone( false, true );
        	customer.Customer_Identifier__c = null;
            pageMode = CustomerEditExtension.PGE_MODE_CLONE;
        }
        
        Map<String, Schema.FieldSet> FieldsetMap =Schema.SObjectType.Customer__c.fieldSets.getMap();
        
        
        if ( customer.RecordType.DeveloperName == 'Corporate_Parent') {
            customerFields =  FieldsetMap.get( namespace + 'Customer_Fields').getFields();
            //readOnlyCustomerFields = FieldsetMap.get( namespace + 'Read_Only_Fields').getFields();
        } else if ( customer.RecordType.DeveloperName == 'Bill_To') {
            customerFields =  FieldsetMap.get( namespace + 'Bill_To_Fields').getFields();
           // readOnlyCustomerFields = FieldsetMap.get( namespace + 'Read_Only_Fields').getFields();
        } else if ( customer.RecordType.DeveloperName == 'Sold_To') {
            customerFields = FieldsetMap.get( namespace + 'Sold_To_Fields').getFields();
          //  readOnlyCustomerFields = FieldsetMap.get( namespace + 'Read_Only_Fields').getFields();
        } else if ( customer.RecordType.DeveloperName == 'Ship_To') {
            customerFields = FieldsetMap.get( namespace + 'Ship_To_Fields').getFields();
          //  readOnlyCustomerFields = FieldsetMap.get( namespace + 'Read_Only_Fields').getFields();
        }else if ( customer.RecordType.DeveloperName == 'Site') {
            customerFields = FieldsetMap.get( namespace + 'Site_Fields').getFields();
          //  readOnlyCustomerFields = FieldsetMap.get( namespace + 'Read_Only_Fields').getFields();
        }
        
        for(Integer i=0;i<customerFields.size();i++){
            
            if(nonUpdateableMap.containsKey(customerFields[i].getFieldPath())){
                customerFields.remove(i);
            }
        }
        
        
        //if ( customer.Address__r == null ) {    
        //    theAccount = new Account(); 
        //}
        //else
        //    theAccount = customer.Address__r;
        
        
   /*     if ( customer.Contact__r == null ) {    uncomment when contacts are needed for customers in the package.
            theContact = new Contact(); 
        }
        else
            theContact = customer.Contact__r;
        */
        
        if( ApexPages.currentPage().getParameters().get('clone') != '1' ){
        changedCustomer = customer.clone(true,true);
        //changedAccount = theAccount.clone(true,true);
        changedContact = theContact.clone(true,true);
        oldCustomer = customer.clone(true,true);
        oldAccount = oldCustomer.address__r;
    }
        //else{
        //  oldAccount = theAccount.clone(true,true);
        //}
    }
    
    public Sobject getRecordById( id p) {
        Set<String> fieldpaths = new Set<String>(this.fieldList.split(','));
        SOQLUtil soql = new SOQLUtil('Customer__c', TRUE);
        soql.addFields(fieldpaths);
        soql.setWhereClause('id = :p');
        soql.setLimit(1);
        return Database.query(soql.getQuery());
    } 


    private string fieldList { get { 
        if (fieldList == null ) { 
                    
            Set<String> fieldset = new Set<String>{ 'Parent_Customer_Identifier__c', 
                                                    'Customer_Identifier__c',
                                                    'Name',  
                                                    'Parent_Customer__c' , 
                                                    'RecordType.DeveloperName', 
                                                    'RecordType.Name',
                                                    'RecordTypeId', 
                                                    'Address__r.Name', 
                                                    'Id',
                                                    'Status__c',
                                                    'Customer_Street__c',
                                                    'Customer_Street_1__c',
                                                    'Customer_Street_2__c',
                                                    'Customer_City__c',
                                                    'Customer_State__c',
                                                    'Customer_Zip_Code__c',
                                                    'Customer_Country__c'
                                                };
            
            //, 'Contact__r.LastName',
              //  'Customer_Type__c'
              //,'Customer_Type__c''Corporate_Parent_Identifier__c',
            
            Map<String, Schema.FieldSet> FieldsetMap =Schema.SObjectType.Customer__c.fieldSets.getMap();
            
            //KNDY-7410
            //Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Customer__c.fields.getMap();
            SchemaUtil util = SchemaUtil.getInstance();
            Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(Schema.SObjectType.Customer__c.fields.getMap());                      
            
            for(Schema.FieldSetMember f : FieldsetMap.get( namespace + 'Bill_To_Fields').getFields() ) { 
                 
                
                Schema.SObjectField field   = fieldsMap.get(f.getFieldPath().replace(namespace,''));
                
                if(field.getDescribe().isUpdateable()){   
                
                    fieldset.add ( f.getFieldPath().replace(namespace,'') );
                    fieldSetMemberTypeMap.put(f.getFieldPath().replace(namespace,''),f.getType());
                }
                else{
                    nonUpdateableMap.put(f.getFieldPath(),f);
                }
            }
            
            for(Schema.FieldSetMember f : FieldsetMap.get( namespace + 'Sold_To_Fields').getFields() ) {    
                Schema.SObjectField field   = fieldsMap.get(f.getFieldPath().replace(namespace,''));
                
                if(field.getDescribe().isUpdateable()){   
                
                    fieldset.add ( f.getFieldPath().replace(namespace,'') );
                    fieldSetMemberTypeMap.put(f.getFieldPath().replace(namespace,''),f.getType());
                }
                else{
                    nonUpdateableMap.put(f.getFieldPath(),f);
                }
            } 
            
            for(Schema.FieldSetMember f : FieldsetMap.get( namespace + 'Ship_To_Fields').getFields() ) {    
                Schema.SObjectField field   = fieldsMap.get(f.getFieldPath().replace(namespace,''));
                
                if(field.getDescribe().isUpdateable()){   
                
                    fieldset.add ( f.getFieldPath().replace(namespace,'') );
                    fieldSetMemberTypeMap.put(f.getFieldPath().replace(namespace,''),f.getType());
                }
                else{
                    nonUpdateableMap.put(f.getFieldPath(),f);
                }
            }
            
            for(Schema.FieldSetMember f : FieldsetMap.get( namespace + 'Customer_Fields').getFields() ) {    
                Schema.SObjectField field   = fieldsMap.get(f.getFieldPath().replace(namespace,''));
                
                if(field.getDescribe().isUpdateable()){   
                
                    fieldset.add ( f.getFieldPath().replace(namespace,'') );
                    fieldSetMemberTypeMap.put(f.getFieldPath().replace(namespace,''),f.getType());
                }
                else{
                    nonUpdateableMap.put(f.getFieldPath(),f);
                }
            }
            
            for(Schema.FieldSetMember f : FieldsetMap.get( namespace + 'Site_Fields').getFields() ) {    
                Schema.SObjectField field   = fieldsMap.get(f.getFieldPath().replace(namespace,''));
                
                if(field.getDescribe().isUpdateable()){   
                
                    fieldset.add ( f.getFieldPath().replace(namespace,'') );
                    fieldSetMemberTypeMap.put(f.getFieldPath().replace(namespace,''),f.getType());
                }
                else{
                    nonUpdateableMap.put(f.getFieldPath(),f);
                }
            }
            
          /*  for(Schema.FieldSetMember f : FieldsetMap.get( namespace + 'Read_Only_Fields').getFields() ) {    
                Schema.SObjectField field   = fieldsMap.get(f.getFieldPath().replace(namespace,''));
                
                if(field.getDescribe().isUpdateable()){   
                
                    fieldset.add ( f.getFieldPath().replace(namespace,'') );
                    fieldSetMemberTypeMap.put(f.getFieldPath().replace(namespace,''),f.getType());
                }
                else{
                    nonUpdateableMap.put(f.getFieldPath(),f);
                }
            }*/
            
            for(Schema.FieldSetMember f : FieldsetMap.get( namespace + 'Customer_Address_Fields').getFields() ) {    
 
                    fieldset.add ( f.getFieldPath().replace(namespace,'') );
                    fieldSetMemberTypeMap.put(f.getFieldPath().replace(namespace,''),f.getType());
                    
                    AccountFields.add( f.getFieldPath().replace(namespace+'Address__r.','') );
            }
            
          /*  for(Schema.FieldSetMember f : FieldsetMap.get( namespace + 'Customer_Contact_Fields').getFields() ) {    
 
                    fieldset.add ( f.getFieldPath().replace(namespace,'') );
                    fieldSetMemberTypeMap.put(f.getFieldPath().replace(namespace,''),f.getType());
                    
                    ContactFields.add( f.getFieldPath().replace(namespace+'Contact__r.','') );
            }*/
            
            
            
            List<STring > tmp = new List<String>(fieldset);
            fieldList = String.join( tmp, ',' );
            
        } return fieldList; 
    }  set; }
    
    public Pagereference doSave() {
        
        List<Customer__c> newCustomer = new List<Customer__c>();
        newCustomer.add(customer);
        //Map<Id,Customer__c> oldCustomerMap = new Map<Id,Customer__c>();
        //oldCustomerMap.put(oldCustomer.Id,oldCustomer);
        
       /* if(!CustomerNew.isEmpty(theContact)){  uncomment when customer has contact relationship
            
            if(theContact.name__c == null){
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please specify a name for the contact'));
                return null;
            }
                
        }*/
        
        //KNDY-1774 - Security: CustomerEditExtension must check FLS and CRUD on all DML
        try{
                if(this.pageMode == CustomerEditExtension.PGE_MODE_EDIT){
                    DML.updateAsUser(newCustomer);
                } else{
                    DML.insertAsUser(newCustomer);
                }

        }catch(Exception ex){
        		Apexpages.addMessages(ex); 
        }
        
        
       
        PageReference p = new Pagereference('/'+customer.id);
        return ( ApexPages.hasMessages() ? null : p );
    }

    public static Map<Id, List<Customer__c>> getRelatedCustomers(Customer__c customer){

        Map<Id, List<Customer__c>> childCustomers = new Map<Id, List<Customer__c>>();

        if(customer != null){

            Id topParentCustomer = customer.RecordType.DeveloperName == CustomerService.CUST_TYPE_CORP_PARENT ? customer.Id : customer.Top_Parent_Customer__c;

            Set<String> customerFields = new Set<String>{
                    'Top_Parent_Customer__c',
                    'Parent_Customer__c',
                    'Id',
                    'Status__c'
                };

            SOQLUtil soql = new SOQLUtil('Customer__c', TRUE);
            soql.addFields(customerFields);
            soql.setWhereClause('Top_Parent_Customer__c = :topParentCustomer');

            List<Customer__c> customers = Database.query(soql.getQuery());

            if(customers.size() > 0){
                for (Customer__c cust: customers) {
                    List<Customer__c> tCusts;

                    if(childCustomers.containsKey(cust.Parent_Customer__c)){
                        tCusts = childCustomers.get(cust.Parent_Customer__c);

                    } else{
                        tCusts = new List<Customer__c>();

                    }

                    tCusts.add(cust);
                    childCustomers.put(cust.Parent_Customer__c, tCusts);
                }
            }
        }

        return childCustomers;
    }

    public static List<Customer__c> updateCustStatus(Map<Id, List<Customer__c>> relatedCustomers,
                                                     Customer__c customer,
                                                     String status){

        List<Customer__c> customers = new List<Customer__c>();

        customer.Status__c  = status;
        customers.add(customer);

        if(relatedCustomers.containsKey(customer.Id)){

            List<Customer__c> tCustomers = relatedCustomers.get(customer.Id);

            for(Customer__c cust : tCustomers){
                cust.Status__c = status;

                if(relatedCustomers.containsKey(cust.Id)){
                    customers.addAll(updateCustStatus(relatedCustomers, cust, status));
                } else {
                    customers.add(cust);
                }
            }
        }

        return customers;
    }

    public PageReference approve(){

        List<Customer__c> customersToApprove = new List<Customer__c>();

        if(customer.Id != null){
            //Approval Process
            Map<Id, List<Customer__c>> relatedCustomers = CustomerEditExtension.getRelatedCustomers(customer);

            customersToApprove = updateCustStatus(relatedCustomers, customer, CustomerService.CUST_STATUS_APPROVED);

            DML.updateAsUser(customersToApprove);
        }

        return new Pagereference('/'+customer.id);
    }

    public PageReference deactivate(){

        List<Customer__c> customersToDeactivate = new List<Customer__c>();

        if(customer.Id != null){

            //Deactivate Process
            Map<Id, List<Customer__c>> relatedCustomers = CustomerEditExtension.getRelatedCustomers(customer);

            customersToDeactivate = updateCustStatus(relatedCustomers, customer, CustomerService.CUST_STATUS_INACTIVE);

            DML.updateAsUser(customersToDeactivate);
        }

        return new Pagereference('/'+customer.Id);

    }

    public Pagereference doCancel() {
        
        if( customer.id != null ) { 
			return new Pagereference('/'+customer.id);
        }
        else{
			PageReference prRef;
			if( apexPages.currentPage().getParameters().get('retUrl') != null ){
				
				prRef = new PageReference('/' + apexPages.currentPage().getParameters().get('retUrl') );	
    			}
			else{
    
				Schema.DescribeSObjectResult dsr = Customer__c.SObjectType.getDescribe();
				prRef = new PageReference('/' + dsr.getKeyPrefix());			
			}		
			
			prRef.setRedirect(true);
			return prRef;
        }	
    }
    
     public PageReference lookupZipcode() { 
        try { 
            ZipcodeLookup.getUsername();
            //List<String> AddressString = ZipcodeLookup.callApiWithRequest(theAccount.id, null, theAccount.BillingStreet, theAccount.BillingCity, theAccount.BillingState);
            List<String> AddressString = ZipcodeLookup.callApiWithRequest(customer.id, null, customer.Customer_Street__c, customer.Customer_City__c, customer.Customer_State__c);

            if(AddressString != null){
                
                //theAccount.BillingStreet = AddressString[0];
                //theAccount.BillingCity = AddressString[1];
                //theAccount.BillingState = AddressString[2];
                //theAccount.BillingPostalCode = AddressString[3];
                //theAccount.BillingCountry = 'US';  
                //displayAddressPopUp = false;
                //customer.Address_Validated__c = true;
                //customer.address_validation_overriden__c = false;

                customer.Customer_Street__c = AddressString[0];
                customer.Customer_City__c = AddressString[1];
                customer.Customer_State__c = AddressString[2];
                customer.Customer_Zip_Code__c = AddressString[3];
                customer.Customer_Country__c = Label.US;  
                 
            }
        } catch ( Exception e) {
            
            ApexPages.addMessages( e );
             
        }
        
       
        return null;
    }
    
  /*   public PageReference showAddressPopup() {
        
        displayAddressPopup = true;
        customer.Address_Validated__c = false;
        customer.address_validation_overriden__c = false;
        return null;
        
     } */
     
    /* public PageReference closeAddressPopup() {
        
        System.debug('in Cancel0' + theAccount.BillingStreet  + theAccount.BillingCity  + theAccount.BillingState + theAccount.BillingPostalCode);
        
        theAccount.BillingStreet = null;
        theAccount.BillingCity = null;
        theAccount.BillingState = null;
        theAccount.BillingPostalCode = null;
        customer.address_validation_overriden__c = false;
        
        //displayOverride = false;
        displayAddressPopup = false;
        
        System.debug('in Cancel' + theAccount.BillingStreet  + theAccount.BillingCity  + theAccount.BillingState + theAccount.BillingPostalCode);
        
        return null;
    }*/
    
   /* public PageReference overrideAddress() {
        
        //displayOverride = false;
        displayAddressPopup = false;
        customer.address_validation_overriden__c = true;
        customer.Address_Validated__c = false;
        
            
        return null;    
    }*/
    
   
    
    public PageReference showPopup() {
        
        //try{
            
        //    //Map<String, Schema.SObjectField> AccountFields = Schema.SObjectType.Account.fields.getMap();
        //    //Map<String, Schema.SObjectField> ContactFields = Schema.SObjectType.Contact.fields.getMap();
            
        ///*    for(Schema.FieldSetMember f : customerFields){
        //        if(customer.get(f.FieldPath) != oldCustomer.get(f.FieldPath)){
        //            changedFields.add(f.FieldPath);
        //        }
        //    }
            
        //    for(Schema.FieldSetMember f : readOnlyCustomerFields){
        //        if(customer.get(f.FieldPath) != oldCustomer.get(f.FieldPath)){
        //            changedFields.add(f.FieldPath);
        //        }
        //    }*/
            
        //    //KNDY-2786
        //    AccountFields.remove(null);
        //    AccountFields.remove('');
        //    if(theAccount != null && oldAccount != null){
           //     for(String addressFields : AccountFields){
    
           //         if(theAccount.get(addressFields) != oldAccount.get(addressFields)){
           //             ChangedAddressFields.add(addressFields);
           //         }
           //     }
        //    }
            
        //    for( String contactFieldName : ContactFields ){
            
        //        if( theContact.get( contactFieldName ) != oldContact.get( contactFieldName )){
                    
        //            contactFieldName = contactFieldName;
                    
        //            ChangedContactFields.add( contactFieldName );
        //        }
            
                
        //    }
            
        //    if(ChangedAddressFields.size()>0)
        //    {
                
        //        customersList = [select id,name,Company__r.Name,recordtypeid, Recordtype.DeveloperName, Recordtype.Name,Parent_Customer__c,Street__c,City__c,Status__c,State__c,Zip_Code__c,address__c from Customer__c where address__c =:customer.address__c];
        //    }
        //    if( ( customersList.size()>1 ) || ( customersList.size() == 1 && ApexPages.currentPage().getParameters().get('clone') == '1' )){
        //        customers.addAll(customersList);
        //        for(Integer i=0; i<customersList.size();i++){
        //            if(customersList[i].id == customer.id)
        //                customersList.remove(i);
        //        }
        //        displayPopup = true;
        //        displayText = Label.Address_change_will_affect_addresses_of_following_customers;

        //    }
        //    else{
                
        //        displayPopup = false;
        //        //KNDY-1774 - Security: CustomerEditExtension must check FLS and CRUD on all DML
        //        try{
        //          DML.allowUpsertObjectAndFields(new List<sObject>{theAccount});
        //          upsert theAccount;
        //          PageReference pageRefSave = doSave();
        //          return ( ApexPages.hasMessages() ? null : pageRefSave);
        //        }catch(Exception ex){
        //          Apexpages.addMessages(ex); 
        //          return null;
        //        }
        //    }       
        
            return null;
        //}
        //catch(System.DmlException e){
        //    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        //    return null;
        //}
    
    }
    
    public PageReference unLinkAddress() {
        
        //displayPopup = false;
     //   //KNDY-1774 - Security: CustomerEditExtension must check FLS and CRUD on all DML
     //   try{
     //     Account newAcc = theAccount.clone(false,true);
        //    if(newAcc.unlink_count__c == null)
        //        newAcc.unlink_count__c = 1;
        //    else
        //        newAcc.unlink_count__c += 1;
                
        //    newAcc.Address_Key__c ='temporary'; 
        //    System.debug('addressKeyCheck'+newAcc.address_key__c+'&'+oldAccount.address_key__c+'&'+newAcc.unlink_count__c);
        //    System.debug('addressKeyCheck1'+oldAccount.address_key__c+theAccount.address_key__c+newAcc.address_key__c);
            
        //    DML.sobjectInsertObjectAndFields(new List<sObject>{newAcc});
        //    //Customer__c address_link_change_customer = new Customer__c(id=customer.id);
            
        //    DML.allowUpsert( new List<sObject>{customer});
        //    customer.address__c = newAcc.id;
        //    upsert customer;
            
        //    //changedFields.add(ChangeRequestService.Namespace+'__'+'Address__c');
        //    PageReference pageRefSave = doSave();
        //    return pageRefSave;
            
     //   } catch(Exception ex) {
        //      Apexpages.addMessages(ex); 
                return null;
     //   }
        
    }
    
    public PageReference continueSave(){
        
        displayPopup = false;
        //KNDY-1774 - Security: CustomerEditExtension must check FLS and CRUD on all DML
        try{
            //DML.checkUpsertAsUser(new List<sObject>{theAccount});
            //upsert theAccount;
            Customer__c dummyCustomer= new Customer__c();
            Set<String> dummySet = new Set<String>();
            PageReference pageRefSave = doSave();
            return pageRefSave;
        }catch(Exception ex){
	        	Apexpages.addMessages(ex); 
	        	return null;
        }
        
    }
    
    public void closePopup() {
        displayPopup = false;
        customers=new List<Customer__c>();
    }
    
        
    
}