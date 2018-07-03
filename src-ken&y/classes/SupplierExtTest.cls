/**
 * This class contains unit tests for validating the behavior of 
 * mehods in SupplierExtTest.cls
 */
@isTest
private class SupplierExtTest {
	public static TestFuel globalTestData = new TestFuel();
		
	public class TestDataForSupplierExt {
		public User_Preference__c userPref;{
			userPref = new User_Preference__c();
			userPref.Default_Company__c = globalTestData.company.Id;
			userPref.User__c = UserInfo.getUserId();
			insert userPref;
		}
	}
	
	static testMethod void testSupplierExt() {
		TestDataForSupplierExt localTestData = new TestDataForSupplierExt();
		
    	ApexPages.StandardController scon;
        SupplierExt suppExt;
        
        scon = new ApexPages.StandardController(new Supplier__c());
        suppExt = new SupplierExt(scon);
        
        system.assertNotEquals(null, suppExt.newSupplier);
        system.assertEquals(null, suppExt.newSupplier.Address__c);
        //system.assertEquals('Supplier', suppExt.newSupplier.Address__r.Type);//KNDY-11683
        system.assertNotEquals(null, suppExt.newSupplier.Company__c);
        
        scon = new ApexPages.StandardController(globalTestData.supplier);
        suppExt = new SupplierExt(scon);
        
        system.assertNotEquals(null, suppExt.newSupplier);
        system.assertNotEquals(null, suppExt.newSupplier.Id);
        system.assertEquals(globalTestData.company.Id, suppExt.newSupplier.Company__c);
    }
    
    static testMethod void testSave() {
		TestDataForSupplierExt localTestData = new TestDataForSupplierExt();
		
		string supplierName = SchemaUtil.getInstance().getLocalNameFromObject(new Supplier__c());
		Map<String, String> mRecTypes = KSE.RecordTypeDevNameMap(supplierName);
		Id purchaseRecTypeId = mRecTypes.get('Purchase_From');
		Id remitRecTypeId = mRecTypes.get('Remit_To'); 
		
    	ApexPages.StandardController scon;
        SupplierExt suppExt;
        
        scon = new ApexPages.StandardController(new Supplier__c());
        suppExt = new SupplierExt(scon);
        suppExt.newSupplier.Name = 'Test Supplier Ext';
        suppExt.newSupplier.Type__c = 'Purchasing';
        suppExt.newSupplier.Tax_ID__c = 'TIN12345';
        suppExt.newSupplier.Remit_To__c = globalTestData.remitToSupplier.Id;        
        suppExt.newSupplier.RecordTypeId = purchaseRecTypeId;
        suppExt.newSupplier.Supplier_Street__c = '303 Twin Dolphin Drive';
        suppExt.newSupplier.Supplier_City__c = 'Redwood City';
        suppExt.newSupplier.Supplier_State__c = 'CA';
        suppExt.newSupplier.Supplier_Zip_Code__c = '94156';
        suppExt.newSupplier.Supplier_Country__c = 'USA';
        suppExt.newSupplier.Street_1__c = 'Redwood Shores';
        suppExt.newSupplier.Street_2__c = 'Suite 500';
        
        suppExt.save();
        
        test.StartTest();        
        system.assertNotEquals(null, scon.getId());
        Supplier__c newSupplier = [select Id, Company__c, Address__c, Invoice_Matching__c, RecordType.Name, RecordType.DeveloperName, RecordTypeId, Street__c, Supplier_Street__c,Supplier_City__c,Supplier_State__c,Supplier_Zip_Code__c,Supplier_Country__c from Supplier__c where Id = :scon.getId()];
        system.assertEquals('Three Way', newSupplier.Invoice_Matching__c);
        system.assertEquals(null, newSupplier.Address__c);
        system.assertEquals(globalTestData.company.Id, newSupplier.Company__c);
        system.assert(newSupplier.Supplier_Country__c != '', 'New address field for country not null');//KNDY-11683
        system.assert(newSupplier.Supplier_Street__c != '', 'New address field for Street not null');
        system.assert(newSupplier.Supplier_State__c != '', 'New address field for State__c not null');
        system.assert(newSupplier.Supplier_City__c != '', 'New address field for City not null');
        system.assert(newSupplier.Supplier_Zip_Code__c != '', 'New address field for Zipcode not null');
        system.assert(newSupplier.Street__c == '303 Twin Dolphin Drive Redwood Shores Suite 500', 'Street field is not populated correct '+newSupplier.Street__c);
      
        Account acct = [select id, Account.Name, Account.Type from Account where Id =:globalTestData.account.id];
        newSupplier.Address__c = acct.Id;
        newSupplier.Address__r = acct;
        update newSupplier;

        Supplier__c newSupp1 = [select Id, Supplier_Id__c, Aliases__c, Currency__c, Remit_To__c, Company__c,Minimum_Shelf_Life_In_Days__c, DUNS_Number__c, Name, Type__c, Parent_Supplier__c, Top_Parent_Supplier__c, Status__c, Address__c, Address__r.Name, Address__r.Type, Invoice_Matching__c, RecordType.Name, RecordType.DeveloperName, RecordTypeId, Street__c, Supplier_Street__c,Supplier_City__c,Supplier_State__c,Supplier_Zip_Code__c,Supplier_Country__c from Supplier__c where Id = :newSupplier.id];
  
        ApexPages.StandardController scon1 = new ApexPages.StandardController(newSupp1);
        SupplierExt suppExt1 = new SupplierExt(scon1);
        suppExt1.save();
        
        Supplier__c newSupp = [select Id, Company__c, Address__c, Address__r.Name, Address__r.Type, Invoice_Matching__c, RecordType.Name, RecordType.DeveloperName, RecordTypeId, Street__c, Supplier_Street__c,Supplier_City__c,Supplier_State__c,Supplier_Zip_Code__c,Supplier_Country__c from Supplier__c where Id = :scon1.getId()];
        system.assertNotEquals(newSupp.Address__r.Name, 'Test Supplier Ext');
        system.assertNotEquals(newSupp.Address__r.Type, 'Supplier');
        system.assertEquals(newSupp.Address__r.Name, acct.Name);
        system.assertEquals(newSupp.Address__r.Type, null);
        test.StopTest();

    }
    
