@isTest
public with sharing class GenerateAccountingBatchExtTest {
/*    static TestDataForFinance data = new TestDataForFinance();
        
    // TODO this class should insert test data of same type in one insert if possible
    // all headers first, then all lines
    
    // Test The Shipment Accounting Batch
    static testMethod void shipmentAccountingBatchTest() {
        test.startTest();
        List<Shipment__c> shipmentList = new List<Shipment__c>();
        Shipment__c shipment1 = new Shipment__c();
        shipment1.Company__c = data.company.id;
        shipment1.Date_Shipped__c = system.now();
        shipment1.Currency__c = TestFuel.currencyUSD.id;
        shipment1.transaction_date__c = system.now();
        shipment1.Status__c = 'Confirmed';
        shipmentList.add(shipment1);
        
        Shipment__c shipment2 = new Shipment__c();
        shipment2.Company__c = data.company.id;
        shipment2.Date_Shipped__c = system.now();
        shipment2.Currency__c = TestFuel.currencyUSD.id;
        shipment2.transaction_date__c = system.now();
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
        shipLineList.add(shipLine1);
        
        Shipment_Line__c shipLine2 = new Shipment_Line__c();
        shipLine2.Company__c = data.company.id;
        shipLine2.Extended_Cost__c = 5;
        shipLine2.Quantity_Shipped__c = 5;
        shipLine2.Sales_Order__c = data.salesOrder1.id;
        shipLine2.Sales_Order_Line__c = data.SalesOrderLineList[1].id;
        shipLine2.Unit_Price__c = 25;
        shipLine2.Product__c = data.product.id ; 
        shipLine2.Location__c = data.location.id;
        shipLine2.Shipment__c = shipment1.id;
        shipLineList.add(shipLine2);
        
        
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
        shipLineList.add(shipLine4);
        
        insert shipLineList;
        
        shipmentList[0].finalized__c = true;
        shipmentList[1].finalized__c = true;
        update shipmentList;
        
        Apexpages.Standardcontroller stdcon = new Apexpages.Standardcontroller(data.company);
        GenerateAccountingBatchExt GABC = new GenerateAccountingBatchExt(stdcon);
        GABC.generateShipmentAccounting();
        test.stopTest();
        
        Set<Id> shipmentIds = new Set<Id>();
        for(Shipment__c shipment: shipmentList){
            shipmentIds.add(shipment.id);
        }
        
        List<Shipment__c> ShipmentAfter = [Select id, Name, (Select id, Name from Accounting_Entries__r where void__c = false) from Shipment__c where id in :shipmentIds];
        for(integer i=0;i<ShipmentAfter.size(); i++){
           system.assertNotEquals(0,ShipmentAfter[i].Accounting_Entries__r.size());
        }
    }
    
    // Test The Customer Invoice Accounting Batch
    static testMethod void custInvoiceAccountingBatchTest() {
        Test.startTest();
        
        List<Customer_Invoice_Line__c> custInvLineList1 = new List<Customer_Invoice_Line__c>();
        List<Customer_Invoice_Line__c> custInvLineList2 = new List<Customer_Invoice_Line__c>();
        List<Customer_Invoice__c> custInvAEList = new List<Customer_Invoice__c>();

        accounting_default__c accdef = new accounting_default__c();
        accdef.company__c = data.company.id;
        accdef.gl_account__c = data.acctData.cashGL.id;
        insert accdef;
    
        List<Customer_Invoice__c> custInvList = new List<Customer_Invoice__c>();
        Customer_Invoice__c custInv1 = new Customer_Invoice__c();
        custInv1.Company__c = data.company.id;
        custInv1.Invoice_Type__c = 'Ship Invoice';
        custInv1.Date_Invoiced__c = System.today();
        custInv1.transaction_date__c = system.now();
        //Added Bill To for field filters
            custInv1.Bill_To_Customer__c = data.customer_billto.id;
        custInv1.Sold_To_Customer__c = data.customerList[0].id;
        custInv1.Subtotal__c = 0;
        custInv1.Sales_Order__c = data.salesOrder1.id;
        custInvList.add(custInv1);
        
        Customer_Invoice__c custInv2 = new Customer_Invoice__c();
        custInv2.Company__c = data.company.id;
        custInv2.Invoice_Type__c = 'Ship Invoice';
        custInv2.Date_Invoiced__c = System.today();
        custInv2.transaction_date__c = system.now();
        //Added Bill To for field filters
        custInv2.Bill_To_Customer__c = data.customer_billto1.id;
        custInv2.Sold_To_Customer__c = data.customerList[1].id;
        custInv2.Subtotal__c = 0;
        custInv2.Sales_Order__c = data.salesOrder2.id;
        custInvList.add(custInv2);
        
        Customer_Invoice__c custInv3 = new Customer_Invoice__c();
        custInv3.Company__c = data.company.id;
        custInv3.Invoice_Type__c = 'Miscellaneous';
        custInv3.Date_Invoiced__c = System.now();
        custInv3.Transaction_Date__c = System.now();
        //Added Bill To for field filters
        custInv3.Bill_To_Customer__c = data.customer_billto.id;
        custInv3.Sold_to_customer__c = data.customerList[0].id;
        custInvList.add(custInv3);
        insert custInvList;
        
        Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
        custInvLine1.Company__c = data.company.id;
        custInvLine1.Quantity_Shipped__c = 2;
        custInvLine1.Unit_Price__c = 7;
        custInvLine1.Product__c = data.product.id ;
        custInvLine1.Discount_Percent__c = 0.2;
        custInvLine1.Customer_Invoice__c = custInv1.id;
        custInvLineList1.add(custInvLine1);
        
        Customer_Invoice_Line__c custInvLine2 = new Customer_Invoice_Line__c();
        custInvLine2.Quantity_Shipped__c = 3;
        custInvLine2.Company__c = data.company.id;
        custInvLine2.Product__c = data.product.id ;
        custInvLine2.Unit_Price__c = 9;
        custInvLine2.Discount_Percent__c = 0.2;
        custInvLine2.Customer_Invoice__c = custInv1.id;
        custInvLineList1.add(custInvLine2);
        
        insert custInvLineList1;        
          
        Customer_Invoice_Line__c custInvLine3 = new Customer_Invoice_Line__c();
        custInvLine3.Company__c = data.company.id;
        custInvLine3.Product__c = data.product.id ;
        custInvLine3.Quantity_Shipped__c = 2;
        custInvLine3.Unit_Price__c = 7;
        custInvLine3.Discount_Percent__c = 0.2;
        custInvLine3.Customer_Invoice__c = custInv2.id;
        custInvLineList2.add(custInvLine3);
        
        Customer_Invoice_Line__c custInvLine4 = new Customer_Invoice_Line__c();
        custInvLine4.Company__c = data.company.id;
        custInvLine4.Product__c = data.product.id ;
        custInvLine4.Quantity_Shipped__c = 3;
        custInvLine4.Unit_Price__c = 9;
        custInvLine4.Discount_Percent__c = 0.2;
        custInvLine4.Customer_Invoice__c = custInv2.id;
        custInvLineList2.add(custInvLine4);
        insert custInvLineList2;
        
        
        Customer_Invoice_Line__c custInvLine5 = new Customer_Invoice_Line__c();
        custInvLine5.Quantity_Shipped__c = -5;
        custInvLine5.accounting_segment__c = accdef.id;
        custInvLine5.Company__c = data.company.id;
        custInvLine5.Unit_Price__c = 10;
        custInvLine5.Product__c = data.product.id ; 
        custInvLine5.Customer_Invoice__c = custInv3.id;
        insert custInvLine5;
        
        custInvList[0].finalized__c = true;
        custInvList[1].finalized__c = true;
        custInvList[2].finalized__c = true;
        update custInvList;
        
        custInvAEList.add(custInv1);
        custInvAEList.add(custInv2);
        custInvAEList.add(custInv3);
        system.debug(Logginglevel.INFO+'custInvAEList:'+custInvAEList);
        Apexpages.Standardcontroller stdcon = new Apexpages.Standardcontroller(data.company);
        GenerateAccountingBatchExt GABC = new GenerateAccountingBatchExt(stdcon);
        GABC.generateInvoiceAccounting();
        test.stopTest();
        
        Set<Id> invoiceIds = new Set<Id>();
        for(Customer_Invoice__c invoice: custInvAEList){
            invoiceIds.add(invoice.id);
        }
        
        List<Customer_Invoice__c> InvoicesAfter = [Select id, Name, Invoice_Type__c,(Select id,Name from Accounting_Entries__r where void__c = false) from Customer_Invoice__c where id in :invoiceIds];
        system.debug(Logginglevel.INFO+'InvoicesAfter:'+InvoicesAfter);
        //system.assertEquals(3, InvoicesAfter.size());
        /* TODO: fix me at the end of KNDY-3369
        for(integer i=0;i<InvoicesAfter.size(); i++){
            system.assertNotEquals(0,InvoicesAfter[i].Accounting_Entries__r.size());
        }
    }
    
    // Test The Customer Receipt Accounting Batch
    static testMethod void custReceiptAccountingBatchTest() {
        //GenerateAccountingService GAS = new GenerateAccountingService();
        test.startTest();
        
        CustomerReceiptAccounting cra = new CustomerReceiptAccounting();
          
        Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
        //Added Bill To for field filters
            custInvoice1.Bill_To_Customer__c = data.customer_billto.id;
        custInvoice1.Sold_To_Customer__c = data.customerList[0].id;
        custInvoice1.Sales_Order__c = data.salesOrder1.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.Transaction_Date__c = System.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Subtotal__c = 0;
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        
        Customer_Invoice__c custInvoice2 = new Customer_Invoice__c();
        custInvoice2.Company__c = data.company.id;
        //Added Bill To for field filters
            custInvoice2.Bill_To_Customer__c = data.customer_billto.id;
        custInvoice2.Sold_To_Customer__c = data.customerList[0].id;
        custInvoice2.Sales_Order__c = data.salesOrder2.Id;
        custInvoice2.Date_Invoiced__c = System.now();
        custInvoice2.Transaction_Date__c = System.now();
        custInvoice2.status__c = 'Open';
        custInvoice2.Subtotal__c = 0;
        custInvoice2.Currency__c = TestFuel.currencyUSD.id;
        custInvoice2.Invoice_Type__c = 'Ship Invoice';
        insert new List<Customer_Invoice__c > { custInvoice1, custInvoice2} ;
        
        
        Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
            custInvLine1.Company__c = data.company.id;
            custInvLine1.Quantity_Shipped__c = 5;
            //custInvLine1.Sales_Order_Line__c = data.SalesOrderLineList[0].id;
            custInvLine1.Unit_Price__c = 10;
            //custInvLine1.Sales_Order__c = data.salesOrder1.id;
            custInvLine1.Product__c = data.product.id ; 
            custInvLine1.Discount_Percent__c = data.SalesOrderLineList[0].Discount_Percent__c;
            custInvLine1.Customer_Invoice__c = custInvoice1.Id; 
     
        
        Customer_Invoice_Line__c custInvLine2 = new Customer_Invoice_Line__c();
            custInvLine2.Company__c = data.company.id;
            custInvLine2.Quantity_Shipped__c = 5;
            //custInvLine2.Sales_Order_Line__c = data.SalesOrderLineList[2].id;
            custInvLine2.Unit_Price__c = 10;
            //shipmentObj2.Sales_Order__c = data.salesOrder2.id;
            custInvLine2.Product__c = data.product.id ; 
            custInvLine2.Discount_Percent__c = data.SalesOrderLineList[2].Discount_Percent__c;
    
            custInvLine2.Customer_Invoice__c = custInvoice2.Id; 
    
        insert new List<Customer_Invoice_Line__c> { custInvLine1, custInvLine2};                
            
        custInvoice1.finalized__c = true;
        custInvoice2.finalized__c = true;
        update new List<Customer_Invoice__c > { custInvoice1, custInvoice2} ;
   
        
        Reason_Code__c deductionCode = new Reason_Code__c();{
         deductionCode.Type__c = 'Deductions';  
         deductionCode.Code__c = 'D001';
         insert deductionCode;
        }
        
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();
        
        Customer_Receipt__c custReceipt1 = new Customer_Receipt__c();
            //custReceipt1.Amount_Received__c = 300;
            custReceipt1.Amount_Unapplied__c = 0;
            custReceipt1.Company__c = data.company.Id;
            //custReceipt1.Bank_Account__c = data.bankAccount.id;
            custReceipt1.Customer__c = data.customer_billto.id;
            custReceipt1.Date_Received__c = system.now();
            custReceipt1.transaction_date__c = system.now();
            //custReceipt1.Payment_Method__c = 'Check';
            custReceipt1.Currency__c = TestFuel.currencyUSD.id;
            
            custReceipt1.exception__c = false;
           
        
        Customer_Receipt__c custReceipt2 = new Customer_Receipt__c();
            //custReceipt2.Amount_Received__c = 300;
            custReceipt2.Amount_Unapplied__c = 0;
            custReceipt2.Company__c = data.company.Id;
            //custReceipt2.Bank_Account__c = data.bankAccount.id;
            custReceipt2.Customer__c = data.customer_billto.id;
            custReceipt2.Date_Received__c = system.now();
            custReceipt2.transaction_date__c = system.now();
            //custReceipt2.Payment_Method__c = 'Check';
            custReceipt2.Currency__c = TestFuel.currencyUSD.id;
            
            custReceipt2.exception__c = false;
            
        insert new List<Customer_Receipt__c> { custReceipt1, custReceipt2} ;  
        
        Customer_Receipt_Line__c crl1 = new Customer_Receipt_Line__c();
            crl1.Amount_To_Apply__c = 100;
            crl1.amount__c = 10;  
        	crl1.Reason_Code__c = deductionCode.Id;
            crl1.Customer_Receipt__c = custReceipt1.id;
            crl1.Customer_Invoice__c = custInvoice1.id;
            crl1.Type__c ='Payment';
            crl1.Currency__c = TestFuel.currencyUSD.id;
            crl1.line_Number__c ='1';
        
        Customer_Receipt_Line__c genDeduction = new Customer_Receipt_Line__c();
        genDeduction.Amount__c = 10;
        genDeduction.Type__c = PaymentService.TYPE_GEN_DED;
        genDeduction.Customer_Receipt__c = custReceipt1.Id;
        genDeduction.Reason_Code__c = deductionCode.Id;
        
        Customer_Receipt_Line__c genDeduction1 = new Customer_Receipt_Line__c();
        genDeduction1.Amount__c = 10;
        genDeduction1.Type__c = PaymentService.TYPE_GEN_DED;
        genDeduction1.Customer_Receipt__c = custReceipt2.Id;
        genDeduction1.Reason_Code__c = deductionCode.Id;
            
        
        Customer_Receipt_Line__c crl2 = new Customer_Receipt_Line__c();
            crl2.Amount_To_Apply__c = 100;
            crl2.amount__c = 10;
            crl2.Customer_Receipt__c = custReceipt2.id;
            crl2.Customer_Invoice__c = custInvoice2.id;
            crl1.Type__c ='Payment';
            crl2.Currency__c = TestFuel.currencyUSD.id;
            crl2.line_Number__c ='1';
        
        insert new list < Customer_Receipt_Line__c> { crl1, crl2, genDeduction, genDeduction1};
        
        custReceipt1.Finalized__c = true;
        custReceipt2.Finalized__c = true;     
        update new List<Customer_Receipt__c> { custReceipt1, custReceipt2} ; 
        
        custReceiptList.add(custReceipt1);
        custReceiptList.add(custReceipt2);
        
        Apexpages.Standardcontroller stdcon = new Apexpages.Standardcontroller(data.company);
        GenerateAccountingBatchExt GABC = new GenerateAccountingBatchExt(stdcon);
        
        GABC.generateReceiptAccounting();
        test.stopTest();
        
        Set<Id> receiptIds = new Set<Id>();
        for(Customer_Receipt__c receipt: custReceiptList){
            receiptIds.add(receipt.id);
        }
        
        List<Customer_Receipt__c> ReceiptsAfter = [Select id, Name, (Select id, Name from Accounting_Entries__r where void__c = false) from Customer_Receipt__c where id in :receiptIds];
    
        for(integer i=0;i<ReceiptsAfter.size(); i++){
            system.assertNotEquals(0,ReceiptsAfter[i].Accounting_Entries__r.size() );
        }
        }
    
    // Test The PO Receipt Accounting Batch
    static testMethod void POReceiptAccountingBatchTest() {
        test.startTest();
        
        //GenerateAccountingService GAS = new GenerateAccountingService();
        ReceivingDocumentAccounting rda = new ReceivingDocumentAccounting();
        
        List<Purchase_Order__c> poList = new List<Purchase_Order__c>();
        poList = [Select   p.Supplier__c,         p.Status__c, 
                                p.Payment_Term__c, p.Order_Date__c, 
                                p.Name, p.Id, p.Deliver_to__c, p.Date_Closed__c, 
                                p.Company__c, p.Buyer__c,   
                                p.Approval_Status__c, p.Acknowledge_Via__c, 
                                (Select Id, IsDeleted, Name, Purchase_Order__c, Company__c, 
                                    Date_Added__c, Date_Closed__c, Date_Last_Changed__c, Description__c,  
                                    Item__c, Latest_Promise_Date__c, Line_Value__c, Line__c,  Manufacturers_Part__c, 
                                    Need_Date__c, Order_Quantity__c, Overage_Percentage__c, 
                                    Promise_Date__c, Purchase_UOM__c, Quantity_Returned_to_Supplier__c, 
                                    Quantity_Still_Due__c, Requisition_Number__c, Rush_Line__c, Special_Notes__c, Status__c, 
                                    Supplier_Part__c, Suppliers_Part_Description__c, Unit_Price__c 
                                    From Purchase_Order_Lines__r order by Line__c ASC) 
                                From Purchase_Order__c p
                                where p.id in (:data.purchaseOrder1.id, :data.purchaseOrder2.id, :data.purchaseOrder3.id)];
        List<Receiving_Document__c> receivingDocList = new List<Receiving_Document__c>(); 
        Receiving_Document__c receivingdocument1=new Receiving_Document__c(); { 
            receivingdocument1.Company__c=data.company.Id;
            receivingdocument1.Supplier__c=data.supplier.Id;
            receivingdocument1.Status__c = 'Open';        
            receivingdocument1.Date_Received__c = System.now();
            //receivingdocument1.Finalized__c = true;
            receivingdocument1.Currency__c = TestFuel.currencyUSD.id;
            receivingdocument1.Transaction_Date__c = system.now();
            insert receivingdocument1; 
        }
        receivingDocList.add(receivingdocument1);
        Receiving_Document__c receivingdocument2=new Receiving_Document__c(); { 
            receivingdocument2.Company__c=data.company.Id;
            receivingdocument2.Supplier__c=data.supplier.Id;
            receivingdocument2.Status__c = 'Open';        
            receivingdocument2.Date_Received__c = System.now();
            //receivingdocument2.Finalized__c = true;
            receivingdocument2.Currency__c = TestFuel.currencyUSD.id;
            receivingdocument2.Transaction_Date__c = system.now();
            insert receivingdocument2; 
        }
        receivingDocList.add(receivingdocument2);
        Receiving_Document__c receivingdocument3=new Receiving_Document__c(); { 
            receivingdocument3.Company__c=data.company.Id;
            receivingdocument3.Supplier__c=data.supplier.Id;
            receivingdocument3.Status__c = 'Open';        
            receivingdocument3.Date_Received__c = System.now();
            //receivingdocument3.Finalized__c = true;
            receivingdocument3.Currency__c = TestFuel.currencyUSD.id;
            receivingdocument3.Transaction_Date__c = system.now();
            insert receivingdocument3; 
        }
        receivingDocList.add(receivingdocument3);
        List<Purchase_Order_Line__c> polineList = [select Id, Purchase_Order__c, Item__c,Unit_Price__c,Order_Quantity__c  
                                                    from Purchase_Order_Line__c 
                                                    where Purchase_Order__c  in (:data.purchaseOrder1.id, :data.purchaseOrder2.id, :data.purchaseOrder3.id)];
                                                     
        List<Receipt_Line__c> receiptinvoicelineList = new List<Receipt_Line__c>();
            Receipt_Line__c receiptinvoiceline1 = new Receipt_Line__c();
            receiptinvoiceline1.Item__c = data.itemList[0].id;
            receiptinvoiceline1.Company__c = data.company.id;
            receiptinvoiceline1.Supplier__c=data.supplier.Id;
            receiptinvoiceline1.Status__c = 'Open';     
            receiptinvoiceline1.Receiving_Document__c=receivingdocument1.Id;
            receiptinvoiceline1.Location__c = data.location.id;
            receiptinvoiceline1.Unit_Price__c = 15;
            receiptinvoiceline1.Purchase_Order__c = data.purchaseOrder1.id;
            receiptinvoiceline1.Purchase_Order_Line__c = polineList[0].ID;
            receiptinvoiceline1.Quantity_Received__c = 6;
            receiptinvoiceline1.Extended_Cost__c = 70;
            receiptinvoicelineList.add(receiptinvoiceline1); 
            
            Receipt_Line__c receiptinvoiceline2 = new Receipt_Line__c();
            receiptinvoiceline2.Item__c = data.itemList[0].id;
            receiptinvoiceline2.Company__c = data.company.id;
            receiptinvoiceline2.Supplier__c=data.supplier.Id;
            receiptinvoiceline2.Status__c = 'Open';     
            receiptinvoiceline2.Receiving_Document__c=receivingdocument2.Id;
            receiptinvoiceline2.Location__c = data.location.id;
            receiptinvoiceline2.Unit_Price__c = 15;
            receiptinvoiceline2.Purchase_Order__c = data.purchaseOrder2.id;
            receiptinvoiceline2.Purchase_Order_Line__c = polineList[1].ID;
            receiptinvoiceline2.Quantity_Received__c = 6;
            receiptinvoiceline2.Extended_Cost__c = 70;
            receiptinvoicelineList.add(receiptinvoiceline2);
            
            Receipt_Line__c receiptinvoiceline3 = new Receipt_Line__c();
            receiptinvoiceline3.Item__c = data.itemList[0].id;
            receiptinvoiceline3.Company__c = data.company.id;
            receiptinvoiceline3.Supplier__c=data.supplier.Id;
            receiptinvoiceline3.Status__c = 'Open';     
            receiptinvoiceline3.Receiving_Document__c=receivingdocument2.Id;
            receiptinvoiceline3.Location__c = data.location.id;
            receiptinvoiceline3.Unit_Price__c = 15;
            receiptinvoiceline3.Purchase_Order__c = data.purchaseOrder2.id;
            receiptinvoiceline3.Purchase_Order_Line__c = polineList[2].ID;
            receiptinvoiceline3.Quantity_Received__c = 6;
            receiptinvoiceline3.Extended_Cost__c = 70;
            receiptinvoicelineList.add(receiptinvoiceline3);
            
            Receipt_Line__c receiptinvoiceline4 = new Receipt_Line__c();
            receiptinvoiceline4.Item__c = data.itemList[0].id;
            receiptinvoiceline4.Company__c = data.company.id;
            receiptinvoiceline4.Supplier__c=data.supplier.Id;
            receiptinvoiceline4.Status__c = 'Open';     
            receiptinvoiceline4.Receiving_Document__c=receivingdocument3.Id;
            receiptinvoiceline4.Location__c = data.location.id;
            receiptinvoiceline4.Unit_Price__c = 15;
            receiptinvoiceline4.Purchase_Order__c = data.purchaseOrder3.id;
            receiptinvoiceline4.Purchase_Order_Line__c = polineList[3].ID;
            receiptinvoiceline4.Quantity_Received__c = 6;
            receiptinvoiceline4.Extended_Cost__c = 70;
            receiptinvoicelineList.add(receiptinvoiceline4);
            
            Receipt_Line__c receiptinvoiceline5 = new Receipt_Line__c();
            receiptinvoiceline5.Item__c = data.itemList[0].id;
            receiptinvoiceline5.Company__c = data.company.id;
            receiptinvoiceline5.Supplier__c=data.supplier.Id;
            receiptinvoiceline5.Status__c = 'Open';     
            receiptinvoiceline5.Receiving_Document__c=receivingdocument3.Id;
            receiptinvoiceline5.Location__c = data.location.id;
            receiptinvoiceline5.Unit_Price__c = 15;
            receiptinvoiceline5.Purchase_Order__c = data.purchaseOrder3.id;
            receiptinvoiceline5.Purchase_Order_Line__c = polineList[4].ID;
            receiptinvoiceline5.Quantity_Received__c = 6;
            receiptinvoiceline5.Extended_Cost__c = 70;
            receiptinvoicelineList.add(receiptinvoiceline5);
            
            insert receiptinvoicelineList;
            
            //loop throught the receiptlines and null out the line types so it matches with the accounting rules in the test data
            //it was defaulted to the PO line's line type
            for(Receipt_Line__c rl: receiptinvoicelineList){
                rl.Line_Type__c = null;
            } 
            update receiptinvoicelineList;           
            
            
            for(Receiving_Document__c receipt: receivingDocList){
                receipt.finalized__c = true;
            }
            
            update receivingDocList;
            
            Apexpages.Standardcontroller stdcon = new Apexpages.Standardcontroller(data.company);
            GenerateAccountingBatchExt GABC = new GenerateAccountingBatchExt(stdcon);
            GABC.generatePOReceiptAccounting() ;
            test.stopTest();
            
            Set<Id> receiptIds = new Set<Id>();
            for(Receiving_Document__c receipt: receivingDocList){
                receiptIds.add(receipt.id);
            }
            
            List<Receiving_Document__c> ReceiptsAfter = [Select id, Name, (Select id, Name from Accounting_Entries__r where void__c = false) from Receiving_Document__c where id in :receiptIds];
        
            for(integer i=0;i<ReceiptsAfter.size(); i++){
                system.assertNotEquals(0,ReceiptsAfter[i].Accounting_Entries__r.size());
            }
        }
    
    // Test The Supplier Invoice Accounting Batch
    static testMethod void suppInvoiceAccountingBatchTest() {
        test.startTest();
        List<Supplier_Invoice_Line__c> suppInvLineList1 = new List<Supplier_Invoice_Line__c>();
        List<Supplier_Invoice_Line__c> suppInvLineList2 = new List<Supplier_Invoice_Line__c>();
        List<Supplier_Invoice__c> suppInvAEList = new List<Supplier_Invoice__c>();
        
        List<Purchase_Order_Line__c> poLineList = [Select id, Name from Purchase_Order_Line__c where Purchase_Order__c in (:data.purchaseOrder2.id, :data.purchaseOrder3.id)];

        Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();
        suppInv1.Company__c = data.company.id;
        suppInv1.Date_Invoiced__c = System.today();
        suppInv1.Supplier__c = data.remittosupplier.id;
        suppInv1.Supplier_Invoice__c = KSE.getUniqueNumberString();
        suppInv1.Amount_Due__c = data.purchaseOrder1.Purchase_Order_Value__c;
        suppInv1.Invoice_Amount__c = data.purchaseOrder1.Purchase_Order_Value__c;
        suppInv1.Currency__c = TestFuel.currencyUSD.id;
        suppInv1.Transaction_Date__c = system.now();
        
        system.assert(data.purchaseOrder1.Purchase_Order_Value__c>0, 'PO Value <-0: ' + data.purchaseOrder1);
        insert suppInv1;
        
        Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c();           
        suppInvLine1.Supplier_Invoice__c = suppInv1.Id;
        suppInvLine1.Extended_Cost__c = 50;
        suppInvLine1.Invoice_Quantity__c = 4;
        suppInvLine1.Invoice_Unit_Price__c = 20;
        suppInvLine1.Item__c = data.itemList[0].id;
        suppInvLine1.Purchase_Order__c = data.purchaseOrder2.id;
        suppInvLine1.Purchase_Order_Line__c = poLineList[0].id;
        suppInvLine1.Quantity_Received__c = 4;
        suppInvLine1.Unit_Price__c = 15; 
        suppInvLineList1.add(suppInvLine1);
        
        Supplier_Invoice_Line__c suppInvLine2 = new Supplier_Invoice_Line__c();   
        suppInvLine2.Supplier_Invoice__c = suppInv1.Id;
        suppInvLine2.Extended_Cost__c = 50;
        suppInvLine2.Invoice_Quantity__c = 2;
        suppInvLine2.Invoice_Unit_Price__c = 20;
        suppInvLine2.Item__c = data.itemList[0].id;
        suppInvLine2.Purchase_Order__c = data.purchaseOrder2.id;
        suppInvLine2.Purchase_Order_Line__c = poLineList[1].id;
        suppInvLine2.Quantity_Received__c = 4;
        suppInvLine2.Unit_Price__c = 15; 
        suppInvLineList1.add(suppInvLine2);
        insert suppInvLineList1;
        
        suppInv1.Finalized__c = true;
        update suppInv1;
        
        Supplier_Invoice__c suppInv2 = new Supplier_Invoice__c();
        suppInv2.Company__c = data.company.id;
        suppInv2.Date_Invoiced__c = System.today();
        suppInv2.Supplier__c = data.remittosupplier.id;
        suppInv2.Supplier_Invoice__c = KSE.getUniqueNumberString();
        suppInv2.Amount_Due__c = data.purchaseOrder2.Purchase_Order_Value__c;
        suppInv2.Invoice_Amount__c = data.purchaseOrder2.Purchase_Order_Value__c;
        suppInv2.Currency__c = TestFuel.currencyUSD.id;
        suppInv2.Transaction_Date__c = system.now();
        insert suppInv2;
        
        Supplier_Invoice_Line__c suppInvLine3 = new Supplier_Invoice_Line__c();
        suppInvLine3.Supplier_Invoice__c = suppInv2.Id;
        suppInvLine3.Extended_Cost__c = 50;
        suppInvLine3.Invoice_Quantity__c = 4;
        suppInvLine3.Invoice_Unit_Price__c = 50;
        suppInvLine3.Item__c = data.itemList[0].id;
        suppInvLine3.Purchase_Order__c = data.purchaseOrder3.id;
        suppInvLine2.Purchase_Order_Line__c = poLineList[2].id;
        suppInvLine3.Quantity_Received__c = 4;
        suppInvLine3.Unit_Price__c = 15; 
        suppInvLineList2.add(suppInvLine3);
        
        Supplier_Invoice_Line__c suppInvLine4 = new Supplier_Invoice_Line__c();    
        suppInvLine4.Supplier_Invoice__c = suppInv2.Id;
        suppInvLine4.Extended_Cost__c = 50;
        suppInvLine4.Invoice_Quantity__c = 5;
        suppInvLine4.Invoice_Unit_Price__c = 25;
        suppInvLine4.Item__c = data.itemList[0].id;
        suppInvLine4.Purchase_Order__c = data.purchaseOrder3.id;
        suppInvLine2.Purchase_Order_Line__c = poLineList[3].id;
        suppInvLine4.Quantity_Received__c = 4;
        suppInvLine4.Unit_Price__c = 15; 
        suppInvLineList2.add(suppInvLine4);
        insert suppInvLineList2;
        
        suppInv2.Finalized__c = true;
        update suppInv2;
        
        suppInvAEList.add(suppInv1);
        suppInvAEList.add(suppInv2);
        
        Apexpages.Standardcontroller stdcon = new Apexpages.Standardcontroller(data.company);
        GenerateAccountingBatchExt GABC = new GenerateAccountingBatchExt(stdcon);
        GABC.generateSupplierInvoiceAccounting();
        test.stopTest();
        
        Set<Id> invoiceIds = new Set<Id>();
        for(Supplier_Invoice__c invoice: suppInvAEList){
            invoiceIds.add(invoice.id);
        }
        
        List<Supplier_Invoice__c> InvoicesAfter = [Select id, Name, (Select id, Name from Accounting_Entries__r where void__c = false) from Supplier_Invoice__c where id in :invoiceIds];
        /* TODO: Fix me at the end of KNDY-3369
        for(integer i=0;i<InvoicesAfter.size(); i++){
            system.assertNotEquals(0,InvoicesAfter[i].Accounting_Entries__r.size());
        }
        
        
    }
    
    // Test The Supplier Payment Accounting Batch
    static testMethod void suppPaymentAccountingBatchTest() {
        test.startTest();
        
        //GenerateAccountingService GAS = new GenerateAccountingService();
        SupplierPaymentAccounting spa = new SupplierPaymentAccounting();
        
        // Query POs from data class    
        List<Purchase_Order__c> poList = new List<Purchase_Order__c>();
        poList = [Select   p.Supplier__c,         p.Status__c, 
                                p.Ship_Via__c, p.Rush_Order__c, 
                                p.Payment_Term__c, p.Order_Date__c, 
                                p.Name, p.Remit_To_Supplier__c,
                                p.Id, p.Deliver_to__c, p.Date_Closed__c, 
                                p.Company__c, p.Buyer__c, p.Approval_Status__c, p.Acknowledge_Via__c,p.Purchase_Order_Value__c, 
                                (Select Id, IsDeleted, Name, Purchase_Order__c, Company__c, 
                                    Date_Added__c, Date_Closed__c, Date_Last_Changed__c, Description__c,  
                                    Item__c, Latest_Promise_Date__c, Line_Value__c, Line__c,  Manufacturers_Part__c, 
                                    Need_Date__c, Order_Quantity__c, Overage_Percentage__c, 
                                    Promise_Date__c, Purchase_UOM__c, Quantity_Returned_to_Supplier__c, 
                                    Quantity_Still_Due__c, Requisition_Number__c, Rush_Line__c, Special_Notes__c, Status__c, 
                                    Supplier_Part__c, Suppliers_Part_Description__c, Unit_Price__c 
                                    From Purchase_Order_Lines__r order by Line__c ASC) 
                                From Purchase_Order__c p
                                where p.id in (:data.purchaseOrder1.id, :data.purchaseOrder2.id, :data.purchaseOrder3.id)];
        // Create Receiving document
        Receiving_Document__c receivingdocument=new Receiving_Document__c(); { 
            receivingdocument.Company__c=data.company.Id;
            //receivingdocument.Finalized__c = true;
            receivingdocument.Date_Received__c = system.now();
            receivingdocument.Supplier__c=data.supplier.Id;
            receivingdocument.Status__c = 'Closed';    
            receivingdocument.Transaction_Date__c = system.now();    
            receivingdocument.Currency__c = TestFuel.currencyUSD.id;
            insert receivingdocument; 
        }
        
        Receipt_Line__c rl = new Receipt_Line__c();
        rl.Item__c = data.itemList[0].id;
        rl.Company__c = poList[0].company__c;
        rl.Supplier__c = poList[0].supplier__c;
        rl.Status__c = 'Open';     
        rl.Receiving_Document__c = receivingdocument.Id;
        rl.Location__c = data.location.id;
        rl.Unit_Price__c = 15;
        rl.Purchase_Order__c = poList[0].id;
        rl.Purchase_Order_Line__c = poList[0].Purchase_Order_Lines__r[0].ID;
        rl.Quantity_Received__c = poList[0].Purchase_Order_Lines__r[0].Quantity_Still_Due__c;
        rl.Extended_Cost__c = 70;
        insert rl;
        
        receivingdocument.finalized__c = true;
        update receivingdocument;
        
        // Create Supplier Invoices for each PO
        List<Supplier_Invoice__c> supplierInvList = new List<Supplier_Invoice__c>();
        Integer intCount = 0;
        for(Purchase_Order__c po:poList){
            Supplier_Invoice__c suppInv = new Supplier_Invoice__c();
            suppInv.Amount_Due__c = po.Purchase_Order_Value__c;
            suppInv.Invoice_Amount__c = po.Purchase_Order_Value__c;
            suppInv.Company__c = po.Company__c;
            suppInv.Supplier_Invoice__c = KSE.getUniqueNumberString();
            suppInv.Date_Invoiced__c = system.now();
            suppInv.Supplier__c = po.Remit_To_Supplier__c;     
            suppInv.Currency__c = TestFuel.currencyUSD.id;
            suppInv.Transaction_Date__c = system.now();       
            supplierInvList.add(suppInv);
            intCount++;
        }
        insert supplierInvList;
    
        // Add lines to the invoices  
        List<Purchase_Order_Line__c> polineList = [select Id, Purchase_Order__c, Item__c,Unit_Price__c,Order_Quantity__c,company__c,delivery_facility__c, need_date__c  from Purchase_Order_Line__c where Purchase_Order__c  in (:data.purchaseOrder1.id, :data.purchaseOrder2.id, :data.purchaseOrder3.id)]; 
        List<Supplier_Invoice_Line__c> receiptinvoicelineList = new List<Supplier_Invoice_Line__c>();
        
        Set<Id> ItemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        List<Date> dateList = new List<Date>();
        for(Purchase_Order_Line__c pol : polineList) {
            ItemIds.add(pol.Item__c);
            facilityIds.add(pol.Delivery_Facility__c);
            dateList.add(pol.Need_Date__c); 
        }
        
        ItemService.preCacheCostRecords(dateList, itemIds, facilityIds);
        
        for(Integer i=0;i<polineList.size();i++){
            Supplier_Invoice_Line__c receiptinvoiceline = new Supplier_Invoice_Line__c();
            receiptinvoiceline.Item__c = polineList[i].Item__c;
            receiptinvoiceline.Invoice_Quantity__c = polineList[i].Order_Quantity__c;
            receiptinvoiceline.Invoice_Unit_Price__c = polineList[i].Unit_Price__c;
            receiptinvoiceline.Unit_Price__c = polineList[i].Unit_Price__c;
            receiptinvoiceline.Purchase_Order__c = polineList[i].Purchase_Order__c;
            receiptinvoiceline.Purchase_Order_Line__c = polineList[i].ID;
            receiptinvoiceline.Quantity_Received__c = polineList[i].Order_Quantity__c;
            //KNDY-2170
            //receiptinvoiceline.Extended_Cost__c = polineList[i].Order_Quantity__c * polineList[i].item__r.Active_Standard_Cost__c;
            system.assert(polineList[i].Order_Quantity__c != null);
            Decimal tmpCost = ItemService.getActiveStandardCost(ItemIds,facilityIds, polineList[i].company__c, polineList[i].delivery_facility__c, system.now()).get(polineList[i].Item__c);
            //system.assert(tmpCost != null);
            if(tmpCost == null) tmpCost = 0; 
            receiptinvoiceline.Extended_Cost__c = polineList[i].Order_Quantity__c * tmpCost;
            receiptinvoicelineList.add(receiptinvoiceline); 
        }
        

        // Update the Supplier Invoice on the lines
        receiptinvoicelineList[0].Supplier_Invoice__c = supplierInvList[0].id;
        receiptinvoicelineList[1].Supplier_Invoice__c = supplierInvList[1].id;
        receiptinvoicelineList[2].Supplier_Invoice__c = supplierInvList[1].id;
        receiptinvoicelineList[3].Supplier_Invoice__c = supplierInvList[2].id;
        receiptinvoicelineList[4].Supplier_Invoice__c = supplierInvList[2].id;
        
        insert receiptinvoicelineList;
        // Update the supplier invoice Finalized Flag to true
        supplierInvList[0].Finalized__c = true;
        supplierInvList[1].Finalized__c = true;
        supplierInvList[2].Finalized__c = true;
        update supplierInvList;

         
        Set<Id> RcptInvIds = new Set<Id>();
        for(Supplier_Invoice_Line__c rcptInvLine: receiptinvoicelineList){
            RcptInvIds.add(rcptInvLine.id);
        }
        List<Supplier_Payment__c> suppPayList = new List<Supplier_Payment__c>();
        
        // Create Supplier Payments
        Supplier_Payment__c suppPay1 = new Supplier_Payment__c();
        suppPay1.Payment_Amount__c = poList[0].Purchase_Order_Value__c;
        suppPay1.Date_Paid__c = system.now();
        suppPay1.Payment_Method__c = 'Check';
        suppPay1.Bank_Account__c = data.bankAccount.id ;
        suppPay1.Company__c = poList[0].Company__c;
        suppPay1.Supplier__c = poList[0].Remit_To_Supplier__c;
        suppPay1.Currency__c = TestFuel.currencyUSD.id;
        suppPayList.add(suppPay1);
        
        Supplier_Payment__c suppPay2 = new Supplier_Payment__c();
        suppPay2.Payment_Amount__c = poList[1].Purchase_Order_Value__c;
        suppPay2.Date_Paid__c = system.now();
        suppPay2.Payment_Method__c = 'Check';
        suppPay2.Bank_Account__c = data.bankAccount.id ;
        suppPay2.Company__c = poList[1].Company__c;
        suppPay2.Supplier__c = poList[1].Remit_To_Supplier__c;
        suppPay2.Currency__c = TestFuel.currencyUSD.id;
        suppPayList.add(suppPay2);
        
        Supplier_Payment__c suppPay3 = new Supplier_Payment__c();
        suppPay3.Payment_Amount__c = poList[2].Purchase_Order_Value__c;
        suppPay3.Date_Paid__c = system.now();
        suppPay3.Payment_Method__c = 'Check';
        suppPay3.Bank_Account__c = data.bankAccount.id ;
        suppPay3.Company__c = poList[2].Company__c;
        suppPay3.Supplier__c = poList[2].Remit_To_Supplier__c;
        suppPay3.Currency__c = TestFuel.currencyUSD.id;
        suppPayList.add(suppPay3);
        insert suppPayList;
        
        Set<ID> SuppPayIds = new Set<Id>();
        for(Supplier_Payment__c suppPay: suppPayList){
            SuppPayIds.add(suppPay.id);
        }
        
        // Create Payments
        List<Supplier_Payment_Line__c> paymentList = new List<Supplier_Payment_Line__c>();
        Supplier_Payment_Line__c payment1 = new Supplier_Payment_Line__c();
        payment1.Supplier_Invoice__c = supplierInvList[0].id;
        payment1.Supplier_Payment__c = suppPayList[0].id;
        payment1.Amount_To_Apply__c = suppPayList[0].Payment_Amount__c;
        paymentList.add(payment1);
        
        Supplier_Payment_Line__c payment2 = new Supplier_Payment_Line__c();
        payment2.Supplier_Invoice__c = supplierInvList[1].id;
        payment2.Supplier_Payment__c = suppPayList[1].id;
        payment2.Amount_To_Apply__c = suppPayList[1].Payment_Amount__c;
        paymentList.add(payment2);
        
        Supplier_Payment_Line__c payment3 = new Supplier_Payment_Line__c();
        payment3.Supplier_Invoice__c = supplierInvList[2].id;
        payment3.Supplier_Payment__c = suppPayList[2].id;
        payment3.Amount_To_Apply__c = suppPayList[2].Payment_Amount__c;
        paymentList.add(payment3);
        
        insert paymentList;
        
        for(Supplier_Payment__c sp : suppPayList){
            sp.Finalized__c = true;
        }
        
        update suppPayList;
        
        Apexpages.Standardcontroller stdcon = new Apexpages.Standardcontroller(data.company);
        GenerateAccountingBatchExt GABC = new GenerateAccountingBatchExt(stdcon);
        GABC.generateSupplierPaymentAccounting();
        test.stopTest();
            
        List<Supplier_Payment__c> SuppPaymentsAfter = [Select id, Name, (Select id, Name from Accounting_Entries__r where void__c = false) from Supplier_Payment__c where id in :SuppPayIds];
        /* TODO: fix me at the end of KNDY - 3369
        for(integer i=0;i<SuppPaymentsAfter.size(); i++){
            system.assertNotEquals(0,SuppPaymentsAfter[i].Accounting_Entries__r.size());
        }
        
      
    }
    */
}