@isTest
private class ReceivingDocumentAPITest {
    private static Receiving_Document__c receivingDocument { get; set; }
    private static List<Receipt_Line__c> receiptLines { get; set; }

    private static testMethod void testClose() {
        TestData data = new TestData();
		data.receivingdocument.Transaction_Date__c = system.now();
		data.receivingdocument1.Transaction_Date__c = system.now();
		update data.receivingdocument;
		update data.receivingdocument1;//PTP-400 setting TD as doc is finalized now
        Map<Id,ReceivingDocumentAPI.ReceivingDocumentWrapper> rdMap = new Map<Id,ReceivingDocumentAPI.ReceivingDocumentWrapper>();
        ReceivingDocumentAPI.ReceivingDocumentWrapper rdWrapper1 = new ReceivingDocumentAPI.ReceivingDocumentWrapper(data.receivingdocument.Id);
        ReceivingDocumentAPI.ReceivingDocumentWrapper rdWrapper2 = new ReceivingDocumentAPI.ReceivingDocumentWrapper(data.receivingdocument1.Id);
        rdMap.put(rdWrapper1.receivingDocumentId,rdWrapper1);
        rdMap.put(rdWrapper2.receivingDocumentId,rdWrapper2);

        Test.startTest();
        Map<Id,ReceivingDocumentAPI.ReceivingDocumentAPIStatus> statuses = ReceivingDocumentAPI.close(rdMap);
        Test.stopTest();
        System.assert([SELECT Id FROM Receiving_Document__c WHERE Status__c = 'Closed'].size() == 2,'all receiving documents should be closed');
        System.assert([SELECT Id FROM Receipt_Line__c WHERE Status__c = 'Closed'].size() == 4,'all receipt lines should be closed');
    }
    private static testMethod void testSuccessReceive() {
        Test.startTest();
        Testdata data = new TestData();
        dataSetup(data);
        Test.stopTest();
        ReceivingDocumentAPI.ReceivingDocumentAPIStatus status = ReceivingDocumentAPI.release(new Set<Id>{receivingDocument.Id});
        System.assert([SELECT Id,Status__c FROM Receiving_Document__c WHERE Id = :receivingDocument.Id][0].Status__c == 'Open');

        Map<Id,ReceivingDocumentAPI.ReceivingDocumentWrapper> rdMap = new Map<Id,ReceivingDocumentAPI.ReceivingDocumentWrapper>();
        ReceivingDocumentAPI.ReceivingDocumentWrapper rdWrapper = new ReceivingDocumentAPI.ReceivingDocumentWrapper(receivingDocument.Id);
        ReceivingDocumentAPI.ReceiptLineWrapper receiptLineWrapper = new ReceivingDocumentAPI.ReceiptLineWrapper();
        ReceivingDocumentAPI.ReceivingLine rl = new ReceivingDocumentAPI.ReceivingLine();
        rl.qtyReceived = receiptLines[0].Quantity_Declared__c;
        rl.lot = 'A';
        rl.expirationDate = Date.today() + 365;
        rl.dateReceived = Date.today();
        receiptLineWrapper.receivingLines.add(rl);
        rdWrapper.lines.put(receiptLines[0].Id,receiptLineWrapper);
        receiptLineWrapper = new ReceivingDocumentAPI.ReceiptLineWrapper();
        rl = new ReceivingDocumentAPI.ReceivingLine();
        rl.qtyReceived = receiptLines[1].Quantity_Declared__c;
        rl.lot = 'B';
        rl.expirationDate = Date.today() + 365;
        rl.dateReceived = Date.today();
        rl.attributes.put('Date_Received__c',Date.today());
        receiptLineWrapper.receivingLines.add(rl);
        rdWrapper.lines.put(receiptLines[1].Id,receiptLineWrapper);
        rdMap.put(rdWrapper.receivingDocumentId,rdWrapper);
        
        Map<Id,ReceivingDocumentAPI.ReceivingDocumentAPIStatus> statuses = ReceivingDocumentAPI.receive(rdMap);
        
        System.assert(statuses.values()[0].success, statuses);
        //System.assert([SELECT Id FROM Receiving_Document__c WHERE Status__c = 'Closed'].size() == 1,[SELECT Id, Status__c, Type__c FROM Receiving_Document__c]);
        System.assert([SELECT Id FROM Receipt_Line__c WHERE Status__c = 'Closed'].size() == 2);
        System.assert([SELECT Id FROM Purchase_Order__c WHERE Status__c = 'Closed'].size() == 1);
        System.assert([SELECT Id FROM Purchase_Order_Line__c WHERE Status__c = 'Closed'].size() == 1);
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Type__c = 'Location' AND Expiration_Date__c = :Date.today()+365 AND Lot_Number__c = 'A'][0].Quantity__c == 20);
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Type__c = 'Location' AND Expiration_Date__c = :Date.today()+365 AND Lot_Number__c = 'B'][0].Quantity__c == 5);
        
    }
    private static testMethod void testReceiveTooMuch() {
        Test.startTest();
        Testdata data = new TestData();
        dataSetup(data);
        Test.stopTest();
        ReceivingDocumentAPI.ReceivingDocumentAPIStatus status = ReceivingDocumentAPI.release(new Set<Id>{receivingDocument.Id});
        System.assert([SELECT Id,Status__c FROM Receiving_Document__c WHERE Id = :receivingDocument.Id][0].Status__c == 'Open');

        Map<Id,ReceivingDocumentAPI.ReceivingDocumentWrapper> rdMap = new Map<Id,ReceivingDocumentAPI.ReceivingDocumentWrapper>();
        ReceivingDocumentAPI.ReceivingDocumentWrapper rdWrapper = new ReceivingDocumentAPI.ReceivingDocumentWrapper(receivingDocument.Id);
        ReceivingDocumentAPI.ReceiptLineWrapper receiptLineWrapper = new ReceivingDocumentAPI.ReceiptLineWrapper();
        ReceivingDocumentAPI.ReceivingLine rl = new ReceivingDocumentAPI.ReceivingLine();
        rl.qtyReceived = receiptLines[0].Quantity_Declared__c;
        rl.lot = 'A';
        rl.expirationDate = Date.today() + 365;
        rl.dateReceived = Date.today();
        receiptLineWrapper.receivingLines.add(rl);
        rdWrapper.lines.put(receiptLines[0].Id,receiptLineWrapper);
        receiptLineWrapper = new ReceivingDocumentAPI.ReceiptLineWrapper();
        rl = new ReceivingDocumentAPI.ReceivingLine();
        rl.qtyReceived = receiptLines[1].Quantity_Declared__c+100;
        rl.lot = 'B';
        rl.expirationDate = Date.today() + 365;
        rl.dateReceived = Date.today();
        receiptLineWrapper.receivingLines.add(rl);
        rdWrapper.lines.put(receiptLines[1].Id,receiptLineWrapper);
        rdMap.put(rdWrapper.receivingDocumentId,rdWrapper);
        
        Map<Id,ReceivingDocumentAPI.ReceivingDocumentAPIStatus> statuses = ReceivingDocumentAPI.receive(rdMap);
        System.assert(!statuses.values()[0].success);
    }
    private static testMethod void testBadStatus() {
        Test.startTest();
        Testdata data = new TestData();
        dataSetup(data);
        Test.stopTest();

        ReceivingDocumentAPI.ReceivingDocumentAPIStatus status = ReceivingDocumentAPI.release(new Set<Id>{receivingDocument.Id});
        System.assert([SELECT Id,Status__c FROM Receiving_Document__c WHERE Id = :receivingDocument.Id][0].Status__c == 'Open');

        update new Receiving_Document__c(Id=receivingDocument.Id,Status__c='Draft');

        Map<Id,ReceivingDocumentAPI.ReceivingDocumentWrapper> rdMap = new Map<Id,ReceivingDocumentAPI.ReceivingDocumentWrapper>();
        ReceivingDocumentAPI.ReceivingDocumentWrapper rdWrapper = new ReceivingDocumentAPI.ReceivingDocumentWrapper(receivingDocument.Id);
        ReceivingDocumentAPI.ReceiptLineWrapper receiptLineWrapper = new ReceivingDocumentAPI.ReceiptLineWrapper();
        ReceivingDocumentAPI.ReceivingLine rl = new ReceivingDocumentAPI.ReceivingLine();
        rl.qtyReceived = receiptLines[0].Quantity_Declared__c;
        rl.lot = 'A';
        rl.expirationDate = Date.today() + 365;
        rl.dateReceived = Date.today();
        receiptLineWrapper.receivingLines.add(rl);
        rdWrapper.lines.put(receiptLines[0].Id,receiptLineWrapper);
        receiptLineWrapper = new ReceivingDocumentAPI.ReceiptLineWrapper();
        rl = new ReceivingDocumentAPI.ReceivingLine();
        rl.qtyReceived = receiptLines[1].Quantity_Declared__c+100;
        rl.lot = 'B';
        rl.expirationDate = Date.today() + 365;
        rl.dateReceived = Date.today();
        receiptLineWrapper.receivingLines.add(rl);
        rdWrapper.lines.put(receiptLines[1].Id,receiptLineWrapper);
        rdMap.put(rdWrapper.receivingDocumentId,rdWrapper);
        
        Map<Id,ReceivingDocumentAPI.ReceivingDocumentAPIStatus> statuses = ReceivingDocumentAPI.receive(rdMap);
        System.assert(!statuses.values()[0].success);
    }
    private static testMethod void testMissingAttribute() {
        Test.startTest();
        Testdata data = new TestData();
        dataSetup(data);
        Test.stopTest();

        ReceivingDocumentAPI.ReceivingDocumentAPIStatus status = ReceivingDocumentAPI.release(new Set<Id>{receivingDocument.Id});
        System.assert([SELECT Id,Status__c FROM Receiving_Document__c WHERE Id = :receivingDocument.Id][0].Status__c == 'Open');

        Map<Id,ReceivingDocumentAPI.ReceivingDocumentWrapper> rdMap = new Map<Id,ReceivingDocumentAPI.ReceivingDocumentWrapper>();
        ReceivingDocumentAPI.ReceivingDocumentWrapper rdWrapper = new ReceivingDocumentAPI.ReceivingDocumentWrapper(receivingDocument.Id);
        ReceivingDocumentAPI.ReceiptLineWrapper receiptLineWrapper = new ReceivingDocumentAPI.ReceiptLineWrapper();
        ReceivingDocumentAPI.ReceivingLine rl = new ReceivingDocumentAPI.ReceivingLine();
        rl.qtyReceived = receiptLines[0].Quantity_Declared__c;
        //rl.lot = 'A';
        rl.expirationDate = Date.today() + 365;
        rl.dateReceived = Date.today();
        receiptLineWrapper.receivingLines.add(rl);
        rdWrapper.lines.put(receiptLines[0].Id,receiptLineWrapper);
        receiptLineWrapper = new ReceivingDocumentAPI.ReceiptLineWrapper();
        rl = new ReceivingDocumentAPI.ReceivingLine();
        rl.qtyReceived = receiptLines[1].Quantity_Declared__c+100;
        rl.lot = 'B';
        //rl.expirationDate = Date.today() + 365;
        rl.dateReceived = Date.today();
        receiptLineWrapper.receivingLines.add(rl);
        rdWrapper.lines.put(receiptLines[1].Id,receiptLineWrapper);
        rdMap.put(rdWrapper.receivingDocumentId,rdWrapper);
        
        Map<Id,ReceivingDocumentAPI.ReceivingDocumentAPIStatus> statuses = ReceivingDocumentAPI.receive(rdMap);
        System.assert(!statuses.values()[0].success);
    }
    private static testMethod void testReceivingDocumentRelease() {
        TestFuel testData = new TestFuel();
        Receiving_Document__c rd = testData.receivingDocumentASN;
        
        Test.startTest();
        ReceivingDocumentAPI.ReceivingDocumentAPIStatus status = ReceivingDocumentAPI.release(new Set<Id>{rd.Id});
        Test.stopTest();
        
        List<Receipt_Line__c> rlList = [SELECT Id,Status__c,Purchase_Order__r.FOB_Term__r.FOB_Point__c,(SELECT Id,Quantity__c,Type__c FROM SKIDs__r),Receiving_Document__r.Status__c FROM Receipt_Line__c WHERE Receiving_Document__c =:rd.id];
        System.assert(rlList.size() == 1);
        Receipt_Line__c rl = rlList[0];
        System.assert(rl.Status__c == 'Open',status.errorMessage);
        System.assert(rl.Receiving_Document__r.Status__c == 'Open');
        System.assert(rl.Purchase_Order__r.FOB_Term__r.FOB_Point__c != 'Origin');
        System.assert(rl.SKIDs__r.size() == 0);
    }
    private static testMethod void testReceivingDocumentReleaseErrors() {
        TestFuel testData = new TestFuel();
        Receiving_Document__c rd = testData.receivingDocumentASN;
        rd.Status__c = 'Closed';
        DML.updateAsUser(rd);
        
        Test.startTest();
        ReceivingDocumentAPI.ReceivingDocumentAPIStatus status = ReceivingDocumentAPI.release(new Set<Id>{rd.Id});
        Test.stopTest();
        
        System.assert(!status.success, 'Receiving Document is not draft'); 
    }


    private static void dataSetup(TestData data) {
        data.itemList[2].Item_Attribute__c = data.itemAttrObj.Id;
        update data.itemList[2];
        update new Item_Attribute__c(Id=data.itemAttrObj.Id,Date_Received__c=true);
        List<Configuration__c> configList = new List<Configuration__c>();  
        List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Bin__c.sObjectType};  
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        data.location3.Bin_Tracked__c = false;
        update data.location3;
        delete configList;
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c WHERE Id = :data.purchaseOrder2.Id LIMIT 1];
        po.Approval_Status__c = 'Approved';
        po.Status__c = 'Open';
        update po;

        receivingDocument = new Receiving_Document__c();
        receivingDocument.Company__c = data.company.Id;
        receivingDocument.Supplier__c = data.supplier.Id;
        receivingDocument.Type__c = 'Advanced Shipment Notice';
        receivingDocument.Status__c = 'Draft';
        receivingDocument.Currency__c = TestFuel.currencyUSD.id;
        insert receivingDocument;
        receiptLines = new List<Receipt_Line__c>();
        receiptLines.add(new Receipt_Line__c());
        receiptLines[0].Company__c = data.company.Id;
        receiptLines[0].Supplier__c = data.supplier.Id;
        receiptLines[0].Receiving_Document__c = receivingDocument.Id;
        receiptLines[0].Purchase_Order__c = data.purchaseorder2.Id;
        receiptLines[0].Status__c = 'Draft';
        Purchase_Order_Line__c poLine = [SELECT Id,Quantity_Still_Due__c,Item__c FROM Purchase_Order_Line__c WHERE Purchase_Order__c =: data.purchaseorder2.Id LIMIT 1]; 
        receiptLines[0].Purchase_Order_Line__c = poLine.Id;
        receiptLines[0].Item__c = poLine.Item__c;
        receiptLines[0].Quantity_Declared__c = poLine.Quantity_Still_Due__c - 5;
        receiptLines.add(new Receipt_Line__c());
        receiptLines[1].Company__c = data.company.Id;
        receiptLines[1].Supplier__c = data.supplier.Id;
        receiptLines[1].Receiving_Document__c = receivingDocument.Id;
        receiptLines[1].Purchase_Order__c = data.purchaseorder2.Id;
        receiptLines[1].Purchase_Order_Line__c = poLine.Id;
        receiptLines[1].Quantity_Declared__c = 5;
        receiptLines[1].Status__c = 'Draft';
        receiptLines[1].Item__c = poLine.Item__c;
        insert receiptLines;
    }
}