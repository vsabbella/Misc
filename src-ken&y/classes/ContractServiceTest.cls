/**
 *
 */
@isTest
private class ContractServiceTest {

	static TestFuel fuel = new TestFuel();
	
    /*
		Test for defaulting payment terms from Supplier to Purchasing Contract Header
	*/
	static testMethod void testToDefaultPymtTermsFromSupplier() {
		
		fuel.supplier.Invoice_Matching__c = 'Three Way';
		update fuel.supplier;
		//Contract
        Contract__c contract = new Contract__c();
        contract.Name = 'TestContract';
        contract.Contract_Start__c = Date.today().addDays(-1);
        contract.Contract_End__c = Date.today().addDays(4);
        contract.OwnerID = System.Userinfo.getUserId();
        contract.Status__c = 'Open';
        contract.Company__c = fuel.company.id;
        contract.Supplier__c = fuel.supplier.id;
        insert contract;
        
        Contract_Line__c contractItem = new Contract_Line__c();
        contractItem.Contract__c = contract.Id;
        contractItem.Contract_Start__c = Date.today().addDays(-1);
        contractItem.Contract_End__c = Date.today().addDays(4);
        contractItem.Status__c = 'Active';
        contractItem.Negotiated_Price__c = 100;
        contractItem.Item__c = fuel.itemList[1].id;
        contractItem.Purchase_UOM__c = fuel.uomList[8].Id;
        contractItem.Contract_Quantity__c = 10;
        contractItem.Invoice_Matching__c = '';
        insert contractItem;
        
        Test.StartTest();
		
		Contract__c ct = [select id, name, payment_term__c, Approval_Status__c, payment_term__r.name from Contract__c where id =: contract.id];
		system.assertEquals(ct.Approval_Status__c,  'Pending Authorization');
		system.debug('ct: ' + ct);
		system.assertNotEquals(null, ct.Payment_Term__c);
		system.assertEquals('2/10 Net 30', ct.Payment_Term__r.Name);
		
		Contract_Line__c ctl = [select id, Contract_Quantity__c, Invoice_Matching__c, Approved__c from Contract_Line__c where id =:contractItem.id];
		system.assertEquals('Three Way', ctl.Invoice_Matching__c);
		
		
		
		//test for flip PA Approval Status .....KNDY-11429
		ct.Approval_Status__c = 'Approved';
		update ct;
		
		ctl.Contract_Quantity__c = 15;
		update ctl;
		
		Contract__c con = [select id, name, payment_term__c, payment_term__r.name, Approval_Status__c from Contract__c where id =: contract.id];
		system.assertEquals(con.Approval_Status__c, 'Pending Authorization');
		
		con.Approval_Status__c = 'Approved';
		update con;
		
		Contract_Line__c contractLine = new Contract_Line__c();
        contractLine.Contract__c = contract.Id;
        contractLine.Contract_Start__c = Date.today().addDays(-1);
        contractLine.Contract_End__c = Date.today().addDays(4);
        contractLine.Status__c = 'Active';
        contractLine.Negotiated_Price__c = 100;
        contractLine.Item__c = fuel.itemList[1].id;
        contractLine.Purchase_UOM__c = fuel.uomList[8].Id;
        contractLine.Contract_Quantity__c = 10;
        insert contractLine;
        
        Contract__c pa = [select id, name, payment_term__c, payment_term__r.name, Approval_Status__c from Contract__c where id =: contract.id];
		system.assertEquals(pa.Approval_Status__c, 'Pending Authorization');
        
		Test.stopTest();
	}

