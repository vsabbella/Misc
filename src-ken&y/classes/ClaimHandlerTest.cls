@isTest
private class ClaimHandlerTest {
	static TestFuel tdf = new TestFuel();
		 
	public class ClaimsData{
		
		public Customer_Invoice__c custInvoice;
		public Customer_Invoice_Line__c custInvoiceLine;
		public Customer_Receipt__c custReceipt;
		public List<Customer_Receipt_Line__c> pmtLines;
        public Reason_Code__c deductionCode;
		public ClaimsData(){
			createData();
		}
		
		void createData(){
			
			//Sample AR Data
			custInvoice = new Customer_Invoice__c();
			custInvoice.Company__c = tdf.company.Id;
			custInvoice.Customer__c = tdf.customerParent.Id;
			custInvoice.Bill_To_Customer__c = tdf.customerbillto.id;
			custInvoice.Currency__c = TestFuel.currencyUSD.id;
			custInvoice.Invoice_Type__c = 'Ship Invoice';
			custInvoice.Status__c = 'Open';
			custInvoice.Sales_Order__c = tdf.salesOrder.Id;
			insert custInvoice;
			
			custInvoiceLine = new Customer_Invoice_Line__c();
			custInvoiceLine.Customer_Invoice__c = custInvoice.Id;
			custInvoiceLine.Product__c = tdf.product.Id;
			custInvoiceLine.Quantity_Shipped__c = 10;
			custInvoiceLine.Unit_Price__c = 10;
			custInvoiceLine.Extended_Price__c = 100;
			insert custInvoiceLine;
			
			custReceipt = new Customer_Receipt__c();
			custReceipt.Company__c = tdf.company.Id;
			custReceipt.Type__c = CustomerReceiptService.TYPE_RECEIPT;
			custReceipt.Customer__c = tdf.customerBillTo.Id;
			custReceipt.Date_Received__c = system.today();
			insert custReceipt;
            deductionCode = new Reason_Code__c();
            deductionCode.Type__c = 'Deductions';
            deductionCode.Code__c = 'D001';
            insert deductionCode;
		}
		
	}
	
	static testMethod void testLookupReferenceCriteria_fail() { //OTC-579
		system.assert(tdf.periodList!=null);
		
		List<Claim__c> sampleList = new List<Claim__c>();
		
		Process__c p = new Process__c();
    	p.Name = 'Small Balance';
    	p.Object__c = sampleList.getSObjectType().getDescribe().getName(); //'Claim__c';
    	p.Object_Step__c = Claim__c.Step__c.getDescribe().getName(); //'Step__c';
    	p.Active__c = true;
    	p.Automated__c = true;
    	p.After__c = true;
    	p.Insert__c = true;
    	p.State__c = 'ClaimHandler.ClaimState';
    	p.Sequence__c = 10;
    	insert p;
    	
    	Reason_Code__c resolution = new Reason_Code__c();
		resolution.name = 'Unsaleables';
		resolution.type__c = 'Resolution';
		insert resolution;
		
    	Criteria__c c = new Criteria__c();
    	c.Name = 'Small balance -1';
    	c.Process__c = p.Id;
    	//Manually write in the status field without the assumed namespace
    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
    	c.field__c = 'Status__c';//Claim__c.Status__c.getDescribe().getName(); //'Status__c';
    	c.operator__c = 'not equal to';
    	c.value_field__c = 'Value';
    	c.reference__c = 'Closed';
    	c.number__c = 10;
    	insert c;
    	
    	Criteria__c c1 = new Criteria__c();
    	c1.Name = 'Small Balance -2';
    	c1.Process__c = p.Id;
    	//Manually write in the status field without the assumed namespace
    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
    	c1.field__c = 'Resolution_Code__c';//Claim__c.Status__c.getDescribe().getName(); //'Status__c';
    	c1.operator__c = 'equals';
    	c1.value_field__c = 'Value';
    	c1.reference__c = String.valueOf(resolution.Id).substring(0,15);
    	c1.number__c = 20;
    	insert c1;
    	
    	Step__c s = new Step__c();
    	s.Name = 'Small Balance -1';
    	s.Process__c = p.Id;
    	s.Sequence__c = 10;
    	insert s;
    	
    	list<Action__c> actions = new list<Action__c>();
    	actions.add(new Action__c(Name = 'Small Balance -1', Step__c = s.Id,Action__c = 'ClaimHandler.Resolve', Sequence__c =10));
    	
    	
    	insert actions;
    	
    	
    	
    	Claim__c claim = new Claim__c(Parent_Customer__c = tdf.customerparent.Id, Bill_To_Customer__c = tdf.customerBillTo.Id, Amount__c =150, Status__c ='New', Company__c = tdf.company.id );
    	insert claim;
    	
    	claim = [select Status__c from Claim__c where id = :claim.Id LIMIT 1];
    	system.assert(claim.Status__c == 'New', 'The status should be open as part of criteria evaluated to false ');
		
		
	}
	
