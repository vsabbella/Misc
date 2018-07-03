@isTest
private class HierarchyServiceTest {
	class testHierarchyData{
		testHierarchyData() {}
		
		public Datetime asOfDate = system.now();
		
		public Period__c p = new Period__c() ; { 
			Testfuel fuel = new Testfuel();
            List<Period__c> periods = fuel.periodList;
            ////system.debug(logginglevel.info,'periods:'+periods);
            for(Period__c thisPeriod : periods){
            	////system.debug(logginglevel.info,'thisPeriod:'+thisPeriod);
            	////system.debug(logginglevel.info,'thisPeriod.period_start__c:'+thisPeriod.period_start__c+'==========thisPeriod.period_end__c:'+thisPeriod.period_end__c+'==========asOfDate:'+asOfDate);
            	if(thisPeriod.period_start__c <= asOfDate && asOfDate < thisPeriod.period_end__c ){
            		p = thisPeriod;
            		break;
            	}
            }
        }
        
		//public List<Hierarchy__c> hList = new List<hierarchy__c>();
		public GL_Account__c expenseGL, wagesExpenseGL, salariesExpenseGL, bonusExpenseGL, suppliesExpenseGL, suppliesExpenseGLParent, rentExpenseGL, rentExpenseGLParent, utilitiesExpenseGL, telephoneExpenseGL, waterExpenseGL, electricityExpenseGL;
		
