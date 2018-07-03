/**
 * This class contains unit tests for validating the behavior of methods
 * in CustomerReceiptManageExt.cls
 */
@isTest
private class CustomerReceiptManageExtTest {
	@testSetup static void ts() { 
        TestFuel globalTestData = new TestFuel(); 
        system.assert(globalTestData.company.Id != null &&
        			  globalTestData.customerParent.Id != null &&
        			  globalTestData.customerBillTo.Id != null &&
        			  globalTestData.resolutionCode.Id != null &&
        			  globalTestData.deductionCode.Id != null &&
        			  globalTestData.customerSoldTo.Id != null &&
        			  globalTestData.salesOrder.id != null && 
        			  globalTestData.periodList != null &&
        			  globalTestData.bankAccount.Id != null &&
        			  TestFuel.currencyUSD.Id != null &&
        			  TestFuel.currencyGBP.ID != null);
	}
	
	
	public static TestFuelQuery globalTestData = new TestFuelQuery();
	public static Customer_Receipt__c custReceipt {
		get{
			if(custReceipt == null){
				custReceipt = new Customer_Receipt__c();
				custReceipt.Company__c = globalTestData.company.Id;
				custReceipt.Customer__c = globalTestData.customerParent.Id;
				custReceipt.Date_Received__c = system.now();
				custReceipt.Type__c = 'Receipt';
				custReceipt.Currency__c = globalTestData.currencyUSD.id;
				//custReceipt.Amount_Unapplied__c =0; // as this field is manipulated on the client side. 
				insert custReceipt;
			}	
			return custReceipt;
		}
		set;
	}
	
	
	public static Customer_Invoice__c creditMemo {
	    get{
			if(creditMemo == null){
				creditMemo = new Customer_Invoice__c();
				creditMemo.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
                creditMemo.Company__c = globalTestData.company.Id;
                creditMemo.Customer_Receipt__c = custReceipt.Id;
                creditMemo.Invoice_Type__c = 'Credit Memo';
                creditMemo.Status__c = CustomerInvoiceService.STATUS_OPEN;
                creditMemo.Date_Invoiced__c = system.now();
                creditMemo.Currency__c = custReceipt.Currency__c;
				creditMemo.Transaction_Date__c = system.now();
				creditMemo.Amount_To_Apply__c = 1;
				insert creditMemo;
				
				Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
				cil.Customer_Invoice__c = creditMemo.Id;
				cil.Quantity_Shipped__c = -1;
				cil.Unit_Price__c = 10;
				insert cil;
			}	
			return creditMemo;
		}
		set;
	}
	
	public static Customer_Invoice__c CustomerInvoice {
	    get{
			if(CustomerInvoice == null){
				CustomerInvoice = new Customer_Invoice__c();
				CustomerInvoice.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
                CustomerInvoice.Company__c = globalTestData.company.Id;
                CustomerInvoice.Customer_Receipt__c = custReceipt.Id;
                CustomerInvoice.Invoice_Type__c = 'Manual';
                CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
                CustomerInvoice.Date_Invoiced__c = system.now();
                CustomerInvoice.Currency__c = custReceipt.Currency__c;
                CustomerInvoice.Transaction_Date__c = Date.today();
                CustomerInvoice.Amount_To_Apply__c = 1;
				//CustomerInvoice.Finalized__c =true;
				insert CustomerInvoice;
				
				Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
				cil.Customer_Invoice__c = CustomerInvoice.Id;
				cil.Quantity_Shipped__c = 1;
				cil.Unit_Price__c = 100;
				insert cil;
			}	
			return CustomerInvoice;
		}
		set;
	}
	
	public static Customer_Receipt_Line__c paymentLine {
	    get{
			if(paymentLine == null){
				paymentLine = new Customer_Receipt_Line__c();
				paymentLine.Amount__c = 50;
				paymentLine.Customer_Receipt__c = custReceipt.Id;
				paymentLine.Customer_Invoice__c = CustomerInvoice.Id;
				paymentLine.Type__c = PaymentService.TYPE_PAYMENT;
				
				insert paymentLine;
			}	
			return paymentLine;
		}
		set;
	}
	
	public static Customer_Receipt_Line__c writeOff {
	    get{
			if(writeOff == null){
				writeOff = new Customer_Receipt_Line__c();
				writeOff.Amount__c = 5;
				writeOff.Customer_Receipt__c = custReceipt.Id;
				writeOff.Customer_Invoice__c = CustomerInvoice.Id;
				writeOff.Type__c = PaymentService.TYPE_WRITEOFF;
				writeOff.Reason_Code__c = globalTestData.resolutionCode.Id;
				
				insert writeOff;
			}	
			return writeOff;
		}
		set;
	}
	
	public static Customer_Receipt_Line__c unEarned {
	    get{
			if(unEarned == null){
				unEarned = new Customer_Receipt_Line__c();
				unEarned.Amount__c = 5;
				unEarned.Customer_Receipt__c = custReceipt.Id;
				unEarned.Customer_Invoice__c = CustomerInvoice.Id;
				unEarned.Type__c = PaymentService.TYPE_UNEARNED_DISCOUNT;
				
				insert unEarned;
			}	
			return unEarned;
		}
		set;
	}
	
	public static Customer_Receipt_Line__c deductionLine {
	    get{
			if(deductionLine == null){
				deductionLine = new Customer_Receipt_Line__c();
				deductionLine.Amount__c = -100;
				deductionLine.Customer_Receipt__c = custReceipt.Id;
				deductionLine.Reason_Code__c = globalTestData.deductionCode.Id;
				deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
				deductionLine.Customer__c = globalTestData.customerBillTo.Id;
				deductionLine.Sold_To_Customer__c = globalTestData.customerSoldTo.Id;
				
				insert deductionLine;
			}	
			return deductionLine;
		}
		set;
	}
	public static Customer_Receipt_Line__c invDeductionLine {
	    get{
			if(invDeductionLine == null){
				invDeductionLine = new Customer_Receipt_Line__c();
				invDeductionLine.Amount__c = -100;
				invDeductionLine.Customer_Receipt__c = custReceipt.Id;
				invDeductionLine.Reason_Code__c = globalTestData.deductionCode.Id;
				invDeductionLine.Customer_Invoice__c = CustomerInvoice.Id;
				invDeductionLine.Type__c = PaymentService.TYPE_INVOICE_DEDUCTION;
				
				insert invDeductionLine;
			}	
			return invDeductionLine;
		}
		set;
	}
	
	public static Claim__c claim {
	    get{
			if(claim == null){
				claim = new Claim__c();
				claim.Company__c = globalTestData.company.Id;
				claim.Parent_Customer__c = globalTestData.customerParent.Id;
				claim.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
				claim.Currency__c = globalTestData.currencyUSD.id;
				claim.Amount__c = 20;
				claim.Type__c = PaymentService.TYPE_GEN_DED;
				claim.Source__c =  PaymentService.TYPE_GEN_DED; //KNDY-15037
				claim.Status__c = 'Open';
				claim.Approval_Status__c = 'Approved';
				insert claim;
			}	
			return claim;
		}
		set;
	}
	
	public static Customer_Receipt_Line__c OverPaymentLine {
	    get{
			if(OverPaymentLine == null){
				OverPaymentLine = new Customer_Receipt_Line__c();
				OverPaymentLine.Amount__c =10;
				OverPaymentLine.Customer_Receipt__c = custReceipt.Id;
				OverPaymentLine.Type__c = PaymentService.TYPE_OVERPAYMENT;
				OverPaymentLine.Customer_Invoice__c = creditMemo.Id; //	KNDY-13995
				OverPaymentLine.Customer__c = globalTestData.customerBillTo.id;
				insert OverPaymentLine;
			}	
			return OverPaymentLine;
		}
		set;
	}
	
	public static Customer_Receipt_Line__c PrePaymentLine {
	    get{
			if(PrePaymentLine == null){
				PrePaymentLine = new Customer_Receipt_Line__c();
				PrePaymentLine.Amount__c =208;
				PrePaymentLine.Customer_Receipt__c = custReceipt.Id;
				PrePaymentLine.Type__c = PaymentService.TYPE_PREPAYMENT;
				PrePaymentLine.Customer__c = globalTestData.customerBillTo.id;
				PrePaymentLine.Sales_Order__c = globalTestData.salesOrder.id;
				insert PrePaymentLine;
			}	
			return PrePaymentLine;
		}
		set;
	}
	
