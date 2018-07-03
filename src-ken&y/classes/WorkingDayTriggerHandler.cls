public with sharing class WorkingDayTriggerHandler {
    public static final Set<String> requiredFields = new Set<String>{ 'Calendar__c','Start__c','End__c' };
    
    public static void beforeInsert() { validate((List<Working_Day__c>)Trigger.new); }
    public static void beforeUpdate() { validate((List<Working_Day__c>)Trigger.new); }
    
    
    private static void validate(List<Working_Day__c> days) {
        Date earliestDate;
        Date lastDate;
        Set<Id> calendarIds = new Set<Id>();
        for (Working_Day__c day:days) {
            Boolean hasError = false;
            for (String field:requiredFields) {
                if (day.get(field) == null) {
                    day.addError(Working_Day__c.getSObjectType().getDescribe().fields.getMap().get(field).getDescribe().getLabel() + ' ' + Label.is_required);
                    hasError = true;
                }
            }
            if (!hasError) {
                day.Hours__c = (day.End__c.getTime() - day.Start__c.getTime())/(1000*60*60);
                calendarIds.add(day.Calendar__c);
                if (earliestDate == null || day.Start__c.date() < earliestDate)
                    earliestDate = day.Start__c.date();
                if (lastDate == null || day.End__c.date() < lastDate)
                    lastDate = day.End__c.date();
            }
        }
        
        Map<Id,Map<Date,Id>> existingDates = new Map<Id,Map<Date,Id>>();
        
		DateTime earliestDateTime = DateTime.newInstance(earliestDate,Time.newInstance(0,0,0,0));
		DateTime lastDateTime = DateTime.newInstance(lastDate,Time.newInstance(23,59,59,999));
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Working_Day__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Calendar__c','Start__c'
		});
		soql.setWhereClause('Calendar__c IN :calendarIds AND Start__c >= :earliestDateTime AND End__c <= :lastDateTime');
		
		for (Working_Day__c day : Database.query(soql.getQuery())){
            if (!existingDates.containsKey(day.Calendar__c)){
                existingDates.put(day.Calendar__c,new Map<Date,Id>());
            }
            existingDates.get(day.Calendar__c).put(day.Start__c.date(),day.Id);
        }
        
        for (Working_Day__c day:days)
            if (existingDates.containsKey(day.Calendar__c) && existingDates.get(day.Calendar__c).containsKey(day.Start__c.date()) &&  existingDates.get(day.Calendar__c).get(day.Start__c.date()) != day.Id)
                day.addError(String.valueOf(day.Start__c.date()) + ' ' + Label.already_exists);
    }
    
    public static void afterInsert() { }  
    public static void afterUpdate() { }
    public static void beforeDelete() { }
    public static void afterDelete() { }
    public static void afterUndelete() { } 
}