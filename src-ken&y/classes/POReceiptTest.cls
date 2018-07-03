/**
 * This class contains unit tests for Coverage.
 */
@isTest
private class POReceiptTest {
	static TestDataForFinance tdata = new TestDataForFinance();
        
	public class POReceiptData{
        //GenerateAccountingService GAS = new GenerateAccountingService();
        ReceivingDocumentAccounting rda = new ReceivingDocumentAccounting();
        
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
                                where p.id in (:tdata.purchaseOrder1.id, :tdata.purchaseOrder2.id, :tdata.purchaseOrder3.id, :tdata.purchaseOrder4.id)];
        List<Receiving_Document__c> receivingDocList = new List<Receiving_Document__c>(); {
            Receiving_Document__c receivingdocument1=new Receiving_Document__c();
                receivingdocument1.Company__c=tdata.company.Id;
                receivingdocument1.Supplier__c=tdata.supplier.Id;
                receivingdocument1.Status__c = 'Open';   
		    	//FIN-566 fix ASN Accounting
                receivingdocument1.type__c = 'Purchase Order Receipt';                     
                receivingdocument1.Date_Received__c = System.now();
                //receivingdocument1.Finalized__c = true;
                //receivingdocument1.finalized_date__c = system.now();
                receivingdocument1.transaction_date__c = system.now();
                receivingdocument1.Currency__c = TestFuel.currencyUSD.id;
                receivingdocument1.historical__c = false;
                receivingDocList.add(receivingdocument1); 
                
            Receiving_Document__c receivingdocument2=new Receiving_Document__c();
                receivingdocument2.Company__c=tdata.company.Id;
                receivingdocument2.Supplier__c=tdata.supplier.Id;
                receivingdocument2.Status__c = 'Open';   
		    	//FIN-566 fix ASN Accounting
                receivingdocument2.type__c = 'Purchase Order Receipt';                     
                receivingdocument2.Date_Received__c = System.now();
                //receivingdocument2.Finalized__c = true;
                //receivingdocument2.finalized_date__c = system.now();
                receivingdocument2.transaction_date__c = system.now();
                receivingdocument2.Currency__c = TestFuel.currencyUSD.id;
                receivingdocument2.historical__c = false;
                receivingDocList.add(receivingdocument2);
        
            Receiving_Document__c receivingdocument3=new Receiving_Document__c();
                receivingdocument3.Company__c=tdata.company.Id;
                receivingdocument3.Supplier__c=tdata.supplier.Id;
                receivingdocument3.Status__c = 'Open'; 
 		    	//FIN-566 fix ASN Accounting
                receivingdocument3.type__c = 'Purchase Order Receipt';                       
                receivingdocument3.Date_Received__c = System.now();
                //receivingdocument3.Finalized__c = true;
                //receivingdocument3.finalized_date__c = system.now();
                receivingdocument3.transaction_date__c = system.now();
                receivingdocument3.Currency__c = TestFuel.currencyUSD.id;
                receivingdocument3.historical__c = false;
                receivingDocList.add(receivingdocument3);
          
          	Receiving_Document__c receivingdocument4=new Receiving_Document__c();
                receivingdocument4.Company__c=tdata.company.Id;
                receivingdocument4.Supplier__c=tdata.supplier.Id;
                receivingdocument4.Status__c = 'Open';   
 		    	//FIN-566 fix ASN Accounting
                receivingdocument4.type__c = 'Purchase Order Receipt';                     
                receivingdocument4.Date_Received__c = System.now();
               	//receivingdocument4.Finalized__c = true;
                //receivingdocument4.finalized_date__c = system.now();
                receivingdocument4.transaction_date__c = system.now();
                receivingdocument4.Currency__c = TestFuel.currencyUSD.id;
                receivingdocument4.historical__c = false;
                receivingDocList.add(receivingdocument4);
            insert receivingDocList;
        }
        List<Purchase_Order_Line__c> polineList = [select Id, Purchase_Order__c, Item__c,Unit_Price__c,Order_Quantity__c  
                                                    from Purchase_Order_Line__c 
                                                    where Purchase_Order__c  in 
                                                    (:tdata.purchaseOrder1.id, :tdata.purchaseOrder2.id, :tdata.purchaseOrder3.id, :tdata.purchaseOrder4.id)];
                                                     
