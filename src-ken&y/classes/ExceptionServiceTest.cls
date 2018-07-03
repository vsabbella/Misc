/**
 * This class contains unit tests for validating the behavior of methods in ExceptionServiceAPI.cls
 */
@isTest
private class ExceptionServiceTest {
	static TestFuel globalTestData = new TestFuel();
	
	static testMethod void testSetException() {
    	Test.startTest();
    	
    	TaskType NORMAL_TASK = new TaskType();
		NORMAL_TASK.code = 'NO-TASK00001';
		NORMAL_TASK.label = 'Not an exception.';
		NORMAL_TASK.description = 'This task is created to test if the exceptions count is wrongly updated.';
		NORMAL_TASK.typeName = 'Other';
				
    	ExceptionServiceAPI exService = new ExceptionServiceAPI();
    	exService.setException(new Sales_Order__c(), NORMAL_TASK);
    	exService.setException(globalTestData.salesOrder, NORMAL_TASK);
		exService.finishTasks();
		
		globalTestData.salesOrder = [select Id, Exceptions_Count__c, Has_Exceptions__c,
										    (select Id, Exception_Code__c, Status, Type 
										      from Tasks
							      	 		 where isClosed = false
							      	 		 and Exception_Code__c  = :ExceptionUtil.PRODUCT_IS_BLOCKED.code) 
									   from Sales_Order__c 
									  where Id = :globalTestData.salesOrder.Id LIMIT 1];
		
		system.assertEquals(false, globalTestData.salesOrder.Exceptions_Count__c > 0);
		system.assertEquals(false, globalTestData.salesOrder.Has_Exceptions__c);
		
		exService.setException(globalTestData.salesOrder, ExceptionUtil.PRODUCT_IS_BLOCKED);
    	exService.finishTasks();
		
		globalTestData.salesOrder = [select Id, Exceptions_Count__c, Has_Exceptions__c,
										    (select Id, Exception_Code__c, Status, Type 
										      from Tasks
							      	 		 where isClosed = false
							      	 		 and Exception_Code__c  = :ExceptionUtil.PRODUCT_IS_BLOCKED.code) 
									   from Sales_Order__c 
									  where Id = :globalTestData.salesOrder.Id LIMIT 1];
		
		List<Task> exceptionList = globalTestData.salesOrder.Tasks;							 
		system.assertNotEquals(0, exceptionList.size());
		system.assertEquals('Exception', exceptionList[0].Type);
		system.assertEquals(TaskType.EXCEPTION_STATUS_OPEN, exceptionList[0].Status);
		system.assertEquals(ExceptionUtil.PRODUCT_IS_BLOCKED.code, exceptionList[0].Exception_Code__c);
		
		Test.stopTest();
    }
    
    static testMethod void testClearException() {
    	Test.startTest();
    	ExceptionServiceAPI exService = new ExceptionServiceAPI();
    	exService.setException(globalTestData.salesOrder, ExceptionUtil.PRODUCT_IS_BLOCKED);
		exService.finishTasks();
		
		List<Task> exceptionList = [select Id,
										   (select Id, Exception_Code__c, Status, Type 
										      from Tasks
							      			 where isClosed = false AND Status != 'Closed') 
									  from Sales_Order__c 
									 where Id = :globalTestData.salesOrder.Id].Tasks;
									 
		system.assertEquals(1, exceptionList.size(), 'exceptionList.size() 1: ');
		
		exService.clearException(globalTestData.salesOrder, ExceptionUtil.PRODUCT_IS_BLOCKED);
		exService.finishTasks();
		
		exceptionList = [select Id,
							    (select Id, Exception_Code__c, Status, Type 
							      from Tasks
							      where isClosed = true OR Status = 'Closed') 
						   from Sales_Order__c 
						  where Id = :globalTestData.salesOrder.Id].Tasks;
									 
		system.assertEquals(1, exceptionList.size(), 'exceptionList.size() 2: '); //KNDY-16892
		
		exService.setException(globalTestData.salesOrder, ExceptionUtil.PRODUCT_IS_BLOCKED);
		exService.finishTasks();
		
		// Test that the previously closed task is not opened again.							 
//		system.assertEquals(1, [select Id, (select Id, Exception_Code__c, Status, Type from Tasks where isClosed = false AND Status != 'Closed')
//											  from Sales_Order__c
//											 where Id = :globalTestData.salesOrder.Id].Tasks.size(), 'exceptionList.size() 3: ');
											 
    	/*system.assertEquals(1, [select Id, (select Id, Exception_Code__c, Status, Type from Tasks where isClosed = true) 
											  from Sales_Order__c 
											 where Id = :globalTestData.salesOrder.Id].Tasks.size(), 'exceptionList.size() 4: ');
	*/	
		Test.stopTest();											 
    }
    
