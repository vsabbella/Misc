public with sharing class WorkOrderUncompleteExtV2 extends BaseController {
    public String namespaceUU { get; set; } { namespaceUU = KSE.NamespaceUU; }
    public Id woId { get; set; }
    public Id opId { get; set; }
    public Operation_Tracking__c op { get; set; }
    public Boolean last { get; set; }
    public Boolean disable { get; set; } { disable = false; }
    public Boolean serialTracked { get; set; } { serialTracked = false; }
    
    private Item__c containerItem {get;set;}

    private Work_Order__c wo;
    
    // Conversion between WO Packaging UOM to Item Stocking UOM
    public Decimal conversionFactor {get;set;}
    
    public Boolean limitSerials { get; set; } { limitSerials = false; }
    public Integer limitSerialsCount { get; set; } { limitSerialsCount = 1500; }

    public WorkOrderUncompleteExtV2() {
        Configuration__c config = Configuration__c.getAll().get('WorkOrderLimitSerials');
        if (config != null && !String.isEmpty(config.Value__c)) {
            limitSerials = true;
            try {
                limitSerialsCount = Integer.valueOf(config.Value__c);
            } catch (Exception e) { }
        }

        try {
            try {
                woId = (Id)ApexPages.currentPage().getParameters().get('wo');

                SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
                woQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c','Contents__c', 'Complete_To_Location__c', 'Field_Service__c', 'Item__c', 'Status__c', 'Type__c', 'Company__r.Serial_Control__c','Item__r.Container__c',
                    'Complete_to_Location__r.Bin_Tracked__c', 'Item__r.Item_Attribute__c', 'Item__r.Non_Inventory__c', 'Item__r.Source__c', 'Complete_to_Location__r.Bin_Tracked__c', 'Item__r.Item_Attribute__c', 'Item__r.Non_Inventory__c', 'Item__r.Stocking_UOM__c',
                    'Item__r.Source__c', 'MRB_Location__r.Bin_Tracked__c','Item__r.Container_Item__r.Container_Package_Class__c', 'Packaging_UOM__r.Package_Class__c', 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c',
                    'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c','Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Packaging_UOM__c',
                    'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Packaging_UOM__r.Package_Class__r.Level__c', 'Item__r.Packaging_UOM__c', 'Facility__r.Facility_Identifier__c' });
                woQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
                woQuery.setWhereClause('Id = :woId');

                SOQLUtil.ChildRelationship opQuery = new SOQLUtil.ChildRelationship(woQuery, 'Operation_Trackings__r');
                opQuery.addFields(new Set<String>{ 'Id', 'Name' });
                opQuery.setOrderByClause('Sequence__c DESC');
                woQuery.addChildRelationship(opQuery);

                wo = Database.query(woQuery.getQuery());
                
                List<Id> lstPkgUom = (List<Id>) JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.class);
                conversionFactor = KSE.getConversionFactor ( wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, wo.Item__r.Stocking_UOM__c, lstPkgUom);
                
            } catch(Exception e) {
                throw new WorkOrderUncompleteException(Label.Invalid_work_order_Id + ': ' + woId);
            }

            opId = (Id)ApexPages.currentPage().getParameters().get('op');

            for (Operation_Tracking__c operation:wo.Operation_Trackings__r) {
                if (last == null) {
                    if (operation.Id == opId) {
                        last = true;
                    } else {
                        last = false;
                    }
                }

                if (operation.Id == opId) {
                    op = operation;
                    break;
                }
            }

            if (op == null) {
                throw new WorkOrderUncompleteException('Invalid operation Id: ' + opId);
            }
            
            // Get the container item for the package class 
            containerItem = SkidService3.getContainerforItem (wo.Item__r, wo.Packaging_UOM__r );

            if (wo.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT) {
                serialTracked = true;
            }

            Map<Id,String> validateErrors = WorkOrderService.validateForUncomplete(new List<Work_Order__c>{wo});
            if (validateErrors.containsKey(wo.Id)) {
                throw new WorkOrderUncompleteException(validateErrors.get(wo.Id));
            }
        } catch(Exception e) { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            disable = true;
        }
    }

    @RemoteAction
    public static JsonResult getHeaderAssemblyData(Id woId, Id opId, Boolean last) {
        JsonResult result = new JsonResult();
        try {
            WorkOrderService.UncompleteWrapper wrapper = new WorkOrderService.UncompleteWrapper(null, null, null, null, null, last, null);

            SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
            woQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Default_WIP_Location__c', 'Facility__c', 'Item__c',
                'Number_of_Operations__c', 'Packaging_UOM__c',

                'Facility__r.Facility_Identifier__c',

                'Item__r.Item_Attribute__c', 'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c' });
            woQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
            woQuery.addFields('Complete_RO');
            woQuery.setWhereClause('Id = :woId');

            SOQLUtil.ChildRelationship opQuery = new SOQLUtil.ChildRelationship(woQuery, 'Operation_Trackings__r');
            opQuery.addFields(new Set<String>{ 'Id', 'Name' ,'Backflush_Resource__c','Fixed_Hours__c','Standard_Hours__c'});
            opQuery.addFields('RecordOperations');
            woQuery.addChildRelationship(opQuery);

            Work_Order__c wo = Database.query(woQuery.getQuery());
            wrapper.wo = wo;

            for (Operation_Tracking__c op:wrapper.wo.Operation_Trackings__r) {
                if (op.Id == opId) {
                    wrapper.op = op;
                }
            }

            result.records = new List<Object>{ wrapper };
            result.records.add(WorkOrderService.getUncompleteAssemblyData(new List<WorkOrderService.UncompleteWrapper>{ wrapper }));
        } catch (Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    @RemoteAction 
    public static JsonResult save(Id woId,Id opId,List<SkidService3.SerialWrapper> assemblies,List<WorkOrderWrapper> rows,Boolean last,List<String> skidDateFields) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();

        try {
            Work_Order__c workOrder = WorkOrderService.getWorkOrders(new Set<Id>{woId},null,new Set<String>{ 'Shipment_Line__r.Shipment__c' },new Set<String>{ 'Operation_Trackings__r' })[0];
            Map<Id,Material_Tracking__c> materials = new Map<Id,Material_Tracking__c>(WorkOrderService.getMaterials(new Set<Id>{ woId },null,null,null,null,null,true));
            Map<Id,Material_Tracking__c> consumedMTs = new Map<Id,Material_Tracking__c>();
            
            for (WorkOrderWrapper row:rows) {
                row.workOrder = workOrder;
                if (materials.containsKey(row.material.Id)) {
                    consumedMTs.put(row.material.Id, materials.get(row.material.Id));
                    materials.remove(row.material.Id);
                }
                row.material = consumedMTs.get(row.material.Id);
                
                for (SkidService3.SerialWrapper sw:row.serialWrapperList) {
                    KendoUtils.UpdateDateFields(sw.skid,skidDateFields);
                    sw.skid.Item__r = row.material.Item__r;
                }
            }

            for (Material_Tracking__c mt:materials.values()) {
                rows.add(new WorkOrderWrapper(workOrder,mt,new List<SkidService3.SerialWrapper>()));
            }

            Operation_Tracking__c op;
            Operation_Tracking__c nextOp;
            for (Operation_Tracking__c operation:workOrder.Operation_Trackings__r) {
                if (operation.Id == opId) {
                    op = operation;
                    break;
                }
            }
            for (Operation_Tracking__c operation:workOrder.Operation_Trackings__r) {
                if (operation.Sequence__c > op.Sequence__c && (nextOp == null || operation.Sequence__c < nextOp.Sequence__c)) {
                    nextOp = operation;
                }
            }

            Decimal hoursToUnconsume = 0;
            SkidService3.SerialWrapper assemblySW;

            for (SkidService3.SerialWrapper assembly:assemblies) {
                assembly.skid.Item__r = workOrder.Item__r;
                assembly.skid.Facility2__c = workOrder.Facility__c;
                assembly.skid.Facility2__r = workOrder.Facility__r;

                if (assembly.skid.Input_Quantity__c > 0) {
                    hoursToUnconsume += assembly.skid.Input_Quantity__c;
                }

                assemblySW = assembly;
            }
            
            WorkOrderService.UncompleteWrapper wrapper = new WorkOrderService.UncompleteWrapper(workOrder,op,nextOp,assemblySW,rows,last,hoursToUnconsume);
            
            WorkOrderService.checkUncompleteErrors(new List<WorkOrderService.UncompleteWrapper>{wrapper});
            
            WorkOrderService.uncompleteV2(new List<WorkOrderService.UncompleteWrapper>{wrapper});              
        } catch (Exception e) {
            Database.rollback(sp);          
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

	@RemoteAction
    public static JsonResult getConversionFactor(Item__c item, Decimal facilityId, Id uomId, Id woPkgId) {
        
        JsonResult result = new JsonResult();
        result.records = new List<Object>{KSE.getConversionFactor(item.Id, facilityId, woPkgId, uomId, (List<Id>)JSON.deserialize(item.Packaging_UOM__c, List<Id>.Class)) };
        return result;
    }
    
    @RemoteAction
    public static Boolean isBinTracked(Id locationId) {
        return [SELECT Id,Bin_Tracked__c FROM Location__c WHERE Id = :locationId][0].Bin_Tracked__c;
    }

    @RemoteAction
    public static JsonResult getComponentData(Work_Order__c wo, Id opId, Boolean last, SkidService3.SerialWrapper selectedAssembly) {
        JsonResult result = new JsonResult();
        try {
            result.records = WorkOrderService.getUncompleteComponentData(new List<WorkOrderService.UncompleteWrapper>{ new WorkOrderService.UncompleteWrapper(wo, new Operation_Tracking__c(Id = opId), null, selectedAssembly, null, last, null) });
            result.total = result.records.size();
        } catch (Exception e) {
            CustomException.addError(result, e);
        }
        return result;
    }

    @RemoteAction 
    public static JsonResult getByproductData(Id woId,Id opId,Boolean last) {
        JsonResult result = new JsonResult();
        try {
            result.records = WorkOrderService.getUncompleteByproductData(new Set<Id>{woId},new Set<Id>{opId},last);
            result.total = result.records.size();
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction 
    public static JsonResult getWIPData(Id woId,Id opId,Boolean last) {
        JsonResult result = new JsonResult();
        try {
            result.records = WorkOrderService.getUncompleteWIPData(new Set<Id>{woId},new Set<Id>{opId},last);
            result.total = result.records.size();
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    public String headerFieldsJson {
        get {
            if (headerFieldsJson == null) {
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Work_Order__c', 'Complete_RO', null, true);
                fiList.remove(0);
                for (FieldInfo fi:fiList) {
                    fi.field = 'wo.' + fi.field;
                }
        
                List<FieldInfo> opFiList = FieldInfo.fetchJsonFieldInfos('Operation_Tracking__c', 'RecordOperations', null, true);
                opFiList.remove(0);
                for (FieldInfo fi:opFiList) {
                    fi.field = 'op.' + fi.field;
                }
                fiList.addAll(opFiList);
        
                headerFieldsJson = JSON.serialize(fiList);
            }
            return headerFieldsJson;
        } set;
    }

    public String assemblyFieldsJson {
        get {
            if (assemblyFieldsJson == null) {
                List<String> assemblyFields = new List<String>();
                if ((wo.Type__c != WorkOrderService.WO_TYPE_REPAIR || wo.Field_Service__c == false) && last == true) assemblyFields = new List<String>{ 'Location__c', 'Bin__c' };
                if (wo.Type__c == WorkOrderService.WO_TYPE_REPAIR) assemblyFields.add('Customer__c');
                assemblyFields.addAll(SkidService3.trackedAttributes(null, null, wo.Item__r, new Item__c(Item_Attribute__r = new Item_Attribute__c(License_Plate_Number__c = true))));
                assemblyFields.addAll(new List<String>{ 'Quantity_Available__c', 'Quantity_To_Return__c', 'Input_Quantity__c' });

                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c', assemblyFields);
                for (FieldInfo fi:fiList) {
                    if (fi.field == 'Quantity_To_Return__c' || fi.field == 'Input_Quantity__c') {
                        fi.editable = true;
                        fi.title = fi.field == 'Quantity_To_Return__c' ? 'Quantity to Uncomplete' : 'Hours to Unconsume';
                    } else {
                        fi.editable = false;
                        if (fi.field == 'Quantity_Available__c') fi.title = 'Available to Uncomplete';
                    }
                    
                    fi.field = 'skid.' + fi.field;
                }

                assemblyFieldsJson = JSON.serialize(fiList);
            }
            return assemblyFieldsJson;
        } private set;
    }

    public String materialFieldsJson {
        get {
            if (materialFieldsJson == null) {
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Material_Tracking__c', 'Complete', null, true);
                fiList.remove(0);
                for (FieldInfo fi:fiList) {
                    fi.field = 'material.' + fi.field;
                }
                materialFieldsJson = JSON.serialize(fiList);
            }
            return materialFieldsJson;
        } set;
    }

    public String editableSkidFieldsJson {
        get {
            if (editableSkidFieldsJson == null) {
                editableSkidFieldsJson = getSkidFieldList(true);
            }
            return editableSkidFieldsJson;
        } set;
    }

    public String uneditableSkidFieldsJson {
        get {
            if (uneditableSkidFieldsJson == null) {
                uneditableSkidFieldsJson = getSkidFieldList(false);
            }
            return uneditableSkidFieldsJson;
        } set;
    }

    private String getSkidFieldList(Boolean editable) {

         List<String> displayFields = new List<String>();
         displayFields.addAll(SkidService3.attributesForDisplay(null, null, false));
         List<FieldInfo> skidFields = FieldInfo.fetchJsonFieldInfos('SKID__c', displayFields);
         displayFields = new List<String>{'Quantity__c','Quantity_To_Return__c'};
         skidFields.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', displayFields));

        for (FieldInfo fi:skidFields) {
            if (fi.field == 'Quantity__c') {
                fi.title = 'Quantity Available';
            }

            if (fi.field == 'Location__c' && editable) {
                fi.title = 'Putaway Location';
            }

            if (fi.field != 'Quantity_To_Return__c' && (!editable || (fi.field != 'Location__c' && fi.field != 'Bin__c'))) {
                fi.editable = false;
            }

            fi.field = 'skid.' + fi.field;
        }

        return JSON.serialize(skidFields); 
    }

    public String serialFieldListJson {
        get {
            if (serialFieldListJson == null) {
                serialFieldListJson = JSON.serialize(serialFieldList);
            }
            return serialFieldListJson;
        } set;
    }

    public String serialAttributesJson {
        get {
            if (serialAttributesJson == null) {
                serialAttributesJson = JSON.serialize(serialAttributes); 
            }
            return serialAttributesJson;
        } set;
    }

    public List<FieldInfo> serialFieldList {
        get {
            if (serialFieldList == null) {
                FieldInfo fi = new FieldInfo('','','integer');
                fi.editable = false;
                serialFieldList = new List<FieldInfo>{fi};
                serialFieldList.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c','Serial',serialAttributes.size() > 0 ? String.join(serialAttributes, ',') : null,false));

                for (FieldInfo field:serialFieldList) {
                    if (field.field.toLowerCase() == 'fixed_asset__c' || field.field.toLowerCase() == 'name') {
                        field.editable = false;
                    }
                }
            }
            return serialFieldList;
        } set;
    }

    public List<String> serialAttributes {
        get {
            if (serialAttributes == null) {
                serialAttributes = new List<String>();
                for (String attr:SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType,'Serial_Attributes')) {
                    serialAttributes.add(attr.replace(namespaceUU,'').toLowerCase().trim()); 
                }
            }
            return serialAttributes;
        } set;
    }

    public Integer gridSize {
        get {
            if (gridSize == null) {
                gridSize = serialFieldList.size() * 150;
            }
            return gridSize;
        } set;
    }

    public PageReference cancel() { return new PageReference('/' + wo.Id); }

    public class WorkOrderUncompleteException extends Exception { }

    //TO DELETE
    public String woJson { get; set; }
    @RemoteAction public static JsonResult getOperation ( Id woId, Id opId ) { return null; }
    @RemoteAction public static JsonResult getAssemblyData (Id woId, Id opId, Boolean lastOp) { return null; }
    public String headerFieldListJson { get; set; }
    public String assemblyConfigJson { get; set; }
    public String assemblyFieldListJson { get; set; }
    public String returnConfigJson { get; set; }
    public String byproductConfigJson { get; set; }
    public String wipConfigJson { get; set; }
    private GridRelatedListController.GridRelatedListConfig getConfig() { return null; }
    public String materialFieldListJson { get; set; }
    public String uneditableSkidFieldListJson { get; set; }
    public String editableSkidFieldListJson { get; set; }
}