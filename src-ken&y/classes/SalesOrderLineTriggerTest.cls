/**
 * This class contains unit tests 
 */
@isTest
private class SalesOrderLineTriggerTest {
	
	static TestData data = new TestData();
    /* OTC-18 : Demand skids are no more created based on sales order status
    static testMethod void mainTest() {
    	test.startTest();
        System.debug(' SoqlQueries ' + Limits.getQueries() + ' - ' + Limits.getLimitQueries());
        //create sales order line
        list<Sales_Order_Line__c> salesOrderLineList=new list<Sales_Order_Line__c>();//=data.SalesOrderLines;
        list<Sales_Order_Line__c> deleteSalesOrderLineList=new list<Sales_Order_Line__c>();
        list<SKID__c> deleteSkidList=new list<SKID__c>();
        list<Sales_Order_Line__c> updateSalesOrderLineList=new list<Sales_Order_Line__c>();
        
        set<Id> skidSet=new set<Id>();
        set<Id> lineIds=new set<Id>();
        
        //create sales order lines
        for(Item__c itemObj:data.itemList){
            Sales_Order_Line__c SalesOrderLine=new Sales_Order_Line__c();
         	SalesOrderLine.Product__c = data.product.id;
            SalesOrderLine.Company__c=itemObj.Company__c;
            SalesOrderLine.Sales_Order__c = data.salesOrder.Id;
            SalesOrderLine.Quantity_Ordered__c = 100;
            SalesOrderLine.Required_Date__c = System.today()+5;
            SalesOrderLine.Status__c='Draft';
            
            salesOrderLineList.add(SalesOrderLine);
            
        }
        insert salesOrderLineList;
        
        // Change the sales order line status from "Draft" to "Open"
        
        data.salesOrder.Status__c = 'Open';
        update data.salesOrder;
        
        for (Sales_Order_Line__c tmp : salesOrderLineList) { 
        	lineIds.add( tmp.id );
        	tmp.Status__c = 'Open';
        }
        
    	update salesOrderLineList;
    	    	
        
        //check if the skids got created
        for(Sales_Order_Line__c lineObj:[select Id,Quantity_Backordered__c,
        									(select Id,Quantity__c from SKIDs__r where Type__c=:SKIDService.SKID_TYPE_SO_DEMAND limit 1)
        									from Sales_Order_Line__c where Id in:salesOrderLineList]){
            system.assertnotEquals(0, lineObj.SKIDs__r.size() );
            
            skidSet.add(lineObj.SKIDs__r[0].Id);
            
            deleteSalesOrderLineList.add(lineObj);
        }
      
        system.assertNotEquals(skidSet.size(),0);
        
        //update the quantity shipped
        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
	    insert rc;
        for(Sales_Order_Line__c lineObj:salesOrderLineList){
             lineObj.Quantity_Shipped__c=50;
             //KNDY-2551	         
	         lineObj.Quantity_Change_Reason__c = rc.Id;
             lineObj.Required_Date__c=system.today()+4;
             updateSalesOrderLineList.add(lineObj);
        }
        if(updateSalesOrderLineList.size()>0)
            update updateSalesOrderLineList;
        
        //check if the skid got updated
        for(Sales_Order_Line__c lineObj:[select Id, Product__r.Item__r.Stocking_UOM__c, Product__r.Item__r.Stocking_UOM__r.Name,
        								Selling_UOM__c, Selling_UOM__r.Name,
        								(select Id,Quantity__c,Order_Date__c from SKIDs__r where Type__c=:SKIDService.SKID_TYPE_SO_DEMAND limit 1),Quantity_Backordered__c,Required_Date__c from Sales_Order_Line__c where Id in:lineIds]){
            
            system.assertEquals(lineObj.SKIDs__r[0].Quantity__c, lineObj.Quantity_Backordered__c * KSE.getConversionFactor(lineObj));
            system.assertEquals(lineObj.SKIDs__r[0].Order_Date__c,lineObj.Required_Date__c);
        
        }
        
        delete deleteSalesOrderLineList;
        
        //check if the skids got deleted
        
        system.assertEquals([select Id from SKID__c where Type__c=:SKIDService.SKID_TYPE_SO_DEMAND and Sales_order_line__c in:lineIds].size(),0);
        
        test.stopTest();
    }*/
    
