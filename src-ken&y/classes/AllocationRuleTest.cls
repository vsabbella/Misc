@isTest
private class AllocationRuleTest {
	public static TestFuel fuel = new TestFuel();
	public static Allocation_Rule__c allocationRule
	{
		get 
		{
			if(allocationRule == null)
			{
				allocationRule = new Allocation_Rule__c();
				allocationRule.Product__c = fuel.product.Id;
                allocationRule.Company__c = fuel.company.Id;
                allocationRule.Facility__c = fuel.facility2.Id;
                allocationRule.Customer__c  = fuel.customerParent.id;
                allocationRule.Allocation__c = 100;
                allocationRule.Business_Process_Type__c = 'OTC';
                allocationRule.Start_Date__c = System.today() - 30;
                allocationRule.End_Date__c = System.today() + 30;
                allocationRule.Type__c = 'Manual';
                
			}
			 return allocationRule;
		}
		set;
	}
	
	public static Allocation_Rule__c allocationRule1
	{
		get 
		{
			if(allocationRule1 == null)
			{
				allocationRule1 = new Allocation_Rule__c();
				allocationRule1.Product__c = fuel.product2.Id;
                allocationRule1.Company__c = fuel.company.Id;
                allocationRule1.Facility__c = fuel.facility2.Id;
                allocationRule1.Customer__c  = fuel.customerParent.id;
                allocationRule1.Allocation__c = 100;
                allocationRule1.Business_Process_Type__c = 'OTC';
                allocationRule1.Start_Date__c = System.today() - 30;
                allocationRule1.End_Date__c = System.today() + 30;
                allocationRule1.Type__c = 'Manual';
                
			}
			 return allocationRule1;
		}
		set;
	}
	
	
	public static Sales_Order__c salesOrderCurrent
	{
		get
		{
			if(salesOrderCurrent == null)
			{
				salesOrderCurrent = new Sales_Order__c();
		        salesOrderCurrent.Company__c = fuel.company.id;
		        salesOrderCurrent.Customer__c = fuel.customerSoldTo.id;   
		        salesOrderCurrent.Ship_To__c = fuel.customerShipTo.Id;
		        salesOrderCurrent.Payment_Term__c = fuel.terms.id;
		        salesOrderCurrent.Date_Time_Ordered__c = System.today().addDays(2); // in current year
		        
			}
			 return salesOrderCurrent;
	
		}
		set;
	}
	
	public static Sales_Order_Line__c salesOrderLine
	{
		get
		{
			if(salesOrderLine == null)
			{
				salesOrderLine = new Sales_Order_Line__c();
		        salesOrderLine = new Sales_Order_Line__c();
		        salesOrderLine.Product__c = fuel.product.Id;
		        salesOrderLine.Description__c = fuel.product.Description__c;
		        salesOrderLine.Company__c = fuel.company.id;
		        salesOrderLine.Sales_Order__c = salesOrderCurrent.Id;
		        salesOrderLine.Quantity_Ordered__c = 30;
		        salesOrderLine.Required_Date__c = System.today() + 5;
		        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
		       
			}
			return salesOrderLine;
		}
		set;
	}
	
