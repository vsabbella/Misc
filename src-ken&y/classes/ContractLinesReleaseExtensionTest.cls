@isTest
private class ContractLinesReleaseExtensionTest {
    private static SchemaUtil queryutil = SchemaUtil.getInstance();
    class mockData{
        public Configuration__c rf = new Configuration__c();{
            rf.name = 'Contract Release Field';
            rf.Value__c = 'Remaining_Quantity__c';
            insert rf;
        }

        public Source_Document_Approval__c sd = new Source_Document_Approval__c();{
            sd.Name = 'Purchase Order';
            sd.Allow_Approval__c = true;
            insert sd;
        }
    }

    @testSetup
    private static void setupfuel() {
        TestFuel dataInit = new TestFuel();
        // initialize necessary data to be queried by TestDataQuery
        system.assert(
                dataInit.company != null &&
                        dataInit.ContractAM != null &&
                        dataInit.uomList != null &&
                        dataInit.uomcList != null &&
                        dataInit.facility != null &&
                        dataInit.location != null &&
                        dataInit.ContractLine != null
        );
    }

    static TestFuelQuery fuel = new TestFuelQuery();

    private static Contract_Line__c fetchPurchaseAgreementLines( id paid )  {
        Contract_Line__c paLine =  database.query(
                queryutil.generateQueryFromFieldSet('Contract_Line__c',
                        new set<string>{'Line_Release', 'Tiers', 'Extended_Tiers'},
                        new set<string>{'Id','Invoice_Matching__c','Line__c','UOM__c','Contract__r.Company__c','Contract__r.Company__r.Default_Transaction_Currency__c','Contract_Quantity__c', 'Location__c', 'Quantity_Still_Due__c',

                                'Purchased_Quantity__c', 'PurchasedValue__c','Quantity_Received__c','Remaining_Quantity__c','Available_Quantity__c','Remaining_Value__c','Remaining_Value_Percent__c','Status__c',
                                'ValueReceived__c','Contract__r.Payment_Term__c', 'Contract__r.Payment_Term__r.id', 'Contract__r.FOB_Term__c', 'Contract__r.FOB_Term__r.id', 'Item__c', 'Item__r.Description__c', 'Contract__r.Supplier__c',
                                'Item__r.Buyer_Planner__c','Item__r.Purchasing_UOM__c', 'Contract__r.Transportation_Mode__c', 'Consigned__c', 'Item_Cross_Reference__c', 'Type__c', 'Contract__r.Contract_Number__c', 'Status__c', 'Contract__c', 'Contract__r.Supplier__r.Remit_To__c','Contract__r.Currency__c',
                                'Contract__r.Unit_Price_Tolerance_Over__c','Contract__r.Quantity_Tolerance_Over__c','Contract__r.Amount_Tolerance__c','Contract__r.Supplier__r.Default_Receiving_Tolerance__c'},
                        '  id =:paid  order by Line__c asc limit 1' )) ;
        return paLine ;
    }


    //  Being able to release a contract line resulting in creation of PO header and corresponding PO lines
    static testMethod void happyPathScenario() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        contract.Approval_Status__c = 'Approved';
        update contract;

        Contract_Line__c cl = fuel.ContractLine;
        cl.Approved__c = true;
        update cl;

        Test.startTest();