    /*
     * @description  
     */
    static testMethod void ContractClassTest() {
        
        //Test data for checkForContractItemExistance
        
        //Company 
        Company__c company = new Company__c();
        company.name = 'TestDataCo';
        company.A_Days__c = 6;
        company.B_Days__c = 20;
        company.C_Days__c = 90;
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        company.Consol_Currency__c = TestFuel.currencyGBP.id;
        company.Stat_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        company.Subs_currency__c = TestFuel.currencyUSD.id;
        
        insert company;
        
        //Business partner
        
        //Query for Supplier recordtype
        //RecordType suppRecordType = [select Id from RecordType where DeveloperName = 'Supplier' and SObjectType = 'Business_Partner__c'];
        map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c');
        
        Supplier__c businessPartner = new Supplier__c();
        businessPartner.name = 'Business partner test';
        businessPartner.Company__c = company.id;
		businessPartner.Status__c = 'Active';
		businessPartner.Type__c = 'Remit-To';
        businessPartner.RecordTypeId = rtMap.get('Remit_To');
        insert businessPartner;
        
        Payment_Term__c paymentTermInfo = new Payment_Term__c();{
        	paymentTermInfo.Name = '2/10 Net 30';
        	paymentTermInfo.Description__c = '2% discount in 10 days, due 30 days';
        	paymentTermInfo.Discount_Days__c = 10;
        	paymentTermInfo.Discount_Percent__c = 2.0;
        	paymentTermInfo.Due_Days__c = 30;
            insert paymentTermInfo;
        }
        // UOM
        UOM__c uomEach = new UOM__c();
        uomEach.name = 'EA';
        insert uomEach;
        
        //Item
        Item__c item = new Item__c();
        item.name='TestItems';
        item.Description__c='TestItem';
        item.company__c = company.id;
        item.Stocking_UOM__c = uomEach.Id;
        item.Packaging_UOM__c = JSON.serialize(new List<Id>{uomEach.Id});
        insert item;
           
        //Contract
        Contract__c contract = new Contract__c();
        contract.Name = 'TestContract';
        contract.Contract_Start__c = Date.today().addDays(-1);
        contract.Contract_End__c = Date.today().addDays(4);
        contract.OwnerID = System.Userinfo.getUserId();
        contract.Status__c = 'Open';
        
        insert contract;
        
        //Contract Item that is active
        Contract_Line__c contractItem = new Contract_Line__c();
        contractItem.Contract__c = contract.Id;
        contractItem.Contract_Start__c = Date.today().addDays(-1);
        contractItem.Contract_End__c = Date.today().addDays(4);
        contractItem.Status__c = 'Open';
        contractItem.Negotiated_Price__c = 100;
        contractItem.Item__c = item.id;
        contractItem.Purchase_UOM__c = uomEach.Id;
        contractItem.Contract_Quantity__c = 10;
        insert contractItem;
        
        //Crate a new instance of the current class
        ContractService CC = new ContractService();     
        
        //Check for the previous existance of a contract item for same purchase UOM with an overlaping valid dates
    
        Contract_Line__c contractItemOverlap = new Contract_Line__c();
        contractItemOverlap.Contract__c = contract.Id;
        contractItemOverlap.Contract_Start__c = Date.today().addDays(-1);
        contractItemOverlap.Contract_End__c = Date.today().addDays(4);
        contractItemOverlap.Status__c = 'Open';
        contractItemOverlap.Negotiated_Price__c = 100;
		contractItemOverlap.Item__c = item.id;
		contractItemOverlap.Purchase_UOM__c = uomEach.Id;
        contractItemOverlap.Contract_Quantity__c = 10;
        List<Contract_Line__c> contractItemsList = new List<Contract_Line__c>();

        contractItemsList.add(contractItemOverlap);
		Boolean isSuccess = true;
        try{
            insert contractItemsList; // after trigger will check for duplicates
        }catch(Exception e){
            isSuccess = false;
            system.assertnotequals(null, e);
            system.assert(e.getMessage().contains(Label.Duplicate_open_lines_exist_with_given_start_end_dates));
        }
        system.assert(isSuccess == false);
        //Inactivate the contract item
        contractItem.Status__c = 'Closed';
        update contractItem;
        

        //Test data for contract item purchased amount
        
        //Purchase Order
        //create a new PO record
        Purchase_Order__c purchaseOrder = new Purchase_Order__c();
        purchaseOrder.Order_Date__c = Date.today();
        purchaseOrder.Supplier__c = businessPartner.Id;
        purchaseOrder.Company__c = company.Id;
        
        insert purchaseOrder;
        
        
        //Purchase order line
        Purchase_Order_Line__c poline = new Purchase_Order_Line__c();
        poline.Order_Quantity__c = 1;
        //poline.Unit_Price__c = MCR1.Purchase_Price__c;
        poline.Unit_Price__c = 1;
        poline.Purchase_Order__c = purchaseOrder.Id;
        poline.Company__c = item.Company__c;  
        poline.Indirect__c = true;
        poline.Need_Date__c = Date.today().addDays(10);
        poline.Item__c = item.Id;
        poline.Purchase_UOM__c = uomEach.Id;
        //poline.Contract_Line__c = contractItem.Id;

        insert poline;
        
        Contract_Line__c citem = [select PurchasedValue__c, Remaining_Value_Percent__c from Contract_Line__c where id = :contractItem.Id];
        
        System.debug('citem: ' + citem);
        
        //Update poline
        poline.Order_Quantity__c = 9;
        
        update poline;
		//KNDY-5046
        //test Contract.trigger delete
        delete contract;
        
    }
    
