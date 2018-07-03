@isTest
private class AllocationRuleKndy2132Test {
    
    // This test class is written in huge time crunch, quality of this test case beyond coverage could be certainly done 
    // in free time later 
  
    // tests if Extension basics are working correctly with validations etc
  testMethod static void testBasicSetup() {

        TestFuel fuel = new TestFuel();
        // accessing it before Test.startTest() to make sure limits are not consumed later 
        Customer__c custShipTo = fuel.customerShipTo; 
        
        Test.startTest();
        //
        // Simple checks 
        //
        
        // Sequence number generation
        //Long seqNo = AllocationRuleManagementExt.getBiggestNextSequenceNumber();
       // System.assertEquals(1, seqNo, 'No Allocation Rule data, so sequence should start from 1');
        
        AllocationRuleManagementExt ext;
        
        ext = new AllocationRuleManagementExt(new ApexPages.StandardController(new Product__c()) );
        System.assert(ExceptionService.hasErrors, 'Expected errors: In memory product should not work with extension');
        
        ExceptionService.messages.clear();
        ext = new AllocationRuleManagementExt(new ApexPages.StandardController(fuel.product) );
        
        // Test fetching of Corp Customer RecordTypeId
        Id corpCustomerRecordTypeId;
        // positive test : a valid id should come back
        corpCustomerRecordTypeId =  ext.getCorpCustomerRecordTypeId();
        System.assertNotEquals(null, corpCustomerRecordTypeId, AllocationRuleManagementExt.CorpCustomerRecordTypeName + ' record type missing for Sobject Customer');
        
        // backup this one to restore after negative test
        String orignalCorpCustomerRecordTypeName = AllocationRuleManagementExt.CorpCustomerRecordTypeName;
        AllocationRuleManagementExt.CorpCustomerRecordTypeName = '232323sdsdsdsdsdsdsdvxcve'; // some really odd recordtype name to enter negative scenario
        // should fail
        try {
            corpCustomerRecordTypeId =  ext.getCorpCustomerRecordTypeId();    
            System.assert(false, 'Should fail as Customer record type name : ' +  AllocationRuleManagementExt.CorpCustomerRecordTypeName +  ' is not valid');
        } catch (Exception ex) {
            // Expected here
        }
        // restore this back to assure normal functioning 
        AllocationRuleManagementExt.CorpCustomerRecordTypeName = orignalCorpCustomerRecordTypeName;
        
        // Default dates being generated
        System.assertEquals(KSE.NamespaceUU, ext.getNamespacePrefix());
        
        System.assertNotEquals(null, ext.getDefaultFieldInfos());
        
        // Create sample filter data
        AllocationRuleManagementExt.FilterInfo filterInfo = new AllocationRuleManagementExt.FilterInfo();
        filterInfo.productId = fuel.product.Id;
		filterInfo.companyId = fuel.company.Id; 
		filterInfo.suggestedName = 'M-1'; 
		filterInfo.showWarningsForExistingRules = true;
        
        try {
            filterInfo.parse();    
            System.assert(false, 'Bad configuration should make it fail as from/to dates are missing');
        } catch (Exception ex) {
            // normal    
        }
        
        Test.stopTest();
    }
    
    
    // tests if extension creates new rule correctly
    testMethod static void testNewRule() {	

        TestFuel fuel = new TestFuel();
        // accessing it before Test.startTest() to make sure limits are not consumed later 
        Customer__c custShipTo = fuel.customerShipTo;
        
        Test.startTest();
        AllocationRuleManagementExt.AllocationRule ar;
        
        // Rule in current or past date can't be edited
        Datetime fromDatetime = System.now().addDays(1);
        // test FB rule filters
        
         // Create sample filter data
        AllocationRuleManagementExt.FilterInfo filterInfo = new AllocationRuleManagementExt.FilterInfo();
        filterInfo.productId = fuel.product.Id;
		filterInfo.companyId = fuel.company.Id; 
		filterInfo.suggestedName = 'FB-1'; 
		filterInfo.showWarningsForExistingRules = true;
		filterInfo.fromDateMillis = fromDatetime.getTime();
		filterInfo.toDateMillis = fromDatetime.addDays(6).getTime();
		filterInfo.histFromDateMillis = fromDatetime.addYears(-1).getTime();
		filterInfo.histToDateMillis = fromDatetime.addYears(-1).addDays(6).getTime();
        filterInfo.ruleType = AllocationRuleManagementExt.TYPE_PICKVAL_FB.getValue();
        
        // generate a rule instance of type FB
        ar = AllocationRuleManagementExt.newRule(filterInfo);
        System.assertEquals(AllocationRuleManagementExt.TYPE_PICKVAL_FB.getValue(), ar.sobj.Type__c, 'Rule type should be FB');
//        System.assertEquals(fromDatetime.getTime(), ar.fromDatetime , 'Rule should be created with correct dates');

        // try new rule with HFS rule type
        filterInfo.ruleType = AllocationRuleManagementExt.TYPE_PICKVAL_HFS.getValue();
        ar = AllocationRuleManagementExt.newRule(filterInfo);
        System.assertEquals(AllocationRuleManagementExt.TYPE_PICKVAL_HFS.getValue(), ar.sobj.Type__c, 'Rule type should be HFS');
                
        // test new rule with M rule type
		filterInfo.ruleType = AllocationRuleManagementExt.TYPE_PICKVAL_M.getValue();
        ar = AllocationRuleManagementExt.newRule(filterInfo);
        System.assertEquals(AllocationRuleManagementExt.TYPE_PICKVAL_M.getValue(), ar.sobj.Type__c, 'Rule type should be Manual');
        
        Test.stopTest();
    }
    
    
    // tests if extension creates save rule correctly and checks for overlaps
    testMethod static void testSaveRule() {

        TestFuel fuel = new TestFuel();
        // accessing it before Test.startTest() to make sure limits are not consumed later 
        Customer__c custShipTo = fuel.customerShipTo;
        
        Test.startTest();
        AllocationRuleManagementExt.AllocationRule ar;
        
        // Rule in current or past date can't be edited
        Datetime fromDatetime = System.now().addDays(1);
        // test FB rule filters
        
        AllocationRuleManagementExt.FilterInfo filterInfo = new AllocationRuleManagementExt.FilterInfo();
        filterInfo.productId = fuel.product.Id;
		filterInfo.companyId = fuel.company.Id; 
		filterInfo.suggestedName = 'FB-1'; 
		filterInfo.showWarningsForExistingRules = true;
		filterInfo.fromDateMillis = fromDatetime.getTime();
		filterInfo.toDateMillis = fromDatetime.addDays(6).getTime();
		filterInfo.histFromDateMillis = fromDatetime.addYears(-1).getTime();
		filterInfo.histToDateMillis = fromDatetime.addYears(-1).addDays(6).getTime();
		filterInfo.ruleType = AllocationRuleManagementExt.TYPE_PICKVAL_HFS.getValue();
		
        JSONResult loadRuleResult = AllocationRuleManagementExt.loadRules(filterInfo);
        
        // No rule so new one should be auto generated
        List<AllocationRuleManagementExt.AllocationRule> hfsRules = new List<AllocationRuleManagementExt.AllocationRule>();
        for(Object arule : loadRuleResult.records){
        	AllocationRuleManagementExt.AllocationRule arule1 = (AllocationRuleManagementExt.AllocationRule) arule;
        	arule1.sobj.Customer__c = fuel.customerparent.Id;
        	arule1.sobj.Facility__c = fuel.facility.id;
        	hfsRules.add(arule1);
        }
        
        System.assert(loadRuleResult.success, 'No existing rules should be there, as its a clean slate as of now');
        System.assertEquals(1, hfsRules.size());
        
        // save rule to db
        JsonResult result = AllocationRuleManagementExt.saveRules(new AllocationRuleManagementExt.AllocationRule[] {}, hfsRules,
                                            new AllocationRuleManagementExt.AllocationRule[] {}, new String[]{});
        System.assert(result.success, 'This is the only rule with good data should go thru');
        // Handle to the hfs rule 
        AllocationRuleManagementExt.AllocationRule hfsRule = hfsRules[0];

        
        // Load rules in wider date range and see if the above HFS rule loads up
		filterInfo.toDateMillis = fromDatetime.addMonths(2).getTime();
		filterInfo.ruleType = AllocationRuleManagementExt.TYPE_PICKVAL_M.getValue();
        // reload the rules
        loadRuleResult = AllocationRuleManagementExt.loadRules(filterInfo);
        
        // Direct typecasting between list does not work.
        AllocationRuleManagementExt.AllocationRule[] manualRules = new List<AllocationRuleManagementExt.AllocationRule>(); 
        for(Object arule : loadRuleResult.records){
        	manualRules.add((AllocationRuleManagementExt.AllocationRule) arule);
        }
        
        // one of the previously created HFS rule should come this time
        System.assertEquals(1, manualRules.size());
        // Match the ids
        System.assertEquals(hfsRule.sobj.Id, manualRules[0].sobj.Id);
        System.assert(!loadRuleResult.messages.isEmpty(), 'Should have message for overlapping rules');
        System.assert(loadRuleResult.success == false, 'Should find the previously created HFS rule');
        
        // Force save overlapping rule, to check triggers that will make the save crash
        ar = AllocationRuleManagementExt.newRule(filterInfo);
        ar.sobj.Allocation__c = 100;
        result = AllocationRuleManagementExt.saveRules(new AllocationRuleManagementExt.AllocationRule[] {}, 
                                            new AllocationRuleManagementExt.AllocationRule[]{ar},
                                            new AllocationRuleManagementExt.AllocationRule[] {}, new String[]{});
        
        System.assert(result.success == false, 'Overlapping rule should make it fail');
        
               
        Test.stopTest();       
    }
    
