@isTest
private class CustomerReceiptAccountingExtTest {

	@testSetup static void ts() { 
		TestFuel data = new TestFuel();	
		// these asserts cause TestFuelQuery to insert data
		system.assert(		
			data.company != null &&
			data.customerSoldTo != null &&
			data.customerBillTo != null &&
			data.customerParent != null &&
			data.product_Misc != null &&
			data.product != null &&
			data.periodList != null &&
			data.salesOrder != null &&
			data.salesOrderLines != null
						
		);
		system.assert(data.paymentProfile != null &&
			data.paymentMethod != null &&
			data.custInv1 != null &&
			data.bankAccount != null);
	}
        
   public class custReceiptData{
        TestFuelQuery data = new TestFuelQuery();
   	
        //GenerateAccountingService GAS = new GenerateAccountingService(); 
        CustomerReceiptAccounting cra = new CustomerReceiptAccounting();
        List<Customer_Invoice__c> custInvoiceList = new List<Customer_Invoice__c>();{
            Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
            custInvoice1.Company__c = data.company.id;
            //Added Bill To for field filters
		    custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
            custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
            custInvoice1.Sales_Order__c = data.salesOrder.Id;
            custInvoice1.Date_Invoiced__c = System.now();
            custInvoice1.Transaction_Date__c = System.now();
            custInvoice1.status__c = 'Open';
            //custInvoice1.Subtotal__c = 0;
            custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
           	custInvoice1.Invoice_Type__c = 'Adjustment';
            custInvoiceList.add(custInvoice1);
            
            Customer_Invoice__c custInvoice2 = new Customer_Invoice__c();
            custInvoice2.Company__c = data.company.id;
            //Added Bill To for field filters
		    custInvoice2.Bill_To_Customer__c = data.customerbillto.id;
            custInvoice2.Sold_To_Customer__c = data.customerSoldTo.id;
            custInvoice2.Sales_Order__c = data.salesOrder.Id;
            custInvoice2.Date_Invoiced__c = System.now();
            custInvoice2.Transaction_Date__c = System.now();
            custInvoice2.status__c = 'Open';
            //.Subtotal__c = 0;
            custInvoice2.Currency__c = data.company.Default_Transaction_Currency__c;
            custInvoice2.Invoice_Type__c = 'Adjustment';
            
            custInvoiceList.add(custInvoice2);
            
            insert custInvoiceList;
        }
        
        List<Customer_Invoice_Line__c> shipInvList = new List<Customer_Invoice_Line__c>();{
        Customer_Invoice_Line__c shipmentObj1 = new Customer_Invoice_Line__c();
            shipmentObj1.Quantity_Shipped__c = 5;
            //shipmentObj1.Sales_Order_Line__c = data.salesOrderLines[0].id;
            shipmentObj1.Unit_Price__c = 30;
            //shipmentObj1.Sales_Order__c = data.salesOrder.id;
            shipmentObj1.Product__c = data.product.id ;
            shipmentObj1.Discount_Percent__c = data.salesOrderLine.Discount_Percent__c;
            shipmentObj1.Customer_Invoice__c = custInvoiceList[0].Id; 
            
        shipInvList.add(shipmentObj1);
        
        Customer_Invoice_Line__c shipmentObj2 = new Customer_Invoice_Line__c();
            shipmentObj2.Quantity_Shipped__c = 5;
            //shipmentObj2.Sales_Order_Line__c = data.salesOrderLines[2].id;
            shipmentObj2.Unit_Price__c = 30;
            //shipmentObj2.Sales_Order__c = data.salesOrder2.id;
            shipmentObj2.Product__c = data.product.id ; 
            shipmentObj2.Discount_Percent__c = data.salesOrderLine2.Discount_Percent__c;
            shipmentObj2.Customer_Invoice__c = custInvoiceList[1].Id; 
            
        shipInvList.add(shipmentObj2);     
        insert shipInvList;           
        
        custInvoiceList[0].finalized__c = true;
        custInvoiceList[1].finalized__c = true;
        update custInvoiceList;         
        }
        