    static testmethod void test_soline_open_close() {
    	// verify that the trigger is opening and closing the lines properly.
    	test.startTest();
    	system.assertEquals('Draft', data.salesOrder.status__c, 'expected Draft sales order');
    	data.salesOrder.Status__c = 'Open';
		update data.salesOrder;
		
		// close all lines on this order
		Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
		insert rc;
		for ( Sales_Order_Line__c tmp : data.SalesOrderLines )    	{
			// to close a line make qty shipped == qty ordered
			tmp.Status__c = 'Open';
			tmp.Quantity_Fulfilled__c = tmp.Quantity_Ordered__c; 
			//KNDY-2551
	        tmp.Quantity_Change_Reason__c = rc.Id;
		}
		
		update  data.SalesOrderLines ;
		reQuerySalesOrder();
		
		for ( Sales_Order_Line__c tmp : data.SalesOrderLines )    	{
			system.assertEquals( tmp.Quantity_Ordered__c, tmp.Quantity_Fulfilled__c, 'Quantity Fulfilled is not equal to Quantity Ordered' );
			system.assertEquals( 'Closed', tmp.status__c, 'expected closed line' ); 
		}
		system.assertEquals('Closed', data.salesOrder.status__c, 'expected Closed sales order');
		
		// KNDY-1489: Test that the SO Demand Skids are deleted for the sales order lines.
		System.assertEquals(0, [select ID from SKID__c where Type__c = :SKIDService.SKID_TYPE_SO_DEMAND and Sales_Order_Line__c IN :data.SalesOrderLines].size());
		
		// add an open line
		Sales_Order_Line__c SalesOrderLine=new Sales_Order_Line__c();
		SalesOrderLine.Product__c = data.product.id;
		SalesOrderLine.Company__c= data.itemList[0].Company__c;
		SalesOrderLine.Sales_Order__c = data.salesOrder.Id;
		SalesOrderLine.Quantity_Ordered__c = 100;
		SalesOrderLine.Required_Date__c = System.today()+5;
		SalesOrderLine.Status__c='Open';
        insert   SalesOrderLine;
        
        reQuerySalesOrder();  
		system.assertEquals('Open', data.salesOrder.status__c, 'expected Open sales order');
    }
    
    static testmethod void test_soline_Total_Weight() {
    	test.startTest();
    	reQuerySalesOrder();
    	system.assertEquals( 1375.000000, data.salesOrder.Total_Weight__c, 'expected 1375.000000');
    	// add an open line
		Sales_Order_Line__c SalesOrderLine=new Sales_Order_Line__c();
		SalesOrderLine.Product__c = data.product.id;
		SalesOrderLine.Company__c= data.itemList[0].Company__c;
		SalesOrderLine.Sales_Order__c = data.salesOrder.Id;
		SalesOrderLine.Quantity_Ordered__c = 100;
		SalesOrderLine.Required_Date__c = System.today()+5;
		SalesOrderLine.Status__c='Draft';
        insert   SalesOrderLine;
        
        reQuerySalesOrder();
        system.assertEquals( 2675.000000, data.salesOrder.Total_Weight__c, 'expected 2675.000000');
        
        //SalesOrderLine.Description__c = 'Test Memo';
        SalesOrderLine.UPC_Code__c = '123456789';
        integer i = Limits.getQueries();
        
        update SalesOrderLine;
        integer i2 = Limits.getQueries();
        
        //system.assertEquals( i, i2, 'Expected no Additional Queries on SalesOrderLine Trigger' );
        
        delete SalesOrderLine;  // run the after delete trigger to see if the weight comes back down 
       	
       	reQuerySalesOrder();
    	system.assertEquals( 1375.000000, data.salesOrder.Total_Weight__c, 'expected 1375.000000');
    	 
    }
    
