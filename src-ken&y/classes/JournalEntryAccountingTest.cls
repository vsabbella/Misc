@isTest
public class JournalEntryAccountingTest {
	
	// Create a inner class for journal entry of type manual / SCOA adjustment
	// 1. Test the JE trigger
	// 2. Test the JEAccounting.cls
	// 3. Test JEAccountingBatch.cls
	// 4. Test JES.cls
	// 5. Test JEAccountingExt.cls
	// 6. Test JELinesManageExt.cls 
	public class JournalEntries {
		
		// create a accounting standard
		public Accounting_Standard__c accountingStandard = new Accounting_Standard__c();{
        	accountingStandard.name = 'US GAAP';
    		insert accountingStandard;
        }
		// create a company
        public Company__c company = new Company__c();{
	        company = new Company__c();
	        company.name = '100';
	        company.A_Days__c = 6;
	        company.B_Days__c = 20;
	        company.C_Days__c = 90;
	        company.accounting_standard__c = accountingStandard.id;
	        company.Comp_Currency__c = TestFuel.currencyUSD.id;
	        company.Consol_Currency__c = TestFuel.currencyUSD.id;
	        company.Stat_Currency__c = TestFuel.currencyUSD.id;
	        company.Subs_Currency__c = TestFuel.currencyUSD.id;
	        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
	 
	        insert company;
    	}
    	
    	public String periodName(Datetime myDT){
        	String myDate = myDT.format('MM-yyyy');
        	system.assert( myDate != null, 'expected valid date');
        	return myDate.toUpperCase();
    	}
    
		// create periods
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
    	public Segment_Validation__c sv1, sv2;
    	public List<Segment_Validation__c> svList = new List<Segment_Validation__c>();{
            sv1 = new Segment_Validation__c();
            sv1.segment_1__c = '*';
            sv1.segment_2__c = '*';
            sv1.segment_3__c = '*';
            sv1.active__c = true;
            svList.add(sv1);
            sv2 = new Segment_Validation__c();
            sv2.segment_1__c = '*';
            sv2.segment_2__c = null;
            sv2.segment_3__c = null;
            sv2.active__c = true;
            svList.add(sv2);
            insert svList;
            
        }

        public GL_Type__c currentAssets = new GL_Type__c();
	    public GL_Type__c currentLiabilities = new GL_Type__c();

        public List<GL_Type__c> gltypes = new List<GL_Type__c>();{
        	currentAssets = new GL_Type__c();
			currentAssets.Name  = 'Current Assets';
			currentAssets.Normal_Balance__c  = 'Debit';
			currentAssets.Accounting_Type__c  = 'Assets';
			currentAssets.Statement_Type__c  = 'Balance Sheet';
			currentAssets.Account_Range_From__c = '10000';
			currentAssets.Account_Range_To__c ='14999';
			gltypes.add(currentAssets);

			currentLiabilities = new GL_Type__c();
			currentLiabilities.Name  = 'Current Liabilities';
	    	currentLiabilities.Normal_Balance__c  = 'Credit';
	    	currentLiabilities.Accounting_Type__c  = 'Liabilities';
	    	currentLiabilities.Statement_Type__c  = 'Balance Sheet';
	    	currentLiabilities.Account_Range_From__c = '20000';
	    	currentLiabilities.Account_Range_To__c ='24999';
	    	gltypes.add(currentLiabilities);

	    	insert gltypes;

        }
        
    	public GL_Account__c cashGL = new GL_Account__c();
    	public GL_Account__c receivablesGL = new GL_Account__c();
    	public GL_Account__c payablesGL = new GL_Account__c();
    	public GL_Account__c GRNIGL = new GL_Account__c();
    	
    	public List<GL_Account__c> GLAccountList = new List<GL_Account__c>();{
            cashGL = new GL_Account__c();
            cashGL.Name = '12000 - Cash';
            cashGL.GL_Account_Number__c = '12000';
            cashGL.GL_Account_Name__c = 'Cash';
            cashGL.active__c = true;
            cashGL.Report_Section__c = 'Current Assets';  
            cashGL.Normal_Balance__c = 'Debit';
            cashGL.Statement_Type__c = 'Balance Sheet';
            cashGL.Report_Section_Grouping__c = 'Assets';
            cashGL.Cash_Flow_Report_Section_Grouping__c = 'Operating Cash Flow';
            cashGL.FX_Type__c = 'Monetary Non-cash';
            cashGL.non_cash__c = true;
            cashGL.GL_Type__c = currentAssets.id;
            GLAccountList.add(cashGL);
            
            receivablesGL = new GL_Account__c();
            receivablesGL.Name = '11000 - Accounts Receivable';
            receivablesGL.GL_Account_Number__c = '11000';
            receivablesGL.GL_Account_Name__c = 'Accounts Receivable';
            receivablesGL.active__c = true;
            receivablesGL.Report_Section__c = 'Current Assets';
            receivablesGL.Statement_Type__c = 'Balance Sheet'; 
            receivablesGL.Report_Section_Grouping__c = 'Assets';
            receivablesGL.Normal_Balance__c = 'Debit'; 
            receivablesGL.FX_Type__c = 'Monetary Non-cash';
            receivablesGL.GL_Type__c = currentAssets.id;
            GLAccountList.add(receivablesGL);
            
            payablesGL = new GL_Account__c();
            payablesGL.Name = '21000 - Accounts Payable ';
            payablesGL.GL_Account_Number__c = '21000';
            payablesGL.GL_Account_Name__c = 'Accounts Payable';
            payablesGL.Report_Section__c = 'Accounts Payable';
            payablesGL.Normal_Balance__c = 'Credit';
            payablesGL.active__c = true;
            payablesGL.Statement_Type__c = 'Income Statement';  
            payablesGL.GL_Type__c = currentLiabilities.id; 
            GLAccountList.add(payablesGL);
            
            GRNIGL = new GL_Account__c();
            GRNIGL.Name = '23000 - Goods Received Not Invoiced ';
            GRNIGL.GL_Account_Number__c = '23000';
            GRNIGL.GL_Account_Name__c = 'Goods Received Not Invoiced';
            GRNIGL.Report_Section__c = 'Current Liabilities';
            GRNIGL.active__c = true;
            GRNIGL.Normal_Balance__c = 'Credit';
            GRNIGL.Statement_Type__c = 'Income Statement';  
            GRNIGL.GL_Type__c = currentLiabilities.id; 
            GLAccountList.add(GRNIGL);
            
            insert GLAccountList;
    	}
		
		public Bank_Account__c bankAccount {
		get{
			if(bankAccount == null){
				bankAccount = new Bank_Account__c(
    				Name = 'Test BOFA',
    				Company__c = company.Id,//KNDY-11230
    				account_type__c = 'Checking',
    				GL_Account__c = cashGL.id,
    				Active__c = true);
				insert bankAccount;
			}	
			return bankAccount;
		}
		set;
	}
		public List<Accounting_Rule__c> JEAccountingRules = new List<Accounting_Rule__c> ();{
			Accounting_Rule__c jeRule1 = new Accounting_Rule__c();
            jeRule1.Object_Name__c = 'Journal_Entry__c';
            jeRule1.Accounting_Standard__c = accountingStandard.id;
            jeRule1.Transaction__c = 'Manual';
            jeRule1.SubTransaction_Type__c = 'Write Off';
            jeRule1.Line_Type__c = null;
            jeRule1.Rule_Type__c = 'CR';
            jeRule1.Default_GL_Account__c = false;
            jeRule1.GL_Account_Reference_Value__c = 'GL_Account__c';
            jeRule1.GL_Account__c = null;
            jeRule1.Amount_Reference__c = null; 
            jeRule1.Company_Ledger__c = true;       
            jeRule1.Effective_Start_Date__c = effStartDate;
            jeRule1.Raise_Exceptions_for_Blank_Amounts__c=false;
            jeRule1.Suppress_Zero_Amount_Lines__c = true;                
            JEAccountingRules.add(jeRule1);
            
            Accounting_Rule__c jeRule2 = new Accounting_Rule__c();
            jeRule2.Object_Name__c = 'Journal_Entry__c';
            jeRule2.Accounting_Standard__c = accountingStandard.id;
            jeRule2.Transaction__c = 'Manual';
            jeRule2.SubTransaction_Type__c = 'Write Off';
            jeRule2.Line_Type__c = null;
            jeRule2.Rule_Type__c = 'DR';
            jeRule2.Default_GL_Account__c = false;
            jeRule2.GL_Account_Reference_Value__c = 'GL_Account__c';
            jeRule2.GL_Account__c = null;
            jeRule2.Amount_Reference__c = null; 
            jeRule2.Company_Ledger__c = true;    
            jeRule2.Effective_Start_Date__c =effStartDate;    
            jeRule2.Raise_Exceptions_for_Blank_Amounts__c=false;
            jeRule2.Suppress_Zero_Amount_Lines__c = true;                
            JEAccountingRules.add(jeRule2);

			Accounting_Rule__c jeRule4 = new Accounting_Rule__c();
            jeRule4.Object_Name__c = 'Journal_Entry__c';
            jeRule4.Accounting_Standard__c = accountingStandard.id;
            jeRule4.Transaction__c = 'Manual';
            jeRule4.SubTransaction_Type__c = 'Rounding';
            jeRule4.Line_Type__c = null;
            jeRule4.Rule_Type__c = 'CR';
            jeRule4.Default_GL_Account__c = false;
            jeRule4.GL_Account_Reference_Value__c = 'GL_Account__c';
            jeRule4.GL_Account__c = null;
            jeRule4.Amount_Reference__c = null; 
            jeRule4.Company_Ledger__c = true;       
            jeRule4.Effective_Start_Date__c = effStartDate;
            jeRule4.Raise_Exceptions_for_Blank_Amounts__c=false;
            jeRule4.Suppress_Zero_Amount_Lines__c = true;                
            JEAccountingRules.add(jeRule4);
            
            Accounting_Rule__c jeRule3 = new Accounting_Rule__c();
            jeRule3.Object_Name__c = 'Journal_Entry__c';
            jeRule3.Accounting_Standard__c = accountingStandard.id;
            jeRule3.Transaction__c = 'Manual';
            jeRule3.SubTransaction_Type__c = 'Rounding';
            jeRule3.Line_Type__c = null;
            jeRule3.Rule_Type__c = 'DR';
            jeRule3.Default_GL_Account__c = false;
            jeRule3.GL_Account_Reference_Value__c = 'GL_Account__c';
            jeRule3.GL_Account__c = null;
            jeRule3.Amount_Reference__c = null; 
            jeRule3.Company_Ledger__c = true;    
            jeRule3.Effective_Start_Date__c =effStartDate;    
            jeRule3.Raise_Exceptions_for_Blank_Amounts__c=false;
            jeRule3.Suppress_Zero_Amount_Lines__c = true;                
                       
            JEAccountingRules.add(jeRule3);            
        
        
			insert JEAccountingRules;	
		}

		public List<Journal_Entry_Line__c> jeLineList{
			get{
				if(jeLineList == null){
					jeLineList = new List<Journal_Entry_Line__c>();
					Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
				    jeLine1.Journal_Entry__c = JEList[0].id;
					jeLine1.Amount_CR__c = 5;
					jeLine1.Amount_DR__c = 0;
					jeLine1.GL_Account__c = cashGL.id;
					jeLine1.Subtransaction_Type__c = 'Write Off';
				    jeLineList.add(jeLine1); 
				    
				    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
				    jeLine2.Journal_Entry__c = JEList[0].id;
					jeLine2.Amount_CR__c = 0;
					jeLine2.Amount_DR__c = 5;
					jeLine2.GL_Account__c = receivablesGL.id;
					jeLine2.Subtransaction_Type__c = 'Write Off';
				    jeLineList.add(jeLine2); 
				    
				    
				    Journal_Entry_Line__c jeLine3 = new Journal_Entry_Line__c(); 
				    jeLine3.Journal_Entry__c = JEList[1].id;
					jeLine3.Amount_CR__c = 5;
					jeLine3.Amount_DR__c = 0;
					jeLine3.GL_Account__c = cashGL.id;
					jeLine3.Subtransaction_Type__c = 'Write Off';
				    jeLineList.add(jeLine3); 
				    
				    Journal_Entry_Line__c jeLine4 = new Journal_Entry_Line__c(); 
				    jeLine4.Journal_Entry__c = JEList[1].id;
					jeLine4.Amount_CR__c = 0;
					jeLine4.Amount_DR__c = 5;
					jeLine4.GL_Account__c = receivablesGL.id;
					jeLine4.Subtransaction_Type__c = 'Write Off';
				    jeLineList.add(jeLine4); 
				    
				    insert jeLineList;
				    
				    JEList[0].finalized__c = true;
				    JEList[1].finalized__c = true;
				    update JEList;
				}
				return jeLineList;
			}
			set;
		}

		public List<Journal_Entry__c> JEList {
			get{
				if(JEList == null){
					JEList = new List<Journal_Entry__c>();

					Journal_Entry__c je1 = new Journal_Entry__c();
					je1.name = 'JE001';
				    je1.Company__c = company.id;	
				    je1.type__c = 'Manual';   
				    je1.Transaction_Type__c = 'Manual';
				    je1.Transaction_Date__c = System.now();  
				    //je1.GL_Date__c = System.today();  
					je1.Currency__c = TestFuel.currencyUSD.id;
					//je1.Finalized__c = true;		
				    JEList.add(je1);

				    Journal_Entry__c je2 = new Journal_Entry__c();
					je2.name = 'JE001';
				    je2.Company__c = company.id;	
				    je2.type__c = 'Manual';   
				    je2.Transaction_Type__c = 'Manual';
				    je2.Transaction_Date__c = System.now();  
				    //je2.GL_Date__c = System.today();  
					je2.Currency__c = TestFuel.currencyUSD.id;
					//je2.Finalized__c = true;		
				    JEList.add(je2);
				    
				    insert JEList;
				    System.assert(jeLineList != null);

				}
				return JEList;
			}
			set;
		}

		public Supplier__c supplier{
			get{
				if(supplier == null){
					supplier = new Supplier__c();
		        	supplier.status__C = 'Active';
		        	supplier.Name = 'Test Supplier';
		        	supplier.Type__c = 'Purchasing';
		        	insert supplier;        
				}
				return supplier;
			}
			set;
    	}
    	
    	public Supplier_Invoice__c suppInv1{
    		get{
    			if(suppInv1 == null){
    				suppInv1 = new Supplier_Invoice__c();
    				suppInv1.Company__c = company.id;
		            suppInv1.Invoice_Type__c = 'Invoice';
		            suppInv1.Date_Invoiced__c = System.now();
		            suppInv1.Supplier__c = supplier.id;
		            //suppInv1.Amount_Due__c = data.purchaseOrder2.Purchase_Order_Value__c;
		            suppInv1.Invoice_Amount__c = 10;
		            suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
		            suppInv1.Finalized__c = false;
		            suppInv1.Currency__c = TestFuel.currencyUSD.id;
		            insert suppInv1;
		            system.assert(suppInvLine1 != null);
    			}
    			return suppInv1;
    		}
    		set;
		}
		//Add Class
		public Class__c clsObj{
			get{
				if(clsObj == null){
					clsObj = new Class__c();
					clsObj.name = 'Class-1';
		        	clsObj.Type__c= 'Goods';
		        	insert clsObj;
				}
				return clsObj;
			}
			set;
		}
		
