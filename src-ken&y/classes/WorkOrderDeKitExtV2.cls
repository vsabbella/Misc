public with sharing class WorkOrderDeKitExtV2 extends BaseController {

	public String namespaceUU { get; set; } { namespaceUU = KSE.namespaceUU; }
    public static Work_Order__c workOrder { get; set; }
    public static Boolean serialTracked { get; set; } { serialTracked = false; }
    public String serialFieldList { get; set; }
    public Integer gridSize { get; set; }
    final String TYPE_REFERENCE = 'reference' ;
    public static string serialAttributes { get;set;}
    
    private static SchemaUtil util = SchemaUtil.getInstance();
    
    public class WorkOrderKitDeExtV2Exception extends Exception { }

    public WorkOrderDeKitExtV2(ApexPages.StandardController con) {
        try {
            Set<String> woFields = new Set<String>{'Company__r.Serial_Control__c'};
            workOrder = WorkOrderService.getWorkOrders(new Set<Id>{con.getId()},null,woFields,null)[0];
            
            if (workOrder.Company__r.Serial_Control__c != null && workOrder.Company__r.Serial_Control__c == 'At receipt and all processes') {
                serialTracked = true;
            }
            
            FieldInfo fii = new FieldInfo('','','integer');
            fii.editable = false;
            List<FieldInfo> fiList = new List<FieldInfo>{fii};
            List<String> serialAttributesList = new list<String>();
        
            for( String serAttr : SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'Serial_Attributes') ){
       	        serialAttributesList.add(serAttr.replace( KSE.namespaceUU, '').toLowerCase().trim()); 
       	    }
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
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new WorkOrderKitDeExtV2Exception(e.getMessage());
        }
    }
    
    public String getWorkOrderJson() {
        return JSON.serialize(workOrder);  
    }

    @RemoteAction
    public static JsonResult getLocations(Id locationId,Id scrapLocationId) {
        JsonResult result = new JsonResult();
        try {
            List<Id> locationIds = new List<Id>();
            if (locationId != null) locationIds.add(locationId);
            if (scrapLocationId != null) locationIds.add(scrapLocationId);

            SOQLUtil locQuery = new SOQLUtil('Location__c');
            locQuery.addAllCustomFields();
            locQuery.setWhereClause('Id IN :locationIds');
            result.records = Database.query(locQuery.getQuery());
        } catch (Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
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
        for (FieldInfo fi:skidFields) {
            fi.editable = false;
        }

        skidFields.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c',new List<String>{ 'Location__c', 'Bin__c', 'Packaging_UOM__c' }));

        FieldInfo fi = new FieldInfo('ScrapLocation__c','Scrap Location','reference');
        fi.referenceTo = 'Location__c';
        fi.editable = true;
        skidFields.add(fi);

        fi = new FieldInfo('ScrapBin__c','Scrap Bin','reference');
        fi.referenceTo = 'Bin__c';
        fi.editable = true;
        skidFields.add(fi);

        List<FieldInfo> readFields = FieldInfo.fetchJsonFieldInfos('SKID__c', SchemaUtil.getInstance().getFieldsFromFieldSetString(SKID__c.sObjectType, 'Kit_RO'));
        for (FieldInfo f:readFields) {
            f.editable = false;
        }
        skidFields.addAll(readFields);

        skidFields.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c',new List<String>{ 'Quantity__c', 'Quantity_to_Issue__c', 'Quantity_to_Scrap__c' }));

        for (FieldInfo info:skidFields) {
            if (info.field == 'Quantity__c') {
                info.title = 'Quantity Available';
                info.editable = false;
            } else if (info.field == 'Quantity_to_Issue__c') {
                info.title = 'Quantity To Return';
            } else if (info.field == 'Location__c') {
                info.title = 'Dekit Location';
            } else if (info.field == 'Bin__c') {
                info.title = 'Dekit Bin';
            }
            info.field = 'skid.' + info.field;
        }

        return JSON.serialize(skidFields);
    }
    
    public String getDeKitConfigJson() { 
        GridRelatedListController.GridRelatedListConfig kitConfig = new GridRelatedListController.GridRelatedListConfig();
        kitConfig.uniqueId = 'DekitGrid';
        kitConfig.title = 'DeKit Information';
        kitConfig.objectName = 'Material_Tracking__c';
        kitConfig.parentRecord = workOrder;
        kitConfig.parentField = 'Work_Order__c';
        kitConfig.fieldset = 'Kit';
        kitConfig.buttons = 'Expand All, Collapse All, Populate Component Quantities';
        kitConfig.alwaysUseFullDateTimeFormat = false;
        return JSON.serialize(kitConfig);
    }
    
    @RemoteAction 
    public static JsonResult getDeKitData(String woId) {
        JsonResult result = new JsonResult();
        try {
            Id workOrderId = (Id)woId;    
            result.records = WorkOrderService.getDeKitData(new Set<Id>{workOrderId});
            result.total = result.records.size();
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    @RemoteAction 
    public static JsonResult save(Id woId,List<WorkOrderWrapper> wowList,List<String> materialDateFields,List<String> skidDateFields) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try {
            Work_Order__c wo = WorkOrderService.getWorkorders(new Set<Id>{ woId },null,new Set<String>{ 'Shipment_Line__r.Sales_Order_Line__r.Receipt_Line__c' },null)[0];

            for (WorkOrderWrapper wow:wowList) {
                KendoUtils.UpdateDateFields(wow.material,materialDateFields);
                wow.workorder = wo;
                for (SkidService3.SerialWrapper sw:wow.serialWrapperList) {
                    KendoUtils.UpdateDateFields(sw.skid,skidDateFields);
                    sw.skid.Item__r = wow.material.Item__r;
                }
            }
            
            WorkOrderService.dekitV2(new Map<Id,Work_Order__c>{ woId => wo },new Map<Id,List<WorkOrderWrapper>>{ woId => wowList });                         
        } catch (Exception e) {
            Database.rollback(sp);          
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
}