    static testMethod void testCloneSupplier() {
		TestDataForSupplierExt localTestData = new TestDataForSupplierExt();
		
		string supplierName = SchemaUtil.getInstance().getLocalNameFromObject(new Supplier__c());
		Map<String, String> mRecTypes = KSE.RecordTypeDevNameMap(supplierName);
		Id purchaseRecTypeId = mRecTypes.get('Purchase_From');
		Id remitRecTypeId = mRecTypes.get('Remit_To'); 
				
		
    	ApexPages.StandardController scon;
        SupplierExt suppExt;
        
        Supplier__c supplier = [select Id,  Company__c, Address__c, Name, Tax_ID__c, Type__c 
        						,RecordType.Name, RecordType.DeveloperName, RecordTypeId,
                                Supplier_Street__c,Supplier_City__c,Supplier_State__c,Supplier_Zip_Code__c,Supplier_Country__c 
                                from Supplier__c where Id = :globalTestData.supplier.Id];
        
        scon = new ApexPages.StandardController(supplier);
        suppExt = new SupplierExt(scon);
        suppExt.newSupplier.Name = 'Test Supplier Ext 2';
        suppExt.newSupplier.Type__c = 'Remit-To';
        suppExt.newSupplier.Tax_ID__c = 'TIN12345';
        suppExt.newSupplier.RecordTypeId = remitRecTypeId;
        
        
        suppExt.cloneSupplier();
        
        system.assertNotEquals(null, suppExt.newSupplier.Id);
        Supplier__c clonedSupplier = [select Id, Company__c, Address__c,RecordType.Name, RecordType.DeveloperName, RecordTypeId, Supplier_Street__c,Supplier_City__c,Supplier_State__c,Supplier_Zip_Code__c,Supplier_Country__c from Supplier__c where Id = :suppExt.newSupplier.Id];
        system.assertEquals(globalTestData.supplier.Address__c, clonedSupplier.Address__c); //test for not creating a new account when address stays the same
        system.assertEquals(globalTestData.company.Id, clonedSupplier.Company__c);
        
        //test when address changes, it creates a new account
        scon = new ApexPages.StandardController(supplier);
        suppExt = new SupplierExt(scon);
        suppExt.newSupplier.Name = 'Test Supplier Ext 3';
        suppExt.newSupplier.Type__c = 'Remit-To';
        suppExt.newSupplier.Tax_ID__c = 'TIN12345';
        suppExt.newSupplier.Supplier_City__c = 'A New City'; //KNDY-11683
        suppExt.newSupplier.RecordTypeId = remitRecTypeId;
        suppExt.cloneSupplier();
        clonedSupplier = [select Id, Company__c, Address__c, Supplier_City__c from Supplier__c where Id = :suppExt.newSupplier.Id];
        system.assertEquals(globalTestData.supplier.Address__c, clonedSupplier.Address__c);
        system.assertNotEquals(globalTestData.supplier.Supplier_City__c, clonedSupplier.Supplier_City__c);
        //system.assertEquals(clonedSupplier.Address__r.Type, 'Supplier');
        
    }
}