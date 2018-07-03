@isTest
public class TestFuel {
    public class MyException extends Exception {}

    public Map<String,String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
    public map <string,string> SupplierRecordTypes = KSE.RecordTypeDevNameMap('Supplier__c');
        
    public Account account {
        get {
            if (account == null) {
                account = newAccount();
                //account.name = 'KenandyTestFuel'+ '-' + String.ValueOf(Math.round(Math.random(), 2));
				account.name = 'KenandyTestFuel' + '-Account #1';
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
				account.phone = '650-468-20001';
                account.fax = '650-468-2010';
				account.website = 'kenandyTest.com';
                insert account;
            }
            return account;
        }
        set;
    }
    
    public Accounting_Standard__c accountingStandard{
    	get{
    		if(accountingStandard == null){
    			accountingStandard = new Accounting_Standard__c();
    			accountingStandard.name = 'US GAAP';
    			insert accountingStandard;
    		}
    		return accountingStandard;
    	}
    	set;
    }

    public static Currency__c currencyUSD{
        get {
            if(currencyUSD== null){
                currencyUSD = new Currency__c();
                currencyUSD.name = 'USD TestFuel';
                //currencyUSD.Active__c = TRUE;
                currencyUSD.ISO_Code__c = 'USD';
                currencyUSD.Currency__c = 'USD Currency';
                insert currencyUSD;
            }
            return currencyUSD;
        }
        
        set;
    }
  
    public static Currency__c currencyGBP {
        get {
            if(currencyGBP == null){
                currencyGBP = new Currency__c();
                currencyGBP.name = 'GBP TestFuel';
                //currencyUSD.Active__c = TRUE; 
                currencyGBP.ISO_Code__c = 'GBP';
                currencyGBP.Currency__c = 'British Pound';
                insert currencyGBP;
            }
            return currencyGBP;
        }
        
        set;
    } 

    public static Currency__c currencyEUR {
        get {
            if(currencyEUR == null){
                currencyEUR = new Currency__c();
                currencyEUR.name = 'EUR TestFuel';
                //currencyUSD.Active__c = TRUE;
                currencyEUR.ISO_Code__c = 'EUR';
                currencyEUR.Currency__c = 'EURO Currency';
                insert currencyEUR;
            }
            return currencyEUR;
        }
        
        set;
    }

    public static Currency__c currencySGD {
        get {
            if(currencySGD == null){
                currencySGD = new Currency__c();
                currencySGD.name = 'SGD TestFuel';
                //currencyUSD.Active__c = TRUE;
                currencySGD.ISO_Code__c = 'SGD';
                currencySGD.Currency__c = 'SGD Currency';
                insert currencySGD;
            }
            return currencySGD;
        }
        
        set;
    }  

    public static Currency__c currencyCAD {
        get {
            if(currencyCAD == null){
                currencyCAD = new Currency__c();
                currencyCAD.name = 'CAD TestFuel';
                //currencyUSD.Active__c = TRUE;
                currencyCAD.ISO_Code__c = 'CAD';
                currencyCAD.Currency__c = 'CAD Currency';
                insert currencyCAD;
            }
            return currencyCAD;
        }
        
        set;
    }                
    
    public Company__c company {
        get {
            if (company == null) {
                company = new Company__c();
				company.name = 'Kenandy' + '-Main Company';
                    company.accounting_standard__c = accountingStandard.Id;
                    company.Address__c = account.ID;
                    company.A_Days__c = 30;
                    company.B_Days__c = 60;
                    company.C_Days__c = 180;
				company.Company_Identifier__c = 'KEN' + '-mainCompany#1';
                    company.Comp_Currency__c = TestFuel.currencyUSD.id;
                    company.Consol_Currency__c = TestFuel.currencyUSD.id;
                    company.Stat_Currency__c = TestFuel.currencyUSD.id;
                    company.Subs_Currency__c = TestFuel.currencyUSD.id;
                    company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
                    //company.Finalize_Supplier_Invoices_w_Exceptions__c = false; //KNDY-2817
                    company.Serial_Control__c = SkidService3.AT_RECEIPT;
                    system.assert(AutoBackdatingConfigVal != null);//Make the setting to default No as all existing tests are written based on that flow.
                    insert company;
            }
            return company;
        }
        set;
    }

     public Configuration__c AutoBackdatingConfigVal {
        get {
            if(AutoBackdatingConfigVal==null){
                // Create Configuration
                AutoBackdatingConfigVal = new Configuration__c();
                AutoBackdatingConfigVal.name = 'AutoBackdateToOpenSubledgers';
                AutoBackdatingConfigVal.Value__c = 'No';
                insert AutoBackdatingConfigVal;                
            }
            return AutoBackdatingConfigVal;
        }
        set;
    }   
    public Company__c altCompany {
        get {
            if (altCompany == null) {
                altCompany = new Company__c();
				altCompany.name = 'AltKenandyTestFuel' + '-Alternate';
                altCompany.accounting_standard__c = accountingStandard.Id;
                altCompany.Address__c = account.ID;
                altCompany.A_Days__c = 30;
                altCompany.B_Days__c = 60;
                altCompany.C_Days__c = 180;
				altCompany.Company_Identifier__c = 'KEN' + '-AltCompany#2';
                altCompany.Comp_Currency__c = TestFuel.currencyUSD.id;
                altCompany.Consol_Currency__c = TestFuel.currencyEUR.id;
                altCompany.Stat_Currency__c = TestFuel.currencyGBP.id;
                altCompany.Subs_Currency__c = TestFuel.currencyUSD.id;
                altCompany.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
                //company.Finalize_Supplier_Invoices_w_Exceptions__c = false; //KNDY-2817
                system.assert(AutoBackdatingConfigVal != null);//Make the setting to default No as all existing tests are written based on that flow.
                insert altCompany;
            }
            return altCompany;
        }
        set;
    }
    
    public List<Accounting_Rule__c> invoiceRuleList{
        get{
            if(invoiceRuleList == null){
                invoiceRuleList = new List<Accounting_Rule__c>();
                
                Accounting_Rule__c intercoInvestment1 = new Accounting_Rule__c();
                intercoInvestment1.Object_Name__c = 'Invoice__c';
	            //intercoInvestment1.Company__c = company.id;
                intercoInvestment1.Transaction__c = 'Intercompany Investment';
                intercoInvestment1.Role__c = 'Investor';
                intercoInvestment1.SubTransaction_Type__c = null;
                intercoInvestment1.Line_Type__c = null;
                intercoInvestment1.Rule_Type__c = 'CR';
                intercoInvestment1.Default_GL_Account__c = true;
                intercoInvestment1.GL_Account_Reference_Value__c = null;
                intercoInvestment1.GL_Account__c = intercompanyAPGL.id;
                intercoInvestment1.Amount_Reference__c = null; 
                intercoInvestment1.Company_Ledger__c = true;  
                intercoInvestment1.Intercompany_Reference_Value__c = 'Invoice__r.From_Company__c';         
                invoiceRuleList.add(intercoInvestment1);
                
                Accounting_Rule__c intercoInvestment2 = new Accounting_Rule__c();
                intercoInvestment2.Object_Name__c = 'Invoice__c';
	            //intercoInvestment2.Company__c = company.id;
                intercoInvestment2.Transaction__c = 'Intercompany Investment';
                intercoInvestment2.Role__c = 'Investor';
                intercoInvestment2.SubTransaction_Type__c = null;
                intercoInvestment2.Line_Type__c = null;
                intercoInvestment2.Rule_Type__c = 'DR';
                intercoInvestment2.Default_GL_Account__c = true;
                intercoInvestment2.GL_Account_Reference_Value__c = null;
                intercoInvestment2.GL_Account__c = intercompanyInvestmentGL.id;
                intercoInvestment2.Amount_Reference__c = null; 
                intercoInvestment2.Company_Ledger__c = true;   
                intercoInvestment2.Intercompany_Reference_Value__c = 'Invoice__r.From_Company__c';           
                invoiceRuleList.add(intercoInvestment2);            
				/*
                Accounting_Rule__c intercoInvestment3 = new Accounting_Rule__c();
                intercoInvestment3.Object_Name__c = 'Invoice__c';
	            //intercoInvestment3.Company__c = altCompany.id;
                intercoInvestment3.Transaction__c = 'Intercompany Investment';
                intercoInvestment3.Role__c = 'Investor';
                intercoInvestment3.SubTransaction_Type__c = null;
                intercoInvestment3.Line_Type__c = null;
                intercoInvestment3.Rule_Type__c = 'CR';
                intercoInvestment3.Default_GL_Account__c = true;
                intercoInvestment3.GL_Account_Reference_Value__c = null;
                intercoInvestment3.GL_Account__c = intercompanyInvestmentGL.id;
                intercoInvestment3.Amount_Reference__c = null; 
                intercoInvestment3.Company_Ledger__c = true;   
                intercoInvestment3.Intercompany_Reference_Value__c = 'Invoice__r.From_Company__c';        
                invoiceRuleList.add(intercoInvestment3);
                
                Accounting_Rule__c intercoInvestment4 = new Accounting_Rule__c();
                intercoInvestment4.Object_Name__c = 'Invoice__c';
	            //intercoInvestment4.Company__c = altCompany.id;
                intercoInvestment4.Transaction__c = 'Intercompany Investment';
                intercoInvestment4.Role__c = 'Investor';
                intercoInvestment4.SubTransaction_Type__c = null;
                intercoInvestment4.Line_Type__c = null;
                intercoInvestment4.Rule_Type__c = 'DR';
                intercoInvestment4.Default_GL_Account__c = true;
                intercoInvestment4.GL_Account_Reference_Value__c = null;
                intercoInvestment4.GL_Account__c = intercompanyAPGL.id;
                intercoInvestment4.Amount_Reference__c = null; 
                intercoInvestment4.Company_Ledger__c = true;  
                intercoInvestment4.Intercompany_Reference_Value__c = 'Invoice__r.From_Company__c';            
                invoiceRuleList.add(intercoInvestment4); 
	            */
                Accounting_Rule__c intercoInvestment5 = new Accounting_Rule__c();
                intercoInvestment5.Object_Name__c = 'Invoice__c';
	            //intercoInvestment5.Company__c = company.id;
                intercoInvestment5.Transaction__c = 'Intercompany Investment';
                intercoInvestment5.Role__c = 'Investee';
                intercoInvestment5.SubTransaction_Type__c = null;
                intercoInvestment5.Line_Type__c = null;
                intercoInvestment5.Rule_Type__c = 'CR';
                intercoInvestment5.Default_GL_Account__c = true;
                intercoInvestment5.GL_Account_Reference_Value__c = null;
                intercoInvestment5.GL_Account__c = intercompanyAPICGL.id;
                intercoInvestment5.Amount_Reference__c = null; 
                intercoInvestment5.Company_Ledger__c = true;   
                intercoInvestment5.Intercompany_Reference_Value__c = 'Invoice__r.To_Company__c';        
                invoiceRuleList.add(intercoInvestment5);
                
                Accounting_Rule__c intercoInvestment6 = new Accounting_Rule__c();
                intercoInvestment6.Object_Name__c = 'Invoice__c';
	            //intercoInvestment6.Company__c = company.id;
                intercoInvestment6.Transaction__c = 'Intercompany Investment';
                intercoInvestment6.Role__c = 'Investee';
                intercoInvestment6.SubTransaction_Type__c = null;
                intercoInvestment6.Line_Type__c = null;
                intercoInvestment6.Rule_Type__c = 'DR';
                intercoInvestment6.Default_GL_Account__c = true;
                intercoInvestment6.GL_Account_Reference_Value__c = null;
                intercoInvestment6.GL_Account__c = intercompanyARGL.id;
                intercoInvestment6.Amount_Reference__c = null; 
                intercoInvestment6.Company_Ledger__c = true;   
                intercoInvestment6.Intercompany_Reference_Value__c = 'Invoice__r.To_Company__c';           
                invoiceRuleList.add(intercoInvestment6);            
				/*
                Accounting_Rule__c intercoInvestment7 = new Accounting_Rule__c();
                intercoInvestment7.Object_Name__c = 'Invoice__c';
	            //intercoInvestment7.Company__c = altCompany.id;
                intercoInvestment7.Transaction__c = 'Intercompany Investment';
                intercoInvestment7.Role__c = 'Investee';
                intercoInvestment7.SubTransaction_Type__c = null;
                intercoInvestment7.Line_Type__c = null;
                intercoInvestment7.Rule_Type__c = 'CR';
                intercoInvestment7.Default_GL_Account__c = true;
                intercoInvestment7.GL_Account_Reference_Value__c = null;
                intercoInvestment7.GL_Account__c = intercompanyAPICGL.id;
                intercoInvestment7.Amount_Reference__c = null; 
                intercoInvestment7.Company_Ledger__c = true;  
                intercoInvestment7.Intercompany_Reference_Value__c = 'Invoice__r.To_Company__c';         
                invoiceRuleList.add(intercoInvestment7);
                
                Accounting_Rule__c intercoInvestment8 = new Accounting_Rule__c();
                intercoInvestment8.Object_Name__c = 'Invoice__c';
	            //intercoInvestment8.Company__c = altCompany.id;
                intercoInvestment8.Transaction__c = 'Intercompany Investment';
                intercoInvestment8.Role__c = 'Investee';
                intercoInvestment8.SubTransaction_Type__c = null;
                intercoInvestment8.Line_Type__c = null;
                intercoInvestment8.Rule_Type__c = 'DR';
                intercoInvestment8.Default_GL_Account__c = true;
                intercoInvestment8.GL_Account_Reference_Value__c = null;
                intercoInvestment8.GL_Account__c = intercompanyARGL.id;
                intercoInvestment8.Amount_Reference__c = null; 
                intercoInvestment8.Company_Ledger__c = true;    
                intercoInvestment8.Intercompany_Reference_Value__c = 'Invoice__r.To_Company__c';          
                invoiceRuleList.add(intercoInvestment8);
	            */
                Accounting_Rule__c intercoCrossCharge1 = new Accounting_Rule__c();
                intercoCrossCharge1.Object_Name__c = 'Invoice__c';
	            //intercoCrossCharge1.Company__c = Company.id;
                intercoCrossCharge1.Transaction__c = 'Intercompany Cross Charge';
                intercoCrossCharge1.Role__c = 'Payee';
                intercoCrossCharge1.SubTransaction_Type__c = null;
                intercoCrossCharge1.Line_Type__c = null;
                intercoCrossCharge1.Rule_Type__c = 'CR';
                intercoCrossCharge1.Default_GL_Account__c = true;
                intercoCrossCharge1.GL_Account_Reference_Value__c = null;
                intercoCrossCharge1.GL_Account__c = intercompanyARGL.id;
                intercoCrossCharge1.Amount_Reference__c = null; 
                intercoCrossCharge1.Company_Ledger__c = true;    
                intercoCrossCharge1.Intercompany_Reference_Value__c = 'Invoice__r.To_Company__c';          
                invoiceRuleList.add(intercoCrossCharge1);
                
                Accounting_Rule__c intercoCrossCharge2 = new Accounting_Rule__c();
                intercoCrossCharge2.Object_Name__c = 'Invoice__c';
	            //intercoCrossCharge2.Company__c = Company.id;
                intercoCrossCharge2.Transaction__c = 'Intercompany Cross Charge';
                intercoCrossCharge2.Role__c = 'Payee';
                intercoCrossCharge2.SubTransaction_Type__c = null;
                intercoCrossCharge2.Line_Type__c = null;
                intercoCrossCharge2.Rule_Type__c = 'DR';
                intercoCrossCharge2.Default_GL_Account__c = false;
                intercoCrossCharge2.GL_Account_Reference_Value__c = 'Accounting_Default__r.GL_Account__c';
                intercoCrossCharge2.GL_Account__c = null;
                intercoCrossCharge2.Amount_Reference__c = null; 
                intercoCrossCharge2.Company_Ledger__c = true;    
                intercoCrossCharge2.Intercompany_Reference_Value__c = 'Invoice__r.To_Company__c';          
                invoiceRuleList.add(intercoCrossCharge2);
	            /*
                Accounting_Rule__c intercoCrossCharge3 = new Accounting_Rule__c();
                intercoCrossCharge3.Object_Name__c = 'Invoice__c';
	            //intercoCrossCharge3.Company__c = altCompany.id;
                intercoCrossCharge3.Transaction__c = 'Intercompany Cross Charge';
                intercoCrossCharge3.Role__c = 'Payor';
                intercoCrossCharge3.SubTransaction_Type__c = null;
                intercoCrossCharge3.Line_Type__c = null;
                intercoCrossCharge3.Rule_Type__c = 'CR';
                intercoCrossCharge3.Default_GL_Account__c = true;
                intercoCrossCharge3.GL_Account_Reference_Value__c = null;
                intercoCrossCharge3.GL_Account__c = intercompanyAPGL.id;
                intercoCrossCharge3.Amount_Reference__c = null; 
                intercoCrossCharge3.Company_Ledger__c = true;    
                intercoCrossCharge3.Intercompany_Reference_Value__c = 'Invoice__r.From_Company__c';          
                invoiceRuleList.add(intercoCrossCharge3);
                
                Accounting_Rule__c intercoCrossCharge4 = new Accounting_Rule__c();
                intercoCrossCharge4.Object_Name__c = 'Invoice__c';
	            //intercoCrossCharge4.Company__c = altCompany.id;
                intercoCrossCharge4.Transaction__c = 'Intercompany Cross Charge';
                intercoCrossCharge4.Role__c = 'Payor';
                intercoCrossCharge4.SubTransaction_Type__c = null;
                intercoCrossCharge4.Line_Type__c = null;
                intercoCrossCharge4.Rule_Type__c = 'DR';
                intercoCrossCharge4.Default_GL_Account__c = false;
                intercoCrossCharge4.GL_Account_Reference_Value__c = 'Accounting_Default__r.GL_Account__c';
                intercoCrossCharge4.GL_Account__c = null;
                intercoCrossCharge4.Amount_Reference__c = null; 
                intercoCrossCharge4.Company_Ledger__c = true;    
                intercoCrossCharge4.Intercompany_Reference_Value__c = 'Invoice__r.From_Company__c';          
                invoiceRuleList.add(intercoCrossCharge4 );
	            */
                //Adding Effectivity to the accounting rules.
                for(Accounting_rule__c rule:invoiceRuleList)
                {
                    rule.Effective_Start_Date__c= effStartDate;
	            	rule.Accounting_Standard__c  = accountingStandard.Id;
                }                   
            
                insert invoiceRuleList;
            }
            return invoiceRuleList;
        } 
        set;
        
    }   
    
    
    public List<Accounting_Rule__c> paymentRuleList{
        get{
            if(paymentRuleList == null){
                paymentRuleList = new List<Accounting_Rule__c>();
                
                
                Accounting_Rule__c intercoPayment1 = new Accounting_Rule__c();
                intercoPayment1.Object_Name__c = 'Payment__c';
	            //intercoPayment1.Company__c = Company.id;
                intercoPayment1.Transaction__c = 'Intercompany Payment';
                intercoPayment1.Role__c = 'Payor';
                intercoPayment1.SubTransaction_Type__c = 'Intercompany Payment';
                intercoPayment1.Line_Type__c = null;
                intercoPayment1.Rule_Type__c = 'DR';
                intercoPayment1.Default_GL_Account__c = true;
                intercoPayment1.GL_Account_Reference_Value__c = null;
                intercoPayment1.GL_Account__c = intercompanyAPGL.id;
                intercoPayment1.Amount_Reference__c = null; 
                intercoPayment1.Company_Ledger__c = true;    
                intercoPayment1.Intercompany_Reference_Value__c = 'Payment__r.To_Company__c';          
                paymentRuleList.add(intercoPayment1);
                
                Accounting_Rule__c intercoPayment2 = new Accounting_Rule__c();
                intercoPayment2.Object_Name__c = 'Payment__c';
	            //intercoPayment2.Company__c = Company.id;
                intercoPayment2.Transaction__c = 'Intercompany Payment';
                intercoPayment2.Role__c = 'Payor';
                intercoPayment2.SubTransaction_Type__c = 'Intercompany Payment';
                intercoPayment2.Line_Type__c = null;
                intercoPayment2.Rule_Type__c = 'CR';
                intercoPayment2.Default_GL_Account__c = true;
                intercoPayment2.GL_Account_Reference_Value__c = null;
                intercoPayment2.GL_Account__c = IntercompanyUnappliedCashGL.id;
                intercoPayment2.Amount_Reference__c = null; 
                intercoPayment2.Company_Ledger__c = true;    
                intercoPayment2.Intercompany_Reference_Value__c = 'Payment__r.To_Company__c';          
                paymentRuleList.add(intercoPayment2);
                
                Accounting_Rule__c intercoPayment11 = new Accounting_Rule__c();
                intercoPayment11.Object_Name__c = 'Payment__c';
	            //intercoPayment11.Company__c = Company.id;
                intercoPayment11.Transaction__c = 'Intercompany Payment';
                intercoPayment11.Role__c = 'Payor';
                intercoPayment11.Line_Type__c = null;
                intercoPayment11.Rule_Type__c = 'DR';
                intercoPayment11.Default_GL_Account__c = true;
                intercoPayment11.GL_Account_Reference_Value__c = null;
                intercoPayment11.GL_Account__c = intercompanyAPGL.id;
                intercoPayment11.Amount_Reference__c = null; 
                intercoPayment11.Company_Ledger__c = true;    
                intercoPayment11.Intercompany_Reference_Value__c = 'Payment__r.To_Company__c';          
                paymentRuleList.add(intercoPayment11);
                
                Accounting_Rule__c intercoPayment12 = new Accounting_Rule__c();
                intercoPayment12.Object_Name__c = 'Payment__c';
	            //intercoPayment12.Company__c = Company.id;
                intercoPayment12.Transaction__c = 'Intercompany Payment';
                intercoPayment12.Role__c = 'Payor';
                intercoPayment12.Line_Type__c = null;
                intercoPayment12.Rule_Type__c = 'CR';
                intercoPayment12.Default_GL_Account__c = true;
                intercoPayment12.GL_Account_Reference_Value__c = null;
                intercoPayment12.GL_Account__c = IntercompanyUnappliedCashGL.id;
                intercoPayment12.Amount_Reference__c = null; 
                intercoPayment12.Company_Ledger__c = true;    
                intercoPayment12.Intercompany_Reference_Value__c = 'Payment__r.To_Company__c';          
                paymentRuleList.add(intercoPayment12);
                
                Accounting_Rule__c intercoPayment3 = new Accounting_Rule__c();
                intercoPayment3.Object_Name__c = 'Payment__c';
	            //intercoPayment3.Company__c = Company.id;
                intercoPayment3.Transaction__c = 'Intercompany Payment';
                intercoPayment3.Role__c = 'Payor';
                intercoPayment3.SubTransaction_Type__c = 'Intercompany Netting';
                intercoPayment3.Line_Type__c = null;
                intercoPayment3.Rule_Type__c = 'DR';
                intercoPayment3.Default_GL_Account__c = true;
                intercoPayment3.GL_Account_Reference_Value__c = null;
                intercoPayment3.GL_Account__c = IntercompanyUnappliedCashGL.id;
                intercoPayment3.Amount_Reference__c = null; 
                intercoPayment3.Company_Ledger__c = true;    
                intercoPayment3.Intercompany_Reference_Value__c = 'Payment__r.To_Company__c';          
                paymentRuleList.add(intercoPayment3);
                
                Accounting_Rule__c intercoPayment4 = new Accounting_Rule__c();
                intercoPayment4.Object_Name__c = 'Payment__c';
	            //intercoPayment4.Company__c = Company.id;
                intercoPayment4.Transaction__c = 'Intercompany Payment';
                intercoPayment4.Role__c = 'Payor';
                intercoPayment4.SubTransaction_Type__c = 'Intercompany Netting';
                intercoPayment4.Line_Type__c = null;
                intercoPayment4.Rule_Type__c = 'CR';
                intercoPayment4.Default_GL_Account__c = true;
                intercoPayment4.GL_Account_Reference_Value__c = null;
                intercoPayment4.GL_Account__c = intercompanyARGL.id;
                intercoPayment4.Amount_Reference__c = null; 
                intercoPayment4.Company_Ledger__c = true;    
                intercoPayment4.Intercompany_Reference_Value__c = 'Payment__r.To_Company__c';          
                paymentRuleList.add(intercoPayment4);
	            /*
                Accounting_Rule__c intercoPayment5 = new Accounting_Rule__c();
                intercoPayment5.Object_Name__c = 'Payment__c';
	            //intercoPayment5.Company__c = altCompany.id;
                intercoPayment5.Transaction__c = 'Intercompany Payment';
                intercoPayment5.Role__c = 'Payee';
                intercoPayment5.SubTransaction_Type__c = 'Intercompany Payment';
                intercoPayment5.Line_Type__c = null;
                intercoPayment5.Rule_Type__c = 'DR';
                intercoPayment5.Default_GL_Account__c = true;
                intercoPayment5.GL_Account_Reference_Value__c = null;
                intercoPayment5.GL_Account__c = IntercompanyUnappliedCashGL.id;
                intercoPayment5.Amount_Reference__c = null; 
                intercoPayment5.Company_Ledger__c = true;    
                intercoPayment5.Intercompany_Reference_Value__c = 'Payment__r.From_Company__c';          
                paymentRuleList.add(intercoPayment5);
                
                Accounting_Rule__c intercoPayment6 = new Accounting_Rule__c();
                intercoPayment6.Object_Name__c = 'Payment__c';
	            //intercoPayment6.Company__c = altCompany.id;
                intercoPayment6.Transaction__c = 'Intercompany Payment';
                intercoPayment6.Role__c = 'Payee';
                intercoPayment6.SubTransaction_Type__c = 'Intercompany Payment';
                intercoPayment6.Line_Type__c = null;
                intercoPayment6.Rule_Type__c = 'CR';
                intercoPayment6.Default_GL_Account__c = true;
                intercoPayment6.GL_Account_Reference_Value__c = null;
                intercoPayment6.GL_Account__c = intercompanyARGL.id;
                intercoPayment6.Amount_Reference__c = null; 
                intercoPayment6.Company_Ledger__c = true;    
                intercoPayment6.Intercompany_Reference_Value__c = 'Payment__r.From_Company__c';          
                paymentRuleList.add(intercoPayment6);
                
                Accounting_Rule__c intercoPayment9 = new Accounting_Rule__c();
                intercoPayment9.Object_Name__c = 'Payment__c';
	            //intercoPayment9.Company__c = altCompany.id;
                intercoPayment9.Transaction__c = 'Intercompany Payment';
                intercoPayment9.Role__c = 'Payee';
                intercoPayment9.Line_Type__c = null;
                intercoPayment9.Rule_Type__c = 'DR';
                intercoPayment9.Default_GL_Account__c = true;
                intercoPayment9.GL_Account_Reference_Value__c = null;
                intercoPayment9.GL_Account__c = IntercompanyUnappliedCashGL.id;
                intercoPayment9.Amount_Reference__c = null; 
                intercoPayment9.Company_Ledger__c = true;    
                intercoPayment9.Intercompany_Reference_Value__c = 'Payment__r.From_Company__c';          
                paymentRuleList.add(intercoPayment9);
                
                Accounting_Rule__c intercoPayment10 = new Accounting_Rule__c();
                intercoPayment10.Object_Name__c = 'Payment__c';
                intercoPayment10.Company__c = altCompany.id;
                intercoPayment10.Transaction__c = 'Intercompany Payment';
                intercoPayment10.Role__c = 'Payee';
                intercoPayment10.Line_Type__c = null;
                intercoPayment10.Rule_Type__c = 'CR';
                intercoPayment10.Default_GL_Account__c = true;
                intercoPayment10.GL_Account_Reference_Value__c = null;
                intercoPayment10.GL_Account__c = intercompanyARGL.id;
                intercoPayment10.Amount_Reference__c = null; 
                intercoPayment10.Company_Ledger__c = true;    
                intercoPayment10.Intercompany_Reference_Value__c = 'Payment__r.From_Company__c';          
                paymentRuleList.add(intercoPayment10);
                
                Accounting_Rule__c intercoPayment7 = new Accounting_Rule__c();
                intercoPayment7.Object_Name__c = 'Payment__c';
	            //intercoPayment7.Company__c = altCompany.id;
                intercoPayment7.Transaction__c = 'Intercompany Payment';
                intercoPayment7.Role__c = 'Payee';
                intercoPayment7.SubTransaction_Type__c = 'Intercompany Netting';
                intercoPayment7.Line_Type__c = null;
                intercoPayment7.Rule_Type__c = 'DR';
                intercoPayment7.Default_GL_Account__c = true;
                intercoPayment7.GL_Account_Reference_Value__c = null;
                intercoPayment7.GL_Account__c = IntercompanyUnappliedCashGL.id;
                intercoPayment7.Amount_Reference__c = null; 
                intercoPayment7.Company_Ledger__c = true;    
                intercoPayment7.Intercompany_Reference_Value__c = 'Payment__r.From_Company__c';          
                paymentRuleList.add(intercoPayment7);
                
                Accounting_Rule__c intercoPayment8 = new Accounting_Rule__c();
                intercoPayment8.Object_Name__c = 'Payment__c';
	            //intercoPayment8.Company__c = altCompany.id;
                intercoPayment8.Transaction__c = 'Intercompany Payment';
                intercoPayment8.Role__c = 'Payee';
                intercoPayment8.SubTransaction_Type__c = 'Intercompany Netting';
                intercoPayment8.Line_Type__c = null;
                intercoPayment8.Rule_Type__c = 'CR';
                intercoPayment8.Default_GL_Account__c = true;
                intercoPayment8.GL_Account_Reference_Value__c = null;
                intercoPayment8.GL_Account__c = intercompanyAPGL.id;
                intercoPayment8.Amount_Reference__c = null; 
                intercoPayment8.Company_Ledger__c = true;    
                intercoPayment8.Intercompany_Reference_Value__c = 'Payment__r.From_Company__c';          
                paymentRuleList.add(intercoPayment8);
	            */
                //Adding Effectivity to the accounting rules.
                for(Accounting_rule__c rule:paymentRuleList)
                {
                    rule.Effective_Start_Date__c= effStartDate;
	            	rule.Accounting_Standard__c = accountingStandard.Id;
                }                   
            
                insert paymentRuleList;
            }
            return paymentRuleList;
        } 
        set;
        
    }   
    
    public List<Exchange_Rate__c> exchangeRateList {
        get {
            if (exchangeRateList == null) {
                    exchangeRateList = new List<Exchange_Rate__c>();
                    Exchange_Rate__c exchangeRate1, exchangeRate2, exchangeRate3, exchangeRate4, exchangeRate5;
                exchangeRate1= new Exchange_Rate__c();
                exchangeRate1.Active__c = true;
                exchangeRate1.From_Currency__c = TestFuel.currencyUSD.id;
                exchangeRate1.To_Currency__c = TestFuel.currencySGD.id;
                exchangeRate1.Daily_Monthly__c = 'Daily';
                exchangeRate1.Multiplier_Exchange_Rate__c = 1.250000;
                exchangeRate1.rate_start_datetime__c = system.now();
                exchangeRate1.rate_end_datetime__c = system.now() + 2;
                
            
                exchangeRateList.add(exchangeRate1);
            
                exchangeRate2= new Exchange_Rate__c();
                exchangeRate2.Active__c = true;
                exchangeRate2.From_Currency__c = TestFuel.currencySGD.id;
                exchangeRate2.To_Currency__c = TestFuel.currencyGBP.id;
                exchangeRate2.Daily_Monthly__c = 'Daily';
                exchangeRate2.Multiplier_Exchange_Rate__c = 0.470000;
                exchangeRate2.rate_start_datetime__c = system.now();
                exchangeRate2.rate_end_datetime__c = system.now() + 30;
            
                exchangeRateList.add(exchangeRate2);
            
                exchangeRate3= new Exchange_Rate__c();
                exchangeRate3.Active__c = true;
                exchangeRate3.From_Currency__c = TestFuel.currencySGD.id;
                exchangeRate3.To_Currency__c = TestFuel.currencyEUR.id;
                exchangeRate3.Daily_Monthly__c = 'Daily';
                exchangeRate3.Multiplier_Exchange_Rate__c = 0.580000;
                exchangeRate3.rate_start_datetime__c = system.now();
                exchangeRate3.rate_end_datetime__c = system.now() + 30;
            
                exchangeRateList.add(exchangeRate3);
            
                exchangeRate4= new Exchange_Rate__c();
                exchangeRate4.Active__c = true;
                exchangeRate4.From_Currency__c = TestFuel.currencySGD.id;
                exchangeRate4.To_Currency__c = TestFuel.currencyUSD.id;
                exchangeRate4.Daily_Monthly__c = 'Daily';
                exchangeRate4.Multiplier_Exchange_Rate__c = 0.800000;
                exchangeRate4.rate_start_datetime__c = system.now();
                exchangeRate4.rate_end_datetime__c = system.now() + 30;
            
                exchangeRateList.add(exchangeRate4);
                
                exchangeRate5= new Exchange_Rate__c();
                exchangeRate5.Active__c = true;
                exchangeRate5.From_Currency__c = TestFuel.currencyCAD.id;
                exchangeRate5.To_Currency__c = TestFuel.currencySGD.id;
                exchangeRate5.Daily_Monthly__c = 'Daily';
                exchangeRate5.Multiplier_Exchange_Rate__c = 1.140000;
                exchangeRate5.rate_start_datetime__c = system.now();
                exchangeRate5.rate_end_datetime__c = system.now() + 2;
            
                exchangeRateList.add(exchangeRate5);
                List<Exchange_Rate__c> tmpRates = new List<Exchange_Rate__c>();
                for(Exchange_Rate__c r : exchangeRateList){
                    Exchange_Rate__c iR = r.clone(false, false, false);
                    iR.From_Currency__c = r.To_Currency__c;
                    iR.To_Currency__c = r.From_Currency__c;
                    iR.multiplier_exchange_rate__c = 1/r.multiplier_exchange_rate__c;
                    tmpRates.add(iR);
                }
                exchangeRateList.addAll(tmpRates);
                insert exchangeRateList;
            }
            return exchangeRateList;
        }
        set;
    }
    public datetime effStartDate{
        get{
            if(effStartDate==null)
            {
                //Give the earliest eff date possible - Previous yr used to make sure Transactions created are in effectivity range of accounting rules.
                return datetime.newInstance(system.now().year()-1, 1, 1, 0, 0, 0);
            }
            else
            {
                return effStartDate;
            }
        }set; 
    }
    
    public List<GL_Type__c> GLTypeTestData{
        get{
            if(GLTypeTestData == null){
                string glTypeBody = [SELECT id, Body FROM StaticResource WHERE Name = 'TestData_GLType' LIMIT 1].body.toString();
                GLTypeTestData = (List<GL_Type__c>)CSVParser.parseRecords(GL_Type__c.sObjectType, glTypeBody);
                system.debug('GLTypeTestData:'+GLTypeTestData);
                insert GLTypeTestData;
            }
            return GLTypeTestData;
        }
        set ;
         
    }
    
    public Map<String,GL_Type__c> mGLTypes {
        get{
            if(mGLTypes == null){
                mGLTypes = new Map<String,GL_Type__c>();
                for(GL_Type__c glt: GLTypeTestData){
                    mGLTypes.put(String.valueof(glt.get('Name')), glt);
                }
            }
            return mGLTypes;
        }
        set;
    }
    
    public List<GL_Account__c> GLAccountTestData{
        get{
                system.assert(GLTypeTestData.size() != 0);
                if(GLAccountTestData == null){
                    //List<sObject> recs = Test.loadData(GL_Account__c.sObjectType, 'TestData_GLAccount');
                    //GLAccountTestData = (List<GL_Account__c>)recs;
                    string glAccountBody = [SELECT id, Body FROM StaticResource WHERE Name = 'TestData_GLAccount' LIMIT 1].body.toString();
                    GLAccountTestData = (List<GL_Account__c>)CSVParser.parseRecords(GL_Account__c.sObjectType, glAccountBody);
                    system.debug(logginglevel.info,'GLAccountTestData:'+GLAccountTestData);
                    insert GLAccountTestData;
                }
        
            return GLAccountTestData;
        }
        set ;
         
    }
    
    public Map<String,GL_Account__c> mGLAccounts {
        get{
            if(mGLAccounts == null){
                mGLAccounts = new Map<String,GL_Account__c>();
                for(GL_Account__c gla: GLAccountTestData){
                    String s = String.valueof(gla.get('GL_Account_Number__c'));
                    mGLAccounts.put(s, gla);
                }
            }
            return mGLAccounts;
        }
        set;
    }
    
    public List<Class__c> classList {
         get {
             if (classList == null){
                 classList = new List<Class__c>();
                 Class__c itemClass1 = new Class__c();
                 itemClass1.Type__c = 'Goods';
                 itemClass1.Name = 'Goods';
                 itemClass1.Inventory_GL_Account__c = FGInventoryGL.id;
                 itemClass1.Revenue_GL_Account__c = revenueGL.id;
                 classList.add(itemClass1); 
                 
                 Class__c itemClass2 = new Class__c();
                 itemClass2.Type__c = 'Miscellaneous';
                 itemClass2.Name = 'Miscellaneous';
                 itemClass2.Inventory_GL_Account__c = FGInventoryGL.id;
                 itemClass2.Revenue_GL_Account__c = revenueGL.id;
                 classList.add(itemClass2); 
                 
                 Class__c itemClass3 = new Class__c();
                 itemClass3.Type__c = 'Expense';
                 itemClass3.Name = 'Expense';
                 itemClass3.Inventory_GL_Account__c = FGInventoryGL.id;
                 itemClass3.Revenue_GL_Account__c = revenueGL.id;
                 classList.add(itemClass3); 
                 insert classList;
             }
             return classlist;
         }set;
     }
 
 

