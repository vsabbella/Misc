@isTest
private class FixedAssetManageAdjustmentsExtTest {
    @testSetup 
    static void testDataSetup() {
        // Create Fixed Asset Data  
        Test.startTest();
        FixedAssetData fad = new FixedAssetData();
        Test.stopTest();
        GL_Account__c glAcc = [select id from GL_Account__c where Active__c = true limit 1];
        fad.si.Finalized__c = true;
        update fad.si;
         Supplier_Invoice__c si = [SELECT Id,Company__c,Company__r.accounting_Standard__c, invoice_amount__c,(Select Id from Supplier_Invoice_lines__r limit 1) FROM Supplier_Invoice__c WHERE supplier_invoice__c = '1010110' limit 1];
        list<Accounting_rule__c> allAccRules = [SELECT Id,Object__c,effective_Start_date__c,amount_reference__c,effective_end_date__c,Rule_Type__c, Transaction__c,SubTransaction_Type__c,Accounting_Standard__c,Default_GL_Account__c,GL_Account__c 
                                                FROM Accounting_rule__c];
         for(Accounting_rule__c line: allAccRules){
            line.Company__c = si.Company__c;
            line.accounting_Standard__c = si.Company__r.accounting_Standard__c;    
            if(line.Object_Name__c == 'Supplier_Invoice__c')  {
                line.Object__c = 'Supplier Invoice';
            }
            if(line.Transaction__c == 'Supplier Invoice')  {
                line.Transaction__c = 'Invoice';
            }   
            if(line.Object_Name__c == 'Fixed_Asset_Depreciation__c'){
                line.Object__c = 'Fixed Asset Depreciation';
            }
            if(line.GL_Account__c == null) 
                line.GL_Account__c = glAcc.Id;
            line.Default_GL_Account__c  = true;
        }
        update allAccRules;
    }
    
    static testMethod void testNewSingle() {
         test.starttest();
        Supplier_Invoice__c si = [SELECT Id,Company__c,currency__c,purchase_order__c, company__r.Default_Transaction_Currency__c ,company__r.comp_currency__c,Purchase_Order__r.Currency__c, company__r.Accounting_Standard__c, Invoice_type__c, transaction_date__c,posting_date__c, finalized__c, invoice_amount__c,finalized_date__c,(Select Id,Unit_Price__c from Supplier_Invoice_lines__r limit 1) FROM Supplier_Invoice__c WHERE supplier_invoice__c = '1010110'];
          company__c comp = [Select id,Default_Transaction_Currency__c,comp_currency__c from company__c where id =: si.company__c];
          comp.comp_currency__c = comp.Default_Transaction_Currency__c;
          update comp;
             si.finalized__c = false;
             si.finalized_hidden__c = false;
             update si;
             purchase_order__c po = [select id, currency__c from purchase_order__c limit 1];
             po.currency__c = si.company__r.comp_currency__c;
             update po;
             si.purchase_order__c = po.id;
             si.currency__c = si.company__r.comp_currency__c;   
             si.finalized__c = true;
             si.finalized_hidden__c = true; 
             update si;
        Asset_Class__c slac = [Select Id from Asset_Class__c where Name = 'SL Property'];
        
        SupplierInvoiceAccounting sAcc = new SupplierInvoiceAccounting();
        List<sObject> sObj = [Select Id,supplier_invoice__c from Supplier_Invoice_Line__c];
        sAcc.execute(sObj);
        
        test.setCurrentPage(Page.FixedAssetManageAdjustments);
        
        Fixed_Asset__c fa = new Fixed_Asset__c();
        
        FixedAssetManageAdjustmentsExt ext = new FixedAssetManageAdjustmentsExt(new Apexpages.Standardcontroller(fa));
        ext.RILDetails[0].selected = true;
        
        ext.selectedRIL = ext.RILDetails[0].ril.Id;
        
        ext.selectedAction = 'SINGLE';
        
        ext.updateAction(); 
        
        system.assert(ext.fa != null);
        system.assert(ext.fa.acquisition_cost__c == ext.RILDetails[0].ril.Accounting_Entry_Lines__r[0].Comp_Functional_Currency_Amount_DR__c);
        system.assert(ext.fa.units__c == ext.RILDetails[0].ril.Invoice_Quantity__c);
        system.assert(ext.fa.Supplier_Invoice_line__c == si.Supplier_Invoice_lines__r[0].Id);
        system.assert(ext.RILDetails[0].ril.Id == si.Supplier_Invoice_lines__r[0].Id);
        
        ext.fa.name = 'test';
        ext.fa.Asset_Class__c = slac.Id;
        ext.fa.In_Service_Date__c = system.today();
        ext.fa.company__c = si.company__c;
        ext.fa.description__c = 'test';
        ext.save();
      
        Fixed_asset__c faSingle = [SELECT Id FROM Fixed_Asset__c WHERE Supplier_Invoice_line__c = :si.Supplier_Invoice_lines__r[0].Id limit 1];
        system.assert(faSingle.Id != null);
          test.stoptest();
    }
    
