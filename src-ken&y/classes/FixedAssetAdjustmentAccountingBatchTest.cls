@isTest
private class FixedAssetAdjustmentAccountingBatchTest {
    
    @testSetup
    static void createTestData() {
        Test.startTest(); //denote testing context
            FixedAssetData fad =  new FixedAssetData();
             Test.stopTest();
            List<Fixed_Asset_Adjustment__c> faas = new List<Fixed_Asset_Adjustment__c>();
            // Create Fixed Asset Data with final depreciation date greater than FAA TD to be used in testFAAUnfinalizeWhenValidFADsExists
            Fixed_Asset__c fa = [SELECT id, name, depreciation_method__c, depreciation_period__c, estimated_end_of_life__c, in_service_date__c, 
                                acquisition_cost__c, residual_value__c, date_last_depreciated__c, book_value__c, Fixed_Asset_Key__c,
                                company__c, company__r.Default_Transaction_Currency__c, Final_Depreciation_Date__c, depreciation_count__c,
                                Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, Total_Depreciated_Value__c,Prorate_First_Period__c
                                FROM Fixed_Asset__c 
                                WHERE Id = :fad.slfa.Id];
                                
            for(integer i=0; i<10; i++){
                Fixed_Asset_Adjustment__c iFaa = 
                        new Fixed_Asset_Adjustment__c(Supplier_Invoice_line__c = fad.ril1.Id, supplier_invoice__c = fad.ril1.supplier_invoice__c, amount__c = 1, 
                                                        type__c = 'Upgrade', subtransaction_type__c = 'Upgrade',  fixed_asset__c = fad.insertFixedAssets[0].Id,
                                                        company__c = fad.si.Company__c, Currency__c = fad.si.Currency__c,
                                                        adjustment_date__c = system.today(), transaction_date__c = system.now());
                faas.add(iFaa);
            }
            insert faas;
            for(Fixed_Asset_Adjustment__c faa : faas){
                faa.finalized__c = true;
            }
            update faas;
            
            Fixed_Asset_Adjustment__c unfinalizedFAA      = 
                                        new Fixed_Asset_Adjustment__c(Supplier_Invoice_line__c = fad.ril1.Id, supplier_invoice__c = fad.ril1.supplier_invoice__c, amount__c = 1, 
                                                    type__c = 'Upgrade', subtransaction_type__c = 'Upgrade', fixed_asset__c = fa.Id,
                                                    company__c = fad.si.Company__c, Currency__c = fad.si.Currency__c,
                                                    adjustment_date__c = system.today().addMonths(-1), transaction_date__c = system.now().addMonths(-1));   
            insert unfinalizedFAA;
                                                    
        //Test.stopTest(); //revert from testing context
    }
    static testMethod void testBatch() {
       
       Set<Id> faaIds    = new Set<Id>();
       
       List<Fixed_Asset_Adjustment__c> adjustments  = [SELECT Supplier_Invoice_line__c , 
                                                            supplier_invoice__c  , amount__c  , 
                                                            type__c  , subtransaction_type__c  , 
                                                            fixed_asset__c ,
                                                            company__c  , 
                                                            Currency__c  ,
                                                            adjustment_date__c  , 
                                                            transaction_date__c 
                                                      FROM Fixed_Asset_Adjustment__c LIMIT 5  ] ;
        
        for(Fixed_Asset_Adjustment__c eachFAA : adjustments){
            faaIds.add(eachFAA.Id);
        }
        test.startTest();
        	FixedAssetAdjustmentAccountingBatch batch = new FixedAssetAdjustmentAccountingBatch(new Set<Id>{adjustments[0].company__c});
        	database.executebatch(batch);
        test.stopTest();
         
		List<Accounting_Entry__c> aes = [SELECT Id 
		                                    FROM Accounting_Entry__c 
		                                    WHERE Fixed_Asset_Adjustment__c IN :faaIds];
		system.assertEquals(5, aes.size(), 'We expect 1 AE for every Adjustment' + batch.messages);
		
    }
    