		public list<GL_Account__c> glList = new list<GL_Account__c>();	{
			list<GL_Type__c> expenselist = new list<GL_Type__c>();
			GL_Type__c expense = new GL_Type__c();
            GL_Type__c expense2 = new GL_Type__c();
            
            expense.Name  = 'Payroll';
	    	expense.Normal_Balance__c  = 'Debit';
	    	expense.Accounting_Type__c  = 'Operating Expenses';
	    	expense.Statement_Type__c  = 'Income Statement';
	    	expense.Account_Range_From__c = '60000';
	    	expense.Account_Range_To__c ='69999';
    		

			expense2.Name  = 'Other Operating Expense';
	    	expense2.Normal_Balance__c  = 'Debit';
	    	expense2.Accounting_Type__c  = 'Operating Expenses';
	    	expense2.Statement_Type__c  = 'Income Statement';
	    	expense2.Account_Range_From__c = '63000';
	    	expense2.Account_Range_To__c ='63999';
			
            expenselist.add(expense);
            expenselist.add(expense2);
    		insert expenselist;
	    		
			expenseGL = new GL_Account__c();
			expenseGL.Name = '60000 - Employee Expense';
			expenseGL.GL_Account_Number__c = '60000';
			expenseGL.GL_Account_Name__c = 'Employee Expense';
			expenseGL.active__c = true;
			expenseGL.Normal_Balance__c = 'Debit';
			expenseGL.Statement_Type__c = 'Income Statement';
			expenseGL.non_cash__c = true;
			expenseGL.GL_Type__c = expenselist[0].id;
			glList.add(expenseGL);
			
			wagesExpenseGL = new GL_Account__c();
			wagesExpenseGL.Name = '60001 - Wages Expense';
			wagesExpenseGL.GL_Account_Number__c = '60001';
			wagesExpenseGL.GL_Account_Name__c = 'Wages Expense';
			wagesExpenseGL.active__c = true;
			wagesExpenseGL.Normal_Balance__c = 'Debit';
			wagesExpenseGL.Statement_Type__c = 'Income Statement';
			wagesExpenseGL.non_cash__c = true;
			wagesExpenseGL.GL_Type__c = expenselist[0].id;
			glList.add(wagesExpenseGL);
			
			salariesExpenseGL = new GL_Account__c();
			salariesExpenseGL.Name = '60004 - Salaries Expense';
			salariesExpenseGL.GL_Account_Number__c = '60004';
			salariesExpenseGL.GL_Account_Name__c = 'Salaries Expense';
			salariesExpenseGL.active__c = true;
			salariesExpenseGL.Normal_Balance__c = 'Debit';
			salariesExpenseGL.Statement_Type__c = 'Income Statement';
			salariesExpenseGL.non_cash__c = true;
			salariesExpenseGL.GL_Type__c =expenselist[0].id;
			glList.add(salariesExpenseGL);
			
			bonusExpenseGL = new GL_Account__c();
			bonusExpenseGL.Name = '60005 - Bonus Expense';
			bonusExpenseGL.GL_Account_Number__c = '60005';
			bonusExpenseGL.GL_Account_Name__c = 'Bonus Expense';
			bonusExpenseGL.active__c = true;
			bonusExpenseGL.Normal_Balance__c = 'Debit';
			bonusExpenseGL.Statement_Type__c = 'Income Statement';
			bonusExpenseGL.non_cash__c = true;
			bonusExpenseGL.GL_Type__c = expenselist[0].id;
			glList.add(bonusExpenseGL);
			
			suppliesExpenseGLParent = new GL_Account__c();
			suppliesExpenseGLParent.Name = '63000 - Supplies Expense Parent';
			suppliesExpenseGLParent.GL_Account_Number__c = '63000';
			suppliesExpenseGLParent.GL_Account_Name__c = 'Supplies Expense';
			suppliesExpenseGLParent.active__c = true;
			suppliesExpenseGLParent.Normal_Balance__c = 'Debit';
			suppliesExpenseGLParent.Statement_Type__c = 'Income Statement';
			suppliesExpenseGLParent.non_cash__c = true;
			suppliesExpenseGLParent.GL_Type__c = expenselist[1].id;
			glList.add(suppliesExpenseGLParent);


			rentExpenseGLParent = new GL_Account__c();
			rentExpenseGLParent.Name = '63001 - Rent Expense';
			rentExpenseGLParent.GL_Account_Number__c = '63001';
			rentExpenseGLParent.GL_Account_Name__c = 'Rent Expense';
			rentExpenseGLParent.active__c = true;
			rentExpenseGLParent.Normal_Balance__c = 'Debit';
			rentExpenseGLParent.Statement_Type__c = 'Income Statement';
			rentExpenseGLParent.non_cash__c = true;
			rentExpenseGLParent.GL_Type__c = expenselist[1].id;
			glList.add(rentExpenseGLParent);

			suppliesExpenseGL = new GL_Account__c();
			suppliesExpenseGL.Name = '63002 - Supplies Expense';
			suppliesExpenseGL.GL_Account_Number__c = '63002';
			suppliesExpenseGL.GL_Account_Name__c = 'Supplies Expense';
			suppliesExpenseGL.active__c = true;
			suppliesExpenseGL.Normal_Balance__c = 'Debit';
			suppliesExpenseGL.Statement_Type__c = 'Income Statement';
			suppliesExpenseGL.non_cash__c = true;
			suppliesExpenseGL.GL_Type__c = expenselist[1].id;
			glList.add(suppliesExpenseGL);
			
			rentExpenseGL = new GL_Account__c();
			rentExpenseGL.Name = '63003 - Rent Expense';
			rentExpenseGL.GL_Account_Number__c = '63003';
			rentExpenseGL.GL_Account_Name__c = 'Rent Expense';
			rentExpenseGL.active__c = true;
			rentExpenseGL.Normal_Balance__c = 'Debit';
			rentExpenseGL.Statement_Type__c = 'Income Statement';
			rentExpenseGL.non_cash__c = true;
			rentExpenseGL.GL_Type__c = expenselist[1].id;
			glList.add(rentExpenseGL);
			
			utilitiesExpenseGL = new GL_Account__c();
			utilitiesExpenseGL.Name = '63006 - Utilities Expense';
			utilitiesExpenseGL.GL_Account_Number__c = '63006';
			utilitiesExpenseGL.GL_Account_Name__c = 'Utilities Expense';
			utilitiesExpenseGL.active__c = true;
			utilitiesExpenseGL.Normal_Balance__c = 'Debit';
			utilitiesExpenseGL.Statement_Type__c = 'Income Statement';
			utilitiesExpenseGL.non_cash__c = true;
			utilitiesExpenseGL.GL_Type__c = expenselist[1].id;
			glList.add(utilitiesExpenseGL);
			
			telephoneExpenseGL = new GL_Account__c();
			telephoneExpenseGL.Name = '63007 - Telephone Expense';
			telephoneExpenseGL.GL_Account_Number__c = '63007';
			telephoneExpenseGL.GL_Account_Name__c = 'Telephone Expense';
			telephoneExpenseGL.active__c = true;
			telephoneExpenseGL.Normal_Balance__c = 'Debit';
			telephoneExpenseGL.Statement_Type__c = 'Income Statement';
			telephoneExpenseGL.non_cash__c = true;
			telephoneExpenseGL.GL_Type__c = expenselist[1].id;
			glList.add(telephoneExpenseGL);
			
			waterExpenseGL = new GL_Account__c();
			waterExpenseGL.Name = '63008 - Water Expense';
			waterExpenseGL.GL_Account_Number__c = '63008';
			waterExpenseGL.GL_Account_Name__c = 'Water Expense';
			waterExpenseGL.active__c = true;
			waterExpenseGL.Normal_Balance__c = 'Debit';
			waterExpenseGL.Statement_Type__c = 'Income Statement';
			waterExpenseGL.non_cash__c = true;
			waterExpenseGL.GL_Type__c = expenselist[1].id;
			glList.add(waterExpenseGL);
			
			electricityExpenseGL = new GL_Account__c();
			electricityExpenseGL.Name = '63009 - Electricity Expense';
			electricityExpenseGL.GL_Account_Number__c = '63009';
			electricityExpenseGL.GL_Account_Name__c = 'Electricity Expense';
			electricityExpenseGL.active__c = true;
			electricityExpenseGL.Normal_Balance__c = 'Debit';
			electricityExpenseGL.Statement_Type__c = 'Income Statement';
			electricityExpenseGL.non_cash__c = true;
			electricityExpenseGL.GL_Type__c = expenselist[1].id;
			glList.add(electricityExpenseGL);
			
			insert glList;
			
			wagesExpenseGL.subaccount_of__c 		= expenseGL.id;
			
			suppliesExpenseGL.subaccount_of__c 		= suppliesExpenseGLParent.id;
			rentExpenseGL.subaccount_of__c 			= rentExpenseGLParent.id;

			salariesExpenseGL.subaccount_of__c 		= expenseGL.id;
			bonusExpenseGL.subaccount_of__c 		= expenseGL.id;

			utilitiesExpenseGL.subaccount_of__c 	= rentExpenseGL.id;
			telephoneExpenseGL.subaccount_of__c 	= rentExpenseGL.id;

			waterExpenseGL.subaccount_of__c 		= utilitiesExpenseGL.id;
			electricityExpenseGL.subaccount_of__c 	= utilitiesExpenseGL.id;
			
			update glList;
			
		}
		
		
		// Use hierarchy object to link the GL accounts with each other
		public List<Hierarchy__c> hList = new List<Hierarchy__c>();{
			////system.debug(logginglevel.info,'p:'+p);
			////system.debug(logginglevel.info,'glList:'+glList);
			
			Hierarchy__c h1 = new Hierarchy__c();
			h1.name = 'H1';
			h1.code__c = expenseGL.id;
			h1.type__c = 'Segment Hierarchy';
			h1.start_period__c = p.id;
			hList.add(h1);
			
			Hierarchy__c h2 = new Hierarchy__c();
			h2.name = 'H2';
			h2.code__c = wagesExpenseGL.id;
			h2.parent_code__c = expenseGL.id;
			h2.type__c = 'Segment Hierarchy';
			h2.start_period__c = p.id;
			hList.add(h2);
			
			Hierarchy__c h3 = new Hierarchy__c();
			h3.name = 'H3';
			h3.code__c = suppliesExpenseGL.id;
			h3.parent_code__c = expenseGL.id;
			h3.type__c = 'Segment Hierarchy';
			h3.start_period__c = p.id;
			hList.add(h3);
			
			Hierarchy__c h4 = new Hierarchy__c();
			h4.name = 'H4';
			h4.code__c = rentExpenseGL.id;
			h4.parent_code__c = expenseGL.id;
			h4.type__c = 'Segment Hierarchy';
			h4.start_period__c = p.id;
			hList.add(h4);
			
			Hierarchy__c h5 = new Hierarchy__c();
			h5.name = 'H5';
			h5.code__c = salariesExpenseGL.id;
			h5.parent_code__c = wagesExpenseGL.id;
			h5.type__c = 'Segment Hierarchy';
			h5.start_period__c = p.id;
			hList.add(h5);
			
			Hierarchy__c h6 = new Hierarchy__c();
			h6.name = 'H6';
			h6.code__c = bonusExpenseGL.id;
			h6.parent_code__c = wagesExpenseGL.id;
			h6.type__c = 'Segment Hierarchy';
			h6.start_period__c = p.id;
			hList.add(h6);
			
			Hierarchy__c h7 = new Hierarchy__c();
			h7.name = 'H7';
			h7.code__c = utilitiesExpenseGL.id;
			h7.parent_code__c = rentExpenseGL.id;
			h7.type__c = 'Segment Hierarchy';
			h7.start_period__c = p.id;
			hList.add(h7);
			
			Hierarchy__c h8 = new Hierarchy__c();
			h8.name = 'H8';
			h8.code__c = telephoneExpenseGL.id;
			h8.parent_code__c = rentExpenseGL.id;
			h8.type__c = 'Segment Hierarchy';
			h8.start_period__c = p.id;
			hList.add(h8);
			
			Hierarchy__c h9 = new Hierarchy__c();
			h9.name = 'H9';
			h9.code__c = waterExpenseGL.id;
			h9.parent_code__c = utilitiesExpenseGL.id;
			h9.type__c = 'Segment Hierarchy';
			h9.start_period__c = p.id;
			hList.add(h9);
			
			Hierarchy__c h10 = new Hierarchy__c();
			h10.name = 'H10';
			h10.code__c = electricityExpenseGL.id;
			h10.parent_code__c = utilitiesExpenseGL.id;
			h10.type__c = 'Segment Hierarchy';
			h10.start_period__c = p.id;
			hList.add(h10);
			
			insert hList;
			
		}
	
	}
	
