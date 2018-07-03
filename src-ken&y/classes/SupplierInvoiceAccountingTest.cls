@isTest
public class SupplierInvoiceAccountingTest {
	
    public class SampleData{
        
        public TestFuel data = new TestFuel();
        public SampleData(){
            updateData();
        }
        
        
        // Test Supplier Invoice Accounting
	    public List<Supplier_Invoice_Line__c> suppInvLineList1 = new List<Supplier_Invoice_Line__c>();
	    public List<Supplier_Invoice_Line__c> suppInvLineList2 = new List<Supplier_Invoice_Line__c>();
	    public List<Supplier_Invoice__c> suppInvAEList = new List<Supplier_Invoice__c>();
	    public Supplier_Invoice__c suppInv1, suppInv2, suppInv3;
        public Supplier_Invoice_Line__c suppInvLine1, suppInvLine2, suppInvLine3, suppInvLine4, rilt1;
	    public List<Purchase_Order_Line__c> poLineList = [Select id, Name from Purchase_Order_Line__c where Purchase_Order__c in (:data.purchaseOrder2.id, :data.purchaseOrder3.id)];
        public Purchase_Order__c purchaseOrder1 = new Purchase_Order__c();
        public Purchase_Order__c purchaseOrder2 = new Purchase_Order__c();
        public Purchase_Order__c purchaseOrder3 = new Purchase_Order__c();
        public Purchase_Order__c purchaseOrder4 = new Purchase_Order__c();
     	public List<UOM__c> uomList = new List<UOM__c>(); 
        public List<Item__c> itemList = new List<Item__c>();{
                 
            Item__c ItemObj2=new Item__c();
            ItemObj2.name='HP Printer';
            ItemObj2.Description__c='It is a Test item';
            ItemObj2.Source__c=Label.Source_field_of_ItemP;
            ItemObj2.Company__c = data.company.id;
            ItemObj2.Class__c = data.classList[0].id;
            ItemObj2.Stocking_UOM__c = data.uomList[0].Id;
            ItemObj2.Packaging_UOM__c = JSON.serialize(new List<Id>{ data.uomList[0].Id });
            
            itemList.add(ItemObj2);
            
            Item__c ItemObj3=new Item__c();
            ItemObj3.name='HP Printer 3';
            ItemObj3.Description__c='It is a Test item';
           // ItemObj3.Source__c='Miscellaneous';
            ItemObj3.Source__c='Manufactured';
            ItemObj3.Company__c = data.company.id;
            ItemObj3.Class__c = data.classList[1].id;
            ItemObj3.Stocking_UOM__c = data.uomList[0].Id;
            ItemObj3.Packaging_UOM__c = JSON.serialize(new List<Id>{ data.uomList[0].Id });
            
            itemList.add(ItemObj3);
            
            Item__c ItemObj4=new Item__c();
            ItemObj4.name='HP Printer 4';
            ItemObj4.Description__c='It is a Test item';
            ItemObj4.Source__c='Expense';
            itemObj4.Non_Inventory__c = true; 
            ItemObj4.Company__c = data.company.id;
            ItemObj4.Class__c = data.classList[2].id;
            ItemObj4.Stocking_UOM__c = data.uomList[0].Id;
            ItemObj4.Packaging_UOM__c = JSON.serialize(new List<Id>{ data.uomList[0].Id });
            
            itemList.add(ItemObj4);
            insert itemList;
        }
       
