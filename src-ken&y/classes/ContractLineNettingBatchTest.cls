@isTest
private class ContractLineNettingBatchTest {
    private static SchemaUtil queryutil = SchemaUtil.getInstance();
    
    class ContractLinesNettingTestData{
        public SKIDServiceTest.TestDataForSkidService sstestData = new SKIDServiceTest.TestDataForSkidService();
        
        //Create a GL Type
        public GL_Type__c testGLT = new GL_Type__c();{
            testGLT.Name  = 'Current Assets';
            testGLT.Normal_Balance__c  = 'Debit';
            testGLT.Accounting_Type__c  = 'Assets';
            testGLT.Statement_Type__c  = 'Balance Sheet';
            testGLT.Account_Range_From__c = '10000';
            testGLT.Account_Range_To__c ='14999';
            insert testGLT;
        }
        
        //Create a GL Account
        public GL_Account__c glaccount = new GL_Account__c();{
            
            glaccount.Name = 'testglaccount';
            glaccount.GL_Account_Number__c = '10000';
            glaccount.GL_Account_Name__c = 'Current Assets';
            glaccount.GL_Type__c = testGLT.id;
            glaccount.Active__c = true;
            insert glaccount;
        }
        
        public segment_validation__c segval = new segment_validation__c();{
            segval.segment_1__c = '*';
            segval.segment_2__c = '*';
            segval.active__c = true;
            insert segval;
        }
        
        //Create payment terms info
        public Payment_Term__c paymentTermInfo = new Payment_Term__c();{
            paymentTermInfo.Name = '2/10 Net 30';
            paymentTermInfo.Description__c = '2% discount in 10 days, due 30 days';
            paymentTermInfo.Discount_Days__c = 10;
            paymentTermInfo.Discount_Percent__c = 2.0;
            paymentTermInfo.Due_Days__c = 30;
            insert paymentTermInfo;
        }
        
        public FOB_Terms__c fobTerms = new FOB_Terms__c();{
            fobTerms.name = 'FOB Term 1';
            insert fobTerms;
        }
        
        public UOM__c uomEach = new UOM__c();{
            uomEach.name = 'EA';
            insert uomEach;
        }
        
        User_Preference__c up = new User_Preference__c();{
            up.Default_Company__c = sstestData.company.id;
            up.ownerID = userinfo.getUserID();
            up.Default_Facility__c = sstestData.facility.Id;
            insert up;
        }
        
        public map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c'); 
        
        //Create Supplier, assign remit and payment terms info
        public Supplier__c remittosupplier = new Supplier__c();{
            remittosupplier.Name = 'Test Remit To';
            remittosupplier.Payment_Term__c = paymentTermInfo.Id;
            remittosupplier.Status__c = 'Active';
            remittosupplier.Type__c = 'Remit-To';
            remittosupplier.RecordTypeId = rtMap.get('Remit_To');
            remittosupplier.company__c = sstestData.company.id;
            insert remittosupplier;
        }
        
        public Supplier__c supplier = new Supplier__c();{
            supplier.Name = 'Test';
            supplier.Payment_Term__c = paymentTermInfo.Id;
            supplier.Status__c = 'Active';
            supplier.Type__c = 'Purchasing';
            supplier.RecordTypeId = rtMap.get('Purchase_From');
            supplier.Remit_To__c =  remittosupplier.id;
            supplier.company__c = sstestData.company.id;
            insert supplier;
        }
        
        public Class__c miscClass = new Class__c();{
            
            miscClass.Name = 'Class Misc';
            miscClass.Type__c = 'Miscellaneous';
            insert miscClass;
        }
        
        public Class__c regClass = new Class__c();{
            
            regClass.Name = 'Class Reg';
            regClass.Type__c = 'Services';
            insert regClass;
        }
        
        //Create an item
        
            Item__c item = new Item__c();{
            item.Name = 'testitem';
            item.Active__c = true;
            item.Class__c = regClass.id;
            item.Source__c = 'Services';
            item.Company__c = sstestData.company.Id;
            item.Stocking_UOM__c = uomEach.Id;
            item.Packaging_UOM__c = JSON.serialize(new List<Id>{ uomEach.Id });
            insert item;    
            }
            
