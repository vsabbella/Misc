@isTest
public class SupplierPaymentVoidCancelTest {
    static TestDataForFinance data ;
    static SupplierPaymentData suppPaymentData;
    
    static{
        data = new TestDataForFinance();
        suppPaymentData = new SupplierPaymentData();
    }
    
    private static Accounting_Default__c createAccountingDefault(){
        Accounting_Default__c testDefault = new Accounting_Default__c();
        testDefault.Company__c = data.company.id;
        testDefault.GL_Account__c = data.Acctdata.CashGl.id;
        DML.insertAsUser( new list<sobject>{testDefault} );
        return testDefault;
    }
    
    private static List<Purchase_Order__c> getPOList(){
        List<Purchase_Order__c> poList = [Select   p.Supplier__c, p.Status__c, 
                                p.Payment_Term__c, p.Order_Date__c, p.Purchase_Order_Value__c,
                                p.Name, p.Id, p.Deliver_to__c, p.Date_Closed__c, p.Remit_To_Supplier__c,
                                p.Company__c, p.Buyer__c, p.Approval_Status__c, p.Acknowledge_Via__c, 
                                (Select Id, IsDeleted, Name, Purchase_Order__c, Company__c, 
                                    Date_Added__c, Date_Closed__c, Date_Last_Changed__c, Description__c,  
                                    Item__c, Latest_Promise_Date__c, Line_Value__c, Line__c,  Manufacturers_Part__c, 
                                    Need_Date__c, Order_Quantity__c, Overage_Percentage__c, 
                                    Promise_Date__c, Purchase_UOM__c, Quantity_Returned_to_Supplier__c, 
                                    Quantity_Still_Due__c, Requisition_Number__c, Rush_Line__c, Special_Notes__c, Status__c, 
                                    Supplier_Part__c, Suppliers_Part_Description__c, Unit_Price__c 
                                    From Purchase_Order_Lines__r order by Line__c ASC) 
                                From Purchase_Order__c p
                                where p.id in (:data.purchaseOrder1.id, :data.purchaseOrder2.id, :data.purchaseOrder3.id, :data.purchaseOrder4.id)];
       return poList;
    }
    
    private static List<Purchase_Order_Line__c> getPOLines(){
       List<Purchase_Order_Line__c> poLineList = [Select id, Name, Item__c from Purchase_Order_Line__c where Purchase_Order__c in (:data.purchaseOrder2.id, :data.purchaseOrder3.id, :data.purchaseOrder4.id)];
       return poLineList;
    }
    
    private static Supplier_Invoice__c createSI(String invType, Decimal invAmount){
       Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();
       suppInv1.Company__c = data.company.id;
       suppInv1.Invoice_Type__c = invType;
       suppInv1.Date_Invoiced__c = System.now();
       suppInv1.transaction_date__c = system.now();
       suppInv1.Currency__c = TestFuel.currencyUSD.Id;
       suppInv1.Supplier__c = data.remittosupplier.id;
       //suppInv1.Amount_Due__c = data.purchaseOrder2.Purchase_Order_Value__c;
       suppInv1.Invoice_Amount__c = invAmount;
       //Uniqueness of below field can be maintained iff invAmount is unique
       suppInv1.Supplier_Invoice__c = invAmount + invType;
       suppInv1.Finalized__c = false;
       suppInv1.Void__c = false;
       suppInv1.historical__c = false;
       return suppInv1;
    }
    
    private static Supplier_Invoice_Line__c createSILine(Decimal invQty, Decimal invUnitPrice, 
                                        Supplier_Invoice__c si, Purchase_Order_Line__c pol){
       Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c();
       //suppInvLine1.Supplier__c = data.remittosupplier.id;
       suppInvLine1.Supplier_Invoice__c = si.id;
       suppInvLine1.Extended_Cost__c = 50;
       suppInvLine1.Invoice_Quantity__c = invQty;
       suppInvLine1.Item__c = data.itemList[0].id;
       //suppInvLine1.Location__c = data.location.id;
       suppInvLine1.Purchase_Order__c = data.purchaseOrder2.id;
       suppInvLine1.Purchase_Order_Line__c = pol.id;
       suppInvLine1.Quantity_Received__c = 4;
       suppInvLine1.Unit_Price__c = invUnitPrice; 
       suppInvLine1.Line_Type__c = 'Item';
       return suppInvLine1;
    }
    
