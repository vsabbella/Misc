@isTest
public class ShipmentAccountingTest {
	/*
	    
	static testmethod void testShipmentAccounting(){
		TestDataForFinance data = new TestDataForFinance();
	   	Test.startTest();
	   	List<Shipment__c> shipmentList = new List<Shipment__c>();
	   	
	    Shipment__c shipment1 = new Shipment__c();
	    shipment1.Company__c = data.company.id;
	    shipment1.Date_Shipped__c = system.now();
	    shipment1.Transaction_Date__c = system.now();
	    shipment1.Currency__c = TestFuel.currencyUSD.id;
	    shipment1.Status__c = 'Confirmed';
	    shipmentList.add(shipment1); 
	    
	    Shipment__c shipment2 = new Shipment__c();
	    shipment2.Company__c = data.company.id;
	    shipment2.Date_Shipped__c = system.now();
	    shipment2.Transaction_Date__c = system.now();
	    shipment2.Currency__c = TestFuel.currencyUSD.id;
	    shipment2.Status__c = 'Confirmed';
	    shipmentList.add(shipment2); 
	    
	    insert shipmentList;
	    
	    List<Shipment_Line__c> shipLineList = new List<Shipment_Line__c>();
	    Shipment_Line__c shipLine1 = new Shipment_Line__c();
	    shipLine1.Company__c = data.company.id;
	    shipLine1.Extended_Cost__c = 5;
	    shipLine1.Quantity_Shipped__c = 5;
	    shipLine1.Sales_Order__c = data.salesOrder1.id;
	    shipLine1.Sales_Order_Line__c = data.SalesOrderLineList[0].id;
	    shipLine1.Unit_Price__c = 25;
	    shipLine1.Product__c = data.product.id;
	    shipLine1.Location__c = data.location.id;
	    shipLine1.Shipment__c = shipment1.id;
	    shipLine1.Line_Type__c = null;
	    shipLine1.Subtransaction_Type__c = 'Goods';
	    shipLineList.add(shipLine1);
	    
	    Shipment_Line__c shipLine2 = new Shipment_Line__c();
	    shipLine2.Company__c = data.company.id;
	    shipLine2.Extended_Cost__c = 5;
	    shipLine2.Quantity_Shipped__c = 5;
	    shipLine2.Sales_Order__c = data.salesOrder1.id;
	    shipLine2.Sales_Order_Line__c = data.SalesOrderLineList[1].id;
	    shipLine2.Unit_Price__c = 25;
	    shipLine2.Product__c = data.product.id;
	    shipLine2.Location__c = data.location.id;
	    shipLine2.Shipment__c = shipment1.id;
	    shipLine2.Line_Type__c = null;
	    shipLine2.Subtransaction_Type__c = 'Goods';	    
	    shipLineList.add(shipLine2);

	    
	    List<Shipment_Line__c> shipLineList2 = new List<Shipment_Line__c>();
	    Shipment_Line__c shipLine3 = new Shipment_Line__c();
	    shipLine3.Company__c = data.company.id;
	    shipLine3.Extended_Cost__c = 5;
	    shipLine3.Quantity_Shipped__c = 5;
	    shipLine3.Sales_Order__c = data.salesOrder2.id;
	    shipLine3.Sales_Order_Line__c = data.SalesOrderLineList[2].id;
	    shipLine3.Unit_Price__c = 25;
	    shipLine3.Product__c = data.product.id;
	    shipLine3.Location__c = data.location.id;
	    shipLine3.Shipment__c = shipment2.id;
	   	shipLine3.Line_Type__c = null;
	    shipLine3.Subtransaction_Type__c = 'Goods';
	    shipLineList.add(shipLine3);
	    
	    Shipment_Line__c shipLine4 = new Shipment_Line__c();
	    shipLine4.Company__c = data.company.id;
	    shipLine4.Extended_Cost__c = 5;
	    shipLine4.Quantity_Shipped__c = 5;
	    shipLine4.Sales_Order__c = data.salesOrder2.id;
	    shipLine4.Sales_Order_Line__c = data.SalesOrderLineList[3].id;
	    shipLine4.Unit_Price__c = 25;
	    shipLine4.Product__c = data.product.id;
	    shipLine4.Location__c = data.location.id;
	    shipLine4.Shipment__c = shipment2.id;
	    shipLine4.Line_Type__c = null;
	    shipLine4.Subtransaction_Type__c = 'Goods';	    
	    shipLineList.add(shipLine4);
	    
	    insert shipLineList;
	    
	    shipmentList[0].Finalized__c = true;
	    shipmentList[1].Finalized__c = true;
	    update shipmentList;

	    Set<Id> shipmentIds = new Set<Id>();
	    for(Shipment__c shipment: shipmentList){
	        shipmentIds.add(shipment.id);
	    }
	    
	    List<Shipment__c> shipList = [Select id, Name, Finalized__c, Finalized_hidden__c 
	                                        from Shipment__c
	                                        where id in :shipmentIds ];
	    for(Shipment__c shipment: shipList){
	        system.assertEquals(true, shipment.Finalized__c);
	        system.assertEquals(true, shipment.Finalized_hidden__c);
	    }
	    boolean sawException = false;
	    try{
	        shipList[0].Finalized__c = false;
	        update shipList[0];
	    }catch(Exception e){
	        sawException = true;
	    }
	    
	    system.assertEquals(true, sawException);
	    
	   	ShipmentAccounting sa = new ShipmentAccounting();
	    //sa.execute(ShipmentList);		

	    //CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
        //cia.execute(new List<Customer_Invoice__c>{custInvoice1});

        //Set<Id> companyIds = new Set<Id>{data.company.id};

		//Test.startTest();
			//Database.executebatch(new ShipmentAccountingBatch(companyIds));
		//Test.stopTest();
		//cia = new CustomerInvoiceAccounting();
        List<Shipment_Line__c> sls = [SELECT Id,Shipment__c
        												FROM Shipment_Line__c
        												WHERE Shipment__c in :shipmentIds];

        sa.execute(sls);    
	    
	    List<Accounting_Entry__c> acctEntry = [Select id, Name, Shipment__c
	                                            from Accounting_Entry__c 
	                                            where Shipment__c in :shipmentIds];
	    
	    system.assertNotEquals(null,acctEntry);
	    // TODO: SK- restest after the acctg rules are modified to populate the COMP Ledger
	    system.assertEquals(2,acctEntry.size());
	    
	}
	
	//1. Create header missing company, transaction currency , transaction date 
	//2. Create header without line and finalize it 
	//3. create header and one line finalize
	//4. update line created in step3
	//5. add new line to the header created in step3
	//6. delete new line created in step 5
	//7. undelete line deleted in step 6 
		
	static testmethod void testShipmentHeaderFinalize(){
		
		TestFuel fuel = new TestFuel();
    	Company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;
    	
	   	
	   	List<Shipment__c> shipmentList = new List<Shipment__c>();
	   	
	    Shipment__c shipment1 = new Shipment__c();
	    shipment1.Date_Shipped__c = system.now();
	    shipment1.Transaction_Date__c = system.now();
	    shipment1.Currency__c = TestFuel.currencyUSD.id;
	    shipment1.finalized__c = true;
	    shipment1.status__c = 'Confirmed';
	    
	    Test.startTest();
	    boolean sawException = false;
	    string exMsg = null;
	    
	    try{
	    	insert shipment1;
	    }catch(Exception ex){
	    	exMsg = ex.getMessage();
	    	sawException = true;
	    }
	    system.assertEquals(true, sawException); // company can not be null
	    
	    exMsg = null;
	    sawException = false;
	   	shipment1.Company__c = company.id;
	   	shipment1.Transaction_date__c = null;
	   	shipment1.finalized__c = true;
	   	try{
	   		update shipment1;
	   	}catch(Exception ex){
	   		exMsg = ex.getMessage();
	   		sawException = true;
	   	}
	   	system.assertEquals(true, sawException);// transaction date can not be null
	    
	    exMsg = null;
	    sawException = false;
	   	shipment1.Currency__c = null;
	   	shipment1.Transaction_date__c = system.now();
	   	shipment1.finalized__c = true;
	   	try{
	   		update shipment1;
	   	}catch(Exception ex){
	   		exMsg = ex.getMessage();
	   		sawException = true;
	   	}
	   	system.assertEquals(true, sawException); // transaction currency can not be null
	   	
	   	exMsg = null;
	   	sawException = false;
	   	shipment1.Currency__c = TestFuel.currencyUSD.id;
	   	shipment1.finalized__c = true;
	   	try{
	   		update shipment1;
	   	}catch(Exception ex){
	   		exMsg = ex.getMessage();
	   		sawException = true;
	   	}
	    // shipment without lines can not be finalized
	    system.assert(sawException, 'We are expecting to see an exception for attempting to finalized a doc without lines' + exMsg );
	    Test.stopTest();
	}
	
	static testmethod void testShipmentLineUpdate(){
		TestFuel fuel = new TestFuel();
		Company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;

	   	List<Shipment__c> shipmentList = new List<Shipment__c>();
	   	
	    Shipment__c shipment1 = new Shipment__c();
	    shipment1.Date_Shipped__c = system.now();
	    shipment1.Transaction_Date__c = system.now();
	    shipment1.Currency__c = TestFuel.currencyUSD.id;
	    shipment1.company__c = company.id;
	    shipment1.status__c = 'Confirmed';
	    
	    insert shipment1;
	    
	    Shipment_Line__c shipLine1 = new Shipment_Line__c();
	    shipLine1.Company__c = company.id;
	    shipLine1.Extended_Cost__c = 5;
	    shipLine1.Quantity_Shipped__c = 5;
	    shipLine1.Sales_Order__c = fuel.salesOrder.id;
	    shipLine1.Sales_Order_Line__c = fuel.salesOrderLines[0].id;
	    shipLine1.Unit_Price__c = 25;
	    shipLine1.Product__c = fuel.product.id;
	    shipLine1.Location__c = fuel.location.id;
	    shipLine1.Shipment__c = shipment1.id;
	    shipLine1.Line_Type__c = null;
	    shipLine1.Subtransaction_Type__c = 'Goods';
	    
	    insert shipLine1;
	    
	    shipment1 = [ select id, Date_Shipped__c, Transaction_Date__c, Currency__c, Company__c, Status__c from Shipment__c where Id=:shipment1.id];
	    
	    shipment1.finalized__c = true;
	    update shipment1;
	    
	    Test.startTest();
	    String exMsg = null;
	    boolean sawException = false;
	    try{
	    	shipLine1.product__c = fuel.product2.id; // product field exists in finalize field set which is not meant to be modified after doc is finalized
	    	update shipLine1; 
	    }catch(Exception ex){
	    	exMsg = ex.getMessage();
	    	sawException = true;
	    }
	    Test.stopTest();
	    
	    system.assert(sawException, 'We are expecting to see an exception for attempting to edit a line of a finalized doc ' + exMsg);
	}
	
	static testmethod void testShipmentLineInsert(){
		TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;

	   	List<Shipment__c> shipmentList = new List<Shipment__c>();
	   	
	    Shipment__c shipment1 = new Shipment__c();
	    shipment1.company__c = company.id;
	    shipment1.Date_Shipped__c = system.now();
	    shipment1.Transaction_Date__c = system.now();
	    shipment1.Currency__c = TestFuel.currencyUSD.id;
	    shipment1.status__c = 'Confirmed';
	    
	    insert shipment1;
	    
	    Shipment_Line__c shipLine1 = new Shipment_Line__c();
	    shipLine1.Company__c = company.id;
	    shipLine1.Extended_Cost__c = 5;
	    shipLine1.Quantity_Shipped__c = 5;
	    shipLine1.Sales_Order__c = fuel.salesOrder.id;
	    shipLine1.Sales_Order_Line__c = fuel.salesOrderLines[0].id;
	    shipLine1.Unit_Price__c = 25;
	    shipLine1.Product__c = fuel.product.id;
	    shipLine1.Location__c = fuel.location.id;
	    shipLine1.Shipment__c = shipment1.id;
	    shipLine1.Line_Type__c = null;
	    shipLine1.Subtransaction_Type__c = 'Goods';
	    
	    insert shipLine1;
	    
	    shipment1.finalized__c = true;
	    update shipment1;
	    
	    Shipment_Line__c shipLine2 = new Shipment_Line__c();
	    shipLine2.Company__c = company.id;
	    shipLine2.Extended_Cost__c = 5;
	    shipLine2.Quantity_Shipped__c = 5;
	    shipLine2.Sales_Order__c = fuel.salesOrder.id;
	    shipLine2.Sales_Order_Line__c = fuel.salesOrderLines[0].id;
	    shipLine2.Unit_Price__c = 25;
	    shipLine2.Product__c = fuel.product.id;
	    shipLine2.Location__c = fuel.location.id;
	    shipLine2.Shipment__c = shipment1.id;
	    shipLine2.Line_Type__c = null;
	    shipLine2.Subtransaction_Type__c = 'Goods';
	    
	    Test.startTest();
	    String exMsg = null;
	    boolean sawException = false;
	    try{
	    	insert shipLine2; // new line can not be added to source doc once it is finalized
	    }catch(Exception ex){
	    	exMsg = ex.getMessage();
	    	sawException = true;
	    }
	    
	    Test.stopTest();
	    
	    system.assert(sawException, 'We are expecting to see an exception for attempting to add a line to a finalized doc ' + exMsg);
	}
	
	static testmethod void testShipmentLineDelete(){
		TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;

	   	List<Shipment__c> shipmentList = new List<Shipment__c>();
	   	
	    Shipment__c shipment1 = new Shipment__c();
	    shipment1.company__c = company.id;
	    shipment1.Date_Shipped__c = system.now();
	    shipment1.Transaction_Date__c = system.now();
	    shipment1.Currency__c = TestFuel.currencyUSD.id;
	    shipment1.status__c = 'Confirmed';
	    
	    insert shipment1;
	    
	    Shipment_Line__c shipLine1 = new Shipment_Line__c();
	    shipLine1.Company__c = company.id;
	    shipLine1.Extended_Cost__c = 5;
	    shipLine1.Quantity_Shipped__c = 5;
	    shipLine1.Sales_Order__c = fuel.salesOrder.id;
	    shipLine1.Sales_Order_Line__c = fuel.salesOrderLines[0].id;
	    shipLine1.Unit_Price__c = 25;
	    shipLine1.Product__c = fuel.product.id;
	    shipLine1.Location__c = fuel.location.id;
	    shipLine1.Shipment__c = shipment1.id;
	    shipLine1.Line_Type__c = null;
	    shipLine1.Subtransaction_Type__c = 'Goods';
	    
	    insert shipLine1;
	    
	    shipment1.finalized__c = true;
	    update shipment1;
	    
	    Test.startTest();
	    String exMsg = null;
	    boolean sawException = false;
	    try{
	    	delete shipLine1; //  line can not be deleted from a source doc once it is finalized
	    }catch(Exception ex){
	    	exMsg = ex.getMessage();
	    	sawException = true;
	    }
	    Test.stopTest();
	    
	    system.assert(sawException, 'We are expecting to see an exception for attempting to delete a line from a finalized doc ' + exMsg);
	}
	
	static testmethod void testShipmentLineUndelete(){
		TestFuel fuel = new TestFuel();
		company__c company = fuel.company;
    	List<Period__c> periods = fuel.periodList;

	   	List<Shipment__c> shipmentList = new List<Shipment__c>();
	   	
	    Shipment__c shipment1 = new Shipment__c();
	    shipment1.company__c = company.id;
	    shipment1.Date_Shipped__c = system.now();
	    shipment1.Transaction_Date__c = system.now();
	    shipment1.Currency__c = TestFuel.currencyUSD.id;
	    
	    insert shipment1;
	    
	    List<Shipment_Line__c> shipLineList = new List<Shipment_Line__c>();
	    Shipment_Line__c shipLine1 = new Shipment_Line__c();
	    shipLine1.Company__c = company.id;
	    shipLine1.Extended_Cost__c = 5;
	    shipLine1.Quantity_Shipped__c = 5;
	    shipLine1.Sales_Order__c = fuel.salesOrder.id;
	    shipLine1.Sales_Order_Line__c = fuel.salesOrderLines[0].id;
	    shipLine1.Unit_Price__c = 25;
	    shipLine1.Product__c = fuel.product.id;
	    shipLine1.Location__c = fuel.location.id;
	    shipLine1.Shipment__c = shipment1.id;
	    shipLine1.Line_Type__c = null;
	    shipLine1.Subtransaction_Type__c = 'Goods';
	    shipLineList.add(shipLine1);
	    
	    Shipment_Line__c shipLine2 = new Shipment_Line__c();
	    shipLine2.Company__c = company.id;
	    shipLine2.Extended_Cost__c = 5;
	    shipLine2.Quantity_Shipped__c = 5;
	    shipLine2.Sales_Order__c = fuel.salesOrder.id;
	    shipLine2.Sales_Order_Line__c = fuel.salesOrderLines[1].id;
	    shipLine2.Unit_Price__c = 25;
	    shipLine2.Product__c = fuel.product2.id;
	    shipLine2.Location__c = fuel.location.id;
	    shipLine2.Shipment__c = shipment1.id;
	    shipLine2.Line_Type__c = null;
	    shipLine2.Subtransaction_Type__c = 'Goods';
	    shipLineList.add(shipLine2);
	    
	    insert shipLineList;
		delete shipLine2;
		
		shipment1.status__c = 'Confirmed';
		shipment1.finalized__c = true;
	    update shipment1;
	    
	    Test.startTest();
	    String exMsg = null;
	    boolean sawException = false;
	    try{
	    	undelete shipLine1; 
	    }catch(Exception ex){
	    	exMsg = ex.getMessage();
	    	sawException = true;
	    }
	    Test.stopTest();
	    
	    system.assert(sawException, 'We are expecting to see an exception for attempting to undelete a line for a finalized doc ' + exMsg);
	}
	
	//FIN-954 Test if the new field Transaction Type is used by accounting process to book 
	
		static testmethod void testNewTransactionTypeFieldUsedInShipmentAccounting()
		{
			TestFuel fuel = new TestFuel();
			company__c company = fuel.company;
	    	List<Period__c> periods = fuel.periodList;
	    	
            List<Item_Cost__c> itemcostList = new List<Item_Cost__c>();
        
            Item_Cost__c ItemCostObj = new Item_Cost__c();
            ItemCostObj.Item__c = fuel.itemList[0].ID;
            ItemCostObj.Status__c = 'Proposed';
            //ItemCostObj.Date_Activated__c = system.today();
            ItemCostObj.Material_Cost__c = 30;
            ItemCostObj.Labor_Cost__c = 10;
            ItemCostObj.Outside_Processing_Cost__c = 20;
            ItemCostObj.Overhead_Cost__c = 5;
            ItemCostObj.Start_date__c = DateTime.now().addHours(-1);
            ItemCostObj.Company__c = fuel.company.Id;
            itemcostList.add(ItemCostObj);
            
            Item_Cost__c ItemCostObj2 = new Item_Cost__c();
            ItemCostObj2.Item__c = fuel.itemList[5].ID;
            ItemCostObj2.Status__c = 'Proposed';
            //ItemCostObj2.Date_Activated__c = system.today();
            ItemCostObj2.Material_Cost__c = 550;
            ItemCostObj2.Labor_Cost__c = 10;
            ItemCostObj2.Outside_Processing_Cost__c = 20;
            ItemCostObj2.Overhead_Cost__c = 5;
            ItemCostObj2.Start_date__c = DateTime.now().addHours(-1);
            ItemCostObj2.Company__c = fuel.company.Id;
            itemcostList.add(ItemCostObj2);
            
            insert itemcostList;
            
            for(Item_Cost__c ic : itemcostList){
                ic.Status__c = 'Approved';
                ic.Date_Approved__c = DateTime.now();
                //ic.Date_Activated__c = system.today();
            }
        	ItemService.allowItemCostUpdate = true;
            update itemcostList;
	
			List<accounting_rule__c> arList = new list<accounting_rule__c>();
			
			Accounting_Rule__c shipacctRule1 = new Accounting_Rule__c();
            shipacctRule1.Object_Name__c = 'Shipment__c';
            //shipacctRule1.Company__c = company.id;
            shipacctRule1.Accounting_Standard__c = fuel.accountingStandard.Id;
            shipacctRule1.Transaction__c = 'Logical Sales Order Shipment';
            shipacctRule1.SubTransaction_Type__c = 'Goods';
            shipacctRule1.Line_Type__c = 'Standard';
            shipacctRule1.Rule_Type__c = 'CR';
            shipacctRule1.Default_GL_Account__c = true;
            shipacctRule1.GL_Account__c = fuel.receivablesGL.id;
            shipacctRule1.Amount_Reference__c = null;    
            shipacctRule1.Effective_Start_Date__c=fuel.effStartDate;                         
            arList.add(shipacctRule1);
            
            Accounting_Rule__c shipacctRule2 = new Accounting_Rule__c();
            shipacctRule2.Object_Name__c = 'Shipment__c';
            //shipacctRule2.Company__c = company.id;
            shipacctRule2.Accounting_Standard__c = fuel.accountingStandard.Id;
            shipacctRule2.Transaction__c = 'Logical Sales Order Shipment';
            shipacctRule2.SubTransaction_Type__c = 'Goods';
            shipacctRule2.Line_Type__c = 'Standard';
            shipacctRule2.Rule_Type__c = 'DR';
            shipacctRule2.Default_GL_Account__c = true;
            shipacctRule2.GL_Account_Reference_Value__c = null;
            shipacctRule2.GL_Account__c = fuel.revenueGL.id;
            shipacctRule2.Amount_Reference__c = null;        
            shipacctRule2.Effective_Start_Date__c=fuel.effStartDate;            
            arList.add(shipacctRule2);   
            
            insert arList;
            
            
            
		   	
		    Shipment__c shipment1 = new Shipment__c();
		    shipment1.company__c = company.id;
		    shipment1.Date_Shipped__c = system.now();
		    shipment1.Transaction_Date__c = system.now();
		    shipment1.Currency__c = TestFuel.currencyUSD.id;
		    shipment1.Transaction_Type__c =  'Logical Sales Order Shipment';
	       shipment1.Status__c = 'Confirmed';
		    
		    insert shipment1;
		    
		    List<Shipment_Line__c> shipLineList = new List<Shipment_Line__c>();
		    Shipment_Line__c shipLine1 = new Shipment_Line__c();
		    shipLine1.Company__c = company.id;
		    shipLine1.Extended_Cost__c = 5;
		    shipLine1.Quantity_Shipped__c = 5;
		    shipLine1.Sales_Order__c = fuel.salesOrder.id;
		    shipLine1.Sales_Order_Line__c = fuel.salesOrderLines[0].id;
		    shipLine1.Unit_Price__c = 25;
		    shipLine1.Product__c = fuel.product.id;
		    shipLine1.Location__c = fuel.location.id;
		    shipLine1.Shipment__c = shipment1.id;
		    shipLine1.Line_Type__c = 'Standard';
		    shipLine1.Subtransaction_Type__c = 'Goods';
		    shipLineList.add(shipLine1);
		    
		    Shipment_Line__c shipLine2 = new Shipment_Line__c();
		    shipLine2.Company__c = company.id;
		    shipLine2.Extended_Cost__c = 5;
		    shipLine2.Quantity_Shipped__c = 5;
		    shipLine2.Sales_Order__c = fuel.salesOrder.id;
		    shipLine2.Sales_Order_Line__c = fuel.salesOrderLines[1].id;
		    shipLine2.Unit_Price__c = 25;
		    shipLine2.Product__c = fuel.product2.id;
		    shipLine2.Location__c = fuel.location.id;
		    shipLine2.Shipment__c = shipment1.id;
		    shipLine2.Line_Type__c = 'Standard';
		    shipLine2.Subtransaction_Type__c = 'Goods';
		    shipLineList.add(shipLine2);
		    
		    insert shipLineList;	
            shipment1.Finalized__c = true;
            update shipment1;
    

            
            List<Shipment__c> shipList = [Select id, Name, Finalized__c, Finalized_hidden__c ,transaction_type__c,(select id,name,subtransaction_type__c,line_type__c from shipment_lines__r)
                                                from Shipment__c
                                                where id = :shipment1.id ];
            system.assertEquals(true, shipList[0].Finalized__c);
            system.assertEquals(true, shipList[0].Finalized_hidden__c);
            system.assertEquals('Logical Sales Order Shipment', shipList[0].transaction_type__c);
            system.assertEquals('Goods', shipList[0].shipment_lines__r[0].subtransaction_type__c);
            system.assertEquals('Standard', shipList[0].shipment_lines__r[0].line_type__c);
            system.assertEquals('Goods', shipList[0].shipment_lines__r[1].subtransaction_type__c);
            system.assertEquals('Standard', shipList[0].shipment_lines__r[1].line_type__c);  
            
		    shipmentAccounting sha = new shipmentAccounting();
		    sha.execute(shipLineList);
		    
		    list<accounting_entry__c> AEs= [select id,name,transaction_type__c,(select id,name from accounting_entry_lines__r where has_exceptions__c=false ) 
										     from accounting_entry__c
										     where status__c='Active'
                                             and has_exceptions__c=false
										     ];	
		    //list<task> t1=[select id,description from task where whatid = :AEs[0].id];
            //list<task> t2=[select id,description from task where whatid in (:AEs[0].accounting_entry_lines__r[0].id,:AEs[0].accounting_entry_lines__r[1].id)];
            //system.assertEquals(t1, null);
            //system.assertEquals(t2, null);
  		    system.assertNotEquals(AEs.size(),0,'Expecting active AEs without any exceptions');          
			system.assertNotEquals(AEs[0].accounting_entry_lines__r.size(),0,'Expecting active AELs without any exceptions');
		    system.assertEquals(AEs[0].transaction_type__c,'Logical Sales Order Shipment','Expecting the transaction type from the SH to be used');
												
		}
			
		
		// Test missing item cost
		static testmethod void testMissingItemCostOnShipmentAccounting()
		{
			TestFuel fuel = new TestFuel();
			company__c company = fuel.company;
	    	List<Period__c> periods = fuel.periodList;
	    	
            List<Item_Cost__c> itemcostList = new List<Item_Cost__c>();
 		
			List<accounting_rule__c> arList = new list<accounting_rule__c>();
			Test.startTest();
			Accounting_Rule__c shipacctRule1 = new Accounting_Rule__c();
            shipacctRule1.Object_Name__c = 'Shipment__c';
            shipacctRule1.Company__c = company.id;
            shipacctRule1.Transaction__c = 'Logical Sales Order Shipment';
            shipacctRule1.SubTransaction_Type__c = 'Goods';
            shipacctRule1.Line_Type__c = 'Standard';
            shipacctRule1.Rule_Type__c = 'CR';
            shipacctRule1.Default_GL_Account__c = true;
            shipacctRule1.GL_Account__c = fuel.receivablesGL.id;
            shipacctRule1.Amount_Reference__c = null;      
            shipacctRule1.Effective_Start_Date__c=fuel.effStartDate;      
            arList.add(shipacctRule1);
            
            Accounting_Rule__c shipacctRule2 = new Accounting_Rule__c();
            shipacctRule2.Object_Name__c = 'Shipment__c';
            shipacctRule2.Company__c = company.id;
            shipacctRule2.Transaction__c = 'Logical Sales Order Shipment';
            shipacctRule2.SubTransaction_Type__c = 'Goods';
            shipacctRule2.Line_Type__c = 'Standard';
            shipacctRule2.Rule_Type__c = 'DR';
            shipacctRule2.Default_GL_Account__c = true;
            shipacctRule2.GL_Account_Reference_Value__c = null;
            shipacctRule2.GL_Account__c = fuel.revenueGL.id;
            shipacctRule2.Amount_Reference__c = null;       
            shipacctRule2.Effective_Start_Date__c=fuel.effStartDate;                          
            arList.add(shipacctRule2);   
            
            insert arList;
 	    	
 	    	Shipment__c shipment1 = new Shipment__c();
		    shipment1.company__c = company.id;
		    shipment1.Date_Shipped__c = system.now();
		    shipment1.Transaction_Date__c = system.now();
		    shipment1.Currency__c = TestFuel.currencyUSD.id;
		    shipment1.Transaction_Type__c =  'Logical Sales Order Shipment';
	       	shipment1.Status__c = 'Confirmed';
		    
		    insert shipment1;
		    
		    List<Shipment_Line__c> shipLineList = new List<Shipment_Line__c>();
		    Shipment_Line__c shipLine1 = new Shipment_Line__c();
		    shipLine1.Company__c = company.id;
		    shipLine1.Extended_Cost__c = 5;
		    shipLine1.Quantity_Shipped__c = 5;
		    shipLine1.Sales_Order__c = fuel.salesOrder.id;
		    shipLine1.Sales_Order_Line__c = fuel.salesOrderLines[0].id;
		    shipLine1.Unit_Price__c = 25;
		    shipLine1.Product__c = fuel.product.id;
		    shipLine1.Location__c = fuel.location.id;
		    shipLine1.Shipment__c = shipment1.id;
		    shipLine1.Line_Type__c = 'Standard';
		    shipLine1.Subtransaction_Type__c = 'Goods';
		    shipLineList.add(shipLine1);
		    
		    Shipment_Line__c shipLine2 = new Shipment_Line__c();
		    shipLine2.Company__c = company.id;
		    shipLine2.Extended_Cost__c = 5;
		    shipLine2.Quantity_Shipped__c = 5;
		    shipLine2.Sales_Order__c = fuel.salesOrder.id;
		    shipLine2.Sales_Order_Line__c = fuel.salesOrderLines[1].id;
		    shipLine2.Unit_Price__c = 25;
		    shipLine2.Product__c = fuel.product2.id;
		    shipLine2.Location__c = fuel.location.id;
		    shipLine2.Shipment__c = shipment1.id;
		    shipLine2.Line_Type__c = 'Standard';
		    shipLine2.Subtransaction_Type__c = 'Goods';
		    shipLineList.add(shipLine2);
		    
		    insert shipLineList;	
            shipment1.Finalized__c = true;
            update shipment1;
          
            List<Shipment__c> shipList = [Select id, Name, Finalized__c, Finalized_hidden__c ,transaction_type__c,(select id,name,subtransaction_type__c,line_type__c from shipment_lines__r)
                                                from Shipment__c
                                                where id = :shipment1.id ];
            system.assertEquals(true, shipList[0].Finalized__c);
            system.assertEquals(true, shipList[0].Finalized_hidden__c);
            system.assertEquals('Logical Sales Order Shipment', shipList[0].transaction_type__c);
            system.assertEquals('Goods', shipList[0].shipment_lines__r[0].subtransaction_type__c);
            system.assertEquals('Standard', shipList[0].shipment_lines__r[0].line_type__c);
            system.assertEquals('Goods', shipList[0].shipment_lines__r[1].subtransaction_type__c);
            system.assertEquals('Standard', shipList[0].shipment_lines__r[1].line_type__c);  
            
		    shipmentAccounting sha = new shipmentAccounting();
		    sha.execute(shipLineList);
		    Test.stopTest();
		    list<accounting_entry__c> AEs= [select id,name,transaction_type__c, (select id,name, item_cost_missing__c from accounting_entry_lines__r where has_exceptions__c=true ) 
										     from accounting_entry__c
										     where status__c='Active'
                                             
										     ];	
										     
			system.assertNotEquals(AEs.size(),0,'Expecting active AEs without any exceptions');
 
			for(Accounting_Entry__c ae: AEs){
				for(Accounting_Entry_Line__c ael : ae.accounting_entry_lines__r ){
					system.assert(ael.item_cost_missing__c == true,'ael:'+ael);
				}
			}
			
		}
	
		static testmethod void testTransferOrderShipmentAccounting()
		{
			TestFuel fuel = new TestFuel();
			company__c company = fuel.company;
	    	List<Period__c> periods = fuel.periodList;
	    	
            List<Item_Cost__c> itemcostList = new List<Item_Cost__c>(fuel.costList);

            
			List<accounting_rule__c> arList = new list<accounting_rule__c>();
			
			Accounting_Rule__c shipacctRule1 = new Accounting_Rule__c();
            shipacctRule1.Object_Name__c = 'Shipment__c';
            shipacctRule1.Company__c = company.id;
            shipacctRule1.Transaction__c = 'Transfer Order Shipment';
            shipacctRule1.SubTransaction_Type__c = null;
            shipacctRule1.Line_Type__c = null;
            shipacctRule1.Rule_Type__c = 'CR';
            shipacctRule1.Default_GL_Account__c = true;
            shipacctRule1.GL_Account__c = fuel.receivablesGL.id;
            shipacctRule1.Amount_Reference__c = null;            
 	     	shipacctRule1.Effective_Start_Date__c = fuel.effStartDate;            
            arList.add(shipacctRule1);
            
            Accounting_Rule__c shipacctRule2 = new Accounting_Rule__c();
            shipacctRule2.Object_Name__c = 'Shipment__c';
            shipacctRule2.Company__c = company.id;
            shipacctRule2.Transaction__c = 'Transfer Order Shipment';
            shipacctRule2.SubTransaction_Type__c = null;
            shipacctRule2.Line_Type__c = null;
            shipacctRule2.Rule_Type__c = 'DR';
            shipacctRule2.Default_GL_Account__c = true;
            shipacctRule2.GL_Account_Reference_Value__c = null;
            shipacctRule2.GL_Account__c = fuel.revenueGL.id;
            shipacctRule2.Amount_Reference__c = null;    
 	     	shipacctRule2.Effective_Start_Date__c = fuel.effStartDate;                                   
            arList.add(shipacctRule2);   
            
            insert arList;
 	    	
 	    	Shipment__c shipment1 = new Shipment__c();
		    shipment1.company__c = company.id;
		    shipment1.Date_Shipped__c = system.now();
		    shipment1.Transaction_Date__c = system.now();
		    shipment1.Currency__c = TestFuel.currencyUSD.id;
		    shipment1.Transaction_Type__c =  'Transfer Order Shipment';
	       	shipment1.Status__c = 'Confirmed';
		    
		    insert shipment1;
		    
		    List<Shipment_Line__c> shipLineList = new List<Shipment_Line__c>();
		    Shipment_Line__c shipLine1 = new Shipment_Line__c();
		    shipLine1.Company__c = company.id;
		    shipLine1.Extended_Cost__c = 5;
		    shipLine1.Quantity_Shipped__c = 5;
		    shipLine1.Order__c = fuel.transferorder.id;
		    shipLine1.Order_Line__c = fuel.transferOrderLines[1].id;
		    shipLine1.Unit_Price__c = 25;
		    shipLine1.Product__c = null;
 		    shipLine1.item__c =  fuel.itemList[5].id;
		    shipLine1.Location__c = fuel.location.id;
		    shipLine1.facility__c = fuel.facility.id;            
		    shipLine1.Shipment__c = shipment1.id;
		    shipLine1.Line_Type__c = null;
		    shipLine1.Subtransaction_Type__c = null;
		    shipLineList.add(shipLine1);
		    
		    insert shipLineList;	
            shipment1.Finalized__c = true;
            update shipment1;
          
            List<Shipment__c> shipList = [Select id, Name, Finalized__c, Finalized_hidden__c ,transaction_type__c,(select id,name,subtransaction_type__c,line_type__c from shipment_lines__r)
                                                from Shipment__c
                                                where id = :shipment1.id ];
            system.assertEquals(true, shipList[0].Finalized__c);
            system.assertEquals(true, shipList[0].Finalized_hidden__c);
            system.assertEquals('Transfer Order Shipment', shipList[0].transaction_type__c);
            system.assertEquals(null, shipList[0].shipment_lines__r[0].subtransaction_type__c);
            system.assertEquals(null, shipList[0].shipment_lines__r[0].line_type__c);
            
		    shipmentAccounting sha = new shipmentAccounting();
		    sha.execute(shipLineList);
		    
		    list<accounting_entry__c> AEs= [select id,name,transaction_type__c, (select id,name, item_cost_missing__c from accounting_entry_lines__r  ) 
										     from accounting_entry__c
										     where status__c='Active' 
										     ];	
			system.assertNotEquals(AEs.size(),0,'Expecting active AEs without any exceptions');
			system.assertNotEquals(AEs[0].accounting_entry_lines__r.size(),0,'Expecting active AELs without any exceptions');
 
			for(Accounting_Entry__c ae: AEs){
				for(Accounting_Entry_Line__c ael : ae.accounting_entry_lines__r ){
					system.assertEquals(ael.item_cost_missing__c , false,'ael:'+ael);
				}
			}
			
		}
	*/
}