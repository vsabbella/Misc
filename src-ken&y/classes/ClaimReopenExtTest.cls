@isTest
private class ClaimReopenExtTest {
	@testSetup static void ts() {
		TestFuel data = new TestFuel();
		// these asserts cause TestFuel to insert data
		system.assert(
				data.company != null &&
						data.bankAccount != null &&
						data.customerParent != null &&
						data.customerSoldTo != null &&
						data.customerBillTo != null &&
						data.product != null &&
						data.periodList != null &&
						data.salesOrder != null &&
						data.salesOrderLines != null &&
						data.resolutionCode != null
		);

		//Sample AR Data
		Customer_Invoice__c custInvoice = new Customer_Invoice__c();
		custInvoice.Company__c = data.company.Id;
		custInvoice.Customer__c = data.customerParent.Id;
		custInvoice.Bill_To_Customer__c = data.customerbillto.Id;
		custInvoice.Currency__c = data.company.Default_Transaction_Currency__c;
		custInvoice.date_invoiced__c = system.now();
		custInvoice.transaction_date__c = system.now();
		custInvoice.Invoice_Type__c = 'Ship Invoice';
		custInvoice.Status__c = 'Open';
		custInvoice.Sales_Order__c = data.salesOrder.Id;
		custInvoice.historical__c = false;
		insert custInvoice;

		Customer_Invoice_Line__c custInvoiceLine = new Customer_Invoice_Line__c();
		custInvoiceLine.Customer_Invoice__c = custInvoice.Id;
		custInvoiceLine.Product__c = data.product.Id;
		custInvoiceLine.Quantity_Shipped__c = 10;
		custInvoiceLine.Unit_Price__c = 10;
		custInvoiceLine.Extended_Price__c = 100;
		insert custInvoiceLine;

		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = data.company.Id;
		custReceipt.Type__c = CustomerReceiptService.TYPE_RECEIPT;
		custReceipt.Customer__c = data.customerbillto.Id;
		custReceipt.Date_Received__c = system.today();
		custReceipt.transaction_date__c = system.now();
		custReceipt.Currency__c = data.company.Default_Transaction_Currency__c;
		custReceipt.historical__c = false;
		insert custReceipt;

		Reason_Code__c deductionCode = new Reason_Code__c();
		deductionCode.Type__c = 'Deductions';
		deductionCode.Code__c = 'D001';
		insert deductionCode;

		List<Customer_Receipt_Line__c> pmtLines = new List<Customer_Receipt_Line__c>();
		Customer_Receipt_Line__c pmtCash = new Customer_Receipt_Line__c();
		pmtCash.Amount__c = 90;
		pmtCash.Type__c = 'Payment';
		pmtCash.Customer_Invoice__c = custInvoice.Id;
		pmtCash.Customer_Receipt__c = custReceipt.Id;
		pmtLines.add(pmtCash);

		Customer_Receipt_Line__c pmtInvDed = new Customer_Receipt_Line__c();
		pmtInvDed.Amount__c = 10;
		pmtInvDed.Type__c = 'Invoice Deduction';
		pmtInvDed.Reason_Code__c = deductionCode.Id;
		pmtInvDed.Customer_Invoice__c = custInvoice.Id;
		pmtInvDed.Customer_Receipt__c = custReceipt.Id;
		pmtInvDed.Reference__c = 'Some reference';
		pmtInvDed.Notes__c = 'Some Notes';
		pmtLines.add(pmtInvDed);


		Customer_Receipt_Line__c genDeduction = new Customer_Receipt_Line__c();//s
		genDeduction.Amount__c = 90;
		genDeduction.Type__c = PaymentService.TYPE_GEN_DED;
		genDeduction.Reason_Code__c = deductionCode.Id;
		genDeduction.Customer_Receipt__c = custReceipt.Id;
		pmtLines.add(genDeduction);

		insert pmtLines;

		Reason_Code__c resolution = new Reason_Code__c();
		resolution.name = 'Unsaleables';
		resolution.type__c = 'Resolution';
		insert resolution;

		custReceipt.finalized__c = true;
		custReceipt.Amount_Unapplied__c = 0;
		update custReceipt;
	}

	static testMethod void testReopenWithClosedRelatedClaims() {


		Claim__c c = [SELECT Id, status__c,Amount__c FROM Claim__c limit 1];
		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		c.Resolution_Code__c = resolution.Id;
		c.Ready__c = true;
		update c;

		insert new Claim_Line__c(Claim__c = c.Id, Resolution_Code__c = resolution.Id, Total_Amount__c = 1);

		ClaimService.resolve(new set<ID>{
				c.Id
		});
		test.startTest();
		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c, Ready__c, (Select id from Related_Claims__r) FROM Claim__c WHERE Id = :c.Id];
		c.Related_Claims__r[0].Resolution_Code__c = resolution.Id;
		update c.Related_Claims__r[0];