    private static Supplier_Payment__c createSP(Purchase_Order__c po, Decimal paymentAmount){
        Supplier_Payment__c suppPay1 = new Supplier_Payment__c();
        suppPay1.Payment_Amount__c = paymentAmount;
        suppPay1.Date_Paid__c = system.now();
        suppPay1.transaction_date__c = system.now();
        suppPay1.Payment_Method_G__c = 'Check';
        suppPay1.Bank_Account__c = data.bankAccount.id ;
        suppPay1.Company__c = po.Company__c;
        //suppPay1.Finalized__c = true;
        //suppPay1.finalized_date__c = system.now();
        suppPay1.Supplier__c = po.Remit_To_Supplier__c;
        suppPay1.Currency__c = TestFuel.currencyUSD.id;
        suppPay1.historical__c = false;
        suppPay1.Void__c = false;
        suppPay1.Status__c = 'Applied';
        return suppPay1;
    }
    
    private static  Supplier_Payment_Line__c createSPL(Supplier_payment__c sp, Supplier_Invoice__c si){
       Supplier_Payment_Line__c payment1 = new Supplier_Payment_Line__c();
       payment1.type__c = 'Payment';
       payment1.Supplier_Invoice__c = si.id;
       payment1.Supplier_Payment__c = sp.id;
       payment1.Amount__c = sp.Payment_Amount__c;
       return payment1;
    }
    
    public class SupplierPaymentData{
        
        //Accounting_Default__c testDefault = createAccountingDefault();
        List<Purchase_Order__c> poList = getPOList();
        List<Purchase_Order_Line__c> poLineList = getPOLines();
        
        public Supplier_Invoice__c suppInv1;
        public Supplier_Invoice_Line__c suppInvLine1;
        public Supplier_Invoice_Line__c suppInvLine2;
        public Supplier_Invoice__c prepaymentSI;
        public Supplier_Invoice_Line__c prepaymentSILine;
        public Supplier_Invoice__c appliedPrepaymentSI;
        public Supplier_Invoice_Line__c appliedPrepaymentSILine;
        public Supplier_Invoice__c prepaymentSI2;
        public Supplier_Invoice_Line__c prepaymentSILine2;

        
        List<Supplier_Invoice__c> suppInvAEList = new List<Supplier_Invoice__c>();{
            System.debug(logginglevel.error, 'Executed Queries so far-1--->'+Limits.getQueries());
            suppInv1 = createSI('Invoice', 160); 
            
            // This SI will only be paid off in tests
            prepaymentSI = createSI('Prepayment', 10);
            prepaymentSI.Credit_Memo_Amount__c = -10;
            
            // This SI will be paid off in tests, 
            // and applied to pay of other SIs.
            // prepayment amount available to apply will be 0
            prepaymentSI2 = createSI('Prepayment', 11);
            prepaymentSI2.Credit_Memo_Amount__c = -11;
            prepaymentSI2.Credit_Memo_Balance__c = 0; // available to apply
            
            
            appliedPrepaymentSI = createSI('Invoice', 100);
            suppInvAEList.add(suppInv1);
            suppInvAEList.add(prepaymentSI);
            suppInvAEList.add(appliedPrepaymentSI);
            suppInvAEList.add(prepaymentSI2);
            DML.insertAsUser( suppInvAEList );
        }
        
