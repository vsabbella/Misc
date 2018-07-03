@isTest
private class FixedAssetUndoSplitConTest {

	@testSetup static void ts() {
	   
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Work_Order__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;  
        FixedAssetData fad = new FixedAssetData(); 
        delete configList; 
        fad.si.Finalized__c = true;
        update fad.si;        
	}    
     
    static testMethod void testUndoSplit() {
         Test.startTest();
        Fixed_Asset__c slfa = [SELECT id, name, depreciation_method__c,Asset_Class__c, depreciation_period__c,
      								 estimated_end_of_life__c, in_service_date__c, 
	    						 	 acquisition_cost__c, residual_value__c, date_last_depreciated__c,
	    							 book_value__c, Fixed_Asset_Key__c, company__r.Comp_Currency__c,
	    							 company__c, company__r.Default_Transaction_Currency__c, company__r.Id, 
	    							 Final_Depreciation_Date__c, depreciation_count__c,
	    							 Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, 
	    							 Total_Depreciated_Value__c,Prorate_First_Period__c
     							FROM Fixed_Asset__c 
     	  						WHERE 	Asset_Tag_Number__c = '1010101' 
     	  						limit 1]; 
     	  						
    	Supplier_Invoice_Line__c ril = [SELECT Id,supplier_invoice__c ,supplier_invoice__r.company__c,Supplier_Invoice__r.Company__r.accounting_Standard__c,
    	                                        supplier_invoice__r.currency__c,extended_price__c,invoice_quantity__c,Finalized__c 
        								    FROM Supplier_Invoice_Line__c
        									WHERE track_as_asset__c='Yes' 
        									limit 1];  
                          GL_Account__c glAcc = [select id from GL_Account__c where Active__c = true limit 1];
       list<Accounting_rule__c> allAccRules = [SELECT Id,Object__c,effective_Start_date__c,amount_reference__c,effective_end_date__c,Rule_Type__c, Transaction__c,SubTransaction_Type__c,Accounting_Standard__c,Default_GL_Account__c,GL_Account__c 
                                                FROM Accounting_rule__c];
         for(Accounting_rule__c line: allAccRules){
            line.Company__c = ril.Supplier_Invoice__r.Company__c;
            line.accounting_Standard__c = ril.Supplier_Invoice__r.Company__r.accounting_Standard__c;    
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

       
         	SupplierInvoiceAccounting sAcc = new SupplierInvoiceAccounting();
            List<sObject> sObj = [Select Id,supplier_invoice__c from Supplier_Invoice_Line__c];
            sAcc.execute(sObj);					

        
            Test.setCurrentPage(Page.FixedAssetManageAdjustments);
            FixedAssetManageAdjustmentsExt ext = 
                                new FixedAssetManageAdjustmentsExt(new Apexpages.Standardcontroller(slfa));
            ext.RILDetails[0].selected = true; 
            ext.RILDetails[0].ril.Id   = ril.Id; 
            ext.selectedRIL = ext.RILDetails[0].ril.Id;
            
            system.debug(logginglevel.error,'selectedRIL'+ext.selectedRIL);
            ext.selectedAction = 'ADJUST';
            
            ext.updateAction();
            
            System.debug(logginglevel.error,'ril--->'+ril);
            System.debug(logginglevel.error,'ril.finalized--->'+ril.Finalized__c);
            
            system.assert(ext.fa != null);
            //system.assert(ext.fa.acquisition_cost__c == (ext.RILDetails[0].ril.extended_cost__c 
            														//+ ext.RILDetails[1].ril.extended_cost__c));
            
            ext.fa.name = 'test';
            ext.fa.Asset_Class__c = slfa.Id;
            ext.fa.In_Service_Date__c = system.today();
            ext.fa.company__c = slfa.company__c;
            ext.fa.description__c = 'test';
            
            ext.newAdjustments = new List<Fixed_Asset_Adjustment__c>();	
            ext.newAdjustments.add(new Fixed_Asset_Adjustment__c(Supplier_Invoice_line__c = ril.Id, supplier_invoice__c = ril.supplier_invoice__c, 
    			                                                  fixed_asset__c = slfa.Id,company__c = ril.supplier_invoice__r.company__c, 
    			                                                  currency__c = ril.supplier_invoice__r.currency__c,
    															  amount__c = ril.extended_price__c, units__c = ril.invoice_quantity__c,
    															  adjustment_Date__c=system.today()));
            
            System.debug(logginglevel.error,'ext.newAdjustments---->'+ext.newAdjustments);
            ext.save(); 
    
            List<Fixed_Asset_Adjustment__c> adjustments = [SELECT Id, amount__c 
            													FROM Fixed_Asset_Adjustment__c ];
             
            System.debug(logginglevel.error,'adjustments--->'+adjustments);
            
            system.assert(adjustments.size()!=0);
            
            //----------undo split--------------//
             
            test.setCurrentPage(page.FixedAssetUndoSplit); 
            ApexPages.currentPage().getParameters().put('faaId',adjustments[0].Id);
            
            FixedAssetUndoSplitCon con = new FixedassetUndoSplitCon();
                
            system.assert(con.RILWrappers.size() == 1);
                
            for(FixedAssetUndoSplitCon.RILWrapper rw : con.RILWrappers){
                rw.selected = true;
            }
            con.undoSplit();
            con.workbench();
             
            List<Supplier_Invoice_Line__c> rils = [SELECT Id, Track_as_Asset__c 
                                                    FROM Supplier_Invoice_Line__c ];   
            
            List<Fixed_Asset_Adjustment__c> adjustmentsAftr = [SELECT Id, amount__c 
            													FROM Fixed_Asset_Adjustment__c 
            													WHERE Fixed_Asset__c = :ext.fa.Id 
            													order by amount__c asc];
            
            System.debug('Adjustmnets after Undo Adjustment'+adjustmentsAftr);  
           //--- Assert that the SILS have been restored---------  
            for(Supplier_Invoice_Line__c eachRIL : rils){
                system.assert(eachRIL.track_as_asset__c == 'Yes');
            }
           Test.stopTest();
           //--- Assert that the adjustmnets have been removed---------  
           system.assert(adjustmentsAftr.size()==0);
            
    } 
    
    static testMethod void testUndoWithFADs(){ 
     
     Test.startTest();
     
    	 Fixed_Asset__c slfa = [SELECT id, name, depreciation_method__c,Asset_Class__c, depreciation_period__c,
      								 estimated_end_of_life__c, in_service_date__c, 
	    						 	 acquisition_cost__c, residual_value__c, date_last_depreciated__c,
	    							 book_value__c, Fixed_Asset_Key__c, company__r.Comp_Currency__c,
	    							 company__c, company__r.Default_Transaction_Currency__c, company__r.Id, 
	    							 Final_Depreciation_Date__c, depreciation_count__c,
	    							 Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, 
	    							 Total_Depreciated_Value__c,Prorate_First_Period__c
     							FROM Fixed_Asset__c 
     	  						WHERE 	Asset_Tag_Number__c = '1010101' 
     	  						limit 1]; 
     	  						
    	 Supplier_Invoice_Line__c ril = [SELECT Id,supplier_invoice__c ,supplier_invoice__r.company__c, Supplier_Invoice__r.Company__r.accounting_Standard__c,
    	                                        supplier_invoice__r.currency__c,extended_price__c,invoice_quantity__c 
        								    FROM Supplier_Invoice_Line__c
        									WHERE track_as_asset__c='Yes' 
        									limit 1];  

        GL_Account__c glAcc = [select id from GL_Account__c where Active__c = true limit 1];
        list<Accounting_rule__c> allAccRules = [SELECT Id,Object__c,effective_Start_date__c,amount_reference__c,effective_end_date__c,Rule_Type__c, Transaction__c,SubTransaction_Type__c,Accounting_Standard__c,Default_GL_Account__c,GL_Account__c 
                                                FROM Accounting_rule__c];
        for(Accounting_rule__c line: allAccRules){
            line.Company__c = ril.Supplier_Invoice__r.Company__c;
            line.accounting_Standard__c = ril.Supplier_Invoice__r.Company__r.accounting_Standard__c;    
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

        SupplierInvoiceAccounting sAcc = new SupplierInvoiceAccounting();							
        List<sObject> sObj = [Select Id,supplier_invoice__c from Supplier_Invoice_Line__c];
        sAcc.execute(sObj); 

        Test.setCurrentPage(Page.FixedAssetManageAdjustments);
        FixedAssetManageAdjustmentsExt ext = 
                            new FixedAssetManageAdjustmentsExt(new Apexpages.Standardcontroller(slfa));
        ext.RILDetails[0].selected = true; 
        ext.RILDetails[0].ril.Id=ril.Id; 
        ext.selectedRIL = ext.RILDetails[0].ril.Id;
        ext.selectedAction = 'ADJUST';
        ext.newAdjustments = new List<Fixed_Asset_Adjustment__c>();	
        ext.newAdjustments.add(new Fixed_Asset_Adjustment__c(Supplier_Invoice_line__c = ril.Id, supplier_invoice__c = ril.supplier_invoice__c, 
			                                                  fixed_asset__c = slfa.Id,company__c = ril.supplier_invoice__r.company__c, 
			                                                  currency__c = ril.supplier_invoice__r.currency__c,
															  amount__c = ril.extended_price__c, units__c = ril.invoice_quantity__c,
															  adjustment_Date__c=system.today()));
        //ext.updateAction(); //track_as_asset__c ->clsoed
        ext.save();  
             
        /*List<Fixed_Asset_Adjustment__c> adjustments = [SELECT Id, amount__c
        													FROM Fixed_Asset_Adjustment__c 
        													WHERE Fixed_Asset__c = :slfa.Id  
        													order by amount__c asc]; 
        System.assert(adjustments.size()>0);*/
         
        //---- Creating Depreciation records for FA-------
        AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
	    asld.execute(new List<sObject>{(sObject)slfa}, system.today(), true);    
        //FixedAssetDepreciationAccountingBatch batch = 
	   		                   // new FixedAssetDepreciationAccountingBatch(new Set<Id>{slfa.company__r.Id}); 
	    //database.executebatch(batch);
	    /*List<Fixed_Asset_Depreciation__c> fads = 	[SELECT Id
        	 		                                FROM Fixed_Asset_Depreciation__c 
        		 	                                limit 1]; 
     
       	System.assert(fads.size()>0);*/
     
       //----------Try Undo split when there is Depreciation Records--------
      	Test.setCurrentPage(page.FixedAssetUndoSplit); 
      	
      	FixedAssetUndoSplitCon con = new FixedassetUndoSplitCon();
      	for(FixedAssetUndoSplitCon.RILWrapper rw : con.RILWrappers){
            rw.selected = true;
        }
      	con.undoSplit();
      	con.workbench(); 
       Supplier_Invoice_Line__c rilAftr = [SELECT Id, Track_as_Asset__c 
                                                FROM Supplier_Invoice_Line__c 
                                                WHERE ID = :ril.Id limit 1];    
       System.debug(logginglevel.error,'rilAftr--->'+rilAftr);                   
        //--- Verify the SILS are not restored-----------
      system.assert(rilAftr.track_as_asset__c == 'Closed');
      //------Verify that the adjustmnets  are not removed----------- 
      List<Fixed_Asset_Adjustment__c> adjustmentsAftr = [SELECT Id, amount__c
        													FROM Fixed_Asset_Adjustment__c 
        													WHERE Fixed_Asset__c = :slfa.Id  
        													order by amount__c asc];  
       Test.stopTest();       													
   	 System.assert(adjustmentsAftr.size()>0);
    } 
    
    /*
    static testMethod void testUndoSplitMaintainAsset() {
        test.startTest(); 
        
        Asset_Class__c slac = [SELECT Id FROM Asset_Class__c WHERE Depreciation_Method__c='Straight Line'];
		company__c company = [SELECT Id FROM Company__c];
        
        test.setCurrentPage(Page.FixedAssetManageAdjustments);
        
        Fixed_Asset__c fa = new Fixed_Asset__c();
        
        FixedAssetManageAdjustmentsExt ext = new FixedAssetManageAdjustmentsExt(new Apexpages.Standardcontroller(fa));
        
        system.assert(ext.RILDetails.size() == 2);
        
        ext.RILDetails[0].selected = true;
        ext.RILDetails[1].selected = true;
        
        ext.selectedAction = 'GROUP';
        
        ext.updateAction();
        
        system.assert(ext.fa != null);
        system.assert(ext.fa.acquisition_cost__c == (ext.RILDetails[0].ril.extended_cost__c + ext.RILDetails[1].ril.extended_cost__c));
        
        ext.fa.name = 'test';
        ext.fa.Asset_Class__c = slac.Id;
        ext.fa.In_Service_Date__c = system.today();
        ext.fa.company__c = company.Id;
        ext.fa.description__c = 'test';
        
        ext.save();
        
        system.assert(ext.fa.Id != null); 
        
        List<Fixed_Asset_Adjustment__c> adjustments = [SELECT Id, amount__c FROM Fixed_Asset_Adjustment__c WHERE Fixed_Asset__c = :ext.fa.Id ORDER BY amount__c asc];
        system.assert(adjustments[0].amount__c == 1000);
        system.assert(adjustments[1].amount__c == 2000);
        
        test.setCurrentPage(page.FixedAssetUndoSplit);
        
        
            
            FixedAssetUndoSplitCon con = new FixedassetUndoSplitCon();
            
            system.assert(con.RILWrappers.size() == 2);

            con.RILWrappers[0].selected = true;
            
            con.undoSplit();
            
            con.workbench();
            
            //Assert that the Fixed Asset was not deleted because there is still an adjustments or depreciation
            List<Fixed_Asset__c> fas = [SELECT Id FROM Fixed_Asset__c WHERE Id = :ext.fa.Id];
            system.assert(fas.size() == 1);
                        
        
        test.stopTest();
        
    }*/
    
    static testmethod void testUndoManualAdjustmentWithoutValidFADs(){
        
        test.startTest();
          
	        List<Fixed_Asset__c> faToAdjust = [SELECT id, name, acquisition_cost__c,Date_Last_Depreciated__c, company__r.Comp_Currency__c,
	    					    	                status__c,company__c, company__r.Default_Transaction_Currency__c
     						                    	FROM Fixed_Asset__c 
     	  						                    WHERE 	Asset_Tag_Number__c = '1010101' 
     	  						                    limit 1];  
	       
	        //-------------Add adjustments-----------------//
             Apexpages.StandardController con  		     = new Apexpages.StandardController(faToAdjust[0]);
	         FixedAssetManualAdjustmentExt faaManualAdj  = new FixedAssetManualAdjustmentExt(con);
	    	 List<Fixed_Asset_Adjustment__c> manualAdjustmentsToAdd 
	    	                                             = new List<Fixed_Asset_Adjustment__c>{
	                                                             new Fixed_Asset_Adjustment__c(Fixed_Asset__c=faToAdjust[0].id, 
	                                                                   Company__c =faToAdjust[0].Company__c,
	                                                                   Currency__c=faToAdjust[0].company__r.Default_Transaction_Currency__c,
	                                                                   type__c = 'Upgrade',adjustment_Date__c=system.today())};
	        
            manualAdjustmentsToAdd[0].Amount__c = 1000;
	        faaManualAdj.faAdjustmentsList =  manualAdjustmentsToAdd;
	        faaManualAdj.saveAdjustment();   
	        List<Fixed_Asset__c> faAfterAdjust = [SELECT id, name, acquisition_cost__c,Date_Last_Depreciated__c, 
	    					    	                company__c, company__r.Default_Transaction_Currency__c,
	    					    	                    (select id from Fixed_Asset_Adjustments__r)
     						                    	FROM Fixed_Asset__c 
     	  						                    WHERE 	 Id=:faToAdjust[0].Id
     	  						                    limit 1]; 
     	  	 
     	  	List<Fixed_Asset_Adjustment__c> faaInFA = faAfterAdjust[0].Fixed_Asset_Adjustments__r;
     	  	
     	  	Id currentFAAId =faaInFA[0].Id; 
     	  	//-----------Try to Undo the Manual Adjustments---------------
     	  	Test.setCurrentPage( Page.FixedAssetUndoSplit);      
	        ApexPages.currentPage().getParameters().put('faaId',currentFAAId);
	          
	        FixedAssetUndoSplitCon UndoSplitExt          = new FixedAssetUndoSplitCon();
	        UndoSplitExt.undoSplit();
        
            List<Fixed_Asset__c> faAfterUndoAdjust = [SELECT id, name, acquisition_cost__c,Total_Adjustments__C,
                                                            (select id from Fixed_Asset_Adjustments__r)
             						                    	FROM Fixed_Asset__c 
             	  						                    WHERE 	 Id=:faToAdjust[0].Id
             	  						                    limit 1]; 
          test.stopTest();
          //--------- The manual adjustments should be undone----------------------/    
           List<Fixed_Asset_Adjustment__c> faAdjustmentsAfterUndo = faAfterUndoAdjust[0].Fixed_Asset_Adjustments__r;
           //KNDY-13139 We are not updating aquistion cost on adding /undoing/unfinalizing/finalizing adjustments.  
           system.assertEquals(faAfterUndoAdjust[0].acquisition_cost__c,38000,'Undoing a adjustment has no impact on acquistion cost.');         
           system.assertEquals(faAfterUndoAdjust[0].Total_Adjustments__C,0); 
           system.assertEquals(faAdjustmentsAfterUndo.size(),0); 
             
          
    }
    static testmethod void testUndoManualAdjWithValidFADs(){
        
        test.startTest();
           
	        List<Apexpages.Message> msgs = ApexPages.getMessages();
            boolean sawExceptions        = false;

	        List<Fixed_Asset__c> faToAdjust = [SELECT id, name, acquisition_cost__c,Date_Last_Depreciated__c, company__r.Comp_Currency__c,
	    					    	                status__c,company__c, company__r.Default_Transaction_Currency__c
     						                    	FROM Fixed_Asset__c 
     	  						                    WHERE 	Asset_Tag_Number__c = '1010101' 
     	  						                    limit 1];  
	       
	        //-------------Add adjustments-----------------//
             Apexpages.StandardController con  		     = new Apexpages.StandardController(faToAdjust[0]);
	         FixedAssetManualAdjustmentExt faaManualAdj  = new FixedAssetManualAdjustmentExt(con);
	    	 List<Fixed_Asset_Adjustment__c> manualAdjustmentsToAdd 
	    	                                             = new List<Fixed_Asset_Adjustment__c>{
	                                                             new Fixed_Asset_Adjustment__c(Fixed_Asset__c=faToAdjust[0].id, 
	                                                                   Company__c =faToAdjust[0].Company__c,
	                                                                   Currency__c=faToAdjust[0].company__r.Default_Transaction_Currency__c,
	                                                                   type__c = 'Upgrade',adjustment_Date__c=system.today())}; 
	        
            manualAdjustmentsToAdd[0].Amount__c = 1000;
	        faaManualAdj.faAdjustmentsList =  manualAdjustmentsToAdd;
	        faaManualAdj.saveAdjustment();   
	        List<Fixed_Asset__c> faAfterAdjust = [SELECT id, name, acquisition_cost__c,Date_Last_Depreciated__c, company__r.Comp_Currency__c,
        	    					    	                company__c, company__r.Id,company__r.Default_Transaction_Currency__c,
        	    					    	                depreciation_method__c,Asset_Class__c, depreciation_period__c,
              								                estimated_end_of_life__c, in_service_date__c, 
        	    						 	                residual_value__c,book_value__c, Fixed_Asset_Key__c,
        	    							                Final_Depreciation_Date__c, depreciation_count__c,
        	    							                Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, 
        	    							                Total_Depreciated_Value__c,Prorate_First_Period__c,
	    					    	                        (select id from Fixed_Asset_Adjustments__r)
     						                    	FROM Fixed_Asset__c 
     	  						                    WHERE 	 Id=:faToAdjust[0].Id
     	  						                    limit 1]; 
     	  	 
     	  	List<Fixed_Asset_Adjustment__c> faaInFA = faAfterAdjust[0].Fixed_Asset_Adjustments__r;
     	  	Id currentFAAId =faaInFA[0].Id; 
     	  	
     	  	//------Create Depreciation Records after adding adjustment-----------//
            AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
	        asld.execute(new List<sObject>{(sObject)faAfterAdjust[0]}, system.today(), true);    
            //FixedAssetDepreciationAccountingBatch batch = 
	   		  //                  new FixedAssetDepreciationAccountingBatch(new Set<Id>{faAfterAdjust[0].company__r.Id}); 
	   		//database.executebatch(batch);
    	    List<Fixed_Asset_Depreciation__c> fads = 	[SELECT Id
            	 		                                FROM Fixed_Asset_Depreciation__c 
            		 	                                limit 1]; 
         
           	 system.assert(fads.size()>0); 
     	  	//-----------Try to Undo the Manual Adjustments---------------
     	  	Test.setCurrentPage( Page.FixedAssetUndoSplit);      
	        ApexPages.currentPage().getParameters().put('faaId',currentFAAId);
	          
	        FixedAssetUndoSplitCon UndoSplitExt          = new FixedAssetUndoSplitCon();
	        UndoSplitExt.undoSplit();
            
            List<Fixed_Asset__c> faAfterUndoAdjust = [SELECT id, name, acquisition_cost__c,Total_Adjustments__C,
                                                            (select id from Fixed_Asset_Adjustments__r)
             						                    	FROM Fixed_Asset__c 
             	  						                    WHERE 	 Id=:faToAdjust[0].Id
             	  						                    limit 1]; 
           test.stopTest();
            //--------- The manual adjustments should be not undone since depreciation exists----------------------/  
           List<Fixed_Asset_Adjustment__c> faAdjustmentsAfterUndo = faAfterUndoAdjust[0].Fixed_Asset_Adjustments__r;

           system.assertEquals(faAfterUndoAdjust[0].Total_Adjustments__C,1000);            
           //KNDY-13139 We are not updating aquistion cost on adding /undoing/unfinalizing/finalizing adjustments.      
           system.assertEquals(faAfterUndoAdjust[0].acquisition_cost__c,38000,'As we are NOT updating aquistion cost on undoing/adding adjustment it should stay the same.');
           system.assert(faAdjustmentsAfterUndo.size()>0); 
           
    }
}