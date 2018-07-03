@isTest
private class CustomerServiceTest {
	
	public testmethod static void testDefaultBillToValidationRule() {

		TestFuel fuel = new TestFuel(); 
		fuel.customerParent.Default_Bill_To_Customer__c = fuel.customerSoldTo.Id;
        boolean errorFound = false;
        try {
			update fuel.customerParent;
        }catch(Exception ex) {
			system.assert(ex.getMessage().contains('The Default Bill To Customer must be related to Corporate Parent Customer and have a \'Bill To\' record type.'));
        	errorFound = true;
        }
        
        system.assertEquals(true, errorFound);
        
	}

	public testmethod static void testValidateUseFixedPricing() {

		TestFuel fuel = new TestFuel(); 

		// Implement brackets
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(fuel.company));
        
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        System.assertEquals(5, bracketWraps.size());
        for (BracketPricingUpchargeManageExt.BracketPriceWrapper wrap : bracketWraps) {
            System.assertEquals(null, wrap.reasonCode.Id);
            System.assertEquals(BracketPricingService.TypeBracketPricingUpcharge, wrap.reasonCode.Type__c);
            System.assertEquals(fuel.company.Id, wrap.reasonCode.Company__c);
            System.assertEquals('Price__c', wrap.pricebookLineField);
            System.assert(wrap.volumeRangeBottom == null || wrap.volumeRangeBottom == 0);
            System.assert(wrap.percentUpcharge == null || wrap.percentUpcharge == 0);
        }
        
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2,brack3,brack4,brack5;
        
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 200;
        brack1.percentUpcharge = 0;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 150;
        brack2.percentUpcharge = 1;
        brack2.pricebookLineField = 'Price_2__c';

        // Create bracket 3
        brack3 = bracketWraps[2];
        brack3.inUse = true;
        brack3.volumeRangeBottom = 100;
        brack3.percentUpcharge = 2;
        brack3.pricebookLineField = 'Price_3__c';

        // Create bracket 4
        brack4 = bracketWraps[3];
        brack4.inUse = true;
        brack4.volumeRangeBottom = 50;
        brack4.percentUpcharge = 3;
        brack4.pricebookLineField = 'Price_4__c';

        // Create bracket 5
        brack5 = bracketWraps[4];
        brack5.inUse = true;
        brack5.volumeRangeBottom = 0;
        brack5.percentUpcharge = 4;
        brack5.pricebookLineField = 'Price_5__c';

        // Persist to DB
        ext.onSave();
		