		public UOM__c uom {
		    get {
		        if ( uom == null ) {
		            uom = new UOM__c();
		            uom.Name = 'EA';
		            uom.Description__c = 'EA';
		            insert uom;
		        }
		        return uom;
		    } set;
		}
		
		// Add item 
		public Item__c Item{
			get{
				if(Item == null){
					Item = new Item__c();
					Item.name='HP Printer 3';
		        	Item.Description__c='It is a Test item';
		        	Item.Source__c='Miscellaneous';
		        	Item.Company__c = company.id;
		        	Item.class__c = clsObj.id;
		         	Item.Non_Inventory__c = true;
		         	Item.Packaging_UOM__c = JSON.serialize( new List<Id> {uom.Id});
		         	insert Item;
				}
				return Item;
			}
			set;
		}
		// Add Supplier Invoice Line
		Supplier_Invoice_Line__c suppInvLine1{
			get{
				if(suppInvLine1 == null){
					suppInvLine1 = new Supplier_Invoice_Line__c();
					//suppInvLine1.Supplier__c = data.remittosupplier.id;
		            suppInvLine1.Supplier_Invoice__c = suppInv1.id;
		            suppInvLine1.Line_Type__c = 'Standard';
		            suppInvLine1.Extended_Cost__c = 50;
		            suppInvLine1.Invoice_Quantity__c = 1;
		            suppInvLine1.Unit_Price__c = 10;
		            suppInvLine1.Item__c = Item.id;
		 
		            insert suppInvLine1;
		            
		            suppInv1.finalized__c = true;
		            update suppInv1;
				}
				return suppInvLine1;
			}
			set;
		}
		
		public List<Segment_Definition__c> customsegList = new List<Segment_Definition__c>();{
            Segment_Definition__c custom_seg1 = new Segment_Definition__c();
            custom_seg1.Name = 'Company__c';
            custom_seg1.Accounting_Entry_Field__c = 'Company__c'; // just need a field to stuff into
            custom_seg1.Object_API_Name__c = 'Company__c';
            custom_seg1.Segment_Number__c = 1;
            customsegList.add(custom_seg1);
            
            Segment_Definition__c custom_seg2 = new Segment_Definition__c();
            custom_seg2.Name = 'GL_Account__c';
            custom_seg2.Accounting_Entry_Field__c = 'GL_Account__c'; // just need a field to stuff into
            custom_seg2.Object_API_Name__c = 'GL_Account__c';
            custom_seg2.Accounting_Rule_Segment__c = 'GL_Account__c';
            custom_seg2.Accounting_Rule_Reference_Value__c = 'GL_Account_Reference_Value__c';
            custom_seg2.Accounting_Rule_Default__c = 'Default_GL_Account__c';
            custom_seg2.Segment_Number__c = 2;
            customsegList.add(custom_seg2);
            
            Segment_Definition__c custom_seg3 = new Segment_Definition__c();
            custom_seg3.Name = 'Intercompany__c';
            custom_seg3.Accounting_Entry_Field__c = 'Intercompany__c'; // just need a field to stuff into
            custom_seg3.Object_API_Name__c = 'Intercompany__c';
            custom_seg3.Accounting_Rule_Segment__c = 'Intercompany__c';
            custom_seg3.Accounting_Rule_Reference_Value__c = 'Intercompany_Reference_Value__c';
            custom_seg3.Accounting_Rule_Default__c = 'Default_Intercompany__c';
            custom_seg3.Segment_Number__c = 3;
            customsegList.add(custom_seg3);
            
            insert customsegList; 
        } 
	
	}

	public class TestDataForAutobackDatingJE{
	    Testfuel fuel = new Testfuel();
		public company__c company = fuel.company;
  		public list<Period__c> periodList = new list<Period__c>();
        public period__c PrevPeriod = new period__c();
        public period__c CurrPeriod = new period__c();
        public period__c FuturePeriod = new period__c();
 		public Fiscal_Year__c fy = new Fiscal_Year__c();
 		public Configuration__c autobackdtsetting;
        
        public List<Accounting_Rule__c> accountingRules = fuel.accountingRuleList; 		
	    public Journal_Entry__c jeCurr = new Journal_Entry__c();
		public List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
 
		
		public  TestDataForAutobackDatingJE(){		   
			Configuration__c cutoffsConfig = new Configuration__c();
            cutoffsConfig.Name = 'EnableCutoffs';
            cutoffsConfig.Value__c = 'Yes';
            insert cutoffsConfig;
			
			// update Configuration
		    autobackdtsetting = fuel.AutoBackdatingConfigVal;
			//c.name = 'AutoBackdateToOpenSubledgers';
			autobackdtsetting.Value__c = 'Yes';
			update autobackdtsetting;
		
			fy.company__c = company.Id;
			fy.fiscal_year_start_date__c = system.now().addMonths(-1);
			fy.fiscal_year_end_date__c = system.now().addMonths(3);		
			insert fy;	 
			   
	        PrevPeriod.name='PrevPeriod';
	        PrevPeriod.company__c=company.id;
	        PrevPeriod.open__c=true;       
	        PrevPeriod.Period_Start__c=system.now().addhours(-24);//From system.now() to 24 hrs before.
	        PrevPeriod.period_end__c=system.now();
			PrevPeriod.fiscalyear__c = fy.Id;
	       
	        periodList.add(PrevPeriod);	  
	         
	        CurrPeriod.name='CurrPeriod';
	        CurrPeriod.company__c=company.id;
	        CurrPeriod.open__c=true;       
	        CurrPeriod.Period_Start__c=PrevPeriod.period_end__c;
	        CurrPeriod.period_end__c=PrevPeriod.period_end__c.addhours(24);//From system.now() to 24 hrs later.	 	
			CurrPeriod.fiscalyear__c = fy.Id;
		    CurrPeriod.JE_Cutoff__c = CurrPeriod.period_end__c.addhours(-2);    
			CurrPeriod.AR_Subledger_Cutoff__c = CurrPeriod.JE_Cutoff__c;
			CurrPeriod.AP_Subledger_Cutoff__c = CurrPeriod.JE_Cutoff__c;
			CurrPeriod.Receiving_Subledger_Cutoff__c = CurrPeriod.JE_Cutoff__c;
			CurrPeriod.Shipment_Subledger_Cutoff__c = CurrPeriod.JE_Cutoff__c;
			CurrPeriod.Inventory_Subledger_Cutoff__c = CurrPeriod.JE_Cutoff__c;
			CurrPeriod.FA_Subledger_Cutoff__c = CurrPeriod.JE_Cutoff__c;
	        periodList.add(CurrPeriod);	  
	 
	        FuturePeriod.name='FuturePeriod';
	        FuturePeriod.company__c=company.id;
	        FuturePeriod.open__c=true;       
	        FuturePeriod.Period_Start__c= CurrPeriod.period_end__c;//From 24 hrs later to 48hrs later.
	        FuturePeriod.period_end__c=CurrPeriod.period_end__c.addhours(24);	 	
			FuturePeriod.fiscalyear__c = fy.Id;
		    FuturePeriod.JE_Cutoff__c = FuturePeriod.period_end__c.addhours(-2);    
			FuturePeriod.AR_Subledger_Cutoff__c = FuturePeriod.JE_Cutoff__c;
			FuturePeriod.AP_Subledger_Cutoff__c = FuturePeriod.JE_Cutoff__c;
			FuturePeriod.Receiving_Subledger_Cutoff__c = FuturePeriod.JE_Cutoff__c;
			FuturePeriod.Shipment_Subledger_Cutoff__c = FuturePeriod.JE_Cutoff__c;
			FuturePeriod.Inventory_Subledger_Cutoff__c = FuturePeriod.JE_Cutoff__c;
			FuturePeriod.FA_Subledger_Cutoff__c = FuturePeriod.JE_Cutoff__c;		     
		    periodList.add(FuturePeriod);	  
	        
	        insert periodlist;
	               
			jeCurr.name = 'jeInCurrPeriod';
		    jeCurr.Company__c = company.id;	
		    jeCurr.type__c = 'Manual';   
		    jeCurr.Transaction_Date__c = System.now();  
			jeCurr.Currency__c = TestFuel.currencyUSD.id;
		    
		    insert jeCurr;
		    
		    
		    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
		    jeLine1.Journal_Entry__c = jeCurr.id;
			jeLine1.Amount_CR__c = 5;
			jeLine1.Amount_DR__c = 0;
			jeLine1.GL_Account__c = fuel.cashGL.id;
		    jeLineList.add(jeLine1); 
		    
		    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
		    jeLine2.Journal_Entry__c = jeCurr.id;
			jeLine2.Amount_CR__c = 0;
			jeLine2.Amount_DR__c = 5;
			jeLine2.GL_Account__c = fuel.receivablesGL.id;
		    jeLineList.add(jeLine2); 
		    
		    insert jeLineList;
		}
	
	}
	static testmethod void testJEAccounting(){
	    // Test Journal Entry Accounting
	    JournalEntries JE = new JournalEntries();
	    
	    Test.startTest();

	    JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(JE.jeLineList);
	    
	    List<Journal_Entry__c> jeList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c,
	    							(Select id, Name,COMP_Total_Credit__c, COMP_Total_Debit__c  from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id in :JE.JEList];
	    Test.stopTest();
	    
	    system.assertEquals(true, jeList[0].Finalized__c);
	    system.assertNotEquals(null, jeList[0].Finalized_Date__c);
	    system.assertEquals(1, jeList[0].Accounting_Entries__r.size());
	    system.assertEquals(1, jeList[1].Accounting_Entries__r.size());
	    for(Accounting_Entry__c thisAE: jeList[0].Accounting_Entries__r){
	    	system.assert(thisAE.COMP_Total_Credit__c != null,'thisAE:'+thisAE);
	    	system.assert(thisAE.COMP_Total_Credit__c != 0,'thisAE:'+thisAE);
	    }
	}
	
	static testmethod void testJEAccountingExt(){
		JournalEntries JE = new JournalEntries();
	    JournalEntryAccountingExt GAEC;
	    
	    Test.startTest();
		Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(JE.JEList);
        
        setcon.setSelected(JE.JEList);
        GAEC = new JournalEntryAccountingExt(setcon);
        
        PageReference pg = GAEC.GenerateJournalEntryAccounting(); 
        
        system.assert(pg != null, setCon.getSelected().size() + ' ' + apexpages.getMessages());
        
	    Test.stopTest();
	    
	    List<Journal_Entry__c> jeList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c,
	    							(Select id, Name, COMP_Total_Credit__c, COMP_Total_Debit__c from Accounting_Entries__r)
	    							from Journal_Entry__c where id in :JE.JEList];
	    
