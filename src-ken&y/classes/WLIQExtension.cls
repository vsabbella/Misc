/** 
 * @description Produce a list of facility location and quantity for a given Item, called from 
 * a visualforce page the can be placed on the standard page for the Item to give a summary of inventory
 */
global with sharing class WLIQExtension extends BaseController{

    private apexpages.StandardController c;
    public String namespaceUU { get; set; } { namespaceUU = KSE.namespaceUU; }
    public GridRelatedListController.GridRelatedListConfig invgridConfig {get; set;}
    public Item__c it {get; set;}
    public Id defaultItemId { get; set; }
    public string pageTitle { get; set; }
    public Boolean selecterror {get; set;}
     
    public WLIQExtension(ApexPages.StandardController con) {
        c=con;
        it=(Item__c)c.getRecord();
        defaultItemId = it.Id;
        ID WID, LID, itemId;
        Double qty;
        Integer i;
    
        selecterror = false;
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		itemId = it.Id;
		SOQLUtil soql = new SOQLUtil('Item__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID'
		});
		soql.setWhereClause('ID = :itemId');
		
		List<Item__c> itList = Database.query(soql.getQuery());

        if (itList.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Invalid_Item));
            selecterror = true;
            return;
        } 
        
        itemId = it.Id;
		
		
    }
    
    public String skidFieldsJson {
        get {
            if (skidFieldsJson == null) {
                List<String> skidFields = new List<String>();
                skidFields.addAll(new List<String>{ 'Facility2__c','Quantity_Available__c','Quantity_Used__c','Quantity_Allocated__c', 'Input_Quantity__c', 'Quantity_to_Issue__c','Quantity_Scrapped__c' });

                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c', skidFields);
                
                for (FieldInfo fi:fiList) {
                	
                	if (fi.field == 'Quantity_Available__c') {
                        fi.title = 'Non-Nettable';
                    } else if (fi.field == 'Quantity_Used__c') {
                        fi.title = 'Nettable';
                    }
                	else if (fi.field == 'Quantity_Allocated__c') {
                        fi.title = Label.Allocated;
                    } else if (fi.field == 'Input_Quantity__c') {
                        fi.title = 'WIP';
                    }
                    else if (fi.field == 'Quantity_to_Issue__c') {
                        fi.title = 'In-Transit';
                    }
                    else if(fi.field == 'Quantity_Scrapped__c'){
                    	fi.title = 'Consigned';
                    }
                	
                	fi.editable = false;
                }
                
                
                skidFieldsJson = JSON.serialize(fiList);
            }
            return skidFieldsJson;
        } set;
    }
    
    public String skiddetailFieldsJson {
        get {
            if (skiddetailFieldsJson == null) {
                List<String> skidFields = new List<String>();
                skidFields.addAll(new List<String>{ 'Location__c','Quantity_Available__c','Quantity_Used__c','Quantity_Allocated__c', 'Input_Quantity__c', 'Quantity_to_Issue__c','Quantity_Scrapped__c' });

                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c', skidFields);
                
                for (FieldInfo fi:fiList) {
                	
                	if (fi.field == 'Quantity_Available__c') {
                        fi.title = 'Non-Nettable';
                    } else if (fi.field == 'Quantity_Used__c') {
                        fi.title = 'Nettable';
                    }
                	else if (fi.field == 'Quantity_Allocated__c') {
                        fi.title = Label.Allocated;
                    } else if (fi.field == 'Input_Quantity__c') {
                        fi.title = 'WIP';
                    }
                    else if (fi.field == 'Quantity_to_Issue__c') {
                        fi.title = 'In-Transit';
                    }
                    else if(fi.field == 'Quantity_Scrapped__c'){
                    	fi.title = 'Consigned';
                    }
                	fi.editable = false;
                }
                
                
                skiddetailFieldsJson = JSON.serialize(fiList);
            }
            return skiddetailFieldsJson;
        } set;
    }
    
    @RemoteAction
    global static JSONResult getLocandFacilityIds(String itemrecId){
    	JSONResult result = new JSONResult();
    	Id itemId = (Id)itemrecId;
    	SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Facility2__c','Location__c','Location__r.Nettable__c','Quantity__c','Quantity_Stocking_UOM__c','Type__c','Lot__c','Lot__r.Lot_Hold__c'
		});
		soql.setWhereClause('Item__c = :itemId and (Type__c = \'Location\' or Type__c = \'Allocated\' or Type__c = \'In-Transit\' or Type__c = \'WIP\')');
		//soql.setOrderByClause('Location__r.Name ASC');

		List<SKID__c>SKIDList = Database.query(soql.getQuery());
		
        set<id> locationIDset = new set<id>(); 
        set<id> facilityIDset = new set<id>();  
        map<id, list<SKID__c>> locationSKIDmap = new map<id, list<SKID__c>>();          
        map<id, location__c> locationMap = new map<id, location__c>();
        
        for(SKID__c skid:SKIDlist){
        	if(skid.Location__c !=null)
            	locationIDset.add(skid.Location__c);
            if(skid.Facility2__c !=null)
            	facilityIDset.add(skid.Facility2__c);
        }
        List<Id> locIds = new List<Id>(locationIDset);
        List<Id> facilityrecIds = new List<Id>(facilityIDset);
        
        List<object> records = (List<object>) locIds;
        result.records = records;
        if(facilityIDset.size()>0)
        	result.additionalInfo = JSON.serialize(facilityIDset);
        else
        	result.additionalInfo = null;
        	
		return result;
    }
    
    @RemoteAction 
    global static JSONResult getSkidsbyLoc(List<Id> locIds,Id facilityId,String itemrecId) {
    	
    	JsonResult result = new JsonResult();
    	Id itemId = (Id)itemrecId;
    	Set<Id> locationIDset = new Set<Id>(locIds);
		SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Location__c','Location__r.Nettable__c','Consigned_Owner__c','Quantity__c','Quantity_Stocking_UOM__c','Type__c','Lot__c','Lot__r.Lot_Hold__c','Location__r.Name'
		});
		soql.setWhereClause('Item__c = :itemId and Location__c = :locationIDset and Facility2__c = :facilityId and (Type__c = \'Location\' or Type__c = \'Allocated\' or Type__c = \'Planned Pick\' or Type__c = \'In-Transit\' or Type__c = \'WIP\')');
		soql.setOrderByClause('Location__r.Name ASC');

		List<SKID__c>SKIDList = Database.query(soql.getQuery());
        
        
        map<id, list<SKID__c>> locationSKIDmap = new map<id, list<SKID__c>>();          
        map<id, location__c> locationMap = new map<id, location__c>();
       
        
        for(SKID__c skid:SKIDlist){
            
            if(locationSKIDmap.containsKey(skid.Location__c)==false){
                locationSKIDmap.put(skid.Location__c, new list<SKID__c>());
            }
            if(!locationMap.containsKey(skid.Location__c)){
            	locationMap.put(skid.Location__c, skid.Location__r);
            }
            locationSKIDmap.get(skid.Location__c).add(skid); // creating a map of all skids in a location
                
        }
        List<SKID__c> quantityskids = new List<SKID__c>();
        for(Id locId:locationSKIDmap.keyset()){
        	Location__c locRec = locationMap.get(locId);
        	SKID__c qtyskid = new SKID__c(Location__c = locRec.Id,Location__r = locRec,Quantity_Used__c=0,Quantity_Available__c=0,Quantity_Allocated__c=0,Quantity_to_Issue__c=0,Input_Quantity__c=0,Quantity_Scrapped__c=0);
			
        	for(SKID__c sk:locationSKIDmap.get(locId)){
        		
        		  if(sk.Type__c =='Location' && sk.Consigned_Owner__c !=null){
		          	
               	  	qtyskid.Quantity_Scrapped__c += sk.Quantity_Stocking_UOM__c;
               	  	if(sk.location__r.Nettable__c && (!sk.Lot__r.Lot_Hold__c))
               	  		qtyskid.Quantity_Used__c += sk.Quantity_Stocking_UOM__c;
               	  	else{
               	  		qtyskid.Quantity_Available__c += sk.Quantity_Stocking_UOM__c;
               	  	}
               	  }	  
        		  else if(sk.Type__c =='Location' && sk.location__r.Nettable__c && (!sk.Lot__r.Lot_Hold__c)){
                    
                    qtyskid.Quantity_Used__c += sk.Quantity_Stocking_UOM__c;
                  }
                  else if(sk.Type__c =='Location'){
                    
                    qtyskid.Quantity_Available__c += sk.Quantity_Stocking_UOM__c;
                  }
                  else if(sk.Type__c == 'Allocated' || sk.Type__c == 'Planned Pick'){
                    
                    qtyskid.Quantity_Allocated__c += sk.Quantity_Stocking_UOM__c;
                  }
                  else if(sk.Type__c == 'In-Transit'){
                    
                    qtyskid.Quantity_to_Issue__c += sk.Quantity_Stocking_UOM__c;
                  }
                  else if(sk.Type__c == 'WIP'){
                    
                    qtyskid.Input_Quantity__c += sk.Quantity_Stocking_UOM__c;
               	  }
               	  
               	
        	}
        	quantityskids.add(qtyskid);
        }
        result.records = quantityskids;
        result.total = quantityskids.size();
        
        return result;
    }
    
    @RemoteAction 
    global static JSONResult getSkidsbyFacility(List<Id> facilityIds,String itemrecId) {
    	
    	JsonResult result = new JsonResult();
    	
    	if(facilityIds.size() ==0){
    		return null;
    	}
    	Set<Id> facilityIDset = new Set<Id>(facilityIds);
    	
    	Id itemId = (Id)itemrecId;
    	
		SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Location__c','Location__r.Nettable__c','Consigned_Owner__c','Quantity__c','Quantity_Stocking_UOM__c','Type__c','Lot__c','Lot__r.Lot_Hold__c','Facility2__r.Name','Facility2__r.Id'
		});
		soql.setWhereClause('Item__c = :itemId and Facility2__c = :facilityIDset and (Type__c = \'Location\' or Type__c = \'Allocated\' or Type__c = \'Planned Pick\' or Type__c = \'In-Transit\' or Type__c = \'WIP\')');
		soql.setOrderByClause('Facility2__r.Name ASC');

		List<SKID__c>SKIDList = Database.query(soql.getQuery());
        
        
        map<id, list<SKID__c>> locationSKIDmap = new map<id, list<SKID__c>>();    
        map<id, set<Id>> facilitylocIdmap = new map<id, set<Id>>();     
        map<Id,Facility__c> facilitymap = new map<Id,Facility__c>();
        map<Id,List<SKID__c>> softallocSKids =new map<Id,List<SKID__c>>();
        
        for(SKID__c skid:SKIDlist){
            
            if(skid.Location__c == null && (skid.Type__c == 'Allocated' || skid.Type__c == 'Planned Pick')){
            	if(!softallocSKids.containsKey(skid.Facility2__c)){
            		softallocSKids.put(skid.Facility2__c,new list<SKID__c>());
            	}
            	softallocSKids.get(skid.Facility2__c).add(skid); 
            }
            else if(skid.Location__c != null){
            	
            	if(!locationSKIDmap.containsKey(skid.Location__c))
                	locationSKIDmap.put(skid.Location__c, new list<SKID__c>());
                
                locationSKIDmap.get(skid.Location__c).add(skid); // creating a map of all skids in a location
            }
            
            if(!facilitylocIdmap.containsKey(skid.Facility2__c)){
                facilitylocIdmap.put(skid.Facility2__c, new set<Id>());
            }
            if(!facilitymap.containskey(skid.Facility2__c)){
            	facilitymap.put(skid.Facility2__c,skid.Facility2__r);
            }
            
            facilitylocIdmap.get(skid.Facility2__c).add(skid.Location__c);
                
        }
        
		
		//Also loop through soft allocated skids without location.
		List<SKID__c> quantityskids = new List<SKID__c>();
		for(Id facilityId:facilitymap.keyset()){
			Facility__c facilityRec= facilitymap.get(facilityId);
			
			SKID__c qtyskid = new SKID__c(Facility2__c = facilityRec.Id,Facility2__r = facilityRec,Quantity_Used__c=0,Quantity_Available__c=0,Quantity_Allocated__c=0,Quantity_to_Issue__c=0,Input_Quantity__c=0,Quantity_Scrapped__c=0);
			
			for(Id locId:facilitylocIdmap.get(facilityId)){
				
				if(locationSKIDmap.containskey(locId)){
					for(SKID__c sk:locationSKIDmap.get(locId)){
		        		  
		        		  if(sk.Type__c =='Location' && sk.Consigned_Owner__c !=null){
		        		  	
		               	  	qtyskid.Quantity_Scrapped__c += sk.Quantity_Stocking_UOM__c;
		               	  	if(sk.location__r.Nettable__c && (!sk.Lot__r.Lot_Hold__c))
		               	  		qtyskid.Quantity_Used__c += sk.Quantity_Stocking_UOM__c;
		               	  	else{
		               	  		qtyskid.Quantity_Available__c += sk.Quantity_Stocking_UOM__c;
		               	  	}
		               	  }
		        		  else if(sk.Type__c =='Location' && sk.location__r.Nettable__c && (!sk.Lot__r.Lot_Hold__c)){
		                    
		                    qtyskid.Quantity_Used__c += sk.Quantity_Stocking_UOM__c;
		                  }
		                  else if(sk.Type__c =='Location'){
		                    
		                    qtyskid.Quantity_Available__c += sk.Quantity_Stocking_UOM__c;
		                  }
		                  else if(sk.Type__c == 'Allocated' || sk.Type__c == 'Planned Pick'){
		                    
		                    qtyskid.Quantity_Allocated__c += sk.Quantity_Stocking_UOM__c;
		                  }
		                  else if(sk.Type__c == 'In-Transit'){
		                    
		                    qtyskid.Quantity_to_Issue__c += sk.Quantity_Stocking_UOM__c;
		                  }
		                  else if(sk.Type__c == 'WIP'){
		                    
		                    qtyskid.Input_Quantity__c += sk.Quantity_Stocking_UOM__c;
		               	  }
		               	  
		               		
		        	}
				}
				
	        	
			}
			//Add soft allocated inventory
			if(softallocSKids.containskey(facilityId)){
					
				for(SKID__c allocSk : softallocSKids.get(facilityId)){
					
					if(allocSk.Type__c == 'Allocated' || allocSk.Type__c == 'Planned Pick'){
		                qtyskid.Quantity_Allocated__c += allocSk.Quantity_Stocking_UOM__c;
	                }
				}
				
			}
			quantityskids.add(qtyskid);
		}
        
        result.records = quantityskids;
        result.total = quantityskids.size();
        
        return result;
    }
    
    public String getinvGridConfigJson() {
        invgridConfig = new GridRelatedListController.GridRelatedListConfig();
        invgridConfig.uniqueId = 'InventorybyFacilityGrid';
        invgridConfig.title = 'Quantity Information';
        invgridConfig.objectName = 'Item__c';
        invgridConfig.buttons = 'Expand All, Collapse All,search';
        invgridConfig.alwaysUseFullDateTimeFormat = false;
        return JSON.serialize(invgridConfig);
    }

}