		// Reload extension to verify
        ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(fuel.company));
	    
	    Pricebook__c pricebook = new Pricebook__c(); 
	    pricebook.Name = fuel.company.Name +  ' Orange Pricebook2';
	    pricebook.Company__c = fuel.company.Id; 
	    insert pricebook; 

	    Pricebook_Line__c pl = new Pricebook_Line__c();
	    pl.Product__c = fuel.product.Id;
	    pl.Pricebook__c = pricebook.Id;
	    pl.Use_Fixed_Pricing__c = false;
	    pl.Price__c = 10;
	    pl.Start_date__c = System.today(); 
	    
	    Pricebook_Line__c pl2 = new Pricebook_Line__c();
	    pl2.Product__c = fuel.product3.Id;
	    pl2.Pricebook__c = pricebook.Id;
	    pl2.Use_Fixed_Pricing__c = false;
	    pl2.Price__c = 20;
	    pl2.Start_date__c = System.today();
	    	
	    insert new List<Pricebook_Line__c>{pl,pl2};

	    Test.startTest();

		Map<Id, Pricebook_Line__c> pbLinesById = new Map<Id, Pricebook_Line__c>([SELECT Price_2__c, Price_3__c, Price_4__c, Price_5__c 
	                                                                             FROM Pricebook_Line__c WHERE Id IN :new Set<Id>{pl.Id, pl2.Id}]);
	 	Pricebook_Line__c plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id =:pl.Id];
  		System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);
        
  		//Check that our pricing is working properly
        System.assertEquals(10.1, plReloaded.Price_2__c);
        System.assertEquals(10.2, plReloaded.Price_3__c);
        System.assertEquals(10.3, plReloaded.Price_4__c);
        System.assertEquals(10.4, plReloaded.Price_5__c);


		Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;   
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        salesOrder.pricebook__c = pricebook.id;// make sure its pointing to normal pricebook
        insert salesOrder;

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 5;
        salesOrderLine.Required_Date__c = System.today() + 5;
        insert salesOrderLine;
        
        //Check the line price:
        Sales_Order__c SO1 = [SELECT Id, Bracket_Price_Field_In_Use__c, Total_Product_Weight__c FROM Sales_Order__c WHERE Id = :salesOrder.Id LIMIT 1];
        System.assert(SO1.Bracket_Price_Field_In_Use__c.contains('Price_4__c'));
        Sales_Order_Line__c SOL1 = [SELECT Id, Unit_Price__c, Quantity_Ordered__c FROM Sales_Order_Line__c WHERE Id = :salesOrderLine.Id LIMIT 1];
        system.assert(SOL1.Unit_Price__c == 10.3);
        system.debug(LoggingLevel.INFO, SO1);
        system.debug(LoggingLevel.INFO, SOL1);

        Sales_Order_Line__c salesOrderLineP3 = new Sales_Order_Line__c();
        salesOrderLineP3.Product__c = fuel.product3.Id; // this is product 3, which should come from national pricebook
        salesOrderLineP3.Description__c = fuel.product.Description__c;
        salesOrderLineP3.Company__c = fuel.company.id;
        salesOrderLineP3.Sales_Order__c = salesOrder.Id;
        salesOrderLineP3.Quantity_Ordered__c = 10;
        salesOrderLineP3.Required_Date__c = System.today() + 5;
        insert salesOrderLineP3;
 		

        for ( Sales_Order__c SO : [SELECT Id, Bracket_Price_Field_In_Use__c, Total_Product_Weight__c,
							 	    (SELECT Id, Quantity_Ordered__c, Unit_Price__c, Product__c FROM Sales_Order_Lines__r)
							 	   FROM Sales_Order__c WHERE Id = :salesOrder.Id]){

	        for (Sales_Order_Line__c SOL : SO.Sales_Order_Lines__r){
				System.debug(LoggingLevel.INFO, SOL);
				// Product - 10.2, Product3 - 20.4
				System.assert(SOL.Unit_Price__c == 10.2 || SOL.Unit_Price__c == 20.4 );      		
	        }
        	System.debug(LoggingLevel.INFO, SO);
        	System.assert(SO.Bracket_Price_Field_In_Use__c.contains('Price_3__c'));
		}

        // Customer SoldTo - Use Fixed Pricing
		Customer__c customerSoldTo = fuel.customerSoldTo;
        customerSoldTo.Use_Fixed_Pricing__c = true;
        update customerSoldTo;
		Test.stopTest(); 
        
        // Only newly created orders will use the Use_Fixed_Pricing on the Customer
        Sales_Order__c salesOrder2 = new Sales_Order__c();
        salesOrder2.Company__c = fuel.company.id;
        salesOrder2.Customer__c = fuel.customerSoldTo.id;   
        salesOrder2.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder2.Payment_Term__c = fuel.terms.id;
        salesOrder2.pricebook__c = pricebook.id;
        insert salesOrder2; 

        Sales_Order_Line__c salesOrderLine2 = new Sales_Order_Line__c();
        salesOrderLine2.Product__c = fuel.product.Id;
        salesOrderLine2.Description__c = fuel.product.Description__c;
        salesOrderLine2.Company__c = fuel.company.id;
        salesOrderLine2.Sales_Order__c = salesOrder2.Id;
        salesOrderLine2.Quantity_Ordered__c = 5;
        salesOrderLine2.Required_Date__c = System.today() + 5;

        Sales_Order_Line__c salesOrderLine2P3 = new Sales_Order_Line__c();
        salesOrderLine2P3.Product__c = fuel.product3.Id; 
        salesOrderLine2P3.Description__c = fuel.product.Description__c;
        salesOrderLine2P3.Company__c = fuel.company.id;
        salesOrderLine2P3.Sales_Order__c = salesOrder2.Id;
        salesOrderLine2P3.Quantity_Ordered__c = 10;
        salesOrderLine2P3.Required_Date__c = System.today() + 5;
        insert new Sales_Order_Line__c[]{salesOrderLine2, salesOrderLine2P3};

        Sales_Order__c SO = [SELECT Id, Bracket_Price_Field_In_Use__c, Total_Product_Weight__c
			  				 FROM Sales_Order__c WHERE Id = :salesOrder2.Id];

		System.assertEquals(SO.Bracket_Price_Field_In_Use__c, null);
	}
}