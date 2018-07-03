@isTest
public class CustomerReceiptAccountingTest {
    //static TestDataForFinance data = new TestDataForFinance();
    
         
    static testmethod void testCRAccounting(){
        Testfuel data = new Testfuel(); 
        List<Period__c> periodList = data.periodList;
                
        Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
        //Added Bill To for field filters
        custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        //custInvoice1.Subtotal__c = 0;
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Adjustment';
        insert custInvoice1;
        
        Customer_Invoice_Line__c shipmentObj1 = new Customer_Invoice_Line__c();
        shipmentObj1.Quantity_Shipped__c = 10;
        shipmentObj1.Company__c = data.company.id;
        shipmentObj1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        shipmentObj1.Unit_Price__c = 10;
        shipmentObj1.Sales_Order__c = data.salesOrder.id;
        shipmentObj1.Product__c = data.product.id ; 
        shipmentObj1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        shipmentObj1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert shipmentObj1;        
     
        custInvoice1.Finalized__c = true;
        update  custInvoice1;
        
        Test.startTest();
        
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        
        Customer_Receipt__c custReceipt1 = new Customer_Receipt__c();
        //custReceipt1.Amount_Received__c = 300;
        custReceipt1.Company__c = data.company.Id;
        //custReceipt1.Bank_Account__c = data.bankAccount.id;
        custReceipt1.Customer__c = data.customerbillto.id ;
        custReceipt1.Date_Received__c = system.now();
        custReceipt1.transaction_date__c = system.now();
        custReceipt1.Currency__c = TestFuel.currencyUSD.id;
        //custReceipt1.Finalized__c = true; 
//        custReceipt1.exception__c = false;
            
        insert custReceipt1;           
        
        Reason_Code__c deductionCode = new Reason_Code__c();{
         deductionCode.Type__c = 'Deductions';  
         deductionCode.Code__c = 'D001';
         insert deductionCode;
       }
        
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
        Customer_Receipt_Line__c payment1 = new Customer_Receipt_Line__c();
        payment1.Amount__c = 91;
        payment1.Type__c = 'Payment';
        payment1.Customer_Receipt__c = custReceipt1.id;
        payment1.Customer_Invoice__c = custInvoice1.id;
        payment1.Currency__c = TestFuel.currencyUSD.id;
        payment1.line_Number__c ='1';
        crLineList.add(payment1);           
        
        Customer_Receipt_Line__c payment2 = new Customer_Receipt_Line__c();
        payment2.Amount__c = 5;
        payment2.Type__c = 'Earned Terms Discount';
        payment2.Customer_Receipt__c = custReceipt1.id;
        payment2.Customer_Invoice__c = custInvoice1.id;
        payment2.Currency__c = TestFuel.currencyUSD.id;
        payment2.line_Number__c ='1';
        crLineList.add(payment2);       
        
        Customer_Receipt_Line__c payment3 = new Customer_Receipt_Line__c();
        payment3.Amount__c = 2;
        payment3.Type__c = 'Unearned Terms Discount';
        payment3.Customer_Receipt__c = custReceipt1.id;
        payment3.Customer_Invoice__c = custInvoice1.id;
        payment3.Currency__c = TestFuel.currencyUSD.id;
        payment3.line_Number__c ='1';
        crLineList.add(payment3);       
        
        Customer_Receipt_Line__c payment4 = new Customer_Receipt_Line__c();
        payment4.Amount__c = 2;
        payment4.Type__c = 'Write Off';
        payment4.Customer_Receipt__c = custReceipt1.id;
        payment4.Customer_Invoice__c = custInvoice1.id;
        payment4.Currency__c = TestFuel.currencyUSD.id;
        payment4.line_Number__c ='1';
        crLineList.add(payment4);       
        
       /* Customer_Receipt_Line__c payment5 = new Customer_Receipt_Line__c();
        payment5.Amount__c = 10;
        payment5.Type__c = 'Credit Memo';
        payment5.Customer_Receipt__c = custReceipt1.id;
        //payment4.Customer_Invoice__c = custInvoice1.id;
        payment5.Currency__c = TestFuel.currencyUSD.id;
        payment5.line_Number__c ='1';
        crLineList.add(payment5);  */
        
        Customer_Receipt_Line__c genDeduction = new Customer_Receipt_Line__c();
        genDeduction.Amount__c = 91;
        genDeduction.Type__c = PaymentService.TYPE_GEN_DED;
        genDeduction.Customer_Receipt__c = custReceipt1.Id;
        genDeduction.Reason_Code__c = deductionCode.Id;
        crLineList.add(genDeduction);
        insert crLineList;      
        
        custReceipt1.Finalized__c = true;
        update custReceipt1;
      
        custReceiptList.add(custReceipt1);
        
        List<Customer_Receipt__c> custQuery = [select ID, Name, Amount_Received__c, Amount_Unapplied__c, Customer__c, Finalized__c, Finalized_hidden__c, Company__c, 
                                                Currency__c, Date_Received__c, (Select id, Name, Amount_To_Apply__c, Customer_Invoice__c, Customer_Receipt__c, 
                                                Customer_Receipt__r.Amount_Received__c, Customer_Receipt__r.Amount_Unapplied__c
                                                from Customer_Receipt_Lines__r) 
                                                from Customer_Receipt__c 
                                                where Finalized__c = true 
                                                and id = :custReceipt1.id];
        
        system.assertEquals(true, custQuery[0].Finalized__c);
        system.assertEquals(true, custQuery[0].Finalized_hidden__c);
        
        boolean sawException = false;
        try{
            custQuery[0].Finalized__c = false;
            update custQuery[0];
        }catch(Exception e){
            sawException = true;
        }
        
        system.assertEquals(true, sawException);
        
        CustomerReceiptAccounting cra = new CustomerReceiptAccounting();
        cra.execute([SELECT Id, customer_receipt__c from Customer_Receipt_Line__c WHERE Customer_Receipt__c IN :custReceiptList]);  
        
        
        List<Accounting_Entry__c> accountingEntryListReceipt = [Select id, Name, Customer_Receipt__c, Customer__c, Has_Exceptions__c,
                                                                (SELECT Id, name, Has_Exceptions__c, subtransaction_type__c, line_type__c, mandatory_segment_exception__c, error_message__c FROM Accounting_Entry_Lines__r)
                                                        From Accounting_Entry__c a
                                                        where Customer_Receipt__c = :custReceipt1.Id];
                                                        
        
        system.assertNotEquals(null,accountingEntryListReceipt);
        for(Accounting_Entry__c ae : accountingEntryListReceipt){
            system.assertEquals(ae.Has_Exceptions__c, true, 'This accounting entry should not have an exception ' +  ae + ' - ' + ae.Accounting_Entry_Lines__r);
        }
        
        system.assertEquals(1,accountingEntryListReceipt.size());
        Integer listsize = accountingEntryListReceipt.size();
        for(Integer i=0; i< listsize; i++){
            system.assertEquals( data.customerbillto.id ,accountingEntryListReceipt[i].Customer__c);
        }
        
    }
    
