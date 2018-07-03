public with sharing class Export1099RecordsExt extends BaseController{
    public static SchemaUtil util = SchemaUtil.getInstance();
    public string s1099Fields;
    public string NamespaceUU { get { return KSE.NamespaceUU; }}

    public Export1099RecordsExt(Apexpages.Standardcontroller controller){
       s1099Fields = getS1099Fields();
    }
    
    	public Export1099RecordsExt(ApexPages.StandardSetController scon) {
		// to support integration with vf pages for list view buttons
	}
    
    public String getReturnUrl(){
        PageReference pageRef;
        Schema.DescribeSObjectResult result = Supplier_1099__c.SObjectType.getDescribe();
        pageRef = new PageReference('/' + result.getKeyPrefix());
        return pageRef.getUrl();
    }
    
    @RemoteAction @ReadOnly 
    public static JsonResult getSupplier1099Records(List<String> selectedCompanyIds, String selectedYear) {
        JsonResult result = new JsonResult();
        Integer intYr = Integer.ValueOf(selectedYear);
        Map<String, List<Supplier_1099__c>> mapCompanyId1099s = new Map<String, List<Supplier_1099__c>>();
        String fieldset = 'Export_1099_Records';
        string whereClause =  ' Company__c in :selectedCompanyIds and Exclude__c = false and Year__c =:selectedYear';
        Set<String> additionalFields = new Set<String>{'Company__c', 'Year__c','Supplier__r.Name', 'Company__r.Name'};
        if (selectedCompanyIds == null || selectedCompanyIds.size() == 0){
            whereClause =  ' Exclude__c = false and Year__c =:selectedYear';
        }
        try{
            String queryString = util.generateQueryFromFieldSet('Supplier_1099__c', new Set<string>{ fieldset }, additionalFields, whereClause);
            List<Supplier_1099__c> s1099List = database.query(queryString);
            result.records = s1099List;
            result.success = false;
            if (result.records != null && result.records.size() > 0){
                result.success = true;
                result.total = result.records.size();
                Map<String, List<Supplier_1099__c>> mapCompanyId1099Records = get1099sPerCompany(s1099List);
                result.records = new List<Map<String, List<Supplier_1099__c>>>{mapCompanyId1099Records};
            }else{
                result.total = 0;
                String errorMessage = Label.No_records_are_available_to_export;   
                result.addMessage(errorMessage, ApexPages.Severity.INFO);
            }
        }catch (Exception ex){
            String errorMessage = 'An Error occured : ' + ex.getMessage();   
            result.addMessage(errorMessage, ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    public static Map<String, List<Supplier_1099__c>> get1099sPerCompany(List<Supplier_1099__c> s1099List){
         Map<String, List<Supplier_1099__c>> mapCompanyId1099s = new Map<String, List<Supplier_1099__c>>();
         for (Supplier_1099__c record: s1099List){
         	 String fileName = 'Supplier 1099s-<Company Name>-<Year>';
             fileName = fileName.replace('<Year>',record.Year__c);
             fileName = fileName.replace('<Company Name>' ,record.Company__r.Name);
             if (!mapCompanyId1099s.containsKey(fileName)){
                 mapCompanyId1099s.put(fileName, new List<Supplier_1099__c>());
             }
             mapCompanyId1099s.get(fileName).add(record);
         }
         return mapCompanyId1099s;
    }
    
    public string getS1099Fields(){
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Supplier_1099__c', 'Export_1099_Records');
        fieldInfoList.remove(0); // remove Id field
        s1099Fields = JSON.serialize(fieldInfoList);
        return s1099Fields;
    }
}