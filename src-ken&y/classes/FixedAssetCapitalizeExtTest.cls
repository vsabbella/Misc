@isTest
private class FixedAssetCapitalizeExtTest { 
	
	//--------Test data setup for all methods in this class----------//
	@testSetup
	static void allTheDataForThisTestClass() {
	    //Arun: moved out of test setup as FixedAssetTest.FixedAssetData is doing a lot of computation and with some new things in
	    //testData.cls , this was hitting too many soql within test setup 
	}
	
	static testMethod void testCapitalizeAsset() { 
         FixedAssetData fad = new FixedAssetData();
        
        Test.startTest();
        Currency__c defaultCurr = [Select Id from Currency__c where Id =: fad.td.company.Comp_Currency__c];
	    Fixed_Asset__c slfa = new Fixed_Asset__c();
    	slfa.company__c = fad.td.company.Id;
    	slfa.Asset_Class__c = fad.slac.Id;
    	slfa.Asset_Tag_Number__c = '5050505';
    	slfa.Date_Purchased__c = system.today().addYears(-5);
    	slfa.In_Service_Date__c = system.today().addYears(-5);
    	slfa.Acquisition_Cost__c = 38000;
        slfa.Purchase_Price__c = slfa.Acquisition_Cost__c;
        slfa.Purchase_Currency__c = defaultCurr.Id;
    	slfa.Depreciation_Life__c = 60;
    	slfa.Status__c = FixedAssetService.STATUS_CIP;
    	slfa.Residual_Value__c = 2000;
    	slfa.Fixed_Asset_Type__c = FixedAssetService.ASSET_ACCOUNTING;
    	slfa.Tax_Book__c = fad.corp.Id;
	   	insert slfa;
	    	
		Apexpages.Standardcontroller Con = new Apexpages.Standardcontroller(slfa);
    	test.setCurrentPage(page.FixedAssetCapitalize);
    	FixedAssetCapitalizeExt ext = new FixedAssetCapitalizeExt(Con);
    	system.assert(ext.isValid);
    	ext.btn_Capitalize();
    	Test.stopTest();

    	Fixed_Asset__c fa = [SELECT Id, status__c,
    							 (SELECT id ,finalized__c FROM Fixed_Asset_Depreciations__r)
    						   FROM Fixed_Asset__c 
    						   WHERE Id =:slfa.Id];
    	List<Fixed_Asset_Depreciation__c> fads = fa.Fixed_Asset_Depreciations__r;
    
    	system.assert(fa.status__c == FixedAssetService.STATUS_ACTIVE);
    	system.assert(fads.size()>0);
    	system.assertEquals(fads[0].finalized__c,true);
    	
    }
	
    static testMethod void testCapitalizeAssets() {
        
        FixedAssetData fad = new FixedAssetData();
        
        Test.startTest();
        Currency__c defaultCurr = [Select Id from Currency__c where Id =: fad.td.company.Comp_Currency__c];
	    Fixed_Asset__c slfa = new Fixed_Asset__c();
    	slfa.company__c = fad.td.company.Id;
    	slfa.Asset_Class__c = fad.slac.Id;
    	slfa.Asset_Tag_Number__c = '5050505';
    	slfa.Date_Purchased__c = system.today().addYears(-5);
    	slfa.In_Service_Date__c = system.today().addYears(-5);
    	slfa.Acquisition_Cost__c = 38000;
        slfa.Purchase_Price__c = slfa.Acquisition_Cost__c;
        slfa.Purchase_Currency__c = defaultCurr.Id;
    	slfa.Depreciation_Life__c = 60;
    	slfa.Status__c = FixedAssetService.STATUS_CIP;
    	slfa.Residual_Value__c = 2000;
    	slfa.Fixed_Asset_Type__c = FixedAssetService.ASSET_ACCOUNTING;
    	slfa.Tax_Book__c = fad.corp.Id;
	    	
	    insert slfa;
	    	
	    List<Fixed_Asset__c> fixedAssetsToCapitalize = [SELECT id 
	                                FROM Fixed_Asset__c LIMIT 2]; 
    	Apexpages.Standardsetcontroller ssCon = new Apexpages.Standardsetcontroller(fixedAssetsToCapitalize);
    	ssCon.setSelected(fixedAssetsToCapitalize);
    	
    	test.setCurrentPage(page.FixedAssetsCapitalize); 
    	FixedAssetCapitalizeExt ext = new FixedAssetCapitalizeExt(ssCon); 
    	
    	system.assert(!ext.hasInvalid, 'both sample assets are valid');
    	
    	ext.btn_CapitalizeAssets();
        Test.stopTest();
     
    	for(Fixed_Asset__c faCapitalized  : [SELECT Id, status__c 
    	                                            FROM Fixed_Asset__c 
    	                                            WHERE id in :fixedAssetsToCapitalize ]){
    		system.assertEquals(FixedAssetService.STATUS_ACTIVE,faCapitalized.status__c);
    	}
    	
    }
    
    static testMethod void testCapitalizeActiveAsset() {
        
         FixedAssetData fad = new  FixedAssetData();
        
        Test.startTest();
        
        Currency__c defaultCurr = [Select Id from Currency__c where Id =: fad.td.company.Comp_Currency__c];
	    Fixed_Asset__c slfa = new Fixed_Asset__c();
    	slfa.company__c = fad.td.company.Id;
    	slfa.Asset_Class__c = fad.slac.Id;
    	slfa.Asset_Tag_Number__c = '5050505';
    	slfa.Date_Purchased__c = system.today().addYears(-5);
    	slfa.In_Service_Date__c = system.today().addYears(-5);
    	slfa.Acquisition_Cost__c = 38000;
    	slfa.Purchase_Price__c = slfa.Acquisition_Cost__c;
        slfa.Purchase_Currency__c = defaultCurr.Id;
        slfa.Depreciation_Life__c = 60;
    	slfa.Status__c = FixedAssetService.STATUS_CIP;
    	slfa.Residual_Value__c = 2000;
    	slfa.Fixed_Asset_Type__c = FixedAssetService.ASSET_ACCOUNTING;
    	slfa.Tax_Book__c = fad.corp.Id;
	    	
	    insert slfa;
	    	
	    slfa.In_Service_Date__c = system.today().addDays(1);
        update slfa;
        
    	Apexpages.Standardcontroller Con = new Apexpages.Standardcontroller(slfa);
    	
    	pageReference testPage = page.FixedAssetCapitalize;
    	testPage.getParameters().put('Id', slfa.Id);
    	
    	test.setCurrentPage(testPage);
    	
    	FixedAssetCapitalizeExt ext = new FixedAssetCapitalizeExt(Con);
        Test.stopTest();
        system.assert(!ext.isValid);
    	
    }
}