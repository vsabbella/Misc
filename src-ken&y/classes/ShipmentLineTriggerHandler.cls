public with sharing class ShipmentLineTriggerHandler {
    private static final Set<String> fieldsToRound = new Set<String>{ 'Quantity_Planned__c', 'Quantity_Allocated__c', 'Quantity_To_Pick__c',
        'Quantity_Picked__c', 'Quantity_Shipped__c' };

    public static void beforeInsert() { KSE.roundNumberFields(Trigger.new, fieldsToRound); }
    public static void beforeUpdate() { KSE.roundNumberFields(Trigger.new, fieldsToRound); }

    public static void beforeDelete() { }
    public static void afterInsert() { }
    public static void afterUpdate() { }
    public static void afterDelete() { }
    public static void afterUndelete() { }
}