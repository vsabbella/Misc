public with sharing class SupplierExt {
    ApexPages.StandardController scon;
    public Supplier__c newSupplier;
    public Map<Id,RecordType> supplierRecordTypes {get;set;}
    public List<String> supplierStringFields {get;set;}
    public boolean error {get;set;}
    public boolean pageSubmitted {get;set;}
    public Map<String,String> errorMessages {get;set;}
    
    public string namespace {get;set;}

    public Account originalAccount; //holds the account values when the page is loaded, so we can compare and see if they changed on save
    
    public class SupplierExtException extends Exception{
    
    }
   
    public String recordTypeName {
        get {
            if(newSupplier.RecordTypeId != null && supplierRecordTypes.containsKey(newSupplier.RecordTypeId)) {
                return supplierRecordTypes.get(newSupplier.RecordTypeId).DeveloperName;
            }
            else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.No_Access_to_Supplier_record_types ));
                return null;
            }
        }
    }
   
    public SupplierExt(ApexPages.StandardController sc){
        try{
            namespace = KSE.NamespaceUU;
            SchemaUtil util = SchemaUtil.getInstance();
            String supplierType = namespace + 'Supplier__c';
            Schema.sObjectType sObjectType = Schema.getGlobalDescribe().get(supplierType);
            
            List<Schema.FieldSetMember> supplierFields = new List<Schema.FieldSetMember>();
            supplierFields.addAll(util.getFieldsFromFieldSet(sObjectType, 'New_Remit_To'));
            supplierFields.addAll(util.getFieldsFromFieldSet(sObjectType, 'New_Purchase_From'));
            supplierFields.addAll(util.getFieldsFromFieldSet(sObjectType, 'New'));
            
            supplierStringFields = new List<String>();
            
            for(Schema.FieldSetMember fsm : supplierFields) {
                supplierStringFields.add(fsm.getFieldPath());
            }
            
            supplierStringFields.add('Address__r.Name');
            supplierStringFields.add('Invoice_Matching__c');
            
            if (!Test.isRunningTest()) {
                sc.addFields(supplierStringFields);
            }
            
            scon = sc;
            newSupplier = (Supplier__c) scon.getRecord();
            
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('RecordType', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','DeveloperName'
			});
			soql.setWhereClause('sObjectType = :supplierType');
			
			supplierRecordTypes = new Map<Id,RecordType>((List<RecordType>)Database.query(soql.getQuery()));

            errorMessages = new Map<String,String>();
            Schema.DescribeSObjectResult dsr = Supplier__c.SObjectType.getDescribe();
            Schema.RecordTypeInfo defaultRecordType;
            for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
                if(rti.isDefaultRecordTypeMapping()) {
                    defaultRecordType = rti;
                }
            }
            
            if(ApexPages.CurrentPage().getParameters().containsKey('RecordType')) {
                newSupplier.RecordTypeId = ApexPages.CurrentPage().getParameters().get('RecordType');
            }
            
            if(newSupplier.RecordTypeId == null) {
                newSupplier.RecordTypeId = defaultRecordType.getRecordTypeId();
            }
            
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			Set<Id> newSupplierId = new Set<Id>{newSupplier.Id};
			
			soql = new SOQLUtil('Supplier__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'RecordTypeId'
			});
			soql.setWhereClause('Id IN :newSupplierId');
			
			List<Supplier__c> suppliers = Database.query(soql.getQuery());
			
			Id supplierRecordTypeId = suppliers.size() > 0 ? suppliers[0].RecordTypeId : null;
			
			if(newSupplier.Id != null && (Id) newSupplier.RecordTypeId != supplierRecordTypeId){
                newSupplier.Type__c = '';
            }
            
            //KNDY-11683
            /*if(newSupplier.Address__c == null){
                newSupplier.Address__r = new Account();
                //PTP-307: Account's type set to 'Supplier' when creating new supplier record
                newSupplier.Address__r.Type = 'Supplier';
            }
            
            if (originalAccount == null) {
                originalAccount = newSupplier.Address__r.clone(false, true);
            }*/
            
            // KNDY-2112: Set Supplier's Default Company as current user's company.
            // KNDY-4627: Set Supplier's Default Company as company from original Supplier record instead.
            if(newSupplier.Company__c == null) {
                UserPreference.getInstance().assignDefaultOrganization(newSupplier, UserInfo.getUserId());
            }
            // KNDY-12006: Set Supplier's Default Invoice Matching as Three Way.
            if(newSupplier.Invoice_Matching__c == null){
                newSupplier.Invoice_Matching__c = 'Three Way';
            }
        }catch(Exception e){
            ApexPages.addMessages(e);
        }
    }

    public PageReference save(){
        Savepoint sp = Database.setSavepoint();
            
        SchemaUtil util = SchemaUtil.getInstance();
        errorMessages = new Map<String,String>();
        Schema.sObjectType sObjectType = Schema.getGlobalDescribe().get(namespace+'Supplier__c');
    
        List<Schema.FieldSetMember> supplierDetailFields = new List<Schema.FieldSetMember>();
        
        if(recordTypeName == 'Purchase_From') {
            supplierDetailFields.addAll(util.getFieldsFromFieldSet(sObjectType, 'New_Purchase_From'));
        }
        else if(recordTypeName == 'Remit_To') {
            supplierDetailFields.addAll(util.getFieldsFromFieldSet(sObjectType, 'New_Remit_To'));
            newSupplier.Remit_To__c = null; 
        }
        else {
            supplierDetailFields.addAll(util.getFieldsFromFieldSet(sObjectType, 'New'));
        }
        error = false;
        pageSubmitted = true;
        for(Schema.FieldSetMember fsm : supplierDetailFields) {
            if((newSupplier.get(fsm.getFieldPath()) == null || newSupplier.get(fsm.getFieldPath()) == '')  && (fsm.getDBRequired() || fsm.getRequired())) {
                errorMessages.put(fsm.getFieldPath(),fsm.getLabel() + ':' + Label.Enter_a_value );
                error = true;
        
                if(error){
                    for(String e : errorMessages.values()) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(e)));
                    }
                }
            }
        }system.debug(LoggingLevel.ERROR, error);
        if(error) {
            return null;
        }
         
        PageReference pageRef;
        pageRef = scon.save(); //TODO: Catch and throw duplicate exception with a custom message.
        return pageRef;
    }
    
    
    public PageReference cloneSupplier(){
        Savepoint sp = Database.setSavepoint();
        try{
            // Clone the supplier
            newSupplier = newSupplier.clone(false, true);
            newSupplier.Supplier_Unique__c = null; // This will be assigned through a workflow rule.
            
            //if the address has been changed, create a new account/address and link to cloned supplier. otherwise link the cloned supplier to the same account/address
            Boolean addressChanged = false;
            if (originalAccount != null && newSupplier.Address__c != null) {
                if (originalAccount.BillingStreet != newSupplier.Address__r.BillingStreet) {
                    addressChanged = true;  
                }
                if (originalAccount.BillingCity != newSupplier.Address__r.BillingCity) {
                    addressChanged = true;  
                }
                if (originalAccount.BillingState != newSupplier.Address__r.BillingState) {
                    addressChanged = true;  
                }
                if (originalAccount.BillingPostalCode != newSupplier.Address__r.BillingPostalCode) {
                    addressChanged = true;  
                }   
                if (originalAccount.BillingCountry != newSupplier.Address__r.BillingCountry) {
                    addressChanged = true;  
                }                                           
            }
            
            if (addressChanged) {
                newSupplier.Address__r = newSupplier.Address__r.clone(false, true); // Copy address fields
                newSupplier.Address__r.Name = newSupplier.Name;
                //PTP-307
                newSupplier.Address__r.Type = 'Supplier';
                DML.insertAsUser(newSupplier.Address__r); // Insert the new address.   
            }
            
            
            if (newSupplier.Address__r != null && newSupplier.Address__r.Id != null){
                newSupplier.Address__c = newSupplier.Address__r.Id;
                newSupplier.Address__r.Type = 'Supplier';
               
            }
            
            DML.insertAsUser(newSupplier);
        }catch(Exception e){
            ApexPages.addMessages(e);
            Database.rollBack(sp);
            return null;
        }
        
        PageReference pageRef;
        pageRef = new PageReference('/'+newSupplier.Id); 
        return pageRef;
    }
    
}