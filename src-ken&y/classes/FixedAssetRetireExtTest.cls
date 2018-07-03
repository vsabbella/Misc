@isTest
private class FixedAssetRetireExtTest {

    @testSetup
	static void testDataSetUpForThisTestClass() {
	  FixedAssetData fad = new  FixedAssetData(); 
	  
	}
    // 1. Fixed Asset Linked to Serial
    // 2. Depreciation exists but depreciated partially
    //3. Disposition date within limits
    static testMethod void returnToInventory(){
       
        Date currDay = system.today();
        Test.startTest();	 
		
		Fixed_Asset__c fa = [SELECT id, name,Status__c,depreciation_method__c, depreciation_period__c, 
		                            estimated_end_of_life__c, in_service_date__c, 
    								acquisition_cost__c, residual_value__c, date_last_depreciated__c, book_value__c, 
    								Fixed_Asset_Key__c,company__c, company__r.Default_Transaction_Currency__c, 
    								company__r.Comp_Currency__c, Final_Depreciation_Date__c, depreciation_count__c,
    								Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, 
    								Total_Depreciated_Value__c,tax_book__c,
    								Asset_Class__r.GL_Account__c,Asset_Class__r.Depreciated_GL_Account__c ,Retirement_Type__c,
    								Disposition_Date__c,Prorate_First_Period__c
    							FROM Fixed_Asset__c 
    							WHERE Asset_Tag_Number__c = '1010101' limit 1];  
     
    	fa.In_Service_Date__c = currDay.toStartOfMonth();
        fa.Estimated_End_of_Life__c = system.today().addmonths(14); 
    	update fa;  
    	
    	system.debug('fa--->'+fa);
            
        Facility__c facility = new Facility__c(
                                     Name = 'Facility',
                                     Company__c = fa.company__c,
                                     Primary_Key__c = 'FA001',
                                     Description__c = 'Facility.');
        insert facility;   
        Location__c   location = new Location__c(
                                 Facility__c = facility.id,
                                 Description__c = 'location',
                                 name = 'Location1'  );
        insert location;
          
        Item_Attribute__c itemAttr = new Item_Attribute__c();
            itemAttr.Name = 'Attribute-1';
            itemAttr.Expiration_Date__c = false;
            itemAttr.Lot_Number__c = false; 
            itemAttr.Minimum_Shelf_Life_In_Days__c = false;
            itemAttr.Serial_Number__c = true;
            itemAttr.Fixed_Asset__c = true; 
        insert itemAttr;
        
       
        UOM__c currUOM =   [select id,name from UOM__c where name like 'EA' limit 1];
        
        Item__c item = new Item__c();
            item.name = 'Item-';
            item.Description__c='Items';
            item.Source__c = 'Manufactured';
            item.company__c = fa.company__C;
            item.item_attribute__c = itemAttr.Id;
            item.Active__c = true;
            item.Stocking_UOM__c = currUOM.Id;
            item.Packaging_UOM__c = JSON.serialize(new List<Id>{ currUOM.Id });
        insert item;
          
        SKID__c skid = new SKID__c();
        skid.Facility2__c = facility.Id;
                skid.location__c = location.id;
                skid.Quantity__c = 200.0;
                skid.Quantity_Stocking_UOM__c = 200;
                skid.Packaging_UOM__c = currUOM.Id; 
                skid.Stocking_UOM__c = currUOM.Id;
                skid.Item__c = item.Id;
                skid.company__c = fa.company__C; 
                skid.Type__c = SKIDService.SKID_TYPE_LOCATION;
                skid.Expiration_Date__c = System.today() + 365;   
        insert  skid;
        skid.Item__r = item;
           
        Serial__c assetSerial = new Serial__c(
            Name = 'Asset Serial',
            Item__c = skid.Item__c,
            Company__c = fa.Company__c,
            Allow_Reentry__c = false,
            Status__c  ='Inventory',
            SKID__c    = skid.Id
       );
        
        assetSerial.Unique_Key2__c = fa.Company__c + '-' + skid.Item__c + '-' + assetSerial.Name;
        insert assetSerial;
        List<Serial__c> selectedSerialsList = new List<Serial__c>();
        selectedSerialsList.add(assetSerial);
     
        Apexpages.Standardcontroller Con = new Apexpages.Standardcontroller(fa);
        test.setCurrentPage(page.FixedAssetLinkToSerial);
        FixedAssetLinkToSerialExt ext = new FixedAssetLinkToSerialExt(Con); 
       
        FixedAssetLinkToSerialExt.attachSerialsTOFA(fa.Id,selectedSerialsList);
       
          //-------------Running Depreciation-----------------
   	     AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
   	     asld.execute(new List<sObject>{(sObject)fa}, currDay.addMonths(1), true);  
   	 
                                            
   	     Fixed_Asset__C faAfterDep = [select id,name ,Status__c,Disposition_Date__c ,
   	                                        depreciation_method__c, depreciation_period__c, estimated_end_of_life__c, in_service_date__c, 
            								acquisition_cost__c, residual_value__c, date_last_depreciated__c, book_value__c, Fixed_Asset_Key__c,
            								company__c, company__r.Default_Transaction_Currency__c, company__r.Comp_Currency__c, Final_Depreciation_Date__c, depreciation_count__c,
            								Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, Total_Depreciated_Value__c,tax_book__c,
            								Asset_Class__r.GL_Account__c,Asset_Class__r.Depreciated_GL_Account__c ,Retirement_Type__c,
       		                                (select id ,Depreciation_Date__c from Fixed_Asset_Depreciations__r) 
       		                                from Fixed_Asset__c where id=:fa.Id]; 
   		List<Fixed_Asset_Depreciation__c> fads = faAfterDep.Fixed_Asset_Depreciations__r;
   		
   		system.debug('returnToInventory fads'+fads);
   		
   		if(fads.size()>0){
       	 
       		faAfterDep.Disposition_Date__c            = fads[fads.size()-1].Depreciation_Date__c-1;//.toStartOfMonth()+5;
       		faAfterDep.disposition_action__c          =  'Sold';
       		faAfterDep.Retirement_Type__c             = 'Return to Inventory';
       		update faAfterDep; 
       	 	PageReference newPage = Page.FixedAssetRetire;
    		newPage.getParameters().put('Id', faAfterDep.Id);
    		test.setCurrentPage(newPage);
    		
    		Apexpages.standardcontroller retireCon = new Apexpages.Standardcontroller(faAfterDep);
    		FixedAssetRetireExt retireExt = new FixedAssetRetireExt(retireCon);
    		retireExt.tmpFixedAsset.GL_Account__c = faAfterDep.Asset_Class__r.GL_Account__c; //glAcct.Id;
    		retireExt.btn_Retire();
    		
       		Fixed_Asset__C faAfter = [SELECT id,name ,Status__c,Disposition_Date__c ,Total_Depreciated_Value__c,
       		                                (SELECT id ,Depreciation_Date__c FROM Fixed_Asset_Depreciations__r) 
       		                                FROM Fixed_Asset__c WHERE id=:faAfterDep.Id]; 
       		Serial__c serialLinkedtoAsset =[SELECT id,book_value__c,SKID__r.Rental__c,SKID__r.Used__c 
       		                                    FROM Serial__c 
       		                                    WHERE Fixed_Asset__c=:faAfterDep.Id limit 1];
       		                                    
       		// ----- Changes as per KNDY-13956-------------------------//
       		// Find the IT related to this transaction -------
       		List<Serial_Transaction__c> sts = [SELECT ID,Type__c,Inventory_Transaction__c
       	                                           FROM Serial_Transaction__c 
       	                                           WHERE Serial__c = :serialLinkedtoAsset.ID] ;
       		 
       		Id  current_IT_Id ;
       		Inventory_Transaction__c current_IT;
       		
       		for(Serial_Transaction__c st: sts){
       		   if(st.Type__c.contains('Fixed Asset to Inventory')){
       		       current_IT_Id = st.Inventory_Transaction__c;
       		   }
       		}
       		
       		if(current_IT_Id!=null){
       		 	current_IT= [SELECT ID,Type__c,Book_Value_of_Related_Fixed_Asset__c 
       		                                             FROM Inventory_Transaction__c 
       	                                                 WHERE Id = :current_IT_Id] ;
       		}
       		 
       	     //------------Assert that the asset is retired-----------// 
       	    system.assertEquals(faAfter.Status__c,'Retired');
       	    //------------Assert that the book value on the Serial Object is updated-----------//
       	    system.assertEquals(serialLinkedtoAsset.book_value__c,faAfterDep.book_value__c);
       	    //------------Assert that the book value is updated on Inventory_Transaction__c----------//
       	    system.assertEquals(current_IT.Book_Value_of_Related_Fixed_Asset__c,faAfterDep.book_value__c); 
       	    //------------Assert that the SKID Rental flag is unchecked after Return to inventory------------//
       	    system.assertEquals(serialLinkedtoAsset.SKID__r.Rental__c,false);
       	      //------------Assert that the SKID Used flag is checked after Return to inventory-----------//
       	    system.assertEquals(serialLinkedtoAsset.SKID__r.Used__c,true);
   		}
   		
    	Test.stopTest();	
            
    }
    static testMethod void retireTest() { 
	   	Test.startTest();	 
		
		Fixed_Asset__c fa = [SELECT id, name,Status__c,depreciation_method__c, depreciation_period__c, estimated_end_of_life__c, in_service_date__c, 
    								acquisition_cost__c, residual_value__c, date_last_depreciated__c, book_value__c, Fixed_Asset_Key__c,company__r.Comp_Currency__c,
    								company__c, company__r.Default_Transaction_Currency__c, Final_Depreciation_Date__c, depreciation_count__c,
    								Depreciation_Convention__c, depreciable_basis__c, Asset_Tag_Number__c, Total_Depreciated_Value__c,tax_book__c,
    								Asset_Class__r.GL_Account__c,Asset_Class__r.Depreciated_GL_Account__c ,Retirement_Type__c
    							FROM Fixed_Asset__c 
    							WHERE Asset_Tag_Number__c = '1010101' LIMIT 1];  
    		 
        fa.Retirement_Type__c             = 'Retire';
   		fa.In_Service_Date__c       	  = system.today().addMonths(-2);
   		fa.Depreciation_Life__c			  = 1;
    	update fa; 
        
       	    //-------------Running Depreciation-----------------
       		AccountingStraightLineDepreciation asld = new AccountingStraightLineDepreciation();
       		asld.execute(new List<sObject>{(sObject)fa}, system.today(), true); 
    	   	
    		PageReference newPage = Page.FixedAssetRetire;
    		newPage.getParameters().put('Id', fa.Id);
    		test.setCurrentPage(newPage);
    		
    		Apexpages.standardcontroller con = new Apexpages.Standardcontroller(fa);
    		FixedAssetRetireExt ext = new FixedAssetRetireExt(con);
    		ext.btn_Retire();
    		
    		//Assert the fa hasn't been retired because of missing disposition data
    		fa = [SELECT Id, status__c, acquisition_cost__c, book_value__c, residual_value__c,
    		                Asset_Class__r.Depreciated_GL_Account__c,Asset_Class__r.GL_Account__c
    		                FROM Fixed_Asset__c WHERE Id = :fa.Id];
    		system.assertNotEquals(fa.status__c, 'Retired');
    	    
    	   
    		
    		fa.Retirement_Type__c    = 'Retire';
    		fa.disposition_action__c = 'Sold';
    		fa.Disposition_Date__c = system.today();
    		update fa;
    		
    		con = new Apexpages.Standardcontroller(fa);
    		ext = new FixedAssetRetireExt(con);
    		ext.tmpFixedAsset.GL_Account__c = fa.Asset_Class__r.GL_Account__c; //glAcct.Id;
    		List<SelectOption> selOpts = ext.retirementOptions;
    		ext.btn_Retire();
	
		//Assert the fa has been retired
		fa = [SELECT Id, status__c, acquisition_cost__c, book_value__c,Asset_Class__r.GL_Account__c,
		            residual_value__c,Asset_Class__r.Depreciated_GL_Account__c,
		            (select id from Fixed_Asset_Depreciations__r)
		            FROM Fixed_Asset__c WHERE Id = :fa.Id];
		system.assert(fa.status__c == FixedAssetService.STATUS_RETIRED);
	   	test.stopTest(); 
		
    }
    