    // Loads rules, checks if used allocation is calculated correctly for the same.
    testMethod static void testRuleWithUsedAllocation() {
        TestFuel fuel = new TestFuel();
        // accessing it before Test.startTest() to make sure limits are not consumed later 
        Customer__c custShipTo = fuel.customerShipTo;
        fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
        Sales_Order__c salesOrder1YearBack = new Sales_Order__c();
        salesOrder1YearBack.Company__c = fuel.company.id;
        salesOrder1YearBack.Customer__c = fuel.customerSoldTo.id;   
        salesOrder1YearBack.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder1YearBack.Payment_Term__c = fuel.terms.id;
        salesOrder1YearBack.Date_Time_Ordered__c = System.today().addYears(-1).addDays(2); // in last year
        
        Sales_Order__c salesOrderCurrent = new Sales_Order__c();
        salesOrderCurrent.Company__c = fuel.company.id;
        salesOrderCurrent.Customer__c = fuel.customerSoldTo.id;   
        salesOrderCurrent.Ship_To__c = fuel.customerShipTo.Id;
        salesOrderCurrent.Payment_Term__c = fuel.terms.id;
        salesOrderCurrent.Date_Time_Ordered__c = System.today().addDays(2); // in current year
        
        insert new Sales_Order__c[] { salesOrder1YearBack, salesOrderCurrent };
        
        List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>();
        // Last year SO Lines
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder1YearBack.Id;
        salesOrderLine.Quantity_Ordered__c = 4;
        salesOrderLine.Required_Date__c = System.today() + 10; //passed the Allocation Rule date
        salesOrderLine.Ship_From_Location__c = fuel.location.Id;
        soLines.add(salesOrderLine);
        // 2nd line
        salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder1YearBack.Id;
        salesOrderLine.Quantity_Ordered__c = 6;
        salesOrderLine.Required_Date__c = System.today() + 10; //passed the Allocation Rule date
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id; // another location > facilty to split allocation 
        soLines.add(salesOrderLine);
        
        // Current year SO Lines
        salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrderCurrent.Id;
        salesOrderLine.Quantity_Ordered__c = 30;
        salesOrderLine.Required_Date__c = System.today().addDays(1) ;
        salesOrderLine.Ship_From_Location__c = fuel.location.Id;
        soLines.add(salesOrderLine);
        
        // 2nd line
        salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrderCurrent.Id;
        salesOrderLine.Quantity_Ordered__c = 50;
        salesOrderLine.Required_Date__c = System.today().addDays(1) ;
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
        soLines.add(salesOrderLine);
        
        insert soLines;
        
        
        Shipment__c shipment1 = new Shipment__c();
	    shipment1.Company__c = fuel.company.id;
	    shipment1.Date_Shipped__c = system.now().addYears(-1).addDays(2);
	    shipment1.Currency__c = TestFuel.currencyUSD.id;
	    shipment1.Customer__c = fuel.customerShipTo.Id;
	    insert shipment1; 
        
	    List<Shipment_Line__c> shipLineList1 = new List<Shipment_Line__c>();
	    Shipment_Line__c shipLine1 = new Shipment_Line__c();
	    shipLine1.Company__c = fuel.company.id;
	    shipLine1.Extended_Cost__c = 5;
        shipLine1.Quantity_Planned__c = 4;
        shipLine1.Quantity_Allocated__c = 0;
        shipLine1.Quantity_To_Pick__c = 0;
        shipLine1.Quantity_Picked__c = 0;
	    shipLine1.Quantity_Shipped__c = 4;
	    shipLine1.Sales_Order__c = salesOrder1YearBack.id;
	    shipLine1.Sales_Order_Line__c = soLines[0].id;
	    shipLine1.Unit_Price__c = 25;
        shipLine1.Item__c = fuel.product.Item__c;
	    shipLine1.Product__c = fuel.product.id;
	    shipLine1.Location__c = fuel.location.id;
	    shipLine1.Shipment__c = shipment1.id;
	    shipLineList1.add(shipLine1);
        
	    Shipment_Line__c shipLine2 = new Shipment_Line__c();
	    shipLine2.Company__c = fuel.company.id;
	    shipLine2.Extended_Cost__c = 5;
        shipLine2.Quantity_Planned__c = 6;
        shipLine2.Quantity_Allocated__c = 0;
        shipLine2.Quantity_To_Pick__c = 0;
        shipLine2.Quantity_Picked__c = 0;
	    shipLine2.Quantity_Shipped__c = 6;
	    shipLine2.Sales_Order__c = salesOrder1YearBack.id;
	    shipLine2.Sales_Order_Line__c = soLines[1].id;
	    shipLine2.Unit_Price__c = 25;
        shipLine2.Item__c = fuel.product.Item__c;
	    shipLine2.Product__c = fuel.product.id;
	    shipLine2.Location__c = fuel.location2.id;
	    shipLine2.Shipment__c = shipment1.id;
	    shipLineList1.add(shipLine2);
	    insert shipLineList1;
        
	    shipment1.Status__c = 'Confirmed';
	    shipment1.Finalized__c = true;
	    update shipment1;
        
        
        Test.startTest();
        AllocationRuleManagementExt.AllocationRule ar;
        
        // Rule in current or past date can't be edited
        Datetime fromDatetime = System.now().addDays(1);
        // test FB rule filters
        
        AllocationRuleManagementExt.FilterInfo filterInfo = new AllocationRuleManagementExt.FilterInfo();
        filterInfo.productId = fuel.product.Id;
		filterInfo.companyId = fuel.company.Id; 
		filterInfo.suggestedName = 'FB-1'; 
		filterInfo.showWarningsForExistingRules = true;
		filterInfo.fromDateMillis = fromDatetime.getTime();
		filterInfo.toDateMillis = fromDatetime.addDays(6).getTime();
		filterInfo.histFromDateMillis = fromDatetime.addYears(-1).getTime();
		filterInfo.histToDateMillis = fromDatetime.addYears(-1).addDays(6).getTime();
		
		JSONResult loadRuleResult;
        AllocationRuleManagementExt.AllocationRule facility1Rule, facility2Rule;

		
        // Test Manual rules        
		filterInfo.ruleType = AllocationRuleManagementExt.TYPE_PICKVAL_M.getValue();
        loadRuleResult = AllocationRuleManagementExt.loadRules(filterInfo);
        
        // Direct typecasting between list does not work.
        AllocationRuleManagementExt.AllocationRule[] manualRules = new List<AllocationRuleManagementExt.AllocationRule>(); 
        for(Object arule : loadRuleResult.records){
        	manualRules.add((AllocationRuleManagementExt.AllocationRule) arule);
        }
        
        System.assertEquals(1, manualRules.size());
        
		// Test HFS Rule loading, quantityToAllocate must be evenly distributed
		filterInfo.quantityToAllocate = 100;
		filterInfo.ruleType = AllocationRuleManagementExt.TYPE_PICKVAL_HFS.getValue();
        loadRuleResult = AllocationRuleManagementExt.loadRules(filterInfo);
        
        // No rule so new one should be auto generated
        List<AllocationRuleManagementExt.AllocationRule> hfsRules = new List<AllocationRuleManagementExt.AllocationRule>();
        for(Object arule : loadRuleResult.records){
        	hfsRules.add((AllocationRuleManagementExt.AllocationRule) arule);
        }
        
        System.assert(loadRuleResult.success, 'No existing rules should be there, as its a clean slate as of now');
        System.assertEquals(2, hfsRules.size());
        
        for (AllocationRuleManagementExt.AllocationRule har : hfsRules) {
            if (har.sobj.Facility__c == fuel.facility.id) {
                facility1Rule = har;
            } else if (har.sobj.Facility__c == fuel.facility2.id) {
                facility2Rule = har;
            }
        }
        
        System.assertEquals(40, facility1Rule.sobj.Allocation__c);
        System.assertEquals(60, facility2Rule.sobj.Allocation__c);
        
        // save rule to db
        JsonResult result = AllocationRuleManagementExt.saveRules(new AllocationRuleManagementExt.AllocationRule[] {}, hfsRules,
                                            new AllocationRuleManagementExt.AllocationRule[] {}, new String[]{});
        System.assert(result.success, 'This is the only rule with good data should go thru');
        
        Allocation_Rule__c[] rulesFrmDb = [Select Id, Start_date__c, End_date__c, Allocation__c, Allocation_Used__c, Facility__c from Allocation_Rule__c];

        //System.debug (LoggingLevel.INFO, rulesFrmDb);
        Allocation_Rule__c ruleForFacility1, ruleForFacility2;
        
        for (Allocation_Rule__c rule : rulesFrmDb) {
            if (rule.Facility__c == fuel.facility.id) {
                ruleForFacility1 = rule;
            } else if (rule.Facility__c == fuel.facility2.id) {
                ruleForFacility2 = rule;
            }
        }
        
        System.assertEquals(30, ruleForFacility1.Allocation_Used__c);
        System.assertEquals(50, ruleForFacility2.Allocation_Used__c);
        
        //(Allocation_Rule__c:{Allocation_Used__c=30.000000, Allocation__c=40.000000, Id=a06b000000k9GnmAAE, Facility__c=a0cb00000018asZAAQ}, 
        //Allocation_Rule__c:{Allocation_Used__c=50.000000, Allocation__c=60.000000, Id=a06b000000k9GnnAAE, Facility__c=a0cb00000018asaAAA})
        
        SalesOrderService.AllocationRuleValidationRunning = false;
        
        // Add 2 more lines with 20 each to test cutting
        soLines = new List<Sales_Order_Line__c>();
        Sales_Order_Line__c solC3 = new Sales_Order_Line__c();
        solC3.Product__c = fuel.product.Id;
        solC3.Description__c = fuel.product.Description__c;
        solC3.Company__c = fuel.company.id;
        solC3.Sales_Order__c = salesOrderCurrent.Id;
        solC3.Quantity_Ordered__c = 80;
        solC3.Required_Date__c = System.today() + 5;
        solC3.Ship_From_Location__c = fuel.location.Id;
        soLines.add(solC3);
        // 2nd line
        Sales_Order_Line__c solC4 = new Sales_Order_Line__c();
        solC4.Product__c = fuel.product.Id;
        solC4.Description__c = fuel.product.Description__c;
        solC4.Company__c = fuel.company.id;
        solC4.Sales_Order__c = salesOrderCurrent.Id;
        solC4.Quantity_Ordered__c = 80;
        solC4.Required_Date__c = System.today() + 5;
        solC4.Ship_From_Location__c = fuel.location2.Id;
        soLines.add(solC4);
        
        insert soLines;
        // Future method called in above insert, end it here
        Test.stopTest();   
        
        Map<Id, Sales_Order_Line__c> allSOLines = new Map<Id, Sales_Order_Line__c>([Select id, Quantity_Ordered__c, Required_Date__c, Estimated_ship_date__c, Ship_From_Location__r.Facility__c From Sales_Order_Line__c]);
        
        //system.debug(LoggingLevel.info, allSOLines);
        //system.debug(LoggingLevel.info, [Select Id, Start_date__c, End_date__c, Allocation__c, Allocation_Used__c, Facility__c from Allocation_Rule__c]);

        System.assertEquals(6, allSOLines.size());
        Task[] exceptionTasks = ExceptionService.fetchTasks(allSOLines.keySet(), ExceptionUtil.SO_LINE_ALLOCATION_EXCEPTION.code, TaskType.EXCEPTION_STATUS_OPEN);

        //System.assertEquals(2, exceptionTasks.size(), 'Two of the so lines should get adjusted');            
    }   
    