    public Class__c clsObj {
        get {
            if (clsObj == null) {
                clsObj = new Class__c();
                clsObj.Name = string.valueOf(system.now());
                clsObj.Description__c = 'Item Class One';
                clsObj.Type__c = 'Goods';
                clsObj.Revenue_GL_Account__c = cashGL.Id;
                clsObj.Inventory_GL_Account__c = FGInventoryGL.Id;
                clsObj.class_unique__c = clsObj.Name;
                insert clsObj;
            }
            return clsObj;
        } set;
    } 
    public Class__c FreightClass {
        get {
            if (FreightClass == null) {
                FreightClass = new Class__c();
                FreightClass.Name = 'Freight Class';
                FreightClass.Description__c = 'Freight Class';
                FreightClass.Type__c = 'Freight';
                FreightClass.class_unique__c = FreightClass.Name;
                insert FreightClass;
            }
            return FreightClass;
        } set;
    }
    public Class__c ItemClassNoType {
        get {
            if (ItemClassNoType == null) {
                ItemClassNoType = new Class__c();
                ItemClassNoType.Name = 'Freight Class - no type';
                ItemClassNoType.Description__c = 'Freight Class';
                ItemClassNoType.class_unique__c = ItemClassNoType.Name;
                ItemClassNoType.Type__c = '';
                insert ItemClassNoType;
            }
            return ItemClassNoType;
        } set;
    }

    public Item_Attribute__c itemAttrObj {
        get {
            if (itemAttrObj == null) {
                itemAttrObj = new Item_Attribute__c(
                    Name = 'No Serials Attribute-1',
                    Lot_Number__c = true,
                    Expiration_Date__c = true
                );
                insert itemAttrObj;
            }
            return itemAttrObj;
        } set;
    }
    
    public Item_Attribute__c itemAttrObj2 {
        get {
            if (itemAttrObj2 == null) {
                itemAttrObj2 = new Item_Attribute__c(
                    Name = 'Serials Attribute-2',
                    Lot_Number__c = true,
                    Expiration_Date__c = true,
                    Serial_Number__c = true,
                    Minimum_Shelf_Life_In_Days__c = true
                );
                insert itemAttrObj2;
            }
            return itemAttrObj2;
        } set;
    }
    
    public Item_Attribute__c lpnAttribute {
        get {
            if (lpnAttribute == null) {
                lpnAttribute = new Item_Attribute__c(
                    Name = 'LPN',
                    License_Plate_Number__c = true
                );
                insert lpnAttribute;
            }
            return lpnAttribute;
        } set;
    }
    
    public UOM__c uomObj {
        get {
            if (uomObj == null) {
                uomObj = uomList[8];
            }
            return uomObj;
        }
        set;
    }
    
    public UOM__c uomInch {
        get {
            if (uomInch == null) {
                uomInch = uomList[6];
            }
            return uomInch;
        }
        set;
    }
    
    public UOM__c RENTAL_MONTH {
    	 get {
            if (RENTAL_MONTH == null) {
                RENTAL_MONTH = new UOM__c(Name = 'Rental Month', Type__c = 'Time', Every__c = 28, Recurrence__c = 'Day(s)');
                insert RENTAL_MONTH;
            }
            return RENTAL_MONTH;
        }
        set;
    }
    
    public UOM__c WEEK {
    	 get {
            if (WEEK == null) {
                WEEK = new UOM__c(Name = 'Week', Type__c = 'Time', Every__c = 1, Recurrence__c = 'Week(s)');
                insert WEEK;
            }
            return WEEK;
        }
        set;
    }
    public UOM__c CALENDAR_MONTH {
    	 get {
            if (CALENDAR_MONTH == null) {
                CALENDAR_MONTH = new UOM__c(Name = 'Calendar Month', Type__c = 'Time', Every__c = 1, Recurrence__c = 'Month(s)');
                insert CALENDAR_MONTH;
            }
            return CALENDAR_MONTH;
        }
        set;
    }
    public UOM__c CALENDAR_QUARTER {
    	 get {
            if (CALENDAR_QUARTER == null) {
                CALENDAR_QUARTER = new UOM__c(Name= 'Calendar Quarter', Type__c = 'Time', Every__c = 1, Recurrence__c = 'Quarter(s)');
                insert CALENDAR_QUARTER;
            }
            return CALENDAR_QUARTER;
        }
        set;
    }
    
    public List<Package_Class__c> packageClassList {
        get {
            if (packageClassList == null) {
                Package_Class__c palletClass = new Package_Class__c(Name='Pallet', Level__c = 3);
                Package_Class__c caseClass = new Package_Class__c(Name='Case', Level__c = 2);
                Package_Class__c eachClass = new Package_Class__c(Name='Each', Level__c = 1);
                packageClassList = new List<Package_Class__c>{ palletClass, caseClass, eachClass };
                
                DML.systemTime = System.now().addHours(-2);
                List<Configuration__c> configList = new List<Configuration__c>{ new Configuration__c(Name = Package_Class__c.sObjectType.getDescribe().getLocalName() + '-' + Package_Class__c.sObjectType.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()) };
                insert configList;
                
                insert packageClassList;
                caseClass.Parent_Package_Class__c = palletClass.Id;
                eachClass.Parent_Package_Class__c = caseClass.Id;
                update packageClassList;
                
                delete configList;
            }
            return packageClassList;
        } set;
    }

    public List<UOM__c> uomList {
        get {
            if (uomList == null) {
                Map<String, UOM__c> existingUoms = new Map<String, UOM__c>();
                for (UOM__c uom:[SELECT Id, name FROM UOM__c]) existingUoms.put(uom.Name, uom);

                List<String> uoms = new List<String>{ 'LB', 'TN', 'DZ', 'OZ', 'MI', 'YD', 'IN', 'FT', 'EA', 'FT3', 'GAL', 'EA2', 'CS', 'PT' };
                List<String> uomDescs = new List<String>{ 'Pound', 'Ton', 'Dozen', 'Ounce', 'Mile', 'Yard', 'Inch', 'Foot', 'Each', 'Cubic', 'Gallon', 'Each2', 'Case', 'Pallet' };
                
                uomList = new List<UOM__c>();
                for (Integer i = 0; i < uoms.size(); i++){
                    String uom = uoms[i];

                    if(!existingUoms.containsKey(uom)) {
                        uomList.add(new UOM__c(
                            Name = uom,
                            Description__c = uomDescs[i]
                        ));
                    } else {
                        uomList.add(existingUoms.get(uom));
                    }

                    if (uom == 'EA2') {
                        uomList[i].Package_Class__c = packageClassList[2].Id;
                    } else if (uom == 'CS') {
                        uomList[i].Package_Class__c = packageClassList[1].Id;
                    } else if (uom == 'PT') {
                        uomList[i].Package_Class__c = packageClassList[0].Id;
                    }
                }

                upsert uomList;
                System.assert(uomcList != null);
            }
            return uomList;
        } set;
    }
    
    public List<Stock_Movement_Rule_Settings__c> smrsList {
        get {
            if (smrsList == null) {
                List<String> stockMovementRuleFields = new List<String>{'Class__c','Customer__c','Company__c','Facility__c','Item__c'};
                List<String> sourceDocuments = new List<String>{'Purchase Order', 'Sales Order', 'Work Order', 'Transfer Order', 'Receiving Document','Transfer'};
                smrsList = new List<Stock_Movement_Rule_Settings__c>();
                
                for( String sourceDocument : sourceDocuments ){
                    for( String stockMovementRuleField : stockMovementRuleFields ){
                        
                        if( !(stockMovementRuleField == 'Customer__c' && ( sourceDocument != 'Sales Order'))   ){
                            Stock_Movement_Rule_Settings__c smrs = new Stock_Movement_Rule_Settings__c();
                            smrs.Name = sourceDocument+'-'+stockMovementRuleField;
                            smrs.Stock_Movement_Rule_Field__c = stockMovementRuleField;
                            smrs.Source_Document__c = sourceDocument;
                            
                            if( (sourceDocument == 'Purchase Order' || sourceDocument == 'Receiving Document') && stockMovementRuleField == 'Class__c' ){
                                smrs.Source_Document_Path__c = 'Item__r.Class__c';
                            }
                            else if( sourceDocument == 'Purchase Order' && stockMovementRuleField == 'Facility__c' ){
                                smrs.Source_Document_Path__c = 'Delivery_Facility__c';
                            }
                            else if( sourceDocument == 'Sales Order' && stockMovementRuleField == 'Class__c' ){
                                smrs.Source_Document_Path__c = 'Product__r.Item__r.Class__c';
                            }
                            else if( sourceDocument == 'Sales Order' && stockMovementRuleField == 'Customer__c' ){
                                smrs.Source_Document_Path__c = 'Sales_Order__r.Customer__c';
                            }
                            else if( sourceDocument == 'Sales Order' && stockMovementRuleField == 'Facility__c' ){
                                smrs.Source_Document_Path__c = 'Ship_From_Location__r.Facility__c';
                            }
                            else if( sourceDocument == 'Sales Order' && stockMovementRuleField == 'Item__c' ){
                                smrs.Source_Document_Path__c = 'Product__r.Item__c';
                            }
                            else if( sourceDocument == 'Transfer Order' && stockMovementRuleField == 'Company__c' ){
                                smrs.Source_Document_Path__c = 'Order__r.Shipping_Company__c';
                                smrs.Source_Document_Path_Putaway__c ='Order__r.Receiving_Company__c';
                            }
                            else if( sourceDocument == 'Transfer Order' && stockMovementRuleField == 'Class__c' ){
                                smrs.Source_Document_Path__c = 'Shipping_Item__r.Class__c';
                                smrs.Source_Document_Path_Putaway__c ='Receiving_Item__r.Class__c';
                            }
                            else if( sourceDocument == 'Transfer Order' && stockMovementRuleField == 'Facility__c' ){
                                smrs.Source_Document_Path__c = 'Ship_From_Facility__c';
                                smrs.Source_Document_Path_Putaway__c ='Deliver_To_Facility__c';
                            }
                            else if( sourceDocument == 'Transfer Order' && stockMovementRuleField == 'Item__c' ){
                                smrs.Source_Document_Path__c = 'Shipping_Item__c';
                                smrs.Source_Document_Path_Putaway__c ='Receiving_Item__c';
                            }    
                            else if( sourceDocument == 'Transfer' && stockMovementRuleField == 'Company__c' ){//custom setting for direct putaway stock movement rule 
                                smrs.Source_Document_Path__c = 'Company__c';
                                smrs.Source_Document_Path_Putaway__c ='Company__c';
                            }
                            else if( sourceDocument == 'Transfer' && stockMovementRuleField == 'Class__c' ){
                                smrs.Source_Document_Path__c = 'Class__c';
                                smrs.Source_Document_Path_Putaway__c ='Class__c';
                            }
                            else if( sourceDocument == 'Transfer' && stockMovementRuleField == 'Facility__c' ){
                                smrs.Source_Document_Path__c = 'Facility__c';
                                smrs.Source_Document_Path_Putaway__c ='Facility__c';
                            }
                            else if( sourceDocument == 'Transfer' && stockMovementRuleField == 'Item__c' ){
                                smrs.Source_Document_Path__c = 'Item__c';
                                smrs.Source_Document_Path_Putaway__c ='Item__c';        
                            } else if (sourceDocument == 'Work Order' && stockMovementRuleField == 'Class__c') {
                                smrs.Source_Document_Path__c = 'Item__r.Class__c';
                            } else if (sourceDocument == 'Work Order' && stockMovementRuleField == 'Facility__c') {
                                smrs.Source_Document_Path__c = 'Work_Order__r.Facility__c';
                            } else if (sourceDocument == 'Work Order' && stockMovementRuleField == 'Company__c') {
                                smrs.Source_Document_Path__c = 'Work_Order__r.Company__c';
                            } else {
                                smrs.Source_Document_Path__c = stockMovementRuleField;
                            }
                            
                            if (sourceDocument != 'Transfer Order')
                                smrs.Source_Document_Path_Putaway__c = smrs.Source_Document_Path__c;
                            
                            smrsList.add(smrs);
                        }
                    }
                }
                insert smrsList;
            }
            return smrsList;
        } 
        set;
    }
    
    public List<Custom_Tab_Settings__c> csTabSettings {
        get{
            if (csTabSettings == null) {
                
                csTabSettings= new List<Custom_Tab_Settings__c>();
                
                List<String> tabNames = new List<String>{'Inventory','Purchasing','Order Management','Specification','Planning', 'Assign Facility'};
            
                for(String tab:tabNames){
                    
                        Custom_Tab_Settings__c cs = new Custom_Tab_Settings__c();
                        cs.Name = tab+'tab';
                        if(tab == 'Inventory'){
                            cs.Tab_Name__c = tab;
                            cs.Sequence__c = 1;
                            cs.Object_API_Name__c = 'Item__c';
                            cs.Header_Field_Set_Object_API_Name__c = 'Item__c';
                            cs.Header_Field_Set_Name__c = 'Inventory';
                            csTabSettings.add(cs);
                        }
                        if(tab == 'Purchasing'){
                            cs.Tab_Name__c = tab;
                            cs.Sequence__c = 2;
                            cs.Object_API_Name__c = 'Item__c';
                            cs.Header_Field_Set_Object_API_Name__c = 'Item__c';
                            cs.Header_Field_Set_Name__c = 'Purchasing';
                            csTabSettings.add(cs);
                        }
                        if(tab == 'Order Management'){
                            cs.Tab_Name__c = tab;
                            cs.Sequence__c = 3;
                            cs.Object_API_Name__c = 'Item__c';
                            cs.Header_Field_Set_Object_API_Name__c = 'Item__c';
                            cs.Header_Field_Set_Name__c = 'OrderDetail';
                            cs.Detail_Field_Set_Object_API_Name__c = 'Product__c';
                            cs.Detail_Field_Set_Name__c = 'Create_Product';
                            csTabSettings.add(cs);
                        }
                        if(tab == 'Specification'){
                            cs.Tab_Name__c = tab;
                            cs.Sequence__c = 4;
                            cs.Object_API_Name__c = 'Item__c';
                            cs.Header_Field_Set_Object_API_Name__c = 'Item__c';
                            cs.Header_Field_Set_Name__c = 'ItemSpec_Header';
                            cs.Detail_Field_Set_Object_API_Name__c = 'Item_Specification__c';
                            cs.Detail_Field_Set_Name__c = 'Create_ItemSpec';
                            csTabSettings.add(cs);
                        }
                        if(tab == 'Planning'){
                            cs.Tab_Name__c = tab;
                            cs.Sequence__c = 5;
                            cs.Object_API_Name__c = 'Item__c';
                            cs.Header_Field_Set_Object_API_Name__c = 'Item__c';
                            cs.Header_Field_Set_Name__c = 'Planning';
                            csTabSettings.add(cs);
                        }
                        if(tab == 'Assign Facility'){
                            cs.Tab_Name__c = tab;
                            cs.Sequence__c = 6;
                            cs.Object_API_Name__c = 'Item__c';
                            cs.Detail_Field_Set_Object_API_Name__c = 'Facility_Item__c';
                            cs.Detail_Field_Set_Name__c = 'Assign_Facility';
                            csTabSettings.add(cs);
                        }
                    
                } 
                
                insert csTabSettings;
            }
            return csTabSettings;
        }
        set;
        
    }
    
    /*
     * Item 22 (Index 12) = Case Item
     * Item 23 (Index 13) = Pallet Item
     * Item 24 (Index 14) = Item with packaging (no container override)
     * Item 25 (Index 15) = Item with packaging (case override)
     * Item 26 (Index 16) = Item with packaging (pallet override)
     */
    public List<Item__c> itemList  {
        get {
            if (itemList == null) {
                itemList = new List<Item__c>();
                for (Integer i = 10; i < 27; i++) {
                    Item__c item = new Item__c(
                        Name = company.Name + ' Item-' + i,
                        Company__c = company.Id,
                        Active__c = true,
                        Non_Inventory__c = false,
                        Description__c = 'Item-' + i,
                        Purchasing_UOM__c = uomList[8].Id,
                        Item_Attribute__c = itemAttrObj.Id,
                        Stocking_UOM__c = uomList[8].Id,
                        Packaging_UOM__c = JSON.serialize(new List<Id>{ uomList[8].Id })
                    );
                    
                    if (i == 10 || i == 15) {
                        item.Source__c = 'Manufactured';
                        item.Class__c = clsObj.ID;
                        item.Lead_Time__c = i / 2;
                        if (i == 10) item.ABC_Code__c = 'A';
                        else item.ABC_Code__c = 'B';
                    } else if (i == 21) {
                        item.Source__c = 'Manufactured';
                        item.Class__c = clsObj.ID;
                        item.Lead_Time__c = i / 3;
                    } else {
                        item.Source__c = 'Purchased';
                        item.Lead_Time__c = i / 5;
                    }

                    if (i == 22) {
                        item.Container__c = true;
                        item.Container_Package_Class__c = packageClassList[1].Id;
                        item.ExtId__c = 'CaseContainer';
                        item.Item_Attribute__c = null;
                    } else if (i == 23) {
                        item.Container__c = true;
                        item.Container_Package_Class__c = packageClassList[0].Id;
                        item.ExtId__c = 'PalletContainer';    
                        item.Item_Attribute__c = lpnAttribute.Id;
                    } else if (i == 24 || i == 25 || i == 26) {
                        item.Stocking_UOM__c = uomList[11].Id;
                        item.Purchasing_UOM__c = uomList[11].Id;
                        item.Packaging_UOM__c = JSON.serialize(new List<Id>{ uomList[11].Id, uomList[12].Id, uomList[13].Id });
                    }

                    itemList.add(item);
                }
                insert itemList;

                DML.systemTime = System.now().addHours(-2);
                List<Configuration__c> configList = new List<Configuration__c>{
                    new Configuration__c(Name = Package_Class__c.sObjectType.getDescribe().getLocalName() + '-' + Package_Class__c.sObjectType.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()),
                    new Configuration__c(Name = Item__c.sObjectType.getDescribe().getLocalName() + '-' + Item__c.sObjectType.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId())
                };
                insert configList;

                itemList[9].Container_Item__c = itemList[12].Id;
                itemList[10].Container_Item__c = itemList[13].Id;
                update itemList;

                packageClassList[0].Default_Container_Item__c = itemList[13].Id;
                packageClassList[1].Default_Container_Item__c = itemList[12].Id;
                update packageClassList;

                delete configList;
                
                List<Item_Cost__c> getCosts = costList;
            }
            return itemList;
        } 
        set;
    }
    public Item__c FreightItem  {
        get {
            if (FreightItem == null) {
                FreightItem = new Item__c();
                FreightItem.name = Company.Name + ' Freight Item';
                FreightItem.Description__c = 'Freight Item';
                FreightItem.Source__c = 'Purchased';
                FreightItem.Class__c = FreightClass.id;
                FreightItem.company__c = company.id;
                FreightItem.Active__c = true;
                FreightItem.Packaging_UOM__c = JSON.serialize(new List<Id>{uomList[8].Id});
                insert FreightItem;
            }
            return FreightItem;
        } set;
    }
    public Item__c ItemNoClassType  {
        get {
            if (ItemNoClassType == null) {
                ItemNoClassType = new Item__c();
                ItemNoClassType.name = Company.Name + '-ItemNoClassType';
                ItemNoClassType.Description__c = 'Freight Item';
                ItemNoClassType.Source__c = 'Purchased';
                ItemNoClassType.Class__c = ItemClassNoType.id;
                ItemNoClassType.company__c = company.id;
                ItemNoClassType.Active__c = true;
                ItemNoClassType.Purchasing_UOM__c = uomList[8].Id;
                ItemNoClassType.Packaging_UOM__c = JSON.serialize(new List<Id>{uomList[8].Id});
                insert ItemNoClassType;
            }
            return ItemNoClassType;
        } set;
    }
    public List<UOM_Conversion_Details__c> uomcList {
        get {
            if (uomcList == null) {
                uomcList = new List<UOM_Conversion_Details__c>(); 
                
                UOM_Conversion_Details__c Obj = new UOM_Conversion_Details__c();
                //DZ-EA
                Obj.Name = ((String)uomList[2].Id).substring(3, 15) + ((String)uomList[8].Id).substring(3, 15);
                Obj.uom_1__c = uomList[2].Id;
                Obj.uom_1_Quantity__c =1;
                Obj.uom_2__c = uomList[8].Id;
                Obj.uom_2_Quantity__c = 12.0;
                Obj.Key_1__c = string.valueof(uomList[2].Id)+string.valueof(uomList[8].Id); 
                Obj.Key_2__c = string.valueof(uomList[8].Id)+string.valueof(uomList[2].Id);
                uomcList.add(Obj);
                
                
                UOM_Conversion_Details__c Obj1 = new UOM_Conversion_Details__c();
                //FT-IN
                Obj1.Name = ((String)uomList[7].Id).substring(3, 15) + ((String)uomList[6].Id).substring(3, 15);
                Obj1.uom_1__c = uomList[7].Id;
                Obj1.uom_1_Quantity__c =1;
                Obj1.uom_2__c = uomList[6].Id;
                Obj1.uom_2_Quantity__c = 12.0;
                Obj1.Key_1__c = string.valueof(uomList[7].Id)+string.valueof(uomList[6].Id);
                Obj1.Key_2__c = string.valueof(uomList[6].Id)+string.valueof(uomList[7].Id);
                uomcList.add(Obj1);
                
                
                UOM_Conversion_Details__c Obj2 = new UOM_Conversion_Details__c();
                //MI-FT
                Obj2.Name = ((String)uomList[4].Id).substring(3, 15) + ((String)uomList[7].Id).substring(3, 15);
                Obj2.uom_1__c = uomList[4].Id;
                Obj2.uom_1_Quantity__c =1;
                Obj2.uom_2__c = uomList[7].Id;
                Obj2.uom_2_Quantity__c = 5280.0;
                Obj2.Key_1__c = string.valueof(uomList[4].Id)+string.valueof(uomList[7].Id);//string.valueof(itemList[0].Id) + 
                Obj2.Key_2__c = string.valueof(uomList[7].Id)+string.valueof(uomList[4].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj2);
            
                UOM_Conversion_Details__c Obj3 = new UOM_Conversion_Details__c();
                //YD-FT
                Obj3.Name = ((String)uomList[5].Id).substring(3, 15) + ((String)uomList[7].Id).substring(3, 15);
                Obj3.uom_1__c = uomList[5].Id;
                Obj3.uom_1_Quantity__c =1;
                Obj3.uom_2__c = uomList[7].Id;
                Obj3.uom_2_Quantity__c = 3.0;
                Obj3.Key_1__c = string.valueof(uomList[5].Id)+string.valueof(uomList[7].Id);//string.valueof(itemList[0].Id) + 
                Obj3.Key_2__c = string.valueof(uomList[7].Id)+string.valueof(uomList[5].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj3);
            
                
                UOM_Conversion_Details__c Obj4 = new UOM_Conversion_Details__c();
                //LB-OZ
                Obj4.Name = ((String)uomList[0].Id).substring(3, 15) + ((String)uomList[3].Id).substring(3, 15);
                Obj4.uom_1__c = uomList[0].Id;
                Obj4.uom_1_Quantity__c =1;
                Obj4.uom_2__c = uomList[3].Id;
                Obj4.uom_2_Quantity__c = 16.0;
                Obj4.Key_1__c = string.valueof(uomList[0].Id)+string.valueof(uomList[3].Id);//string.valueof(itemList[0].Id) + 
                Obj4.Key_2__c = string.valueof(uomList[3].Id)+string.valueof(uomList[0].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj4);
            
                UOM_Conversion_Details__c Obj5 = new UOM_Conversion_Details__c();
                //MI-YD
                Obj5.Name = ((String)uomList[4].Id).substring(3, 15) + ((String)uomList[5].Id).substring(3, 15);
                Obj5.uom_1__c = uomList[4].Id;
                Obj5.uom_1_Quantity__c =1;
                Obj5.uom_2__c = uomList[5].Id;
                Obj5.uom_2_Quantity__c = 1760.0;
                Obj5.Key_1__c = string.valueof(uomList[4].Id)+string.valueof(uomList[5].Id);//string.valueof(itemList[0].Id) + 
                Obj5.Key_2__c = string.valueof(uomList[5].Id)+string.valueof(uomList[4].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj5);
                
                UOM_Conversion_Details__c Obj6 = new UOM_Conversion_Details__c();
                //TN-LB
                Obj6.Name = ((String)uomList[1].Id).substring(3, 15) + ((String)uomList[0].Id).substring(3, 15);
                Obj6.uom_1__c = uomList[1].Id;
                Obj6.uom_1_Quantity__c =1;
                Obj6.uom_2__c = uomList[0].Id;
                Obj6.uom_2_Quantity__c = 2000.0;
                Obj6.Key_1__c = string.valueof(uomList[1].Id)+string.valueof(uomList[0].Id);//string.valueof(itemList[0].Id) + 
                Obj6.Key_2__c = string.valueof(uomList[0].Id)+string.valueof(uomList[1].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj6);
                
                UOM_Conversion_Details__c Obj7 = new UOM_Conversion_Details__c();
                //YD-FT3
                Obj7.Name = ((String)uomList[5].Id).substring(3, 15) + ((String)uomList[9].Id).substring(3, 15);
                Obj7.uom_1__c = uomList[5].Id;
                Obj7.uom_1_Quantity__c =1;
                Obj7.uom_2__c = uomList[9].Id;
                Obj7.uom_2_Quantity__c = 0.037040;
                Obj7.Key_1__c = string.valueof(uomList[5].Id)+string.valueof(uomList[9].Id);//string.valueof(itemList[9].Id) + 
                Obj7.Key_2__c = string.valueof(uomList[9].Id)+string.valueof(uomList[5].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj7);
                
                UOM_Conversion_Details__c Obj8 = new UOM_Conversion_Details__c();
                //FT3-GAL
                Obj8.Name = ((String)uomList[10].Id).substring(3, 15) + ((String)uomList[9].Id).substring(3, 15);
                Obj8.uom_1__c = uomList[10].Id;
                Obj8.uom_1_Quantity__c =1;
                Obj8.uom_2__c = uomList[9].Id;
                Obj8.uom_2_Quantity__c = 0.133680;
                Obj8.Key_1__c = string.valueof(uomList[10].Id)+string.valueof(uomList[9].Id);//string.valueof(itemList[0].Id) + 
                Obj8.Key_2__c = string.valueof(uomList[9].Id)+string.valueof(uomList[10].Id);//string.valueof(itemList[0].Id) + 
                //Obj.Conversion_Factor__c = uomcnvs[i];
                uomcList.add(Obj8);
                
                UOM_Conversion_Details__c ObjA = new UOM_Conversion_Details__c();
    	            ObjA.Name = ((String)uomList[2].Id).substring(3, 15) + ((String)uomList[9].Id).substring(3, 15);
 	            ObjA.uom_1__c = uomList[2].Id;
 	            ObjA.uom_1_Quantity__c =1;
 	            ObjA.uom_2__c = uomList[9].Id;
 	            ObjA.uom_2_Quantity__c = 12.0;
 	            ObjA.Key_1__c = string.valueof(uomList[2].Id)+string.valueof(uomList[9].Id); 
 	            ObjA.Key_2__c = string.valueof(uomList[9].Id)+string.valueof(uomList[2].Id);
 	            uomcList.add(ObjA);
              
                UOM_Conversion_Details__c ObjD = new UOM_Conversion_Details__c();
             	//YD-FT3
             	ObjD.Name = ((String)uomList[5].Id).substring(3, 15) + ((String)uomList[8].Id).substring(3, 15);
 	            ObjD.uom_1__c = uomList[5].Id;
 	            ObjD.uom_1_Quantity__c =1;
 	            ObjD.uom_2__c = uomList[8].Id;
 	            ObjD.uom_2_Quantity__c = 0.037040;
 	            ObjD.Key_1__c = string.valueof(uomList[5].Id)+string.valueof(uomList[8].Id);//string.valueof(itemList[0].Id) + 
 	            ObjD.Key_2__c = string.valueof(uomList[8].Id)+string.valueof(uomList[5].Id);//string.valueof(itemList[0].Id) + 
 	            //Obj.Conversion_Factor__c = uomcnvs[i];
 	            uomcList.add(ObjD);

                //EA2-CS
                uomcList.add(new UOM_Conversion_Details__c(
                    Name = ((String)uomList[11].Id).substring(3, 15) + ((String)uomList[12].Id).substring(3, 15),
                    UOM_1__c = uomList[11].Id,
                    UOM_1_Quantity__c = 2,
                    UOM_2__c = uomList[12].Id,
                    UOM_2_Quantity__c = 1,
                    Key_1__c = '' + uomList[11].Id + uomList[12].Id,
                    Key_2__c = '' + uomList[12].Id + uomList[11].Id
                ));

                //CS-PT
                uomcList.add(new UOM_Conversion_Details__c(
                    Name = ((String)uomList[12].Id).substring(3, 15) + ((String)uomList[13].Id).substring(3, 15),
                    UOM_1__c = uomList[12].Id,
                    UOM_1_Quantity__c = 3,
                    UOM_2__c = uomList[13].Id,
                    UOM_2_Quantity__c = 1,
                    Key_1__c = '' + uomList[12].Id + uomList[13].Id,
                    Key_2__c = '' + uomList[13].Id + uomList[12].Id
                ));
                
                insert uomcList;
            }
            return uomcList;
        } 
        set;
    }
      
    public Item_Specification__c assembly {
        get {
            if (assembly == null) {
                assembly = new Item_Specification__c(
                    Facility__c = facility2.Id,
                    Item__c  = itemList[0].Id,
                    Start_Date2__c = System.now().addDays(-39),
                    Revision__c = 'A1',
                    Company__c = company.Id,
                    Production__c = true,
                    Costing__c = true,
                    Copy_Phantom_Routings__c = false,
                    Packaging_UOM__c = uomList[8].Id,
                    Default_Work_Order_Packaging_UOM__c = uomList[8].Id
                );
                insert assembly;

                System.assert(assemblyRoutings != null);
                System.assert(assemblyComponents != null);
            }
            return assembly;
        }
        set;
    }

    public List<Routing__c> assemblyRoutings {
        get {
            if (assemblyRoutings == null) {
                if (company.Manufacturing_Calendar__c == null) {
                    company.Manufacturing_Calendar__c = manufacturingCalendar.Id;
                    update company;
                }

                assemblyRoutings = new List<Routing__c>();
                for (Integer i=0;i<3;i++) {
                	assemblyRoutings.add(new Routing__c(
                        Assembly_Item_Specification__c = assembly.Id,
                        Company__c = company.Id,
                        Facility__c = facility2.Id,
                        Work_Center_Resource__c = wcResources[i].Id,
                        Work_Center__c = wcResources[i].Work_Center__c,
                        Resource_Sequence__c = i + 1,
                        Resource_Quantity__c = 1,
                        Standard_Hours__c = 1,
                        Fixed_Hours__c = false,
                        Backflush_Resource__c = false
                    ));
                }
                insert assemblyRoutings;
            }
            return assemblyRoutings;
        } set;
    }

    public List<Component__c> assemblyComponents {
        get {
            if (assemblyComponents == null) {
                assemblyComponents = new List<Component__c>();
                for (Integer i=1;i<6;i++) {
                    Component__c component = new Component__c(
                        Component_Item__c = itemList[i].Id,
                        Assembly_Item_Specification__c = assembly.Id,
                        Quantity_per_Assembly__c = 1,
                        Type__c = ComponentService.TYPE_BACKFLUSH,
                        Company__c = company.Id,
                        Component_Sequence__c = i,
                    	Yield__c = 100.00
                    );

                    if (i == 1 || i == 2) {
                        component.Routing__c = assemblyRoutings[0].Id;
                    } else if (i == 3 || i == 4) {
                        component.Routing__c = assemblyRoutings[1].Id;

                        if (i == 3) {
                            component.Quantity_per_Assembly__c = 2;
                        }
                    } else if (i == 5) {
                        component.Routing__c = assemblyRoutings[2].Id;
                    }

                    assemblyComponents.add(component);
                }
                insert assemblyComponents;
            }
            return assemblyComponents;
        } set;
    }

    public Item_Specification__c assembly2 {
        get {
            if (assembly2 == null) {
                itemList[4].Source__c = ItemService.ITEM_SOURCE_PHANTOM;
                update itemList[4];

                assembly2 = new Item_Specification__c(
                    Facility__c = facility2.Id,
                    Item__c  = itemList[4].Id,
                    Start_Date2__c = System.now().addDays(-39),
                    Revision__c = 'A2',
                    Company__c = company.Id,
                    Production__c = true,
                    Costing__c = true,
                    Copy_Phantom_Routings__c = false,
                    Packaging_UOM__c = uomList[8].Id,
                    Default_Work_Order_Packaging_UOM__c = uomList[8].Id
                );
                insert assembly2;

                System.assert(assembly2Routings != null);
                System.assert(assembly2Components != null);
            }
            return assembly2;
        }
        set;
    }

    public List<Routing__c> assembly2Routings {
        get {
            if (assembly2Routings == null) {
                if (company.Manufacturing_Calendar__c == null) {
                    company.Manufacturing_Calendar__c = manufacturingCalendar.Id;
                    update company;
                }

                assembly2Routings = new List<Routing__c>();
                for (Integer i=0;i<3;i++) {
                	assembly2Routings.add(new Routing__c(
                        Assembly_Item_Specification__c = assembly2.Id,
                        Company__c = company.Id,
                        Facility__c = facility2.Id,
                        Work_Center_Resource__c = wcResources[i].Id,
                        Work_Center__c = wcResources[i].Work_Center__c,
                        Resource_Sequence__c = i + 4,
                        Resource_Quantity__c = 1,
                        Standard_Hours__c = 1,
                        Fixed_Hours__c = false,
                        Backflush_Resource__c = false
                    ));
                }
                insert assembly2Routings;
            }
            return assembly2Routings;
        } set;
    }

    public List<Component__c> assembly2Components {
        get {
            if (assembly2Components == null) {
                assembly2Components = new List<Component__c>();
                for (Integer i=6;i<11;i++) {
                    Component__c component = new Component__c(
                        Component_Item__c = itemList[i].Id,
                        Assembly_Item_Specification__c = assembly2.Id,
                        Quantity_per_Assembly__c = 1,
                        Type__c = ComponentService.TYPE_BACKFLUSH,
                        Company__c = company.Id,
                        Component_Sequence__c = i,
                    	Yield__c = 100.00
                    );

                    if (i == 6 || i == 7) {
                        component.Routing__c = assembly2Routings[0].Id;

                        if (i == 6) {
                            component.Quantity_per_Assembly__c = 2.5;
                            component.Type__c = ComponentService.TYPE_KIT;
                        }
                    } else if (i == 8 || i == 9) {
                        component.Routing__c = assembly2Routings[1].Id;
                    } else if (i == 10) {
                        component.Routing__c = assembly2Routings[2].Id;
                    }

                    assembly2Components.add(component);
                }
                insert assembly2Components;
            }
            return assembly2Components;
        } set;
    }

    public Work_Order__c phantomWorkOrder  {
        get {
            if (phantomWorkOrder == null) {
                phantomWorkOrder = new Work_Order__c(
                    Company__c = company.Id,
                    Facility__c = facility2.Id,
                    Assembly_Item_Specification__c = assembly.Id,
                    Item__c = assembly.Item__c,
                    Need_Date2__c = System.today() + 30,
                    Start_Date2__c = System.today().addDays(30 - (Integer)itemList[0].Lead_Time__c),
                    Order_Quantity__c = 10,
                    Status__c = 'Draft',
                    Type__c = 'Regular',
                    Complete_To_Location__c = location6.Id,
                    MRB_Location__c = location2.Id,
                    Default_WIP_Location__c = location7.Id,
                    Notes__c = 'phantomworkorder',
                    Currency__c = TestFuel.currencyUSD.Id,
                    Packaging_UOM__c = uomList[8].Id
                );
                insert phantomWorkOrder;
            }
            return phantomWorkOrder;
        } set;
    }
    
    public List<Item_Cost__c> costList {
        get{
            if(costList == null) {
                ItemService.allowItemCostUpdate = true;
                costList = new List<Item_Cost__c>(); 
                
                List<Item_Cost__c> tempIcList = new List<Item_Cost__c>();   
            
                if (itemList.size() > 0 ) {
                    
                    for(integer i=0;i<11;i++){
                        Item_Cost__c cost = new Item_Cost__c();
                        cost.Name = itemList[i].Name;
                        cost.Item__c = itemList[i].ID;
                        cost.Material_Cost__c = 1 + i;
                        if (i == 0 || i == 5) {
                            cost.Labor_Cost__c = (i+10) * 1.2;
                            cost.Material_Cost__c = (i+10) * 1.77;
                            cost.Start_Date__c = system.now().addDays(-1);
                            cost.Facility__c = facility.Id;  
                        }else{  
                            cost.Start_Date__c = system.now().addDays(-1); 
                        }  
                        cost.Status__c = 'Proposed';
                        cost.Company__c = company.Id;
                        costList.add(cost);
                    }
                    
                    for(integer i=0;i<11;i++){
                        Item_Cost__c cost = new Item_Cost__c();
                        cost.Name = itemList[i].Name;
                        cost.Item__c = itemList[i].ID;
                        cost.Material_Cost__c = i *1.25;
                        if (i == 0 || i == 5) {
                            cost.Labor_Cost__c = (i+10) * 1.4;
                            cost.Material_Cost__c = (i+10) * 1.9;
                            cost.Facility__c = facility.Id; 
                        }            
                        cost.Status__c = 'Planning - 1';
                        cost.Start_Date__c = system.now().addDays(-1);
                        cost.Company__c = company.Id;
                        costList.add(cost);
                    }
                    
                    insert costList; 
                    
                    for(Item_Cost__c ic :costList){
                        //Only for Activate Proposed Item Cost/Revaluate Item Cost
                        if(ic.item__c == itemList[2].id || ic.item__c == itemList[3].id){
                            ic.facility__c = facility2.id;
                        }
                        if(ic.Status__c == 'Proposed'){
                            ic.Status__c = 'Approved';
                            ic.Date_Approved__c = DateTime.now();
                            ic.On_hand_Revaluation__c = true;
                        }else if(ic.Status__c == 'Planning - 1'){
                            ic.Status__c = 'Proposed';
                            ic.On_hand_Revaluation__c = false;
                        }
                        tempIcList.add(ic);
                    }
                    
                    update tempIcList;
                }
            }
            return costList;
        }
        set;
    }
    
    
    public Payment_Term__c terms  {
        get {
            if (terms == null) {
                terms = new Payment_Term__c(); 
                terms.name = '2/10 Net 30'; 
                terms.Description__c = '2% discount in 10 days, due 30 days';
                terms.Type__c = KSE.PAYMENT_TERM_DUE_DAYS; //AR-3 need to define type on Payment Terms. 
                terms.Discount_Days__c = 10;
                terms.Discount_Percent__c = 2;
                terms.Due_Days__c = 30;
                insert terms; 
            }
            return terms;
        } 
        set;
    }    
    