	static testMethod void testLookupReferenceCriteria_notEqualTo() { 
		system.assert(tdf.periodList!=null);
		
		List<Claim__c> sampleList = new List<Claim__c>();
		
		Process__c p = new Process__c();
    	p.Name = 'Small Balance';
    	p.Object__c = sampleList.getSObjectType().getDescribe().getName(); //'Claim__c';
    	p.Object_Step__c = Claim__c.Step__c.getDescribe().getName(); //'Step__c';
    	p.Active__c = true;
    	p.Automated__c = true;
    	p.After__c = true;
    	p.Insert__c = true;
    	p.State__c = 'ClaimHandler.ClaimState';
    	p.Sequence__c = 10;
    	insert p;
    	
    	Reason_Code__c resolution = new Reason_Code__c();
		resolution.name = 'Unsaleables';
		resolution.type__c = 'Resolution';
		insert resolution;
		
		Reason_Code__c resolution1 = new Reason_Code__c();
		resolution1.name = 'Unsaleables1';
		resolution1.type__c = 'Resolution';
		insert resolution1;
		
    	Criteria__c c = new Criteria__c();
    	c.Name = 'Small balance -1';
    	c.Process__c = p.Id;
    	//Manually write in the status field without the assumed namespace
    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
    	c.field__c = 'Status__c';//Claim__c.Status__c.getDescribe().getName(); //'Status__c';
    	c.operator__c = 'not equal to';
    	c.value_field__c = 'Value';
    	c.reference__c = 'Closed';
    	c.number__c = 10;
    	insert c;
    	
    	Criteria__c c1 = new Criteria__c();
    	c1.Name = 'Small Balance -2';
    	c1.Process__c = p.Id;
    	//Manually write in the status field without the assumed namespace
    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
    	c1.field__c = 'Resolution_Code__c';//Claim__c.Status__c.getDescribe().getName(); //'Status__c';
    	c1.operator__c = 'not equal to';
    	c1.value_field__c = 'Value';
    	c1.reference__c = String.valueOf(resolution1.Id).substring(0,15);
    	c1.number__c = 20;
    	insert c1;
    	
    	Step__c s = new Step__c();
    	s.Name = 'Small Balance -1';
    	s.Process__c = p.Id;
    	s.Sequence__c = 10;
    	insert s;
    	
    	list<Action__c> actions = new list<Action__c>();
    	actions.add(new Action__c(Name = 'Small Balance -1', Step__c = s.Id,Action__c = 'ClaimHandler.Resolve', Sequence__c =10));
    	
    	
    	insert actions;
    	
    	
        Claim__c claim = new Claim__c(Parent_Customer__c = tdf.customerparent.Id, Bill_To_Customer__c = tdf.customerBillTo.Id, Amount__c =150, Status__c ='New',Source__c = 'Invoice Deduction', Company__c = tdf.company.id, Resolution_Code__c = resolution.Id);
    	insert claim;
    	
    	claim = [select Status__c from Claim__c where id = :claim.Id LIMIT 1];
    	system.assert(claim.Status__c == 'Closed', 'The status should be open as part of criteria evaluated to false ');
		
		
	}
	static testMethod void testLookupReferenceCriteria() {
		system.assert(tdf.periodList!=null);
		
		List<Claim__c> sampleList = new List<Claim__c>();
		
		Process__c p = new Process__c();
    	p.Name = 'Small Balance';
    	p.Object__c = sampleList.getSObjectType().getDescribe().getName(); //'Claim__c';
    	p.Object_Step__c = Claim__c.Step__c.getDescribe().getName(); //'Step__c';
    	p.Active__c = true;
    	p.Automated__c = true;
    	p.After__c = true;
    	p.Insert__c = true;
    	p.State__c = 'ClaimHandler.ClaimState';
    	p.Sequence__c = 10;
    	insert p;
    	
    	Criteria__c c = new Criteria__c();
    	c.Name = 'Small balance -1';
    	c.Process__c = p.Id;
    	//Manually write in the status field without the assumed namespace
    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
    	c.field__c = 'Status__c';//Claim__c.Status__c.getDescribe().getName(); //'Status__c';
    	c.operator__c = 'not equal to';
    	c.value_field__c = 'Value';
    	c.reference__c = 'Closed';
    	c.number__c = 10;
    	insert c;
    	
    	Criteria__c c1 = new Criteria__c();
    	c1.Name = 'Small Balance -2';
    	c1.Process__c = p.Id;
    	//Manually write in the status field without the assumed namespace
    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
    	c1.field__c = 'Bill_to_Customer__c';//Claim__c.Status__c.getDescribe().getName(); //'Status__c';
    	c1.operator__c = 'equals';
    	c1.value_field__c = 'Value';
    	c1.reference__c = String.valueOf(tdf.customerBillTo.Id).substring(0,14);
    	c1.number__c = 20;
    	insert c1;
    	
    	Step__c s = new Step__c();
    	s.Name = 'Small Balance -1';
    	s.Process__c = p.Id;
    	s.Sequence__c = 10;
    	insert s;
    	
    	list<Action__c> actions = new list<Action__c>();
    	actions.add(new Action__c(Name = 'Small Balance -1', Step__c = s.Id,Action__c = 'ClaimHandler.Resolve', Sequence__c =10));
    	
    	
    	insert actions;
    	
    	Reason_Code__c resolution = new Reason_Code__c();
		resolution.name = 'Unsaleables';
		resolution.type__c = 'Resolution';
		insert resolution;
    	
        
        Claim__c claim = new Claim__c(Parent_Customer__c = tdf.customerparent.Id, Bill_To_Customer__c = tdf.customerBillTo.Id, Amount__c =150, Status__c ='New',Source__c ='Invoice Deduction', Company__c = tdf.company.id, Resolution_Code__c =resolution.id );
    	insert claim;
    	
    	claim = [select Status__c from Claim__c where id = :claim.Id LIMIT 1];
    	system.assert(claim.Status__c == 'Closed', 'The status should be closed as part of Process automation');
		
		
	}
	static testMethod void CreiteriaServiceTest_Number() {
		system.assert(tdf.periodList!=null);
		Claim__c claim = new Claim__c(Company__c = tdf.company.Id,
		    													Parent_Customer__c = tdf.customerParent.Id,
		    													Currency__c = TestFuel.currencyUSD.id,
		    													Type__c = 'MILITARY DIST PAYMENT',
		    													Claim_Date__c = Date.today(),
		    													Amount__c = 100,
		    													Status__c = 'New');
		insert claim;
		List<Claim__c> sampleList = new List<Claim__c>();
		Process__c p = new Process__c();
    	p.Name = 'Military Payment';
    	p.Object__c = sampleList.getSObjectType().getDescribe().getName(); //'Claim__c';
    	p.Object_Step__c = Claim__c.Step__c.getDescribe().getName(); //'Step__c';
    	p.Active__c = true;
    	p.Automated__c = true;
    	p.After__c = true;
    	p.Insert__c = true;
    	p.State__c = 'ClaimHandler.ClaimState';
    	p.Sequence__c = 10;
    	insert p;
    	
    	list<Criteria__c> lCriterias = new list<Criteria__c>();
    	lCriterias.add(new Criteria__c(Name = 'Military Payment -1',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Amount__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'not equal to',
								    	value_field__c = 'Value',
								    	reference__c = '10',
								    	number__c = 10));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -2',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Amount__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'less than',
								    	value_field__c = 'Value',
								    	reference__c = '200',
								    	number__c = 20));	
		lCriterias.add(new Criteria__c(Name = 'Military Payment -3',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Amount__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'greater than',
								    	value_field__c = 'Value',
								    	reference__c = '10',
								    	number__c = 30));	
		lCriterias.add(new Criteria__c(Name = 'Military Payment -4',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Amount__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'less or equal',
								    	value_field__c = 'Value',
								    	reference__c = '100',
								    	number__c = 40));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -5',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Amount__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'greater or equal',
								    	value_field__c = 'Value',
								    	reference__c = '100',
								    	number__c = 50));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -6',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Amount__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'equals',
								    	value_field__c = 'Value',
								    	reference__c = '100',
								    	number__c = 60));						    		
		insert lCriterias;						    								    							    	
    	
		boolean  answer = CriteriaService.evaluateCriteria(lCriterias,claim);
		system.assertEquals(answer,true);
	}
	
	static testMethod void CreiteriaServiceTest_Text() {
		system.assert(tdf.periodList!=null);
		Claim__c claim = new Claim__c(Company__c = tdf.company.Id,
		    													Parent_Customer__c = tdf.customerParent.Id,
		    													Currency__c = TestFuel.currencyUSD.id,
		    													Type__c = 'MILITARY DIST PAYMENT',
		    													Claim_Date__c = Date.today(),
		    													Amount__c = 100,
		    													Status__c = 'New');
		insert claim;
		List<Claim__c> sampleList = new List<Claim__c>();
		Process__c p = new Process__c();
    	p.Name = 'Military Payment';
    	p.Object__c = sampleList.getSObjectType().getDescribe().getName(); //'Claim__c';
    	p.Object_Step__c = Claim__c.Step__c.getDescribe().getName(); //'Step__c';
    	p.Active__c = true;
    	p.Automated__c = true;
    	p.After__c = true;
    	p.Insert__c = true;
    	p.State__c = 'ClaimHandler.ClaimState';
    	p.Sequence__c = 10;
    	insert p;
    	
    	list<Criteria__c> lCriterias = new list<Criteria__c>();
    	lCriterias.add(new Criteria__c(Name = 'Military Payment -1',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Status__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'not equal to',
								    	value_field__c = 'Value',
								    	reference__c = 'Closed',
								    	number__c = 10));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -2',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Status__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'starts with',
								    	value_field__c = 'Value',
								    	reference__c = 'New',
								    	number__c = 20));	
		lCriterias.add(new Criteria__c(Name = 'Military Payment -3',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Status__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'does not start with',
								    	value_field__c = 'Value',
								    	reference__c = '10',
								    	number__c = 30));	
		lCriterias.add(new Criteria__c(Name = 'Military Payment -4',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Status__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'contains',
								    	value_field__c = 'Value',
								    	reference__c = 'ew',
								    	number__c = 40));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -5',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Status__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'does not contain',
								    	value_field__c = 'Value',
								    	reference__c = '100',
								    	number__c = 50));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -6',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Status__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'equals',
								    	value_field__c = 'Value',
								    	reference__c = 'New',
								    	number__c = 60));						    		
		insert lCriterias;						    								    							    	
    	
		boolean  answer = CriteriaService.evaluateCriteria(lCriterias,claim);
		system.assertEquals(answer,true);
	}
	
	static testMethod void CreiteriaServiceTest_Date() {//2015-03-31 00:00:00
		system.assert(tdf.periodList!=null);
		Claim__c claim = new Claim__c(Company__c = tdf.company.Id,
		    													Parent_Customer__c = tdf.customerParent.Id,
		    													Currency__c = TestFuel.currencyUSD.id,
		    													Type__c = 'MILITARY DIST PAYMENT',
		    													Claim_Date__c = Date.newInstance(2015,3,31),
		    													Amount__c = 100,
		    													Status__c = 'New');
		insert claim;
		List<Claim__c> sampleList = new List<Claim__c>();
		Process__c p = new Process__c();
    	p.Name = 'Military Payment';
    	p.Object__c = sampleList.getSObjectType().getDescribe().getName(); //'Claim__c';
    	p.Object_Step__c = Claim__c.Step__c.getDescribe().getName(); //'Step__c';
    	p.Active__c = true;
    	p.Automated__c = true;
    	p.After__c = true;
    	p.Insert__c = true;
    	p.State__c = 'ClaimHandler.ClaimState';
    	p.Sequence__c = 10;
    	insert p;
    	
    	list<Criteria__c> lCriterias = new list<Criteria__c>();
    	lCriterias.add(new Criteria__c(Name = 'Military Payment -1',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Claim_Date__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'not equal to',
								    	value_field__c = 'Value',
								    	reference__c = '2015-03-30 00:00:00',
								    	number__c = 10));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -2',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Claim_Date__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'less than',
								    	value_field__c = 'Value',
								    	reference__c = '2015-04-01 00:00:00',
								    	number__c = 20));	
		lCriterias.add(new Criteria__c(Name = 'Military Payment -3',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Claim_Date__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'greater than',
								    	value_field__c = 'Value',
								    	reference__c = '2015-03-30 00:00:00',
								    	number__c = 30));	
		lCriterias.add(new Criteria__c(Name = 'Military Payment -4',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Claim_Date__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'less or equal',
								    	value_field__c = 'Value',
								    	reference__c = '2015-03-31 00:00:00',
								    	number__c = 40));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -5',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Claim_Date__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'greater or equal',
								    	value_field__c = 'Value',
								    	reference__c = '2015-03-31 00:00:00',
								    	number__c = 50));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -6',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Claim_Date__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'equals',
								    	value_field__c = 'Value',
								    	reference__c = '2015-03-31 00:00:00',
								    	number__c = 60));						    		
		insert lCriterias;						    								    							    	
    	
		boolean  answer = CriteriaService.evaluateCriteria(lCriterias,claim);
		system.assertEquals(answer,true);
	}
	
	static testMethod void CreiteriaServiceTest_DateTim() {//2015-03-31 07:00:00
		system.assert(tdf.periodList!=null);
		Claim__c claim = new Claim__c(Company__c = tdf.company.Id,
		    													Parent_Customer__c = tdf.customerParent.Id,
		    													Currency__c = TestFuel.currencyUSD.id,
		    													Type__c = 'MILITARY DIST PAYMENT',
		    													Claim_Date__c = Date.newInstance(2015,3,31),
		    													Last_Action__c = DateTime.newInstanceGMT(2015, 03, 31, 07, 00, 00),
		    													Amount__c = 100,
		    													Status__c = 'New');
		insert claim;
		List<Claim__c> sampleList = new List<Claim__c>();
		Process__c p = new Process__c();
    	p.Name = 'Military Payment';
    	p.Object__c = sampleList.getSObjectType().getDescribe().getName(); //'Claim__c';
    	p.Object_Step__c = Claim__c.Step__c.getDescribe().getName(); //'Step__c';
    	p.Active__c = true;
    	p.Automated__c = true;
    	p.After__c = true;
    	p.Insert__c = true;
    	p.State__c = 'ClaimHandler.ClaimState';
    	p.Sequence__c = 10;
    	insert p;
    	
    	list<Criteria__c> lCriterias = new list<Criteria__c>();
    	lCriterias.add(new Criteria__c(Name = 'Military Payment -1',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Last_Action__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'not equal to',
								    	value_field__c = 'Value',
								    	reference__c = '2015-03-31 21:44:01',
								    	number__c = 10));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -2',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Last_Action__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'less than',
								    	value_field__c = 'Value',
								    	reference__c = '2015-03-31 08:00:00',
								    	number__c = 20));	
		lCriterias.add(new Criteria__c(Name = 'Military Payment -3',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Last_Action__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'greater than',
								    	value_field__c = 'Value',
								    	reference__c = '2015-03-30 06:00:00',
								    	number__c = 30));	
		lCriterias.add(new Criteria__c(Name = 'Military Payment -4',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Last_Action__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'less or equal',
								    	value_field__c = 'Value',
								    	reference__c = '2015-03-31 07:00:00',
								    	number__c = 40));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -5',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Last_Action__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'greater or equal',
								    	value_field__c = 'Value',
								    	reference__c = '2015-03-30 07:00:00',
								    	number__c = 50));
		lCriterias.add(new Criteria__c(Name = 'Military Payment -6',
								    	Process__c = p.Id,
								    	//Manually write in the status field without the assumed namespace
								    	//The criteria evaluation should clean the namespace and prevent duplicate fields queried
								    	field__c = 'Last_Action__c',//Claim__Status__getDescribe().getName(), //'Status__c',
								    	operator__c = 'equals',
								    	value_field__c = 'Value',
								    	reference__c = '2015-03-31 07:00:00',
								    	number__c = 60));						    		
		insert lCriterias;						    								    							    	
    	
		boolean  answer = CriteriaService.evaluateCriteria(lCriterias,claim);
		system.assertEquals(answer,true);
	}
	
   
    
}