@isTest
public class PutawayReceiptsExtTest {

    
    static testMethod void doPutawayRMALines(){     
        
        TestFuel fuel = new TestFuel();
        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;    
        List<Period__c> periodList = fuel.periodList;
        Facility__c facility1 = fuel.facility2;
        
        //Addeing User Preference
        insert new User_Preference__c(OwnerId = UserInfo.getUserId(),Name = 'my preference',Default_Company__c = fuel.company.Id,Default_Facility__c = fuel.facility2.Id);
        
        fuel.itemList[1].item_attribute__c = null;
        update fuel.itemList[0];
        
        fuel.itemList[4].item_attribute__c = null;
        update fuel.itemList[5];
        
        
        facility1.RMA_Receipt_Routing__c = 'Inspect';
        update facility1;
        
        //Update Sales Order Type as RMA
        so.Type__c = SalesOrderService.SO_TYPE_RMA;
        so.Status__c = 'Open';
        update so;
        
        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;
        
        
        //Create Receiving Document and Receipt Lines
        Receiving_Document__c rd = new Receiving_Document__c(
                Company__c = fuel.company.id,
                Date_Created__c = system.today(),
                Status__c = 'Draft',
                Type__c = 'RMA Receipt',
                Transaction_Type__c = 'RMA Receipt',
                Currency__c = TestFuel.currencyUSD.id,
                Transaction_Date__C = system.now()
            );
        insert rd;
        List<Receipt_Line__c> receiptlineslist = new List<Receipt_Line__c>(); 
        Receipt_Line__c receiptline1 = new Receipt_Line__c();
        receiptline1.Company__c = fuel.company.Id;
        receiptline1.Sales_Order__c = so.Id;
        receiptline1.Sales_Order_Line__c = soline.Id;
        receiptline1.Item__c = fuel.itemList[1].ID;
        receiptline1.Quantity_Received__c = 10;
        receiptline1.Quantity_Still_Due_For_Putaway__c = 10;
        //receiptline1.Expiration_Date__c = System.today()+5;
        receiptline1.Facility__c = facility1.Id;
        receiptline1.Location__c = fuel.location2.Id;
        receiptline1.Status__c = 'Closed';
        receiptline1.Sales_Order__c = so.id;
        receiptline1.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline1);
        
        Receipt_Line__c receiptline2 = new Receipt_Line__c();
        receiptline2.Company__c = fuel.company.Id;
        receiptline2.Sales_Order__c = so.Id;
        receiptline2.Sales_Order_Line__c = soline1.Id;
        receiptline2.Item__c = fuel.itemList[4].Id;
        receiptline2.Facility__c = facility1.Id;
        receiptline2.Location__c = fuel.location2.Id;
        
