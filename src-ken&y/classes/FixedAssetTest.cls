@isTest
public class FixedAssetTest { 
 
  //moving all test data setup for all methods in this class
    @testSetup
    static void testDataSetUpForThisTestClass() {
     DML.systemTime = system.now().addMinutes(-20);
     List<Configuration__c> configList = new List<Configuration__c>();
     List<sObjectType> skipTriggers = new List<sObjectType>{Work_Order__c.sObjectType};
        
    
     for (sObjectType s:skipTriggers) {
         configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
     }
     insert configList;  
     FixedAssetData fad = new FixedAssetData(); 
     delete configList;  
    }
     public static List<Fixed_Asset__c> fixedAssets = [SELECT id, name,asset_class__c,depreciation_method__c, depreciation_period__c,Prorate_First_Period__c,
                                                estimated_end_of_life__c, in_service_date__c,acquisition_cost__c, residual_value__c, date_last_depreciated__c, 
                                                book_value__c, Fixed_Asset_Key__c,company__c,company__r.Id, company__r.Default_Transaction_Currency__c, 
                                                company__r.Comp_currency__c, Final_Depreciation_Date__c, depreciation_count__c,Depreciation_Convention__c, depreciable_basis__c, 
                                                Asset_Tag_Number__c, Total_Depreciated_Value__c
                                            FROM Fixed_Asset__c 
                                            WHERE Fixed_Asset_Type__c like 'Accounting' limit 2];   
    

 static testMethod void testDepreciationsAndRollback() {
        test.startTest();
    
        FixedAssetDepreciationBatch fadBatch = new FixedAssetDepreciationBatch(new Set<Id>{fixedAssets[0].company__r.Id});
        database.executeBatch(fadBatch);
     
        //Test the VF controller extension to rollback a depreciation record
        //Fixed_Asset_Depreciation__c fadep = FixedAssetService.generateFixedAssetDepreciation(1000, system.today(), 38000, fad.insertFixedAssets[0], FixedAssetService.TYPE_DEPRECIATION);
        //insert fadep;
        
        pageReference currPage = new PageReference('/apex/FixedAssetDepreciationRollback?Id=' + fixedAssets[0].Id);
        Test.setCurrentPage(currPage);
        Apexpages.Standardcontroller fasc = new Apexpages.Standardcontroller(fixedAssets[0]);
        FixedAssetDepreciationRollbackExt rbExt = new FixedAssetDepreciationRollbackExt(fasc);
   
        List<Fixed_Asset_Depreciation__c> fads = [SELECT Id FROM Fixed_Asset_Depreciation__c WHERE Fixed_Asset__c = :fixedAssets[0].Id];
        integer originalFads = fads.size();
        rbExt = new FixedAssetDepreciationRollbackExt(fasc);
        
    
        //FIN-593 Changes
        try
        {
        rbExt.btn_Rollback();
        } catch(DmlException dmle) {            
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, dmle.getDmlType(0), 'Should fail, cannot delete finalized depreciation records.');
        }  
        
