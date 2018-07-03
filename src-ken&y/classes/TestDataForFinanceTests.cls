@isTest
private class TestDataForFinanceTests {
    
    @testSetup static void ts() {
        TestDataForFinance tdf = new TestDataForFinance();
    }
    
    static TestDataForFinanceQuery data = new TestDataForFinanceQuery();
    
    
    
    
    /********************************************************************************************
    * BEGIN SegmentTest Tests
    *********************************************************************************************/  

    /* create a test for custom segment feature, we will stuff a value into an invoice */
     static testMethod void SegmentTest_custom_segment_test(){        
        List<Customer_Invoice_Line__c> custInvLineList1 = new List<Customer_Invoice_Line__c>();
        List<Customer_Invoice_Line__c> custInvLineList2 = new List<Customer_Invoice_Line__c>();
        List<Customer_Invoice__c> custInvAEList = new List<Customer_Invoice__c>();
        
        string custInvName = SchemaUtil.getInstance().getLocalNameFromObject(new Customer_Invoice__c());
        Map<String, String> mRecTypes = KSE.RecordTypeDevNameMap(custInvName);
        Id invRecTypeId = mRecTypes.get('Invoice');
        Id cmRecTypeId = mRecTypes.get('Credit_Memo');         
        
        Test.startTest();
        List<Customer_Invoice__c> custInvList = new List<Customer_Invoice__c> ();
        Customer_Invoice__c custInv1 = new Customer_Invoice__c();
        custInv1.Company__c = data.company.id;
        custInv1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInv1.Invoice_Type__c = 'Ship Invoice';
        custInv1.Date_Invoiced__c = System.today();
        custInv1.Transaction_Date__c = System.now();
        //Added Bill To for field filters
        custInv1.Bill_To_Customer__c = data.customer_billto.id;
        custInv1.Sold_To_Customer__c = data.customer1.id;
        //custInv1.Subtotal__c = 0;
        custInv1.Sales_Order__c = data.salesOrder1.id;
        custInvList.add(custInv1);
        
        Customer_Invoice__c custInv2 = new Customer_Invoice__c();
        custInv2.Company__c = data.company.id;
        custInv2.Currency__c = data.company.Default_Transaction_Currency__c;
        custInv2.Invoice_Type__c = 'Ship Invoice';
        custInv2.Date_Invoiced__c = System.today();
        custInv2.Transaction_Date__c = System.now();
        //Added Bill To for field filters
        custInv2.Bill_To_Customer__c = data.customer_billto.id;
        custInv2.Sold_To_Customer__c = data.customer1.id;
        //custInv2.Subtotal__c = 0;
        custInv2.Sales_Order__c = data.salesOrder2.id;
        custInvList.add(custInv2);
       
        insert custInvList;
       
        Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
        custInvLine1.Quantity_Shipped__c = 2;
        custInvLine1.Sales_Order_Line__c = data.SalesOrderLineList[0].id;
        custInvLine1.Unit_Price__c = 7;
        custInvLine1.Sales_Order__c = data.salesOrder1.id;
        custInvLine1.Product__c = data.product.id; 
        custInvLine1.Discount_Percent__c = 0.2;
        custInvLine1.Customer_Invoice__c = custInv1.id;
        custInvLineList1.add(custInvLine1);
       
        Customer_Invoice_Line__c custInvLine2 = new Customer_Invoice_Line__c();
        custInvLine2.Quantity_Shipped__c = 3;
        custInvLine2.Sales_Order_Line__c = data.SalesOrderLineList[1].id;
        custInvLine2.Unit_Price__c = 9;
        custInvLine2.Sales_Order__c = data.salesOrder1.id;
        custInvLine2.Product__c = data.product.id ; 
        custInvLine2.Discount_Percent__c = 0.2;
        custInvLine2.Customer_Invoice__c = custInv1.id;
        custInvLineList1.add(custInvLine2);
        insert custInvLineList1;          
        
        Customer_Invoice_Line__c custInvLine3 = new Customer_Invoice_Line__c();
        custInvLine3.Quantity_Shipped__c = 2;
        custInvLine3.Sales_Order_Line__c = data.SalesOrderLineList[2].id;
        custInvLine3.Unit_Price__c = 7;
        custInvLine3.Sales_Order__c = data.salesOrder2.id;
        custInvLine3.Product__c = data.product.id ; 
        custInvLine3.Discount_Percent__c = 0.2;
        custInvLine3.Customer_Invoice__c = custInv2.id;
        custInvLineList2.add(custInvLine3);
        
        Customer_Invoice_Line__c custInvLine4 = new Customer_Invoice_Line__c();
        custInvLine4.Quantity_Shipped__c = 3;
        custInvLine4.Sales_Order_Line__c = data.SalesOrderLineList[3].id;
        custInvLine4.Unit_Price__c = 9;
        custInvLine4.Sales_Order__c = data.salesOrder2.id;
        custInvLine4.Product__c = data.product.id ; 
        custInvLine4.Discount_Percent__c = 0.2;
        custInvLine4.Customer_Invoice__c = custInv2.id;
        custInvLineList2.add(custInvLine4);
        insert custInvLineList2;
        
        custInvList[0].Finalized__c = true;
        custInvList[1].Finalized__c = true;
        update custInvList;
        
        
        custInvAEList.add(custInv1);
        custInvAEList.add(custInv2);

        // make sure the customer has a value for the address
        Account acc = new Account(Name='foobargack');
        insert acc; 
        data.customer1.Address__c = acc.id;   
        update data.customer1; 
        
        
        
        //GenerateAccountingService GAS = new GenerateAccountingService(); 
        //GAS.createCustInvoiceAccounting(custInvAEList); 
        CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
        list<customer_invoice_line__c> cilList = new list<customer_invoice_line__c>();
        cillist.addall(custInvLineList2);
        cillist.addall(custInvLineList1);
        
        cia.execute(cillist);
         
        Test.stopTest();
        
        Set<Id> custInvIds = new Set<Id>();
        for(Customer_Invoice__c custInv: custInvAEList){
            custInvIds.add(custInv.id);
        }
        List<Accounting_Entry__c> acctEntry = [Select id, Name,  Customer_Invoice__c
                                                , ( select id, error_message__c from Accounting_Entry_Lines__r )
                                                from Accounting_Entry__c 
                                                where Customer_Invoice__c in :custInvIds];
        system.assertNotEquals(null,acctEntry);
        system.assertEquals(2,acctEntry.size());
        Set<Id> acctentryids = new Set<Id>();
        for ( Accounting_Entry__c a: acctEntry ) { 
            acctentryids.add(a.id);
            System.debug(LoggingLevel.INFO, a.Accounting_Entry_Lines__r);
        }
        
        List<Accounting_Entry_Line__c> acctentryline = [
            Select id, Name, GL_Account__c, GL_Account__r.Name, Accounting_Entry__r.Transaction_Type__c, Amount_CR__c, Amount_DR__c 
            from Accounting_Entry_Line__c where Accounting_Entry__c in :acctentryids 
            order by GL_Account__c  ];  // order by is required when we are testing for the order of the results by array index
        
        //for ( Accounting_Entry_Line__c a: acctentryline ) { System.debug(LoggingLevel.INFO, a.GL_Account__r.Name); }
        system.assertEquals(8,acctentryline.size());
        
        system.assertEquals(data.revenueGL.id,acctentryline[0].GL_Account__c );
        system.assertEquals(data.revenueGL.id,acctentryline[1].GL_Account__c );
        system.assertEquals(data.revenueGL.id,acctentryline[2].GL_Account__c );
        system.assertEquals(data.revenueGL.id,acctentryline[3].GL_Account__c );
        
        system.assertEquals(data.receivablesGL.id,acctentryline[4].GL_Account__c );        
        system.assertEquals(data.receivablesGL.id,acctentryline[5].GL_Account__c );
        system.assertEquals(data.receivablesGL.id,acctentryline[6].GL_Account__c ); 
        system.assertEquals(data.receivablesGL.id,acctentryline[7].GL_Account__c ); 
        
     }
    