            Item__c item2 = new Item__c();{
            item2.Name = 'testitemmisc';
            item2.Active__c = true;
            item.Class__c = miscClass.id;
            item2.Company__c = sstestData.company.Id;
            item2.Source__c = 'Miscellaneous';
            item2.Non_Inventory__c = true;
            item2.Stocking_UOM__c = uomEach.Id;
            item2.Packaging_UOM__c = JSON.serialize(new List<Id>{ uomEach.Id });
            insert item2;
            }
        
       //Contract
        Contract__c contract = new Contract__c();{
        contract.Name = 'TestContract';
        contract.Contract_Start__c = Date.today().addDays(-1);
        contract.Contract_End__c = Date.today().addDays(4);
        contract.OwnerID = System.Userinfo.getUserId();
        contract.Status__c = 'Open';
        contract.Supplier__c = supplier.id;
        contract.Company__c = sstestData.company.Id;
        contract.Approval_Status__c = 'Approved';
        contract.Currency__c =  TestFuel.currencyUSD.id;
        insert contract;
        }
        
        //Contract Item that is active
        Contract_Line__c contractLine1 = new Contract_Line__c();{
        contractLine1.Contract__c = contract.Id;
        contractLine1.Company__c = sstestData.company.Id;
        contractLine1.Item__c = item.id;
        contractLine1.Name = 'Test CTL 1';
        contractLine1.Contract_Start__c = Date.today().addDays(-1);
        contractLine1.Contract_End__c = Date.today().addDays(4);
        contractLine1.Status__c = 'Open';
        contractLine1.Negotiated_Price__c = 10;
        contractLine1.Contract_Quantity__c = 100;
        contractline1.Quantity_Still_Due__c = 0;
        contractLine1.Type__c = 'Fixed';
        contractLine1.Purchased_Quantity__c = 0;
        contractLine1.Purchase_UOM__c = uomEach.Id;
        insert contractLine1;
        }
        List< Contract_Line__c > clList = new List< Contract_Line__c >();
        { 
            clList.add( contractLine1 );
            
        }

        public Configuration__c rf = new Configuration__c();{
            rf.name = 'Contract Release Field';
            rf.Value__c = 'Remaining_Quantity__c';
            insert rf;
    }
    
    }
    
    static testMethod void happyPathScenario() {
        ContractLinesNettingTestData globalTestData = new ContractLinesNettingTestData();
        
        Purchase_Order__c purchaseOrder = new Purchase_Order__c();{
        purchaseOrder.Supplier__c = globalTestData.supplier.id; 
        purchaseOrder.Company__c = globalTestData.sstestData.company.id;
        purchaseOrder.Payment_Term__c = globalTestData.paymentTermInfo.id;
        purchaseOrder.Currency__c = TestFuel.currencyUSD.id;
        insert purchaseOrder;
        }
        Purchase_Order_Line__c objPODetail = new Purchase_Order_Line__c();{
        objPODetail.Purchase_Order__c = purchaseOrder.Id;
        objPODetail.Order_Quantity__c = 10;        
        objPODetail.Unit_Price__c = 12;
        objPODetail.Item__c = globalTestData.item.Id;
        objPODetail.Company__c = globalTestData.sstestData.company.id;
        objPODetail.Need_Date__c = system.today() + 7;
        objPODetail.Contract_Line__c = globalTestData.contractLine1.id;
        objPODetail.Supplier__c = globalTestData.supplier.id; 
        insert objPODetail;
        }
        
        globalTestData.contractLine1.Purchased_Quantity__c = 0;
        update globalTestData.contractLine1;
        system.assert(globalTestData.contractLine1.Purchased_Quantity__c == 0, 'Purchased Quantity is not zeroed out.');
        contract_line__c clt = [select id, name, Purchased_Quantity__c from contract_line__c where id =:globalTestData.contractLine1.id ];
        system.assert(clt.Purchased_Quantity__c == 0, 'Purchased Quantity is not zero.');
        
        Process_Job__c job = new Process_Job__c( name= 'Contract Netting ',apex_class__c = 'ContractLineNettingBatch'    ,   batch_size__c = 25, Company__c = globalTestData.sstestData.company.id,
                                        Description__c = 'Recalculates the netting buckets on a contract line ',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = true );
        
        insert Job;
        
        Process_Job__c QueriedJob = [select id, ownerid, active__c, namespace__c, frequency__c, interval__c, name,  Batch_Size__c, Description__c, Preferred_Run_Hour__c, Process_Job_next__c, last_run__c, next_run__c, exception__c, company__c, Apex_Class__c, Facility__c   from Process_Job__c  where id=:Job.Id];
        
        ContractLineNettingBatch jpBatch = new ContractLineNettingBatch();
        Test.startTest();
        jpBatch.runBatch(QueriedJob);
        Test.stopTest();
        
        clt = [select id, Purchased_Quantity__c from Contract_Line__c where id =: globalTestData.contractLine1.id];
        system.assert(clt.Purchased_Quantity__c == 10, 'Purchased Quantity mismatch');

    }
    
