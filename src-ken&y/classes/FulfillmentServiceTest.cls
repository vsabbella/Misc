@isTest
public class FulfillmentServiceTest {
    private static testMethod void paymentTerm() {
        TestFuel fuel = new TestFuel();
        System.assert(fuel.smrsList != null);
        System.assert(fuel.stockMovementRuleList != null);
        insert new Configuration__c(Name = 'STACKTRACE');

        Sales_Order__c so = fuel.packageSalesOrder;
        new SalesOrderService().plan(so.Id);

        new TestFuelQuery().setupInventory(true);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        SKID__c skid = wrappers[0].serialWrappers[0].skid;
        skid.Input_Quantity__c = 1;

        Map<Id, List<SkidWrapperV2>> inputData = new Map<Id, List<SkidWrapperV2>>{ wrappers[0].line.Id => new List<SkidWrapperV2>{ new SkidWrapperV2(skid) }};
        ShipmentAPI.Allocate allocate = new ShipmentAPI.Allocate();
        Action.Response resp = allocate.execute(JSON.serialize(inputData));
        System.assert(resp.success == true, resp);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        Test.startTest();
        skid = wrappers[0].serialWrappers[0].skid;
        skid.Packaging_UOM__c = null;
        skid.Input_Quantity__c = 1;

        inputData = new Map<Id, List<SkidWrapperV2>>{ wrappers[0].line.Id => new List<SkidWrapperV2>{ new SkidWrapperV2(skid) }};
        ShipmentAPI.PlanPick plan = new ShipmentAPI.PlanPick();
        resp = plan.execute(JSON.serialize(inputData));
        System.assert(resp.success == true, resp);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        skid = wrappers[0].serialWrappers[0].skid;
        skid.Input_Quantity__c = 1;

        inputData = new Map<Id, List<SkidWrapperV2>>{ wrappers[0].line.Id => new List<SkidWrapperV2>{ new SkidWrapperV2(skid) }};
        ShipmentAPI.Pick pick = new ShipmentAPI.Pick();
        resp = pick.execute(JSON.serialize(inputData));
        System.assert(resp.success == true, resp);

        FulfillmentService.processedShipmentLineIds.clear();

        ShipmentAPI.ship ship = new ShipmentAPI.Ship();
        resp = ship.execute(JSON.serialize(new Set<Id>{ shipmentLines.values()[0].Shipment__c }));
        System.assert(resp.success == true, resp);
        Test.stopTest();
        List<Fulfillment__c> fulfillments = [SELECT Id, Payment_Term__c FROM Fulfillment__c WHERE Sales_Order_Line__r.Sales_Order__c = :so.Id];
        System.assert(fulfillments.size() == 1, fulfillments);
        System.assert(fulfillments[0].Payment_Term__c == fuel.terms.Id);
    }
      
         //Test PaymentTerm with no salesorder
    private static testMethod void testpaymentTermWithoutSO(){
   
                TestFuel tf = new TestFuel();
        Payment_Term__c terms = new Payment_Term__c(); 
                terms.name = '3/10 Net 40'; 
                terms.Description__c = '3% discount in 10 days, due 30 days';
                terms.Type__c = KSE.PAYMENT_TERM_DUE_DAYS; 
                terms.Discount_Days__c = 10;
                terms.Discount_Percent__c = 2;
                terms.Due_Days__c = 30;
                insert terms; 
   
      Customer__c   customerBillTo = new Customer__c(); 
                customerBillTo.name = 'Customer Bill To 90';
                customerBillTo.recordTypeId = tf.CustomerRecordTypes.get('Bill_To');
                customerBillTo.Company__c = tf.company.id;
                customerBillTo.Payment_Term__c = tf.terms.ID;
               // customerBillTo.Address__c = tf.account.ID;
                customerBillTo.Credit_Limit__c = 100000.0;
                customerBillTo.Parent_Customer__c = tf.customerParent.id; 
                customerBillTo.Top_Parent_Customer__c = tf.customerParent.id;
                customerBillTo.Customer_Identifier__c = 'FLTEST1231'; 
                customerBillTo.Status__c = 'Approved';
      			customerBillTo.Payment_Term__c = terms.id;
                insert customerBillTo;
        
        
        fulfillment__C  fulFilmentWithAgLine= new Fulfillment__c(company__C=tf.company.id , name ='Test no SO',agreement_line__C=tf.agreementLine.id,customer__c = customerBillTo.id   );
        insert fulFilmentWithAgLine ;
        system.assertEquals( [select payment_terms__c from agreement__C where id = :tf.agreement.id].payment_terms__C,[select Payment_Term__c from fulfillment__c where id = :fulFilmentWithAgLine.id].Payment_Term__c);
        
        fulfillment__C  fulFilmentWOAgLine= new Fulfillment__c(company__C=tf.company.id, name ='Test no SO cust',customer__c = customerBillTo.id  );
        insert fulFilmentWOAgLine;
        
        system.assertEquals( terms.id,[select Payment_Term__c from fulfillment__c where id = :fulFilmentWOAgLine.id].Payment_Term__c);
    }
    