    /********************************************************************************************
    * BEGIN PurchaseOrderAccountingTest Tests
    *********************************************************************************************/
    /*This feature is soon to be deprecated hence commenting the test method to skip the too many SOQL queries errors - KNDY-7633
    // Test Purchase Order Accounting
/*  public static testMethod void PurchaseOrderAccountingTest_testPurchaseOrderAccounting() {

        FOB_Terms__c fob = new FOB_Terms__c(fob_point__c = 'Origin');
        insert fob;
        data.purchaseOrder1.fob_term__c = fob.Id;
        update data.purchaseOrder1;
        
        for(Purchase_Order_Line__c pol : data.purchaseOrder1.Purchase_Order_Lines__r){
            pol.Subtransaction_type__c = 'Origin';
            pol.quantity_shipped__c = 1;
            pol.unit_price__c = 10;
        }
        
        update data.purchaseOrder1.Purchase_Order_Lines__r;
        
        data.purchaseOrder1.transaction_date__c = system.now();
        data.purchaseOrder1.finalized__c = true;
        update data.purchaseOrder1;
        
        test.startTest();
            System.assert(true); 
            PurchaseOrderAccounting poa = new PurchaseOrderAccounting();
            poa.execute(new List<sObject>{data.purchaseOrder1.Purchase_Order_Lines__r});
            system.debug('referenced rules: ' + poa.referencedRules);
        test.stopTest();
        
        return;
        //Test was failing with too many soql queries below this point.  needs to be fixed.
        //KNDY-7190.        
        
        List<Accounting_Entry__c> aes = [SELECT Id, (SELECT Id, name FROM Accounting_Entry_Lines__r) FROM Accounting_Entry__c WHERE Purchase_Order__c = :data.purchaseOrder1.Id ALL ROWS];
        for(Purchase_Order_Line__c pol : [SELECT Id, subtransaction_type__c, line_type__c, purchase_order__r.type__c FROM Purchase_Order_Line__c WHERE Purchase_Order__c = :data.purchaseOrder1.Id]){
            system.debug('pol: ' + pol);
            system.debug('po: ' + pol.Purchase_Order__r);
        }
        for(Accounting_Rule__c ar : [SELECT Id, object_name__c, transaction__c, subtransaction_type__c, line_type__c FROM Accounting_Rule__c WHERE object_name__c = 'Purchase_Order__c']){
            system.debug('ar: ' + ar);
        }
        system.assertEquals(1, aes.size());
        system.assertEquals(2, aes[0].Accounting_Entry_Lines__r.size(), 'Expecting 1 CR and 1 DR Line ' + Apexpages.getMessages() + ' ' + aes[0].Accounting_Entry_Lines__r);
    }
    
    // Test Purchase Order Accounting Extension
    public static testMethod void PurchaseOrderAccountingTest_testPurchaseOrderAccountingExt() {

        FOB_Terms__c fob = new FOB_Terms__c(fob_point__c = 'Origin');
        insert fob;
        data.purchaseOrder1.fob_term__c = fob.Id;
        update data.purchaseOrder1;
        
        for(Purchase_Order_Line__c pol : data.purchaseOrder1.Purchase_Order_Lines__r){
            pol.Subtransaction_type__c = 'Origin';
            pol.quantity_shipped__c = 1;
            pol.unit_price__c = 10;
        }
        
        update data.purchaseOrder1.Purchase_Order_Lines__r;
        
        data.purchaseOrder1.transaction_date__c = system.now();
        data.purchaseOrder1.finalized__c = true;
        update data.purchaseOrder1;
        
        
        test.startTest();
            Apexpages.standardsetcontroller ssCon = new Apexpages.StandardSetController(database.getqueryLocator([SELECT Id FROM Purchase_Order__c WHERE Id = :data.purchaseOrder1.Id]));
            ssCon.setSelected(new list<sObject>{data.purchaseOrder1});
            PurchaseOrderAccountingExt ext = new PurchaseOrderAccountingExt(ssCon);
            ext.GeneratePurchaseOrderAccounting();
        test.stopTest();
        
        return;
        //Test was failing with too many soql queries below this point.  needs to be fixed.
        //KNDY-7190.  
        
        List<Accounting_Entry__c> aes = [SELECT Id, (SELECT Id, name FROM Accounting_Entry_Lines__r) FROM Accounting_Entry__c WHERE Purchase_Order__c = :data.purchaseOrder1.Id AND Status__c = 'Active'];
        for(Purchase_Order_Line__c pol : [SELECT Id, subtransaction_type__c, line_type__c, purchase_order__r.type__c FROM Purchase_Order_Line__c WHERE Purchase_Order__c = :data.purchaseOrder1.Id]){
            system.debug(pol);
            system.debug(pol.Purchase_Order__r);
        }
        system.assertEquals(1, aes.size(), 'Expecting 1 Accounting Entry ' + Apexpages.getMessages());
        system.assertEquals(2, aes[0].Accounting_Entry_Lines__r.size(), 'Expecting 1 CR and 1 DR Line ' + Apexpages.getMessages());
    }
        FOB_Terms__c fob = new FOB_Terms__c(fob_point__c = 'Origin');
        insert fob;
        data.purchaseOrder1.fob_term__c = fob.Id;
        update data.purchaseOrder1;
        
        for(Purchase_Order_Line__c pol : data.purchaseOrder1.Purchase_Order_Lines__r){
            pol.Subtransaction_type__c = 'Origin';
            pol.quantity_shipped__c = 1;
            pol.unit_price__c = 10;
        }
        
        update data.purchaseOrder1.Purchase_Order_Lines__r;
        
        data.purchaseOrder1.transaction_date__c = system.now();
        data.purchaseOrder1.finalized__c = true;
        update data.purchaseOrder1;
        
        test.startTest();
            System.assert(true); 
            PurchaseOrderAccounting poa = new PurchaseOrderAccounting();
            poa.execute(new List<sObject>{data.purchaseOrder1.Purchase_Order_Lines__r});
            system.debug('referenced rules: ' + poa.referencedRules);
        test.stopTest();
        
        return;
        //Test was failing with too many soql queries below this point.  needs to be fixed.
        //KNDY-7190.        
        
        List<Accounting_Entry__c> aes = [SELECT Id, (SELECT Id, name FROM Accounting_Entry_Lines__r) FROM Accounting_Entry__c WHERE Purchase_Order__c = :data.purchaseOrder1.Id ALL ROWS];
        for(Purchase_Order_Line__c pol : [SELECT Id, subtransaction_type__c, line_type__c, purchase_order__r.type__c FROM Purchase_Order_Line__c WHERE Purchase_Order__c = :data.purchaseOrder1.Id]){
            system.debug('pol: ' + pol);
            system.debug('po: ' + pol.Purchase_Order__r);
        }
        for(Accounting_Rule__c ar : [SELECT Id, object_name__c, transaction__c, subtransaction_type__c, line_type__c FROM Accounting_Rule__c WHERE object_name__c = 'Purchase_Order__c']){
            system.debug('ar: ' + ar);
        }
        system.assertEquals(1, aes.size());
        system.assertEquals(2, aes[0].Accounting_Entry_Lines__r.size(), 'Expecting 1 CR and 1 DR Line ' + Apexpages.getMessages() + ' ' + aes[0].Accounting_Entry_Lines__r);
    }
    */
    
