@isTest
public class SupplierPaymentAccountingTest {
    
    public class SampleData{
        
        public TestDataForFinance data = new TestDataForFinance();
        //public TestFuel data = new TestFuel();
        public List<Purchase_Order__c> poList;
        public Receiving_Document__c receivingdocument;
        public Receipt_Line__c rl;
        public List<Supplier_Invoice__c> supplierInvList;
        public List<Supplier_Payment__c> suppPayList;
        public Supplier_Payment__c suppPay1, suppPay2, suppPay3;
        public List<Supplier_Payment_Line__c> paymentList;
        public Supplier_Payment_Line__c payment1, payment2, payment3, payment4;
        public Set<ID> SuppPayIds;
        public List<Supplier_Payment__c> supplierPaymentQuery;
        
        public SampleData(){
            updateData();
        }
        
        public void updateData(){
            
            // Query POs from data class    
            poList = new List<Purchase_Order__c>();
            poList = [Select   p.Supplier__c, p.Status__c, p.currency__c, 
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
            receivingdocument=new Receiving_Document__c(); { 
                receivingdocument.Company__c=data.company.Id;
                //receivingdocument.Finalized__c = true;
                receivingdocument.Date_Received__c = system.now();
                receivingdocument.Supplier__c=data.supplier.Id;
                receivingdocument.Status__c = 'Closed';      
                receivingdocument.Currency__c = TestFuel.currencyUSD.id;
                receivingdocument.transaction_date__c = system.now();  
                insert receivingdocument; 
            }
            
            rl = new Receipt_Line__c();
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
            supplierInvList = new List<Supplier_Invoice__c>();
            map<id,integer> siPOmap = new map<id,integer>();
            integer cnt = 0;
            for(Purchase_Order__c po:poList){
                Supplier_Invoice__c suppInv = new Supplier_Invoice__c();
                suppInv.Amount_Due__c = po.Purchase_Order_Value__c;
                suppInv.Company__c = po.Company__c;
                suppInv.Supplier_Invoice__c = KSE.getUniqueNumberString();
                suppInv.Date_Invoiced__c = system.now();
                suppInv.Supplier__c = po.Remit_To_Supplier__c;
                suppInv.Invoice_Amount__c = po.Purchase_Order_Value__c;
                suppInv.Currency__c = po.Currency__c;
                siPOmap.put(po.id,cnt);
                supplierInvList.add(suppInv);
                cnt++;
            }
            insert supplierInvList;
            // Add lines to the invoices  
            List<Purchase_Order_Line__c> polineList = [select Id, Purchase_Order__c, Item__c, Delivery_Facility__c, Company__c, Need_Date__c, Unit_Price__c,Order_Quantity__c  from Purchase_Order_Line__c where Purchase_Order__c  in (:data.purchaseOrder1.id, :data.purchaseOrder2.id, :data.purchaseOrder3.id)]; 
            List<Supplier_Invoice_Line__c> receiptinvoicelineList = new List<Supplier_Invoice_Line__c>();
            Set<Id> itemIds = new Set<Id>();
            Set<Id> facilityIds = new Set<Id>();
            List<Date> dateList = new List<Date>();
            for(Purchase_Order_Line__c pol : polineList) {
                itemIds.add(pol.Item__c);
                facilityIds.add(pol.Delivery_Facility__c);
                dateList.add(pol.Need_Date__c); 
            }
           
            ItemService.preCacheCostRecords(dateList, itemIds, facilityIds);
           
            for(Integer i=0;i<polineList.size();i++){
                integer si_num = siPOmap.get(polinelist[i].Purchase_Order__c);
                Supplier_Invoice_Line__c receiptinvoiceline = new Supplier_Invoice_Line__c();
                receiptinvoiceline.Item__c = polineList[i].Item__c;
                receiptinvoiceline.Invoice_Quantity__c = polineList[i].Order_Quantity__c;
                receiptinvoiceline.Supplier_Invoice__c = supplierInvList[si_num].id;
                receiptinvoiceline.Unit_Price__c = polineList[i].Unit_Price__c;
                receiptinvoiceline.Purchase_Order__c = polineList[i].Purchase_Order__c;
                receiptinvoiceline.Purchase_Order_Line__c = polineList[i].ID;
                receiptinvoiceline.Quantity_Received__c = polineList[i].Order_Quantity__c;
                decimal qty = polineList[i].Order_Quantity__c == null ? 0 : polineList[i].Order_Quantity__c;
                DateTime costDate;
                if(polineList[i].Need_Date__c != null)
                    costDate = datetime.newInstance(polineList[i].Need_Date__c.year(), polineList[i].Need_Date__c.month(),polineList[i].Need_Date__c.day());
                decimal stdCost = ItemService.getActiveStandardCost(itemIds,facilityIds,polineList[i].Company__c,polineList[i].Delivery_Facility__c,costDate).get(poLineList[i].Item__c) ;
                if(stdCost == null) stdCost = 0;
                receiptinvoiceline.Extended_Cost__c = qty * stdCost;
                receiptinvoicelineList.add(receiptinvoiceline); 
            }
            insert receiptinvoicelineList;
            // Update the Supplier Invoice on the lines
            receiptinvoicelineList[0].Supplier_Invoice__c = supplierInvList[0].id;
            receiptinvoicelineList[1].Supplier_Invoice__c = supplierInvList[1].id;
            receiptinvoicelineList[2].Supplier_Invoice__c = supplierInvList[1].id;
            receiptinvoicelineList[3].Supplier_Invoice__c = supplierInvList[2].id;
            receiptinvoicelineList[4].Supplier_Invoice__c = supplierInvList[2].id;
            
            update receiptinvoicelineList;
            // Update the supplier invoice Finalized Flag to true
            supplierInvList[0].Finalized__c = true;
            supplierInvList[1].Finalized__c = true;
            supplierInvList[2].Finalized__c = true;
            update supplierInvList;
             
            Set<Id> RcptInvIds = new Set<Id>();
            for(Supplier_Invoice_Line__c rcptInvLine: receiptinvoicelineList){
                RcptInvIds.add(rcptInvLine.id);
            }
            
            suppPayList = new List<Supplier_Payment__c>();
            
            // Create Supplier Payments
            suppPay1 = new Supplier_Payment__c();
            suppPay1.Payment_Amount__c = poList[0].Purchase_Order_Value__c;
            suppPay1.Date_Paid__c = system.now();
            suppPay1.transaction_date__c = system.now();
            suppPay1.Payment_Method_G__c = 'Check';
            suppPay1.Bank_Account__c = data.bankAccount.id ;
            suppPay1.Company__c = poList[0].Company__c;
            //suppPay1.Finalized__c = true;
            //suppPay1.finalized_date__c = system.now();
            suppPay1.Supplier__c = poList[0].Remit_To_Supplier__c;
            suppPay1.Currency__c = TestFuel.currencyUSD.id;
            suppPay1.historical__c = false;
            suppPayList.add(suppPay1);
            
            suppPay2 = new Supplier_Payment__c();
            suppPay2.Payment_Amount__c = poList[1].Purchase_Order_Value__c;
            suppPay2.Date_Paid__c = system.now();
            suppPay2.transaction_date__c = system.now();
            suppPay2.Payment_Method_G__c = 'Check';
            suppPay2.Bank_Account__c = data.bankAccount.id ;
            suppPay2.Company__c = poList[1].Company__c;
            //suppPay2.Finalized__c = true;
            //suppPay2.finalized_date__c = system.now();
            suppPay2.Supplier__c = poList[1].Remit_To_Supplier__c;
            suppPay2.Currency__c = TestFuel.currencyUSD.id;
            suppPay2.historical__c = false;
            suppPayList.add(suppPay2);
            
            suppPay3 = new Supplier_Payment__c();
            suppPay3.Payment_Amount__c = poList[2].Purchase_Order_Value__c;
            suppPay3.Date_Paid__c = system.now();
            suppPay3.transaction_date__c = system.now();
            suppPay3.Payment_Method_G__c = 'Check';
            suppPay3.Bank_Account__c = data.bankAccount.id ;
            suppPay3.Company__c = poList[2].Company__c;
            //suppPay3.Finalized__c = true;
            //suppPay3.finalized_date__c = system.now();
            suppPay3.Supplier__c = poList[2].Remit_To_Supplier__c;
            suppPay3.Currency__c = TestFuel.currencyUSD.id;
            suppPay3.historical__c = false;
            
            suppPayList.add(suppPay3);
            insert suppPayList;
            
            SuppPayIds = new Set<Id>();
            for(Supplier_Payment__c suppPay: suppPayList){
                SuppPayIds.add(suppPay.id);
            }
            
            // Create Payments
            paymentList = new List<Supplier_Payment_Line__c>();
            payment1 = new Supplier_Payment_Line__c();
            payment1.type__c = 'Payment';
            payment1.Supplier_Invoice__c = supplierInvList[0].id;
            payment1.Supplier_Payment__c = suppPayList[0].id;
            payment1.Amount__c = suppPayList[0].Payment_Amount__c;
            paymentList.add(payment1);
            
            payment2 = new Supplier_Payment_Line__c();
            payment2.type__c = 'Payment';
            payment2.Supplier_Invoice__c = supplierInvList[1].id;
            payment2.Supplier_Payment__c = suppPayList[1].id;
            payment2.Amount__c = suppPayList[1].Payment_Amount__c;
            paymentList.add(payment2);
            
            payment3 = new Supplier_Payment_Line__c();
            payment3.type__c = 'Payment';
            payment3.Supplier_Invoice__c = supplierInvList[2].id;
            payment3.Supplier_Payment__c = suppPayList[2].id;
            payment3.Amount__c = suppPayList[2].Payment_Amount__c - 10;
            paymentList.add(payment3);
            
            payment4 = new Supplier_Payment_Line__c();
            payment4.type__c = 'Earned Terms Discount';
            payment4.Supplier_Invoice__c = supplierInvList[2].id;
            payment4.Supplier_Payment__c = suppPayList[2].id;
            payment4.Amount__c = 10;
            paymentList.add(payment4);
            
            insert paymentList;        
            
            for(Supplier_Payment__c sp : suppPayList){
                sp.finalized__c = true;
            }
            
            update suppPayList;
            
            supplierPaymentQuery = [Select id, Name, Finalized__c, Finalized_hidden__c,
                                                                (Select id, Name from Supplier_Payment_Lines__r) 
                                                                from Supplier_Payment__c 
                                                                where id in :SuppPayIds];
            system.assert(supplierPaymentQuery.size() == 3);
            system.assert(supplierPaymentQuery[0].Supplier_Payment_Lines__r.size() > 0  , 'expected  a payment');
        }
    }
    
