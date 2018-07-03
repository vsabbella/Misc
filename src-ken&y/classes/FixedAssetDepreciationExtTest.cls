@isTest
private class FixedAssetDepreciationExtTest {
    
    //moving all test data setup for all methods in this class
	@testSetup
	static void testDataSetUpForThisTestClass() {
        test.startTest();
	    FixedAssetData fad = new FixedAssetData(); 
        Test.stopTest();
	    //Add more assets to test page controls
    	List<Fixed_Asset__c> additionalAssets = new List<Fixed_Asset__c>();
    	for(integer i=0; i<10; i++){
			additionalAssets.addAll(fad.insertFixedAssets.deepClone(false, false, false));   
    	}
    	integer counter = 0;
    	for(Fixed_Asset__c fa : additionalAssets){
    		fa.asset_tag_number__c = string.valueOf(counter) + string.valueOf(math.random());
    		counter++;
    	}
    	insert additionalAssets; 
	}
    
    static testMethod void testDepreciation() {
    	
    	List<Fixed_Asset__c> fixedAssets = new List<Fixed_Asset__c>();
    	fixedAssets = [SELECT Id,company__r.Id FROM Fixed_Asset__c limit 3];
    	Tax_Book__c corpTaxbk = [SELECT id,name 
    	                            FROM Tax_Book__c 
    	                            WHERE name LIKE 'Corporate' 
    	                            LIMIT 1];
	    
    	Apexpages.Standardsetcontroller ssCon = new Apexpages.Standardsetcontroller(fixedAssets);
    	ssCon.setSelected(fixedAssets);
    	
    	test.setCurrentPage(page.FixedAssetDepreciation);
    	
    	test.startTest();
	    	FixedAssetDepreciationExt ext = new FixedAssetDepreciationExt(ssCon);
	    	ext.updateCompanyBookOptions();
	 		ext.getTaxBookOptions();
	    	ext.updateDepreciableFixedAssets();
	    	
	    	ext.selectedCompanyId = fixedAssets[0].company__r.Id;
	        ext.selectedBookId = corpTaxbk.Id;
	      
	    	ext.getPageNumber();
	    	ext.getNumberOfPages();
	    	ext.getHasNext();
	    	ext.getHasPrevious();
	    	ext.next();
	    	ext.previous();
	    	ext.first();
	    	ext.last();
	    	
	    	ext.btn_RunDepreciation();
	    	ext.btn_Workbench();
    	test.stopTest();
    	
    }
    
    static testMethod void testBatchDepreciation() {
        test.startTest();
        List<Fixed_Asset__c> fixedAssets = new List<Fixed_Asset__c>();
    	fixedAssets = [SELECT Id,company__r.Id FROM Fixed_Asset__c limit 1];
    	Tax_Book__c corpTaxbk = [SELECT id,name 
    	                            FROM Tax_Book__c 
    	                            WHERE name LIKE 'Corporate' 
    	                            LIMIT 1];
    	  
    	Apexpages.Standardsetcontroller ssCon = new Apexpages.Standardsetcontroller(new List<Fixed_Asset__c>());
    	
    	test.setCurrentPage(page.FixedAssetDepreciation);
    	 
    	
	    	FixedAssetDepreciationExt ext = new FixedAssetDepreciationExt(ssCon);
	    	ext.updateCompanyBookOptions();
	    	ext.getTaxBookOptions();
	    	ext.updateDepreciableFixedAssets();
	    	
	    	ext.selectedCompanyId = fixedAssets[0].Id;
	    	ext.selectedBookId = corpTaxbk.Id;
	    	
	    	ext.btn_RunDepreciation();
	    	ext.btn_Workbench();
    	test.stopTest();
    	
    	//TODO Assert that the batch was started successfully
    	
    }
 
