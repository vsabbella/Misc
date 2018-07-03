@istest
public class CashForecastTest 
{


    public class SampleData
    {
        public list<customer__c> custlist;
        public list<Payment_Term__c> termList = new list<Payment_Term__c>(); 
        public Testdataforfinance td = new testdataforfinance();

        
        public SampleData()
        {
            termList = new list<Payment_Term__c>(); 
            Payment_Term__c p1 = new Payment_Term__c();
            
            p1.name= '2/10Discount 10'; 
            p1.Type__c = KSE.PAYMENT_TERM_DUE_DAYS;
            p1.Due_Days__c = 0;
            termList.add(p1); 
            Payment_Term__c p2 = new Payment_Term__c();
            p2.name = '2/11Discount 11';
            p2.Type__c = KSE.PAYMENT_TERM_DUE_DAYS;
            p2.Due_Days__c = 0; 
            termList.add(p2); 
            insert termList;
            Test.startTest();
            custList = [select id,name from customer__c
                                          where recordtypeId = :td.CustomerRecordTypes.get('Bill_To')];
            
            //Create closed customer invoice for each customers
            //Date invoiced month start ;date paid ->month*2  ;dtp=month*2-1;
            list<customer_invoice__c> ciList = new list<customer_invoice__c>();
            
            for(customer__c c :custList)
            {
                //Require 3 months DTP Avg.Based on current month create historical data
                integer currmonth = system.now().month();
                integer curryear; 
                boolean isPrevRolling=false;
                if(currmonth>3)
                {
                    curryear= system.now().year();
                }
                else
                {
                    curryear = system.now().year()-1;
                    currmonth=12;
                    isPrevRolling=true;
                }
                if(isPrevRolling)
                {
                    cilist.addAll(createClosedCI(c,curryear,currmonth));

                    curryear= system.now().year();
                    currmonth = system.now().month();
                                        
                    ciList.addAll(createClosedCI(c,curryear,currmonth));
                    
                }
                    ciList.addAll(createClosedCI(c,curryear,currmonth));
                
    
                
            }
            insert ciList;
            generateCIL(ciList)  ; 
            closeCIs(ciList);
            
            
            //Create Open CIs- customer 1,customer 2 with payment term p1 for current month
            list<customer_invoice__c> OpenCIList = new list<customer_invoice__c>();
            Integer i=0;//alternate payment terms for customers.

            for(customer__c c1 :custList)
            {
                for(i=0;i<31;i++)
                {
                    customer_invoice__c ci = new customer_invoice__c();
                    ci.Bill_To_Customer__c = c1.id;
                    ci.company__c=td.company.id;
                    ci.Payment_Term__c =termList[1].id;
                    ci.Date_Invoiced__c = system.now().date().tostartofmonth().adddays(i);
                    ci.Transaction_Date__c = system.now().date().tostartofmonth().adddays(i);
                    ci.status__c='Open';
                    //i=i==1?0:i+1;
                    OpenCIList.add(ci);        
                }                
            }
            

            insert OpenCIList;
            generateCIL(OpenCIList)  ; 

			list<customer_invoice__C> OpenCINoDTP = new list<customer_invoice__C>();            
            //CI with bill to customer having new payment term-No DTP history
                    customer_invoice__c ci = new customer_invoice__c();
                    ci.Bill_To_Customer__c = custlist[0].id;
                    ci.company__c=td.company.id;
                    ci.Payment_Term__c =termList[0].id;
                    ci.Date_Invoiced__c = system.now().date().tostartofmonth().adddays(i);
                    ci.Transaction_Date__c = system.now().date().tostartofmonth().adddays(i);
                    ci.status__c='Open';
                    //i=i==1?0:i+1;
                    OpenCINoDTP.add(ci);              
            //CI with bill to customer having no payment term
                     customer_invoice__c ci1 = new customer_invoice__c();
                    ci1.Bill_To_Customer__c = custlist[0].id;
                    ci1.company__c=td.company.id;
                    ci1.Date_Invoiced__c = system.now().date().tostartofmonth().adddays(i);
                    ci1.Transaction_Date__c = system.now().date().tostartofmonth().adddays(i);
                    ci1.status__c='Open';
                    //i=i==1?0:i+1;
                    OpenCINoDTP.add(ci1);   
            insert OpenCINoDTP;
            generateCIL(OpenCINoDTP)  ; 

                   
        }
        
