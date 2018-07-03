@isTest
public class ClaimManageExtTest {
	@testSetup static void ts() { 
        TestFuel data = new TestFuel(); 
        // these asserts cause TestFuel to insert data
        system.assert(      
            data.company != null &&
            data.bankAccount != null &&
            data.customerSoldTo != null &&
            data.customerBillTo != null &&
            data.product_Misc != null &&
            data.product != null &&
            data.periodList != null &&
            data.salesOrder != null &&
            data.salesOrderLines != null &&
            data.purchaseOrder != null &&
            data.stockMovementRuleList != null &&
            data.smrsList != null &&
            data.itemList != null &&
            data.itemAttrObj != null &&
            data.itemAttrObj2 != null &&
            data.bin != null &&
            data.location != null &&
            data.RENTAL_MONTH != null &&
            data.resolutionCode != null
        );
        
        
    	insert new Segment_Validation__c(Active__c = true, Segment_1__c ='*',  Segment_2__c ='*');													   
    }
   
	

   	public class ClaimsData{
		public Customer_Invoice__c custInvoice;
		public Customer_Invoice_Line__c custInvoiceLine;
		public Customer_Receipt__c custReceipt;
		public Reason_Code__c resolution;
        public Reason_Code__c deductionCode;
        public Claim__c claim;
    	TestFuelQuery globalTestData = new TestFuelQuery();
		public ClaimsData(){
			createData();
		}
		void createData(){
			
			//Sample AR Data
			custInvoice = new Customer_Invoice__c();
			custInvoice.Company__c = globalTestData.company.Id;
            custInvoice.Customer__c = globalTestData.customerParent.Id;
            custInvoice.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
			custInvoice.Currency__c = globalTestData.company.Default_Transaction_Currency__c;
			custInvoice.Invoice_Type__c = 'Ship Invoice';
			custInvoice.Status__c = 'Open';
			custInvoice.Sales_Order__c = globalTestData.salesOrder.Id;
			custInvoice.historical__c = false;
			insert custInvoice;
    
			custInvoiceLine = new Customer_Invoice_Line__c();
			custInvoiceLine.Customer_Invoice__c = custInvoice.Id;
			custInvoiceLine.Product__c = globalTestData.product.Id;
			custInvoiceLine.Quantity_Shipped__c = 20;
			custInvoiceLine.Unit_Price__c = 10;
			custInvoiceLine.Extended_Price__c = 200;
			insert custInvoiceLine;
				
			custReceipt = new Customer_Receipt__c();
			custReceipt.Company__c = globalTestData.company.Id;
			custReceipt.Type__c = CustomerReceiptService.TYPE_RECEIPT;
			custReceipt.Customer__c = globalTestData.customerBillTo.Id;
			custReceipt.Date_Received__c = system.today();
			custReceipt.historical__c = false;
			insert custReceipt;
				
            deductionCode = new Reason_Code__c();
            deductionCode.Type__c = 'Deductions';
            deductionCode.Code__c = 'D001';
            insert deductionCode;
			
			
			
			
			resolution = new Reason_Code__c();
			resolution.name = 'Unsaleables';
			resolution.type__c = 'Resolution';
			insert resolution;
			
			claim = new Claim__c();
			claim.Company__c = globalTestData.company.Id;
			claim.Parent_Customer__c = globalTestData.customerParent.Id;
			claim.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
			claim.Currency__c = globalTestData.company.Default_Transaction_Currency__c;
			claim.Amount__c = 20;
			claim.Type__c = PaymentService.TYPE_GEN_DED;
			claim.Status__c = 'Open';
	        claim.Source__c = ClaimService.SOURCE_MANUAL;
			claim.Approval_Status__c = 'Approved';
			insert claim;
			
		}	
				
	}
	
    