    static testMethod void testSLDepreciationWithProrate(){
   
     	Test.startTest();
     	
            Fixed_Asset__c fa = [SELECT id, name,asset_class__c,depreciation_method__c, depreciation_period__c,Prorate_First_Period__c,
            					    estimated_end_of_life__c, in_service_date__c,acquisition_cost__c, residual_value__c, date_last_depreciated__c, 
            					    book_value__c, Fixed_Asset_Key__c,company__c,company__r.Id, company__r.Default_Transaction_Currency__c, 
            					    Final_Depreciation_Date__c, depreciation_count__c,Depreciation_Convention__c, depreciable_basis__c, company__r.Comp_Currency__c,
            					    Asset_Tag_Number__c, Total_Depreciated_Value__c
	    						FROM Fixed_Asset__c 
	    						WHERE Asset_Tag_Number__c = '1010101' 
	    						LIMIT 1];
    	 
    	   //Asset Class Settings to Prorate
    	   fa.Prorate_First_Period__c = true;
    	   Date firstDayOfMonth = System.today().toStartOfMonth();
            
    	   // Changing the in service date after the beginning of the month
    	   fa.in_service_Date__c	 =  firstDayOfMonth;
    	   //Date.newInstance(System.today().year(), System.today().addMonths(-3).month(), 12 ); //3 months depreciation 
    	   fa.Residual_Value__c 	 =  0; 
    	   //fa.Depreciation_Life__c 	 =  4;
    	   fa.Estimated_End_of_Life__c = fa.in_service_Date__c.addmonths(14);
    	   
    	   try{
    	       update fa; 
    	  
    		   AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
    		   asld.execute(new List<sObject>{(sObject)fa},firstDayOfMonth.addMonths(1), true);
    		  
    		   FixedAssetDepreciationAccountingBatch batch = new FixedAssetDepreciationAccountingBatch(new Set<Id>{fa.company__r.Id});
    		   database.executebatch(batch);
    	   }
    	   catch(exception exe){
    	       system.debug('Issue in testSLDepreciationWithProrate '+exe.getStackTraceString());
    	   } 
       Test.stopTest();
	   
	   List<Fixed_Asset_Depreciation__c> fads = [SELECT Id, transaction_date__c,depreciation_Amount__c
        											 FROM Fixed_Asset_Depreciation__c 
        											 LIMIT 1];
        
       if(fads.size()>0){
         system.assert(fads[0].depreciation_Amount__c < fa.acquisition_cost__c /3);  
       } 
	   					
    } 
    
 
    static testMethod void testAutoBackDating_WithStraightLineDepreciation(){
     
		//Custom Settings for Autobackdating
		Configuration__c c = new Configuration__c();
		c.name = 'AutoBackdateToOpenSubledgers';
		c.Value__c = 'Yes';
		insert c;	  
		
		Date currDate = system.today();
			
       	test.startTest();
    		Fixed_Asset__c fa = [SELECT id, name, depreciation_method__c, depreciation_period__c, estimated_end_of_life__c, in_service_date__c, 
    	    						acquisition_cost__c, residual_value__c, date_last_depreciated__c, book_value__c, Fixed_Asset_Key__c, company__r.Comp_Currency__c,
    	    						company__c, company__r.Id,company__r.Default_Transaction_Currency__c, Final_Depreciation_Date__c, depreciation_count__c,
    	    						Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, Total_Depreciated_Value__c
	    						FROM Fixed_Asset__c 
	    						WHERE Asset_Tag_Number__c = '1010101' limit 1]; 
	      
	    	fa.In_Service_Date__c = currDate.toStartOfMonth();
            fa.Estimated_End_of_Life__c = system.today().addmonths(14);
	   		
	   		try{
	   		    	update fa; 	
	   		    	AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
	     	        asld.execute(new List<sObject>{(sObject)fa}, currDate.addmonths(1), true);
	                
	                FixedAssetDepreciationAccountingBatch batch = new FixedAssetDepreciationAccountingBatch(new Set<Id>{fa.company__r.Id});
			        database.executebatch(batch);
	   		}
	   		catch(Exception exe){
	   		      system.debug('Issue in testAutoBackDating_WithStraightLineDepreciation '+exe.getStackTraceString());
	   		} 
        
        test.stopTest();
        
        List<Fixed_Asset_Depreciation__c> fads = [SELECT Id, transaction_date__c,posting_date__C,finalized_date__C
        												 FROM Fixed_Asset_Depreciation__c];
        
        System.debug('testAutoBackDating_WithStraightLineDepreciation : The FAD records '+fads);
        
        if(fads.size()>0){
            
            Fixed_Asset_Depreciation__c fadToBeVerified = fads[0]; 
            // Assert that the Posting Date Equals Transaction Date  
            System.assertEquals(true,fadToBeVerified.transaction_date__c == fadToBeVerified.posting_date__c);	  
        }
         
        
     }
     static testMethod void testAutoBackDating_WithDecliningDepreciation(){
     
       	Date currDate = system.today(); 
		//Custom Settings
		Configuration__c c = new Configuration__c();
		c.name = 'AutoBackdateToOpenSubledgers';
		c.Value__c = 'Yes';
		insert c;	 
		 
       	test.startTest();
    		Fixed_Asset__c fa = [SELECT id, name, depreciation_method__c, depreciation_period__c, estimated_end_of_life__c, in_service_date__c, 
	    						        acquisition_cost__c, residual_value__c, date_last_depreciated__c, book_value__c, Fixed_Asset_Key__c, company__r.Comp_Currency__c,
	    						        company__c, company__r.Id,company__r.Default_Transaction_Currency__c, Final_Depreciation_Date__c, depreciation_count__c,
	    						        Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, Total_Depreciated_Value__c
	    						FROM Fixed_Asset__c 
	    						WHERE Asset_Tag_Number__c = '1010101' limit 1]; 
	   	   
	   	   fa.In_Service_Date__c   = currDate.toStartOfMonth();
	   	   fa.Residual_Value__c 	 =  0; 
           fa.Estimated_End_of_Life__c = fa.in_service_Date__c.addmonths(14);
           fa.Depreciation_Convention__c = 'Full Month';
   		   
   		    try{
       		   update fa; 	
	            AccountingDecliningBalanceDepreciation adbd = new AccountingDecliningBalanceDepreciation();
	    	    adbd.execute(new List<sObject>{(sObject)fa}, currDate.addmonths(1), true);
    	      
        	    FixedAssetDepreciationAccountingBatch batch = new FixedAssetDepreciationAccountingBatch(new Set<Id>{fa.company__r.Id});
    		    database.executebatch(batch); 
   		    } 
           catch(Exception exe){
        	    system.debug('Issue in testAutoBackDating_WithDecliningDepreciation '+exe.getStackTraceString());
           }
	    	  
        
        test.stopTest();
        
        List<Fixed_Asset_Depreciation__c> fads = [SELECT Id, transaction_date__c,posting_date__C,finalized_date__C
        												 FROM Fixed_Asset_Depreciation__c];
        System.debug('The Declining Balance FAD records '+fads);
        if(fads.size()>0){
             Fixed_Asset_Depreciation__c fadToBeVerified = fads[0];
             // Assert that the Posting Date Equals Transaction Date  
            System.assertEquals(true,fadToBeVerified.transaction_date__c==fadToBeVerified.posting_date__c);	 
        } 
        
     }
      