        List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();{
        
        Customer_Receipt__c custReceipt1 = new Customer_Receipt__c();
            //custReceipt1.Amount_Received__c = 100;
            custReceipt1.Amount_Unapplied__c = 10;
            custReceipt1.Company__c = data.company.Id;
            //custReceipt1.Bank_Account__c = data.bankAccount.id;
            custReceipt1.Customer__c = data.customerbillto.Id;
            custReceipt1.Date_Received__c = system.now();
            custReceipt1.Currency__c = data.company.Default_Transaction_Currency__c;
            custReceipt1.exception__c = false;
          	custReceipt1.transaction_date__c = system.now();
           	
        custReceiptList.add(custReceipt1);    
        
        Customer_Receipt__c custReceipt2 = new Customer_Receipt__c();
            //custReceipt2.Amount_Received__c = 100;
            custReceipt2.Amount_Unapplied__c = 17;
            custReceipt2.Company__c = data.company.Id;
            //custReceipt2.Bank_Account__c = data.bankAccount.id;
            custReceipt2.Customer__c = data.customerbillto.Id;
            custReceipt2.Date_Received__c = system.now();
            custReceipt2.Currency__c = data.company.Default_Transaction_Currency__c;
            custReceipt2.exception__c = false;
            
        custReceiptList.add(custReceipt2);
        
        insert custReceiptList;     
        
        }
        
          
       Reason_Code__c deductionCode = new Reason_Code__c();{
         deductionCode.Type__c = 'Deductions';  
         deductionCode.Code__c = 'D001';
         insert deductionCode;
       }
        List<Customer_Receipt_Line__c> paymentList = new List<Customer_Receipt_Line__c>();{
        Customer_Receipt_Line__c payment1 = new Customer_Receipt_Line__c();
            payment1.Amount__c = 100;
            payment1.Type__c = 'Payment';
            payment1.Customer_Receipt__c = custReceiptList[0].id;
            payment1.Customer_Invoice__c = custInvoiceList[0].id;
            payment1.Currency__c = data.company.Default_Transaction_Currency__c;
            payment1.line_Number__c ='1';
        
        paymentList.add(payment1);    
        
        Customer_Receipt_Line__c payment2 = new Customer_Receipt_Line__c();
            payment2.Amount__c = 100;
            payment2.Type__c = 'Payment';
            payment2.Customer_Receipt__c = custReceiptList[1].id;
            payment2.Customer_Invoice__c = custInvoiceList[1].id;
            payment2.Currency__c = data.company.Default_Transaction_Currency__c;
            payment2.line_Number__c ='1';
        
        paymentList.add(payment2);
        
        Customer_Receipt_Line__c payment3 = new Customer_Receipt_Line__c();
            payment3.Amount__c = 10;
            payment3.Type__c = 'Write Off';
            payment3.Customer_Receipt__c = custReceiptList[0].id;
            payment3.Customer_Invoice__c = custInvoiceList[0].id;
            payment3.Currency__c = data.company.Default_Transaction_Currency__c;
            payment3.line_Number__c ='2';
        
        paymentList.add(payment3);
        
        Customer_Receipt_Line__c payment4 = new Customer_Receipt_Line__c();
            payment4.Amount__c = 10;
            payment4.Type__c = 'Deduction';
            payment4.Customer_Receipt__c = custReceiptList[1].id;
            payment4.Customer_Invoice__c = custInvoiceList[1].id;
            payment4.Currency__c = data.company.Default_Transaction_Currency__c;
            payment4.line_Number__c ='2';
        
        paymentList.add(payment4);
        
        Customer_Receipt_Line__c payment5 = new Customer_Receipt_Line__c();
            payment5.Amount__c = 5;
            payment5.Type__c = 'Earned Terms Discount';
            payment5.Customer_Receipt__c = custReceiptList[1].id;
            payment5.Customer_Invoice__c = custInvoiceList[1].id;
            payment5.Currency__c = data.company.Default_Transaction_Currency__c;
            payment5.line_Number__c ='3';
        
        paymentList.add(payment5);
        
        Customer_Receipt_Line__c payment6 = new Customer_Receipt_Line__c();
            payment6.Amount__c = 1;
            payment6.Type__c = 'Unearned Terms Discount';
            payment6.Customer_Receipt__c = custReceiptList[1].id;
            payment6.Customer_Invoice__c = custInvoiceList[1].id;
            payment6.Currency__c = data.company.Default_Transaction_Currency__c;
            payment6.line_Number__c ='4';
        paymentList.add(payment6);
        
         Customer_Receipt_Line__c payment7 = new Customer_Receipt_Line__c();
            payment7.Amount__c = 1;
            payment7.Type__c = 'Write Off';
            payment7.Customer_Receipt__c = custReceiptList[1].id;
            payment7.Customer_Invoice__c = custInvoiceList[1].id;
            payment7.Currency__c = data.company.Default_Transaction_Currency__c;
            payment7.line_Number__c ='5';
        paymentList.add(payment7);
          
          
          Customer_Receipt_Line__c genDeduction1 = new Customer_Receipt_Line__c();
    	genDeduction1.Amount__c = 100;
    	genDeduction1.Type__c = PaymentService.TYPE_GEN_DED;
        genDeduction1.Reason_Code__c = deductionCode.Id;
    	genDeduction1.Customer_Receipt__c = custReceiptList[0].Id;
    	paymentList.add(genDeduction1);
    	
    	Customer_Receipt_Line__c genDeduction2 = new Customer_Receipt_Line__c();
    	genDeduction2.Amount__c = 100;
    	genDeduction2.Type__c = PaymentService.TYPE_GEN_DED;
        genDeduction2.Reason_Code__c = deductionCode.Id;
    	genDeduction2.Customer_Receipt__c = custReceiptList[1].Id;
    	paymentList.add(genDeduction2);          
        insert paymentList;
        
        custReceiptList[0].Finalized__c = true;
        custReceiptList[0].finalized_date__c = system.now();
        custReceiptList[0].Amount_Unapplied__c = 0;
        custReceiptList[1].Finalized__c = true;
        custReceiptList[1].finalized_date__c = system.now();
        custReceiptList[1].Amount_Unapplied__c = 0;
        
        update custReceiptList;
        }
        
