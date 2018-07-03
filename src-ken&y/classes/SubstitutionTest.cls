/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for Substitution__c object.
 */
 
//	Tests to perform:
//  1. Assert that Start date must be before End date.
//  2. Assert that Start range is not overlapped for similar rules.
//	3. Assert that only the rule active currently is being use. Not the past or future rules.
//	4. Assert that the most specific rule is chosen and falls back to generic rules if not available.
//	5. Assert that reason code is of type substitution.

@isTest
private class SubstitutionTest {
	
	static TestData globalTestData = new TestData();
	
	class SubstitutionTestData {
		
		// Create a substitution rule for Product-10 as primary (registered) product in the UPC group.
		public Substitution__c sub {
			get{
				if(sub == null){
					sub = new Substitution__c();
					sub.Name='Primary Product Sub';
					sub.Current_Product__c = globalTestData.product.Id;
                    sub.Start_Date__c = system.today()-1;
					sub.End_Date__c = system.today() + 720;
				}
				return sub;
			}
			set;
		}
		
		// Create a substitution rule to ALWAYS substitute Product-10 with Product-15.
		public Substitution__c sub2 {
			get{	
				if(sub2 == null){
					sub2 = new Substitution__c();
					sub2.Name='Secondary Product Sub';
					sub2.Current_Product__c = globalTestData.product2.Id;
					sub2.Substitute_Product__c = globalTestData.product.Id;
                    sub2.Start_Date__c = system.today()-1;
					sub2.End_Date__c = system.today() + 720;	
				}
				return sub2;
			}
			set;
		}
							  
		
		{	
			// Make sure that the two products have the same UPC code
			globalTestData.product2.UPC_Code__c = globalTestData.product.UPC_Code__c;
			update globalTestData.product2;
						
			// Initializes and inserts subtitution records.				  
			insert new List<Substitution__c>{sub, sub2};			
			
			// Assert that the records have been inserted.
			system.assert(sub.Id != null && sub2.Id != null );
			
		}
							  
	}
	
	//  KNDY-2122: Test the basic substitution functionality where the substitution rule is found correctly and 
	//	the product on the sales order line is substituted with another similar product.
	static testMethod void testProductSubstitution() {
    	
    	Test.startTest();
    	
    	SubstitutionTestData localTestData = new SubstitutionTestData();
    	
    	// Make sure the ordered date is within substitution rule's effective range.
    	globalTestData.salesOrder.Date_Time_Ordered__c = System.now();
    	update globalTestData.salesOrder;
    	
    	// Change the product to "Product-15" on all the so lines.
        List<Sales_Order_Line__c> updatedSOLines = new List<Sales_Order_Line__c>();
    	for(Sales_Order_Line__c sol : globalTestData.salesOrder.Sales_Order_Lines__r){
        	if(sol.Product__c != globalTestData.product2.Id){ 
        		sol.Product__c = globalTestData.product2.Id;
        		updatedSOLines.add(sol);
        	}
        }
        
        // Assert that atleast one sales order line is updated to test.
        system.assertNotEquals(0, updatedSOLines.size(), 'No lines were updated to Product-10 for testing');
        update updatedSOLines;
        
        for(Sales_Order_Line__c sol : [select Id, Product__c from Sales_Order_Line__c where Id IN :updatedSOLines]){
        	// Assert that the Product-15 is substituted with Product-10
        	system.assertEquals(globalTestData.product.Id, sol.Product__c);
        }
        
    }
    
