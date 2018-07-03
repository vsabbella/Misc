Public with sharing class APForecastExt{
    public List<APForecastExtWrapper> previousList {get;set;}
    public List<APForecastExtWrapper> currentList {get;set;}
    public ApexPages.StandardSetController mycon{get;set;}  
    public List<Date> previousListDate {get;set;}
    public List<Date> currentListDate {get;set;}
    public Integer distanceOfPrevToCurr {get;set;}
    public Integer distanceOfCurrToEnd {get;set;}
    public Date startdate {get;set;}
    public Date enddate {get;set;}
    public Date prevexpdate {get;set;}
    public Date currdate{get;set;}
    public Date customPriorDate {get;set;}
    public Date customLaterDate {get;set;}  
    public Integer customPreviousInteger {get;set;}
    public Integer customFutureInteger {get;set;}     
    public boolean customDateGenInEffect = FALSE;
    public double priorAmountTotal {get;set;}
    public double previousTotal {get;set;} 
    public double laterTotal {get;set;} 
    public double grandTotal {get;set;}
    public double currentTotal {get;set;}
    public date lastDayInScope {get;set;}
    public string DateFilterCurr,DateFilterPrev,DateFilterPrior,DateFilterLater ;
    public string BaseQuery1,BaseQuery2,CustomFilter,GroupClause, OrderByClause ;
    public string query1Prior,query2Prev,query3Curr,query4Later ;
    public string HelpURL{get;set;}



    private static final Integer NUMBER_OF_DAYS_IN_A_WEEK = 7;

    public void customDateGen(){
        
        currdate = system.now().date();
        startdate = currdate;
        // Setting custom date ranges && validations 
        //If both values are set
        if( (customFutureInteger >= 0 || customFutureInteger != NULL) && (customPreviousInteger > 0 || customPreviousInteger != NULL)){
            enddate = currdate.addDays(customFutureInteger);
            prevexpdate = currdate.addDays(-customPreviousInteger);
            customDateGenInEffect = true;            
        }
        //If future integer is set
        if((customFutureInteger >= 0 &&  customFutureInteger != NULL) && (customPreviousInteger < 0 || customPreviousInteger == NULL)){
            enddate = currdate.addDays(customFutureInteger);
            prevexpdate = currdate.adddays(-6);
            customDateGenInEffect = true;            
        }
        //If previous integer is set 
        if((customFutureInteger < 0 || customFutureInteger == NULL) && (customPreviousInteger > 0 && customPreviousInteger != NULL)){
            prevexpdate = currdate.addDays(-customPreviousInteger);
            enddate = currdate.addDays(26); 
            customDateGenInEffect = true;  
            //Minimum Days must be 1 for both scopes
            if((customPreviousInteger == 0)){
                prevexpdate = currdate.addDays(-1);         
            }          
        }


        //Error validation rules 
        if(customFutureInteger < 0 && customPreviousInteger < 0){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Please add a positive whole numbers'));
        }else if(customFutureInteger < 0){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Please add a positive whole number'));
        }else if(customPreviousInteger < 0){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Please add a positive whole number'));
        }else{
                   distanceOfPrevToCurr = prevexpdate.daysBetween(startdate);
        distanceOfCurrToEnd = currdate.daysBetween(enddate);

        if(distanceOfPrevToCurr > 60){
            prevexpdate=startdate.adddays(-60);
            distanceOfPrevToCurr = 60;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Maximum Number of days is 60'));            
        }
        if(distanceOfCurrToEnd > 60){
            enddate = currdate.addDays(60); 
            distanceOfCurrToEnd = 60;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Maximum Number of days is 60'));
        }
        if(distanceOfPrevToCurr == 0){
            distanceOfPrevToCurr = 1;
        }
        //Add page redirect and reload after date is updated.
            getAPForecastData();

            PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
            pageRef.setRedirect(true); 
        }

    }

    public void resetCustomDateGenFilter(){
        currdate = system.now().date();
        startdate = currdate;
        //if(customDateFilterInPlace = false){
        prevexpdate=startdate.adddays(-6);//Last date before prior bucketing
        enddate = currdate.addDays(26);  //Last date after which there is Later Bucketing
        distanceOfPrevToCurr = prevexpdate.daysBetween(startdate);
        distanceOfCurrToEnd = currdate.daysBetween(enddate);
        getAPForecastData();

        PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
        pageRef.setRedirect(true);


 
    }

    public APForecastExt(){
        
        if( customDateGenInEffect == FALSE ){
        currdate = system.now().date();
        startdate = currdate;
        //if(customDateFilterInPlace = false){
        prevexpdate=startdate.adddays(-6);//Last date before prior bucketing
        enddate = currdate.addDays(26);  //Last date after which there is Later Bucketing
        distanceOfPrevToCurr = prevexpdate.daysBetween(startdate);
        distanceOfCurrToEnd = currdate.daysBetween(enddate);
        }



        //CustomFilter='';
        //list<DTPFilter__c> DTPFilters = DTPFilter__c.getAll().values();
        //Map<String, Schema.SObjectField> fieldMap = util.getFieldsMap('Supplier_invoice__c');


        BaseQuery1 = 'select sum(Invoice_Amount__c) sum ,Payment_Due_Date__c paymentDueDate from Supplier_invoice__c where status__c !=\'Closed\'';
        BaseQuery2 = 'select sum(Invoice_Amount__c) sum  from Supplier_invoice__c where status__c !=\'Closed\'';        
        DateFilterCurr ='  and (Payment_Due_Date__c >= :startDate AND Payment_Due_Date__c <=  :enddate) and Payment_Due_Date__c!=null ';
        DateFilterPrev ='  and (Payment_Due_Date__c >=  :prevexpdate AND Payment_Due_Date__c <  :startDate) and Payment_Due_Date__c!=null ';    
        DateFilterPrior='  and Payment_Due_Date__c <  :prevexpdate and Payment_Due_Date__c!=null ';    
        DateFilterLater='  and Payment_Due_Date__c >  :enddate  and Payment_Due_Date__c!=null ';    

        GroupClause = ' group by Payment_Due_Date__c '; 
        OrderByClause = 'Order By Payment_Due_Date__c ASC';       
        getAPForecastData();  
        HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpCashForecast';

    }

    public void getAPForecastData(){
        
        query1Prior = BaseQuery2+DateFilterPrior;
        list<aggregateresult> openSIPriorExpBucket  =  database.query(query1Prior);  
        system.debug(openSIPriorExpBucket.size());
       
        query2Prev = BaseQuery1+DateFilterPrev+GroupClause+OrderByClause + ' LIMIT '+distanceOfPrevToCurr;
        list<aggregateresult> openSIPrevExpBucket  =  database.query(query2Prev);  
        system.debug(openSIPrevExpBucket.size());

        query3Curr = BaseQuery1+DateFilterCurr + GroupClause + OrderByClause + ' LIMIT '+distanceOfCurrToEnd;
        list<aggregateresult> openSICurrExpBucket  =  database.query(query3Curr);  
        system.debug(openSICurrExpBucket.size());

        query4Later = BaseQuery2+DateFilterLater;
        list<aggregateresult> openSILaterExpBucket  =  database.query(query4Later);  
        system.debug(openSILaterExpBucket.size());

        generateApForcastReport(openSIPriorExpBucket,openSIPrevExpBucket,openSICurrExpBucket,openSILaterExpBucket);

    }

    public void generateApForcastReport(list<aggregateresult> prior, list<aggregateresult> prev, list<aggregateresult> curr, list<aggregateresult> later){
         grandTotal = 0;
         previousTotal = 0;
         laterTotal = 0;
         currentTotal = 0;
         previousList = new List<APForecastExtWrapper>();
         currentList = new List<APForecastExtWrapper>();
         previousListDate = new List<Date> ();
         currentListDate = new list<Date> ();

        //Construct Prior Date List and Append with Dates within scope
        map<date,double> prevAggrMap= new map<date,double>();
        
        for(aggregateresult ar: prev){
            if(prev.size() > 0){
            prevAggrMap.put((date)ar.get('paymentDueDate'),(double)ar.get('sum'));
            }
        }

        for(Integer i = 0; i < distanceOfPrevToCurr ; i++){
            //date dateForRefrence = system.now().date();         
            date dateForRefrence = prevexpdate.adddays(i);
            previousListDate.add(dateForRefrence);
        }


        //Add Prior 
        APForecastExtWrapper priorRecord = new APForecastExtWrapper();
        priorRecord.forecastDate = 'Prior Payments Total';
        priorRecord.forecastLabel = 'Prior';
        if((double)prior[0].get('sum') == NULL){
            priorRecord.apDollarAmount = 0;

        }else{
            priorRecord.apDollarAmount = (double)prior[0].get('sum');
            grandTotal += priorRecord.apDollarAmount;
        }

        priorAmountTotal = priorRecord.apDollarAmount;
        //previousList.add(priorRecord);


        APForecastExtWrapper prevRecordTotal = new APForecastExtWrapper();

            prevRecordTotal.forecastDate = 'Previous Payments Total';
            prevRecordTotal.forecastLabel = 'prev';
            prevRecordTotal.apDollarAmount = 0;

            //previousTotal = prevRecordTotal.apDollarAmount = 0;

        Double weeklyTotalPrevious = 0;
        Integer dayCountPrevious = 0;

        for(Date dateInContext: previousListDate){
            dayCountPrevious++;
            Integer modulusRemainder = math.mod(dayCountPrevious, NUMBER_OF_DAYS_IN_A_WEEK);
        APForecastExtWrapper prevRecord = new APForecastExtWrapper();
        prevRecord.forecastDate = string.valueOf(dateInContext);
        prevRecord.forecastLabel = 'prev';
            if(prevAggrMap.containskey(dateInContext)){
                prevRecord.apDollarAmount = prevAggrMap.get(dateInContext);  
                weeklyTotalPrevious += prevAggrMap.get(dateInContext);  
                previousTotal += prevAggrMap.get(dateInContext);
                grandTotal += prevAggrMap.get(dateInContext);  
            }
            else{
                prevRecord.apDollarAmount = 0; 
                weeklyTotalPrevious += 0;
                previousTotal += 0;     
            }
            prevRecordTotal.apDollarAmount += prevRecord.apDollarAmount;
            previousList.add(prevRecord);

            //if(modulusRemainder != 0 && previousListDate.size() == dayCountPrevious){
                        
            //        for(Integer i = 0; i < (NUMBER_OF_DAYS_IN_A_WEEK - math.mod(previousListDate.size(), NUMBER_OF_DAYS_IN_A_WEEK)); i++) {
            //            APForecastExtWrapper blankSpace = new APForecastExtWrapper();
            //            blankSpace.forecastDate = ' ';
            //            blankSpace.apDollarAmount = NULL;
            //            previousList.add(blankSpace);
            //            //eeklyTotalPrevious = 0; 
            //        }

            //} 

            //if(modulusRemainder == 0 || previousListDate.size() == dayCountPrevious){
            //            APForecastExtWrapper currentRecordWeeklyTotal = new APForecastExtWrapper();
            //            currentRecordWeeklyTotal.forecastDate = 'Weekly Total';
            //            currentRecordWeeklyTotal.apDollarAmount = weeklyTotalPrevious;
            //            previousList.add(currentRecordWeeklyTotal);
            //            weeklyTotalPrevious = 0; 

            //            }   
                        generateWeeklyTotalandAlign(modulusRemainder, previousListDate.size(), dayCountPrevious, weeklyTotalPrevious, previousList);
            if(modulusRemainder == 0 || previousListDate.size() == dayCountPrevious){
                weeklyTotalPrevious = 0; 
            }

        }



        //previousList.add(prevRecordTotal);        
        
        system.debug(previousList.size());



        //Construct Later Date List and Append with Dates within scope
        map<date,double> currentAggrMap= new map<date,double>();
        
        for(aggregateresult ar: curr){
            if(curr.size() > 0){
            currentAggrMap.put((date)ar.get('paymentDueDate'),(double)ar.get('sum'));
            }
        }

        for(Integer i = 0; i <= distanceOfCurrToEnd ; i++){
       
           date dateForRefrence = startdate.adddays(i);
            currentListDate.add(dateForRefrence);
        }



        APForecastExtWrapper laterRecordTotal = new APForecastExtWrapper();
        laterRecordTotal.forecastDate = 'Total Payments Due Within Scope';
        laterRecordTotal.forecastLabel = 'later';
        laterRecordTotal.apDollarAmount = 0;


        Integer dayCountCurrent = 0;
        Double weeklyTotalCurrent = 0;
        //Add Later
        for(Date dateInContext: currentListDate){


        APForecastExtWrapper currentRecord = new APForecastExtWrapper();
        dayCountCurrent++;
        Integer modulusRemainder = math.mod(dayCountCurrent, NUMBER_OF_DAYS_IN_A_WEEK);
        currentRecord.forecastDate = string.valueOf(dateInContext);
        currentRecord.forecastLabel = 'later';
            if(currentAggrMap.containskey(dateInContext)){
                currentRecord.apDollarAmount = currentAggrMap.get(dateInContext);    
                weeklyTotalCurrent += currentAggrMap.get(dateInContext);   
                grandTotal += currentRecord.apDollarAmount; 
            }
            else{
                currentRecord.apDollarAmount = 0;  
                weeklyTotalCurrent += 0; 

            }

            laterRecordTotal.apDollarAmount += currentRecord.apDollarAmount;
            currentList.add(currentRecord);   

        //    if(modulusRemainder != 0 && currentListDate.size() == dayCountCurrent){
                        
        //            for(Integer i = 0; i < (NUMBER_OF_DAYS_IN_A_WEEK - math.mod(currentListDate.size(), NUMBER_OF_DAYS_IN_A_WEEK)); i++) {
        //                APForecastExtWrapper blankSpace = new APForecastExtWrapper();
        //                blankSpace.forecastDate = ' ';
        //                blankSpace.apDollarAmount = NULL;
        //                currentList.add(blankSpace);
        //                //eeklyTotalPrevious = 0; 
        //            }

        //    } 

        //    if(modulusRemainder == 0 || currentListDate.size() == dayCountCurrent){
        //            APForecastExtWrapper currentRecordWeeklyTotal = new APForecastExtWrapper();
        //            currentRecordWeeklyTotal.forecastDate = 'Weekly Total';
        //            currentRecordWeeklyTotal.apDollarAmount = weeklyTotalCurrent;
        //            currentList.add(currentRecordWeeklyTotal);
        //            weeklyTotalCurrent = 0; 

        //            } 
            generateWeeklyTotalandAlign(modulusRemainder, currentListDate.size(), dayCountCurrent, weeklyTotalCurrent, currentList);
                if(modulusRemainder == 0 || currentListDate.size() == dayCountCurrent){                      
                    weeklyTotalCurrent = 0;   
                }
        }

        currentTotal = laterRecordTotal.apDollarAmount;




        
        //Add Later 
        APForecastExtWrapper laterRecord = new APForecastExtWrapper();
        laterRecord.forecastDate = 'Payments Due After: '+ string.ValueOf(currentListDate[currentListDate.size()-1]);
        laterRecord.forecastLabel = 'Current';
        if( (double)later[0].get('sum') != NULL){
            //laterTotal += (double)later[0].get('sum');
            laterRecord.apDollarAmount = (double)later[0].get('sum');
            grandTotal += laterRecord.apDollarAmount; 

        }else{
            laterRecord.apDollarAmount = 0;
        }
            laterTotal = laterRecord.apDollarAmount;
            system.debug(currentList.size());




    }


    public void generateWeeklyTotalandAlign(Integer modulusRemainderInt, Integer listSize, Integer dayCount, Double weeklyTotal, List<APForecastExtWrapper> wrapperList){
                if(modulusRemainderInt != 0 && listSize == dayCount){
                        
                    for(Integer i = 0; i < (NUMBER_OF_DAYS_IN_A_WEEK - math.mod(listSize, NUMBER_OF_DAYS_IN_A_WEEK)); i++) {
                        APForecastExtWrapper blankSpace = new APForecastExtWrapper();
                        blankSpace.forecastDate = ' ';
                        blankSpace.apDollarAmount = NULL;
                        wrapperList.add(blankSpace);
                        //eeklyTotalPrevious = 0; 
                    }

            } 

            if(modulusRemainderInt == 0 || listSize == dayCount){
                        APForecastExtWrapper recordWeeklyTotal = new APForecastExtWrapper();
                        recordWeeklyTotal.forecastDate = 'Total';
                        recordWeeklyTotal.forecastLabel = 'Weekly Total';
                        recordWeeklyTotal.apDollarAmount = weeklyTotal;
                        wrapperList.add(recordWeeklyTotal);
                        weeklyTotal = 0; 

                        } 
    }




    public class APForecastExtWrapper{
        public double apDollarAmount {get;set;}
        public string forecastDate {get;set;}
        public string forecastLabel {get;set;}
    }
}