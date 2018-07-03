@isTest
public with sharing class ManageItemExtTest {
		
		
		static testMethod void createItem(){   	
	    
	    	TestFuel fuel = new TestFuel();
	    	String itemHeaderFieldList;
	    	
	    	List<Custom_Tab_Settings__c> customTabSettings = fuel.csTabSettings;
	    	Map<string,list<string>> itemFieldSetmap = new Map<string,list<string>>();
	    	Map<String,String> configMap = new Map<String,String>();
	    	List<String> tabnames = new List<String>();
			Item__c item = new Item__c();
	        
	    	ApexPages.StandardController con = new ApexPages.StandardController(item);
	    	ManageItemExt itemcon = new ManageItemExt(con);
	    	
	    	tabnames = itemcon.gettabs();
	    	itemcon.gethasDetailMap();
	    	itemcon.gethasHeaderMap();
	    	
	    	String itemStr;
	    	//Getting Header Details
	    	itemHeaderFieldList = itemcon.getitemHeaderFieldList();
	    	itemStr = itemcon.getitemDetailJson(); 
	    	
	    	itemFieldSetmap = ManageItemExt.getTabsFieldList(false);
	    	
	    	
	    	Id itemId;
	    	
	    	//Update Item and Save Item Changes
	    	List<String> strlist = new List<String>();
	    	strlist.add(fuel.uomList[8].Id);
			item.Company__c = fuel.company.Id;
			item.Name = 'Test Item New UI';
			item.Description__c = 'New Item Desc';
			item.Last_Cycle_Count__c = system.today();
			item.Weight__c = 100;
			item.Source__c = 'Manufactured';
            item.Class__c = fuel.clsobj.ID;
            item.Lead_Time__c = 1;
            item.ABC_Code__c = 'B';
            item.Active__c = true;
	        item.Stocking_UOM__c = fuel.uomList[8].Id;
	        item.Packaging_UOM__c = JSON.Serialize(strlist);
	        item.item_attribute__c = fuel.itemAttrObj.ID;
			JSONResult itemresult;
			List<String> headerDateFields = new List<String>{'Last_Cycle_Count__c','Next_Cycle_Count_Date__c'};
    		itemresult = ManageItemExt.saveItemChanges(item, headerDateFields);
    		system.assert(itemresult.records.size()==1, itemresult);
    		Item__c savedItem;
    		savedItem = (Item__c)itemresult.records[0];
    		itemId = savedItem.Id;
    		
    		List<SObject> productlist = new List<SObject>();
    		List<SObject> itemSpeclist = new List<SObject>();
    		List<SObject> facilityItemlist = new List<SObject>();
    		List<SObject> updatedlist = new List<SObject>();
    		List<SObject> deletelist = new List<SObject>();
    		
    		
	    	JSONResult prodresult;
	    	JSONResult itemSpecresult;
	    	JSONResult facilityItemresult;
    		
    		Product__c newprod = new Product__c(Name = 'Test Prod 1', Description__c = 'Prod Desc', Selling_UOM__c = fuel.uomList[8].Id, Item__c = itemId, Company__c = fuel.company.Id);
    		productlist.add((SObject)newprod);
    		
    		prodresult = ManageItemExt.saveGridLines(updatedlist, productlist, deletelist, new list<String>{''});
    		system.assert(prodresult.success == true, prodresult);
    		system.assert(prodresult.records.size() >0, prodresult);
    		
    		Item_Specification__c itemspec = new Item_Specification__c(Name = 'Test Prod 1', Revision__c = 'A1', Start_Date2__c = System.now(), Item__c = itemId, Company__c = fuel.company.Id);
    		itemSpeclist.add((SObject)itemspec);
    		itemSpecresult = ManageItemExt.saveGridLines(updatedlist, itemSpeclist, deletelist, new list<String>{''});
    		system.assert(itemSpecresult.success == true, itemSpecresult);
    		system.assert(itemSpecresult.records.size() >0, itemSpecresult);
    		
    		Facility_Item__c facilityitem = new Facility_Item__c(Name = savedItem.Name, Facility__c = fuel.facility.Id, Item__c = itemId, Company__c = fuel.company.Id);
    		facilityItemlist.add((SObject)facilityitem);
    		facilityItemresult = ManageItemExt.saveGridLines(updatedlist, facilityItemlist, deletelist, new list<String>{''});
    		system.assert(facilityItemresult.success == true, facilityItemresult);
    		system.assert(facilityItemresult.records.size() >0, facilityItemresult);
    		
	    	for(String s:itemFieldSetmap.keyset()){
	    			
    			if(itemFieldSetmap.get(s).size()>1){
    				
    				String detailfieldlist = itemFieldSetmap.get(s)[1];
    				configMap = ManageItemExt.getGridConfig(s);
    	
					JSONResult result = ManageItemExt.getGridLines(configMap.get('config'), itemId);
					system.assert(result.records.size() == 1, result);
					
    			}
    			
	    		
	    	}
	    	 
		}
		
		static testMethod void createItem_withoutPkgUOM(){   	
	    
	    	TestFuel fuel = new TestFuel();
	    	String itemHeaderFieldList;
	    	
	    	List<Custom_Tab_Settings__c> customTabSettings = fuel.csTabSettings;
	    	Map<string,list<string>> itemFieldSetmap = new Map<string,list<string>>();
	    	Map<String,String> configMap = new Map<String,String>();
	    	List<String> tabnames = new List<String>();
			Item__c item = new Item__c();
	        
	    	ApexPages.StandardController con = new ApexPages.StandardController(item);
	    	ManageItemExt itemcon = new ManageItemExt(con);
	    	
	    	tabnames = itemcon.gettabs();
	    	itemcon.gethasDetailMap();
	    	itemcon.gethasHeaderMap();
	    	
	    	String itemStr;
	    	//Getting Header Details
	    	itemHeaderFieldList = itemcon.getitemHeaderFieldList();
	    	itemStr = itemcon.getitemDetailJson(); 
	    	
	    	itemFieldSetmap = ManageItemExt.getTabsFieldList(false);
	    	
	    	
	    	Id itemId;
	    	
	    	//Update Item and Save Item Changes
	    	List<String> strlist = new List<String>();
	    	strlist.add(fuel.uomList[8].Id);
			item.Company__c = fuel.company.Id;
			item.Name = 'Test Item New UI';
			item.Description__c = 'New Item Desc';
			item.Last_Cycle_Count__c = system.today();
			item.Weight__c = 100;
			item.Source__c = 'Manufactured';
            item.Class__c = fuel.clsobj.ID;
            item.Lead_Time__c = 1;
            item.ABC_Code__c = 'B';
            item.Active__c = true;
	        item.Stocking_UOM__c = fuel.uomList[8].Id;
	        //item.Packaging_UOM__c = JSON.Serialize(strlist);
	        item.item_attribute__c = fuel.itemAttrObj.ID;
			JSONResult itemresult;
			List<String> headerDateFields = new List<String>{'Last_Cycle_Count__c','Next_Cycle_Count_Date__c'};
    		itemresult = ManageItemExt.saveItemChanges(item, headerDateFields);
    		system.assert(itemresult.records.size()==1, itemresult);
    		Item__c savedItem;
    		savedItem = (Item__c)itemresult.records[0];
    		itemId = savedItem.Id;
    		
    		Item__c queriedItem = [Select Id,Name,Packaging_UOM__c from Item__c where Id =: itemId];
	    	system.assert(queriedItem.Packaging_UOM__c !=null,queriedItem);
		}
	
		static testMethod void editItem(){   	
	    
	    	TestFuel fuel = new TestFuel();
	    	Item__c itemRec = fuel.itemlist[0];
	    	
	    	
	    	String itemHeaderFieldList;
	    	String itemHeaderROFieldList;
	    	
	    	List<Custom_Tab_Settings__c> customTabSettings = fuel.csTabSettings;
	    	Map<string,list<string>> itemFieldSetmap = new Map<string,list<string>>();
	    	Map<String,String> configMap = new Map<String,String>();
	    	List<String> tabnames = new List<String>();
			Item__c item = new Item__c();
	        
	    	ApexPages.StandardController con = new ApexPages.StandardController(itemRec);
	    	ManageItemExt itemcon = new ManageItemExt(con);
	    	
	    	String itemStr;
	    	//Getting Header Details
	    	itemHeaderFieldList = itemcon.getitemHeaderFieldList();
	    	itemHeaderROFieldList = itemcon.getitemHeaderROFieldList();
	    	itemStr = itemcon.getitemDetailJson(); 
	    	itemcon.getReturnUrl();
	    	
	    	itemFieldSetmap = ManageItemExt.getTabsFieldList(false);
	    	
	    	//Update Item and Save Item Changes
	    	List<String> strlist = new List<String>();
	    	strlist.add(fuel.uomList[8].Id);
			itemRec.Source__c = 'Purchased';
			itemRec.Description__c = 'Updated Description';
			itemRec.Last_Cycle_Count__c = system.today() + 2;
            itemRec.Lead_Time__c = 1;
            itemRec.ABC_Code__c = 'B';
            itemRec.Stocking_UOM__c = fuel.uomList[8].Id;
            itemRec.Packaging_UOM__c = JSON.Serialize(strlist);
            
			JSONResult itemresult;
			List<String> headerDateFields = new List<String>{'Last_Cycle_Count__c','Next_Cycle_Count_Date__c'};
    		itemresult = ManageItemExt.saveItemChanges(itemRec, headerDateFields);
    		system.assert(itemresult.records.size()==1, itemresult);
    		Item__c savedItem;
    		savedItem = (Item__c)itemresult.records[0];
    		
    		Item__c queriedItem = [Select ABC_Code__c,Next_Cycle_Count_Date__c, Source__c, Last_Cycle_Count__c from Item__c where Id =:itemRec.Id];
    		
    		system.assert(queriedItem.ABC_Code__c == 'B' && queriedItem.Source__c == 'Purchased',queriedItem);
    		system.assert(queriedItem.Last_Cycle_Count__c == system.today() + 2, queriedItem);
    		
    		List<SObject> productlist = new List<SObject>();
    		List<SObject> updatedproductlist = new List<SObject>();
    		List<SObject> itemSpeclist = new List<SObject>();
    		List<SObject> facilityItemlist = new List<SObject>();
    		List<SObject> updatedlist = new List<SObject>();
    		List<SObject> deletelist = new List<SObject>();
    		
    		
	    	JSONResult prodresult;
	    	JSONResult updatedprodresult;
	    	JSONResult itemSpecresult;
	    	JSONResult facilityItemresult;
    		
    		Product__c newprod = new Product__c(Name = 'Test Prod 1', Description__c = 'Prod Desc', Selling_UOM__c = fuel.uomList[8].Id, Item__c = itemRec.Id, Company__c = fuel.company.Id);
    		
    		Product__c newprod1 = new Product__c(Name = 'Test Prod 2', Description__c = 'Prod 2 Desc', Selling_UOM__c = fuel.uomList[6].Id, Item__c = itemRec.Id, Company__c = fuel.company.Id);
    		
    		productlist.add((SObject)newprod);
    		productlist.add((SObject)newprod1);
    		
    		
    		prodresult = ManageItemExt.saveGridLines(updatedlist, productlist, deletelist, new list<String>{''});
    		system.assert(prodresult.success == true, prodresult);
    		system.assert(prodresult.records.size() == 2, prodresult);
    		
    		Product__c queriedproduct = [Select Description__c, Selling_UOM__c from Product__c where Selling_UOM__c =:fuel.uomList[8].Id];
    		
    		queriedproduct.Selling_UOM__c = fuel.uomList[7].Id;
    		queriedproduct.Description__c = 'Updated Test Desc';
    		updatedproductlist.add(queriedproduct);
    		//deletelist.add(newprod1);
    		productlist.clear();
    		
    		updatedprodresult = ManageItemExt.saveGridLines(updatedproductlist, productlist, deletelist, new list<String>{''});
    		system.assert(updatedprodresult.success == true, updatedprodresult);
    		system.assert(updatedprodresult.records.size() >0, updatedprodresult);
    		
    		//List<Product__c> deletedprodlist = [Select Description__c, Selling_UOM__c from Product__c where Selling_UOM__c =:newprod1.Id];
    		//system.assert(deletedprodlist.size() == 0);
		}
}