   static testmethod void test_so_Total_Number_of_Pallets_floor_spaces() {
        test.startTest();
        data.product2.stackable__c = true;
        data.product2.Units_per_Layer__c=10;
        data.product2.Layers_per_Pallet__c=4;
        update data.product2;
       
        for (Sales_Order_Line__c tpf : data.SalesOrderLines) {
            tpf.Product__c = data.Product2.id; 
        }
        
        update data.SalesOrderLines ;
        test.stopTest();
        reQuerySalesOrder();
        system.assertEquals( 3,data.salesOrder.Number_of_pallets__c, 'expected 3');
        system.debug('No.of pallets='+ data.salesOrder.Number_of_Pallets__c);
        system.assertEquals( 2,data.salesOrder.Number_of_Floor_Spaces__c, 'expected 2');
    }
    
    private static void reQuerySalesOrder() {
        data.salesOrder = [Select s.Status__c, s.Customer__c, s.Company__c,Total_Weight__c,Number_of_pallets__c,Number_of_floor_spaces__c,
                                (Select Id, Name, Sales_Order__c,
                                Backorder_Value__c, Company__c, Description__c, Discount_Percent__c, Quantity_Fulfilled__c,
                                Extended_Price__c, Product__r.Item__c, Line__c, Quantity_Backordered__c, Number_of_pallets__c, Number_of_Floor_Spaces__c,
                                Quantity_Ordered__c, Quantity_Shipped__c, Required_Date__c, Status__c, Product__r.Item__r.Class__c,
                                Unit_Price__c From Sales_Order_Lines__r ) 
                    From Sales_Order__c s where id=:data.salesOrder.id limit 1];
        
     	data.SalesOrderLines = data.salesOrder.Sales_Order_Lines__r;
     	system.assert( data.SalesOrderLines.size() > 0 );
    }
    
    /* TODO hess
    static testmethod void test_UPC_code_match() {
		
		TestData data = new TestData();
		
		// add a line to a sales order, providing only the UPC code
		Sales_Order_Line__c SalesOrderLine = new Sales_Order_Line__c();
        //SalesOrderLine.Item__c = ItemList[5].Id;
        SalesOrderLine.UPC_Code__c = data.product2.UPC_Code__c;
        //SalesOrderLine.Description__c = product2.Description__c;
        SalesOrderLine.Company__c = data.company.id;
        SalesOrderLine.Sales_Order__c = data.salesOrder.Id;
        SalesOrderLine.Quantity_Ordered__c = 15;
        SalesOrderLine.Required_Date__c = System.today()+15;
        SalesOrderLine.Taxable__c = true;
        //SalesOrderLine.Unit_Price__c = product2.Price__c;
   
        insert SalesOrderLine;
        system.assert( SalesOrderLine.id != null );
	}
	*/
	
	// Test for KNDY-1476
	static testMethod void testSalesOrderLineEditQuantity(){
		Test.startTest();
		// Create a sales order line with zero quantity
		Sales_Order_Line__c sol=new Sales_Order_Line__c();
		sol.Product__c = data.product.id;
		sol.Company__c= data.itemList[0].Company__c;
		sol.Sales_Order__c = data.salesOrder.Id;
		sol.Quantity_Ordered__c = 0;
		sol.Required_Date__c = System.today()+5;
		
        insert sol;
        
        System.assertEquals('Draft', [select Id, Status__c 
        								from Sales_Order_Line__c
        								where id = :sol.Id
        								limit 1
        								].Status__c);
        // Edit the sales order line quantity								
       	sol.Quantity_Ordered__c = 10;
       	//KNDY-2551
        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
        insert rc;
        sol.Quantity_Change_Reason__c = rc.Id;
       	update sol;		
       	
       	System.assertEquals(10, [select Id, Status__c , Quantity_Ordered__c
    								from Sales_Order_Line__c
    								where id = :sol.Id
    								limit 1
    								].Quantity_Ordered__c);	

		Test.stopTest();        								
    }
}