    static testMethod void testAccounting() {
    	 Set<Id> compIds = new  Set<Id>();
         List<Fixed_Asset_Adjustment__c> adjustments  = [SELECT Supplier_Invoice_line__c , 
                                                            supplier_invoice__c  , amount__c  , 
                                                            type__c  , subtransaction_type__c  , 
                                                            fixed_asset__c ,company__r.Id,
                                                            company__c  , 
                                                            Currency__c  ,
                                                            adjustment_date__c  , 
                                                            transaction_date__c 
                                                      FROM Fixed_Asset_Adjustment__c LIMIT 5  ] ;
                                                      
        for(Fixed_Asset_Adjustment__c adj: adjustments){
            compIds.add(adj.company__r.Id);
        }
        test.startTest();
        	AccountingProcessFixedAssetAdjustments faa = new AccountingProcessFixedAssetAdjustments();
        	faa.execute(adjustments);
            List<Accounting_Entry__c> aes = [SELECT Id FROM Accounting_Entry__c WHERE Fixed_Asset_Adjustment__c IN :adjustments];
		    system.assertEquals(5, aes.size(), 'We expect 1 AE for every Adjustment');
		    FixedAssetAdjustmentAccountingBatch batch = new FixedAssetAdjustmentAccountingBatch(compIds);
        test.stopTest();
		List<Accounting_Entry__c> aes1 = [SELECT Id FROM Accounting_Entry__c WHERE Fixed_Asset_Adjustment__c IN :adjustments and status__c = 'Draft'];
		system.assertEquals(0, aes1.size(), 'We expect records are nopt picked up again'); 
    }
    
