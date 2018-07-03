@isTest 
public with sharing class SupplierInvoiceVoidCancelTest {
	
	static TestDataForFinance data = new TestDataForFinance();
        
    public class SupplierInvoiceData{
        Accounting_Default__c testDefault = new Accounting_Default__c();{
        	testDefault.Company__c = data.company.id;
        	testDefault.GL_Account__c = data.Acctdata.CashGl.id;
            DML.insertAsUser( new list<sobject>{testDefault} );//KNDY-1751
        }
        
        
        List<Purchase_Order__c> poList = [Select   p.Supplier__c,         p.Status__c, 
                                p.Payment_Term__c, p.Order_Date__c, 
                                p.Name, p.Id, p.Deliver_to__c, p.Date_Closed__c, 
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
                                where p.id in (:data.purchaseOrder2.id)];
                                
        public List<Supplier_Invoice_Line__c> suppInvLineList = new List<Supplier_Invoice_Line__c>();
        
        public Supplier_Invoice__c suppInv1, suppInv2,suppInv3,suppInv4;
        
        List<Supplier_Invoice__c> suppInvAEList = new List<Supplier_Invoice__c>();{
            suppInv1 = new Supplier_Invoice__c();
            suppInv1.Company__c = data.company.id;
            suppInv1.Invoice_Type__c = 'Invoice';
            suppInv1.Date_Invoiced__c = System.now();
            suppInv1.transaction_date__c = system.now();
            suppInv1.Currency__c = TestFuel.currencyUSD.id;
            suppInv1.Supplier__c = data.remittosupplier.id;
            //suppInv1.Amount_Due__c = data.purchaseOrder2.Purchase_Order_Value__c;
            suppInv1.Invoice_Amount__c = 160;
            suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
            suppInv1.Finalized__c = false;
            suppInv1.Void__c = false;
            suppInv1.historical__c = false;
            suppInv1.Payment_Term__c = data.terms.id;
            //suppInv1.status__c = 'draft';
            suppInvAEList.add(suppInv1);
            
            DML.insertAsUser( suppInvAEList );
            //insert suppInvAEList;
        }
        
        //List<Purchase_Order_Line__c> poLineList = [Select id, Name, Item__c from Purchase_Order_Line__c where Purchase_Order__c in (:data.purchaseOrder2.id, :data.purchaseOrder3.id, :data.purchaseOrder4.id)];
        List<Purchase_Order_Line__c> poLineList = [Select id, Name, Item__c,Invoice_Matching__c,Purchase_Order__c, Quantity_Received__c from Purchase_Order_Line__c where Purchase_Order__c = :data.purchaseOrder2.id];
        
      
        
       
        Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); {
            //suppInvLine1.Supplier__c = data.remittosupplier.id;
            suppInvLine1.Supplier_Invoice__c = suppInvAEList[0].id;
            suppInvLine1.Extended_Cost__c = 50;
            
            suppInvLine1.Item__c = data.itemList[0].id;
            //suppInvLine1.Location__c = data.location.id;
            suppInvLine1.Purchase_Order__c = data.purchaseOrder2.id;
            suppInvLine1.Purchase_Order_Line__c = poLineList[0].id;
            suppInvLine1.Invoice_Quantity__c = 4;
            suppInvLine1.Unit_Price__c = 25; 
            suppInvLine1.Line_Type__c = 'Item';
            suppInvLineList.add(suppInvLine1);
            
            Supplier_Invoice_Line__c suppInvLine2 = new Supplier_Invoice_Line__c();
            //suppInvLine2.Supplier__c = data.remittosupplier.id;
            suppInvLine2.Supplier_Invoice__c = suppInvAEList[0].id;
            suppInvLine2.Extended_Cost__c = 50;
            suppInvLine2.Invoice_Quantity__c = 4;
            suppInvLine2.Item__c = data.itemList[0].id;
            //suppInvLine2.Location__c = data.location.id;
            suppInvLine2.Purchase_Order__c = data.purchaseOrder2.id;
            suppInvLine2.Purchase_Order_Line__c = poLineList[1].id;
            suppInvLine2.Unit_Price__c = 15; 
            suppInvLine2.Line_Type__c = 'Item';
            suppInvLineList.add(suppInvLine2);
    
            DML.insertAsUser( suppInvLineList );
            suppInv1.Finalized__c = true;
            
            DML.allowUpdateFields( new list<string>{'Finalized__c'}, Supplier_Invoice__c.SObjectType );
            DML.sobjectUpdate( suppInvAEList );    
            
        }
    }
    		
   static testMethod void testCancel_for2wayand3way() {
      
		SupplierInvoiceData suppInvData = new SupplierInvoiceData();
        test.startTest();

        
        List<Supplier_invoice__c> suppInvList = [Select id, Name , finalized__c, finalized_date__c, transaction_date__c, posting_date__c, historical__c, status__c, void__c,has_exceptions__c,exceptions_count__c,line_exceptions_count__c
                                                    from supplier_invoice__c where id = :suppInvData.suppInv1.id];
        
        
        //doing the inspect on SI
        for(Supplier_invoice__c si: suppInvList){
            SupplierInvoiceService.inspectSI(si.Id);
        }    
        List<Supplier_invoice__c> suppInvListAfterInspect = [Select id, Name , finalized__c, finalized_date__c, transaction_date__c, posting_date__c, historical__c, status__c, void__c,has_exceptions__c,exceptions_count__c,line_exceptions_count__c
        											from supplier_invoice__c where id = :suppInvData.suppInv1.id];
        System.debug(logginglevel.error,'suppInvListAfterInspect---->'+suppInvListAfterInspect);
        
        List<Supplier_invoice_line__c> suppInvLineafterInspectLst = [Select Id,Invoice_Quantity__c,Invoice_Quantity_To_Stock__c,Matched__c,Finalized__c,Purchase_Order_Line__c, Purchase_Order_Line__r.Invoice_Matching__c from Supplier_Invoice_Line__c
                                                                  where Supplier_invoice__c = :suppInvData.suppInv1.id];
        List<Id> silIds = new List<Id>();
        system.debug(logginglevel.ERROR, 'poLineList '+[Select id, Name, Item__c,Invoice_Matching__c,Purchase_Order__c, Quantity_Received__c from Purchase_Order_Line__c where Purchase_Order__c = :data.purchaseOrder2.id]); 
        
        for(Supplier_invoice_line__c sil : suppInvLineafterInspectLst){
            silIds.add(sil.Id);
            system.debug(logginglevel.ERROR,'sil '+sil.id +' '+sil.Purchase_Order_Line__r.Invoice_Matching__c +'pol '+sil.Purchase_Order_Line__c);
        }
        List<Task> silexceptions = [SELECT Id, Subject, Status, Exception_Code__c, 
                    Description, WhatId, OwnerId FROM Task  WHERE WhatId in :silIds];
                    
        System.debug(logginglevel.error,'silexceptions---->'+silexceptions);
         
        system.assert(suppInvListAfterInspect[0].status__c == 'Approved', 'The SI should be in Approved status '+silexceptions); 
      
		SupplierInvoiceVoidCancelService vcs = new SupplierInvoiceVoidCancelService(suppInvList);
	
		vcs.getBusinessVoidCancelDetails(suppInvList);
		vcs.cancelSourceDocuments(suppInvList);
        test.stopTest();
        
        List<Supplier_invoice__c> suppInvAfterCancelList1 = [Select id, Name , Supplier_and_Invoice__c, status__c,Purchase_Order__c,Balance_Due__c,
                                                            (Select Id,Invoice_Quantity__c,Invoice_Quantity_To_Stock__c,Matched__c,Finalized__c,Purchase_Order_Line__c from Supplier_Invoice_Lines__r)
        											from supplier_invoice__c where id = :suppInvData.suppInv1.id];
        
        System.debug(logginglevel.error,'suppInvAfterCancelList1---->'+suppInvAfterCancelList1);
        
        system.assertEquals(1, suppInvAfterCancelList1.size());
        system.assert(suppInvAfterCancelList1[0].status__c == 'Cancelled', 'The SI should be in cancelled status'); 
        //system.assertEquals(0, suppInvAfterCancelList1[0].Balance_Due__c);
        
        List<Id> polIdList = new List<Id>();
        for(Supplier_Invoice__c si : suppInvAfterCancelList1){
            for(Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){ 
               polIdList.add(sil.Purchase_Order_Line__c);
               System.debug(logginglevel.error,'polIdList-->'+polIdList);
               System.debug(logginglevel.error,'sil-->'+sil);
               system.assert(sil.Matched__c == false, 'The SIL matched should be false');
               system.assert(sil.Finalized__c == false, 'The SIL finalized should be false');
               
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
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', suppInvData.suppInv1.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(suppInvData.suppInv1);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        system.assert( ApexPages.hasMessages() == false, ApexPages.getMessages() );
   }
    

   static testMethod void testVoidAccounting_for2wayand3way() {
        
        
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Bank_Transaction_Group__c-'+Bank_Transaction_Group__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Customer_Receipt__c-'+Customer_Receipt__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Customer_Receipt_Line__c-'+Customer_Receipt_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Journal_Entry__c-'+Journal_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Journal_Entry_Line__c-'+Journal_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        
        insert lConfigs;
        
        
		SupplierInvoiceData suppInvData = new SupplierInvoiceData();
        
        List<Supplier_invoice__c> suppInvList = [Select id, Name , finalized__c, finalized_date__c, transaction_date__c, posting_date__c, historical__c, status__c, void__c,has_exceptions__c,exceptions_count__c,line_exceptions_count__c
                                                    from supplier_invoice__c where id = :suppInvData.suppInv1.id];
        test.startTest();
        
        //doing the inspect on SI
        for(Supplier_invoice__c si: suppInvList){
            SupplierInvoiceService.inspectSI(si.Id);
        }

        List<Supplier_invoice__c> suppInvListAfterInspect = [Select id, Name , finalized__c, finalized_date__c, transaction_date__c, posting_date__c, historical__c, status__c, void__c,has_exceptions__c,exceptions_count__c,line_exceptions_count__c
                                                    from supplier_invoice__c where id = :suppInvData.suppInv1.id];
        System.debug(logginglevel.error,'suppInvListAfterInspect---->'+suppInvListAfterInspect);

        List<Supplier_invoice_line__c> suppInvLineafterInspectLst = [Select Id,Invoice_Quantity__c,Invoice_Quantity_To_Stock__c,Matched__c,Finalized__c,Purchase_Order_Line__c from Supplier_Invoice_Line__c
                                                                  where Supplier_invoice__c = :suppInvData.suppInv1.id];
        
		
        List<Id> silIds = new List<Id>();
        for(Supplier_invoice_line__c sil : suppInvLineafterInspectLst){
            silIds.add(sil.Id);
	}
        List<Task> silexceptions = [SELECT Id, Subject, Status, Exception_Code__c, 
                    Description, WhatId, OwnerId FROM Task  WHERE WhatId in :silIds];
                    
        System.debug(logginglevel.error,'silexceptions---->'+silexceptions);
         
        system.assert(suppInvListAfterInspect[0].status__c == 'Approved', 'The SI should be in Approved status '+silexceptions); 
		
        Test.setCurrentPage( Page.AccountingEntryGenerate);
        Apexpages.currentPage().getParameters().put('id', suppInvData.suppInv1.id );
        SourceDocumentAccountingCon con = new SourceDocumentAccountingCon();
        con.populateSobjDetails();
        list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
        integer i=0;
        for(map<string,string> m:chunks)
        {
            SourceDocumentAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.getguid(),con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
            i++;
        }
        SupplierInvoiceVoidCancelService vcs = new SupplierInvoiceVoidCancelService(suppInvList);
        vcs.getBusinessVoidCancelDetails(suppInvList);
        vcs.voidSourceDocuments(suppInvList);
         test.stopTest();  
       
        List<Supplier_invoice__c> suppInvAfterVoidList = [Select id, Name , Supplier_and_Invoice__c, status__c,Purchase_Order__c, void_date__c, Date_Invoiced__c,
                                                            (Select Id,Invoice_Quantity__c,Invoice_Quantity_To_Stock__c,Matched__c,Finalized__c,Purchase_Order_Line__c from Supplier_Invoice_Lines__r)
                                                            from supplier_invoice__c where id = :suppInvData.suppInv1.id];
        system.debug(logginglevel.error,'suppInvAfterVoidList---->'+suppInvAfterVoidList);
        system.assert(suppInvAfterVoidList[0].status__c == 'Void', 'The SI should be in void status'); 
        system.assertEquals(suppInvAfterVoidList[0].Void_Date__c.date(), suppInvAfterVoidList[0].Date_Invoiced__c.date());
        
        
        List<Id> polIdList = new List<Id>();
        for(Supplier_Invoice__c si : suppInvAfterVoidList){
            for(Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){ 
               polIdList.add(sil.Purchase_Order_Line__c);
               System.debug(logginglevel.error,'polIdList-->'+polIdList);
               System.debug(logginglevel.error,'sil-->'+sil);
               system.assert(sil.Matched__c == false, 'The SIL matched should be false');
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
        
        PageReference pageRef = Page.SupplierInvoiceManage;
        pageRef.getParameters().put('Id', suppInvData.suppInv1.Id);
        pageRef.getParameters().put('Clone', '1'); // Clone it
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(suppInvData.suppInv1);
        SupplierInvoiceManageExt siMngExt = new SupplierInvoiceManageExt(sc);
        system.assert( ApexPages.hasMessages() == false, ApexPages.getMessages() );
    }
    
    static testMethod void testCancelAccounting_for2wayand3way(){
        
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Bank_Transaction_Group__c-'+Bank_Transaction_Group__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Customer_Receipt__c-'+Customer_Receipt__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Customer_Receipt_Line__c-'+Customer_Receipt_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Journal_Entry__c-'+Journal_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Journal_Entry_Line__c-'+Journal_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        
        insert lConfigs;
        
        
        SupplierInvoiceData suppInvData = new SupplierInvoiceData();
        
        List<Supplier_invoice__c> suppInvList = [Select id, Name , finalized__c, finalized_date__c, transaction_date__c, posting_date__c, historical__c, status__c, void__c,has_exceptions__c,exceptions_count__c,line_exceptions_count__c
                                                 from supplier_invoice__c where id = :suppInvData.suppInv1.id];
        test.startTest();
        
        //doing the inspect on SI
        for(Supplier_invoice__c si: suppInvList){
            SupplierInvoiceService.inspectSI(si.Id);
        }    
        
        List<Supplier_invoice__c> suppInvListAfterInspect = [Select id, Name , finalized__c, finalized_date__c, transaction_date__c, posting_date__c, historical__c, status__c, void__c,has_exceptions__c,exceptions_count__c,line_exceptions_count__c
                                                    from supplier_invoice__c where id = :suppInvData.suppInv1.id];
        System.debug(logginglevel.error,'suppInvListAfterInspect---->'+suppInvListAfterInspect);
        
        List<Supplier_invoice_line__c> suppInvLineafterInspectLst = [Select Id,Invoice_Quantity__c,Invoice_Quantity_To_Stock__c,Matched__c,Finalized__c,Purchase_Order_Line__c from Supplier_Invoice_Line__c
                                                                  where Supplier_invoice__c = :suppInvData.suppInv1.id];
        
        
        List<Id> silIds = new List<Id>();
        for(Supplier_invoice_line__c sil : suppInvLineafterInspectLst){
            silIds.add(sil.Id);
        }
        List<Task> silexceptions = [SELECT Id, Subject, Status, Exception_Code__c, 
                    Description, WhatId, OwnerId FROM Task  WHERE WhatId in :silIds];
      
        System.debug(logginglevel.error,'silexceptions---->'+silexceptions);
         
        system.assert(suppInvListAfterInspect[0].status__c == 'Approved', 'The SI should be in Approved status '+silexceptions);
        
        
        
        Test.setCurrentPage( Page.SourceDocumentAccounting);
        Apexpages.currentPage().getParameters().put('id', suppInvListAfterInspect[0].Id );
        
        SourceDocumentAccountingCon con = new SourceDocumentAccountingCon();
        con.populateSobjDetails();
        list<map<string,string>> chunks =(list<map<string,string>>)JSON.deserialize(con.getautonumberchunks(), list<map<string,string>>.class);
        integer i=0;
        for(map<string,string> m:chunks)
        {
           SourceDocumentAccountingCon.generateAccounting(con.gettheSourceDocIdPg(),con.getguid(),con.gettheSourceDocNamePg(),i,chunks.size(),m.get('max'),m.get('min'));
            i++;
        }
       
        
        Accounting_Entry__c ae = [Select Id, Exceptions_Count__c from Accounting_Entry__c where Supplier_Invoice__c = :suppInvList limit 1 ];
        system.debug(logginglevel.error,'ae '+ae);
        ae.Exceptions_Count__c = 1;
        update ae;
        delete lConfigs;
        
        system.debug(logginglevel.error,'suppInvList--1-->'+suppInvList);
        system.debug(logginglevel.error,'suppInvListAfterInspect--1-->'+suppInvListAfterInspect);
        //query AE and set Has Excpetions = true
        
        SupplierInvoiceVoidCancelService vcs = new SupplierInvoiceVoidCancelService(suppInvListAfterInspect);
        vcs.getBusinessVoidCancelDetails(suppInvListAfterInspect);
        Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = vcs.cancelSourceDocuments(suppInvListAfterInspect);
        
        test.stopTest();
        
        system.debug(logginglevel.error,'suppInvList--2-->'+suppInvList);
        system.debug(logginglevel.error,'suppInvListAfterInspect--2-->'+suppInvListAfterInspect);
        
        List<Supplier_invoice__c> suppInvAfterCancelList = [Select id, Name , Supplier_and_Invoice__c, status__c,Purchase_Order__c,
                                                            (Select Id,Invoice_Quantity__c,Invoice_Quantity_To_Stock__c,Matched__c,Finalized__c,Purchase_Order_Line__c from Supplier_Invoice_Lines__r)
                                                            from supplier_invoice__c where id = :suppInvListAfterInspect[0].id];
                                                            
        System.debug(logginglevel.error,'suppInvAfterCancelList---->'+suppInvAfterCancelList);
        
        system.assertEquals(suppInvAfterCancelList[0].status__c ,'Cancelled', VoidCancelResponses); 
        
        
        List<Id> polIdList = new List<Id>();
        for(Supplier_Invoice__c si : suppInvAfterCancelList){
            for(Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){ 
               polIdList.add(sil.Purchase_Order_Line__c);
               System.debug(logginglevel.error,'polIdList-->'+polIdList);
               System.debug(logginglevel.error,'sil-->'+sil);
               system.assert(sil.Matched__c == false, 'The SIL matched should be false');
               system.assert(sil.Finalized__c == false, 'The SIL finalized should be false');
               
            }
        }
      
        List<Purchase_Order_Line__c> poLineListData = [Select id, Name, Item__c,Order_Quantity__c,Quantity_Matched__c,Invoice_Matching__c  from Purchase_Order_Line__c where Id in :polIdList];
        System.debug(logginglevel.error,'poLineListData-->'+poLineListData);
        for(Purchase_Order_Line__c pol : poLineListData){
            if(pol.Invoice_Matching__c == 'Two Way')
              system.assert(pol.Quantity_Matched__c == 0, 'The Quantity matched should be 0');
            else
              system.assert(pol.Quantity_Matched__c == 0, 'The Quantity matched should be 0');
        }
	}
}