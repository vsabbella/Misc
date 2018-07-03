@isTest 	
public with sharing class ExceptionTasksExtNewTest {
		
		public static testMethod void ExceptionTasksTest() {
			TestFuel data = new TestFuel();
			
			Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
		    custInvLine1.Company__c = data.company.id;
		    custInvLine1.Quantity_Shipped__c = 2;
		    custInvLine1.Unit_Price__c = 7;
		    custInvLine1.Product__c = data.product.id ; 
		    custInvLine1.Discount_Percent__c = 0.2;
		    custInvLine1.Customer_Invoice__c = data.custInv1.id;
		    custInvLine1.Extended_Price__c = custInvLine1.Quantity_Shipped__c * custInvLine1.Unit_Price__c;
		    
		    insert custInvLine1;
		    
			ExceptionTasksExtNew con = new ExceptionTasksExtNew();
			con.parent = data.custInv1;
			String type = con.parentType;
			
			ExceptionService exService = new ExceptionService();
			exService.setException(data.custInv1,ExceptionUtil.SO_INVOICE_LINE_PRICE_MISMATCH);
			exService.setException(custInvLine1,ExceptionUtil.PRODUCT_IS_BLOCKED);
			exService.setException(custInvLine1,ExceptionUtil.PRODUCT_IS_MISSING_VALID_PRICE);
			exService.finishTasks();
			
			System.assert(con.getFieldList() != null);

		}
		
		public static testMethod void MassOverride_withNoProhibitOverride()
		{
			TestFuel fuel = new TestFuel();
			
			Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
			CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
            CustomerInvoice.Company__c = fuel.company.Id;
            CustomerInvoice.Invoice_Type__c = 'Manual';
            CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
            CustomerInvoice.Date_Invoiced__c = system.now();
            CustomerInvoice.Currency__c = TestFuel.currencyUSD.id;
            CustomerInvoice.Transaction_Date__c = Date.today();
			//CustomerInvoice.Finalized__c =true;
			insert CustomerInvoice;
			
			Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
			cil.Customer_Invoice__c = CustomerInvoice.Id;
			cil.Quantity_Shipped__c = 1;
			cil.Unit_Price__c = 100;
			insert cil;
			
			CustomerInvoice.Finalized__c = true;
			update CustomerInvoice;
			
			list<Task> tasks = new list<Task>();
			tasks.add(new Task(whatId = CustomerInvoice.Id, Subject = 'tasks with no override', Type = 'Exception', Exception_Code__c = 'someCode1', Status = 'Open', Prohibit_Override__c = false));
			tasks.add(new Task(whatId = CustomerInvoice.Id, Subject = 'tasks with  override', Type = 'Exception', Exception_Code__c = 'someCode2', Status = 'Open', Prohibit_Override__c = false));
			
			insert tasks;
			
			ExceptionTasksExtNew con = new ExceptionTasksExtNew();
			con.parent = CustomerInvoice;
			String type = con.parentType;
			
			
			System.assert(con.getFieldList() != null);
			TasksMassOverride overrideExt = new TasksMassOverride(con);
			
			JSONResult result = TasksMassOverride.massOverrideTasks(tasks);
			system.assertEquals(result.success, true,'We expect none to fail the update');
			//system.assertEquals(result.messages.size(),1);
			
			
			for(Task t: [Select Id, isClosed, Prohibit_Override__c from Task where id in :tasks])
			{
				if(t.Prohibit_Override__c)
					system.assertEquals(t.isClosed,false);
				//else
				//	system.assertEquals(t.isClosed,true);
			}
			
		}
		
		
		public static testMethod void MassOverride_withProhibitOverride()
		{
			TestFuel fuel = new TestFuel();
			
			Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
			CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
            CustomerInvoice.Company__c = fuel.company.Id;
            CustomerInvoice.Invoice_Type__c = 'Manual';
            CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
            CustomerInvoice.Date_Invoiced__c = system.now();
            CustomerInvoice.Currency__c = TestFuel.currencyUSD.id;
            CustomerInvoice.Transaction_Date__c = Date.today();
			//CustomerInvoice.Finalized__c =true;
			insert CustomerInvoice;
			
			Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
			cil.Customer_Invoice__c = CustomerInvoice.Id;
			cil.Quantity_Shipped__c = 1;
			cil.Unit_Price__c = 100;
			insert cil;
			
			CustomerInvoice.Finalized__c = true;
			update CustomerInvoice;
			
			list<Task> tasks = new list<Task>();
			tasks.add(new Task(whatId = CustomerInvoice.Id, Subject = 'tasks with no override', Type = 'Exception', Exception_Code__c = 'someCode1', Status = 'Open', Prohibit_Override__c = false));
			tasks.add(new Task(whatId = CustomerInvoice.Id, Subject = 'tasks with  override', Type = 'Exception', Exception_Code__c = 'someCode2', Status = 'Open', Prohibit_Override__c = true));
			
			insert tasks;
			
			ExceptionTasksExtNew con = new ExceptionTasksExtNew();
			con.parent = CustomerInvoice;
			String type = con.parentType;
			
			
			System.assert(con.getFieldList() != null);
			TasksMassOverride overrideExt = new TasksMassOverride(con);
			
			JSONResult result = TasksMassOverride.massOverrideTasks(tasks);
			system.assertEquals(result.success, false,'We expect one to fail the update');
			system.assertEquals(result.messages.size(),1);
			
			
			for(Task t: [Select Id, isClosed, Prohibit_Override__c from Task where id in :tasks])
			{
				if(t.Prohibit_Override__c)
					system.assertEquals(t.isClosed,false);
				//else
				//	system.assertEquals(t.isClosed,true);
			}
			
		}
}