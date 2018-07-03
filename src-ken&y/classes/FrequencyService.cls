public with sharing class FrequencyService {
	
	public static final String FREQUENCY_PERIOD_DAY = 'Day(s)';
	public static final String FREQUENCY_PERIOD_WEEK = 'Week(s)';
	public static final String FREQUENCY_PERIOD_MONTH = 'Month(s)';
	public static final String FREQUENCY_PERIOD_QUARTER = 'Quarter(s)';
	public static final String FREQUENCY_PERIOD_ANNUAL = 'Year(s)';
	public static final String FREQUENCY_PERIOD_IMMEDIATE = 'Immediate';
	
	
	public class FrequencyServiceException extends exception{}
	
	public static Date nextBillingDate(String frequencyPeriod, Date applyToDate, Integer dateOn, Integer everyCount) {
		
		if(everyCount == null || frequencyPeriod == null || applyToDate == null) {
			system.debug(logginglevel.error,'exception---> '+everyCount +' '+frequencyPeriod +' '+ applyToDate);
			throw new FrequencyServiceException('FrequencyService - Arguments cannot be null');
		}
		
		Date finalDate = applyToDate;
		for(integer i =1; i<= everyCount; ++i)
			finalDate = nextBillingDate( frequencyPeriod,  finalDate,  dateOn);
		
		return finalDate;
	}
	
	private static Date nextBillingDate(String frequencyPeriod, Date applyToDate, Integer dateOn) {
		
		if(frequencyPeriod == FREQUENCY_PERIOD_DAY)
			return applyToDate.addDays(1);
		else if(frequencyPeriod == FREQUENCY_PERIOD_WEEK)
			return applyToDate.addDays(7);
		else if(frequencyPeriod == FREQUENCY_PERIOD_MONTH) {
			if(dateOn == 31)
				return applyToDate.addMonths(2).toStartOfMonth().addDays(-1);
			else {
				if(dateOn == 30 && applyToDate.month() == 2 && (applyToDate.day() == 29 || applyToDate.day() == 28)) //take care for feb
					return applyToDate.addMonths(2).toStartOfMonth().addDays(-2);
				else if(dateOn == 29 && applyToDate.month() == 2 && applyToDate.day() == 28)//take care for feb
					return applyToDate.addMonths(2).toStartOfMonth().addDays(-3);
			else
				return applyToDate.addMonths(1);
			}
				
		}else if(frequencyPeriod == FREQUENCY_PERIOD_QUARTER) {
			if(dateOn == 31)
				return applyToDate.addMonths(4).toStartOfMonth().addDays(-1);
			else {
				if(dateOn == 30 && applyToDate.month() == 2 && (applyToDate.day() == 29 || applyToDate.day() == 28)) //take care for feb
					return applyToDate.addMonths(4).toStartOfMonth().addDays(-2);
				else if(dateOn == 29 && applyToDate.month() == 2 && applyToDate.day() == 28)//take care for feb
					return applyToDate.addMonths(4).toStartOfMonth().addDays(-3);
			else
				return applyToDate.addMonths(3);
			}	
		}else if(frequencyPeriod == FREQUENCY_PERIOD_ANNUAL)
			return applyToDate.addYears(1);
		else if(frequencyPeriod == FREQUENCY_PERIOD_IMMEDIATE)
			return applyToDate; //KNDY-10459
		else {
			system.debug('throwing exception');
			throw new FrequencyServiceException('Frequency '+frequencyPeriod+' not defined.');
		}
	}
	
	public static Date previousBillingDate(String frequencyPeriod, Date applyToDate, Integer dateOn, Integer everyCount) {
		if(everyCount == null || frequencyPeriod == null || applyToDate == null) {
			system.debug('exception '+everyCount + frequencyPeriod + applyToDate);
			throw new FrequencyServiceException('FrequencyService - Arguments cannot be null');
		}
		Date finalDate = applyToDate;
		for(integer i =1; i<= everyCount; ++i)
			finalDate = previousBillingDate( frequencyPeriod,  finalDate,  dateOn);
		
		return finalDate;
	}
	
    
    private static Date previousBillingDate(String frequencyPeriod, Date applyToDate, Integer dateOn) {
		if(frequencyPeriod == FREQUENCY_PERIOD_DAY)
			return applyToDate.addDays(-1);
		else if(frequencyPeriod == FREQUENCY_PERIOD_WEEK)
			return applyToDate.addDays(-7);
		else if(frequencyPeriod == FREQUENCY_PERIOD_MONTH) {
			if(dateOn == 31)
				return applyToDate.toStartOfMonth().addDays(-1);
			else {
				if(dateOn == 30 && applyToDate.month() == 2 && (applyToDate.day() == 29 || applyToDate.day() == 28)) //take care for feb
					return applyToDate.toStartOfMonth().addDays(-2);
				else if(dateOn == 29 && applyToDate.month() == 2 && applyToDate.day() == 28)//take care for feb
					return applyToDate.toStartOfMonth().addDays(-3);
			else
				return applyToDate.addMonths(-1);
		}
		}
		else if(frequencyPeriod == FREQUENCY_PERIOD_QUARTER) {
			if(dateOn == 31)
				return applyToDate.addMonths(-2).toStartOfMonth().addDays(-1);
			else {
				if(dateOn == 30 && applyToDate.month() == 2 && (applyToDate.day() == 29 || applyToDate.day() == 28)) //take care for feb
					return applyToDate.addMonths(-2).toStartOfMonth().addDays(-2);
				else if(dateOn == 29 && applyToDate.month() == 2 && applyToDate.day() == 28)//take care for feb
					return applyToDate.addMonths(-2).toStartOfMonth().addDays(-3);
				else
					return applyToDate.addMonths(-3);
			}	
		}
		else if(frequencyPeriod == FREQUENCY_PERIOD_ANNUAL)
			return applyToDate.addYears(-1);
		else if(frequencyPeriod == FREQUENCY_PERIOD_IMMEDIATE)
			return applyToDate; //KNDY-10459
		else
			throw new FrequencyServiceException('Frequency '+frequencyPeriod+' not defined.');
	}
	
	 public static Date previousBillingDate(String frequencyPeriod, Date applyToDate) {
	 	return  null;
	 }
										  
	//gets a future date closes to fulfilDate thats greater than billingDate									  
	public static Date closestFutureBillingDate(Date fulfilDate, Date billingDate, String frequencyPeriod, Integer dateOn, Integer everyCount) {
		
		Date retDate = billingDate;
		while(fulfilDate > retDate) {
			 retDate = nextBillingDate(frequencyPeriod, retDate, dateOn, everyCount);
			system.debug('retDate '+retDate);
		}
		return retDate;
	}

	public static  boolean hasFullCycle(Date startDate, Date endDate, String frequencyPeriod, integer everyCount) {
		
		if(frequencyPeriod == FREQUENCY_PERIOD_DAY) {
			integer  cycle = startDate.daysBetween(endDate);
			return cycle/everyCount >= 1;
		} else if(frequencyPeriod == FREQUENCY_PERIOD_WEEK) {
			integer  cycle = startDate.daysBetween(endDate)/7;
			return cycle/everyCount >= 1;
		} else if(frequencyPeriod == FREQUENCY_PERIOD_MONTH) {
			integer  cycle = startDate.monthsBetween(endDate);
			return cycle/everyCount >= 1;
		}else if(frequencyPeriod == FREQUENCY_PERIOD_QUARTER) {
			integer  cycle = startDate.monthsBetween(endDate) /3;
			return cycle/everyCount >= 1;
		}else if(frequencyPeriod == FREQUENCY_PERIOD_ANNUAL) {
			integer  cycle = startDate.monthsBetween(endDate)/12;
			return cycle/everyCount >= 1;
		}else {
			return false;
		}
		
		
	}

}