		ClaimService.resolve(new set<ID>{
				c.Related_Claims__r[0].Id
		});


		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c FROM Claim__c WHERE Id = :c.Id];
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimReopenExt reopenext = new ClaimReopenExt(con);
		try {
			reopenext.reopen();
		} catch (Exception ex) {
			system.assert(ex.getMessage().contains(Label.Claim_cannot_be_reversed_because_it_has_related_claim_that_is_closed));
		}

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c, Ready__c, (Select id from Related_Claims__r) FROM Claim__c WHERE Id = :c.Id];

		system.assertEquals(c.Status__c, ClaimService.STATUS_CLOSED, 'The claim should be closed after the resolution - ' + Apexpages.getMessages());

		Customer_Invoice__c ci = [SELECT Id, Status__c FROM Customer_Invoice__c WHERE claim__c = :c.Id];
		system.assertEquals(ci.Status__c, CustomerInvoiceService.STATUS_CLOSED, 'The settlement customer invoice should be cancelled');
		system.debug(logginglevel.INFO, 'QUERIES: ' + Limits.getQueries());
		test.stopTest();
	}

	static testMethod void testReopenWithOpenRelatedClaims() {

		Claim__c c = [SELECT Id, status__c,Amount__c FROM Claim__c limit 1];
		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		c.Resolution_Code__c = resolution.Id;
		c.Ready__c = true;
		update c;

		insert new Claim_Line__c(Claim__c = c.Id, Resolution_Code__c = resolution.Id, Total_Amount__c = 1);

		ClaimService.resolve(new set<ID>{
				c.Id
		});
		test.startTest();
		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c FROM Claim__c WHERE Id = :c.Id];
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimReopenExt reopenext = new ClaimReopenExt(con);
		reopenext.reopen();

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c, Ready__c, (Select id from Related_Claims__r) FROM Claim__c WHERE Id = :c.Id];

		system.assertEquals(c.Status__c, ClaimService.STATUS_OPEN, 'The claim should be closed after the resolution - ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Method__c, null, 'The claims should not reflect a settlement method ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Date__c, null, 'The claim should not reflect today as the settlement date - ' + Apexpages.getMessages());
		system.assertEquals(c.Ready__c, false, 'The claim ready checkbox should be false - ' + Apexpages.getMessages()); //OTC-680
		system.assertEquals(c.Related_Claims__r.size(), 0);

		Customer_Invoice__c ci = [SELECT Id, Status__c FROM Customer_Invoice__c WHERE claim__c = :c.Id];
		system.assertEquals(ci.Status__c, CustomerInvoiceService.STATUS_CANCEL, 'The settlement customer invoice should be cancelled');
		system.debug(logginglevel.INFO, 'QUERIES: ' + Limits.getQueries());
		test.stopTest();
	}

	static testMethod void testReopenManualSourceClaim() {

		//ClaimsData cd = new ClaimsData();
		Claim__c c = [SELECT Id, status__c,Amount__c FROM Claim__c limit 1];
		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		c.Resolution_Code__c = resolution.Id;
		c.Settlement_Method__c = 'Refund';
		c.Ready__c = true;
		update c;

		test.startTest();
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimReopenExt reopenext = new ClaimReopenExt(con);
		try {
			reopenext.reopen();
		} catch (Exception ex) {
			system.assert(ex.getMessage().contains(Label.You_can_t_reopen_a_claim_with_a_refund_settlement_method));
		}

		test.stopTest();
	}

	static testMethod void testExtension() {


		//ClaimsData cd = new ClaimsData();
		Claim__c c = [SELECT Id, status__c,Amount__c FROM Claim__c limit 1];
		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		c.Resolution_Code__c = resolution.Id;
		c.Ready__c = true;
		update c;

		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimResolveExt resolveext = new ClaimResolveExt(con);

		test.startTest();
		resolveext.resolve();

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c FROM Claim__c WHERE Id = :c.Id];

		system.assertEquals(c.Status__c, ClaimService.STATUS_CLOSED, 'The claim should be closed after the resolution - ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Method__c, ClaimService.SETTLE_MANUAL, 'The claims should reflect a manual - ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Date__c, system.today(), 'The claim should reflect today as the settlement date - ' + Apexpages.getMessages());

		Customer_Invoice__c ci = [SELECT Id FROM Customer_Invoice__c WHERE claim__c = :c.Id];
		system.assertNotEquals(ci, null, 'The settlement customer invoice should be created and related to the claim');
		system.debug(logginglevel.INFO, 'QUERIES: ' + Limits.getQueries());

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c FROM Claim__c WHERE Id = :c.Id];
		con = new Apexpages.Standardcontroller(c);
		ClaimReopenExt reopenext = new ClaimReopenExt(con);
		reopenext.reopen();

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c, Ready__c FROM Claim__c WHERE Id = :c.Id];

		system.assertEquals(c.Status__c, ClaimService.STATUS_OPEN, 'The claim should be closed after the resolution - ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Method__c, null, 'The claims should not reflect a settlement method ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Date__c, null, 'The claim should not reflect today as the settlement date - ' + Apexpages.getMessages());
		system.assertEquals(c.Ready__c, false, 'The claim ready checkbox should be false - ' + Apexpages.getMessages()); //OTC-680

		ci = [SELECT Id, Status__c FROM Customer_Invoice__c WHERE claim__c = :c.Id];
		system.assertEquals(ci.Status__c, CustomerInvoiceService.STATUS_CANCEL, 'The settlement customer invoice should be cancelled');
		system.debug(logginglevel.INFO, 'QUERIES: ' + Limits.getQueries());

		test.stopTest();
	}

	//Below method added to test KNDY-9825 [Prevent claim from closing without settlement method ]
	static testMethod void testClaimNotGettingClosedWOSettlementMethod() {

		TestFuelQuery fuel = new TestFuelQuery();
		boolean IsUpdateFailed = false;
		Claim__c claim = new Claim__c();
		claim.Company__c = fuel.company.Id;
		claim.Parent_Customer__c = fuel.customerParent.Id;
		claim.Bill_To_Customer__c = fuel.customerBillTo.Id;
		claim.Sold_To_Customer__c = fuel.customerSoldTo.Id;
		claim.Currency__c = fuel.company.Default_Transaction_Currency__c;
		claim.Amount__c = 20;
		claim.Type__c = PaymentService.TYPE_GEN_DED;
		claim.Status__c = 'Open';
		claim.Claim_Date__c = Date.today();
		insert claim;
		Test.startTest();
		//Updating Status to closed without populating settlement method
		claim.Status__c = 'Closed';
		try{
			update claim;
		}catch(Exception ex) {
			IsUpdateFailed = true;
			system.debug(logginglevel.INFO, 'Exception: ' + ex.getMessage());
			system.assert(ex.getMessage().contains('Please populate settlement method while closing claims.'));
		}
		system.assertEquals(true, IsUpdateFailed);
		Test.stopTest();
	}
	//Below method added to test KNDY-9825 [Prevent claim from closing without settlement method ]
	static testMethod void testClaimGettingClosedWithSettlementMethod() {

		TestFuelQuery fuel = new TestFuelQuery();
		Claim__c claim = new Claim__c();
		claim.Company__c = fuel.company.Id;
		claim.Parent_Customer__c = fuel.customerParent.Id;
		claim.Bill_To_Customer__c = fuel.customerBillTo.Id;
		claim.Sold_To_Customer__c = fuel.customerSoldTo.Id;
		claim.Currency__c = fuel.company.Default_Transaction_Currency__c;
		claim.Amount__c = 20;
		claim.Type__c = PaymentService.TYPE_GEN_DED;
		claim.Status__c = 'Open';
		claim.Claim_Date__c = Date.today();
		insert claim;
		Test.startTest();
		//Updating Status to closed and populating settlement method
		claim.Status__c = 'Closed';
		claim.Settlement_Method__c = 'Adjustment';
		try{
			update claim;
		}catch(Exception ex) {
			system.assertEquals(null,ex.getMessage());
		}
		Claim__c queriedClaim = [Select Id,Status__c from Claim__c where Id = :claim.Id];
		system.assertEquals('Closed', queriedClaim.Status__c);
		Test.stopTest();
	}

	static testMethod void testReopenManualRejectedClaim() { //KNDY-15531
		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		TestFuelQuery fuel = new TestFuelQuery();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		Claim__c claim = new Claim__c();
		claim.Company__c = fuel.company.Id;
		claim.Parent_Customer__c = fuel.customerParent.Id;
		claim.Bill_To_Customer__c = fuel.customerBillTo.Id;
		claim.Sold_To_Customer__c = fuel.customerSoldTo.Id;
		claim.Currency__c = fuel.company.Default_Transaction_Currency__c;
		claim.Amount__c = 20;
		claim.Type__c = ClaimService.SOURCE_MANUAL;
		claim.Source__c = ClaimService.SOURCE_MANUAL;
		claim.Resolution_Code__c = resolution.Id;
		claim.Status__c = 'Open';
		claim.Claim_Date__c = Date.today();
		claim.Enter_Claims_Notes__c = 'Test memo 1';
		insert claim;

		ClaimService.reject(new List<Claim__c>{claim});

		Claim__c  c =[Select Id, Enter_Claims_Notes__c, Settlement_Method__c, Status__c, Amount__c,Resolution_Code__c, Related_Claim__c, (select Id, Name, Resolution_Code__c, Reason_Code__c, Total_Amount__c from Claim_Lines__r)
		from Claim__c
		where Id = :claim.Id
		];
		system.assertEquals(c.Status__c, ClaimService.STATUS_CLOSED, c);
		system.assertEquals(c.Settlement_Method__c, ClaimService.SETTLEMENT_METHOD_REJECTED, c);
		system.assertEquals(c.Enter_Claims_Notes__c, 'Test memo 1', c);
		system.assertEquals(c.Resolution_Code__c, resolution.Id, c);
		system.assertEquals(c.Claim_Lines__r.size(), 1);

		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimReopenExt reopenext = new ClaimReopenExt(con);
		reopenext.reopen();

		claim = [
				Select Id, Resolution_Code__c, Enter_Claims_Notes__c, Settlement_Method__c, Settlement_Date__c, Status__c, (select Id, Name, Resolution_Code__c, Reason_Code__c, Total_Amount__c from Claim_Lines__r)
				from Claim__c
				where Id = :claim.Id
				limit 1
		];
		system.assertEquals(claim.Status__c, ClaimService.STATUS_OPEN, claim);
		system.assertEquals(claim.Settlement_Method__c, null, claim);
		system.assertEquals(claim.Resolution_Code__c, null, claim);
		system.assertEquals(claim.Claim_Lines__r.size(), 0);
		system.assertEquals(claim.Enter_Claims_Notes__c, 'Test memo 1', claim);
	}

	static testMethod void test_AssertFail_Credit() {

		Test.startTest();
		//ClaimsData cd = new ClaimsData();
		Claim__c c = [SELECT Id, status__c FROM Claim__c limit 1];
		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		c.Resolution_Code__c = resolution.Id;
		c.Manage__c = 'Credit';
		update c;
		//ClaimService.createClaimLines(new set<Id>{c.Id});
		//List<Claim_Line__c> claimLines = [SELECT Id, unit_amount__c, quantity__c FROM Claim_Line__c WHERE Claim__c = :c.Id];

		//for(Claim_Line__c cl : claimLines){
		//	cl.Quantity__c = -1;
		//	cl.Unit_Amount__c = 5;
		//}

		//update claimLines;

		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimResolveExt ext = new ClaimResolveExt(con);

		ext.resolve();
		system.assertEquals(ext.disableAction, true, 'The claim should fail validation - ' + Apexpages.getMessages());
		Test.stopTest();
	}


	static testMethod void test_Fail_NullAmount() { //OTC-661

		Test.startTest();
		Claim__c c = new Claim__c(Amount__c = null, Status__c = 'New', Source__c = 'Manual');
		insert c;

		Claim_Line__c cl = new Claim_Line__C(Claim__c = c.Id);
		insert cl;

		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimResolveExt ext = new ClaimResolveExt(con);

		ext.resolve();
		system.assertEquals(ext.disableAction, true, 'The claim should fail validation - ' + Apexpages.getMessages());
		Test.stopTest();
	}
	static testMethod void test_AssertFail_NUllClaimLineCode() {

		Test.startTest();
		Claim__c c = [SELECT Id, status__c FROM Claim__c limit 1];
		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		c.Resolution_Code__c = resolution.Id;
		update c;

		Claim_Line__c cl = new Claim_Line__C(Claim__c = c.Id);
		insert cl;
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimResolveExt ext = new ClaimResolveExt(con);

		ext.resolve();
		system.assertEquals(ext.disableAction, true, 'The claim should fail validation - ' + Apexpages.getMessages());
		Test.stopTest();
	}

	static testMethod void test_AssertFail_NonMatchingCodes() {

		Test.startTest();
		//ClaimsData cd = new ClaimsData();
		Claim__c c = [SELECT Id, status__c FROM Claim__c limit 1];
		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		c.Resolution_Code__c = resolution.Id;
		update c;

		Claim_Line__c cl = new Claim_Line__C(Claim__c = c.Id, Resolution_Code__c = resolution.ID);
		insert cl;

		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimResolveExt ext = new ClaimResolveExt(con);

		ext.resolve();
		system.assertEquals(ext.disableAction, true, 'The claim should fail validation - ' + Apexpages.getMessages());
		Test.stopTest();
	}
	static testMethod void test_AssertFail_ManageLines() {

		Test.startTest();
		//ClaimsData cd = new ClaimsData();
		Claim__c c = [SELECT Id, status__c FROM Claim__c limit 1];
		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		c.Resolution_Code__c = resolution.Id;
		update c;

		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimResolveExt ext = new ClaimResolveExt(con);
		PageReference ref = ext.manageLines();
		system.assertNOTEquals(ref, null, 'The claim should navigate to ClaimLinesManage page - ' + Apexpages.getMessages());
	}

	static testMethod void testExtension1() {


		//ClaimsData cd = new ClaimsData();
		Test.startTest();
		Claim__c c = [SELECT Id, status__c,Amount__c FROM Claim__c limit 1];

		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		c.Resolution_Code__c = resolution.Id;
		update c;

		system.debug('inside testExtension, claim amount --> ' + c.Amount__c);
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimResolveExt ext = new ClaimResolveExt(con);

		ext.resolve();

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c, Parent_Customer__c, Resolution_Code__c FROM Claim__c WHERE Id = :c.Id];

		system.assertEquals(c.Status__c, ClaimService.STATUS_CLOSED, 'The claim should be closed after the resolution - ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Method__c, ClaimService.SETTLE_MANUAL, 'The claims should reflect a manual - ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Date__c, system.today(), 'The claim should reflect today as the settlement date - ' + Apexpages.getMessages());

		//We are expecting a journal entry to be generated by the service class
		List<Customer_Invoice__c> cis = [SELECT Id, Invoice_Type__c, Claim__r.Settlement_Method__c, Claim__r.Settlement_Date__c,Customer__c,Resolution_Code__c FROM Customer_Invoice__c WHERE Claim__c = :c.Id];
		system.assertEquals(1, cis.size(), 'We are expecting 1 settlement invoice created for this claim');
		system.assertNotEquals(cis[0], null, 'The settlement customer invoice should be created and related to the claim');
		system.assertEquals(cis[0].Customer__c, c.Parent_Customer__c, 'The customer on CI should match the parent customer on Claim'); //OTC-656
		system.assertEquals(cis[0].Resolution_Code__c, c.Resolution_Code__c, 'The Resolution_Code__c on CI should match the Resolution_Code__c on Claim'); //AR-58
		system.assertEquals(cis[0].Invoice_Type__c, CustomerInvoiceService.TYPE_SETTLEMENT);
		system.assertEquals(cis[0].Claim__r.Settlement_Method__c, ClaimService.SETTLE_MANUAL, cis[0].Claim__r);
		system.assertEquals(cis[0].Claim__r.Settlement_Date__c, system.today(), cis[0].Claim__r);
		test.stopTest();
	}

	static testMethod void testExtension_PartialCose() {


		//ClaimsData cd = new ClaimsData();
		Test.startTest();
		Claim__c c = [SELECT Id, status__c,Amount__c FROM Claim__c limit 1];
		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		c.Resolution_Code__c = resolution.Id;
		update c;

		insert new Claim_Line__c(Claim__c = c.Id, Resolution_Code__c = resolution.Id, Total_Amount__c = 1);

		system.debug('inside testExtension, claim amount --> ' + c.Amount__c);
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimResolveExt ext = new ClaimResolveExt(con);

		ext.resolve();

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c, Parent_Customer__c, Resolution_Code__c, (Select Id, Amount__c from Related_Claims__r) FROM Claim__c WHERE Id = :c.Id];

		system.assertEquals(c.Status__c, ClaimService.STATUS_CLOSED, 'The claim should be closed after the resolution - ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Method__c, ClaimService.SETTLE_MANUAL, 'The claims should reflect a manual - ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Date__c, system.today(), 'The claim should reflect today as the settlement date - ' + Apexpages.getMessages());
		system.assertEquals(1, c.Related_Claims__r.size());
		system.assertEquals(9, c.Related_Claims__r[0].Amount__c);
		Customer_Invoice__c ci = [SELECT Id, Customer__c, Resolution_Code__c FROM Customer_Invoice__c WHERE claim__c = :c.Id];
		system.assertNotEquals(ci, null, 'The settlement customer invoice should be created and related to the claim');
		system.assertEquals(ci.Customer__c, c.Parent_Customer__c, 'The customer on CI should match the parent customer on Claim'); //OTC-656
		system.assertEquals(ci.Resolution_Code__c, c.Resolution_Code__c, 'The Resolution_Code__c on CI should match the Resolution_Code__c on Claim'); //AR-58
		test.stopTest();
	}

	static testMethod void resolveMultipleClaims() {

		TestFuelQuery fuel = new TestFuelQuery();
		//create manual claim
		Reason_Code__c resolution = [Select Id from Reason_Code__c where type__c = 'Resolution' limit 1];
		Claim__c claim = new Claim__c();
		claim.Company__c = fuel.company.Id;
		claim.Parent_Customer__c = fuel.customerParent.Id;
		claim.Bill_To_Customer__c = fuel.customerBillTo.Id;
		claim.Currency__c = fuel.currencyUSD.id;
		claim.Amount__c = 20;
		claim.Type__c = PaymentService.TYPE_GEN_DED;
		claim.Status__c = 'Open';
		claim.Source__c = ClaimService.SOURCE_MANUAL;
		claim.Approval_Status__c = 'Approved';
		claim.Resolution_Code__c = resolution.ID;
		insert claim;

		test.startTest();
		map<Id, Claim__c> claims = new map<Id, Claim__c>([SELECT Id FROM Claim__c]);
		system.assertEquals(claims.size(), 3, 'We are expecting 1 claim created for the deduction line: ' + claims);

		for (Claim__c c : claims.values())
			c.Resolution_Code__c = resolution.ID;
		update claims.values();


		//ClaimService.resolve(claims.keyset());
		try {
			ClaimService.resolve(new set<id>{
					claim.id
			});
		} catch (exception e) {
			Claim__c claimStatus = [select id,status__c from claim__c where id = :claim.id];
			system.assertEquals(claimStatus.status__c == 'Open', true, 'Manual claims cannot be resolved' + claimStatus);
		}
		test.stopTest();
	}



    /*
	*	This test ensures that claims are deleted corresponding to payment lines being deleted from unapplied receipts or other means
	*/
	static testMethod void testClaimDeletedFromDeletedPayment() {

		Customer_Invoice__c custInvoice = [Select Id from Customer_Invoice__c limit 1];
		Customer_Receipt__c custReceipt = [Select Id, Transaction_Date__c, Finalized_Date__c, Void__c, Void_Date__c, Historical__c,Posting_Date__c from Customer_Receipt__c limit 1];


		//We are expecting the trigger to run on the payment line dml, creating 1 claim for the invoice deduction line
		test.startTest();
		List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Source__c = 'Invoice Deduction'];
		system.assertEquals(claims.size(), 1, 'We are expecting 1 claim created for the deduction line: ' + claims);

		Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<Customer_Receipt__c>{
				custReceipt
		});
		custReceipt.finalized__c = false;
		custReceipt.finalized_hidden__c = false;
		update custReceipt;

		delete new list<Customer_Receipt_Line__c>([Select id From Customer_Receipt_Line__c where Type__c = 'Invoice Deduction']);

		//We are expecting the trigger to run on the payment line dml, deleting any related existing open claims
		claims = [SELECT Id FROM Claim__c WHERE Source__c = 'Invoice Deduction'];
		system.assertEquals(claims.size(), 0, 'We are expecting all claims to be removed');
		test.stopTest();
	}


    /* This test verifies the finish split functionality. We expect to successfully close the claim if the amount balances from the lines
    *	If not, an exception should be thrown
    */
	static testMethod void testFinishSplit() {


		//ClaimsData cd = new ClaimsData();

		//We are expecting the trigger to run on the payment line insert, creating 1 claim for the invoice deduction line
		test.startTest();
		List<Claim__c> claims = [SELECT Id FROM Claim__c limit 1];
		system.assertEquals(claims.size(), 1, 'We are expecting 1 claim created for the deduction line: ' + claims);

		Claim__c split1 = new Claim__c();
		split1.Related_Claim__c = claims[0].Id;
		split1.Amount__c = 8;
		Claim__c split2 = new Claim__c();
		split2.Related_Claim__c = claims[0].Id;
		split2.Amount__c = 2;
		insert new List<Claim__c>{
				split1, split2
		};

		ClaimService.finishSplit(new set<Id>{
				claims[0].Id
		});
		Claim__c parentClaim = [SELECT Id, settlement_date__c, settlement_method__c FROM Claim__c WHERE Id = :claims[0].Id];
		system.assertEquals(parentClaim.settlement_date__c, system.today(), 'This claim should be settled when the split is "finished"');
		system.assertEquals(parentClaim.settlement_method__c, ClaimService.SETTLE_SPLIT, 'This claim should reflect a split settlement method');

		test.stopTest();
	}

    /*
    *	This test verifies the finish split functionality. We expect to fail settling claim because the split doesn't add up to the claim amount
    */
	static testMethod void testCannotFinishSplit() {


		//ClaimsData cd = new ClaimsData();


		//We are expecting the trigger to run on the payment line insert, creating 1 claim for the invoice deduction line
		test.startTest();
		List<Claim__c> claims = [SELECT Id FROM Claim__c limit 1];
		system.assertEquals(claims.size(), 1, 'We are expecting 1 claim created for the deduction line: ' + claims);

		Claim__c split1 = new Claim__c();
		split1.Related_Claim__c = claims[0].Id;
		split1.Amount__c = 8;
		insert split1;
		try {
			ClaimService.finishSplit(new set<Id>{
					claims[0].Id
			});
		} catch (Exception ex) {
			//This is a negative test
		}
		Claim__c parentClaim = [SELECT Id, settlement_date__c, settlement_method__c FROM Claim__c WHERE Id = :claims[0].Id];
		system.assertNotEquals(parentClaim.settlement_date__c, system.today(), 'This claim should be not be settled due to a shortage on the split totals');
		system.assertNotEquals(parentClaim.settlement_method__c, ClaimService.SETTLE_SPLIT, 'This claim should not reflect a split settlement method');

		test.stopTest();
	}

     /*
    *	This test verifies the undo of a split occurs correctly, as long as the child claims have not been settled
    */
	static testMethod void testUndoSplit() {


		//ClaimsData cd = new ClaimsData();
		Reason_Code__c resolution = [Select Id from Reason_Code__c where type__c = 'Resolution' limit 1];
		//We are expecting the trigger to run on the payment line insert, creating 1 claim for the invoice deduction line
		test.startTest();
		List<Claim__c> claims = [SELECT Id FROM Claim__c limit 1];
		system.assertEquals(claims.size(), 1, 'We are expecting 1 claim created for the deduction line: ' + claims);

		Claim__c split1 = new Claim__c();
		split1.Related_Claim__c = claims[0].Id;
		split1.Amount__c = 8;
		Claim__c split2 = new Claim__c();
		split2.Related_Claim__c = claims[0].Id;
		split2.Amount__c = 2;
		insert new List<Claim__c>{
				split1, split2
		};

		ClaimService.finishSplit(new set<Id>{
				claims[0].Id
		});
		Claim__c parentClaim = [SELECT Id, settlement_date__c, settlement_method__c FROM Claim__c WHERE Id = :claims[0].Id];
		system.assertEquals(parentClaim.settlement_date__c, system.today(), 'This claim should be settled when the split is "finished"');
		system.assertEquals(parentClaim.settlement_method__c, ClaimService.SETTLE_SPLIT, 'This claim should reflect a split settlement method');

		claims[0].Resolution_Code__c = resolution.Id;
		update claims;
		//ClaimService.resolve(new set<Id>{claims[0].Id});
		parentClaim = [
				SELECT Id, Status__c, settlement_date__c, settlement_method__c, (SELECT Id, name FROM Related_Claims__r)
				FROM Claim__c
				WHERE Id = :claims[0].Id
		];
		system.assertEquals(parentClaim.Status__c, ClaimService.STATUS_CLOSED, 'The status should be closed after being resolved.');

		// ClaimService.reopen(new set<Id>{claims[0].Id});
		ClaimService.undoSplit(new set<Id>{
				claims[0].Id
		});
		parentClaim = [
				SELECT Id, Status__c, settlement_date__c, settlement_method__c, (SELECT Id, name FROM Related_Claims__r), (SELECT Status__c FROM Customer_Invoices__r)
				FROM Claim__c
				WHERE Id = :claims[0].Id
		];
		system.debug(LoggingLevel.INFO, parentClaim.Status__c);
		//system.assertEquals(parentClaim.Customer_Invoices__r[0].Status__c, ClaimService.STATUS_CANCELLED, 'The status should be cancelled.');

		system.assertEquals(parentClaim.settlement_date__c, null, 'This claim should be open');
		system.assertEquals(parentClaim.settlement_method__c, null, 'This claim should be open');
		system.assertEquals(parentClaim.Status__c, ClaimService.STATUS_OPEN, 'This claim should be open');
		system.assertEquals(parentClaim.Related_Claims__r.size(), 0, 'There should be not related claims after the undo split');
		test.stopTest();
	}


	static testMethod void testFinishSplitAmountreverse() {    //8320
		//ClaimsData cd = new ClaimsData();

		test.startTest();
		List <Claim__c> claims = new List <Claim__c>([SELECT Id FROM Claim__c limit 1]);

		Claim__c split01 = new Claim__c();
		split01.Related_Claim__c = claims[0].Id;
		split01.Amount__c = 8;
		Claim__c split02 = new Claim__c();
		split02.Related_Claim__c = claims[0].Id;
		split02.Amount__c = 2;
		insert new List<Claim__c>{
				split01, split02
		};
		boolean flagerror = false;
		try {
			ClaimService.finishSplit(new set<Id>{
					claims[0].Id
			});
		} catch (Exception e) {
			flagerror = e.getmessage().contains(Label.Claim_amount_cannot_be_split_using_reverse_amounts);

		}
		system.assertEquals(flagerror, false);

	}


	//TODO: Negative undo split test condition

    /*
    *	Test that the correspondent field is being populated from the parent customer.
    */
	static testMethod void testPopulateCorrespondent() {
		//system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];

		Profile p = [select id from profile where name = 'System Administrator'];
		User testUser = new User(alias = 'standt', email = 'standarduser@claims.com',
				emailencodingkey = 'UTF-8', lastname = 'Testing', languagelocalekey = 'en_US',
				localesidkey = 'en_US', profileid = p.Id,
				timezonesidkey = 'America/Los_Angeles', username = 'standarduser@claims.com' + TestData_Extension.uniquestring());
		insert testUser;
		TestFuelQuery fuel = new TestFuelQuery();
		fuel.customerParent.Claims_Correspondent__c = testUser.Id;
		update fuel.customerParent;

		// Assert that the field is populated when a claim is inserted.
		Claim__c claim = new Claim__c();
		claim.Parent_Customer__c = fuel.customerParent.Id;

		upsert claim;

		system.assert([select Id, Correspondant__c from Claim__c where Id = :claim.Id limit 1].Correspondant__c == testUser.Id);

	}

	static testMethod void test_canLoad() {

		//TestFuel globalTestData = new TestFuel();
		Claim__c claim = [select id, Claim_Balance__c, Status__c,Amount__c from Claim__c limit 1];


		ClaimSettleAgainstClaimsExt ext = new ClaimSettleAgainstClaimsExt(new Apexpages.Standardcontroller(claim));
		system.assertEquals(ext.isValid, false, ApexPages.getmessages());
	}

	static testMethod void test0BlankRelatedClaims() //AR-66
	{
		//ClaimsData cd = new ClaimsData();
		Claim__c c = [SELECT Id, status__c,Amount__c, Source__c FROM Claim__c WHERE Source__c = 'Invoice Deduction'];
		system.assert(c.Source__c == 'Invoice Deduction', 'This should be an invoice deduciton claim.');
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimSplitExt ext = new ClaimSplitExt(con);

		system.assertEquals(ext.disabled, false, 'This claim should be able to have a write off performed');
		system.assertEquals(ext.splitClaims.size(), 1, 'We should have a new claim by default for user entry');

		ext.splitClaims[0].claim.amount__c = 0;
		try {
			ext.saveClaims();
		} catch (Exception ex) {
			system.assert(ex.getMessage().contains(Label.Cannot_save_Claim_0_Amount_Split));
		}

		ext.splitClaims[0].claim.amount__c = null;
		try {
			ext.saveClaims();
		} catch (Exception ex) {
			system.assert(ex.getMessage().contains(Label.Cannot_save_Claim_0_Amount_Split));
		}
		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c,Amount__c, Source__c, (select id from Related_Claims__r) FROM Claim__c WHERE Id = :c.Id];
		system.assertEquals(c.Status__c, ClaimService.STATUS_NEW, 'The claim should be closed after the split settlement');
		system.assert(c.Related_Claims__r.size() == 0, 'No related claims should have been created as split was not complete');

	}

	static testMethod void testpostiveClmsplitWNegativeAmt() //KNDY-8320
	{
		//ClaimsData cd = new ClaimsData();
		Claim__c c = [SELECT Id, status__c,Amount__c, Source__c FROM Claim__c WHERE Source__c = 'Invoice Deduction'];
		system.assert(c.Source__c == 'Invoice Deduction', 'This should be an invoice deduciton claim.');
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimSplitExt ext = new ClaimSplitExt(con);

		system.assertEquals(ext.disabled, false, 'This claim should be able to have a write off performed');
		system.assertEquals(ext.splitClaims.size(), 1, 'We should have a new claim by default for user entry');

		ext.splitClaims[0].claim.amount__c = -(c.amount__c);
		try {
			ext.saveClaims();
		} catch (Exception ex) {
			system.assert(ex.getMessage().contains(Label.Claim_amount_cannot_be_split_using_reverse_amounts));
		}

		//   ext.splitClaims[0].claim.amount__c = c.amount__c;
		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c,Amount__c, Source__c, (select id from Related_Claims__r) FROM Claim__c WHERE Id = :c.Id];
		system.assert(c.Related_Claims__r.size() == 0, 'No related claims should have been created as split was not complete');

	}


	static testMethod void testClaimSplitWithLines() //AR-82
	{
		//ClaimsData cd = new ClaimsData();
		Claim__c c = [SELECT Id, status__c,Amount__c, Source__c FROM Claim__c WHERE Source__c = 'Invoice Deduction'];
		system.assert(c.Source__c == 'Invoice Deduction', 'This should be an invoice deduciton claim.');
		insert new Claim_Line__c(Claim__c = c.Id, Total_Amount__c = 1);
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimSplitExt ext;
		try {
			ext = new ClaimSplitExt(con);
		} catch (Exception ex) {
			system.assert(ex.getMessage().contains(Label.Cannot_split_claim_if_they_have_lines));
		}


		system.assertEquals(ext.disabled, true, 'This claim split shld be disabled');


	}
	static testMethod void goBack() {
		//ClaimsData cd = new ClaimsData();
		Claim__c c = [SELECT Id, status__c,Amount__c, Source__c FROM Claim__c WHERE Source__c = 'Invoice Deduction'];
		system.assert(c.Source__c == 'Invoice Deduction', 'This should be an invoice deduciton claim.');
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimSplitExt ext = new ClaimSplitExt(con);

		system.assertEquals(ext.disabled, false, 'This claim should be able to have a write off performed');
		system.assertEquals(ext.splitClaims.size(), 1, 'We should have a new claim by default for user entry');

		ext.addClaim();
		system.assertEquals(ext.splitClaims.size(), 2, 'We should have another new claim for user entry');
		ext.splitClaims[0].claim.amount__c = 2;
		ext.splitClaims[1].claim.amount__c = 8;
		ext.saveClaims();
		ext.goBack();

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c,Amount__c, Source__c, (select id from Related_Claims__r) FROM Claim__c WHERE Id = :c.Id];
		system.assertEquals(c.Status__c, ClaimService.STATUS_NEW, 'The claim should be closed after the split settlement');
		system.assert(c.Related_Claims__r.size() == 0, 'No related claims should have been created as split was not complete');

	}
	static testMethod void testExtension3() {
		test.startTest();

		//ClaimsData cd = new ClaimsData();
		Claim__c c = [SELECT Id, status__c,Amount__c, Source__c FROM Claim__c WHERE Source__c = 'Invoice Deduction'];
		system.assert(c.Source__c == 'Invoice Deduction', 'This should be an invoice deduciton claim.');
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimSplitExt ext = new ClaimSplitExt(con);

		system.assertEquals(ext.disabled, false, 'This claim should be able to have a write off performed');
		system.assertEquals(ext.splitClaims.size(), 1, 'We should have a new claim by default for user entry');

		ext.addClaim();
		system.assertEquals(ext.splitClaims.size(), 2, 'We should have another new claim for user entry');

		ext.splitClaims[0].claim.amount__c = 2;
		ext.splitClaims[1].claim.amount__c = 8;
		//save claims before deleting
		ext.saveClaims();
		ext.splitClaims[1].selected = true;
		ext.deleteClaims();
		system.debug(ext.splitClaims);
		system.assertEquals(ext.splitClaims.size(), 1, 'We should have 1 line left after the last was deleted ');
		ext.splitClaims[0].selected = true;
		ext.deleteClaims();
		system.assertEquals(ext.splitClaims.size(), 1, 'We should have 1 line created since all lines are deleted ');

		//delete claim without selecting line.
		ext.deleteClaims();
		string errorStr = '';
		for (ApexPages.Message msg :ApexPages.GetMessages())
			if (msg.getDetail() == Label.Select_one_or_more_claims) {
				errorStr = msg.getDetail() ;
				break;
			}
		system.assertEquals(errorStr, Label.Select_one_or_more_claims);

		//delete without saving record
		ext.splitClaims[0].selected = true;
		ext.splitClaims[0].claim.amount__c = 2;
		ext.deleteClaims();

		//split claim
		ext.splitClaims[0].claim.amount__c = 2;
		ext.addClaim();
		ext.splitClaims[1].claim.amount__c = 8;
		ext.saveClaims();
		ext.finishSplit();
		ext.goBack();

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c,Amount__c, Source__c FROM Claim__c WHERE Id = :c.Id];

		system.assertEquals(c.Status__c, ClaimService.STATUS_CLOSED, 'The claim should be closed after the split settlement');
		system.assertEquals(c.Settlement_Method__c, ClaimService.SETTLE_SPLIT, 'The claims should reflect a split settlement method');
		system.assertEquals(c.Settlement_Date__c, system.today(), 'The claim should reflect today as the settlement date');

		List<Claim__c> relatedClaims = [SELECT Id, Source__c FROM Claim__c WHERE related_claim__c = :c.Id];
		system.assertEquals(relatedClaims.size(), 2, 'We should see two related claims to the parent split');
		system.assertEquals(relatedClaims[0].Source__c, c.Source__c, 'The source should match');
		system.assertEquals(relatedClaims[1].Source__c, c.Source__c, 'The source should match');

		ApexPages.GetMessages().clear(); //OTC-710
		con = new Apexpages.Standardcontroller(c);
		ext = new ClaimSplitExt(con);
		boolean ErrorExists = false;
		for (ApexPages.Message msg :ApexPages.GetMessages())
			if (msg.getDetail() == Label.Claim_is_closed) {
				ErrorExists = true;
				break;
			}
		system.assertEquals(ErrorExists, true, ApexPages.GetMessages());
		test.stopTest();

	}

	static testMethod void resolveSplitClaim() {
		boolean ErrorExists = false;
		//ClaimsData cd = new ClaimsData();
		Reason_Code__c res = [Select Id from Reason_Code__c where Type__c = 'Resolution' limit 1];
		//insert  res;

		Claim__c c = [SELECT Id, status__c,Amount__c, Source__c, Company__c FROM Claim__c WHERE Source__c = 'Invoice Deduction'];
		system.assert(c.Source__c == 'Invoice Deduction', 'This should be an invoice deduciton claim.');
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimSplitExt ext = new ClaimSplitExt(con);
		test.startTest();
		system.assertEquals(ext.disabled, false, 'This claim should be able to have a write off performed');
		system.assertEquals(ext.splitClaims.size(), 1, 'We should have a new claim by default for user entry');

		ext.addClaim();
		system.assertEquals(ext.splitClaims.size(), 2, 'We should have another new claim for user entry');

		ext.splitClaims[0].claim.amount__c = 2;
		ext.splitClaims[1].claim.amount__c = 8;
		ext.saveClaims();

		ext.splitClaims[1].selected = true;
		ext.resolve();
		ErrorExists = false;
		for (ApexPages.Message msg :ApexPages.GetMessages())
			if (msg.getDetail() == Label.Choose_resolution_code_for_selected_claims) {
				ErrorExists = true;
				break;
			}
		system.assert(ErrorExists);

		ext.splitClaims[1].claim.Resolution_Code__c = res.Id;
		ext.saveClaims();

		ext.resolve();

		List<Claim__c> relatedClaims = [SELECT Id, Source__c, Resolution_Code__c, Company__c FROM Claim__c WHERE related_claim__c = :c.Id order by ID];
		system.assertEquals(relatedClaims.size(), 2, 'We should see two related claims to the parent split');
		system.assertEquals(relatedClaims[0].Company__c, c.Company__c, 'The Company__c should match');
		system.assertEquals(relatedClaims[0].Source__c, c.Source__c, 'The source should match');
		system.assertEquals(relatedClaims[1].Company__c, c.Company__c, 'The Company__c should match');
		system.assertEquals(relatedClaims[1].Source__c, c.Source__c, 'The source should match');
		system.assertEquals(relatedClaims[1].Resolution_Code__c, res.Id, 'the second claim shld be resolved');
		test.stopTest();


	}

	/*
	*	This test ensures that claims are created corresponding to new payment lines being created via cash app or other means
	*/
	static testMethod void testClaimFieldUpdated() {
		test.startTest();
		List<Claim__c> localClaimsList = new List<Claim__c>();
		//ClaimsData cd = new ClaimsData();
		Claim__c testClaim = new Claim__c();
		List<Claim__c> claims = [SELECT Id, status__c,Currently_Reopened_Flag__c,Type__c FROM Claim__c WHERE Source__c = 'Invoice Deduction'];

		system.assertEquals(claims[0].Currently_Reopened_Flag__c, false, 'Atleast one claim must be there ');
		if (claims.size() > 0) {
			testClaim = claims[0];
		}
		if (testClaim.Type__c == 'Promotion') {
			testClaim.Type__c = 'Transportation';
		} else {
			testClaim.Type__c = 'Promotion';
		}
		testClaim.Currently_Reopened_Flag__c = true;
		localClaimsList.add(testClaim);
		update localClaimsList;
		Claim__c updatedClaim = [SELECT Id,Currently_Reopened_Flag__c FROM Claim__c WHERE Id = :testClaim.Id];
		System.assertEquals(updatedClaim.Currently_Reopened_Flag__c, true, 'You can only Edit the Enter Claims Notes field while editing the closed claim');
		test.stopTest();
	}

	static testMethod void testClaimFieldUpdated01() {
		test.startTest();
		List<Claim__c> localClaimsList = new List<Claim__c>();
		//ClaimsData cd = new ClaimsData();
		Claim__c testClaim = new Claim__c();
		List<Claim__c> claims = [SELECT Id, status__c,Settlement_Date__c,Currently_Reopened_Flag__c,Type__c FROM Claim__c Where Source__c = 'Invoice Deduction'];

		system.assertEquals(claims[0].Currently_Reopened_Flag__c, false, 'Atleast one claim must be there ');
		if (claims.size() > 0) {
			testClaim = claims[0];
		}
		if (testClaim.status__c == 'Closed') {
			testClaim.status__c = 'Open' ;
		} else {
			testClaim.status__c = 'Closed';
		}

		if (testClaim.Settlement_Date__c == System.today()) {
			testClaim.Settlement_Date__c = System.today().addDays(1) ;
		} else {
			testClaim.Settlement_Date__c = System.today();
		}
		//System.assertEquals(testClaim, null, testClaim);
		//ClaimService.reOpen(new Set<ID>{testClaim.Id});
		testClaim.status__c = 'Open';
		testClaim.Currently_Reopened_Flag__c = true;
		localClaimsList.add(testClaim);
		update localClaimsList;
		Claim__c updatedClaim = [SELECT Id,Currently_Reopened_Flag__c FROM Claim__c WHERE Id = :testClaim.Id];
		//System.assertEquals(updatedClaim.Currently_Reopened_Flag__c, true, 'You can only Edit the Enter Claims Notes field while editing the closed claim');
		test.stopTest();
	}

	static testMethod void testExtension4() {

		Test.startTest();


		Claim__c c = [SELECT Id, parent_customer__c, status__c, Enter_Claims_Notes__c, Reference__c FROM Claim__c WHERE Source__c = 'Invoice Deduction'];
		system.assertEquals('Some reference',c.Reference__c);
		system.assertEquals('Some Notes',c.Enter_Claims_Notes__c);

		Reason_Code__c resolution = [Select Id from Reason_Code__c limit 1];
		system.debug('inside test: ' + c.Parent_Customer__c);
		c.Resolution_Code__c = resolution.Id;
		// c.Bill_to_Customer__c = tdf.customerBillTo.Id; OTC-729
		update c;

		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
		ClaimChargebackExt ext = new ClaimChargebackExt(con);
		system.assertEquals(ext.disableAction, false, 'This claim should be able to have a Chargeback performed');

		ext.chargeback();

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c FROM Claim__c WHERE Id = :c.Id];

		system.assertEquals(c.Status__c, ClaimService.STATUS_CLOSED, 'The claim should be closed after the Chargeback - ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Method__c, ClaimService.SETTLE_CHARGEBACK, 'The claims should reflect a Chargeback - ' + Apexpages.getMessages());
		system.assertEquals(c.Settlement_Date__c, system.today(), 'The claim should reflect today as the settlement date - ' + Apexpages.getMessages());

		con = new Apexpages.Standardcontroller(c);
		ext = new ClaimChargebackExt(con);
		ext.chargeback();
		system.assertEquals(ext.disableAction, true, 'The claim is closed so cannot performa  chargeback action on it.');

		c = [Select Id, (Select Id from Claim_Lines__r), (Select Id From Related_Claims__r) from Claim__c where Id = :c.Id limit 1];
		system.assertNotEquals(0, c.Claim_Lines__r.size(), 'It should create claim lines'); //KNDY-7983
		system.assertEquals(0, c.Related_Claims__r.size(), 'It should not create any related claims if the entire amount is charged back.'); //KNDY-7983

		Customer_Invoice__c ci = [SELECT Id, has_exceptions__c, Invoice_Type__c,Memo__c FROM Customer_Invoice__c WHERE claim__c = :c.Id];
		system.assertEquals(ci.Invoice_Type__c, CustomerInvoiceService.TYPE_CHARGEBACK, 'The Chargeback customer invoice should be created and related to the claim');
		system.assertEquals(ci.Has_Exceptions__c, false, 'No exception for missing bill to should be created');
		system.assertEquals(ci.Memo__c, 'Some reference', 'ci.Memo__c should have some data');
		system.debug(logginglevel.INFO, 'QUERIES: ' + Limits.getQueries());
		test.stopTest();
	}

	static testMethod void testExtension5() {

		test.startTest();

		//ClaimsData cd = new ClaimsData();
		Claim__c c = [SELECT Id, status__c, source__c, Settlement_Method__c,Amount__c FROM Claim__c WHERE Source__c = 'Invoice Deduction'];

		Apexpages.Standardcontroller undocon = new Apexpages.Standardcontroller(c);
		ClaimUndoSplitExt undoext = new ClaimUndoSplitExt(undocon);
		system.assertEquals(undoext.disableAction, true, 'This claim cannot be split.');
		undoext.undoSplit();

		Apexpages.Standardcontroller splitcon = new Apexpages.Standardcontroller(c);
		ClaimSplitExt splitext = new ClaimSplitExt(splitcon);

		system.assertEquals(splitext.disabled, false, 'This claim should be able to have a write off performed');
		system.assertEquals(splitext.splitClaims.size(), 1, 'We should have a new claim by default for user entry');

		splitext.addClaim();

		system.assertEquals(splitext.splitClaims.size(), 2, 'We should have another new claim for user entry');

		splitext.splitClaims[0].claim.amount__c = 2;
		splitext.splitClaims[1].claim.amount__c = 8;

		splitext.saveClaims();
		splitext.finishSplit();

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c,Amount__c FROM Claim__c WHERE Id = :c.Id];

		system.assertEquals(c.Status__c, ClaimService.STATUS_CLOSED, 'The claim should be closed after the split settlement');
		system.assertEquals(c.Settlement_Method__c, ClaimService.SETTLE_SPLIT, 'The claims should reflect a split settlement method');
		system.assertEquals(c.Settlement_Date__c, system.today(), 'The claim should reflect today as the settlement date');

		List<Claim__c> relatedClaims = [SELECT Id FROM Claim__c WHERE related_claim__c = :c.Id];
		system.assertEquals(relatedClaims.size(), 2, 'We should see two related claims to the parent split');

		undoext = new ClaimUndoSplitExt(undocon);
		system.assertEquals(undoext.disableAction, false, 'This claim can be split.');
		undoext.undoSplit();

		c = [SELECT Id, Status__c, Settlement_Method__c, Settlement_Date__c,Amount__c FROM Claim__c WHERE Id = :c.Id];

		system.assertEquals(c.Status__c, ClaimService.STATUS_OPEN, 'The claim should be open after the undo split settlement');
		system.assertEquals(c.Settlement_Method__c, null, 'The claim should not reflect a split settlement method');
		system.assertEquals(c.Settlement_Date__c, null, 'The claim should not reflect today as the settlement date');

		relatedClaims = [SELECT Id FROM Claim__c WHERE related_claim__c = :c.Id];
		system.assertEquals(relatedClaims.size(), 0, 'We should not see related claims to the parent split');

		test.stopTest();

	}
}