        Set<Id> receiptIds = new Set<Id>();
        {
            for(Customer_Receipt__c receipt: custReceiptList){
                receiptIds.add(receipt.id);
            }
        }
        
    }
    
    static testMethod void myUnitTest1() {
        
        CustomerReceiptAccountingExt GAEC;
        custReceiptData custRcptData = new custReceiptData();
       Test.startTest();
        
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(custRcptData.custReceiptList);
        setcon.setSelected(custRcptData.custReceiptList);
        GAEC = new CustomerReceiptAccountingExt(setcon);
       
        GAEC.GenerateCustomerReceiptAccounting() ;
        Test.stopTest();
        List<Accounting_Entry__c> acctEntryList = [Select id, Name, Customer_Receipt__c
                                                    from Accounting_Entry__c
                                                    where Customer_Receipt__c in :custRcptData.receiptIds]; 
        system.assertNotEquals(null,acctEntryList);
        List<Customer_Receipt__c> ReceiptsAfter = [Select id, Name, (Select id, Name from accounting_entries__r where void__c = false)from Customer_Receipt__c where id in :custRcptData.receiptIds]; 
        
        for(integer i=0;i<ReceiptsAfter.size(); i++){
            system.assertNotEquals(0, ReceiptsAfter[i].Accounting_Entries__r.size());
        }
   
    }
    
 /*   static testMethod void myUnitTest2() {
        CustomerReceiptAccountingExt GAEC;
        custReceiptData custRcptData = new custReceiptData();
        custRcptData.custReceiptList[0].Date_Received__c = null;
        update custRcptData.custReceiptList[0];
        Test.startTest();
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(custRcptData.custReceiptList);
        
        setcon.setSelected(custRcptData.custReceiptList);
        GAEC = new CustomerReceiptAccountingExt(setcon);
       
        GAEC.GenerateCustomerReceiptAccounting() ;
        Test.stopTest();

        system.assertEquals(true,GAEC.requiredFielderror );
    }
    
    static testMethod void myUnitTest3() {
        CustomerReceiptAccountingExt GAEC;
        custReceiptData custRcptData = new custReceiptData();
        custRcptData.custReceiptList[0].Company__c = null;
        update custRcptData.custReceiptList[0];
        Test.startTest();
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(custRcptData.custReceiptList);
        
        setcon.setSelected(custRcptData.custReceiptList);
        GAEC = new CustomerReceiptAccountingExt(setcon);
       
        GAEC.GenerateCustomerReceiptAccounting() ;
        Test.stopTest();

        system.assertEquals(true,GAEC.requiredFielderror );
    }
    
    static testMethod void myUnitTest4() {
        CustomerReceiptAccountingExt GAEC;
        custReceiptData custRcptData = new custReceiptData();
        custRcptData.custReceiptList[0].Currency__c = null;
        update custRcptData.custReceiptList[0];
        Test.startTest();
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(custRcptData.custReceiptList);
        
        setcon.setSelected(custRcptData.custReceiptList);
        GAEC = new CustomerReceiptAccountingExt(setcon);
       
        GAEC.GenerateCustomerReceiptAccounting() ;
        Test.stopTest();

        system.assertEquals(true,GAEC.requiredFielderror );
    }*/
}