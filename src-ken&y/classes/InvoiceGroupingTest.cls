@isTest
private class InvoiceGroupingTest {
// Retrofitted test methods have been moved to InvoiceGroupingRulesExtTest
// as this method fails with Too many soqls after converting to TestFuelQuery.
       static testMethod void InvoiceGrouping_VoidCancel() { //DONE
        Testfuel fuel = new Testfuel();
        Date dtNow = system.now().date();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(dtNow.addMonths(-6), Time.newInstance(0,0,0,0)),  rank__c = 1, Billing_UOM__c = fuel.CALENDAR_QUARTER.ID, Recurrence_Start_Date__c = DateTime.newInstance(Date.newInstance(2015,1,10), Time.newInstance(0,0,0,0)),
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);

        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
       // system.assertEquals(DateTime.newInstance(2015,5,30,0,0,0), igr.next_Invoice_Date__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
        	sol.Start_Date__c = DateTime.newInstance(Date.newInstance(2015,1,1), Time.newInstance(0,0,0,0));
        	sol.End_Date__c = DateTime.newInstance(Date.newInstance(2015,9,1), Time.newInstance(0,0,0,0));
        	sol.Rate_Basis__c = 'Quantity';
        	
        }
        update lSOLs;
        
        Fulfillment__c f = new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Currency__c = TestFuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                             type__c='Recurring', Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c ='Recurring', Status__c = 'Complete', Pricing_UOM__c = fuel.CALENDAR_MONTH.Id);

        insert f;
        
        
        test.startTest();
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c, Invoice_Type__c, Finalized__c, Date_Invoiced__c, Planned_Invoice_Date__c, (Select ID from Customer_Invoice_Lines__r ) from Customer_Invoice__c order by Planned_Invoice_Date__c desc];
        system.assertEquals(4,lCIs.size(), lCIs);

            Fulfillment__c changedfulFilment1 = [select id,last_bill_Date__c from Fulfillment__c where id = :f.id];
            system.debug('****changedfulFilment1.last_bill_Date__c= ' + changedfulFilment1.last_bill_Date__c  + ' ic1 ' +lCIs[1].Planned_Invoice_Date__c + ' ic0 ' + lCIs[0].Planned_Invoice_Date__c );
        
            Customer_invoice__c CI = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c from Customer_Invoice__c where id = :lCIs[0].id limit 1 ];
            CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CI));
            system.assert(!ext.getDisableCancel() == true, ext.getVoidCancelDetails()+' '+lCIs);
            
            ext.cancelDocs();
            Customer_Invoice__c CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c from Customer_Invoice__c where id = :CI.Id limit 1 ];
            system.assertEquals( 'Cancelled',CustomerInvoice.Status__c);
        
            Fulfillment__c changedfulFilment = [select id,last_bill_Date__c from Fulfillment__c where id = :f.id];
            system.debug('###changedfulFilment.last_bill_Date__c ' + changedfulFilment.last_bill_Date__c);
        
        Customer_Invoice_Line__c[] cils=[Select ID, End_Date__c from Customer_Invoice_Line__c where Customer_Invoice__c = :lCIs[1].id order by End_Date__c desc];
            system.assertEquals(changedfulFilment.last_bill_Date__c, cils[0].End_Date__c);
   
                        
    }

    static testMethod void InvoiceGrouping_AggregateCI_DependsonCurrencyonFulfmt() { //DONE
        Testfuel fuel = new Testfuel();
        
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c, Currency__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = TestFuel.currencyCAD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        
        insert lFs;
        
        
        test.startTest();
            Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Invoice_Type__c, Finalized__c, Date_Invoiced__c,Currency__r.Name, (Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(1,lCIs.size());
        for(Customer_Invoice__c ci : lCIs) {
            system.assertEquals(true, ci.Finalized__c);
            system.assertEquals('CAD', ci.Currency__r.Name);
        }
                
                        

    }
    
        static testMethod void InvoiceGrouping_PartialCIFinalize() { //KNDY-15144
        TestFuel fuel = new TestFuel();
        test.startTest();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        // SO1 = fuel.salesOrder
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c, 
        Pricebook__c,Company__c ,Description__c ,Discount_Percent__c,
        Quantity_Ordered__c ,Required_Date__c,Sales_Order__c,
        Ship_From_Location__c ,Unit_Price__c 
        from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        system.assertEquals(2,lSOLs.size());
        
        // SO2
        Sales_Order__c so2 = fuel.salesOrder.clone();
        insert so2;
        List<Sales_Order_Line__c> so2Lines= new List<Sales_Order_Line__c>();
        for (Sales_Order_Line__c sol: lSOLs){
            Sales_Order_Line__c sol2 = sol.clone();
            sol2.Sales_Order__c = so2.Id;
            so2Lines.add(sol2);
        }
        insert so2Lines;
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        //Fulfillments for SO1
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 4, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,7,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 5, Product__c = lSOLs[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        // Fulfillment for SO2, quantity totalling 0
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = so2Lines[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = so2Lines[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = so2Lines[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = -1, Product__c = so2Lines[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,7,20,0,0,0), Currency__c = fuel.company.Default_Transaction_Currency__c, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = so2Lines[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c =-2, Product__c = so2Lines[0].Product__c, Price_Type__c ='Sales', Status__c = 'Complete'));
        insert lFs;
        
        Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        
        list<Customer_Invoice__c> lCIs = [Select id, Invoice_Type__c, Sales_Order__c, Finalized__c, Date_Invoiced__c,(Select id from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        system.assertEquals(2,lCIs.size());
        Integer finalizedCIct = 0;
        Integer unfinalizedCIct = 0;
        for(Customer_Invoice__c ci : lCIs) {
            if (ci.Finalized__c == true){
                finalizedCIct ++;
                system.assertEquals(ci.Sales_Order__c, fuel.salesOrder.Id, '>>> ci: ' + ci);
            }
            else{
                unfinalizedCIct ++;
                system.assertEquals(ci.Sales_Order__c, so2.Id, '>>> ci: ' + ci);
            }
        }
        system.assertEquals(finalizedCIct, 1, '>>> lCIs: ' + lCIs);
        system.assertEquals(unfinalizedCIct, 1, '>>> lCIs: ' + lCIs);
        list<Customer_Invoice_Sub_Line__c> subLines = [Select id from Customer_Invoice_Sub_Line__c where Fulfillment__c in :lFs];
        system.assertEquals(6,subLines.size());
    }
    

    static testMethod void InvoiceGrouping_DontRemoveHeaders() {
    	
    	 Testfuel fuel = new Testfuel();
        
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),  rank__c = 1, 
                                                                    Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = fuel.company.Id, Use_Billing_Frequency_on_Fulfillment__c = true);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c, Currency__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = TestFuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c, Price_Type__c ='Recurring', Status__c = 'Complete', 
                                   Start_Date__c = DateTime.newInstance(Date.newInstance(2014,1,1), Time.newInstance(0,0,0,0)), End_Date__c = DateTime.newInstance(Date.newInstance(2014,1,29), Time.newInstance(0,0,0,0)),
                                   Pricing_UOM__c = fuel.WEEK.Id, Billing_UOM__c = fuel.WEEK.Id, Recurrence_Start_Date__c = DateTime.newInstance(Date.newInstance(2014,1,1), Time.newInstance(0,0,0,0))
                                   )); //F-1
       lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = TestFuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[1].Product__c, Price_Type__c ='Recurring', Status__c = 'Complete', 
                                   Start_Date__c = DateTime.newInstance(Date.newInstance(2014,1,1), Time.newInstance(0,0,0,0)), End_Date__c = DateTime.newInstance(Date.newInstance(2014,1,29), Time.newInstance(0,0,0,0)),
                                   Pricing_UOM__c = fuel.RENTAL_MONTH.Id, Billing_UOM__c = fuel.WEEK.Id, Recurrence_Start_Date__c = DateTime.newInstance(Date.newInstance(2014,1,1), Time.newInstance(0,0,0,0))
                                   )); //F-2
        
        insert lFs;
        
        test.startTest();
            Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        test.StopTest();
        list<Customer_Invoice__c> lCIs = [Select id, Invoice_Type__c, Finalized__c, Date_Invoiced__c,Currency__r.Name, (Select id, Start_Date__c, End_Date__c from Customer_Invoice_Lines__r) from Customer_Invoice__c order by Planned_Invoice_Date__c];
        system.assertEquals(4,lCIs.size());
        
        system.assertEquals(1,lCIs[0].Customer_Invoice_Lines__r.size()); //CI-1 with F-1
        system.assertEquals(1,lCIs[1].Customer_Invoice_Lines__r.size());//CI-1 with F-1
        system.assertEquals(1,lCIs[2].Customer_Invoice_Lines__r.size());//CI-1 with F-1
        system.assertEquals(2,lCIs[3].Customer_Invoice_Lines__r.size(), lCIs[3].Customer_Invoice_Lines__r);
        
        
    	
    }
}