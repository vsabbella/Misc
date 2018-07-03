@isTest
private class DateUtilTest {
    // Tests if a date is moved back correctly to a day of week
    testMethod static void testToPreviousDayOfWeek() {
        Datetime dt = Datetime.newInstance(2014, 3, 4);
        Datetime sunDt = DateUtil.toPreviousDayOfWeek(DateUtil.DayOfWeek.Sunday, dt);
        System.assertEquals(2, sunDt.day(),'Should be 2nd as thats the sunday in march-2014');
        System.assertEquals(dt.month(), sunDt.month());
        System.assertEquals(dt.year(), sunDt.year());
    }
    
    // Tests if a date is moved forward correctly to a day of week
    testMethod static void testToNextDayOfWeek() {
        Datetime dt = Datetime.newInstance(2014, 3, 4);
        Datetime sunDt = DateUtil.toNextDayOfWeek(DateUtil.DayOfWeek.Sunday, dt);
        System.assertEquals(9, sunDt.day(),'Should be 9th as thats the sunday in march-2014');
        System.assertEquals(dt.month(), sunDt.month());
        System.assertEquals(dt.year(), sunDt.year());
    }
    
    
    // Tests if a date is moved correctly to end of month
    testMethod static void testToEndOfMonth() {
        Datetime dt = Datetime.newInstance(2014, 3, 4);
        Datetime sunDt = DateUtil.toEndOfMonth(dt);
        System.assertEquals(31, sunDt.day(),'Should be 31st as thats the end of month in march-2014');
        System.assertEquals(dt.month(), sunDt.month());
        System.assertEquals(dt.year(), sunDt.year());
    }
    
    
    
}