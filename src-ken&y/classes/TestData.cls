@istest 
global with sharing class TestData {
/* To add this data to the org from Developer Console execute the following:

TestData data=new TestData();

The list of records to delete if you want to run it again:

delete [select Id from Shipment__c ];
delete [select Id from SKID__c ];
delete [select Id from Order_Forecast__c ];
delete [select Id from Work_Order__c ];
delete [select Id from Supplier_Invoice_Line__c ];
delete [select Id from Receiving_Document__c ];
delete [select Id from Pricebook_Line__c];
delete [select Id from Pricebook__c];
delete [select Id from Purchase_Order_Line__c ];
delete [select Id from Purchase_Order__c ];
delete [select Id from Sales_Order_Line__c ];
delete [select Id from Sales_Order__c ];
delete [select Id from Customer__c ];
delete [select Id from Shipping_Method__c ];
delete [select Id from Component__c];
delete [select Id from Item_Specification__c];
delete [select Id from Lot__c];
delete [select Id from Product__c];
delete [select Id from Item_Cost__c];
delete [select Id from Item__c];
delete [select Id from Bin__c];
delete [select Id from Location__c];
delete [select Id from Facility__c];
delete [select Id from Supplier__c];
delete [select Id from Payment_Term__c];
delete [select Id from Class__c];
delete [select Id from UOM_Conversion_Details__c];
delete [select Id from UOM__c];
delete [select Id from Company_Group__c ];
delete [select Id from Company__c];
delete [select Id from GL_Account__c];

TestData data=new TestData();

*/

    /* 
     * Global data - data which does not include a company lookup
     */

    
    public Account account = new Account(); 
    public Account billtoaccount = new Account(); 
    public Account shiptoaccount = new Account(); 
    public Account soldtoaccount = new Account(); 
    public Account remittoaccount = new Account();
    public List<UOM__c> uomList = new List<UOM__c>(); 
    public UOM__c uomObj = new UOM__c(); 
    public List<UOM_Conversion_Details__c> uomcList = new List<UOM_Conversion_Details__c>(); 
    public Payment_Term__c terms = new Payment_Term__c(); 
    public Class__c clsObj=new Class__c();
    public Item_Attribute__c itemAttrObj = new Item_Attribute__c();
    public Reason_Code__c resObj = new Reason_Code__c();
    
  
    
    
    public List<Exchange_Rate__c> exchangeRateList=new List<Exchange_Rate__c>();
    
    // Accounting Sub class creates the data for segment, GL Accounts, Accounting Rules and Exchange Rates
    public class Accounting {
        // globals 
        public Id myComp;
        public list<Accounting_Rule__c> rules = new List<Accounting_Rule__c>();
        public datetime effStartDate=datetime.newInstance(system.now().year()-1, 1, 1, 0, 0, 0);
        public Accounting_Standard__c accountingStandard = new Accounting_Standard__c();{
        	accountingStandard.name = 'US GAAP';
    		insert accountingStandard;
        }
        
        public Accounting (Id CompanyId){
            system.assertNotEquals(null, CompanyId, CompanyId);
            this.myComp = CompanyId;
            updateCompanyAS(myComp);
            updateGLAccountList();
            updateRules();
            updateAssetClasses();
        }
        
        public void updateCompanyAS(id myCompany){
        	Company__c c = new Company__c( id = myCompany);
        	c.Accounting_Standard__c = accountingStandard.id;
        	update c;
        }
        
        public void updateRules(){    
            updateJournalEntryRules();
            updateShipmentRules();
            updateCustInvRules();
            updateCustCMRules();
            updateCustReceiptRules();
            updatePOReceiptRules();
            updateSuppInvRules();
            updateSuppCMRules();
            updateSupplierPmtRules();
            updateInvChangeRules();
            updateWorkOrderRules();
            updateFixedAssetRules();
            //KNDY-10268 - deprecating bank file and bank file line objects
            //updateBankFileRules();
            updatePurchaseOrderRules();
            for(Accounting_Rule__c ar : rules){
                ar.Company_Ledger__c = true;
                ar.Accounting_Standard__c = accountingStandard.Id;
                //ar.Consolidation_Ledger__c = true;
                //ar.Statutory_Ledger__c = true;
                //ar.Subsidiary_Ledger__c = true;
            }
            
            AccountingRuleService.setUniqueKeyField(rules);
            //TODO: This is dealing with duplicates because we cannot make the unique_key__c field an external id in the managed package
            List<Accounting_Rule__c> newRules = new List<Accounting_Rule__c>();
            List<Accounting_Rule__c> existingRules = [SELECT Id, unique_key__c FROM Accounting_Rule__c WHERE Company__c = :myComp];
            set<string> ruleKeys = new set<string>();
            for(Accounting_Rule__c ar : existingRules){
                ruleKeys.add(ar.unique_key__c);
            }
            for(Accounting_Rule__c ar : rules){
                ar.effective_start_date__c=effStartDate;
                if(!ruleKeys.contains(ar.unique_key__c)){
                    newRules.add(ar);
                }
            }
            insert newRules;
            //insert rules;
            //upsert rules unique_key__c;
        }
        
        // Create Segment Definition
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
            for(Accounting_Default_Segment_Definition__c sd : existingSegs){
                if(sd.Name == 'Company__c'){
                    hasCompany = true;
                }else if(sd.Name == 'GL_Account__c'){
                    hasGL = true;
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
            insert customAccountingDefaultSegmentList; 
        } 
        
        // create the default wide rule which will allow any combination for the segments
        public List<Segment_Validation__c> svList = new List<Segment_Validation__c>();{
            Segment_Validation__c sv1 = new Segment_Validation__c();
            sv1.segment_1__c = '*';
            sv1.segment_2__c = '*';
            sv1.active__c = true;
            svList.add(sv1);
            Segment_Validation__c sv2 = new Segment_Validation__c();
            sv2.segment_1__c = '*';
            sv2.segment_2__c = null;
            sv2.active__c = true;
            svList.add(sv2);
            insert svList;
            
        }
        
        public List<Asset_Class__c> assetClasses = new List<Asset_Class__c>();
        
        public void updateAssetClasses(){
            
            
            Asset_Class__c vehAC = new Asset_Class__c(name = 'Vehicles', depreciation_method__c = 'MACRS', declining_balance__c = '200%', depreciation_period__c = 'Monthly', depreciation_convention__c = 'Full Month', life_in_months__c = 60, GL_Account__c = propertyGL.Id, company__c = myComp);
            assetClasses.add(vehAC);
            insert assetClasses;
            
            Tax_Book__c corpBook = new Tax_Book__c(active__c = true, corporate__c = true, name='Corporate', company__c = myComp);
            insert corpBook;
            
            Tax_Book__c taxBook = new Tax_Book__c(active__c = true, corporate__c = false, name = 'Tax Book', Tax_Book__c = corpBook.Id, company__c = myComp);
            insert taxBook;
            
            List<Asset_Class_Rule__c> acRules = new List<Asset_Class_Rule__c>();
            Asset_Class_Rule__c acrCorp = new Asset_Class_Rule__c();
            acrCorp.asset_class__c = vehAC.Id;
            acrCorp.depreciation_method__c = 'MACRS';
            acrCorp.declining_balance__c = '200%';
            acrCorp.depreciation_period__c = 'Monthly';
            acrCorp.depreciation_convention__c = 'Full Month';
            acrCorp.life_in_months__c = 60;
            acrCorp.Tax_Book__c = corpBook.Id;
            acrCorp.Company__c = myComp;
            acrCorp.start_date__c = system.today().addYears(-1);
            acrCorp.end_date__c = system.today().addYears(1);
            acrCorp.GL_Account__c = propertyGL.Id;
            acRules.add(acrCorp);
            
            Asset_Class_Rule__c acrTax = new Asset_Class_Rule__c();
            acrTax.asset_class__c = vehAC.Id;
            acrTax.depreciation_method__c = 'Straight Line';
            acrTax.declining_balance__c = null;
            acrTax.depreciation_period__c = 'Monthly';
            acrTax.depreciation_convention__c = 'Full Month';
            acrTax.life_in_months__c = 60;
            acrTax.Tax_Book__c = taxBook.Id;
            acrTax.start_date__c = system.today().addYears(-1);
            acrTax.end_date__c = system.today().addYears(1);
            acrTax.GL_Account__c = propertyGL.Id;
            acrTax.Company__c = myComp;
            acRules.add(acrTax);
            
            insert acRules;
        }
        
        // Create GL Types
        GL_Type__c currentAssets = new GL_Type__c();
        GL_Type__c longTermAssets = new GL_Type__c();
        GL_Type__c costOfGoodsSold = new GL_Type__c();
        GL_Type__c Revenue = new GL_Type__c();
        GL_Type__c operatingExpense = new GL_Type__c();
        GL_Type__c currentLiabilities = new GL_Type__c();
        GL_Type__c longTermLiabilities = new GL_Type__c();
        
        public List<GL_Type__c> GLTypeList = new List<GL_Type__c>();{
      
            currentAssets.Name  = 'Current Assets';
            currentAssets.Normal_Balance__c  = 'Debit';
            currentAssets.Accounting_Type__c  = 'Assets';
            currentAssets.Statement_Type__c  = 'Balance Sheet';
            currentAssets.Account_Range_From__c = '10000';
            currentAssets.Account_Range_To__c ='14999';
            GLTypeList.add(currentAssets);
            
            longTermAssets.Name  = 'Long Term Assets';
            longTermAssets.Normal_Balance__c  = 'Debit';
            longTermAssets.Accounting_Type__c  = 'Assets';
            longTermAssets.Statement_Type__c  = 'Balance Sheet';
            longTermAssets.Account_Range_From__c = '15000';
            longTermAssets.Account_Range_To__c ='19999';
            GLTypeList.add(longTermAssets);
            
            currentLiabilities.Name  = 'Current Liabilities';
            currentLiabilities.Normal_Balance__c  = 'Credit';
            currentLiabilities.Accounting_Type__c  = 'Liabilities';
            currentLiabilities.Statement_Type__c  = 'Balance Sheet';
            currentLiabilities.Account_Range_From__c = '20000';
            currentLiabilities.Account_Range_To__c ='24999';
            GLTypeList.add(currentLiabilities);
            
            longTermLiabilities.Name  = 'Long Term Liabilities';
            longTermLiabilities.Normal_Balance__c  = 'Credit';
            longTermLiabilities.Accounting_Type__c  = 'Liabilities';
            longTermLiabilities.Statement_Type__c  = 'Balance Sheet';
            longTermLiabilities.Account_Range_From__c = '25000';
            longTermLiabilities.Account_Range_To__c ='29999';
            GLTypeList.add(longTermLiabilities);
            
            Revenue.Name  = 'Revenue';
            Revenue.Normal_Balance__c  = 'Credit';
            Revenue.Accounting_Type__c  = 'Revenue';
            Revenue.Statement_Type__c  = 'Income Statement';
            Revenue.Account_Range_From__c = '40000';
            Revenue.Account_Range_To__c ='49999';
            GLTypeList.add(Revenue);
    
            costOfGoodsSold.Name  = 'Cost of Goods Sold';
            costOfGoodsSold.Normal_Balance__c  = 'Debit';
            costOfGoodsSold.Accounting_Type__c  = 'Cost of Goods Sold';
            costOfGoodsSold.Statement_Type__c  = 'Income Statement';
            costOfGoodsSold.Account_Range_From__c = '50000';
            costOfGoodsSold.Account_Range_To__c ='59999';
            GLTypeList.add(costOfGoodsSold);
            
            operatingExpense.Name  = 'Other Operating Expense';
            operatingExpense.Normal_Balance__c  = 'Debit';
            operatingExpense.Accounting_Type__c  = 'Operating Expenses';
            operatingExpense.Statement_Type__c  = 'Income Statement';
            operatingExpense.Account_Range_From__c = '60000';
            operatingExpense.Account_Range_To__c ='79999';
            GLTypeList.add(operatingExpense);
            
            insert GLTypeList;
        
        }   
        
    
        // Create GL Accounts
        public GL_Account__c cashGL = new GL_Account__c();
        public GL_Account__c unappliedCashGL = new GL_Account__c();
        public GL_Account__c propertyGL = new GL_Account__c();
        public GL_Account__c longTermGL = new GL_Account__c();
        public GL_Account__c inventoryGL = new GL_Account__c();
        public GL_Account__c cogsGL = new GL_Account__c();
        public GL_Account__c revenueGL = new GL_Account__c();
        public GL_Account__c salesReturnsGL = new GL_Account__c();
        public GL_Account__c taxGL = new GL_Account__c();
        public GL_Account__c receivablesGL = new GL_Account__c();
        public GL_Account__c wipInventoryGL = new GL_Account__c();
        public GL_Account__c FGInventoryGL = new GL_Account__c();
        public GL_Account__c payablesGL = new GL_Account__c();
        public GL_Account__c accruedExpGL = new GL_Account__c();
        public GL_Account__c overpaymentGL = new GL_Account__c();
        public GL_Account__c GRNIGL = new GL_Account__c();
        public GL_Account__c GoodsInTransit = new GL_Account__c();
        public GL_Account__c salesDiscountGL = new GL_Account__c();
        public GL_Account__c inventoryScrapGL = new GL_Account__c();
        public GL_Account__c allowanceExpGL = new GL_Account__c();
        public GL_Account__c deductionExpGL = new GL_Account__c();
        public GL_Account__c InventoryAdjustmentGL = new GL_Account__c();
        public GL_Account__c PPVGL = new GL_Account__c();
        public GL_Account__c IPVGL = new GL_Account__c();
        public GL_Account__c writeoffGL = new GL_Account__c();
        public GL_Account__c officeExpGL = new GL_Account__c();
        public GL_Account__c miscRcptGL = new GL_Account__c();
        public GL_Account__c miscIssueGL = new GL_Account__c();
        public GL_Account__c miscInvScrapGL = new GL_Account__c();
        public GL_Account__c marketingGL = new GL_Account__c();
        public GL_Account__c cipGL = new GL_Account__c();
        public GL_Account__c rawMaterialGL = new GL_Account__c();
        
        public List<GL_Account__c> GLAccountList = new List<GL_Account__c>();
        
        public void updateGLAccountList(){
        
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
            cashGL.FX_Type__c = 'Monetary Cash';
            cashGL.GL_Type__c = currentAssets.id;
            GLAccountList.add(cashGL);
            
            unappliedCashGL = new GL_Account__c();
            unappliedCashGL.Name = '12100 - Unapplied Cash';
            unappliedCashGL.GL_Account_Number__c = '12100';
            unappliedCashGL.GL_Account_Name__c = 'Unapplied Cash';
            unappliedCashGL.active__c = true;
            unappliedCashGL.Report_Section__c = 'Current Assets';  
            unappliedCashGL.Normal_Balance__c = 'Credit';
            unappliedCashGL.Statement_Type__c = 'Balance Sheet';
            unappliedCashGL.Report_Section_Grouping__c = 'Assets';
            unappliedCashGL.Cash_Flow_Report_Section_Grouping__c = 'Operating Cash Flow';
            unappliedCashGL.non_cash__c = true;
            unappliedCashGL.GL_type__c = currentAssets.id;
            GLAccountList.add(unappliedCashGL);
            
            propertyGL = new GL_Account__c();
            propertyGL.Name = '17000 - Property';
            propertyGL.GL_Account_Number__c = '17000';
            propertyGL.GL_Account_Name__c = 'Property';
            propertyGL.active__c = true;
            propertyGL.Report_Section__c = 'Long Term Assets';  
            propertyGL.Normal_Balance__c = 'Debit';
            propertyGL.Statement_Type__c = 'Balance Sheet';
            propertyGL.Report_Section_Grouping__c = 'Assets';
            propertyGL.Cash_Flow_Report_Section_Grouping__c = 'Investing Cash Flow';
            propertyGL.non_cash__c = true;
            propertyGL.GL_Type__c = longTermAssets.id;
            GLAccountList.add(propertyGL); 
            
            longTermGL = new GL_Account__c();
            longTermGL.Name = '28000 - Long Term';
            longTermGL.GL_Account_Number__c = '28000';
            longTermGL.GL_Account_Name__c = 'Long Term';
            longTermGL.active__c = true;
            longTermGL.Report_Section__c = 'Long Term Liabilities';  
            longTermGL.Normal_Balance__c = 'Credit';
            longTermGL.Statement_Type__c = 'Balance Sheet';
            longTermGL.Report_Section_Grouping__c = 'Liabilities and Equity';
            longTermGL.Cash_Flow_Report_Section_Grouping__c = 'Financing Cash Flow';
            longTermGL.non_cash__c = true;
            longTermGL.GL_Type__c = longTermLiabilities.id;
            GLAccountList.add(longTermGL);    
            
            inventoryGL = new GL_Account__c();
            inventoryGL.Name = '42000 - Revenue';
            inventoryGL.GL_Account_Number__c = '42000';
            inventoryGL.GL_Account_Name__c = 'Revenue';
            inventoryGL.Report_Section__c = 'Revenue';
            inventoryGL.Normal_Balance__c = 'Credit';
            inventoryGL.active__c = true;
            inventoryGL.Statement_Type__c = 'Income Statement';  
            inventoryGL.GL_type__c = revenue.id; 
            GLAccountList.add(inventoryGL);
            
            cogsGL = new GL_Account__c();
            cogsGL.Name = '50000 - Cost of Goods Sold';
            cogsGL.GL_Account_Number__c = '50000';
            cogsGL.GL_Account_Name__c = 'Cost of Goods Sold';
            cogsGL.Report_Section__c = 'Cost of Goods Sold';
            cogsGL.Normal_Balance__c = 'Debit';
            cogsGL.active__c = true;
            cogsGL.Statement_Type__c = 'Income Statement';  
            cogsGL.GL_type__c = costOfGoodsSold.id; 
            GLAccountList.add(cogsGL);
            
            revenueGL = new GL_Account__c();
            revenueGL.Name = '41000 - Revenue';
            revenueGL.GL_Account_Number__c = '41000';
            revenueGL.GL_Account_Name__c = 'Revenue';
            revenueGL.Report_Section__c = 'Revenue';
            revenueGL.Normal_Balance__c = 'Credit';
            revenueGL.active__c = true;
            revenueGL.Statement_Type__c = 'Income Statement';  
            revenueGL.GL_type__c = revenue.id; 
            GLAccountList.add(revenueGL);
            
            salesReturnsGL = new GL_Account__c();
            salesReturnsGL.Name = '48000 - Sales Returns';
            salesReturnsGL.GL_Account_Number__c = '48000';
            salesReturnsGL.GL_Account_Name__c = 'Sales Returns';
            salesReturnsGL.active__c = true;
            salesReturnsGL.Report_Section__c = 'Revenue';
            salesReturnsGL.Normal_Balance__c = 'Credit';
            salesReturnsGL.Statement_Type__c = 'Income Statement';  
            salesReturnsGL.GL_type__c = revenue.id; 
            GLAccountList.add(salesReturnsGL);
            
            taxGL = new GL_Account__c();
            taxGL.Name = '24000 - Taxes Payable';
            taxGL.GL_Account_Number__c = '24000';
            taxGL.GL_Account_Name__c = 'Taxes Payable';
            taxGL.active__c = true;
            taxGL.Report_Section__c = 'Interest and Tax Expenses';
            taxGL.Statement_Type__c = 'Income Statement';  
            taxGL.Normal_Balance__c = 'Debit';
            taxGL.GL_type__c = currentLiabilities.id; 
            GLAccountList.add(taxGL);
            
            receivablesGL = new GL_Account__c();
            receivablesGL.Name = '11000 - Accounts Receivable';
            receivablesGL.GL_Account_Number__c = '11000';
            receivablesGL.GL_Account_Name__c = 'Accounts Receivable';
            receivablesGL.active__c = true;
            receivablesGL.Report_Section__c = 'Current Assets';
            receivablesGL.Statement_Type__c = 'Balance Sheet'; 
            receivablesGL.Report_Section_Grouping__c = 'Assets';
            receivablesGL.Normal_Balance__c = 'Debit'; 
            receivablesGL.GL_type__c = currentAssets.id;  
            GLAccountList.add(receivablesGL);
            
            wipInventoryGL = new GL_Account__c();
            wipInventoryGL.Name = '14000 - WIP Inventory';
            wipInventoryGL.GL_Account_Number__c = '14000';
            wipInventoryGL.GL_Account_Name__c = 'WIP Inventory';
            wipInventoryGL.Report_Section__c = 'Current Assets';
            wipInventoryGL.Normal_Balance__c = 'Debit';
            wipInventoryGL.active__c = true;
            wipInventoryGL.Statement_Type__c = 'Balance Sheet';  
            wipInventoryGL.Report_Section_Grouping__c = 'Assets';
            wipInventoryGL.GL_type__c = currentAssets.id;
            GLAccountList.add(wipInventoryGL);
            
            FGInventoryGL = new GL_Account__c();
            FGInventoryGL.Name = '15000 - Finished Goods Inventory';
            FGInventoryGL.GL_Account_Number__c = '15000';
            FGInventoryGL.GL_Account_Name__c = 'Finished Goods Inventory';
            FGInventoryGL.Report_Section__c = 'Current Assets';
            FGInventoryGL.active__c = true;
            FGInventoryGL.Statement_Type__c = 'Balance Sheet';  
            FGInventoryGL.Normal_Balance__c = 'Debit';
            FGInventoryGL.Report_Section_Grouping__c = 'Assets';
            FGInventoryGL.FX_Type__c = 'Monetary Non-cash';
            FGInventoryGL.GL_type__c = longTermAssets.id;
            GLAccountList.add(FGInventoryGL);
            
            payablesGL = new GL_Account__c();
            payablesGL.Name = '21000 - Accounts Payable ';
            payablesGL.GL_Account_Number__c = '21000';
            payablesGL.GL_Account_Name__c = 'Accounts Payable';
            payablesGL.Report_Section__c = 'Accounts Payable';
            payablesGL.Normal_Balance__c = 'Credit';
            payablesGL.active__c = true;
            payablesGL.Statement_Type__c = 'Income Statement';  
            payablesGL.FX_Type__c = 'Monetary Non-cash';
            payablesGL.GL_type__c = currentLiabilities.id;
            GLAccountList.add(payablesGL);
            
            accruedExpGL = new GL_Account__c();
            accruedExpGL.Name = '22000 - Accrued Expense';
            accruedExpGL.GL_Account_Number__c = '22000';
            accruedExpGL.GL_Account_Name__c = 'Accrued Expense';
            accruedExpGL.Report_Section__c = 'Current Liabilities';
            accruedExpGL.active__c = true;
            accruedExpGL.Statement_Type__c = 'Income Statement';  
            accruedExpGL.Normal_Balance__c = 'Credit';
            accruedExpGL.GL_type__c = currentLiabilities.id;
            GLAccountList.add(accruedExpGL);
            
            overpaymentGL = new GL_Account__c();
            overpaymentGL.Name = '24000 - Overpayment';
            overpaymentGL.GL_Account_Number__c = '24000';
            overpaymentGL.GL_Account_Name__c = 'Overpayment';
            overpaymentGL.Report_Section__c = 'Current Liabilities';
            overpaymentGL.active__c = true;
            overpaymentGL.Normal_Balance__c = 'Credit';
            overpaymentGL.Statement_Type__c = 'Income Statement';  
            overpaymentGL.GL_type__c = currentLiabilities.id;
            GLAccountList.add(overpaymentGL);
            
            GRNIGL = new GL_Account__c();
            GRNIGL.Name = '23000 - Goods Received Not Invoiced ';
            GRNIGL.GL_Account_Number__c = '23000';
            GRNIGL.GL_Account_Name__c = 'Goods Received Not Invoiced';
            GRNIGL.Report_Section__c = 'Current Liabilities';
            GRNIGL.active__c = true;
            GRNIGL.Normal_Balance__c = 'Credit';
            GRNIGL.Statement_Type__c = 'Income Statement';  
            GRNIGL.FX_Type__c = 'Monetary Non-cash';
            GRNIGL.GL_type__c = currentLiabilities.id;
            GLAccountList.add(GRNIGL);
            
            GoodsInTransit = new GL_Account__c();
            GoodsInTransit.Name = '23100 - Goods In Transit';
            GoodsInTransit.GL_Account_Number__c = '23100';
            GoodsInTransit.GL_Account_Name__c = 'Goods In Transit';
            GoodsInTransit.Report_Section__c = 'Current Liabilities';
            GoodsInTransit.active__c = true;
            GoodsInTransit.Normal_Balance__c = 'Credit';
            GoodsInTransit.Statement_Type__c = 'Income Statement';  
            GoodsInTransit.GL_type__c = currentLiabilities.id; 
            GLAccountList.add(GoodsInTransit);
            
            salesDiscountGL = new GL_Account__c();
            salesDiscountGL.Name = '49000 - Sales Discounts';
            salesDiscountGL.GL_Account_Number__c = '49000';
            salesDiscountGL.GL_Account_Name__c = 'Sales Discounts';
            salesDiscountGL.Report_Section__c = 'Current Liabilities';
            salesDiscountGL.active__c = true;
            salesDiscountGL.Normal_Balance__c = 'Credit';
            salesDiscountGL.Statement_Type__c = 'Income Statement';  
            salesDiscountGL.GL_type__c = revenue.id;  
            GLAccountList.add(salesDiscountGL);
            
            inventoryScrapGL = new GL_Account__c();
            inventoryScrapGL.Name = '52000 - Inventory Scrap';
            inventoryScrapGL.GL_Account_Number__c = '52000';
            inventoryScrapGL.GL_Account_Name__c = 'Inventory Scrap';
            inventoryScrapGL.Report_Section__c = 'Cost of Goods Sold';
            inventoryScrapGL.active__c = true;
            inventoryScrapGL.Normal_Balance__c = 'Credit';
            inventoryScrapGL.Statement_Type__c = 'Income Statement';  
            inventoryScrapGL.GL_type__c = costOfGoodsSold.id;  
            GLAccountList.add(inventoryScrapGL);
            
            allowanceExpGL = new GL_Account__c();
            allowanceExpGL.Name = '65000 - Allowance Expense';
            allowanceExpGL.GL_Account_Number__c = '65000';
            allowanceExpGL.GL_Account_Name__c = 'Allowance Expense';
            allowanceExpGL.Report_Section__c = 'Cost of Goods Sold';
            allowanceExpGL.active__c = true;
            allowanceExpGL.Normal_Balance__c = 'Credit';
            allowanceExpGL.Statement_Type__c = 'Income Statement';  
            allowanceExpGL.GL_type__c = operatingExpense.id;  
            GLAccountList.add(allowanceExpGL);
            
            deductionExpGL = new GL_Account__c();
            deductionExpGL.Name = '66000 - Deduction Expense';
            deductionExpGL.GL_Account_Number__c = '66000';
            deductionExpGL.GL_Account_Name__c = 'Deduction Expense';
            deductionExpGL.Report_Section__c = 'Cost of Goods Sold';
            deductionExpGL.active__c = true;
            deductionExpGL.Normal_Balance__c = 'Credit';
            deductionExpGL.Statement_Type__c = 'Income Statement';  
            deductionExpGL.GL_type__c = operatingExpense.id;  
            GLAccountList.add(deductionExpGL);
            
            InventoryAdjustmentGL = new GL_Account__c();
            InventoryAdjustmentGL.Name = '58500 - Inventory Adjustment';
            InventoryAdjustmentGL.GL_Account_Number__c = '58500';
            InventoryAdjustmentGL.GL_Account_Name__c = 'Inventory Adjustment';
            InventoryAdjustmentGL.Report_Section__c = 'Current Assets';
            InventoryAdjustmentGL.active__c = true;
            InventoryAdjustmentGL.Normal_Balance__c = 'Debit';
            InventoryAdjustmentGL.Statement_Type__c = 'Balance Sheet';  
            InventoryAdjustmentGL.Report_Section_Grouping__c = 'Assets';
            InventoryAdjustmentGL.GL_type__c = costOfGoodsSold.id;
            GLAccountList.add(InventoryAdjustmentGL);
            
            PPVGL = new GL_Account__c();
            PPVGL.Name = '24100 - Purchase Price Variance';
            PPVGL.GL_Account_Number__c = '24100';
            PPVGL.GL_Account_Name__c = 'Purchase Price Variance';
            PPVGL.Report_Section__c = 'Purchase Price Variance';
            PPVGL.active__c = true;
            PPVGL.Normal_Balance__c = 'Credit';
            PPVGL.Statement_Type__c = 'Income Statement';  
            PPVGL.FX_Type__c = 'Monetary Non-cash';
            PPVGL.GL_type__c = currentLiabilities.id;
            GLAccountList.add(PPVGL);
            
            IPVGL = new GL_Account__c();
            IPVGL.Name = '59100 - Invoice Price Variance';
            IPVGL.GL_Account_Number__c = '59100';
            IPVGL.GL_Account_Name__c = 'Invoice Price Variance';
            IPVGL.Report_Section__c = 'Invoice Price Variance';
            IPVGL.active__c = true;
            IPVGL.Normal_Balance__c = 'Credit';
            IPVGL.Statement_Type__c = 'Income Statement';
            IPVGL.FX_Type__c = 'Monetary Non-cash';  
            IPVGL.GL_type__c = costOfGoodsSold.id;  
            GLAccountList.add(IPVGL);
            
            writeoffGL = new GL_Account__c();
            writeoffGL.Name = '61000 - Write Off';
            writeoffGL.GL_Account_Number__c = '61000';
            writeoffGL.GL_Account_Name__c = 'Write Off';
            writeoffGL.Report_Section__c = 'Write Off';
            writeoffGL.active__c = true;
            writeoffGL.Normal_Balance__c = 'Credit';
            writeoffGL.Statement_Type__c = 'Income Statement';  
            writeoffGL.GL_type__c = operatingExpense.id; 
            GLAccountList.add(writeoffGL);
            
            officeExpGL = new GL_Account__c();
            officeExpGL.Name = '65000 - Office Expense';
            officeExpGL.GL_Account_Number__c = '65000';
            officeExpGL.GL_Account_Name__c = 'Office Expense';
            officeExpGL.Report_Section__c = 'Write Off';
            officeExpGL.active__c = true;
            officeExpGL.Normal_Balance__c = 'Credit';
            officeExpGL.Statement_Type__c = 'Income Statement';  
            officeExpGL.GL_type__c = operatingExpense.id;
            GLAccountList.add(officeExpGL);
            
            miscRcptGL = new GL_Account__c();
            miscRcptGL.Name = '23500 - Misc Receipt of Items';
            miscRcptGL.GL_Account_Number__c = '23500';
            miscRcptGL.GL_Account_Name__c = 'Misc Receipt of Items';
            miscRcptGL.Report_Section__c = ' ';
            miscRcptGL.active__c = true;
            miscRcptGL.Normal_Balance__c = 'Credit';
            miscRcptGL.Statement_Type__c = 'Income Statement';  
            miscRcptGL.GL_type__c = currentLiabilities.id;  
            GLAccountList.add(miscRcptGL);
            
            miscIssueGL = new GL_Account__c();
            miscIssueGL.Name = '51000 - Misc Issue';
            miscIssueGL.GL_Account_Number__c = '51000';
            miscIssueGL.GL_Account_Name__c = 'Misc Issue';
            miscIssueGL.Report_Section__c = ' ';
            miscIssueGL.active__c = true;
            miscIssueGL.Normal_Balance__c = 'Credit';
            miscIssueGL.Statement_Type__c = 'Income Statement';  
            miscIssueGL.GL_type__c = costOfGoodsSold.id;  
            GLAccountList.add(miscIssueGL);
            
            miscInvScrapGL = new GL_Account__c();
            miscInvScrapGL.Name = '52100 - Inventory Scrap';
            miscInvScrapGL.GL_Account_Number__c = '52100';
            miscInvScrapGL.GL_Account_Name__c = 'Inventory Scrap';
            miscInvScrapGL.Report_Section__c = ' ';
            miscInvScrapGL.active__c = true;
            miscInvScrapGL.Normal_Balance__c = 'Credit';
            miscInvScrapGL.Statement_Type__c = 'Income Statement';  
            miscInvScrapGL.GL_type__c = costOfGoodsSold.id;  
            GLAccountList.add(miscInvScrapGL);
            
            marketingGL = new GL_Account__c();
            marketingGL.Name = '62000 - Marketing Expense';
            marketingGL.GL_Account_Number__c = '62000';
            marketingGL.GL_Account_Name__c = 'Marketing Expense';
            marketingGL.Report_Section__c = 'Expense';
            marketingGL.active__c = true;
            marketingGL.Normal_Balance__c = 'Credit';
            marketingGL.Statement_Type__c = 'Income Statement';  
            marketingGL.GL_type__c = operatingExpense.id;  
            GLAccountList.add(marketingGL);
            
            cipGL = new GL_Account__c();
            cipGL.Name = '15100 - CIP';
            cipGL.GL_Account_Number__c = '15100';
            cipGL.GL_Account_Name__c = 'CIP';
            cipGL.Report_Section__c = 'Long Term Assets';
            cipGL.active__c = true;
            cipGL.Normal_Balance__c = 'Credit';
            cipGL.Statement_Type__c = 'Income Statement';  
            cipGL.GL_type__c = longTermAssets.id;  
            GLAccountList.add(cipGL);
            
            rawMaterialGL = new GL_Account__c();
            rawMaterialGL.Name = '22500 - Raw Materials';
            rawMaterialGL.GL_Account_Number__c = '22500';
            rawMaterialGL.GL_Account_Name__c = 'Raw Materials';
            rawMaterialGL.Report_Section__c = 'Current Assets';
            rawMaterialGL.active__c = true;
            rawMaterialGL.Normal_Balance__c = 'Debit';
            rawMaterialGL.Statement_Type__c = 'Balance Sheet';
            rawMaterialGL.Report_Section_Grouping__c = 'Assets';  
            rawMaterialGL.GL_type__c = currentLiabilities.id;  
            GLAccountList.add(rawMaterialGL);

            for(GL_Account__c gl : GLAccountList){
                gl.GL_Account_Unique__c = gl.Name;
            }
            
            //insert GLAccountList;
            upsert GLAccountList GL_Account_Unique__c;
        } 
        
       public List<Accounting_Rule__c> JEAccountingRules = new List<Accounting_Rule__c> ();
       public void updateJournalEntryRules(){
            Accounting_Rule__c jeRule1 = new Accounting_Rule__c();
            jeRule1.Object_Name__c = 'Journal_Entry__c';
            jeRule1.Company__c = myComp;
            jeRule1.Transaction__c = 'Manual';
            jeRule1.SubTransaction_Type__c = null;
            jeRule1.Line_Type__c = null;
            jeRule1.Rule_Type__c = 'CR';
            jeRule1.Default_GL_Account__c = false;
            jeRule1.GL_Account_Reference_Value__c = 'GL_Account__c';
            jeRule1.GL_Account__c = null;
            jeRule1.Amount_Reference__c = null;            
            jeRule1.Raise_Exceptions_for_Blank_Amounts__c=true;
            jeRule1.Suppress_Zero_Amount_Lines__c = true;                
            JEAccountingRules.add(jeRule1);
            
            Accounting_Rule__c jeRule2 = new Accounting_Rule__c();
            jeRule2.Object_Name__c = 'Journal_Entry__c';
            jeRule2.Company__c = myComp;
            jeRule2.Transaction__c = 'Manual';
            jeRule2.SubTransaction_Type__c = null;
            jeRule2.Line_Type__c = null;
            jeRule2.Rule_Type__c = 'DR';
            jeRule2.Default_GL_Account__c = false;
            jeRule2.GL_Account_Reference_Value__c = 'GL_Account__c';
            jeRule2.GL_Account__c = null;
            jeRule2.Amount_Reference__c = null;               
            jeRule2.Raise_Exceptions_for_Blank_Amounts__c=true;
            jeRule2.Suppress_Zero_Amount_Lines__c = true;                
            JEAccountingRules.add(jeRule2); 
            
            Accounting_Rule__c jeRule3 = new Accounting_Rule__c();
            jeRule3.Object_Name__c = 'Journal_Entry__c';
            jeRule3.Company__c = myComp;
            jeRule3.Transaction__c = 'Accrual - Manual';
            jeRule3.Line_Type__c = null;
            jeRule3.Rule_Type__c = 'CR';
            jeRule3.Default_GL_Account__c = false;
            jeRule3.GL_Account_Reference_Value__c = 'GL_Account__c';
            jeRule3.GL_Account__c = null;
            jeRule3.Amount_Reference__c = null; 
            jeRule3.Company_Ledger__c = true;           
            jeRule3.Raise_Exceptions_for_Blank_Amounts__c=true;
            jeRule3.Suppress_Zero_Amount_Lines__c = true;                
            JEAccountingRules.add(jeRule3);
            
            Accounting_Rule__c jeRule4 = new Accounting_Rule__c();
            jeRule4.Object_Name__c = 'Journal_Entry__c';
            jeRule4.Company__c = myComp;
            jeRule4.Transaction__c = 'Accrual - Manual';
            jeRule4.Line_Type__c = null;
            jeRule4.Rule_Type__c = 'DR';
            jeRule4.Default_GL_Account__c = false;
            jeRule4.GL_Account_Reference_Value__c = 'GL_Account__c';
            jeRule4.GL_Account__c = null;
            jeRule4.Amount_Reference__c = null; 
            jeRule4.Company_Ledger__c = true;               
            jeRule4.Raise_Exceptions_for_Blank_Amounts__c=true;
            jeRule4.Suppress_Zero_Amount_Lines__c = true;                
            JEAccountingRules.add(jeRule4);           
        
        }
       
       // Create Accounting Rules
        public List<Accounting_Rule__c> ShipmentAcctRulesList = new List<Accounting_Rule__c>();
        public void updateShipmentRules(){
            Accounting_Rule__c shipacctRule1 = new Accounting_Rule__c();
            shipacctRule1.Object_Name__c = 'Shipment__c';
            shipacctRule1.Company__c = myComp;
            shipacctRule1.Transaction__c = 'Shipment';
            shipacctRule1.SubTransaction_Type__c = 'Goods';
            shipacctRule1.Line_Type__c = null;
            //shipacctRule1.Segment_Name__c = 'GL_Account__c';
            shipacctRule1.Rule_Type__c = 'CR';
            //shipacctRule1.Criteria__c = 'Item Class';
            shipacctRule1.Default_GL_Account__c = false;
            shipacctRule1.GL_Account_Reference_Value__c = 'Product__r.Item__r.class__r.Inventory_GL_Account__c';
            shipacctRule1.GL_Account__c = null;
            shipacctRule1.Amount_Reference__c = null;            
            ShipmentAcctRulesList.add(shipacctRule1);
            
            Accounting_Rule__c shipacctRule2 = new Accounting_Rule__c();
            shipacctRule2.Object_Name__c = 'Shipment__c';
            shipacctRule2.Company__c = myComp;
            shipacctRule2.Transaction__c = 'Shipment';
            shipacctRule2.SubTransaction_Type__c = 'Goods';
            shipacctRule2.Line_Type__c = null;
            //shipacctRule2.Segment_Name__c = 'GL_Account__c';
            shipacctRule2.Rule_Type__c = 'DR';
            //shipacctRule2.Criteria__c = 'Accounting Default';
            shipacctRule2.Default_GL_Account__c = true;
            shipacctRule2.GL_Account_Reference_Value__c = null;
            shipacctRule2.GL_Account__c = cogsGL.id;
            shipacctRule2.Amount_Reference__c = null;               
            ShipmentAcctRulesList.add(shipacctRule2);            
        
            rules.addAll(ShipmentAcctRulesList);
            //insert ShipmentAcctRulesList;
            //system.debug( LoggingLevel.INFO, ShipmentAcctRulesList );
        }
        
        public List<Accounting_Rule__c> CustInvAcctRulesList = new List<Accounting_Rule__c>();
        public void updateCustInvRules(){
            
            Accounting_Rule__c custInvGoodsCR = new Accounting_Rule__c();
            custInvGoodsCR.Object_Name__c = 'Customer_Invoice__c';
            custInvGoodsCR.Company__c = myComp;
            custInvGoodsCR.Transaction__c = 'Customer Invoice';
            custInvGoodsCR.SubTransaction_Type__c = 'Goods';
            //custInvAcctCR.Segment_Name__c = 'GL_Account__c';
            custInvGoodsCR.Rule_Type__c = 'CR';
            //custInvAcctCR.Criteria__c = 'Customer Type';
            custInvGoodsCR.Default_GL_Account__c = false;
            custInvGoodsCR.GL_Account_Reference_Value__c = 'Product__r.Item__r.class__r.Revenue_GL_Account__c';
            custInvGoodsCR.GL_Account__c = null;
            CustInvAcctRulesList.add(custInvGoodsCR);
            
            Accounting_Rule__c custInvGoodsDR = new Accounting_Rule__c();
            custInvGoodsDR.Object_Name__c = 'Customer_Invoice__c';
            custInvGoodsDR.Company__c = myComp;
            custInvGoodsDR.Transaction__c = 'Customer Invoice';
            custInvGoodsDR.SubTransaction_Type__c = 'Goods';
            //custInvAcctDR.Segment_Name__c = 'GL_Account__c';
            custInvGoodsDR.Rule_Type__c = 'DR';
            //custInvAcctDR.Criteria__c = 'Customer Type';
            custInvGoodsDR.Default_GL_Account__c = true;
            custInvGoodsDR.GL_Account_Reference_Value__c = null;
            custInvGoodsDR.GL_Account__c = receivablesGL.id;
            CustInvAcctRulesList.add(custInvGoodsDR);            
            
            Accounting_Rule__c CIGoodsCR = new Accounting_Rule__c();
            CIGoodsCR.Object_Name__c = 'Customer_Invoice__c';
            CIGoodsCR.Company__c = myComp;
            CIGoodsCR.Transaction__c = 'Ship Invoice';
            CIGoodsCR.SubTransaction_Type__c = 'Goods';
            //custInvAcctCR.Segment_Name__c = 'GL_Account__c';
            CIGoodsCR.Rule_Type__c = 'CR';
            //custInvAcctCR.Criteria__c = 'Customer Type';
            CIGoodsCR.Default_GL_Account__c = false;
            CIGoodsCR.GL_Account_Reference_Value__c = 'Product__r.Item__r.class__r.Revenue_GL_Account__c';
            CIGoodsCR.GL_Account__c = null;
            CustInvAcctRulesList.add(CIGoodsCR);
            
            Accounting_Rule__c CIGoodsDR = new Accounting_Rule__c();
            CIGoodsDR.Object_Name__c = 'Customer_Invoice__c';
            CIGoodsDR.Company__c = myComp;
            CIGoodsDR.Transaction__c = 'Ship Invoice';
            CIGoodsDR.SubTransaction_Type__c = 'Goods';
            //custInvAcctDR.Segment_Name__c = 'GL_Account__c';
            CIGoodsDR.Rule_Type__c = 'DR';
            //custInvAcctDR.Criteria__c = 'Customer Type';
            CIGoodsDR.Default_GL_Account__c = true;
            CIGoodsDR.GL_Account_Reference_Value__c = null;
            CIGoodsDR.GL_Account__c = receivablesGL.id;
            CustInvAcctRulesList.add(CIGoodsDR); 
                       
            Accounting_Rule__c custInvManualGoodsCR = new Accounting_Rule__c();
            custInvManualGoodsCR.Object_Name__c = 'Customer_Invoice__c';
            custInvManualGoodsCR.Company__c = myComp;
            custInvManualGoodsCR.Transaction__c = 'Manual';
            custInvManualGoodsCR.SubTransaction_Type__c = 'Goods';
            custInvManualGoodsCR.Rule_Type__c = 'CR';
            custInvManualGoodsCR.Default_GL_Account__c = true;
            custInvManualGoodsCR.GL_Account_Reference_Value__c = null;
            custInvManualGoodsCR.GL_Account__c = cashGL.id;
            CustInvAcctRulesList.add(custInvManualGoodsCR);
        
            Accounting_Rule__c custInvManualGoodsDR = new Accounting_Rule__c();
            custInvManualGoodsDR.Object_Name__c = 'Customer_Invoice__c';
            custInvManualGoodsDR.Company__c = myComp;
            custInvManualGoodsDR.Transaction__c = 'Manual';
            custInvManualGoodsDR.SubTransaction_Type__c = 'Goods';
            custInvManualGoodsDR.Rule_Type__c = 'DR';
            custInvManualGoodsDR.Default_GL_Account__c = true;
            custInvManualGoodsDR.GL_Account_Reference_Value__c = null;
            custInvManualGoodsDR.GL_Account__c = receivablesGL.id;
            CustInvAcctRulesList.add(custInvManualGoodsDR);
            
            Accounting_Rule__c custInvTaxCR = new Accounting_Rule__c();
            custInvTaxCR.Object_Name__c = 'Customer_Invoice__c';
            custInvTaxCR.company__c = myComp;
            custInvTaxCR.Transaction__c = 'Customer Invoice';
            custInvTaxCR.SubTransaction_Type__c = 'Sales Tax';
            //custInvTaxCR.Segment_Name__c = 'GL_Account__c';
            custInvTaxCR.Rule_Type__c = 'CR';
            //custInvTaxCR.Criteria__c = 'Accounting Default';
            custInvTaxCR.Default_GL_Account__c = true;
            custInvTaxCR.GL_Account_Reference_Value__c = null;
            custInvTaxCR.GL_Account__c = taxGL.id;
            CustInvAcctRulesList.add(custInvTaxCR);
            
            Accounting_Rule__c custInvTaxDR = new Accounting_Rule__c();
            custInvTaxDR.Object_Name__c = 'Customer_Invoice__c';
            custInvTaxDR.company__c = myComp;
            custInvTaxDR.Transaction__c = 'Customer Invoice';
            custInvTaxDR.SubTransaction_Type__c = 'Sales Tax';
            //custInvTaxDR.Segment_Name__c = 'GL_Account__c';
            custInvTaxDR.Rule_Type__c = 'DR';
            //custInvTaxDR.Criteria__c = 'Accounting Default';
            custInvTaxDR.Default_GL_Account__c = true;
            custInvTaxDR.GL_Account_Reference_Value__c = null;
            custInvTaxDR.GL_Account__c = receivablesGL.id;
            CustInvAcctRulesList.add(custInvTaxDR);
            
            Accounting_Rule__c custInvMiscCR = new Accounting_Rule__c();
            custInvMiscCR.Object_Name__c = 'Customer_Invoice__c';
            custInvMiscCR.company__c = myComp;
            custInvMiscCR.Transaction__c = 'Customer Invoice';
            custInvMiscCR.SubTransaction_Type__c = 'Miscellaneous';
            //custInvMiscCR.Segment_Name__c = 'GL_Account__c';
            custInvMiscCR.Rule_Type__c = 'CR';
            //custInvMiscCR.Criteria__c = 'Customer Type';
            custInvMiscCR.Default_GL_Account__c = false;
            custInvMiscCR.GL_Account_Reference_Value__c = 'Product__r.Item__r.class__r.Revenue_GL_Account__c';
            CustInvAcctRulesList.add(custInvMiscCR);
            
            Accounting_Rule__c custInvMiscDR = new Accounting_Rule__c();
            custInvMiscDR.Object_Name__c = 'Customer_Invoice__c';
            custInvMiscDR.company__c = myComp;
            custInvMiscDR.Transaction__c = 'Customer Invoice';
            custInvMiscDR.SubTransaction_Type__c = 'Miscellaneous';
            //custInvMiscDR.Segment_Name__c = 'GL_Account__c';
            custInvMiscDR.Rule_Type__c = 'DR';
            //custInvMiscDR.Criteria__c = 'Accounting Default';
            custInvMiscDR.Default_GL_Account__c = true;
            custInvMiscDR.GL_Account_Reference_Value__c = null;
            custInvMiscDR.GL_Account__c = receivablesGL.id;
            CustInvAcctRulesList.add(custInvMiscDR);
            
            Accounting_Rule__c custInvOffCR = new Accounting_Rule__c();
            custInvOffCR.Object_Name__c = 'Customer_Invoice__c';
            custInvOffCR.company__c = myComp;
            custInvOffCR.Transaction__c = 'Customer Invoice';
            custInvOffCR.SubTransaction_Type__c = 'Off Invoice';
            //custInvOffCR.Segment_Name__c = 'GL_Account__c';
            custInvOffCR.Rule_Type__c = 'CR';
            //custInvOffCR.Criteria__c = 'Accounting Default';
            custInvOffCR.Default_GL_Account__c = true;
            custInvOffCR.GL_Account_Reference_Value__c = null;
            custInvOffCR.GL_Account__c = allowanceExpGL.id;
            CustInvAcctRulesList.add(custInvOffCR);
            
            Accounting_Rule__c custInvOffDR = new Accounting_Rule__c();
            custInvOffDR.Object_Name__c = 'Customer_Invoice__c';
            custInvOffDR.company__c = myComp;
            custInvOffDR.Transaction__c = 'Customer Invoice';
            custInvOffDR.SubTransaction_Type__c = 'Off Invoice';
            //custInvOffDR.Segment_Name__c = 'GL_Account__c';
            custInvOffDR.Rule_Type__c = 'DR';
            //custInvOffDR.Criteria__c = 'Accounting Default';
            custInvOffDR.Default_GL_Account__c = true;
            custInvOffDR.GL_Account_Reference_Value__c = null;
            custInvOffDR.GL_Account__c = receivablesGL.id;
            CustInvAcctRulesList.add(custInvOffDR);
            
            Accounting_Rule__c custInvDedCreditCR = new Accounting_Rule__c();
            custInvDedCreditCR.Object_Name__c = 'Customer_Invoice__c';
            custInvDedCreditCR.company__c = myComp;
            custInvDedCreditCR.Transaction__c = 'Adjustment';
            custInvDedCreditCR.Subtransaction_Type__c = 'Goods';
            custInvDedCreditCR.Line_Type__c = 'Deduction Credit';
            //custInvDedCreditCR.Segment_Name__c = 'GL_Account__c';
            custInvDedCreditCR.Rule_Type__c = 'CR';
            //custInvDedCreditCR.Criteria__c = 'Accounting Default';
            custInvDedCreditCR.Default_GL_Account__c = true;
            custInvDedCreditCR.GL_Account_Reference_Value__c = null;
            custInvDedCreditCR.GL_Account__c = cashGL.id;
            CustInvAcctRulesList.add(custInvDedCreditCR);
            
            Accounting_Rule__c custInvDedCreditDR = new Accounting_Rule__c();
            custInvDedCreditDR.Object_Name__c = 'Customer_Invoice__c';
            custInvDedCreditDR.company__c = myComp;
            custInvDedCreditDR.Transaction__c = 'Adjustment';
            custInvDedCreditDR.Subtransaction_Type__c = 'Goods';
            custInvDedCreditDR.Line_Type__c = 'Deduction Credit';
            //custInvDedCreditDR.Segment_Name__c = 'GL_Account__c';
            custInvDedCreditDR.Rule_Type__c = 'DR';
            //custInvDedCreditDR.Criteria__c = 'Accounting Default';
            custInvDedCreditDR.Default_GL_Account__c = true;
            custInvDedCreditDR.GL_Account_Reference_Value__c = null;
            custInvDedCreditDR.GL_Account__c = receivablesGL.id;
            CustInvAcctRulesList.add(custInvDedCreditDR);
                
            rules.addAll(CustInvAcctRulesList);    
            //insert CustInvAcctRulesList;
        }
        
        public List<Accounting_Rule__c> CustCMAcctRulesList = new List<Accounting_Rule__c>();
        public void updateCustCMRules(){
            Accounting_Rule__c cmInvCR = new Accounting_Rule__c();
            cmInvCR.Object_Name__c = 'Customer_Invoice__c';
            cmInvCR.company__c = myComp;
            cmInvCR.Transaction__c = 'Invoice Credit';
            cmInvCR.SubTransaction_Type__c = 'Goods';
            //cmInvCR.Segment_Name__c = 'GL_Account__c';
            cmInvCR.Rule_Type__c = 'CR';
            //cmInvCR.Criteria__c = 'Accounting Default';
            cmInvCR.Default_GL_Account__c = true;
            cmInvCR.GL_Account_Reference_Value__c = null;
            cmInvCR.GL_Account__c = receivablesGL.id;
            CustCMAcctRulesList.add(cmInvCR);
            
            Accounting_Rule__c cmInvDR = new Accounting_Rule__c();
            cmInvDR.Object_Name__c = 'Customer_Invoice__c';
            cmInvDR.company__c = myComp;
            cmInvDR.Transaction__c = 'Invoice Credit';
            cmInvDR.SubTransaction_Type__c = 'Goods';
            //cmInvDR.Segment_Name__c = 'GL_Account__c';
            cmInvDR.Rule_Type__c = 'DR';
            //cmInvDR.Criteria__c = 'Accounting Default';
            cmInvDR.Default_GL_Account__c = false;
            cmInvDR.GL_Account_Reference_Value__c = 'Product__r.Item__r.class__r.Revenue_GL_Account__c';//'Accounting_Segment__r.GL_Account__c';
            cmInvDR.GL_Account__c = salesReturnsGL.id;
            CustCMAcctRulesList.add(cmInvDR);
            
            Accounting_Rule__c cmMiscCR = new Accounting_Rule__c();
            cmMiscCR.Object_Name__c = 'Customer_Invoice__c';
            cmMiscCR.company__c = myComp;
            cmMiscCR.Transaction__c = 'Miscellaneous Credit';
            cmMiscCR.SubTransaction_Type__c = null;
            //cmMiscCR.Segment_Name__c = 'GL_Account__c';
            cmMiscCR.Rule_Type__c = 'CR';
            //cmMiscCR.Criteria__c = 'Accounting Default';
            cmMiscCR.Default_GL_Account__c = true;
            cmMiscCR.GL_Account_Reference_Value__c = null;
            cmMiscCR.GL_Account__c = receivablesGL.id;
            CustCMAcctRulesList.add(cmMiscCR);
            
            Accounting_Rule__c cmMiscDR = new Accounting_Rule__c();
            cmMiscDR.Object_Name__c = 'Customer_Invoice__c';
            cmMiscDR.company__c = myComp;
            cmMiscDR.Transaction__c = 'Miscellaneous Credit';
            cmMiscDR.SubTransaction_Type__c = null;
            //cmMiscDR.Segment_Name__c = 'GL_Account__c';
            cmMiscDR.Rule_Type__c = 'DR';
            //cmMiscDR.Criteria__c = 'Accounting Default';
            cmMiscDR.Default_GL_Account__c = false;
            cmMiscDR.GL_Account_Reference_Value__c = 'Product__r.Item__r.class__r.Revenue_GL_Account__c';//'Accounting_Segment__r.GL_Account__c';
            cmMiscDR.GL_Account__c = salesReturnsGL.id;
            CustCMAcctRulesList.add(cmMiscDR);
            
            Accounting_Rule__c prepayCR = new Accounting_Rule__c();
            prepayCR.Object_Name__c = 'Customer_Invoice__c';
            prepayCR.company__c = myComp;
            prepayCR.Transaction__c = 'Prepayment';
            prepayCR.SubTransaction_Type__c = null;
            prepayCR.Rule_Type__c = 'CR';
            prepayCR.Default_GL_Account__c = true;
            prepayCR.GL_Account_Reference_Value__c = null;
            prepayCR.GL_Account__c = receivablesGL.id;
            CustCMAcctRulesList.add(prepayCR);
            
            Accounting_Rule__c prepayDR = new Accounting_Rule__c();
            prepayDR.Object_Name__c = 'Customer_Invoice__c';
            prepayDR.company__c = myComp;
            prepayDR.Transaction__c = 'Prepayment';
            prepayDR.SubTransaction_Type__c = null;
            prepayDR.Rule_Type__c = 'DR';
            prepayDR.Default_GL_Account__c = true;
            prepayDR.GL_Account_Reference_Value__c = null;
            prepayDR.GL_Account__c = salesReturnsGL.id;
            CustCMAcctRulesList.add(prepayDR);
            
            Accounting_Rule__c cmcCR = new Accounting_Rule__c();
            cmcCR.Object_Name__c = 'Customer_Invoice__c';
            cmcCR.company__c = myComp;
            cmcCR.Transaction__c = 'Credit Memo';
            cmcCR.SubTransaction_Type__c = null;
            cmcCR.Rule_Type__c = 'CR';
            cmcCR.Default_GL_Account__c = true;
            cmcCR.GL_Account_Reference_Value__c = null;
            cmcCR.GL_Account__c = receivablesGL.id;
            CustCMAcctRulesList.add(cmcCR);
            
            Accounting_Rule__c cmcDR = new Accounting_Rule__c();
            cmcDR.Object_Name__c = 'Customer_Invoice__c';
            cmcDR.company__c = myComp;
            cmcDR.Transaction__c = 'Credit Memo';
            cmcDR.SubTransaction_Type__c = null;
            cmcDR.Rule_Type__c = 'DR';
            cmcDR.Default_GL_Account__c = true;
            cmcDR.GL_Account_Reference_Value__c = null;
            cmcDR.GL_Account__c = salesReturnsGL.id;
            CustCMAcctRulesList.add(cmcDR);
            
            rules.addAll(CustCMAcctRulesList);
            //insert CustCMAcctRulesList;
        }
        
        public List<Accounting_Rule__c> CustReceiptAcctRulesList = new List<Accounting_Rule__c>();
        public void updateCustReceiptRules(){
            Accounting_Rule__c cracctRule1 = new Accounting_Rule__c();
            cracctRule1.Object_Name__c = 'Customer_Receipt__c';
            cracctRule1.company__c = myComp;
            cracctRule1.Transaction__c = 'Customer Receipt';
            cracctRule1.SubTransaction_Type__c = 'Payment';
            //cracctRule1.Segment_Name__c = 'GL_Account__c';
            cracctRule1.Rule_Type__c = 'CR';
            //cracctRule1.Criteria__c = 'Accounting Default';
            cracctRule1.Default_GL_Account__c = true;
            cracctRule1.GL_Account_Reference_Value__c = null;
            cracctRule1.GL_Account__c = receivablesGL.id;
            cracctRule1.Amount_Reference__c = null;            
            CustReceiptAcctRulesList.add(cracctRule1);
            
            
            Accounting_Rule__c cracctRule2 = new Accounting_Rule__c();
            cracctRule2.Object_Name__c = 'Customer_Receipt__c';
            cracctRule2.company__c = myComp;
            cracctRule2.Transaction__c = 'Customer Receipt';
            cracctRule2.SubTransaction_Type__c = 'Payment';
            //cracctRule2.Segment_Name__c = 'GL_Account__c';
            cracctRule2.Rule_Type__c = 'DR';
            //cracctRule2.Criteria__c = 'Bank Account / Lockbox';
            cracctRule2.Default_GL_Account__c = true;
            cracctRule2.GL_Account_Reference_Value__c = null;
            cracctRule2.GL_Account__c = unappliedCashGL.Id;
            cracctRule2.Amount_Reference__c = null;                
            CustReceiptAcctRulesList.add(cracctRule2);
            
            Accounting_Rule__c cracctRule3 = new Accounting_Rule__c();
            cracctRule3.Object_Name__c = 'Customer_Receipt__c';
            cracctRule3.company__c = myComp;
            cracctRule3.Transaction__c = 'Customer Receipt';
            cracctRule3.SubTransaction_Type__c = 'Write Off';
            //cracctRule3.Segment_Name__c = 'GL_Account__c';
            cracctRule3.Rule_Type__c = 'CR';
            //cracctRule3.Criteria__c = 'Accounting Default';
            cracctRule3.Default_GL_Account__c = true;
            cracctRule3.GL_Account_Reference_Value__c = null;
            cracctRule3.GL_Account__c = receivablesGL.id;
            cracctRule3.Amount_Reference__c = null;                
            CustReceiptAcctRulesList.add(cracctRule3);
            
            Accounting_Rule__c cracctRule4 = new Accounting_Rule__c();
            cracctRule4.Object_Name__c = 'Customer_Receipt__c';
            cracctRule4.company__c = myComp;
            cracctRule4.Transaction__c = 'Customer Receipt';
            cracctRule4.SubTransaction_Type__c = 'Write Off';
            //cracctRule4.Segment_Name__c = 'GL_Account__c';
            cracctRule4.Rule_Type__c = 'DR';
            //cracctRule4.Criteria__c = 'Accounting Default';
            cracctRule4.Default_GL_Account__c = true;
            cracctRule4.GL_Account_Reference_Value__c = null;
            cracctRule4.GL_Account__c = writeoffGL.id;
            cracctRule4.Amount_Reference__c = null;                
            CustReceiptAcctRulesList.add(cracctRule4);
            
            Accounting_Rule__c cracctRule5 = new Accounting_Rule__c();
            cracctRule5.Object_Name__c = 'Customer_Receipt__c';
            cracctRule5.company__c = myComp;
            cracctRule5.Transaction__c = 'Customer Receipt';
            cracctRule5.SubTransaction_Type__c = 'Earned Terms Discount';
            //cracctRule5.Segment_Name__c = 'GL_Account__c';
            cracctRule5.Rule_Type__c = 'CR';
            //cracctRule5.Criteria__c = 'Accounting Default';
            cracctRule5.Default_GL_Account__c = true;
            cracctRule5.GL_Account_Reference_Value__c = null;
            cracctRule5.GL_Account__c = receivablesGL.id;
            CustReceiptAcctRulesList.add(cracctRule5);
            
            Accounting_Rule__c cracctRule6 = new Accounting_Rule__c();
            cracctRule6.Object_Name__c = 'Customer_Receipt__c';
            cracctRule6.company__c = myComp;
            cracctRule6.Transaction__c = 'Customer Receipt';
            cracctRule6.SubTransaction_Type__c = 'Earned Terms Discount';
            //cracctRule6.Segment_Name__c = 'GL_Account__c';
            cracctRule6.Rule_Type__c = 'DR';
            //cracctRule6.Criteria__c = null;
            cracctRule6.Default_GL_Account__c = true;
            cracctRule6.GL_Account_Reference_Value__c = null;
            cracctRule6.GL_Account__c = salesDiscountGL.id;
            cracctRule6.Amount_Reference__c = null;                
            CustReceiptAcctRulesList.add(cracctRule6);
            
            Accounting_Rule__c cracctRule7 = new Accounting_Rule__c();
            cracctRule7.Object_Name__c = 'Customer_Receipt__c';
            cracctRule7.company__c = myComp;
            cracctRule7.Transaction__c = 'Customer Receipt';
            cracctRule7.SubTransaction_Type__c = 'Unearned Terms Discount';
            //cracctRule7.Segment_Name__c = 'GL_Account__c';
            cracctRule7.Rule_Type__c = 'CR';
            //cracctRule7.Criteria__c = null;
            cracctRule7.Default_GL_Account__c = true;
            cracctRule7.GL_Account_Reference_Value__c = null;
            cracctRule7.GL_Account__c = receivablesGL.id;
            cracctRule7.Amount_Reference__c = null;                
            CustReceiptAcctRulesList.add(cracctRule7);
            
            Accounting_Rule__c cracctRule8 = new Accounting_Rule__c();
            cracctRule8.Object_Name__c = 'Customer_Receipt__c';
            cracctRule8.company__c = myComp;
            cracctRule8.Transaction__c = 'Customer Receipt';
            cracctRule8.SubTransaction_Type__c = 'Unearned Terms Discount';
            //cracctRule8.Segment_Name__c = 'GL_Account__c';
            cracctRule8.Rule_Type__c = 'DR';
            //cracctRule8.Criteria__c = null;
            cracctRule8.Default_GL_Account__c = true;
            cracctRule8.GL_Account_Reference_Value__c = null;
            cracctRule8.GL_Account__c = salesDiscountGL.id;
            cracctRule8.Amount_Reference__c = null;                
            CustReceiptAcctRulesList.add(cracctRule8);
            
            Accounting_Rule__c cracctRule9 = new Accounting_Rule__c();
            cracctRule9.Object_Name__c = 'Customer_Receipt__c';
            cracctRule9.company__c = myComp;
            cracctRule9.Transaction__c = 'Customer Receipt';
            cracctRule9.SubTransaction_Type__c = 'Deduction';
            //cracctRule9.Segment_Name__c = 'GL_Account__c';
            cracctRule9.Rule_Type__c = 'CR';
            //cracctRule9.Criteria__c = null;
            cracctRule9.Default_GL_Account__c = true;
            cracctRule9.GL_Account_Reference_Value__c = null;
            cracctRule9.GL_Account__c = receivablesGL.id;
            cracctRule9.Amount_Reference__c = null;                
            CustReceiptAcctRulesList.add(cracctRule9);
            
            Accounting_Rule__c cracctRule10 = new Accounting_Rule__c();
            cracctRule10.Object_Name__c = 'Customer_Receipt__c';
            cracctRule10.company__c = myComp;
            cracctRule10.Transaction__c = 'Customer Receipt';
            cracctRule10.SubTransaction_Type__c = 'Deduction';
            //cracctRule10.Segment_Name__c = 'GL_Account__c';
            cracctRule10.Rule_Type__c = 'DR';
            //cracctRule10.Criteria__c = null;
            cracctRule10.Default_GL_Account__c = true;
            cracctRule10.GL_Account_Reference_Value__c = null;
            cracctRule10.GL_Account__c = deductionExpGL.id;
            cracctRule10.Amount_Reference__c = null;                
            CustReceiptAcctRulesList.add(cracctRule10);
            
            Accounting_Rule__c cracctRule11 = new Accounting_Rule__c();
            cracctRule11.Object_Name__c = 'Customer_Receipt__c';
            cracctRule11.company__c = myComp;
            cracctRule11.Transaction__c = 'Customer Receipt';
            cracctRule11.SubTransaction_Type__c = 'Overpayment';
            //cracctRule11.Segment_Name__c = 'GL_Account__c';
            cracctRule11.Rule_Type__c = 'CR';
            //cracctRule11.Criteria__c = null;
            cracctRule11.Default_GL_Account__c = true;
            cracctRule11.GL_Account_Reference_Value__c = null;
            cracctRule11.GL_Account__c = overpaymentGL.id;
            cracctRule11.Amount_Reference__c = null;                
            CustReceiptAcctRulesList.add(cracctRule11);
            
            Accounting_Rule__c cracctRule12 = new Accounting_Rule__c();
            cracctRule12.Object_Name__c = 'Customer_Receipt__c';
            cracctRule12.company__c = myComp;
            cracctRule12.Transaction__c = 'Customer Receipt';
            cracctRule12.SubTransaction_Type__c = 'Overpayment';
            //cracctRule12.Segment_Name__c = 'GL_Account__c';
            cracctRule12.Rule_Type__c = 'DR';
            //cracctRule12.Criteria__c = null;
            cracctRule12.Default_GL_Account__c = true;
            cracctRule12.GL_Account_Reference_Value__c = null;
            cracctRule12.GL_Account__c = cashGL.id;
            cracctRule12.Amount_Reference__c = null;
            CustReceiptAcctRulesList.add(cracctRule12);
            
            Accounting_Rule__c cracctRule13 = new Accounting_Rule__c();
            cracctRule13.Object_Name__c = 'Customer_Receipt__c';
            cracctRule13.company__c = myComp;
            cracctRule13.Transaction__c = 'Customer Receipt';
            cracctRule13.SubTransaction_Type__c = 'Credit Memo';
            //cracctRule13.Segment_Name__c = 'GL_Account__c';
            cracctRule13.Rule_Type__c = 'CR';
            //cracctRule13.Criteria__c = null;
            cracctRule13.Default_GL_Account__c = true;
            cracctRule13.GL_Account_Reference_Value__c = null;
            cracctRule13.GL_Account__c = cashGL.id;
            cracctRule13.Amount_Reference__c = null;                
            CustReceiptAcctRulesList.add(cracctRule13);
            
            Accounting_Rule__c cracctRule14 = new Accounting_Rule__c();
            cracctRule14.Object_Name__c = 'Customer_Receipt__c';
            cracctRule14.company__c = myComp;
            cracctRule14.Transaction__c = 'Customer Receipt';
            cracctRule14.SubTransaction_Type__c = 'Credit Memo';
            //cracctRule14.Segment_Name__c = 'GL_Account__c';
            cracctRule14.Rule_Type__c = 'DR';
            //cracctRule14.Criteria__c = null;
            cracctRule14.Default_GL_Account__c = true;
            cracctRule14.GL_Account_Reference_Value__c = null;
            cracctRule14.GL_Account__c = receivablesGL.id;
            cracctRule14.Amount_Reference__c = null;                
            CustReceiptAcctRulesList.add(cracctRule14);
                
            rules.addAll(CustReceiptAcctRulesList);    
            //insert CustReceiptAcctRulesList;
    
        }
        
        public List<Accounting_Rule__c> POReceiptAcctRulesList = new List<Accounting_Rule__c>();
        public void updatePOReceiptRules(){
            Accounting_Rule__c rcptacctRule1 = new Accounting_Rule__c();
            rcptacctRule1.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule1.company__c = myComp;
            //FIN-566 fix -ASN Accounting                        
            rcptacctRule1.Transaction__c = 'Purchase Order Receipt';
            rcptacctRule1.SubTransaction_Type__c = 'Goods';
            rcptacctRule1.Rule_Type__c = 'CR';
            rcptacctRule1.Default_GL_Account__c = true;
            rcptacctRule1.GL_Account__c = GRNIGL.id;
            rcptacctRule1.Amount_Reference__c = 'Purchase_Price__c';            
            POReceiptAcctRulesList.add(rcptacctRule1);

            //FIN-566 fix -ASN Accounting            
            Accounting_Rule__c rcptacctRule10 = new Accounting_Rule__c();
            rcptacctRule10.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule10.company__c = myComp;
            rcptacctRule10.Transaction__c = 'Advanced Shipment Notice';
            rcptacctRule10.SubTransaction_Type__c = 'Goods';
            rcptacctRule10.Rule_Type__c = 'CR';
            rcptacctRule10.Default_GL_Account__c = true;
            rcptacctRule10.GL_Account__c = GRNIGL.id;
            rcptacctRule10.Amount_Reference__c = 'Purchase_Price__c';            
            POReceiptAcctRulesList.add(rcptacctRule10);
            
            Accounting_Rule__c rcptacctRule2 = new Accounting_Rule__c();
            rcptacctRule2.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule2.company__c = myComp;
            //FIN-566 fix -ASN Accounting                        
            rcptacctRule2.Transaction__c = 'Purchase Order Receipt';
            rcptacctRule2.SubTransaction_Type__c = 'Goods';
            rcptacctRule2.Rule_Type__c = 'DR';
            rcptacctRule2.Default_GL_Account__c = false;
            rcptacctRule2.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            rcptacctRule2.GL_Account__c = null;
            rcptacctRule2.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule2);
            
            //FIN-566 fix -ASN Accounting                        
            Accounting_Rule__c rcptacctRule20 = new Accounting_Rule__c();
            rcptacctRule20.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule20.company__c = myComp;
            rcptacctRule20.Transaction__c = 'Advanced Shipment Notice';
            rcptacctRule20.SubTransaction_Type__c = 'Goods';
            rcptacctRule20.Rule_Type__c = 'DR';
            rcptacctRule20.Default_GL_Account__c = false;
            rcptacctRule20.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            rcptacctRule20.GL_Account__c = null;
            rcptacctRule20.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule20);
            
            
            
            Accounting_Rule__c rcptacctRule11 = new Accounting_Rule__c();
            rcptacctRule11.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule11.company__c = myComp;
            //FIN-566 fix -ASN Accounting                        
            rcptacctRule11.Transaction__c = 'Purchase Order Receipt';
            rcptacctRule11.SubTransaction_Type__c = 'Goods';
            rcptacctRule11.Rule_Type__c = 'CR';
            rcptacctRule11.Default_GL_Account__c = true;
            rcptacctRule11.GL_Account_Reference_Value__c = null;
            rcptacctRule11.GL_Account__c = PPVGL.id;
            rcptacctRule11.Amount_Reference__c = null;            
            POReceiptAcctRulesList.add(rcptacctRule11);
            
            //FIN-566 fix -ASN Accounting                                    
            Accounting_Rule__c rcptacctRule12 = new Accounting_Rule__c();
            rcptacctRule12.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule12.company__c = myComp;
            rcptacctRule12.Transaction__c = 'Advanced Shipment Notice';
            rcptacctRule12.SubTransaction_Type__c = 'Goods';
            rcptacctRule12.Rule_Type__c = 'CR';
            rcptacctRule12.Default_GL_Account__c = true;
            rcptacctRule12.GL_Account_Reference_Value__c = null;
            rcptacctRule12.GL_Account__c = PPVGL.id;
            rcptacctRule12.Amount_Reference__c = null;            
            POReceiptAcctRulesList.add(rcptacctRule12);
            
            Accounting_Rule__c rcptacctRule22 = new Accounting_Rule__c();
            rcptacctRule22.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule22.company__c = myComp;
            //FIN-566 fix -ASN Accounting                        
            rcptacctRule22.Transaction__c = 'Purchase Order Receipt';
            rcptacctRule22.SubTransaction_Type__c = 'Goods';
            rcptacctRule22.Rule_Type__c = 'DR';
            rcptacctRule22.Default_GL_Account__c = true;
            rcptacctRule22.GL_Account__c = PPVGL.Id;
            rcptacctRule22.Amount_Reference__c = 'Purchase_Price__c';               
            POReceiptAcctRulesList.add(rcptacctRule22);
            
            //FIN-566 fix -ASN Accounting                                                            
            Accounting_Rule__c rcptacctRule23 = new Accounting_Rule__c();
            rcptacctRule23.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule23.company__c = myComp;
            rcptacctRule23.Transaction__c = 'Advanced Shipment Notice';
            rcptacctRule23.SubTransaction_Type__c = 'Goods';
            rcptacctRule23.Rule_Type__c = 'DR';
            rcptacctRule23.Default_GL_Account__c = true;
            rcptacctRule23.GL_Account__c = PPVGL.Id;
            rcptacctRule23.Amount_Reference__c = 'Purchase_Price__c';               
            POReceiptAcctRulesList.add(rcptacctRule23);
            
            Accounting_Rule__c rcptacctRule3 = new Accounting_Rule__c();
            rcptacctRule3.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule3.company__c = myComp;
            //FIN-566 fix -ASN Accounting                        
            rcptacctRule3.Transaction__c = 'Purchase Order Receipt';
            rcptacctRule3.SubTransaction_Type__c = 'Expense';
            //rcptacctRule3.Segment_Name__c = 'GL_Account__c';
            rcptacctRule3.Rule_Type__c = 'CR';
            //rcptacctRule3.Criteria__c = 'Accounting Default';
            rcptacctRule3.Default_GL_Account__c = false;
            rcptacctRule3.GL_Account_Reference_Value__c = null;
            rcptacctRule3.GL_Account__c = GRNIGL.id;
            rcptacctRule3.Amount_Reference__c = null;              
            POReceiptAcctRulesList.add(rcptacctRule3);
            
            
            //FIN-566 fix -ASN Accounting                                                                        
            Accounting_Rule__c rcptacctRule30 = new Accounting_Rule__c();
            rcptacctRule30.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule30.company__c = myComp;
            rcptacctRule30.Transaction__c = 'Advanced Shipment Notice';
            rcptacctRule30.SubTransaction_Type__c = 'Expense';
            //rcptacctRule3.Segment_Name__c = 'GL_Account__c';
            rcptacctRule30.Rule_Type__c = 'CR';
            //rcptacctRule3.Criteria__c = 'Accounting Default';
            rcptacctRule30.Default_GL_Account__c = false;
            rcptacctRule30.GL_Account_Reference_Value__c = null;
            rcptacctRule30.GL_Account__c = GRNIGL.id;
            rcptacctRule30.Amount_Reference__c = null;              
            POReceiptAcctRulesList.add(rcptacctRule30);  
            
            Accounting_Rule__c rcptacctRule4 = new Accounting_Rule__c();
            rcptacctRule4.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule4.company__c = myComp;
            //FIN-566 fix -ASN Accounting                        
            rcptacctRule4.Transaction__c = 'Purchase Order Receipt';
            rcptacctRule4.SubTransaction_Type__c = 'Expense';
            //rcptacctRule4.Segment_Name__c = 'GL_Account__c';
            rcptacctRule4.Rule_Type__c = 'DR';
            //rcptacctRule4.Criteria__c = 'Item Class';
            rcptacctRule4.Default_GL_Account__c = false;
            rcptacctRule4.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            rcptacctRule4.GL_Account__c = null;
            rcptacctRule4.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule4);
            
            //FIN-566 fix -ASN Accounting                                                            
            Accounting_Rule__c rcptacctRule40 = new Accounting_Rule__c();
            rcptacctRule40.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule40.company__c = myComp;
            rcptacctRule40.Transaction__c = 'Advanced Shipment Notice';
            rcptacctRule40.SubTransaction_Type__c = 'Expense';
            //rcptacctRule4.Segment_Name__c = 'GL_Account__c';
            rcptacctRule40.Rule_Type__c = 'DR';
            //rcptacctRule4.Criteria__c = 'Item Class';
            rcptacctRule40.Default_GL_Account__c = false;
            rcptacctRule40.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            rcptacctRule40.GL_Account__c = null;
            rcptacctRule40.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule40);           
            
            Accounting_Rule__c rcptacctRule5 = new Accounting_Rule__c();
            rcptacctRule5.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule5.company__c = myComp;
            //FIN-566 fix -ASN Accounting                        
            rcptacctRule5.Transaction__c = 'Purchase Order Receipt';
            rcptacctRule5.SubTransaction_Type__c = 'Miscellaneous';
            //rcptacctRule5.Segment_Name__c = 'GL_Account__c';
            rcptacctRule5.Rule_Type__c = 'CR';
            //rcptacctRule5.Criteria__c = 'Accounting Default';
            rcptacctRule5.Default_GL_Account__c = false;
            rcptacctRule5.GL_Account_Reference_Value__c = null;
            rcptacctRule5.GL_Account__c = GRNIGL.id;
            rcptacctRule5.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule5);

            //FIN-566 fix -ASN Accounting                                                            
            Accounting_Rule__c rcptacctRule50 = new Accounting_Rule__c();
            rcptacctRule50.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule50.company__c = myComp;
            rcptacctRule50.Transaction__c = 'Advanced Shipment Notice';
            rcptacctRule50.SubTransaction_Type__c = 'Miscellaneous';
            //rcptacctRule5.Segment_Name__c = 'GL_Account__c';
            rcptacctRule50.Rule_Type__c = 'CR';
            //rcptacctRule5.Criteria__c = 'Accounting Default';
            rcptacctRule50.Default_GL_Account__c = false;
            rcptacctRule50.GL_Account_Reference_Value__c = null;
            rcptacctRule50.GL_Account__c = GRNIGL.id;
            rcptacctRule50.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule50);


            
            Accounting_Rule__c rcptacctRule6 = new Accounting_Rule__c();
            rcptacctRule6.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule6.company__c = myComp;
            //FIN-566 fix -ASN Accounting                        
            rcptacctRule6.Transaction__c = 'Purchase Order Receipt';
            rcptacctRule6.SubTransaction_Type__c = 'Miscellaneous';
            //rcptacctRule6.Segment_Name__c = 'GL_Account__c';
            rcptacctRule6.Rule_Type__c = 'DR';
            //rcptacctRule6.Criteria__c = 'Item Class';
            rcptacctRule6.Default_GL_Account__c = false;
            rcptacctRule6.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            rcptacctRule6.GL_Account__c = null;
            rcptacctRule6.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule6);

            //FIN-566 fix -ASN Accounting                                                            
            Accounting_Rule__c rcptacctRule60 = new Accounting_Rule__c();
            rcptacctRule60.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule60.company__c = myComp;
            rcptacctRule60.Transaction__c = 'Advanced Shipment Notice';
            rcptacctRule60.SubTransaction_Type__c = 'Miscellaneous';
            //rcptacctRule6.Segment_Name__c = 'GL_Account__c';
            rcptacctRule60.Rule_Type__c = 'DR';
            //rcptacctRule6.Criteria__c = 'Item Class';
            rcptacctRule60.Default_GL_Account__c = false;
            rcptacctRule60.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            rcptacctRule60.GL_Account__c = null;
            rcptacctRule60.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule60);



            
            Accounting_Rule__c rcptacctRule7 = new Accounting_Rule__c();
            rcptacctRule7.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule7.company__c = myComp;
            //FIN-566 fix -ASN Accounting                        
            rcptacctRule7.Transaction__c = 'Purchase Order Receipt';
            rcptacctRule7.SubTransaction_Type__c = null;
            rcptacctRule7.Rule_Type__c = 'CR';
            rcptacctRule7.Default_GL_Account__c = false;
            rcptacctRule7.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            rcptacctRule7.GL_Account__c = null;
            rcptacctRule7.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule7);


            //FIN-566 fix -ASN Accounting                                                            
            Accounting_Rule__c rcptacctRule70 = new Accounting_Rule__c();
            rcptacctRule70.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule70.company__c = myComp;
            rcptacctRule70.Transaction__c = 'Advanced Shipment Notice';
            rcptacctRule70.SubTransaction_Type__c = null;
            rcptacctRule70.Rule_Type__c = 'CR';
            rcptacctRule70.Default_GL_Account__c = false;
            rcptacctRule70.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            rcptacctRule70.GL_Account__c = null;
            rcptacctRule70.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule70);
            
            
                        
            Accounting_Rule__c rcptacctRule8 = new Accounting_Rule__c();
            rcptacctRule8.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule8.company__c = myComp;
            //FIN-566 fix -ASN Accounting                        
            rcptacctRule8.Transaction__c = 'Purchase Order Receipt';
            rcptacctRule8.SubTransaction_Type__c = null;
            rcptacctRule8.Rule_Type__c = 'DR';
            rcptacctRule8.Default_GL_Account__c = false;
            rcptacctRule8.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            rcptacctRule8.GL_Account__c = null;
            rcptacctRule8.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule8);
 
 
             //FIN-566 fix -ASN Accounting                                                            
             Accounting_Rule__c rcptacctRule80 = new Accounting_Rule__c();
            rcptacctRule80.Object_Name__c = 'Receiving_Document__c';
            rcptacctRule80.company__c = myComp;
            rcptacctRule80.Transaction__c = 'Advanced Shipment Notice';
            rcptacctRule80.SubTransaction_Type__c = null;
            rcptacctRule80.Rule_Type__c = 'DR';
            rcptacctRule80.Default_GL_Account__c = false;
            rcptacctRule80.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            rcptacctRule80.GL_Account__c = null;
            rcptacctRule80.Amount_Reference__c = null;               
            POReceiptAcctRulesList.add(rcptacctRule80);
            
            rules.addAll(POReceiptAcctRulesList);
            //insert POReceiptAcctRulesList;
        
        }
        
        public List<Accounting_Rule__c> SuppInvAcctRulesList = new List<Accounting_Rule__c>();
        public void updateSuppInvRules(){
            Accounting_Rule__c sinvacctRule1 = new Accounting_Rule__c();
            sinvacctRule1.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule1.company__c = myComp;
            sinvacctRule1.Transaction__c = 'Supplier Invoice';
            sinvacctRule1.SubTransaction_Type__c = 'Goods';
            sinvacctRule1.Rule_Type__c = 'DR';
            sinvacctRule1.Default_GL_Account__c = true;
            sinvacctRule1.GL_Account_Reference_Value__c = null;
            sinvacctRule1.GL_Account__c = IPVGL.id;
            sinvacctRule1.Line_Type__c = 'Item';
            SuppInvAcctRulesList.add(sinvacctRule1);
            
            Accounting_Rule__c sinvacctRule2 = new Accounting_Rule__c();
            sinvacctRule2.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule2.company__c = myComp;
            sinvacctRule2.Transaction__c = 'Supplier Invoice';
            sinvacctRule2.SubTransaction_Type__c = 'Goods';
            sinvacctRule2.Rule_Type__c = 'CR';
            sinvacctRule2.Default_GL_Account__c = true;
            sinvacctRule2.GL_Account_Reference_Value__c = null;
            sinvacctRule2.GL_Account__c = payablesGL.id;
            sinvacctRule2.Line_Type__c = 'Item';
            SuppInvAcctRulesList.add(sinvacctRule2);
            
            Accounting_Rule__c sinvacctRule11 = new Accounting_Rule__c();
            sinvacctRule11.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule11.company__c = myComp;
            sinvacctRule11.Transaction__c = 'Supplier Invoice';
            sinvacctRule11.SubTransaction_Type__c = 'Goods';
            sinvacctRule11.Rule_Type__c = 'DR';
            sinvacctRule11.Default_GL_Account__c = true;
            sinvacctRule11.GL_Account_Reference_Value__c = null;
            sinvacctRule11.GL_Account__c = GRNIGL.id;
            sinvacctRule11.Line_Type__c = 'Item';
            sinvacctRule11.Amount_Reference__c = 'Purchase_Price__c';
            SuppInvAcctRulesList.add(sinvacctRule11);
            
            Accounting_Rule__c sinvacctRule22 = new Accounting_Rule__c();
            sinvacctRule22.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule22.company__c = myComp;
            sinvacctRule22.Transaction__c = 'Supplier Invoice';
            sinvacctRule22.SubTransaction_Type__c = 'Goods';
            sinvacctRule22.Rule_Type__c = 'CR';
            sinvacctRule22.Default_GL_Account__c = true;
            sinvacctRule22.GL_Account_Reference_Value__c = null;
            sinvacctRule22.GL_Account__c = IPVGL.id;
            sinvacctRule22.Line_Type__c = 'Item';
            sinvacctRule22.Amount_Reference__c = 'Purchase_Price__c';
            SuppInvAcctRulesList.add(sinvacctRule22);
            
            Accounting_Rule__c sinvacctRule91 = new Accounting_Rule__c();
            sinvacctRule91.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule91.company__c = myComp;
            sinvacctRule91.Transaction__c = 'Supplier Invoice';
            sinvacctRule91.SubTransaction_Type__c = 'Goods';
            sinvacctRule91.Rule_Type__c = 'DR';
            sinvacctRule91.Default_GL_Account__c = true;
            sinvacctRule91.GL_Account_Reference_Value__c = null;
            sinvacctRule91.GL_Account__c = IPVGL.id;
            SuppInvAcctRulesList.add(sinvacctRule91);
            
            //KNDY-12704
            Accounting_Rule__c sinvacctRule912 = new Accounting_Rule__c();
            sinvacctRule912.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule912.company__c = myComp;
            sinvacctRule912.Transaction__c = 'Supplier Invoice';
            sinvacctRule912.SubTransaction_Type__c = 'Goods - Purchase Order';
            sinvacctRule912.Rule_Type__c = 'CR';
            sinvacctRule912.Default_GL_Account__c = true;
            sinvacctRule912.GL_Account_Reference_Value__c = null;
            sinvacctRule912.GL_Account__c = IPVGL.id;
            sinvacctRule912.Amount_Reference__c = 'Purchase_Price__c';
            SuppInvAcctRulesList.add(sinvacctRule912);
            
            Accounting_Rule__c sinvacctRule913 = new Accounting_Rule__c();
            sinvacctRule913.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule913.company__c = myComp;
            sinvacctRule913.Transaction__c = 'Supplier Invoice';
            sinvacctRule913.SubTransaction_Type__c = 'Goods - Purchase Order';
            sinvacctRule913.Rule_Type__c = 'DR';
            sinvacctRule913.Default_GL_Account__c = true;
            sinvacctRule913.GL_Account_Reference_Value__c = null;
            sinvacctRule913.GL_Account__c = IPVGL.id;
            SuppInvAcctRulesList.add(sinvacctRule913);
            // end KNDY-12704
            
            Accounting_Rule__c sinvacctRule92 = new Accounting_Rule__c();
            sinvacctRule92.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule92.company__c = myComp;
            sinvacctRule92.Transaction__c = 'Supplier Invoice';
            sinvacctRule92.SubTransaction_Type__c = 'Goods';
            sinvacctRule92.Rule_Type__c = 'CR';
            sinvacctRule92.Default_GL_Account__c = true;
            sinvacctRule92.GL_Account_Reference_Value__c = null;
            sinvacctRule92.GL_Account__c = payablesGL.id;
            SuppInvAcctRulesList.add(sinvacctRule92);
            
            Accounting_Rule__c sinvacctRule911 = new Accounting_Rule__c();
            sinvacctRule911.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule911.company__c = myComp;
            sinvacctRule911.Transaction__c = 'Supplier Invoice';
            sinvacctRule911.SubTransaction_Type__c = 'Goods';
            sinvacctRule911.Rule_Type__c = 'DR';
            sinvacctRule911.Default_GL_Account__c = true;
            sinvacctRule911.GL_Account_Reference_Value__c = null;
            sinvacctRule911.GL_Account__c = GRNIGL.id;
            sinvacctRule911.Amount_Reference__c = 'Purchase_Price__c';
            SuppInvAcctRulesList.add(sinvacctRule911);
            
            Accounting_Rule__c sinvacctRule922 = new Accounting_Rule__c();
            sinvacctRule922.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule922.company__c = myComp;
            sinvacctRule922.Transaction__c = 'Supplier Invoice';
            sinvacctRule922.SubTransaction_Type__c = 'Goods';
            sinvacctRule922.Rule_Type__c = 'CR';
            sinvacctRule922.Default_GL_Account__c = true;
            sinvacctRule922.GL_Account_Reference_Value__c = null;
            sinvacctRule922.GL_Account__c = IPVGL.id;
            sinvacctRule922.Amount_Reference__c = 'Purchase_Price__c';
            SuppInvAcctRulesList.add(sinvacctRule922);
            
            /*
            Accounting_Rule__c sinvacctRule3 = new Accounting_Rule__c();
            sinvacctRule3.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule3.company__c = myComp;
            sinvacctRule3.Transaction__c = 'Supplier Invoice';
            sinvacctRule3.SubTransaction_Type__c = 'Purchase Price Variance';
            //sinvacctRule3.Segment_Name__c = 'GL_Account__c';
            sinvacctRule3.Rule_Type__c = 'CR';
            //sinvacctRule3.Criteria__c = 'Accounting Default';
            sinvacctRule3.Default_GL_Account__c = true;
            sinvacctRule3.GL_Account_Reference_Value__c = null;
            sinvacctRule3.GL_Account__c = PPVGL.id;
            SuppInvAcctRulesList.add(sinvacctRule3);
            
            Accounting_Rule__c sinvacctRule4 = new Accounting_Rule__c();
            sinvacctRule4.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule4.company__c = myComp;
            sinvacctRule4.Transaction__c = 'Supplier Invoice';
            sinvacctRule4.SubTransaction_Type__c = 'Purchase Price Variance';
            //sinvacctRule4.Segment_Name__c = 'GL_Account__c';
            sinvacctRule4.Rule_Type__c = 'DR';
            //sinvacctRule4.Criteria__c = 'Accounting Default';
            sinvacctRule4.Default_GL_Account__c = true;
            sinvacctRule4.GL_Account_Reference_Value__c = null;
            sinvacctRule4.GL_Account__c = PPVGL.id;
            SuppInvAcctRulesList.add(sinvacctRule4);
            
            Accounting_Rule__c sinvacctRule5 = new Accounting_Rule__c();
            sinvacctRule5.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule5.company__c = myComp;
            sinvacctRule5.Transaction__c = 'Supplier Invoice';
            sinvacctRule5.SubTransaction_Type__c = 'Goods';
            sinvacctRule5.Rule_Type__c = 'CR';
            sinvacctRule5.Default_GL_Account__c = true;
            sinvacctRule5.GL_Account_Reference_Value__c = null;
            sinvacctRule5.GL_Account__c = IPVGL.id;
            SuppInvAcctRulesList.add(sinvacctRule5);
            
            Accounting_Rule__c sinvacctRule6 = new Accounting_Rule__c();
            sinvacctRule6.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule6.company__c = myComp;
            sinvacctRule6.Transaction__c = 'Supplier Invoice';
            sinvacctRule6.SubTransaction_Type__c = 'Goods';
            sinvacctRule6.Rule_Type__c = 'DR';
            sinvacctRule6.Default_GL_Account__c = true;
            sinvacctRule6.GL_Account_Reference_Value__c = null;
            sinvacctRule6.GL_Account__c = IPVGL.id;            
            SuppInvAcctRulesList.add(sinvacctRule6);
            */
            
            
            Accounting_Rule__c sinvacctRule7 = new Accounting_Rule__c();
            sinvacctRule7.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule7.company__c = myComp;
            sinvacctRule7.Transaction__c = 'Supplier Invoice';
            sinvacctRule7.SubTransaction_Type__c = 'Expense';
            //sinvacctRule7.Segment_Name__c = 'GL_Account__c';
            sinvacctRule7.Rule_Type__c = 'CR';
            //sinvacctRule7.Criteria__c = 'Item Class';
            sinvacctRule7.Default_GL_Account__c = false;
            sinvacctRule7.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            sinvacctRule7.GL_Account__c = null;            
            SuppInvAcctRulesList.add(sinvacctRule7);
            
            Accounting_Rule__c sinvacctRule8 = new Accounting_Rule__c();
            sinvacctRule8.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule8.company__c = myComp;
            sinvacctRule8.Transaction__c = 'Supplier Invoice';
            sinvacctRule8.SubTransaction_Type__c = 'Expense';
            //sinvacctRule8.Segment_Name__c = 'GL_Account__c';
            sinvacctRule8.Rule_Type__c = 'DR';
            //sinvacctRule8.Criteria__c = 'Accounting Default';
            sinvacctRule8.Default_GL_Account__c = true;
            sinvacctRule8.GL_Account_Reference_Value__c = null;
            sinvacctRule8.GL_Account__c = GRNIGL.id;            
            SuppInvAcctRulesList.add(sinvacctRule8);
            

            Accounting_Rule__c sinvacctRule7a = new Accounting_Rule__c();
            sinvacctRule7a.Object__c = 'Supplier Invoice';
            sinvacctRule7a.company__c = myComp;
            sinvacctRule7a.Transaction__c = 'Invoice';
            sinvacctRule7a.SubTransaction_Type__c = 'Miscellaneous - Purchase Order';
            //sinvacctRule7.Segment_Name__c = 'GL_Account__c';
            sinvacctRule7a.Rule_Type__c = 'CR';
            //sinvacctRule7.Criteria__c = 'Item Class';
            sinvacctRule7a.Default_GL_Account__c = false;
            sinvacctRule7a.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            sinvacctRule7a.GL_Account__c = null;            
            SuppInvAcctRulesList.add(sinvacctRule7a);
            
            Accounting_Rule__c sinvacctRule8a = new Accounting_Rule__c();
            sinvacctRule8a.Object__c = 'Supplier Invoice';
            sinvacctRule8a.company__c = myComp;
            sinvacctRule8a.Transaction__c = 'Invoice';
            sinvacctRule8a.SubTransaction_Type__c = 'Miscellaneous - Purchase Order';
            //sinvacctRule8.Segment_Name__c = 'GL_Account__c';
            sinvacctRule8a.Rule_Type__c = 'DR';
            //sinvacctRule8.Criteria__c = 'Accounting Default';
            sinvacctRule8a.Default_GL_Account__c = true;
            sinvacctRule8a.GL_Account_Reference_Value__c = null;
            sinvacctRule8a.GL_Account__c = GRNIGL.id;            
            SuppInvAcctRulesList.add(sinvacctRule8a);


            Accounting_Rule__c sinvacctRule9 = new Accounting_Rule__c();
            sinvacctRule9.Object__c = 'Supplier Invoice';
            sinvacctRule9.company__c = myComp;
            sinvacctRule9.Transaction__c = 'Invoice';
            sinvacctRule9.SubTransaction_Type__c = 'Miscellaneous';
            //sinvacctRule9.Segment_Name__c = 'GL_Account__c';
            sinvacctRule9.Rule_Type__c = 'CR';
            //sinvacctRule9.Criteria__c = 'Item Class';
            sinvacctRule9.Default_GL_Account__c = false;
            sinvacctRule9.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            sinvacctRule9.GL_Account__c = null;            
            SuppInvAcctRulesList.add(sinvacctRule9);
            
            Accounting_Rule__c sinvacctRule10 = new Accounting_Rule__c();
            sinvacctRule10.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule10.company__c = myComp;
            sinvacctRule10.Transaction__c = 'Supplier Invoice';
            sinvacctRule10.SubTransaction_Type__c = 'Miscellaneous';
            //sinvacctRule10.Segment_Name__c = 'GL_Account__c';
            sinvacctRule10.Rule_Type__c = 'DR';
            //sinvacctRule10.Criteria__c = 'Accounting Default';
            sinvacctRule10.Default_GL_Account__c = true;
            sinvacctRule10.GL_Account_Reference_Value__c = null;
            sinvacctRule10.GL_Account__c = GRNIGL.id;            
            SuppInvAcctRulesList.add(sinvacctRule10);
                
            Accounting_Rule__c sinvacctRule31 = new Accounting_Rule__c();
            sinvacctRule31.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule31.company__c = myComp;
            sinvacctRule31.Transaction__c = 'Supplier Invoice';
            sinvacctRule31.SubTransaction_Type__c = null;
            sinvacctRule31.Rule_Type__c = 'CR';
            sinvacctRule31.Default_GL_Account__c = false;
            sinvacctRule31.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            sinvacctRule31.GL_Account__c = null;            
            SuppInvAcctRulesList.add(sinvacctRule31);
            
            Accounting_Rule__c sinvacctRule32 = new Accounting_Rule__c();
            sinvacctRule32.Object_Name__c = 'Supplier_Invoice__c';
            sinvacctRule32.company__c = myComp;
            sinvacctRule32.Transaction__c = 'Supplier Invoice';
            sinvacctRule32.SubTransaction_Type__c = null;
            sinvacctRule32.Rule_Type__c = 'DR';
            sinvacctRule32.Default_GL_Account__c = true;
            sinvacctRule32.GL_Account_Reference_Value__c = null;
            sinvacctRule32.GL_Account__c = GRNIGL.id;            
            SuppInvAcctRulesList.add(sinvacctRule32);
                
            rules.addAll(SuppInvAcctRulesList);    
            //insert SuppInvAcctRulesList;
     
        }
        
        public List<Accounting_Rule__c> SuppCMAcctRulesList = new List<Accounting_Rule__c>();
        public void updateSuppCMRules(){
            Accounting_Rule__c scmacctRule1 = new Accounting_Rule__c();
            scmacctRule1.Object_Name__c = 'Supplier_Invoice__c';
            scmacctRule1.company__c = myComp;
            scmacctRule1.Transaction__c = 'Supplier Credit Memo';
            scmacctRule1.SubTransaction_Type__c = 'Invoice';
            //scmacctRule1.Segment_Name__c = 'GL_Account__c';
            scmacctRule1.Rule_Type__c = 'CR';
            //scmacctRule1.Criteria__c = 'Accounting Default';
            scmacctRule1.Default_GL_Account__c = false;
            scmacctRule1.GL_Account_Reference_Value__c = 'Accounting_Segment__r.GL_Account__c';
            scmacctRule1.GL_Account__c = payablesGL.id;
            SuppCMAcctRulesList.add(scmacctRule1);
            
            Accounting_Rule__c scmacctRule2 = new Accounting_Rule__c();
            scmacctRule2.Object_Name__c = 'Supplier_Invoice__c';
            scmacctRule2.company__c = myComp;
            scmacctRule2.Transaction__c = 'Supplier Credit Memo';
            scmacctRule2.SubTransaction_Type__c = 'Invoice';
            //scmacctRule2.Segment_Name__c = 'GL_Account__c';
            scmacctRule2.Rule_Type__c = 'DR';
            //scmacctRule2.Criteria__c = 'Accounting Default';
            scmacctRule2.Default_GL_Account__c = true;
            scmacctRule2.GL_Account_Reference_Value__c = null;
            scmacctRule2.GL_Account__c = payablesGL.id;
            SuppCMAcctRulesList.add(scmacctRule2);
            
            Accounting_Rule__c scmacctRule3 = new Accounting_Rule__c();
            scmacctRule3.Object_Name__c = 'Supplier_Invoice__c';
            scmacctRule3.company__c = myComp;
            scmacctRule3.Transaction__c = 'Supplier Credit Memo';
            scmacctRule3.SubTransaction_Type__c = 'On Account';
            //scmacctRule3.Segment_Name__c = 'GL_Account__c';
            scmacctRule3.Rule_Type__c = 'CR';
            //scmacctRule3.Criteria__c = 'Accounting Default';
            scmacctRule3.Default_GL_Account__c = false;
            scmacctRule3.GL_Account_Reference_Value__c = 'Accounting_Segment__r.GL_Account__c';
            scmacctRule3.GL_Account__c = payablesGL.id;
            SuppCMAcctRulesList.add(scmacctRule3);
            
            Accounting_Rule__c scmacctRule4 = new Accounting_Rule__c();
            scmacctRule4.Object_Name__c = 'Supplier_Invoice__c';
            scmacctRule4.company__c = myComp;
            scmacctRule4.Transaction__c = 'Supplier Credit Memo';
            scmacctRule4.SubTransaction_Type__c = 'On Account';
            //scmacctRule4.Segment_Name__c = 'GL_Account__c';
            scmacctRule4.Rule_Type__c = 'DR';
            //scmacctRule4.Criteria__c = 'Accounting Default';
            scmacctRule4.Default_GL_Account__c = true;
            scmacctRule4.GL_Account_Reference_Value__c = 'Accounting_Segment__r.GL_Account__c';
            scmacctRule4.GL_Account__c = payablesGL.id;
            SuppCMAcctRulesList.add(scmacctRule4);
            
            Accounting_Rule__c scmacctRule5 = new Accounting_Rule__c();
            scmacctRule5.Object_Name__c = 'Supplier_Invoice__c';
            scmacctRule5.company__c = myComp;
            scmacctRule5.Transaction__c = 'Credit Memo';
            scmacctRule5.SubTransaction_Type__c = null;
            scmacctRule5.Rule_Type__c = 'CR';
            scmacctRule5.Default_GL_Account__c = false;
            scmacctRule5.GL_Account_Reference_Value__c = 'Accounting_Segment__r.GL_Account__c';
            scmacctRule5.GL_Account__c = payablesGL.id;
            SuppCMAcctRulesList.add(scmacctRule5);
            
            Accounting_Rule__c scmacctRule6 = new Accounting_Rule__c();
            scmacctRule6.Object_Name__c = 'Supplier_Invoice__c';
            scmacctRule6.company__c = myComp;
            scmacctRule6.Transaction__c = 'Credit Memo';
            scmacctRule6.SubTransaction_Type__c = null;
            scmacctRule6.Rule_Type__c = 'DR';
            scmacctRule6.Default_GL_Account__c = true;
            scmacctRule6.GL_Account_Reference_Value__c = 'Accounting_Segment__r.GL_Account__c';
            scmacctRule6.GL_Account__c = payablesGL.id;
            SuppCMAcctRulesList.add(scmacctRule6);
            
            rules.addAll(SuppCMAcctRulesList);    
            //insert SuppCMAcctRulesList;
        }
    
        public List<Accounting_Rule__c> SuppPaymentAcctRulesList = new List<Accounting_Rule__c>();
        public void updateSupplierPmtRules(){
    
            Accounting_Rule__c suppayacctRule1 = new Accounting_Rule__c();
            suppayacctRule1.Object_Name__c = 'Supplier_Payment__c';
            suppayacctRule1.company__c = myComp;
            suppayacctRule1.Transaction__c = 'Supplier Payment';
            suppayacctRule1.SubTransaction_Type__c = 'Payment';
            //suppayacctRule1.Segment_Name__c = 'GL_Account__c';
            suppayacctRule1.Rule_Type__c = 'DR';
            //suppayacctRule1.Criteria__c = 'Accounting Default';
            suppayacctRule1.Default_GL_Account__c = true;
            suppayacctRule1.GL_Account_Reference_Value__c = null;
            suppayacctRule1.GL_Account__c = payablesGL.id;
            suppayacctRule1.Amount_Reference__c = null;            
            SuppPaymentAcctRulesList.add(suppayacctRule1);
            
            Accounting_Rule__c suppayacctRule2 = new Accounting_Rule__c();
            suppayacctRule2.Object_Name__c = 'Supplier_Payment__c';
            suppayacctRule2.company__c = myComp;
            suppayacctRule2.Transaction__c = 'Supplier Payment';
            suppayacctRule2.SubTransaction_Type__c = 'Payment';
            //suppayacctRule2.Segment_Name__c = 'GL_Account__c';
            suppayacctRule2.Rule_Type__c = 'CR';
            //suppayacctRule2.Criteria__c = 'Bank Account';
            suppayacctRule2.Default_GL_Account__c = false;
            suppayacctRule2.GL_Account_Reference_Value__c = 'Supplier_Payment__r.Bank_Account__r.GL_Account__c';
            suppayacctRule2.GL_Account__c = null;
            suppayacctRule2.Amount_Reference__c = null;                
            SuppPaymentAcctRulesList.add(suppayacctRule2);
            
            Accounting_Rule__c suppayacctRule3 = new Accounting_Rule__c();
            suppayacctRule3.Object_Name__c = 'Supplier_Payment__c';
            suppayacctRule3.company__c = myComp;
            suppayacctRule3.Transaction__c = 'Supplier Payment';
            suppayacctRule3.SubTransaction_Type__c = 'Earned Terms Discount';
            //suppayacctRule3.Segment_Name__c = 'GL_Account__c';
            suppayacctRule3.Rule_Type__c = 'CR';
            //suppayacctRule3.Criteria__c = 'Accounting Default';
            suppayacctRule3.Default_GL_Account__c = true;
            suppayacctRule3.GL_Account_Reference_Value__c = null;
            suppayacctRule3.GL_Account__c = payablesGL.id;
            suppayacctRule3.Amount_Reference__c = null;                
            SuppPaymentAcctRulesList.add(suppayacctRule3);
            
            Accounting_Rule__c suppayacctRule4 = new Accounting_Rule__c();
            suppayacctRule4.Object_Name__c = 'Supplier_Payment__c';
            suppayacctRule4.company__c = myComp;
            suppayacctRule4.Transaction__c = 'Supplier Payment';
            suppayacctRule4.SubTransaction_Type__c = 'Earned Terms Discount';
            //suppayacctRule4.Segment_Name__c = 'GL_Account__c';
            suppayacctRule4.Rule_Type__c = 'DR';
            //suppayacctRule4.Criteria__c = 'Accounting Default';
            suppayacctRule4.Default_GL_Account__c = true;
            suppayacctRule4.GL_Account_Reference_Value__c = null;
            suppayacctRule4.GL_Account__c = payablesGL.id;
            suppayacctRule4.Amount_Reference__c = null;                
            SuppPaymentAcctRulesList.add(suppayacctRule4);
            
            Accounting_Rule__c suppayacctRule5 = new Accounting_Rule__c();
            suppayacctRule5.Object_Name__c = 'Supplier_Payment__c';
            suppayacctRule5.Transaction__c = 'Supplier Payment';
            suppayacctRule5.SubTransaction_Type__c = 'Prepayment';
            suppayacctRule5.Rule_Type__c = 'CR';
            suppayacctRule5.Default_GL_Account__c = true;
            suppayacctRule5.GL_Account_Reference_Value__c = null;
            suppayacctRule5.GL_Account__c = payablesGL.id;
            suppayacctRule5.Amount_Reference__c = null;                
            suppayacctRule5.Company_Ledger__c = true;                
            SuppPaymentAcctRulesList.add(suppayacctRule5);
                
            Accounting_Rule__c suppayacctRule6 = new Accounting_Rule__c();
            suppayacctRule6.Object_Name__c = 'Supplier_Payment__c';
            suppayacctRule6.Transaction__c = 'Supplier Payment';
            suppayacctRule6.SubTransaction_Type__c = 'Prepayment';
            suppayacctRule6.Rule_Type__c = 'DR';
            suppayacctRule6.Default_GL_Account__c = true;
            suppayacctRule6.GL_Account_Reference_Value__c = null;
            suppayacctRule6.GL_Account__c = payablesGL.id;
            suppayacctRule6.Amount_Reference__c = null;                
            suppayacctRule6.Company_Ledger__c = true;             
            SuppPaymentAcctRulesList.add(suppayacctRule6);
            
            rules.addAll(SuppPaymentAcctRulesList);
            //insert SuppPaymentAcctRulesList;
        }
     
        public List<Accounting_Rule__c> InventoryChangeAcctRulesList = new List<Accounting_Rule__c>();
        public void updateInvChangeRules(){
            Accounting_Rule__c invchgacctRule1 = new Accounting_Rule__c();
            invchgacctRule1.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule1.company__c = myComp;
            invchgacctRule1.Transaction__c = 'Cycle Count';
            invchgacctRule1.SubTransaction_Type__c = 'Cycle Count';
            invchgacctRule1.Line_type__c = null;
            //invchgacctRule1.Segment_Name__c = 'GL_Account__c';
            invchgacctRule1.Rule_Type__c = 'CR';
            //invchgacctRule1.Criteria__c = 'Item Class';
            invchgacctRule1.Default_GL_Account__c = true;
            invchgacctRule1.GL_Account_Reference_Value__c = null;
            invchgacctRule1.GL_Account__c = InventoryAdjustmentGL.id;
            invchgacctRule1.Amount_Reference__c = null;            
            InventoryChangeAcctRulesList.add(invchgacctRule1);
            
            Accounting_Rule__c invchgacctRule2 = new Accounting_Rule__c();
            invchgacctRule2.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule2.company__c = myComp;
            invchgacctRule2.Transaction__c = 'Cycle Count';
            invchgacctRule2.SubTransaction_Type__c = 'Cycle Count';
            invchgacctRule2.Line_type__c = null;
            //invchgacctRule2.Segment_Name__c = 'GL_Account__c';
            invchgacctRule2.Rule_Type__c = 'DR';
            //invchgacctRule2.Criteria__c = 'Accounting Default'; 
            invchgacctRule2.Default_GL_Account__c = true;
            invchgacctRule2.GL_Account_Reference_Value__c = null; //'Item__r.class__r.Inventory_GL_Account__c';
            invchgacctRule2.GL_Account__c = inventoryGL.id;
            invchgacctRule2.Amount_Reference__c = null;               
            InventoryChangeAcctRulesList.add(invchgacctRule2);
            
            Accounting_Rule__c invchgacctRule3 = new Accounting_Rule__c();
            invchgacctRule3.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule3.company__c = myComp;
            invchgacctRule3.Transaction__c = 'Adjustment';
            invchgacctRule3.SubTransaction_Type__c = 'Adjustment Increase';
            invchgacctRule3.Line_Type__c = null;
            //invchgacctRule3.Segment_Name__c = 'GL_Account__c';
            invchgacctRule3.Rule_Type__c = 'CR';
            //invchgacctRule3.Criteria__c = 'Item Class';
            invchgacctRule3.Default_GL_Account__c = true;
            invchgacctRule3.GL_Account_Reference_Value__c = null; //'Item__r.class__r.Inventory_GL_Account__c';
            invchgacctRule3.GL_Account__c = InventoryAdjustmentGL.id;
            invchgacctRule3.Amount_Reference__c = null;               
            InventoryChangeAcctRulesList.add(invchgacctRule3);
            
            Accounting_Rule__c invchgacctRule4 = new Accounting_Rule__c();
            invchgacctRule4.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule4.company__c = myComp;
            invchgacctRule4.Transaction__c = 'Adjustment';
            invchgacctRule4.SubTransaction_Type__c = 'Adjustment Increase';
            invchgacctRule4.Line_Type__c = null;
            //invchgacctRule4.Segment_Name__c = 'GL_Account__c';
            invchgacctRule4.Rule_Type__c = 'DR';
            //invchgacctRule4.Criteria__c = 'Accounting Default'; 
            invchgacctRule4.Default_GL_Account__c = true;
            invchgacctRule4.GL_Account_Reference_Value__c = null;
            invchgacctRule4.GL_Account__c = inventoryGL.id;
            invchgacctRule4.Amount_Reference__c = null;               
            InventoryChangeAcctRulesList.add(invchgacctRule4);
            
            Accounting_Rule__c invchgacctRule5 = new Accounting_Rule__c();
            invchgacctRule5.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule5.company__c = myComp;
            invchgacctRule5.Transaction__c = 'Cycle Count';
            invchgacctRule5.SubTransaction_Type__c = 'Cycle Count';
            invchgacctRule5.Line_type__c = 'Decrease';
            //invchgacctRule5.Segment_Name__c = 'GL_Account__c';
            invchgacctRule5.Rule_Type__c = 'CR';
            //invchgacctRule5.Criteria__c = 'Item Class';
            invchgacctRule5.Default_GL_Account__c = true;
            invchgacctRule5.GL_Account_Reference_Value__c = null;
            invchgacctRule5.GL_Account__c = InventoryAdjustmentGL.id;
            invchgacctRule5.Amount_Reference__c = null;               
            InventoryChangeAcctRulesList.add(invchgacctRule5);
            
            Accounting_Rule__c invchgacctRule6 = new Accounting_Rule__c();
            invchgacctRule6.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule6.company__c = myComp;
            invchgacctRule6.Transaction__c = 'Cycle Count';
            invchgacctRule6.SubTransaction_Type__c = 'Cycle Count';
            invchgacctRule6.Line_type__c = 'Decrease';
            //invchgacctRule6.Segment_Name__c = 'GL_Account__c';
            invchgacctRule6.Rule_Type__c = 'DR';
            //invchgacctRule6.Criteria__c = 'Accounting Default'; 
            invchgacctRule6.Default_GL_Account__c = true;
            invchgacctRule6.GL_Account_Reference_Value__c = null; //'Item__r.class__r.Inventory_GL_Account__c';
            invchgacctRule6.GL_Account__c = inventoryGL.id;
            invchgacctRule6.Amount_Reference__c = null;               
            InventoryChangeAcctRulesList.add(invchgacctRule6);
            
            Accounting_Rule__c invchgacctRule7 = new Accounting_Rule__c();
            invchgacctRule7.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule7.company__c = myComp;
            invchgacctRule7.Transaction__c = 'Adjustment';
            invchgacctRule7.SubTransaction_Type__c = 'Adjustment Decrease';
            invchgacctRule7.Line_Type__c = null;
            //invchgacctRule7.Segment_Name__c = 'GL_Account__c';
            invchgacctRule7.Rule_Type__c = 'CR';
            //invchgacctRule7.Criteria__c = 'Item Class';
            invchgacctRule7.Default_GL_Account__c = true;
            invchgacctRule7.GL_Account_Reference_Value__c = null; //'Item__r.class__r.Inventory_GL_Account__c';
            invchgacctRule7.GL_Account__c = InventoryAdjustmentGL.id;
            invchgacctRule7.Amount_Reference__c = null; 
            InventoryChangeAcctRulesList.add(invchgacctRule7);
            
            Accounting_Rule__c invchgacctRule8 = new Accounting_Rule__c();
            invchgacctRule8.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule8.company__c = myComp;
            invchgacctRule8.Transaction__c = 'Adjustment';
            invchgacctRule8.SubTransaction_Type__c = 'Adjustment Decrease';
            invchgacctRule8.Line_Type__c = null;
            //invchgacctRule8.Segment_Name__c = 'GL_Account__c';
            invchgacctRule8.Rule_Type__c = 'DR';
            //invchgacctRule8.Criteria__c = 'Accounting Default'; 
            invchgacctRule8.Default_GL_Account__c = true;
            invchgacctRule8.GL_Account_Reference_Value__c = null;
            invchgacctRule8.GL_Account__c = inventoryGL.id;
            invchgacctRule8.Amount_Reference__c = null;               
            InventoryChangeAcctRulesList.add(invchgacctRule8);
            
            Accounting_Rule__c invchgacctRule9 = new Accounting_Rule__c();
            invchgacctRule9.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule9.company__c = myComp;
            invchgacctRule9.Transaction__c = 'Transfer';
            invchgacctRule9.SubTransaction_Type__c = 'Transfer';
            invchgacctRule9.Line_Type__c = 'Increase';
            //invchgacctRule9.Segment_Name__c = 'GL_Account__c';
            invchgacctRule9.Rule_Type__c = 'CR';
            //invchgacctRule9.Criteria__c = 'Item Class';
            invchgacctRule9.Default_GL_Account__c = true;
            invchgacctRule9.GL_Account_Reference_Value__c = null; //'Item__r.class__r.Inventory_GL_Account__c';
            invchgacctRule9.GL_Account__c = InventoryAdjustmentGL.id;
            invchgacctRule9.Amount_Reference__c = null;               
            InventoryChangeAcctRulesList.add(invchgacctRule9);
            
            Accounting_Rule__c invchgacctRule10 = new Accounting_Rule__c();
            invchgacctRule10.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule10.company__c = myComp;
            invchgacctRule10.Transaction__c = 'Transfer';
            invchgacctRule10.SubTransaction_Type__c = 'Transfer';
            invchgacctRule10.Line_Type__c = 'Increase';
            //invchgacctRule10.Segment_Name__c = 'GL_Account__c';
            invchgacctRule10.Rule_Type__c = 'DR';
            //invchgacctRule10.Criteria__c = 'Accounting Default'; 
            invchgacctRule10.Default_GL_Account__c = true;
            invchgacctRule10.GL_Account_Reference_Value__c = null;
            invchgacctRule10.GL_Account__c = inventoryGL.id;
            invchgacctRule10.Amount_Reference__c = null;               
            InventoryChangeAcctRulesList.add(invchgacctRule10);
            
            Accounting_Rule__c invchgacctRule11 = new Accounting_Rule__c();
            invchgacctRule11.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule11.company__c = myComp;
            invchgacctRule11.Transaction__c = 'Transfer';
            invchgacctRule11.SubTransaction_Type__c = 'Transfer';
            invchgacctRule11.Line_Type__c = 'Decrease';
            //invchgacctRule11.Segment_Name__c = 'GL_Account__c';
            invchgacctRule11.Rule_Type__c = 'CR';
            //invchgacctRule11.Criteria__c = 'Item Class';
            invchgacctRule11.Default_GL_Account__c = true;
            invchgacctRule11.GL_Account_Reference_Value__c = null; //'Item__r.class__r.Inventory_GL_Account__c';
            invchgacctRule11.GL_Account__c = inventoryGL.id;
            invchgacctRule11.Amount_Reference__c = null;               
            InventoryChangeAcctRulesList.add(invchgacctRule11);
            
            Accounting_Rule__c invchgacctRule12 = new Accounting_Rule__c();
            invchgacctRule12.Object_Name__c = 'Inventory_Change__c';
            invchgacctRule12.company__c = myComp;
            invchgacctRule12.Transaction__c = 'Transfer';
            invchgacctRule12.SubTransaction_Type__c = 'Transfer';
            invchgacctRule12.Line_Type__c = 'Decrease';
            //invchgacctRule12.Segment_Name__c = 'GL_Account__c';
            invchgacctRule12.Rule_Type__c = 'DR';
            //invchgacctRule12.Criteria__c = 'Accounting Default'; 
            invchgacctRule12.Default_GL_Account__c = true;
            invchgacctRule12.GL_Account_Reference_Value__c = null;
            invchgacctRule12.GL_Account__c = InventoryAdjustmentGL.id;
            invchgacctRule12.Amount_Reference__c = null;               
            InventoryChangeAcctRulesList.add(invchgacctRule12);
            
            
            
            rules.addAll(InventoryChangeAcctRulesList);    
            //insert InventoryChangeAcctRulesList;
           
        }
    
        public List<Accounting_Rule__c> WorkOrderAcctRulesList = new List<Accounting_Rule__c>();
        public void updateWorkOrderRules(){
            Accounting_Rule__c woacctRule1 = new Accounting_Rule__c();
            woacctRule1.Object_Name__c = 'Work_Order__c';
            woacctRule1.company__c = myComp;
            woacctRule1.Transaction__c = 'Work Order';
            woacctRule1.SubTransaction_Type__c = 'Work Order Assembly Completion';
            woacctRule1.Line_type__c = 'Material Cost';
            woacctRule1.Rule_Type__c = 'CR';
            woacctRule1.Default_GL_Account__c = true;
            woacctRule1.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule1);
            
            Accounting_Rule__c woacctRule2 = new Accounting_Rule__c();
            woacctRule2.Object_Name__c = 'Work_Order__c';
            woacctRule2.company__c = myComp;
            woacctRule2.Transaction__c = 'Work Order';
            woacctRule2.SubTransaction_Type__c = 'Work Order Assembly Completion';
            woacctRule2.Line_type__c = 'Labor Cost';
            woacctRule2.Rule_Type__c = 'CR';
            woacctRule2.Default_GL_Account__c = true;
            woacctRule2.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule2);
            
            Accounting_Rule__c woacctRule3 = new Accounting_Rule__c();
            woacctRule3.Object_Name__c = 'Work_Order__c';
            woacctRule3.company__c = myComp;
            woacctRule3.Transaction__c = 'Work Order';
            woacctRule3.SubTransaction_Type__c = 'Work Order Assembly Completion';
            woacctRule3.Line_type__c = 'Overhead Cost';
            woacctRule3.Rule_Type__c = 'CR';
            woacctRule3.Default_GL_Account__c = true;
            woacctRule3.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule3);
            
            Accounting_Rule__c woacctRule4 = new Accounting_Rule__c();
            woacctRule4.Object_Name__c = 'Work_Order__c';
            woacctRule4.company__c = myComp;
            woacctRule4.Transaction__c = 'Work Order';
            woacctRule4.SubTransaction_Type__c = 'Work Order Assembly Completion';
            woacctRule4.Line_type__c = 'Outside Processing Cost';
            woacctRule4.Rule_Type__c = 'CR';
            woacctRule4.Default_GL_Account__c = true;
            woacctRule4.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule4);
            
            Accounting_Rule__c woacctRule5 = new Accounting_Rule__c();
            woacctRule5.Object_Name__c = 'Work_Order__c';
            woacctRule5.company__c = myComp;
            woacctRule5.Transaction__c = 'Work Order';
            woacctRule5.SubTransaction_Type__c = 'Work Order Assembly Completion';
            woacctRule5.Line_type__c = 'Material';
            woacctRule5.Rule_Type__c = 'DR';
            woacctRule5.Default_GL_Account__c = true;
            woacctRule5.GL_Account__c = FGInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule5);    
            
            //--------
            
            Accounting_Rule__c woacctRule6 = new Accounting_Rule__c();
            woacctRule6.Object_Name__c = 'Work_Order__c';
            woacctRule6.company__c = myComp;
            woacctRule6.Transaction__c = 'Work Order';
            woacctRule6.SubTransaction_Type__c = 'Work Order Assembly Uncompletion';
            woacctRule6.Line_type__c = 'Material Cost';
            woacctRule6.Rule_Type__c = 'DR';
            woacctRule6.Default_GL_Account__c = true;
            woacctRule6.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule6);
            
            Accounting_Rule__c woacctRule7 = new Accounting_Rule__c();
            woacctRule7.Object_Name__c = 'Work_Order__c';
            woacctRule7.company__c = myComp;
            woacctRule7.Transaction__c = 'Work Order';
            woacctRule7.SubTransaction_Type__c = 'Work Order Assembly Uncompletion';
            woacctRule7.Line_type__c = 'Labor Cost';
            woacctRule7.Rule_Type__c = 'DR';
            woacctRule7.Default_GL_Account__c = true;
            woacctRule7.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule7);
            
            Accounting_Rule__c woacctRule8 = new Accounting_Rule__c();
            woacctRule8.Object_Name__c = 'Work_Order__c';
            woacctRule8.company__c = myComp;
            woacctRule8.Transaction__c = 'Work Order';
            woacctRule8.SubTransaction_Type__c = 'Work Order Assembly Uncompletion';
            woacctRule8.Line_type__c = 'Overhead Cost';
            woacctRule8.Rule_Type__c = 'DR';
            woacctRule8.Default_GL_Account__c = true;
            woacctRule8.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule8);
            
            Accounting_Rule__c woacctRule9 = new Accounting_Rule__c();
            woacctRule9.Object_Name__c = 'Work_Order__c';
            woacctRule9.company__c = myComp;
            woacctRule9.Transaction__c = 'Work Order';
            woacctRule9.SubTransaction_Type__c = 'Work Order Assembly Uncompletion';
            woacctRule9.Line_type__c = 'Outside Processing Cost';
            woacctRule9.Rule_Type__c = 'DR';
            woacctRule9.Default_GL_Account__c = true;
            woacctRule9.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule9);
            
            Accounting_Rule__c woacctRule10 = new Accounting_Rule__c();
            woacctRule10.Object_Name__c = 'Work_Order__c';
            woacctRule10.company__c = myComp;
            woacctRule10.Transaction__c = 'Work Order';
            woacctRule10.SubTransaction_Type__c = 'Work Order Assembly Uncompletion';
            woacctRule10.Line_type__c = 'Material';
            woacctRule10.Rule_Type__c = 'CR';
            woacctRule10.Default_GL_Account__c = true;
            woacctRule10.GL_Account__c = FGInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule10);
            
            //--------
            
            Accounting_Rule__c woacctRule11 = new Accounting_Rule__c();
            woacctRule11.Object_Name__c = 'Work_Order__c';
            woacctRule11.company__c = myComp;
            woacctRule11.Transaction__c = 'Work Order';
            woacctRule11.SubTransaction_Type__c = 'Work Order Assembly Scrap';
            woacctRule11.Line_type__c = 'Material Cost';
            woacctRule11.Rule_Type__c = 'CR';
            woacctRule11.Default_GL_Account__c = true;
            woacctRule11.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule11);
            
            Accounting_Rule__c woacctRule12 = new Accounting_Rule__c();
            woacctRule12.Object_Name__c = 'Work_Order__c';
            woacctRule12.company__c = myComp;
            woacctRule12.Transaction__c = 'Work Order';
            woacctRule12.SubTransaction_Type__c = 'Work Order Assembly Scrap';
            woacctRule12.Line_type__c = 'Labor Cost';
            woacctRule12.Rule_Type__c = 'CR';
            woacctRule12.Default_GL_Account__c = true;
            woacctRule12.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule12);   
            
            Accounting_Rule__c woacctRule13 = new Accounting_Rule__c();
            woacctRule13.Object_Name__c = 'Work_Order__c';
            woacctRule13.company__c = myComp;
            woacctRule13.Transaction__c = 'Work Order';
            woacctRule13.SubTransaction_Type__c = 'Work Order Assembly Scrap';
            woacctRule13.Line_type__c = 'Overhead Cost';
            woacctRule13.Rule_Type__c = 'CR';
            woacctRule13.Default_GL_Account__c = true;
            woacctRule13.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule13);  
            
            Accounting_Rule__c woacctRule14 = new Accounting_Rule__c();
            woacctRule14.Object_Name__c = 'Work_Order__c';
            woacctRule14.company__c = myComp;
            woacctRule14.Transaction__c = 'Work Order';
            woacctRule14.SubTransaction_Type__c = 'Work Order Assembly Scrap';
            woacctRule14.Line_type__c = 'Outside Processing Cost';
            woacctRule14.Rule_Type__c = 'CR';
            woacctRule14.Default_GL_Account__c = true;
            woacctRule14.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule14);    
            
            Accounting_Rule__c woacctRule15 = new Accounting_Rule__c();
            woacctRule15.Object_Name__c = 'Work_Order__c';
            woacctRule15.company__c = myComp;
            woacctRule15.Transaction__c = 'Work Order';
            woacctRule15.SubTransaction_Type__c = 'Work Order Assembly Scrap';
            woacctRule15.Line_type__c = 'Material';
            woacctRule15.Rule_Type__c = 'DR';
            woacctRule15.Default_GL_Account__c = true;
            woacctRule15.GL_Account__c = inventoryScrapGL.id;
            WorkOrderAcctRulesList.add(woacctRule15);    
            
            //--------
            
            Accounting_Rule__c woacctRule16 = new Accounting_Rule__c();
            woacctRule16.Object_Name__c = 'Work_Order__c';
            woacctRule16.company__c = myComp;
            woacctRule16.Transaction__c = 'Work Order';
            woacctRule16.SubTransaction_Type__c = 'Work Order Component Issue';
            woacctRule16.Line_type__c = 'Material';
            woacctRule16.Rule_Type__c = 'DR';
            woacctRule16.Default_GL_Account__c = true;
            woacctRule16.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule16);
            
            Accounting_Rule__c woacctRule17 = new Accounting_Rule__c();
            woacctRule17.Object_Name__c = 'Work_Order__c';
            woacctRule17.company__c = myComp;
            woacctRule17.Transaction__c = 'Work Order';
            woacctRule17.SubTransaction_Type__c = 'Work Order Component Issue';
            woacctRule17.Line_type__c = 'Material';
            woacctRule17.Rule_Type__c = 'CR';
            woacctRule17.Default_GL_Account__c = true;
            woacctRule17.GL_Account__c = rawMaterialGL.id;
            WorkOrderAcctRulesList.add(woacctRule17);     
            
            
            
            //--------
            Accounting_Rule__c woacctRule18 = new Accounting_Rule__c();
            woacctRule18.Object_Name__c = 'Work_Order__c';
            woacctRule18.company__c = myComp;
            woacctRule18.Transaction__c = 'Work Order';
            woacctRule18.SubTransaction_Type__c = 'Work Order Component Return';
            woacctRule18.Line_type__c = 'Material';
            woacctRule18.Rule_Type__c = 'CR';
            woacctRule18.Default_GL_Account__c = true;
            woacctRule18.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule18);
            
            Accounting_Rule__c woacctRule19 = new Accounting_Rule__c();
            woacctRule19.Object_Name__c = 'Work_Order__c';
            woacctRule19.company__c = myComp;
            woacctRule19.Transaction__c = 'Work Order';
            woacctRule19.SubTransaction_Type__c = 'Work Order Component Return';
            woacctRule19.Line_type__c = 'Material';
            woacctRule19.Rule_Type__c = 'DR';
            woacctRule19.Default_GL_Account__c = true;
            woacctRule19.GL_Account__c = rawMaterialGL.id;
            WorkOrderAcctRulesList.add(woacctRule19);     
            
            
            
            //--------
            
            Accounting_Rule__c woacctRule20 = new Accounting_Rule__c();
            woacctRule20.Object_Name__c = 'Work_Order__c';
            woacctRule20.company__c = myComp;
            woacctRule20.Transaction__c = 'Work Order';
            woacctRule20.SubTransaction_Type__c = 'Work Order Component Scrap';
            woacctRule20.Line_type__c = 'Material';
            woacctRule20.Rule_Type__c = 'CR';
            woacctRule20.Default_GL_Account__c = true;
            woacctRule20.GL_Account__c = wipInventoryGL.id;
            WorkOrderAcctRulesList.add(woacctRule20);          
            
            Accounting_Rule__c woacctRule21 = new Accounting_Rule__c();
            woacctRule21.Object_Name__c = 'Work_Order__c';
            woacctRule21.company__c = myComp;
            woacctRule21.Transaction__c = 'Work Order';
            woacctRule21.SubTransaction_Type__c = 'Work Order Component Scrap';
            woacctRule21.Line_type__c = 'Material';
            woacctRule21.Rule_Type__c = 'DR';
            woacctRule21.Default_GL_Account__c = true;
            woacctRule21.GL_Account__c = inventoryScrapGL.id;
            WorkOrderAcctRulesList.add(woacctRule21);           
                
            rules.addAll(WorkOrderAcctRulesList);    
            //insert WorkOrderAcctRulesList;  
        }
        
        public List<Accounting_Rule__c> FixedAssetAcctRulesList = new List<Accounting_Rule__c>();
        public void updateFixedAssetRules(){
            Accounting_Rule__c arStdCR = new Accounting_Rule__c();
            arStdCR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
            arStdCR.company__c = myComp;
            arStdCR.transaction__c = 'Fixed Asset Depreciation';
            arStdCR.subtransaction_type__c = 'Standard';
            arStdCR.line_type__c = null;
            //arStdCR.criteria__c = 'Fixed Asset Depreciation';
            //arStdCR.segment_name__c = 'GL_Account__c';
            arStdCR.Rule_Type__c = 'CR';
            arStdCR.Default_GL_Account__c = false;
            arStdCR.GL_Account_reference_value__c = 'Fixed_Asset__r.GL_Account__c';
            arStdCR.GL_Account__c = null;
            FixedAssetAcctRulesList.add(arStdCR);
            
            Accounting_Rule__c arStdDR = new Accounting_Rule__c();
            arStdDR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
            arStdDR.company__c = myComp;
            arStdDR.transaction__c = 'Fixed Asset Depreciation';
            arStdDR.subtransaction_type__c = 'Standard';
            arStdDR.line_type__c = null;
            //arStdDR.criteria__c = 'Fixed Asset Depreciation';
            //arStdDR.segment_name__c = 'GL_Account__c';
            arStdDR.Rule_Type__c = 'DR';
            arStdDR.Default_GL_Account__c = true;
            arStdDR.GL_Account_reference_value__c = null;
            arStdDR.gl_account__c = accruedExpGL.Id;
            FixedAssetAcctRulesList.add(arStdDR);
            
            Accounting_Rule__c arDepCR = new Accounting_Rule__c();
            arDepCR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
            arDepCR.company__c = myComp;
            arDepCR.transaction__c = 'Fixed Asset Depreciation';
            arDepCR.subtransaction_type__c = 'Depreciation';
            arDepCR.line_type__c = null;
            //arDepCR.criteria__c = 'Fixed Asset Depreciation';
            //arDepCR.segment_name__c = 'GL_Account__c';
            arDepCR.Rule_Type__c = 'CR';
            arDepCR.Default_GL_Account__c = false;
            arDepCR.GL_Account_reference_value__c = 'Fixed_Asset__r.GL_Account__c';
            arDepCR.GL_Account__c = null;
            FixedAssetAcctRulesList.add(arDepCR);
            
            Accounting_Rule__c arDepDR = new Accounting_Rule__c();
            arDepDR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
            arDepDR.company__c = myComp;
            arDepDR.transaction__c = 'Fixed Asset Depreciation';
            arDepDR.subtransaction_type__c = 'Depreciation';
            arDepDR.line_type__c = null;
            //arDepDR.criteria__c = 'Fixed Asset Depreciation';
            //arDepDR.segment_name__c = 'GL_Account__c';
            arDepDR.Rule_Type__c = 'DR';
            arDepDR.Default_GL_Account__c = true;
            arDepDR.GL_Account_reference_value__c = null;
            arDepDR.gl_account__c = accruedExpGL.Id;
            FixedAssetAcctRulesList.add(arDepDR);
            
            Accounting_Rule__c arCIPCR = new Accounting_Rule__c();
            arCIPCR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
            arCIPCR.company__c = myComp;
            arCIPCR.transaction__c = 'Fixed Asset Depreciation';
            arCIPCR.subtransaction_type__c = 'Capitalize';
            arCIPCR.Line_Type__c = null;
            //arCIPCR.criteria__c = 'Fixed Asset Depreciation';
            //arCIPCR.segment_name__c = 'GL_Account__c';
            arCIPCR.Rule_Type__c = 'CR';
            arCIPCR.GL_Account_reference_value__c = 'Fixed_Asset__r.GL_Account__c';
            arCIPCR.GL_Account__c = null;
            FixedAssetAcctRulesList.add(arCIPCR);
            
            Accounting_Rule__c arCIPDR = new Accounting_Rule__c();
            arCIPDR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
            arCIPDR.company__c = myComp;
            arCIPDR.transaction__c = 'Fixed Asset Depreciation';
            arCIPDR.subtransaction_type__c = 'Capitalize';
            //arCIPDR.criteria__c = 'Fixed Asset Depreciation';
            //arCIPDR.segment_name__c = 'GL_Account__c';
            arCIPDR.Rule_Type__c = 'DR';
            arCIPDR.Default_Gl_Account__c = true;
            arCIPDR.GL_Account_Reference_Value__c = null;
            arCIPDR.GL_Account__c = cipGL.Id;
            FixedAssetAcctRulesList.add(arCIPDR);
            
            Accounting_Rule__c arWOCR = new Accounting_Rule__c();
            arWOCR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
            arWOCR.company__c = myComp;
            arWOCR.transaction__c = 'Fixed Asset Depreciation';
            arWOCR.subtransaction_type__c = 'Write Off';
            arWOCR.Line_Type__c = null;
            //arWOCR.criteria__c = 'Fixed Asset Depreciation';
            //arWOCR.segment_name__c = 'GL_Account__c';
            arWOCR.Rule_Type__c = 'CR';
            arWOCR.Default_GL_Account__c = false;
            arWOCR.GL_Account_reference_value__c = 'Fixed_Asset__r.GL_Account__c';
            arWOCR.GL_Account__c = null;
            FixedAssetAcctRulesList.add(arWOCR);
            
            Accounting_Rule__c arWODR = new Accounting_Rule__c();
            arWODR.Object_Name__c = 'Fixed_Asset_Depreciation__c';
            arWODR.company__c = myComp;
            arWODR.transaction__c = 'Fixed Asset Depreciation';
            arWODR.subtransaction_type__c = 'Write Off';
            arWODR.Line_Type__c = null;
            //arWODR.criteria__c = 'Fixed Asset Depreciation';
            //arWODR.segment_name__c = 'GL_Account__c';
            arWODR.Rule_Type__c = 'DR';
            arWODR.Default_GL_Account__c = true;
            arWODR.GL_Account_Reference_Value__c = null;
            arWODR.gl_account__c = writeOffGL.Id;
            FixedAssetAcctRulesList.add(arWODR);
            
            Accounting_Rule__c arAdjCR = new Accounting_Rule__c();
            arAdjCR.Object_Name__c = 'Fixed_Asset_Adjustment__c';
            arAdjCR.company__c = myComp;
            arAdjCR.transaction__c = 'Fixed Asset Adjustment';
            arAdjCR.subtransaction_type__c = 'Upgrade';
            arAdjCR.Line_Type__c = null;
            //arAdjCR.criteria__c = 'Fixed Asset Adjustment';
            //arAdjCR.segment_name__c = 'GL_Account__c';
            arAdjCR.Rule_Type__c = 'CR';
            arAdjCR.Default_GL_Account__c = false;
            arAdjCR.GL_Account_reference_value__c = 'Fixed_Asset__r.GL_Account__c';
            arAdjCR.GL_Account__c = null;
            FixedAssetAcctRulesList.add(arAdjCR);
            
            Accounting_Rule__c arAdjDR = new Accounting_Rule__c();
            arAdjDR.Object_Name__c = 'Fixed_Asset_Adjustment__c';
            arAdjDR.company__c = myComp;
            arAdjDR.transaction__c = 'Fixed Asset Adjustment';
            arAdjDR.subtransaction_type__c = 'Upgrade';
            arAdjDR.Line_Type__c = null;
            //arAdjDR.criteria__c = 'Fixed Asset Adjustment';
            //arAdjDR.segment_name__c = 'GL_Account__c';
            arAdjDR.Rule_Type__c = 'DR';
            arAdjDR.Default_GL_Account__c = true;
            arAdjDR.GL_Account_Reference_Value__c = null;
            arAdjDR.GL_Account__c = accruedExpGL.Id;
            FixedAssetAcctRulesList.add(arAdjDR);
            
            rules.addAll(FixedAssetAcctRulesList);    
            //insert FixedAssetAcctRulesList;
            
        }
        
        public List<Accounting_Rule__c> BankFileRulesList  = new List<Accounting_Rule__c>();
        //KNDY-10268 - deprecating bank file and bank file line objects
        /*public void updateBankFileRules(){
            
            Accounting_Rule__c arDebitDR = new Accounting_Rule__c();
            arDebitDR.Object_Name__c = 'Bank_File__c';
            arDebitDR.company__c = myComp;
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
            arDebitCR.company__c = myComp;
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
            arCreditDR.company__c = myComp;
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
            arCreditCR.company__c = myComp;
            arCreditCR.Transaction__c = 'Bank File';
            arCreditCR.Subtransaction_Type__c = 'Credit';
            arCreditCR.Line_Type__c = null;
            arCreditCR.Rule_Type__c = 'CR';
            arCreditCR.GL_Account__c = unappliedCashGL.Id;
            arCreditCR.Default_GL_Account__c = true;
            arCreditCR.GL_Account_Reference_Value__c = null;
            BankFileRulesList.add(arCreditCR);
            
            rules.addAll(BankFileRulesList);    
            //insert BankFileRulesList;
            
        } */
        
        public List<Accounting_Rule__c> PurchaseOrderRulesList  = new List<Accounting_Rule__c>();
        public void updatePurchaseOrderRules(){
            
            
            Accounting_Rule__c poRule1 = new Accounting_Rule__c();
            poRule1.Object_Name__c = 'Purchase_Order__c';
            poRule1.company__c = myComp;
            poRule1.Transaction__c = 'Standard';
            poRule1.SubTransaction_Type__c = 'Origin';
            //poRule1.Line_Type__c = 'Standard';
            poRule1.Rule_Type__c = 'CR';
            poRule1.Default_GL_Account__c = true;
            poRule1.GL_Account_Reference_Value__c = null;
            poRule1.GL_Account__c = GoodsInTransit.id;
            poRule1.Amount_Reference__c = null;            
            PurchaseOrderRulesList.add(poRule1);
            
            Accounting_Rule__c poRule2 = new Accounting_Rule__c();
            poRule2.Object_Name__c = 'Purchase_Order__c';
            poRule2.company__c = myComp;
            poRule2.Transaction__c = 'Standard';
            poRule2.SubTransaction_Type__c = 'Origin';
            //poRule2.Line_Type__c = 'Standard';
            poRule2.Rule_Type__c = 'DR';
            poRule2.Default_GL_Account__c = false;
            poRule2.GL_Account_Reference_Value__c = 'Item__r.Class__r.Inventory_GL_Account__c';
            poRule2.GL_Account__c = null;
            poRule2.Amount_Reference__c = null; 
            PurchaseOrderRulesList.add(poRule2);
            
            rules.addAll(PurchaseOrderRulesList);
        } 
        
            
        // Create Exchange Rates
        public List<Exchange_Rate__c> exchangeRateList=new List<Exchange_Rate__c>(); {
        
            Exchange_Rate__c exchangeRate1, exchangeRate2, exchangeRate3, exchangeRate4, exchangeRate5;
            exchangeRate1= new Exchange_Rate__c();
            exchangeRate1.Active__c = true;
            exchangeRate1.From_Currency__c = TestFuel.currencyUSD.id;
            exchangeRate1.To_Currency__c = TestFuel.currencySGD.Id;
            exchangeRate1.Daily_Monthly__c = 'Daily';
            exchangeRate1.Multiplier_Exchange_Rate__c = 1.250000;
            exchangeRate1.rate_start_datetime__c = system.now();
            exchangeRate1.rate_end_datetime__c = system.now() + 2;
            
        
            exchangeRateList.add(exchangeRate1);
        
            exchangeRate2= new Exchange_Rate__c();
            exchangeRate2.Active__c = true;
            exchangeRate2.From_Currency__c = TestFuel.currencySGD.Id;
            exchangeRate2.To_Currency__c = TestFuel.currencyGBP.Id;
            exchangeRate2.Daily_Monthly__c = 'Daily';
            exchangeRate2.Multiplier_Exchange_Rate__c = 0.470000;
            exchangeRate2.rate_start_datetime__c = system.now();
            exchangeRate2.rate_end_datetime__c = system.now() + 30;
        
            exchangeRateList.add(exchangeRate2);
        
            exchangeRate3= new Exchange_Rate__c();
            exchangeRate3.Active__c = true;
            exchangeRate3.From_Currency__c = TestFuel.currencySGD.Id;
            exchangeRate3.To_Currency__c = TestFuel.currencyEUR.Id;
            exchangeRate3.Daily_Monthly__c = 'Daily';
            exchangeRate3.Multiplier_Exchange_Rate__c = 0.580000;
            exchangeRate3.rate_start_datetime__c = system.now();
            exchangeRate3.rate_end_datetime__c = system.now() + 30;
        
            exchangeRateList.add(exchangeRate3);
        
            exchangeRate4= new Exchange_Rate__c();
            exchangeRate4.Active__c = true;
            exchangeRate4.From_Currency__c = TestFuel.currencySGD.Id;
            exchangeRate4.To_Currency__c = TestFuel.currencyUSD.Id;
            exchangeRate4.Daily_Monthly__c = 'Daily';
            exchangeRate4.Multiplier_Exchange_Rate__c = 0.800000;
            exchangeRate4.rate_start_datetime__c = system.now();
            exchangeRate4.rate_end_datetime__c = system.now() + 30;
        
            exchangeRateList.add(exchangeRate4);
            
            exchangeRate5= new Exchange_Rate__c();
            exchangeRate5.Active__c = true;
            exchangeRate5.From_Currency__c = TestFuel.currencyCAD.id;
            exchangeRate5.To_Currency__c = TestFuel.currencySGD.Id;
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
            Database.insert(exchangeRateList);
       }
   }
        
    public void TestDataGlobal()     {
        
        //uomObj.Name = 'EA';
        //uomObj.Description__c = 'Each';
        //insert uomObj;
     
        List<Account> account_list = new List<Account>(); 
        account = new Account();
        account.name = 'Kenandy';
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
        
        account_list.add (  account );
    
    
        billtoaccount = new Account();
        billtoaccount.name = 'Bill-to Account';
        billtoaccount.billingstreet = '123 Moscow St';
        billtoaccount.billingcity = 'San Francisco';
        billtoaccount.billingstate = 'CA';
        billtoaccount.billingpostalcode = '94112';
        billtoaccount.billingcountry = 'USA';
        billtoaccount.phone = '415-555-2000';
        billtoaccount.fax = '415-555-2010';
        account_list.add (  billtoaccount );
 
        shiptoaccount = new Account();
        shiptoaccount.name = 'Ship-to Account';
        shiptoaccount.billingstreet = '100 Deer St';
        shiptoaccount.billingcity = 'Tucson';
        shiptoaccount.billingstate = 'AZ';
        shiptoaccount.billingpostalcode = '94112';
        shiptoaccount.billingcountry = 'USA';
        shiptoaccount.phone = '520-555-5073';
        shiptoaccount.fax = '520-555-8913';
        account_list.add ( shiptoaccount );
    
    
        soldtoaccount = new Account();
        soldtoaccount.name = 'Sold-to Account';
        soldtoaccount.billingstreet = '1 Main St';
        soldtoaccount.billingcity = 'Burbank';
        soldtoaccount.billingstate = 'CA';
        soldtoaccount.billingpostalcode = '91505';
        soldtoaccount.phone = '714-555-1320';
        soldtoaccount.fax = '714-555-2110';
        account_list.add ( soldtoaccount );
      
        remittoaccount = new Account();
        remittoaccount.name = 'Remit-to Account';
        remittoaccount.billingstreet = '1 Boardwalk Dr';
        remittoaccount.billingcity = 'Santa Jose';
        remittoaccount.billingstate = 'CA';
        remittoaccount.billingpostalcode = '95205';
        remittoaccount.phone = '408-555-1965';
        remittoaccount.fax = '408-555-8341';
        account_list.add ( remittoaccount );
   
        insert account_list; 
       
    
        List<String> uoms = new List<String>{'LB', 'TN', 'DZ', 'OZ', 'MI', 'YD', 'IN', 'FT','EA'};
        List<String> uomdescs = new List<String>{'Pound', 'Ton', 'Dozen', 'Ounce', 'Mile', 'Yard', 'Inch', 'Foot','Each'};
        {
        for (Integer i = 0; i < uoms.size(); ++i) {
            UOM__c Obj = new UOM__c();
            Obj.Name = uoms[i];
            Obj.Description__c = uomdescs[i];
            uomList.add(Obj);
        }
        insert uomList;
        }
    
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
    
        insert uomcList;
    
        List<String> stockMovementRuleFields = new List<String>{'Class__c','Customer__c','Company__c','Facility__c','Item__c'};
        List<String> sourceDocuments = new List<String>{'Purchase Order', 'Sales Order', 'Work Order', 'Transfer Order', 'Receiving Document'};
        List<Stock_Movement_Rule_Settings__c> smrsList = new List<Stock_Movement_Rule_Settings__c>();
        
        for( String sourceDocument : sourceDocuments ){
            for( String stockMovementRuleField : stockMovementRuleFields ){
                
                if( !(stockMovementRuleField == 'Customer__c' && ( sourceDocument != 'Sales Order'))  ){
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
                    else if( sourceDocument == 'Work Order' && stockMovementRuleField == 'Class__c' ){
                        smrs.Source_Document_Path__c = 'Item__r.Class__c';
                    }
                    else if( sourceDocument == 'Work Order' && stockMovementRuleField == 'Facility__c' ){
                        smrs.Source_Document_Path__c = 'Work_Order__r.Facility__c';
                    }
                    else if( sourceDocument == 'Work Order' && stockMovementRuleField == 'Company__c' ){
                        smrs.Source_Document_Path__c = 'Work_Order__r.Company__c';
                    }
                    else{
                        smrs.Source_Document_Path__c = stockMovementRuleField;
                    }
                    
                    if( sourceDocument != 'Transfer Order'){
                        smrs.Source_Document_Path_Putaway__c = smrs.Source_Document_Path__c;
                    }
                    
                    smrsList.add(smrs);
                }
            }
        }
        insert smrsList;
        
        terms.name = '2/10 Net 30'; 
        terms.Description__c = '2% discount in 10 days, due 30 days';
        terms.Discount_Days__c = 10;
        terms.Discount_Percent__c = 2;
        terms.Due_Days__c = 30;
        insert terms; 
  
    
            
    
        /* 
         * and a few more from TextDataForFinance
         */
        acctData = new Accounting(company.id);
    
        clsObj.name = 'Class-1';
        clsObj.Inventory_GL_Account__c =acctData.inventoryGL.id;
        clsObj.Type__c= 'Goods';
    
        Class__c c2 = new Class__c( Name='Class Labor', Type__c = 'Labor' ); 
        Class__c c3 = new Class__c( Name='Class Services', Type__c = 'Services' );
        Class__c c4 = new Class__c( Name='Class Miscellaneous', Type__c = 'Miscellaneous' );
    
        insert new List<Class__c>{ clsObj, c2, c3, c4} ;
       
        itemAttrObj.Name = 'Attribute-1';
        itemAttrObj.Expiration_Date__c = true;
        itemAttrObj.Lot_Number__c = true;
        insert itemAttrObj;
    
        resObj.Name = 'res-cc';
        resObj.Description__c = 'Cycle Count Reason';
        resObj.Type__c = 'Cycle Count';
    
        Reason_Code__c r2 = new Reason_Code__c( Name = 'rec-ic', Description__c = 'Inventory Change Reason', Type__c = 'Inventory Change' );
    
        insert new List<Reason_Code__c>{ resObj, r2 };


    } // END of TestData ()  globals

    public Accounting acctData; 
    
    public String periodName(Datetime myDT){
        String myDate = myDT.format('MM-yyyy');
        system.assert( myDate != null, 'expected valid date');
        return myDate.toUpperCase();
    }

    //Create a map between the Record Type Name and Id for easy retrieval
    public Map<String,String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
    public map <string,string> SupplierRecordTypes = KSE.RecordTypeDevNameMap('Supplier__c');
     /*********************************************************************************************
      * 
      * Company data - records and tables below here link to a specific company
      * 
      */
    
    // globals 
    public Company__c company ;
    public Supplier__c supplier = new Supplier__c();
    public Supplier__c remitToSupplier = new Supplier__c(); 
    public Location__c location = new Location__c(); 
    public Facility__c facility = new Facility__c();
    public Facility__c facility2 = new Facility__c();  
    public Location__c location1 = new Location__c();  
    public Location__c location2 = new Location__c(); 
    public Location__c location3 = new Location__c();
    public Location__c location4 = new Location__c(); 
    public Location__c location5 = new Location__c();     
    public Location__c location6 = new Location__c();   
    public Location__c location7 = new Location__c(); 
    public Location__c location8 = new Location__c(); 
    public Location__c location9 = new Location__c(); 
    public Location__c location10 = new Location__c(); 
    public Bin__c bin1 = new Bin__c();
    public Bin__c bin2 = new Bin__c();
    public Bin__c bin3 = new Bin__c();
    
        
    public Stock_Movement_Rule__c stockMovement1 = new Stock_Movement_Rule__c();     
    public Stock_Movement_Rule__c stockMovement2 = new Stock_Movement_Rule__c(); 
    public Stock_Movement_Rule__c stockMovement3 = new Stock_Movement_Rule__c(); 
    public Stock_Movement_Rule__c stockMovement4 = new Stock_Movement_Rule__c(); 
    public Stock_Movement_Rule__c stockMovement5 = new Stock_Movement_Rule__c(); 
    public List<Stock_Movement_Rule__c> stockMovementRuleList = new List<Stock_Movement_Rule__c>();
    
    public Pick_Sort_Criteria__c pickSort1 = new Pick_Sort_Criteria__c();     
    public Pick_Sort_Criteria__c pickSort2 = new Pick_Sort_Criteria__c(); 
    
    public List<Item__c> itemList=new List<Item__c>();    
    public List<Item_Cost__c> costList = new List<Item_Cost__c>();
    public List<Item_Cost__c> tempIcList = new List<Item_Cost__c>();
    
    public Product__c product = new Product__c();    
    public Product__c product2 = new Product__c(); 
    public Pricebook__c pricebook = new Pricebook__c(); 
    public Product_Group__c productgroup = new Product_Group__c();
    public Facility_Assignment__c facilityassignment = new Facility_Assignment__c();
    
    public Item_Specification__c assembly = new Item_Specification__c(); 
    public Item_Specification__c assembly2 = new Item_Specification__c(); 
    public list<Component__c> componentList= new list<Component__c>();
    public Supplier__c shipper = new Supplier__c();             // shipper is actually a Supplier record
    public Shipping_Method__c shippingMethod=new Shipping_Method__c();
    public Customer__c customerParent = new Customer__c(); 
    public Customer__c customerBillTo = new Customer__c(); 
    public Customer__c customer = new Customer__c();  // this will be a sold to 
    public Customer__c customerSoldTo = new Customer__c(); 
    public Customer__c customerShipTo = new Customer__c(); 
    public list<Sales_Order_Line__c> SalesOrderLines=new list<Sales_Order_Line__c>();    
    public Sales_Order__c salesOrder=new Sales_Order__c();  
    public list<Order_Line__c> transferOrderLines=new list<Order_Line__c>();    
    public Order__c transferOrder=new Order__c();  
    public Purchase_Order__c purchaseOrder = new Purchase_Order__c();
    public Purchase_Order__c purchaseOrder2 = new Purchase_Order__c();
    public Purchase_Order__c purchaseOrder3 = new Purchase_Order__c();
    public Purchase_Order__c purchaseOrder4 = new Purchase_Order__c();
    public Purchase_Order__c purchaseOrder5 = new Purchase_Order__c();
    public Receiving_Document__c receivingdocument=new Receiving_Document__c();  
    public Receiving_Document__c receivingdocument1=new Receiving_Document__c();  
    public Receipt_Line__c receiptinvoiceline=new Receipt_Line__c();  
    public Receipt_Line__c receiptinvoiceline1=new Receipt_Line__c();  
    public Receipt_Line__c receiptinvoiceline2=new Receipt_Line__c(); 
    public Receipt_Line__c receiptinvoiceline3=new Receipt_Line__c();  
    public Receipt_Line__c receiptinvoiceline4=new Receipt_Line__c(); 
    public Work_Order__c workorder = new Work_Order__c(); 
    public Work_Order__c workorder2 = new Work_Order__c(); 
    public Order_Forecast__c orderforecast = new Order_Forecast__c(); 
    public Order_Forecast__c orderforecast2 = new Order_Forecast__c(); 
    
    public List<Period__c> periodList = new List<Period__c>();    
    
    /* 
     * VisualForce constructor when run from the Company setup link, knows how to build data for that company
     */   
    
    
    private void TestDataUpserts( id coid ) {
        
            Reason_Code__c crxceed = new Reason_Code__c( name='CRXCD' , 
                Code__c = 'CRXCD',
                Type__c = 'Sales Order', 
                Category__c ='Credit Limit',
                Description__c='This order would cause a credit limit to be exceeded' ,
                Primary_Key__c = 'CRXCD_'+coid,
                Company__c = coid );
            
            upsert new List<Reason_Code__c> { crxceed }  Primary_Key__c; 
    }
    
    private static TestData instance = null;
    public static TestData getInstance(){
        // lazy load the record only initialize if it doesn't already exist
        if ( instance == null ) instance = new TestData();
        return instance;
    } 
    
    public TestData(Company__c co) {  // if you already have a company, stash that 
            company = co;
    }    
    
    /*
     * All test methods use this constructor, builds all details needed to run many tests
     */     
    public TestData() {    
        //TestDataGlobal();  // creates globals
        
        company = new Company__c();
        company.name = 'Kenandy';
        company.Address__c = account.ID;
        company.A_Days__c = 30;
        company.B_Days__c = 60;
        company.C_Days__c = 180;
        company.Company_Identifier__c = 'KEN';  
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        company.Consol_Currency__c = TestFuel.currencyEUR.id;
        company.Stat_Currency__c = TestFuel.currencyGBP.id;
        company.Subs_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        //company.Finalize_Supplier_Invoices_w_Exceptions__c = false; //KNDY-2817
        insert company;
        
        TestDataGlobal();  // creates globals
        
        TestData_worker(  );     // creates company based data
    }
    
    public void TestData_worker( ) {
       
       TestDataUpserts( this.company.id ); // build records using upsert, avoids duplicates and is unlikely to throw an exception
       
            string remittosupnam = company.Name + 'Remit to Supplier';
            //List<Supplier__c> tmp2 =  [select id,name from supplier__c where name = :remittosupnam];
            //if ( tmp.size() == 0) {
                remitToSupplier.Name = remittosupnam;
                remitToSupplier.Company__c = company.ID;
                remitToSupplier.Tax_ID__c = 'tax ID';
                remitToSupplier.Address__c = remittoaccount.ID;
                remitToSupplier.Status__c = 'Active';
                remitToSupplier.Payment_Term__c = terms.ID;
                remitToSupplier.Type__c = 'Remit-To';
                remitToSupplier.RecordTypeId = SupplierRecordTypes.get('Remit_To');
                remitToSupplier.Alternate_Name__c = 'Remit to Supplier';
                insert remitToSupplier;
            //} else {
            //    remitToSupplier = tmp[0]; 
            //}
      
            string supnam = company.Name + ' Supplier-1';
            //List<Supplier__c> tmp =  [select id,name from supplier__c where name = :supnam];
            //if ( tmp.size() == 0) {
                supplier.Name = supnam;
                supplier.Company__c = company.ID;
                supplier.Tax_ID__c = 'tax ID';
                supplier.Address__c = remittoaccount.ID;
                supplier.Status__c = 'Active';
                supplier.Payment_Term__c = terms.ID;
                supplier.Type__c = 'Purchasing';
                supplier.RecordTypeId = SupplierRecordTypes.get('Purchase_From');
                supplier.Remit_To__c =  remitToSupplier.id;
                supplier.Alternate_Name__c = 'Test Supplier';
                insert supplier;
            //} else {
            //    supplier = tmp[0]; 
            //} 
        
            string fn = company.Name + ' Facility-1';
            //if ( [ select id from Facility__c where name = :fn ].size() == 0 ) {
                
                facility.Name = fn;
                facility.Company__c = company.Id;
                facility.Description__c = 'Facility-1';
                facility.Primary_Key__c = 'FA01';
                insert facility;
                
                location.Facility__c = facility.id;
                location.name = 'Receiving Dock';
                location.Nettable__c = false;
                location.Primary_Key__c = 'loc';
                insert location;
                
                facility = [ select id, name, ( select id, name from Locations__r ) 
                                from Facility__c where id = :facility.id limit 1];    
        
            
                facility2.Name = company.Name + ' Facility-2';
                facility2.Company__c = company.Id;
                facility2.Description__c = 'Facility-2';
                facility2.Primary_Key__c = 'FA02';
                insert facility2;
            
                location1.Facility__c = facility2.id;
                location1.name = 'Receiving Dock';
                location1.Nettable__c = false;
                location1.Primary_Key__c = 'loc1';                    
        
                location2.Facility__c = facility2.id;
                location2.name = 'Inspection';
                location2.Nettable__c = false;
                location2.Primary_Key__c = 'loc2';                   
                
           
                location3.Facility__c = facility2.ID;
                location3.Name = 'Stock';
                location3.Nettable__c = true;
                location3.Primary_Key__c = 'loc3';                   
              
                location3.Bin_Tracked__c = true;
                
                
                
                List<Configuration__c> configList = new List<Configuration__c>();  
                List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Bin__c.sObjectType};  
                
                for (sObjectType s:skipTriggers) {
                    configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
                }
                insert configList;
                insert new List<Location__c> {location1, Location2, location3};
            
                bin1.Name = 'Stock-Bin-1';
                bin1.Location__c = location3.id;
                
            
                bin2.Name = 'Stock-Bin-2';
                bin2.Location__c = location3.id;
                
                
                bin3.Name = 'Stock-Bin-3';
                bin3.Location__c = location3.id;
                
                insert new List<Bin__c>{bin1, bin2, bin3};            
            
                location4.Facility__c = facility2.ID;
                location4.Name = 'Challenge';
                location4.Nettable__c = false;
                location4.Primary_Key__c = 'loc4';                  
                
          
                location5.Facility__c = facility2.ID;
                location5.Name = 'Finished Goods';
                location5.Nettable__c = true;
                location5.Primary_Key__c = 'loc5';                  
                
            
                location6.Facility__c = facility2.ID;
                location6.Name = 'MRB';
               // location6.Nettable__c = false;
                location6.Primary_Key__c = 'loc6';                   
                
            
                location7.Facility__c = facility2.ID;
                location7.Name = 'Putaway';
                location7.Nettable__c = true;
                location7.Primary_Key__c = 'loc7';                    
                
               
                location8.Facility__c = facility2.ID;
                location8.Name = 'Scrap';
                location8.Nettable__c = false;
                location8.Primary_Key__c = 'loc8';                   
                
            
                location9.Facility__c = facility2.ID;
                location9.Name = 'WIP';
                location9.Nettable__c = true;
                location9.Primary_Key__c = 'loc9';                   
                
           
                location10.Facility__c = facility2.ID;
                location10.Name = 'Shipping Dock';
                location10.Nettable__c = true;
                location10.Primary_Key__c = 'loc10';                  
                
                
                insert new List<Location__c> {location4, Location5, location6, location7, Location8, location9, location10};
                delete configList;
                facility2.Default_Purchasing_Delivery_Location__c = location1.Id;
                facility2.Default_Sales_Order_Ship_From_Location__c = location10.Id;
                facility2.Default_Work_Order_Complete_to_Location__c = location5.Id;
                facility2.Default_Work_Order_MRB_Location__c = location8.Id;
                facility2.Default_Work_Order_WIP_Location__c = location9.Id;
                
                update facility2;
                
                company.Default_Purchasing_Deliver_To_Facility__c = location1.Facility__c;
                company.Default_Sales_Order_Ship_From_Facility__c = location10.Facility__c;
                company.Default_Work_Order_Facility__c = location3.Facility__c;
          //      company.Default_Work_Order_Scrap_Facility__c = location8.Facility__c;
                update company;                 
       
     
            string cn = company.Name + ' Item-10' ; 
            //if ( [select id from Item__c where name = :cn ].size() == 0 ) {
                for(integer i=10;i<21;i++){
                    Item__c item = new Item__c();
                    item.name= company.Name + ' Item-'+i;
                    item.Description__c='Item-'+i;
                    if (i == 10 || i == 15) {
                        item.Source__c = 'Manufactured';
                        item.Class__c = clsobj.ID;
                        item.Lead_Time__c = i/2;
                        if (i == 10) item.ABC_Code__c = 'A';
                        else item.ABC_Code__c = 'B';
                    } 
                    else {
                        item.Source__c = 'Purchased';
                        item.Supplier__c = supplier.ID;
                        item.Class__c = clsobj.ID;
                        item.Purchasing_UOM__c = uomList[8].ID;
                        item.Lead_Time__c = i/5;
                    }
                    item.company__c = company.id;
                    item.Active__c = true;
                    item.Stocking_UOM__c = uomList[8].ID;
                    item.Packaging_UOM__c = JSON.serialize(new List<Id>{uomList[8].Id});
                    itemList.add(item);
                }
                
                Item__c consignedItem = new Item__c();
                consignedItem.name= company.Name + ' Item-Consigned';
                consignedItem.Description__c='Item-Consigned';
                consignedItem.Source__c = 'Purchased';
                consignedItem.Supplier__c = supplier.ID;
                consignedItem.Class__c = clsobj.ID;
                consignedItem.Purchasing_UOM__c = uomList[8].ID;
                consignedItem.Lead_Time__c = 22/5;
                consignedItem.company__c = company.id;
                consignedItem.Active__c = true;
                consignedItem.Stocking_UOM__c = uomList[8].ID;
                consignedItem.Packaging_UOM__c = JSON.serialize(new List<Id>{uomList[8].Id});
                itemList.add(consignedItem);
                insert itemList;
                
                Item_Cross_Reference__c icr = new Item_Cross_Reference__c();
                icr.Item__c = consignedItem.Id;
                icr.Supplier__c = supplier.id;
                icr.Ship_to_Facility__c = facility2.Id;
                icr.Consigned__c = true;
                icr.Active__c = true;
                icr.Approval_Status__c = 'Approved';
                insert icr;
            //} else {
            //    itemList = [ select id, Active_Standard_Cost__c, name, Class__c from Item__c where Company__c = :company.id ]; // grab them
            //}
      
            // do we have costs already ?
            //if ( [select id from Item_Cost__c where item__c = :itemList[0].id ].size() == 0 ) { 
                
                for(integer i=0;i<11;i++){
                    Item_Cost__c cost = new Item_Cost__c();
                    cost.Name = itemList[i].Name;
                    cost.Item__c = itemList[i].ID;
                    cost.Material_Cost__c = 1 + i;
                    if (i == 0 || i == 5) {
                        cost.Labor_Cost__c = (i+10) * 1.2;
                        cost.Material_Cost__c = (i+10) * 1.77;
                    }  
                    cost.Status__c = 'Proposed';
                    cost.start_date__c = DateTime.now();
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
                    }            
                    cost.Status__c = 'Planning - 1';
                    cost.start_date__c = DateTime.now() - 10;
                    cost.Company__c = company.Id;
                    costList.add(cost);
                }
                insert costList;
                
                for(Item_Cost__c ic :costList){
                        if(ic.Status__c == 'Proposed'){
                            ic.Status__c = 'Approved';
                            ic.Date_Activated__c = System.today();
                        }else if(ic.Status__c == 'Planning - 1'){
                            ic.Status__c = 'Proposed';
                        }
                        tempIcList.add(ic);
                }
                    
                update tempIcList;
                
            //}
            
            string pgnam = company.Name +  ' ProductGroup-1';
            //if ( itemList.size() > 0 && uomList.size() > 0 && 
            //    [select id from Product_Group__c where name = :pgnam].size() == 0) 
            //{
                productgroup.Name = pgnam;
                productgroup.Company__c = company.id;
                productgroup.Facility_Assignment__c = true;
                
                insert new List<Product_Group__c>{productgroup};
            //}
            
      
            string pnam = company.Name +  ' Product-10';
            //if ( itemList.size() > 0 && uomList.size() > 0 && 
            //    [select id from Product__c where name = :pnam].size() == 0) 
            //{
                product.company__c = company.id;
                product.Name = pnam ;
                product.Item__c  = itemList[0].ID;
                product.Description__c = 'Product-10';
                product.Product_Group__c = productgroup.ID;
                product.Selling_UOM__c = uomList[8].ID;
                product.Weight__c = 13;
                product.Weight_UOM__c = uomList[0].ID;
                product.UPC_Code__c = '123456789123';  
                product.Dimension_UOM__c = uomList[6].ID;
                product.Length__c = 1;
                product.Width__c = 1;
                product.Height__c = 1;
                product.units_per_layer__c = 1;
                product.layers_per_pallet__c = 1;
                
                
                product2.company__c = company.id;
                product2.Name =  company.Name +  ' Product-15';
                product2.Item__c  = itemList[5].ID;
                product2.Description__c = 'Product-15';
                product2.Product_Group__c = productgroup.ID;
                product2.Selling_UOM__c = uomList[8].ID;
                product2.Weight__c = 5;
                product2.Weight_UOM__c = uomList[0].ID;
                product2.UPC_code__c = '234567891234'; 
                product2.Dimension_UOM__c = uomList[6].ID;
                product2.Length__c = 1;
                product2.Width__c = 1;
                product2.Height__c = 1;
                product2.units_per_layer__c = 1;
                product2.layers_per_pallet__c = 1;
                
                insert new List<Product__c>{product, product2};
            //}
      
        
     
            pricebook.name = company.Name +  ' Orange Pricebook';
            pricebook.company__c = company.id; 
            pricebook.Description__c = 'Covers high volume customers, and distributors';
            /*
            if ( product.id == null ) { 
                string prnam = company.Name +  ' Product-10';
                product = [ select id from Product__c where name = :prnam limit 1 ];
                prnam =  company.Name +  ' Product-15';
                product2 = [ select id from Product__c where name = :prnam limit 1 ];
            }
            */
            //Pricebook__c[] pbList =[select id from Pricebook__c where name = :pricebook.name limit 1]; 
            //if ( pbList.size() == 0) { 
                // build it
                insert pricebook; 
                
                //insert products into the book
                Pricebook_Line__c pl =new Pricebook_Line__c();
                pl.product__c = product.id;
                pl.pricebook__c = pricebook.id;
                pl.price__c = 12.1;
                pl.Start_Date__c = System.today();
                pl.End_Date__c = System.today()+30;
               
                Pricebook_Line__c pl2 =new Pricebook_Line__c();
                pl2.product__c = product2.id;
                pl2.pricebook__c = pricebook.id;
                pl2.price__c = 11.1;
                pl2.Start_Date__c = System.today();
                pl2.End_Date__c = System.today()+30;
                
                insert new List<Pricebook_Line__c>{pl,pl2};
                
            //} else { 
            //    pricebook= pbList[0];
            //}
            
           
            if ( itemList.size() > 0  ) {
            
                assembly.Item__c  = itemList[0].ID;
                assembly.Start_Date2__c = System.now().addDays(-39);
                assembly.Revision__c = 'A';
                assembly.company__c = company.id;
                assembly.Production__c = true;
                assembly.Costing__c = true;
                assembly.Packaging_UOM__c = uomList[8].Id;
                assembly.Default_Work_Order_Packaging_UOM__c = uomList[8].Id;

                assembly2.Item__c  = itemList[5].ID;
                assembly2.Start_Date2__c = System.now().addDays(-75);
                assembly2.Revision__c = 'B';
                assembly2.company__c = company.id;
                assembly2.Production__c = true;
                assembly2.Costing__c = true;
                assembly2.Packaging_UOM__c = uomList[8].Id;
                assembly2.Default_Work_Order_Packaging_UOM__c = uomList[8].Id;
                
                insert new List<Item_Specification__c> {assembly, assembly2};
                
                for(integer i=1;i<6;i++){
                    Component__c comp=new Component__c();
                    comp.Component_Item__c=itemList[i].Id;
                    comp.Assembly_Item_Specification__c=assembly.Id;
                    if (i == 3) comp.Quantity_per_Assembly__c = 2;
                    else comp.Quantity_per_Assembly__c = 1;
                    comp.Type__c = ComponentService.TYPE_BACKFLUSH;
                    comp.Company__c=company.Id;
                    componentList.add(comp);
                }
                
                for(integer i=6;i<11;i++){
                    Component__c comp=new Component__c();
                    comp.Component_Item__c=itemList[i].Id;
                    comp.Assembly_Item_Specification__c=assembly2.Id;
                    if (i == 6){
                        comp.Quantity_per_Assembly__c = 2.5;
                        comp.Type__c = ComponentService.TYPE_KIT;
                    }else {
                        comp.Quantity_per_Assembly__c = 1;
                        comp.Type__c = ComponentService.TYPE_BACKFLUSH;
                    }
                    
                    comp.Company__c=company.Id;
                    componentList.add(comp);
                }
            
                insert componentList;
            }
     
            string sn = company.Name +  ' Supplier-1';
            if ( [select id,RecordType.Name, RecordType.DeveloperName, RecordTypeId from Supplier__c where name = :sn ].size() == 0 ) {
            
                shipper.Name = sn;
                shipper.Company__c = company.ID;
                shipper.Tax_ID__c = 'tax ID';
                shipper.Address__c = remittoaccount.ID;
                shipper.Status__c = 'Active';
                shipper.Payment_Term__c = terms.ID;
                shipper.Type__c = 'Purchasing';
                shipper.RecordTypeId = SupplierRecordTypes.get('Purchase_From');
                shipper.Remit_To__c =  remitToSupplier.id;
                insert shipper;
            
                shippingMethod.Supplier__c=shipper.id;
                shippingMethod.Name= 'Ground';
                shippingMethod.Description__c='USPS Ground';
                insert shippingMethod; 
            }
        
    
        string cnam = company.Name + ' Customer Corp Parent 1';
        //if ( [select id from Customer__c where name = :cnam].size() == 0) {
            system.assert( CustomerRecordTypes.get('Corporate_Parent') != null, 'expected valid id for corp to record type on customer');
            customerParent.name = company.Name + ' Customer Corp Parent 1';
            customerParent.recordTypeId = CustomerRecordTypes.get('Corporate_Parent');
            customerParent.Company__c = company.id;
            customerParent.Address__c = soldtoaccount.ID;
            customerParent.Credit_Limit__c = 100000.0;
            customerParent.Customer_Identifier__c = company.Name + ' CPTEST123'; 
            customerParent.Open_Sales_Orders__c = 0;
            customerParent.Uninvoiced_Shipments__c = 0;
            customerParent.Status__c = 'Approved';
            customerParent.Track_Install_Base__c = true;
            insert customerParent;
        
            system.assert( CustomerRecordTypes.get('Bill_To') != null, 'expected valid id for bill to record type on customer');
            customerBillTo.name = 'Customer Bill To 1';
            customerBillTo.recordTypeId = CustomerRecordTypes.get('Bill_To');
            customerBillTo.Company__c = company.id;
            customerBillTo.Payment_Term__c = terms.ID;
            customerBillTo.Address__c = billtoaccount.ID;
            customerBillTo.Credit_Limit__c = 100000.0;
            customerBillTo.Parent_Customer__c = customerParent.id; 
            customerBillTo.Customer_Identifier__c = company.Name + ' BDTEST123'; 
            customerBillTo.Status__c = 'Approved';
            customerBillTo.Track_Install_Base__c = true;
            insert customerBillTo;
       
            system.assert( CustomerRecordTypes.get('Sold_To') != null, 'expected valid id for sold to record type on customer');
            customerSoldTo.name = 'Customer Sold To 1';
            customerSoldTo.recordTypeId = CustomerRecordTypes.get('Sold_To');
            customerSoldTo.Company__c = company.id;
            customerSoldTo.Address__c = soldtoaccount.ID;
            customerSoldTo.Credit_Limit__c = 100000.0;
            customerSoldTo.Parent_Customer__c = customerBillTo.id; 
            customerSoldTo.Customer_Identifier__c = company.Name + ' SDTEST123'; 
            customerSoldTo.Pricebook__c = pricebook.id;
            customerSoldTo.Status__c = 'Approved';
            customerSoldTo.Track_Install_Base__c = true;
            insert customerSoldTo;
            
            customer = customerSoldTo; 
    
            system.assert( CustomerRecordTypes.get('Ship_To') != null, 'expected valid id for ship to record type on customer');
            customerShipTo.name = 'Customer Ship To 1';
            customerShipTo.recordTypeId = CustomerRecordTypes.get('Ship_To');
            customerShipTo.Company__c = company.id;
            customerShipTo.Address__c = shiptoaccount.ID;
            customerShipTo.Credit_Limit__c = 100000.0;
            customerShipTo.Parent_Customer__c = customerSoldTo.id;
            customerShipTo.Customer_Identifier__c = company.Name + ' SHTEST123';  
            customerShipTo.Status__c = 'Approved';
            customerShipTo.Track_Install_Base__c = true;
            insert customerShipTo;
            
            //insert new List<Customer__c>{customerParent, customerBillTo, customerSoldTo, customerShipTo};
        //}
        
            List<Pick_Sort_Criteria__c> pscList = new List<Pick_Sort_Criteria__c>();
            
            pickSort1.Name = 'Sort criteria1';
            pickSort1.Sort_Field__c = 'Expiration_Date__c';
            pickSort1.Sort_Order__c = 'Asc';
            pickSort1.Null_Values__c = 'Last';
            pickSort1.Sort_Priority__c = 2;
            pickSort1.Company__c = company.id;
            pickSort1.Customer__c = customerSoldTo.id;
            pickSort1.Active__c = true;
            pscList.add( pickSort1 );
            
            pickSort2.Name = 'Sort criteria2';
            pickSort2.Sort_Field__c = 'Consigned_Owner__r.Name';
            pickSort2.Sort_Order__c = null;
            pickSort2.Null_Values__c = 'First';
            pickSort2.Sort_Priority__c = 1;
            pickSort2.Company__c = company.id;
            pickSort2.Customer__c = customerSoldTo.id;
            pickSort2.Active__c = true;
            pscList.add( pickSort2 );
            
            insert pscList;
            
            
            
            stockMovement1.Name = 'Putaway rule1';
            stockMovement1.Rule_Type__c = 'Putaway';
            stockMovement1.Company__c = company.id;
            stockMovement1.Facility__c = facility2.id;
            stockMovement1.Class__c = clsObj.id;
            stockMovement1.Item__c = null;
            stockMovement1.Customer__c = null;
            stockMovement1.Source_Document__c = 'Purchase Order';
            stockMovement1.Priority__c = 4;
            stockMovement1.Location_List__c = JSON.serialize(new List<Id>{location3.id});
            stockMovement1.Active__c = true;
            stockMovementRuleList.add( stockMovement1 );  
            
            stockMovement2.Name = 'Putaway rule2';
            stockMovement2.Rule_Type__c = 'Putaway';
            stockMovement2.Company__c = company.id;
            stockMovement2.Facility__c = facility2.id;
            stockMovement2.Class__c = clsObj.id;
            stockMovement2.Item__c = null;
            stockMovement2.Customer__c = null;
            stockMovement2.Source_Document__c = 'Work Order';
            stockMovement2.Priority__c = 5;
            stockMovement2.Location_List__c = JSON.serialize(new List<Id>{location3.id});
            stockMovement2.Active__c = true;
            stockMovementRuleList.add( stockMovement2 );  
            
            stockMovement3.Name = 'Pick rule1';
            stockMovement3.Rule_Type__c = 'Pick';
            stockMovement3.Company__c = company.id;
            stockMovement3.Facility__c = facility2.id;
            stockMovement3.Class__c = null;
            stockMovement3.Item__c = itemList[0].id;
            stockMovement3.Customer__c = customer.id;
            stockMovement3.Source_Document__c = 'Sales Order';
            stockMovement3.Priority__c = 1;
            stockMovement3.Location_List__c = JSON.serialize(new List<Id>{location3.id});
            stockMovement3.Active__c = true;
            stockMovementRuleList.add( stockMovement3 );  
            
            stockMovement4.Name = 'Pick rule2';
            stockMovement4.Rule_Type__c = 'Pick';
            stockMovement4.Company__c = company.id;
            stockMovement4.Facility__c = facility2.id;
            stockMovement4.Class__c = clsObj.id;
            stockMovement4.Item__c = null;
            stockMovement4.Customer__c = customer.id;
            stockMovement4.Source_Document__c = 'Sales Order';
            stockMovement4.Priority__c = 2;
            stockMovement4.Location_List__c = JSON.serialize(new List<Id>{location3.id});
            stockMovement4.Active__c = true;
            stockMovementRuleList.add( stockMovement4 );  
            
            stockMovement5.Name = 'Pick rule3';
            stockMovement5.Rule_Type__c = 'Pick';
            stockMovement5.Company__c = company.id;
            stockMovement5.Facility__c = facility2.id;
            stockMovement5.Class__c = clsObj.id;
            stockMovement5.Item__c = null;
            stockMovement5.Customer__c = null;
            stockMovement5.Source_Document__c = 'Work Order';
            stockMovement5.Priority__c = 3;
            stockMovement5.Location_List__c = JSON.serialize(new List<Id>{location3.id});
            stockMovement5.Active__c = true;
            stockMovementRuleList.add( stockMovement5 );
            
            Stock_Movement_Rule__c stockMovement7 = new Stock_Movement_Rule__c();
            stockMovement7.Name = 'Transfer Order Pick rule';
            stockMovement7.Rule_Type__c = 'Pick';
            stockMovement7.Company__c = company.id;
            stockMovement7.Facility__c = facility2.id;
            stockMovement7.Source_Document__c = 'Transfer Order';
            stockMovement7.Priority__c = 1;
            stockMovement7.Location_List__c = JSON.serialize(new List<Id>{location3.id});
            stockMovement7.Active__c = true;
            stockMovementRuleList.add( stockMovement7 ); 
            
            Stock_Movement_Rule__c stockMovement8 = new Stock_Movement_Rule__c();
            stockMovement8.Name = 'Transfer Order Putaway rule';
            stockMovement8.Rule_Type__c = 'Putaway';
            stockMovement8.Company__c = company.id;
            stockMovement8.Facility__c = facility.id;
            stockMovement8.Source_Document__c = 'Transfer Order';
            stockMovement8.Priority__c = 1;
            stockMovement8.Location_List__c = JSON.serialize(new List<Id>{location.id});
            stockMovement8.Active__c = true;
            stockMovementRuleList.add( stockMovement8 );
            
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
            stockMovement10.Location_List__c = JSON.serialize(new List<Id>{location3.id});
            stockMovement10.Active__c = true;
            stockMovementRuleList.add( stockMovement10 );
            
            insert stockMovementRuleList;
        
            string fanam = company.Name +  ' FA-1';
            //if ( itemList.size() > 0 && uomList.size() > 0 && 
            //    [select id from Facility_Assignment__c where name = :fanam].size() == 0) 
            //{
                facilityassignment.Name = fanam;
                facilityassignment.Company__c = company.id;
                facilityassignment.Active__c = true;
                facilityassignment.Start_Date__c = System.today() - 60;
                facilityassignment.Facility__c = facility2.ID;
                facilityassignment.Product_Group__c = productgroup.ID;
                facilityassignment.Ship_to_Customer__c = customerShipTo.ID;
                
                insert new List<Facility_Assignment__c>{facilityassignment};
            //}
     
                
            salesOrder.Company__c = company.id;
            salesOrder.Customer__c = customer.id;    // must be a sold to
            salesOrder.Ship_To__c = customerShipTo.Id;
            salesOrder.Bill_To__c = customerBillTo.Id;
            salesOrder.Payment_Term__c = terms.id;
            salesOrder.Required_Date__c = system.today().adddays(2);
            salesOrder.Original_Sales_Order__c = 'so123';  
            salesOrder.Currency__c = TestFuel.currencyUSD.ID;   
            insert salesOrder;
            
            Sales_Order_Line__c SalesOrderLine = new Sales_Order_Line__c();
            SalesOrderLine.Product__c = product.Id;
            SalesOrderLine.Description__c = product.Description__c;
            SalesOrderLine.Company__c = company.id;
            SalesOrderLine.Sales_Order__c = salesOrder.Id;
            SalesOrderLine.Quantity_Ordered__c = 100;
            SalesOrderLine.Required_Date__c = System.today()+5;
            SalesOrderLine.Weight_UOM__c = uomList[0].ID;
            
            SalesOrderLine.Discount_Percent__c = 2;
            SalesOrderLine.Ship_From_Location__c = location10.ID;
            SalesOrderLines.add(SalesOrderLine);
            
            SalesOrderLine = new Sales_Order_Line__c();
            SalesOrderLine.Product__c = product2.Id;
            SalesOrderLine.Description__c = product2.Description__c;
            SalesOrderLine.Discount_Percent__c = 2;
            SalesOrderLine.Company__c = company.id;
            SalesOrderLine.Sales_Order__c = salesOrder.Id;
            SalesOrderLine.Quantity_Ordered__c = 15;
            SalesOrderLine.Required_Date__c = System.today()+15;
            
            SalesOrderLine.Ship_From_Location__c = location10.ID;
            
            SalesOrderLines.add(SalesOrderLine);
                    
            insert SalesOrderLines;
    
            salesOrder = [Select s.Status__c, s.Customer__c, s.Company__c, s.Ship_To__c, s.customer__r.top_parent_customer__c, s.order_total__c,
                                s.Customer__r.Customer_Group__c, s.Ship_To__r.Customer_Group__c, s.customer__r.top_parent_customer__r.Customer_Group__c,
                                s.Currency__c,Required_Date__c, s.Subtotal__c, s.Ship_From_Location__c,
                                (Select Id, IsDeleted, Name, CreatedDate, CreatedById, Product__r.Product_Group__c, Quantity_Fulfilled__c,
                                LastModifiedDate, LastModifiedById, SystemModstamp, Sales_Order__c,  Product_Weight__c,
                                Backorder_Value__c, Company__c, Description__c, Discount_Percent__c, Ship_From_Location__r.Facility__r.Address__c,
                                Extended_Price__c, Product__r.Item__c, Line__c, Quantity_Backordered__c, Ship_From_Location__c, 
                                Quantity_Ordered__c, Quantity_Shipped__c, Required_Date__c, Status__c, Product__r.Item__r.Class__c,
                                Unit_Price__c From Sales_Order_Lines__r ) 
                    From Sales_Order__c s where id=:salesOrder.id limit 1];
        
        SalesOrderLines = salesOrder.Sales_Order_Lines__r;

        transferOrder = new Order__c(
                                    Shipping_Company__c = company.id,
                                    Deliver_To_Facility__c = facility.id,
                                    Deliver_To_Location__c = location.ID,
                                    Receiving_Company__c = company.id,
                                    Ship_From_Facility__c = facility2.id,
                                    Ship_From_Location__c = location2.ID,
                                    Status__c = 'Draft',
                                    Currency__c = TestFuel.currencyUSD.ID
                                );
        insert transferOrder; 
        
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
        toLine1.Quantity_Ordered__c = 10;
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
        
        insert transferOrderLines;
        
        purchaseOrder.Supplier__c = supplier.id; 
        purchaseOrder.Company__c = company.id;
        purchaseOrder.Payment_Term__c = terms.id;
        purchaseOrder.Delivery_Facility__c = facility2.id;
        purchaseOrder.Delivery_Location__c = location1.ID;
        purchaseOrder.Remit_To_Supplier__c = remitToSupplier.id;
        purchaseOrder.Memo__c = 'PurchaseOrder';
        purchaseOrder.Currency__c = TestFuel.currencyUSD.Id;
        
        purchaseOrder2.Supplier__c = supplier.id; 
        purchaseOrder2.Company__c = company.id;
        purchaseOrder2.Payment_Term__c  = terms.id;
        purchaseOrder2.Delivery_Facility__c = facility2.id;
        purchaseOrder2.Delivery_Location__c = location1.ID;
        purchaseOrder2.Remit_To_Supplier__c = remitToSupplier.id;
        purchaseOrder2.Memo__c = 'PurchaseOrder2';
        purchaseOrder2.Currency__c = TestFuel.currencyUSD.Id;
        
        purchaseOrder3.Supplier__c = supplier.id; 
        purchaseOrder3.Company__c = company.id;
        purchaseOrder3.Payment_Term__c  = terms.id;
        purchaseOrder3.Delivery_Facility__c = facility2.id;
        purchaseOrder3.Delivery_Location__c = location1.ID;
        purchaseOrder3.Remit_To_Supplier__c = remitToSupplier.id;
        purchaseOrder3.Memo__c = 'PurchaseOrder3';
        purchaseOrder3.Currency__c = TestFuel.currencyUSD.Id;
        
        purchaseOrder4.Supplier__c = supplier.id; 
        purchaseOrder4.Company__c = company.id;
        purchaseOrder4.Payment_Term__c  = terms.id;
        //purchaseOrder4.Approval_Status__c = 'Approved';
        purchaseOrder4.Delivery_Facility__c = facility2.id;
        purchaseOrder4.Delivery_Location__c = location1.ID;
        purchaseOrder4.Remit_To_Supplier__c = remitToSupplier.id;
        purchaseOrder4.Memo__c = 'PurchaseOrder4';
        purchaseOrder4.Currency__c = TestFuel.currencyUSD.Id;
        
        purchaseOrder5.Supplier__c = supplier.id; 
        purchaseOrder5.Company__c = company.id;
        purchaseOrder5.Payment_Term__c  = terms.id;
        purchaseOrder5.Delivery_Facility__c = facility2.id;
        purchaseOrder5.Delivery_Location__c = location1.ID;
        purchaseOrder5.Remit_To_Supplier__c = remitToSupplier.id;
        purchaseOrder5.Memo__c = 'purchaseOrder5';
        purchaseOrder5.Currency__c = TestFuel.currencyUSD.Id;
        insert new List<Purchase_Order__c>{ purchaseOrder, PurchaseOrder2, purchaseOrder3, purchaseOrder4, purchaseOrder5 };
        
        Purchase_Order_Line__c objPODetail = new Purchase_Order_Line__c();
        objPODetail.Purchase_Order__c = purchaseOrder.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = itemList[2].Id;
        objPODetail.Description__c = itemList[2].Description__c;
        objPODetail.Purchase_UOM__c = itemList[2].Purchasing_UOM__c;
        objPODetail.Company__c = company.id;
        objPODetail.Need_Date__c = system.today() + 7;
        objPODetail.Delivery_Facility__c = facility2.id;
        objPODetail.Delivery_Location__c = location1.ID;
        objPODetail.Supplier__c = supplier.Id;

        Purchase_Order_Line__c objPODetail2 = new Purchase_Order_Line__c();
        objPODetail2.Purchase_Order__c = purchaseOrder2.Id;
        objPODetail2.Order_Quantity__c = 25;        
        objPODetail2.Unit_Price__c = 1.29;
        objPODetail2.Item__c = itemList[2].Id;
        objPODetail2.Description__c = itemList[7].Description__c;
        objPODetail2.Purchase_UOM__c = itemList[7].Purchasing_UOM__c;
        objPODetail2.Company__c = company.id;
        objPODetail2.Need_Date__c = system.today() + 17;
        objPODetail2.Delivery_Facility__c = facility2.id;
        objPODetail2.Delivery_Location__c = location1.ID;
        objPODetail2.Supplier__c = supplier.Id;
        //insert new List<Purchase_Order_Line__c>;
        
        Purchase_Order_Line__c objPODetail3 = new Purchase_Order_Line__c();
        objPODetail3.Purchase_Order__c = purchaseOrder4.Id;
        objPODetail3.Order_Quantity__c = 25;        
        objPODetail3.Unit_Price__c = 1.29;
        objPODetail3.Item__c = itemList[2].Id;
        objPODetail3.Description__c = itemList[7].Description__c;
        objPODetail3.Purchase_UOM__c = itemList[7].Purchasing_UOM__c;
        objPODetail3.Company__c = company.id;
        objPODetail3.Need_Date__c = system.today() + 17;
        objPODetail3.Delivery_Facility__c = facility2.id;
        objPODetail3.Delivery_Location__c = location1.ID;
        objPODetail3.Supplier__c = supplier.Id;
        
        Purchase_Order_Line__c objPODetail4 = new Purchase_Order_Line__c();
        objPODetail4.Purchase_Order__c = purchaseOrder4.Id;
        objPODetail4.Consigned__c = true;
        objPODetail4.Order_Quantity__c = 25;        
        objPODetail4.Unit_Price__c = 1.29;
        objPODetail4.Item__c = itemList[2].Id;
        objPODetail4.Description__c = itemList[7].Description__c;
        objPODetail4.Purchase_UOM__c = itemList[7].Purchasing_UOM__c;
        objPODetail4.Company__c = company.id;
        objPODetail4.Need_Date__c = system.today() + 17;
        objPODetail4.Delivery_Facility__c = facility2.id;
        objPODetail4.Delivery_Location__c = location1.ID;
        objPODetail4.Supplier__c = supplier.Id;
   
        Purchase_Order_Line__c pol1_po5 = new Purchase_Order_Line__c();
        pol1_po5.Purchase_Order__c = purchaseOrder5.Id;
        pol1_po5.Order_Quantity__c = 25;        
        pol1_po5.Unit_Price__c = 1.29;
        pol1_po5.Item__c = itemList[2].Id;
        pol1_po5.Description__c = itemList[7].Description__c;
        pol1_po5.Purchase_UOM__c = itemList[7].Purchasing_UOM__c;
        pol1_po5.Company__c = company.id;
        pol1_po5.Need_Date__c = system.today() + 17;
        pol1_po5.Delivery_Facility__c = facility2.id;
        pol1_po5.Delivery_Location__c = location1.ID;
        pol1_po5.Supplier__c = supplier.Id;
        
        Purchase_Order_Line__c pol2_po5_consigned = new Purchase_Order_Line__c();
        pol2_po5_consigned.Purchase_Order__c = purchaseOrder5.Id;
        pol2_po5_consigned.Consigned__c = true;
        pol2_po5_consigned.Order_Quantity__c = 25;        
        pol2_po5_consigned.Unit_Price__c = 1.29;
        pol2_po5_consigned.Item__c = consignedItem.Id;
        pol2_po5_consigned.Description__c = consignedItem.Description__c;
        pol2_po5_consigned.Purchase_UOM__c = consignedItem.Purchasing_UOM__c;
        pol2_po5_consigned.Company__c = company.id;
        pol2_po5_consigned.Need_Date__c = system.today() + 17;
        pol2_po5_consigned.Delivery_Facility__c = facility2.id;
        pol2_po5_consigned.Delivery_Location__c = location1.ID;
        pol2_po5_consigned.Supplier__c = supplier.Id;
        List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>{ objPODetail, objPODetail2, objPODetail3, objPODetail4, pol1_po5, pol2_po5_consigned };
        
        for (integer i = 1; i < 11; ++i) {
            Purchase_Order_Line__c Obj = new Purchase_Order_Line__c();
            Obj.Purchase_Order__c = purchaseOrder3.Id;
            Obj.Order_Quantity__c = 500;        
            Obj.Unit_Price__c = costList[i].Material_Cost__c;
            Obj.Item__c = itemList[i].Id;
            Obj.Description__c = itemList[i].Description__c;
            Obj.Purchase_UOM__c = itemList[i].Purchasing_UOM__c;
            Obj.Company__c = company.id;
            Obj.Need_Date__c = system.today() + 5;
            obj.Delivery_Facility__c = facility2.id;
            Obj.Delivery_Location__c = location1.ID;
            Obj.Supplier__c = supplier.Id;
            polList.add(obj);
        }
        insert polList;
         
         purchaseOrder = [Select p.SystemModstamp, 
                        p.Supplier__c, p.Status__c, 
                        p.Ship_Via__c, p.Rush_Order__c, 
                        p.Payment_Term__c, p.Order_Date__c, 
                        p.Name, p.Need_Date__c,
                        p.Id, p.Deliver_to__c, p.Date_Closed__c, p.Delivery_Location__c,p.Delivery_Facility__c,
                        p.Company__c, p.Buyer__c, Purchase_Order_Value__c,   
                        p.Approval_Status__c, p.Acknowledge_Via__c, 
                        (Select Id, IsDeleted, Name, Purchase_Order__c, Company__c, SystemModstamp,
                            Date_Added__c, Date_Closed__c, Date_Last_Changed__c, Description__c,  
                            Item__c, Latest_Promise_Date__c, Line_Value__c, Line__c,  Manufacturers_Part__c, 
                            Need_Date__c, Order_Quantity__c, Overage_Percentage__c, 
                            Promise_Date__c, Purchase_UOM__c, Quantity_Returned_to_Supplier__c, 
                            Quantity_Still_Due__c, Delivery_Location__c,Delivery_Facility__c,
                            Requisition_Number__c, Rush_Line__c, Special_Notes__c, Status__c, 
                            Supplier_Part__c, Suppliers_Part_Description__c, Unit_Price__c 
                            From Purchase_Order_Lines__r order by Line__c ASC) 
                        From Purchase_Order__c p
                        where p.id = :purchaseOrder.id limit 1];
    
      
            receivingdocument.Company__c = company.Id;
            receivingdocument.Supplier__c = supplier.Id;
            receivingdocument.Carrier__c = 'USPS';
            receivingdocument.Tracking_Number__c = '99423724234762348853';
            receivingdocument.Number_of_Boxes__c = 1;
            receivingdocument.Date_Expected__c = system.today() + 11;
            receivingdocument.Currency__c = TestFuel.currencyUSD.id;
            insert receivingdocument; 
        
            receivingdocument1.Company__c = company.Id;
            receivingdocument1.Supplier__c = supplier.Id;
            receivingdocument1.Carrier__c = 'USPS';
            receivingdocument1.Tracking_Number__c = '99423724234762348853';
            receivingdocument1.Number_of_Boxes__c = 1;
            receivingdocument1.Date_Expected__c = system.today() + 14;
            receivingdocument1.Type__c = 'Purchase Order Return';
            receivingdocument1.Currency__c = TestFuel.currencyUSD.id;            
            insert receivingdocument1; 
        
        
            List<Purchase_Order_Line__c> poline = [select ID from Purchase_Order_Line__c 
                where Purchase_Order__c =: purchaseorder2.ID Limit 1]; 
            
            receiptinvoiceline.Company__c=company.Id;
            receiptinvoiceline.Supplier__c=supplier.Id;
            receiptinvoiceline.Receiving_Document__c=receivingdocument.Id;
            receiptinvoiceline.Purchase_Order__c = purchaseorder2.ID;
            receiptinvoiceline.Purchase_Order_Line__c = poline[0].ID;
            //receiptinvoiceline.Quantity_Shipped__c = 1;
            receiptinvoiceline.Number_of_Boxes__c = 1;
            receiptinvoiceline.Item__c = itemList[0].id;
            receiptinvoiceline.Quantity_returned_to_supplier__c = 5;
            receiptinvoiceline.Quantity_Returned_to_Supplier_for_Credit__c = 0;
            //insert receiptinvoiceline; 
        
            receiptinvoiceline1.Company__c=company.Id;
            receiptinvoiceline1.Supplier__c=supplier.Id;
            receiptinvoiceline1.Receiving_Document__c=receivingdocument.Id;
            receiptinvoiceline1.Purchase_Order__c = purchaseorder2.ID;
            receiptinvoiceline1.Purchase_Order_Line__c = poline[0].ID;
            //receiptinvoiceline.Quantity_Shipped__c = 1;
            receiptinvoiceline1.Number_of_Boxes__c = 1;
            receiptinvoiceline1.Item__c = itemList[0].id;
            receiptinvoiceline1.Quantity_returned_to_supplier__c = 0;
            receiptinvoiceline1.Quantity_Returned_to_Supplier_for_Credit__c = 5;
           // insert receiptinvoiceline1; 
           
            receiptinvoiceline3.Company__c=company.Id;
            receiptinvoiceline3.Supplier__c=supplier.Id;
            receiptinvoiceline3.Receiving_Document__c=receivingdocument1.Id;
            receiptinvoiceline3.Purchase_Order__c = purchaseorder2.ID;
            receiptinvoiceline3.Purchase_Order_Line__c = poline[0].ID;
            //receiptinvoiceline.Quantity_Shipped__c = 1;
            receiptinvoiceline3.Number_of_Boxes__c = 1;
            receiptinvoiceline3.Item__c = itemList[0].id;
            receiptinvoiceline3.Quantity_returned_to_supplier__c = 5;
            receiptinvoiceline3.Quantity_Returned_to_Supplier_for_Credit__c = 0;
            //insert receiptinvoiceline; 
        
            receiptinvoiceline4.Company__c=company.Id;
            receiptinvoiceline4.Supplier__c=supplier.Id;
            receiptinvoiceline4.Receiving_Document__c=receivingdocument1.Id;
            receiptinvoiceline4.Purchase_Order__c = purchaseorder2.ID;
            receiptinvoiceline4.Purchase_Order_Line__c = poline[0].ID;
            //receiptinvoiceline.Quantity_Shipped__c = 1;
            receiptinvoiceline4.Number_of_Boxes__c = 1;
            receiptinvoiceline4.Item__c = itemList[0].id;
            receiptinvoiceline4.Quantity_returned_to_supplier__c = 0;
            receiptinvoiceline4.Quantity_Returned_to_Supplier_for_Credit__c = 5;
           // insert receiptinvoiceline1;
           
           List<Receipt_Line__c> rlList = new List<Receipt_Line__c>();
            rlList.add( receiptinvoiceline );
            rlList.add( receiptinvoiceline1 );
            rlList.add( receiptinvoiceline3 );
            rlList.add( receiptinvoiceline4 );
            insert rlList;
        
        
            workorder.company__c = company.id;
            workorder.Assembly_Item_Specification__c = assembly.ID;
            workorder.Complete_to_Location__c = location3.id;  
            workorder.Facility__c = location3.facility__c;  
            workorder.Need_Date2__c = System.today() + 30;
            workorder.Order_Quantity__c = 75;
            workorder.MRB_Location__c = location8.id;
            workorder.Default_WIP_Location__c = location9.id;
            workorder.Notes__c = 'workorder';
            workorder.Packaging_UOM__c = uomList[8].Id ;
            workorder.Currency__c = TestFuel.currencyUSD.id;
            workorder.Item__c = assembly.Item__c;
            
            workorder2.company__c = company.id;
            workorder2.Assembly_Item_Specification__c = assembly2.ID;
            workorder2.Complete_to_Location__c = location3.id;            
            workorder2.Facility__c = location3.facility__c;        
            workorder2.Need_Date2__c = System.today() + 15;
            workorder2.Order_Quantity__c = 120;
            workorder2.MRB_Location__c = location8.id;
            workorder2.Default_WIP_Location__c = location9.id;
            workorder2.Notes__c = 'workorder2';
            workorder2.Packaging_UOM__c = uomList[8].Id ;
            workorder2.Item__c = assembly2.Item__c;
            workorder2.Currency__c = TestFuel.currencyUSD.id;
            
            insert new List<Work_Order__c>{ workorder, workorder2};
       
            orderforecast.company__c = company.id;
            orderforecast.Item__c = itemList[0].ID;
            orderforecast.Plan_Date__c = System.today() + 25;
            orderforecast.Forecast_Quantity__c = 100;
            orderforecast.Consumption_End_Date__c = System.today() + 200;
            orderforecast.Consumption_Start_Date__c = System.today() - 200;
            insert orderforecast;
        
            orderforecast2.company__c = company.id;
            orderforecast2.Item__c = itemList[5].ID;
            orderforecast2.Plan_Date__c = System.today() + 35;
            orderforecast2.Forecast_Quantity__c = 300;
            orderforecast2.Consumption_End_Date__c = System.today() + 200;
            orderforecast2.Consumption_Start_Date__c = System.today() - 200;
            insert orderforecast2;
        
       
        periodList = generatePeriods(company.Id, system.now().year());
        Fiscal_Year__c fy = new Fiscal_Year__c();
        fy.company__c = company.Id;
        fy.fiscal_year_start_date__c = periodList[0].period_start__c;
        fy.fiscal_year_end_date__c = periodList[periodList.size()-1].period_end__c.addMonths(3);
        
        insert fy;

        for(Period__c p : periodList){
            p.fiscalyear__c = fy.Id;
        }
        insert periodList; 
        Period__c priorPeriod = new Period__c();
        for(Period__c p : periodList){
            p.prior_period__c = priorPeriod.Id;
            priorPeriod = p;
        }
        update periodList;
       
    } // end of creating data for company
    
    
    public List<Period__c> generatePeriods(Id companyId, integer year){
        List<Period__c> periods = new List<Period__c>();
        //integer year = system.now().year();
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
            iPeriod.Company__c = companyId;
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
            
            periods.add(iPeriod);
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
            iPeriod.Company__c = companyId;
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
            
            periods.add(iPeriod);
        }
        
        return periods;
    }
    /*
    Period__c newPeriod( Id cid, integer month  ) {
        Period__c period1 = new Period__c();
       
        //Datetime currTime = system.now();
        Datetime currTime = Datetime.newInstance(system.today().year(), month, 15); //fake datetime based on the middle of the month passed in
        
        
        Date currDate = currTime.date();
        Date begOfMonthDate = currDate.toStartOfMonth();
        Date endOfMonthDate = begOfMonthDate.addMonths(1);              
        
        Date begOfYearDate = Date.newInstance(currDate.year(), 1, 1);
        Date endOfYearDate = Date.newInstance(currDate.year(), 12, 31);
        
        Datetime begOfMonthDatetime = DateTime.newInstance(currDate.year(), currDate.month(), 1,0, 0, 0);
        Datetime endOfMonthDatetime = DateTime.newInstance(endOfMonthDate.year(), endOfMonthDate.addMonths(1).month(), 1, 0, 0, 0);            
       
        period1.Year_Start_Date__c = begOfYearDate;
        period1.Year_End_Date__c = endOfYearDate;
        period1.Period_Start__c = begOfMonthDatetime;
        period1.Period_End__c = endOfMonthDatetime;
        String periodName1 = periodName(Date.valueof(period1.Period_Start__c));
        period1.Name = periodName1 + string.valueOf(month);
        period1.Period_Number__c = month;
        period1.Quarter_Number__c =  (month / 4) +1 ;
        
        period1.Fiscal_Year__c = String.valueOf(currDate.year());
        period1.Company__c = cId;
        period1.Adjustment_Period__c = false;
        period1.Closed__c = false;
        period1.Open__c = true;
        period1.Fiscal__c = true;
        period1.Corporate__c = false;
        period1.Tax__c = false;
        period1.Permanently_Closed__c = false;
        period1.Adjustment_Period__c = false;
        
        period1.AP_Subledger_Cutoff__c = endOfMonthDatetime  ;
        period1.AR_Subledger_Cutoff__c = endOfMonthDatetime ;
        period1.Shipment_Subledger_Cutoff__c = endOfMonthDatetime ;
        period1.Receiving_Subledger_Cutoff__c = endOfMonthDatetime ;
        period1.FA_Subledger_Cutoff__c = endOfMonthDatetime ;
        period1.Inventory_Subledger_Cutoff__c = endOfMonthDatetime ;
        period1.Period_Cut_Off__c = endOfMonthDatetime ;
        return period1;
    }
    */
    // SK - Commented below function as the datetime values for period start and end were causing problem and replaced by function above.
    /*Period__c newPeriod( Id cid, integer month  ) {
        Period__c period1 = new Period__c();
        period1.Year_Start_Date__c = Date.newInstance(system.today().year(),01,01);
        period1.Year_End_Date__c = Date.newInstance(system.today().year(),12,31);

        
        String periodName1 = periodName(period1.Period_Start_Date__c);
        period1.Name = periodName1 + string.valueOf(month);
        period1.Period_Number__c = month;
        period1.Quarter_Number__c =  (month / 4) +1 ;
        
        period1.Fiscal_Year__c = String.valueOf(system.today().year());
        period1.Company__c = cId;
        period1.Adjustment_Period__c = false;
        period1.Closed__c = false;
        period1.Open__c = true;
        period1.Fiscal__c = true;
        period1.Corporate__c = false;
        period1.Tax__c = false;
        period1.Permanently_Closed__c = false;
        period1.Adjustment_Period__c = false;
        period1.Period_Start__c = DateTime.newInstance(system.today().year(),month,1);
        period1.Period_End__c = period1.Period_Start__c.addMonths(1).addDays(-1);
        period1.Period_End__c = DateTime.newInstance(period1.Period_End__c.year(), period1.Period_End__c.month(), period1.Period_End__c.day(), 23, 59, 00);
        period1.AP_Subledger_Cutoff__c = period1.Period_End__c ;
        period1.AR_Subledger_Cutoff__c = period1.Period_End__c;
        period1.Shipment_Subledger_Cutoff__c = period1.Period_End__c;
        period1.Receiving_Subledger_Cutoff__c = period1.Period_End__c;
        period1.FA_Subledger_Cutoff__c = period1.Period_End__c;
        period1.Inventory_Subledger_Cutoff__c = period1.Period_End__c;
        period1.Period_Cut_Off__c = period1.Period_End__c;
        return period1;
    }
    */
  
    public static void insertSKIDQuantityToStock(TestData data ) { 
        List<SKID__c> sk = new List<SKID__c>();
        for (Item__c item : data.itemList) {
            SKID__c skid = new SKID__c();
            skid.location__c = data.location3.id;  // this is STOCK
            skid.Company__c= data.company.id;
            skid.Quantity__c = 200.0;
            skid.Quantity_Stocking_UOM__c = 200.0;
            skid.Item__c= item.Id;
            skid.Type__c = 'Location';
            skid.Expiration_Date__c = System.today() + 30;
            skid.Packaging_UOM__c =data.uomList[8].Id;
            skid.Stocking_UOM__c = data.uomList[8].Id;
            sk.add(skid);
        }
        insert sk;
    }
    //  public static String uniqueString () { return String.valueOf(System.currentTimeMillis()); } 
  
 
}