    // KNDY-2122: Test that if the primary product is blocked, then the secondary products are blocked too, unless,
    // there is a more specific rule for that product.
    static testMethod void testPrimaryProductBlock() {
    	
    	Test.startTest();
    	
    	SubstitutionTestData localTestData = new SubstitutionTestData();
    	localTestData.sub.Block__c = true;
    	update localTestData.sub;
    	
    	// Make sure the ordered date is within substitution rule's effective range.
    	globalTestData.salesOrder.Date_Time_Ordered__c = System.now();
    	update globalTestData.salesOrder;
    	
    	// Make Product-10 primary product of the UPC group.
    	globalTestData.product.Primary__c = true;
    	update globalTestData.product;
    	
    	SalesOrderFlowCache.flush(Product__c.sObjectType);
    	
    	// Change the product to "Product-15" on all the so lines.
        List<Sales_Order_Line__c> updatedSOLines = new List<Sales_Order_Line__c>();
    	for(Sales_Order_Line__c sol : globalTestData.salesOrder.Sales_Order_Lines__r){
        	if(sol.Product__c != globalTestData.product2.Id){ 
        		sol.Product__c = globalTestData.product2.Id;
        		updatedSOLines.add(sol);
        	}
        }
        
        // Assert that atleast one sales order line is updated to test.
        system.assertNotEquals(0, updatedSOLines.size(), 'No lines were updated to Product-10 for testing');
        update updatedSOLines;
        
        for(Sales_Order_Line__c sol : [select Id, Product__c, Has_Exceptions__c
        								 from Sales_Order_Line__c 
        								where Id IN :updatedSOLines]){
        	// Assert that the Product-10 is substituted with Product-15
        	system.assert(sol.Has_Exceptions__c);
        	system.assertEquals(globalTestData.product2.Id, sol.Product__c);
        	system.assertEquals(true, ExceptionService.hasOpenTask(sol.Id, ExceptionUtil.PRODUCT_IS_BLOCKED.code));
        }
        
        Product__c product3 = globalTestData.product2.clone();
    	product3.Name = 'Product-11';
    	insert product3;
    	
        Substitution__c sub3 = new Substitution__c(
								  Name='SUB-3',
								  Facility__c = globalTestData.facility2.Id,
								  Current_Product__c = globalTestData.product.Id,
								  Substitute_Product__c = product3.Id,
                                  Start_Date__c = system.today()-1,
								  End_Date__c = system.today() + 720
							   );
    	insert sub3;
        
        // Change the product to "Product-10" on all the so lines.
        for(Sales_Order_Line__c sol : updatedSOLines){
    		sol.Product__c = globalTestData.product.Id;
        }
        
        // Assert that atleast one sales order line is updated to test.
        system.assertNotEquals(0, updatedSOLines.size(), 'No lines were updated to Product-10 for testing');
        update updatedSOLines;
        
        for (Sales_Order_Line__c sol : [SELECT Id, Product__c, Has_Exceptions__c, Description__c
        								  FROM Sales_Order_Line__c WHERE Id IN :updatedSOLines]){
        	// Assert that the Product-10 is substituted with Product-15
            System.assertEquals(product3.Description__c, sol.Description__c);
        	system.assertEquals(product3.Id, sol.Product__c, 'Expected the product to get substituted.');
        }
    }
    
    //	KNDY-2122: Test the substitution for a product and facility.
	static testMethod void testFacilityProductSubstitution() {
    	
    	Test.startTest();
    	
    	SubstitutionTestData localTestData = new SubstitutionTestData();
    	
    	Product__c product3 = globalTestData.product2.clone();
    	product3.Name = 'Product-11';
    	insert product3;
    	
    	Substitution__c sub3 = new Substitution__c(
								  Name='SUB-3',
								  Facility__c = globalTestData.facility2.Id,
								  Current_Product__c = globalTestData.product.Id,
								  Substitute_Product__c = product3.Id,
                                  Start_Date__c = system.today()-1,
								  End_Date__c = system.today() + 720
								  );
    	insert sub3;
    	
    	// Make sure the ordered date is within substitution rule's effective range.
    	globalTestData.salesOrder.Date_Time_Ordered__c = System.now();
    	globalTestData.salesOrder.Ship_From_Location__c = null;
    	update globalTestData.salesOrder;
    	
    	// Change the product to "Product-10" on all the so lines.
        List<Sales_Order_Line__c> updatedSOLines = new List<Sales_Order_Line__c>();
    	for(Sales_Order_Line__c sol : globalTestData.salesOrder.Sales_Order_Lines__r){
        	if(sol.Product__c != globalTestData.product.Id){ 
        		sol.Product__c = globalTestData.product.Id;
        		sol.Ship_From_Location__c = null;
        		updatedSOLines.add(sol);
        	}
        }
        
        // Assert that atleast one sales order line is updated to test.
        system.assertNotEquals(0, updatedSOLines.size(), 'No lines were updated to Product-10 for testing');
        update updatedSOLines;
        
        for(Sales_Order_Line__c sol : [select Id, Product__c from Sales_Order_Line__c where Id IN :updatedSOLines]){
        	// Assert that the Product-10 is substituted with Product-11
        	system.assertEquals(globalTestData.product.Id, sol.Product__c);
        }
        
        for(Sales_Order_Line__c sol : updatedSOLines){
        	sol.Ship_From_Location__c = globalTestData.location2.Id;
        }
        update updatedSOLines;
         
        for(Sales_Order_Line__c sol : [select Id, Product__c from Sales_Order_Line__c where Id IN :updatedSOLines]){
        	// Assert that the Product-10 is substituted with Product-11
        	system.assertEquals(product3.Id, sol.Product__c);
        }
        
    }
    