        Map<string,string> queryMapPAL = null;
        String palQuery = null;
        String palQueryCondition = null;

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);
        //JsonResult resultCLines = ContractLinesReleaseExtension.getContractLinesList(sstestData.company.id, sstestData.facility.Id);
        //system.assertEquals(true, resultCLines.success);
        // since test data is missing tier information
        id cltid = contractLine1.id;
        contract_line__c clt = fetchPurchaseAgreementLines( cltid);
        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 100;
        }
        clt = [select id, name, Remaining_Quantity__c from contract_line__c where id =:contractLine1.id ];
        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add( ctlineWrapper );

        }

        List<Purchase_Order__c> poList = [select id, Currency__r.ISO_Code__c from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(0, poList.size());

        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);

        //PTP-127 - Lines with QTY = 0 should not be available in the release UI
        queryMapPAL = clre.getContractLinesQuery();
        palQuery = queryMapPAL.get('Query');
        palQueryCondition = queryMapPAL.get('Condition');

        system.assertEquals(true, palQuery != null);
        system.assertEquals(true, palQueryCondition != null);

        poList = [select id, supplier__c, name, Delivery_Facility__c, status__c, Approval_Status__c, Currency__c, Purchase_Agreement__c, Currency__r.ISO_Code__c from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(1, poList.size());
        system.assertEquals('Approved',poList[0].Approval_Status__c); //PTP-145 Approval status on POs created by Release Process should not be flipped
        system.assertEquals('USD', poList[0].Currency__r.ISO_Code__c); //KNDY-11822
        poList[0].Order_Date__c = System.today()+5;
        update poList[0];
        poList = [select id, supplier__c, name, Order_Date__c, Delivery_Facility__c, status__c, Approval_Status__c, Purchase_Agreement__c, Currency__r.ISO_Code__c from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals('Pending Authorization', poList[0].Approval_Status__c);  //Checking the PO Approval Status when particular fields are changed.
        List<Purchase_Order_Line__c> poLineList = [select id, name, Consigned__c, Approved__c, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c = :poList[0].id];
        system.assertEquals(1, poLineList.size());
        //TODO: remove the commented assert
        //system.assertEquals(ContractLine1.Consigned__c, poLineList[0].Consigned__c);
        system.assertEquals(true, poLineList[0].Approved__c);
        ApexPages.StandardController setCon1 = new Apexpages.StandardController(contract);
        PurchaseAgreeementCloseCancelExt conClose = new PurchaseAgreeementCloseCancelExt(setCon1);
        conClose.cancel();
        Contract__c con1 = [select id, name, Status__c from Contract__c where id = :contract.id];
        system.assertEquals(con1.Status__c, 'Open');
        system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains('Purchase Agreement with a Purchase Order cannot be Cancelled!'));
        system.assertEquals(poList[0].Purchase_Agreement__c, contract.id);
        polist[0].purchase_Agreement__c = null; //PTP-79
        try{
            update polist[0];
        }
        catch(DmlException e){
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' , e.getDmlStatusCode(0) );
        }
    }

    //  this should result in creation of 2 POs and corresponding lines based on unique combination of facility, supplier, Transportation mode, FOB terms and pymt terms
    static testMethod void create2POsBasedOnCriteria() {//Criteria: unique combination of facility, supplier, transportation mode, FOB terms and pymt terms result in a PO header with corresponding lines

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        Test.startTest();
        id cltid = contractLine1.id;
        contract_line__c clt1 = fetchPurchaseAgreementLines( cltid);

        List<Contract_Line__c> clList = new List<Contract_Line__c>();
        clList.add(clt1);

        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt1;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 10;
        }

        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add( ctlineWrapper );

        }
        Contract__c Contract2 = new Contract__c();{
            Contract2.Name = 'TestContract1';
            Contract2.Contract_Start__c = Date.today().addDays(-1);
            Contract2.Contract_End__c = Date.today().addDays(4);
            Contract2.OwnerID = System.Userinfo.getUserId();
            Contract2.Status__c = 'Open';
            Contract2.Supplier__c = fuel.supplier.id;
            Contract2.Company__c = fuel.company.Id;
            Contract2.FOB_Term__c = fuel.fobTerm.id;
            Contract2.Payment_Term__c = fuel.terms.id;
            Contract2.Ship_to_Facility__c = fuel.facility.Id;
            Contract2.Transportation_Mode__c = 'RAIL';
            Contract2.Approval_Status__c = 'Approved';
            insert Contract2;
        }

        //Contract Item that is active
        Contract_Line__c contractLine2 = new Contract_Line__c();{
            contractLine2.Contract__c = Contract2.Id;
            contractLine2.Company__c = fuel.company.Id;
            contractLine2.Item__c = fuel.itemlist[0].id;
            contractLine2.Contract_Start__c = Date.today().addDays(-1);
            contractLine2.Contract_End__c = Date.today().addDays(3);
            contractLine2.Status__c = 'Open';
            contractLine2.Negotiated_Price__c = 10;
            contractLine2.Contract_Quantity__c = 100;
            contractLine2.Type__c = 'Fixed';
            insert contractLine2;
        }

        clList.add(contractLine2);
        cltid = contractLine2.id;
        contract_line__c clt2 = fetchPurchaseAgreementLines( cltid);

        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper2 = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper2.ctLine = clt2;
            ctlineWrapper2.needDate = Date.today();
            ctlineWrapper2.quantityToRelease = 10;
        }

        ctLineWrappers.add(ctlineWrapper2);

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);
        //JsonResult resultCLines = ContractLinesReleaseExtension.getContractLinesList(sstestData.company.id, sstestData.facility.Id);
        //system.assertEquals(true, resultCLines.success);

        List<Purchase_Order__c> poList = [select id from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(0, poList.size());

        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        poList = [select id, supplier__c, name, Delivery_Facility__c, status__c from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(2, poList.size());
        List<Id> poHeaderIds = new List<ID>();
        for (Purchase_Order__c po: poList)
            poHeaderIds.add(po.id);

        List<Purchase_Order_Line__c> poLineList = [select id, name, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c, Overage_Percentage__c, supplier__r.Default_Receiving_Tolerance__c from Purchase_Order_Line__c where purchase_order__c IN :poHeaderIds];
        system.assertEquals(2, poLineList.size());
        for (Purchase_Order_Line__c poline : poLineList){
            system.assertEquals(poline.supplier__r.Default_Receiving_Tolerance__c,poline.Overage_Percentage__c);
        }
        test.StopTest();
    }
    static testMethod void createPOofDecimalOrderQuantity() {//Release PA with Decimal Quantity whcih creates POL with decimal order quantity

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        Test.startTest();
        id cltid = contractLine1.id;
        contract_line__c clt1 = fetchPurchaseAgreementLines( cltid);

        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt1;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 5.5;
        }

        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add( ctlineWrapper );
        }

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        Purchase_Order__c po = [select id, supplier__c, name, Delivery_Facility__c, status__c from Purchase_Order__c where company__c = :fuel.company.id];

        Purchase_Order_Line__c poLine = [select id, name, Delivery_Facility__c, Contract_Line__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c, Overage_Percentage__c, supplier__r.Default_Receiving_Tolerance__c from Purchase_Order_Line__c where purchase_order__c = :po.Id];
        system.assertEquals(ctlineWrapper.quantityToRelease, poLine.Order_Quantity__c);

        test.StopTest();
    }

    //KNDY-2300 Tier based pricing test
    static testMethod void createPOUsingTieredPricing() {
        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        contractLine1.status__c = 'Cancelled';
        update contractLine1;

        List<Contract_Line__c> clList = new List<Contract_Line__c>();
        clList.add(contractLine1);

        Test.startTest();

        Contract_Line__c contractLine2 = new Contract_Line__c();{
            contractLine2.Contract__c = contract.Id;
            contractLine2.Company__c = fuel.company.Id;
            contractLine2.Item__c = fuel.itemList[0].id;
            contractLine2.Contract_Start__c = Date.today().addDays(-1);
            contractLine2.Contract_End__c = Date.today().addDays(3);
            contractLine2.Status__c = 'Open';
            contractLine2.Negotiated_Price__c = 10;
            contractLine2.Contract_Quantity__c = 100;
            contractLine2.Type__c = 'Tiered';
            contractLine2.Tier_1_Max__c = 10;
            contractLine2.Tier_1_Price__c = 9.00;
            contractLine2.Tier_2_Max__c = 20;
            contractLine2.Tier_2_Price__c = 8.00;
            contractLine2.Tier_3_Max__c = 30;
            contractLine2.Tier_3_Price__c = 7;
            contractLine2.Tier_4_Max__c = 40;
            contractLine2.Tier_4_Price__c = 6;
            contractLine2.Tier_5_Max__c = 50;
            contractLine2.Tier_5_Price__c = 5;
            contractLine2.Tier_6_Max__c = 60;
            contractLine2.Tier_6_Price__c = 4;
            contractLine2.Tier_7_Max__c = 70;
            contractLine2.Tier_7_Price__c = 3;
            contractLine2.Tier_8_Max__c = 80;
            contractLine2.Tier_8_Price__c = 2;
            contractLine2.Tier_9_Max__c = 90;
            contractLine2.Tier_9_Price__c = 1;
            contractLine2.Tier_10_Max__c = 100;
            contractLine2.Tier_10_Price__c = 0.50;
            insert contractLine2;
        }
        clList.add(contractLine2);

        id cltid = contractLine2.id;
        contract_line__c clt2 = fetchPurchaseAgreementLines( cltid);

        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper2 = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper2.ctLine = clt2;
            ctlineWrapper2.needDate = Date.today();
            ctlineWrapper2.quantityToRelease = 65;
        }

        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add(ctlineWrapper2);
        }

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine2);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);

        List<Purchase_Order__c> poList = [select id from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(0, poList.size());

        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        poList = [select id, supplier__c, name, Delivery_Facility__c, status__c from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(1, poList.size());
        List<Id> poHeaderIds = new List<ID>();
        for (Purchase_Order__c po: poList)
            poHeaderIds.add(po.id);

        List<Purchase_Order_Line__c> poLineList = [select id, name, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c IN :poHeaderIds];
        system.assertEquals(1, poLineList.size());
        system.assert(poLineList[0].Unit_Price__c == 3, 'Unit price mismatch: ' + poLineList[0].Unit_Price__c);

    }

    //  Release a contact line and do basic netting by capturing the purchased quantity
    static testMethod void releaseAContractLineAndNetAgainstIt() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        Test.startTest();

        id cltid = contractLine1.id;
        contract_line__c clt2 = fetchPurchaseAgreementLines( cltid);

        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper2 = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper2.ctLine = clt2;
            ctlineWrapper2.needDate = Date.today();
            ctlineWrapper2.quantityToRelease = 65;
        }

        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add(ctlineWrapper2);
        }

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);

        List<Purchase_Order__c> poList = [select id from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(0, poList.size());

        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        poList = [select id, supplier__c, name, Delivery_Facility__c, Purchase_Order_Value__c, Quantity_Released__c, status__c from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(1, poList.size());
        clt2 = [select id, name, Purchased_Quantity__c, PurchasedValue__c from Contract_Line__c where id =: cltid];
        system.assert(poList[0].Quantity_Released__c == clt2.Purchased_Quantity__c, 'Purchased quantity mismatch against PO header.');
    }

    // to provide code coverage
    static testMethod void dummyTests() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        Test.startTest();

        id cltid = contractLine1.id;
        contract_line__c clt3 = fetchPurchaseAgreementLines( cltid);

        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt3;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 10;
        }
        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add( ctlineWrapper );

        }
        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);
        clre.getContractLinesConfigJson();
        clre.getContractLinesFieldList();
        clre.getReleaseLinesConfigJson();
        clre.getReleaseLinesFieldList();
        // clre.addRowForRelease(ctlineWrapper);

        //JsonResult resultCLines = ContractLinesReleaseExtension.getContractLines(fuel.company.id, fuel.facility.Id);
        //system.assertEquals(true, resultCLines.success);

        List<Purchase_Order__c> poList = [select id from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(0, poList.size());

        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        poList = [select id, supplier__c, name, Delivery_Facility__c, status__c from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(1, poList.size());
        List<Purchase_Order_Line__c> poLineList = [select id, name, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c = :poList[0].id];
        system.assertEquals(1, poLineList.size());


    }

    //KNDY-3259 Creating 2 POs based on blanket number + need date combination
    static testMethod void create2POsBasedOnBlaketNumberNeedDateCombination() {//Criteria: blanket number + need date

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        Test.startTest();
        id cltid = contractLine1.id;
        contract_line__c clt1 = fetchPurchaseAgreementLines( cltid);
        update clt1;

        List<Contract_Line__c> clList = new List<Contract_Line__c>();
        clList.add(contractLine1);

        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt1;
            ctlineWrapper.needDate = Date.today().addDays(1); // making sure the need date falls on next day
            ctlineWrapper.quantityToRelease = 10;
        }

        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add( ctlineWrapper );

        }

        //Contract Item that is active
        Contract_Line__c contractLine2 = new Contract_Line__c();{
            contractLine2.Contract__c = contract.Id;
            contractLine2.Company__c = fuel.company.Id;
            contractLine2.Item__c = fuel.itemList[0].id;
            contractLine2.Contract_Start__c = Date.today().addDays(-1);
            contractLine2.Contract_End__c = Date.today().addDays(3);
            contractLine2.Status__c = 'Open';
            contractLine2.Negotiated_Price__c = 10;
            contractLine2.Contract_Quantity__c = 100;
            contractLine2.Type__c = 'Fixed';
            insert contractLine2;
        }
        clList.add(contractLine2);
        cltid = contractLine2.id;
        contract_line__c clt2 = fetchPurchaseAgreementLines( cltid);

        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper2 = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper2.ctLine = clt2;
            ctlineWrapper2.needDate = Date.today(); // need date is today compared to the previous one which is marked as next day
            ctlineWrapper2.quantityToRelease = 10;
        }

        ctLineWrappers.add(ctlineWrapper2);

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);
        //JsonResult resultCLines = ContractLinesReleaseExtension.getContractLinesList(sstestData.company.id, sstestData.facility.Id);
        //system.assertEquals(true, resultCLines.success);

        List<Purchase_Order__c> poList = [select id from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(0, poList.size());


        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        poList = [select id, supplier__c, Remit_To_Supplier__c,name, Delivery_Facility__c, status__c, Purchase_Agreement__c from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(2, poList.size());
        system.assert(poList[0].Purchase_Agreement__c != null, 'PA lookup not populated');
        system.assert(poList[0].Remit_To_Supplier__c != poList[0].supplier__c, 'Remit-To lookup not populated correctly');
        List<Id> poHeaderIds = new List<ID>();
        for (Purchase_Order__c po: poList)
            poHeaderIds.add(po.id);

        List<Purchase_Order_Line__c> poLineList = [select id, name, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c IN :poHeaderIds];
        system.assertEquals(2, poLineList.size());

    }

    static testMethod void isQuantityToReleaseWithinMOQLimits() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        fuel.itemList[0].Approved_Supplier_Required__c = true;
        update fuel.itemList[0];

        Item_Cross_Reference__c icr = new Item_Cross_Reference__c();
        icr.Name = 'ICR';
        icr.Item__c = fuel.itemList[0].Id;
        icr.Ship_to_Facility__c = fuel.facility.Id;
        icr.Active__c = true;
        icr.Approval_Status__c = 'Approved';
        icr.Minimum_Order_Quantity__c = 10;
        icr.Supplier__c = fuel.supplier.id;
        icr.UOM__c = fuel.uomList[2].Id;
        icr.Cross_Reference_Type__c = 'Supplier';
        insert icr;


        Test.startTest();

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);
        Double quantity = 10;

        ID itemID = fuel.itemList[0].Id;
        ID supID = fuel.supplier.id;
        ID facID = fuel.facility.Id;
        Date myDate = Date.today();
        String dateValue = myDate.format();

        Contract_Line__c cLine = contractLine1;

        JsonResult result = ContractLinesReleaseExtension.isWithinMOQ(cLine, supID, itemID, facID, dateValue, 121);
        system.assert(result.success == true, 'UOM conversion failed or quantity is more than MOQ');
    }

    static testMethod void DefaultICRValues() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        Item_Cross_Reference__c icr = new Item_Cross_Reference__c();
        icr.Name = 'ICR';
        icr.Item__c = fuel.itemList[0].Id;
        icr.Ship_to_Facility__c = fuel.facility.Id;
        icr.Active__c = true;
        icr.Approval_Status__c = 'Approved';
        icr.Minimum_Order_Quantity__c = 10;
        icr.Supplier__c = fuel.supplier.id;
        icr.UOM__c = fuel.uomList[2].Id;
        icr.Cross_Reference_Type__c = 'Supplier';
        icr.Consigned__c = true;
        insert icr;

        contractLine1.Item_Cross_Reference__c = icr.id;
        update contractLine1;

        Test.startTest();
        id cltid = contractLine1.id;
        contract_line__c clt1 = fetchPurchaseAgreementLines( cltid);


        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt1;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 10;
        }

        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add(ctlineWrapper);
        }

        ApexPages.StandardController setCon = new Apexpages.StandardController(clt1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        list<Purchase_Order__c> poList = [select id, supplier__c, name, Delivery_Facility__c, status__c from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(1, poList.size());
        List<Id> poHeaderIds = new List<ID>();
        for (Purchase_Order__c po: poList)
            poHeaderIds.add(po.id);

        List<Purchase_Order_Line__c> poLineList = [select id, name, Item_Cross_Reference__c, Consigned__c, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c IN :poHeaderIds];
        system.assertEquals(1, poLineList.size());
        system.assert(poLineList[0].Consigned__c);
        system.assertEquals(poLineList[0].Item_Cross_Reference__c, clt1.Item_Cross_Reference__c);

    }

    //KNDY-4376
    //If the release qty is > biggest tier, it should return the price from the biggest tier it finds
    static testMethod void createPOUsingLargerThanTierQty() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        contractLine1.status__c = 'Cancelled';
        update contractLine1;

        List<Contract_Line__c> clList = new List<Contract_Line__c>();
        clList.add(contractLine1);

        Test.startTest();

        Contract_Line__c contractLine2 = new Contract_Line__c();{
            contractLine2.Contract__c = contract.Id;
            contractLine2.Company__c = fuel.company.Id;
            contractLine2.Item__c = fuel.itemList[0].id;
            contractLine2.Contract_Start__c = Date.today().addDays(-1);
            contractLine2.Contract_End__c = Date.today().addDays(3);
            contractLine2.Status__c = 'Open';
            contractLine2.Negotiated_Price__c = 10;
            contractLine2.Contract_Quantity__c = 100;
            contractLine2.Type__c = 'Tiered';
            contractLine2.Tier_1_Max__c = 10;
            contractLine2.Tier_1_Price__c = 9.00;
            contractLine2.Tier_2_Max__c = 20;
            contractLine2.Tier_2_Price__c = 8.00;
            contractLine2.Tier_3_Max__c = 30;
            contractLine2.Tier_3_Price__c = 7;
            contractLine2.Tier_4_Max__c = 40;
            contractLine2.Tier_4_Price__c = 6;
            contractLine2.Tier_5_Max__c = 0;
            contractLine2.Tier_5_Price__c = 5;
            contractLine2.Tier_6_Max__c = 0;
            contractLine2.Tier_6_Price__c = 4;
            contractLine2.Tier_7_Max__c = 0;
            contractLine2.Tier_7_Price__c = 3;
            contractLine2.Tier_8_Max__c = 0;
            contractLine2.Tier_8_Price__c = 2;
            contractLine2.Tier_9_Max__c = 0;
            contractLine2.Tier_9_Price__c = 1;
            contractLine2.Tier_10_Max__c = 0;
            contractLine2.Tier_10_Price__c = 0.50;
            insert contractLine2;
        }
        clList.add(contractLine2);

        id cltid = contractLine2.id;
        contract_line__c clt2 = fetchPurchaseAgreementLines( cltid);

        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper2 = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper2.ctLine = clt2;
            ctlineWrapper2.needDate = Date.today();
            ctlineWrapper2.quantityToRelease = 100;
        }

        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add(ctlineWrapper2);
        }

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine2);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);

        List<Purchase_Order__c> poList = [select id from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(0, poList.size());

        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        poList = [select id, supplier__c, name, Delivery_Facility__c, status__c from Purchase_Order__c where company__c = :fuel.company.id];
        system.assertEquals(1, poList.size());
        List<Id> poHeaderIds = new List<ID>();
        for (Purchase_Order__c po: poList)
            poHeaderIds.add(po.id);

        List<Purchase_Order_Line__c> poLineList = [select id, name, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c IN :poHeaderIds];
        system.assertEquals(1, poLineList.size());
        system.assert(poLineList[0].Unit_Price__c == 6, 'Unit price mismatch: ' + poLineList[0].Unit_Price__c);

    }


    //KNDy-4614 if quantity to release matches the MOQ exactly, release should still be allowed
    static testMethod void isQuantityToReleaseEqualToMOQLimits() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        fuel.itemList[0].Approved_Supplier_Required__c = true;
        update fuel.itemList[0];

        Item_Cross_Reference__c icr = new Item_Cross_Reference__c();
        icr.Name = 'ICR';
        icr.Item__c = fuel.itemList[0].Id;
        icr.Ship_to_Facility__c = fuel.facility.Id;
        icr.Active__c = true;
        icr.Approval_Status__c = 'Approved';
        icr.Minimum_Order_Quantity__c = 10;
        icr.Supplier__c = fuel.supplier.id;
        icr.UOM__c = fuel.uomList[2].Id;
        icr.Cross_Reference_Type__c = 'Supplier';
        insert icr;


        Test.startTest();

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);
        Double qty = 120.00;
        ID itemID = fuel.itemList[0].Id;
        ID supID = fuel.supplier.id;
        ID facID = fuel.facility.Id;
        Date myDate = Date.today();
        String dateValue = myDate.format();
        Contract_Line__c cLine = contractLine1;

        JsonResult result = ContractLinesReleaseExtension.isWithinMOQ(cLine,supID, itemID, facID,dateValue,qty);
        system.assert(result.success == true, 'UOM conversion failed or quantity is more than MOQ');

        //PTP-90 MOQ validation when the MOQ is not set
        icr.Minimum_Order_Quantity__c = null;
        update icr;
        ApexPages.StandardController setCon1 = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre1 = new ContractLinesReleaseExtension(setCon);
        Double qty1 = 120.00;
        ID itemID1 = fuel.itemList[0].Id;
        ID supID1 = fuel.supplier.id;
        ID facID1 = fuel.facility.Id;
        Contract_Line__c cLine1 = contractLine1;

        JsonResult result1 = ContractLinesReleaseExtension.isWithinMOQ(cLine1, supID1, itemID1, facID1,dateValue,qty1);
        system.assertEquals(result1.success, true);

    }

    //KNDY-4696 if item is not marked as asl reqd then dont do the MOQ validation
    static testMethod void itemNotASLReqdNoMOQValidation() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        fuel.itemList[0].Approved_Supplier_Required__c = false;
        update fuel.itemList[0];

        Test.startTest();

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);
        Double qty = 120.00;
        ID itemID = fuel.itemList[0].Id;
        ID supID = fuel.supplier.id;
        ID facID = fuel.facility.Id;
        Contract_Line__c cLine = contractLine1;
        Date myDate = Date.today();
        String dateValue = myDate.format();

        JsonResult result = ContractLinesReleaseExtension.isWithinMOQ(cLine, supID, itemID, facID,dateValue,qty);
        system.assert(result.success == true, 'MOQ validation occurs and fails.'); //PTP-180 ICR is queried irrespective of ASL, but no error is thrown
    }

    static testMethod void checkTierQuantityonRelease() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        fuel.itemList[0].Approved_Supplier_Required__c = false;
        update fuel.itemList[0];

        Contract_Line__c contractLine2 = new Contract_Line__c();{
            contractLine2.Contract__c = contract.Id;
            contractLine2.Company__c = fuel.company.Id;
            contractLine2.Item__c = fuel.itemList[0].id;
            contractLine2.Contract_Start__c = Date.today().addDays(-1);
            contractLine2.Contract_End__c = Date.today().addDays(3);
            contractLine2.Status__c = 'Open';
            contractLine2.Negotiated_Price__c = 10;
            contractLine2.Contract_Quantity__c = 100;
            contractLine2.Type__c = 'Tiered';
            contractLine2.Tier_1_Max__c = 10;
            contractLine2.Tier_1_Price__c = 9.00;
            contractLine2.Tier_2_Max__c = 20;
            contractLine2.Tier_2_Price__c = 8.00;
            contractLine2.Tier_3_Max__c = 30;
            contractLine2.Tier_3_Price__c = 7;
            contractLine2.Tier_4_Max__c = 40;
            contractLine2.Tier_4_Price__c = 6;
            contractLine2.Tier_5_Max__c = 50;
            contractLine2.Tier_5_Price__c = 5;
            contractLine2.Tier_6_Max__c = 60;
            contractLine2.Tier_6_Price__c = 4;
            contractLine2.Tier_7_Max__c = 70;
            contractLine2.Tier_7_Price__c = 3;
            contractLine2.Tier_8_Max__c = 80;
            contractLine2.Tier_8_Price__c = 2;
            contractLine2.Tier_9_Max__c = 90;
            contractLine2.Tier_9_Price__c = 1;
            contractLine2.Tier_10_Max__c = 95;
            contractLine2.Tier_10_Price__c = 0.50;
            insert contractLine2;
        }

        Test.startTest();

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);

        ID itemID = fuel.itemList[0].Id;
        ID supID = fuel.supplier.id;
        ID facID = fuel.facility.Id;
        Date myDate = Date.today();
        String dateValue = myDate.format();

        JsonResult result = ContractLinesReleaseExtension.isWithinMOQ(contractLine2, supID, itemID, facID, dateValue, 99);
        system.assertEquals(result.success, false);
        JsonResult result1 = ContractLinesReleaseExtension.isWithinMOQ(contractLine2, supID, itemID, facID, dateValue, 5);
        system.assertEquals(result1.success, true);
        JsonResult result2 = ContractLinesReleaseExtension.isWithinMOQ(contractLine2, supID, itemID, facID, dateValue, 15);
        system.assertEquals(result2.success, true);
        JsonResult result3 = ContractLinesReleaseExtension.isWithinMOQ(contractLine2, supID, itemID, facID, dateValue, 25);
        system.assertEquals(result3.success, true);
        JsonResult result4 = ContractLinesReleaseExtension.isWithinMOQ(contractLine2, supID, itemID, facID, dateValue, 35);
        system.assertEquals(result4.success, true);
        JsonResult result5 = ContractLinesReleaseExtension.isWithinMOQ(contractLine2, supID, itemID, facID, dateValue, 45);
        system.assertEquals(result5.success, true);
        JsonResult result6 = ContractLinesReleaseExtension.isWithinMOQ(contractLine2, supID, itemID, facID, dateValue, 55);
        system.assertEquals(result6.success, true);
        JsonResult result7 = ContractLinesReleaseExtension.isWithinMOQ(contractLine2, supID, itemID, facID, dateValue, 65);
        system.assertEquals(result7.success, true);
        JsonResult result8 = ContractLinesReleaseExtension.isWithinMOQ(contractLine2, supID, itemID, facID, dateValue, 75);
        system.assertEquals(result8.success, true);
        JsonResult result9 = ContractLinesReleaseExtension.isWithinMOQ(contractLine2, supID, itemID, facID, dateValue, 85);
        system.assertEquals(result9.success, true);
        JsonResult result10 = ContractLinesReleaseExtension.isWithinMOQ(contractLine2, supID, itemID, facID, dateValue, 93);
        system.assertEquals(result10.success, true);

        Test.stopTest();
    }
    //PTP-245 Check if price is updated on Purchase Order when the price is updated on the Purchase Agreement
    static testMethod void test_UpdatePOpricefromPA() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        contract.Update_Open_PO_Lines__c = true;
        update contract;

        Test.startTest();
        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);

        id cltid = contractLine1.id;
        contract_line__c clt = fetchPurchaseAgreementLines( cltid);
        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 100;
        }
        clt = [select id, name, Remaining_Quantity__c from contract_line__c where id =:contractLine1.id ];
        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add( ctlineWrapper );

        }

        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        List<Purchase_Order__c> poList = [select id, supplier__c, name, Delivery_Facility__c, status__c, Approval_Status__c, Purchase_Agreement__c from Purchase_Order__c where company__c = :fuel.company.id];
        List<Purchase_Order_Line__c> poLineList = [select id, name, Consigned__c, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c = :poList[0].id];
        system.assertEquals(poLineList[0].Unit_Price__c, contractLine1.Negotiated_Price__c);

        contractLine1.Negotiated_Price__c = 20;
        update contractLine1;
        purchase_order_line__c poLine = [select id, name, unit_price__c from purchase_order_Line__c where id=:poLineList[0].id];
        system.assertEquals(poLine.Unit_Price__c, contractLine1.Negotiated_Price__c);
    }

    //PTP-261 Update the PA quantity after Release
    static testMethod void test_UpdatePAQtyAfterRelease() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        contract.Update_Open_PO_Lines__c = true;
        update contract;

        Test.startTest();
        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);

        id cltid = contractLine1.id;
        contract_line__c clt = fetchPurchaseAgreementLines( cltid);
        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 40;
        }
        clt = [select id, name, Remaining_Quantity__c from contract_line__c where id =:contractLine1.id ];
        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add( ctlineWrapper );

        }

        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);

        ContractLine1.Contract_Quantity__c = 30;
        try{
            update ContractLine1;
        }
        catch(DmlException e){
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' , e.getDmlStatusCode(0) );
        }

    }

    //PTP-120 RTV to succeed when PO is received in full
    //Test method written here to use the existing release process
    static testMethod void test_RTVWhenPOFullyReceived() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        contract.Update_Open_PO_Lines__c = true;
        update contract;

        ApexPages.StandardController setCon1 = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon1);

        id cltid = contractLine1.id;
        contract_line__c clt = fetchPurchaseAgreementLines( cltid);
        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 100; //Release in full
        }
        clt = [select id, name, Remaining_Quantity__c from contract_line__c where id =:contractLine1.id ];
        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add( ctlineWrapper );

        }
        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);    //Release is successful
        Test.startTest();
        Purchase_Order__c po = [select id, name, Company__c, Remit_to_Supplier__c, Currency__c from Purchase_Order__c where Purchase_Agreement__c = :Contract.id];
        Purchase_Order_Line__c poLine = [select id, name, Company__c, Purchase_Order__c, Item__c, Order_Quantity__c, Unit_Price__c, Need_Date__c, Supplier__c, Delivery_Facility__c, Delivery_Location__c, Quantity_Received__c, Purchase_Order__r.Currency__c from Purchase_Order_Line__c where Purchase_Order__c = :po.id];

        List< Purchase_Order__c > poTestList = new List< Purchase_Order__c >();
        poTestList.add(po);

        Apexpages.StandardSetController setCon = new Apexpages.StandardSetController(poTestList);
        setcon.setSelected(poTestList);
        PurchaseOrderReturnToVendorExt rtv = new PurchaseOrderReturnToVendorExt(setCon);

        rtv.retrievePOLines();

        system.assert(ApexPages.getMessages().size() ==1);

        setCon = new Apexpages.StandardSetController(poTestList);
        setcon.setSelected(poTestList);
        rtv = new PurchaseOrderReturnToVendorExt(setCon);
        system.assertEquals(poLine.Quantity_Received__c, 0);
        poLine.Quantity_Received__c = 100; //Receive fully
        update poLine;
        system.assertEquals(poLine.Quantity_Received__c, 100);
        rtv = new PurchaseOrderReturnToVendorExt(setCon);
        rtv.retrievePOLines();
        rtv.POLinesForDisplay[0].newPolRecord.Quantity_Returned_To_Supplier__c = 10;
        rtv.POLinesForDisplay[0].newPolRecord.Need_Date__c = system.today();
        rtv.save();
        system.debug('rtv.POLinesForDisplay ' + rtv.POLinesForDisplay);
        //system.assert( rtv.newPOLines.size() == 1 ); // TODO: uncomment after analysis PO should be created successfully when RTV done for a fully received PO
    }

    static testMethod void updatePOLinePriceAfterReleaseFromPALine() { //PTP-296

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        Test.startTest();
        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);

        id cltid = contractLine1.id;
        contract_line__c clt = fetchPurchaseAgreementLines( cltid);
        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 100;
        }
        clt = [select id, name, Remaining_Quantity__c from contract_line__c where id =:contractLine1.id ];
        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add( ctlineWrapper );

        }


        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        List<Purchase_Order__c> poList = [select id, supplier__c, name, Delivery_Facility__c, status__c, Approval_Status__c, Purchase_Agreement__c from Purchase_Order__c where company__c = :fuel.company.id];
        List<Purchase_Order_Line__c> poLineList = [select id, name, Consigned__c, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c = :poList[0].id];
        system.assertEquals(poLineList[0].Unit_Price__c, contractLine1.Negotiated_Price__c);

        poLineList[0].Unit_Price__c = 20;
        update poLineList;
        purchase_order_line__c poLine = [select id, name, unit_price__c from purchase_order_Line__c where id=:poLineList[0].id];
        system.assertNotEquals(poLine.Unit_Price__c, contractLine1.Negotiated_Price__c);
        system.assertEquals(poLine.Unit_Price__c, 20);
    }

    //PTP-299
    static testMethod void test_UpdatePOpricefromTieredPALine() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        contractLine1.status__c = 'Cancelled';
        update contractLine1;

        contract.Update_Open_PO_Lines__c = true;
        update contract;

        List<Contract_Line__c> clList = new List<Contract_Line__c>();
        clList.add(contractLine1);

        Test.startTest();

        Contract_Line__c contractLine2 = new Contract_Line__c();{
            contractLine2.Contract__c = contract.Id;
            contractLine2.Company__c = fuel.company.Id;
            contractLine2.Item__c = fuel.itemList[0].id;
            contractLine2.Contract_Start__c = Date.today().addDays(-1);
            contractLine2.Contract_End__c = Date.today().addDays(3);
            contractLine2.Status__c = 'Open';
            contractLine2.Negotiated_Price__c = 10;
            contractLine2.Contract_Quantity__c = 100;
            contractLine2.Type__c = 'Tiered';
            contractLine2.Tier_1_Max__c = 10;
            contractLine2.Tier_1_Price__c = 9.00;
            contractLine2.Tier_2_Max__c = 20;
            contractLine2.Tier_2_Price__c = 8.00;
            contractLine2.Tier_3_Max__c = 30;
            contractLine2.Tier_3_Price__c = 7;
            contractLine2.Tier_4_Max__c = 40;
            contractLine2.Tier_4_Price__c = 6;
            contractLine2.Tier_5_Max__c = 50;
            contractLine2.Tier_5_Price__c = 5;
            contractLine2.Tier_6_Max__c = 60;
            contractLine2.Tier_6_Price__c = 4;
            contractLine2.Tier_7_Max__c = 70;
            contractLine2.Tier_7_Price__c = 3;
            contractLine2.Tier_8_Max__c = 80;
            contractLine2.Tier_8_Price__c = 2;
            contractLine2.Tier_9_Max__c = 90;
            contractLine2.Tier_9_Price__c = 1;
            contractLine2.Tier_10_Max__c = 100;
            contractLine2.Tier_10_Price__c = 0.50;
            insert contractLine2;
        }
        clList.add(contractLine2);

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine2);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);

        id cltid = contractLine2.id;
        contract_line__c clt = fetchPurchaseAgreementLines( cltid);
        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 10;
        }
        clt = [select id, name, Remaining_Quantity__c from contract_line__c where id =:contractLine2.id ];
        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add( ctlineWrapper );

        }

        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;

        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        List<Purchase_Order__c> poList = [select id, supplier__c, name, Delivery_Facility__c, status__c, Approval_Status__c, Purchase_Agreement__c from Purchase_Order__c where company__c = :fuel.company.id];
        List<Purchase_Order_Line__c> poLineList = [select id, name, Consigned__c, Delivery_Facility__c, status__c, Item__c, Order_Quantity__c, Purchase_UOM__c, Supplier__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c = :poList[0].id];
        system.assertEquals(poLineList[0].Unit_Price__c, contractLine2.Tier_1_Price__c);

        contractLine2.Tier_1_Price__c = 1.56;
        update contractLine2;
        purchase_order_line__c poLine = [select id, name, unit_price__c from purchase_order_Line__c where id=:poLineList[0].id];
        system.assertEquals(poLine.Unit_Price__c, contractLine2.Tier_1_Price__c);

    }

    //PTP-410 Check for ordering multiples during release
    static testMethod void test_ValidateOrderingMultiplesonItem() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        facility_Item__c fItem = new Facility_Item__c();{
            fItem.Company__c = fuel.company.id;
            fItem.Facility__c = fuel.facility.Id;
            fItem.Item__c = fuel.itemList[0].id;
            fItem.Ordering_Multiple__c = 10;
            insert fITem;
        }
        Test.startTest();

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);

        ID itemID = fuel.itemList[0].Id;
        ID supID = fuel.supplier.id;
        ID facID = fuel.facility.Id;
        Contract_Line__c cLine = contractLine1;
        Date myDate = Date.today();
        String dateValue = myDate.format();

        JsonResult result = ContractLinesReleaseExtension.isWithinMOQ(cLine, supID, itemID, facID, dateValue, 12);
        system.assertEquals(false,result.success);
        result = ContractLinesReleaseExtension.isWithinMOQ(cLine, supID, itemID, facID, dateValue,  13);
        system.assertEquals(false,result.success);
        result = ContractLinesReleaseExtension.isWithinMOQ(cLine, supID, itemID, facID, dateValue,  122);
        system.assertEquals(false,result.success);
        result = ContractLinesReleaseExtension.isWithinMOQ(cLine, supID, itemID, facID, dateValue,  10);
        system.assertEquals(true,result.success);

    }

    //PTP-399 Add new qty bucket fields and verify them after release, updates to happen real time when PO Changes
    static testMethod void test_QtyBucketsonAgreements() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        fuel.facility.Default_Purchasing_Delivery_Location__c = location.id;
        update fuel.facility;


        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);
        id cltid = contractLine1.id;
        contract_line__c clt = fetchPurchaseAgreementLines( cltid);
        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 50;
        }
        clt = [select id, name, Remaining_Quantity__c from contract_line__c where id =:contractLine1.id ];
        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{
            ctLineWrappers.add( ctlineWrapper );

        }
        Test.startTest();
        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(fuel.company.id, fuel.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);

        //Use case 1 - Agreement Release: Contract Qty = 100, PO Created for 50, so expected contract bucket field values should be
        //Purchased Qty = 50, Qty Received = 0, Qty Still Due = 50, Remaining Qty = 50, Available Qty = 50
        Contract_Line__c cLine = [select id, name, Quantity_Received__c, Quantity_Still_Due__c, Quantity_Returned__c, Purchased_Quantity__c, Remaining_Quantity__c, Available_Quantity__c,
                Contract__r.PurchasedValue__c, Contract__r.Remaining_Value__c from Contract_Line__c where id = :contractLine1.id];
        Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
        poLine = [select id, name, Quantity_Received__c from Purchase_Order_Line__c where Contract_Line__c = :contractLine1.id];
        system.assertEquals(cline.Purchased_Quantity__c, 50);
        system.assertEquals(cLine.Quantity_Received__c, 0);
        system.assertEquals(cLine.Quantity_Still_Due__c, 50);
        system.assertEquals(cLine.Quantity_Returned__c, 0);
        system.assertEquals(cLine.Remaining_Quantity__c, 50);
        system.assertEquals(cLine.Available_Quantity__c, 50);
        system.assertEquals(cLine.Contract__r.PurchasedValue__c, 500);
        system.assertEquals(cLine.Contract__r.Remaining_Value__c, 500);

        //Use case 2 PO partial Receipt: Receive 20 from the PO Created, so expected contract bucket field values should be
        //Purchased Qty = 50, Qty Received = 20, Qty Still Due = 30, Remaining Qty = 50, Available Qty = 50
        poLine.Quantity_Received__c = 20;
        update poLine;
        cLine = [select id, name, Quantity_Received__c, Quantity_Still_Due__c, Quantity_Returned__c, Purchased_Quantity__c, Remaining_Quantity__c, Available_Quantity__c from Contract_Line__c where id = :contractLine1.id];
        system.assertEquals(cline.Purchased_Quantity__c, 50);
        system.assertEquals(cLine.Quantity_Received__c, 20);
        system.assertEquals(cLine.Quantity_Still_Due__c, 30);
        system.assertEquals(cLine.Quantity_Returned__c, 0);
        system.assertEquals(cLine.Remaining_Quantity__c, 50);
        system.assertEquals(cLine.Available_Quantity__c, 50);

        //Use case 3 PO full Receipt: Receive remaining 30 from the PO Created, so expected contract bucket field values should be
        //Purchased Qty = 50, Qty Received = 20, Qty Still Due = 30, Remaining Qty = 50, Available Qty = 50
        poLine.Quantity_Received__c = 50;
        update poLine;
        cLine = [select id, name, Quantity_Received__c, Quantity_Still_Due__c, Quantity_Returned__c, Purchased_Quantity__c, Remaining_Quantity__c, Available_Quantity__c from Contract_Line__c where id = :contractLine1.id];
        system.assertEquals(cline.Purchased_Quantity__c, 50);
        system.assertEquals(cLine.Quantity_Received__c, 50);
        system.assertEquals(cLine.Quantity_Still_Due__c, 0);
        system.assertEquals(cLine.Quantity_Returned__c, 0);
        system.assertEquals(cLine.Remaining_Quantity__c, 50);
        system.assertEquals(cLine.Available_Quantity__c, 50);

        //Use case 4 PO Over Receipt: Receive 10 more from the PO Created, so expected contract bucket field values should be
        //Purchased Qty = 50, Qty Received = 60, Qty Still Due = 0, Remaining Qty = 40, Available Qty = 50
        poLine.Quantity_Received__c = 60;
        update poLine;
        cLine = [select id, name, Quantity_Received__c, Quantity_Still_Due__c, Quantity_Returned__c, Purchased_Quantity__c, Remaining_Quantity__c, Available_Quantity__c from Contract_Line__c where id = :contractLine1.id];
        system.assertEquals(cline.Purchased_Quantity__c, 50);
        system.assertEquals(cLine.Quantity_Received__c, 60);
        system.assertEquals(cLine.Quantity_Still_Due__c, 0);
        system.assertEquals(cLine.Quantity_Returned__c, 0);
        system.assertEquals(cLine.Remaining_Quantity__c, 40);
        system.assertEquals(cLine.Available_Quantity__c, 50);

        //Use case 5 PO Returns: Receive remaining 30 from the PO Created, so expected contract bucket field values should be
        //Purchased Qty = 40(per PTP-574), Qty Received = 60, Qty Still Due = 0, Remaining Qty = 50, Available Qty = 60, Qty Returned = 10
        //PTP-574 - During returns, the return qty is put back to the purchased quantity
        poLine.Quantity_Returned_to_Supplier_for_Credit__c = 10;
        update poLine;
        cLine = [select id, name, Quantity_Received__c, Quantity_Still_Due__c, Quantity_Returned__c, Purchased_Quantity__c, Remaining_Quantity__c, Available_Quantity__c from Contract_Line__c where id = :contractLine1.id];
        system.assertEquals(cline.Purchased_Quantity__c, 40); //PTP-574 Puchased quantity will be updated during returns on PO
        system.assertEquals(cLine.Quantity_Received__c, 60);
        system.assertEquals(cLine.Quantity_Still_Due__c, 0);
        system.assertEquals(cLine.Quantity_Returned__c, 10);
        system.assertEquals(cLine.Remaining_Quantity__c, 50);
        system.assertEquals(cLine.Available_Quantity__c, 60);
        Test.stopTest();
    }

    //KNDY-7139 Check for ordering multiples during release - Ordering Multiple is 0
    static testMethod void test_ValidateOrderingMultiplesonItem_0() {

        mockData data = new mockData();
        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        Location__c location = fuel.location;

        facility_Item__c fItem = new Facility_Item__c();{
            fItem.Company__c = fuel.company.id;
            fItem.Facility__c = fuel.facility.Id;
            fItem.Item__c = fuel.itemList[0].id;
            fItem.Ordering_Multiple__c = 0;
            insert fITem;
        }
        Test.startTest();

        ApexPages.StandardController setCon = new Apexpages.StandardController(contractLine1);
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);
        ID itemID = fuel.itemList[0].Id;
        ID supID = fuel.supplier.id;
        ID facID = fuel.facility.Id;
        Contract_Line__c cLine = contractLine1;
        Date myDate = Date.today();
        String dateValue = myDate.format();

        JsonResult result = ContractLinesReleaseExtension.isWithinMOQ(cLine, supID, itemID, facID, dateValue, 10);
        system.assertEquals(true,result.success);
    }
}