    private static testMethod void testBlockHoldOnFulfillmentIfNoReasonCode() {//KNDY-9455
    	TestFuel fuel = new TestFuel();
    	
    	Fulfillment__c f = new Fulfillment__c(company__C=fuel.company.id , name ='Test no SO',agreement_line__C=fuel.agreementLine.id, customer__c = fuel.customerBillTo.id , invoice_hold__c = true  );
    	boolean errorFound = false;
    	try {
    		insert f;
    	}catch(Exception ex) {
    		system.assert(ex.getMessage().contains('You must enter a reason code if setting fulfillment on hold'));
    		errorFound =true;
    	}
    	
    	system.assertEquals(true,errorFound);
    	
    	Reason_Code__c holdCode = new Reason_Code__c();
        holdCode.Company__c = fuel.company.Id;
        holdCode.Type__c = 'Invoice Hold';
        holdCode.Code__c = 'D001';
        insert holdCode;
    	
    	f.Reason_Code__c = holdCode.Id;
    	insert f;
    	
    	f =[select Id From Fulfillment__c where Invoice_Hold__c = true limit 1];
    	system.assertNotEquals(null,f.Id);
    	
    	f.Invoice_Hold__c = false;
    	update f;
    	
    	f =[select Id, Reason_Code__c From Fulfillment__c where Invoice_Hold__c = false limit 1];
    	system.assertEquals(null,f.Reason_Code__c);
    	
    }

    // KNDY-9688: Create a Sales Order Line with that is Usage Based, and make sure that it remains open even though Quantity Fulfilled is greater than Quantity Ordered
    private static testMethod void usageBasedSOLRemainsOpen() {
        TestFuel fuel = new TestFuel();

        Sales_Order__c so = new Sales_Order__c(
            Company__c = fuel.company.Id,
            Customer__c = fuel.customerSoldTo.Id,
            Ship_To__c = fuel.customerShipTo.Id,
            Bill_To__c = fuel.customerBillTo.Id,
            Payment_Term__c = fuel.terms.Id
        );
        insert so;

        update new Item__c(Id = fuel.product2.Item__c, Non_Inventory__c = true, Source__c = 'Expense');

        Sales_Order_Line__c sol1 = new Sales_Order_Line__c(
            Product__c = fuel.product.Id,
            Description__c = fuel.product.Description__c,
            Company__c = fuel.company.Id,
            Sales_Order__c = so.Id,
            Quantity_Ordered__c = 50,
            Required_Date__c = System.today() + 5,
            Discount_Percent__c = 2,
            Ship_From_Location__c = fuel.location2.Id,
            Usage_Based__c = true
        );
        insert sol1;

        Sales_Order_Line__c sol2 = new Sales_Order_Line__c(
            Product__c = fuel.product2.Id,
            Description__c = fuel.product2.Description__c,
            Company__c = fuel.company.Id,
            Sales_Order__c = so.Id,
            Quantity_Ordered__c = 50,
            Required_Date__c = System.today() + 5,
            Discount_Percent__c = 2,
            Ship_From_Location__c = fuel.location2.Id
        );
        insert sol2;

        insert new List<Fulfillment__c>{
            new Fulfillment__c(
                Company__c = fuel.company.Id,
                Name = 'Test no SO',
                Sales_Order_Line__c = sol1.Id,
                Quantity__c = 100,
                Status__c = 'Complete'
            ),
            new Fulfillment__c(
                Company__c = fuel.company.Id,
                Name = 'Test no SO',
                Sales_Order_Line__c = sol2.Id,
                Quantity__c = 50,
                Status__c = 'Complete'
            )
        };

        List<Sales_Order_Line__c> soLines = [SELECT Id FROM Sales_Order_Line__c WHERE Status__c != 'Closed'];
        System.assert(soLines.size() == 1, soLines);
    }
    
