public with sharing class Supplier1099Service {
    
    public class Supplier1099Exception extends Exception{}
    private static final decimal SUPPLIER_TAX_ID_MAX_LENGTH = 11;
    public static final Set<String> validCurrency = new Set<String>{'USD'};
    
    public static Integer generateSupplier1099s(List<Supplier__c> suppliers, Id batchJobId, Integer intyr, Decimal amount, Id companyId){
        Integer supplier1099ct = 0;
        validateSupplier1099MappingCMDT();//KNDY-18065
          
        //This set of keys tracks which records had failed mapping - it will be used to remove 1099s from the DML statement before commit
        Set<string> failedKeys = new Set<string>();
        Set<ID> validSupplierIDs = new Set<ID>();
        Map<String, Supplier_1099_Box_MappingMDT__mdt> mappingMDTMap = get1099BoxMappings(); //KNDY-18065
        
        //Requery to enforce we have all of our needed references
       
        //Collect all active 1099 date ranges
      //  System.debug(' I am in 1099Service');  
        Datetime startDate;
        Datetime endDate;

		startDate = Datetime.newInstance(intyr, 1, 1, 0, 0, 0);    
		endDate =  Datetime.newInstance(intyr, 12, 31, 23, 59, 59); 
        
        // Get valid suppliers [with payments over $600 for the year]
       
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Supplier_Payment__c', true, true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Supplier__c SupplierID','sum(Payment_Amount__c) TotalPaid'
		});
		
		soql.setWhereClause('Supplier__c IN :suppliers AND (Company__c = :companyId AND Currency__r.Name in :validCurrency'
							+' AND Finalized__c = true AND Status__c != \'Void\' AND Status__c != \'Cancelled\' AND Void__c != true '
							+' AND (Date_Paid__c <=: endDate) AND (Date_Paid__c >=: startDate)) AND Void__c != true GROUP BY Supplier__c'
							+' HAVING sum(Payment_Amount__c) >= ' + amount );

		List<AggregateResult> arValid1099Suppliers = Database.query(soql.getQuery());
                          
        for(AggregateResult ar : arValid1099Suppliers){
            validSupplierIDs.add((ID)ar.get('SupplierID'));
        }
        
        // KNDY-17912 Remove suppliers with filed 1099s for same year
        system.debug(LoggingLevel.Error, '>>> validSupplierIds pre: ' + validSupplierIds);
        	soql = new SOQLUtil('Supplier_1099__c', true); //enforceFLS=true, running in user mode 
	    soql.addFields(new set<string>{
		'Id', 'Filed__c', 'Supplier__c', 'Year__c', 'Company__c', 'Company__r.Name'
	    });
	    soql.setWhereClause('Supplier__c IN :validSupplierIDs and Company__c =:companyId and Filed__c = true and Year__c = \'' + intyr + '\'');
	    List<Supplier_1099__c> filed1099Records = Database.query(soql.getQuery());
        for(Supplier_1099__c filed1099 : filed1099Records){
            if (validSupplierIds.contains(filed1099.Supplier__c)){
                validSupplierIds.remove(filed1099.Supplier__c);
            }
        }
        system.debug(LoggingLevel.Error, '>>> validSupplierIds post: ' + validSupplierIds);
        if (validSupplierIds.size() == 0 && filed1099Records.size() > 0){
            String error = Label.Supplier_1099_Filed;
            error = error.replace('<companyName>', filed1099Records[0].Company__r.Name);
            error = error.replace('<reportingYear>', String.ValueOf(intyr));
            throw new Supplier1099Exception(error);
        }


        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Supplier__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','X1099_Supplier__c','Street__c','Company__r.Name','Alternate_Name__c','Company__r.City__c','Company__r.Street__c','Company__r.State__c',
			'Company__r.Zip_Code__c','Company__r.Country__c','Company__r.TIN__c','Company__r.Default_Transaction_Currency__c','Name',
			'City__c','State__c','Zip_Code__c','Country__c','Address__c','Tax_ID__c','Supplier_ID__c',
			'X1099_Box__c','Address__r.Phone',
			'RecordType.Name','RecordType.DeveloperName','RecordTypeId'
		});
		soql.setWhereClause('X1099_Supplier__c = true AND Id IN :validSupplierIDs');

		suppliers = Database.query(soql.getQuery());
        
        //map of supplierId to 1099
        Map<string, Supplier_1099__c> m1099s = new Map<string, Supplier_1099__c>();
        Map<Id, Supplier__c> mSuppliers = new Map<Id, Supplier__c>(suppliers);
        
        //adds payments
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Supplier_Payment_Line__c', true, true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Supplier_Payment__r.Supplier__c supId','SUM(Amount__c) AmountPaid','X1099_Box_G__c box','Supplier_Payment__r.Company__c companyId', 'MIN(Supplier_Payment__r.Name) minSPName' 
		});
		soql.setWhereClause('Supplier_Payment__r.Supplier__c IN :validSupplierIDs AND Type__c = \'Payment\' AND Supplier_Payment__r.Company__c = :companyId'
							+' AND Supplier_Payment__r.Currency__r.Name in :validCurrency AND ((Supplier_Payment__r.Date_Paid__c >=: startDate) AND (Supplier_Payment__r.Date_Paid__c <=: endDate)) '
							+' AND Supplier_Payment__r.Finalized__c = true AND Supplier_Payment__r.Status__c != \'Void\' AND Supplier_Payment__r.Status__c != \'Cancelled\' '
							+' AND Supplier_Payment__r.Void__c != true GROUP BY Supplier_Payment__r.Supplier__c, X1099_Box_G__c, Exclude_From_1099__c, Supplier_Payment__r.Company__c HAVING (Exclude_From_1099__c = false)');
		
		List<AggregateResult> arSupplierDetails = Database.query(soql.getQuery());
        
        // KNDY-12464: Get company map seperately.
        Set<Id> companyIds = new Set<Id>();
        for(AggregateResult ar : arSupplierDetails){
        	companyIds.add((Id)ar.get('companyId'));
        }
        
        soql = new SOQLUtil('Company__c', true, true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id', 'Name', 'City__c',
			'Street__c', 'State__c',
			'Zip_Code__c', 'Country__c', 'Address__r.Phone',
			'TIN__c', 'Default_Transaction_Currency__c'
		});
		soql.setWhereClause('Id IN :companyIds');
		
        Map<Id, Company__c> companyMap = new Map<Id, Company__c>((List<Company__c>)Database.query(soql.getQuery()));
        
        // subtracts credits
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Supplier_Payment_Line__c', true, true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Supplier_Payment__r.Supplier__c supId','SUM(Amount__c) CreditAmount','X1099_Box_G__c box', 'MIN(Supplier_Payment__r.Name) minSPName'
		});
		soql.setWhereClause('Supplier_Payment__r.Supplier__c IN :validSupplierIDs AND Supplier_Payment__r.Company__c = :companyId AND (Type__c = \'Credit Memo\'  or Type__c = \'Prepayment\') '
							+' AND Supplier_Payment__r.Finalized__c = true AND Supplier_Payment__r.Status__c != \'Void\' AND Supplier_Payment__r.Status__c != \'Cancelled\' '
							+' AND ((Supplier_Payment__r.Date_Paid__c >=: startDate) AND (Supplier_Payment__r.Date_Paid__c <=: endDate)) '
							+' AND Supplier_Payment__r.Void__c != true AND Supplier_Payment__r.Currency__r.Name in :validCurrency ' 
							+' GROUP BY Supplier_Payment__r.Supplier__c, X1099_Box_G__c, Exclude_From_1099__c HAVING (Exclude_From_1099__c = false)');
		
		List<AggregateResult> arSupplierCredits = Database.query(soql.getQuery());

        for(AggregateResult ar : arSupplierDetails){
            
            string boxRef = (string)ar.get('box');
            Id supplierId = (Id)ar.get('supId');
            Id compId = (Id)ar.get('companyId');
            String spName = (string) ar.get('minSPName');
            
            system.debug(LoggingLevel.Error, 'boxRef from AR Supplier: ' + boxRef);
            
            if(boxRef != null && boxRef != ''){
                
                if(mSuppliers.containsKey(supplierId)){
                    
                
                    Supplier__c iSupplier = mSuppliers.get(supplierId);
                    validateSupplierTaxId(iSupplier);//KNDY-17762

                    string iKey =  string.valueOf(supplierId);
                    
                    if(!m1099s.containskey(iKey)){
                        
                        sObject iObj = new Supplier_1099__c();
                        String fieldAPIName = getSupplier1099FieldAPIName(boxRef,mappingMDTMap, spName,iSupplier.Name);
                        iObj.put(fieldAPIName, ar.get('AmountPaid'));
                        system.debug(LoggingLevel.Error, '1099 amt at create: ' + iObj);
                        
                        Company__c company = companyMap.get(compId);
                        validateCompanyTaxId(company);
                        //Cast the sObject to a Supplier 1099 for further field assignments
                        Supplier_1099__c i1099 = (Supplier_1099__c)iObj;
                        i1099.Batch_Job_ID__c = batchJobId; //KNDY-17912
                        i1099.Company__c = company.Id;
                        i1099.Supplier__c = iSupplier.Id;
                        i1099.Year__c = string.valueOf(intyr);
                        i1099.Merge__c = true;

                        
                        //Payer Details
                        i1099.Payer_Name__c = company.Name;
                        i1099.PayerCountry__c = company.Country__c;
                        i1099.Payer_FIN__c = company.TIN__c;
                        i1099.Payer_Street__c = company.Street__c;
                        i1099.Payer_City__c = company.City__c;
                        i1099.Payer_State__c = company.State__c;
                        i1099.Payer_Zip__c = company.Zip_Code__c;
                        i1099.Payer_Phone__c = company.Address__r.Phone;//KNDY-18844
                        if (company.Country__c != NULL){ 
                            i1099.PayerCountry__c = company.Country__c;
                        }
                        else i1099.PayerCountry__c = 'US';
                        
                        
                        //Recipient Details
                        i1099.Recipient_ID__c = iSupplier.Tax_ID__c;
                        i1099.Supplier_ID__c = iSupplier.Supplier_ID__c;
                        if (iSupplier.Alternate_Name__c != NULL ){
                            i1099.Recipient_Name__c = iSupplier.Alternate_Name__c;  
                        }   
                        else i1099.Recipient_Name__c = iSupplier.Name;                       
                        i1099.Recipient_Street__c = iSupplier.Street__c;
                        i1099.Recipient_City__c = iSupplier.City__c;
                        i1099.Recipient_State__c = iSupplier.State__c;
                        i1099.Recipient_Zip__c = iSupplier.Zip_Code__c;                        
                        i1099.Recipient_Country__c = iSupplier.Country__c;
     
                        //system.debug('map put: ' + iKey + ' - ' + i1099);
                        m1099s.put(iKey, i1099);
                        
                    }else{
                        
                        //Grab the record out of the map and update the respective box, then put it back in the map
                        sObject i1099 = m1099s.get(iKey);
                        String fieldAPIName = getSupplier1099FieldAPIName(boxRef,mappingMDTMap,spName,iSupplier.Name);
                        decimal iAmt = (decimal)ar.get('AmountPaid');
                        decimal iFieldAmt = (decimal)i1099.get(fieldAPIName);
                        iFieldAmt = iFieldAmt == null ? 0 : iFieldAmt;
                        i1099.put(fieldAPIName, iAmt + iFieldAmt);
                        system.debug(LoggingLevel.Error, 'obj amt at increment: ' + i1099 + ' : ' + i1099.get(fieldAPIName));
                            
                        //system.debug('map put: ' + iKey + ' - ' + i1099);
                        m1099s.put(iKey, (Supplier_1099__c)i1099);
                    }
                    
                }
                    
            }
        }
        
        //Loop through and decrement credits
        for(AggregateResult ar : arSupplierCredits){
       	 	
        	string boxRef = (string)ar.get('box');
            Id supplierId = (Id)ar.get('supId');
            String spName = (string) ar.get('minSPName');
            String supplierName = '';
            if(mSuppliers.containsKey(supplierId)){
               supplierName = mSuppliers.get(supplierId).Name;
            }
            //system.debug('credit boxRef: ' + boxRef + ' - ' + supplierId);
            if(boxRef != null && boxRef != ''){
            	
                string fieldName = Supplier1099Service.getSupplier1099FieldAPIName(boxRef,mappingMDTMap, spName,supplierName);
                string iKey = string.valueOf(supplierId);
                
                if(m1099s.containsKey(iKey)){
                	sObject i1099 = m1099s.get(iKey);
                	//decimal creditAmt = mSupplierBoxCredits.get(supplierId + boxRef);
                	decimal creditAmt = (decimal)ar.get('CreditAmount');
                	creditAmt = creditAmt == null ? 0 : creditAmt;
                    decimal iFieldAmt = (decimal)i1099.get(fieldName);
                    iFieldAmt = iFieldAmt == null ? 0 : iFieldAmt;
                    system.debug('field amount: ' + iFieldAmt);
                    system.debug('credit decrement: ' + creditAmt);
                	i1099.put(fieldName, iFieldAmt + creditAmt); //KNDY-9590
                	system.debug('adjusted field amt: ' + i1099.get(fieldName));
                	m1099s.put(iKey, (Supplier_1099__c)i1099);
                }
                
            }
        }
        
        if(m1099s.values().size() > 0){
            //system.debug('m1099s: ' + m1099s.size() + ' - ' + m1099s);
                List<Supplier_1099__c> insert1099s = m1099s.values();
                List<Database.saveResult> results = DML.insertAsUser(insert1099s, true); //KNDY-17762

                integer resultSize = results.size();
                for(integer i=0; i<resultSize; i++){
                   if(!results[i].isSuccess()){
                        string errorMessage = '';
                        for(Database.Error err : results[i].getErrors()){
                            errorMessage += err.getMessage() + ', ';
                        }
                        errorMessage = errorMessage.substringBeforeLast(',');
                        string supplierId = insert1099s[i].supplier__c;
                        Notify.Message iErrorChatter = new Notify.Message('Supplier 1099 Error', errorMessage);
                        Notify.chatterOn(new Supplier1099Service(), supplierId, new List<Notify.Message>{iErrorChatter});         
                    }
                    else{
                       supplier1099ct++;
                    }
                }
        }
        return supplier1099ct;
    }
    
    // validates if CMDT source picklist value text exists as a picklist value in 1099 Box field on SPL
    public static void validateSupplier1099MappingCMDT(){ //KNDY-18065
       Map<String, Supplier_1099_Box_MappingMDT__mdt> mappingMDTMap = get1099BoxMappings();
       Set<String> sourcePicklistValues = mappingMDTMap.keySet();
       Set<String> splPicklistValues = new Set<String>();
       String error= '';
       
       Schema.DescribeFieldResult fieldResult = Supplier_Payment_Line__c.x1099_Box_G__c.getDescribe();
       List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
       for (Schema.PicklistEntry f: picklistEntries){
          splPicklistValues.add(f.getValue());
       }
       sourcePicklistValues.removeAll(splPicklistValues);
       if (sourcePicklistValues.size() > 0){
           error = Label.Invalid_Source_Picklist_Value;
           String srcPicklistValuesStr = '';
           for (String picklistValue : sourcePicklistValues){
              srcPicklistValuesStr += picklistValue + ', ';
           }
           srcPicklistValuesStr = srcPicklistValuesStr.removeEnd(', ');
           error = error.replace('<Value Name>',srcPicklistValuesStr);
       }
       if (!String.isBlank(error)){
           throw new Supplier1099Exception(error);
       }
    }
    
    private static void validateSupplierTaxId(Supplier__c iSupplier){ //KNDY-17762
        String errormsg = '';
        if (String.isBlank(iSupplier.Tax_Id__c)){
           errormsg = Label.Supplier_is_missing_a_tax_identification_number;
           errormsg = errormsg.replace('<SupplierName>', iSupplier.Name);
           throw new Supplier1099Exception(errormsg);
        }
        else if (iSupplier.Tax_Id__c.length() > Supplier1099Service.SUPPLIER_TAX_ID_MAX_LENGTH){
           errormsg = Label.Supplier_has_a_tax_ID_that_exceeds_the_valid_length;
           errormsg = errormsg.replace('<SupplierName>', iSupplier.Name);
           throw new Supplier1099Exception(errormsg);
        }
    }

    private static void validateCompanyTaxId(Company__c co){ //KNDY-17905
        if (String.isBlank(co.TIN__c)){
           String errormsg = Label.Company_is_missing_a_tax_identification_number;
           errormsg = errormsg.replace('<CompanyName>', co.Name);
           throw new Supplier1099Exception(errormsg);
        }
    }
    
    // Assumption: only 1 mapping exists for source picklist value
    private static Map<String, Supplier_1099_Box_MappingMDT__mdt> get1099BoxMappings(){//KNDY-18065
        Map<String, Supplier_1099_Box_MappingMDT__mdt> mappingMDTMap = new  Map<String, Supplier_1099_Box_MappingMDT__mdt>();
        Supplier_1099_Box_MappingMDT__mdt[] cmdtMappings = [SELECT MasterLabel, Source_Picklist_Value__c, Destination_Field__r.QualifiedApiName FROM Supplier_1099_Box_MappingMDT__mdt];
        for (Supplier_1099_Box_MappingMDT__mdt cmdtMapping: cmdtMappings){
           String x1099BoxValue = cmdtMapping.Source_Picklist_Value__c;
           if (!mappingMDTMap.containsKey(x1099BoxValue)){
               mappingMDTMap.put(x1099BoxValue, cmdtMapping);
           }
        }
        return mappingMDTMap;
    }
     
    private static String getSupplier1099FieldAPIName(String boxName, Map<String, Supplier_1099_Box_MappingMDT__mdt> x1099BoxMappings, String spName, String supplierName){
        String fieldAPIName= '';
        system.debug(LoggingLevel.Error, '>>>>x1099BoxMappings : ' + x1099BoxMappings + '>>>>boxName: ' + boxName);
        if (x1099BoxMappings.containsKey(boxName)){
            fieldAPIName = x1099BoxMappings.get(boxName).Destination_Field__r.QualifiedApiName;
        }
        if (String.isBlank(fieldAPIName)){
            String errorMsg = Label.Missing_1099_Box_Mapping;
            errorMsg = errorMsg.replace('<value in Supplier field>', supplierName);
            errorMsg = errorMsg.replace('<Box name>', boxName);
            errorMsg = errorMsg.replace('<SP Name>', spName);
            throw new Supplier1099Exception(errorMsg);
        }
        return fieldAPIName;
    }
    
}