    //PTP-68 Remove Active flag from Purchase Agreement
    //Check if the Line Status is set to Expired when the end date < today
    static testMethod void test_LineStatusExpired() {
        
        ContractLinesNettingTestData globalTestData = new ContractLinesNettingTestData();
        globalTestData.contract.Contract_Start__c = Date.today().addDays(-10);
        globalTestData.contract.Contract_End__c = Date.today().addDays(-2);
        update globalTestData.contract;
        
        globalTestData.contractLine1.Contract_Start__c = Date.today().addDays(-10);
        globalTestData.contractLine1.Contract_End__c = Date.today().addDays(-2);
        update globalTestData.contractLine1;
        
        Process_Job__c job = new Process_Job__c( name= 'Contract Netting ',apex_class__c = 'ContractLineNettingBatch'    ,   batch_size__c = 25, Company__c = globalTestData.sstestData.company.id,
                                        Description__c = 'Recalculates the netting buckets on a contract line ',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = true );
        
        insert Job;
        
        Process_Job__c QueriedJob = [select id, ownerid, active__c, namespace__c, frequency__c, interval__c, name,  Batch_Size__c, Description__c, Preferred_Run_Hour__c, Process_Job_next__c, last_run__c, next_run__c, exception__c, company__c, Apex_Class__c, Facility__c   from Process_Job__c  where id=:Job.Id];
        
        ContractLineNettingBatch jpBatch = new ContractLineNettingBatch();
        Test.startTest();
        jpBatch.runBatch(QueriedJob);
        Test.stopTest();
        
        contract__c c = [select id, name, Status__c from Contract__c where id = :globalTestData.Contract.id];
        contract_Line__c l = [select id, name, Status__c from Contract_Line__c where id = :globalTestData.ContractLine1.id];
        system.assertEquals(c.Status__c, 'Expired');
        system.assertEquals(l.Status__c, 'Expired');
    }   
    //PTP-141 Check for qty buckets after batch run
    static testMethod void test_QtyBucketsforPartialReceive(){
        
        ContractLinesNettingTestData globalTestData = new ContractLinesNettingTestData();
        globalTestData.ContractLine1.Negotiated_Price__c = 0.25;
        globalTestData.ContractLine1.Contract_Quantity__c = 1000;
        update globalTestData.ContractLine1;
        
        Purchase_Order__c purchaseOrder = new Purchase_Order__c();{
        purchaseOrder.Supplier__c = globalTestData.supplier.id; 
        purchaseOrder.Company__c = globalTestData.sstestData.company.id;
        purchaseOrder.Payment_Term__c = globalTestData.paymentTermInfo.id;
        purchaseOrder.Currency__c = TestFuel.currencyUSD.id;
        insert purchaseOrder;
        }
        Purchase_Order_Line__c objPODetail = new Purchase_Order_Line__c();{
        objPODetail.Purchase_Order__c = purchaseOrder.Id;
        objPODetail.Order_Quantity__c = 1000;        
        objPODetail.Unit_Price__c = 0.25;
        objPODetail.Item__c = globalTestData.item.Id;
        objPODetail.Company__c = globalTestData.sstestData.company.id;
        objPODetail.Need_Date__c = system.today() + 7;
        objPODetail.Contract_Line__c = globalTestData.contractLine1.id;
        objPODetail.Supplier__c = globalTestData.supplier.id; 
        insert objPODetail;
        }
        //Receive 700 and check for the quantity buckets
        objPODetail.Quantity_Received__c = 700;
        update objPODetail;
        
        Process_Job__c job = new Process_Job__c( name= 'Contract Netting ',apex_class__c = 'ContractLineNettingBatch'    ,   batch_size__c = 25, Company__c = globalTestData.sstestData.company.id,
                                        Description__c = 'Recalculates the netting buckets on a contract line ',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = true );
        
        insert Job;
        
        Process_Job__c QueriedJob = [select id, ownerid, active__c, namespace__c, frequency__c, interval__c, name,  Batch_Size__c, Description__c, Preferred_Run_Hour__c, Process_Job_next__c, last_run__c, next_run__c, exception__c, company__c, Apex_Class__c, Facility__c   from Process_Job__c  where id=:Job.Id];
        
        ContractLineNettingBatch jpBatch = new ContractLineNettingBatch();
        Test.startTest();
        jpBatch.runBatch(QueriedJob);
        Test.stopTest();
        contract_Line__c l = [select id, name, Status__c, Purchased_Quantity__c, PurchasedValue__c, Quantity_Received__c, Remaining_Quantity__c, Remaining_Value__c, Remaining_Value_Percent__c, ValueReceived__c from Contract_Line__c where id = :globalTestData.ContractLine1.id];
        system.assertEquals(l.Purchased_Quantity__c, 1000);
        system.assertEquals(l.PurchasedValue__c, 250);
        system.assertEquals(l.Quantity_Received__c, 700);
        system.assertEquals(l.ValueReceived__c, 175);
        system.assertEquals(l.Remaining_Quantity__c, 0);
        system.assertEquals(l.Remaining_Value__c, 0);
    }
    static testMethod void test_QtyBucketsforShortClose(){
        
        ContractLinesNettingTestData globalTestData = new ContractLinesNettingTestData();
        globalTestData.ContractLine1.Negotiated_Price__c = 0.25;
        globalTestData.ContractLine1.Contract_Quantity__c = 1000;
        update globalTestData.ContractLine1;
        
        Purchase_Order__c purchaseOrder = new Purchase_Order__c();{
        purchaseOrder.Supplier__c = globalTestData.supplier.id; 
        purchaseOrder.Company__c = globalTestData.sstestData.company.id;
        purchaseOrder.Payment_Term__c = globalTestData.paymentTermInfo.id;
        purchaseOrder.Purchase_Agreement__c = globalTestData.Contract.id;
        purchaseOrder.Currency__c = TestFuel.currencyUSD.id;
        insert purchaseOrder;
        }
        Purchase_Order_Line__c objPODetail = new Purchase_Order_Line__c();{
        objPODetail.Purchase_Order__c = purchaseOrder.Id;
        objPODetail.Order_Quantity__c = 1000;        
        objPODetail.Unit_Price__c = 0.25;
        objPODetail.Item__c = globalTestData.item.Id;
        objPODetail.Company__c = globalTestData.sstestData.company.id;
        objPODetail.Need_Date__c = system.today() + 7;
        objPODetail.Contract_Line__c = globalTestData.contractLine1.id;
        objPODetail.Supplier__c = globalTestData.supplier.id; 
        insert objPODetail;
        }
         Test.startTest();
        //Receive 700, short close the PO and check for the quantity buckets
        objPODetail.Quantity_Received__c = 700;
        objPODetail.Status__c = 'Closed';
        update objPODetail;
        
       	Process_Job__c job = new Process_Job__c( name= 'Contract Netting ',apex_class__c = 'ContractLineNettingBatch'    ,   batch_size__c = 25, Company__c = globalTestData.sstestData.company.id,
                                        Description__c = 'Recalculates the netting buckets on a contract line ',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = true );
        
        insert Job;
        
        //Process_Job__c QueriedJob = [select id, ownerid, active__c, namespace__c, frequency__c, interval__c, name,  Batch_Size__c, Description__c, Preferred_Run_Hour__c, Process_Job_next__c, last_run__c, next_run__c, exception__c, company__c, Apex_Class__c, Facility__c   from Process_Job__c  where id=:Job.Id];
        
        
        ContractLineNettingBatch jpBatch = new ContractLineNettingBatch();
       
        jpBatch.runBatch(Job);
        contract_Line__c l = [select id, name, Status__c, Purchased_Quantity__c, PurchasedValue__c, Quantity_Received__c, Remaining_Quantity__c, Remaining_Value__c, Remaining_Value_Percent__c, ValueReceived__c from Contract_Line__c where id = :globalTestData.ContractLine1.id];
        Test.stopTest();
        system.assertEquals(l.Purchased_Quantity__c, 1000);
        system.assertEquals(l.PurchasedValue__c, 250);
        system.assertEquals(l.Quantity_Received__c, 700);
        system.assertEquals(l.ValueReceived__c, 175);
        system.assertEquals(l.Remaining_Quantity__c, 300);
        system.assertEquals(l.Remaining_Value__c, 75);
        system.assertEquals(l.Status__c, 'Open'); //Contract Line must be open when Remaining Qty is changed
    }
    
