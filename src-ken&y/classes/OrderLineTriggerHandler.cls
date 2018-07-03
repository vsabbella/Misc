public with sharing class OrderLineTriggerHandler {
    private static final Set<String> fieldsToRound = new Set<String>{ 'Quantity_Ordered__c', 'Quantity_Released__c', 'Quantity_Allocated__c',
        'Quantity_Shipped__c', 'Quantity_Received__c' };

    public static void beforeInsert() { KSE.roundNumberFields(Trigger.new, fieldsToRound); }
    public static void beforeUpdate() { KSE.roundNumberFields(Trigger.new, fieldsToRound); }

    public static void beforeDelete() { }
    public static void afterInsert() { }
    public static void afterUpdate() { }
    public static void afterDelete() { }
    public static void afterUndelete() { }
}