    static testMethod void testFinishTasks() {
    	Test.startTest();
    	ExceptionServiceAPI exService = new ExceptionServiceAPI();
    	exService.setException(globalTestData.salesOrder, ExceptionUtil.PRODUCT_IS_BLOCKED);
		exService.finishTasks();
		
		List<Task> exceptionList = [select Id,
										   (select Id, Exception_Code__c, Status, Type 
										      from Tasks
							      	 		 where isClosed = false) 
									  from Sales_Order__c 
									 where Id = :globalTestData.salesOrder.Id].Tasks;
									 
		system.assertNotEquals(0, exceptionList.size());
		//system.assertEquals(false, exService.isRunning);
		
		//exService.start();
		exService.clearException(globalTestData.salesOrder, ExceptionUtil.PRODUCT_IS_BLOCKED);
		list<Database.UpsertResult> upsertTasks = exService.finishTasks(false);
		
		exceptionList = [select Id,
							   (select Id, Exception_Code__c, Status, Type 
							      from Tasks
				      	 		 where isClosed = false) 
						  from Sales_Order__c 
						 where Id = :globalTestData.salesOrder.Id].Tasks;
									 
		//system.assertNotEquals(0, upsertTasks.size());
		system.assertNotEquals(0, exceptionList.size());
		//system.assertEquals(false, exService.isRunning);
		Test.stopTest();
	}

	static testMethod void testFinish() {
		Test.startTest();
		ExceptionServiceAPI exService = new ExceptionServiceAPI();
		exService.setException(globalTestData.salesOrder, ExceptionUtil.PRODUCT_IS_BLOCKED);
		exService.finish();

		List<Task> exceptionList = [select Id,
		(select Id, Exception_Code__c, Status, Type
		from Tasks
		where isClosed = false)
		from Sales_Order__c
		where Id = :globalTestData.salesOrder.Id].Tasks;

		system.assertNotEquals(0, exceptionList.size());
		//system.assertEquals(false, exService.isRunning);

		//exService.start();
		exService.clearException(globalTestData.salesOrder, ExceptionUtil.PRODUCT_IS_BLOCKED);
		list<Task> upsertTasks = exService.finish(false);

		exceptionList = [select Id,
		(select Id, Exception_Code__c, Status, Type
		from Tasks
		where isClosed = false)
		from Sales_Order__c
		where Id = :globalTestData.salesOrder.Id].Tasks;

		//system.assertNotEquals(0, upsertTasks.size());
		system.assertNotEquals(0, exceptionList.size());
		//system.assertEquals(false, exService.isRunning);
		Test.stopTest();
	}
    
	static testMethod void testHasMessages(){
		
		List<MessageUtil.Severity> severities = MessageUtil.Severity.values();
		system.assert(severities.size() > 0, 'Expected to return a list of enums.');
		
		for(MessageUtil.Severity sev : severities){
			ExceptionService.addMessage(sev.name(), sev.name(), '');
		}
		
		for(MessageUtil.Severity sev : severities){
			system.assert(ExceptionService.hasMessages(sev.name()), 'Expected true.');
		}
		
	}
	
	static testMethod void testMaxSeverityLevel(){
		
		ExceptionService.addMessage(MessageUtil.Severity.CONFIRM.name(), MessageUtil.Severity.CONFIRM.name(), '');
		system.assert(ExceptionService.maxSeverityLevel == 0);
		
		ExceptionService.addMessage(MessageUtil.Severity.INFO.name(), MessageUtil.Severity.CONFIRM.name(), '');
		system.assert(ExceptionService.maxSeverityLevel == 1);
		
		ExceptionService.addMessage(MessageUtil.Severity.WARNING.name(), MessageUtil.Severity.CONFIRM.name(), '');
		system.assert(ExceptionService.maxSeverityLevel == 2);
		
		ExceptionService.addMessage(MessageUtil.Severity.ERROR.name(), MessageUtil.Severity.CONFIRM.name(), '');
		system.assert(ExceptionService.maxSeverityLevel == 3);
		
		ExceptionService.addMessage(MessageUtil.Severity.FATAL.name(), MessageUtil.Severity.CONFIRM.name(), '');
		system.assert(ExceptionService.maxSeverityLevel == 4);
		
	}
}
