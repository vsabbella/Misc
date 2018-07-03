/*
*   Test methods for InventoryMasterViewExt
*/
@isTest
public with sharing class InventoryMasterViewExtTest {
    static TestFuel fuel = new TestFuel();
    static List<String> attributesforDisplay;
    static testMethod void testgetLotMasterViewFieldList() {
        // Arrange
        Item__c item = getItem();
        ApexPages.StandardController stdCon = new Apexpages.StandardController(item);
        InventoryMasterViewExt lmhCon = new InventoryMasterViewExt(stdCon);
        GridRelatedListController con = new GridRelatedListController();
        con.config = getLotMasterViewLinesConfig();
        System.assert(lmhCon.skiddetailFieldsJson != null,lmhCon.skiddetailFieldsJson);
        System.assert(lmhCon.NamespaceUU != null);
        // Act
        List<ID> itemIDs = new List<ID>();
        itemIDs.add(item.ID);
        JSONResult result = InventoryMasterViewExt.getColumnList(itemIDs);
        
        // Assert
        System.assert(result !=null);
        List<Object> recs= result.records;
        attributesforDisplay =(List<String>) recs;
    }
    
    static testMethod void testGetLotMasterViewLinesConfigJson() {
        // Arrange
        Item__c item = getItem();
        ApexPages.StandardController stdCon = new Apexpages.StandardController(item);
        InventoryMasterViewExt lmhCon = new InventoryMasterViewExt(stdCon);
        GridRelatedListController con = new GridRelatedListController();
        
        con.config = lmhCon.invgridConfig;
        
        // Act
        string result = lmhCon.getinvGridConfigJson();
        
        // Assert
        System.assertEquals(result, JSON.serialize(lmhCon.invgridConfig));
    }

    static testMethod void testGetLotMasterViewLines(){
        Test.startTest();
        
        // Arrange
        Item__c item = getItem();
        insertSKIDs();
        
        List<ID> itemIDs = new List<ID>();
        itemIDs.add(item.ID);
        itemIDs.add(fuel.itemList[5].Id);
        
        JSONResult result = InventoryMasterViewExt.getColumnList(itemIDs);
        
        // Assert
        System.assert(result !=null);
        List<Object> recs= result.records;
        attributesforDisplay =(List<String>) recs;
        
        GridRelatedListController.GridRelatedListConfig config = getLotMasterViewLinesConfig();
        
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter = new KendoUtils.FilterDescriptor();
        KendoUtils.FilterDescriptor facilityfilter = new KendoUtils.FilterDescriptor();
        
        List<String> itemlist = new List<String>();
        
        itemlist.add((String)item.ID);
        itemlist.add((String)fuel.itemList[1].Id);
        itemlist.add((String)fuel.itemList[2].Id);
        itemlist.add((String)fuel.itemList[3].Id);
        itemlist.add((String)fuel.itemList[4].Id);
        itemlist.add((String)fuel.itemList[5].Id);
        filter.field = 'Item__c';
        
        filter.operator = 'contains';
        filter.value = JSON.Serialize(itemlist);
        
        facilityfilter.field = 'Facility__c';
        facilityfilter.fieldType = 'string';
        facilityfilter.operator = 'eq';
        facilityfilter.value = fuel.facility.Id;
       
        filters.add(filter);
        filters.add(facilityfilter);
        
        
        JsonResult jsonresult = new JsonResult();
        // Act
        jsonresult = InventoryMasterViewExt.getSkidsbyFacility(attributesforDisplay,filters);
        
        // Assert
        system.assert(jsonresult.records.size()==6,jsonresult);
        JSONResult jsonresult1 = new JSONResult();
        List<SKID__c> skidlist = (List<SKID__c>)jsonresult.records;
        
        Boolean WIPQty,InTransitQty,NettableQty,ConsignedQty,AllocatedQty;
        Boolean softAllocatedQty = false;
        Boolean locationsdisplayed,noLocdisplayed;
        
        for(SKID__c skid:skidlist){
        	
        	if(skid.Input_Quantity__c == 20){
        		WIPQty = true;
        	}
        	else if(skid.Quantity_Scrapped__c == 40){
        		ConsignedQty = true;
        	}
        	else if(skid.Quantity_to_Issue__c == 30){
        		InTransitQty = true;
        	}
        	else if(skid.Quantity_Allocated__c == 25){
        		softAllocatedQty = true;
        		jsonresult1 = InventoryMasterViewExt.getSkidsbyLoc(skid.Facility2__c,skid.Item__c,skid,new list<string>());
        		system.assert(jsonresult1.records.size()==0,jsonresult1);
        		noLocdisplayed=true;
        	}
        	else if(skid.Quantity_Allocated__c == 50){
        		AllocatedQty = true;
        	}
        	else if(skid.Quantity_Used__c == 200){
        		NettableQty = true;
        	}
        	
        	if(skid.Quantity_Allocated__c !=25){
        		jsonresult1 = InventoryMasterViewExt.getSkidsbyLoc(skid.Facility2__c,skid.Item__c,skid,new list<string>());
        		locationsdisplayed =true;
        		system.assert(jsonresult1.records.size()>0,jsonresult1);
        	}
        	
        		
        }
        system.assert(WIPQty ==true && ConsignedQty ==true && WIPQty ==true && softAllocatedQty==true && AllocatedQty ==true && NettableQty==true);
        
        system.assert(locationsdisplayed ==true && noLocdisplayed ==true);
        Test.stopTest();
    }
    
    private static Item__c getItem() {
        Item__c item = fuel.itemList[0];
        
        return item;
    }     
    
    public static void insertSKIDs() { 
        List<SKID__c> sk = new List<SKID__c>();
        Lot__c lotA = new Lot__c(Name = 'LotA', Item__c = fuel.itemList[0].Id, Company__c = fuel.company.Id);
        insert lotA;
        for (Item__c item : fuel.itemList) {
            SKID__c skid = new SKID__c();
            skid.Facility2__c = fuel.facility.Id;
            skid.Item__c= item.Id;
            skid.Expiration_Date__c = System.today() + 30;
          	skid.Company__c = fuel.company.Id;
          	skid.Packaging_UOM__c = item.Stocking_UOM__c;
          	skid.Stocking_UOM__c = item.Stocking_UOM__c;
          	skid.Location__r = fuel.location;
            skid.Location__c = fuel.location.id;
            if(item.Id == fuel.itemList[1].Id){
          		skid.Quantity__c = 25.0;
        		skid.Quantity_Stocking_UOM__c = 25.0;
        		skid.Type__c = 'Allocated';
        		skid.Location__r = null;
            	skid.Location__c = null;
            	sk.add(skid);
          	}
          	else if(item.Id == fuel.itemList[2].Id){
          		skid.Quantity__c = 50.0;
        		skid.Quantity_Stocking_UOM__c = 50.0;
        		skid.Type__c = 'Allocated';
        		//skid.Location__r.Facility__c = fuel.facility.Id;
        		sk.add(skid);
        		
          	}
          	else if(item.Id == fuel.itemList[3].Id){
          		skid.Quantity__c = 20.0;
        		skid.Quantity_Stocking_UOM__c = 20.0;
        		skid.Type__c = 'WIP';
        		sk.add(skid);
          	}
          	else if(item.Id == fuel.itemList[4].Id){
          		skid.Quantity__c = 30.0;
        		skid.Quantity_Stocking_UOM__c = 30.0;
        		skid.Type__c = 'In-Transit';
        		sk.add(skid);
          	}
          	else if(item.Id == fuel.itemList[5].Id){
          		skid.Quantity__c = 40.0;
        		skid.Quantity_Stocking_UOM__c = 40.0;
        		skid.Type__c = 'Location';
        		skid.Consigned_Owner__c = fuel.supplier.Id;
        		sk.add(skid);
          	}
          	else if(item.Id == fuel.itemList[0].Id){
          		skid.Type__c = 'Location';
            	skid.Quantity__c = 200.0;
            	skid.Quantity_Stocking_UOM__c = 200.0;
            	skid.Lot__c = lotA.Id;
            	skid.lot__r = lotA;
            	sk.add(skid);
          	}
        }
        
        insert sk;
        
        
    }
    
    private static GridRelatedListController.GridRelatedListConfig getLotMasterViewLinesConfig() {
        GridRelatedListController.GridRelatedListConfig config = new GridRelatedListController.GridRelatedListConfig();
        config.title = 'Lot Master View Lines';
        config.buttons = 'search, excel, pdf';

        return config;
    }
}