    //--------------KNDY-11657 Test FixedAsset Depreciation Rollback  with Finalized and  
    	//Unfinalized FADs with Acc entries only in Open Period-----------------------   
    static testMethod void testFADepRollbackOpenPeriod(){
     
       	test.startTest();
			
			Fixed_Asset__c fa = [SELECT id, name, depreciation_method__c, depreciation_period__c, estimated_end_of_life__c, in_service_date__c, 
	    								acquisition_cost__c, residual_value__c, date_last_depreciated__c, book_value__c, Fixed_Asset_Key__c, company__r.Comp_Currency__c,
	    								company__c, company__r.Id,company__r.Default_Transaction_Currency__c, Final_Depreciation_Date__c, depreciation_count__c,
	    								Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, Total_Depreciated_Value__c,tax_book__c
	    						FROM Fixed_Asset__c 
	    						WHERE Asset_Tag_Number__c = '1010101' 
	    						LIMIT 1];
	    	 
	    	fa.in_service_Date__c = system.today().addMonths(-2).toStartOfMonth();
	   		update fa; 			
	   		
	   		//------------------- Generate Straight Line Depreciation on Fixed Asset------------		
	    	AccountingStraightLineDepreciation asld = 
	    							new AccountingStraightLineDepreciation();
	     	asld.execute(new List<sObject>{(sObject)fa}, system.today(), true);
	     	
	     	//------------------Fetch all fixed Asset Depreciation Records--------------------- 
	     	List<Fixed_Asset_Depreciation__c> allFADs = [SELECT Id,Name,Finalized__c
						 						              FROM Fixed_Asset_Depreciation__c 
											                  WHERE Company__c = :fa.company__r.Id];
       	
	        //----------------- Make some fixed Asset Depreciation Records unfinalized--------------- 
	        allFADs[0].finalized__c 		= false;  		 
            allFADs[0].finalized_hidden__c 	= false; 
            
	        update allFADs;
	     	
	     	System.debug('---Show both finalized and unfinalized  FADs----'+allFADs); 
	     	
	    	//----------------- Generate Accounting on FADS with FAD Depreciation Batch Job-----------
			FixedAssetDepreciationAccountingBatch batch = 
										new FixedAssetDepreciationAccountingBatch(new Set<Id>{fa.company__r.Id});
			database.executebatch(batch);
	       
	       //------------------Test Rollback from  Companyfixedassetdepreciationrollback Page ----------
	        Test.setCurrentPage( Page.Companyfixedassetdepreciationrollback);      
	        Apexpages.StandardController con  		= new Apexpages.StandardController(new Fixed_Asset__c());
	        CompanyFixedAssetDepreciationRollbackExt cmpRollBack 
	        										= new CompanyFixedAssetDepreciationRollbackExt(con);
	        cmpRollBack.selectedCompanyId		    = fa.company__r.Id ;
		    cmpRollBack.selectedBookId              = fa.tax_book__c;										
	        cmpRollBack.updateFixedAssetDepreciations();
	        cmpRollBack.btn_Rollback();
        										
       	test.stopTest();
       
        //-----------------------Fetch all the FADs after Rollback---------------------------------
        List<Fixed_Asset_Depreciation__c> fadsAfterRollBack = [SELECT Id,Name,Finalized__c
        						 						              FROM Fixed_Asset_Depreciation__c 
        												              where Company__c = :fa.company__r.Id];        												              
         											        												              
         //-----------------------Verify if the FADs got wiped off---------------------------------
        System.assertEquals(0,fadsAfterRollBack.size());
        
        //--------------Fetch all the Accounting entries generated for all the finalized FADs------ 
        List<Accounting_Entry__c> aeListAfterRollBack	    = [SELECT id,name,Fixed_Asset_Depreciation__c,status__c 
                                                   		 			FROM Accounting_Entry__c 
                                                    	 			WHERE Company__c = :fa.company__r.Id ];
         //-----------Verify that those Accounting entries status turns to Obsolete after Rollback-------------
        System.assertEquals('Obsolete',aeListAfterRollBack[0].Status__c);
        
    }
    //-------KNDY-11177---- 
static testMethod void testDepreciatedFAStatus(){   
		test.startTest();
    		
    		Fixed_Asset__c fa = [SELECT id, name, depreciation_method__c,Status__c,depreciation_period__c, estimated_end_of_life__c, 
        							in_service_date__c, Depreciation_Life__c,acquisition_cost__c, residual_value__c, date_last_depreciated__c, company__r.Comp_Currency__c,
        							book_value__c, Fixed_Asset_Key__c,company__c, company__r.Default_Transaction_Currency__c, Final_Depreciation_Date__c,
        							depreciation_count__c,Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, Total_Depreciated_Value__c
        						FROM Fixed_Asset__c 
        						WHERE Asset_Tag_Number__c = '1010101' limit 1];  
            fa.acquisition_cost__c = 4000; 
            fa.residual_value__c   = 0;
       		fa.In_Service_Date__c       	= system.today().addMonths(-2);
       		fa.Depreciation_Life__c			= 2;
        	//fa.Final_Depreciation_Date__c 	= system.today().addMonths(-1);//To test the case --> fa.Final_Depreciation_Date__c < system.today() 
        	update fa;
        
       		 
    		Fixed_Asset__c updatedFA = [SELECT id, name, depreciation_method__c,Status__c,depreciation_period__c, estimated_end_of_life__c, Prorate_First_Period__c,
                							in_service_date__c, Depreciation_Life__c,acquisition_cost__c, residual_value__c, date_last_depreciated__c, company__r.Comp_Currency__c,
                							book_value__c, Fixed_Asset_Key__c,company__c, company__r.Default_Transaction_Currency__c, Final_Depreciation_Date__c,
                							depreciation_count__c,Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, Total_Depreciated_Value__c
                						FROM Fixed_Asset__c 
                						WHERE Asset_Tag_Number__c = '1010101' limit 1];  
       		//-------------Running Depreciation-----------------
       		 AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
       		 asld.execute(new List<sObject>{(sObject)updatedFA}, system.today(), true);
	    
	    test.stopTest(); 
	    
	   	 Fixed_Asset__c depreciatedFA 			= [SELECT Id,Status__C ,Book_value__c,Acquisition_Cost__c,Final_Depreciation_Date__c,
	   	                                                  Residual_Value__c,Total_Depreciated_Value__c,Depreciable_Basis__c
	   	 								   				 FROM Fixed_Asset__c
        												 WHERE Id = :updatedFA.Id 
        												 limit 1]; 
		 System.assertEquals(depreciatedFA.Status__C,FixedAssetService.STATUS_DEPRECIATED);	
		 System.assertEquals(depreciatedFA.Total_Depreciated_Value__c,depreciatedFA.Depreciable_Basis__c);
	    
    }
     //---- To cover KNDY-11584----
    static testMethod void testFAStatusAfterFADRollback(){   
    	 
		test.startTest();
    		
    		Fixed_Asset__c fa = [SELECT id, name,Status__c,depreciation_method__c, depreciation_period__c, estimated_end_of_life__c, in_service_date__c, 
        								acquisition_cost__c, residual_value__c, date_last_depreciated__c, book_value__c, Fixed_Asset_Key__c, company__r.Comp_Currency__c,
        								company__c,company__r.Id, company__r.Default_Transaction_Currency__c, Final_Depreciation_Date__c, depreciation_count__c,
        								Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, Total_Depreciated_Value__c,tax_book__c
        							FROM Fixed_Asset__c 
        							WHERE Asset_Tag_Number__c = '1010101' limit 1];  
        		 
            
       		fa.In_Service_Date__c       	  = system.today().addMonths(-2);
       		fa.Depreciation_Life__c			  = 1;
        	fa.Final_Depreciation_Date__c 	  = system.today().addMonths(-1);
        	 
        	update fa; 
           	       
       	    //-------------Running Depreciation-----------------
       		AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
       		asld.execute(new List<sObject>{(sObject)fa}, system.today(), true);
       	  	   
            //------------------Test Rollback from  Companyfixedassetdepreciationrollback Page ----------
            Test.setCurrentPage( Page.Companyfixedassetdepreciationrollback);      
            Apexpages.StandardController con  		= new Apexpages.StandardController(new Fixed_Asset__c());
            CompanyFixedAssetDepreciationRollbackExt cmpRollBack 
            										= new CompanyFixedAssetDepreciationRollbackExt(con);
            cmpRollBack.selectedCompanyId		    = fa.company__r.Id ;
    	    cmpRollBack.selectedBookId              = fa.tax_book__c;										
            cmpRollBack.updateFixedAssetDepreciations(); 
            cmpRollBack.btn_Rollback();
    	        
                
        test.stopTest();  
        Fixed_Asset__c faAfterRollback    = [SELECT Id,Status__C 
                                                FROM Fixed_Asset__c
                                                WHERE Id = :fa.Id  
                                                LIMIT 1];  
        System.assertEquals(faAfterRollback.Status__C,'Active'); 
        
    } 
    
}