@isTest
private class DirectPutawayTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.periodList != null);
        System.assert(f.itemList != null);
        System.assert(f.location3 != null);
        System.assert(f.location5 != null);
        System.assert(f.itemAttrObj2 != null);
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);

        insert new User_Preference__c(
            OwnerId = UserInfo.getUserId(),
            Default_Company__c = f.company.Id,
            Default_Facility__c = f.facility2.Id,
            User__c = UserInfo.getUserId()
        );
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void putawayInventoryInEaches() {
        
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
        
        Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 100,
            Packaging_UOM__c = fuel.uomList[8].Id
        );
        insert bin1;
         Bin__c bin2 = new Bin__c(
            Name = 'Location 3 Bin2',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 100,
            Packaging_UOM__c = fuel.uomList[8].Id
        );
        insert bin2;
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 100,
            Item__c = fuel.itemList[0].Id,
            Type__c = 'Location',
            Bin__c = bin1.id,
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[8].Id,
            Packaging_UOM__r = fuel.uomList[8]
        );
        insert skid;
        
        
        //create putaway dummy stock movement rule and putaway skid for direct putaway
        Stock_Movement_Rule__c dummySMR = new Stock_Movement_Rule__c(Name = 'Dummy',
        Rule_Type__c = null,
        Company__c = fuel.company.Id,
        Facility__c = fuel.facility2.Id,
        Class__c = null,
        Item__c =  fuel.itemList[0].Id,
        Customer__c = null,
        Source_Document__c = 'Transfer',
        source_location__c = fuel.location5.Id,
        Active__c = true);
        
        skid__c dummySkid = new skid__c (Name = 'DummySkid',
        Company__c = fuel.company.Id,
        Facility2__c = fuel.facility2.Id,
        Item__c =  fuel.itemList[0].Id,
        Quantity__c = 3,
        Packaging_UOM__c = fuel.uomList[8].Id,
        Packaging_UOM__r =  fuel.uomList[8],                        
        //License_Plate_Number__c = 'a3K50000001LFFB',
        Container_Item__c = fuel.itemList[0].Id ,
        Container_Item__r = fuel.itemList[0]                        
       );
          
        list<skidservice3.directPutawayWrapper> dpWList = new list<skidservice3.directPutawayWrapper>();
        skidservice3.directPutawayWrapper dpW =  new SkidService3.directPutawayWrapper( dummySMR, dummySkid);
        
        dpWList.add(dpW);
        map<integer, Bin__c > availableBin = SkidService3.availableBinForDirectPutaway(dpWList);
        system.assertEquals(1, availableBin.size());
        system.assertEquals(bin2.id, availableBin.get(0).id);
        
 
    }
     private static testMethod void putawayInventoryInCases() {
        
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
        //cs-2 each,pt-3 cases,pt-eaches -6 cases = 12,PT -13,EA2 - 11
       // update new Item__c(Id = fuel.itemList[24].Id ,Container_Item__c =  fuel.itemList[22].Id );
        Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin1;
         Bin__c bin2 = new Bin__c(
            Name = 'Location 3 Bin2',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin2;
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 4,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            Bin__c = bin1.id,
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[11].Id,
            Packaging_UOM__r = fuel.uomList[11]
        );
        insert skid;
        
        
        //create putaway dummy stock movement rule and putaway skid for direct putaway
        Stock_Movement_Rule__c dummySMR = new Stock_Movement_Rule__c(Name = 'Dummy',
        Rule_Type__c = null,
        Company__c = fuel.company.Id,
        Facility__c = fuel.facility2.Id,
        Class__c = null,
        Item__c =  fuel.itemList[14].Id,
        Customer__c = null,
        Source_Document__c = 'Transfer',
        source_location__c = fuel.location5.Id,
        Active__c = true);
        
        skid__c dummySkid = new skid__c (Name = 'DummySkid',
        Company__c = fuel.company.Id,
        Facility2__c = fuel.facility2.Id,
        Item__c =  fuel.itemList[14].Id,
        Quantity__c = 3,
        Packaging_UOM__c = fuel.uomList[11].Id,
        Packaging_UOM__r =  fuel.uomList[11], 
        Container_Item__c = fuel.itemList[12].Id ,
        Container_Item__r = fuel.itemList[12]                        
       );
          
        list<skidservice3.directPutawayWrapper> dpWList = new list<skidservice3.directPutawayWrapper>();
        skidservice3.directPutawayWrapper dpW =  new SkidService3.directPutawayWrapper( dummySMR, dummySkid);
        
        dpWList.add(dpW);
        map<integer, Bin__c > availableBin = SkidService3.availableBinForDirectPutaway(dpWList);
        system.assertEquals(1, availableBin.size());
        system.assertEquals(bin2.id, availableBin.get(0).id);
        
 
    }
    private static testMethod void putawayInventoryInPartPallet() {
        
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
        //cs-2 each,pt-3 cases,pt-eaches -6 cases = 12,PT -13,EA2 - 11
        Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 1,
            Packaging_UOM__c = fuel.uomList[13].Id
        );
        insert bin1;
         Bin__c bin2 = new Bin__c(
            Name = 'Location 3 Bin2',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[13].Id
        );
        insert bin2;
        LPN__c LPN1 = new LPN__c(
            Name = 'LPN-1'
        );
        insert LPN1;
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 2,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            Bin__c = bin1.id,
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[12].Id,
            Packaging_UOM__r = fuel.uomList[12]
        );
        insert skid;
        
        
        //create putaway dummy stock movement rule and putaway skid for direct putaway
        Stock_Movement_Rule__c dummySMR = new Stock_Movement_Rule__c(Name = 'Dummy',
        Rule_Type__c = null,
        Company__c = fuel.company.Id,
        Facility__c = fuel.facility2.Id,
        Class__c = null,
        Item__c =  fuel.itemList[14].Id,
        Customer__c = null,
        Source_Document__c = 'Transfer',
        source_location__c = fuel.location5.Id,
        Active__c = true);
        
        skid__c dummySkid = new skid__c (Name = 'DummySkid',
        Company__c = fuel.company.Id,
        Facility2__c = fuel.facility2.Id,
        Item__c =  fuel.itemList[14].Id,
        Quantity__c = 1,
        Packaging_UOM__c = fuel.uomList[12].Id,
        Packaging_UOM__r =  fuel.uomList[12],                          
        License_Plate_Number__c = LPN1.id,
        Container_Item__c = fuel.itemList[13].Id ,//pallet container item
        Container_Item__r = fuel.itemList[13]                        
       );
          
        list<skidservice3.directPutawayWrapper> dpWList = new list<skidservice3.directPutawayWrapper>();
        skidservice3.directPutawayWrapper dpW =  new SkidService3.directPutawayWrapper( dummySMR, dummySkid);
        
        dpWList.add(dpW);
        map<integer, Bin__c > availableBin = SkidService3.availableBinForDirectPutaway(dpWList);
        system.assertEquals(1, availableBin.size());
        system.assertEquals(bin2.id, availableBin.get(0).id);
        
 
    }
    private static testMethod void putawayInventoryInPartPalletWithOnhandPartPalletInv() {
       
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
        //cs-2 each,pt-3 cases,pt-6 eaches , cases = uomList[12],PT = uomList[13],EA2 - uomList[11]
        Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 1,
            Packaging_UOM__c = fuel.uomList[13].Id
        );
        insert bin1;
         Bin__c bin2 = new Bin__c(
            Name = 'Location 3 Bin2',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[13].Id
        );
        insert bin2;
        LPN__c LPN1 = new LPN__c(
            Name = 'LPN-1'
        );
        insert LPN1;
         LPN__c LPN2 = new LPN__c(
            Name = 'LPN-2'
        );
        insert LPN2;
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 1,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            Bin__c = bin1.id,
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[12].Id,
            Packaging_UOM__r = fuel.uomList[12],
            License_Plate_Number__c = LPN2.id,
            Container_Item__c = fuel.itemList[13].Id ,//pallet container item
            Container_Item__r = fuel.itemList[13]                        
        );
        insert skid;
        
        
        //create putaway dummy stock movement rule and putaway skid for direct putaway
        Stock_Movement_Rule__c dummySMR = new Stock_Movement_Rule__c(Name = 'Dummy',
        Rule_Type__c = null,
        Company__c = fuel.company.Id,
        Facility__c = fuel.facility2.Id,
        Class__c = null,
        Item__c =  fuel.itemList[14].Id,
        Customer__c = null,
        Source_Document__c = 'Transfer',
        source_location__c = fuel.location5.Id,
        Active__c = true);
        
        skid__c dummySkid = new skid__c (Name = 'DummySkid',
        Company__c = fuel.company.Id,
        Facility2__c = fuel.facility2.Id,
        Item__c =  fuel.itemList[14].Id,
        Quantity__c = 1,
        Packaging_UOM__c = fuel.uomList[12].Id,
        Packaging_UOM__r =  fuel.uomList[12],                          
        License_Plate_Number__c = LPN1.id,
        Container_Item__c = fuel.itemList[13].Id ,//pallet container item
        Container_Item__r = fuel.itemList[13]                        
       );
          
        list<skidservice3.directPutawayWrapper> dpWList = new list<skidservice3.directPutawayWrapper>();
        skidservice3.directPutawayWrapper dpW =  new SkidService3.directPutawayWrapper( dummySMR, dummySkid);
        
        dpWList.add(dpW);
        map<integer, Bin__c > availableBin = SkidService3.availableBinForDirectPutaway(dpWList);
        system.assertEquals(1, availableBin.size());
        system.assertEquals(bin2.id, availableBin.get(0).id);
        
 
    }
    private static testMethod void putawayInventoryMatchingLPN() {
       
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
        //cs-2 each,pt-3 cases,pt-eaches -6 cases = 12,PT -13,EA2 - 11
        Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[13].Id
        );
        insert bin1;
         Bin__c bin2 = new Bin__c(
            Name = 'Location 3 Bin2',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[13].Id
        );
        insert bin2;
        LPN__c LPN1 = new LPN__c(
            Name = 'LPN-1'
        );
        insert LPN1;
         LPN__c LPN2 = new LPN__c(
            Name = 'LPN-2'
        );
        insert LPN2;
        //part pallet skid
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 1,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            Bin__c = bin1.id,
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[12].Id,
            Packaging_UOM__r = fuel.uomList[12],
            License_Plate_Number__c = LPN1.id,
            Container_Item__c = fuel.itemList[13].Id ,
            Container_Item__r = fuel.itemList[13]                        
        );
        insert skid;
        //pallet skid
        SKID__c skid2 = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 1,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',   
            Bin__c = bin2.id,
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[13].Id,
            Packaging_UOM__r = fuel.uomList[13],
            License_Plate_Number__c = LPN2.id,
            Container_Item__c = fuel.itemList[13].Id ,
            Container_Item__r = fuel.itemList[13]                        
        );
        insert skid2;
        
        
        //create putaway dummy stock movement rule and putaway skid for direct putaway
        Stock_Movement_Rule__c dummySMR = new Stock_Movement_Rule__c(Name = 'Dummy',
        Rule_Type__c = null,
        Company__c = fuel.company.Id,
        Facility__c = fuel.facility2.Id,
        Class__c = null,
        Item__c =  fuel.itemList[14].Id,
        Customer__c = null,
        Source_Document__c = 'Transfer',
        source_location__c = fuel.location5.Id,
        Active__c = true);
        
        skid__c dummySkid = new skid__c (Name = 'DummySkid',
        Company__c = fuel.company.Id,
        Facility2__c = fuel.facility2.Id,
        Item__c =  fuel.itemList[14].Id,
        Quantity__c = 1,
        Packaging_UOM__c = fuel.uomList[12].Id,
        Packaging_UOM__r =  fuel.uomList[12],                          
        License_Plate_Number__c = LPN1.id,
        Container_Item__c = fuel.itemList[13].Id ,//pallet container item
        Container_Item__r = fuel.itemList[13]                        
       );
          
        list<skidservice3.directPutawayWrapper> dpWList = new list<skidservice3.directPutawayWrapper>();
        skidservice3.directPutawayWrapper dpW =  new SkidService3.directPutawayWrapper( dummySMR, dummySkid);
        
        dpWList.add(dpW);
        map<integer, Bin__c > availableBin = SkidService3.availableBinForDirectPutaway(dpWList);
        system.assertEquals(1, availableBin.size());
        system.assertEquals(bin1.id, availableBin.get(0).id);  
 
    }
    private static testMethod void putawayInventoryNoBinFound() {
        
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
        //cs-2 each,pt-3 cases,pt-eaches -6 cases = 12,PT -13,EA2 - 11
      
        Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin1;
         Bin__c bin2 = new Bin__c(
            Name = 'Location 3 Bin2',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin2;
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 4,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            Bin__c = bin1.id,
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[11].Id,
            Packaging_UOM__r = fuel.uomList[11]
        );
        insert skid;
        
        SKID__c skid2 = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 4,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            Bin__c = bin2.id,
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[11].Id,
            Packaging_UOM__r = fuel.uomList[11]
        );
        insert skid2;
        
        
        //create putaway dummy stock movement rule and putaway skid for direct putaway
        Stock_Movement_Rule__c dummySMR = new Stock_Movement_Rule__c(Name = 'Dummy',
        Rule_Type__c = null,
        Company__c = fuel.company.Id,
        Facility__c = fuel.facility2.Id,
        Class__c = null,
        Item__c =  fuel.itemList[14].Id,
        Customer__c = null,
        Source_Document__c = 'Transfer',
        source_location__c = fuel.location5.Id,
        Active__c = true);
        
        skid__c dummySkid = new skid__c (Name = 'DummySkid',
        Company__c = fuel.company.Id,
        Facility2__c = fuel.facility2.Id,
        Item__c =  fuel.itemList[14].Id,
        Quantity__c = 3,
        Packaging_UOM__c = fuel.uomList[11].Id,
        Packaging_UOM__r =  fuel.uomList[11], 
        Container_Item__c = fuel.itemList[12].Id ,
        Container_Item__r = fuel.itemList[12]                        
       );
          
        list<skidservice3.directPutawayWrapper> dpWList = new list<skidservice3.directPutawayWrapper>();
        skidservice3.directPutawayWrapper dpW =  new SkidService3.directPutawayWrapper( dummySMR, dummySkid);
        
        dpWList.add(dpW);
        map<integer, Bin__c > availableBin = SkidService3.availableBinForDirectPutaway(dpWList);
        system.assertEquals(0, availableBin.size());//No bin found 
 
    }

    private static testMethod void putawayInventoryInMultipleWrapper() {
        
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
        //cs-2 each,pt-3 cases,pt-eaches -6 cases = 12,PT -13,EA2 - 11
       // update new Item__c(Id = fuel.itemList[24].Id ,Container_Item__c =  fuel.itemList[22].Id );
        Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin1;
         Bin__c bin2 = new Bin__c(
            Name = 'Location 3 Bin2',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin2;
        
        
        //create putaway dummy stock movement rule and putaway skid for direct putaway
        Stock_Movement_Rule__c dummySMR = new Stock_Movement_Rule__c(Name = 'Dummy',
        Rule_Type__c = null,
        Company__c = fuel.company.Id,
        Facility__c = fuel.facility2.Id,
        Class__c = null,
        Item__c =  fuel.itemList[14].Id,
        Customer__c = null,
        Source_Document__c = 'Transfer',
        source_location__c = fuel.location5.Id,
        Active__c = true);
        
        skid__c dummySkid = new skid__c (Name = 'DummySkid',
        Company__c = fuel.company.Id,
        Facility2__c = fuel.facility2.Id,
        Item__c =  fuel.itemList[14].Id,
        Quantity__c = 3,
        Packaging_UOM__c = fuel.uomList[11].Id,
        Packaging_UOM__r =  fuel.uomList[11], 
        Container_Item__c = fuel.itemList[12].Id ,
        Container_Item__r = fuel.itemList[12]                        
       );
       
        Stock_Movement_Rule__c dummySMR2 = new Stock_Movement_Rule__c(Name = 'dummySMR2',
        Rule_Type__c = null,
        Company__c = fuel.company.Id,
        Facility__c = fuel.facility2.Id,
        Class__c = null,
        Item__c =  fuel.itemList[14].Id,
        Customer__c = null,
        Source_Document__c = 'Transfer',
        source_location__c = fuel.location5.Id,
        Active__c = true);
        
        skid__c dummySkid2 = new skid__c (Name = 'DummySkid2',
        Company__c = fuel.company.Id,
        Facility2__c = fuel.facility2.Id,
        Item__c =  fuel.itemList[14].Id,
        Quantity__c = 3,
        Packaging_UOM__c = fuel.uomList[11].Id,
        Packaging_UOM__r =  fuel.uomList[11], 
        Container_Item__c = fuel.itemList[12].Id ,
        Container_Item__r = fuel.itemList[12]                        
       );
          
        list<skidservice3.directPutawayWrapper> dpWList = new list<skidservice3.directPutawayWrapper>();
        skidservice3.directPutawayWrapper dpW =  new SkidService3.directPutawayWrapper( dummySMR, dummySkid);
        skidservice3.directPutawayWrapper dpW2 =  new SkidService3.directPutawayWrapper( dummySMR2, dummySkid2);
        dpWList.add(dpW);
        dpWList.add(dpW2);
        system.assertEquals(2, dpWList.size(),dpWList);
        map<integer, Bin__c > availableBin = SkidService3.availableBinForDirectPutaway(dpWList);
        system.assertEquals(2, availableBin.size(),availableBin);
        system.assertEquals(bin1.id, availableBin.get(0).id);
        system.assertEquals(bin2.id, availableBin.get(1).id);
 
    }

    
}