        List<Supplier_Invoice_Line__c> suppInvLineList = new List<Supplier_Invoice_Line__c>();{
            // Create 2 siLine for amount 80 each
            suppInvLine1 = createSILine(4, 20, suppInvAEList[0], poLineList[0]);
            suppInvLineList.add(suppInvLine1);
            suppInvLine2 = createSILine(4, 20, suppInvAEList[0], poLineList[0]);
            suppInvLineList.add(suppInvLine2);
            // Create 1 prepayment siline for amount 10 
            prepaymentSILine = createSILine(10, 1, suppInvAEList[1], poLineList[0]);
            //prepaymentSILine.Prepayment_Amount_Applicable__c = 10;
            suppInvLineList.add(prepaymentSILine);
            // Create 1 prepayment siline for amount 11
            prepaymentSILine2 = createSILine(11, 1, prepaymentSI2, poLineList[0]);
            suppInvLineList.add(prepaymentSILine2);
            // Create 1 siline for amount 100 and prepayment amount applicable 11
            appliedPrepaymentSILine = createSILine(100, 1, appliedPrepaymentSI, poLineList[0]);
            //appliedPrepaymentSILine.Prepayment_Amount_Applicable__c = 11; 
            suppInvLineList.add(appliedPrepaymentSILine);
            
            DML.insertAsUser( suppInvLineList );
            // approve and finalize SI
            suppInv1.Status__c = 'Approved';
            suppInv1.Finalized__c = true;
            prepaymentSI.Status__c = 'Approved';
            prepaymentSI.Finalized__c = true;
            prepaymentSI2.Status__c = 'Approved';
            prepaymentSI2.Finalized__c = true;
            appliedPrepaymentSI.Status__c = 'Approved';
            appliedPrepaymentSI.Finalized__c = true;
            
            DML.allowUpdateFields( new list<string>{'Finalized__c', 'Status__c'}, Supplier_Invoice__c.SObjectType );
            DML.sobjectUpdate( suppInvAEList );    
        }
        
        Supplier_Payment__c suppPay1;
        Supplier_Payment_Line__c payment1;
        Supplier_Payment__c prepaymentSP;
        Supplier_Payment_Line__c prepaymentSPL;
        Supplier_Payment__c prepaymentSP2;
        Supplier_Payment_Line__c prepaymentSPL2;
        Supplier_Payment__c prepaymentAppliedSP;
        Supplier_Payment_Line__c prepaymentApplied_PaymentSPL;
        Supplier_Payment_Line__c prepaymentApplied_PrepaymentSPL;
        // Create Supplier Payments
        List<Supplier_Payment__c> suppPayList = new List<Supplier_Payment__c>();{
            suppPay1 = createSP(poList[0], 160); // pay 160
            prepaymentSP = createSP(poList[0], 10); // pay 10
            prepaymentAppliedSP = createSP(poList[0], 89); // pay 100 (inv amount) - (11) prepayment amount
            prepaymentSP2 = createSP(poList[0], 11); // pay 11
            suppPayList.add(suppPay1);
            suppPayList.add(prepaymentSP);
            suppPayList.add(prepaymentAppliedSP);
            suppPayList.add(prepaymentSP2);
            DML.insertAsUser( suppPayList );
        }
        