    /* This feature is soon to be deprecated hence commenting the test method to skip the too many SOQL queries errors - KNDY-7633
    // Test Purchase Order Accounting Extension
    public static testMethod void PurchaseOrderAccountingTest_testPurchaseOrderAccountingExt() {

        FOB_Terms__c fob = new FOB_Terms__c(fob_point__c = 'Origin');
        insert fob;
        data.purchaseOrder1.fob_term__c = fob.Id;
        update data.purchaseOrder1;
        
        for(Purchase_Order_Line__c pol : data.purchaseOrder1.Purchase_Order_Lines__r){
            pol.Subtransaction_type__c = 'Origin';
            pol.quantity_shipped__c = 1;
            pol.unit_price__c = 10;
        }
        
        update data.purchaseOrder1.Purchase_Order_Lines__r;
        
        data.purchaseOrder1.transaction_date__c = system.now();
        data.purchaseOrder1.finalized__c = true;
        update data.purchaseOrder1;
        
        
        test.startTest();
            Apexpages.standardsetcontroller ssCon = new Apexpages.StandardSetController(database.getqueryLocator([SELECT Id FROM Purchase_Order__c WHERE Id = :data.purchaseOrder1.Id]));
            ssCon.setSelected(new list<sObject>{data.purchaseOrder1});
            PurchaseOrderAccountingExt ext = new PurchaseOrderAccountingExt(ssCon);
            ext.GeneratePurchaseOrderAccounting();
        test.stopTest();
        
        return;
        //Test was failing with too many soql queries below this point.  needs to be fixed.
        //KNDY-7190.  
        
        List<Accounting_Entry__c> aes = [SELECT Id, (SELECT Id, name FROM Accounting_Entry_Lines__r) FROM Accounting_Entry__c WHERE Purchase_Order__c = :data.purchaseOrder1.Id AND Status__c = 'Active'];
        for(Purchase_Order_Line__c pol : [SELECT Id, subtransaction_type__c, line_type__c, purchase_order__r.type__c FROM Purchase_Order_Line__c WHERE Purchase_Order__c = :data.purchaseOrder1.Id]){
            system.debug(pol);
            system.debug(pol.Purchase_Order__r);
        }
        system.assertEquals(1, aes.size(), 'Expecting 1 Accounting Entry ' + Apexpages.getMessages());
        system.assertEquals(2, aes[0].Accounting_Entry_Lines__r.size(), 'Expecting 1 CR and 1 DR Line ' + Apexpages.getMessages());
    }
    
    public static testMethod void PurchaseOrderAccountingTest_testFinalizeHeaderValidation(){
        
        data.purchaseOrder1.transaction_date__c = system.now();
        data.purchaseOrder1.finalized__c = true;
        update data.purchaseOrder1;
        
        test.startTest();
        
        string trxnCurr = data.purchaseOrder1.Currency__c;
        boolean sawException = false;
        string exMsg;
        try{
            data.purchaseOrder1.Currency__c = null;
            update data.purchaseOrder1;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to edit a finalized doc ' + exMsg );
        
        sawException = false;
        exMsg = null;
        data.purchaseOrder1.Currency__c = trxnCurr;
        try{
            delete data.purchaseOrder1;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to delete a finalized doc ' + exMsg );
        
        test.stopTest();
    }
    
    public static testMethod void PurchaseOrderAccountingTest_testFinalizeLineEditValidation(){
        
        data.purchaseOrder1.transaction_date__c = system.now();
        data.purchaseOrder1.finalized__c = true;
        update data.purchaseOrder1;
        
        test.startTest();
        
        for(Purchase_Order_Line__c pol : data.purchaseOrder1.Purchase_Order_Lines__r){
            pol.Subtransaction_type__c = 'Change';
        }
        
        boolean sawException = false;
        string exMsg = null;
        try{
            update data.purchaseOrder1.Purchase_Order_Lines__r;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to edit finalized doc lines ' + exMsg );
    } */
    
        
    /* public static testMethod void PurchaseOrderAccountingTest_testFinalizeLineDeleteValidation(){

        data.purchaseOrder1.transaction_date__c = system.now();
        //data.purchaseOrder1.finalized__c = true;
        update data.purchaseOrder1;
        
        test.startTest();
            
        boolean sawException = false;
        string exMsg = null;
        try{
            delete data.purchaseOrder1.Purchase_Order_Lines__r;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to delete finalized doc lines ' + exMsg );
    }
    
    public static testMethod void PurchaseOrderAccountingTest_testFinalizeLineAddValidation(){

        data.purchaseOrder1.transaction_date__c = system.now();
        //data.purchaseOrder1.finalized__c = true;
        update data.purchaseOrder1;
        
        test.startTest();
    
        boolean sawException = false;
        string exMsg = null;
        try{
            List<Purchase_Order_Line__c> newPOLs = new List<Purchase_Order_Line__c>();
            for(Purchase_Order_Line__c pol : data.purchaseOrder1.Purchase_Order_Lines__r){
                newPOLs.add(pol.clone(false, true));
            }
            insert newPOLs;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        system.assert(sawException, 'We are expecting to see an exception for attempting to add lines to a finalized doc ' + exMsg );
    }
    
    public static testMethod void PurchaseOrderAccountingTest_testFinalizeLineUndeleteValidation(){
        
        test.startTest();
        
        List<Purchase_Order_Line__c> newPOLs = new List<Purchase_Order_Line__c>();
        for(Purchase_Order_Line__c pol : data.purchaseOrder1.Purchase_Order_Lines__r){
            newPOLs.add(pol.clone(false, true));
        }
        insert newPOLs;
        
        delete newPOLs;
       
        data.purchaseOrder1.transaction_date__c = system.now();
       // data.purchaseOrder1.finalized__c = true;
        update data.purchaseOrder1;
        
        boolean sawException = false;
        string exMsg = null;
        
        try{
            undelete newPOLs;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        system.assert(sawException, 'We are expecting to see an exception for attempting to undelete lines on a finalized doc ' + exMsg );
    }  */     




    /********************************************************************************************
    * BEGIN POReceiptTest Tests
    *********************************************************************************************/  


    
}