    static testMethod void testRetireParent(){
     
        Test.startTest();
        
    	GL_Account__c glAcct = [SELECT Id 
    							FROM GL_Account__c 
    							WHERE Name = '17000 - Property' 
    							LIMIT 1];
    		Company__c comp = [Select Id, comp_currency__c from Company__c where name = 'Kenandy' and Company_Identifier__c = 'KEN' limit 1];
        Asset_Class__c ac = new Asset_Class__c(Company__c = comp.Id,name = 'test', gl_account__c = glAcct.Id, depreciation_method__c = 'Declining Balance', 
                                               depreciation_period__c = 'Monthly', Declining_Balance__c = '200%', 
                                               Depreciation_Convention__c = 'Full Month');
        insert ac;
		
		Fixed_Asset__c fa = new Fixed_Asset__c(purchase_currency__c = comp.comp_currency__c,Company__c = comp.id,name = 'test', status__c = 'Active', asset_tag_number__c = '10101', 
		                                       asset_class__c = ac.Id,   fixed_asset_type__c = 'Accounting', 
		                                       in_service_Date__c = system.today(), acquisition_cost__c = 1000,purchase_price__c = 1000, residual_value__c = 100, 
		                                       depreciation_life__c = 12, Disposition_Date__c = system.today(), disposition_action__c = 'Sold',
		                                       Retirement_Type__c='Retire');
		insert fa;
	 
		
		Fixed_Asset__c faKey = [ select id, Fixed_Asset_Key__c from Fixed_Asset__c where id = :fa.id ];
		fa.Fixed_Asset_Key__c = faKey.Fixed_Asset_Key__c;
		
		Fixed_Asset_Depreciation__c fad = FixedAssetService.generateFixedAssetDepreciation(900, system.today(), 1000, fa, FixedAssetService.TYPE_DEPRECIATION);
		insert fad;
		
		Fixed_Asset__c faChild = new Fixed_Asset__c(purchase_currency__c = comp.comp_currency__c,Company__c = comp.id,name = 'testChild', Parent_Fixed_Asset__c = fa.id, status__c = 'Active', 
		                                            asset_tag_number__c = '10102', asset_class__c = ac.Id,
		                                            fixed_asset_type__c = 'Accounting', in_service_Date__c = system.today(), acquisition_cost__c = 1000,purchase_price__c = 1000,
		                                            residual_value__c = 100, depreciation_life__c = 12, Disposition_Date__c = system.today(),
		                                            disposition_action__c = 'Sold' ,Retirement_Type__c='Retire');
		insert faChild;
		
		Fixed_Asset__c faChildKey = [ select id, Fixed_Asset_Key__c from Fixed_Asset__c where id = :faChild.id ];
		faChild.Fixed_Asset_Key__c = faChildKey.Fixed_Asset_Key__c;
		
		Fixed_Asset_Depreciation__c fadChild = FixedAssetService.generateFixedAssetDepreciation(900, system.today(), 1000,
		                                    faChild, FixedAssetService.TYPE_DEPRECIATION);
		insert fadChild;
		
		Apexpages.standardcontroller con = new Apexpages.Standardcontroller(fa);
		FixedAssetRetireExt ext = new FixedAssetRetireExt(con);
		ext.tmpFixedAsset.GL_Account__c = glAcct.Id;
		//Assert the fa has not been retired as there is an unretired child
		system.assert( ext.isError );
		system.assert( ApexPages.getMessages().size() > 0 , ApexPages.getMessages());
		
		con = new Apexpages.Standardcontroller(faChild);
		ext = new FixedAssetRetireExt(con);
		ext.tmpFixedAsset.GL_Account__c = glAcct.Id;
		ext.btn_Retire();
		
		faChild = [SELECT Id, status__c, acquisition_cost__c, book_value__c, residual_value__c FROM Fixed_Asset__c WHERE Id = :faChild.Id];
		system.assert(faChild.status__c == FixedAssetService.STATUS_RETIRED);
		
		con = new Apexpages.Standardcontroller(fa);
		ext = new FixedAssetRetireExt(con);
		ext.tmpFixedAsset.GL_Account__c = glAcct.Id;
		
		
		//Assert the fa has been retired
		ext.btn_Retire();
		fa = [SELECT Id, status__c, acquisition_cost__c, book_value__c, residual_value__c FROM Fixed_Asset__c WHERE Id = :fa.Id];
		system.assert(fa.status__c == FixedAssetService.STATUS_RETIRED);
		
    	Test.stopTest();
    }
}