        List<Supplier_Payment_Line__c> paymentList = new List<Supplier_Payment_Line__c>();{
            payment1 = createSPL(suppPayList[0],suppInvAEList[0]);
            prepaymentSPL = createSPL (suppPayList[1],suppInvAEList[1]);
            prepaymentSPL2 = createSPL (prepaymentSP2,prepaymentSI2);//11
            
            // Use Invoice SI on SPL
            prepaymentApplied_PaymentSPL = createSPL (prepaymentAppliedSP,appliedPrepaymentSI);
            prepaymentApplied_PaymentSPL.Type__c = 'Payment';
            prepaymentApplied_PaymentSPL.Amount__c = 100;
            // use Prepayment SI on SPL
            prepaymentApplied_PrepaymentSPL = createSPL (prepaymentAppliedSP,prepaymentSI2);
            prepaymentApplied_PrepaymentSPL.Type__c = 'Prepayment';
            prepaymentApplied_PrepaymentSPL.Amount__c = -11;
            
            paymentList.add(payment1);
            paymentList.add(prepaymentSPL);
            paymentList.add(prepaymentSPL2);
            paymentList.add(prepaymentApplied_PaymentSPL);
            paymentList.add(prepaymentApplied_PrepaymentSPL);
            insert paymentList;        
            
            // Finalize the payment
            for(Supplier_Payment__c sp : suppPayList){
                sp.finalized__c = true;
            }
            update suppPayList;
            
            // Close the supplier invoice, and reset amount paid
            for (Supplier_Invoice__c si :suppInvAEList){
                si.Status__c = 'Closed';
                si.Amount_Paid__c = si.Invoice_Amount__c; // Balance due will become 0
            }
            update suppInvAEList;
            System.debug(logginglevel.error, 'Executed Queries so far-2--->'+Limits.getQueries());
            // Make basic assertions of test data
            List<Supplier_Payment__c> supplierPaymentQuery = [Select id, Name, Finalized__c, Finalized_hidden__c,
                                      (Select id, Name, Supplier_Invoice__r.Status__c, Supplier_Invoice__r.Invoice_Amount__c,
                                        Supplier_Invoice__r.Amount_Paid__c, Supplier_Invoice__r.Balance_Due__c from Supplier_Payment_Lines__r) 
                                      from Supplier_Payment__c 
                                      where id in :suppPayList];
            system.assert(supplierPaymentQuery.size() == 4, '>>>supplierPaymentQuery.size()/suppPayList:'+supplierPaymentQuery.size()+'/'+suppPayList);
            for (Supplier_Payment__c sp: supplierPaymentQuery){
	            system.assert(sp.Supplier_Payment_Lines__r.size() > 0  , 'expected  a payment');
	            for (Supplier_Payment_Line__c spl : sp.Supplier_Payment_Lines__r){
	                system.assert(spl.Supplier_Invoice__r.Status__c == 'Closed', '>>> spl.Supplier_Invoice__r: ' + spl.Supplier_Invoice__r);
	                system.assert(spl.Supplier_Invoice__r.Amount_Paid__c == spl.Supplier_Invoice__r.Invoice_Amount__c, '>>> spl.Supplier_Invoice__r: ' + spl.Supplier_Invoice__r);
	                system.assert(spl.Supplier_Invoice__r.Balance_Due__c == 0, '>>> spl.Supplier_Invoice__r: ' + spl.Supplier_Invoice__r);
	            }
            }
        }
    }
    static testMethod void testCancel() {
        test.startTest();
        SupplierPaymentVoidCancelService vcs = new SupplierPaymentVoidCancelService(new List<Supplier_Payment__c>{suppPaymentData.suppPay1});
        Map<Id, VoidCancelService.VoidCancelDetail> vcdMap = vcs.getBusinessVoidCancelDetails(new list<sObject>{(sobject) suppPaymentData.suppPay1});
        test.stopTest(); 
        
        system.assert(vcdMap.size() == 1, '>>>> vcdMap: ' + vcdMap);
        String businessCancelErrors = '';
        for (VoidCancelService.VoidCancelDetail vcd : vcdMap.values()){
            businessCancelErrors += vcd.cancelMessages;
        }
        
        system.debug(LoggingLevel.Error, '>>> businessCancelErrors: ' + businessCancelErrors);
        system.assert(!String.isBlank(businessCancelErrors));
        system.assert(!businessCancelErrors.contains ('Cancel is not permitted for Supplier Payments'));
        system.assertEquals(suppPaymentData.suppPay1.Finalized__c, true,'Supplier Payment is not finalized');
        system.assertEquals(vcdMap.get(suppPaymentData.suppPay1.id).isCancellable, true,'Supplier Payment is not cancellable');
        
    }
    