    //KNDY-6559 Over Receive PO Line and calculate Netting
    static testMethod void test_QtyBucketsAfterOverReceivingPOLine(){
        
        ContractLinesNettingTestData globalTestData = new ContractLinesNettingTestData();
        Test.startTest();
        
        globalTestData.ContractLine1.Negotiated_Price__c = 0.25;
        globalTestData.ContractLine1.Contract_Quantity__c = 10000;
        update globalTestData.ContractLine1;
        
        ApexPages.StandardController setCon = new Apexpages.StandardController(globalTestData.ContractLine1); 
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);
        id cltid = globalTestData.ContractLine1.id;
        contract_line__c clt = fetchPurchaseAgreementLines( cltid);
        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 1000;
        }
        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{ 
            ctLineWrappers.add( ctlineWrapper );
            
        }
        
        List<Purchase_Order__c> poList = [select id from Purchase_Order__c where company__c = :globalTestData.sstestData.company.id];
        system.assertEquals(0, poList.size());
        
        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(globalTestData.sstestData.company.id, globalTestData.sstestData.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);
        
        globalTestData.sstestData.facility.Default_Purchasing_Delivery_Location__c = globalTestData.sstestData.locationList[0].id;
        update globalTestData.sstestData.facility;
        
        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(globalTestData.sstestData.company.id, globalTestData.sstestData.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        
        poList = [select id, supplier__c, name, Delivery_Facility__c, status__c, Currency__c, Approval_Status__c, Purchase_Agreement__c, Currency__r.ISO_Code__c from Purchase_Order__c where company__c = :globalTestData.sstestData.company.id];
        system.assertEquals(1, poList.size());
        List<Purchase_Order_Line__c> poLineList = [select id, name, Order_Quantity__c, Quantity_Returned_to_Supplier__c, Quantity_Received__c, Quantity_Still_Due__c, Quantity_Returned_to_Supplier_for_Credit__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c = :poList[0].id];
        system.assertEquals(1, poLineList.size());
        system.assertEquals('USD', poList[0].Currency__r.ISO_Code__c);
        
        //Receive 1100 and check for the quantity buckets
        poLineList[0].Quantity_Received__c = 1100;
        update poLineList[0];
        system.assertEquals(1000, poLineList[0].Order_Quantity__c);
        system.assertEquals(1100, poLineList[0].Quantity_Received__c);
        system.assertEquals(1000, poLineList[0].Quantity_Still_Due__c);
        
                
        contract_Line__c clineDetail = [select id, name, Status__c, Purchased_Quantity__c, PurchasedValue__c, Quantity_Received__c, Remaining_Quantity__c, Remaining_Value__c, Remaining_Value_Percent__c, ValueReceived__c from Contract_Line__c where id = :globalTestData.ContractLine1.id];
        system.assertEquals(clineDetail.Purchased_Quantity__c, 1000);
        system.assertEquals(clineDetail.PurchasedValue__c, 250);
        system.assertEquals(clineDetail.Quantity_Received__c, 1100);
        system.assertEquals(clineDetail.ValueReceived__c, 275);
        system.assertEquals(clineDetail.Remaining_Quantity__c, 8900);
        
        
        Process_Job__c job = new Process_Job__c( name= 'Contract Netting ',apex_class__c = 'ContractLineNettingBatch'    ,   batch_size__c = 25, Company__c = globalTestData.sstestData.company.id,
                                        Description__c = 'Recalculates the netting buckets on a contract line ',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = true );
        
        insert Job;
        
        Process_Job__c QueriedJob = [select id, ownerid, active__c, namespace__c, frequency__c, interval__c, name,  Batch_Size__c, Description__c, Preferred_Run_Hour__c, Process_Job_next__c, last_run__c, next_run__c, exception__c, company__c, Apex_Class__c, Facility__c   from Process_Job__c  where id=:Job.Id];
        
        ContractLineNettingBatch jpBatch = new ContractLineNettingBatch();
        jpBatch.runBatch(QueriedJob);
        Test.stopTest();
        clineDetail = [select id, name, Purchased_Quantity__c, PurchasedValue__c, Quantity_Received__c, Remaining_Quantity__c, ValueReceived__c from Contract_Line__c where id = :globalTestData.ContractLine1.id];
        system.assertEquals(clineDetail.Purchased_Quantity__c, 1000);
        system.assertEquals(clineDetail.PurchasedValue__c, 250);
        system.assertEquals(clineDetail.Quantity_Received__c, 1100);
        system.assertEquals(clineDetail.ValueReceived__c, 275);
        system.assertEquals(clineDetail.Remaining_Quantity__c, 8900);
        
    }
    
    //KNDY-6559 Under Receive PO Line, short close and calculate Netting
    static testMethod void test_QtyBucketsAfterUnderReceivingPOLineAndShortCloseit(){
        
        ContractLinesNettingTestData globalTestData = new ContractLinesNettingTestData();
        
        globalTestData.ContractLine1.Negotiated_Price__c = 0.25;
        globalTestData.ContractLine1.Contract_Quantity__c = 10000;
        update globalTestData.ContractLine1;
        
        ApexPages.StandardController setCon = new Apexpages.StandardController(globalTestData.ContractLine1); 
        ContractLinesReleaseExtension clre = new ContractLinesReleaseExtension(setCon);
        id cltid = globalTestData.ContractLine1.id;
        contract_line__c clt = fetchPurchaseAgreementLines( cltid);
        ContractLinesReleaseExtension.ContractLineWrapper ctlineWrapper = new ContractLinesReleaseExtension.ContractLineWrapper();{
            ctlineWrapper.ctLine = clt;
            ctlineWrapper.needDate = Date.today();
            ctlineWrapper.quantityToRelease = 1000;
        }
        List<ContractLinesReleaseExtension.ContractLineWrapper> ctLineWrappers = new List<ContractLinesReleaseExtension.ContractLineWrapper>();{ 
            ctLineWrappers.add( ctlineWrapper );
            
        }
        
        List<Purchase_Order__c> poList = [select id from Purchase_Order__c where company__c = :globalTestData.sstestData.company.id];
        system.assertEquals(0, poList.size());
        
        JsonResult resultPOFailed = ContractLinesReleaseExtension.releaseContractLines(globalTestData.sstestData.company.id, globalTestData.sstestData.facility.Id, ctLineWrappers);
        system.assertEquals(false, resultPOFailed.success);
        
        globalTestData.sstestData.facility.Default_Purchasing_Delivery_Location__c = globalTestData.sstestData.locationList[0].id;
        update globalTestData.sstestData.facility;
        Test.startTest();
        JsonResult resultPO = ContractLinesReleaseExtension.releaseContractLines(globalTestData.sstestData.company.id, globalTestData.sstestData.facility.Id, ctLineWrappers);
        system.assertEquals(true, resultPO.success);
        
        poList = [select id, supplier__c, name, Delivery_Facility__c, status__c, Approval_Status__c, Purchase_Agreement__c from Purchase_Order__c where company__c = :globalTestData.sstestData.company.id];
        system.assertEquals(1, poList.size());
        List<Purchase_Order_Line__c> poLineList = [select id, name, Order_Quantity__c, Quantity_Returned_to_Supplier__c, Quantity_Received__c, Quantity_Still_Due__c, Quantity_Returned_to_Supplier_for_Credit__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c = :poList[0].id];
        system.assertEquals(1, poLineList.size());
       
        //Receive 1100 and check for the quantity buckets
        poLineList[0].Quantity_Received__c = 800;
        update poLineList[0];
        poLineList = [select id, name, Order_Quantity__c, Quantity_Returned_to_Supplier__c, Quantity_Received__c, Quantity_Still_Due__c, Quantity_Returned_to_Supplier_for_Credit__c, Unit_Price__c from Purchase_Order_Line__c where purchase_order__c = :poList[0].id];
        system.assertEquals(1000, poLineList[0].Order_Quantity__c);
        system.assertEquals(800, poLineList[0].Quantity_Received__c);
        system.assertEquals(200, poLineList[0].Quantity_Still_Due__c);
        
        /* KNDY-13591 - commenting this as the class is deprecated
        PurchaseOrderLinesAddManageExt poc = new PurchaseOrderLinesAddManageExt(new apexpages.standardController(poList[0]));
        Apexpages.currentPage().getParameters().put('selected_indexes','0');
        poc.poLineList[0].poLine.Short_Close__c = true; 
        system.assert(poc.saveAndReturn()!=null, ' expected record id');
        */
        poLineList[0].Short_Close__c = true;
        poLineList[0].Status__c = 'Closed';
        update poLineList[0];
        
        //poLineList[0].Short_Close__c = true; //Quantity still Due should go to 0 at this point.
        //update poLineList[0];
        
                
        contract_Line__c clineDetail = [select id, name, Status__c, Purchased_Quantity__c, PurchasedValue__c, Quantity_Received__c, Remaining_Quantity__c, Remaining_Value__c, Remaining_Value_Percent__c, ValueReceived__c from Contract_Line__c where id = :globalTestData.ContractLine1.id];
        system.assertEquals(clineDetail.Purchased_Quantity__c, 800);
        system.assertEquals(clineDetail.PurchasedValue__c, 200);
        system.assertEquals(clineDetail.Quantity_Received__c, 800);
        system.assertEquals(clineDetail.ValueReceived__c, 200);
        system.assertEquals(clineDetail.Remaining_Quantity__c, 9200);
        
        
        Process_Job__c job = new Process_Job__c( name= 'Contract Netting ',apex_class__c = 'ContractLineNettingBatch'    ,   batch_size__c = 25, Company__c = globalTestData.sstestData.company.id,
                                        Description__c = 'Recalculates the netting buckets on a contract line ',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = true );
        
        insert Job;
        
        Process_Job__c QueriedJob = [select id, ownerid, active__c, namespace__c, frequency__c, interval__c, name,  Batch_Size__c, Description__c, Preferred_Run_Hour__c, Process_Job_next__c, last_run__c, next_run__c, exception__c, company__c, Apex_Class__c, Facility__c   from Process_Job__c  where id=:Job.Id];
        
        ContractLineNettingBatch jpBatch = new ContractLineNettingBatch();
        jpBatch.runBatch(QueriedJob);
        Test.stopTest();
        clineDetail = [select id, name, Purchased_Quantity__c, PurchasedValue__c, Quantity_Received__c, Remaining_Quantity__c, ValueReceived__c from Contract_Line__c where id = :globalTestData.ContractLine1.id];
        system.assertEquals(clineDetail.Purchased_Quantity__c, 800);
        system.assertEquals(clineDetail.PurchasedValue__c, 200);
        system.assertEquals(clineDetail.Quantity_Received__c, 800);
        system.assertEquals(clineDetail.ValueReceived__c, 200);
        system.assertEquals(clineDetail.Remaining_Quantity__c, 9200);
        
    }
    
    private static Contract_Line__c fetchPurchaseAgreementLines( id paid )  {
        Contract_Line__c paLine =  database.query( 
                    queryutil.generateQueryFromFieldSet('Contract_Line__c', 
                        new set<string>{'Line_Release', 'Tiers', 'Extended_Tiers'},
                        new set<string>{'Id', 'Invoice_Matching__c','Line__c','UOM__c','Contract__r.Company__c','Contract_Quantity__c', 'Location__c', 'Quantity_Still_Due__c',
                            'Purchased_Quantity__c', 'PurchasedValue__c','Quantity_Received__c','Remaining_Quantity__c','Remaining_Value__c','Remaining_Value_Percent__c','Status__c',
                            'ValueReceived__c','Contract__r.Payment_Term__c', 'Contract__r.Payment_Term__r.id', 'Contract__r.FOB_Term__c', 'Contract__r.FOB_Term__r.id', 'Item__c', 'Item__r.Description__c', 'Contract__r.Supplier__c', 
                            'Item__r.Buyer_Planner__c','Item__r.Purchasing_UOM__c', 'Contract__r.Transportation_Mode__c', 'Consigned__c', 'Type__c', 'Contract__r.Contract_Number__c', 'Status__c', 'Contract__c', 'Contract__r.Supplier__r.Remit_To__c','Contract__r.Currency__c',
                            'Contract__r.Unit_Price_Tolerance_Over__c','Contract__r.Quantity_Tolerance_Over__c','Contract__r.Amount_Tolerance__c','Contract__r.Supplier__r.Default_Receiving_Tolerance__c'},
                        '  id =:paid  order by Line__c asc limit 1' )) ;
        return paLine ;
    }
}