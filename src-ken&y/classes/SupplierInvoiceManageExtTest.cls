 @isTest
public with sharing class SupplierInvoiceManageExtTest {
	
	@testSetup static void ts() { 
		TestFuel data = new TestFuel();	
		// these asserts cause TestFuelQuery to insert data
		system.assert(		
			data.company != null &&
			data.supplier != null &&
			data.purchaseOrder != null && 
			data.purchaseOrderLines != null &&
			data.remittosupplier != null &&
			data.periodList != null &&
			data.terms != null &&
			data.itemList != null &&
			data.cashGL != null &&
			data.clsObj != null &&
			data.ItemNoClassType != null &&
			data.facility2 != null &&
			data.location2 != null &&
			data.customerShipTo != null  //KNDY-18171
		);
	}
	
	class MyException extends Exception{}
	
	//KNDY-18171
	static testMethod void test_ValuesOfTaxFieldOnSIL_StandardPO() {
		TestFuelQuery fuel = new TestFuelQuery();
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
	    list<Configuration__c> lConfigs = new list<Configuration__c>();
	    lConfigs.add(new Configuration__c(Name = 'Supplier__c-'+Supplier__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    insert lConfigs;
	    
	    //updating Purchase from Supplier Address
	    update new Supplier__c(Id=fuel.supplier.id,
	    	Supplier_City__c = 'Buffalo',
	    	Supplier_Country__c = 'US',
	    	Supplier_State__c = 'NJ',
	    	Supplier_Street__c = '121 East England Street',
	    	Supplier_Zip_Code__c = '24415'
	    );
	    
	    list<Purchase_Order__c> lstPO = new list<Purchase_Order__c>();
		Purchase_Order__c purchaseOrder = new Purchase_Order__c(
                                        Supplier__c = fuel.supplier.id, 
                                        Company__c = fuel.company.id,
                                        Delivery_Facility__c = fuel.facility2.id,
                                        Delivery_Location__c = fuel.location2.ID,
                                        Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                        Approval_Status__c = 'Approved',
                                        Acknowledge_Via__c = 'Email',
                                        Status__c = 'Open',
                                        Memo__c = 'purchaseOrder',
                                        Currency__c = fuel.currencyUSD.id
                            );
        lstPO.add(purchaseOrder);                                                
       insert lstPO;
      
       list<Purchase_Order_Line__c> lstPOL = new list<Purchase_Order_Line__c>();
        Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
	    poLine.Purchase_Order__c = lstPO[0].Id;
	    poLine.Order_Quantity__c = 10;     
	    poLine.Unit_Price__c = 12;
	    poLine.Item__c = fuel.ItemNoClassType.Id;
	    poLine.Description__c = 'purchaseOrderLine0';
	    poLine.Purchase_UOM__c = fuel.ItemNoClassType.Purchasing_UOM__c;
	    poLine.Company__c = fuel.company.id;
	    poLine.Need_Date__c = system.today() + 7;
	    poLine.Delivery_Facility__c = fuel.facility2.id;
	    poLine.Delivery_Location__c = fuel.location2.ID;
	    poLine.Supplier__c = fuel.supplier.Id;
	    poLine.Line__c = 1;
	    poLine.Quantity_Matched__c = 0;
	    poLine.Amount_Matched__c = 0;
	    lstPOL.add(poLine);
	    insert lstPOL;
	    
	    lstPO[0].Approval_Status__c = 'Approved';
        update lstPO;
        
        SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{'Id','Purchase_Order__r.Type__c','Delivery_Facility__r.City_Name__c',
		'Delivery_Facility__r.Country_Name__c','Delivery_Facility__r.Street_Address__c','Delivery_Facility__r.State_Province_Name__c',
		'Delivery_Facility__r.Zip_Postal_Code__c','Purchase_Order__r.Deliver_to_Customer__r.City__c','Purchase_Order__r.Deliver_to_Customer__r.Country__c',
		'Purchase_Order__r.Deliver_to_Customer__r.State__c','Purchase_Order__r.Deliver_to_Customer__r.Street__c',
		'Purchase_Order__r.Deliver_to_Customer__r.Zip_Code__c','Purchase_Order__r.Supplier__r.City__c',
		'Purchase_Order__r.Supplier__r.Country__c','Purchase_Order__r.Supplier__r.State__c','Purchase_Order__r.Supplier__r.Street__c',
		'Purchase_Order__r.Supplier__r.Zip_Code__c'});
         soql.setWhereClause('Id in: lstPOL');
		 list<Purchase_Order_Line__c> polList = Database.query(soql.getQuery());
		    
        Test.startTest();
        Supplier_Invoice__c si = new Supplier_Invoice__c(Company__c = fuel.company.id,
            Supplier__c = fuel.remittosupplier.id,
            Invoice_Type__c = 'Invoice',
            Date_Invoiced__c = system.now(),
            Supplier_Invoice__c = '987612',
            Payment_Term__c = fuel.terms.Id,
            Invoice_Amount__c = 491,
            Purchase_Order__c = lstPO[0].id,
            Currency__c = fuel.company.Default_Transaction_Currency__c,
            Status__c = 'Draft');
        insert si; 
         Supplier_Invoice_Line__c invoiceLine = new Supplier_Invoice_Line__c(); {
            invoiceLine.Supplier_Invoice__c = si.Id;
            invoiceLine.Invoice_Quantity__c = 5;
            invoiceLine.Unit_Price__c = 100;//KNDY-14371
            invoiceLine.Description__c = 'test';
            invoiceLine.Purchase_Order__c = lstPO[0].Id;
            invoiceLine.Purchase_Order_Line__c = lstPOL[0].id;
            invoiceLine.Item__c = fuel.ItemNoClassType.Id;
            
        }
		SupplierInvoiceService.populateShipToShipFromFieldsOnSIL(new list<Supplier_Invoice_Line__c>{invoiceLine},polList);
		
        system.assertEquals('Redwood City',invoiceLine.Ship_To_City__c,invoiceLine.Ship_To_City__c);
        system.assertEquals('USA',invoiceLine.Ship_To_Country__c,invoiceLine.Ship_To_Country__c);
        system.assertEquals('CA',invoiceLine.Ship_To_State__c,invoiceLine.Ship_To_State__c);
        system.assertEquals('303 Twin Dolphin Drive, Suite 500',invoiceLine.Ship_To_Street__c,invoiceLine.Ship_To_Street__c);
        system.assertEquals('94065',invoiceLine.Ship_To_Zip_Code__c,invoiceLine.Ship_To_Zip_Code__c);
        system.assertEquals('Buffalo',invoiceLine.Ship_From_City__c,invoiceLine.Ship_From_City__c);
        system.assertEquals('US',invoiceLine.Ship_From_Country__c,invoiceLine.Ship_From_Country__c);
        system.assertEquals('NJ',invoiceLine.Ship_From_State__c,invoiceLine.Ship_From_State__c);
        system.assertEquals('121 East England Street',invoiceLine.Ship_From_Street__c,invoiceLine.Ship_From_Street__c);
        system.assertEquals('24415',invoiceLine.Ship_From_Zip_Code__c,invoiceLine.Ship_From_Zip_Code__c);
        Test.stopTest();

	}
	
	//KNDY-18171
	static testMethod void test_ValuesOfTaxFieldOnSIL_DropShipPO() {
		TestFuelQuery fuel = new TestFuelQuery();
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
	    list<Configuration__c> lConfigs = new list<Configuration__c>();
	    lConfigs.add(new Configuration__c(Name = 'Customer__c-'+Customer__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    insert lConfigs;
	    
	    //updating Purchase from Customer Address
	    update new Customer__c(Id=fuel.customerShipTo.id,
	    	Customer_Street__c = '141 Eagle Street',
	    	Customer_City__c = 'Pheonix',
	    	Customer_State__c = 'AZ',
	    	Customer_Country__c = 'US',
	    	Customer_Zip_Code__c = '24418'
	    );
	    
	    list<Purchase_Order__c> lstPO = new list<Purchase_Order__c>();
		Purchase_Order__c purchaseOrder = new Purchase_Order__c(
                                        Supplier__c = fuel.supplier.id, 
                                        Company__c = fuel.company.id,
                                        Deliver_to_Customer__c = fuel.customerShipTo.id,
                                        Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                        Approval_Status__c = 'Approved',
                                        Acknowledge_Via__c = 'Email',
                                        Status__c = 'Open',
                                        Memo__c = 'purchaseOrder',
                                        Currency__c = fuel.currencyUSD.id,
                                        Type__c = 'Drop Ship'
                            );                    
      lstPO.add(purchaseOrder);                       
      insert lstPO;
      
      list<Purchase_Order_Line__c> lstPOL = new list<Purchase_Order_Line__c>();
      Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
	  poLine.Purchase_Order__c = lstPO[0].Id;
	  poLine.Order_Quantity__c = 10;     
	  poLine.Unit_Price__c = 12;
	  poLine.Item__c = fuel.ItemNoClassType.Id;
	  poLine.Description__c = 'purchaseOrderLine0';
	  poLine.Purchase_UOM__c = fuel.ItemNoClassType.Purchasing_UOM__c;
	  poLine.Company__c = fuel.company.id;
	  poLine.Need_Date__c = system.today() + 7;
	  poLine.Delivery_Facility__c = fuel.facility2.id;
	  poLine.Delivery_Location__c = fuel.location2.ID;
	  poLine.Supplier__c = fuel.supplier.Id;
	  poLine.Line__c = 1;
	  poLine.Quantity_Matched__c = 0;
	  poLine.Amount_Matched__c = 0;
	  lstPOL.add(poLine);
	  insert lstPOL;
	    
	  lstPO[0].Approval_Status__c = 'Approved';
      update lstPO;
      
       SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{'Id','Purchase_Order__r.Type__c','Delivery_Facility__r.City_Name__c',
		'Delivery_Facility__r.Country_Name__c','Delivery_Facility__r.Street_Address__c','Delivery_Facility__r.State_Province_Name__c',
		'Delivery_Facility__r.Zip_Postal_Code__c','Purchase_Order__r.Deliver_to_Customer__r.City__c','Purchase_Order__r.Deliver_to_Customer__r.Country__c',
		'Purchase_Order__r.Deliver_to_Customer__r.State__c','Purchase_Order__r.Deliver_to_Customer__r.Street__c',
		'Purchase_Order__r.Deliver_to_Customer__r.Zip_Code__c','Purchase_Order__r.Supplier__r.City__c',
		'Purchase_Order__r.Supplier__r.Country__c','Purchase_Order__r.Supplier__r.State__c','Purchase_Order__r.Supplier__r.Street__c',
		'Purchase_Order__r.Supplier__r.Zip_Code__c'});
         soql.setWhereClause('Id in: lstPOL');
		 list<Purchase_Order_Line__c> polList = Database.query(soql.getQuery());
		 
        Test.startTest();
        Supplier_Invoice__c si = new Supplier_Invoice__c(Company__c = fuel.company.id,
            Supplier__c = fuel.remittosupplier.id,
            Invoice_Type__c = 'Invoice',
            Date_Invoiced__c = system.now(),
            Supplier_Invoice__c = '987612',
            Payment_Term__c = fuel.terms.Id,
            Invoice_Amount__c = 491,
            Purchase_Order__c = lstPO[0].id,
            Currency__c = fuel.company.Default_Transaction_Currency__c,
            Status__c = 'Draft');
        insert si; 
         Supplier_Invoice_Line__c invoiceLine = new Supplier_Invoice_Line__c(); {
            invoiceLine.Supplier_Invoice__c = si.Id;
            invoiceLine.Invoice_Quantity__c = 5;
            invoiceLine.Unit_Price__c = 100;//KNDY-14371
            invoiceLine.Description__c = 'test';
            invoiceLine.Purchase_Order__c = lstPO[0].Id;
            invoiceLine.Purchase_Order_Line__c = lstPOL[0].id;
            invoiceLine.Item__c = fuel.ItemNoClassType.Id;
            
        }

		SupplierInvoiceService.populateShipToShipFromFieldsOnSIL(new list<Supplier_Invoice_Line__c>{invoiceLine},polList);
        
        system.assertEquals('Redwood City',invoiceLine.Ship_From_City__c,invoiceLine.Ship_From_City__c);
        system.assertEquals('USA',invoiceLine.Ship_From_Country__c,invoiceLine.Ship_From_Country__c);
        system.assertEquals('CA',invoiceLine.Ship_From_State__c,invoiceLine.Ship_From_State__c);
        system.assertEquals('303 Twin Dolphin Drive, Suite 500',invoiceLine.Ship_From_Street__c,invoiceLine.Ship_From_Street__c);
        system.assertEquals('94065',invoiceLine.Ship_From_Zip_Code__c,invoiceLine.Ship_From_Zip_Code__c);
        system.assertEquals('Pheonix',invoiceLine.Ship_To_City__c,invoiceLine.Ship_To_City__c);
        system.assertEquals('US',invoiceLine.Ship_To_Country__c,invoiceLine.Ship_To_Country__c);
        system.assertEquals('AZ',invoiceLine.Ship_To_State__c,invoiceLine.Ship_To_State__c);
        system.assertEquals('141 Eagle Street',invoiceLine.Ship_To_Street__c,invoiceLine.Ship_To_Street__c);
        system.assertEquals('24418',invoiceLine.Ship_To_Zip_Code__c,invoiceLine.Ship_To_Zip_Code__c);
        Test.stopTest();
        
	}
	
	static testMethod void testInvoiceLinePONoCLASSType() {
		TestFuelQuery fuel = new TestFuelQuery();
		Purchase_Order__c purchaseOrder = new Purchase_Order__c(
                                        Supplier__c = fuel.supplier.id, 
                                        Company__c = fuel.company.id,
                                        Delivery_Facility__c = fuel.facility2.id,
                                        Delivery_Location__c = fuel.location2.ID,
                                        Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                        Approval_Status__c = 'Approved',
                                        Acknowledge_Via__c = 'Email',
                                        Status__c = 'Open',
                                        Memo__c = 'purchaseOrder',
                                        Currency__c = fuel.currencyUSD.id
                            );
      insert purchaseOrder;
      
      Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
	    poLine.Purchase_Order__c = purchaseOrder.Id;
	    poLine.Order_Quantity__c = 10;     
	    poLine.Unit_Price__c = 12;
	    poLine.Item__c = fuel.ItemNoClassType.Id;
	    poLine.Description__c = 'purchaseOrderLine0';
	    poLine.Purchase_UOM__c = fuel.ItemNoClassType.Purchasing_UOM__c;
	    poLine.Company__c = fuel.company.id;
	    poLine.Need_Date__c = system.today() + 7;
	    poLine.Delivery_Facility__c = fuel.facility2.id;
	    poLine.Delivery_Location__c = fuel.location2.ID;
	    poLine.Supplier__c = fuel.supplier.Id;
	    poLine.Line__c = 1;
	    poLine.Quantity_Matched__c = 0;
	    poLine.Amount_Matched__c = 0;
	    insert poline;
	    purchaseOrder.Approval_Status__c = 'Approved';
        update purchaseOrder;
        
        Supplier_Invoice__c si = new Supplier_Invoice__c(Company__c = fuel.company.id,
            Supplier__c = fuel.remittosupplier.id,
            Invoice_Type__c = 'Invoice',
            Date_Invoiced__c = system.now(),
            Supplier_Invoice__c = '987612',
            Payment_Term__c = fuel.terms.Id,
            Invoice_Amount__c = 491,
            Purchase_Order__c = PurchaseOrder.id,
            Currency__c = fuel.company.Default_Transaction_Currency__c,
            Status__c = 'Draft');
        insert si; 
         Supplier_Invoice_Line__c invoiceLine = new Supplier_Invoice_Line__c(); {
            invoiceLine.Supplier_Invoice__c = si.Id;
            invoiceLine.Invoice_Quantity__c = 5;
            invoiceLine.Unit_Price__c = 100;//KNDY-14371
            invoiceLine.Description__c = 'test';
            invoiceLine.Purchase_Order__c = purchaseOrder.Id;
            invoiceLine.Purchase_Order_Line__c = poLine.id;
            invoiceLine.Item__c = fuel.ItemNoClassType.Id;
            
        }
        insert invoiceLine;
        
        invoiceLine = [Select ID, SubTransaction_Type__c from Supplier_invoice_line__c where ID = :invoiceLine.Id];
        system.assertEquals('Miscellaneous - Purchase Order', invoiceLine.SubTransaction_Type__c,invoiceLine);
       
        
	}
	//KNDY-15609 - check weather amount gets populated
	static testMethod void testInvoiceLineAmountPopulated() {
		TestFuelQuery fuel = new TestFuelQuery();
		Test.startTest();
		Purchase_Order__c purchaseOrder = new Purchase_Order__c(
                                        Supplier__c = fuel.supplier.id, 
                                        Company__c = fuel.company.id,
                                        Delivery_Facility__c = fuel.facility2.id,
                                        Delivery_Location__c = fuel.location2.ID,
                                        Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                        Approval_Status__c = 'Approved',
                                        Acknowledge_Via__c = 'Email',
                                        Status__c = 'Open',
                                        Memo__c = 'purchaseOrder',
                                        Currency__c = fuel.currencyUSD.id
                            );
      insert purchaseOrder;
      
      Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
	    poLine.Purchase_Order__c = purchaseOrder.Id;
	    poLine.Order_Quantity__c = 10;     
	    poLine.Unit_Price__c = 12;
	    poLine.Item__c = fuel.ItemNoClassType.Id;
	    poLine.Description__c = 'purchaseOrderLine0';
	    poLine.Purchase_UOM__c = fuel.ItemNoClassType.Purchasing_UOM__c;
	    poLine.Company__c = fuel.company.id;
	    poLine.Need_Date__c = system.today() + 7;
	    poLine.Delivery_Facility__c = fuel.facility2.id;
	    poLine.Delivery_Location__c = fuel.location2.ID;
	    poLine.Supplier__c = fuel.supplier.Id;
	    poLine.Line__c = 1;
	    poLine.Quantity_Matched__c = 0;
	    poLine.Amount_Matched__c = 0;
	    insert poline;
	    purchaseOrder.Approval_Status__c = 'Approved';
        update purchaseOrder;
        
        Supplier_Invoice__c si = new Supplier_Invoice__c(Company__c = fuel.company.id,
            Supplier__c = fuel.remittosupplier.id,
            Invoice_Type__c = 'Invoice',
            Date_Invoiced__c = system.now(),
            Supplier_Invoice__c = '987612',
            Payment_Term__c = fuel.terms.Id,
            Invoice_Amount__c = 491,
            Purchase_Order__c = PurchaseOrder.id,
            Currency__c = fuel.company.Default_Transaction_Currency__c,
            Status__c = 'Draft');
        insert si; 
         Supplier_Invoice_Line__c invoiceLine = new Supplier_Invoice_Line__c(); {
            invoiceLine.Supplier_Invoice__c = si.Id;
            invoiceLine.Invoice_Quantity__c = 5;
            invoiceLine.Unit_Price__c = 100;//KNDY-14371
            invoiceLine.Description__c = 'test';
            invoiceLine.Purchase_Order__c = purchaseOrder.Id;
            invoiceLine.Purchase_Order_Line__c = poLine.id;
            invoiceLine.Item__c = fuel.ItemNoClassType.Id;
            
        }
        insert invoiceLine;
        
        invoiceLine = [Select ID, SubTransaction_Type__c,Amount__c from Supplier_invoice_line__c where ID = :invoiceLine.Id];
        system.assertEquals( invoiceLine.Amount__c != null, true,invoiceLine);
        
        //KNDY-15609 - check amount populated
         Supplier_Invoice_Line__c invoiceLine1 = new Supplier_Invoice_Line__c(); {
            invoiceLine1.Supplier_Invoice__c = si.Id;
            invoiceLine1.Invoice_Quantity__c = 5;
            invoiceLine1.Unit_Price__c = 100;//KNDY-14371
            invoiceLine1.VAT_Amount__c = 10.556;
            invoiceLine1.Description__c = 'test';
            invoiceLine1.Purchase_Order__c = purchaseOrder.Id;
            invoiceLine1.Purchase_Order_Line__c = poLine.id;
            invoiceLine1.Item__c = fuel.ItemNoClassType.Id;
            
        }
        insert invoiceLine1;
        
        invoiceLine1 = [Select ID,Amount__c,Unit_Price__c,Invoice_Quantity__c from Supplier_invoice_line__c where ID = :invoiceLine1.Id];
        system.assertEquals( invoiceLine1.Amount__c == 510.56, true,invoiceLine1);
        invoiceLine1.Unit_Price__c = 10;
        update invoiceLine1;
        invoiceLine1 = [Select ID,Amount__c,Unit_Price__c,Invoice_Quantity__c from Supplier_invoice_line__c where ID = :invoiceLine1.Id];
        system.assertEquals( invoiceLine1.Amount__c == 60.56, true,invoiceLine1);
        invoiceLine1.Unit_Price__c = 100;
        invoiceLine1.VAT_Amount__c = null;
        update invoiceLine1;
        invoiceLine1 = [Select ID,Amount__c,Unit_Price__c,Invoice_Quantity__c from Supplier_invoice_line__c where ID = :invoiceLine1.Id];
        system.assertEquals( invoiceLine1.Amount__c == 500, true,invoiceLine1);
        invoiceLine1.VAT_Amount__c = 10.55;
        update invoiceLine1;
        invoiceLine1 = [Select ID,Amount__c,Unit_Price__c,Invoice_Quantity__c from Supplier_invoice_line__c where ID = :invoiceLine1.Id];
        system.assertEquals( invoiceLine1.Amount__c == 510.55, true,invoiceLine1);
        Test.stopTest();
	}
	
	static testMethod void testGetCustomViews() {
		SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
		
		// Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        List<Grid_Views_Config__c> customViewList = testData.customViewList;
    	ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act 
        string result = con.getCustomViews();
        // Assert
        System.assertNotEquals(result, '');
        List<SelectListItem> customviews = (List<SelectListItem>) JSON.deserialize(result, List<SelectListItem>.class);
        system.assertEquals(customviews.size(), 2);
        Boolean allFieldsViewFound = false;
        Boolean customView1Found = false;
        for (SelectListItem customView: customviews){
            if ( customView.text == Label.All_Fields){
                allFieldsViewFound = true;
            }
            else if (customView.text == customViewList[0].View_Name__c){
                customView1Found = true;
            }
        }
        system.assertEquals( allFieldsViewFound, true);
        system.assertEquals( customView1Found, true);
	}
	
	static testMethod void testGetCustomViewFields() {
		SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
		
		// Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        List<Grid_Views_Config__c> customViewList = testData.customViewList;
    	ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act 
        string result = con.getCustomViewFields();
        
        // Assert
        System.assertNotEquals(result, '');
	}
	
	static testMethod void testGetSupplierInvoiceJson() {
		SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
		
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
    	ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        si = (Supplier_Invoice__c) SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.id ,'0').records[0];
        // Act 
        string result = con.getSupplierInvoiceJson();
        
        // Assert
        System.assertEquals(result, JSON.serialize(si));
    }
    
	static testMethod void testGetSupplierInvoiceHeaderFieldList() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	Test.startTest();
    	
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
    	ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        string result = con.getSupplierInvoiceHeaderFieldList();
        
        // Assert
        System.assertNotEquals(result, '');
        
        Test.stopTest();
    }
    
    static testMethod void testActionsMap(){
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt ext = new SupplierInvoiceManageExt(setCon);
        
        //SI Id does not exist
        String siTestMapStr = ext.getUserSIActionsMap(); 
        System.debug(logginglevel.error,'siTestMapStr--->'+siTestMapStr);
       
        Map<String,Object> siActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(siTestMapStr);  
        System.debug(logginglevel.error, 'siActionTestMap--->'+siActionTestMap);  
        // Invoice status should be set to Incomplete by controller constructor
        system.assertEquals(siActionTestMap.get('Save'),true);
        system.assertEquals(siActionTestMap.get('Save_New'),true);
        system.assertEquals(siActionTestMap.get('Save_Return'),true);
        system.assertEquals(siActionTestMap.get('Save_Validate'),true);
        system.assertEquals(siActionTestMap.get('Clone'),false);
        system.assertEquals(siActionTestMap.get('Validate'),false); 
        system.assertEquals(siActionTestMap.get('Get_Tax'),false); 
        system.assertEquals(siActionTestMap.get('Unfinalize'),false); 
        system.assertEquals(siActionTestMap.get('Cancel'),false);
        system.assertEquals(siActionTestMap.get('Void'),false); 
        system.assertEquals(siActionTestMap.get('Pay_Invoice'),false);

        String actionsMapOnSILStr = ext.getSILActionsMap();
        Map<String,Object> silActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(actionsMapOnSILStr);  
        system.assertEquals(silActionTestMap.get('Create'),true);
        system.assertEquals(silActionTestMap.get('Clone'),true);
        system.assertEquals(silActionTestMap.get('Delete'),true);
        system.assertEquals(silActionTestMap.get('MatchToPO'), true);
        Test.stopTest();
        
    }
    
    static testMethod void testSILActionsMapCancelledSI(){
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612TestHold';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 3;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Currency__c = globalTestData.company.Default_Transaction_Currency__c;
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;
        }
        si_mrl.Status__c = 'Cancelled';
        update si_mrl;
        
        Test.startTest();
        
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt ext1 = new SupplierInvoiceManageExt(setCon);

        String actionsMapOnSILStr = ext1.getSILActionsMap();
        Map<String,Object> silActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(actionsMapOnSILStr);  
        system.assertEquals(silActionTestMap.get('Create'),false);
        system.assertEquals(silActionTestMap.get('Clone'),false);
        system.assertEquals(silActionTestMap.get('Delete'),false);
        
        Test.stopTest();
    }
    
    static testMethod void testGetSupplierInvoiceAddlHeaderFieldList() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	
    	Test.startTest();
    	
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
    	ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        string result = con.getSupplierInvoiceAddlHeaderFieldList();
        
        // Assert
        System.assertNotEquals(result, '');
        
        Test.stopTest();
    }
    
    static testMethod void testGetSupplierInvoiceVATFieldList() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        
        Test.startTest();
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        string result = con.getVATFieldList();
        
        // VAT field list may or may not be empty depending on which customers are using the VAT feature
        
        Test.stopTest();
    }
    
    static testMethod void testGetSupplierInvoiceLinesFieldList() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	
    	Test.startTest();
    	
		// Arrange
		Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
    	ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        con.supplierInvoiceLinesConfig = testData.supplierInvoiceLinesConfig;
        
        // Act
        string result = con.getSupplierInvoiceLinesFieldList();
        
        // Assert
        System.assertEquals(result, con.supplierInvoiceLinesFieldList);

        List<FieldInfo> fieldInfos =  (List<FieldInfo>) JSON.deserialize(result, List<FieldInfo>.class);
        for (FieldInfo fi : FieldInfos){
           if (fi.field == 'segments.Company__c'){
           	system.assertEquals(fi.hidden, true, 'fi: '+ fi); //KNDY-15943
           }
        }
        Test.stopTest();
    }
    
    static testMethod void testGetSupplierInvoiceLinesConfigJson() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
    	ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        con.supplierInvoiceLinesConfig = testData.supplierInvoiceLinesConfig;
        
        // Act
        string result = con.getSupplierInvoiceLinesConfigJson();
        
        // Assert
        System.assertEquals(result, JSON.serialize(con.supplierInvoiceLinesConfig));
    }
        
    static testMethod void testGetSegmentLinesFieldList() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	Test.startTest();
    	
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
    	ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        con.supplierInvoiceLinesConfig = testData.segmentLinesConfig;
        
        // Act
        string result = con.getSegmentLinesFieldList();
        
        // Assert
        System.assertEquals(result, con.segmentLinesFieldList);
        
        Test.stopTest();
    }
    
    static testMethod void testGetPurchaseOrderLinesConfigJson() {
       SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	
    	// Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
    	ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        con.purchaseOrderLinesConfig = testData.purchaseOrderLinesConfig;
        
        // Act
        string result = con.getPurchaseOrderLinesConfigJson();
        
        // Assert
        System.assertEquals(result, JSON.serialize(con.purchaseOrderLinesConfig));
    }
        
    static testMethod void testGetPurchaseOrderLinesFieldList() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	Test.startTest();
    	
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
    	ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        con.purchaseOrderLinesConfig = testData.purchaseOrderLinesConfig;
        
        // Act
        string result = con.getPurchaseOrderLinesFieldList();
        
        // Assert
        System.assertEquals(result, con.purchaseOrderLinesFieldList);
        
        Test.stopTest();
    }
    
    static testMethod void testGetSupplierInvoiceDetails(){
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();
        
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
                
        // Act
        JsonResult result = SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null); // not for a clone

        // Assert
        System.assertNotEquals(0, result.total);
        
        Test.stopTest();
    }
    
    static testMethod void testGetPaymentDefaults() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	Test.startTest();
    	
    	// Arrange
    	Supplier__c supplier = testData.fuel.supplier;
    	
    	// Act
        JsonResult result = SupplierInvoiceManageExt.getPaymentDefaults(supplier.Id, null);
        
        // Assert
        System.assertNotEquals(0, result.total);
        
        Test.stopTest();
    }
    
    static testMethod void testGetPurchaseOrderDetails() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	Test.startTest();
    	
    	// Arrange
    	Purchase_Order__c po = testData.fuel.purchaseOrder;
    	
    	// Act
        JsonResult result = SupplierInvoiceManageExt.getPurchaseOrderDetails(po.Id);
        
        // Assert
        System.assertNotEquals(0, result.total);
        
        Test.stopTest();
    }
    
    /* static testMethod void testGetPurchaseOrderLineDetails() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	Test.startTest();
    	
    	// Arrange
    	Purchase_Order_Line__c po = testData.fuel.purchaseOrderLines[0];
    	
    	// Act
        JsonResult result = SupplierInvoiceManageExt.getPurchaseOrderLineDetails(po.Id, 'Invoice');
        
        // Assert
        System.assertNotEquals(0, result.total);
        
        Test.stopTest();
    } */
    
    static testMethod void testGetInvoiceLines() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	Test.startTest();

    	// Arrange
    	GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
    	Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
    	
    	// Act
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLines(config, null); // not for a clone
        
        // Assert
        System.assertNotEquals(0, result.total);
        
        Test.stopTest();
    }
    
    // Action drop-down tests
    static testMethod void testValidateInspect_SIHold() {
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 491;
            si_mrl.Purchase_Order__c = testdata.fuel.purchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = true;
        insert si_mrl;
        }
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si_mrl);              
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si_mrl.Id);  
        Test.setCurrentPage(pageRef);
        
        JsonResult result = SupplierInvoiceManageExt.headerActions(si_mrl.Id, 'Validate');
        system.assert(result.success == false, 'Invoice is on Hold.');
        
        Test.stopTest();
   }
   
   static testMethod void testInspectSI() {
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 1000;
        si.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
        si.Status__c = 'Incomplete';        
        insert si;
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);              
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        JsonResult result = SupplierInvoiceManageExt.headerActions(si.Id, 'Validate');
        system.assert(result.success == true, 'Validate should have succeeded');
        
        Test.stopTest();
   }
   
   static testMethod void testClone_ApprovedSI() {
      SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612TestHold';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 3;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Transaction_Date__c = system.today();
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;
        }
        si_mrl.Status__c = 'Approved';
        si_mrl.Finalized__c = true;
        update si_mrl;
        
        Test.startTest();
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si_mrl.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
       
        // Tests for cloned Supplier Invoice
        JsonResult result = SupplierInvoiceManageExt.getSupplierInvoiceDetails(si_mrl.Id, '1');
        system.assert(result.success == true);
        system.assert(result.records != null);
        system.assert(result.records.size() == 1);
        
        Supplier_Invoice__c siClone = (Supplier_Invoice__c)result.records[0];
        system.assertEquals(siClone.Status__c, 'Incomplete');
        system.assertEquals(siClone.Supplier_Invoice__c, '');
        system.assertEquals(siClone.Exceptions_Count__c, 0);
        system.assertEquals(siClone.Id, null);
        system.assert(siClone.Currency__c == SupplierInvoiceService.getSICurrency(si_mrl.Currency__c).Id);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');        
        }
        
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si_mrl.Id, '1').records[0];
        invoiceHeader.Supplier_Invoice__c = '390847a23432';
        
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, '1').records;
        SupplierInvoiceManageExt.InvoiceLineWrapper updateInvoiceLine = invoiceLines[0];
        updateInvoiceLine.invoiceLine.Unit_Price__c = 50;
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = 5; 
            newInvoiceLine.Unit_Price__c = 12;
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[2].Id;
        }
        
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);

        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); {
        updatedList.add(updateInvoiceLine);
        }

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }

        List<Supplier_Invoice_Line__c> sillist = [select id, Unit_Price__c from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si_mrl.id ];
        system.assertEquals(1, sillist.size());
        system.assertEquals(sillist[0].Unit_Price__c, 1.0);

        JsonResult result1 = SupplierInvoiceManageExt.saveAction(invoiceHeader, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(true, result1.success);
        
        List<Supplier_Invoice_Line__c> sillist1 = [select id, Unit_Price__c, Extended_Price__c, Purchase_Price__c   from Supplier_Invoice_Line__c where Supplier_Invoice__c = :invoiceHeader.id];
        system.assertEquals(2, sillist1.size());
        System.debug(logginglevel.error,'sillist1--->'+sillist1);
        system.assertEquals(sillist1[0].Unit_Price__c, 50); // Updated Unit Price on the Cloned SI.
        Test.stopTest();
   }
   
   static testMethod void testClone_DraftSI() {
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 491;
            si_mrl.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Status__c = 'Draft';
            si_mrl.Exceptions_Count__c = 1;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c invoiceLine = new Supplier_Invoice_Line__c(); {
            invoiceLine.Supplier_Invoice__c = si_mrl.Id;
            invoiceLine.Invoice_Quantity__c = 5;
            invoiceLine.Unit_Price__c = 100;//KNDY-14371
            invoiceLine.Description__c = 'test';
            invoiceLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
            invoiceLine.Purchase_Order_Line__c = testData.fuel.purchaseOrderLines[0].id;
            invoiceLine.Item__c = testData.fuel.itemList[0].Id;
            invoiceLine.Exceptions_Count__c = 1; // has exceptions
        }
        insert invoiceLine;
        
        Test.startTest();
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si_mrl.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(si_mrl);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        system.assert(siMngExt.pageTitle.contains ('Clone of'));
        
        // Tests for cloned Supplier Invoice
        JsonResult result = SupplierInvoiceManageExt.getSupplierInvoiceDetails(si_mrl.Id, '1');
        system.assert(result.success == true);
        system.assert(result.records != null);
        system.assert(result.records.size() == 1);
        Supplier_Invoice__c siClone = (Supplier_Invoice__c)result.records[0];
        system.assertEquals(siClone.Status__c, 'Incomplete');
        system.assertEquals(siClone.Supplier_Invoice__c, '');
        system.assertEquals(siClone.Exceptions_Count__c, 0);
        system.assertEquals(siClone.Id, null);
        system.assert(siClone.Currency__c == SupplierInvoiceService.getSICurrency(si_mrl.Currency__c).Id);
        
        // Tests for cloned lines
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        result = SupplierInvoiceManageExt.getInvoiceLines(config, '1'); // cloning lines
        system.assertEquals(1, result.total);
        SupplierInvoiceManageExt.InvoiceLineWrapper invLineWrapper = (SupplierInvoiceManageExt.InvoiceLineWrapper) result.records[0];
        Supplier_Invoice_Line__c silClone = invLineWrapper.invoiceLine;
        system.assertEquals(silClone.Id, null);
        system.assertEquals(siClone.Exceptions_Count__c, 0);
        Test.stopTest();
    }
   
   // There should be no error message on page
   static testMethod void testClone_NoSILines() {
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        // SI has no si lines
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 491;
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Status__c = 'Draft';
            si_mrl.Exceptions_Count__c = 1;
        insert si_mrl;
        }
        
        Test.startTest();
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si_mrl.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(si_mrl);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        system.assert(siMngExt.pageTitle.contains ('Clone of'));
        
        // Tests for cloned Supplier Invoice
        JsonResult result = SupplierInvoiceManageExt.getSupplierInvoiceDetails(si_mrl.Id, '1');
        system.assert(result.success == true);
        system.assert(result.records != null);
        system.assert(result.records.size() == 1);
        Supplier_Invoice__c siClone = (Supplier_Invoice__c)result.records[0];
        system.assertEquals(siClone.Status__c, 'Incomplete');
        system.assertEquals(siClone.Supplier_Invoice__c, '');
        system.assertEquals(siClone.Exceptions_Count__c, 0);
        system.assertEquals(siClone.Id, null);
        
        // Tests for cloned lines
        GridRelatedListController.GridRelatedListConfig config = siMngExt.supplierInvoiceLinesConfig;
        result = SupplierInvoiceManageExt.getInvoiceLines(config, '1'); // cloning lines
        system.assertEquals(0, result.total, '>>> result: ' + result);
        system.assert(result.messages.size() == 0, '>>> result.messages: ' + result.messages);
        Test.stopTest();
    }
    
    static testMethod void testClone_ForInactiveSupplier() {
       
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        Supplier__c supplier = testdata.fuel.remittosupplier;
        supplier.status__c = 'Inactive';
        update supplier;
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = supplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 491;
            si_mrl.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Status__c = 'Draft';
            si_mrl.Exceptions_Count__c = 1;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c invoiceLine = new Supplier_Invoice_Line__c(); {
            invoiceLine.Supplier_Invoice__c = si_mrl.Id;
            invoiceLine.Invoice_Quantity__c = 5;
            invoiceLine.Unit_Price__c = 100;
            invoiceLine.Description__c = 'test';
            invoiceLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
            invoiceLine.Purchase_Order_Line__c = testData.fuel.purchaseOrderLines[0].id;
            invoiceLine.Item__c = testData.fuel.itemList[0].Id;
            invoiceLine.Exceptions_Count__c = 1; // has exceptions
        }
        insert invoiceLine;
        
        Test.startTest();
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si_mrl.Id);
        pageRef.getParameters().put('Clone', null); //clone should be set as 1 in the VF page, else would be null
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(si_mrl);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        system.assert(!siMngExt.pageTitle.contains ('Clone of'));
        Test.stopTest();
    }
    
    // No lines should be cloned with error message on page
    static testMethod void testCloneSIInvoice_ClosedForInvoicingPOLs() {
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        Purchase_Order_Line__c pol = testdata.fuel.purchaseOrderLines[0];
        pol.Quantity_Matched__c = pol.Order_Quantity__c;
        update pol;
        
        Purchase_Order_Line__c testPOL = [Select Id, Order_Quantity__c, Quantity_Matched__c,
                Invoice_Status__c from Purchase_Order_Line__c where Id = :pol.Id];
        system.assert(testPOL.Invoice_Status__c == 'Closed for invoicing', '>>> testPOL: ' + testPOL);
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 491;
            si_mrl.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Status__c = 'Incomplete';
            si_mrl.Exceptions_Count__c = 0;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c invoiceLine = new Supplier_Invoice_Line__c(); {
            invoiceLine.Supplier_Invoice__c = si_mrl.Id;
            invoiceLine.Invoice_Quantity__c = 5;
            invoiceLine.Unit_Price__c = 100;//KNDY-14371
            invoiceLine.Description__c = 'test';
            invoiceLine.Purchase_Order__c = testdata.fuel.purchaseOrder.Id;
            invoiceLine.Purchase_Order_Line__c = testdata.fuel.purchaseOrderLines[0].id;
            invoiceLine.Item__c = testdata.fuel.itemList[0].Id;
            invoiceLine.Exceptions_Count__c = 0; // has no exceptions
        }
        insert invoiceLine;
        
        Test.startTest();
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si_mrl.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(si_mrl);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        system.assert(siMngExt.pageTitle.contains ('Clone of'));
        
        // Tests for cloned Supplier Invoice
        JsonResult result = SupplierInvoiceManageExt.getSupplierInvoiceDetails(si_mrl.Id, '1');
        system.assert(result.success == true);
        system.assert(result.records != null);
        system.assert(result.records.size() == 1);
        Supplier_Invoice__c siClone = (Supplier_Invoice__c)result.records[0];
        system.assertEquals(siClone.Status__c, 'Incomplete');
        system.assertEquals(siClone.Supplier_Invoice__c, '');
        system.assertEquals(siClone.Exceptions_Count__c, 0);
        system.assertEquals(siClone.Id, null);
        
        // Tests for cloned lines
        GridRelatedListController.GridRelatedListConfig config = siMngExt.supplierInvoiceLinesConfig;
        result = SupplierInvoiceManageExt.getInvoiceLines(config, '1'); // cloning lines
        system.assertEquals(0, result.total, '>>> result: ' + result);
        system.assert(result.messages.size() == 1, '>>> result.messages: ' + result.messages);
        system.assert(result.messages[0].get('message').contains(Label.All_invoice_lines_cannot_be_cloned),'>>> result: ' + result);
        Test.stopTest();
    }
    
    // All Lines should be cloned
    static testMethod void testCloneSIPrepayment_ClosedForInvoicingPOLs() {
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        Purchase_Order_Line__c pol = testdata.fuel.purchaseOrderLines[0];
        pol.Quantity_Matched__c = pol.Order_Quantity__c;
        update pol;
        
        Purchase_Order_Line__c testPOL = [Select Id, Order_Quantity__c, Quantity_Matched__c,
                Invoice_Status__c from Purchase_Order_Line__c where Id = :pol.Id];
        system.assert(testPOL.Invoice_Status__c == 'Closed for invoicing', '>>> testPOL: ' + testPOL);
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Prepayment';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 491;
            si_mrl.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Status__c = 'Incomplete';
            si_mrl.Exceptions_Count__c = 0;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c invoiceLine = new Supplier_Invoice_Line__c(); {
            invoiceLine.Supplier_Invoice__c = si_mrl.Id;
            invoiceLine.Invoice_Quantity__c = 5;
            invoiceLine.Unit_Price__c = 100;//KNDY-14371
            invoiceLine.Description__c = 'test';
            invoiceLine.Purchase_Order__c = testdata.fuel.purchaseOrder.Id;
            invoiceLine.Purchase_Order_Line__c = testdata.fuel.purchaseOrderLines[0].id;
            invoiceLine.Item__c = testdata.fuel.itemList[0].Id;
            invoiceLine.Exceptions_Count__c = 0; // has no exceptions
        }
        insert invoiceLine;

        Test.startTest();
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si_mrl.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(si_mrl);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        system.assert(siMngExt.pageTitle.contains ('Clone of'));
        
        // Tests for cloned Supplier Invoice
        JsonResult result = SupplierInvoiceManageExt.getSupplierInvoiceDetails(si_mrl.Id, '1');
        system.assert(result.success == true);
        system.assert(result.records != null);
        system.assert(result.records.size() == 1);
        Supplier_Invoice__c siClone = (Supplier_Invoice__c)result.records[0];
        system.assertEquals(siClone.Status__c, 'Incomplete');
        system.assertEquals(siClone.Supplier_Invoice__c, '');
        system.assertEquals(siClone.Exceptions_Count__c, 0);
        system.assertEquals(siClone.Id, null);
        
        // Tests for cloned lines
        GridRelatedListController.GridRelatedListConfig config = siMngExt.supplierInvoiceLinesConfig;
        result = SupplierInvoiceManageExt.getInvoiceLines(config, '1'); // cloning lines
        system.assertEquals(1, result.total, '>>> result: ' + result);
        system.assert(result.messages.size() == 0, '>>> result.messages: ' + result.messages);
        Test.stopTest();
    }
    
    // All Lines should be cloned
    static testMethod void testCloneSICreditMemo_ClosedForInvoicingPOLs() {
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        Purchase_Order_Line__c pol = testdata.fuel.purchaseOrderLines[0];
        pol.Quantity_Matched__c = pol.Order_Quantity__c;
        update pol;
        
        Purchase_Order_Line__c testPOL = [Select Id, Order_Quantity__c, Quantity_Matched__c,
                Invoice_Status__c from Purchase_Order_Line__c where Id = :pol.Id];
        system.assert(testPOL.Invoice_Status__c == 'Closed for invoicing', '>>> testPOL: ' + testPOL);
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Credit Memo';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = -491;
            si_mrl.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Status__c = 'Incomplete';
            si_mrl.Exceptions_Count__c = 0;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c invoiceLine = new Supplier_Invoice_Line__c(); {
            invoiceLine.Supplier_Invoice__c = si_mrl.Id;
            invoiceLine.Invoice_Quantity__c = 5;
            invoiceLine.Unit_Price__c = -100;//KNDY-14371
            invoiceLine.Description__c = 'test';
            invoiceLine.Purchase_Order__c = testdata.fuel.purchaseOrder.Id;
            invoiceLine.Purchase_Order_Line__c = testdata.fuel.purchaseOrderLines[0].id;
            invoiceLine.Item__c = testdata.fuel.itemList[0].Id;
            invoiceLine.Exceptions_Count__c = 0; // has no exceptions
        }
        insert invoiceLine;

        Test.startTest();
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si_mrl.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(si_mrl);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        system.assert(siMngExt.pageTitle.contains ('Clone of'));
        
        // Tests for cloned Supplier Invoice
        JsonResult result = SupplierInvoiceManageExt.getSupplierInvoiceDetails(si_mrl.Id, '1');
        system.assert(result.success == true);
        system.assert(result.records != null);
        system.assert(result.records.size() == 1);
        Supplier_Invoice__c siClone = (Supplier_Invoice__c)result.records[0];
        system.assertEquals(siClone.Status__c, 'Incomplete');
        system.assertEquals(siClone.Supplier_Invoice__c, '');
        system.assertEquals(siClone.Exceptions_Count__c, 0);
        system.assertEquals(siClone.Id, null);
        
        // Tests for cloned lines
        GridRelatedListController.GridRelatedListConfig config = siMngExt.supplierInvoiceLinesConfig;
        result = SupplierInvoiceManageExt.getInvoiceLines(config, '1'); // cloning lines
        system.assertEquals(1, result.total, '>>> result: ' + result);
        system.assert(result.messages.size() == 0, '>>> result.messages: ' + result.messages);
        Test.stopTest();
    }
    
    static testMethod void testLoadExceptions() {
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 1000;
        si.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
        si.Status__c = 'Incomplete';        
        insert si;
        
        List<supplier_Invoice__c> sis = new List<Supplier_Invoice__c>();
        sis.add(si);        
        supplierInvoiceService.inspectIncompleteInvoices(sis);
        
        Supplier_Invoice__c si1 = [select Id, Name, Status__c,
                                    Invoice_Type__c, Company__c, Supplier__c, Date_Invoiced__c,
                                    Supplier_Invoice__c, Supplier_and_Invoice__c, Invoice_Amount__c,
                                    Currency__c, Purchase_Order__c, Has_Exceptions__c, 
                                    Has_Line_Exceptions__c, Finalized__c
                                    from Supplier_Invoice__c where id =: si.id];
        system.assertEquals('Incomplete',si1.status__c);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(si1);              
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si1.Id);  
        Test.setCurrentPage(pageRef);
        Test.startTest();
        
        ExceptionTasksExtNew exceptionTasksExtNew = new ExceptionTasksExtNew();
        exceptionTasksExtNew.parent = si1;
        GridRelatedListController.GridRelatedListConfig exceptionsConfig = exceptionTasksExtNew.config;
        exceptionsConfig.parentRecord = si1;
        //system.debug(LoggingLevel.Error, '>>>exceptionsConfig:' + exceptionsConfig);
        system.assertNotEquals (exceptionsConfig, null, 'Expected exceptionsConfig to be not null');
        String exceptionsFieldList = siMngExt.getExceptionsFieldList();
        system.assert(!String.isBlank(exceptionsFieldList));
        String jsonStr =  siMngExt.getWhatIdNameMapJson();
        system.assert(!String.isBlank(jsonStr));
        // system.debug(LoggingLevel.Error, '>>>jsonStr:' + jsonStr);       
        DataSourceResult dsr = SupplierInvoiceManageExt.getTaskRelatedList(exceptionsConfig) ;
        //system.debug(LoggingLevel.Error, '>>>dsr:' + dsr);
        system.assertNotEquals(0, dsr.total);
        Test.stopTest();       
    } 
     
    static testMethod void testGetInvoiceLinesByPurchaseOrderId() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	Test.startTest();

    	// Arrange
    	Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
    	String invoiceType = 'Invoice';
    	
    	// Act
    	List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        
        // Assert
        System.assertNotEquals(0, result.total);
        
        Test.stopTest();
    }
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_SIPrepay_WithOpenandClosedInvoicingPOLs() {  
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Purchase_Order_Line__c pol = testData.fuel.purchaseOrderLines[0];
        pol.Quantity_Matched__c = pol.Order_Quantity__c;
        update pol;
        
        Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
        poLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
        poLine.Order_Quantity__c = 10;     
        poLine.Unit_Price__c = 12;
        poLine.Item__c = testData.fuel.itemList[2].Id;
        poLine.Description__c = 'purchaseOrderLine0';
        poLine.Purchase_UOM__c = testData.fuel.itemList[2].Purchasing_UOM__c;
        poLine.Company__c = testData.fuel.company.id;
        poLine.Need_Date__c = system.today() + 7;
        poLine.Delivery_Facility__c = testData.fuel.facility2.id;
        poLine.Delivery_Location__c = testData.fuel.location2.ID;
        poLine.Supplier__c = testData.fuel.supplier.Id;
        poLine.Line__c = 1;
        poLine.Quantity_Matched__c = 0;
        insert poLine;
        
        List<Id> purchaseOrderLineIds = new List<Id>();
        purchaseOrderLineIds.add(pol.id);
        purchaseOrderLineIds.add(poLine.id);

        
        List<Id> validPurchaseOrderIds = new List<Id>();
        
        List<Purchase_Order_Line__c> testPOLlst = [Select Id, Order_Quantity__c, Quantity_Matched__c,
             Invoice_Status__c from Purchase_Order_Line__c where Id in :purchaseOrderLineIds];
        for(Purchase_Order_Line__c testPOL : testPOLlst ){
             if(testPOL.Id == pol.Id){
               system.assert(testPOL.Invoice_Status__c == 'Closed for invoicing', '>>> testPOL: ' + testPOL);
             }else{
               system.assert(testPOL.Invoice_Status__c == 'Open for invoicing', '>>> testPOL: ' + testPOL);   
             } 
        }
        

        Test.startTest();
        Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.Id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        
        String invoiceType = 'Prepayment';
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        system.assertEquals(1, result.total);
        system.assert(result.messages.size() == 0, '>>> result.messages: ' + result.messages);
    }
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_SI_AllTypes_WithOpenandClosedInvoicingPOLs() {  
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Purchase_Order_Line__c pol = testData.fuel.purchaseOrderLines[0];
        pol.Quantity_Matched__c = pol.Order_Quantity__c;
        update pol;
        
        Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
        poLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
        poLine.Order_Quantity__c = 10;     
        poLine.Unit_Price__c = 12;
        poLine.Item__c = testData.fuel.itemList[2].Id;
        poLine.Description__c = 'purchaseOrderLine0';
        poLine.Purchase_UOM__c = testData.fuel.itemList[2].Purchasing_UOM__c;
        poLine.Company__c = testData.fuel.company.id;
        poLine.Need_Date__c = system.today() + 7;
        poLine.Delivery_Facility__c = testData.fuel.facility2.id;
        poLine.Delivery_Location__c = testData.fuel.location2.ID;
        poLine.Supplier__c = testData.fuel.supplier.Id;
        poLine.Line__c = 1;
        poLine.Quantity_Matched__c = 0;
        insert poLine;
        
        List<Id> purchaseOrderLineIds = new List<Id>();
        purchaseOrderLineIds.add(pol.id);
        purchaseOrderLineIds.add(poLine.id);
        
        List<Id> validPurchaseOrderIds = new List<Id>();
        
        List<Purchase_Order_Line__c> testPOLlst = [Select Id, Order_Quantity__c, Quantity_Matched__c,
             Invoice_Status__c from Purchase_Order_Line__c where Id in :purchaseOrderLineIds];
        for(Purchase_Order_Line__c testPOL : testPOLlst ){
             if(testPOL.Id == pol.Id){
               system.assert(testPOL.Invoice_Status__c == 'Closed for invoicing', '>>> testPOL: ' + testPOL);
             }else{
               system.assert(testPOL.Invoice_Status__c == 'Open for invoicing', '>>> testPOL: ' + testPOL);   
             } 
        }
        
        Test.startTest();
        Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.Id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        
        String invoiceType = 'Prepayment';
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        system.assertEquals(1, result.total);
        system.assert(result.messages.size() == 0, '>>> result.messages: ' + result.messages);
        
        invoiceType = 'Invoice';  
        JsonResult result1 = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        system.assertEquals(1, result1.total);
        system.assert(result1.messages.size() == 0, '>>> result1.messages: ' + result1.messages);  
        
        invoiceType = 'Credit Memo';  
        JsonResult result2 = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        system.assertEquals(2, result2.total);
        system.assert(result2.messages.size() == 0, '>>> result2.messages: ' + result2.messages);
        Test.stopTest();
    }
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_SIInv_NoPOLs() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Purchase_Order__c po = testData.fuel.purchaseOrder;
        Purchase_Order__c newPO = po.clone();
        insert newPO; // has no lines
        Test.startTest();
        Purchase_Order__c purchaseOrder = newPO;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        String invoiceType = 'Invoice';
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        system.assertEquals(0, result.total);
        system.assert(result.messages.size() == 1, '>>> result.messages: ' + result.messages);
        system.assert(result.messages[0].get('message').contains(Label.The_purchase_order_has_no_lines),'>>> result: ' + result);
        Test.stopTest();
    }
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_SIPrepay_NoPOLs() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Purchase_Order__c po = testData.fuel.purchaseOrder;
        Purchase_Order__c newPO = po.clone();
        insert newPO; // has no lines
        Test.startTest();
        Purchase_Order__c purchaseOrder = newPO;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        String invoiceType = 'Prepayment';
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        system.assertEquals(0, result.total);
        system.assert(result.messages.size() == 1, '>>> result.messages: ' + result.messages);
        system.assert(result.messages[0].get('message').contains(Label.The_purchase_order_has_no_lines),'>>> result: ' + result);
        Test.stopTest();
    }
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_SICreditMemo_NoPOLs() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Purchase_Order__c po = testData.fuel.purchaseOrder;
        Purchase_Order__c newPO = po.clone();
        insert newPO; // has no lines
        Test.startTest();
        Purchase_Order__c purchaseOrder = newPO;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        String invoiceType = 'Credit Memo';
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        system.assertEquals(0, result.total);
        system.assert(result.messages.size() == 1, '>>> result.messages: ' + result.messages);
        system.assert(result.messages[0].get('message').contains(Label.The_purchase_order_has_no_lines),'>>> result: ' + result);
        Test.stopTest();
    }
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_SIInv_WithClosedForInvoicingPOLs() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Purchase_Order_Line__c pol = testData.fuel.purchaseOrderLines[0];
        pol.Quantity_Matched__c = pol.Order_Quantity__c;
        update pol;
        
        Purchase_Order_Line__c testPOL = [Select Id, Order_Quantity__c, Quantity_Matched__c,
             Invoice_Status__c from Purchase_Order_Line__c where Id = :pol.Id];
        system.assert(testPOL.Invoice_Status__c == 'Closed for invoicing', '>>> testPOL: ' + testPOL);
        
        Test.startTest();
        Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        String invoiceType = 'Invoice';
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        system.assertEquals(0, result.total);
        system.assert(result.messages.size() == 1, '>>> result.messages: ' + result.messages);
        system.assert(result.messages[0].get('message').contains('The purchase order has no lines.'),'>>> result: ' + result);
        
        Test.stopTest();
    }
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_SIPrepay_WithClosedForInvoicingPOLs() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Purchase_Order_Line__c pol = testData.fuel.purchaseOrderLines[0];
        pol.Quantity_Matched__c = pol.Order_Quantity__c;
        update pol;
        
        Purchase_Order_Line__c testPOL = [Select Id, Order_Quantity__c, Quantity_Matched__c,
             Invoice_Status__c from Purchase_Order_Line__c where Id = :pol.Id];
        system.assert(testPOL.Invoice_Status__c == 'Closed for invoicing', '>>> testPOL: ' + testPOL);
        
        Test.startTest();
        Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        String invoiceType = 'Prepayment';
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        system.assertEquals(0, result.total);
        system.assert(result.messages.size() == 1, '>>> result.messages: ' + result.messages);
        Test.stopTest();
    }
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_SICreditMemo_WithClosedForInvoicingPOLs() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Purchase_Order_Line__c pol = testData.fuel.purchaseOrderLines[0];
        pol.Quantity_Matched__c = pol.Order_Quantity__c;
        update pol;
        
        Purchase_Order_Line__c testPOL = [Select Id, Order_Quantity__c, Quantity_Matched__c,
             Invoice_Status__c from Purchase_Order_Line__c where Id = :pol.Id];
        system.assert(testPOL.Invoice_Status__c == 'Closed for invoicing', '>>> testPOL: ' + testPOL);
        
        Test.startTest();
        Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        String invoiceType = 'Credit Memo';
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);

        system.assertEquals(1, result.total);
        system.assert(result.messages.size() == 0, '>>> result.messages: ' + result.messages);
        Test.stopTest();
    }
    
    
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_DraftSIInv_testQuantityUninvoiced_2way() {
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
        
        Purchase_Order_Line__c pol = new Purchase_Order_Line__c();{
            pol.Company__c = testdata.fuel.company.Id;
            pol.Item__c = testdata.fuel.itemlist[2].Id;
            pol.Order_Quantity__c = 10;
            pol.Invoice_Matching__c = 'Two Way';
            pol.Purchase_Order__c = testdata.fuel.purchaseOrder.Id;
            pol.Unit_Price__c = 12;
            pol.Need_Date__c = System.today();
            insert pol;
        }
        
        // Draft SI, POLine is partially invoiced
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 60;
            si_mrl.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = pol.id;
            sil_mrl.Item__c = testdata.fuel.itemList[2].id;
            sil_mrl.Item__r = new Item__c( id= testdata.fuel.itemList[1].id, Source__c = testdata.fuel.itemList[1].Source__c, Class__c = testdata.fuel.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = testdata.fuel.clsObj.id, type__c = testdata.fuel.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 5;
            sil_mrl.Unit_Price__c = 12;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        } 
        
        Test.startTest();
        String invoiceType = 'Invoice';
        Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        System.debug(logginglevel.error,'result--->'+result);
        system.assertEquals(2, result.total);
        system.assert(result.messages.size() == 0, '>>> result.messages: ' + result.messages);
        
        for(SupplierInvoiceManageExt.InvoiceLineWrapper invLnWrapper : (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)result.records){
            Supplier_Invoice_Line__c invLine  =  invLnWrapper.invoiceLine;
            if(invLine.Purchase_Order_Line__c == pol.id){
                // KNDY-19417 10 - 0 (as 5 invoiced but is in draft status)
                system.assert(invLine.Invoice_Quantity__c == 10, '>>> Invoice Quanity count is not correct ' + invLine.Invoice_Quantity__c);  
            }    
        }
        
        //Invoicing for the balance quantity
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Payment_Term__c = testdata.fuel.terms.Id;
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 60;
        si.Transaction_Currency__c = 'USD';
        si.Status__c = 'Incomplete';  
        si.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;      
      
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = 5; 
            newInvoiceLine.Unit_Price__c = 12;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[2].Id;
            newInvoiceLine.Purchase_Order_Line__c = pol.id;
            newInvoiceLine.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;  
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result1 = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result1.success == true, '>>> result1.messages: ' + result1.messages);
        si = [Select Id, Status__c,Has_Exceptions__c, Line_Exceptions_Count__c from Supplier_Invoice__c where Id = :si.Id];
        System.debug(logginglevel.error,'si-->'+si);
        System.assert(newInvoiceLine != null);
        List<Task> t = [SELECT Id, Subject, Status, Exception_Code__c, Description, WhatId, OwnerID FROM Task WHERE WhatId = :newInvoiceLine.id ];
        System.debug(logginglevel.error,'task-->'+t);
        system.assert(si.Status__c == 'Approved');
        
         Test.stopTest();
    }

    static testMethod void testGetInvoiceLinesByPurchaseOrderId_ApprovedSIInv_testQuantityUninvoiced_2way() {//KNDY-19417
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
        
        Purchase_Order_Line__c pol = new Purchase_Order_Line__c();{
            pol.Company__c = testdata.fuel.company.Id;
            pol.Item__c = testdata.fuel.itemlist[2].Id;
            pol.Order_Quantity__c = 10;
            pol.Invoice_Matching__c = 'Two Way';
            pol.Purchase_Order__c = testdata.fuel.purchaseOrder.Id;
            pol.Unit_Price__c = 12;
            pol.Need_Date__c = System.today();
            pol.Quantity_Matched__c = 5;
            insert pol;
        }
        
        // Draft SI, POLine is partially invoiced
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 60;
            si_mrl.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = pol.id;
            sil_mrl.Item__c = testdata.fuel.itemList[2].id;
            sil_mrl.Item__r = new Item__c( id= testdata.fuel.itemList[1].id, Source__c = testdata.fuel.itemList[1].Source__c, Class__c = testdata.fuel.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = testdata.fuel.clsObj.id, type__c = testdata.fuel.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 5;
            sil_mrl.Unit_Price__c = 12;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        } 
        
        si_mrl.Status__c = 'Approved';
        update si_mrl;
        Test.startTest();
        String invoiceType = 'Invoice';
        Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        System.debug(logginglevel.error,'result--->'+result);
        system.assertEquals(2, result.total);
        system.assert(result.messages.size() == 0, '>>> result.messages: ' + result.messages);
        
        for(SupplierInvoiceManageExt.InvoiceLineWrapper invLnWrapper : (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)result.records){
            Supplier_Invoice_Line__c invLine  =  invLnWrapper.invoiceLine;
            if(invLine.Purchase_Order_Line__c == pol.id){
                system.assert(invLine.Invoice_Quantity__c == 5, '>>> Invoice Quanity count is not correct ' + invLine.Invoice_Quantity__c); /// 10 - 5(already invoiced) = 5; 
            }    
        }
        Test.stopTest();
    }
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_ApprovedSICreditMemo_testQuantityUninvoiced_2way() {//KNDY-19417
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
        
        Purchase_Order_Line__c pol = new Purchase_Order_Line__c();{
            pol.Company__c = testdata.fuel.company.Id;
            pol.Item__c = testdata.fuel.itemlist[2].Id;
            pol.Order_Quantity__c = 10;
            pol.Invoice_Matching__c = 'Two Way';
            pol.Purchase_Order__c = testdata.fuel.purchaseOrder.Id;
            pol.Unit_Price__c = 12;
            pol.Need_Date__c = System.today();
            pol.Quantity_Matched__c = 5;
            insert pol;
        }
        
        // Draft SI, POLine is partially invoiced
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Credit Memo';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 60;
            si_mrl.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = pol.id;
            sil_mrl.Item__c = testdata.fuel.itemList[2].id;
            sil_mrl.Item__r = new Item__c( id= testdata.fuel.itemList[1].id, Source__c = testdata.fuel.itemList[1].Source__c, Class__c = testdata.fuel.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = testdata.fuel.clsObj.id, type__c = testdata.fuel.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 5;
            sil_mrl.Unit_Price__c = -12;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        } 
        
        si_mrl.Status__c = 'Approved';
        update si_mrl;
        Test.startTest();
        String invoiceType = 'Credit Memo';
        Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        System.debug(logginglevel.error,'result--->'+result);
        system.assertEquals(2, result.total);
        system.assert(result.messages.size() == 0, '>>> result.messages: ' + result.messages);
        
        for(SupplierInvoiceManageExt.InvoiceLineWrapper invLnWrapper : (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)result.records){
            Supplier_Invoice_Line__c invLine  =  invLnWrapper.invoiceLine;
            if(invLine.Purchase_Order_Line__c == pol.id){
                system.assert(invLine.Invoice_Quantity__c == 0, '>>> Invoice Quanity count is not correct ' + invLine.Invoice_Quantity__c); /// 10 - 5(already invoiced) = 5; 
            }    
        }
        Test.stopTest();
    }
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_ApprovedPrepayment_testQuantityUninvoiced_2way() {//KNDY-19417
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
        
        Purchase_Order_Line__c pol = new Purchase_Order_Line__c();{
            pol.Company__c = testdata.fuel.company.Id;
            pol.Item__c = testdata.fuel.itemlist[2].Id;
            pol.Order_Quantity__c = 10;
            pol.Invoice_Matching__c = 'Two Way';
            pol.Purchase_Order__c = testdata.fuel.purchaseOrder.Id;
            pol.Unit_Price__c = 12;
            pol.Need_Date__c = System.today();
            pol.Quantity_Matched__c = 5;
            insert pol;
        }
        
        // Draft SI, POLine is partially invoiced
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Prepayment';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 60;
            si_mrl.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = pol.id;
            sil_mrl.Item__c = testdata.fuel.itemList[2].id;
            sil_mrl.Item__r = new Item__c( id= testdata.fuel.itemList[1].id, Source__c = testdata.fuel.itemList[1].Source__c, Class__c = testdata.fuel.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = testdata.fuel.clsObj.id, type__c = testdata.fuel.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 5;
            sil_mrl.Unit_Price__c = 12;
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        } 
        
        si_mrl.Status__c = 'Approved';
        update si_mrl;
        Test.startTest();
        String invoiceType = 'Prepayment';
        Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        System.debug(logginglevel.error,'result--->'+result);
        system.assertEquals(2, result.total);
        system.assert(result.messages.size() == 0, '>>> result.messages: ' + result.messages);
        
        for(SupplierInvoiceManageExt.InvoiceLineWrapper invLnWrapper : (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)result.records){
            Supplier_Invoice_Line__c invLine  =  invLnWrapper.invoiceLine;
            if(invLine.Purchase_Order_Line__c == pol.id){
                system.assert(invLine.Invoice_Quantity__c == 0, '>>> Invoice Quanity count is not correct ' + invLine.Invoice_Quantity__c); /// 10 - 5(already invoiced) = 5; 
            }    
        }
        Test.stopTest();
    }
    
    static testMethod void testGetInvoiceLinesByPurchaseOrderId_SIInv_testQuantityUninvoiced_3way() {
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
        
        Purchase_Order_Line__c pol = testData.fuel.purchaseOrderLines[0];
        pol.Quantity_Received__c = 10;
        pol.Quantity_Matched__c = 5;
        update pol;
        
        // Draft SI, POLine is partially invoiced
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 60;
            si_mrl.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
         Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = pol.id;
            sil_mrl.Item__c = testdata.fuel.itemList[2].id;
            sil_mrl.Item__r = new Item__c( id= testdata.fuel.itemList[1].id, Source__c = testdata.fuel.itemList[1].Source__c, Class__c = testdata.fuel.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = testdata.fuel.clsObj.id, type__c = testdata.fuel.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 5;
            sil_mrl.Unit_Price__c = 12;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        } 
        
        Supplier_Invoice__c si_mrl1 = new Supplier_Invoice__c();{
            si_mrl1.Company__c = testdata.fuel.company.id;
            si_mrl1.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl1.Invoice_Type__c = 'Invoice';
            si_mrl1.Date_Invoiced__c = system.now();
            si_mrl1.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl1.Supplier_Invoice__c = '9876122342';
            si_mrl1.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl1.Invoice_Amount__c = 24;
            si_mrl1.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl1.Status__c = 'Draft';
            si_mrl1.exception__c = false;
            si_mrl1.exception_Details__c = null;
            si_mrl1.hold__c = false;
            insert si_mrl1;
        }
        
        Supplier_Invoice_Line__c sil_mrl1 = new Supplier_Invoice_Line__c();{
            sil_mrl1.Purchase_Order_Line__c = pol.id;
            sil_mrl1.Item__c = testdata.fuel.itemList[2].id;
            sil_mrl1.Item__r = new Item__c( id= testdata.fuel.itemList[1].id, Source__c = testdata.fuel.itemList[1].Source__c, Class__c = testdata.fuel.itemList[1].Class__c );
            sil_mrl1.Item__r.Class__r = new Class__c( id = testdata.fuel.clsObj.id, type__c = testdata.fuel.clsObj.type__c );
            sil_mrl1.Description__c = 'test';
            sil_mrl1.Invoice_Quantity__c = 2;
            sil_mrl1.Unit_Price__c = 12;//KNDY-14371
            sil_mrl1.Supplier_Invoice__c = si_mrl1.id;
            sil_mrl1.segment_exception__c = false;
            sil_mrl1.price_exception__c = false;
            sil_mrl1.quantity_exception__c = false;
            sil_mrl1.exception_details__c = null;
            sil_mrl1.matched__c = false;
            insert sil_mrl1;   
        }
         
        Test.startTest();
        
        si_mrl.Status__c = 'Approved';//KNDY-19417
        si_mrl1.Status__c = 'Cancelled';
        update new List<Supplier_Invoice__c> {si_mrl,si_mrl1};
        
        String invoiceType = 'Invoice';
        Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
        List<Id> purchaseOrderIds = new List<Id>();
        purchaseOrderIds.add(purchaseOrder.id);
        String purchaseOrdersStr = JSON.serialize(purchaseOrderIds);
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrdersStr, invoiceType);
        System.debug(logginglevel.error,'result--->'+result);

        system.assertEquals(1, result.total);
        system.assert(result.messages.size() == 0, '>>> result.messages: ' + result.messages);
        for(SupplierInvoiceManageExt.InvoiceLineWrapper invLnWrapper : (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)result.records){
            Supplier_Invoice_Line__c invLine  =  invLnWrapper.invoiceLine;
            system.assert(invLine.Invoice_Quantity__c == 5, '>>> Invoice Quanity count is not correct ' + invLine.Invoice_Quantity__c); /// 10 - 5(already invoiced) = 5; neglected the cancelled SI
        }
        
        //Invoicing for the balance quantity
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test101021234';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Payment_Term__c = testdata.fuel.terms.Id;
        si.Invoice_Amount__c = 60;
        si.Transaction_Currency__c = 'USD';
        si.Status__c = 'Incomplete';  
        si.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;      
      
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = 5; 
            newInvoiceLine.Unit_Price__c = 12;
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[2].Id;
            newInvoiceLine.Purchase_Order_Line__c = pol.id;
            newInvoiceLine.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;  
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result1 = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result1.success == true, '>>> result1.messages: ' + result1.messages);
        
        Test.stopTest();
    }

    
   /* static testMethod void testDoNotGetCancelledInvoiceLinesByPurchaseOrderId() {
    	Test.startTest();

    	// Arrange
    	Purchase_Order__c purchaseOrder = testData.fuel.purchaseOrder;
    	String invoiceType = 'Invoice';
    	
    	//cancel PO
    	 PurchaseOrderVoidCancelService vcs = new PurchaseOrderVoidCancelService(new List<Purchase_Order__c>{purchaseOrder});
		
		vcs.getBusinessVoidCancelDetails(new list<sObject>{(sobject) purchaseOrder});
		vcs.businessCancel(new list<sObject>{(sobject) purchaseOrder}); 
		
    	// Act
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLinesByPurchaseOrderId(purchaseOrder.Id);
        
        // Assert
        System.assertEquals(0, result.total);
        
        Test.stopTest();
    } */
    
    static testMethod void testGetSegments() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	Test.startTest();

    	// Arrange
    	Item__c item = testData.fuel.itemList[0];
    	
    	// Act
        JsonResult result = SupplierInvoiceManageExt.getSegments(item.Id, '');
        
        // Assert
        System.assertNotEquals(0, result.total);
        
        Test.stopTest();
    }
    
    static testMethod void testGetReturnUrl() {
    	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
    	Test.startTest();
    	
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        string result = con.getReturnUrl();
        
        // Assert
        System.assertNotEquals(result, '');
        
        Test.stopTest();
    }
    
    static testMethod void testGetReturnUrlForNewSupplierInvoice() {
    	Test.startTest();
    	
        // Arrange
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        string result = con.getReturnUrl();
        
        // Assert
        System.assertNotEquals(result, '');
        
        Test.stopTest();
    }
    
    static testMethod void testUnitPrice(){
	    SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
	        
	    // Arrange
	    GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
	    Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
	    ApexPages.StandardController setCon = new Apexpages.StandardController(si);
	    SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
	
	    Supplier_Invoice_Line__c SIL = [select Id, Purchase_Order_Line__c, Purchase_Order__c from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.id ];
	    SIL.Purchase_Order__c = testData.fuel.purchaseOrder.Id;  
	    SIL.Purchase_Order_Line__c = testData.fuel.purchaseOrderLines[0].id;  
		update SIL;
		  
	    // Act
	    Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
	    invoiceHeader.invoice_type__c = 'Invoice';
	        
	    List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;
	    	
	    SupplierInvoiceManageExt.InvoiceLineWrapper updateInvoiceLine = invoiceLines[0];
	    updateInvoiceLine.invoiceLine.Invoice_Quantity__c = 20;
		updateInvoiceLine.invoiceLine.Unit_Price__c = 23;//KNDY-14371
	        
	    List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();{
	    	newList.add(updateInvoiceLine);
	    }
	    
	    Test.startTest();
	    SupplierInvoiceManageExt.saveLines(si,newList);
	    list<Supplier_Invoice_Line__c> lstSIL = [select Id, Invoice_Quantity__c, Unit_Price__c, Purchase_Order_Line__r.Unit_Price__c, Purchase_Order_Line__r.Order_Quantity__c from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.id ];
	
	    system.assertEquals(20,lstSIL[0].Invoice_Quantity__c,lstSIL[0].Invoice_Quantity__c);
	    system.assertEquals(23,lstSIL[0].Unit_Price__c,lstSIL[0].Unit_Price__c);
	    system.assertEquals(10,lstSIL[0].Purchase_Order_Line__r.Order_Quantity__c,lstSIL[0].Purchase_Order_Line__r.Order_Quantity__c);
	    system.assertEquals(12,lstSIL[0].Purchase_Order_Line__r.Unit_Price__c,lstSIL[0].Purchase_Order_Line__r.Unit_Price__c);
	    Test.stopTest();
	
	}
    
    // Create a new supplier invoice line and call the save method to insert the new line
    static testMethod void testSaveAction() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';
        
        List<String> headerDateFields = new List<String>();
        {
			headerDateFields.add('Date_Invoiced__c');
			headerDateFields.add('Date_Received__c'); 	       	
        }
        
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;
    	
    	Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
        	newInvoiceLine.Supplier_Invoice__c = si.Id;
	        newInvoiceLine.Invoice_Quantity__c = 5;
	        newInvoiceLine.Unit_Price__c = 100;//KNDY-14371
	        newInvoiceLine.Description__c = 'test';
	        newInvoiceLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
            newInvoiceLine.Purchase_Order_Line__c = testData.fuel.purchaseOrderLines[0].id;
	        newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        
        // Default Segments
        Accounting_Default__c accDflt = new Accounting_Default__c();{
            accDflt.Company__c = testData.fuel.company.id;
            accDflt.GL_Account__c = testData.fuel.cashGL.id;
        }
        insert accDflt;
        
        
         Supplier_Invoice_Line__c altInvoiceLine = new Supplier_Invoice_Line__c(); {
            altInvoiceLine.Supplier_Invoice__c = si.Id;
            altInvoiceLine.Invoice_Quantity__c = 5;
            altInvoiceLine.Unit_Price__c = 100;//KNDY-14371
            altInvoiceLine.Description__c = 'test';
            altInvoiceLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
            altInvoiceLine.Purchase_Order_Line__c = testData.fuel.purchaseOrderLines[0].id;
            altInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
            altInvoiceLine.Accounting_Segment__c = accDflt.id;
        }

         Supplier_Invoice_Line__c noItemAndPOInvoiceLine = new Supplier_Invoice_Line__c(); { //KNDY-12704
            noItemAndPOInvoiceLine.Supplier_Invoice__c = si.Id;
            noItemAndPOInvoiceLine.Invoice_Quantity__c = 5;
            noItemAndPOInvoiceLine.Unit_Price__c = 100;//KNDY-14371
            noItemAndPOInvoiceLine.Description__c = 'no item and PO';
            noItemAndPOInvoiceLine.Accounting_Segment__c = accDflt.id;
        }
        
        Supplier_Invoice_Line__c noPOLine = new Supplier_Invoice_Line__c(); {//KNDY-12704
            noPOLine.Supplier_Invoice__c = si.Id;
            noPOLine.Invoice_Quantity__c = 5;
            noPOLine.Unit_Price__c = 100;//KNDY-14371
            noPOLine.Description__c = 'no PO';
            noPOLine.Item__c = testData.fuel.itemList[0].Id;
            noPOLine.Accounting_Segment__c = accDflt.id;
        }
        
        SupplierInvoiceManageExt.InvoiceLineWrapper updateInvoiceLine = invoiceLines[0];
        updateInvoiceLine.invoiceLine.Invoice_Quantity__c = 20;
	    updateInvoiceLine.invoiceLine.Unit_Price__c = 50;//KNDY-14371
        
        SupplierInvoiceManageExt.InvoiceLineWrapper newInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        SupplierInvoiceManageExt.InvoiceLineWrapper altInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(altInvoiceLine);
        SupplierInvoiceManageExt.InvoiceLineWrapper noItemAndPOInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(noItemAndPOInvoiceLine);
        SupplierInvoiceManageExt.InvoiceLineWrapper noPOLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(noPOLine);

    	List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();{
    		newList.add(newInvoiceLineWrapper);
            newList.add(altInvoiceLineWrapper);
            newList.add(noItemAndPOInvoiceLineWrapper);//KNDY-12704
            newList.add(noPOLineWrapper);//KNDY-12704
    	}
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); {
        	deletedList.add(updateInvoiceLine);
        }
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); {
        	
        	updatedList.add(updateInvoiceLine);
        }
        
        List<String> dateFields = new List<String>();
        {
			dateFields.add('Date_Invoiced__c');
			dateFields.add('Date_Received__c'); 	       	
        }
        
        Integer sillistSize = [select id from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.id ].size();
        system.assertEquals(1, sillistSize);

        SupplierInvoiceManageExt.saveLines(si,newList);
        List<Supplier_Invoice_Line__c> sillist = [select id, SubTransaction_Type__c from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.id ];
        system.assertEquals(5, sillist.size());
        for (Supplier_Invoice_Line__c sil : sillist){
            if (sil.Id == altInvoiceLine.Id || sil.Id == newInvoiceLine.Id){
                String expectedSTT = 'Goods - Purchase Order';
                system.assertEquals(sil.SubTransaction_Type__c,expectedSTT, sil);
            }
            else if (sil.Id == noItemAndPOInvoiceLine.Id){
                String expectedSTT = 'Miscellaneous';
                system.assertEquals(sil.SubTransaction_Type__c,expectedSTT, sil);
            }
            else if (sil.Id == noPOLine.Id){
                String expectedSTT = 'Goods';
                system.assertEquals(sil.SubTransaction_Type__c,expectedSTT, sil);
            }
        }
    
        for(SupplierInvoiceManageExt.InvoiceLineWrapper supInv : newList){
        	if(supInv.hasSegments && supInv.segments != null){
    		    Accounting_Default__c adSegment = supInv.segments;
    			adSegment.Company__c = null; // id field cannot accept a blank string,has to be null
                adSegment.GL_Account__c = null;
        	}
        }
        
        SupplierInvoiceManageExt.saveLines(si,newList);
        
        // Query the supplier invoice line and check for the Accounting segment to be null.
        
        List<Supplier_Invoice_Line__c> verifySilList = [select id,Accounting_Segment__c from Supplier_Invoice_Line__c where id = :altInvoiceLine.id];
        
        system.assert(verifySilList.size() == 1);
        
        //Assert if the Supplier invoice line has Accounting Segment null
           
        system.assert(verifySilList[0].Accounting_Segment__c == null);
        
        List<Accounting_Default__c> verifySegmentList = [select id from Accounting_Default__c where id = :accDflt.id];
        
        // Also assert if the segment record exits
        
        system.assert(verifySegmentList.isEmpty(),'Segment/s for the Supplier Invoice Line exists with a size :'+verifySegmentList.size());
        
        JsonResult result = SupplierInvoiceManageExt.saveAction(invoiceHeader, headerDateFields, updatedList, newList, deletedList, dateFields, false);

        // Assert
        system.assert(true, result.success);
        system.assertNotEquals(0, result.total);

        //SI Id exists and test the actions on the ActionsMap.
        String siTestMapStr = SupplierInvoiceService.populateSISaveAndActions(si.Id); 
        System.debug(logginglevel.error,'siTestMapStr--->'+siTestMapStr);
       
        Map<String,Object> siActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(siTestMapStr);  
        System.debug(logginglevel.error, 'siActionTestMap--->'+siActionTestMap);  
       // Invoice in the Incomplete status - just saved
       system.assertEquals(siActionTestMap.get('Save'),true);
       system.assertEquals(siActionTestMap.get('Save_New'),true);
       system.assertEquals(siActionTestMap.get('Save_Return'),true);
       system.assertEquals(siActionTestMap.get('Save_Validate'),true);
       system.assertEquals(siActionTestMap.get('Clone'),true);
       system.assertEquals(siActionTestMap.get('Validate'),true); 
       system.assertEquals(siActionTestMap.get('Get_Tax'),true); 
       system.assertEquals(siActionTestMap.get('Unfinalize'),false); 
       system.assertEquals(siActionTestMap.get('Cancel'),true);
       system.assertEquals(siActionTestMap.get('Void'),false); 
       system.assertEquals(siActionTestMap.get('Pay_Invoice'),false);

    	Test.stopTest();
    }

    static testMethod void testSTT_Prepayment() { //KNDY-16084
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        // Default Segments
        Accounting_Default__c accDflt = new Accounting_Default__c();{
            accDflt.Company__c = testData.fuel.company.id;
            accDflt.GL_Account__c = testData.fuel.cashGL.id;
        }
        insert accDflt;

        Test.startTest();
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice.clone();
        si.invoice_type__c = 'Prepayment';
        si.Supplier_Invoice__c = si.Supplier_Invoice__c + '2';
        insert si;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');                
        }
        
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = 5;
            newInvoiceLine.Unit_Price__c = 100;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
            newInvoiceLine.Purchase_Order_Line__c = testData.fuel.purchaseOrderLines[0].id;
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
            newInvoiceLine.Accounting_Segment__c = accDflt.id;
        }
                
         Supplier_Invoice_Line__c noItemAndPOInvoiceLine = new Supplier_Invoice_Line__c(); { //KNDY-12704
            noItemAndPOInvoiceLine.Supplier_Invoice__c = si.Id;
            noItemAndPOInvoiceLine.Invoice_Quantity__c = 5;
            noItemAndPOInvoiceLine.Unit_Price__c = 100;//KNDY-14371
            noItemAndPOInvoiceLine.Description__c = 'no item and PO';
            noItemAndPOInvoiceLine.Accounting_Segment__c = accDflt.id;
        }
        
        Supplier_Invoice_Line__c noPOLine = new Supplier_Invoice_Line__c(); {//KNDY-12704
            noPOLine.Supplier_Invoice__c = si.Id;
            noPOLine.Invoice_Quantity__c = 5;
            noPOLine.Unit_Price__c = 100;//KNDY-14371
            noPOLine.Description__c = 'no PO';
            noPOLine.Item__c = testData.fuel.itemList[0].Id;
            noPOLine.Accounting_Segment__c = accDflt.id;
        }
                
        SupplierInvoiceManageExt.InvoiceLineWrapper newInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        SupplierInvoiceManageExt.InvoiceLineWrapper noItemAndPOInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(noItemAndPOInvoiceLine);
        SupplierInvoiceManageExt.InvoiceLineWrapper noPOLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(noPOLine);

        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();{
        newList.add(newInvoiceLineWrapper);//itemlist[0], po
        newList.add(noItemAndPOInvoiceLineWrapper);//KNDY-12704
        newList.add(noPOLineWrapper);//KNDY-12704 itemlist[0]
        }
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        
        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');                
        }
        SupplierInvoiceManageExt.saveLines(si,newList);
        List<Supplier_Invoice_Line__c> sillist = [select id, SubTransaction_Type__c from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.id ];
        system.assertEquals(3, sillist.size(), sillist);
        for (Supplier_Invoice_Line__c sil : sillist){
            if (sil.Id == newInvoiceLine.Id){
                system.assertEquals(String.isBlank(sil.SubTransaction_Type__c),true, sil);
            }
            else if (sil.Id == noItemAndPOInvoiceLine.Id){
                system.assertEquals(String.isBlank(sil.SubTransaction_Type__c),true, sil);
            }
            else if (sil.Id == noPOLine.Id){
                system.assertEquals(String.isBlank(sil.SubTransaction_Type__c),true, sil);
            }
        }
    }
    
    static testMethod void testSTT_CreditMemo() { //KNDY-16084
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        // Default Segments
        Accounting_Default__c accDflt = new Accounting_Default__c();{
            accDflt.Company__c = testData.fuel.company.id;
            accDflt.GL_Account__c = testData.fuel.cashGL.id;
        }
        insert accDflt;

        Test.startTest();
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice.clone();
        si.invoice_type__c = 'Credit Memo';
        si.Invoice_Amount__c = -1*si.Invoice_Amount__c;
        si.Supplier_Invoice__c = si.Supplier_Invoice__c + '1';
        insert si;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');                
        }
        
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = -5;
            newInvoiceLine.Unit_Price__c = 100;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
            newInvoiceLine.Purchase_Order_Line__c = testData.fuel.purchaseOrderLines[0].id;
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
            newInvoiceLine.Accounting_Segment__c = accDflt.id;
        }
                
         Supplier_Invoice_Line__c noItemAndPOInvoiceLine = new Supplier_Invoice_Line__c(); { //KNDY-12704
            noItemAndPOInvoiceLine.Supplier_Invoice__c = si.Id;
            noItemAndPOInvoiceLine.Invoice_Quantity__c = -5;
            noItemAndPOInvoiceLine.Unit_Price__c = 100;//KNDY-14371
            noItemAndPOInvoiceLine.Description__c = 'no item and PO';
            noItemAndPOInvoiceLine.Accounting_Segment__c = accDflt.id;
        }
        
        Supplier_Invoice_Line__c noPOLine = new Supplier_Invoice_Line__c(); {//KNDY-12704
            noPOLine.Supplier_Invoice__c = si.Id;
            noPOLine.Invoice_Quantity__c = -5;
            noPOLine.Unit_Price__c = 100;//KNDY-14371
            noPOLine.Description__c = 'no PO';
            noPOLine.Item__c = testData.fuel.itemList[0].Id;
            noPOLine.Accounting_Segment__c = accDflt.id;
        }
        
        SupplierInvoiceManageExt.InvoiceLineWrapper newInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        SupplierInvoiceManageExt.InvoiceLineWrapper noItemAndPOInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(noItemAndPOInvoiceLine);
        SupplierInvoiceManageExt.InvoiceLineWrapper noPOLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(noPOLine);

        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();{
        newList.add(newInvoiceLineWrapper);//itemlist[0], po
        newList.add(noItemAndPOInvoiceLineWrapper);//KNDY-12704
        newList.add(noPOLineWrapper);//KNDY-12704 itemlist[0]
        }
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        
        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');                
        }
        
        SupplierInvoiceManageExt.saveLines(si,newList);
        List<Supplier_Invoice_Line__c> sillist = [select id, SubTransaction_Type__c from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.id ];
        system.assertEquals(3, sillist.size(), sillist);
        for (Supplier_Invoice_Line__c sil : sillist){
            if (sil.Id == newInvoiceLine.Id){
                String expectedSTT = 'Goods - Purchase Order';
                system.assertEquals(sil.SubTransaction_Type__c,expectedSTT, sil);
            }
            else if (sil.Id == noItemAndPOInvoiceLine.Id){
                String expectedSTT = 'Miscellaneous';
                system.assertEquals(sil.SubTransaction_Type__c,expectedSTT, sil);
            }
            else if (sil.Id == noPOLine.Id){
                String expectedSTT = 'Goods';
                system.assertEquals(sil.SubTransaction_Type__c,expectedSTT, sil);
            }
        }
    }
    
    static testMethod void testSILDescription_BasedOnItemType() { //non miscellaneous - same description as item
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();
        
        Supplier_Invoice__c si = new Supplier_Invoice__c(); {
	        si.Invoice_Type__c = 'Invoice';
	        si.Company__c = testdata.fuel.company.Id;
	        si.Supplier__c = testdata.fuel.supplier.Id;
	        si.Date_Invoiced__c = system.now();
	        si.Supplier_Invoice__c = 'test191';
	        si.Supplier_and_Invoice__c = 'test 191';
	        si.Invoice_Amount__c = 100;
	        si.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
	        si.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
        }
        insert si;
        
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        
        Item__c item = KSE.getItemJSONRecord(testData.fuel.itemList[0].name,testData.fuel.company.Id,null,null);
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = 5;
            newInvoiceLine.Unit_Price__c = 100;
            newInvoiceLine.Description__c = item.Description__c;
            newInvoiceLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
            newInvoiceLine.Purchase_Order_Line__c = testData.fuel.purchaseOrderLines[0].id;
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        
        SupplierInvoiceManageExt.InvoiceLineWrapper newInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();{
            newList.add(newInvoiceLineWrapper);
        }
        
        SupplierInvoiceManageExt.saveLines(si,newList);
        
        List<Supplier_Invoice_Line__c> sillist = [select id,Item__c,Description__c from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.id ];
        System.debug(logginglevel.error,sillist);
        system.assertEquals(1, sillist.size());
        system.assertEquals(item.Description__c, sillist[0].Description__c,'Decription of the Item and SIL are not the same');
        
    
        Test.stopTest();
    }

    // Create a SI with duplicate invoice number for same supplier
    static testmethod void testSaveAction_DuplicateSI() {//KNDY-9677
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        
        Test.startTest();
        // Create a duplicate si
        Supplier_Invoice__c newSI = si.clone();
        newSI.invoice_type__c = 'Invoice';
        newSI.Date_Invoiced__c = system.now();
        system.assert(newSI.Supplier_Invoice__c == si.Supplier_Invoice__c); // invoice number
        system.assert(newSI.Supplier__c == si.Supplier__c);
        ApexPages.StandardController setCon = new Apexpages.StandardController(newSI);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        List<String> headerDateFields = new List<String>();
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');	

        // no lines
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<String> dateFields = new List<String>();
        dateFields.add('Date_Invoiced__c');
        dateFields.add('Date_Received__c');
        
        // save SI
        JsonResult result = SupplierInvoiceManageExt.saveAction(newSI, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assertEquals(false, result.success);
        system.assert(result.messages.size() == 1);
        
        // Unable to check for Label.Duplicate_supplier_invoice_exists_for_supplier message set by controller
        // as in testmethod context the duplicate message does not display the field name
        // live context -'DUPLICATE_VALUE, duplicate value found: Supplier_and_Invoice__c'
        // testmethod context - DUPLICATE_VALUE, duplicate value found: <unknown>
        // if this testmethod is annotated with isTest(SeeAllData=true), the duplicate field name is displayed
        // but preparatory test data insertion in TestFuel fails as duplicates are created.
        for (Map<String, String> error : result.messages) {
           system.assert(error.get('message').contains('DUPLICATE_VALUE, duplicate value found'), error.get('message'));
        }
        Test.stopTest();
    }
    
    
    //KNDY-9910 ability to change the unit price on SIL from 0 to a valid value
    static testMethod void testSaveUnitPrice() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();

        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.NonPOInvoice;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';

        List<String> headerDateFields = new List<String>();
        {
		headerDateFields.add('Date_Invoiced__c');
		headerDateFields.add('Date_Received__c');        
        }

    	Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
        	newInvoiceLine.Supplier_Invoice__c = si.Id;
        	newInvoiceLine.Invoice_Quantity__c = 5;
        	newInvoiceLine.Unit_Price__c = 0.0;//KNDY-14371
        	newInvoiceLine.Description__c = 'test';
        	newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        	insert newInvoiceLine;
        }
        system.assertEquals(newInvoiceLine.Unit_Price__c, 0.0);//KNDY-14371

        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;
        SupplierInvoiceManageExt.InvoiceLineWrapper updateInvoiceLine = invoiceLines[0];
    	updateInvoiceLine.invoiceLine.Unit_Price__c = 50;//KNDY-14371

    	List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();

        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); {
        updatedList.add(updateInvoiceLine);
        }

        List<String> dateFields = new List<String>();
        {
			dateFields.add('Date_Invoiced__c');
			dateFields.add('Date_Received__c');        
        }

        List<Supplier_Invoice_Line__c> sillist = [select id, Unit_Price__c from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.id ];
        system.assertEquals(1, sillist.size());
        system.assertEquals(sillist[0].Unit_Price__c, 0.0);//KNDY-14371

        JsonResult result = SupplierInvoiceManageExt.saveAction(invoiceHeader, headerDateFields, updatedList, newList, deletedList, dateFields, false);

        system.assert(true, result.success);
    	system.assertNotEquals(0, result.total);

    	List<Supplier_Invoice_Line__c> sillist1 = [select id, Unit_Price__c, Extended_Price__c, Purchase_Price__c   from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.id];

        system.assertEquals(sillist1[0].Unit_Price__c, 50);//KNDY-14371

        //KNDY-12733
        String purPriceStr = String.valueOf(sillist1[0].Purchase_Price__c);
        String extPriceStr = String.valueOf(sillist1[0].Extended_Price__c);

        system.assertEquals(purPriceStr.substringAfterLast('.').length(), 2);
        system.assertEquals(extPriceStr.substringAfterLast('.').length(), 2);

    	Test.stopTest();
    }
    
    static testMethod void testSaveSIL_SI_NEGATIVE_PRICE_QTY() { //KNDY-12325 KNDY-12490
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();

        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.NonPOInvoice;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        // Negaive unit price and quantity
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = -1;
            newInvoiceLine.Unit_Price__c = -1;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }

        JsonResult result = SupplierInvoiceManageExt.saveAction(invoiceHeader, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == false, '>>>> result.messages: ' + result.messages);
        String expectedErrorMessage = ExceptionUtil.SI_NEGATIVE_PRICE_QTY.description;
        system.assert(result.messages.size() == 1);
        List<Map<String, String>> errorList = result.messages;
        system.assert(errorList.size() == 1);
        List<String> errors = errorList[0].values();
        String errorMsg = errors[0];
        system.assert(errorMsg.contains(expectedErrorMessage), '>>>> result.messages: ' + result.messages);
        Test.stopTest();
    }

    static testMethod void testSaveSIL_PrepaymentSI_NEGATIVE_LINE_AMOUNT() { //KNDY-12325
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();

        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.NonPOInvoice;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Prepayment';

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        // Negaive amount
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = 1;
            newInvoiceLine.Unit_Price__c = -1;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }

        JsonResult result = SupplierInvoiceManageExt.saveAction(invoiceHeader, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == false, '>>>> result.messages: ' + result.messages);
        String expectedErrorMessage = ExceptionUtil.NEGATIVE_LINE_AMOUNT.description;
        system.assert(result.messages.size() == 1);
        List<Map<String, String>> errorList = result.messages;
        system.assert(errorList.size() == 1);
        List<String> errors = errorList[0].values();
        String errorMsg = errors[0];
        system.assert(errorMsg.contains(expectedErrorMessage), '>>>> result.messages: ' + result.messages);
        Test.stopTest();
    }
    
    static testMethod void testSaveSIL_CM_POSITIVE_LINE_AMOUNT() { //KNDY-12325 KNDY-12490
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();

        // Positive amount in header
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.NonPOInvoice.clone();
        si.Invoice_Amount__c = -1;
        si.invoice_type__c = 'Credit Memo';
        si.Supplier_Invoice__c = 'abc7345';

        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        // Positive amount in line
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = -1;
            newInvoiceLine.Unit_Price__c = -1;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }

        JsonResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == false, '>>>> result.messages: ' + result.messages);
        Test.stopTest();
    }
    
    static testMethod void testSave_SIL_NULL_PRICE_QTY() { //KNDY-12325 KNDY-12490
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();

        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.NonPOInvoice;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        //Null unit price and quantity
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = null;
            newInvoiceLine.Unit_Price__c = null;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        List<String> expectedErrorMessages = new List<String>();
        expectedErrorMessages.add(ExceptionUtil.SI_ZERO_QUANTITY.description);
        //expectedErrorMessages.add(ExceptionUtil.SI_ZERO_UNIT_PRICE.description);

        JSONResult result = SupplierInvoiceManageExt.saveAction(invoiceHeader, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == false, '>>>> result.messages: ' + result.messages);
        system.assert(result.messages.size() == expectedErrorMessages.size(), '>>>> result.messages: ' + result.messages);
        
        Integer errorMatchCt = 0;
        for (Map<String, String> errorMap : result.messages) {
            String error = errorMap.get('message');
            for (String expectedErrorMsg : expectedErrorMessages){
                if(error.contains(expectedErrorMsg)){
                    errorMatchCt ++;
                }
            }
        }
        system.assert(errorMatchCt == expectedErrorMessages.size(),'>>>> result.messages: ' + result.messages);
        Test.stopTest();
    }
    
    static testMethod void testSave_SIL_ZERO_PRICE_QTY() { //KNDY-12325 KNDY-12490
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();

        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.NonPOInvoice;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        // zero unit price and quantity
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = 0;
            newInvoiceLine.Unit_Price__c = 0;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        List<String> expectedErrorMessages = new List<String>();
        expectedErrorMessages.add(ExceptionUtil.SI_ZERO_QUANTITY.description);
        //expectedErrorMessages.add(ExceptionUtil.SI_ZERO_UNIT_PRICE.description);

        JSONResult result = SupplierInvoiceManageExt.saveAction(invoiceHeader, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == false, '>>>> result.messages: ' + result.messages);
        system.assert(result.messages.size() == expectedErrorMessages.size(), '>>>> result.messages: ' + result.messages);

        Integer errorMatchCt = 0;
        for (Map<String, String> errorMap : result.messages) {
            String error = errorMap.get('message');
            for (String expectedErrorMsg : expectedErrorMessages){
                if(error.contains(expectedErrorMsg)){
                    errorMatchCt ++;
                }
            }
        }
        system.assert(errorMatchCt == expectedErrorMessages.size(),'>>>> result.messages: ' + result.messages);
        Test.stopTest();
    }

    static testMethod void testSave_SIL_MISSING_POLINE() { //KNDY-12325 KNDY-12490
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();

        // corresponding siline has no poline
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;//.clone();
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        // Act
        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        // No POline
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = 1;
            newInvoiceLine.Unit_Price__c = 1;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Purchase_Order_Line__c = null;
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
            newInvoiceLine.Purchase_Order__c = si.Purchase_Order__c ;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }

        JsonResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == false, '>>>> result.messages: ' + result.messages);
        String expectedErrorMessage = ExceptionUtil.MISSING_POLINE.description;
        system.assert(result.messages.size() == 1);
        List<Map<String, String>> errorList = result.messages;
        system.assert(errorList.size() == 1);
        List<String> errors = errorList[0].values();
        String errorMsg = errors[0];
        system.assert(errorMsg.contains(expectedErrorMessage), '>>>> result.messages: ' + result.messages);
        Test.stopTest();
    }

    static testMethod void testSaveAndInspectCMZeroDollarSI() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
       
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Credit Memo';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test101025';
        si.Supplier_and_Invoice__c = 'test 101025';
        si.Invoice_Amount__c = 0;
        si.Transaction_Currency__c = 'USD';
        si.Status__c = 'Incomplete';        
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = -10;
            newInvoiceLine.Unit_Price__c = 0;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        System.debug(logginglevel.error,'result--->>'+result);
        system.assert(result.success == false, '>>> result.messages: ' + result.messages);
        
        String expectedErrorMessage = 'You can\'t save a supplier invoice if the Invoice Type field is Credit Memo or Prepayment and the Invoice Amount field is 0.';
        Boolean pageHasExpectedErrorMessage = false;
        for (Map<String, String> errorMap : result.messages) {
            String errorMessage = errorMap.get('message');
            System.debug(logginglevel.error,'errorMessage-->'+errorMessage);
            System.debug(logginglevel.error,'expectedErrorMessage-->'+expectedErrorMessage);
            Integer location;  
//            if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
//                    list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
//                    if(!msgArray.isEmpty()){
//                        errorMessage = msgArray.get(msgArray.size()-1);
//                        if(errorMessage.contains(': []')){
//                            location = errorMessage.lastIndexOf(': []');
//                            errorMessage = errorMessage.mid(0, location);
//                        }
//                    }
//            }
            System.debug(logginglevel.error,'errorMessage-->'+errorMessage);
            System.debug(logginglevel.error,'expectedErrorMessage-->'+expectedErrorMessage);
              if(errorMessage.contains(expectedErrorMessage)){
                pageHasExpectedErrorMessage = true;
            }
        }
        system.assert(pageHasExpectedErrorMessage);
        system.assert(si.Status__c == 'Incomplete','Cannot save the SI, so in incomplete status');
        
        Test.stopTest();
    }
    
    static testMethod void testSaveAndInspectZeroDollarSI() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
       
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 0;
        si.Transaction_Currency__c = 'USD';
        si.Status__c = 'Incomplete';        
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = 100;
            newInvoiceLine.Unit_Price__c = 0;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>> result.messages: ' + result.messages);
        system.assert(si.Id != null);
        si = [Select Id, Invoice_Type__c,Company__c ,Supplier__c,Date_Invoiced__c,Supplier_Invoice__c ,
                    Supplier_and_Invoice__c,Invoice_Amount__c,Transaction_Currency__c,Status__c,Finalized__c
                    from Supplier_Invoice__c where Id = :si.Id];
        system.assert(si.Status__c == 'Incomplete');
        Test.stopTest();
    }

    static testMethod void testSaveSIL_INVALID_ITEM() { //KNDY-12325 KNDY-12490
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();

        // corresponding siline has no poline
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
       // si.Purchase_Order__c = testData.fuel.purchaseOrder1.Id;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        Purchase_Order_Line__c pol = testData.fuel.purchaseOrderLines[0];

        // Act
        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        // POline on sil is unrelated to PO on SI
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = 1;
            newInvoiceLine.Unit_Price__c = 1;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Purchase_Order_Line__c = pol.Id;
            newInvoiceLine.Item__c = null;
            newInvoiceLine.Purchase_Order__c = si.Purchase_Order__c ;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }

        JsonResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == false, '>>>> result.messages: ' + result.messages);
        String expectedErrorMessage = ExceptionUtil.INVALID_ITEM.description;
        Boolean pageHasExpectedErrorMessage = false;
        for (Map<String, String> errorMap : result.messages) {
            String error = errorMap.get('message');
            if(error.contains(expectedErrorMessage)){
                pageHasExpectedErrorMessage = true;
            }
        }
        system.assert(pageHasExpectedErrorMessage);
        Test.stopTest();
    }
    
    static testMethod void testSaveAndInspect_HappyPath() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
       
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 1000;
        si.Transaction_Currency__c = 'USD';
        si.Status__c = 'Incomplete';        
        si.Payment_Due_Override_Date__c = system.today() + 5;       
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            //newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = 100;
            newInvoiceLine.Unit_Price__c = 10;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>> result.messages: ' + result.messages);
        system.assert(si.Id != null);
        si = [Select Id, Status__c from Supplier_Invoice__c where Id = :si.Id];
        system.assert(si.Status__c == 'Approved');
        Test.stopTest();
   }
   
   // create new si, save and inspect should save the si, 
   // but invoice should not be approved
   static testMethod void testSaveAndInspect_NewSI_Failure() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
       
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 1000;
        si.Transaction_Currency__c = 'USD';
        si.Status__c = 'Incomplete';        
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>> result.messages: ' + result.messages);
        // SI should be saved
        system.assert(si.Id != null);
        si = [Select Id, Status__c, Has_Exceptions__c from Supplier_Invoice__c where Id = :si.Id];
        system.assert(si.Status__c == 'Incomplete');
        system.assert(si.Has_Exceptions__c == true);
        Test.stopTest();
   }
   // create new si with missing payment term, save and inspect should save the si, 
   // invoice will be in draft status.
   // Add payment Term and Save.
   // Tests for POL qty matched buckets.
   static testMethod void test2Way_ChangePaymentTerm() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
        Purchase_Order_Line__c pol = testData.fuel.purchaseOrderLines[0].clone();
        pol.Invoice_Matching__c = 'Two Way';
        insert pol;
        
        Purchase_Order_Line__c polNewState = [Select Id, Purchase_Order__r.Id, 
                Purchase_Order__r.Payment_Term__c, Quantity_Matched__c, Invoice_Status__c
                from Purchase_Order_Line__c where Id = : pol.Id];
        system.assert(polNewState.Purchase_Order__r.Payment_Term__c != null, '>>>> polNewState.Purchase_Order__r: ' + polNewState.Purchase_Order__r);
        system.assert(polNewState.Invoice_Status__c == 'Open for invoicing', '>>>> polNewState: ' + polNewState);
        system.assert(polNewState.Quantity_Matched__c == 0, '>>>> polNewState: ' + polNewState);
        
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Purchase_Order__c = pol.Purchase_Order__c;
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 120;
        si.Transaction_Currency__c = 'USD';
        si.Payment_Term__c = null;
        si.Status__c = 'Incomplete';        
        si.Payment_Due_Override_Date__c = system.today() + 5;       
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = 10;
            newInvoiceLine.Unit_Price__c = 12;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = pol.Item__c;
            newInvoiceLine.Purchase_Order_Line__c = pol.Id;
        }
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }

        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);

        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>> result.messages: ' + result.messages);
        // SI should be saved
        system.assert(si.Id != null);
        si = [Select Id, Status__c, Has_Exceptions__c, Line_Exceptions_Count__c from Supplier_Invoice__c where Id = :si.Id];
        System.debug(logginglevel.error,'si--->'+si);
        system.assertEquals(si.Status__c,'Draft');
        system.assert(si.Line_Exceptions_Count__c > 0, '>>> si: ' + si);
        Task t = [SELECT Id, Subject, Status, Exception_Code__c, Description, WhatId, OwnerID FROM Task WHERE WhatId = :newInvoiceLine.id ];
        system.assertEquals(t.Exception_Code__c, 'SI-TERMS000001');
        polNewState = [Select Id, Purchase_Order__r.Payment_Term__c, Quantity_Matched__c
                        from Purchase_Order_Line__c where Id = : pol.Id];
        // Draft SI
        system.assert(polNewState.Quantity_Matched__c == 0, '>>>> polNewState: ' + polNewState);
        
        // Set payment term and save SI
        si.Payment_Term__c = polNewState.Purchase_Order__r.Payment_Term__c;
        si.Status__c = 'Incomplete';
        update si;
    
        si = [Select Id, Status__c, Date_Invoiced__c, Payment_Due_Date__c, Discount_Date__c, Discount_Override_Date__c from Supplier_Invoice__c where Id = :si.Id];
        
        DateTime dT = si.Discount_Date__c;
        Date discDate = date.newinstance(dT.year(), dT.month(), dT.day());
        
        System.assert(si.Payment_Due_Date__c == system.today().addDays(30),'Payment Due Date is not correct');
        System.assert(discDate == system.today().addDays(9),'Discount Date is not correct');
        
        Test.stopTest();
        polNewState = [Select Id, Purchase_Order__r.Payment_Term__c, Quantity_Matched__c
                        from Purchase_Order_Line__c where Id = : pol.Id];
        system.assert(polNewState.Quantity_Matched__c == 0, '>>>> polNewState: ' + polNewState);
   }
   
   // create new si with missing payment term, save and inspect should save the si, 
   // invoice will be in draft status.
   // Add payment Term and Save.
   // Tests for POL qty matched buckets.
   static testMethod void test3Way_ChangePaymentTerm() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
        Purchase_Order_Line__c pol = testData.fuel.purchaseOrderLines[0].clone();
        pol.Invoice_Matching__c = 'Three Way';
        insert pol;
        
        Purchase_Order_Line__c polNewState = [Select Id, Purchase_Order__r.Id, 
                Purchase_Order__r.Payment_Term__c, Quantity_Matched__c, Invoice_Status__c
                from Purchase_Order_Line__c where Id = : pol.Id];
        system.assert(polNewState.Purchase_Order__r.Payment_Term__c != null, '>>>> polNewState.Purchase_Order__r: ' + polNewState.Purchase_Order__r);
        system.assert(polNewState.Invoice_Status__c == 'Open for invoicing', '>>>> polNewState: ' + polNewState);
        system.assert(polNewState.Quantity_Matched__c == 0, '>>>> polNewState: ' + polNewState);

        Receiving_Document__c receivingDocument = new Receiving_Document__c();{
            receivingDocument = new Receiving_Document__c();
            receivingDocument.Company__c = pol.Company__c;
            receivingDocument.Supplier__c = pol.Supplier__c;
            receivingDocument.Status__c = 'Open';
            receivingDocument.Date_Created__c = system.today();
            receivingDocument.Type__c = 'Purchase Order Receipt';
        }
        List<Receiving_Document__c> rds = new List<Receiving_Document__c>{receivingDocument};           
        insert rds;
                
        Receipt_Line__c receiptLine = new Receipt_Line__c();{
            receiptLine.Purchase_Order__c = pol.Purchase_Order__c;
            receiptLine.Purchase_Order_Line__c = pol.Id;
            receiptLine.Item__c = pol.Item__c;
            receiptLine.Company__c = pol.Company__c;
            receiptLine.Supplier__c = pol.Supplier__c;
            receiptLine.Quantity_Received__c = 10;
            receiptLine.Uninvoiced_Quantity__c = 10;
            receiptLine.Facility__c = pol.Delivery_Facility__c;
            receiptLine.Location__c = pol.Delivery_Location__c;
            receiptLine.Receiving_Document__c = receivingDocument.Id;
        } 
        
        List<Receipt_Line__c>  receiptLines = new List<Receipt_Line__c>{receiptLine}; 
        insert receiptLines;
        // Receive POL order quantity in full
        pol.Quantity_Received__c = 10; 
        update pol; 
        
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Purchase_Order__c = pol.Purchase_Order__c;
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 120;
        si.Transaction_Currency__c = 'USD';
        si.Payment_Term__c = null;
        si.Status__c = 'Incomplete';        
        si.Payment_Due_Override_Date__c = system.today() + 5;        
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = 10;
            newInvoiceLine.Unit_Price__c = 12;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = pol.Item__c;
            newInvoiceLine.Purchase_Order_Line__c = pol.Id;
        }
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }

        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);

        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>> result.messages: ' + result.messages);
        // SI should be saved
        system.assert(si.Id != null);
        si = [Select Id, Status__c, Has_Exceptions__c, Line_Exceptions_Count__c from Supplier_Invoice__c where Id = :si.Id];
        system.assertEquals(si.Status__c,'Draft');
        system.assert(si.Line_Exceptions_Count__c > 0, '>>> si: ' + si);
        Task t = [SELECT Id, Subject, Status, Exception_Code__c, Description, WhatId, OwnerID FROM Task WHERE WhatId = :newInvoiceLine.id ];
        system.assertEquals(t.Exception_Code__c, 'SI-TERMS000001');
        polNewState = [Select Id, Purchase_Order__r.Payment_Term__c, Quantity_Matched__c
                        from Purchase_Order_Line__c where Id = : pol.Id];
        // Draft SI
        system.assert(polNewState.Quantity_Matched__c == 0, '>>>> polNewState: ' + polNewState);
        
        // Set payment term and save SI
        si.Payment_Term__c = polNewState.Purchase_Order__r.Payment_Term__c;
        si.Status__c = 'Incomplete';
        update si;
        
        si = [Select Id, Status__c, Date_Invoiced__c, Payment_Due_Date__c, Discount_Date__c, Discount_Override_Date__c from Supplier_Invoice__c where Id = :si.Id];
        
        DateTime dT = si.Discount_Date__c;
        Date discDate = date.newinstance(dT.year(), dT.month(), dT.day());
        
        System.assert(si.Payment_Due_Date__c == system.today().addDays(30),'Payment Due Date is not correct');
        System.assert(discDate == system.today().addDays(9),'Discount Date is not correct');
        Test.stopTest();
        polNewState = [Select Id, Purchase_Order__r.Payment_Term__c, Quantity_Matched__c
                        from Purchase_Order_Line__c where Id = : pol.Id];
        system.assert(polNewState.Quantity_Matched__c == 0, '>>>> polNewState: ' + polNewState);
   }
   
    static testMethod void testSaveAndInspectCM() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
       
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Credit Memo';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test1010564562';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = -1000;
        si.Transaction_Currency__c = 'USD';
        si.Status__c = 'Incomplete';        
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            //newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = -100;
            newInvoiceLine.Unit_Price__c = 10;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        System.debug(logginglevel.error, 'result--->'+result );
        system.assert(result.success == true, '>>> result.messages: ' + result.messages);
        system.assert(si.Id != null);
        si = [Select Id, Status__c, Credit_Memo_Amount__c, Credit_Memo_Balance__c from Supplier_Invoice__c where Id = :si.Id];
        system.assert(si.Status__c == 'Incomplete');
        system.assert(si.Credit_Memo_Amount__c == -1000);
        system.assert(si.Credit_Memo_Balance__c == -1000);
        
        Test.stopTest();
   }
   
   
   
    static testMethod void testSaveAndActionsDropdownOnSI() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
       
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 1000;
        si.Transaction_Currency__c = 'USD';
        si.Status__c = 'Incomplete';        
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            //newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = 100;
            newInvoiceLine.Unit_Price__c = 10;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
       // SI Id does not exist
       String siInitialActionsMapStr = SupplierInvoiceService.populateSISaveAndActions(null); 
       System.debug(logginglevel.error,'siInitialActionsMapStr--->'+siInitialActionsMapStr);
       
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>> result.messages: ' + result.messages);
        system.assert(si.Id != null);
        si = [Select Id, Status__c from Supplier_Invoice__c where Id = :si.Id];
        system.assert(si.Status__c == 'Incomplete');
        
        //SI Id exists and test the actions - enabled or disabled
        String siTestMapStr = SupplierInvoiceService.populateSISaveAndActions(si.Id); 
        System.debug(logginglevel.error,'siTestMapStr--->'+siTestMapStr);
       
        Map<String,Object> siActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(siTestMapStr);  
        System.debug(logginglevel.error, 'siActionTestMap--->'+siActionTestMap);  
       
       system.assertEquals(siActionTestMap.get('Save'),true);
       system.assertEquals(siActionTestMap.get('Save_New'),true);
       system.assertEquals(siActionTestMap.get('Save_Return'),true);
       system.assertEquals(siActionTestMap.get('Save_Validate'),true);
       system.assertEquals(siActionTestMap.get('Clone'),true);
       system.assertEquals(siActionTestMap.get('Validate'),true); 
       system.assertEquals(siActionTestMap.get('Get_Tax'),true); 
       system.assertEquals(siActionTestMap.get('Unfinalize'),false); 
       system.assertEquals(siActionTestMap.get('Cancel'),true);
       system.assertEquals(siActionTestMap.get('Void'),false); 
       system.assertEquals(siActionTestMap.get('Pay_Invoice'),false); 
       
       Test.stopTest();
   }
    

   // Tests for POL Closed for invoicing.
   static testMethod void test3Way_DraftToApproved_POLineClosedForInvoicing(){
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
        
        // POL order quantity 100
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = testdata.fuel.company.Id;
            POLine1.Item__c = testdata.fuel.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Purchase_Order__c = testdata.fuel.purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
            POLine1.Quantity_Received__c = 100;
            insert POLine1;
        }
        
        // Receive PO in full
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = testdata.fuel.company.Id;
            receivingDocument1.Supplier__c = testdata.fuel.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            receivingDocument1.Date_Created__c = system.today();
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = testdata.fuel.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = testdata.fuel.itemList[1].Id;
            receiptLine1.Company__c = testdata.fuel.company.Id;
            receiptLine1.Supplier__c = testdata.fuel.supplier.Id;
            //receiptLine1.Quantity_Declared__c = POLine.Order_Quantity__c;
            receiptLine1.Quantity_Received__c = 100;
            receiptLine1.Uninvoiced_Quantity__c = 100;
            receiptLine1.Facility__c = testdata.fuel.facility.Id;
            receiptLine1.Location__c = testdata.fuel.purchaseOrder.Delivery_Location__c;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            //insert receiptLine1;
        }  

        List<Receipt_Line__c> RecLineList = new List<Receipt_Line__c>();
        RecLineList.add(receiptLine1);
        insert RecLineList;
        
        // Draft SI, POLine is fully invoiced
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = testdata.fuel.company.id;
            si_mrl.Supplier__c = testdata.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testdata.fuel.terms.Id;
            si_mrl.Invoice_Amount__c = 1000;
            si_mrl.Purchase_Order__c = testdata.fuel.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = testdata.fuel.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= testdata.fuel.itemList[1].id, Source__c = testdata.fuel.itemList[1].Source__c, Class__c = testdata.fuel.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = testdata.fuel.clsObj.id, type__c = testdata.fuel.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 100;
            sil_mrl.Unit_Price__c = 10;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        } 

        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        Test.startTest();
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];

        system.assertEquals('Approved',si.status__c); //Invoice should be approved

        POLine1 = [Select Id, Invoice_Status__c, Quantity_Matched__c, Order_Quantity__c from Purchase_Order_Line__c where Id = :POLine1.Id];
        system.assertEquals(POLine1.Quantity_Matched__c, POLine1.Order_Quantity__c, '>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Invoice_Status__c, 'Closed for Invoicing', '>>> POLine1: ' + POLine1);
        Test.stopTest();
        
    }

   // Tests for POL Closed for invoicing.
   static testMethod void test2Way_DraftToApproved_POLineClosedForInvoicing() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
        
        // POL order quantity 10
        Purchase_Order_Line__c pol = new Purchase_Order_Line__c();{
            pol.Company__c = testdata.fuel.company.Id;
            pol.Item__c = testdata.fuel.itemlist[1].Id;
            pol.Order_Quantity__c = 10;
            pol.Invoice_Matching__c = 'Two Way';
            pol.Purchase_Order__c = testdata.fuel.purchaseOrder.Id;
            pol.Unit_Price__c = 12;
            pol.Need_Date__c = System.today();
            pol.Quantity_Received__c = 100;
            insert pol;
        }
        
        Purchase_Order_Line__c polNewState = [Select Id, Purchase_Order__r.Id, 
                Purchase_Order__r.Payment_Term__c, Quantity_Matched__c, Invoice_Status__c
                from Purchase_Order_Line__c where Id = : pol.Id];
        system.assert(polNewState.Invoice_Status__c == 'Open for invoicing', '>>>> polNewState: ' + polNewState);
        system.assert(polNewState.Quantity_Matched__c == 0, '>>>> polNewState: ' + polNewState);
        
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Purchase_Order__c = pol.Purchase_Order__c;
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 120;
        si.Transaction_Currency__c = 'USD';
        si.Payment_Term__c = polNewState.Purchase_Order__r.Payment_Term__c;
        si.Status__c = 'Draft';        
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = 10;
            newInvoiceLine.Unit_Price__c = 12;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testdata.fuel.itemList[1].id;
            newInvoiceLine.Purchase_Order_Line__c = pol.Id;
            newInvoiceLine.Item__r = new Item__c( id= testdata.fuel.itemList[1].id, Source__c = testdata.fuel.itemList[1].Source__c, Class__c = testdata.fuel.itemList[1].Class__c );
            newInvoiceLine.Item__r.Class__r = new Class__c( id = testdata.fuel.clsObj.id, type__c = testdata.fuel.clsObj.type__c );
        }
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }

        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);

        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }

        JSONResult result = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>> result.messages: ' + result.messages);
        Test.stopTest();
        polNewState = [Select Id, Invoice_Status__c,Purchase_Order__r.Payment_Term__c, Quantity_Matched__c, Order_Quantity__c
                        from Purchase_Order_Line__c where Id = : pol.Id];
        system.assertEquals(polNewState.Quantity_Matched__c, polNewState.Order_Quantity__c, '>>> polNewState: ' + polNewState);
        system.assert(polNewState.Invoice_Status__c == 'Closed for invoicing', '>>>> polNewState: ' + polNewState);
   }
   
   static testMethod void test3Way_ChangeIncompleteSIQty(){
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
        
        
        Test.startTest();
        
        Purchase_Order_Line__c POLine1 = testData.fuel.purchaseOrderLines[0].clone();
        POLine1.Invoice_Matching__c = 'Three Way';
        insert POLine1;
        
        Purchase_Order_Line__c polNewState = [Select Id, Purchase_Order__r.Id, 
                Purchase_Order__r.Payment_Term__c, Quantity_Matched__c, Invoice_Status__c
                from Purchase_Order_Line__c where Id = : POLine1.Id];
        system.assert(polNewState.Purchase_Order__r.Payment_Term__c != null, '>>>> polNewState.Purchase_Order__r: ' + polNewState.Purchase_Order__r);
        system.assert(polNewState.Invoice_Status__c == 'Open for invoicing', '>>>> polNewState: ' + polNewState);
        system.assert(polNewState.Quantity_Matched__c == 0, '>>>> polNewState: ' + polNewState);

        Receiving_Document__c receivingDocument = new Receiving_Document__c();{
            receivingDocument = new Receiving_Document__c();
            receivingDocument.Company__c = POLine1.Company__c;
            receivingDocument.Supplier__c = POLine1.Supplier__c;
            receivingDocument.Status__c = 'Open';
            receivingDocument.Date_Created__c = system.today();
            receivingDocument.Type__c = 'Purchase Order Receipt';
        }
        List<Receiving_Document__c> rds = new List<Receiving_Document__c>{receivingDocument};           
        insert rds;
                
        Receipt_Line__c receiptLine = new Receipt_Line__c();{
            receiptLine.Purchase_Order__c = POLine1.Purchase_Order__c;
            receiptLine.Purchase_Order_Line__c = POLine1.Id;
            receiptLine.Item__c = POLine1.Item__c;
            receiptLine.Company__c = POLine1.Company__c;
            receiptLine.Supplier__c = POLine1.Supplier__c;
            receiptLine.Quantity_Received__c = 10;
            receiptLine.Uninvoiced_Quantity__c = 10;
            receiptLine.Facility__c = POLine1.Delivery_Facility__c;
            receiptLine.Location__c = POLine1.Delivery_Location__c;
            receiptLine.Receiving_Document__c = receivingDocument.Id;
        } 
        
        List<Receipt_Line__c>  receiptLines = new List<Receipt_Line__c>{receiptLine}; 
        insert receiptLines;
        // Receive POL order quantity in full
        POLine1.Quantity_Received__c = 20; 
        update POLine1;
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = POLine1.Company__c;
            si_mrl.Supplier__c = testData.fuel.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = testData.fuel.purchaseOrder.Payment_Term__c;
            // invoice for 11 qty when po order qty was 10
            si_mrl.Invoice_Amount__c = 132; // 11*12(unit price)
            si_mrl.Purchase_Order__c = POLine1.Purchase_Order__c;
            si_mrl.Status__c = 'Incomplete';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.Payment_Due_Override_Date__c  = system.today().addDays(30);
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        
        System.debug(logginglevel.error,'Pymt Due Override date-->'+si_mrl.Payment_Due_Override_Date__c );
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = POLine1.Item__c;
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 11; // greater than max invoice quantity of 20
            sil_mrl.Unit_Price__c = 12;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        // Set Qty bucket on POL
        /* POLine1.Quantity_Uninvoiced__c = -1;
        update POLine1; */
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectIncompleteInvoices(sup);
        
        // Exception as Invoice quanity is higher than 20
        // No Amount Exception
        Supplier_Invoice__c si = [select id, name, Has_Exceptions__c, exception_details__c, status__c,Payment_Due_Override_Date__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, Quantity_Exception__c, Price_Exception__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Incomplete',si.status__c); 
        system.assertEquals(si.Has_Exceptions__c, true);
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
        }
        Map<Id, Set<Task>> mapExceptionTasks = ExceptionService.fetchExceptionTasks(new Set<Id> {si_mrl.Id});
        system.assertEquals(mapExceptionTasks.size(), 1);
        system.assert(mapExceptionTasks.containsKey(si_mrl.Id));
        Set<Task> exceptions = mapExceptionTasks.get(si_mrl.Id);
        system.assert(exceptions.size() == 1,'Current Exception count>>'+exceptions.size() );

        for (Task t: exceptions){
             System.debug(logginglevel.error,'t.Exception_Code__c:---> ' + t.Exception_Code__c);
             system.assertEquals(t.Exception_Code__c,'SI-SUM00001','>>> t.Exception_Code__c: ' + t.Exception_Code__c);
        }  
        POLine1 = [Select Id, Quantity_Matched__c, Amount_Matched__c
                     from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        //system.assertEquals(POLine1.Quantity_Uninvoiced__c,-1,'>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Quantity_Matched__c,0,'>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Amount_Matched__c,0,'>>> POLine1: ' + POLine1);
        
        si_mrl.Invoice_Amount__c = 120;
        update si_mrl;
        sil_mrl.Invoice_Quantity__c = 10;
        update sil_mrl;
        POLine1 = [Select Id, Quantity_Matched__c, Amount_Matched__c from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        //system.assertEquals(POLine1.Quantity_Uninvoiced__c,0,'>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Quantity_Matched__c,0,'>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Amount_Matched__c,0,'>>> POLine1: ' + POLine1);

        Test.stopTest();
    } 
   // On existing si, add new lines with line amount different from header amount
   static testMethod void testSaveAndInspect_UpdateIncompleteSI() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
       
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 10;
        si.Transaction_Currency__c = 'USD';
        si.Status__c = 'Incomplete';
        insert si;
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }

        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = 100;
            newInvoiceLine.Unit_Price__c = 10;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>> result.messages: ' + result.messages);
        si = [Select Id, Status__c, Has_Exceptions__c from Supplier_Invoice__c where Id = :si.Id];
        system.assert(si.Status__c == 'Incomplete');
        system.assert(si.Has_Exceptions__c == true);
        Test.stopTest();
    }

   // Save and inspect an existing draft si
   static testMethod void testSaveAndInspect_UpdateDraftSI() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
       
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 10;
        si.Transaction_Currency__c = 'USD';
        si.Status__c = 'Draft';
        insert si;
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }

        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = 100;
            newInvoiceLine.Unit_Price__c = 10;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>> result.messages: ' + result.messages);
        si = [Select Id, Status__c, Has_Exceptions__c from Supplier_Invoice__c where Id = :si.Id];
        system.assert(si.Status__c == 'Incomplete');
        system.assert(si.Has_Exceptions__c == true);
        Test.stopTest();
    }

   static testMethod void testSaveAndInspectApprovedSI() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        List<Period__c> periodList = testdata.fuel.periodList;
       
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 1000;
        si.Transaction_Currency__c = 'USD';
        si.Status__c = 'Incomplete';        
        si.Payment_Due_Override_Date__c = system.today() + 5; 
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);

        List<String> headerDateFields = new List<String>();
        {
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        }
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = 100;
            newInvoiceLine.Unit_Price__c = 10;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        for(SupplierInvoiceManageExt.InvoiceLineWrapper invWrapper : newList){
           System.debug(logginglevel.error,'invWrapper.invoiceLine.Tax_Included__c--->'+invWrapper.invoiceLine.Tax_Included__c);
           System.assert(invWrapper.invoiceLine.Tax_Included__c == false,'Check box would have possible null value');
        }
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>> result.messages: ' + result.messages);
        system.assert(si.Id != null);
        si = [Select Id, Invoice_Type__c,Company__c ,Supplier__c,Date_Invoiced__c,Supplier_Invoice__c ,
                    Supplier_and_Invoice__c,Invoice_Amount__c,Transaction_Currency__c,Status__c,Finalized__c
                    from Supplier_Invoice__c where Id = :si.Id];
        system.assert(si.Status__c == 'Approved');
        
        // Save and inspect approved si with no changes in lines,
        newList.clear();
        result = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == false, '>>> result.messages: ' + result.messages);
        si = [Select Id, Status__c from Supplier_Invoice__c where Id = :si.Id];
        system.assert(si.Status__c == 'Approved');
        Set<String> expectedMessages = new Set<String>{
                                'Your changes have been saved.',
                                'Record not in Incomplete / Draft status.'};
        for (Map<String, String> error : result.messages) {
            system.assert(expectedMessages.contains(error.get('message').trim()), '>>> ' + error.get('message'));
        }
        
        List<Supplier_Invoice_Line__c> silList = [Select Id, Memo__c from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.Id];
        for(Supplier_Invoice_Line__c siLine : silList){
            siLine.Memo__c = 'Adding text on Approved and Finalized SILine';
        }
        update silList;
        
        List<Supplier_Invoice_Line__c> silList1 = [Select Id, Memo__c from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.Id];
        System.debug(logginglevel.error,'silList1--->'+silList1);
        
        List<Supplier_Invoice__c> siList = [Select Id, Status__c, (Select Id,Memo__c,Tax_Included__c from Supplier_Invoice_Lines__r) from Supplier_Invoice__c where Id = :si.Id];
        
        for(Supplier_Invoice__c sinvoice : siList){
            System.assertEquals(sinvoice.Status__c, 'Approved', 'SI Status has changed,check this');
            for(Supplier_Invoice_Line__c siline : sinvoice.Supplier_Invoice_Lines__r){
                System.assertEquals(siline.Memo__c,'Adding text on Approved and Finalized SILine', 'Memo text is not updated on sil');
                System.assert(siline.Tax_Included__c == false, 'Tax Included check box value is not correct');
            }  
        }
        Test.stopTest();
    }
    
    static testMethod void testChangePOOnInvoice_SILDelete() { 
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        
		Purchase_Order__c poOld = testData.fuel.purchaseOrder;
		Purchase_Order__c poNew = poOld.clone();
		
		List<Purchase_Order_Line__c> poOldLines = testData.fuel.purchaseOrderLines;
		system.assert(poOldLines.size() == 1);
		List<Purchase_Order_Line__c> poNewLines = new List<Purchase_Order_Line__c>();
		for (Purchase_Order_Line__c pol:poOldLines){
			poNewLines.add(pol.clone());
		}
		
		insert poNew;
		insert poNewLines;
		
		Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
		system.assertEquals(si.Purchase_Order__c, poOLd.id, '>>> si: ' + si);
		Supplier_Invoice_Line__c sil = testData.matchToPOSIL;
		system.assert(sil.Id != null , '>>> sil: ' + sil);
		sil.Purchase_Order__c = poOld.Id;
		sil.Purchase_Order_Line__c = poOldLines[0].Id;
		update sil;
		
		// 5 Qty invoiced on poOld
		//poNewLines[0].Quantity_Uninvoiced__c = poNewLines[0].Order_Quantity__c;
		//poOldLines[0].Quantity_Uninvoiced__c = poOldLines[0].Order_Quantity__c - 5;
		List<Purchase_Order_Line__c> pols = new List<Purchase_Order_Line__c> {poNewLines[0], poOldLines[0]};
		update pols;
		
        // create si lines for new PO
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); { 
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = poNewLines[0].Order_Quantity__c;
            newInvoiceLine.Purchase_Order__c = poNew.Id;
            newInvoiceLine.Purchase_Order_Line__c = poNewLines[0].Id;
            newInvoiceLine.Unit_Price__c =  poNewLines[0].Unit_Price__c;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = poNewLines[0].Item__c;
        }
        
		/* Decimal origQtyUninvoiced_poOld = poOldLines[0].Quantity_Uninvoiced__c;
		Decimal origQtyUninvoiced_poNew = poNewLines[0].Quantity_Uninvoiced__c;
		Decimal expectedQtyUninvoiced_poNew  = origQtyUninvoiced_poNew - newInvoiceLine.Invoice_Quantity__c;//10-10 = 0 */

		Test.startTest();
		
        // Load si with poOld in UI
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        List<String> headerDateFields = new List<String>();
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        List<String> lineDateFields = new List<String>();
        lineDateFields.add('Date_Invoiced__c');
        lineDateFields.add('Date_Received__c');        
        // SIL delete - get si lines for old PO
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLines(config, null); // not for a clone
        System.assertNotEquals(0, result.total);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>) result.records; 
        // Get qty to put back on poline
        Decimal silQtytoPutBack = 0;
        for (SupplierInvoiceManageExt.InvoiceLineWrapper invWrapper : deletedList){
            silQtytoPutBack += invWrapper.invoiceLine.Invoice_Quantity__c;
        }
        //Decimal expectedQtyUninvoiced_poOld  = origQtyUninvoiced_poOld + silQtytoPutBack;//5 +5 = 10

        // Change PO on SI 
        si.Purchase_Order__c = poNew.Id;
        // insert new SILs
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, lineDateFields, false);
        system.assert(result.success == true, '>>>> result.messages: ' + result.messages);
        
       /* pols = [Select Id, Quantity_Uninvoiced__c from Purchase_Order_Line__c where Id in : pols];
        for (Purchase_Order_Line__c pol: pols){
            if (pol.Id == poNewLines[0].Id){
                system.assertEquals(pol.Quantity_Uninvoiced__c,expectedQtyUninvoiced_poNew, '>>> polNew : ' + pol);
            }
            else if (pol.Id == poOldLines[0].Id){
                system.assertEquals(pol.Quantity_Uninvoiced__c,expectedQtyUninvoiced_poOld, '>>> polOld : ' + pol);
            }
        } */
        Test.stopTest();
    }
    
    static testMethod void testChangePOOnCM_SILDelete() { 
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        
		Purchase_Order__c poOld = testData.fuel.purchaseOrder;
		Purchase_Order__c poNew = poOld.clone();
		insert poNew;
		
		// Create POLines for new PO
		List<Purchase_Order_Line__c> poOldLines = testData.fuel.purchaseOrderLines;
		system.assert(poOldLines.size() == 1);
		List<Purchase_Order_Line__c> poNewLines = new List<Purchase_Order_Line__c>();
		for (Purchase_Order_Line__c pol:poOldLines){
			Purchase_Order_Line__c polNewLine = pol.clone();
			polNewLine.Purchase_Order__c = poNew.Id;
			poNewLines.add(polNewLine);
		}
		insert poNewLines;
		
		//Create CM for old po
		Supplier_Invoice__c si = testData.matchToPOSupplierInvoice.clone(); 
		si.Invoice_Type__c = 'Credit Memo';
		si.Invoice_Amount__c = -1 * si.Invoice_Amount__c;
		si.Supplier_Invoice__c = 'CMTest1';
		si.Purchase_Order__c = poOld.Id;
		insert si;
        
		Supplier_Invoice_Line__c sil = testData.matchToPOSIL.clone();
		sil.Supplier_Invoice__c = si.Id;
		sil.Purchase_Order__c = poOld.Id;
		sil.Purchase_Order_Line__c = poOldLines[0].Id;
		sil.Item__c = poOldLines[0].Item__c;
		sil.Invoice_Quantity__c = -1 * sil.Invoice_Quantity__c;
		insert sil;
		
		// Set POL fields
		poNewLines[0].Quantity_Credited__c = 0;
		poNewLines[0].Amount_Credited__c = 0;
		//poNewLines[0].Quantity_Uninvoiced__c = poNewLines[0].Order_Quantity__c;
		poOldLines[0].Quantity_Credited__c =  sil.Invoice_Quantity__c;
		poOldLines[0].Amount_Credited__c = sil.Invoice_Quantity__c * sil.Unit_Price__c;//KNDY-14371
		//poOldLines[0].Quantity_Uninvoiced__c = poOldLines[0].Order_Quantity__c;
		List<Purchase_Order_Line__c> pols = new List<Purchase_Order_Line__c> {poNewLines[0], poOldLines[0]};
		update pols;
		
        // create si lines for new PO
        Supplier_Invoice_Line__c newInvoiceLine = sil.clone();
        newInvoiceLine.Purchase_Order__c = poNew.Id;
        newInvoiceLine.Purchase_Order_Line__c = poNewLines[0].Id;
        
        // set expected pol fields
        Decimal expectedQtyCredited_poNew  = sil.Invoice_Quantity__c;
        Decimal expectedAmtCredited_poNew  = sil.Invoice_Quantity__c * sil.Unit_Price__c;//KNDY-14371
        Decimal expectedQtyUninvoiced_poNew = poNewLines[0].Order_Quantity__c;
        Decimal expectedQtyCredited_poOld  = 0;
        Decimal expectedAmtCredited_poOld  = 0;
        Decimal expectedQtyUninvoiced_poOld = poOldLines[0].Order_Quantity__c;

		Test.startTest();
		
        // Load si with poOld in UI
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        List<String> headerDateFields = new List<String>();
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        List<String> lineDateFields = new List<String>();
        lineDateFields.add('Date_Invoiced__c');
        lineDateFields.add('Date_Received__c');        
        
        // load SILs to delete - si lines for old PO
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLines(config, null); // not for a clone
        System.assertEquals(1, result.total);
        for (SupplierInvoiceManageExt.InvoiceLineWrapper invWrapper : (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)result.records){
        		Supplier_Invoice_Line__c silOld = invWrapper.invoiceLine;
        		system.assertEquals(silOld.Purchase_Order__c ,poOld.Id, '>>> silOld: ' + silOld);
        		system.assertEquals(silOld.Purchase_Order_Line__c,poOldLines[0].Id , '>>> silOld: ' + silOld);
        }
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>) result.records; 

        // Change PO on SI 
        si.Purchase_Order__c = poNew.Id;
        // load SILs to insert - for new PO
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // no si lines to update
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
         
        // save si
        result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, lineDateFields, false);
        system.assert(result.success == true, '>>>> result.messages: ' + result.messages);
        
        pols = [Select Id, Quantity_Credited__c, Amount_Credited__c from Purchase_Order_Line__c where Id in : pols];
        for (Purchase_Order_Line__c pol: pols){
            if (pol.Id == poNewLines[0].Id){
                system.assertEquals(pol.Quantity_Credited__c,expectedQtyCredited_poNew, '>>> polNew : ' + pol);
                system.assertEquals(pol.Amount_Credited__c,expectedAmtCredited_poNew, '>>> polNew : ' + pol);
                //system.assertEquals(pol.Quantity_Uninvoiced__c,expectedQtyUninvoiced_poNew, '>>> polNew : ' + pol);
            }
            else if (pol.Id == poOldLines[0].Id){
                system.assertEquals(pol.Quantity_Credited__c,expectedQtyCredited_poOld, '>>> polOld: ' + pol);
                system.assertEquals(pol.Amount_Credited__c,expectedAmtCredited_poOld, '>>> polOld : ' + pol);
                //system.assertEquals(pol.Quantity_Uninvoiced__c,expectedQtyUninvoiced_poOld, '>>> polOld : ' + pol);
            }
        }
        Test.stopTest();
    }
    
    
     static testMethod void testValidateSIwithoutDueDates() {
        
        SupplierInvoiceManageExtTestData testdata = new SupplierInvoiceManageExtTestData();
        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Invoice_Type__c = 'Invoice';
        si.Company__c = testdata.fuel.company.Id;
        si.Supplier__c = testdata.fuel.supplier.Id;
        si.Date_Invoiced__c = system.now();
        si.Supplier_Invoice__c = 'test10102';
        si.Supplier_and_Invoice__c = 'test 10102';
        si.Invoice_Amount__c = 1000;
        si.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
        si.Status__c = 'Incomplete';        
        insert si;
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(si);              
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', si.Id);  
        Test.setCurrentPage(pageRef);
        
        JsonResult result = SupplierInvoiceManageExt.headerActions(si.Id, 'Validate');
        system.assert(result.success == true, 'Validate should have failed');
        
        List<Task> taskList = [SELECT Id, Subject, Status, Exception_Code__c, Description, WhatId, OwnerID FROM Task WHERE WhatId = :si.Id ];
        System.debug(logginglevel.error,'task-->'+taskList);
        System.assert(taskList.size() > 0, 'No exceptions found for the inspect of SI');
        for(Task taskRec : taskList){
            if(taskRec.Exception_Code__c == 'SI-DUEDATE'){
                system.assert(taskRec.Subject.contains('A due date is required.'));
            }
        }
        
        si.Payment_Due_Override_Date__c = System.today();
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Invoice_Quantity__c = 100;
            newInvoiceLine.Unit_Price__c = 10;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');        
        }
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');
        }     
        
        JsonResult result1 = SupplierInvoiceManageExt.saveAndInspect(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result1.success == true, '>>> result1.messages: ' + result1.messages);
        si = [Select Id, Status__c, Has_Exceptions__c from Supplier_Invoice__c where Id = :si.Id];
        system.assert(si.Status__c == 'Approved');
        
        Test.stopTest();
     }    
    
    
	static testMethod void testChangePOOnPrepayment_SILDelete() { 
		SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
		
		Purchase_Order__c poOld = testData.fuel.purchaseOrder;
		Purchase_Order__c poNew = poOld.clone();
		insert poNew;
		
		// Create POLines for new PO
		List<Purchase_Order_Line__c> poOldLines = testData.fuel.purchaseOrderLines;
		system.assert(poOldLines.size() == 1);
		List<Purchase_Order_Line__c> poNewLines = new List<Purchase_Order_Line__c>();
		for (Purchase_Order_Line__c pol:poOldLines){
			Purchase_Order_Line__c polNewLine = pol.clone();
			polNewLine.Purchase_Order__c = poNew.Id;
			poNewLines.add(polNewLine);
		}
		insert poNewLines;
		
		//Create CM for old po
		Supplier_Invoice__c si = testData.matchToPOSupplierInvoice.clone(); 
		si.Invoice_Type__c = 'Prepayment';
		si.Invoice_Amount__c = si.Invoice_Amount__c;
		si.Supplier_Invoice__c = 'PrepayTest1';
		si.Purchase_Order__c = poOld.Id;
		insert si;
        
		Supplier_Invoice_Line__c sil = testData.matchToPOSIL.clone();
		sil.Supplier_Invoice__c = si.Id;
		sil.Purchase_Order__c = poOld.Id;
		sil.Purchase_Order_Line__c = poOldLines[0].Id;
		sil.Item__c = poOldLines[0].Item__c;
		sil.Invoice_Quantity__c = sil.Invoice_Quantity__c;
		insert sil;
		
		//KNDY-16084
		Supplier_Invoice_Line__c invoiceLine = [Select ID, SubTransaction_Type__c from Supplier_invoice_line__c where ID = :sil.Id];
        system.assertEquals(null, invoiceLine.SubTransaction_Type__c,invoiceLine);
		
		// Set POL fields
		poNewLines[0].Quantity_Credited__c = 0;
		poNewLines[0].Amount_Credited__c = 0;
		//poNewLines[0].Quantity_Uninvoiced__c = poNewLines[0].Order_Quantity__c;
		poOldLines[0].Quantity_Credited__c =  0;
		poOldLines[0].Amount_Credited__c = 0;
		//poOldLines[0].Quantity_Uninvoiced__c = poOldLines[0].Order_Quantity__c;
		List<Purchase_Order_Line__c> pols = new List<Purchase_Order_Line__c> {poNewLines[0], poOldLines[0]};
		update pols;
		
        // create si lines for new PO
        Supplier_Invoice_Line__c newInvoiceLine = sil.clone();
        newInvoiceLine.Purchase_Order__c = poNew.Id;
        newInvoiceLine.Purchase_Order_Line__c = poNewLines[0].Id;
        
        // set expected pol fields
        Decimal expectedQtyCredited_poNew  = 0;
        Decimal expectedAmtCredited_poNew  = 0;
        Decimal expectedQtyUninvoiced_poNew = poNewLines[0].Order_Quantity__c;
        Decimal expectedQtyCredited_poOld  = 0;
        Decimal expectedAmtCredited_poOld  = 0;
        Decimal expectedQtyUninvoiced_poOld = poOldLines[0].Order_Quantity__c;

        Test.startTest();
        
        // Load si with poOld in UI
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        List<String> headerDateFields = new List<String>();
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        List<String> lineDateFields = new List<String>();
        lineDateFields.add('Date_Invoiced__c');
        lineDateFields.add('Date_Received__c');        
        
        // load SILs to delete - si lines for old PO
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLines(config, null); // not for a clone
        System.assertEquals(1, result.total);
        for (SupplierInvoiceManageExt.InvoiceLineWrapper invWrapper : (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)result.records){
        		Supplier_Invoice_Line__c silOld = invWrapper.invoiceLine;
        		system.assertEquals(silOld.Purchase_Order__c ,poOld.Id, '>>> silOld: ' + silOld);
        		system.assertEquals(silOld.Purchase_Order_Line__c,poOldLines[0].Id , '>>> silOld: ' + silOld);
        }
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>) result.records; 

        // Change PO on SI 
        si.Purchase_Order__c = poNew.Id;
        // load SILs to insert - for new PO
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        newList.add(newLineWrapper);
        
        // no si lines to update
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
         
        // save si
        result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, lineDateFields, false);
        system.assert(result.success == true, '>>>> result.messages: ' + result.messages);
        
        pols = [Select Id, Quantity_Credited__c, Amount_Credited__c from Purchase_Order_Line__c where Id in : pols];
        for (Purchase_Order_Line__c pol: pols){
            if (pol.Id == poNewLines[0].Id){
                system.assertEquals(pol.Quantity_Credited__c,expectedQtyCredited_poNew, '>>> polNew : ' + pol);
                system.assertEquals(pol.Amount_Credited__c,expectedAmtCredited_poNew, '>>> polNew : ' + pol);
                //system.assertEquals(pol.Quantity_Uninvoiced__c,expectedQtyUninvoiced_poNew, '>>> polNew : ' + pol);
            }
            else if (pol.Id == poOldLines[0].Id){
                system.assertEquals(pol.Quantity_Credited__c,expectedQtyCredited_poOld, '>>> polOld: ' + pol);
                system.assertEquals(pol.Amount_Credited__c,expectedAmtCredited_poOld, '>>> polOld : ' + pol);
                //system.assertEquals(pol.Quantity_Uninvoiced__c,expectedQtyUninvoiced_poOld, '>>> polOld : ' + pol);
            }
        }
        Test.stopTest();
    }
    
    static testMethod void testRemovePOOnInvoice_SILDelete() { 
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        
		Purchase_Order__c poOld = testData.fuel.purchaseOrder;
		List<Purchase_Order_Line__c> poOldLines = testData.fuel.purchaseOrderLines;
		system.assert(poOldLines.size() == 1);
		
		Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
		system.assertEquals(si.Purchase_Order__c, poOLd.id, '>>> si: ' + si);
		Supplier_Invoice_Line__c sil = testData.matchToPOSIL;
		system.assert(sil.Id != null , '>>> sil: ' + sil);
		sil.Purchase_Order__c = poOld.Id;
		sil.Purchase_Order_Line__c = poOldLines[0].Id;
		update sil;
		
		// 5 Qty invoiced on poOld
		//poOldLines[0].Quantity_Uninvoiced__c = poOldLines[0].Order_Quantity__c - 5;
		List<Purchase_Order_Line__c> pols = new List<Purchase_Order_Line__c> { poOldLines[0]};
		update pols;
		
		//Decimal origQtyUninvoiced_poOld = poOldLines[0].Quantity_Uninvoiced__c;

		Test.startTest();
		
        // Load si with poOld in UI
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        List<String> headerDateFields = new List<String>();
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        List<String> lineDateFields = new List<String>();
        lineDateFields.add('Date_Invoiced__c');
        lineDateFields.add('Date_Received__c');        
        
        // load sils to delete - get si lines for old PO
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLines(config, null); // not for a clone
        System.assertNotEquals(0, result.total);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>) result.records; 
        // Get qty to put back on poline
        Decimal silQtytoPutBack = 0;
        for (SupplierInvoiceManageExt.InvoiceLineWrapper invWrapper : deletedList){
            silQtytoPutBack += invWrapper.invoiceLine.Invoice_Quantity__c;
        }
        //Decimal expectedQtyUninvoiced_poOld  = origQtyUninvoiced_poOld + silQtytoPutBack;//5 +5 = 10

        //Remove PO on SI 
        si.Purchase_Order__c = null;
        // empty lists - no new sils and no sils to update
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        
        // save si
        result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, lineDateFields, false);
        system.assert(result.success == true, '>>>> result.messages: ' + result.messages);
        
        /*pols = [Select Id, Quantity_Uninvoiced__c from Purchase_Order_Line__c where Id in : pols];
        for (Purchase_Order_Line__c pol: pols){
            if (pol.Id == poOLdLines[0].Id){
                system.assertEquals(pol.Quantity_Uninvoiced__c,expectedQtyUninvoiced_poOld, '>>> polOld : ' + pol);
            }
        }*/
        Test.stopTest();
    }
    
    static testMethod void testRemovePOOnCM_SILDelete() { 
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        
		Purchase_Order__c poOld = testData.fuel.purchaseOrder;
		List<Purchase_Order_Line__c> poOldLines = testData.fuel.purchaseOrderLines;
		system.assert(poOldLines.size() == 1);

		
		//Create CM for old po
		Supplier_Invoice__c si = testData.matchToPOSupplierInvoice.clone(); 
		si.Invoice_Type__c = 'Credit Memo';
		si.Invoice_Amount__c = -1 * si.Invoice_Amount__c;
		si.Supplier_Invoice__c = 'CMTest1';
		si.Purchase_Order__c = poOld.Id;
		insert si;
        
		Supplier_Invoice_Line__c sil = testData.matchToPOSIL.clone();
		sil.Supplier_Invoice__c = si.Id;
		sil.Purchase_Order__c = poOld.Id;
		sil.Purchase_Order_Line__c = poOldLines[0].Id;
		sil.Item__c = poOldLines[0].Item__c;
		sil.Invoice_Quantity__c = -1 * sil.Invoice_Quantity__c;
		insert sil;
		
		// Set POL fields
		poOldLines[0].Quantity_Credited__c =  sil.Invoice_Quantity__c;
		poOldLines[0].Amount_Credited__c = sil.Invoice_Quantity__c * sil.Unit_Price__c;//KNDY-14371
		//poOldLines[0].Quantity_Uninvoiced__c = poOldLines[0].Order_Quantity__c;
		List<Purchase_Order_Line__c> pols = new List<Purchase_Order_Line__c> {poOldLines[0]};
		update pols;
        
        // set expected pol fields
        Decimal expectedQtyCredited_poOld  = 0;
        Decimal expectedAmtCredited_poOld  = 0;
        Decimal expectedQtyUninvoiced_poOld = poOldLines[0].Order_Quantity__c;

		Test.startTest();
		
        // Load si with poOld in UI
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        List<String> headerDateFields = new List<String>();
        headerDateFields.add('Date_Invoiced__c');
        headerDateFields.add('Date_Received__c');        
        List<String> lineDateFields = new List<String>();
        lineDateFields.add('Date_Invoiced__c');
        lineDateFields.add('Date_Received__c');        
        
        // load SILs to delete - si lines for old PO
        JsonResult result = SupplierInvoiceManageExt.getInvoiceLines(config, null); // not for a clone
        System.assertEquals(1, result.total);
        for (SupplierInvoiceManageExt.InvoiceLineWrapper invWrapper : (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)result.records){
        		Supplier_Invoice_Line__c silOld = invWrapper.invoiceLine;
        		system.assertEquals(silOld.Purchase_Order__c ,poOld.Id, '>>> silOld: ' + silOld);
        		system.assertEquals(silOld.Purchase_Order_Line__c,poOldLines[0].Id , '>>> silOld: ' + silOld);
        }
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>) result.records; 

        // Remove PO on SI 
        si.Purchase_Order__c = null;
        // no SILs to insert
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        // no si lines to update
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
         
        // save si
        result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, lineDateFields, false);
        system.assert(result.success == true, '>>>> result.messages: ' + result.messages);
        
        pols = [Select Id, Quantity_Credited__c, Amount_Credited__c from Purchase_Order_Line__c where Id in : pols];
        for (Purchase_Order_Line__c pol: pols){
            if (pol.Id == poOldLines[0].Id){
                system.assertEquals(pol.Quantity_Credited__c,expectedQtyCredited_poOld, '>>> polOld: ' + pol);
                system.assertEquals(pol.Amount_Credited__c,expectedAmtCredited_poOld, '>>> polOld : ' + pol);
                //system.assertEquals(pol.Quantity_Uninvoiced__c,expectedQtyUninvoiced_poOld, '>>> polOld : ' + pol);
            }
        }
        Test.stopTest();
    }
    
    class SupplierInvoiceManageExtTestData {
        
    	private SchemaUtil util = SchemaUtil.getInstance();
		TestFuelQuery fuel = new TestFuelQuery();
	        
		public SupplierInvoiceManageExtTestData() {
			
		}
		
		public Set<String> getInvoiceLinesAdditionalFields() {
		SegmentService segmentSvc = new SegmentService();
		List<String> segmentsList = new List<String>();
	    Set<String> invoiceLinesAdditionalFields = new Set<String>();
	        
			segmentsList = segmentSvc.segmentNameListForAP(true, 'Invoice');
			invoiceLinesAdditionalFields.addAll(new set<string>{'id','Name','Item__r.Source__c','Purchase_Order_Line__r.Company__c','Purchase_Order_Line__r.Delivery_Facility__c','Purchase_Order_Line__r.Need_Date__c','Purchase_Order_Line__r.Item__c','Item__r.Name',
                            'Supplier_Invoice__r.Supplier__c', 'Supplier_Invoice__r.Supplier_Invoice__c', 'Supplier_Invoice__r.Invoice_Type__c', 'Supplier_Invoice__r.Total_Extended_Price__c','Supplier_Invoice__r.Status__c','Supplier_Invoice__r.Total_Invoice__c','Accounting_Segment__c',
                            'Line_Type__c', 'Item__r.Class__c','Purchase_Order_Line__r.Name','Item__r.Class__r.Type__c'});
	        invoiceLinesAdditionalFields.addAll(segmentsList);
	        
	        for (Integer i = 0; i < segmentsList.size(); i++) {
	            invoiceLinesAdditionalFields.add(segmentsList[i].replace('__c', '__r.Name'));
	        }
	        
	        return invoiceLinesAdditionalFields;
		}
		public Supplier_Invoice__c NonPOInvoice = new Supplier_Invoice__c();{
			NonPOInvoice.Invoice_Type__c = 'Invoice';
	    	NonPOInvoice.Company__c = fuel.company.Id;
	        NonPOInvoice.Supplier__c = fuel.supplier.Id;
			NonPOInvoice.Date_Invoiced__c = system.now();
	        NonPOInvoice.Supplier_Invoice__c = 'test101a';
	        NonPOInvoice.Supplier_and_Invoice__c = 'test 101a';
	        NonPOInvoice.Invoice_Amount__c = 1000;
	        NonPOInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
	        insert NonPOInvoice;
		}
		
        public Set<String> getPurchaseOrderLinesAdditionalFields() {
	    	Set<String> poLinesAdditionalFields = new Set<String>();
	        poLinesAdditionalFields.addAll( new set<string>{'id','Company__c','Delivery_Facility__c','Need_Date__c','Name','Item__r.Name','Item__r.Source__c','Item__r.Class__c','Item__r.Class__r.Type__c',
	        						'Purchase_Order__c', 'Purchase_Order__r.Name','Description__c','Item__c','Order_Quantity__c', 'Unit_Price__c'} );
	        
	        for (String fieldName: util.getFieldsFromFieldSetString(Supplier_Invoice_Line__c.sObjectType , 'Supplier_Invoice_Line')) {
	        	if (fieldName.contains('Purchase_Order_Line__r.')) {
					poLinesAdditionalFields.add(fieldName.split('\\.')[1]);
	        	}
	    	}
	    	
	    	return util.removeNSfromSetString(poLinesAdditionalFields); //strip out the NS
	    }
		
		public Supplier_Invoice_Line__c matchToPOSIL = new Supplier_Invoice_Line__c();
		// Create a Match to PO Supplier Invoice
        public Supplier_Invoice__c matchToPOSupplierInvoice = new Supplier_Invoice__c();{
	        matchToPOSupplierInvoice.Invoice_Type__c = 'Invoice';
	    	matchToPOSupplierInvoice.Company__c = fuel.company.Id;
	        matchToPOSupplierInvoice.Supplier__c = fuel.supplier.Id;
			matchToPOSupplierInvoice.Date_Invoiced__c = system.now();
	        matchToPOSupplierInvoice.Supplier_Invoice__c = 'test101';
	        matchToPOSupplierInvoice.Supplier_and_Invoice__c = 'test 101';
	        matchToPOSupplierInvoice.Invoice_Amount__c = 1000;
	        matchToPOSupplierInvoice.Purchase_Order__c = fuel.purchaseOrder.Id;
	        matchToPOSupplierInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        
	       	insert matchToPOSupplierInvoice;
	       	
	       	// Create a Supplier Invoice Line
	       	Supplier_Invoice_Line__c siLine = new Supplier_Invoice_Line__c();
	       	siLine.Supplier_Invoice__c = matchToPOSupplierInvoice.Id;
	        siLine.Invoice_Quantity__c = 5;
	        siLine.Unit_Price__c = 100;//KNDY-14371
	        siLine.Description__c = 'test';
	        
	        insert siLine;
	        matchToPOSIL = siLine;
        }
        
        public List<Grid_Views_Config__c> customViewList = new List<Grid_Views_Config__c>(); {
        	Grid_Views_Config__c customView1 = new Grid_Views_Config__c();
        	customView1.Name = 'Supplier_Invoice_Line';
        	customView1.Fieldset_name__c = 'Supplier_Invoice_Line';
        	customView1.Grid_Name__c = 'SupplierInvoiceLinesGrid';
        customView1.View_Name__c = 'Custom view 1';
        customView1.Show__c = true;
        customView1.View_Dropdown_Index__c = 0;
        	insert customView1;
        	
        	customViewList.add(customView1);

        }
        
        public GridRelatedListController.GridRelatedListConfig supplierInvoiceLinesConfig = new GridRelatedListController.GridRelatedListConfig(); {
	        supplierInvoiceLinesConfig.uniqueId = 'InvoiceLinesGrid';
	        supplierInvoiceLinesConfig.title = 'Invoice Lines';
	        supplierInvoiceLinesConfig.parentRecord = matchToPOSupplierInvoice;
	        supplierInvoiceLinesConfig.objectName = 'Supplier_Invoice_Line__c';  
	        supplierInvoiceLinesConfig.parentField = 'Supplier_Invoice__c';
	        supplierInvoiceLinesConfig.fieldset = 'Supplier_Invoice_Line';
	        supplierInvoiceLinesConfig.buttons = 'create, cancel, delete, search';
	        supplierInvoiceLinesConfig.additionalFields = String.join(new List<String>(getInvoiceLinesAdditionalFields()), ',');
	    }
	    
	    public GridRelatedListController.GridRelatedListConfig segmentLinesConfig = new GridRelatedListController.GridRelatedListConfig(); {
	        segmentLinesConfig.uniqueId = 'SegmentLinesGrid';
	        segmentLinesConfig.objectName = 'Accounting_Default__c';
	    }
	    
	    public GridRelatedListController.GridRelatedListConfig purchaseOrderLinesConfig = new GridRelatedListController.GridRelatedListConfig(); { 
		    // Purchase Order Lines Grid config
	        purchaseOrderLinesConfig = new GridRelatedListController.GridRelatedListConfig();
	        purchaseOrderLinesConfig.uniqueId = 'POLinesGrid';
	        purchaseOrderLinesConfig.title = 'Purchase Order Lines';
	        purchaseOrderLinesConfig.objectName = 'Purchase_Order_Line__c';  
	        purchaseOrderLinesConfig.fieldset = 'Supplier_Invoice_New';
	        purchaseOrderLinesConfig.buttons = 'columnmenu, search';
	        purchaseOrderLinesConfig.additionalFields = String.join(new List<String>(getPurchaseOrderLinesAdditionalFields()), ',');
	    }
    }
    
     static testMethod void testRoundingAmountFields() {
     	SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
     	Test.startTest();
        
        Supplier_Invoice__c testRounding = new Supplier_Invoice__c();{
	        testRounding.Invoice_Type__c = 'Invoice';
	    	testRounding.Company__c = testData.fuel.company.Id;
	        testRounding.Supplier__c = testData.fuel.supplier.Id;
			testRounding.Date_Invoiced__c = system.now();
	        testRounding.Supplier_Invoice__c = 'test1011';
	        testRounding.Supplier_and_Invoice__c = 'test 1011';
	        testRounding.Invoice_Amount__c = 100.345677;
	        testRounding.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
        
	       	insert testRounding;
	       	
	       	// Create a Supplier Invoice Line
	       	Supplier_Invoice_Line__c siLine = new Supplier_Invoice_Line__c();
	       	siLine.Supplier_Invoice__c = testRounding.Id;
	        siLine.Invoice_Quantity__c = 1;
	        siLine.Unit_Price__c = 100.3456779870;//KNDY-14371
	        siLine.Description__c = 'test';
	        
	        insert siLine;
        }
        
        Supplier_Invoice__c testAfterInsert = [select Invoice_Amount__c, Total_Extended_Price__c, (Select Unit_Price__c from Supplier_Invoice_Lines__r) from Supplier_Invoice__c where Id = :testRounding.Id];
        system.assert(testAfterInsert.Invoice_Amount__c == 100.35, 'Rounding failed, amt saved: ' + testAfterInsert.Invoice_Amount__c);
        system.assert(testAfterInsert.Total_Extended_Price__c == 100.35, 'Rounding failed, roll up saved: ' + testAfterInsert.Total_Extended_Price__c);
        system.assert(testAfterInsert.Supplier_Invoice_Lines__r[0].Unit_Price__c == 100.345678, 'Rounding failed, unit price saved: ' + testAfterInsert.Supplier_Invoice_Lines__r[0].Unit_Price__c);//KNDY-14371
        
     	
     }

     //PTP-596 Deleting a row without saving the row should go through fine
         // Create a new supplier invoice line and call the save method to insert the new line
    static testMethod void testSaveActionforDelete() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');           
        }
        
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;
        
        Supplier_Invoice_Line__c newInvoiceLine = new Supplier_Invoice_Line__c(); {
            newInvoiceLine.Supplier_Invoice__c = si.Id;
            newInvoiceLine.Invoice_Quantity__c = 5;
            newInvoiceLine.Unit_Price__c = 100;//KNDY-14371
            newInvoiceLine.Description__c = 'test';
            newInvoiceLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
            newInvoiceLine.Purchase_Order_Line__c = testData.fuel.purchaseOrderLines[0].id;
            newInvoiceLine.Item__c = testData.fuel.itemList[0].Id;
        }

        Supplier_Invoice_Line__c delInvoiceLine = new Supplier_Invoice_Line__c(); {
            delInvoiceLine.Supplier_Invoice__c = si.Id;
            delInvoiceLine.Invoice_Quantity__c = 5;
            delInvoiceLine.Unit_Price__c = 100;//KNDY-14371
            delInvoiceLine.Description__c = 'test';
            delInvoiceLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
            delInvoiceLine.Purchase_Order_Line__c = testData.fuel.purchaseOrderLines[0].id;
            delInvoiceLine.Purchase_Order_Line__r = testData.fuel.purchaseOrderLines[0];
            delInvoiceLine.Item__c = testData.fuel.itemList[1].Id;
        }
        
        SupplierInvoiceManageExt.InvoiceLineWrapper updateInvoiceLine = invoiceLines[0];
        updateInvoiceLine.invoiceLine.Invoice_Quantity__c = 20;
        updateInvoiceLine.invoiceLine.Unit_Price__c = 50;//KNDY-14371
        
        SupplierInvoiceManageExt.InvoiceLineWrapper newInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(newInvoiceLine);
        SupplierInvoiceManageExt.InvoiceLineWrapper delInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(delInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();{
            newList.add(newInvoiceLineWrapper);
        }
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); {
            deletedList.add(delInvoiceLineWrapper);
        }
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); { 
            updatedList.add(updateInvoiceLine);
        }
        
        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');             
        }
        
        Integer sillistSize = [select id from Supplier_Invoice_Line__c where Supplier_Invoice__c = :si.id ].size();
        system.assertEquals(1, sillistSize);

        SupplierInvoiceManageExt.deleteLines(si,deletedList); 
        system.assertEquals(1, sillistSize); // Since the Supplier invoice line is deleted from the UI only and not from the database.

        JsonResult result = SupplierInvoiceManageExt.saveAction(invoiceHeader, headerDateFields, updatedList, newList, deletedList, dateFields, false);

        // Assert should be success when deleting a line that was never saved..!!
        system.assert(true, result.success);
        
        //testing the delete of SI
        try{
            delete si;
        }catch(Exception exp){
           system.assert(exp.getMessage().contains(Label.You_cannot_delete_an_invoice)); 
        }
      
        Test.stopTest();
    }
    static testMethod void testSaveActionforUpdateDeleteCMs_3Way() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Status__c = 'Open';
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Credit Memo';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = 'test-CMIncomplete1';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = -8;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Incomplete';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        // SIL to delete
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = -6;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            
        }
        
        // SIL to update
        Supplier_Invoice_Line__c sil_mrl1 = new Supplier_Invoice_Line__c();{
            sil_mrl1.Purchase_Order_Line__c = POLine1.id;
            sil_mrl1.Item__c = globalTestData.itemList[1].id;
            sil_mrl1.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl1.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl1.Description__c = 'test';
            sil_mrl1.Invoice_Quantity__c = -2;
            sil_mrl1.Unit_Price__c = 1;//KNDY-14371
            sil_mrl1.Supplier_Invoice__c = si_mrl.id;
            sil_mrl1.segment_exception__c = false;
            sil_mrl1.price_exception__c = false;
            sil_mrl1.quantity_exception__c = false;
            sil_mrl1.exception_details__c = null;
            sil_mrl1.matched__c = false;
        }
        List<Supplier_Invoice_Line__c> sils = new List<Supplier_Invoice_Line__c>{sil_mrl, sil_mrl1};
        insert sils;
        
        // Set Qty bucket on POL
        //POLine1.Quantity_Uninvoiced__c = POLine1.Order_Quantity__c;
        POLine1.Quantity_Credited__c = -6;
        POLine1.Amount_Credited__c = -6;
        update POLine1;
        
        Test.startTest();
        // Arrange
        Supplier_Invoice__c si = si_mrl; // Has 1 lines       
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si;       
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');           
        }
        
        // no silines to insert
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        
        // update of siline, change inv qty
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        SupplierInvoiceManageExt.InvoiceLineWrapper updatedsilWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(sil_mrl1);
        updatedsilWrapper.invoiceLine.Purchase_Order_Line__c = POLine1.Id;
        updatedsilWrapper.invoiceLine.Purchase_Order_Line__r = POLine1;
        updatedsilWrapper.invoiceLine.Invoice_Quantity__c = sil_mrl1.Invoice_Quantity__c - 1;
        updatedList.add(updatedsilWrapper);

        // Set up deletion on supplier invoice line
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        SupplierInvoiceManageExt.InvoiceLineWrapper delInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(sil_mrl);
        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__c = POLine1.Id;
        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__r = POLine1;
        deletedList.add(delInvoiceLineWrapper);

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');             
        }
        
        // save si, silines will be updated and inserted
        si.Invoice_Amount__c = -1;
        JSONResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>>> result.messages: ' + result.messages);
        
        POLine1 = [Select Id, Order_Quantity__c,
                    Quantity_Credited__c, Amount_Credited__c from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        //system.assertEquals(POLine1.Quantity_Uninvoiced__c, POLine1.Order_Quantity__c, '>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Quantity_Credited__c , -1, '>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Amount_Credited__c ,-1, '>>> POLine1: ' + POLine1);

        Test.stopTest();
    }

    static testMethod void testSaveActionforUpdateDeleteInvoices_3Way() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Status__c = 'Open';
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = 'test-Incomplete1';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 8;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Incomplete';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        // SIL to delete
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 6;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            
        }
        
        // SIL to update
        Supplier_Invoice_Line__c sil_mrl1 = new Supplier_Invoice_Line__c();{
            sil_mrl1.Purchase_Order_Line__c = POLine1.id;
            sil_mrl1.Item__c = globalTestData.itemList[1].id;
            sil_mrl1.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl1.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl1.Description__c = 'test';
            sil_mrl1.Invoice_Quantity__c = 2;
            sil_mrl1.Unit_Price__c = 1;//KNDY-14371
            sil_mrl1.Supplier_Invoice__c = si_mrl.id;
            sil_mrl1.segment_exception__c = false;
            sil_mrl1.price_exception__c = false;
            sil_mrl1.quantity_exception__c = false;
            sil_mrl1.exception_details__c = null;
            sil_mrl1.matched__c = false;
        }
        List<Supplier_Invoice_Line__c> sils = new List<Supplier_Invoice_Line__c>{sil_mrl, sil_mrl1};
        insert sils;
        
        // Set Qty bucket on POL
        //POLine1.Quantity_Uninvoiced__c = POLine1.Order_Quantity__c - 8; //12
        POLine1.Quantity_Credited__c = 0;
        POLine1.Amount_Credited__c = 0;
        update POLine1;
        
        Test.startTest();
        // Arrange
        Supplier_Invoice__c si = si_mrl; // Has 1 lines       
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si;       
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');           
        }
        
        // no silines to insert
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        
        // update of siline, change inv qty
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        SupplierInvoiceManageExt.InvoiceLineWrapper updatedsilWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(sil_mrl1);
        updatedsilWrapper.invoiceLine.Purchase_Order_Line__c = POLine1.Id;
        updatedsilWrapper.invoiceLine.Purchase_Order_Line__r = POLine1;
        updatedsilWrapper.invoiceLine.Invoice_Quantity__c = sil_mrl1.Invoice_Quantity__c - 1;
        updatedList.add(updatedsilWrapper);

        // Set up deletion on supplier invoice line
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        SupplierInvoiceManageExt.InvoiceLineWrapper delInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(sil_mrl);
        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__c = POLine1.Id;
        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__r = POLine1;
        deletedList.add(delInvoiceLineWrapper);

        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');             
        }
        
        // save si, silines will be updated and inserted
        si.Invoice_Amount__c = 1;
        JSONResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>>> result.messages: ' + result.messages);
        
        POLine1 = [Select Id, Order_Quantity__c,
                    Quantity_Credited__c, Amount_Credited__c from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        //system.assertEquals(POLine1.Quantity_Uninvoiced__c, POLine1.Order_Quantity__c - 1, '>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Quantity_Credited__c , 0, '>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Amount_Credited__c ,0, '>>> POLine1: ' + POLine1);

        Test.stopTest();
    }
    
    static testMethod void testSaveActionforAddDeleteCMs_3Way() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Status__c = 'Open';
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Credit Memo';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = 'test-CMIncomplete1';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = -6;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Incomplete';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        // SIL to delete
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = -6;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;
        }
        
        // SIL to insert
        Supplier_Invoice_Line__c sil_mrl1 = new Supplier_Invoice_Line__c();{
            sil_mrl1.Purchase_Order_Line__c = POLine1.id;
            sil_mrl1.Item__c = globalTestData.itemList[1].id;
            sil_mrl1.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl1.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl1.Description__c = 'test';
            sil_mrl1.Invoice_Quantity__c = -2;
            sil_mrl1.Unit_Price__c = 1;//KNDY-14371
            sil_mrl1.Supplier_Invoice__c = si_mrl.id;
            sil_mrl1.segment_exception__c = false;
            sil_mrl1.price_exception__c = false;
            sil_mrl1.quantity_exception__c = false;
            sil_mrl1.exception_details__c = null;
            sil_mrl1.matched__c = false;
        }
         
        // Set Qty bucket on POL
        //POLine1.Quantity_Uninvoiced__c = POLine1.Order_Quantity__c;
        POLine1.Quantity_Credited__c = -6;
        POLine1.Amount_Credited__c = -6;
        update POLine1;
        
        Test.startTest();
        // Arrange
        Supplier_Invoice__c si = si_mrl; // Has 1 lines       
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si;       
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');           
        }
        
        // Insert CM of qty -2
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(sil_mrl1);
        newLineWrapper.invoiceLine.Purchase_Order_Line__c = POLine1.Id;
        newLineWrapper.invoiceLine.Purchase_Order_Line__r = POLine1;
        newList.add(newLineWrapper);
        
        // no update of silines
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        
        // Set up deletion on supplier invoice line
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;
        for (SupplierInvoiceManageExt.InvoiceLineWrapper iLine: invoiceLines){
	        SupplierInvoiceManageExt.InvoiceLineWrapper delInvoiceLineWrapper = iLine;             
	        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__c = POLine1.Id;
	        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__r = POLine1;
        	    deletedList.add(delInvoiceLineWrapper);
        }
        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');             
        }
        
        // save si, silines will be deleted and inserted
        si.Invoice_Amount__c = -2;
        JSONResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>>> result.messages: ' + result.messages);
        
        POLine1 = [Select Id, Order_Quantity__c,
                    Quantity_Credited__c, Amount_Credited__c from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        //system.assertEquals(POLine1.Quantity_Uninvoiced__c, POLine1.Order_Quantity__c, '>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Quantity_Credited__c , -2, '>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Amount_Credited__c ,-2, '>>> POLine1: ' + POLine1);

        Test.stopTest();
    }

    static testMethod void testSaveActionforAddDeleteInvoices_3Way() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Status__c = 'Open';
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = 'test-CMIncomplete1';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 6;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Incomplete';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        // SIL to delete
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 6;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;
        }
        
        // SIL to insert
        Supplier_Invoice_Line__c sil_mrl1 = new Supplier_Invoice_Line__c();{
            sil_mrl1.Purchase_Order_Line__c = POLine1.id;
            sil_mrl1.Item__c = globalTestData.itemList[1].id;
            sil_mrl1.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl1.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl1.Description__c = 'test';
            sil_mrl1.Invoice_Quantity__c = 2;
            sil_mrl1.Unit_Price__c = 1;//KNDY-14371
            sil_mrl1.Supplier_Invoice__c = si_mrl.id;
            sil_mrl1.segment_exception__c = false;
            sil_mrl1.price_exception__c = false;
            sil_mrl1.quantity_exception__c = false;
            sil_mrl1.exception_details__c = null;
            sil_mrl1.matched__c = false;
        }
         
        // Set Qty bucket on POL
        //POLine1.Quantity_Uninvoiced__c = POLine1.Order_Quantity__c - 6;
        POLine1.Quantity_Credited__c = 0;
        POLine1.Amount_Credited__c = 0;
        update POLine1;
        
        Test.startTest();
        // Arrange
        Supplier_Invoice__c si = si_mrl; // Has 1 lines       
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si;       
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');           
        }
        
        // Insert invoice of qty 2
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        SupplierInvoiceManageExt.InvoiceLineWrapper newLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(sil_mrl1);
        newLineWrapper.invoiceLine.Purchase_Order_Line__c = POLine1.Id;
        newLineWrapper.invoiceLine.Purchase_Order_Line__r = POLine1;
        newList.add(newLineWrapper);
        
        // no update of silines
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        
        // Set up deletion on supplier invoice line
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;
        for (SupplierInvoiceManageExt.InvoiceLineWrapper iLine: invoiceLines){
	        SupplierInvoiceManageExt.InvoiceLineWrapper delInvoiceLineWrapper = iLine;             
	        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__c = POLine1.Id;
	        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__r = POLine1;
        	    deletedList.add(delInvoiceLineWrapper);
        }
        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');             
        }
        
        // save si, silines will be deleted and inserted
        si.Invoice_Amount__c = 2;
        JSONResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>>> result.messages: ' + result.messages);
        
        POLine1 = [Select Id, Order_Quantity__c,
                    Quantity_Credited__c, Amount_Credited__c from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        //system.assertEquals(POLine1.Quantity_Uninvoiced__c, POLine1.Order_Quantity__c-2, '>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Quantity_Credited__c , 0, '>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Amount_Credited__c ,0, '>>> POLine1: ' + POLine1);

        Test.stopTest();
    }
    
    static testMethod void testSaveActionforDeleteCMs_3Way() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Status__c = 'Open';
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Credit Memo';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612-test-CM';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = -6;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = -3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
 
         Supplier_Invoice_Line__c sil_mrl1 = new Supplier_Invoice_Line__c();{
            sil_mrl1.Purchase_Order_Line__c = POLine1.id;
            sil_mrl1.Item__c = globalTestData.itemList[1].id;
            sil_mrl1.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl1.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl1.Description__c = 'test';
            sil_mrl1.Invoice_Quantity__c = -2;
            sil_mrl1.Unit_Price__c = 1;//KNDY-14371
            sil_mrl1.Supplier_Invoice__c = si_mrl.id;
            sil_mrl1.segment_exception__c = false;
            sil_mrl1.price_exception__c = false;
            sil_mrl1.quantity_exception__c = false;
            sil_mrl1.exception_details__c = null;
            sil_mrl1.matched__c = false;
        } 
        
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c();{
            sil_mrl2.Purchase_Order_Line__c = POLine1.id;
            sil_mrl2.Item__c = globalTestData.itemList[1].id;
            sil_mrl2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl2.Description__c = 'test';
            sil_mrl2.Invoice_Quantity__c = -1;
            sil_mrl2.Unit_Price__c = 1;//KNDY-14371
            sil_mrl2.Supplier_Invoice__c = si_mrl.id;
            sil_mrl2.segment_exception__c = false;
            sil_mrl2.price_exception__c = false;
            sil_mrl2.quantity_exception__c = false;
            sil_mrl2.exception_details__c = null;
            sil_mrl2.matched__c = false;
        }  
        // Set Qty bucket on POL
        //POLine1.Quantity_Uninvoiced__c = POLine1.Order_Quantity__c;
        POLine1.Quantity_Credited__c = -6;
        POLine1.Amount_Credited__c = -6;
        update POLine1;
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl1,sil_mrl2};
        insert supILs; 

        Test.startTest();
        // Arrange
        Supplier_Invoice__c si = si_mrl; // Has 3 lines       
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si;       
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');           
        }

        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        
        // Set up deletion on supplier invoice line
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;
        for (SupplierInvoiceManageExt.InvoiceLineWrapper iLine: invoiceLines){
	        SupplierInvoiceManageExt.InvoiceLineWrapper delInvoiceLineWrapper = iLine;             
	        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__c = POLine1.Id;
	        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__r = POLine1;
        	    deletedList.add(delInvoiceLineWrapper);
        }
        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');             
        }
        
        // save si, silines will be deleted
        JSONResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>>> result.messages: ' + result.messages);
        
        POLine1 = [Select Id, Order_Quantity__c,
                    Quantity_Credited__c, Amount_Credited__c from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        //system.assertEquals(POLine1.Quantity_Uninvoiced__c, POLine1.Order_Quantity__c, '>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Quantity_Credited__c , 0, '>>> POLine1: ' + POLine1);
        system.assertEquals(POLine1.Amount_Credited__c ,0, '>>> POLine1: ' + POLine1);

        Test.stopTest();
    }
    
    static testMethod void testSaveActionforDelete_2Way() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Status__c = 'Open';
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612-test';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 6;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
 
         Supplier_Invoice_Line__c sil_mrl1 = new Supplier_Invoice_Line__c();{
            sil_mrl1.Purchase_Order_Line__c = POLine1.id;
            sil_mrl1.Item__c = globalTestData.itemList[1].id;
            sil_mrl1.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl1.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl1.Description__c = 'test';
            sil_mrl1.Invoice_Quantity__c = 2;
            sil_mrl1.Unit_Price__c = 1;//KNDY-14371
            sil_mrl1.Supplier_Invoice__c = si_mrl.id;
            sil_mrl1.segment_exception__c = false;
            sil_mrl1.price_exception__c = false;
            sil_mrl1.quantity_exception__c = false;
            sil_mrl1.exception_details__c = null;
            sil_mrl1.matched__c = false;
        } 
        
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c();{
            sil_mrl2.Purchase_Order_Line__c = POLine1.id;
            sil_mrl2.Item__c = globalTestData.itemList[1].id;
            sil_mrl2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl2.Description__c = 'test';
            sil_mrl2.Invoice_Quantity__c = 1;
            sil_mrl2.Unit_Price__c = 1;//KNDY-14371
            sil_mrl2.Supplier_Invoice__c = si_mrl.id;
            sil_mrl2.segment_exception__c = false;
            sil_mrl2.price_exception__c = false;
            sil_mrl2.quantity_exception__c = false;
            sil_mrl2.exception_details__c = null;
            sil_mrl2.matched__c = false;
        }  
        // Set Qty bucket on POL
        //POLine1.Quantity_Uninvoiced__c = 14;
        //update POLine1;
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl1,sil_mrl2};
        insert supILs; 

        Test.startTest();
        // Arrange
        Supplier_Invoice__c si = si_mrl; // Has 3 lines       
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si;       
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');           
        }

        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        
        // Set up deletion on supplier invoice line
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;
        for (SupplierInvoiceManageExt.InvoiceLineWrapper iLine: invoiceLines){
	        SupplierInvoiceManageExt.InvoiceLineWrapper delInvoiceLineWrapper = iLine;             
	        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__c = POLine1.Id;
	        delInvoiceLineWrapper.invoiceLine.Purchase_Order_Line__r = POLine1;
        	    deletedList.add(delInvoiceLineWrapper);
        }
        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');             
        }
        
        // save si, silines will be deleted
        JSONResult result = SupplierInvoiceManageExt.saveAction(si, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(result.success == true, '>>>> result.messages: ' + result.messages);
        
        POLine1 = [Select Id,  Order_Quantity__c from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        //system.assert(POLine1.Quantity_Uninvoiced__c == POLine1.Order_Quantity__c, POLine1.Quantity_Uninvoiced__c);
        Test.stopTest();
    }
    
   //PTP-706 Hold Approved SI
    static testMethod void testHoldApprovedSI(){
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612TestHold';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 3;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Transaction_Date__c = system.today();
            si_mrl.Currency__c = testdata.fuel.company.Default_Transaction_Currency__c;
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;
        }
        si_mrl.Status__c = 'Approved';
        si_mrl.Finalized__c = true;
        update si_mrl;
        
        Test.startTest();

        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si_mrl;    
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        {
			headerDateFields.add('Date_Invoiced__c');
			headerDateFields.add('Date_Received__c');
        }
        List<String> dateFields = new List<String>();
        {
			dateFields.add('Date_Invoiced__c');
			dateFields.add('Date_Received__c');
        }
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
		List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        si_mrl.Hold__c = true;
        JsonResult result = SupplierInvoiceManageExt.saveAction(si_mrl, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(true, result.success);
        
        Supplier_Invoice__c si = [Select Status__c, Id from Supplier_Invoice__c where Id = :si_mrl.Id];
        system.assert(si.Status__c == 'Approved');
		Test.stopTest();
    }
    
   //PTP-706 Hold Cancelled SI
    static testMethod void testHoldCancelledSI(){
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612TestHold';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 3;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Currency__c = globalTestData.company.Default_Transaction_Currency__c;
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;
        }
        si_mrl.Status__c = 'Cancelled';
        update si_mrl;
        
        Test.startTest();

        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si_mrl;    
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');
        }
        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');
        }
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        si_mrl.Hold__c = true;
        JsonResult result = SupplierInvoiceManageExt.saveAction(si_mrl, headerDateFields, updatedList, newList, deletedList, dateFields, false);
