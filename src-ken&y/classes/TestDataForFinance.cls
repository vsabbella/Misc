/**
 *  @description: This class contains the data to be used in test methods.
 *  This class contains variables declared as properties (using getters and setters).
 *  The properties are initialized ONLY ONCE and only at the time of access from the test methods in apex classes.
 *   
    Steps to test the accounting entry creation
    1. Create Company
    2. Create Facility
    3. Create Location
    4. Create Accounting Rules
    5. Create GL Accounts
    6. Create Accounting Defaults
    7. Create Periods
    8. Create Exchange Rates
    9. Create Items
    10. Create Class
    11. Create Product
    12. Create Item Costs
    13. Create Suppliers
    14. Create Customers
    15. Create Payment Terms
    16. Create Sales Orders and Sales Order Lines
    17. Create Shipments and Shipment Lines
    18. Create Customer Invoices and Customer Invoice Lines
    19. Create Customer Receipts and Payments
    20. Create Purchase Orders and Purchase Order Lines
    21. Create Receiving Documents and Receiving Lines
    22. Create Supplier Invoices and Supplier Invoice Lines
    23. Create Supplier Payments and Payments
    24. Call Accounting functions 
    
  */
 
@isTest
global with sharing class TestDataForFinance {
    public Company__c company = new Company__c();
    {
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
        //company.Finalize_Supplier_Invoices_w_Exceptions__c = false; //KNDY-2817
            
        insert company;
    }
    
    
    public Facility__c facility = new Facility__c();{
    	
    	Account address = new Account();
    	address.Name = 'Test Facility';
    	address.BillingStreet = '123 Main St.';
    	address.BillingCity = 'Redwood City';
    	address.BillingState = 'CA';
    	insert address;
    	
        facility = new Facility__c();
        facility.Company__c = company.id;
        facility.Name = 'Test Facility';
        facility.Address__c = address.Id;
        
        insert facility;
     
    }
    
    public Location__c location = new Location__c();{
        location = new Location__c();
        location.Facility__c = facility.id;
        location.name = 'Test Location';
        
        insert location;
    }
         
    public TestData.Accounting  Acctdata = new TestData.Accounting(company.id); 
   
    public Bank_Account__c bankAccount = new Bank_Account__c();{
        bankAccount.Name = 'Test BOFA';
        bankAccount.account_type__c = 'Checking';
        bankAccount.GL_Account__c = Acctdata.cashGL.id;
        bankAccount.active__c = true;
        bankAccount.Currency__c = TestFuel.currencyUSD.id;
        insert bankAccount;
    }
    
    
    public String periodName(Datetime myDT){
        String myDate = myDT.format('MM-yyyy');
        system.assert( myDate != null, 'expected valid date');
        return myDate.toUpperCase();
    }
    
    public List<Period__c> periodList = new List<Period__c>();{
                          
        	Datetime currTime = system.now();
			
			Date currDate = currTime.date();
			Date begOfMonthDate = currDate.toStartOfMonth();
			Date endOfMonthDate = begOfMonthDate.addMonths(1).addDays(-1);  			
			
			Date begOfYearDate = Date.newInstance(currDate.year(), 1, 1);
			Date endOfYearDate = Date.newInstance(currDate.year(), 12, 31);
			
			Datetime begOfMonthDatetime = DateTime.newInstance(currDate.year(), currDate.month(), 1, 0, 0, 0);
			Datetime endOfMonthDatetime = DateTime.newInstance(endOfMonthDate.addMonths(1).year(), endOfMonthDate.addMonths(1).month(), 1, 0, 0, 0);	
			
			Period__c period0 = new Period__c();
	        period0.Name = periodName(Datetime.now().addMonths(-1));
	        period0.Period_Number__c = 12;
	        period0.Quarter_Number__c = 4;
	        period0.Period_Start__c = begOfMonthDatetime.addMonths(-1);
	        period0.Period_End__c = begOfMonthDatetime;
	        
	        period0.Adjustment_Period__c = false;
	        period0.Closed__c = false;
	        period0.Open__c = true;
	        period0.Fiscal__c = true;
	        period0.Corporate__c = false;
	        period0.Tax__c = false;
	        period0.Permanently_Closed__c = false;
	        period0.Year_Start_Date__c = begOfYearDate;
	        period0.Year_End_Date__c = endOfYearDate;
	        period0.Company__c = company.Id;
	        period0.Fiscal_Year__c = String.valueOf(system.today().year());
	        period0.AP_Subledger_Cutoff__c = period0.Period_End__c ;
	        period0.AR_Subledger_Cutoff__c = period0.Period_End__c;
	        period0.Shipment_Subledger_Cutoff__c = period0.Period_End__c;
	        period0.Receiving_Subledger_Cutoff__c = period0.Period_End__c;
	        period0.FA_Subledger_Cutoff__c = period0.Period_End__c;
	        period0.Inventory_Subledger_Cutoff__c = period0.Period_End__c;
	        period0.JE_Cutoff__c = period0.Period_End__c;
	        periodList.add(period0);
			
			Period__c period1 = new Period__c();
			String periodName1 = periodName(Datetime.now());
            period1.Name = periodName1;
            period1.Period_Number__c = 12;
            period1.Quarter_Number__c = 4;
            period1.Period_Start__c = begOfMonthDatetime;
            period1.Period_End__c = endOfMonthDatetime; 
                      
            period1.Adjustment_Period__c = false;
            period1.Closed__c = false;
            period1.Open__c = true;
            period1.Fiscal__c = true;
            period1.Corporate__c = false;
            period1.Tax__c = false;
            period1.Permanently_Closed__c = false;
            period1.Year_Start_Date__c = begOfYearDate;
            period1.Year_End_Date__c = endOfYearDate;
            period1.Company__c =company.Id;
            period1.Fiscal_Year__c = String.valueOf(currDate.year());
            period1.AP_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.AR_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.Shipment_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.Receiving_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.FA_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.Inventory_Subledger_Cutoff__c = endOfMonthDatetime;
            period1.JE_Cutoff__c = endOfMonthDatetime;
            
            periodList.add(period1);
        	
        	Period__c period2 = new Period__c();
	        periodName1 = periodName(Datetime.now().addMonths(1));
	        period2.Name = periodName1;
	        period2.Period_Number__c = 12;
	        period2.Quarter_Number__c = 4;
	        period2.Period_Start__c = period1.period_end__c;
	        period2.Period_End__c = period2.Period_Start__c.addMonths(1);
	        
	        period2.Adjustment_Period__c = false;
	        period2.Closed__c = false;
	        period2.Open__c = true;
	        period2.Fiscal__c = true;
	        period2.Corporate__c = false;
	        period2.Tax__c = false;
	        period2.Permanently_Closed__c = false;
	        period2.Year_Start_Date__c = period1.Year_Start_Date__c;
	        period2.Year_End_Date__c = period1.Year_End_Date__c;
	        period2.Company__c = company.Id;
	        period2.Fiscal_Year__c = String.valueOf(system.today().year());
	        period2.AP_Subledger_Cutoff__c = period2.Period_End__c ;
	        period2.AR_Subledger_Cutoff__c = period2.Period_End__c;
	        period2.Shipment_Subledger_Cutoff__c = period2.Period_End__c;
	        period2.Receiving_Subledger_Cutoff__c = period2.Period_End__c;
	        period2.FA_Subledger_Cutoff__c = period2.Period_End__c;
	        period2.Inventory_Subledger_Cutoff__c = period2.Period_End__c;
	        period2.JE_Cutoff__c = period2.Period_End__c;
	        periodList.add(period2);
        	
        	datetime refDate = periodList[0].period_start__c;
			Fiscal_Year__c fy = new Fiscal_Year__c();
			fy.company__c = company.Id;
			fy.fiscal_year_start_date__c = periodList[0].period_start__c;
			fy.fiscal_year_end_date__c = periodList[periodList.size()-1].period_end__c.addMonths(3);
			
			insert fy;

        	for(Period__c p : periodList){
        		system.debug('start: ' + p.period_start__c);
        		system.debug('end: ' + p.period_end__c);
        		system.assertEquals(p.period_start__c, refDate, p);
        		refDate = p.period_end__c;
				p.fiscalyear__c = fy.Id;
        	}
        	
        	insert periodList;
        	
        	periodList[1].prior_period__c = periodList[0].Id;
        	periodList[2].prior_period__c = periodList[1].Id;
        	update periodList;
        	
        	system.debug(logginglevel.info,'periodList:'+periodList);
   
    }
    public Class__c itemClass, itemClass1, itemClass2, itemClass3; 
    public List<Class__c> classList = new List<Class__c>();{
        itemClass1 = new Class__c();
        itemClass1.Type__c = 'Goods';
        itemClass1.Name = 'Goods';
        itemClass1.Inventory_GL_Account__c = Acctdata.inventoryGL.id;
        itemClass1.Revenue_GL_Account__c = Acctdata.revenueGL.id;
        classList.add(itemClass1); 
        
        itemClass2 = new Class__c();
        itemClass2.Type__c = 'Miscellaneous';
        itemClass2.Name = 'Miscellaneous';
        itemClass2.Inventory_GL_Account__c = Acctdata.inventoryGL.id;
        itemClass2.Revenue_GL_Account__c = Acctdata.revenueGL.id;
        classList.add(itemClass2); 
        
        itemClass3 = new Class__c();
        itemClass3.Type__c = 'Expense';
        itemClass3.Name = 'Expense';
        itemClass3.Inventory_GL_Account__c = Acctdata.inventoryGL.id;
        itemClass3.Revenue_GL_Account__c = Acctdata.revenueGL.id;
        classList.add(itemClass3); 
        
        insert classList;
        
        itemClass = classList[0];
        
    }
    
    //KNDY 3621 UOM Conversion
    
     /*public UOM__c uomObj = new UOM__c(); 
        {
        	uomObj.Name = 'EA';
	        uomObj.Description__c = 'Each';
	        insert uomObj;
        }
       */ 
     public List<UOM__c> uomList = new List<UOM__c>(); 
     public List<String> uoms = new List<String>{'LB', 'TN', 'DZ', 'OZ', 'MI', 'YD', 'IN', 'FT', 'FT3','EA'};
     public List<String> uomdescs = new List<String>{'Pound', 'Ton', 'Dozen', 'Ounce', 'Mile', 'Yard', 'Inch', 'Foot', 'Cubic','Each'};
        
        {    	
	        for (Integer i = 0; i < uoms.size(); ++i) {
	            UOM__c Obj = new UOM__c();
	            Obj.Name = uoms[i];
	            Obj.Description__c = uomdescs[i];
	            uomList.add(Obj);
	        }
	        insert uomList;
        } 
        
    
    public List<UOM_Conversion_Details__c> uomcList = new List<UOM_Conversion_Details__c>(); 
       {
        
       UOM_Conversion_Details__c Obj = new UOM_Conversion_Details__c();
    			//DZ-EA
	            Obj.Name = ((String)uomList[2].Id).substring(3, 15) + ((String)uomList[9].Id).substring(3, 15);
	            Obj.uom_1__c = uomList[2].Id;
	            Obj.uom_1_Quantity__c =1;
	            Obj.uom_2__c = uomList[9].Id;
	            Obj.uom_2_Quantity__c = 12.0;
	            Obj.Key_1__c = string.valueof(uomList[2].Id)+string.valueof(uomList[9].Id); 
	            Obj.Key_2__c = string.valueof(uomList[9].Id)+string.valueof(uomList[2].Id);
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
	            //LB-OZ
	            Obj2.Name = ((String)uomList[0].Id).substring(3, 15) + ((String)uomList[3].Id).substring(3, 15);
	            Obj2.uom_1__c = uomList[0].Id;
	            Obj2.uom_1_Quantity__c =1;
	            Obj2.uom_2__c = uomList[3].Id;
	            Obj2.uom_2_Quantity__c = 16.0;
	            Obj2.Key_1__c = string.valueof(uomList[0].Id)+string.valueof(uomList[3].Id);//string.valueof(itemList[0].Id) + 
	            Obj2.Key_2__c = string.valueof(uomList[3].Id)+string.valueof(uomList[0].Id);//string.valueof(itemList[0].Id) + 
	            //Obj.Conversion_Factor__c = uomcnvs[i];
	            uomcList.add(Obj2);
	            
	            
	            UOM_Conversion_Details__c Obj3 = new UOM_Conversion_Details__c();
	            //MI-FT
	            Obj3.Name = ((String)uomList[4].Id).substring(3, 15) + ((String)uomList[7].Id).substring(3, 15);
	            Obj3.uom_1__c = uomList[4].Id;
	            Obj3.uom_1_Quantity__c =1;
	            Obj3.uom_2__c = uomList[7].Id;
	            Obj3.uom_2_Quantity__c = 5280.0;
	            Obj3.Key_1__c = string.valueof(uomList[4].Id)+string.valueof(uomList[7].Id);//string.valueof(itemList[0].Id) + 
	            Obj3.Key_2__c = string.valueof(uomList[7].Id)+string.valueof(uomList[4].Id);//string.valueof(itemList[0].Id) + 
	            //Obj.Conversion_Factor__c = uomcnvs[i];
	            uomcList.add(Obj3);
	            
	            UOM_Conversion_Details__c Obj4 = new UOM_Conversion_Details__c();
	            //MI-YD
	            Obj4.Name = ((String)uomList[4].Id).substring(3, 15) + ((String)uomList[5].Id).substring(3, 15);
	            Obj4.uom_1__c = uomList[4].Id;
	            Obj4.uom_1_Quantity__c =1;
	            Obj4.uom_2__c = uomList[5].Id;
	            Obj4.uom_2_Quantity__c = 1760.0;
	            Obj4.Key_1__c = string.valueof(uomList[4].Id)+string.valueof(uomList[5].Id);//string.valueof(itemList[0].Id) + 
	            Obj4.Key_2__c = string.valueof(uomList[5].Id)+string.valueof(uomList[4].Id);//string.valueof(itemList[0].Id) + 
	            //Obj.Conversion_Factor__c = uomcnvs[i];
	            uomcList.add(Obj4);
	            
	            
	            UOM_Conversion_Details__c Obj5 = new UOM_Conversion_Details__c();
	            //TN-LB
	            Obj5.Name = ((String)uomList[1].Id).substring(3, 15) + ((String)uomList[0].Id).substring(3, 15);
	            Obj5.uom_1__c = uomList[1].Id;
	            Obj5.uom_1_Quantity__c =1;
	            Obj5.uom_2__c = uomList[0].Id;
	            Obj5.uom_2_Quantity__c = 2000.0;
	            Obj5.Key_1__c = string.valueof(uomList[1].Id)+string.valueof(uomList[0].Id);//string.valueof(itemList[0].Id) + 
	            Obj5.Key_2__c = string.valueof(uomList[0].Id)+string.valueof(uomList[1].Id);//string.valueof(itemList[0].Id) + 
	            //Obj.Conversion_Factor__c = uomcnvs[i];
	            uomcList.add(Obj5);
	            
	            UOM_Conversion_Details__c Obj6 = new UOM_Conversion_Details__c();
            	//YD-FT
            	Obj6.Name = ((String)uomList[5].Id).substring(3, 15) + ((String)uomList[7].Id).substring(3, 15);
	            Obj6.uom_1__c = uomList[5].Id;
	            Obj6.uom_1_Quantity__c =1;
	            Obj6.uom_2__c = uomList[7].Id;
	            Obj6.uom_2_Quantity__c = 3.0;
	            Obj6.Key_1__c = string.valueof(uomList[5].Id)+string.valueof(uomList[7].Id);//string.valueof(itemList[0].Id) + 
	            Obj6.Key_2__c = string.valueof(uomList[7].Id)+string.valueof(uomList[5].Id);//string.valueof(itemList[0].Id) + 
	            //Obj.Conversion_Factor__c = uomcnvs[i];
	            uomcList.add(Obj6);
	            
	            
	            UOM_Conversion_Details__c Obj7 = new UOM_Conversion_Details__c();
            	//YD-FT3
            	Obj7.Name = ((String)uomList[5].Id).substring(3, 15) + ((String)uomList[8].Id).substring(3, 15);
	            Obj7.uom_1__c = uomList[5].Id;
	            Obj7.uom_1_Quantity__c =1;
	            Obj7.uom_2__c = uomList[8].Id;
	            Obj7.uom_2_Quantity__c = 0.037040;
	            Obj7.Key_1__c = string.valueof(uomList[5].Id)+string.valueof(uomList[8].Id);//string.valueof(itemList[0].Id) + 
	            Obj7.Key_2__c = string.valueof(uomList[8].Id)+string.valueof(uomList[5].Id);//string.valueof(itemList[0].Id) + 
	            //Obj.Conversion_Factor__c = uomcnvs[i];
	            uomcList.add(Obj7);
        	insert uomcList;
        }
        
        public List<Item__c> itemList = new List<Item__c>();{
             
            Item__c ItemObj2=new Item__c();
            ItemObj2.name='HP Printer';
            ItemObj2.Description__c='It is a Test item';
            ItemObj2.Source__c=Label.Source_field_of_ItemP;
            ItemObj2.Company__c = company.id;
            ItemObj2.Class__c = itemClass1.id;
            ItemObj2.Stocking_UOM__c = uomList[3].ID;
            ItemObj2.Packaging_UOM__c = JSON.serialize(new List<Id>{uomList[3].Id});
            
            itemList.add(ItemObj2);
            
            Item__c ItemObj3=new Item__c();
            ItemObj3.name='HP Printer 3';
            ItemObj3.Description__c='It is a Test item';
           // ItemObj3.Source__c='Miscellaneous';
            ItemObj3.Source__c='Manufactured';
            ItemObj3.Company__c = company.id;
            ItemObj3.Class__c = itemClass2.id;
            ItemObj3.Stocking_UOM__c = uomList[3].ID;
            ItemObj3.Packaging_UOM__c = JSON.serialize(new List<Id>{uomList[3].Id});
            
            itemList.add(ItemObj3);
            
            Item__c ItemObj4=new Item__c();
            ItemObj4.name='HP Printer 4';
            ItemObj4.Description__c='It is a Test item';
            ItemObj4.Source__c='Expense';
            itemObj4.Non_Inventory__c = true; 
            ItemObj4.Company__c = company.id;
            ItemObj4.Class__c = itemClass3.id;
            ItemObj4.Stocking_UOM__c = uomList[3].ID;
            ItemObj4.Packaging_UOM__c = JSON.serialize(new List<Id>{uomList[3].Id});
            
            itemList.add(ItemObj4);
            insert itemList;
        }
        
    public Product__c product = new Product__c(); {
                        
        product.company__c = company.id;
        product.Name = 'Test Product';
        product.Item__c = itemList[0].id;
        product.Weight__c = 1;
        product.Weight_UOM__c = uomList[0].ID;
        product.Dimension_UOM__c = uomList[5].ID;
        product.Length__c = 1;
        product.Height__c = 1;
        product.Width__c = 1;
        product.units_per_layer__c = 1;
        product.layers_per_pallet__c = 1;
        
        insert product;
    
    }
    
    
    public Item_Specification__c assembly = new Item_Specification__c(); {
        assembly.Item__c  = itemList[0].ID;
        assembly.Start_Date2__c = System.now().addDays(-39);
        assembly.Revision__c = 'A';
        assembly.company__c = company.id;
        assembly.Facility__c = facility.id;     
        insert assembly;   
    }       
    
    
    public List<Item_Cost__c> itemcostList = new List<Item_Cost__c>();{
        
        Item_Cost__c ItemCostObj = new Item_Cost__c();
        ItemCostObj.Item__c = itemList[0].ID;
        ItemCostObj.Status__c = 'Proposed';
        //ItemCostObj.Date_Activated__c = system.today();
        ItemCostObj.Material_Cost__c = 30;
        ItemCostObj.Labor_Cost__c = 10;
        ItemCostObj.Outside_Processing_Cost__c = 20;
        ItemCostObj.Overhead_Cost__c = 5;
        ItemCostObj.Start_date__c = DateTime.now();
        ItemCostObj.Company__c = company.Id;
        itemcostList.add(ItemCostObj);
        
        Item_Cost__c ItemCostObj2 = new Item_Cost__c();
        ItemCostObj2.Item__c = itemList[0].ID;
        ItemCostObj2.Status__c = 'Proposed';
        //ItemCostObj2.Date_Activated__c = system.today();
        ItemCostObj2.Material_Cost__c = 550;
        ItemCostObj2.Labor_Cost__c = 10;
        ItemCostObj2.Outside_Processing_Cost__c = 20;
        ItemCostObj2.Overhead_Cost__c = 5;
        ItemCostObj2.Facility__c = facility.Id;
        ItemCostObj2.Start_date__c = DateTime.now();
        ItemCostObj2.Company__c = company.Id;
        itemcostList.add(ItemCostObj2);
        
        insert itemcostList;
        
        for(Item_Cost__c ic : itemcostList){
            ic.Status__c = 'Approved';
            ic.Date_Approved__c = DateTime.now();
            //ic.Date_Activated__c = system.today();
        }
        ItemService.allowItemCostUpdate = true;
        update itemcostList;
        
            
    }
    
    public map <string,string> SupplierRecordTypes = KSE.RecordTypeDevNameMap('Supplier__c');
    
    public Supplier__c remittosupplier = new Supplier__c();{
        remittosupplier = new Supplier__c();
        remittosupplier.Status__c = 'Active';
        remittosupplier.Name = 'Test Remit To Supplier';
        remittosupplier.Type__c = 'Remit-To';
        remitToSupplier.RecordTypeId = SupplierRecordTypes.get('Remit_To');
        remitToSupplier.company__c = company.id;
        insert remittosupplier;        
    }
    
    public Supplier__c supplier = new Supplier__c();{
        supplier = new Supplier__c();
        supplier.status__C = 'Active';
        supplier.Name = 'Test Supplier';
        supplier.Type__c = 'Purchasing';
        supplier.RecordTypeId = SupplierRecordTypes.get('Purchase_From');
        supplier.Remit_To__c =  remittosupplier.id;
        supplier.company__c = company.id;
        insert supplier;        
    }
    
    
    //Create a map between the Record Type Name and Id for easy retrieval
    public Map<String,String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
    
    public Customer__c customer ;
    public Customer__c customer2 ;
    public Customer__c customer3;
    public Customer__c customer_corp;
    public Customer__c customer_billto;
    public Customer__c customer_billto1;
    public Customer__c customer_billto2;
    public Customer__c customer_billto3;
    public Customer__c customer_shipto;
    public Customer__c customer_shipto1;
    public Customer__c customer_shipto2;
    public Customer__c customer_shipto3;
    public List<Customer__c> customerList = new List<Customer__c>();{
        customer_corp = new Customer__c();
        customer_corp.name = 'TestCustomer-Corporate';
        customer_corp.status__c = 'Approved';
        customer_corp.Company__c = company.id;
        customer_corp.recordtypeId = CustomerRecordTypes.get('Corporate_Parent');
        insert customer_corp;
        
        customer_billto = new Customer__c();
        customer_billto.name = 'TestCustomer-BillTo';
        customer_billto.status__c = 'Approved';
        customer_billto.Company__c = company.id;
        customer_billto.Parent_Customer__c = customer_corp.id;
        customer_billto.recordtypeId = CustomerRecordTypes.get('Bill_To');
       // insert customer_billto;
        
        customer_billto1 = new Customer__c();
        customer_billto1.name = 'TestCustomer-BillTo1';
        customer_billto1.status__c = 'Approved';
        customer_billto1.Company__c = company.id;
        customer_billto1.Parent_Customer__c = customer_corp.id;
        customer_billto1.recordtypeId = CustomerRecordTypes.get('Bill_To');
       // insert customer_billto1;
        
        customer_billto2 = new Customer__c();
        customer_billto2.name = 'TestCustomer-BillTo2';
        customer_billto2.status__c = 'Approved';
        customer_billto2.Company__c = company.id;
        customer_billto2.Parent_Customer__c = customer_corp.id;
        customer_billto2.recordtypeId = CustomerRecordTypes.get('Bill_To');
        //insert customer_billto2;
        
        customer_billto3 = new Customer__c();
        customer_billto3.name = 'TestCustomer-BillTo3';
        customer_billto3.status__c = 'Approved';
        customer_billto3.Company__c = company.id;
        customer_billto3.Parent_Customer__c = customer_corp.id;
        customer_billto3.recordtypeId = CustomerRecordTypes.get('Bill_To');
        insert new list<Customer__c>{customer_billto, customer_billto1, customer_billto2, customer_billto3};
        
        Customer__c customer1 = new Customer__c();
        customer1.name = 'TestCustomer1';
        customer1.status__c = 'Approved';
        customer1.Company__c = company.id;
        customer1.Parent_Customer__c = customer_billto.id;
        customer1.recordtypeId = CustomerRecordTypes.get('Sold_To');
        customerList.add(customer1);
        
        customer2 = new Customer__c();
        customer2.name = 'TestCustomer2';
        customer2.status__c = 'Approved';
        customer2.Company__c = company.id;
        customer2.Parent_Customer__c = customer_billto1.id;
        customer2.recordtypeId = CustomerRecordTypes.get('Sold_To');
        customerList.add(customer2);
        
        customer3 = new Customer__c();
        customer3.name = 'TestCustomer3';
        customer3.status__c = 'Approved';
        customer3.Company__c = company.id;
        customer3.Parent_Customer__c = customer_billto2.id;
        customer3.recordtypeId = CustomerRecordTypes.get('Sold_To');
        customerList.add(customer3);
        
        insert customerList;
        customer = customerList[0];
        
        customer_shipto = new Customer__c();
        customer_shipto.name = 'TestCustomer-ShipTo';
        customer_shipto.status__c = 'Approved';
        customer_shipto.Company__c = company.id;
        customer_shipto.Parent_Customer__c = customer1.id;
        customer_shipto.recordtypeId = CustomerRecordTypes.get('Ship_To');
        //insert customer_shipto;
        
        customer_shipto1 = new Customer__c();
        customer_shipto1.name = 'TestCustomer-ShipTo1';
        customer_shipto1.status__c = 'Approved';
        customer_shipto1.Company__c = company.id;
        customer_shipto1.Parent_Customer__c = customer2.id;
        customer_shipto1.recordtypeId = CustomerRecordTypes.get('Ship_To');
        //insert customer_shipto1;
        
        customer_shipto2 = new Customer__c();
        customer_shipto2.name = 'TestCustomer-ShipTo2';
        customer_shipto2.status__c = 'Approved';
        customer_shipto2.Company__c = company.id;
        customer_shipto2.Parent_Customer__c = customer3.id;
        customer_shipto2.recordtypeId = CustomerRecordTypes.get('Ship_To');
        
        insert new List<Customer__c> { customer_shipto, customer_shipto1, customer_shipto2} ;
    }
    
    public Payment_Term__c terms = new Payment_Term__c(); {
        terms.name = 'Test Terms'; 
        terms.Type__c = KSE.PAYMENT_TERM_DUE_DAYS;
        terms.Due_Days__c =0; 
        insert terms; 
    }
    
    public Sales_Order__c salesOrderObj;  // for backward compat 
    public Sales_Order__c salesOrder1=new Sales_Order__c();
    public Sales_Order__c salesOrder3=new Sales_Order__c(); 
    public Sales_Order__c salesOrder2=new Sales_Order__c();
    
            { 
            salesOrder1.Customer__c=customerList[0].id;
            salesOrder1.Currency__c = TestFuel.currencyUSD.id ;
            salesOrder1.Status__c='Open';
            salesOrder1.Type__c = 'Standard';
            salesOrder1.Payment_Term__c = terms.id;
            salesOrder1.Company__c = company.id;
            salesOrder1.Ship_Complete__c = true;
            salesOrder1.Weight_UOM__c = uomList[0].ID;
        	salesOrder1.Dimension_UOM__c = uomList[5].ID;
        	salesOrder1.Original_Sales_Order__c = 'salesOrder1';
  
            salesOrder2.Customer__c=customerList[0].id;
            salesOrder2.Currency__c = TestFuel.currencyUSD.id ;
            salesOrder2.Status__c='Open';
            salesOrder2.Type__c = 'Special';
            salesOrder2.Payment_Term__c = terms.id;
            salesOrder2.company__c = company.id;
            salesOrder2.Weight_UOM__c = uomList[0].ID;
        	salesOrder2.Dimension_UOM__c = uomList[5].ID;
        	salesOrder2.Original_Sales_Order__c = 'salesOrder2';
        
            salesOrder3.Customer__c=customerList[0].id;
            salesOrder3.Currency__c = TestFuel.currencyUSD.id ;
            salesOrder3.Status__c='Open';
            salesOrder3.Type__c = 'Adjustment';
            salesOrder3.Payment_Term__c = terms.id;
            salesOrder3.company__c = company.id;
            salesOrder3.Weight_UOM__c = uomList[0].ID;
        	salesOrder3.Dimension_UOM__c = uomList[5].ID;
        	salesOrder3.Original_Sales_Order__c = 'salesOrder3';
                              
            insert new List<Sales_Order__c> { salesorder1, salesOrder2,salesOrder3 } ;
            salesOrderObj = salesOrder1;
       }
        
        public List<Sales_Order_Line__c> SalesOrderLineList = new List<Sales_Order_Line__c>();
        {
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
            
                                    
            SalesOrderLineList.add(salesOrderLineObj1);
            
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
                                
            SalesOrderLineList.add(salesOrderLineObj2);
            
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
                        
            SalesOrderLineList.add(salesOrderLineObj3);
            
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
            SalesOrderLineList.add(salesOrderLineObj4);
            
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
            
            SalesOrderLineList.add(salesOrderLineObj31);
            
            insert SalesOrderLineList;
            
           }
           
           public Purchase_Order__c purchaseOrder1 = new Purchase_Order__c();
           public Purchase_Order__c purchaseOrder2 = new Purchase_Order__c();
           public Purchase_Order__c purchaseOrder3 = new Purchase_Order__c();
           public Purchase_Order__c purchaseOrder4 = new Purchase_Order__c();
           
           {
                purchaseOrder1.Order_Date__c = system.today();
                purchaseOrder1.status__c = 'Open';
                purchaseOrder1.Supplier__c = supplier.id; 
                purchaseOrder1.Remit_To_Supplier__c = remittosupplier.id; 
                purchaseOrder1.Company__c = company.id;
                purchaseOrder1.Payment_Term__c = terms.id;
                purchaseOrder1.Memo__c = 'PurchaseOrder1';
                purchaseOrder1.Currency__c = TestFuel.currencyUSD.id;
                
                purchaseOrder2.Order_Date__c = system.today();
                purchaseOrder2.status__c = 'Open';
                purchaseOrder2.Supplier__c = supplier.id;
                purchaseOrder2.Remit_To_Supplier__c = remittosupplier.id; 
                purchaseOrder2.Company__c = company.id;
                purchaseOrder2.Payment_Term__c = terms.id;
                purchaseOrder2.Memo__c = 'PurchaseOrder2';
                purchaseOrder2.Currency__c = TestFuel.currencyUSD.id;
           
                purchaseOrder3.Order_Date__c = system.today();
                purchaseOrder3.Supplier__c = supplier.id; 
                purchaseOrder3.Remit_To_Supplier__c = remittosupplier.id;
                purchaseOrder3.Company__c = company.id;
                purchaseOrder3.Payment_Term__c = terms.id;
                purchaseOrder3.status__c = 'Open';
           		purchaseOrder3.Memo__c = 'PurchaseOrder3';
           	    purchaseOrder3.Currency__c = TestFuel.currencyUSD.id;           		
           
                purchaseOrder4.Order_Date__c = system.today();
                purchaseOrder4.Supplier__c = supplier.id;
                purchaseOrder4.Remit_To_Supplier__c = remittosupplier.id; 
                purchaseOrder4.Company__c = company.id;
                purchaseOrder4.Payment_Term__c = terms.id;
                purchaseOrder4.status__c = 'Open';
                purchaseOrder4.Memo__c = 'PurchaseOrder4';
                purchaseOrder4.Currency__c = TestFuel.currencyUSD.id;
                
                insert new List<sobject>{ purchaseOrder1, purchaseOrder2, purchaseOrder3, purchaseOrder4};

                List<Purchase_Order_Line__c> objPODetailList = new List<Purchase_Order_Line__c>();
   
                Purchase_Order_Line__c objPODetail = new Purchase_Order_Line__c();
                objPODetail.Purchase_Order__c = purchaseOrder1.Id;
                objPODetail.Order_Quantity__c = 10;        
                objPODetail.Unit_Price__c = 12;
                objPODetail.Item__c = itemList[0].Id;
                objPODetail.Purchase_UOM__c = uomList[0].Id;
                objPODetail.Status__c = Label.Open;    
                objPODetail.Need_Date__c = System.today();
                objPODetail.Company__c = company.id;
                objPODetail.Delivery_Location__c = location.ID;
                objPODetail.Delivery_facility__c = location.facility__c;
                //objPODetail.Line_Type__c = 'Standard';
                objPODetail.Supplier__c = supplier.Id;
                objPODetailList.add( objPODetail );                   
                
                
                Purchase_Order_Line__c objPODetail1 = new Purchase_Order_Line__c();
                objPODetail1.Purchase_Order__c = purchaseOrder2.Id;
                objPODetail1.Order_Quantity__c = 10;        
                objPODetail1.Unit_Price__c = 25;
                objPODetail1.Item__c = itemList[0].Id;
                objPODetail1.Purchase_UOM__c = uomList[0].Id;
                objPODetail1.Status__c = Label.Open;    
                objPODetail1.Need_Date__c = System.today();
                objPODetail1.Company__c = company.id;
                objPODetail1.Delivery_Location__c = location.ID;
                objPODetail1.Delivery_facility__c = location.facility__c;
                //objPODetail1.Line_Type__c = 'Standard';
                objPODetail1.Supplier__c = supplier.Id;
                objPODetail1.Invoice_Matching__c = 'Two Way';
               
                objPODetailList.add(objPODetail1);                    
                
                Purchase_Order_Line__c objPODetail2 = new Purchase_Order_Line__c();
                objPODetail2.Purchase_Order__c = purchaseOrder2.Id;
                objPODetail2.Order_Quantity__c = 5;        
                objPODetail2.Unit_Price__c = 15;
                objPODetail2.Item__c = itemList[0].Id;
                objPODetail2.Purchase_UOM__c = uomList[0].Id;
                objPODetail2.Status__c = Label.Open;    
                objPODetail2.Need_Date__c = System.today();
                objPODetail2.Company__c = company.id;
                objPODetail2.Delivery_Location__c = location.ID;
                objPODetail2.Delivery_facility__c = location.facility__c;
                //objPODetail2.Line_Type__c = 'Standard';
                objPODetail2.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail2);  
                
                
                Purchase_Order_Line__c objPODetail4 = new Purchase_Order_Line__c();
                objPODetail4.Purchase_Order__c = purchaseOrder3.Id;
                objPODetail4.Order_Quantity__c = 10;        
                objPODetail4.Unit_Price__c = 25;
                objPODetail4.Item__c = itemList[0].Id;
                objPODetail4.Purchase_UOM__c = uomList[0].Id;
                objPODetail4.Status__c = Label.Open;    
                objPODetail4.Need_Date__c = System.today();
                objPODetail4.Company__c = company.id;
                objPODetail4.Delivery_Location__c = location.ID;
                objPODetail4.Delivery_facility__c = location.facility__c;
                //objPODetail1.Line_Type__c = 'Standard';
                objPODetail4.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail4);                     // line trigger sets the Line__c sequence
                
                Purchase_Order_Line__c objPODetail5 = new Purchase_Order_Line__c();
                objPODetail5.Purchase_Order__c = purchaseOrder3.Id;
                objPODetail5.Order_Quantity__c = 5;        
                objPODetail5.Unit_Price__c = 15;
                objPODetail5.Item__c = itemList[0].Id;
                objPODetail5.Purchase_UOM__c = uomList[0].Id;
                objPODetail5.Status__c = Label.Open;    
                objPODetail5.Need_Date__c = System.today();
                objPODetail5.Company__c = company.id;
                objPODetail5.Delivery_Location__c = location.ID;
                objPODetail5.Delivery_facility__c = location.facility__c;
                //objPODetail2.Line_Type__c = 'Standard';
                objPODetail5.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail5);  
                
      
                Purchase_Order_Line__c objPODetail6 = new Purchase_Order_Line__c();
                objPODetail6.Purchase_Order__c = purchaseOrder4.Id;
                objPODetail6.Order_Quantity__c = 1;        
                objPODetail6.Unit_Price__c = 25;
                objPODetail6.Item__c = itemList[1].Id;
                objPODetail6.Purchase_UOM__c = uomList[0].Id;
                objPODetail6.Status__c = Label.Open;    
                objPODetail6.Need_Date__c = System.today();
                objPODetail6.Company__c = company.id;
                objPODetail6.Delivery_Location__c = location.ID;
                objPODetail6.Delivery_facility__c = location.facility__c;
                //objPODetail6.Line_Type__c = 'Standard';
                objPODetail6.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail6);                     // line trigger sets the Line__c sequence
                
                Purchase_Order_Line__c objPODetail7 = new Purchase_Order_Line__c();
                objPODetail7.Purchase_Order__c = purchaseOrder4.Id;
                objPODetail7.Order_Quantity__c = 2;        
                objPODetail7.Unit_Price__c = 20;
                objPODetail7.Item__c = itemList[0].Id;
                objPODetail7.Purchase_UOM__c = uomList[0].Id;
                objPODetail7.Status__c = Label.Open;    
                objPODetail7.Need_Date__c = System.today();
                objPODetail7.Company__c = company.id;
                objPODetail7.Delivery_Location__c = location.ID;
                objPODetail7.Delivery_facility__c = location.facility__c;
                //objPODetail7.Line_Type__c = 'Standard';
                objPODetail7.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail7); 
                
                Purchase_Order_Line__c objPODetail3 = new Purchase_Order_Line__c();
                objPODetail3.Purchase_Order__c = purchaseOrder4.Id;
                objPODetail3.Order_Quantity__c = 2;        
                objPODetail3.Unit_Price__c = 10;
                objPODetail3.Item__c = itemList[0].Id;
                objPODetail3.Purchase_UOM__c = uomList[0].Id;
                objPODetail3.Status__c = Label.Open;    
                objPODetail3.Need_Date__c = System.today();
                objPODetail3.Company__c = company.id;
                objPODetail3.Delivery_Location__c = location.ID;
                objPODetail3.Delivery_facility__c = location.facility__c;
                //objPODetail3.Line_Type__c = 'Standard';
                objPODetail3.Supplier__c = supplier.Id;
                objPODetailList.add(objPODetail3); 
                
                insert objPODetailList;   
 
                
	           Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
	            receivingDocument1 = new Receiving_Document__c();
	            receivingDocument1.Company__c = company.Id;
	            receivingDocument1.Supplier__c = supplier.Id;
	            receivingDocument1.Status__c = 'Open';
	            receivingDocument1.Date_Created__c = system.today();
	            receivingDocument1.Type__c = 'Purchase Order Receipt';
	            insert receivingDocument1;
	          }
	        
	         Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
	            receiptLine1.Purchase_Order__c = purchaseOrder2.Id;
	            receiptLine1.Purchase_Order_Line__c = objPODetail2.Id;
	            receiptLine1.Item__c = itemList[0].Id;
	            receiptLine1.Company__c = company.Id;
	            receiptLine1.Supplier__c = supplier.Id;
	            receiptLine1.Quantity_Received__c = 4;
	            receiptLine1.Uninvoiced_Quantity__c = 4;
	            receiptLine1.Facility__c = facility.Id;
	            receiptLine1.Location__c = location.Id;
	            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
	            insert receiptLine1;
	        }
	        
	        // Receive POL order quantity in full
	        objPODetail2.Quantity_Received__c = 4; 
	        update objPODetail2;
 
            // TODO query these back with one query, not 4
             purchaseorder1 = [Select p.SystemModstamp, 
                        p.Supplier__c, p.Status__c, 
                        p.Ship_Via__c, p.Rush_Order__c, 
                        p.Payment_Term__c, p.Order_Date__c, 
                        p.Name, p.Id, p.Deliver_to__c, p.Date_Closed__c, 
                        p.Company__c, p.Buyer__c, Purchase_Order_Value__c,  
                        p.Approval_Status__c, p.Acknowledge_Via__c, p.Currency__c, 
                        (Select Id, IsDeleted, Name, Purchase_Order__c, Company__c, Line_Type__c,
                            Date_Added__c, Date_Closed__c, Date_Last_Changed__c, Description__c,  
                            Item__c, Latest_Promise_Date__c, Line_Value__c, Line__c,  Manufacturers_Part__c, 
                            Need_Date__c, Order_Quantity__c, Overage_Percentage__c, 
                            Promise_Date__c, Purchase_UOM__c, Quantity_Returned_to_Supplier__c, 
                            Quantity_Still_Due__c,
                            Requisition_Number__c, Rush_Line__c, Special_Notes__c, Status__c, 
                            Supplier_Part__c, Suppliers_Part_Description__c, Unit_Price__c 
                            From Purchase_Order_Lines__r order by Line__c ASC) 
                        From Purchase_Order__c p
                        where p.id = :purchaseOrder1.id limit 1];
    
   
                 purchaseOrder2 = [Select p.SystemModstamp, 
                        p.Supplier__c, p.Status__c, 
                        p.Ship_Via__c, p.Rush_Order__c, 
                        p.Payment_Term__c, p.Order_Date__c, 
                        p.Name, p.Id, p.Deliver_to__c, p.Date_Closed__c, 
                        p.Company__c, p.Buyer__c, Purchase_Order_Value__c,  
                        p.Approval_Status__c, p.Acknowledge_Via__c, p.Currency__c, 
                        (Select Id, IsDeleted, Name, Purchase_Order__c, Company__c, Line_Type__c,
                            Date_Added__c, Date_Closed__c, Date_Last_Changed__c, Description__c,  
                            Item__c, Latest_Promise_Date__c, Line_Value__c, Line__c,  Manufacturers_Part__c, 
                            Need_Date__c, Order_Quantity__c, Overage_Percentage__c, 
                            Promise_Date__c, Purchase_UOM__c, Quantity_Returned_to_Supplier__c, 
                            Quantity_Still_Due__c,
                            Requisition_Number__c, Rush_Line__c, Special_Notes__c, Status__c, 
                            Supplier_Part__c, Suppliers_Part_Description__c, Unit_Price__c 
                            From Purchase_Order_Lines__r order by Line__c ASC) 
                        From Purchase_Order__c p
                        where p.id = :purchaseOrder2.id limit 1];
                
                purchaseOrder3 = [Select p.SystemModstamp, 
                        p.Supplier__c, p.Status__c, 
                        p.Ship_Via__c, p.Rush_Order__c, 
                        p.Payment_Term__c, p.Order_Date__c, 
                        p.Name, p.Id, p.Deliver_to__c, p.Date_Closed__c, 
                        p.Company__c, p.Buyer__c, Purchase_Order_Value__c,  
                        p.Approval_Status__c, p.Acknowledge_Via__c, p.Currency__c, 
                        (Select Id, IsDeleted, Name, Purchase_Order__c, Company__c, Line_Type__c,
                            Date_Added__c, Date_Closed__c, Date_Last_Changed__c, Description__c,  
                            Item__c, Latest_Promise_Date__c, Line_Value__c, Line__c,  Manufacturers_Part__c, 
                            Need_Date__c, Order_Quantity__c, Overage_Percentage__c, 
                            Promise_Date__c, Purchase_UOM__c, Quantity_Returned_to_Supplier__c, 
                            Quantity_Still_Due__c,
                            Requisition_Number__c, Rush_Line__c, Special_Notes__c, Status__c, 
                            Supplier_Part__c, Suppliers_Part_Description__c, Unit_Price__c 
                            From Purchase_Order_Lines__r order by Line__c ASC) 
                        From Purchase_Order__c p
                        where p.id = :purchaseOrder3.id limit 1];
                          
                purchaseOrder4 = [Select p.SystemModstamp, 
                        p.Supplier__c, p.Status__c, 
                        p.Ship_Via__c, p.Rush_Order__c, 
                        p.Payment_Term__c, p.Order_Date__c, 
                        p.Name, p.Id, p.Deliver_to__c, p.Date_Closed__c, 
                        p.Company__c, p.Buyer__c, Purchase_Order_Value__c,  
                        p.Approval_Status__c, p.Acknowledge_Via__c, p.Currency__c,
                        (Select Id, IsDeleted, Name, Purchase_Order__c, Company__c, Line_Type__c,
                            Date_Added__c, Date_Closed__c, Date_Last_Changed__c, Description__c,  
                            Item__c, Latest_Promise_Date__c, Line_Value__c, Line__c,  Manufacturers_Part__c, 
                            Need_Date__c, Order_Quantity__c, Overage_Percentage__c, 
                            Promise_Date__c, Purchase_UOM__c, Quantity_Returned_to_Supplier__c, 
                            Quantity_Still_Due__c,
                            Requisition_Number__c, Rush_Line__c, Special_Notes__c, Status__c, 
                            Supplier_Part__c, Suppliers_Part_Description__c, Unit_Price__c 
                            From Purchase_Order_Lines__r order by Line__c ASC) 
                        From Purchase_Order__c p
                        where p.id = :purchaseOrder4.id limit 1];
                 
           }
    
    public static testMethod void t1() {
        TestDataForFinance data = new TestDataForFinance(); 
        System.debug( LoggingLevel.INFO, 'TestDataForFinance uses queries : '+ Limits.getQueries() );  
        // we are at 66, don't go up !!
        // dang, now 68, TODO put the lines insert statements into one insert dml
        // dang, dang, now 76, 24 more to go.
        // triple dang, need to lower ASAP
        system.assert(  Limits.getQueries() <= 81, ' expected TestDataForFinance to use 81 queries or less!  '+Limits.getQueries());
    }   
}