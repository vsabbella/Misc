public with sharing class WorkOrderCompleteExtV2 extends BaseController {
    public String namespace { get; private set; } { namespace = KSE.NamespaceUU; }
    public Boolean limitSerials { get; private set; } { limitSerials = false; }
    public Integer limitSerialsCount { get; private set; } { limitSerialsCount = 1500; }
    public String woJson { get; private set; }
    public Boolean serialTracked { get; private set; } { serialTracked = false; }
    public Operation_Tracking__c op { get; private set; }
    public String opJson { get; private set; }
    public Boolean last { get; private set; } { last = false; }
    public Boolean disable { get; set; } { disable = false; }

    private Work_Order__c wo;

    public WorkOrderCompleteExtV2() {
        Configuration__c config = Configuration__c.getValues('WorkOrderLimitSerials');
        if (config != null && String.isEmpty(config.Value__c) == false) {
            limitSerials = true;
            try { limitSerialsCount = Integer.valueOf(config.Value__c); } catch (Exception e) { }
        }
        
        try {
            Id woId;
            try {
                woId = (Id)ApexPages.currentPage().getParameters().get('wo');
                wo = getWorkOrder(woId);
                woJson = JSON.serialize(wo);
            } catch (Exception e) {
                throw new CustomException(Label.Invalid_work_order_Id + ': ' + woId);
            }

            if (wo.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT) serialTracked = true;

            Id opId = (Id)ApexPages.currentPage().getParameters().get('op');
            for (Integer i = 0; i < wo.Operation_Trackings__r.size(); i++) {
                Operation_Tracking__c operation = wo.Operation_Trackings__r[i];
                if (operation.Id == opId) {
                    op = operation;
                    if (i == 0) last = true;
                    break;
                }
            }
            if (op == null) throw new CustomException('Invalid operation Id: ' + opId);

            opJson = JSON.serialize(op);

            Map<Id, String> validateErrors = WorkOrderService.validateForComplete(new Map<Id,Work_Order__c>{ opId => wo }, false);
            if (validateErrors.containsKey(wo.Id) == true) throw new CustomException(validateErrors.get(wo.Id));
            
            if (wo.Status__c == WorkOrderService.WO_STATUS_COMPLETE) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.WorkOrder_already_completed));
        } catch (Exception e) {
            CustomException.addError(e);
            disable = true;
        }
    }

    public static Work_Order__c getWorkOrder(Id woId) { return Database.query(getWorkOrderQuery('Id = :woId')); }
    public static String getWorkOrderQuery(String whereClause) {
        SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
        woQuery.addFields(new Set<String>{ 'Id', 'Name', 'Close_Date__c', 'Company__c', 'Complete_to_Location__c', 'Completed__c', 'Default_WIP_Location__c',
            'Facility__c', 'Field_Service__c', 'Item__c', 'MRB_Location__c', 'Number_of_Operations__c', 'Order_Quantity__c', 'Order_Quantity_Stocking_UOM__c',
            'Packaging_UOM__c', 'Quantity_Complete__c', 'Quantity_Complete_Stocking_UOM__c', 'Quantity_Scrapped__c', 'Quantity_Scrapped_Stocking_UOM__c',
            'Quantity_to_Complete__c', 'Quantity_to_Complete_Stocking_UOM__c', 'Status__c', 'Type__c',


            'Company__r.Serial_Control__c',

            'Complete_to_Location__r.Bin_Tracked__c', 'Complete_to_Location__r.Facility__c', 'Complete_to_Location__r.Mixed_Bins_Allowed__c',
            'Complete_to_Location__r.Track_Bin_Capacity__c',

            'Default_WIP_Location__r.Bin_Tracked__c', 'Default_WIP_Location__r.Facility__c', 'Default_WIP_Location__r.Mixed_Bins_Allowed__c',
            'Default_WIP_Location__r.Track_Bin_Capacity__c',

            'Facility__r.Facility_Identifier__c',

            'Item__r.Container__c', 'Item__r.Container_Item__c', 'Item__r.Container_Item__r.Item_Attribute__c',
            'Item__r.Container_Item__r.Container_Package_Class__c', 'Item__r.Container_Item__r.Container_Package_Class__r.Level__c',
            'Item__r.Item_Attribute__c', 'Item__r.Non_Inventory__c', 'Item__r.Packaging_UOM__c', 'Item__r.Source__c', 'Item__r.Stocking_UOM__c',

            'MRB_Location__r.Bin_Tracked__c', 'MRB_Location__r.Facility__c', 'MRB_Location__r.Mixed_Bins_Allowed__c', 'MRB_Location__r.Track_Bin_Capacity__c',

            'Packaging_UOM__r.Package_Class__c', 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
            'Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c', 'Packaging_UOM__r.Package_Class__r.Level__c' });
        woQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
        woQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Container_Item__r.Item_Attribute__r');
        woQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
        woQuery.addFields('Complete_RO');
        woQuery.setWhereClause(whereClause);

        SOQLUtil.ChildRelationship opQuery = new SOQLUtil.ChildRelationship(woQuery, 'Operation_Trackings__r');
        opQuery.addFields(new Set<String>{ 'Id', 'Name', 'Backflush_Resource__c', 'Fixed_Hours__c', 'Hours_Consumed__c', 'Quantity_Available__c',
            'Quantity_Completed__c', 'Quantity_Scrapped__c', 'Sequence__c', 'Standard_Hours__c' });
        opQuery.addFields('RecordOperations');
        opQuery.setOrderByClause('Sequence__c DESC');
        woQuery.addChildRelationship(opQuery);

        return woQuery.getQuery();
    }

    public static SkidService3.SerialWrapper generateNewAssembly(Work_Order__c wo) {
        return new SkidService3.SerialWrapper(new SKID__c(
            Company__c = wo.Company__c,
            Quantity_Issued__c = 0,
            Quantity_Short__c = 0,
            Total_Material__c = 0,
            Quantity_Allocated__c = 0,
            Quantity_Required__c = 0,
            Quantity_Used__c = 0,
            Quantity_Scrapped__c = 0,
            Input_Quantity__c = 0,
            Stocking_UOM__c = wo.Item__r.Stocking_UOM__c,
            Item__c = wo.Item__c,
            Facility2__c = wo.Facility__c,
            Date_Received__c = wo.Item__r.Item_Attribute__c != null && wo.Item__r.Item_Attribute__r.Date_Received__c == true ? Date.today() : null
        ));
    }

    @RemoteAction
    public static JsonResult getAssemblyData(Work_Order__c wo, Operation_Tracking__c op, Boolean last) {
        JsonResult result = new JsonResult();
        try {
            List<SkidService3.SerialWrapper> swList = WorkOrderService.getCompleteAssemblyData(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, null, null, null, last) }).get(op.Id);

            if (wo.Type__c != WorkOrderService.WO_TYPE_REPAIR && (last == false || wo.Number_of_Operations__c == 1)) {
                Item__c container = SkidService3.getContainerforItem(wo.Item__r, wo.Packaging_UOM__r);
                List<String> trackedAttrs = SkidService3.trackedAttributes(null, null, wo.Item__r, container);
                
                List<Id> pkgUoms = (List<Id>)JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.Class);
                if (swList.size() == 0 || trackedAttrs.size() > 1 || pkgUoms.size() > 1) {
                    Boolean populated = false;
                    for (SkidService3.SerialWrapper sw:swList) {
                        if (sw.skid.Quantity_Used__c > 0) {
                            populated = true;
                            break;
                        }
                    }
                    
                    SkidService3.SerialWrapper assembly = generateNewAssembly(wo);
                    assembly.skid.Packaging_UOM__c = wo.Packaging_UOM__c;
                    assembly.skid.Packaging_UOM__r = wo.Packaging_UOM__r;
                    assembly.skid.Container_Item__r = container;
                    assembly.skid.Container_Item__c = container.Id;
                    assembly.conversionFactor = KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, wo.Item__r.Stocking_UOM__c, pkgUoms);
                    if (populated == false) {
                        assembly.skid.Quantity_Used__c = Math.max(op.Quantity_Available__c, 0);
                        if (op.Backflush_Resource__c == true) assembly.skid.Input_Quantity__c = Math.max(op.Standard_Hours__c * (op.Fixed_Hours__c == true ? 1 : op.Quantity_Available__c), 0);
                    }
                    swList.add(assembly);
                }
            }

            if (swList.size() == 0) swList.add(new SkidService3.SerialWrapper(new SKID__c(Input_Quantity__c = 0)));

            result.records = swList;
        } catch (Exception e) {
            CustomException.addError(result, e);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult uomChange(Item__c item, Decimal facilityId, Id uomId, Id woPkgId) {
        SOQLUtil uomQuery = new SOQLUtil('UOM__c');
        uomQuery.addFields(new Set<String>{ 'Id', 'Name', 'Package_Class__c',

            'Package_Class__r.Default_Container_Item__c', 'Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c', 'Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
            'Package_Class__r.Fractional_Quantities_Allowed__c', 'Package_Class__r.Level__c' });
        uomQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
        uomQuery.setWhereClause('Id = :uomId');
        UOM__c uom = Database.query(uomQuery.getQuery());

        JsonResult result = new JsonResult();
        result.records = new List<Object>{ uom, SkidService3.getContainerforItem(item, uom), KSE.getConversionFactor(item.Id, facilityId, uomId, item.Stocking_UOM__c, (List<Id>)JSON.deserialize(item.Packaging_UOM__c, List<Id>.Class)),KSE.getConversionFactor(item.Id, facilityId, woPkgId, uomId, (List<Id>)JSON.deserialize(item.Packaging_UOM__c, List<Id>.Class)) };
        return result;
    }
    
    @RemoteAction 
    public static JsonResult getBackflushData(Id woId, Id opId, Boolean last) {
        JsonResult result = new JsonResult();
        try {
            List<WorkOrderWrapper> backflushData = WorkOrderService.getCompleteBackflushData(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(new Work_Order__c(Id = woId), new Operation_Tracking__c(Id = opId), null, null, null, null, last) }).get(woId);
            if (backflushData == null) backflushData = new List<WorkOrderWrapper>();
            result.records = backflushData;
        } catch (Exception e) {
            CustomException.addError(result, e);
        }
        return result;
    }
    
    @RemoteAction 
    public static JsonResult getByproductData(Id woId, Id opId, Boolean last) {
        JsonResult result = new JsonResult();
        try {
            result.records = WorkOrderService.getCompleteByproductData(new Set<Id>{ woId }, new Set<Id>{ opId }, last);
        } catch (Exception e) {
            CustomException.addError(result, e);
        }
        return result;
    }
    
    @RemoteAction 
    public static JsonResult getIssueFromWIPData(Id woId, Boolean last) {
        JsonResult result = new JsonResult();
        try {
            List<WorkOrderWrapper> wipData = WorkOrderService.getCompleteWIPData(new Set<Id>{ woId }, last).get(woId);
            if (wipData == null) wipData = new List<WorkOrderWrapper>();
            result.records = wipData;
        } catch (Exception e) {
            CustomException.addError(result, e);
        }
        return result;
    }

    @RemoteAction 
    public static JsonResult save(Id woId, Id opId, SkidService3.SerialWrapper assembly, List<WorkOrderWrapper> components, List<SkidService3.SerialWrapper> byproducts, Operation_Transaction__c ot) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try {
            Work_Order__c wo = getWorkOrder(woId);

            Operation_Tracking__c op;
            Operation_Tracking__c nextOp;
            Boolean last = false;
            for (Integer i = 0; i < wo.Operation_Trackings__r.size(); i++) {
                Operation_Tracking__c operation = wo.Operation_Trackings__r[i];
                if (operation.Id == opId) {
                    op = operation;
                    if (i == 0) last = true;
                    else nextOp = wo.Operation_Trackings__r[i - 1];
                    break;
                }
            }
            
            if (assembly != null) {
                List<String> attributes = SkidService3.attributesForPutaway(null, new Set<String>{ 'facility2__c', 'location__c', 'bin__c' });
                attributes.add('Customer__c');
                attributes.add('Sales_Order_Line__c');

                Map<List<String>, SkidService3.SerialWrapper> assemblies = new Map<List<String>, SkidService3.SerialWrapper>();
                for (SkidService3.SerialWrapper sw:WorkOrderService.getCompleteAssemblyData(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, null, null, null, last)}).get(op.Id)) {
                    assemblies.put(SkidService3.generateKey(sw.skid, attributes), sw);
                }

                List<String> assemblyKey = SkidService3.generateKey(assembly.skid, attributes);
                if (assemblies.containsKey(assemblyKey) == true) {
                    SkidService3.SerialWrapper requeriedAssembly = assemblies.get(assemblyKey);
                    requeriedAssembly.skid.Quantity_Used__c = assembly.skid.Quantity_Used__c;
                    requeriedAssembly.skid.Quantity_Scrapped__c = assembly.skid.Quantity_Scrapped__c;
                    requeriedAssembly.skid.Input_Quantity__c = assembly.skid.Input_Quantity__c;
                    requeriedAssembly.skid.Bin__c = assembly.skid.Bin__c;
                    requeriedAssembly.skid.Temporary_LPN_Holder__c = assembly.skid.Temporary_LPN_Holder__c;
                    requeriedAssembly.toskid = assembly.toskid;

                    if (requeriedAssembly.serialList.size() > 0) {
                        Map<Id, Serial__c> requeriedSerials = new Map<Id, Serial__c>(requeriedAssembly.serialList);
                        for (Serial__c serial:assembly.serialList) {
                            if (serial.Id != null && requeriedSerials.containsKey(serial.Id) == false) throw new CustomException('Serial ' + serial.Name + ' not found. Please refresh the page.');
                        }
                        requeriedAssembly.serialList = assembly.serialList;
                    }

                    assembly = requeriedAssembly;
                }
                assembly.skid.Item__r = wo.Item__r;
            } 

            if (components == null) components = new List<WorkOrderWrapper>();
            if (components.size() > 0) {
                List<String> attributes = SkidService3.attributesForPutaway();

                Map<Id, WorkOrderWrapper> requeriedComponents = new Map<Id, WorkOrderWrapper>();
                List<WorkOrderWrapper> requeriedData = WorkOrderService.getCompleteBackflushData(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(new Work_Order__c(Id = woId), new Operation_Tracking__c(Id = opId), null, null, null, null, last)}).get(woId);
                if (requeriedData != null) {
                    for (WorkOrderWrapper wow:requeriedData) requeriedComponents.put(wow.material.Id, wow);
                }
                requeriedData = WorkOrderService.getCompleteWIPData(new Set<Id>{ woId }, last).get(woId);
                if (requeriedData != null) {
                    for (WorkOrderWrapper wow:requeriedData) requeriedComponents.put(wow.material.Id, wow);
                }

                for (WorkOrderWrapper wow:components) {
                    if (requeriedComponents.containsKey(wow.material.Id) == false) throw new CustomException(wow.material.Name + ': No material tracking found. Please refresh the page.');
                
                    WorkOrderWrapper requeriedComponent = requeriedComponents.get(wow.material.Id);
                    Material_Tracking__c mt = requeriedComponent.material;
                    wow.material = mt;

                    Map<Id, SkidService3.SerialWrapper> requeriedSkids = new Map<Id, SkidService3.SerialWrapper>();
                    for (SkidService3.SerialWrapper sw:requeriedComponent.serialWrapperList) requeriedSkids.put(sw.skid.Id, sw);

                    List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
                    for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                        if (sw.skid.Id != null) {
                            if (requeriedSkids.containsKey(sw.skid.Id) == false) throw new CustomException(mt.Name + ': Inventory not found. Please refresh the page.');
                        
                            SkidService3.SerialWrapper requeriedSkid = requeriedSkids.get(sw.skid.Id);
                            requeriedSkid.skid.Quantity_to_Issue__c = sw.skid.Quantity_to_Issue__c;
                            requeriedSkid.skid.Quantity_to_Scrap__c = sw.skid.Quantity_to_Scrap__c;
                            requeriedSkid.skid.Item__r = mt.Item__r;
                            requeriedSkid.toskid = sw.toskid;

                            if (requeriedSkid.serialList.size() > 0) {
                                Map<Id, Serial__c> requeriedSerials = new Map<Id, Serial__c>(requeriedSkid.serialList);
                                for (Serial__c serial:sw.serialList) {
                                    if (requeriedSerials.containsKey(serial.Id) == false) throw new CustomException(mt.Name + ': Serial ' + serial.Name + ' not found. Please refresh the page.');
                                }
                                requeriedSkid.serialList = sw.serialList;
                            }

                            sw = requeriedSkid;
                        }
                        sw.skid.Item__r = mt.Item__r;
                        swList.add(sw);
                    }
                }
            }

            if (byproducts != null && byproducts.size() > 0) {
                Map<Id, SkidService3.SerialWrapper> requeriedByproducts = new Map<Id, SkidService3.SerialWrapper>();
                for (SkidService3.SerialWrapper sw:WorkOrderService.getCompleteByproductData(new Set<Id>{ woId }, new Set<Id>{ opId }, last)) {
                    requeriedByproducts.put(sw.skid.Material_Tracking__c, sw);
                }

                for (SkidService3.SerialWrapper sw:byproducts) {
                    if (requeriedByproducts.containsKey(sw.skid.Material_Tracking__c) == false) throw new CustomException(sw.skid.Material_Tracking__r.Name + ': No material tracking found. Please refresh the page.');

                    Material_Tracking__c mt = requeriedByproducts.get(sw.skid.Material_Tracking__c).skid.Material_Tracking__r;
                    sw.skid.Item__r = mt.Item__r;
                    components.add(new WorkOrderWrapper(null, mt, new List<SkidService3.SerialWrapper>{ sw }));
                }
            }
            
            WorkOrderService.CompleteWrapper wrapper = new WorkOrderService.CompleteWrapper(wo, op, nextOp, assembly, components, null, last);
            if (ot != null) wrapper.ot = ot;
            WorkOrderService.complete(new List<WorkOrderService.CompleteWrapper>{ wrapper }, false, false);  
        } catch (Exception e) {
            Database.rollback(sp); 
            CustomException.addError(result, e);

        }
        return result;
    }
    
    @RemoteAction
    public static JsonResult getConversionFactor(Work_Order__c wo, Id toUomId) {
        JsonResult result = new JsonResult();
        try {
            result.records = new List<Object>{ KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, toUomId, (List<Id>)JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.Class)) };
        } catch (Exception e) {
            CustomException.addError(result, e);
        }
        return result;
    }
    
    public String headerFieldsJson {
        get {
            if (headerFieldsJson == null) {
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Work_Order__c', 'Complete_RO', null, true);
                fiList.remove(0);
                for (FieldInfo fi:fiList) fi.field = 'wo.' + fi.field;
        
                List<FieldInfo> opFiList = FieldInfo.fetchJsonFieldInfos('Operation_Tracking__c', 'RecordOperations', null, true);
                opFiList.remove(0);
                for (FieldInfo fi:opFiList) fi.field = 'op.' + fi.field;
                fiList.addAll(opFiList);
        
                headerFieldsJson = JSON.serialize(fiList);
            }
            return headerFieldsJson;
        } private set;
    }

    public String assemblyFieldsJson {
        get {
            if (assemblyFieldsJson == null) {
                List<String> assemblyFields = new List<String>();
                if (wo.Type__c == WorkOrderService.WO_TYPE_REPAIR) assemblyFields.add('Customer__c');
                assemblyFields.addAll(SkidService3.trackedAttributes(null, (wo.Type__c != WorkOrderService.WO_TYPE_REPAIR || wo.Field_Service__c == false) && last ? wo.Complete_to_Location__r : null, wo.Item__r, new Item__c(Item_Attribute__r = new Item_Attribute__c(License_Plate_Number__c = true))));

                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c', assemblyFields);
                if (wo.MRB_Location__r.Bin_Tracked__c == true) {
                    FieldInfo fi = new FieldInfo('Scrap_Bin__c', 'Scrap Bin', 'reference');
                    fi.referenceTo = 'Bin__c';
                    fi.editable = true;
                    fiList.add(fi);
                }

                List<String> fields = new List<String>{ 'Quantity_Short__c' };
                if (wo.Type__c == WorkOrderService.WO_TYPE_REPAIR || (wo.Number_of_Operations__c > 1 && last == true)) fields.add('Quantity_Available__c');
                fields.addAll(new List<String>{ 'Quantity_Used__c', 'Quantity_Scrapped__c', 'Input_Quantity__c' });
                fiList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', fields));

                Set<String> editableFields = new Set<String>{ 'License_Plate_Number__c', 'Bin__c', 'Scrap_Bin__c', 'Quantity_Used__c',
                    'Quantity_Scrapped__c', 'Input_Quantity__c' };

                for (FieldInfo fi:fiList) {
                    if (fi.field != 'Quantity_Short__c' && fi.field != 'Quantity_Available__c' && (editableFields.contains(fi.field) || wo.Number_of_Operations__c == 1 || last == false)) {
                        fi.editable = true;
                    } else {
                        fi.editable = false;
                    }

                    if (fi.field == 'Quantity_Short__c') fi.title = 'Quantity Completed';
                    else if (fi.field == 'Quantity_Used__c') fi.title = 'Quantity to Complete';
                    else if (fi.field == 'Quantity_Scrapped__c') fi.title = 'Quantity to Scrap';
                    else if (fi.field == 'Input_Quantity__c') fi.title = 'Hours To Consume';
                    else if (fi.field == 'License_Plate_Number__c') fi.validateLookupOnBlur = true;

                    fi.field = 'skid.' + fi.field;
                }

                fiList.addAll(FieldInfo.fetchJsonFieldInfos('Operation_Transaction__c', 'Record'));

                assemblyFieldsJson = JSON.serialize(fiList);
            }
            return assemblyFieldsJson;
        } private set;
    }

    public List<FieldInfo> transactionFields {
        get {
            if (transactionFields == null) {
                transactionFields = FieldInfo.fetchJsonFieldInfos('Operation_Transaction__c', 'Record');
                transactionFields.remove(0);
            }
            return transactionFields;
        } private set;
    }

    public String transactionFieldsJson {
        get {
            if (transactionFieldsJson == null) transactionFieldsJson = JSON.serialize(transactionFields);
            return transactionFieldsJson;
        } private set;
    }

    public String materialFieldsJson {
        get {
            if (materialFieldsJson == null) {
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Material_Tracking__c', 'Complete', null, true);
                fiList.remove(0);
                for (FieldInfo fi:fiList) fi.field = 'material.' + fi.field;
                materialFieldsJson = JSON.serialize(fiList);
            }
            return materialFieldsJson;
        } private set;
    }

    public String byproductFieldsJson {
        get {
            if (byproductFieldsJson == null) {
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c', 'Complete_Byproduct', null, true);
                fiList.remove(0);
                
                List<String> displayFields = new List<String>{ 'Location__c', 'Bin__c', 'Packaging_UOM__c', 'Lot_Number__c' };
                displayFields.addAll(SkidService3.attributesForDisplay(new Set<String>{ 'location__c', 'bin__c', 'lot_number__c' }, new List<String>{ 'Quantity__c' }, false, new Item__c(Item_Attribute__r = new Item_Attribute__c(License_Plate_Number__c = true))));
                fiList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', displayFields));

                for (FieldInfo fi:fiList) {
                    if (fi.field == 'Quantity__c') fi.title = 'Quantity to Complete';
                    fi.field = 'skid.' + fi.field;
                }

                byproductFieldsJson = JSON.serialize(fiList);
            }
            return byproductFieldsJson;
        } private set;
    }

    public String repairEditableFieldsJson {
        get {
            if (repairEditableFieldsJson == null) {
                Set<String> repairEditableFields = new Set<String>();
                for (String fld:SchemaUtil.getInstance().removeNSfromSetString(new Set<String>(SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'RepairEditable')))) {
                    repairEditableFields.add('skid.' + fld);
                }

                repairEditableFieldsJson = JSON.serialize(repairEditableFields).toLowerCase();
            }
            return repairEditableFieldsJson;
        } private set;
    }

    public List<FieldInfo> serialFields {
        get {
            if (serialFields == null) {
                serialFields = new List<FieldInfo>{ new FieldInfo('', '', 'integer') };
                serialFields.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c', 'Serial', SkidService3.serialAttributes.size() > 0 ? String.join(SkidService3.serialAttributes, ',') : null, false));
                for (FieldInfo fi:serialFields) {
                    if (fi.field == 'Fixed_Asset__c') {
                        fi.editable = false;
                        break;
                    }
                }
            }
            return serialFields;
        } private set;
    }

    public String serialFieldsJson {
        get {
            if (serialFieldsJson == null) serialFieldsJson = JSON.serialize(serialFields);
            return serialFieldsJson;
        } private set;
    }

    public String serialAttributesJson {
        get {
            if (serialAttributesJson == null) serialAttributesJson = JSON.serialize(SkidService3.serialAttributes);
            return serialAttributesJson;
        } private set;
    }

    public Integer gridSize {
        get {
            if (gridSize == null) gridSize = serialFields.size() * 100;
            return gridSize;
        } private set;
    }

    public Integer assemblyGridSize {
        get {
            if (assemblyGridSize == null) assemblyGridSize = (gridSize * 2) + 40;
            return assemblyGridSize;
        } private set;
    }
    
    public PageReference cancel() { return new PageReference('/' + wo.Id); }

    //TO DELETE
    public String namespaceUU { get; set; }
    public String serialAttributes { get; set; }
    public String serialFieldList { get; set; }
    public String woId { get; set; }
    public String opId { get; set; }
    public String getAssemblyFieldListWithAllAttributes() { return null; }
    public String getBackflushDetailFieldList() { return null; }
    public String getIssueFromWipDetailFieldList() { return null; }
    public static List<String> refreshTrackedAttr(Location__c location , Item__c item) { return null; }
    public String getByproductsFieldList() { return null; }
}