     static testMethod void testCancel_for2wayand3way() {
       
       test.startTest();
       SupplierPaymentVoidCancelService vcs = new SupplierPaymentVoidCancelService(new List<Supplier_Payment__c>{suppPaymentData.suppPay1});
       Map<Id, VoidCancelService.VoidCancelDetail> vcdMap = vcs.getBusinessVoidCancelDetails(new list<sObject>{(sobject) suppPaymentData.suppPay1});
        
       Apexpages.standardcontroller SPcon = new Apexpages.Standardcontroller(suppPaymentData.suppPay1);  
       SupplierPaymentVoidCancelExt ext = new SupplierPaymentVoidCancelExt(SPcon);
       
       ext.CancelDocs();
       List<Supplier_Payment__c> supPaymentLst = [Select id, Name, Status__c,(Select id, Name, Supplier_Invoice__r.Status__c, Supplier_Invoice__r.Invoice_Amount__c,
                                        Supplier_Invoice__r.Amount_Paid__c, Supplier_Invoice__r.Balance_Due__c from Supplier_Payment_Lines__r)  from Supplier_Payment__c where id = :suppPaymentData.suppPay1.id];
       System.debug(logginglevel.error,'supPaymentLst---->'+supPaymentLst);
       System.assertEquals(supPaymentLst[0].Status__c,'Cancelled','Supplier Payment is not cancelled');
       
       Id supplierInvoiceId;
       for (Supplier_Payment__c sp: supPaymentLst){
                system.assert(sp.Supplier_Payment_Lines__r.size() > 0  , 'expected  a payment');
                for (Supplier_Payment_Line__c spl : sp.Supplier_Payment_Lines__r){
                    supplierInvoiceId = spl.Supplier_Invoice__r.Id;
                    system.assert(spl.Supplier_Invoice__r.Status__c == 'Approved', '>>> spl.Supplier_Invoice__r: ' + spl.Supplier_Invoice__r);
                    system.assert(spl.Supplier_Invoice__r.Balance_Due__c == spl.Supplier_Invoice__r.Invoice_Amount__c, '>>> spl.Supplier_Invoice__r: ' + spl.Supplier_Invoice__r);
                    system.assert(spl.Supplier_Invoice__r.Amount_Paid__c == 0, '>>> spl.Supplier_Invoice__r: ' + spl.Supplier_Invoice__r);
                }
            }
       test.stopTest();
        
      List<Supplier_invoice__c> suppInvAfterCancelList1 = [Select id, Name , Supplier_and_Invoice__c, status__c,Purchase_Order__c,Balance_Due__c,
                                                            (Select Id,Invoice_Quantity__c,Invoice_Quantity_To_Stock__c,Matched__c,Finalized__c,Purchase_Order_Line__c from Supplier_Invoice_Lines__r)
                                                    from supplier_invoice__c where id = :supplierInvoiceId];
        
        System.debug(logginglevel.error,'suppInvAfterCancelList1---->'+suppInvAfterCancelList1);
        
        system.assertEquals(1, suppInvAfterCancelList1.size());
        system.assert(suppInvAfterCancelList1[0].status__c == 'Approved', 'The SI should be in cancelled status'); 
        system.assertEquals(160, suppInvAfterCancelList1[0].Balance_Due__c);
        
        List<Id> polIdList = new List<Id>();
        for(Supplier_Invoice__c si : suppInvAfterCancelList1){
            for(Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){ 
               polIdList.add(sil.Purchase_Order_Line__c);
               System.debug(logginglevel.error,'polIdList-->'+polIdList);
               System.debug(logginglevel.error,'sil-->'+sil);
               system.assert(sil.Matched__c == false, 'The SIL matched should be false');
               system.assert(sil.Finalized__c == true, 'The SIL finalized should be true');
               
           }
        }
      
        List<Purchase_Order_Line__c> poLineListData = [Select id, Name, Item__c,Order_Quantity__c,Quantity_Matched__c,Invoice_Matching__c,Quantity_Received__c  from Purchase_Order_Line__c where Id in :polIdList];
        System.debug(logginglevel.error,'poLineListData-->'+poLineListData);
        for(Purchase_Order_Line__c pol : poLineListData){
            if(pol.Invoice_Matching__c == 'Two Way'){
              system.assert(pol.Quantity_Matched__c == 0, 'The Quantity matched should be 0');
              system.assert(pol.Quantity_Received__c == 0, 'The Quantity received should be 0 on 2-way matching');
            }else{
              system.assert(pol.Quantity_Matched__c == 0, 'The Quantity matched should be 0');
              system.assert(pol.Quantity_Received__c <> 0, 'The Quantity received should not be 0 on 3-way matching');
            }  
        } 
     }      
    
    static testMethod void testVoidAccounting() {
        List<Supplier_Invoice__c> sis = testVoidSP_WithAccounting(suppPaymentData.suppPay1);
        
        // Amount Paid on SI should decrease, balance due on SI should increase
        for (Supplier_Invoice__c si : sis){
             if (si.Id != suppPaymentData.suppInv1.Id){
                continue;
            }
            system.assert(si.Status__c != 'Closed', '>>> si: ' + si);
            system.assert(si.Status__c == 'Approved', '>>> si: ' + si);
            system.assert(si.Amount_Paid__c == 0, '>>> si: ' + si);
            system.assert(si.Balance_Due__c == 160, '>>> si: ' + si);
        }
    }
    
    static testMethod void testVoidPrepayamentSP_Paid() {
        List<Supplier_Invoice__c> sis = testVoidSP_WithAccounting(suppPaymentData.prepaymentSP);
        for (Supplier_Invoice__c si : sis){
            if (si.Id != suppPaymentData.prepaymentSI.Id){
                continue;
            }
            system.assert(si.Status__c != 'Closed', '>>> si: ' + si);
            system.assert(si.Status__c == 'Approved', '>>> si: ' + si);
            system.assert(si.Amount_Paid__c == 0, '>>> si: ' + si);
            system.assert(si.Balance_Due__c == 10, '>>> si: ' + si);
        }
    }
    
