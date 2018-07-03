global with sharing class AgreementReleaseExt extends BaseController{

    private static SchemaUtil util = SchemaUtil.getInstance();
    public string NamespaceUU { get { return KSE.NamespaceUU; } }
    public Apexpages.Standardcontroller con {get;set;}

    public List<LineWrapper> lws {get;set;}
    public boolean renderGrid  {get;set;}
    public boolean disableButton {get;set;}
    public class AgreementReleaseException extends Exception{}

    public string agreementId {get;set;}
    public string agreementLineFieldList {get; set; }
    public GridRelatedListController.GridRelatedListConfig agreementLinesConfig {get; set;}

    public string billTo {get;set;}
    public string soldTo {get;set;}
    public string shipTo {get;set;}

    public boolean isSuccess {get;set;}
    public String errorMsg{get;set;}

    //Serial Search UI related attributes
    public String SerialsFieldList = null;
    public GridRelatedListController.GridRelatedListConfig SerialsConfig {get; set;}
    public string serialAttributes { get; set;}

    public pageReference passvals() {

        return null;
    }

    public AgreementReleaseExt(){

        ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'No agreement is specified.'));
    }

    public string getSerialsFieldList() {
        if (SerialsFieldList == null && SerialsConfig != null) {
            FieldInfo fieldInfoItem;

            try{

                List<String> serialAttributesList = new list<String>();
                for( String serAttr : SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'Serial_Attributes') ){
                    serAttr = serAttr.replace( KSE.namespaceUU, '').toLowerCase().trim();
                    serialAttributesList.add(serAttr);
                }

                serialAttributes = JSON.serialize(serialAttributesList);

                //Get Name, Company, SKID from Serial
                List<String> fields = new List<String>{'ID','Name','Company__c','SKID__c'};

                //Get the list of serial attributes from the Item Attribute fieldset
                List<FieldInfo> serialFields = FieldInfo.fetchJsonFieldInfos('Item_Attribute__c', 'Serial_Attributes');
                for (FieldInfo f : serialFields){
                    f.editable = false;
                    fields.add(f.field);
                }

                List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Serial__c',fields);
                for (FieldInfo f : fieldInfoList){
                    f.required = false;
                    f.filterable = true;
                    f.editable = false;
                    if (f.field == 'id'){
                        f.hidden = true;
                	}
                }
                SerialsFieldList = JSON.serialize(fieldInfoList);
            }
            catch(FieldInfo.EmptyFieldSetMemberException e){
                SerialsFieldList = '';
                //Get Name, Company, SKID from Serial to make sure some fields are shown in the serials grid even if the fieldset if empty
                List<String> fields = new List<String>{'ID','Name','Company__c','SKID__c'};
                List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Serial__c',fields);
                for (FieldInfo f : fieldInfoList){
                    f.required = false;
                    f.filterable = true;
                    f.editable = false;
                    if (f.field == 'id'){
                        f.hidden = true;
            }
        }
                SerialsFieldList = JSON.serialize(fieldInfoList);
            }
        }

        return SerialsFieldList;
    }

    public String getSerialsConfigJson() {
        String configStr = JSON.serialize(this.SerialsConfig);
        return configStr;
    }

    public AgreementReleaseExt(Apexpages.Standardcontroller controller){

        // get the agreement lines field info list
        List<FieldInfo> agreementLinefieldInfoList = FieldInfo.fetchJsonFieldInfos('Agreement_Line__c', 'Release');

        List<FieldInfo> additionalFieldInfo = FieldInfo.fetchJsonFieldInfos('Agreement_Line__c', new String[] {'Customer_Site__c'});

        List<FieldInfo> requiredDateFieldInfo = FieldInfo.fetchJsonFieldInfos('Sales_Order_Line__c', new String[] {'Required_Date__c'});

        List<FieldInfo> fulfillmentStartDateFieldInfo = FieldInfo.fetchJsonFieldInfos('Sales_Order_Line__c', new String[] {'Fulfillment_Start_Date__c'});

        for(FieldInfo field : additionalFieldInfo) {
            agreementLinefieldInfoList.add(field);
        }

        // set the wrapper class prefix
        for(Integer i = 0; i < agreementLinefieldInfoList.size(); i++){

            agreementLinefieldInfoList[i].field = 'al.' + agreementLinefieldInfoList[i].field;
            if (agreementLinefieldInfoList[i].field == 'al.Price_Type__c'){
                agreementLinefieldInfoList[i].editable = false;
        	}
        }

        for(FieldInfo field : requiredDateFieldInfo) {
            agreementLinefieldInfoList.add(field);
        }

        for(FieldInfo field : fulfillmentStartDateFieldInfo) {
            agreementLinefieldInfoList.add(field);
        }

        /*
        KNDY-11699 - Commenting this piece as the available qty column should be added based on Serial Control on Company. Adding it after agreement query
        agreementLineFieldList = JSON.serialize(agreementLinefieldInfoList);
        */
        agreementLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        agreementLinesConfig.uniqueId = 'agreementLines';
        agreementLinesConfig.objectName = 'Agreement_Line__c';
        agreementLinesConfig.parentField = 'Agreement__c';
        agreementLinesConfig.buttons = '';

        SerialsConfig = new GridRelatedListController.GridRelatedListConfig();
        SerialsConfig.uniqueId = 'SerialsGrid';
        SerialsConfig.objectName = 'Serial__c';
        SerialsConfig.buttons = 'columnmenu, search';

        this.con = controller;

        if(this.con == null){

            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'No agreement is specified.'));
        }else{
            renderGrid = true;
            disableButton = false;
            if(!test.isRunningTest()){
                this.con.addFields(new list<String>{'Company__c', 'Customer__c', 'Customer__r.RecordType.DeveloperName', 'Status__c', 'Currency__c',//Ship To
                                       'Customer__r.Parent_Customer__c', 'Customer__r.Parent_Customer__r.Name', //Sold To
                                       'Customer__r.Parent_Customer__r.Parent_Customer__c', 'Customer__r.Parent_Customer__r.Parent_Customer__r.Name', //Bill To
                                       'Payment_Terms__c', 'Bill_To__c', 'Sold_To__c', 'Ship_To__c',
                                       'Company__c', 'Company__r.Serial_Control__c', //company's serial attribute
                                       'Customer__r.Top_Parent_Customer__c', 'Customer__r.Top_Parent_Customer__r.Name'});
            }

            Agreement__c agreement  = (Agreement__c) con.getRecord();
            agreementId = agreement.Id;
            updateLines();

            //KNDY-11699 - check for serial control and add the available qty column to the grid
            if (agreement.Company__r.Serial_Control__c != null){
                FieldInfo fieldInfoItem = new FieldInfo('serialQty', 'Available Quantity', 'double', false);
                fieldInfoItem.editable = false;
                agreementLinefieldInfoList.add(fieldInfoItem);
            }

            agreementLineFieldList = JSON.serialize(agreementLinefieldInfoList);

            if(agreement.Customer__r.RecordType.DeveloperName == 'Sold_To') {
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id'
				});
				Id custId = agreement.Customer__c;
				soql.setWhereClause('RecordType.DeveloperName = \'Ship_To\' and Parent_Customer__c = :custId');
				list<Customer__c> shipTos = Database.query(soql.getQuery());

                if(shipTos.size() == 1)
                {
                    shipTo = shipTos[0].Id;
                    soldTo = agreement.Customer__c;
                    billTo = agreement.Customer__r.Parent_Customer__c;
                }

            }
            else if(agreement.Customer__r.RecordType.DeveloperName == 'Bill_To') {
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id'
				});
				Id custId = agreement.Customer__c;
				soql.setWhereClause('RecordType.DeveloperName = \'Sold_To\' and Parent_Customer__c = :custId');
				list<Customer__c> soldTos = Database.query(soql.getQuery());

                if(soldTos.size() == 1)
                {
					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
					soql.addFields(new set<string>{
						'id'
					});
					custId = agreement.Customer__c;
					soql.setWhereClause('RecordType.DeveloperName = \'Ship_To\' and Parent_Customer__c = :custId');
					list<Customer__c> shipTos = Database.query(soql.getQuery());

                    if(shipTos.size() == 1)
                    {
                        shipTo = shipTos[0].Id;
                        soldTo = soldTos[0].Id;
                        billTo = agreement.Customer__c;
                    }

                }
            }

            else  {
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id'
				});
				Id custId = agreement.Customer__c;
				soql.setWhereClause('RecordType.DeveloperName = \'Bill_To\' and Parent_Customer__c = :custId');
				list<Customer__c> billTos = Database.query(soql.getQuery());

                if(billTos.size() == 1)
                {
					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
					soql.addFields(new set<string>{
						'id'
					});
					soql.setWhereClause('RecordType.DeveloperName = \'Sold_To\' and Parent_Customer__c = :billTos');
					list<Customer__c> soldTos = Database.query(soql.getQuery());

                    if(soldTos.size() == 1)
                    {
						//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
						soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
						soql.addFields(new set<string>{
							'id'
						});
						soql.setWhereClause('RecordType.DeveloperName = \'Ship_To\' and Parent_Customer__c = :soldTos');
						list<Customer__c> shipTos = Database.query(soql.getQuery());

                        if(shipTos.size() == 1)
                        {
                            shipTo = shipTos[0].Id;
                            soldTo = soldTos[0].Id;
                            billTo = billTos[0].Id;
                        }

                    }
                }

            }

        }

    }

    public void updateLines(){

        lws = new List<LineWrapper>();

        set<string> alFields = new set<string>{'Id', 'name', 'Description__c','Price_Type__c','Pricing_UOM__c', 'customer_site__c', 'product__c', 'product__r.name',
        'product__r.selling_uom__c', 'product__r.item__r.lead_time__c', 'product__r.product_type__c', 'product__r.item__r.fulfillment_source__c', 'product__r.used__c',
         'agreement_price__c', 'ship_to__c', 'rate_basis__c', 'occurrence__c', 'start_date__c', 'end_date__c'};

        for(string field : schemautil.getInstance().getFieldsFromFieldSetString(Agreement_Line__c.getSObjectType(), 'Release')){
            //Guard against duplicate fields due to Namespace
            field = field.replace(KSE.NamespaceUU, '');
            alFields.add(field.toLowerCase());
        }
        //string status = 'Pending Approval';
        List<String> statusList = new List<String>();
        statusList.add('Pending Approval');
        statusList.add('Rejected');
        datetime oDate = system.now();
        SOQLUtil soql = new SOQLUtil('Agreement_Line__c', TRUE);
        soql.addFields(alFields);
        soql.setWhereClause('Agreement__c = \'' + con.getId() + '\' AND Revision_Status__c NOT IN :statusList AND start_date__c <= :oDate AND (end_date__c > :oDate OR end_date__c = null) AND Product__r.Item__r.Source__c != \'One Time Charge\'');
        soql.setOrderByClause('NAME');
        for(Agreement_Line__c al : Database.query(soql.getQuery())){
            lws.add(new LineWrapper(al));
        }
        if(lws.size() == 0){
            renderGrid = false;
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.WARNING, 'There are no lines for this agreement.'));
        }
    }

    @RemoteAction
    global static JsonResult getSerials(ID itemID, boolean prodUsed, string agrLineType) {

        JsonResult result = new JsonResult();

        if (agrLineType == null){
            agrLineType = 'Sales'; //make sure there is a default, if the agreement line does not have a line type
        }

        List<String> filterCriteria = new List<String>();
        filterCriteria.add('Allow_Reentry__c = false');
        filterCriteria.add('SKID__c != null');
        filterCriteria.add('Allocated_SKID__c = null');
        filterCriteria.add('SKID__r.Type__c != \'Install Base\'');
        filterCriteria.add('SKID__r.Shipment_Line__c = null');
        filterCriteria.add('Item__c = :itemID');

        //KNDY-12482 - Logic to check if the serial returned should be rental/sale and if it is used or new
        if (agrLineType == 'Recurring' && prodUsed == true){ //this is used product for rental, so bring all serials on skid where Rental = true and Used = true
            filterCriteria.add('SKID__r.Used__c = true');
            filterCriteria.add('SKID__r.Rental__c = true');
        }
        else if(agrLineType == 'Sales' && prodUsed == true){ //this is used product for sale, so bring all serials on skid where Rental = false and Used = true
            filterCriteria.add('SKID__r.Used__c = true');
            filterCriteria.add('SKID__r.Rental__c = false');
        }
        else if(agrLineType == 'Recurring' && prodUsed == false){ //this is selling product for rental, so bring all serials on skid where Rental = true and Used = false
            filterCriteria.add('SKID__r.Used__c = false');
            filterCriteria.add('SKID__r.Rental__c = true');
        }
        else if(agrLineType == 'Sales' && prodUsed == false){ //this is selling product for sale, so bring all serials on skid where Rental = false and Used = false
            filterCriteria.add('SKID__r.Used__c = false');
            filterCriteria.add('SKID__r.Rental__c = false');
        }

        String whereClause = '';

        if (filterCriteria.size() > 0) {
            whereClause += String.join(filterCriteria, ' AND ');
        }

        List<String> serialFieldsList = util.getFieldsFromFieldSetString('Item_Attribute__c', 'Serial_Attributes');
        Set<String> serialFieldsSet = new Set<String>(serialFieldsList);
        serialFieldsSet.addAll(util.getAllCustomFieldsFromObject(null,'Serial__c'));

        datetime oDate = system.now();
        SOQLUtil soql = new SOQLUtil('Serial__c', TRUE);
        soql.addFields(new Set<String>{'Id', 'name', 'Company__c', 'SKID__c', 'SKID__r.Item__r.Fulfillment_Source__c'});
        soql.addFields(serialFieldsSet);
        soql.addFields(util.getAllCustomFieldsFromObject('SKID__r.','SKID__c'));
        soql.setWhereClause(whereClause);
        soql.setOrderByClause('NAME');

        List<Serial__c> serialList = getSerialList(database.query(soql.getQuery()));

        boolean isNonInventory = false;

        if (serialList.size() > 0){
            for (Serial__c s : serialList){
                if (isNonInventory == false && s.SKID__r.Item__r.Fulfillment_Source__c != 'Inventory'){
                    isNonInventory = true;
                }
            }
        }else{
            result.addMessage('No records to display', ApexPages.Severity.WARNING);
        }

        if (isNonInventory){
            result.success = false;
            String message = 'Cannot select inventory to allocate for this Item';
            result.addMessage(message, ApexPages.Severity.ERROR);
            return result;
        }

        result.records = serialList;
        result.total = serialList.size();
        return result;

    }

    public static List<Serial__c> getSerialList(List<Serial__c> serialList){

        Set<Id> rlForWO = new Set<Id>();
        for (Serial__c serial : serialList){
            if (serial.SKID__r.Receipt_Line__c != null){
                rlForWO.add(serial.SKID__r.Receipt_Line__c);
            }
        }

        if (!rlForWO.isEmpty()){
            Set<Id> nonCompleteRl = new Set<Id>();
            for (Work_Order__c wo : [select id, Receipt_Line__c from Work_Order__c where Receipt_Line__c IN :rlForWO and Status__c Not IN ('Complete')]){
                nonCompleteRl.add(wo.Receipt_Line__c);
            }

            // indexing to preserver query sort order
            for (Integer i = serialList.size() - 1; i >= 0; i--){
                // remove serials that have a RL with a related WO that's not complete
                if (nonCompleteRl.contains( serialList[i].Skid__r.Receipt_Line__c) ){
                    serialList.remove(i);
                }
            }
        }
        return serialList;
    }

    @RemoteAction
    global static JsonResult getAgreementLineData(String agreementId) {
        List<LineWrapper> wrapperList = new List<LineWrapper>();
        JsonResult result = new JsonResult();
        //string status = 'Pending Approval';
        List<String> statusList = new List<String>();
        statusList.add('Pending Approval');
        statusList.add('Rejected');
        datetime oDate = system.now();
        SOQLUtil soql = new SOQLUtil('Agreement_Line__c', TRUE);
        soql.addFields('Release');
        soql.addFields(new Set<String>{'Parent_Agreement_Line__c', 'List_Price__c', 'Pricebook__c','Description__c', 'Price_Type__c','Pricing_UOM__c','Id', 'name', 'customer_site__c', 'product__c', 'product__r.name', 'product__r.Selling_UOM__c',
                                        'Product__r.Item__c','Product__r.Item__r.Non_Inventory__c','Product__r.Item__r.Item_Attribute__c', 'Product__r.Item__r.Item_Attribute__r.Serial_Number__c',
                                        'product__r.item__r.lead_time__c', 'product__r.product_type__c', 'product__r.item__r.fulfillment_source__c', 'Product__r.Used__c', 'product__r.Item_Specification__c',
                                        'agreement_price__c', 'ship_to__c', 'occurrence__c', 'rate_basis__c', 'start_date__c', 'end_date__c','Agreement__c'});

        soql.addFields(util.getAllCustomFieldsFromObject('Product__r.Item__r.Item_Attribute__r.','Item_Attribute__c'));
        soql.setWhereClause('Agreement__c = :agreementId AND Revision_Status__c NOT IN :statusList AND (end_date__c > :oDate OR end_date__c = null) AND Product__r.Item__r.Source__c != \'One Time Charge\'');
        soql.setOrderByClause('NAME');
        List<Agreement_Line__c> agreementLineList = database.query(soql.getQuery());

        Set<id> itemIDstogetSerials = new Set<id>();

        for (Integer i = 0; i< agreementLineList.size() ; i++) {

            LineWrapper lineWrapper = new LineWrapper(agreementLineList[i]);

            if (agreementLineList[i].Product__r.Item__r.Item_Attribute__c != null &&
                agreementLineList[i].Product__r.Item__r.Item_Attribute__r.Serial_Number__c == true &&
                agreementLineList[i].Product__r.Item__r.Non_Inventory__c == false){
                itemIDstogetSerials.add(agreementLineList[i].Product__r.Item__c);
                lineWrapper.isSerialProduct = true;
            }else{
                lineWrapper.isSerialProduct = false;
            }

            wrapperList.add(lineWrapper);
        }

        //TODO: Can check the company serial enable attribute and disable the complete block below
        //Query the list of serials available for the serial items and store it in a item to serial map
        SOQLUtil soql_serial = new SOQLUtil('Serial__c', TRUE);
        soql_serial.addFields(new Set<String> {'Id', 'name', 'SKID__c', 'Allow_Reentry__c', 'Item__c', 'SKID__r.Used__c', 'SKID__r.Rental__c', 'SKID__r.Receipt_Line__c'});
        soql_serial.setWhereClause('SKID__c != null AND Allocated_SKID__c = null AND Allow_Reentry__c = false AND SKID__r.Type__c != \'Install Base\' AND SKID__r.Shipment_Line__c = null AND Item__c in :itemIDstogetSerials');

        List<Serial__c> serialList = getSerialList(database.query(soql_serial.getQuery()));

        Map<id, List<Serial__c>> itemToSerialList = new Map<id, List<Serial__c>>();

        //create a map with item id/used or rental/Agreement line type to list of serials
        Map<String, List<Serial__c>> itemUsedorRentalMap = new Map<String, List<Serial__c>>();
        for (Serial__c s : serialList) {
            List<Serial__c> sList = new List<Serial__c>();
            string uniquekey = (string)s.Item__c + s.SKID__r.Used__c + s.SKID__r.Rental__c;
            if (!itemUsedorRentalMap.containsKey(uniquekey)){
                sList.add(s);
                itemUsedorRentalMap.put(uniquekey, sList.clone());
            }
            else{
                sList = itemUsedorRentalMap.get(uniquekey);
                sList.add(s);
                itemUsedorRentalMap.put(uniquekey, sList.clone());
            }
        }

        //Loop through the item to serial map and get the available serial quantity to display in the UI. This is displayed as the available quantity
        for (LineWrapper l : wrapperList){
            //based on agreement line type and product's item, decide what will be qty
            String rental = (l.al.Price_Type__c == 'Recurring') ? 'true' : 'false';
            String key = (string)l.itemID + l.al.Product__r.Used__c + rental;
            if (itemUsedorRentalMap.containsKey(key)){
                l.serialQty = itemUsedorRentalMap.get(key).size();
            }
        }

        result.records = wrapperList;
        result.total = wrapperList.size();
        return result;

    }

    @RemoteAction
    global static DataSourceResult createSalesOrders (List<LineWrapper> lws, String agreementId, String billTo, String soldTo, String shipTo, String requiredDate) {

        Set<Id> salesOrderIds = new Set<Id>();
        List<Sales_Order_Line__c> salesOrderLinesForDML = new List<Sales_Order_Line__c>();

        system.debug(LoggingLevel.Info, 'Inside remote action -->' + lws);

        DataSourceResult result = new DataSourceResult();
        Savepoint sp = Database.setSavepoint();
        try{
            boolean hasLines = false;
            boolean isSerialEnabled = false;
            boolean createAndRelease = false;
            Map<Sales_Order_Line__c, List<Serial__c>> soltoSerials = new Map<Sales_Order_Line__c, List<Serial__c>>();
            //Agreement__c a = (Agreement__c)con.getRecord();
            Set<String> fields = new Set<String>{'Company__c', 'Customer__c', 'Customer__r.RecordType.DeveloperName', 'Status__c', 'Currency__c',//Ship To
                                       'Customer__r.Parent_Customer__c', 'Customer__r.Parent_Customer__r.Name', //Sold To
                                       'Customer__r.Parent_Customer__r.Parent_Customer__c', 'Customer__r.Parent_Customer__r.Parent_Customer__r.Name', //Bill To
                                       'Payment_Terms__c','Bill_To__c','Ship_To__c','Sold_To__c',
                                       'Customer__r.Top_Parent_Customer__c', 'Customer__r.Top_Parent_Customer__r.Name','Company__r.Serial_Control__c','Billing_UOM__c','Recurrence_Start_Date__c'};

            SOQLUtil soql = new SOQLUtil('Agreement__c', TRUE);
            soql.addFields(fields);
            soql.setWhereClause(' Id = \'' + agreementId +'\'');
            Agreement__c agreement = Database.Query(soql.getQuery());
            if(agreement.status__c != 'Approved'){
                Database.rollback(sp);
                result.success = false;
                String message = 'This agreement must be approved to release orders.';
                result.addMessage(message, ApexPages.Severity.ERROR);
                return result;
            }
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Top_Parent_Customer__c'
			});
			Id custId = agreement.Customer__c;
			soql.setWhereClause('ID = :custId');
			Customer__c cust = Database.query(soql.getQuery());

            List<LineWrapper> lws_final = new List<LineWrapper>();
            Map<id, SKID__c> serialIDtoSKID = new Map<id, SKID__c>();
            Set<id> serialIds = new Set<id>();


            if (agreement.Company__r.Serial_Control__c != null){
                isSerialEnabled = true;
            }

            if (isSerialEnabled){
                for (LineWrapper lw: lws){
                    if (lw.qty >= 1 && lw.isSerialProduct == true && lw.al.Price_Type__c == 'Sales' && lw.serialList.size() > 0){
                        for (integer i=0; i<lw.serialList.size(); i++){
                            serialIds.add(lw.serialList[i].id);
                        }
                        lws_final.add(lw);
                    }
                    else  if (lw.qty >= 1 && lw.isSerialProduct == true && lw.al.Price_Type__c == 'Recurring'){
                        for (integer i=0; i<lw.qty; i++){
                            LineWrapper l = new LineWrapper();
                            List<Serial__c> cl = new List<Serial__c>();

                            l.al = lw.al;
                            l.qty = 1;
                            l.requiredDate = system.today();
                            l.fulfillmentStartDate = lw.fulfillmentStartDate;
                            l.selected = lw.selected;
                            l.used = lw.used;
                            l.sol = lw.sol;
                            l.isCreateRelease = lw.isCreateRelease;
                            if (lw.serialList.size() > 0){
                                lw.serialList[i].Temporary_Value_Holder__c = 'Allocate';
                                cl.add(lw.serialList[i]);
                                l.serialList = cl;
                                serialIds.add(lw.serialList[i].id);
                            }
                            lws_final.add(l);
                        }
                    }
                    else{
                        lws_final.add(lw);
                    }
                }
            }
            else{
                lws_final.addAll(lws);
            }

            Map<String, List<LineWrapper>> mShipToLineWrapper = new Map<String, List<LineWrapper>>();
            Map<Integer, Sales_Order_Line__c> solMap = new Map<Integer, Sales_Order_Line__c>();
            Map<Integer, List<Serial__c>> serialListMap = new Map<Integer, List<Serial__c>>();
            date rDate;
            map<id,Product__c> pIdToProduct = new map<id,Product__c>();
            set<id> prodId = new set<id>();
            for(LineWrapper lw: lws_final) {
                //prodId.add(lw.al.Product__c);
                String key = lw.al.Ship_To__c;
                rDate = (rDate == null || lw.sol.Required_Date__c > rDate) ? lw.sol.Required_Date__c : rDate;
                system.debug(LoggingLevel.INFO, 'lw.createAndRelease--'+createAndRelease);
                if (!createAndRelease){
                    system.debug(LoggingLevel.INFO, 'lw.isCreateRelease--'+lw.isCreateRelease);
                    if (lw.isCreateRelease){
                        createAndRelease = true;
                    }
                }
                if (!mShipToLineWrapper.containsKey( key ))
                    mShipToLineWrapper.put( key, new List<LineWrapper> ());
                mShipToLineWrapper.get( key ).add( lw );
            }
            for(LineWrapper lw: lws_final) {
                if(lw.selected && lw.qty != null && lw.qty != 0){
                    prodId.add(lw.al.Product__c);
                }
            }
            system.debug(LoggingLevel.Info, 'mShipToLineWrapper--'+mShipToLineWrapper);

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			soql = new SOQLUtil('Product__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Selling_UOM__c','Item__r.Fulfillment_Source__c', 'Item_Specification__c'
			});
			soql.setWhereClause('Id IN :prodId');
			List<Product__c> prod = Database.query(soql.getQuery());

            for(Product__c p:prod){
             pIdToProduct.put(p.id, p);
            }
            for(String shipToId : mShipToLineWrapper.keySet()) {
                if (shipToId != null) {
                    shipTo = shipToId;
                }

                Sales_Order__c so = new Sales_Order__c();
                so.Agreement__c = agreement.Id; //KNDY-7491
                so.Company__c = agreement.Company__c;
                so.Currency__c = agreement.Currency__c;
                so.Payment_Term__c = agreement.Payment_Terms__c;//KNDY-8247
                so.Required_Date__c = rDate;

                //KNDY-12134
                so.Billing_UOM__c = agreement.Billing_UOM__c;
                so.Recurrence_Start_Date__c = agreement.Recurrence_Start_Date__c;

                if(agreement.Customer__r.RecordType.DeveloperName == 'Ship_To') {
                    so.Ship_To__c = agreement.Customer__c;
                    so.Customer__c = agreement.Customer__r.Parent_Customer__c;
                    so.Bill_To__c = agreement.Customer__r.Parent_Customer__r.Parent_Customer__c;
                }
                else if(agreement.Customer__r.RecordType.DeveloperName == 'Sold_To') {
                    if(String.isBlank(shipTo))
                        throw new AgreementReleaseException ('Please select values for all customers');
                    so.Ship_To__c = shipTo;
                    so.Customer__c = agreement.Customer__c;
                    so.Bill_To__c = agreement.Customer__r.Parent_Customer__c;
                
                }
                else if(agreement.Customer__r.RecordType.DeveloperName == 'Bill_To') {
                    if(String.isBlank(shipTo) || String.isBlank(soldTo))
                        throw new AgreementReleaseException ('Please select values for all customers');
                    so.Ship_To__c = shipTo;
                    so.Customer__c = soldTo;
                    so.Bill_To__c = agreement.Customer__c;
                
                }
                else {
                    if(String.isBlank(shipTo) || String.isBlank(soldTo) || String.isBlank(billTo))
                        throw new AgreementReleaseException ('Please select values for all customers');
                    so.Ship_To__c = shipTo;
                    so.Customer__c = soldTo;
                    so.Bill_To__c = billTo;

                }
                DML.insertAsUser(so);
                system.debug(LoggingLevel.INFO, 'createAndRelease--'+createAndRelease);
                salesOrderIds.add(so.Id);
                set<Id> itemIds = new set<Id>();
                    for(LineWrapper lw : mShipToLineWrapper.get(shipToId)){
                    if(lw.selected && lw.qty != null && lw.qty != 0){
                        itemIds.add(lw.al.product__r.Item__c);
                    }
                }
                //requery sales order to get ship from location KNDY-7576
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil

				soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','Ship_From_Location__c', 'Ship_From_Location__r.Facility__c', 'Ship_From_Location__r.Facility__r.FAcility_Identifier__c'
				});
				Id soId = so.Id;
				soql.setWhereClause('id = :soId');
				Sales_Order__c sOrder = Database.query(soql.getQuery());

				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				soql = new SOQLUtil('Item_Specification__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','Item__c'
				});
				soql.setWhereClause('Item__c IN :itemIds AND Configurable__c = true');
				soql.setOrderByClause('Start_Date2__c desc');
				SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Components__r');
				childRel.addFields(new set<string>{
					'Id','Name','Component_Item__c','Component_Item__r.Name','Quantity_per_Assembly__c'
				});
				childRel.setWhereClause('Configuration_Type__c = \'Mandatory\'');
				soql.addChildRelationship(childRel);
				List<Item_Specification__c> itemSpecs = Database.query(soql.getQuery());

                Map<Id, Item_Specification__c> mItemSpecs = new Map<Id, Item_Specification__c>();
                for(Item_Specification__c is : itemSpecs){
                    mItemSpecs.put(is.Item__c, is);
                    for(Component__c c : is.Components__r){
                        itemIds.add(c.Component_Item__c);
                    }
                }

                //TODO: This will break with multiple products for a single item
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				soql = new SOQLUtil('Product__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','Item__c'
				});
				soql.setWhereClause('Item__c IN :itemIds');
				List<Product__c> products = Database.query(soql.getQuery());

                Map<Id, Product__c> mProducts = new Map<Id, Product__c>();
                for(Product__c p : products){
                    mProducts.put(p.Item__c, p);
                }

                integer tmp = 1;
                for(LineWrapper lw : mShipToLineWrapper.get(shipToId)){
                    if(lw.selected && lw.qty != null && lw.qty != 0){
                        hasLines = true;
                        Sales_Order_Line__c iSOL = new Sales_Order_Line__c();
                        iSOL.Company__c = agreement.Company__c;
                        iSOL.Required_Date__c = lw.sol.Required_Date__c;
                        iSOL.Sales_Order__c = sOrder.Id;
                        iSOL.Ship_From_Location__c = sOrder.Ship_From_Location__c;//KNDY-7576
                        iSOL.Ship_From_Facility__c = sOrder.Ship_From_Location__r.Facility__c;
                        iSOL.Ship_From_Facility__r = sOrder.Ship_From_Location__r.Facility__r;
                        iSOL.Customer_Site__c = lw.al.Customer_Site__c;
                        iSOL.Product__c = lw.al.Product__c;
                        iSOL.Product_Reference__c = lw.al.Product_Reference__c;
                        iSOL.Price_Type__c = lw.al.Price_Type__c;
                        iSOL.Pricing_UOM__c = lw.al.Pricing_UOM__c;
                        iSOL.Description__c = lw.al.Description__c;
                        iSOL.Pricebook__c = lw.al.Pricebook__c;
                        if(lw.al.Rate_Basis__c == 'Flat'){
                        	//TODO: This is seriously hard wired right now, need to provide alternatives to flat orders from agreements
                        	if(lw.qty != lw.al.Sales_Agreement_Quantity__c){
                        		throw new AgreementReleaseException('Quantity Ordered for Flat Rate Basis must be Agreement Quantity');
                        	}else{
                        		iSOL.Quantity_Ordered__c = lw.al.Sales_Agreement_Quantity__c;
                        	}
                        }else{
                        	iSOL.Quantity_Ordered__c = lw.qty;
                        }
                        iSOL.Unit_Price__c = lw.al.agreement_price__c;
                        iSOL.List_Price__c = lw.al.List_Price__c;
                        iSOL.Agreement_Line__c = lw.al.Id;
                        iSOL.Billing_Category__c = lw.al.Billing_Category__c;
                        iSOL.Fulfillment_Category__c = lw.al.Fulfillment_Category__c;
                        iSOL.Start_Date__c = lw.al.Start_Date__c;
                        if(lw.al.Price_Type__c == 'Sales'){
                           iSOL.End_Date__c = lw.al.End_Date__c;
                        }
                        iSOL.Occurrence__c = lw.al.Occurrence__c;
                        iSOL.Rate_Basis__c = lw.al.Rate_Basis__c;
                        iSOL.Agreement__c = lw.al.Agreement__c;
                        iSOL.Fulfillment_Start_Date__c = lw.fulfillmentStartDate != null ? lw.fulfillmentStartDate : system.today();
                        if (lw.al.Price_Type__c == 'Recurring'){
                            iSOL.Rental__c = true;
                        }
                        iSOL.Used__c = lw.used;
                        if (pIdToProduct.get(lw.al.Product__c).Item__r.Fulfillment_Source__c != null){
                            iSOL.Fulfillment_Source__c = pIdToProduct.get(lw.al.Product__c).Item__r.Fulfillment_Source__c;
                        }

                        if (pIdToProduct.get(lw.al.Product__c).Item_Specification__c != null){ //set the item spec if the product has an item spec on it
                            iSOL.Item_Specification__c = pIdToProduct.get(lw.al.Product__c).Item_Specification__c; 
                        }

                        //integer leadTime = lw.al.product__r.item__r.lead_time__c == null ? 7 : integer.valueOf(lw.al.product__r.item__r.lead_time__c);
                        //iSOL.required_date__c = system.today().addDays(leadTime);
                        //iSOL.Site__c = lw.sol.Site__c;
                       // if(pIdToProduct.get(lw.al.Product__c).Item__r.Fulfillment_Source__c != null){
                       // iSOL.Fulfillment_Source__c = pIdToProduct.get(lw.al.Product__c).Item__r.Fulfillment_Source__c;
                       // }
                        if(pIdToProduct.get(lw.al.Product__c).Selling_UOM__c != null){
                          iSOL.selling_uom__c = pIdToProduct.get(lw.al.Product__c).Selling_UOM__c;//lw.al.product__r.Selling_UOM__c
                        }
                        salesOrderLinesForDML.add(iSOL);

                        serialListMap.put(tmp, lw.serialList);
                        solMap.put(tmp, iSOL);
                        tmp++;
                        //system.debug('salesOrderLinesForDML'+salesOrderLinesForDML);
                        if(lw.al.product__r.product_type__c == 'Configurable'){

                            Item_Specification__c is = mItemSpecs.get(lw.al.product__r.Item__c);
                            /* if(is == null){
                                throw new AgreementReleaseException('No Item Specification was found for ' + lw.al.product__r.name);
                            } */

                                if (is != null) {
                                iSOL.Item_Specification__c = is.Id;

                                for(Component__c c : is.Components__r){

                                    Product__c iProd = mProducts.get(c.Component_Item__c);
                                    if(iProd == null){
                                        throw new AgreementReleaseException('No product was found for component item ' + c.name + ' (' + c.Component_Item__r.Name + ')' + ' ' + 'component item: ' + c.component_item__c + ' ' + 'mProducts: ' + mProducts);
                                    }
                                    Sales_Order_Line__c iSOLC = new Sales_Order_Line__c();
                                    iSOLC.Company__c = agreement.Company__c;
                                    iSOLC.Sales_Order__c = sOrder.Id;
                                    iSOLC.Required_Date__c = lw.sol.Required_Date__c;
                                    iSOLC.Ship_From_Location__c = sOrder.Ship_From_Location__c;//KNDY-7576
                                    iSOLC.Product__c = iProd.Id;
                                    iSOLC.Quantity_Ordered__c = lw.qty * c.Quantity_per_Assembly__c;
                                    iSOLC.selling_uom__c = lw.al.product__r.selling_uom__c;
                                    //iSOLC.required_date__c = iSOL.required_date__c;
                                    iSOLC.Unit_Price__c = 0;
                                    iSOLC.Component__c = c.Id;
                                    iSOLC.Item_Specification__c = is.Id;
                                    iSOLC.Agreement_Line__c = lw.al.Id;
                                    iSOLC.Fulfillment_Source__c = c.Component_Item__r.Fulfillment_Source__c;
                                    iSOLC.Pricebook__c = lw.al.Pricebook__c;
                                    if(lw.al.Occurrence__c == 'Monthly' || lw.al.Occurrence__c == 'Quarterly' || lw.al.Occurrence__c == 'Annually'){
			                        	iSOLC.Start_Date__c = lw.al.Start_Date__c;
			                        	iSOLC.End_Date__c = lw.al.End_Date__c;
			                        }
			                        iSOLC.Occurrence__c = lw.al.Occurrence__c;
			                        iSOLC.Rate_Basis__c = lw.al.Rate_Basis__c;
                                    iSOLC.Fulfillment_Start_Date__c = lw.fulfillmentStartDate != null ? lw.fulfillmentStartDate : system.today();
                                    if (lw.al.Price_Type__c == 'Recurring'){
                                        iSOLC.Rental__c = true;
                                    }
                                    iSOLC.Used__c = lw.used;
                                    //iSOLC.Site__c = lw.sol.Site__c;
                                    salesOrderLinesForDML.add(iSOLC);
                                    serialListMap.put(tmp, lw.serialList);
                                    solMap.put(tmp, iSOLC);
                                    tmp++;
                                }
                            }
                        }

                    }
                }

                if(!hasLines){
                    Database.rollback(sp);
                    result.success = false;
                    String message = 'There are no selected lines with quantity specified.';
                    result.addMessage(message, ApexPages.Severity.ERROR);
                    return result;
                }

            }

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','name'
			});
			soql.setWhereClause('Id IN :salesOrderIds');
			List<Sales_Order__c> newSalesOrders = Database.query(soql.getQuery());

            SalesOrderLineService.mapLineDependencies(salesOrderIds);

            result.message = '';

            DML.insertAsUser(salesOrderLinesForDML);
            
            for(Sales_Order__c n : newSalesOrders) {
                result.addMessage('<a href="/'+ n.Id+'">' + n.Name + '</a>' + ' was created successfully', ApexPages.Severity.CONFIRM);
            }
            

            set<id> soids = new set<id>();
            for (Sales_Order__c so : newSalesOrders){
                soids.add(so.id);
            }

            set<id> solids = new set<id>();
            for (Sales_Order_Line__c sol : salesOrderLinesForDML){
                solids.add(sol.id);
            }

            if (createAndRelease){
                AgreementService.autoReleaseAllocateSOs(soids, solids, serialIds);
            }

        }catch(Exception e){
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e, ApexPages.Severity.ERROR);
        }
        SalesOrderLineService.getParentSalesOrderLine(salesOrderIds);
        return result;

    }

    global class LineWrapper{

        public Agreement_Line__c al {get;set;}
        public Sales_Order_Line__c sol {get;set;}
        public Sales_Order__c so {get;set;}
        public boolean selected {get;set;}
        public integer qty {get;set;}
        public Date requiredDate {get;set;}
        public double serialQty {get;set;}
        public id itemID {get;set;}
        public List<Serial__c> serialList {get;set;}
        public boolean isSerialProduct {get;set;}
        public Date fulfillmentStartDate {get;set;}
        public boolean used {get; set;}
        public boolean isCreateRelease {get; set;}

        global LineWrapper(Agreement_Line__c al){
            this.al = al;
            this.sol = new Sales_Order_Line__c();
            this.so = new Sales_Order__c();
            so.Required_Date__c = system.today();
            this.selected = true;
            this.qty = 0;
            this.itemID = al.Product__r.Item__c;
            this.serialList = new List<Serial__c>();
            this.fulfillmentStartDate = system.today();
            this.used = al.Product__r.Used__c;
        }

        global LineWrapper() {

        }

    }

}