        receiptline2.Quantity_Received__c = 15;
        receiptline2.Quantity_Still_Due_For_Putaway__c = 15;
        receiptline2.Status__c = 'Closed';
        receiptline2.Sales_Order__c = so.id;
        receiptline2.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline2);
        
        insert receiptlineslist;
        //new SalesOrderService().plan(so.Id); 
        
        PutawayReceiptsExt putawayext = new PutawayReceiptsExt();
        PutawayReceiptsExt.setGridConfig('RMA');
        
        putawayext.getreceiptLinesConfigJson();
        //Create ASN with inTransit SKID       
       
        Receiving_Document__c queriedrd = [Select Id, Name, Currency__c  from Receiving_Document__c where Id =:rd.Id]; 
        String docnum = rd.Name;
        ID currencyfilter = queriedrd.Currency__c;
        
        List<Receipt_Line__c> newreceiptlinelist = [Select Id from Receipt_Line__c where Receiving_Document__c =:rd.Id];
        system.assert(newreceiptlinelist.size() == 2, newreceiptlinelist);
        
        List<Id> rlineIds = new List<Id>();
        for(Receipt_Line__c line:newreceiptlinelist){
            rlineIds.add(line.id);
        }
        
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        test.startTest();
       
        PutawayReceiptsExt recon = new PutawayReceiptsExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = PutawayReceiptsExt.getrdHeaderFieldList('RMA');
        PutawayReceiptsExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4]);
        String LinesFieldList;
        LinesFieldList = PutawayReceiptsExt.setFieldConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
		String receivingLinesFieldListJson = configMap.get('fieldList');
        searchresult = PutawayReceiptsExt.getLinesToReceive(facility1.ID, fuel.itemList[4].Id, null, fuel.customerSoldTo.id, rd.Name,'RMA');
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
        //Manage Putaway 
        
        getListresult = PutawayReceiptsExt.getList(rlineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = PutawayReceiptsExt.getrdDetails(rlineIds, 'RMA');
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(rlineIds), new set<String>{'Receipt_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
        	
        	for( SkidService3.serialWrapper sw : rw.serialWrapperList){
        		SKID__c skid = sw.skid;
        		Sales_Order_Line__c sol = (Sales_Order_Line__c)rw.rl.getSObject('Sales_Order_Line__r');
        	
        		if(skid.Item__c == fuel.itemList[1].ID){
        			skid.Quantity__c = 5;
        			skid.Expiration_Date__c = system.today() + 7;
        			skid.Date_received__c = system.today();
        			skid.Lot_Number__c = 'LOT 1';
        			rw.putawayType = 'Inventory';
        			skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
                    skid.Packaging_UOM__c = sol.Packaging_UOM__c;
                    skid.Packaging_UOM__r = sol.Packaging_UOM__r;
        		}
        		else{
        			skid.Quantity__c = 4;
        			skid.Expiration_Date__c = system.today() + 7;
        			skid.Date_received__c = system.today();
        			skid.Lot_Number__c = 'LOT 2';
        			rw.putawayType = 'Scrap';
        			skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
                    skid.Packaging_UOM__c = sol.Packaging_UOM__c;
                    skid.Packaging_UOM__r = sol.Packaging_UOM__r;
        		}
        			
        		
        	}
        }
        
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        rdoc.Transaction_Date__c = system.today() +5;
        
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = PutawayReceiptsExt.putaway(rwrapperlist, null, null, rdoc, null,'RMA',true);
        
        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        
        //Also check Quantity_Fulfilled__c on updated solines.								
		Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_Still_Due_For_Putaway__c, Item__c, Quantity_Received__c, Quantity_To_Stock__c, Receiving_Document__r.Transaction_Type__c
        									   from Receipt_Line__c where Id =: rlineIds];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
        	receiptlineSet.add(rcptline.Id);
        	system.assert(rcptline.Quantity_To_Stock__c ==rcptline.Quantity_Received__c);
        	if(rcptline.Item__c == fuel.itemList[1].ID){
        		system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 5, rcptline);
        	}
        	else if(rcptline.Item__c == fuel.itemList[4].ID){
        		system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 11, rcptline);
        	} 
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'RMA Receipt', rcptline.Receiving_Document__r.Transaction_Type__c);            
        }
               
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Inventory_Change__c, Transaction_Date__c, Receipt_Line__r.Receiving_Document__r.Transaction_Date__c, Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
        										  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
        Boolean invflag, scrapflag;
        for(Inventory_Transaction__c it: itlist){

            if (it.Inventory_Change__r.Type__c == 'RMA Receipt') {
        		invflag = true;
        		system.assert(it.Transaction_Date__c == it.Receipt_Line__r.Receiving_Document__r.Transaction_Date__c);
        	}
        	if(it.Inventory_Change__r.Type__c == 'RMA Scrap'){
        		scrapflag = true;
        	}
        	
        	inventorychangeset.add(it.Inventory_Change__c);
        }
        system.assert(inventorychangeset.size() ==2);//one for scrap and one for inventory
        system.assert(invflag ==true && scrapflag == true);
       
    }
    
    static testMethod void doPutawayRMAForReplacementLines(){   	
    	
    	TestFuel fuel = new TestFuel();
    	Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;    
        List<Period__c> periodList = fuel.periodList;
        Facility__c facility1 = fuel.facility2;
        
        //Addeing User Preference
        insert new User_Preference__c(OwnerId = UserInfo.getUserId(),Name = 'my preference',Default_Company__c = fuel.company.Id,Default_Facility__c = fuel.facility2.Id);
        
        fuel.itemList[1].item_attribute__c = null;
        update fuel.itemList[0];
        
        fuel.itemList[4].item_attribute__c = null;
        update fuel.itemList[5];
        
        
        facility1.RMA_Receipt_Routing__c = 'Inspect';
        update facility1;
        
        //Update Sales Order Type as RMA
        so.Type__c = SalesOrderService.SO_TYPE_RMA;
        so.Status__c = 'Open';
        update so;
        
        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;
        
        
        //Create Receiving Document and Receipt Lines
        Receiving_Document__c rd = new Receiving_Document__c(
                Company__c = fuel.company.id,
                Date_Created__c = system.today(),
                Status__c = 'Draft',
                Type__c = 'RMA Receipt',
                Transaction_Type__c = 'RMA Receipt',
                Transaction_Currency__c = 'USD',
                Transaction_Date__C = system.now()
            );
        insert rd;
        List<Receipt_Line__c> receiptlineslist = new List<Receipt_Line__c>(); 
		Receipt_Line__c receiptline1 = new Receipt_Line__c();
        receiptline1.Company__c = fuel.company.Id;
        receiptline1.Sales_Order__c = so.Id;
        receiptline1.Sales_Order_Line__c = soline.Id;
        receiptline1.Item__c = fuel.itemList[1].ID;
        receiptline1.Quantity_Received__c = 10;
        receiptline1.Quantity_Still_Due_For_Putaway__c = 10;
        //receiptline1.Expiration_Date__c = System.today()+5;
        receiptline1.Facility__c = facility1.Id;
        receiptline1.Location__c = fuel.location2.Id;
        receiptline1.Status__c = 'Closed';
        receiptline1.Sales_Order__c = so.id;
        receiptline1.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline1);
        
        Receipt_Line__c receiptline2 = new Receipt_Line__c();
        receiptline2.Company__c = fuel.company.Id;
        receiptline2.Sales_Order__c = so.Id;
        receiptline2.Sales_Order_Line__c = soline1.Id;
        receiptline2.Item__c = fuel.itemList[4].Id;
        receiptline2.Facility__c = facility1.Id;
        receiptline2.Location__c = fuel.location2.Id;
        
        receiptline2.Quantity_Received__c = 15;
        receiptline2.Quantity_Still_Due_For_Putaway__c = 15;
        receiptline2.Status__c = 'Closed';
        receiptline2.Sales_Order__c = so.id;
        receiptline2.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline2);
        
        insert receiptlineslist;
        //new SalesOrderService().plan(so.Id); 
        
        PutawayReceiptsExt putawayext = new PutawayReceiptsExt();
		PutawayReceiptsExt.setGridConfig('RMA');
		
		putawayext.getreceiptLinesConfigJson();
        //Create ASN with inTransit SKID       
       
        Receiving_Document__c queriedrd = [Select Id, Name, Transaction_Currency__c  from Receiving_Document__c where Id =:rd.Id]; 
       	String docnum = rd.Name;
       	String currencyfilter = queriedrd.Transaction_Currency__c;
       	
       	List<Receipt_Line__c> newreceiptlinelist = [Select Id from Receipt_Line__c where Receiving_Document__c =:rd.Id];
        system.assert(newreceiptlinelist.size() == 2, newreceiptlinelist);
        
        List<Id> rlineIds = new List<Id>();
        for(Receipt_Line__c line:newreceiptlinelist){
        	rlineIds.add(line.id);
        }
        
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        test.startTest();
       
        PutawayReceiptsExt recon = new PutawayReceiptsExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = PutawayReceiptsExt.getrdHeaderFieldList('RMA');
        PutawayReceiptsExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4]);
        String LinesFieldList;
        LinesFieldList = PutawayReceiptsExt.setFieldConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
		String receivingLinesFieldListJson = configMap.get('fieldList');
        searchresult = PutawayReceiptsExt.getLinesToReceive(facility1.ID, fuel.itemList[4].Id, null, fuel.customerSoldTo.id, rd.Name,'RMA');
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
        //Manage Putaway 
        
        getListresult = PutawayReceiptsExt.getList(rlineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = PutawayReceiptsExt.getrdDetails(rlineIds, 'RMA');
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(rlineIds), new set<String>{'Receipt_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
            
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                Sales_Order_Line__c sol = (Sales_Order_Line__c)rw.rl.getSObject('Sales_Order_Line__r');
                if(skid.Item__c == fuel.itemList[1].ID){
                    skid.Quantity__c = 5;
                    skid.Expiration_Date__c = system.today() + 7;
                    skid.Date_received__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Inventory';
                    skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
                    skid.Packaging_UOM__c = sol.Packaging_UOM__c;
                    skid.Packaging_UOM__r = sol.Packaging_UOM__r;
                }
                else{
                    skid.Quantity__c = 4;
                    skid.Expiration_Date__c = system.today() + 7;
                    skid.Date_received__c = system.today();
                    skid.Lot_Number__c = 'LOT 2';
                    rw.putawayType = 'Scrap';
                    skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
                    skid.Packaging_UOM__c = sol.Packaging_UOM__c;
                    skid.Packaging_UOM__r = sol.Packaging_UOM__r;
                }
                    
                
            }
        }
        
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = PutawayReceiptsExt.putaway(rwrapperlist, null, null, rdoc, null,'RMA',false);
        
        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        
        //Also check Quantity_Fulfilled__c on updated solines.                              
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_Still_Due_For_Putaway__c, Item__c, Quantity_Received__c, Quantity_To_Stock__c, Receiving_Document__r.Transaction_Type__c
                                               from Receipt_Line__c where Id =: rlineIds];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c ==rcptline.Quantity_Received__c);
            if(rcptline.Item__c == fuel.itemList[1].ID){
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 5, rcptline);
            }
            else if(rcptline.Item__c == fuel.itemList[4].ID){
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 11, rcptline);
            } 
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'RMA Receipt', rcptline.Receiving_Document__r.Transaction_Type__c);            
        }
               
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
        Boolean invflag, scrapflag;
        for(Inventory_Transaction__c it: itlist){

            if (it.Inventory_Change__r.Type__c == 'RMA Receipt') {
                invflag = true;
            }
            if(it.Inventory_Change__r.Type__c == 'RMA Scrap'){
                scrapflag = true;
            }
            
            inventorychangeset.add(it.Inventory_Change__c);
        }
        system.assert(inventorychangeset.size() ==2);//one for scrap and one for inventory
        system.assert(invflag ==true && scrapflag == true);
       
    }

    static testMethod void doPutawayRMAForRepairLines(){

        TestFuel fuel = new TestFuel();
        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
        List<Period__c> periodList = fuel.periodList;
        Facility__c facility1 = fuel.facility2;

        //Addeing User Preference
        insert new User_Preference__c(OwnerId = UserInfo.getUserId(),Name = 'my preference',Default_Company__c = fuel.company.Id,Default_Facility__c = fuel.facility2.Id);

        fuel.itemList[1].item_attribute__c = null;
        update fuel.itemList[0];

        fuel.itemList[4].item_attribute__c = null;
        update fuel.itemList[5];


        facility1.RMA_Receipt_Routing__c = 'Inspect';
        update facility1;

        //Update Sales Order Type as RMA
        so.Type__c = SalesOrderService.SO_TYPE_RMA_REPAIR;
        so.Status__c = 'Open';
        update so;

        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;


        //Create Receiving Document and Receipt Lines
        Receiving_Document__c rd = new Receiving_Document__c(
                Company__c = fuel.company.id,
                Date_Created__c = system.today(),
                Status__c = 'Draft',
                Type__c = 'RMA Receipt For Repair',
                Transaction_Type__c = 'RMA Receipt For Repair',
                Currency__c = TestFuel.currencyUSD.id,
                Transaction_Date__C = system.now()
        );
        insert rd;
        List<Receipt_Line__c> receiptlineslist = new List<Receipt_Line__c>();
        Receipt_Line__c receiptline1 = new Receipt_Line__c();
        receiptline1.Company__c = fuel.company.Id;
        receiptline1.Sales_Order__c = so.Id;
        receiptline1.Sales_Order_Line__c = soline.Id;
        receiptline1.Item__c = fuel.itemList[1].ID;
        receiptline1.Quantity_Received__c = 10;
        receiptline1.Quantity_Still_Due_For_Putaway__c = 10;
        //receiptline1.Expiration_Date__c = System.today()+5;
        receiptline1.Facility__c = facility1.Id;
        receiptline1.Location__c = fuel.location2.Id;
        receiptline1.Status__c = 'Closed';
        receiptline1.Sales_Order__c = so.id;
        receiptline1.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline1);

        Receipt_Line__c receiptline2 = new Receipt_Line__c();
        receiptline2.Company__c = fuel.company.Id;
        receiptline2.Sales_Order__c = so.Id;
        receiptline2.Sales_Order_Line__c = soline1.Id;
        receiptline2.Item__c = fuel.itemList[4].Id;
        receiptline2.Facility__c = facility1.Id;
        receiptline2.Location__c = fuel.location2.Id;

        receiptline2.Quantity_Received__c = 15;
        receiptline2.Quantity_Still_Due_For_Putaway__c = 15;
        receiptline2.Status__c = 'Closed';
        receiptline2.Sales_Order__c = so.id;
        receiptline2.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline2);

        insert receiptlineslist;
        //new SalesOrderService().plan(so.Id);

        PutawayReceiptsExt putawayext = new PutawayReceiptsExt();
        PutawayReceiptsExt.setGridConfig('RMA');

        putawayext.getreceiptLinesConfigJson();
        //Create ASN with inTransit SKID

        Receiving_Document__c queriedrd = [Select Id, Name, Currency__c  from Receiving_Document__c where Id =:rd.Id];
        String docnum = rd.Name;
        ID currencyfilter = queriedrd.Currency__c;

        List<Receipt_Line__c> newreceiptlinelist = [Select Id from Receipt_Line__c where Receiving_Document__c =:rd.Id];
        system.assert(newreceiptlinelist.size() == 2, newreceiptlinelist);

        List<Id> rlineIds = new List<Id>();
        for(Receipt_Line__c line:newreceiptlinelist){
            rlineIds.add(line.id);
        }

        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();

        test.startTest();

        PutawayReceiptsExt recon = new PutawayReceiptsExt();
        Map<String,String> configMap = new Map<String,String>();

        String headerfieldlist = PutawayReceiptsExt.getrdHeaderFieldList('RMA');
        PutawayReceiptsExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4]);
        String LinesFieldList;
        LinesFieldList = PutawayReceiptsExt.setFieldConfig('RMA');

        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        searchresult = PutawayReceiptsExt.getLinesToReceive(facility1.ID, fuel.itemList[4].Id, null, fuel.customerSoldTo.id, rd.Name, 'RMA');
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);

        //Manage Putaway

        getListresult = PutawayReceiptsExt.getList(rlineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);

        //Create RD with some info and Receive
        rdocresult = PutawayReceiptsExt.getrdDetails(rlineIds, 'RMA');

        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(rlineIds), new set<String>{'Receipt_Line__c'.toLowerCase()} );

        for(ReceivingWrapper rw: rwrapperlist){

            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                Sales_Order_Line__c sol = (Sales_Order_Line__c)rw.rl.getSObject('Sales_Order_Line__r');
                if(skid.Item__c == fuel.itemList[1].ID){
                    skid.Quantity__c = 5;
                    skid.Expiration_Date__c = system.today() + 7;
                    skid.Date_received__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Inventory';
                    skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
                    skid.Packaging_UOM__c = sol.Packaging_UOM__c;
                    skid.Packaging_UOM__r = sol.Packaging_UOM__r;
                }
                else{
                    skid.Quantity__c = 4;
                    skid.Expiration_Date__c = system.today() + 7;
                    skid.Date_received__c = system.today();
                    skid.Lot_Number__c = 'LOT 2';
                    rw.putawayType = 'Scrap';
                    skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
                    skid.Packaging_UOM__c = sol.Packaging_UOM__c;
                    skid.Packaging_UOM__r = sol.Packaging_UOM__r;
                }


            }
        }

        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = PutawayReceiptsExt.putaway(rwrapperlist, null, null, rdoc, null,'RMA',false);

        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);

        //Also check Quantity_Fulfilled__c on updated solines.
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_Still_Due_For_Putaway__c, Item__c, Quantity_Received__c, Quantity_To_Stock__c, Receiving_Document__r.Transaction_Type__c
        from Receipt_Line__c where Id =: rlineIds];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c ==rcptline.Quantity_Received__c);
            if(rcptline.Item__c == fuel.itemList[1].ID){
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 5, rcptline);
            }
            else if(rcptline.Item__c == fuel.itemList[4].ID){
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 11, rcptline);
            }

            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'RMA Receipt For Repair', rcptline.Receiving_Document__r.Transaction_Type__c);
        }

        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
        FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];

        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
        Boolean invflag, scrapflag;
        for(Inventory_Transaction__c it: itlist){

            if (it.Inventory_Change__r.Type__c == 'RMA Receipt For Repair') {
                invflag = true;
            }
            if(it.Inventory_Change__r.Type__c == 'RMA Scrap'){
                scrapflag = true;
            }

            inventorychangeset.add(it.Inventory_Change__c);
        }
        system.assert(inventorychangeset.size() ==2);//one for scrap and one for inventory
        system.assert(invflag ==true && scrapflag == true,itlist);

    }
    
     static testMethod void doPutaway_Errors(){     
        
        TestFuel fuel = new TestFuel();
        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;    
        List<Period__c> periodList = fuel.periodList;
        Facility__c facility1 = fuel.facility2;
        
        //Addeing User Preference
        insert new User_Preference__c(OwnerId = UserInfo.getUserId(),Name = 'my preference',Default_Company__c = fuel.company.Id,Default_Facility__c = fuel.facility2.Id);
        
        fuel.itemList[1].item_attribute__c = null;
        update fuel.itemList[0];
        
        fuel.itemList[4].item_attribute__c = null;
        update fuel.itemList[5];
        
        
        facility1.RMA_Receipt_Routing__c = 'Inspect';
        update facility1;
        
        //Update Sales Order Type as RMA
        so.Type__c = SalesOrderService.SO_TYPE_RMA;
        so.Status__c = 'Open';
        update so;
        
        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;
        
        
        //Create Receiving Document and Receipt Lines
        Receiving_Document__c rd = new Receiving_Document__c(
                Company__c = fuel.company.id,
                Date_Created__c = system.today(),
                Status__c = 'Draft',
                Type__c = 'RMA Receipt',
                Transaction_Type__c = 'RMA Receipt',
                Currency__c = TestFuel.currencyUSD.id,
                Transaction_Date__C = system.now()
            );
        insert rd;
        List<Receipt_Line__c> receiptlineslist = new List<Receipt_Line__c>(); 
        Receipt_Line__c receiptline1 = new Receipt_Line__c();
        receiptline1.Company__c = fuel.company.Id;
        receiptline1.Sales_Order__c = so.Id;
        receiptline1.Sales_Order_Line__c = soline.Id;
        receiptline1.Item__c = fuel.itemList[1].ID;
        receiptline1.Quantity_Received__c = 10;
        receiptline1.Quantity_Still_Due_For_Putaway__c = 10;
        //receiptline1.Expiration_Date__c = System.today()+5;
        receiptline1.Facility__c = facility1.Id;
        receiptline1.Location__c = fuel.location2.Id;
        receiptline1.Status__c = 'Closed';
        receiptline1.Sales_Order__c = so.id;
        receiptline1.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline1);
        
        Receipt_Line__c receiptline2 = new Receipt_Line__c();
        receiptline2.Company__c = fuel.company.Id;
        receiptline2.Sales_Order__c = so.Id;
        receiptline2.Sales_Order_Line__c = soline1.Id;
        receiptline2.Item__c = fuel.itemList[4].Id;
        receiptline2.Facility__c = facility1.Id;
        receiptline2.Location__c = fuel.location2.Id;
        
        receiptline2.Quantity_Received__c = 15;
        receiptline2.Quantity_Still_Due_For_Putaway__c = 15;
        receiptline2.Status__c = 'Closed';
        receiptline2.Sales_Order__c = so.id;
        receiptline2.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline2);
        
        insert receiptlineslist;
        //new SalesOrderService().plan(so.Id); 
        
        PutawayReceiptsExt putawayext = new PutawayReceiptsExt();
        PutawayReceiptsExt.setGridConfig('RMA');
        
        putawayext.getreceiptLinesConfigJson();
        //Create ASN with inTransit SKID       
       
        Receiving_Document__c queriedrd = [Select Id,Name, Currency__c  from Receiving_Document__c where Id =:rd.Id]; 
        String docnum = queriedrd.Name;
        //String currencyfilter = queriedrd.Currency__c;
        
        List<Receipt_Line__c> newreceiptlinelist = [Select Id from Receipt_Line__c where Receiving_Document__c =:rd.Id];
        system.assert(newreceiptlinelist.size() == 2, newreceiptlinelist);
        
        List<Id> rlineIds = new List<Id>();
        for(Receipt_Line__c line:newreceiptlinelist){
            rlineIds.add(line.id);
        }
        
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        test.startTest();
       
        PutawayReceiptsExt recon = new PutawayReceiptsExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = PutawayReceiptsExt.getrdHeaderFieldList('RMA');
        PutawayReceiptsExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4]);
        String LinesFieldList;
        LinesFieldList = PutawayReceiptsExt.setFieldConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        searchresult = PutawayReceiptsExt.getLinesToReceive(fuel.facility2.ID, null, null, fuel.customerSoldTo.id, null, 'RMA');
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
        //Manage Putaway        
        
        getListresult = PutawayReceiptsExt.getList(rlineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = PutawayReceiptsExt.getrdDetails(rlineIds, 'RMA');
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(rlineIds), new set<String>{'Receipt_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
            
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == fuel.itemList[1].ID){
                    skid.Quantity__c = 0;
                    skid.Expiration_Date__c = system.today() + 7;
                    skid.Date_received__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Inventory';
                }
                else{
                    skid.Quantity__c = 0;
                    skid.Expiration_Date__c = system.today() + 7;
                    skid.Date_received__c = system.today();
                    skid.Lot_Number__c = 'LOT 2';
                    rw.putawayType = 'Inventory';
                }
                    
                
            }
        }
        
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        
        try{
            receiveLinesresult = PutawayReceiptsExt.putaway(rwrapperlist, null, null, rdoc, null,'RMA',false);
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains(Label.No_Quantities_Entered_To_Receive), ex.getMessage());
        }
        
        
         system.assert(receiveLinesresult.success == false, receiveLinesresult);
        
        
         for(ReceivingWrapper rw: rwrapperlist){
            
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == fuel.itemList[1].ID){
                    skid.Quantity__c = 2;
                    skid.Expiration_Date__c = system.today() + 7;
                    skid.Date_received__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = null;
                }
                else{
                    skid.Quantity__c = 4;
                    skid.Expiration_Date__c = system.today() + 7;
                    skid.Date_received__c = system.today();
                    skid.Lot_Number__c = 'LOT 2';
                    rw.putawayType = null;
                }
                    
                
            }
        }
        try{
            receiveLinesresult = PutawayReceiptsExt.putaway(rwrapperlist, null, null, rdoc, null,'RMA',false);
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains(Label.Specify_Putaway_Type_For_Line), ex.getMessage());//Validation for putaway type on receipt line will fail
            
        }
       
       system.assert(receiveLinesresult.success == false, receiveLinesresult);
       
       test.stopTest();
       
    }
  
    static testMethod void doPutawayRMALinesWithSerials(){      
        
        TestFuel fuel = new TestFuel();
        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;    
        List<Period__c> periodList = fuel.periodList;
        Facility__c facility1 = fuel.facility2;
        
        //Addeing User Preference
        insert new User_Preference__c(OwnerId = UserInfo.getUserId(),Name = 'my preference',Default_Company__c = fuel.company.Id,Default_Facility__c = fuel.facility2.Id);
        
        fuel.itemList[0].item_attribute__c = fuel.itemAttrObj2.id;
        fuel.itemList[5].item_attribute__c = fuel.itemAttrObj2.id;
        update new list<Item__c>{fuel.itemList[0], fuel.itemList[5]};
        
        
        facility1.RMA_Receipt_Routing__c = 'Inspect';
        update facility1;
        
        //Update Sales Order Type as RMA
        so.Type__c = SalesOrderService.SO_TYPE_RMA;
        so.Status__c = 'Open';
        update so;
        
        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;
        
        
        //Create Receiving Document and Receipt Lines
        Receiving_Document__c rd = new Receiving_Document__c(
                Company__c = fuel.company.id,
                Date_Created__c = system.today(),
                Status__c = 'Draft',
                Type__c = 'RMA Receipt',
                Transaction_Type__c = 'RMA Receipt',
                Currency__c = TestFuel.currencyUSD.id,
                Transaction_Date__C = system.now()
            );
        insert rd;
        List<Receipt_Line__c> receiptlineslist = new List<Receipt_Line__c>(); 
        Receipt_Line__c receiptline1 = new Receipt_Line__c();
        receiptline1.Company__c = fuel.company.Id;
        receiptline1.Sales_Order__c = so.Id;
        receiptline1.Sales_Order_Line__c = soline.Id;
        receiptline1.Item__c = fuel.itemList[0].ID;
        receiptline1.Quantity_Received__c = 10;
        receiptline1.Quantity_Still_Due_For_Putaway__c = 10;
        //receiptline1.Expiration_Date__c = System.today()+5;
        receiptline1.Facility__c = facility1.Id;
        receiptline1.Location__c = fuel.location2.Id;
        receiptline1.Status__c = 'Closed';
        receiptline1.Sales_Order__c = so.id;
        receiptline1.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline1);
        
        Receipt_Line__c receiptline2 = new Receipt_Line__c();
        receiptline2.Company__c = fuel.company.Id;
        receiptline2.Sales_Order__c = so.Id;
        receiptline2.Sales_Order_Line__c = soline1.Id;
        receiptline2.Item__c = fuel.itemList[5].Id;
        receiptline2.Facility__c = facility1.Id;
        receiptline2.Location__c = fuel.location2.Id;
        
        receiptline2.Quantity_Received__c = 15;
        receiptline2.Quantity_Still_Due_For_Putaway__c = 15;
        receiptline2.Status__c = 'Closed';
        receiptline2.Sales_Order__c = so.id;
        receiptline2.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline2);
        
        insert receiptlineslist;
        
        Serial__c serReturns = new Serial__c(
            Name = 'Serial Reentry',
            Item__c = fuel.itemList[0].id,
            Company__c = fuel.company.Id,
            Allow_Reentry__c = true,
            Status__c = 'Voided'
        );
        serReturns.Unique_Key2__c = fuel.company.Id + '-' + serReturns.Item__c + '-' + serReturns.Name;
        insert serReturns;
        
        PutawayReceiptsExt putawayext = new PutawayReceiptsExt();
        PutawayReceiptsExt.setGridConfig('RMA');
        
        putawayext.getreceiptLinesConfigJson();
        //Create ASN with inTransit SKID       
       
        Receiving_Document__c queriedrd = [Select Id, Name, Currency__c  from Receiving_Document__c where Id =:rd.Id]; 
        String docnum = rd.Name;
        ID currencyfilter = queriedrd.Currency__c;
        
        List<Receipt_Line__c> newreceiptlinelist = [Select Id from Receipt_Line__c where Receiving_Document__c =:rd.Id];
        system.assert(newreceiptlinelist.size() == 2, newreceiptlinelist);
        
        List<Id> rlineIds = new List<Id>();
        for(Receipt_Line__c line:newreceiptlinelist){
            rlineIds.add(line.id);
        }
        
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        test.startTest();
       
        PutawayReceiptsExt recon = new PutawayReceiptsExt();
        Map<String,String> configMap = new Map<String,String>();
        
        //Manage Putaway 
        
        getListresult = PutawayReceiptsExt.getList(rlineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = PutawayReceiptsExt.getrdDetails(rlineIds, 'RMA');
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(rlineIds), new set<String>{'Receipt_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
            
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                Sales_Order_Line__c sol = (Sales_Order_Line__c)rw.rl.getSObject('Sales_Order_Line__r');
                if(skid.Item__c == fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Expiration_Date__c = system.today() + 7;
                    skid.Date_received__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Inventory';
                    skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
                    skid.Packaging_UOM__c = sol.Packaging_UOM__c;
                    skid.Packaging_UOM__r = sol.Packaging_UOM__r;
                }
                else{
                    skid.Quantity__c = 4;
                    skid.Expiration_Date__c = system.today() + 7;
                    skid.Date_received__c = system.today();
                    skid.Lot_Number__c = 'LOT 2';
                    rw.putawayType = 'Scrap';
                    skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
                    skid.Packaging_UOM__c = sol.Packaging_UOM__c;
                    skid.Packaging_UOM__r = sol.Packaging_UOM__r;
                }
                
                List<Serial__c> serialList = new List<Serial__c>();
                
                if(skid.Item__c == fuel.itemList[0].ID){
                    
                    serialList.add(serReturns);    
                }
                for (Integer i=0;i<4;i++) {
                    Serial__c ser = new Serial__c(
                        Name = 'Serial ' + i,
                        Item__c = skid.Item__c,
                        Company__c = fuel.company.Id
                    );
                    ser.Unique_Key2__c = fuel.company.Id + '-' + ser.Item__c + '-' + ser.Name;
                    serialList.Add(ser);
                }
                sw.serialList = serialList;
                system.debug('serialList: ' + serialList);
            }
        }
        
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = PutawayReceiptsExt.putaway(rwrapperlist, null, null, rdoc, null,'RMA',false);
        
        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        
        //Also check Quantity_Fulfilled__c on updated solines.                              
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_Still_Due_For_Putaway__c, Item__c, Quantity_Received__c, Quantity_To_Stock__c, Receiving_Document__r.Transaction_Type__c
                                               from Receipt_Line__c where Id =: rlineIds];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c ==rcptline.Quantity_Received__c);
            if(rcptline.Item__c == fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 5, rcptline);
            }
            else if(rcptline.Item__c == fuel.itemList[5].ID){
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 11, rcptline);
            } 
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'RMA Receipt', rcptline.Receiving_Document__r.Transaction_Type__c);            
        }
               
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, 
                Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, 
                To_SKID__r.Name, To_SKID__r.Location__c, ( select Id, Serial__c, Serial__r.Allow_Reentry__c, Serial__r.SKID__c, Type__c From Serial_Transactions__r) 
                FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
        Boolean invflag, scrapflag;
        for(Inventory_Transaction__c it: itlist){
            
            if(it.Inventory_Change__r.Type__c == 'RMA Receipt'){
                invflag = true;
            }
            if(it.Inventory_Change__r.Type__c == 'RMA Scrap'){
                scrapflag = true;
            }
            
            inventorychangeset.add(it.Inventory_Change__c);
            system.assertNotEquals(null, it.Serial_Transactions__r);
            
            if( it.Item__c == fuel.itemList[0].Id ){
                system.assertEquals(5, it.Quantity__c);
                system.assertEquals(5, it.Serial_Transactions__r.size());
                system.assertEquals('RMA Receipt', it.Serial_Transactions__r[0].Type__c);
            }
            else{
                system.assertEquals(4, it.Quantity__c);
                system.assertEquals(4, it.Serial_Transactions__r.size());
                system.assertEquals('RMA Scrap', it.Serial_Transactions__r[0].Type__c);
            }
        }
        system.assert(inventorychangeset.size() ==2);//one for scrap and one for inventory
        system.assert(invflag ==true && scrapflag == true);
       
    }
    
    static testMethod void PutawayMiscLinesWithSerials(){   	
    	
    	TestFuel fuel = new TestFuel();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;    
        List<Period__c> periodList = fuel.periodList;
        Facility__c facility = fuel.facility2;
        
        Fixed_Asset__c fixedAsset = fuel.fixedAsset;
        
        //Addeing User Preference
        insert new User_Preference__c(OwnerId = UserInfo.getUserId(),Name = 'my preference',Default_Company__c = fuel.company.Id,Default_Facility__c = fuel.facility2.Id);
        
        fuel.itemList[0].item_attribute__c = fuel.itemAttrObj2.id;
        fuel.itemList[5].item_attribute__c = fuel.itemAttrObj2.id;
        update new list<Item__c>{fuel.itemList[0], fuel.itemList[5]};
        
        //Create Receiving Document and Receipt Lines
        Receiving_Document__c rd = new Receiving_Document__c(
                Company__c = fuel.company.id,
                Date_Created__c = system.today(),
                Status__c = 'Draft',
                Type__c = 'Miscellaneous Receipt',
                Transaction_Type__c = 'Miscellaneous Receipt',
                Currency__c = TestFuel.currencyUSD.id,
                Transaction_Date__C = system.now()
            );
        insert rd;
        
        List<Receipt_Line__c> receiptlineslist = new List<Receipt_Line__c>(); 
		Receipt_Line__c receiptline1 = new Receipt_Line__c();
        receiptline1.Company__c = fuel.company.Id;
        receiptline1.Item__c = fuel.itemList[0].ID;
        receiptline1.Quantity_Declared__c = 10;
        receiptline1.Facility__c = facility.Id;
        receiptline1.Facility__r = facility;
        receiptline1.Location__c = fuel.location2.Id;
        receiptline1.Status__c = 'Draft';
        receiptline1.Packaging_UOM__c = fuel.uomList[8].id;
        receiptline1.Packaging_UOM__r = fuel.uomList[8];
        receiptline1.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline1);
        
        Receipt_Line__c receiptline2 = new Receipt_Line__c();
        receiptline2.Company__c = fuel.company.Id;
        receiptline2.Item__c = fuel.itemList[5].Id;
        receiptline2.Facility__c = facility.Id;
        receiptline2.Facility__r = facility;
        receiptline2.Location__c = fuel.location2.Id;
        receiptline2.Quantity_Declared__c = 15;
        receiptline2.Status__c = 'Draft';
        receiptline2.Packaging_UOM__c = fuel.uomList[8].id;
        receiptline2.Packaging_UOM__r = fuel.uomList[8];
        receiptline2.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline2);
        
        insert receiptlineslist;
        
        ApexPages.StandardController con = new ApexPages.StandardController(rd);
        ReceivingDocumentReleaseExt rdre = new ReceivingDocumentReleaseExt(con);
        
        rdre.release();
        
        Serial__c serReturns = new Serial__c(
            Name = 'Serial Reentry',
            Item__c = fuel.itemList[0].id,
            Company__c = fuel.company.Id,
            Allow_Reentry__c = true,
            Fixed_Asset__c = fixedAsset.Id, //mimicing linking asset to serial
            Status__c = 'Voided'
        );
        serReturns.Unique_Key2__c = fuel.company.Id + '-' + serReturns.Item__c + '-' + serReturns.Name;
        insert serReturns;
        
        PutawayReceiptsExt putawayext = new PutawayReceiptsExt();
		PutawayReceiptsExt.setGridConfig('Receiving Document');
		
		putawayext.getreceiptLinesConfigJson();
        //Create ASN with inTransit SKID       
       
       	List<Receipt_Line__c> newreceiptlinelist = [Select Id, Status__c, Quantity_Still_Due_For_Putaway__c from Receipt_Line__c where Receiving_Document__c =:rd.Id];
        system.assert(newreceiptlinelist.size() == 2, newreceiptlinelist);
        
        List<Id> rlineIds = new List<Id>();
        for(Receipt_Line__c line:newreceiptlinelist){
        	rlineIds.add(line.id);
        }
        
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        test.startTest();
       
        PutawayReceiptsExt recon = new PutawayReceiptsExt();
        Map<String,String> configMap = new Map<String,String>();
        
        //Manage Putaway 
        
        getListresult = PutawayReceiptsExt.getList(rlineIds, 'Receiving Document');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = PutawayReceiptsExt.getrdDetails(rlineIds, 'Receiving Document');
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = (List<ReceivingWrapper>)getListresult.records;
       
        for(ReceivingWrapper rw: rwrapperlist){
        	
        	for( SkidService3.serialWrapper sw : rw.serialWrapperList){
        		SKID__c skid = sw.skid;
        		
        		if(skid.Item__c == fuel.itemList[0].ID){
        			skid.Quantity__c = 5;
        			skid.Expiration_Date__c = system.today() + 7;
        			skid.Date_received__c = system.today();
        			skid.Lot_Number__c = 'LOT 1';
        			rw.putawayType = 'Inventory';
        			skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
        		}
        		else{
        			skid.Quantity__c = 4;
        			skid.Expiration_Date__c = system.today() + 7;
        			skid.Date_received__c = system.today();
        			skid.Lot_Number__c = 'LOT 2';
        			rw.putawayType = 'Scrap';
        			skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
        		}
        		skid.Packaging_UOM__r.Package_Class__r = null;   
        		List<Serial__c> serialList = new List<Serial__c>();
        		
        		if(skid.Item__c == fuel.itemList[0].ID){
        		    
        		    serialList.add(serReturns);    
        		}
                for (Integer i=0;i<4;i++) {
                    Serial__c ser = new Serial__c(
                        Name = 'Serial ' + i,
                        Item__c = skid.Item__c,
                        Company__c = fuel.company.Id
                    );
                    ser.Unique_Key2__c = fuel.company.Id + '-' + ser.Item__c + '-' + ser.Name;
                    serialList.Add(ser);
                }
                sw.serialList = serialList;
        	}
        }
        
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = PutawayReceiptsExt.putaway(rwrapperlist, null, null, rdoc, null,'RMA',false);
        
        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        
        //Also check Quantity_Fulfilled__c on updated solines.								
		Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_Still_Due_For_Putaway__c, Item__c, Quantity_Received__c, Quantity_To_Stock__c, Receiving_Document__r.Transaction_Type__c,
        									  (select Id,Status__c, Type__c From Work_Orders__r) from Receipt_Line__c where Id =: rlineIds];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
        	receiptlineSet.add(rcptline.Id);
        	system.assert(rcptline.Quantity_To_Stock__c ==rcptline.Quantity_Received__c);
        	if(rcptline.Item__c == fuel.itemList[0].ID){
        		system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 5, rcptline);
        	}
        	else if(rcptline.Item__c == fuel.itemList[5].ID){
        		system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 11, rcptline);
        	} 
            system.assertEquals(0, rcptline.Work_Orders__r.size());
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Miscellaneous Receipt', rcptline.Receiving_Document__r.Transaction_Type__c);            
        }
               
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, 
                Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, 
                To_SKID__r.Name, To_SKID__r.Location__c, ( select Id, Serial__c, Fixed_Asset__c, Serial__r.Fixed_Asset__c, Serial__r.Allow_Reentry__c, Serial__r.SKID__c, Type__c From Serial_Transactions__r) 
        		FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
    
        for(Inventory_Transaction__c it: itlist){
        	
        	system.assert(it.Inventory_Change__r.Type__c == 'Miscellaneous Receipt');
        	
        	inventorychangeset.add(it.Inventory_Change__c);
        	system.assertNotEquals(null, it.Serial_Transactions__r);
        	
        	if( it.Item__c == fuel.itemList[0].Id ){
        	    system.assertEquals(5, it.Quantity__c);
        	    system.assertEquals(5, it.Serial_Transactions__r.size());
        	    system.assertEquals('Miscellaneous Receipt', it.Serial_Transactions__r[0].Type__c);
        	    
        	    Boolean serReturnsAssert = false;
        	    for(Serial_Transaction__c st : it.Serial_Transactions__r){
        	        if( st.Serial__c == serReturns.Id){
        	            system.assertEquals(fixedAsset.Id, st.Fixed_Asset__c);//serial attributes framework
        	            system.assertEquals(fixedAsset.Id, st.Serial__r.Fixed_Asset__c);
        	            serReturnsAssert = true;
        	        }
        	    }
        	    system.assertEquals(true, serReturnsAssert);
        	}
        	else{
        	    system.assertEquals(4, it.Quantity__c);
        	    system.assertEquals(4, it.Serial_Transactions__r.size());
        	    system.assertEquals('Miscellaneous Receipt', it.Serial_Transactions__r[0].Type__c);
        	}
        }
        system.assert(inventorychangeset.size() ==1);
    }
    
    static testMethod void PutawayMiscLinesWithInspection(){   	
    	
    	TestFuel fuel = new TestFuel();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;    
        List<Period__c> periodList = fuel.periodList;
        Facility__c facility = fuel.facility2;
        
        //Addeing User Preference
        insert new User_Preference__c(OwnerId = UserInfo.getUserId(),Name = 'my preference',Default_Company__c = fuel.company.Id,Default_Facility__c = fuel.facility2.Id);
        
        //Create Receiving Document and Receipt Lines
        Receiving_Document__c rd = new Receiving_Document__c(
                Company__c = fuel.company.id,
                Date_Created__c = system.today(),
                Status__c = 'Draft',
                Type__c = 'Miscellaneous Receipt',
                Transaction_Type__c = 'Miscellaneous Receipt',
                Currency__c = TestFuel.currencyUSD.id,
                Transaction_Date__C = system.now()
            );
        insert rd;
        
        List<Receipt_Line__c> receiptlineslist = new List<Receipt_Line__c>(); 
		Receipt_Line__c receiptline1 = new Receipt_Line__c();
        receiptline1.Company__c = fuel.company.Id;
        receiptline1.Item__c = fuel.itemList[14].ID;
        receiptline1.Quantity_Declared__c = 10;
        receiptline1.Facility__c = facility.Id;
        receiptline1.Location__c = fuel.location2.Id;
        receiptline1.Status__c = 'Draft';
        receiptline1.Packaging_UOM__c = fuel.uomList[12].Id;
        receiptline1.Packaging_UOM__r = fuel.uomList[12];
        receiptline1.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline1);
        
        Receipt_Line__c receiptline2 = new Receipt_Line__c();
        receiptline2.Company__c = fuel.company.Id;
        receiptline2.Item__c = fuel.itemList[15].Id;
        receiptline2.Facility__c = facility.Id;
        receiptline2.Location__c = fuel.location2.Id;
        receiptline2.Quantity_Declared__c = 15;
        receiptline2.Status__c = 'Draft';
        receiptline2.Packaging_UOM__c = fuel.uomList[12].Id;
        receiptline2.Packaging_UOM__r = fuel.uomList[12];
        receiptline2.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline2);
        
        insert receiptlineslist;
        
        ApexPages.StandardController con = new ApexPages.StandardController(rd);
        ReceivingDocumentReleaseExt rdre = new ReceivingDocumentReleaseExt(con);
        
        rdre.release();
        
        PutawayReceiptsExt putawayext = new PutawayReceiptsExt();
		PutawayReceiptsExt.setGridConfig('Receiving Document');
		
		putawayext.getreceiptLinesConfigJson();
       	
       	List<Receipt_Line__c> newreceiptlinelist = [Select Id, Status__c, Quantity_Still_Due_For_Putaway__c from Receipt_Line__c where Receiving_Document__c =:rd.Id];
        system.assert(newreceiptlinelist.size() == 2, newreceiptlinelist);
        
        List<Id> rlineIds = new List<Id>();
        for(Receipt_Line__c line:newreceiptlinelist){
        	rlineIds.add(line.id);
        }
        
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        test.startTest();
       
        PutawayReceiptsExt recon = new PutawayReceiptsExt();
        Map<String,String> configMap = new Map<String,String>();
        
        //Manage Putaway 
        
        getListresult = PutawayReceiptsExt.getList(rlineIds, 'Receiving Document');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = PutawayReceiptsExt.getrdDetails(rlineIds, 'Receiving Document');
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = (List<ReceivingWrapper>)getListresult.records;
       
        for(ReceivingWrapper rw: rwrapperlist){
        	
        	for( SkidService3.serialWrapper sw : rw.serialWrapperList){
        		SKID__c skid = sw.skid;
        		
        		if(skid.Item__c == fuel.itemList[14].ID){
        			skid.Quantity__c = 5;
        			skid.Expiration_Date__c = system.today() + 7;
        			skid.Date_received__c = system.today();
        			skid.Lot_Number__c = 'LOT 1';
        			rw.putawayType = 'Inspection';
        			skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
                    
        		}
        		else{
        			skid.Quantity__c = 4;
        			skid.Expiration_Date__c = system.today() + 7;
        			skid.Date_received__c = system.today();
        			skid.Lot_Number__c = 'LOT 2';
        			rw.putawayType = 'Inspection';
        			skid.Stocking_UOM__c = skid.Item__r.Stocking_UOM__c;
        		}
        		
        		List<Serial__c> serialList = new List<Serial__c>();
                sw.serialList = serialList;
        	}
        }
        
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        
        receiveLinesresult = PutawayReceiptsExt.putaway(rwrapperlist, null, null, rdoc, null,'RMA',false);
        
        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        
        //Also check Quantity_Fulfilled__c on updated solines.								
		Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_Still_Due_For_Putaway__c, Item__c, Quantity_Received__c, Quantity_To_Stock__c, Receiving_Document__r.Transaction_Type__c,
        									  (select Id,Status__c, Type__c From Work_Orders__r) from Receipt_Line__c where Id =: rlineIds];
        system.assert(receiptlines.size() == 2, receiptlines);
        
        for(Receipt_Line__c rcptline: receiptlines){
        	receiptlineSet.add(rcptline.Id);
        	system.assert(rcptline.Quantity_To_Stock__c ==rcptline.Quantity_Received__c*2);
        	if(rcptline.Item__c == fuel.itemList[14].ID){
        		system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 5, rcptline);
        	}
        	else if(rcptline.Item__c == fuel.itemList[15].ID){
        		system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 11, rcptline);
        	} 
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Miscellaneous Receipt', rcptline.Receiving_Document__r.Transaction_Type__c);
            
            system.assertEquals(1, rcptline.Work_Orders__r.size());
            system.assertEquals('Draft', rcptline.Work_Orders__r[0].Status__c);
            system.assertEquals('Repair', rcptline.Work_Orders__r[0].Type__c);
        }
               
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, 
                Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, 
                To_SKID__r.Name, To_SKID__r.Location__c, ( select Id, Serial__c, Serial__r.Allow_Reentry__c, Serial__r.SKID__c, Type__c From Serial_Transactions__r) 
        		FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
    
        for(Inventory_Transaction__c it: itlist){
        	
        	system.assert(it.Inventory_Change__r.Type__c == 'Miscellaneous Receipt');
        	
        	inventorychangeset.add(it.Inventory_Change__c);
        	system.assertNotEquals(null, it.Serial_Transactions__r);
        	
        	if( it.Item__c == fuel.itemList[14].Id ){
        	    system.assertEquals(5, it.Quantity__c);
        	    system.assertEquals(0, it.Serial_Transactions__r.size());
        	}
        	else{
        	    system.assertEquals(4, it.Quantity__c);
        	    system.assertEquals(0, it.Serial_Transactions__r.size());
        	}
        }
        system.assert(inventorychangeset.size() ==1);
    }
    
    static testMethod void PutawayMiscLinesErrors(){   	
    	
    	TestFuel fuel = new TestFuel();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;    
        List<Period__c> periodList = fuel.periodList;
        Facility__c facility = fuel.facility2;
        
        //Addeing User Preference
        insert new User_Preference__c(OwnerId = UserInfo.getUserId(),Name = 'my preference',Default_Company__c = fuel.company.Id,Default_Facility__c = fuel.facility2.Id);
        
        //Create Receiving Document and Receipt Lines
        Receiving_Document__c rd = new Receiving_Document__c(
                Company__c = fuel.company.id,
                Date_Created__c = system.today(),
                Status__c = 'Draft',
                Type__c = 'Miscellaneous Receipt',
                Transaction_Type__c = 'Miscellaneous Receipt',
                Currency__c = TestFuel.currencyUSD.id,
                Transaction_Date__C = system.now()
            );
        insert rd;
        
        List<Receipt_Line__c> receiptlineslist = new List<Receipt_Line__c>(); 
		Receipt_Line__c receiptline1 = new Receipt_Line__c();
        receiptline1.Company__c = fuel.company.Id;
        receiptline1.Item__c = fuel.itemList[14].ID;
        receiptline1.Quantity_Declared__c = 10;
        receiptline1.Facility__c = facility.Id;
        receiptline1.Location__c = fuel.location2.Id;
        receiptline1.Status__c = 'Draft';
        receiptline1.Packaging_UOM__c = fuel.uomList[12].Id;
        receiptline1.Packaging_UOM__r = fuel.uomList[12];
        receiptline1.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline1);
        
        Receipt_Line__c receiptline2 = new Receipt_Line__c();
        receiptline2.Company__c = fuel.company.Id;
        receiptline2.Item__c = fuel.itemList[15].Id;
        receiptline2.Facility__c = facility.Id;
        receiptline2.Location__c = fuel.location2.Id;
        receiptline2.Quantity_Declared__c = 15;
        receiptline2.Status__c = 'Draft';
        receiptline2.Packaging_UOM__c = fuel.uomList[12].Id;
        receiptline2.Packaging_UOM__r = fuel.uomList[12];
        receiptline2.Receiving_Document__c = rd.id;
        receiptlineslist.add(receiptline2);
        
        insert receiptlineslist;
        
        ApexPages.StandardController con = new ApexPages.StandardController(rd);
        ReceivingDocumentReleaseExt rdre = new ReceivingDocumentReleaseExt(con);
        
        rdre.release();
        
        PutawayReceiptsExt putawayext = new PutawayReceiptsExt();
		PutawayReceiptsExt.setGridConfig('Receiving Document');
		
		putawayext.getreceiptLinesConfigJson();
       	
       	List<Receipt_Line__c> newreceiptlinelist = [Select Id, Status__c, Quantity_Still_Due_For_Putaway__c from Receipt_Line__c where Receiving_Document__c =:rd.Id];
        system.assert(newreceiptlinelist.size() == 2, newreceiptlinelist);
        
        List<Id> rlineIds = new List<Id>();
        for(Receipt_Line__c line:newreceiptlinelist){
        	rlineIds.add(line.id);
        }
        
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        test.startTest();
       
        PutawayReceiptsExt recon = new PutawayReceiptsExt();
        Map<String,String> configMap = new Map<String,String>();
        
        //Manage Putaway 
        
        getListresult = PutawayReceiptsExt.getList(rlineIds, 'Receiving Document');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = PutawayReceiptsExt.getrdDetails(rlineIds, 'Receiving Document');
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = (List<ReceivingWrapper>)getListresult.records;
       
        for(ReceivingWrapper rw: rwrapperlist){
        	
        	for( SkidService3.serialWrapper sw : rw.serialWrapperList){
        		SKID__c skid = sw.skid;
        		if(skid.Item__c == fuel.itemList[14].ID){
        			skid.Quantity__c = 0;
        			skid.Expiration_Date__c = system.today() + 7;
        			skid.Date_received__c = system.today();
        			skid.Lot_Number__c = 'LOT 1';
        			rw.putawayType = 'Inspection';
        		}
        		else{
        			skid.Quantity__c = 0;
        			skid.Expiration_Date__c = system.today() + 7;
        			skid.Date_received__c = system.today();
        			skid.Lot_Number__c = 'LOT 2';
        			rw.putawayType = 'Inspection';
        		}
        		
        		List<Serial__c> serialList = new List<Serial__c>();
                sw.serialList = serialList;
        	}
        }
        
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        
        try{
        	receiveLinesresult = PutawayReceiptsExt.putaway(rwrapperlist, null, null, rdoc, null,'RMA',false);
        }
        catch(Exception ex){
        	System.assert(ex.getMessage().contains(Label.No_Quantities_Entered_To_Receive), ex.getMessage());
        }
        
        
         system.assert(receiveLinesresult.success == false, receiveLinesresult);
        
        
         for(ReceivingWrapper rw: rwrapperlist){
        	
        	for( SkidService3.serialWrapper sw : rw.serialWrapperList){
        		SKID__c skid = sw.skid;
        		if(skid.Item__c == fuel.itemList[1].ID){
        			skid.Quantity__c = 100;
        			skid.Expiration_Date__c = system.today() + 7;
        			skid.Date_received__c = system.today();
        			skid.Lot_Number__c = 'LOT 1';
        			rw.putawayType = null;
        		}
        		else{
        			skid.Quantity__c = 100;
        			skid.Expiration_Date__c = system.today() + 7;
        			skid.Date_received__c = system.today();
        			skid.Lot_Number__c = 'LOT 2';
        			rw.putawayType = null;
        		}
        			
        		
        	}
        }
        try{
        	receiveLinesresult = PutawayReceiptsExt.putaway(rwrapperlist, null, null, rdoc, null,'RMA',false);
        }
        catch(Exception ex){
        	System.assert(ex.getMessage().contains(Label.Cannot_Over_Receive_For_Putaway), ex.getMessage());
        	
        }
       
       system.assert(receiveLinesresult.success == false, receiveLinesresult);
       
       test.stopTest();
    }
}