    static testMethod void testCancelPrepayamentSP_Paid() {
        List<Supplier_Invoice__c> sis = testCancelSP_WithAccounting(suppPaymentData.prepaymentSP);
        for (Supplier_Invoice__c si : sis){
            if (si.Id != suppPaymentData.prepaymentSI.Id){
                continue;
            }
            system.assert(si.Status__c != 'Closed', '>>> si: ' + si);
            system.assert(si.Status__c == 'Approved', '>>> si: ' + si);
            system.assert(si.Amount_Paid__c == 0, '>>> si: ' + si);
            system.assert(si.Balance_Due__c == 10, '>>> si: ' + si);
        }
    }
    
    static testMethod void testVoidSP_withPrepayamentApplied() {
        system.assert(suppPaymentData.prepaymentSI2.Credit_Memo_Balance__c == 0);
        List<Supplier_Invoice__c> sis = testVoidSP_WithAccounting(suppPaymentData.prepaymentAppliedSP);
        for (Supplier_Invoice__c si : sis){
            if (si.Id == suppPaymentData.appliedPrepaymentSI.Id){
                system.assert(si.Status__c != 'Closed', '>>> si: ' + si);
                system.assert(si.Status__c == 'Approved', '>>> si: ' + si);
                system.assert(si.Amount_Paid__c == 0, '>>> si: ' + si);
                system.assert(si.Balance_Due__c == 100, '>>> si: ' + si);
            }
            else  if (si.Id == suppPaymentData.prepaymentSI2.Id){
                system.assert(si.Status__c == 'Closed', '>>> si: ' + si);
                system.assert(si.Amount_Paid__c == 11, '>>> si: ' + si);
                system.assert(si.Balance_Due__c == 0, '>>> si: ' + si);
                system.assert(si.Credit_Memo_Balance__c == -11, '>>> si: ' + si);
            }
        }
    }

    static testMethod void testVoidSP_AfterPrepaymentIsApplied_Invalid() {//KNDY-13654
        system.assert(suppPaymentData.prepaymentSI2.Credit_Memo_Balance__c == 0);
        system.assert(suppPaymentData.prepaymentSI2.Credit_Memo_Balance__c !=
                      suppPaymentData.prepaymentSI2.Credit_Memo_Amount__c);
        // Assumption - SP has been applied to pay other invoices
        Supplier_Payment__c sp = suppPaymentData.prepaymentSP2;
        
        test.startTest();  
        // Void the SP
        Test.setCurrentPage( Page.SupplierPaymentVoidCancel);
        Apexpages.standardcontroller SPcon = new Apexpages.Standardcontroller(sp);
        SupplierPaymentVoidCancelExt ext = new SupplierPaymentVoidCancelExt(SPcon);
        VoidCancelService.VoidCancelDetail vcd = ext.getVoidCancelDetails();
        system.assertEquals(vcd.isVoidable, false, '>>> vcd: ' + vcd);
        // Will contain other void errors such as no Accounting Entries
        system.assert ( vcd.voidMessages.size() != 0, '>>>vcd: ' + vcd);
        Boolean cannotVoid = false;
        for(String msg :  vcd.voidMessages) {
            if( msg == Label.SP_Void_is_not_allowed ){
                cannotVoid = true;
            }
        }
        system.assertEquals(cannotVoid, true, '>>>vcd: ' + vcd);
        Test.stopTest();
    }
    