    static testMethod void testNewGroup() {
         test.starttest();
        Supplier_Invoice__c si = [SELECT Id,Company__c,currency__c,purchase_order__c, company__r.Default_Transaction_Currency__c ,company__r.comp_currency__c,Purchase_Order__r.Currency__c, company__r.Accounting_Standard__c, Invoice_type__c, transaction_date__c,posting_date__c, finalized__c, invoice_amount__c,finalized_date__c,(Select Id,Unit_Price__c from Supplier_Invoice_lines__r limit 1) FROM Supplier_Invoice__c WHERE supplier_invoice__c = '1010110'];
          company__c comp = [Select id,Default_Transaction_Currency__c,comp_currency__c from company__c where id =: si.company__c];
          comp.comp_currency__c = comp.Default_Transaction_Currency__c;
          update comp;
             si.finalized__c = false;
             si.finalized_hidden__c = false;
             update si;
             purchase_order__c po = [select id, currency__c from purchase_order__c limit 1];
             po.currency__c = si.company__r.comp_currency__c;
             update po;
             si.purchase_order__c = po.id;
             si.currency__c = si.company__r.comp_currency__c;   
             si.finalized__c = true;
             si.finalized_hidden__c = true; 
             update si;
        Asset_Class__c slac = [Select Id from Asset_Class__c where Name = 'SL Property'];
        
        SupplierInvoiceAccounting sAcc = new SupplierInvoiceAccounting();
        List<sObject> sObj = [Select Id,supplier_invoice__c from Supplier_Invoice_Line__c];
        sAcc.execute(sObj);
        
            test.setCurrentPage(Page.FixedAssetManageAdjustments);
            
            Fixed_Asset__c fa = new Fixed_Asset__c();
            
            FixedAssetManageAdjustmentsExt ext = new FixedAssetManageAdjustmentsExt(new Apexpages.Standardcontroller(fa));
            
            system.assert(ext.RILDetails.size() == 2);
            
            ext.RILDetails[0].selected = true;
            ext.RILDetails[1].selected = true;
            
            ext.selectedAction = 'GROUP';
            
            ext.updateAction();
            
            system.assert(ext.fa != null);
            ext.fa.name = 'test';
            ext.fa.Asset_Class__c = slac.Id;
            ext.fa.In_Service_Date__c = system.today();
            ext.fa.company__c = si.company__c;
            ext.fa.description__c = 'test';
            
            ext.save();
       
        system.assert(ext.fa.Id != null);
         test.stoptest();
    }
    
