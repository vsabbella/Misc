public with sharing class CashForecastExt
{
    date startdate;
    date enddate;
    date prevexpdate;
    public date currdate{get;set;}
    public map<date,string> mRowStartDate = new  map<date,string>();
    
    public list<string> strings {get;set;}
    public list<cashForecastWrapper> ck{get;set;}
    public map<string,list<cashForecastWrapper>> cashReport{get;set;} 
    public list<cashForecastWrapper> prevcashReport{get;set;}  
    public double grandtotal{get;set;}
    
    public string HelpURL{get;set;}
 
 // FIN-851 Need to filter by custom setting    
    public string baseWhereClause,CustomFilter,GroupClause;
    public string DateFilterCurr,DateFilterPrev,DateFilterPrior,DateFilterLater;
    public string query1,query2,query3,query4;
	public Set<String> BaseQueryFields1, BaseQueryFields2;    

    public SchemaUtil util = SchemaUtil.getInstance();
    
    public CashForecastExt()
    {
        currdate = system.now().date();
        startdate = currdate;
        prevexpdate=startdate.adddays(-6);//Last date before prior bucketing
        enddate = currdate.addDays(26);  //Last date after which there is Later Bucketing
        cashReport = new map<string,list<cashForecastWrapper>> ();
        grandtotal=0;
        buildStartDatemap(); //Build row startDates
        
       //Get filter values from DTPFilter__c custom setting
        CustomFilter='';

        list<DTPFilter__c> DTPFilters = DTPFilter__c.getAll().values();
        Map<String, Schema.SObjectField> fieldMap = util.getFieldsMap('Customer_invoice__c');

       
        for(DTPFilter__c d:DTPFilters)
        {
            if(fieldMap.containskey(d.name))
            {
                Schema.SObjectField field=fieldMap.get(d.name);
                Schema.DescribeFieldResult FSR=field.getDescribe();
				if(FSR.getType()==DisplayType.String || FSR.getType()==DisplayType.Picklist )
                {
                  CustomFilter =CustomFilter + ' and ' +d.name +'=\''+d.Filterval__c+'\'';                 
                    
                }
                else
                {
                   CustomFilter =CustomFilter + ' and ' +d.name +'='+d.Filterval__c;                 
                    
                }
            }
        }
        system.debug(logginglevel.INFO,'+customfilter+'+customfilter);
        
        //Construct Dynamic Query for various Buckets
		BaseQueryFields1 = new set<string>{'sum(Total_Amount__c) sum', 'DTPForecastDate__c fdate'};	
		BaseQueryFields2 = new set<string>{'sum(Total_Amount__c) sum'};	  		
		baseWhereClause = 'status__c =\'Open\'';		
        
        DateFilterCurr ='  and DTPForecastDate__c > = :startDate and DTPForecastDate__c < = :enddate and DTPForecastDate__c!=null ';
        DateFilterPrev ='  and DTPForecastDate__c >=  :prevexpdate and DTPForecastDate__c <  :startDate and DTPForecastDate__c!=null ';    
        DateFilterPrior='  and DTPForecastDate__c <  :prevexpdate and DTPForecastDate__c!=null ';    
        DateFilterLater='  and DTPForecastDate__c >  :enddate    and DTPForecastDate__c!=null ';    

        GroupClause = ' group by DTPForecastDate__c ';        
        getCashForecastData();
        HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpCashForecast';
        
    }
    public void getCashForecastData()
    {
    	
        SOQLUtil soql = new SOQLUtil('customer_invoice__c');
        soql.addFields(BaseQueryFields1);
        soql.setWhereClause(baseWhereClause + DateFilterCurr + customfilter + GroupClause);
        system.debug(logginglevel.INFO,'+query1+'+soql.getQuery());
        list<aggregateresult> openCICurrBucket = database.query(soql.getQuery());     
        
        soql = new SOQLUtil('customer_invoice__c');
        soql.addFields(BaseQueryFields1);
        soql.setWhereClause(baseWhereClause + DateFilterPrev + customfilter + GroupClause);        
        system.debug(logginglevel.INFO,'+query2+'+soql.getQuery());        
		list<aggregateresult> openCIPrevExpBucket = database.query(soql.getQuery());     
        
        soql = new SOQLUtil('customer_invoice__c');
        soql.addFields(BaseQueryFields2);
        soql.setWhereClause(baseWhereClause + DateFilterPrior + CustomFilter);             
        system.debug(logginglevel.INFO,'+query3+'+soql.getQuery());                
        list<aggregateresult> openCIPriorBucket = database.query(soql.getQuery());     
        
        soql = new SOQLUtil('customer_invoice__c');
        soql.addFields(BaseQueryFields2);
        soql.setWhereClause(baseWhereClause + DateFilterLater + CustomFilter);   
        system.debug(logginglevel.INFO,'+query4+'+soql.getQuery());                        
        list<aggregateresult> openCILaterBucket =  database.query(soql.getQuery());

        system.debug(logginglevel.info,'openCIAggregates'+openCICurrBucket);
        system.debug(logginglevel.info,'openCIPrevExpBucket'+openCIPrevExpBucket);
        system.debug(logginglevel.info,'openCIPriorBucket'+openCIPriorBucket);
        system.debug(logginglevel.info,'openCILaterBucket'+openCILaterBucket);    
        cashReport= buildCashForecastReport(openCICurrBucket,openCIPriorBucket,openCIPrevExpBucket,openCILaterBucket);
        system.debug(logginglevel.info,'cashReport'+cashReport);
        
    }
    
    public map<string,list<cashForecastWrapper>> buildCashForecastReport(list<aggregateresult> curr,list<aggregateresult> prior,list<aggregateresult> exp,list<aggregateresult> later)
    {
        
        
        //Map of forecastDate to Invoice amount for easy retrieval
        map<date,double> expAggrMap= new map<date,double>();
        
        for(aggregateresult ar: exp)
        {
            expAggrMap.put((date)ar.get('fdate'),(double)ar.get('sum'));
        }
        
        
        //Build prev expected list
        prevcashReport = new list<cashForecastWrapper>();
        
        integer pi=1;
        double prevtotal=0;
        date pwDay = prevexpdate;
        while(pi<=6)
        {
            
            date forecastdate = pwDay;
            cashForecastWrapper cfw = new cashForecastWrapper();
            cfw.forecastDate = string.valueOf(forecastdate);
            if(expAggrMap.containskey(pwDay))
            {
                cfw.CashExpected = expAggrMap.get(pwDay);                
            }
            else
            {
                cfw.CashExpected = 0;                
                
            }
            prevtotal=prevtotal+cfw.cashexpected;
            cfw.sortorder=forecastdate;
            prevcashReport.add(cfw);
            pwday=prevexpdate.adddays(pi);
            pi++;
            
        }
        //Append prior bucket Data
        cashForecastWrapper cfw1 = new cashForecastWrapper();
        cfw1.forecastDate = 'Prior';
       // cfw1.sortorder=date.valueof('0001-01-01');//To Ensure it gets sorted first
        cfw1.sortorder=null;                        
        
        if((double)prior[0].get('sum')!=null)
        {
            system.debug('prior'+prior);
            cfw1.CashExpected = (double)prior[0].get('sum');
            prevtotal=prevtotal+cfw1.CashExpected ;
            
        }
        else
        {
            cfw1.CashExpected=0;  
        }
        prevcashReport.add(cfw1);
        
        system.debug('prevcashReport'+prevcashReport);
        
        //Append prev anticipated sub total
        cashForecastWrapper cfw2 = new cashForecastWrapper();
        cfw2.forecastDate = 'Total';
        cfw2.CashExpected = prevtotal;
        //cfw2.sortorder=date.valueOf('9999-12-02');//To ensure it gets sorted Last
        cfw2.sortorder=null;                        
        prevcashReport.add(cfw2);
        
        prevcashReport.sort();
        
        grandtotal=grandtotal+prevtotal;
       
        //Map of forecast dates in current rolling window to their respective sums for easy retrieval
        map<date,double> currAggrMap= new map<date,double>();
        
        for(aggregateresult ar: curr)
        {
            currAggrMap.put((date)ar.get('fdate'),(double)ar.get('sum'));
        }
        map<string,list<cashForecastWrapper>> mcf = new map<string,list<cashForecastWrapper>> ();
        
        //Build Future Expected Row map
        
        for(date d :mRowStartDate.keyset())
        {
            integer i=1,j=7;
            string rowkey = mRowStartDate.get(d);
            date wDay=d;
            //if row4 build only for 6 days +Later Bucket
            if(rowkey=='row4')
            {
                j=6;
                //Add Later bucket.Sortorder ensures it gets appended last.
                cashForecastWrapper cfw = new cashForecastWrapper();
                cfw.forecastDate = 'Later';
                if((double)later[0].get('sum')!=null)
                {
                    system.debug('later'+later);
                    cfw.CashExpected = (double)later[0].get('sum');
                    
                }
                else
                {
                    cfw.CashExpected=0;  
                }
               // cfw.sortorder=date.valueOf('9999-12-01');//To ensure it gets sorted second Last.
                cfw.sortorder=null;                        
                
                mcf.put(rowkey,new list<cashForecastWrapper>{cfw});
                
            }
            while(i<=j )
            {
                //If aggregate result contains forecast date,retrieve expected cash.Else,put 0.
                
                if(currAggrMap.containsKey(wDay))
                {
                    
                    date forecastdate = wDay;
                    cashForecastWrapper cfw = new cashForecastWrapper();
                    cfw.forecastDate = string.valueOf(forecastdate);
                    cfw.CashExpected = currAggrMap.get(wDay);
                    cfw.sortorder=forecastdate;
                    if(mcf.containskey(rowkey))
                    {
                        mcf.get(rowkey).add(cfw);
                    }
                    else 
                    {
                        
                        mcf.put(rowkey,new list<cashForecastWrapper>{cfw});
                    }
                    
                }   
                
                
                else
                {
                    date forecastdate = wDay;
                    
                    cashForecastWrapper cfw = new cashForecastWrapper();
                    cfw.forecastDate = string.valueOf(wDay);
                    cfw.CashExpected = 0;
                    cfw.sortorder=forecastdate;
                    if(mcf.containskey(rowkey))
                    {
                        mcf.get(rowkey).add(cfw);
                    }
                    else
                    {
                        
                        mcf.put(rowkey,new list<cashForecastWrapper>{cfw});
                    }   
                }
                wDay=d.adddays(i); //Build for consecutive 7/6 days in the row. 
                i++;
                
            } 
        }
        
        //Compute weekly totals and sort 
        
        for(string rowkey :mcf.keyset())
        {
            double Total =0;
            for(cashForecastWrapper cfwl:mcf.get(rowkey))
            {
                total=total+cfwl.CashExpected;
            }
            cashForecastWrapper cfw = new cashForecastWrapper();
            cfw.forecastDate = 'Total';
            cfw.CashExpected = total;  
           // cfw.sortorder=date.valueOf('9999-12-03'); //To ensure totals get appended last. 
            cfw.sortorder=null;                        
            mcf.get(rowkey).add(cfw);
            system.debug('mcf-Row Map before sort'+mcf);
            mcf.get(rowkey).sort();
            system.debug('mcf-Row Map After Sort'+mcf);
            grandtotal=grandtotal+total;
            
        }
        system.debug(logginglevel.info,'mcf'+mcf);
        
        return mcf;
    }
    public void buildStartDatemap()
    {
        Integer days=0;
        for(integer i=1;i<=4;i++)
        {
            mRowStartDate.put(currdate.adddays(days),'Row'+i);
            days=days+7;
            
        }
    }
    
    public class cashForecastWrapper implements comparable
    {
        public string forecastDate{get;set;} 
        public double CashExpected{get;set;}
        public date sortorder{get;set;}  
        
        public Integer compareTo(Object compareTo) {
            cashForecastWrapper compareToCFW= (cashForecastWrapper)compareTo;
            if(compareToCFW.forecastDate=='Prior') return 1;
            if(this.forecastDate=='Later' && compareToCFW.forecastdate=='Total' )return -1;
            if(this.forecastDate=='Later' && compareToCFW.sortorder!=null ) return 1;
            if(this.forecastDate=='Total' && compareToCFW.sortorder!=null ) return 1; 

            if ((sortorder == compareToCFW.sortorder) )return 0;
            if ((sortorder > compareToCFW.sortorder)) return 1; 
            return -1;  
        }
        
    }
    
}