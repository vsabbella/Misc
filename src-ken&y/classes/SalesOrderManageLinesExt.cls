/** 
 *  File Name: SalesOrderManageLinesExt.cls
 *  
 *  @Description: SalesOrderManageLinesExt contains all the classes and methods needed for
 *          for the SalesOrderManageLines.page to be fully functional
 *  @Copyright : Kenandy, Inc. 2015
 *  @author : Jerome Israel
 *  @Date : 04/22/2015
* */ 
public with sharing class SalesOrderManageLinesExt extends GridRelatedListController {

    private static TaxService taxation = TaxService.getInstance();

    public String pageTitle { get; set; }
    public String segmentLinesFieldList = null;
    public String salesOrderLinesFieldList = null;  
    public String soLineAllowancesFieldList = null;
    
    public Apexpages.StandardController controller;
    public static Boolean uiReadOnly { get; set; }
    public Sales_Order__c theSalesOrder { get;  set;}           //Sales order we will operate on , used by the page
    public Boolean isSOLineModificationAllowed { get; set;}
    public Boolean hasTax{get;private set;}
    
    public SegmentService segmentSvc = new SegmentService();
    public static SchemaUtil util = SchemaUtil.getInstance();

    public string NamespaceUU { get { return KSE.NamespaceUU; }}

    public GridRelatedListController.GridRelatedListConfig salesOrderLinesConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig soLineAllowancesConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig segmentLinesConfig {get; set;}

    public String InventoryFieldList = null;
    public GridRelatedListController.GridRelatedListConfig InventoryConfig {get; set;}

    public Map<String, FieldInfo> allFieldsMap = new Map<String, FieldInfo>();

    public List<Grid_Views_Config__c> gridViews = null;

    public Id soldToCustRecordType { get; set; }
    public Id billToCustRecordType { get; set; }
    public Id shipToCustRecordType { get; set; }
    public Id siteCustRecordType { get; set; }

    public String getInventoryConfigJson() {
        String configStr = JSON.serialize(this.InventoryConfig);
        return configStr;
    }

    public static Map<String, String> soLineManageAllowancesPageVariables = new Map<String, String>{'GridTitle' => 'Manage Sales Order Line Allowances',
                                                                                                    'GridFieldSet' => 'Manage_Line_Allowances' , //Primary field set for the Manage SO Line Allowance page
                                                                                                    'GridReadOnlyFieldSet' => 'Manage_Line_Allowances_RO',
                                                                                                    'ObjectName' => 'Allowance_Applied__c',
                                                                                                    'ParentField' => 'Sales_Order_Line__c',
                                                                                                    'GridSortField' => 'Name',
                                                                                                    'GridSortOrder' => 'DESC'
                                                                                                    };

    public static Map<String, String> soManageLinesPageVariables = new Map<String, String>{'GridFieldSet' => 'Master',//'Manage_Lines' , //Primary field set for the SO Manage Lines page
                                                                                           'GridReadOnlyFieldSet' => 'Master_RO',//'Manage_Lines_RO',
                                                                                           'GridDefaultViewFieldSet' => 'Manage_Lines',
                                                                                           'ObjectName' => 'Sales_Order_Line__c',
                                                                                           'ParentField' => 'Sales_Order__c',
                                                                                           'htmlDivGridId' => 'GridAddManageSalesOrderLines',
                                                                                           'GridSortField' => 'Line__c',
                                                                                           'GridSortOrder' => 'DESC'}; 

    //Any read only fields that needs to populated with values should be handled at Javascript (Kendo Limitation)
    //These fields will NOT have the property "editable" set to false from the controller side but will be set 
    //at the UI through Javascript                                                                   
    public static Set<String> readOnlyFieldsHandledAtUI = new Set<String>{'Line__c', 'Fulfillment_Source__c'};

    //Front end UI validation error for cancelled or closed sales order lines
    public static String KNDO_CANCELED_CLOSED_LINE_ERROR = 'Cancelled or Closed sales order lines cannot be modified.';
    public static String KNDO_REQUIRED_FIELD_LINE_ERROR = 'Required field is missing : ';

    //Page messages
    public static String KNDO_INVALID_PRODUCT_REFERENCE {
        get {
            return 'The Product Reference value is no longer valid. You can remove the Reference and save, or you can delete the line.';
        }
    }
    public static String KNDO_PAGE_HEADER_ERROR_MSG { 
        get { 
            return 'One or more Sales Order lines has errors.'; 
        } 
    }

    public static String KNDO_PAGE_HEADER_EXCEPTION_MSG {
        get {
            return 'One or more Sales Order lines has exceptions.';
        }
    } 

    public static String KNDO_PAGE_HEADER_SO_STATUS_WARNING_MSG {
        get {
            return 'Sales Order line modifications are not allowed for a closed or cancelled Sales Order.';
        }
    }

    public static String KNDO_PAGE_HEADER_GENERAL_EXCEPTION_MSG { 
        get { 
            return 'Unexpected exception occured. Please contact support.'; 
        } 
    }
    public static String KNDY_INVALID_ORDER_QUANTITY { 
        get { 
            return 'Sales Order Lines Order quantity must be more than closed req lines qty, if you want to decrease the qty please cancel the req and rerelease the SO.'; 
        } 
    }
    public static String KNDO_DELETE_SO_LINE_STATUS_ERROR { 
        get { 
            return 'Only Sales Order Lines that are in Draft status could be deleted.'; 
        } 
    }

	public static string KNDO_DELETE_SO_LINE_SHIPPED_ERROR {
		get {
			return 'Cannot delete Sales Order Line that has Shipped Quantities.';
		}
	}

    public static String KNDO_SO_MANAGE_LINES_DUPLICATE_LINE_NUMBERS_ERROR {
        get { 
            return 'Duplicate line numbers are not allowed.'; 
        } 
    }

    public static String KNDO_SO_PRODUCT_ITEM_KIT_NON_INVENTORY_FULFILLMENT_SOURCE_ERROR {
        get{
            return 'Sales Order Line with Product -> Item -> Item Source = \'Kit\' can only be created with Fulfillment Source = \'Inventory\'';
        }
    }

	public static String KNDO_SOL_ITEM_SPEC_AND_SHIP_FROM_LOCATION_MISMATCH {
		get {
			return 'Item Specification and Ship From Location should have matching Facility.';
		}
	}
    public static String getSalesOrderTypeRepair(){

            return SalesOrderService.SO_TYPE_REPAIR;
    }

    //Constructor
    public SalesOrderManageLinesExt(ApexPages.standardcontroller con) {       
        controller = con;
        uiReadOnly = false;

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		ID conId = con.getId();
        theSalesOrder = new Sales_Order__c();

        if( con.getRecord().id != null ) {
            SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{

                    'Id', 'Company__c','Company__r.Use_Warranty_Repairs__c', 'Customer__c', 'Customer__r.Top_Parent_Customer__c', 'Customer__r.Top_Parent_Customer__r.Id', 'Customer__r.Pricebook__c',
                    'Customer__r.Order_Quantity_Factor_At__c', 'Customer__r.Customer_Group__c', 'Date_Time_Ordered__c', 'Dimension_UOM__c',
                    'Dimension_UOM__r.Name', 'Name', 'Pricebook__c', 'Pricebook__r.Name', 'Pricing_Date__c', 'Price_Determination_Date__c', 'Required_Date__c',
                    'Status__c', 'Subtotal__c', 'Ship_From_Location__c', 'Ship_From_Location__r.Id', 'Ship_From_Location__r.Name', 'Ship_to__c', 'Type__c', 'Currency__c',
                    'Weight_UOM__c', 'Weight_UOM__r.Name','Ship_From_Location__r.Facility__c', 'Ship_From_Location__r.Facility__r.Name'
            });
            soql.addFields(AllowanceRuleService.salesOrderFields);
            soql.setWhereClause('Id = :conId');

            theSalesOrder = Database.query(soql.getQuery());
            hasTax = taxation.taxServiceConfigured(theSalesOrder) ;//&& !taxBlackListedInvoiceTypesForCI.contains(theSalesOrder.Type__c);
            pageTitle = 'Sales Order ' + theSalesOrder.Name;

            if (ApexPages.currentPage().getParameters().containsKey('clone') && ApexPages.currentPage().getParameters().get('clone') == '1') {
                pageTitle = 'Clone of Sales Order ' + theSalesOrder.Name;
            }
        }else{
			System.debug( logginglevel.error, '~*~ con.getRecord() :' + con.getRecord() );

			// using this to retrieve new SO record relationships such as Opportunity__c when creating New SO from Opportunity related list.
			Sales_Order__c soCon = (Sales_Order__c) con.getRecord();

			Map<String, Schema.SObjectField> soFields = Sales_Order__c.getSobjectType().getDescribe().fields.getMap();
			for (Schema.SObjectField objField : soFields.values()){
				DescribeFieldResult dfr = objField.getDescribe();
				String fieldName = dfr.name;

				if (soCon.get(fieldName) == null){
					continue;
				}

				theSalesOrder.put(fieldName, soCon.get(fieldName));
			}


            theSalesOrder.Type__c = 'Standard';
            theSalesOrder.Status__c = 'Draft';
            CompanyService compServ = new CompanyService(controller);
            UserPreference usp = UserPreference.getInstance();
            theSalesOrder.Company__c = CompanyService.getDefaultCompanyId();
            theSalesOrder.Company__r = compServ.Company;
            theSalesOrder.Currency__r = CompanyService.defaultTransactionCurrencyRec(theSalesOrder.Company__c);
            theSalesOrder.Date_Time_Ordered__c = system.now();
            if(theSalesOrder.Currency__r != null){
                theSalesOrder.Currency__c = CompanyService.defaultTransactionCurrencyRec(theSalesOrder.Company__c).Id;
            }
            pageTitle = 'Sales Order';
        }

        billToCustRecordType = Schema.SObjectType.Customer__c.RecordTypeInfosByName.get('Bill To').RecordTypeId;
        soldToCustRecordType = Schema.SObjectType.Customer__c.RecordTypeInfosByName.get('Sold To').RecordTypeId;
        shipToCustRecordType = Schema.SObjectType.Customer__c.RecordTypeInfosByName.get('Ship To').RecordTypeId;
        siteCustRecordType = Schema.SObjectType.Customer__c.RecordTypeInfosByName.get('Site').RecordTypeId;

        system.debug(LoggingLevel.Error, 'theSalesOrder--'+theSalesOrder);
        initializeSOManageLines();
        initializeSOLineManageAllowance();

    }

    public String getReturnUrl(){
        PageReference pageRef;

        if (theSalesOrder != null && theSalesOrder.Id != null ){
            pageRef =  new PageReference('/' + theSalesOrder.Id);
        }
        else{
            Schema.DescribeSObjectResult dsr = Sales_Order__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());
        }

        return pageRef.getUrl();
    }

    /*
     *  getSalesOrderLinesConfigJson method return the sales order line config
     *  
     *  @return configStr String
     *
     */
    public String getSalesOrderLinesConfigJson() {

        String configStr = JSON.serialize(this.salesOrderLinesConfig);
          
        return configStr;
    }
    
    /*
     *  getSOLineAllowancesConfig method return the sales order Manage Allowances config
     *  
     *  @return configStr String
     *
     */
    public String getSOLineAllowancesConfigJSON() {

        String configStr = JSON.serialize(this.soLineAllowancesConfig);
          
        return configStr;
    }

    /*
     *  initializeSOLineManageAllowance method sets the page defaults
     *  
     *
     */
    public void initializeSOLineManageAllowance(){

        Set<String> allowanceAdditionalFields = new set<string> {
            'Allowance_Type__r.Manual__c', 'Allowance_Type__r.Basis__c', 'Allowance_Type__r.Percent_Of_Target_Field__c','Allowance_Rule2__r.Allowance_Code__c',
            'Allowance_Type__r.Amount__c', 'Allowance_Type__r.Target_Field__c', 'Allowance_Type__r.Rate_Field__c', 'Allowance_Rule2__c', 'Allowance_Rule2__r.Name', 'Allowance_Code__c'
        };

        allowanceAdditionalFields.addAll(AllowanceRuleService.allowanceAppliedFields);

        soLineAllowancesConfig = new GridRelatedListController.GridRelatedListConfig();
        soLineAllowancesConfig.title = soLineManageAllowancesPageVariables.get('GridTitle');
        soLineAllowancesConfig.objectName = soLineManageAllowancesPageVariables.get('ObjectName');
        soLineAllowancesConfig.fieldset = soLineManageAllowancesPageVariables.get('GridFieldSet');
        soLineAllowancesConfig.parentField = soLineManageAllowancesPageVariables.get('ParentField');
        soLineAllowancesConfig.additionalFields = String.join(new List<String>(allowanceAdditionalFields), ',');
        soLineAllowancesConfig.buttons = 'create,save,cancel,delete';
        soLineAllowancesConfig.sortField = soLineManageAllowancesPageVariables.get('GridSortField');
        soLineAllowancesConfig.sortOrder = soLineManageAllowancesPageVariables.get('GridSortOrder');
    }
    /*
     *  initializeSOManageLines method sets the page defaults
     *  
     *
     */
    public void initializeSOManageLines(){

        List<String> segmentsList = segmentSvc.segmentNameList();
        Set<String> salesOrderLinesAdditionalFields = new Set<String>();

        salesOrderLinesAdditionalFields.addAll(new set<string>{
				'Accounting_Segment__c',
				'Available_Inventory__c',
				'Company__c',
				'Name',
				'Product__r.Item__c',
				'Product__r.Item__r.Stocking_UOM__c',
				'Product__r.Item__r.Packaging_UOM__c',
				'Product__r.Item__r.Fulfillment_Source__c',
				'Product__r.Item_Specification__c',
				'Product_Reference__c',
				'Product_Reference__r.Id',
				'Product_Reference__r.name',
				'Product_Reference__r.Active__c',
				'Item_Specification__c',
				'Selling_UOM__c',
				'Quantity_Allocated__c',
				'Quantity_Shipped__c',
				'Price_Type__c',
				'Pricing_UOM__c',
				'Status__c',
				'New_Pricing_Rule__c',
				'Line__c',
				'List_Price__c',
				'Product__r.Units_per_Layer__c',
				'Product__r.Units_per_Pallet__c',
				'Ship_From_Location__r.Facility__c',
				'Ship_From_Location__r.Facility__r.Facility_Identifier__c',
				'Sales_Order__c',
				'Sales_Order__r.Type__c',
				'Sales_Order__r.Price_Determination_Date__c',
				'Fulfillment_Source__c',
				'Related_Sales_Order_Line__c',
				'Non_Shippable__c',
				'Pricebook_Line__c',
				'Pricebook_Line__r.Use_Fixed_Pricing__c',
				'Pricebook_Line__r.Min__c',
				'Pricebook_Line__r.Max__c',
				'Pricebook_Line__r.Pricebook__c',
				'Product__r.Item__r.Non_Inventory__c',
				'Product__r.Item__r.Source__c',
				'Item_Specification__r.Facility__c'
		});

        if(taxation.taxServiceConfigured(theSalesOrder)){
            List<FieldInfo> taxFields = taxation.getDisplayFieldSet(Sales_Order__c.getSobjectType());

            if(taxFields != null){
                for(FieldInfo tf : taxFields){
                    salesOrderLinesAdditionalFields.add(tf.field);
                }
            }
        }

        for (Integer i =0; i < segmentsList.size(); i++) {

            segmentsList[i] = 'Accounting_Segment__r.' + segmentsList[i];
        }

        salesOrderLinesAdditionalFields.addAll(segmentsList);
        
        for (Integer i = 0; i < segmentsList.size(); i++) {

            salesOrderLinesAdditionalFields.add(segmentsList[i].replace('__c', '__r.Name'));
        }
        
        //Kendo Grid config
        salesOrderLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        salesOrderLinesConfig.uniqueId = soManageLinesPageVariables.get('htmlDivGridId');
        salesOrderLinesConfig.parentRecord = theSalesOrder;
        salesOrderLinesConfig.objectName = soManageLinesPageVariables.get('ObjectName');
        salesOrderLinesConfig.parentField = soManageLinesPageVariables.get('ParentField');
        //salesOrderLinesConfig.fieldset =  soManageLinesPageVariables.get('GridFieldSet');
        salesOrderLinesConfig.additionalFields = String.join(new List<String>(salesOrderLinesAdditionalFields), ',');
        salesOrderLinesConfig.sortField = soManageLinesPageVariables.get('GridSortField');
        salesOrderLinesConfig.sortOrder = soManageLinesPageVariables.get('GridSortOrder');

        salesOrderLinesConfig.buttons = 'create, cancel, delete, excel, print, columnmenu, search';
        isSOLineModificationAllowed = true;

        if (theSalesOrder.id != null && !pageTitle.contains('Clone')) {
            if (theSalesOrder.Status__c.equals(SalesOrderLineService.SO_LINE_STATUS_CLOSED) || theSalesOrder.Status__c.equals(SalesOrderLineService.SO_LINE_STATUS_CANCELLED)) {

                isSOLineModificationAllowed = false;
                salesOrderLinesConfig.buttons = 'excel, columnmenu, print, search';
            }
        }
        
        // Segment Lines Grid config
        segmentLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        segmentLinesConfig.uniqueId = 'SegmentLinesGrid';
        segmentLinesConfig.objectName = 'Accounting_Default__c'; 

        InventoryConfig = new GridRelatedListController.GridRelatedListConfig();
        InventoryConfig.uniqueId = 'InventoryGrid';
        InventoryConfig.objectName = 'SKID__c';
        InventoryConfig.buttons = 'columnmenu, search';
    }

    /*
     *  getColumnIndex method fetches the index of the column field name. It returns 0 if no match found
     *
     *  @param  fieldInfoList
     *  @param  fieldName
     *  @return Integer    
     *
     */
    public Integer getColumnIndex(List<FieldInfo> fieldInfoList, String fieldName){

        for(Integer i = 0; i < fieldInfoList.size(); i++) {

            if(fieldInfoList[i].field == fieldName){
                return i;
            }
        }

        return 0;
    }

    /*
     *  getGridViews method prepares the list of views to be listed on the dropdown box in the UI
     *
     *  @param  fieldInfoList
     *  @param  fieldName
     *  @return Integer    
     *
     */
    public String getGridViews() {
        List<SelectListItem> viewList = new List<SelectListItem>();
        List<Grid_Views_Config__c> gridViews = this.gridViews == null ? KSE.getGridViews(soManageLinesPageVariables.get('htmlDivGridId')) : this.gridViews;

        // use for preventing duplicate field set values in grid views
        Set<String> existingViews = new Set<String>();

        existingViews.add(soManageLinesPageVariables.get('GridDefaultViewFieldSet'));

        for(Grid_Views_Config__c gvConfig: gridViews){

            if (!existingViews.contains(gvConfig.Fieldset_Name__c.toLowerCase())){

                viewList.add(new SelectListItem(gvConfig.Fieldset_Name__c, gvConfig.View_Name__c));
                existingViews.add(gvConfig.Fieldset_Name__c.toLowerCase());
            }
        }

        if (gridViews.isEmpty() || gridViews[0].View_Dropdown_Index__c == 0){
            viewList.add(new SelectListItem(soManageLinesPageVariables.get('GridDefaultViewFieldSet'), 'Default'));
        } else {
            viewList.add(0,new SelectListItem(soManageLinesPageVariables.get('GridDefaultViewFieldSet'), 'Default'));
        }

        return JSON.serialize(viewList);
    }

    /*
     *  getUIFieldNames method prepares and puts the UI field names in a list and returns it.
     *
     *  @param  fieldInfoList
     *  @return List<String>    
     *
     */
    private List<String> getUIFieldNames(List<FieldInfo> fieldInfoList){
        List<String> fieldNames = new List<String>();

        for(FieldInfo f: fieldInfoList){
            fieldNames.add('soLine.' + f.field);
        }
        return fieldNames;
    }

    public String getAllFields(){
        if (allFieldsMap.keySet().isEmpty()){
            getGridViewFields();
        }

        return JSON.serialize(allFieldsMap.keySet());
    }

    /*
     *  getGridViewFields method fetches list of fields on associated with a fieldset that are part of the grid views
     *
     *  @return String    
     *
     */
    public String getGridViewFields() {

        Map<String, List<String>> gridViewFieldsMap = new Map<String, List<String>>();
        
        List<Grid_Views_Config__c> gridViews = this.gridViews == null ? KSE.getGridViews(soManageLinesPageVariables.get('htmlDivGridId')) : this.gridViews;

        gridViews.add(new Grid_Views_Config__c(Fieldset_Name__c = soManageLinesPageVariables.get('GridDefaultViewFieldSet')));

        for(Grid_Views_Config__c gvConfig: gridViews){

            List<String> fieldNames = new List<String>();
            //Ignore the fieldset that has been loaded already
            if(gridViewFieldsMap.containsKey(gvConfig.Fieldset_Name__c)){
                continue;
            }

            try {

                List<FieldInfo> fieldList = FieldInfo.fetchJsonFieldInfos(soManageLinesPageVariables.get('ObjectName'), gvConfig.Fieldset_Name__c);
                
                for (FieldInfo fi : fieldList){
                    if (!allFieldsMap.containsKey(fi.field) || fi.required){
                        allFieldsMap.put(fi.field, fi);
                    }
                }

                fieldNames = getUIFieldNames(fieldList);

            } catch (FieldInfo.EmptyFieldSetMemberException e) {
                //ignnore invalid fieldsets
            }
            
            gridViewFieldsMap.put(gvConfig.Fieldset_Name__c, fieldNames);
        }
        
        //gridViewFieldsMap.put(soManageLinesPageVariables.get('GridFieldSet'), new List<String>(getUIFieldNames(new List<FieldInfo>(allFields))));

        return JSON.serialize(gridViewFieldsMap);
    }

    /*
     *  getSalesOrderLinesFieldList method fetches all the Sales Order line fields that needs to be shown on/off screen.
     *
     *  @return salesOrderLinesFieldList String    
     *
     */
    public string getSalesOrderLinesFieldList() {

        if (salesOrderLinesFieldList == null && salesOrderLinesConfig != null) {

            List<FieldInfo> readOnlyFieldInfoList = new List<FieldInfo>();
            Set<String> readOnlyFields = new Set<String>();

            Set<String> segmentFields = new Set<String>();
            // get the sales order lines field info list
            //List<FieldInfo> soLineFieldInfoList = FieldInfo.fetchJsonFieldInfos(salesOrderLinesConfig.objectName, salesOrderLinesConfig.fieldset);

            getGridViewFields();
            List<FieldInfo> soLineFieldInfoList = allFieldsMap.values();

            List<FieldInfo> availableSegments = (List<FieldInfo>) JSON.deserialize(KSE.getSegmentLinesFieldList(segmentLinesFieldList, segmentLinesConfig), List<FieldInfo>.class);

            List<FieldInfo> taxFields = null;
            if(taxation.taxServiceConfigured(theSalesOrder)){

                try{
                    taxFields = taxation.getDisplayFieldSet(Sales_Order__c.getSobjectType());

                    if(taxFields != null){
                        soLineFieldInfoList.addAll(taxFields);
                    }


                }catch(FieldInfo.EmptyFieldSetMemberException e) {
                    System.debug('#### Has Exception');
                    System.debug(e);
                }
                
            }
            

            try {

                readOnlyFieldInfoList = FieldInfo.fetchJsonFieldInfos(salesOrderLinesConfig.objectName, soManageLinesPageVariables.get('GridReadOnlyFieldSet'));
            }

            catch (FieldInfo.EmptyFieldSetMemberException e) {
                // Ignore EmptyFieldSetMemberException. Need to revisit the this logic so the empty field set would return an empty array instead

            }

            for(Integer i = 0; i < readOnlyFieldInfoList.size(); i++){

                if(!readOnlyFieldsHandledAtUI.contains(readOnlyFieldInfoList[i].field)){

                    readOnlyFields.add(readOnlyFieldInfoList[i].field);
                } else {

                    uiReadOnly = true;
                }
            }

            List<Integer> accountSegmentFieldIndexes = new List<Integer>();

            Boolean isStatusFieldAvailable = false;
            Boolean isQtyShippedFieldAvailable = false;
            // set the wrapper class prefix
            for(Integer i = 0; i < soLineFieldInfoList.size(); i++){
                //soLineFieldInfoList[i].hidden = true;
                //If the soLineFieldInfoList has any Accounting segment fields then add the field name to segmentFields list and 
                //also add the indexes of the segment fields to the accountSegmentFieldIndexes
                if(soLineFieldInfoList[i].field.toLowerCase().contains('accounting_segment__r.')){

                    segmentFields.add(soLineFieldInfoList[i].field.toLowerCase().substringAfter('accounting_segment__r.'));
                    accountSegmentFieldIndexes.add(i);
                }

                if(soLineFieldInfoList[i].field.toLowerCase() == 'status__c'){
                    isStatusFieldAvailable = true;
                }
                if(soLineFieldInfoList[i].field.toLowerCase() == 'quantity_shipped__c'){
                    isQtyShippedFieldAvailable = true;
                }


                if (soLineFieldInfoList[i].title.toLowerCase() == 'ship from location' && (SalesOrderService.SO_RMA_TYPES.contains(theSalesOrder.Type__c) || SalesOrderService.SO_RMA_REPLACEMENT_TYPES.contains(theSalesOrder.Type__c))) {
                    soLineFieldInfoList[i].title = 'Shipping/Receiving Location';
                }
                if(soLineFieldInfoList[i].field.toLowerCase().contains('product__r.')){

                    soLineFieldInfoList[i].title = 'Product ' + soLineFieldInfoList[i].title;
                }

                
                if (readOnlyFields.contains(soLineFieldInfoList[i].field)) {

                   soLineFieldInfoList[i].editable =  false;
                }

                soLineFieldInfoList[i].field = 'soLine.' + soLineFieldInfoList[i].field;
            }

            // Add status field if it is not available on the field set 
            // and set it as a hidden field, as we need it for validation purpose during dml operations
            if(!isStatusFieldAvailable){
                FieldInfo statusField = FieldInfo.fetchJsonFieldInfos(salesOrderLinesConfig.objectName, new string[] { 'Status__c' })[0];
                statusField.field = 'soLine.' + statusField.field;
                statusField.editable = false;
                statusField.hidden = true;
                soLineFieldInfoList.add(statusField);
            }

            if(!isQtyShippedFieldAvailable){
                FieldInfo qtyShippedField = FieldInfo.fetchJsonFieldInfos(salesOrderLinesConfig.objectName, new string[] { 'Quantity_Shipped__c' })[0];
                qtyShippedField.field = 'soLine.' + qtyShippedField.field;
                qtyShippedField.editable = false;
                qtyShippedField.hidden = true;
                soLineFieldInfoList.add(qtyShippedField);
            }
            //Remove Account Segment fields from the Manage Lines field set as we are handling 
            //Accounting Segments separately while saving the line
            for(Integer i = accountSegmentFieldIndexes.size() - 1; i >= 0 ; i--) {
                
                soLineFieldInfoList.remove(accountSegmentFieldIndexes[i]);
            }

            //Add available inventory column to the grid
            FieldInfo fi = FieldInfo.fetchJsonFieldInfos(salesOrderLinesConfig.objectName, new string[] { 'Available_Inventory__c' })[0];

            fi.field = 'soLine.' + fi.field;
            fi.editable = false;
            fi.hidden = true;
            soLineFieldInfoList.add(fi);

            //Add error column to the grid
            fi = new FieldInfo('errors', 'Errors', 'rowinfo');

            soLineFieldInfoList.add(0, fi);
            
            //Add  Quantity Factor column to the grid after the Selling UOM column
            fi = new FieldInfo('quantityFactor', 'Quantity Factor', 'Decimal');
            fi.editable = true;

            soLineFieldInfoList.add(getColumnIndex(soLineFieldInfoList, 'soLine.Selling_UOM__c') + 1, fi);

            //Add segment fields if any
            for(Integer i = 0; i < availableSegments.size(); i++){
                
                if(segmentFields.contains(availableSegments[i].field.toLowerCase())){
                    
                    FieldInfo segmentField = availableSegments[i];
                
                    if (segmentField.field == 'Id') {

                        segmentField.hidden = true;
                    }
                    segmentField.hidden = true;
                    segmentField.field = 'segments.' + segmentField.field;
                    soLineFieldInfoList.add(segmentField);
                }
            }
            
            soLineFieldInfoList.add(new FieldInfo('rowGUID', 'Row ID', 'string', true));

            salesOrderLinesFieldList = JSON.serialize(soLineFieldInfoList);
        }
        
        return salesOrderLinesFieldList;
    }

    public string getInventoryFieldList(){

        List<String> fields = new List<String>{'ID','Name','Location__c','Type__c','Quantity__c','Item__c'};
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c','Available_Inventory');
        for (FieldInfo f : fieldInfoList){
            f.required = false;
            f.filterable = true;
            f.editable = false;
            if (f.field == 'id'){
                f.hidden = true;
            }
        }
        InventoryFieldList = JSON.serialize(fieldInfoList);

        return InventoryFieldList;
    }

    /*
     *  getAllowanceLinesFieldList method returns the serialized string of all the field info list included in 
     *  the Manage Allowances page field set
     *
     *  @return String    
     *
     */
    public String getSOLineAllowancesFieldList() {

        String allowanceLinesFieldList = '';

        List<FieldInfo> allowanceFieldInfoList = new List<FieldInfo>();

        if (soLineAllowancesConfig != null) {

            //Get the primary field list
            for (FieldInfo field : FieldInfo.fetchJsonFieldInfos(soLineManageAllowancesPageVariables.get('ObjectName'),
                                                              soLineManageAllowancesPageVariables.get('GridFieldSet'))){
                if(field.field == 'Allowance_Code__c'){
                    field.fieldtype = 'reference'; // override type to make it a picklist
                }
                allowanceFieldInfoList.add(field);
            }

            allowanceLinesFieldList = JSON.serialize(allowanceFieldInfoList);

        }

        return allowanceLinesFieldList;
    }

    public string getsalesorderheaderJson() {
        return JSON.serialize(theSalesOrder);
    }

    public string getSalesOrderHeaderFieldList() {
        String salesorderHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        Set<String> readOnlyFields = new Set<String>();

        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Sales_Order__c', 'New_Sales_Order');

        fieldInfoList.remove(0); // Remove Id field from the list

        for(Integer i = 0; i < fieldInfoList.size(); i++) {
            if (fieldInfoList[i].field == 'Status__c') {
                fieldInfoList[i].editable = false;
            }
        }

        salesorderHeaderFieldList = JSON.serialize(fieldInfoList);

        return salesorderHeaderFieldList;
    }

    public string getSalesOrderAddlHeaderFieldList() {
        String salesOrderAddlHeaderFieldList = '';
        List<FieldInfo> result = new List<FieldInfo>();
        Set<String> headerFields = new Set<String>();
        List<FieldInfo> headerList = (List<FieldInfo>) JSON.deserialize(getSalesOrderHeaderFieldList(), List<FieldInfo>.class);

        for(Integer i = 0; i < headerList.size(); i++){
            headerFields.add(headerList[i].field);
        }

        try {
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Sales_Order__c', 'New_Sales_Order_Additional_Fields');

            fieldInfoList.remove(0);    // Remove Id field from the list

            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                if (!headerFields.contains(fieldInfoList[i].field)) {
                    result.add(fieldInfoList[i]);
                }
            }

            salesOrderAddlHeaderFieldList = (result.size() > 0) ? JSON.serialize(result) : '';
        }
        catch (FieldInfo.EmptyFieldSetMemberException e) {
            salesOrderAddlHeaderFieldList = '';
        }

        return salesOrderAddlHeaderFieldList;
    }

    @RemoteAction
    public static JsonResult getSalesOrderDetails(Id salesOrderId, String clone) {
        String objectName = 'Sales_Order__c';
        String headerFieldset = 'New_Sales_Order';
        String headerAddlFieldset = 'New_Sales_Order_Additional_Fields';
        Set<String> addlFields = new Set<String> { 'Id',  'Company__r.Use_Warranty_Repairs__c', 'Customer__c', 'Customer__r.Top_Parent_Customer__c', 'Customer__r.Top_Parent_Customer__r.Id', 'Customer__r.Pricebook__c',
                'Customer__r.Order_Quantity_Factor_At__c', 'Customer__r.Customer_Group__c', 'Date_Time_Ordered__c', 'Dimension_UOM__c',
                'Dimension_UOM__r.Name', 'Name', 'Pricebook__c', 'Pricebook__r.Name', 'Pricing_Date__c', 'Price_Determination_Date__c', 'Required_Date__c',
                'Status__c', 'Subtotal__c', 'Ship_From_Location__c', 'Ship_From_Location__r.Id', 'Ship_From_Location__r.Name', 'Ship_to__c', 'Type__c', 'Currency__c',
                'Weight_UOM__c', 'Weight_UOM__r.Name', 'Ship_From_Location__r.Facility__c', 'Ship_From_Location__r.Facility__r.Name' };

        string whereClause = 'Id  = :salesOrderId LIMIT 1';

        SOQLUtil soql = new SOQLUtil(objectName);
        soql.addFields(headerFieldset);
        soql.addFields(headerAddlFieldset);
        soql.addFields(addlFields);
        soql.setWhereClause(whereClause);

        List<Sales_Order__c> salesOrder = Database.query(soql.getQuery());

        if ( clone != null && clone == '1'){
            Sales_Order__c soClone = new Sales_Order__c();
            soClone = salesOrder[0].clone(false, true);
            soClone.Status__c = 'Draft';
            soClone.Required_Date__c = null;
            soClone.Date_Time_Ordered__c = system.now();
            soClone.Pricing_Date__c = null;
            salesOrder.clear();
            salesOrder.add(soClone);
        }

        return new JsonResult(salesOrder, salesOrder.size());
    }

    @RemoteAction
    public static JsonResult getCustomerDefaults(Id customerId) {

        JsonResult result = new JsonResult();
        List<Customer__c> customerList = new List<Customer__c>();

        //Fetch Bill to info and the payment terms details and set it as first item in list
        SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
                'Id','Street__c','City__c','State__c','Zip_Code__c','Country__c','Parent_Customer__r.Payment_Term__c','Parent_Customer__r.Payment_Term__r.Name', 'Price_Determination_Date__c',
                'Parent_Customer__c', 'Parent_Customer__r.Street__c','Parent_Customer__r.City__c','Parent_Customer__r.State__c','Parent_Customer__r.Zip_Code__c','Parent_Customer__r.Country__c',
                'Currency__c','Currency__r.Name', 'Top_Parent_Customer__c','Top_Parent_Customer__r.Currency__c', 'Top_Parent_Customer__r.Currency__r.Name'
        });
        soql.setWhereClause('Id = :customerId');
        List<Customer__c> cList = Database.query(soql.getQuery());

        if (cList.size() > 0){
            customerList.add(cList[0]);
        }

        //Fetch Ship to info and set it as second item in list
        soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
                'ID','name','Street__c','City__c','State__c','Zip_Code__c','Country__c'
        });
        soql.setWhereClause('Parent_customer__c = :customerId');
        List<Customer__c> sList = Database.query(soql.getQuery());

        if ( sList.size() == 1 ) {
            customerList.add(sList[0]);
        }

        //result.records[0] = bill to details
        //result.records[1] = ship to details
        result.records = customerList;
        return result;
    }

    @RemoteAction
    public static JSONResult fetchTaxes(String parentRecord, List<SOLineWrapper> soLines){
        Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(parentRecord, Sales_Order__c.class);
        JsonResult result = new JsonResult();
        if(taxation.taxServiceConfigured(salesOrder)){
            TaxService.TaxResult taxresult = taxation.getTax(salesOrder.Id);

            if(taxresult != null){
                Id soId = salesOrder.Id;
                SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'Id','Sales_Tax__c','Sales_Tax_Rate__c','Value_Added_Tax_Rate__c','VAT_Amount__c'
                });
                soql.setWhereClause('Sales_Order__c =:soId');

                 Map<Id, Sales_Order_Line__c> sols = new Map<Id, Sales_Order_Line__c>((List<Sales_Order_Line__c>)database.query(soql.getQuery()));
                for(soLineWrapper sw : soLines){
                    Sales_Order_Line__c temp = sols.get(sw.soLine.Id);

                    if(temp != null){
                        sw.soLine.Sales_Tax__c = temp.Sales_Tax__c;
                        sw.soLine.Sales_Tax_Rate__c = temp.Sales_Tax_Rate__c;
                        sw.soLine.Value_Added_Tax_Rate__c = temp.Value_Added_Tax_Rate__c;
                        sw.soLine.VAT_Amount__c = temp.VAT_Amount__c;
                    }
                }
              
                result.records = soLines;
                result.total = soLines.size();

                if(taxresult.isSuccess == false){
                    result.addmessage(taxresult.message, ApexPages.Severity.Error);
                }else{
                    result.addmessage(taxresult.message, ApexPages.Severity.Info);
                }
            }
        }else{
            result.success = false;
            result.addMessage('Tax Service not implemented', ApexPages.Severity.ERROR);
        }

        return result;
    }


    private static Map<Id, Map<Id, Decimal>> skidsToItemFacilityInvMap(List<SKID__c> skids){

        Map<Id, Map<Id, Decimal>> itemFacilityInvMap = new Map<Id, Map<Id, Decimal>>();

        for (SKID__c skid: skids) {

            Map<Id, Decimal> facilityToInvMap = new Map<Id, Decimal>();
            Decimal prevQty = 0;
            Id innerKey = skid.Location__r.Facility__c;
            Id outerKey = skid.Item__c;
            if(itemFacilityInvMap.containsKey(outerKey)){

                facilityToInvMap = itemFacilityInvMap.get(outerKey);

                if(facilityToInvMap.containsKey(innerKey)){

                    prevQty = facilityToInvMap.get(innerKey);

                }
            }

            if( skid.Type__c == 'Location' ){

                facilityToInvMap.put(innerKey, (prevQty + skid.Quantity_Stocking_UOM__c ));

            } else {

                facilityToInvMap.put(innerKey, (prevQty - skid.Quantity_Stocking_UOM__c ));
            }

            itemFacilityInvMap.put(outerKey, facilityToInvMap);
        }

        return itemFacilityInvMap;
    }

    @RemoteAction
    public static JsonResult getInventory(id itemID){

        JsonResult result = new JsonResult();

        SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
                'Id','Type__c','Quantity__c','Item__c','Location__c','Location__r.Facility__c', 'Quantity_Stocking_UOM__c', 'Facility2__r.Facility_Identifier__c', 'Shipment_Line__c'
        });
        soql.setWhereClause('Item__c = :itemID and (Type__c = \'SO Demand\' OR Type__c = \'Planned Pick\' OR Type__c = \'Allocated\' OR (Type__c = \'Location\' and Location__r.Nettable__c = true and Shipment_Line__c = null))');

        List<SKID__c> skidList = Database.query(soql.getQuery());
        system.debug('skidList.size()'+skidList.size());
        List<SKID__c> InvskidList = new List<SKID__c>();

        Map<string,double> facilitytoQty = new Map<string,double>();

        for (SKID__c s : skidList){
            system.debug('Skid--'+s);
            system.debug('facilitytoQty--'+facilitytoQty);
            if (s.Type__c != 'Location'){
                string key = String.valueof(s.Location__c) + String.valueof(s.Location__r.Facility__c);
                if (!facilitytoQty.containsKey(key)){
                    facilitytoQty.put(key, s.Quantity_Stocking_UOM__c);
                }
                else{
                    double qty = facilitytoQty.get(key);
                    qty = qty + s.Quantity_Stocking_UOM__c;
                    facilitytoQty.put(key, qty);
                }
            }
        }
        system.debug('facilitytoQty--'+facilitytoQty);
        for (SKID__c s : skidList){
            if (s.Type__c == 'Location'){
                system.debug('Location Skid--'+s);
                string key = String.valueof(s.Location__c) + String.valueof(s.Location__r.Facility__c);
                if (facilitytoQty.containsKey(key)){
                    system.debug('Location s.Quantity_Stocking_UOM__c--'+s.Quantity_Stocking_UOM__c);
                    s.Quantity_Stocking_UOM__c = s.Quantity_Stocking_UOM__c - facilitytoQty.get(key);
                    system.debug('Location s.Quantity_Stocking_UOM__c--'+s.Quantity_Stocking_UOM__c);
                }
                InvskidList.add(s);
            }
        }
        result.records = InvskidList;
        result.total = InvskidList.size();
        return result;
    }

    /*
     *  fetchAvailableInventory method fetches the available quantity for the product associated with each 
     *  sales order lines that are in 'Draft' status
     *
     *  @param  soLines     List<SOLineWrapper>
     *  @param  dateFields  List<String>
     *  @return JsonResult    
     *
     */
    @RemoteAction
    public static JsonResult fetchAvailableInventory(List<SOLineWrapper> soLinesWrappers, List<String> dateFields){
        
        JsonResult result = new JsonResult();
        Set<Id> itemsSet = new Set<Id>();
        map<String, Decimal> availableQuantity = new map<String, Decimal>();
        
        for(SOLineWrapper solw: soLinesWrappers){

            KendoUtils.UpdateDateFields(solw.soLine, dateFields);

            if( solw.soLine.Status__c == SalesOrderLineService.SO_LINE_STATUS_DRAFT ){

                itemsSet.add( solw.soLine.Product__r.Item__c );
            }
        }

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Type__c','Quantity__c','Item__c','Location__r.Facility__c', 'Quantity_Stocking_UOM__c', 'Facility2__r.Facility_Identifier__c', 'Shipment_Line__c'
		});
		soql.setWhereClause('Item__c IN :itemsSet and (Type__c = \'SO Demand\' OR Type__c = \'Planned Pick\' OR Type__c = \'Allocated\' OR (Type__c = \'Location\' and Location__r.Nettable__c = true and Shipment_Line__c = null))');

		List<SKID__c> inventorySkids = Database.query(soql.getQuery());

        if(inventorySkids.size() > 0){
            Map<Id, Map<id, Decimal>> itemToFacilityQty = skidsToItemFacilityInvMap(inventorySkids);

            for(soLineWrapper soLineWrapper: soLinesWrappers) {

                Sales_Order_Line__c sol = soLineWrapper.soLine;
                Decimal conversionFactor = KSE.getConversionFactor(sol);

                Id itemKey = sol.Product__r.Item__c;
                sol.Available_Inventory__c = 0;

                if(itemToFacilityQty.containsKey(itemKey)){

                    Map<Id, Decimal> facilityQtyMap = itemToFacilityQty.get(itemKey);
                    Id facKey = sol.Ship_From_Location__r.Facility__c;

                    if(sol.Ship_From_Location__c != null && facilityQtyMap.containsKey(facKey)){

                        sol.Available_Inventory__c = facilityQtyMap.get(facKey) / conversionFactor;

                    } else if(sol.Ship_From_Location__c == null){

                        Decimal itemTotalQty = 0;
                        for (Id facId : facilityQtyMap.keySet()) {

                            itemTotalQty = itemTotalQty + (facilityQtyMap.get(facId) / conversionFactor);
                        }

                        sol.Available_Inventory__c = itemTotalQty;
                    }
                }
            }
        }

        result.records = soLinesWrappers;
        result.total = soLinesWrappers.size();
        result.addmessage('The available inventory for all Draft Sales Order Lines are displayed under the Available Inventory column.', ApexPages.Severity.Info);

        return result;
    }

    /*
     *  getSalesOrderFromID method fetches the Sales Order details
     *
     *  @param  SOId
     *  @return Sales_Order__c
     *
     */
    public static Sales_Order__c getSalesOrderFromID (id SOId){

        Sales_Order__c so = new Sales_Order__c();
        Set<String> addlFields = new Set<String>{'Customer__r.Top_Parent_Customer__c','Customer__r.Customer_Group__c', 'Bill_to__r.Customer_Group__c', 'Ship_to__r.Customer_Group__c',
                                                    'Customer__r.Top_Parent_Customer__r.Customer_Group__c','Pricebook__c','Customer__r.Pricebook__c', 'Agreement__c', 'Total_Quantity_Ordered__c',
                                                    'Customer__r.Order_Quantity_Factor_At__c','Price_Determination_Date__c','Pricing_Date__c',
													'Ship_From_Location__c', 'Ship_From_Location__r.Facility__c', 'Ship_From_Location__r.Facility__r.Name'};

        SOQLUtil soql = new SOQLUtil('Sales_Order__c');
        soql.addFields('New_Sales_Order');
        soql.addFields('New_Sales_Order_Additional_Fields');
        soql.addFields(addlFields);
		soql.addFields(AllowanceRuleService.salesOrderFields);
        soql.setWhereClause('Id = :SOId LIMIT 1');

        so = Database.query(soql.getQuery());
        return so;

    }

    /*
     *  getSalesOrderLines method fetches the Sales Order Lines associated with the sales order along with
     *  exception, segments and other related details
     *
     *  @param  salesOrderLinesConfig
     *  @return JsonResult    
     *
     */
    @RemoteAction
    public static JsonResult getSalesOrderLines(GridRelatedListController.GridRelatedListConfig salesOrderLinesConfig, string parentRecord, List<String> allFields, String clone) {

        JsonResult result = new JsonResult();

        List<SOLineWrapper> wrapperList = new List<SOLineWrapper>();
        Map<Id, List<Task>> exceptionsMap = new Map<Id, List<Task>>();

        //Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(parentRecord, Sales_Order__c.class);
        Sales_Order__c salesOrder = getSalesOrderFromID(parentRecord);

        Id salesOrderId = salesOrder.Id;
        String sortField = String.IsNotBlank(salesOrderLinesConfig.sortField) ? salesOrderLinesConfig.sortField : 'CreatedDate';
        String sortOrder = String.IsNotBlank(salesOrderLinesConfig.sortOrder) ? salesOrderLinesConfig.sortOrder : 'Desc';

        set<string> addlFields = (String.isNotBlank(salesOrderLinesConfig.additionalFields)) ? new set<string>(salesOrderLinesConfig.additionalFields.split(',')) : null;
		
		String whereClause =  ' ' + salesOrderLinesConfig.parentField + ' = :salesOrderId order by ' + sortField + ' ' + sortOrder;
        
        SOQLUtil soql = new SOQLUtil(salesOrderLinesConfig.objectName);
        soql.addFields(new Set<String>(allFields));
        soql.addFields(addlFields);
        soql.addFields(new Set<String>{'Agreement_Line__c'});
        soql.setWhereClause(whereClause);

        List<Sales_Order_Line__c> soLineList = database.query(soql.getQuery());

        if ( clone != null && clone == '1'){
            List<Sales_Order_Line__c> soLinesCloned = new List<Sales_Order_Line__c>();
            for (Sales_Order_Line__c sol : soLineList){
                Sales_Order_Line__c solClone = new Sales_Order_Line__c();
                solClone = sol.clone(false,true);
                solClone.Status__c = 'Draft';
                solClone.Pricebook__c = null;
                solClone.Pricebook__r = null;
				solClone.Pricebook_line__c = null;
				solClone.Pricebook_line__r = null;
                solClone.Unit_Price__c = null;
                solClone.List_Price__c = null;
                solClone.Allowances__c = null;
                solClone.Required_Date__c = null;
                solClone.Quantity_Change_Reason__c = null;
                solClone.Quantity_Shipped__c = 0;
                solClone.Ordered_Date_Time__c = system.now();

                Sales_Order__c soClone = new Sales_Order__c();
                soClone = salesOrder.clone(false, true);
                soClone.Status__c = 'Draft';
                soClone.Required_Date__c = null;
                soClone.Date_Time_Ordered__c = system.now();
                soClone.Pricing_Date__c = null;
                solClone.Sales_Order__r = soClone;

                if(sol.Accounting_Segment__c != null ){
                    Accounting_Default__c accountingDefault = new Accounting_Default__c();
                    solClone.Accounting_Segment__c = null;
                    if (sol.Accounting_Segment__r != null){
                        accountingDefault = sol.Accounting_Segment__r.clone(false,true);
                        solClone.Accounting_Segment__r = accountingDefault;
                    }
                }
                soLinesCloned.add(solClone);
            }
            soLineList.clear();
            soLineList.addAll(soLinesCloned);

            Map<String,Pricebook_Line__c> priceBookLineMap = PricingService.fetchSOLinesPriceBookInfo(soLineList);
            system.debug(logginglevel.error, 'soLineList--'+soLineList);
            system.debug(logginglevel.error, 'priceBookLineMap--'+priceBookLineMap);
            for (Sales_Order_Line__c soLine : soLineList) {
                Pricebook_Line__c priceBookLine = priceBookLineMap.containsKey('newso' + '-' + soLine.Line__c) ? priceBookLineMap.get('newso' + '-' + soLine.Line__c) : new Pricebook_Line__c();

                //Update Price
                if (priceBookLine != new Pricebook_Line__c()) {

                    if (soLine.Pricebook__c == priceBookLine.Pricebook__c || soLine.Pricebook__c == null) {
                        soLine.Unit_Price__c = priceBookLine.price__c;
                        soLine.Pricebook__c = priceBookLine.Pricebook__c;
                        soLine.Pricebook__r = priceBookLine.Pricebook__r;
						soLine.Pricebook_line__c = priceBookLine.Id;
						soLine.Pricebook_Line__r = pricebookLine;
                    } else {
                        soLine.Unit_Price__c = null; // PBL not found for SOL and PB combo
                    }
                }
            }

            //These are new lines, so no need to check for exceptions, the exception map will be empty
            for (Integer i = 0; i< soLineList.size() ; i++){
                SOLineWrapper soLineWrapper = new SOLineWrapper(soLineList[i]);

                if (soLineWrapper.soLine.Accounting_Segment__r != null){
                    soLineWrapper.segments = soLineWrapper.soLine.Accounting_Segment__r;
                }

                //Update Quantity factor field
                if(!String.isBlank(salesOrder.Customer__r.Order_Quantity_Factor_At__c)){
                    soLineWrapper.updateQuantityFactor(salesOrder.Customer__r.Order_Quantity_Factor_At__c);
                }
                wrapperList.add(soLineWrapper);
            }

            result.records = wrapperList;
            result.total = wrapperList.size();
            return result;
        }

        Set<Id> soLineIds = (new Map<Id, Sales_Order_Line__c>(soLineList)).keySet();

        //Fetch exceptions associated with each Sales Order Line
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		soql = new SOQLUtil('Task', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','subject','WhatId'
		});
		soql.setWhereClause('WhatId in :soLineIds and type = \'Exception\' and status = \'Open\'');

		List<Task> tasks = Database.query(soql.getQuery());

        if(tasks.size() > 0){
            for(Task task: tasks){
                if(exceptionsMap.containsKey(task.WhatId)){
                    exceptionsMap.get(task.WhatId).add(task);
                } else{
                    List<Task> tempTask = new List<Task>();
                    tempTask.add(task);
                    exceptionsMap.put(task.WhatId, tempTask);
                }
            }
        }

        for (Integer i = 0; i< soLineList.size() ; i++) {
            SOLineWrapper soLineWrapper = new SOLineWrapper(soLineList[i], exceptionsMap.get(soLineList[i].Id));
            //Update Quantity factor field
            if(!String.isBlank(salesOrder.Customer__r.Order_Quantity_Factor_At__c)){
                soLineWrapper.updateQuantityFactor(salesOrder.Customer__r.Order_Quantity_Factor_At__c);
            }
            wrapperList.add(soLineWrapper);
        }
        
        result.records = wrapperList;
        result.total = wrapperList.size();
        
        return result;
    }
    
    /*
     *  getSalesOrderLineDetailsFromUPC method is called when the user enters a UPC code on the Sales Order Line
     *  manage page and tabs out. 
     *
     *  @param  upcCode 
     *  @param  soLinePricebookId 
     *  @param  salesOrderRecord 
     *  @return JsonResult    
     *
     */
    @RemoteAction
    public static JsonResult getSalesOrderLineDetailsFromUPC(   String upcCode, 
                                                                Sales_Order_Line__c soLine, 
                                                                List<String> dateFields,
                                                                String salesOrderRecord, String fc ){

        JsonResult result = new JsonResult();
        Sales_Order__c salesOrder = getSalesOrderFromID(salesOrderRecord);//(Sales_Order__c)JSON.deserialize(salesOrderRecord, Sales_Order__c.class);

        List<Product__c> ProdList = new List<Product__c>();
        
        KendoUtils.UpdateDateFields(soLine, dateFields);

        if(upcCode!=null){
            
            try{
                
                List<SOLineWrapper> soLineWrappers = new List<SOLineWrapper>();
                
                Sales_Order_Line__c salesOrderLine = getSalesOrderLineDetails( 'upc_code',
                                                                                upcCode, 
                                                                                soLine,
                                                                                salesOrder, fc);   

                SOLineWrapper soLineWrapper = new SOLineWrapper(salesOrderLine);
    
                if(!String.isBlank(salesOrder.Customer__r.Order_Quantity_Factor_At__c)){

                    soLineWrapper.updateQuantityFactor(salesOrder.Customer__r.Order_Quantity_Factor_At__c);
                }

                soLineWrappers.add(soLineWrapper);

                result.records = soLineWrappers;
                result.total = soLineWrappers.size();

            } catch (Exception e){
                
                result.success = false;
                result.addMessage('An Error occured : ' + e.getMessage(), ApexPages.Severity.ERROR);
            }
                    
        }

        return result;
       
     }
     /*
     *  getSalesOrderLineDetailsFromCustomerProduct method is called when the user enters a  Customer product on the Sales Order Line
     *  manage page and tabs out, it populated the related Kenandy Product 
     *
     *  @param  CustomerproductName 
     *  @param  soLine 
     *  @param  salesOrderRecord
     *  @return JsonResult    
     *
     */
    @RemoteAction 
    public static JsonResult getSalesOrderLineDetailsFromProductCrossRef( String productReferenceId, 
                                                                  Sales_Order_Line__c soLine, 
                                                                  List<String> dateFields,
                                                                  String salesOrderRecord, String fc ){  
        JsonResult result = new JsonResult();
        Sales_Order__c salesOrder = getSalesOrderFromID(salesOrderRecord);//(Sales_Order__c)JSON.deserialize(salesOrderRecord, Sales_Order__c.class);
        KendoUtils.UpdateDateFields(soLine, dateFields);
        Set<String> crossRefQueryFields = new Set<String>{ 'Id', 'Name', 'Product__c', 'Product__r.Id', 'Product__r.name', 'Customer__c', 'Active__c', 'Customer__r.Name ' };
        String crossRefqueryWhereClause = ('Id = \'' + productReferenceId + '\' AND Active__c = true AND Cross_Reference_Type__c = \'Customer\' AND Reference_Object__c = \'Product\'');

        SOQLUtil soql = new SOQLUtil('Cross_Reference__c');
        soql.addFields(crossRefQueryFields);
        soql.setWhereClause(crossRefqueryWhereClause);

        List<Cross_Reference__c> crossRefList = Database.query(soql.getQuery());

        try {
            List<SOLineWrapper> soLineWrappers = new List<SOLineWrapper>();

            Sales_Order_Line__c salesOrderLine = getSalesOrderLineDetails( 'product', crossRefList[0].Product__c, soLine, salesOrder, fc);   
            soLineWrapper soLineWrapper = new SOLineWrapper(salesOrderLine);
            soLineWrappers.add(soLineWrapper);
            result.records = soLineWrappers;
            result.total = soLineWrappers.size();
        }
        catch (Exception e) {
            result.success = false;
            result.addMessage('An Error occured :' + e.getMessage(), ApexPages.Severity.ERROR);
        }    
        return result;
    }

   /*
     *  getSalesOrderLineDetailsFromProduct method is called when the user enters a product on the Sales Order Line
     *  manage page and tabs out. 
     *
     *  @param  productName 
     *  @param  soLinePricebookId 
     *  @param  salesOrderRecord
     *  @return JsonResult    
     *
     */
    @RemoteAction 
    public static JsonResult getSalesOrderLineDetailsFromProduct( String productId, 
                                                                  Sales_Order_Line__c soLine, 
                                                                  List<String> dateFields,
                                                                  String salesOrderRecord, String fc ){  
        JsonResult result = new JsonResult();
        Sales_Order__c salesOrder = getSalesOrderFromID(salesOrderRecord);//(Sales_Order__c)JSON.deserialize(salesOrderRecord, Sales_Order__c.class);
        
        KendoUtils.UpdateDateFields(soLine, dateFields);
        
        try {

            List<SOLineWrapper> soLineWrappers = new List<SOLineWrapper>();

            Sales_Order_Line__c salesOrderLine = getSalesOrderLineDetails( 'product',
                                                                            productId, 
                                                                            soLine,
                                                                            salesOrder, fc);  


            SOLineWrapper soLineWrapper = new SOLineWrapper(salesOrderLine);

            if(!String.isBlank(salesOrder.Customer__r.Order_Quantity_Factor_At__c)){

                soLineWrapper.updateQuantityFactor(salesOrder.Customer__r.Order_Quantity_Factor_At__c);
            }

            soLineWrappers.add(soLineWrapper);
            
            result.records = soLineWrappers;
            result.total = soLineWrappers.size();
        }
        catch (Exception e) {

            result.success = false;
			System.debug( logginglevel.error, '~*~' + e.getStackTraceString() + ' ' + e.getMessage() );
            result.addMessage('An Error occured : ' + e.getMessage(), ApexPages.Severity.ERROR);
        }
        
        return result;
    }
    
    /*
     *  getSalesOrderLineDetails method returns the product details including the price information
     *  if available
     *
     *  @param  productMatchingVariable 
     *  @param  productMatchingValue 
     *  @param  soLinePricebookId
     *  @param  salesOrder
     *  @return Sales_Order_Line__c    
     *
     */
    public  static Sales_Order_Line__c getSalesOrderLineDetails(String productMatchingVariable,
                                                                String productMatchingValue, 
                                                                Sales_Order_Line__c sol,
                                                                Sales_Order__c salesOrder, string fc) {  

        Sales_Order_Line__c soLine = new Sales_Order_Line__c();

        String pricingDate;

        if (salesOrder.Price_Determination_Date__c == SalesOrderService.PRICE_DET_ORDER && sol.Ordered_Date_Time__c != null){
            pricingDate = String.valueOf(sol.Ordered_Date_Time__c.date());
        } else {
            pricingDate = salesOrder.Pricing_Date__c != null ? String.valueOf(salesOrder.Pricing_Date__c) : String.valueOf(system.today());
        }
        
        soLine.Ordered_Date_Time__c = sol.Ordered_Date_Time__c;
		soLine.Line__c = sol.Line__c;
		soLine.Related_Sales_Order_Line__c = sol.Related_Sales_Order_Line__c;


        //Fetch Product information
        Set<String> productQueryFields = new Set<String>{'Id', 
                                                         'Name',
                                                         'Description__c',
                                                         'Item__c', 
                                                         'Item__r.Name',
                                                         'Item__r.Fulfillment_Source__c',
                                                         'Item_Specification__c',
                                                         'Item_Specification__r.Name',
														'Item_Specification__r.Facility__c',
														'Item_Specification__r.Facility__r.Name',
                                                         'Pricebook_Line_Required__c',
                                                         'Product_Group__c',
                                                         'Selling_UOM__r.Name', 
                                                         'Units_per_Layer__c',
                                                         'Units_per_Pallet__c',
                                                         'UPC_Code__c',
                                                         'Invoiceable__c',
                                                         'Item__r.Source__c'};
		productQueryFields.addAll(AllowanceRuleService.productFields);

        String productQueryWhereClause = ''; 

        if(productMatchingVariable == 'product'){

            productQueryWhereClause = ' id = \''+ String.escapeSingleQuotes(productMatchingValue) +'\' Limit 1 ';

        } else if (productMatchingVariable == 'upc_code'){

            productQueryWhereClause = ' UPC_Code__c = \'' + productMatchingValue + '\' and Primary__c = true limit 1 ';
        }
        
        SOQLUtil soql = new SOQLUtil('Product__c');
        soql.addFields(productQueryFields);
        soql.setWhereClause(productQueryWhereClause);
        
                      
        Product__c[] products = Database.query( soql.getQuery() ); 
                      
        if (products == null || products.isEmpty()) {
            // Return empty Sales Order Line object
            return soLine;
        }

        Product__c product = products[0]; 

        sol.product__c = product.id;
        sol.product__r = product;

        if(sol.Id == null){
            sol.Sales_Order__c = salesOrder.Id;
        }

        sol.Sales_Order__r = salesOrder;
        Boolean fieldChange;

       fieldChange = (fc == 'soLine.Product__c') || (fc == 'soLine.Product_Reference__c') ? true : false;
       Cross_Reference__c crossRef = new Cross_Reference__c();

       if(fieldChange){
           crossRef =  fetchCrossReferenceDetails(product, salesOrder); 
       }

		Set<String> nonStdSoTypes = new Set<String>();
		nonStdSoTypes.addAll(SalesOrderService.SO_RMA_REPLACEMENT_TYPES);
		nonStdSoTypes.addAll(SalesOrderService.SO_ADJUSTMENT_TYPES);
		nonStdSoTypes.addAll(SalesOrderService.SO_RMA_TYPES);

		Boolean blockRepriceForAdjustment =  sol.Related_Sales_Order_Line__c == null || !nonStdSoTypes.contains(salesOrder.Type__c);

        if (sol.Agreement_Line__c == null && blockRepriceForAdjustment){ //  ){
            Pricebook_Line__c priceBookLine;
            Map<String,Pricebook_Line__c> priceBookLineMap = PricingService.fetchSOLinesPriceBookInfo(new List<Sales_Order_Line__c>{sol});
            priceBookLine = priceBookLineMap.containsKey(salesOrder.id + '-' + sol.Line__c) ? priceBookLineMap.get(salesOrder.id + '-' + sol.Line__c) : new Pricebook_Line__c();

            //Update Price
            if (priceBookLine != new Pricebook_Line__c()) {

                if (sol.Pricebook__c == priceBookLine.Pricebook__c || sol.Pricebook__c == null){
					System.debug( logginglevel.error, '~*~  (SOMLE) PBL found');
					soLine.List_Price__c = priceBookLine.price__c;
					soLine.Unit_Price__c = priceBookLine.price__c;
                    soLine.Pricebook__c = priceBookLine.Pricebook__c;
                    soLine.Pricebook__r = priceBookLine.Pricebook__r;
					soLine.Pricebook_Line__c = pricebookLine.Id;
					soLine.Pricebook_Line__r = priceBookLine;
					System.debug( logginglevel.error, '~*~ priceBookLine :' + priceBookLine );
                } else {
					System.debug( logginglevel.error, '~*~ (SOMLE) PBL not found');
                    soLine.Pricebook__c = sol.Pricebook__c;
                    soLine.Pricebook__r = sol.Pricebook__r;
					soLine.Pricebook_Line__c = sol.Pricebook_line__c;
					soLine.Pricebook_Line__r = sol.Pricebook_line__r;
					System.debug( logginglevel.error, '~*~ soLine.Pricebook_Line__r :' + soLine.Pricebook_Line__r );
                    soLine.Unit_Price__c = null; // PBL not found for SOL and PB combo
					soLine.List_Price__c = null;
				}
            }
        } else {
			System.debug( logginglevel.error, '~*~ (SOMLE) maintain original price');
            // maintaing original Unit Price is agreement line is present
            soLine.Pricebook__c = sol.Pricebook__c;
            soLine.Pricebook__r = sol.Pricebook__r;
			soLine.Pricebook_Line__c = sol.Pricebook_line__c;
			soLine.Pricebook_Line__r = sol.Pricebook_line__r;
			System.debug( logginglevel.error, '~*~ soLine.Pricebook_Line__r :' + soLine.Pricebook_Line__r );
            soLine.Unit_Price__c = sol.Unit_Price__c;
			soLine.List_Price__c = sol.List_Price__c;
		}

        soLine.Selling_UOM__c = product.Selling_UOM__c;
        soLine.Selling_UOM__r = product.Selling_UOM__r;
        soLine.Description__c = product.Description__c;
        soLine.Product__c = product.Id;
        soLine.Product__r = product;
        soLine.UPC_Code__c = product.UPC_Code__c;

        if(fieldChange){   
            soLine.Product_Reference__c = crossRef.Id;
            soLine.Product_Reference__r = crossRef;
        }
     
        soLine.Fulfillment_Source__c = (product.Item__r.Fulfillment_Source__c) == null ? KSE.getDefaultPickListValue('Sales_Order_Line__c', 'Fulfillment_Source__c') : product.Item__r.Fulfillment_Source__c;

		Set<String> fields = new Set<String>{'Unit_Price__c', 'List_Price__c', 'New_Pricing_Rule__c'};
		for (String field : fields) {
			System.debug( logginglevel.error, '~*~ (SOMLE) soLine.' + field + ': ' + soLine.get(field) );
			System.debug( logginglevel.error, '~*~ (SOMLE) sol.' + field + ': ' + sol.get(field) );
			System.debug( logginglevel.error, '~*~ \n :' );
		}
			/* KNDY-17915 */
		AllowanceService.previewNewPrice(salesOrder, new List<Sales_Order_Line__c>{soLine});

		System.debug( logginglevel.error, '~*~ soLine :' + soLine );
        return soLine;
    }

    public static Cross_Reference__c fetchCrossReferenceDetails( Product__c product,  Sales_Order__c salesOrder){
        Cross_Reference__c crossRef = new Cross_Reference__c();

        Set<String> crossRefQueryFields = new Set<String>{ 'Id', 'Name', 'Product__c', 'Product__r.name', 'Customer__c', 'Active__c', 'Customer__r.Name ' };
        String crossRefqueryWhereClause = ('product__c = \'' +  product.id  + '\' AND Active__c = true AND Cross_Reference_Type__c = \'Customer\' AND Reference_Object__c = \'Product\'');
        String crossRefqueryOrderByClause = 'Name';

        SOQLUtil soql = new SOQLUtil('Cross_Reference__c');
        soql.addFields(crossRefQueryFields);
        soql.setWhereClause(crossRefqueryWhereClause);
        soql.setOrderByClause(crossRefqueryOrderByClause);
        List<Cross_Reference__c> crossRefList = Database.query(soql.getQuery());
        
        for(Cross_Reference__c cr : crossRefList){
            if(cr.Customer__r.Id == salesOrder.Customer__r.Top_Parent_Customer__c){
                crossRef = cr;
                break;
            }else if(cr.Customer__r.Id == null) {
                crossRef = cr;
                break;    
            } 
            
        }
        return crossRef;
  
        
    }

    /*
     *  addRowErrors method constructs the error message to a list and associate with the appropriate row 
     *  to validate all the SO lines before doing a DML operation like Save, cancel, delete
     *
     *  @param  rowErrors   (Map<String, List<String>>)     Map of a List of errors associated to a row to be updated
     *  @param  rowGUID     (String)                        Unique row ID of the kendo screen
     *  @return rowErrors   (Map<String, List<String>>)     Errors associated with each rows  
     *
     */
    private static Map<String, List<String>> addRowErrors(Map<String, List<String>> rowErrors, String rowGUID, String errorMessage){

        if(rowErrors.containsKey(rowGUID)){

            rowErrors.get(rowGUID).add(errorMessage);
        } else {
            List<String> errorMessages = new List<String>();
            errorMessages.add(errorMessage);
            rowErrors.put(rowGUID, errorMessages);

        }

        return rowErrors;
    }

    /*
     *  preValidateSO method is called before the SO lines to identify if the SO Lines are allowed to be 
     *  modified based on the Sales Order data
     *
     *  @param  salesOrder              (Sales_Order__c) Sales Order to be managed by the Add manage page
     *  @return preValidationSOError    (String)         Prevalidation error for the SO if any  
     *
     */
    private static String preValidateSO(Sales_Order__c salesOrder){

        String preValidationSOError = null;

        if(salesOrder != null){

            if(salesOrder.Status__c == SalesOrderService.SO_STATUS_CANCEL || salesOrder.Status__c == SalesOrderService.SO_STATUS_CLOSED){
                preValidationSOError = SalesOrderManageLinesExt.KNDO_PAGE_HEADER_SO_STATUS_WARNING_MSG;
            }
        }

        return preValidationSOError;
    }


    /*
     * getFieldLabel method is called to get the Field label
     *
     *  @param objectName   String    Name of the object
     *  @param fieldName    String    API name of the field
     *  @return fieldLabel
     */
    private static String getFieldLabel(String objectName, String fieldAPIName){

        String fieldLabel = null;

        // this can accept list of strings, we describe only one object here
        List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(new List<String>{objectName}); 

        String objectLabel = describeSobjectsResult[0].getLabel();

		//KNDY-7410
		//Map<String, Schema.SObjectField> allFields = describeSobjectsResult[0].fields.getMap();
		util = SchemaUtil.getInstance();
		Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(describeSobjectsResult[0].fields.getMap());              

        fieldLabel = fieldsMap.get(fieldAPIName).getDescribe().getLabel();

        return fieldLabel;

     }

    /*
     *  preValidateSoLines method is called before any DML operation of the So lines to 
     *  to validate all the SO lines before doing a DML operation like Save, cancel, delete
     *
     *  @param  soLineWrapper              row to be updated
     *  @param  action                      Specify action inorder to do validations based on specific operations (Eg. Update, Insert)
     *  @param  existingLineErrors          Any existing line errors
     *  @return Map<String, List<String>>   Errors associated with each rows after prevalidation  
     *
     */
    private static Map<String, List<String>> preValidateSoLines(SOLineWrapper soLineWrapper, String action, Map<String, List<String>> existingLineErrors){
        Map<String, List<String>> preValidationErrors = new Map<String, List<String>>();

        if(existingLineErrors != null){
            preValidationErrors.putAll(existingLineErrors);
        }

		if (action == 'Close'){
			if (soLineWrapper.soLine.Quantity_Backordered__c == 0 && soLineWrapper.soLine.Status__c != 'Open'){
				preValidationErrors.putAll(addRowErrors(preValidationErrors, soLineWrapper.rowGuid, SalesOrderCloseExt.Quantity_Shipped_Error));
			}


			if(soLineWrapper.soLine.Quantity_Allocated__c > 0.0){
				preValidationErrors.putAll(addRowErrors(preValidationErrors, soLineWrapper.rowGuid, Label.Cannot_close_sales_order_line_with_quantity_allocated));
			}
		}

		if (action == 'Cancel'){

		}

        if(action == 'Insert' || action == 'Update'){

            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(soManageLinesPageVariables.get('ObjectName'),soManageLinesPageVariables.get('GridDefaultViewFieldSet'));

            for(FieldInfo fieldInfo : fieldInfoList){

                if(fieldInfo.required == true){

                    if(soLineWrapper.soLine.get(fieldInfo.field) == null){

                        preValidationErrors.putAll(addRowErrors(preValidationErrors, soLineWrapper.rowGuid, KNDO_REQUIRED_FIELD_LINE_ERROR + getFieldLabel(soManageLinesPageVariables.get('ObjectName'), fieldInfo.field)));
                    }
                }
            }

			// if facility is null, badly created model data sent to controller
			if (soLineWrapper.soLine.Item_Specification__c != null
					&& soLineWrapper.soLine.Ship_From_Location__c != null
					&& soLineWrapper.soLine.Item_Specification__r.Facility__c != null
					&& soLineWrapper.soLine.Ship_From_Location__r.Facility__c != null // in the event that facility isn't captured through an edge case
					&& soLineWrapper.soLine.Item_Specification__r.Facility__c != soLineWrapper.soLine.Ship_From_Location__r.Facility__c){

				preValidationErrors.putAll(addRowErrors(preValidationErrors, soLineWrapper.rowGuid, KNDO_SOL_ITEM_SPEC_AND_SHIP_FROM_LOCATION_MISMATCH));
			}

            if(soLineWrapper.soLine.Product__r.Item__r.Source__c  != null && 
               soLineWrapper.soLine.Product__r.Item__r.Source__c == ItemService.ITEM_SOURCE_KIT && 
               soLineWrapper.soLine.Fulfillment_Source__c != SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY){

                preValidationErrors.putAll(addRowErrors(preValidationErrors, soLineWrapper.rowGuid, KNDO_SO_PRODUCT_ITEM_KIT_NON_INVENTORY_FULFILLMENT_SOURCE_ERROR));
            }
            if(soLineWrapper.soLine.Product_Reference__c != null && soLineWrapper.soLine.Product_Reference__r.Active__c == false ){
                preValidationErrors.putAll(addRowErrors(preValidationErrors, soLineWrapper.rowGuid, KNDO_INVALID_PRODUCT_REFERENCE));     
            }

        } else if (action == 'Delete'){

            if(soLineWrapper.soLine.Status__c != SalesOrderLineService.SO_LINE_STATUS_DRAFT){

                preValidationErrors.putAll(addRowErrors(preValidationErrors, soLineWrapper.rowGuid, KNDO_DELETE_SO_LINE_STATUS_ERROR));
            }

			if (soLineWrapper.soLine.Quantity_Shipped__c > 0){
				preValidationErrors.putAll(addRowErrors(preValidationErrors, soLineWrapper.rowGuid, KNDO_DELETE_SO_LINE_SHIPPED_ERROR));
			}
        }

        //Delete is handled seperately
        if(action != 'Delete'){
            //Prevent the user from updating any closed or cancelled SO Lines
            if(soLineWrapper.soLine.Status__c == SalesOrderLineService.SO_LINE_STATUS_CANCELLED || soLineWrapper.soLine.Status__c == SalesOrderLineService.SO_LINE_STATUS_CLOSED){

                preValidationErrors.putAll(addRowErrors(preValidationErrors, soLineWrapper.rowGuid, KNDO_CANCELED_CLOSED_LINE_ERROR));

            }
        }

        return preValidationErrors;
    }

    /*
     *  getRowErrorWrapperList method is called to get the list of row errors in the form of SOLineErrorWrapper object
     *
     *  @param rowErrors Map<String, List<String>> List of errors for each row where the key is the rowGUID
     *  @return List<SOLineErrorWrapper>
     */
     private static List<SOLineErrorWrapper> convertRowErrorsToWrapperList(Map<String, List<String>> rowErrors){

        List<SOLineErrorWrapper> rowErrorWrapperList = new List<SOLineErrorWrapper>();
        
        if(rowErrors.size() > 0){

            for (String rGUID : rowErrors.keySet()){

                rowErrorWrapperList.add(new SOLineErrorWrapper(rGUID, rowErrors.get(rGUID)));

            }

        }

        return rowErrorWrapperList;
     }

    /*
     *  updateJSONResult method is called once the DML operation is completed to update the JSONResult object
     *  
     *  @param jsonResult               JSONResult object
     *  @param rowErrors                Map<String, List<String>> List of errors for each row
     *  @param hasException             Boolean
     *  @param sp                       Savepoint Database save point
     *  @return JSONResult
     *
     */
    private static JSONResult updateJSONResult(JSONResult jsonResult, 
                                               Map<String, List<String>> rowErrors, 
                                               Integer rowsSucceeded,
                                               Boolean hasException){

        List<SOLineErrorWrapper> rowErrorList = new List<SOLineErrorWrapper>();

        if(rowErrors.size() > 0){

            rowErrorList = convertRowErrorsToWrapperList(rowErrors);
        }
        //Show user friendly errors on screen
        if(rowErrors.size() == 0 && !hasException){
            jsonResult.success = true;
            jsonResult.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
            jsonResult.total = rowsSucceeded;

        } else if(rowErrorList.size() > 0 && !hasException){

            jsonResult.success = false;
            jsonResult.records = rowErrorList;
            jsonResult.addMessage(KNDO_PAGE_HEADER_ERROR_MSG, ApexPages.Severity.ERROR); 

        } else if(hasException){

            jsonResult.success = false;

            if(rowErrorList.size() > 0){
                jsonResult.records = rowErrorList;
            }

            jsonResult.addMessage(KNDO_PAGE_HEADER_GENERAL_EXCEPTION_MSG, ApexPages.Severity.ERROR);
        }

        return jsonResult;
    }

    /**
     *  updateSOLineDefaults method is used to update any default value to be assigned before 
     *  saving the sales order lines(Both update and creating new line)
     *
     *  @param      SOLineWrapper       Sales Order Line wrapper object
     *  @param      Sales_Order__c      Sales Order details
     *  @param      List<String>        List of Date fields
     *  @param      Boolean             Indicates if the line is a new line or existing line to be updated
     *  @return     List<SOLineWrapper>
     *
     */
    public static SOLineWrapper updateSOLineDefaults(SOLineWrapper soLineWrapper, 
                                                     Sales_Order__c salesOrder, 
                                                     List<String> dateFields,
                                                     Boolean newLine){
                
        //Convert the kendo date format to Salesforce format
        KendoUtils.UpdateDateFields(soLineWrapper.soLine, dateFields);
        //Set Available inventory to null always before saving
        soLineWrapper.soLine.Available_Inventory__c = null;

        if(newLine){
            //Default the Sales Order Id and company for every new line from Sales Order
            soLineWrapper.soLine.Sales_Order__c = salesOrder.Id;
            soLineWrapper.soLine.Company__c = salesOrder.Company__c;
            //row.soLine.Ship_From_Location__c = salesOrder.Ship_From_Location__c;
            soLineWrapper.soLine.Required_Date__c = (Date)soLineWrapper.soLine.Required_Date__c != null ? (Date)soLineWrapper.soLine.Required_Date__c : (Date)salesOrder.Required_Date__c;
            //OTC-739 Default SOL Line Type as Replacement for Replacement SOs
            soLineWrapper.soLine.Line_Type__c = salesOrder.Type__c == 'Replacement' ? 'Replacement' : soLineWrapper.soLine.Line_Type__c;
	    soLineWrapper.soLine.Quantity_Shipped__c = 0; //KNDY-19526 - For new lines, set the qty shipped to 0
        } 
        
        if(salesOrder.Weight_UOM__c != null){

            //Assign Weight_UOM__c from Sales Order to the SO line
            soLineWrapper.soLine.Weight_UOM__c = salesOrder.Weight_UOM__c;
        } 
        
        //Default the Item Specification from product if the Sales Order type is not Repair
        if(salesOrder.Type__c != SalesOrderService.SO_TYPE_REPAIR && soLineWrapper.soLine.Item_Specification__c == null && soLineWrapper.soLine.Product__r.Item_Specification__c != null){

            soLineWrapper.soLine.Item_Specification__c = soLineWrapper.soLine.Product__r.Item_Specification__c;
        }

        if(soLineWrapper.soLine.Fulfillment_Source__c == null){

            if(soLineWrapper.soLine.Product__r.Item__r.Fulfillment_Source__c == null){

                soLineWrapper.soLine.Fulfillment_Source__c =  KSE.getDefaultPickListValue('Sales_Order_Line__c', 'Fulfillment_Source__c');
            } else {

                soLineWrapper.soLine.Fulfillment_Source__c = soLineWrapper.soLine.Product__r.Item__r.Fulfillment_Source__c;
            }
        }

        return soLineWrapper;
    }

    @RemoteAction
    public static JsonResult cancelsalesorder (id salesOrderId) {

        JsonResult result = new JsonResult();
        Sales_Order__c so = new Sales_Order__c();

        SOQLUtil soql = new SOQLUtil('Sales_Order__c');
        soql.addFields('New_Sales_Order');
        soql.setWhereClause('Id = :salesOrderId');

        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Sales_Order_Lines__r');
        childRel.addFields(new Set<String>{'id', 'Name', 'Status__c'});
        soql.addChildRelationship(childRel);

        so = database.query(soql.getQuery());

        if (so.Status__c != 'Draft'){
            result.success = false;
            result.addMessage(Label.Sales_Order_Cancel,ApexPages.Severity.ERROR);
            return result;
        }

        Savepoint sp = Database.setSavepoint();

        try{
            so.Status__c = 'Cancelled';
            DML.checkUpdate(so);
            update so;
        }catch(DmlException de){
            System.debug(loggingLevel.Error, 'KNDY exception : ' + de.getMessage());
            result.success = false;
            result.addMessage(de.getMessage() , ApexPages.Severity.ERROR);
            Database.rollback(sp);
        }

        return result;
    }

    /**
     *  saveHeader method is called from Sales Order Add manage screen when the create button is clicked the first time
     *  create new lines
     *
     *  @param  sOrder              Sales Order Header
     *  @param  headerDateFields    List of datefields in the header fieldset that needs to be converted to Salesforce date format
     *  @return JsonResult
     *
     */
    @RemoteAction
    public static JsonResult saveHeader(Sales_Order__c sOrder, List<String> headerDateFields) {

        JsonResult result = new JsonResult();

        KendoUtils.UpdateDateFields(sOrder, headerDateFields);

        Savepoint sp = Database.setSavepoint();

        Sales_Order__c so = new Sales_Order__c();

        try {
            DML.checkUpsertAsUser(sOrder); upsert sOrder;

            Id soID = sOrder.id;
            SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{

                    'Id', 'Company__c', 'Customer__c', 'Customer__r.Top_Parent_Customer__c', 'Customer__r.Top_Parent_Customer__r.Id', 'Customer__r.Pricebook__c',
                    'Customer__r.Order_Quantity_Factor_At__c', 'Customer__r.Customer_Group__c', 'Date_Time_Ordered__c', 'Dimension_UOM__c',
                    'Dimension_UOM__r.Name', 'Name', 'Pricebook__c', 'Pricebook__r.Name', 'Pricing_Date__c', 'Price_Determination_Date__c', 'Required_Date__c',
                    'Status__c', 'Subtotal__c', 'Ship_From_Location__r.Facility__c', 'Ship_From_Location__r.Facility__r.Name', 'Ship_From_Location__c', 'Ship_From_Location__r.Id', 'Ship_From_Location__r.Name', 'Ship_to__c', 'Type__c', 'Currency__c',
                    'Weight_UOM__c', 'Weight_UOM__r.Name','Company__r.Use_Warranty_Repairs__c'
            });
			soql.addFields(AllowanceRuleService.salesOrderFields);
            soql.setWhereClause('Id = :soID');

            so = Database.query(soql.getQuery());

        }catch(DmlException de){
            System.debug(loggingLevel.Error, 'KNDY exception : ' + de.getMessage());
            result.success = false;
            result.additionalInfo = 'header';
            result.addMessage(de.getMessage() , ApexPages.Severity.ERROR);
            Database.rollback(sp);
        }

        if (result.success){
            result.records = new List<Sales_Order__c>{so};
        }

        return result;
    }

    /**
     *  saveSalesOrderLines method is called from Sales Order Add manage screen and will be used to save changes and/or 
     *  create new lines
     *
     *  @param  sOrder              Sales Order Header
     *  @param  headerDateFields    List of datefields in the header fieldset that needs to be converted to Salesforce date format
     *  @param  updatedList         List of selected rows to be updated
     *  @param  newList             List of rows to be created
     *  @param  dateFields          List of datefields in the fieldset that needs to be converted to Salesforce date format
     *  @param  parentRecord        SalesOrder Id
     *  @return JsonResult
     *
     */
    @RemoteAction
    public static JsonResult saveSalesOrderLines(Sales_Order__c sOrder, List<String> headerDateFields, List<SOLineWrapper> updatedList, List<SOLineWrapper> newList, List<String> dateFields, String parentRecord) {

        JsonResult result = new JsonResult();

        KendoUtils.UpdateDateFields(sOrder, headerDateFields);

        Savepoint sp = Database.setSavepoint();

        try {
            DML.checkUpsertAsUser(sOrder); upsert sOrder;
        }catch(DmlException de){
            System.debug(loggingLevel.Error, 'KNDY exception : ' + de.getMessage());
            result.success = false;
            result.additionalInfo = 'header';
            result.addMessage(de.getMessage() , ApexPages.Severity.ERROR);
        }

        if(!result.success){
            //Rollback all DB changes
            Database.rollback(sp);
            return result;
        }

        Boolean hasException = false;

        List<Sales_Order_Line__c> salesOrderLines = new List<Sales_Order_Line__c>();
        List<Purchase_Order_Line__c> closedPoLines = new List<Purchase_Order_Line__c>();
        Map<Id,Purchase_Order_Line__c> closedPoLinesMap = new Map<Id,Purchase_Order_Line__c>();
            
        List<Accounting_Default__c> soLineSegments = new List<Accounting_Default__c>();
        List<Accounting_Default_Segment_Definition__c> segmentDefinitions = Accounting_Default_Segment_Definition__c.getAll().Values();

        //RowGUID list for Sales order line is for hooking up the DML error messages to the correct row in the UI
        List<String> rowGuidSalesOrderLine = new List<String>();
        //RowGUID list for segments is for hooking up the DML error messages to the correct row in the UI
        List<String> rowGuidSegments = new List<String>();
        //Error message map
        Map<String, List<String>> rowErrors = new Map<String, List<String>>();
        Map<Id, Sales_Order_Line__c> closeSOLMap = new Map<Id, Sales_Order_Line__c>();
        Map<Id, Sales_Order_Line__c> SOLMap = new Map<Id, Sales_Order_Line__c>();
        set<id> reqLineIds = new set<id>();
        set<id> asnId = new set<id>();

        Sales_Order__c salesOrder = sOrder;//(Sales_Order__c)JSON.deserialize(parentRecord, Sales_Order__c.class);

        String soError = preValidateSO(salesOrder);
        
        //If the Sales Order is clear of any error then process the SO Lines
        if(soError == null){

            //Prepare data for DML operation
            if(updatedList.size() > 0){

                for (SOLineWrapper row: updatedList) { 
                    //Convert the kendo date format to Salesforce format
                    //KendoUtils.UpdateDateFields(row.soLine, dateFields);
                    updateSOLineDefaults(row, sOrder, dateFields, false);

                    //Pre validate all rows to be updated
                    rowErrors.putAll(preValidateSoLines(row, 'Update', rowErrors));

                    if(rowErrors.size() > 0){

                        if(rowErrors.containsKey(row.rowGUID)){

                            continue;
                        }
                    }

                    //Add all legit rows for DML operation
                    rowGuidSalesOrderLine.add(row.rowGUID);

                    Boolean isSegmentEmpty = true;

                    // looping through the Segment Def to compare against segments entered
                    for(Accounting_Default_Segment_Definition__c sd : segmentDefinitions){ 

                        if (row.segments != null && row.segments.get(sd.accounting_default_field__c) != null){ //A segment is entered since value is not null (blanks == null)

                            isSegmentEmpty = false; //Even if one of the segments is filled in then set the flag in order to validate that invoice line
                            break;
                        }

                    }

                    if(!isSegmentEmpty){
                        soLineSegments.add(row.segments);
                        rowGuidSegments.add(row.rowGUID);
                    }
                    if(row.soLine.Fulfillment_Source__c == 'Drop Ship'|| row.soLine.Fulfillment_Source__c == 'Back to Back' ){                                                                      
                        if(row.soLine.Quantity_Ordered__c == row.soLine.Quantity_Shipped__c) {
                            row.soLine.Status__c = SalesOrderLineService.SO_LINE_STATUS_CLOSED; 
                            closeSOLMap.put(row.soLine.Id, row.soLine);
                            for(Requisition_Line__c rl : salesOrderLineService.solToReqLines(closeSOLMap)){
                                if(rl.Status__c == 'Open'){
                                    reqLineIds.add(rl.id);
                                }
                            }


                            //Fetch Purchase Order Lines associated with Drop ship / Back to Back SO 
                            closedPoLinesMap = setPolClosedForSoClosed(closeSOLMap);
                            closedPoLines = closedPoLinesMap.values();

                            List<Purchase_Order_Line__c> poLinesToCancel = PurchaseOrderService.getASNlinesToPOLs(closedPoLines);

                            for(Purchase_Order_Line__c pol :poLinesToCancel){
                                for (ASN_Line__c asnLine :pol.ASN_Lines__r) {
                                  asnId.add(asnLine.asn__c) ; 
                                }  
                            }
                            
                            List<ASNAddManageExt.ASNLineWrapper> asnlinewrapperlist = new List<ASNAddManageExt.ASNLineWrapper>();
                            Map<Id,ASNAddManageExt.ASNLineWrapper> asnlMap = new Map<Id,ASNAddManageExt.ASNLineWrapper>();
                            for (ASNAddManageExt.ASNLineWrapper asnlWrapper:ASNService.getASNLineWrappers(asnId,'')) {
                                asnlMap.put(asnlWrapper.asnl.Id,asnlWrapper);
                            }
                                  
                            for(Purchase_Order_Line__c pol :poLinesToCancel){
                                for (ASN_Line__c asnLine :pol.ASN_Lines__r) {
                                    asnlinewrapperlist.add(asnlMap.get(asnLine.Id));
                                }
                            }
                            JsonResult asnlResult = ASNService.CancelCloseASNLines(asnlinewrapperlist,ASNService.ASN_STATUS_CANCELLED,true);

                            if(asnlResult.messages.size()> 0){
                                rowErrors.putAll(preValidateSoLines(row, 'Update', rowErrors));

                            }

                        } else {
                            Set<Id>solIds = new Set<Id>();
                            for(soLineWrapper solrow : updatedList){
                                solIds.add(solrow.soLine.Id);
                            }
                            SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
                            soql.addFields(new set<string>{
                                'Id','name', 'Quantity_Ordered__c','Sales_Order__r.Type__c'
                            });
                            soql.setWhereClause('ID IN :solIds');
                            
                            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Requisition_Lines__r');
                            childRel.addFields(new set<string>{
                                'id','name', 'Status__c', 'Quantity_Ordered__c', 'Sales_Order_Line__c'
                            });
                            soql.addChildRelationship(childRel);

                            List<Sales_Order_Line__c> soLineList = Database.query(soql.getQuery());     
                                String kendoRowGUID = getRowGUID(updatedList, row.soLine.Id);
                            for(Sales_Order_Line__c sol : soLineList){
                            Decimal qty = 0.0;
                                if(sol.id == row.soLine.id){
                                    for(Requisition_Line__c rl : sol.Requisition_Lines__r){                         
                                        if(rl.Status__c == 'Closed'){              
                                            qty = qty + rl.Quantity_Ordered__c;
                                        }
                                    } 
                                    if(row.soLine.Quantity_Ordered__c <= qty && !SalesOrderService.SO_RMA_REPLACEMENT_TYPES.contains(row.soLine.Sales_Order__r.Type__c) && !SalesOrderService.SO_RMA_TYPES.contains(row.soLine.Sales_Order__r.Type__c)){
                                        rowErrors.putAll(addRowErrors(rowErrors, kendoRowGUID, KNDY_INVALID_ORDER_QUANTITY));
                                        continue; 
                                    }    
                                }
                                
                            }

                              
                        }
                        
                    }

                    salesOrderLines.add(row.soLine);

                }
                
            }

			List<Sales_Order_Line__c> newSOLinesList = new List<Sales_Order_Line__c>();
            if(newList.size() > 0){

                for (SOLineWrapper row: newList) { 

                    updateSOLineDefaults(row, sOrder, dateFields, true);

                    //Pre validate all rows to be inserted
                    rowErrors.putAll(preValidateSoLines(row, 'Insert', rowErrors));

                    if(rowErrors.size() > 0){

                        if(rowErrors.containsKey(row.rowGUID)){

                            continue;
                        }
                    }

                    salesOrderLines.add(row.soLine);
					newSOLinesList.add(row.soLine);
                    rowGuidSalesOrderLine.add(row.rowGUID);

                    Boolean isSegmentEmpty = true;

                    // looping through the Segment Def to compare against segments entered
                    for(Accounting_Default_Segment_Definition__c sd : segmentDefinitions){ 

                        if (row.segments != null && row.segments.get(sd.accounting_default_field__c) != null){ //A segment is entered since value is not null (blanks == null)

                            isSegmentEmpty = false; //Even if one of the segments is filled in then set the flag in order to validate that invoice line
                            break;
                        }
                    }

                    if(!isSegmentEmpty){
                        soLineSegments.add(row.segments);
                        rowGuidSegments.add(row.rowGUID);
                    }
                    
                }
            }

            //Upsert Segments associated with the Sales Order Line
            if(soLineSegments.size() > 0){

                try {
                    DML.checkUpsertAsUser(soLineSegments); upsert soLineSegments;

                    //Link the Accounting Default to the updated SO lines
                    for (SOLineWrapper soLineWrapper: updatedList) {

                        Sales_Order_Line__c soLine = soLineWrapper.soLine;
                        Accounting_Default__c segment = soLineWrapper.segments;

                        if (segment != null) {

                            soLine.Accounting_Segment__c = segment.Id;
                        }
                    }

                    //Link the Accounting Default to the new SO lines
                    for (SOLineWrapper soLineWrapper: newList) {

                        Sales_Order_Line__c soLine = soLineWrapper.soLine;
                        Accounting_Default__c segment = soLineWrapper.segments;

                        if (segment != null) {

                            soLine.Accounting_Segment__c = segment.Id;
                        }
                    }
                } catch(DmlException de) {

                    Integer numErrors = de.getNumDml();

                    for(Integer i=0; i<numErrors; i++) {

                        rowErrors.putAll(addRowErrors(rowErrors, rowGuidSegments[de.getDmlIndex(i)], de.getDmlMessage(i)));

                     }
                } catch(Exception e){

					System.debug( logginglevel.error, '~*~ Exception Type: ' + e.getTypeName() );
                    hasException = true;
                    System.debug(loggingLevel.Error, 'Exception on upsert soLineSegments : ' + e.getMessage()); 
                }
                
            }

            //Save Sales Order lines
            if(rowErrors.size() == 0){

                if (salesOrderLines.size() > 0) {
                    if (newSOLinesList.size() > 0) {
                        if ( SalesOrderService.SO_RMA_TYPES.contains( salesOrder.Type__c ) || SalesOrderService.SO_RMA_REPLACEMENT_TYPES.contains(salesOrder.Type__c)) {

							List<Sales_Order_Line__c> replacementCloneList = SalesOrderRMAExt.processRMALines( newSOLinesList, salesOrder, true );

							salesOrderLines.addAll( replacementCloneList );

						}
					}

                    try {
						DML.checkUpsertAsUser(salesOrderLines); upsert salesOrderLines; 
                        if(closedPoLines.size() > 0){
                            DML.checkUpsertAsUser(closedPoLines); upsert closedPoLines;
                        }
                        if(reqLineIds.size() > 0){
                            cancelOpenReqLine(reqLineIds);
                        } 

                    } catch(DmlException de) {
						System.debug( loggingLevel.Error, '*** ' + de.getMessage() + ' ' + de.getStackTraceString() );
						Integer numErrors = de.getNumDml();

                        for(Integer i=0;i<numErrors;i++) {
                            String errorMessage = de.getDmlMessage(i);
                            if(de.getDmlType(i) == StatusCode.DUPLICATE_VALUE){

                                errorMessage = getUserFriendlyErrorMessage(de, i);
                            }
							System.debug( logginglevel.error, '~*~ rowErrors :' + rowErrors );
							// when errors are added via backend service. rowGuidSalesOrderLine cannot index properly so a List Index bound error will be thrown.
                            rowErrors.putAll(addRowErrors(rowErrors, rowGuidSalesOrderLine[de.getDmlIndex(i)], errorMessage));
                        }

                    } catch(Exception e){

						System.debug( logginglevel.error, 'Exception Type: ' + e.getTypeName() );
                        hasException = true;
                        System.debug(loggingLevel.Error, 'KNDY exception : ' + e.getMessage());
                                
                    }
                }

                result = updateJSONResult(result, rowErrors, salesOrderLines.size(),hasException);

            } else {

                result = updateJSONResult(result, rowErrors, 0, hasException);

            }
        } else {

            result.success = false;
            result.addMessage(soError, ApexPages.Severity.ERROR); 
        }

        if(!result.success){
            //Rollback all DB changes
            Database.rollback(sp);
        }else{
            list<Sales_Order__c> records = new list<Sales_Order__c>();
            records.add(sORder);
            result.records = records;
        }

        return result;
    }
    @future 
    public static void cancelOpenReqLine(Set<Id> reqLineIds) {
        List<Requisition_Line__c> rlList = new List<Requisition_Line__c>();
        system.debug(logginglevel.info,'into future'+reqLineIds);
        SOQLUtil soql = new SOQLUtil('Requisition_Line__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'Id','name','Status__c'
                });
                soql.setWhereClause('ID IN :reqLineIds');

            for(Requisition_Line__c rl : Database.query(soql.getQuery())){
                rl.Status__c = 'Cancelled';
                rlList.add(rl);
            }     
            if(rlList.size() >0){
                DML.updateAsUser(rlList);
            }
    }
    public static Map<Id,Purchase_Order_Line__c> setPolClosedForSoClosed(Map<Id, Sales_Order_Line__c> soLinesMap) {
        Map<Id,Requisition_Line__c> dropshipReqLinesMap = new Map<Id,Requisition_Line__c>();
        Map<Id,Purchase_Order_Line__c> closePoLinesMap = new Map<Id,Purchase_Order_Line__c>();
        List<Requisition_Line__c>updateOpenReqLines = new List<Requisition_Line__c>();
        Set<Id> solIds = soLinesMap.keySet();
        Set<Id> poLineIds = new Set<Id>();

        SOQLUtil soql = new SOQLUtil('Requisition_Line__c');
        soql.setWhereClause('Sales_Order_Line__c IN :solIds');
        soql.addFields(new Set<String>{'Id', 'Status__c', 'Quantity_Released__c', 'Name', 'Sales_Order_Line__c'});                                              
        dropshipReqLinesMap = new Map<Id,Requisition_Line__c>((List<Requisition_Line__c>)Database.query(soql.getQuery()));
        Set<Id> reqLineIds = dropshipReqLinesMap.keySet();

		for(Requisition_Line__c rl : dropshipReqLinesMap.values()){
            if(rl.Status__c == 'Open'){
                rl.Status__c = 'Cancelled';
                updateOpenReqLines.add(rl);
            }

        }

        SOQLUtil RcrSoql = new SOQLUtil('Requisition_Cross_Reference__c');
        RcrSoql.addFields(new Set<String>{'Id', 'Purchase_Order_Line__c', 'Purchase_Order_Line__r.Name', 'Requisition_Line__c'});
        RcrSoql.setWhereClause('Requisition_Line__c IN:reqLineIds');
                    
        List<Requisition_Cross_Reference__c> rcfList = Database.query(RcrSoql.getQuery());
        for(Requisition_Cross_Reference__c rcf : rcfList){
            poLineIds.add(rcf.Purchase_Order_Line__c);
        }
        if(poLineIds.size()>0){
            SOQLUtil PolSoql = new SOQLUtil('Purchase_Order_Line__c');
            PolSoql.addFields(new Set<String>{'Id', 'name', 'Status__c'});
            PolSoql.setWhereClause('Id IN :poLineIds');

            List<Purchase_Order_Line__c> polList = Database.query(PolSoql.getQuery());
            for(Purchase_Order_Line__c pol : polList){
				if(pol.Status__c != 'Cancelled'){
                    pol.Status__c = 'Closed';
                    closePoLinesMap.put(pol.id, pol);
                }               

            }
        }
        if(updateOpenReqLines.size() > 0){
            DML.checkUpsertAsUser(updateOpenReqLines); upsert updateOpenReqLines;
        }

    return closePoLinesMap;

    }

    /**
     *  getUserFriendlyErrorMessage method is called if the DMLException error messages are not user
     *  friendly. Any modification to the standard DML error message should go in here.
     *  @param    dmlException    DMLexception (List of DMLExceptions)
     *  @param    index           Integer (Index of the error Message)
     *  @return   errorMessage    String (User friendly error message)
     *
     */
    public static String getUserFriendlyErrorMessage(DMLException dmlException, Integer index){

        String errorMessage = dmlException.getDmlMessage(index);

        //Modify Duplicate messages for line numbers
        if(dmlException.getDmlType(index) == StatusCode.DUPLICATE_VALUE){

            if(errorMessage.contains('Unique_Sales_Order_Line__c ')){

                errorMessage = KNDO_SO_MANAGE_LINES_DUPLICATE_LINE_NUMBERS_ERROR;
            }
        }  

        return errorMessage;
    }

    /*
     *  deleteSalesOrderLines method is called from Sales Order Add manage screen and will be used to delete the 
     *  seleted sales order lines
     *
     *  @param  deleteList  List of selected rows to be deleted
     *  @param  dateFields  List of datefields in the fieldset that needs to be converted to Salesforce date format
     *  @param  parentRecord    SalesOrder Id
     *  @return JsonResult
     *
     */
    @RemoteAction
    public static JsonResult deleteSalesOrderLines(List<SOLineWrapper> deleteList, List<String> dateFields, String parentRecord) {

        JsonResult result = new JsonResult();
        Boolean hasException = false;
        List<Sales_Order_Line__c> deleteSalesOrderLines = new List<Sales_Order_Line__c>();

        //Error message map
        Map<String, List<String>> rowErrors = new Map<String, List<String>>();
        //RowGUID list is for hooking up the DML error messages to the correct row in the UI
        List<String> rowGuid = new List<String>();

        Savepoint sp = Database.setSavepoint();

        Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(parentRecord, Sales_Order__c.class);
        
        String soError = preValidateSO(salesOrder);
        
        if(soError == null){

            //Prepare the data for DML operation
            for (SOLineWrapper row: deleteList) {

                KendoUtils.UpdateDateFields(row.soLine, dateFields);

                //Pre validate all So Lines to be deleted
                rowErrors.putAll(preValidateSoLines(row, 'Delete', rowErrors));

                //Ignore any rows that has failed pre-validation
                if(rowErrors.size() > 0){

                    if(rowErrors.containsKey(row.rowGUID)){

                        continue;
                    }
                }

                rowGuid.add(row.rowGUID);
                deleteSalesOrderLines.add(row.soLine);
            }
            
            if (deleteSalesOrderLines.size() > 0) {

                try {
                    //DP: the comment below doesn't seen valid.  the jira refers to commits done on another file.  copy paste error?
                    //OTC-439 users with Del perm on object can delete any row (even owned by others)
                    DML.deleteAsUser(deleteSalesOrderLines);
                } catch (DMLException de) {

                    Integer numErrors = de.getNumDml();

                    for(Integer i=0;i<numErrors;i++) {

                        rowErrors.putAll(addRowErrors(rowErrors, rowGuid[de.getDmlIndex(i)], de.getDmlMessage(i)));
                    }

                } catch (Exception e) {

                    hasException = true;
                    System.debug(loggingLevel.Error, 'KNDY exception : ' + e.getMessage());
                
                }
            }
            
            result = updateJSONResult(result, rowErrors, deleteSalesOrderLines.size(), hasException);
            
        } else {

            result.success = false;
            result.addMessage(soError, ApexPages.Severity.ERROR); 
        }
        
        if(!result.success){
            //Rollback all DB changes
            Database.rollback(sp);
        }


        return result;
    }
    
    /*
     *  getRowGUID method is called to fetch the Kendo row GUID from the soLine Wrapper List
     *
     *  @param  soLineWrapperList   List<SOLineWrapper>
     *  @param  soLineId            String
     *  @return rowGUID             String
     *  
     */
    private static String getRowGUID(List<SOLineWrapper> soLineWrapperList,String soLineId){

        String rowGUID;

        for(SOLineWrapper soLineWrapper: soLineWrapperList) {

            if(soLineWrapper.soLine.id == soLineId){

                return soLineWrapper.rowGUID;
            }
        }
        return null;
    }

    /*
     *  closeSalesOrderLines method is called from Sales Order Add manage screen and will be used to close the
     *  selected sales order lines
     *
     *  @param  soLines         List of selected rows to be cancelled
     *  @param  dateFields      List of datefields in the fieldset that needs to be converted to Salesforce date format
     *  @param  parentRecord    SalesOrder Id
     *  @return JsonResult
     *
     */
    @RemoteAction
    public static JsonResult closeSalesOrderLines(List<SOLineWrapper> cancelSoLineWrappers, List<String> dateFields, String parentRecord) {

        JsonResult result = new JsonResult();
        Boolean hasException = false;
        //Error message map
        Map<String, List<String>> rowErrors = new Map<String, List<String>>();

        //RowGUID list is for hooking up the DML error messages to the correct row in the UI
        List<String> rowGuidDeleteShipments = new List<String>();
        List<String> rowGuidUpdateSoLines = new List<String>();
        List<Sales_Order_Line__c> closeSoLines = new List<Sales_Order_Line__c>();
        List<Shipment_Line__c> deleteShipmentLines = new List<Shipment_Line__c>();
        List<Task> deleteExceptions = new List<Task>();
        Map<Id, Sales_Order_Line__c> cancelSOLinesMap = new Map<Id, Sales_Order_Line__c>();


        Savepoint sp = Database.setSavepoint();
        Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(parentRecord, Sales_Order__c.class);

        //Pre-validate SalesOrder
        String soError = preValidateSO(salesOrder);

        if(soError == null){



            //Build Cancell Sales Order Lines map
            for ( SOLineWrapper soLineWrapper : cancelSoLineWrappers ) {

                KendoUtils.UpdateDateFields(soLineWrapper.soLine, dateFields);

                rowErrors.putAll(preValidateSoLines(soLineWrapper, 'Close', rowErrors));

                //Ignore any rows that has failed pre-validation
                if(rowErrors.size() > 0){

                    if(rowErrors.containsKey(soLineWrapper.rowGUID)){

                        continue;
                    }
                }

                if ( soLineWrapper.soLine.Id != null ) {

                    cancelSOLinesMap.put(soLineWrapper.soLine.Id, soLineWrapper.soLine );
                }

                if (soLineWrapper.exceptions != null){
                    deleteExceptions.addAll(soLineWrapper.exceptions);
                }
            }

            try {
                //Fetch shipments associated with the SO to be deleted

                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                Set<Id> cancelSOIds = cancelSOLinesMap.keySet();

                SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                        'Id','Name','Quantity_Allocated__c','Quantity_Shipped__c','Status__c','Agreement_Line__c', 'Quantity_Backordered__c'
                });
                soql.setWhereClause('Id IN :cancelSOIds');

                SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Shipment_Lines__r');
                childRel.addFields(new set<string>{
                        'Id','Name','Quantity_Shipped__c','Shipment__c','Shipment__r.Status__c'
                });
                childRel.setWhereClause('Locked__c = false');
                soql.addChildRelationship(childRel);

                for(Sales_Order_Line__c sol : Database.query(soql.getQuery())){
                    //get Row GUID
                    String kendoRowGUID = getRowGUID(cancelSoLineWrappers, sol.Id);

					// if errors exist for this line, skip.
					if (rowErrors.containsKey(kendoRowGUID)){
						continue;
					}

                    sol.Status__c = SalesOrderLineService.SO_LINE_STATUS_CLOSED;

                    for(Shipment_Line__c shipmentLine: sol.Shipment_Lines__r) {
                        deleteShipmentLines.add(shipmentLine);
                        rowGuidDeleteShipments.add(kendoRowGUID);
                    }

                    //Build So Lines list
                    closeSoLines.add(sol);
                    rowGuidUpdateSoLines.add(kendoRowGUID);
                }

            } catch(Exception e) {

                hasException = true;
				System.debug( logginglevel.error, '~*~ ' + e.getMessage() + '\n' + e.getStackTraceString() );
            }

            if(true){ //rowErrors.size() == 0){

				Map<String, List<String>> dmlRowErrors = new Map<String, List<String>>();
                //Delete shiptment lines
                try{

                    DML.deleteAsUser(deleteShipmentLines);
                    DML.deleteAsSystem(deleteExceptions);

                } catch(DMLException de) {

                    Integer numErrors = de.getNumDml();

                    for(Integer i=0;i<numErrors;i++) {

						dmlRowErrors.putAll(addRowErrors(dmlRowErrors, rowGuidDeleteShipments[de.getDmlIndex(i)], de.getDmlMessage(i)));
                    }

                } catch(Exception e) {

                    hasException = true;
					System.debug( logginglevel.error, '~*~ ' + e.getMessage() + '\n' + e.getStackTraceString() );
                }

                // not checking for rowErrors because those lines are not in in the closeSoLines list
				if(dmlRowErrors.size() == 0){

                    //Update sales order lines
                    try {
                        DML.updateAsUser(closeSoLines);
                    } catch(DMLException de) {

                        Integer numErrors = de.getNumDml();

                        for(Integer i=0;i<numErrors;i++) {

							dmlRowErrors.putAll(addRowErrors(dmlRowErrors, rowGuidUpdateSoLines[de.getDmlIndex(i)], de.getDmlMessage(i)));
                        }

                    } catch(Exception e) {

                        hasException = true;
						System.debug( logginglevel.error, '~*~ ' + e.getMessage() + '\n' + e.getStackTraceString() );
                    }
                }

				rowErrors = joinErrorMaps(rowErrors, dmlRowErrors);

                result = updateJSONResult(result, rowErrors, closeSoLines.size(), hasException);

            } else {

                result = updateJSONResult(result, rowErrors, 0, hasException);

            }

        } else {

            result.success = false;
            result.addMessage(soError, ApexPages.Severity.ERROR);

        }

        if(!result.success){
            //Rollback all DB changes
            Database.rollback(sp);
        }

        return result;
    }

	public static Map<String, List<String>> joinErrorMaps(Map<String, List<String>> errorMap1, Map<String, List<String>> errorMap2){
		Map<String, List<String>> joinedMap = new Map<String, List<String>>();

		for (String key : errorMap1.keySet()){
			if (!joinedMap.containsKey(key)){
				joinedMap.put(key, new List<String>());
			}
			joinedMap.get(key).addAll(errorMap1.get(key));
		}

		for (String key : errorMap2.keySet()){
			if (!joinedMap.containsKey(key)){
				joinedMap.put(key, new List<String>());
			}
			joinedMap.get(key).addAll(errorMap2.get(key));
		}

		return joinedMap;
	}

    /*
     *  cancelSalesOrderLines method is called from Sales Order Add manage screen and will be used to cancel the 
     *  seleted sales order lines
     *
     *  @param  soLines         List of selected rows to be cancelled
     *  @param  dateFields      List of datefields in the fieldset that needs to be converted to Salesforce date format
     *  @param  parentRecord    SalesOrder Id
     *  @return JsonResult
     *
     */
    @RemoteAction
    public static JsonResult cancelSalesOrderLines(List<SOLineWrapper> cancelSoLineWrappers, List<String> dateFields, String parentRecord) {

        JsonResult result = new JsonResult();
        Boolean hasException = false;
        //Error message map
        Map<String, List<String>> rowErrors = new Map<String, List<String>>();

        //RowGUID list is for hooking up the DML error messages to the correct row in the UI
        List<String> rowGuidDeleteShipments = new List<String>();
        List<String> rowGuidUpdateSoLines = new List<String>();

        List<Sales_Order_Line__c> cancelSoLines = new List<Sales_Order_Line__c>();
        List<Shipment_Line__c> deleteShipmentLines = new List<Shipment_Line__c>();
        List<Task> deleteExceptions = new List<Task>();
        Map<Id, Sales_Order_Line__c> cancelSOLinesMap = new Map<Id, Sales_Order_Line__c>();
		Map<Id, Requisition_Line__c> cancelReqLinesMap = new Map<Id, Requisition_Line__c>();
        Map<Id, Requisition_Line__c> reqLineMap = new Map<Id, Requisition_Line__c>();
        Map<Id, Purchase_Order_Line__c> cancelPoLinesMap = new Map<Id, Purchase_Order_Line__c>();
        Set<Id> poLineIds = new Set<Id>();
        Boolean updateOnlyReqLine = false;
        Boolean updateReqLineAndPOL = false;

        Savepoint sp = Database.setSavepoint();
        Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(parentRecord, Sales_Order__c.class);
        
        //Pre-validate SalesOrder
        String soError = preValidateSO(salesOrder);

        if(soError == null){

            

            //Build Cancell Sales Order Lines map
            for ( SOLineWrapper soLineWrapper : cancelSoLineWrappers ) {

                KendoUtils.UpdateDateFields(soLineWrapper.soLine, dateFields);

                rowErrors.putAll(preValidateSoLines(soLineWrapper, 'Cancel', rowErrors));

                //Ignore any rows that has failed pre-validation
                if(rowErrors.size() > 0){

                    if(rowErrors.containsKey(soLineWrapper.rowGUID)){

                        continue;
                    }
                }

                if ( soLineWrapper.soLine.Id != null ) {

                    cancelSOLinesMap.put(soLineWrapper.soLine.Id, soLineWrapper.soLine );
                }

                if (soLineWrapper.exceptions != null){
                    deleteExceptions.addAll(soLineWrapper.exceptions);
                }
            }
            
            try {
                //Fetch shipments associated with the SO to be deleted
                
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				Set<Id> cancelSOIds = cancelSOLinesMap.keySet();
				
				SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','Name','Quantity_Allocated__c','Quantity_Shipped__c','Status__c','Agreement_Line__c'
				});
				soql.setWhereClause('Id IN :cancelSOIds');
				
				SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Shipment_Lines__r');
				childRel.addFields(new set<string>{
					'Id','Name','Quantity_Shipped__c','Shipment__c','Shipment__r.Status__c'
				});
				childRel.setWhereClause('Locked__c = false');
				soql.addChildRelationship(childRel);

				for(Sales_Order_Line__c sol : Database.query(soql.getQuery())){
                    //get Row GUID
                    String kendoRowGUID = getRowGUID(cancelSoLineWrappers, sol.Id);

                    if(sol.Quantity_Shipped__c > 0){

                        String qtyShippedError = 'Quantity has already been shipped for this sales order line and hence cannot be cancelled.';
                        rowErrors.putAll(addRowErrors(rowErrors, kendoRowGUID, qtyShippedError));
                        continue;
                    }
                    
                    // TODO : Should we automatically unallocate too if a line is cancelled ??                          
                    if(sol.Quantity_Allocated__c > 0){

                        String qtyAllocatedError = 'Quantity has already been allocated for this sales order line. Please unallocate the quantity in order to cancel the line.';
                        rowErrors.putAll(addRowErrors(rowErrors, kendoRowGUID, qtyAllocatedError));
                        continue;                           
                    }
                    
                    sol.Status__c = SalesOrderLineService.SO_LINE_STATUS_CANCELLED; 
                    
                    reqLineMap = SalesOrderLineService.cancelReqLines(cancelSOLinesMap);
                    
                    Set<ID> reqIds = reqLineMap.keyset();
                    SOQLUtil soql1 = new SOQLUtil('Requisition_Cross_Reference__c');
                    soql1.addFields(new Set<String>{'Id', 'Purchase_Order_Line__c', 'Purchase_Order_Line__r.Name', 'Requisition_Line__c'});
                    soql1.setWhereClause('Requisition_Line__c IN:reqIds');
                    List<Requisition_Cross_Reference__c> rcfList = Database.query(soql1.getQuery());
                    
                    for(Requisition_Cross_Reference__c rcf : rcfList){
                    	 poLineIds.add(rcf.Purchase_Order_Line__c);
                    }
                    if(poLineIds.size()>0){
                    	SOQLUtil soql2 = new SOQLUtil('Purchase_Order_Line__c');
                    	soql2.addFields(new Set<String>{'Id', 'name', 'Status__c', 'Quantity_Matched__c'});
                    	soql2.setWhereClause('Id IN :poLineIds');
                    	List<Purchase_Order_Line__c> polList = Database.query(soql2.getQuery());
                    	
                    	for(Purchase_Order_Line__c pol : polList){
                   			pol.Status__c = 'Cancelled';
                    	 	cancelPoLinesMap.put(pol.id, pol);
                    	 	updateReqLineAndPOL = true;	
                    	 	
                    	 	if(pol.Quantity_Matched__c > 0){
                        		String qtyInvoicedError = 'Cannot Cancel the Sales Order Line since a Supplier Invoice is created. Please contact your administrator.';
                        		rowErrors.putAll(addRowErrors(rowErrors, kendoRowGUID, qtyInvoicedError));
                        		continue;
                    		}	
                    	}
                    	if(updateReqLineAndPOL){
                            try{
                    	       DML.updateAsUser(cancelPoLinesMap.values());
                    	       SalesOrderLineService.cancelReqLines(cancelSOLinesMap);
                       		}catch(Exception e){
                       			rowErrors.putall(addRowErrors(rowErrors, kendoRowGUID, e.getMessage()));
                       		}
                    	}
                        
                    }

                    for(Shipment_Line__c shipmentLine: sol.Shipment_Lines__r) {

                       deleteShipmentLines.add(shipmentLine);
                       rowGuidDeleteShipments.add(kendoRowGUID);

                    }

                    //Build So Lines list
                    cancelSoLines.add(sol);
                    rowGuidUpdateSoLines.add(kendoRowGUID);
                }

            } catch(Exception e) {

                hasException = true;
                System.debug(e.getMessage());
            }

            if(rowErrors.size() == 0){

                //Delete shiptment lines
                try{

                    DML.deleteAsUser(deleteShipmentLines);
                    DML.deleteAsSystem(deleteExceptions);

                } catch(DMLException de) {

                    Integer numErrors = de.getNumDml();

                    for(Integer i=0;i<numErrors;i++) {

                        rowErrors.putAll(addRowErrors(rowErrors, rowGuidDeleteShipments[de.getDmlIndex(i)], de.getDmlMessage(i)));
                    }

                } catch(Exception e) {

                    hasException = true;
                    System.debug(e.getMessage());
                }

                if(rowErrors.size() == 0){

                    //Update sales order lines
                    try {
                    	DML.updateAsUser(cancelSoLines);
                    } catch(DMLException de) {

                        Integer numErrors = de.getNumDml();

                        for(Integer i=0;i<numErrors;i++) {

                            rowErrors.putAll(addRowErrors(rowErrors, rowGuidUpdateSoLines[de.getDmlIndex(i)], de.getDmlMessage(i)));
                        }

                    } catch(Exception e) {

                        hasException = true;
                        System.debug(e.getMessage());
                    }
                }

                result = updateJSONResult(result, rowErrors, cancelSoLines.size(), hasException);

            } else {

                result = updateJSONResult(result, rowErrors, 0, hasException);

            }

        } else {

            result.success = false;
            result.addMessage(soError, ApexPages.Severity.ERROR); 

        }

        if(!result.success){
            //Rollback all DB changes
            Database.rollback(sp);
        }

        return result;
    }
    
    /*
     *  fetchAllowance method is called when the user enters an Allowance rule on the Sales Order Manage
     *  allowances page and tabs out. 
     *
     *  @param  allowanceRuleId 
     *  @return JsonResult    
     *
     */
    @RemoteAction
    public static JsonResult fetchAllowance(String allowanceRuleId,
            String soLineId, Decimal overrideValue) {

        JsonResult result = new JsonResult();

        if (allowanceRuleId != null) {

            try{

                Allowance_Applied__c allowanceApplied = new Allowance_Applied__c();

				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
                SOQLUtil soql = new SOQLUtil('Allowance_Rule__c', true); //enforceFLS=true, running in user mode
                soql.addFields(AllowanceRuleService.allowanceRuleFields);
                soql.setWhereClause('Id = :allowanceRuleId');
				soql.setLimit(1);
				
                Allowance_Rule__c allowanceRule = Database.query(soql.getQuery());
                Allowance_Type__c allowanceType = allowanceRule.Allowance_Type__r;

                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
                soql.addFields(AllowanceRuleService.salesOrderLineFields);
				soql.setWhereClause('Id = :soLineId');
				soql.setLimit(1);

				Sales_Order_Line__c soLine = Database.query(soql.getQuery());

                Allowance_Applied__c aa = new AllowanceCalcService.AllowanceCreation(
                    new AllowanceRuleService.RuleContext(
                        allowanceRule,
                        new List<Sales_Order_Line__c>{soLine},
                        overrideValue
                    )
                ).getAllowanceRecord();

                result.records = new List<Allowance_Applied__c> {aa};
                result.total = result.records.size();
                result.success = true;

            } catch (Exception e){
                
                result.success = false;
                result.addMessage('An Error occured : ' + e.getMessage(), ApexPages.Severity.ERROR);
                System.debug(loggingLevel.Error, '*** e: ' +  e.getMessage() + ' ' + e.getStackTraceString());
            }

        }

        return result;
    }

    /*
     *  fetchAllowanceRules method returns all the list of Allowance Rules that can be applied 
     *  for a sales order line. 
     *
     *  @param  soLineId 
     *  @return List<SelectListItem>    
     *
     */
    @RemoteAction
    public static JsonResult fetchAllowanceRuleTypes(String soLineId) {

        List<Allowance_Rule__c> ruleList = AllowanceService.loadManualRules(soLineId);
        
        return new JsonResult(ruleList, ruleList.size());
    }
    
    /*
     *  getSOLineHeaderFieldList method returns the list of fields for Manage Line Allowances header
     *
     *  @return String  
     *
     */
    public string getSOLineHeaderFieldList() {
        String salesOrderLineHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        
        // get the sales order line header field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Sales_Order_Line__c', 'Manage_Line_Allowances_Header');
        
        for (Integer i = 0; i < fieldInfoList.size(); i++){
            fieldInfoList[i].editable = false;
        }
        
		fieldInfoList.remove(0); // Remove Id field from the list
        
        salesOrderLineHeaderFieldList = JSON.serialize(fieldInfoList);
        
        return salesOrderLineHeaderFieldList;
    }
    
    /*
     *  getSOLineHeaderDetails method returns information related to SO Line header details
     *  for Sales Order line allowances pop up window.
     *
     *  @param  soLineId 
     *  @return List<SelectListItem>    
     *
     */
    @RemoteAction
    public static JsonResult getSOLineHeaderDetails(Id soLineId) { 
        String objectName = 'Sales_Order_Line__c';
        String headerFieldset = 'Manage_Line_Allowances_Header';  
        Set<String> addlFields = new Set<String> {};      
        //string whereClause = 'Id  = :soLineId LIMIT 1';
        
        String whereClause =  'Id = :soLineId LIMIT 1';
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
        soql.addFields('Manage_Line_Allowances_Header');
        soql.addFields(new Set<String>(addlFields));
        soql.setWhereClause(whereClause);
        
        //String queryString = util.generateQueryFromFieldSet(objectName, new Set<string>{ headerFieldset }, addlFields, whereClause);

        List<Sales_Order_Line__c> soLine = database.query(soql.getQuery());   
 
        return new JsonResult(soLine, soLine.size());
    }

	/**
	 * Get the search results on Sobject for the search term and returns
	 * the records with fields in the fielset defined. If the fieldset is
	 * blank then the result is comparative to (List<SelectListItem>) lookupSearchFilter()
	 * but returns the result in a map
	 */
	@RemoteAction
	public static List<Object> lookupSearchFilter2 ( String searchTerm, String objectName, String filterCriteria, String additionalFields) {

		SchemaUtil util = SchemaUtil.getInstance();
		List<Object> selectList = new List<Object>();

		try {

			if ( String.isBlank( objectName ) ) {
				return selectList;
			}

			Schema.SObjectType objectType = util.getGlobalDescribe( objectName );

			SOQLUtil soql = new SOQLUtil( objectName );
			soql.addFields( new set<string>{ 'Id', 'Name' } );


			Set<String> fields =  new Set<String>( additionalFields.split( ',' ));
			if ( String.isNotEmpty( additionalFields ) ) {
				soql.addFields( fields );
			}



			String filterString = '';
			if ( String.isNotBlank( searchTerm ) ) {
				filterString += 'Name LIKE \'%' + String.escapeSingleQuotes( searchTerm ) + '%\'';

				if ( searchTerm.length() <= 3 ) {
					soql.setLimit( 100 );
				}
			}
			else {
				soql.setLimit( 100 );
			}

			if ( String.isNotBlank( filterCriteria ) ) {
				if ( filterString.trim().startsWith( 'Name' ) ) {
					filterString += ' AND ' + filterCriteria;
				}
				else {
					filterString += filterCriteria;
				}
			}

			soql.setWhereClause( filterString );
			soql.setOrderByClause( 'Name' );
			List<SObject> result = Database.query( soql.getQuery() );

			// get fields for fieldset

			for ( SObject obj : result ) {
				String id = String.valueOf( obj.get( 'Id' ) );
				String name = String.valueOf( obj.get( 'Name' ) );
				Map<String, Object> selectListItem = new Map<String, Object>();
				selectListItem.put( 'value', id );
				selectListItem.put( 'text', name );

				Map<String, Object> selectItem = (Map<String, Object> ) JSON.deserializeUntyped( JSON.serialize( obj ) );
				selectListItem.put( 'sobjectMap', selectItem );
				selectList.add( selectListItem );
			}
		} catch (exception e){
			System.debug( logginglevel.error, '~*~ e: ' + e.getMessage() + '\n' + e.getStackTraceString());
		}

		return selectList;
	}

    /** 
     *  Class Name: SOLineWrapper 
     *  
     *  @Description: SOLineWrapper is the wrapper class that holds the Sales Order Line information along with other important
     *                  data for the functionality of the Sales Order Line Manage page to be complete.                
     *  @Copyright : Kenandy, Inc. 2015
     *  @author : Jerome Israel
     *  @Date : 04/22/2015
    * */ 
    public class SOLineWrapper{

        public Sales_Order_Line__c soLine { get; set; }
        public ID loc;

        public String rowGUID = '';
        public Accounting_Default__c segments { get; set; }
        Task[] exceptions { get; set; }
        List<Object> errors { get; set; }
        public Decimal quantityFactor { get; set; }
        
        //Constructor 1
        public SOLineWrapper(){
            Accounting_Default__c ad = new Accounting_Default__c();
            
            this.soLine = new Sales_Order_Line__c();
            this.segments = ad;
        }
        
        //Constructor 2
        public SOLineWrapper(Sales_Order_Line__c soLine) {
            Accounting_Default__c ad = new Accounting_Default__c();
            this.soLine = soLine;     
            
            if (soLine.Accounting_Segment__c != null) { 
                ad = soLine.Accounting_Segment__r; 
            }
                    
            this.segments = ad;
        }

        //Constructor 3
        public SOLineWrapper(Sales_Order_Line__c soLine, List<Task> exceptions) {
            Accounting_Default__c ad = new Accounting_Default__c();
            this.exceptions = exceptions;
            this.soLine = soLine;        
            
            if (soLine.Accounting_Segment__c != null) { 
                ad = soLine.Accounting_Segment__r; 
            }
            
            this.segments = ad;
        }

        public void updateQuantityFactor(String quantityFactoredAt) {
                
                if(quantityFactoredAt == 'Layer'){

                    this.quantityFactor = this.soLine.Product__r.Units_per_Layer__c;

                    
                } else if(quantityFactoredAt == 'Pallet'){

                    this.quantityFactor = this.soLine.Product__r.Units_per_Pallet__c;
                }
        }
    }

    /** 
     *  Class Name: SOLineErrorWrapper 
     *  
     *  @Description: SOLineErrorWrapper is the wrapper class that holds the error information for the Sales Order Lines to be
    *                  displayed on the Sales Order Line Manage page.                
     *  @Copyright : Kenandy, Inc. 2015
     *  @author : Jerome Israel
     *  @Date : 05/01/2015
    * */ 
    public class SOLineErrorWrapper {
        public String rowGUID { get; set; }
        public List<String> errors { get; set; }

        //Constructor 1
        public SOLineErrorWrapper(String rowGUID, List<String> errors) {

            this.rowGUID = rowGUID;
            this.errors = errors;
        }
    }
}
