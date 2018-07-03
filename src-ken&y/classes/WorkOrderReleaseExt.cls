public with sharing class WorkOrderReleaseExt extends BaseController{

    private ApexPages.StandardController con;
    public String namespaceUU { get; set; } { namespaceUU = KSE.NamespaceUU; }
    public static Work_Order__c worder { get; set; }
    public String worderJson { get; set; }
    public String materialConfigJson { get; set; }
    public String materialFieldListJson { get; set; }
    public String componentTitle { get; set; }
    public String poConfigJson { get; set; }
    public String poFieldListJson { get; set; }
    public String poTitle { get; set; }
    public static Map<String,Routing__c> routingmap = new Map<String,Routing__c>();
    public WorkOrderReleaseExt(ApexPages.StandardController controller) {
        con = controller;
        Id itemSpecId;
        worder = (Work_Order__c)controller.getrecord();
        
        worderJson = JSON.serialize(worder);
        GridRelatedListController.GridRelatedListConfig materialConfig = new GridRelatedListController.GridRelatedListConfig();
        materialConfig.uniqueId = 'materialGrid';
        
        List<FieldInfo> materialFieldList;
        componentTitle = 'Material';
        materialConfig.objectName = 'Material_Tracking__c';
        materialConfig.parentField = 'Work_Order__c';
        materialConfig.title = componentTitle;
        materialConfig.parentRecord = worder;
        materialConfig.alwaysUseFullDateTimeFormat = false;
        materialConfigJson = JSON.serialize(materialConfig);
        
        materialFieldList = FieldInfo.fetchJsonFieldInfos('Material_Tracking__c',new List<String>{ 'Item__c','Supplier__c','Work_Order__r.Order_Quantity__c','Quantity_Required__c','Operation_Tracking__c' }); 
        
        
        for (FieldInfo fi:materialFieldList) {
        	
            fi.editable = false;
            fi.field = 'rec.' + fi.field;
            if (fi.field.toLowerCase() == 'rec.quantity_required__c') {
                fi.editable = true;
            }
            
        }
        FieldInfo fieldInfoItem = new FieldInfo('rec.Routing__c', 'Routing', 'reference');
        fieldInfoItem.referenceTo = 'Routing__c';
        fieldInfoItem.editable = false;
        materialFieldList.add(fieldInfoItem);
        
        FieldInfo fieldInfoItem1 = new FieldInfo('Purchase_Order__c', 'Purchase Order', 'reference');
        fieldInfoItem1.referenceTo = 'Purchase_Order__c';
        fieldInfoItem1.editable = true;
        materialFieldList.add(fieldInfoItem1);
        
        
        for (FieldInfo fi:materialFieldList) {
            fi.required = false;
            if (fi.field.toLowerCase() == 'quantity_issued__c' || fi.field.toLowerCase() == 'quantity_short__c' || fi.field.toLowerCase() == 'quantity_used__c' || fi.field.toLowerCase() == 'quantity_scrapped__c') {
                fi.editable = false;
            }
        }
        
        materialFieldListJson = JSON.serialize(materialFieldList);
        
        GridRelatedListController.GridRelatedListConfig poConfig = new GridRelatedListController.GridRelatedListConfig();
        poConfig.uniqueId = 'poGrid';
        
        List<FieldInfo> poFieldList;
        poTitle = 'Purchase Orders';
        poConfig.objectName = 'Purchase_Order__c';
        poConfig.title = poTitle;
        poConfig.alwaysUseFullDateTimeFormat = false;
        poConfigJson = JSON.serialize(poConfig);
        
        poFieldList = FieldInfo.fetchJsonFieldInfos('Purchase_Order__c', 'SubContract_PO_Info');
        for (FieldInfo fi1:poFieldList) {
           	fi1.editable = false;
        }
        poFieldListJson = JSON.serialize(poFieldList);
        
    }
    
     public String getReturnUrl(){
        PageReference pageRef;
        
        if (worder != null && worder.Id != null ){
            pageRef =  new PageReference('/' + worder.Id);
        }
        else {
            Schema.DescribeSObjectResult dsr = Work_Order__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        }
        return pageRef.getUrl();
    }
    
    @RemoteAction 
    public static JsonResult getRecords(Id woId) {
        JsonResult result = new JsonResult();
        List<worderWrapper> worderwrappers = new List<worderWrapper>();
        try {
            
        SOQLUtil workOrderQuery = new SOQLUtil('Work_Order__c');
        workOrderQuery.addFields(new Set<String>{ 'Id','Name','Status__c','Assembly_Item_Specification__c', 'Item__c', 'Order_Quantity__c', 'Packaging_UOM__c', 
                                        'Assembly_Item_Specification__r.Packaging_UOM__c', 'Item__r.Packaging_UOM__c', 'Facility__r.Facility_Identifier__c',

                'Assembly_Item_Specification__r.Packaging_UOM__r.Package_Class__c', 'Assembly_Item_Specification__r.Packaging_UOM__r.Package_Class__r.Level__c',
                'Packaging_UOM__r.Package_Class__c', 'Packaging_UOM__r.Package_Class__r.Level__c' });
        workOrderQuery.setWhereClause('Id = :woId');
        
     	SOQLUtil.ChildRelationship mQuery = new SOQLUtil.ChildRelationship(workOrderQuery,'Material_Trackings__r');
        mQuery.addFields(new Set<String>{ 'Item__c','Quantity_Required__c','Quantity_Issued__c','Quantity_Completed__c','Work_Order__r.Status__c','Item__r.Source__c','Supplier__c','Quantity_Per_Assembly__c','Operation_Tracking__r.Name','Operation_Tracking__c','Operation_Tracking__r.Routing__c','Operation_Tracking__r.Routing__r.Id','Operation_Tracking__r.Routing__r.Name','Work_Order__r.Order_Quantity__c' });
        mQuery.addFields('ManageMaterialRelease');
        mQuery.setWhereClause('Item__r.Source__c = \'Outside Processing\'');
        workOrderQuery.addChildRelationship(mQuery);
		worder = Database.query(workOrderQuery.getQuery());
            
            Map<Id, List<Material_Tracking__c>> materialTrackings = new Map<Id, List<Material_Tracking__c>>();
            Map<Id, Purchase_Order__c> purchaseOrders = new Map<Id, Purchase_Order__c>();
            if (worder.Status__c == WorkOrderService.WO_STATUS_DRAFT && worder.Assembly_Item_Specification__c != null) {
                List<Id> pkgUoms = (List<Id>)JSON.deserialize(worder.Item__r.Packaging_UOM__c, List<Id>.Class);
                Decimal convFactor;
                if (worder.Packaging_UOM__r.Package_Class__r.Level__c > worder.Assembly_Item_Specification__r.Packaging_UOM__r.Package_Class__r.Level__c) {
                    convFactor = KSE.getConversionFactor(worder.Item__c, worder.Facility__r.Facility_Identifier__c, worder.Packaging_UOM__c, worder.Assembly_Item_Specification__r.Packaging_UOM__c, pkgUoms);
                } else {
                    convFactor = KSE.getConversionFactor(worder.Item__c, worder.Facility__r.Facility_Identifier__c, worder.Assembly_Item_Specification__r.Packaging_UOM__c, worder.Packaging_UOM__c, pkgUoms);
                }

                SOQLUtil componentQuery = new SOQLUtil('Component__c');
                componentQuery.addAllCustomFields();
                componentQuery.addAllCustomFields(Item__c.sObjectType,'Component_Item__r');
                componentQuery.setOrderByClause('Component_Item__r.Name');
                componentQuery.setWhereClause('Assembly_Item_Specification__c = \'' + worder.Assembly_Item_Specification__c + '\' AND Component_Item__r.Source__c = \'' + ItemService.ITEM_SOURCE_OSP + '\'');
                for (Component__c component:Database.query(componentQuery.getQuery())) {
                    Material_Tracking__c mt = new Material_Tracking__c(
                        Item__c = component.Component_Item__c,
                        Item__r = component.Component_Item__r,
                        Quantity_Issued__c = 0,
                        Type__c = component.Type__c,
                        Supplier__c = component.Supplier__c,
                        Supplier__r = component.Supplier__r,
                        Work_Order__c = woId,
                        Work_Order__r = worder,
                        Operation_Tracking__c = null,
                        Operation_Tracking__r = new Operation_Tracking__c(Hours_Consumed__c = 0, Quantity_Available__c = 0, Quantity_Scrapped__c = 0, Routing__c = component.Routing__c, Routing__r = component.Routing__r)
                    );
                    
                    if (worder.Packaging_UOM__r.Package_Class__r.Level__c > worder.Assembly_Item_Specification__r.Packaging_UOM__r.Package_Class__r.Level__c) {
                        mt.Quantity_Per_Assembly__c = component.Quantity_per_Assembly__c * convFactor;
                    } else {
                        mt.Quantity_Per_Assembly__c = component.Quantity_per_Assembly__c / convFactor;
                    }

                    if (materialTrackings.containsKey(component.Routing__c) == false) materialTrackings.put(component.Routing__c, new List<Material_Tracking__c>{ mt });
                    else materialTrackings.get(component.Routing__c).add(mt);
                }
            } else if (worder.Status__c != WorkOrderService.WO_STATUS_DRAFT) {
                Set<Id> mtIds = new Set<Id>();
                for (Material_Tracking__c mt:worder.Material_Trackings__r) {
                    mtIds.add(mt.Id);
                    if (materialTrackings.containsKey(mt.Operation_Tracking__c) == false) materialTrackings.put(mt.Operation_Tracking__c, new List<Material_Tracking__c>{ mt });
                    else materialTrackings.get(mt.Operation_Tracking__c).add(mt);
                }

                SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
                polQuery.addFields(new Set<String>{ 'Id', 'Name', 'Material_Tracking__c', 'Purchase_Order__c', 'Purchase_Order__r.Supplier__c' });
                polQuery.setWhereClause('Material_Tracking__c IN :mtIds and Status__c NOT IN (\'Cancelled\', \'Closed\')');
                for (Purchase_Order_Line__c pol:Database.query(polQuery.getQuery())) purchaseOrders.put(pol.Material_Tracking__c, pol.Purchase_Order__r);
            }

            for (Id opId:materialTrackings.keySet()) {
                for (Material_Tracking__c mt:materialTrackings.get(opId)) {
                    worderWrapper wrapper = new worderWrapper(mt);

                    if (materialTrackings.get(opId).size() == 1) {
                        wrapper.tempvalMap.put('readOnlyQty', 'true');
                        if (mt.Quantity_Required__c == null) mt.Quantity_Required__c = worder.Order_Quantity__c * mt.Quantity_Per_Assembly__c;
                    } else {
                        wrapper.tempvalMap.put('readOnlyQty', 'false');
                        if (mt.Quantity_Required__c == null) mt.Quantity_Required__c = 0;
                    }

                    if (purchaseOrders.containsKey(mt.Id) == true) {
                        Purchase_Order__c po = purchaseOrders.get(mt.Id);
                        wrapper.poRec = po;
                        wrapper.tempvalMap.put('poReadOnly', 'true');
                    }

                    worderwrappers.add(wrapper);
                }
            }
        
        if(worderwrappers.size()>0){
        	 
        	 result.records = worderwrappers;
        	 result.total = result.records.size();
        }
        
           
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    @RemoteAction
    public static JSONResult getPOList(Id supplierId){
    	JsonResult result = new JsonResult();
    	List<Purchase_Order__c> purchaseOrders = new List<Purchase_Order__c>();
        try {
            
	        SOQLUtil poQuery = new SOQLUtil('Purchase_Order__c');
	        poQuery.addFields(new Set<String>{ 'Id','Name','Status__c','Supplier__c', 'Currency__c', 'Company__c' });
	        poQuery.addFields('SubContract_PO_Info');
	        poQuery.setWhereClause('Supplier__c = :supplierId AND Type__c = \'SubContract\' AND Status__c NOT IN (\'Closed\', \'Cancelled\')');
	        
			purchaseOrders = Database.query(poQuery.getQuery());
			result.records = purchaseOrders;
        	result.total = result.records.size();
		
        }catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    @RemoteAction
    public static JSONResult releaseWO(Id workorderId) {
        Savepoint sp = Database.setSavepoint();
        JSONResult result = new JSONResult();
        
        try {
        	WorkOrderPlanningService.release(new Set<Id>{ workorderId });
        
        }catch(Exception e) {
        	Database.rollback(sp);
            String msg;
            if (e instanceof DMLException) {
                msg = e.getDmlMessage(0);
            } else {
                msg = e.getMessage();
            }
            result.success = false;
            result.addMessage(msg,ApexPages.Severity.ERROR);
	    }
	    
        return result;
    }
    
    @RemoteAction
    public static JSONResult release(List<worderWrapper> updatedrows, List<String> datefields, Work_Order__c worderObj,Boolean consolidateflag) {
        Savepoint sp = Database.setSavepoint();
        JSONResult result = new JSONResult();
        Map<String,Decimal> distributeQtymap = new Map<String,Decimal>();
        Map<String,Purchase_Order__c> mtPurchaseOrdermap = new Map<String,Purchase_Order__c>();
        Map<String,Decimal> qtymap = new Map<String,Decimal>();
        Map<String,SObject> sObjectmap = new Map<String,SObject>();
        Map<String,SObject> consolidateObjmap = new Map<String,SObject>();
        String errorNewRecs = '';
        Id woId;
        
        try {
        			
	        		woId = (Id)updatedrows[0].rec.get('Work_Order__c');
	        
		        	Map<String,Decimal> objQtymap = new Map<String,Decimal>();
		        	Decimal qtyrequired=0;
		        	
		        	Map<Id,Routing__c> itemRoutingmap = new Map<Id,Routing__c>();
		        	for(worderWrapper wrap:updatedrows){
		        		SObject obj = wrap.rec;
		        		String pokey;
		        		if(worderObj.Status__c == 'Draft'){
		        			Id routingId;
		        			String rkey;
		        			Routing__c routingObj;
		        			
		        			if(wrap.inputMap.containskey('Routing__c')){
		        				
		        				routingId =(String)wrap.inputMap.get('Routing__c').get('Id');
		        				routingObj = (Routing__c)wrap.inputMap.get('Routing__c');
		        			}
		        			String rtkey = (String)obj.get('Item__c')+(String)routingId;
		        			if(!qtymap.containskey(rtkey) && obj.get('Quantity_Required__c') !=null){
			        			qtymap.put(rtkey,(Decimal)obj.get('Quantity_Required__c'));
			        		}
			        		else if(qtymap.containskey(rtkey) && obj.get('Quantity_Required__c') !=null){
			        			qtyrequired = qtymap.get(rtkey) + (Decimal)obj.get('Quantity_Required__c');
			        		
			        			qtymap.put(rtkey,qtyrequired);
			        			
			        		}
			        		
			        		//If consolidate and save
			        		if(consolidateflag == true && wrap.tempvalMap.containskey('Selected')){
			        			consolidateObjmap.put(routingId+(String)obj.get('Supplier__c'),obj);
			        		}
		        			if(wrap.poRec !=null){
		        				pokey = routingId+(String)obj.get('Supplier__c');
		        				
		        				if(!mtPurchaseOrdermap.containskey(pokey)){
		        					mtPurchaseOrdermap.put(pokey,wrap.poRec);
		        				}
		        			}
			        		
			        		if(!sObjectmap.containskey(rtkey)){
		        			
			        			sObjectmap.put(rtkey,(Material_Tracking__c)obj);//Operation Tracking for relrelease...
			        			sObjectmap.get(rtkey).putSObject('Operation_Tracking__r',new Operation_Tracking__c(Routing__c = routingId, Routing__r =routingObj));
			        		}
			        		
			        		
			        		
		        		}
		        		else{
		        			String rkey = (String)obj.get('Item__c')+(String)obj.get('Operation_Tracking__c');
		        			
		        			if(!qtymap.containskey(rkey)){
			        			qtymap.put(rkey,(Decimal)obj.get('Quantity_Required__c'));
			        		}
			        		else{
			        			qtyrequired = qtymap.get(rkey) + (Decimal)obj.get('Quantity_Required__c');
			        		
			        			qtymap.put(rkey,qtyrequired);
			        		}
			        		if(!objQtymap.containskey((String)obj.get('Item__c')+(String)obj.get('Operation_Tracking__c'))){
			        			objQtymap.put((String)obj.get('Item__c')+(String)obj.get('Operation_Tracking__c'),(Decimal)obj.get('Quantity_per_Assembly__c'));
			        		}
			        		
			        		if(!sObjectmap.containskey(rkey) && (Id)obj.get('Operation_Tracking__c') != null){
		        			
			        			sObjectmap.put(rkey,(Operation_Tracking__c)obj.getSObject('Operation_Tracking__r'));//Operation Tracking for relrelease...
			        		}
			        		if(consolidateflag == true && wrap.tempvalMap.containskey('Selected')){
			        			consolidateObjmap.put((Id)obj.get('Operation_Tracking__c')+(String)obj.get('Supplier__c'),obj);
			        		}
			        		//ReRelease logic
			        		if(wrap.poRec !=null){
			        			pokey = (Id)obj.get('Operation_Tracking__c')+(String)obj.get('Supplier__c');
		        				if(!mtPurchaseOrdermap.containskey(pokey)){
		        					mtPurchaseOrdermap.put(pokey,wrap.poRec);
		        				}
		        			}
		        		}
		        		
		        		
		        		String key='';
		        		KendoUtils.UpdateDateFields(obj, dateFields);
		        		if(worderObj.Status__c == 'Draft'){
		        			
		        			key= String.valueof(wrap.inputMap.get('Routing__c').get('Id')) + String.valueof(obj.get('Supplier__c'));//getSObject('Operation_Tracking__r').
		        		}
		        		else if(worderObj.Status__c == 'In Process' || worderObj.Status__c == 'Released'){
		        			key= String.valueof(obj.get('Operation_Tracking__c')) + String.valueof(obj.get('Supplier__c'));
		        		}
		        		
		        		if(obj.get('Quantity_Required__c') !=null)
			            	distributeQtymap.put(key,(Decimal)obj.get('Quantity_Required__c'));
			            
		        	}
            WorkOrderPlanningService.release(new Set<Id>{ woId },distributeQtymap,qtymap,consolidateObjmap,mtPurchaseOrdermap);
        } catch (Exception e) {
	            String msg;
	            if (e instanceof DMLException) {
	                msg = e.getDmlMessage(0);
	            } else {
	                msg = e.getMessage();
	            }
	            result.success = false;
	            result.addMessage(msg,ApexPages.Severity.ERROR);
	            
	            Database.rollback(sp);
	        }
	        
        	return result; 
        }
        
        public class worderWrapper{
        
        public Map<String, SObject> inputMap = new Map<String, SObject>();
        public Map<String,String> tempvalMap = new Map<String,String>();
        public Purchase_Order__c poRec {get; set;}
        public SObject rec {get; set;}

        public worderWrapper(){
            this.rec = rec;
        }
        
        public worderWrapper(SObject rec){ 
        
            this.rec = rec;
            
        }
        
         public worderWrapper(SObject rec, Purchase_Order__c poline ){ 
        
            this.rec = rec;
            this.poRec = poRec;
            
        }

    }
       
}