    //1. Create header missing company, transaction currency , transaction date 
    //2. Create header without line and finalize it 
    //3. create header and one line finalize
    //4. update line created in step3
    //5. add new line to the header created in step3
    //6. delete new line created in step 5
    //7. undelete line deleted in step 6 
        
    static testmethod void testCRHeaderFinalize(){
        
        TestFuel data = new TestFuel();
        //Company__c company = fuel.company;
        List<Period__c> periods = data.periodList;
        
        
        List<Customer_Receipt__c> crList = new List<Customer_Receipt__c>();
        
        Customer_Receipt__c custReceipt1 = new Customer_Receipt__c();
        custReceipt1.Amount_Received__c = 300;
        custReceipt1.Amount_Unapplied__c = 0;
        custReceipt1.Customer__c = data.customerbillto.id ;
        custReceipt1.Date_Received__c = system.now();
        custReceipt1.transaction_date__c = system.now();
        custReceipt1.Currency__c = TestFuel.currencyUSD.id;
//        custReceipt1.exception__c = false;
        
        Test.startTest();
        boolean sawException = false;
        string exMsg = null;
        
        try{
            custReceipt1.finalized__c = true;
            custReceipt1.company__c = null;
            insert custReceipt1;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        system.assertEquals(true, sawException); // company can not be null
        
        exMsg = null;
        sawException = false;
        custReceipt1.Company__c = data.company.id;
        custReceipt1.Transaction_date__c = null;
        custReceipt1.finalized__c = true;
        try{
            update custReceipt1;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        system.assertEquals(true, sawException);// transaction date can not be null
        
        exMsg = null;
        sawException = false;
        custReceipt1.Currency__c = null;
        custReceipt1.Transaction_date__c = system.now();
        custReceipt1.finalized__c = true;
        try{
            update custReceipt1;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        system.assertEquals(true, sawException); // transaction currency can not be null
        
        exMsg = null;
        sawException = false;
        custReceipt1.Currency__c = TestFuel.currencyUSD.id;
        custReceipt1.finalized__c = true;
        try{
            update custReceipt1;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        // shipment without lines can not be finalized
        system.assert(sawException, 'We are expecting to see an exception for attempting to finalized a doc without lines' + exMsg );
        Test.stopTest();
    }
    
    static testmethod void testCRLineUpdate(){
        TestFuel data = new TestFuel();
        //Company__c company = fuel.company;
        List<Period__c> periods = data.periodList;
        
        Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
        custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Adjustment';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 30;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     
        custInvoice1.Finalized__c = true;
        update  custInvoice1;
        
        Customer_Receipt__c custReceipt1 = new Customer_Receipt__c();
        //custReceipt1.Amount_Received__c = 300;
        custReceipt1.Amount_Unapplied__c = 0;
        custReceipt1.Company__c = data.company.Id;
        custReceipt1.Customer__c = data.customerbillto.id ;
        custReceipt1.Date_Received__c = system.now();
        custReceipt1.transaction_date__c = system.now();
        custReceipt1.Currency__c = TestFuel.currencyUSD.id;
//        custReceipt1.exception__c = false;
        
        insert custReceipt1;
        
        Reason_Code__c deductionCode = new Reason_Code__c();{
         deductionCode.Type__c = 'Deductions';  
         deductionCode.Code__c = 'D001';
         insert deductionCode;
        }
        
        Customer_Receipt_Line__c crLine1 = new Customer_Receipt_Line__c();
        crLine1.Amount__c = 90;
        crLine1.Type__c = 'Payment';
        crLine1.Customer_Receipt__c = custReceipt1.id;
        crLine1.Customer_Invoice__c = custInvoice1.id;
        crLine1.Currency__c = TestFuel.currencyUSD.id;
        crLine1.line_Number__c ='1';
        
        Customer_Receipt_Line__c genDeduction = new Customer_Receipt_Line__c();
        genDeduction.Amount__c = 90;
        genDeduction.Type__c = PaymentService.TYPE_GEN_DED;
        genDeduction.Reason_Code__c = deductionCode.Id;
        genDeduction.Customer_Receipt__c = custReceipt1.Id;
        genDeduction.Currency__c = TestFuel.currencyUSD.id;     
        insert new list<Customer_Receipt_Line__c>{crLine1, genDeduction};
        

        
        
        custReceipt1.finalized__c = true;
        update custReceipt1;
        
        Test.startTest();
        String exMsg = null;
        boolean sawException = false;
        try{
            crLine1.Currency__c = TestFuel.currencyGBP.id; // amount field exists in finalize field set which is not meant to be modified after doc is finalized
            update crLine1; 
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        Test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to edit a line of a finalized doc ' + exMsg);
    }
    
    static testmethod void testCRLineInsert(){
        TestFuel data = new TestFuel();
        List<Period__c> periods = data.periodList;

        Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
        custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Adjustment';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 50;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     
        custInvoice1.Finalized__c = true;
        update  custInvoice1;
        
        Customer_Receipt__c custReceipt1 = new Customer_Receipt__c();
        //custReceipt1.Amount_Received__c = 300;
        custReceipt1.Amount_Unapplied__c = 0;
        custReceipt1.Company__c = data.company.Id;
        custReceipt1.Customer__c = data.customerbillto.id ;
        custReceipt1.Date_Received__c = system.now();
        custReceipt1.transaction_date__c = system.now();
        custReceipt1.Currency__c = TestFuel.currencyUSD.id;
//        custReceipt1.exception__c = false;
        
        insert custReceipt1;
        
        Reason_Code__c deductionCode = new Reason_Code__c();{
         deductionCode.Type__c = 'Deductions';  
         deductionCode.Code__c = 'D001';
         insert deductionCode;
        }
        
        Customer_Receipt_Line__c crLine1 = new Customer_Receipt_Line__c();
        crLine1.Amount__c = 90;
        crLine1.Type__c = 'Payment';
        crLine1.Customer_Receipt__c = custReceipt1.id;
        crLine1.Customer_Invoice__c = custInvoice1.id;
        crLine1.Currency__c = TestFuel.currencyUSD.id;
        crLine1.line_Number__c ='1';
        
        Customer_Receipt_Line__c genDeduction = new Customer_Receipt_Line__c();
        genDeduction.Amount__c = 90;
        genDeduction.Type__c = PaymentService.TYPE_GEN_DED;
        genDeduction.Reason_Code__c = deductionCode.Id;
        genDeduction.Customer_Receipt__c = custReceipt1.Id;
        insert new list<Customer_Receipt_Line__c>{crLine1, genDeduction};
        
        custReceipt1.finalized__c = true;
        update custReceipt1;
        
        Customer_Receipt_Line__c crLine2 = new Customer_Receipt_Line__c();
        crLine2.Amount__c = 90;
        crLine2.Type__c = 'Payment';
        crLine2.Customer_Receipt__c = custReceipt1.id;
        crLine2.Customer_Invoice__c = custInvoice1.id;
        crLine2.Currency__c = TestFuel.currencyUSD.id;
        crLine2.line_Number__c ='1';
    
        Test.startTest();
        String exMsg = null;
        boolean sawException = false;
        try{
            insert crLine2; // new line can not be added to source doc once it is finalized
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        Test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to add a line to a finalized doc ' + exMsg);
    }
    
    static testmethod void testCRLineDelete(){
        TestFuel data = new TestFuel();
        List<Period__c> periods = data.periodList;

        Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
        custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Adjustment';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 20;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     
        custInvoice1.Finalized__c = true;
        update  custInvoice1;
        
        Reason_Code__c deductionCode = new Reason_Code__c();{
         deductionCode.Type__c = 'Deductions';  
         deductionCode.Code__c = 'D001';
         insert deductionCode;
        }
        
        Customer_Receipt__c custReceipt1 = new Customer_Receipt__c();
        //custReceipt1.Amount_Received__c = 300;
        custReceipt1.Amount_Unapplied__c = 0;
        custReceipt1.Company__c = data.company.Id;
        custReceipt1.Customer__c = data.customerbillto.id ;
        custReceipt1.Date_Received__c = system.now();
        custReceipt1.transaction_date__c = system.now();
        custReceipt1.Currency__c = TestFuel.currencyUSD.id;
 //       custReceipt1.exception__c = false;
        
        insert custReceipt1;
        
        Customer_Receipt_Line__c crLine1 = new Customer_Receipt_Line__c();
        crLine1.Amount__c = 90;
        crLine1.Type__c = 'Payment';
        crLine1.Customer_Receipt__c = custReceipt1.id;
        crLine1.Customer_Invoice__c = custInvoice1.id;
        crLine1.Currency__c = TestFuel.currencyUSD.id;
        crLine1.line_Number__c ='1';
        
        Customer_Receipt_Line__c genDeduction = new Customer_Receipt_Line__c();
        genDeduction.Amount__c = 90;
        genDeduction.Type__c = PaymentService.TYPE_GEN_DED;
        genDeduction.Reason_Code__c = deductionCode.Id;
        genDeduction.Customer_Receipt__c = custReceipt1.Id;
        insert new list<Customer_Receipt_Line__c>{crLine1, genDeduction};
        
        
        
        custReceipt1.finalized__c = true;
        update custReceipt1;
        
        Test.startTest();
        String exMsg = null;
        boolean sawException = false;
        try{
            delete custReceipt1; //  line can not be deleted from a source doc once it is finalized
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        Test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to delete a line from a finalized doc ' + exMsg);
    }
    
    static testmethod void testCRLineUndelete(){
        TestFuel data = new TestFuel();
        List<Period__c> periods = data.periodList;

        Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
        custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Adjustment';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 40;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     
        custInvoice1.Finalized__c = true;
        update  custInvoice1;
        
        Reason_Code__c deductionCode = new Reason_Code__c();{
         deductionCode.Type__c = 'Deductions';  
         deductionCode.Code__c = 'D001';
         insert deductionCode;
        }
        
        Test.startTest();
        
        Customer_Receipt__c custReceipt1 = new Customer_Receipt__c();
        //custReceipt1.Amount_Received__c = 300;
        custReceipt1.Amount_Unapplied__c = 0;
        custReceipt1.Company__c = data.company.Id;
        custReceipt1.Customer__c = data.customerbillto.id ;
        custReceipt1.Date_Received__c = system.now();
        custReceipt1.transaction_date__c = system.now();
        custReceipt1.Currency__c = TestFuel.currencyUSD.id;
//        custReceipt1.exception__c = false;
        
        insert custReceipt1;
        
        List<Customer_Receipt_Line__c> crLineList = new List<Customer_Receipt_Line__c>();
        Customer_Receipt_Line__c crLine1 = new Customer_Receipt_Line__c();
        crLine1.Amount__c = 90;
        crLine1.Type__c = 'Payment';
        crLine1.Customer_Receipt__c = custReceipt1.id;
        crLine1.Customer_Invoice__c = custInvoice1.id;
        crLine1.Currency__c = TestFuel.currencyUSD.id;
        crLine1.line_Number__c ='1';
        crLineList.add(crLine1);
                
        Customer_Receipt_Line__c crLine2 = new Customer_Receipt_Line__c();
        crLine2.Amount__c = 90;
        crLine2.Type__c = 'Payment';
        crLine2.Customer_Receipt__c = custReceipt1.id;
        crLine2.Customer_Invoice__c = custInvoice1.id;
        crLine2.Currency__c = TestFuel.currencyUSD.id;
        crLine2.line_Number__c ='1';
        crLineList.add(crLine2);
       
       Customer_Receipt_Line__c genDeduction = new Customer_Receipt_Line__c();
        genDeduction.Amount__c = 90;
        genDeduction.Type__c = PaymentService.TYPE_GEN_DED;
        genDeduction.Reason_Code__c = deductionCode.Id;
        genDeduction.Customer_Receipt__c = custReceipt1.Id;
        crLineList.add(genDeduction);
        
       
        insert crLineList;
        
        delete crLine2;
        
        custReceipt1.finalized__c = true;
        update custReceipt1;
        
        
        String exMsg = null;
        boolean sawException = false;
        try{
            undelete crLine2; 
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        Test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to undelete a line for a finalized doc ' + exMsg);
    }
    
}