    // Inserting a line with different uom in overlapping date ranges for same item
    static testMethod void testUniquePALine(){ //KNDY-10599
        //Company 
        Company__c company = new Company__c();
        company.name = 'TestDataCo';
        company.A_Days__c = 6;
        company.B_Days__c = 20;
        company.C_Days__c = 90;
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        company.Consol_Currency__c = TestFuel.currencyGBP.id;
        company.Stat_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        company.Subs_currency__c = TestFuel.currencyUSD.id;        
        insert company;

        //Query for Supplier recordtype
        //RecordType suppRecordType = [select Id from RecordType where DeveloperName = 'Supplier' and SObjectType = 'Business_Partner__c'];
        map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c');
        
        Supplier__c businessPartner = new Supplier__c();
        businessPartner.name = 'Business partner test';
        businessPartner.Company__c = company.id;
        businessPartner.Status__c = 'Active';
        businessPartner.Type__c = 'Remit-To';
        businessPartner.RecordTypeId = rtMap.get('Remit_To');
        insert businessPartner;
        
        Payment_Term__c paymentTermInfo = new Payment_Term__c();{
            paymentTermInfo.Name = '2/10 Net 30';
            paymentTermInfo.Description__c = '2% discount in 10 days, due 30 days';
            paymentTermInfo.Discount_Days__c = 10;
            paymentTermInfo.Discount_Percent__c = 2.0;
            paymentTermInfo.Due_Days__c = 30;
            insert paymentTermInfo;
        }
        // UOM
        UOM__c uomEach = new UOM__c();
        uomEach.name = 'EA';
        UOM__c uomDozen = new UOM__c();
        uomDozen.name = 'DZ';
        List<UOM__c> uoms = new List<UOM__c>{uomEach, uomDozen};
        insert uoms;
        
        //Item
        Item__c item = new Item__c();
        item.name='TestItems';
        item.Description__c='TestItem';
        item.company__c = company.id;
        insert item;
           
        //Contract
        Contract__c contract = new Contract__c();
        contract.Name = 'TestContract';
        contract.Contract_Start__c = Date.today().addDays(-1);
        contract.Contract_End__c = Date.today().addDays(4);
        contract.OwnerID = System.Userinfo.getUserId();
        contract.Status__c = 'Open';
        
        insert contract;
        
        //Contract Item that is open
        Contract_Line__c contractItem = new Contract_Line__c();
        contractItem.Contract__c = contract.Id;
        contractItem.Contract_Start__c = Date.today().addDays(-1);
        contractItem.Contract_End__c = Date.today().addDays(4);
        contractItem.Status__c = 'Open';
        contractItem.Negotiated_Price__c = 100;
        contractItem.Item__c = item.id;
        contractItem.Purchase_UOM__c = uomEach.Id;
        contractItem.Contract_Quantity__c = 10;
        insert contractItem;
        
        //Crate a new instance of the current class
        ContractService CC = new ContractService();     
        
        // Create a new pa line with different uom, overlapping dates and same item
        Contract_Line__c contractItemOverlap = new Contract_Line__c();
        contractItemOverlap.Contract__c = contract.Id;
        contractItemOverlap.Contract_Start__c = Date.today().addDays(-1);
        contractItemOverlap.Contract_End__c = Date.today().addDays(4);
        contractItemOverlap.Status__c = 'Open';
        contractItemOverlap.Negotiated_Price__c = 100;
        contractItemOverlap.Item__c = item.id;
        contractItemOverlap.Purchase_UOM__c = uomDozen.Id;
        contractItemOverlap.Contract_Quantity__c = 10;
        List<Contract_Line__c> contractItemsList = new List<Contract_Line__c>();
        contractItemsList.add(contractItemOverlap);
        
        Test.startTest();
        // insert should succeed
        Boolean isSuccess = true;
        try{
            insert contractItemsList;
        }
        catch (Exception ex){
            isSuccess = false;
        }
        system.assert(isSuccess );
        system.assert(contractItemOverlap.Id != null);
        Test.stopTest();
    }
    
