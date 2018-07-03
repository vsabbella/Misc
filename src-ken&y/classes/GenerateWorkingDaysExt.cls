public with sharing class GenerateWorkingDaysExt {
    private ApexPages.StandardController con;
    public Calendar__c calendar { get; set; }
    
    public Date endDate { get; set; }
    public List<TimeWrapper> times { get; set; } { 
        List<String> daysOfTheWeek = new List<String>{ 'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday' };
        times = new List<TimeWrapper>(); 
        for (String day:daysOfTheWeek)
            times.add(new TimeWrapper(day));
    }

    public GenerateWorkingDaysExt(ApexPages.StandardController c) { 
        con = c; 


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
SOQLUtil soql = new SOQLUtil('Calendar__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','Start_Date__c'
});
        string cId = con.getId();
        soql.setWhereClause('Id = :cId');
soql.setLimit(1);
calendar = Database.query(soql.getQuery());




/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        soql = new SOQLUtil('Working_Day__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','End__c'
});
        string calenderId = calendar.Id;        
        soql.setWhereClause('Calendar__c = :calenderId');
soql.setOrderByClause('End__c DESC');
List<Working_Day__c> existingDays = Database.query(soql.getQuery());


        if (existingDays.size() > 0)
            calendar.Start_Date__c = existingDays[0].End__c.date().addDays(1);
    }
    public PageReference save() {
        if (endDate == null)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'End date ' + Label.is_required));
        else if (endDate < calendar.Start_Date__c)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.End_date_must_be_after_start_date));
        Map<String,TimeWrapper> timeMap = new Map<String,TimeWrapper>();
        for (TimeWrapper t:times) {
            if ((t.startTime != null || t.endTime != null) && (t.startTime == null || t.endTime == null))
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.Missing_start_or_end_time_for + ' ' + t.dayOfTheWeek));
            else if (t.startTime >= t.endTime)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.Start_time_must_be_before_end_time_for + ' ' + t.dayOfTheWeek));
            if (t.startTime != null && t.endTime != null)
                timeMap.put(t.dayOfTheWeek,t);
        }
        if (ApexPages.hasMessages(ApexPages.Severity.FATAL))
            return null;
            
        List<Working_Day__c> daysToInsert = new List<Working_Day__c>();
        Date d = calendar.Start_Date__c;
        while (d <= endDate) {
            TimeWrapper t = timeMap.get(DateTime.newInstance(d,Time.newInstance(0,0,0,0)).format('EEEE'));
            if (t != null)
                daysToInsert.add(new Working_Day__c(
                    Calendar__c = calendar.Id,
                    Start__c = DateTime.newInstance(d,t.startTime),
                    End__c = DateTime.newInstance(d,t.endTime)
                ));
            d = d.addDays(1);
        }
        try {
            DML.insertAsUser(daysToInsert);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            return null;
        }
        return con.cancel();
    }

    public class TimeWrapper {
        public String dayOfTheWeek { get; set; }
        public Time startTime { get; set; }
        public Time endTime { get; set; }
        public TimeWrapper(String day) { dayOfTheWeek = day; }
    }
}