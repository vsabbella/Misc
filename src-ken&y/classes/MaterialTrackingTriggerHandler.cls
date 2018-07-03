public with sharing class MaterialTrackingTriggerHandler {
    private static final Set<String> fieldsToRound = new Set<String>{ 'Quantity_Allocated__c', 'Quantity_Completed__c', 'Quantity_Issued__c', 'Quantity_Per_Assembly__c',
        'Quantity_Required__c', 'Quantity_Scrapped__c', 'Quantity_Used__c' };

    public static void beforeInsert() { KSE.roundNumberFields(Trigger.new, fieldsToRound); }
    public static void beforeUpdate() { KSE.roundNumberFields(Trigger.new, fieldsToRound); }

    public static void afterInsert() { ComponentTriggerHandler.validateOSP(Trigger.new); }
    public static void afterUpdate() {
        for (SObject mt:Trigger.new) {
            if (KSE.isFieldChanging('Item__c', mt, Trigger.oldMap) ||  KSE.isFieldChanging('Operation_Tracking__c', mt, Trigger.oldMap) || KSE.isFieldChanging('Type__c', mt, Trigger.oldMap) || KSE.isFieldChanging('Supplier__c', mt, Trigger.oldMap)) {
                ComponentTriggerHandler.validateOSP(Trigger.new);
                return;
            }
        }
    }
    
    public static void beforeDelete() { }
    public static void afterDelete() { }
    public static void afterUndelete() { }
}