 static testMethod void validateCancelledSalesOrder(){
 	Customer_Receipt_Line__c prePaymentCRL = PrePaymentLine;
 	boolean isSuccess;
 	Sales_Order__c cancelledSO = [Select Id,Status__c from Sales_Order__c where Id=:globalTestData.salesOrder.id];
 	update PrePaymentLine;
 	cancelledSO.Status__c = 'Cancelled';
 	update cancelledSO;
 	try{
 		isSuccess = true;
 		update PrePaymentLine; //updating CRL
 	}catch(Exception ex){
 		isSuccess = false;
 		system.assert(ex.getMessage().contains(System.Label.SalesOrderValidation));
 	}	
 	system.assertEquals(false,isSuccess);
 }		
 static testMethod void testCustomerReceiptManageExt() {
        ApexPages.StandardController con = new ApexPages.StandardController(custReceipt);
        CustomerReceiptManageExt crManageExt = new CustomerReceiptManageExt(con);
        system.assert(crManageExt.creditMemosGridConfig != null );
        system.assert(crManageExt.deductionsGridConfig != null );
        system.assert(crManageExt.customerInvoicesGridConfig != null );
        system.assert(crManageExt.customerInvoiceDetailsGridConfig != null );
        system.assert(crManageExt.claimsGridConfig != null );
        system.assert(crManageExt.additionalPaymentsGridConfig != null );
        
        system.assert(crManageExt.getCreditMemoFieldList().length() > 0 );
        system.assert(crManageExt.getDeductionFieldList().length() > 0 );
       
        String fieldInfoListStr = crManageExt.getCustomerInvoiceFieldList();
        system.assert(fieldInfoListStr.length() > 0 );
        List<FieldInfo> fieldInfoList = (List<FieldInfo>) JSON.deserialize(fieldInfoListStr, List<FieldInfo>.class);
        Boolean hasEarnedDiscount = false;//KNDY-17349
        Boolean hasUnearnedDiscount = false;//KNDY-17349
        for (FieldInfo fi : fieldInfoList){
            if (fi.field == 'earnedDiscountAmount'){
               hasEarnedDiscount = true;
            }
            else if (fi.field == 'unearnedDiscountAmount'){
               hasUnearnedDiscount = true;
            }
        }
        system.assertEquals(hasEarnedDiscount, true);
        system.assertEquals(hasUnearnedDiscount, true);
        system.assert(crManageExt.getCustomerInvoiceDetailFieldList().length() > 0 );
        system.assert(crManageExt.getClaimFieldList().length() > 0 );
        system.assert(crManageExt.getAdditionalPaymentFieldList().length() > 0 );
        
        system.assert(crManageExt.getCreditMemosGridConfigJson() != null );
        system.assert(crManageExt.getDeductionsGridConfigJson() != null );
        system.assert(crManageExt.getCustomerInvoicesGridConfigJson() != null );
        system.assert(crManageExt.getCustomerInvoiceDetailsGridConfigJson() != null );
        system.assert(crManageExt.getClaimsGridConfigJson() != null );
        system.assert(crManageExt.getAdditionalPaymentsGridConfigJson() != null );
    }
    
    static testMethod void testGetReturnUrl() {
        ApexPages.StandardController con = new ApexPages.StandardController(new Customer_Receipt__c());
        CustomerReceiptManageExt crmExt = new CustomerReceiptManageExt(con);
        
        Schema.DescribeSObjectResult dsr = Customer_Receipt__c.SObjectType.getDescribe();
        system.assertEquals(crmExt.getReturnUrl(), '/' + dsr.getKeyPrefix(), 'Return URL does not match for new customer receipt: ' + crmExt.getReturnUrl());
        
        con = new ApexPages.StandardController(custReceipt);
        crmExt = new CustomerReceiptManageExt(con);
        
        String custReceiptId  = String.valueOf(custReceipt.Id).substring(0,15); // Case sensitive id.
        system.assertEquals(crmExt.getReturnUrl(), '/' + custReceiptId, 'Return URL does not match for existing customer receipt: ' + crmExt.getReturnUrl());
    }
 