    static testMethod void testNewCustom() {
        test.startTest();
       Supplier_Invoice__c si = [SELECT Id,Company__c,currency__c,purchase_order__c, company__r.Default_Transaction_Currency__c ,company__r.comp_currency__c,Purchase_Order__r.Currency__c, company__r.Accounting_Standard__c, Invoice_type__c, transaction_date__c,posting_date__c, finalized__c, invoice_amount__c,finalized_date__c,(Select Id,Unit_Price__c from Supplier_Invoice_lines__r limit 1) FROM Supplier_Invoice__c WHERE supplier_invoice__c = '1010110'];
          company__c comp = [Select id,Default_Transaction_Currency__c,comp_currency__c from company__c where id =: si.company__c];
          comp.comp_currency__c = comp.Default_Transaction_Currency__c;
          update comp;
             si.finalized__c = false;
             si.finalized_hidden__c = false;
             update si;
             purchase_order__c po = [select id, currency__c from purchase_order__c limit 1];
             po.currency__c = si.company__r.comp_currency__c;
             update po;
             si.purchase_order__c = po.id;
             si.currency__c = si.company__r.comp_currency__c;   
             si.finalized__c = true;
             si.finalized_hidden__c = true; 
             update si;
        Asset_Class__c slac = [Select Id from Asset_Class__c where Name = 'SL Property'];
        
        SupplierInvoiceAccounting sAcc = new SupplierInvoiceAccounting();
        List<sObject> sObj = [Select Id,supplier_invoice__c from Supplier_Invoice_Line__c];
        sAcc.execute(sObj);
        test.setCurrentPage(Page.FixedAssetManageAdjustments);
        
        Fixed_Asset__c fa = new Fixed_Asset__c();
        
        FixedAssetManageAdjustmentsExt ext = new FixedAssetManageAdjustmentsExt(new Apexpages.Standardcontroller(fa));
        
        system.assert(ext.RILDetails.size() == 2);
        
        ext.RILDetails[0].selected = true;
        
        ext.selectedRIL = ext.RILDetails[0].ril.Id;
        
        ext.selectedAction = 'CUSTOM';
        
        ext.updateAction();
        
        system.assert(ext.fas.size() == 1);
        
        //Populate the new fixed asset details
        ext.fas[0].name = 'test';
        ext.fas[0].Asset_Class__c = slac.Id;
        ext.fas[0].In_Service_Date__c = system.today();
        ext.fas[0].company__c = si.Company__c;
        ext.fas[0].description__c = 'test';
        ext.fas[0].acquisition_cost__c = 500;
        
        ext.addAdditional();
        
        system.assert(ext.fas.size() == 2);
        
        ext.fas[1].name = 'test1';
        ext.fas[1].Asset_Class__c = slac.Id;
        ext.fas[1].In_Service_Date__c = system.today();
        ext.fas[1].company__c = si.Company__c;
        ext.fas[1].description__c = 'test1';
        ext.fas[1].acquisition_cost__c = 500;
        
        ext.save();
        
        List<Fixed_Asset__c> fasCustom = [SELECT Id, (SELECT Id, amount__c, fixed_asset__c FROM Fixed_Asset_Adjustments__r) FROM Fixed_Asset__c WHERE Supplier_Invoice_line__c = :si.Supplier_Invoice_lines__r[0].Id];
        for(Fixed_Asset__c fc : fasCustom){
            for(Fixed_Asset_Adjustment__c adj : fc.Fixed_Asset_Adjustments__r){
                system.assert(adj.amount__c == 500);
            }
        }
        test.stoptest();
    }
    
