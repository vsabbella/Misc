@isTest
private class TransferOrderTests {
    @testSetup
    private static void setupData() {
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Currency__c.sObjectType ,Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, item_attribute__c.sObjectType,Shipment__c.sObjectType,Customer__c.sObjectType, Shipment_Line__c.sObjectType,Product__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.itemAttrObj2 != null);
        System.assert(f.periodList != null);
        System.assert(f.purchaseOrder != null);
        System.assert(f.purchaseOrderLines != null);
        System.assert(f.supplier != null);
        System.assert(f.packageTransferOrder != null);
        delete configList;
        OrderService.release(new Map<Id, Id>{ f.transferOrder.Id => null });
    }

    private static TestFuelQuery fuel = new TestFuelQuery();
    
    
    private static testMethod void pack_receiveTransferOrder() {
        
        Test.startTest();
        Configuration__c configX = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert configX;
        SOQLUtil shipmentQuery1 = new SOQLUtil('Shipment__c');
        shipmentQuery1.addField('Id');
        Shipment__c shipmentToBeDeleted = Database.query(shipmentQuery1.getQuery());
        
        delete shipmentToBeDeleted;
        delete configX;
        OrderService.release(new Map<Id, Id>{ fuel.packageTransferOrder.Id => null });
        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        
        Order_Line__c oline = fuel.packageTransferOrder.Order_Lines__r[0];
        

        insert new User_Preference__c(Default_Company__c = oline.Shipping_Company__c, Default_Facility__c = fuel.facility2.Id, User__c = UserInfo.getUserId());

        update new Location__c(Id = oline.Ship_From_Location__c, Bin_Tracked__c = true);
        Bin__c bin = new Bin__c(Name = 'Bin', Location__c = oline.Ship_From_Location__c);
        insert bin;
        bin = BaseController.getBin(bin.Id);

        fuel.setupInventory(true, false, true);
        delete [SELECT Id FROM Item_Attribute__c WHERE License_Plate_Number__c != true];
        delete [SELECT Id FROM Lot__c];
        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Item__c = :fuel.itemList[14].Id];
        for (SKID__c skid:skids) {
            skid.Expiration_Date__c = null;
            skid.Lot_Number__c = null;
        }
        update skids;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        system.assert(shipmentLines.size()==1,shipmentLines);
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        wrappers[0].line = shipmentLines.get(wrappers[0].line.Id);
        wrappers[0].header = wrappers[0].line.getSObject('Shipment__r');
        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
            
            System.debug('**sw.skid:'+sw.skid);
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        LineWrapper shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.debug('**Plan wrapper uom:'+wrapper.uom);
                System.debug('**Plan Before sw:'+sw);
                if (wrapper.uom == 'PT'){
                    sw.skid.Quantity_to_Issue__c = 1;
                    System.debug('**PT skid:'+sw.skid.Quantity_to_Issue__c);
                } 
                else if (wrapper.uom == 'CS') {
                    sw.skid.Quantity_to_Issue__c = 2;
                    System.debug('**CS Skid:'+sw.skid.Quantity_to_Issue__c);
                }
                else {
                    sw.skid.Quantity_to_Issue__c = 0;
                    System.debug('**Else Skid:'+sw.skid.Quantity_to_Issue__c);
                }
                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                
                
                shlWrapper.serialWrappers.add(sw);
            }
        }
        
        ShipmentInventoryService.plan(new List<LineWrapper>{ shlWrapper });
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.debug('**Before**Plan SKID Qty Issue**:'+sw.skid.Quantity_to_Issue__c);
                if (wrapper.uom == 'PT' || wrapper.uom == 'CS') {
                    sw.skid.Quantity_to_Issue__c = 1;
                }
                else sw.skid.Quantity_to_Issue__c = 0;
                sw.toskid = new SKID__c(Bin__c = bin.Id, Bin__r = bin, License_Plate_Number__r = new LPN__c(Name = 'PACKLPN'));
                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            }
        }
        
        
        delete c;
        ShipmentInventoryService.pick(new List<LineWrapper>{ shlWrapper });

        List<Inventory_Transaction__c> itList = [SELECT Id,Name,Type__c,Quantity__c,Packaging_UOM__r.Name,Mixed_Palletized__c,Container_Item__c,Container_Item__r.Name,License_Plate_Number__r.Name FROM Inventory_Transaction__c WHERE Type__c = 'Transfer Order Pick'];
        
        System.assert(itList.size() == 3, itList.size());
        Test.stopTest(); 
        
        
        itList = [SELECT Id,Name,Type__c,Quantity__c,Packaging_UOM__r.Name,Mixed_Palletized__c,Container_Item__c,Container_Item__r.Name,License_Plate_Number__r.Name FROM Inventory_Transaction__c WHERE Type__c = 'Transfer'];
        System.assert(itList.size() == 2, itList.size());

        skids = [SELECT Id FROM SKID__c WHERE Shipment_Line__c != null];
        System.assert(skids.size() == 2, skids.size());

        skids = [SELECT Id FROM SKID__c WHERE Mixed_Palletized__c = true];
        System.assert(skids.size() == 1, skids.size());
        
        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);
        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records.size());
        wrappers = (List<LineWrapper>)result.records;

        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers.size());
            for(SkidService3.SerialWrapper sw:wrapper.serialWrappers){
                if(wrapper.uom=='PT'){
                    System.assert(sw.skid.Quantity__c == 1, sw.skid);
                }
                else if(wrapper.uom=='CS'){
                    System.assert(sw.skid.Quantity__c == 2, sw.skid);
                }
                
            }
            
        }
        
        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Order_Line__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Shipment_Line__c',
            'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c',

            'Item__r.Stocking_UOM__c','Packaging_UOM__r.Name','Mixed_Palletized__c','To_SKID__r.Mixed_Palletized__c','License_Plate_Number__c','To_SKID__r.License_Plate_Number__c','To_SKID__r.License_Plate_Number__r.Name',

            'Order_Line__r.Deliver_To_Facility__c', 'Order_Line__r.Deliver_To_Location__c', 'Order_Line__r.Order__c', 'Order_Line__r.Quantity_Allocated__c',
            'Order_Line__r.Quantity_Shipped__c', 'Order_Line__r.Order__r.Status__c', 'Order_Line__r.Status__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_Shipped__c',
            'Shipment_Line__r.Shipment__r.Date_Shipped__c', 'Shipment_Line__r.Shipment__r.Locked__c', 'Shipment_Line__r.Shipment__r.Status__c',
            'Shipment_Line__r.Shipment__r.Transaction_Date__c','Container_Item__r.Name',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Order_Line__c', 'To_SKID__r.Packaging_UOM__c','To_SKID__r.Packaging_UOM__r.name', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Transfer Order Shipment\'');

        List<Inventory_Transaction__c> itList1 = Database.query(itQuery.getQuery());
        System.assert(itList1.size() == 2, itList);
        Boolean caseToSkidCheck= false;
        Boolean palletToSkidCheck=false;
        for (Inventory_Transaction__c it:itList1) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Shipment_Line__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            
            System.assert(it.To_Facility__c == it.Order_Line__r.Deliver_To_Facility__c, it);
            System.assert(it.To_Location__c == it.Order_Line__r.Deliver_To_Location__c, it);
            System.assert(it.From_SKID__c == null, it);
            System.assert(it.To_SKID__c != null, it);
            system.assert(it.Packaging_UOM__r.Name == 'PT' || it.Packaging_UOM__r.Name == 'CS',it.Packaging_UOM__r.Name);
            if(it.Packaging_UOM__r.Name =='PT'){
                System.assert(it.Quantity__c == 1, it);
                System.assert(it.Quantity_Stocking_UOM__c == 6, it);
                System.assert(it.Container_Item__c == fuel.itemList[13].Id, it.Container_Item__r.Name);
                
            }
            else if(it.Packaging_UOM__r.Name =='CS'){
                System.assert(it.Quantity__c == 2, it);
                System.assert(it.Quantity_Stocking_UOM__c == 4, it);
                System.assert(it.Container_Item__c == fuel.itemList[13].Id, it.Container_Item__r.Name);//Pallet Container for Mixed Palletized
            }
            System.assert(it.License_Plate_Number__c !=null,it);
            SKID__c toSkid = it.To_SKID__r;
            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_INTRANSIT, toSkid);
            if(it.Packaging_UOM__r.Name =='CS'){
                System.assert(toSkid.Mixed_Palletized__c == true, toSkid);
                System.assert(toSkid.License_Plate_Number__c !=null,toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == 4, toSkid);
                System.assert(toSkid.Packaging_UOM__c == it.Packaging_UOM__c, toSkid.Packaging_UOM__r.Name);
                System.assert(toSkid.Container_Item__c == fuel.itemList[13].Id, toSkid);//Pallet Container for Mixed Palletized
                caseToSkidCheck = true;
            }
            else if(it.Packaging_UOM__r.Name =='PT'){
                System.assert(toSkid.Mixed_Palletized__c == false, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == 6, toSkid);
                System.assert(toSkid.Packaging_UOM__c == it.Packaging_UOM__c, toSkid.Packaging_UOM__r.Name);
                System.assert(toSkid.Container_Item__c == fuel.itemList[13].Id, toSkid);
                palletToSkidCheck = true;
            }
            
            System.assert(toSkid.Quantity__c == it.Quantity__c, toSkid);
            
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);
            System.assert(toSkid.Order_Line__c == it.Order_Line__c, toSkid);

            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Shipped__c == it.Shipment_Line__r.Quantity_Planned__c, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == true, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c != null, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Transaction_Date__c != null, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Order_Line__r.Quantity_Allocated__c == 0, it.Order_Line__r);
            System.assert(it.Order_Line__r.Quantity_Shipped__c == it.Shipment_Line__r.Quantity_Planned__c, it.Order_Line__r);
            System.assert(it.Order_Line__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r);
            System.assert(it.Order_Line__r.Order__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r.Order__r);
        }
        
        system.assert(caseToSkidCheck == true && palletToSkidCheck == true,caseToSkidCheck);
         
         //Receiving Workbench
        
        
        String docnum = fuel.packageTransferOrder.Id;
        
        JSONResult searchresult = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();         
        
       
        List<Id> tolineIds = new List<Id>();
        tolineIds.add(oline.Id);
        
        List<SKID__c> transitSKIDs = [Select Id,Mixed_Palletized__c,License_Plate_Number__c,Packaging_UOM__r.Name from SKID__c where Order_Line__c IN :tolineIds];
        system.assert(transitSKIDs.size()==2,transitSKIDs);
        for(SKID__c sk:transitSKIDs){
            system.assert(sk.License_Plate_Number__c !=null,sk);
            if(sk.Packaging_UOM__r.Name == 'CS'){
                system.assert(sk.Mixed_Palletized__c ==true,sk);
            }
            else if(sk.Packaging_UOM__r.Name == 'PT'){
                system.assert(sk.Mixed_Palletized__c ==false,sk);
            }
            
        }
        
         
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(tolineIds, 'Transfer Order',fuel.currencyUSD.Id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(tolineIds), new set<String>{'Order_Line__c'.toLowerCase()} );
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        rdoc.Currency__c = fuel.currencyUSD.id;
        rdoc.Transaction_Date__c = system.now() +2;
        system.assert(rdocresult.records.size() == 1, rdocresult);
               
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                if(sw.skid.Packaging_UOM__r.name == 'PT'){
                    system.assert(sw.skid.Quantity__c == 1);
                    system.assert(sw.skid.Mixed_Palletized__c ==false);
                }
                else if(sw.skid.Packaging_UOM__r.name == 'CS'){
                    system.assert(sw.skid.Quantity__c == 2);
                    system.assert(sw.skid.Mixed_Palletized__c ==true);
                    system.assert(sw.skid.License_Plate_Number__c !=null,rwrapperlist);  
                }
                system.assert(sw.skid.Container_Item__c == fuel.itemList[13].Id);//Pallet Container on Transit SKID
            
            }
        }
       
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
       
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        Configuration__c config1 = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert config1;
        List<Order_Line__c> updatedtolines = [Select Id, Status__c, Quantity_Still_Due__c, Quantity_To_Receive__c, Quantity_Received__c from Order_Line__c where Order__c =: fuel.packageTransferOrder.Id];
        system.assert(updatedtolines.size()>0, updatedtolines);
        
        for(Order_Line__c line:updatedtolines){            
            system.assert(line.Status__c == 'Closed', line);
            system.assert(line.Quantity_To_Receive__c == 0, line.Quantity_To_Receive__c);       
        }
        
        
        List<Receipt_Line__c> receiptLines = [SELECT Id,Order__c,Order_Line__c,Order_Line__r.Quantity_Received__c,Status__c,Quantity_Received__c,Receiving_Document__r.Status__c,Receiving_Document__r.Finalized__c,Receiving_Document__r.Type__c,Receiving_Document__r.Transaction_Type__c FROM Receipt_Line__c WHERE Receipt_Line__c.Receiving_Document__r.Type__c = 'Transfer Order Receipt'];
        
        System.assert(receiptLines.size() == 1,receiptLines);
        for (Receipt_Line__c rl:receiptLines) {
            System.assert(rl.Order__c == fuel.packageTransferOrder.Id,rl);
            System.assert(rl.Status__c == 'Closed',rl);
            System.assert(rl.Receiving_Document__r.Status__c == 'Closed',rl.Receiving_Document__r);
            System.assert(rl.Receiving_Document__r.Finalized__c,rl.Receiving_Document__r);
            System.assert(rl.Receiving_Document__r.Type__c == 'Transfer Order Receipt',rl.Receiving_Document__r);
            System.assert(rl.Receiving_Document__r.Transaction_Type__c == 'Transfer Order Receipt',rl.Receiving_Document__r);
            System.assert(rl.Quantity_Received__c == rl.Order_Line__r.Quantity_Received__c,rl);
        }
            
        List<Inventory_Transaction__c> itList2 = [SELECT Id,Item__c,To_SKID__r.Container_Item__c,Order_Line__r.Quantity_Received__c,Packaging_UOM__r.Name,To_SKID__r.License_Plate_Number__c,From_SKID__c,To_SKID__c,Quantity__c,Type__c,Subtransaction_Type__c FROM Inventory_Transaction__c WHERE Receipt_Line__c IN :receiptLines];
        System.assert(itList2.size() == 2,itList2);
        
        for (Inventory_Transaction__c it:itList2) {
            System.assert(it.To_SKID__c != null,it);
            System.assert(it.Subtransaction_Type__c == 'Transfer Order Receipt',it);
            system.assert(it.Type__c == 'Transfer Order Receipt',it); 
            system.assert(it.Packaging_UOM__r.Name == 'PT' || it.Packaging_UOM__r.Name == 'CS',it.Packaging_UOM__r.Name);
            if(it.Packaging_UOM__r.Name=='PT'){
                System.assert(it.Quantity__c == 1, it.Order_Line__r);
                System.assert(it.To_SKID__r.License_Plate_Number__c != null, it.Order_Line__r);
                system.assert(it.To_SKID__r.Container_Item__c == fuel.itemList[13].Id);
            }
            else if(it.Packaging_UOM__r.Name=='CS'){
                System.assert(it.Quantity__c == 2, it.Order_Line__r);
                System.assert(it.To_SKID__r.License_Plate_Number__c == null, it.Order_Line__r);//LPN should be removed from loc skid.
                system.assert(it.To_SKID__r.Container_Item__c == fuel.itemList[12].Id);//Changed to Case Container
            }
            
        } 
        
    }
    
    /* FIX ME
    private static testMethod void pack_RecieveandVoidRD_TransferOrder() {
        
        Test.startTest();
        Configuration__c configX = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert configX;
        SOQLUtil shipmentQuery1 = new SOQLUtil('Shipment__c');
        shipmentQuery1.addField('Id');
        Shipment__c shipmentToBeDeleted = Database.query(shipmentQuery1.getQuery());
        
        delete shipmentToBeDeleted;
        delete configX;
        OrderService.release(new Map<Id, Id>{ fuel.packageTransferOrder.Id => null });
        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        
        Order_Line__c oline = fuel.packageTransferOrder.Order_Lines__r[0];
        

        insert new User_Preference__c(Default_Company__c = oline.Shipping_Company__c, Default_Facility__c = fuel.facility2.Id, User__c = UserInfo.getUserId());

        update new Location__c(Id = oline.Ship_From_Location__c, Bin_Tracked__c = true);
        Bin__c bin = new Bin__c(Name = 'Bin', Location__c = oline.Ship_From_Location__c);
        insert bin;
        bin = BaseController.getBin(bin.Id);

        fuel.setupInventory(true, false, true);
        delete [SELECT Id FROM Item_Attribute__c WHERE License_Plate_Number__c != true];
        delete [SELECT Id FROM Lot__c];
        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Item__c = :fuel.itemList[14].Id];
        for (SKID__c skid:skids) {
            skid.Expiration_Date__c = null;
            skid.Lot_Number__c = null;
        }
        update skids;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        //delete c;
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        system.assert(shipmentLines.size()==1,shipmentLines);
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        wrappers[0].line = shipmentLines.get(wrappers[0].line.Id);
        wrappers[0].header = wrappers[0].line.getSObject('Shipment__r');
        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
            
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        LineWrapper shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (wrapper.uom == 'PT'){
                    sw.skid.Quantity_to_Issue__c = 1;
                } 
                else if (wrapper.uom == 'CS') {
                    sw.skid.Quantity_to_Issue__c = 2;
                }
                else {
                    sw.skid.Quantity_to_Issue__c = 0;
                }
                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            }
        }
        
        ShipmentInventoryService.plan(new List<LineWrapper>{ shlWrapper });
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (wrapper.uom == 'PT' || (wrapper.uom == 'CS' && sw.skid.License_Plate_Number__c == null)) {
                    sw.skid.Quantity_to_Issue__c = 1;
                }
                else sw.skid.Quantity_to_Issue__c = 0;
                sw.toskid = new SKID__c(Bin__c = bin.Id, Bin__r = bin, License_Plate_Number__r = new LPN__c(Name = 'PACKLPN'));
                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                
                shlWrapper.serialWrappers.add(sw);
            }
        }
        
        
        delete c;
        ShipmentInventoryService.pick(new List<LineWrapper>{ shlWrapper });

        Test.stopTest(); 
        
        Configuration__c config = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert config;
        
        
        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);
        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records.size());
        wrappers = (List<LineWrapper>)result.records;

        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers.size());
            for(SkidService3.SerialWrapper sw:wrapper.serialWrappers){
                if(wrapper.uom=='PT'){
                    System.assert(sw.skid.Quantity__c == 1, sw.skid);
                }
                else if(wrapper.uom=='CS'){
                    System.assert(sw.skid.Quantity__c == 2, sw.skid);
                }
                
            }
            
        }
        
        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);
        
         //Receiving
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();         
        
        List<Id> tolineIds = new List<Id>();
        tolineIds.add(oline.Id);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(tolineIds, 'Transfer Order',fuel.currencyUSD.Id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(tolineIds), new set<String>{'Order_Line__c'.toLowerCase()} );
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        rdoc.Currency__c = fuel.currencyUSD.id;
        rdoc.Transaction_Date__c = system.now() +2;
        system.assert(rdocresult.records.size() == 1, rdocresult);
               
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                if(sw.skid.Packaging_UOM__r.name == 'PT'){
                    system.assert(sw.skid.Quantity__c == 1);
                    system.assert(sw.skid.Mixed_Palletized__c ==false);
                }
                else if(sw.skid.Packaging_UOM__r.name == 'CS'){
                    system.assert(sw.skid.Quantity__c == 2);
                    system.assert(sw.skid.Mixed_Palletized__c ==true);
                    system.assert(sw.skid.License_Plate_Number__c !=null,rwrapperlist);  
                }
                system.assert(sw.skid.Container_Item__c == fuel.itemList[13].Id);//Pallet Container on Transit SKID
            
            }
        }
        delete config;
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        Configuration__c config1 = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert config1;
        
        ReceivingDocumentVoidCancelService vcs = new ReceivingDocumentVoidCancelService(new List<Receiving_Document__c>{ rdoc });
        vcs.getBusinessVoidCancelDetails(new List<Receiving_Document__c>{ rdoc });
        delete config1;
        vcs.businessVoid(new List<Receiving_Document__c>{ rdoc });


        //List<SKID__c> toSupplySkids = [SELECT Id FROM SKID__c WHERE Type__c = 'TO Supply'];
        //System.assert(toSupplySkids.size() == 2,toSupplySkids);
        
        List<SKID__c> toInTransitSkids = [SELECT Id,Type__c,Container_Item__r.Name,Container_Item__c,Order_Line__r.Status__c,Order_Line__r.Quantity_To_Receive__c,Order_Line__r.Quantity_Shipped__c,Mixed_Palletized__c,License_Plate_Number__c,Packaging_UOM__r.Name FROM SKID__c WHERE Type__c IN('In-Transit','TO Supply')];
        System.assert(toInTransitSkids.size() == 4,toInTransitSkids);
        List<SKID__c> toSupplySkids = new List<SKID__c>();
        for(SKID__c sk:toInTransitSkids){
            if(sk.Type__c == 'TO Supply'){
                toSupplySkids.add(sk);
                continue;
            }
            if(sk.Packaging_UOM__r.Name == 'CS'){
                System.assert(sk.Mixed_Palletized__c == true,sk);
                System.assert(sk.Container_Item__c == fuel.itemList[13].Id, sk.Container_Item__r.Name);//Pallet Container for Mixed Palletized
                System.assert(sk.License_Plate_Number__c !=null,sk);
            }
            System.assert(sk.Order_Line__r.Status__c =='Open',sk.Order_Line__r);
            system.assert(sk.Order_Line__r.Quantity_To_Receive__c == sk.Order_Line__r.Quantity_Shipped__c, sk.Order_Line__r.Quantity_To_Receive__c); 
            
        }
        System.assert(toSupplySkids.size() == 2,toSupplySkids);
        List<Receipt_Line__c> rlforvoidList = [SELECT Id,Status__c,Receiving_Document__r.Status__c FROM Receipt_Line__c WHERE Receiving_Document__c = :rdoc.Id];
        System.assert(rlforvoidList.size() == 1,rlforvoidList.size());
        for(Receipt_Line__c rl:rlforvoidList){
        	System.assert(rl.Receiving_Document__r.Status__c == 'Void',rl.Receiving_Document__r);
        	System.assert(rl.Status__c == 'Void',rl); 
        }
        
        
    }*/

    private static testMethod void allocateNoAttributes() {
        fuel.setupInventory();

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                System.assert(sw.skid.Quantity_Available__c == 100, sw);
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 4, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Order_Line__c == skid.Shipment_Line__r.Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__r.Quantity_Allocated__c == 5, skid.Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);

            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 5, skid);
            } else if (skid.Type__c == SkidService3.SKID_TYPE_TO_DEMAND) {
                System.assert(skid.Quantity__c == (skid.Shipment_Line__r.Quantity_Planned__c - 5), skid);
                System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            } else {
                System.assert(false, 'Unexpected skid type: ' + skid.Type__c);
            }
        }

        Test.startTest();
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) {
                    System.assert(sw.skid.Quantity_Allocated__c == 5, sw);
                    System.assert(sw.skid.Quantity_Available__c == 95, sw);
                    sw.skid.Input_Quantity__c = -5;
                } else {
                    System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                    System.assert(sw.skid.Quantity_Available__c == 100, sw);
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_TO_DEMAND);
            System.assert(skid.Quantity__c == skid.Shipment_Line__r.Quantity_Planned__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            System.assert(skid.Order_Line__c == skid.Shipment_Line__r.Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__r.Quantity_Allocated__c == 0, skid.Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_PLANNED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void allocateAttributes() {
        fuel.setupInventory(true);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                System.assert(sw.skid.Quantity_Available__c == 100, sw);
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 4, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Order_Line__c == skid.Shipment_Line__r.Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__r.Quantity_Allocated__c == 5, skid.Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);

            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 5, skid);
            } else if (skid.Type__c == SkidService3.SKID_TYPE_TO_DEMAND) {
                System.assert(skid.Quantity__c == (skid.Shipment_Line__r.Quantity_Planned__c - 5), skid);
                System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            } else {
                System.assert(false, 'Unexpected skid type: ' + skid.Type__c);
            }
        }

        Test.startTest();
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) {
                    System.assert(sw.skid.Quantity_Allocated__c == 5, sw);
                    System.assert(sw.skid.Quantity_Available__c == 95, sw);
                    sw.skid.Input_Quantity__c = -5;
                } else {
                    System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                    System.assert(sw.skid.Quantity_Available__c == 100, sw);
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_TO_DEMAND);
            System.assert(skid.Quantity__c == skid.Shipment_Line__r.Quantity_Planned__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            System.assert(skid.Order_Line__c == skid.Shipment_Line__r.Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__r.Quantity_Allocated__c == 0, skid.Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_PLANNED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void allocateSerials() {
        fuel.setupInventory(true, true);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                System.assert(sw.skid.Quantity_Available__c == 10, sw);
                if (sw.skid.Location__c == fuel.location3.Id) {
                    sw.skid.Input_Quantity__c = 5;
                    sw.serialList[0].Temporary_Value_Holder__c = 'Allocate';
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery, 'Allocated_Serials__r');
        serialQuery.addFields(new Set<String>{ 'Id', 'Allow_Reentry__c', 'Company__c', 'Item__c', 'SKID__c' });
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 4, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Order_Line__c == skid.Shipment_Line__r.Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__r.Quantity_Allocated__c == 5, skid.Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);

            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 5, skid);
                System.assert(skid.Allocated_Serials__r.size() == 1, skid.Allocated_Serials__r);
                System.assert(skid.Allocated_Serials__r[0].Allow_Reentry__c == false, skid.Allocated_Serials__r[0]);
                System.assert(skid.Allocated_Serials__r[0].Company__c == skid.Shipment_Line__r.Company__c, skid.Allocated_Serials__r[0]);
                System.assert(skid.Allocated_Serials__r[0].Item__c == skid.Item__c, skid.Allocated_Serials__r[0]);
                System.assert(skid.Allocated_Serials__r[0].SKID__c != null, skid.Allocated_Serials__r[0]);
            } else if (skid.Type__c == SkidService3.SKID_TYPE_TO_DEMAND) {
                System.assert(skid.Quantity__c == (skid.Shipment_Line__r.Quantity_Planned__c - 5), skid);
                System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            } else {
                System.assert(false, 'Unexpected skid type: ' + skid.Type__c);
            }
        }

        Test.startTest();
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) {
                    System.assert(sw.skid.Quantity_Allocated__c == 5, sw);
                    System.assert(sw.skid.Quantity_Available__c == 5, sw);
                    sw.skid.Input_Quantity__c = -5;
                    sw.serialList[0].Temporary_Value_Holder__c = 'Unallocate';
                } else {
                    System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                    System.assert(sw.skid.Quantity_Available__c == 10, sw);
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_TO_DEMAND);
            System.assert(skid.Quantity__c == skid.Shipment_Line__r.Quantity_Planned__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            System.assert(skid.Order_Line__c == skid.Shipment_Line__r.Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__r.Quantity_Allocated__c == 0, skid.Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_PLANNED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void planPickNoAttributes() {
        fuel.setupInventory();

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 0, sw);
            System.assert(sw.skid.Quantity_Available__c == 5, sw);
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c',
            'Shipment_Line__r.Shipment__c','Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c != \'' + SkidService3.SKID_TYPE_TO_DEMAND + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_PLANNED, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        }
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());

        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 5, sw);
            System.assert(sw.skid.Quantity_Available__c == 0, sw);
            sw.skid.Quantity_to_Issue__c = -5;
            sw.skid.Input_Quantity__c = -5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.plan(wrappers);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__c == skid.Shipment_Line__r.Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__r.Quantity_Allocated__c == 5, skid.Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void planPickAttributes() {
        fuel.setupInventory(true);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 0, sw);
            System.assert(sw.skid.Quantity_Available__c == 5, sw);
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c',
            'Shipment_Line__r.Shipment__c','Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c != \'' + SkidService3.SKID_TYPE_TO_DEMAND + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_PLANNED, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        }
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());

        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 5, sw);
            System.assert(sw.skid.Quantity_Available__c == 0, sw);
            sw.skid.Quantity_to_Issue__c = -5;
            sw.skid.Input_Quantity__c = -5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.plan(wrappers);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__c == skid.Shipment_Line__r.Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__r.Quantity_Allocated__c == 5, skid.Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void planPickSerials() {
        fuel.setupInventory(true, true);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 0, sw);
            System.assert(sw.skid.Quantity_Available__c == 5, sw);
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.serialList[0].Temporary_Value_Holder__c = 'Plan';
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c',
            'Shipment_Line__r.Shipment__c','Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c != \'' + SkidService3.SKID_TYPE_TO_DEMAND + '\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery, 'Allocated_Serials__r');
        serialQuery.addFields(new Set<String>{ 'Id', 'Allow_Reentry__c', 'Company__c', 'Item__c', 'SKID__c' });
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_PLANNED, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
            System.assert(skid.Allocated_Serials__r.size() == 1, skid.Allocated_Serials__r);
            System.assert(skid.Allocated_Serials__r[0].Allow_Reentry__c == false, skid.Allocated_Serials__r[0]);
            System.assert(skid.Allocated_Serials__r[0].Company__c == skid.Shipment_Line__r.Company__c, skid.Allocated_Serials__r[0]);
            System.assert(skid.Allocated_Serials__r[0].Item__c == skid.Item__c, skid.Allocated_Serials__r[0]);
            System.assert(skid.Allocated_Serials__r[0].SKID__c != null, skid.Allocated_Serials__r[0]);
        }
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());

        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 5, sw);
            System.assert(sw.skid.Quantity_Available__c == 0, sw);
            sw.skid.Quantity_to_Issue__c = -5;
            sw.skid.Input_Quantity__c = -5;
            sw.serialList[0].Temporary_Value_Holder__c = 'Unplan';
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.plan(wrappers);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__c == skid.Shipment_Line__r.Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Order_Line__r.Quantity_Allocated__c == 5, skid.Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void pickNoAttributes() {
        fuel.setupInventory();

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 0, sw);
            System.assert(sw.skid.Quantity_Available__c == 5, sw);
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Order_Line__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Type__c == 'Transfer Order Pick', it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);

            System.assert(it.From_SKID__c != null, it);
            System.assert(it.From_SKID__r.Quantity__c == 95, it.From_SKID__r);
            System.assert(it.From_SKID__r.Quantity_Stocking_UOM__c == it.From_SKID__r.Quantity__c, it.From_SKID__r);

            System.assert(it.To_SKID__c != null, it);
            System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
            System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity__c == 5, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);

            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 5, sw);
            System.assert(sw.skid.Quantity_Available__c == 0, sw);
            sw.skid.Quantity_to_Issue__c = -5;
            sw.skid.Input_Quantity__c = -5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Transfer Order Pick\'');

        itList = Database.query(itQuery.getQuery());

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Type__c == 'Transfer Order Undo Pick', it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.From_SKID__c == null, it);

            System.assert(it.To_SKID__c != null, it);
            System.assert(it.To_SKID__r.Quantity__c == 100, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);

            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
        }
        
        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void pickAttributes() {
        fuel.setupInventory(true);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 0, sw);
            System.assert(sw.skid.Quantity_Available__c == 5, sw);
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Order_Line__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Type__c == 'Transfer Order Pick', it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);

            System.assert(it.From_SKID__c != null, it);
            System.assert(it.From_SKID__r.Quantity__c == 95, it.From_SKID__r);
            System.assert(it.From_SKID__r.Quantity_Stocking_UOM__c == it.From_SKID__r.Quantity__c, it.From_SKID__r);

            System.assert(it.To_SKID__c != null, it);
            System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
            System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity__c == 5, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);

            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 5, sw);
            System.assert(sw.skid.Quantity_Available__c == 0, sw);
            sw.skid.Quantity_to_Issue__c = -5;
            sw.skid.Input_Quantity__c = -5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Transfer Order Pick\'');

        itList = Database.query(itQuery.getQuery());

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Type__c == 'Transfer Order Undo Pick', it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.From_SKID__c == null, it);

            System.assert(it.To_SKID__c != null, it);
            System.assert(it.To_SKID__r.Quantity__c == 100, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);

            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
        }
        
        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void pickSerials() {
        fuel.setupInventory(true, true);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 0, sw);
            System.assert(sw.skid.Quantity_Available__c == 5, sw);
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            for (Integer i = 0; i < 5; i++) sw.serialList[i].Temporary_Value_Holder__c = 'Pick';
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Order_Line__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery, 'Serial_Transactions__r');
        stQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Facility__c', 'Item__c', 'Serial__c', 'Serial_Parent__c', 'Type__c',

            'Serial__r.Allocated_SKID__c', 'Serial__r.Allow_Reentry__c', 'Serial__r.Company__c', 'Serial__r.Item__c', 'Serial__r.SKID__c' });
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Type__c == 'Transfer Order Pick', it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);

            System.assert(it.From_SKID__c != null, it);
            System.assert(it.From_SKID__r.Quantity__c == 5, it.From_SKID__r);
            System.assert(it.From_SKID__r.Quantity_Stocking_UOM__c == it.From_SKID__r.Quantity__c, it.From_SKID__r);

            System.assert(it.To_SKID__c != null, it);
            System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
            System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity__c == 5, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);

            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r);
            for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                System.assert(st.Company__c == it.Company__c, st);
                System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
                System.assert(st.Item__c == it.Item__c, st);
                System.assert(st.Serial__c != null, st);
                System.assert(st.Serial_Parent__c == null, st);
                System.assert(st.Type__c == 'Pick', st);
                System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
                System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
                System.assert(st.Serial__r.Company__c == it.Company__c, st.Serial__r);
                System.assert(st.Serial__r.Item__c == it.Item__c, st.Serial__r);
                System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
            }
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 5, sw);
            System.assert(sw.skid.Quantity_Available__c == 0, sw);
            sw.skid.Quantity_to_Issue__c = -5;
            sw.skid.Input_Quantity__c = -5;
            for (Integer i = 0; i < 5; i++) sw.serialList[i].Temporary_Value_Holder__c = 'Unpick';
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Transfer Order Pick\'');

        itList = Database.query(itQuery.getQuery());

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Type__c == 'Transfer Order Undo Pick', it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.From_SKID__c == null, it);

            System.assert(it.To_SKID__c != null, it);
            System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);

            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r);
            for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                System.assert(st.Company__c == it.Company__c, st);
                System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
                System.assert(st.Item__c == it.Item__c, st);
                System.assert(st.Serial__c != null, st);
                System.assert(st.Serial_Parent__c == null, st);
                System.assert(st.Type__c == 'Undo Pick', st);
                System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
                System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
                System.assert(st.Serial__r.Company__c == it.Company__c, st.Serial__r);
                System.assert(st.Serial__r.Item__c == it.Item__c, st.Serial__r);
                System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
            }
        }
        
        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void shipNoAttributes() {
        fuel.setupInventory();

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = (Decimal)wrapper.line.get('Quantity_Planned__c');
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_to_Issue__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            System.assert(sw.skid.Input_Quantity__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_to_Issue__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            System.assert(sw.skid.Input_Quantity__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        ShipmentInventoryService.pick(wrappers);

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);
        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 2, result.records);
        wrappers = (List<LineWrapper>)result.records;

        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
        }

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Order_Line__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Shipment_Line__c',
            'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c',

            'Item__r.Stocking_UOM__c',

            'Order_Line__r.Deliver_To_Facility__c', 'Order_Line__r.Deliver_To_Location__c', 'Order_Line__r.Order__c', 'Order_Line__r.Quantity_Allocated__c',
            'Order_Line__r.Quantity_Shipped__c', 'Order_Line__r.Order__r.Status__c', 'Order_Line__r.Status__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_Shipped__c',
            'Shipment_Line__r.Shipment__r.Date_Shipped__c', 'Shipment_Line__r.Shipment__r.Locked__c', 'Shipment_Line__r.Shipment__r.Status__c',
            'Shipment_Line__r.Shipment__r.Transaction_Date__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Order_Line__c', 'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Transfer Order Shipment\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == it.Shipment_Line__r.Quantity_Shipped__c, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Shipment_Line__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.To_Facility__c == it.Order_Line__r.Deliver_To_Facility__c, it);
            System.assert(it.To_Location__c == it.Order_Line__r.Deliver_To_Location__c, it);
            System.assert(it.From_SKID__c == null, it);
            System.assert(it.To_SKID__c != null, it);

            SKID__c toSkid = it.To_SKID__r;
            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_INTRANSIT, toSkid);
            System.assert(toSkid.Quantity__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Quantity_Stocking_UOM__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Container_Item__c == it.Container_Item__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);
            System.assert(toSkid.Order_Line__c == it.Order_Line__c, toSkid);

            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Shipped__c == it.Shipment_Line__r.Quantity_Planned__c, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == true, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c != null, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Transaction_Date__c != null, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Order_Line__r.Quantity_Allocated__c == 0, it.Order_Line__r);
            System.assert(it.Order_Line__r.Quantity_Shipped__c == it.Shipment_Line__r.Quantity_Planned__c, it.Order_Line__r);
            System.assert(it.Order_Line__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r);
            System.assert(it.Order_Line__r.Order__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r.Order__r);
        }

        ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(!ext.shipMode, ext);
        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() != null, shipment);

        result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 2, result.records);
        wrappers = (List<LineWrapper>)result.records;

        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
        }

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        Test.stopTest();

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Transfer Order Undo Shipment\'');

        itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == it.Shipment_Line__r.Quantity_Planned__c, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Shipment_Line__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Order_Line__r.Deliver_To_Facility__c, it);
            System.assert(it.From_Location__c == it.Order_Line__r.Deliver_To_Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.To_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_SKID__c == null, it);
            System.assert(it.To_SKID__c != null, it);

            SKID__c toSkid = it.To_SKID__r;
            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
            System.assert(toSkid.Quantity__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Quantity_Stocking_UOM__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Container_Item__c == it.Container_Item__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);
            System.assert(toSkid.Shipment_Line__c == it.Shipment_Line__c, toSkid);

            System.assert(it.Shipment_Line__r.Quantity_Picked__c == it.Shipment_Line__r.Quantity_Planned__c, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == false, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c == null, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Order_Line__r.Quantity_Allocated__c == it.Shipment_Line__r.Quantity_Planned__c, it.Order_Line__r);
            System.assert(it.Order_Line__r.Quantity_Shipped__c == 0, it.Order_Line__r);
            System.assert(it.Order_Line__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r);
            System.assert(it.Order_Line__r.Order__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r.Order__r);
        }
    }
    
    //Receive Transfer Order
    
    private static testMethod void receiveTransferOrder() {
        fuel.setupInventory();

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = (Decimal)wrapper.line.get('Quantity_Planned__c');
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }

        
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_to_Issue__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            System.assert(sw.skid.Input_Quantity__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_to_Issue__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            System.assert(sw.skid.Input_Quantity__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        ShipmentInventoryService.pick(wrappers);
        
        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);
        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        Test.startTest();
        System.assert(result.success, result);
        System.assert(result.records.size() == 2, result.records);
        wrappers = (List<LineWrapper>)result.records;

        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
        }

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Order_Line__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Shipment_Line__c',
            'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c',

            'Item__r.Stocking_UOM__c',

            'Order_Line__r.Deliver_To_Facility__c', 'Order_Line__r.Deliver_To_Location__c', 'Order_Line__r.Order__c', 'Order_Line__r.Quantity_Allocated__c',
            'Order_Line__r.Quantity_Shipped__c', 'Order_Line__r.Order__r.Status__c', 'Order_Line__r.Status__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_Shipped__c',
            'Shipment_Line__r.Shipment__r.Date_Shipped__c', 'Shipment_Line__r.Shipment__r.Locked__c', 'Shipment_Line__r.Shipment__r.Status__c',
            'Shipment_Line__r.Shipment__r.Transaction_Date__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Order_Line__c', 'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Transfer Order Shipment\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == it.Shipment_Line__r.Quantity_Shipped__c, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Shipment_Line__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.To_Facility__c == it.Order_Line__r.Deliver_To_Facility__c, it);
            System.assert(it.To_Location__c == it.Order_Line__r.Deliver_To_Location__c, it);
            System.assert(it.From_SKID__c == null, it);
            System.assert(it.To_SKID__c != null, it);

            SKID__c toSkid = it.To_SKID__r;
            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_INTRANSIT, toSkid);
            System.assert(toSkid.Quantity__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Quantity_Stocking_UOM__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Container_Item__c == it.Container_Item__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);
            System.assert(toSkid.Order_Line__c == it.Order_Line__c, toSkid);

            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Shipped__c == it.Shipment_Line__r.Quantity_Planned__c, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == true, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c != null, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Transaction_Date__c != null, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Order_Line__r.Quantity_Allocated__c == 0, it.Order_Line__r);
            System.assert(it.Order_Line__r.Quantity_Shipped__c == it.Shipment_Line__r.Quantity_Planned__c, it.Order_Line__r);
            System.assert(it.Order_Line__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r);
            System.assert(it.Order_Line__r.Order__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r.Order__r);
        }

        
        //Receiving Workbench
        
        ReceivingWorkBenchExt.setGridConfig('Transfer Order', fuel.facility.id);
        
        String docnum = fuel.transferOrder.Id;
        
        JSONResult searchresult = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();         
        
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('Transfer Order');
        
        configMap = ReceivingWorkBenchExt.getGridConfig('Transfer Order');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
                
       
        List<Id> tolineIds = new List<Id>();
        
        List<Order_Line__c> lineIdslist = [Select Id from Order_Line__c where Order__c =:fuel.transferOrder.Id];
        for(Order_Line__c ol:lineIdslist){
        	tolineIds.add(ol.Id);
        }
        
        //ReceivingWorkBenchExt.getDocumentInfo('Transfer Order', docnum.Id);
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, fuel.transferOrder.Deliver_To_Facility__c, null, null, null, docnum, null, fuel.transferOrder.Currency__c, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0,searchresult);
        //Manage Receive        
         
        getListresult = ReceivingWorkBenchExt.getList(tolineIds, 'Transfer Order');
        system.debug('getListresult: ' + getListresult);
        system.assert(getListresult.success == true, getListresult.message);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(tolineIds, 'Transfer Order',fuel.currencyUSD.Id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(tolineIds), new set<String>{'Order_Line__c'.toLowerCase()} );
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        rdoc.Currency__c = fuel.currencyUSD.id;
        rdoc.Transaction_Date__c = system.now() +2;
        system.assert(rdocresult.records.size() == 1, rdocresult);
               
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                
                system.assert(sw.skid.Quantity__c == rw.rl.get('Quantity_To_Receive__c'));              
            }
        }
        
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
       
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        
        List<Order_Line__c> updatedtolines = [Select Id, Status__c, Quantity_Still_Due__c, Quantity_To_Receive__c, Quantity_Received__c from Order_Line__c where Order__c =: fuel.transferOrder.Id];
        system.assert(updatedtolines.size()>0, updatedtolines);
        
        for(Order_Line__c line:updatedtolines){            
            system.assert(line.Status__c == 'Closed', line);
            system.assert(line.Quantity_To_Receive__c == 0, line.Quantity_To_Receive__c);       
        }
        
        
        List<Receipt_Line__c> receiptLines = [SELECT Id,Order__c,Order_Line__c,Order_Line__r.Quantity_Received__c,Status__c,Quantity_Received__c,Receiving_Document__r.Status__c,Receiving_Document__r.Finalized__c,Receiving_Document__r.Type__c,Receiving_Document__r.Transaction_Type__c FROM Receipt_Line__c WHERE Receipt_Line__c.Receiving_Document__r.Type__c = 'Transfer Order Receipt'];
        
        System.assert(receiptLines.size() == 2,receiptLines);
        for (Receipt_Line__c rl:receiptLines) {
            System.assert(rl.Order__c == fuel.transferOrder.Id,rl);
            System.assert(rl.Status__c == 'Closed',rl);
            System.assert(rl.Receiving_Document__r.Status__c == 'Closed',rl.Receiving_Document__r);
            System.assert(rl.Receiving_Document__r.Finalized__c,rl.Receiving_Document__r);
            System.assert(rl.Receiving_Document__r.Type__c == 'Transfer Order Receipt',rl.Receiving_Document__r);
            System.assert(rl.Receiving_Document__r.Transaction_Type__c == 'Transfer Order Receipt',rl.Receiving_Document__r);
            System.assert(rl.Quantity_Received__c == rl.Order_Line__r.Quantity_Received__c,rl);
        }
            
        List<Inventory_Transaction__c> itList1 = [SELECT Id,Item__c,Order_Line__r.Quantity_Received__c,From_SKID__c,To_SKID__c,Quantity__c,Type__c,Subtransaction_Type__c FROM Inventory_Transaction__c WHERE Receipt_Line__c IN :receiptLines];
        System.assert(itList1.size() == 2,itList1);
        
        for (Inventory_Transaction__c it:itList1) {
            System.assert(it.To_SKID__c != null,it);
            System.assert(it.Subtransaction_Type__c == 'Transfer Order Receipt',it);
            system.assert(it.Type__c == 'Transfer Order Receipt',it); 
            System.assert(it.Quantity__c == it.Order_Line__r.Quantity_Received__c, it.Order_Line__r);
        } 
        
        ReceivingDocumentVoidCancelService vcs = new ReceivingDocumentVoidCancelService(new List<Receiving_Document__c>{ rdoc });
        vcs.getBusinessVoidCancelDetails(new List<Receiving_Document__c>{ rdoc });
        vcs.businessVoid(new List<Receiving_Document__c>{ rdoc });

        

        List<SKID__c> toSupplySkids = [SELECT Id FROM SKID__c WHERE Type__c = 'TO Supply'];
        System.assert(toSupplySkids.size() == 0,toSupplySkids);
        
        List<Receipt_Line__c> rlforvoidList = [SELECT Id,Status__c,Receiving_Document__r.Status__c FROM Receipt_Line__c WHERE Receiving_Document__c = :rdoc.Id];
           
        for(Receipt_Line__c rl:rlforvoidList){
        	System.assert(rl.Receiving_Document__r.Status__c == 'Void',rl.Receiving_Document__r);
        	System.assert(rl.Status__c == 'Void',rl); 
        }
        
        List<Order_Line__c> openOrderLines = [Select Id, Status__c, Quantity_Shipped__c,Quantity_To_Receive__c,Quantity_Still_Due__c, Quantity_Received__c from Order_Line__c where Order__c =: fuel.transferOrder.Id];
        system.assert(openOrderLines.size()==2, openOrderLines);
        Test.stopTest();
        for(Order_Line__c line:openOrderLines){            
            system.assert(line.Status__c == 'Open', line);
            system.assert(line.Quantity_To_Receive__c == line.Quantity_Shipped__c, line.Quantity_To_Receive__c);         
        }
    }
    

    private static testMethod void shipAttributes() {
        fuel.setupInventory(true);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = (Decimal)wrapper.line.get('Quantity_Planned__c');
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_to_Issue__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            System.assert(sw.skid.Input_Quantity__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_to_Issue__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            System.assert(sw.skid.Input_Quantity__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        ShipmentInventoryService.pick(wrappers);

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);
        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 2, result.records);
        wrappers = (List<LineWrapper>)result.records;

        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
        }

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Order_Line__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Shipment_Line__c',
            'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c',

            'Item__r.Stocking_UOM__c',

            'Order_Line__r.Deliver_To_Facility__c', 'Order_Line__r.Deliver_To_Location__c', 'Order_Line__r.Order__c', 'Order_Line__r.Quantity_Allocated__c',
            'Order_Line__r.Quantity_Shipped__c', 'Order_Line__r.Order__r.Status__c', 'Order_Line__r.Status__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_Shipped__c',
            'Shipment_Line__r.Shipment__r.Date_Shipped__c', 'Shipment_Line__r.Shipment__r.Locked__c', 'Shipment_Line__r.Shipment__r.Status__c',
            'Shipment_Line__r.Shipment__r.Transaction_Date__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Order_Line__c', 'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Transfer Order Shipment\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == it.Shipment_Line__r.Quantity_Shipped__c, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Shipment_Line__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.To_Facility__c == it.Order_Line__r.Deliver_To_Facility__c, it);
            System.assert(it.To_Location__c == it.Order_Line__r.Deliver_To_Location__c, it);
            System.assert(it.From_SKID__c == null, it);
            System.assert(it.To_SKID__c != null, it);

            SKID__c toSkid = it.To_SKID__r;
            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_INTRANSIT, toSkid);
            System.assert(toSkid.Quantity__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Quantity_Stocking_UOM__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Container_Item__c == it.Container_Item__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);
            System.assert(toSkid.Order_Line__c == it.Order_Line__c, toSkid);

            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Shipped__c == it.Shipment_Line__r.Quantity_Planned__c, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == true, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c != null, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Transaction_Date__c != null, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Order_Line__r.Quantity_Allocated__c == 0, it.Order_Line__r);
            System.assert(it.Order_Line__r.Quantity_Shipped__c == it.Shipment_Line__r.Quantity_Planned__c, it.Order_Line__r);
            System.assert(it.Order_Line__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r);
            System.assert(it.Order_Line__r.Order__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r.Order__r);
        }

        ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(!ext.shipMode, ext);
        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() != null, shipment);

        result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 2, result.records);
        wrappers = (List<LineWrapper>)result.records;

        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity__c == (Decimal)wrapper.line.get('Quantity_Planned__c'), sw);
        }

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        Test.stopTest();

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Transfer Order Undo Shipment\'');

        itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == it.Shipment_Line__r.Quantity_Planned__c, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Shipment_Line__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Order_Line__r.Deliver_To_Facility__c, it);
            System.assert(it.From_Location__c == it.Order_Line__r.Deliver_To_Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.To_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_SKID__c == null, it);
            System.assert(it.To_SKID__c != null, it);

            SKID__c toSkid = it.To_SKID__r;
            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
            System.assert(toSkid.Quantity__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Quantity_Stocking_UOM__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Container_Item__c == it.Container_Item__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);
            System.assert(toSkid.Shipment_Line__c == it.Shipment_Line__c, toSkid);

            System.assert(it.Shipment_Line__r.Quantity_Picked__c == it.Shipment_Line__r.Quantity_Planned__c, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == false, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c == null, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Order_Line__r.Quantity_Allocated__c == it.Shipment_Line__r.Quantity_Planned__c, it.Order_Line__r);
            System.assert(it.Order_Line__r.Quantity_Shipped__c == 0, it.Order_Line__r);
            System.assert(it.Order_Line__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r);
            System.assert(it.Order_Line__r.Order__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r.Order__r);
        }
    }

    private static testMethod void shipSerials() {
        fuel.setupInventory(true, true);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_to_Issue__c == 5, sw);
            System.assert(sw.skid.Input_Quantity__c == 5, sw);
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_to_Issue__c == 5, sw);
            System.assert(sw.skid.Input_Quantity__c == 5, sw);
            for (Integer i = 0; i < sw.skid.Input_Quantity__c; i++) sw.serialList[i].Temporary_Value_Holder__c = 'Pick';
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        ShipmentInventoryService.pick(wrappers);

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);
        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 2, result.records);
        wrappers = (List<LineWrapper>)result.records;

        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity__c == 5, sw);
            System.assert(sw.serialList.size() == sw.skid.Quantity__c, sw.serialList);
        }

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Order_Line__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Shipment_Line__c',
            'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c',

            'Item__r.Stocking_UOM__c',

            'Order_Line__r.Deliver_To_Facility__c', 'Order_Line__r.Deliver_To_Location__c', 'Order_Line__r.Order__c', 'Order_Line__r.Quantity_Allocated__c',
            'Order_Line__r.Quantity_Shipped__c', 'Order_Line__r.Order__r.Status__c', 'Order_Line__r.Status__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_Shipped__c',
            'Shipment_Line__r.Shipment__r.Date_Shipped__c', 'Shipment_Line__r.Shipment__r.Locked__c', 'Shipment_Line__r.Shipment__r.Status__c',
            'Shipment_Line__r.Shipment__r.Transaction_Date__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Order_Line__c', 'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Transfer Order Shipment\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery, 'Serial_Transactions__r');
        stQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Facility__c', 'Item__c', 'Serial__c', 'Serial_Parent__c', 'Type__c',
            
            'Serial__r.Allocated_SKID__c', 'Serial__r.Allow_Reentry__c', 'Serial__r.Company__c', 'Serial__r.Item__c', 'Serial__r.SKID__c' });
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Shipment_Line__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.To_Facility__c == it.Order_Line__r.Deliver_To_Facility__c, it);
            System.assert(it.To_Location__c == it.Order_Line__r.Deliver_To_Location__c, it);
            System.assert(it.From_SKID__c == null, it);
            System.assert(it.To_SKID__c != null, it);

            SKID__c toSkid = it.To_SKID__r;
            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_INTRANSIT, toSkid);
            System.assert(toSkid.Quantity__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Quantity_Stocking_UOM__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Container_Item__c == it.Container_Item__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);
            System.assert(toSkid.Order_Line__c == it.Order_Line__c, toSkid);

            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == true, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c != null, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Transaction_Date__c != null, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Order_Line__r.Quantity_Allocated__c == 0, it.Order_Line__r);
            System.assert(it.Order_Line__r.Quantity_Shipped__c == 5, it.Order_Line__r);
            System.assert(it.Order_Line__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r);
            System.assert(it.Order_Line__r.Order__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r.Order__r);

            System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r.size());
            for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                System.assert(st.Company__c == it.Company__c, st);
                System.assert(st.Facility__c == it.From_Facility__c, st);
                System.assert(st.Item__c == it.Item__c, st);
                System.assert(st.Serial_Parent__c == null, st);
                System.assert(st.Type__c == 'Shipment', st);

                System.assert(st.Serial__c != null, st);
                System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
                System.assert(st.Serial__r.Allow_Reentry__c == true, st.Serial__r);
                System.assert(st.Serial__r.Company__c == st.Company__c, st.Serial__r);
                System.assert(st.Serial__r.Item__c == st.Item__c, st.Serial__r);
                System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
            }
        }

        ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(!ext.shipMode, ext);
        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() != null, shipment);

        result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 2, result.records);
        wrappers = (List<LineWrapper>)result.records;

        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity__c == 5, sw);
            System.assert(sw.serialList.size() == sw.skid.Quantity__c, sw.serialList);
        }

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        Test.stopTest();

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Transfer Order Undo Shipment\'');

        itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Shipment_Line__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Order_Line__r.Deliver_To_Facility__c, it);
            System.assert(it.From_Location__c == it.Order_Line__r.Deliver_To_Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.To_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_SKID__c == null, it);
            System.assert(it.To_SKID__c != null, it);

            SKID__c toSkid = it.To_SKID__r;
            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
            System.assert(toSkid.Quantity__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Quantity_Stocking_UOM__c == it.Quantity__c, toSkid);
            System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Container_Item__c == it.Container_Item__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);
            System.assert(toSkid.Shipment_Line__c == it.Shipment_Line__c, toSkid);

            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == false, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c == null, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Order_Line__r.Quantity_Allocated__c == 5, it.Order_Line__r);
            System.assert(it.Order_Line__r.Quantity_Shipped__c == 0, it.Order_Line__r);
            System.assert(it.Order_Line__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r);
            System.assert(it.Order_Line__r.Order__r.Status__c == OrderService.O_STATUS_OPEN, it.Order_Line__r.Order__r);

            System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r.size());
            for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                System.assert(st.Company__c == it.Company__c, st);
                System.assert(st.Facility__c == it.From_Facility__c, st);
                System.assert(st.Item__c == it.Item__c, st);
                System.assert(st.Serial_Parent__c == null, st);
                System.assert(st.Type__c == 'Undo Shipment', st);

                System.assert(st.Serial__c != null, st);
                System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
                System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
                System.assert(st.Serial__r.Company__c == st.Company__c, st.Serial__r);
                System.assert(st.Serial__r.Item__c == st.Item__c, st.Serial__r);
                System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
            }
        }
    }
    private static testMethod void pickNoAttributes_Consigned() {
        fuel.setupInventory();
        List<SKID__c> skidlist = new List<SKID__c>();
        for(SKID__C sk:fuel.skids){
            if(sk.Item__c == fuel.itemList[0].Id && sk.Location__c == fuel.location3.Id){
                sk.Consigned_Owner__c = fuel.supplier.id;
                sk.Purchase_Order_Line__c = fuel.purchaseOrderLines[0].Id;
                skidlist.add(sk);
            }
            
        }
        
        update skidlist;
        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        Boolean consignedCheck = false;
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id){
                    sw.skid.Input_Quantity__c = 5;
                    if(sw.skid.Item__c == fuel.itemList[0].Id){
                        system.assert(sw.skid.Consigned_Owner__c !=null);
                        system.assert(sw.skid.Purchase_Order_Line__c !=null);
                        consignedCheck = true;
                    }
                }
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        system.assert(consignedCheck==true);
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 0, sw);
            System.assert(sw.skid.Quantity_Available__c == 5, sw);
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Order_Line__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c','Consigned_Owner__c','Purchase_Order_Line__c','To_Location__r.Facility__c',

            'Item__r.Stocking_UOM__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);
		Boolean itConsignedCheck = false;
        for (Inventory_Transaction__c it:itList) {
            if(it.Type__c == 'Transfer Order Pick'){
                System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
                System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
                System.assert(it.Quantity__c == 5, it);
                System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
                System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
                System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
                System.assert(it.Finalized__c == true, it);
                System.assert(it.Inventory_Change__c != null, it);
                System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
                System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
                System.assert(it.To_Facility__c == it.From_Facility__c, it);
                System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
                System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
                System.assert(it.Container_Item__c == it.Item__c, it);
    
                System.assert(it.From_SKID__c != null, it);
                System.assert(it.From_SKID__r.Quantity__c == 95, it.From_SKID__r);
                System.assert(it.From_SKID__r.Quantity_Stocking_UOM__c == it.From_SKID__r.Quantity__c, it.From_SKID__r);
    
                System.assert(it.To_SKID__c != null, it);
                System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
                System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
                System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
                System.assert(it.To_SKID__r.Quantity__c == 5, it.To_SKID__r);
                System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
                System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
                System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
                System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
                System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
                System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
                System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);
    
                System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
                System.assert(it.Shipment_Line__r.Quantity_Picked__c == 5, it.Shipment_Line__r);
                System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
                if(it.Item__c == fuel.itemList[0].Id){
                    system.assert(it.Consigned_Owner__c !=null);
                    system.assert(it.Purchase_Order_Line__c !=null);
                    itConsignedCheck = true;
                }
            }
            else if(it.Type__c == 'Transfer Of Ownership'){
                System.assert(false,'Unexpected Transfer Of Ownership IT type: ' + it.Type__c);
            }
            
        }
		system.assert(itConsignedCheck == true);
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 5, sw);
            System.assert(sw.skid.Quantity_Available__c == 0, sw);
            sw.skid.Quantity_to_Issue__c = -5;
            sw.skid.Input_Quantity__c = -5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Transfer Order Pick\'');

        itList = Database.query(itQuery.getQuery());

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Type__c == 'Transfer Order Undo Pick', it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.From_SKID__c == null, it);

            System.assert(it.To_SKID__c != null, it);
            System.assert(it.To_SKID__r.Quantity__c == 100, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);

            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
        }
        
        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        }
    }
    
    private static testMethod void pickAttributes_withConsignedInventory() {
        fuel.setupInventory(true);
        List<SKID__c> skidlist = new List<SKID__c>();
        for(SKID__C sk:fuel.skids){
            if(sk.Item__c == fuel.itemList[0].Id && sk.Location__c == fuel.location3.Id){
                sk.Consigned_Owner__c = fuel.supplier.id;
                sk.Purchase_Order_Line__c = fuel.purchaseOrderLines[0].Id;
                skidlist.add(sk);
            }
        }
        
        update skidlist;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        Boolean consignedCheck = false;
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id){
                    sw.skid.Input_Quantity__c = 5;
                    
                    if(sw.skid.Item__c == fuel.itemList[0].Id){
                        system.assert(sw.skid.Consigned_Owner__c !=null);
                        system.assert(sw.skid.Purchase_Order_Line__c !=null);
                        consignedCheck = true;
                    }
                } 
                else sw.skid.Input_Quantity__c = 0;
                
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        system.assert(consignedCheck == true);
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 0, sw);
            System.assert(sw.skid.Quantity_Available__c == 5, sw);
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Order_Line__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c','Consigned_Owner__c','Purchase_Order_Line__c',

            'Item__r.Stocking_UOM__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);
		Boolean itConsignedCheck = false;
        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Type__c == 'Transfer Order Pick', it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);

            System.assert(it.From_SKID__c != null, it);
            System.assert(it.From_SKID__r.Quantity__c == 95, it.From_SKID__r);
            System.assert(it.From_SKID__r.Quantity_Stocking_UOM__c == it.From_SKID__r.Quantity__c, it.From_SKID__r);

            System.assert(it.To_SKID__c != null, it);
            System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
            System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity__c == 5, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);

            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
            if(it.Item__c == fuel.itemList[0].Id){
                system.assert(it.Consigned_Owner__c !=null);
                system.assert(it.Purchase_Order_Line__c !=null);
                itConsignedCheck = true;
            }
        }
		system.assert(itConsignedCheck==true);
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 5, sw);
            System.assert(sw.skid.Quantity_Available__c == 0, sw);
            sw.skid.Quantity_to_Issue__c = -5;
            sw.skid.Input_Quantity__c = -5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Transfer Order Pick\'');

        itList = Database.query(itQuery.getQuery());

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Type__c == 'Transfer Order Undo Pick', it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.From_SKID__c == null, it);

            System.assert(it.To_SKID__c != null, it);
            System.assert(it.To_SKID__r.Quantity__c == 100, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);

            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
        }
        
        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        }
    }
    
    private static testMethod void pickSerials_withConsignedInventory() {
        fuel.setupInventory(true, true);
        List<SKID__c> skidlist = new List<SKID__c>();
        for(SKID__C sk:fuel.skids){
            if(sk.Item__c == fuel.itemList[0].Id && sk.Location__c == fuel.location3.Id){
                sk.Consigned_Owner__c = fuel.supplier.id;
                sk.Purchase_Order_Line__c = fuel.purchaseOrderLines[0].Id;
                skidlist.add(sk);
            }
        }
        
        update skidlist;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        Boolean consignedCheck=false;
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) {
                    sw.skid.Input_Quantity__c = 5;
                    if(sw.skid.Item__c == fuel.itemList[0].Id){
                        system.assert(sw.skid.Consigned_Owner__c !=null);
                        system.assert(sw.skid.Purchase_Order_Line__c !=null);
                        consignedCheck = true;
                    }
                }
                else sw.skid.Input_Quantity__c = 0;
                
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
                
                
            }
        }
        system.assert(consignedCheck ==true);
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        Test.startTest();

        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 0, sw);
            System.assert(sw.skid.Quantity_Available__c == 5, sw);
            sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = 5;
            for (Integer i = 0; i < 5; i++) sw.serialList[i].Temporary_Value_Holder__c = 'Pick';
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Order_Line__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c','Consigned_Owner__c','Purchase_Order_Line__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery, 'Serial_Transactions__r');
        stQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Facility__c', 'Item__c', 'Serial__c', 'Serial_Parent__c', 'Type__c',

            'Serial__r.Allocated_SKID__c', 'Serial__r.Allow_Reentry__c', 'Serial__r.Company__c', 'Serial__r.Item__c', 'Serial__r.SKID__c' });
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2, itList);
		Boolean itConsignedCheck = false;
        for (Inventory_Transaction__c it:itList) {
            
            
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Type__c == 'Transfer Order Pick', it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);

            System.assert(it.From_SKID__c != null, it);
            System.assert(it.From_SKID__r.Quantity__c == 5, it.From_SKID__r);
            System.assert(it.From_SKID__r.Quantity_Stocking_UOM__c == it.From_SKID__r.Quantity__c, it.From_SKID__r);

            System.assert(it.To_SKID__c != null, it);
            System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
            System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity__c == 5, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
            System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);

            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r);
            if(it.Item__c == fuel.itemList[0].Id){
                system.assert(it.Consigned_Owner__c !=null);
                system.assert(it.Purchase_Order_Line__c !=null);
                itConsignedCheck = true;
            }
            for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                System.assert(st.Company__c == it.Company__c, st);
                System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
                System.assert(st.Item__c == it.Item__c, st);
                System.assert(st.Serial__c != null, st);
                System.assert(st.Serial_Parent__c == null, st);
                System.assert(st.Type__c == 'Pick', st);
                System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
                System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
                System.assert(st.Serial__r.Company__c == it.Company__c, st.Serial__r);
                System.assert(st.Serial__r.Item__c == it.Item__c, st.Serial__r);
                System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
            }
        }
		system.assert(itConsignedCheck == true);
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c', 'Packaging_UOM__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 2, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');

            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            System.assert(sw.skid.Quantity_Used__c == 5, sw);
            System.assert(sw.skid.Quantity_Available__c == 0, sw);
            sw.skid.Quantity_to_Issue__c = -5;
            sw.skid.Input_Quantity__c = -5;
            for (Integer i = 0; i < 5; i++) sw.serialList[i].Temporary_Value_Holder__c = 'Unpick';
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Transfer Order Pick\'');

        itList = Database.query(itQuery.getQuery());

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Type__c == 'Transfer Order Undo Pick', it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Quantity__c == 5, it);
            System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
            System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Order_Line__c == it.Shipment_Line__r.Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Container_Item__c == it.Item__c, it);
            System.assert(it.From_SKID__c == null, it);

            System.assert(it.To_SKID__c != null, it);
            System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
            System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);

            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 5, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r);
            for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                System.assert(st.Company__c == it.Company__c, st);
                System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
                System.assert(st.Item__c == it.Item__c, st);
                System.assert(st.Serial__c != null, st);
                System.assert(st.Serial_Parent__c == null, st);
                System.assert(st.Type__c == 'Undo Pick', st);
                System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
                System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
                System.assert(st.Serial__r.Company__c == it.Company__c, st.Serial__r);
                System.assert(st.Serial__r.Item__c == it.Item__c, st.Serial__r);
                System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
            }
        }
        
        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity__c == 5, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        }
    }
}