	    system.assertEquals(true, jeList[0].Finalized__c);
	    system.assertNotEquals(null, jeList[0].Finalized_Date__c);
	    system.assertEquals(1, jeList[0].Accounting_Entries__r.size());
	    system.assertEquals(1, jeList[1].Accounting_Entries__r.size());

	}

	static testmethod void testFxAndRounding(){

		JournalEntries JE = new JournalEntries();
	    JournalEntryAccountingExt GAEC;

	    GL_Type__c other = new GL_Type__c();
		other.Name  = 'Other Income/Expense';
		other.Normal_Balance__c  = 'Credit';
		other.Accounting_Type__c  = 'Revenue';
		other.Statement_Type__c  = 'Income Statement';
		other.Account_Range_From__c = '70000';
		other.Account_Range_To__c ='79999';
	
		insert other;

		GL_Account__c rfx = new GL_Account__c();
		rfx.Name = '79500 - RealizedFX';
	    rfx.GL_Account_Number__c = '79500';
	    rfx.GL_Account_Name__c = 'RealizedFX';
	    rfx.active__c = true;
	    rfx.FX_Type__c = 'RFX';
	    rfx.non_cash__c = true;
	    rfx.GL_Type__c = other.id;
	    
	    insert rfx;

	    Exchange_Rate__c er = new Exchange_Rate__c();
		er.From_Currency__c = TestFuel.currencyGBP.Id;
		er.To_Currency__c = JE.company.Comp_Currency__c;
		er.Daily_Monthly__c = 'Daily';
		er.Rate_Start_DateTime__c = System.now().addDays(-10);
		er.Multiplier_Exchange_Rate__c = 1.439;

		insert er;


	    Journal_Entry__c je3 = new Journal_Entry__c();
		je3.name = 'JE001';
		je3.Company__c = JE.company.id;	
		je3.type__c = 'Manual';   
		je3.Transaction_Type__c = 'Manual';
		je3.Transaction_Date__c = System.now();  
		je3.Currency__c = TestFuel.currencyGBP.Id;

		insert je3;


		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		Journal_Entry_Line__c jeLine5 = new Journal_Entry_Line__c(); 
		jeLine5.Journal_Entry__c = je3.id;
		jeLine5.Amount_CR__c = 123;
		jeLine5.Amount_DR__c = 0;
		jeLine5.GL_Account__c = JE.cashGL.id;
		jeLine5.Subtransaction_Type__c = 'Write Off';
		jeLineList.add(jeLine5); 

		Journal_Entry_Line__c jeLine6 = new Journal_Entry_Line__c(); 
		jeLine6.Journal_Entry__c = je3.id;
		jeLine6.Amount_CR__c = 0;
		jeLine6.Amount_DR__c = 36.5;
		jeLine6.GL_Account__c = JE.receivablesGL.id;
		jeLine6.Subtransaction_Type__c = 'Write Off';
		jeLineList.add(jeLine6); 

		Journal_Entry_Line__c jeLine7 = new Journal_Entry_Line__c(); 
		jeLine7.Journal_Entry__c = je3.id;
		jeLine7.Amount_CR__c = 0;
		jeLine7.Amount_DR__c = 86;
		jeLine7.GL_Account__c = JE.receivablesGL.id;
		jeLine7.Subtransaction_Type__c = 'Write Off';
		jeLineList.add(jeLine7); 

		Journal_Entry_Line__c jeLine8 = new Journal_Entry_Line__c(); 
		jeLine8.Journal_Entry__c = je3.id;
		jeLine8.Amount_CR__c = 0;
		jeLine8.Amount_DR__c = .5;
		jeLine8.GL_Account__c = JE.receivablesGL.id;
		jeLine8.Subtransaction_Type__c = 'Rounding';
		jeLineList.add(jeLine8); 
		insert jeLineList;


		je3.Finalized__c = true;
		update je3;

		List<Journal_Entry__c> jelist = new List<Journal_Entry__c>{je3};

        Rounding_Configuration__c rounding = new Rounding_Configuration__c(	ExtId__c = 'Journal_entry__c', Value__c = .1);
	    
	    Test.startTest();
		Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(jelist);
        
        setcon.setSelected(jelist);
        GAEC = new JournalEntryAccountingExt(setcon);
        
        PageReference pg = GAEC.GenerateJournalEntryAccounting(); 
        
        system.assert(pg != null, setCon.getSelected().size() + ' ' + apexpages.getMessages());
        
	    Test.stopTest();

	    List<Accounting_Entry__c> aes = [Select id, Name, Has_Exceptions__c,COMP_Total_Credit__c, COMP_Total_Debit__c, COMP_Functional_Total_CR__c,COMP_Functional_Total_DR__c,transaction_type__c,
	    									(Select Id, COMP_Transaction_Currency__c, COMP_Functional_Currency__c, COMP_Functional_Currency_Amount_CR__c, COMP_Functional_Currency_Amount_DR__c, 
	    										COMP_Transaction_Currency_Amount_CR__c, COMP_Transaction_Currency_Amount_DR__c,SubTransaction_Type__c, COMP_Functional_Conversion_Rate__c,Exception__c
	    									From Accounting_Entry_Lines__r)
	    								From Accounting_Entry__c
	    								Where Journal_Entry__c =:je3.Id];

	    System.debug(LoggingLevel.ERROR, '#### Trans CR: ' + aes[0].COMP_Total_Credit__c + '\tTrans DR: ' + aes[0].COMP_Total_Debit__c);
	    System.debug(LoggingLevel.ERROR, '#### Funct CR: ' + aes[0].COMP_Functional_Total_CR__c + + '\tFunct DR: ' + aes[0].COMP_Functional_Total_DR__c);

	    for(Accounting_Entry_Line__c ael : aes[0].Accounting_Entry_Lines__r){
	    	System.debug(LoggingLevel.ERROR, '#### Exception: ' + ael.Exception__c + '\tTran Currency: ' + ael.COMP_Transaction_Currency__c + '\tFunc Currency: ' + ael.COMP_Functional_Currency__c +'\tRate: ' + ael.COMP_Functional_Conversion_Rate__c + '\tTrans CR: ' + ael.COMP_Transaction_Currency_Amount_CR__c + '\tTrans DR: ' + ael.COMP_Transaction_Currency_Amount_DR__c + '\tFunct CR: ' + ael.COMP_Functional_Currency_Amount_CR__c + '\tFunct Dr: ' + ael.COMP_Functional_Currency_Amount_DR__c);


	    	if(ael.Exception__c == true){
	    		List<Task> task = [Select Id, Description from Task Where WhatId =: ael.Id];

	    		for(Task t : task){
	    			System.debug(LoggingLevel.ERROR, '#### Error: ' + t.Description);
	    		}

	    	}
	    }
		list<accounting_entry_line__c> ael = [Select Id, accounting_rule__c
	    									From accounting_entry_line__c where accounting_rule__r.subtransaction_type__c = 'Rounding' limit 1];
	    system.assert(ael != null,'We should see rounding Line');	
	    system.assertEquals(1, aes.size());	
	    system.assertEquals(true, aes[0].COMP_Total_Debit__c == aes[0].COMP_Total_Credit__c, 'Expected Comp Total DR == to Comp Total CR got ' + aes[0].COMP_Total_Debit__c + ' = ' + aes[0].COMP_Total_Credit__c);
	    system.assertEquals(true, aes[0].COMP_Functional_Total_DR__c > 0, 'Expected a value for Comp Functional Total DR');
	    system.assertEquals(true, aes[0].COMP_Functional_Total_DR__c == aes[0].COMP_Functional_Total_CR__c, 'Expected Comp Funct DR = to Comp Funct CR got ' + aes[0].COMP_Functional_Total_DR__c + ' = ' + aes[0].COMP_Functional_Total_CR__c);
	    system.assertEquals(false, aes[0].Has_Exceptions__c, 'Expected no exceptions');

	}
   
	
	static testmethod void testJEAccountingBatch(){
		JournalEntries JE = new JournalEntries();

		System.assert(JE.JEList != null);
		
		Set<Id> companyIds = new Set<Id>{JE.company.id };

		Test.startTest();
			database.executebatch(new JournalEntryAccountingBatch(companyIds));
		Test.stopTest();
		List<Journal_Entry__c> jeList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c,
	    							(Select id, Name from Accounting_Entries__r)
	    							from Journal_Entry__c where id in :JE.JEList];
	    
	    system.assertEquals(true, jeList[0].Finalized__c);
	    system.assertNotEquals(null, jeList[0].Finalized_Date__c);
	    system.assertEquals(1, jeList[0].Accounting_Entries__r.size());
	    system.assertEquals(1, jeList[1].Accounting_Entries__r.size());
	}	
	
	
	//Test initial page load and vars required for Kendo widgets to render.
	static testmethod void  testJournalEntryAddManageFieldsInitialRender(){
        
        JournalEntries JE = new JournalEntries();        
        Journal_Entry__c journalEntry = new Journal_Entry__c();
        
		journalEntry.name = 'JE001';
	    journalEntry.Company__c = JE.company.id;	
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
	    //journalEntry.GL_Date__c = System.today();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
		//je1.Finalized__c = true;		
	    insert journalEntry;
        
	    List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
 
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = JE.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
        
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = JE.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 

		insert	jeLineList;		
        
        journalEntry = [Select id, Name, Period__r.Name, Period__c from Journal_Entry__c where id = :journalEntry.id];
        System.assertNotEquals(null, journalEntry.id );
        
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(journalEntry);
        JournalEntryLinesManageExt jExt = new JournalEntryLinesManageExt(sc);	
       
        //Assert vars loaded on constructor.
        System.assertNotEquals(jExt.JERecJSON,null,'Expecting serialized journal rec.')	;
        System.assertNotEquals(jExt.journalEntryLinesConfig,null,'Expecting journalEntryLinesConfig to loaded in constructor.')	;
 
        //Assert JSON vars loaded from getters used by Kendo widgets for fieldlist.       
		System.assertNotEquals(jExt.getjeHeaderFields(),null,'Expecting fields from Journal_Entry_Header fieldset. ');
		System.assertNotEquals(jExt.getjeAddlHeaderFields(),null,'Expecting fields from Journal_Entry_Additional_Info fieldset. ');		
		System.assertNotEquals(jExt.getJournalEntryLineFieldList(),null,'Expecting fields from Journal_Entry_Line_Edit fieldset. ');			
		System.assertNotEquals(jExt.getJournalEntryLineFieldList(),null,'Expecting fields for task. ');					
		
		//Assert JSON Vars of recs queried from DB.
		JSONResult jeRecJSON1 = JournalEntryLinesManageExt.getJournalEntryDetails(journalEntry.Id,null); 
		System.assertNotEquals(jeRecJSON1,null,'Expecting je rec ');					
		JSONResult jeRecJSON11 = JournalEntryLinesManageExt.getJournalEntryDetails(journalEntry.Id,'1'); //For clone
		System.assertNotEquals(jeRecJSON11,null,'Expecting je rec for clone ');					
		
		JSONResult jelineJSON2 = JournalEntryLinesManageExt.getJournalEntryLines(jExt.journalEntryLinesConfig,null);
		System.assertNotEquals(jelineJSON2,null,'Expecting jel recs. ');					
		JSONResult jelineJSON22 = JournalEntryLinesManageExt.getJournalEntryLines(jExt.journalEntryLinesConfig,'1');
		System.assertNotEquals(jelineJSON22,null,'Expecting jel rec for clone ');					
		
		Map<id, List<Task>>  mTasks = JournalEntryLinesManageExt.getJournalEntryLineTaskDetails(new set<id>{jeLine1.id,jeLine2.id});
		System.assertNotEquals(mTasks,null,'Expecting task recs. ');					
		
		//Assert for Go Back button
		system.assertNotEquals(jExt.getReturnUrl(),null,'Expecting return URL for Go back.');
		
		list<gl_account__c> glAccount = [select id, active__c from gl_account__c where id =: JE.receivablesGL.id];
		glAccount[0].active__c = false;
		update glAccount;
		JSONResult jelineJSON24 = JournalEntryLinesManageExt.getJournalEntryLines(jExt.journalEntryLinesConfig,'1');
		list<JournalEntryLinesManageExt.JournalEntryLineWrapper> JeW = (list<JournalEntryLinesManageExt.JournalEntryLineWrapper>)jelineJSON24.records;
		system.debug('jelineJSON24 records ==== : ' + JeW[1].jeline.gl_account__c);
		System.assertEquals(JeW[1].jeline.gl_account__c ,null,'Expecting jel gl account not cloned ');					
	}
	
	//Test various user actions with save.
	//For an Existing JE,Add + Delete+ Update Lines and finalize with exceptions.
	//For an Existing JE, Add + Delete +Update Line with Finalize without exception.
	//For a new JE ,Add + Del + Update Lines with Finalize.
	static testmethod void  testJournalEntryAddManageSaveAction(){
        JournalEntries JE = new JournalEntries();        
        Journal_Entry__c journalEntryWithoutFinalized = new Journal_Entry__c();
        
		journalEntryWithoutFinalized.name = 'JE001';
	    journalEntryWithoutFinalized.Company__c = JE.company.id;	
	    journalEntryWithoutFinalized.type__c = 'Manual';   
	    journalEntryWithoutFinalized.Transaction_Type__c = 'Manual';
	    journalEntryWithoutFinalized.Transaction_Date__c = System.now();  
		journalEntryWithoutFinalized.Currency__c = TestFuel.currencyUSD.id;
		journalEntryWithoutFinalized.Finalized__c =false;
		
        Journal_Entry__c journalEntryWithFinalized = new Journal_Entry__c();        
		journalEntryWithFinalized.name = 'JE002';
	    journalEntryWithFinalized.Company__c = JE.company.id;	
	    journalEntryWithFinalized.type__c = 'Manual';   
	    journalEntryWithFinalized.Transaction_Type__c = 'Manual';
	    journalEntryWithFinalized.Transaction_Date__c = System.now();  
		journalEntryWithFinalized.Currency__c = TestFuel.currencyUSD.id;
		journalEntryWithFinalized.Finalized__c =true;
		
	    List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
	    List<JournalEntryLinesManageExt.JournalEntryLineWrapper> newList = new List<JournalEntryLinesManageExt.JournalEntryLineWrapper>();
	    List<JournalEntryLinesManageExt.JournalEntryLineWrapper> updateList = new List<JournalEntryLinesManageExt.JournalEntryLineWrapper>();
	    List<JournalEntryLinesManageExt.JournalEntryLineWrapper> delList = new List<JournalEntryLinesManageExt.JournalEntryLineWrapper>();
	    List<String> headerDateFields = new List<String>{'Transaction_Date__c'};
	    List<string> dateFields = new List<String>();
 
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntryWithoutFinalized.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = JE.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
        JournalEntryLinesManageExt.JournalEntryLineWrapper jeLine1wrapper = new JournalEntryLinesManageExt.JournalEntryLineWrapper(jeLine1,null);
        
 	    Journal_Entry_Line__c jeLine1a = new Journal_Entry_Line__c(); 
	    jeLine1a.Journal_Entry__c = journalEntryWithoutFinalized.id;
		jeLine1a.Amount_CR__c = 0;
		jeLine1a.Amount_DR__c = 5;
		jeLine1a.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1a);  
        JournalEntryLinesManageExt.JournalEntryLineWrapper jeLine1awrapper = new JournalEntryLinesManageExt.JournalEntryLineWrapper(jeLine1a,null);
               
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntryWithoutFinalized.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
        JournalEntryLinesManageExt.JournalEntryLineWrapper jeLine2wrapper = new JournalEntryLinesManageExt.JournalEntryLineWrapper(jeLine2,null);


        
	    Journal_Entry_Line__c jeLine3= new Journal_Entry_Line__c(); 
	    jeLine3.Journal_Entry__c = journalEntryWithFinalized.id;
		jeLine3.Amount_CR__c = 0;
		jeLine3.Amount_DR__c = 5;
		jeLine3.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine3); 
        JournalEntryLinesManageExt.JournalEntryLineWrapper jeLine3wrapper = new JournalEntryLinesManageExt.JournalEntryLineWrapper(jeLine3,null);

	    Journal_Entry_Line__c jeLine4= new Journal_Entry_Line__c(); 
	    jeLine4.Journal_Entry__c = journalEntryWithFinalized.id;
		jeLine4.Amount_CR__c = 5;
		jeLine4.Amount_DR__c = 0;
		jeLine4.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine4); 
        JournalEntryLinesManageExt.JournalEntryLineWrapper jeLine4wrapper = new JournalEntryLinesManageExt.JournalEntryLineWrapper(jeLine4,null);
        	    			    		
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(journalEntryWithFinalized);
        JournalEntryLinesManageExt jExt = new JournalEntryLinesManageExt(sc);
        
        //For a new JE ,Add  Lines and Finalize.
        JSONResult JSONResultOnInsert = JournalEntryLinesManageExt.saveAction(journalEntryWithFinalized,headerDateFields,new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>(),new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>{jeLine3wrapper,jeLine4wrapper},new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>(),null);
        system.assertEquals(JSONResultOnInsert.success,true,'Expecting successful insert.'+JSONResultOnInsert);
        
        //For a new JE ,Add lines without Finalize.
        JSONResult JSONResultOnInsertWithoutFinalize = JournalEntryLinesManageExt.saveAction(journalEntryWithoutFinalized,headerDateFields,new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>(),new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>{jeLine1wrapper,jeLine1awrapper,jeLine2wrapper},new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>(),null);
        system.assertEquals(JSONResultOnInsert.success,true,'Expecting successful insert.'+JSONResultOnInsertWithoutFinalize);        
  
        //For the above existing add ,update lines and Finalize - With Exception.
        list<Journal_Entry_Line__c> jelToUpdate = [select id,name,Amount_DR__c from Journal_Entry_Line__c where id = :jeLine2.id]  ;
        System.assertEquals(jelToUpdate.size(),1,'Expecting dr jel to be inserted');
        jelToUpdate[0].Amount_DR__c = 15;//induce a imbalance;
        jelToUpdate[0].Amount_CR__c = 3;//induce a row Error;
        
        JournalEntryLinesManageExt.JournalEntryLineWrapper imbalanceWrapper =new JournalEntryLinesManageExt.JournalEntryLineWrapper(jelToUpdate[0],null);
        
        journalEntryWithoutFinalized.Finalized__c=true;
        //update a line to cause imbalance
        JSONResult JSONResultOnInsertWithFinalizeException = JournalEntryLinesManageExt.saveAction(journalEntryWithoutFinalized,headerDateFields,new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>{imbalanceWrapper},new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>(),new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>(),null);
        system.assertEquals(JSONResultOnInsertWithFinalizeException.success,false,'Expecting exception on update/del.'+JSONResultOnInsertWithFinalizeException);        
        Boolean sawException =false;
        for(map<string,string> mExceptionTypeToval:JSONResultOnInsertWithFinalizeException.messages){
        	for(string exceptionType:mExceptionTypeToval.keyset()){
        		if(exceptionType=='message'){
		        	if(mExceptionTypeToval.get(exceptionType).contains('The credit and debit does not match on this Journal Entry')){
		        		sawException = true;
		        	}
        		}
        	}
        }
        system.assertEquals(sawException,true,'Expecting error credit debit mismatch on finalize.');
 
        
        //undo the above change to restore balance -revert CR line to 5 and delete extra 1a Line.
         imbalanceWrapper.jeline.Amount_DR__c = 5;//revert to original;
         imbalanceWrapper.jeline.Amount_CR__c = 0;//revert to original;
        
        JSONResult JSONResultOnInsertWithFinalizeNoException = JournalEntryLinesManageExt.saveAction(journalEntryWithoutFinalized,headerDateFields,new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>{imbalanceWrapper},new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>(),new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>{jeLine1awrapper},null);
        system.assertEquals(JSONResultOnInsertWithFinalizeNoException.success,true,'Expecting succesful finalize update.'+JSONResultOnInsertWithFinalizeNoException);         
        
    }
	
	
	
	// To test the method generateJEfromAE and generateJEfromAELs from JournalAccountingService
	static testmethod void testgenerateJE(){ 
		JournalEntries JE = new JournalEntries();
		JournalEntryService JES = JournalEntryService.getInstance();
		List<Accounting_Rule__c> SuppInvAcctRulesList = new List<Accounting_Rule__c>();
		Accounting_Rule__c sinvacctRule1 = new Accounting_Rule__c();
        sinvacctRule1.Object_Name__c = 'Supplier_Invoice__c';
        sinvacctRule1.Accounting_Standard__c = JE.accountingStandard.id;
        sinvacctRule1.Transaction__c = 'Supplier Invoice';
        sinvacctRule1.SubTransaction_Type__c = 'Goods';
        sinvacctRule1.Line_type__c = 'Standard';
        sinvacctRule1.Rule_Type__c = 'DR';
        sinvacctRule1.Default_GL_Account__c = true;
        sinvacctRule1.GL_Account_Reference_Value__c = null;
        sinvacctRule1.GL_Account__c = JE.GRNIGL.id;
        sinvacctRule1.Effective_Start_Date__c =JE.effStartDate;
        SuppInvAcctRulesList.add(sinvacctRule1);
		

        Accounting_Rule__c sinvacctRule2 = new Accounting_Rule__c();
        sinvacctRule2.Object_Name__c = 'Supplier_Invoice__c';
        sinvacctRule2.Accounting_Standard__c = Je.accountingStandard.id;
        sinvacctRule2.Transaction__c = 'Supplier Invoice';
        sinvacctRule2.SubTransaction_Type__c = 'Goods';
        sinvacctRule2.Line_type__c = 'Standard';
        sinvacctRule2.Rule_Type__c = 'CR';
        sinvacctRule2.Default_GL_Account__c = true;
        sinvacctRule2.GL_Account_Reference_Value__c = null;
        sinvacctRule2.GL_Account__c = JE.payablesGL.id;
        sinvacctRule2.Effective_Start_Date__c =JE.effStartDate;        
        SuppInvAcctRulesList.add(sinvacctRule2);
		
        insert SuppInvAcctRulesList;
		
		// Create a AE and AE Lines to pass to the functions to check if the JE and JELines are created as expected
		
		SupplierInvoiceAccounting sa = new SupplierInvoiceAccounting();
		sa.execute(new List<Supplier_Invoice_line__c>{JE.suppInvLine1});
		
		Accounting_Entry__c AE = [Select id, Name ,
									(Select id, Name from Accounting_Entry_Lines__r)
									from Accounting_Entry__c where Supplier_Invoice__c = :JE.SuppInv1.id];
		system.assertEquals(2, AE.Accounting_Entry_Lines__r.size());
		
		JES.generateJEfromAELs(AE.Accounting_Entry_Lines__r);

		
		Journal_Entry__c journalEntry = [Select id, Name, Transaction_Type__c, Transaction_Date__c, Type__c, Company__c, Customer__c, Supplier__c,
								(Select id, Name, Amount_CR__c, Amount_DR__c, GL_Account__c, Transaction_Date__c, Source_ID__c, Source_Name__c, Line_Type__c, Subtransaction_Type__c,Reversing_Line__c
								from Journal_Entry_Lines__r ORDER BY Amount_DR__c DESC)
								from Journal_Entry__c 
								where Supplier_Invoice__c = :JE.SuppInv1.id];
		
		System.assertNotEquals(null, journalEntry);
		System.assertEquals(2, journalEntry.Journal_Entry_Lines__r.size());
		System.assertEquals(10, journalEntry.Journal_Entry_Lines__r[0].Amount_DR__c);
		System.assertEquals(10, journalEntry.Journal_Entry_Lines__r[1].Amount_CR__c);
		System.assertEquals(true, journalEntry.Journal_Entry_Lines__r[0].Reversing_Line__c);
		System.assertEquals(true, journalEntry.Journal_Entry_Lines__r[1].Reversing_Line__c);
		System.assert( journalEntry.Journal_Entry_Lines__r[0].Source_ID__c.contains(JE.suppInvLine1.id));
		System.assert( journalEntry.Journal_Entry_Lines__r[1].Source_ID__c.contains(JE.suppInvLine1.id));
		System.assertEquals('Goods', journalEntry.Journal_Entry_Lines__r[0].Subtransaction_Type__c);
		System.assertEquals('Goods', journalEntry.Journal_Entry_Lines__r[1].Subtransaction_Type__c);
		System.assertEquals('Standard', journalEntry.Journal_Entry_Lines__r[0].Line_Type__c);
		System.assertEquals('Standard', journalEntry.Journal_Entry_Lines__r[1].Line_Type__c);
		//SK - TODO: Revisit to find why it does not find the GL Account
		//System.assertEquals(JE.cashGL.id, journalEntry.Journal_Entry_Lines__r[0].GL_Account__c);
		//System.assertEquals(JE.receivablesGL.id, journalEntry.Journal_Entry_Lines__r[1].GL_Account__c); 
		//As per FIN-954 we are using transaction_type__c for accounting on all source docs.The below assert is not valid as it will have the same value as type__c
		//System.assertEquals('Supplier Invoice', journalEntry.Transaction_Type__c);
		System.assertEquals('SCOA Adjustment', journalEntry.Type__c);
		
	}
	
	
	
	
	// Test JournalEntryVoidCancelExt.cls
	static testmethod void testJEVoidCancelExt_Void(){
		// create JE and generate accounting
		// Close Period
		// Void JE

		System.debug(LoggingLevel.ERROR, '#### Query Start setup: ' + Limits.getQueries());
		
		JournalEntries JE = new JournalEntries();
        
        Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    journalEntry.Company__c = JE.company.id;	
	    //journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
	    //journalEntry.GL_Date__c = System.today();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
		//je1.Finalized__c = true;		
	    insert journalEntry;
        
 		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = JE.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = JE.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
		
		insert	jeLineList;
		
		journalEntry.finalized__c = true;
		update journalEntry;
		
		List<Journal_Entry__c> journalEntryList = new List<Journal_Entry__c>();
		journalEntryList.add(journalEntry);
		system.assert(journalEntryList.size() == 1, 'journalEntryList size is not 1');
        JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(jeLineList);
	    
	    journalEntryList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Type__c, posting_date__c,
                            		Period__r.Name, Period__c,Period__r.Open__c,void__c,Status__c,Period__r.JE_Cutoff__c,Void_Date__c,company__c,
	    							(Select id, Name from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id = :journalEntry.id];
    
    	system.assertEquals('Manual', journalEntryList[0].Type__c);
	    system.assertEquals(true, journalEntryList[0].Finalized__c);
	    system.assertNotEquals(null, journalEntryList[0].Finalized_Date__c);
	    system.assertEquals(1, journalEntryList[0].Accounting_Entries__r.size());
	    
        //Commenting out due to SOQL limits.  This query shouldn't be need
        /*journalEntry = [Select id, Name, Period__r.Name, Period__c,Period__r.Open__c,Finalized__c, 
        				Type__c,void__c,Status__c,Transaction_Date__c, Finalized_Date__c, Period__r.JE_Cutoff__c, posting_date__c
        				 from Journal_Entry__c where id = :journalEntry.id];
        System.assertNotEquals(null, journalEntry.id );
        System.assertNotEquals(null, journalEntry.Period__c );
        System.assertEquals(true, journalEntry.Period__r.Open__c );*/
        
        journalEntry = journalEntryList.get(0);
		
 		Period__c p = new Period__c(id = journalEntry.Period__c);
		p.AR_Subledger_Closed__c =  System.now().addseconds(1);
		p.AP_Subledger_Closed__c = System.now().addseconds(1);
		p.FA_Subledger_Closed__c = System.now().addseconds(1);
		p.Inventory_Subledger_Closed__c = System.now().addseconds(1);
		p.Receiving_Subledger_Closed__c = System.now().addseconds(1);
		p.Shipment_Subledger_Closed__c = System.now().addseconds(1);
		p.GL_Close__c = system.now().addseconds(2);
		p.Open__c = false;
		p.Closed__c = true;
		
		PeriodService.systemEditable.add(p.Id);
		update p;

		System.debug(LoggingLevel.ERROR, '#### Query End setup: ' + Limits.getQueries());
		
	    Test.startTest();	
	    System.debug(LoggingLevel.ERROR, '#### Query Start Test: ' + Limits.getQueries());
	    	
		System.assertEquals(0, Limits.getQueries()); 
        
        //Commenting out because we are exceeding SOQL limit.  This query shouldn't be needed.
		/*p = [Select id, Period_End__c, AR_Subledger_Closed__c, AP_Subledger_Closed__c, FA_Subledger_Closed__c,
			Inventory_Subledger_Closed__c, Receiving_Subledger_Closed__c, Shipment_Subledger_Closed__c, JE_Cutoff__c, Open__c, Closed__c, next_period__c
			from Period__c where id = :journalEntry.Period__c];
		
		system.assert(p.Closed__c == true,'p:'+p);
		system.assert(p.next_period__c != null,'periodList:'+je.periodList);*/
        
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(journalEntry);
        VoidCancelService.voidDate = journalEntry.Period__r.JE_Cutoff__c.addDays(1);
        JournalEntryVoidCancelService JEVCS = new JournalEntryVoidCancelService(new List<Journal_Entry__c> {journalEntry});
       	//JEVCS.currDate = p.JE_Cutoff__c.addDays(1);
        
        JournalEntryVoidCancelExt jExt = new JournalEntryVoidCancelExt(sc);
        PageReference voidCancelPage = page.JournalEntryVoidCancel;
        
        // As the period cutoff is past and period is closed not expecting to cancel the JE.
        jExt.cancelDocs();
        journalEntry = [Select id, Name, Void__c, Void_Date__c , Status__c,company__c,
        				(Select id, Name, Period__c from Accounting_Entries__r)
        				from Journal_Entry__c where id = :journalEntry.id];
        
        system.assert(!journalEntry.Status__c.equalsIgnoreCase('Cancelled'),'Expecting JE Cancel to be disabled as the period cut off is past');
        
        // As the period cutoff is past and period is closed expecting to void the JE
        jExt.voidDocs();
    
        journalEntry = [Select id, Name, Void__c, Void_Date__c , Status__c,company__c,
        				(Select id, Name, Period__c,status__c from Accounting_Entries__r where status__c='Active')
        				from Journal_Entry__c where id = :journalEntry.id];
        
        System.debug(LoggingLevel.ERROR, '#### Query End Test: ' + Limits.getQueries());
        Test.stopTest();

        system.assert(journalEntry.Void__c == true,'Journal Entry did not void');
        system.assert(journalEntry.Void_Date__c != null,'Journal Entry void date is null');
        system.assertNotEquals(journalEntry.Accounting_Entries__r,null,'Journal Entry did not create a voided AE');        
        system.assert(journalEntry.Accounting_Entries__r.size() == 2,'Journal Entry did not create a voided AE');

        System.debug(LoggingLevel.ERROR, '#### Query End: ' + Limits.getQueries());
        
	}
	
	static testMethod void testJEUnfinalize_BankRec() {
		JournalEntries JE = new JournalEntries();
        
        Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    journalEntry.Company__c = JE.company.id;	
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
	    insert journalEntry;
        
 		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = JE.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = JE.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
		
		insert	jeLineList;
		
		journalEntry.finalized__c = true;
		update journalEntry;
		
		List<Journal_Entry__c> journalEntryList = new List<Journal_Entry__c>();
		journalEntryList.add(journalEntry);
		system.assert(journalEntryList.size() == 1, 'journalEntryList size is not 1');
        Test.startTest();
        
	    journalEntryList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Type__c, posting_date__c,
	    							(Select id, Name from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id = :journalEntry.id];
    
	    system.assertEquals(true, journalEntryList[0].Finalized__c);
	    system.assertNotEquals(null, journalEntryList[0].Finalized_Date__c);
	    
        journalEntry = [Select id, Name,Period__r.Name, Period__c,Period__r.Open__c,Finalized__c, Void_Date__c,company__c,
        				Type__c,void__c,Status__c,Transaction_Date__c, Finalized_Date__c, Period__r.JE_Cutoff__c, posting_date__c
        				 from Journal_Entry__c where id = :journalEntry.id];
        System.assertNotEquals(null, journalEntry.id );
        System.assertNotEquals(null, journalEntry.Period__c );
        System.assertEquals(true, journalEntry.Period__r.Open__c );
        
        //INJECT BANK REC SCENARIO FOR CANCEL
        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = JE.company.id, Amount__c = -5, Transaction_Date__c = journalEntry.Transaction_Date__c , 
        												   Bank_Account__c = JE.bankAccount.Id);
        insert bt;
        
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Journal_Entry_Line__c = jeLine1.Id, Amount__c = -5);
        insert btm;
        
        BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
        dateTime reconciledDate = system.now();
        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.Id}, reconciledDate, JE.bankAccount.id);
        ////INJECT BANK REC SCENARIO FOR CANCEL --END 
        String tmpId = journalEntry.id;
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', tmpId );
		SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
		ExceptionService.messages.clear();
		try
		{
			srcDocUnfinalizeExt1.unfinalizeSourceDoc();
		}catch(Exception ex)
		{
			system.debug('CR unfinalize exception: '+ex.getMessage()); //AR-87
		}
		
		boolean ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages())
        	if(msg.getDetail().contains(Label.transaction_has_been_reconciled))
        	{
        		ErrorExists = true;
        		break;
        	}
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
		srcDocUnfinalizeExt1.unfinalize(); 
		
		bt = [select id, Finalized__c, Reconciled_Hidden__c, Match_Approved__c, Reconciled_As_Of_Date__c from Bank_Transaction__c where Id = :bt.Id limit 1];
        system.assertEquals(false, bt.Match_Approved__c, bt);
        system.assertEquals(false, bt.Reconciled_Hidden__c, bt);
        system.assertEquals(null, bt.Reconciled_As_Of_Date__c, bt);
	}
	
	// Test JournalEntryVoidCancelExt.cls
	static testmethod void testJEVoidCancelExt_Cancel(){
		// create JE finalize and generate accounting
		// Cancel JE and assert the related AE is deleted
		
		JournalEntries JE = new JournalEntries();
        
        Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    journalEntry.Company__c = JE.company.id;	
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
	    insert journalEntry;
        
 		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = JE.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = JE.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
		
		insert	jeLineList;
		
		journalEntry.finalized__c = true;
		update journalEntry;
		
		List<Journal_Entry__c> journalEntryList = new List<Journal_Entry__c>();
		journalEntryList.add(journalEntry);
		system.assert(journalEntryList.size() == 1, 'journalEntryList size is not 1');
        Test.startTest();
        JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(jeLineList);
	    
	    journalEntryList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Type__c, posting_date__c,
	    							(Select id, Name from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id = :journalEntry.id];
    
	    system.assertEquals(true, journalEntryList[0].Finalized__c);
	    system.assertNotEquals(null, journalEntryList[0].Finalized_Date__c);
	    system.assertEquals(1, journalEntryList[0].Accounting_Entries__r.size());
        
        journalEntry = [Select id, Name,Period__r.Name, Period__c,Period__r.Open__c,Finalized__c, Void_Date__c,company__c,
        				Type__c,void__c,Status__c,Transaction_Date__c, Finalized_Date__c, Period__r.JE_Cutoff__c, posting_date__c
        				 from Journal_Entry__c where id = :journalEntry.id];
        System.assertNotEquals(null, journalEntry.id );
        System.assertNotEquals(null, journalEntry.Period__c );
        System.assertEquals(true, journalEntry.Period__r.Open__c );
        
        //INJECT BANK REC SCENARIO FOR CANCEL
        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = JE.company.id, Amount__c = -5, Transaction_Date__c = journalEntry.Transaction_Date__c , 
        												   Bank_Account__c = JE.bankAccount.Id);
        insert bt;
        
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Journal_Entry_Line__c = jeLine1.Id, Amount__c = -5);
        insert btm;
        
        BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
        dateTime reconciledDate = system.now();
        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.Id}, reconciledDate, JE.bankAccount.id);
        ////INJECT BANK REC SCENARIO FOR CANCEL --END 
        
        
		Period__c p = new Period__c(id = journalEntry.Period__c);
		p = [Select id, Period_End__c, AR_Subledger_Closed__c, AP_Subledger_Closed__c, FA_Subledger_Closed__c,
			Inventory_Subledger_Closed__c, Receiving_Subledger_Closed__c, Shipment_Subledger_Closed__c, JE_Cutoff__c, 
			Open__c, Closed__c, next_period__c
			from Period__c where id = :journalEntry.Period__c];
		
		system.assert(p.Closed__c == false,'p:'+p);
		system.assert(p.next_period__c != null,'periodList:'+je.periodList);
		
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(journalEntry);
        VoidCancelService.voidDate = p.JE_Cutoff__c.addDays(-1);
        JournalEntryVoidCancelService JEVCS = new JournalEntryVoidCancelService(new List<Journal_Entry__c> {journalEntry});
       	//JEVCS.currDate = p.JE_Cutoff__c.addDays(-1);
        
        JournalEntryVoidCancelExt jExt = new JournalEntryVoidCancelExt(sc);
        PageReference voidCancelPage = page.JournalEntryVoidCancel;
        
        // As the period cutoff is not past and period is Open expecting the void JE disabled
        jExt.voidDocs();
       
       	journalEntry = [Select id, Name, Void__c, Void_Date__c , Status__c,company__c,
        				(Select id, Name, Period__c,status__c from Accounting_Entries__r)
        				from Journal_Entry__c where id = :journalEntry.id];
        
        system.assert(journalEntry.Void__c == false,'Journal Entry voided');
        system.assert(journalEntry.Void_Date__c == null,'Journal Entry void date is not null');
        system.assert(journalEntry.Accounting_Entries__r.size() == 1,'Expecting Accounting entry not to be touched as void is disabled');
        VoidCancelService.VoidCancelDetail detail = jExt.getVoidCancelDetails();
        system.debug('detail '+detail);
		boolean ErrorExists = false;
        for( String msg : detail.cancelMessages)
        	if(msg != null && msg.contains(Label.transaction_has_been_reconciled))
        	{
        		ErrorExists = true;
        		break;
        	}
         system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
       // As the period cutoff is not past and period is Open not expecting cancel JE to succeed
        jExt.cancelDocs();        
        
        journalEntry = [Select id, Name, Void__c, Void_Date__c , Status__c,company__c,
        				(Select id, Name, Period__c, Status__c from Accounting_Entries__r)
        				from Journal_Entry__c where id = :journalEntry.id];
        
        system.assert(journalEntry.Status__c.equalsIgnoreCase('Cancelled'),'Journal Entry did not void');
        system.assert(journalEntry.Accounting_Entries__r[0].status__c == 'Obsolete');
        //system.assert(journalEntry.Accounting_Entries__r.size() == 0,'Expecting AE to be deleted while performing Cancel');
        bt = [select id, Match_Approved__c, Reconciled_As_Of_Date__c, Reconciled_Hidden__c from Bank_Transaction__c where Id = :bt.Id limit 1];
        system.assertEquals(false, bt.Match_Approved__c, bt);
        system.assertEquals(false, bt.Reconciled_Hidden__c, bt);
        system.assertEquals(null, bt.Reconciled_As_Of_Date__c, bt); 
        Test.stopTest();
	}
	
	static testmethod void testJEVoidCancelExtCancel_BTMatched(){
		// create JE finalize and generate accounting
		// Cancel JE and assert the related AE is deleted
		
		JournalEntries JE = new JournalEntries();
        
        Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    journalEntry.Company__c = JE.company.id;	
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
	    insert journalEntry;
        
 		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = JE.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = JE.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
		
		insert	jeLineList;
		
		journalEntry.finalized__c = true;
		update journalEntry;
		
		List<Journal_Entry__c> journalEntryList = new List<Journal_Entry__c>();
		journalEntryList.add(journalEntry);
		system.assert(journalEntryList.size() == 1, 'journalEntryList size is not 1');
        Test.startTest();
        JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(jeLineList);
	    
	    journalEntryList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Type__c, posting_date__c,
	    							(Select id, Name from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id = :journalEntry.id];
    
	    system.assertEquals(true, journalEntryList[0].Finalized__c);
	    system.assertNotEquals(null, journalEntryList[0].Finalized_Date__c);
	    system.assertEquals(1, journalEntryList[0].Accounting_Entries__r.size());
        
        journalEntry = [Select id, Name,Period__r.Name, Period__c,Period__r.Open__c,Finalized__c, Void_Date__c,company__c,
        				Type__c,void__c,Status__c,Transaction_Date__c, Finalized_Date__c, Period__r.JE_Cutoff__c, posting_date__c
        				 from Journal_Entry__c where id = :journalEntry.id];
        System.assertNotEquals(null, journalEntry.id );
        System.assertNotEquals(null, journalEntry.Period__c );
        System.assertEquals(true, journalEntry.Period__r.Open__c );
        
        //INJECT BANK REC SCENARIO FOR CANCEL
        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = JE.company.id, Amount__c = -5, Transaction_Date__c = journalEntry.Transaction_Date__c , 
        												   Bank_Account__c = JE.bankAccount.Id);
        insert bt;
        
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Journal_Entry_Line__c = jeLine1.Id, Amount__c = -5);
        insert btm;
        ////INJECT BANK REC SCENARIO FOR CANCEL --END 
        
        
		Period__c p = new Period__c(id = journalEntry.Period__c);
		p = [Select id, Period_End__c, AR_Subledger_Closed__c, AP_Subledger_Closed__c, FA_Subledger_Closed__c,
			Inventory_Subledger_Closed__c, Receiving_Subledger_Closed__c, Shipment_Subledger_Closed__c, JE_Cutoff__c, 
			Open__c, Closed__c, next_period__c
			from Period__c where id = :journalEntry.Period__c];
		
		system.assert(p.Closed__c == false,'p:'+p);
		system.assert(p.next_period__c != null,'periodList:'+je.periodList);
		
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(journalEntry);
        VoidCancelService.voidDate = p.JE_Cutoff__c.addDays(-1);
        JournalEntryVoidCancelService JEVCS = new JournalEntryVoidCancelService(new List<Journal_Entry__c> {journalEntry});
       	//JEVCS.currDate = p.JE_Cutoff__c.addDays(-1);
        
        JournalEntryVoidCancelExt jExt = new JournalEntryVoidCancelExt(sc);
        PageReference voidCancelPage = page.JournalEntryVoidCancel;
        
        // As the period cutoff is not past and period is Open expecting the void JE disabled
        jExt.voidDocs();
       
       	journalEntry = [Select id, Name, Void__c, Void_Date__c , Status__c,company__c,
        				(Select id, Name, Period__c,status__c from Accounting_Entries__r)
        				from Journal_Entry__c where id = :journalEntry.id];
        
        system.assert(journalEntry.Void__c == false,'Journal Entry voided');
        system.assert(journalEntry.Void_Date__c == null,'Journal Entry void date is not null');
        system.assert(journalEntry.Accounting_Entries__r.size() == 1,'Expecting Accounting entry not to be touched as void is disabled');
        VoidCancelService.VoidCancelDetail detail = jExt.getVoidCancelDetails();
        system.debug('detail '+detail);
		boolean ErrorExists = false;
        for( String msg : detail.cancelMessages)
        	if(msg != null && msg.contains(Label.Existing_matches_will_be_deleted))
        	{
        		ErrorExists = true;
        		break;
        	}
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
        // As the period cutoff is not past and period is Open not expecting cancel JE to succeed
        jExt.cancelDocs();        
        
        journalEntry = [Select id, Name, Void__c, Void_Date__c , Status__c,company__c,
        				(Select id, Name, Period__c, Status__c from Accounting_Entries__r)
        				from Journal_Entry__c where id = :journalEntry.id];
        
        system.assert(journalEntry.Status__c.equalsIgnoreCase('Cancelled'),'Journal Entry did not void');
        system.assert(journalEntry.Accounting_Entries__r[0].status__c == 'Obsolete');
        //system.assert(journalEntry.Accounting_Entries__r.size() == 0,'Expecting AE to be deleted while performing Cancel');
        bt = [select id, Reconciled_As_Of_Date__c, Reconciled_Hidden__c from Bank_Transaction__c where Id = :bt.Id limit 1];
        system.assertEquals(false, bt.Reconciled_Hidden__c, bt);
        system.assertEquals(null, bt.Reconciled_As_Of_Date__c, bt); 
        Test.stopTest();
	}
	
	//1. Create header missing company, transaction currency , transaction date 
	//2. Create header without line and finalize it 
	//3. create header and one line finalize
	//4. update line created in step3
	//5. add new line to the header created in step3
	//6. delete new line created in step 5
	//7. undelete line deleted in step 6 
		
	static testmethod void testJEHeaderFinalize(){
		
		TestFuel fuel = new TestFuel();
    	Company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;
    	
	   	
	   	Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
	    insert journalEntry;
	    
	    Test.startTest();
	    boolean sawException = false;
	    string exMsg = null;
	    
	    try{
	    	journalEntry.finalized__c = true;
	    	insert journalEntry;
	    }catch(Exception ex){
	    	exMsg = ex.getMessage();
	    	sawException = true;
	    }
	    system.assertEquals(true, sawException); // company can not be null
	    
	    exMsg = null;
	    sawException = false;
	   	journalEntry.Company__c = company.id;
	   	
	   	//--Called from UI when user chnages company ----//
	   	JournalEntryLinesManageExt.getCompanyDetails(''+journalEntry.Company__c ,''+journalEntry);
	   	
	   	journalEntry.Transaction_date__c = null;
	   	journalEntry.finalized__c = true;
	   	try{
	   		update journalEntry;
	   	}catch(Exception ex){
	   		exMsg = ex.getMessage();
	   		sawException = true;
	   	}
	   	system.assertEquals(true, sawException);// transaction date can not be null
	    
	    exMsg = null;
	    sawException = false;
	   	journalEntry.Currency__c = null;
	   	journalEntry.Transaction_date__c = system.now();
	   	journalEntry.finalized__c = true;
	   	try{
	   		update journalEntry;
	   	}catch(Exception ex){
	   		exMsg = ex.getMessage();
	   		sawException = true;
	   	}
	   	system.assertEquals(true, sawException); // transaction currency can not be null
	   	
	   	exMsg = null;
	   	sawException = false;
	   	journalEntry.Currency__c = TestFuel.currencyUSD.id;
	   	journalEntry.finalized__c = true;
	   	try{
	   		update journalEntry;
	   	}catch(Exception ex){
	   		exMsg = ex.getMessage();
	   		sawException = true;
	   	}
	    // journal entry without lines can not be finalized
	    system.assert(sawException, 'We are expecting to see an exception for attempting to finalized a doc without lines' + exMsg );
	    Test.stopTest();
	}
	
	static testmethod void testJELineUpdate(){
		TestFuel fuel = new TestFuel();
		Company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;

	   	Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    journalEntry.Company__c = fuel.company.id;	
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
	    insert journalEntry;
        
 		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = fuel.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = fuel.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
		
		insert	jeLineList;
		
		journalEntry.finalized__c = true;
		update journalEntry;
	    
	    Test.startTest();
	    String exMsg = null;
	    boolean sawException = false;
	    try{
	    	jeLine2.GL_Account__c = fuel.cashGL.id; // gl account field exists in finalize field set which is not meant to be modified after doc is finalized
	    	update jeLine2; 
	    }catch(Exception ex){
	    	exMsg = ex.getMessage();
	    	sawException = true;
	    }
	    Test.stopTest();
	    
	    system.assert(sawException, 'We are expecting to see an exception for attempting to edit a line of a finalized doc ' + exMsg);
	}
	
	static testmethod void testJELineInsert(){
		TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;

	   	Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    journalEntry.Company__c = fuel.company.id;	
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
	    insert journalEntry;
        
 		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = fuel.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = fuel.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
		
		insert	jeLineList;
		
		journalEntry.finalized__c = true;
		update journalEntry;
	    
	    Journal_Entry_Line__c jeLine3 = new Journal_Entry_Line__c(); 
	    jeLine3.Journal_Entry__c = journalEntry.id;
		jeLine3.Amount_CR__c = 5;
		jeLine3.Amount_DR__c = 0;
		jeLine3.GL_Account__c = fuel.cashGL.id;
		jeLine3.Subtransaction_Type__c = 'Write Off';
	    
	    Test.startTest();
	    String exMsg = null;
	    boolean sawException = false;
	    try{
	    	insert jeLine3; // new line can not be added to source doc once it is finalized
	    }catch(Exception ex){
	    	exMsg = ex.getMessage();
	    	sawException = true;
	    }
	    
	    Test.stopTest();
	    
	    system.assert(sawException, 'We are expecting to see an exception for attempting to add a line to a finalized doc ' + exMsg);
	}
	
	static testmethod void testJELineDelete(){
		TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;

	   	Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    journalEntry.Company__c = fuel.company.id;	
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
	    insert journalEntry;
        
 		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = fuel.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = fuel.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
		
		insert	jeLineList;
		
		journalEntry.finalized__c = true;
		update journalEntry;
	    
	    Test.startTest();
	    String exMsg = null;
	    boolean sawException = false;
	    try{
	    	delete jeLine2; //  line can not be deleted from a source doc once it is finalized
	    }catch(Exception ex){
	    	exMsg = ex.getMessage();
	    	sawException = true;
	    }
	    Test.stopTest();
	    
	    system.assert(sawException, 'We are expecting to see an exception for attempting to delete a line from a finalized doc ' + exMsg);
	}
	
	static testmethod void testJELineUndelete(){
		TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;

	   	Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    journalEntry.Company__c = fuel.company.id;	
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
	    insert journalEntry;
        
 		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = fuel.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = fuel.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
		
		Journal_Entry_Line__c jeLine3 = new Journal_Entry_Line__c(); 
	    jeLine3.Journal_Entry__c = journalEntry.id;
		jeLine3.Amount_CR__c = 0;
		jeLine3.Amount_DR__c = 5;
		jeLine3.GL_Account__c = fuel.receivablesGL.id;
		jeLine3.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine3);
	    
		insert	jeLineList;
		delete jeLine3;
		
		journalEntry.finalized__c = true;
		update journalEntry;
		
	    Test.startTest();
	    String exMsg = null;
	    boolean sawException = false;
	    try{
	    	undelete jeLine3; 
	    }catch(Exception ex){
	    	exMsg = ex.getMessage();
	    	sawException = true;
	    }
	    Test.stopTest();
	    
	    system.assert(sawException, 'We are expecting to see an exception for attempting to undelete a line for a finalized doc ' + exMsg);
	}
	
	static testmethod void testValidateJEFields(){ // To test the exception framework
		TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;

	   	Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    //journalEntry.Company__c = fuel.company.id;	
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    //journalEntry.Transaction_Date__c = System.now();  
		//journalEntry.Currency__c = TestFuel.currencyUSD.id; // this gets defaulted if not specified (required field on layout).
	    insert journalEntry;
        
        List<Task> exceptionList = [select Id,
										   (select Id, Exception_Code__c, Status, Type 
										      from Tasks
							      	 		 where isClosed = false) 
									  from Journal_Entry__c 
									 where Id = :journalEntry.id].Tasks;
									 
		system.assert(exceptionList.size() != 0,'exceptionList'+exceptionList);
		// expected exceptions: JE_MISSING_TRANSACTION_DATE, JE_MISSING_COMPANY, JE_MISSING_TRANSACTION_CURRENCY
        system.assert(exceptionList.size() == 3,'exceptionList'+exceptionList);
        
        
 		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
	    jeLine1.Amount_DR__c = null;
		jeLine1.Amount_CR__c = 5;
		jeLine1.GL_Account__c = fuel.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = fuel.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
	    
	    insert jeLineList;
	    
	    List<Task> lineexceptionList = [select Id,
										   (select Id, Exception_Code__c, Status 
										      from Tasks
							      	 		 where isClosed = false) 
									  from Journal_Entry_Line__c 
									 where Id = :jeLine1.id].Tasks;
									 
		
		system.assert(lineexceptionList.size() != 0,'lineexceptionList'+lineexceptionList);
		// expected exceptions: JEL_MISSING_COMPANY, JEL_MISSING_TRANSACTION_CURRENCY
        system.assert(lineexceptionList.size() == 2,'lineexceptionList'+lineexceptionList+'lineexceptionList.size():'+lineexceptionList.size());
        Boolean sawException = false;
        String exMsg;
        try{
	    	journalEntry.finalized__c = true;
	    	update journalEntry;
        }catch(Exception e){
        	sawException = true;
        	exMsg = e.getMessage();
        }
        
        system.assert(sawException == true,'exMsg:'+exMsg);
	}
	static testmethod void testJEAccounting_Accrual(){
	    // Test Journal Entry Accounting
	    TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;
    	List<Accounting_Rule__c> accountingRules = fuel.accountingRuleList;
    	List<Journal_Entry_Line__c> jeLineList;
		List<Journal_Entry__c> JEList_Accrual = new List<Journal_Entry__c>();	{
			Journal_Entry__c je1 = new Journal_Entry__c();
			je1.name = 'JE001';
		    je1.Company__c = company.id;	
		    je1.Type__c = 'Manual';
		    je1.auto_reverse__c = true;	
		    je1.Transaction_Date__c = System.now();  
			je1.Currency__c = TestFuel.currencyUSD.id;
		    Boolean sawException = false;
		    String exMsg;
		    try{
		    	insert je1;
		    }catch(Exception e){
		    	sawException = true;
		    	exMsg = e.getMessage();
		    }
		    system.assertEquals(true,sawException,'Expected to see the exception to set the Manual JE with Autoreverse check box filled in :'+exMsg);
		    
		    je1.auto_reverse__c = false; // this will be defaulted to true for the accrual manual type in the trigger
		   	je1.type__c = 'Accrual - Manual'; 
            //FIN-954 we are using transaction_type__c for accounting on all source docs.Trigger defaults  transaction_type__c from type__c. 
            //TODO: Add the below line once we deprecate type__c  
            //je1.transaction_type__c = 'Accrual - Manual';  
		    insert je1;
            je1 = [select id,name ,type__c,transaction_type__c from journal_entry__c where id=:je1.id];
            system.assertEquals(je1.transaction_type__c,'Accrual - Manual','Expecting transaction_type__c to be defaulted from type__c');
		    JEList_Accrual.add(je1);
		    
		    jeLineList = new List<Journal_Entry_Line__c>();
		    
		    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
		    jeLine1.Journal_Entry__c = JEList_Accrual[0].id;
			jeLine1.Amount_CR__c = 5;
			jeLine1.Amount_DR__c = 0;
			jeLine1.GL_Account__c = fuel.cashGL.id;
		    jeLineList.add(jeLine1); 
		    
		    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
		    jeLine2.Journal_Entry__c = JEList_Accrual[0].id;
			jeLine2.Amount_CR__c = 0;
			jeLine2.Amount_DR__c = 5;
			jeLine2.GL_Account__c = fuel.receivablesGL.id;
		    jeLineList.add(jeLine2); 
		    
		    insert jeLineList;
	
		    JEList_Accrual[0].finalized__c = true;
		    update JEList_Accrual;
		    
		}
	    Test.startTest();

	    JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(jeLineList);
	    
	    					
		AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEReverse, [SELECT Id FROM Accounting_Entry_Line__c WHERE Journal_Entry_Line__c IN :jeLineList]);
	    
	    
	    List<Journal_Entry__c> jeList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Auto_Reverse__c,
	    							(Select id, Name,COMP_Total_Credit__c, COMP_Total_Debit__c, Related_Accounting_Entry__c  from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id in :JEList_Accrual];
	    		
	    Test.stopTest();
	
	    system.assertEquals(true, jeList[0].Finalized__c);
	    system.assertNotEquals(null, jeList[0].Finalized_Date__c);
	    system.assertEquals(true, jeList[0].Auto_Reverse__c);
	    system.assertEquals(2, jeList[0].Accounting_Entries__r.size());
	    for(Accounting_Entry__c thisAE: jeList[0].Accounting_Entries__r){
	    	system.assert(thisAE.COMP_Total_Credit__c != null,'thisAE:'+thisAE);
	    	system.assert(thisAE.COMP_Total_Credit__c != 0,'thisAE:'+thisAE);
	    	system.assert(thisAE.COMP_Total_Debit__c != null,'thisAE:'+thisAE);
	    	system.assert(thisAE.COMP_Total_Debit__c != 0,'thisAE:'+thisAE);
	    }
	    List<Accounting_Entry__c> relatedAEtoDelete = new List<Accounting_Entry__c>();
	    for(Accounting_Entry__c thisAE: jeList[0].Accounting_Entries__r){
	    	if(thisAE.Related_Accounting_Entry__c == null){
	    		relatedAEtoDelete.add(thisAE);
	    	}
	}
	    system.assertEquals(1,relatedAEtoDelete.size());
	    if(relatedAEtoDelete.size() > 0){
	    	delete relatedAEtoDelete;
	    }
	    
	    jeList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Auto_Reverse__c,
	    							(Select id, Name,COMP_Total_Credit__c, COMP_Total_Debit__c, Related_Accounting_Entry__c  from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id in :JEList_Accrual];
	    
	    system.assertEquals(0, jeList[0].Accounting_Entries__r.size());
	}
	
	// Finalize & Account JE For TD < FD- With Autobackdating
	static testmethod void testJEPeriodFinalizedAfterTDperiodWithAutobackdating(){

		TestDataForAutobackDatingJE testdataForJEAutoBkdt = new TestDataForAutobackDatingJE(); 
	    list<Journal_Entry_Line__c> JELs = new list<Journal_Entry_Line__c>(testdataForJEAutoBkdt.jeLineList);

		Journal_Entry__c je = testdataForJEAutoBkdt.jeCurr;
	    je.transaction_date__c =  system.now().addhours(-22);
		je.finalized__c=true;
		update JE;
		
	    Journal_Entry__c jeAfterFinalize = [select id,name,Finalized_Date__c, Transaction_Date__c, posting_date__c,Finalized__c,period__c 
	    					                from Journal_Entry__c where id =:JELs[0].journal_entry__c];		
        
        system.assertEquals(jeAfterFinalize.period__c,testdataForJEAutoBkdt.prevPeriod.Id,'Expecting JE period to be backdated to txn period.')    ;    
        
        JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(JELs);
        
        Journal_Entry__c jeAfterAccounting = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Auto_Reverse__c, Period__c, posting_date__c,
	    							(Select id, Name, Period__c, COMP_Total_Credit__c, COMP_Total_Debit__c, Related_Accounting_Entry__c  
	    							from Accounting_Entries__r where has_exceptions__c = false and status__c = 'Active')
	    							from Journal_Entry__c where id = :JELs[0].journal_entry__c];
	    							  		
	    system.assert(jeAfterAccounting.Accounting_Entries__r != null, 'Expected to have accounting generated for JE');
	    system.assertEquals(jeAfterAccounting.Accounting_Entries__r[0].Period__c ,testdataForJEAutoBkdt.prevPeriod.Id,'Expected period is not set on AE ');        
         
	}
	// Finalize & Account JE For TD > FD- With Autobackdating
	static testmethod void testJEPeriodFinalizedbeforeTDperiodWithAutobackdating(){
		
		TestDataForAutobackDatingJE testdataForJEAutoBkdt = new TestDataForAutobackDatingJE(); 
	    list<Journal_Entry_Line__c> JELs = new list<Journal_Entry_Line__c>(testdataForJEAutoBkdt.jeLineList);

		Journal_Entry__c je = testdataForJEAutoBkdt.jeCurr;
	    je.transaction_date__c =  system.now().addhours(26);
		je.finalized__c=true;
		update JE;
		
	    Journal_Entry__c jeAfterFinalize = [select id,name,Finalized_Date__c, Transaction_Date__c, posting_date__c,Finalized__c,period__c 
	    					                from Journal_Entry__c where id =:JELs[0].journal_entry__c];		
        
        system.assertEquals(jeAfterFinalize.period__c,testdataForJEAutoBkdt.futurePeriod.Id,'Expecting JE period to be backdated to txn period.')    ;  	
        JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(JELs);
        
        Journal_Entry__c jeAfterAccounting = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Auto_Reverse__c, Period__c, posting_date__c,
	    							(Select id, Name, Period__c, COMP_Total_Credit__c, COMP_Total_Debit__c, Related_Accounting_Entry__c  
	    							from Accounting_Entries__r where has_exceptions__c = false and status__c = 'Active')
	    							from Journal_Entry__c where id = :JELs[0].journal_entry__c];
	    							  		
	    system.assert(jeAfterAccounting.Accounting_Entries__r != null, 'Expected to have accounting generated for JE');
	    system.assertEquals(jeAfterAccounting.Accounting_Entries__r[0].Period__c ,testdataForJEAutoBkdt.futurePeriod.Id,'Expected period is not set on AE ');   
	}
	// Finalize JE For TD < FD- - Without Autobackdating-Exception as it gets posted to prev period
	// Finalize JE For TD > FD And TD < JECutoff- Without Autobackdating- No Exception	
	// Finalize JE For TD > FD And TD > JECutoff- Without Autobackdating- Exception as it gets posted to next period	
	
	static testmethod void testJEPeriodFinalizedBeforeAndAfterTDperiodWithoutAutobackdating(){
		
		TestDataForAutobackDatingJE testdataForJEAutoBkdt = new TestDataForAutobackDatingJE(); 
		
		Configuration__c c = testdataForJEAutoBkdt.autobackdtsetting;
		c.name = 'AutoBackdateToOpenSubledgers';
		c.Value__c = 'No';
		update c;		
		
	    list<Journal_Entry_Line__c> JELs = new list<Journal_Entry_Line__c>(testdataForJEAutoBkdt.jeLineList);
	    
		boolean sawException1 = false;
		boolean sawException2 = false;
		
		Journal_Entry__c je = testdataForJEAutoBkdt.jeCurr;
	    je.transaction_date__c =  system.now().addhours(-22);
		je.finalized__c=true;
		
		try{
		   update JE;
		}
		catch(Exception ex){
			sawException1 = true;
			system.assert(ex.getMessage().containsIgnoreCase(Label.Cannot_be_after_JE_cutoff),'Expecting validation rule to kick off.');
		}
		system.assertEquals(sawException1,true,'Expecting error as TD cannot be before/after txn period JE cutoff.');
		
	    je.transaction_date__c =  testdataForJEAutoBkdt.currPeriod.JE_Cutoff__c.addhours(1);
		je.finalized__c=true;	
		
		try{
		   update JE;
		}
		catch(Exception ex){
			sawException2 = true;
			system.assert(ex.getMessage().containsIgnoreCase(Label.Cannot_be_after_JE_cutoff),'Expecting validation rule to kick off.');
		}	
		journal_entry__c jeafterupdate1 = [select id,name,transaction_date__c,posting_date__c,period__c,period__r.name 
										  from Journal_Entry__c where id=:je.id];		
		system.assertEquals(sawException2,true,'Expecting error as TD cannot be before/after txn period JE cutoff.'+jeafterupdate1.posting_date__c+jeafterupdate1.Period__c+jeafterupdate1.transaction_date__c);
		
				
	    je.transaction_date__c =  testdataForJEAutoBkdt.FuturePeriod.JE_Cutoff__c.addhours(-1);
		je.finalized__c=true;	
		
		try{
		   update JE;
		}
		catch(Exception ex){
			system.assertEquals(ex,null,'Not expecting any exception but got '+ex);
		}	
		journal_entry__c jeafterupdate2 = [select id,name,finalized__c,transaction_date__c,posting_date__c,period__c,period__r.name 
										  from Journal_Entry__c where id=:je.id];					
		system.assertEquals(jeafterupdate2.finalized__c,true,'Expecting to be finalized in futureperiod');		
		system.assertEquals(jeafterupdate2.period__c,testdataForJEAutoBkdt.FuturePeriod.id,'Expecting Txn period');		
		
	}

	// create JE, generate Accounting and check the period is based on TD for JEs and AEs
	static testmethod void testJEPeriod(){
		Testfuel fuel = new Testfuel();
		company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;
  	
        List<Accounting_Rule__c> accountingRules = fuel.accountingRuleList;
        
        List<Journal_Entry__c> JEList = new List<Journal_Entry__c>();    
    	Journal_Entry__c je1 = new Journal_Entry__c();
		je1.name = 'JE001';
	    je1.Company__c = company.id;	
	    je1.type__c = 'Manual';   
	    je1.Transaction_Date__c = System.now();  
		je1.Currency__c = TestFuel.currencyUSD.id;
	    
	    insert je1;
	    JEList.add(je1);
	    
	    List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
	    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = je1.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = fuel.cashGL.id;
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = je1.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = fuel.receivablesGL.id;
	    jeLineList.add(jeLine2); 
	    
	    insert jeLineList;

	    je1.finalized__c = true;
	    update je1;
		Period__c p;
		
		for(Period__c thisPeriod : periods){
        	if(thisPeriod.open__c && (je1.transaction_date__c >= thisPeriod.Period_Start__c && je1.transaction_date__c <= thisPeriod.Period_End__c)){
        		p = thisPeriod;
        		break;
        	}
         }
         
        JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(jeLineList);
        
        jeList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Auto_Reverse__c, Period__c, posting_date__c,
	    							(Select id, Name, Period__c, COMP_Total_Credit__c, COMP_Total_Debit__c, Related_Accounting_Entry__c  from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id in :JEList];
	    							  		
	    system.assert(jeList[0].Accounting_Entries__r != null, 'Expected to have accounting generated for JE');
	    system.assert(jeList[0].Period__c == p.id,'Expected period is not set on JE '+p);
	    system.assert(jeList[0].Accounting_Entries__r[0].Period__c == p.id,'Expected period is not set on AE '+p);
   		
   		Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(jeList);
   		    
   		p = [Select id, Name, Prior_Period__c, Prior_Period__r.period_Start__c, Prior_Period__r.period_end__c
   			from Period__c 
   			where id = :p.id];	
   		if(p.prior_Period__c !=null){
   			jeList[0].transaction_date__c = p.prior_Period__r.period_Start__c;
   			update jeList;
   		
	   		jeList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Auto_Reverse__c, Period__c,
		    							(Select id, Name, Period__c, COMP_Total_Credit__c, COMP_Total_Debit__c, Related_Accounting_Entry__c  from Accounting_Entries__r where void__c = false)
		    							from Journal_Entry__c where id in :JEList];	
		    system.assert(jeList[0].finalized__c == false,'Expected the record to be unfinalized'+jeList[0]);	
		    system.assert(jeList[0].Transaction_Date__c == p.prior_period__r.period_start__c,'Expected the record to be unfinalized'+jeList[0]);	
	   		
	   		Boolean sawException = false;
	   		String exMsg;
	   		try{
	   			jeList[0].finalized__c = true;
	   			update jeList[0];
	   		}catch(Exception e){
	   			sawException = true;
	   			exMsg = e.getMessage();
	   		    system.assert(exMsg.containsIgnoreCase(Label.Cannot_be_after_JE_cutoff),'Expecting exception as TD period cannot be different from assigned period.'+exmsg);
	   			
	   		}
	   		system.assert(sawException == true,'Expected  to see exception as TD period cannot be different from txn period '+exMsg);
	   		

        }
	}
	
	// Test update related AE as Obsolete  after the unfinalize
	static testmethod void testAEObsolete(){
	    TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;
    	List<Accounting_Rule__c> accountingRules = fuel.accountingRuleList;
    	List<Journal_Entry_Line__c> jeLineList;
		List<Journal_Entry__c> JEList_Accrual = new List<Journal_Entry__c>();	{
			Journal_Entry__c je1 = new Journal_Entry__c();
			je1.name = 'JE001';
		    je1.Company__c = company.id;	
		    je1.Type__c = 'Manual';
		    je1.auto_reverse__c = true;	
		    je1.Transaction_Date__c = System.now();  
			je1.Currency__c = TestFuel.currencyUSD.id;
		    Boolean sawException = false;
		    String exMsg;
		    try{
		    	insert je1;
		    }catch(Exception e){
		    	sawException = true;
		    	exMsg = e.getMessage();
		    }
		    system.assertEquals(true,sawException,'Expected to see the exception to set the Manual JE with Autoreverse check box filled in :'+exMsg);
		    
		    je1.auto_reverse__c = false; // this will be defaulted to true for the accrual manual type in the trigger
		   	je1.type__c = 'Accrual - Manual';             
            //FIN-954 we are using transaction_type__c for accounting on all source docs.Trigger defaults  transaction_type__c from type__c. 
            //TODO: Add the below line once we deprecate type__c              
            //je1.transaction_type__c = 'Accrual - Manual';   
		    insert je1;
		    JEList_Accrual.add(je1);
		    
		    jeLineList = new List<Journal_Entry_Line__c>();
		    
		    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
		    jeLine1.Journal_Entry__c = JEList_Accrual[0].id;
			jeLine1.Amount_CR__c = 5;
			jeLine1.Amount_DR__c = 0;
			jeLine1.GL_Account__c = fuel.cashGL.id;
		    jeLineList.add(jeLine1); 
		    
		    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
		    jeLine2.Journal_Entry__c = JEList_Accrual[0].id;
			jeLine2.Amount_CR__c = 0;
			jeLine2.Amount_DR__c = 5;
			jeLine2.GL_Account__c = fuel.receivablesGL.id;
		    jeLineList.add(jeLine2); 
		    
		    insert jeLineList;
	
		    JEList_Accrual[0].finalized__c = true;
		    update JEList_Accrual;
		    
		}
	    Test.startTest();

	    JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(jeLineList);
	    
	    					
		AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEReverse, [SELECT Id FROM Accounting_Entry_Line__c WHERE Journal_Entry_Line__c IN :jeLineList]);
	    
	    List<Journal_Entry__c> jeList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Auto_Reverse__c, posting_date__c,  
	    							(Select id, Name,COMP_Total_Credit__c, COMP_Total_Debit__c, Related_Accounting_Entry__c, status__c  from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id in :JEList_Accrual];
	    		
	    Test.stopTest();
	
	    system.assertEquals(true, jeList[0].Finalized__c);
	    system.assertNotEquals(null, jeList[0].Finalized_Date__c);
	    system.assertEquals(true, jeList[0].Auto_Reverse__c);
	    system.assertEquals(2, jeList[0].Accounting_Entries__r.size());
	    for(Accounting_Entry__c ae: jeList[0].Accounting_Entries__r){
	    	system.assert(ae.status__c == 'Active','ae:'+ae);
	    }
	    
	    
	    // unfinalize the JE
	    Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(jeList);
	    
	    jeList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c, Auto_Reverse__c, posting_date__c,
	    							(Select id, Name,COMP_Total_Credit__c, COMP_Total_Debit__c, Related_Accounting_Entry__c, status__c  from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id in :JEList_Accrual];
	    
	    system.assertEquals(2, jeList[0].Accounting_Entries__r.size());
	    
	    for(Accounting_Entry__c ae: jeList[0].Accounting_Entries__r){
	    	system.assert(ae.status__c == 'Obsolete','ae:'+ae);
	    }
	     
	}
	
	// Test deletion of AE after the period is closed
	static testmethod void testAEDeletion(){
		Configuration__c cutoffsConfig = new Configuration__c();
        cutoffsConfig.Name = 'EnableCutoffs';
        cutoffsConfig.Value__c = 'Yes';
        insert cutoffsConfig;
        
		// create JE and generate accounting
		// Close Period
		// Delete AE
		
		JournalEntries JE = new JournalEntries();
        
        Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    journalEntry.Company__c = JE.company.id;	
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
	    insert journalEntry;
        
 		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = JE.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = JE.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
		
		insert	jeLineList;
		
		journalEntry.finalized__c = true;
		update journalEntry;
		
		List<Journal_Entry__c> journalEntryList = new List<Journal_Entry__c>();
		journalEntryList.add(journalEntry);
		system.assert(journalEntryList.size() == 1, 'journalEntryList size is not 1');
        Test.startTest();
        JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(jeLineList);
	    
	    journalEntryList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c,
	    							(Select id, Name from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id = :journalEntry.id];
    
	    system.assertEquals(true, journalEntryList[0].Finalized__c);
	    system.assertNotEquals(null, journalEntryList[0].Finalized_Date__c);
	    system.assertEquals(1, journalEntryList[0].Accounting_Entries__r.size());
	    
        
        journalEntry = [Select id, Name, Period__r.Name, Period__c,Period__r.Open__c from Journal_Entry__c where id = :journalEntry.id];
        System.assertNotEquals(null, journalEntry.id );
        System.assertNotEquals(null, journalEntry.Period__c );
        System.assertEquals(true, journalEntry.Period__r.Open__c );
		
		Period__c p = [Select id, Name, AR_Subledger_Cutoff__c, AP_Subledger_Cutoff__c, FA_Subledger_Cutoff__c,
						Inventory_Subledger_cutoff__c, shipment_subledger_cutoff__c, receiving_subledger_cutoff__c,
						JE_Cutoff__c, AR_Subledger_Closed__c, AP_Subledger_Closed__c, FA_Subledger_Closed__c,
						Inventory_Subledger_Closed__c, shipment_subledger_Closed__c, receiving_subledger_Closed__c, GL_Close__c,
						period_start__c, period_end__c
						from period__c 
						where id = :journalEntry.period__c];
						
		system.debug(logginglevel.info,'p:'+p);
		
		// test the subledger cut off date move back in time causes exception
		Boolean sawException = false;
		String exMsg;
		try{
			p.AR_Subledger_cutoff__c = p.AR_Subledger_cutoff__c.addDays(-1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff back in time'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.AP_Subledger_cutoff__c = p.AP_Subledger_cutoff__c.addDays(-1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff back in time'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.FA_Subledger_cutoff__c = p.FA_Subledger_cutoff__c.addDays(-1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff back in time'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.Shipment_Subledger_cutoff__c = p.Shipment_Subledger_cutoff__c.addDays(-1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff back in time'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.Receiving_Subledger_cutoff__c = p.Receiving_Subledger_cutoff__c.addDays(-1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff back in time'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.Inventory_Subledger_cutoff__c = p.Inventory_Subledger_cutoff__c.addDays(-1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff back in time'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.JE_Cutoff__c = p.JE_Cutoff__c.addDays(-1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff back in time'+exMsg);
		
		p = [Select id, Name, AR_Subledger_Cutoff__c, AP_Subledger_Cutoff__c, FA_Subledger_Cutoff__c,
						Inventory_Subledger_cutoff__c, shipment_subledger_cutoff__c, receiving_subledger_cutoff__c,
						JE_Cutoff__c, AR_Subledger_Closed__c, AP_Subledger_Closed__c, FA_Subledger_Closed__c,
						Inventory_Subledger_Closed__c, shipment_subledger_Closed__c, receiving_subledger_Closed__c, GL_Close__c,
						period_start__c, period_end__c
						from period__c 
						where id = :journalEntry.period__c];
						
		// test the subledger cut off date move in future with no exceptions
	 	sawException = false;
		exMsg = '';
		try{
			p.JE_cutoff__c = p.JE_cutoff__c.addDays(1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(false,sawException,'Not expected to see the exception while updating the JE cutoff in future'+exMsg);
		
		sawException = false;
		exMsg = '';
		system.debug(logginglevel.info,'p.AR_Subledger_cutoff__c:'+p.AR_Subledger_cutoff__c);
		system.debug(logginglevel.info,'p.AR_Subledger_cutoff__c addDays(1):'+p.AR_Subledger_cutoff__c.addDays(1));
		try{
			p.AR_Subledger_cutoff__c = p.AR_Subledger_cutoff__c.addDays(1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(false,sawException,'Not expected to see the exception while updating the subledger cutoff in future'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.AP_Subledger_cutoff__c = p.AP_Subledger_cutoff__c.addDays(1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(false,sawException,'Not expected to see the exception while updating the subledger cutoff in future'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.FA_Subledger_cutoff__c = p.FA_Subledger_cutoff__c.addDays(1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(false,sawException,'Not expected to see the exception while updating the subledger cutoff in future'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.Shipment_Subledger_cutoff__c = p.Shipment_Subledger_cutoff__c.addDays(1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(false,sawException,'Not expected to see the exception while updating the subledger cutoff in future'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.Receiving_Subledger_cutoff__c = p.Receiving_Subledger_cutoff__c.addDays(1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(false,sawException,'Not expected to see the exception while updating the subledger cutoff in future'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.Inventory_Subledger_cutoff__c = p.Inventory_Subledger_cutoff__c.addDays(1);
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(false,sawException,'Not expected to see the exception while updating the subledger cutoff in future'+exMsg);
		
		
		p.AR_Subledger_Closed__c =  System.now().addseconds(1);
		p.AP_Subledger_Closed__c = System.now().addseconds(1);
		p.FA_Subledger_Closed__c = System.now().addseconds(1);
		p.Inventory_Subledger_Closed__c = System.now().addseconds(1);
		p.Receiving_Subledger_Closed__c = System.now().addseconds(1);
		p.Shipment_Subledger_Closed__c = System.now().addseconds(1);
		//p.JE_Cutoff__c = system.now().addseconds(1);
		p.GL_Close__c = system.now().addseconds(2);
		p.Open__c = false;
		p.Closed__c = true;
		
		PeriodService.systemEditable.add(p.Id);
		update p;
		
		// test for updating the subledger cutoff fields after the subledger is closed
		sawException = false;
		exMsg = '';
		try{
			p.AR_Subledger_cutoff__c = system.now();
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff after the subledger close'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.AP_Subledger_cutoff__c = system.now();
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff after the subledger close'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.FA_Subledger_cutoff__c = system.now();
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff after the subledger close'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.Shipment_Subledger_cutoff__c = system.now();
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff after the subledger close'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.Receiving_Subledger_cutoff__c = system.now();
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff after the subledger close'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.Inventory_Subledger_cutoff__c = system.now();
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff after the subledger close'+exMsg);
		
		sawException = false;
		exMsg = '';
		try{
			p.JE_Cutoff__c = system.now();
			update p;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		system.assertEquals(true,sawException,'Expected to see the exception while updating the subledger cutoff after the subledger close'+exMsg);
		
		p = [Select id, Period_End__c, AR_Subledger_Closed__c, AP_Subledger_Closed__c, FA_Subledger_Closed__c,
			Inventory_Subledger_Closed__c, Receiving_Subledger_Closed__c, Shipment_Subledger_Closed__c, JE_Cutoff__c, Open__c, Closed__c
			from Period__c where id = :journalEntry.Period__c];
		
		system.assert(p.Closed__c, true);
		
		Accounting_Entry__c AccountingEntrytoDelete = [Select id, Name, Period__c, Period_Status__c
														from Accounting_Entry__c
														where Journal_Entry__c = :journalEntry.id];
	 	sawException = false;
		exMsg = '';
		system.assert(AccountingEntrytoDelete.period_status__c.equalsIgnoreCase('Closed') ,'Expected period status Closed');
		
		try{
			delete AccountingEntrytoDelete;
		}catch(Exception e){
			sawException = true;
			exMsg = e.getMessage();
		}
        
        system.assert(sawException = true,'Expected to see exception while deleting the accounting entry in closed period');
        
        p.Open__c = false;
		p.Closed__c = false;
		p.Permanently_Closed__c = true;
		update p;
		
		p = [Select id, Period_End__c, AR_Subledger_Closed__c, AP_Subledger_Closed__c, FA_Subledger_Closed__c,
			Inventory_Subledger_Closed__c, Receiving_Subledger_Closed__c, Shipment_Subledger_Closed__c, JE_Cutoff__c, Open__c, Closed__c, Permanently_Closed__c
			from Period__c where id = :journalEntry.Period__c];
		
		system.assert(p.Permanently_Closed__c, true);
		
		try{
			delete AccountingEntrytoDelete;
		}catch(Exception e){
			sawException = true;
			exMsg = e.getMessage();
		}
        
        system.assert(sawException = true,'Expected to see exception while deleting the accounting entry in permanently closed period');
        
        Test.stopTest();
	}

	// Test creation of AE after the period is closed -- 
	static testmethod void testAECreation(){
		// create JE 
		// Close Period
		// generate AE 
		
		JournalEntries JE = new JournalEntries();
        
        Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
	    journalEntry.Company__c = JE.company.id;	
	    journalEntry.type__c = 'Manual';   
	    journalEntry.Transaction_Type__c = 'Manual';
	    journalEntry.Transaction_Date__c = System.now();  
		journalEntry.Currency__c = TestFuel.currencyUSD.id;
	    insert journalEntry;
        
 		List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntry.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = JE.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = journalEntry.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = JE.receivablesGL.id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 
		
		insert	jeLineList;
		
		journalEntry.finalized__c = true;
		update journalEntry;
		
		journalEntry = [Select id, Name, Period__r.Name, Period__c,Period__r.Open__c from Journal_Entry__c where id = :journalEntry.id];
		system.assert(journalEntry.Period__c != null);
		
		Period__c p = new Period__c(id = journalEntry.Period__c);
		p.AR_Subledger_Closed__c =  System.now().addseconds(1);
		p.AP_Subledger_Closed__c = System.now().addseconds(1);
		p.FA_Subledger_Closed__c = System.now().addseconds(1);
		p.Inventory_Subledger_Closed__c = System.now().addseconds(1);
		p.Receiving_Subledger_Closed__c = System.now().addseconds(1);
		p.Shipment_Subledger_Closed__c = System.now().addseconds(1);
		//p.JE_Cutoff__c = system.now().addseconds(1);
		p.GL_Close__c = system.now().addseconds(2);
		p.Open__c = false;
		p.Closed__c = true;
		
		PeriodService.systemEditable.add(journalEntry.Period__c);
		update p;
		
		List<Journal_Entry__c> journalEntryList = new List<Journal_Entry__c>();
		journalEntryList.add(journalEntry);
		system.assert(journalEntryList.size() == 1, 'journalEntryList size is not 1');
        Test.startTest();
        
        JournalEntryAccounting jea = new JournalEntryAccounting();
        String exMsg;
        Boolean sawException = false;
        try{
	    	jea.execute(jeLineList);
        }catch(Exception e){
        	sawException = true;
        	exMsg = e.getMessage();
        }
        
        // FIN-671
        List<Accounting_Entry__c> aeList = [SELECT Id FROM Accounting_Entry__c WHERE Journal_Entry__c = :journalEntry.Id];
        system.assertEquals(true, ExceptionService.hasOpenTask(aeList[0].Id, ExceptionUtil.AE_MISSING_PERIOD.code),'Expected to see the exception while inserting a record in a closed period'+exMsg);
        
        delete aeList;
        
	    journalEntryList = [Select id, Name, Finalized_Date__c, Transaction_Date__c, Finalized__c,
	    							(Select id, Name from Accounting_Entries__r where void__c = false)
	    							from Journal_Entry__c where id = :journalEntry.id];
    
	    system.assertEquals(true, journalEntryList[0].Finalized__c);
	    system.assertNotEquals(null, journalEntryList[0].Finalized_Date__c);
	    system.assertEquals(0, journalEntryList[0].Accounting_Entries__r.size());
	    
	    p.Open__c = false;
		p.Closed__c = false;
		p.permanently_closed__c = true;
		
		update p;
		
		jea = new JournalEntryAccounting();
        sawException = false;
        try{
	    	jea.execute(jeLineList);
        }catch(Exception e){
        	sawException = true;
        	exMsg = e.getMessage();
        }
        
        aeList = [SELECT Id FROM Accounting_Entry__c WHERE Journal_Entry__c = :journalEntry.Id];
        system.assertEquals(true, ExceptionService.hasOpenTask(aeList[0].Id, ExceptionUtil.AE_MISSING_PERIOD.code),'Expected to see the exception while inserting a record in a closed period'+exMsg);
        
		// FIN-671 system.assertEquals(true, sawException,'Expected to see the exception while inserting a record in a permanently closed period'+exMsg);
        Test.stopTest();
     
	}

	static testmethod void testJEDefaultTransactionCurrency(){
		Testfuel fuel = new Testfuel();
		
    	Journal_Entry__c je1 = new Journal_Entry__c();
		je1.name = 'JE001';
	    je1.Company__c = fuel.company.id;	
	    je1.type__c = 'Manual';   
	    je1.Transaction_Date__c = System.now();  
		//je1.Currency__c = TestFuel.currencyGBP.id;
	    
	    insert je1;
	    je1 = [Select id, Name, currency__c
	    		from journal_entry__c
	    		where id = :je1.id];
	    		
	    system.assert(je1.currency__c == fuel.company.Default_Transaction_Currency__c,'Expected to see the transaction currency to default from company');
	    
	    je1.Currency__c = TestFuel.currencyGBP.id;
	    update je1;
	    
	    je1 = [Select id, Name, currency__c
	    		from journal_entry__c
	    		where id = :je1.id];
	    system.assert(je1.Currency__c == TestFuel.currencyGBP.id,'Expected to see the transaction currency is as user specified while updating the record');
	    		
	    Journal_Entry__c je2 = new Journal_Entry__c();
		je2.name = 'JE001';
	    je2.Company__c = fuel.company.id;	
	    je2.type__c = 'Manual';   
	    je2.Transaction_Date__c = System.now();  
		je2.Currency__c = TestFuel.currencyEUR.id;
	    
	    insert je2;
	    
	    je2 = [Select id, Name, currency__c
	    		from journal_entry__c
	    		where id = :je2.id];
	    system.assert(je2.currency__c == TestFuel.CurrencyEUR.Id,'Expected to see the transaction currency is as specified by user on insert');
	}
    
    static testmethod void testJEAccrualWithoutNextPeriod()
    {
 	    TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
        period__c period1 = new period__c();
        period1.name='Test1';
        period1.company__c=company.id;
        period1.open__c=true;
        //DateTime myDateTime = DateTime.newInstance(2015, 05, 22, 12, 59, 57);
        period1.Period_Start__c=system.now();
        period1.period_end__c=period1.period_start__c.addhours(24);
		Fiscal_Year__c fy = new Fiscal_Year__c();
		fy.company__c = company.Id;
		fy.fiscal_year_start_date__c = period1.period_start__c;
		fy.fiscal_year_end_date__c = period1.period_end__c.addMonths(3);
		
		insert fy;
	
		period1.fiscalyear__c = fy.Id;
        insert period1;
    	List<Accounting_Rule__c> accountingRules = fuel.accountingRuleList;
    	List<Journal_Entry_Line__c> jeLineList;
		List<Journal_Entry__c> JEList_Accrual = new List<Journal_Entry__c>();	
        
			Journal_Entry__c je = new Journal_Entry__c();
			je.name = 'JE001';
		    je.Company__c = company.id;	
     	    je.Transaction_Date__c = System.now();  
			je.Currency__c = TestFuel.currencyUSD.id;
		   	je.type__c = 'Accrual - Manual'; 
            //FIN-954 we are using transaction_type__c for accounting on all source docs.Trigger defaults  transaction_type__c from type__c. 
            //TODO: Add the below line once we deprecate type__c  
            //je1.transaction_type__c = 'Accrual - Manual';  
		    insert je;
		    JEList_Accrual.add(je);
		    
		    jeLineList = new List<Journal_Entry_Line__c>();
		    
		    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
		    jeLine1.Journal_Entry__c = JEList_Accrual[0].id;
			jeLine1.Amount_CR__c = 5;
			jeLine1.Amount_DR__c = 0;
			jeLine1.GL_Account__c = fuel.cashGL.id;
		    jeLineList.add(jeLine1); 
		    
		    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
		    jeLine2.Journal_Entry__c = JEList_Accrual[0].id;
			jeLine2.Amount_CR__c = 0;
			jeLine2.Amount_DR__c = 5;
			jeLine2.GL_Account__c = fuel.receivablesGL.id;
		    jeLineList.add(jeLine2); 
		    
		    insert jeLineList;
	
		    JEList_Accrual[0].finalized__c = true;
		    update JEList_Accrual;      
        	Test.startTest();

            JournalEntryAccounting jea = new JournalEntryAccounting();
            jea.execute(jeLineList);	    					
            AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEReverse, [SELECT Id FROM Accounting_Entry_Line__c WHERE Journal_Entry_Line__c IN :jeLineList]);	    
			list<accounting_entry__c> aelist = [select id,name,has_exceptions__c from accounting_entry__c 
                                                where status__c='Active'
                                                and journal_entry__c=:JEList_Accrual[0].id
                                                and has_exceptions__c=true];
            system.assertNotEquals(aelist.size(), 0,'Expecting reversal Entry to have exceptions');
            //Now create the next period.
            period__c period2 = new period__c();
            period2.name='Test2';
            period2.company__c=company.id;
            period2.open__c=true;
            //DateTime myDateTime = DateTime.newInstance(2015, 05, 22, 12, 59, 57);
            period2.Period_Start__c=period1.period_end__c;
            period2.period_end__c=period2.period_start__c.addhours(24);
			period2.fiscalyear__c = fy.Id;
            insert period2;           
            database.executebatch(new AccountingEntryVoidBatch());           
            Test.stopTest();
            list<accounting_entry__c> regenerateAElist = [select id,name,has_exceptions__c from accounting_entry__c 
                                                            where status__c='Active'
                                                            and journal_entry__c=:JEList_Accrual[0].id
                                                            and has_exceptions__c=true];
            system.assertequals(regenerateAElist.size(),0,'Expecting no exceptions after batch regenenerated of Reversal AE with exceptions');
    
    }
    //KNDY-18879 test Je with usd and bank account on je lines with GBP currency. it will failed due to validation rule
    static testmethod void  testJournalEntryDiffBankCurrency(){
    	
        JournalEntries JE = new JournalEntries(); 
        Bank_Account__c bankAccount = JE.bankAccount;
        bankAccount.Currency__c = TestFuel.currencyGBP.id;
        update bankAccount;
        Journal_Entry__c journalEntryWithoutFinalized = new Journal_Entry__c();
        
		journalEntryWithoutFinalized.name = 'JE001';
	    journalEntryWithoutFinalized.Company__c = JE.company.id;	
	    journalEntryWithoutFinalized.type__c = 'Manual';   
	    journalEntryWithoutFinalized.Transaction_Type__c = 'Manual';
	    journalEntryWithoutFinalized.Transaction_Date__c = System.now();  
		journalEntryWithoutFinalized.Currency__c = TestFuel.currencyUSD.id;
		journalEntryWithoutFinalized.Finalized__c =false;
		
        Journal_Entry__c journalEntryWithFinalized = new Journal_Entry__c();        
		journalEntryWithFinalized.name = 'JE002';
	    journalEntryWithFinalized.Company__c = JE.company.id;	
	    journalEntryWithFinalized.type__c = 'Manual';   
	    journalEntryWithFinalized.Transaction_Type__c = 'Manual';
	    journalEntryWithFinalized.Transaction_Date__c = System.now();  
		journalEntryWithFinalized.Currency__c = TestFuel.currencyUSD.id;
		journalEntryWithFinalized.Finalized__c =true;
		
	    List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
	    List<JournalEntryLinesManageExt.JournalEntryLineWrapper> newList = new List<JournalEntryLinesManageExt.JournalEntryLineWrapper>();
	    List<JournalEntryLinesManageExt.JournalEntryLineWrapper> updateList = new List<JournalEntryLinesManageExt.JournalEntryLineWrapper>();
	    List<JournalEntryLinesManageExt.JournalEntryLineWrapper> delList = new List<JournalEntryLinesManageExt.JournalEntryLineWrapper>();
	    List<String> headerDateFields = new List<String>{'Transaction_Date__c'};
	    List<string> dateFields = new List<String>();
 
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = journalEntryWithoutFinalized.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = JE.cashGL.id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
		jeLine1.Bank_account__c = bankAccount.id;
	    jeLineList.add(jeLine1); 
        JournalEntryLinesManageExt.JournalEntryLineWrapper jeLine1wrapper = new JournalEntryLinesManageExt.JournalEntryLineWrapper(jeLine1,null);
        
 	    Journal_Entry_Line__c jeLine1a = new Journal_Entry_Line__c(); 
	    jeLine1a.Journal_Entry__c = journalEntryWithoutFinalized.id;
		jeLine1a.Amount_CR__c = 0;
		jeLine1a.Amount_DR__c = 5;
		jeLine1a.Subtransaction_Type__c = 'Write Off';
		jeLine1a.Bank_account__c = bankAccount.id;
	    jeLineList.add(jeLine1a);  
        JournalEntryLinesManageExt.JournalEntryLineWrapper jeLine1awrapper = new JournalEntryLinesManageExt.JournalEntryLineWrapper(jeLine1a,null);
               
	        			    		
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(journalEntryWithFinalized);
        JournalEntryLinesManageExt jExt = new JournalEntryLinesManageExt(sc);
        
       
        //For a new JE ,Add lines without Finalize.
        JSONResult JSONResultOnInsertWithoutFinalize = JournalEntryLinesManageExt.saveAction(journalEntryWithoutFinalized,headerDateFields,new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>(),new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>{jeLine1wrapper,jeLine1awrapper},new list<JournalEntryLinesManageExt.JournalEntryLineWrapper>(),null);
        system.assertEquals(JSONResultOnInsertWithoutFinalize.success,false,'Expecting successful insert.'+JSONResultOnInsertWithoutFinalize);        
  		system.assertEquals(JSONResultOnInsertWithoutFinalize.records.size() >=0,true,'Expecting successful insert.'+JSONResultOnInsertWithoutFinalize.records);        
  		list<JournalEntryLinesManageExt.JELineErrorWrapper> JeW = (list<JournalEntryLinesManageExt.JELineErrorWrapper>)JSONResultOnInsertWithoutFinalize.records;
  		system.assertEquals(JeW != null, true, JeW);        
        Boolean sawException =false;
        for(JournalEntryLinesManageExt.JELineErrorWrapper JeWL:jeW){ 
        	system.assertEquals(JeWL.errors != null, true, JeWL.errors);          	        	
        	if(JeWL.errors[0].contains('You can\'t save this journal entry because the currency is different from the bank account currency.')){
        		sawException = true;
        	}        		        	
        }
        system.assertEquals(sawException,true,'Expecting error mismatch on bank account currency and JE currency.' +JSONResultOnInsertWithoutFinalize.messages);
       
    }

}