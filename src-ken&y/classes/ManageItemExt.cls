global with sharing class ManageItemExt extends BaseController {

        ApexPages.StandardController con;
        public string NamespaceUU { get { return KSE.NamespaceUU; }}
        private static SchemaUtil util = SchemaUtil.getInstance();  
        public Boolean initialisedcs{get; set;}
        public Boolean newCusTabSetting{get; set;}
        public Item__c item {get; set;}
        public Id itemId;
        public Boolean isHideResultsOnPageLoad {get; set;}  
        public static list<SObject> rlineslist;
        public Id defaultFacility{ get; set;}
        public Boolean tabView { get; set;} { tabView = true; }
        public Boolean errorOnPageLoad {get;set;}{errorOnPageLoad = false;}
        public string HelpURL{get;set;}
        public Map<String,Boolean> hasDetailMap = new Map<String, Boolean>();
        public Map<String,Boolean> hasHeaderMap = new Map<String, Boolean>();
        public class ManageItemExtException extends Exception{}

        
        //public List<string> tabs = null;
                
    
        public ManageItemExt(ApexPages.StandardController controller) {
           
            isHideResultsOnPageLoad = true;
            HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpItems';
            con = controller;
            initialisedcs = false;
            newCusTabSetting = false;
            itemId = controller.getId();
            
            if(itemId != null ){
            	item = (Item__c) controller.getRecord();
                
                //Query for all fields:
                
                item = queryitemRec(itemId);
                          
                if(Apexpages.currentPage().getParameters().get('clone') == '1'){
                 	
                 	item.Name = null;
                 	item.Id = null;
                    item.ExtId__c = null;
                 	item.Company_Item_Unique__c = null;
                 	controller.getRecord().Id = null;
                 	itemId = null;
                }
                
            }
            else{
            	item = new Item__c();
            	
            	List<User_Preference__c> u = [select id, Default_Company__c,Default_Company__r.Name from User_Preference__c where ownerId = :UserInfo.getUserID() limit 1];	
		        if (u.size() > 0){
			        if (u[0].Default_Company__c != null){
			        	item.Company__c = u[0].Default_Company__c;
			        	item.Company__r = u[0].Default_Company__r;
			        }
		        }
            	
            	item.Source__c = KSE.getDefaultPickListValue('Item__c', 'Source__c');
            	item.Fulfillment_Source__c = KSE.getDefaultPickListValue('Item__c', 'Fulfillment_Source__c');
            	item.ABC_Code__c = KSE.getDefaultPickListValue('Item__c', 'ABC_Code__c');
            	item.Active__c = true;
            }
            
        }
        
        public static Item__c queryitemRec(Id recId){
        	
        		Set<String> fieldsetNames = new Set<String>();
        		fieldsetNames.add('Item_Header');
                
	            for(Custom_Tab_Settings__c cs:[SELECT Tab_Name__c,Header_Field_Set_Name__c, Header_Read_Only_Field_Set_Name__c FROM Custom_Tab_Settings__c where Object_API_Name__c = 'Item__c' order by sequence__c asc]){
	                if(cs.Header_Field_Set_Name__c != null)
	                	fieldsetNames.add(cs.Header_Field_Set_Name__c);
	                
	            }
        		
        		set<String> fieldStrings = new set<string>{ 'ID','Dimension_UOM__r.Name','Non_Inventory__c','Class__r.Name', 'Class__r.Id', 'Packaging_UOM__c'};
                
                Item__c querieditem =  Database.query( Schemautil.getInstance().generateQueryFromFieldSet( 'Item__c', fieldsetNames, fieldStrings, 'Id =:recId limit 1' ) ); 
                return querieditem;
        	
        }
        
        
    @RemoteAction
    global static string getPkgUOMNames(Item__c itemRec, List<String> headerDateFields){
    	String pkgNames='';
    	return pkgNames;
    }
    
        
    @RemoteAction

    global static string getPackagingUOMNames(String packagingUOMs){


		Set<Id> pkgUOMList = (Set<Id>) JSON.deserialize(packagingUOMs, Set<Id>.class);
        String uomNames; 
        
        SOQLUtil soql = new SOQLUtil('UOM__c');
        soql.addFields(new Set<String>{'Name'});
        soql.setWhereClause('Id IN:pkgUOMList ');

        Map<Id,UOM__c> uoms = new map<Id,UOM__c>((List<UOM__c>)database.query(soql.getQuery()));
        
        for(Id uomId: pkgUOMList){
        	
        	UOM__c rec = uoms.get(uomId);
        	
            if(String.isBlank(uomNames) && rec.Name !=''){
            	uomNames = rec.Name; 
            }
            else
            	uomNames = uomNames +','+rec.Name;   
            
        }
        uomNames = JSON.serialize(uomNames);
        return uomNames;
           
    } 
        
        public list<string> createCustomSettingData(){
        	
        	List<Custom_Tab_Settings__c> csTabSettings= new List<Custom_Tab_Settings__c>();
        	List<String> tabNames = new List<String>{'Inventory','Purchasing','Order Management','Specification','Planning', 'Assign Facility'};
	        
		        for(String tab:tabNames){
		        	
			        	Custom_Tab_Settings__c cs = new Custom_Tab_Settings__c();
			        	cs.Name = tab+'tab';
			        	if(tab == 'Inventory'){
			        		cs.Tab_Name__c = tab;
			        		cs.Sequence__c = 1;
				       		cs.Object_API_Name__c = 'Item__c';
				       		cs.Header_Field_Set_Object_API_Name__c = 'Item__c';
				       		cs.Header_Field_Set_Name__c = 'Inventory';
				       		csTabSettings.add(cs);
			        	}
			        	if(tab == 'Purchasing'){
			        		cs.Tab_Name__c = tab;
			        		cs.Sequence__c = 2;
				       		cs.Object_API_Name__c = 'Item__c';
				       		cs.Header_Field_Set_Object_API_Name__c = 'Item__c';
				       		cs.Header_Field_Set_Name__c = 'Purchasing';
				       		csTabSettings.add(cs);
			        	}
			        	if(tab == 'Order Management'){
			        		cs.Tab_Name__c = tab;
			        		cs.Sequence__c = 3;
				       		cs.Object_API_Name__c = 'Item__c';
				       		cs.Header_Field_Set_Object_API_Name__c = 'Item__c';
				       		cs.Header_Field_Set_Name__c = 'OrderDetail';
				       		cs.Detail_Field_Set_Object_API_Name__c = 'Product__c';
				       		cs.Detail_Field_Set_Name__c = 'Create_Product';
				       		csTabSettings.add(cs);
			        	}
			        	if(tab == 'Specification'){
			        		cs.Tab_Name__c = tab;
			        		cs.Sequence__c = 4;
				       		cs.Object_API_Name__c = 'Item__c';
				       		cs.Header_Field_Set_Object_API_Name__c = 'Item__c';
				       		cs.Header_Field_Set_Name__c = 'ItemSpec_Header';
				       		cs.Detail_Field_Set_Object_API_Name__c = 'Item_Specification__c';
				       		cs.Detail_Field_Set_Name__c = 'Create_ItemSpec';
				       		csTabSettings.add(cs);
			        	}
			        	if(tab == 'Planning'){
			        		cs.Tab_Name__c = tab;
			        		cs.Sequence__c = 5;
				       		cs.Object_API_Name__c = 'Item__c';
				       		cs.Header_Field_Set_Object_API_Name__c = 'Item__c';
				       		cs.Header_Field_Set_Name__c = 'Planning';
				       		csTabSettings.add(cs);
			        	}
			        	if(tab == 'Assign Facility'){
			        		cs.Tab_Name__c = tab;
			        		cs.Sequence__c = 6;
				       		cs.Object_API_Name__c = 'Item__c';
				       		cs.Detail_Field_Set_Object_API_Name__c = 'Facility_Item__c';
				       		cs.Detail_Field_Set_Name__c = 'Assign_Facility';
				       		csTabSettings.add(cs);
			        	}
		       		
		        } 
    			DML.insertAsUser(csTabSettings);
    			initialisedcs = true;
    			newCusTabSetting = true;
    			return tabNames;
    		
        }
        
        public string getitemDetailJson() {
            return JSON.serialize(item);  
        }
        
        public list<string> gettabs() {
            list<String> tabs = new list<String>();
                
            for(Custom_Tab_Settings__c cs:[SELECT Tab_Name__c,Detail_Field_Set_Name__c FROM Custom_Tab_Settings__c where Object_API_Name__c = 'Item__c' order by sequence__c asc]){
                
                tabs.add(cs.Tab_Name__c);
                
            }

            return tabs;
            
        }
        
        public Pagereference tabsexists() {
            list<String> tabslist = new list<String>();
            PageReference pageRef;
            String vfPage;
	        if(!initialisedcs){
	        	   
	        	vfPage = Apexpages.currentPage().getUrl().substring(0,Apexpages.currentPage().getUrl().lastIndexOf('?')); 
	            for(Custom_Tab_Settings__c cs:[SELECT Tab_Name__c,Detail_Field_Set_Name__c FROM Custom_Tab_Settings__c where Object_API_Name__c = 'Item__c' order by sequence__c asc]){
	                
	                tabslist.add(cs.Tab_Name__c);
	                
	            }
				if(tabslist.size() == 0){
					createCustomSettingData();
					string retURL;
					if (item != null && item.id != null ){
		            	
    					pageRef = new PageReference(vfPage);
						pageRef.getParameters().put('Id',item.Id);
			        }
			        else{
			            pageRef = new PageReference(vfPage);
			        }
				}
				else{
					initialisedcs = true;
				}
				
	        }
	        
	        
	        if(newCusTabSetting)
	        	return pageRef.setRedirect(true);
	        else
	        	return null;
	        
        }
        
        public String getReturnUrl(){
	        PageReference pageRef;
	        
	        if (item != null && item.Id != null ){
	            pageRef =  new PageReference('/' + item.Id);
	        }
	        else{
	            Schema.DescribeSObjectResult dsr = Item__c.SObjectType.getDescribe();
	            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
	        }
	        
	        return pageRef.getUrl();
       }
        
        
        public Map<String, Boolean> gethasDetailMap() {
            
            for(Custom_Tab_Settings__c cs:[SELECT Tab_Name__c,Detail_Field_Set_Name__c, Detail_Field_Set_Object_API_Name__c FROM Custom_Tab_Settings__c where Object_API_Name__c = 'Item__c' order by sequence__c asc]){
                if(cs.Detail_Field_Set_Name__c != null && cs.Detail_Field_Set_Object_API_Name__c != null)
                    hasDetailMap.put(cs.Tab_Name__c,true);
                else
                    hasDetailMap.put(cs.Tab_Name__c,false);
            }
            
            return hasDetailMap;
        }
        
        public Map<String, Boolean> gethasHeaderMap() {
            
            for(Custom_Tab_Settings__c cs:[SELECT Tab_Name__c,Header_Field_Set_Name__c, Header_Field_Set_Object_API_Name__c FROM Custom_Tab_Settings__c where Object_API_Name__c = 'Item__c' order by sequence__c asc]){
                if(cs.Header_Field_Set_Name__c != null && cs.Header_Field_Set_Object_API_Name__c != null)
                    hasHeaderMap.put(cs.Tab_Name__c,true);
                else
                    hasHeaderMap.put(cs.Tab_Name__c,false);
            }
            
            return hasHeaderMap;
        }
        
        public string getitemHeaderFieldList() {
            
            String itemHeaderFieldList = '';
            FieldInfo fieldInfoItem;
            Set<String> readOnlyFields = new Set<String>();
            
            // get the header field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('item__c', 'item_header');
            
            fieldInfoList.remove(0); // Remove Id field from the list
            
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                
                if(fieldInfoList[i].field == 'Source__c'){
                	
                	fieldInfoList[i].selectList.remove(0);
                }
                
            }
                
            itemHeaderFieldList = JSON.serialize(fieldInfoList);
            
            return itemHeaderFieldList;
        }
        
        public string getitemHeaderROFieldList() {
            
            String itemHeaderFieldList = '';
            FieldInfo fieldInfoItem;
            Set<String> readOnlyFields = new Set<String>();
            
            // get the asn header field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('item__c', 'item_header');
            
            fieldInfoList.remove(0); // Remove Id field from the list
            
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                
                fieldInfoList[i].editable = false;
            }
                
            itemHeaderFieldList = JSON.serialize(fieldInfoList);
            
            return itemHeaderFieldList;
        }
        
        @RemoteAction 
        global static Map<String, String> getGridConfig(String tab){
            Map<String, String> configMap = new Map<String, String>();
            GridRelatedListController.GridRelatedListConfig gridLinesConfig = new GridRelatedListController.GridRelatedListConfig();
            String gridLinesConfigJson = '';
            
            for(Custom_Tab_Settings__c cs:Custom_Tab_Settings__c.getAll().values()){
                if(cs.Tab_Name__c == tab){
                    gridLinesConfig.uniqueId = cs.Tab_Name__c+'Grid';
                    gridLinesConfig.objectName = cs.Detail_Field_Set_Object_API_Name__c;
                    gridLinesConfig.fieldset = cs.Detail_Field_Set_Name__c;
                    gridLinesConfig.buttons = 'create, save, delete, search';        
                    
                }
            }
            gridLinesConfigJson = JSON.serialize(gridLinesConfig);
            
            configMap.put('config', gridLinesConfigJson);
        
            return configMap;
            
        }
        
        @RemoteAction
        global static JsonResult saveGridLines(List<SObject> updatedList, List<SObject> newList, List<SObject> deletedList, List<String> dateFields) {
	        
			
	        if (updatedList.size() > 0 && dateFields.size()>0) {
	            for (SObject line : updatedList) {
	                KendoUtils.UpdateDateFields(line, dateFields);
	            }
	        }
	        
	        if (newList.size() > 0 && dateFields.size()>0) {
	            for (SObject line : newList) {
	                KendoUtils.UpdateDateFields(line, dateFields);
	            }
	        }
	        
	        JsonResult result = new JsonResult();
	        Savepoint sp = Database.setSavepoint();
	        list<SObject> records = new list<SObject>();        
	
	        try {
	        	    
	            
	            List<SObject> insertobjLines = new List<SObject>();
	            List<SObject> updateobjLines = new List<SObject>();
	            
	            for (SObject line : newList) {
	                insertobjLines.add(line);
	            }
	            
	            for (SObject line : updatedList) {
	                updateobjLines.add(line);
	            }
	            
	            try{
		            if(insertobjLines.size()>0){
		           		insert insertobjLines;
		           		result.records = insertobjLines;
		           		
		            }
	            }
	            catch(DMLException dmlex){
	            	checkupsertErrors(dmlex, insertobjLines);
	            	
	            }
	            try{
	            	if(updateobjLines.size()>0){
		           		update updateobjLines;
		           		result.records = updateobjLines;
		            }
	            	
	            }
	            catch(DMLException dmle){
	            	checkupsertErrors(dmle, updateobjLines);
	            }
	            
	           
	            if (deletedList.size() > 0) {
        	    	//delete grid lines;
                	delete deletedList;
            	}
	            
	            
	        }
	        catch (Exception e) {
	            Database.rollback(sp);
	            result.success = false;
	            result.addMessage('An Error occurred : ' + e.getMessage() , ApexPages.Severity.ERROR);
	            
	        }
	        if(result.success)
				result.addMessage('Your changes have been saved successfully', ApexPages.Severity.CONFIRM);
	        return result;
	    }
	    
	    public static void checkupsertErrors(DMLException dmlex, List<SObject> objLines){
	    		
	    		if( dmlex.getMessage().contains('DUPLICATE_VALUE')){ 
	        		if(dmlex.getDmlMessage(0).contains('Item_Revision__c') || dmlex.getDmlMessage(0).contains('Unique_Costing_Start_Date__c')){
	        			throw new ManageItemExtException('A duplicate Item Specification has been found:'+ 'Revision : '+objLines[dmlex.getDmlIndex(0)].get('Revision__c')+', Start Date : '+objLines[dmlex.getDmlIndex(0)].get('Start_Date2__c'));
	           			
	        		}
	        		else if(dmlex.getDmlMessage(0).contains('Facility_Item_Unique__c')){
	        			throw new ManageItemExtException('The Facility Item already exists:'+ 'Facility : '+objLines[dmlex.getDmlIndex(0)].getSObject('Facility__r').get('Name')+', Item : '+objLines[dmlex.getDmlIndex(0)].get('Name'));
	                }
	                else if(dmlex.getDmlMessage(0).contains('Product_Unique__c')){
	        			throw new ManageItemExtException('Product already exists for this item:'+ 'Product : '+objLines[dmlex.getDmlIndex(0)].get('Name') +'. Please delete one of the records and save again.');
	            	
	        		}
	        		else if(dmlex.getDmlMessage(0).contains('Company_Item_Unique__c')){
	        			throw new ManageItemExtException('Company/Item already exists:'+ 'Company : '+objLines[dmlex.getDmlIndex(0)].getSObject('Company__r').get('Name')+', Item : '+objLines[dmlex.getDmlIndex(0)].get('Name'));
			                
	        		}
	                else{
	                		throw new ManageItemExtException(dmlex.getDMLMessage(0));
	                }
	    		}
	    		else{
						throw new ManageItemExtException(dmlex.getDMLMessage(0));
	    		}
	                
	    	
	    }
	    
	    public static void checkUOMErrors(List<String>packagingUOMList,Item__c itemRec){
	    	//Collect all the levels and packaging class
	    	
            Set<String> PkgUOMIds = new Set<String>(packagingUOMList);
            Set<Id> uomIds = new Set<Id>();
	        
	        SOQLUtil uomQuery = new SOQLUtil('Uom__c', true);
            uomQuery.addFields(new set<string>{
	            'id','name','package_class__c','package_class__r.Level__c','package_class__r.parent_package_class__r.Name','package_class__r.parent_package_class__c'
	        });
	        uomQuery.setWhereClause('(id in:PkgUOMIds)');
	        uomQuery.setOrderBy(new map<string,soqlutil.SortOrder>{'package_class__r.Level__c'=>soqlutil.SortOrder.SORTASC});
	        Map<id,Uom__c> uomsMap = new Map<id,Uom__c>((List<Uom__c>)Database.query(uomQuery.getQuery()));
	        
            if(uomsMap != null){
	        	uomIds.addall(uomsMap.keyset());
	        }
	        if(uomIds !=null && !uomIds.contains(itemRec.Stocking_UOM__c)){
	        	throw new ManageItemExtException('Stocking UOM need to be part of Packaging UOMs on the item.');
	        }
	        Set<Id> pkgIds = new Set<Id>();
            
            Map<Id,Id> uomToClassMap = new Map<Id,Id>();//UOM Id to Package/Parent Pkg Class
            Map<String,Set<Id>> uomPkgIdsmap = new Map<String,Set<Id>>();
            Map<Decimal,Id> uomLevelmap = new Map<Decimal,Id>();
            Map<Id,Package_Class__c> uompkgmap = new Map<Id,Package_Class__c>();
            
            SOQLUtil pkgQuery = new SOQLUtil('Package_Class__c', true);
            pkgQuery.addAllCustomFields();
            pkgQuery.addFields(new Set<String>{'Parent_Package_Class__r.Name','Parent_Package_Class__r.Level__c',
            									'Parent_Package_Class__r.Default_Container_Item__c','Parent_Package_Class__r.Parent_Package_Class__r.Name'});
            
            Map<Id,Package_Class__c> pkgclassmap= new Map<Id,Package_Class__c>((List<Package_Class__c>)Database.query(pkgQuery.getQuery()));
            Map<Id,Id> parentPkgClassmap = new Map<Id,Id>();
            Set<Id> withoutPkgClassUOMIds = new Set<Id>();
            for(Package_Class__c cl:pkgclassmap.values()){
            	if(!parentPkgClassmap.containskey(cl.Id)){
            		parentPkgClassmap.put(cl.Id,cl.Parent_Package_Class__c);
            	}
            }
            
            for(Uom__c uomObj:uomsMap.values()){
            	Decimal Level;
            	
            	if(uomObj.package_class__r !=null)
            		Level = uomObj.package_class__r.level__c;
            	else
            		Level = 1;
            	
            	if(uomObj.package_class__r !=null && !uomLevelmap.containskey(Level)){
            		uomLevelmap.put(uomObj.package_class__r.level__c,uomObj.Id);
            	}
            	else if(uomObj.package_class__r == null && !uomLevelmap.containskey(Level)){
            		uomLevelmap.put(Level,uomObj.Id);//Level considered 1 if no Pkg Class defined
            		withoutPkgClassUOMIds.add(uomObj.Id);
            	}
            	else if(uomLevelmap.containskey(Level)){
            		throw new ManageItemExtException('You cannot specify UOMs on the same level.');
            	}
            	if(uomPkgIdsmap.values().size() == 0 && uomObj.package_class__c !=null){
            		
            		if(!uomPkgIdsmap.containskey('Hierarchy')){
	            		uomPkgIdsmap.put('Hierarchy',new Set<Id>());
	            	}
	            	
	            	uomPkgIdsmap.get('Hierarchy').add(uomObj.package_class__c);
	            		
            		Id parentPkgClassId;
            		if(uomObj.package_class__r !=null && uomObj.package_class__r.parent_package_class__c !=null){
            			parentPkgClassId = uomObj.package_class__r.parent_package_class__c;
            			uomPkgIdsmap.get('Hierarchy').add(uomObj.package_class__r.parent_package_class__c);
            		}
            			
            		
            		if(parentPkgClassId !=null && parentPkgClassmap.containskey(parentPkgClassId) && parentPkgClassmap.get(parentPkgClassId) !=null){
	            		uomPkgIdsmap.get('Hierarchy').add(parentPkgClassmap.get(uomObj.package_class__r.parent_package_class__c));
	            		parentPkgClassId = parentPkgClassmap.get(uomObj.package_class__r.parent_package_class__c);
	            	}
            		
            		while(parentPkgClassId !=null){
            			if(parentPkgClassmap.containskey(parentPkgClassId) && parentPkgClassmap.get(parentPkgClassId) != null){
	            			if(parentPkgClassId != parentPkgClassmap.get(parentPkgClassId) && !uomPkgIdsmap.get('Hierarchy').contains(parentPkgClassmap.get(parentPkgClassId))){
	            				uomPkgIdsmap.get('Hierarchy').add(parentPkgClassmap.get(parentPkgClassId));
	            				parentPkgClassId = parentPkgClassmap.get(parentPkgClassId);	
	            			}
	            			else{
	            				parentPkgClassId = null;
	            			}
	            			
	            		}
	            		else if(parentPkgClassmap.containskey(parentPkgClassId) && parentPkgClassmap.get(parentPkgClassId)==null){
	            			parentPkgClassId = null;
	            		}
	            		else if(!parentPkgClassmap.containskey(parentPkgClassId)){
	            			parentPkgClassId = null;
	            		}
            	    }
            	}
            	else {
            		Set<Id> packageSet = new Set<Id>();
            		if(uomPkgIdsmap.containskey('Hierarchy'))
            			packageSet = uomPkgIdsmap.get('Hierarchy');
            		
            		if(uomObj.package_class__c != null && (!packageSet.contains(uomObj.package_class__c) || withoutPkgClassUOMIds.size()>0)){
            			throw new ManageItemExtException('All the UOM need to belong to same Package Class Hierarchy.');
            		}
            	}
            	
            	
            }
            
            
	    }
        	
        
        @RemoteAction
        global static Map<string,list<string>> getTabsFieldList(Boolean readOnlyflag) {
            //Map<String, String> itemFieldSetmap = new Map<String, String>();
            Map<String, list<String>> itemFieldSetmap = new Map<String, list<String>>();
            String purchasingFieldList = '';
            String planningFieldList = '';
            String inventoryFieldList = '';
            String orderdetailFieldList = '';
            FieldInfo fieldInfoItem, fieldInfoItem1, fieldInfoItem2;
            List<Custom_Tab_Settings__c> tabsettingslist = new List<Custom_Tab_Settings__c>();
            Map<string,Custom_Tab_Settings__c> fieldsetinfomap = new Map<string,Custom_Tab_Settings__c>();
            
            for( Custom_Tab_Settings__c t : Custom_Tab_Settings__c.getAll().values() ){
                if(t.Object_API_Name__c == 'Item__c'){
                   fieldsetinfomap.put(t.Tab_Name__c, t);
                   
                }
            }
            itemFieldSetmap = getAllFieldList(fieldsetinfomap, readOnlyflag);
            
            return itemFieldSetmap;
            
        }
        
         
        public static Map<string,list<string>> getAllFieldList(Map<String,Custom_Tab_Settings__c> FieldObjMap, Boolean readOnlyflag) {
            
            
            Map<String, list<String>> itemFieldSetmap = new Map<String, list<String>>();
            
            for(String tab: FieldObjMap.keyset()){
                String tabHeaderFieldList='';
                String tabdetailFieldList='';
                List<String>tabDetailList = new List<String>();
                List<String> tabHeaderList = new List<String>();
                
                if(FieldObjMap.containskey(tab)){
                    Custom_Tab_Settings__c cus = FieldObjMap.get(tab);
                    Set<String> readOnlyFields = new Set<String>();
                    if(cus.Header_Field_Set_Name__c !=null && cus.Header_Field_Set_Object_API_Name__c !=null){
                    	if(cus.Header_Read_Only_Field_Set_Name__c != null){
                    		List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos(cus.Header_Field_Set_Object_API_Name__c, cus.Header_Read_Only_Field_Set_Name__c);
					        for (Integer i = 0; i<fieldInfoListRO.size(); i++){
					            readOnlyFields.add(fieldInfoListRO[i].field);
					        }	
                    	}
                    	
                    	 
                    	List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(cus.Header_Field_Set_Object_API_Name__c, cus.Header_Field_Set_Name__c);
                    	
	                    fieldInfoList.remove(0); // Remove Id field from the list
	                    
	                    for(Integer i = 0; i < fieldInfoList.size(); i++) {
	                    	
	                        if(readOnlyflag == true || readOnlyFields.contains(fieldInfoList[i].field))
	                        	fieldInfoList[i].editable = false;
	                        
	                    }
	                    
	                    tabheaderFieldList = JSON.serialize(fieldInfoList);
	                    tabDetailList.add(tabheaderFieldList);
                    }
                   
                    if(tabDetailList.size()>0) 
                    	itemFieldSetmap.put(cus.Tab_Name__c, tabDetailList);
                    
                    if(cus.Detail_Field_Set_Name__c !=null && cus.Detail_Field_Set_Object_API_Name__c !=null){
                        
                        List<FieldInfo> fieldInfoList1 = FieldInfo.fetchJsonFieldInfos(cus.Detail_Field_Set_Object_API_Name__c, cus.Detail_Field_Set_Name__c,null);
                
                        fieldInfoList1.remove(0); // Remove Id field from the list
                        
                        for(Integer i = 0; i < fieldInfoList1.size(); i++) {
                           	
                           	 if(readOnlyflag == true)
	                        	fieldInfoList1[i].editable = false;
	                         
                        }
                        tabdetailFieldList = JSON.serialize(fieldInfoList1);
                        tabDetailList.add(tabdetailFieldList);
                        if(tabDetailList.size() >1)
                        	itemFieldSetmap.put(cus.Tab_Name__c, tabDetailList);
                        else
                        	itemFieldSetmap.put(cus.Tab_Name__c, new List<string>{' ', tabdetailFieldList});
                   } 
                   		
                 }  
            }
            
            return itemFieldSetmap;         
            
        }
        
        @RemoteAction
        global static Jsonresult saveItemChanges(Item__c itemRec, List<String> headerDateFields){
        	Savepoint sp1 = Database.setSavepoint();
        	JsonResult result = new JsonResult();
        	list<SObject> records = new list<SObject>();
        	list<SObject> insertlist = new list<SObject>();
        	list<SObject> updatelist = new list<SObject>();
        	List<SObject> updateditemList = new List<SObject>();
        	KendoUtils.UpdateDateFields(itemRec, headerDateFields);
        	List<String> packagingUOMList = new List<String>();
        	if(itemRec.Packaging_UOM__c != null)
        		packagingUOMList = (List<String>) JSON.deserialize(itemRec.Packaging_UOM__c, List<String>.class);
        	
        	try{
        		if(packagingUOMList.size()>0)
        			checkUOMErrors(packagingUOMList,itemRec);
        		if(itemRec.Id != null){
        			try{
        				updatelist.add(itemRec);
            			update updatelist;
            			result.records = updatelist;
        			}
        			catch(DMLException dmlex){
		            	checkupsertErrors(dmlex, updatelist);
	            	}
            		
	            }
	            else{
	            	try{
	            		insertlist.add(itemRec);
	            		insert insertlist;
	            		
	            		Item__c qitem = (Item__c)queryitemRec(itemRec.Id);
	            		updateditemList.add(qitem);
	            		
	            		result.records = updateditemList;
	            	}
	            	catch(DMLException dmlex){
	            		
		            	checkupsertErrors(dmlex, insertlist);
		            	
	            	}
	            	
	            }
	            
        	}
        	catch(Exception e){
	        	Database.rollback(sp1);
	            result.success = false;
	            if( result.reason != 'ERROR') result.reason = 'FATAL_ERROR';
	            	result.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        	}
            
            if(result.success)
	            result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
            
            return result;
        }
        
        
        
        @RemoteAction
        global static JsonResult getGridLines(String config, Id itemId) { 
            String sobjectName, fieldsetName;
            JsonResult result = new JsonResult();
            String whereClause = '';
            whereClause = 'Item__c != null and Item__c =:itemId';
            
            GridRelatedListController.GridRelatedListConfig gridLinesConfig = (GridRelatedListController.GridRelatedListConfig)JSON.deserialize(config, GridRelatedListController.GridRelatedListConfig.class);
            fieldsetName = gridLinesConfig.fieldset;
            sobjectName = gridLinesConfig.objectName;
            
            Set<String> additionalFields = new set<string>{'Id', 'Name'};
            String query = util.generateQueryFromFieldSet(sobjectName, new Set<string>{ fieldsetName },additionalFields, whereClause);
            rlineslist = Database.query( query );
            result.records = rlineslist; 
            result.total = rlineslist.size();   
            
            return result;
        
        }
    
}