        private void updateData(){
            
     		List<UOM__c> uomList = data.uomList;
             purchaseOrder1.Order_Date__c = system.today();
             purchaseOrder1.status__c = 'Open';
             purchaseOrder1.Supplier__c = data.supplier.id; 
             purchaseOrder1.Remit_To_Supplier__c = data.remittosupplier.id; 
             purchaseOrder1.Company__c = data.company.id;
             purchaseOrder1.Payment_Term__c = data.terms.id;
             purchaseOrder1.Memo__c = 'PurchaseOrder1';
             purchaseOrder1.Currency__c = TestFuel.currencyUSD.id;
             
             purchaseOrder2.Order_Date__c = system.today();
             purchaseOrder2.status__c = 'Open';
             purchaseOrder2.Supplier__c = data.supplier.id;
             purchaseOrder2.Remit_To_Supplier__c = data.remittosupplier.id; 
             purchaseOrder2.Company__c = data.company.id;
             purchaseOrder2.Payment_Term__c = data.terms.id;
             purchaseOrder2.Memo__c = 'PurchaseOrder2';
             purchaseOrder2.Currency__c = TestFuel.currencyUSD.id;
             
             purchaseOrder3.Order_Date__c = system.today();
             purchaseOrder3.Supplier__c = data.supplier.id; 
             purchaseOrder3.Remit_To_Supplier__c = data.remittosupplier.id;
             purchaseOrder3.Company__c = data.company.id;
             purchaseOrder3.Payment_Term__c = data.terms.id;
             purchaseOrder3.status__c = 'Open';
             purchaseOrder3.Memo__c = 'PurchaseOrder3';
             purchaseOrder3.Currency__c = TestFuel.currencyUSD.id;           		
             
             purchaseOrder4.Order_Date__c = system.today();
             purchaseOrder4.Supplier__c = data.supplier.id;
             purchaseOrder4.Remit_To_Supplier__c = data.remittosupplier.id; 
             purchaseOrder4.Company__c = data.company.id;
             purchaseOrder4.Payment_Term__c = data.terms.id;
             purchaseOrder4.status__c = 'Open';
             purchaseOrder4.Memo__c = 'PurchaseOrder4';
             purchaseOrder4.Currency__c = TestFuel.currencyUSD.id;
                 
                 insert new List<sobject>{ purchaseOrder1, purchaseOrder2, purchaseOrder3, purchaseOrder4};
                 
              List<Purchase_Order_Line__c> objPODetailList = new List<Purchase_Order_Line__c>();
              
             Purchase_Order_Line__c objPODetail = new Purchase_Order_Line__c();
             objPODetail.Purchase_Order__c = purchaseOrder1.Id;
             objPODetail.Order_Quantity__c = 10;        
             objPODetail.Unit_Price__c = 12;
             objPODetail.Item__c = itemList[0].Id;
             objPODetail.Purchase_UOM__c = uomList[0].Id;
             objPODetail.Status__c = Label.Open;    
             objPODetail.Need_Date__c = System.today();
             objPODetail.Company__c = data.company.id;
             objPODetail.Delivery_Location__c = data.location.ID;
             objPODetail.Delivery_facility__c = data.location.facility__c;
             //objPODetail.Line_Type__c = 'Standard';
             objPODetail.Supplier__c = data.supplier.Id;
             objPODetailList.add( objPODetail );                   
             
             
             Purchase_Order_Line__c objPODetail1 = new Purchase_Order_Line__c();
             objPODetail1.Purchase_Order__c = purchaseOrder2.Id;
             objPODetail1.Order_Quantity__c = 10;        
             objPODetail1.Unit_Price__c = 25;
             objPODetail1.Item__c = itemList[0].Id;
             objPODetail1.Purchase_UOM__c = uomList[0].Id;
             objPODetail1.Status__c = Label.Open;    
             objPODetail1.Need_Date__c = System.today();
             objPODetail1.Company__c = data.company.id;
             objPODetail1.Delivery_Location__c = data.location.ID;
             objPODetail1.Delivery_facility__c = data.location.facility__c;
             //objPODetail1.Line_Type__c = 'Standard';
             objPODetail1.Supplier__c = data.supplier.Id;
             objPODetail1.Invoice_Matching__c = 'Two Way';
             
             objPODetailList.add(objPODetail1);                    
             
             Purchase_Order_Line__c objPODetail2 = new Purchase_Order_Line__c();
             objPODetail2.Purchase_Order__c = purchaseOrder2.Id;
             objPODetail2.Order_Quantity__c = 5;        
             objPODetail2.Unit_Price__c = 15;
             objPODetail2.Item__c = itemList[0].Id;
             objPODetail2.Purchase_UOM__c = uomList[0].Id;
             objPODetail2.Status__c = Label.Open;    
             objPODetail2.Need_Date__c = System.today();
             objPODetail2.Company__c = data.company.id;
             objPODetail2.Delivery_Location__c = data.location.ID;
             objPODetail2.Delivery_facility__c = data.location.facility__c;
             //objPODetail2.Line_Type__c = 'Standard';
             objPODetail2.Supplier__c = data.supplier.Id;
             objPODetailList.add(objPODetail2);  
 
             objPODetail1 = new Purchase_Order_Line__c();
             objPODetail1.Purchase_Order__c = purchaseOrder3.Id;
             objPODetail1.Order_Quantity__c = 10;        
             objPODetail1.Unit_Price__c = 25;
             objPODetail1.Item__c = itemList[0].Id;
             objPODetail1.Purchase_UOM__c = uomList[0].Id;
             objPODetail1.Status__c = Label.Open;    
             objPODetail1.Need_Date__c = System.today();
             objPODetail1.Company__c = data.company.id;
             objPODetail1.Delivery_Location__c = data.location.ID;
             objPODetail1.Delivery_facility__c = data.location.facility__c;
             //objPODetail1.Line_Type__c = 'Standard';
             objPODetail1.Supplier__c = data.supplier.Id;
             objPODetailList.add(objPODetail1);                     // line trigger sets the Line__c sequence
             
             objPODetail2 = new Purchase_Order_Line__c();
             objPODetail2.Purchase_Order__c = purchaseOrder3.Id;
             objPODetail2.Order_Quantity__c = 5;        
             objPODetail2.Unit_Price__c = 15;
             objPODetail2.Item__c = itemList[0].Id;
             objPODetail2.Purchase_UOM__c = uomList[0].Id;
             objPODetail2.Status__c = Label.Open;    
             objPODetail2.Need_Date__c = System.today();
             objPODetail2.Company__c = data.company.id;
             objPODetail2.Delivery_Location__c = data.location.ID;
             objPODetail2.Delivery_facility__c = data.location.facility__c;
             //objPODetail2.Line_Type__c = 'Standard';
             objPODetail2.Supplier__c = data.supplier.Id;
             objPODetailList.add(objPODetail2);  
             
             
             objPODetail1 = new Purchase_Order_Line__c();
             objPODetail1.Purchase_Order__c = purchaseOrder4.Id;
             objPODetail1.Order_Quantity__c = 1;        
             objPODetail1.Unit_Price__c = 25;
             objPODetail1.Item__c = itemList[1].Id;
             objPODetail1.Purchase_UOM__c = uomList[0].Id;
             objPODetail1.Status__c = Label.Open;    
             objPODetail1.Need_Date__c = System.today();
             objPODetail1.Company__c = data.company.id;
             objPODetail1.Delivery_Location__c = data.location.ID;
             objPODetail1.Delivery_facility__c = data.location.facility__c;
             //objPODetail1.Line_Type__c = 'Standard';
             objPODetail1.Supplier__c = data.supplier.Id;
             objPODetailList.add(objPODetail1);                     // line trigger sets the Line__c sequence
             
             objPODetail2 = new Purchase_Order_Line__c();
             objPODetail2.Purchase_Order__c = purchaseOrder4.Id;
             objPODetail2.Order_Quantity__c = 2;        
             objPODetail2.Unit_Price__c = 20;
             objPODetail2.Item__c = itemList[0].Id;
             objPODetail2.Purchase_UOM__c = uomList[0].Id;
             objPODetail2.Status__c = Label.Open;    
             objPODetail2.Need_Date__c = System.today();
             objPODetail2.Company__c = data.company.id;
             objPODetail2.Delivery_Location__c = data.location.ID;
             objPODetail2.Delivery_facility__c = data.location.facility__c;
             //objPODetail2.Line_Type__c = 'Standard';
             objPODetail2.Supplier__c = data.supplier.Id;
             objPODetailList.add(objPODetail2); 
             
             Purchase_Order_Line__c objPODetail3 = new Purchase_Order_Line__c();
             objPODetail3.Purchase_Order__c = purchaseOrder4.Id;
             objPODetail3.Order_Quantity__c = 2;        
             objPODetail3.Unit_Price__c = 10;
             objPODetail3.Item__c = itemList[0].Id;
             objPODetail3.Purchase_UOM__c = uomList[0].Id;
             objPODetail3.Status__c = Label.Open;    
             objPODetail3.Need_Date__c = System.today();
             objPODetail3.Company__c = data.company.id;
             objPODetail3.Delivery_Location__c = data.location.ID;
             objPODetail3.Delivery_facility__c = data.location.facility__c;
             //objPODetail3.Line_Type__c = 'Standard';
             objPODetail3.Supplier__c = data.supplier.Id;
             objPODetailList.add(objPODetail3); 
             insert objPODetailList;   
              
             map<id,Purchase_Order__c> poMap = new map <id, Purchase_Order__c>([select id, name, Purchase_Order_Value__c from Purchase_Order__c where id =: purchaseOrder1.id OR id =: purchaseOrder2.id OR id =: purchaseOrder3.id OR id =: purchaseOrder4.id]);
            	//system.assert(poMap.size() == 0, 'poMap : ' + poMap);

           	suppInv1 = new Supplier_Invoice__c();
            suppInv1.Company__c = data.company.id;
            suppInv1.Invoice_Type__c = 'Invoice';
            suppInv1.Date_Invoiced__c = System.now();
            suppInv1.Currency__c = TestFuel.currencyUSD.id;
            suppInv1.Transaction_Date__c = system.now();
            suppInv1.Supplier__c = data.remittosupplier.id;
            suppInv1.Amount_Due__c = poMap.get(purchaseOrder1.id).Purchase_Order_Value__c;
            suppInv1.Invoice_Amount__c = poMap.get(purchaseOrder1.id).Purchase_Order_Value__c;
            suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
            suppInv1.historical__c = false;
            //insert suppInv1; 
            
            suppInv2 = new Supplier_Invoice__c();
            suppInv2.Company__c = data.company.id;
            suppInv2.Invoice_Type__c = 'Invoice';
            suppInv2.Date_Invoiced__c = System.today();
            suppInv2.Currency__c = TestFuel.currencyUSD.id;
            suppInv2.Transaction_Date__c = system.now();
            suppInv2.Supplier__c = data.remittosupplier.id;
            suppInv2.Amount_Due__c = poMap.get(purchaseOrder2.id).Purchase_Order_Value__c;
            suppInv2.Invoice_Amount__c = poMap.get(purchaseOrder2.id).Purchase_Order_Value__c;
            suppInv2.Supplier_Invoice__c = String.valueOfGmt(system.today()+1);
            suppInv2.historical__c = false;
            //insert suppInv2;
            
            suppInv3 = new Supplier_Invoice__c();
            suppInv3.Company__c = data.company.id;
            suppInv3.Invoice_Type__c = 'Credit Memo';
            suppInv3.Date_Invoiced__c = System.now();
            suppInv3.Currency__c = TestFuel.currencyUSD.id;
            suppInv3.Transaction_Date__c = system.now();
            suppInv3.Supplier__c = data.remittosupplier.id;
            suppInv3.Credit_Memo_Amount__c = -500;
            suppInv3.Invoice_Amount__c = -500;
            suppInv3.Supplier_Invoice__c = String.valueOfGmt(system.today()+3);
            suppInv3.historical__c = false;
            //insert suppInv3;
            
            suppInvAEList.add(suppInv1);
            suppInvAEList.add(suppInv2);
            suppInvAEList.add(suppInv3);
            
            insert suppInvAEList;
            
            suppInvLine1 = new Supplier_Invoice_Line__c(); 
            suppInvLine1.Supplier_Invoice__c = suppInv1.id;
            suppInvLine1.Invoice_Quantity__c = 3;
            suppInvLine1.Invoice_Quantity_to_Stock__c = 8;
            suppInvLine1.Item__c = data.itemList[0].id;
            suppInvLine1.Purchase_Order__c = purchaseOrder2.id;
            suppInvLine1.Purchase_Order_Line__c = poLineList[0].id;
            suppInvLine1.Quantity_Received__c = 4;
            suppInvLine1.Unit_Price__c = 20; 
            suppInvLine1.Line_Type__c = 'Item';
            suppInvLineList1.add(suppInvLine1);
            
            Supplier_Invoice_Line__c suppInvLine2 = new Supplier_Invoice_Line__c();
            suppInvLine2.Supplier_Invoice__c = suppInv1.id;
            suppInvLine2.Invoice_Quantity__c = 3;
            suppInvLine2.Invoice_Quantity_to_Stock__c = 8;
            suppInvLine2.Item__c = data.itemList[0].id;
            suppInvLine2.Purchase_Order__c = data.purchaseOrder2.id;
            suppInvLine2.Purchase_Order_Line__c = poLineList[1].id;
            suppInvLine2.Quantity_Received__c = 4;
            suppInvLine2.Unit_Price__c = 20; 
            suppInvLine2.Line_Type__c = 'Item';
            suppInvLineList1.add(suppInvLine2);
            insert suppInvLineList1;
            
            suppInvLine3 = new Supplier_Invoice_Line__c();   
            suppInvLine3.Supplier_Invoice__c = suppInv2.id;
            suppInvLine3.Invoice_Quantity__c = 11;
            suppInvLine3.Invoice_Quantity_to_Stock__c = 2;
            suppInvLine3.Item__c = data.itemList[0].id;
            suppInvLine3.Purchase_Order__c = data.purchaseOrder3.id;
            suppInvLine3.Purchase_Order_Line__c = poLineList[2].id;
            suppInvLine3.Quantity_Received__c = 4;
            suppInvLine3.Unit_Price__c = 15; 
            suppInvLine3.Line_Type__c = 'Item';
            suppInvLineList2.add(suppInvLine3);
            
            suppInvLine4 = new Supplier_Invoice_Line__c();     
            suppInvLine4.Supplier_Invoice__c = suppInv2.id;
            suppInvLine4.Invoice_Quantity__c = 8;
            suppInvLine4.Invoice_Quantity_to_Stock__c = 2;
            suppInvLine4.Item__c = data.itemList[0].id;
            suppInvLine4.Purchase_Order__c = data.purchaseOrder3.id;
            suppInvLine4.Purchase_Order_Line__c = poLineList[3].id;
            suppInvLine4.Quantity_Received__c = 4;
            suppInvLine4.Unit_Price__c = 20; 
            suppInvLine4.Line_Type__c = 'Item';
            suppInvLineList2.add(suppInvLine4);
            insert suppInvLineList2;
            
            rilt1 = new Supplier_Invoice_Line__c();
            rilt1.Item__c = data.itemList[0].id;
            rilt1.Item__r = new Item__c( id= data.itemList[0].id );
            rilt1.Description__c = 'test';
            rilt1.Invoice_Quantity__c = -1; 
            rilt1.Unit_Price__c = 500;//KNDY-14371
            rilt1.Supplier_Invoice__c = suppInv3.id;
            rilt1.Invoice_Line__c = suppInvLine4.id;
            rilt1.Subtransaction_Type__c = 'On Account';
            rilt1.Invoice_Line__r = [ select id, Extended_Price__c from Supplier_Invoice_Line__c where id=:suppInvLine4.id ];
            insert rilt1;  
            
            system.debug(suppInv2);
            system.assert(suppInv2.Total_Extended_Price__c == suppInv2.Total_Invoice__c, 'Sum (' + suppInv2.Total_Extended_Price__c + ') does not equal total Invoice (' + suppinv2.Total_Invoice__c + ')');
            suppInv2.Status__c = 'Approved';
            suppInv2.finalized__c = true;
            //suppInv2.Finalized_Date__c = system.now();
            //update suppInv2;
            
            system.debug(suppInv1);
            suppInv1.Status__c = 'Approved';
            suppInv1.finalized__c = true;
            //suppInv1.Finalized_Date__c = system.now();
            //update suppInv1;
            
            suppInv3.status__c ='Approved';
            suppInv3.finalized__c = true;
            //suppInv3.Finalized_Date__c = system.now();
            //update suppInv3; 
            
            update suppInvAEList;
        }
        
        
	    
    }   
	static testmethod void testSIAccounting(){
        
        SampleData sd = new SampleData();
        
	    Test.startTest();
	    
	    sd.suppInv1 = [Select id, Name, Finalized__c, Finalized_hidden__c
	                                    from Supplier_Invoice__c 
	                                    where id = :sd.suppInv1.id];
	    system.debug(sd.suppInv1);        
	    system.assertEquals(true, sd.suppInv1.Finalized__c);
	    system.assertEquals(true, sd.suppInv1.Finalized_hidden__c);
	    
	    boolean sawException = false;
	    try{
	        sd.suppInv1.Finalized__c = false;
	        update sd.suppInv1;
	    }catch(Exception e){
	        sawException = true;
	    }
	    
	    system.assertEquals(true, sawException);
	            
	    SupplierInvoiceAccounting sia = new SupplierInvoiceAccounting();
        list<supplier_invoice_line__c> silList = new list<supplier_invoice_line__c>();
        silList.addall(sd.suppInvLineList1);
        silList.addall(sd.suppInvLineList2);
        silList.add(sd.rilt1);

	    sia.execute(silList);
	    
	    Set<Id> suppInvIds = new Set<Id>();
	    for(Supplier_Invoice__c suppInv: sd.suppInvAEList){
	        suppInvIds.add(suppInv.id);
	    }
	    List<Accounting_Entry__c> acctEntry = [Select id, Name, Supplier_Invoice__c, Supplier__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Supplier_Invoice__c in :suppInvIds) order by id];
	        
