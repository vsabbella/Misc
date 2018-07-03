public with sharing class CustomerNewExtension {

    public Customer__c customer {get;set;} {customer = new Customer__c(); }
    public Customer__c testCustomer {get;set;} {testCustomer = new Customer__c(); }
    
    //public Account theAccount {get; set; } { theAccount = new Account(); }
   
    public String corporate_recordtypeid {get;set;}
    public String RecordTypeDeveloperName {get;set;}
    public Boolean CopyFromParent {get;set;} {CopyFromParent = false; }
    
    public List<Customer__c> customers {get;set;} {customers = new List<Customer__c>(); }
    
    ApexPages.StandardSetcontroller con; 
    
    public List<Schema.FieldSetMember> customerFieldsNew { get; set; } {
        customerFieldsNew = new List<Schema.FieldSetMember>(); 
    }
    
    public List<Schema.FieldSetMember> readOnlyCustomerFields { get; set; } {
        readOnlyCustomerFields = new List<Schema.FieldSetMember>(); 
    }
  
    Map<String,String> CustomerRecordTypes;
    Map<Id,string> RecordType_Name ;  
    public CustomerNewExtension(Apexpages.standardController cust) 
    {
        
        CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');      // map from name -> id
        RecordType_Name = new Map<id,string>();                                             // map from id => rt name
        for ( string nam: CustomerRecordTypes.keySet() ) {  
            RecordType_Name.put( CustomerRecordTypes.get(nam), nam); 
        }
        
        corporate_recordtypeid = CustomerRecordTypes.get('Corporate_Parent');
        Customer__c parentCustomer = new Customer__c();
        Id topParentId;
        if(cust.getRecord()!=null){
            parentCustomer = (Customer__c) cust.getRecord();
            if(parentCustomer.Id != null){
                Customer__c tmpCust = [SELECT Id, top_parent_customer__c FROM Customer__c WHERE Id = :parentCustomer.Id];
                customer.top_parent_customer__c = tmpCust.top_parent_customer__c;
            }
        }
        
        if(parentCustomer.recordtypeid != null){
            
            if(RecordType_Name.get(parentCustomer.recordtypeid) =='Corporate_Parent'){
                customer.recordtypeid = CustomerRecordTypes.get('Bill_To');
            }
            else if(RecordType_Name.get(parentCustomer.recordtypeid) =='Bill_To'){
                customer.recordtypeid = CustomerRecordTypes.get('Sold_To');
            }
            else if(RecordType_Name.get(parentCustomer.recordtypeid) =='Sold_To'){
                customer.recordtypeid = CustomerRecordTypes.get('Ship_To');
            }
            else if(RecordType_Name.get(parentCustomer.recordtypeid) =='Ship_To'){
                customer.recordtypeid = CustomerRecordTypes.get('Site');
            }
            customer.parent_customer__c = parentCustomer.id;
        }
            
    }
    
    public void generateCustomerFields(){
        
        if(customer.Recordtypeid!=null){
            
            Map<String, Schema.FieldSet> FieldsetMap =Schema.SObjectType.Customer__c.fieldSets.getMap();
            
            if ( RecordTypeDeveloperName == 'Corporate_Parent') {
                
                customerFieldsNew =  FieldsetMap.get( KSE.NamespaceUU + 'Customer_Fields').getFields();
                //readOnlyCustomerFields.addAll(FieldsetMap.get( namespace + 'Read_Only_Fields').getFields());
            
            } else if ( RecordTypeDeveloperName == 'Bill_To') {
                
                customerFieldsNew =  FieldsetMap.get( KSE.NamespaceUU + 'Bill_To_Fields').getFields();
                //readOnlyCustomerFields.addAll(FieldsetMap.get( namespace + 'Read_Only_Fields').getFields());
            
            } else if ( RecordTypeDeveloperName == 'Sold_To') {
                
                customerFieldsNew = FieldsetMap.get( KSE.NamespaceUU + 'Sold_To_Fields').getFields();
                //readOnlyCustomerFields.addAll(FieldsetMap.get( namespace + 'Read_Only_Fields').getFields());
            
            } else if ( RecordTypeDeveloperName == 'Ship_To') {
                
                customerFieldsNew = FieldsetMap.get( KSE.NamespaceUU + 'Ship_To_Fields').getFields();
                //readOnlyCustomerFields.addAll(FieldsetMap.get( namespace + 'Read_Only_Fields').getFields());
            } else if ( RecordTypeDeveloperName == 'Site') {
                
                customerFieldsNew = FieldsetMap.get( KSE.NamespaceUU + 'Site_Fields').getFields();
                //readOnlyCustomerFields.addAll(FieldsetMap.get( namespace + 'Read_Only_Fields').getFields());
            }
            
        }
        
    }
    
    public List<selectOption> getRecordTypes() {
        List<selectOption> options = new List<selectOption>(); 
        
        //options.add(new selectOption('','--Select--'));
        Schema.DescribeSObjectResult custDescribe = Customer__c.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> recTypes = custDescribe.getRecordTypeInfos();
        map<Id, string> mRecTypeNames = new map<Id, string>();
        for(Schema.RecordTypeInfo rti : recTypes){
            mRecTypeNames.put(rti.getRecordTypeId(), rti.getName());
        }
        options.add(new selectOption(CustomerRecordTypes.get('Corporate_Parent'), mRecTypeNames.get(CustomerRecordTypes.get('Corporate_Parent')))); 
        options.add(new selectOption(CustomerRecordTypes.get('Bill_To'), mRecTypeNames.get(CustomerRecordTypes.get('Bill_To'))));
        options.add(new selectOption(CustomerRecordTypes.get('Sold_To'), mRecTypeNames.get(CustomerRecordTypes.get('Sold_To'))));
        options.add(new selectOption(CustomerRecordTypes.get('Ship_To'), mRecTypeNames.get(CustomerRecordTypes.get('Ship_To'))));
        options.add(new selectOption(CustomerRecordTypes.get('Site'), mRecTypeNames.get(CustomerRecordTypes.get('Site'))));
        return options; 
    }
    
    public Pagereference doSave() {
        
        //KNDY-15842: Account to customer - check if a corp parent already exists for the account company combination
        if (customer.RecordtypeId == CustomerRecordTypes.get('Corporate_Parent')){
            if (CustomerService.checkforExistingCorpParent(customer)){
    			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,Label.Cannot_create_corp_parent_customer);
        		ApexPages.addMessage(myMsg);
        		return null;
    		}    
        }
            
        Savepoint sp = Database.setSavepoint();
        try{
            if(!CopyFromParent){
                //theAccount.Name = customer.Name;
                //theAccount.Type = 'Customer';   // OTC-521 Setting the default value to Customer
                //DML.sobjectInsertObjectAndFields(new list<sobject>{ theAccount });
                //customer.address__c = theAccount.id;
            }
            
            /*if( RecordTypeDeveloperName != 'Corporate_Parent' ){ // populates the corporate parent on customers below the corporate parent
                Customer__c corpCustomer = (Customer__c) ChangeRequestService.findTop(customer);
                customer.corporate_parent__c = corpCustomer.id;
            }*/
            
            DML.insertAsUser(new list<sobject>{ customer });
                      
        }
        catch(System.DmlException e){
            
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getDmlMessage(0))) );
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getDmlMessage(0) + ' ' + e.getStackTraceString());
            Database.rollback(sp);
            //theAccount = theAccount.clone(false);
            customer = customer.clone(false);
            return null;
            
        }
        PageReference p = new Pagereference('/'+customer.id);
        
        return ( ApexPages.hasMessages() ? null : p );
    }

    public PageReference doContinue(){
        
        Customer__c parentCustomer = new Customer__c();
        if(RecordTypeDeveloperName==null)
        RecordTypeDeveloperName = RecordType_Name.get(customer.RecordtypeId);
        if ( RecordTypeDeveloperName != 'Corporate_Parent') {
            if(customer.parent_customer__c == null && customer.Top_Parent_Customer__c == null){
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.You_must_specify_a_parent_customer));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must specify a Parent Customer or Top Parent Customer.'));    
            }else if(customer.parent_customer__c != null){

                parentCustomer = [Select recordtype.DeveloperName,
                                         address__c,
                                         Zip_Code__c,
                                         Customer_Street__c,
                                         Customer_Street_1__c,
                                         Customer_Street_2__c,
                                         City__c,
                                         State__c, 
                                         Country__c, 
                                         company__c, 
                                         top_parent_customer__c
                                    from Customer__c 
                                   where id=:customer.parent_customer__c];

            //    System.debug('check this'+parentCustomer.recordtype.DeveloperName+RecordTypeDeveloperName);
                if(RecordTypeDeveloperName == 'Bill_To' && parentCustomer.recordtype.DeveloperName != 'Corporate_Parent')
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Only_CorporateParentCustomer_can_be_parent_to_BillToCustomer));
                else if(RecordTypeDeveloperName == 'Sold_To' && parentCustomer.recordtype.DeveloperName != 'Bill_To')
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Only_BillToCustomer_can_be_a_parent_to_a_SoldToCustomer)); 
                else if(RecordTypeDeveloperName == 'Ship_To' && parentCustomer.recordtype.DeveloperName != 'Sold_To')
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Only_SoldToCustomer_can_be_a_parent_to_a_ShipToCustomer)); 
                else if(RecordTypeDeveloperName == 'Site' && parentCustomer.recordtype.DeveloperName != 'Ship_To')
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only Ship To Customers can be a parent to a Site')); 
                
                if(customer.top_parent_customer__c != null && parentCustomer.top_parent_customer__c != customer.top_parent_customer__c){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Top Parent Customer must match the Parent Customer\'s Top Parent. Please leave blank to accept the default.')); 
                }
                
                if(CopyFromParent){
                    //customer.address__c = parentCustomer.address__c;
                    
                    //theAccount.BillingStreet = parentCustomer.Street__c;
                    //theAccount.BillingCity = parentCustomer.City__c;
                    //theAccount.BillingState = parentCustomer.State__c;
                    //theAccount.BillingPostalCode = parentCustomer.Zip_Code__c;
                    customer.Customer_Street__c = parentCustomer.Customer_Street__c;
                    customer.Customer_Street_1__c = parentCustomer.Customer_Street_1__c;
                    customer.Customer_Street_2__c = parentCustomer.Customer_Street_2__c;
                    customer.Customer_City__c = parentCustomer.City__c;
                    customer.Customer_State__c = parentCustomer.State__c;
                    customer.Customer_Zip_Code__c = parentCustomer.Zip_Code__c;
                    customer.Customer_Country__c = parentCustomer.Country__c;

                }
                
                customer.company__c = parentCustomer.company__c;
                 if(RecordTypeDeveloperName == 'Sold_To'){                  
                    //get the default value of the Price Determination Date picklist                
                    for (Schema.PicklistEntry p : Customer__c.Price_Determination_Date__c.getDescribe().getPicklistValues()) {
                        if (p.isDefaultValue()) {
                            customer.Price_Determination_Date__c = p.getValue();
                        }
                    }   
                 }
            }else if(customer.top_parent_customer__c != null && customer.parent_customer__c == null){

                parentCustomer = [Select recordtype.DeveloperName,
                                         address__c,
                                         Zip_Code__c,
                                         Customer_Street__c,
                                         Customer_Street_1__c,
                                         Customer_Street_2__c,
                                         City__c,
                                         State__c, 
                                         Country__c, 
                                         company__c 
                                    from Customer__c 
                                   where id=:customer.top_parent_customer__c];

                if(CopyFromParent){
                    //customer.address__c = parentCustomer.address__c;
                    
                    //theAccount.BillingStreet = parentCustomer.Street__c;
                    //theAccount.BillingCity = parentCustomer.City__c;
                    //theAccount.BillingState = parentCustomer.State__c;
                    //theAccount.BillingPostalCode = parentCustomer.Zip_Code__c;

                    customer.Customer_Street__c = parentCustomer.Customer_Street__c;
                    customer.Customer_Street_1__c = parentCustomer.Customer_Street_1__c;
                    customer.Customer_Street_2__c = parentCustomer.Customer_Street_2__c;
                    customer.Customer_City__c = parentCustomer.City__c;
                    customer.Customer_State__c = parentCustomer.State__c;
                    customer.Customer_Zip_Code__c = parentCustomer.Zip_Code__c;
                    customer.Customer_Country__c = parentCustomer.Country__c;
                }
                
                customer.company__c = parentCustomer.company__c;  
                if(RecordTypeDeveloperName == 'Sold_To'){                   
                    //get the default value of the Price Determination Date picklist                
                    for (Schema.PicklistEntry p : Customer__c.Price_Determination_Date__c.getDescribe().getPicklistValues()) {
                        if (p.isDefaultValue()) {
                            customer.Price_Determination_Date__c = p.getValue();
                        }
                    }   
                 }
            }
        
        }else{
            customer.parent_customer__c = null ;
            customer.company__c = CompanyService.getDefaultCompanyID();
            CopyFromParent = false;
        }
        
        generateCustomerFields();
        if(!ApexPages.hasMessages()){
            PageReference pageRef = Page.CustomerNew;
            pageRef.setRedirect(false);
            return pageRef;
        }
        else
            return null;
    }
    
    public Pagereference doCancel() {
        Schema.DescribeSObjectResult dsr = Customer__c.SObjectType.getDescribe();
        return new Pagereference('/'+dsr.getKeyPrefix()+'/o');
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
                //theAccount.BillingCountry = Label.US;  

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
    
   /*  public PageReference showAddressPopup() {
        
        displayAddressPopup = true;
        customer.Address_Validated__c = false;
        customer.address_validation_overriden__c = false;
        return null;
        
     } 
     
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
    
  /*  public PageReference overrideAddress() {
        
        //displayOverride = false;
        displayAddressPopup = false;
        customer.address_validation_overriden__c = true;
       customer.Address_Validated__c = false;
        
            
        return null;    
    }
    
    public PageReference showPopup() { 
        
        try{
            
        List<Customer__c> customersList = new List<Customer__c>();
        displayPopup = true;
    
        if(customer.Name != null){
            String name = '%'+customer.name+'%';
            customersList = [select id,name,Company__r.Name,Street__c,City__c,Status__c,State__c,Zip_Code__c from Customer__c where name like :name];
        
            if(customersList.size()==0){
                
                customersList = [select id, name, Company__r.Name, Street__c, City__c, Status__c, State__c, Zip_Code__c from Customer__c 
                                where Street__c  =:theAccount.BillingStreet and city__c =:theAccount.BillingCity and state__c =:theAccount.BillingState 
                                and (Street__c != null or city__c !=null or state__c != null) ];
                
                displayText = 'Possible Duplicates By Address:';
                customers.addAll(customersList);
            }
            else{
                displayText = 'Possible Duplicates By Name:';
                for(customer__c c : customersList){
                    if(c.name == customer.name )
                        customers.add(c);
                }   
                if(customers.size()==0)
                    customers.addAll(customersList);
            }
                        
            if(customers.size()==0) 
                displayText = 'No Duplicates Found!';
            
                
        }
        else{
            displayText = 'Please enter the Customer Name';
        }
        
        return null;
        }
        catch(System.DmlException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
            return null;
        }
    
    }
    
    public void closePopup() {
        
        displayPopup = false;
        customers=new List<Customer__c>();
    }*/
  
}