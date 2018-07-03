public class FixedAssetData{
      
    public TestData td = new TestData();
    public Tax_Book__c corp, state;
    public Asset_Class__c slac, ddac200, ddac150, syac, mcac;
    public Asset_Class_Rule__c slacCorp, ddac200Corp, syacCorp, mcacCorp, slacState, ddac200State, syacState, mcacState;
    public Fixed_Asset__c slfa, ddfa200, ddfa150, syfa, mcfa;
    public List<Asset_Class__c> insertAssetClasses;
    public List<Fixed_Asset__c> insertFixedAssets;
    public List<Tax_Book__c> insertTaxBooks;
    public List<Asset_Class_Rule__c> insertAssetClassRules;
    
    public FixedAssetData(){
      updateTaxBooks();
      updateAssetClasses();
      updateAssetClassRules();
      updateFixedAssets();
    }
    
    public FixedAssetData(boolean createAssets){
      updateTaxBooks();
      updateAssetClasses();
      updateAssetClassRules();
    }
    
    public void updateTaxBooks(){
      
      insertTaxbooks = new List<Tax_Book__c>();
      
      corp = new Tax_Book__c();
      corp.name = 'Corporate';
      corp.active__c = true;
      corp.corporate__c = true;
      corp.company__c = td.company.Id;
      insertTaxbooks.add(corp);
      
      state = new Tax_Book__c();
      state.name = 'State';
      state.active__c = true;
      state.corporate__c = false;
      state.company__c = td.company.Id;
      insertTaxbooks.add(state);
      
      insert insertTaxbooks;
      
      state.tax_book__c = corp.Id;
      update state;
    }
    
      
      public void updateAssetClasses(){
        
        insertAssetClasses = new List<Asset_Class__c>();
        
        slac = new Asset_Class__c();
        slac.Depreciation_Method__c = 'Straight Line';
        slac.Depreciation_Period__c = 'Monthly';
        slac.Depreciation_Convention__c = 'Full Month';
        slac.Name = 'SL Property';
        slac.GL_Account__c = td.acctData.longTermGL.Id;
        slac.Life_in_Months__c = 60;
        slac.Company__c = td.company.Id;
        insertAssetClasses.add(slac);
        
        
        ddac200 = new Asset_Class__c();
        ddac200.Depreciation_Method__c = 'Declining Balance';
        ddac200.Depreciation_Period__c = 'Monthly';
        ddac200.Declining_Balance__c = '200%';
        ddac200.Depreciation_Convention__c = 'Full Month';
        ddac200.Name = 'DD200 Property';
        ddac200.GL_Account__c = td.acctData.longTermGL.Id;
        ddac200.Life_in_Months__c = 60;
        ddac200.Company__c = td.company.Id;
        insertAssetClasses.add(ddac200);
        
        ddac150 = new Asset_Class__c();
        ddac150.Depreciation_Method__c = 'Declining Balance';
        ddac150.Depreciation_Period__c = 'Monthly';
        ddac150.Declining_Balance__c = '150%';
        ddac150.Depreciation_Convention__c = 'Mid Month';
        ddac150.Name = 'DD150 Property';
        ddac150.GL_Account__c = td.acctData.longTermGL.Id;
        ddac150.Life_in_Months__c = 60;
        ddac150.Company__c = td.company.Id;
        insertAssetClasses.add(ddac150);
        
        syac = new Asset_Class__c();
        syac.Depreciation_Method__c = 'Sum of Years';
        syac.Depreciation_Period__c = 'Annually';
        syac.Depreciation_Convention__c = 'Full Year';
        syac.Name = 'SY Property';
        syac.GL_Account__c = td.acctData.longTermGL.Id;
        syac.Life_in_Months__c = 60;
        syac.Company__c = td.company.Id;
        insertAssetClasses.add(syac);
        
        mcac = new Asset_Class__c();
        mcac.Depreciation_Method__c = 'MACRS';
        mcac.Depreciation_Period__c = 'Monthly';
        mcac.Depreciation_Convention__c = 'Full Month';
        mcac.Declining_Balance__c = '150%';
        mcac.Name = 'MACRS Property';
        mcac.GL_Account__c = td.acctData.longTermGL.Id;
        mcac.Life_in_Months__c = 60;
        mcac.Company__c = td.company.Id;
        insertAssetClasses.add(mcac);
        
        insert insertAssetClasses;
      }
      
      public void updateFixedAssets(){
        Currency__c defaultCurr = [Select Id from Currency__c where Id =: td.company.Comp_Currency__c];
        insertFixedAssets = new List<Fixed_Asset__c>();
      
        slfa = new Fixed_Asset__c();
        slfa.company__c = td.company.Id;
        slfa.Asset_Class__c = slac.Id;
        slfa.Asset_Tag_Number__c = '1010101';
        slfa.Date_Purchased__c = system.today().addYears(-5);
        slfa.In_Service_Date__c = system.today().addYears(-5);
        slfa.Acquisition_Cost__c = 38000;
        slfa.Depreciation_Life__c = 60;
        slfa.Status__c = 'Active';
        slfa.Residual_Value__c = 2000;
        slfa.Fixed_Asset_Type__c = FixedAssetService.ASSET_ACCOUNTING;
        
        boolean sawException = false;
        try{
            insert slfa;
        }catch(Exception e){
            sawException = true;
        }
        system.assertEquals(true, sawException);

        slfa.Purchase_Price__c = slfa.Acquisition_Cost__c;
        slfa.Purchase_Currency__c = defaultCurr.Id;
        insertFixedAssets.add(slfa);
        
        ddfa200 = new Fixed_Asset__c();
        ddfa200.company__c = td.company.Id;
        ddfa200.Asset_Class__c = ddac200.Id;
        ddfa200.Asset_Tag_Number__c = '1010102';
        ddfa200.Date_Purchased__c = system.today().addYears(-5);
        ddfa200.In_Service_Date__c = system.today().addYears(-5);
        ddfa200.Acquisition_Cost__c = 38000;
        ddfa200.Purchase_Price__c = ddfa200.Acquisition_Cost__c;
        ddfa200.Purchase_Currency__c = defaultCurr.Id;
        ddfa200.Depreciation_Life__c = 60;
        ddfa200.Status__c = 'Active';
        ddfa200.Residual_Value__c = 2000;
        ddfa200.Fixed_Asset_Type__c = FixedAssetService.ASSET_ACCOUNTING;
        insertFixedAssets.add(ddfa200);
        
        ddfa150 = new Fixed_Asset__c();
        ddfa150.company__c = td.company.Id;
        ddfa150.Asset_Class__c = ddac150.Id;
        ddfa150.Asset_Tag_Number__c = '10101021';
        ddfa150.Date_Purchased__c = system.today().addYears(-5);
        ddfa150.In_Service_Date__c = system.today().addYears(-5);
        ddfa150.Acquisition_Cost__c = 38000;
        ddfa150.Purchase_Price__c = ddfa150.Acquisition_Cost__c;
        ddfa150.Purchase_Currency__c = defaultCurr.Id;
        ddfa150.Depreciation_Life__c = 60;
        ddfa150.Status__c = 'Active';
        ddfa150.Residual_Value__c = 2000;
        ddfa150.Fixed_Asset_Type__c = FixedAssetService.ASSET_ACCOUNTING;
        insertFixedAssets.add(ddfa150);
        
        syfa = new Fixed_Asset__c();
        syfa.company__c = td.company.Id;
        syfa.Asset_Class__c = syac.Id;
        syfa.Asset_Tag_Number__c = '1010103';
        syfa.Date_Purchased__c = system.today().addYears(-5);
        syfa.In_Service_Date__c = system.today().addYears(-5);
        syfa.Acquisition_Cost__c = 38000;
        syfa.Purchase_Price__c = syfa.Acquisition_Cost__c;
        syfa.Purchase_Currency__c = defaultCurr.Id;
        syfa.Depreciation_Life__c = 60;
        syfa.Status__c = 'Active';
        syfa.Residual_Value__c = 2000;
        syfa.Fixed_Asset_Type__c = FixedAssetService.ASSET_ACCOUNTING;
        insertFixedAssets.add(syfa);
        
        mcfa = new Fixed_Asset__c();
        mcfa.company__c = td.company.Id;
        mcfa.Asset_Class__c = mcac.Id;
        mcfa.Asset_Tag_Number__c = '1010104';
        mcfa.Date_Purchased__c = system.today().addYears(-5);
        mcfa.In_Service_Date__c = system.today().addYears(-5);
        mcfa.Acquisition_Cost__c = 38000;
        mcfa.Purchase_Price__c = mcfa.Acquisition_Cost__c;
        mcfa.Purchase_Currency__c = defaultCurr.Id;
        mcfa.Depreciation_Life__c = 60;
        mcfa.Status__c = 'Active';
        mcfa.Residual_Value__c = 2000;
        mcfa.Fixed_Asset_Type__c = FixedAssetService.ASSET_ACCOUNTING;
        insertFixedAssets.add(mcfa);
        
        insert insertFixedAssets;
      }
      
      public Supplier_Invoice__c si; {
        si = new Supplier_Invoice__c();
      si.Company__c = td.company.Id;
      si.Supplier__c = td.remittosupplier.Id;
      si.Currency__c = TestFuel.currencyUSD.id;
      si.date_invoiced__c = system.now();
      si.Status__c = 'In Process';
      //si.Finalized__c = true;
      si.invoice_amount__c = 3000;
      si.supplier_invoice__c = '1010110';
      insert si;
      }
    
    public Supplier_Invoice_Line__c ril1;{
      ril1 = new Supplier_Invoice_Line__c();
      ril1.supplier_invoice__c = si.Id;
      ril1.purchase_order_line__c = td.purchaseOrder.purchase_order_lines__r[0].Id;
      ril1.Purchase_Order__c = td.purchaseOrder.Id;
      ril1.Quantity_Received__c = 10;
      ril1.unit_price__c = 100;
      ril1.extended_cost__c = 1000;
      ril1.invoice_quantity__c = 10;
      ril1.unit_price__c = 100; //KNDY-14371
      //ril1.status__c = 'Closed';
      ril1.track_as_asset__c = 'Yes';
      insert ril1;
    }
    
    public Supplier_Invoice_Line__c ril2;{
      ril2 = new Supplier_Invoice_Line__c();
      ril2.supplier_invoice__c = si.Id;
      ril2.purchase_order_line__c = td.purchaseOrder.purchase_order_lines__r[0].Id;
      ril2.Purchase_Order__c = td.purchaseOrder.Id;
      ril2.Quantity_Received__c = 10;
      ril2.unit_price__c = 200;
      ril2.extended_cost__c = 2000;
      ril2.invoice_quantity__c = 10;
      ril2.unit_price__c = 200; //KNDY-14371
      //ril2.status__c = 'Closed';
      ril2.track_as_asset__c = 'Yes';
      insert ril2;
    }
    
    public void updateAssetClassRules(){
      
      insertAssetClassRules = new List<Asset_Class_Rule__c>();
      
      slacCorp = new Asset_Class_Rule__c();
      slacCorp.company__c = td.company.Id;
      slacCorp.tax_book__c = corp.Id;
      slacCorp.start_date__c = date.newInstance(system.today().addYears(-5).year(), 1, 1);
      slacCorp.end_date__c = date.newInstance(system.today().year(), 12, 31);
      slacCorp.asset_class__c = slac.Id;
      slacCorp.depreciation_method__c = slac.depreciation_method__c;
      slacCorp.depreciation_convention__c = slac.depreciation_convention__c;
      slacCorp.declining_balance__c = slac.declining_balance__c;
      slacCorp.depreciation_period__c = slac.depreciation_period__c;
      slacCorp.life_in_months__c = slac.life_in_months__c;
      insertAssetClassRules.add(slacCorp);
      
      ddac200Corp = new Asset_Class_Rule__c();
      ddac200Corp.tax_book__c = corp.Id;
      ddac200Corp.company__c = td.company.Id;
      ddac200Corp.start_date__c = date.newInstance(system.today().addYears(-5).year(), 1, 1);
      ddac200Corp.end_date__c = date.newInstance(system.today().year(), 12, 31);
      ddac200Corp.asset_class__c = ddac200.Id;
      ddac200Corp.depreciation_method__c = slac.depreciation_method__c;
      ddac200Corp.depreciation_convention__c = slac.depreciation_convention__c;
      ddac200Corp.declining_balance__c = slac.declining_balance__c;
      ddac200Corp.depreciation_period__c = slac.depreciation_period__c;
      ddac200Corp.life_in_months__c = slac.life_in_months__c;
      insertAssetClassRules.add(ddac200Corp);
      
      syacCorp = new Asset_Class_Rule__c();
      syacCorp.tax_book__c = corp.Id;
      syacCorp.company__c = td.company.Id;
      syacCorp.start_date__c = date.newInstance(system.today().addYears(-5).year(), 1, 1);
      syacCorp.end_date__c = date.newInstance(system.today().year(), 12, 31);
      syacCorp.asset_class__c = syac.Id;
      syacCorp.depreciation_method__c = slac.depreciation_method__c;
      syacCorp.depreciation_convention__c = slac.depreciation_convention__c;
      syacCorp.declining_balance__c = slac.declining_balance__c;
      syacCorp.depreciation_period__c = slac.depreciation_period__c;
      syacCorp.life_in_months__c = slac.life_in_months__c;
      insertAssetClassRules.add(syacCorp);
      
      mcacCorp = new Asset_Class_Rule__c();
      mcacCorp.tax_book__c = corp.Id;
      mcacCorp.company__c = td.company.Id;
      mcacCorp.start_date__c = date.newInstance(system.today().addYears(-5).year(), 1, 1);
      mcacCorp.end_date__c = date.newInstance(system.today().year(), 12, 31);
      mcacCorp.asset_class__c = mcac.Id;
      mcacCorp.depreciation_method__c = slac.depreciation_method__c;
      mcacCorp.depreciation_convention__c = slac.depreciation_convention__c;
      mcacCorp.declining_balance__c = slac.declining_balance__c;
      mcacCorp.depreciation_period__c = slac.depreciation_period__c;
      mcacCorp.life_in_months__c = slac.life_in_months__c;
      insertAssetClassRules.add(mcacCorp);
      
      slacState = new Asset_Class_Rule__c();
      slacState.tax_book__c = state.Id;
      slacState.company__c = td.company.Id;
      slacState.start_date__c = date.newInstance(system.today().addYears(-5).year(), 1, 1);
      slacState.end_date__c = date.newInstance(system.today().year(), 12, 31);
      slacState.asset_class__c = slac.Id;
      slacState.depreciation_method__c = slac.depreciation_method__c;
      slacState.depreciation_convention__c = slac.depreciation_convention__c;
      slacState.declining_balance__c = slac.declining_balance__c;
      slacState.depreciation_period__c = slac.depreciation_period__c;
      slacState.life_in_months__c = slac.life_in_months__c;
      insertAssetClassRules.add(slacState);
      
      ddac200State = new Asset_Class_Rule__c();
      ddac200State.tax_book__c = state.Id;
      ddac200State.company__c = td.company.Id;
      ddac200State.start_date__c = date.newInstance(system.today().addYears(-5).year(), 1, 1);
      ddac200State.end_date__c = date.newInstance(system.today().year(), 12, 31);
      ddac200State.asset_class__c = ddac200.Id;
      ddac200State.depreciation_method__c = slac.depreciation_method__c;
      ddac200State.depreciation_convention__c = slac.depreciation_convention__c;
      ddac200State.declining_balance__c = slac.declining_balance__c;
      ddac200State.depreciation_period__c = slac.depreciation_period__c;
      ddac200State.life_in_months__c = slac.life_in_months__c;
      insertAssetClassRules.add(ddac200State);
      
      syacState = new Asset_Class_Rule__c();
      syacState.tax_book__c = state.Id;
      syacState.company__c = td.company.Id;
      syacState.start_date__c = date.newInstance(system.today().addYears(-5).year(), 1, 1);
      syacState.end_date__c = date.newInstance(system.today().year(), 12, 31);
      syacState.asset_class__c = syac.Id;
      syacState.depreciation_method__c = slac.depreciation_method__c;
      syacState.depreciation_convention__c = slac.depreciation_convention__c;
      syacState.declining_balance__c = slac.declining_balance__c;
      syacState.depreciation_period__c = slac.depreciation_period__c;
      syacState.life_in_months__c = slac.life_in_months__c;
      insertAssetClassRules.add(syacState);
      
      mcacState = new Asset_Class_Rule__c();
      mcacState.tax_book__c = state.Id;
      mcacState.company__c = td.company.Id;
      mcacState.start_date__c = date.newInstance(system.today().addYears(-5).year(), 1, 1);
      mcacState.end_date__c = date.newInstance(system.today().year(), 12, 31);
      mcacState.asset_class__c = mcac.Id;
      mcacState.depreciation_method__c = slac.depreciation_method__c;
      mcacState.depreciation_convention__c = slac.depreciation_convention__c;
      mcacState.declining_balance__c = slac.declining_balance__c;
      mcacState.depreciation_period__c = slac.depreciation_period__c;
      mcacState.life_in_months__c = slac.life_in_months__c;
      insertAssetClassRules.add(mcacState);
      
      insert insertAssetClassRules;
      
    }
    
  }