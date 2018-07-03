public with sharing class InventoryTransactionsHistoryExt extends BaseController {
	ApexPages.StandardController con;
	public string NamespaceUU { get { return KSE.NamespaceUU; }}
	private static SchemaUtil util = SchemaUtil.getInstance();
	public GridRelatedListController.GridRelatedListConfig lotMasterHistoryLinesConfig {get; set;}	
	public Boolean isHideResultsOnPageLoad {get; set;}	
    private Id itemId;
    
    public InventoryTransactionsHistoryExt(ApexPages.StandardController controller) {
        con = controller;
        isHideResultsOnPageLoad = true;
		
		// Lot Master History Lines Grid config
        lotMasterHistoryLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        lotMasterHistoryLinesConfig.uniqueId = 'LotMasterHistoryGrid';
        lotMasterHistoryLinesConfig.title = 'Inventory Transactions History Lines';
        lotMasterHistoryLinesConfig.objectName = 'Inventory_Transaction__c';
        lotMasterHistoryLinesConfig.fieldset = 'Inventory_History_Lines';
        lotMasterHistoryLinesConfig.buttons = 'search, excel, pdf';
        lotMasterHistoryLinesConfig.additionalFields = 'From_Lot__c,From_Lot__r.Name,Purchase_Order_Line__c, Purchase_Order_Line__r.Name, Purchase_Order_Line__r.Purchase_Order__c, Purchase_Order_Line__r.Purchase_Order__r.Name, Receipt_Line__c, Receipt_Line__r.Name, Receipt_Line__r.Purchase_Order__r.Name, Sales_Order_Line__c, Sales_Order_Line__r.Name, Sales_Order_Line__r.Sales_Order__c, Sales_Order_Line__r.Sales_Order__r.Name, Receipt_Line__r.Name, Shipment_Line__r.Name, Work_Order__c, Work_Order__r.Name, Inventory_Change__c, Inventory_Change__r.Name, Inventory_Change__r.Reason_Code__r.Name, Order_Line__c, Order_Line__r.Name, Order_Line__r.Order__c, Order_Line__r.Order__r.Name,From_Location__r.Facility__c';
        lotMasterHistoryLinesConfig.sortField = 'Transaction_Date__c';
        lotMasterHistoryLinesConfig.sortOrder = 'DESC';
    }
    
    public string getlotMasterHistoryLinesConfigJson() {
    	return JSON.serialize(lotMasterHistoryLinesConfig);
    }
	
    public string getLotMasterHistoryFieldList() {
    	List<FieldInfo> fieldInfoList = new List<FieldInfo>();
    		
    	if (lotMasterHistoryLinesConfig != null) {
	    	FieldInfo fieldInfoItem;
	    	// get the lot master history lines field info list
	        fieldInfoList = FieldInfo.fetchJsonFieldInfos(lotMasterHistoryLinesConfig.objectName, lotMasterHistoryLinesConfig.fieldset);
	        
	        // set all the fields as readonly
	        for(Integer i = 0; i < fieldInfoList.size(); i++){
	        	fieldInfoList[i].field = 'it.' + fieldInfoList[i].field;
	        	fieldInfoList[i].editable = false;
	        }
	            
	        // balance field
			fieldInfoItem = new FieldInfo('balance', 'Balance', 'double');
			fieldInfoItem.scale = 6;
			fieldInfoItem.precision = 2;
			fieldInfoItem.sortable = false;
			fieldInfoItem.editable = false;
	        fieldInfoList.add(fieldInfoItem);
	        
	        // reference number field
			fieldInfoItem = new FieldInfo('referenceNumber', Label.Reference +'#', 'string');
			fieldInfoItem.editable = false;
	        fieldInfoList.add(fieldInfoItem);
	        
	        // source document field
			fieldInfoItem = new FieldInfo('sourceDocument', Label.Source_Document, 'string');
			fieldInfoItem.editable = false;
	        fieldInfoList.add(fieldInfoItem);
	        
	        // reason code field
			fieldInfoItem = new FieldInfo('reasonCode', Schema.SObjectType.Reason_Code__c.getLabel(), 'string');
			fieldInfoItem.editable = false;
	        fieldInfoList.add(fieldInfoItem);
    	}
    	
        return JSON.serialize(fieldInfoList);
    }
    
    public SelectOption[] getTransactionTypeOptions() {
        List<SelectOption> options = new List<SelectOption>();
		
        for (SelectListItem listItem : getPicklistValues('Inventory_Transaction__c', 'Type__c')) {
        	if (String.isNotBlank(listItem.value)) {
            	options.add(new SelectOption(listItem.value, listItem.text));
        	}
        }
        
        return options;
    }
    
    @RemoteAction 
    public static JsonResult getLotMasterHistoryLines(List<KendoUtils.FilterDescriptor> filters, String referenceNumber, GridRelatedListController.GridRelatedListConfig config) {
    	List<LotMasterHistoryWrapper> result = new List<LotMasterHistoryWrapper>();
    	List<Inventory_Transaction__c> itList = new List<Inventory_Transaction__c>();
    	List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
    	List<KendoUtils.FilterDescriptor> newFacilityFilters = new List<KendoUtils.FilterDescriptor>();
		
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        set<String> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
        
        String whereClause = '';
        Id facilityId;
        
        for(KendoUtils.FilterDescriptor fd: filters){
            
            if ((fd.field == 'To_Location__r.Facility__c' || fd.field == 'From_Location__r.Facility__c') && fd.value !=null){
	            newFacilityFilters.add(fd);
	            facilityId = (Id)fd.value;
            }
            else
            	newFilters.add(fd);
            	
    	}
	    List<String> filterCriteria = KendoUtils.getFilterCriteria(newFilters);
	    List<String> filterfacilityCriteria = KendoUtils.getFilterCriteria(newFacilityFilters);
	    
	    if (String.isNotBlank(referenceNumber)) {
        	referenceNumber = String.escapeSingleQuotes(referenceNumber);
        	filterCriteria.add(String.format('(Purchase_Order_Line__r.Name LIKE \'\'%{0}%\'\' OR Receipt_Line__r.Name LIKE \'\'%{0}%\'\' OR Sales_Order_Line__r.Name LIKE \'\'%{0}%\'\' OR Shipment_Line__r.Name LIKE \'\'%{0}%\'\' OR Work_Order__r.Name LIKE \'\'%{0}%\'\' OR Inventory_Change__r.Name LIKE \'\'%{0}%\'\' OR Order_Line__r.Name LIKE \'\'%{0}%\'\')', new String[] { referenceNumber }));
        }
        
        
	    if (filterCriteria.size() > 0) {
	       whereClause += String.join(filterCriteria, ' AND ');
	    }
	    if (filterfacilityCriteria.size() > 0) {
        	whereClause += ' AND ('+String.join(filterfacilityCriteria, ' OR ') + ')';
        }
	    
	    if(String.isNotBlank(config.sortField)){
	        whereClause += ' ORDER BY ' + config.sortField;
	        if(String.isNotBlank(config.sortOrder)){
	            whereClause += ' ' + config.sortOrder;
	        }
	    }
        
        /*String queryString = util.generateQueryFromFieldSet(config.objectName, new Set<string>{ fieldset }, addlFields, whereClause);
        system.debug('QS:' + queryString);*/
        
        SOQLUtil soql = new SOQLUtil(config.objectName);
	    soql.addFields(fieldset);
	    soql.addFields(addlFields);
	    soql.setWhereClause(whereClause);
	    
        itList = Database.query(soql.getQuery());   
        
        for (Inventory_Transaction__c it: itList) {
        	
        	if(it.Type__c != 'Transfer Order Shipment' || (it.Type__c == 'Transfer Order Shipment' && it.From_Location__r.Facility__c == facilityId)){
        		result.add(new LotMasterHistoryWrapper(it));
        	}
			
        }
    
    	return new JsonResult(result, result.size());
    }
        
    public with sharing class LotMasterHistoryWrapper {
    	public Inventory_Transaction__c it {get; set;}
        public String referenceNumber {get; set;}
        public String sourceDocument {get; set;}
        public String reasonCode {get; set;}
        
        public LotMasterHistoryWrapper(Inventory_Transaction__c inventoryTransaction) {
        	it = inventoryTransaction;
			Id referenceId = null;
			String referenceName = null;
			Id sourceDocId = null;
			String sourceDocName = null;
			
			if (it.Purchase_Order_Line__c != null) {
					referenceId = it.Purchase_Order_Line__c;
					referenceName = it.Purchase_Order_Line__r.Name;
				
				sourceDocId = it.Purchase_Order_Line__r.Purchase_Order__c;
				sourceDocName = it.Purchase_Order_Line__r.Purchase_Order__r.Name;
				}
			else if (it.Receipt_Line__c != null) {
				referenceId = it.Receipt_Line__c;
				referenceName = it.Receipt_Line__r.Name;
				
				sourceDocId = it.Receipt_Line__r.Purchase_Order__c;
				sourceDocName = it.Receipt_Line__r.Purchase_Order__r.Name;
			}
			else if (it.Sales_Order_Line__c != null) {
				if (it.Shipment_Line__c != null) {
					referenceId = it.Shipment_Line__c;
					referenceName = it.Shipment_Line__r.Name;
				}
				else {
					referenceId = it.Sales_Order_Line__c;
					referenceName = it.Sales_Order_Line__r.Name;
				}
				
				sourceDocId = it.Sales_Order_Line__r.Sales_Order__c;
				sourceDocName = it.Sales_Order_Line__r.Sales_Order__r.Name;
			}
			else if (it.Work_Order__c != null) {
				referenceId = it.Work_Order__c;
				referenceName = it.Work_Order__r.Name;
				
				sourceDocId = referenceId;
				sourceDocName = referenceName;
			}
			else if (it.Inventory_Change__c != null) {
				referenceId = it.Inventory_Change__c;
				referenceName = it.Inventory_Change__r.Name;
				
				sourceDocId = referenceId;
				sourceDocName = referenceName;
			}
			else if (it.Order_Line__c != null) {
				referenceId = it.Order_Line__c;
				referenceName = it.Order_Line__r.Name;
			
				sourceDocId = it.Order_Line__r.Order__c;
				sourceDocName = it.Order_Line__r.Order__r.Name;
			}
			
			if (referenceId != null && referenceName != null) {
				referenceNumber = string.format('<a href="/{0}" target="_blank">{1}</a>', new string[] { referenceId, referenceName });
			}
			
			if (sourceDocId != null && sourceDocName != null) {
				sourceDocument = string.format('<a href="/{0}" target="_blank">{1}</a>', new string[] { sourceDocId, sourceDocName });
			}
			
            if (it.Inventory_Change__c != null) {
	            reasonCode = it.Inventory_Change__r.Reason_Code__r.Name;
            }
            if (it.Lot__c == null && it.From_Lot__c != null) {
                it.Lot__c = it.From_Lot__c;
                it.Lot__r = it.From_Lot__r;
            }
        }
    }
    
}