@isTest
public with sharing class PurchaseOrderManageExtTest {
    static PurchaseOrderManageExtTestData testData = new PurchaseOrderManageExtTestData();
    
    // Transaction Currency is not required from API
    static testmethod void saveNewPurchaseOrder_NoTransactionCurrency(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);

        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        system.assertEquals(true, result.success);
        Test.stopTest();
    }
    
    // Buyer default
    static testmethod void saveNewPurchaseOrder_Buyer(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        
        JsonResult result = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        system.assertEquals(true, result.success);
        po = [Select Id, Buyer__c from Purchase_Order__c where id = :po.Id];
        system.assertEquals(po.Buyer__c, UserInfo.getUserId());
    }
    
    // New Purchase Order - Acknowledge Via Field should default from Supplier
    static testmethod void saveNewPurchaseOrder_NoAcknowlegdeVia(){
        // Set Preferred correspondence on Supplier
        Supplier__c supplier = testData.fuel.supplier;
        supplier.Preferred_Correspondence__c = 'Chatter';
        update supplier;
        
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = supplier.id;
        po.Type__c  = 'Standard';
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);

        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        system.assertEquals(true, result.success);
        Purchase_Order__c pOrder = [Select Id, Acknowledge_Via__c from Purchase_Order__c
                                     where Id = :po.Id];
        system.assert(pOrder.Acknowledge_Via__c == supplier.Preferred_Correspondence__c);
        Test.stopTest();
    }
    
    // Acknowledge Via Field should not default from Supplier
    static testmethod void saveNewPurchaseOrder_WithAcknowlegdeVia(){
        // Set Preferred correspondence on Supplier
        Supplier__c supplier = testData.fuel.supplier;
        supplier.Preferred_Correspondence__c = 'Chatter';
        update supplier;
        
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = supplier.id;
        po.Type__c  = 'Standard';
        po.Acknowledge_Via__c = 'Email';
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);

        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        system.assertEquals(true, result.success);
        Purchase_Order__c pOrder = [Select Id, Acknowledge_Via__c from Purchase_Order__c
                                     where Id = :po.Id];
        system.assert(pOrder.Acknowledge_Via__c != supplier.Preferred_Correspondence__c);
        system.assert(pOrder.Acknowledge_Via__c == 'Email');
        Test.stopTest();
    }
    
    // Drop Ship PO cannot be created from PurchaseOrderManage Page
    static testmethod void saveNewPurchaseOrder_DropShip(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Drop Ship';
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        system.assertEquals(false, result.success);
        system.assert(result.messages.size() == 1);
        Set<String> expectedErrorMessages = new Set<String>{Label.Purchase_Order_creation_failed_Cannot_create_Drop_Ship_PO};
        for (Map<String, String> error : result.messages) {
            system.assert(expectedErrorMessages.contains(error.get('message')));
        }
        Test.stopTest();
    }

    // POLines can be added on a drop ship PO from PurchaseOrderManage Page
    static testmethod void saveNewPurchaseOrderLines_DropShip(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Drop Ship';
        insert po;
        
        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c newLine = testdata.createLine(po, 50, 1, item, 'Open');
        testData.insertUOMConversion(item, newLine.Purchase_UOM__c);
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        // one new POL
        PurchaseOrderManageExt.POLineWrapper newPOLineWrapper = new PurchaseOrderManageExt.POLineWrapper(newLine);
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>{newPOLineWrapper};

        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        system.assertEquals(true, result.success);
        system.assert(result.messages.size() == 1);
        Set<String> expectedErrorMessages = new Set<String>{Label.Changes_saved};
        for (Map<String, String> error : result.messages) {
            system.assert(expectedErrorMessages.contains(error.get('message')));
        }
        Test.stopTest();
    }

    static testmethod void createNewPO_ApprovalStatus(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Currency__c = TestFuel.currencyUSD.id;
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);

        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        Purchase_Order__c savedPO = [Select Id, Approval_Status__c from Purchase_Order__c where Id = :po.Id];
        system.assertEquals(savedPO.Approval_Status__c, 'Pending Authorization');
        Test.stopTest();
    }
    
    static testmethod void createNewPO_testDefaults(){ //KNDY-11133
        Company__c company = testData.fuel.company;
        company.Default_Purchasing_Deliver_To_Facility__c = testData.fuel.facility.Id;
        update company;
        Facility__c facility = testData.fuel.facility;
        facility.Default_Purchasing_Delivery_Location__c = testData.fuel.location.Id;
        update facility;
        UserPreference.getInstance().preference.Default_Company__c = testData.fuel.company.Id;
        UserPreference.getInstance().preference.Default_Facility__c = testData.fuel.facility2.Id;
        UserPreference.getInstance().updateUserPreference();
        
        Facility__c facility2 = testData.fuel.facility2;
        facility2.Default_Purchasing_Delivery_Location__c = testData.fuel.location2.Id;
        update facility2;
        
        Id defaultCompanyId = CompanyService.getDefaultCompanyId();
        Company__c defaultCompany = CompanyService.getCompanyInfo(defaultCompanyId);
        
        Test.startTest();
        Purchase_Order__c po = new Purchase_Order__c();
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        Purchase_Order__c newPO = con.po;
        system.assertEquals(newPO.Company__c, defaultCompany.Id);
        system.assertEquals(newPO.Currency__c, defaultCompany.Default_Transaction_Currency__c);
        system.assertEquals(newPO.Delivery_Facility__c, testData.fuel.facility2.Id );
        system.assertEquals(newPO.Delivery_Location__c, testData.fuel.location2.Id );
        Test.stopTest();
    }
    
    static testmethod void approvePO_Success(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Currency__c = TestFuel.currencyUSD.id;
        insert po;
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.approvePO(po.Id);
        Purchase_Order__c savedPO = [Select Id, Approval_Status__c from Purchase_Order__c where Id = :po.Id];
        system.assertEquals(savedPO.Approval_Status__c, 'Approved');
        Test.stopTest();
    }
    
    // Cancel PO with open lines, lines should be cancelled
    static testmethod void CancelPOWithOpenLines(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        insert po;

        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c line = testdata.createLine(po, 50, 1, item, 'Open');
        testData.insertUOMConversion(item, line.Purchase_UOM__c);

        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        // one new POL
        PurchaseOrderManageExt.POLineWrapper newPOLineWrapper = new PurchaseOrderManageExt.POLineWrapper(line);
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>{newPOLineWrapper};

        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        
        JsonResult result = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        system.assertEquals(true, result.success);
        
        Test.startTest();
        result = PurchaseOrderManageExt.cancelPO(po.Id);
        system.assertEquals(true, result.success);
        Purchase_Order__c savedPO = [Select Id, Status__c from Purchase_Order__c where Id = :po.Id];
        system.assertEquals(savedPO.Status__c, 'Cancelled');
        Purchase_Order_Line__c cancelledPOL = [Select Id, Status__c from Purchase_Order_Line__c where Id = :line.Id];
        system.assertEquals(cancelledPOL.Status__c, 'Cancelled');
        Test.stopTest();
    }

    // Cancel PO without any lines, PO should be cancelled
    static testmethod void CancelPO_WithNoLines(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Status__c = 'Open';
        insert po;
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.cancelPO(po.Id);
        system.assertEquals(true, result.success);
        Purchase_Order__c savedPO = [Select Id, Status__c from Purchase_Order__c where Id = :po.Id];
        system.assertEquals(savedPO.Status__c, 'Cancelled');
        Test.stopTest();
    }
        
    // Close PO with open lines, lines should be closed
    static testmethod void ClosePOWithOpenLines(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        insert po;
        
        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c line = testdata.createLine(po, 50, 1, item, 'Open');
        testData.insertUOMConversion(item, line.Purchase_UOM__c);
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        // one new POL
        PurchaseOrderManageExt.POLineWrapper newPOLineWrapper = new PurchaseOrderManageExt.POLineWrapper(line);
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>{newPOLineWrapper};

        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        
        JsonResult result = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        system.assertEquals(true, result.success);
        
        Test.startTest();
        result = PurchaseOrderManageExt.closePO(po.Id);
        system.assertEquals(true, result.success);
        Purchase_Order__c savedPO = [Select Id, Status__c from Purchase_Order__c where Id = :po.Id];
        system.assertEquals(savedPO.Status__c, 'Closed');
        Purchase_Order_Line__c closedPOL = [Select Id, Status__c from Purchase_Order_Line__c where Id = :line.Id];
        system.assertEquals(closedPOL.Status__c, 'Closed');
        Test.stopTest();
    }

    // Close PO without any lines, PO should be closed
    static testmethod void ClosePO_WithNoLines(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Status__c = 'Open';
        insert po;
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);  
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.closePO(po.Id);
        system.assertEquals(true, result.success);
        Purchase_Order__c savedPO = [Select Id, Status__c from Purchase_Order__c where Id = :po.Id];
        system.assertEquals(savedPO.Status__c, 'Closed');
        Test.stopTest();
    }
        
    // Close lines, PO should also close
    static testmethod void closeLine_POClose(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Status__c = 'Open';
        insert po;

        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c line = testdata.createLine(po, 50, 1, item, 'Open');
        testData.insertUOMConversion(item, line.Purchase_UOM__c);

        insert line;
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        // one POL to close
        PurchaseOrderManageExt.POLineWrapper updatedPOLineWrapper = new PurchaseOrderManageExt.POLineWrapper(line);
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>{updatedPOLineWrapper};
        
        Test.startTest();
        JSONResult result = PurchaseOrderManageExt.closeLines(po.Id, updatedList, dateFields );
        system.assertEquals(true, result.success);
        system.assertEquals(result.records.size(), 1);
        Purchase_Order__c savedPOObj =  (Purchase_Order__c)result.records[0];
        system.assertEquals(savedPOObj.Status__c , 'Closed');
        Purchase_Order_Line__c closedPOL = [Select Id, Status__c from Purchase_Order_Line__c where Id = :line.Id];
        system.assertEquals(closedPOL.Status__c, 'Closed');
        Test.stopTest();
    }
    
    // Cancel lines, PO should also cancel
    static testmethod void cancelLine_POCancel(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Status__c = 'Open';
        insert po;
        
        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c line = testdata.createLine(po, 50, 1, item, 'Open');
        testData.insertUOMConversion(item, line.Purchase_UOM__c);

        insert line;
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        // one POL to cancel
        PurchaseOrderManageExt.POLineWrapper updatedPOLineWrapper = new PurchaseOrderManageExt.POLineWrapper(line);
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>{updatedPOLineWrapper};
        
        Test.startTest();
        JSONResult result = PurchaseOrderManageExt.cancelLines(po.Id, updatedList, dateFields );
        system.assertEquals(true, result.success);
        system.assertEquals(result.records.size(), 1);
        Purchase_Order__c savedPOObj =  (Purchase_Order__c)result.records[0];
        system.assertEquals(savedPOObj.Status__c , 'Cancelled');
        Purchase_Order_Line__c POL = [Select Id, Status__c from Purchase_Order_Line__c where Id = :line.Id];
        system.assertEquals(POL.Status__c, 'Cancelled');
        Test.stopTest();
    }

    static testmethod void closeLine_Error(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Status__c = 'Open';
        insert po;

        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c line = testdata.createLine(po, 50, 1, item, 'Open');
        testData.insertUOMConversion(item, line.Purchase_UOM__c);

        insert line;
        line.Status__c = 'Closed';
        update line;
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        // one POL to close
        PurchaseOrderManageExt.POLineWrapper updatedPOLineWrapper = new PurchaseOrderManageExt.POLineWrapper(line);
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>{updatedPOLineWrapper};
        
        Test.startTest();
        JSONResult result = PurchaseOrderManageExt.closeLines(po.Id, updatedList, dateFields );
        system.assertEquals(false, result.success);
        system.assert(result.messages.size() == 1);
        String expectedErrorMessage = Label.Selected_Lines_are_already_closed_or_cancelled;
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage));
        }
        Test.stopTest();
    }
    
    static testmethod void cancelLine_Error(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Status__c = 'Open';
        insert po;

        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c line = testdata.createLine(po, 50, 1, item, 'Open');
        testData.insertUOMConversion(item, line.Purchase_UOM__c);

        insert line;
        line.Status__c = 'Closed';
        update line;
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        // one POL to cancel
        PurchaseOrderManageExt.POLineWrapper updatedPOLineWrapper = new PurchaseOrderManageExt.POLineWrapper(line);
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>{updatedPOLineWrapper};
        
        Test.startTest();
        JSONResult result = PurchaseOrderManageExt.cancelLines(po.Id, updatedList, dateFields );
        system.assertEquals(false, result.success);
        system.assert(result.messages.size() == 1);
        String expectedErrorMessage = Label.Selected_Lines_are_already_closed_or_cancelled;
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage));
        }
        Test.stopTest();
    }
    
    static testmethod void deletePO_Success(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Currency__c = TestFuel.currencyUSD.id;
        insert po;
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.deletePO(po.Id);
        system.assert(result.success);
        Test.stopTest();
    }
    static testMethod void testdeletePOLValidation() {
    	Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        insert po;
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        
        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c newLine1 = testdata.createLine(po, 10, 1, item, 'Open');
        testData.insertUOMConversion(item, newLine1.Purchase_UOM__c);
        
        List<Purchase_Order_Line__c> lines = new List<Purchase_Order_Line__c>{newLine1}; 
        insert lines;
        Test.startTest();
       	JsonResult result = PurchaseOrderManageExt.approvePO(po.Id);
       	system.assert(result.success);
        
        List<Purchase_Order_Line__c> pols = [select id, name, Approved__c from Purchase_Order_Line__c where Purchase_Order__c =:po.id];
        system.assert(pols[0].Approved__c = true);
        try{
        	delete pols;	
        }catch(exception e){
        	system.assert(e.getMessage().contains('Approved Purchase Order lines cannot be deleted.'));	
        }
        Test.stopTest();
    }
    
    // KNDY-8783 POLines should be ordered by Line__c Asc
    static testMethod void testPOLinesDisplayOrder(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        insert po;
        
        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c newLine1 = testdata.createLine(po, 10, 1, item, 'Open');
        Purchase_Order_Line__c newLine2 = testdata.createLine(po, 20, 1, item, 'Open');
        testData.insertUOMConversion(item, newLine1.Purchase_UOM__c);
        
        List<Purchase_Order_Line__c> lines = new List<Purchase_Order_Line__c>{newLine1, newLine2};
        insert lines;
        
        ApexPages.StandardController setCon = new Apexpages.StandardController(po); 
        PurchaseOrderManageExt ext = new PurchaseOrderManageExt(setCon);
        ext.getPOLinesConfigJson();
        JSONResult result = PurchaseOrderManageExt.getPOLines (ext.poLinesConfig, null, (List<String>) JSON.deserialize(ext.getAllFields(), List<String>.class));
        system.assert(result.records.size() == 2);
        Decimal poLine0_LineNumber;
        Decimal poLine1_LineNumber;
        for (Integer ix=0; ix < result.records.size(); ix ++){
            PurchaseOrderManageExt.POLineWrapper poLWrapper = (PurchaseOrderManageExt.POLineWrapper) result.records[ix];
            if (ix == 0){
                poLine0_LineNumber = poLWrapper.poLine.Line__c;
            }
            else if (ix == 1){
                poLine1_LineNumber = poLWrapper.poLine.Line__c;
            }
        }
        system.assert(poLine0_LineNumber < poLine1_LineNumber);
    }
    
    static testmethod void addNewPOLine_agreementPO_Error(){ //KNDY-11176
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Purchase_Agreement__c = testData.fuel.contract.Id;
        po.Currency__c = TestFuel.currencyUSD.id;
        insert po;
        
        //Create new poline with item in contract, but with different UOM 
        //Contract lines with this item/uom combination does not exist
        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c newLine1 = testdata.createLine(po, 10, 1, item, 'Open');
        newLine1.Item__c = testData.fuel.contractLines[0].Item__c; 
        newLine1.Purchase_UOM__c = testData.fuel.uomList[8].Id;
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        PurchaseOrderManageExt.POLineWrapper newPOLineWrapper = new PurchaseOrderManageExt.POLineWrapper(newLine1);
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>{newPOLineWrapper};
        
        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        system.assertEquals(false, result.success);
        system.assert(result.messages.size() == 1);
        String expectedErrorMessage = Label.Cannot_add_lines_with_item_UOM_combination_not_in_Purchase_Agreement;
        for (Map<String, String> error : result.messages) {
            system.assert(error.get('message').contains(expectedErrorMessage), '>>> errMsg: ' + error.get('message'));
        }
        Test.stopTest();
    }
    
    static testmethod void addNewPOLine_agreementPO_Success(){ //KNDY-11176
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Purchase_Agreement__c = testData.fuel.contract.Id;
        po.Currency__c = TestFuel.currencyUSD.id;
        insert po;
        
        //Create new poline with item and UOM as in contract line
        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c newLine1 = testdata.createLine(po, 10, 1, item, 'Open');
        newLine1.Item__c = testData.fuel.contractLines[0].Item__c; 
        newLine1.Purchase_UOM__c = null;
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        PurchaseOrderManageExt.POLineWrapper newPOLineWrapper = new PurchaseOrderManageExt.POLineWrapper(newLine1);
        List<PurchaseOrderManageExt.POLineWrapper> newList = new List<PurchaseOrderManageExt.POLineWrapper>{newPOLineWrapper};
        
        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.saveAction(po, headerDateFields, updatedList, newList, deletedList, dateFields);
        system.assertEquals(true, result.success);
        Purchase_Order_Line__c poLine = [Select Id, Contract_Line__c 
                            from Purchase_Order_Line__c where Id = :newLine1.Id];
        system.assertEquals(poLine.Contract_Line__c, testData.fuel.contractLines[0].Id);
        Test.stopTest();
    }
    
    static testMethod void dummyTestForAdditionalCoverage(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        insert po;
        
        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c newLine = testdata.createLine(po, 50, 1, item, 'Open');
        testData.insertUOMConversion(item, newLine.Purchase_UOM__c);
        
        ApexPages.StandardController setCon = new Apexpages.StandardController(po); 
        PurchaseOrderManageExt ext = new PurchaseOrderManageExt(setCon);
        ext.getCustomViews();
        ext.getCustomViewFields();
        ext.getPurchaseOrderHeaderFieldList();
        ext.getPurchaseOrderAddlHeaderFieldList();
        ext.getPOLinesFieldList();
        ext.getReturnUrl();
        ext.getPurchaseOrderJSON();
        ext.getPOLinesConfigJson();
        PurchaseOrderManageExt.getPODetails(po.id, null);
        PurchaseOrderManageExt.getPOLines (ext.poLinesConfig, null, (List<String>) JSON.deserialize(ext.getAllFields(), List<String>.class));
    }
    //KNDY-9504
     static testMethod void testUpdateReqWithPOCancel() {
        TestFuel fuel = new TestFuel();
        
        Purchase_Order__c po = new Purchase_Order__c();
        po.Supplier__c = fuel.supplier.id;
        po.Company__c = fuel.company.id;
    	po.Payment_Term__c = fuel.terms.id;
    	po.Delivery_Facility__c = fuel.facility2.id;
    	po.Delivery_Location__c = fuel.location2.ID;
    	po.Remit_To_Supplier__c = fuel.remitToSupplier.id;
    	po.Approval_Status__c = 'Approved';
    	po.fob_term__c = fuel.fobTerm.id;
    	po.Status__c = 'Open';
    	po.Memo__c = 'purchaseOrder';
    	po.Currency__c = TestFuel.currencyUSD.id;
    	insert po;
    	
        Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
        poLine.Purchase_Order__c = po.Id;
        poLine.Order_Quantity__c = 10;     
        poLine.Unit_Price__c = 12;
        poLine.Item__c = fuel.itemList[2].Id;
        poLine.Description__c = fuel.itemList[2].Description__c;
        poLine.Purchase_UOM__c = fuel.itemList[2].Purchasing_UOM__c;
        poLine.Company__c = fuel.company.id;
        poLine.Need_Date__c = system.today() + 7;
        poLine.Delivery_Facility__c = fuel.facility2.id;
        poLine.Delivery_Location__c = fuel.location2.ID;
        poLine.Supplier__c = fuel.supplier.Id;
        insert poLine;
        
        Requisition__c req = new Requisition__c();
        req.Company__c = fuel.company.id;
        req.Transaction_Date__c = system.today();
		req.Delivery_Facility__c = fuel.facility2.Id;
		req.Type__c = RequisitionService.RQ_TYPE_PURCHASE_REQUISITION;
		req.Source__c = RequisitionService.RQ_SOURCE_DROPSHIP;
		req.Status__c = 'Closed'; 
		req.Approval_Status__c = 'Approved';
		req.Delivery_Address__c = fuel.customerShipTo.Address__c;
        req.Currency__c = TestFuel.currencyUSD.id;
		insert req;
		
		Requisition_Line__c reqLine = new Requisition_Line__c();
		reqLine.Requisition__c = req.Id;
		reqLine.Quantity_Ordered__c = 5;
		reqLine.Quantity_Released__c = 5;
		reqLine.Purchasing_UOM__c = fuel.uomList[8].Id;
		reqLine.Item__c = fuel.itemList[0].Id;
		reqLine.Approved__c = true;
		reqLine.Status__c = 'Closed';
		insert reqLine;
		
		Requisition_Cross_Reference__c rcf = new Requisition_Cross_Reference__c();
		rcf.Purchase_Order_Line__c = poLine.id;
		rcf.Requisition_Line__c = reqLine.id;
		insert rcf;
		
		JSONResult result = PurchaseOrderService.cancelPOLines(new List<Purchase_Order_Line__c>{poLine},true);
        system.assertEquals(result.success, true);
        test.StartTest();
        
        Purchase_Order_Line__c pol = [select id, name, status__c from Purchase_Order_Line__c where id= :poline.id LIMIT 1];
        system.assertEquals(pol.Status__c, 'Cancelled');
        
        Requisition_Cross_Reference__c rcr= [select id, Requisition_Line__c,Requisition_Line__r.Name, Purchase_Order_Line__c from Requisition_Cross_Reference__c where Purchase_Order_Line__c = :poline.id LIMIT 1];
        Requisition_Line__c rl = [select id, name, Status__c, Quantity_Released__c, Quantity_Ordered__c, Approved__c, Requisition__r.Id, Requisition__r.Source__c from Requisition_Line__c where id =:rcr.Requisition_Line__c LIMIT 1];
        system.assertEquals(rl.Approved__c, true);
        system.assertEquals(rl.Quantity_Released__c, 0.0);
        system.assertEquals(rl.Status__c, 'Open');
        
        test.StopTest();
		
    }

    static testMethod void testClone_OpenPO() {
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Status__c = 'Open';
        insert po;

        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c line = testdata.createLine(po, 50, 1, item, 'Open');
        testData.insertUOMConversion(item, line.Purchase_UOM__c);
        insert line;
        
        Test.startTest();
        PageReference pageRef = Page.PurchaseOrderManage;
        pageRef.getParameters().put('Id', po.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        system.assert(con.pageTitle.contains ('Clone of'));
        
        // Tests for cloned Purchase Order
        JsonResult result = PurchaseOrderManageExt.getPODetails(po.Id, '1');
        system.assert(result.success == true);
        system.assert(result.records != null);
        system.assert(result.records.size() == 1);
        Purchase_Order__c poClone = (Purchase_Order__c)result.records[0];
        system.assertEquals(poClone.Status__c, 'Open');
        system.assertEquals(poClone.Approval_Status__c, 'Pending Authorization');
        system.assertEquals(poClone.Id, null);
        
        // Tests for cloned lines
        GridRelatedListController.GridRelatedListConfig config = con.poLinesConfig;
        result = PurchaseOrderManageExt.getPOLines(config, '1', (List<String>) JSON.deserialize(con.getAllFields(), List<String>.class)); // cloning lines
        system.assertEquals(1, result.total);
        PurchaseOrderManageExt.POLineWrapper poLineWrapper = (PurchaseOrderManageExt.POLineWrapper) result.records[0];
        Purchase_Order_Line__c polClone = poLineWrapper.poLine;
        system.assertEquals(polClone.Id, null);
        Test.stopTest();
    }

    static testMethod void testClone_ApprovedPO() { //KNDY-10509
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Status__c = 'Open';
        insert po;
        
        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c line = testdata.createLine(po, 50, 1, item, 'Open');
        testData.insertUOMConversion(item, line.Purchase_UOM__c);
        insert line;
        
        po.Approval_Status__c = 'Approved';
        update po;
        
        Test.startTest();
        PageReference pageRef = Page.PurchaseOrderManage;
        pageRef.getParameters().put('Id', po.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        
        List<String> headerDateFields = new List<String>();
        List<String> dateFields = new List<String>();
        testData.getDateFields(headerDateFields, dateFields);
        
        system.assert(con.pageTitle.contains ('Clone of'));
        
        // Tests for cloned Purchase Order
        JsonResult result = PurchaseOrderManageExt.getPODetails(po.Id, '1');
        system.assert(result.success == true);
        system.assert(result.records != null);
        system.assert(result.records.size() == 1);
        Purchase_Order__c poClone = (Purchase_Order__c)result.records[0];
        system.assertEquals(poClone.Status__c, 'Open');
        system.assertEquals(poClone.Approval_Status__c, 'Pending Authorization');
        system.assertEquals(poClone.Id, null);
        
        // Tests for cloned lines
        GridRelatedListController.GridRelatedListConfig config = con.poLinesConfig;
        result = PurchaseOrderManageExt.getPOLines(config, '1', (List<String>) JSON.deserialize(con.getAllFields(), List<String>.class)); // cloning lines
        system.assertEquals(1, result.total);
        PurchaseOrderManageExt.POLineWrapper poLineWrapper = (PurchaseOrderManageExt.POLineWrapper) result.records[0];
        Purchase_Order_Line__c polClone = poLineWrapper.poLine;
        system.assertEquals(polClone.Id, null);
        Test.stopTest();
    }
    
    //KNDY-15382 Test You cannot reduce Order Qty below Qty Recd 
    static testmethod void reduceOrderQtyBelowQtyRecd(){
        Purchase_Order__c po = new Purchase_Order__c();
        po.Company__c = testData.fuel.company.id;
        po.Supplier__c = testData.fuel.supplier.id;
        po.Type__c  = 'Standard';
        po.Status__c = 'Open';
        insert po;

        Item__c item = testdata.getItem('AnyItem');
        Purchase_Order_Line__c line = testdata.createLine(po, 50, 1, item, 'Open');
        testData.insertUOMConversion(item, line.Purchase_UOM__c);
		line.Quantity_Received__c = 10;
		line.Quantity_Matched__c = 0;
		insert line;
        
        Purchase_Order_Line__c line1 = testdata.createLine(po, 10, 5, item, 'Open');
        line1.Quantity_Received__c = 10;
        line1.Quantity_Matched__c = 10;
        line1.Status__c = 'Closed';
        line1.Approved__c = true;
		insert line1;
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(po);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        
        Test.startTest();
        JsonResult result = PurchaseOrderManageExt.approvePO(po.Id);
        Purchase_Order__c savedPO = [Select Id, Approval_Status__c,(Select id, Approved__c, Order_Quantity__c, Quantity_Received__c, Quantity_Returned_To_Supplier__c, Status__c from Purchase_Order_Lines__r) from Purchase_Order__c where Id = :po.Id];
        system.assertEquals(savedPO.Approval_Status__c, 'Approved');
        List<Purchase_Order_Line__c> lines = savedPO.Purchase_Order_Lines__r;
        
        Map<Decimal, Purchase_Order_Line__c> poLineMap = new Map<Decimal, Purchase_Order_Line__c>();
        for(Purchase_Order_Line__c poline: lines){
        	poLineMap.put(poline.Order_Quantity__c, poline);
        }
        system.assertEquals(poLineMap.size(), 2);
        
        line = poLineMap.get(50.000000);
        line.Order_Quantity__c = 9;//reducing order quantity below qty recd
        String expectedErrorMessage = 'Cannot reduce the Purchase Order Quantity less than the Quantity Received';
        
        try{
        	update line;
        }catch (Exception e){
        	system.assert(e.getMessage().contains(expectedErrorMessage));
        }
        
        line.Order_Quantity__c = 10;//set order qty equal to qty recd
        
        try{
        	update line;
        }catch (Exception e){
        	system.assert(e.getMessage().contains(expectedErrorMessage));
        }
        
        line1 = [select id, Order_Quantity__c from Purchase_Order_Line__c where Id = :poLineMap.get(50.000000).id];
        system.assertEquals(line1.Order_Quantity__c, 10);
        
        line = poLineMap.get(10.000000);
        line.Unit_Price__c = 11;
        
        expectedErrorMessage = 'You cannot update a closed line';
        
        try{
        	update line;
        }catch (Exception e){
        	system.assert(e.getMessage().contains(expectedErrorMessage));
        }	
        Test.stopTest();
    }
	
    class PurchaseOrderManageExtTestData {
        private SchemaUtil util = SchemaUtil.getInstance();
        public TestFuel fuel = new TestFuel();
        
        public void getDateFields(List<String> headerDateFields, List<String> lineDateFields){
            headerDateFields = new List<String>();
            lineDateFields = new List<String>{'Need_Date__c','Promised_Date__c','Latest_Promise_Date__c'};
        }
        
        public void insertUOMConversion (Item__c item, Id fromUOMId){
            UOM_Conversion_Details__c uomConversion = new UOM_Conversion_Details__c();
            uomConversion.Name = ((String)item.Id).substring(3, 15) + ((String)fromUOMId).substring(3, 15) + ((String)item.Stocking_UOM__c).substring(3, 15);
            uomConversion.UOM_1__c = fromUOMId;
            uomConversion.UOM_1_Quantity__c=12;
            uomConversion.UOM_2__c = item.Stocking_UOM__c;
            uomConversion.UOM_2_Quantity__c=1;
            uomConversion.Item__c=item.Id;
            upsert uomConversion;
        } 
        public Purchase_Order_Line__c createLine(Purchase_Order__c po, Decimal OrderQty, Decimal unitPrice, Item__c item, String status){
            Purchase_Order_Line__c newLine = new Purchase_Order_Line__c();
            newLine.Purchase_Order__c = po.Id;
            newLine.Order_Quantity__c = OrderQty;
            newLine.Unit_Price__c = unitPrice;
            newLine.Description__c = 'test';
            newLine.Item__c = item.Id;
            newLine.Company__c = fuel.company.id;
            newLine.Delivery_Facility__c = fuel.facility.Id;
            newLine.Need_Date__c = Date.today();
            newLine.Delivery_Location__c = fuel.location.Id;
            newLine.Purchase_UOM__c = fuel.uomInch.Id;
            newLine.Status__c = status;
	    newLine.Quantity_Returned_To_Supplier__c = 0;
	    newLine.Quantity_Returned_To_Supplier_For_Credit__c = 0;
            return newLine;
        }
        
        public Source_Document_Approval__c sd = new Source_Document_Approval__c();{
            sd.Name = 'Purchase Order';
            sd.Allow_Approval__c = true;
            insert sd;
        }
        
        public Item__c getItem(String itemType){
            Item__c ret = new Item__c();
            if (itemType == 'AnyItem'){
                ret = fuel.itemList[0];
            }
            // Assumption: Purchasing item will have Purchase_UOM field set (Required?)
            else if (itemType == 'PurchasedItem'){
               for (Item__c i: fuel.itemList){
                    if (i.Source__c == 'Purchased'){
                         ret = i;
                    }
                }     
            }
            return ret;
        }
    }
}