	// Test the buildHierarchy function by passing the custom segment object.
    static testMethod void test_buildHierarchy() {
    	// build some data for a custom segment ( could be any existing object )
    	TestHierarchyData hd = new TestHierarchyData();
    	////system.debug(logginglevel.info,'hierarchylist:'+hd.hList());
    	Map<Id, sObject> mSObjects = new Map<Id, sObject>();
    	for(sObject sObj: hd.glList){
    		mSObjects.put(sObj.id, sObj);
    	}
    	Test.startTest();
    	hierarchyResult hr = hierarchyService.buildHierarchy(mSObjects, hd.asOfDate);
    	ID parentId = hd.expenseGL.id;
    	List<Node> nodeList = hr.getChildNodes(parentId);
    	map<Id, Node> mTestNode = new Map<Id, Node>();
    	for(Node n: nodeList){
    		mTestNode.put(n.id, n);
    	}
    	Test.stopTest();
    	Node wagesNode = new Node();
    	wagesNode.id = hd.wagesExpenseGL.id;
    	////system.debug(logginglevel.info,'wagesNode:'+wagesNode);
    	//assert that the nodeList has expected children in the list
    	system.assert(mTestNode.containsKey(wagesNode.id));
    	
    	Id ChildId = hd.bonusExpenseGL.id;
    	Boolean isMyParent = hr.checkParent(childId, parentId);
    	// assert that the isMyParent is true / false depending on the data passed in
    	system.assert(isMyParent);
    	
    	parentId = hd.expenseGL.id;
    	childId = hd.waterExpenseGL.id;
    	isMyParent = hr.checkParent(childId, parentId);
    	// assert that the isMyParent is true / false depending on the data passed in
    	system.assert(isMyParent);
    	
    
    }
    