    public Product__c product  {
        get {
            if (product == null) {
                product = newProduct();    
                insert product;
            }
            return product;
        } 
        set;
    }
    public Cross_Reference__c crossRef {
        get {
            if(crossRef == null) {
                crossRef = newCrossRef();
                insert crossRef;
            }
            return crossRef;
        }
        set;
    }
    
    public Product__c product2  {
        get {
            if (product2 == null) {
                product2 = newProduct2();
                insert product2;  
            }
            return product2;
        } 
        set;
    }    
    
    public Product__c product3  {
        get {
            if (product3 == null) {
                product3 = new Product__c();
                product3.company__c = this.company.id;
                product3.Name =  ' Product-25';
                product3.Item__c  = this.itemList[5].ID;
                product3.Description__c = 'Product-15';
                product3.Selling_UOM__c = uomList[8].Id;
                product3.Weight__c = 5;
                product3.Weight_UOM__c = this.uomList[0].ID;
                product3.UPC_code__c = '234567891235'; 
                product3.Dimension_UOM__c = this.uomList[6].ID;
                product3.Length__c = 1;
                product3.Width__c = 1;
                product3.Height__c = 1;
                insert product3;
            }
            return product3;
        } 
        set;
    }    
    
    
    public Product__c product_Misc  {
        get {
            if (product_Misc == null) {
                product_Misc = new Product__c();
                product_Misc.company__c = this.company.id;
                product_Misc.Name =  'Product-Misc';
                itemList[11].Source__c = 'Miscellaneous';
                itemList[11].Non_Inventory__c = true;
                update itemList[11];
                product_Misc.Item__c  = this.itemList[11].ID;
                product_Misc.Description__c = 'Product-15';
                product_Misc.Selling_UOM__c = uomList[8].Id;
                product_Misc.Weight__c = 5;
                product_Misc.Weight_UOM__c = this.uomList[0].ID;
                product_Misc.UPC_code__c = '234567891235'; 
                product_Misc.Dimension_UOM__c = uomList[6].Id;
                product_Misc.Length__c = 1;
                product_Misc.Width__c = 1;
                product_Misc.Height__c = 1;
                insert product_Misc;
            }
            return product_Misc;
        } 
        set;
    }   
    public Pricebook__c pricebook  {
        get {
            if (pricebook == null) {
                pricebook = new Pricebook__c(); 
                pricebook.name = this.company.Name +  ' Orange Pricebook';
                pricebook.company__c = this.company.id; 
                pricebook.Primary_Key__c = 'NATBOOK';
                pricebook.Currency__c = TestFuel.currencyUSD.id;
                insert pricebook; 
                this.pricebook = pricebook;
                
                Pricebook_Line__c pl =new Pricebook_Line__c();
                pl.product__c = this.product.id;
                pl.pricebook__c = this.pricebook.id;
                pl.price__c = 11.12;
                pl.start_date__c = system.today(); 
                pl.end_date__c = system.today().addDays(100);
                
                Pricebook_Line__c pl2 =new Pricebook_Line__c();
                pl2.product__c = this.product2.id;
                pl2.pricebook__c = this.pricebook.id;
                pl2.price__c = 12.11;
                pl2.start_date__c = system.today();
                pl2.end_date__c = system.today().addDays(100); 
                
                Pricebook_Line__c pl3 = new Pricebook_Line__c(
                    Product__c = packageProduct.Id,
                    Pricebook__c = pricebook.Id,
                    Price__c = 0,
                    Start_Date__c = System.today(),
                    End_Date__c = System.today().addDays(100)
                );

                // note product3 is not in any pricebook
                insert new List<Pricebook_Line__c>{ pl, pl2, pl3 };
            }
            return pricebook;
        } set;
    }    
    
    public Customer__c customerParent {
        get {
            if (customerParent == null) {
                system.assert( this.company!=null && this.terms != null && this.account !=null );
                customerParent = new Customer__c(); 
                customerParent.name = this.company.Name + ' Customer Corp Parent 1';
                customerParent.recordTypeId = this.CustomerRecordTypes.get('Corporate_Parent');
                customerParent.Company__c = this.company.id;
                customerParent.Payment_Term__c = this.terms.ID;
                //customerParent.Address__c = this.account.ID;
                customerParent.Credit_Limit__c = 100000.0;
                customerParent.Customer_Identifier__c = 'CPTEST123';
                customerParent.Record_Type_Name__c = 'Corporate_Parent'; 
                customerParent.Status__c = 'Approved';
                customerParent.Currency__c = TestFuel.currencyUSD.ID;
                customerParent.Customer_Street__c = '303 Twin Dolphin Drive, Suite 500';
                customerParent.Customer_City__c = 'Redwood City'; 
                customerParent.Customer_State__c = 'CA';
                customerParent.Customer_Zip_Code__c = '94065';
                customerParent.Customer_Country__c = 'USA';
                customerParent.Track_Install_Base__c = true;

                insert customerParent;
            }
            return customerParent;
        }
        set;
    }
    
    public Customer__c customerBillTo  {
        get {
            if (customerBillTo == null) {
                system.assert( this.customerParent !=null );
                customerBillTo = new Customer__c(); 
                customerBillTo.name = 'Customer Bill To 1';
                customerBillTo.recordTypeId = this.CustomerRecordTypes.get('Bill_To');
                customerBillTo.Company__c = this.company.id;
                customerBillTo.Payment_Term__c = this.terms.ID;
                //ustomerBillTo.Address__c = this.account.ID;
                customerBillTo.Credit_Limit__c = 100000.0;
                customerBillTo.Parent_Customer__c = this.customerParent.id; 
                customerBillTo.Top_Parent_Customer__c = this.customerParent.id;
                customerBillTo.Customer_Identifier__c = 'BDTEST123'; 
                customerBillTo.Status__c = 'Approved';
                customerBillTo.Currency__c = TestFuel.currencyUSD.ID;
                customerBillTo.Customer_Street__c = '303 Twin Dolphin Drive, Suite 500';
                customerBillTo.Customer_City__c = 'Redwood City'; 
                customerBillTo.Customer_State__c = 'CA';
                customerBillTo.Customer_Zip_Code__c = '94065';
                customerBillTo.Customer_Country__c = 'USA';
                customerBillTo.Track_Install_Base__c = true;
                insert customerBillTo;
            }
            return customerBillTo;
        }
        set;
    }
    
    public Customer__c customerSoldTo  {
        get {
            if (customerSoldTo == null) {
                system.assert( this.customerBillTo !=null );
                customerSoldTo = new Customer__c(); 
                customerSoldTo.name = 'Customer Sold To 1';
                customerSoldTo.recordTypeId = this.CustomerRecordTypes.get('Sold_To');
                customerSoldTo.Company__c = this.company.id;
                customerSoldTo.Payment_Term__c = this.terms.ID;
                //customerSoldTo.Address__c = this.account.ID;
                customerSoldTo.Credit_Limit__c = 100000.0;
                customerSoldTo.Parent_Customer__c = this.customerBillTo.id; 
                customerSoldTo.Customer_Identifier__c = 'SDTEST123'; 
                customerSoldTo.Record_type_name__c = 'Sold_To';
                customerSoldTo.pricebook__c = this.pricebook.id;
                customerSoldTo.Top_Parent_Customer__c = this.customerParent.id;
                customerSoldTo.Status__c = 'Approved';
                customerSoldTo.Currency__c = TestFuel.currencyUSD.ID;
                customerSoldTo.Customer_Street__c = '303 Twin Dolphin Drive, Suite 500';
                customerSoldTo.Customer_City__c = 'Redwood City'; 
                customerSoldTo.Customer_State__c = 'CA';
                customerSoldTo.Customer_Zip_Code__c = '94065';
                customerSoldTo.Customer_Country__c = 'USA';
                customerSoldTo.Track_Install_Base__c = true;
                insert customerSoldTo;
            }
            return customerSoldTo;
        }
        set;
    }
    
    public Customer__c  customerShipTo  {
        get {
            if (customerShipTo == null) {
                customerShipTo = newCustomerShipTo();
                insert customerShipTo;
            }
            return customerShipTo;
        }
        set;
    }
    
    public Customer__c  customerSite  {
        get {
            if (customerSite == null) {
                customerSite = newCustomerSite();
                insert customerSite;
            }
            return customerSite;
        }
        set;
    }
    
	public Payment_Profile__c paymentProfile {
     	get {
     		if(paymentProfile == null) {
     			paymentProfile = new Payment_Profile__c();
 				paymentProfile.Customer__c = customerParent.Id;
 				paymentProfile.Gateway__c = 'Authorize.net';
 				paymentProfile.Payment_Profile_ID__c = 'custId123';
 				insert paymentProfile;
     		}
     		return paymentProfile;
     	}
     	set;
     }
     
     public Payment_Method__c paymentMethod {
     	get {
     		if(paymentMethod == null) {
     			paymentMethod = new Payment_Method__c();
 				paymentMethod.Payment_Profile__c = paymentProfile.Id;
 				paymentMethod.Payment_Method_ID__c = 'abc123';
 				insert paymentMethod;
     		}
     		return paymentMethod;
     		
     	}
     	set;
     }
     
    public Facility__c facility {
        get {
            if (facility == null) {
                facility = new Facility__c(
                               Name = company.Name + ' Facility-1',
                               Company__c = company.Id,
                               Primary_Key__c = 'FA01',
                               Description__c = 'Facility-1'
                           );
                insert facility;    
            }
            return facility;
        }
        set;
    }
    
    public Facility__c facility2 {
        get {
            if (facility2 == null) {
                facility2 = new Facility__c(
                    Name = company.Name + ' Facility-2',
                    Company__c = company.Id,
                    Address__c = account.Id,
                    Primary_Key__c = 'FA02',
//					Shipping_Calendar__c = [select Id from BusinessHours where isDefault = true limit 1].Id, // used for calculating EST SHIP DATE but default calendar has availability of 24/7 7 days a week so next available day has little meaning. All this does is needlessly add two queries (at least)
                    Description__c = 'Facility-2'
                );
                insert facility2;    
            }
            return facility2;
        }
        set;
    }
    
    public Location__c location { 
        get {
            if (location == null) {
                location = new Location__c(
                    Facility__c = facility.id,
                    Description__c = 'location',
                    name = 'Delivery/Shipping Location'  );
                insert location;
            }
            return location;
        }
        set; 
    }
    
    public Location__c location2 { 
        get {
            if (location2 == null) {
                location2 = new Location__c(
                    Facility__c = facility2.id,
                    Description__c = 'location2',
                    name = 'Delivery/Shipping/scrap Location'  );
                insert location2;
            }
            return location2;
        }
        set; 
    }
    
    public Location__c location3 { 
        get {
            if (location3 == null) {
                location3 = new Location__c(
                    Facility__c = facility2.id,
                    Description__c = 'location3',
                    name = 'Stock'  );
                insert location3;
            }
            return location3;
        }
        set; 
    }
    
    public Location__c location4 { 
        get {
            if (location4 == null) {
                location4= new Location__c(
                    Facility__c = facility.id,
                    Description__c = 'location4',
                    name = 'Stock'  );
                insert location4;
            }
            return location4;
        }
        set; 
    }
    
    public Location__c location5 { 
        get {
            if (location5 == null) {
                location5 = new Location__c(
                    Facility__c = facility2.id,
                    Description__c = 'location5',
                    name = 'Stock Location2'  );
                insert location5;
            }
            return location5;
        }
        set; 
    }
    
    public Location__c location6 { 
        get {
            if (location6 == null) {
                location6 = new Location__c(
                    Facility__c = facility2.id,
                    Description__c = 'location6',
                    name = 'Finished Goods'  );
                insert location6;
            }
            return location6;
        }
        set; 
    }
    
    public Location__c location7 { 
        get {
            if (location7 == null) {
                location7 = new Location__c(
                    Facility__c = facility2.id,
                    Description__c = 'location7',
                    name = 'WIP Location'  );
                insert location7;
            }
            return location7;
        }
        set; 
    }
    