    // OTC-593
    static testMethod void testFacilityProductSubstitutionPriceError() {
    	
    	Test.startTest();
    	
    	SubstitutionTestData localTestData = new SubstitutionTestData();

  	
    	// Make sure the ordered date is within substitution rule's effective range.
    	globalTestData.salesOrder.Date_Time_Ordered__c = System.now();
    	globalTestData.salesOrder.Ship_From_Location__c = null;
    	update globalTestData.salesOrder;
    	
    	
    	
    	for(Sales_Order_Line__c sol : [select Id, Product__c, Unit_Price__c, Pricebook__c from Sales_Order_Line__c where Id 
    									IN :globalTestData.salesOrder.Sales_Order_Lines__r]){
        	system.assertNotEquals(null, sol.Unit_Price__c);
        	system.assertNotEquals(null, sol.Pricebook__c);
        	system.debug(LoggingLevel.INFO, sol);
        }
    	
        List<Sales_Order_Line__c> updatedSOLines = new List<Sales_Order_Line__c>();
    	for(Sales_Order_Line__c sol : globalTestData.salesOrder.Sales_Order_Lines__r){
    		sol.Ship_From_Location__c = null;
    		updatedSOLines.add(sol);
    	}
        
        // Assert that atleast one sales order line is updated to test.
        system.assertNotEquals(0, updatedSOLines.size(), 'No lines were updated to Product-10 for testing');
        update updatedSOLines;
        
        for(Sales_Order_Line__c sol : [select Id, Product__c, Unit_Price__c, Pricebook__c from Sales_Order_Line__c where Id IN :updatedSOLines]){
        	system.assertNotEquals(null, sol.Unit_Price__c);
        	system.assertNotEquals(null, sol.Pricebook__c);
        	system.debug(LoggingLevel.INFO, sol);
        	
        }
        
        for(Sales_Order_Line__c sol : updatedSOLines){
        	sol.Ship_From_Location__c = globalTestData.location2.Id;
        }
        update updatedSOLines;
         
        for(Sales_Order_Line__c sol : [select Id, Product__c, Unit_Price__c, Pricebook__c from Sales_Order_Line__c where Id IN :updatedSOLines]){
        	system.assertNotEquals(null, sol.Unit_Price__c);
        	system.assertNotEquals(null, sol.Pricebook__c);
        	system.debug(LoggingLevel.INFO, sol);
        	
        }
        
    }
    
