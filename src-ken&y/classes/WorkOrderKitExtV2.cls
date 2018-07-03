public with sharing class WorkOrderKitExtV2 extends BaseController {
    public String namespaceUU { get; set; } { namespaceUU = KSE.namespaceUU; }
    public static Work_Order__c workOrder { get; set; }
    public static Boolean serialTracked { get; set; } { serialTracked = false; }
    public String serialFieldList { get; set; }
    public Integer gridSize { get; set; }
    final String TYPE_REFERENCE = 'reference' ;
    public static string serialAttributes { get;set;}

    public Boolean disable { get; set; } { disable = false; }    

    private static SchemaUtil util = SchemaUtil.getInstance();
    
    public class WorkOrderKitExtV2Exception extends Exception { }

    public WorkOrderKitExtV2(ApexPages.StandardController con) {
        workOrder = WorkOrderService.getWorkOrders(new Set<Id>{ con.getId() },null,new Set<String>{ 'Complete_To_Location__r.Facility__r.Company__c' },null)[0];

        if (workOrder.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT) {
            serialTracked = true;
        }
        
        try {
            WorkOrderService.validateForKit(new List<Work_Order__c>{ workOrder });
            
            FieldInfo fii = new FieldInfo('','','integer');
            fii.editable = false;
            List<FieldInfo> fiList = new List<FieldInfo>{fii};
            List<String> serialAttributesList = SkidService3.serialAttributes;
            serialAttributes = JSON.serialize(serialAttributesList);
            fiList.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c', 'Serial',serialAttributesList.size() > 0 ? String.join(serialAttributesList, ',') : null, false));
            
            for(FieldInfo fi : fiList){
                
                String field = fi.field.replace(KSE.NamespaceUU, '');
                if(field.toLowerCase() == 'name'){
                    fi.field='SerialNameId';
                    fi.fieldType = TYPE_REFERENCE;
                    fi.referenceTo = 'Serial__c';
                }
                else if( field.toLowerCase() == 'fixed_asset__c' ){
                    fi.editable = false;
                }
            }
            serialFieldList = JSON.serialize(fiList);
            gridSize = fiList.size() * 150;
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            disable = true;
        }
    }

    @RemoteAction
    public static JsonResult save(List<WorkOrderWrapper> mWrappers,List<String> mDateFields,List<String> skidDateFields) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        Set<Id> woIds = new Set<Id>();

        try {
            for (WorkOrderWrapper mWrapper:mWrappers) {
                woIds.add(mWrapper.material.Work_Order__c);

                KendoUtils.UpdateDateFields(mWrapper.material,mDateFields);
                
                for (SkidService3.SerialWrapper sw:mWrapper.serialWrapperList) {
                    KendoUtils.UpdateDateFields(sw.skid,skidDateFields);
                }
            }

            Work_Order__c wo = WorkOrderService.getWorkOrders(woIds,null,new Set<String>{ 'Complete_To_Location__r.Facility__r.Company__c' },null)[0];

            Map<Id, Material_Tracking__c> materials = new Map<Id, Material_Tracking__c>(WorkOrderService.getMaterials(woIds,null,new Set<String>{ WorkOrderService.MATERIAL_TYPE_KIT, WorkOrderService.MATERIAL_TYPE_REPAIR },new Set<String>{ 'Kit' },new Set<String>{ 'Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c' },' AND Operation_Tracking__c = null ', true));

            for (WorkOrderWrapper mWrapper:mWrappers) {
                mWrapper.workOrder = wo.clone(true, true);
                mWrapper.material = materials.get(mWrapper.material.Id);
            }

            WorkOrderService.kit(mWrappers);
        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    public String getWorkOrderJson() {
        return JSON.serialize(workOrder);  
    }
    
    @RemoteAction 
    public static JsonResult getKitData(Id woId) {
        JsonResult result = new JsonResult();
        try {
            result.records = WorkOrderService.getKitData(new Set<Id>{ woId });
            result.total = result.records.size();
        } catch (Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult addLine(Material_Tracking__c mt) {
        JsonResult result = new JsonResult();
        try {
            SKID__c skid = new SKID__c(
                Company__c = mt.Work_Order__r.Company__c,
                Type__c = SkidService3.SKID_TYPE_LOCATION,
                Item__c = mt.Item__c,
                Item__r = mt.Item__r,
                Facility2__c = mt.Work_Order__r.Facility__c,
                Facility2__r = mt.Work_Order__r.Facility__r,
                Quantity__c = 0,
                Quantity_Available__c = 0,
                Quantity_to_Issue__c = 0
            );
            SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skid,new List<Serial__c>());
            sw.trackedAttributes = new List<String>();
            for (String attr:SkidService3.refreshTrackedAttr(null,null,new Item__c(Id = mt.Item__c))) {
                sw.trackedAttributes.add('skid.' + attr.toLowerCase());
            }
            result.records = new List<SkidService3.SerialWrapper>{ sw };
        } catch (Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult getLocation(Id locationId) {
        JsonResult result = new JsonResult();
        try {
            SOQLUtil locQuery = new SOQLUtil('Location__c');
            locQuery.addAllCustomFields();
            locQuery.setWhereClause('Id = \'' + locationId + '\'');
            result.records = new List<Location__c>{ (Location__c)Database.query(locQuery.getQuery())[0] };
        } catch (Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    public String getKitConfigJson() {
        GridRelatedListController.GridRelatedListConfig kitConfig = new GridRelatedListController.GridRelatedListConfig();
        kitConfig.uniqueId = 'kitGrid';
        kitConfig.title = 'Kit Information';
        kitConfig.objectName = 'Material_Tracking__c';
        kitConfig.parentRecord = workOrder;
        kitConfig.parentField = 'Work_Order__c';
        kitConfig.fieldset = 'Kit';
        kitConfig.buttons = 'Expand All, Collapse All, Populate Component Quantities';
        kitConfig.alwaysUseFullDateTimeFormat = false;
        return JSON.serialize(kitConfig);
    }
    
    public String getMtFieldList() {
        List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Material_Tracking__c','Kit',null,true);
        fiList.remove(0); // Remove Id field from the list
        for (FieldInfo fi:fiList) {
            fi.field = 'material.' + fi.field;
        }
        return JSON.serialize(fiList);
    }
    
    public String getSkidFieldList() {
        List<String> displayFields = new List<String>();
        if (workOrder.Type__c == WorkOrderService.WO_TYPE_REPAIR && workOrder.Shipment_Line__c == null && workOrder.Field_Service__c) {
            displayFields.add('Customer__c');
        }
        displayFields.addAll(SkidService3.attributesForDisplay(null, new List<String>{ 'Consigned_Owner__c' }, false));
        List<FieldInfo> skidFields = FieldInfo.fetchJsonFieldInfos('SKID__c', displayFields);

        List<FieldInfo> readFields = FieldInfo.fetchJsonFieldInfos('SKID__c', SchemaUtil.getInstance().getFieldsFromFieldSetString(SKID__c.sObjectType, 'Kit_RO'));
        for (FieldInfo fi:readFields) {
            fi.editable = false;
        }
        skidFields.addAll(readFields);

        skidFields.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', new List<String>{ 'Quantity_Available__c', 'Quantity_to_Issue__c' }));

        for (FieldInfo fi:skidFields) {
            if (fi.field == 'Customer__c' || fi.field == 'Consigned_Owner__c' || fi.field == 'Quantity_Available__c') {
                fi.editable = false;
            }
            fi.field = 'skid.' + fi.field;
        }
        return JSON.serialize(skidFields);
    }
}