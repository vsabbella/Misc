public with sharing class ClaimManageExt extends BaseController {

    ApexPages.StandardController con;
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    public string pageTitle { get; set; }
    public boolean renderEditable {get;set;}
    //constructor
    public ClaimManageExt(ApexPages.StandardController controller) {
        con = controller;
        Id claimId = con.getId();
		List<Claim__c> claims = new List<Claim__c> ();
		if(String.isBlank(claimId) == false){
			//claim = (Claim__c) controller.getRecord();
			String whereClause = ' Id = :claimId';
			SOQLUtil soql = new SOQLUtil('Claim__c',true);
            soql.addFields('Claim_Header');
            soql.addField('Line_Exceptions__c');
            soql.addField('Name');
            soql.setWhereClause(whereClause);
			system.debug('Claim query=='+ soql.getQuery());
            claims = (List<Claim__c>) Database.query( soql.getQuery());
			pageTitle = 'Claim' + ': ' + claims[0].Name;	
			renderEditable = true;
			//make editable false in case of claim status not new/open , source not manual , claim lines are created
			if((claims[0].Status__c != ClaimService.STATUS_NEW && claims[0].Status__c != ClaimService.STATUS_OPEN)
			|| claims[0].Source__c != ClaimService.SOURCE_MANUAL || claims[0].Line_Exceptions__c > 0){
				renderEditable = false;
			}
			con = new ApexPages.StandardController(claims[0]);
		}
		else{
			renderEditable = true;
			pageTitle = 'Claim';
		}
    }
    //get header claim field list
    public string getClaimHeaderFieldList() {
        String claimHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        
        // get the Claim header field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Claim__c', 'Claim_Header');
        
        for (Integer i = 0; i < fieldInfoList.size(); i++){
           	if (fieldinfoList[i].field == 'Status__c' || fieldinfoList[i].field == 'Source__c')
           		 fieldInfoList[i].editable = false;
           	else
                fieldInfoList[i].editable = renderEditable;
            
        }
        
		fieldInfoList.remove(0); // Remove Id field from the list
        
        claimHeaderFieldList = JSON.serialize(fieldInfoList);
        
        return claimHeaderFieldList;
    }
    //get additional field list including readonly and editable fieldsets
    public string getClaimAddlHeaderFieldList() {
        String claimAddlHeaderFieldList = '';
        List<FieldInfo> result = new List<FieldInfo>();
        Set<String> headerFields = new Set<String>();
        List<FieldInfo> headerList = (List<FieldInfo>) JSON.deserialize(getclaimHeaderFieldList(), List<FieldInfo>.class);
        
        for(Integer i = 0; i < headerList.size(); i++){
            headerFields.add(headerList[i].field);
        }
        
        try {
            // get the claim header additional field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Claim__c', 'Claim_Additional_Info_Header_RO');
            
            fieldInfoList.remove(0);    // Remove Id field from the list
            
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                if (!headerFields.contains(fieldInfoList[i].field)) {
                	fieldInfoList[i].editable = false;
                    result.add(fieldInfoList[i]);
                }
            }
            fieldInfoList = FieldInfo.fetchJsonFieldInfos('Claim__c', 'Claim_Additional_Info_Header');
            
            fieldInfoList.remove(0);    // Remove Id field from the list
            
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                if (!headerFields.contains(fieldInfoList[i].field)) {
                	fieldInfoList[i].editable = true;
                    result.add(fieldInfoList[i]);
                }
            }
            
            claimAddlHeaderFieldList = (result.size() > 0) ? JSON.serialize(result) : '';
        }
        catch (FieldInfo.EmptyFieldSetMemberException e) {
            claimAddlHeaderFieldList = '';
        }
        
        return claimAddlHeaderFieldList;
    }
    //set the returnurl for goback button
    public String getReturnUrl(){
		PageReference pageRef;
        
        if (con != null && con.getId() != null ){
            pageRef =  new PageReference('/' + con.getId());
        }
        else{
            Schema.DescribeSObjectResult dsr = Claim__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        }
        
        return pageRef.getUrl();	
	}
	//get keyprefix
	 public string getKeyPrefix() {
    	return Claim__c.SObjectType.getDescribe().getKeyPrefix();
    }
	//get claim data in new/edit scenarios
	@RemoteAction
	public static JsonResult getClaim(String claimId){
		
		List<Claim__c> claims = new List<Claim__c>();
		SchemaUtil shUtil = new SchemaUtil();
		JsonResult result = new JsonResult();
		
		// Return an emoty record for new claim
		if(string.isBlank(claimId)){
			Claim__c claim = new Claim__c();
			ID companyID = CompanyService.getDefaultCompanyId(); 
			Company__c company = CompanyService.getCompanyInfo(companyID);
          
            if(company != null){
				claim.Company__c = company.id;
				claim.Company__r = company;
				claim.Currency__c =company.Default_Transaction_Currency__c;
	
				Id currencyId = claim.Currency__c;
				
				System.debug('currencyId=='+currencyId);
				claim.Currency__r = company.Default_Transaction_Currency__r;

            }
            claim.Status__C = ClaimService.STATUS_NEW;
            claim.Source__c = ClaimService.SOURCE_MANUAL;
			claims.add(claim);
		}else{
			//edit case scenario
			String whereClause = ' Id = :claimId';
			set<String> fieldSets = new set<String>();
          	SOQLUtil soql = new SOQLUtil('Claim__c',true);
		
           
           	soql.addFields('Claim_Header');
           	soql.addFields('Claim_Additional_Info_Header_RO');
            soql.addFields('Claim_Additional_Info_Header');
            
            soql.setWhereClause(whereClause);	        
            claims = (List<Claim__c>) Database.query(soql.getQuery());	

		}

		result.success = true;
		result.records = claims;
        result.total = claims.size();
        
        return result;	
	}
	//get company default transaction currency
	@RemoteAction
	public static JSONResult getCompanyDefaultCurrency(String companyId) {
		JsonResult result = new JsonResult();
		try {
			Id currencyId = CompanyService.defaultTransactionCurrency(companyId);
			result.success = true;
			SOQLUtil soql = new SOQLUtil('Currency__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','ISO_Code__c','name'
			});
			soql.setWhereClause('Id = :currencyId');
			
			result.records = Database.query(soql.getQuery());
			return result;
		}catch(exception ex) {
			system.debug(LoggingLevel.Error, 'ex: '+ex.getMessage()+' stacktrace: '+ex.getStacktraceString());
			result.success = false;
			result.addMessage(ex.getmessage(), ApexPages.Severity.ERROR);
			return result;
		}
	}
	//save claim data
	@RemoteAction
	public static JsonResult save(Claim__c claim, List<String> headerDateFields){
		system.debug(LoggingLevel.INFO, 'claim: ' + claim);
		JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        list<Claim__c> records = new list<Claim__c>();
        
        try{ 
        	
        	//saveclaim
        	 
			if(claim != null){
	            
	            KendoUtils.UpdateDateFields(claim, headerDateFields);
	           	system.debug('claim '+claim);
	            DML.checkUpsertAsUser(claim); upsert claim;
	        }
	        result.success = true;
	        Id claimId = claim.id;
            records.add(claim);
            result.records = records;
            result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
	        
        }catch(DMLException ex) {
			Database.rollback(sp);
            result.success = false;
            for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {
                
                    string errorMessage = ex.getDmlMessage(idx);
                    string statusCode = ex.getDmlStatusCode(idx);
                    Integer location;    
                    system.debug('errorMessage=='+ ex.getStackTraceString() + '-message = ' + ex.getMessage() +'getDmlStatusCode' + ex.getDmlStatusCode(idx));
                    if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                    list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');

                    if(!msgArray.isEmpty()){
                        errorMessage = msgArray.get(msgArray.size()-1);

                        if(errorMessage.contains(': []: []')){
                            location = errorMessage.lastIndexOf(': []: []');
                            errorMessage = errorMessage.mid(0, location);
                        }
                        if(errorMessage.contains(': []')){
                            location = errorMessage.lastIndexOf(': []');
                            errorMessage = errorMessage.mid(0, location);
                        }
                    }
                } 
                    
                result.addMessage( errorMessage, ApexPages.severity.ERROR);
        	}
            //System.debug(logginglevel.info,result);
		}
        catch ( DML.InsuffientAccessException e ) { 
 			Database.rollback(sp);
            result.success = false;
 			result.addMessage(Label.Insufficient_access_contact_administrator_for_permissions, ApexPages.Severity.ERROR); 
 		}catch (Exception e) { //AR-15 JSONResult addMessage handles DML Exception
        	Database.rollback(sp);
        	string errorMessage = e.getMessage();
        	system.debug('errorMessage=='+ errorMessage);
            result.success = false;
            
            result.addMessage(e, ApexPages.Severity.ERROR); //AR-15
        }

        return result;
	}
	//get picklist values for type field
	public String getTypeDescribe() {
     	return JSON.serialize(Claim__c.Type__c.getDescribe());
     }
     //get picklist values for subtype field
     public String getSubTypeDescribe() {
     	return JSON.serialize(Claim__c.Subtype__c.getDescribe());
     }
     //get picklist values for reason field
     public String getReasonDescribe() {
     	return JSON.serialize(Claim__c.Reason__c.getDescribe());
     }
}