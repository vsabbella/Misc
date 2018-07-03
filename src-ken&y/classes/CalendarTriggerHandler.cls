public with sharing class CalendarTriggerHandler {
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    private static final Set<String> requiredFields = new Set<String>{ KSE.NamespaceUU + 'Company__c', KSE.NamespaceUU + 'Start_Date__c', KSE.NamespaceUU + 'Type__c' };
    
    public static void beforeInsert() { validate((List<Calendar__c>)Trigger.new); }
    public static void beforeUpdate() { validate((List<Calendar__c>)Trigger.new); }
    
    private static void validate(List<Calendar__c> calendars) {
        for (Calendar__c calendar:calendars)
            for (String field:requiredFields)
                if (calendar.get(field) == null)
                    calendar.addError(Calendar__c.getSObjectType().getDescribe().fields.getMap().get(field).getDescribe().getLabel() + ' ' + Label.is_required);
    }
    
    public static void afterInsert() { }  
    public static void afterUpdate() { }
    public static void beforeDelete() { }
    public static void afterDelete() { }
    public static void afterUndelete() { } 
}