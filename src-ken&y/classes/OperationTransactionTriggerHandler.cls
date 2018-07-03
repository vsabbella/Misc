public with sharing class OperationTransactionTriggerHandler {
    private static final Set<String> fieldsToRound = new Set<String>{ 'Quantity_Completed__c', 'Quantity_Packaging_UOM__c', 'Quantity_Scrapped__c' };

    public static void beforeInsert() { KSE.roundNumberFields(Trigger.new, fieldsToRound); }
    public static void beforeUpdate() { KSE.roundNumberFields(Trigger.new, fieldsToRound); }

    public static void beforeDelete() { }
    public static void afterInsert() { }
    public static void afterUpdate() { }
    public static void afterDelete() { }
    public static void afterUndelete() { }
}