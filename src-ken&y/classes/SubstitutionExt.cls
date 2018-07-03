public with sharing class SubstitutionExt extends GridRelatedListController {
	
	ApexPages.StandardController con;
	private static SchemaUtil util = SchemaUtil.getInstance();
	
	public GridRelatedListController.GridRelatedListConfig SubstitutionsConfig {get; set;}
	
	public String getSubstitutionsConfigJson() {
        String configStr = JSON.serialize(this.SubstitutionsConfig);
        return configStr;
    }
    
    public String SubstitutionsFieldList = null;
	public String previousPage { get; set; }
	public Id defaultFacility{ get; set;}
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    
	public SubstitutionExt(ApexPages.StandardController scon){
		con = scon;
        previousPage = ApexPages.currentPage().getHeaders().get('Referer');
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('User_Preference__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Default_Facility__c'
		});
		soql.setWhereClause('OwnerId = :UserInfo.getUserID()');
		soql.setLimit(1);

		List<User_Preference__c> u = Database.query(soql.getQuery());

        if (u.size() > 0){
	        if (u[0].Default_Facility__c != null)
	        	defaultFacility = u[0].Default_Facility__c;
        }		
        
        // Substitutions Grid config
        SubstitutionsConfig = new GridRelatedListController.GridRelatedListConfig();
        SubstitutionsConfig.uniqueId = 'SubstitutionsGrid';
        SubstitutionsConfig.title = 'Substitutions';
        SubstitutionsConfig.objectName = 'Substitution__c';
        SubstitutionsConfig.fieldset = 'Substitution_Edit';
        SubstitutionsConfig.buttons = 'create, delete, save, cancel, search';
        SubstitutionsConfig.alwaysUseFullDateTimeFormat = false;
    }
	
	public string getSubstitutionsFieldList() {
        if (SubstitutionsFieldList == null && SubstitutionsConfig != null) {
        	
        	FieldInfo fieldInfoItem;
        	// get the Substitutions field info list
            
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(SubstitutionsConfig.objectName, SubstitutionsConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id'};
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	fieldInfoList[i].field = fieldName;
            	if(! ( fieldName.endsWith('UPC__c') || fieldName.endsWith('Primary__c') ) ){
            	    fieldInfoList[i].editable = true;
            	}
            	else{
            	    fieldInfoList[i].editable = false;
            	}
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            }
            
            SubstitutionsFieldList = JSON.serialize(fieldInfoList);
        }
        
        return SubstitutionsFieldList;
    }
    
    @RemoteAction
	public static JsonResult getSubstitutions(String upc, String productId, String primaryFlag, String customerId, String facilityId, String startDateString, String endDateString) {
		JsonResult result = new JsonResult();
		List<Substitution__c> substitutionList = new List<Substitution__c>();
        
        List<String> filters = new List<String>();
        
        if(upc != null && upc != ''){
            filters.add('Current_Product__r.UPC_Code__c = :upc');
        }
        
        if(productId != null && productId != ''){
            filters.add('Current_Product__c = :productId');
        }
        
        // Filter by primary only if primary is set, else display all results.
        Boolean primary = Boolean.valueOf(primaryFlag);
        if(primary){
            filters.add('Primary__c = true');
        }
        
        if(customerId != null && customerId != ''){
            filters.add('Customer__c = :customerId');
        }
        
        if(facilityId != null && facilityId != ''){
            filters.add('Facility__c = :facilityId');
        }
        
        if(startDateString != null && startDateString != ''){
            Date startDate = Date.parse(startDateString);
            filters.add('Start_Date__c >= :startDate');
        }
        
        if(endDateString != null && endDateString != ''){
            Date endDate = Date.parse(endDateString);
            filters.add('End_Date__c <= :endDate');
        }
        
        Iterator<String> iFilters = filters.iterator();
        
        String whereClause = '';
        
        while(iFilters.hasNext()){
            whereClause += iFilters.next();
            
            if(iFilters.hasNext()){
                whereClause += ' and ';    
            }
        }
        
        SOQLUtil soql = new SOQLUtil('Substitution__c');
	    soql.addFields('Substitution_Edit');
	    soql.setWhereClause(whereClause);
	    
	    substitutionList.addAll((List<Substitution__c>) Database.query(soql.getQuery()));
	    
		result.records = substitutionList;
        result.total = substitutionList.size();
        
        return result;
	}

}