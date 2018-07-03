/**
 * test the accounting generate page/controller 
 */
@isTest
private class AccountingEntryGenerateTest  {/*
    
 	public static testMethod void GenerateTest() {
	    TestDataForFinance data = new TestDataForFinance();
	    Shipment__c shipment1 = new Shipment__c();
	    shipment1.Company__c = data.company.id;
	    shipment1.Date_Shipped__c = system.now();
	    shipment1.Currency__c = TestFuel.currencyUSD.id;
	    shipment1.Status__c ='Confirmed';
	    insert shipment1; 
	    
	    List<Shipment_Line__c> shipLineList1 = new List<Shipment_Line__c>();
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
	    shipLine1.Taxable__c = data.SalesOrderLineList[0].Taxable__c;
	    shipLineList1.add(shipLine1);
	    
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
	    shipLine2.Taxable__c = data.SalesOrderLineList[1].Taxable__c;
	    shipLineList1.add(shipLine2);
	    insert shipLineList1;
	    
	    shipment1.Finalized__c = true;
	    update shipment1;
	    
	    Test.startTest();
		Test.setCurrentPage( Page.AccountingEntryGenerate);
		Apexpages.currentPage().getParameters().put('id', shipment1.id );
		AccountingEntryGenerateCon con = new AccountingEntryGenerateCon();
		con.previewAE();
		
		system.assert( Apexpages.hasMessages() == false , Apexpages.getMessages() );
		//system.debug( Logginglevel.info, con.lines );
		
		system.assert(con.renderReview, 'The page should be displaying the review section data');
     /*Commenting as part of KNDY-6885 */
	//	system.assert(!con.manyLines, 'This is a small volume of lines');
/*		List<Accounting_Entry__c> ae = [SELECT Id FROM Accounting_Entry__c WHERE shipment__c = :shipment1.id];
		system.assertNotEquals(0, ae.size(), 'We are expecting an AE synchronously');
				
		system.assert( con.close() != null );
		
		// test if the Finalized flag is set, we expect an error
		
		// test where bad object is passed 
		Apexpages.currentPage().getParameters().put('id', data.company.id );
		con = new AccountingEntryGenerateCon(); 
		con.previewAE(); 
	}
	
	/*
	TODO: This test will be broken while the generate page is under construction 
	public static testMethod void PreviewTestFail() {
        JournalEntryAccountingTest.JournalEntries JE = new JournalEntryAccountingTest.JournalEntries();
        UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{JE.JEList[0]});
        Test.setCurrentPage( Page.AccountingEntryGenerate);
        Apexpages.currentPage().getParameters().put('id', JE.JEList[0].id );
	    Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{JE.JEList[0]});        
		AccountingEntryGenerateCon con = new AccountingEntryGenerateCon();
        con.previewAE();
		system.assert( Apexpages.hasMessages() == true, ' expected error msg');		
	}
	*/
    /*Commenting as part of KNDY-6885 
	public static testMethod void testFutureCall()
    {
        JournalEntryAccountingTest.JournalEntries JE = new JournalEntryAccountingTest.JournalEntries();
	    Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{JE.JEList[0]});
	    system.assertEquals(true, mResponses.get(JE.JEList[0].Id).Success, 'We are expecting a successful unfinalize');
        Test.startTest();
	    List<Journal_Entry_Line__c> JELs = new List<Journal_Entry_Line__c>{JE.jeLineList[0], JE.jeLineList[1]};

	    List<Journal_Entry_Line__c> newJELsSet1 = new List<Journal_Entry_Line__c>();
	    for(integer i=0; i<=26; i++){
	    	newJELsSet1.addAll(JELs.deepclone());
	    }
	    system.assert(newJELsSet1.size() > 50);
	    insert newJELsSet1;//52 Lines Invokes future
	    JE.JEList[0].finalized__c = true;
	    update JE.JEList[0];  
        
	    Test.setCurrentPage( Page.AccountingEntryGenerate);
		Apexpages.currentPage().getParameters().put('id', JE.JEList[0].Id );
		AccountingEntryGenerateCon con = new AccountingEntryGenerateCon();
        datetime lddt = con.loadDt;
		con.previewAE();
		
		system.assert(con.manyLines, 'This should have a "large line volume"');
		system.assert(!con.renderReview, 'We are not ready to show the generated lines');
		
		List<Accounting_Entry__c> ae = [SELECT Id FROM Accounting_Entry__c WHERE Journal_Entry__c = :JE.JEList[0].Id];
		system.assertEquals(0, ae.size(), 'We are expecting that the AE is deferred to the @future');
	    Test.stopTest();

	    con.refresh();
	    system.assert(!con.manyLines, 'This should have a "large line volume" turned off');
		system.assert(con.renderReview, 'We are now ready to show the generated lines');
		
		ae = [SELECT Id FROM Accounting_Entry__c WHERE Journal_Entry__c = :JE.JEList[0].Id  ORDER BY CreatedDate desc LIMIT 1];
		system.assertNotEquals(0, ae.size(), 'We are expecting an AE from the @future');
		
		system.assertEquals(ae[0].Id, con.record.Id, 'We should see the AE match between the @future return and the controller');

    }*/
    /*Commenting as part of KNDY-6885 
	public static testMethod void largeVolume(){
		JournalEntryAccountingTest.JournalEntries JE = new JournalEntryAccountingTest.JournalEntries();
	    Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{JE.JEList[0]});
	    system.assertEquals(true, mResponses.get(JE.JEList[0].Id).Success, 'We are expecting a successful unfinalize');
        Test.startTest();
	    List<Journal_Entry_Line__c> JELs = new List<Journal_Entry_Line__c>{JE.jeLineList[0], JE.jeLineList[1]};

	    List<Journal_Entry_Line__c> newJELsSet = new List<Journal_Entry_Line__c>();
	    for(integer i=0; i<=101; i++){
	    	newJELsSet.addAll(JELs.deepclone());
	    }
	    system.assert(newJELsSet.size() > 200);
	    insert newJELsSet;//202 Lines Invokes Batch
	    JE.JEList[0].finalized__c = true;
	    update JE.JEList[0];  
        
	    Test.setCurrentPage( Page.AccountingEntryGenerate);
		Apexpages.currentPage().getParameters().put('id', JE.JEList[0].Id );
		AccountingEntryGenerateCon con = new AccountingEntryGenerateCon();
        datetime lddt = con.loadDt;
		con.previewAE();
		
		system.assert(con.toomanyLines, 'This should have a "large line volume"');
		system.assert(!con.renderReview, 'We are not ready to show the generated lines');
		
		List<Accounting_Entry__c> ae = [SELECT Id FROM Accounting_Entry__c WHERE Journal_Entry__c = :JE.JEList[0].Id and status__c != 'Draft'];
		system.assertEquals(0, ae.size(), 'We are expecting that the AE is generated from Batch');
	    Test.stopTest();

	    con.refresh();
	    system.assert(!con.toomanyLines, 'This should have a "large line volume" turned off');
		system.assert(con.renderReview, 'We are now ready to show the generated lines');
		
		ae = [SELECT Id FROM Accounting_Entry__c WHERE Journal_Entry__c = :JE.JEList[0].Id  ORDER BY CreatedDate desc LIMIT 1];
		system.assertNotEquals(0, ae.size(), 'We are expecting an AE from the Batch');
		
		system.assertEquals(ae[0].Id, con.record.Id, 'We should see the AE match between the batch return and the controller');
         
	}*/
}