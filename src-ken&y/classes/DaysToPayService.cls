public with sharing class DaysToPayService 
{

	public map<string,list<customer_invoice__c>> mCustPymntToOpenInvoice = new map<string,list<customer_invoice__c>>();
	public map<string,Decimal> mCustPymntToDTP = new map<string,Decimal>();
    public set<string> mCustPymntKeys = new set<string>();
    public list<customer_invoice__c> updateList = new list<customer_invoice__C>();
    public list<customer_invoice__c> custPayWithoutDTPList = new list<customer_invoice__C>();
    public list<customer_invoice__c> ConsolidatedUpdateList = new list<customer_invoice__c>();
    public list<customer_invoice__c> custWithoutPaymentList = new list<customer_invoice__C>();
    public list<AggregateResult> ClosedCIByCustPayList = new list<AggregateResult>();
    public list<AggregateResult> AllCompClosedCI = new list<AggregateResult>();    
    public Decimal DTPTotal =0.0;
    public Id CompanyId;
    public set<string> QueryFields = new set<string>{'id','name','Bill_To_Customer__c' ,'Payment_Term__c','Payment_Due_Date__c','Date_Invoiced__c','Date_Time_Paid__c ','Period_Paid__c', 'DTPForecastDate__c'};
           

	public void setCompany(Id compId)
	{
		CompanyId=compId;
	}

    public string getDTPFilterFromCustomSetting()
    {
    	schemaUtil Util=SchemaUtil.getInstance();
        string CustomFilter='';
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
    			/*else if(FSR.getType()==DisplayType.Date)
                {
				   Integer year=Integer.valueof(d.Filterval__c.substringBefore ('-'));
 				   string rest=d.Filterval__c.substringAfter ('-');
 				   Integer month=Integer.valueOf(rest.substringBefore ('-'));
 				   rest=rest.substringAfter ('-');
 				   Integer day=Integer.valueof(rest.substringBefore (' '));
 				   rest=rest.substringAfter (' ');
                    system.debug('yyyymmm'+year+month+day);
                    datetime filterdt = datetime.newinstance(year,month,day);
                    date filterdate=filterdt.date();
                    system.debug('yyyymmm'+filterdate);
                   
                   CustomFilter =CustomFilter + ' and ' +d.name +'=\''+filterdate+'\'';                 
                   
                }*/
                else
                {
                   CustomFilter =CustomFilter + ' and ' +d.name +'='+d.Filterval__c;                 
                    
                }
            }
        }
        SYSTEM.debug('CustomFilter'+CustomFilter);
        return CustomFilter;
    }

    public list<customer_invoice__c> computeForecastDate(list<Customer_Invoice__c> CIList)
    {
    	ConsolidatedUpdateList= new list<customer_invoice__c>();
    	updateList= new list<customer_invoice__c>();
    	custWithoutPaymentList = new list<customer_invoice__c>();
    	custPayWithoutDTPList = new list<customer_invoice__c>();
 	    mCustPymntToOpenInvoice = new map<string,list<customer_invoice__c>>();

        
		for(customer_invoice__c ci: CIList)
        {
            if(ci.Payment_Term__c!=null && ci.Bill_To_Customer__c!=null )
            {
                string Key = ci.Bill_To_Customer__c+':'+ci.Payment_Term__c;
                if(mCustPymntToOpenInvoice.containskey(key))
                {
                    mCustPymntToOpenInvoice.get(key).add(ci);
                    
                }
                else
                {
                    list<customer_invoice__c> openCIList = new list<customer_invoice__c>();
                    openCIList.add(ci);
                    mCustPymntToOpenInvoice.put(key,openCIList);
                    
                }               
            }

             else  if(ci.Payment_Term__c==null && ci.Bill_To_Customer__c!=null )
                {
                    //Customers without Payment Term - We check for DTPHistory else we use the All customer DTP Average for past three months for recent 1000 iNVOICES
                     custWithoutPaymentList.add(ci);

                }
            else
            {
                  //If no  customer we skip updating forecast date on them.   
            }

        }
        if(custWithoutPaymentList.size()>0)
        {
        	checkForPaymentHistory(); //Adds Invoices to respective bucket lists based on presence or absence of DTP history
        	
        }                
        system.debug('InputKeys'+mCustPymntToOpenInvoice.keyset());
        system.debug('mCustPymntToOpenInvoice'+JSON.serialize(mCustPymntToOpenInvoice));

        updateList.addAll(summarizeByCustPayment(mCustPymntToOpenInvoice.keyset()));
        system.debug('Output-updatelist'+updatelist);
        return updateList;
  			
    }
    public list<customer_invoice__c> summarizeByCustPayment(set<string> custPayKeys)
    {
        Integer last3month =Date.today().month()-3;
        Integer last3yr;

        if(last3month < 0)
        {
            last3month =12+last3month;
            last3yr = Date.today().year()-1;
            
        }
        else
        {
            last3yr =Date.today().year();
        }
        date last3monthdate = datetime.newInstance(last3yr,last3month,1).date();
        
		set<string> CustInScope = new set<string>();
        set<string> PaymentInScope = new set<string>();
        for(string s:custPayKeys)
        {
            list<string> KeyList = s.split(':');
            CustInScope.add(KeyList.get(0));
            PaymentInScope.add(KeyList.get(1));
            
        }
        string customFilter = '';
        customFilter=getDTPFilterFromCustomSetting();
        system.debug(Logginglevel.INFO,'CustInScope'+CustInScope);
        system.debug(Logginglevel.INFO,'PaymentInScope'+PaymentInScope);
        system.debug(Logginglevel.INFO,'last3monthdate'+last3monthdate);

        SOQLUtil soql = new SOQLUtil('customer_invoice__c', true, true); //enforce fls = true, is aggregate query = true
        soql.addFields(new set<string>{
			'Bill_To_Customer__c Cust','Payment_Term__c Payment','avg(Days_to_Pay__c) Avg'        
        });
        soql.setWhereClause(
        	'status__c = \'Closed\' ' + customFilter +
			'and Date_Time_Paid__c=LAST_N_MONTHS:3 ' +
			'group by Bill_To_Customer__c ,Payment_Term__C ' +             
			'having Bill_To_Customer__c in :CustInScope ' +
			'and Payment_Term__C in :PaymentInScope '   	
        );

        system.debug('query'+soql.getQuery());
        ClosedCIByCustPayList=database.query(soql.getQuery());
        
        system.debug(Logginglevel.INFO,'Aggregates' + ClosedCIByCustPayList);
		       
        Boolean DTPFound;
        for(string s : custPayKeys)
        {
            DTPFound=false;
	        for(AggregateResult ar:ClosedCIByCustPayList)
	        {
	            list<string> slist=s.split(':');
	            DTPFound= false;
				if(ar.get('Cust')==sList[0] && ar.get('Payment')==sList[1])
	            {
	                 decimal avgdec= (decimal)ar.get('Avg');  
	                 integer avg = (integer)avgdec.round(System.RoundingMode.HALF_UP) ;
	                
	                 list<customer_invoice__c> custPayList =mCustPymntToOpenInvoice.get(s);
	                for(customer_invoice__c ci:custPayList)
	                {
	                    ci.DTPForecastDate__c=ci.Date_Invoiced__c.date().adddays(avg);
	                }
	                system.debug('Cust|Payment|Average'+ar.get('Cust')+ar.get('Payment')+Avg);
	                ConsolidatedUpdateList.addAll(custPayList);
	                
	                DTPFound = true;
	                break;
	            }
	             
	        }
            if(!DTPFound)
            {
                //Customers with Payment Term But no DTP History in past three months- We use All customer DTP Average for past three months
                custPayWithoutDTPList.addall(mCustPymntToOpenInvoice.get(s));
                system.debug('Customers without payment term and/or DTP History'+custPayWithoutDTPList);

            }
        }
        if(custPayWithoutDTPList.size()>0)
        {
        	//Get Customer Id without DTP
        	set<id> CustIdWithoutDTP = new set<id>();
        	for(customer_invoice__c ci:custPayWithoutDTPList)
        	{
        		CustIdWithoutDTP.add(ci.bill_to_customer__c);
        	}
     		//FIN-1049 Limiting the avg aggregation for last 1000 Closed CI to avoid 500001 governor limit error   	
        	list<customer_invoice__c> Last1000ClosedCIs = new list<customer_invoice__c>();
        	
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			soql = new SOQLUtil('customer_invoice__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name'
			});
			soql.setWhereClause('status__c=\'Closed\' and company__c=:CompanyId and Date_Time_Paid__c=LAST_N_MONTHS:3');
			soql.setOrderByClause('Date_Time_Paid__c desc');
			soql.setLimit(1000);
			Last1000ClosedCIs = Database.query(soql.getQuery());

            //FIN-654 Remove Divide By Zero exception
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			soql = new SOQLUtil('customer_invoice__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'avg(Days_to_Pay__c) TotAvg'
			});
			soql.setWhereClause('id in :Last1000ClosedCIs');
			AllCompClosedCI = Database.query(soql.getQuery());

            system.debug('AllCompClosedCIForCust'+AllCompClosedCI);
            if(AllCompClosedCI[0].get('TotAvg')!=null)
            {
                decimal Totavgdec= (decimal)AllCompClosedCI[0].get('TotAvg');  
                integer DTPTotRound = (integer)Totavgdec.round(System.RoundingMode.HALF_UP) ;
                for(customer_invoice__c ci:custPayWithoutDTPList)
                {
                    ci.DTPForecastDate__c=ci.Date_Invoiced__c.date().adddays(DTPTotRound);
                    
                }
                ConsolidatedUpdateList.addAll(custPayWithoutDTPList);                                   
            }
            else
                {
                       //Skip updating Customer without DTP 
                       //as there are no closed Invoices in past three months for any Customer             
                }

               
        }
        
	    system.debug('ConsolidatedUpdateList'+JSON.serialize(ConsolidatedUpdateList));

        return ConsolidatedUpdateList;
    }
    public void checkForPaymentHistory()
    {
    	   //Get map of customers without payment term to their list of open customer invoices
    	    map<id,list<customer_invoice__c>> mCustToInvoices = new map<id,list<customer_invoice__c>>();
        	for(customer_invoice__c ci:custWithoutPaymentList)
        	{
        		if(mCustToInvoices.containskey(ci.bill_to_customer__c))
        		{
        			mCustToInvoices.get(ci.bill_to_customer__c).add(ci);
        		}
        		else
        		{
        			mCustToInvoices.put(ci.bill_to_customer__c,new list<customer_invoice__c>{ci});
        			
        		}
        	}
        	system.debug('Inside check paymenthistory'+mCustToInvoices);
        	//Get DTP Avg for All closed CI for the customers without paymentterm in batch scope irrespective of payment term 
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('customer_invoice__c', true, true); //enforceFLS=true, running in user mode.  aggregate query = true
			soql.addFields(new set<string>{
				'Bill_To_Customer__c Cust','avg(Days_to_Pay__c) TotAvg'
			});
			Set<Id> IdSet = mCustToInvoices.keyset();
			soql.setWhereClause('Date_Time_Paid__c !=null and status__c = \'Closed\' and Date_Time_Paid__c=LAST_N_MONTHS:3 and Bill_To_Customer__c in :IdSet and Bill_To_Customer__c!=null group by Bill_To_Customer__c');
			list<aggregateresult> ClosedCIForCust = Database.query(soql.getQuery());

        system.debug('Inside ClosedCIForCust'+ClosedCIForCust);
				                                           
           if(ClosedCIForCust.size()>0)	
           {
           	 for(AggregateResult ar:ClosedCIForCust)
           	 {
           	 	if(ar.get('Cust')!=null) //Additional null check apart from query
           	 	{
           	 		list<customer_invoice__c> invoicesToUpdate = new list<customer_invoice__c>();
	           	 	invoicesToUpdate.addall(mCustToInvoices.get((id)ar.get('Cust')));     	 	
	                decimal Totavgdec= (decimal)ar.get('TotAvg');  
		                if(Totavgdec!=null)//Found DTP History for this customer without payment term 
		                {
		                	
		                    integer DTPTotRound = (integer)Totavgdec.round(System.RoundingMode.HALF_UP) ;
			                for(customer_invoice__c ci:invoicesToUpdate)
			                {
			                    ci.DTPForecastDate__c=ci.Date_Invoiced__c.date().adddays(DTPTotRound);
			                    
			                }
			                system.debug('Days to pay for customer '+ar.get('Cust')+'without payment term is '+DTPTotRound);
			                ConsolidatedUpdateList.addAll(invoicesToUpdate);        	 		
		           	 	}
		           	 	else
		           	 	{
		           	 		custPayWithoutDTPList.addAll(invoicesToUpdate);//No DTP history found 
		           	 	}	                	
	            }
	            system.debug('ConsolidatedUpdateList'+ConsolidatedUpdateList);

           	 }
           	
           }
           else //None of the customers without payment term in batch scope have DTP history.Add it to no dtp found bucket to get all company aggregates
           {
           	  custPayWithoutDTPList.addAll(custWithoutPaymentList);//No DTP history
           	
           }
    }


}