    // No UOM on Purchased Item
    static testMethod void testPALine_NoUOM_NoMOQ() { //KNDY-10599
        //Company 
        Company__c company = new Company__c();
        company.name = 'TestDataCo';
        company.A_Days__c = 6;
        company.B_Days__c = 20;
        company.C_Days__c = 90;
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        company.Consol_Currency__c = TestFuel.currencyGBP.id;
        company.Stat_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        company.Subs_currency__c = TestFuel.currencyUSD.id;        
        insert company;

        //Query for Supplier recordtype
        //RecordType suppRecordType = [select Id from RecordType where DeveloperName = 'Supplier' and SObjectType = 'Business_Partner__c'];
        map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c');
        
        Supplier__c businessPartner = new Supplier__c();
        businessPartner.name = 'Business partner test';
        businessPartner.Company__c = company.id;
        businessPartner.Status__c = 'Active';
        businessPartner.Type__c = 'Remit-To';
        businessPartner.RecordTypeId = rtMap.get('Remit_To');
        insert businessPartner;
        
        Payment_Term__c paymentTermInfo = new Payment_Term__c();{
            paymentTermInfo.Name = '2/10 Net 30';
            paymentTermInfo.Description__c = '2% discount in 10 days, due 30 days';
            paymentTermInfo.Discount_Days__c = 10;
            paymentTermInfo.Discount_Percent__c = 2.0;
            paymentTermInfo.Due_Days__c = 30;
            insert paymentTermInfo;
        }
        // UOM
        UOM__c uomEach = new UOM__c();
        uomEach.name = 'EA';
        List<UOM__c> uoms = new List<UOM__c>{uomEach};
        insert uoms;
        
        //Item
        Item__c item = new Item__c();
        item.name='TestItems';
        item.Description__c='TestItem';
        item.company__c = company.id;
        item.Source__c = 'Purchased';
        insert item;
           
        //Contract
        Contract__c contract = new Contract__c();
        contract.Name = 'TestContract';
        contract.Contract_Start__c = Date.today().addDays(-1);
        contract.Contract_End__c = Date.today().addDays(4);
        contract.OwnerID = System.Userinfo.getUserId();
        contract.Status__c = 'Open';
        insert contract;
        
        //Contract Line that is active, without MOQ and UOM
        Contract_Line__c contractItem = new Contract_Line__c();
        contractItem.Contract__c = contract.Id;
        contractItem.Contract_Start__c = Date.today().addDays(-1);
        contractItem.Contract_End__c = Date.today().addDays(4);
        contractItem.Status__c = 'Open';
        contractItem.Negotiated_Price__c = 100;
        contractItem.Item__c = item.id;
        contractItem.Purchase_UOM__c = null;
        contractItem.Minimum_Order_Quantity__c = null;
        contractItem.Contract_Quantity__c = 10;
        Test.startTest();
        // insert should fail
        Boolean isSuccess = true;
        try{
            insert contractItem;
        }
        catch (Exception ex){
            isSuccess = false;
            system.assert(ex.getMessage().contains('Purchase UOM is required. Cannot default from item as there is no purchasing uom.'), 'Unexpected ex: ' +ex);
        }
        system.assert(!isSuccess );
        Test.stopTest();
    }
    