        List<Receipt_Line__c> receiptinvoicelineList = new List<Receipt_Line__c>();{
            Receipt_Line__c receiptinvoiceline1 = new Receipt_Line__c();
            receiptinvoiceline1.Item__c = tdata.itemList[0].id;
            receiptinvoiceline1.Company__c = tdata.company.id;
            receiptinvoiceline1.Supplier__c=tdata.supplier.Id;
            receiptinvoiceline1.Status__c = 'Open';     
            receiptinvoiceline1.Receiving_Document__c=receivingDocList[0].Id;
            receiptinvoiceline1.Location__c = tdata.location.id;
            receiptinvoiceline1.Unit_Price__c = 15;
            receiptinvoiceline1.Purchase_Order__c = tdata.purchaseOrder1.id;
            receiptinvoiceline1.Purchase_Order_Line__c = polineList[0].ID;
            receiptinvoiceline1.Quantity_Received__c = 6;
            receiptinvoiceline1.Extended_Cost__c = 70;
            receiptinvoicelineList.add(receiptinvoiceline1); 
            
            Receipt_Line__c receiptinvoiceline2 = new Receipt_Line__c();
            receiptinvoiceline2.Item__c = tdata.itemList[0].id;
            receiptinvoiceline2.Company__c = tdata.company.id;
            receiptinvoiceline2.Supplier__c=tdata.supplier.Id;
            receiptinvoiceline2.Status__c = 'Open';     
            receiptinvoiceline2.Receiving_Document__c=receivingDocList[1].Id;
            receiptinvoiceline2.Location__c = tdata.location.id;
            receiptinvoiceline2.Unit_Price__c = 15;
            receiptinvoiceline2.Purchase_Order__c = tdata.purchaseOrder2.id;
            receiptinvoiceline2.Purchase_Order_Line__c = polineList[1].ID;
            receiptinvoiceline2.Quantity_Received__c = 6;
            receiptinvoiceline2.Extended_Cost__c = 70;
            receiptinvoicelineList.add(receiptinvoiceline2);
            
            Receipt_Line__c receiptinvoiceline3 = new Receipt_Line__c();
            receiptinvoiceline3.Item__c = tdata.itemList[0].id;
            receiptinvoiceline3.Company__c = tdata.company.id;
            receiptinvoiceline3.Supplier__c=tdata.supplier.Id;
            receiptinvoiceline3.Status__c = 'Open';     
            receiptinvoiceline3.Receiving_Document__c=receivingDocList[1].Id;
            receiptinvoiceline3.Location__c = tdata.location.id;
            receiptinvoiceline3.Unit_Price__c = 15;
            receiptinvoiceline3.Purchase_Order__c = tdata.purchaseOrder2.id;
            receiptinvoiceline3.Purchase_Order_Line__c = polineList[2].ID;
            receiptinvoiceline3.Quantity_Received__c = 6;
            receiptinvoiceline3.Extended_Cost__c = 70;
            receiptinvoicelineList.add(receiptinvoiceline3);
            
            Receipt_Line__c receiptinvoiceline4 = new Receipt_Line__c();
            receiptinvoiceline4.Item__c = tdata.itemList[0].id;
            receiptinvoiceline4.Company__c = tdata.company.id;
            receiptinvoiceline4.Supplier__c=tdata.supplier.Id;
            receiptinvoiceline4.Status__c = 'Open';     
            receiptinvoiceline4.Receiving_Document__c=receivingDocList[2].Id;
            receiptinvoiceline4.Location__c = tdata.location.id;
            receiptinvoiceline4.Unit_Price__c = 15;
            receiptinvoiceline4.Purchase_Order__c = tdata.purchaseOrder3.id;
            receiptinvoiceline4.Purchase_Order_Line__c = polineList[3].ID;
            receiptinvoiceline4.Quantity_Received__c = 6;
            receiptinvoiceline4.Extended_Cost__c = 70;
            receiptinvoicelineList.add(receiptinvoiceline4);
            
            Receipt_Line__c receiptinvoiceline5 = new Receipt_Line__c();
            receiptinvoiceline5.Item__c = tdata.itemList[0].id;
            receiptinvoiceline5.Company__c = tdata.company.id;
            receiptinvoiceline5.Supplier__c=tdata.supplier.Id;
            receiptinvoiceline5.Status__c = 'Open';     
            receiptinvoiceline5.Receiving_Document__c=receivingDocList[2].Id;
            receiptinvoiceline5.Location__c =tdata.location.id;
            receiptinvoiceline5.Unit_Price__c = 15;
            receiptinvoiceline5.Purchase_Order__c = tdata.purchaseOrder3.id;
            receiptinvoiceline5.Purchase_Order_Line__c = polineList[4].ID;
            receiptinvoiceline5.Quantity_Received__c = 6;
            receiptinvoiceline5.Extended_Cost__c = 70;
            receiptinvoicelineList.add(receiptinvoiceline5);
            
            Receipt_Line__c receiptinvoiceline6 = new Receipt_Line__c();
            receiptinvoiceline6.Item__c = tdata.itemList[1].id;
            receiptinvoiceline6.Company__c = tdata.company.id;
            receiptinvoiceline6.Supplier__c=tdata.supplier.Id;
            receiptinvoiceline6.Status__c = 'Open';     
            receiptinvoiceline6.Receiving_Document__c=receivingDocList[3].Id;
            receiptinvoiceline6.Location__c = tdata.location.id;
            receiptinvoiceline6.Unit_Price__c = 25;
            receiptinvoiceline6.Purchase_Order__c = tdata.purchaseOrder4.id;
            receiptinvoiceline6.Purchase_Order_Line__c = polineList[5].ID;
            receiptinvoiceline6.Quantity_Received__c = 1;
            receiptinvoicelineList.add(receiptinvoiceline6);
            
            Receipt_Line__c receiptinvoiceline7 = new Receipt_Line__c();
            receiptinvoiceline7.Item__c = tdata.itemList[0].id;
            receiptinvoiceline7.Company__c = tdata.company.id;
            receiptinvoiceline7.Supplier__c=tdata.supplier.Id;
            receiptinvoiceline7.Status__c = 'Open';     
            receiptinvoiceline7.Receiving_Document__c=receivingDocList[3].Id;
            receiptinvoiceline7.Location__c = tdata.location.id;
            receiptinvoiceline7.Unit_Price__c = 20;
            receiptinvoiceline7.Purchase_Order__c = tdata.purchaseOrder4.id;
            receiptinvoiceline7.Purchase_Order_Line__c = polineList[6].ID;
            receiptinvoiceline7.Quantity_Received__c = 2;
            receiptinvoiceline7.Extended_Cost__c = 6;
            receiptinvoicelineList.add(receiptinvoiceline7);
            
            Receipt_Line__c receiptinvoiceline8 = new Receipt_Line__c();
            receiptinvoiceline8.Item__c = tdata.itemList[2].id;
            receiptinvoiceline8.Company__c = tdata.company.id;
            receiptinvoiceline8.Supplier__c=tdata.supplier.Id;
            receiptinvoiceline8.Status__c = 'Open';     
            receiptinvoiceline8.Receiving_Document__c=receivingDocList[3].Id;
            receiptinvoiceline8.Location__c = tdata.location.id;
            receiptinvoiceline8.Unit_Price__c = 10;
            receiptinvoiceline8.Purchase_Order__c = tdata.purchaseOrder4.id;
            receiptinvoiceline8.Purchase_Order_Line__c = polineList[7].ID;
            receiptinvoiceline8.Quantity_Received__c = 2;
            receiptinvoicelineList.add(receiptinvoiceline8);
            
            insert receiptinvoicelineList;
            
	        //loop throught the receiptlines and null out the line types so it matches with the accounting rules in the test data
	        //it was defaulted to the PO line's line type
	        for(Receipt_Line__c rl: receiptinvoicelineList){
	            rl.Line_Type__c = null;
        	}
	        update receiptinvoicelineList;                 
            
            for(Receiving_Document__c rd : receivingDocList){
            	rd.finalized__c = true;
            }  
            
            update receivingDocList;
            
        }
                        