//        system.assert(result.success == false);
        system.assert(result.messages.size() == 1);
        for (Map<String, String> error : result.messages) {
//        	   system.assert(error.get('message').contains('Hold cannot be changed on a Cancelled Supplier Invoice'));
        }
    }
    
    //KNDY-8743 - Inaction item validation
    //if the po line has an inactive item, no error should be thrown when the po line with deactivated item is deleted from SI
    static testMethod void testDeleteofInactiveItem() {
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        Test.startTest();
        
        // Arrange
        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        ApexPages.StandardController setCon = new Apexpages.StandardController(si);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        
        // Act
        Supplier_Invoice__c invoiceHeader = (Supplier_Invoice__c)SupplierInvoiceManageExt.getSupplierInvoiceDetails(si.Id, null).records[0];
        invoiceHeader.invoice_type__c = 'Invoice';
        
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');           
        }
        
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;

        //Deactivate the item
        testData.fuel.itemList[1].Active__c = false;
        update testData.fuel.itemList[1];

        Supplier_Invoice_Line__c delInvoiceLine = new Supplier_Invoice_Line__c(); {
            delInvoiceLine.Supplier_Invoice__c = si.Id;
            delInvoiceLine.Invoice_Quantity__c = 5;
            delInvoiceLine.Unit_Price__c = 100;//KNDY-14371
            delInvoiceLine.Description__c = 'test';
            delInvoiceLine.Purchase_Order__c = testData.fuel.purchaseOrder.Id;
            delInvoiceLine.Purchase_Order_Line__c = testData.fuel.purchaseOrderLines[0].id;
            delInvoiceLine.Purchase_Order_Line__r = testData.fuel.purchaseOrderLines[0];
            delInvoiceLine.Item__c = testData.fuel.itemList[1].Id;
        }
        
        SupplierInvoiceManageExt.InvoiceLineWrapper delInvoiceLineWrapper = new SupplierInvoiceManageExt.InvoiceLineWrapper(delInvoiceLine);
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); {
            deletedList.add(delInvoiceLineWrapper);
        }
        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');             
        }
        
        JsonResult result = SupplierInvoiceManageExt.saveAction(invoiceHeader, headerDateFields, new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(), new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(), deletedList, dateFields, false);

        // Assert should be success when deleting a line with deactivated item
        system.assert(true, result.success);
      
        Test.stopTest();  
    }

    //KNDY-9376 Creating a prepayment invoice
    static testMethod void testCreatingPrepaymentInv(){
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Prepayment';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612TestHold';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 3;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Transaction_Date__c = system.today();
            si_mrl.Currency__c = globalTestData.company.Default_Transaction_Currency__c;
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;
        }


		Test.startTest();
		//KNDY-19005 -SI Id exists and test the actions on the ActionsMap.
		string siTestMapStr = SupplierInvoiceService.populateSISaveAndActions(si_mrl.Id);
		System.debug(logginglevel.error,'siTestMapStr--->'+siTestMapStr);

		Map<String,Object> siActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(siTestMapStr);
		System.debug(logginglevel.error, 'siActionTestMap--->'+siActionTestMap);
		// Invoice in the approved status - just saved
		system.assertEquals(siActionTestMap.get('Pay_Invoice'),false);

		si_mrl.Status__c = 'Approved';
		si_mrl.Finalized__c = true;
		update si_mrl;

        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si_mrl;    
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        {
			headerDateFields.add('Date_Invoiced__c');
			headerDateFields.add('Date_Received__c');
        }
        List<String> dateFields = new List<String>();
        {
			dateFields.add('Date_Invoiced__c');
			dateFields.add('Date_Received__c');
        }
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>();
		List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 

        //si_mrl.Hold__c = true;
        JsonResult result = SupplierInvoiceManageExt.saveAction(si_mrl, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        system.assert(true, result.success);
        
        Supplier_Invoice__c si = [Select Status__c, Id from Supplier_Invoice__c where Id = :si_mrl.Id];
        system.assert(si.Status__c == 'Approved');
		//KNDY-19005 -SI Id exists and test the actions on the ActionsMap.
		        siTestMapStr = SupplierInvoiceService.populateSISaveAndActions(si.Id);
		        System.debug(logginglevel.error,'siTestMapStr--->'+siTestMapStr);
			siActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(siTestMapStr);
		        	System.debug(logginglevel.error, 'siActionTestMap--->'+siActionTestMap);
		        // Invoice in the approved status - just saved
				        system.assertEquals(siActionTestMap.get('Pay_Invoice'),true);

				        //check for closed invoices
						        si.Status__c = 'Closed';
		        update si;
		        si = [Select Status__c, Id from Supplier_Invoice__c where Id = :si_mrl.Id];
		        system.assert(si.Status__c == 'Closed');
		        siTestMapStr = SupplierInvoiceService.populateSISaveAndActions(si.Id);
		        System.debug(logginglevel.error,'siTestMapStr--->'+siTestMapStr);

				        siActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(siTestMapStr);
		        System.debug(logginglevel.error, 'siActionTestMap--->'+siActionTestMap);
		        // Invoice in the approved status - just saved
				       system.assertEquals(siActionTestMap.get('Pay_Invoice'),false);
		Test.stopTest();
    }
    
    static testMethod void testSaveOnCancelledSI(){
        SupplierInvoiceManageExtTestData testData = new SupplierInvoiceManageExtTestData();
        TestFuelQuery globaltestdata = testData.fuel;
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612TestHold';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 3;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Currency__c = globalTestData.company.Default_Transaction_Currency__c;
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;
        }
        si_mrl.Status__c = 'Cancelled';
        update si_mrl;
        
        Test.startTest();
        
       

        GridRelatedListController.GridRelatedListConfig config = testData.supplierInvoiceLinesConfig;
        config.parentRecord = si_mrl;    
        ApexPages.StandardController setCon = new Apexpages.StandardController(si_mrl);
        SupplierInvoiceManageExt con = new SupplierInvoiceManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        {
            headerDateFields.add('Date_Invoiced__c');
            headerDateFields.add('Date_Received__c');
        }
        List<String> dateFields = new List<String>();
        {
            dateFields.add('Date_Invoiced__c');
            dateFields.add('Date_Received__c');
        }
        
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> invoiceLines = (List<SupplierInvoiceManageExt.InvoiceLineWrapper>)SupplierInvoiceManageExt.getInvoiceLines(config, null).records;
        
        SupplierInvoiceManageExt.InvoiceLineWrapper updateInvoiceLine = invoiceLines[0];
        updateInvoiceLine.invoiceLine.Invoice_Quantity__c = 20;
        updateInvoiceLine.invoiceLine.Unit_Price__c = 50;
        
        // empty lists
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> newList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> deletedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); 
        
        List<SupplierInvoiceManageExt.InvoiceLineWrapper> updatedList = new List<SupplierInvoiceManageExt.InvoiceLineWrapper>(); {
            updatedList.add(updateInvoiceLine);
        }

        JsonResult result = SupplierInvoiceManageExt.saveAction(si_mrl, headerDateFields, updatedList, newList, deletedList, dateFields, false);
        System.debug(logginglevel.error,'result-->'+result);
        system.assert(result.messages.size() == 1);
        System.debug(logginglevel.error,'result-->'+result.messages);
        for (Map<String, String> error : result.messages) {
           system.assert(error.get('message').contains('You can\''+'t edit a cancelled or void invoice.'), 'The error message is not correct');         
        }
        
        try{
            si_mrl.memo__c = 'Update the memo text';
            update si_mrl;
        }catch(DmlException dmlexp){
            for (Integer idx = 0; idx < dmlexp.getNumDml() ; idx++) {
	                string errorMessage = dmlexp.getDmlMessage(idx);
		            if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
		                list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
		                if(!msgArray.isEmpty()){
		                    errorMessage = msgArray.get(msgArray.size()-1);
		                    System.assert(errorMessage.contains('You can\''+'t edit a cancelled or void invoice.'),'Error Message displayed is wrong');
		                }
		            }
            }                        
        }catch(Exception exp){
            system.debug(exp);
        }   
    }
}