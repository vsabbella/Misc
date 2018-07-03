/**
 * Test methods for KendoUtils class
 */
@isTest
private class KendoUtilsTest {
	static TestFuel fuel = new TestFuel();
    
    static testMethod void testUpdateDateFields(){
        Test.startTest();
        
        // Arrange
        Purchase_Order__c po = fuel.purchaseOrder;
        List<String> dateFields = new List<String> { 'Order_Date__c' };
        Date orderDate = Datetime.newInstance(0).dateGMT();
        
        po.Order_Date__c = orderDate;
        
        // Act
        KendoUtils.UpdateDateFields(po, dateFields);
        
        // Assert
        System.assertNotEquals(orderDate, po.Order_Date__c);
        
        Test.stopTest();
    }
    
    // This method is obsolete and no longer being used
    /*
    static testMethod void testSerialize(){
        Test.startTest();
        
        // Arrange
        Purchase_Order__c po = fuel.purchaseOrder;
        
        // Act
        String resultJson = KendoUtils.Serialize(po);
        Purchase_Order__c resultPo = (Purchase_Order__c) JSON.deserialize(resultJson, Purchase_Order__c.class);
                
        // Assert
        System.assertEquals(resultPo.Status__c, po.Status__c);
        System.assertEquals(resultPo.Approval_Status__c, po.Approval_Status__c);
        
        Test.stopTest();
    }*/
    