        fads = [SELECT Id FROM Fixed_Asset_Depreciation__c WHERE Fixed_Asset__c = :fixedAssets[0].Id];
        test.stopTest(); 
    }
    

    static testMethod void testCompanyWideDepreciationRollback(){ 
       test.startTest();
        System.debug(Logginglevel.ERROR, '1.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        Tax_Book__c corpTaxBook = [SELECT id,name FROM Tax_Book__c WHERE name like 'Corporate' limit 1];
        Gl_Account__c longTermGL = [SELECT id,name FROM Gl_Account__c WHERE Name like '28000 - Long Term' limit 1];
        Company__c comp = [select id,name from Company__c where id = :fixedAssets[0].company__r.Id limit 1];
        
            
        List<Fixed_Asset_Depreciation__c> fads = new List<Fixed_Asset_Depreciation__c>();
           
        for(integer i=0; i<51; i++){
            Fixed_Asset_Depreciation__c iFad = FixedAssetService.generateFixedAssetDepreciation(i, system.today() - i, 38000-i, fixedAssets[0], FixedAssetService.TYPE_DEPRECIATION);
            //overwrite the key as we're generating dummy records for bulk entry
            iFad.depreciation_key__c = string.valueOf(i);
            fads.add(iFad);
        }
       System.debug(Logginglevel.ERROR,'2.Number of Queries used in this apex code so far: ' + Limits.getQueries());
          
        insert fads;
        //Test the company wide VF controller extension to rollback a depreciation record
        Pagereference currPage = new PageReference('/apex/CompanyFixedAssetDepreciation?Id=' + fixedAssets[0].company__r.Id);
        Test.setCurrentPage(currPage);
        Apexpages.Standardcontroller cosc = new Apexpages.Standardcontroller(comp);
        CompanyFixedAssetDepreciationRollbackExt corbExt = new CompanyFixedAssetDepreciationRollbackExt(cosc); 
        
        corbExt.selectedBookId = corpTaxBook.Id;
        corbExt.updateFixedAssetDepreciations();
        
        corbExt.getFixedAssetDepreciations();
        corbExt.getPageNumber();
        corbExt.getHasNext();
        corbExt.getHasPrevious();
        corbExt.getNumberOfPages();
        corbExt.first();
        corbExt.previous();
        corbExt.next();
        corbExt.last();
        //test.starttest();
        corbExt.btn_Rollback();
    
        //Assert the batch initiated successfully
        system.assert(corbExt.disableRollback);
        
        List<Fixed_Asset__c> fixedAssetsAfterRollBack = [SELECT id, name, company__c, asset_class__c, asset_tag_number__c, 
                                                            date_purchased__c, acquisition_cost__c, depreciation_life__c,
                                                            status__c, residual_value__c, retirement_date__c, estimated_end_of_life__c, gl_account__c, 
                                                            depreciation_method__c, depreciation_period__c, depreciation_count__c, 
                                                            (SELECT id FROM Fixed_Asset_Depreciations__r)
                                                                FROM Fixed_Asset__c
                                                                WHERE Id = :fixedAssets[0].Id ];
        
        System.debug(Logginglevel.ERROR,'3.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        for(Fixed_Asset__c fa : fixedAssetsAfterRollBack){
            //Verify gl account population from trigger         
            system.assertEquals(fa.gl_account__c, longTermGL.Id);
            
            //Verify data end of life date populated from trigger
            system.assertNotEquals(fa.estimated_end_of_life__c, null);
        }
          test.stoptest();

    }
    
    static testMethod void testDateIncrements(){
        //Test the period methods in the FixedAssetService class
        Date testDate = system.today().addYears(-3);
        system.assertNotEquals(null, FixedAssetService.incrementPeriod(testDate, 'Monthly'), 'Should return a date');
        system.assertNotEquals(null, FixedAssetService.incrementPeriod(testDate, 'Daily'), 'Should return a date');
        system.assertNotEquals(null, FixedAssetService.incrementPeriod(testDate, 'Quarterly'), 'Should return a date');
        system.assertNotEquals(null, FixedAssetService.incrementPeriod(testDate, 'Bi-Monthly'), 'Should return a date');
        system.assertNotEquals(null, FixedAssetService.incrementPeriod(testDate, 'Semi-Annually'), 'Should return a date');
        system.assertNotEquals(null, FixedAssetService.incrementPeriod(testDate, 'Annually'), 'Should return a date');
        system.assertEquals(null, FixedAssetService.incrementPeriod(testDate, 'NoResult'), 'Should return null');
        
        system.assertNotEquals(null, FixedAssetService.returnPeriodCount(testDate, system.today(), 'Monthly'), 'Should return a date');
        system.assertNotEquals(null, FixedAssetService.returnPeriodCount(testDate, system.today(), 'Daily'), 'Should return a date');
        system.assertNotEquals(null, FixedAssetService.returnPeriodCount(testDate, system.today(), 'Quarterly'), 'Should return a date');
        system.assertNotEquals(null, FixedAssetService.returnPeriodCount(testDate, system.today(), 'Bi-Monthly'), 'Should return a date');
        system.assertNotEquals(null, FixedAssetService.returnPeriodCount(testDate, system.today(), 'Semi-Annually'), 'Should return a date');
        system.assertNotEquals(null, FixedAssetService.returnPeriodCount(testDate, system.today(), 'Annually'), 'Should return a date');
        system.assertEquals(null, FixedAssetService.returnPeriodCount(testDate, system.today(), 'NoResult'), 'Should return null');
    }
    
    
    
    static testMethod void testDepreciationAccounting(){
         test.startTest();
        List<Segment_Validation__c>  svList = [select id, Name, segment_1__c, segment_2__c from Segment_Validation__c];
        system.assertEquals(2, svList.size());
        //Grab the record with all the formulas and trigger assigned values
        Fixed_Asset__c fa = fixedAssets[0];
                                
        system.assert( fa.in_service_Date__c != null);
        system.assert( fa.estimated_end_of_life__c != null, ' expected estimated_end_of_life__c to be set');
        fa.in_service_Date__c = system.today().addMonths(-1).toStartOfMonth();
        update fa;                      
        
       
        
            AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
            asld.execute(new List<sObject>{(sObject)fa}, system.today(), true);
             
            FixedAssetDepreciationAccountingBatch batch = new FixedAssetDepreciationAccountingBatch(new Set<Id>{fixedAssets[0].company__r.Id});
            batch.setuseSuperWhere(false);
            database.executebatch(batch);
            
            List<Fixed_Asset_Depreciation__c> insertFads = new List<Fixed_Asset_Depreciation__c>();
            Fixed_Asset_Depreciation__c fadCIP = FixedAssetService.generateFixedAssetDepreciation(36000, 
                                                    system.today(), 38000, fa, FixedAssetService.TYPE_DEPRECIATION);
            fadCIP.depreciation_type__c = FixedAssetService.TYPE_CIP;
            fadCIP.depreciation_key__c = fa.asset_tag_number__c + FixedAssetService.TYPE_CIP;
            fadCIP.accounting_subtype__c = FixedAssetService.TYPE_CIP;
            insertFads.add(fadCIP);
            
            Fixed_Asset_Depreciation__c fadWO = FixedAssetService.generateFixedAssetDepreciation(36000, system.today(), 
                                                38000, fa, FixedAssetService.TYPE_DEPRECIATION);
            fadWO.depreciation_type__c = FixedAssetService.TYPE_RESIDUAL;
            fadWO.depreciation_key__c = fa.asset_tag_number__c + FixedAssetService.TYPE_RESIDUAL;
            fadWO.accounting_subtype__c = FixedAssetService.TYPE_RESIDUAL;
            insertFads.add(fadWO);
            
            //insert insertFads;
            
            List<Fixed_Asset_Depreciation__c> fads = [Select id, Name from Fixed_Asset_Depreciation__c where id in :insertFads];
        
            //Force fire the accounting depreciation processor
            AccountingProcessFixedAssetDepreciation apfad = new AccountingProcessFixedAssetDepreciation();
            //system.assert(batch.query!= null,'batch:'+batch);
            //List<Fixed_Asset_Depreciation__c> fads = database.query(batch.query);
            apfad.execute((List<sObject>)fads);
            List<Accounting_Entry__c> acctEntries = [SELECT Id 
                                                            FROM Accounting_Entry__c 
                                                            WHERE fixed_asset_depreciation__r.fixed_asset__c = :fixedAssets[0].Id]; 
            batch = new FixedAssetDepreciationAccountingBatch(new Set<Id>{fa.company__r.Id});
        
            List<Accounting_Entry__c> aes1 = [SELECT Id 
                                                  FROM Accounting_Entry__c 
                                                  WHERE fixed_asset_depreciation__r.fixed_asset__c = :fixedAssets[0].Id and status__c = 'Draft']; 
            system.assertEquals(0, aes1.size(), 'We expect records are nopt picked up again');
            //Validate that accounting entries were created
            //system.assert(acctEntries.size()>0);
            FixedAssetDepreciationRollbackBatch fadrb = new FixedAssetDepreciationRollbackBatch();
            fadrb.runBatch(fa.company__r.Id);
        test.stopTest();
    }
    
    
    static testMethod void testTaxBookAssetGeneration(){
     test.startTest();
        //Find all tax book fixed assets related to the original assets
        List<Fixed_Asset__c> fas = [SELECT Id FROM Fixed_Asset__c WHERE Fixed_Asset__c IN :fixedAssets];
        system.assert(fas.size() > 0);
     test.stopTest();   
    }
    
    static testMethod void testTaxBookAssetDelete(){
     
                                        
        test.startTest();
            //Find all tax book fixed assets related to the original assets
            List<Fixed_Asset__c> fas = [SELECT Id FROM Fixed_Asset__c WHERE Fixed_Asset__c IN :fixedAssets];
            
            system.assert(fas.size() > 0);
            
            for(Fixed_Asset__c fa : fas){
                fa.Status__c = FixedAssetService.STATUS_INACTIVE;
            }
            update fas;
            
            //Delete the original assets
            delete fixedAssets;
            
        
        
        //Verify the generated tax book fixed assets are deleted too
        List<Fixed_Asset__c> taxBookAssets = [SELECT Id FROM Fixed_Asset__c WHERE Id IN :fas];
        system.assert(taxBookAssets.size() == 0);
        test.stopTest();
    }
    
    static testMethod void testTaxBookAssetActiveNoDelete(){
     
        test.startTest();
            //Find all tax book fixed assets related to the original assets
            List<Fixed_Asset__c> fas = [SELECT Id FROM Fixed_Asset__c WHERE Fixed_Asset__c IN :fixedAssets];
            
            system.assert(fas.size() > 0);
            
            //Delete the original assets
            delete fixedAssets;
            
        //Verify the generated tax book fixed assets are not deleted - they are active
        List<Fixed_Asset__c> taxBookAssets = [SELECT Id FROM Fixed_Asset__c WHERE Id IN :fas];
        system.assert(taxBookAssets.size() > 0);
        test.stopTest();
    }
    
    static testMethod void testHeaderFinalize(){
     
        test.startTest();
        Fixed_Asset__c  fa = fixedAssets[0];
            fa.in_service_Date__c = system.today().addMonths(-1).toStartOfMonth();
            update fa;          
                        
            AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
            asld.execute(new List<sObject>{(sObject)fa}, system.today(), true);
             
            FixedAssetDepreciationAccountingBatch batch = new FixedAssetDepreciationAccountingBatch(new Set<Id>{fa.company__r.Id});
            database.executebatch(batch);
        
        
        
        boolean sawError = false;
        try{
            List<Fixed_Asset_Depreciation__c> fads = [SELECT Id, transaction_date__c 
                                                            FROM Fixed_Asset_Depreciation__c 
                                                            WHERE Fixed_Asset__c IN :fixedAssets];
            for(Fixed_Asset_Depreciation__c fadep : fads){
                fadep.transaction_date__c = fadep.transaction_date__c.addDays(1);
            }
            update fads;
        }catch(exception ex){
            sawError = true;
        }
        
        system.assert(sawError, 'We should see an error when attempting to update a finalized header');
        test.stopTest();
        
    }
    static testMethod void FixedAssetResidualValueValidationCheck(){
        String errMSG;
        Boolean sawError = false;
        
        test.startTest();
            List<Fixed_Asset__c> fas = [SELECT Id, Residual_Value__c 
                                                FROM Fixed_Asset__c 
                                                WHERE Fixed_Asset__c IN :fixedAssets];
            
            system.assert(fas.size() > 0);
            
            for(Fixed_Asset__c fa : fas){
                fa.Residual_Value__c = NULL;
            }
            try{
                update fas;
            }catch(DmlException error){
                errMSG = error.getMessage();
                sawError = TRUE;
            }
        system.assert(errMSG.contains('Please enter a value for Residual Value'), 'Validation Rule did not prevent null value');
        system.assert(sawError == TRUE);            
        test.stopTest();
        
    }   

}