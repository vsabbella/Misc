@isTest(SeeAllData='true')
public class ReconRemoteReportAPITest {/*
    
    GL_Type__c CurrentAssets = new GL_Type__c();
    public GL_Account__c ReconGL  = new GL_Account__c();
    public company__c ReconCompany = new company__c();
    public period__c ReconPeriod = new Period__c();
    public Reconciliation__c recon;
    
    public ReconRemoteReportAPITest() {
       list<company__c> existingComp = [select id,name from  company__c limit 1];
       list<period__c> existingPeriod=  [select id,name from period__c where company__c=:existingComp limit 1];
       list<GL_Account__c> existingGL = [select id,name from GL_Account__c limit 1];
       CreateData cd = new CreateData();
       ReconCompany = existingComp.size()>0?existingComp[0]:cd.company;
       ReconPeriod  = existingPeriod.size()>0 ?existingPeriod[0]:cd.periodlist[0];
       ReconGL =  existingGL.size()>0 ?existingGL[0]:cd.cashGL;
       recon = new Reconciliation__c();
       recon.name='Test Recon';
       recon.GL_Account__c=ReconGL.Id;
       recon.period__c=ReconPeriod.Id;
       recon.company__c=ReconCompany.Id;
       insert recon;
    }
    public class createData
    {
                public Account newAccount() {
                    Account account = new Account();
                    account.name = 'Kenandy';
                    account.billingstreet = '2055 Woodside Rd. Ste 110';
                    account.billingcity = 'Redwood City';
                    account.billingstate = 'CA';
                    account.billingpostalcode = '94061';
                    account.billingcountry = 'USA';
                    account.shippingstreet = '2055 Woodside Rd. Ste 110';
                    account.shippingcity = 'Redwood City';
                    account.shippingstate = 'CA';
                    account.shippingpostalcode = '94061';
                    account.shippingcountry = 'USA';
                    account.phone = '650-468-2000';
                    account.fax = '650-468-2010';
                    account.website = 'kenandy.com';
                    return account;
                }  	
                    public Account account {
                get {
                    if (account == null) {
                        account = newAccount();
                        //account.name = 'KenandyTestFuel'+ '-' + String.ValueOf(Math.round(Math.random(), 2));
                        account.name = 'KenandyTestFuel'+ '-' + String.ValueOf((Integer) (Math.random () * 999));
                        account.billingstreet = '303 Twin Dolphin Drive, Suite 500';
                        account.billingcity = 'Redwood City';
                        account.billingstate = 'CA';
                        account.billingpostalcode = '94065';
                        account.billingcountry = 'USA';
                        account.shippingstreet = '303 Twin Dolphin Drive, Suite 500';
                        account.shippingcity = 'Redwood City';
                        account.shippingstate = 'CA';
                        account.shippingpostalcode = '94065';
                        account.shippingcountry = 'USA';
                        account.phone = '650-468-2000';
                        account.fax = '650-468-2010';
                        account.website = 'kenandy.com';
                        insert account;
                    }
                    return account;
                }
                set;
            }
            public Company__c company {
                get {
                    if (company == null) {
                        company = new Company__c();
                            company.name = 'KenandyTestFuel'+ '-' + String.ValueOf((Integer) (Math.random () * 999));
                            company.Address__c = account.ID;
                            company.A_Days__c = 30;
                            company.B_Days__c = 60;
                            company.C_Days__c = 180;
                            company.Company_Identifier__c = 'KEN' + '-' + String.ValueOf((Integer) (Math.random () * 999));
                            company.Comp_Currency__c = TestFuel.currencySGD.id;
                            company.Consol_Currency__c = TestFuel.currencyEUR.id;
                            company.Stat_Currency__c = TestFuel.currencyGBP.id;
                            company.Subs_Currency__c = TestFuel.currencyUSD.id;
                            company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
                            //company.Finalize_Supplier_Invoices_w_Exceptions__c = false; //KNDY-2817
                            insert company;
                    }
                    return company;
                }
                set;
            }
            public GL_Type__c CurrentAssets{
                get{
                    if(currentAssets == null){
                        currentAssets = new GL_Type__c();
                        currentAssets.Name  = 'Current Assets';
                        currentAssets.Normal_Balance__c  = 'Debit';
                        currentAssets.Accounting_Type__c  = 'Assets';
                        currentAssets.Statement_Type__c  = 'Balance Sheet';
                        currentAssets.Account_Range_From__c = '1111110000';
                        currentAssets.Account_Range_To__c ='1111114999';
                        
                        insert currentAssets;
                    }
                    return currentAssets;
                }
                set;
            }      
            public GL_Account__c  cashGL {
             get{
               if(cashGL == null){
                cashGL = new GL_Account__c();
                cashGL.Name = '1111110000 - Cash';
                cashGL.GL_Account_Number__c = '1111110000';
                cashGL.GL_Account_Name__c = 'Cash';
                cashGL.active__c = true;
                cashGL.Report_Section__c = 'Current Assets';  
                cashGL.Normal_Balance__c = 'Debit';
                cashGL.Statement_Type__c = 'Balance Sheet';
                cashGL.Report_Section_Grouping__c = 'Assets';
                cashGL.Cash_Flow_Report_Section_Grouping__c = 'Operating Cash Flow';
                cashGL.non_cash__c = true;
                cashGL.GL_Type__c = currentAssets.id;
                insert cashGL;
                }
              return cashGL;
            }
                set;
        }
        public List<Period__c> periodList = new List<Period__c>();{
                          
        	integer year = system.now().year();
   			periodList = new List<Period__c>();
   			for(integer i=1; i<=12; i++){
			    Period__c iPeriod = new Period__c();
			    iPeriod.Name = string.valueOf(i) + '-' + string.valueOf(year);
			    iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
			    iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
			    iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
			    iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
			    iPeriod.Period_Number__c = i;
			    if(i>=1 && i <= 3){
			        iPeriod.Quarter_Number__c = 1;
			    }else if(i>=4 && i <= 6){
			        iPeriod.Quarter_Number__c = 2;
			    }else if(i>=7 && i <= 9){
			        iPeriod.Quarter_Number__c = 3;
			    }else if(i>=10 && i <= 12){
			        iPeriod.Quarter_Number__c = 4;
			    }	
			    
			    iPeriod.Fiscal_Year__c = String.valueOf(year);
			    iPeriod.Company__c = company.Id;
			    iPeriod.Adjustment_Period__c = false;
			    iPeriod.Closed__c = false;
			    iPeriod.Open__c = i >= system.now().month();
			    iPeriod.Fiscal__c = true;
			    iPeriod.Corporate__c = false;
			    iPeriod.Tax__c = false;
			    iPeriod.Permanently_Closed__c = false;
			    iPeriod.Adjustment_Period__c = false;
			    
			    iPeriod.AP_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.AR_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.Shipment_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.Receiving_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.FA_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.Inventory_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.JE_Cutoff__c = iPeriod.Period_End__c;
			    
			    periodList.add(iPeriod);
			}
			
			year++;
			for(integer i=1; i<=12; i++){
			    Period__c iPeriod = new Period__c();
			    iPeriod.Name = string.valueOf(i) + '-' + string.valueOf(year);
			    iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
			    iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
			    iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
			    iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
			    iPeriod.Period_Number__c = i;
			    if(i>=1 && i <= 3){
			        iPeriod.Quarter_Number__c = 1;
			    }else if(i>=4 && i <= 6){
			        iPeriod.Quarter_Number__c = 2;
			    }else if(i>=7 && i <= 9){
			        iPeriod.Quarter_Number__c = 3;
			    }else if(i>=10 && i <= 12){
			        iPeriod.Quarter_Number__c = 4;
			    }	
			    
			    iPeriod.Fiscal_Year__c = String.valueOf(year);
			    iPeriod.Company__c = company.Id;
			    iPeriod.Adjustment_Period__c = false;
			    iPeriod.Closed__c = false;
			    iPeriod.Open__c = i >= system.now().month();
			    iPeriod.Fiscal__c = true;
			    iPeriod.Corporate__c = false;
			    iPeriod.Tax__c = false;
			    iPeriod.Permanently_Closed__c = false;
			    iPeriod.Adjustment_Period__c = false;
			    
			    iPeriod.AP_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.AR_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.Shipment_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.Receiving_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.FA_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.Inventory_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.JE_Cutoff__c = iPeriod.Period_End__c;
			    
			    periodList.add(iPeriod);
			}
			Fiscal_Year__c fy = new Fiscal_Year__c();
			fy.company__c = company.Id;
			fy.fiscal_year_start_date__c = periodList[0].period_start__c;
			fy.fiscal_year_end_date__c = periodList[periodList.size()-1].period_end__c.addMonths(3);
			
			insert fy;
	
	    	for(Period__c p : periodList){
				p.fiscalyear__c = fy.Id;
	    	}
    		insert periodList;
   
    	}


    }
        public static testmethod void testReportCall()
    {
        ReconRemoteReportAPITest rd = new ReconRemoteReportAPITest();
        ReconRemoteExt.BegEndBalResult begEndBal = ReconRemoteExt.runBegBalReports(rd.recon.id,true,false);
        system.assertEquals(true, begEndBal.isValid,'Expecting succesful Call');
    }
*/}