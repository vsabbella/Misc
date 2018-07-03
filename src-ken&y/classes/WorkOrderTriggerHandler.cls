public with sharing class WorkOrderTriggerHandler {
    private static final SchemaUtil util = SchemaUtil.getInstance();
    private static final Set<String> fieldsToRound = new Set<String>{ 'Completed__c', 'Order_Quantity__c', 'Order_Quantity_Stocking_UOM__c', 'Quantity_Complete__c',
        'Quantity_Complete_Stocking_UOM__c', 'Quantity_Scrapped__c', 'Quantity_Scrapped_Stocking_UOM__c' };

    public static void beforeInsert() {
        List<Work_Order__c> workOrders = (List<Work_Order__c>)Trigger.new;
        validate(workOrders);
        calculateStockingQtys(workOrders, null);
        KSE.roundNumberFields(Trigger.new, fieldsToRound);
    }

    public static void beforeUpdate() {
        List<Work_Order__c> workOrders = (List<Work_Order__c>)Trigger.new;
        Map<Id, Work_Order__c> oldWorkOrders = (Map<Id,Work_Order__c>)Trigger.oldMap;

        validate(workOrders);
        if (WorkOrderService.allowWorkOrderUpdate == false) isValidEdit(workOrders, oldWorkOrders);
        calculateStockingQtys(workOrders, oldWorkOrders);
        KSE.roundNumberFields(workOrders, fieldsToRound);
    }

    private static void calculateStockingQtys(List<Work_Order__c> workOrders, Map<Id, Work_Order__c> oldWorkOrders) {
        List<Work_Order__c> workOrdersToUpdate = new List<Work_Order__c>();
        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        for (Work_Order__c wo:workOrders) {
            if (KSE.isFieldChanging('Order_Quantity__c', wo, oldWorkOrders) == true || KSE.isFieldChanging('Packaging_UOM__c', wo, oldWorkOrders) == true || KSE.isFieldChanging('Item__c', wo, oldWorkOrders) == true || KSE.isFieldChanging('Facility__c', wo, oldWorkOrders) == true) {
                workOrdersToUpdate.add(wo);
                if (oldWorkOrders == null) {
                    itemIds.add(wo.Item__c);
                    facilityIds.add(wo.Facility__c);
                }
            }
        }

        if (workOrdersToUpdate.size() > 0) {
            Map<Id, Item__c> items;
            Map<Id, Facility__c> facilities;
            Map<Id, Work_Order__c> queriedWorkOrders;
            if (oldWorkOrders == null) {
                SOQLUtil itemQuery = new SOQLUtil('Item__c');
                itemQuery.addFields(new Set<String>{ 'Id', 'Packaging_UOM__c', 'Stocking_UOM__c' });
                itemQuery.setWhereClause('Id IN :itemIds');
                items = new Map<Id, Item__c>((List<Item__c>)Database.query(itemQuery.getQuery()));

                SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
                facilityQuery.addFields(new Set<String>{ 'Id', 'Facility_Identifier__c' });
                facilityQuery.setWhereClause('Id IN :facilityIds');
                facilities = new Map<Id, Facility__c>((List<Facility__c>)Database.query(facilityQuery.getQuery()));
            } else {
                SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
                woQuery.addFields(new Set<String>{ 'Id', 'Facility__c', 'Facility__r.Facility_Identifier__c', 'Item__c', 'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c' });
                woQuery.setWhereClause('Id IN :workOrdersToUpdate');
                queriedWorkOrders = new Map<Id, Work_Order__c>((List<Work_Order__c>)Database.query(woQuery.getQuery()));
            }

            Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
            for (Work_Order__c wo:workOrdersToUpdate) {
                Item__c item;
                Facility__c facility;
                if (queriedWorkOrders != null) {
                    Work_Order__c queriedWo = queriedWorkOrders.get(wo.Id);
                    item = queriedWo.Item__r;
                    facility = queriedWo.Facility__r;
                } else {
                    item = items.get(wo.Item__c);
                    facility = facilities.get(wo.Facility__c);
                }

                if (packagingUoms.containsKey(item.Id) == false) packagingUoms.put(item.Id, (List<Id>)JSON.deserialize(item.Packaging_UOM__c, List<Id>.Class));

                wo.Order_Quantity_Stocking_UOM__c = wo.Order_Quantity__c * KSE.getConversionFactor(item.Id, facility.Facility_Identifier__c, wo.Packaging_UOM__c, item.Stocking_UOM__c, packagingUoms.get(item.Id));
            }
        }
    }

    private static void isValidEdit(List<Work_Order__c> workOrders, Map<Id, Work_Order__c> oldWorkOrders) {
        Set<String> fields = util.getAllCustomFieldsFromObject(null, 'Work_Order__c');
        Set<String> editableFields = new Set<String>();
        for (FieldSetMember fsm:util.getFieldsFromFieldSet(Work_Order__c.sObjectType, 'WO_Editable_Fields')) {
            editableFields.add(fsm.getFieldPath().toLowerCase().replace(KSE.namespaceUU.toLowerCase(), ''));
        }
        fields.removeAll(editableFields);

        for (Work_Order__c wo:workOrders) {
            Work_Order__c oldWo = oldWorkOrders.get(wo.Id);
            if (oldWo.Status__c != WorkOrderService.WO_STATUS_DRAFT) {
                for (String field:fields) {
                    if (KSE.isFieldChanging(field, wo, oldWorkOrders) == true) {
                        wo.addError(Label.Cannot_edit_work_order);
                        break;
                    }
                }
            }

            if (KSE.isFieldChanging('Field_Service__c', wo, oldWorkOrders)) wo.addError('Field Service: ' + Label.Attribute_cannot_be_changed);
            if (wo.Order_Quantity__c <= 0) wo.Order_Quantity__c.addError(wo.Name + ': Order Quantity cannot be zero or negative.');
        }
    }

    private static void validate(List<Work_Order__c> workOrders) {
        for (Work_Order__c wo:workOrders) {
            if (wo.Status__c != WorkOrderService.WO_STATUS_DRAFT && wo.Type__c == WorkOrderService.WO_TYPE_REPAIR && wo.Reason_Code__c == null) {
                wo.Reason_Code__c.addError('Reason code is required for repair work orders.');
            }
        }
    }

    public static void beforeDelete() { }
    public static void afterInsert() { }
    public static void afterUpdate() { }
    public static void afterDelete() { }
    public static void afterUndelete() { }
}