        Set<Id> receiptIds = new Set<Id>();
        {
            for(Receiving_Document__c receipt: receivingDocList){
                receiptIds.add(receipt.id);
            }
        }
    }
    
    
    static testMethod void POReceiptData_test1() {
        Test.startTest();
        
        POReceiptAccountingExt GAEC;
        POReceiptData poRcptData = new POReceiptData();
       	Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(poRcptData.receivingDocList);
        
        setcon.setSelected(poRcptData.receivingDocList);
        GAEC = new POReceiptAccountingExt(setcon);
       
        GAEC.GeneratePOReceiptAccounting();
              
        List<Accounting_Entry__c> acctEntryList = [Select id, Name, Receiving_Document__c
                                                    from Accounting_Entry__c
                                                    where Receiving_Document__c in :poRcptData.receiptIds]; 
        system.assertNotEquals(null,acctEntryList);
        //system.assertEquals(null, GAEC.objectList);
        Test.stopTest();

        List<Receiving_Document__c> ReceiptsAfter = [Select id, Name, (Select id, Name from Accounting_Entries__r where void__c = false) from Receiving_Document__c where id in :poRcptData.receiptIds]; 
        for(integer i=0;i<ReceiptsAfter.size(); i++){
            system.assertNotEquals(0 ,ReceiptsAfter[i].accounting_entries__r.size());
        }
        
        List <Accounting_Entry__c> acctEntryListNew = [Select id, Name, 
        												(Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c
        												from Accounting_Entry_Lines__r)
        												from Accounting_Entry__c 
        												where Receiving_Document__c = :poRcptData.receivingDocList[3].id];
		//FIN-326
		system.assertEquals(8,acctEntryListNew[0].Accounting_Entry_Lines__r.size());        												

    }
    
    static testMethod void POReceiptData_test2() {
        Test.startTest();
        
        POReceiptAccountingExt GAEC;
        POReceiptData poRcptData = new POReceiptData();
        UnfinalizeService.unfinalizeSourceDocs(poRcptData.receivingDocList);
        
        
       	poRcptData.receivingDocList[0].Date_Received__c = null;
       	poRcptData.receivingDocList[0].Finalized__c = true;
       	update poRcptData.receivingDocList[0];
       	Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(poRcptData.receivingDocList);
        
        setcon.setSelected(poRcptData.receivingDocList);
        GAEC = new POReceiptAccountingExt(setcon);
       
        GAEC.GeneratePOReceiptAccounting();
              
        system.assertEquals(true, GAEC.requiredFielderror);
    }
    
    static testMethod void POReceiptData_test3() {
    	Test.startTest();
        
        POReceiptAccountingExt GAEC;
        POReceiptData poRcptData = new POReceiptData();       
	    poRcptData.receivingDocList[0].Currency__c = null;
	    
	    boolean sawException = false;
	   	try{
       		update poRcptData.receivingDocList[0];
	   	}catch(Exception ex){
	   		sawException = true;
	   	}
	   	
	   	system.assert(sawException, 'This DML to null the Transaction currency should fail');
       	
       	Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(poRcptData.receivingDocList);
        
        setcon.setSelected(poRcptData.receivingDocList);
        GAEC = new POReceiptAccountingExt(setcon);
       
        GAEC.GeneratePOReceiptAccounting();
              
        system.assertEquals(true, GAEC.requiredFielderror);
        
    }
    
}