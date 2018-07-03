@isTest public with sharing class GenerateAccountingTest {
	
	static TestData data = new TestData();
	
	public static testMethod void test_sales_order_special() {
		TestData.insertSKIDQuantityToStock(data);
		
		// as a accounts manager i want to perform a special step when a sales
		// order is created with a "special" type
		
		/* TODO 
		insert new Process_Configuration__c(name='foo',  
										Object_Name__c = 'Sales_Order__c',
										Field_Name__c = 'Type__c' , 
										Field_Value__c = 'Special' , 
										Class_Name__c = 'GenerateAccountingTest' );
		
		data.salesOrder.Type__c ='Special';
		update data.salesOrder; 
		*/
		system.assert( data.salesOrder.id != null);
		refetch(); 
		test.startTest();
		
		/*
		Accounting_Default__c record = new Accounting_Default__c();
		insert record;
		data.salesOrder.Accounting_Default__c = record.id; 
		update data.salesOrder; 
	
		refetch(); 
		
		system.assert( data.salesOrder.Accounting_Default__c != null );
		
		// input values into the accounting override ( as a user would )
		Accounting_Default__c ad = [ select id, name from Accounting_Default__c where id = :data.salesOrder.Accounting_Default__c limit 1];
		ad.company__c = data.company.id;
		ad.gl_account__c = data.Acctdata.marketingGL.id; 
		update ad; 
		*/
		 
		// sales order is all set, now SO allocate 
		ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(data.salesOrder);
		
		SOPlanExt SOPExt = new SOPlanExt(con);
        SOPExt.plan();        
       
       	PageReference allocate = Page.SalesOrderAllocate;
       	allocate.getParameters().put('Id', data.salesOrder.Id);
       	Test.setCurrentPage(allocate);
        con = new ApexPages.Standardcontroller(data.salesOrder);
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        
        //System.assertNotEquals(null, SOAExt.getSalesOrderLines());
         System.assertNotEquals(null,SOAExt.solList);
         System.assertNotEquals(0, SOAExt.solList.size());
         System.assertNotEquals( 0,SOAExt.solWrapperList.size());
      // System.assertNotEquals(null, SOAExt.soLinesToAllocate);
      // System.assertNotEquals(0, SOAExt.soLinesToAllocate.size());
        system.assert( SOAExt.disableSave == false, apexpages.getMessages() );
        
        for(SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList){            
             sw.skidList[0].Quantity_Allocated__c  = 1;
        }
        
        Pagereference p = SOAExt.allocate();
        system.assert( SOAExt.disableSave == false, apexpages.getMessages() );
        
        //system.assert( p != null, Apexpages.getMessages());
//        system.debug(LoggingLevel.INFO, 'page is '+ p);
        
        // here we should have shipments
        refetch(); 
        
 //       system.debug(LoggingLevel.INFO,  [select id from Shipment_Line__c where   sales_order__c = :data.salesOrder.id ] );
        
        //List<Shipment_Line__c> lines = [select id,Shipment__c, shipment__r.company__c, shipment__r.date_shipped__c from Shipment_Line__c where   sales_order__c = :data.salesOrder.id ];
        //system.assert( lines.size()>0 );
        
        system.assert( data.salesOrder.shipment_Lines__r.size() > 0, ' size was zero on invoice lines' );
        
        		 
        // Confirm Pick for the quantity allocated for the salesorder. 
        SalesOrderConfirmPickExt SOCPExt = new SalesOrderConfirmPickExt(con);
        SOCPExt.confirmPick();
        system.assert( SOCPExt.disableConfirmPick != true, apexpages.getMessages() );
        
        // Confirm shipment of this sales order
        SalesOrderConfirmShipExtension SOCSExt = new SalesOrderConfirmShipExtension(con);
        SOCSExt.confirmShip();
        system.assert( SOCSExt.disableConfirmShip != true, apexpages.getMessages() );
        
        
        /*
        GenerateAccountingService GAS = new GenerateAccountingService();
        GAS.createShipmentAccounting( [select id, company__c , Date_Shipped__c 
        	from Shipment__c where id = :lines[0].Shipment__c]  );
        */
         
        /* SK - Do we need to run shipment accounting here ? We already have shipment accounting tests covered in ShipmentAccountingTest
        ShipmentAccounting sa = new ShipmentAccounting();
        //sa.execute([select id, company__c , Date_Shipped__c 
        //	from Shipment__c where id = :lines[0].Shipment__c]);
        //sa.execute(new List<Shipment__c>{new Shipment__c(Id=lines[0].shipment__c, company__c = lines[0].shipment__r.company__c, date_shipped__c = system.today())});
        sa.execute(data.salesOrder.shipment_Lines__r);
       	Test.stopTest();
        // verify marketingGL on ae
        List<Accounting_Entry__c> acctEntry = [Select id, Name, Shipment__c, 
                                                Exception__c 
        										, ( select id, name, Transaction_Date__c, 
        										Amount_DR__c, Amount_CR__c, GL_account__c,
        										Mandatory_Segment_Exception__c from Accounting_Entry_Lines__r )
        										
                                            from Accounting_Entry__c 
                                            where Shipment__c = :data.salesOrder.shipment_Lines__r[0].Shipment__c];
    
	    system.assertNotEquals(null,acctEntry);
	    for ( Accounting_Entry_Line__c tmp : acctEntry[0].Accounting_Entry_Lines__r ) {
	    //	system.debug(LoggingLevel.INFO, tmp);
	    }
        
	    system.assertEquals(1,acctEntry.size());
	    */
	}

	private static void refetch() { 
		data.salesOrder = [Select s.Status__c, s.Customer__c, s.Company__c, Accounting_Default__c,
								date_time_ordered__c, CreatedDate, Currency__c,	Type__c, Line_Exceptions__c,
                                (Select Id,  Sales_Order__c, 
                                Backorder_Value__c, Company__c, Product__r.Item__c, Line__c, Quantity_Backordered__c, 
                                Quantity_Ordered__c, Quantity_Shipped__c, Required_Date__c, Status__c, Product__r.Item__r.Class__c,
                                Unit_Price__c From Sales_Order_Lines__r ) , ( select id , name , Shipment__c from  Shipment_Lines__r )
                    From Sales_Order__c s where id=:data.salesOrder.id limit 1];
        
        system.assert( data.salesOrder.id != null);
	}

}