   static testMethod void testClaimManageExt(){
        ApexPages.StandardController con = new ApexPages.StandardController(new Claim__c());
        ClaimManageExt claimManageExt = new ClaimManageExt(con);
        system.assert(claimManageExt.getClaimHeaderFieldList().length() > 0 );
        system.assert(claimManageExt.getClaimAddlHeaderFieldList().length() > 0 );
        system.assert(claimManageExt.getTypeDescribe() != null );
        system.assert(claimManageExt.getSubTypeDescribe() != null );
        system.assert(claimManageExt.getReasonDescribe()!= null);
    } 
    static testMethod void testGetReturnUrl() {
    	
    	ClaimsData cd = new ClaimsData();
        ApexPages.StandardController con = new ApexPages.StandardController(new Claim__c());
        ClaimManageExt claimManageExt = new ClaimManageExt(con);
        
        Schema.DescribeSObjectResult dsr = Claim__c.SObjectType.getDescribe();
        system.assertEquals(claimManageExt.getReturnUrl(), '/' + dsr.getKeyPrefix(), 'Return URL does not match for new customer receipt: ' + claimManageExt.getReturnUrl());
        
        con = new ApexPages.StandardController(cd.claim);
        claimManageExt = new ClaimManageExt(con);
        system.assertEquals(claimManageExt.getKeyPrefix() != null, true);
        String claimId  = String.valueOf(cd.claim.Id).substring(0,15); // Case sensitive id.
        system.assertEquals(claimManageExt.getReturnUrl(), '/' + claimId, 'Return URL does not match for existing customer receipt: ' + claimManageExt.getReturnUrl());
    }
    static testMethod void testGetClaim(){
       	ClaimsData cd = new ClaimsData();
       	TestFuelQuery globalTestData = new TestFuelQuery();
        system.assert(cd.claim.Id != null); // Makes sure that the claim is created.
        JSONResult result = ClaimManageExt.getClaim(cd.claim.Id);
        system.assert(result.total == 1, 'Claim count does not match: ' + result.total);
        //set default user preferences
        CompanyService cs = new CompanyService(new ApexPages.standardController(globalTestData.company));
        system.assertEquals( true, cs.doedit );
        system.assertEquals( null, cs.editCompany() ); 
        system.assertEquals( true, cs.doedit );
        cs.manageDefaults();
        cs.defaults.Preference.Default_Company__c = globalTestData.company.id;
        
        // Change in default company changes the membership of the user in public groups.
        // This needs to insert a setup object and might throw MIXED_DML_EXCEPTION. Hence the runAs().
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        system.runAs(currentUser){
        	Test.startTest();
        	cs.defaults.updateUserPreference();	
        }
        result = ClaimManageExt.getClaim(null);
        system.assert(result.total == 1, 'Claim count does not match: ' + result.total);
        Claim__c claimCheck = (Claim__c)result.records[0];
        system.assert(claimCheck.Company__c == globalTestData.company.Id, 'Claim company does not match: ' + result.records);

    }
    static testMethod void getClaimWithClosedClaims(){
        //test with claimlines
		ClaimsData cd = new ClaimsData();
    	TestFuelQuery globalTestData = new TestFuelQuery();
    	List<Customer_Receipt_Line__c> pmtLines = new List<Customer_Receipt_Line__c>();
    	Customer_Receipt_Line__c pmtCash = new Customer_Receipt_Line__c();
    	pmtCash.Amount__c = 90;
    	pmtCash.Type__c = 'Payment';
    	pmtCash.Customer_Invoice__c = cd.custInvoice.Id;
    	pmtCash.Customer_Receipt__c = cd.custReceipt.Id;
    	pmtLines.add(pmtCash);
       
    	Customer_Receipt_Line__c pmtInvDed1 = new Customer_Receipt_Line__c();
    	pmtInvDed1.Amount__c = 50;
    	pmtInvDed1.Type__c = 'Invoice Deduction';
        pmtInvDed1.Reason_Code__c = cd.deductionCode.Id;
    	pmtInvDed1.Customer_Invoice__c = cd.custInvoice.Id;
    	pmtInvDed1.Customer_Receipt__c = cd.custReceipt.Id;
    	pmtLines.add(pmtInvDed1);
		
    	Customer_Receipt_Line__c pmtInvDed = new Customer_Receipt_Line__c();
    	pmtInvDed.Amount__c = 50;
    	pmtInvDed.Type__c = 'Invoice Deduction';
        pmtInvDed.Reason_Code__c = cd.deductionCode.Id;
    	pmtInvDed.Customer_Invoice__c = cd.custInvoice.Id;
    	pmtInvDed.Customer_Receipt__c = cd.custReceipt.Id;
    	pmtLines.add(pmtInvDed);
		
    	Customer_Receipt_Line__c genDeduction = new Customer_Receipt_Line__c();
    	genDeduction.Amount__c = 90;
    	genDeduction.Type__c = PaymentService.TYPE_GEN_DED;
        genDeduction.Reason_Code__c = cd.deductionCode.Id;
    	genDeduction.Customer_Receipt__c = cd.custReceipt.Id;
    	pmtLines.add(genDeduction);
    	insert pmtLines;
		
    	cd.custReceipt.finalized__c = true;
	    update cd.custReceipt;
		
       	test.startTest();
    	List<Claim__c> claims = [SELECT Id,Source__c,Status__c,Amount__c FROM Claim__c WHERE Customer_Receipt_Line__c = :pmtInvDed.Id];
    	system.assertEquals(claims.size(), 1, 'We are expecting 1 claim created for the deduction line: ' + claims);
    	claims[0].Resolution_Code__c = cd.resolution.Id;
    	update claims;
    	//Pass the Id of the sole expected returned result
    	ClaimService.resolve(new set<Id>{claims[0].Id});
		
    	//We are expecting a journal entry to be generated by the service class
    	List<Customer_Invoice__c> cis = [SELECT Id, Invoice_Type__c, Claim__r.Settlement_Method__c, Claim__r.Settlement_Date__c FROM Customer_Invoice__c WHERE Claim__c = :claims[0].Id];
    	system.assertEquals(1, cis.size(), 'We are expecting 1 settlement invoice created for this claim');
    	system.assertEquals(cis[0].Invoice_Type__c, CustomerInvoiceService.TYPE_SETTLEMENT);
    	system.assertEquals(cis[0].Claim__r.Settlement_Method__c, ClaimService.SETTLE_AUTO, cis[0].Claim__r);
    	system.assertEquals(cis[0].Claim__r.Settlement_Date__c, system.today(), cis[0].Claim__r);
    	claims[0].Amount__c = 100;
	 	
    	JSONResult saveResult = ClaimManageExt.save(claims[0], null);
        system.debug('saveResult==' + saveResult);
        system.assertequals(saveResult.success, false, 'Claim save failed: ' + saveResult);
    	test.stopTest();
        
    }
    static testMethod void getCompanyCurrency() {
    	TestFuelQuery globalTestData = new TestFuelQuery();
    	
    	JSONresult result = ClaimManageExt.getCompanyDefaultCurrency(globalTestData.company.Id);
    	system.assertEquals(true,result.success);
    	system.assertEquals(1, result.records.size());
    	Currency__c curr = (Currency__c)result.records[0];
    	system.assertEquals(globalTestData.company.Default_Transaction_Currency__c, curr.Id);
    }
    static testMethod void testSave(){
    	ClaimsData cd = new ClaimsData();
        TestFuelQuery globalTestData = new TestFuelQuery();
        system.assert(cd.claim.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = ClaimManageExt.getClaim(cd.claim.Id);
        system.assert(result.total == 1, 'Claim count does not match: ' + result.total);
        
        //OTC-318
        Profile p = [select id from profile where name='System Administrator']; 
	    User testUser = new User(alias = 'standt', email='standarduser@claims.com', 
	                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', 
	                localesidkey='en_US', profileid = p.Id, 
	                timezonesidkey='America/Los_Angeles', username='standarduser@claims.com');
	    insert testUser;
	    
        globalTestData.customerParent.Claims_Correspondent__c = testUser.Id;
        update globalTestData.customerParent;

        Test.startTest();
        
        JSONResult saveResult = ClaimManageExt.save(cd.claim, null);
        Test.stopTest();
        system.assert(saveResult.success == true, 'Method save failed due to '+ saveResult.messages);
        
    }
    
    //KNDY-15531 KNDY-16068 Zero or Negative claim amount
    static testMethod void testInvalidAmountForManualClaim(){
        String expectedErrorMsg = 'You can\'t enter a zero or negative amount for a manual claim.';
        TestFuelQuery globalTestData = new TestFuelQuery();
       
        // Negative amount
        Claim__c claim = new Claim__c();
        claim.Company__c = globalTestData.company.Id;
        claim.Parent_Customer__c = globalTestData.customerParent.Id;
        claim.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        claim.Currency__c = globalTestData.currencyUSD.id;
        claim.Amount__c = -20;
        claim.Type__c = PaymentService.TYPE_GEN_DED;
        claim.Status__c = 'Open';
        claim.Source__c = ClaimService.SOURCE_MANUAL;
        claim.Approval_Status__c = 'Approved';
    
        Test.startTest();
        
        JSONResult saveResult = ClaimManageExt.save(claim, null);
        system.assertEquals(saveResult.success,false,saveResult);
        boolean ErrorExists = false;
        for(Map<String, String> msg :saveResult.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains(expectedErrorMsg)){
                ErrorExists = true;
                break;
                }
            }
        }
        system.assertEquals(ErrorExists, true, saveResult.messages);
            
        //0 amount
        claim.Amount__c = 0;
        saveResult = ClaimManageExt.save(claim, null);
        system.assertEquals(saveResult.success,false,saveResult);
        ErrorExists = false;
        for(Map<String, String> msgMap :saveResult.messages){
            if(msgMap.containsKey('message')){
                if(msgMap.get('message').contains(expectedErrorMsg)){
                ErrorExists = true;
                break;
                }
            }
        }
        system.assertEquals(ErrorExists, true, saveResult.messages);
        Test.stopTest();
    }
}