    // Test the buildHierarchy function by passing the GL records and the parent field
    static testMethod void test_buildHierarchy_Self() {
    	TestHierarchyData hd = new TestHierarchyData();
        // get hierarchy result
        Map<Id, sObject> mSObjects = new Map<Id, sObject>();
    	for(sObject sObj: hd.glList){
    		mSObjects.put(sObj.id, sObj);
    	}
    	//system.debug(logginglevel.info,'mSObjects:'+mSObjects);
    	Test.startTest();
        hierarchyResult hr = hierarchyService.buildHierarchy(mSObjects, 'SubAccount_Of__c');
		//system.debug(logginglevel.error,'hr in testmethod:'+ JSON.serialize(hr));

        // Test isMyParent function - assert with expected parent
    	// Test getMyChildren function - assert to check if the list contains expected children 
    	ID parentId = hd.expenseGL.id;
    	List<Node> nodeList = hr.getChildNodes(parentId);
    	//system.debug(logginglevel.error,'nodeList in testmethod:'+ JSON.serialize(nodeList));
    	map<Id, Node> mTestNode = new Map<Id, Node>();
    	for(Node n: nodeList){
    		mTestNode.put(n.id, n);
    	}
    	Test.stopTest();
    	Node wagesNode = new Node();
    	wagesNode.id = hd.wagesExpenseGL.id;
    	//system.debug(logginglevel.error,'wagesNode:'+ JSON.serialize(wagesNode));
    	//system.debug(logginglevel.error,'mTestNode:'+ JSON.serialize(mTestNode));
    	//assert that the nodeList has expected children in the list
    	system.assert(mTestNode.containsKey(wagesNode.id));
    		
    	Id ChildId = hd.bonusExpenseGL.id;
    	Boolean isMyParent = hr.checkParent(childId, parentId);
    	// assert that the isMyParent is true / false depending on the data passed in
    	system.assert(isMyParent);
    	
    	parentId = hd.expenseGL.id;
    	childId = hd.bonusExpenseGL.id;
    	isMyParent = hr.checkParent(childId, parentId);
    	// assert that the isMyParent is true / false depending on the data passed in
    	system.assert(isMyParent);
    }
    
