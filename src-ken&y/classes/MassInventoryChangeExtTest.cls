@isTest
private class MassInventoryChangeExtTest {
    @testSetup
    private static void setupData() {
        TestFuel fuel = new TestFuel();
        System.assert(fuel.periodList != null);
        System.assert(fuel.itemList != null);
        System.assert(fuel.location3 != null);
        System.assert(fuel.location5 != null);
        System.assert(fuel.itemAttrObj2 != null);
        System.assert(fuel.smrsList != null);
        System.assert(fuel.smrsList != null);
        System.assert(fuel.stockMovementRuleList != null);

        insert new User_Preference__c(
            OwnerId = UserInfo.getUserId(),
            Default_Company__c = fuel.company.Id,
            Default_Facility__c = fuel.facility2.Id,
            User__c = UserInfo.getUserId()
        );
    }
    private static TestFuelQuery fuel = new TestFuelQuery();
    
    
    
    private static testMethod void testAdjustmentIncreaseNoSerials() {

       MassInventoryChangeExt ext = new MassInventoryChangeExt(new ApexPages.StandardSetController(new List<Inventory_Change__c>{new Inventory_Change__c()})); 
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Container_Item__c = fuel.itemList[0].Id,
            Item__c = fuel.itemList[0].Id,
            Type__c = 'Location',
            Company__c = fuel.company.Id
        );
        insert skid;

        
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Change'
        );
        insert rc;
        
        
        JsonResult newRow = MassInventoryChangeExt.addRow(fuel.location3.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
            
        row.fromSKID.Item__c = fuel.itemList[0].Id;
        JSONResult dsr = MassInventoryChangeExt.getLocationSKIDS(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(dsr.records!=null && dsr.records.size()>0);
        
        list<SkidService3.SerialWrapper> serialWrapper = (List<SkidService3.SerialWrapper>)dsr.records;
          serialWrapper[0].skid.count_quantity__c = 5;
        
        String result = MassInventoryChangeExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapper,new List<String>());
        
        List<Inventory_Change__c> ics = [SELECT Id FROM Inventory_Change__c WHERE Type__c = 'Adjustment'];
        System.assert(ics.size() == 1, result);
        System.assert([SELECT Id FROM Inventory_Transaction__c WHERE Inventory_Change__c = :ics[0].Id].size() == 1);
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Location__c = :fuel.location3.id][0].Quantity__c == 105);
        
    }
    
    
    private static testMethod void testAdjustmentDecreaseNoSerials() {

       MassInventoryChangeExt ext = new MassInventoryChangeExt(new ApexPages.StandardSetController(new List<Inventory_Change__c>{new Inventory_Change__c()})); 

        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Container_Item__c = fuel.itemList[0].Id,
            Item__c = fuel.itemList[0].Id,
            Type__c = 'Location',
            Company__c = fuel.company.Id
        );
        insert skid;
        
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Change'
        );
        insert rc;
        
        
        JsonResult newRow = MassInventoryChangeExt.addRow(fuel.location3.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
            
        row.fromSKID.Item__c = fuel.itemList[0].Id;
        JSONResult dsr = MassInventoryChangeExt.getLocationSKIDS(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(dsr.records!=null && dsr.records.size()>0);
        
        list<SkidService3.SerialWrapper> serialWrapper = (List<SkidService3.SerialWrapper>)dsr.records;
          serialWrapper[0].skid.count_quantity__c = -5;
        
        MassInventoryChangeExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapper,new List<String>());
        
        List<Inventory_Change__c> ics = [SELECT Id FROM Inventory_Change__c WHERE Type__c = 'Adjustment'];
        System.assert(ics.size() == 1);
        System.assert([SELECT Id FROM Inventory_Transaction__c WHERE Inventory_Change__c = :ics[0].Id].size() == 1);
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Location__c = :fuel.location3.id][0].Quantity__c == 95);
        
    }
  
    private static testMethod void testQuantityNotFound() {
 
        
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Change'
        );
        insert rc;
        
        
        JsonResult newRow = MassInventoryChangeExt.addRow(fuel.location3.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
        //System.assert(row.toSKID.Location__c == fuel.location5.Id,row);        
        row.fromSKID.Item__c = fuel.itemList[0].Id;
        JSONResult dsr = MassInventoryChangeExt.getLocationSKIDS(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(dsr.records.size() == 0);
        
        
    }
     
    private static testMethod void testGetFieldList () {
        
        MassInventoryChangeExt ext = new MassInventoryChangeExt(new ApexPages.StandardSetController(new List<Inventory_Change__c>{new Inventory_Change__c()}));
        String skidFields = ext.skidFieldListJson;
        String skidHeaderFields = ext.skidHeaderFieldListJson;
        Integer gSize = ext.gridSize;
        
        system.assert ( ext.serialAttributesJson != null && String.isEmpty(ext.serialAttributesJson) == false );    
        system.assert ( ext.skidFieldListJson != null && String.isEmpty(ext.skidFieldListJson) == false );
        system.assert ( ext.skidHeaderFieldListJson != null && String.isEmpty(ext.skidHeaderFieldListJson) == false );
        system.assert ( ext.serialFieldListJson != null && String.isEmpty(ext.serialFieldListJson) == false );
    }  
    
    private static testMethod void testAdjustmentIncreaseWithSerials (){
        
        fuel.setupInventory(true,true);
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Change'
        );
        insert rc;
         Serial__c serial1 = new Serial__c();
            serial1.Item__c = fuel.itemList[0].Id;
            serial1.Name = '456';
            serial1.Company__c = fuel.company.Id;
            insert serial1;

        JsonResult newRow = MassInventoryChangeExt.addRow(fuel.location3.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
              
        row.fromSKID.Item__c = fuel.itemList[0].Id;
        JSONResult dsr = MassInventoryChangeExt.getLocationSKIDS(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(dsr.records!=null && dsr.records.size()>0);

        list<SkidService3.SerialWrapper> serialWrapper = (List<SkidService3.SerialWrapper>)dsr.records;
          serialWrapper[0].skid.count_quantity__c = 1;
          //serialList.add(serial1);
          serialWrapper[0].serialList.add(serial1); 
        
        MassInventoryChangeExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapper,new List<String>());
        
        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);
        
        System.assert(itList[0].Type__c == 'Adjustment Increase',itList[0]);
        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].From_SKID__c == itList[0].To_SKID__c,itList[0]);
        System.assert(itList[0].Quantity__c == 1,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 11,itList[0].From_SKID__r);
        System.assert(itList[0].Serial_Transactions__r.size() == 1,itList[0].Serial_Transactions__r);
        System.assert(itList[0].Serial_Transactions__r[0].Type__c == 'Adjustment',itList[0].Serial_Transactions__r[0]);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.setWhereClause('Id = \'' + itList[0].From_SKID__c + '\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
        serialQuery.addAllCustomFields();
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 1,skids);
        
        System.assert(skids[0].Quantity__c == skids[0].Serials__r.size(),skids[0].Serials__r);
        
        for (Serial__c serial:skids[0].Serials__r) {
            System.assert(!serial.Allow_Reentry__c,serial);
        }
        list<serial__c> serialsList = skids[0].Serials__r;
        SOQLUtil serQuery = new SOQLUtil('Serial__c');
        serQuery.addAllCustomFields();
        serQuery.setWhereClause('id in :serialsList');

        List<Serial__c> serials = Database.query(serQuery.getQuery());
        
        System.assert(serials.size() == 11,serials);
        
        
       
    }
    private static testMethod void testAdjustmentDecreaseWithSerials (){
        fuel.setupInventory(true,true);
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Change'
        );
        insert rc;

        JsonResult newRow = MassInventoryChangeExt.addRow(fuel.location3.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
              
        row.fromSKID.Item__c = fuel.itemList[0].Id;
        JSONResult dsr = MassInventoryChangeExt.getLocationSKIDS(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(dsr.records!=null && dsr.records.size()>0);
        
        list<SkidService3.SerialWrapper> serialWrapper = (List<SkidService3.SerialWrapper>)dsr.records;
          serialWrapper[0].skid.count_quantity__c = -1;
          serialWrapper[0].serialList.remove(0);
          
        string result = MassInventoryChangeExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapper,new List<String>());
       

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);
        
        System.assert(itList[0].Type__c == 'Adjustment Decrease',itList[0]);
        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].From_SKID__c == itList[0].To_SKID__c,itList[0]);
        System.assert(itList[0].Quantity__c == -1,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 9,itList[0].From_SKID__r);
        System.assert(itList[0].Serial_Transactions__r.size() == 1,itList[0].Serial_Transactions__r);
        System.assert(itList[0].Serial_Transactions__r[0].Type__c == 'Adjustment',itList[0].Serial_Transactions__r[0]);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.setWhereClause('Id = \'' + itList[0].From_SKID__c + '\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
        serialQuery.addAllCustomFields();
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 1,skids);
        
        System.assert(skids[0].Quantity__c == skids[0].Serials__r.size(),skids[0].Serials__r);
        for (Serial__c serial:skids[0].Serials__r) {
            System.assert(!serial.Allow_Reentry__c,serial);
        }

        SOQLUtil serQuery = new SOQLUtil('Serial__c');
        serQuery.addAllCustomFields();
        serQuery.setWhereClause('SKID__c = null');

        List<Serial__c> serials = Database.query(serQuery.getQuery());
        System.assert(serials.size() == 1,serials);
        System.assert(serials[0].Allow_Reentry__c,serials[0]);
        

    }
     private static testMethod void testAdjustmentIncreaseCases() {

       MassInventoryChangeExt ext = new MassInventoryChangeExt(new ApexPages.StandardSetController(new List<Inventory_Change__c>{new Inventory_Change__c()})); 
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 5,
            Quantity_Stocking_UOM__c = 10,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[12].Id,
            Packaging_UOM__r = fuel.uomList[12],
            Stocking_UOM__c = fuel.uomList[11].Id,
            Stocking_UOM__r = fuel.uomList[11],
            Container_Item__c = fuel.itemList[12].Id ,//case container item  
            Container_Item__r = fuel.itemList[12]  
        );
        insert skid;
        
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Change'
        );
        insert rc;
        
        
        JsonResult newRow = MassInventoryChangeExt.addRow(fuel.location3.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
            
        row.fromSKID.Item__c = fuel.itemList[14].Id;
        JSONResult dsr = MassInventoryChangeExt.getLocationSKIDS(fuel.itemList[14].Id,fuel.location3.Id);
        System.assert(dsr.records!=null && dsr.records.size()>0, dsr);
        
        list<SkidService3.SerialWrapper> serialWrapper = (List<SkidService3.SerialWrapper>)dsr.records;
          serialWrapper[0].skid.count_quantity__c = 5;
        
        MassInventoryChangeExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapper,new List<String>());
        
        List<Inventory_Change__c> ics = [SELECT Id FROM Inventory_Change__c WHERE Type__c = 'Adjustment'];
        System.assert(ics.size() == 1);
        list<Inventory_Transaction__c> itList = [SELECT Id,Packaging_UOM__c,Stocking_UOM__c,Quantity_Stocking_UOM__c,Quantity__c FROM Inventory_Transaction__c WHERE Inventory_Change__c = :ics[0].Id];
        System.assert(itList.size() == 1);
        System.assert(itList[0].Packaging_UOM__c == fuel.uomList[12].Id);
        System.assert(itList[0].Stocking_UOM__c == fuel.uomList[11].Id);
        System.assert(itList[0].Quantity_Stocking_UOM__c == 10);
        System.assert(itList[0].Quantity__c == 5);
        list<SKID__c> skidList = [SELECT Id,Packaging_UOM__c,Stocking_UOM__c,Quantity_Stocking_UOM__c,Quantity__c FROM SKID__c WHERE Item__c = :fuel.itemList[14].Id];
        System.assert(skidList[0].Quantity__c == 10);
        System.assert(skidList[0].Packaging_UOM__c == fuel.uomList[12].Id);
        System.assert(skidList[0].Stocking_UOM__c == fuel.uomList[11].Id);
        System.assert(skidList[0].Quantity_Stocking_UOM__c == 20);
        
        
    }
     private static testMethod void testAdjustmentIncreaseCasesCheckingBinCapacity() {  

       MassInventoryChangeExt ext = new MassInventoryChangeExt(new ApexPages.StandardSetController(new List<Inventory_Change__c>{new Inventory_Change__c()})); 
       update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
         Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin1;
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Bin__c = bin1.id,
            Quantity__c = 1,
            Quantity_Stocking_UOM__c = 2,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[12].Id,  
            Packaging_UOM__r = fuel.uomList[12],
            Stocking_UOM__c = fuel.uomList[11].Id,
            Container_Item__c = fuel.itemList[12].Id ,//case container item  
            Container_Item__r = fuel.itemList[12]  
        );
        insert skid;
        
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Change'
        );
        insert rc;
        
        
        JsonResult newRow = MassInventoryChangeExt.addRow(fuel.location3.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
            
        row.fromSKID.Item__c = fuel.itemList[0].Id;
        JSONResult dsr = MassInventoryChangeExt.getLocationSKIDS(fuel.itemList[14].Id,fuel.location3.Id);
        System.assert(dsr.records!=null && dsr.records.size()>0);
        
        list<SkidService3.SerialWrapper> serialWrapper = (List<SkidService3.SerialWrapper>)dsr.records;
          serialWrapper[0].skid.count_quantity__c = 5;
        
        string result = MassInventoryChangeExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapper,new List<String>());
        
        Jsonresult res = (JsonResult)JSON.deserialize(result, JsonResult.class);
        System.assert(res.success == false, res);
        
        List<Inventory_Change__c> ics = [SELECT Id FROM Inventory_Change__c WHERE Type__c = 'Adjustment'];
        System.assert(ics.size() == 0);
        
        
    }
    private static testMethod void createNewSkid() {  

        MassInventoryChangeExt ext = new MassInventoryChangeExt(new ApexPages.StandardSetController(new List<Inventory_Change__c>{new Inventory_Change__c()})); 

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 25,
            Expiration_Date__c = System.today() + 10,
            Lot_Number__c = 'ABC',
            Packaging_UOM__c = fuel.uomList[8].Id
        );
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Change'
        );
        insert rc;
        JsonResult newRow = MassInventoryChangeExt.addRow(fuel.location3.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
            
        row.fromSKID.Item__c = fuel.itemList[0].Id;
       
        list<SkidService3.SerialWrapper> serialWrapper = new List<SkidService3.SerialWrapper>{new SkidService3.SerialWrapper(skid,new List<Serial__c>()) };
        serialWrapper[0].skid.count_quantity__c = 25;
        String result = MassInventoryChangeExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapper,new List<String>());
        
        List<Inventory_Change__c> ics = [SELECT Id FROM Inventory_Change__c WHERE Type__c = 'Adjustment'];
        System.assert(ics.size() == 1, result);
        
        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);
        System.assert(itList[0].Inventory_Change__c == ics[0].Id,itList[0]);
        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].From_SKID__c == itList[0].To_SKID__c,itList[0]);
        System.assert(itList[0].Quantity__c == 25,itList[0]);
        System.assert(itList[0].To_SKID__r.Location__c == fuel.location3.id,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 25,itList[0].From_SKID__r);

    }
}