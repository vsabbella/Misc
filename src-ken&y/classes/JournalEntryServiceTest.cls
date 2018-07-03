@isTest
private class JournalEntryServiceTest {
	static Decimal manyDigits = 5.123456789;
	static Decimal storedDigits =   manyDigits.setScale(6,RoundingMode.FLOOR); // test for KNDY-6889
    
    static testMethod void validateJEStatusTest() {
    	JournalEntries JE = new JournalEntries();
    	Journal_Entry__c je1 = new Journal_Entry__c();
			je1.name = 'JE001';
		    je1.Company__c = JE.company.id;	
		    je1.type__c = 'Manual';   
		    je1.Transaction_Type__c = 'Manual';
		    je1.Transaction_Date__c = System.now();  
		    //je1.GL_Date__c = System.today();  
			je1.Currency__c = TestFuel.currencyUSD.id;
			//je1.Finalized__c = true;		
		 insert je1;
		 je1.status__c = 'Cancelled';
		 update je1;
		 je1.Transaction_Type__c = 'Accrual - Manual';
		 try{
		 	update je1;
		 }
		 catch(exception e){
		 		Boolean expectedExceptionThrown =  e.getMessage().contains('You cannot change Journal Entry after it is voided or cancelled') ? true : false;
				System.AssertEquals(expectedExceptionThrown, true);
		 }	
        
       	Journal_Entry__c je2 = [ select id, (select id, Amount_CR__c, Amount_DR__c from Journal_Entry_Lines__r ) 
                                from Journal_Entry__c where Description__c = 'JE002' limit 1];
        for ( Journal_Entry_Line__c jl : je2.Journal_Entry_Lines__r) {
        		system.assert( jl.Amount_CR__c == 0 || jl.Amount_CR__c == storedDigits, 'expected to store 6 digits');
            	system.assert( jl.Amount_DR__c == 0 || jl.Amount_DR__c == storedDigits, 'expected to store 6 digits');
        }
    }
    
    static testMethod void test_KSE_truncatedDifference() {
    	Boolean isDifferent = false;
    	Decimal CRAmt_o, DRAmt_o;
    	
    	CRAmt_o = 1.00000002;
	    DRAmt_o = 1.000007;
	    
	    isDifferent = KSE.isEqualDecimal(CRAmt_o,DRAmt_o);
	    system.assert(false == isDifferent,'CRAmt_o :'+CRAmt_o+' ---- DRAmt_o:'+DRAmt_o);
	    
    	CRAmt_o = 1.00000000;
	    DRAmt_o = 1.00000067;
	    
	    isDifferent = KSE.isEqualDecimal(CRAmt_o,DRAmt_o);
	    system.assert(true == isDifferent,'CRAmt_o :'+CRAmt_o+' ---- DRAmt_o:'+DRAmt_o);
	    
	    CRAmt_o = 1.00000002;
	    DRAmt_o = 1.00000067;
	    
	    isDifferent = KSE.isEqualDecimal(CRAmt_o,DRAmt_o);
	    system.assert(true == isDifferent,'CRAmt_o :'+CRAmt_o+' ---- DRAmt_o:'+DRAmt_o);
	    
	    CRAmt_o = 1.00000052;
	    DRAmt_o = 1.00000067;
	    
	    isDifferent = KSE.isEqualDecimal(CRAmt_o,DRAmt_o);
	    system.assert(true == isDifferent,'CRAmt_o :'+CRAmt_o+' ---- DRAmt_o:'+DRAmt_o);
	    
	    CRAmt_o = 1.00000059;
	    DRAmt_o = 1.00000067;
	    
	    isDifferent = KSE.isEqualDecimal(CRAmt_o,DRAmt_o);
	    system.assert(true == isDifferent,'CRAmt_o :'+CRAmt_o+' ---- DRAmt_o:'+DRAmt_o);
	    
	    CRAmt_o = -1.000009;
	    DRAmt_o = 1.000009;
	    
	    isDifferent = KSE.isEqualDecimal(CRAmt_o,DRAmt_o);
	    system.assert(false == isDifferent,'CRAmt_o :'+CRAmt_o+' ---- DRAmt_o:'+DRAmt_o);
	    
	    CRAmt_o = -1.000007;
	    DRAmt_o = -1.000006;
	    
	    isDifferent = KSE.isEqualDecimal(CRAmt_o,DRAmt_o);
	    system.assert(false == isDifferent,'CRAmt_o :'+CRAmt_o+' ---- DRAmt_o:'+DRAmt_o);
	    
	    CRAmt_o = -1.000003;
	    DRAmt_o = -1.0000006;
	    
	    isDifferent = KSE.isEqualDecimal(CRAmt_o,DRAmt_o);
	    system.assert(false == isDifferent,'CRAmt_o :'+CRAmt_o+' ---- DRAmt_o:'+DRAmt_o);
	    
	    CRAmt_o = 0;
	    DRAmt_o = 0;
	    
	    isDifferent = KSE.isEqualDecimal(CRAmt_o,DRAmt_o);
	    system.assert(true == isDifferent,'CRAmt_o :'+CRAmt_o+' ---- DRAmt_o:'+DRAmt_o);
    	
    	
    	CRAmt_o = null;
	    DRAmt_o = null;
	    
	    isDifferent = KSE.isEqualDecimal(CRAmt_o,DRAmt_o);
	    system.assert(true == isDifferent,'CRAmt_o :'+CRAmt_o+' ---- DRAmt_o:'+DRAmt_o);
    }
    
