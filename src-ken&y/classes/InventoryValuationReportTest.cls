@isTest
private class InventoryValuationReportTest {
	public static string NamespaceUU { get { return KSE.NamespaceUU; }} 
    public static testMethod void getAllTransactionsTest() {
        TestFuel tf=new testFuel();
        
        Facility__c f = tf.facility2; 
        SKID__c skid1 = tf.skids[0];
        
        
        skid1.Consigned_Owner__c =null;
        upsert skid1;
        SKID__c skid2 = tf.skids[1];
        
        
        skid2.Consigned_Owner__c =null;
		upsert skid2;

        test.starttest();
        InventoryValuationReportExt.resultChunkObject obj1=new InventoryValuationReportExt.resultChunkObject();
        obj1 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/6/2015 12:00 AM',tf.location5.Id,tf.location7.Id,1000,NamespaceUU+'Location__c',false,false);
        
        InventoryValuationReportExt.resultChunkObject obj2=new InventoryValuationReportExt.resultChunkObject();
        obj2 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/6/2015 12:00 AM',f.Id,tf.facility2.Id,1000,NamespaceUU+'Facility__c',false,false);
        
        InventoryValuationReportExt.resultChunkObject obj3=new InventoryValuationReportExt.resultChunkObject();
        obj3 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/6/2015 12:00 AM',tf.itemList[0].Id,tf.itemList[1].Id,1000,NamespaceUU+'Item__c',false,false);
		
		InventoryValuationReportExt.resultChunkObject obj4=new InventoryValuationReportExt.resultChunkObject();
        obj4 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/12/2015 12:00 AM',tf.costList[0].Id,tf.costList[1].Id,1000,NamespaceUU+'Item_Cost__c',false,false);
		
		InventoryValuationReportExt.resultChunkObject obj5=new InventoryValuationReportExt.resultChunkObject();
        obj5 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/6/2015 12:00 AM',skid1.id,skid2.id,1000,NamespaceUU+'SKID__c',false,false);
		
		
		InventoryValuationReportExt.resultChunkObject obj6=new InventoryValuationReportExt.resultChunkObject();
        obj6 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/6/2015 12:00 AM',tf.location5.Id,tf.location7.Id,1000,NamespaceUU+'Location__c',true,false);
        
        InventoryValuationReportExt.resultChunkObject obj7=new InventoryValuationReportExt.resultChunkObject();
        obj7 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/6/2015 12:00 AM',f.Id,tf.facility2.Id,1000,NamespaceUU+'Facility__c',true,false);
        
        InventoryValuationReportExt.resultChunkObject obj8=new InventoryValuationReportExt.resultChunkObject();
        obj8 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/6/2015 12:00 AM',tf.itemList[0].Id,tf.itemList[1].Id,1000,NamespaceUU+'Item__c',true,false);
		
		InventoryValuationReportExt.resultChunkObject obj9=new InventoryValuationReportExt.resultChunkObject();
        obj9 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/12/2015 12:00 AM',tf.costList[0].id,tf.costList[1].id,1000,NamespaceUU+'Item_Cost__c',true,false);
		
		InventoryValuationReportExt.resultChunkObject obj10=new InventoryValuationReportExt.resultChunkObject();
        obj10 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/6/2015 12:00 AM',skid1.id,skid2.id,1000,NamespaceUU+'SKID__c',true,false);
        
        //Test for Null/No records and for Failure cause
        //======================================================================================================================================================================
        //Last record is false
        InventoryValuationReportExt.resultChunkObject obj11=new InventoryValuationReportExt.resultChunkObject();
        obj11 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/6/2015 12:00 AM',null,null,1000,NamespaceUU+'Inventory_Transaction__c',false,false);
        
        //Last record is true
        InventoryValuationReportExt.resultChunkObject obj12=new InventoryValuationReportExt.resultChunkObject();
        obj12 = InventoryValuationReportExt.getAllTransactions(f.Id,'8/6/2015 12:00 AM',null,null,1000,NamespaceUU+'Inventory_Transaction__c',true,false);
        
        InventoryValuationReportExt.resultChunkObject obj13=new InventoryValuationReportExt.resultChunkObject();
        obj13 = InventoryValuationReportExt.getAllTransactions(null,'8/6/2015 12:00 AM',null,null,1000,null,true,false);
		
        test.stoptest();
        system.assertEquals('Success', obj1.Messages); 
        system.assert(obj1.draftCount>0, obj1.draftCount); 
        system.assertEquals('Success', obj2.Messages);
        system.assert(obj2.draftCount>0, obj2.draftCount); 
        system.assertEquals('Success', obj3.Messages);
        system.assert(obj3.draftCount>0, obj3.draftCount); 
        system.assertEquals('Success', obj4.Messages);
        system.assertEquals(0, obj4.draftCount); 
        system.assertEquals('Success', obj5.Messages);
        system.assert(obj5.draftCount>0, obj5.draftCount); 
        
        system.assertEquals('Success', obj6.Messages); 
        system.assert(obj6.draftCount>0, obj6.draftCount); 
        system.assertEquals('Success', obj7.Messages);
        system.assert(obj7.draftCount>0, obj7.draftCount); 
        system.assertEquals('Success', obj8.Messages);
        system.assert(obj8.draftCount>0, obj8.draftCount); 
        system.assertEquals('Success', obj9.Messages);
        system.assertEquals(0, obj9.draftCount); 
        system.assertEquals('Success', obj10.Messages);
        system.assert(obj10.draftCount>0, obj10.draftCount); 
        
        //These 2 are for invalid id being queried in inventory transactions 
        system.assertEquals(0, obj11.draftCount);
        system.assertEquals(0, obj12.draftCount); 
        
        //Made the catch block to fire by passing the null object
        system.assertNotEquals('Success', obj13.Messages);
        system.assertEquals(null, obj13.draftCount); 
        
        InventoryValuationReportExt ext = new InventoryValuationReportExt ();
        system.assertEquals( String.isNotBlank( ext.availableCostBucketsJson ), true );
        
        
	}
	
