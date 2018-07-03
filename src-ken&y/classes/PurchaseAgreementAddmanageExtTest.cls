@isTest
public class PurchaseAgreementAddmanageExtTest {

    @testSetup
    private static void setupfuel() {
        TestFuel dataInit = new TestFuel();
        // initialize necessary data to be queried by TestDataQuery
        system.assert(
                dataInit.company != null &&
                dataInit.ContractAM != null &&
                dataInit.uomInch != null &&
                dataInit.ContractLine != null
        );
    }

    static TestFuelQuery fuel = new TestFuelQuery();

    static testMethod void addPALines(){

        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        ApexPages.StandardController setCon = new Apexpages.StandardController(contract);
        PurchaseAgreementAddManageExt pa = new PurchaseAgreementAddManageExt(setCon);
        JSONResult result = new JSONResult();

        List< Contract_Line__c > addpalList = new List< Contract_Line__c >();
        List< Contract_Line__c > updpalList = new List< Contract_Line__c >();
        List< Contract_Line__c > delpalList = new List< Contract_Line__c >();


        Contract_Line__c contractLine2 = new Contract_Line__c();{
            contractLine2.Company__c = fuel.company.Id;
            contractLine2.Item__c = fuel.itemlist[1].id;
            contractLine2.Name = 'Test CTL 2';
            contractLine2.Contract_Start__c = Date.today().addDays(-3);
            contractLine2.Contract_End__c = Date.today().addDays(5);
            contractLine2.Status__c = 'Open';
            contractLine2.Negotiated_Price__c = 12;
            contractLine2.Contract_Quantity__c = 500;
            contractLine2.Consigned__c = true;
            contractLine2.Purchased_Quantity__c = 0;
            contractLine2.Quantity_Received__c = 0;
            contractLine2.Quantity_Still_Due__c = 0;
            contractLine2.Quantity_Returned__c = 0;
            contractLine2.Purchase_UOM__c = fuel.uomInch.id;
            addpalList.add(contractLine2);
        }

        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Contract_Start__c');
            headerDateFields.add('Contract_End__c');
        }

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Contract_Start__c');
            dateFields.add('Contract_End__c');
        }

        List<String> parentRecord = new List<String>();
        {
            parentRecord.add(JSON.serialize(contract));
        }

        test.StartTest();
        result = PurchaseAgreementAddmanageExt.saveAction(contract, headerDateFields, updpalList, addpalList, delpalList, dateFields);
        system.assertEquals(result.success, true);

        //Verify that the line is inserted along with the existing line
        List<Contract_Line__c> paLines = [select id, name, Approved__c, Status__c from Contract_Line__c where Contract__c = :contract.id];
        system.assertEquals(paLines.size(), 2);

        //verify if the Approved is false for both the lines as the PA is yet to be approved
        system.assertEquals(contract.Approval_Status__c, 'Pending Authorization');
        for (Contract_Line__c paLine : paLines){
            system.assertEquals(paLine.Approved__c, false);
        }

        //Update the approval status to Approved and check if all lines are now approved
        contract.Approval_Status__c = 'Approved';
        update contract;

        paLines = [select id, name, Approved__c, Status__c from Contract_Line__c where Contract__c = :contract.id];
        for (Contract_Line__c paLine : paLines){
            system.assertEquals(paLine.Approved__c, true);
        }
        test.StopTest();

    }

    static testMethod void testPAStatusonApproval(){

        Contract__c contract = fuel.ContractAM;
        contract.Contract_Start__c = Date.today();
        contract.Approval_Status__c = 'Pending Authorization';
        update contract;

        system.assertEquals(contract.Approval_Status__c, 'Pending Authorization');
        contract.Approval_Status__c = 'Approved';
        update contract;

        contract = [select id, name, Status__c, Approval_Status__c from Contract__c where id = :contract.id];
        system.assertEquals(contract.Status__c, 'Open');

    }

    static testMethod void testFlipApprovalStatus_headerchange(){

        Contract__c contract = fuel.ContractAM;
        contract.FOB_Term__c = fuel.fobTerm.id;
        update contract;

        Contract__c pa = [select id, name, Status__c, Approval_Status__c from Contract__c where id = :contract.id];
        system.assertEquals(pa.Approval_Status__c, 'Pending Authorization');
    }

    static testMethod void testFlipApprovalStatus_linechange(){

        Contract__c contract = fuel.ContractAM;
        Contract_Line__c contractLine1 = fuel.ContractLine;
        contract.Approval_Status__c = 'Approved';
        update contract;

        //Check header approval status on pa line updates
        contractLine1.Contract_Quantity__c = 800;
        update contractLine1;

        Contract__c pa = [select id, name, Status__c, Approval_Status__c from Contract__c where id = :contract.id];
        system.assertEquals(pa.Approval_Status__c, 'Pending Authorization');

        //check line approval status on pa line inserts
        contract.Approval_Status__c = 'Approved';
        update contract;

        Contract_Line__c contractLine2 = new Contract_Line__c();{
            contractLine2.Contract__c = contract.Id;
            contractLine2.Company__c = fuel.company.Id;
            contractLine2.Item__c = fuel.itemlist[1].id;
            contractLine2.Name = 'Test CTL 3';
            contractLine2.Contract_Start__c = Date.today().addDays(-3);
            contractLine2.Contract_End__c = Date.today().addDays(7);
            contractLine2.Status__c = 'Open';
            contractLine2.Negotiated_Price__c = 12;
            contractLine2.Contract_Quantity__c = 600;

            insert contractLine2;
        }

        pa = [select id, name, Status__c, Approval_Status__c from Contract__c where id = :contract.id];
        system.assertEquals(pa.Approval_Status__c, 'Pending Authorization');

    }

    static testMethod void testPALinesCancel(){

        Contract__c contract = fuel.ContractAM;
        contract.Approval_Status__c = 'Approved';
        update contract;

        Contract_Line__c cl = fuel.ContractLine;
        cl.Approved__c = true;
        update cl;

        Test.startTest();
        JSONResult result = PurchaseAgreementAddManageExt.cancelLines(new List<Contract_Line__c>{cl});
        system.assertEquals(result.success, true);

        cl = [select id, name, Status__c, Quantity_Received__c,PurchasedValue__c, Approved__c from Contract_Line__c where id = :cl.id];
        system.assertEquals(cl.Status__c, 'Cancelled');
        Test.stopTest();

    }

    static testMethod void testPALinesClose(){

        Contract__c contract = fuel.ContractAM;
        contract.Approval_Status__c = 'Approved';
        update contract;

        Contract_Line__c cl = fuel.ContractLine;
        cl.Approved__c = true;
        update cl;

        Test.startTest();
        JSONResult result = PurchaseAgreementAddManageExt.closeLines(new List<Contract_Line__c>{cl});
        system.assertEquals(result.success, true);

        cl = [select id, name, Status__c, Quantity_Received__c,PurchasedValue__c, Approved__c from Contract_Line__c where id = :cl.id];
        system.assertEquals(cl.Status__c, 'Closed');
        Test.stopTest();

    }

    static testMethod void testPALinesCloseCancelFailure(){

        Contract__c contract = fuel.ContractAM;
        Contract_Line__c cl = fuel.ContractLine;

        Test.startTest();
        JSONResult result = PurchaseAgreementAddManageExt.cancelLines(new List<Contract_Line__c>{cl});
        system.assertEquals(result.success, false);

        result = PurchaseAgreementAddManageExt.closeLines(new List<Contract_Line__c>{cl});
        system.assertEquals(result.success, false);

        Test.stopTest();

    }

    static testMethod void testPAHeaderCancel(){

        Contract__c contract = fuel.ContractAM;

        Test.startTest();
        JSONResult result = PurchaseAgreementAddManageExt.approve(contract.id);
        system.assertEquals(result.success, true);

        result = PurchaseAgreementAddManageExt.cancel(contract.id);
        system.assertEquals(result.success, true);

        Test.stopTest();

    }

    static testMethod void testPAHeaderClose(){

        Contract__c contract = fuel.ContractAM;

        Test.startTest();
        JSONResult result = PurchaseAgreementAddManageExt.approve(contract.id);
        system.assertEquals(result.success, true);

        result = PurchaseAgreementAddManageExt.close(contract.id);
        system.assertEquals(result.success, true);

        Test.stopTest();

    }

    static testMethod void testPADelete(){

        Contract__c contract = fuel.ContractAM;

        Test.startTest();
        JSONResult result = PurchaseAgreementAddManageExt.deletepa(contract.id);
        system.assertEquals(result.success, true);

        Test.stopTest();

    }

    //PALine qty checks against MOQ
    static testMethod void testPALineQtyAgainstMOQ() { //KNDY-10599
        PAData data = new PAData();
        Contract__c contract = fuel.ContractAM;

        //Contract Line that is active, without MOQ and UOM
        Contract_Line__c contractItem = new Contract_Line__c();
        contractItem.Contract__c = contract.Id;
        contractItem.Contract_Start__c = Date.today().addDays(-1);
        contractItem.Contract_End__c = Date.today().addDays(4);
        contractItem.Status__c = 'Active';
        contractItem.Negotiated_Price__c = 100;
        contractItem.Item__c = fuel.itemlist[0].id;
        contractItem.Purchase_UOM__c = fuel.uomInch.id;

        // MOQ is greater than contract qty
        contractItem.Minimum_Order_Quantity__c = 20;
        contractItem.Contract_Quantity__c = 10;

        PageReference pageRef = Page.PurchaseAgreementAddManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(contract);
        PurchaseAgreementAddManageExt con = new PurchaseAgreementAddManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        data.getDateFields(headerDateFields, dateFields);
        List< Contract_Line__c > newpalList = new List< Contract_Line__c >();
        List< Contract_Line__c > updatedpalList = new List< Contract_Line__c >();
        List< Contract_Line__c > deletedpalList = new List< Contract_Line__c >();
        newpalList.add(contractItem);

        List<String> parentRecord = new List<String>();
        {
            parentRecord.add(JSON.serialize(contract));
        }
        Test.startTest();
        JSONResult result = PurchaseAgreementAddManageExt.saveAction(contract, headerDateFields, newpalList, updatedpalList, deletedpalList, dateFields);
        system.assertEquals(false, result.success);
        system.assert(result.messages.size() == 1);
        String expectedErrorMessage = Label.Purchase_Agreement_Quantity_cannot_be_less_than_minimum_order_quantity;
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage));
        }
        Test.stopTest();
    }

    static testMethod void testClone_OpenPA() { //KNDY-10083
        PAData data = new PAData();
        Contract__c contract = fuel.ContractAM;
        contract.Contract_Start__c = Date.today();
        contract.Approval_Status__c = 'Pending Authorization';
        update contract;

        Contract_Line__c cl = fuel.ContractLine;

        Test.startTest();
        PageReference pageRef = Page.PurchaseAgreementAddManage;
        pageRef.getParameters().put('Id', data.contract.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(contract);
        PurchaseAgreementAddManageExt con = new PurchaseAgreementAddManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        data.getDateFields(headerDateFields, dateFields);

        system.assert(con.pageTitle.contains ('Clone of'));

        // Tests for cloned Purchase Agreement
        JsonResult result = PurchaseAgreementAddManageExt.getPurchaseAgreementDetails(contract.Id, '1');
        system.assert(result.success == true);
        system.assert(result.records != null);
        system.assert(result.records.size() == 1);
        Contract__c paClone = (Contract__c)result.records[0];
        system.assertEquals(paClone.Status__c, 'Draft');
        system.assertEquals(paClone.Approval_Status__c, 'Pending Authorization');
        system.assertEquals(paClone.Id, null);

        // Tests for cloned lines
        GridRelatedListController.GridRelatedListConfig config = con.purchaseAgreementLinesConfig;
        result = PurchaseAgreementAddManageExt.getPurchaseAgreementLines(config, '1', (List<String>) JSON.deserialize(con.getAllFields(), List<String>.class)); // cloning lines
        system.assertEquals(1, result.total);
        Contract_Line__c palClone = (Contract_Line__c) result.records[0];
        system.assertEquals(palClone.Id, null);
        Test.stopTest();
    }

    static testMethod void testClone_ApprovedPA() { //KNDY-10083
        PAData data = new PAData();
        Contract__c contract = fuel.ContractAM;
        contract.Contract_Start__c = Date.today();
        contract.Approval_Status__c = 'Approved';
        update contract;

        Contract_Line__c cl = fuel.ContractLine;
        cl.Approved__c = true;
        update cl;

        Test.startTest();
        PageReference pageRef = Page.PurchaseAgreementAddManage;
        pageRef.getParameters().put('Id', data.contract.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(contract);
        PurchaseAgreementAddManageExt con = new PurchaseAgreementAddManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        data.getDateFields(headerDateFields, dateFields);

        system.assert(con.pageTitle.contains ('Clone of'));

        // Tests for cloned Purchase Agreement
        JsonResult result = PurchaseAgreementAddManageExt.getPurchaseAgreementDetails(contract.Id, '1');
        system.assert(result.success == true);
        system.assert(result.records != null);
        system.assert(result.records.size() == 1);
        Contract__c paClone = (Contract__c)result.records[0];
        system.assertEquals(paClone.Status__c, 'Draft');
        system.assertEquals(paClone.Approval_Status__c, 'Pending Authorization');
        system.assertEquals(paClone.Id, null);

        // Tests for cloned lines
        GridRelatedListController.GridRelatedListConfig config = con.purchaseAgreementLinesConfig;
        result = PurchaseAgreementAddManageExt.getPurchaseAgreementLines(config, '1', (List<String>) JSON.deserialize(con.getAllFields(), List<String>.class)); // cloning lines
        system.assertEquals(1, result.total);
        Contract_Line__c palClone = (Contract_Line__c) result.records[0];
        system.assertEquals(palClone.Id, null);
        Test.stopTest();
    }

    static testMethod void dummyTestForAdditionalCoverage(){

        PAData data = new PAData();
        Contract__c contract = fuel.ContractAM;

        ApexPages.StandardController setCon = new Apexpages.StandardController(contract);
        PurchaseAgreementAddManageExt paExt = new PurchaseAgreementAddManageExt(setCon);
        paExt.getCustomViews();
        paExt.getCustomViewFields();
        paExt.getPurchaseAgreementHeaderFieldList();
        paExt.getPurchaseAgreementAddlHeaderFieldList();
        paExt.getPurchaseAgreementLinesFieldList();
        paExt.getReturnUrl();
        paExt.getPurchaseAgreementJSON();
        paExt.getPurchaseAgreementLinesConfigJson();
        PurchaseAgreementAddManageExt.getPurchaseAgreementDetails(contract.id, null);
        PurchaseAgreementAddManageExt.getPurchaseAgreementLines (data.paLinesConfig, null, (List<String>) JSON.deserialize(paExt.getAllFields(), List<String>.class));

        List< Contract_Line__c > palList = new List< Contract_Line__c >();

         List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Contract_Start__c');
            headerDateFields.add('Contract_End__c');
        }

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Contract_Start__c');
            dateFields.add('Contract_End__c');
        }

        List<String> parentRecord = new List<String>();
        {
            parentRecord.add(JSON.serialize(contract));
        }

        PurchaseAgreementAddManageExt.saveAction(contract, headerDateFields, palList, palList, palList, dateFields);
    }

     public class PAData{
         Contract__c contract = fuel.ContractAM;
        GridRelatedListController.GridRelatedListConfig paLinesConfig = new GridRelatedListController.GridRelatedListConfig();{
            paLinesConfig.uniqueId = 'PurchaseAgreementLinesGrid';
            paLinesConfig.title = 'Purchase Agreement Lines';
            paLinesConfig.parentRecord = contract;
            paLinesConfig.objectName = 'Contract_Line__c';
            paLinesConfig.parentField = 'Contract__c';
            paLinesConfig.fieldset = 'All_Fields';
            paLinesConfig.buttons = 'create, delete, columnmenu, search';
        }

        public void getDateFields(List<String> headerDateFields, List<String> lineDateFields){
            headerDateFields = new List<String>{'Contract_Start__c','Contract_End__c'};
            lineDateFields = new List<String>{'Contract_Start__c','Contract_End__c'};
        }
     }

}