    public class JournalEntries {
    	
    	// create a accounting standard
		public Accounting_Standard__c accountingStandard = new Accounting_Standard__c();{
        	accountingStandard.name = 'US GAAP';
    		insert accountingStandard;
        }
        
        //create a bank account
        public Bank_Account__c bankAccount {
			get {
				if (bankAccount == null) {
	    			bankAccount = new Bank_Account__c(
	    				Name = 'Test BOFA',
	    				account_type__c = 'Checking',
	    				GL_Account__c = cashGL.id,
	    				Company__c = company.Id,
	    				Active__c = true,
	    				Currency__c = TestFuel.currencyUSD.id
					);
					insert bankAccount; 
					//company.Credit_Card_Bank_Account__c = bankAccount.Id;
					//update company;
				}
				return bankAccount;
			}
			set; 
	    }
        
		// create a company
        public Company__c company = new Company__c();{
	        company = new Company__c();
	        company.name = '100';
	        company.A_Days__c = 6;
	        company.B_Days__c = 20;
	        company.C_Days__c = 90;
	        company.Comp_Currency__c = TestFuel.currencySGD.id;
	        company.Consol_Currency__c = TestFuel.currencyEUR.id;
	        company.Stat_Currency__c = TestFuel.currencyGBP.id;
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
			fy.fiscal_year_end_date__c = periodList[periodList.size()-1].period_end__c;
			
			insert fy;
	
	    	for(Period__c p : periodList){
				p.fiscalyear__c = fy.Id;
	    	}
    		insert periodList;
   
    	}
        public Period__c zeroPeriod = new Period__c();{
    	Integer year = system.now().year();
        zeroPeriod.Name = 'P1';
        zeroPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
        zeroPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
        zeroPeriod.Type__c = 'Period 13';
        zeroPeriod.Period_Number__c = 2;
        zeroPeriod.Quarter_Number__c = 1;
        zeroPeriod.Company__c = company.Id;
        zeroPeriod.fiscalYear__c = periodList[0].fiscalyear__c;
        insert zeroPeriod;
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
        public GL_Type__c currentAssets{
    		get{
    			if(currentAssets == null){
    				currentAssets = new GL_Type__c();
    				currentAssets.Name  = 'Current Assets';
	    			currentAssets.Normal_Balance__c  = 'Debit';
	    			currentAssets.Accounting_Type__c  = 'Assets';
	    			currentAssets.Statement_Type__c  = 'Balance Sheet';
	    			currentAssets.Account_Range_From__c = '10000';
	    			currentAssets.Account_Range_To__c ='14999';
	    		
	    			insert currentAssets;
    			}
    			return currentAssets;
    		}
    		set;
    	}
        
	    public GL_Type__c currentLiabilities{
	    	get{
	    		if(currentLiabilities == null){
	    			currentLiabilities = new GL_Type__c();
	    			currentLiabilities.Name  = 'Current Liabilities';
			    	currentLiabilities.Normal_Balance__c  = 'Credit';
			    	currentLiabilities.Accounting_Type__c  = 'Liabilities';
			    	currentLiabilities.Statement_Type__c  = 'Balance Sheet';
			    	currentLiabilities.Account_Range_From__c = '20000';
			    	currentLiabilities.Account_Range_To__c ='24999';
		    		
		    		insert currentLiabilities;
	    		}
	    		return currentLiabilities;
	    	}
	    	set;
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
            jeRule1.Effective_Start_Date__c = datetime.newInstance(system.now().year()-1, 1, 1, 0, 0, 0);             
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
            jeRule2.Effective_Start_Date__c = datetime.newInstance(system.now().year()-1, 1, 1, 0, 0, 0);                                       
            jeRule2.Raise_Exceptions_for_Blank_Amounts__c=false;
            jeRule2.Suppress_Zero_Amount_Lines__c = true;                
            JEAccountingRules.add(jeRule2);            
        
        
			insert JEAccountingRules;	
		}
		public List<Journal_Entry_Line__c> jeLineList;
		public List<Journal_Entry__c> JEList = new List<Journal_Entry__c>();	{
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
			je2.name = 'JE002';
			je2.Description__c = 'JE002';
		    je2.Company__c = company.id;	
		    je2.type__c = 'Manual';   
		    je2.Transaction_Type__c = 'Manual';
		    je2.Transaction_Date__c = System.now();  
		    //je2.GL_Date__c = System.today();  
			je2.Currency__c = TestFuel.currencyUSD.id;
			//je2.Finalized__c = true;		
		    JEList.add(je2);
		    
		    insert JEList;    
			
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
		    
		    // these attach to JE#2
		    Journal_Entry_Line__c jeLine3 = new Journal_Entry_Line__c(); 
		    jeLine3.Journal_Entry__c = JEList[1].id;
			jeLine3.Amount_CR__c = manyDigits;
			jeLine3.Amount_DR__c = 0;
			jeLine3.GL_Account__c = cashGL.id;
			jeLine3.Subtransaction_Type__c = 'Write Off';
		    jeLineList.add(jeLine3); 
		    
		    Journal_Entry_Line__c jeLine4 = new Journal_Entry_Line__c(); 
		    jeLine4.Journal_Entry__c = JEList[1].id;
			jeLine4.Amount_CR__c = 0;
			jeLine4.Amount_DR__c = manyDigits;
			jeLine4.GL_Account__c = receivablesGL.id;
			jeLine4.Subtransaction_Type__c = 'Write Off';
		    jeLineList.add(jeLine4); 
		    
		    insert jeLineList;
		    
		    JEList[0].finalized__c = true;
		    JEList[1].finalized__c = true;
		    update JEList;
		}
		
		public Supplier__c supplier = new Supplier__c();{
        	supplier = new Supplier__c();
        	supplier.status__C = 'Active';
        	supplier.Name = 'Test Supplier';
        	supplier.Type__c = 'Purchasing';
        	insert supplier;        
    	}
    	
    	public Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();{
            suppInv1.Company__c = company.id;
            suppInv1.Invoice_Type__c = 'Invoice';
            suppInv1.Date_Invoiced__c = System.now();
            suppInv1.Currency__c = TestFuel.currencyUSD.id;
            suppInv1.Supplier__c = supplier.id;
            //suppInv1.Amount_Due__c = data.purchaseOrder2.Purchase_Order_Value__c;
            suppInv1.Invoice_Amount__c = 10;
            suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
            suppInv1.Finalized__c = false;
            insert suppInv1;
		}
		//Add Class
		public Class__c clsObj = new Class__c();{
			clsObj.name = 'Class-1';
        	clsObj.Type__c= 'Goods';
        	insert clsObj;
		}
		
		public UOM__c uomObj = new UOM__c();{
		    
            uomObj.Name = 'EA';
            uomObj.Description__c = 'EA';
            insert uomObj;            
		}
		
		// Add item 
		public Item__c Item = new Item__c();{
        	Item.name='HP Printer 3';
        	Item.Description__c='It is a Test item';
        	Item.Source__c='Miscellaneous';
        	Item.Non_Inventory__c = true;
        	Item.Company__c = company.id;
        	Item.class__c = clsObj.id;
        	Item.Stocking_UOM__c = uomObj.Id;
            Item.Packaging_UOM__c = JSON.serialize(new List<Id>{ uomObj.Id });
         	insert Item;
		}
		// Add Supplier Invoice Line
		Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); {
            //suppInvLine1.Supplier__c = data.remittosupplier.id;
            suppInvLine1.Supplier_Invoice__c = suppInv1.id;
            suppInvLine1.Line_Type__c = 'Standard';
            suppInvLine1.Extended_Cost__c = 50;
            suppInvLine1.Invoice_Quantity__c = 1;
            suppInvLine1.Unit_Price__c = 10;//KNDY-14371
            suppInvLine1.Item__c = Item.id;
 
            insert suppInvLine1;
            
            suppInv1.finalized__c = true;
            update suppInv1;
            
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

	static testMethod void copyJELdescriptionToAELTest(){

 		JournalEntries JE = new JournalEntries();
        Test.startTest();
	   
	    JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(JE.jeLineList);

        Test.stopTest();
        //This list will return one AEL 
        List<Accounting_Entry_Line__c> aelsGeneratedList = [SELECT ID, Journal_Entry_Line__c, Description__c FROM Accounting_Entry_Line__c WHERE Journal_Entry_Line__c = : JE.jeLineList[0].id];
        system.assert(aelsGeneratedList.size() > 0);                
        system.assertEquals(aelsGeneratedList[0].Description__c, JE.jeLineList[0].Description__c);

	}
	
    static testMethod void test_YearEndAdjustmentInsert() {
 		JournalEntries JE = new JournalEntries();
        
			period__c pr = [Select Id,FiscalYear__r.Fiscal_Year_End_Date__c from period__c where id =: JE.Zeroperiod.id];
			Journal_Entry__c je1 = new Journal_Entry__c();
			je1.name = 'JE001';
		    je1.Company__c = JE.company.id;	
		    je1.type__c = 'Year End Adjustment';   
		    je1.Transaction_Type__c = 'Year End Adjustment';
		    je1.Transaction_Date__c = pr.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1);  
		    je1.gl_date_time__c = je1.Transaction_Date__c;  
		    je1.posting_Date__c = je1.Transaction_Date__c;  
			je1.Currency__c = TestFuel.currencyUSD.id;
    
		    try{
		    	insert je1;
    		}    
			catch(exception e){
				system.assert(e.getmessage().contains('When the Type field is Year End Adjustment, a value in the Period field is required.'), 'e :  ' + e);
			}
		    
			je1.period__c = JE.Zeroperiod.id;
			
			insert je1;
			period__c pr1 = [Select Id,FiscalYear__r.Fiscal_Year_End_Date__c from period__c where id =: JE.Zeroperiod.id];
			Journal_Entry__c jenew = [Select Id,Transaction_Date__c from Journal_Entry__c where id =: je1.id];
			system.assert(jenew.Transaction_Date__c == pr1.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1),'jenew.Transaction_Date__c = ' + jenew.Transaction_Date__c + 'pr.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1)  =  ' + pr1.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1) + 'Je1.id = ' + je1.id);
			
    }

    static testMethod void test_YearEndAdjustmentInsertwithYearEndAlreadyexisting() {
 		JournalEntries JE = new JournalEntries();
        
			period__c pr = [Select Id,FiscalYear__r.Fiscal_Year_End_Date__c from period__c where id =: JE.Zeroperiod.id];
			Journal_Entry__c je1 = new Journal_Entry__c();
			je1.name = 'JE001';
		    je1.Company__c = JE.company.id;	
		    je1.type__c = 'Year End';   
		    je1.Transaction_Type__c = 'Year End Adjustment';
		    je1.Transaction_Date__c = pr.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1);  
		    je1.gl_date_time__c = je1.Transaction_Date__c;  
		    je1.posting_Date__c = je1.Transaction_Date__c;  
			je1.Currency__c = TestFuel.currencyUSD.id;
			je1.period__c = JE.Zeroperiod.id;
		    insert je1;
    
			Journal_Entry__c je2 = new Journal_Entry__c();
			je2.name = 'JE001';
		    je2.Company__c = JE.company.id;	
		    je2.type__c = 'Year End';   
		    je2.Transaction_Type__c = 'Year End Adjustment';
		    je2.Transaction_Date__c = System.now();  
			je2.Currency__c = TestFuel.currencyUSD.id;
			je2.period__c = JE.Zeroperiod.id;
		    try{
		    	insert je2;
    		}    
			catch(exception e){
				system.assert(e.getmessage().contains('You cannot create adjusting journal entries for this year because net income has already been transferred to retained earnings. To create adjusting entries, you must first cancel the balance transfer in the Fiscal Year Close window'));
			}		    
			
    }
    static testMethod void test_YearEndAdjustmentCancel() {
 		JournalEntries JE = new JournalEntries();
        
			period__c pr = [Select Id,FiscalYear__r.Fiscal_Year_End_Date__c from period__c where id =: JE.Zeroperiod.id];

			Journal_Entry__c je2 = new Journal_Entry__c();
			je2.name = 'JE001';
		    je2.Company__c = JE.company.id;	
		    je2.type__c = 'Year End Adjustment';   
		    je2.Transaction_Type__c = 'Year End Adjustment';
		    je2.Transaction_Date__c = pr.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1);  
		    je2.gl_date_time__c = je2.Transaction_Date__c;  
		    je2.posting_Date__c = je2.Transaction_Date__c;  
			je2.Currency__c = TestFuel.currencyUSD.id;
			je2.period__c = JE.Zeroperiod.id;
			je2.finalized__c = false;
		    	insert je2;
			
	        list<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
	        
	        Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	        jeLine1.Journal_Entry__c = je2.id;
	        jeLine1.Amount_CR__c = 500;
	        jeLine1.Amount_DR__c = 0;
	        jeLine1.GL_Account__c = JE.cashGL.id;
	        jeLineList.add(jeLine1); 
	        
	        Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	        jeLine2.Journal_Entry__c = je2.id;
	        jeLine2.Amount_CR__c = 0;
	        jeLine2.Amount_DR__c = 500;
	        jeLine2.GL_Account__c = JE.receivablesGL.id;
	        jeLineList.add(jeLine2);
	        
	        insert jeLineList;
	        
			je2.finalized__c = true;
			je2.finalized_date__c = system.now();
			update je2;
			Journal_Entry__c je1 = new Journal_Entry__c();
			je1.name = 'JE001';
		    je1.Company__c = JE.company.id;	
		    je1.type__c = 'Year End';   
		    je1.Transaction_Date__c = pr.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1);  
		    je1.gl_date_time__c = je1.Transaction_Date__c;  
		    je1.posting_Date__c = je1.Transaction_Date__c;  
		    je1.Transaction_Type__c = 'Year End Adjustment';
		    je1.Transaction_Date__c = pr.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1);  
		    je1.gl_date_time__c = je1.Transaction_Date__c;  
		    je1.posting_Date__c = je1.Transaction_Date__c;  
			je1.Currency__c = TestFuel.currencyUSD.id;
			je1.period__c = JE.Zeroperiod.id;
		    insert je1;
    		
  		    list<journal_entry__c> JEListbefore = [select id, name , status__c, Company__c, type__c, Transaction_Type__c, Transaction_Date__c, Currency__c, period__c, finalized__c, Finalized_Date__c, void__c, Posting_Date__c from journal_entry__c where id=: je2.id];
    		JournalEntryVoidCancelExt ext = new JournalEntryVoidCancelExt(new ApexPages.standardController(JEListbefore[0]));
    		ext.cancelDocs();
		    list<journal_entry__c> JEList = [select id, name , status__c from journal_entry__c where id=: je2.id];
		    system.assert(JEList[0].status__c == 'Cancelled', 'JE should be cancelled');
    }
    static testMethod void test_AutoInverseJELCantHaveBankAccountPopulated() {
 		JournalEntries JE = new JournalEntries();
        
			period__c pr = [Select Id,FiscalYear__r.Fiscal_Year_End_Date__c from period__c where id =: JE.Zeroperiod.id];
			Journal_Entry__c je2 = new Journal_Entry__c();
			je2.name = 'JE001';
		    je2.Company__c = JE.company.id;	
		    je2.type__c = 'Accrual - Manual';   
		    je2.Transaction_Date__c = pr.FiscalYear__r.Fiscal_Year_End_Date__c.addSeconds(-1);  
		    je2.gl_date_time__c = je2.Transaction_Date__c;  
		    je2.posting_Date__c = je2.Transaction_Date__c;  
			je2.Currency__c = TestFuel.currencyUSD.id;
			je2.period__c = JE.Zeroperiod.id;
			je2.finalized__c = false;
		    insert je2;
			system.assert([Select Auto_Reverse__c from Journal_Entry__c where Id =:je2.Id].Auto_Reverse__c,'Incorrect Auto_Reverse__c value');
	        list<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
	        
	        Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	        jeLine1.Journal_Entry__c = je2.id;
	        jeLine1.Amount_CR__c = 500;
	        jeLine1.Amount_DR__c = 0;
	        jeLine1.GL_Account__c = JE.cashGL.id;
	        jeLine1.Bank_Account__c = JE.bankAccount.Id;
	        jeLineList.add(jeLine1); 
	        
	        Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	        jeLine2.Journal_Entry__c = je2.id;
	        jeLine2.Amount_CR__c = 0;
	        jeLine2.Amount_DR__c = 500;
	        jeLine2.GL_Account__c = JE.receivablesGL.id;
	        jeLine1.Bank_Account__c = JE.bankAccount.Id;
	        jeLineList.add(jeLine2);
	        boolean isException = false;
	        Test.startTest();
	        try{
	        	insert jeLineList;
	        }catch(dmlexception ex){
	        	if(ex.getMessage().contains(label.Auto_Reverse_field_is_selected)){
	        		isException = true;
	        	}
	        }
	        system.assert(isException,'Validation Failed.');
	        
	        jeLine1.Bank_Account__c = null;
	        jeLine2.Bank_Account__c = null;
	        
	        isException = false;
	        try{
	        	insert jeLineList;
	        }catch(dmlexception ex){
	        	if(ex.getMessage().contains(label.Auto_Reverse_field_is_selected)){
	        		isException = true;
	        	}
	        }
	        system.assert(!isException,'Validation Failed.');
	        Test.stopTest();
    }
}