/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class RefundCreditManageTest { 
    
    @testSetup static void ts() { 
        TestFuel data = new TestFuel(); 
        // these asserts cause TestFuelQuery to insert data
        system.assert(      
            data.company != null &&
            data.customerParent != null &&
            data.customerBillTo != null &&
            data.product != null &&
            data.bankAccount != null &&
            data.salesOrder != null &&
            data.salesOrderLines != null &&
            data.paymentProfile != null &&
            data.paymentMethod != null &&
            data.periodList != null &&
            data.accountingStandard != null &&
            data.receivablesGL != null &&
            TestFuel.currencyGBP != null
            
        );
    }
    
    
     public class MockRestServiceResponse implements HttpCalloutMock {
        
        public HttpResponse respond(HttpRequest req) {
            
            string xmlBody = req.getBody();
            Dom.Document doc = new Dom.Document();
            doc.load(xmlBody);
            Dom.XMLNode reqRoot = doc.getRootElement();
            string reqRootName = reqRoot.getName();
            system.debug('reqRootName: ' + reqRootName);
            
            HttpResponse resp = new HttpResponse();
            resp.setHeader('Content-Type', 'text/xml');
            resp.setStatusCode(200);
            resp.setBody(requestResponseBodies.get(reqRootName));
            return resp;
        }
    }
    
    class RefundCreditManageExtTestData {
        
        private SchemaUtil util = SchemaUtil.getInstance();
        TestFuelQuery fuel = new TestFuelQuery();
            
        public RefundCreditManageExtTestData() {
            
        }
        
        public Company__c company = fuel.company; 
        public Customer__c customerParent = fuel.customerParent;
        public Customer__c customerBillTo = fuel.customerBillTo;
        public Customer__c customerShipTo = fuel.customerShipTo;
        public Currency__c currencyUSD = fuel.currencyUSD;
        public Product__c product = fuel.product;
        public Bank_Account__c bankAccount = fuel.bankAccount;
        
        public Customer_Receipt__c custReceipt = null;
        public Customer_Invoice__c custInv = null;
        public Customer_Invoice_Line__c ciLine = null;
        public Customer_Receipt_Line__c PrePaymentLine = null;
        
        
        public datetime effStartDate{
        get{
	            if(effStartDate==null)
	            {
	                //Give the earliest eff date possible - Previous yr used to make sure Transactions created are in effectivity range of accounting rules.
	                return datetime.newInstance(system.now().year()-1, 1, 1, 0, 0, 0);
	            }
	            else
	            {
	                return effStartDate;
	            }
         }set; 
       }
        
        public list<Accounting_Rule__c> lARs {
        
        get {
            if(lARs == null)
            {
                lARs = new list<Accounting_Rule__c>();
                
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Refund', Subtransaction_Type__c = 'Refund Unapplied Prepayment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= effStartDate));
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Refund', Subtransaction_Type__c = 'Refund Unapplied Prepayment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= effStartDate));
                
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Refund', Subtransaction_Type__c = 'Refund Credit',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= effStartDate));
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Refund', Subtransaction_Type__c = 'Refund Credit',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= effStartDate));
                
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Refund', Subtransaction_Type__c = 'Refund Unapplied Overpayment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= effStartDate));
                lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Refund', Subtransaction_Type__c = 'Refund Unapplied Overpayment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c= effStartDate));
                
                insert lARs;
            }
            
            return lARs;
        }
        
        set;
    }
        
        public Customer_Invoice__c createCI(Company__c company, Customer__c customerBillTo, String invoiceType, String status){ // Customer Invoice
            
                custInv = new Customer_Invoice__c();
                custInv.Customer__c = customerParent.Id;
                custInv.Bill_To_Customer__c = customerBillTo.Id;
                custInv.Company__c = company.Id;
                if ( custReceipt != null){
                    custInv.Customer_Receipt__c = custReceipt.Id;
                }
                custInv.Invoice_Type__c = invoiceType; //'Prepayment';
                custInv.Status__c = status; //CustomerInvoiceService.STATUS_OPEN;
                custInv.Date_Invoiced__c = system.now();
                custInv.Currency__c = company.Default_Transaction_Currency__c;
                custInv.Transaction_Date__c = system.now();
                return custInv;
            
        }
        
        public Customer_Invoice_Line__c createCILine(Customer_Invoice__c custInv){ // Customer Invoice Line
                ciLine = new  Customer_Invoice_Line__c();
                ciLine.Product__c = product.id;
                ciLine.Customer_Invoice__c = custInv.Id;
                ciLine.Quantity_Shipped__c = 10;
                ciLine.Unit_Price__c = -10;
                return ciLine;
        
        }
        
      
        public Customer_Receipt__c createCR(Company__c company, Customer__c customerParent){
        
                fuel.paymentMethod.Type__c = 'Credit Card';
                update fuel.paymentMethod;
                
                custReceipt = new Customer_Receipt__c();
                custReceipt.Amount_To_Apply__c = 10;
                custReceipt.Amount_Received__c = 10;
		        custReceipt.Transaction_Date__c = system.now();
		        custReceipt.Currency__c = company.Default_Transaction_Currency__c;
		        custReceipt.Company__c = company.Id;
		        custReceipt.Customer__c = customerParent.Id;
		        custReceipt.Payment_Method_3__c = fuel.paymentMethod.Id;
		        custReceipt.Transaction_ID__c = '12345';
		        custReceipt.Type__c = 'Receipt';
		        custReceipt.Bank_Account_2__c = fuel.bankAccount.Id;      
		        custReceipt.Reference_Number__c = '12345';
                return custReceipt;
    }
     
        public Customer_Receipt_Line__c createReceiptLine(Customer_Receipt__c custReceipt,Customer__c customerBillTo, Sales_Order__c salesOrder){
            
                PrePaymentLine = new Customer_Receipt_Line__c();
                PrePaymentLine.Customer_Receipt__c = custReceipt.Id;
                PrePaymentLine.Amount__c = 10;
                PrePaymentLine.Type__c = PaymentService.TYPE_PREPAYMENT;
                PrePaymentLine.Customer__c = customerBillTo.id;
                PrePaymentLine.Sales_Order__c = salesOrder.Id;  
                PrePaymentLine.Sales_Order__r = salesOrder;  
                return  PrePaymentLine;
            
        }
         
        public Claim__c createClaim(){
            Claim__c cl = new Claim__c();
            cl.Name = 'testClaim';
            cl.Source__c = 'Invoice Deduction';
            cl.Currency__c = company.Default_Transaction_Currency__c;
            cl.Company__c = company.Id;
            cl.Parent_Customer__c = customerParent.Id;
            cl.Bill_To_Customer__c = customerBillTo.Id;
            return cl;
        }
        
        public Allowance_Type__c createAllowance(){
            Allowance_Type__c aType = new Allowance_Type__c();
            aType.Name = 'Test Allowance Type';
            aType.Type__c = 'Accrual';
            aType.Allowance_Class__c = 'Standard';
            aType.Basis__c = 'Rate By';
            aType.Manual__c = false;
            aType.Rate_Field__c = 'Quantity';
            aType.Amount__c = 10;
            return aType;
        }
        
        public Allowance_Applied__c createAllowanceApplied(Allowance_Type__c at ){
            Allowance_Applied__c aa1 = new Allowance_Applied__c();
            aa1.Allowance_Class__c = 'Standard';
            aa1.Allowance_Type__c = at.Id;
            aa1.BillBack_Commitment__c = 10;
            aa1.Allowance_Code__c = 'Test Allowance Code';
            return aa1;
        }
    }
    
    static testMethod void Claim_RefundCreditManageTest() {
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        Claim__c cl = testData.createClaim();
        insert cl;
        Test.startTest();
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('claimId', cl.Id);
        RefundCreditManageExt controller = new RefundCreditManageExt();
        system.assertNotEquals(controller.claimId, null);
        system.assertEquals(controller.defaultCustomer, null);
        system.assertEquals(controller.defaultCompany, null);
        system.assertEquals(controller.defaultCurrency, null);
        Test.stopTest();
    }

    static testMethod void Claim_RefundCreditManageTest_getInvoiceCreditsFieldList() {
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        Claim__c cl = testData.createClaim();
        insert cl;
        Test.startTest();
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('claimId', cl.Id);
        RefundCreditManageExt controller = new RefundCreditManageExt();
        String invoiceCreditsFieldListStr = controller.getInvoiceCreditsFieldList();
        List<FieldInfo> invoiceCreditsFieldList = (List<FieldInfo>) JSON.deserialize(InvoiceCreditsFieldListStr, List<FieldInfo>.class);
        Boolean allowanceCodeColumnFound = false;
        Integer allowanceCodeColumnIndex = -1;
        for (Integer ct = 0; ct < invoiceCreditsFieldList.size(); ct ++){
            FieldInfo fi= invoiceCreditsFieldList[ct];
            if (fi.title == Label.Refund_Amount  || fi.title == Label.Settlement_Amount || fi.title == 'Memo'){
                system.assertEquals (fi.filterable, false, '>>> fi: ' + fi);
            }
            else{
                system.assertEquals (fi.filterable, true, '>>> fi: ' + fi);
            }
            if(fi.title == 'Allowance Code'){
               allowanceCodeColumnFound = true;
               allowanceCodeColumnIndex = ct;
            }
        }
        system.assert(allowanceCodeColumnFound);
        system.assertEquals(allowanceCodeColumnIndex, 3, '>>> allowanceCodeColumnIndex: ' + allowanceCodeColumnIndex);
        Test.stopTest();
    }
    
    static testMethod void Customer_RefundCreditManageTest_getInvoiceCreditsFieldList() {
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        Test.startTest();
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('cuId', testData.customerParent.Id);
        RefundCreditManageExt controller = new RefundCreditManageExt();
        String invoiceCreditsFieldListStr = controller.getInvoiceCreditsFieldList();
        List<FieldInfo> invoiceCreditsFieldList = (List<FieldInfo>) JSON.deserialize(InvoiceCreditsFieldListStr, List<FieldInfo>.class);
        Boolean allowanceCodeColumnFound = false;
        Integer allowanceCodeColumnIndex = -1;
        for (Integer ct = 0; ct < invoiceCreditsFieldList.size(); ct ++){
            FieldInfo fi= invoiceCreditsFieldList[ct];
            if (fi.title == Label.Refund_Amount || fi.title == 'Memo'){
                system.assertEquals (fi.filterable, false, '>>> fi: ' + fi);
            }
            else{
                system.assertEquals (fi.filterable, true, '>>> fi: ' + fi);
            }
            if(fi.title == 'Allowance Code'){
               allowanceCodeColumnFound = true;
               allowanceCodeColumnIndex = ct;
            }
        }
        system.assert(!allowanceCodeColumnFound);
        system.assertEquals(allowanceCodeColumnIndex, -1, '>>> allowanceCodeColumnIndex: ' + allowanceCodeColumnIndex);
        Test.stopTest();
    }
    
    static testMethod void CI_RefundCreditManageTest_getInvoiceCreditsFieldList() {
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        Customer_Invoice__c manualCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, 'Manual', 'Open');
        insert manualCI;
        Customer_Invoice_Line__c manualCILine = testData.createCILine(manualCI);
        insert manualCILine;
        manualCI.Finalized__c = true;
        update manualCI;
        
        Test.startTest();
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('ciId', manualCI.Id);
        RefundCreditManageExt controller = new RefundCreditManageExt();
        String invoiceCreditsFieldListStr = controller.getInvoiceCreditsFieldList();
        List<FieldInfo> invoiceCreditsFieldList = (List<FieldInfo>) JSON.deserialize(InvoiceCreditsFieldListStr, List<FieldInfo>.class);
        Boolean allowanceCodeColumnFound = false;
        Integer allowanceCodeColumnIndex = -1;
        for (Integer ct = 0; ct < invoiceCreditsFieldList.size(); ct ++){
            FieldInfo fi= invoiceCreditsFieldList[ct];
            if (fi.title == Label.Refund_Amount || fi.title == 'Memo'){
                system.assertEquals (fi.filterable, false, '>>> fi: ' + fi);
            }
            else{
                system.assertEquals (fi.filterable, true, '>>> fi: ' + fi);
            }
            if(fi.title == 'Allowance Code'){
               allowanceCodeColumnFound = true;
               allowanceCodeColumnIndex = ct;
            }
        }
        system.assert(!allowanceCodeColumnFound);
        system.assertEquals(allowanceCodeColumnIndex, -1, '>>> allowanceCodeColumnIndex: ' + allowanceCodeColumnIndex);
        Test.stopTest();
    }
    
    static testMethod void RefundCreditManageTest() {
        
        RefundCreditManageExt rcManageExt = new RefundCreditManageExt();
        system.assert(rcManageExt.InvoiceCreditsConfig != null );
        system.assert(rcManageExt.getInvoiceCreditsFieldList().length() > 0 );
		system.assert(rcManageExt.getInvoiceCreditsConfigJson() != null );
		
		system.assert(rcManageExt.RefundMethodConfig != null );
        system.assert(rcManageExt.getRefundMethodFieldList().length() > 0 );
        
        system.assert(rcManageExt.PaymentCreditsConfig != null );
        system.assert(rcManageExt.getPaymentCreditsFieldList().length() > 0 );
        system.assert(rcManageExt.getPaymentCreditsConfigJson() != null );
  }
    
    static testMethod void testRefundCreditsFilters(){
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();

        User_Preference__c up = new User_Preference__c();
        up.Default_Company__c = testData.fuel.company.id;
        up.ownerID = UserInfo.getUserID();
        insert up;
        
        RefundCreditManageExt ext = new RefundCreditManageExt();
        
        // Launch from Refund Credit Tab
        system.assert(ext.defaultCompany == testData.fuel.company.Id, 'default company is not the same');
        system.assert(ext.defaultCurrency == testData.fuel.company.Default_Transaction_Currency__c, 'default currency is not the same');
        
        //Launch from CI or Customer
        
        //Failure Case -  No Default Currency found
        RefundCreditManageExt ext1 = new RefundCreditManageExt();
        ext1.customerId = testData.fuel.customerParent.Id;
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor fd1_NoCurr = new KendoUtils.FilterDescriptor();
        fd1_NoCurr.field = 'Customer__c';
        fd1_NoCurr.fieldType = 'string';
        fd1_NoCurr.value = testData.fuel.customerParent.Id;
        fd1_NoCurr.operator = 'eq';
        filters.add(fd1_NoCurr);
        
        KendoUtils.FilterDescriptor fd2_NoCurr = new KendoUtils.FilterDescriptor();
        fd2_NoCurr.field = 'Company__c';
        fd2_NoCurr.fieldType = 'string';
        fd2_NoCurr.value = testData.fuel.company.Id;
        fd2_NoCurr.operator = 'eq';
        filters.add(fd2_NoCurr);
        
        String creditsType_NoCurr = 'Invoice';
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.getInvoiceCredits( filters,creditsType_NoCurr,null,false ); 
        System.debug(logginglevel.error,'result1--->'+result1);
        system.assert(result1.success == true,'Failed to fetch Credit Invoices for Customer'); 
        system.assert(result1.records.size() == 0,'The are some CreditInvoices fetched, this is not correct');    
        
        //Success Case
        List<KendoUtils.FilterDescriptor> filters3 = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor fd1_All = new KendoUtils.FilterDescriptor();
        fd1_All.field = 'Customer__c';
        fd1_All.fieldType = 'string';
        fd1_All.value = testData.fuel.customerParent.Id;
        fd1_All.operator = 'eq';
        filters3.add(fd1_All);
        
        KendoUtils.FilterDescriptor fd2_All = new KendoUtils.FilterDescriptor();
        fd2_All.field = 'Company__c';
        fd2_All.fieldType = 'string';
        fd2_All.value = testData.fuel.company.Id;
        fd2_All.operator = 'eq';
        filters3.add(fd2_All);
        
        KendoUtils.FilterDescriptor fd3_All = new KendoUtils.FilterDescriptor();
        fd3_All.field = 'Currency__c';
        fd3_All.fieldType = 'string';
        fd3_All.value = testData.fuel.company.Default_Transaction_Currency__c; 
        fd3_All.operator = 'eq';
        filters3.add(fd3_All);
       
        Test.startTest();
        String creditsType = 'Invoice';
        JsonResult result = new JsonResult();
        result = RefundCreditManageExt.getInvoiceCredits( filters3,creditsType,null,false );
        system.assert(result.success == true,'Failed to fetch Credit Invoices'); 
        Test.stopTest();
    }
    
    static testMethod void testInvoiceCredits_NegativeBalances(){
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
   
        Test.startTest();
        
        
        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;
        
        Customer_Invoice__c prepaymentCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, 'Prepayment', 'Open');
        prepaymentCIList.add(prepaymentCI);
        insert prepaymentCIList;
        
        Customer_Invoice_Line__c prePayCILine = testData.createCILine(prepaymentCIList[0]);
        prePayCILineList.add(prePayCILine);
        insert prePayCILineList;
        Test.stopTest();
        
        Customer_Invoice__c custInvoice = [ select id, Invoice_Type__c, Balance__c, Total_Amount__c from Customer_Invoice__c where id = :prepaymentCIList[0].Id];
        system.assertEquals(-100, custInvoice.Balance__c);
        system.assertEquals(-100, custInvoice.Total_Amount__c);
        system.assertEquals('Prepayment', custInvoice.Invoice_Type__c);
       
    }

    static testMethod void testInvoiceCredits_ClaimPageLoad(){
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        
        Allowance_Type__c accrualAllowanceType = testData.createAllowance();
        insert accrualAllowanceType;
        Allowance_Applied__c aa = testData.createAllowanceApplied(accrualAllowanceType);
        insert aa;
        
        Customer_Invoice__c manualCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, 'Manual', 'Open');
        cis.add(manualCI);
        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, AllowanceRuleService.ALLOWANCE_ACCRUAL, 'Open');
        cis.add(aaCI);
        insert cis;
        Customer_Invoice_Line__c manualCILine = testData.createCILine(manualCI);
        cils.add(manualCILine);
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        aaCILine.Allowance_Applied__c = aa.Id;
        cils.add(aaCILine);
        insert cils;
        manualCI.Finalized__c = true;
        aaCI.Finalized__c = true;
        update cis;

        Claim__c cl = testData.createClaim();
        insert cl;
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('claimId', cl.Id);

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        RefundCreditManageExt ext = new RefundCreditManageExt();
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        System.debug(logginglevel.error,'result-->'+result);

        system.assert(result.success == true,'The Credit Invoices are not fetched');
        system.assert(result.records.size() == 2,'The Credit Invoices are not fetched');
        List<RefundCreditService.InvoiceCreditsWrapper> invoicCreditWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>) result.records;
        for (RefundCreditService.InvoiceCreditsWrapper wrapper: invoicCreditWrappers){
            if (wrapper.cusInv.Id == aaCI.Id){
                system.assertEquals(wrapper.lineAllowanceCode, aa.Allowance_Code__c);
            }
            else{
                system.assertEquals(wrapper.lineAllowanceCode, '');
            }
        }
        Test.stopTest();
    }
     
    static testMethod void testInvoiceCredits_Search(){

        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();

        Customer_Invoice__c custInv = new Customer_Invoice__c();
        custInv.Customer__c = testData.fuel.customerParent.Id;
        custInv.Bill_To_Customer__c = testData.fuel.customerBillTo.Id;
        custInv.Company__c = testData.fuel.company.Id;
        custInv.Invoice_Type__c = 'Manual'; 
        custInv.Status__c = 'Open'; 
        custInv.Date_Invoiced__c = system.now();
        custInv.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
        custInv.Transaction_Date__c = system.now();
        insert custInv;
            
        Customer_Invoice_Line__c ciLine = new  Customer_Invoice_Line__c();
        ciLine.Product__c = testData.fuel.product.id;
        ciLine.Customer_Invoice__c = custInv.Id;
        ciLine.Quantity_Shipped__c = 10;
        ciLine.Unit_Price__c = -10;
        insert ciLine;
        
        custInv.Finalized__c = true;
        update custInv;

        System.debug(logginglevel.error,'custInv--->'+custInv);

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        System.debug(logginglevel.error,'result-->'+result);

        system.assert(result.success == true,'The Credit Invoices aren not fetched');
        system.assert(result.records.size() == 1,'The Credit Invoices aren not fetched');
    } 
    
    static testMethod void testInvoiceCredits_InvoiceLaunch_NotEligibleCI(){
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();


        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;

        Customer_Invoice__c prepaymentCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, 'Prepayment', 'Open');
        prepaymentCIList.add(prepaymentCI);
        insert prepaymentCIList;
        
        Customer_Invoice_Line__c prePayCILine = testData.createCILine(prepaymentCIList[0]);
        prePayCILineList.add(prePayCILine);
        insert prePayCILineList;
        
        Customer_Invoice__c custInvoice = [ select id, Invoice_Type__c, Balance__c, Total_Amount__c from Customer_Invoice__c where id = :prepaymentCIList[0].Id];
        system.assertEquals(-100, custInvoice.Balance__c);
        system.assertEquals(-100, custInvoice.Total_Amount__c);
        system.assertEquals('Prepayment', custInvoice.Invoice_Type__c);
        
        ApexPages.StandardController con = new ApexPages.StandardController(custInvoice);
        RefundCreditInvoiceLaunchExt invLaunch = new RefundCreditInvoiceLaunchExt(con);
        Test.startTest();
        invLaunch.theCustomerInvoiceId = custInvoice.Id;
        PageReference pgRef = invLaunch.navigateToRefundCredit();
        system.assert(pgRef == null, 'Customer Invoice is not valid for refund');
        system.assert( Apexpages.hasMessages() == true , Apexpages.getMessages() );
        Test.stopTest();
       
    }
    
    static testMethod void testInvoiceCredits_InvoiceLaunch_EligibleCI(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
        
        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;
        //KNDY-13995
        crLine = [SELECT Customer_Invoice__c FROM Customer_Receipt_Line__c where Id = :crLine.Id];
        
        Customer_Invoice__c prepaymentCI = [SELECT Id,(SELECT Id FROM Customer_Invoice_Lines__r)
                                            FROM Customer_Invoice__c WHERE Id = :crLine.Customer_Invoice__c]; //KNDY-13995
                                            
                                            
        prepaymentCIList.add(prepaymentCI);
        System.debug(logginglevel.error,'prepaymentCIList-->'+prepaymentCIList);
        
        Customer_Invoice_Line__c prePayCILine = prepaymentCI.Customer_Invoice_Lines__r[0];
        prePayCILineList.add(prePayCILine);
        
        System.debug(logginglevel.error,'prePayCILineList-->'+prePayCILineList);
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        
        requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
        
        Customer_Invoice__c custInvoice = [ select id, Company__c, Currency__c, Customer__c, Invoice_Type__c, Balance__c, Total_Amount__c,Finalized__c from Customer_Invoice__c where id in  :prepaymentCIList];
        system.assertEquals(-10, custInvoice.Balance__c);
        system.assertEquals(-10, custInvoice.Total_Amount__c);
        
        System.debug(logginglevel.error,'custInvoice--->'+custInvoice);
        
        Test.startTest();
        ApexPages.StandardController con = new ApexPages.StandardController(custInvoice);
        RefundCreditInvoiceLaunchExt invLaunch = new RefundCreditInvoiceLaunchExt(con);
        
        invLaunch.theCustomerInvoiceId = custInvoice.Id;
        PageReference pgRef = invLaunch.navigateToRefundCredit();
        System.debug(logginglevel.error,'pgRef---->'+pgRef);
        system.assert(pgRef != null, 'Customer Invoice is valid for refund'); //launched on to the Refund Credit page
        system.assert( Apexpages.hasMessages() == false , Apexpages.getMessages() ); 
        
        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerParent.Id;
        fd1.operator = 'eq';
        filters.add(fd1);
        
        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
       
        RefundCreditManageExt invRFCredit = new RefundCreditManageExt();
        invRFCredit.customerInvoiceId = custInvoice.Id;
        
        JsonResult result = new JsonResult();
        String creditsType = 'PaymentGateway';
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,String.valueOf(custInvoice.Id),false); 
        
        List<RefundCreditService.InvoiceCreditsWrapper> invCredWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>)result.records;
        
        System.debug(logginglevel.error,invCredWrappers.size());
        System.debug(logginglevel.error,'invCredWrappers--->'+invCredWrappers);
        System.debug(logginglevel.error,'crList[0]--->'+crList[0]);

        JsonResult result2 = RefundCreditManageExt.getValidInvoicePaymentCredits(invCredWrappers,String.valueOf(custInvoice.Id),false);
        System.debug(logginglevel.error,'result2--->'+result2);
        
        system.assert( result2.success == true,'Valid Payment Credits Not Present' );
        system.assert( result2.records.size() == 1, 'No Payment gateway credits Available'); //one Payment Gateway Credit Record Avaialble
        
        Test.stopTest();
       
    }
    
    static testMethod void testInvoiceCredits_ShipInvoiceType_InvoiceLaunch(){
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();


        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;


        Customer_Invoice__c prepaymentCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, 'Ship Invoice', 'Open');
        prepaymentCIList.add(prepaymentCI);
        insert prepaymentCIList;
        
        Customer_Invoice_Line__c prePayCILine = testData.createCILine(prepaymentCIList[0]);
        prePayCILineList.add(prePayCILine);
        insert prePayCILineList;
        
        Customer_Invoice__c custInvoice = [ select id, Invoice_Type__c, Balance__c, Total_Amount__c from Customer_Invoice__c where id = :prepaymentCIList[0].Id];
        system.assertEquals(-100, custInvoice.Balance__c);
        system.assertEquals(-100, custInvoice.Total_Amount__c);
        system.assertEquals('Ship Invoice', custInvoice.Invoice_Type__c);
        
        ApexPages.StandardController con = new ApexPages.StandardController(custInvoice);
        RefundCreditInvoiceLaunchExt invLaunch = new RefundCreditInvoiceLaunchExt(con);
        Test.startTest();
        invLaunch.theCustomerInvoiceId = custInvoice.Id;
        PageReference pgRef = invLaunch.navigateToRefundCredit();
        system.assert(pgRef == null, 'Customer Invoice is not valid for refund');
        system.assert( Apexpages.hasMessages() == true , Apexpages.getMessages() );
        
        Pagereference pgRefToCI = invLaunch.returnToCI();
        system.assert(pgRefToCI == null, 'Not Retruning back to CI');
        Test.stopTest();
       
    }
    
    
    
    static testMethod void testInvoiceCredits_CustomerLaunch(){
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();


        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;

        Customer_Invoice__c prepaymentCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, 'Prepayment', 'Open');
        prepaymentCIList.add(prepaymentCI);
        insert prepaymentCIList;
        
        Customer_Invoice_Line__c prePayCILine = testData.createCILine(prepaymentCIList[0]);
        prePayCILineList.add(prePayCILine);
        insert prePayCILineList;
        
        Customer_Invoice__c custInvoice = [ select id, Invoice_Type__c, Balance__c, Total_Amount__c from Customer_Invoice__c where id = :prepaymentCIList[0].Id];
        system.assertEquals(-100, custInvoice.Balance__c);
        system.assertEquals(-100, custInvoice.Total_Amount__c);
        system.assertEquals('Prepayment', custInvoice.Invoice_Type__c);
       
        
        ApexPages.StandardController con = new ApexPages.StandardController(testData.fuel.customerBillTo);
        RefundCreditCustomerLaunchExt invLaunch = new RefundCreditCustomerLaunchExt(con);
        
        Test.startTest();
        invLaunch.theCustomerId = testData.fuel.customerBillTo.Id;
        PageReference pgRef = invLaunch.navigateToRefundCredit();
        system.assert(pgRef != null, 'Customer and its Customer Invoices are not valid for refund');
        system.assert( Apexpages.hasMessages() == false , 'Redirecting to Refund Credit Failed' );
        Test.stopTest();
       
    }
    
     static testMethod void testInvoiceCredits_Ship_To_CustomerLaunch(){
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();


        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
   
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;
        
        Customer_Invoice__c prepaymentCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, 'Prepayment', 'Open');
        prepaymentCIList.add(prepaymentCI);
        insert prepaymentCIList;
        
        Customer_Invoice_Line__c prePayCILine = testData.createCILine(prepaymentCIList[0]);
        prePayCILineList.add(prePayCILine);
        insert prePayCILineList;
        
        Customer_Invoice__c custInvoice = [ select id, Invoice_Type__c, Balance__c, Total_Amount__c from Customer_Invoice__c where id = :prepaymentCIList[0].Id];
        system.assertEquals(-100, custInvoice.Balance__c);
        system.assertEquals(-100, custInvoice.Total_Amount__c);
        system.assertEquals('Prepayment', custInvoice.Invoice_Type__c); 
        
        
        ApexPages.StandardController con = new ApexPages.StandardController(testData.fuel.customerShipTo);
        RefundCreditCustomerLaunchExt invLaunch = new RefundCreditCustomerLaunchExt(con);
        
        Test.startTest();
        invLaunch.theCustomerId = testData.fuel.customerShipTo.Id;
        PageReference pgRef = invLaunch.navigateToRefundCredit();
        system.assert(pgRef == null, 'Customer got eligible for refund, please check');
        system.assert( Apexpages.hasMessages() == true ,  'Refund Credit re-direction Passed' );  
        Test.stopTest();
       
    }
    
    static testMethod void testInvoiceCredits_NoServiceConfiguration_Setting(){
      
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
        
        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;
        //KNDY-13995
        crLine = [SELECT Customer_Invoice__c FROM Customer_Receipt_Line__c where Id = :crLine.Id];
        
        Customer_Invoice__c prepaymentCI = [SELECT Id,
                                                (SELECT Id FROM Customer_Invoice_Lines__r)
                                            FROM Customer_Invoice__c WHERE Id = :crLine.Customer_Invoice__c]; //KNDY-13995
        prepaymentCIList.add(prepaymentCI);
        System.debug(logginglevel.error,'prepaymentCIList-->'+prepaymentCIList);
        
        Customer_Invoice_Line__c prePayCILine = prepaymentCI.Customer_Invoice_Lines__r[0];
        prePayCILineList.add(prePayCILine);
        
        System.debug(logginglevel.error,'prePayCILineList-->'+prePayCILineList);
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        
        requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
        
        Customer_Invoice__c custInvoice = [ select id, Company__c, Currency__c, Customer__c, Invoice_Type__c, Balance__c, Total_Amount__c,Finalized__c from Customer_Invoice__c where id in  :prepaymentCIList];
        system.assertEquals(-10, custInvoice.Balance__c);
        system.assertEquals(-10, custInvoice.Total_Amount__c);
        
        System.debug(logginglevel.error,'custInvoice--->'+custInvoice);
        
        Test.startTest();
        ApexPages.StandardController con = new ApexPages.StandardController(custInvoice);
        RefundCreditInvoiceLaunchExt invLaunch = new RefundCreditInvoiceLaunchExt(con);
        
        invLaunch.theCustomerInvoiceId = custInvoice.Id;
        PageReference pgRef = invLaunch.navigateToRefundCredit();

        system.assert(pgRef == null, 'Customer Invoice is not valid for refund'); 
        System.debug(logginglevel.error,'Apexpages.getMessages()--->'+Apexpages.getMessages());
        system.assert( Apexpages.hasMessages() == true , Apexpages.getMessages() ); //launched on to the Refund Credit page with a valid error message
        Test.stopTest();
    }    

    static testMethod void Claim_testCreateRefundReceipt_Success(){
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        
        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, AllowanceRuleService.ALLOWANCE_ACCRUAL, 'Open');
        cis.add(aaCI);
        insert cis;
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        cils.add(aaCILine);
        insert cils;
        aaCI.Finalized__c = true;
        update cis;

        Claim__c cl = testData.createClaim();
        cl.Source__c = 'Manual';
        cl.Amount__c = 100;
        insert cl;

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        // Set Claim Id in page url
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('claimId', cl.Id);
        RefundCreditManageExt ext = new RefundCreditManageExt();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        //Get Customer Invoice Wrappers
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        System.debug(logginglevel.error,'result-->'+result);
        system.assert(result.success == true,'The Credit Invoices are not fetched');
        system.assert(result.records.size() == 1,'The Credit Invoices are not fetched');
        List<RefundCreditService.InvoiceCreditsWrapper> invoicCreditWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>) result.records;
        
        // Set amount to refund on ci wrappers
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invoicCreditWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 100.00;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        // Set up a CR to insert with Claim lookup
        DateTime dateReceived = system.now();
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;
        custReceipt.Claim__c = cl.Id;
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = dateReceived;
        custReceipt.Payment_Method_G__c = 'Check';
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        System.debug(logginglevel.error,invoicCreditWrappers.size());
        System.debug(logginglevel.error,'invoicCreditWrappers--->'+invoicCreditWrappers);
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        // Call extension method that creates CR
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invoicCreditWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        Test.stopTest();
        
        // CI asserts
        aaCI = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id = :aaCI.id];
        system.assertEquals(aaCI.Balance__c, 0, '>>> aaCI:'+aaCI);
        system.assertEquals(aaCI.Status__c, 'Closed','>>> aaCI:'+aaCI);
        
        // CR and CRL asserts
        List<Customer_Receipt__c> crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Claim__c = :cl.Id];
        system.assertEquals(crs.size() ,1, '>>> crs: ' + crs);
        Customer_Receipt__c cr = crs[0];
        system.assertEquals(cr.Type__c, 'Refund', '>>>> cr: ' + cr);
        system.assertEquals(cr.Status__c, 'Closed', '>>>> cr: ' + cr);
        system.assertEquals(cr.Finalized__c, true, '>>>> cr: ' + cr);
        system.assertEquals(cr.Amount_Unapplied__c, 0, '>>>> cr: ' + cr);
        system.assertEquals(cr.Customer_Receipt_Lines__r.size(), 1, '>>>> cr.Customer_Receipt_Lines__r: ' + cr.Customer_Receipt_Lines__r);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Type__c, PaymentService.TYPE_REFUND_ALLOWANCE_ACCRUAL, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Amount__c, -100, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        
        // Manual claim asserts
        cl = [Select Id, Status__c, Settlement_Method__c, Claim_Balance__c, Settlement_Date__c,
               (Select Id, Customer_Invoice__c from Claim_Lines__r)
              from Claim__c where Id = :cl.Id];
        system.assertEquals(cl.Status__c, 'Closed', '>>> cl: ' + cl);
        system.assertEquals(cl.Settlement_Method__c, 'Refund', '>>> cl: ' + cl);
        system.assertEquals(cl.Settlement_Date__c, Date.newInstance(dateReceived.year(),dateReceived.month(),dateReceived.day()), '>>> cl: ' + cl);
        system.assertEquals(cl.Claim_Balance__c, 0, '>>> cl: ' + cl);
        system.assertEquals(cl.Claim_Lines__r.size(), 1);
        system.assertEquals(cl.Claim_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cl.Claim_Lines__r[0]:' + cl.Claim_Lines__r[0]);
    }
    
    static testMethod void Claim_testCreateRefundReceipt_Failure(){
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        
        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, AllowanceRuleService.ALLOWANCE_ACCRUAL, 'Open');
        cis.add(aaCI);
        insert cis;
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        cils.add(aaCILine);
        insert cils;
        aaCI.Finalized__c = true;
        update cis;
        
        // Set up an invalid Claim
        Claim__c cl = testData.createClaim();
        cl.Source__c = 'General Deduction';
        cl.Amount__c = 100;
        insert cl;

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        // Set Claim Id in page url
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('claimId', cl.Id);
        RefundCreditManageExt ext = new RefundCreditManageExt();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        //Get Customer Invoice Wrappers
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        System.debug(logginglevel.error,'result-->'+result);
        system.assert(result.success == true,'The Credit Invoices are not fetched');
        system.assert(result.records.size() == 1,'The Credit Invoices are not fetched');
        List<RefundCreditService.InvoiceCreditsWrapper> invoicCreditWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>) result.records;
        
        // Set amount to refund on ci wrappers
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invoicCreditWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 100.00;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        // Set up a CR to insert with Claim lookup
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;
        custReceipt.Claim__c = cl.Id;
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Check';
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        System.debug(logginglevel.error,invoicCreditWrappers.size());
        System.debug(logginglevel.error,'invoicCreditWrappers--->'+invoicCreditWrappers);
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        // Call extension method that creates CR
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invoicCreditWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == false,'Customer Receipt Creation Succeeded' );
        system.assert( Apexpages.hasMessages() == true , 'Expected Exception on Creation of Customer Receipt' );
        String expectedErrorMessage = Label.Refund_Credit_Invalid_Claim;
		Boolean errorExists = true;
		for(ApexPages.Message msg: apexPages.getMessages()) {
			if(msg.getDetail().contains(expectedErrorMessage)) 
				errorExists = true;
		}
		system.assertEquals(true, errorExists, ApexPages.getMessages());
        Test.stopTest();
        
        // CI asserts
        aaCI = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id = :aaCI.id];
        system.assertNotEquals(aaCI.Balance__c, 0, '>>> aaCI:'+aaCI);
        system.assertNotEquals(aaCI.Status__c, 'Closed','>>> aaCI:'+aaCI);
        
        // CR and CRL asserts
        List<Customer_Receipt__c> crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Claim__c = :cl.Id];
        system.assertEquals(crs.size() ,0, '>>> crs: ' + crs);

        // General Deduction claim asserts
        cl = [Select Id, Status__c, Settlement_Method__c, Claim_Balance__c,
               (Select Id, Customer_Invoice__c from Claim_Lines__r)
              from Claim__c where Id = :cl.Id];
        system.assertNotEquals(cl.Status__c, 'Closed', '>>> cl: ' + cl);
        system.assertNotEquals(cl.Settlement_Method__c, 'Refund', '>>> cl: ' + cl);
        system.assertNotEquals(cl.Claim_Balance__c, 0, '>>> cl: ' + cl);
        system.assertEquals(cl.Claim_Lines__r.size(),0);
    }
    
    static testMethod void testCreateRefundReceipt(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
   
        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;
        //KNDY-13995
        crLine = [SELECT Customer_Invoice__c FROM Customer_Receipt_Line__c where Id = :crLine.Id];
        
        Customer_Invoice__c prepaymentCI = [SELECT Id,(SELECT Id FROM Customer_Invoice_Lines__r) FROM Customer_Invoice__c WHERE Id = :crLine.Customer_Invoice__c]; //KNDY-13995
                                            
                                            
        prepaymentCIList.add(prepaymentCI);
        System.debug(logginglevel.error,'prepaymentCIList-->'+prepaymentCIList);
        
        Customer_Invoice_Line__c prePayCILine = prepaymentCI.Customer_Invoice_Lines__r[0];
        prePayCILineList.add(prePayCILine);
        
        System.debug(logginglevel.error,'prePayCILineList-->'+prePayCILineList);
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        
        requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest'));
        
        
        Customer_Invoice__c custInvoice = [ select id, Company__c, Currency__c, Customer__c, Invoice_Type__c, Balance__c, Total_Amount__c,Finalized__c from Customer_Invoice__c where id in  :prepaymentCIList];
        system.assertEquals(-10, custInvoice.Balance__c);
        system.assertEquals(-10, custInvoice.Total_Amount__c);
        
        System.debug(logginglevel.error,'custInvoice--->'+custInvoice);
        
        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerParent.Id;
        fd1.operator = 'eq';
        filters.add(fd1);
        
        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);
        
        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,String.valueOf(custInvoice.Id),false); 
        
        
        System.debug(logginglevel.error,'result-->'+result);
        
        system.assert(result.success == true,'The Credit Invoices aren not fetched');
        system.assert(result.records.size() == 1,'The Credit Invoices aren not fetched');
        
        List<RefundCreditService.InvoiceCreditsWrapper> invCredWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>)result.records;
        
        System.debug(logginglevel.error,'invCredWrappers--->'+invCredWrappers);
        
        RefundCreditManageExt invRFLaunch = new RefundCreditManageExt();
        invRFLaunch.customerInvoiceId = custInvoice.Id;
        String url = invRFLaunch.getReturnUrl();
        system.assert( url != null,'CI Return URL not available' );
        System.debug(logginglevel.error,'url-->'+url);
        JsonResult result2 = RefundCreditManageExt.getRefundMethod();
        System.debug(logginglevel.error,'result2-->'+result2);
        system.assert( result2.success == true,'Refund Method popup not rendered' );
        //KNDY-18030 no disbursement bank associated on company level
        JsonResult resultBankAcc = RefundCreditManageExt.getRefundBankAccountMethod(testData.fuel.company.Id);
        System.debug(logginglevel.error,'resultBankAcc-->'+resultBankAcc);
        system.assert( resultBankAcc.total == 1,'Refund Method company bank account not fetched' + resultBankAcc );
        Company__c disbursementBank = (Company__c) resultBankAcc.records[0];
        system.assertEquals(disbursementBank.Disbursement_Bank_Account__c == null, true,'No Disbursement bank account on company' + disbursementBank);
        system.assertEquals(disbursementBank.Disbursement_Bank_Account__c != testData.fuel.bankAccount.Id, true,'Disbursement bank account on company is not same as bank account' + disbursementBank);
        
        Bank_Account__c bankaccount = new Bank_Account__c();
    	bankaccount.name = 'Wells Fargo';
    	bankaccount.company__c = testData.fuel.company.id;
    	bankaccount.GL_Account__c = testData.fuel.receivablesGL.id;
    	insert bankaccount;
    	
        testData.fuel.company.Disbursement_Bank_Account__c = bankaccount.id;
        update testData.fuel.company;
        //KNDY-18030  disbursement bank associated on company level
        resultBankAcc = RefundCreditManageExt.getRefundBankAccountMethod(testData.fuel.company.Id);
        System.debug(logginglevel.error,'resultBankAcc-->'+resultBankAcc);
        system.assert( resultBankAcc.total == 1,'Refund Method company bank account not fetched' + resultBankAcc );
        disbursementBank = (Company__c) resultBankAcc.records[0];
        system.assertEquals(disbursementBank.Disbursement_Bank_Account__c != null, true,'No Disbursement bank account on company' + disbursementBank);      
        //18029 - disbursement bank account has payment method associated to it
        resultBankAcc = RefundCreditManageExt.getBankAccountDetails(disbursementBank.Disbursement_Bank_Account__c );
        bankaccount = (Bank_Account__c) resultBankAcc.records[0];
        system.assertEquals(bankaccount.Primary_Disbursement_Payment_Method__c == null, true,' Disbursement Payment method associated to bank level' + bankaccount.Primary_Disbursement_Payment_Method__c);      
        
        bankaccount.Primary_Disbursement_Payment_Method__c = 'Online';
        update bankaccount;
        resultBankAcc = RefundCreditManageExt.getBankAccountDetails(disbursementBank.Disbursement_Bank_Account__c );
        bankaccount = (Bank_Account__c) resultBankAcc.records[0];
        system.assertEquals(bankaccount.Primary_Disbursement_Payment_Method__c == 'Online', true,'No Disbursement Payment method associated to company level' + disbursementBank);      
        
        
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invCredWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 5;
            
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Check';
    
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        
        System.debug(logginglevel.error,invCredWrappers.size());
        System.debug(logginglevel.error,'invCredWrappers--->'+invCredWrappers);
        
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invCredWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        Test.stopTest();
     
    } 
    
    static testMethod void testCreateRefundReceipt_ForNonRegularInvoicesTypes(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');  
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
   
        
        Customer_Invoice__c custInv = new Customer_Invoice__c();
        custInv.Customer__c = testData.fuel.customerParent.Id;
        custInv.Bill_To_Customer__c = testData.fuel.customerBillTo.Id;
        custInv.Company__c = testData.fuel.company.Id;
        custInv.Invoice_Type__c = 'NonManual'; 
        custInv.Status__c = 'Open'; 
        custInv.Date_Invoiced__c = system.now();
        custInv.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
        custInv.Transaction_Date__c = system.now();
        insert custInv;
            
        Customer_Invoice_Line__c ciLine = new  Customer_Invoice_Line__c();
        ciLine.Product__c = testData.fuel.product.id;
        ciLine.Customer_Invoice__c = custInv.Id;
        ciLine.Quantity_Shipped__c = 10;
        ciLine.Unit_Price__c = -10;
        insert ciLine;
        
        custInv.Finalized__c = true;
        update custInv;

        System.debug(logginglevel.error,'custInv--->'+custInv);
        
        
        Customer_Invoice__c custInvoice = [ select id, Company__c, Currency__c, Customer__c, Invoice_Type__c, Balance__c, Total_Amount__c,Finalized__c from Customer_Invoice__c where id = :custInv.Id];
        system.assertEquals(-100, custInvoice.Balance__c);
        system.assertEquals(-100, custInvoice.Total_Amount__c);
        system.assertEquals('NonManual', custInvoice.Invoice_Type__c);
        
        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerParent.Id;
        fd1.operator = 'eq';
        filters.add(fd1);
        
        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);
        
        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        JsonResult result = new JsonResult();
        
        String creditsType = 'Invoice';
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        
        System.debug(logginglevel.error,'result-->'+result);
        
        system.assert(result.success == true,'The Credit Invoices aren not fetched');
        
        List<RefundCreditService.InvoiceCreditsWrapper> invCredWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>)result.records;
        
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invCredWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 5;
            
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Check';
    
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        
        System.debug(logginglevel.error,invCredWrappers.size());
        System.debug(logginglevel.error,'invCredWrappers--->'+invCredWrappers);
        
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invCredWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        Id crId = null;
        for(Map<String, String> msg :result1.messages)
            if(msg.containsKey('message')){
                if(msg.get('message').contains('has been created.')){
                    crId = Id.valueOf(msg.get('message').substringBetween('/','"')); 
                }
            }
     
        Customer_Receipt_Line__c crl = [select id, Type__c, Amount__c from Customer_Receipt_Line__c where Customer_Receipt__c = :crId]; 
        system.debug(logginglevel.error,'crl---->'+crl);
        system.assert( crl.Type__c == PaymentService.TYPE_REFUND_CREDIT, 'Customer Receipt of desired type is not created' );
        Test.stopTest();
    }
    
    static testMethod void testCreateRefundReceipt_failure(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
   
        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;
        //KNDY-13995
        crLine = [SELECT Customer_Invoice__c FROM Customer_Receipt_Line__c where Id = :crLine.Id];
        
        Customer_Invoice__c prepaymentCI = [SELECT Id,
                                                (SELECT Id FROM Customer_Invoice_Lines__r)
                                            FROM Customer_Invoice__c WHERE Id = :crLine.Customer_Invoice__c]; //KNDY-13995
                                            
                                            
        prepaymentCIList.add(prepaymentCI);
        System.debug(logginglevel.error,'prepaymentCIList-->'+prepaymentCIList);
        
        Customer_Invoice_Line__c prePayCILine = prepaymentCI.Customer_Invoice_Lines__r[0];
        prePayCILineList.add(prePayCILine);
        
        System.debug(logginglevel.error,'prePayCILineList-->'+prePayCILineList);
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        
        requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest'));
        
        
        Customer_Invoice__c custInvoice = [ select id, Company__c, Currency__c, Customer__c, Invoice_Type__c, Balance__c, Total_Amount__c,Finalized__c from Customer_Invoice__c where id in  :prepaymentCIList];
        system.assertEquals(-10, custInvoice.Balance__c);
        system.assertEquals(-10, custInvoice.Total_Amount__c);
        
        System.debug(logginglevel.error,'custInvoice--->'+custInvoice);

        
        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerParent.Id;
        fd1.operator = 'eq';
        filters.add(fd1);
        
        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);
        
        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,String.valueOf(custInvoice.Id),false); 
       
        System.debug(logginglevel.error,'result-->'+result);
        
        system.assert(result.success == true,'The Credit Invoices aren not fetched');
        
        List<RefundCreditService.InvoiceCreditsWrapper> invCredWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>)result.records;
        
        System.debug(logginglevel.error,'invCredWrappers--->'+invCredWrappers);
        
        RefundCreditManageExt invRFLaunch = new RefundCreditManageExt();
        invRFLaunch.customerInvoiceId = custInvoice.Id;
        String url = invRFLaunch.getReturnUrl();
        system.assert( url != null,'CI Return URL not available' );
        JsonResult result2 = RefundCreditManageExt.getRefundMethod();
        system.assert( result2.success == true,'Refund Method popup not rendered' );
        
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invCredWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 25;
            
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;   
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Check'; 
        
        custReceiptList.add(custReceipt);
        
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invCredWrappers,totalRefundAmount);  
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == false,'Refund amount is not greater than the balance' );
        system.assert( Apexpages.hasMessages() == true , 'Exception on Creation of Customer Receipt' );
        Test.stopTest();
     
    } 
    
    static testMethod void testCreatePaymentGatewayCustomerReceipt(){

        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
        
        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;
        //KNDY-13995
        crLine = [SELECT Customer_Invoice__c FROM Customer_Receipt_Line__c where Id = :crLine.Id];
        
        Customer_Invoice__c prepaymentCI = [SELECT Id,
                                                (SELECT Id FROM Customer_Invoice_Lines__r)
                                            FROM Customer_Invoice__c WHERE Id = :crLine.Customer_Invoice__c]; //KNDY-13995
                                            
                                            
        prepaymentCIList.add(prepaymentCI);
        System.debug(logginglevel.error,'prepaymentCIList-->'+prepaymentCIList);
        
        Customer_Invoice_Line__c prePayCILine = prepaymentCI.Customer_Invoice_Lines__r[0];
        prePayCILineList.add(prePayCILine);
        
        System.debug(logginglevel.error,'prePayCILineList-->'+prePayCILineList);
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        
        requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
        
        Customer_Invoice__c custInvoice = [ select id, Company__c, Currency__c, Customer__c, Invoice_Type__c, Balance__c, Total_Amount__c,Finalized__c from Customer_Invoice__c where id in  :prepaymentCIList];
        system.assertEquals(-10, custInvoice.Balance__c);
        system.assertEquals(-10, custInvoice.Total_Amount__c);
        
        System.debug(logginglevel.error,'custInvoice--->'+custInvoice);

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerParent.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        
        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        
        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);

        
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        
        RefundCreditManageExt invRFCredit = new RefundCreditManageExt();
        invRFCredit.customerInvoiceId = custInvoice.Id;
        
        JsonResult result = new JsonResult();
        String creditsType = 'PaymentGateway';
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,String.valueOf(custInvoice.Id),false); 
        
        List<RefundCreditService.InvoiceCreditsWrapper> invCredWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>)result.records;
        
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invCredWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 5;
            
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        System.debug(logginglevel.error,invCredWrappers.size());
        System.debug(logginglevel.error,'invCredWrappers--->'+invCredWrappers);
        
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount); 
        
        System.debug(logginglevel.error,'crList[0]--->'+crList[0]);
        
        
        JsonResult result1 = new JsonResult();
        JsonResult result2 = RefundCreditManageExt.getValidInvoicePaymentCredits(invCredWrappers,String.valueOf(custInvoice.Id),false);
        system.assert( result2.success == true,'Valid Payment Credits Not Present' );
        
        result1 = RefundCreditManageExt.createPaymentGatewayRefundReceipt(invCredWrappers,crList[0].Payment_Method_3__c,crList[0].Transaction_ID__c);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        Test.stopTest();
     
    }
    
    static testMethod void testInvoiceCredits_MultipleSearch(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<KendoUtils.FilterDescriptor> filters1 = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
        
        Customer_Receipt__c cr1 = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr1);
        
        Customer_Receipt__c cr2 = testData.createCR( testData.fuel.company, testData.fuel.customerBillTo );
        System.debug(logginglevel.error,'testData.fuel.customerBillTo-->'+testData.fuel.customerBillTo);
        crList.add(cr2);
        System.debug(logginglevel.error,'cr2-->'+cr2);
        insert crList;
        
        Customer_Receipt_Line__c crLine1 = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine1);
        
        Customer_Receipt_Line__c crLine2 = testData.createReceiptLine( crList[1],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine2);
        System.debug(logginglevel.error,'crLine2-->'+crLine2);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;
        //KNDY-13995
        crLine1 = [SELECT Customer_Invoice__c FROM Customer_Receipt_Line__c where Id = :crLine1.Id];
        
        Customer_Invoice__c prepaymentCI = [SELECT Id,(SELECT Id FROM Customer_Invoice_Lines__r)
                                                               FROM Customer_Invoice__c WHERE Id = :crLine1.Customer_Invoice__c]; //KNDY-13995
        prepaymentCIList.add(prepaymentCI);
        System.debug(logginglevel.error,'prepaymentCIList-->'+prepaymentCIList);
        
        Customer_Invoice_Line__c prePayCILine = prepaymentCI.Customer_Invoice_Lines__r[0];
        prePayCILineList.add(prePayCILine);
        
        System.debug(logginglevel.error,'prePayCILineList-->'+prePayCILineList);
        
        Customer_Invoice__c custInvoice = [ select id, Company__c, Currency__c, Customer__c, Invoice_Type__c, Balance__c, Total_Amount__c,Finalized__c from Customer_Invoice__c where id = :prepaymentCIList[0].Id ];
        system.assertEquals(-10, custInvoice.Balance__c);
        system.assertEquals(-10, custInvoice.Total_Amount__c);
        System.debug(logginglevel.error,'custInvoice--->'+custInvoice);
        
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        
        requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
        //KNDY-13995
        crLine2 = [SELECT Customer_Invoice__c FROM Customer_Receipt_Line__c where Id = :crLine2.Id];
        
        Customer_Invoice__c prepaymentCI2 = [SELECT Id,Customer__c,Bill_To_Customer__c,(SELECT Id FROM Customer_Invoice_Lines__r)
                                                               FROM Customer_Invoice__c WHERE Id = :crLine2.Customer_Invoice__c]; //KNDY-13995
        System.debug(logginglevel.error,'prepaymentCI2-->'+prepaymentCI2);
        prepaymentCIList.add(prepaymentCI2);
        
        System.debug(logginglevel.error,'prepaymentCIList-->'+prepaymentCIList);
        
        Customer_Invoice_Line__c prePayCILine2 = prepaymentCI2.Customer_Invoice_Lines__r[0];
        prePayCILineList.add(prePayCILine2);
        
        System.debug(logginglevel.error,'prePayCILineList-->'+prePayCILineList);
        
        Customer_Invoice__c custInvoice1 = [ select id, Company__c, Currency__c, Customer__c, Invoice_Type__c, Balance__c, Total_Amount__c,Finalized__c from Customer_Invoice__c where id = :prepaymentCIList[1].Id];
        system.assertEquals(-10, custInvoice1.Balance__c);
        system.assertEquals(-10, custInvoice1.Total_Amount__c);
        System.debug(logginglevel.error,'custInvoice1--->'+custInvoice1);
        
        
        Test.startTest();
        ApexPages.StandardController con = new ApexPages.StandardController(custInvoice);
        RefundCreditInvoiceLaunchExt invLaunch = new RefundCreditInvoiceLaunchExt(con);
        
        invLaunch.theCustomerInvoiceId = custInvoice.Id;
        PageReference pgRef = invLaunch.navigateToRefundCredit();
        System.debug(logginglevel.error,'pgRef---->'+pgRef);
        system.assert(pgRef != null, 'Customer Invoice is valid for refund'); //launched on to the Refund Credit page
        system.assert( Apexpages.hasMessages() == false , Apexpages.getMessages() ); 
        
        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerParent.Id;
        fd1.operator = 'eq';
        filters.add(fd1);
        
        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
       
        RefundCreditManageExt invRFCredit = new RefundCreditManageExt();
        invRFCredit.customerInvoiceId = custInvoice.Id;
        
        JsonResult result = new JsonResult();
        String creditsType = 'PaymentGateway';
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,String.valueOf(custInvoice.Id),false); 
        system.assert( result.success == true,'Valid Invoice Credits Not Present' );
        system.assert( result.records.size() == 1, 'No Invoice credits Available');
        
        List<RefundCreditService.InvoiceCreditsWrapper> invCredWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>)result.records;
        
        
        System.debug(logginglevel.error,invCredWrappers.size());
        System.debug(logginglevel.error,'invCredWrappers--->'+invCredWrappers);
        System.debug(logginglevel.error,'crList[0]--->'+crList[0]);

        JsonResult result2 = RefundCreditManageExt.getValidInvoicePaymentCredits(invCredWrappers,String.valueOf(custInvoice.Id),false);
        System.debug(logginglevel.error,'result2--->'+result2);
        
        system.assert( result2.success == true,'Valid Payment Credits Not Present' );
        system.assert( result2.records.size() == 1, 'No Payment gateway credits Available'); //one Payment Gateway Credit Record Avaialble
        
        System.debug(logginglevel.error,'testData.fuel.customerBillTo-->'+testData.fuel.customerBillTo);
        KendoUtils.FilterDescriptor fdNew1 = new KendoUtils.FilterDescriptor(); 
        fdNew1.field = 'Customer__c';
        fdNew1.fieldType = 'string';
        fdNew1.value = testData.fuel.customerBillTo.Id;
        fdNew1.operator = 'eq';
        filters1.add(fdNew1);
        
        KendoUtils.FilterDescriptor fdNew2 = new KendoUtils.FilterDescriptor();
        fdNew2.field = 'Company__c';
        fdNew2.fieldType = 'string';
        fdNew2.value = testData.fuel.company.Id;
        fdNew2.operator = 'eq';
        filters1.add(fdNew2);

        KendoUtils.FilterDescriptor fdNew3 = new KendoUtils.FilterDescriptor();
        fdNew3.field = 'Currency__c';
        fdNew3.fieldType = 'string';
        fdNew3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fdNew3.operator = 'eq';
        filters1.add(fdNew3);
        System.debug(logginglevel.error,'filters1-->'+filters1);
        
        String inCreditsType = 'PaymentGateway';
        JsonResult result3 = RefundCreditManageExt.getInvoiceCredits(filters1,inCreditsType,String.valueOf(custInvoice.Id),true);
        System.debug(logginglevel.error,'result3--->'+result3); 
        system.assert( result3.success == true,'Valid PaymentGateway Credits Not Present' );
        system.assert( result3.records.size() == 2, 'No PaymentGateway credits Available'); 
        Test.stopTest();
       
    }
    
    static testMethod void testRefundReceipt_Unfinalize(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
   
        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;
        //KNDY-13995
        crLine = [SELECT Customer_Invoice__c FROM Customer_Receipt_Line__c where Id = :crLine.Id];
        Customer_Invoice__c prepaymentCI = [SELECT Id,(SELECT Id FROM Customer_Invoice_Lines__r) FROM Customer_Invoice__c WHERE Id = :crLine.Customer_Invoice__c]; //KNDY-13995
        prepaymentCIList.add(prepaymentCI);
        
        Customer_Invoice_Line__c prePayCILine = prepaymentCI.Customer_Invoice_Lines__r[0];
        prePayCILineList.add(prePayCILine);
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest'));
        
        Customer_Invoice__c custInvoice = [ select id, Company__c, Currency__c, Customer__c, Invoice_Type__c, Balance__c, Total_Amount__c,Finalized__c from Customer_Invoice__c where id in  :prepaymentCIList];
        system.assertEquals(-10, custInvoice.Balance__c);
        system.assertEquals(-10, custInvoice.Total_Amount__c);
        System.debug(logginglevel.error,'custInvoice--->'+custInvoice);
        
        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerParent.Id;
        fd1.operator = 'eq';
        filters.add(fd1);
        
        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);
        
        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        
        Test.startTest();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,String.valueOf(custInvoice.Id),false); 
        system.assert(result.success == true,'The Credit Invoices aren not fetched');
        system.assert(result.records.size() == 1,'The Credit Invoices aren not fetched');
        
        List<RefundCreditService.InvoiceCreditsWrapper> invCredWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>)result.records;
        
        RefundCreditManageExt invRFLaunch = new RefundCreditManageExt();
        invRFLaunch.customerInvoiceId = custInvoice.Id;
        JsonResult result2 = RefundCreditManageExt.getRefundMethod();
        system.assert( result2.success == true,'Refund Method popup not rendered' );
        
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invCredWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 5;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Check';
        custReceiptList.add(custReceipt);
        
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invCredWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        
        
        String crId = null;
        for(Map<String, String> msg :result1.messages)
            if(msg.containsKey('message')){
                if(msg.get('message').contains('has been created.')){
                    crId = Id.valueOf(msg.get('message').substringBetween('/','"')); 
                }
            }
       
        System.debug(logginglevel.error,'crId--->'+crId);  
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
        Apexpages.currentPage().getParameters().put('id', crId );
        SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
        ExceptionService.messages.clear();
        try
        {
            srcDocUnfinalizeExt1.unfinalizeSourceDoc();
        }catch(Exception ex)
        {
            system.debug('CR unfinalize exception: '+ex.getMessage());
        }
        
        boolean ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages())
            if(msg.getDetail().contains(Label.Cannot_Unfinalize_Refund_Customer_Receipts))
            {
                ErrorExists = true;  
                break;
            }
        system.assertEquals(ErrorExists,true, ApexPages.GetMessages()); // CR of Refund Type not allowed to be Unfinalized.
        
        custReceipt = [Select Id, Finalized__c, Status__c from Customer_Receipt__c where id = :crId limit 1];
        system.assertEquals(custReceipt.Finalized__c, true, 'CR is not Finalized');
        system.assertEquals(custReceipt.Status__c, 'Closed', 'CR Status should be in Closed');  
        
        Test.stopTest();
     
    }
    
    static testMethod void testRefundReceipt_Cancel(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
   
        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
        }
        update crList;
        //KNDY-13995
        crLine = [SELECT Customer_Invoice__c FROM Customer_Receipt_Line__c where Id = :crLine.Id];
        Customer_Invoice__c prepaymentCI = [SELECT Id,(SELECT Id FROM Customer_Invoice_Lines__r) FROM Customer_Invoice__c WHERE Id = :crLine.Customer_Invoice__c]; //KNDY-13995
        prepaymentCIList.add(prepaymentCI);
        
        Customer_Invoice_Line__c prePayCILine = prepaymentCI.Customer_Invoice_Lines__r[0];
        prePayCILineList.add(prePayCILine);
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest'));
        
        Customer_Invoice__c custInvoice = [ select id, Company__c, Currency__c, Customer__c, Invoice_Type__c, Balance__c, Total_Amount__c,Finalized__c from Customer_Invoice__c where id in  :prepaymentCIList];
        system.assertEquals(-10, custInvoice.Balance__c);
        system.assertEquals(-10, custInvoice.Total_Amount__c);
        System.debug(logginglevel.error,'custInvoice--->'+custInvoice);
        
        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerParent.Id;
        fd1.operator = 'eq';
        filters.add(fd1);
        
        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);
        
        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        
        Test.startTest();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,String.valueOf(custInvoice.Id),false); 
        system.assert(result.success == true,'The Credit Invoices aren not fetched');
        system.assert(result.records.size() == 1,'The Credit Invoices aren not fetched');
        
        List<RefundCreditService.InvoiceCreditsWrapper> invCredWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>)result.records;
        
        RefundCreditManageExt invRFLaunch = new RefundCreditManageExt();
        invRFLaunch.customerInvoiceId = custInvoice.Id;
        JsonResult result2 = RefundCreditManageExt.getRefundMethod();
        system.assert( result2.success == true,'Refund Method popup not rendered' );
        
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invCredWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 10;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Check';
        custReceiptList.add(custReceipt);
        
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invCredWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        
        custInvoice = [ select id, Company__c, Status__c, Balance__c, Finalized__c from Customer_Invoice__c where id = :custInvoice.Id limit 1];
        System.debug(logginglevel.error,custInvoice);
        system.assertEquals(custInvoice.Finalized__c,true);
        system.assertEquals(custInvoice.Status__c,'Closed'); //CI is in closed status
        system.assertEquals(0, custInvoice.Balance__c); //CI balance is 0
        
        String crId = null;
        for(Map<String, String> msg :result1.messages)
            if(msg.containsKey('message')){
                if(msg.get('message').contains('has been created.')){
                    crId = Id.valueOf(msg.get('message').substringBetween('/','"')); 
                }
            }
       
        System.debug(logginglevel.error,'crId--->'+crId);  
        custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
                       from Customer_Receipt__c where id = :crId limit 1 ];
        
        CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
        system.assert(!ext.getDisableCancel() == true,'Can cancel CRs');
        
        ext.CancelDocs();
        //KNDY-13995
        custReceipt = [Select Id, Finalized__c, Status__c, (Select Id, Amount__c, Type__c, Customer_Invoice__c from Customer_Receipt_Lines__r) from Customer_Receipt__c where id = :crId limit 1];
            
        system.assertEquals(custReceipt.Finalized__c, false);
        system.assertEquals(custReceipt.Status__c, 'Cancelled'); //CR has been cancelled
        
        custInvoice = [ select id, Company__c, Status__c, Balance__c, Finalized__c from Customer_Invoice__c where id = :custReceipt.Customer_Receipt_Lines__r[0].Customer_Invoice__c limit 1]; //KNDY-13995
        System.debug(logginglevel.error,custInvoice);
        system.assertEquals(custInvoice.Finalized__c,true);
        system.assertEquals(custInvoice.Status__c,'Open'); //CI is reset to open status
        system.assertEquals(-10, custInvoice.Balance__c); //CI balance reset to -10
        
        Test.stopTest();
    }
    
    static testMethod void testRefundReceipt_Void(){
        
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        
        List<Customer_Invoice__c> prepaymentCIList = new  List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> prePayCILineList = new List<Customer_Invoice_Line__c>();
        List<Customer_Receipt__c> crList = new  List<Customer_Receipt__c>();
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
   
        Customer_Receipt__c cr = testData.createCR( testData.fuel.company, testData.fuel.customerParent );
        crList.add(cr);
        insert crList;
        
        Customer_Receipt_Line__c crLine = testData.createReceiptLine( crList[0],testData.fuel.customerBillTo, testData.fuel.salesOrder );  
        crLineList.add(crLine);
        insert crLineList;
        
        for(Customer_Receipt__c cusRecp : crList){  
          cusRecp.Finalized__c = true;
    }
        update crList;
        //KNDY-13995
        crLine = [SELECT Customer_Invoice__c FROM Customer_Receipt_Line__c where Id = :crLine.Id];
        Customer_Invoice__c prepaymentCI = [SELECT Id,(SELECT Id,Finalized__c FROM Customer_Invoice_Lines__r) FROM Customer_Invoice__c WHERE Id = :crLine.Customer_Invoice__c]; //KNDY-13995
        System.debug(logginglevel.error,prepaymentCI.Customer_Invoice_Lines__r);
        prepaymentCIList.add(prepaymentCI);
        
        Customer_Invoice_Line__c prePayCILine = prepaymentCI.Customer_Invoice_Lines__r[0];
        prePayCILineList.add(prePayCILine);
        
        Customer_Invoice__c custInvoice = [ select id, Company__c, Currency__c, Customer__c, Invoice_Type__c, Balance__c, Total_Amount__c,Finalized__c from Customer_Invoice__c where id in  :prepaymentCIList];
        system.assertEquals(-10, custInvoice.Balance__c); //Initial Balance on the CI
        system.assertEquals(-10, custInvoice.Total_Amount__c);
        System.debug(logginglevel.error,'custInvoice--->'+custInvoice);
        
        
        Double totalRefundAmount = 10.00;
        
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Cash';
        insert custReceipt;
        
        Customer_Receipt_Line__c OverPaymentLine = new Customer_Receipt_Line__c();
        OverPaymentLine.Amount__c = -10;
        OverPaymentLine.Customer_Receipt__c = custReceipt.Id;
        OverPaymentLine.Type__c = PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT;
        OverPaymentLine.Customer__c = testData.fuel.customerBillTo.id;
        OverPaymentLine.Customer_Invoice__c = custInvoice.Id; //KNDY-13995
        insert OverPaymentLine;
        
        custReceipt.Finalized__c = true;
        update custReceipt;
        
        custInvoice = [ select id, Company__c, Status__c, Balance__c, Finalized__c from Customer_Invoice__c where id = :custInvoice.Id limit 1];
        System.debug(logginglevel.error,custInvoice);
        system.assertEquals(custInvoice.Finalized__c,true);
        system.assertEquals(custInvoice.Status__c,'Closed'); //CI is in closed status
        system.assertEquals(0, custInvoice.Balance__c); //CI balance is 0
      
        Test.startTest();
        system.assert(testData.lARs.size() >0);
        
        AccountingService cia = new CustomerReceiptAccounting();
        list <Customer_Receipt_Line__c> crlLines = new list <Customer_Receipt_Line__c>();
        crlLines.add(OverPaymentLine);
        
        cia.execute(crlLines);
        
        custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c, Customer_Receipt__c from Customer_Receipt_Lines__r),
                       (Select Id, Has_Exceptions__c from Accounting_Entries__r) 
                       from Customer_Receipt__c where id = :custReceipt.id limit 1 ];
        
        system.debug('test: ae '+ custReceipt.Accounting_Entries__r);
        system.debug([select id, subject from Task where whatId = :custReceipt.Accounting_Entries__r.get(0).Id]);
        for(Accounting_Entry_Line__c ael : [Select Id, SubTransaction_type__c, line_Type__c, (select id, subject from Tasks) from Accounting_Entry_Line__c where Accounting_Entry__c = :custReceipt.Accounting_Entries__r.get(0).Id])
        {
            system.debug('ael: '+ael);
            system.debug('ael with tasks: '+ael.Tasks);
        }
        
        CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
        system.assert(!ext.getDisableVoid() == true,'Can cancel CRs');
        
        ext.voidDocs();
        
        custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r)
                       from Customer_Receipt__c where id = :custReceipt.id limit 1 ];
        
        system.assertEquals(custReceipt.Finalized__c, true);  
        system.assertEquals(custReceipt.Status__c, 'Void');
        
        custInvoice = [ select id, Company__c, Status__c, Balance__c, Finalized__c from Customer_Invoice__c where id = :custInvoice.Id limit 1];
        System.debug(logginglevel.error,custInvoice);
        system.assertEquals(custInvoice.Finalized__c,true);
        system.assertEquals(custInvoice.Status__c,'Open'); //CI is reset to open status
        system.assertEquals(-10, custInvoice.Balance__c); //CI balance reset to -10 
        
        Test.stopTest();
    }
    
    //KNDY-17697 - thru claim refund credit and due to no of advice lines are < CR lines it will create void check number with cancelled CR
    static testMethod void Claim_testCreateRefundReceipt_CheckOverflow(){
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        
        //fetch bank account and update preprinted stock true and no of advice lines to 1 to create overflow of remittance
        //KNDY-18900 Replace next check number (number) field with text field
        Bank_Account__c bankAcct  = [select id,GL_Account__c,account_type__c,active__c,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c,Next_Check_Number_2__c from  Bank_Account__c where Name = 'Test BOFA'];
        bankAcct.Use_Pre_Printed_Check_Stock__c = true;
        bankAcct.Number_of_Advice_Lines_Per_Page__c = 1 ;
        bankAcct.Next_Check_Number_2__c = '1';
        update bankAcct; 
        
        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_PREPAYMENT, 'Open');
        cis.add(aaCI);
        Customer_Invoice__c aaCI1 = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_OVERPAYMENT, 'Open');
        cis.add(aaCI1);
        insert cis;
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        cils.add(aaCILine);
        Customer_Invoice_Line__c aaCILine1 = testData.createCILine(aaCI1);
        cils.add(aaCILine1);
        insert cils;
        aaCI.Finalized__c = true;
        aaCI1.Finalized__c = true; 
        update cis;

        Claim__c cl = testData.createClaim();
        cl.Source__c = 'Manual';
        cl.Amount__c = 200;
        insert cl;

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        // Set Claim Id in page url
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('claimId', cl.Id);
        RefundCreditManageExt ext = new RefundCreditManageExt();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        //Get Customer Invoice Wrappers
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        System.debug(logginglevel.error,'result-->'+result);
        system.assert(result.success == true,'The Credit Invoices are not fetched');
        system.assert(result.records.size() == 2,'The Credit Invoices are not fetched');
        List<RefundCreditService.InvoiceCreditsWrapper> invoicCreditWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>) result.records;
        
        // Set amount to refund on ci wrappers
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invoicCreditWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 100.00;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        // Set up a CR to insert with Claim lookup
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;
        custReceipt.Claim__c = cl.Id;
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Check';
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        System.debug(logginglevel.error,invoicCreditWrappers.size());
        System.debug(logginglevel.error,'invoicCreditWrappers--->'+invoicCreditWrappers);
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        // Call extension method that creates CR
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invoicCreditWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        Test.stopTest();
        
        // CI asserts
        List<Customer_Invoice__c > ciList = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id IN :cis];
        for (Customer_Invoice__c CI :ciList){
        	system.assertEquals(CI.Balance__c, 0, '>>> CI:'+CI);
        	system.assertEquals(CI.Status__c, 'Closed','>>> CI:'+CI);
        }
        // CR and CRL asserts
        List<Customer_Receipt__c> crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Claim__c = :cl.Id];
        system.assertEquals(crs.size() ,1, '>>> crs: ' + crs);
        system.assertEquals(crs[0].Customer_Receipt_Lines__r.size() ,2, '>>> Customer receipt line is not matching: ' + crs[0].Customer_Receipt_Lines__r);
        Customer_Receipt__c cr = crs[0];
        system.assertEquals(cr.Type__c, 'Refund', '>>>> cr: ' + cr);
        system.assertEquals(cr.Reference_Number__c, '1', '>>>> wrong reference number: ' + cr);
        system.assertEquals(cr.Status__c, 'Closed', '>>>> cr: ' + cr);
        system.assertEquals(cr.Finalized__c, true, '>>>> cr: ' + cr);
        system.assertEquals(cr.Amount_Unapplied__c, 0, '>>>> cr: ' + cr);
        system.assertEquals(cr.Customer_Receipt_Lines__r.size(), 2, '>>>> cr.Customer_Receipt_Lines__r: ' + cr.Customer_Receipt_Lines__r);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Type__c, PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[1].Customer_Invoice__c, aaCI1.Id, '>>> cr.Customer_Receipt_Lines__r[1]: '+ cr.Customer_Receipt_Lines__r[1]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Amount__c, -100, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        
        //check for cancelled CR
        crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,Status_Reason__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Customer__c = :testData.fuel.customerBillTo.Id and Status__c ='Cancelled'];
      	system.assertEquals(crs.size() ,1, '>>> crs: ' + crs);
        system.assertEquals(crs[0].Customer_Receipt_Lines__r.size() ,0, '>>> Customer receipt line is not matching: ' + crs[0].Customer_Receipt_Lines__r);
        cr = crs[0];
        system.assertEquals(cr.Type__c, 'Refund', '>>>> cr: ' + cr); 
        system.assertEquals(cr.Reference_Number__c, '2', '>>>> wrong reference number: ' + cr);
        system.assertEquals(cr.Status__c, 'Cancelled', '>>>> cr: ' + cr);
        system.assertEquals(cr.Status_Reason__c, 'Void from Overflow Advice', '>>>> cr: ' + cr);
        system.assertEquals(cr.Finalized__c, false, '>>>> cr: ' + cr);
        system.assertEquals(cr.Amount_Unapplied__c, 0, '>>>> cr: ' + cr);
        system.assertEquals(cr.Claim__c, null, '>>>> cr: ' + cr);
        system.assertEquals(cr.Customer_Receipt_Lines__r.size(), 0, '>>>> cr.Customer_Receipt_Lines__r: ' + cr.Customer_Receipt_Lines__r);
        // Manual claim asserts        
        cl = [Select Id, Status__c, Settlement_Method__c, Claim_Balance__c,
               (Select Id, Customer_Invoice__c from Claim_Lines__r)
              from Claim__c where Id = :cl.Id];
        system.assertEquals(cl.Status__c, 'Closed', '>>> cl: ' + cl);
        system.assertEquals(cl.Settlement_Method__c, 'Refund', '>>> cl: ' + cl);
        system.assertEquals(cl.Claim_Balance__c, 0, '>>> cl: ' + cl);
        system.assertEquals(cl.Claim_Lines__r.size(), 2);
        system.assertEquals(cl.Claim_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cl.Claim_Lines__r[0]:' + cl.Claim_Lines__r[0]);
        system.assertEquals(cl.Claim_Lines__r[1].Customer_Invoice__c, aaCI1.Id, '>>> cl.Claim_Lines__r[1]:' + cl.Claim_Lines__r[1]);
    }
    
    //KNDY-17697 - thru claim refund credit and due to no of advice lines are < CR lines it will create void check number without cancelled CR
    static testMethod void Claim_testCreateRefundReceipt_NoCheckOverflow(){
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        
        //fetch bank account and update preprinted stock true and no of advice lines to 1 to create overflow of remittance
        //KNDY-18900 Replace next check number (number) field with text field
        Bank_Account__c bankAcct  = [select id,GL_Account__c,account_type__c,active__c,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c,Next_Check_Number_2__c from  Bank_Account__c where Name = 'Test BOFA'];
        bankAcct.Use_Pre_Printed_Check_Stock__c = true;
        bankAcct.Number_of_Advice_Lines_Per_Page__c = 10 ;
        bankAcct.Next_Check_Number_2__c = '1';
        update bankAcct;
        
        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_PREPAYMENT, 'Open');
        cis.add(aaCI);
        Customer_Invoice__c aaCI1 = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_OVERPAYMENT, 'Open');
        cis.add(aaCI1);
        insert cis;
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        cils.add(aaCILine);
        Customer_Invoice_Line__c aaCILine1 = testData.createCILine(aaCI1);
        cils.add(aaCILine1);
        insert cils;
        aaCI.Finalized__c = true;
        aaCI1.Finalized__c = true; 
        update cis;

        Claim__c cl = testData.createClaim();
        cl.Source__c = 'Manual';
        cl.Amount__c = 200;
        insert cl;

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        // Set Claim Id in page url
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('claimId', cl.Id);
        RefundCreditManageExt ext = new RefundCreditManageExt();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        //Get Customer Invoice Wrappers
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        System.debug(logginglevel.error,'result-->'+result);
        system.assert(result.success == true,'The Credit Invoices are not fetched');
        system.assert(result.records.size() == 2,'The Credit Invoices are not fetched');
        List<RefundCreditService.InvoiceCreditsWrapper> invoicCreditWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>) result.records;
        system.debug(LoggingLevel.Error,'invoicCreditWrappers '+invoicCreditWrappers);
        // Set amount to refund on ci wrappers
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invoicCreditWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 100.00;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        // Set up a CR to insert with Claim lookup
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;
        custReceipt.Claim__c = cl.Id;
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Check';
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        System.debug(logginglevel.error,invoicCreditWrappers.size());
        System.debug(logginglevel.error,'invoicCreditWrappers--->'+invoicCreditWrappers);
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        // Call extension method that creates CR
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invoicCreditWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        Test.stopTest();
        
        /*// CI asserts
        List<Customer_Invoice__c > ciList = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id IN :cis];
        for (Customer_Invoice__c CI :ciList){
        	system.assertEquals(CI.Balance__c, 0, '>>> CI:'+CI);
        	system.assertEquals(CI.Status__c, 'Closed','>>> CI:'+CI);
        }*/
        // CR and CRL asserts
        List<Customer_Receipt__c> crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Claim__c = :cl.Id];
        system.assertEquals(crs.size() ,1, '>>> crs: ' + crs);
        system.assertEquals(crs[0].Customer_Receipt_Lines__r.size() ,2, '>>> Customer receipt line is not matching: ' + crs[0].Customer_Receipt_Lines__r);
        Customer_Receipt__c cr = crs[0];
        system.assertEquals(cr.Type__c, 'Refund', '>>>> cr: ' + cr);
        system.assertEquals(cr.Reference_Number__c, '1', '>>>> wrong reference number: ' + cr);
        system.assertEquals(cr.Status__c, 'Closed', '>>>> cr: ' + cr);
        system.assertEquals(cr.Finalized__c, true, '>>>> cr: ' + cr);
        system.assertEquals(cr.Amount_Unapplied__c, 0, '>>>> cr: ' + cr);
        system.assertEquals(cr.Customer_Receipt_Lines__r.size(), 2, '>>>> cr.Customer_Receipt_Lines__r: ' + cr.Customer_Receipt_Lines__r);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Type__c, PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[1].Customer_Invoice__c, aaCI1.Id, '>>> cr.Customer_Receipt_Lines__r[1]: '+ cr.Customer_Receipt_Lines__r[1]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Amount__c, -100, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        
        //check for cancelled CR - it shouldn't be creating any cancelled CR
        crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,Status_Reason__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Customer__c = :testData.fuel.customerBillTo.Id and Status__c ='Cancelled'];
      	system.assertEquals(crs.size() ,0, '>>> crs: ' + crs);
        
       
        // Manual claim asserts        
        cl = [Select Id, Status__c, Settlement_Method__c, Claim_Balance__c,
               (Select Id, Customer_Invoice__c from Claim_Lines__r)
              from Claim__c where Id = :cl.Id];
        system.assertEquals(cl.Status__c, 'Closed', '>>> cl: ' + cl);
        system.assertEquals(cl.Settlement_Method__c, 'Refund', '>>> cl: ' + cl);
        system.assertEquals(cl.Claim_Balance__c, 0, '>>> cl: ' + cl);
        system.assertEquals(cl.Claim_Lines__r.size(), 2);
        system.assertEquals(cl.Claim_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cl.Claim_Lines__r[0]:' + cl.Claim_Lines__r[0]);
        system.assertEquals(cl.Claim_Lines__r[1].Customer_Invoice__c, aaCI1.Id, '>>> cl.Claim_Lines__r[1]:' + cl.Claim_Lines__r[1]);
    } 
    //KNDY-17697 - thru CI refund credit and due to no of advice lines are < CR lines it will create void check number with cancelled CR
    static testMethod void CI_testCreateRefundReceipt_CheckOverflow(){
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        
        //fetch bank account and update preprinted stock true and no of advice lines to 1 to create overflow of remittance
        //KNDY-18900 Replace next check number (number) field with text field
        Bank_Account__c bankAcct  = [select id,GL_Account__c,account_type__c,active__c,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c,Next_Check_Number_2__c from  Bank_Account__c where Name = 'Test BOFA'];
        bankAcct.Use_Pre_Printed_Check_Stock__c = true;
        bankAcct.Number_of_Advice_Lines_Per_Page__c = 1 ;
        bankAcct.Next_Check_Number_2__c = '1';
        update bankAcct;
        
        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_PREPAYMENT, 'Open');
        cis.add(aaCI);       
        insert cis;
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        cils.add(aaCILine);        
        insert cils;
        aaCI.Finalized__c = true;        
        update cis;
        

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        // Set Claim Id in page url
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('ciId', aaCI.Id);
        RefundCreditManageExt ext = new RefundCreditManageExt();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        //Get Customer Invoice Wrappers
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,aaCI.id,false); 
        System.debug(logginglevel.error,'result-->'+result);
        system.assert(result.success == true,'The Credit Invoices are not fetched');
        system.assert(result.records.size() == 1,'The Credit Invoices are not fetched');
        List<RefundCreditService.InvoiceCreditsWrapper> invoicCreditWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>) result.records;
        
        // Set amount to refund on ci wrappers
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invoicCreditWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 100.00;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        // Set up a CR to insert with Claim lookup
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;   
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Check';
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        System.debug(logginglevel.error,invoicCreditWrappers.size());
        System.debug(logginglevel.error,'invoicCreditWrappers--->'+invoicCreditWrappers);
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        // Call extension method that creates CR
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invoicCreditWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        Test.stopTest();
        
        // CI asserts
        List<Customer_Invoice__c > ciList = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id IN :cis];
        for (Customer_Invoice__c CI :ciList){
        	system.assertEquals(CI.Balance__c, 0, '>>> CI:'+CI);
        	system.assertEquals(CI.Status__c, 'Closed','>>> CI:'+CI);
        }
        // CR and CRL asserts
        List<Customer_Receipt__c> crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Customer__c = :testData.fuel.customerBillTo.Id];
        system.assertEquals(crs.size() ,1, '>>> crs: ' + crs);
        system.assertEquals(crs[0].Customer_Receipt_Lines__r.size() ,1, '>>> Customer receipt line is not matching: ' + crs[0].Customer_Receipt_Lines__r);
        Customer_Receipt__c cr = crs[0];
        system.assertEquals(cr.Type__c, 'Refund', '>>>> cr: ' + cr);
        system.assertEquals(cr.Reference_Number__c, '1', '>>>> wrong reference number: ' + cr);
        system.assertEquals(cr.Status__c, 'Closed', '>>>> cr: ' + cr);
        system.assertEquals(cr.Finalized__c, true, '>>>> cr: ' + cr);
        system.assertEquals(cr.Amount_Unapplied__c, 0, '>>>> cr: ' + cr);        
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Type__c, PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Amount__c, -100, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        
        //check for cancelled CR
        //check for cancelled CR - it shouldn't be creating any cancelled CR
        crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,Status_Reason__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Customer__c = :testData.fuel.customerBillTo.Id and Status__c ='Cancelled'];
      	system.assertEquals(crs.size() ,0, '>>> crs: ' + crs);
    }    
    //KNDY-17697 - all eligible credit and due to no of advice lines are < CR lines it will create void check number with cancelled CR
    static testMethod void AllCI_testCreateRefundReceipt_CheckOverflow(){
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        
        //fetch bank account and update preprinted stock true and no of advice lines to 1 to create overflow of remittance
        //KNDY-18900 Replace next check number (number) field with text field
        Bank_Account__c bankAcct  = [select id,GL_Account__c,account_type__c,active__c,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c,Next_Check_Number_2__c from  Bank_Account__c where Name = 'Test BOFA'];
        bankAcct.Use_Pre_Printed_Check_Stock__c = true;
        bankAcct.Number_of_Advice_Lines_Per_Page__c = 1 ;
        bankAcct.Next_Check_Number_2__c = '1';
        update bankAcct;
        
        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_PREPAYMENT, 'Open');
        cis.add(aaCI);
        Customer_Invoice__c aaCI1 = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_OVERPAYMENT, 'Open');
        cis.add(aaCI1);
        insert cis;
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        cils.add(aaCILine);
        Customer_Invoice_Line__c aaCILine1 = testData.createCILine(aaCI1);
        cils.add(aaCILine1);
        insert cils;
        aaCI.Finalized__c = true;
        aaCI1.Finalized__c = true; 
        update cis;


        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        RefundCreditManageExt ext = new RefundCreditManageExt();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        //Get Customer Invoice Wrappers
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        System.debug(logginglevel.error,'result-->'+result);
        system.assert(result.success == true,'The Credit Invoices are not fetched');
        system.assert(result.records.size() == 2,'The Credit Invoices are not fetched');
        List<RefundCreditService.InvoiceCreditsWrapper> invoicCreditWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>) result.records;
        
        // Set amount to refund on ci wrappers
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invoicCreditWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 100.00;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        // Set up a CR to insert with Claim lookup
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;     
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Check';
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        System.debug(logginglevel.error,invoicCreditWrappers.size());
        System.debug(logginglevel.error,'invoicCreditWrappers--->'+invoicCreditWrappers);
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        // Call extension method that creates CR
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invoicCreditWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' +result1 );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        Test.stopTest();
        
        // CI asserts
        List<Customer_Invoice__c > ciList = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id IN :cis];
        for (Customer_Invoice__c CI :ciList){
        	system.assertEquals(CI.Balance__c, 0, '>>> CI:'+CI);
        	system.assertEquals(CI.Status__c, 'Closed','>>> CI:'+CI);
        }
        // CR and CRL asserts
        List<Customer_Receipt__c> crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Customer__c = :testData.fuel.customerBillTo.Id and Status__c = 'Closed'];
        system.assertEquals(crs.size() ,1, '>>> crs: ' + crs);
        system.assertEquals(crs[0].Customer_Receipt_Lines__r.size() ,2, '>>> Customer receipt line is not matching: ' + crs[0].Customer_Receipt_Lines__r);
        Customer_Receipt__c cr = crs[0];
        system.assertEquals(cr.Type__c, 'Refund', '>>>> cr: ' + cr);
        system.assertEquals(cr.Reference_Number__c, '1', '>>>> wrong reference number: ' + cr);
        system.assertEquals(cr.Status__c, 'Closed', '>>>> cr: ' + cr);
        system.assertEquals(cr.Finalized__c, true, '>>>> cr: ' + cr);
        system.assertEquals(cr.Amount_Unapplied__c, 0, '>>>> cr: ' + cr);
        system.assertEquals(cr.Customer_Receipt_Lines__r.size(), 2, '>>>> cr.Customer_Receipt_Lines__r: ' + cr.Customer_Receipt_Lines__r);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Type__c, PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[1].Customer_Invoice__c, aaCI1.Id, '>>> cr.Customer_Receipt_Lines__r[1]: '+ cr.Customer_Receipt_Lines__r[1]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Amount__c, -100, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        
        //check for cancelled CR
        crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,Status_Reason__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Customer__c = :testData.fuel.customerBillTo.Id and Status__c ='Cancelled'];
      	system.assertEquals(crs.size() ,1, '>>> crs: ' + crs);
        system.assertEquals(crs[0].Customer_Receipt_Lines__r.size() ,0, '>>> Customer receipt line is not matching: ' + crs[0].Customer_Receipt_Lines__r);
        cr = crs[0];
        system.assertEquals(cr.Type__c, 'Refund', '>>>> cr: ' + cr); 
        system.assertEquals(cr.Reference_Number__c, '2', '>>>> wrong reference number: ' + cr);
        system.assertEquals(cr.Status__c, 'Cancelled', '>>>> cr: ' + cr);
        system.assertEquals(cr.Status_Reason__c, 'Void from Overflow Advice', '>>>> cr: ' + cr);
        system.assertEquals(cr.Finalized__c, false, '>>>> cr: ' + cr);
        system.assertEquals(cr.Amount_Unapplied__c, 0, '>>>> cr: ' + cr);
        system.assertEquals(cr.Claim__c, null, '>>>> cr: ' + cr);
        system.assertEquals(cr.Customer_Receipt_Lines__r.size(), 0, '>>>> cr.Customer_Receipt_Lines__r: ' + cr.Customer_Receipt_Lines__r);        
    }
    //KNDY-17697 - all eligible credit and due to no of advice lines are < CR lines it will create void check number without cancelled CR 
    static testMethod void AllCI_testCreateRefundReceipt_NoCheckOverflow(){
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        
        //fetch bank account and update preprinted stock true and no of advice lines to 1 to create overflow of remittance
        //KNDY-18900 Replace next check number (number) field with text field        
        Bank_Account__c bankAcct  = [select id,GL_Account__c,account_type__c,active__c,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c,Next_Check_Number_2__c from  Bank_Account__c where Name = 'Test BOFA'];
        bankAcct.Use_Pre_Printed_Check_Stock__c = true;
        bankAcct.Number_of_Advice_Lines_Per_Page__c = 10 ;
        bankAcct.Next_Check_Number_2__c = '1';
        update bankAcct;
        
        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_PREPAYMENT, 'Open');
        cis.add(aaCI);
        Customer_Invoice__c aaCI1 = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_OVERPAYMENT, 'Open');
        cis.add(aaCI1);
        insert cis;
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        cils.add(aaCILine);
        Customer_Invoice_Line__c aaCILine1 = testData.createCILine(aaCI1);
        cils.add(aaCILine1);
        insert cils;
        aaCI.Finalized__c = true;
        aaCI1.Finalized__c = true; 
        update cis;

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        // Set Claim Id in page url
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        RefundCreditManageExt ext = new RefundCreditManageExt();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        //Get Customer Invoice Wrappers
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        System.debug(logginglevel.error,'result-->'+result);
        system.assert(result.success == true,'The Credit Invoices are not fetched');
        system.assert(result.records.size() == 2,'The Credit Invoices are not fetched');
        List<RefundCreditService.InvoiceCreditsWrapper> invoicCreditWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>) result.records;
        
        // Set amount to refund on ci wrappers
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invoicCreditWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 100.00;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        // Set up a CR to insert with Claim lookup
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;        
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Check';
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        System.debug(logginglevel.error,invoicCreditWrappers.size());
        System.debug(logginglevel.error,'invoicCreditWrappers--->'+invoicCreditWrappers);
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        // Call extension method that creates CR
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invoicCreditWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        Test.stopTest();
        
        // CI asserts
        List<Customer_Invoice__c > ciList = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id IN :cis];
        for (Customer_Invoice__c CI :ciList){
        	system.assertEquals(CI.Balance__c, 0, '>>> CI:'+CI);
        	system.assertEquals(CI.Status__c, 'Closed','>>> CI:'+CI);
        }
        // CR and CRL asserts
        List<Customer_Receipt__c> crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Customer__c = :testData.fuel.customerBillTo.Id and Status__c ='Closed'];
        system.assertEquals(crs.size() ,1, '>>> crs: ' + crs);
        system.assertEquals(crs[0].Customer_Receipt_Lines__r.size() ,2, '>>> Customer receipt line is not matching: ' + crs[0].Customer_Receipt_Lines__r);
        Customer_Receipt__c cr = crs[0];
        system.assertEquals(cr.Type__c, 'Refund', '>>>> cr: ' + cr);
        system.assertEquals(cr.Reference_Number__c, '1', '>>>> wrong reference number: ' + cr);
        system.assertEquals(cr.Status__c, 'Closed', '>>>> cr: ' + cr);
        system.assertEquals(cr.Finalized__c, true, '>>>> cr: ' + cr);
        system.assertEquals(cr.Amount_Unapplied__c, 0, '>>>> cr: ' + cr);
        system.assertEquals(cr.Customer_Receipt_Lines__r.size(), 2, '>>>> cr.Customer_Receipt_Lines__r: ' + cr.Customer_Receipt_Lines__r);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Type__c, PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[1].Customer_Invoice__c, aaCI1.Id, '>>> cr.Customer_Receipt_Lines__r[1]: '+ cr.Customer_Receipt_Lines__r[1]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Amount__c, -100, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        
        //check for cancelled CR - it shouldn't be creating any cancelled CR
        crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,Status_Reason__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Customer__c = :testData.fuel.customerBillTo.Id and Status__c ='Cancelled'];
      	system.assertEquals(crs.size() ,0, '>>> crs: ' + crs);
        
       
    } 
    //KNDY-17697 - thru claim refund credit and payment method other than Check
    static testMethod void Claim_testCreateRefundReceipt_CashRefund(){
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        
        //fetch bank account and update preprinted stock true and no of advice lines to 1 to create overflow of remittance
        //KNDY-18900 Replace next check number (number) field with text field
        Bank_Account__c bankAcct  = [select id,GL_Account__c,account_type__c,active__c,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c,Next_Check_Number_2__c from  Bank_Account__c where Name = 'Test BOFA'];
        bankAcct.Use_Pre_Printed_Check_Stock__c = true;
        bankAcct.Number_of_Advice_Lines_Per_Page__c = 10 ;
        bankAcct.Next_Check_Number_2__c = '1';
        update bankAcct;
        
        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_PREPAYMENT, 'Open');
        cis.add(aaCI);
        Customer_Invoice__c aaCI1 = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_OVERPAYMENT, 'Open');
        cis.add(aaCI1);
        insert cis;
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        cils.add(aaCILine);
        Customer_Invoice_Line__c aaCILine1 = testData.createCILine(aaCI1);
        cils.add(aaCILine1);
        insert cils;
        aaCI.Finalized__c = true;
        aaCI1.Finalized__c = true; 
        update cis;

        Claim__c cl = testData.createClaim();
        cl.Source__c = 'Manual';
        cl.Amount__c = 200;
        insert cl;

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        // Set Claim Id in page url
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('claimId', cl.Id);
        RefundCreditManageExt ext = new RefundCreditManageExt();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        //Get Customer Invoice Wrappers
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        System.debug(logginglevel.error,'result-->'+result);
        system.assert(result.success == true,'The Credit Invoices are not fetched');
        system.assert(result.records.size() == 2,'The Credit Invoices are not fetched');
        List<RefundCreditService.InvoiceCreditsWrapper> invoicCreditWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>) result.records;
        
        // Set amount to refund on ci wrappers
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invoicCreditWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 100.00;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        // Set up a CR to insert with Claim lookup
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;
        custReceipt.Claim__c = cl.Id;
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'Cash';
        custReceipt.Reference_Number__c = '123456';
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        System.debug(logginglevel.error,invoicCreditWrappers.size());
        System.debug(logginglevel.error,'invoicCreditWrappers--->'+invoicCreditWrappers);
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        // Call extension method that creates CR
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invoicCreditWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        Test.stopTest();
        
        // CI asserts
        List<Customer_Invoice__c > ciList = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id IN :cis];
        for (Customer_Invoice__c CI :ciList){
        	system.assertEquals(CI.Balance__c, 0, '>>> CI:'+CI);
        	system.assertEquals(CI.Status__c, 'Closed','>>> CI:'+CI);
        }
        // CR and CRL asserts
        List<Customer_Receipt__c> crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Claim__c = :cl.Id];
        system.assertEquals(crs.size() ,1, '>>> crs: ' + crs);
        system.assertEquals(crs[0].Customer_Receipt_Lines__r.size() ,2, '>>> Customer receipt line is not matching: ' + crs[0].Customer_Receipt_Lines__r);
        Customer_Receipt__c cr = crs[0];
        system.assertEquals(cr.Type__c, 'Refund', '>>>> cr: ' + cr);
        system.assertEquals(cr.Reference_Number__c, '123456', '>>>> wrong reference number: ' + cr);
        system.assertEquals(cr.Status__c, 'Closed', '>>>> cr: ' + cr);
        system.assertEquals(cr.Finalized__c, true, '>>>> cr: ' + cr);
        system.assertEquals(cr.Amount_Unapplied__c, 0, '>>>> cr: ' + cr);
        system.assertEquals(cr.Customer_Receipt_Lines__r.size(), 2, '>>>> cr.Customer_Receipt_Lines__r: ' + cr.Customer_Receipt_Lines__r);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Type__c, PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[1].Customer_Invoice__c, aaCI1.Id, '>>> cr.Customer_Receipt_Lines__r[1]: '+ cr.Customer_Receipt_Lines__r[1]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Amount__c, -100, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        
        //check for cancelled CR - it shouldn't be creating any cancelled CR
        crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,Status_Reason__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Customer__c = :testData.fuel.customerBillTo.Id and Status__c ='Cancelled'];
      	system.assertEquals(crs.size() ,0, '>>> crs: ' + crs);
        
       
        // Manual claim asserts        
        cl = [Select Id, Status__c, Settlement_Method__c, Claim_Balance__c,
               (Select Id, Customer_Invoice__c from Claim_Lines__r)
              from Claim__c where Id = :cl.Id];
        system.assertEquals(cl.Status__c, 'Closed', '>>> cl: ' + cl);
        system.assertEquals(cl.Settlement_Method__c, 'Refund', '>>> cl: ' + cl);
        system.assertEquals(cl.Claim_Balance__c, 0, '>>> cl: ' + cl);
        system.assertEquals(cl.Claim_Lines__r.size(), 2);
        system.assertEquals(cl.Claim_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cl.Claim_Lines__r[0]:' + cl.Claim_Lines__r[0]);
        system.assertEquals(cl.Claim_Lines__r[1].Customer_Invoice__c, aaCI1.Id, '>>> cl.Claim_Lines__r[1]:' + cl.Claim_Lines__r[1]);
    } 
    //KNDY-17697 - all eligible credit payment method EFT. It doesn't get affected by pre printed check stock flag on bank account.
    static testMethod void AllCI_testCreateRefundReceipt_EFTMethod(){
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        
        //fetch bank account and update preprinted stock true and no of advice lines to 1 to create overflow of remittance
        //KNDY-18900 Replace next check number (number) field with text field
        Bank_Account__c bankAcct  = [select id,GL_Account__c,account_type__c,active__c,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c,Next_Check_Number_2__c from  Bank_Account__c where Name = 'Test BOFA'];
        bankAcct.Use_Pre_Printed_Check_Stock__c = true;
        bankAcct.Number_of_Advice_Lines_Per_Page__c = 10 ;
        bankAcct.Next_Check_Number_2__c = '1';
        update bankAcct;
        
        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_PREPAYMENT, 'Open');
        cis.add(aaCI);
        Customer_Invoice__c aaCI1 = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_OVERPAYMENT, 'Open');
        cis.add(aaCI1);
        insert cis;
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        cils.add(aaCILine);
        Customer_Invoice_Line__c aaCILine1 = testData.createCILine(aaCI1);
        cils.add(aaCILine1);
        insert cils;
        aaCI.Finalized__c = true;
        aaCI1.Finalized__c = true; 
        update cis;

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        // Set Claim Id in page url
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        RefundCreditManageExt ext = new RefundCreditManageExt();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        //Get Customer Invoice Wrappers
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        System.debug(logginglevel.error,'result-->'+result);
        system.assert(result.success == true,'The Credit Invoices are not fetched');
        system.assert(result.records.size() == 2,'The Credit Invoices are not fetched');
        List<RefundCreditService.InvoiceCreditsWrapper> invoicCreditWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>) result.records;
        
        // Set amount to refund on ci wrappers
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invoicCreditWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 100.00;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        // Set up a CR to insert with Claim lookup
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;        
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_G__c = 'EFT';
        custReceipt.Reference_Number__c ='123456';
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        System.debug(logginglevel.error,invoicCreditWrappers.size());
        System.debug(logginglevel.error,'invoicCreditWrappers--->'+invoicCreditWrappers);
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        // Call extension method that creates CR
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invoicCreditWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == true,'Customer Receipt Creation Failed' );
        system.assert( Apexpages.hasMessages() == false , 'Exception on Creation of Customer Receipt' );
        Test.stopTest();
        
        // CI asserts
        List<Customer_Invoice__c > ciList = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id IN :cis];
        for (Customer_Invoice__c CI :ciList){
        	system.assertEquals(CI.Balance__c, 0, '>>> CI:'+CI);
        	system.assertEquals(CI.Status__c, 'Closed','>>> CI:'+CI);
        }
        // CR and CRL asserts
        List<Customer_Receipt__c> crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Customer__c = :testData.fuel.customerBillTo.Id and Status__c ='Closed'];
        system.assertEquals(crs.size() ,1, '>>> crs: ' + crs);
        system.assertEquals(crs[0].Customer_Receipt_Lines__r.size() ,2, '>>> Customer receipt line is not matching: ' + crs[0].Customer_Receipt_Lines__r);
        Customer_Receipt__c cr = crs[0];
        system.assertEquals(cr.Type__c, 'Refund', '>>>> cr: ' + cr);
        system.assertEquals(cr.Reference_Number__c, '123456', '>>>> wrong reference number: ' + cr);
        system.assertEquals(cr.Status__c, 'Closed', '>>>> cr: ' + cr);
        system.assertEquals(cr.Finalized__c, true, '>>>> cr: ' + cr);
        system.assertEquals(cr.Amount_Unapplied__c, 0, '>>>> cr: ' + cr);
        system.assertEquals(cr.Customer_Receipt_Lines__r.size(), 2, '>>>> cr.Customer_Receipt_Lines__r: ' + cr.Customer_Receipt_Lines__r);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Type__c, PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Customer_Invoice__c, aaCI.Id, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[1].Customer_Invoice__c, aaCI1.Id, '>>> cr.Customer_Receipt_Lines__r[1]: '+ cr.Customer_Receipt_Lines__r[1]);//KNDY-13995
        system.assertEquals(cr.Customer_Receipt_Lines__r[0].Amount__c, -100, '>>> cr.Customer_Receipt_Lines__r[0]: '+ cr.Customer_Receipt_Lines__r[0]);
        
        //check for cancelled CR - it shouldn't be creating any cancelled CR
        crs = [Select Id, Type__c, Status__c, Finalized__c, Amount_Unapplied__c, Claim__c,Reference_Number__c,Status_Reason__c,
                                     (Select Id, Type__c, Amount__c, Customer_Invoice__c from Customer_Receipt_Lines__r) //KNDY-13995
                                  from Customer_Receipt__c where Customer__c = :testData.fuel.customerBillTo.Id and Status__c ='Cancelled'];
      	system.assertEquals(crs.size() ,0, '>>> crs: ' + crs);
        
       
    } 
    //KNDY-18879 - block refund if bank account currency is diff then CI
    static testMethod void testRefundReceipt_DiffBACurrencyAndCRCurrency(){
        
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        Bank_Account__c  bankAccount = testdata.fuel.bankAccount;
        bankAccount.Currency__c = testdata.fuel.CurrencyGBP.id;
        update bankAccount;
        
        
        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_PREPAYMENT, 'Open');
        cis.add(aaCI);
        Customer_Invoice__c aaCI1 = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, CustomerInvoiceService.CM_OVERPAYMENT, 'Open');
        cis.add(aaCI1);
        insert cis;
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        cils.add(aaCILine);
        Customer_Invoice_Line__c aaCILine1 = testData.createCILine(aaCI1);
        cils.add(aaCILine1);
        insert cils;
        aaCI.Finalized__c = true;
        aaCI1.Finalized__c = true; 
        update cis;

        KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
        fd1.field = 'Customer__c';
        fd1.fieldType = 'string';
        fd1.value = testData.fuel.customerBillTo.Id;
        fd1.operator = 'eq';
        filters.add(fd1);

        KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
        fd2.field = 'Company__c';
        fd2.fieldType = 'string';
        fd2.value = testData.fuel.company.Id;
        fd2.operator = 'eq';
        filters.add(fd2);

        KendoUtils.FilterDescriptor fd3 = new KendoUtils.FilterDescriptor();
        fd3.field = 'Currency__c';
        fd3.fieldType = 'string';
        fd3.value = testData.fuel.company.Default_Transaction_Currency__c;   
        fd3.operator = 'eq';
        filters.add(fd3);
        System.debug(logginglevel.error,'filters-->'+filters);
        
        Test.startTest();
        // Set Claim Id in page url
        PageReference pageRef = Page.RefundCreditManage;
        Test.setCurrentPage(pageRef);
        RefundCreditManageExt ext = new RefundCreditManageExt();
        JsonResult result = new JsonResult();
        String creditsType = 'Invoice';
        //Get Customer Invoice Wrappers
        result = RefundCreditManageExt.getInvoiceCredits(filters,creditsType,null,false); 
        System.debug(logginglevel.error,'result-->'+result);
        system.assert(result.success == true,'The Credit Invoices are not fetched');
        system.assert(result.records.size() == 2,'The Credit Invoices are not fetched');
        List<RefundCreditService.InvoiceCreditsWrapper> invoicCreditWrappers = (List<RefundCreditService.InvoiceCreditsWrapper>) result.records;
        
        // Set amount to refund on ci wrappers
        Double totalRefundAmount = 0.00;
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrper : invoicCreditWrappers){
            invCreditWrper.cusInv.Memo__c = 'This is a Memo Text';
            invCreditWrper.refundAmount = 100.00;
            totalRefundAmount += invCreditWrper.refundAmount;
        }
        
        // Set up a CR to insert with Claim lookup
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Customer__c = testData.fuel.customerBillTo.Id;        
        custReceipt.Company__c = testData.fuel.company.Id;
        custReceipt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c; 
        custReceipt.Bank_Account_2__c = testData.fuel.bankAccount.Id;  
        custReceipt.Amount_Received__c = -1 * totalRefundAmount;
        custReceipt.Type__c = 'Refund';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Payment_Method_2__c = 'Check';
        custReceiptList.add(custReceipt);
    
        System.debug(logginglevel.error,custReceiptList.size());
        System.debug(logginglevel.error,'custReceiptList--->'+custReceiptList);
        System.debug(logginglevel.error,invoicCreditWrappers.size());
        System.debug(logginglevel.error,'invoicCreditWrappers--->'+invoicCreditWrappers);
        System.debug(logginglevel.error,'totalRefundAmount--->'+totalRefundAmount);
        
        // Call extension method that creates CR
        JsonResult result1 = new JsonResult();
        result1 = RefundCreditManageExt.createRefundReceipt(custReceiptList,new list<String> {'Date_Received__c'},invoicCreditWrappers,totalRefundAmount);
        
        System.debug(logginglevel.error,'result1-->'+result1);
        system.assert( result1.success == false,'Customer Receipt Creation Failed' );
        String expectedErrorMessage ='You can\'t create a receipt using a different currency from the bank account\'s currency.' ;
        boolean errorExists = false;
        for(Map<String, String> msg :result1.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains(expectedErrorMessage)){
                    errorExists = true;
                }
            }
        }        
		system.assertEquals(true, errorExists, result1.messages);
        Test.stopTest();

    }


    static testMethod void settleClaimFromRefundCredit() {
        RefundCreditManageExtTestData testData = new RefundCreditManageExtTestData();
        List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();

        Customer_Invoice__c aaCI = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, AllowanceRuleService.ALLOWANCE_ACCRUAL, 'Open');
        cis.add(aaCI);

        Customer_Invoice__c aaCI2 = testData.createCI(testData.fuel.company, testData.fuel.customerBillTo, AllowanceRuleService.ALLOWANCE_ACCRUAL, 'Open');
        cis.add(aaCI2);

        insert cis;
        Customer_Invoice_Line__c aaCILine = testData.createCILine(aaCI);
        cils.add(aaCILine);
        insert cils;
        aaCI.Finalized__c = true;
        update cis;

        Claim__c cl = testData.createClaim();
        cl.Source__c = 'General Deduction';
        cl.Amount__c = 200;
        cl.claim_date__c = system.today();
        insert cl;

        RefundCreditService.InvoiceCreditsWrapper wrapper = new RefundCreditService.InvoiceCreditsWrapper();
        wrapper.refundAmount = 100;
        wrapper.cusInv = aaCI;

        RefundCreditService.InvoiceCreditsWrapper wrapper2 = new RefundCreditService.InvoiceCreditsWrapper();
        wrapper2.refundAmount = 100;
        wrapper2.cusInv = aaCI2;

        JSONResult result = RefundCreditManageExt.settleClaim(cl.Id, new List<RefundCreditService.InvoiceCreditsWrapper> {wrapper, wrapper2});
        system.assertEquals(true, result.success, result);

        list<Customer_Receipt__c> lCR = [Select Id, Status__c, Finalized__c, (Select Id, Type__c, Amount__c from Customer_Receipt_Lines__r Order By Amount__c Desc) from Customer_Receipt__c where Type__c = 'Claim Settlement' and Finalized__c = true and Status__c = 'Closed'];
        system.assertEquals(1, lCR.size());
        system.assertEquals(3,lCR[0].Customer_Receipt_Lines__r.size());
        system.assertEquals(200,lCR[0].Customer_Receipt_Lines__r[0].Amount__c);
        system.assertEquals('Debit Applied - Claim',lCR[0].Customer_Receipt_Lines__r[0].Type__c);
        system.assertEquals(100,lCR[0].Customer_Receipt_Lines__r[1].Amount__c);
        system.assertEquals(100,lCR[0].Customer_Receipt_Lines__r[2].Amount__c);

    }
    @testVisible
    private static map<string, string> requestResponseBodies = new map<string, string>{
        'getCustomerProfileRequest'             =>  '<?xml version="1.0" encoding="utf-8"?> <getCustomerProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <profile> <merchantCustomerId>custId123</merchantCustomerId> <description>some description</description> <email>mark@example.com</email> <customerProfileId>10000</customerProfileId> <paymentProfiles> <billTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </billTo> <customerPaymentProfileId>20000</customerPaymentProfileId> <payment> <creditCard> <cardNumber>XXXX1111</cardNumber> <expirationDate>XXXX</expirationDate> </creditCard> </payment> </paymentProfiles> <paymentProfiles> <customerPaymentProfileId>20001</customerPaymentProfileId> <payment> <bankAccount> <accountType>checking</accountType> <routingNumber>XXXX0000</routingNumber> <accountNumber>XXXX0000</accountNumber> <nameOnAccount>John Doe</nameOnAccount> <bankName>Bank of Washington</bankName> </bankAccount> </payment> </paymentProfiles> <shipToList> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </shipToList> <shipToList> <firstName>Jane</firstName> <lastName>Doe</lastName> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> </shipToList> </profile> </getCustomerProfileResponse>',
        'createCustomerProfileRequest'          =>  '<?xml version="1.0" encoding="UTF-8"?> <createCustomerProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <customerProfileId>38545475</customerProfileId> <customerPaymentProfileIdList> <numericString>35049701</numericString> </customerPaymentProfileIdList> <customerShippingAddressIdList /> <validationDirectResponseList> <string>1,1,1,(TESTMODE) This transaction has been approved.,000000,P,0,none,Test transaction for ValidateCustomerPaymentProfile.,1.00,CC,auth_only,Cust_Id_1450292633,,,,,,,,,,,ryan.sieve@kenandy.com,,,,,,,,,0.00,0.00,0.00,FALSE,none,939D83D40EDEAB16DCEC897FE84C3C85,,,,,,,,,,,,,XXXX1111,Visa,,,,,,,,,,,,,,,,</string> </validationDirectResponseList> </createCustomerProfileResponse>',
        'createCustomerPaymentProfileRequest'   =>  '<?xml version="1.0" encoding="utf-8"?> <createCustomerPaymentProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <customerPaymentProfileId>20000</customerPaymentProfileId> <validationDirectResponse>1,1,1,This transaction has been approved.,000000,Y,2000000000,none,Test transaction for ValidateCustomerPaymentProfile.,0.01,CC,auth_only,custId123, John,Doe,,123 Main St.,Bellevue,WA,98004,USA,000-000-0000,,mark@example.com,,,,,,,,,0.00,0.00,0.00,,none, D18EB6B211FE0BBF556B271FDA6F92EE,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, </validationDirectResponse> </createCustomerPaymentProfileResponse>',
        'createTransactionRequest'              =>  '<?xml version="1.0" encoding="utf-8"?> <createTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <refId>123456</refId> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <transactionResponse> <responseCode>1</responseCode> <authCode>UGELQC</authCode> <avsResultCode>E</avsResultCode> <cavvResultCode /> <transId>2148061808</transId> <refTransID /> <transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash> <accountNumber>XXXX0015</accountNumber> <accountType>MasterCard</accountType> <message> <code>1</code> <description>This transaction has been approved.</description> </message> <userFields> <userField> <name>MerchantDefinedFieldName1</name> <value>MerchantDefinedFieldValue1</value> </userField> <userField> <name>favorite_color</name> <value>lavender</value> </userField> </userFields> </transactionResponse> </createTransactionResponse>',
        'authenticateTestRequest'               =>  '<?xml version="1.0" encoding="utf-8"?> <authenticateTestResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> </authenticateTestResponse>',
        'getTransactionDetailsRequest'          =>  '<?xml version="1.0" encoding="utf-8"?> <getTransactionDetailsResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <transaction> <transId>12345</transId> <refTransId>12345</refTransId> <splitTenderId>12345</splitTenderId> <submitTimeUTC>2010-08-30T17:49:20.757Z</submitTimeUTC> <submitTimeLocal>2010-08-30T13:49:20.757</submitTimeLocal> <transactionType>authCaptureTransaction</transactionType> <transactionStatus>capturedPendingSettlement</transactionStatus> <responseCode>1</responseCode> <responseReasonCode>1</responseReasonCode> <responseReasonDescription> Approval</responseReasonDescription> <authCode>000000</authCode> <AVSResponse>X</AVSResponse> <cardCodeResponse>M</cardCodeResponse> <CAVVResponse>2</CAVVResponse> <FDSFilterAction>authAndHold</FDSFilterAction> <FDSFilters> <FDSFilter> <name>Hourly Velocity Filter</name> <action>authAndHold</action> </FDSFilter> <FDSFilter> <name>Amount Filter</name> <action>report</action> </FDSFilter> </FDSFilters> <batch> <batchId>12345</batchId> <settlementTimeUTC>2010-08-30T17:49:20.757Z</settlementTimeUTC> <settlementTimeLocal>2010-08-30T13:49:20.757</settlementTimeLocal> <settlementState>settledSuccessfully</settlementState> </batch> <order> <invoiceNumber>INV00001</invoiceNumber> <description>some description</description> <purchaseOrderNumber>PO000001</purchaseOrderNumber> </order> <requestedAmount>5.00</requestedAmount> <authAmount>2.00</authAmount> <settleAmount>2.00</settleAmount> <tax> <amount>1.00</amount> <name>WA state sales tax</name> <description>Washington state sales tax</description> </tax> <shipping> <amount>2.00</amount> <name>ground based shipping</name> <description>Ground based 5 to 10 day shipping</description> </shipping> <duty> <amount>1.00</amount> </duty> <lineItems> <lineItem> <itemId>ITEM00001</itemId> <name>name of item sold</name> <description>Description of item sold</description> <quantity>1</quantity> <unitPrice>6.95</unitPrice> <taxable>true</taxable> </lineItem> <lineItem> <itemId>ITEM00001</itemId> <name>name of item sold</name> <description>Description of item sold</description> <quantity>1</quantity> <unitPrice>6.95</unitPrice> <taxable>true</taxable> </lineItem> </lineItems> <prepaidBalanceRemaining>30.00</prepaidBalanceRemaining> <taxExempt>false</taxExempt> <payment> <!-- either creditCard or bankAccount will be here --> <creditCard> <cardNumber>XXXX1111</cardNumber> <expirationDate>XXXX</expirationDate> <accountType>Visa</accountType> </creditCard> <!--<bankAccount> <routingNumber>XXXX0000</routingNumber> <accountNumber>XXXX0000</accountNumber> <nameOnAccount>John Doe</nameOnAccount> <echeckType>WEB</echeckType> </bankAccount>--> </payment> <customer> <type>individual</type> <id>ABC00001</id> <email>mark@example.com</email> </customer> <billTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </billTo> <shipTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> </shipTo> <recurringBilling>false</recurringBilling> <customerIP>0.0.0.0</customerIP> <subscription> <id>145521</id> <paynum>1</paynum> <marketType>eCommerce</marketType> <product>Card Not Present</product> <returnedItems> <returnedItem> <id>2148878904</id> <dateUTC>2014-05-12T21:22:44Z</dateUTC> <dateLocal>2014-05-12T14:22:44</dateLocal> <code>R02</code> <description>Account Closed</description> </returnedItem> </returnedItems> <solution> <id>A1000004</id> <name>Shopping Cart</name> </solution> <mobileDeviceId>2354578983274523978</mobileDeviceId> </subscription> </transaction> </getTransactionDetailsResponse>'                                 
    };
   
}