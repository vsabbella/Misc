public with sharing class CompanyService {
    public static Boolean allowAutoPlanPickUpdate = false;

    public static Map<Id, Company__c> setAutoPlanPick(Set<Id> companyIds, Set<Id> recordIds) {
        Map<Id, Company__c> companiesToUpdate = new Map<Id, Company__c>();
        if (companyIds.size() > 0) {
            Map<String, sObjectField> allocProfileFields = SchemaUtil.getInstance().getFieldsMap('Allocation_Profile__c');

            SOQLUtil allocProfileQuery = new SOQLUtil('Allocation_Profile__c');
            allocProfileQuery.addAllCustomFields();
            allocProfileQuery.addField('Item__r.Company__c');
            allocProfileQuery.setWhereClause('Id NOT IN :recordIds AND (Company__c IN :companyIds OR Item__r.Company__c IN :companyIds)');
            for (Allocation_Profile__c allocProfile:Database.query(allocProfileQuery.getQuery())) {
                Id companyId = allocProfile.Company__c;
                if (companyId == null && allocProfile.Item__c != null) companyId = allocProfile.Item__r.Company__c;

                if (companyId == null || !companyIds.contains(companyId)) continue;

                for (String fld:allocProfileFields.keySet()) {
                    if (fld.endsWith('__c') && allocProfileFields.get(fld).getDescribe().getType() == Schema.DisplayType.Boolean && (Boolean)allocProfile.get(fld) == false) {
                        companyIds.remove(companyId);
                        break;
                    }
                }
            }

            if (companyIds.size() > 0) {
                SOQLUtil itemQuery = new SOQLUtil('Item__c');
                itemQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c' });
                //GET ALL OTHER ITEMS FOR SAME COMPANY WHERE PACKAGING UOM IS POPULATED AND NOT AN EMPTY LIST, A LIST WITH 1 15-DIGIT ID OR A LIST WITH 1 18-DIGIT ID (AKA ALL OTHER ITEMS FOR THE SAME COMPANY WITH MULTIPLE PACKAGING UOMS)
                itemQuery.setWhereClause('Id NOT IN :recordIds AND Company__c IN :companyIds AND Packaging_UOM__c != null AND (NOT Packaging_UOM__c LIKE \'[""]\') AND (NOT Packaging_UOM__c LIKE \'["_______________"]\') AND (NOT Packaging_UOM__c LIKE \'["__________________"]\')');
                for (Item__c item:Database.query(itemQuery.getQuery())) companyIds.remove(item.Company__c);

                for (Id companyId:companyIds) companiesToUpdate.put(companyId, new Company__c(Id = companyId, Auto_Plan_Pick__c = true));
            }
        }
        return companiesToUpdate;
    }
    
    /** 
     * @description methods used to read the custom setting and save or change it 
     * used by KenandySetup page
     */
    
    public static boolean checkValidName( string input_string) { // KNDY-3520
        if ( input_string == null || input_string == '' ) return true;
        Pattern validNameChars = Pattern.compile('^[0-9a-zA-Z,\\?\\._/ @&\\!~*_\\-:\\+;\\#\\\']*$');
		Matcher MyMatcher = validNameChars.matcher(input_string);
		return MyMatcher.matches();
    }

    /**
     * @description this method would check if there are any supplier payments made by
     * this company
     */
    
    public static boolean checkSupplierPaymentsAvailability(Bank_Account__c bnkAcnt){ // FIN-632
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Supplier_Payment__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'count()'
		});
		Id cId = bnkAcnt.Company__c;
		Id bId = bnkAcnt.Id;
		soql.setWhereClause('company__c = :cId and Bank_Account__c = :bId and Void__c != true');
		Integer supPymtsCount = Database.countQuery(soql.getQuery());

        if(supPymtsCount > 0 ){ 
          return false;
        }else{
          return true;
        }
    
    }
    
    
    /**
     * @description this method would check if there are any Bank Files with bank processed status available for this
     * this company
     */
    //commented method for kndy-10268 deprecating bank_file__c object
    /*public static boolean checkBankFileAvailability(Bank_Account__c bnkAcnt){ // FIN-632
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Bank_File__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'count()'
		});
		Id cId = bnkAcnt.Company__c;
		Id baId = bnkAcnt.Id;
		soql.setWhereClause('company__c = : cId and Bank_Account__c = :baId and Bank_Processed__c = true');
		Integer bankFileCount = Database.countQuery(soql.getQuery());

        if(bankFileCount > 0 ){ 
          return false;
        }else{
          return true;
        }
    
    }*/

    public Company__c Company {get; set; } { company = new Company__c(); }

    public boolean doedit { get; set; } { doedit = false; } 
    
    public  UserPreference defaults { get; set; }  
        
    public Pagereference editCompany() {    doedit = true;  return null; }
    
    public void saveCompany() { 
        try { 
            defaults.updateUserPreference();        // modify the user preference record 
            fetchCompanyName();                     // fetch the company they selected
            doedit = false; 
        } catch( Exception e ) { Apexpages.addmessages(e); }   
    }

    public PageReference manageDefaults() { 
        // simple navagiate to the preferences record, but must save first if there is none
        saveCompany(); 
        return ( Apexpages.hasMessages() ? 
            null : 
            new Apexpages.Standardcontroller(defaults.preference).view()
            );
    }
    
    private void fetchCompanyName() { 
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name'
		});
		Id dCId = defaults.preference.Default_Company__c;
		soql.setWhereClause('id = :dCId');
		soql.setLimit(1);
		Company = Database.query(soql.getQuery());
    }
    /**
     * @description constructor for the Kenandy Getting Around page , note the getRecord() is not used
     */ 
    public CompanyService(ApexPages.standardController c) { 
        defaults = UserPreference.getInstance();
        if ( defaults.preference.Default_Company__c == null ) {
            // switch to edit mode so user can specify a default company
            doedit=true; 
            // pick a company for the user if we can
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name'
			});
			soql.setLimit(2);
			List<Company__c> tmp = Database.query(soql.getQuery());

            //system.debug( Logginglevel.INFO, tmp );
            if ( tmp.size() > 0 ) { 
                Company = tmp[0];
                defaults.preference.Default_Company__c = Company.id;
            }
            ApexPages.addMessage( new ApexPages.Message(Apexpages.Severity.INFO, Label.Confirm_a_default_company_and_Save));
        } else { 
            fetchCompanyName();
        }
       
    }

    /** 
     * @description pull the user preference record, return the default company id 
    */
    public static Id getDefaultCompanyId() { 
        UserPreference defaults = UserPreference.getInstance();
        return defaults.preference.Default_Company__c;
    }
        
    public static id getBankAccount(id companyID){
        if(companyID!=null){
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','disbursement_bank_account__c'
			});
			soql.setWhereClause('id=:companyID');
			Company__c comp = ((List<Company__c>)Database.query(soql.getQuery()))[0];
            return comp.Disbursement_Bank_Account__c;
        }else{
            return null;
        }
    }
    //KNDY-18030 - get bank account (deposit/disbursement/credit card) from company
    public static Company__c getCompanyBankAccount(id companyID){
        if(companyID != null){
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','deposit_bank_account__c','deposit_bank_account__r.name','deposit_bank_account__r.Currency__c','deposit_bank_account__r.Currency__r.id',
				'deposit_bank_account__r.Currency__r.name'
				,'disbursement_bank_account__c','disbursement_bank_account__r.name','disbursement_bank_account__r.Currency__c','disbursement_bank_account__r.Currency__r.id',
				'disbursement_bank_account__r.Currency__r.name'
				,'Credit_Card_Bank_Account__c','Credit_Card_Bank_Account__r.name','Credit_Card_Bank_Account__r.Currency__c','Credit_Card_Bank_Account__r.Currency__r.id',
				'Credit_Card_Bank_Account__r.Currency__r.name'
				,'Default_Transaction_Currency__c','Default_Transaction_Currency__r.id','Default_Transaction_Currency__r.name'
				//KNDY-18029 - fetch payment method for disbursement and deposit bank account 
				,'disbursement_bank_account__r.Primary_Disbursement_Payment_Method__c' ,'deposit_bank_account__r.Primary_Deposit_Payment_Method__c'				
			});
			soql.setWhereClause('id=:companyID');
			Company__c comp = ((List<Company__c>)Database.query(soql.getQuery()))[0];
            return comp;
        }else{
            return null;
        }
    }
    /*
    //KNDY-18030 - Created generic method to get all bank details from company getCompanyBankAccount so commenting this				
    //KNDY-14482 - get deposit bank account
    public static Company__c getDepositBankAccount(id companyID){
        if(companyID != null){
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','deposit_bank_account__c','deposit_bank_account__r.name','deposit_bank_account__r.Currency__c','deposit_bank_account__r.Currency__r.id',
				'deposit_bank_account__r.Currency__r.name','Default_Transaction_Currency__c','Default_Transaction_Currency__r.id','Default_Transaction_Currency__r.name'
			});
			soql.setWhereClause('id=:companyID');
			Company__c comp = ((List<Company__c>)Database.query(soql.getQuery()))[0];
            return comp;
        }else{
            return null;
        }
    }*/
    public static String defaultTransactionCurrency(id companyID){
        if(companyID!=null){
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Default_Transaction_Currency__c'
			});
			soql.setWhereClause('Id = :companyID');
			Company__c comp = ((List<Company__c>)Database.query(soql.getQuery()))[0];
            return comp.Default_Transaction_Currency__c;
        }else{
            return null;
        }
    }

    public static map<Id,Id> setDefaultCurrency(set<ID> companyIds){
        map<id,id> companyCurrencyMap = new map<Id,Id>();
         
            SOQLUtil soql = new SOQLUtil('Company__c', true);
            soql.addFields(new set<string>{'ID', 'Default_Transaction_Currency__c'  }); 
            soql.setWhereClause('ID IN : companyIds');
            List<Company__c> companyList = Database.query(soql.getQuery());
         
         for(Company__c comp : companyList){
          companyCurrencyMap.put(Comp.id, comp.Default_Transaction_Currency__c);   
         }
         return companyCurrencyMap;
    }
    
    public static map<Id,Id> setCompanyCurrency(set<ID> companyIds){
        map<id,id> companyCurrencyMap = new map<Id,Id>();
         
            SOQLUtil soql = new SOQLUtil('Company__c', true);
            soql.addFields(new set<string>{'ID', 'Comp_Currency__c'  }); 
            soql.setWhereClause('ID IN : companyIds');
            List<Company__c> companyList = Database.query(soql.getQuery());
         
         for(Company__c comp : companyList){
          	companyCurrencyMap.put(Comp.id, comp.Comp_Currency__c);   
         }
         return companyCurrencyMap;
    }    
    
    public static Id defaultTransactionCurrencyId(id companyID){
        if(companyID!=null){
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Default_Transaction_Currency__c'
			});
			soql.setWhereClause('Id = :companyID');
			Company__c comp = ((List<Company__c>)Database.query(soql.getQuery()))[0];
            return comp.Default_Transaction_Currency__c;
        }else{
            return null;
        }
    }
    
    private static map<ID,Currency__c> defaultTransactionCurrencyMap  = new map<ID,Currency__c>();
    public static Currency__c defaultTransactionCurrencyRec(id companyID){
        if(companyID!=null){
             if(defaultTransactionCurrencyMap.containsKey(companyID) == false){			
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Default_Transaction_Currency__c'
			});
			soql.setWhereClause('Id = :companyID');
			Company__c comp = ((List<Company__c>)Database.query(soql.getQuery()))[0];
			soql = new SOQLUtil('Currency__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','ISO_Code__c','Currency__c','Name'
			});
			id defaultcurr = comp.Default_Transaction_Currency__c;
 			soql.setWhereClause('Id = :defaultcurr');
                List<Currency__c> currs = ((List<Currency__c>)Database.query(soql.getQuery()));

                if(currs.size() > 0){
                    defaultTransactionCurrencyMap.put(companyID,currs.get(0));
                }
             }  
             return defaultTransactionCurrencyMap.get(companyID);
        }else{
            return null;
        }
    }
    
    public static Map<Id, Company__c> getCompanyMap(set<ID> companyIds){ //KNDY-14504
        if (companyIds == null || companyIds.size() == 0) return null;
        map<id,id> companyCurrencyMap = new map<Id,Id>();
        SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
                'Id', 'Name', 'Default_Transaction_Currency__c',
                'Street__c','City__c','State__c','Zip_Code__c','Country__c'
        });
        soql.setWhereClause('ID IN : companyIds');
        Map<Id, Company__c> companyMap = new Map<Id, Company__c>((List<Company__c>)Database.query(soql.getQuery()));
        return companyMap;
    }
    
    public static Company__c getCompanyInfo(Id companyId){ //KNDY-11133
        if (companyId == null) return null;
        SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
                'Id', 'Name', 'Default_Transaction_Currency__c',
                'Default_Purchasing_Deliver_To_Facility__c',
                'Default_Purchasing_Deliver_To_Facility__r.Id', 
                'Default_Purchasing_Deliver_To_Facility__r.Name',
                'Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__c',
                'Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__r.Id',
                'Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__r.Name',
                'Default_Transaction_Currency__r.Id','Default_Transaction_Currency__r.Name'
        });
        soql.setWhereClause('id=:companyID');
        Company__c comp = ((List<Company__c>)Database.query(soql.getQuery()))[0];
        return comp;
    }
    
    /** 
     * @description Static utility methods used by several triggers to set some default lookups based on text identifiers
     *  this expects a list of objects with both 'company__c' and 'company_identifier__c' as a valid fields, or else
     */
    
    public static void setDefaultCompany( List<sobject> objs ) {
    	setDefaultCompany(objs, true );
    } 
    
    public static void setDefaultCompany( List<sobject> objs, Boolean isBefore ) { 
            setLookupUsingField( objs, isBefore, 'Company__c', 'Company__c', 'Company_Identifier__c' );
    }

    public static void setLookupUsingField( List<sobject> objs, Boolean isBefore,string objectAPIName, string lvalue , string rvalue) { 
            setLookupUsingField(objs, isBefore, objectAPIName, lvalue, rvalue, rvalue);
    }
    
    public static void setLookupUsingField( List<sobject> objs, Boolean isBefore,
                                                                string objectAPIName,           // object we will query info from 
                                                                string lvalue ,                         // final field name to PUT into (field in objs)
                                                                string rvalue,                      // final field to GET from (field on objectAPIName)
                                                                string sourcevalue) {               // 
        if ( isBefore == false ) {  return ; }
     
        List<String> ref = new List<string>();
        String queryString;
        SOQLUtil soql;

        for ( Sobject obj: objs ) { 
            if ( obj.get(lvalue) == null  && obj.get(rvalue) != null ) {
                ref.add( (string)obj.get(rvalue) );
            }
        }
        
            if (ref.size() > 0 ) {

                Map<string,id> myMap = new Map<string,id>();
                
             //Adding Primary Logic on picking product based on UPC Code KNDY-4313
         
		    if(rvalue == 'UPC_Code__c' && objectAPIName == 'Product__c'){
                soql = new SOQLUtil(objectAPIName, TRUE);
                soql.addFields(new Set<String>{'Id', sourcevalue});
                soql.setWhereClause(sourcevalue+'  in :ref ' +' and Primary__c'+  ' = true');
		    }
		    else{
                soql = new SOQLUtil(objectAPIName, TRUE);
                soql.addFields(new Set<String>{'Id', sourcevalue});
                soql.setWhereClause(sourcevalue+'  in :ref ');
		    } 
                
            for ( sobject i: Database.query(soql.getQuery()) ) {
                /*  TODO 
                 allow multi
                 if ( sourcevalue.indexOf('.')>0) {
                    string[] aa = sourcevalue.split('\\.');
                    sobject f1 = (sobject)i.getSObject( aa[0] ); 
                    myMap.put( (string)f1.get( aa[1] ), i.id); 
                } else { 
                    myMap.put( (string)i.get(sourcevalue), i.id);
                } */
                
                myMap.put( (string)i.get(sourcevalue), i.id);
            }
    
                for ( sobject obj: objs) { 
                    if (    obj.get(lvalue) == null     && 
                            obj.get(rvalue) != null     && 
                            myMap.containsKey( (string)obj.get(rvalue) ) )  
                    {
                        obj.put(lvalue, myMap.get( (string)obj.get(rvalue) ) );
                    }
                }
            }
        }
    
    
}