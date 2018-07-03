@isTest
public class BracketPricingUpchargeManageExtTest  {
    static Company__c company ;
    static {
        Account account = new Account();
        account = new Account();
        account.name = 'Kenandy';
        account.billingstreet = '303 Twin Dolphin Drive, Suite 500';
        account.billingcity = 'Redwood City';
        account.billingstate = 'CA';
        account.billingpostalcode = '94065';
        account.billingcountry = 'USA';
        account.shippingstreet = '303 Twin Dolphin Drive, Suite 500';
        account.shippingcity = 'Redwood City';
        account.shippingstate = 'CA';
        account.shippingpostalcode = '94065';
        account.shippingcountry = 'USA';
        account.phone = '650-468-2000';
        account.fax = '650-468-2010';
        account.website = 'kenandy.com';
        insert account;

        company = new Company__c();
        company.name = 'Kenandy';
        company.Address__c = account.ID;
        company.A_Days__c = 30;
        company.B_Days__c = 60;
        company.C_Days__c = 180;
        company.Consol_Currency__c = TestFuel.currencyEUR.id;
        company.Stat_Currency__c = TestFuel.currencyGBP.id;
        company.Subs_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        insert company;

    }
    

    /*
 		Create good bracket data with valid inputs
    */
    testmethod static void testBracketCreation() {
        // Implement test code
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(company));
        
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        System.assertEquals(5, bracketWraps.size());
        for (BracketPricingUpchargeManageExt.BracketPriceWrapper wrap : bracketWraps) {
            System.assertEquals(null, wrap.reasonCode.Id);
            System.assertEquals(BracketPricingService.TypeBracketPricingUpcharge, wrap.reasonCode.Type__c);
            System.assertEquals(company.Id, wrap.reasonCode.Company__c);
            System.assertEquals('Price__c', wrap.pricebookLineField);
            System.assert(wrap.volumeRangeBottom == null || wrap.volumeRangeBottom == 0);
            System.assert(wrap.percentUpcharge == null || wrap.percentUpcharge == 0);
        }
        
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2,brack3,brack4,brack5;
        
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 0;
        brack1.percentUpcharge = 0;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 50;
        brack2.percentUpcharge = 1;
        brack2.pricebookLineField = 'Price_2__c';

        // Create bracket 3
        brack3 = bracketWraps[2];
        brack3.inUse = true;
        brack3.volumeRangeBottom = 100;
        brack3.percentUpcharge = 2;
        brack3.pricebookLineField = 'Price_3__c';

        // Create bracket 4
        brack4 = bracketWraps[3];
        brack4.inUse = true;
        brack4.volumeRangeBottom = 150;
        brack4.percentUpcharge = 3;
        brack4.pricebookLineField = 'Price_4__c';

        // Create bracket 5
        brack5 = bracketWraps[4];
        brack5.inUse = true;
        brack5.volumeRangeBottom = 200;
        brack5.percentUpcharge = 4;
        brack5.pricebookLineField = 'Price_5__c';

        // Persist to DB
        ext.onSave();
		
		assertMessages(Apexpages.getMessages(), Apexpages.Severity.INFO);