    static testMethod void testSetAgreementQuantities() {
        TestFuel fuel = new TestFuel();
       
        Customer__c customerBillTo = fuel.customerBillTo;
        Customer__c customerSoldTo = fuel.customerSoldTo;
        Customer__c customerShipTo = fuel.customerShipto;
        Pricebook__c pricebook = fuel.pricebook;
        Product__c product = fuel.product;
        
        Agreement__c agreement = new Agreement__c();
        agreement.Company__c = fuel.company.Id;
        agreement.Name = 'Sample Agreement';
        agreement.Customer__c = fuel.customerParent.Id;
        agreement.Bill_To__c = fuel.customerBillTo.Id;
        agreement.Start_Date__c = system.today();
        agreement.End_Date__c = system.today().addDays(100);
        agreement.Status__c = 'Draft';
        agreement.Currency__c = TestFuel.currencyGBP.id;
        agreement.Payment_Terms__c  = fuel.terms.Id;
       
        insert agreement;

    
        Agreement_Line__c agreementLine = new Agreement_Line__c();
        
        agreementLine.Agreement__c = agreement.Id;
        agreementLine.Start_Date__c = agreement.Start_Date__c;
        agreementLine.End_Date__c = agreement.End_Date__c;
        agreementLine.Occurrence__c = 'Immediate';
        agreementLine.Rate_Basis__c = 'Quantity';
        agreementLine.Product__c = product.Id;
        agreementLine.Product_Type__c = 'Product';
        agreementLine.Sales_Agreement_Quantity__c = 100;
        agreementLine.Revision_Status__c = null;
        agreementLine.Agreement_Price__c = 100;
        insert agreementLine;
        agreement.Status__c = 'Approved'; 
        update agreement;


        Test.startTest();
        Sales_Order__c so = new Sales_Order__c();
        so.Company__c = fuel.company.Id;
        so.Status__c  = 'Draft'; 
        so.Customer__c = fuel.customerSoldTo.Id;
        so.Currency__c = TestFuel.currencyGBP.id;
        so.Ship_To__c = fuel.customerShipTo.Id;
        so.Bill_To__c = fuel.customerBillTo.Id;
        so.Payment_Term__c = fuel.terms.Id;
        insert so;

        Sales_Order_Line__c soLine = new Sales_Order_Line__c();
        soLine.Product__c = product.Id;
        soLine.Status__c  = 'Draft'; 
        soLine.Description__c = product.Description__c;
        soLine.Company__c = fuel.company.Id;
        soLine.Occurrence__c  = 'Immediate';
        soLine.Rate_Basis__c = 'Quantity';
        soLine.Sales_Order__c = so.Id;
        soLine.Quantity_Ordered__c = 100;
        soLine.Quantity_Fulfilled__c = 0;
        soLine.Agreement_Line__c = agreementLine.id;
        soLine.Ship_From_Location__c = fuel.location.id;
        insert soLine;
        Fulfillment__c f1 = new Fulfillment__c( name ='Test',Agreement_Line__c = agreementLine.id,  Sales_Order_Line__c = soLine.Id, Quantity__c = 100, Status__c = 'Complete' );
        insert f1;
        
        Test.stopTest();
        List<Sales_Order_Line__c> sol = [SELECT Id,Status__c,product__c,Agreement_Line__c,Quantity_Ordered__c,Occurrence__c,Rate_Basis__c, Quantity_Fulfilled__c  FROM Sales_Order_Line__c WHERE  ID = :soLine.Id];
        
        system.assertEquals('Closed', sol[0].Status__c );
        list<Agreement_Line__c> aList = [SELECT id,product__c,Sales_Agreement_Quantity__c ,Remaining_Quantity__c,Sold_Quantity__c  FROM
                                            Agreement_Line__c  WHERE ID = :agreementLine.id]; 
        
        system.assertEquals(100, aList[0].Sold_Quantity__c);
        system.assertEquals(0, aList[0].Remaining_Quantity__c);
    }
}