    //	KNDY-2122: Test the substitution for a customer and product.
	static testMethod void testCustomerProductSubstitution() {
    	
    	Test.startTest();
    	
    	SubstitutionTestData localTestData = new SubstitutionTestData();
    	
    	Product__c product3 = globalTestData.product2.clone();
    	product3.Name = 'Product-11';
    	insert product3;
    	
    	Substitution__c sub3 = new Substitution__c(
								  Name='SUB-3',
								  Customer__c = globalTestData.customerShipTo.Id, // Ship-to customer
								  Current_Product__c = globalTestData.product.Id,
								  Substitute_Product__c = product3.Id,
                                  Start_Date__c = system.today()-1,
								  End_Date__c = system.today() + 720
								  );
    	insert sub3;
    	
    	// Make sure the ordered date is within substitution rule's effective range.
    	globalTestData.salesOrder.Date_Time_Ordered__c = System.now();
    	update globalTestData.salesOrder;
    	
    	// Change the product to "Product-10" on all the so lines.
        List<Sales_Order_Line__c> updatedSOLines = new List<Sales_Order_Line__c>();
    	for(Sales_Order_Line__c sol : globalTestData.salesOrder.Sales_Order_Lines__r){
        	if(sol.Product__c != globalTestData.product.Id){ 
        		sol.Product__c = globalTestData.product.Id;
        		updatedSOLines.add(sol);
        	}
        }
        
        // Assert that atleast one sales order line is updated to test.
        system.assertNotEquals(0, updatedSOLines.size(), 'No lines were updated to Product-10 for testing');
        update updatedSOLines;
        
        for(Sales_Order_Line__c sol : [select Id, Product__c from Sales_Order_Line__c where Id IN :updatedSOLines]){
        	// Assert that the Product-10 is substituted with Product-11
        	system.assertEquals(product3.Id, sol.Product__c);
        }
        
    }
    
    //	KNDY-2122: Test the substitution for a customer, facility and product.
	static testMethod void testFacilityCustomerProductSubstitution() {
    	
    	Test.startTest();
    	
    	SubstitutionTestData localTestData = new SubstitutionTestData();
    	
    	Product__c product3 = globalTestData.product2.clone();
    	product3.Name = 'Product-11';
    	insert product3;
    	
    	Substitution__c sub3 = new Substitution__c(
								  Name='SUB-3',
								  Facility__c = globalTestData.facility2.Id,
								  Customer__c = globalTestData.customer.Id,
								  Current_Product__c = globalTestData.product.Id,
								  Substitute_Product__c = product3.Id,
                                  Start_Date__c = system.today()-1,
								  End_Date__c = system.today() + 720
								  );
    	insert sub3;
    	
    	// Make sure the ordered date is within substitution rule's effective range.
    	globalTestData.salesOrder.Date_Time_Ordered__c = System.now();
    	globalTestData.salesOrder.Ship_From_Location__c = null;
    	update globalTestData.salesOrder;
    	
    	// Change the product to "Product-10" on all the so lines.
        List<Sales_Order_Line__c> updatedSOLines = new List<Sales_Order_Line__c>();
    	for(Sales_Order_Line__c sol : globalTestData.salesOrder.Sales_Order_Lines__r){
        	if(sol.Product__c != globalTestData.product.Id){ 
        		sol.Product__c = globalTestData.product.Id;
        		updatedSOLines.add(sol);
        	}
        }
        
        // Assert that atleast one sales order line is updated to test.
        system.assertNotEquals(0, updatedSOLines.size(), 'No lines were updated to Product-10 for testing');
        update updatedSOLines;
        
        for(Sales_Order_Line__c sol : [select Id, Product__c from Sales_Order_Line__c where Id IN :updatedSOLines]){
        	// Assert that the Product-10 is substituted with Product-11
        	system.assertEquals(product3.Id, sol.Product__c);
        }
        
    }
    
