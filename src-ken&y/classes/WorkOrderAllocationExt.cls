public with sharing class WorkOrderAllocationExt extends GridRelatedListController {

    public String namespaceUU { get; set; } { namespaceUU = KSE.NamespaceUU; }
    public Boolean serialTracked { get; set; } { serialTracked = false; }
    public Boolean disable { get; set; } { disable = false; }

    private Work_Order__c wo;

    public WorkOrderAllocationExt(ApexPages.StandardController con) { 
        wo = WorkOrderService.getWorkOrders(new Set<Id>{ con.getId() },null,null,null)[0];

        if (wo.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT) {
            serialTracked = true;
        }

        try {
            AllocationService.validate(new List<Work_Order__c>{ wo });
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            disable = true;
        }
    }

    @RemoteAction
    public static JsonResult getMaterialData(Id woId) {
        JsonResult result = new JsonResult();
        try {
            result.records = AllocationService.getLines(new Set<Id>{ woId });
            result.total = result.records.size();
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult save(List<LineWrapper> mWrappers,List<String> mDateFields,List<String> skidDateFields) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try {
            for (LineWrapper mWrapper:mWrappers) {
                KendoUtils.UpdateDateFields(mWrapper.line,mDateFields);
                
                for (SkidService3.SerialWrapper sw:mWrapper.serialWrappers) {
                    KendoUtils.UpdateDateFields(sw.skid,skidDateFields);

                    sw.skid.Item__r = (Item__c)mWrapper.line.getSObject('Item__r');
                }
            }

            AllocationService.allocate(mWrappers);
        } catch(Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    public String woJson {
        get {
            if (woJson == null) {
                woJson = JSON.serialize(wo);
            }
            return woJson;
        } set;
    }

    public String materialConfigJson {
        get {
            if (materialConfigJson == null) {
                materialConfigJson = JSON.serialize(AllocationService.getLineConfig(Material_Tracking__c.sObjectType));
            }
            return materialConfigJson;
        } set;
    }

    public String materialFieldsJson {
        get {
            if (materialFieldsJson == null) {
                materialFieldsJson = JSON.serialize(AllocationService.getLineFields('Material_Tracking__c'));
            }
            return materialFieldsJson;
        } set;
    }

    public String skidFieldsJson {
        get {
            if (skidFieldsJson == null) {
                skidFieldsJson = JSON.serialize(AllocationService.skidFields);
            }
            return skidFieldsJson;
        } set;
    }

    public String serialFieldsJson {
        get {
            if (serialFieldsJson == null) {
                serialFieldsJson = JSON.serialize(AllocationService.serialFields);
            }
            return serialFieldsJson;
        } set;
    }

    public String serialAttributesJson {
        get {
            if (serialAttributesJson == null) {
                serialAttributesJson = JSON.serialize(SkidService3.serialAttributes); 
            }
            return serialAttributesJson;
        } set;
    }

    public Integer gridSize {
        get {
            if (gridSize == null) {
                gridSize = AllocationService.gridSize;
            }
            return gridSize;
        } set;
    }

    public PageReference cancel() { return new PageReference('/' + wo.Id); }
}