/**
 * Create/Change Work Order for MTO/BTO SOLines
 * Multiple SOLines (same item and Ship Location) can be consolidated
 */ 
public with sharing class WorkOrderPlannerWorkbenchExt extends BaseController{
    public String namespaceUU { get; set; } { namespaceUU = KSE.NamespaceUU; }
    public String soLinesFieldList;
    List<FieldInfo> soLinesFieldInfoList, woFieldInfoList;
    public String woFieldList;
    public Id defaultCompany { get; set; }
    public Id defaultFacility { get; set; }
    public string HelpURL{get;set;}
    public string woStatuses{get {
        if ( woStatuses == null ) {
            Set<String> statuses = new set<string>{'',WorkOrderService.WO_STATUS_DRAFT,WorkOrderService.WO_STATUS_IN_PROCESS,WorkOrderService.WO_STATUS_RELEASED,WorkOrderService.WO_STATUS_COMPLETE};  
            woStatuses = JSON.serialize(statuses);
        }
        return woStatuses;
    }set;}
    public WorkOrderPlannerWorkbenchExt () {
        HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpWOPlannerWorkbench';
        User_Preference__c up = UserPreference.getInstance().preference;
        
        if (up != null ) {
            if  (up.Default_Facility__c != null ) {
                defaultFacility = up.Default_Facility__c;
            }
            if  (up.Default_Company__c != null ) {
                defaultCompany = up.Default_Company__c;
            }   
        }
    }
    
    /** Grid configurations **/
    /** Sales Order Line Grid Configurations and data **/
    private GridRelatedListController.GridRelatedListConfig solineConfig {
        get {
            if ( solineConfig == null ) {
                solineConfig = new GridRelatedListController.GridRelatedListConfig ();
                solineConfig.objectName = 'Sales_Order_Line__c';
                solineConfig.fieldset = 'WO_Planner_Workbench';
                solineConfig.buttons = '';
                solineConfig.pageSize   = 10;
                solineConfig.parentField = 'Sales_Order__c';
                solineConfig.height = '30%';
                solineConfig.sortField = 'Work_Order__c';
                solineConfig.sortOrder = 'ASC';
                solineConfig.addlWhereClause = 'Status__c=\'Open\' AND (Fulfillment_Source__c=\'Build To Order\' OR Product__r.Item__r.Source__c=\'Build To Order\' ) AND Sales_Order__r.Type__c IN (\'Standard\', \'RMA-Replacement\')';
            }
            return solineConfig;
        } set;
    }
      
    public String getSOLinesFieldList() {
        if (soLinesFieldList == null && solineConfig != null) {
            soLinesFieldInfoList = new List<FieldInfo>();
            for ( FieldInfo fi : FieldInfo.fetchJsonFieldInfos(solineConfig.objectName, solineConfig.fieldset, solineConfig.readOnlyFields)) {
                if ( fi.title.equals ('Work Order') ) {
                    fi.editable = true;
                } else {
                    fi.editable = false;     
                }
                
                soLinesFieldInfoList.add( fi );
            }
            soLinesFieldList = JSON.serialize(soLinesFieldInfoList);
        }
        
        return soLinesFieldList;
    }
    
    public String solineConfigJson {
        get {
            if ( solineConfigJson == null ) {
                solineConfigJson = JSON.serialize( solineConfig);
            }
            return solineConfigJson; 
        } set;
    }
    
    /** Work Order Grid Configurations and data **/
    private GridRelatedListController.GridRelatedListConfig woConfig {
        get {
            if ( woConfig == null ) {
                woConfig = new GridRelatedListController.GridRelatedListConfig ();
                woConfig.objectName = 'Work_Order__c';
                woConfig.fieldset   = 'WO_Planner_Workbench';
                woConfig.buttons    = '';
                woConfig.pageSize   = 10;
                woConfig.height     = '30%';
                woConfig.sortField = 'Need_Date2__c';
                woConfig.sortOrder = 'ASC';
                woConfig.addlWhereClause =  'Status__c NOT IN (\'Closed\',\'Cancelled\') AND Type__c != \''+WorkOrderService.WO_TYPE_REPAIR +'\' ';
            }
            return woConfig;
        } set;
    }
    
    public String getWOFieldList() {
        if (woFieldList == null && woConfig != null) {
            woFieldInfoList = new List<FieldInfo>();
            for ( FieldInfo f: FieldInfo.fetchJsonFieldInfos(woConfig.objectName, woConfig.fieldset, woConfig.readOnlyFields)) {
                f.editable = false;
                woFieldInfoList.add(f);    
            }
            
            // Scrapped__c field is the temporary value holder  for Demand Quantity
            FieldInfo field = new FieldInfo ('Scrapped__c', 'Demand Quantity', 'decimal');
            field.editable = false;
            woFieldInfoList.add (field);
            woFieldList = JSON.serialize(woFieldInfoList);
        }
        
        return woFieldList;
    }
    
    public String woConfigJson {
        get {
            if ( woConfigJson == null ) {
                woConfigJson = JSON.serialize( woConfig);
            }
            return woConfigJson;
        } set;
    }
    
    /** Grid Events **/
    /** data fetch**/
    @RemoteAction 
    public static DataSourceResult getSOLineData( GridRelatedListController.GridRelatedListConfig config, 
                            Id facility, Id soId, 
                            Id customerId, Id productId, Id itemId,
                            List<KendoUtils.FilterDescriptor> filters) {
        
        // Date Filter
        List<String> filterCriteria = new List<String>();
        if ( filters != null )
            filterCriteria = KendoUtils.getFilterCriteria(filters);
        
        if (filterCriteria.size() > 0) {
            config.addlWhereClause += ' AND ' + String.join(filterCriteria, ' AND ');
        }
        
        if ( facility != null ) {
            config.addlWhereClause += ' AND Ship_From_Location__r.Facility__c=\''+facility+'\'';
        } else {
            config.addlWhereClause += ' AND Ship_From_Location__r.Facility__c=null';
        }
        if ( soID != null ) {
            config.addlWhereClause += ' AND Sales_Order__c=\''+soID+'\'';
        }
        if ( customerId != null ) {
            config.addlWhereClause += ' AND Sales_Order__r.Customer__c=\''+customerId+'\'';
        }
        if ( productId!= null ) {
            config.addlWhereClause += ' AND Product__c=\''+productId+'\'';
        }
        if (itemID != null ){
            config.addlWhereClause += ' AND Product__r.Item__c=\''+itemID+'\'';
        }
        
        return GridRelatedListController.getRelatedList (config);
    }
    
    @RemoteAction
    public static DataSourceResult getWOData( GridRelatedListController.GridRelatedListConfig config, 
                            Id facility, Id soId, 
                            Id customerId, Id productId, Id itemId,
                            List<KendoUtils.FilterDescriptor> filters,
                            string status) {
                                
        String addnlWhereClause;                       
        if(status == ''){
         addnlWhereClause = ' Status__c NOT IN (\'Closed\',\'Cancelled\') AND Type__c != \''+WorkOrderService.WO_TYPE_REPAIR +'\' ';   
        }else {
            addnlWhereClause = ' Status__c = \'' + status+'\' AND Type__c != \''+WorkOrderService.WO_TYPE_REPAIR +'\' ';   
        }
        
        
        // Date Filter
        List<String> filterCriteria = new List<String>();
        if ( filters != null )
            filterCriteria = KendoUtils.getFilterCriteria(filters);
        
        if (filterCriteria.size() > 0) {
            addnlWhereClause += ' AND ' + String.join(filterCriteria, ' AND ');
        }
        
        // work oredr related filter
        if ( facility != null ) {
            addnlWhereClause += ' AND Facility__c=\''+facility+'\'';
        } else {
            addnlWhereClause += ' AND Facility__c=null';
        }
        
        if (itemID != null ){
            addnlWhereClause += ' AND Item__c=\''+itemID+'\'';
        }
        
        config.addlWhereClause = addnlWhereClause;
        DataSourceResult result = GridRelatedListController.getRelatedList (config);
        Set<Id> workOrderIds = new Set<Id> ();
        for ( SObject wo : result.records ) {
            workOrderIds.add ( wo.Id );
        }
        
        Map<Id,Decimal> mapWODemands = new Map<Id, Decimal> (); 
        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        map<id,Shipment_Line__c> woToSHLMap = new map<id,Shipment_Line__c>();
        SOQLUtil shlQuery = new SOQLUtil ('Shipment_Line__c');
        shlQuery.addAllCustomFields();
        shlQuery.addFields( new Set<String>{'Product__r.Item__c','Sales_Order_Line__r.Selling_UOM__c','Product__r.Item__r.Stocking_UOM__c', 'Product__r.Item__r.Packaging_UOM__c','Item__c',
                        'Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c', 'Facility__r.Facility_Identifier__c','Work_Order__r.Packaging_UOM__c'
        });
        shlQuery.setWhereClause('Work_Order__c !=null AND Work_Order__c in :workOrderIds');
        
        for (Shipment_Line__c shl: Database.query(shlQuery.getQuery()) ) {
          if(!woToSHLMap.containsKey(shl.Work_Order__c)){
             woToSHLMap.put(shl.Work_Order__c,shl);  
          }
        }
        
        for ( AggregateResult aggRes : [SELECT work_order__c, SUM(Quantity_Ordered__c), SUM(Quantity_Allocated__c) from Sales_order_Line__c WHERE work_order__c in :workOrderIds GROUP BY work_order__c] ) {
            Id woID = (Id)aggRes.get(KSE.NamespaceUU + 'Work_Order__c');
            Decimal qty = (Decimal) aggRes.get('expr0');
            Shipment_Line__c shl ;    
            if(woToSHLMap.containsKey(woID)){
               shl = woToSHLMap.get(woID); 
            }
            packagingUoms.put(shl.Item__c, (List<Id>)JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.Class));
            Decimal convFactor = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c,shl.Sales_Order_Line__r.Selling_UOM__c, shl.Work_Order__r.Packaging_UOM__c, packagingUoms.get(shl.Item__c)); 
            mapWODemands.put( woID, qty * convFactor );
        }
        
        for ( SObject wo : result.records ) {
            wo.put( 'Scrapped__c', mapWODemands.get(wo.Id) );
        }
        
        return result;
    }
    
    /**
     * so line grid save
     * @param soLines
     * @param intSaveType 1=Consolidate and Save, 0=Save
     */ 
    @RemoteAction 
    public static JsonResult save ( List<Sales_Order_Line__c> soLines, Integer intSaveType ) {
        WorkOrderService.SaveType st;
        if ( intSaveType == 1) {
            st = WorkOrderService.SaveType.CONSOLIDATE_AND_SAVE;
        } else {
            st = WorkOrderService.SaveType.SAVE;
        }
        
        Map<Id, Sales_Order_Line__c> mapSOLines = new Map<Id, Sales_Order_Line__c>();
        Map<Id, Sales_Order_Line__c> mapOldSOLines = new Map<Id, Sales_Order_Line__c>();
        Map<Id, Shipment_Line__c> solToShlMap = new Map<Id, Shipment_Line__c>();
        
        for ( Sales_Order_Line__c sol : soLines ) {
            mapSOLines.put ( sol.Id, sol);
        }
        
        Set<Id> solIds = mapSOLines.keySet();
        Set<String> addnlFields = new Set<String>{
            'Product__r.Item__c', 'Product__r.Item__r.Lead_Time__c', 'Product__r.Item__r.Non_Inventory__c', 'Product__r.Item__r.Stocking_UOM__c', 'Product__r.Item__r.Packaging_UOM__c','Item_Specification__r.Default_Work_Order_Packaging_UOM__c',
            'Sales_Order__r.Type__c', 'Sales_Order__r.Ship_From_Location__r.Facility__c','Ship_From_Location__r.Facility__c',
            'Ship_From_Location__r.Facility__r.Default_Work_Order_Complete_to_Location__c','Ship_From_Location__r.Facility__r.Default_Work_Order_MRB_Location__c',
            'Ship_From_Location__r.Facility__r.Default_Work_Order_WIP_Location__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
        };
        SOQLUtil solQueryUtil = new SOQLUtil ('Sales_Order_Line__c', true);
        solQueryUtil.addAllCustomFields();
        solQueryUtil.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
        solQueryUtil.addFields(addnlFields);
        solQueryUtil.setWhereClause('id in :solIds');
        
        for ( Sales_Order_Line__c sol : Database.query ( solQueryUtil.getQuery() ) ) {
            mapOldSOLines.put( sol.Id, sol);
        }
        
        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c', true);
        shlQuery.addFields(new Set<String> {'id','Sales_Order_Line__c', 'Product__r.Item__r.Stocking_UOM__c','Sales_Order_Line__r.Selling_UOM__c',
            'Quantity_Allocated__c', 'Quantity_Planned__c', 'Quantity_Picked__c','Quantity_Shipped__c', 'Facility__r.Facility_Identifier__c'
        });
        shlQuery.setWhereClause('Sales_Order_Line__c in :solIds');
        
        for (Shipment_Line__c shl: Database.query (shlQuery.getQuery())) {
            solToShlMap.put(shl.Sales_Order_Line__c, shl);
        }
       
        Savepoint sp = Database.setSavepoint();
        JsonResult result = new JsonResult ();
        try {
            WorkOrderService.syncWorkOrdersWithSalesOrderLines(mapSOLines, mapOldSOLines, solToShlMap,  st);
            
            if ( ExceptionService.hasErrors ) {
                Database.rollback(sp);
                result.success = false;
                result.messages = new List<Map<String, String>> (ExceptionService.messages );
                
            } else {
                result.success = true;
            }
        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    } 
    
    /**
     * Update the wo order quantity to match the demand quantity and re release
     */ 
    @RemoteAction 
    public static JSONResult updateAndReReleaseWorkOrders ( List<Work_Order__c> wos ) {
        JSONResult result = new JSONResult ();
        List<Work_Order__c> wosToUpdate = new List<Work_Order__c> ();
        Set<Id> wosForReRelease = new Set<Id> ();
        for ( Work_Order__c wo: wos) {
            if ( wo.Scrapped__c != null ) {
                wosToUpdate.add( new Work_Order__c (Id= wo.Id, Order_Quantity__c=wo.Scrapped__c, Last_Sync_date__c=System.now()) );
                wosForReRelease.add(wo.Id);
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            WorkOrderService.allowWorkOrderUpdate = true;
            DML.updateAsUser(wosToUpdate);
            WorkOrderService.allowWorkOrderUpdate = false;
            
            WorkOrderPlanningService.release (wosForReRelease);
            if ( ExceptionService.hasErrors ) {
                Database.rollback(sp);
                result.success = false;
                result.messages = new List<Map<String, String>> (ExceptionService.messages );
                
            } else {
                result.success = true;
            }
        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        
        return result;
    }
    
}