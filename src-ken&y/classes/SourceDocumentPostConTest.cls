@isTest
public with sharing class SourceDocumentPostConTest {
 
    public class SampleData{
        
        public TestFuel fuel = new TestFuel();
       // public TestData.Accounting accting = new TestData.Accounting(fuel.company.Id);
        public Period__c p1, p2, p3;
        public list<Period__c> currentYearPeriodList = fuel.periodList;
        public SampleData(){
        	getCurrentPeriod();
            updatePeriod_SLCSuccess();
        }
        
        Datetime currDatetime = system.now();
        public Period__c currentPeriod = new Period__c();
        public Period__c priorPeriod = new Period__c();
       
       	{
        	currentYearPeriodList = [Select id, Name, period_start__c, period_end__c, prior_period__c
        							from Period__c
      								where id in :currentYearPeriodList];
        }
        
        public Period__c getCurrentPeriod (){
        	system.debug(logginglevel.info,'currentYearPeriodList:'+currentYearPeriodList);
        	system.debug(logginglevel.info,'currDatetime:'+currDatetime);
        	for(Period__c thisPeriod: currentYearPeriodList){
        		if(currDatetime >= thisPeriod.Period_Start__c && currDatetime < thisPeriod.Period_End__c ){
        			currentPeriod = thisPeriod;
        		}
        	}
        	if(currentPeriod.prior_period__c != null){
        		priorPeriod = new Period__c(id = currentPeriod.prior_period__c);}
       		else{
       			priorPeriod = fuel.periodListLastYear[fuel.periodListLastYear.size() - 1];}
        	return currentPeriod;
        }
        
        public void updatePeriod_SLCSuccess(){ 
            List<Period__c> periodListLastYear = fuel.periodListLastYear;
            p1 = periodListLastYear[0];
            p1.Open__c = true;
            update p1;
        }
        
    }
    
    static testMethod void testAR(){
        SampleData sd = new SampleData();
        sd.p1.Open__c = false;
        update sd.p1;
        
        List<Accounting_Rule__c>ciAcctRules = sd.fuel.ciAccountingRuleList;
        Test.startTest();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.priorPeriod);
        pageReference pr = page.SourceDocumentPost;
        Test.setCurrentPage(pr);
        SourceDocumentPostCon ext = new SourceDocumentPostCon(con);
        
        system.assert(ext.blockpost == true, 'sd.p1:'+ sd.p1);
        
        sd.p1.type__c = null;
        sd.p1.Open__c = true;
        update sd.p1;
        
        con = new Apexpages.Standardcontroller(sd.priorPeriod);
        pr = page.SourceDocumentPost;
        Test.setCurrentPage(pr);
        ext = new SourceDocumentPostCon(con);
        
        system.assert(ext.blockpost == true, 'sd.p1:'+ sd.p1);
        
        sd.p1.type__c = 'Fiscal';
        update sd.p1;
        
        con = new Apexpages.Standardcontroller(sd.priorPeriod);
        pr = page.SourceDocumentPost;
        Test.setCurrentPage(pr);
        ext = new SourceDocumentPostCon(con);
        
        ext.selectedSourceDocument = 'Customer_Invoice__c';
        
        system.assert(true,ext.blockPost);
        system.assert(sd.currentYearPeriodList != null,'sd.currentYearPeriodList:'+sd.currentYearPeriodList);
        system.assert(sd.currDatetime != null,'sd.currDatetime:'+sd.currDatetime);
        system.assert(sd.currentPeriod != null,'sd.currentPeriod:'+sd.currentPeriod);
        	
        Period__c currentPeriod = [Select id, Name, Prior_Period__c, period_start__c , period_end__c
        				from Period__c
        				where id = :sd.currentPeriod.id];
        
        Sales_Order__c so = sd.fuel.salesOrder;
        
        Customer_Invoice__c ci = new Customer_Invoice__c();
        ci.Status__c = 'Open';
        ci.Sold_to_Customer__c = sd.fuel.customerSoldTo.Id;
        ci.Invoice_Type__c = 'Ship Invoice';
        ci.Currency__c = so.Currency__c;
        ci.Transaction_Date__c = currentPeriod.Period_start__c.addSeconds(-1);
        ci.Date_Invoiced__c = currentPeriod.Period_start__c.addSeconds(-1);
        ci.Company__c = sd.fuel.company.Id;
        ci.Bill_to_Customer__c = so.Bill_to__c;
        ci.Customer__c = sd.fuel.customerParent.Id;
        
        insert ci;
        
        List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        for(Sales_Order_Line__c sol : sd.fuel.salesOrderLines){
            Customer_Invoice_Line__c iCIL = new Customer_Invoice_Line__c();
            iCIL.Company__c = so.Company__c;
            iCIL.Customer_Invoice__c = ci.id;
			iCIL.Product__c = sd.fuel.product.Id;
			iCIL.Sales_Order__c = so.Id;
			iCIL.Sales_Order_Line__c = sol.Id;
            iCIL.Unit_Price__c = sol.Unit_Price__c;
            iCIL.Quantity_Shipped__c = sol.Quantity_Ordered__c;
            iCIL.Discount_Percent__c = sol.Discount_Percent__c; 
            iCIL.Line_Type__c = sol.Line_Type__c;
            iCIL.Extended_Price__c = sol.Unit_Price__c *  sol.Quantity_Ordered__c;
            iCIL.Quantity_From_Stock__c = sol.Quantity_From_Stock__c;
            cils.add(iCIL);
        }
        
        insert cils;
        
        ci.finalized__c = true;
        update ci;
        
        CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
        cia.execute(cils);
        Test.stopTest();
        
        ext = new SourceDocumentPostCon(con);
        ext.selectedSourceDocument = 'Customer_Invoice__c';
        ext.updateGrid();
        
        ci = [Select id, Name, finalized__c, transaction_date__c, finalized_date__c, posting_date__c,
        		(Select id, Name, Status__c, has_exceptions__c from Accounting_Entries__r)
        		from Customer_Invoice__c
        		where id = :ci.id];
        		
        system.assert(ci.finalized_date__c == ci.posting_date__c,'ci:'+ci);
       	system.assert(ext.sourceDocs[0].sObj.id == ci.id,'ci:'+ci);
       	
       	system.assert(ci.Accounting_entries__r.size() == 1);
       	system.assert(ci.Accounting_entries__r[0].status__c == 'Active');
       	
       	ext.sourceDocs[0].selected = true;
        ext.assign();
        ci = [Select id, Name, finalized__c, transaction_date__c, finalized_date__c, posting_date__c,
        		(Select id, Name, Status__c, has_exceptions__c from Accounting_Entries__r)
        		from Customer_Invoice__c
        		where id = :ci.id];
        system.assert(ci.finalized_date__c != ci.posting_date__c,'ci:'+ci);
        system.assert(ci.Accounting_entries__r.size() == 1);
       	system.assert(ci.Accounting_entries__r[0].status__c == 'Obsolete');
        
        ext.first();
        ext.last();
        ext.next();
        ext.previous();
        
    }
    
    static testMethod void testAP(){
        SampleData sd = new SampleData();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.priorPeriod);
        pageReference pr = page.SourceDocumentPost;
        Test.setCurrentPage(pr);
        SourceDocumentPostCon ext = new SourceDocumentPostCon(con);
        
        ext.selectedSourceDocument = 'Supplier_Invoice__c';
        
        system.assert(true,ext.blockPost);
        system.assert(sd.currentYearPeriodList != null,'sd.currentYearPeriodList:'+sd.currentYearPeriodList);
        system.assert(sd.currDatetime != null,'sd.currDatetime:'+sd.currDatetime);
        system.assert(sd.currentPeriod != null,'sd.currentPeriod:'+sd.currentPeriod);
        	
        Period__c currentPeriod = [Select id, Name, Prior_Period__c, period_start__c , period_end__c
        				from Period__c
        				where id = :sd.currentPeriod.id];
 
        Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();
        suppInv1.Company__c = sd.fuel.company.id;
        suppInv1.Invoice_Type__c = 'Invoice';
        suppInv1.Date_Invoiced__c = currentPeriod.Period_start__c.addSeconds(-1);
        suppInv1.Currency__c = TestFuel.currencyUSD.id;
        suppInv1.Transaction_Date__c = currentPeriod.Period_start__c.addSeconds(-1);
        suppInv1.Supplier__c = sd.fuel.remittosupplier.id;
        suppInv1.Invoice_Amount__c = 100;
        suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
        suppInv1.historical__c = false;
      	
      	insert suppInv1;
      	
      	Item__c item = sd.fuel.itemList[0];
      	item.source__c = 'Miscellaneous';
      	item.Non_Inventory__c = true;
      	update item;
      	
      	Supplier_Invoice_Line__c SuppInvLine1 = new Supplier_Invoice_Line__c(); 
        suppInvLine1.Supplier_Invoice__c = suppInv1.id;
        suppInvLine1.Invoice_Quantity__c = 10;
        suppInvLine1.Unit_Price__c = 10;//KNDY-14371
        suppInvLine1.Item__c = item.id;
      	
      	insert SuppInvLine1;
      	
      	suppInv1.finalized__c = true;
        suppInv1.Status__c = 'Closed';
      	update suppInv1;
      	
        Supplier_Invoice__c si = [Select Id, Status__C from Supplier_Invoice__c];
        system.assertEquals('Closed', si.Status__c);
      	ext = new SourceDocumentPostCon(con);
        ext.selectedSourceDocument = 'Supplier_Invoice__c';
        ext.updateGrid();
        
        suppInv1 = [Select id, Name, finalized__c, transaction_date__c, finalized_date__c, posting_date__c
        		from Supplier_Invoice__c
        		where id = :suppInv1.id];
        system.assert(suppInv1.finalized_date__c == suppInv1.posting_date__c,'suppInv1:'+suppInv1);
       	system.assert(ext.sourceDocs[0].sObj.id == suppInv1.id,'suppInv1:'+suppInv1);
       	ext.sourceDocs[0].selected = true;
        ext.assign();
        
        suppInv1 = [Select id, Name, finalized__c, transaction_date__c, finalized_date__c, posting_date__c
        		from Supplier_Invoice__c
        		where id = :suppInv1.id];
        system.assert(suppInv1.finalized_date__c != suppInv1.posting_date__c,'suppInv1:'+suppInv1);
    	
    }
    
    static testMethod void testReceiving(){
        SampleData sd = new SampleData();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.priorPeriod);
        pageReference pr = page.SourceDocumentPost;
        Test.setCurrentPage(pr);
        SourceDocumentPostCon ext = new SourceDocumentPostCon(con);
        
        ext.selectedSourceDocument = 'Receiving_Document__c';
        
        system.assert(true,ext.blockPost);
        system.assert(sd.currentYearPeriodList != null,'sd.currentYearPeriodList:'+sd.currentYearPeriodList);
        system.assert(sd.currDatetime != null,'sd.currDatetime:'+sd.currDatetime);
        system.assert(sd.currentPeriod != null,'sd.currentPeriod:'+sd.currentPeriod);
        	
        Period__c currentPeriod = [Select id, Name, Prior_Period__c, period_start__c , period_end__c
        				from Period__c
        				where id = :sd.currentPeriod.id];
 
        Receiving_Document__c rd = sd.fuel.receivingDocumentASN;
            
        List<Receipt_Line__c> rls = sd.fuel.receivingDocumentASNLines;
        for(Receipt_Line__c rl : rls){
            rl.extended_cost__c = 10;
        }
        update rls;
        
        rd.transaction_date__c = currentPeriod.Period_start__c.addSeconds(-1);
        rd.finalized__c = true;
        rd.Date_Received__c = currentPeriod.Period_start__c.addSeconds(-1);
        //FIN-566 fix -ASN Accounting
        rd.type__c='Advanced Shipment Notice';
        
        update rd;
      	
      	ext = new SourceDocumentPostCon(con);
        ext.selectedSourceDocument = 'Receiving_Document__c';
        ext.updateGrid();
        
        rd = [Select id, Name, finalized__c, transaction_date__c, finalized_date__c, posting_date__c
        		from Receiving_Document__c
        		where id = :rd.id];
        system.assert(rd.finalized_date__c == rd.posting_date__c,'rd:'+rd);
        system.assert(ext.sourceDocs[0] != null, 'ext.sourceDocs:'+ext.sourceDocs);
       	system.assert(ext.sourceDocs[0].sObj.id == rd.id,'rd:'+rd);
       	ext.sourceDocs[0].selected = true;
        ext.assign();
        
        rd = [Select id, Name, finalized__c, transaction_date__c, finalized_date__c, posting_date__c
        		from Receiving_Document__c
        		where id = :rd.id];
        system.assert(rd.finalized_date__c != rd.posting_date__c,'rd:'+rd);
    	
    }
    
    static testMethod void testShipment(){
        SampleData sd = new SampleData();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.priorPeriod);
        pageReference pr = page.SourceDocumentPost;
        Test.setCurrentPage(pr);
        SourceDocumentPostCon ext = new SourceDocumentPostCon(con);
        
        ext.selectedSourceDocument = 'Shipment__c';
        
        system.assert(true,ext.blockPost);
        system.assert(sd.currentYearPeriodList != null,'sd.currentYearPeriodList:'+sd.currentYearPeriodList);
        system.assert(sd.currDatetime != null,'sd.currDatetime:'+sd.currDatetime);
        system.assert(sd.currentPeriod != null,'sd.currentPeriod:'+sd.currentPeriod);
        	
        Period__c currentPeriod = [Select id, Name, Prior_Period__c, period_start__c , period_end__c
        				from Period__c
        				where id = :sd.currentPeriod.id];
 
        Sales_Order__c so = sd.fuel.salesOrder;
        List<Sales_Order_Line__c> sols = sd.fuel.salesOrderLines;
        
        Shipment__c sh = new Shipment__c();
        sh.Company__c = sd.fuel.company.Id;
        sh.Customer__c = sd.fuel.customerShipTo.Id;
        sh.Date_Shipped__c = currentPeriod.Period_start__c.addSeconds(-1);
        sh.estimated_delivery_date__c = (currentPeriod.Period_start__c.addSeconds(-1)).date();
        sh.Currency__c = TestFuel.currencyUSD.id;
        sh.status__c = 'Confirmed';
        sh.transaction_date__c = currentPeriod.Period_start__c.addSeconds(-1);
        
        insert sh;
        
        List<Shipment_Line__c> sls = new List<Shipment_Line__c>(); 
        for(Sales_Order_Line__c sol : sols){
            Shipment_Line__c sl = new Shipment_Line__c();
            sl.Shipment__c = sh.Id;
            sl.Company__c = sd.fuel.company.id;
            sl.Item__c = sol.Product__r.Item__c;
            sl.product__c = sol.product__c;
            sl.sales_order__c = so.Id;
            sl.sales_order_line__c = sol.Id;
            sl.facility__c = sd.fuel.facility.Id;
            sl.location__c = sd.fuel.location.Id;
            sl.unit_price__c = sol.unit_price__c;
            sl.discount_percent__c = sol.discount_percent__c;
            sl.Quantity_Planned__c = sol.Quantity_Ordered__c;
            sl.Quantity_Allocated__c = 0;
            sl.Quantity_To_Pick__c = 0;
            sl.Quantity_Picked__c = 0;
            sl.quantity_shipped__c = sol.quantity_ordered__c;
            sl.quantity_from_stock__c = sol.quantity_ordered__c;
            sl.extended_cost__c = sol.quantity_ordered__c * sol.unit_price__c;
            sls.add(sl);
        }
        insert sls;
      	
      	sh.finalized__c = true;
      	update sh;
      	
      	ext = new SourceDocumentPostCon(con);
        ext.selectedSourceDocument = 'Shipment__c';
        ext.updateGrid();
        
        sh = [Select id, Name, finalized__c, transaction_date__c, finalized_date__c, posting_date__c
        		from Shipment__c
        		where id = :sh.id];
        system.assert(sh.finalized_date__c == sh.posting_date__c,'sh:'+sh);
        system.assert(ext.sourceDocs[0] != null, 'ext.sourceDocs:'+ext.sourceDocs);
       	system.assert(ext.sourceDocs[0].sObj.id == sh.id,'sh:'+sh);
       	ext.sourceDocs[0].selected = true;
        ext.assign();
        
        sh = [Select id, Name, finalized__c, transaction_date__c, finalized_date__c, posting_date__c
        		from Shipment__c
        		where id = :sh.id];
        system.assert(sh.finalized_date__c != sh.posting_date__c,'sh:'+sh);
    }
}