    public Bin__c bin {
        get {
            List<Configuration__c> configList = new List<Configuration__c>();
            List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType};  
            
            for (sObjectType s:skipTriggers) {
                configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
            }
            insert configList;
            update new Location__c(Id = location3.Id, Bin_Tracked__c = true,Mixed_Bins_Allowed__c = true);
            delete configList;
            if (bin == null) {
                bin = new Bin__c(
                               Name = 'Stock-Bin-1',
                               Description__c = 'bin',
                               Location__c = location3.id
                           );
                insert bin;    
            }
            return bin;
        }
        set;
    }
    
    public GL_Type__c currentAssets{
        get{
            if(currentAssets == null){
                if(mGLTypes.size() != 0 && mGLTypes.containsKey('Current Assets')){
                    currentAssets = mGLTypes.get('Current Assets');
                }
                
            }
            return currentAssets;
        }
        set;
    }
    
    public GL_Type__c longTermAssets{
        get{
            if(longTermAssets == null){
                if(mGLTypes.size() != 0 && mGLTypes.containsKey('Long Term Assets')){
                    longTermAssets = mGLTypes.get('Long Term Assets');
                }
            }
            return longTermAssets;
        }
        set;
    }
    
    public GL_Type__c currentLiabilities{
        get{
            if(currentLiabilities == null){
                if(mGLTypes.size() != 0 && mGLTypes.containsKey('Current Liabilities')){
                    currentLiabilities = mGLTypes.get('Current Liabilities');
                }
            }
            return currentLiabilities;
        }
        set;
    }
    
    public GL_Type__c longTermLiabilities{
        get{
            if(longTermLiabilities == null){
                if(mGLTypes.size() != 0 && mGLTypes.containsKey('Long Term Liabilities')){
                    longTermLiabilities = mGLTypes.get('Long Term Liabilities');
                }
            }
            return longTermLiabilities;
        }
        set;
    } 
    
    public GL_Type__c equity{
        get{
            if(equity == null){
                if(mGLTypes.size() != 0 && mGLTypes.containsKey('Equity')){
                    equity = mGLTypes.get('Equity');
                }
            }
            return equity;
        }
        set;
    }
    
    public GL_Type__c revenue{
        get{
            if(revenue == null){
                if(mGLTypes.size() != 0 && mGLTypes.containsKey('Revenue')){
                    revenue = mGLTypes.get('Revenue');
                }
            }
            return revenue;
        }
        set;
    }
    
    public GL_Type__c costOfGoodsSold{
        get{
            if(costOfGoodsSold == null){
                if(mGLTypes.size() != 0 && mGLTypes.containsKey('Cost of Goods Sold')){
                    costOfGoodsSold = mGLTypes.get('Cost of Goods Sold');
                }
            }
            return costOfGoodsSold;
        }
        set;
    }
    
    public GL_Type__c expense{
        get{
            if(expense == null){
                if(mGLTypes.size() != 0 && mGLTypes.containsKey('Expense')){
                    expense = mGLTypes.get('Expense');
                }
            }
            return expense;
        }
        set;
    }
    
    public GL_Type__c operatingExpense{
        get{
            if(operatingExpense == null){
                if(mGLTypes.size() != 0 && mGLTypes.containsKey('Operating Expense')){
                    operatingExpense = mGLTypes.get('Operating Expense');
                }
            }
            return operatingExpense;
        }
        set;
    }
    
    public GL_Type__c otherIncome_Expense{
        get{
            if(otherIncome_Expense == null){
                if(mGLTypes.size() != 0 && mGLTypes.containsKey('Other Income')){
                    otherIncome_Expense = mGLTypes.get('Other Income');
                }
            }
            return otherIncome_Expense;
        }
        set;
    }
    
    public GL_Account__c taxGL { 
        get {
            if ( taxGL == null && mGLAccounts.containsKey('24000')) {
                taxGL = mGLAccounts.get('24000');
            }
            return taxGL; 
        }
        set; 
    } 
    
    public GL_Account__c rfxGL{
        get{
            if(rfxGL == null && mGLAccounts.containsKey('79500')){
                rfxGL = mGLAccounts.get('79500');
            }
            return rfxGL;
        }
        set;
    }
    
    public GL_Account__c intercompanyInvestmentGL { 
        get {
            if ( intercompanyInvestmentGL == null && mGLAccounts.containsKey('14100')) {
                intercompanyInvestmentGL = mGLAccounts.get('14100');
            }
            return intercompanyInvestmentGL; 
        }
        set; 
    }
    
    public GL_Account__c intercompanyAPGL { 
        get {
            if ( intercompanyAPGL == null && mGLAccounts.containsKey('21500')) {
                intercompanyAPGL = mGLAccounts.get('21500');
            }
            return taxGL; 
        }
        set; 
    } 
    
    public GL_Account__c intercompanyARGL { 
        get {
            if ( intercompanyARGL == null && mGLAccounts.containsKey('11500')) {
                intercompanyARGL = mGLAccounts.get('11500');
            }
            return intercompanyARGL; 
        }
        set; 
    }
    
    public GL_Account__c intercompanyAPICGL { 
        get {
            if ( intercompanyAPICGL == null && mGLAccounts.containsKey('29000')) {
                intercompanyAPICGL = mGLAccounts.get('29000');
            }
            return intercompanyAPICGL; 
        }
        set; 
    }
    
    public GL_Account__c cashCompanyAGL { 
        get {
            if ( cashCompanyAGL == null && mGLAccounts.containsKey('12200')) {
                cashCompanyAGL = mGLAccounts.get('12200');
            }
            return cashCompanyAGL; 
        }
        set; 
    }
    
    public GL_Account__c cashCompanyBGL { 
        get {
            if ( cashCompanyBGL == null && mGLAccounts.containsKey('12300')) {
                cashCompanyBGL = mGLAccounts.get('12300');
            }
            return cashCompanyBGL; 
        }
        set; 
    }
    
    public GL_Account__c UnappliedCashGL { 
        get {
            if ( UnappliedCashGL == null && mGLAccounts.containsKey('12100')) {
                UnappliedCashGL = mGLAccounts.get('12100');
            }
            return UnappliedCashGL; 
        }
        set; 
    }
    
    public GL_Account__c IntercompanyUnappliedCashGL { 
        get {
            if ( IntercompanyUnappliedCashGL == null && mGLAccounts.containsKey('12400')) {
                IntercompanyUnappliedCashGL = mGLAccounts.get('12400');
            }
            return IntercompanyUnappliedCashGL; 
        }
        set; 
    }
    
    public GL_Account__c overPaymentGL { 
        get {
            if ( overPaymentGL == null && mGLAccounts.containsKey('24100')) {
                overPaymentGL = mGLAccounts.get('24100');
            }
            return overPaymentGL; 
        }
        set; 
    } 
    
    public GL_Account__c allowanceExpGL { 
        get {
            if ( allowanceExpGL == null && mGLAccounts.containsKey('65000')) {
                allowanceExpGL = mGLAccounts.get('65000');
            }
            return allowanceExpGL; 
        }
        set; 
    }
    
    public GL_Account__c cashGL { 
        get {
            if ( cashGL == null && mGLAccounts.containsKey('12000')) {
                cashGL = mGLAccounts.get('12000');
            }
            return cashGL; 
        }
        set; 
    } 
    public GL_Account__c PPVGL { 
        get {
            if ( PPVGL == null && mGLAccounts.containsKey('59000')) {
                    PPVGL = mGLAccounts.get('59000');
            }
            return PPVGL; 
        }
        set; 
    } 
    
    public GL_Account__c IPVGL { 
        get {
            if ( IPVGL == null && mGLAccounts.containsKey('59100')) {
                    IPVGL = mGLAccounts.get('59100');
            }
            return IPVGL; 
        }
        set; 
    } 
    
    public GL_Account__c propertyGL { 
        get {
            if ( propertyGL == null && mGLAccounts.containsKey('17000')) {
                propertyGL = mGLAccounts.get('17000');
            }
            return propertyGL; 
        }
        set; 
    } 
    
    public GL_Account__c FGInventoryGL{
        
        get{
            if ( FGInventoryGL == null && mGLAccounts.containsKey('15000')) {
                FGInventoryGL = mGLAccounts.get('15000');
            }
            return FGInventoryGL; 
        }
        set; 
    } 
    
    public GL_Account__c receivablesGL { 
        get {
            if ( receivablesGL == null && mGLAccounts.containsKey('11000')) {
                receivablesGL = mGLAccounts.get('11000');
            }
            return receivablesGL; 
        }
        set; 
    } 
    
    public GL_Account__c payablesGL { 
        get {
            if ( payablesGL == null && mGLAccounts.containsKey('21000')) {
                payablesGL = mGLAccounts.get('21000');
            }
            return payablesGL; 
        }
        set; 
    } 
    
    public GL_Account__c GRNIGL { 
        get {
            if ( GRNIGL == null && mGLAccounts.containsKey('23000')) {
                GRNIGL = mGLAccounts.get('23000');
            }
            return GRNIGL; 
        }
        set; 
    } 
    
    public GL_Account__c expenseGL { 
        get {
            if ( expenseGL == null && mGLAccounts.containsKey('55100')) {
                expenseGL = mGLAccounts.get('55100');
            }
            return expenseGL; 
        }
        set; 
    } 
    
    public GL_Account__c revenueGL { 
        get {
            if ( revenueGL == null && mGLAccounts.containsKey('42000')) {
                revenueGL = mGLAccounts.get('42000');
            }
            return revenueGL; 
        }
        set; 
    } 
    
    public GL_Account__c retainedEarningsGL { 
        get {
            if ( retainedEarningsGL == null && mGLAccounts.containsKey('39000')) {
                retainedEarningsGL = mGLAccounts.get('39000');
            }
            return retainedEarningsGL; 
        }
        set; 
    } 
    
    public GL_Account__c cogsGL { 
        get {
            if ( cogsGL == null && mGLAccounts.containsKey('50000')) {
                cogsGL = mGLAccounts.get('50000');
            }
            return cogsGL; 
        }
        set; 
    } 
    
    
    public Bank_Account__c bankAccount {
		get {
			if (bankAccount == null) {
    			bankAccount = new Bank_Account__c(
    				Name = 'Test BOFA',
    				account_type__c = 'Checking',
    				GL_Account__c = cashGL.id,
    				Company__c = company.Id,
    				Active__c = true,
                    Bank_Account_Number_2__c = '12345',
    				Currency__c = TestFuel.currencyUSD.id
				);
				insert bankAccount; 
				company.Credit_Card_Bank_Account__c = bankAccount.Id;
				update company;
			}
			return bankAccount;
		}
		set; 
    } 
    
    public FOB_Terms__c fobTerm {
        get {
            if ( fobTerm == null  ) {
                 fobTerm = new FOB_Terms__c(
                                             Name = 'test term destination',
                                             FOB_Point__c = 'Destination'
                                        );
                insert fobTerm;
                
            }
                
            return fobTerm;
        }
        set;
    }

    public Supplier__c remitToSupplier { 
        get {
            if ( remittosupplier == null ) { 
                remittosupplier = new Supplier__c(); 
                remittosupplier.Name = company.Name + ' Supplier-1';
                remittosupplier.Company__c = company.ID;
                remittosupplier.Tax_ID__c = 'tax ID';
                remittosupplier.Address__c = account.ID;  // remittoaccount ?? TODO 
                remittosupplier.Status__c = 'Active';
                remittosupplier.Payment_Term__c = terms.ID;
                remittosupplier.Always_Take_Discount__c = false;
                remittosupplier.Type__c = 'Remit-To';
                remitToSupplier.RecordTypeId = SupplierRecordTypes.get('Remit_To');
                remitToSupplier.Alternate_Name__c = 'Remit to Supplier';
                insert remittosupplier;
            }
            return remittosupplier;
        }
        set; 
    }   
    
    public Supplier__c supplier { 
        get {
            if ( supplier == null ) { 
                supplier = new Supplier__c(); 
                supplier.Name = company.Name + ' Supplier-1';
                supplier.Company__c = company.ID;
                supplier.Tax_ID__c = 'tax ID';
                supplier.Address__c = account.ID;  // remittoaccount ?? TODO 
                supplier.Status__c = 'Active';
                //supplier.Payment_Term__c = terms.ID;
                supplier.FOB_Term__c = fobTerm.id;
                supplier.Type__c = 'Purchasing';
                supplier.RecordTypeId = SupplierRecordTypes.get('Purchase_From');
                supplier.Remit_To__c =  remittosupplier.id;
                supplier.Default_Receiving_Tolerance__c = 3;
                supplier.Create_RTV_Credit_Memo__c = true;
                supplier.Create_RTV_PO__c = true; 
                supplier.Alternate_Name__c = 'Test Supplier';
                insert supplier;
            }
            return supplier;
        }
        set; 
    }
    
    public Hierarchy__c hierarchy1 { 
        get {
            if (hierarchy1 == null  ) {
                hierarchy1 = new Hierarchy__c( 
                    Code__c = 'H1111' , 
                    Primary_Key__c = 'H1111' , 
                    Type__c = 'Product Hierarchy'
                );
                insert hierarchy1; 
            }
            return hierarchy1;
        }
        set; 
    }
    
    public Product_Group__c productGroup { 
        get {
            if ( productGroup == null  ) {
                productGroup = new Product_Group__c( 
                    name ='foo',  
                    Primary_Key__c = 'PG23',
                    Hierarchy_Code__c = 'H1111' 
                );
                insert productGroup;
            }
            return productGroup;
        }
        set; 
    }
    
    public List<SKID__c> skids {
        get {
            if (skids == null) {
                skids = new List<SKID__c>();
                for (Item__c item : this.itemList) {
                    SKID__c skid = new SKID__c();
                    skid.location__c = this.location3.id;
                    skid.Facility2__c = this.facility2.Id;
                    skid.Company__c= this.company.id;
                    skid.Quantity__c = 200.0;
                    skid.Item__c= item.Id;
                    skid.Type__c = SKIDService.SKID_TYPE_LOCATION;
                    skid.Quantity_Stocking_UOM__c = 100;
                    skid.Stocking_UOM__c = item.Stocking_UOM__c;
                    skid.Packaging_UOM__c = item.Stocking_UOM__c;
                    skid.Packaging_UOM__r = uomList[8];
                    skid.Container_Item__c = item.id;
                    skid.Expiration_Date__c = System.today() + 365;
                    
                    SKID__c skid1 = skid.clone(false,false);
                    skid1.location__c = this.location5.id;
                    
                    skids.add(skid);
                    skids.add(skid1);
                }
                insert skids;
            }
            return skids;
        } 
        set;
    }
    
    public Sales_Order__c salesOrder { 
        get {
            if ( salesOrder == null  ) {
                salesOrder = newSalesOrder();
                salesOrder.Ship_to__c = customerShipTo.Id;
                salesOrder.Bill_To__c = customerBillTo.Id;
                salesOrder.Currency__c = TestFuel.currencyUSD.id;
                salesOrder.Original_Sales_Order__c = 'so123'; 
                salesOrder.Type__c = 'Standard';
                insert salesOrder;
                insert salesOrderLines;
            }
            return salesOrder;
        }
        set; 
    }
    
    public List<Sales_Order_Line__c> salesOrderLines {
        get{
            if(salesOrderLines == null){
                salesOrderLines = new List<Sales_Order_Line__c>();
                
                Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
                salesOrderLine.Company__c = company.Id;
                salesOrderLine.Description__c = product.Description__c;
                salesOrderLine.Discount_Percent__c = 2;
                salesOrderLine.Product__c = product.Id;
                salesOrderLine.Product__r = product;
                salesOrderLine.Product_Reference__c = crossRef.id;
                salesOrderLine.Quantity_Ordered__c = 100;
                salesOrderLine.Required_Date__c = System.today()+5;
                salesOrderLine.Sales_Order__c = salesOrder.Id;
                salesOrderLine.Ship_From_Location__c = location2.Id;
                salesOrderLine.Unit_Price__c = 11.12;
                salesOrderLine.Memo__c = 'salesOrderLine';
                SalesOrderLine.Selling_UOM__c = uomList[8].id;
                SalesOrderLine.Packaging_UOM__c = uomList[8].id;
                SalesOrderLine.Line__c = 1;
                salesOrderLines.add(salesOrderLine);
                
                Sales_Order_Line__c salesOrderLine2 = new Sales_Order_Line__c();
                salesOrderLine2.Company__c = company.id;
                salesOrderLine2.Description__c = product2.Description__c;
                salesOrderLine2.Discount_Percent__c = 2;
                salesOrderLine2.Product__c = product2.Id;
                salesOrderLine2.Product__r = product2;
                salesOrderLine2.Quantity_Ordered__c = 15;
                salesOrderLine2.Required_Date__c = System.today()+15;
                salesOrderLine2.Sales_Order__c = salesOrder.Id;
                salesOrderLine2.Ship_From_Location__c = location2.Id;
                SalesOrderLine2.Selling_UOM__c = uomList[8].id;
                SalesOrderLine2.Packaging_UOM__c = uomList[8].id;
                salesOrderLine2.Unit_Price__c = 12.11;
                salesOrderLine2.Sales_Tax__c = 14.686403;
                salesOrderLine2.Memo__c = 'salesOrderLine2';
                SalesOrderLine2.Line__c = 2;
                salesOrderLines.add(salesOrderLine2);
            }
            return salesOrderLines;
        }
        set;
    }
    
    public Sales_Order__c salesOrder1 { 
        get {
            if ( salesOrder1 == null  ) {
                salesOrder1 = new Sales_Order__c();
                salesOrder1.Customer__c=customerSoldTo.id;
                salesOrder1.Currency__c = TestFuel.currencyUSD.id ;
                salesOrder1.Status__c='Open';
                salesOrder1.Type__c = 'Standard';
                salesOrder1.Payment_Term__c = terms.id;
                salesOrder1.Company__c = company.id;
                salesOrder1.Ship_Complete__c = true;
                salesOrder1.Weight_UOM__c = uomList[0].ID;
                salesOrder1.Dimension_UOM__c = uomList[5].ID;
                salesOrder1.Original_Sales_Order__c = 'salesOrder1';
                insert salesOrder1;
                insert salesOrder1Lines;
            }
            return salesOrder1;
        }
        set; 
    }
    
    public List<Sales_Order_Line__c> salesOrder1Lines {
        get{
            if(salesOrder1Lines == null){
                salesOrder1Lines = new List<Sales_Order_Line__c>();
                
                Sales_Order_Line__c salesOrderLineObj1 = new Sales_Order_Line__c();
                salesOrderLineObj1.Sales_Order__c=salesOrder1.Id;
                salesOrderLineObj1.Quantity_Ordered__c =12; 
                salesOrderLineObj1.Unit_Price__c = 480;
                salesOrderLineObj1.Required_Date__c=System.today()+5;
                salesOrderLineObj1.Status__c='Open';
                salesOrderLineObj1.Company__c = company.id;
                salesOrderLineObj1.Product__c = product.id;
                salesOrderLineObj1.Ship_From_Location__c = location.id;
                salesOrderLineObj1.Line_Type__c = 'Standard';
                salesOrderLineObj1.Weight_UOM__c = uomList[0].ID;
                salesOrderLineObj1.Dimension_UOM__c = uomList[5].ID;
                salesOrder1Lines.add(salesOrderLineObj1);
                
                Sales_Order_Line__c salesOrderLineObj2 = new Sales_Order_Line__c();
                salesOrderLineObj2.Sales_Order__c=salesOrder1.Id;
                salesOrderLineObj2.Quantity_Ordered__c =5; 
                salesOrderLineObj2.Unit_Price__c = 480;
                salesOrderLineObj2.Required_Date__c=System.today()+30;
                salesOrderLineObj2.Status__c='Open';
                salesOrderLineObj2.Company__c = company.id;
                salesOrderLineObj2.Product__c = product.id;
                salesOrderLineObj2.Ship_From_Location__c = location.id;
                salesOrderLineObj2.Line_Type__c = 'Standard';
                salesOrderLineObj2.Weight_UOM__c = uomList[0].ID;
                salesOrderLineObj2.Dimension_UOM__c = uomList[5].ID;
                salesOrder1Lines.add(salesOrderLineObj2);
            }
            return salesOrder1Lines;
        }
        set;
    }
    
    public Sales_Order__c salesOrder2 { 
        get {
            if ( salesOrder2 == null  ) {
                salesOrder2 = new Sales_Order__c();
                salesOrder2.Customer__c = customerSoldTo.id;
                salesOrder2.Currency__c = TestFuel.currencyUSD.id ;
                salesOrder2.Status__c='Open';
                salesOrder2.Type__c = 'Special';
                salesOrder2.Payment_Term__c = terms.id;
                salesOrder2.company__c = company.id;
                salesOrder2.Weight_UOM__c = uomList[0].ID;
                salesOrder2.Dimension_UOM__c = uomList[5].ID;
                salesOrder2.Original_Sales_Order__c = 'salesOrder2';
                insert salesOrder2;
                insert salesOrder2Lines;
            }
            return salesOrder2;
        }
        set; 
    }
    
    public List<Sales_Order_Line__c> salesOrder2Lines {
        get{
            if(salesOrder2Lines == null){
                salesOrder2Lines = new List<Sales_Order_Line__c>();
                
                Sales_Order_Line__c salesOrderLineObj3 = new Sales_Order_Line__c();
                salesOrderLineObj3.Sales_Order__c=salesOrder2.Id;
                salesOrderLineObj3.Quantity_Ordered__c =3; 
                salesOrderLineObj3.Unit_Price__c = 480;
                salesOrderLineObj3.Required_Date__c=System.today()+5;
                salesOrderLineObj3.Status__c='Open';
                salesOrderLineObj3.Company__c = company.id;
                salesOrderLineObj3.Product__c = product.id;
                salesOrderLineObj3.Ship_From_Location__c = location.id;
                salesOrderLineObj3.Line_Type__c = 'Standard';
                salesOrderLineObj3.Weight_UOM__c = uomList[0].ID;
                salesOrderLineObj3.Dimension_UOM__c = uomList[5].ID;
                            
                salesOrder2Lines.add(salesOrderLineObj3);
                
                Sales_Order_Line__c salesOrderLineObj4 = new Sales_Order_Line__c();
                salesOrderLineObj4.Sales_Order__c=salesOrder2.Id;
                salesOrderLineObj4.Quantity_Ordered__c =3; 
                salesOrderLineObj4.Unit_Price__c = 480;
                salesOrderLineObj4.Required_Date__c=System.today()+5;
                salesOrderLineObj4.Status__c='Open';
                salesOrderLineObj4.Company__c = company.id;
                salesOrderLineObj4.Product__c = product.id;
                salesOrderLineObj4.Ship_From_Location__c = location.id;
                salesOrderLineObj4.Line_Type__c = 'Distribution Sample'; 
                salesOrderLineObj4.Weight_UOM__c = uomList[0].ID;
                salesOrderLineObj4.Dimension_UOM__c = uomList[5].ID;         
                salesOrder2Lines.add(salesOrderLineObj4);
            }
            return salesOrder2Lines;
        }
        set;
    }
    
    
    public Sales_Order__c salesOrder3 { 
        get {
            if ( salesOrder3 == null  ) {
                salesOrder3 = new Sales_Order__c();
                salesOrder3.Customer__c = customerSoldTo.id;
                salesOrder3.Currency__c = TestFuel.currencyUSD.id ;
                salesOrder3.Status__c='Open';
                salesOrder3.Type__c = 'Adjustment';
                salesOrder3.Payment_Term__c = terms.id;
                salesOrder3.company__c = company.id;
                salesOrder3.Weight_UOM__c = uomList[0].ID;
                salesOrder3.Dimension_UOM__c = uomList[5].ID;
                salesOrder3.Original_Sales_Order__c = 'salesOrder3';
                insert salesOrder3;
                insert salesOrder3Lines;
            }
            return salesOrder3;
        }
        set; 
    }
    
    public List<Sales_Order_Line__c> salesOrder3Lines {
        get{
            if(salesOrder3Lines == null){
                salesOrder3Lines = new List<Sales_Order_Line__c>();
                
                Sales_Order_Line__c salesOrderLineObj31 = new Sales_Order_Line__c();
                salesOrderLineObj31.Sales_Order__c=salesOrder3.Id;
                salesOrderLineObj31.Quantity_Ordered__c =-2; 
                salesOrderLineObj31.Unit_Price__c = 40;
                salesOrderLineObj31.Required_Date__c=System.today()+5;
                salesOrderLineObj31.Status__c='Open';
                salesOrderLineObj31.Company__c = company.id;
                salesOrderLineObj31.Product__c = product.id;
                salesOrderLineObj31.Ship_From_Location__c = location.id;
                salesOrderLineObj31.Weight_UOM__c = uomList[0].ID;
                salesOrderLineObj31.Dimension_UOM__c = uomList[5].ID; 
                
                salesOrder3Lines.add(salesOrderLineObj31);
            }
            return salesOrder3Lines;
        }
        set;
    }
    
    public Receiving_Document__c receivingDocumentASN { 
        get {
            if ( receivingDocumentASN == null  ) {
                receivingDocumentASN = newreceivingDocumentASN();

                insert receivingDocumentASN;
                insert receivingDocumentASNLines;
            }
            return receivingDocumentASN;
        }
        set; 
    }
    
    public List<Receipt_Line__c> receivingDocumentASNLines {
        get{
            if(receivingDocumentASNLines == null){
                receivingDocumentASNLines = new List<Receipt_Line__c>();
                
                Receipt_Line__c receivingDocumentASNLine = new Receipt_Line__c();
                receivingDocumentASNLine.Company__c = company.Id;
                receivingDocumentASNLine.Purchase_Order__c = purchaseOrder.Id;
                receivingDocumentASNLine.Purchase_Order_Line__c = purchaseOrderLines[0].Id;
                receivingDocumentASNLine.Item__c = purchaseOrderLines[0].Item__c;
                receivingDocumentASNLine.Quantity_Declared__c = 5;
                receivingDocumentASNLine.Expiration_Date__c = System.today()+5;
                receivingDocumentASNLine.Lot_Number__c = '1234';
                receivingDocumentASNLine.Status__c = 'Draft';
                receivingDocumentASNLine.Supplier__c = supplier.id;
                receivingDocumentASNLine.Receiving_Document__c = receivingDocumentASN.id;
                receivingDocumentASNLines.add(receivingDocumentASNLine);

            }
            return receivingDocumentASNLines;
        }
        set;
    }
    
    public Receiving_Document__c receivingDocumentMisc { 
        get {
            if ( receivingDocumentMisc == null  ) {
                receivingDocumentMisc = newreceivingDocumentASN();
                receivingDocumentMisc.Type__c = 'Miscellaneous Receipt';

                insert receivingDocumentMisc;
                insert receivingDocumentMiscLines;
            }
            return receivingDocumentMisc;
        }
        set; 
    }
    
    public List<Receipt_Line__c> receivingDocumentMiscLines {
        get{
            if(receivingDocumentMiscLines == null){
                receivingDocumentMiscLines = new List<Receipt_Line__c>();
                
                Receipt_Line__c receivingDocumentMiscLine = new Receipt_Line__c();
                receivingDocumentMiscLine.Company__c = company.Id;
                receivingDocumentMiscLine.Item__c = itemList[0].Id;
                receivingDocumentMiscLine.Quantity_Declared__c = 5;
                receivingDocumentMiscLine.Status__c = 'Draft';
                receivingDocumentMiscLine.Receiving_Document__c = receivingDocumentMisc.id;
                receivingDocumentMiscLines.add(receivingDocumentMiscLine);

            }
            return receivingDocumentMiscLines;
        }
        set;
    }
    
    public List<Stock_Movement_Rule__c> stockMovementRuleList {
        get{
            if(stockMovementRuleList == null){
                stockMovementRuleList = new List<Stock_Movement_Rule__c>();
                
                Stock_Movement_Rule__c stockMovement1 = new Stock_Movement_Rule__c();
                stockMovement1.Name = 'Putaway rule1';
                stockMovement1.Rule_Type__c = 'Putaway';
                stockMovement1.Company__c = company.id;
                stockMovement1.Facility__c = facility2.id;
                stockMovement1.Class__c = clsObj.id;
                stockMovement1.Item__c = null;
                stockMovement1.Customer__c = null;
                stockMovement1.Source_Document__c = 'Purchase Order';
                stockMovement1.Priority__c = 4;
                stockMovement1.Location_List__c = JSON.serialize(new List<Id>{location3.id,location5.id});
                stockMovement1.Active__c = true;
                stockMovementRuleList.add( stockMovement1 );  
                
                Stock_Movement_Rule__c stockMovement2 = new Stock_Movement_Rule__c();
                stockMovement2.Name = 'Putaway rule2';
                stockMovement2.Rule_Type__c = 'Putaway';
                stockMovement2.Company__c = company.id;
                stockMovement2.Facility__c = facility2.id;
                stockMovement2.Class__c = null;
                stockMovement2.Item__c = null;
                stockMovement2.Customer__c = null;
                stockMovement2.Source_Document__c = 'Work Order';
                stockMovement2.Priority__c = 5;
                stockMovement2.Location_List__c = JSON.serialize(new List<Id>{location3.id,location5.id});
                stockMovement2.Active__c = true;
                stockMovementRuleList.add( stockMovement2 );  
                
                Stock_Movement_Rule__c stockMovement3 = new Stock_Movement_Rule__c();
                stockMovement3.Name = 'Pick rule1';
                stockMovement3.Rule_Type__c = 'Pick';
                stockMovement3.Company__c = company.id;
                stockMovement3.Facility__c = facility2.id;
                stockMovement3.Class__c = null;
                stockMovement3.Item__c = itemList[0].id;
                stockMovement3.Customer__c = customerSoldTo.id;
                stockMovement3.Source_Document__c = 'Sales Order';
                stockMovement3.Priority__c = 1;
                stockMovement3.Location_List__c = JSON.serialize(new List<Id>{location3.id,location5.id});
                stockMovement3.Active__c = true;
                stockMovementRuleList.add( stockMovement3 );  
                
                Stock_Movement_Rule__c stockMovement4 = new Stock_Movement_Rule__c();
                stockMovement4.Name = 'Pick rule2';
                stockMovement4.Rule_Type__c = 'Pick';
                stockMovement4.Company__c = company.id;
                stockMovement4.Facility__c = facility2.id;
                stockMovement4.Class__c = null;
                stockMovement4.Item__c = null;
                stockMovement4.Customer__c = customerSoldTo.id;
                stockMovement4.Source_Document__c = 'Sales Order';
                stockMovement4.Priority__c = 2;
                stockMovement4.Location_List__c = JSON.serialize(new List<Id>{location3.id,location5.id});
                stockMovement4.Active__c = true;
                stockMovementRuleList.add( stockMovement4 );  
                
                Stock_Movement_Rule__c stockMovement5 = new Stock_Movement_Rule__c();
                stockMovement5.Name = 'Pick rule3';
                stockMovement5.Rule_Type__c = 'Pick';
                stockMovement5.Company__c = company.id;
                stockMovement5.Facility__c = facility2.id;
                stockMovement5.Class__c = null;
                stockMovement5.Item__c = null;
                stockMovement5.Customer__c = null;
                stockMovement5.Source_Document__c = 'Work Order';
                stockMovement5.Priority__c = 3;
                stockMovement5.Location_List__c = JSON.serialize(new List<Id>{location3.id,location5.id});
                stockMovement5.Active__c = true;
                stockMovementRuleList.add( stockMovement5 ); 
                
                Stock_Movement_Rule__c stockMovement6 = new Stock_Movement_Rule__c();
                stockMovement6.Name = 'Putaway rule3';
                stockMovement6.Rule_Type__c = 'Putaway';
                stockMovement6.Company__c = company.id;
                stockMovement6.Facility__c = facility2.id;
                stockMovement6.Source_Document__c = 'Purchase Order';
                stockMovement6.Priority__c = 6;
                stockMovement6.Location_List__c = JSON.serialize(new List<Id>{location3.id,location5.id});
                stockMovement6.Active__c = true;
                stockMovementRuleList.add( stockMovement6 );  
                
                Stock_Movement_Rule__c stockMovement7 = new Stock_Movement_Rule__c();
                stockMovement7.Name = 'Transfer Order Pick rule';
                stockMovement7.Rule_Type__c = 'Pick';
                stockMovement7.Company__c = company.id;
                stockMovement7.Facility__c = facility2.id;
                stockMovement7.Source_Document__c = 'Transfer Order';
                stockMovement7.Priority__c = 1;
                stockMovement7.Location_List__c = JSON.serialize(new List<Id>{location3.id,location5.id});
                stockMovement7.Active__c = true;
                stockMovementRuleList.add( stockMovement7 ); 
                
                Stock_Movement_Rule__c stockMovement8 = new Stock_Movement_Rule__c();
                stockMovement8.Name = 'Transfer Order Putaway rule';
                stockMovement8.Rule_Type__c = 'Putaway';
                stockMovement8.Company__c = company.id;
                stockMovement8.Facility__c = facility.id;
                stockMovement8.Source_Document__c = 'Transfer Order';
                stockMovement8.Priority__c = 1;
                stockMovement8.Location_List__c = JSON.serialize(new List<Id>{location4.id});
                stockMovement8.Active__c = true;
                stockMovementRuleList.add( stockMovement8 ); 
                
                Stock_Movement_Rule__c stockMovement9 = new Stock_Movement_Rule__c();
                stockMovement9.Name = 'Putaway rule3';
                stockMovement9.Rule_Type__c = 'Putaway';
                stockMovement9.Company__c = company.id;
                stockMovement9.Facility__c = facility2.id;
                stockMovement9.Class__c = clsObj.id;
                stockMovement9.Item__c = null;
                stockMovement9.Customer__c = null;
                stockMovement9.Source_Document__c = 'Sales Order';
                stockMovement9.Priority__c = 1;
                stockMovement9.Location_List__c = JSON.serialize(new List<Id>{location3.id,location5.id});
                stockMovement9.Active__c = true;
                stockMovementRuleList.add( stockMovement9 ); 
                
                Stock_Movement_Rule__c stockMovement10 = new Stock_Movement_Rule__c();
                stockMovement10.Name = 'Putaway rule10';
                stockMovement10.Rule_Type__c = 'Putaway';
                stockMovement10.Company__c = company.id;
                stockMovement10.Facility__c = facility2.id;
                stockMovement10.Class__c = null;
                stockMovement10.Item__c = null;
                stockMovement10.Customer__c = null;
                stockMovement10.Source_Document__c = 'Receiving Document';
                stockMovement10.Priority__c = 1;
                stockMovement10.Location_List__c = JSON.serialize(new List<Id>{location3.id,location5.id});
                stockMovement10.Active__c = true;
                stockMovementRuleList.add( stockMovement10 ); 
                //stock Movement rule for direct putaway
                Stock_Movement_Rule__c stockMovement11 = new Stock_Movement_Rule__c();
                stockMovement11.Name = 'Transfer Rule for Direct Putaway';
                stockMovement11.Rule_Type__c = 'Putaway';
                stockMovement11.Company__c = company.id;
                stockMovement11.Facility__c = facility2.id;
                stockMovement11.Class__c = null;
                stockMovement11.Item__c = null;
                stockMovement11.Customer__c = null;
                stockMovement11.Source_Document__c = 'Transfer';
                stockMovement11.Priority__c = 2;
                stockMovement11.Location_List__c = JSON.serialize(new List<Id>{location3.id});
                stockMovement11.Active__c = true;
                stockMovementRuleList.add( stockMovement11 ); 
                
                insert stockMovementRuleList;
            }
            return stockMovementRuleList;
        }
        set;
    }
    
    public Means_of_Transport__c meansOfTransport {
        get{
            if(meansOfTransport == null){
                meansOfTransport = newMeansOfTransport('LAND', 'Land');
                insert meansOfTransport;
            }
            return meansOfTransport;
        }
        set;
    }
    
    //public Transit_Route__c transitRoute {
    //  get{
    //      if(transitRoute == null){
    //          transitRoute = new Transit_Route__c();
    //          transitRoute.Destination__c = customerShipTo.Address__c;
    //          transitRoute.Origin__c = facility2.Address__c;
    //          transitRoute.Means_of_Transport__c = meansOfTransport.Id;
    //          transitRoute.Transit_Time__c = 2;
    //          transitRoute.Delivery_Method__c = 'Delivery';
                
    //          insert transitRoute;
    //      }
    //      return transitRoute;
    //  }
    //  set;    
    //}
    
    public List<Period__c> periodList {
        get {
            if (periodList == null) {
                integer year = system.now().year();
                periodList = new List<Period__c>();
                
                //insert current year
                for(integer i=1; i<=12; i++){
                    Period__c iPeriod = new Period__c();
                    //iPeriod.Name = string.valueOf(i) + '-' + string.valueOf(year);
                    //iPeriod.Name = string.valueOf(i) + '-' + String.ValueOf(Math.random());

                    iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
                    iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
                    iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
                    iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
					iPeriod.Name = company.Company_Identifier__c + '_' + iPeriod.Period_Start__c.getTime();
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
                
                
                //insert next year
                year++;
                for(integer i=1; i<=12; i++){
                    Period__c iPeriod = new Period__c();
                    iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
                    iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
                    iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
                    iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
					iPeriod.Name = company.Company_Identifier__c + '_' + iPeriod.Period_Start__c.getTime();
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
            update periodList;
            
            return periodList;
        } 
        set;
    }    
    
    //previous year periods - usually not needed
    public List<Period__c> periodListLastYear {
        get {
            if (periodListLastYear == null) {
                integer year = (system.now().year() - 1);
                periodListLastYear = new List<Period__c>();

                for(integer i=1; i<=12; i++){
                    Period__c iPeriod = new Period__c();
                    iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
                    iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
                    iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
                    iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
                    iPeriod.Period_Number__c = i;
					iPeriod.Name = company.Company_Identifier__c + '_' + iPeriod.Period_Start__c.getTime();
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
                    
                    periodListLastYear.add(iPeriod);
                }
                
                
                Fiscal_Year__c fy = new Fiscal_Year__c();
                fy.company__c = company.Id;
                fy.fiscal_year_start_date__c = periodListLastYear[0].period_start__c;
                fy.fiscal_year_end_date__c = periodListLastYear[periodListLastYear.size()-1].period_end__c.addMonths(3);
                insert fy;
                
                for(Period__c p : periodListLastYear){
                    p.fiscalyear__c = fy.Id;
                }
                insert periodListLastYear;
            }
            
            update periodListLastYear;
            return periodListLastYear; 
        }
        set;
    }  

    public List<Period__c> altCompanyPeriodList {
        get {
            if (altCompanyPeriodList == null) {
                integer year = system.now().year();
                altCompanyPeriodList = new List<Period__c>();
                
                //insert current year
                for(integer i=1; i<=12; i++){
                    Period__c iPeriod = new Period__c();
                    iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
                    iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
                    iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
                    iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
					iPeriod.Name = altCompany.Company_Identifier__c + '_' + iPeriod.Period_Start__c.getTime();
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
                    iPeriod.Company__c = altCompany.Id;
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
                    
                    altCompanyPeriodList.add(iPeriod);
                }
                
                
                //insert next year
                year++;
                for(integer i=1; i<=12; i++){
                    Period__c iPeriod = new Period__c();
                    iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
                    iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
                    iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
                    iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
                    iPeriod.Period_Number__c = i;
					iPeriod.Name = altCompany.Company_Identifier__c + '_' + iPeriod.Period_Start__c.getTime();
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
                    iPeriod.Company__c = altCompany.Id;
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
                    
                    altCompanyPeriodList.add(iPeriod);
                }
                
                Fiscal_Year__c fy = new Fiscal_Year__c();
                fy.company__c = altCompany.Id;
                fy.fiscal_year_start_date__c = altCompanyPeriodList[0].period_start__c;
                fy.fiscal_year_end_date__c = altCompanyPeriodList[altCompanyPeriodList.size()-1].period_end__c.addMonths(3);
                
                insert fy;
                for(Period__c p : altCompanyPeriodList){
                    p.fiscalyear__c = fy.Id;
                }
                
                insert altCompanyPeriodList;
            }
            update altCompanyPeriodList;
            
            return altCompanyPeriodList;
        } 
        set;
    }    
    
    public List<GL_Account__c> GLAccountList {
        get {
            if ( GLAccountList == null ) {
                
                GLAccountList = new List<GL_Account__c>();
                
                GL_Account__c cashGL = mGLAccounts.containsKey('12000') ? mGLAccounts.get('12000'):null ;
                GLAccountList.add(cashGL);
                
                GL_Account__c receivablesGL = mGLAccounts.containsKey('11000') ? mGLAccounts.get('11000'):null;
                GLAccountList.add(receivablesGL);
                
                GL_Account__c revenueGL = mGLAccounts.containsKey('42000') ? mGLAccounts.get('42000'):null;
                GLAccountList.add(revenueGL);
                
                GL_Account__c unappliedCashGL = mGLAccounts.containsKey('12100') ? mGLAccounts.get('12100'):null;
                GLAccountList.add(unappliedCashGL);
                
                GL_Account__c propertyGL = mGLAccounts.containsKey('17000') ? mGLAccounts.get('17000'):null;
                GLAccountList.add(propertyGL); 
                
                GL_Account__c longTermGL = mGLAccounts.containsKey('28000') ? mGLAccounts.get('28000'):null;
                GLAccountList.add(longTermGL);    
                
                GL_Account__c inventoryGL = mGLAccounts.containsKey('12500') ? mGLAccounts.get('12500'):null;
                GLAccountList.add(inventoryGL);
                
                GL_Account__c cogsGL = mGLAccounts.containsKey('50000') ? mGLAccounts.get('50000'):null;
                GLAccountList.add(cogsGL);
                
                GL_Account__c salesReturnsGL = mGLAccounts.containsKey('48000') ? mGLAccounts.get('48000'):null;
                GLAccountList.add(salesReturnsGL);
                
                GL_Account__c taxGL = mGLAccounts.containsKey('24000') ? mGLAccounts.get('24000'):null;
                GLAccountList.add(taxGL);
               
                GL_Account__c wipInventoryGL = mGLAccounts.containsKey('14000') ? mGLAccounts.get('14000'):null;
                GLAccountList.add(wipInventoryGL);
                
                GL_Account__c FGInventoryGL = mGLAccounts.containsKey('15000') ? mGLAccounts.get('15000'):null;
                GLAccountList.add(FGInventoryGL);
                
                GL_Account__c payablesGL = mGLAccounts.containsKey('21000') ? mGLAccounts.get('21000'):null;
                GLAccountList.add(payablesGL);
                
                GL_Account__c accruedExpGL = mGLAccounts.containsKey('22000') ? mGLAccounts.get('22000'):null;
                GLAccountList.add(accruedExpGL);
                
                GL_Account__c overpaymentGL = mGLAccounts.containsKey('24100') ? mGLAccounts.get('24100'):null;
                GLAccountList.add(overpaymentGL);
                
                GL_Account__c GRNIGL = mGLAccounts.containsKey('23000') ? mGLAccounts.get('23000'):null;
                GLAccountList.add(GRNIGL);
                
                GL_Account__c GoodsInTransit = mGLAccounts.containsKey('23100') ? mGLAccounts.get('23100'):null;
                GLAccountList.add(GoodsInTransit);
                
                GL_Account__c salesDiscountGL = mGLAccounts.containsKey('49000') ? mGLAccounts.get('49000'):null;
                GLAccountList.add(salesDiscountGL);
                
                GL_Account__c inventoryScrapGL = mGLAccounts.containsKey('52000') ? mGLAccounts.get('52000'):null;
                GLAccountList.add(inventoryScrapGL);
                
                GL_Account__c allowanceExpGL = mGLAccounts.containsKey('55000') ? mGLAccounts.get('55000'):null;
                GLAccountList.add(allowanceExpGL);
                
                GL_Account__c deductionExpGL = mGLAccounts.containsKey('56000') ? mGLAccounts.get('56000'):null;
                GLAccountList.add(deductionExpGL);
                
                GL_Account__c InventoryAdjustmentGL = mGLAccounts.containsKey('58500') ? mGLAccounts.get('58500'):null;
                GLAccountList.add(InventoryAdjustmentGL);
                
                GL_Account__c PPVGL = mGLAccounts.containsKey('59000') ? mGLAccounts.get('59000'):null;
                GLAccountList.add(PPVGL);
                
                GL_Account__c IPVGL = mGLAccounts.containsKey('59100') ? mGLAccounts.get('59100'):null;
                GLAccountList.add(IPVGL);
                
                GL_Account__c writeoffGL = mGLAccounts.containsKey('61000') ? mGLAccounts.get('61000'):null;
                GLAccountList.add(writeoffGL);
                
                GL_Account__c officeExpGL = mGLAccounts.containsKey('65000') ? mGLAccounts.get('65000'):null;
                GLAccountList.add(officeExpGL);
                
                GL_Account__c miscRcptGL = mGLAccounts.containsKey('23500') ? mGLAccounts.get('23500'):null;
                GLAccountList.add(miscRcptGL);
                
                GL_Account__c miscIssueGL = mGLAccounts.containsKey('51000') ? mGLAccounts.get('51000'):null;
                GLAccountList.add(miscIssueGL);
                
                GL_Account__c miscInvScrapGL = mGLAccounts.containsKey('52100') ? mGLAccounts.get('52100'):null;
                GLAccountList.add(miscInvScrapGL);
                
                GL_Account__c marketingGL = mGLAccounts.containsKey('62000') ? mGLAccounts.get('62000'):null;
                GLAccountList.add(marketingGL);
                
                GL_Account__c cipGL = mGLAccounts.containsKey('15100') ? mGLAccounts.get('15100'):null;
                GLAccountList.add(cipGL);
                
                GL_Account__c rawMaterialGL = mGLAccounts.containsKey('22500') ? mGLAccounts.get('22500'):null;
                GLAccountList.add(rawMaterialGL);
                
                GL_Account__c gain_LossOnSaleofAsset = mGLAccounts.containsKey('79000') ? mGLAccounts.get('79000'):null; 
                GLAccountList.add(gain_LossOnSaleofAsset);
                
                GL_Account__c InterestIncome_Expense =mGLAccounts.containsKey('89020') ?  mGLAccounts.get('89020'):null;
                GLAccountList.add(InterestIncome_Expense);
                
                GL_Account__c RealizedFX = mGLAccounts.containsKey('79500') ?  mGLAccounts.get('79500'):null;
                GLAccountList.add(RealizedFX);
                
                GL_Account__c provisionForFederalTaxes = mGLAccounts.containsKey('99998') ? mGLAccounts.get('99998'):null;
                GLAccountList.add(provisionForFederalTaxes);
                
                GL_Account__c shareCapital = mGLAccounts.containsKey('38000') ? mGLAccounts.get('38000'):null;
                GLAccountList.add(shareCapital);
                
                GL_Account__c retainedEarnings = mGLAccounts.containsKey('39000') ? mGLAccounts.get('39000'):null;
                GLAccountList.add(retainedEarnings);
                
            }
            
            
            return GLAccountList; 
        }
        set;
    }  
       
    
    
    public List<Accounting_Rule__c> BankTxnGrpAcctRulesList {
        get{
            if(BankTxnGrpAcctRulesList == null){
                BankTxnGrpAcctRulesList = new List<Accounting_Rule__c>();
                Accounting_Rule__c BankTxnGrpCRDT1 = new Accounting_Rule__c();
                BankTxnGrpCRDT1.Object_Name__c = 'Bank_Transaction_Group__c';
                //BankTxnGrpCRDT1.company__c = company.id;
                BankTxnGrpCRDT1.Transaction__c = 'Standard';
                BankTxnGrpCRDT1.SubTransaction_Type__c = 'Credit';
                BankTxnGrpCRDT1.Rule_Type__c = 'CR';
                BankTxnGrpCRDT1.Default_GL_Account__c = true;
                BankTxnGrpCRDT1.GL_Account_Reference_Value__c = null;
                BankTxnGrpCRDT1.GL_Account__c = unappliedCashGL.id;
                BankTxnGrpCRDT1.Line_Type__c = null;
                BankTxnGrpCRDT1.Company_Ledger__c = true;
                BankTxnGrpCRDT1.Effective_Start_Date__c= effStartDate;
                BankTxnGrpAcctRulesList.add(BankTxnGrpCRDT1);             

                Accounting_Rule__c BankTxnGrpCRDT2 = new Accounting_Rule__c();
                BankTxnGrpCRDT2.Object_Name__c = 'Bank_Transaction_Group__c';
                //BankTxnGrpCRDT2.company__c = company.id;
                BankTxnGrpCRDT2.Transaction__c = 'Standard';
                BankTxnGrpCRDT2.SubTransaction_Type__c = 'Credit';
                BankTxnGrpCRDT2.Rule_Type__c = 'DR';
                BankTxnGrpCRDT2.Default_GL_Account__c = false;
                BankTxnGrpCRDT2.GL_Account_Reference_Value__c = 'Bank_Account__r.GL_Account__c';
                BankTxnGrpCRDT2.GL_Account__c = null ;
                BankTxnGrpCRDT2.Line_Type__c = null;
                BankTxnGrpCRDT2.Company_Ledger__c = true;
                BankTxnGrpCRDT2.Effective_Start_Date__c= effStartDate;
                BankTxnGrpAcctRulesList.add(BankTxnGrpCRDT2);
                                
                Accounting_Rule__c BankTxnGrpDBT1 = new Accounting_Rule__c();
                BankTxnGrpDBT1.Object_Name__c = 'Bank_Transaction_Group__c';
                //BankTxnGrpDBT1.company__c = company.id;
                BankTxnGrpDBT1.Transaction__c = 'Standard';
                BankTxnGrpDBT1.SubTransaction_Type__c = 'Debit';
                BankTxnGrpDBT1.Rule_Type__c = 'CR';
                BankTxnGrpDBT1.Default_GL_Account__c = false;
                BankTxnGrpDBT1.GL_Account_Reference_Value__c = 'Bank_Account__r.GL_Account__c';
                BankTxnGrpDBT1.GL_Account__c = null;
                BankTxnGrpDBT1.Line_Type__c = null;
                BankTxnGrpDBT1.Company_Ledger__c = true;
                BankTxnGrpDBT1.Effective_Start_Date__c= effStartDate;
                BankTxnGrpAcctRulesList.add(BankTxnGrpDBT1);             

                Accounting_Rule__c BankTxnGrpDBT2 = new Accounting_Rule__c();
                BankTxnGrpDBT2.Object_Name__c = 'Bank_Transaction_Group__c';
                //BankTxnGrpDBT2.company__c = company.id;
                BankTxnGrpDBT2.Transaction__c = 'Standard';
                BankTxnGrpDBT2.SubTransaction_Type__c = 'Debit';
                BankTxnGrpDBT2.Rule_Type__c = 'DR';
                BankTxnGrpDBT2.Default_GL_Account__c = true;
                BankTxnGrpDBT2.GL_Account_Reference_Value__c = null;
                BankTxnGrpDBT2.GL_Account__c = unappliedCashGL.id;
                BankTxnGrpDBT2.Line_Type__c = null;
                BankTxnGrpDBT2.Company_Ledger__c = true;
                BankTxnGrpDBT2.Effective_Start_Date__c= effStartDate;
                BankTxnGrpAcctRulesList.add(BankTxnGrpDBT2);    
                
                for(Accounting_Rule__c ar : BankTxnGrpAcctRulesList){
                	ar.Accounting_Standard__c = accountingStandard.Id;
                }
              insert BankTxnGrpAcctRulesList;
            }
            update BankTxnGrpAcctRulesList;       
            return BankTxnGrpAcctRulesList;
        }
        set;
    }                       
    public List<Accounting_Rule__c> SuppInvAcctRulesList {
        get {
            if (SuppInvAcctRulesList == null) {
                SuppInvAcctRulesList = new List<Accounting_Rule__c>();
                
                Accounting_Rule__c sinvacctRule1 = new Accounting_Rule__c();
                sinvacctRule1.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule1.company__c = company.id;
                sinvacctRule1.Transaction__c = 'Supplier Invoice';
                sinvacctRule1.SubTransaction_Type__c = 'Goods';
                sinvacctRule1.Rule_Type__c = 'DR';
                sinvacctRule1.Default_GL_Account__c = true;
                sinvacctRule1.GL_Account_Reference_Value__c = null;
                sinvacctRule1.GL_Account__c = IPVGL.id;
                sinvacctRule1.Line_Type__c = 'Item';
                sinvacctRule1.Company_Ledger__c = true;
                SuppInvAcctRulesList.add(sinvacctRule1);
                
                Accounting_Rule__c sinvacctRule2 = new Accounting_Rule__c();
                sinvacctRule2.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule2.company__c = company.id;
                sinvacctRule2.Transaction__c = 'Supplier Invoice';
                sinvacctRule2.SubTransaction_Type__c = 'Goods';
                sinvacctRule2.Rule_Type__c = 'CR';
                sinvacctRule2.Default_GL_Account__c = true;
                sinvacctRule2.GL_Account_Reference_Value__c = null;
                sinvacctRule2.GL_Account__c = payablesGL.id;
                sinvacctRule2.Line_Type__c = 'Item';
                sinvacctRule2.Company_Ledger__c = true;
                SuppInvAcctRulesList.add(sinvacctRule2);
                
                Accounting_Rule__c sinvacctRule11 = new Accounting_Rule__c();
                sinvacctRule11.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule11.company__c = company.id;
                sinvacctRule11.Transaction__c = 'Supplier Invoice';
                sinvacctRule11.SubTransaction_Type__c = 'Goods';
                sinvacctRule11.Rule_Type__c = 'DR';
                sinvacctRule11.Default_GL_Account__c = true;
                sinvacctRule11.GL_Account_Reference_Value__c = null;
                sinvacctRule11.GL_Account__c = GRNIGL.id;
                sinvacctRule11.Line_Type__c = 'Item';
                sinvacctRule11.Amount_Reference__c = 'Purchase_Price__c';
                sinvacctRule11.Company_Ledger__c = true;
                SuppInvAcctRulesList.add(sinvacctRule11);
                
                Accounting_Rule__c sinvacctRule22 = new Accounting_Rule__c();
                sinvacctRule22.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule22.company__c = company.id;
                sinvacctRule22.Transaction__c = 'Supplier Invoice';
                sinvacctRule22.SubTransaction_Type__c = 'Goods';
                sinvacctRule22.Rule_Type__c = 'CR';
                sinvacctRule22.Default_GL_Account__c = true;
                sinvacctRule22.GL_Account_Reference_Value__c = null;
                sinvacctRule22.GL_Account__c = IPVGL.id;
                sinvacctRule22.Line_Type__c = 'Item';
                sinvacctRule22.Amount_Reference__c = 'Purchase_Price__c';
                sinvacctRule22.Company_Ledger__c = true;
                SuppInvAcctRulesList.add(sinvacctRule22);
                
                Accounting_Rule__c sinvacctRule91 = new Accounting_Rule__c();
                sinvacctRule91.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule91.company__c = company.id;
                sinvacctRule91.Transaction__c = 'Supplier Invoice';
                sinvacctRule91.SubTransaction_Type__c = 'Goods';
                sinvacctRule91.Rule_Type__c = 'DR';
                sinvacctRule91.Default_GL_Account__c = true;
                sinvacctRule91.GL_Account_Reference_Value__c = null;
                sinvacctRule91.GL_Account__c = IPVGL.id;
                sinvacctRule91.Company_Ledger__c = true;
                SuppInvAcctRulesList.add(sinvacctRule91);
                
                Accounting_Rule__c sinvacctRule92 = new Accounting_Rule__c();
                sinvacctRule92.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule92.company__c = company.id;
                sinvacctRule92.Transaction__c = 'Supplier Invoice';
                sinvacctRule92.SubTransaction_Type__c = 'Goods';
                sinvacctRule92.Rule_Type__c = 'CR';
                sinvacctRule92.Default_GL_Account__c = true;
                sinvacctRule92.GL_Account_Reference_Value__c = null;
                sinvacctRule92.GL_Account__c = payablesGL.id;
                sinvacctRule92.Company_Ledger__c = true;
                SuppInvAcctRulesList.add(sinvacctRule92);
                
                Accounting_Rule__c sinvacctRule911 = new Accounting_Rule__c();
                sinvacctRule911.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule911.company__c = company.id;
                sinvacctRule911.Transaction__c = 'Supplier Invoice';
                sinvacctRule911.SubTransaction_Type__c = 'Goods';
                sinvacctRule911.Rule_Type__c = 'DR';
                sinvacctRule911.Default_GL_Account__c = true;
                sinvacctRule911.GL_Account_Reference_Value__c = null;
                sinvacctRule911.GL_Account__c = GRNIGL.id;
                sinvacctRule911.Amount_Reference__c = 'Purchase_Price__c';
                sinvacctRule911.Company_Ledger__c = true;
                SuppInvAcctRulesList.add(sinvacctRule911);
                
                Accounting_Rule__c sinvacctRule922 = new Accounting_Rule__c();
                sinvacctRule922.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule922.company__c = company.id;
                sinvacctRule922.Transaction__c = 'Supplier Invoice';
                sinvacctRule922.SubTransaction_Type__c = 'Goods';
                sinvacctRule922.Rule_Type__c = 'CR';
                sinvacctRule922.Default_GL_Account__c = true;
                sinvacctRule922.GL_Account_Reference_Value__c = null;
                sinvacctRule922.GL_Account__c = IPVGL.id;
                sinvacctRule922.Amount_Reference__c = 'Purchase_Price__c';
                sinvacctRule922.Company_Ledger__c = true;
                SuppInvAcctRulesList.add(sinvacctRule922);
            
                Accounting_Rule__c sinvacctRule7 = new Accounting_Rule__c();
                sinvacctRule7.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule7.company__c = company.id;
                sinvacctRule7.Transaction__c = 'Supplier Invoice';
                sinvacctRule7.SubTransaction_Type__c = 'Expense';
                //sinvacctRule7.Segment_Name__c = 'GL_Account__c';
                sinvacctRule7.Rule_Type__c = 'CR';
                //sinvacctRule7.Criteria__c = 'Item Class';
                sinvacctRule7.Default_GL_Account__c = false;
                sinvacctRule7.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                sinvacctRule7.GL_Account__c = null;            
                sinvacctRule7.Company_Ledger__c = true;           
                SuppInvAcctRulesList.add(sinvacctRule7);
                
                Accounting_Rule__c sinvacctRule8 = new Accounting_Rule__c();
                sinvacctRule8.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule8.company__c = company.id;
                sinvacctRule8.Transaction__c = 'Supplier Invoice';
                sinvacctRule8.SubTransaction_Type__c = 'Expense';
                //sinvacctRule8.Segment_Name__c = 'GL_Account__c';
                sinvacctRule8.Rule_Type__c = 'DR';
                //sinvacctRule8.Criteria__c = 'Accounting Default';
                sinvacctRule8.Default_GL_Account__c = true;
                sinvacctRule8.GL_Account_Reference_Value__c = null;
                sinvacctRule8.GL_Account__c = GRNIGL.id;            
                sinvacctRule8.Company_Ledger__c = true;           
                SuppInvAcctRulesList.add(sinvacctRule8);
                
                Accounting_Rule__c sinvacctRule9 = new Accounting_Rule__c();
                sinvacctRule9.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule9.company__c = company.id;
                sinvacctRule9.Transaction__c = 'Supplier Invoice';
                sinvacctRule9.SubTransaction_Type__c = 'Miscellaneous';
                //sinvacctRule9.Segment_Name__c = 'GL_Account__c';
                sinvacctRule9.Rule_Type__c = 'CR';
                //sinvacctRule9.Criteria__c = 'Item Class';
                sinvacctRule9.Default_GL_Account__c = false;
                sinvacctRule9.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                sinvacctRule9.GL_Account__c = null;            
                sinvacctRule9.Company_Ledger__c = true;     
                SuppInvAcctRulesList.add(sinvacctRule9);
                
                Accounting_Rule__c sinvacctRule10 = new Accounting_Rule__c();
                sinvacctRule10.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule10.company__c = company.id;
                sinvacctRule10.Transaction__c = 'Supplier Invoice';
                sinvacctRule10.SubTransaction_Type__c = 'Miscellaneous';
                //sinvacctRule10.Segment_Name__c = 'GL_Account__c';
                sinvacctRule10.Rule_Type__c = 'DR';
                //sinvacctRule10.Criteria__c = 'Accounting Default';
                sinvacctRule10.Default_GL_Account__c = true;
                sinvacctRule10.GL_Account_Reference_Value__c = null;
                sinvacctRule10.GL_Account__c = GRNIGL.id;            
                sinvacctRule10.Company_Ledger__c = true;           
                SuppInvAcctRulesList.add(sinvacctRule10);
                    
                Accounting_Rule__c sinvacctRule31 = new Accounting_Rule__c();
                sinvacctRule31.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule31.company__c = company.id;
                sinvacctRule31.Transaction__c = 'Supplier Invoice';
                sinvacctRule31.SubTransaction_Type__c = null;
                sinvacctRule31.Rule_Type__c = 'CR';
                sinvacctRule31.Default_GL_Account__c = false;
                sinvacctRule31.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                sinvacctRule31.GL_Account__c = null;            
                sinvacctRule31.Company_Ledger__c = true;       
                SuppInvAcctRulesList.add(sinvacctRule31);
                
                Accounting_Rule__c sinvacctRule32 = new Accounting_Rule__c();
                sinvacctRule32.Object_Name__c = 'Supplier_Invoice__c';
	            //sinvacctRule32.company__c = company.id;
                sinvacctRule32.Transaction__c = 'Supplier Invoice';
                sinvacctRule32.SubTransaction_Type__c = null;
                sinvacctRule32.Rule_Type__c = 'DR';
                sinvacctRule32.Default_GL_Account__c = true;
                sinvacctRule32.GL_Account_Reference_Value__c = null;
                sinvacctRule32.GL_Account__c = GRNIGL.id;            
                sinvacctRule32.Company_Ledger__c = true;           
                SuppInvAcctRulesList.add(sinvacctRule32);

                //KNDY-12704
                Accounting_Rule__c sinvacctRule711 = new Accounting_Rule__c();
                sinvacctRule711.Object_Name__c = 'Supplier_Invoice__c';
                sinvacctRule711.Transaction__c = 'Supplier Invoice';
                sinvacctRule711.SubTransaction_Type__c = 'Goods - Purchase Order';
                sinvacctRule711.Rule_Type__c = 'CR';
                sinvacctRule711.Default_GL_Account__c = false;
                sinvacctRule711.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                sinvacctRule711.GL_Account__c = null;            
                sinvacctRule711.Company_Ledger__c = true;           
                SuppInvAcctRulesList.add(sinvacctRule711);
                //KNDY-12704
                Accounting_Rule__c sinvacctRule712 = new Accounting_Rule__c();
                sinvacctRule712.Object_Name__c = 'Supplier_Invoice__c';
                sinvacctRule712.Transaction__c = 'Supplier Invoice';
                sinvacctRule712.SubTransaction_Type__c = 'Goods - Purchase Order';
                sinvacctRule712.Rule_Type__c = 'DR';
                sinvacctRule712.Default_GL_Account__c = true;
                sinvacctRule712.GL_Account_Reference_Value__c = null;
                sinvacctRule712.GL_Account__c = rfxGL.id;            
                sinvacctRule712.Company_Ledger__c = true;           
                SuppInvAcctRulesList.add(sinvacctRule712);
                
                Accounting_Rule__c sinvacctRule711A = new Accounting_Rule__c();
                sinvacctRule711A.Object_Name__c = 'Supplier_Invoice__c';
                sinvacctRule711A.Transaction__c = 'Invoice';
                sinvacctRule711A.SubTransaction_Type__c = 'Goods - Purchase Order';
                sinvacctRule711A.Rule_Type__c = 'CR';
                sinvacctRule711A.Default_GL_Account__c = false;
                sinvacctRule711A.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                sinvacctRule711A.GL_Account__c = IPVGL.id;            
                sinvacctRule711A.Company_Ledger__c = true;           
                SuppInvAcctRulesList.add(sinvacctRule711A);
                //KNDY-12704
                Accounting_Rule__c sinvacctRule712A = new Accounting_Rule__c();
                sinvacctRule712A.Object_Name__c = 'Supplier_Invoice__c';
                sinvacctRule712A.Transaction__c = 'Invoice';
                sinvacctRule712A.SubTransaction_Type__c = 'Goods - Purchase Order';
                sinvacctRule712A.Rule_Type__c = 'DR';
                sinvacctRule712A.Default_GL_Account__c = true;
                sinvacctRule712A.GL_Account_Reference_Value__c = null;
                sinvacctRule712A.GL_Account__c = rfxGL.id;            
                sinvacctRule712A.Company_Ledger__c = true;           
                SuppInvAcctRulesList.add(sinvacctRule712A);
                
                 Accounting_Rule__c sinvacctRule1New = new Accounting_Rule__c();
                 sinvacctRule1New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule1New.company__c = company.id;
                 sinvacctRule1New.Transaction__c = 'Invoice';
                 sinvacctRule1New.SubTransaction_Type__c = 'Goods';
                 sinvacctRule1New.Rule_Type__c = 'DR';
                 sinvacctRule1New.Default_GL_Account__c = true;
                 sinvacctRule1New.GL_Account_Reference_Value__c = null;
                 sinvacctRule1New.GL_Account__c = IPVGL.id;
                 sinvacctRule1New.Line_Type__c = 'Item';
                 sinvacctRule1New.Company_Ledger__c = true;
                 SuppInvAcctRulesList.add(sinvacctRule1New);
                 
                 Accounting_Rule__c sinvacctRule2New = new Accounting_Rule__c();
                 sinvacctRule2New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule2New.company__c = company.id;
                 sinvacctRule2New.Transaction__c = 'Invoice';
                 sinvacctRule2New.SubTransaction_Type__c = 'Goods';
                 sinvacctRule2New.Rule_Type__c = 'CR';
                 sinvacctRule2New.Default_GL_Account__c = true;
                 sinvacctRule2New.GL_Account_Reference_Value__c = null;
                 sinvacctRule2New.GL_Account__c = payablesGL.id;
                 sinvacctRule2New.Line_Type__c = 'Item';
                 sinvacctRule2New.Company_Ledger__c = true;
                 SuppInvAcctRulesList.add(sinvacctRule2New);
                 
                 Accounting_Rule__c sinvacctRule11New = new Accounting_Rule__c();
                 sinvacctRule11New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule11New.company__c = company.id;
                 sinvacctRule11New.Transaction__c = 'Invoice';
                 sinvacctRule11New.SubTransaction_Type__c = 'Goods';
                 sinvacctRule11New.Rule_Type__c = 'DR';
                 sinvacctRule11New.Default_GL_Account__c = true;
                 sinvacctRule11New.GL_Account_Reference_Value__c = null;
                 sinvacctRule11New.GL_Account__c = GRNIGL.id;
                 sinvacctRule11New.Line_Type__c = 'Item';
                 sinvacctRule11New.Amount_Reference__c = 'Purchase_Price__c';
                 sinvacctRule11New.Company_Ledger__c = true;
                 SuppInvAcctRulesList.add(sinvacctRule11New);
                 
                 Accounting_Rule__c sinvacctRule22New = new Accounting_Rule__c();
                 sinvacctRule22New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule22New.company__c = company.id;
                 sinvacctRule22New.Transaction__c = 'Invoice';
                 sinvacctRule22New.SubTransaction_Type__c = 'Goods';
                 sinvacctRule22New.Rule_Type__c = 'CR';
                 sinvacctRule22New.Default_GL_Account__c = true;
                 sinvacctRule22New.GL_Account_Reference_Value__c = null;
                 sinvacctRule22New.GL_Account__c = IPVGL.id;
                 sinvacctRule22New.Line_Type__c = 'Item';
                 sinvacctRule22New.Amount_Reference__c = 'Purchase_Price__c';
                 sinvacctRule22New.Company_Ledger__c = true;
                 SuppInvAcctRulesList.add(sinvacctRule22New);
                 
                 Accounting_Rule__c sinvacctRule91New = new Accounting_Rule__c();
                 sinvacctRule91New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule91New.company__c = company.id;
                 sinvacctRule91New.Transaction__c = 'Invoice';
                 sinvacctRule91New.SubTransaction_Type__c = 'Goods';
                 sinvacctRule91New.Rule_Type__c = 'DR';
                 sinvacctRule91New.Default_GL_Account__c = true;
                 sinvacctRule91New.GL_Account_Reference_Value__c = null;
                 sinvacctRule91New.GL_Account__c = IPVGL.id;
                 sinvacctRule91New.Company_Ledger__c = true;
                 SuppInvAcctRulesList.add(sinvacctRule91New);
                 
                 Accounting_Rule__c sinvacctRule92New = new Accounting_Rule__c();
                 sinvacctRule92New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule92New.company__c = company.id;
                 sinvacctRule92New.Transaction__c = 'Invoice';
                 sinvacctRule92New.SubTransaction_Type__c = 'Goods';
                 sinvacctRule92New.Rule_Type__c = 'CR';
                 sinvacctRule92New.Default_GL_Account__c = true;
                 sinvacctRule92New.GL_Account_Reference_Value__c = null;
                 sinvacctRule92New.GL_Account__c = payablesGL.id;
                 sinvacctRule92New.Company_Ledger__c = true;
                 SuppInvAcctRulesList.add(sinvacctRule92New);
                 
                 Accounting_Rule__c sinvacctRule911New = new Accounting_Rule__c();
                 sinvacctRule911New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule911New.company__c = company.id;
                 sinvacctRule911New.Transaction__c = 'Invoice';
                 sinvacctRule911New.SubTransaction_Type__c = 'Goods';
                 sinvacctRule911New.Rule_Type__c = 'DR';
                 sinvacctRule911New.Default_GL_Account__c = true;
                 sinvacctRule911New.GL_Account_Reference_Value__c = null;
                 sinvacctRule911New.GL_Account__c = GRNIGL.id;
                 sinvacctRule911New.Amount_Reference__c = 'Purchase_Price__c';
                 sinvacctRule911New.Company_Ledger__c = true;
                 SuppInvAcctRulesList.add(sinvacctRule911New);
                 
                 Accounting_Rule__c sinvacctRule922New = new Accounting_Rule__c();
                 sinvacctRule922New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule922New.company__c = company.id;
                 sinvacctRule922New.Transaction__c = 'Invoice';
                 sinvacctRule922New.SubTransaction_Type__c = 'Goods';
                 sinvacctRule922New.Rule_Type__c = 'CR';
                 sinvacctRule922New.Default_GL_Account__c = true;
                 sinvacctRule922New.GL_Account_Reference_Value__c = null;
                 sinvacctRule922New.GL_Account__c = IPVGL.id;
                 sinvacctRule922New.Amount_Reference__c = 'Purchase_Price__c';
                 sinvacctRule922New.Company_Ledger__c = true;
                 SuppInvAcctRulesList.add(sinvacctRule922New);
             
                 Accounting_Rule__c sinvacctRule7New = new Accounting_Rule__c();
                 sinvacctRule7New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule7New.company__c = company.id;
                 sinvacctRule7New.Transaction__c = 'Invoice';
                 sinvacctRule7New.SubTransaction_Type__c = 'Expense';
                 //sinvacctRule7New.Segment_Name__c = 'GL_Account__c';
                 sinvacctRule7New.Rule_Type__c = 'CR';
                 //sinvacctRule7New.Criteria__c = 'Item Class';
                 sinvacctRule7New.Default_GL_Account__c = false;
                 sinvacctRule7New.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                 sinvacctRule7New.GL_Account__c = null;            
                 sinvacctRule7New.Company_Ledger__c = true;           
                 SuppInvAcctRulesList.add(sinvacctRule7New);
                 
                 Accounting_Rule__c sinvacctRule8New = new Accounting_Rule__c();
                 sinvacctRule8New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule8New.company__c = company.id;
                 sinvacctRule8New.Transaction__c = 'Invoice';
                 sinvacctRule8New.SubTransaction_Type__c = 'Expense';
                 //sinvacctRule8New.Segment_Name__c = 'GL_Account__c';
                 sinvacctRule8New.Rule_Type__c = 'DR';
                 //sinvacctRule8New.Criteria__c = 'Accounting Default';
                 sinvacctRule8New.Default_GL_Account__c = true;
                 sinvacctRule8New.GL_Account_Reference_Value__c = null;
                 sinvacctRule8New.GL_Account__c = GRNIGL.id;            
                 sinvacctRule8New.Company_Ledger__c = true;           
                 SuppInvAcctRulesList.add(sinvacctRule8New);
                 
                 Accounting_Rule__c sinvacctRule9New = new Accounting_Rule__c();
                 sinvacctRule9New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule9New.company__c = company.id;
                 sinvacctRule9New.Transaction__c = 'Invoice';
                 sinvacctRule9New.SubTransaction_Type__c = 'Miscellaneous';
                 //sinvacctRule9New.Segment_Name__c = 'GL_Account__c';
                 sinvacctRule9New.Rule_Type__c = 'CR';
                 //sinvacctRule9New.Criteria__c = 'Item Class';
                 sinvacctRule9New.Default_GL_Account__c = false;
                 sinvacctRule9New.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                 sinvacctRule9New.GL_Account__c = null;            
                 sinvacctRule9New.Company_Ledger__c = true;     
                 SuppInvAcctRulesList.add(sinvacctRule9New);
                 
                 Accounting_Rule__c sinvacctRule10New = new Accounting_Rule__c();
                 sinvacctRule10New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule10New.company__c = company.id;
                 sinvacctRule10New.Transaction__c = 'Invoice';
                 sinvacctRule10New.SubTransaction_Type__c = 'Miscellaneous';
                 //sinvacctRule10New.Segment_Name__c = 'GL_Account__c';
                 sinvacctRule10New.Rule_Type__c = 'DR';
                 //sinvacctRule10New.Criteria__c = 'Accounting Default';
                 sinvacctRule10New.Default_GL_Account__c = true;
                 sinvacctRule10New.GL_Account_Reference_Value__c = null;
                 sinvacctRule10New.GL_Account__c = GRNIGL.id;            
                 sinvacctRule10New.Company_Ledger__c = true;           
                 SuppInvAcctRulesList.add(sinvacctRule10New);
                     
                 Accounting_Rule__c sinvacctRule31New = new Accounting_Rule__c();
                 sinvacctRule31New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule31New.company__c = company.id;
                 sinvacctRule31New.Transaction__c = 'Invoice';
                 sinvacctRule31New.SubTransaction_Type__c = null;
                 sinvacctRule31New.Rule_Type__c = 'CR';
                 sinvacctRule31New.Default_GL_Account__c = false;
                 sinvacctRule31New.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                 sinvacctRule31New.GL_Account__c = null;            
                 sinvacctRule31New.Company_Ledger__c = true;       
                 SuppInvAcctRulesList.add(sinvacctRule31New);
                 
                 Accounting_Rule__c sinvacctRule32New = new Accounting_Rule__c();
                 sinvacctRule32New.Object_Name__c = 'Supplier_Invoice__c';
 	            //sinvacctRule32New.company__c = company.id;
                 sinvacctRule32New.Transaction__c = 'Invoice';
                 sinvacctRule32New.SubTransaction_Type__c = null;
                 sinvacctRule32New.Rule_Type__c = 'DR';
                 sinvacctRule32New.Default_GL_Account__c = true;
                 sinvacctRule32New.GL_Account_Reference_Value__c = null;
                 sinvacctRule32New.GL_Account__c = GRNIGL.id;            
                 sinvacctRule32New.Company_Ledger__c = true;           
                 SuppInvAcctRulesList.add(sinvacctRule32New);
                //Adding Effectivity to the accounting rules.
                for(Accounting_rule__c rule:SuppInvAcctRulesList)
                {
                    rule.Effective_Start_Date__c= effStartDate;
	            	rule.Accounting_Standard__c = accountingStandard.Id;
                }
                
                insert SuppInvAcctRulesList;
            }
            update SuppInvAcctRulesList;
            
            return SuppInvAcctRulesList;
        } 
        set;
    } 
    
    public List<Accounting_Rule__c> SuppPaymentAcctRulesList {
        get {
            if (SuppPaymentAcctRulesList == null) {
                SuppPaymentAcctRulesList = new List<Accounting_Rule__c>();
                
                Accounting_Rule__c suppayacctRule1 = new Accounting_Rule__c();
                suppayacctRule1.Object_Name__c = 'Supplier_Payment__c';
	            //suppayacctRule1.company__c = company.id;
                suppayacctRule1.Transaction__c = 'Supplier Payment';
                suppayacctRule1.SubTransaction_Type__c = 'Payment';
                //suppayacctRule1.Segment_Name__c = 'GL_Account__c';
                suppayacctRule1.Rule_Type__c = 'DR';
                //suppayacctRule1.Criteria__c = 'Accounting Default';
                suppayacctRule1.Default_GL_Account__c = true;
                suppayacctRule1.GL_Account_Reference_Value__c = null;
                suppayacctRule1.GL_Account__c = payablesGL.id;
                suppayacctRule1.Amount_Reference__c = null;            
                suppayacctRule1.Company_Ledger__c = true;           
                SuppPaymentAcctRulesList.add(suppayacctRule1);
                
                Accounting_Rule__c suppayacctRule2 = new Accounting_Rule__c();
                suppayacctRule2.Object_Name__c = 'Supplier_Payment__c';
	            //suppayacctRule2.company__c = company.id;
                suppayacctRule2.Transaction__c = 'Supplier Payment';
                suppayacctRule2.SubTransaction_Type__c = 'Payment';
                //suppayacctRule2.Segment_Name__c = 'GL_Account__c';
                suppayacctRule2.Rule_Type__c = 'CR';
                //suppayacctRule2.Criteria__c = 'Bank Account';
                suppayacctRule2.Default_GL_Account__c = false;
                suppayacctRule2.GL_Account_Reference_Value__c = 'Supplier_Payment__r.Bank_Account__r.GL_Account__c';
                suppayacctRule2.GL_Account__c = null;
                suppayacctRule2.Amount_Reference__c = null;                
                suppayacctRule2.Company_Ledger__c = true;              
                SuppPaymentAcctRulesList.add(suppayacctRule2);
                
                Accounting_Rule__c suppayacctRule3 = new Accounting_Rule__c();
                suppayacctRule3.Object_Name__c = 'Supplier_Payment__c';
	            //suppayacctRule3.company__c = company.id;
                suppayacctRule3.Transaction__c = 'Supplier Payment';
                suppayacctRule3.SubTransaction_Type__c = 'Earned Terms Discount';
                //suppayacctRule3.Segment_Name__c = 'GL_Account__c';
                suppayacctRule3.Rule_Type__c = 'CR';
                //suppayacctRule3.Criteria__c = 'Accounting Default';
                suppayacctRule3.Default_GL_Account__c = true;
                suppayacctRule3.GL_Account_Reference_Value__c = null;
                suppayacctRule3.GL_Account__c = payablesGL.id;
                suppayacctRule3.Amount_Reference__c = null;                
                suppayacctRule3.Company_Ledger__c = true;                
                SuppPaymentAcctRulesList.add(suppayacctRule3);
                
                Accounting_Rule__c suppayacctRule4 = new Accounting_Rule__c();
                suppayacctRule4.Object_Name__c = 'Supplier_Payment__c';
	            //suppayacctRule4.company__c = company.id;
                suppayacctRule4.Transaction__c = 'Supplier Payment';
                suppayacctRule4.SubTransaction_Type__c = 'Earned Terms Discount';
                //suppayacctRule4.Segment_Name__c = 'GL_Account__c';
                suppayacctRule4.Rule_Type__c = 'DR';
                //suppayacctRule4.Criteria__c = 'Accounting Default';
                suppayacctRule4.Default_GL_Account__c = true;
                suppayacctRule4.GL_Account_Reference_Value__c = null;
                suppayacctRule4.GL_Account__c = payablesGL.id;
                suppayacctRule4.Amount_Reference__c = null;                
                suppayacctRule4.Company_Ledger__c = true;             
                SuppPaymentAcctRulesList.add(suppayacctRule4);
            
                Accounting_Rule__c suppayacctRule5 = new Accounting_Rule__c();
                 suppayacctRule5.Object_Name__c = 'Supplier_Payment__c';
 	            //suppayacctRule1.company__c = company.id;
                 suppayacctRule5.Transaction__c = 'Payment';
                 suppayacctRule5.SubTransaction_Type__c = 'Payment';
                 //suppayacctRule1.Segment_Name__c = 'GL_Account__c';
                 suppayacctRule5.Rule_Type__c = 'DR';
                 //suppayacctRule1.Criteria__c = 'Accounting Default';
                 suppayacctRule5.Default_GL_Account__c = true;
                 suppayacctRule5.GL_Account_Reference_Value__c = null;
                 suppayacctRule5.GL_Account__c = payablesGL.id;
                 suppayacctRule5.Amount_Reference__c = null;            
                 suppayacctRule5.Company_Ledger__c = true;           
                 SuppPaymentAcctRulesList.add(suppayacctRule5);
                 
                 Accounting_Rule__c suppayacctRule6 = new Accounting_Rule__c();
                 suppayacctRule6.Object_Name__c = 'Supplier_Payment__c';
 	            //suppayacctRule2.company__c = company.id;
                 suppayacctRule6.Transaction__c = 'Payment';
                 suppayacctRule6.SubTransaction_Type__c = 'Payment';
                 //suppayacctRule2.Segment_Name__c = 'GL_Account__c';
                 suppayacctRule6.Rule_Type__c = 'CR';
                 //suppayacctRule2.Criteria__c = 'Bank Account';
                 suppayacctRule6.Default_GL_Account__c = false;
                 suppayacctRule6.GL_Account_Reference_Value__c = 'Supplier_Payment__r.Bank_Account__r.GL_Account__c';
                 suppayacctRule6.GL_Account__c = null;
                 suppayacctRule6.Amount_Reference__c = null;                
                 suppayacctRule6.Company_Ledger__c = true;              
                 SuppPaymentAcctRulesList.add(suppayacctRule6);
                 
                 Accounting_Rule__c suppayacctRule7 = new Accounting_Rule__c();
                 suppayacctRule7.Object_Name__c = 'Supplier_Payment__c';
 	            //suppayacctRule3.company__c = company.id;
                 suppayacctRule7.Transaction__c = 'Payment';
                 suppayacctRule7.SubTransaction_Type__c = 'Earned Terms Discount';
                 //suppayacctRule3.Segment_Name__c = 'GL_Account__c';
                 suppayacctRule7.Rule_Type__c = 'CR';
                 //suppayacctRule3.Criteria__c = 'Accounting Default';
                 suppayacctRule7.Default_GL_Account__c = true;
                 suppayacctRule7.GL_Account_Reference_Value__c = null;
                 suppayacctRule7.GL_Account__c = payablesGL.id;
                 suppayacctRule7.Amount_Reference__c = null;                
                 suppayacctRule7.Company_Ledger__c = true;                
                 SuppPaymentAcctRulesList.add(suppayacctRule7);
                 
                 Accounting_Rule__c suppayacctRule8 = new Accounting_Rule__c();
                 suppayacctRule8.Object_Name__c = 'Supplier_Payment__c';
 	            //suppayacctRule4.company__c = company.id;
                 suppayacctRule8.Transaction__c = 'Payment';
                 suppayacctRule8.SubTransaction_Type__c = 'Earned Terms Discount';
                 //suppayacctRule4.Segment_Name__c = 'GL_Account__c';
                 suppayacctRule8.Rule_Type__c = 'DR';
                 //suppayacctRule4.Criteria__c = 'Accounting Default';
                 suppayacctRule8.Default_GL_Account__c = true;
                 suppayacctRule8.GL_Account_Reference_Value__c = null;
                 suppayacctRule8.GL_Account__c = payablesGL.id;
                 suppayacctRule8.Amount_Reference__c = null;                
                 suppayacctRule4.Company_Ledger__c = true;             
                 SuppPaymentAcctRulesList.add(suppayacctRule8);
 
                 
                //Adding Effectivity to the accounting rules.
                for(Accounting_rule__c rule:SuppPaymentAcctRulesList)
                {
                    rule.Effective_Start_Date__c= effStartDate;
	            	rule.Accounting_Standard__c = accountingStandard.Id;
                }            
                insert SuppPaymentAcctRulesList;
            }
            update SuppPaymentAcctRulesList;
            
            return SuppPaymentAcctRulesList;
        } 
        set;
    } 
    
    public List<Accounting_Rule__c> rdAccountingRuleList {
        get {
            if (rdAccountingRuleList == null) {
                rdAccountingRuleList = new List<Accounting_Rule__c>();
                
                Accounting_Rule__c rcptacctRule1 = new Accounting_Rule__c();
                rcptacctRule1.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule1.company__c = company.id;
                rcptacctRule1.Transaction__c = 'Purchase Order Receipt';
                rcptacctRule1.SubTransaction_Type__c = 'Goods';
                rcptacctRule1.Rule_Type__c = 'CR';
                rcptacctRule1.Default_GL_Account__c = true;
                rcptacctRule1.GL_Account__c = GRNIGL.id;
                rcptacctRule1.Amount_Reference__c = 'Purchase_Price__c';  
                rcptacctRule1.Company_Ledger__c = true;
                rdAccountingRuleList.add(rcptacctRule1);
    
                Accounting_Rule__c rcptacctRule2 = new Accounting_Rule__c();
                rcptacctRule2.Object_Name__c = 'Receiving_Document__c';
		        //rcptacctRule2.company__c = company.id;
                //FIN-566 fix -ASN Accounting                        
                rcptacctRule2.Transaction__c = 'Purchase Order Receipt';
                rcptacctRule2.SubTransaction_Type__c = 'Goods';
                rcptacctRule2.Rule_Type__c = 'DR';
                rcptacctRule2.Default_GL_Account__c = true;
                rcptacctRule2.GL_Account_Reference_Value__c = null;
                rcptacctRule2.GL_Account__c = FGInventoryGL.id;
                rcptacctRule2.Amount_Reference__c = null;               
                rcptacctRule2.Company_Ledger__c = true;           
                rdAccountingRuleList.add(rcptacctRule2);
                
                Accounting_Rule__c rcptacctRule10 = new Accounting_Rule__c();
                rcptacctRule10.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule10.company__c = company.id;
                rcptacctRule10.Transaction__c = 'Advanced Shipment Notice';
                rcptacctRule10.SubTransaction_Type__c = 'Goods';
                rcptacctRule10.Rule_Type__c = 'CR';
                rcptacctRule10.Default_GL_Account__c = true;
                rcptacctRule10.GL_Account__c = GRNIGL.id;
                rcptacctRule10.Amount_Reference__c = 'Purchase_Price__c';            
                rcptacctRule10.Company_Ledger__c = true;         
                rdAccountingRuleList.add(rcptacctRule10);
                
                Accounting_Rule__c rcptacctRule20 = new Accounting_Rule__c();
                rcptacctRule20.Object_Name__c = 'Receiving_Document__c';
		        //rcptacctRule20.company__c = company.id;
                rcptacctRule20.Transaction__c = 'Advanced Shipment Notice';
                rcptacctRule20.SubTransaction_Type__c = 'Goods';
                rcptacctRule20.Rule_Type__c = 'DR';
                rcptacctRule20.Default_GL_Account__c = true;
                rcptacctRule20.GL_Account_Reference_Value__c = null;
                rcptacctRule20.GL_Account__c = FGInventoryGL.id;
                rcptacctRule20.Amount_Reference__c = null;               
                rcptacctRule20.Company_Ledger__c = true;              
                rdAccountingRuleList.add(rcptacctRule20);
                
                Accounting_Rule__c rcptacctRule11 = new Accounting_Rule__c();
                rcptacctRule11.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule11.company__c = company.id;
                rcptacctRule11.Transaction__c = 'Purchase Order Receipt';
                rcptacctRule11.SubTransaction_Type__c = 'Goods';
                rcptacctRule11.Rule_Type__c = 'CR';
                rcptacctRule11.Default_GL_Account__c = true;
                rcptacctRule11.GL_Account_Reference_Value__c = null;
                rcptacctRule11.GL_Account__c = PPVGL.id;
                rcptacctRule11.Amount_Reference__c = null;            
                rcptacctRule11.Company_Ledger__c = true;            
                rdAccountingRuleList.add(rcptacctRule11);
                
                Accounting_Rule__c rcptacctRule12 = new Accounting_Rule__c();
                rcptacctRule12.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule12.company__c = company.id;
                rcptacctRule12.Transaction__c = 'Advanced Shipment Notice';
                rcptacctRule12.SubTransaction_Type__c = 'Goods';
                rcptacctRule12.Rule_Type__c = 'CR';
                rcptacctRule12.Default_GL_Account__c = true;
                rcptacctRule12.GL_Account_Reference_Value__c = null;
                rcptacctRule12.GL_Account__c = PPVGL.id;
                rcptacctRule12.Amount_Reference__c = null;            
                rcptacctRule12.Company_Ledger__c = true;          
                rdAccountingRuleList.add(rcptacctRule12);
                
                Accounting_Rule__c rcptacctRule22 = new Accounting_Rule__c();
                rcptacctRule22.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule22.company__c = company.id;
                rcptacctRule22.Transaction__c = 'Purchase Order Receipt';
                rcptacctRule22.SubTransaction_Type__c = 'Goods';
                rcptacctRule22.Rule_Type__c = 'DR';
                rcptacctRule22.Default_GL_Account__c = true;
                rcptacctRule22.GL_Account__c = PPVGL.Id;
                rcptacctRule22.Amount_Reference__c = 'Purchase_Price__c';               
                rcptacctRule22.Company_Ledger__c = true;            
                rdAccountingRuleList.add(rcptacctRule22);
                
                Accounting_Rule__c rcptacctRule23 = new Accounting_Rule__c();
                rcptacctRule23.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule23.company__c = company.id;
                rcptacctRule23.Transaction__c = 'Advanced Shipment Notice';
                rcptacctRule23.SubTransaction_Type__c = 'Goods';
                rcptacctRule23.Rule_Type__c = 'DR';
                rcptacctRule23.Default_GL_Account__c = true;
                rcptacctRule23.GL_Account__c = PPVGL.Id;
                rcptacctRule23.Amount_Reference__c = 'Purchase_Price__c';               
                rcptacctRule23.Company_Ledger__c = true;              
                rdAccountingRuleList.add(rcptacctRule23);
                
                Accounting_Rule__c rcptacctRule3 = new Accounting_Rule__c();
                rcptacctRule3.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule3.company__c = company.id;
                rcptacctRule3.Transaction__c = 'Purchase Order Receipt';
                rcptacctRule3.SubTransaction_Type__c = 'Expense';
                rcptacctRule3.Rule_Type__c = 'CR';
                rcptacctRule3.Default_GL_Account__c = false;
                rcptacctRule3.GL_Account_Reference_Value__c = null;
                rcptacctRule3.GL_Account__c = GRNIGL.id;
                rcptacctRule3.Amount_Reference__c = null;              
                rcptacctRule3.Company_Ledger__c = true;             
                rdAccountingRuleList.add(rcptacctRule3);
                
                Accounting_Rule__c rcptacctRule30 = new Accounting_Rule__c();
                rcptacctRule30.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule30.company__c = company.id;
                rcptacctRule30.Transaction__c = 'Advanced Shipment Notice';
                rcptacctRule30.SubTransaction_Type__c = 'Expense';
                rcptacctRule30.Rule_Type__c = 'CR';
                rcptacctRule30.Default_GL_Account__c = false;
                rcptacctRule30.GL_Account_Reference_Value__c = null;
                rcptacctRule30.GL_Account__c = GRNIGL.id;
                rcptacctRule30.Amount_Reference__c = null;              
                rcptacctRule30.Company_Ledger__c = true;            
                rdAccountingRuleList.add(rcptacctRule30);  
                
                Accounting_Rule__c rcptacctRule4 = new Accounting_Rule__c();
                rcptacctRule4.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule4.company__c = company.id;
                rcptacctRule4.Transaction__c = 'Purchase Order Receipt';
                rcptacctRule4.SubTransaction_Type__c = 'Expense';
                rcptacctRule4.Rule_Type__c = 'DR';
                rcptacctRule4.Default_GL_Account__c = false;
                rcptacctRule4.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                rcptacctRule4.GL_Account__c = null;
                rcptacctRule4.Amount_Reference__c = null;               
                rcptacctRule4.Company_Ledger__c = true;               
                rdAccountingRuleList.add(rcptacctRule4);
                
                Accounting_Rule__c rcptacctRule40 = new Accounting_Rule__c();
                rcptacctRule40.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule40.company__c = company.id;
                rcptacctRule40.Transaction__c = 'Advanced Shipment Notice';
                rcptacctRule40.SubTransaction_Type__c = 'Expense';
                rcptacctRule40.Rule_Type__c = 'DR';
                rcptacctRule40.Default_GL_Account__c = false;
                rcptacctRule40.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                rcptacctRule40.GL_Account__c = null;
                rcptacctRule40.Amount_Reference__c = null;               
                rcptacctRule40.Company_Ledger__c = true;             
                rdAccountingRuleList.add(rcptacctRule40);           
                
                Accounting_Rule__c rcptacctRule5 = new Accounting_Rule__c();
                rcptacctRule5.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule5.company__c = company.id;
                rcptacctRule5.Transaction__c = 'Purchase Order Receipt';
                rcptacctRule5.SubTransaction_Type__c = 'Miscellaneous';
                rcptacctRule5.Rule_Type__c = 'CR';
                rcptacctRule5.Default_GL_Account__c = false;
                rcptacctRule5.GL_Account_Reference_Value__c = null;
                rcptacctRule5.GL_Account__c = GRNIGL.id;
                rcptacctRule5.Amount_Reference__c = null;               
                rcptacctRule5.Company_Ledger__c = true;               
                rdAccountingRuleList.add(rcptacctRule5);
    
                Accounting_Rule__c rcptacctRule50 = new Accounting_Rule__c();
                rcptacctRule50.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule50.company__c = company.id;
                rcptacctRule50.Transaction__c = 'Advanced Shipment Notice';
                rcptacctRule50.SubTransaction_Type__c = 'Miscellaneous';
                rcptacctRule50.Rule_Type__c = 'CR';
                rcptacctRule50.Default_GL_Account__c = false;
                rcptacctRule50.GL_Account_Reference_Value__c = null;
                rcptacctRule50.GL_Account__c = GRNIGL.id;
                rcptacctRule50.Amount_Reference__c = null;               
                rcptacctRule50.Company_Ledger__c = true;               
                rdAccountingRuleList.add(rcptacctRule50);
                
                Accounting_Rule__c rcptacctRule6 = new Accounting_Rule__c();
                rcptacctRule6.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule6.company__c = company.id;
                rcptacctRule6.Transaction__c = 'Purchase Order Receipt';
                rcptacctRule6.SubTransaction_Type__c = 'Miscellaneous';
                rcptacctRule6.Rule_Type__c = 'DR';
                rcptacctRule6.Default_GL_Account__c = false;
                rcptacctRule6.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                rcptacctRule6.GL_Account__c = null;
                rcptacctRule6.Amount_Reference__c = null;               
                rcptacctRule6.Company_Ledger__c = true;               
                rdAccountingRuleList.add(rcptacctRule6);
    
                Accounting_Rule__c rcptacctRule60 = new Accounting_Rule__c();
                rcptacctRule60.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule60.company__c = company.id;
                rcptacctRule60.Transaction__c = 'Advanced Shipment Notice';
                rcptacctRule60.SubTransaction_Type__c = 'Miscellaneous';
                rcptacctRule60.Rule_Type__c = 'DR';
                rcptacctRule60.Default_GL_Account__c = false;
                rcptacctRule60.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                rcptacctRule60.GL_Account__c = null;
                rcptacctRule60.Amount_Reference__c = null;               
                rcptacctRule60.Company_Ledger__c = true;             
                rdAccountingRuleList.add(rcptacctRule60);
                
                Accounting_Rule__c rcptacctRule7 = new Accounting_Rule__c();
                rcptacctRule7.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule7.company__c = company.id;
                rcptacctRule7.Transaction__c = 'Purchase Order Receipt';
                rcptacctRule7.SubTransaction_Type__c = null;
                rcptacctRule7.Rule_Type__c = 'CR';
                rcptacctRule7.Default_GL_Account__c = false;
                rcptacctRule7.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                rcptacctRule7.GL_Account__c = null;
                rcptacctRule7.Amount_Reference__c = null;               
                rcptacctRule7.Company_Ledger__c = true;               
                rdAccountingRuleList.add(rcptacctRule7);
    
                Accounting_Rule__c rcptacctRule70 = new Accounting_Rule__c();
                rcptacctRule70.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule70.company__c = company.id;
                rcptacctRule70.Transaction__c = 'Advanced Shipment Notice';
                rcptacctRule70.SubTransaction_Type__c = null;
                rcptacctRule70.Rule_Type__c = 'CR';
                rcptacctRule70.Default_GL_Account__c = false;
                rcptacctRule70.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                rcptacctRule70.GL_Account__c = null;
                rcptacctRule70.Amount_Reference__c = null;               
                rcptacctRule70.Company_Ledger__c = true;             
                rdAccountingRuleList.add(rcptacctRule70);
                
                Accounting_Rule__c rcptacctRule8 = new Accounting_Rule__c();
                rcptacctRule8.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule8.company__c = company.id;
                rcptacctRule8.Transaction__c = 'Purchase Order Receipt';
                rcptacctRule8.SubTransaction_Type__c = null;
                rcptacctRule8.Rule_Type__c = 'DR';
                rcptacctRule8.Default_GL_Account__c = false;
                rcptacctRule8.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                rcptacctRule8.GL_Account__c = null;
                rcptacctRule8.Amount_Reference__c = null;               
                rcptacctRule8.Company_Ledger__c = true;            
                rdAccountingRuleList.add(rcptacctRule8);
     
                Accounting_Rule__c rcptacctRule80 = new Accounting_Rule__c();
                rcptacctRule80.Object_Name__c = 'Receiving_Document__c';
	            //rcptacctRule80.company__c = company.id;
                rcptacctRule80.Transaction__c = 'Advanced Shipment Notice';
                rcptacctRule80.SubTransaction_Type__c = null;
                rcptacctRule80.Rule_Type__c = 'DR';
                rcptacctRule80.Default_GL_Account__c = false;
                rcptacctRule80.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
                rcptacctRule80.GL_Account__c = null;
                rcptacctRule80.Amount_Reference__c = null;               
                rcptacctRule80.Company_Ledger__c = true;            
                rdAccountingRuleList.add(rcptacctRule80);
    
                //Adding Effectivity to the accounting rules.
                for(Accounting_rule__c rule:rdAccountingRuleList)
                {
                    rule.Effective_Start_Date__c= effStartDate;
	            	rule.Accounting_Standard__c = accountingStandard.Id;
                }                   
                insert rdAccountingRuleList;
            }
            update rdAccountingRuleList;
            
            return rdAccountingRuleList;
        } 
        set;
    } 
     
    
    
    public List<Accounting_Rule__c> ciAccountingRuleList {
        get {
            if (ciAccountingRuleList == null) {
                ciAccountingRuleList = new List<Accounting_Rule__c>();
                
                Accounting_Rule__c custInvCR = new Accounting_Rule__c();
                custInvCR.Object_Name__c = 'Customer_Invoice__c';
                custInvCR.Transaction__c = 'Ship Invoice';
                custInvCR.SubTransaction_Type__c = 'Goods';
                custInvCR.Rule_Type__c = 'CR';
                custInvCR.Default_GL_Account__c = true;
                custInvCR.GL_Account_Reference_Value__c = null;
                custInvCR.GL_Account__c = cashGL.id;
                ciAccountingRuleList.add(custInvCR);
            
                Accounting_Rule__c custInvDR = new Accounting_Rule__c();
                custInvDR.Object_Name__c = 'Customer_Invoice__c';
                custInvDR.Transaction__c = 'Ship Invoice';
                custInvDR.SubTransaction_Type__c = 'Goods';
                custInvDR.Rule_Type__c = 'DR';
                custInvDR.Default_GL_Account__c = true;
                custInvDR.GL_Account_Reference_Value__c = null;
                custInvDR.GL_Account__c = receivablesGL.id;
                ciAccountingRuleList.add(custInvDR);

                Accounting_Rule__c shipInvCR = new Accounting_Rule__c();
                shipInvCR.Object_Name__c = 'Customer_Invoice__c';
                shipInvCR.Transaction__c = 'Ship Invoice';
                shipInvCR.Rule_Type__c = 'CR';
                shipInvCR.Default_GL_Account__c = true;
                shipInvCR.GL_Account_Reference_Value__c = null;
                shipInvCR.GL_Account__c = cashGL.id;
                ciAccountingRuleList.add(shipInvCR);
            
                Accounting_Rule__c shipInvDR = new Accounting_Rule__c();
                shipInvDR.Object_Name__c = 'Customer_Invoice__c';
                shipInvDR.Transaction__c = 'Ship Invoice';
                shipInvDR.Rule_Type__c = 'DR';
                shipInvDR.Default_GL_Account__c = true;
                shipInvDR.GL_Account_Reference_Value__c = null;
                shipInvDR.GL_Account__c = receivablesGL.id;
                ciAccountingRuleList.add(shipInvDR);

                Accounting_Rule__c custInvManualCR = new Accounting_Rule__c();
                custInvManualCR.Object_Name__c = 'Customer_Invoice__c';
                custInvManualCR.Transaction__c = 'Manual';
                custInvManualCR.Rule_Type__c = 'CR';
                custInvManualCR.Default_GL_Account__c = true;
                custInvManualCR.GL_Account_Reference_Value__c = null;
                custInvManualCR.GL_Account__c = receivablesGL.id;
                ciAccountingRuleList.add(custInvManualCR);
            
                Accounting_Rule__c custInvManualDR = new Accounting_Rule__c();
                custInvManualDR.Object_Name__c = 'Customer_Invoice__c';
                custInvManualDR.Transaction__c = 'Manual';
                custInvManualDR.Rule_Type__c = 'DR';
                custInvManualDR.Default_GL_Account__c = true;
                custInvManualDR.GL_Account_Reference_Value__c = null;
                custInvManualDR.GL_Account__c = receivablesGL.id;
                ciAccountingRuleList.add(custInvManualDR);
                
                Accounting_Rule__c custInvManualCR1 = new Accounting_Rule__c();
                custInvManualCR1.Object_Name__c = 'Customer_Invoice__c';
                custInvManualCR1.Transaction__c = 'Manual';
                custInvManualCR1.SubTransaction_Type__c = 'Miscellaneous'; //ttt
                custInvManualCR1.Rule_Type__c = 'CR';
                custInvManualCR1.Default_GL_Account__c = true;
                custInvManualCR1.GL_Account_Reference_Value__c = null;
                custInvManualCR1.GL_Account__c = receivablesGL.id;
                ciAccountingRuleList.add(custInvManualCR1);
            
                Accounting_Rule__c custInvManualDR1 = new Accounting_Rule__c();
                custInvManualDR1.Object_Name__c = 'Customer_Invoice__c';
                custInvManualDR1.Transaction__c = 'Manual';
                custInvManualDR1.SubTransaction_Type__c = 'Miscellaneous';//ttt
                custInvManualDR1.Rule_Type__c = 'DR';
                custInvManualDR1.Default_GL_Account__c = true;
                custInvManualDR1.GL_Account_Reference_Value__c = null;
                custInvManualDR1.GL_Account__c = receivablesGL.id;
                ciAccountingRuleList.add(custInvManualDR1);

                Accounting_Rule__c custInvManualGoodsCR = new Accounting_Rule__c();
                custInvManualGoodsCR.Object_Name__c = 'Customer_Invoice__c';
                custInvManualGoodsCR.Transaction__c = 'Manual';
                custInvManualGoodsCR.SubTransaction_Type__c = 'Goods';
                custInvManualGoodsCR.Rule_Type__c = 'CR';
                custInvManualGoodsCR.Default_GL_Account__c = true;
                custInvManualGoodsCR.GL_Account_Reference_Value__c = null;
                custInvManualGoodsCR.GL_Account__c = cashGL.id;
                ciAccountingRuleList.add(custInvManualGoodsCR);
            
                Accounting_Rule__c custInvManualGoodsDR = new Accounting_Rule__c();
                custInvManualGoodsDR.Object_Name__c = 'Customer_Invoice__c';
                custInvManualGoodsDR.Transaction__c = 'Manual';
                custInvManualGoodsDR.SubTransaction_Type__c = 'Goods';
                custInvManualGoodsDR.Rule_Type__c = 'DR';
                custInvManualGoodsDR.Default_GL_Account__c = true;
                custInvManualGoodsDR.GL_Account_Reference_Value__c = null;
                custInvManualGoodsDR.GL_Account__c = receivablesGL.id;
                ciAccountingRuleList.add(custInvManualGoodsDR);

                Accounting_Rule__c custInvGoodsCR = new Accounting_Rule__c();
                custInvGoodsCR.Object_Name__c = 'Customer_Invoice__c';
                custInvGoodsCR.Transaction__c = 'Customer Invoice';
                custInvGoodsCR.SubTransaction_Type__c = 'Goods';
                custInvGoodsCR.Rule_Type__c = 'CR';
                custInvGoodsCR.Default_GL_Account__c = true;
                custInvGoodsCR.GL_Account_Reference_Value__c = null;
                custInvGoodsCR.GL_Account__c = cashGL.id;
                custInvGoodsCR.Company_Ledger__c = true;       
                ciAccountingRuleList.add(custInvGoodsCR);
            
                Accounting_Rule__c custInvGoodsDR = new Accounting_Rule__c();
                custInvGoodsDR.Object_Name__c = 'Customer_Invoice__c';
                custInvGoodsDR.Transaction__c = 'Customer Invoice';
                custInvGoodsDR.SubTransaction_Type__c = 'Goods';
                custInvGoodsDR.Rule_Type__c = 'DR';
                custInvGoodsDR.Default_GL_Account__c = true;
                custInvGoodsDR.GL_Account_Reference_Value__c = null;
                custInvGoodsDR.GL_Account__c = receivablesGL.id;
                custInvGoodsDR.Company_Ledger__c = true;       
                ciAccountingRuleList.add(custInvGoodsDR);
                
                Accounting_Rule__c custInvTaxCR = new Accounting_Rule__c();
                custInvTaxCR.Object_Name__c = 'Customer_Invoice__c';
                custInvTaxCR.Transaction__c = 'Customer Invoice';
                custInvTaxCR.SubTransaction_Type__c = 'Sales Tax';
                custInvTaxCR.Rule_Type__c = 'CR';
                custInvTaxCR.Default_GL_Account__c = true;
                custInvTaxCR.GL_Account_Reference_Value__c = null;
                custInvTaxCR.GL_Account__c = taxGL.id;
                ciAccountingRuleList.add(custInvTaxCR);
                
                Accounting_Rule__c custInvTaxDR = new Accounting_Rule__c();
                custInvTaxDR.Object_Name__c = 'Customer_Invoice__c';
                custInvTaxDR.Transaction__c = 'Customer Invoice';
                custInvTaxDR.SubTransaction_Type__c = 'Sales Tax';
                custInvTaxDR.Rule_Type__c = 'DR';
                custInvTaxDR.Default_GL_Account__c = true;
                custInvTaxDR.GL_Account_Reference_Value__c = null;
                custInvTaxDR.GL_Account__c = receivablesGL.id;
                ciAccountingRuleList.add(custInvTaxDR);
                
                Accounting_Rule__c custInvMiscCR = new Accounting_Rule__c();
                custInvMiscCR.Object_Name__c = 'Customer_Invoice__c';
                custInvMiscCR.Transaction__c = 'Customer Invoice';
                custInvMiscCR.SubTransaction_Type__c = 'Miscellaneous';
                custInvMiscCR.Rule_Type__c = 'CR';
                custInvMiscCR.Default_GL_Account__c = false;
                custInvMiscCR.GL_Account_Reference_Value__c = 'Product__r.Item__r.class__r.Revenue_GL_Account__c';
                ciAccountingRuleList.add(custInvMiscCR);
                
                Accounting_Rule__c custInvMiscDR = new Accounting_Rule__c();
                custInvMiscDR.Object_Name__c = 'Customer_Invoice__c';
                custInvMiscDR.Transaction__c = 'Customer Invoice';
                custInvMiscDR.SubTransaction_Type__c = 'Miscellaneous';
                custInvMiscDR.Rule_Type__c = 'DR';
                custInvMiscDR.Default_GL_Account__c = true;
                custInvMiscDR.GL_Account_Reference_Value__c = null;
                custInvMiscDR.GL_Account__c = receivablesGL.id;
                ciAccountingRuleList.add(custInvMiscDR);
                
                Accounting_Rule__c custInvOffCR = new Accounting_Rule__c();
                custInvOffCR.Object_Name__c = 'Customer_Invoice__c';
                custInvOffCR.Transaction__c = 'Customer Invoice';
                custInvOffCR.SubTransaction_Type__c = 'Off Invoice';
                custInvOffCR.Rule_Type__c = 'CR';
                custInvOffCR.Default_GL_Account__c = true;
                custInvOffCR.GL_Account_Reference_Value__c = null;
                custInvOffCR.GL_Account__c = allowanceExpGL.id;
                ciAccountingRuleList.add(custInvOffCR);
                
                Accounting_Rule__c custInvOffDR = new Accounting_Rule__c();
                custInvOffDR.Object_Name__c = 'Customer_Invoice__c';
                custInvOffDR.Transaction__c = 'Customer Invoice';
                custInvOffDR.SubTransaction_Type__c = 'Off Invoice';
                custInvOffDR.Rule_Type__c = 'DR';
                custInvOffDR.Default_GL_Account__c = true;
                custInvOffDR.GL_Account_Reference_Value__c = null;
                custInvOffDR.GL_Account__c = receivablesGL.id;
                ciAccountingRuleList.add(custInvOffDR);
                
                Accounting_Rule__c custInvDedCreditCR = new Accounting_Rule__c();
                custInvDedCreditCR.Object_Name__c = 'Customer_Invoice__c';
                custInvDedCreditCR.Transaction__c = 'Adjustment';
                custInvDedCreditCR.Subtransaction_Type__c = 'Goods';
                custInvDedCreditCR.Line_Type__c = 'Deduction Credit';
                custInvDedCreditCR.Rule_Type__c = 'CR';
                custInvDedCreditCR.Default_GL_Account__c = true;
                custInvDedCreditCR.GL_Account_Reference_Value__c = null;
                custInvDedCreditCR.GL_Account__c = cashGL.id;
                ciAccountingRuleList.add(custInvDedCreditCR);
                
                Accounting_Rule__c custInvDedCreditDR = new Accounting_Rule__c();
                custInvDedCreditDR.Object_Name__c = 'Customer_Invoice__c';
                custInvDedCreditDR.Transaction__c = 'Adjustment';
                custInvDedCreditDR.Subtransaction_Type__c = 'Goods';
                custInvDedCreditDR.Line_Type__c = 'Deduction Credit';
                custInvDedCreditDR.Rule_Type__c = 'DR';
                custInvDedCreditDR.Default_GL_Account__c = true;
                custInvDedCreditDR.GL_Account_Reference_Value__c = null;
                custInvDedCreditDR.GL_Account__c = receivablesGL.id;
                ciAccountingRuleList.add(custInvDedCreditDR);
                
                
                Accounting_Rule__c custInvDedCreditCRCI = new Accounting_Rule__c();
		        custInvDedCreditCRCI.Object_Name__c = 'Customer_Invoice__c';
		        custInvDedCreditCRCI.Transaction__c = 'Customer Invoice';
		        custInvDedCreditCRCI.Subtransaction_Type__c = null;
		        custInvDedCreditCRCI.Line_Type__c = null;
		        custInvDedCreditCRCI.Rule_Type__c = 'CR';
		        custInvDedCreditCRCI.Default_GL_Account__c = true;
		        custInvDedCreditCRCI.GL_Account_Reference_Value__c = null;
		        custInvDedCreditCRCI.GL_Account__c = cashGL.id;
		        ciAccountingRuleList.add(custInvDedCreditCRCI);
		        
		        Accounting_Rule__c custInvDedCreditDRCI = new Accounting_Rule__c();
		        custInvDedCreditDRCI.Object_Name__c = 'Customer_Invoice__c';
		        custInvDedCreditDRCI.Transaction__c = 'Customer Invoice';
		        custInvDedCreditDRCI.Subtransaction_Type__c = null;
		        custInvDedCreditDRCI.Line_Type__c = null;
		        custInvDedCreditDRCI.Rule_Type__c = 'DR';
		        custInvDedCreditDRCI.Default_GL_Account__c = true;
		        custInvDedCreditDRCI.GL_Account_Reference_Value__c = null;
		        custInvDedCreditDRCI.GL_Account__c = receivablesGL.id;
		        ciAccountingRuleList.add(custInvDedCreditDRCI);
		        
                //Adding Effectivity to the accounting rules.
                for(Accounting_rule__c rule:ciAccountingRuleList)
                {
                    rule.Effective_Start_Date__c= effStartDate;
	            	rule.Accounting_Standard__c = accountingStandard.Id;
                }                   
                insert ciAccountingRuleList;
            }
            update ciAccountingRuleList;
            
            return ciAccountingRuleList;
        } 
        set;
    } 
    
    public List<Accounting_Rule__c> shipmentRuleList{
        get{
            if(shipmentRuleList == null){
                shipmentRuleList = new List<Accounting_Rule__c>();
                
                Accounting_Rule__c shipacctRule1 = new Accounting_Rule__c();
                shipacctRule1.Object_Name__c = 'Shipment__c';
	            //shipacctRule1.Company__c = company.id;
                shipacctRule1.Transaction__c = 'Shipment';
                shipacctRule1.SubTransaction_Type__c = 'Goods';
                shipacctRule1.Line_Type__c = null;
                shipacctRule1.Rule_Type__c = 'CR';
                shipacctRule1.Default_GL_Account__c = true;
                shipacctRule1.GL_Account_Reference_Value__c = 'Product__r.Item__r.class__r.Inventory_GL_Account__c';
                shipacctRule1.GL_Account__c = FGInventoryGL.id;
                shipacctRule1.Amount_Reference__c = null; 
                shipacctRule1.Company_Ledger__c = true;           
                shipmentRuleList.add(shipacctRule1);
                
                Accounting_Rule__c shipacctRule2 = new Accounting_Rule__c();
                shipacctRule2.Object_Name__c = 'Shipment__c';
	            //shipacctRule2.Company__c = company.id;
                shipacctRule2.Transaction__c = 'Shipment';
                shipacctRule2.SubTransaction_Type__c = 'Goods';
                shipacctRule2.Line_Type__c = null;
                shipacctRule2.Rule_Type__c = 'DR';
                shipacctRule2.Default_GL_Account__c = true;
                shipacctRule2.GL_Account_Reference_Value__c = null;
                shipacctRule2.GL_Account__c = cogsGL.id;
                shipacctRule2.Amount_Reference__c = null; 
                shipacctRule2.Company_Ledger__c = true;              
                shipmentRuleList.add(shipacctRule2);   
                
                
                
             Accounting_Rule__c transferAccCreditDRCI = new Accounting_Rule__c();
		        transferAccCreditDRCI.Object_Name__c = 'Inventory_Change__c';
		        transferAccCreditDRCI.Transaction__c = 'Transfer Order Shipment';
		        transferAccCreditDRCI.Subtransaction_Type__c = 'Transfer Order Shipment';
		        transferAccCreditDRCI.Line_Type__c = null;
		        transferAccCreditDRCI.Rule_Type__c = 'DR';
		        transferAccCreditDRCI.Default_GL_Account__c = true;
		        transferAccCreditDRCI.GL_Account_Reference_Value__c = null;
		        transferAccCreditDRCI.GL_Account__c = receivablesGL.id;
	        shipmentRuleList.add(transferAccCreditDRCI);
	        
	         Accounting_Rule__c transferAccDebitDRCI = new Accounting_Rule__c();
		        transferAccDebitDRCI.Object_Name__c = 'Inventory_Change__c';
		        transferAccDebitDRCI.Transaction__c = 'Transfer Order Shipment';
		        transferAccDebitDRCI.Subtransaction_Type__c = 'Transfer Order Shipment';
		        transferAccDebitDRCI.Line_Type__c = null;
		        transferAccDebitDRCI.Rule_Type__c = 'CR';
		        transferAccDebitDRCI.Default_GL_Account__c = true;
		        transferAccDebitDRCI.GL_Account_Reference_Value__c = null;
		        transferAccDebitDRCI.GL_Account__c = receivablesGL.id;
	        shipmentRuleList.add(transferAccDebitDRCI);
		        

                //Adding Effectivity to the accounting rules.
                for(Accounting_rule__c rule:shipmentRuleList)
                {
                    rule.Effective_Start_Date__c= effStartDate;
	            	rule.Accounting_Standard__c = accountingStandard.Id;
                }                   
            
                insert shipmentRuleList;
            }
            return shipmentRuleList;
        } 
        set;
        
    }   
   //KNDY-10268 - deprecating bank file and bank file line objects 
   /*public List<Accounting_Rule__c> BankFileRulesList {
        get {
            if (BankFileRulesList == null) {
                BankFileRulesList = new List<Accounting_Rule__c>();
                
                Accounting_Rule__c arDebitDR = new Accounting_Rule__c();
                arDebitDR.Object_Name__c = 'Bank_File__c';
	            //arDebitDR.company__c = company.id;
                arDebitDR.Transaction__c = 'Bank File';
                arDebitDR.Subtransaction_Type__c = 'Debit';
                arDebitDR.Line_Type__c = null;
                arDebitDR.Rule_Type__c = 'DR';
                arDebitDR.GL_Account__c = payablesGL.Id;
                arDebitDR.Default_GL_Account__c = true;
                arDebitDR.GL_Account_Reference_Value__c = null;
                BankFileRulesList.add(arDebitDR);
                
                Accounting_Rule__c arDebitCR = new Accounting_Rule__c();
                arDebitCR.Object_Name__c = 'Bank_File__c';
	            //arDebitCR.company__c = company.id;
                arDebitCR.Transaction__c = 'Bank File';
                arDebitCR.Subtransaction_Type__c = 'Debit';
                arDebitCR.Line_Type__c = null;
                arDebitCR.Rule_Type__c = 'CR';
                arDebitCR.GL_Account__c = cashGL.Id;
                arDebitCR.Default_GL_Account__c = true;
                arDebitCR.GL_Account_Reference_Value__c = null;
                BankFileRulesList.add(arDebitCR);
                
                Accounting_Rule__c arCreditDR = new Accounting_Rule__c();
                arCreditDR.Object_Name__c = 'Bank_File__c';
	            //arCreditDR.company__c = company.id;
                arCreditDR.Transaction__c = 'Bank File';
                arCreditDR.Subtransaction_Type__c = 'Credit';
                arCreditDR.Line_Type__c = null;
                arCreditDR.Rule_Type__c = 'DR';
                arCreditDR.GL_Account__c = cashGL.Id;
                arCreditDR.Default_GL_Account__c = true;
                arCreditDR.GL_Account_Reference_Value__c = null;
                BankFileRulesList.add(arCreditDR);
                
                Accounting_Rule__c arCreditCR = new Accounting_Rule__c();
                arCreditCR.Object_Name__c = 'Bank_File__c';
	            //arCreditCR.company__c = company.id;
                arCreditCR.Transaction__c = 'Bank File';
                arCreditCR.Subtransaction_Type__c = 'Credit';
                arCreditCR.Line_Type__c = null;
                arCreditCR.Rule_Type__c = 'CR';
                arCreditCR.GL_Account__c = unappliedCashGL.Id;
                arCreditCR.Default_GL_Account__c = true;
                arCreditCR.GL_Account_Reference_Value__c = null;
                BankFileRulesList.add(arCreditCR);
                
                //Adding Effectivity to the accounting rules.
                for(Accounting_rule__c rule:BankFileRulesList)
                {
                    rule.Effective_Start_Date__c= effStartDate;
	            	rule.Accounting_Standard__c = accountingStandard.Id;
                }                   
                insert BankFileRulesList;
            }
            
            return BankFileRulesList;
        } 
        set;
    }*/
        
    
    public List<Accounting_Rule__c> crAccountingRuleList {
        get {
            if (crAccountingRuleList == null) {
                crAccountingRuleList = new List<Accounting_Rule__c>();
                
                Accounting_Rule__c cracctRule1 = new Accounting_Rule__c();
                cracctRule1.Object_Name__c = 'Customer_Receipt__c';
	            //cracctRule1.company__c = company.id;
                cracctRule1.Transaction__c = 'Customer Receipt';
                cracctRule1.SubTransaction_Type__c = 'Payment';
                cracctRule1.line_type__c = null;
                cracctRule1.Rule_Type__c = 'CR';
                cracctRule1.Default_GL_Account__c = true;
                cracctRule1.GL_Account_Reference_Value__c = null;
                cracctRule1.GL_Account__c = receivablesGL.id;
                cracctRule1.Amount_Reference__c = null;  
                cracctRule1.Company_Ledger__c = true;                 
                crAccountingRuleList.add(cracctRule1);
                
                Accounting_Rule__c cracctRule2 = new Accounting_Rule__c();
                cracctRule2.Object_Name__c = 'Customer_Receipt__c';
	            //cracctRule2.company__c = company.id;
                cracctRule2.Transaction__c = 'Customer Receipt';
                cracctRule2.SubTransaction_Type__c = 'Payment';
                cracctRule2.line_type__c = null;
                cracctRule2.Rule_Type__c = 'DR';
                cracctRule2.Default_GL_Account__c = true;
                cracctRule2.GL_Account_Reference_Value__c = null;
                cracctRule2.GL_Account__c = cashGL.Id;
                cracctRule2.Amount_Reference__c = null;  
                cracctRule2.Company_Ledger__c = true;                     
                crAccountingRuleList.add(cracctRule2);
                
                Accounting_Rule__c cracctRule13 = new Accounting_Rule__c();
                cracctRule13.Object_Name__c = 'Customer_Receipt__c';
                cracctRule13.company__c = company.id;
                cracctRule13.Transaction__c = 'Customer Receipt';
                cracctRule13.SubTransaction_Type__c = 'Credit Memo';
                //cracctRule13.Segment_Name__c = 'GL_Account__c';
                cracctRule13.Rule_Type__c = 'CR';
                //cracctRule13.Criteria__c = null;
                cracctRule13.Default_GL_Account__c = true;
                cracctRule13.GL_Account_Reference_Value__c = null;
                cracctRule13.GL_Account__c = cashGL.id;
                cracctRule13.Amount_Reference__c = null;                
                crAccountingRuleList.add(cracctRule13);
                
                Accounting_Rule__c cracctRule14 = new Accounting_Rule__c();
                cracctRule14.Object_Name__c = 'Customer_Receipt__c';
	            //cracctRule14.company__c = company.id;
                cracctRule14.Transaction__c = 'Customer Receipt';
                cracctRule14.SubTransaction_Type__c = 'Credit Memo';
                //cracctRule14.Segment_Name__c = 'GL_Account__c';
                cracctRule14.Rule_Type__c = 'DR';
                //cracctRule14.Criteria__c = null;
                cracctRule14.Default_GL_Account__c = true;
                cracctRule14.GL_Account_Reference_Value__c = null;
                cracctRule14.GL_Account__c = receivablesGL.id;
                cracctRule14.Amount_Reference__c = null;                
                crAccountingRuleList.add(cracctRule14);

                 Accounting_Rule__c cracctRule15 = new Accounting_Rule__c();
                 cracctRule15.Object_Name__c = 'Customer_Receipt__c';
 	            //cracctRule1.company__c = company.id;
                 cracctRule15.Transaction__c = 'Receipt';
                 cracctRule15.SubTransaction_Type__c = 'Payment';
                 cracctRule15.line_type__c = null;
                 cracctRule15.Rule_Type__c = 'CR';
                 cracctRule15.Default_GL_Account__c = true;
                 cracctRule15.GL_Account_Reference_Value__c = null;
                 cracctRule15.GL_Account__c = receivablesGL.id;
                 cracctRule15.Amount_Reference__c = null;  
                 cracctRule15.Company_Ledger__c = true;                 
                 crAccountingRuleList.add(cracctRule15);
                 
                 Accounting_Rule__c cracctRule21 = new Accounting_Rule__c();
                 cracctRule21.Object_Name__c = 'Customer_Receipt__c';
 	            //cracctRule2.company__c = company.id;
                 cracctRule21.Transaction__c = 'Receipt';
                 cracctRule21.SubTransaction_Type__c = 'Payment';
                 cracctRule21.line_type__c = null;
                 cracctRule21.Rule_Type__c = 'DR';
                 cracctRule21.Default_GL_Account__c = true;
                 cracctRule21.GL_Account_Reference_Value__c = null;
                 cracctRule2.GL_Account__c = cashGL.Id;
                 cracctRule21.Amount_Reference__c = null;  
                 cracctRule21.Company_Ledger__c = true;                     
                 crAccountingRuleList.add(cracctRule21);
                 
                 Accounting_Rule__c cracctRule16 = new Accounting_Rule__c();
                 cracctRule16.Object_Name__c = 'Customer_Receipt__c';
                 cracctRule16.company__c = company.id;
                 cracctRule16.Transaction__c = 'Receipt';
                 cracctRule16.SubTransaction_Type__c = 'Credit Memo';
                 //cracctRule13.Segment_Name__c = 'GL_Account__c';
                 cracctRule16.Rule_Type__c = 'CR';
                 //cracctRule13.Criteria__c = null;
                 cracctRule16.Default_GL_Account__c = true;
                 cracctRule16.GL_Account_Reference_Value__c = null;
                 cracctRule16.GL_Account__c = cashGL.id;
                 cracctRule16.Amount_Reference__c = null;                
                 crAccountingRuleList.add(cracctRule16);
                 
                 Accounting_Rule__c cracctRule17 = new Accounting_Rule__c();
                 cracctRule17.Object_Name__c = 'Customer_Receipt__c';
 	            //cracctRule14.company__c = company.id;
                 cracctRule17.Transaction__c = 'Receipt';
                 cracctRule17.SubTransaction_Type__c = 'Credit Memo';
                 //cracctRule14.Segment_Name__c = 'GL_Account__c';
                 cracctRule17.Rule_Type__c = 'DR';
                 //cracctRule14.Criteria__c = null;
                 cracctRule17.Default_GL_Account__c = true;
                 cracctRule17.GL_Account_Reference_Value__c = null;
                 cracctRule17.GL_Account__c = receivablesGL.id;
                 cracctRule17.Amount_Reference__c = null;                
                 crAccountingRuleList.add(cracctRule17);
 
 
                //Adding Effectivity to the accounting rules.
                for(Accounting_rule__c rule:crAccountingRuleList)
                {
                    rule.Effective_Start_Date__c= effStartDate;
	            	rule.Accounting_Standard__c = accountingStandard.Id;
                }                   
                insert crAccountingRuleList;
            }
            
            return crAccountingRuleList;
        } 
        set;
    } 
    
    public List<Accounting_Rule__c> FixedAssetAcctRulesList {
        get {
            if (FixedAssetAcctRulesList == null) {
                FixedAssetAcctRulesList = new List<Accounting_Rule__c>();
                
                Accounting_Rule__c arStdCR = new Accounting_Rule__c();
                arStdCR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
	            //arStdCR.company__c = company.id;
                arStdCR.transaction__c = 'Fixed Asset Depreciation';
                arStdCR.subtransaction_type__c = 'Standard';
                arStdCR.line_type__c = null;
                arStdCR.Rule_Type__c = 'CR';
                arStdCR.Default_GL_Account__c = false;
                arStdCR.GL_Account_reference_value__c = 'Fixed_Asset__r.GL_Account__c';
                arStdCR.GL_Account__c = null;
                arStdCR.Company_Ledger__c = true;
                FixedAssetAcctRulesList.add(arStdCR);
                
                Accounting_Rule__c arStdDR = new Accounting_Rule__c();
                arStdDR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
	            //arStdDR.company__c = company.id;
                arStdDR.transaction__c = 'Fixed Asset Depreciation';
                arStdDR.subtransaction_type__c = 'Standard';
                arStdDR.line_type__c = null;
                arStdDR.Rule_Type__c = 'DR';
                arStdDR.Default_GL_Account__c = true;
                arStdDR.GL_Account_reference_value__c = null;
                arStdDR.gl_account__c = expenseGL.Id;
                arStdDR.Company_Ledger__c = true;
                FixedAssetAcctRulesList.add(arStdDR);
                
                Accounting_Rule__c arDepCR = new Accounting_Rule__c();
                arDepCR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
	            //arDepCR.company__c = company.id;
                arDepCR.transaction__c = 'Fixed Asset Depreciation';
                arDepCR.subtransaction_type__c = 'Depreciation';
                arDepCR.line_type__c = null;
                arDepCR.Rule_Type__c = 'CR';
                arDepCR.Default_GL_Account__c = false;
                arDepCR.GL_Account_reference_value__c = 'Fixed_Asset__r.GL_Account__c';
                arDepCR.GL_Account__c = null;
                arDepCR.Company_Ledger__c = true;
                FixedAssetAcctRulesList.add(arDepCR);
                
                Accounting_Rule__c arDepDR = new Accounting_Rule__c();
                arDepDR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
	            //arDepDR.company__c = company.id;
                arDepDR.transaction__c = 'Fixed Asset Depreciation';
                arDepDR.subtransaction_type__c = 'Depreciation';
                arDepDR.line_type__c = null;
                arDepDR.Rule_Type__c = 'DR';
                arDepDR.Default_GL_Account__c = true;
                arDepDR.GL_Account_reference_value__c = null;
                arDepDR.gl_account__c = expenseGL.Id;
                arDepDR.Company_Ledger__c = true;
                FixedAssetAcctRulesList.add(arDepDR);
                
                Accounting_Rule__c arCIPCR = new Accounting_Rule__c();
                arCIPCR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
	            //arCIPCR.company__c = company.id;
                arCIPCR.transaction__c = 'Fixed Asset Depreciation';
                arCIPCR.subtransaction_type__c = 'Capitalize';
                arCIPCR.Line_Type__c = null;
                arCIPCR.Rule_Type__c = 'CR';
                arCIPCR.GL_Account_reference_value__c = 'Fixed_Asset__r.GL_Account__c';
                arCIPCR.GL_Account__c = null;
                arCIPCR.Company_Ledger__c = true;
                FixedAssetAcctRulesList.add(arCIPCR);
                
                Accounting_Rule__c arCIPDR = new Accounting_Rule__c();
                arCIPDR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
                arCIPDR.company__c = company.id;
                arCIPDR.transaction__c = 'Fixed Asset Depreciation';
                arCIPDR.subtransaction_type__c = 'Capitalize';
                arCIPDR.Rule_Type__c = 'DR';
                arCIPDR.Default_Gl_Account__c = true;
                arCIPDR.GL_Account_Reference_Value__c = null;
                arCIPDR.GL_Account__c = FGInventoryGL.Id;
                arCIPDR.Company_Ledger__c = true;
                FixedAssetAcctRulesList.add(arCIPDR);
                
                Accounting_Rule__c arWOCR = new Accounting_Rule__c();
                arWOCR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
	            //arWOCR.company__c = company.id;
                arWOCR.transaction__c = 'Fixed Asset Depreciation';
                arWOCR.subtransaction_type__c = 'Write Off';
                arWOCR.Line_Type__c = null;
                arWOCR.Rule_Type__c = 'CR';
                arWOCR.Default_GL_Account__c = false;
                arWOCR.GL_Account_reference_value__c = 'Fixed_Asset__r.GL_Account__c';
                arWOCR.GL_Account__c = null;
                arWOCR.Company_Ledger__c = true;
                FixedAssetAcctRulesList.add(arWOCR);
                
                Accounting_Rule__c arWODR = new Accounting_Rule__c();
                arWODR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
	            //arWODR.company__c = company.id;
                arWODR.transaction__c = 'Fixed Asset Depreciation';
                arWODR.subtransaction_type__c = 'Write Off';
                arWODR.Line_Type__c = null;
                arWODR.Rule_Type__c = 'DR';
                arWODR.Default_GL_Account__c = true;
                arWODR.GL_Account_Reference_Value__c = null;
                arWODR.gl_account__c = expenseGL.Id;
                arWODR.Company_Ledger__c = true;
                FixedAssetAcctRulesList.add(arWODR);
                
                Accounting_Rule__c arAdjCR = new Accounting_Rule__c();
                arAdjCR.Object_Name__c = 'Fixed_Asset_Adjustment__c';
	            //arAdjCR.company__c = company.id;
                arAdjCR.transaction__c = 'Fixed Asset Adjustment';
                arAdjCR.subtransaction_type__c = 'Upgrade';
                arAdjCR.Line_Type__c = null;
                arAdjCR.Rule_Type__c = 'CR';
                arAdjCR.Default_GL_Account__c = false;
                arAdjCR.GL_Account_reference_value__c = 'Fixed_Asset__r.GL_Account__c';
                arAdjCR.GL_Account__c = null;
                arAdjCR.Company_Ledger__c = true;
                FixedAssetAcctRulesList.add(arAdjCR);
                
                Accounting_Rule__c arAdjDR = new Accounting_Rule__c();
                arAdjDR.Object_Name__c = 'Fixed_Asset_Adjustment__c';
	            //arAdjDR.company__c = company.id;
                arAdjDR.transaction__c = 'Fixed Asset Adjustment';
                arAdjDR.subtransaction_type__c = 'Upgrade';
                arAdjDR.Line_Type__c = null;
                arAdjDR.Rule_Type__c = 'DR';
                arAdjDR.Default_GL_Account__c = true;
                arAdjDR.GL_Account_Reference_Value__c = null;
                arAdjDR.GL_Account__c = expenseGL.Id;
                arAdjDR.Company_Ledger__c = true;
                FixedAssetAcctRulesList.add(arAdjDR);
            
                //Adding Effectivity to the accounting rules.
                for(Accounting_rule__c rule:FixedAssetAcctRulesList)
                {
                    rule.Effective_Start_Date__c= effStartDate;
	            	rule.Accounting_Standard__c = accountingStandard.Id;
                }               
                insert FixedAssetAcctRulesList;
            }
            
            return FixedAssetAcctRulesList;
        } 
        set;
    }   
    
    public List<Accounting_Rule__c> AccountingRuleList {
        get {
            if (AccountingRuleList == null) {
                AccountingRuleList = new List<Accounting_Rule__c>();
                Accounting_Rule__c jeRule1 = new Accounting_Rule__c();
                jeRule1.Object_Name__c = 'Journal_Entry__c';
	            //jeRule1.Company__c = company.id;
                jeRule1.Transaction__c = 'Manual';
                jeRule1.SubTransaction_Type__c = 'Write Off';
                jeRule1.Line_Type__c = null;
                jeRule1.Rule_Type__c = 'CR';
                jeRule1.Default_GL_Account__c = false;
                jeRule1.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule1.GL_Account__c = null;
                jeRule1.Amount_Reference__c = null; 
                jeRule1.Company_Ledger__c = true;           
                AccountingRuleList.add(jeRule1);
                
                Accounting_Rule__c jeRule2 = new Accounting_Rule__c();
                jeRule2.Object_Name__c = 'Journal_Entry__c';
	            //jeRule2.Company__c = company.id;
                jeRule2.Transaction__c = 'Manual';
                jeRule2.SubTransaction_Type__c = 'Write Off';
                jeRule2.Line_Type__c = null;
                jeRule2.Rule_Type__c = 'DR';
                jeRule2.Default_GL_Account__c = false;
                jeRule2.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule2.GL_Account__c = null;
                jeRule2.Amount_Reference__c = null; 
                jeRule2.Company_Ledger__c = true;               
                AccountingRuleList.add(jeRule2); 
                
                Accounting_Rule__c jeRule3 = new Accounting_Rule__c();
                jeRule3.Object_Name__c = 'Journal_Entry__c';
	            //jeRule3.Company__c = company.id;
                jeRule3.Transaction__c = 'Accrual - Manual';
                jeRule3.Line_Type__c = null;
                jeRule3.Rule_Type__c = 'CR';
                jeRule3.Default_GL_Account__c = false;
                jeRule3.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule3.GL_Account__c = null;
                jeRule3.Amount_Reference__c = null; 
                jeRule3.Company_Ledger__c = true;           
                AccountingRuleList.add(jeRule3);
                
                Accounting_Rule__c jeRule4 = new Accounting_Rule__c();
                jeRule4.Object_Name__c = 'Journal_Entry__c';
	            //jeRule4.Company__c = company.id;
                jeRule4.Transaction__c = 'Accrual - Manual';
                jeRule4.Line_Type__c = null;
                jeRule4.Rule_Type__c = 'DR';
                jeRule4.Default_GL_Account__c = false;
                jeRule4.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule4.GL_Account__c = null;
                jeRule4.Amount_Reference__c = null; 
                jeRule4.Company_Ledger__c = true;               
                AccountingRuleList.add(jeRule4);
                
                Accounting_Rule__c jeRule5 = new Accounting_Rule__c();
                jeRule5.Object_Name__c = 'Journal_Entry__c';
	            //jeRule5.Company__c = company.id;
                jeRule5.Transaction__c = 'Recurring Journal';
                jeRule5.Line_Type__c = null;
                jeRule5.Rule_Type__c = 'CR';
                jeRule5.Default_GL_Account__c = false;
                jeRule5.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule5.GL_Account__c = null;
                jeRule5.Amount_Reference__c = null; 
                jeRule5.Company_Ledger__c = true;           
                AccountingRuleList.add(jeRule5);
                
                Accounting_Rule__c jeRule6 = new Accounting_Rule__c();
                jeRule6.Object_Name__c = 'Journal_Entry__c';
	            //jeRule6.Company__c = company.id;
                jeRule6.Transaction__c = 'Recurring Journal';
                jeRule6.Line_Type__c = null;
                jeRule6.Rule_Type__c = 'DR';
                jeRule6.Default_GL_Account__c = false;
                jeRule6.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule6.GL_Account__c = null;
                jeRule6.Amount_Reference__c = null; 
                jeRule6.Company_Ledger__c = true;               
                AccountingRuleList.add(jeRule6);
                
                
                Accounting_Rule__c jeRule7 = new Accounting_Rule__c();
                jeRule7.Object_Name__c = 'Journal_Entry__c';
	            //jeRule7.Company__c = company.id;
                jeRule7.Transaction__c = 'Manual';
                jeRule7.SubTransaction_Type__c = null;
                jeRule7.Line_Type__c = null;
                jeRule7.Rule_Type__c = 'CR';
                jeRule7.Default_GL_Account__c = false;
                jeRule7.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule7.GL_Account__c = null;
                jeRule7.Amount_Reference__c = null; 
                jeRule7.Company_Ledger__c = true;           
                AccountingRuleList.add(jeRule7);
                
                Accounting_Rule__c jeRule8 = new Accounting_Rule__c();
                jeRule8.Object_Name__c = 'Journal_Entry__c';
	            //jeRule8.Company__c = company.id;
                jeRule8.Transaction__c = 'Manual';
                jeRule8.SubTransaction_Type__c = null;
                jeRule8.Line_Type__c = null;
                jeRule8.Rule_Type__c = 'DR';
                jeRule8.Default_GL_Account__c = false;
                jeRule8.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule8.GL_Account__c = null;
                jeRule8.Amount_Reference__c = null; 
                jeRule8.Company_Ledger__c = true;           
                AccountingRuleList.add(jeRule8); 
                
                Accounting_Rule__c jeRule9 = new Accounting_Rule__c();
                jeRule9.Object_Name__c = 'Journal_Entry__c';
	            //jeRule7.Company__c = company.id;
                jeRule9.Transaction__c = 'Year End Adjustment';
                jeRule9.SubTransaction_Type__c = null;
                jeRule9.Line_Type__c = null;
                jeRule9.Rule_Type__c = 'CR';
                jeRule9.Default_GL_Account__c = false;
                jeRule9.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule9.GL_Account__c = null;
                jeRule9.Amount_Reference__c = null; 
                jeRule9.Company_Ledger__c = true;           
                AccountingRuleList.add(jeRule9);
                
                Accounting_Rule__c jeRule10 = new Accounting_Rule__c();
                jeRule10.Object_Name__c = 'Journal_Entry__c';
	            //jeRule8.Company__c = company.id;
                jeRule10.Transaction__c = 'Year End Adjustment';
                jeRule10.SubTransaction_Type__c = null;
                jeRule10.Line_Type__c = null;
                jeRule10.Rule_Type__c = 'DR';
                jeRule10.Default_GL_Account__c = false;
                jeRule10.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule10.GL_Account__c = null;
                jeRule10.Amount_Reference__c = null; 
                jeRule10.Company_Ledger__c = true;           
                AccountingRuleList.add(jeRule10); 
                
                //KNDY-16543
                Accounting_Rule__c jeRule11 = new Accounting_Rule__c();
                jeRule11.Object_Name__c = 'Journal_Entry__c';
	            //jeRule7.Company__c = company.id;
                jeRule11.Transaction__c = 'Bank Transaction';
                jeRule11.SubTransaction_Type__c = 'Bank Adjustment';
                jeRule11.Line_Type__c = null;
                jeRule11.Rule_Type__c = 'CR';
                jeRule11.Default_GL_Account__c = true;
                jeRule11.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule11.GL_Account__c = null;
                jeRule11.Amount_Reference__c = null; 
                jeRule11.Company_Ledger__c = true;  
                jeRule11.Effective_Start_Date__c = system.now().addYears(-1);         
                AccountingRuleList.add(jeRule11);
                
                Accounting_Rule__c jeRule12 = new Accounting_Rule__c();
                jeRule12.Object_Name__c = 'Journal_Entry__c';
	            //jeRule8.Company__c = company.id;
                jeRule12.Transaction__c = 'Bank Transaction';
                jeRule12.SubTransaction_Type__c = 'Bank Adjustment';
                jeRule12.Line_Type__c = null;
                jeRule12.Rule_Type__c = 'DR';
                jeRule12.Default_GL_Account__c = false;
                jeRule12.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule12.GL_Account__c = null;
                jeRule12.Amount_Reference__c = null; 
                jeRule12.Company_Ledger__c = true;    
                jeRule12.Effective_Start_Date__c = system.now().addYears(-1);             
                AccountingRuleList.add(jeRule12); 
                
                Accounting_Rule__c jeRule13 = new Accounting_Rule__c();
                jeRule13.Object_Name__c = 'Journal_Entry__c';
	            //jeRule7.Company__c = company.id;
                jeRule13.Transaction__c = 'Bank Transaction';
                jeRule13.SubTransaction_Type__c = 'Bank Interest Income';
                jeRule13.Line_Type__c = null;
                jeRule13.Rule_Type__c = 'CR';
                jeRule13.Default_GL_Account__c = true;
                jeRule13.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule13.GL_Account__c = null;
                jeRule13.Amount_Reference__c = null; 
                jeRule13.Company_Ledger__c = true;  
                jeRule13.Effective_Start_Date__c = system.now();         
                AccountingRuleList.add(jeRule13);
                
                Accounting_Rule__c jeRule14 = new Accounting_Rule__c();
                jeRule14.Object_Name__c = 'Journal_Entry__c';
	            //jeRule8.Company__c = company.id;
                jeRule14.Transaction__c = 'Bank Transaction';
                jeRule14.SubTransaction_Type__c = 'Bank Interest Income';
                jeRule14.Line_Type__c = null;
                jeRule14.Rule_Type__c = 'DR';
                jeRule14.Default_GL_Account__c = false;
                jeRule14.GL_Account_Reference_Value__c = 'GL_Account__c';
                jeRule14.GL_Account__c = null;
                jeRule14.Amount_Reference__c = null; 
                jeRule14.Company_Ledger__c = true;    
                jeRule14.Effective_Start_Date__c = system.now();             
                AccountingRuleList.add(jeRule14); 
                
                //Adding Effectivity to the accounting rules.
                for(Accounting_rule__c rule:AccountingRuleList)
                {
                    rule.Effective_Start_Date__c= effStartDate;
	            	rule.Accounting_Standard__c = accountingStandard.Id;
		            rule.Raise_Exceptions_for_Blank_Amounts__c=false;
		            rule.Suppress_Zero_Amount_Lines__c = true;                
                }                   
                insert AccountingRuleList;
            }
            update AccountingRuleList;
            
            return AccountingRuleList;
        } 
        set;
    }    
    
    public TestFuel() {}
    
    public Means_of_Transport__c newMeansOfTransport(String code, String modeOfTransport) {
        Means_of_Transport__c mot = new Means_of_Transport__c();
        mot.Code__c = code;
        mot.Mode_of_Transport__c = modeOfTransport;
        // Set max to a high value to avoid exceptions in other test cases
        mot.Maximum_Cube__c = 1000000;
        mot.Maximum_Weight__c = 1000000;
        return mot;
    }
    
    /* utility functions while creating data */
    public String periodName(Datetime myDT){
        String myDate = myDT.format('MM-yyyy');
        system.assert( myDate != null, 'expected valid date');
        return myDate.toUpperCase();
    }
        
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
    
    public Customer__c newCustomerShipTo() {
        Customer__c cst = new Customer__c(); 
        cst.name = 'Customer Ship To 1';
        cst.recordTypeId = this.CustomerRecordTypes.get('Ship_To');
        cst.Company__c = this.company.id;
        cst.Payment_Term__c = this.terms.ID;
        cst.Currency__c = TestFuel.currencyUSD.ID;
        //cst.Address__c = this.account.ID;
        cst.Credit_Limit__c = 100000.0;
        cst.Parent_Customer__c = this.customerSoldTo.id;
        cst.Customer_Identifier__c = 'SHTEST123'; 
        cst.Top_Parent_Customer__c = this.customerParent.id;
        cst.Status__c = 'Approved';
        cst.Business_Hours__c = [select Id from BusinessHours where isDefault = true limit 1].Id;

        cst.Customer_Street__c = '303 Twin Dolphin Drive, Suite 500';
        cst.Customer_City__c = 'Redwood City'; 
        cst.Customer_State__c = 'CA';
        cst.Customer_Zip_Code__c = '94065';
        cst.Customer_Country__c = 'USA';
        cst.Track_Install_Base__c = true;
        
        return cst;
    }
    
    public Customer__c newCustomerSite() {
        Customer__c cst = new Customer__c(); 
        cst.name = 'Customer Site';
        cst.recordTypeId = this.CustomerRecordTypes.get('Site');
        cst.Company__c = this.company.id;
        cst.Payment_Term__c = this.terms.ID;
        cst.Currency__c = TestFuel.currencyUSD.ID;
        //cst.Address__c = this.account.ID;
        cst.Credit_Limit__c = 100000.0;
        cst.Parent_Customer__c = this.customerShipTo.id;
        cst.Customer_Identifier__c = 'SITETEST123'; 
        cst.Top_Parent_Customer__c = this.customerParent.id;
        cst.Status__c = 'Approved';
        cst.Business_Hours__c = [select Id from BusinessHours where isDefault = true limit 1].Id;

        cst.Customer_Street__c = '303 Twin Dolphin Drive, Suite 500';
        cst.Customer_City__c = 'Redwood City'; 
        cst.Customer_State__c = 'CA';
        cst.Customer_Zip_Code__c = '94065';
        cst.Customer_Country__c = 'USA';
        return cst;
    }
    
    
    public Sales_Order__c newSalesOrder() {
        Sales_Order__c so = new Sales_Order__c(
                Company__c = this.company.id,
                Customer__c = this.customerSoldTo.id,
                Ship_To__c = this.customerShipTo.Id,
                Payment_Term__c = this.terms.id,
                Currency__c = company.Default_Transaction_Currency__c
            );
        return so;
    }
    
    public Pricebook__c newPricebook() {
        pricebook = new Pricebook__c( 
            Name = this.company.Name +  ' Orange Pricebook',
            Company__c = this.company.Id,
            Primary_Key__c = 'NATBOOK',
            Currency__c = TestFuel.currencyUSD.ID
        );
        return pricebook;
    }

    public Receiving_Document__c newReceivingDocumentASN() {
        
        Receiving_Document__c rd = new Receiving_Document__c(
                Company__c = this.company.id,
                Supplier__c = this.supplier.id,
                Date_Created__c = system.today(),
                Status__c = 'Draft',
                Type__c = 'Advanced Shipment Notice',
                Currency__c = TestFuel.currencyUSD.id,
                Transaction_Date__C = system.now()
            );
        return rd;    
    }
    

    public Product__c newProduct() {
        Product__c p = new Product__c(
                                company__c = this.company.id,
                                Name = 'Product 1' ,
                                Item__c  = this.itemList[0].ID,
                                Description__c = 'Product-10',
                                Selling_UOM__c = this.uomList[8].ID,
                                Weight__c = 13,
                                Weight_UOM__c = this.uomList[3].ID,                                
                                UPC_Code__c = '123456789123',  
                                Primary_Key__c = '123456',
                                Dimension_UOM__c = this.uomList[6].ID,
                                Length__c = 1,
                                Width__c = 1,
                                Height__c = 1
                        );    
        return p;
    }
    public Cross_Reference__c newCrossRef() {
        Cross_Reference__c  cr = new Cross_Reference__c(
                                        Name = 'CR01',
                                        Cross_Reference_Type__c = 'Customer',
                                        Reference_Object__c = 'Product',
                                        Active__c = true,
                                        Customer__c = customerParent.Id,
                                        Product__c = product.Id 
                                );
        return cr;
    }
    
    public Product__c newProduct2() {
        Product__c p = new Product__c(
                                company__c = this.company.id,
                                Name = 'Product-15' ,
                                Item__c  = this.itemList[5].ID,
                                Description__c = 'Product-15',
                                Selling_UOM__c = this.uomList[8].ID,
                                Weight__c = 5,
                                Weight_UOM__c = this.uomList[0].ID,
                                UPC_Code__c = '234567891234',
                                Dimension_UOM__c = this.uomList[6].ID,
                                Length__c = 1,
                                Width__c = 1,
                                Height__c = 1
                        );    
        return p;
    }

    public Contract__c contractAM {
        get{
            if(contractAM == null){
                contractAM = new Contract__c(
                                Name = 'TestContract',
                                ExtId__c = 'TestContract',
                                Contract_Start__c = Date.today().addDays(-1),
                                Contract_End__c = Date.today().addDays(8),
                                OwnerID = System.Userinfo.getUserId(),
                                Status__c = 'Open',
                                Supplier__c = supplier.id,
                                Company__c = company.Id,
                                Payment_Term__c = terms.id,
                                Ship_to_Facility__c = facility.Id,
                                Transportation_Mode__c = 'RAIL',
                                Currency__c = TestFuel.currencyUSD.id
                                );
                insert contractAM;
            }
            return contractAM;
        }
        set;
    }

    public Contract_Line__c contractLine {
        get{
            if(contractLine == null){
                contractLine = new Contract_Line__c(
                                    Contract__c = contractAM.Id,
                                    ExtId__c = 'TestContractLine',
                                    Company__c = company.Id,
                                    Item__c = itemlist[0].id,
                                    Name = 'Test CTL 1',
                                    Contract_Start__c = Date.today().addDays(-1),
                                    Contract_End__c = Date.today().addDays(4),
                                    Status__c = 'Open',
                                    Negotiated_Price__c = 10,
                                    Contract_Quantity__c = 100,
                                    Consigned__c = true,
                                    Purchased_Quantity__c = 0,
                                    Quantity_Received__c = 0,
                                    Quantity_Still_Due__c = 0,
                                    Quantity_Returned__c = 0,
                                    Purchase_UOM__c = uomList[8].Id
                                );
                insert contractLine;
            }
            return contractLine;
        }
        set;
    }
    
    public Purchase_Order__c purchaseOrder {
        get {
            if ( purchaseOrder == null  ) {
                 purchaseOrder = new Purchase_Order__c(
                                                    Supplier__c = supplier.id, 
                                                    Company__c = company.id,
                                                    Payment_Term__c = terms.id,
                                                    Delivery_Facility__c = facility2.id,
                                                    Delivery_Location__c = location2.ID,
                                                    Remit_To_Supplier__c = remitToSupplier.id,
                                                    Approval_Status__c = 'Approved',
                                                    fob_term__c = fobTerm.id,
                                                    Acknowledge_Via__c = 'Email',
                                                    Status__c = 'Open',
                                                    Memo__c = 'purchaseOrder',
                                                    Currency__c = TestFuel.currencyUSD.id
                                        );
                insert purchaseOrder;
                
                insert purchaseOrderLines;
                purchaseOrder.Approval_Status__c = 'Approved';
                update purchaseOrder;
            }
                
            return purchaseOrder;
        }
        set;
    }
    
    public List<Purchase_Order_Line__c> purchaseOrderLines {
        get {
            if ( purchaseOrderLines == null  ) {
                purchaseOrderLines = new List<Purchase_Order_Line__c>();
                
                Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
                poLine.Purchase_Order__c = purchaseOrder.Id;
                poLine.Order_Quantity__c = 10;     
                poLine.Unit_Price__c = 12;
                poLine.Item__c = itemList[2].Id;
                poLine.Item__r = itemList[2];
                poLine.Description__c = 'purchaseOrderLine0';
                poLine.Purchase_UOM__c = itemList[2].Purchasing_UOM__c;
                poLine.Stocking_UOM__c = itemList[2].Stocking_UOM__c;
                poLine.Packaging_UOM__c = itemList[2].Stocking_UOM__c;
                poLine.Company__c = company.id;
                poLine.Need_Date__c = system.today() + 7;
                poLine.Delivery_Facility__c = facility2.id;
                poLine.Delivery_Location__c = location2.ID;
                poLine.Supplier__c = supplier.Id;
                poLine.Line__c = 1;
                poLine.Quantity_Matched__c = 0;
                poLine.Amount_Matched__c = 0;
                purchaseOrderLines.add( poLine );                               
            }
            
            return purchaseOrderLines;
        }
        set;
    }
    
    public Purchase_Order__c purchaseOrder1 {
        get {
            if ( purchaseOrder1 == null  ) {
                 purchaseOrder1 = new Purchase_Order__c(
                    Supplier__c = supplier.id, 
                    Company__c = company.id,
                    Payment_Term__c = terms.id,
                    Delivery_Facility__c = facility2.id,
                    Delivery_Location__c = location2.ID,
                    Remit_To_Supplier__c = remitToSupplier.id,
                    Approval_Status__c = 'Approved',
                    fob_term__c = fobTerm.id,
                    Status__c = 'Open',
                    Memo__c = 'purchaseOrder',
                    Currency__c = TestFuel.currencyUSD.id
                );
                insert purchaseOrder1;
                
                insert purchaseOrder1Lines;
                purchaseOrder1.Approval_Status__c = 'Approved';
                update purchaseOrder1;
            }
                
            return purchaseOrder1;
        }
        set;
    }
    
    public List<Purchase_Order_Line__c> purchaseOrder1Lines {
        get {
            if ( purchaseOrderLines == null  ) {
                purchaseOrderLines = new List<Purchase_Order_Line__c>();
                
                Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
                poLine.Purchase_Order__c = purchaseOrder1.Id;
                poLine.Order_Quantity__c = 10;     
                poLine.Unit_Price__c = 12;
                poLine.Item__c = itemList[2].Id;
                poLine.Description__c = itemList[2].Description__c;
                poLine.Purchase_UOM__c = itemList[2].Purchasing_UOM__c;
                poLine.Company__c = company.id;
                poLine.Need_Date__c = system.today() + 7;
                poLine.Delivery_Facility__c = facility2.id;
                poLine.Delivery_Location__c = location2.ID;
                poLine.Supplier__c = supplier.Id;
                poLine.Line__c = 1;
                
                purchaseOrderLines.add( poLine );                               
            }
            
            return purchaseOrderLines;
        }
        set;
    }
    
    public Purchase_Order__c purchaseOrder2 {
        get {
            if ( purchaseOrder2 == null  ) {
                 purchaseOrder2 = new Purchase_Order__c(
                    Supplier__c = supplier.id, 
                    Company__c = company.id,
                    Payment_Term__c = terms.id,
                    Delivery_Facility__c = facility2.id,
                    Delivery_Location__c = location2.ID,
                    Remit_To_Supplier__c = remitToSupplier.id,
                    Approval_Status__c = 'Approved',
                    fob_term__c = fobTerm.id,
                    Status__c = 'Open',
                    Memo__c = 'purchaseOrder2',
                    Currency__c = TestFuel.currencyUSD.id
                );
                insert purchaseOrder2;
                
                insert purchaseOrder2Lines;
                purchaseOrder2.Approval_Status__c = 'Approved';
                update purchaseOrder2;
            }
                
            return purchaseOrder2;
        }
        set;
    }
    
    public List<Purchase_Order_Line__c> purchaseOrder2Lines {
        get {
            if ( purchaseOrder2Lines == null  ) {
                purchaseOrder2Lines = new List<Purchase_Order_Line__c>();
                
                Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
                poLine.Purchase_Order__c = purchaseOrder2.Id;
                poLine.Order_Quantity__c = 10;     
                poLine.Unit_Price__c = 25;
                poLine.Item__c = itemList[2].Id;
                poLine.Description__c = itemList[2].Description__c;
                poLine.Purchase_UOM__c = itemList[2].Purchasing_UOM__c;
                poLine.Company__c = company.id;
                poLine.Need_Date__c = system.today() + 7;
                poLine.Delivery_Facility__c = facility2.id;
                poLine.Delivery_Location__c = location2.ID;
                poLine.Supplier__c = supplier.Id;
                poLine.Line__c = 1;
                purchaseOrder2Lines.add( poLine );      
                
                Purchase_Order_Line__c poLine2 = new Purchase_Order_Line__c();
                poLine2.Purchase_Order__c = purchaseOrder2.Id;
                poLine2.Order_Quantity__c = 5;     
                poLine2.Unit_Price__c = 15;
                poLine2.Item__c = itemList[2].Id;
                poLine2.Description__c = itemList[2].Description__c;
                poLine2.Purchase_UOM__c = itemList[2].Purchasing_UOM__c;
                poLine2.Company__c = company.id;
                poLine2.Need_Date__c = system.today() + 7;
                poLine2.Delivery_Facility__c = facility2.id;
                poLine2.Delivery_Location__c = location2.ID;
                poLine2.Supplier__c = supplier.Id;
                poLine2.Line__c = 2;
                purchaseOrder2Lines.add( poLine2 );                             
            }
            
            return purchaseOrder2Lines;
        }
        set;
    }
    
    public Purchase_Order__c purchaseOrder3 {
        get {
            if ( purchaseOrder3 == null  ) {
                 purchaseOrder3 = new Purchase_Order__c(
                    Supplier__c = supplier.id, 
                    Company__c = company.id,
                    Payment_Term__c = terms.id,
                    Delivery_Facility__c = facility2.id,
                    Delivery_Location__c = location2.ID,
                    Remit_To_Supplier__c = remitToSupplier.id,
                    Approval_Status__c = 'Approved',
                    fob_term__c = fobTerm.id,
                    Status__c = 'Open',
                    Memo__c = 'purchaseOrder',
                    currency__c = TestFuel.currencyUSD.id
                );
                insert purchaseOrder3;
                
                insert purchaseOrder3Lines;
                purchaseOrder3.Approval_Status__c = 'Approved';
                update purchaseOrder3;
            }
                
            return purchaseOrder3;
        }
        set;
    }
    
    public List<Purchase_Order_Line__c> purchaseOrder3Lines {
        get {
            if ( purchaseOrder3Lines == null  ) {
                purchaseOrder3Lines = new List<Purchase_Order_Line__c>();
                
                Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
                poLine.Purchase_Order__c = purchaseOrder3.Id;
                poLine.Order_Quantity__c = 10;     
                poLine.Unit_Price__c = 25;
                poLine.Item__c = itemList[2].Id;
                poLine.Description__c = itemList[2].Description__c;
                poLine.Purchase_UOM__c = itemList[2].Purchasing_UOM__c;
                poLine.Company__c = company.id;
                poLine.Need_Date__c = system.today() + 7;
                poLine.Delivery_Facility__c = facility2.id;
                poLine.Delivery_Location__c = location2.ID;
                poLine.Supplier__c = supplier.Id;
                poLine.Line__c = 1;
                
                purchaseOrder3Lines.add( poLine );
                
                Purchase_Order_Line__c poLine2 = new Purchase_Order_Line__c();
                poLine2.Purchase_Order__c = purchaseOrder3.Id;
                poLine2.Order_Quantity__c = 5;     
                poLine2.Unit_Price__c = 15;
                poLine2.Item__c = itemList[2].Id;
                poLine2.Description__c = itemList[2].Description__c;
                poLine2.Purchase_UOM__c = itemList[2].Purchasing_UOM__c;
                poLine2.Company__c = company.id;
                poLine2.Need_Date__c = system.today() + 7;
                poLine2.Delivery_Facility__c = facility2.id;
                poLine2.Delivery_Location__c = location2.ID;
                poLine2.Supplier__c = supplier.Id;
                poLine2.Line__c = 1;
                
                purchaseOrder3Lines.add( poLine2 );
             }
            
            return purchaseOrder3Lines;
        }
        set;
    }
    
    public Calendar__c manufacturingCalendar {
        get {
            if (manufacturingCalendar == null) {
                manufacturingCalendar = new Calendar__c(
                    Name = 'MFG Calendar',
                    Company__c = company.Id,
                    Type__c = 'Manufacturing',
                    Start_Date__c = Date.newInstance(Date.today().year(),1,1)
                );
                insert manufacturingCalendar;
                
                List<Working_Day__c> workingDays = new List<Working_Day__c>();
                Date d = manufacturingCalendar.Start_Date__c;
                while (d < Date.newInstance(Date.today().addYears(2).year(),1,1)) {
                    workingDays.add(new Working_Day__c(
                        Calendar__c = manufacturingCalendar.Id,
                        Start__c = DateTime.newInstance(d,Time.newInstance(9,0,0,0)),
                        End__c = DateTime.newInstance(d,Time.newInstance(17,0,0,0))
                    ));
                    d = d.addDays(1);
                }
                insert workingDays;
            }
            return manufacturingCalendar;
        } set;
    }

    public List<Work_Center__c> workCenters {
        get {
            if (workCenters == null) {
                workCenters = new List<Work_Center__c>();
                for (Integer i=1;i<4;i++) {
                    workCenters.add(new Work_Center__c(
                        Name = 'WC ' + i,
                        Company__c = company.Id,
                        Facility__c = facility2.Id,
                        Manufacturing_Overhead_Factor__c = i
                    ));
                }
                insert workCenters;
            }
            return workCenters;
        } set;
    }

    public List<Resource__c> resources {
        get {
            if (resources == null) {
                resources = new List<Resource__c>();
                for (Integer i=1;i<4;i++) {
                    resources.add(new Resource__c(
                        Name = 'Resource ' + i,
                        Company__c = company.Id,
                        Facility__c = facility2.Id,
                        Rate__c = i
                    ));
                }
                insert resources;
            }
            return resources;
        } set;
    }

    public List<Work_Center_Resource__c> wcResources {
        get {
            if (wcResources == null) {
                wcResources = new List<Work_Center_Resource__c>();
                for (Integer i=1;i<4;i++) {
                    wcResources.add(new Work_Center_Resource__c(
                        Name = 'WC Resource ' + i,
                        Company__c = company.Id,
                        Facility__c = facility2.Id,
                        Work_Center__c = workCenters[i-1].Id,
                        Resource__c = resources[i-1].Id
                    ));
                }
                insert wcResources;
            }
            return wcResources;
        } set;
    }

    public Item_Specification__c itemSpec {
        get {
            if (itemSpec == null) {
                itemSpec = new Item_Specification__c(
                    Company__c = company.Id,
                    Facility__c = facility2.Id,
                    Item__c = itemList[5].Id,
                    Revision__c = 'IS',
                    Start_Date2__c = System.now().addDays(-1),
                    Costing__c = true,
                    Production__c = true,
                    Copy_Phantom_Routings__c = false,
                    Packaging_UOM__c = uomList[8].Id,
                    Default_Work_Order_Packaging_UOM__c = uomList[8].Id
                );
                insert itemSpec;

                System.assert(routings != null);
                System.assert(components != null);
            }
            return itemSpec;
        } set;
    }

    public List<Routing__c> routings {
        get {
            if (routings == null) {
                if (company.Manufacturing_Calendar__c == null) {
                    company.Manufacturing_Calendar__c = manufacturingCalendar.Id;
                    update company;
                }
                
                routings = new List<Routing__c>();
                for (Integer i=0;i<3;i++) {
                    routings.add(new Routing__c(
                        Assembly_Item_Specification__c = itemSpec.Id,
                        Company__c = company.Id,
                        Facility__c = facility2.Id,
                        Operation_Sequence__c = 1,
                        Work_Center_Resource__c = wcResources[i].Id,
                        Work_Center__c = wcResources[i].Work_Center__c,
                        Resource_Sequence__c = i + 1,
                        Resource_Quantity__c = 1,
                        Standard_Hours__c = 1,
                        Fixed_Hours__c = false,
                        Backflush_Resource__c = false
                    ));
                }
                insert routings;              
            }
            return routings;
        } set;
    }

    public List<Component__c> components {
        get {
            if (components == null) {
                components = new List<Component__c>();
                components.add(new Component__c(
                    Assembly_Item_Specification__c = itemSpec.Id,
                    Quantity_Per_Assembly__c = 1,
                    Component_Item__c = itemList[2].Id,
                    Component_Sequence__c = 1,
                    Company__c = company.Id,
                    Yield__c = 100.00,
                    Type__c = ComponentService.TYPE_BACKFLUSH,
                    Routing__c = routings[0].Id
                ));
                components.add(new Component__c(
                    Assembly_Item_Specification__c = itemSpec.Id,
                    Quantity_Per_Assembly__c = 1,
                    Component_Item__c = itemList[0].Id,
                    Component_Sequence__c = 2,
                    Company__c = company.Id,
                    Yield__c = 100.00,
                    Type__c = ComponentService.TYPE_BACKFLUSH,
                    Routing__c = routings[0].Id
                ));    
                insert components;
            }
            return components;
        } set;
    }
        
    public Item_Specification__c configItemSpec  {
        get {
            if (configItemSpec== null ) {
                
                configItemSpec = new Item_Specification__c();
                configItemSpec.Company__c = company.id;
                configItemSpec.Item__c = itemList[5].id;
                configItemSpec.Revision__c = 'R1';
                configItemSpec.Start_Date2__c = System.now().addDays(-1);
                configItemSpec.Configurable__c = true;
                configItemSpec.Costing__c = false;
                configItemSpec.Production__c = false;
                configItemSpec.Packaging_UOM__c = uomList[8].Id;
                configItemSpec.Default_Work_Order_Packaging_UOM__c = uomList[8].Id;
                    
                insert configItemSpec;
                insert configComponents;
            }
            return configItemSpec;
        } set;
    }
    
    public List<Component__c> configComponents {
        get {
            if ( configComponents == null  ) {
                configComponents = new List<Component__c>();
                
                Component__c comp1 = new Component__c();
                comp1.Assembly_Item_Specification__c = configItemSpec.Id;
                comp1.Quantity_Per_Assembly__c = 1;
                comp1.Component_Item__c = itemList[2].Id;
                comp1.Company__c = company.id;
                comp1.Yield__c = 100.00;
                comp1.Type__c = 'Backflush';
                comp1.Configuration_Type__c = 'Mandatory';
                configComponents.add( comp1 );
                
                Component__c comp2 = new Component__c();
                comp2.Assembly_Item_Specification__c = configItemSpec.Id;
                comp2.Quantity_Per_Assembly__c = 1;
                comp2.Component_Item__c = itemList[0].Id;
                comp2.Company__c = company.id;
                comp2.Yield__c = 100.00;
                comp2.Type__c = 'Backflush';
                comp2.Configuration_Type__c = 'Mandatory';
                configComponents.add( comp2 );                              
            }
            
            return configComponents;
        }
        set;
    }
    
    public Work_Order__c workOrder  {
        get {
            if (workOrder== null) {
                workOrder = new Work_Order__c(
                    Company__c = company.Id,
                    Facility__c = facility2.Id,
                    Assembly_Item_Specification__c = itemSpec.Id,
                    Item__c = itemSpec.Item__c,
                    Need_Date2__c = System.today() + 30,
                    Start_Date2__c = DateTime.newInstance(System.today().addDays(1),Time.newInstance(0,0,0,0)),
                    Order_Quantity__c = 10,
                    Status__c = 'Draft',
                    Type__c = 'Regular',
                    Complete_To_Location__c = location6.Id,
                    MRB_Location__c = location2.Id,
                    Default_WIP_Location__c = location7.Id,
                    Notes__c = 'workorder',
                    Currency__c = TestFuel.currencyUSD.ID,
                    Packaging_UOM__c = uomList[8].Id
                );
                insert workOrder;
            }
            return workOrder;
        } set;
    }
    
    public Customer_Invoice__c custInv1  {
        get {
            if (custInv1== null ) {
                system.assert( company != null && customerBillTo != null && customerSoldTo != null);
                custInv1 = new Customer_Invoice__c();
                custInv1.Company__c = company.id;
                custInv1.Invoice_Type__c = 'Ship Invoice';
                custInv1.Status__c = 'Open';
                custInv1.Bill_To_Customer__c = customerBillTo.id;
                custInv1.Sold_To_Customer__c = customerSoldTo.id;
                insert custInv1;
            }
            return custInv1;
        } set;
    }
    
     public Tax_Book__c book {
        get{
            if(book == null){
                book = new Tax_Book__c();
                book.Name = 'Corporate';
                book.corporate__c = true;
                book.active__c = true;
                book.Company__c = company.Id;
                insert book;
            }
            return book;
        }
        set;
    }
    
    public Reason_Code__c deductionCode {
        get{
            if(deductionCode == null){
                deductionCode = new Reason_Code__c();
                deductionCode.Company__c = company.Id;
                deductionCode.Type__c = 'Deductions';
                deductionCode.Code__c = 'D001';
                insert deductionCode;
            }
            return deductionCode;
        }
        set;
    }
    
     public Reason_Code__c resolutionCode {
        get{
            if(resolutionCode == null){
                resolutionCode = new Reason_Code__c();
                resolutionCode.Company__c = company.Id;
                resolutionCode.Type__c = 'Resolution';
                resolutionCode.Code__c = 'R001';
                insert resolutionCode;
            }
            return resolutionCode;
        }
        set;
    }
    
    public Asset_Class__c assetClass {
        get{
            if(assetClass == null){
                assetClass = new Asset_Class__c();
                assetClass.name = 'Vehicles';
                assetClass.depreciation_method__c = 'MACRS';
                assetClass.declining_balance__c = '200%';
                assetClass.depreciation_period__c = 'Monthly';
                assetClass.depreciation_convention__c = 'Full Month';
                assetClass.life_in_months__c = 60;
                assetClass.GL_Account__c = cashGL.Id;
                assetClass.Company__c = company.Id;
                insert assetClass;
            }
            return assetClass;
        }
        set;
    }
    
    public Fixed_Asset__c fixedAsset {
        get{
            if(fixedAsset == null){
                fixedAsset = new Fixed_Asset__c();
                fixedAsset.name = 'Truck';
                fixedAsset.Asset_Class__c = assetClass.Id;
                fixedAsset.company__c = company.Id;
                fixedAsset.tax_book__c = book.Id;
                fixedAsset.Fixed_Asset_Type__c = FixedAssetService.ASSET_ACCOUNTING;
                fixedAsset.In_Service_Date__c = system.today().addYears(-3);
                fixedAsset.Acquisition_Cost__c = 65000;
                fixedAsset.Purchase_price__c = 65000;
                fixedAsset.Purchase_Currency__c = company.Comp_Currency__c;
                fixedAsset.Residual_Value__c = 5000;
                fixedAsset.Status__c = 'Active';
                fixedAsset.GL_Account__c = cashGL.Id;
                insert fixedAsset;
                fixedAsset = [SELECT Id, name, status__c, company__c, asset_class__c, depreciation_count__c, depreciation_life__c, in_service_date__c, 
                                gl_account__c, depreciation_method__c, depreciation_period__c, Estimated_End_of_Life__c, retirement_date__c, 
                                acquisition_cost__c, residual_value__c, book_value__c, date_last_depreciated__c, next_depreciation_date__c, 
                                asset_tag_number__c, fixed_asset_key__c, Company__r.Default_Transaction_Currency__c, disposition_date__c, 
                                depreciation_convention__c, declining_balance__c, Depreciable_Basis__c, Final_Depreciation_Date__c, total_depreciated_value__c 
                                FROM Fixed_Asset__c WHERE Id = :fixedAsset.Id];
            }
            return fixedAsset;
        }
        set;
    }

    public Order__c transferOrder {
        get {
            if (transferOrder == null) {
                transferOrder = newTransferOrder(); 
                transferOrder.Order_Date__c = System.today() - 10;
                insert transferOrder;
                insert transferOrderLines;
            }
            return transferOrder;
        } set;
    }
    
    public Order__c newTransferOrder() {
        Order__c transferOrder = new Order__c(
                                            Shipping_Company__c = company.id,
                                            Deliver_To_Facility__c = facility.id,
                                            Deliver_To_Location__c = location.ID,
                                            Receiving_Company__c = company.id,
                                            Ship_From_Facility__c = facility2.id,
                                            Ship_From_Location__c = location2.ID,
                                            currency__c = TestFuel.currencyUSD.id,
                                            Status__c = 'Draft'
                                        );
        return transferOrder;
    }
    
    public List<Order_Line__c> transferOrderLines {
        get {
            if ( transferOrderLines == null  ) {
                transferOrderLines = new List<Order_Line__c>();
                
                Order_Line__c toLine = new Order_Line__c();
                toLine.Order__c = transferOrder.Id;
                toLine.Quantity_Ordered__c = 10;
                toLine.Description__c = itemList[0].Description__c;
                toLine.Receiving_Item__c = itemList[0].Id;
                toLine.Receiving_Company__c = company.id;
                toLine.Required_Date__c = system.today() + 7;
                toLine.Deliver_To_Facility__c = facility.id;
                toLine.Deliver_To_Location__c = location.ID;
                toLine.Shipping_Item__c = itemList[0].Id;
                toLine.Shipping_Company__c = company.id;
                toLine.Required_Date__c = system.today() + 7;
                toLine.Ship_From_Facility__c = facility2.id;
                toLine.Ship_From_Location__c = location2.ID;
                transferOrderLines.add( toLine );
                
                Order_Line__c toLine1 = new Order_Line__c();
                toLine1.Order__c = transferOrder.Id;
                toLine1.Quantity_Ordered__c = 15;
                toLine1.Description__c = itemList[5].Description__c;
                toLine1.Receiving_Item__c = itemList[5].Id;
                toLine1.Receiving_Company__c = company.id;
                toLine1.Required_Date__c = system.today() + 7;
                toLine1.Deliver_To_Facility__c = facility.id;
                toLine1.Deliver_To_Location__c = location.ID;
                toLine1.Shipping_Item__c = itemList[5].Id;
                toLine1.Shipping_Company__c = company.id;
                toLine1.Required_Date__c = system.today() + 7;
                toLine1.Ship_From_Facility__c = facility2.id;
                toLine1.Ship_From_Location__c = location2.ID;
                transferOrderLines.add( toLine1 );
            }
                
            return transferOrderLines;
        }
        set;
    }
    
    
    public Order__c packageTransferOrder {
        get {
            if (packageTransferOrder == null) {
                packageTransferOrder = newPackageTransferOrder(); 
                packageTransferOrder.Order_Date__c = System.today() - 12;
                insert packageTransferOrder;
                insert packageTransferOrderLines;
            }
            return packageTransferOrder;
        } set;
    }
    
    public Order__c newPackageTransferOrder() {
        Order__c packageTransferOrder = new Order__c(
                                            Shipping_Company__c = company.id,
                                            Deliver_To_Facility__c = facility.id,
                                            Deliver_To_Location__c = location.ID,
                                            Receiving_Company__c = company.id,
                                            Ship_From_Facility__c = facility2.id,
                                            Ship_From_Location__c = location2.ID,
                                            currency__c = TestFuel.currencyUSD.id,
                                            Status__c = 'Draft'
                                        );
        return packageTransferOrder;
    }
    
    public List<Order_Line__c> packageTransferOrderLines {
        get {
            if ( packageTransferOrderLines == null  ) {
                packageTransferOrderLines = new List<Order_Line__c>();
                
                Order_Line__c pkgToLine = new Order_Line__c();
                pkgToLine.Order__c = packageTransferOrder.Id;
                pkgToLine.Quantity_Ordered__c = 10;
                pkgToLine.Description__c = itemList[14].Description__c;
                pkgToLine.Receiving_Item__c = itemList[14].Id;
                pkgToLine.Receiving_Company__c = company.id;
                pkgToLine.Required_Date__c = system.today() + 7;
                pkgToLine.Deliver_To_Facility__c = facility.id;
                pkgToLine.Deliver_To_Location__c = location.ID;
                pkgToLine.Shipping_Item__c = itemList[14].Id;
                pkgToLine.Shipping_Company__c = company.id;
                pkgToLine.Required_Date__c = system.today() + 7;
                pkgToLine.Ship_From_Facility__c = facility2.id;
                pkgToLine.Ship_From_Location__c = location2.ID;
                packageTransferOrderLines.add( pkgToLine );
            }
                
            return packageTransferOrderLines;
        }
        set;
    }
    //TODO: ADD GET;SET; JW-8-1-2014
    public List<Segment_Definition__c> customsegList = new List<Segment_Definition__c>();{
            
        List<Segment_Definition__c> existingSegs = Segment_Definition__c.getAll().Values();
        boolean hasCompany = false;
        boolean hasGL = false;
        boolean hasInterco = false;
        for(Segment_Definition__c sd : existingSegs){
            if(sd.Name == 'Company__c'){
                hasCompany = true;
            }else if(sd.Name == 'GL_Account__c'){
                hasGL = true;
            }else if(sd.Name == 'Intercompany__c'){
                hasInterco = true;
            }
        }
        
        if(!hasCompany){
            Segment_Definition__c custom_seg1 = new Segment_Definition__c();
            custom_seg1.Name = 'Company__c';
            custom_seg1.Accounting_Entry_Field__c = 'Company__c'; // just need a field to stuff into
            custom_seg1.Object_API_Name__c = 'Company__c';
            custom_seg1.Segment_Number__c = 1;
            customsegList.add(custom_seg1);
        }
        
        if(!hasGL){
            Segment_Definition__c custom_seg2 = new Segment_Definition__c();
            custom_seg2.Name = 'GL_Account__c';
            custom_seg2.Accounting_Entry_Field__c = 'GL_Account__c'; // just need a field to stuff into
            custom_seg2.Object_API_Name__c = 'GL_Account__c';
            custom_seg2.Accounting_Rule_Segment__c = 'GL_Account__c';
            custom_seg2.Accounting_Rule_Reference_Value__c = 'GL_Account_Reference_Value__c';
            custom_seg2.Accounting_Rule_Default__c = 'Default_GL_Account__c';
            custom_seg2.Segment_Number__c = 2;
            customsegList.add(custom_seg2);
        }
        
        if(!hasInterco){
                Segment_Definition__c custom_seg3 = new Segment_Definition__c();
                custom_seg3.Name = 'Intercompany__c';
                custom_seg3.Accounting_Entry_Field__c = 'Intercompany__c'; // just need a field to stuff into
                custom_seg3.Object_API_Name__c = 'Intercompany__c';
                custom_seg3.Accounting_Rule_Segment__c = 'Intercompany__c';
                custom_seg3.Accounting_Rule_Reference_Value__c = 'Intercompany_Reference_Value__c';
                custom_seg3.Accounting_Rule_Default__c = 'Default_Intercompany__c';
                custom_seg3.Segment_Number__c = 3;
                customsegList.add(custom_seg3);
            }
            
        insert customsegList; 
    } 
    
    public List<Accounting_Default_Segment_Definition__c> customAccountingDefaultSegmentList = new List<Accounting_Default_Segment_Definition__c>();{
        
        List<Accounting_Default_Segment_Definition__c> existingSegs = Accounting_Default_Segment_Definition__c.getAll().Values();
        boolean hasCompany = false;
        boolean hasGL = false;
        boolean hasinterco = false;
        for(Accounting_Default_Segment_Definition__c sd : existingSegs){
            if(sd.Name == 'Company__c'){
                hasCompany = true;
            }else if(sd.Name == 'GL_Account__c'){
                hasGL = true;
            }else if(sd.Name == 'Intercompany__c'){
                hasinterco = true;
            }
        }
        
        if(!hasCompany){
            Accounting_Default_Segment_Definition__c custom_seg1 = new Accounting_Default_Segment_Definition__c();
            custom_seg1.Name = 'Company__c';
            custom_seg1.Accounting_Default_Field__c = 'Company__c'; // just need a field to stuff into
            custom_seg1.Object_API_Name__c = 'Company__c';
            custom_seg1.Segment_Number__c = 1;
            customAccountingDefaultSegmentList.add(custom_seg1);
        }
        
        if(!hasGL){
            Accounting_Default_Segment_Definition__c custom_seg2 = new Accounting_Default_Segment_Definition__c();
            custom_seg2.Name = 'GL_Account__c';
            custom_seg2.Accounting_Default_Field__c = 'GL_Account__c'; // just need a field to stuff into
            custom_seg2.Object_API_Name__c = 'GL_Account__c';
            custom_seg2.Segment_Number__c = 2;
            customAccountingDefaultSegmentList.add(custom_seg2);
        }
        
        if(!hasinterco){
            Accounting_Default_Segment_Definition__c custom_seg3 = new Accounting_Default_Segment_Definition__c();
            custom_seg3.Name = 'Intercompany__c';
            custom_seg3.Accounting_Default_Field__c = 'Intercompany__c'; // just need a field to stuff into
            custom_seg3.Object_API_Name__c = 'Intercompany__c';
            custom_seg3.Segment_Number__c = 3;
            customAccountingDefaultSegmentList.add(custom_seg3);
        }
        
        insert customAccountingDefaultSegmentList; 
    } 
    
    // create the default wide rule which will allow any combination for the segments
    public List<Segment_Validation__c> svList = new List<Segment_Validation__c>();{
        Segment_Validation__c sv1 = new Segment_Validation__c();
        sv1.segment_1__c = '*';
        sv1.segment_2__c = '*';
        sv1.segment_3__c = '*';
        sv1.active__c = true;
        svList.add(sv1);
        Segment_Validation__c sv2 = new Segment_Validation__c();
        sv2.segment_1__c = '*';
        sv2.segment_2__c = null;
        sv2.segment_3__c = null;
        sv2.active__c = true;
        svList.add(sv2);
        insert svList;
        
    }  



     public Contract__c contract {
        
        get {
            if ( contract == null  ) {
                contract = newContract(); 
                insert contract;
                insert contractLines;
            }        
            return contract;
        }

        set;
    }
    
    public Contract__c newContract() {
        Contract__c contract = new Contract__c();
        contract.Name = 'TestContract';
        contract.Contract_Start__c = Date.today().addDays(-1);
        contract.Contract_End__c = Date.today().addDays(4);
        contract.OwnerID = System.Userinfo.getUserId();
        contract.Status__c = 'Open';
        contract.Supplier__c = supplier.id;
        contract.Company__c = company.Id;
        contract.FOB_Term__c = fobTerm.id;
        contract.Payment_Term__c = terms.id;
        contract.Ship_to_Facility__c = facility2.Id;
        contract.Transportation_Mode__c = 'RAIL';
        contract.Currency__c = TestFuel.currencyUSD.id;
        return contract;
    }
    
    public List<Contract_Line__c> contractLines {
        get {
            if ( contractLines == null ) {
                contractLines = new List<Contract_Line__c>();
                Contract_Line__c contractLine = new Contract_Line__c();
                contractLine.Contract__c = contract.Id;
                contractLine.Company__c = company.Id;
                contractLine.Item__c = itemlist[0].id;
                contractLine.Name = 'Test CTL 1';
                contractLine.Contract_Start__c = Date.today().addDays(-1);
                contractLine.Contract_End__c = Date.today().addDays(4);
                contractLine.Status__c = 'Open';
                contractLine.Negotiated_Price__c = 10;
                contractLine.Contract_Quantity__c = 1000;
                contractLine.Type__c = 'Fixed';
                contractLine.Consigned__c = false;
                contractLine.Purchased_Quantity__c = 0;
                contractLine.Quantity_Received__c = 0;
                contractLine.Quantity_Still_Due__c = 0;
                contractLine.Quantity_Returned__c = 0;
                contractLines.add(contractLine);
            }
                
            return contractLines;
        }
        set;
    }

    public Category__c categoryBilling{
        get{
            if(categoryBilling == null){
                categoryBilling = new Category__c();
                categoryBilling.Name = 'Billing Category';
                categoryBilling.Type__c = 'Billing';
                insert categoryBilling;
                
       }
            return categoryBilling;
        }
        set;
    }
    public Category__c categoryFulfillment {
        get{
            if(categoryFulfillment == null){
                categoryFulfillment = new Category__c();
                categoryFulfillment.Name = 'Fulfillment  Category';
                categoryFulfillment.Type__c = 'Fulfillment ';
                insert categoryFulfillment;
                
       }
            return categoryFulfillment;
        }
        set;
    }
    
    public Product__c configProduct {
        get{
            if(configProduct == null){
                List<Product__c> prods = new List<Product__c>();
                configProduct = new Product__c();
                configProduct.Product_Type__c = 'Configurable';
                configProduct.Item__c = configItemSpec.Item__c;
                configProduct.Company__c = configItemSpec.Company__c;
                configProduct.Selling_UOM__c = uomObj.Id;
                prods.add(configProduct);
                for(Component__c comp : configComponents){
                    Product__c iProd = new Product__c();
                    iProd.Product_Type__c = 'Product';
                    iProd.Status__c = 'Active';
                    iProd.Used__c = false;
                    iProd.Item__c = comp.Component_Item__c;
                    iProd.Company__c = comp.Company__c;
                    iProd.Selling_UOM__c = uomObj.Id;
                    prods.add(iProd);
                }
                insert prods;
                List<Pricebook_Line__c> pbls = new List<Pricebook_Line__c>();
                integer counter = 0;
                for(Product__c p : prods){
                    Pricebook_Line__c iPL =new Pricebook_Line__c();
                    iPL.product__c = p.Id;
                    iPL.pricebook__c = this.pricebook.id;
                    iPL.price__c = 100 + counter;
                    iPL.start_date__c = system.today().adddays(0);
                    iPL.end_date__c = system.today().adddays(10);
                    pbls.add(iPL);
                    counter++;    
                }
                database.insert(pbls, false);
            }
            return configProduct;
        }set;
    }

    public Plan__c plan{
        get{
            if(plan == null){
                plan = new Plan__c();
                plan.Name = 'Sample Plan';
                plan.Parent_Customer__c = customerParent.Id;
                plan.Start_Date__c = system.today();
                insert plan;
            }
            return plan;
        }
        set;
    }
    
    public Agreement__c agreement{
        get{
            if(agreement == null){
                agreement = new Agreement__c();
                agreement.Company__c = company.Id;
                agreement.Name = 'Sample Agreement';
                agreement.Plan__c = plan.Id;
                agreement.Customer__c = customerParent.Id;
                agreement.Start_Date__c = system.today();
                agreement.Status__c = 'Approved';
                agreement.Customer_Type__c = 'Bill To';
                agreement.Currency__c = TestFuel.currencyGBP.id;
                agreement.Payment_Terms__c = terms.Id;
                insert agreement;
                Agreement_Line__c agl = agreementLine;
            }
            return agreement;
        }
        set;
    }
    
    public Agreement_Line__c agreementLine {
        get{
            if(agreementLine == null){
                agreementLine = new Agreement_Line__c();
                agreementLine.Agreement__c = agreement.Id;
                agreementLine.Start_Date__c = agreement.Start_Date__c;
                agreementLine.Occurrence__c = 'Monthly';
                agreementLine.Rate_Basis__c = 'Quantity';
                agreementLine.Occurrence_Count__c = 12;
                agreementLine.Product__c = configProduct.Id;
                agreementLine.Product_Type__c = 'Configurable';
                agreementLine.Sales_Agreement_Quantity__c = 10000;
                agreementLine.Agreement_Price__c = 100;
                agreementLine.Description__c = 'Sample Agreement Line 1';
                insert agreementLine;
            }
            return agreementLine;
        }
        set;
    }
    public Agreement_Line__c agreementLine1 {
        get{
            if(agreementLine1 == null){
                agreementLine1= new Agreement_Line__c();
                agreementLine1.Agreement__c = agreement.Id;
                agreementLine1.Start_Date__c = agreement.Start_Date__c;
                agreementLine1.Product__c = Product.Id;
                agreementLine1.Sales_Agreement_Quantity__c = 1000;
                agreementLine1.Agreement_Price__c = 10;
                agreementLine1.Description__c = 'Sample Agreement Line 2';
                insert agreementLine1;
            }
            return agreementLine1;
        }
        set;
    }
    
    public list<Bank_Transaction__c> bankTransactions{
        get{
            if(bankTransactions == null){
                bankTransactions = new list<Bank_Transaction__c>();
                
                Bank_Transaction__c bankTransaction = new Bank_Transaction__c();
                bankTransaction.Amount__c = -5000.00;
                bankTransaction.Currency__c = TestFuel.currencyUSD.id;
                bankTransaction.Bank_Account__c = bankAccount.Id;
                bankTransaction.Company__c = company.Id;
                bankTransaction.Transaction_Type__c = 'Credit';
                bankTransaction.Reference_Number__c = '123s44567mnJ';
                bankTransaction.Source__c = 'Yodlee';
                bankTransaction.Transacted_With__c = 'ABCL';
                bankTransaction.Transaction_Date__c = System.now();
                bankTransaction.Payment_Method__c = 'Wire';
                bankTransaction.SubTransaction_Type__c = 'Credit';
                bankTransaction.Bank_Account__c = bankAccount.Id;
                bankTransactions.add(bankTransaction);
                
                bankTransaction = new Bank_Transaction__c();
                bankTransaction.Amount__c = 3000.00;
                bankTransaction.Currency__c = TestFuel.currencyUSD.id;
                bankTransaction.Bank_Account__c = bankAccount.Id;
                bankTransaction.Company__c = company.Id;
                bankTransaction.Transaction_Type__c = 'Debit';
                bankTransaction.Reference_Number__c = '123s44567mnK';
                bankTransaction.Source__c = 'Yodlee';
                bankTransaction.Transacted_With__c = 'HDFC';
                bankTransaction.Transaction_Date__c = System.now();
                bankTransaction.Payment_Method__c = 'Check';
                bankTransaction.SubTransaction_Type__c = 'Debit';  
                bankTransaction.Bank_Account__c = bankAccount.Id;              
                bankTransactions.add(bankTransaction);
                
                bankTransaction = new Bank_Transaction__c();
                bankTransaction.Amount__c = -3000.00;
                bankTransaction.Currency__c = TestFuel.currencyUSD.id;
                bankTransaction.Bank_Account__c = bankAccount.Id;
                bankTransaction.Company__c = company.Id;
                bankTransaction.Transaction_Type__c = 'Credit';
                bankTransaction.Reference_Number__c = '123s44567mnL';
                bankTransaction.Source__c = 'Yodlee';
                bankTransaction.Transacted_With__c = 'KPMG';
                bankTransaction.Transaction_Date__c = System.now();
                bankTransaction.Payment_Method__c = 'Cash';
                bankTransaction.SubTransaction_Type__c = 'Credit';  
                bankTransaction.Bank_Account__c = bankAccount.Id;              
                bankTransactions.add(bankTransaction);
                insert bankTransactions;
            }
            return bankTransactions;
        }
        set;
    }
    
    public list<Customer_Receipt__c> customerReceipts{
        get{
            if(customerReceipts == null){
                customerReceipts = new list<Customer_Receipt__c>();
                
                Customer_Receipt__c customerReceipt = new Customer_Receipt__c();
                customerReceipt.Amount_Received__c = 3000.00;
                customerReceipt.Amount_Unapplied__c = 0;
                customerReceipt.Payment_Method_G__c = 'Wire';
                customerReceipt.Company__c = company.Id;
                customerReceipt.Customer__c = customerbillto.Id;
                customerReceipt.Date_Received__c = system.now();
                customerReceipt.Currency__c = TestFuel.currencyUSD.id;
                customerReceipt.exception__c = false;
                customerReceipt.Reference_Number__c = '123s44567mnJ';
                customerReceipt.Bank_Account_2__c = bankAccount.Id;
                customerReceipt.Type__c = 'Prepayment';
                customerReceipt.transaction_date__c = system.now();
                customerReceipt.Deposit_Identifier__c = 'deposit id';

                customerReceipts.add(customerReceipt);    
        
                Customer_Receipt__c customerReceipt2 = new Customer_Receipt__c();
                customerReceipt2.Amount_Received__c = 2000.00;
                customerReceipt2.Amount_Unapplied__c = 0;
                customerReceipt2.Payment_Method_G__c = 'Credit card';
                customerReceipt2.Company__c = company.Id;
                customerReceipt2.Customer__c = customerbillto.Id;
                customerReceipt2.Date_Received__c = system.now();
                customerReceipt2.Currency__c = TestFuel.currencyUSD.id;
                customerReceipt2.exception__c = false;
                customerReceipt2.Reference_Number__c = '123s44567mnJ';
                customerReceipt2.Bank_Account_2__c = bankAccount.Id;
                customerReceipt.Type__c = 'Prepayment';
                customerReceipt2.transaction_date__c = system.now();
                
                customerReceipts.add(customerReceipt2);
        
                insert customerReceipts;
            }
            return customerReceipts;
        }
        set;
    }
    
     public list<Customer_Receipt_Line__c> customerReceiptLines{
        get{
            if(customerReceiptLines == null){
                customerReceiptLines = new list<Customer_Receipt_Line__c>();           
                Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();
                additionalPayment.Amount__c = 2000;
                additionalPayment.Customer_Receipt__c = customerReceipts[0].Id;
                additionalPayment.Type__c = PaymentService.TYPE_PREPAYMENT;                 
                customerReceiptLines.add(additionalPayment);    
                        
                Customer_Receipt_Line__c additionalPayment2 = new Customer_Receipt_Line__c();
                additionalPayment2.Amount__c = 1000;
                additionalPayment2.Customer_Receipt__c = customerReceipts[0].Id;
                additionalPayment2.Type__c = PaymentService.TYPE_PREPAYMENT;            
                customerReceiptLines.add(additionalPayment2);
                
                Customer_Receipt_Line__c additionalPayment3 = new Customer_Receipt_Line__c();
                additionalPayment3.Amount__c = 1500;
                additionalPayment3.Customer_Receipt__c = customerReceipts[1].Id;
                additionalPayment3.Type__c = PaymentService.TYPE_PREPAYMENT;                    
                customerReceiptLines.add(additionalPayment3); 
                
                Customer_Receipt_Line__c additionalPayment4 = new Customer_Receipt_Line__c();
                additionalPayment4.Amount__c = 500;
                additionalPayment4.Customer_Receipt__c = customerReceipts[1].Id;
                additionalPayment4.Type__c = PaymentService.TYPE_PREPAYMENT;                    
                customerReceiptLines.add(additionalPayment4);
                
                insert customerReceiptLines;
            }
            return customerReceiptLines;
        }
        set;
    }
    
    public list<Accounting_Entry__c> accountingEntries{
        get{
            if(accountingEntries == null){
                accountingEntries = new list<Accounting_Entry__c>();           
                Accounting_Entry__c accountingEntry = new Accounting_Entry__c();
                accountingEntry.source_document_object_name__c = 'Customer_Receipt__c';
                accountingEntry.Company__c = company.Id;
                accountingEntry.Customer_Receipt__c = customerReceipts[0].Id;
                accountingEntry.name = 'One';   
                accountingEntry.Status__c = 'Active';
                accountingEntry.Transaction_Type__c = 'Std';            
                accountingEntries.add(accountingEntry);    
                        
                Accounting_Entry__c accountingEntry1 = new Accounting_Entry__c();
                accountingEntry1.source_document_object_name__c = 'Customer_Receipt__c';
                accountingEntry1.Company__c = company.Id;
                accountingEntry1.Customer_Receipt__c = customerReceipts[1].Id;
                accountingEntry1.name = 'Two';  
                accountingEntry1.Status__c = 'Active';
                accountingEntry1.Transaction_Type__c = 'Std';               
                accountingEntries.add(accountingEntry1);  
                
                insert accountingEntries;
            }
            return accountingEntries;
        }
        set;
    }
     public list<Journal_Entry_Line__c> journalEntryLines{
        get{
            if(journalEntryLines == null){
                list<Journal_Entry__c> lstJournalEntry = new list<Journal_Entry__c>();
                
                Journal_Entry__c journalEntry = new Journal_Entry__c();
                journalEntry.name = 'JE001';
                journalEntry.Company__c = company.id;   
                journalEntry.type__c = 'Bank Transaction';   
                journalEntry.Transaction_Type__c = 'Manual';
                journalEntry.Transaction_Date__c = system.now(); 
                journalEntry.Period__c = periodList[0].Id;
                journalEntry.Currency__c = TestFuel.currencyUSD.id;
                lstJournalEntry.add(journalEntry);
            
                Journal_Entry__c journalEntry2 = new Journal_Entry__c();
                journalEntry2.name = 'JE001';
                journalEntry2.Company__c = company.id;  
                journalEntry2.type__c = 'Bank Transaction';   
                journalEntry2.Transaction_Type__c = 'Manual';
                journalEntry.Transaction_Date__c = system.now();  
                journalEntry2.Currency__c = TestFuel.currencyUSD.id;
                journalEntry2.Period__c = periodList[0].Id;
                lstJournalEntry.add(journalEntry2);
                
                insert lstJournalEntry;    
            
                journalEntryLines = new List<Journal_Entry_Line__c>();
            
                Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
                jeLine1.Journal_Entry__c = lstJournalEntry[0].id;
                jeLine1.Amount_CR__c = 1000.00;
                jeLine1.GL_Account__c = cashGL.id;
                jeLine1.Bank_Transaction__c = bankTransactions[0].Id;
                jeLine1.Subtransaction_Type__c = 'Write Off';
                journalEntryLines.add(jeLine1); 
                
                Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
                jeLine2.Journal_Entry__c = lstJournalEntry[0].id;
                jeLine2.Amount_DR__c = 1000.00;
                jeLine2.GL_Account__c = cashGL.id;
                jeLine2.Subtransaction_Type__c = 'Write Off';
                journalEntryLines.add(jeLine2); 
                
                
                Journal_Entry_Line__c jeLine3 = new Journal_Entry_Line__c(); 
                jeLine3.Journal_Entry__c = lstJournalEntry[1].id;
                jeLine3.Amount_DR__c = 500.00;
                jeLine3.GL_Account__c = cashGL.id;
                jeLine3.Subtransaction_Type__c = 'Write Off';
                journalEntryLines.add(jeLine3); 
                
                Journal_Entry_Line__c jeLine4 = new Journal_Entry_Line__c(); 
                jeLine4.Journal_Entry__c = lstJournalEntry[1].id;
                jeLine4.Amount_CR__c = 500.00;
                jeLine4.GL_Account__c = cashGL.id;
                jeLine4.Bank_Transaction__c = bankTransactions[1].Id;
                jeLine4.Subtransaction_Type__c = 'Write Off';
                journalEntryLines.add(jeLine4); 
            
            insert journalEntryLines;
            journalEntry.Finalized__c = true;  
            journalEntry2.Finalized__c = true;  
            update lstJournalEntry;
            
           }
            return journalEntryLines;
        }
        set;
    }
    
    public list<Accounting_Entry_Line__c> JEAccountingEntriesLines{
        get{
            if(JEAccountingEntriesLines == null){
                list<Accounting_Entry__c> JEAccountingEntries = new list<Accounting_Entry__c>();           
                Accounting_Entry__c accountingEntry = new Accounting_Entry__c();
                accountingEntry.Company__c = company.Id;
                accountingEntry.Journal_Entry__c = journalEntryLines[0].Journal_Entry__c;
                accountingEntry.source_document_object_name__c = 'Journal_Entry__c';
                accountingEntry.name = 'One';   
                accountingEntry.Status__c = 'Active';
                accountingEntry.Transaction_Type__c = 'Std';            
                JEAccountingEntries.add(accountingEntry);    
                        
                Accounting_Entry__c accountingEntry1 = new Accounting_Entry__c();
                accountingEntry1.Company__c = company.Id;
                accountingEntry1.Journal_Entry__c = journalEntryLines[2].Journal_Entry__c;
                accountingEntry1.source_document_object_name__c = 'Journal_Entry__c';
                accountingEntry1.name = 'Two';  
                accountingEntry1.Status__c = 'Active';
                accountingEntry1.Transaction_Type__c = 'Std';               
                JEAccountingEntries.add(accountingEntry1);  
                
                insert JEAccountingEntries;
                
                JEAccountingEntriesLines = new list<Accounting_Entry_Line__c>();   
                Accounting_Entry_Line__c accountingEntryLine = new Accounting_Entry_Line__c();
                accountingEntryLine.Amount_CR__c = 1000;
                accountingEntryLine.Amount_DR__c = 0;
                accountingEntryLine.GL_Account__c = cashGL.id; 
                accountingEntryLine.Transaction_Date__c = system.today();
                accountingEntryLine.Accounting_Entry__c = JEAccountingEntries[0].id;
                accountingEntryLine.Journal_Entry_Line__c = journalEntryLines[0].id;
                accountingEntryLine.Company__c = company.Id;
                JEAccountingEntriesLines.add(accountingEntryLine);
                
                Accounting_Entry_Line__c accountingEntryLine2 = new Accounting_Entry_Line__c();
                accountingEntryLine2.Amount_DR__c = 1000;
                accountingEntryLine2.Amount_CR__c = 0;
                accountingEntryLine2.GL_Account__c = cashGL.id; 
                accountingEntryLine2.Transaction_Date__c = system.today();
                accountingEntryLine2.Accounting_Entry__c = JEAccountingEntries[0].id;
                accountingEntryLine2.Journal_Entry_Line__c = journalEntryLines[1].id;
                accountingEntryLine2.Company__c = company.Id;
                JEAccountingEntriesLines.add(accountingEntryLine2);
                
                Accounting_Entry_Line__c accountingEntryLine3 = new Accounting_Entry_Line__c();
                accountingEntryLine3.Amount_CR__c = 500;
                accountingEntryLine3.Amount_DR__c = 0;
                accountingEntryLine3.GL_Account__c = cashGL.id; 
                accountingEntryLine3.Transaction_Date__c = system.today();
                accountingEntryLine3.Accounting_Entry__c = JEAccountingEntries[1].id;
                accountingEntryLine3.Journal_Entry_Line__c = journalEntryLines[2].id;
                accountingEntryLine3.Company__c = company.Id;
                JEAccountingEntriesLines.add(accountingEntryLine3);
                
                Accounting_Entry_Line__c accountingEntryLine4 = new Accounting_Entry_Line__c();
                accountingEntryLine4.Amount_DR__c = 500;
                accountingEntryLine4.Amount_CR__c = 0;
                accountingEntryLine4.GL_Account__c = cashGL.id; 
                accountingEntryLine4.Transaction_Date__c = system.today();
                accountingEntryLine4.Accounting_Entry__c = JEAccountingEntries[1].id;
                accountingEntryLine4.Journal_Entry_Line__c = journalEntryLines[3].id;
                accountingEntryLine4.Company__c = company.Id;
                JEAccountingEntriesLines.add(accountingEntryLine4);
                
                insert JEAccountingEntriesLines;
            }
            return JEAccountingEntriesLines;
        }
        set;
    }
    
     public list<Supplier_Payment__c> supplierPayments{
        get{
            if(supplierPayments == null){
                supplierPayments = new list<Supplier_Payment__c>();
                Payment_Term__c paymentTermInfo = new Payment_Term__c();
                paymentTermInfo.due_days__c = 30;
                paymentTermInfo.discount_days__c = 30;
                paymentTermInfo.Discount_Percent__c = 10.0;
                insert paymentTermInfo;
                
                map <string,string> rtMap1 = KSE.RecordTypeDevNameMap('Supplier__c');
                
                //Create Supplier, assign remit and payment terms info
                Supplier__c supplier = new Supplier__c();
                supplier.Name = 'Test';
                supplier.Payment_Term__c = paymentTermInfo.Id;
                supplier.Payment_Method_G__c = 'Check';
                supplier.Company__c = company.Id;
                supplier.Status__c = 'Active';
                supplier.Type__c = 'Remit-To';
                supplier.RecordTypeId = rtMap1.get('Remit_To');
                insert supplier;
                
                Supplier_Payment__c suppPay1 = new Supplier_Payment__c();
                suppPay1.Payment_Amount__c = 2000.00;
                suppPay1.Date_Paid__c = system.now();
                suppPay1.transaction_date__c = system.now();
                suppPay1.Payment_Method_G__c = 'Check';
                suppPay1.Bank_Account__c = bankAccount.id ;
                suppPay1.Company__c = company.Id;
                suppPay1.Finalized__c = true;
                suppPay1.finalized_date__c = system.now();
                suppPay1.Supplier__c = supplier.Id;
                suppPay1.Currency__c = TestFuel.currencyUSD.id;
                suppPay1.historical__c = false;
                //KNDY-17923 - deperecated 'Check_Number__c' 
                //suppPay1.Check_Number__c = 8987; 
                suppPay1.Reference__c = '8987'; 
                supplierPayments.add(suppPay1);
                
                Supplier_Payment__c suppPay2 = new Supplier_Payment__c();
                suppPay2.Payment_Amount__c = 1000;
                suppPay2.Date_Paid__c = system.now();
                suppPay2.transaction_date__c = system.now();
                suppPay2.Payment_Method_G__c = 'Check';
                suppPay2.Bank_Account__c = bankAccount.id ;
                suppPay2.Company__c = company.Id;
                suppPay2.Finalized__c = true;
                suppPay2.finalized_date__c = system.now();
                suppPay2.Supplier__c = supplier.Id;
                suppPay2.Currency__c = TestFuel.currencyUSD.id;
                //KNDY-17923 - deperecated 'Check_Number__c' 
                //suppPay2.Check_Number__c = 8987;
                suppPay2.Reference__c = '8987';
                suppPay2.historical__c = false;
                supplierPayments.add(suppPay2);
        
                insert supplierPayments;
            }
            return supplierPayments;
        }
        set;
    }
     public list<Accounting_Entry__c> SPAccountingEntries{
        get{
            if(SPAccountingEntries == null){
                SPAccountingEntries = new list<Accounting_Entry__c>();           
                Accounting_Entry__c accountingEntry = new Accounting_Entry__c();
                accountingEntry.Company__c = company.Id;
                accountingEntry.Supplier_Payment__c = supplierPayments[0].Id;
                accountingEntry.name = 'One';   
                accountingEntry.Status__c = 'Active';
                accountingEntry.Transaction_Type__c = 'Std';            
                SPAccountingEntries.add(accountingEntry);    
                        
                Accounting_Entry__c accountingEntry1 = new Accounting_Entry__c();
                accountingEntry1.Company__c = company.Id;
                accountingEntry1.Supplier_Payment__c = supplierPayments[1].Id;
                accountingEntry1.name = 'Two';  
                accountingEntry1.Status__c = 'Active';
                accountingEntry1.Transaction_Type__c = 'Std';               
                SPAccountingEntries.add(accountingEntry1);  
                
                insert SPAccountingEntries;
            }
            return SPAccountingEntries;
        }
        set;
    }
    
    public Invoice__c intercompanyInvestmentInvoice{
        get{
            if(intercompanyInvestmentInvoice == null){
                
                intercompanyInvestmentInvoice = new Invoice__c();
                intercompanyInvestmentInvoice.From_Company__c = altCompany.Id;
                intercompanyInvestmentInvoice.To_Company__c = company.Id;
                intercompanyInvestmentInvoice.Currency__c = TestFuel.currencyUSD.id;
                intercompanyInvestmentInvoice.Transaction_Date__c = system.now();
                intercompanyInvestmentInvoice.Type__c = 'Intercompany Investment';
                intercompanyInvestmentInvoice.Transaction_Type__c = 'Intercompany Investment';
                
                DML.insertAsSystem(intercompanyInvestmentInvoice);
                
                Invoice_Line__c invLine = new Invoice_Line__c();
                invLine.Invoice__c = intercompanyInvestmentInvoice.Id;
                invLine.Extended_Amount__c = 10000;
                
                DML.insertAsSystem(invLine);
            }
            return intercompanyInvestmentInvoice;
        }
        set;
    }
    
    public Payment__c intercompanyPayment{
        get{
            if(intercompanyPayment == null){
                
                intercompanyPayment = new Payment__c();
                intercompanyPayment.From_Company__c = company.Id;
                intercompanyPayment.To_Company__c = altCompany.Id;
                intercompanyPayment.Currency__c = TestFuel.currencyUSD.id;
                intercompanyPayment.Transaction_Date__c = system.now();
                intercompanyPayment.Type__c = 'Intercompany Payment';
                intercompanyPayment.Transaction_Type__c = 'Intercompany Payment';
                DML.insertAsSystem(intercompanyPayment);
                
                Payment_Line__c pml = new Payment_Line__c();
                pml.Payment__c = intercompanyPayment.Id;
                pml.Amount__c = 10000;
                pml.Type__c = 'Intercompany Payment';
                DML.insertAsSystem(pml);
                
                Payment_Match__c pm = new Payment_Match__c();
                pm.Type__c = pml.Type__c;
                pm.Amount__c = pml.Amount__c;
                pm.Invoice__c = intercompanyInvestmentInvoice.Id;
                pm.Payment_Line__c = pml.Id;
                DML.insertAsSystem(pm);
                
            }
            return intercompanyPayment;
        }
        set;
    }
    
     public Payment__c intercompanyPayment1{
        get{
            if(intercompanyPayment1 == null){
                
                intercompanyPayment1 = new Payment__c();
                intercompanyPayment1.From_Company__c = company.Id;
                intercompanyPayment1.To_Company__c = altCompany.Id;
                intercompanyPayment1.Currency__c = TestFuel.currencyUSD.id;
                intercompanyPayment1.Transaction_Date__c = system.now();
                intercompanyPayment1.Type__c = 'Intercompany Payment';
                intercompanyPayment1.Transaction_Type__c = 'Intercompany Payment';
                DML.insertAsSystem(intercompanyPayment1);
                
                Payment_Line__c pml = new Payment_Line__c();
                pml.Payment__c = intercompanyPayment1.Id;
                pml.Amount__c = 10000;
                pml.Type__c = 'Intercompany Payment';
                DML.insertAsSystem(pml);
                
                Payment_Match__c pm = new Payment_Match__c();
                pm.Type__c = pml.Type__c;
                pm.Amount__c = pml.Amount__c;
                pm.Invoice__c = intercompanyInvestmentInvoice.Id;
                pm.Payment_Line__c = pml.Id;
                DML.insertAsSystem(pm);
                
            }
            return intercompanyPayment1;
        }
        set;
    }

    public Map<String, Reason_Code__c> reasonCodes {
        get {
            if (reasonCodes == null) {
                reasonCodes = new Map<String, Reason_Code__c>();
                reasonCodes.put('Change', new Reason_Code__c(Name = 'Change', Type__c = 'Inventory Change'));
                reasonCodes.put('Transfer', new Reason_Code__c(Name = 'Transfer', Type__c = 'Inventory Transfer'));
                reasonCodes.put('Cycle', new Reason_Code__c(Name = 'Cycle', Type__c = 'Cycle Count'));
                reasonCodes.put('WO', new Reason_Code__c(Name = 'WO', Type__c = 'Work Order'));
                insert reasonCodes.values();
            }
            return reasonCodes;
        } set;
    }

    public list<Accounting_Entry__c> InterCompanyAccountingEntries{
        get{
            if(InterCompanyAccountingEntries == null){
                InterCompanyAccountingEntries = new list<Accounting_Entry__c>();
                Accounting_Entry__c accountingEntry = new Accounting_Entry__c();
                accountingEntry.Company__c = company.Id;
                accountingEntry.Payment__c = intercompanyPayment.Id;
                accountingEntry.name = 'One';
                accountingEntry.Status__c = 'Active';
                accountingEntry.Transaction_Type__c = 'Std';
                InterCompanyAccountingEntries.add(accountingEntry);
                insert InterCompanyAccountingEntries;
            }
            return InterCompanyAccountingEntries;
        }
        set;
    }

    public list<Customer_Receipt__c> RefundCustomerReceipt{
    	get{
    		if(RefundCustomerReceipt == null){
    			RefundCustomerReceipt = new list<Customer_Receipt__c>();
    			Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		        custReceipt.Customer__c = customerBillTo.Id;
		        custReceipt.Company__c = company.Id;

		        custReceipt.Currency__c = company.Default_Transaction_Currency__c;
		        custReceipt.Bank_Account_2__c = bankAccount.Id;

		        custReceipt.Amount_Received__c = -1 * 200;
		        custReceipt.Type__c = 'Refund';
		        custReceipt.Transaction_Date__c = system.now();
		        custReceipt.Date_Received__c = system.now();
		        custReceipt.Payment_Method_G__c = 'Check';
		        RefundCustomerReceipt.add(custReceipt);
		        insert RefundCustomerReceipt;
    		}
    		return RefundCustomerReceipt;
    	}
    	set;
    }


    public list<Accounting_Entry__c> RefundCRAccountingEntries{
        get{
            if(RefundCRAccountingEntries == null){
                RefundCRAccountingEntries = new list<Accounting_Entry__c>();
                Accounting_Entry__c accountingEntry = new Accounting_Entry__c();
                accountingEntry.Company__c = company.Id;
                accountingEntry.Customer_Receipt__c = RefundCustomerReceipt[0].Id;
                accountingEntry.name = 'One';
                accountingEntry.Status__c = 'Active';
                accountingEntry.Transaction_Type__c = 'Std';
                RefundCRAccountingEntries.add(accountingEntry);
                insert RefundCRAccountingEntries;
            }
            return RefundCRAccountingEntries;
        }
        set;
    }
    public Product__c packageProduct {
        get {
            if (packageProduct == null) {
                packageProduct = new Product__c(
                    Company__c = company.Id,
                    Name = 'Package Product',
                    Item__c = itemList[14].Id,
                    Description__c = 'Package Product',
                    Selling_UOM__c = uomList[11].Id
                );
                insert packageProduct;
            }
            return packageProduct;
        } set;
    }
    
    public Sales_Order__c packageSalesOrder {
        get {
            if (packageSalesOrder == null) {
                packageSalesOrder = newSalesOrder();
                packageSalesOrder.Bill_To__c = customerBillTo.Id;
                packageSalesOrder.Original_Sales_Order__c = 'packageSalesOrder'; 
                insert packageSalesOrder;

                System.assert(packageSalesOrderLine != null);
            }
            return packageSalesOrder;
        } set;
    }
    
    public Sales_Order_Line__c packageSalesOrderLine {
        get {
            if (packageSalesOrderLine == null) {
                packageSalesOrderLine = new Sales_Order_Line__c(
                    Company__c = company.Id,
                    Description__c = product.Description__c,
                    Discount_Percent__c = 0,
                    Product__c = packageProduct.Id,
                    Quantity_Ordered__c = 10,
                    Required_Date__c = System.today() + 5,
                    Sales_Order__c = packageSalesOrder.Id,
                    Ship_From_Location__c = location2.Id,
                    Unit_Price__c = 0,
                    Memo__c = 'packageSalesOrderLine',
                    Selling_UOM__c = uomList[11].Id
                );
                insert packageSalesOrderLine;
            }
            return packageSalesOrderLine;
        } set;
    }
}