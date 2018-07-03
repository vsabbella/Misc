/** 
 * @description code best practices that are also useful
 */
global with sharing class KSE {
	
	public static final string PAYMENT_TERM_DUE_DAYS = 'Due Days';
    public static final string PAYMENT_TERM_DUE_DAY_OF_MONTH = 'Due Day Of Month';
	public class KSEException extends Exception{}
	// This class is used to perform sorting similar to 'ORDER BY' in soql queries 
	// without having to query the same records multiple times for different sorting order.
	public class Sortable {
		List<SObject> sObjectsToSort = new List<SObject>();
		List<String> fieldOrder = new List<String>();
		Map<String, String> fieldSortMethod = new Map<String, String>();
		
		public Sortable(List<SObject> sObjectsToSort){
			this.sObjectsToSort = sObjectsToSort;	
		}
		
		public void addSortField(String fieldName, String sortMethod){
			fieldOrder.add(fieldName);
			fieldSortMethod.put(fieldName, sortMethod);
		}
		
		public List<sObject> getSortedList(){
			for(Integer i = fieldOrder.size()-1; i >= 0; i--){
				KSE.sortList(sObjectsToSort, fieldOrder[i], fieldSortMethod.get(fieldOrder[i]));
			}
			return sObjectsToSort;
		}
	}
	
	// Method to check if the difference in given number is greater than threshold of 0.000001
	public static boolean isEqualDecimal(Decimal a, decimal b){
		Decimal compareNumber = 0.000001;
		Decimal difference;
        if ( a == b ) return true; // not different
        
		if((a > 0 && b > 0) || (a < 0 && b < 0)){
			//system.debug(logginglevel.info,'a:'+ a +'b:'+ b);
			difference = Math.abs(a) - Math.abs(b);
		}else{
			return false;  // are different
		}
		//system.debug(logginglevel.info,'difference:'+Math.abs(difference)+'compareNumber:'+compareNumber);
		if(Math.abs(difference) < compareNumber){
			//system.debug(logginglevel.info,'Inside  if - false');
			return true;
		}else{
			//system.debug(logginglevel.info,'Inside else - true');
			return false;
		}
	}
	
    /** 
     * @description compare 2 datetimes, and see if the absolute value difference is within a threshold.  
     * useful for test method assertions where the processing takes some time and system.now() shifts a bit from the original value in the process
     */
    public static dateTimeCloseResult areDateTimesClose(Datetime time1, Datetime time2) {		
		return  areDateTimesClose( time1,  time2, 30);
    } 
    
    public static dateTimeCloseResult areDateTimesClose(Datetime time1, Datetime time2, integer intSecondThreshold) {		
		if(intSecondThreshold == null ||  !((Object) intSecondThreshold instanceOf Integer) || intSecondThreshold < 0)
			throw new KSEException('Need to specify a valid positive integer'); //the amount of seconds we are willing to accept as "close enough".  the processing time it takes to get through some method that ultimately sets a time value.
		
		Boolean bCloseEnough = false;		
		Integer absDiffSeconds;
		if ((time1 != null) && (time2 != null)) {
			absDiffSeconds = Math.abs((time1.getTime()/1000) - (time2.getTime()/1000)).intValue(); //convert millisecs to secs, abs value of difference
			if (absDiffSeconds <= intSecondThreshold) {
				bCloseEnough = true;	
			}
		}		
		return new dateTimeCloseResult(bCloseEnough,absDiffSeconds,intSecondThreshold,time1,time2);
    } 
    
    //custom apex class to hold the return data from the areDateTimesClose method
	public class dateTimeCloseResult {
		public Boolean bCloseEnough 	{get; set;}
		public Integer intDifference 	{get; set;}
		public Integer intThreshold 	{get; set;}
		public Datetime time1 			{get; set;}
		public Datetime time2 			{get; set;}		
		public dateTimeCloseResult(Boolean bce, Integer intD, Integer intT, Datetime t1, Datetime t2) {
			bCloseEnough = bce;
			intDifference = intD;
			intThreshold = intT;
			time1 = t1;
			time2 = t2;
		}	
	}    
   
    /** 
     * @description used for batch jobs without process job records, returns a default of 200 if entry is not found in the custom setting
     */
    public static Integer getBatchSize(String batchName) {
		
		Integer batchSize = 200; 

		Integer minValue = 1;   
		Integer maxValue = 2000; 
		
		Configuration__c c = Configuration__c.getValues(batchName);
		//attempt to parse the string config value into an integer and make sure it is between min/max
		//if not we are just going to use the default
		if (c != null) {
			Integer configBatch;
			try {configBatch = Integer.valueOf(c.Value__c);} catch (Exception e) {}
			if (configBatch != null) {
				if ( (configBatch >= minValue) && (configBatch <= maxValue) ) {
					batchSize = configBatch;
				}
			}
		}
		return batchSize;				
	}    
   
    /** 
     * @description generate a 15 char random/unique string of numbers for test fields that need unique values.  has time and random component.
     */
    public static String getUniqueNumberString() {		
		String sUnique;
		String ts = String.valueOf(System.currentTimeMillis()); //1394732895417, 13 chars
		Double dr = math.random();		
		String sr = String.valueOf(dr); //0.7732302227147324
		sUnique = ts.right(10) + sr.right(5);
		return sUnique;
    }

    /* replace arg1 with arg2, if arg1 is null 
     * this is to keep the code easily readable
     */
        public static string ifNull(string arg1,string arg2) {
          string result = arg1;
          if (arg1==null ) { result = arg2; }
          return result;
        }
    
    
    /** 
     * @description determine if a field is changing, used in triggers to keep the code 
     * easily readable 
     */
    public static Boolean isFieldChanging(String pStringField, Sobject obj, Map<id,Sobject>oldMap) {

        //  to protect against oldMap is null 
        if (oldMap == null  ) { 
            // this is an insert 
            return obj.get(pStringField) !=null;
        }
        
        // oldMap is not null, use it
        return (   obj.get(pStringField) != oldMap.get(obj.Id ).get(pStringField)      );
    }
    /** 
     * @description determine if a field is null or empty 
     */
    public static Boolean isFieldEmpty(String pStringField, Sobject obj ) {
        return ( obj.get(pStringField) == null || obj.get(pStringField)=='' ); 
    }
    
    /** 
     * @description determine if an object is null or empty 
     */
    public static Boolean isEmpty( Object o) { 
        return ( o == null || o == '' ); 
    }

	/* Returns a map of all business hours in the organization
	*	K: Business Hours Id.
	*	V: Business Hours Record.
	*/
	
	private static Map<Id, BusinessHours> businessHoursMap {
		get{
			if(businessHoursMap == null){

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('BusinessHours', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','TimeZoneSidKey'
        });
        soql.setWhereClause('isActive = true');
        businessHoursMap = new Map<Id, BusinessHours>((list<BusinessHours>)Database.query(soql.getQuery())); 



			}
			return businessHoursMap;
		}	
		set;
	}
	
	public static List<Holiday> holidays {
        get{
            if(holidays == null){

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Holiday', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','ActivityDate','RecurrenceType','RecurrenceDayOfMonth','RecurrenceMonthOfYear'
        });
        //soql.setWhereClause('');
        holidays = Database.query(soql.getQuery());



            }
            
            return holidays;
        }
    }
    
    /** 
     * @description  build a Date that is LeadTime days in the future taking into account Bussiness hours
     * for this orginization 
     * @return Date in the future ( reqDate + LeadTime ) 
     */
    public static Date calculateStartDate(Date currentDate,Integer leadTime, Id businessHoursId) {
        Date startDate;
        DateTime startDateTime;
        
        if(currentDate == null){
        	return null;
        }
        
        if(String.isBlank(businessHoursId)){
        	leadTime = (leadTime == null ? 0 : leadTime);
            startDate = currentDate.addDays(-leadTime);
            return startDate;
        }
         
        // Set time to midnight     
        startDateTime = DateTime.newinstance(currentDate.year(), currentDate.month(), currentDate.day(), 0, 0, 0);
		
		// KNDY-5271: Convert the previous start date into the calendar's time zone
        TimeZone calendarTZ = TimeZone.getTimeZone(businessHoursMap.get(businessHoursId).TimeZoneSidKey);
		TimeZone userTZ = UserInfo.getTimeZone();
        startDateTime = KSE.convertTimeZones(startDateTime, userTZ,calendarTZ);
	        
        // Find the business day that is after leadTime days
        if (leadTime != null && leadTime != 0){
            for (Integer i = leadTime; i > 0; i--){
            	// Adds one day at a time and skips to the next working day.
            	startDateTime = startDateTime.addDays(-1);
            	while(isBusinessDay(businessHoursId, startDateTime) == false){
    	    		startDateTime = startDateTime.addDays(-1);
    	    	}
            }
        }else{
        	while(isBusinessDay(businessHoursId, startDateTime) == false){
	    		startDateTime = startDateTime.addDays(-1);
	    	}
        }
        
        startDate = Date.newInstance(startDateTime.year(), startDateTime.month(), startDateTime.day());    
        return startDate;
    }

    /**
     * @description  build a Date that is LeadTime days in the future taking into account Bussiness hours
     * for this orginization 
     * @return Date in the future ( reqDate + LeadTime ) 
     */
    public static Date calculateEndDate(Date currentDate, Integer leadTime, Id businessHoursId) {
        Date endDate;
        DateTime endDateTime;
        
        if(currentDate == null){
        	return null;
        }
        
        if(String.isBlank(businessHoursId)){
        	leadTime = (leadTime == null ? 0 : leadTime);
            endDate = currentDate.addDays(leadTime);
            return endDate;
        }
         
        // Set time to midnight     
        endDateTime = DateTime.newinstance(currentDate.year(), currentDate.month(), currentDate.day(), 0, 0, 0);
		
		// KNDY-5271: Convert the previous start date into the calendar's time zone
        TimeZone calendarTZ = TimeZone.getTimeZone(businessHoursMap.get(businessHoursId).TimeZoneSidKey);
		TimeZone userTZ = UserInfo.getTimeZone();
        endDateTime = KSE.convertTimeZones(endDateTime, userTZ,calendarTZ);
	        
        // Find the business day that is after leadTime days
        if (leadTime != null && leadTime != 0){
            for (Integer i = leadTime; i > 0; i--){
            	// Adds one day at a time and skips to the next working day.
            	endDateTime = endDateTime.addDays(1);
            	while(isBusinessDay(businessHoursId, endDateTime) == false){
    	    		endDateTime = endDateTime.addDays(1);
    	    	}
            }
        }else{
        	while(isBusinessDay(businessHoursId, endDateTime) == false){
	    		endDateTime = endDateTime.addDays(1);
	    	}
        }
        
        endDate = Date.newInstance(endDateTime.year(), endDateTime.month(), endDateTime.day());    
        return endDate;
    }
	
	/**
     * @description  Build a date that is LeadTime days in the past and has open Bussiness hours
     *
     * @return Date in the past ( currentDate - LeadTime ) 
     */
    public static Date previousBusinessDate(Date currentDate, Integer leadTime, Id businessHoursId) {
        Date previousStartDate;
        
		if(currentDate == null){
			return null;
		}
		
        if(String.isBlank(businessHoursId)){
            leadTime = (leadTime == null ? 0 : leadTime);
            previousStartDate = currentDate.addDays(-leadTime);
        }else{
        	// DateTime calculations are made in GMT. previousStartDateTime is in GMT.
	        DateTime previousStartDateTime = DateTime.newInstance(currentDate.year(), currentDate.month(), currentDate.day(), 0, 0, 0);// DateTime.newInstance(currentDate, DateTime.now().time());
	        
	        // Find the business day that is behind leadTime days 
	        if (leadTime != null && leadTime != 0){
	        	previousStartDateTime = previousStartDateTime.addDays(-leadTime);
	        }
	        
	        // KNDY-5271: Convert the previous start date into the calendar's time zone
	        TimeZone calendarTZ = TimeZone.getTimeZone(businessHoursMap.get(businessHoursId).TimeZoneSidKey);
			TimeZone userTZ = UserInfo.getTimeZone();
	        previousStartDateTime = KSE.convertTimeZones(previousStartDateTime, userTZ, calendarTZ);

	        // Make sure that the date is a business day.
	        // If the date is not a working day, go back in time by one day at a time to get
	        // the business day in the past.
	        while(isBusinessDay(businessHoursId, previousStartDateTime) == false){	
	    		previousStartDateTime = previousStartDateTime.addDays(-1);
	    	}
	        
	        previousStartDate = previousStartDateTime.date();
	    }
        
       	return previousStartDate;
    }
    
    /**
     * @description  Build a date that is LeadTime days in the future and has open Bussiness hours
     * 
     * @return Date in the future ( currentDate + LeadTime ) 
     */
    public static Date nextBusinessDate(Date currentDate, Integer leadTime, Id businessHoursId) {
        Date nextStartDate;
        
		if(currentDate == null){
			return null;
		}
		
        if(String.isBlank(businessHoursId)){
        	leadTime = (leadTime == null ? 0 : leadTime);
            nextStartDate = currentDate.addDays(leadTime);
        }else{
        
	        // DateTime calculations are made in GMT. nextStartDateTime is in GMT.
	        DateTime nextStartDateTime = DateTime.newInstance(currentDate.year(), currentDate.month(), currentDate.day(), 0, 0, 0);
			
	        // Find the business day that is ahead leadTime days 
	        if (leadTime != null && leadTime != 0){
	        	nextStartDateTime = nextStartDateTime.addDays(leadTime);
	        }
	        
	        // KNDY-5271: Convert the previous start date into the calendar's time zone
	        TimeZone calendarTZ = TimeZone.getTimeZone(businessHoursMap.get(businessHoursId).TimeZoneSidKey);
			TimeZone userTZ = UserInfo.getTimeZone();
	        nextStartDateTime = KSE.convertTimeZones(nextStartDateTime, userTZ, calendarTZ);
	        
	        // Make sure that the date is a business day.
	        // We could just use BusinessHours.nextStartDate(businessHoursId, nextStartDateTime), 
	        // but using a loop instead to make it consistent with the previousStartDate method logic.
	    	while(isBusinessDay(businessHoursId, nextStartDateTime) == false){
	    		nextStartDateTime = nextStartDateTime.addDays(1);
	    	}
	    	
	       	nextStartDate = nextStartDateTime.date();
        }
        
        return nextStartDate;
    }
 	
 	// Check if the given date/datetime falls on a day with business hours and not a holiday.
 	// There is no way currently to get the association between holidays and business hours in force.com
 	// So holidays are applied for all the business hours in the system regardless of the business hours they 
 	// are associated to in the user interface.
 	// 
 	// You can find the full code at: https://github.com/redargyle/BusinessHoursMath/blob/master/BusinessHoursMath.cls
 	
 	public static Boolean isBusinessDay(Id businessHoursId, Date dateToCheck) {
        return isBusinessDay(businessHoursId, DateTime.newInstance(dateToCheck, DateTime.now().time()));
    }
    
 	public static Boolean isBusinessDay(Id businessHoursId, DateTime datetimeToCheck){
        Date dateToCheck = datetimeToCheck.date();
        
        for(Holiday holiday : holidays) {
            if(holiday.RecurrenceType == null) {//no recurence
                if(holiday.ActivityDate == dateToCheck) {
                    return false;
                }
            } else if(holiday.RecurrenceType == 'RecursYearly') {
                Integer dayOfMonth = dateToCheck.day();
                Integer monthOfYear = dateToCheck.month();
                Integer holidayDayOfMonth = holiday.RecurrenceDayOfMonth;
                Integer holidayMonthOfYear;

                //big if statement to translate month to day
                if(holiday.RecurrenceMonthOfYear == 'January') {
                    holidayMonthOfYear = 1;
                } else if(holiday.RecurrenceMonthOfYear == 'February') {
                    holidayMonthOfYear = 2;
                } else if(holiday.RecurrenceMonthOfYear == 'March') {
                    holidayMonthOfYear = 3;
                } else if(holiday.RecurrenceMonthOfYear == 'April') {
                    holidayMonthOfYear = 4;
                } else if(holiday.RecurrenceMonthOfYear == 'May') {
                    holidayMonthOfYear = 5;
                } else if(holiday.RecurrenceMonthOfYear == 'June') {
                    holidayMonthOfYear = 6;
                } else if(holiday.RecurrenceMonthOfYear == 'July') {
                    holidayMonthOfYear = 7;
                } else if(holiday.RecurrenceMonthOfYear == 'August') {
                    holidayMonthOfYear = 8;
                } else if(holiday.RecurrenceMonthOfYear == 'September') {
                    holidayMonthOfYear = 9;
                } else if(holiday.RecurrenceMonthOfYear == 'October') {
                    holidayMonthOfYear = 10;
                } else if(holiday.RecurrenceMonthOfYear == 'November') {
                    holidayMonthOfYear = 11;
                } else if(holiday.RecurrenceMonthOfYear == 'December') {
                    holidayMonthOfYear = 12;
                }
                if((dayOfMonth == holidayDayOfMonth) && (monthOfYear == holidayMonthOfYear))
                    return false;
            }
        }
        
        return datetimeToCheck.isSameDay(BusinessHours.nextStartDate(businessHoursId, datetimeToCheck)); //return the business day status
    }
    
 	public static DateTime convertTimeZones(DateTime originalDateTime, TimeZone fromZone, TimeZone toZone){
 		DateTime convertedDateTime ;
 		
 		Integer fromOffset = fromZone.getOffSet(originalDateTime);
 		Integer toOffset = toZone.getOffSet(originalDateTime);
 		
 		Integer correction = fromOffset - toOffset;
 		
 		convertedDateTime = originalDateTime.addMinutes(correction / (1000 * 60));
 		
 		return convertedDateTime;
 	}
 	
 	/**
 	*	@description Return the time difference in hours between the user locale and the GMT time.
 	*
 	*/
 	public static Integer getTimeDifference(){
 		Date dateToday = system.today();
        DateTime dateTodayTime = DateTime.newInstance(dateToday.year(), dateToday.month(), dateToday.day(), 0, 0, 0);
        Integer timeDifference = dateTodayTime.hourGmt() - dateTodayTime.hour();
        
        return timeDifference;
 	}
 	
 	/**
 	*	@description Return the day of the week the given date falls on.
 	*	Numbering starts from 0 which represents a Sunday.
 	*	Sunday - 0, Monday - 1, Tuesday - 2, Wednesday - 3, Thursday - 4, Friday - 5, Saturday - 6
 	*/
 	public static Integer dayOfTheWeek(Date futureDate){
 		Date knownSunday = Date.newInstance(1900, 1, 7);
    	Integer dayOfTheWeek = Math.mod( knownSunday.daysBetween(futureDate), 7);
    	return dayOfTheWeek;
 	}
 	
    /**
     * @description  Send single email message
     * Parameters: conId -> User/contact id to send email to the email field of User/Contact
     *            templateId -> Template id which is used to send email
     *            whatId -> Related id which is used in email template
     */
    public static void sendEmail(String conID, String templateID, String whatID) {
        Messaging.SingleEmailMessage singleRequest = new Messaging.SingleEmailMessage();
        singleRequest.setTargetObjectId(conID);
        singleRequest.setTemplateId(templateID);
        singleRequest.setWhatId(whatID);
        singleRequest.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{singleRequest});
    }
    public static void sendEmailAfterBatchCompletion(string templateName) {
        Try {        

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('EmailTemplate', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','name'
        });
        soql.setWhereClause('DeveloperName = :templateName');
        soql.setLimit(1);
        EmailTemplate objEmail = Database.query(soql.getQuery());



            KSE.sendEmail(UserInfo.getUserId(), objEmail.Id, null);
        }
        Catch (Exception ex) {}
    }
    
    global static void sendEmailBatchCompletion(string msg) {
    	sendEmailBatchCompletion(msg,null);
    }  
    
    global static void sendEmailBatchCompletion(string msg, string subject) {
    	if(subject == null || subject == '') {
    		subject = msg;
    	}
    	
    	Messaging.SingleEmailMessage singleRequest = new Messaging.SingleEmailMessage();
        singleRequest.setTargetObjectId(UserInfo.getUserId());
        singleRequest.setSaveAsActivity(false);
        singleRequest.setSubject(subject);
        singleRequest.setHtmlBody('Hi ' +UserInfo.getName() +',<br /><br/>' +msg +'.<br /><br /><br />Thanks');      
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{singleRequest});
    }  
    
    
    /**
     * @description pull defaults for a given item, return in a JSON payload to the vf page
     */ 
    @RemoteAction
    global static Item__c getItemJSONRecord(String item_name, Id companyId, Id facilityid, Date activeStandardCostDate) {
        // extend this list as we want to autopopulate the line defaults
        /*string query = 'Select id,Name,Description__c,Purchasing_UOM__c, '+
                'Source__c, Non_Inventory__c, Purchasing_UOM__r.Name,Purchasing_UOM__r.Id, Stocking_UOM__c, Stocking_UOM__r.Name  '+
                ' from Item__c ';*/
                
        item_name = String.escapeSingleQuotes(item_name);
        Item__c item; 
        
        String whereClause = '';
        
	    SOQLUtil soql = new SOQLUtil('Item__c');
	    soql.addFields(new Set<String>{'id', 'Name', 'Description__c', 'Purchasing_UOM__c', 'Source__c', 'Non_Inventory__c',
	    								 'Purchasing_UOM__r.Name', 'Purchasing_UOM__r.Id', 'Stocking_UOM__c', 'Stocking_UOM__r.Name'});
	     
        try {
        	whereClause = 'Name = \''+item_name +'\' Limit 1 ';
        	soql.setWhereClause(whereClause); 
        	item = Database.query(soql.getQuery());                  
        } catch ( System.Queryexception e ) {
            string term = item_name + '%';
            whereClause = 'Name like \''+ term +'\' Limit 1 ';
            soql.setWhereClause(whereClause); 
        	item = Database.query(soql.getQuery()); 
        }
          
        return item;  // returns as JSON
    } 
    
    @RemoteAction
    global static Item__c getItemJSON(String item_name) {
        // extend this list as we want to autopopulate the line defaults
        /*string query = 'Select id,Name,Description__c,Purchasing_UOM__c, '+
                'Source__c, Purchasing_UOM__r.Name,Purchasing_UOM__r.Id, Stocking_UOM__c, Stocking_UOM__r.Name  '+
                ' from Item__c ';*/
        item_name = String.escapeSingleQuotes(item_name);
        Item__c item;
        
        String whereClause = '';
        
	    SOQLUtil soql = new SOQLUtil('Item__c');
	    soql.addFields(new Set<String>{'id', 'Name', 'Description__c', 'Purchasing_UOM__c', 'Source__c', 'Purchasing_UOM__r.Name', 'Purchasing_UOM__r.Id', 'Stocking_UOM__c', 'Stocking_UOM__r.Name'});
	     
        try {
        	whereClause = 'Name = \''+item_name +'\' Limit 1 ';
        	soql.setWhereClause(whereClause); 
        	item = Database.query(soql.getQuery());                  
        } catch ( System.Queryexception e ) {
            string term = item_name + '%';
            whereClause = 'Name like \''+ term +'\' Limit 1 ';
            soql.setWhereClause(whereClause); 
        	item = Database.query(soql.getQuery()); 
        }
        
        return item;  // returns as JSON
    } 
    
    public KSE(Apexpages.standardController c){} // allow this class to be a controller extension

    /** 
     * @description add two numbers, return the result, account for nulls that may be passed
     */
    public static decimal addQuantityToField( decimal a, decimal b ) {   
        if (a!=null & b != null ) a = a + b; 
        else if ( a != null && b == null ) a = a;    
        else if ( a == null && b != null ) a = b;
        else a = 0;
        return a;
    }
    
    /** 
     * @description add two numbers, return the result, account for nulls that may be passed
     */
    public static decimal subtractDecimals( decimal a, decimal b ) {   
        if (a!=null & b != null ) a = a - b; 
        else if ( a != null && b == null ) a = a;    
        else if ( a == null && b != null ) a = -b; // KNDY-15678
        else a = 0;
        return a;
    }
    
    global static String Namespace { get {
        if ( Namespace != null ) return Namespace;

   		//Security review, this query needs to run in system mode.  Can't use SOQLUtil due to circular reference.
   		ApexClass ac = [SELECT NameSpacePrefix FROM ApexClass WHERE Name = 'KSE' limit 1];

        Namespace = ac.NameSpacePrefix != null ? ac.NameSpacePrefix : '';
        return Namespace;
    } private set; }
    
    global static String NamespaceUU { get { return  Namespace != '' ? Namespace+'__' : '' ;    } }
    
    public static String FieldUsedtoReleasePO { get {
    	if (FieldUsedtoReleasePO != null)
    		return FieldUsedtoReleasePO;

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Configuration__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Value__c'
        });
        soql.setWhereClause('Name = \'Contract Release Field\'');
        soql.setLimit(1);
        List<Configuration__c> rf = Database.query(soql.getQuery());



		if (rf.size() == 0)
			FieldUsedtoReleasePO = 'Available_Quantity__c';
		else
			FieldUsedtoReleasePO = rf[0].Value__c;
    	return FieldUsedtoReleasePO;
    } private set ; }
    
    public static Map<String, Source_Document_Approval__c> sourceDocumentApprovalMap = null; 

    public static Map<String, Source_Document_Approval__c> getSourceDocumentApprovals() {
        if (sourceDocumentApprovalMap == null) {
            sourceDocumentApprovalMap = Source_Document_Approval__c.getAll();
        }
        system.debug('sourceDocumentApprovalMap--'+sourceDocumentApprovalMap);
        return sourceDocumentApprovalMap; 
    }
    
    
        // actually this map contains all record types in this org...  
    private static  Map<String,RecordType> privateRTDevNameMap = null;
    
    private static Map<String,RecordType> getRecordTypeMap() { 
        // ensure that the below query is only performed once
        if ( privateRTDevNameMap == null ) {
            // objectName may already have the namespace applied, check for that

            privateRTDevNameMap = new Map<String,RecordType>(); 
	        /*
	        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
	        */
	        SOQLUtil soql = new SOQLUtil('RecordType', true); //enforceFLS=true, running in user mode
	        soql.addFields(new set<string>{
	            'DeveloperName','sObjectType','Id'
	        });
	        soql.setWhereClause('isActive=true');

	        for( RecordType rt: Database.query(soql.getQuery())){
                privateRTDevNameMap.put( rt.sObjectType + rt.DeveloperName, rt);
            }
        }
        return privateRTDevNameMap;
    }
    
    global static Map<String,String> RecordTypeDevNameMap(string objectName) {
        // build the return map from the static map    
        map<String,String> ret =  new map<String,String>();
        for (RecordType rt: getRecordTypeMap().values() ) { 
            if ( rt.sObjectType == NamespaceUU + objectName) {
                ret.put( rt.DeveloperName, rt.Id );
            }
        }
        return ret;
    }
  
    /** 
     * @description loop over a list of sobjecs, return a set of the ID's that we can use in a query, or records, or..
     */
    public static set<id> grepIdSetFromList( List<sobject> records ) {
        set<id> ret = new set<id>(); 
        for(sObject s : records) { ret.add( s.id); } 
        return ret;
    }

    public static set<id> grepRelatedIdSetFromList( List<sobject> records , string fieldtogather) {        
        return grepRelatedIdSetFromList(records, fieldtogather, 
            false // passing this as false, as many existing code might be impacted by excluding nulls
            );
    }

    public static set<id> grepRelatedIdSetFromList( List<sobject> records , string fieldtogather, boolean excludeNulls) {
        set<id> ret = new set<id>(); 
        for(sObject s : records) { 
        	
        	Id idVar = (Id)AccountingRuleService.getValue( fieldtogather, s);
        	
            if (!excludeNulls || idVar != null) {
                ret.add( (id) idVar ); 
            }
        } 
        return ret;
    }
    
    public static list<sobject> grep( List<sobject> records , string field, string value) {
        list<sobject> ret = new list<sobject>(); 
        for(sObject s : records) { if ( s.get(field) == value) ret.add( s ); } 
        return ret;
    }

    public static list<sobject> grep( List<sobject> records , string field, set<string> values) {
        list<sobject> ret = new list<sobject>();
        for(sObject s : records) { if ( values.contains( String.valueOf(s.get(field))) ) ret.add( s ); }
        return ret;
    }
    
    public static list<sobject> grep( List<sobject> records , string field, boolean value) {
        list<sobject> ret = new list<sobject>(); 
        for(sObject s : records) { if ( s.get(field) == value) ret.add( s ); } 
        return ret;
    }
    
    public static list<sobject> filter( List<sobject> records , Schema.SObjectType value ) {
        list<sobject> ret = new list<sobject>(); 
        for(sObject s : records) { if ( s.getSObjectType() == value) ret.add( s ); } 
        return ret;
    }
    
    //AR-165
    public static list<SObject> grepListFromMap( map<Id,SObject> mapSobject , set<id> recordIds)
    {
    	list<sobject> ret = new list<sobject>(); 
    	for(Id recId : recordIds)
    		if(mapSobject.containsKey(recId))
    			ret.add(mapSobject.get(recId));
    	return ret;
    }
    
    //KNDY-8182 If recordIds is null then just extract all the list values in a single list 
    public static list<SObject> grepListFromMap( map<Id,list<SObject>> mapSobject , set<id> recordIds)
    {
    	list<sobject> ret = new list<sobject>(); 
    	if(recordIds != null && !recordIds.isEmpty()) {
    		for(Id recId : recordIds)
    		if(mapSobject.containsKey(recId))
    			ret.addAll(mapSobject.get(recId));
    	}else {
    		for(Id recId : mapSobject.keySet())
    			ret.addAll(mapSobject.get(recId));
    	}
    	
    	return ret;
    }
    
    //AR-165
    public static list<String> grepFieldFromList(List<sobject> records , string fieldtogather, boolean excludeNulls) {
    	
    	list<string> ret = new list<String>();
    	for(sObject s : records) { 
        	
        	string Var = AccountingRuleService.getValue( fieldtogather, s);
        	
            if (!excludeNulls || Var != null) {
                ret.add( Var ); 
            }
        } 
        return ret;
    }
    
    // TODO add test for this to ??
     /* Sort a list passed in, the list is sorted inplace */
    public static void sortList(List<Sobject> items, String sortField, String order){
        List<Sobject> resultList = new List<Sobject>();
        
        if(order == null){
        	order = 'asc';
        }
        
        if(sortField == null){
        	sortField = 'Name';
        }
   
        //Create a map that can be used for sorting 
        Map<object, List<Sobject>> objectMap = new Map<object, List<Sobject>>();
        		   
        for(Sobject ob : items){
        	if(sortField.indexOf('.') == -1){
	            if(objectMap.get(ob.get(sortField)) == null){  // For non Sobject use obj.ProperyName
	                objectMap.put(ob.get(sortField), new List<Sobject>()); 
	            }
	            objectMap.get(ob.get(sortField)).add(ob);
        	}else{
        		List<String> fieldList = sortField.split('\\.');
        		
        		Object value;
        		String field;
        		SObject record = ob;
        		
        		for(Integer i=0; i < fieldList.size() - 1; i++){
        			record = record.getSObject(fieldList[i]);
        			if(record == null){
        				break;
        			}
        		}
        		
        		field = fieldList[fieldList.size() - 1];
        		value = record != null ? record.get(field) : null;
        		
    			if(objectMap.get(value) == null){  // For non Sobject use obj.ProperyName
	                objectMap.put(value, new List<Sobject>()); 
	            }
	            objectMap.get(value).add(ob);
        	}
        }       
        
        //Sort the keys
        List<object> keys = new List<object>(objectMap.keySet());
        keys.sort();
        
        for(object key : keys){ 
            resultList.addAll(objectMap.get(key)); 
        }
        
        //Apply the sorted values to the source list
        items.clear();
        if(order.toLowerCase() == 'asc'){
            for(Sobject ob : resultList){
                items.add(ob); 
            }
        }else if(order.toLowerCase() == 'desc'){
            for(integer i = resultList.size()-1; i >= 0; i--){
                items.add(resultList[i]);  
            }
        }
    }
    
    public static Decimal getConversionFactor(SObject sObj){
        Decimal conversionFactor = 1.0;
        List<Id> lstPkgUom;
        if(sObj.getSObjectType() == Purchase_Order_Line__c.sObjectType){
            Purchase_Order_Line__c pol = (Purchase_Order_Line__c) sObj;
            lstPkgUom = (List<Id>) JSON.deserialize(pol.Item__r.Packaging_UOM__c, List<Id>.class);
            conversionFactor = GetConversionFactor( pol.Item__c, pol.Delivery_Facility__r.Facility_Identifier__c, pol.Purchase_UOM__c,pol.Item__r.Stocking_UOM__c, lstPkgUom);
            
        }
        else if(sObj.getSObjectType() == Sales_Order_Line__c.sObjectType)
        {
            
            Sales_Order_Line__c sol = (Sales_Order_Line__c) sObj;
            lstPkgUom = (List<Id>) JSON.deserialize(sol.Product__r.Item__r.Packaging_UOM__c, List<Id>.class);
            conversionFactor = GetConversionFactor( sol.Product__r.Item__c, sol.Ship_From_Location__r.Facility__r.Facility_Identifier__c,sol.Selling_UOM__c,sol.Product__r.Item__r.Stocking_UOM__c, lstPkgUom);
        }
        else if(sObj.getSObjectType() == Receipt_Line__c.sObjectType)
        {
            
            Receipt_Line__c rl = (Receipt_Line__c) sObj;
            lstPkgUom = (List<Id>) JSON.deserialize(rl.Item__r.Packaging_UOM__c, List<Id>.class);
            conversionFactor = GetConversionFactor(rl.Item__c,rl.Facility__r.Facility_Identifier__c,rl.Packaging_UOM__c,rl.Item__r.Stocking_UOM__c, lstPkgUom);
        }
        else if(sObj.getSObjectType() == Shipment_Line__c.sObjectType){    

            Shipment_Line__c shl = (Shipment_Line__c) sObj;
            lstPkgUom = (List<Id>) JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.class);
            conversionFactor = GetConversionFactor(shl.Item__c,shl.Facility__r.Facility_Identifier__c, shl.Sales_Order_Line__r.Selling_UOM__c, shl.Item__r.Stocking_UOM__c, lstPkgUom);
        }
        else if(sObj.getSObjectType() == Item__c.sObjectType)
        {    
            
            Item__c item = (Item__c) sObj;
            lstPkgUom = (List<Id>) JSON.deserialize(item.Packaging_UOM__c, List<Id>.class);
            conversionFactor = GetConversionFactor(item.Id,null,item.Purchasing_UOM__c,item.Stocking_UOM__c, lstPkgUom);
            
        }
        else if(sObj.getSObjectType() == Product__c.sObjectType)
        {
        
            Product__c product = (Product__c) sObj;
            lstPkgUom = (List<Id>) JSON.deserialize(product.Item__r.Packaging_UOM__c, List<Id>.class);
            conversionFactor = GetConversionFactor(product.Item__c,null,product.Selling_UOM__c,product.Item__r.Stocking_UOM__c, lstPkgUom);
                
        }
        else{
            throw new SKIDServiceException('Invalid sObject for UOM Conversion: ' + sObj.getSObjectType());
        }
        
        return conversionFactor;
    }
    
    //KNDY 3621 UOM Conversion
    public static Decimal getSOConversionFactor(SObject sObj, string type)
    {
        Decimal conversionFactor = 1.0;
        //System.debug(logginglevel.info,'This is the getConversionFactor(SObject sObj) + string type' + sObj.getSObjectType());
        List<Id> lstPkgUom;
        if(sObj.getSObjectType() == Purchase_Order_Line__c.sObjectType)
        {
            Purchase_Order_Line__c pol = (Purchase_Order_Line__c) sObj;
            lstPkgUom = (List<Id>) JSON.deserialize(pol.Item__r.Packaging_UOM__c, List<Id>.class);
            conversionFactor = GetConversionFactor(pol.Item__c,pol.Delivery_Location__r.Facility__r.Facility_Identifier__c,pol.Purchase_UOM__c,pol.Item__r.Stocking_UOM__c, lstPkgUom);
            
        }
        else if(sObj.getSObjectType() == Sales_Order_Line__c.sObjectType)
        {
        
            Sales_Order_Line__c sol = (Sales_Order_Line__c) sObj;
            lstPkgUom = (List<Id>) JSON.deserialize(sol.Product__r.Item__r.Packaging_UOM__c, List<Id>.class);
            if(type == null)
            {   
	           conversionFactor = GetConversionFactor( sol.Product__r.Item__c,sol.Ship_From_Location__r.Facility__r.Facility_Identifier__c,sol.Selling_UOM__c,sol.Product__r.Item__r.Stocking_UOM__c, lstPkgUom);
                                   
	        }
            else if (type != null)
            {              	
           
              	if(type == 'weight')
              	{ 
              	 
              		conversionFactor = GetConversionFactor(sol.Product__r.Item__c,sol.Ship_From_Location__r.Facility__r.Facility_Identifier__c,sol.Product__r.Weight_UOM__c,sol.Weight_UOM__c, lstPkgUom);
                       
	           }
          	   else if(type == 'dimension')
          	   {
          	 
          	        conversionFactor = GetConversionFactor(sol.Product__r.Item__c,sol.Ship_From_Location__r.Facility__r.Facility_Identifier__c, sol.Product__r.Dimension_UOM__c,sol.Dimension_UOM__c, lstPkgUom);
                                
               }
         
            }
            
        }else if(sObj.getSObjectType() == Item__c.sObjectType){    
            
            Item__c item = (Item__c) sObj;
            lstPkgUom = (List<Id>) JSON.deserialize(item.Packaging_UOM__c, List<Id>.class);
            conversionFactor = GetConversionFactor(item.Id,null,item.Purchasing_UOM__c,item.Stocking_UOM__c, lstPkgUom);
                
        }else if(sObj.getSObjectType() == Product__c.sObjectType){
        
            Product__c product = (Product__c) sObj;
            lstPkgUom = (List<Id>) JSON.deserialize(product.Item__r.Packaging_UOM__c, List<Id>.class);
            conversionFactor = GetConversionFactor(product.Item__c,null,product.Selling_UOM__c,product.Item__r.Stocking_UOM__c, lstPkgUom);
                
        }else{
            throw new SKIDServiceException('Invalid sObject for UOM Conversion: ' + sObj.getSObjectType());
        }
        
        return conversionFactor;
    }
        
    
    @TestVisible private static boolean flagvalue = false;

    public static boolean hasAlreadyfired() {
        return flagvalue;
    }
    
    public static void setAlreadyfired() {
        flagvalue = true;
    }
    // This function will be used in all source document objects Trigger to set hidden flag and throw error if user trying to unfinalize the checkbox manually
    public static void setValidateFinalizedFlagonSD(){
        for(sObject sObj: Trigger.new){
            if((boolean) sObj.get('Finalized__c') == true){
                sObj.put('Finalized_hidden__c',true);
            }
        }
        if(Trigger.isUpdate){
            for(sObject sObj: Trigger.new){
                if( KSE.isFieldChanging('Finalized__c' , sObj, Trigger.oldMap) && sObj.get('Finalized__c') == false && sObj.get('Finalized_Hidden__c') != false) {
                    sObj.addError(Label.Click_Unfinalize);
                }
            }
        }
    }

        /*
    * FROM: https://www.interactiveties.com/blog/2011/apex-drop-leading-zeros.php#.VMv5Ml7F9sA
    */
    //removes leading zeros from a passed string of numbers or returns NULL when not all numeric characters
    public static String drop_leading_zeros(String passedValue) {
        String return_string = null; //return string for passing back
        if (passedValue != null) { //if the passed value is not null
            return_string = passedValue.trim(); //trim the whitespace from the start and end of the value
            Pattern valid_characters = Pattern.compile('([0-9]+)'); //only numbers
            Matcher check_chars = valid_characters.matcher(return_string); //compare the string to the set of valid characters
            if (check_chars.matches()) { //if we have a somewhat valid number
                if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with a 0 and the length is greater than 1
                    boolean keepChecking = true; //create a boolean variable
                    while (keepChecking) { //if boolean is true
                        if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with 0 and there is more than 1 character
                            return_string = return_string.substring(1); //drop the first character
                        } else { //either the string doesn't begin with 0 or the length is less than or equal to 1
                            keepChecking = false; //stop the loop
                        }
                    }
                }
                if (return_string == '0') { //if the resulting string is now a single '0'
                    return_string = null; //set the string to null
                }
            } else { //otherwise the value passed was not valid
                return_string = null; //set the string to null
            }
        }
        return return_string; //pass back a value
    }    
    
    
    
    /*
    * BEGIN Base62 Code
    * This is used to convert salesforce Ids to Integers and back for chunking
    */
    
    /*
    This code ported from python here:
    https://gist.github.com/adyliu/4494223    
    */
    static String basedigits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    
    public static Long base62decode(String s) {
        Long ret = 0;
        Long mult = 1;
        
        String[] chars = s.split('');
        //chars.remove(0);
        
        String[] charsReversed = new List<String>();
        
        for(Integer i = chars.size()-1; i>=0; i--) {
            charsReversed.add(chars.get(i));
        }
        
        for (String c: charsReversed) {
            Integer index = basedigits.indexOf(c);
            system.assert(index > -1, 'bad character');
            ret += mult*index;
            mult *= 62;
        }
        
        return ret;
    }    
    
    
    public static String base62encode(Long num) {
        system.assert(num >= 0, 'expected positive number');
        if (num == 0) {
            return '0';
        }

        List<String> retList = new List<String>();

        String[] basedigitsArr = basedigits.split('');
        //basedigitsArr.remove(0);

        while (num != 0) {
            Integer cIndex = (Integer)Math.Mod(num, 62);
            retList.add(basedigitsArr[cIndex]);
            num = (num/62);
        }
        
        List<String> retListReversed = new List<String>();
        for(Integer i = retList.size()-1; i>=0; i--) {
            retListReversed.add(retList.get(i));
        }   
            
        return String.join(retListReversed, '');
    }  
    /*
    * END Base62 Code
    */
              
    
    
    
    
    
    public static List<Map<String, String>> chunkIdRange(String startId, String endId, Integer chunkSize) {
        
        //grab the beginning of the Id.  we will need to append this back on to the chunked Ids at the end
        String idPrefix = startId.left(6);
        
        String startIdStripped = startId.left(15).right(9);
        String endIdStripped = endId.left(15).right(9);

        //now we have b62 pieces like this: 00006sfef
        //pass them to the method to decode them into Longs
        
        Long startNum = base62decode(startIdStripped); 
        Long endNum = base62decode(endIdStripped); 
            
        //now pass this to the chunkRange method:
        List<Map<String, String>> numberChunkList = chunkRange(startNum, endNum, 9, chunkSize);
        
        system.debug(numberChunkList);
        
        //now loop through the ranges, base62 encode them, and add the id prefix back in
        List<Map<String, String>> idChunkList = new List<Map<String, String>>();
        for (Map<String, String> chunkMap: numberChunkList) {
            Long rangeStart = Long.valueOf(drop_leading_zeros(chunkMap.get('first')));
            Long rangeEnd   = Long.valueOf(drop_leading_zeros(chunkMap.get('last')));
            
            String rangeStartB62    = prefixStringWithZeros(base62encode(rangeStart), 9);
            String rangeEndB62      = prefixStringWithZeros(base62encode(rangeEnd), 9);
            
            idChunkList.add(new Map<String, String>{'first'=> idPrefix+rangeStartB62, 'last'=> idPrefix+rangeEndB62});
        }
        
        return idChunkList;
    }
    
    
    
    
    /*
    * This method is used to chunk up an autonumber range into a list of start and end autonumber values.
    * start autonumber, end autonumber, and size of the chunks is passed in
    * autonumbers passed in need to already be cleaned up into Integer format
    */
    //overloaded version which can take in Ints
    public static List<Map<String, String>> chunkRange(Integer firstAutoNum, Integer lastAutoNum, Integer totalLength, Integer chunkSize) {
        return chunkRange((Long)firstAutoNum, (Long)lastAutoNum, totalLength, chunkSize);
    }
    
    
    public static List<Map<String, String>> chunkRange(Long firstAutoNum, Long lastAutoNum, Integer totalLength, Integer chunkSize) {
        //get the range between the two numbers passed in. 
        Long range = (lastAutoNum - firstAutoNum);  
        
        List<Map<String, Long>> autoNumberChunkList = new List<Map<String, Long>>();
        
        
        if (range < chunkSize) { //range is already smaller than chunk, just add them all
            autoNumberChunkList.add(new Map<String, Long>{'first'=> firstAutoNum, 'last'=> lastAutoNum});   
        } else {
            //need to create multiple chunks
            
            //chunk the range up into chunks the size of chunkSize
            Decimal numChunks = (range / chunkSize);    //figure out how many whole and partial chunks we have
            numChunks = numChunks.round(System.RoundingMode.DOWN);      //discard the partial chunk remainder
            Integer numWholeChunks = numChunks.intValue();
            
            //add the first chunk
            Long firstAutoNumChunk =    firstAutoNum;
            Long lastAutoNumChunk =     firstAutoNum + chunkSize - 1;
            autoNumberChunkList.add(new Map<String, Long>{'first'=> firstAutoNumChunk, 'last'=> lastAutoNumChunk});             
            
            //add any remaining chunks
            for (Integer i=1; i<numWholeChunks; i++) {
                firstAutoNumChunk = (lastAutoNumChunk + 1);
                lastAutoNumChunk = (firstAutoNumChunk + chunkSize - 1);                     
                autoNumberChunkList.add(new Map<String, Long>{'first'=> firstAutoNumChunk, 'last'=> lastAutoNumChunk});
            }
            
            //add in the any remaining chunk which is < chunkSize
            Long lastLastAutoNumChunk = autoNumberChunkList[autoNumberChunkList.size()-1].get('last'); //get last autonumber from last row of the chunkList
            if (lastLastAutoNumChunk < lastAutoNum) {
                autoNumberChunkList.add(new Map<String, Long>{'first'=> lastLastAutoNumChunk+1, 'last'=> lastAutoNum}); 
            }
        }       
        
        //convert our integer map to a padded string map with 0's so it matches the autonumber format 
        List<Map<String, String>> autoNumberChunkListZeroPadded = new List<Map<String, String>>();
        for (Map<String, Long> rangeMap: autoNumberChunkList) {
            autoNumberChunkListZeroPadded.add(new Map<String, String>{'first'=> prefixLongWithZeros(rangeMap.get('first'), totalLength), 
                                                                      'last' => prefixLongWithZeros(rangeMap.get('last'),  totalLength) });     
        }
        
        return autoNumberChunkListZeroPadded;
    }
    
    
    public static String prefixIntWithZeros(Integer intInput, Integer totalLength) {
        String sOutput = '';
        
        if (intInput != null) {
            sOutput = intInput+'';
        }
        
        //prepend with however many zeros we need to get up to total length
        Integer zerosToAdd = (totalLength - sOutput.length());
        if (zerosToAdd > 0) {
            for (Integer i=0; i<zerosToAdd; i++) {
                sOutput = '0'+sOutput;  
            }
        }
        
        return sOutput;
    }
    
    public static String prefixLongWithZeros(Long lngInput, Integer totalLength) {
        String sOutput = '';
        
        if (lngInput != null) {
            sOutput = lngInput+'';
        }
        
        //prepend with however many zeros we need to get up to total length
        Integer zerosToAdd = (totalLength - sOutput.length());
        if (zerosToAdd > 0) {
            for (Integer i=0; i<zerosToAdd; i++) {
                sOutput = '0'+sOutput;  
            }
        }
        
        return sOutput;
    }   
    
    
    public static String prefixStringWithZeros(String sInput, Integer totalLength) {
        String sOutput = '';
        
        if (sInput != null) {
            sOutput = sInput+'';
        }
        
        //prepend with however many zeros we need to get up to total length
        Integer zerosToAdd = (totalLength - sOutput.length());
        if (zerosToAdd > 0) {
            for (Integer i=0; i<zerosToAdd; i++) {
                sOutput = '0'+sOutput;  
            }
        }
        
        return sOutput;
    }   

    public static decimal getConversionFactorFromQuantity(decimal stockingQuantity, decimal orderQuantity)
    {
    	decimal convFactor = 1;
    	if((stockingQuantity==null || orderQuantity==null)||(stockingQuantity==0 || orderQuantity==0))
    		return convFactor;
    	else
    	{
    		convFactor =  (stockingQuantity/orderQuantity);
    	}
    	return convFactor;
    }   
    
    /**
     * @description Get the convertion factor for item UOMS based on the UOM list path
     * @param itemId
     * @param fromUOMId
     * @param toUOMId
     * @param sortedUOMs list of UOM ids sorted on level ASC. panning this list would give 
     *        us the UOM conversion on hierarchy
     * 
     */ 
     //public static Decimal getConversionFactor ( id itemId, id fromUOMId, id toUOMId, List<Id> sortedUOMs ) {
     	//return getConversionFactor(itemId, null, fromUOMId, toUOMId, sortedUOMs);
     //}
    public static Decimal getConversionFactor ( id itemId, Decimal facilityId, id fromUOMId, id toUOMId, List<Id> sortedUOMs ) {
        Boolean isBackwards = false;
        Decimal conversionFactor = null;
        
        if((fromUOMId==null || toUOMId==null) || (fromUOMId == toUOMId)) {
        	return 1;
        }
        
        // get the conversion factor, if conversion exists
        conversionFactor = getConversionFactor ( itemId, facilityId, fromUomId, toUomId );
        
        if ( conversionFactor == null ) { 
            // sortedUom - will be in this order : EA,CS,PT
            // forward - think of EA -> PT
            // backward - thin of PT - EA
            
            // if from and/or to uom are not present in conversionPath, throws error for invalid setup
            Set<Id> uomSet = new Set<Id>(sortedUOMs);
            if ( !uomSet.containsAll ( new Set<Id> {fromUOMId, toUOMId}) || sortedUOMs.size() <= 2) {
                throw new CustomException ('Invalid from or to UOM for Item Packaging UOM');
            } else {
                for ( Integer i=sortedUOMs.size()-1; i> 0; i-- ) {
                    // conversion factor will be initialized when it finds from or to uom in the sortedUOMs
                    if ( conversionFactor == null ) {
                        if ( sortedUOMs[i] != fromUomId && sortedUOMs[i] != toUomId ) { // skip the uom if it doesnt match from/to uom
                            continue;
                        } else if ( sortedUOMs[i] == toUomId ) { // checks if the uom conversion is for the reverse uom list path
                            isBackwards = true;
                        }
                        conversionFactor =1; // initialize when on of from/to uom is found
                    } else {
                        // checks for stopping point. for backwards case, breaking point is for matching fromUomId to the current
                        // element in the sortedUom and otherwise for forward case.
                        if ( isBackwards && sortedUOMs[i] == fromUomId ) { 
                            break;
                        } else if ( !isBackwards && sortedUOMs[i] == toUomId ) {
                            break;
                        }
                    }
                    
                    // check if there is a next - the check above with uomSet ensures we 
                    if ( (i-1) >= 0) {
                        Decimal tmpConversion = getConversionFactor (itemId, facilityId, sortedUOMs[i], sortedUOMs[i-1]);
                        if ( tmpConversion == null ) throw new CustomException('UOM conversion not found');
                        conversionFactor = conversionFactor * getConversionFactor (itemId, facilityId, sortedUOMs[i], sortedUOMs[i-1]);
                    }
                }
                
                if ( conversionFactor == null ) {
                    throw new CustomException('UOM conversion not found');
                }
                
                if ( isBackwards ) conversionFactor = 1/conversionFactor;
            }
        }
        
        return conversionFactor;
    }
	
    private static Decimal getConversionFactor(Id itemId, Decimal facilityId, Id fromUomId, Id toUomId) {
        if (fromUomId == null || toUomId == null || fromUomId == toUomId) return 1;

        String item = itemId != null ? ((String)itemId).substring(3, 15) : '';
        String facility = facilityId != null ? ''+facilityId : '';
        String fromUom = ((String)fromUomId).substring(3, 15);
        String toUom = ((String)toUomId).substring(3, 15);

        UOM_Conversion_Details__c uomConv = UOM_Conversion_Details__c.getInstance(item + fromUom + toUom + facility);
        if (uomConv == null) uomConv = UOM_Conversion_Details__c.getInstance(item + toUom + fromUom + facility);
        if (uomConv == null) uomConv = UOM_Conversion_Details__c.getInstance(item + fromUom + toUom);
        if (uomConv == null) uomConv = UOM_Conversion_Details__c.getInstance(item + toUom + fromUom);
        if (uomConv == null) uomConv = UOM_Conversion_Details__c.getInstance( fromUom + toUom + facility);
        if (uomConv == null) uomConv = UOM_Conversion_Details__c.getInstance( toUom + fromUom + facility);
        if (uomConv == null) uomConv = UOM_Conversion_Details__c.getInstance(fromUom + toUom);
        if (uomConv == null) uomConv = UOM_Conversion_Details__c.getInstance(toUom + fromUom);
        if (uomConv == null) return null; //throw new CustomException('UOM conversion not found');

        Decimal convFactor = 1;
        if (fromUomId == uomConv.UOM_1__c) convFactor = uomConv.UOM_2_Quantity__c / uomConv.UOM_1_Quantity__c;
        else convFactor = uomConv.UOM_1_Quantity__c / uomConv.UOM_2_Quantity__c;

        return convFactor;
    }
    
    public static Date getDueDate (DateTime DateInvoiced, Payment_Term__c pt) {
    	
    	Date dueDate;
    	if (pt.Type__c == null){ // KNDY-11659 KNDY-11688
    		throw new KSEException(Label.Payment_Term_Type_is_blank);
    	}
    	else if(pt.Type__c.equals(PAYMENT_TERM_DUE_DAYS)) {
			dueDate = DateInvoiced.date().addDays(Integer.valueOf(pt.Due_Days__c));
		}
		else if(pt.Type__c.equals(PAYMENT_TERM_DUE_DAY_OF_MONTH)) {
			
			Date invoicedDate = DateInvoiced.date();
			Decimal cutOffDay = pt.Cut_Off_Day__c; // if cut off day is 31 and month(ID) = feb, then cut off day is 28 for non leap year or 29 for leap year. 
			Decimal invoicedMonth = DateInvoiced.month();
			
			//Date.newInstance(2015,0,12) = 12 december 2014... using this formula we calculate the month of the last payment due date. if day of the invoiced date is ahead of the cut off day we must add an extra month.  
			Decimal month = invoicedDate.day() > cutOffDay ? pt.Months_Ahead__c + 1 + invoicedMonth : pt.Months_Ahead__c + invoicedMonth; 
			
			//if day of month on PT is 31 ==> its the last day of the month for payment due date. For February 31 could be 28,29. also 30 could be 28,29. 29 could be 28 if year is not a leap year
			Decimal dayOfMonth =  pt.Day_Of_Month__c == 31 || (math.mod(Integer.valueOf(month),12) == 2 && (pt.Day_Of_Month__c == 30 || pt.Day_Of_Month__c == 29)) ? date.daysInMonth(invoicedDate.year(),Integer.valueOf(month)) 
																																	 : pt.Day_Of_Month__c;
			
			system.debug('invoicedDate '+ invoicedDate);
			system.debug('cutOffDay '+ cutOffDay);
			system.debug('invoicedMonth '+ invoicedMonth);
			system.debug('month '+ month);
			system.debug('dayOfMonth '+ dayOfMonth);
			Date cPDD = Date.newInstance(invoicedDate.year(),Integer.valueOf(month),Integer.valueOf(dayOfMonth));
			dueDate = cPDD <=  invoicedDate? cPDD.addMonths(1) : cPDD; //this is a case when months ahead is 0. you could have a scenario where the calculated payment date is the same or earlier than the invoiced date. 
		}
		
		return dueDate;
    }
    
    public static void ValidateUOM()
    {
    	if(trigger.isbefore && trigger.isDelete){
    		
    		List<UOM_Conversion_Details__c> allUOMConversions = UOM_Conversion_Details__c.getall().values();
	        
	        set<Id> fromUOM=new set<Id>();
	        set<Id> toUOM=new set<Id>();
	        for(UOM_Conversion_Details__c uomC:allUOMConversions)
	        {  
	        	fromUOM.add(uomC.UOM_1__c);
	        	toUOM.add(uomC.UOM_2__c);
	        }
            for(UOM__C uom : (List<UOM__C>)Trigger.old){
            	if((fromUOM.contains(uom.Id)) || (toUOM.contains(uom.Id)))
            		uom.addError(Label.UOM_Cannot_be_Deleted);
            }
	        
    	}
    }
    
    /**
     *  getDefaultPickListValue method fetches the default value of a picklist
     *
     *  @param      objectName       String
     *  @param      fieldApiName     String
     *  @return     defaultVal
     *
     */
    public static String getDefaultPickListValue(String objectName, String fieldApiName){
        //List <Schema.PicklistEntry> pickListValues = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldApiName).getDescribe().getPicklistValues();
	
	//KNDY-7537        
        Map<String, sObjectField> objectFields = SchemaUtil.getInstance().getFieldsMap(objectName);
        List<Schema.PicklistEntry> pickListValues = objectFields.get(fieldApiName).getDescribe().getPicklistValues();
        
        String defaultVal = 'None';
        for (Schema.PicklistEntry pv: pickListValues) {

            if (pv.isDefaultValue()) {
                defaultVal = pv.getValue();
            }    
        }

        return defaultVal;
    }

    /*
     *  getGridViews method fetches list of views from the custom setting(Grid_Views_Config__c)
     *
     *  @param  gridName
     *  @return List<Grid_Views_Config__c>    
     *
     */
    public static List<Grid_Views_Config__c> getGridViews(String gridName) {

        List<Grid_Views_Config__c> gridViews = new List<Grid_Views_Config__c>();

        SOQLUtil soql = new SOQLUtil('Grid_Views_Config__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Name','Grid_Name__c','View_Name__c','Fieldset_Name__c','Show__c','View_Dropdown_Index__c'
        });        
        soql.setWhereClause('Grid_Name__c = :gridName AND Show__c = true');
        soql.setOrderByClause('View_Dropdown_Index__c');
        
        gridViews = Database.query(soql.getQuery());
        
        return gridViews;
    } 
    /*
     *  getSegmentLinesFieldList method fetches all the segment fields from the segment field List
     *
     *  @return segmentLinesFieldList String
     *
     */
    public static string getSegmentLinesFieldList(String segmentLinesFieldList, GridRelatedListController.GridRelatedListConfig segmentLinesConfig) {
        SegmentService segmentSvc = new SegmentService();

        if (segmentLinesFieldList == null && segmentLinesConfig != null) {

            list<String> segments = new list<String>();

            segments.addAll(segmentSvc.segmentNameList()) ;

            // get the segment lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(segmentLinesConfig.objectName, segments);

            segmentLinesFieldList = JSON.serialize(fieldInfoList);
        }

        return segmentLinesFieldList;
    }


    // Custom Exception for Stockpoint Service Class
    public class SKIDServiceException extends Exception{    }
        
    //Get number of retries for parallel chunks from custom setting.    
    public static Integer getRetries(string customSettingName) {
        Integer retryCount = 4; //Default count in case custom setting is not defined.

        Integer minValue = 1;   
        Integer maxValue = 100; 
        
        Configuration__c c = Configuration__c.getValues(customSettingName);
        //attempt to parse the string config value into an integer and make sure it is between min/max
        //if not we are just going to use the default
        if (c != null) {
            Integer configBatch;
            try {configBatch = Integer.valueOf(c.Value__c);} catch (Exception e) {system.debug('Error getting retry count from custom setting  '+ customSettingName +'-'+e.getmessage());}
            if (configBatch != null) {
                if ( (configBatch >= minValue) && (configBatch <= maxValue) ) {
                    retryCount = configBatch;
                }
            }
        }
        return retryCount;               
    }   
    
    public static String replaceCaseInsensitive(String src, String target, String replacement){
        String replaceToken = '(?i)' + target;
        return src.replaceAll(replaceToken, replacement);
    }
    
    public static String replaceLast(String originalString, String subString, String replacement){
        
        if(originalString.indexOfIgnoreCase(subString) > -1){
        	String firstPart = originalString.substringBeforeLast(subString);
        	String lastPart = originalString.substringAfterLast(subString);
        	
	        return (firstPart + replacement + lastPart);
        }
        
        return originalString;
    }
    
    public static void blockRecordDeletion(){
    	if(trigger.isBefore && trigger.isDelete){
    		for(SObject sObj : trigger.old){
    			sObj.addError(Label.Record_cannot_be_deleted);
    		}
    	}
    }

    /**
     *  setLineNumbers method sets the line numbers for Sales Order Lines and
     *  sales agreement lines object
     *  @param List<SObject>
     *  @return List<SObject>
     */
    public static List<SObject> setLineNumbers(List<SObject> sObjects) {
        Schema.SObjectType sObjectType = sObjects.getSObjectType();
        map<Id,Decimal> parentValueMap = new Map<Id,Decimal>();
        set<Id> parentIds = new Set<Id>();
        List<SObject> parentObjects = new List<SObject>();
        SOQLUtil soql;

        if(sObjectType == Agreement_Line__c.sObjectType){
            parentIds = KSE.grepRelatedIdSetFromList(sObjects,'Agreement__c');

            soql = new SOQLUtil('Agreement__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                    'Id'
            });
            soql.setWhereClause('Id IN :parentIds FOR UPDATE');

            SOQLUtil.ChildRelationship agrLineRel = new SOQLUtil.ChildRelationship(soql, 'Agreement_Lines__r');
            agrLineRel.addFields(new set<string>{
                    'Line__c'
            });
            soql.addChildRelationship(agrLineRel);


        } else if(sObjectType == Sales_Order_Line__c.sObjectType){
            parentIds = KSE.grepRelatedIdSetFromList(sObjects, 'Sales_Order__c');
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil

            soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                    'Id'
            });
            soql.setWhereClause('Id IN :parentIds FOR UPDATE');

            SOQLUtil.ChildRelationship soLineRel = new SOQLUtil.ChildRelationship(soql, 'Sales_Order_Lines__r');
            soLineRel.addFields(new set<string>{
                    'Line__c'
            });
            soql.addChildRelationship(soLineRel);

        } else {
            //Return if other object type
            return sObjects;
        }

        parentObjects = Database.query(soql.getQuery());
        // Get the max line number for each sales order
        for (SObject sObj : parentObjects){

            parentValueMap.put(sObj.Id,0);
            List<SObject> existingChildLines = sObj.getSObjectType() == Agreement__c.sObjectType ?
                                                    sObj.getSObjects('Agreement_Lines__r') : sObj.getSObjects('Sales_Order_Lines__r');
            if (existingChildLines != null){
                for (SObject childSObj: existingChildLines){

                    if ((Decimal)childSObj.get('Line__c') > parentValueMap.get(sObj.Id)){
                        Decimal tempD = (Decimal)childSObj.get('Line__c');
                        parentValueMap.put(sObj.Id,tempD);
                    }
                }
            }
        }
        // Assign line numbers
        for (SObject sObj : sObjects) {
            Id myId = sObj.getSObjectType() == Agreement_Line__c.sObjectType ?
                                (Id)sObj.get('Agreement__c') : (Id)sObj.get('Sales_Order__c');

            if (!parentValueMap.containsKey(myId)){
                parentValueMap.put(myId,0);
            }

            Decimal val = parentValueMap.get(myId);
            ++val;
            if ( sObj.get('Line__c') != null ) {
                // KNDY-6005 user did specify line #, we will use it
                val = (Decimal)sObj.get('Line__c');
            }
            parentValueMap.put(myId,val);
            sObj.put('Line__c',val);
            if(sObj.getSObjectType() == Sales_Order_Line__c.sObjectType) {
                //Update Unique Sales Order Line field
                sObj.put('Unique_Sales_Order_Line__c', myId + '-' + val);
            } else if(sObj.getSObjectType() == Agreement_Line__c.sObjectType){
                sObj.put('Unique_Agreement_Line__c', myId + '-' + val);
            }
        }

        return sObjects;
    }

    
    
    /**
	* In some cases we may not want to run the all the test methods.
	* This is to avoid this error in the packaging org:
	* System.LimitException: Your runAllTests request is using too many DB resources.
	*
    * Test methods will still get run in the dev orgs and CI orgs
    * 
	*/    
    public static Boolean checkTestDispatch() {
    	Boolean testDispatch = false;
        Id KNDY4_PKG_ORG_ID = '00DG0000000k1lF'; 

        if (UserInfo.getOrganizationId() == KNDY4_PKG_ORG_ID) {
	        testDispatch = true;    
        }

        return testDispatch;
    }

    public static void roundNumberFields(List<sObject> records, Set<String> fields) {
        for (sObject record:records) {
            for (String field:fields) {
            	//TO DO: THIS SHOULD LOOK AT THE PRECISION ON THE OBJECT
                if (record.get(field) != null) record.put(field, ((Decimal)record.get(field)).setScale(6, System.RoundingMode.HALF_UP));
            }
        }
    }
}