	static testMethod void applyAllocation_Rule_CancelledStatus() //OTC-660
	{
		
		insert allocationRule;
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		
	    insert salesOrderCurrent;
	    salesOrderLine.Status__c = 'Cancelled';
	    insert salesOrderLine;
       
        salesOrderLine = [Select id, allocation_rule__c, has_exceptions__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.debug('test method, sol --> '+ salesOrderLine);
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(0, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
	}
	
	static testMethod void applyAllocation_Rule_Exceptions()
	{
		
		insert allocationRule;
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		
	    insert salesOrderCurrent;
	    salesOrderLine.Quantity_Ordered__c =101;
	    insert salesOrderLine;
       
        salesOrderLine = [Select id, allocation_rule__c, has_exceptions__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.debug('test method, sol --> '+ salesOrderLine);
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(101, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        
        Task t = [select Id, whatId from Task where WhatID = :salesOrderLine.Id limit 1];
        system.assertNotEquals(null,t,'Task exceptions as qty ordered above allocation limit on rule');
        
	}
	
	static testMethod void applyAllocation_Rule_ExceptionsOverride()
	{
		
		insert allocationRule;
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		
	    insert salesOrderCurrent;
	    salesOrderLine.Quantity_Ordered__c =101;
	    insert salesOrderLine;
       
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(101, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        Task t = [select Id, whatId from Task where WhatID = :salesOrderLine.Id limit 1];
        system.assertNotEquals(null,t,'Task exceptions as qty ordered above allocation limit on rule');
        t.Status = 'Overridden';
        update t;
        
         salesOrderLine.Quantity_Ordered__c =102;
	     update salesOrderLine;
	     
	     allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(102, allocationRule.Allocation_Used__c,'Allocations should have been used');
	}
	
	static testMethod void applyAllocation_Rule()
	{
		
		insert allocationRule;
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        
	}
	
	static testMethod void applyAllocation_deleteSOL() //OTC-625
	{
		
		insert allocationRule;
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        delete salesOrderLine;
        
         allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(0, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
	}
	
	static testMethod void applyAllocation_Rule_afterSOLcreated()
	{
		
		
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       	insert allocationRule;
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        
	}
	
	static testMethod void applyAllocation_Rule_updateRule_Product()
	{
		
		
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		insert allocationRule;
       
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       	 allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        allocationRule.Product__c = fuel.product2.Id;
        update allocationRule;
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        System.assertEquals(0, allocationRule.Allocation_Used__c,'Allocations used should reset to 0 as product ha changed');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(null, salesOrderLine.Allocation_Rule__c, 'The SOL should not have any rule associated');
	}
	
	static testMethod void applyAllocation_Rule_updateRule_Facility()
	{
		
		
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		insert allocationRule;
       
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       	 allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        allocationRule.Facility__c = fuel.facility.Id;
        update allocationRule;
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        System.assertEquals(0, allocationRule.Allocation_Used__c,'Allocations used should reset to 0 as product ha changed');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(null, salesOrderLine.Allocation_Rule__c, 'The SOL should not have any rule associated');
	}
	
	static testMethod void applyAllocation_Rule_updateRule_StartDate()
	{
		
		
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		insert allocationRule;
       
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       	 allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        allocationRule.Start_Date__c = System.today().addDays(20);
        update allocationRule;
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        System.assertEquals(0, allocationRule.Allocation_Used__c,'Allocations used should reset to 0 as product ha changed');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(null, salesOrderLine.Allocation_Rule__c, 'The SOL should not have any rule associated');
	}
	
	
	static testMethod void applyAllocation_Rule_updateSOLine_Product_2Rules()
	{
		
		
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		insert allocationRule;
		insert allocationRule1;
       
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       	 allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        salesOrderLine.Product__c = fuel.product2.ID;
        update salesOrderLine;
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
         System.assertEquals(0, allocationRule.Allocation_Used__c,'Allocations used should reset to 0 as product ha changed');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule1.Id, salesOrderLine.Allocation_Rule__c, 'The SOL should not have any rule associated');
	}
	
	
	
	static testMethod void applyAllocation_Rule_updateSOLine_StartDate()
	{
		
		
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		insert allocationRule;
       
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       	 allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        salesOrderLine.Estimated_Ship_Date__c = System.today().addDays(-40);
        update salesOrderLine;
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        System.assertEquals(0, allocationRule.Allocation_Used__c,'Allocations used should reset to 0 as product ha changed');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(null, salesOrderLine.Allocation_Rule__c, 'The SOL should not have any rule associated');
	}
	
	static testMethod void applyAllocation_Rule_updateSOLine_Facility()
	{
		
		
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		insert allocationRule;
       
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       	 allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        salesOrderLine.Ship_From_Location__c = fuel.location.Id;
        update salesOrderLine;
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        System.assertEquals(0, allocationRule.Allocation_Used__c,'Allocations used should reset to 0 as product ha changed');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(null, salesOrderLine.Allocation_Rule__c, 'The SOL should not have any rule associated');
	}
	
	static testMethod void applyAllocation_Rule_updateSOLine_Product()
	{
		
		
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		insert allocationRule;
       
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       	 allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        salesOrderLine.Product__c = fuel.product2.Id;
        update salesOrderLine;
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        System.assertEquals(0, allocationRule.Allocation_Used__c,'Allocations used should reset to 0 as product ha changed');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(null, salesOrderLine.Allocation_Rule__c, 'The SOL should not have any rule associated');
	}
	
	static testMethod void applyAllocation_Rule_updateRule_Customer()
	{
		
		
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		insert allocationRule;
       
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       	 allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        
        Customer__c customerParent = new Customer__c(); 
        customerParent.name = fuel.company.Name + ' Customer Corp Parent 2';
        customerParent.recordTypeId = fuel.CustomerRecordTypes.get('Corporate_Parent');
        customerParent.Company__c = fuel.company.id;
        customerParent.Payment_Term__c = fuel.terms.ID;
        //customerParent.Address__c = fuel.account.ID;
        customerParent.Credit_Limit__c = 100000.0;
        customerParent.Customer_Identifier__c = 'CPTEST1231';
        customerParent.Record_Type_Name__c = 'Corporate_Parent'; 
        insert customerParent;
        
        allocationRule.Customer__c = customerParent.Id;
        update allocationRule;
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        System.assertEquals(0, allocationRule.Allocation_Used__c,'Allocations used should reset to 0 as product ha changed');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(null, salesOrderLine.Allocation_Rule__c, 'The SOL should not have any rule associated');
	}
	
	static testMethod void applyAllocation_Rule_updateSOLine_Customer()
	{
		
		
	    
	    fuel.customerSoldTo.Top_Parent_Customer__c = fuel.customerParent.Id;
		update fuel.customerSoldTo;
		insert allocationRule;
       
	    insert salesOrderCurrent;
	    insert salesOrderLine;
       	 allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        
        System.assertEquals(30, allocationRule.Allocation_Used__c,'Allocations should have been used');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(allocationRule.ID, salesOrderLine.Allocation_Rule__c, 'The SOL should have any AR associated');
        
        
        Customer__c customerParent = new Customer__c(); 
        customerParent.name = fuel.company.Name + ' Customer Corp Parent 2';
        customerParent.recordTypeId = fuel.CustomerRecordTypes.get('Corporate_Parent');
        customerParent.Company__c = fuel.company.id;
        customerParent.Payment_Term__c = fuel.terms.ID;
        //customerParent.Address__c = fuel.account.ID;
        customerParent.Credit_Limit__c = 100000.0;
        customerParent.Customer_Identifier__c = 'CPTEST1231';
        customerParent.Record_Type_Name__c = 'Corporate_Parent'; 
        insert customerParent;
        
        Customer__c customerBillTo = new Customer__c(); 
        customerBillTo.name = 'Customer Bill To 1';
        customerBillTo.recordTypeId = fuel.CustomerRecordTypes.get('Bill_To');
        customerBillTo.Company__c = fuel.company.id;
        customerBillTo.Payment_Term__c = fuel.terms.ID;
        //customerBillTo.Address__c = fuel.account.ID;
        customerBillTo.Credit_Limit__c = 100000.0;
        customerBillTo.Parent_Customer__c = customerParent.id; 
        customerBillTo.Top_Parent_Customer__c = customerParent.id;
        customerBillTo.Customer_Identifier__c = 'BDTEST1231'; 
        insert customerBillTo;
        
        Customer__c customerSoldTo = new Customer__c(); 
        customerSoldTo.name = 'Customer Sold To 1';
        customerSoldTo.recordTypeId = fuel.CustomerRecordTypes.get('Sold_To');
        customerSoldTo.Company__c = fuel.company.id;
        customerSoldTo.Payment_Term__c = fuel.terms.ID;
        //customerSoldTo.Address__c = fuel.account.ID;
        customerSoldTo.Credit_Limit__c = 100000.0;
        customerSoldTo.Parent_Customer__c = customerBillTo.id; 
        customerSoldTo.Top_Parent_Customer__c = customerParent.id; 
        customerSoldTo.Customer_Identifier__c = 'SDTEST1231'; 
        customerSoldTo.pricebook__c = fuel.pricebook.id;
        insert customerSoldTo;
        
        Customer__c shipTo = new Customer__c(); 
        shipTo.name = 'Customer Ship To 2';
        shipTo.recordTypeId = fuel.CustomerRecordTypes.get('Ship_To');
        shipTo.Company__c = fuel.company.id;
        shipTo.Payment_Term__c = fuel.terms.ID;
        //shipTo.Address__c = fuel.account.ID;
        shipTo.Credit_Limit__c = 100000.0;
        shipTo.Parent_Customer__c = customerSoldTo.id;
        shipTo.Customer_Identifier__c = 'SHTEST123';  
       // cst.Business_Hours__c = [select Id from BusinessHours where isDefault = true limit 1].Id;
        
        salesOrderCurrent.Customer__c = customerSoldTo.id;
        salesOrderCurrent.Ship_To__c = shipTo.id;
        update salesOrderCurrent;
        
        allocationRule = [SELECT Id, Start_date__c, End_date__c, 
                                 Allocation__c, Allocation_Used__c, Facility__c 
                            FROM Allocation_Rule__c 
                           WHERE Id = :allocationRule.Id 
                           LIMIT 1];
        System.assertEquals(0, allocationRule.Allocation_Used__c,'Allocations used should reset to 0 as product ha changed');
        
        salesOrderLine = [Select id, allocation_rule__c from Sales_Order_Line__c where id =:salesOrderLine.id limit 1];
        system.assertEquals(null, salesOrderLine.Allocation_Rule__c, 'The SOL should not have any rule associated');
	}

    
}