    static testmethod void testSPAccounting(){

        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice__c-'+Supplier_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        
        SampleData sd = new SampleData();
        
        //system.assertEquals(true, sd.supplierPaymentQuery[0].Finalized__c);
        //system.assertEquals(true, sd.supplierPaymentQuery[0].Finalized_hidden__c);
        sd.supplierPaymentQuery[0].Finalized__c = true;
        sd.supplierPaymentQuery[0].Finalized_hidden__c = true;  
        
        Test.startTest();   
        boolean sawException = false;
        try{
            sd.supplierPaymentQuery[0].Finalized__c = false;
            update sd.supplierPaymentQuery[0];
        }catch(Exception e){

            sawException = true;
        }
        
        //system.assertEquals(true, sawException);
         
        SupplierPaymentAccounting spa = new SupplierPaymentAccounting();
        spa.execute(sd.paymentList);
        
        List<Accounting_Entry__c> accountingEntryListSuppPayment = [Select id, Name, Supplier_Payment__c, Supplier__c
                                                                    from Accounting_Entry__c
                                                                    where Supplier_Payment__c in :sd.SuppPayIds];
        // test if the accounting entries are generated
        system.assertNotEquals(null,accountingEntryListSuppPayment);
        
        Integer listSize = accountingEntryListSuppPayment.size();
        for(Integer i=0;i<listSize; i++){
            system.assertEquals(sd.data.remittosupplier.id, accountingEntryListSuppPayment[i].Supplier__c) ;
        }
        Test.stopTest();  

    }
    
