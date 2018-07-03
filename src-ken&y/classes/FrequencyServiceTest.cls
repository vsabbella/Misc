@isTest
private class FrequencyServiceTest {
	
	
	//TESTING FOR DAYS
	static testMethod void NextBilling_1Day() {
		
		Date result = FrequencyService.nextBillingDate('Day(s)', Date.newInstance(2016,3,31), 1, 1);
		system.assertEquals(Date.newInstance(2016,4,1), result,'WHY!! result is '+result);
	}
	
	static testMethod void PreviousBilling_1Day() {
		
		Date result = FrequencyService.previousBillingDate('Day(s)', Date.newInstance(2016,4,1), 1, 1);
		system.assertEquals(Date.newInstance(2016,3,31), result,'WHY!! result is '+result);
	}
	
	
	static testMethod void NextBilling_3Days() {
		
		Date result = FrequencyService.nextBillingDate('Day(s)', Date.newInstance(2016,3,31), 1, 3);
		system.assertEquals(Date.newInstance(2016,4,3), result,'WHY!! result is '+result);
	}
	
	//TESTING FOR WEEKS
	static testMethod void NextBilling_1Week() {
		
		Date result = FrequencyService.nextBillingDate('Week(s)', Date.newInstance(2016,3,31), 1, 1);
		system.assertEquals(Date.newInstance(2016,4,7), result,'WHY!! result is '+result);
	}
	
	
	static testMethod void NextBilling_3Weeks() {
		
		Date result = FrequencyService.nextBillingDate('Week(s)', Date.newInstance(2016,3,31),1, 3);
		system.assertEquals(Date.newInstance(2016,4,21), result,'WHY!! result is '+result);
	}
	
	//TESTING FOR YEARS
	static testMethod void NextBilling_1Year() {
		
		Date result = FrequencyService.nextBillingDate('Year(s)', Date.newInstance(2016,3,31), 1, 1);
		system.assertEquals(Date.newInstance(2017,3,31), result,'WHY!! result is '+result);
	}
	
	
	static testMethod void NextBilling_3Years() {
		
		Date result = FrequencyService.nextBillingDate('Year(s)', Date.newInstance(2016,3,31),1, 3);
		system.assertEquals(Date.newInstance(2019,3,31), result,'WHY!! result is '+result);
	}
	
	
    
    //TESTING FOR MONTHS
    static testMethod void NextBilling_1Month() {
		
		Date result = FrequencyService.nextBillingDate('Month(s)', Date.newInstance(2016,3,30), 1, 1);
		system.assertEquals(Date.newInstance(2016,4,30), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_1Month_dateOn31() {
		
		Date result = FrequencyService.nextBillingDate('Month(s)', Date.newInstance(2016,2,29), 31, 1);
		system.assertEquals(Date.newInstance(2016,3,31), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_1Month_dateOn30() {
		
		Date result = FrequencyService.nextBillingDate('Month(s)', Date.newInstance(2016,2,29), 30, 1);
		system.assertEquals(Date.newInstance(2016,3,30), result,'WHY!! result is '+result);
	}
	static testMethod void NextBilling_1Month_dateOn29() {
		
		Date result = FrequencyService.nextBillingDate('Month(s)', Date.newInstance(2016,1,31), 29, 1);
		system.assertEquals(Date.newInstance(2016,2,29), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_1Month_dateOn28() {
		
		Date result = FrequencyService.nextBillingDate('Month(s)', Date.newInstance(2015,1,31), 29, 1);
		system.assertEquals(Date.newInstance(2015,2,28), result,'WHY!! result is '+result);
	}
	
	
	static testMethod void NextBilling_3Months() {
		
		Date result = FrequencyService.nextBillingDate('Month(s)', Date.newInstance(2016,3,30), 1, 3);
		system.assertEquals(Date.newInstance(2016,6,30), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_3Months_dateOn31() {
		
		Date result = FrequencyService.nextBillingDate('Month(s)', Date.newInstance(2016,2,29), 31, 3);
		system.assertEquals(Date.newInstance(2016,5,31), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_3Months_dateOn30() {
		
		Date result = FrequencyService.nextBillingDate('Month(s)', Date.newInstance(2016,2,29), 30, 3);
		system.assertEquals(Date.newInstance(2016,5,30), result,'WHY!! result is '+result);
	}
	static testMethod void NextBilling_3Months_dateOn29() {
		
		Date result = FrequencyService.nextBillingDate('Month(s)', Date.newInstance(2015,11,30), 31, 3);
		system.assertEquals(Date.newInstance(2016,2,29), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_3Months_dateOn28() {
		
		Date result = FrequencyService.nextBillingDate('Month(s)', Date.newInstance(2014,11,30), 31, 3);
		system.assertEquals(Date.newInstance(2015,2,28), result,'WHY!! result is '+result);
	}
	
	//TESTING FOR QUARTERS
    static testMethod void NextBilling_1Quarter() {
		
		Date result = FrequencyService.nextBillingDate('Quarter(s)', Date.newInstance(2016,3,30), 1, 1);
		system.assertEquals(Date.newInstance(2016,6,30), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_1Quarter_dateOn31() {
		
		Date result = FrequencyService.nextBillingDate('Quarter(s)', Date.newInstance(2016,2,29), 31, 1);
		system.assertEquals(Date.newInstance(2016,5,31), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_1Quarter_dateOn30() {
		
		Date result = FrequencyService.nextBillingDate('Quarter(s)', Date.newInstance(2016,2,29), 30, 1);
		system.assertEquals(Date.newInstance(2016,5,30), result,'WHY!! result is '+result);
	}
	static testMethod void NextBilling_1Quarter_dateOn29() {
		
		Date result = FrequencyService.nextBillingDate('Quarter(s)', Date.newInstance(2015,11,30), 31, 1);
		system.assertEquals(Date.newInstance(2016,2,29), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_1Quarter_dateOn28() {
		
		Date result = FrequencyService.nextBillingDate('Quarter(s)', Date.newInstance(2014,11,30), 31, 1);
		system.assertEquals(Date.newInstance(2015,2,28), result,'WHY!! result is '+result);
	}
	
	
	static testMethod void NextBilling_3Quarters() {
		
		Date result = FrequencyService.nextBillingDate('Quarter(s)', Date.newInstance(2016,3,30), 1, 3);
		system.assertEquals(Date.newInstance(2016,12,30), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_3Quarters_dateOn31() {
		
		Date result = FrequencyService.nextBillingDate('Quarter(s)', Date.newInstance(2016,2,29), 31, 3);
		system.assertEquals(Date.newInstance(2016,11,30), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_3Quarters_dateOn30() {
		
		Date result = FrequencyService.nextBillingDate('Quarter(s)', Date.newInstance(2016,2,29), 30, 3);
		system.assertEquals(Date.newInstance(2016,11,30), result,'WHY!! result is '+result);
	}
	static testMethod void NextBilling_3Quarters_dateOn29() {
		
		Date result = FrequencyService.nextBillingDate('Quarter(s)', Date.newInstance(2015,5,31), 31, 3);
		system.assertEquals(Date.newInstance(2016,2,29), result,'WHY!! result is '+result);
	}
	
	static testMethod void NextBilling_3Quarters_dateOn28() {
		
		Date result = FrequencyService.nextBillingDate('Quarter(s)', Date.newInstance(2014,5,31), 31, 3);
		system.assertEquals(Date.newInstance(2015,2,28), result,'WHY!! result is '+result);
	}
}