public with sharing class WorkOrderNewExtV2 extends BaseController {

    public Boolean submitted { get; set; } { submitted = false; }
	public String namespaceUU { get; set; } { namespaceUU = KSE.namespaceUU; }
    public static Work_Order__c workOrder { get; set; }
   
    final String TYPE_REFERENCE = 'reference' ;
    
    
    private static SchemaUtil util = SchemaUtil.getInstance();
    
    public class WorkOrderNewExtV2Exception extends Exception { }

    public WorkOrderNewExtV2(ApexPages.StandardController con) {
        workOrder = (Work_Order__c)con.getRecord();
        
        if ( workOrder == null || workOrder.id == null ) {
            User_Preference__c up = UserPreference.getInstance().Preference;
            workOrder.Company__c = up.default_Company__c;
            workOrder.Facility__c = up.Default_Facility__c;
            workOrder.Status__c = 'Draft';
            workOrder.Type__c = 'Regular';
            Id companyId = workOrder.Company__c;
             if(workOrder.Facility__c != null){
                Id facilityId = workOrder.Facility__c;
    			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    			SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
    			soql.addFields(new set<string>{
    				'id','Name','Company__c','Company__r.Name','Company__r.Serial_Control__c','Default_Work_Order_WIP_Location__c','Default_Work_Order_WIP_Location__r.Name','Default_Work_Order_Complete_to_Location__c',
    				'Default_Work_Order_Complete_to_Location__r.Name','Default_Work_Order_MRB_Location__r.Name','Default_Work_Order_MRB_Location__c', 'Facility_Identifier__c'
    			});
    			soql.setWhereClause('Id=:facilityId');
    			List<Facility__c> facList = Database.query(soql.getQuery());
    
                if(facList.size() > 0){
                    workOrder.Facility__r = facList[0];
                    workOrder.Company__r = facList[0].Company__r;
                    workOrder.Complete_to_Location__c = facList[0].Default_Work_Order_Complete_to_Location__c;
                    if(workOrder.Complete_to_Location__c != null){
                       workOrder.Complete_to_Location__r = facList[0].Default_Work_Order_Complete_to_Location__r; 
                    }
                    workOrder.Default_WIP_Location__c = facList[0].Default_Work_Order_WIP_Location__c;
                    if(workOrder.Default_WIP_Location__c != null){
                     workOrder.Default_WIP_Location__r = facList[0].Default_Work_Order_WIP_Location__r;   
                    }
                    workOrder.MRB_Location__c = facList[0].Default_Work_Order_MRB_Location__c;
                    if(workOrder.MRB_Location__c != null){
                      workOrder.MRB_Location__r = facList[0].Default_Work_Order_MRB_Location__r;  
                    }
                    
                }
            } else if(workOrder.Company__c != null){
                
    			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    			SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
    			soql.addFields(new set<string>{
    				'id','Name', 'Serial_Control__c'
    			});
    			soql.setWhereClause('Id=:companyId');
    			List<Company__c> cmpList = Database.query(soql.getQuery());
    
                if(cmpList.size() > 0)
                    workOrder.Company__r = cmpList[0];
            }
        } else {
            SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
            woQuery.addFields(new Set<String>{ 'Id', 'Name', 'Facility__c', 'Item__c', 'Order_Quantity_Stocking_UOM__c', 'Packaging_UOM__c',
                'Quantity_Value_Holder__c', 'Status__c',

                'Facility__r.Facility_Identifier__c',

                'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c'
            });
            woQuery.addFields('New');
            woQuery.setWhereClause('Id = \'' + workOrder.Id + '\'');
            workOrder = Database.query(woQuery.getQuery());

            if (String.isBlank(workOrder.Quantity_Value_Holder__c) == true) {
                List<Id> pkgUoms = (List<Id>)JSON.deserialize(workOrder.Item__r.Packaging_UOM__c, List<Id>.Class);
                Boolean pkgUomFound = false;
                Map<Id, Decimal> qtyMap = new Map<Id, Decimal>();
                Decimal orderQty = workOrder.Order_Quantity_Stocking_UOM__c;
                for (Integer i = pkgUoms.size() - 1; i >= 0; i--) {
                    Id pkgUom = pkgUoms[i];
                    if (pkgUom != workOrder.Packaging_UOM__c && pkgUomFound == false) continue;
                    pkgUomFound = true;

                    Decimal convFactor = KSE.getConversionFactor(workOrder.Item__c, workOrder.Facility__r.Facility_Identifier__c, pkgUom, workOrder.Item__r.Stocking_UOM__c, pkgUoms);
                    qtyMap.put(pkgUom, Math.floor(orderQty / convfactor));
                    orderQty -= (qtyMap.get(pkgUom) * convFactor);
                }
                if (orderQty > 0) qtyMap.put(workOrder.Item__r.Stocking_UOM__c, qtyMap.get(workOrder.Item__r.Stocking_UOM__c) + orderQty);
                workOrder.Quantity_Value_Holder__c = JSON.serialize(qtyMap);
            }
            
            if (ApexPages.currentPage().getParameters().get('clone') == '1') {
                workOrder.Id = null;
                con.getRecord().Id = null;
                workOrder.Name = null;
                workOrder.ExtId__c = null;
                workOrder.Status__c = WorkOrderService.WO_STATUS_DRAFT;
            }
        }
    }
    
    public String getWorkOrderJson() {
        return JSON.serialize(workOrder);  
    }
    
    public String getWorkOrderHeaderFieldList() {
        List<Shipment_Line__c> shls = new List<Shipment_Line__c>();
        if (workOrder.Id != null) {
            SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
            shlQuery.addField('Id');
            shlQuery.setWhereClause('Work_Order__c = \'' + workOrder.Id + '\'');
            shls = Database.query(shlQuery.getQuery());
        }

        List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Work_Order__c', 'New', 'Status__c', false);
        fiList.remove(0);
        for (FieldInfo fi:fiList) {
            fi.editable = fi.field != 'Status__c' && (shls.size() == 0 || (fi.field != 'Facility__c' && fi.field != 'Assembly_Item_Specification__c' && fi.field != 'Item__c' && fi.field != 'Type__c'));
            if (fi.field == 'Type__c') fi.selectList.remove(0);
        }
        return JSON.serialize(fiList);
    }
    
    @RemoteAction
     public static integer calculateDates( Id itemSpecId) {
        
         integer leadTime = 0;
       
			SOQLUtil soql = new SOQLUtil('Item_Specification__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Item__c','Item__r.Lead_Time__c'
			});
			soql.setWhereClause('Id = :itemSpecId');
			soql.setLimit(1);
			
			Item_Specification__c itemSpec = Database.query(soql.getQuery());

            if (itemSpec.Item__r.Lead_Time__c != null) {
                leadTime = (Integer)itemSpec.Item__r.Lead_Time__c;
            }        
              
     
        return leadTime;
        
    }

    /**
	 * Get the search results on Sobject for the search term and returns
	 * the records with fields in the fielset defined. If the fieldset is
	 * blank then the result is comparative to (List<SelectListItem>) lookupSearchFilter()
	 * but returns the result in a map
	 */
    @RemoteAction
    public static List<Object> lookupSearchFilter2 ( String searchTerm, String objectName, String filterCriteria, String additionalFields) {
        SchemaUtil util = SchemaUtil.getInstance();
        List<Object> selectList = new List<Object>();

        if (String.isBlank(objectName))
        {
            return selectList;
        }

        Schema.SObjectType objectType = util.getGlobalDescribe(objectName);

        SOQLUtil soql = new SOQLUtil(objectName);
        soql.addFields(new set<string>{'Id', 'Name'});

        if ( String.isNotEmpty(additionalFields)) {
            soql.addFields(new Set<String>(additionalFields.split(',')));
        }

        String filterString = '';
        System.debug(LoggingLevel.INFO, '*** searchTerm: ' + searchTerm);
        if(String.isNotBlank(searchTerm)){
            filterString += 'Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'';

            if(searchTerm.length() <= 3) {
                soql.setLimit(100);
            }
        }else{
            soql.setLimit(100);
        }

        if(String.isNotBlank(filterCriteria)){
            if(filterString.trim().startsWith('Name')) {
                filterString += ' AND ' + filterCriteria;
            }
            else {
                filterString += filterCriteria;
            }
        }

        soql.setWhereClause(filterString);
        soql.setOrderByClause('Name');
        system.debug('query: ' + soql.getQuery());
        List<SObject> result = Database.query(soql.getQuery());

        // get fields for fieldset

        for (SObject obj : result) {
            String id = String.valueOf(obj.get('Id'));
            String name = String.valueOf(obj.get('Name'));
            Map<String, Object> selectListItem = new Map<String, Object>();
            selectListItem.put('value', id);
            selectListItem.put('text', name);
            Map<String, Object> selectItem = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
            selectListItem.put('sobjectMap', selectItem);
            selectList.add(selectListItem);
        }

        return selectList;
    }
    
     @RemoteAction 
    public static JsonResult getLocationDefaultsFromFacility(String facilityId) {
        List<Facility__c> facilityList = new List<Facility__c>();
        
        String whereClause = 'Id = :facilityId LIMIT 1';
        
        SOQLUtil soql = new SOQLUtil('Facility__c');
	    soql.addFields(new Set<String>{'id','Name','Company__c','Company__r.Name','Company__r.Serial_Control__c','Default_Work_Order_WIP_Location__c','Default_Work_Order_WIP_Location__r.Name',
	               'Default_Work_Order_Complete_to_Location__c','Default_Work_Order_Complete_to_Location__r.Name','Default_Work_Order_MRB_Location__r.Name','Default_Work_Order_MRB_Location__c',
	               'Facility_Identifier__c' });
	    soql.setWhereClause(whereClause);
        
        facilityList = Database.query(soql.getQuery());
        
        return new JsonResult(facilityList, facilityList.size());
    }
    
    // Get the packaging uom's configured for the item and default the packaging uom from the item spec
    @RemoteAction
    public static JsonResult getPackagingUomForItem ( Id assemblyItemSpec ) {
        SOQLUtil itemSpecQuery = new SOQLUtil ( 'Item_Specification__c', true);
        itemSpecQuery.addFields ( new Set<String> {
            'Id', 'Item__r.Packaging_UOM__c', 'Default_Work_Order_Packaging_UOM__c','Default_Work_Order_Packaging_UOM__r.Id', 'Default_Work_Order_Packaging_UOM__r.Name'
            });
        itemSpecQuery.setWhereClause ('Id = :assemblyItemSpec');
        Item_Specification__c itemSpec = Database.query ( itemSpecQuery.getQuery() );
        
        JsonResult res = new JsonResult();
        res.success = true;
        res.records = new List<String>();

        if ( String.isNotEmpty(itemSpec.Item__r.Packaging_UOM__c )) {
            List<String> pkgUoms = (List<String>) Json.deserialize(itemSpec.Item__r.Packaging_UOM__c, List<String>.class);
            SOQLUtil pkgUomQuery = new SOQLUtil('UOM__c', true );
            pkgUomQuery.addFields(new Set<String>{'Id','Name'});
            pkgUomQuery.setWhereClause('Id in :pkgUoms');
            pkgUomQuery.setOrderByClause('Package_Class__r.Level__c ASC');
            res.records = Database.query(pkgUomQuery.getQuery());
        }
        // Defaults the packaging UOM to item spec packaging UOM 
        res.additionalInfo = JSON.serialize( itemSpec.Default_Work_Order_Packaging_UOM__r );
        
        return res;
    }
    
    @RemoteAction
    public static JsonResult save ( Work_Order__c wOrder, List<String> headerDateFields){
        JsonResult result = new JsonResult();
       
        try{
            
            if (wOrder.Order_Quantity__c <= 0)
                throw new WorkOrderNewExtV2Exception(Label.Order_Quantity_cannot_be_negative_or_zero);
            
            if ( wOrder.Assembly_Item_Specification__c == null && wOrder.Type__c != 'Repair' )
                throw new WorkOrderNewExtV2Exception('Assembly Item Specification ' + Label.is_required);
             
            
            if (wOrder.Assembly_Item_Specification__c == null && wOrder.Type__c == 'Repair' && wOrder.Item__c == null)
                throw new WorkOrderNewExtV2Exception('Assembly Item Specification or Item ' + Label.is_required);

            if ( wOrder.Facility__c == null ) {
                throw new WorkOrderNewExtV2Exception('Facility '+ Label.is_required);
            }

            // KNDY-16989
            if ( String.isEmpty(wOrder.Packaging_UOM__c)  ) {
                throw new WorkOrderNewExtV2Exception ('Packaging UOM ' + Label.is_required );
            }
            
            if ( !(string.isblank(wOrder.Assembly_Item_Specification__c) )  ){
		       
		        SOQLUtil soql = new SOQLUtil('Item_Specification__c', true); //enforceFLS=true, running in user mode
		        soql.addFields(new set<string>{
			    'Id','Facility__c','Item__c', 'Type__c', 'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c'
		        });
		        soql.setWhereClause('Id = \'' + wOrder.Assembly_Item_Specification__c + '\'');
		        soql.setLimit(1);
		
		        Item_Specification__c itemSpec = Database.query(soql.getQuery());

                if ( String.isNotBlank(wOrder.Quantity_Value_Holder__c) ) {
                    soql = new SOQLUtil('Facility__c', true);
                    Id facilityId = wOrder.Facility__c;
                    soql.addFields( new Set<String> {'Id','Facility_Identifier__c'});
                    soql.setWhereClause('Id = :facilityId');
                    List<Facility__c> facility = Database.query(soql.getQuery());

                    List<String> pkgUoms = (List<String>) Json.deserialize(itemSpec.Item__r.Packaging_UOM__c, List<String>.class);
                    Map<String, Decimal> mapQuantity = (Map<String, Decimal>) JSON.deserialize(wOrder.Quantity_Value_Holder__c, Map<String, Decimal>.class);
                    Decimal orderQuantity = 0;
                    for ( String uom : pkgUoms){
                        if ( mapQuantity.containsKey(uom) && mapQuantity.get(uom)>0 ) {
                            orderQuantity = KSE.addQuantityToField(orderQuantity, mapQuantity.get(uom) / KSE.getConversionFactor(itemSpec.Item__c,facility[0].Facility_Identifier__c,wOrder.Packaging_UOM__c,uom, pkgUoms ) );
                        }
                    }
                    wOrder.Order_Quantity__c = orderQuantity;
                }

		        
		        if( wOrder.Type__c == 'Regular' && itemSpec.Type__c == 'Repair' ){
		             throw new WorkOrderNewExtV2Exception(Label.Cannot_use_repair_item_specifications_on_regular_work_orders);
                   
                }
                else if( wOrder.Type__c == 'Repair' && itemSpec.Type__c != 'Repair' ){
                    throw new WorkOrderNewExtV2Exception(Label.Only_repair_item_specifications_can_be_used_on_repair_work_orders);
                   
                }
		
		        soql = new SOQLUtil('Item_Specification__c', true); //enforceFLS=true, running in user mode
		        soql.addFields(new set<string>{
			    'Id','Facility__c'
		        });
		        soql.setWhereClause('Company__c = \'' + wOrder.Company__c + '\' AND Item__c = \''+ itemSpec.Item__c +'\' AND Production__c = true');

		        Map<Id,Item_Specification__c> itemSpecMap = new Map<Id,Item_Specification__c>((List<Item_Specification__c>)Database.query(soql.getQuery()));

                if (itemSpecMap.size() > 1) {
                    if (wOrder.Facility__c != null && wOrder.Facility__c != itemSpec.Facility__c) {
                        for (Item_Specification__c is:itemSpecMap.values()) {
                            if (is.Facility__c != null) {
                                throw new WorkOrderNewExtV2Exception(Label.Incorrect_Item_Specification);
                                break;
                            }
                        }
                    }
                }
                wOrder.Item__c = itemSpec.Item__c;
            }
                
            DML.checkUpsertAsUser( worder);
            upsert wOrder;
            result.success = true;
            result.additionalInfo = wOrder.id;
             
        }
        catch(Exception e){
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    } 
    public  String getReturnUrl(){
        PageReference pageRef;
         
        if (workOrder != null && workOrder.id != null ){
            pageRef =  new PageReference('/' + workOrder.Id);
        }
        else{
            Schema.DescribeSObjectResult dsr = Work_Order__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        }
        
        return pageRef.getUrl();
    }

}