    private static List<Supplier_Invoice__c> testVoidSP_WithAccounting(Supplier_Payment__c sp) {
        test.startTest();  
        Test.setCurrentPage( Page.AccountingEntryGenerate);
        Apexpages.currentPage().getParameters().put('id', sp.Id);
        
        // Generate Accounting Entries for SP
        SourceDocumentAccountingCon con = new SourceDocumentAccountingCon();
        con.populateSobjDetails();
        list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
        integer i=0;
        
        for(map<string,string> m:chunks)
        {
            SourceDocumentAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.getguid(),con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
            i++;
        }
        
        // Void the SP
        Test.setCurrentPage( Page.SupplierPaymentVoidCancel);
        SupplierPaymentVoidCancelService vcs = new SupplierPaymentVoidCancelService(new List<Supplier_Payment__c>{sp});
        Map<Id, VoidCancelService.VoidCancelDetail> vcdMap = vcs.getBusinessVoidCancelDetails(new list<sObject>{(sobject) sp});
        
        Apexpages.standardcontroller SPcon = new Apexpages.Standardcontroller(sp);
        SupplierPaymentVoidCancelExt ext = new SupplierPaymentVoidCancelExt(SPcon);
        ext.prepreVoid();
        list<map<string,string>> reverseChunks =(list<map<string,string>>)JSON.deserialize(ext.reverseChunkMap, list<map<string,string>>.class);
        
        integer irev=0;
        for(map<string,string> m:reverseChunks)
        {
            VoidCancelBaseExt.reverseAE(ext.voidAEId,irev,reverseChunks.size(),m.get('min'),m.get('max'),true,con.getguid());
            i++;
        }
        VoidCancelBaseExt.ActualVoidSD(new List<Supplier_Payment__c>{sp}, con.getguid());
        test.stopTest();
        
        List<Supplier_Invoice__c> sis = [Select Id, Amount_Paid__c, Balance_Due__c, 
                    Credit_Memo_Balance__c, Status__c, Credit_Memo_Amount__c from
                    Supplier_Invoice__c where Id in :suppPaymentData.suppInvAEList];
        return sis;
    }
    
     private static List<Supplier_Invoice__c> testCancelSP_WithAccounting(Supplier_Payment__c sp) {
        test.startTest();  
        Test.setCurrentPage( Page.AccountingEntryGenerate);
        Apexpages.currentPage().getParameters().put('id', sp.Id);
        
        // Generate Accounting Entries for SP
        SourceDocumentAccountingCon con = new SourceDocumentAccountingCon();
        con.populateSobjDetails();
        list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
        integer i=0;
        
        for(map<string,string> m:chunks)
        {
            SourceDocumentAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.getguid(),con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
            i++;
        }
        
        // Cancel the SP
        Test.setCurrentPage( Page.SupplierPaymentVoidCancel);
        SupplierPaymentVoidCancelService vcs = new SupplierPaymentVoidCancelService(new List<Supplier_Payment__c>{sp});
        Map<Id, VoidCancelService.VoidCancelDetail> vcdMap = vcs.getBusinessVoidCancelDetails(new list<sObject>{(sobject) sp});
        
        Apexpages.standardcontroller SPcon = new Apexpages.Standardcontroller(sp);
        SupplierPaymentVoidCancelExt ext = new SupplierPaymentVoidCancelExt(SPcon);
        ext.cancelDocs();
        
        test.stopTest();
        
        List<Supplier_Invoice__c> sis = [Select Id, Amount_Paid__c, Balance_Due__c, 
                    Credit_Memo_Balance__c, Status__c, Credit_Memo_Amount__c from
                    Supplier_Invoice__c where Id in :suppPaymentData.suppInvAEList];
        return sis;
    }
    
    static testMethod void testCancelSP_withPrepayamentApplied() {
        system.assert(suppPaymentData.prepaymentSI2.Credit_Memo_Balance__c == 0);
        List<Supplier_Invoice__c> sis = testCancelSP_WithAccounting(suppPaymentData.prepaymentAppliedSP);
        for (Supplier_Invoice__c si : sis){
            if (si.Id == suppPaymentData.appliedPrepaymentSI.Id){
                system.assert(si.Status__c != 'Closed', '>>> si: ' + si);
                system.assert(si.Status__c == 'Approved', '>>> si: ' + si);
                system.assert(si.Amount_Paid__c == 0, '>>> si: ' + si);
                system.assert(si.Balance_Due__c == 100, '>>> si: ' + si);
            }
            else  if (si.Id == suppPaymentData.prepaymentSI2.Id){
                system.assert(si.Status__c == 'Closed', '>>> si: ' + si);
                system.assert(si.Amount_Paid__c == 11, '>>> si: ' + si);
                system.assert(si.Balance_Due__c == 0, '>>> si: ' + si);
                system.assert(si.Credit_Memo_Balance__c == -11, '>>> si: ' + si);
            }
        }
    }
}