     testMethod static  void testAllocationUsed() {
        TestFuel fuel = new TestFuel();
         
        Allocation_Rule__c allocationRule = new Allocation_Rule__c(
        										Product__c = fuel.product.Id,
        										Company__c = fuel.company.Id,
        										Facility__c = fuel.facility2.Id,
        										Customer__c = fuel.customerParent.Id,
        										//Active__c = true,
        										Allocation__c = 100,
        										Business_Process_Type__c = 'OTC',
        										Start_Date__c = System.today() - 30,
        										End_Date__c = System.today() + 30,
        										Type__c = 'Manual'
        									);
        									
		insert allocationRule;
		fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
        
        Sales_Order__c salesOrderCurrent = new Sales_Order__c();
        salesOrderCurrent.Company__c = fuel.company.id;
        salesOrderCurrent.Customer__c = fuel.customerSoldTo.id;   
        salesOrderCurrent.Ship_To__c = fuel.customerShipTo.Id;
        salesOrderCurrent.Payment_Term__c = fuel.terms.id;
        salesOrderCurrent.Date_Time_Ordered__c = System.today().addDays(2); // in current year
        
        insert salesOrderCurrent;
        
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrderCurrent.Id;
        salesOrderLine.Quantity_Ordered__c = 30;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
        
        insert salesOrderLine;
        
        Test.startTest();
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
        						 Allocation__c, Allocation_Used__c, Facility__c 
        					FROM Allocation_Rule__c 
        				   WHERE Id = :allocationRule.Id 
        				   LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c);
        
        salesOrderLine = [SELECT Id, Estimated_ship_date__c 
        				    FROM Sales_Order_Line__c
        				   WHERE Id = :salesOrderLine.Id
        				   LIMIT 1];
        
        System.assertEquals(System.today() + 5, salesOrderLine.Estimated_ship_date__c);
        
        salesOrderLine.Ship_From_Location__c = null;
        
        update salesOrderLine;
        
        salesOrderLine = [SELECT Id, Estimated_ship_date__c 
        				    FROM Sales_Order_Line__c
        				   WHERE Id = :salesOrderLine.Id
        				   LIMIT 1];
        
        System.assertEquals(System.today() + 5, salesOrderLine.Estimated_ship_date__c);
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
        						 Allocation__c, Allocation_Used__c, Facility__c 
        					FROM Allocation_Rule__c 
        				   WHERE Id = :allocationRule.Id 
        				   LIMIT 1];
        
        System.assertEquals(0, allocationRule.Allocation_Used__c);
        
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
        
        update salesOrderLine;
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
        						 Allocation__c, Allocation_Used__c, Facility__c 
        					FROM Allocation_Rule__c 
        				   WHERE Id = :allocationRule.Id 
        				   LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c);
        
        
        Test.stopTest();   
                
    }   
}