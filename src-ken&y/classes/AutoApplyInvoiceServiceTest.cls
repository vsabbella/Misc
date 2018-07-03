@isTest
public class AutoApplyInvoiceServiceTest {
	
	static testMethod void applyOnePrepaymentToOneSO() {
		TestFuel fuel = new TestFuel();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		Sales_Order__c salesOrder = new Sales_Order__c(
                Company__c = fuel.company.id,
                Customer__c = fuel.customerSoldTo.id,
                Ship_To__c = fuel.customerShipTo.Id,
                Payment_Term__c = fuel.terms.id,
                Currency__c = fuel.company.Default_Transaction_Currency__c
            );
		salesOrder.Ship_to__c = fuel.customerShipTo.Id;
		salesOrder.Bill_To__c = fuel.customerBillTo.Id;
		salesOrder.Currency__c = TestFuel.currencyUSD.id;
		salesOrder.Original_Sales_Order__c = 'so123'; 
		insert salesOrder;
		
		Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Company__c = fuel.company.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Quantity_Ordered__c = 10;
        salesOrderLine.Required_Date__c = System.today()+5;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
        //salesOrderLine.Unit_Price__c = 20;
        salesOrderLine.Memo__c = 'salesOrderLine';
		insert salesOrderLine;
		
		Sales_Order_Line__c checkSOL = [SELECT Id, has_exceptions__c, Unit_Price__c, Extended_Price__c, (SELECT Id, subject FROM OpenActivities) FROM Sales_Order_Line__c WHERE ID = :salesOrderLine.Id];
		system.assert(!checkSOL.has_exceptions__c, [SELECT Id, whatId, Subject FROM Task WHERE whatId = :checkSOL.Id]);
		
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Amount_Received__c = 1;
		custReceipt.Bank_Account_2__c =  fuel.bankAccount.Id;
		custReceipt.Currency__c = TestFuel.currencyUSD.id;
		custReceipt.Payment_Method_G__c = 'Cash';
        custReceipt.Reference_Number__c = '123';
		insert custReceipt; 
		
		Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();

		additionalPayment.Amount__c = 1;
		additionalPayment.Customer__c = fuel.customerBillTo.Id;

		additionalPayment.Customer_Receipt__c = custReceipt.Id;
		additionalPayment.Type__c = PaymentService.TYPE_PREPAYMENT;
		additionalPayment.Sales_Order__c = salesOrder.Id;
		insert additionalPayment;
		
		
		custReceipt.Finalized__c = true;
		update custReceipt;
		
		custReceipt = [select id, finalized__c, Amount_Received__c from Customer_Receipt__c where id = :custReceipt.Id limit 1];
		system.assertEquals(true, custReceipt.finalized__c);
		
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = TestFuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = salesOrderLine.Id,
                                   Name = 'F1', Status__c = 'Complete', Invoice_Ready__c = true, Unit_Price__c = salesOrderLine.Unit_Price__c, Quantity__c = salesOrderLine.Quantity_Ordered__c, Product__c = salesOrderLine.Product__c));
        
        insert lFs;
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, 
                                            Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c,Invoice_Type__c, Finalized__c, Date_Invoiced__c, Sales_Order__c, Balance__c, (Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c order by Id ASC];
        system.assertEquals(1,lCIs.size(), lCIs);
        
		test.startTest();
			Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        lCIs = [Select id, Batch_Job_ID__c,Invoice_Type__c, Finalized__c, Date_Invoiced__c, Sales_Order__c, Balance__c, (Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c order by Id ASC];
        system.assertEquals(2,lCIs.size(), lCIs);
        system.debug('lCIs '+lCIs);
        system.assertEquals('Prepayment',lCIs[0].Invoice_Type__c);
        system.assertEquals('Standard',lCIs[1].Invoice_Type__c);
        system.assertEquals(0,lCIs[0].Balance__c,lCIs[0]);
        system.assertEquals(checkSOL.Extended_Price__c - custReceipt.Amount_Received__c,lCIs[1].Balance__c,lCIs[1]);
        
		
	}
	
	static testMethod void applyTwoPrepaymentToOneSO() {
		TestFuel fuel = new TestFuel();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		Sales_Order__c salesOrder = new Sales_Order__c(
                Company__c = fuel.company.id,
                Customer__c = fuel.customerSoldTo.id,
                Ship_To__c = fuel.customerShipTo.Id,
                Payment_Term__c = fuel.terms.id,
                Currency__c = fuel.company.Default_Transaction_Currency__c
            );
		salesOrder.Ship_to__c = fuel.customerShipTo.Id;
		salesOrder.Bill_To__c = fuel.customerBillTo.Id;
		salesOrder.Currency__c = TestFuel.currencyUSD.id;
		salesOrder.Original_Sales_Order__c = 'so123'; 
		insert salesOrder;
		
		Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Company__c = fuel.company.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Quantity_Ordered__c = 10;
        salesOrderLine.Required_Date__c = System.today()+5;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
        //salesOrderLine.Unit_Price__c = 20;
        salesOrderLine.Memo__c = 'salesOrderLine';
		insert salesOrderLine;
		
		Sales_Order_Line__c checkSOL = [SELECT Id, has_exceptions__c, Unit_Price__c, Extended_Price__c, (SELECT Id, subject FROM OpenActivities) FROM Sales_Order_Line__c WHERE ID = :salesOrderLine.Id];
		system.assert(!checkSOL.has_exceptions__c, [SELECT Id, whatId, Subject FROM Task WHERE whatId = :checkSOL.Id]);
		
		
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = TestFuel.currencyUSD.id;
		custReceipt.Amount_Received__c = 2;
		custReceipt.Bank_Account_2__c =  fuel.bankAccount.Id;
		custReceipt.Payment_Method_G__c = 'Cash';
        custReceipt.Reference_Number__c = '123';
		insert custReceipt; 
		
		Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();

		additionalPayment.Amount__c = 1;
		additionalPayment.Customer__c = fuel.customerBillTo.Id;

		additionalPayment.Customer_Receipt__c = custReceipt.Id;
		additionalPayment.Type__c = PaymentService.TYPE_PREPAYMENT;
		additionalPayment.Sales_Order__c = salesOrder.Id;
		insert additionalPayment;
		
		Customer_Receipt_Line__c additionalPayment1 = new Customer_Receipt_Line__c();

		additionalPayment1.Amount__c = 1;
		additionalPayment1.Customer__c = fuel.customerBillTo.Id;

		additionalPayment1.Customer_Receipt__c = custReceipt.Id;
		additionalPayment1.Type__c = PaymentService.TYPE_PREPAYMENT;
		additionalPayment1.Sales_Order__c = salesOrder.Id;
		insert additionalPayment1;
		
		
		custReceipt.Finalized__c = true;
		update custReceipt;
		
		custReceipt = [select id, finalized__c, Amount_Received__c from Customer_Receipt__c where id = :custReceipt.Id limit 1];
		system.assertEquals(true, custReceipt.finalized__c);
		
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = TestFuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = salesOrderLine.Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = salesOrderLine.Unit_Price__c, Quantity__c = salesOrderLine.Quantity_Ordered__c, Product__c = salesOrderLine.Product__c, Status__c = 'Complete'));
        
        insert lFs;
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, 
                                            Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        
		test.startTest();
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c,Invoice_Type__c, Finalized__c, Date_Invoiced__c, Sales_Order__c, Balance__c, (Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c order by Id ASC];
        system.assertEquals(3,lCIs.size(), lCIs);
        system.debug('lCIs '+lCIs);
        system.assertEquals('Prepayment',lCIs[0].Invoice_Type__c);
        system.assertEquals('Prepayment',lCIs[1].Invoice_Type__c);
        system.assertEquals('Standard',lCIs[2].Invoice_Type__c);
        system.assert(lCIs[0].Balance__c == 0 || lCIs[0].Balance__c == -50,lCIs);
        system.assert(lCIs[0].Balance__c == 0 || lCIs[0].Balance__c == -50,lCIs);
        system.assertEquals(checkSOL.Extended_Price__c - custReceipt.Amount_Received__c,lCIs[2].Balance__c,lCIs);
	}

}