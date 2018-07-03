global with sharing class AgreementExchangeExt extends BaseController{

	private static SchemaUtil util = SchemaUtil.getInstance();
    public string NamespaceUU { get { return KSE.NamespaceUU; } }
    public GridRelatedListController.GridRelatedListConfig FulfillmentConfig {get; set;}
    public String fulfillmentLinesFieldList = null;
    public Apexpages.Standardcontroller con {get;set;}
    public id agreementId {get;set;}
    //Serial Search UI related attributes
    public String SerialsFieldList = null;
    public GridRelatedListController.GridRelatedListConfig SerialsConfig {get; set;}
    public string serialAttributes { get; set;}

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

    public String getfulfillmentLinesConfigJson() {
        String configStr = JSON.serialize(this.FulfillmentConfig);
        
        return configStr;
    }
    public string getfulfillmentLinesFieldList() {
        if (fulfillmentLinesFieldList == null && FulfillmentConfig != null) {
            
            // get the contract lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(FulfillmentConfig.objectName, FulfillmentConfig.fieldset);
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                system.debug('fieldInfoList--'+fieldInfoList[i]);
                String fieldName = 'flmt.'+fieldInfoList[i].field;
                fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = false;
            }
            
            FieldInfo fieldInfoItem_Serial = new FieldInfo('serial_existing', 'Existing Serial', 'string', false);
            fieldInfoList.add(fieldInfoItem_Serial);
            
            FieldInfo fieldInfoItem_qty = new FieldInfo('serialQty', 'Available Quantity', 'double', false);
            fieldInfoItem_qty.editable = false;
            fieldInfoList.add(fieldInfoItem_qty);

            FieldInfo fieldInfoItem_Serial1 = new FieldInfo('serial_exchange', 'Serial to exchange', 'string', false);
            fieldInfoList.add(fieldInfoItem_Serial1);

            List<FieldInfo> fieldInfo_SKID = new List<FieldInfo>();
            List<String> fields = new List<String>();
            fields.add('Location__c');
            fields.add('Bin__c');
            fieldInfo_SKID = FieldInfo.fetchJsonFieldInfos('SKID__c',fields);
            for(Integer i = 0; i < fieldInfo_SKID.size(); i++){
                String fieldName = 'skid.'+fieldInfo_SKID[i].field;
                fieldInfo_SKID[i].field = fieldName;
            }
            fieldInfoList.addAll(fieldInfo_SKID);

            fulfillmentLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return fulfillmentLinesFieldList;
    }

    public AgreementExchangeExt(ApexPages.StandardController controller) {

    	this.con = controller;
        
        if(this.con == null){
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'No agreement is specified.'));
        }else{
            if(!test.isRunningTest()){
                this.con.addFields(new list<String>{'Customer__c', 'Customer__r.RecordType.DeveloperName', 'Status__c', 'Currency__c',//Ship To
                        'Customer__r.Parent_Customer__c', 'Customer__r.Parent_Customer__r.Name', //Sold To
                        'Customer__r.Parent_Customer__r.Parent_Customer__c', 'Customer__r.Parent_Customer__r.Parent_Customer__r.Name', //Bill To
                        'Payment_Terms__c', 'Bill_To__c', 'Sold_To__c', 'Ship_To__c',
                        'Company__c', 'Company__r.Serial_Control__c', //company's serial attribute
                        'Customer__r.Top_Parent_Customer__c', 'Customer__r.Top_Parent_Customer__r.Name'});
            }
            Agreement__c a  = (Agreement__c) con.getRecord();
            
            agreementId = a.id;
        
        }

        //Fulfillment Grid config
        FulfillmentConfig = new GridRelatedListController.GridRelatedListConfig();
        FulfillmentConfig.uniqueId = 'FulfillmentGrid';
        FulfillmentConfig.title = 'Fulfillments';
        FulfillmentConfig.objectName = 'Fulfillment__c';
        FulfillmentConfig.fieldset = 'Return';
        FulfillmentConfig.buttons = 'columnmenu, search';
        FulfillmentConfig.alwaysUseFullDateTimeFormat = false;

        SerialsConfig = new GridRelatedListController.GridRelatedListConfig();
        SerialsConfig.uniqueId = 'SerialsGrid';
        SerialsConfig.objectName = 'Serial__c';
        SerialsConfig.buttons = 'columnmenu, search';


    }

    @RemoteAction
    global static JsonResult getSerials(ID itemID, boolean prodUsed) {

        JsonResult result = new JsonResult();

        List<String> filterCriteria = new List<String>();
        filterCriteria.add('Allow_Reentry__c = false');
        filterCriteria.add('SKID__c != null');
        filterCriteria.add('Allocated_SKID__c = null');
        filterCriteria.add('SKID__r.Type__c != \'Install Base\'');
        filterCriteria.add('SKID__r.Shipment_Line__c = null');
        filterCriteria.add('Item__c = :itemID');

        //KNDY-12482 - Logic to check if the serial returned should be rental/sale and if it is used or new
        if (prodUsed == true){ //this is used product for rental, so bring all serials on skid where Rental = true and Used = true
            filterCriteria.add('SKID__r.Used__c = true');
            filterCriteria.add('SKID__r.Rental__c = true');
        }
        else if(prodUsed == false){ //this is selling product for rental, so bring all serials on skid where Rental = true and Used = false
            filterCriteria.add('SKID__r.Used__c = false');
            filterCriteria.add('SKID__r.Rental__c = true');
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
    global static JsonResult getFulfillments(String id) {
        
        JsonResult result = new JsonResult();
        
        List<Fulfillment__c> Fulfillments = new List<Fulfillment__c>();
        
        List<String> filterCriteria = new List<String>();
        filterCriteria.add('End_Date__c = null');
        filterCriteria.add('Sales_Order_Line__r.Agreement__c = :id');
        filterCriteria.add('Type__c = \'Rental\'');
        filterCriteria.add('Price_Type__c = \'Recurring\'');
        filterCriteria.add('Invoice_Ready__c = true');
        
        String whereClause = '';
        
        if (filterCriteria.size() > 0) {
            whereClause += String.join(filterCriteria, ' AND ');
        }
        
        List<String> fieldstoQuery = util.getFieldsFromFieldSetString('Fulfillment__c', 'Return');
        Set<String> fieldSettouseinQuery = new Set<String>(fieldstoQuery);
        datetime oDate = system.now();
        SOQLUtil soql = new SOQLUtil('Fulfillment__c', TRUE);
        soql.addFields(new Set<String>{'Id', 'Name', 'Company__c', 'SKID__c', 'Product__r.Item__c', 'Product__r.Item__r.Item_Attribute__c', 'Product__r.Used__c',
                'Product__r.Item__r.Item_Attribute__r.Serial_Number__c', 'Rate_Basis__c' });
        soql.addFields(util.getAllCustomFieldsFromObject('', 'Fulfillment__c'));
        soql.addFields(fieldSettouseinQuery);
        soql.setWhereClause(whereClause);
        soql.setOrderByClause('LastModifiedDate');
        
        Fulfillments = database.query(soql.getQuery());
        If (Fulfillments.size() == 0){ //KNDY-12781
            result.success = false;
            result.total = 0;
        }else{
            //get the serials for each line
            //1. get the sales order line ids
            Set<id> solIDS = new Set<id>();
            Map<id, string> solIDtoSerial = new Map<id, string>();
            for (Fulfillment__c f : Fulfillments){
                solIDS.add(f.Sales_Order_Line__c);
            }
            
            //2. Get all serials and its corresponding SKID from the sales order line IDs
            soql = new SOQLUtil('Serial__c', TRUE);
            soql.addFields(new Set<String>{'Id', 'Name'});
            soql.addFields(util.getAllCustomFieldsFromObject('', 'Serial__c'));
            soql.addFields(util.getAllCustomFieldsFromObject('SKID__r.','SKID__c'));
            soql.addFields(util.getAllCustomFieldsFromObject('SKID__r.Item__r.','Item__c'));  
            soql.setWhereClause('SKID__r.Sales_Order_Line__c in : solIDS');

            List<Serial__c> serialListSOL = database.query(soql.getQuery());

            Map<id, Serial__c> soltoSerial = new Map<id, Serial__c>();
            for (Serial__c serial : serialListSOL){
                soltoSerial.put(serial.SKID__r.Sales_Order_Line__c, serial);
            }
            
            Set<id> itemIDstogetSerials = new Set<id>();
            List<fulfillmentWrapper> flmtWrapper = new List<fulfillmentWrapper>();
            for (Fulfillment__c f : Fulfillments){
                fulfillmentWrapper fw = new fulfillmentWrapper();
                //fw.sol = f.Sales_Order_Line__r;
                fw.flmt = f;
                itemIDstogetSerials.add(f.Product__r.Item__c);
                fw.returnQty = 0;
                
                if (soltoSerial.containsKey(f.Sales_Order_Line__c)){
                    fw.serial_existing = soltoSerial.get(f.Sales_Order_Line__c).Name;
                    fw.serialexisting = soltoSerial.get(f.Sales_Order_Line__c);
                    fw.skidexisting = soltoSerial.get(f.Sales_Order_Line__c).SKID__r;
                    fw.skidexisting.Item__r = soltoSerial.get(f.Sales_Order_Line__c).SKID__r.Item__r;
                    fw.serial_exchange = '';
                }
                
                flmtWrapper.add(fw);
            }

            SOQLUtil soql_serial = new SOQLUtil('Serial__c', TRUE);
            soql_serial.addFields(new Set<String> {'Id', 'name', 'SKID__c', 'Allow_Reentry__c', 'Item__c', 'SKID__r.Used__c', 'SKID__r.Rental__c', 'SKID__r.Receipt_Line__c','SKID__r.Item__r.Packaging_UOM__c'});
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

            for (fulfillmentWrapper f : flmtWrapper){
                String key = (string)f.flmt.Product__r.Item__c + f.flmt.Product__r.Used__c + 'true';
                if (itemUsedorRentalMap.containsKey(key)){
                    f.serialQty = itemUsedorRentalMap.get(key).size();
                }
            }
            
            result.records = flmtWrapper;
            result.total = flmtWrapper.size();
        }
        return result;
    }
    
    @RemoteAction
    global static JsonResult exchangeSerials (List<fulfillmentWrapper> flmtwrappers) {
        
        JsonResult result = new JsonResult();
        
        //Check if location is bin tracked and throw error if Bin is not provided for a bin tracked location
        Set<id> LocationIDs = new Set<id>();
        for (fulfillmentWrapper f : flmtwrappers){
            LocationIDs.add(f.LocationID);
        }

        SOQLUtil soql_location = new SOQLUtil('Location__c', TRUE);
        soql_location.addFields(new Set<String> {'Id', 'name', 'Bin_Tracked__c'});
            
        List<Location__c> LocList = database.query(soql_location.getQuery());
        Map<ID, Location__c> LocMap = new Map<ID, Location__c>(LocList);

        String Locations = '';
        for (fulfillmentWrapper f : flmtwrappers){
            if (LocMap.containsKey(f.LocationID)){
                //if location is bin tracked and bin is not entered on the UI, then throw and error
                if (LocMap.get(f.LocationID).Bin_Tracked__c == True && f.BinID == null){
                    Locations = Locations + LocMap.get(f.LocationID).Name;
                }
            }
        }

        if (Locations.length() >0){
            result.success = false;
            result.addMessage('Bin is required for Bin Tracked Locations. Please provide bin for : '+Locations,  ApexPages.Severity.ERROR);
            return result;
        }

        
        Savepoint sp = Database.setSavepoint();

        try{
            //Invoke the transfer method in InventoryChangeService
            Map<String,String> config = new Map<String, String>{'IC_TYPE' => 'Rental Exchange'};
            List<SkidService3.SerialWrapper> serialwrapperlist = new List<SkidService3.SerialWrapper>();

            //get list of attributes
            List<String> attributesList = SkidService3.attributesForPutaway();
            attributesList.add('Type__c');

            for (fulfillmentWrapper f : flmtwrappers){
                SKID__c installsk = f.skidexisting;
                SKID__c invsk = f.skidexchange;

                //Loop through attributes and set the install base SKID attribute to inventory skid attribute
                for (String attribute : attributesList){
                    if (invsk.get(attribute) != null) {
                        installsk.put(attribute, invsk.get(attribute));
                    }
                    //additionally if the fulfillment wrapper has the location and bin on it, set that to the install base skid
                    if (f.LocationID != null){
                        installsk.Location__c = f.LocationID;
                    }
                    if (f.BinID != null){
                        installsk.Bin__c = f.BinID;
                    }
                }

                invsk.Sales_Order_Line__c =installsk.Sales_Order_Line__c;
                invsk.Customer__c = installsk.Customer__c;
                invsk.Type__c = SkidService3.SKID_TYPE_INSTALLBASE;
                invSk.Quantity__c = 1;
                invSk.Rental__c = true;
                invsk.item__r.Packaging_UOM__c = installsk.item__r.Packaging_UOM__c;
                //Now SOLine and Customer info will wiped off from Install SKid 
                installsk.Sales_Order_Line__c = null;
                installsk.Customer__c = null;

                SkidService3.SerialWrapper sw1 = new SkidService3.SerialWrapper(installsk,new List<Serial__c>{f.serialexisting});
                for(serial__c serial : sw1.serialList){
                  serial.allow_reentry__c = false ;  
                }
                sw1.itType = 'Rental Exchange In';
                SkidService3.SerialWrapper sw2 = new SkidService3.SerialWrapper(invsk,new List<Serial__c>{f.serialexchange});
                sw2.itType = 'Rental Exchange Out';
                serialwrapperlist.add(sw1);
                serialwrapperlist.add(sw2);
            }
            InventoryChangeService.transfer(serialwrapperlist,null,config);
            result.addMessage('Rental exchange process has been completed successfully', ApexPages.Severity.CONFIRM);
        }
        catch(Exception e){
            Database.rollback(sp);
            result.success = false;
            result.addMessage('Rental exchange process failed: ' + e.getMessage() , ApexPages.Severity.ERROR);
            system.debug(LoggingLevel.INFO, e.getStackTraceString());
        }
        return result;
    }
    
    global class fulfillmentWrapper {
        
        public Fulfillment__c flmt {get;set;}
        public double returnQty {get;set;}
        public string serial_existing {get;set;}
        public string serial_exchange {get;set;}
        public double serialQty {get;set;}
        public Serial__c serialexisting {get;set;}
        public SKID__c skidexisting {get;set;}
        public Serial__c serialexchange {get;set;}
        public SKID__c skidexchange {get;set;}
        public id LocationID {get;set;}
        public id BinID {get;set;}
        
        global fulfillmentWrapper() {
        
        }
    }


}