    static testMethod void testFinalizeHeaderValidation(){

        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        //lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice__c-'+Supplier_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        SampleData sd = new SampleData();
        
        Test.startTest();   
        
        //system.assertEquals(true, sd.supplierPaymentQuery[0].Finalized__c);
        //system.assertEquals(true, sd.supplierPaymentQuery[0].Finalized_hidden__c);
        sd.supplierPaymentQuery[0].Finalized__c = true;
        sd.supplierPaymentQuery[0].Finalized_hidden__c = true;
        
        string trxnCurr = sd.suppPayList[0].Currency__c;
        boolean sawException = false;
        string exMsg;
        try{
            sd.suppPayList[0].Currency__c = null;
            update sd.suppPayList[0];
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to edit a finalized doc ' + exMsg );
        
        sawException = false;
        exMsg = null;
        sd.suppPayList[0].Currency__c = trxnCurr;
        try{
            delete sd.suppPayList[0];
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to delete a finalized doc ' + exMsg );
        
        Test.stopTest(); 
    }
    
    public static testMethod void testFinalizeLineEditValidation(){
        
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        //lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice__c-'+Supplier_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        SampleData sd = new SampleData();
        
        //system.assertEquals(true, sd.supplierPaymentQuery[0].Finalized__c);
        //system.assertEquals(true, sd.supplierPaymentQuery[0].Finalized_hidden__c);
        sd.supplierPaymentQuery[0].Finalized__c = true;
        sd.supplierPaymentQuery[0].Finalized_hidden__c = true;
        
        test.startTest();
        
        for(Supplier_Payment_Line__c spl : sd.paymentList){
            spl.Subtransaction_type__c = 'Change';
        }
        
        boolean sawException = false;
        string exMsg = null;
        try{
            update sd.paymentList;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to edit finalized doc lines ' + exMsg );
    }
    
        
    public static testMethod void testFinalizeLineDeleteValidation(){
        
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        //lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice__c-'+Supplier_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        SampleData sd = new SampleData();
        
        //system.assertEquals(true, sd.supplierPaymentQuery[0].Finalized__c);
        //system.assertEquals(true, sd.supplierPaymentQuery[0].Finalized_hidden__c);
        sd.supplierPaymentQuery[0].Finalized__c = true;
        sd.supplierPaymentQuery[0].Finalized_hidden__c = true;
        
        test.startTest();
            
        boolean sawException = false;
        string exMsg = null;
        try{
            delete sd.paymentList;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to delete finalized doc lines ' + exMsg );
    }
    
    public static testMethod void testFinalizeLineAddValidation(){
        
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        //lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice__c-'+Supplier_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        SampleData sd = new SampleData();
        
        //system.assertEquals(true, sd.supplierPaymentQuery[0].Finalized__c);
        //system.assertEquals(true, sd.supplierPaymentQuery[0].Finalized_hidden__c);
        sd.supplierPaymentQuery[0].Finalized__c = true;
        sd.supplierPaymentQuery[0].Finalized_hidden__c = true;
        
        test.startTest();
    
        boolean sawException = false;
        string exMsg = null;
        try{
            List<Supplier_Payment_Line__c> newSPLs = new List<Supplier_Payment_Line__c>();
            for(Supplier_Payment_Line__c spl : sd.paymentList){
                newSPLs.add(spl.clone(false, true));
            }
            insert newSPLs;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        system.assert(sawException, 'We are expecting to see an exception for attempting to add lines to a finalized doc ' + exMsg );
    }
    
    public static testMethod void testFinalizeLineUndeleteValidation(){
        
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice__c-'+Supplier_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        SampleData sd = new SampleData();
        test.startTest();
        Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(sd.suppPayList);
        
        system.assert(mResponses.get(sd.suppPayList[0].Id).Success, 'We are expecting a successful unfinalize' + mResponses.get(sd.suppPayList[0].Id));
        
        List<Supplier_Payment_Line__c> newSPLs = new List<Supplier_Payment_Line__c>();
        for(Supplier_Payment_Line__c spl : sd.paymentList){
            newSPLs.add(spl.clone(false, true));
        }
        insert newSPLs;
        
        delete newSPLs;
        
        for(Supplier_Payment__c sp : sd.suppPayList){
            sp.finalized__c = true;
        }
        update sd.suppPayList;
       
        boolean sawException = false;
        string exMsg = null;
        
        try{
            undelete newSPLs;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        system.assert(sawException, 'We are expecting to see an exception for attempting to undelete lines on a finalized doc ' + exMsg );
 	}  
 	
 	//// TODO: Below test method to be uncommented and refactored to avoid Too many SOQL errors - KNDY-9759
 /*	public static testMethod void testRFX(){
 	
 		//need exchange rates
 		TestFuel fuel = new TestFuel();
 		List<Period__c> periods = fuel.periodList;
 		//TestData.Accounting acctData = new TestData.Accounting(fuel.company.Id);
 		List<Accounting_Rule__c> rdAccountingRuleList = fuel.rdAccountingRuleList;
 		List<Accounting_Rule__c> SuppInvAcctRulesList = fuel.SuppInvAcctRulesList;
 		List<Accounting_Rule__c> SuppPaymentAcctRulesList = fuel.SuppPaymentAcctRulesList;
 		
        List<GL_Account__c> glaccounts = fuel.GLAccountList;
 		
// 		GL_Account__c rfxGL;
// 		GL_Type__c rfxGLType;
// 		rfxGLType = new GL_Type__c(name = 'RFX GL Type', Normal_Balance__c  = 'Credit',
// 		Accounting_Type__c  = 'Other Comprehensive Income',
// 		Statement_Type__c  = 'Income Statement',
// 		Account_Range_From__c = '870000',
// 		Account_Range_To__c ='879999' );
// 		insert rfxGLType;
//         rfxGL = new GL_Account__c(name = 'RFX', GL_Account_Number__c = '870000', GL_Account_Name__c = 'RFX',FX_Type__c = 'RFX', active__c = true, normal_balance__c = 'Debit', GL_Type__c = rfxGLType.id) ;
//         insert rfxGL;
 		
 		DateTime refDT = system.now();
 		//exchange rates
 		List<Exchange_Rate__c> exchangeRates = new List<Exchange_Rate__c>();
 		integer counter = 0;
 		for(integer i=-4; i < 4; i++){
 			Exchange_Rate__c iER = new Exchange_Rate__c();
            iER.From_Currency__c = TestFuel.currencyGBP.id;
            iER.To_Currency__c = fuel.company.Comp_Currency__c;
 			iER.multiplier_exchange_rate__c = counter+1;
 			iER.rate_start_datetime__c = refDT.addDays(-i-1);
 			iER.rate_end_datetime__c = refDT.addDays(-i);
 			iER.Daily_Monthly__c = 'Daily';
 			exchangeRates.add(iER);
 			counter++;
 		}
 		
 		Exchange_Rate__c iER = new Exchange_Rate__c();
        iER.From_Currency__c = TestFuel.currencyGBP.id;
        iER.To_Currency__c = fuel.company.Comp_Currency__c;
 		iER.multiplier_exchange_rate__c = 10;
 		iER.rate_start_datetime__c = refDT.addDays(-10);
 		iER.rate_end_datetime__c = refDT.addDays(10);
 		iER.Daily_Monthly__c = 'Daily';
 		exchangeRates.add(iER);
 		
 		delete [select id from exchange_rate__c];
 		insert exchangeRates;
 		
 		Item_Cost__c itemCost = new Item_Cost__c();
 		itemCost.Item__c = fuel.itemList[0].Id;
 		itemCost.material_cost__c = 12;
 		itemCost.start_date__c = refDt.addDays(-30);
 		itemCost.Status__c = 'Proposed';
 		itemCost.date_activated__c = system.today().addDays(-30);
 		itemCost.Company__c = fuel.company.Id;
 		insert itemCost;
 		
 		itemCost.Status__c = 'Approved';
 		update itemCost;
 		
 		Purchase_Order__c po = new Purchase_Order__c();
 		po.Order_Date__c = system.today();
        po.status__c = 'Open';
        po.Supplier__c = fuel.supplier.id; 
        po.Remit_To_Supplier__c = fuel.supplier.id; 
        po.Company__c = fuel.company.id;
        po.Payment_Term__c = fuel.terms.id;
        po.Currency__c = TestFuel.currencyGBP.id;
        po.Acknowledge_Via__c = 'Email';
        insert po;
        
        Purchase_Order_Line__c pol = new Purchase_Order_Line__c();
        pol.Purchase_Order__c = po.Id;
        pol.Order_Quantity__c = 10;        
        pol.Unit_Price__c = 12;
        pol.Item__c = fuel.itemList[0].Id;
        pol.Status__c = Label.Open;    
        pol.Need_Date__c = System.today();
        pol.Company__c = fuel.company.id;
        pol.Delivery_Location__c = fuel.location.ID;
        pol.Delivery_facility__c = fuel.location.facility__c;
        pol.Supplier__c = fuel.supplier.Id;
        insert pol; 
        
        Receiving_Document__c rd = new Receiving_Document__c();
        rd.Company__c = po.Company__c;
        rd.Date_Received__c = refDT.addDays(-3);
        rd.Supplier__c = po.Supplier__c;
        rd.Status__c = 'Closed';      
        rd.currency__c = po.Currency__c;
        rd.transaction_date__c = rd.Date_Received__c; 
        rd.Type__c = 'Advanced Shipment Notice';

        insert rd; 
            
        Receipt_Line__c rl = new Receipt_Line__c();
        rl.Item__c = pol.item__c;
        rl.Company__c = po.company__c;
        rl.Supplier__c = po.supplier__c;
        rl.Status__c = 'Open';     
        rl.Receiving_Document__c = rd.Id;
        rl.Location__c = po.Delivery_Location__c;
        rl.Unit_Price__c = 15;
        rl.Purchase_Order__c = po.id;
        rl.Purchase_Order_Line__c = pol.Id;
        rl.Quantity_Received__c = pol.Order_Quantity__c;
        rl.Extended_Cost__c = 70;
        insert rl;
        
        rd.finalized__c = true;
        update rd; 
        
        ReceivingDocumentAccounting rda = new ReceivingDocumentAccounting();
        rda.execute(new List<sObject>{rl});
        
        //query for and assert GRNI and Inventory
        //system.assert(limits.getQueries() < 1, limits.getQueries());
        po = [Select Id, Purchase_Order_Value__c, Order_Date__c,
            status__c, Supplier__c, Remit_To_Supplier__c, Company__c,
            Payment_Term__c, Currency__c 
            from Purchase_Order__c where Id = :po.Id];

        Supplier_Invoice__c si = new Supplier_Invoice__c();
        si.Company__c = po.Company__c;
        si.Supplier__c = po.Supplier__c;
        si.Payment_Term__c = po.Payment_Term__c;
        si.Amount_Due__c = pol.order_quantity__c * pol.unit_price__c;
        si.Supplier_Invoice__c = KSE.getUniqueNumberString();
        si.Date_Invoiced__c = refDt.addDays(-2);
        si.Supplier__c = po.Remit_To_Supplier__c;
        si.Invoice_Amount__c = po.Purchase_Order_Value__c;
        si.Currency__c = po.Currency__c;
        
        insert si;
        
        Supplier_Invoice_Line__c sil = new Supplier_Invoice_Line__c();
        sil.Item__c = pol.Item__c;
        sil.Invoice_Quantity__c = pol.Order_Quantity__c;
        sil.Supplier_Invoice__c = si.id;
        sil.Unit_Price__c = pol.Unit_Price__c;
        sil.Purchase_Order__c = po.Id;
        sil.Purchase_Order_Line__c = pol.Id;
        sil.Quantity_Received__c = pol.Order_Quantity__c;
        decimal qty = pol.Order_Quantity__c;
        decimal stdCost = 15;
        sil.Extended_Cost__c = qty * stdCost;
        
        insert sil;
        
        //KNDY-12704 reset sil to expected values
        sil.SubTransaction_Type__c = 'Goods - Purchase Order';
        sil.Line_Type__c = null;
        update sil;
        
        si.finalized__c = true;
        update si;    
        
        test.startTest();
        
        SupplierInvoiceAccounting sia = new SupplierInvoiceAccounting();
        sia.execute(new List<sObject>{sil});
        
        for(Accounting_Entry_Line__c ael : [SELECT Id, Comp_Transaction_Currency__c, COMP_Transaction_currency_Amount_dr__c, COMP_transaction_currency_amount_cr__c FROM Accounting_Entry_Line__c WHERE Supplier_Invoice_Line__c = :sil.Id]){
            system.assertNotEquals(null, ael.comp_transaction_currency_amount_dr__c);
            system.assertNotEquals(null, ael.comp_transaction_currency_amount_cr__c);
            system.assertNotEquals(null, ael.Comp_Transaction_Currency__c);
        }
        
        Bank_Account__c ba = new Bank_Account__c(
            Name = 'Test Different Currency Acc',
            account_type__c = 'Checking',
            GL_Account__c = fuel.cashGL.id,
            Company__c = fuel.company.Id,
            Active__c = true,
            Currency__c = po.Currency__c
        );
        
        insert ba;
        
        Supplier_Payment__c sp = new Supplier_Payment__c();
        sp.Payment_Amount__c = pol.order_quantity__c * pol.unit_price__c;
        sp.Date_Paid__c = refDt.addDays(-1);
        sp.transaction_date__c = system.now();
        sp.Payment_Method_G__c = 'Check';
        sp.Bank_Account__c = ba.id;
        sp.Company__c = po.Company__c;
        sp.Supplier__c = po.Remit_To_Supplier__c;
        sp.Currency__c = po.Currency__c;
        sp.historical__c = false;
        insert sp;
                
        Supplier_Payment_Line__c spl = new Supplier_Payment_Line__c();
        spl.type__c = 'Payment';
        spl.Supplier_Invoice__c = si.id;
        spl.Supplier_Payment__c = sp.id;
        spl.Amount__c = sp.Payment_Amount__c;
        insert spl;
        
        sp.finalized__c = true;
        update sp;
        
        
        SupplierPaymentAccounting spa = new SupplierPaymentAccounting();
        spa.execute(new List<sObject>{spl});
        
        Accounting_Entry__c ae = [Select Id, Source_Lines_Processed__c, Supplier_Payment__r.Total_Number_of_Lines__c From Accounting_Entry__c Where Supplier_Payment__c =:sp.Id and Status__c = 'Active' limit 1];
        
        List<AggregateResult> arGLs = [SELECT count(Id) nRecs, sum(amount_dr__c) dr, sum(amount_cr__c) cr, 
                                        sum(COMP_Functional_Currency_Amount_DR__c) funcDR,
                                        sum(COMP_Functional_Currency_Amount_CR__c) funcCR, 
                                        GL_Account__c glId, GL_Account__r.Name glName
                                        FROM Accounting_Entry_Line__c
                                        WHERE Status__c = 'Active'
                                        GROUP BY GL_Account__c, GL_Account__r.Name];
        
                                        //AND (Receipt_Line__r.Purchase_Order_Line__c = :pol.Id
                                        //OR Supplier_Invoice_Line__c = :sil.Id
                                        //OR Supplier_Payment_Line__c = :spl.Id
                                        //OR GL_Account__r.FX_Type__c = 'RFX')
                                        //GROUP BY GL_Account__c, GL_Account__r.Name];
                                            
        List<Accounting_Entry_Line__c> aels = [SELECT Id, Accounting_Entry__r.Transaction_Type__c, Subtransaction_Type__c, Line_Type__c, amount_cr__c, amount_dr__c,
        										accounting_rule__c, gl_account__c, gl_account__r.name, accounting_rule__r.gl_account_reference_value__c,
        										accounting_rule__r.default_gl_Account__c, accounting_rule__r.gl_account__r.name, gl_account__r.GL_Account_Name__c,
                                                gl_account__r.FX_Type__c,
        										accounting_rule__r.transaction__c, accounting_rule__r.subtransaction_type__c, accounting_rule__r.line_type__c
        										FROM Accounting_Entry_Line__c
        										WHERE Status__c = 'Active'
		        								AND (Receipt_Line__r.Purchase_Order_Line__c = :pol.Id
		        								OR Supplier_Invoice_Line__c = :sil.Id
		        								OR Supplier_Payment_Line__c = :spl.Id
		        								OR GL_Account__r.FX_Type__c = 'RFX')];
		boolean sawRFX = false;
		for(Accounting_Entry_Line__c ael : aels){
			if(ael.gl_account__r.FX_Type__c != 'RFX'){
				system.assertEquals(ael.Accounting_Rule__c, ael.accounting_rule__c, ael.accounting_entry__r.transaction_type__c + '- ' + ael + ' - ' +  ael.accounting_rule__r);
				system.assertEquals(ael.gl_account__c, ael.gl_account__c, ael.accounting_rule__r.default_gl_Account__c + ' - ' + ael.accounting_rule__r.gl_account__r.name + ' - ' + ael.accounting_rule__r.gl_account_reference_value__c+ ' - ' + ael);
			}else{
				sawRFX = true;
				system.debug(logginglevel.info, 'ael: ' + ael+'ael.GL_Account__r.GL_Account_Name__c:'+ael.GL_Account__r.GL_Account_Name__c);
			}
			//system.debug(logginglevel.info, 'ael: ' + ael);
		}  
		
// 		
// 		SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c');
// 		soql.addAllFields();
// 		List<Accounting_Entry_Line__c> jaels = (List<Accounting_Entry_Line__c>)soql.returnQueryResult();
// 		system.debug(logginglevel.info, 'jaels: ' +  JSON.serialize(jaels)); 	
// 		
		

		system.assert(sawRFX, 'We should have seen RFX'); 
		AggregateResult arTotals = [SELECT sum(COMP_Functional_Currency_Amount_DR__c) funcDR,
        										sum(COMP_Functional_Currency_Amount_CR__c) funcCR
        										FROM Accounting_Entry_Line__c
        										WHERE Status__c = 'Active'];
        										
		        								//AND (Receipt_Line__r.Purchase_Order_Line__c = :pol.Id
		        								//OR Supplier_Invoice_Line__c = :sil.Id
		        								//OR Supplier_Payment_Line__c = :spl.Id
		        								//OR GL_Account__r.FX_Type__c = 'RFX')]; 
	    //test.stopTest();
		        								
		system.assertEquals(arTotals.get('funcDR'), arTotals.get('funcCR'), arTotals + ' - ' + arGLs); 

        system.assertEquals( ae.Source_Lines_Processed__c, ae.Supplier_Payment__r.Total_Number_of_Lines__c, 'Lines Procecessed: ' + ae.Source_Lines_Processed__c + '\tTotal Payment Lines: ' + ae.Supplier_Payment__r.Total_Number_of_Lines__c);
        test.stopTest();
    }*/    
    
}