        public void generateCIL(list<customer_invoice__c> ciList)
        {
            //Generate Customer invoice lines.
            list<customer_invoice_line__c> cilList = new list<customer_invoice_line__c>();
            for(customer_invoice__c ci:ciList)
            {
                customer_invoice_line__c cil = new customer_invoice_line__C();
                cil.Customer_Invoice__c=ci.id;
                cil.Quantity_Shipped__c=2;
                cil.Unit_Price__c=50.00;
                cilList.add(cil);
                ci.finalized__c=true;
            }
            insert cilList;
            //make CI as finalized.
            update cilist;
        }
        
        public void closeCIs(list<customer_invoice__c> ciList)
        {
             //AR-134  fix.
            //Make a payment.
			for(customer_invoice__c ci:ciList)
            {
               ci.status__c='Closed';                
               ci.Amount_Paid__c=100;//The Total Line Amount  
            }
            update cilist;
			//Update Payment date to build dtp History.
            for(customer_invoice__c ci:ciList)
            {
                integer i=ci.Date_Invoiced__c.month();
                ci.Date_Time_Paid__c = ci.Date_Invoiced__c.adddays(i*2);
            }
            update cilist;
            list<customer_invoice__c> ciafterUpdate=[select id,name,status__c,balance__c,Date_Time_Paid__c from customer_invoice__c where id in :cilist];
           // system.assertEquals(ciafterUpdate, null);
            for(customer_invoice__c ci:ciafterUpdate)
            {
                system.assertEquals(ci.balance__c,0,'Balance should be 0 to close the Invoice');
                system.assertEquals(ci.Status__c,'Closed','The status update on the Invoice should be successful as balance is 0');                
            }
        }
        public list<customer_invoice__c> createClosedCI(customer__c c,integer curryear,integer currmonth)
        {
            list<customer_invoice__c> ciList = new list<customer_invoice__c>();
            for(integer i=1;i<=currmonth;i++)
            {
                customer_invoice__c ci = new customer_invoice__c();
                ci.Bill_To_Customer__c = c.id;
                ci.company__c=td.company.id;
                ci.Payment_Term__c =termList[1].id;
                //This stores the datetime in GMT+8 as opposed to .date() which used stored GMT Midnight.Subsequent month() calls returned prev-month causing incorrect cashforecast.
                ci.Date_Invoiced__c = (datetime.newinstance(curryear,i,1));                  
                ci.Transaction_Date__c = (datetime.newinstance(curryear,i,1));                 
                ci.status__c='Open';
              
                ciList.add(ci);        
            }    
            return ciList;
        }
    }
    
    
    
    
    
    
    public static testmethod void testDTPBatch()
    {
        if(KSE.checkTestDispatch()){return;}        
        
        SampleData s = new SampleData();
        list<customer_invoice__c> BeforeopenCI=[Select id,name,DTPForecastdate__c 
                                                from customer_invoice__c 
                                                where status__c='Open' and Finalized__c=true ];
        system.assert(BeforeopenCI.size()>0, 'There should be scope for the Batch');
        for(customer_invoice__c ciBefore: BeforeopenCI)
        {
            system.assertEquals(null, ciBefore.DTPForecastdate__c, 'Forecast date should be empty before Batch');
            
        }
       // DaysToPayService DTPService = new DaysToPayService();
       // system.assertEquals(null, DTPService.getDTPFilterFromCustomSetting());
        DTPBatch dp = new DTPBatch(s.td.company.id);
        system.assertNotEquals(dp.companyid, null);
        database.executeBatch(dp);
        test.stopTest();
        list<customer_invoice__c> AfteropenCI=[Select id,name,DTPForecastdate__c
                                               ,Bill_To_Customer__c,Date_Invoiced__c,Payment_Term__c
                                               from customer_invoice__c 
                                               where status__c='Open' and Finalized__c=true ];
        //system.assertEquals(AfteropenCI, null);
        //Check forecast computation for customer with closed invoice in last 3 month.
        list<aggregateresult> closedCI=[Select Bill_To_Customer__c,Payment_Term__c,
                                               avg(days_to_pay__c) avg
                                               from customer_invoice__c 
                                               where status__c='Closed' 
                                               and Finalized__c=true 
                                               and Date_Time_Paid__c=LAST_N_MONTHS:3
                                               group by Bill_To_Customer__c,Payment_Term__c
                                               having Bill_To_Customer__c=:s.custlist[0].id
                                               and Payment_Term__c=:s.termlist[1].id];
        //Get All customer 3 month avg Aggregate
        list<aggregateresult> AllCustClosedCI=[Select 
                                        avg(days_to_pay__c) avgToT
                                        from customer_invoice__c 
                                        where status__c='Closed' 
                                        and Finalized__c=true 
                                        and Date_Time_Paid__c=LAST_N_MONTHS:3];

        
        //Get All customer DTP Avg
        Decimal DTPTotal=(decimal)AllCustClosedCI[0].get('avgToT');
        integer DTPTotRound = (integer)DTPTotal.round(System.RoundingMode.HALF_UP) ;      
        
        for(customer_invoice__c ciAfter: AfteropenCI)
        {
            system.assertNotEquals(null, ciAfter.DTPForecastdate__c, 'Forecast date should not be empty after Batch');
			if(ciAfter.Bill_To_Customer__c==s.custlist[0].id && ciAfter.Payment_Term__c==s.termlist[1].id)  
            {
                decimal avgdec= (decimal)closedCI[0].get('Avg');  
                integer avg = (integer)avgdec.round(System.RoundingMode.HALF_UP) ;
                date expdate= ciAfter.Date_Invoiced__c .date().adddays(avg);
                system.assertEquals(expdate, ciAfter.DTPForecastdate__c,'DTP Avg is the last 3 month avg for cust,paymnt');
            }
			if(ciAfter.Bill_To_Customer__c==s.custlist[0].id && ciAfter.Payment_Term__c==s.termlist[0].id)  
            {
   
                date expdate= ciAfter.Date_Invoiced__c .date().adddays(DTPTotRound);
                system.assertEquals(expdate, ciAfter.DTPForecastdate__c,'DTP Avg for Cust with NO DTP history is the threemonth DTP Avg across all customer');
            }  
			if(ciAfter.Bill_To_Customer__c==s.custlist[0].id && ciAfter.Payment_Term__c==null)  
            {

                date expdate= ciAfter.Date_Invoiced__c .date().adddays(DTPTotRound);
                system.assertEquals(expdate, ciAfter.DTPForecastdate__c,'DTP Avg for Cust without Payment is the threemonth DTP Avg across all customer');
            }             
            
            
        }
        
    }


    
    
    
    public static testmethod void testCashForecast()
    {
        if(KSE.checkTestDispatch()){return;}        
        
        sampledata s = new sampledata();

        date expDate,currDate=system.now().date(),expstartWeekdate;
        integer i=0;
        integer dtp=0;
        decimal dtpdec=0.0;

        list<integer> prev3months = new list<integer>();
        prev3months.add(system.now().date().addmonths(-3).month());
        prev3months.add(system.now().date().addmonths(-2).month());
        prev3months.add(system.now().date().addmonths(-1).month());

        while(i<3)
        {
            dtpdec=dtpdec+(prev3months.get(i)*2)-1;
            i++;
        }
        
        dtp=(integer)(dtpdec/3).round(System.RoundingMode.HALF_UP);
        // Aim is to assert the expected cash amount for CIs invoiced first of month.Four CI with $100 each satisy the criteria
        expdate=system.now().date().toStartOfMonth().adddays(dtp);//date in which invoices on first of month will b paid.
       
        system.debug(logginglevel.INFO,'expdate'+expdate);
        system.debug(logginglevel.INFO,'currdate'+currdate);



        
        DTPBatch dp = new DTPBatch(s.td.company.id);
        database.executeBatch(dp);
        test.stopTest();
        
        CashForecastExt cf = new CashForecastExt();
        integer daysbetween = currdate.daysbetween(expdate);
        //Get the cash amount from cash report map based on the daybetween exp date and current date 
        
        //if forcastdate is  in the current 27 days  window 

        if(daysbetween >= 0 && daysbetween <= 26)
        {
            for(string rowkey:cf.cashReport.keyset())
            {
                for(cashforecastext.cashForecastWrapper cfw:cf.cashreport.get(rowkey))
                {
                    if(cfw.forecastdate==string.valueof(expdate))
                    {
                        system.assertequals(400,cfw.cashexpected,'Aggregation wrong-(Four CI of $100 each in sampledata)');
                    }
                    
                    
                }
            }
        }
        
        //if forcastdate is  in the last 6 days  window 
        else if(daysbetween<0 && daysbetween>-7 )
        {

            for(cashforecastext.cashForecastWrapper cfw:cf.prevcashReport)
            {
                if(cfw.forecastdate==string.valueof(expdate))
                {
                    system.assertequals(400,cfw.cashexpected,'Aggregation wrong-(four CI of $100 each in sampledata)');
                }

                    
            }
       
                    
        }
        //if forcastdate is  in the prior or later buckets 
        
        else
        {
            if(expdate<currdate)
            {
                system.assert(cf.prevcashReport.get(0).cashexpected>=400,'prior bucket should have atleast 400 added from CI on month 1st');
            }
            else
            {
                system.assert(cf.cashReport.get('Row4').get(6).cashexpected>=400,'Later bucket should have atleast 400 added from CI on month 1st');
                
            }
        }
        
        
    }
    
    
    
    
}