	public static testMethod void getAllTransactionsbyTransactionDate() {
        TestFuel tf=new testFuel();
        
        System.assert(tf.smrsList != null);
        System.assert(tf.stockMovementRuleList != null);
        System.assert(tf.purchaseOrder != null);
        System.assert(tf.periodList != null);
        
        update new Item_Attribute__c(Id = tf.itemAttrObj.Id, Lot_Number__c = false, Expiration_Date__c = false, Date_Received__c = false);
        
       
        test.starttest();
        //Receive PO 
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();         
        
        tf.purchaseOrder.Approval_Status__c = 'Approved';
        update tf.purchaseOrder;          
         
        getListresult = ReceivingWorkBenchExt.getList(new list<Id>{tf.purchaseOrderLines[0].Id}, 'Purchase Order');
       
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(new list<Id>{tf.purchaseOrderLines[0].Id}, 'Purchase Order',testfuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new set<Id>{tf.purchaseOrderLines[0].Id}, new set<String>{'Purchase_Order_Line__c'.toLowerCase()} );
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        rdoc.Currency__c = testfuel.currencyUSD.id;
       
        rdoc.Transaction_Date__c = DateTime.parse('8/10/2016 12:02 AM');
        system.assert(rdocresult.records.size() == 1, rdocresult);
        
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                
                skid.Quantity__c = 5;
            }
        }
        
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        List<Inventory_Transaction__c> invlist = [Select Id, Transaction_Date__c,CreatedDate,To_Facility__c,From_Facility__c from Inventory_Transaction__c];
        
        system.assert(invlist.size()==1);
        InventoryValuationReportExt.resultChunkObject obj11=new InventoryValuationReportExt.resultChunkObject();
        obj11 = InventoryValuationReportExt.getAllTransactions(tf.facility2.Id,'8/15/2016 12:10 AM',invlist[0].Id,invlist[0].Id,1000,NamespaceUU+'Inventory_Transaction__c',true,true);//use transaction date
        
        InventoryValuationReportExt.resultChunkObject obj12=new InventoryValuationReportExt.resultChunkObject();
        obj12 = InventoryValuationReportExt.getAllTransactions(tf.facility2.Id,'8/15/2016 12:00 AM',invlist[0].Id,invlist[0].Id,1000,NamespaceUU+'Inventory_Transaction__c',true,false);//use createddate
        
        
        test.stoptest();
        system.assertEquals('Success', obj11.Messages); 
        system.assert(obj11.draftCount==0, obj11.draftCount); 
        system.assert(obj12.draftCount>0, obj12.draftCount); 
        
	}
	
	
}