    // Item has UOM, which is defaulted on PALine
    static testMethod void testPALine_DefaultUOMFromItem() { //KNDY-10599
        //Company 
        Company__c company = new Company__c();
        company.name = 'TestDataCo';
        company.A_Days__c = 6;
        company.B_Days__c = 20;
        company.C_Days__c = 90;
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        company.Consol_Currency__c = TestFuel.currencyGBP.id;
        company.Stat_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        company.Subs_currency__c = TestFuel.currencyUSD.id;        
        insert company;

        //Query for Supplier recordtype
        //RecordType suppRecordType = [select Id from RecordType where DeveloperName = 'Supplier' and SObjectType = 'Business_Partner__c'];
        map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c');
        
        Supplier__c businessPartner = new Supplier__c();
        businessPartner.name = 'Business partner test';
        businessPartner.Company__c = company.id;
        businessPartner.Status__c = 'Active';
        businessPartner.Type__c = 'Remit-To';
        businessPartner.RecordTypeId = rtMap.get('Remit_To');
        insert businessPartner;
        
        Payment_Term__c paymentTermInfo = new Payment_Term__c();{
            paymentTermInfo.Name = '2/10 Net 30';
            paymentTermInfo.Description__c = '2% discount in 10 days, due 30 days';
            paymentTermInfo.Discount_Days__c = 10;
            paymentTermInfo.Discount_Percent__c = 2.0;
            paymentTermInfo.Due_Days__c = 30;
            insert paymentTermInfo;
        }
        // UOM
        UOM__c uomEach = new UOM__c();
        uomEach.name = 'EA';
        List<UOM__c> uoms = new List<UOM__c>{uomEach};
        insert uoms;
        
        //Item
        Item__c item = new Item__c();
        item.name='TestItems';
        item.Description__c='TestItem';
        item.company__c = company.id;
        item.Purchasing_UOM__c = uomEach.id;
        item.Source__c = 'Expense';
        item.Non_Inventory__c = true;
        insert item;
           
        //Contract
        Contract__c contract = new Contract__c();
        contract.Name = 'TestContract';
        contract.Contract_Start__c = Date.today().addDays(-1);
        contract.Contract_End__c = Date.today().addDays(4);
        contract.OwnerID = System.Userinfo.getUserId();
        contract.Status__c = 'Open';
        insert contract;
        
        //Contract Line that is active, without MOQ and UOM
        Contract_Line__c contractItem = new Contract_Line__c();
        contractItem.Contract__c = contract.Id;
        contractItem.Contract_Start__c = Date.today().addDays(-1);
        contractItem.Contract_End__c = Date.today().addDays(4);
        contractItem.Status__c = 'Open';
        contractItem.Negotiated_Price__c = 100;
        contractItem.Item__c = item.id;
        contractItem.Purchase_UOM__c = null;
        contractItem.Minimum_Order_Quantity__c = null;
        contractItem.Contract_Quantity__c = 10;
        Test.startTest();
        Boolean isSuccess = true;
        try{
            insert contractItem;
        }
        catch (Exception ex){
            isSuccess = false;
        }
        system.assert(isSuccess );
        Contract_Line__c paline = [Select Id, Purchase_UOM__c from Contract_Line__c
                                    where Id = :contractItem.Id];
        system.assert(paline.Purchase_UOM__c == uomEach.Id);
        Test.stopTest();
    }
    static testMethod void testApprovedCtLineValidation(){
    	
    	Contract__c contract = new Contract__c();
        contract.Name = 'TestContract';
        contract.Contract_Start__c = Date.today().addDays(-1);
        contract.Contract_End__c = Date.today().addDays(4);
        contract.OwnerID = System.Userinfo.getUserId();
        contract.Status__c = 'Open';
        contract.Approval_Status__c = 'Approved';
        insert contract;
        
        Contract_Line__c contractItem = new Contract_Line__c();
        contractItem.Contract__c = contract.Id;
        contractItem.Contract_Start__c = Date.today().addDays(-1);
        contractItem.Contract_End__c = Date.today().addDays(4);
        contractItem.Status__c = 'Open';
        contractItem.Approved__c = true;
        contractItem.Negotiated_Price__c = 100;
        contractItem.Item__c = fuel.itemList[10].id;
        contractItem.Purchase_UOM__c = fuel.uomObj.Id;
        contractItem.Contract_Quantity__c = 10;
        insert contractItem;
        
        try{
        	delete contractItem;
        }catch(Exception e){
        	system.assert(e.getMessage().contains('Approved Contract lines cannot be deleted.'), 'unexpected exception on delete:' + e);
        }
    }
    static testMethod void testSuccessAndFailureMail(){
    	   
    	Contract__c contract = new Contract__c(); 
        contract.Name = 'TestContract';
        contract.Contract_Start__c = Date.today().addDays(-1);
        contract.Contract_End__c = Date.today().addDays(4);
        contract.OwnerID = System.Userinfo.getUserId();
        contract.Status__c = 'Open';
        contract.Approval_Status__c = 'Approved';
        insert contract;
        
        Contract_Line__c contractItem = new Contract_Line__c();
        contractItem.Contract__c = contract.Id;
        contractItem.Contract_Start__c = Date.today().addDays(-1);
        contractItem.Contract_End__c = Date.today().addDays(4);
        contractItem.Status__c = 'Open';
        contractItem.Approved__c = true;
        contractItem.Negotiated_Price__c = 100;
        contractItem.Item__c = fuel.itemList[10].id;
        contractItem.Purchase_UOM__c = fuel.uomObj.Id; 
        contractItem.Contract_Quantity__c = 10;
        insert contractItem;
		
        test.StartTest(); 
		contractService cc = new contractservice(); 
		ContractService.sendApproveSuccessEmail(contract.Id); 
        try{
            insert contract;
        }catch(Exception e){
         	ContractService.sendApproveFailedEmail(contract.Id, e ); 	   
        }
    }
}