    static testMethod void testHeaderFinalize(){
    	 Fixed_Asset_Adjustment__c iFaa  = [SELECT Supplier_Invoice_line__c , 
                                                        supplier_invoice__c  , amount__c  , 
                                                        type__c  , subtransaction_type__c  , 
                                                        fixed_asset__c ,
                                                        company__c  , 
                                                        Currency__c  ,
                                                        adjustment_date__c  , 
                                                        transaction_date__c 
                                            FROM Fixed_Asset_Adjustment__c LIMIT 1  ] ;
       
        
        Test.startTest();
            boolean sawError = false;
            try{
              iFaa.transaction_date__c = iFaa.transaction_date__c.addDays(1); 
              update iFaa;
            }catch(exception ex){
            	sawError = true;
            }
        Test.stopTest();
        
        System.assert(sawError, 'We should see an error when attempting to update a finalized header');
    }
    static testMethod void testFAAUnfinalize() {
         
           Fixed_Asset_Adjustment__c iFaa  = [SELECT Supplier_Invoice_line__c , 
                                                        supplier_invoice__c  , amount__c  , 
                                                        type__c  , subtransaction_type__c  , 
                                                        fixed_asset__c ,
                                                        company__c  , 
                                                        Currency__c  ,
                                                        adjustment_date__c  , 
                                                        transaction_date__c 
                                            FROM Fixed_Asset_Adjustment__c LIMIT 1  ] ;
       
            AccountingProcessFixedAssetAdjustments faaAdjAcc = new AccountingProcessFixedAssetAdjustments();
            faaAdjAcc.execute(new List<Fixed_Asset_Adjustment__c>{iFaa}); 
            List<Accounting_Entry__c> aes = [SELECT Id FROM Accounting_Entry__c WHERE Fixed_Asset_Adjustment__c = :iFaa.Id];
            system.assertEquals(1, aes.size(), 'We expect 1 AE for every Adjustment');
            
            Fixed_Asset_Adjustment__c fadToBeUnfinalized = iFaa;
            //System.debug('Before Finalize'+fadToBeUnfinalized);
            Test.startTest();
                // Test Unfinalize FAA   
                Test.setCurrentPage(Page.SourceDocumentUnfinalize);
                ApexPages.currentPage().getParameters().put('id',fadToBeUnfinalized.id);
                SourceDocumentUnfinalize unfinalize = new SourceDocumentUnfinalize();
                unfinalize.unfinalizeSourceDoc();
                unfinalize.unfinalize();
           Test.stopTest();
          
          
        Fixed_Asset_Adjustment__c unfinalizedFAA = [select id, finalized__c from Fixed_Asset_Adjustment__c where id=:fadToBeUnfinalized.id]; 
        //System.debug('After Finalize'+unfinalizedFAA);
        System.assertEquals(false,unfinalizedFAA.finalized__c);
        // Verify that the  Acc Entry becomes Obsolete
        Accounting_Entry__c aeForUnfinalizedFAA = [SELECT Id,Status__c FROM Accounting_Entry__c WHERE Fixed_Asset_Adjustment__c =:unfinalizedFAA.id];
        //System.debug('Acc entry after Unfinalize'+aeForUnfinalizedFAA);
        System.assertEquals('Obsolete',aeForUnfinalizedFAA.Status__c);
    }
    
    
    // KNDY-10996 -- FAA can not be unfinalized if the FAD for that Fixed Asset exists 
      //and Date Last Depreciated > Transaction Date ( FAA's TD)
    static testMethod void testFAAUnfinalizeWhenValidFADsExists() { 
         
            Fixed_Asset__c fa = [SELECT id, name, depreciation_method__c, depreciation_period__c, estimated_end_of_life__c, in_service_date__c, 
                                    acquisition_cost__c, residual_value__c, date_last_depreciated__c, book_value__c, Fixed_Asset_Key__c,company__r.Comp_Currency__c,
                                    company__c, company__r.Default_Transaction_Currency__c, Final_Depreciation_Date__c, depreciation_count__c,
                                    Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, Total_Depreciated_Value__c,Prorate_First_Period__c
                                FROM Fixed_Asset__c 
                                LIMIT 1];
        
            // Create FAA for that FA with transaction date less than final depreciation date 
             
            Fixed_Asset_Adjustment__c unfinalizedFAA = [SELECT Supplier_Invoice_line__c , 
                                                            supplier_invoice__c  , amount__c  , 
                                                            type__c  , subtransaction_type__c  , 
                                                            fixed_asset__c ,
                                                            company__c  , 
                                                            Currency__c  ,
                                                            adjustment_date__c  , 
                                                            transaction_date__c 
                                                      FROM Fixed_Asset_Adjustment__c 
                                                      WHERE finalized__C=false
                                                      LIMIT 1]; 
           	  
           	 	unfinalizedFAA.transaction_date__c = system.now().addMonths(-1) ;
           	    unfinalizedFAA.finalized__C        = true;
           	Test.StartTest();
           	 	update  unfinalizedFAA; 
           	 	System.debug('Fixed Asset Adjustment--'+unfinalizedFAA);
            
        		// Create Fixed Asset depreciations on the FA
        		AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
    	     	asld.execute(new List<sObject>{(sObject)fa}, system.today(), true);
        	
        	 
        		List<Fixed_Asset_Depreciation__c> fads = [SELECT Id
            												 FROM Fixed_Asset_Depreciation__c 
            												 WHERE Fixed_Asset__c = :fa.Id]; 
            	System.debug('The SL FAD records'+fads); 
             
    	    	// Do Unfinalize on FAA 
    	        Test.setCurrentPage(Page.SourceDocumentUnfinalize);
    	        ApexPages.currentPage().getParameters().put('id',unfinalizedFAA.id);
    	        SourceDocumentUnfinalize unfinalize = new SourceDocumentUnfinalize(); 
    	        unfinalize.unfinalizeSourceDoc();
    	        unfinalize.unfinalize();  
          Test.StopTest();
    	// Check the status of Fixed Asset Adjustment - Should be finalized
    	 system.assertEquals(unfinalizedFAA.finalized__C,true);  
    	 	
    } 
}