@isTest
public with sharing class ShipmentUndoConfirmTest {
    
    static testMethod void testUndoConfirmShipmentSO() { //happy scenario
        TestFuel fuel = new TestFuel();
        List<Period__c> periodList = fuel.periodList;
        
        Sales_Order__c salesOrder = fuel.salesOrder;
        
        List<SKID__c> skids = fuel.skids;    
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
            
        
        
        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();
        System.assertEquals(false, soPlanExt.hasErrors);
        
        salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c, Customer__r.top_parent_customer__c,order_total__c, Sales_Tax__c from Sales_Order__c where id = :salesOrder.Id limit 1];
        
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);
        
        system.assert( SOAExt.solWrapperList.size() == 2 );
        
        for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
            
            system.assert( sw.skidList.size() == 1); // number of available location skids
            
            sw.skidList[0].Quantity_Allocated__c  = sw.sol.Quantity_Ordered__c;
        }
        
        SOAExt.allocate();
        
        Test.startTest();
 
        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        
        socpExt.confirmPick();
        
        SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension(con);
        socsExt.confirmShip();
        //Added for KNDY-4454
        Customer__c topParent = [ select id, Open_Sales_Orders__c, Uninvoiced_Shipments__c from customer__c where id =: salesOrder.Customer__r.top_parent_customer__c ];
        
        
        
        List<Shipment__c> shList = [Select Id, Status__c from Shipment__c];
        system.assertEquals(1, shList.size());
        system.assert( shList[0].Status__c == 'Confirmed');

        con = new ApexPages.Standardcontroller(shList[0]);
        ShipmentUndoConfirmExt SUCE = new ShipmentUndoConfirmExt(con);
        SUCE.undoShipConfirm();
        boolean ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages()){
        	if(msg.getDetail() == 'You can only undo shipment of type Transfer Order Shipment. Please use Manage Delivery page.'){
        		ErrorExists = true;
        		break;
        	}
        }
        
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
        
    }
    
    static testMethod void testUndoOnlyConfirmedShipmentsErrorSO(){
        
        TestFuel fuel = new TestFuel();
        
        Sales_Order__c salesOrder = fuel.salesOrder;
        
        List<SKID__c> skids = fuel.skids;    
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();
        System.assertEquals(false, soPlanExt.hasErrors);
        
        salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :salesOrder.Id limit 1];
        
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);
        
        system.assert( SOAExt.solWrapperList.size() == 2 );
        
        for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
            
            system.assert( sw.skidList.size() == 1); // number of available location skids
            
            sw.skidList[0].Quantity_Allocated__c  = sw.sol.Quantity_Ordered__c;
        }
        
        SOAExt.allocate();
        
        Test.startTest();
 
        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        
        socpExt.confirmPick();
        
        List<Shipment__c> shList = [Select Id, Status__c from Shipment__c];
        system.assertEquals(1, shList.size());
        system.assert( shList[0].Status__c == 'Staged');
        
        con = new ApexPages.Standardcontroller(shList[0]);
        ShipmentUndoConfirmExt SUCE = new ShipmentUndoConfirmExt(con);
        SUCE.undoShipConfirm();
        
        Test.stopTest();
        
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == true, 'only confirmed shipments can be undone!' );
    }
    
    static testMethod void testUndoOnlyConfirmedShipmentsErrorSO_AlreadyInvoiced(){ //OTC-518 
        
        TestFuel fuel = new TestFuel();
        List<Period__c> periodList = fuel.periodList;
        
        Sales_Order__c salesOrder = fuel.salesOrder;
        
        List<SKID__c> skids = fuel.skids;    
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
            
        
        
        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();
        System.assertEquals(false, soPlanExt.hasErrors);
        
        salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c, Customer__r.top_parent_customer__c,order_total__c,Sales_Tax__c from Sales_Order__c where id = :salesOrder.Id limit 1];
        
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);
        
        system.assert( SOAExt.solWrapperList.size() == 2 );
        
        for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
            
            system.assert( sw.skidList.size() == 1); // number of available location skids
            
            sw.skidList[0].Quantity_Allocated__c  = sw.sol.Quantity_Ordered__c;
        }
        
        SOAExt.allocate();
        
        Test.startTest();
 
        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        
        socpExt.confirmPick();
        
        SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension(con);
        socsExt.confirmShip();
        //Added for KNDY-4454
        Customer__c topParent = [ select id, Open_Sales_Orders__c, Uninvoiced_Shipments__c from customer__c where id =: salesOrder.Customer__r.top_parent_customer__c ];
        
        
        
        List<Shipment__c> shList = [Select Id, Status__c, Company__c, (Select id,Product__c from Shipment_Lines__r) from Shipment__c];
        system.assertEquals(1, shList.size());
        system.assertEquals(2, shList[0].Shipment_Lines__r.size(), shList[0].Shipment_Lines__r.size());
        system.assert( shList[0].Status__c == 'Confirmed');
        
         
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = TestFuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Shipment_line__c = shList[0].Shipment_Lines__r[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = shList[0].Shipment_Lines__r[0].Product__c));
        
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = TestFuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Shipment_line__c = shList[0].Shipment_Lines__r[1].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 4, Product__c = shList[0].Shipment_Lines__r[0].Product__c));
        insert lFs;
        
        con = new ApexPages.Standardcontroller(shList[0]);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(shList[0].Id,'Shipment__c');
        system.assert(jr.success);
        
        jr = GenerateInvoiceExt.next(false,shList[0].Id, shList[0]);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(shList[0].Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Shipment__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	boolean ErrorExists = false; 
       	jr = GenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
		for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('has been created and finalized.')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        con = new ApexPages.Standardcontroller(shList[0]);
        ShipmentUndoConfirmExt SUCE = new ShipmentUndoConfirmExt(con);
        SUCE.undoShipConfirm();
        
        Test.stopTest();
        
        system.assert( SUCE.errorFound == true, SUCE.errorFound);
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == true, ApexPages.GetMessages());
        ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages()){
        	if(msg.getDetail() == 'You can only undo shipment of type Transfer Order Shipment. Please use Manage Delivery page.'){
        		ErrorExists = true;
        		break;
        	}
        }
        
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
    }
}