    static testMethod void testGetFilterCriteria(){
        Test.startTest();
        
        // Arrange
        List<KendoUtils.FilterDescriptor> filtersList = new List<KendoUtils.FilterDescriptor>();
        
        String approvalStatusEqualsApproved = 'approval_status__c = \'approved\'';
        
        KendoUtils.FilterDescriptor equalsTestFilter = new KendoUtils.FilterDescriptor();
        equalsTestFilter.field = 'Approval_Status__c';
        equalsTestFilter.fieldType = 'string';
        equalsTestFilter.value = 'Approved';
        equalsTestFilter.operator = 'eq';
        
        filtersList.add(equalsTestFilter);
        
        String approvalStatusNotEqualsApproved = 'approval_status__c != \'approved\'';
        
        KendoUtils.FilterDescriptor notEqualsTestFilter = new KendoUtils.FilterDescriptor();
        notEqualsTestFilter.field = 'Approval_Status__c';
        notEqualsTestFilter.fieldType = 'string';
        notEqualsTestFilter.value = 'Approved';
        notEqualsTestFilter.operator = 'neq';
        
        filtersList.add(notEqualsTestFilter);
        
        String approvalStatusContainsApproved = 'approval_status__c like \'%approved%\'';
        
        KendoUtils.FilterDescriptor containsTestFilter = new KendoUtils.FilterDescriptor();
        containsTestFilter.field = 'Approval_Status__c';
        containsTestFilter.fieldType = 'string';
        containsTestFilter.value = 'Approved';
        containsTestFilter.operator = 'contains';
        
        filtersList.add(containsTestFilter);
        
        String approvalStatusDoesNotContainApproved = '(not (approval_status__c like \'%approved%\'))';
        
        KendoUtils.FilterDescriptor doesNotContainTestFilter = new KendoUtils.FilterDescriptor();
        doesNotContainTestFilter.field = 'Approval_Status__c';
        doesNotContainTestFilter.fieldType = 'string';
        doesNotContainTestFilter.value = 'Approved';
        doesNotContainTestFilter.operator = 'doesnotcontain';
        
        filtersList.add(doesNotContainTestFilter);
        
        String quantityGreaterThanZero = 'quantity__c > 0';
        
        KendoUtils.FilterDescriptor greaterThanTestFilter = new KendoUtils.FilterDescriptor();
        greaterThanTestFilter.field = 'Quantity__c';
        greaterThanTestFilter.fieldType = 'integer';
        greaterThanTestFilter.value = 0;
        greaterThanTestFilter.operator = 'gt';
        
        filtersList.add(greaterThanTestFilter);
        
        String quantityLessThanZero = 'quantity__c < 0';
        
        KendoUtils.FilterDescriptor lessThanTestFilter = new KendoUtils.FilterDescriptor();
        lessThanTestFilter.field = 'Quantity__c';
        lessThanTestFilter.fieldType = 'integer';
        lessThanTestFilter.value = 0;
        lessThanTestFilter.operator = 'lt';
        
        filtersList.add(lessThanTestFilter);
        
        String quantityGreaterThanEqualsZero = 'quantity__c >= 0';
        
        KendoUtils.FilterDescriptor greaterThanEqualsTestFilter = new KendoUtils.FilterDescriptor();
        greaterThanEqualsTestFilter.field = 'Quantity__c';
        greaterThanEqualsTestFilter.fieldType = 'integer';
        greaterThanEqualsTestFilter.value = 0;
        greaterThanEqualsTestFilter.operator = 'gte';
        
        filtersList.add(greaterThanEqualsTestFilter);
        
        String quantityLessThanEqualsZero = 'quantity__c <= 0';
        
        KendoUtils.FilterDescriptor lessThanEqualsTestFilter = new KendoUtils.FilterDescriptor();
        lessThanEqualsTestFilter.field = 'Quantity__c';
        lessThanEqualsTestFilter.fieldType = 'integer';
        lessThanEqualsTestFilter.value = 0;
        lessThanEqualsTestFilter.operator = 'lte';
        
        filtersList.add(lessThanEqualsTestFilter);
        
        DateTime dtMtd = system.today().toStartOfMonth();
        String transactionDateMonthToDate = 'transaction_date__c >= ' + dtMtd.format('yyyy-MM-dd\'t\'HH:mm:ss\'z\'', 'GMT') + ' and transaction_date__c <= today';
        
        KendoUtils.FilterDescriptor monthToDateTestFilter = new KendoUtils.FilterDescriptor();
        monthToDateTestFilter.field = 'Transaction_Date__c';
        monthToDateTestFilter.fieldType = 'datetime';
        monthToDateTestFilter.operator = 'mtd';
        
        filtersList.add(monthToDateTestFilter);
        
        DateTime dtYtd = Date.newinstance(system.today().year(), 1, 1);
        String transactionDateYearToDate = 'transaction_date__c >= ' + dtYtd.format('yyyy-MM-dd\'t\'HH:mm:ss\'z\'', 'GMT') + ' and transaction_date__c <= today';
        
        KendoUtils.FilterDescriptor yearToDateTestFilter = new KendoUtils.FilterDescriptor();
        yearToDateTestFilter.field = 'Transaction_Date__c';
        yearToDateTestFilter.fieldType = 'datetime';
        yearToDateTestFilter.operator = 'ytd';
        
        filtersList.add(yearToDateTestFilter);
        
        DateTime dtFmtd = system.today().toStartOfMonth();
        String transactionDateFiscalMonthToDate = 'transaction_date__c >= ' + dtFmtd.format('yyyy-MM-dd\'t\'HH:mm:ss\'z\'', 'GMT') + ' and transaction_date__c <= today';
        
        KendoUtils.FilterDescriptor fiscalMonthToDateTestFilter = new KendoUtils.FilterDescriptor();
        fiscalMonthToDateTestFilter.field = 'Transaction_Date__c';
        fiscalMonthToDateTestFilter.fieldType = 'datetime';
        fiscalMonthToDateTestFilter.operator = 'fmtd';
        
        filtersList.add(fiscalMonthToDateTestFilter);
        
        DateTime dtFytd = Date.newinstance(system.today().year(), 1, 1);
        String transactionDateFiscalYearToDate = 'transaction_date__c >= ' + dtFytd.format('yyyy-MM-dd\'t\'HH:mm:ss\'z\'', 'GMT') + ' and transaction_date__c <= today';
        
        KendoUtils.FilterDescriptor fiscalYearToDateTestFilter = new KendoUtils.FilterDescriptor();
        fiscalYearToDateTestFilter.field = 'Transaction_Date__c';
        fiscalYearToDateTestFilter.fieldType = 'datetime';
        fiscalYearToDateTestFilter.operator = 'fytd';
        
        filtersList.add(fiscalYearToDateTestFilter);
        
        String statusContains = 'status__c in (\'open\',\'closed\')';
        
        KendoUtils.FilterDescriptor statusContainsTestFilter = new KendoUtils.FilterDescriptor();
        statusContainsTestFilter.field = 'Status__c';
        statusContainsTestFilter.fieldType = 'list';
        statusContainsTestFilter.value = '["open", "closed"]';
        statusContainsTestFilter.operator = 'contains';
        
        filtersList.add(statusContainsTestFilter);
        
        String statusDoesNotContains = '(not (status__c in (\'open\',\'closed\')))';
        
        KendoUtils.FilterDescriptor statusDoesNotContainTestFilter = new KendoUtils.FilterDescriptor();
        statusDoesNotContainTestFilter.field = 'Status__c';
        statusDoesNotContainTestFilter.fieldType = 'list';
        statusDoesNotContainTestFilter.value = '["open", "closed"]';
        statusDoesNotContainTestFilter.operator = 'doesnotcontain';
        
        filtersList.add(statusDoesNotContainTestFilter);
        
        DateTime dtFrom = system.today().toStartOfMonth();
        DateTime dtTo = system.today();
        String transactionDateBetween = 'transaction_date__c >= ' + dtFrom.format('yyyy-MM-dd') + ' and transaction_date__c <= ' + dtTo.format('yyyy-MM-dd');
        
        KendoUtils.FilterDescriptor betweenTestFilter = new KendoUtils.FilterDescriptor();
        betweenTestFilter.field = 'Transaction_Date__c';
        betweenTestFilter.fieldType = 'date';
        betweenTestFilter.value = '["' + dtFrom.format('MM/dd/yyy') + '", "' + dtTo.format('MM/dd/yyy') + '"]';
        betweenTestFilter.operator = 'between';
        
        filtersList.add(betweenTestFilter);
        
        // Act
        List<String> result = KendoUtils.getFilterCriteria(filtersList);

        // Assert
        System.assertEquals(approvalStatusEqualsApproved, result[0].toLowerCase());
        System.assertEquals(approvalStatusNotEqualsApproved, result[1].toLowerCase());
        System.assertEquals(approvalStatusContainsApproved, result[2].toLowerCase());
        System.assertEquals(approvalStatusDoesNotContainApproved, result[3].toLowerCase());
        System.assertEquals(quantityGreaterThanZero, result[4].toLowerCase());
        System.assertEquals(quantityLessThanZero, result[5].toLowerCase());
        System.assertEquals(quantityGreaterThanEqualsZero, result[6].toLowerCase());
        System.assertEquals(quantityLessThanEqualsZero, result[7].toLowerCase());
        System.assertEquals(transactionDateMonthToDate, result[8].toLowerCase());
        System.assertEquals(transactionDateYearToDate, result[9].toLowerCase());
        System.assertEquals(transactionDateFiscalMonthToDate, result[10].toLowerCase());
        System.assertEquals(transactionDateFiscalYearToDate, result[11].toLowerCase());
        System.assertEquals(statusContains, result[12].toLowerCase());
        System.assertEquals(statusDoesNotContains, result[13].toLowerCase());
        System.assertEquals(transactionDateBetween, result[14].toLowerCase());
        
        Test.stopTest();
    }
}