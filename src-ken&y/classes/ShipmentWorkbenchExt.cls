public with sharing class ShipmentWorkbenchExt extends BaseController {
    public String namespace { get; set; } { namespace = KSE.namespaceUU; }
    public String atReceipt { get; set; } { atReceipt = SkidService3.AT_RECEIPT; }
    public String shipmentJson { get; set; }
    public String mode { get; set; }
    public String defaultFacility { get; set; }
    public string helpUrl { get; set; } { helpUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/HelpShipmentWorkbench'; }
    public String defaultGridPageSize {
                  get {
                       if(defaultGridPageSize==null){
                           configuration__c defaultGridPageSizeConfig = configuration__c.getValues('DefaultGridPageSize');
                           if(defaultGridPageSizeConfig!=null){
                               defaultGridPageSize = defaultGridPageSizeConfig.value__c;
                           }
                       }
                       return defaultGridPageSize;
                  }
                  private set;
    }
    
    private static SchemaUtil util = SchemaUtil.getInstance();
    
    public ShipmentWorkbenchExt() {
        if (ApexPages.currentPage() != null && ApexPages.currentPage().getParameters().containsKey('shipment') && ApexPages.currentPage().getParameters().containsKey('mode')) {
            Id shipmentId = ApexPages.currentPage().getParameters().get('shipment');
            SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
            shipmentQuery.addFields(new Set<String>{ 'Id', 'Name', 'Ship_From_Facility__c', 'Ship_From_Facility__r.Company__c', 'Ship_From_Facility__r.Company__r.Auto_Plan_Pick__c' });
            shipmentQuery.setWhereClause('Id = :shipmentId');
            Shipment__c shipment = Database.query(shipmentQuery.getQuery());
            shipmentJson = JSON.serialize(shipment);
            defaultFacility = JSON.serialize(shipment.Ship_From_Facility__r);
            mode = ApexPages.currentPage().getParameters().get('mode').toLowerCase();
        } else {
            User_Preference__c up = UserPreference.getInstance().Preference;
            if (up.Default_Facility__c != null) defaultFacility = JSON.serialize(new Facility__c(
                Id = up.Default_Facility__c,
                Name = up.Default_Facility__r.Name,
                Company__c = up.Default_Company__c,
                Company__r = new Company__c(
                    Id = up.Default_Company__c,
                    Name = up.Default_Company__r.Name,
                    Auto_Plan_Pick__c = up.Default_Company__r.Auto_Plan_Pick__c
                )
            ));
        }
    }

    @RemoteAction
    public static JsonResult save(List<LineWrapper> shlWrappers, String mode) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try {
            Id companyId;
            Map<Id, Item__c> items = new Map<Id, Item__c>();
            String shlFilter = '(';
            for (Integer i = 0; i < shlWrappers.size(); i++) {
                Shipment_Line__c shl = (Shipment_Line__c)shlWrappers[i].line;

                if (mode == 'allocate') {
                    companyId = shl.Company__c;
                    items.put(shl.Item__c, shl.Item__r);
                }

                if (i != 0) shlFilter += ',';
                shlFilter += '\'' + shlWrappers[i].line.Id + '\'';
            }
            shlFilter += ')';

            List<String> attributes;
            if (mode == 'allocate') SkidService3.setAllocAttributes(companyId, items);
            else attributes = mode != 'allocate' ? (mode == 'planpick' ? SkidService3.planAttributes : SkidService3.attributes) : null;

            Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(getShipmentLines(new Map<String, Object>{ 'Id' => shlFilter }, mode));
            Map<Id, List<LineWrapper>> requeriedSkids = getInventory(shipmentLines.values(), mode);

            for (LineWrapper wrapper:shlWrappers) {
                Shipment_Line__c shl = (Shipment_Line__c)wrapper.line;

                if (shipmentLines.containsKey(shl.Id) == false) throw new CustomException(shl.Name + ': Shipment line is not available');

                shl = shipmentLines.get(shl.Id);
                wrapper.header = shl.Shipment__r;
                wrapper.line = shl;

                if (requeriedSkids.containsKey(shl.Id) == false) throw new CustomException(shl.Name + ': Inventory could not be found');

                List<String> attrs = mode == 'allocate' ? SkidService3.allocAttributes.get(shl.Item__c) : attributes;

                Map<List<String>, SkidService3.SerialWrapper> requeriedSkidMap = new Map<List<String>, SkidService3.SerialWrapper>();
                for (LineWrapper skidWrapper:requeriedSkids.get(shl.Id)) {
                    for (SkidService3.SerialWrapper sw:skidWrapper.serialWrappers) {
                        List<String> skidKey = SkidService3.generateKey(sw.skid, attrs);
                        if (mode == 'pick') skidKey.add(sw.skid.Temporary_Value_Holder1__c != null ? '' + ((Bin__c)JSON.deserialize(sw.skid.Temporary_Value_Holder1__c, Bin__c.Class)).Id : 'null');
                        requeriedSkidMap.put(skidKey, sw);
                    }
                }

                List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    List<String> skidKey;
                    if (sw.temporaryValueHolder != null) {
                        SKID__c skidClone = sw.skid.clone(false, true);

                        List<String> originalAttrs = sw.temporaryValueHolder.split('\\|');
                        skidClone.Location__c = originalAttrs[0];
                        skidClone.Bin__c = originalAttrs[1] != 'null' ? originalAttrs[1] : null;

                        skidKey = SkidService3.generateKey(skidClone, attrs);
                        skidKey.add(originalAttrs[2]);
                    } else {
                        skidKey = SkidService3.generateKey(sw.skid, attrs);
                        if (mode == 'pick') skidKey.add(sw.toskid != null ? (String)sw.toskid.Bin__c : 'null');
                    }
                    
                    if (requeriedSkidMap.containsKey(skidKey) == false) throw new CustomException(shl.Name + ': Inventory could not be found');

                    SkidService3.SerialWrapper requeriedSw = requeriedSkidMap.get(skidKey);
                    requeriedSw.skid.Quantity_to_Issue__c = sw.skid.Quantity_to_Issue__c;
                    requeriedSw.skid.Quantity_To_Return__c = sw.skid.Quantity_To_Return__c;
                    requeriedSw.skid.Input_Quantity__c = sw.skid.Input_Quantity__c;
                    requeriedSw.skid.Location__c = sw.skid.Location__c;
                    requeriedSw.skid.Location__r = sw.skid.Location__r;
                    requeriedSw.skid.Bin__c = sw.skid.Bin__c;
                    requeriedSw.skid.Bin__r = sw.skid.Bin__r;
                    requeriedSw.toskid = sw.toskid;
                    if (requeriedSw.toskid.License_Plate_Number__c == null && String.isNotBlank(requeriedSw.toskid.Temporary_LPN_Holder__c) == true) {
                        requeriedSw.toskid.License_Plate_Number__r = new LPN__c(Name = requeriedSw.toskid.Temporary_LPN_Holder__c);
                    }
                    requeriedSw.temporaryValueHolder = sw.temporaryValueHolder;
                    requeriedSw.skid.Item__r = shl.Item__r;

                    Map<Id, Serial__c> requeriedSerials = new Map<Id, Serial__c>(requeriedSkidMap.get(skidKey).serialList);

                    List<Serial__c> serials = new List<Serial__c>();
                    for (Serial__c serial:sw.serialList) {
                        if (requeriedSerials.containsKey(serial.Id) == false) throw new CustomException(shl.Name + ': Serial ' + serial.Name + ' could not be found');

                        Serial__c requeriedSerial = requeriedSerials.get(serial.Id);
                        requeriedSerial.Temporary_Value_Holder__c = serial.Temporary_Value_Holder__c;
                        serials.add(requeriedSerial);
                    }

                    requeriedSw.serialList = serials;
                    swList.add(requeriedSw);
                }

                wrapper.serialWrappers = swList;
            }

            if (mode == 'allocate') AllocationService.allocate(shlWrappers);
            else if (mode == 'planpick') ShipmentInventoryService.plan(shlWrappers);
            else ShipmentInventoryService.pick(shlWrappers);
        } catch (Exception e) {
            Database.rollback(sp);
            CustomException.addError(result, e);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult autoPick(List<Id> shlIds) {
        Savepoint sp = Database.setSavepoint();
        JsonResult result = new JsonResult();
        try {
            ShipmentInventoryService.autoPick(shlIds);
        } catch (Exception e) {
            Database.rollback(sp);
            CustomException.addError(result, 'Unable to auto-pick: ' + CustomException.getMessage(e));
        }
        return result;
    }

    public static Map<Id, List<LineWrapper>> getInventory(List<Shipment_Line__c> shipmentLines, String mode) {
        List<LineWrapper> wrappers = mode == 'allocate' ? AllocationService.getInventory(shipmentLines) : (mode == 'planpick' ? ShipmentInventoryService.getInventoryForPlan(shipmentLines) : ShipmentInventoryService.getInventoryForPick(shipmentLines));
		System.debug( logginglevel.error, '~*~ wrappers :' + wrappers );
        Map<Id, List<LineWrapper>> wrapperMap = new Map<Id, List<LineWrapper>>();
        for (LineWrapper wrapper:wrappers) {
            if (!wrapperMap.containsKey(wrapper.line.Id)) wrapperMap.put(wrapper.line.Id, new List<LineWrapper>{ wrapper });
            else wrapperMap.get(wrapper.line.Id).add(wrapper);
        }
        return wrapperMap;
    }

    public static List<Shipment_Line__c> getShipmentLines(Map<String, Object> filters, String mode) { return getShipmentLines(filters, mode, null, true,true); }
    public static List<Shipment_Line__c> getShipmentLines(String whereClause, String mode) { return getShipmentLines(null, mode, whereClause, true,true); }
    public static List<Shipment_Line__c> getShipmentLines(Map<String, Object> filters, String mode, String addlWhereClause) { return getShipmentLines(filters, mode, addlWhereClause, true,true); }
    public static List<Shipment_Line__c> getShipmentLines(Map<String, Object> filters, String mode, String addlWhereClause, Boolean includeUndo, Boolean includeBuildToOrder) {
        Boolean validate = (filters != null && filters.containsKey('Shipment__c') == true) || addlWhereClause != null;

        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        addShlFields(shlQuery, mode);

        String whereClause = 'Item__r.Non_Inventory__c = false ' +
                             'AND Shipment__r.Status__c != \'' + ShipmentService.SHIPMENT_STATUS_CONFIRMED + '\' ' +
                             'AND (Sales_Order_Line__c = null ' +
                             'OR (Sales_Order_Line__r.Fulfillment_Source__c != \'' + SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP + '\' ' ;
	    if(mode == 'allocate' && includeBuildToOrder == false){
	   		whereClause += 'AND Sales_Order_Line__r.Fulfillment_Source__c != \'Build To Order\' ';
	    }
	    whereClause += 'AND Sales_Order_Line__r.Status__c = \'' + SalesOrderLineService.SO_LINE_STATUS_OPEN + '\')) ' +
	    			   'AND (Order_Line__c = null ' +
	    			   'OR Order_Line__r.Status__c = \'' + OrderService.O_STATUS_OPEN + '\') ';
        
        //If not from shipment, exclude SHLs that will fail validations
        if (validate == false) {
            if (mode == 'allocate') {
                whereClause += 'AND (Sales_Order_Line__c = null ' +
                               'OR (Sales_Order_Line__r.Has_Exceptions__c = false ' +
                               'AND (Sales_Order__r.Credit_Hold__c = false OR Sales_Order__r.Override_Credit_Hold__c = true) ' +
                               'AND Sales_Order__r.Hold__c = false ' +
                               'AND Sales_Order__r.Released_to_3PL__c = false ' +
                               'AND Shipment__r.Customer__r.Top_Parent_Customer__r.Status__c = \'Approved\')) ' +
                               'AND Shipment__r.Has_Exceptions__c = false ';
            } else {
                whereClause += 'AND (Sales_Order_Line__c = null OR Sales_Order__r.Hold__c = false) ';
            }
        }

        if (addlWhereClause != null) {
            whereClause += addlWhereClause;
        } else if (filters != null && filters.size() > 0) {
            Map<String, FieldInfo> filterFields = new Map<String, FieldInfo>();
            for (FieldInfo fi:getFilterFields()) {
                if (fi.hidden != true) filterFields.put(fi.field, fi);
            }

            for (String filter:filters.keySet()) {
                FieldInfo fi = filterFields.get(filter);
                Object val = filters.get(filter);

                whereClause += ' AND ';

                if (fi == null) {
                    whereClause += filter + ' IN ' + val;
                } else if (fi.field == 'documentType') {
                    if (val == 'sales') whereClause += 'Sales_Order_Line__c != null';
                    else if (val == 'transfer') whereClause += 'Order_Line__c != null';
                } else if (fi.fieldtype == 'date' || fi.fieldtype == 'datetime') {
                    DateTime dt = DateTime.newInstance(Long.valueOf(String.valueOf(val)));
                    if (fi.fieldtype == 'date') {
                        whereClause += ((filter == 'fromDate' || filter == 'toDate') ? ('Sales_Order_Line__r.Required_Date__c ' + (filter == 'fromDate' ? '>= ' : '<= ')) : (filter + ' = ')) +
                                       dt.formatGmt('yyyy-MM-dd');
                    } else {
                        whereClause += filter + ' = ' + dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                    }
                } else if (fi.fieldtype == 'id' || fi.fieldtype == 'picklist' || fi.fieldtype == 'reference' || fi.fieldtype == 'string') {
                    whereClause += filter + ' = \'' + val + '\'';
                } else {
                    whereClause += filter + ' = ' + val;
                }
            }
        }

        shlQuery.setWhereClause(whereClause);
        shlQuery.setForUpdate();
        
        List<Shipment_Line__c> shipmentLines = Database.query(shlQuery.getQuery());
        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        for (Integer i = 0; i < shipmentLines.size(); i++) {
            Shipment_Line__c shl = shipmentLines[i];

            if (packagingUoms.containsKey(shl.Item__c) == false) packagingUoms.put(shl.Item__c, (List<Id>)JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.Class));
            Decimal convFactor = shl.Sales_Order_Line__c != null ? KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c,shl.Sales_Order_Line__r.Selling_UOM__c, shl.Item__r.Stocking_UOM__c, packagingUoms.get(shl.Item__c)) : 1;

            if (mode == 'allocate') {
                shl.Quantity_To_Pick__c = (shl.Quantity_To_Pick__c / convFactor).setScale(6, System.RoundingMode.HALF_UP); //Stocking to Selling
                shl.Quantity_Picked__c = (shl.Quantity_Picked__c / convFactor).setScale(6, System.RoundingMode.HALF_UP);   //Stocking to Selling

                Decimal qtyToCompare = shl.Quantity_Picked__c + shl.Quantity_Shipped__c;
                if (shl.Company__r.Auto_Plan_Pick__c == false) {
                    qtyToCompare += shl.Quantity_To_Pick__c;
                    if (includeUndo == false) qtyToCompare += shl.Quantity_Allocated__c;
                } else if (includeUndo == false) {
                    qtyToCompare += shl.Quantity_To_Pick__c;
                }

                if (shl.Quantity_Planned__c == qtyToCompare) {
                    shipmentLines.remove(i);
                    i--;
                } else {
                    if (validate == true) {
                        AllocationService.validate(new List<Shipment_Line__c>{ shl });
                    } else if (shl.Sales_Order_Line__c != null && !shl.Sales_Order__r.Override_Credit_Hold__c && !shl.Sales_Order__r.Credit_Hold__c) {
                        OTC__c otc = AllocationService.getOtc(shl);
                        if (otc != null && otc.Customer_Credit_Hold_Check_At_Allocate__c && shl.Sales_Order__r.Customer__r.Top_Parent_Customer__r.Credit_Hold__c) {
                            shipmentLines.remove(i);
                            i--;
                        }
                    }
                }
            } else {
                shl.Quantity_Planned__c = shl.Quantity_Planned__c * convFactor;     //Selling to Stocking
                shl.Quantity_Allocated__c = shl.Quantity_Allocated__c * convFactor; //Selling to Stocking
                shl.Quantity_Shipped__c = shl.Quantity_Shipped__c * convFactor;     //Selling to Stocking

                if ((mode == 'planpick' && (shl.Company__r.Auto_Plan_Pick__c == true || (shl.Quantity_Allocated__c == 0 && (includeUndo == false || shl.Quantity_To_Pick__c == 0)))) || (mode == 'pick' && shl.Quantity_To_Pick__c == 0 && (includeUndo == false || shl.Quantity_Picked__c == 0))) {
                    shipmentLines.remove(i);
                    i--;
                } else if (validate == true) {
                    ShipmentInventoryService.validateForPlanAndPick(new List<Shipment_Line__c>{ shl });
                }
            }
        }

        return shipmentLines;
    }

    @RemoteAction
    public static JsonResult getInventoryAndFields(List<Shipment_Line__c> shipmentLines, String mode) {
        JsonResult result = new JsonResult();
        try {
            result.records = getInventory(shipmentLines, mode).values();
        } catch (Exception e) {
            CustomException.addError(result, e);
        }

        return result;
    }

    @RemoteAction
    public static JsonResult getShipmentLinesAndFields(Map<String, Object> filters, String mode, Boolean includeUndo, Boolean includeBuildToOrder) {
        JsonResult result = new JsonResult();
        try {
            result.records = getShipmentLines(filters, mode, null, includeUndo,includeBuildToOrder);

            List<FieldInfo> fiList = new List<FieldInfo>{ new FieldInfo('warnings', 'Warnings', 'rowinfo') };
            fiList.addAll(FieldInfo.fetchJsonFieldInfos('Shipment_Line__c', mode, null, true));
            for (FieldInfo fi:fiList) {
                fi.required = false;
                if (mode == 'allocate' && fi.field == 'Selling_UOM__c' || ((mode == 'planpick' || mode == 'pick') && fi.field == 'Stocking_UOM__c')) fi.title = 'UOM'; 
            }
            result.additionalInfo = JSON.serialize(fiList);
        } catch (Exception e) {
            CustomException.addError(result, e);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult getShipToCustomerInfo(String ShipTOCustomerId) {
        JsonResult result = new JsonResult();
        try {
            result.records = new List<Object>();
            SOQLUtil customerQuery = new SOQLUtil('customer__c');
            customerQuery.addFields(new Set<String>{ 'Id', 'Name', 'Parent_Customer__c'});
            customerQuery.setWhereClause('Id = :ShipTOCustomerId');
            //Customer__c shipToCustomer = [select id,name,Parent_Customer__c from customer__c where Id=:ShipTOCustomerId];
            Customer__c shipToCustomer = (Customer__c)Database.query(customerQuery.getQuery());
            result.records.add((Object)shipToCustomer);

        } catch (Exception e) {
            CustomException.addError(result, e);
        }
        return result;
    }

    @RemoteAction
    public static Boolean hasAutoPlanPick(Id facilityId) {
        SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
        facilityQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Company__r.Auto_Plan_Pick__c' });
        facilityQuery.setWhereClause('Id = :facilityId');
        Facility__c facility = Database.query(facilityQuery.getQuery());
        return facility.Company__r.Auto_Plan_Pick__c;
    }
    
    public static void addShlFields(SOQLUtil shlQuery, String mode) {
        Set<String> soLineFields = util.getAllCustomFieldsFromObject(null, 'Sales_Order_Line__c');
        
        shlQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Facility__c', 'Item__c', 'Location__c', 'Order__c', 'Order_Line__c', 'Quantity_Allocated__c', 'Quantity_Picked__c',
            'Quantity_Planned__c', 'Quantity_Shipped__c', 'Quantity_To_Pick__c', 'Sales_Order__c', 'Sales_Order_Line__c', 'Shipment__c',

            'Company__r.Serial_Control__c', 'Company__r.Auto_Plan_Pick__c','Sales_Order_Line__r.Sales_Order__r.Type__c','Sales_Order_Line__r.Type__c',

            'Facility__r.Auto_Confirm_Pick_On_Allocation__c', 'Facility__r.Facility_Identifier__c',

            'Location__r.Bin_Tracked__c', 'Location__r.Facility__c', 'Location__r.Mixed_Bins_Allowed__c', 'Location__r.Track_Bin_Capacity__c',

            'Item__r.Container__c', 'Item__r.Item_Attribute__c', 'Item__r.Non_Inventory__c', 'Item__r.Non_Shippable__c', 'Item__r.Source__c', 'Item__r.Packaging_UOM__c',

            'Item__r.Container_Item__c', 'Item__r.Container_Item__r.Container_Package_Class__c', 'Item__r.Container_Item__r.Container_Package_Class__r.Level__c',
            'Item__r.Container_Item__r.Item_Attribute__c',

            'Item__r.Container_Package_Class__c', 'Item__r.Container_Package_Class__r.Level__c',

            'Item__r.Stocking_UOM__c', 'Item__r.Stocking_UOM__r.Package_Class__c', 'Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__c',
            'Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
            'Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
            'Item__r.Stocking_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c', 'Item__r.Stocking_UOM__r.Package_Class__r.Level__c',

            'Order_Line__r.Quantity_Allocated__c', 'Order_Line__r.Shipping_Company__c', 'Order_Line__r.Packaging_UOM__c',
            'Order_Line__r.Ship_From_Facility__r.Facility_Identifier__c','Order_Line__r.Deliver_To_Facility__r.Facility_Identifier__c',

            'Sales_Order__r.Credit_Hold__c', 'Sales_Order__r.Customer__r.Top_Parent_Customer__r.Credit_Hold__c', 'Sales_Order__r.Has_Exceptions__c', 'Sales_Order__r.Hold__c',
            'Sales_Order__r.Override_Credit_Hold__c', 'Sales_Order__r.Released_to_3PL__c', 'Sales_Order__r.Ship_Complete__c',
            
            'Sales_Order_Line__r.Company__c', 'Sales_Order_Line__r.Customer__c', 'Sales_Order_Line__r.Has_Exceptions__c', 'Sales_Order_Line__r.Parent_Sales_Order_Line__c', 'Sales_Order_Line__r.Price_Type__c',
            'Sales_Order_Line__r.Product__r.Used__c', 'Sales_Order_Line__r.Quantity_Allocated__c', 'Sales_Order_Line__r.Quantity_From_Stock__c',
            'Sales_Order_Line__r.Quantity_Ordered__c', 'Sales_Order_Line__r.Selling_UOM__c', 'Sales_Order_Line__r.Selling_UOM__r.Name',
            'Sales_Order_Line__r.Work_Order__c', 'Item__r.Source__c','Sales_Order_Line__r.Fulfillment_Source__c ',
            
            'Shipment__r.Company__c', 'Shipment__r.Customer__r.Top_Parent_Customer__r.Status__c', 'Shipment__r.Has_Exceptions__c', 'Shipment__r.Ship_From_Bin__c',
            'Shipment__r.Ship_From_Bin__r.Blocked__c', 'Shipment__r.Ship_From_Bin__r.Location__c', 'Shipment__r.Ship_From_Bin__r.Max_Capacity__c',
            'Shipment__r.Ship_From_Bin__r.Packaging_UOM__c', 'Shipment__r.Ship_From_Bin__r.Packaging_UOM__r.Package_Class__c', 'Shipment__r.Status__c'
        });
        shlQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
        shlQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Container_Item__r.Item_Attribute__r');
        shlQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
        shlQuery.addFields(mode);
        for (Stock_Movement_Rule_Settings__c smrs:Stock_Movement_Rule_Settings__c.getAll().values()) {
            if (smrs.Source_Document__c == 'Sales Order') {
                shlQuery.addField('Sales_Order_Line__r.' + smrs.Source_Document_Path__c);
            } else if (smrs.Source_Document__c == 'Transfer Order') {
                shlQuery.addField('Order_Line__r.' + smrs.Source_Document_Path__c);
            }
        }
        for (String attr:SkidService3.attributesForPutaway()) {
            if (soLineFields.contains(attr.toLowerCase())) shlQuery.addField('Sales_Order_Line__r.' + attr);
        }
    }

    private static List<FieldInfo> getFilterFields() {
        List<FieldInfo> filterFields = new List<FieldInfo>();
        List<FieldInfo> shlFields = FieldInfo.fetchJsonFieldInfos('Shipment_Line__c', 'Workbench_Filters');
        shlFields.remove(0);

        FieldInfo fi = new FieldInfo('action', 'Action', 'picklist');
        fi.editable = true;
        fi.required = true;
        fi.selectList = new List<SelectListItem>{
            new SelectListItem('allocate', 'Allocate'),
            new SelectListItem('planpick', 'Plan Pick'),
            new SelectListItem('pick', 'Pick')
        };
        filterFields.add(fi);

        fi = FieldInfo.fetchJsonFieldInfos('Shipment_Line__c', new List<String>{ 'Facility__c' })[0];
        fi.editable = true;
        fi.required = true;
        filterFields.add(fi);

        fi = FieldInfo.fetchJsonFieldInfos('Shipment_Line__c', new List<String>{ 'Shipment__c' })[0];
        fi.editable = true;
        fi.required = false;
        filterFields.add(fi);

        fi = new FieldInfo('fromDate', 'From Date', 'date');
        fi.editable = true;
        filterFields.add(fi);

        fi = new FieldInfo('toDate', 'To Date', 'date');
        fi.editable = true;
        filterFields.add(fi);

        fi = new FieldInfo('documentType', 'Document Type', 'picklist');
        fi.editable = true;
        fi.selectList = new List<SelectListItem>{
            new SelectListItem('sales', 'Sales Order'),
            new SelectListItem('transfer', 'Transfer Order')
        };
        filterFields.add(fi);

        for (FieldInfo shlField:shlFields) {
            if (shlField.field == 'Sales_Order__r.Customer__c') shlField.title = 'Customer (Sold To)';
            else if (shlField.field == 'Shipment__r.Customer__c') shlField.title = 'Customer (Ship To)';

            shlField.editable = true;
            shlField.required = false;
            filterFields.add(shlField);
        }
        
        return filterFields;
    }

    public String filterFieldsJson {
        get {
            if (filterFieldsJson == null) filterFieldsJson = JSON.serialize(getFilterFields());
            return filterFieldsJson;
        } set;
    }

    public String pageParamFieldsJson {
        get {
            if (pageParamFieldsJson == null) {
                List<FieldInfo> pageParamFields = new List<FieldInfo>();

                FieldInfo fi = new FieldInfo('includeUndo', 'Include Lines to Undo', 'boolean');
                fi.editable = true;
                pageParamFields.add(fi);
                
                fi = new FieldInfo('includeBuildToOrder', 'Include Build To Order Lines', 'boolean');
                fi.editable = true;
                pageParamFields.add(fi);
                
                fi = new FieldInfo('Bin__c', 'Shipping Bin', 'reference');
                fi.referenceTo = 'Bin__c';
                fi.editable = true;
                pageParamFields.add(fi);
                
                fi = new FieldInfo('LPN__c', 'To LPN', 'reference');
                fi.referenceTo = 'LPN__c';
                fi.editable = true;
                pageParamFields.add(fi);

                pageParamFieldsJson = JSON.serialize(pageParamFields);
            }
            return pageParamFieldsJson;
        } private set;
    }

    public List<FieldInfo> serialFields {
        get {
            if (serialFields == null) {
                List<String> serialFieldList = SkidService3.serialAttributes.clone();
                serialFieldList.add('Status__c');

                serialFields = new List<FieldInfo>{ new FieldInfo('', '', 'integer') };
                serialFields.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c', 'Serial', String.join(serialFieldList, ','), true));
            }
            return serialFields;
        } set;
    }

    public String serialFieldsJson {
        get {
            if (serialFieldsJson == null) serialFieldsJson = JSON.serialize(serialFields);
            return serialFieldsJson;
        } set;
    }

    public String serialAttributesJson {
        get {
            if (serialAttributesJson == null) serialAttributesJson = JSON.serialize(SkidService3.serialAttributes);
            return serialAttributesJson;
        } set;
    }

    public Integer gridSize {
        get {
            if (gridSize == null) gridSize = serialFields.size() * 150;
            return gridSize;
        } set;
    }

    public PageReference cancel() {
        if (ApexPages.currentPage() != null && ApexPages.currentPage().getParameters().containsKey('shipment')) return new PageReference('/' + ApexPages.currentPage().getParameters().get('shipment'));
        return Page.ShipmentWorkbench;
    }
}