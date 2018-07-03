@isTest
private class FixedAssetNewExtTest { 

    static testMethod void testExtension() {
        TestData td = new TestData();
        
        
    	GL_Account__c glAcct = [SELECT Id 
    							FROM GL_Account__c 
    							WHERE Name = '17000 - Property' 
    							LIMIT 1];
    							
        Asset_Class__c ac = new Asset_Class__c(Company__c = td.company.Id,name = 'test', gl_account__c = glAcct.Id, depreciation_method__c = 'Declining Balance', depreciation_period__c = 'Monthly', Declining_Balance__c = '200%', Depreciation_Convention__c = 'Full Month');
        insert ac;
		Fixed_Asset__c fa = new Fixed_Asset__c(purchase_currency__c = td.company.comp_currency__c,Company__c = td.company.id, asset_tag_number__c = '10101',
											   asset_class__c = ac.Id, location__c = td.location.Id, fixed_asset_type__c = FixedAssetService.ASSET_ACCOUNTING,
											   in_service_Date__c = system.today(), acquisition_cost__c = 1000,purchase_price__c = 1000,  residual_value__c = 100, depreciation_life__c = 12);
		insert fa;
		
		Supplier_Invoice__c si = new Supplier_Invoice__c();
		si.Company__c = td.company.Id;
		si.Supplier__c = td.remittosupplier.Id;
		si.Currency__c = TestFuel.currencyUSD.id;
		si.date_invoiced__c = system.now();
		si.Status__c = 'In Process';
		//si.Finalized__c = true;
		si.invoice_amount__c = 1000;
		si.supplier_invoice__c = '1010110';
		insert si;
		
		Supplier_Invoice_Line__c ril = new Supplier_Invoice_Line__c();
		ril.supplier_invoice__c = si.Id;
		ril.purchase_order_line__c = td.purchaseOrder.purchase_order_lines__r[0].Id;
		ril.Purchase_Order__c = td.purchaseOrder.Id;
		ril.Quantity_Received__c = 10;
		ril.unit_price__c = 100;
		insert ril;
		
		
		Fixed_Asset__c newFixedAsset = new Fixed_Asset__c();
		Fixed_Asset__c taxBookFixedAsset = new Fixed_Asset__c();
		Fixed_Asset__C poFixedAsset = new Fixed_Asset__c();
		
		test.startTest();
		
			test.setCurrentPage(Page.FixedAssetNew);
			Apexpages.Standardcontroller newfasc = new Apexpages.Standardcontroller(newFixedAsset);
			FixedAssetNewExt newfa = new FixedAssetNewExt(newfasc);
			newfa.checkExistingAssets();
			newFixedAsset.Asset_Tag_Number__c = '20202';
			newfa.checkExistingAssets();
			system.assert(newfa.renderNewAsset);
			system.assert(!newfa.renderNewTaxBook);
			newfa.createNewFixedAsset();
			
			test.setCurrentPage(Page.FixedAssetNew);
			Apexpages.Standardcontroller tbfasc = new Apexpages.Standardcontroller(taxBookFixedAsset);
			FixedAssetNewExt tbfa = new FixedAssetNewExt(tbfasc);
			taxBookFixedAsset.Asset_Tag_Number__c = '10101';
			tbfa.checkExistingAssets();
			system.assert(!tbfa.renderNewAsset);
			system.assert(tbfa.renderNewTaxBook);
			tbfa.createNewTaxBook();
			
			test.setCurrentPage(Page.FixedAssetNew);
			Apexpages.Standardcontroller pofasc = new Apexpages.Standardcontroller(poFixedAsset);
			FixedAssetNewExt pofa = new FixedAssetNewExt(pofasc);
			pofa.selectedEntryType = 'SINGLE';
			poFixedAsset.supplier_invoice__c = si.Id;
			pofa.updateRILines();
			pofa.selectedRILId = ril.Id;
			pofa.openMultipleAssetPopUp();
			pofa.openCustomAssetPopUp();
			pofa.addAdditionalAsset();
			pofa.openSingleAssetPopUp();
			pofa.cancelPopUp();
			pofa.selectedRILId = ril.Id;
			pofa.openSingleAssetPopUp();
			//Assert that the controller found purchase order lines tied to the specified purchase order
			system.assert(pofa.addfixedAssets.size() > 0);
			for(integer i=0; i<pofa.addFixedAssets.size(); i++){
				pofa.addFixedAssets[0].asset_tag_number__c = string.valueOf(i);
				pofa.addFixedAssets[0].in_service_date__c = system.today();
				pofa.addFixedAssets[0].depreciation_life__c = 60;
				pofa.addFixedAssets[0].location__c = td.location.Id;
			}
			pofa.saveFixedAssets();
			pofa.generateRLFixedAssets();
			
			
		test.stopTest();
		
		
    }
}