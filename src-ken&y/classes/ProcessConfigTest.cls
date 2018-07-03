@istest public  class ProcessConfigTest {

	public static TestMethod void test_processconfig() { 
		// this design limits the actual configuration to a single field 
		// we can support multiple values, but not complex logic at this time
		
		insert new Process_Configuration__c(
				name='SOuseAccountingSegmentCR',  
				Field_Name__c = 'Type__c' , 
				Field_Value__c = 'Special, Custom' ,
				Active__c = true
				); 
		
		// should not fail, just return false for bad names
		system.assert( Process.configSwitch( null , 'foobadname') == false );
		
		sales_order__c so = new Sales_Order__c ( type__c = 'Special' );
		
		system.assert( Process.configSwitch( so, 'SOuseAccountingSegmentCR') );
		
		so = new Sales_Order__c ( type__c = 'custom' );
		system.assert( Process.configSwitch( so, 'SOuseAccountingSegmentCR') );
		
		so.Type__c = 'foo';
		system.assert( ! Process.configSwitch( so, 'SOuseAccountingSegmentCR') );
		
	}
	
	public static TestMethod void test_newConfig() {
		Process_Configuration__c pc1 = new Process_Configuration__c();
		pc1.name='POLineMisc';
		pc1.Object_Name__c = 'Purchase_Order_Line__c';
		pc1.Field_Value__c = 'Miscellaneous' ;
		pc1.Active__c = true;
		insert pc1;
		system.assertEquals(true, ProcessConfigService.configResult('Purchase_Order_Line__c', 'Miscellaneous',null, true));
		
	}
	
	
	
	
	/* Prototype for a call out specified by a process configuration 
	like from a trigger TODO 
	public static TestMethod void test_process_callout() { 
		
		Process_Automation__c conf = new Process_Automation__c(name='check_weight1',  
										Object_Name__c = 'Sales_Order__c',
										Field_name__c = 'Status__c',
										Field_Value__c = 'Draft', 
										Method_Name__c = 'ProcessConfigTest.mytest' ,
										Method_DML__c = false );
		insert conf;
		
		
		sales_order__c so = new Sales_Order__c ( type__c = 'Special', Status__c = 'Draft' );
		
		Process.callProcessConfigMethod( new list<sobject>{so} ); 
		
		system.assert( so.Status__c == 'Accepted' ); 
		
	} */
	
	public class mytest implements Process.Automate {
		
		public void processRecords( Process_Automation__c conf, list<sobject> records ) { 
			
			//system.debug(Logginglevel.info, string.valueof(this) + ' ' + records.size() );
			if ( conf.Object_name__c == 'Sales_Order__c' ) { 
				for ( sobject s : records) { 
					s.put('Status__c', 'Accepted' ); // something we can test 
				}
			}
			
		}
	}
	
	

	/* 
	 * test for SalesOrderBatch automation 
	 */
	public class soAccept implements Process.Automate { 
		
		// simple implementation that will mark the order accepted
		public void processRecords( Process_Automation__c conf, list<sobject> o ) { 
			//system.debug(Logginglevel.info, o.size() );
			if ( conf.Object_name__c == 'Sales_Order__c' ) { 
				for ( sobject s : o) { 
					s.put('Status__c', 'Accepted' ); // something we can test 
				}
			}
			
		} 
	}
	
	public class soPlan implements Process.Automate { 
		// Perform the  "plan" process after checking a few things
		public void processRecords( Process_Automation__c conf, list<sobject> records ) { 
			list <Notify.Message> msgs = new list <Notify.Message>();   
			list <Sales_Order__c> invalidOrders = new List<Sales_Order__c>();
	
			system.debug(LoggingLevel.INFo, 'soPlan here ' + conf );
			
			if ( conf.Object_name__c != 'Sales_Order__c' )  return ;
	
			for ( Sales_Order__c  salesOrder : (list<Sales_Order__c>)records ) {
	
				if ( salesOrder.Status__c != 'Draft') continue;  // make sure this record is ready to be planned !!
	
				string errorMsg = '';
	
				// check details about this order 
				// TODO this makes a query in a loop, FIX ME !!!
				for(Sales_Order_Line__c sol : [SELECT Id, name, ship_from_location__c, quantity_ordered__c, product__c
																FROM Sales_Order_Line__c
																WHERE Sales_Order__c = :salesOrder.id ]){
	
					if(sol.Ship_From_Location__c == null){
						errorMsg += ' Missing Ship From Location ';
					}
					if(sol.quantity_ordered__c <= 0 || sol.quantity_ordered__c == null){
						errorMsg += ' Invalid Quantity Ordered ';
					}
					if(sol.product__c == null){
						errorMsg += ' Missing Product ';
					}
				}	
	
				if ( errorMsg == '' ) { // is valid 
					try { 
	system.debug(Logginglevel.info, ' do the plan ');
						new SalesOrderService().plan(salesOrder.id); 		// do the actual planning work
		system.debug(Logginglevel.info, ' done the plan ');
	
						// dont' report the normal planning, the can be done with field history tracking 
						// msgs.add( new Notify.Message('Order ', salesOrder.name +' planned successfuly') ); 
	
					} catch( exception e ) { 
						msgs.add( new Notify.Message('Unable to plan order', salesOrder.name +' ' + e.getMessage()) ); 					
					}
	 					
				}
				else { // mark this order with an exception
					system.debug(Logginglevel.info, string.valueof(this) + ' ' + errorMsg );
	
					invalidOrders.add ( new Sales_Order__c( id = SalesOrder.id, Ready__c = false	) );
	
					msgs.add( new Notify.Message('Unable to plan order:', salesOrder.name +' ' +errorMsg) ); 
				}
	
				if ( msgs.size() > 0 ) { 
					Notify.chatterOn( this, Salesorder.id, msgs);
				}
	
			} // end for each order
	
			if ( invalidOrders.size() > 0 ) {  // batch update the invalid records we saw
				update invalidOrders;
			}
		}
	}
	
	public static TestMethod void test_salesorderAccept() {
		TestData data = new TestData(); 
		// have a sales order
		// system.debug(LoggingLevel.INFO, data.salesOrder );
		Process_Automation__c conf = new Process_Automation__c(name='check_weight1',  
										Object_Name__c = 'Sales_Order__c',
										Field_name__c = 'Status__c',
										Field_Value__c = 'Draft', 
										Method_Name__c = 'ProcessConfigTest.soAccept',
										Method_DML__c = false,
										Active__c = true );

		
		insert new list<Process_Automation__c>{ conf } ;
		// move the order to "ready" 
		data.salesOrder.Ready__c = true; 	update data.salesOrder;
		
		Test.startTest();
		system.assert( data.salesOrder.Status__c == 'Draft' );
	
		new SalesOrderInspect().runBatch( data.company.id );
        
        Test.stopTest();
        
		data.salesOrder = [Select Status__c From Sales_Order__c where id = :data.salesOrder.id limit 1];
        //system.debug(LoggingLevel.INFO, data.salesOrder);

        system.assert( data.salesOrder.Status__c == 'Accepted' );
        
	}

	
	public static TestMethod void test_salesorderPlan() {
		TestData data = new TestData(); 

		Process_Automation__c plan = new Process_Automation__c(name='plan',  
										Object_Name__c = 'Sales_Order__c',
										Field_name__c = 'Status__c',
										Field_Value__c = 'Draft', 
										Method_Name__c = 'ProcessConfigTest.soPlan',
										Method_DML__c = true,
										Active__c = true );
		
		insert new list<Process_Automation__c>{  plan } ;
		
		// only orders marked "READY " will be considered
		data.salesOrder.Ready__c = true; 	update data.salesOrder;
		
		Test.startTest(); 
		system.assertEquals('Draft', data.salesOrder.Status__c );
		
		new SalesOrderInspect().runBatch( data.company.id );  // move to open, perform planning
        
        Test.stopTest();

		data.salesOrder = [Select Status__c,(select id from Sales_Order_lines__r) 
											From Sales_Order__c where id = :data.salesOrder.id limit 1];
        //system.debug(LoggingLevel.INFO, data.salesOrder);
        system.assertEquals('Open', data.salesOrder.Status__c );
		
		// check that shipment is created
		Shipment_Line__c[] shipments = [ select id, Sales_Order__c from Shipment_Line__c where  Sales_Order__c = :data.salesOrder.id ];
		system.assert( shipments.size() == data.salesOrder.Sales_Order_Lines__r.size() );
	}
	
	public static TestMethod void executeAuto_test() {
		TestData data = new TestData(); 

		Process_Automation__c plan = new Process_Automation__c(name='plan',  
										Object_Name__c = 'Sales_Order__c',
										Field_name__c = 'Status__c',
										Field_Value__c = 'Draft', 
										Method_Name__c = 'ProcessConfigTest.soPlan',
										Method_DML__c = true,
										Active__c = true );
		
		insert new list<Process_Automation__c>{  plan } ;
		
		// only orders marked "READY " will be considered
		data.salesOrder.Ready__c = true; 	update data.salesOrder;
		
		Test.startTest(); 
		system.assertEquals('Draft', data.salesOrder.Status__c );
		
		Process.executeAutomation(new list<sobject>{data.salesOrder} );  
        
        Test.stopTest();

		data.salesOrder = [Select Status__c,(select id from Sales_Order_lines__r) 
											From Sales_Order__c where id = :data.salesOrder.id limit 1];
        //system.debug(LoggingLevel.INFO, data.salesOrder);
        system.assertEquals('Open', data.salesOrder.Status__c );
		
		// check that shipment is created
		Shipment_Line__c[] shipments = [ select id, Sales_Order__c from Shipment_Line__c where  Sales_Order__c = :data.salesOrder.id ];
		system.assert( shipments.size() == data.salesOrder.Sales_Order_Lines__r.size() );
	}
	
	
	/*
	 * negitive testing 
	 */
	public static TestMethod void badMethodName_test() {
		TestData data = new TestData(); 

		Process_Automation__c plan = new Process_Automation__c(name='plan',  
										Object_Name__c = 'Sales_Order__c',
										Field_name__c = 'Status__c',
										Field_Value__c = 'Draft', 
										Method_Name__c = 'notfoundmethod',
										Method_DML__c = true,
										Active__c = true );
		
		insert new list<Process_Automation__c>{  plan } ;
		
		// only orders marked "READY " will be considered
		data.salesOrder.Ready__c = true; 	update data.salesOrder;
		
		Test.startTest(); 
		system.assertEquals('Draft', data.salesOrder.Status__c );
		
		new SalesOrderInspect().runBatch( data.company.id );  
		
		Test.stopTest();
		// check that shipment is NOT created
		Shipment_Line__c[] shipments = [ select id, Sales_Order__c from Shipment_Line__c where  Sales_Order__c = :data.salesOrder.id ];
		system.assertEquals( 0, shipments.size() );
	}
	
	public static TestMethod void test_salesorderPlan_notActive() {
		TestData data = new TestData(); 

		Process_Automation__c plan = new Process_Automation__c(name='plan',  
										Object_Name__c = 'Sales_Order__c',
										Field_name__c = 'Status__c',
										Field_Value__c = 'Draft', 
										Method_Name__c = 'ProcessConfigTest.soPlan',
										Method_DML__c = true,
										Active__c = false );
		
		insert new list<Process_Automation__c>{  plan } ;
		
		// only orders marked "READY " will be considered
		data.salesOrder.Ready__c = true; 	update data.salesOrder;
		
		Test.startTest(); 
		system.assertEquals('Draft', data.salesOrder.Status__c );
		
		new SalesOrderInspect().runBatch( data.company.id );  // move to open, perform planning
        
        Test.stopTest();

		data.salesOrder = [Select Status__c,(select id from Sales_Order_lines__r) 
											From Sales_Order__c where id = :data.salesOrder.id limit 1];
        
        //system.debug(LoggingLevel.INFO, data.salesOrder);
        system.assertEquals('Draft', data.salesOrder.Status__c );
		
	}
	
	static testMethod void Notify_test() {
        Notify.Message m = new Notify.Message( 'hdr ', 'bdy');
        system.assert( m!=null );
        Process p = new Process(); 
        Notify.chatterOnMe( p, new List<Notify.Message>{m} ); 
    }
}