    static testMethod void testDefaultDateReceived() {//KNDY-10670
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
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
        	//Test.stopTest();
        }
        
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(null, '');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        Customer_Receipt__c cr = (Customer_receipt__c)result.records[0];
        system.assert(cr.Date_Received__c != null, 'Customer receipt date received is empty: ' + cr);
        //KNDY-18029 No deposit payment method found
        system.assertEquals(cr.Payment_Method_G__c == null,true,'Deposit payment method associated found : ' + cr);
        
    	
    }
    //KNDY-14482
    static testMethod void testDefaultBankAccount(){
   		Bank_Account__c bankAccountObj = globalTestData.bankAccount;
   		system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	CompanyService cs = new CompanyService(new ApexPages.standardController(globalTestData.company));
        system.assertEquals( true, cs.doedit );
        system.assertEquals( null, cs.editCompany() ); 
        system.assertEquals( true, cs.doedit );
        cs.manageDefaults();
        cs.defaults.Preference.Default_Company__c = globalTestData.company.id;
        Company__c currentCompany = globalTestData.company;
        currentCompany.Deposit_Bank_Account__c = bankAccountObj.id;
        update currentCompany;
        // Change in default company changes the membership of the user in public groups.
        // This needs to insert a setup object and might throw MIXED_DML_EXCEPTION. Hence the runAs().
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        system.runAs(currentUser){
        	Test.startTest();
        	cs.defaults.updateUserPreference();	
        	//Test.stopTest();
        }
        
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(null, '');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        Customer_Receipt__c cr = (Customer_receipt__c)result.records[0];
        system.assert(cr.Bank_Account_2__c != null, 'Bank Account is null: ' + cr);
 
    }
    static testMethod void testSave(){
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id, '');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        //custReceipt = (Customer_Receipt__c) result.records[0];
        
         
        system.assert(creditMemo.Id != null); // Makes sure that the credit memo is created.
        creditMemo.Finalized__c = true;
        update creditMemo;
        JSONResult result2 = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
        system.assert(result2.total == 1, 'Credit memo count does not match: ' + result2.total);
        List<CustomerReceiptManageExt.CreditMemoWrapper> rec = (List<CustomerReceiptManageExt.CreditMemoWrapper>)result2.records;
        rec[0].creditMemo.Memo__c = 'Test memo';
        Id creditMemoId = rec[0].creditMemo.id;
        Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>> creditMemoChanges = new Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>>();
        creditMemoChanges.put('updatedRows', (List<CustomerReceiptManageExt.CreditMemoWrapper>) result2.records);
        
        system.assert(deductionLine.Id != null); // Makes sure that the deduction line is created.
        JSONResult result3 = CustomerReceiptManageExt.getDeductions(custReceipt.Id);
        system.assert(result3.total == 1, 'Deduction count does not match: ' + result3.total);
        Map<String, List<CustomerReceiptManageExt.DeductionWrapper>> deductionChanges = new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>();
        deductionChanges.put('updatedRows', (List<CustomerReceiptManageExt.DeductionWrapper>) result3.records);
        
        system.assert(claim.Id != null); // Makes sure that the claim line is created.
        JSONResult result4 = CustomerReceiptManageExt.getClaims(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
        system.assert(result4.total == 1, 'Claims count does not match: ' + result4.total);
        Map<String, List<CustomerReceiptManageExt.ClaimWrapper>> claimChanges = new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>();
        claimChanges.put('updatedRows', (List<CustomerReceiptManageExt.ClaimWrapper>) result4.records);
        
        system.assert(CustomerInvoice.id != null);
        CustomerInvoice.Finalized__c = true;
        update CustomerInvoice;
       
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
       	List<CustomerReceiptManageExt.CustomerInvoiceWrapper> recs = (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>)CIresult.records;
        recs[0].selected = true; 
        recs[0].customerInvoice.Amount_Applied__c = 98; 
        recs[0].customerInvoice.Memo__c = 'Test memo';
        Id customerInvoiceId = recs[0].customerInvoice.id;
        System.debug(logginglevel.error,'customerInvoiceId--->'+customerInvoiceId);
        
        Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>> CIChanges = new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>();
        CIChanges.put('updatedRows', (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>) CIresult.records);
        
        
        system.assert(OverPaymentLine.Id != null); // Makes sure that the additional payment line is created.
        JSONResult result5 = CustomerReceiptManageExt.getAdditionalPayments(custReceipt.Id);
        system.assert(result5.total == 1, 'Additional payments count does not match: ' + result5.total);
        Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>> additionalPaymentChanges = new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>();
        additionalPaymentChanges.put('updatedRows', (List<CustomerReceiptManageExt.AdditionalPaymentWrapper>) result5.records);
        
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
        custReceipt.Amount_Received__c = 208;
        custReceipt.Bank_Account_2__c =  globalTestData.bankAccount.Id;
        custReceipt.Payment_Method_G__c = 'Cash';
        custReceipt.Reference_Number__c = '123';
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null, creditMemoChanges, deductionChanges, CIchanges, claimChanges, additionalPaymentChanges);
        
        
        
        system.assert(saveResult.success == true, 'Method save failed due to '+ saveResult.messages);
        
        //AR-133 test the JSONResult get records after CR is closed
        
        result3 = CustomerReceiptManageExt.getDeductions(custReceipt.Id);
        system.assert(result3.total == 1, 'Deduction count does not match: ' + result3.total);
        
        CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        
        result5 = CustomerReceiptManageExt.getAdditionalPayments(custReceipt.Id);
        system.assert(result5.total == 1, 'Additional payments count does not match: ' + result5.total);
        
       
        list<Customer_Receipt_Line__c> crlSaved = [select id,Customer_Invoice__c,Memo__c,Type__c from Customer_Receipt_Line__c where Customer_Invoice__c = :customerInvoiceId and memo__c = 'Test memo'];
        System.debug(logginglevel.error,'crlSaved-->'+crlSaved);
        system.assertEquals(2,crlSaved.size(),customerInvoiceId); // 2 CRLs created, with Type - Payment and Earned Terms Discount respectively.
       
       crlSaved = [select id from Customer_Receipt_Line__c where Customer_Invoice__c = :creditMemoId and memo__c = 'Test memo']; //KNDY-13995
        system.assertEquals(1,crlSaved.size()); //KNDY-13817 
        Test.stopTest();
        
    }
    
    
    static testMethod void testSaveCreditMemo_WithMemoPopulatedonCI()
    {
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id, '');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
         
        system.assert(creditMemo.Id != null); // Makes sure that the credit memo is created.
        creditMemo.Finalized__c = true;
        creditMemo.Memo__c = 'This is the Memo Text Added';  
        update creditMemo;
        
        
        JSONResult result2 = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
        system.assert(result2.total == 1, 'Credit memo count does not match: ' + result2.total);
        System.debug(logginglevel.error,'result2---->'+result2);
        
        for(CustomerReceiptManageExt.CreditMemoWrapper cmwrapper : (List<CustomerReceiptManageExt.CreditMemoWrapper>)result2.records){
                cmwrapper.creditMemo.Amount_To_Apply__c = 5;
                cmwrapper.creditMemo.Write_Off_Amount__c = 5;
                cmwrapper.creditMemo.Resolution_Code__c = globalTestData.resolutionCode.Id;
                System.assert(cmwrapper.creditMemo.Memo__c == creditMemo.Memo__c,'The memo text on the CI is not the same'); //makes sure the memo text on the CI is perculated down
                cmwrapper.creditMemo.Memo__c = 'Updated memo text added'; // Updating the Memo text
         }
         
        Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>> creditMemoChanges = new Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>>();
        creditMemoChanges.put('updatedRows', (List<CustomerReceiptManageExt.CreditMemoWrapper>) result2.records);
        
        Test.startTest();
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null, creditMemoChanges, new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>() , new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>(),
                                                                 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>()); // 2 CRL gets created
        System.debug(logginglevel.error,'saveResult--->'+saveResult);
        
        Test.stopTest();
       
        system.assert(saveResult.success == true, 'Method save failed due to '+ saveResult.messages); 
        
        List<Customer_Receipt_Line__c> custReceiptLineList = [select Id,Reason_Code__c,Type__c,Finalized__c,Amount__c,Has_Exceptions__c,Memo__c  from Customer_Receipt_Line__c where Customer_Receipt__c = :custReceipt.Id ];
        system.debug(logginglevel.error,'custReceiptLineList-->'+custReceiptLineList);
        system.assert(custReceiptLineList.size() == 2, 'Customer receipt line count does not match: ' + custReceiptLineList.size());
        for(Customer_Receipt_Line__c crLine : custReceiptLineList){
            system.assert(crLine.Memo__c == 'Updated memo text added',' The Customer Receipt Line does not have the memo text as updated ');
        }
    }
    
    static testMethod void testSaveCI_WithMemoPopulatedonCI() 
    {
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);  
       
        system.assert(CustomerInvoice.id != null);
        
        CustomerInvoice.Finalized__c =true;
        CustomerInvoice.Memo__c = 'This is the Memo Text Added on CI'; 
        update CustomerInvoice;
        
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        
        for(CustomerReceiptManageExt.CustomerInvoiceWrapper ciwrapper : (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>)CIresult.records){
                ciwrapper.selected = true; 
                ciwrapper.customerInvoice.Amount_Applied__c = 9;
                ciwrapper.customerInvoice.Write_Off_Amount__c = 5;
                ciwrapper.customerInvoice.Resolution_Code__c = globalTestData.resolutionCode.Id;
         }
         
        Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>> CIChanges = new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>();
        CIChanges.put('updatedRows', (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>) CIresult.records);
        
        Test.startTest();
        custReceipt.Amount_Received__c = 9;
        custReceipt.Bank_Account_2__c =  globalTestData.bankAccount.Id;
        custReceipt.Payment_Method_G__c = 'Cash';
        custReceipt.Reference_Number__c = '123';
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null, new Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>>(), new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>(), CIChanges,
                                                                 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>());
        Test.stopTest();
        
        system.assert(saveResult.success == true, 'Method save failed due to '+ saveResult.messages);
        
        List<Customer_Receipt_Line__c> custReceiptLineList = [select Id,Reason_Code__c,Type__c,Customer_Invoice__c,Finalized__c,Amount__c,Has_Exceptions__c,Memo__c  from Customer_Receipt_Line__c where Customer_Receipt__c = :custReceipt.Id];
        system.debug(logginglevel.error,'custReceiptLineList-->'+custReceiptLineList);
        system.assert(custReceiptLineList.size() == 3, 'Customer receipt line count does not match: ' + custReceiptLineList.size());
        for(Customer_Receipt_Line__c crLine : custReceiptLineList){  
            system.assert(crLine.Memo__c == 'This is the Memo Text Added on CI',' The Customer Receipt Line does not have the memo text as in CI ');
        }
         
    }
    static testMethod void testSaveCI_WithDiscountAmountChange() {//KNDY-17349
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);  
       
        system.assert(CustomerInvoice.id != null);
        
        CustomerInvoice.Finalized__c =true;

        update CustomerInvoice;
        
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        
        for(CustomerReceiptManageExt.CustomerInvoiceWrapper ciwrapper : (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>)CIresult.records){
                ciwrapper.selected = true; 
                ciwrapper.customerInvoice.Amount_Applied__c = 8;
                ciwrapper.ciEarnedDiscountAmount = .6;
                ciwrapper.ciUnearnedDiscountAmount = .4;
                ciwrapper.customerInvoice.Resolution_Code__c = globalTestData.resolutionCode.Id;
         }
         
        Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>> CIChanges = new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>();
        CIChanges.put('updatedRows', (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>) CIresult.records);
        
        Test.startTest();
        custReceipt.Amount_Received__c = 8;
        custReceipt.Bank_Account_2__c =  globalTestData.bankAccount.Id;
        custReceipt.Payment_Method_2__c = 'Cash';
        custReceipt.Reference_Number__c = '123';
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null, new Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>>(), new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>(), CIChanges,
                                                                 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>());
        Test.stopTest();
        
        system.assert(saveResult.success == true, 'Method save failed due to '+ saveResult.messages);
        
        List<Customer_Receipt_Line__c> custReceiptLineList = [select Id,Type__c,Customer_Invoice__c,Customer_Receipt__r.Finalized__c,Amount__c,Has_Exceptions__c from Customer_Receipt_Line__c where Customer_Receipt__c = :custReceipt.Id];
        system.debug(logginglevel.error,'custReceiptLineList-->'+custReceiptLineList);
        system.assert(custReceiptLineList.size() == 3, 'Customer receipt line count does not match: ' + custReceiptLineList.size());
        Boolean earnedDiscountCRLFound;
        Boolean unearnedDiscountCRLFound;
        Boolean paymentCRLFound;
        for(Customer_Receipt_Line__c crLine : custReceiptLineList){  
            if (crLine.Type__c == PaymentService.TYPE_EARNED_DISCOUNT){
                system.assertEquals(crLine.Amount__c, .6, crLine);
                earnedDiscountCRLFound = true;
            }
            else if (crLine.Type__c == PaymentService.TYPE_UNEARNED_DISCOUNT){
                system.assertEquals(crLine.Amount__c, .4, crLine);
                unearnedDiscountCRLFound = true;
            }
            else if (crLine.Type__c == PaymentService.TYPE_PAYMENT){
                system.assertEquals(crLine.Amount__c, 8, crLine);
                paymentCRLFound = true;
            }
        }
        system.assertEquals(paymentCRLFound, true);
        system.assertEquals(earnedDiscountCRLFound, true);
        system.assertEquals(unearnedDiscountCRLFound, true);
        system.assertEquals(custReceiptLineList[0].Customer_Receipt__r.Finalized__c, true);
    }
    
   static testMethod void testGeneralDeductionsWithMissingReasonCode()
    {
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        Customer_Receipt_Line__c deduction = new Customer_Receipt_Line__c();
        deduction.Amount__c = 10;
        deduction.Customer_Receipt__c = custReceipt.Id;
        
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);  
        
        system.assert(deductionLine.Id != null); // Makes sure that the additional payment line is created.
        JSONResult result5 = CustomerReceiptManageExt.getDeductions(custReceipt.Id);
        system.assert(result5.total == 1, 'General Deduction count does not match: ' + result5.total);
        Map<String, List<CustomerReceiptManageExt.DeductionWrapper>> deductionChanges = new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>();
        deductionChanges.put('updatedRows', (List<CustomerReceiptManageExt.DeductionWrapper>) result5.records);
        
        CustomerReceiptManageExt.DeductionWrapper wrapper = new CustomerReceiptManageExt.DeductionWrapper();
        wrapper.deduction = deduction;
        List<CustomerReceiptManageExt.DeductionWrapper> deductionsList = new List<CustomerReceiptManageExt.DeductionWrapper>();
        deductionsList.add(wrapper);
        deductionChanges.put('newRows', deductionsList);
        
        Test.startTest();
        JSONResult  saveResult = CustomerReceiptManageExt.save(custReceipt, null,  new Map<String,List<CustomerReceiptManageExt.CreditMemoWrapper>>(), deductionChanges, new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>(),
                                                                 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>());
        Test.stopTest();
        
        system.assert(saveResult.success == false, 'Method should pass with CR having exceptions');
        List<Map<String,String>> msgLst = saveResult.messages;
        if(msgLst != null && msgLst.size() > 0){
            Map<String,String> messageMap = new Map<String,String>();
            messageMap = msgLst[0];
            system.assert(messageMap.get('message').contains('The Reason Code for a deduction is required.'));
            
        }
        
        
    }
    
  static testMethod void testUnApplyCI_AmountApplied(){ //OTC-501
        
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        
        
        system.assert(CustomerInvoice.id != null);
        system.assert(paymentLine.id != null);
        system.assert(writeoff.id != null);
        system.assert(unearned.id != null);
        system.assert(invDeductionLine.id != null);
        invDeductionLine.Amount__c =1;
        update invDeductionLine;
      	CustomerInvoice.Finalized__c =true;
      	update CustomerInvoice;
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>> CIChanges = new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>();
        CIChanges.put('updatedRows', (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>) CIresult.records);
    
        Test.startTest();
        custReceipt.Amount_received__c = 208;
        custReceipt.Bank_Account_2__c =  globalTestData.bankAccount.Id;
        custReceipt.Payment_Method_G__c = 'Cash';
        custReceipt.Reference_Number__c = '123';
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null,  new Map<String,List<CustomerReceiptManageExt.CreditMemoWrapper>>(), new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>() , CIchanges,
        														 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>());
       
        
        system.assert(saveResult.success == true, 'Method save failed due to '+ saveResult.messages);
        list<Customer_Receipt_Line__c> crl = [select id, Type__c, Amount__c from Customer_Receipt_Line__c where Customer_Receipt__c = :custReceipt.id];
        system.debug(crl);
        system.assert(crl.size() == 5,crl);
        
        
        CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id,Date.today());
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        CIChanges = new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>();
        CustomerReceiptManageExt.CustomerInvoiceWrapper  ciw= (CustomerReceiptManageExt.CustomerInvoiceWrapper) CIResult.records[0];
        ciw.customerInvoice.Amount_Applied__c =0;
        CIChanges.put('updatedRows', (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>) CIresult.records);
        system.debug('inside test: '+CIresult.records);
       
        CustomerReceiptService.isCodeExecuted =false; //Since in real use cases this will occur acros multipe execution cycle. 
        custReceipt = [Select Id From Customer_Receipt__c where id = :custReceipt.Id limit 1];
        custReceipt.Amount_Received__c = 208;
        
        JSONResult  saveResult1 = CustomerReceiptManageExt.save(custReceipt, null, new Map<String,List<CustomerReceiptManageExt.CreditMemoWrapper>>(), new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>() , CIchanges,
        														 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>());
        system.debug(logginglevel.error, saveResult1);
        system.assert(saveResult1.success == false,'The amount applied is greater than zero, failed due to'+ saveResult1);
        Test.stopTest();
        
    }



    static testMethod void testGetCustomerInvoicesData_Discount(){ //KNDY-17349
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(CustomerInvoice.id != null);
        CustomerInvoice.Finalized__c =true;
		update CustomerInvoice;

        Decimal expectedCIEarnedDiscount = 0;
        Decimal expectedCIUnearnedDiscount = 0;

        // payment date is within the discount period
        Date paymentDate = CustomerReceiptManageExt.getDateFromDateTime(CustomerInvoice.Date_Invoiced__c);
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, paymentDate);
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        CustomerReceiptManageExt.CustomerInvoiceWrapper ciw= (CustomerReceiptManageExt.CustomerInvoiceWrapper) CIresult.records[0];
        Customer_Invoice__c ci = (Customer_Invoice__c) (ciw.customerInvoice);
        expectedCIEarnedDiscount = ci.Balance__c * (.02); // 2% of balance
        system.assertEquals(ciw.ciEarnedDiscountAmount, expectedCIEarnedDiscount, ciw );
        system.assertEquals(ciw.ciUnearnedDiscountAmount, expectedCIUnearnedDiscount, ciw);
        // payment date is outside the discount period
        paymentDate = CustomerReceiptManageExt.getDateFromDateTime(CustomerInvoice.Date_Invoiced__c + 11);
        CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, paymentDate);
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        ciw= (CustomerReceiptManageExt.CustomerInvoiceWrapper) CIresult.records[0];
        ci = (Customer_Invoice__c) (ciw.customerInvoice);
        expectedCIEarnedDiscount = 0;
        system.assertEquals(ciw.ciEarnedDiscountAmount, expectedCIEarnedDiscount, ciw );
        system.assertEquals(ciw.ciUnearnedDiscountAmount, expectedCIUnearnedDiscount, ciw);
    }

	static testMethod void testGetCustomerInvoicesData_BlankPaymentTerm(){ //KNDY-17349
		system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
		system.assert(CustomerInvoice.id != null);
		CustomerInvoice.Finalized__c =true;
		CustomerInvoice.Payment_Term__c = null;
		update CustomerInvoice;

		Decimal expectedCIEarnedDiscount = 0;
		Decimal expectedCIUnearnedDiscount = 0;

		// payment date is within the discount period
		Date paymentDate = CustomerReceiptManageExt.getDateFromDateTime(CustomerInvoice.Date_Invoiced__c);
		JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, paymentDate);
		system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
		CustomerReceiptManageExt.CustomerInvoiceWrapper ciw= (CustomerReceiptManageExt.CustomerInvoiceWrapper) CIresult.records[0];
		Customer_Invoice__c ci = (Customer_Invoice__c) (ciw.customerInvoice);
		system.assertEquals(ciw.ciEarnedDiscountAmount, 0, ciw );
		system.assertEquals(ciw.ciUnearnedDiscountAmount, expectedCIUnearnedDiscount, ciw);
		// payment date is outside the discount period
		paymentDate = CustomerReceiptManageExt.getDateFromDateTime(CustomerInvoice.Date_Invoiced__c + 11);
		CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, paymentDate);
		system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
		ciw= (CustomerReceiptManageExt.CustomerInvoiceWrapper) CIresult.records[0];
		ci = (Customer_Invoice__c) (ciw.customerInvoice);
		expectedCIEarnedDiscount = 0;
		system.assertEquals(ciw.ciEarnedDiscountAmount, expectedCIEarnedDiscount, ciw );
		system.assertEquals(ciw.ciUnearnedDiscountAmount, expectedCIUnearnedDiscount, ciw);
	}
    
    // partailly paid ci with no discount line
    static testMethod void testPartialPaymentCI_Discount(){//KNDY-17349
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        
        system.assert(CustomerInvoice.id != null);
        system.assert(paymentLine.id != null);
        CustomerInvoice.Finalized__c =true;
        update CustomerInvoice;
        custReceipt.Amount_Received__c = 50;
        custReceipt.Finalized__c = true;
        update custReceipt;
        Decimal expectedCIEarnedDiscount = 0;
        Decimal expectedCIUnearnedDiscount = 0;
        
        // payment date is within the discount period
        // and ci is partially paid
        Date paymentDate = CustomerReceiptManageExt.getDateFromDateTime(CustomerInvoice.Date_Invoiced__c);
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, paymentDate);
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        CustomerReceiptManageExt.CustomerInvoiceWrapper ciw= (CustomerReceiptManageExt.CustomerInvoiceWrapper) CIresult.records[0];
        Customer_Invoice__c ci = (Customer_Invoice__c) (ciw.customerInvoice);
        system.assertEquals(ciw.ciEarnedDiscountAmount, expectedCIEarnedDiscount, ciw );
        system.assertEquals(ciw.ciUnearnedDiscountAmount, expectedCIUnearnedDiscount, ciw);
    }

    // partailly paid ci with discount line
    static testMethod void testPartialPaymentCIWithDiscountLine(){//KNDY-17349
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        
        system.assert(CustomerInvoice.id != null);
        system.assert(paymentLine.id != null); 
        Customer_Receipt_Line__c  earned = new Customer_Receipt_Line__c();
        earned.Amount__c = 1;
        earned.Customer_Receipt__c = custReceipt.Id;
        earned.Customer_Invoice__c = CustomerInvoice.Id;
        earned.Type__c = PaymentService.TYPE_EARNED_DISCOUNT;
        insert earned;
        CustomerInvoice.Finalized__c =true;
        update CustomerInvoice;
        custReceipt.Amount_Received__c = 50;
        custReceipt.Finalized__c = true;
        update custReceipt;
        Decimal expectedCIEarnedDiscount = 1;
        Decimal expectedCIUnearnedDiscount = 0;
        
        // payment date is outside the discount period
        // and ci is partially paid
        Date paymentDate = CustomerReceiptManageExt.getDateFromDateTime(CustomerInvoice.Date_Invoiced__c + 11);
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, paymentDate);
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        CustomerReceiptManageExt.CustomerInvoiceWrapper ciw= (CustomerReceiptManageExt.CustomerInvoiceWrapper) CIresult.records[0];
        Customer_Invoice__c ci = (Customer_Invoice__c) (ciw.customerInvoice);
        system.assertEquals(ciw.ciEarnedDiscountAmount, expectedCIEarnedDiscount, ciw );
        system.assertEquals(ciw.ciUnearnedDiscountAmount, expectedCIUnearnedDiscount, ciw);
    }
    
   static testMethod void testCreditMemos() // JIRA OTC-319
    {
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        
        
        system.assert(creditMemo.Id != null); // Makes sure that the credit memo is created.
        creditMemo.Finalized__c = true;
        update creditMemo;
        JSONResult result2 = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
        system.assert(result2.total == 1, 'Credit memo count does not match: ' + result2.total);
        
        List<CustomerReceiptManageExt.CreditMemoWrapper> creditMemoWrappers = (List<CustomerReceiptManageExt.CreditMemoWrapper>)result2.records;
        
        
        boolean flag =false;
        
        for(CustomerReceiptManageExt.CreditMemoWrapper creditMemoWrapper : creditMemoWrappers)
        {
        	//system.debug('Balance: '+ creditmemoWrapper.creditMemo.Balance__c );
        	if(creditmemoWrapper.creditMemo.Balance__c >=0)
        	{
        		flag=true;
        		break;
        	}
        }
        
        system.assert(flag == false, 'CreditMemoWrappers contains positive memos.');
         
    }
    
    static testMethod void testSaveCreditMemosWithWriteOff()
    {
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id, '');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
         
        system.assert(creditMemo.Id != null); // Makes sure that the credit memo is created.
        creditMemo.Finalized__c = true;
        update creditMemo;
        
        
        JSONResult result2 = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
        system.assert(result2.total == 1, 'Credit memo count does not match: ' + result2.total);
        System.debug(logginglevel.error,'result2---->'+result2);
        
        for(CustomerReceiptManageExt.CreditMemoWrapper cmwrapper : (List<CustomerReceiptManageExt.CreditMemoWrapper>)result2.records){
                cmwrapper.creditMemo.Amount_To_Apply__c = 5;
                cmwrapper.creditMemo.Write_Off_Amount__c = 5;
                cmwrapper.creditMemo.Resolution_Code__c = globalTestData.resolutionCode.Id;
        }
        
        Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>> creditMemoChanges = new Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>>();
        creditMemoChanges.put('updatedRows', (List<CustomerReceiptManageExt.CreditMemoWrapper>) result2.records);
        
        Test.startTest();
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null, creditMemoChanges, new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>() , new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>(),
                                                                 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>());
        System.debug(logginglevel.error,'saveResult--->'+saveResult);
        Test.stopTest();
       
        system.assert(saveResult.success == true, 'Method save failed due to '+ saveResult.messages); 
        
        List<Customer_Receipt_Line__c> custReceiptLineList = [select Id,Reason_Code__c,Type__c,Finalized__c,Amount__c,Has_Exceptions__c  from Customer_Receipt_Line__c where Customer_Receipt__c = :custReceipt.Id and Type__c = 'Writeoff Credit'];
        system.debug(logginglevel.error,'custReceiptLineList-->'+custReceiptLineList);
        for(Customer_Receipt_Line__c crLine : custReceiptLineList){
            system.assert(crLine.Type__c == PaymentService.TYPE_WRITEOFF_CREDIT,'The customer receipt is not of Writeoff type');
            system.assert(crLine.Reason_Code__c == globalTestData.resolutionCode.Id,'The Customer Receipt is not of valid resaon code');
        }
    } 
    
     static testMethod void testSaveCreditMemosWithWriteOffandZeroAmounttoApply()
    {
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id, '');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
         
        system.assert(creditMemo.Id != null); // Makes sure that the credit memo is created.
        creditMemo.Finalized__c = true;
        update creditMemo;
        
        
        JSONResult result2 = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
        system.assert(result2.total == 1, 'Credit memo count does not match: ' + result2.total);
        System.debug(logginglevel.error,'result2---->'+result2);
        
        for(CustomerReceiptManageExt.CreditMemoWrapper cmwrapper : (List<CustomerReceiptManageExt.CreditMemoWrapper>)result2.records){
                cmwrapper.creditMemo.Amount_To_Apply__c = 0;
                cmwrapper.creditMemo.Write_Off_Amount__c = 5;
                cmwrapper.creditMemo.Resolution_Code__c = globalTestData.resolutionCode.Id;
        }
        
        Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>> creditMemoChanges = new Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>>();
        creditMemoChanges.put('updatedRows', (List<CustomerReceiptManageExt.CreditMemoWrapper>) result2.records);
        
        Test.startTest();
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null, creditMemoChanges, new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>() , new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>(),
                                                                 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>());
        System.debug(logginglevel.error,'saveResult--->'+saveResult);
        Test.stopTest();
       
        system.assert(saveResult.success == true, 'Method save failed due to '+ saveResult.messages); 
    }
    
    static testMethod void testNegativeInvoiceDeductions() 
    {
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);  
        
        
       	system.assert(CustomerInvoice.id != null);
       	system.assert(invDeductionLine.id != null);
       	CustomerInvoice.Finalized__c =true;
      	update CustomerInvoice;
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>> CIChanges = new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>();
        CIChanges.put('updatedRows', (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>) CIresult.records);
        
         system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
       
        Test.startTest();
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt,  null, null, null, CIchanges, null, null);
        Test.stopTest();
        
        system.assert(saveResult.success == false, 'Method save failed due to '+ saveResult.messages);
         
    }
    
   
    static testMethod void testFinalizedCIs()
    {
    	Customer_Invoice__c CustomerInvoice1 = new Customer_Invoice__c();
		CustomerInvoice1.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        CustomerInvoice1.Company__c = globalTestData.company.Id;
        CustomerInvoice1.Customer_Receipt__c = custReceipt.Id;
        CustomerInvoice1.Invoice_Type__c = 'Ship INvoice';
        CustomerInvoice1.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice1.Date_Invoiced__c = system.now();
        CustomerInvoice1.Currency__c = custReceipt.Currency__c;
		
		insert CustomerInvoice1;
    	
    	system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);  
        
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        system.assert(CIresult.total == 0,'Customer Invoice count does not match ' + CIresult.total);
        
    }
    
    static testMethod void testAdditionalPaymentsWithMissingType() //OTC-679
    {
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	Customer_Receipt_Line__c prepayment = new Customer_Receipt_Line__c();
		prepayment.Amount__c = 10;
		prepayment.Customer_Receipt__c = custReceipt.Id;
		//prepayment.Customer__c = globalTestData.customerBillTo.id;
		//insert prepayment;
    	
    	system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);  
        
        system.assert(OverPaymentLine.Id != null); // Makes sure that the additional payment line is created.
        JSONResult result5 = CustomerReceiptManageExt.getAdditionalPayments(custReceipt.Id);
        system.assert(result5.total == 1, 'Additional payments count does not match: ' + result5.total);
        Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>> additionalPaymentChanges = new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>();
        additionalPaymentChanges.put('updatedRows', (List<CustomerReceiptManageExt.AdditionalPaymentWrapper>) result5.records);
        
        CustomerReceiptManageExt.AdditionalPaymentWrapper wrapper = new CustomerReceiptManageExt.AdditionalPaymentWrapper();
        wrapper.additionalPayment = prepayment; 
        List<CustomerReceiptManageExt.AdditionalPaymentWrapper> additionalPaymentsList = new List<CustomerReceiptManageExt.AdditionalPaymentWrapper>();
        additionalPaymentsList.add(wrapper);
        additionalPaymentChanges.put('newRows', additionalPaymentsList);
        
        Test.startTest();
        JSONResult  saveResult = CustomerReceiptManageExt.save(custReceipt, null,  new Map<String,List<CustomerReceiptManageExt.CreditMemoWrapper>>(), new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>() , new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>(),
        														 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), additionalPaymentChanges);
        Test.stopTest();
        
        system.assert(saveResult.success == false, 'Method should pass with CR having exceptions');
        
        
    }
    
    static testMethod void testVoidCIs()
    {
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	Customer_Invoice__c CustomerInvoice1 = new Customer_Invoice__c();
		CustomerInvoice1.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        CustomerInvoice1.Company__c = globalTestData.company.Id;
        CustomerInvoice1.Customer_Receipt__c = custReceipt.Id;
        CustomerInvoice1.Invoice_Type__c = 'Ship INvoice';
        CustomerInvoice1.Status__c = 'Void';
        CustomerInvoice1.Date_Invoiced__c = system.now();
        CustomerInvoice1.Currency__c = custReceipt.Currency__c;
		CustomerInvoice1.Transaction_Date__c = system.now();
		insert CustomerInvoice1;
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice1.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		CustomerInvoice1.Finalized__c = true;
		update CustomerInvoice1;
    	
    	system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);  
        
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        system.assert(CIresult.total == 0,'Customer Invoice count does not match ' + CIresult.total);
        
    }
    
    
    static testMethod void testVoidCreditMemos()
    {
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	Customer_Invoice__c CustomerInvoice1 = new Customer_Invoice__c();
		CustomerInvoice1.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        CustomerInvoice1.Company__c = globalTestData.company.Id;
        CustomerInvoice1.Customer_Receipt__c = custReceipt.Id;
        CustomerInvoice1.Invoice_Type__c = 'Manual';
        CustomerInvoice1.Status__c = 'Void';
        CustomerInvoice1.Date_Invoiced__c = system.now();
        CustomerInvoice1.Currency__c = custReceipt.Currency__c;
		CustomerInvoice1.Transaction_Date__c = system.now();
		
		insert CustomerInvoice1;
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice1.Id;
		cil.Quantity_Shipped__c = -1;
		cil.Unit_Price__c = 100;
		insert cil;
		CustomerInvoice1.Finalized__c = true;
		update CustomerInvoice1;
    	
    	system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);  
        
        JSONResult CIresult = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
        system.assert(CIresult.total == 0,'Customer Invoice count does not match ' + CIresult.total);
        
    }
    
    static testMethod void testCancelledClaims()
    {
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	system.assert(claim.Id != null);
    	claim.Status__c = 'Cancelled';
    	update claim;
    	JSONResult result4 = CustomerReceiptManageExt.getClaims(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
        system.assert(result4.total == 0, 'Claims count does not match: ' + result4.total);
    }
     
    static testMethod void Prepayments_Finalized() { 
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	system.assertNotEquals(null,custReceipt.Id);
    	
    	system.assert(PrePaymentLine.Id != null); // Makes sure that the additional payment line is created.
        JSONResult result5 = CustomerReceiptManageExt.getAdditionalPayments(custReceipt.Id);
        system.assert(result5.total == 1, 'Additional payments count does not match: ' + result5.total);
        Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>> additionalPaymentChanges = new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>();
        additionalPaymentChanges.put('updatedRows', (List<CustomerReceiptManageExt.AdditionalPaymentWrapper>) result5.records);
        
        custReceipt.Amount_Received__c = 208;
        custReceipt.Payment_Method_G__c = 'Cash';
        custReceipt.Reference_Number__c = '123';
        custReceipt.Bank_Account_2__c =  globalTestData.bankAccount.Id;
        JsonResult saveResult = CustomerReceiptManageExt.save(custReceipt, null,  new Map<String,List<CustomerReceiptManageExt.CreditMemoWrapper>>(), new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>() , new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>(),
        														 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), additionalPaymentChanges);
      	
      	
        system.assertEquals(true, saveResult.success,'Why did it  fail: '+saveResult.messages);
        custReceipt = [Select Id, (Select Id, Sales_Order__c, INvoice_Type__c From Customer_Invoices__r), Finalized__c, Amount_Received__c from Customer_Receipt__c where Id = :custReceipt.ID limit 1];
        system.assertEquals(true, custReceipt.Finalized__c);
    	system.assertEquals(1, custReceipt.Customer_Invoices__r.size());
    	system.assertEquals('Prepayment',custReceipt.Customer_Invoices__r[0].INvoice_Type__c);
    	system.assertEquals(globalTestData.salesOrder.Id,custReceipt.Customer_Invoices__r[0].Sales_Order__c);
    	
    	globalTestData.salesOrder = [Select Id, Prepayments_Received__c from Sales_Order__c where id = :globalTestData.salesOrder.Id limit 1];
    	system.assertEquals(PrePaymentLine.Amount__c,globalTestData.salesOrder.Prepayments_Received__c);
    	
    }
    
    static testMethod void DontLoadCreditMemos() {//KNDY-10389
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	
    	List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
    	List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
    	Customer_Invoice__c creditMemo1 = new Customer_Invoice__c();
		creditMemo1.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        creditMemo1.Company__c = globalTestData.company.Id;
        creditMemo1.Customer_Receipt__c = custReceipt.Id;
        creditMemo1.Invoice_Type__c = 'Credit Memo';
        creditMemo1.Status__c = CustomerInvoiceService.STATUS_OPEN;
        creditMemo1.Date_Invoiced__c = system.now();
        creditMemo1.Currency__c = custReceipt.Currency__c;
		creditMemo1.Transaction_Date__c = system.now();
		cis.add(creditMemo1);
    	Customer_Invoice__c allowanceAccrualCI = new Customer_Invoice__c();
		allowanceAccrualCI.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        allowanceAccrualCI.Company__c = globalTestData.company.Id;
        allowanceAccrualCI.Customer_Receipt__c = custReceipt.Id;
        allowanceAccrualCI.Invoice_Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL;
        allowanceAccrualCI.Status__c = CustomerInvoiceService.STATUS_OPEN;
        allowanceAccrualCI.Date_Invoiced__c = system.now();
        allowanceAccrualCI.Currency__c = custReceipt.Currency__c;
		allowanceAccrualCI.Transaction_Date__c = system.now();
		cis.add(allowanceAccrualCI);
		
		insert cis;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = creditMemo1.Id;
		cil.Quantity_Shipped__c = -1;
		cil.Unit_Price__c = 10;
		cils.add( cil);
		Customer_Invoice_Line__c aa_cil = new Customer_Invoice_Line__c();
		aa_cil.Customer_Invoice__c = allowanceAccrualCI.Id;
		aa_cil.Quantity_Shipped__c = -1;
		aa_cil.Unit_Price__c = 10;
		cils.add(aa_cil);
		insert cils;
		
		creditMemo1.Finalized__c = true;
		allowanceAccrualCI.Finalized__c = true;
		update cis;
		
		Customer__c customerParent = new Customer__c(); 
        customerParent.name = globalTestData.company.Name + ' Customer Corp Parent 11';
        customerParent.recordTypeId = globalTestData.CustomerRecordTypes.get('Corporate_Parent');
        customerParent.Company__c = globalTestData.company.id;
        customerParent.Payment_Term__c = globalTestData.terms.ID;
        customerParent.Address__c = globalTestData.account.ID;
        customerParent.Credit_Limit__c = 100000.0;
        customerParent.Customer_Identifier__c = 'CPTEST1231212';
        customerParent.Record_Type_Name__c = 'Corporate_Parent'; 
        customerParent.Status__c = 'Approved';
        insert customerParent;
		
		
		custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = globalTestData.company.Id;
		custReceipt.Customer__c = globalTestData.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = globalTestData.currencyUSD.id;
		//custReceipt.Amount_Unapplied__c =0; // as this field is manipulated on the client side. 
		insert custReceipt;
		
		Test.startTest();
		// Customer is different on both CIs
		JSONResult result2 = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
		system.assertEquals(0,result2.records.size());
		
		//KNDY-15037 Page not launched from CR, Allowance Accrual CI should not be included
		JSONResult result3 = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, globalTestData.customerBillTo.Id, custReceipt.Currency__c,null);
		system.assertEquals(1,result3.records.size(), '>>>> result3: ' + result3);
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = custReceipt.Id;
		crl.Type__c = PaymentService.TYPE_CREDIT_MEMO;
		crl.Customer_Invoice__c = allowanceAccrualCI.Id; //KNDY-13995
		insert crl;
		//KNDY-15037 Page launched from CR, Allowance Accrual CI should not be included
		JSONResult result4 = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, globalTestData.customerBillTo.Id, custReceipt.Currency__c,custReceipt.Id);
		system.assertEquals(1,result4.records.size(), '>>>> result4: ' + result4);
		
		Test.stopTest();
    }
    
    static testMethod void DontLoadCustomerInvoicess() {//KNDY-10389
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	
    	
    	Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
		custInvoice1.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        custInvoice1.Company__c = globalTestData.company.Id;
        custInvoice1.Customer_Receipt__c = custReceipt.Id;
        custInvoice1.Invoice_Type__c = 'Credit Memo';
        custInvoice1.Status__c = CustomerInvoiceService.STATUS_OPEN;
        custInvoice1.Date_Invoiced__c = system.now();
        custInvoice1.Currency__c = custReceipt.Currency__c;
		custInvoice1.Transaction_Date__c = system.now();
		insert custInvoice1;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = custInvoice1.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 10;
		insert cil;
		
		custInvoice1.Finalized__c = true;
		update custInvoice1;
		
		Customer__c customerParent = new Customer__c(); 
        customerParent.name = globalTestData.company.Name + ' Customer Corp Parent 11';
        customerParent.recordTypeId = globalTestData.CustomerRecordTypes.get('Corporate_Parent');
        customerParent.Company__c = globalTestData.company.id;
        customerParent.Payment_Term__c = globalTestData.terms.ID;
        customerParent.Address__c = globalTestData.account.ID;
        customerParent.Credit_Limit__c = 100000.0;
        customerParent.Customer_Identifier__c = 'CPTEST1231212';
        customerParent.Record_Type_Name__c = 'Corporate_Parent'; 
        customerParent.Status__c = 'Approved';
        insert customerParent;
		
		
		custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = globalTestData.company.Id;
		custReceipt.Customer__c = globalTestData.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = globalTestData.currencyUSD.id;
		//custReceipt.Amount_Unapplied__c =0; // as this field is manipulated on the client side. 
		insert custReceipt;
		
		JSONResult result2 = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
		system.assertEquals(0,result2.records.size());
		
	
    }

    static testMethod void testCurrencyChangeOnCustomerRecipt(){
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        
        Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        custInvoice1.Company__c = globalTestData.company.Id;
        custInvoice1.Customer_Receipt__c = custReceipt.Id;
        custInvoice1.Invoice_Type__c = 'Credit Memo';
        custInvoice1.Status__c = CustomerInvoiceService.STATUS_OPEN;
        custInvoice1.Date_Invoiced__c = system.now();
        custInvoice1.Currency__c = globalTestData.currencyUSD.id;
        custInvoice1.Transaction_Date__c = system.now();
        insert custInvoice1;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
        cil.Customer_Invoice__c = custInvoice1.Id;
        cil.Quantity_Shipped__c = 1;
        cil.Unit_Price__c = 10;
        insert cil;
        
        custInvoice1.Finalized__c = true;
        update custInvoice1;
        
        custReceipt = new Customer_Receipt__c(); 
        custReceipt.Company__c = globalTestData.company.Id;
        custReceipt.Customer__c = globalTestData.customerParent.Id;
        custReceipt.Date_Received__c = system.now();
        custReceipt.Type__c = 'Receipt';
        custReceipt.Currency__c = globalTestData.currencyUSD.id; 
 		insert custReceipt;
        
       
        Customer_Invoice__c custInvoice2 = new Customer_Invoice__c();
        custInvoice2.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        custInvoice2.Company__c = globalTestData.company.Id;
        custInvoice2.Customer_Receipt__c = custReceipt.Id;
        custInvoice2.Invoice_Type__c = 'Credit Memo';
        custInvoice2.Status__c = CustomerInvoiceService.STATUS_OPEN;
        custInvoice2.Date_Invoiced__c = system.now();
        custInvoice2.Currency__c = globalTestData.currencyGBP.id; 
        custInvoice2.Transaction_Date__c = system.now();
        insert custInvoice2;
        
        Customer_Invoice_Line__c cil1 = new Customer_Invoice_Line__c();
        cil1.Customer_Invoice__c = custInvoice2.Id;
        cil1.Quantity_Shipped__c = 1;
        cil1.Unit_Price__c = 10;
        insert cil1;
        
        custInvoice2.Finalized__c = true;
        custInvoice2.Currency__c = globalTestData.currencyGBP.id; 
        update custInvoice2;
        
        Customer_Receipt__c custReceipt1 = new Customer_Receipt__c();
        custReceipt1.Company__c = globalTestData.company.Id;
        custReceipt1.Customer__c = globalTestData.customerParent.Id; 
        custReceipt1.Date_Received__c = system.now();
        custReceipt1.Type__c = 'Receipt';
        custReceipt1.Currency__c = globalTestData.currencyGBP.id;
        insert custReceipt1;
        
        deductionLine = new Customer_Receipt_Line__c();
        deductionLine.Amount__c = -100;
        deductionLine.Customer_Receipt__c = custReceipt1.Id;
        deductionLine.Reason_Code__c = globalTestData.deductionCode.Id;
        deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
        deductionLine.Customer__c = globalTestData.customerBillTo.Id;
        deductionLine.Sold_To_Customer__c = globalTestData.customerSoldTo.Id;
        deductionLine.Currency__c = globalTestData.currencyGBP.id;        
        insert deductionLine;
        
        Customer_Receipt__c custReceipt2 = new Customer_Receipt__c();
        custReceipt2.Company__c = globalTestData.company.Id;
        custReceipt2.Customer__c = globalTestData.customerParent.Id; 
        custReceipt2.Date_Received__c = system.now();
        custReceipt2.Type__c = 'Credit Memo';
        custReceipt2.Currency__c = globalTestData.currencyGBP.id;
        insert custReceipt2;
        
        Customer_Receipt_Line__c cdtMemocrline = new Customer_Receipt_Line__c();
        cdtMemocrline.Amount__c =10;
        cdtMemocrline.Customer_Receipt__c = custReceipt2.Id;
        cdtMemocrline.Type__c = PaymentService.TYPE_CREDIT_MEMO;
        cdtMemocrline.Customer_Invoice__c = custInvoice2.Id; //KNDY-13995
        cdtMemocrline.Customer__c = globalTestData.customerBillTo.id;
        cdtMemocrline.Currency__c = globalTestData.currencyGBP.id;
        insert cdtMemocrline;
        
        Customer_Receipt_Line__c overPymtcrline = new Customer_Receipt_Line__c();
        overPymtcrline.Amount__c =10;
        overPymtcrline.Customer_Receipt__c = custReceipt2.Id;
        overPymtcrline.Type__c = PaymentService.TYPE_OVERPAYMENT;
		overPymtcrline.Customer__c = globalTestData.customerBillTo.id;
        overPymtcrline.Currency__c = globalTestData.currencyGBP.id;		
        insert overPymtcrline;
       

        JSONResult ciResult1 = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        system.assert(ciResult1.total == 1,'Customer Invoice count in USD does not match ' + ciResult1.total);
        
        JSONResult ciResult2 = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt1.Currency__c, custReceipt1.Id, Date.today());
        system.assert(ciResult2.total == 1,'Customer Invoice count in GBP does not match ' + ciResult2.total);
        
        JSONResult result3 = CustomerReceiptManageExt.getDeductions(custReceipt.Id); 
        system.assert(result3.total == 0, 'Deduction count in USD does not match: ' + result3.total);
        
        JSONResult result4 = CustomerReceiptManageExt.getDeductions(custReceipt1.Id); 
        system.assert(result4.total == 1, 'Deduction count in GBP does not match: ' + result4.total);
        
        JSONResult result5 = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt2.Currency__c, custReceipt2.Id);
        system.assert(result5.total == 1, 'Credit memo count in GBP does not match: ' + result5.total); 
        
        JSONResult result6 = CustomerReceiptManageExt.getAdditionalPayments(custReceipt2.Id);
        system.assert(result6.total == 1, 'Additional payments in GBP count does not match: ' + result6.total);
        
    }   

    
    static testMethod void testAdditionalPaymentsWithoutMatchingCurrency() //KNDY-11566
    {
        
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	
        globalTestData.salesOrder.Currency__c = globalTestData.currencyUSD.id;
        update globalTestData.salesOrder;
            
        Customer_Receipt_Line__c prepayment = new Customer_Receipt_Line__c();
		prepayment.Amount__c = 10;
		prepayment.Customer_Receipt__c = custReceipt.Id;
        prepayment.Sales_Order__c = globalTestData.salesOrder.Id; // Sales Order Transaction Currency is USD
        prepayment.Type__c = PaymentService.TYPE_PREPAYMENT;
		prepayment.Customer__c = globalTestData.customerSoldTo.id;

    	system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        
        Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>> additionalPaymentChanges = new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>();
        CustomerReceiptManageExt.AdditionalPaymentWrapper wrapper = new CustomerReceiptManageExt.AdditionalPaymentWrapper();
        wrapper.additionalPayment = prepayment;
        List<CustomerReceiptManageExt.AdditionalPaymentWrapper> additionalPaymentsList = new List<CustomerReceiptManageExt.AdditionalPaymentWrapper>();
        additionalPaymentsList.add(wrapper);
        additionalPaymentChanges.put('newRows', additionalPaymentsList);
        
        Test.startTest(); 
        JSONResult  saveResult = CustomerReceiptManageExt.save(custReceipt, null,  new Map<String,List<CustomerReceiptManageExt.CreditMemoWrapper>>(), new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>() , new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>(),
        														 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), additionalPaymentChanges);
        Test.stopTest();
        system.assert(saveResult.success == false, 'Method should pass with CR having exceptions');
        
    }
    
    
    static testMethod void DontLoadClaims() {//KNDY-10759
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	List<Claim__c> claims = new List<Claim__c>();
    	
    	Claim__c claim1 = new Claim__c();
		claim1.Company__c = globalTestData.company.Id;
		claim1.Parent_Customer__c = globalTestData.customerParent.Id;
		claim1.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
		claim1.Transaction_Currency__c = 'USD';
		claim1.Amount__c = 20;
		claim1.Type__c = PaymentService.TYPE_GEN_DED;
		claim1.Status__c = 'Open';
		claim1.Approval_Status__c = 'Approved';
		claims.add(claim1);
		Claim__c manualClaim = new Claim__c(); //KNDY-15037
		manualClaim.Company__c = globalTestData.company.Id;
		manualClaim.Parent_Customer__c = globalTestData.customerParent.Id;
		manualClaim.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
		manualClaim.Transaction_Currency__c = 'USD';
		manualClaim.Amount__c = 20;
		manualClaim.Source__c = ClaimService.SOURCE_MANUAL;
		manualClaim.Status__c = 'Open';
		claims.add(manualClaim);
		insert claims;
		
		JSONResult result2 = CustomerReceiptManageExt.getClaims(globalTestData.company.Id, '', '','');
		system.assertEquals(0,result2.records.size());
		
    }
    
    static testMethod void getCompanyCurrency() {
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	
    	JSONresult result = CustomerReceiptManageExt.getCompanyDefaultCurrency(globalTestData.company.Id);
    	system.assertEquals(true,result.success);
    	system.assertEquals(1, result.records.size());
    	Currency__c curr = (Currency__c)result.records[0];
    	system.assertEquals(globalTestData.currencyUSD.Id, curr.Id);
    	
    }
    //KNDY-14482
    static testMethod void getCompanyDefaultBankAndCurrency() {
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	Bank_Account__c bankAccountObj = globalTestData.bankAccount;
    	Company__c currentCompany = globalTestData.company;
        currentCompany.Deposit_Bank_Account__c = bankAccountObj.id;
        update currentCompany;
    	JSONresult result = CustomerReceiptManageExt.getCompanyDefaultBankAndCurrency(globalTestData.company.Id);
    	system.assertEquals(true,result.success);
    	system.assertEquals(1, result.records.size());
    	Company__c companyObj = (Company__c)result.records[0];
    	system.assertEquals(bankAccountObj.id, companyObj.Deposit_Bank_Account__c);
    	//KNDY-18029 - FETCH bank's primary deposti payment method
    	result = CustomerReceiptManageExt.getBankAccountDetails(bankAccountObj.Id);
    	system.assertEquals(result.records.size(),result.total);
    	bankAccountObj = (Bank_Account__c)result.records[0];
    	system.assertEquals(bankAccountObj.Primary_Deposit_Payment_Method__c == null,true,'Deposit payment method associated found : ' + bankAccountObj.Primary_Deposit_Payment_Method__c);
    	//associate payment method
    	bankAccountObj.Primary_Deposit_Payment_Method__c = 'EFT';
    	update bankAccountObj;
    	result = CustomerReceiptManageExt.getBankAccountDetails(bankAccountObj.Id);
    	system.assertEquals(result.records.size(),result.total);
    	bankAccountObj = (Bank_Account__c)result.records[0];    	
    	system.assertEquals(bankAccountObj.Primary_Deposit_Payment_Method__c == 'EFT',true,'Deposit payment method associated found : ' + bankAccountObj.Primary_Deposit_Payment_Method__c);
    	
    	
    }
    
    //KNDY-17347
    static testMethod void testWriteOff_IfAmountAppliedisZero(){
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id, '');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        //custReceipt = (Customer_Receipt__c) result.records[0];
        
         
        system.assert(creditMemo.Id != null); // Makes sure that the credit memo is created.
        creditMemo.Finalized__c = true;
        update creditMemo;
        JSONResult result2 = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
        system.assert(result2.total == 1, 'Credit memo count does not match: ' + result2.total);
        List<CustomerReceiptManageExt.CreditMemoWrapper> rec = (List<CustomerReceiptManageExt.CreditMemoWrapper>)result2.records;
        rec[0].creditMemo.Memo__c = 'Test memo';
        Id creditMemoId = rec[0].creditMemo.id;
        Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>> creditMemoChanges = new Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>>();
        creditMemoChanges.put('updatedRows', (List<CustomerReceiptManageExt.CreditMemoWrapper>) result2.records);
        
        system.assert(deductionLine.Id != null); // Makes sure that the deduction line is created.
        JSONResult result3 = CustomerReceiptManageExt.getDeductions(custReceipt.Id);
        system.assert(result3.total == 1, 'Deduction count does not match: ' + result3.total);
        Map<String, List<CustomerReceiptManageExt.DeductionWrapper>> deductionChanges = new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>();
        deductionChanges.put('updatedRows', (List<CustomerReceiptManageExt.DeductionWrapper>) result3.records);
        
        system.assert(claim.Id != null); // Makes sure that the claim line is created.
        JSONResult result4 = CustomerReceiptManageExt.getClaims(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
        system.assert(result4.total == 1, 'Claims count does not match: ' + result4.total);
        Map<String, List<CustomerReceiptManageExt.ClaimWrapper>> claimChanges = new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>();
        claimChanges.put('updatedRows', (List<CustomerReceiptManageExt.ClaimWrapper>) result4.records);
        
        system.assert(CustomerInvoice.id != null);
        CustomerInvoice.Finalized__c = true;
        update CustomerInvoice;
       
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
       	List<CustomerReceiptManageExt.CustomerInvoiceWrapper> recs = (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>)CIresult.records;
        recs[0].selected = true; 
        recs[0].customerInvoice.Amount_Applied__c = 0; 
        recs[0].customerInvoice.Write_Off_Amount__c = 10;
        recs[0].ciEarnedDiscountAmount = 10;
        recs[0].customerInvoice.Memo__c = 'Test memo';
        Id customerInvoiceId = recs[0].customerInvoice.id;
        System.debug(logginglevel.error,'customerInvoiceId--->'+customerInvoiceId);
        
        Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>> CIChanges = new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>();
        CIChanges.put('updatedRows', (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>) CIresult.records);
        
        
        system.assert(OverPaymentLine.Id != null); // Makes sure that the additional payment line is created.
        JSONResult result5 = CustomerReceiptManageExt.getAdditionalPayments(custReceipt.Id);
        system.assert(result5.total == 1, 'Additional payments count does not match: ' + result5.total);
        Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>> additionalPaymentChanges = new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>();
        additionalPaymentChanges.put('updatedRows', (List<CustomerReceiptManageExt.AdditionalPaymentWrapper>) result5.records);
        
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
        custReceipt.Amount_Received__c = 208;
        custReceipt.Bank_Account_2__c =  globalTestData.bankAccount.Id;
        custReceipt.Payment_Method_G__c = 'Cash';
        custReceipt.Reference_Number__c = '123';
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null, creditMemoChanges, deductionChanges, CIchanges, claimChanges, additionalPaymentChanges);
        
        system.assert(saveResult.success == false, 'Method save failed due to '+ saveResult.messages);
        boolean ErrorExists = false;
        for(Map<String, String> msg :saveResult.messages)
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('You must also include a payment as part of the customer receipt if you wish to provide earned or unearned discounts.')){
	        		ErrorExists = true;
	        		break;
        		}
        	} 
        system.assert(ErrorExists); 
        Test.stopTest(); 
    }
    
    //KNDY-19379
    static testMethod void testCustomerInvoiceWriteOff(){
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id, '');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        
        system.assert(CustomerInvoice.id != null);
        CustomerInvoice.Finalized__c = true;
        update CustomerInvoice;
       
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id, Date.today());
        
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        List<CustomerReceiptManageExt.CustomerInvoiceWrapper> recs = (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>)CIresult.records;
        recs[0].selected = true; 
        recs[0].customerInvoice.Amount_Applied__c = 1; 
        recs[0].customerInvoice.Write_Off_Amount__c = 9;
        recs[0].customerInvoice.Resolution_Code__c = globalTestData.resolutionCode.Id;
        Id customerInvoiceId = recs[0].customerInvoice.id;
        System.debug(logginglevel.error,'customerInvoiceId--->'+customerInvoiceId);
        
        Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>> CIChanges = new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>();
        CIChanges.put('updatedRows', (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>) CIresult.records);
        

        Test.startTest();
        custReceipt.Amount_Received__c = 1;
        custReceipt.Bank_Account_2__c =  globalTestData.bankAccount.Id;
        custReceipt.Payment_Method_2__c = 'Cash';
        custReceipt.Reference_Number__c = '123';
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null,  new Map<String,List<CustomerReceiptManageExt.CreditMemoWrapper>>(),
                                                        new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>() , CIchanges,
                                                         new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), 
                                                         new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>());
        
        system.assert(saveResult.success == true, 'Method save failed due to '+ saveResult.messages);
        
        List<Customer_Receipt_Line__c> custReceiptLineList = [select Id,Reason_Code__c,Type__c,Finalized__c,Amount__c,Has_Exceptions__c,Memo__c  from Customer_Receipt_Line__c where Customer_Receipt__c = :custReceipt.Id ];
        system.debug(logginglevel.error,'custReceiptLineList-->'+custReceiptLineList);
        system.assert(custReceiptLineList.size() != 0, 'Customer receipt line count does not match: ' + custReceiptLineList.size());
        Boolean foundWriteOffLine = false;
        for(Customer_Receipt_Line__c crLine : custReceiptLineList){
            if (crLine.Type__c == PaymentService.TYPE_WRITEOFF){
                foundWriteOffLine = true;
            }
        }
        system.assertEquals(foundWriteOffLine, true,'custReceiptLineList-->'+custReceiptLineList);
        Test.stopTest(); 
    }
    
    //KNDY-17347
     static testMethod void testInvoiceDeduction_IfAmountAppliedisZero(){ 
        
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id,'');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        system.assert(CustomerInvoice.id != null);
        system.assert(paymentLine.id != null);
        system.assert(writeoff.id != null);
        system.assert(unearned.id != null);
        system.assert(invDeductionLine.id != null);
        invDeductionLine.Amount__c =1;
        update invDeductionLine;
      	CustomerInvoice.Finalized__c =true;
      	update CustomerInvoice;
        JSONResult CIresult = CustomerReceiptManageExt.getCustomerInvoices(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id,Date.today());
        system.assert(CIresult.total == 1,'Customer Invoice count does not match ' + CIresult.total);
        
        List<CustomerReceiptManageExt.CustomerInvoiceWrapper> recs = (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>)CIresult.records;
        recs[0].selected = true; 
        recs[0].customerInvoice.Amount_Applied__c = 0; 
        recs[0].ciEarnedDiscountAmount = 10;
        recs[0].customerInvoice.Memo__c = 'Test memo';
        Id customerInvoiceId = recs[0].customerInvoice.id;
        System.debug(logginglevel.error,'customerInvoiceId--->'+customerInvoiceId);
        
        Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>> CIChanges = new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>();
        CIChanges.put('updatedRows', (List<CustomerReceiptManageExt.CustomerInvoiceWrapper>) CIresult.records);
    
        Test.startTest();
        custReceipt.Amount_received__c = 208;
        custReceipt.Bank_Account_2__c =  globalTestData.bankAccount.Id;
        custReceipt.Payment_Method_G__c = 'Cash';
        custReceipt.Reference_Number__c = '123';
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null,  new Map<String,List<CustomerReceiptManageExt.CreditMemoWrapper>>(), new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>() , CIchanges,
        														 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>());//, custReceipt.Amount_received__c);
       
        system.assert(saveResult.success == false, 'Method save failed due to '+ saveResult.messages);
         boolean ErrorExists = false;
        for(Map<String, String> msg :saveResult.messages)
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('You must also include a payment as part of the customer receipt if you wish to provide earned or unearned discounts.')){
	        		ErrorExists = true;
	        		break;
        		}
        	} 
        system.assert(ErrorExists);
        Test.stopTest();
    }
    
    static testMethod void testCreditMemo_FullWriteOff(){
        system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
        system.assert(custReceipt.Id != null); // Makes sure that the customer receipt is created.
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(custReceipt.Id, '');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
         
        system.assert(creditMemo.Id != null); // Makes sure that the credit memo is created.
        creditMemo.Finalized__c = true;
        creditMemo.Memo__c = 'This is the Memo Text Added';  
        update creditMemo;
        
        
        JSONResult result2 = CustomerReceiptManageExt.getCreditMemos(globalTestData.company.Id, globalTestData.customerParent.Id, custReceipt.Currency__c, custReceipt.Id);
        system.assert(result2.total == 1, 'Credit memo count does not match: ' + result2.total);
        System.debug(logginglevel.error,'result2---->'+result2);
        
        for(CustomerReceiptManageExt.CreditMemoWrapper cmwrapper : (List<CustomerReceiptManageExt.CreditMemoWrapper>)result2.records){
                cmwrapper.creditMemo.Amount_To_Apply__c = 0;
                cmwrapper.creditMemo.Write_Off_Amount__c = 10;
                cmwrapper.creditMemo.Resolution_Code__c = globalTestData.resolutionCode.Id;
                System.assert(cmwrapper.creditMemo.Memo__c == creditMemo.Memo__c,'The memo text on the CI is not the same'); //makes sure the memo text on the CI is perculated down
                cmwrapper.creditMemo.Memo__c = 'Updated memo text added'; // Updating the Memo text
         }
         
        Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>> creditMemoChanges = new Map<String, List<CustomerReceiptManageExt.CreditMemoWrapper>>();
        creditMemoChanges.put('updatedRows', (List<CustomerReceiptManageExt.CreditMemoWrapper>) result2.records);
        
        Test.startTest();
        JSONResult saveResult = CustomerReceiptManageExt.save(custReceipt, null, creditMemoChanges, new Map<String, List<CustomerReceiptManageExt.DeductionWrapper>>() , new Map<String, List<CustomerReceiptManageExt.CustomerInvoiceWrapper>>(),
                                                                 new Map<String, List<CustomerReceiptManageExt.ClaimWrapper>>(), new Map<String, List<CustomerReceiptManageExt.AdditionalPaymentWrapper>>()); // 2 CRL gets created
        System.debug(logginglevel.error,'saveResult--->'+saveResult);
        
        Test.stopTest();
       
        system.assert(saveResult.success == true, 'Method save failed due to '+ saveResult.messages); 
        
        List<Customer_Receipt_Line__c> custReceiptLineList = [select Id,Reason_Code__c,Type__c,Finalized__c,Amount__c,Has_Exceptions__c,Memo__c  from Customer_Receipt_Line__c where Customer_Receipt__c = :custReceipt.Id ];
        system.debug(logginglevel.error,'custReceiptLineList-->'+custReceiptLineList);
        system.assert(custReceiptLineList.size() == 1, 'Customer receipt line count does not match: ' + custReceiptLineList.size());
        for(Customer_Receipt_Line__c crLine : custReceiptLineList){
            system.assert(crLine.Memo__c == 'Updated memo text added',' The Customer Receipt Line does not have the memo text as updated ');
        }
    }
}