	    system.debug('acctEntry:'+acctEntry);
	    system.assertnotEquals(null,acctEntry);
	    system.assertEquals(3,acctEntry.size());
	    Integer listSize = acctEntry.size();
	    for(Integer i=0;i<listSize; i++){
	        system.assertEquals(sd.data.remittosupplier.id, acctEntry[i].Supplier__c) ;
	    }
    
 
	}	
    
    
    public static testMethod void testFinalizeHeaderValidation(){
        
        SampleData sd = new SampleData();
        test.startTest();
        
        string trxnCurr = sd.suppInv1.Currency__c;
        boolean sawException = false;
        string exMsg;
        try{
            sd.suppInv1.Currency__c = null;
            update sd.suppInv1;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to edit a finalized doc ' + exMsg );
        
        sawException = false;
        exMsg = null;
        sd.suppInv1.Currency__c = trxnCurr;
        try{
            delete sd.suppInv1;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to delete a finalized doc ' + exMsg );
        
        test.stopTest();
    }
    
    public static testMethod void testFinalizeLineEditValidation(){
        
        SampleData sd = new SampleData();
        test.startTest();
        
        sd.suppInvLineList1 = [Select id, Name,finalized__c, unit_price__c from Supplier_Invoice_Line__c where id in :sd.suppInvLineList1];
        
        for(Supplier_Invoice_Line__c sil : sd.suppInvLineList1){
        	system.assertEquals(true, sil.finalized__c,'sil:'+sil);
		    sil.unit_price__c = 100;
		}
		
		boolean sawException = false;
        string exMsg = null;
        try{
        	update sd.suppInvLineList1;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to edit finalized doc lines ' + exMsg );
    }
    
        
    public static testMethod void testFinalizeLineDeleteValidation(){
    	
    	SampleData sd = new SampleData();
        test.startTest();
    	    
        boolean sawException = false;
        string exMsg = null;
        try{
        	delete sd.suppInvLineList1;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
        test.stopTest();
        
        system.assert(sawException, 'We are expecting to see an exception for attempting to delete finalized doc lines ' + exMsg );
    }
 	
 	public static testMethod void testFinalizeLineAddValidation(){
    	
    	SampleData sd = new SampleData();
        test.startTest();
 	
        boolean sawException = false;
        string exMsg = null;
        try{
        	List<Supplier_Invoice_Line__c> newSILs = new List<Supplier_Invoice_Line__c>();
        	for(Supplier_Invoice_Line__c sil : sd.suppInvLineList1){
			    newSILs.add(sil.clone(false, true));
			}
        	insert newSILs;
        }catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
     	
     	test.stopTest();
        system.assert(sawException, 'We are expecting to see an exception for attempting to add lines to a finalized doc ' + exMsg );
 	}
 	
 	public static testMethod void testFinalizeLineUndeleteValidation(){
    	
    	SampleData sd = new SampleData();
    	
    	Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{sd.suppInv1});
    	
    	system.assert(mResponses.get(sd.suppInv1.Id).Success, 'We are expecting a successful unfinalize' + mResponses.get(sd.suppInv1.Id));
    	
    	List<Supplier_Invoice_Line__c> newSILs = new List<Supplier_Invoice_Line__c>();
    	for(Supplier_Invoice_Line__c sil : sd.suppInvLineList1){
		    newSILs.add(sil.clone(false, true));
		}
    	insert newSILs;
    	
        test.startTest();
    	
    	delete newSILs;
       
        sd.suppInv1.finalized__c = true;
        update sd.suppInv1;
		
		boolean sawException = false;
        string exMsg = null;
		
		try{
			undelete newSILs;
     	}catch(Exception ex){
            exMsg = ex.getMessage();
            sawException = true;
        }
        
     	test.stopTest();
        system.assert(sawException, 'We are expecting to see an exception for attempting to undelete lines on a finalized doc ' + exMsg );
 	}
	
	
	public static testMethod void testIPV(){
		SampleData sd = new SampleData();
        
		system.assert(sd.data.SuppInvAcctRulesList.size()> 0 );
	    Test.startTest();
	    
	    // KNDY-12704 Accounting rule for subtransaction type Goods - Purchase Order has no line type
	    // Remove Line type from SIL
	    List<Supplier_Invoice_Line__c> sils = [Select id, Line_Type__c
                                        from Supplier_Invoice_Line__c 
                                        where Supplier_Invoice__c = :sd.suppInv1.id];
        for (Supplier_Invoice_Line__c sil : sils){
            sil.Line_Type__c = '';
        }
        update sils;
	    sd.suppInv1 = [Select id, Name, Finalized__c, Finalized_hidden__c, Transaction_Currency__c
	                                    from Supplier_Invoice__c 
	                                    where id = :sd.suppInv1.id];
	    system.debug(sd.suppInv1);        
	    system.assertEquals(true, sd.suppInv1.Finalized__c);
	    system.assertEquals(true, sd.suppInv1.Finalized_hidden__c);
	    
	    boolean sawException = false;
	    try{
	        sd.suppInv1.Finalized__c = false;
	        update sd.suppInv1;
	    }catch(Exception e){
	        sawException = true;
	    }
	    
	    system.assertEquals(true, sawException);
	            
	    SupplierInvoiceAccounting sia = new SupplierInvoiceAccounting();
	    sia.execute(sd.suppInvLineList1);
	    
	    Set<Id> suppInvIds = new Set<Id>();
	    for(Supplier_Invoice__c suppInv: sd.suppInvAEList){
	        suppInvIds.add(suppInv.id);
	    }
	    List<Accounting_Entry__c> acctEntries = [Select id, Name, Supplier_Invoice__c, Supplier__c,transaction_type__c,
	                                            (Select id, Name, gl_account__c, gl_account__r.name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (Supplier_Invoice__c in :suppInvIds) order by id];
	        
	    system.debug('acctEntry:'+acctEntries);
	    system.assertnotEquals(null,acctEntries);
	    system.assertEquals(1,acctEntries.size());
	    	boolean hasIPV = false;
	    for(Accounting_Entry__c ae : acctEntries){
	    	for(Accounting_Entry_Line__c ael : ae.Accounting_Entry_Lines__r){
	    		ael.gl_account__c = sd.data.IPVGL.Id;
	        	system.assertNotEquals(0, ae.Accounting_Entry_Lines__r.size(), 'We should see lines for this Accounting Entry');
        		if(ael.gl_account__c == sd.data.IPVGL.Id){
        			hasIPV = true;
        		}
	    	}
	    	system.assert(hasIPV, 'We are expecting to see IPV booked to this supplier invoice ' + ae.Accounting_Entry_Lines__r);
	    }
	}

}