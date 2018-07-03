public with sharing class AccountInquiryExt extends BaseController {
	ApexPages.StandardController con;
	public string NamespaceUU { get { return KSE.NamespaceUU; }}
	private static SchemaUtil util = SchemaUtil.getInstance();
	public GridRelatedListController.GridRelatedListConfig accountingEntryLinesConfig {get; set;}	
	public String accountingEntryLinesFieldList = null;
	public Boolean isHideResultsOnPageLoad {get; set;}	
    
    public AccountInquiryExt(ApexPages.StandardController controller) {
        con = controller;
        isHideResultsOnPageLoad = true;
		
    	// Accounting Entry Lines Grid config
        accountingEntryLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        accountingEntryLinesConfig.uniqueId = 'AccountingEntryLinesGrid';
        accountingEntryLinesConfig.title = Schema.SObjectType.Accounting_Entry_Line__c.getLabelPlural();
        accountingEntryLinesConfig.objectName = 'Accounting_Entry_Line__c';
        accountingEntryLinesConfig.fieldset = 'Account_Inquiry_Line';
        accountingEntryLinesConfig.buttons = 'search, excel, pdf';
    }
    
	public String getAccountingEntryLinesConfigJson() {
        String configStr = JSON.serialize(this.accountingEntryLinesConfig);
          
        return configStr;
    }
    
    public string getAccountingEntryLinesFieldList() {
        if (accountingEntryLinesFieldList == null && accountingEntryLinesConfig != null) {
        	FieldInfo fieldInfoItem;
        	// get the accounting entry lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(accountingEntryLinesConfig.objectName, accountingEntryLinesConfig.fieldset);
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	fieldInfoList[i].editable = false;
            }
            
            accountingEntryLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return accountingEntryLinesFieldList;
    }
    
    public List<Object> getSearchFilters() {
    	SegmentService segmentSvc = new SegmentService();
    	List<Segment_Definition__c> segments = segmentSvc.segments;
    	List<Object> searchFilters = new List<Object>();
    	
    	searchFilters.add(new Map<String, Object>{ 'field' => 'Accounting_Entry__r.Period__c', 'title' => Accounting_Entry__c.Period__c.getDescribe().getLabel(), 'fieldtype' => 'custom' });

		for (Segment_Definition__c segment : segments) {
			searchFilters.add(new Map<String, Object>{ 'field' => segment.Name, 'title' => util.getGlobalDescribe(segment.Name).getDescribe().getLabel(), 'fieldtype' => 'reference' });
		}
    	    	    	
    	searchFilters.add(new Map<String, Object>{ 'field' => 'Accounting_Entry__r.Transaction_Type__c', 'title' => Accounting_Entry__c.Transaction_Type__c.getDescribe().getLabel(), 'fieldtype' => 'picklist' });
    	searchFilters.add(new Map<String, Object>{ 'field' => 'SubTransaction_Type__c', 'title' => Accounting_Entry_Line__c.SubTransaction_Type__c.getDescribe().getLabel(), 'fieldtype' => 'picklist' });
		
    	return searchFilters;
    }
    
    public String getSearchFiltersJson() {
    	List<Object> searchFilters = getSearchFilters();
    	
    	return JSON.serialize(searchFilters);
    }
    
    public SelectOption[] getPeriodRangeOptions() {
        List<SelectOption> periodRangeOptions = new List<SelectOption>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name'
		});
		soql.setOrderByClause('Period_Start__c ASC');

		for (Period__c period : Database.query(soql.getQuery())) {
            periodRangeOptions.add(new SelectOption(period.Id, period.Name));
        }
        
        return periodRangeOptions;
    }
    
    public SelectOption[] getPeriodFromRangeOptions() {
        List<SelectOption> periodFromRangeOptions = new List<SelectOption>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Period_Start__c','Name'
		});
		soql.setOrderByClause('Period_Start__c ASC');

		for (Period__c period : Database.query(soql.getQuery())) {
            periodFromRangeOptions.add(new SelectOption(period.Period_Start__c.format(), period.Name));
        }
        
        return periodFromRangeOptions;
    }

    public SelectOption[] getPeriodToRangeOptions() {
        List<SelectOption> periodToRangeOptions = new List<SelectOption>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Period_End__c','Name'
		});
		soql.setOrderByClause('Period_End__c ASC');
		for (Period__c period : Database.query(soql.getQuery())) {
            periodToRangeOptions.add(new SelectOption(period.Period_End__c.format(), period.Name));
        }
        
        return periodToRangeOptions;
    }
    
    @ReadOnly
    @RemoteAction 
    public static DataSourceResult getAccountingEntryLines(List<KendoUtils.FilterDescriptor> filters, GridRelatedListController.GridRelatedListConfig config) {
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        set<String> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
        List<String> filterCriteria = KendoUtils.getFilterCriteria(filters);
        
        String whereClause = '';
        
        if (filterCriteria.size() > 0) {
        	whereClause += String.join(filterCriteria, ' AND ');
        }
        
        if(String.isNotBlank(config.sortField)){
            whereClause += ' ORDER BY ' + config.sortField;
            if(String.isNotBlank(config.sortOrder)){
                whereClause += ' ' + config.sortOrder;
            }
        }
        
        SOQLUtil soql = new SOQLUtil(config.objectName, TRUE);
        if(String.isNotBlank(fieldset)) {
            soql.addFields(fieldset);
        }
        if(addlFields != null) {
          soql.addFields(addlFields);
        }
        soql.setWhereClause(whereClause);
        
        system.debug(Logginglevel.info, soql.getQuery());
        List<sObject> result = database.query(soql.getQuery());
        system.debug(Logginglevel.info, result);
 
        return new DataSourceResult(result, result.size());
    }
}