    //	KNDY-2122: Test skipping substitution for a sold-to customer for any facility and any product.
	static testMethod void testSkipProductSubstitution() {
    	
    	Test.startTest();
    	
    	SubstitutionTestData localTestData = new SubstitutionTestData();
    	
    	Product__c product3 = globalTestData.product2.clone();
    	product3.Name = 'Product-11';
    	insert product3;
    	
    	Substitution__c sub3 = new Substitution__c(
								  Name='SUB-3',
								  Facility__c = globalTestData.facility.Id,
								  Customer__c = globalTestData.customer.Id,
								  Current_Product__c = globalTestData.product.Id,
								  Substitute_Product__c = product3.Id,
                            	  Start_Date__c = system.today()-1,
								  End_Date__c = system.today() + 720
								  );
    	insert sub3;
    	
    	// Make sure the ordered date is within substitution rule's effective range.
    	globalTestData.salesOrder.Date_Time_Ordered__c = System.now();
    	update globalTestData.salesOrder;
    	
    	// Set the skip subtitution flag on the sold-to customer.
    	globalTestData.customer.Skip_Substitution__c = true;
    	update globalTestData.customer;
    	
    	// Change the product to "Product-10" on all the so lines.
        List<Sales_Order_Line__c> updatedSOLines = new List<Sales_Order_Line__c>();
    	for(Sales_Order_Line__c sol : globalTestData.salesOrder.Sales_Order_Lines__r){
        	if(sol.Product__c != globalTestData.product.Id){ 
        		sol.Product__c = globalTestData.product.Id;
        		sol.Ship_From_Location__c = globalTestData.location.Id;
        		updatedSOLines.add(sol);
        	}
        }
        
        // Assert that atleast one sales order line is updated to test.
        system.assertNotEquals(0, updatedSOLines.size(), 'No lines were updated to Product-10 for testing');
        update updatedSOLines;
        
        for(Sales_Order_Line__c sol : [select Id, Product__c from Sales_Order_Line__c where Id IN :updatedSOLines]){
        	// Assert that the Product-10 is not substituted
        	system.assertEquals(globalTestData.product.Id, sol.Product__c);
        }
    }
    
    // OTC-447: Test that substitution is triggered when one of 
    // the following fields are changed on the sales order lines.
    // 1. Product
	// 2. Estimated Ship Date
	// 3. Ship From Location
	static testMethod void testSubstitutionOnUpdate() {
    	
    	Test.startTest();
    	
    	//SubstitutionTestData localTestData = new SubstitutionTestData();
    	
    	Product__c product3 = globalTestData.product.clone();
    	product3.Name = 'Product-11';
    	insert product3;
    	
    	Substitution__c sub3 = new Substitution__c(
								  Name='SUB-3',
								  Facility__c = globalTestData.facility2.Id,
								  Customer__c = globalTestData.customer.Id,
								  Current_Product__c = globalTestData.product.Id,
								  Substitute_Product__c = product3.Id,
                            	  Start_Date__c = system.today()-1,
								  End_Date__c = system.today() + 720
								  );
    	insert sub3;
    	
    	List<Sales_Order_Line__c> solList = [select Id, Product__r.Name 
											   from Sales_Order_Line__c 
										      where Id IN :globalTestData.salesOrder.Sales_Order_Lines__r 
										      order by Line__c];
    	
    	// Change the product to "Product-10" on all the so lines.
        List<Sales_Order_Line__c> updatedSOLines = new List<Sales_Order_Line__c>();
    	for(Sales_Order_Line__c sol : solList){
        	if(sol.Product__c != globalTestData.product.Id){ 
        		sol.Product__c = globalTestData.product.Id;
        		updatedSOLines.add(sol);
        	}
        }
        
        // Assert that atleast one sales order line is updated to test.
        system.assertNotEquals(0, updatedSOLines.size(), 'No lines were updated to Product-10 for testing');
        
        // Clear the ship from location and required date (which should clear the estimated ship date).
    	solList[0].Ship_From_Location__c = null;
    	solList[1].Required_Date__c = system.today() - 5;
    	
        update solList;
        
        solList = [select Id, Product__r.Name 
					 from Sales_Order_Line__c 
				    where Id IN :solList order by Line__c];
        												   
        for(Sales_Order_Line__c sol : solList){
        	// Assert that the Product-10 is not substituted with Product-11
        	system.assertEquals(globalTestData.product.Id, sol.Product__c,
        			'Did not expect product to be substituted: ' + sol.Product__r.Name);
        }
        
        solList[0].Ship_From_Location__c = globalTestData.location1.Id;
        solList[1].Required_Date__c = system.today() + 5;
    	update solList;
    	
    	solList = [select Id, Product__r.Name 
					 from Sales_Order_Line__c 
				    where Id IN :solList order by Line__c];
        
        for(Sales_Order_Line__c sol : solList){
        	// Assert that the Product-10 is substituted with Product-11
        	system.assertEquals(product3.Id, sol.Product__c, 
        			'Expected product to be substituted: ' + sol.Product__r.Name);
        }
    }
}