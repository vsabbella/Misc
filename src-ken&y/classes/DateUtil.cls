public with sharing class DateUtil {
    public enum DayOfWeek {
        None, // Keeping it at ordinal zero, mostly of no use, but rest of the weekday's ordinal 
        // will be compatible with Apex Datetime api
        Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
    }
    
    // moves back till a day of week comes
	public static Datetime toPreviousDayOfWeek(DayOfWeek dow, Datetime fromDatetime) {
	    while ( fromDatetime.format('u') !=  String.valueOf(dow.ordinal()) ) {
        	fromDatetime = fromDatetime.addDays(-1); 
		}
		return fromDatetime;
	}

    // moves back till a day of week comes
	public static Datetime toNextDayOfWeek(DayOfWeek dow, Datetime fromDatetime) {
	    while ( fromDatetime.format('u') !=  String.valueOf(dow.ordinal()) ) {
        	fromDatetime = fromDatetime.addDays(1); 
		}
		return fromDatetime;
	}
	
    // Move to end of month in current date time
	public static Datetime toEndOfMonth(Datetime dt) {
	    Datetime result = dt.addDays( dt.day() -1 );
	    Integer daysInCurrMonth = Date.daysInMonth(dt.year(), dt.month());
	    return dt.addDays(daysInCurrMonth - dt.day());
	}

}