    static testMethod void testNewMultiple() {
          test.starttest();
        Supplier_Invoice__c si = [SELECT Id,Company__c,currency__c,purchase_order__c, company__r.Default_Transaction_Currency__c ,company__r.comp_currency__c,Purchase_Order__r.Currency__c, company__r.Accounting_Standard__c, Invoice_type__c, transaction_date__c,posting_date__c, finalized__c, invoice_amount__c,finalized_date__c,(Select Id,Unit_Price__c from Supplier_Invoice_lines__r limit 1) FROM Supplier_Invoice__c WHERE supplier_invoice__c = '1010110'];
          company__c comp = [Select id,Default_Transaction_Currency__c,comp_currency__c from company__c where id =: si.company__c];
          comp.comp_currency__c = comp.Default_Transaction_Currency__c;
          update comp;
             si.finalized__c = false;
             si.finalized_hidden__c = false;
             update si;
             purchase_order__c po = [select id, currency__c from purchase_order__c limit 1];
             po.currency__c = si.company__r.comp_currency__c;
             update po;
             si.purchase_order__c = po.id;
             si.currency__c = si.company__r.comp_currency__c;   
             si.finalized__c = true;
             si.finalized_hidden__c = true; 
             update si;
        Asset_Class__c slac = [Select Id from Asset_Class__c where Name = 'SL Property'];
        
        SupplierInvoiceAccounting sAcc = new SupplierInvoiceAccounting();
        List<sObject> sObj = [Select Id,supplier_invoice__c from Supplier_Invoice_Line__c];
        sAcc.execute(sObj);
        
        
      
        test.setCurrentPage(Page.FixedAssetManageAdjustments);
        
        Fixed_Asset__c fa = new Fixed_Asset__c();
        
        FixedAssetManageAdjustmentsExt ext = new FixedAssetManageAdjustmentsExt(new Apexpages.Standardcontroller(fa));
        
        system.assert(ext.RILDetails.size() == 2);
        
        ext.RILDetails[0].selected = true;
        
        ext.selectedRIL = ext.RILDetails[0].ril.Id;
        
        ext.selectedAction = 'MULTIPLE';
        
        ext.updateAction();
        
        system.assert(ext.fas.size() == 10);
        
        //Populate the new fixed asset details
        for(integer i=0; i<10; i++){
            ext.fas[i].name = 'test';
            ext.fas[i].Asset_Class__c = slac.Id;
            ext.fas[i].In_Service_Date__c = system.today();
            ext.fas[i].company__c = si.Company__c;
            ext.fas[i].description__c = 'test';
            ext.fas[i].acquisition_cost__c = 500;
        }
        
        
        ext.save();
       
        List<Fixed_Asset__c> fasCustom = [SELECT Id FROM Fixed_Asset__c WHERE Supplier_Invoice_line__r.Supplier_Invoice__c = :si.Id];
        system.assert(fasCustom.size() == 20);
        test.stoptest();
    }
    