        // Reload extension to verify
        ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(company));
        
        // re fetch the new references
        for (Integer idx = 0; idx < ext.bracketWraps.size(); idx++) {
            assertBracketPriceWrapperEquals(bracketWraps[idx], ext.bracketWraps[idx]);
        }
    }

    /*
 		Create bad bracket data with validation errors for price fields
    */
    testmethod static void testValidationErrorsForDuplicatePriceFields() {
        // Implement test code
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(company));
        
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2;
        
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 0;
        brack1.percentUpcharge = 0;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2 with bad data
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 50;
        brack2.percentUpcharge = 1;
        brack2.pricebookLineField = 'Price__c'; // << Bad input as the price field is repeated

        // Persist to DB
        ext.onSave();
		
		assertMessages(Apexpages.getMessages(), Apexpages.Severity.ERROR);
    }
	
	 /*
 		Create bad bracket data with validation errors for Volumne range bottom fields
    */
    testmethod static void testValidationErrorsForDuplicateVolumneRangeBottomFields() {
        // Implement test code
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(company));
        
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2;
        
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 50;
        brack1.percentUpcharge = 0;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2 with bad data
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 50; // << Bad input as the this is repeated
        brack2.percentUpcharge = 1;
        brack2.pricebookLineField = 'Price_2__c'; 

        // Persist to DB
        ext.onSave();
		
		assertMessages(Apexpages.getMessages(), Apexpages.Severity.ERROR);
    }
    
     /*
 		Create bad bracket data with validation errors for percent upcharge fields
    */
    testmethod static void testValidationErrorsForDuplicatePercentUpchargeFields() {
        // Implement test code
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(company));
        
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2;
        
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 10;
        brack1.percentUpcharge = 1;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2 with bad data
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 50; 
        brack2.percentUpcharge = 1; // << Bad input as the this is repeated
        brack2.pricebookLineField = 'Price_2__c'; 

        // Persist to DB
        ext.onSave();
		
		assertMessages(Apexpages.getMessages(), Apexpages.Severity.ERROR);
    }
	
	
	 /*
 		Create bracket data and try deleting it
    */
    testmethod static void testDeletionOfBrackets() {
        // Implement test code
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(company));
        
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2;
        
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 10;
        brack1.percentUpcharge = 1;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2 with bad data
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 50; 
        brack2.percentUpcharge = 2; 
        brack2.pricebookLineField = 'Price_2__c'; 

        // Persist to DB
        ext.onSave();
		// no errors
		assertMessages(Apexpages.getMessages(), Apexpages.Severity.INFO);
		
		// fetch from database to confirm
		BracketPricingService.BracketPrice[] dbBrackets = BracketPricingService.loadBracketPrices(new Set<Id>{company.Id}).get(company.Id);
		System.debug (dbBrackets);
		System.assertEquals(2, dbBrackets.size());
		assertBracketPriceEquals(brack1, dbBrackets[0]);
		assertBracketPriceEquals(brack2, dbBrackets[1]);
		
		// Delete this one by marking not in use
		ext.bracketWraps[1].inUse = false; 
		ext.onSave();
		// Should save without issues
		assertMessages(Apexpages.getMessages(), Apexpages.Severity.INFO);
		
		// 1 less bracket should come now from DB
		dbBrackets = BracketPricingService.loadBracketPrices(new Set<Id>{company.Id}).get(company.Id);
		System.assertEquals(1, dbBrackets.size());
   		assertBracketPriceEquals(brack1, dbBrackets[0]);	
    }
	
	
	 /*
 		Create bracket data check if ranges are correct
    */
    testmethod static void testBracketRanges() {
        // Implement test code
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(company));
        
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2;
        
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 10;
        brack1.percentUpcharge = 1;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2 with bad data
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 50; 
        brack2.percentUpcharge = 2; 
        brack2.pricebookLineField = 'Price_2__c'; 

        // Persist to DB
        ext.onSave();
		// no errors
		assertMessages(Apexpages.getMessages(), Apexpages.Severity.INFO);
		
		// fetch from database to confirm
		BracketPricingService.BracketPriceRange[] dbBracketRanges = BracketPricingService.loadBracketPricesWithRange(new Set<Id>{company.Id}).get(company.Id);
		System.debug (dbBracketRanges);
		System.assertEquals(2, dbBracketRanges.size());
		
		System.assertEquals(49, dbBracketRanges[0].volumeRangeHigh);
		System.assertEquals(BracketPricingService.MaxVolumeRangeValue, dbBracketRanges[1].volumeRangeHigh);
    }
	
	
	static void assertMessages(Apexpages.Message[] msgs, Apexpages.Severity expectedSev) {
		System.debug(msgs);
		for (Apexpages.Message msg : Apexpages.getMessages()) {
			Apexpages.Severity sev = msg.getSeverity(); 
			System.assertEquals(expectedSev, sev);	
		}
		
	}
	
	static void assertBracketPriceEquals(BracketPricingService.BracketPrice expected, BracketPricingService.BracketPrice actual) {
        System.assertEquals(expected.volumeRangeBottom, actual.volumeRangeBottom);
        System.assertEquals(expected.percentUpcharge, actual.percentUpcharge);
        System.assertEquals(expected.pricebookLineField, actual.pricebookLineField);        
    }
    
    static void assertBracketPriceWrapperEquals(BracketPricingUpchargeManageExt.BracketPriceWrapper expected, BracketPricingUpchargeManageExt.BracketPriceWrapper actual) {
        System.assertEquals(expected.inUse, actual.inUse);
        System.assertEquals(expected.volumeRangeBottom, actual.volumeRangeBottom);
        System.assertEquals(expected.percentUpcharge, actual.percentUpcharge);
        System.assertEquals(expected.pricebookLineField, actual.pricebookLineField);        
    }

    static void test_method_two() {
        // Implement test code
    }

}