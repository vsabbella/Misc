/** 
 * @description Produce a list of lot, location, issues, receipts, adjustments, allocated, on hand and available quantity for a given Item
 */
global with sharing class InventoryMasterViewExt extends BaseController {
	ApexPages.StandardController con;
	public string NamespaceUU { get { return KSE.NamespaceUU; }}
	private static SchemaUtil util = SchemaUtil.getInstance();
	private static final Map<String, Schema.sObjectField> skidFieldMap = util.getFieldsMap('SKID__c');
	public GridRelatedListController.GridRelatedListConfig invgridConfig {get; set;}	
	public Boolean isHideResultsOnPageLoad {get; set;}	
    public Id defaultItemId { get; set; }
    public String defaultItemName { get;set;}
    public Id defaultFacId { get; set; }
	public static List<String> invMasterAttributes = util.getFieldsFromFieldSetString(SKID__c.sObjectType , 'InventoryMasterAttributes');
    public static List<String> attributestoDisplayList = new List<String>();
    
    public InventoryMasterViewExt(ApexPages.StandardController controller) {
        con = controller;
        isHideResultsOnPageLoad = true;
        defaultItemId = ApexPages.CurrentPage().getParameters().get('id');
        User_Preference__c up = UserPreference.getInstance().Preference;
        if(up != null && up.Default_Facility__c != null){
            defaultFacId = up.Default_Facility__c;
        }
        if(defaultItemId !=null){
            Item__c itemRec = [Select Id,Name from Item__c where Id =:defaultItemId];
            defaultItemName = itemRec.Name;
        }
        
    }
   
    @RemoteAction    
    public static JSONResult getColumnList(List<ID>itemIDs){
        
        FieldInfo fieldInfoItem;
        List<FieldInfo> fieldInfoList = new List<FieldInfo>();
        
        JsonResult result = new JsonResult();
        
        fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', new List<String>{ 'Item__c','Facility2__c'}));
        Set<String> allitemsAttrSet = new Set<String>();
        Set<String> fieldStrings = new Set<String>{'Id','Name','Item_Attribute__c','Non_Inventory__c','Source__c','Company__c',
                                    'Class__r.Minimum_Shelf_Life_In_Days__c','ABC_Code__c'};
        fieldStrings.addAll(util.getAllCustomFieldsFromObject('Item_Attribute__r.','Item_Attribute__c'));
        
        String whereClause = 'Id IN :itemIDs ';
        SOQLUtil soql = new SOQLUtil('Item__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(whereClause);	

        List<Item__c> items = database.query(soql.getQuery());
		
        if(items.size() > 0 ){
        	
	         Map<Item__c, List<String>> itemtrackedAttrMap = SkidService3.trackedAttributes(null, null, items);
	         for(List<String> strList: itemtrackedAttrMap.values()) {
	             allitemsAttrSet.addall(strList);
	         }
	        
	       	if(allitemsAttrSet.contains('lot_number__c')) {
	            allitemsAttrSet.remove('lot_number__c');
	            allitemsAttrSet.add('lot__c');
	       	}
	      
	       	Set<String> inventoryAttributes = new Set<String>(invMasterAttributes);
	       	inventoryAttributes = util.removeNSfromSetString(inventoryAttributes);
	       
	        //collection of tracked attributes for all items selected for the report.
	        for(String str : inventoryAttributes){
	           if(allitemsAttrSet.contains(str.toLowerCase())){
	              attributestoDisplayList.add(str);
	           }  
	        }
        }
        else{
            attributestoDisplayList = invMasterAttributes;
            
        }
		
        List<FieldInfo> attributestoDisplay = FieldInfo.fetchJsonFieldInfos('SKID__c',attributestoDisplayList);

        for(FieldInfo fi : attributestoDisplay){
         
            fieldInfoItem = new FieldInfo(fi.field, fi.title, fi.fieldtype);
            FieldInfoItem.field = fi.field;
		    fieldInfoItem.editable = false;
		    fieldInfoList.add(fieldInfoItem);
               
        }
        List<String> skidFields = new List<String>();
        skidFields.addAll(new List<String>{'Quantity_Available__c','Quantity_Used__c','Quantity_Allocated__c', 'Input_Quantity__c', 'Quantity_to_Issue__c','Quantity_Scrapped__c' });
		
        fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', skidFields));
        for (FieldInfo fi:fieldInfoList) {
        	
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
         
        
       Set<String> itemDisplayattributes = new Set<String>(attributestoDisplayList);
       itemDisplayattributes = util.removeNSfromSetString(itemDisplayattributes);
       List<String> itemattributes= new List<String>();
       itemattributes.addAll(itemDisplayattributes);
       List<object> records = (List<object>) attributestoDisplayList;
       result.records = records;//JSON.serialize
       
       result.additionalInfo = JSON.serialize(fieldInfoList);
       return result;
    }
    
	//Inventory by Facility/Location
	
	
    public String skiddetailFieldsJson {
        get {
            if (skiddetailFieldsJson == null) {
                List<String> skidFields = new List<String>();
                skidFields.addAll(new List<String>{ 'Location__c','Bin__c','Quantity_Available__c','Quantity_Used__c','Quantity_Allocated__c', 'Input_Quantity__c', 'Quantity_to_Issue__c','Quantity_Scrapped__c' });

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
    public static JSONResult getSkidsbyLoc(Id facilityId,String itemrecId,SKID__c skidObj,List<String> skidDateFields) {
    	
    	JsonResult result = new JsonResult();
    	Id itemId = (Id)itemrecId;
    	
    	KendoUtils.UpdateDateFields(skidObj, skidDateFields);
		SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
		String whereClause;
		Set<String> skidFields = new set<string>{
			'ID','Item__c','Item__r.Name','Item__r.Id','Location__c','Bin__c','Location__r.Nettable__c','Consigned_Owner__c','Quantity__c','Quantity_Stocking_UOM__c','Type__c','Lot__c','Lot__r.Lot_Hold__c','Facility2__r.Name','Facility2__r.Id','Location__r.Facility__r.Name','Location__r.Facility__c','Location__r.Facility__r.Id'
		};
		whereClause = 'Item__c = :itemId and Location__r.Facility__c = :facilityId and (Type__c = \'Location\' or Type__c = \'Allocated\' or Type__c = \'Planned Pick\' or Type__c = \'In-Transit\' or Type__c = \'WIP\')';
		skidFields.addAll(util.getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.','Item_Attribute__c') );
		skidFields.addAll(util.getAllCustomFieldsFromObject('', 'SKID__c'));
		for (String attr: invMasterAttributes) {
			if(skidObj.get(attr) !=null && skidObj.get(attr) !=''){
	            	if(skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Date || 
	            	  skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.DateTime){
	            		Date dateVal = (Date)skidObj.get(attr);
	            		dateVal = date.newinstance(dateVal.year(), dateVal.month(), dateVal.day());
	            		whereClause += ' and '+attr+' = :dateval';
	            	}
	            	else
	            		whereClause += ' and '+attr+' = '+'\''+skidObj.get(attr)+'\'';
            } 
            else{
            	whereClause += ' and '+attr+' = null';
            }
        }
        
		soql.addFields(skidFields);
		soql.setWhereClause(whereClause);
		soql.setOrderByClause('Location__r.Name ASC');
		
		List<SKID__c>SKIDList = Database.query(soql.getQuery());
        
        
        map<list<string>, list<SKID__c>> locationSKIDmap = new map<list<string>, list<SKID__c>>();          
        
        for(SKID__c skid:SKIDlist){
            List<String> keyList= new list<String>{skid.Location__c,skid.Bin__c};
            for (String attr: invMasterAttributes) {
                if(skid.get(attr) !=null && skid.get(attr) !=''){
                   keyList.add(string.valueof(skid.get(attr)));
                }   
            }
            if(locationSKIDmap.containsKey(keyList)==false){
                locationSKIDmap.put(keyList, new list<SKID__c>());
            }
            locationSKIDmap.get(keyList).add(skid); // creating a map of all skids in a location
                
        }
        List<SKID__c> quantityskids = new List<SKID__c>();
        for(List<String> keyList:locationSKIDmap.keyset()){
        	
        	SKID__c qtySkid = new SKID__c(Quantity_Used__c=0,Quantity_Available__c=0,Quantity_Allocated__c=0,Quantity_to_Issue__c=0,Input_Quantity__c=0,Quantity_Scrapped__c=0);
			
        	for(SKID__c sk:locationSKIDmap.get(keyList)){
        		   qtySkid.Location__r = sk.Location__r;
        		   qtySkid.Location__c = sk.Location__c;
        		   qtySkid.bin__r = sk.bin__r;
        		   qtySkid.bin__c = sk.bin__c;
		          if(sk.Type__c =='Location' && sk.Consigned_Owner__c !=null){
               	  	qtySkid.Quantity_Scrapped__c += sk.Quantity_Stocking_UOM__c;
               	  	if(sk.location__r.Nettable__c && (!sk.Lot__r.Lot_Hold__c))
               	  		qtyskid.Quantity_Used__c += sk.Quantity_Stocking_UOM__c;
               	  	else{
               	  		qtyskid.Quantity_Available__c += sk.Quantity_Stocking_UOM__c;
               	  	}
               	  }	  
        		  else if(sk.Type__c =='Location' && sk.location__r.Nettable__c && (!sk.Lot__r.Lot_Hold__c)){
                    
                    qtySkid.Quantity_Used__c += sk.Quantity_Stocking_UOM__c;
                  }
                  else if(sk.Type__c =='Location'){
                    
                    qtySkid.Quantity_Available__c += sk.Quantity_Stocking_UOM__c;
                  }
                  else if(sk.Type__c == 'Allocated' || sk.Type__c == 'Planned Pick'){
                    
                    qtySkid.Quantity_Allocated__c += sk.Quantity_Stocking_UOM__c;
                  }
                  else if(sk.Type__c == 'In-Transit'){
                    
                    qtySkid.Quantity_to_Issue__c += sk.Quantity_Stocking_UOM__c;
                  }
                  else if(sk.Type__c == 'WIP'){
                    
                    qtySkid.Input_Quantity__c += sk.Quantity_Stocking_UOM__c;
               	  }
               	  
               	
        	}
        	quantityskids.add(qtySkid);
        }
        result.records = quantityskids;
        result.total = quantityskids.size();
        
        return result;
    }
    
    @RemoteAction 
    public static JSONResult getSkidsbyFacility(List<String> attributesforDisplay,List<KendoUtils.FilterDescriptor> filters) {
    	JsonResult result = new JsonResult();
    	List<KendoUtils.FilterDescriptor> filtersList = new List<KendoUtils.FilterDescriptor>();
		List<String> filterCriteria = new List<String>();
    	
    	Boolean facilityFilter = false;
    	for (KendoUtils.FilterDescriptor fd: filters) {
        	
        	KendoUtils.FilterDescriptor filter = new KendoUtils.FilterDescriptor();
        	
        	if (fd.field == 'Facility__c') {
        		filter.field = 'Facility2__c';
        		filter.fieldType = fd.fieldType;
        		filter.operator = fd.operator;
        		filter.value = fd.value;
        		facilityFilter = true;
        	}
        	else {
        		filter = fd;
        	}
        	
        	filtersList.add(filter);
        }
        
        filterCriteria = KendoUtils.getFilterCriteria(filtersList);

		SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
		String whereClause;
		Set<String> skidFields = new set<string>{
			'ID','Item__c','Type__c','Item__r.Name','Item__r.Id','Lot__c','Lot__r.Name','Type__c','Bin__c','Bin__r.Name','Location__c','Location__r.Facility__c','Location__r.Facility__r.Name','Location__r.Nettable__c','Consigned_Owner__c','Quantity__c','Quantity_Stocking_UOM__c','Type__c','Lot__c','Lot__r.Lot_Hold__c','Facility2__r.Name','Facility2__r.Id'
		};
		
		whereClause = '(Type__c = \'Location\' or Type__c = \'Allocated\' or Type__c = \'Planned Pick\' or Type__c = \'In-Transit\' or Type__c = \'WIP\')';
		
		if (filterCriteria.size() > 0) {
        	whereClause += ' AND ' + String.join(filterCriteria, ' AND ');
        }
		skidFields.addAll( util.getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.','Item_Attribute__c') );
		skidFields.addAll(util.getAllCustomFieldsFromObject('', 'SKID__c'));
		soql.addFields(skidFields);
		soql.setWhereClause(whereClause);
		
		soql.setOrderByClause('Item__r.Name,Facility2__r.Name ASC');
        
        
		List<SKID__c>SKIDList = Database.query(soql.getQuery());
        
        map<list<string>, List<SKID__c>> facilitySkidsmap = new map<list<string>, List<SKID__c>>();
        
        for(SKID__c skid:SKIDlist){
            List<String> facilitykeyList = new List<String>{skid.Item__c,skid.Facility2__c};
            
            for (String attr: invMasterAttributes) {
                if(skid.get(attr) !=null && skid.get(attr) !=''){
                   
                   facilitykeyList.add(string.valueof(skid.get(attr)));
                }   
            }
            
            if(!facilitySkidsmap.containsKey(facilitykeyList)){
            	facilitySkidsmap.put(facilitykeyList, new list<skid__c>());
            }
            facilitySkidsmap.get(facilitykeyList).add(skid);
            
                
        }
        
		//Also loop through soft allocated skids without location.
		
		List<SKID__c> quantityskids = new List<SKID__c>();
		Schema.sObjectType skidObjType = util.getGlobalDescribe('Skid__c');
        Map<String, Schema.sObjectField> skidFieldsMap = skidObjType.getDescribe().fields.getMap();
        
        for(List<String> strKey:facilitySkidsmap.keyset()){
    		SKID__c qtySkid = new SKID__c(Quantity_Used__c=0,Quantity_Available__c=0,Quantity_Allocated__c=0,Quantity_to_Issue__c=0,Input_Quantity__c=0,Quantity_Scrapped__c=0);
        	for(SKID__c sk:facilitySkidsmap.get(strKey)){
        		if(qtySkid.Item__c == null){
        			qtySkid.Item__c = sk.Item__c ;
        		  	qtySkid.Item__r = sk.Item__r;
        		}
        		if(qtySkid.Facility2__c == null){
    				qtySkid.Facility2__c = sk.Facility2__c;
    		  		qtySkid.Facility2__r = sk.Facility2__r;
        		}
        		
	    		if(sk.Type__c =='Location' && sk.Consigned_Owner__c !=null){
	  	
   	  				qtySkid.Quantity_Scrapped__c += sk.Quantity_Stocking_UOM__c;
   	  				if(sk.location__r.Nettable__c && (!sk.Lot__r.Lot_Hold__c))
               	  		qtyskid.Quantity_Used__c += sk.Quantity_Stocking_UOM__c;
               	  	else{
               	  		qtyskid.Quantity_Available__c += sk.Quantity_Stocking_UOM__c;
               	  	}
   	    		}
	   			else if(sk.Type__c =='Location' && sk.location__r.Nettable__c && (!sk.Lot__r.Lot_Hold__c)){
        
      	    		qtySkid.Quantity_Used__c += sk.Quantity_Stocking_UOM__c;
		     	}
		      	else if(sk.Type__c =='Location'){
		        
		        	qtySkid.Quantity_Available__c += sk.Quantity_Stocking_UOM__c;
		      	}
	      		else if(sk.Type__c == 'Allocated' || sk.Type__c == 'Planned Pick'){
	       			qtySkid.Quantity_Allocated__c += sk.Quantity_Stocking_UOM__c;
	      		}
	      		else if(sk.Type__c == 'In-Transit'){
	        
	        		qtySkid.Quantity_to_Issue__c += sk.Quantity_Stocking_UOM__c;
	      		}
	      		else if(sk.Type__c == 'WIP'){
	        
	       			qtySkid.Input_Quantity__c += sk.Quantity_Stocking_UOM__c;
	   	  		}
   	  
           	 	 //Populating tracked attributes
           	  
           	  	for(String attr:attributesforDisplay){
	           	  	 if(sk.get(attr) !=null){
	           	  	 	 qtySkid.put(attr,sk.get(attr));
	           	  	 	 if(attr.tolowercase() == 'lot__c' && sk.get('Lot__c') !=null){
	    					qtySkid.Lot_Number__c = (String)sk.getSobject('Lot__r').get('Name');
	    					qtySkid.putSObject('Lot__r' ,sk.getSobject('Lot__r'));
	           	  	 	 }
	           	  	 	 else if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference){
	           	  	 	 	
	                        String lookupfield = attr.replace('__c', '__r');
	                        qtySkid.putSObject(lookupfield, sk.getSObject(lookupfield));
	           	  	 	 	
	           	  	 	 }
	           	  	 }
	           	  	 else{
	           	  	 	qtySkid.put(attr,null) ;
	           	  	 }
                }
           	 
         }
         quantityskids.add(qtySkid);
      }
      result.records = quantityskids;
      result.total = quantityskids.size();
    
      return result;
    }
    
    public string getinvGridConfigJson() {
        invgridConfig = new GridRelatedListController.GridRelatedListConfig();
        invgridConfig.uniqueId = 'InventorybyFacilityGrid';
        invgridConfig.title = 'Quantity Information';
        invgridConfig.buttons = 'Expand All, Collapse All, excel, pdf';
        return JSON.serialize(invgridConfig);
    }
}