    static testMethod void testAdjust() {
        test.starttest();
        Supplier_Invoice__c si = [SELECT Id,Company__c,currency__c,purchase_order__c, company__r.Default_Transaction_Currency__c ,company__r.comp_currency__c,Purchase_Order__r.Currency__c, company__r.Accounting_Standard__c, Invoice_type__c, transaction_date__c,posting_date__c, finalized__c, invoice_amount__c,finalized_date__c,(Select Id,Unit_Price__c from Supplier_Invoice_lines__r limit 1) FROM Supplier_Invoice__c WHERE supplier_invoice__c = '1010110'];
          company__c comp = [Select id,Default_Transaction_Currency__c,comp_currency__c from company__c where id =: si.company__c];
          comp.comp_currency__c = comp.Default_Transaction_Currency__c;
          update comp;
             si.finalized__c = false;
             si.finalized_hidden__c = false;
             update si;//unfinalizing the si to make changes
             purchase_order__c po = [select id, currency__c from purchase_order__c limit 1];
             po.currency__c = si.company__r.comp_currency__c;
             update po;
             si.purchase_order__c = po.id;
             si.currency__c = si.company__r.comp_currency__c;   
             si.finalized__c = true;
             si.finalized_hidden__c = true;
             update si;//finalizing the si after changing the currency.
        Asset_Class__c slac = [Select Id from Asset_Class__c where Name = 'SL Property'];
        
       SupplierInvoiceAccounting sAcc = new SupplierInvoiceAccounting();
        List<sObject> sObj = [Select Id,supplier_invoice__c from Supplier_Invoice_Line__c ];
        sAcc.execute(sObj);
        List<Period__c> prds = [Select Id,period_start__c,period_end__c,open__c from Period__c];
        test.setCurrentPage(Page.FixedAssetManageAdjustments);
        
        Fixed_Asset__c fa = new Fixed_Asset__c();
        fa.name = 'test';
        fa.Asset_Class__c = slac.Id;
        fa.In_Service_Date__c = system.today();
        fa.company__c = si.Company__c;
        fa.description__c = 'test';
        fa.acquisition_cost__c = 10000;
        fa.Purchase_Price__c = fa.Acquisition_Cost__c;
        fa.Purchase_Currency__c = comp.comp_currency__c;
        insert fa;
        FixedAssetManageAdjustmentsExt ext = new FixedAssetManageAdjustmentsExt(new Apexpages.Standardcontroller(fa));
        system.assert(ext.RILDetails.size() == 2);
        ext.RILDetails[0].selected = true;
        ext.selectedRIL = ext.RILDetails[0].ril.Id;
        ext.selectedAction = 'ADJUST';
        ext.updateAction();
        ext.newAdjustments[0].amount__c = 1000;
        ext.newAdjustments[0].type__c = 'Adjustment';
        ext.newAdjustments[0].adjustment_Date__c = system.today();
        ext.save();
        Fixed_Asset__c checkFA = [SELECT Id, acquisition_cost__c, total_adjustments__c, (SELECT Id FROM Fixed_Asset_Adjustments__r)  FROM fixed_asset__c WHERE Id = :fa.Id];
        system.assert(checkFA.total_adjustments__c == 1000);
        system.assert(checkFA.acquisition_cost__c == fa.acquisition_cost__c );//We are not updating aquistion cost upon adding adjustment
        system.assertNotEquals(0,checkFA.Fixed_Asset_Adjustments__r.size(), 'We should have an adjustment');
       test.stoptest();
    }
    static testMethod void testInvalidAdjust() {
        test.startTest();
        Supplier_Invoice__c si = [SELECT Id,Company__c,Company__r.comp_currency__c,Company__r.accounting_Standard__c, invoice_amount__c,(Select Id from Supplier_Invoice_lines__r limit 1) FROM Supplier_Invoice__c WHERE supplier_invoice__c = '1010110' limit 1];
        Fixed_Asset__c fa = [select id,company__c,company__r.accounting_Standard__c,Acquisition_Cost__c from fixed_asset__c where status__c = 'Active' limit 1];
        fa.in_service_Date__c = system.today().addMonths(-1).toStartOfMonth();
        fa.Purchase_Currency__c = si.Company__r.comp_currency__c;
        fa.Purchase_Price__c = fa.Acquisition_Cost__c;
        update fa;  
        
        SupplierInvoiceAccounting sAcc = new SupplierInvoiceAccounting();
        List<sObject> sObj = [Select Id,supplier_invoice__c from Supplier_Invoice_Line__c];
        sAcc.execute(sObj);
        test.setCurrentPage(Page.FixedAssetManageAdjustments);
        FixedAssetService.capitalizeFixedAssets(new Set<Id>{fa.Id});

        List<Fixed_Asset_Depreciation__c> fads = [SELECT Id,fixed_asset__r.Date_Last_Depreciated__c FROM Fixed_Asset_Depreciation__c WHERE Fixed_Asset__c =: fa.id];
        system.assert(fads!=null && fads.size()> 0);
        
        FixedAssetManageAdjustmentsExt ext = new FixedAssetManageAdjustmentsExt(new Apexpages.Standardcontroller(fa));
        
        system.assert(ext.RILDetails.size() == 2);
        
        
        ext.RILDetails[0].selected = true;
        
        ext.selectedRIL = ext.RILDetails[0].ril.Id;
        
        ext.selectedAction = 'ADJUST';
        
        ext.updateAction();
        ext.newAdjustments[0].amount__c = 1000;
        ext.newAdjustments[0].type__c = 'Adjustment';
        ext.newAdjustments[0].Adjustment_Date__c = system.today().addmonths(-5);
        
        ext.save();
        system.assertEquals(apexpages.getMessages().size()>0 && apexpages.getMessages()[0].getSummary().contains('date is invalid for the fixed asset adjustment because it is in a period that has depreciation'),true,'Expecting exception as adjustment date is in depreciated period for the asset.');  
        test.stopTest();
    }
    