    static testmethod void test_setPeriodDates(){
   
       	TestHierarchyData hd = new TestHierarchyData();
   		Boolean sawException=false;
       	
    	list<Hierarchy__c> hlist = new list<hierarchy__c>();
    	
		Hierarchy__c h1 = new Hierarchy__c();
		h1.name = 'TestDateDefault -Segment';
		h1.code__c = '123';
		h1.type__c = 'Segment Hierarchy';
		//h1.start_period__c = hd.p.id;		
		hlist.add(h1);

		Hierarchy__c h3 = new Hierarchy__c();
		h3.name = 'TestDateDefault -Segment';
		h3.code__c = '123';
		h3.type__c = 'Segment Hierarchy';
		h3.start_period__c = hd.p.id;		
		hlist.add(h3);
				
		Hierarchy__c h2 = new Hierarchy__c();
		h2.name = 'TestDateDefault -NonSegment';
		h2.code__c = '1234';
		h2.type__c = 'Product Hierarchy';
		hlist.add(h2);
		try{
		insert 	hlist;
		}catch(dmlException dml){
			system.assertEquals(dml.getDMLMessage(0),'Segment Hierarchy must have starting period.','Expecting Hier recs to be inserted');
		}
		list<hierarchy__c> hierRecs=[select id,name,start_date__c,start_datetime__c,end_datetime__c 
		 							 from Hierarchy__c where id in :hlist];
		 
		system.assertNotEquals(hierRecs,null,'Expecting Hier recs to be inserted');
		system.assertEquals(hierRecs.size() == 0,true,hierRecs.size());
		for(Hierarchy__c hierRec:hierRecs){
			
			if(hierRec.name=='TestDateDefault -Segment'){
				system.assertEquals(hierRec.start_date__c,hd.p.Period_Start__c.date());
				system.assertEquals(hierRec.start_datetime__c,hd.p.Period_Start__c);
				system.assertEquals(hierRec.end_datetime__c,null);	
			}
			else if(hierRec.name=='TestDateDefault -NonSegment'){
				system.assertEquals(hierRec.start_date__c,system.today());
								
			}
			
		}
		
		
		Hierarchy__c h4= new Hierarchy__c();
		h4.name = 'Test-withoutType';
		h4.code__c = '12345';
		
	    try{
	    	insert h4;
	    }
	    catch(Exception ex){
	    	sawException= true;
	    	system.assert(ex.getmessage().contains('hierarchy type'));
	    }
	    system.assertEquals(sawException,true,'Expecting Exception to be thrown');
		
    	
    }
    
    
    
}