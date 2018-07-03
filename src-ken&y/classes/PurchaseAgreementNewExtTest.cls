@isTest
private class PurchaseAgreementNewExtTest {

    static testMethod void createNewPAWithDefaultTolerances() {
    	SKIDServiceTest.TestDataForSkidService sstestData = new SKIDServiceTest.TestDataForSkidService();
		sstestData.company.Default_Amount_Tolerance__c = 100;
		sstestData.company.Default_Quantity_Tolerance_Over__c = 10;
		//sstestData.company.Default_Quantity_Tolerance_Under__c = 5;
		sstestData.company.Default_Unit_Price_Tolerance_Over__c = 10;
		//sstestData.company.Default_Unit_Price_Tolerance_Under__c = 3;
		update sstestData.company;
		User_Preference__c up = new User_Preference__c();{
			up.Default_Company__c = sstestData.company.id;
			up.ownerID = userinfo.getUserID();
			up.Default_Facility__c = sstestData.facility.Id;
        	insert up;
        }
		//Create payment terms info
         Payment_Term__c paymentTermInfo = new Payment_Term__c();{
        	paymentTermInfo.Name = '2/10 Net 30';
        	paymentTermInfo.Description__c = '2% discount in 10 days, due 30 days';
        	paymentTermInfo.Discount_Days__c = 10;
        	paymentTermInfo.Discount_Percent__c = 2.0;
        	paymentTermInfo.Due_Days__c = 30;
            insert paymentTermInfo;
        }
        
         FOB_Terms__c fobTerms = new FOB_Terms__c();{
        	fobTerms.name = 'FOB Term 1';
        	insert fobTerms;
        }
        map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c');
        
        //Create Supplier, assign remit and payment terms info
        Supplier__c remittosupplier = new Supplier__c();{
            remittosupplier.Name = 'Test Remit To';
            remittosupplier.Payment_Term__c = paymentTermInfo.Id;
            remittosupplier.Status__c = 'Active';
        	remittosupplier.Type__c = 'Remit-To';
        	remittosupplier.RecordTypeId = rtMap.get('Remit_To');
            insert remittosupplier;
        }
        
        Supplier__c supplier = new Supplier__c();{
            supplier.Name = 'Test';
            supplier.Payment_Term__c = paymentTermInfo.Id;
            supplier.Status__c = 'Active';
        	supplier.Type__c = 'Purchasing';
        	supplier.RecordTypeId = rtMap.get('Purchase_From');
        	supplier.Remit_To__c =  remittosupplier.id;
        	supplier.fob_term__c = fobterms.id;
            insert supplier;
        }
        
		Test.startTest();
		PurchaseAgreementNewExt ext = new PurchaseAgreementNewExt (new Apexpages.Standardcontroller( new Contract__c() ));
        ext.newPA.Contract_Start__c = system.today();
        ext.newPA.Contract_End__c = system.today() + 3;
        ext.newPA.Supplier__c = supplier.id;
        ext.newPA.Payment_Term__c = paymentTermInfo.id;
        //ext.newPA.FOB_Term__c = fobTerms.id; PTP-123 Commenting this line to verify if the FOB is defaulted from the Supplier
        ext.newPA.Transportation_Mode__c = 'RAIL';
        
        Pagereference p0 = ext.savePA();
        system.assert(p0!=null,' expected a view page save not null ' + ApexPages.getMessages());
        
        String url = p0.getUrl();
        
        url = url.replaceAll('/','');
        Contract__c pa = [select id, Payment_Term__c, FOB_Term__c, Transportation_Mode__c, Amount_Tolerance__c, Quantity_Tolerance_Over__c, Unit_Price_Tolerance_Over__c from Contract__c where id = :url limit 1];
        system.assert( pa != null );
        system.debug('pa: ' + pa);
        system.assert(pa.Amount_Tolerance__c == 100, 'Defaulting from company did not work');
        system.assert(pa.Quantity_Tolerance_Over__c == 10, 'Defaulting from company did not work');
        system.assert(pa.Unit_Price_Tolerance_Over__c == 10, 'Defaulting from company did not work');
        //system.assert(pa.Unit_Price_Tolerance_Under__c == 3, 'Defaulting from company did not work');
    	system.assert(pa.Payment_Term__c != null);
    	system.assert(pa.FOB_Term__c != null);
    	system.assert(pa.FOB_Term__c == supplier.FOB_Term__c); //PTP-123 check if FOB is defaulted to Supplier's FOB 
    	system.assert(pa.Transportation_Mode__c == 'RAIL');
    }
}