    static testMethod void testInvalidManualAdjustment() {
        
        test.startTest();
        Fixed_Asset__c fa = [select id, name,status__c, acquisition_cost__c,Date_Last_Depreciated__c, company__c, company__r.Default_Transaction_Currency__c,Company__r.accounting_Standard__c,company__r.Comp_Currency__c
                             from fixed_asset__c WHERE Asset_Tag_Number__c = '1010101' limit 1];

        fa.in_service_Date__c = system.today().addMonths(-1).toStartOfMonth();
        fa.Purchase_Price__c = fa.Acquisition_Cost__c;
        fa.Purchase_Currency__c = fa.company__r.Comp_Currency__c;
        update fa;  
         list<Accounting_rule__c> accRules = [select Id,Object__c,effective_Start_date__c,amount_reference__c,effective_end_date__c,Rule_Type__c, Transaction__c,SubTransaction_Type__c,Accounting_Standard__c,Default_GL_Account__c,GL_Account__c from Accounting_rule__c];
         for(Accounting_rule__c line: accRules){
            line.Company__c = fa.Company__c;
            line.accounting_Standard__c = fa.Company__r.accounting_Standard__c;            
        }
        update accRules;
        FixedAssetService.capitalizeFixedAssets(new Set<Id>{fa.Id});
        Fixed_Asset__c faAfterDep = [SELECT id, name,status__c, acquisition_cost__c,Date_Last_Depreciated__c, company__c, company__r.Default_Transaction_Currency__c,company__r.Comp_Currency__c
                                        FROM Fixed_Asset__c 
                                        WHERE Asset_Tag_Number__c = '1010101' limit 1];
                            
        List<Fixed_Asset_Depreciation__c> fads = [SELECT Id,fixed_asset__c,fixed_asset__r.Date_Last_Depreciated__c,depreciation_date__c FROM Fixed_Asset_Depreciation__c WHERE Fixed_Asset__c =: fa.id];
        system.assert(fads!=null && fads.size()> 0);
        Test.setCurrentPage( Page.FixedAssetManualAdjustment);      
        Apexpages.StandardController con            = new Apexpages.StandardController(faAfterDep);
        FixedAssetManualAdjustmentExt faaManualAdj  = new FixedAssetManualAdjustmentExt(con); 
        faaManualAdj.getReturnUrl();
        List<Fixed_Asset_Adjustment__c> currentAdjustment = new List<Fixed_Asset_Adjustment__c>{
                                                                                new Fixed_Asset_Adjustment__c(Fixed_Asset__c=faAfterDep.id, Company__c =faAfterDep.Company__c,
                                                                                Currency__c=faAfterDep.company__r.Default_Transaction_Currency__c,Amount__c=1000,
                                                                                type__c = 'Upgrade',Adjustment_Date__c=system.today().addmonths(-5))};
            
       faaManualAdj.faAdjustmentsList.clear();
       faaManualAdj.faAdjustmentsList =  currentAdjustment;
       faaManualAdj.saveAndNew();
       
       system.assertEquals(apexpages.getMessages().size()>0 && apexpages.getMessages()[0].getSummary().contains('date is invalid for the fixed asset adjustment because it is in a period that has depreciation'),true,'Expecting exception as adjustment date is in depreciated period for the asset.');  
        test.stopTest();       
        
     }


