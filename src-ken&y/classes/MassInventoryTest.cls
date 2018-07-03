@isTest
private class MassInventoryTest {
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
    
    
    
    private static testMethod void testSuccess() {

       MassInventoryTransferExt ext = new MassInventoryTransferExt(new ApexPages.StandardSetController(new List<Inventory_Change__c>{new Inventory_Change__c()})); 
        
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Item__c = fuel.itemList[0].Id,
            Type__c = 'Location',
            Company__c = fuel.company.Id
        );
        insert skid;
        
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Transfer'
        );
        insert rc;
        
        
        JsonResult newRow = MassInventoryTransferExt.addRow(fuel.location3.Id,fuel.location5.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
        System.assert(row.toSKID.Location__c == fuel.location5.Id,row);        
        row.fromSKID.Item__c = fuel.itemList[0].Id;
        JSONResult dsr = MassInventoryTransferExt.getLocationSKIDS(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(dsr.records!=null && dsr.records.size()>0);
        
        list<SkidService3.SerialWrapper> serialWrapper = (List<SkidService3.SerialWrapper>)dsr.records;
          serialWrapper[0].skid.input_quantity__c = 5;
          serialWrapper[0].skid.Temporary_Value_Holder1__c = fuel.location5.Id;
         
        
        MassInventoryTransferExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapper,new List<String>());
        
        List<Inventory_Change__c> ics = [SELECT Id FROM Inventory_Change__c WHERE Type__c = 'Transfer'];
        System.assert(ics.size() == 1);
        System.assert([SELECT Id FROM Inventory_Transaction__c WHERE Inventory_Change__c = :ics[0].Id].size() == 1);
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Location__c = :fuel.location3.id][0].Quantity__c == 95);
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Location__c = :fuel.location5.id][0].Quantity__c == 5);
    }
   
    private static testMethod void roundTripSuccess() {

       
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Item__c = fuel.itemList[0].Id,
            Type__c = 'Location',
            Company__c = fuel.company.Id
        );
        insert skid;
        
        SKID__c skid1 = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location5.Id,
            Quantity__c = 200,
            Quantity_Stocking_UOM__c = 200,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Item__c = fuel.itemList[0].Id,
            Type__c = 'Location',
            Company__c = fuel.company.Id
        );
        insert skid1;
        
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Transfer'
        );
        insert rc;
        
        MassInventoryTransferExt ext = new MassInventoryTransferExt(new ApexPages.StandardSetController(new List<Inventory_Change__c>{new Inventory_Change__c()})); 
        
        JsonResult newRow = MassInventoryTransferExt.addRow(fuel.location3.Id,fuel.location5.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
        System.assert(row.toSKID.Location__c == fuel.location5.Id,row);        
        row.fromSKID.Item__c = fuel.itemList[0].Id;
       
        
        JSONResult dsr = MassInventoryTransferExt.getLocationSKIDS(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(dsr.records!=null && dsr.records.size()>0);
        
        
        JsonResult newRow1 = MassInventoryTransferExt.addRow(fuel.location5.Id,fuel.location3.Id);
        System.assert(newRow1.success && newRow1.records.size() == 1,newRow1);
        
        MassInventoryService.InventoryData row1 = (MassInventoryService.InventoryData)newRow1.records[0];
        System.assert(row1.fromSKID.Location__c == fuel.location5.Id,row1);
        System.assert(row1.toSKID.Location__c == fuel.location3.Id,row1);
        
        row1.fromSKID.Item__c = fuel.itemList[0].Id;
        
        JSONResult dsr1 = MassInventoryTransferExt.getLocationSKIDS(fuel.itemList[0].Id,fuel.location5.Id);
        System.assert(dsr1.records!=null && dsr1.records.size()>0);
        
        
        list<SkidService3.SerialWrapper> serialWrapper1 = (List<SkidService3.SerialWrapper>)dsr.records;
          serialWrapper1[0].skid.input_quantity__c = 5;
          serialWrapper1[0].skid.Temporary_Value_Holder1__c = fuel.location5.Id;
          
        list<SkidService3.SerialWrapper> serialWrapper2 = (List<SkidService3.SerialWrapper>)dsr1.records;
          serialWrapper2[0].skid.input_quantity__c = 1;
          serialWrapper2[0].skid.Temporary_Value_Holder1__c = fuel.location3.Id;  
         
        list<SkidService3.SerialWrapper> serialWrapperList = new list<SkidService3.SerialWrapper>();
        serialWrapperList.addAll(serialWrapper1);
        serialWrapperList.addAll(serialWrapper2);
        String s = MassInventoryTransferExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapperList,new List<String>());
        List<Inventory_Change__c> ics = [SELECT Id FROM Inventory_Change__c WHERE Type__c = 'Transfer'];
        System.assert(ics.size() == 1);
        System.assert([SELECT Id FROM Inventory_Transaction__c WHERE Inventory_Change__c = :ics[0].Id].size() == 2);
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Location__c = :fuel.location3.id][0].Quantity__c == 96);
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Location__c = :fuel.location5.id][0].Quantity__c == 204);
    }
   
    private static testMethod void testQuantityNotFound() {
 
        
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Transfer'
        );
        insert rc;
        
        
        JsonResult newRow = MassInventoryTransferExt.addRow(fuel.location3.Id,fuel.location5.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
        System.assert(row.toSKID.Location__c == fuel.location5.Id,row);        
        row.fromSKID.Item__c = fuel.itemList[0].Id;
        JSONResult dsr = MassInventoryTransferExt.getLocationSKIDS(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(dsr.records.size() == 0);
        
        
    }
     
    private static testMethod void testGetFieldList () {
        
        MassInventoryTransferExt ext = new MassInventoryTransferExt(new ApexPages.StandardSetController(new List<Inventory_Change__c>{new Inventory_Change__c()}));
        String skidFields = ext.skidFieldListJson;
        String skidHeaderFields = ext.skidHeaderFieldListJson;
        Integer gSize = ext.gridSize;
        
        system.assert ( ext.serialAttributesJson != null && String.isEmpty(ext.serialAttributesJson) == false );    
        system.assert ( ext.skidFieldListJson != null && String.isEmpty(ext.skidFieldListJson) == false );
        system.assert ( ext.skidHeaderFieldListJson != null && String.isEmpty(ext.skidHeaderFieldListJson) == false );
        system.assert ( ext.serialFieldListJson != null && String.isEmpty(ext.serialFieldListJson) == false );
    }  
    
    private static testMethod void testGetSerials (){
        
        update new Location__c(Id = fuel.location5.Id, Bin_Tracked__c = true);
        
        system.debug (fuel.company);
        Bin__c bin = new Bin__c(
            Name = 'Location 5 Bin',
            Location__c = fuel.location5.Id
        );
        insert bin;
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Item__c = fuel.itemList[0].Id,
            Type__c = 'Location',
            Company__c = fuel.company.Id
        );
        insert skid;
        
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Transfer'
        );
        insert rc;
        Serial__c serial = new Serial__c();
        serial.Item__c =skid.Item__c;
        serial.Name = '123';
        serial.SKID__c = skid.id;
        serial.Company__c = skid.Company__c;
        serial.Unique_Key2__c = '' + skid.Company__c + '-' + skid.Item__c + '-' + skid.Id ;
        insert serial;
        List<Serial__c > serialList = new List<Serial__c >();
        serialList.add(serial);
        JsonResult newRow = MassInventoryTransferExt.addRow(fuel.location3.Id,fuel.location5.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        Location__c loc = MassInventoryTransferExt.getLocationRecord( fuel.location5.Id);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
        System.assert(row.toSKID.Location__c == fuel.location5.Id,row);        
        row.fromSKID.Item__c = fuel.itemList[0].Id;
        JSONResult dsr = MassInventoryTransferExt.getLocationSKIDS(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(dsr.records!=null && dsr.records.size()>0);
        List<String> locAndBinId = new List<String>();
        locAndBinId.add(fuel.location5.Id);
        locAndBinId.add(bin.id);
        list<SkidService3.SerialWrapper> serialWrapper = (List<SkidService3.SerialWrapper>)dsr.records;
          serialWrapper[0].skid.input_quantity__c = 1;
          serialWrapper[0].skid.Temporary_Value_Holder1__c = locAndBinId[0]+','+locAndBinId[1];
          serialWrapper[0].serialList = serialList; 
        
        MassInventoryTransferExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapper,new List<String>());
        string Transfer = 'Transfer';
        string SerialName = '123';
        List<Inventory_Change__c> ics = [SELECT Id FROM Inventory_Change__c WHERE Type__c = 'Transfer'];
        System.assert(ics.size() == 1);
        System.assert([SELECT Id FROM Inventory_Transaction__c WHERE Inventory_Change__c = :ics[0].Id].size() == 1);
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Location__c = :fuel.location3.id][0].Quantity__c == 99);
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Location__c = :fuel.location5.id][0].Quantity__c == 1);
        System.assert([SELECT Id FROM Inventory_Transaction__c   WHERE Type__c = :Transfer].size() == 1);
        System.assert([SELECT Id FROM Serial_Transaction__c  WHERE Type__c = :Transfer].size() == 1);
        System.assert([SELECT Id FROM Serial__c  WHERE Name = :SerialName].size() == 1);
    }
     private static testMethod void testTransferCasesSuccess() {

       MassInventoryTransferExt ext = new MassInventoryTransferExt(new ApexPages.StandardSetController(new List<Inventory_Change__c>{new Inventory_Change__c()})); 
        
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 200,
            Stocking_UOM__c = fuel.uomList[11].Id,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[12].Id,
            Packaging_UOM__r = fuel.uomList[12],
            Container_Item__c = fuel.itemList[12].Id ,//case container item  
            Container_Item__r = fuel.itemList[12]  
        );
        insert skid;
        
        Reason_Code__c rc = new Reason_Code__c(
            Company__c = fuel.company.Id,
            Name = 'IC',
            Type__c = 'Inventory Transfer'
        );
        insert rc;
        
          
        JsonResult newRow = MassInventoryTransferExt.addRow(fuel.location3.Id,fuel.location5.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
        System.assert(row.toSKID.Location__c == fuel.location5.Id,row);        
        row.fromSKID.Item__c = fuel.itemList[14].Id;
        JSONResult dsr = MassInventoryTransferExt.getLocationSKIDS(fuel.itemList[14].Id,fuel.location3.Id);
        
        System.assert(dsr.records!=null && dsr.records.size()>0);
        
        list<SkidService3.SerialWrapper> serialWrapper = (List<SkidService3.SerialWrapper>)dsr.records;
          serialWrapper[0].skid.input_quantity__c = 5;
          serialWrapper[0].skid.Temporary_Value_Holder1__c = fuel.location5.Id;
         
        
        MassInventoryTransferExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapper,new List<String>());
        
        List<Inventory_Change__c> ics = [SELECT Id FROM Inventory_Change__c WHERE Type__c = 'Transfer'];
        System.assert(ics.size() == 1);
        list<Inventory_Transaction__c> itList = [SELECT Id,Packaging_UOM__c,Stocking_UOM__c,Quantity_Stocking_UOM__c,Quantity__c FROM Inventory_Transaction__c WHERE Inventory_Change__c = :ics[0].Id];
        System.assert(itList.size() == 1);
        System.assert(itList[0].Packaging_UOM__c == fuel.uomList[12].Id);
        System.assert(itList[0].Stocking_UOM__c == fuel.uomList[11].Id);
        System.assert(itList[0].Quantity_Stocking_UOM__c == 10);
        System.assert(itList[0].Quantity__c == 5);
        list<SKID__c> skidList = [SELECT Id,Packaging_UOM__c,Stocking_UOM__c,Quantity_Stocking_UOM__c,Quantity__c FROM SKID__c WHERE Item__c = :fuel.itemList[14].Id];
        System.assert(skidList[0].Quantity__c == 95);
        System.assert(skidList[1].Quantity__c == 5);
        System.assert(skidList[1].Packaging_UOM__c == fuel.uomList[12].Id);
        System.assert(skidList[1].Stocking_UOM__c == fuel.uomList[11].Id);
        System.assert(skidList[1].Quantity_Stocking_UOM__c == 10);
        
    }
    
    private static testMethod void testTransferCasesBinCapacitySuccess() {

       MassInventoryTransferExt ext = new MassInventoryTransferExt(new ApexPages.StandardSetController(new List<Inventory_Change__c>{new Inventory_Change__c()})); 
         update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
          update new Location__c(Id = fuel.location5.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
         Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin1;
        
         Bin__c bin2 = new Bin__c(
            Name = 'Location 5 Bin1',
            Location__c = fuel.location5.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin2;
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 2,
            Quantity_Stocking_UOM__c = 20,
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
            Type__c = 'Inventory Transfer'
        );
        insert rc;
        
          
        JsonResult newRow = MassInventoryTransferExt.addRow(fuel.location3.Id,fuel.location5.Id);
        System.assert(newRow.success && newRow.records.size() == 1,newRow);
        
        MassInventoryService.InventoryData row = (MassInventoryService.InventoryData)newRow.records[0];
        System.assert(row.fromSKID.Location__c == fuel.location3.Id,row);
        System.assert(row.toSKID.Location__c == fuel.location5.Id,row);        
        row.fromSKID.Item__c = fuel.itemList[14].Id;
        JSONResult dsr = MassInventoryTransferExt.getLocationSKIDS(fuel.itemList[14].Id,fuel.location3.Id);
        
        System.assert(dsr.records!=null && dsr.records.size()>0);
        List<String> locAndBinId = new List<String>();
        locAndBinId.add(fuel.location5.Id);
        locAndBinId.add(bin2.id);  
        list<SkidService3.SerialWrapper> serialWrapper = (List<SkidService3.SerialWrapper>)dsr.records;
          serialWrapper[0].skid.input_quantity__c = 1;
          serialWrapper[0].skid.Temporary_Value_Holder1__c = locAndBinId[0]+','+locAndBinId[1];
        
        MassInventoryTransferExt.save(fuel.company.Id,fuel.facility2.Id,rc.Id,serialWrapper,new List<String>());
        
        List<Inventory_Change__c> ics = [SELECT Id FROM Inventory_Change__c WHERE Type__c = 'Transfer'];
        System.assert(ics.size() == 1);
        list<Inventory_Transaction__c> itList = [SELECT Id,Packaging_UOM__c,Stocking_UOM__c,Quantity_Stocking_UOM__c,Quantity__c FROM Inventory_Transaction__c WHERE Inventory_Change__c = :ics[0].Id];
        System.assert(itList.size() == 1);
        System.assert(itList[0].Packaging_UOM__c == fuel.uomList[12].Id);
        System.assert(itList[0].Stocking_UOM__c == fuel.uomList[11].Id);
        System.assert(itList[0].Quantity_Stocking_UOM__c == 2);
        System.assert(itList[0].Quantity__c == 1);
        list<SKID__c> skidList = [SELECT Id,Packaging_UOM__c,Stocking_UOM__c,Quantity_Stocking_UOM__c,Quantity__c FROM SKID__c WHERE Item__c = :fuel.itemList[14].Id];
        System.assert(skidList[0].Quantity__c == 1);
        System.assert(skidList[1].Quantity__c == 1);
        System.assert(skidList[1].Packaging_UOM__c == fuel.uomList[12].Id);
        System.assert(skidList[1].Stocking_UOM__c == fuel.uomList[11].Id);
        System.assert(skidList[1].Quantity_Stocking_UOM__c == 2);
        System.assert([SELECT Id,Quantity__c,Bin__c FROM SKID__c WHERE Location__c = :fuel.location5.id][0].Bin__c == bin2.id);
    }
}