@isTest
public with sharing class GenerateWorkingDaysTest {
    private static testMethod void testGenerate() {
        TestFuel fuel = new TestFuel();
        Calendar__c cal = new Calendar__c(
            Name = 'Cal',
            Start_Date__c = Date.today(),
            Type__c = 'Manufacturing',
            Company__c = fuel.company.Id
        );
        insert cal;
        update new Calendar__c(Id = cal.Id,Description__c = 'test');
        
        ApexPages.StandardController con = new ApexPages.StandardController(cal);
        
        GenerateWorkingDaysExt ext = new GenerateWorkingDaysExt(con);
        ext.endDate = Date.today().addMonths(1);
        for (GenerateWorkingDaysExt.TimeWrapper tw:ext.times) {
            if (tw.dayOfTheWeek != 'Saturday' && tw.dayOfTheWeek != 'Sunday') {
                tw.startTime = Time.newInstance(9,0,0,0);
                tw.endTime = Time.newInstance(17,0,0,0);
            }
        }
        System.assert(ext.save() != null);
        
        Working_Day__c day = [SELECT Id,Start__c,Hours__c FROM Working_Day__c ORDER BY Start__c ASC LIMIT 1];
        System.assert(day.Hours__c == 8.0);
        update new Working_Day__c(Id = day.Id,Start__c = DateTime.newInstance(day.Start__c.date(),Time.newInstance(10,0,0,0)));
        day = [SELECT Id,Start__c,Hours__c FROM Working_Day__c ORDER BY Start__c ASC LIMIT 1];
        System.assert(day.Hours__c == 7.0);
        delete day;
        
        ext = new GenerateWorkingDaysExt(con);
        System.assert(ext.calendar.Start_Date__c != Date.today());
        ext.endDate = Date.today().addMonths(2);
        for (GenerateWorkingDaysExt.TimeWrapper tw:ext.times) {
            if (tw.dayOfTheWeek != 'Saturday' && tw.dayOfTheWeek != 'Sunday') {
                tw.startTime = Time.newInstance(9,0,0,0);
                tw.endTime = Time.newInstance(17,0,0,0);
            }
        }
        System.assert(ext.save() != null);
        
        delete cal;
    }

}