    //#---------KNDY-12786-----------
     static testMethod void testManualAdjustment() {
        test.startTest();

            Fixed_Asset__c fa = [SELECT id, name, acquisition_cost__c,Date_Last_Depreciated__c, company__r.Comp_Currency__c,
                                        status__c,company__c, company__r.Default_Transaction_Currency__c,Company__r.accounting_Standard__c
                                FROM Fixed_Asset__c 
                                WHERE Asset_Tag_Number__c = '1010101' limit 1];
            list<Accounting_rule__c> accRules = [select Id,Object__c,effective_Start_date__c,amount_reference__c,effective_end_date__c,Rule_Type__c, Transaction__c,SubTransaction_Type__c,Accounting_Standard__c,Default_GL_Account__c,GL_Account__c from Accounting_rule__c];
         for(Accounting_rule__c line: accRules){
            line.Company__c = fa.Company__c;
            line.accounting_Standard__c = fa.Company__r.accounting_Standard__c;            
        }
         update accRules;
        SupplierInvoiceAccounting sAcc = new SupplierInvoiceAccounting();
        List<sObject> sObj = [Select Id,supplier_invoice__c from Supplier_Invoice_Line__c];
        sAcc.execute(sObj);
            Test.setCurrentPage( Page.FixedAssetManualAdjustment);      
            Apexpages.StandardController con            = new Apexpages.StandardController(fa);
            FixedAssetManualAdjustmentExt faaManualAdj  = new FixedAssetManualAdjustmentExt(con);
            
            
            faaManualAdj.getReturnUrl();

            List<Fixed_Asset_Adjustment__c> currentAdjustment = new List<Fixed_Asset_Adjustment__c>{
                                                                   new Fixed_Asset_Adjustment__c(Fixed_Asset__c=fa.id, 
                                                                                                 Company__c =fa.Company__c,
                                                                                                 Currency__c=fa.company__r.Default_Transaction_Currency__c,
                                                                                                 type__c = 'Upgrade',adjustment_date__c=system.today())}; 
            
            currentAdjustment[0].Amount__c = 1000;
            faaManualAdj.faAdjustmentsList =  currentAdjustment;
            faaManualAdj.saveAndNew();
            faaManualAdj.CancelGoBack();
        
        

        Fixed_Asset__c faAfterAdjustment      =  [SELECT Id, acquisition_cost__c, total_adjustments__c,Total_Depreciated_Value__c,Residual_Value__c,book_Value__c,Depreciable_Basis__c,
                                                     (SELECT Id 
                                                        FROM Fixed_Asset_Adjustments__r)  
                                                  FROM fixed_asset__c 
                                                  WHERE Id = :fa.Id];


        system.assert(faAfterAdjustment.total_adjustments__c == 1000);
        //KNDY-13139 We are not updating aquistion cost on adding /undoing/unfinalizing/finalizing adjustments. 
        //We are updating Book Value and depreciable basis instead. 
        system.assert(faAfterAdjustment.acquisition_cost__c == fa.acquisition_cost__c );
        system.assert(faAfterAdjustment.book_Value__c == ((fa.acquisition_cost__c + faAfterAdjustment.total_adjustments__c) - faAfterAdjustment.Total_Depreciated_Value__c));
        system.assert(faAfterAdjustment.Depreciable_Basis__c == ((fa.acquisition_cost__c + faAfterAdjustment.total_adjustments__c) - faAfterAdjustment.Residual_Value__c));
        system.assertNotEquals(0,faAfterAdjustment.Fixed_Asset_Adjustments__r.size(), 'We should have an adjustment');                      
        test.stopTest();
     }

    
     static testMethod void testInvalidFinalizeUnfinalizeManualAdjustment() {
        test.startTest();
        Fixed_Asset__c fa = [SELECT status__c, Company__r.Comp_Currency__c,Company__r.accounting_Standard__c,
                                    id, name, depreciation_method__c, depreciation_period__c, estimated_end_of_life__c, in_service_date__c, 
                                    acquisition_cost__c, residual_value__c, date_last_depreciated__c, book_value__c, Fixed_Asset_Key__c,
                                    company__c, company__r.Default_Transaction_Currency__c, Final_Depreciation_Date__c, depreciation_count__c,
                                    Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, Total_Depreciated_Value__c,Prorate_First_Period__c
                            FROM Fixed_Asset__c 
                            WHERE Asset_Tag_Number__c = '1010101' LIMIT 1];
         list<Accounting_rule__c> accRules = [select Id,Object__c,effective_Start_date__c,amount_reference__c,effective_end_date__c,Rule_Type__c, Transaction__c,SubTransaction_Type__c,Accounting_Standard__c,Default_GL_Account__c,GL_Account__c from Accounting_rule__c];
         for(Accounting_rule__c line: accRules){
            line.Company__c = fa.Company__c;
            line.accounting_Standard__c = fa.Company__r.accounting_Standard__c;            
        }
         update accRules;
        SupplierInvoiceAccounting sAcc = new SupplierInvoiceAccounting();
        List<sObject> sObj = [Select Id,supplier_invoice__c from Supplier_Invoice_Line__c];
        sAcc.execute(sObj);
        Test.setCurrentPage( Page.FixedAssetManualAdjustment);      
        Apexpages.StandardController con            = new Apexpages.StandardController(fa);
        FixedAssetManualAdjustmentExt faaManualAdj  = new FixedAssetManualAdjustmentExt(con); 
        faaManualAdj.getReturnUrl();
        Fixed_Asset_Adjustment__c fad1 = new Fixed_Asset_Adjustment__c(Fixed_Asset__c=fa.id, Company__c =fa.Company__c,
                                                                                Currency__c=fa.company__r.Default_Transaction_Currency__c,Amount__c=10,
                                                                                type__c = 'Upgrade',Adjustment_Date__c=system.today().addmonths(-5),Historical__c=false);
                                                                                
        Fixed_Asset_Adjustment__c fad2 = new Fixed_Asset_Adjustment__c(Fixed_Asset__c=fa.id, Company__c =fa.Company__c,
                                                                                Currency__c=fa.company__r.Default_Transaction_Currency__c,Amount__c=20,
                                                                                type__c = 'Upgrade',Adjustment_Date__c=system.today().addmonths(-5),Historical__c=false);                                                                            
                                                                                
        faaManualAdj.faAdjustmentsList.clear();//Remove the default  list item added on page load.
        faaManualAdj.faAdjustmentsList.add(fad1);
        faaManualAdj.faAdjustmentsList.add(fad2);
         
        faaManualAdj.faAdjustmentsList[0].Historical__c = false;        
        faaManualAdj.faAdjustmentsList[1].Historical__c = false;
        faaManualAdj.saveAndNew();
        list<Fixed_Asset_Adjustment__c> faaList = [select id,name from Fixed_Asset_Adjustment__c where Fixed_Asset__c = :fa.id];
        System.assertEquals(faaList.size()>0,true,'Expecting faa to be inserted');
        
        //Unfinalize fad2 so that we can try to refinalize after depreciation.       
        Map<Id, UnfinalizeService.UnfinalizeResponse> mResults = UnfinalizeService.unfinalizeSourcedocs(new list<Fixed_Asset_Adjustment__c>{fad2});
        System.assertEquals(mResults.get(fad2.Id).Success , true,'Expecting successful unfinalize');

        // Create Fixed Asset depreciations on the FA
        AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
        asld.execute(new List<sObject>{(sObject)fa}, system.today(), true);
        List<Fixed_Asset_Depreciation__c> fadList = [select id from Fixed_Asset_Depreciation__c where Fixed_asset__c =: fa.Id];
        system.debug(LoggingLevel.ERROR,'___fadList___'+fadList.size());
        //Try to refinalize fad2
        fad2.Finalized__c=true;
        Boolean sawFinalizeException = false;
        Boolean sawUnFinalizeException = false;
        try{
            update fad2;            
        }catch(Exception ex){
            sawFinalizeException = true;
        }
        System.assertEquals(sawFinalizeException, true,'Expecting unsuccessful finalize as depreciation records exist.');   
        
        //Try finalizing fad1.  
        try{
          Map<Id, UnfinalizeService.UnfinalizeResponse> mResults1 = UnfinalizeService.unfinalizeSourcedocs(new list<Fixed_Asset_Adjustment__c>{fad1});
            
        }catch(Exception ex){
            sawUnFinalizeException = true;
        }
        System.assertEquals(sawUnFinalizeException, true,'Expecting unsuccessful unfinalize as depreciation records exist.');   
        test.stopTest();        
     }
    
}