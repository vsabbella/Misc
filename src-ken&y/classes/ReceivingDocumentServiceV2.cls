public with sharing class ReceivingDocumentServiceV2 {
    
    public class ReceivingDocumentServiceV2Exception extends Exception{
    }
    
    public static final string RD_STATUS_VOID = 'Void';
    public static final string RD_STATUS_INTRANSIT = 'In-Transit';
    public static final string RD_TYPE_RETURN = 'Return Receipt';
    public static final string RD_TYPE_MISCELLANEOUS = 'Miscellaneous Receipt';
    private static SchemaUtil util = SchemaUtil.getInstance();
    private static ReceivingDocumentServiceV2 instance = null;
    public static boolean skipPutaway = false;
    public static String RMAReceiptRouting = '';
    public static map<id,string> orderlineKeyMismatchExceptionList = new map<id,string>();
    public static map<Id,Map<string,string>> olIdKeyNameMap = new map<Id,Map<string,string>>();
    private ReceivingDocumentServiceV2(){
        
    }
    
    public static ReceivingDocumentServiceV2 getInstance(){
        if(instance == null){
            instance = new ReceivingDocumentServiceV2();
        }
        return instance;
    }
    
    public static map<Id,sObject> queryLines( set<id> headerIds, set<Id> lineIds, set<String> docTypes, Boolean includeChildRelationShips ){
        
        map<Id,SObject> refreshedSObjects = new map<Id,SObject>();
        String inClause = 'Id IN:lineIds';

        if (docTypes.contains('purchase_order_line__c') == true) {
            SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c');

            Set<String> fieldStrings = new Set<String>{'Id','Name','company__c','company__r.Serial_Control__c','company__r.comp_currency__c','material_tracking__c', 'material_tracking__r.allocation_required__c','material_tracking__r.quantity_allocated__c','material_tracking__r.quantity_short__c','material_tracking__r.allocate_on_receipt__c',
                'Item_Specification__r.Item__r.Stocking_UOM__r.Package_Class__r.Level__c','Item_Specification__r.Item__r.Stocking_UOM__r.Package_Class__r.Default_Container_Item__c','Item_Specification__r.Item__r.Stocking_UOM__r.Package_Class__c','material_tracking__r.name','material_tracking__r.work_order__c','material_tracking__r.quantity_issued__c','material_tracking__r.quantity_required__c','material_tracking__r.work_order__r.status__c','material_tracking__r.work_order__r.company__c','material_tracking__r.work_order__r.company__r.serial_control__c',
                'item__c','purchase_order__c','purchase_order__r.Currency__c','purchase_order__r.supplier__c','purchase_order__r.supplier__r.name','purchase_Order__r.status__c','delivery_location__c',
                'delivery_location__r.facility__c','status__c','unit_price__c', 'overage_quantity__c','purchase_order__r.type__c', 'Item__r.Packaging_UOM__c',
                'item__r.item_attribute__c', 'supplier__c', 'consigned__c','item__r.Stocking_uom__c','item__r.Stocking_uom__r.name','item__r.Stocking_uom__r.Package_Class__c', 'item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c','item__r.source__c','company__c',
                'item_specification__r.item__r.Stocking_uom__c','item__r.non_inventory__c','item__r.class__r.minimum_shelf_life_in_days__c','delivery_facility__c','work_order__r.assembly_item_specification__c',
                'item_specification__r.item__r.Container_Item__r.Container_Package_Class__c','work_order__c','item_specification__c', 'item_specification__r.item__r.Packaging_UOM__c','item_specification__r.item__c', 'item_specification__r.item__r.non_inventory__c', 'item_specification__r.item__r.item_attribute__r.serial_number__c','item_specification__r.item__r.item_attribute__c',
                'Quantity_Shipped__c','purchase_Order__r.approval_status__c','delivery_location__r.Facility__r.Default_Work_Order_Complete_to_Location__c','delivery_location__r.Facility__r.Default_Work_Order_MRB_Location__c',
                'delivery_location__r.Facility__r.Default_Work_Order_WIP_Location__c','item__r.Lead_Time__c','Operation_Tracking__c','Operation_Tracking__r.Work_Order__c','Work_Order__r.Type__c','Operation_Tracking__r.Work_Order__r.Type__c',
                'item__r.Container_Item__r.item_attribute__c','item_specification__r.item__r.Container_Item__r.item_attribute__c','Packaging_UOM__c','Packaging_UOM__r.Name','Item__r.Container_Item__c','Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
                'Item__r.Container_Item__r.Container_Package_Class__c','Item__r.Container__c', 'item_specification__r.item__r.Container__c', 'Delivery_Facility__r.Facility_Identifier__c',

                'Purchase_UOM__c','Purchase_UOM__r.Package_Class__c', 'Purchase_UOM__r.Package_Class__r.Default_Container_Item__c',
                'Purchase_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
                'Purchase_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
                'Purchase_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
                'Purchase_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c', 'Purchase_UOM__r.Package_Class__r.Level__c' };

            soql.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
            soql.addAllCustomFields(Item_Attribute__c.sObjectType, 'Purchase_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
            soql.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item_Specification__r.Item__r.Item_Attribute__r');
            
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('','purchase_order_line__c') );
            fieldStrings.addAll( SkidService3.getStockMovementRuleFields('Purchase Order'));
            //if(subquery != null ){ fieldStrings.add(subquery); }
            for(string s :SkidService3.getStockMovementRuleFields('Work Order')){
                s =  'Material_Tracking__r.'+s;
                fieldStrings.add(s);
             }
            if( headerIds != null ){
                inClause = 'Purchase_Order__c IN :headerIds';
            }

            String whereClause = inClause + ' and Quantity_Still_Due__c > 0 and Status__c = \'Open\' and Purchase_Order__r.Status__c = \'Open\'  and Purchase_Order__r.Type__c != \'Drop Ship\' and Purchase_Order__r.FOB_Term__r.FOB_Point__c != \'Origin\'';
            
            soql.addFields('Receiving_RO');
            soql.addFields(fieldStrings);
            soql.setWhereClause(whereClause);

            if(includeChildRelationShips){
                set<String> skidFields = new set<String>{ 'Id', 'Name', 'Location__c', 'Container_item__r.Name','Container_item__c','Order_Line__r.Ship_From_Location__c' , 'Bin__r.Location__c', 'Shipment_Line__r.Company__c','Shipment_Line__r.Facility__c','Shipment_Line__r.Item__c','Packaging_UOM__r.Name','Packaging_UOM__c',
                                        'Shipment_Line__r.Shipment__c','Shipment_Line__r.Shipment__r.Status__c', 'Shipment_Line__c', 'Item__r.Item_Attribute__c','Item__r.Non_Inventory__c','Item__r.Source__c','Company__c','Location__r.Facility__r.Company__c', 'Item__r.Packaging_UOM__c'};
                skidFields.addAll(util.getAllCustomFieldsFromObject(null, 'Skid__c'));
                skidFields.addAll( util.getAllCustomFieldsFromObject('Item__r.item_attribute__r.','item_attribute__c') );

                SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
                skids.addFields(skidFields);
                skids.setWhereClause('Quantity__c>0');
                soql.addChildRelationship(skids);
            }

            /*refreshedSObjects.putAll( new Map<id,SObject>(Database.query( util.generateQueryFromFieldSet( 'Purchase_Order_Line__c', new set<string>{'Receiving_RO'},
                        fieldStrings,inClause+' and Quantity_Still_Due__c > 0 and Status__c = \'Open\' and Purchase_Order__r.Status__c = \'Open\'') )));*/
            refreshedSObjects.putAll( new Map<id,SObject>(Database.query(soql.getQuery())));
            
        }
        
        if( docTypes.contains('Sales_Order_Line__c'.toLowerCase())){
            
            set<String> fieldStrings = new set<string>{'Id','Name', 'Related_Sales_Order_Line__c', 'Related_Sales_Order_Line__r.Fulfillment_Source__c', 'Fulfillment_Source__c','Quantity_Fulfilled__c', 'Status__c','Line__c','Product__r.Item__c', 'Product__r.Item__r.Non_Inventory__c','Product__r.Item__r.Description__c','Product__r.Item__r.Name',
                              'Product__r.Item__r.Class__c', 'Product__r.Item__r.Track_Install_Base__c', 'Product__r.Item__r.Source__c',
                              'Quantity_From_Stock__c','Quantity_Available_to_Ship__c','Quantity_Backordered__c','Company__c', 'Company__r.Serial_Control__c', 'Company__r.Use_Warranty_Repairs__c', 'Selling_UOM__r.Name', 'Ship_From_Location__r.Facility__c', 'Ship_From_Location__r.Facility__r.RMA_Receipt_Routing__c',
                              'Product__c','Product__r.Name','Quantity_Ordered__c','Quantity_Shipped__c','Quantity_to_Ship__c','Ship_From_Location__c','Product__r.Item__r.Stocking_UOM__r.Name',
                              'Required_Date__c','Sales_Order__c','Sales_Order__r.Customer__r.Top_Parent_Customer__c','Status__c','Discount_Percent__c',
                              'Unit_Price__c','SystemModStamp','Sales_Order__r.Customer__r.Top_Parent_Customer__r.Status__c','Product__r.Item__r.Track_Install_Base__c',
                              'Sales_Order__r.Currency__c','Sales_Order__r.Company__c', 'Sales_Order__r.Status__c', 'Sales_Order__r.Type__c', 'Description__c','Selling_UOM__c','Sales_Order__r.Name',
                              'Product__r.item__r.Container__c','Product__r.item__r.Container_Item__r.Container_Package_Class__c','Product__r.Item__r.Container_Item__c','Product__r.Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
                			  'Selling_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c','Packaging_UOM__r.Package_Class__r.Level__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__c','Product__r.Item__r.Container_Item__r.Container_Package_Class__c','Ship_From_Location__r.Facility__r.Default_Work_Order_Complete_to_Location__c','Ship_From_Location__r.Facility__r.Default_Work_Order_MRB_Location__c','Product__r.Item__r.Container__c',
                			  'Selling_UOM__r.Package_Class__r.Level__c','Ship_From_Location__r.Facility__r.Default_Work_Order_WIP_Location__c','product__r.item__r.Lead_Time__c','Packaging_UOM__c','Product__r.Item__r.Packaging_UOM__c','Packaging_UOM__r.Package_class__r.Level__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c',
                'Sales_Order__r.Customer__c'
            };
            
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('product__r.item__r.item_attribute__r.','item_attribute__c') );
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('product__r.','product__c') );
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('','sales_order_line__c') );
            //fieldStrings.addAll( util.getAllCustomFieldsFromObject('Ship_From_Facility__r.','Facility__c') );
            fieldStrings.addAll( SkidService3.getStockMovementRuleFields('Sales Order'));
            
            if( headerIds != null ){
                inClause = 'Sales_Order__c IN:headerIds';
            }

            String whereClause = inClause+' and Status__c = \'Open\' and Quantity_Ordered__c < 0';

            SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
            soql.addFields('RMA_Receiving');
            soql.addFields(fieldStrings);
            soql.setWhereClause(whereClause);

            refreshedSObjects.putAll( new Map<id,SObject>(Database.query(soql.getQuery())));
        }
        
         if( docTypes.contains('Receipt_Line__c'.toLowerCase())){
            
            set<String> fieldStrings = new set<string>{'Id','Name', 'Quantity_Received__c','Company__r.comp_currency__c', 'Status__c','Line__c','Item__c','Item__r.Description__c', 'Item__r.Stocking_UOM__c', 'Item__r.Name','Item__r.Class__c', 'Item__r.Non_Inventory__c', 'Item__r.Source__c',
                              'Packaging_UOM__r.Name','Packaging_UOM__c','Packaging_UOM__r.Package_Class__c','Packaging_UOM__r.Package_Class__r.Level__c','item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_attribute__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_attribute__r.License_Plate_Number__c','Number_of_Boxes__c','Location__c','Quantity_To_Stock__c','Quantity_Still_Due_For_Putaway__c', 'Company__c', 'Facility__c', 'Location__r.Facility__r.RMA_Receipt_Routing__c','Sales_Order_Line__r.Sales_Order__r.Type__c',
                              'Sales_Order__c','Sales_Order__r.Name','Sales_Order_Line__c','Sales_Order_Line__r.Name', 'Sales_Order_Line__r.Fulfillment_Source__c', 'Sales_Order_Line__r.Returned_To_Vendor__c', 'Sales_Order_Line__r.Related_Sales_Order_Line__c','Sales_Order_Line__r.Related_Sales_Order_Line__r.Fulfillment_Source__c', 'Item__r.Stocking_UOM__r.Name','Company__r.Serial_Control__c', 'Company__r.Use_Warranty_Repairs__c','Item__r.Track_Install_Base__c',
                              'Receiving_Document__c','Receiving_Document__r.Name', 'Receiving_Document__r.Type__c', 'Receiving_Document__r.Transaction_Date__c', 'purchase_order__r.Name', 'purchase_order__c', 'purchase_order__r.Currency__c', 'Sales_Order__c','Sales_Order__r.Customer__r.Top_Parent_Customer__c','Status__c',
                              'Unit_Price__c','Sales_Order__r.Customer__r.Top_Parent_Customer__r.Status__c', 'Receiving_Document__r.Currency__c','Sales_Order__r.Currency__c','Sales_Order__r.Company__c','Sales_Order_Line__r.Product__r.Item__r.Stocking_UOM__c', 'Sales_Order_Line__r.Selling_UOM__c',
                              'Sales_Order__r.Status__c', 'Sales_Order__r.Type__c', 'Description__c','Supplier__c','Sales_Order__r.Name','Sales_Order_Line__r.Ship_From_Location__r.Facility__r.Facility_Identifier__c','Sales_Order_Line__r.Company__c',
                              'Sales_Order_Line__r.Selling_UOM__r.Package_Class__c','Sales_Order_Line__r.Selling_UOM__r.Package_Class__r.Level__c','Sales_Order__r.Status__c', 'Sales_Order__r.Type__c', 'Description__c','Supplier__c','Sales_Order__r.Name','Sales_Order_Line__r.Ship_From_Location__r.Facility__c','Sales_Order_Line__r.Company__c','Sales_Order_Line__r.Product__r.Item__r.Packaging_UOM__c',
                              'item__r.Container_Item__c','item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c','item__r.Container_Item__c','item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c','item__r.Container_Item__r.Container_Package_Class__c','item__r.Container_Item__r.Container_Package_Class__c','item__r.Stocking_uom__r.Package_Class__c','item__r.Stocking_uom__r.Package_Class__r.Level__c', 'item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c',
                              'Sales_Order_Line__r.Selling_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c','Sales_Order_Line__r.Packaging_UOM__r.Package_Class__r.Level__c','Sales_Order_Line__r.Packaging_UOM__r.Package_Class__r.Default_Container_Item__c','Item__r.Container_Item__r.Container_Package_Class__c',
                              'Sales_Order_Line__r.Selling_UOM__r.Package_Class__r.Level__c', 'item__r.Packaging_UOM__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
                              'Location__r.Facility__r.Default_Work_Order_Complete_to_Location__c','Location__r.Facility__r.Default_Work_Order_MRB_Location__c','Sales_Order_Line__r.Packaging_UOM__c','item__r.Packaging_UOM__c','Sales_Order_Line__r.Packaging_UOM__r.Package_class__r.Level__c',
                              'Location__r.Facility__r.Default_Work_Order_WIP_Location__c','item__r.Lead_Time__c', 'Company__r.Default_Transaction_Currency__c' ,'Item__r.Container__c', 'Facility__r.Facility_Identifier__c'
            };
            
            fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('sales_order_line__r.product__r.item__r.item_attribute__r.','item_attribute__c') ); 
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('item__r.item_attribute__r.','item_attribute__c') );
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('','receipt_line__c') );
            fieldStrings.addAll( SkidService3.getStockMovementRuleFields('Receiving Document'));
            
            if( headerIds != null ){
                inClause = 'Sales_Order__c IN:headerIds';
            }

             String filterType;
             

            String whereClause = inClause + ' and Quantity_Still_Due_For_Putaway__c > 0';

            
            if(docTypes.contains('Receiving Document'.toLowerCase())){
                whereClause = 'Id IN:lineIds and Status__c != \'Closed\' and Receiving_Document__r.Type__c !=\'RMA Receipt\' and Receiving_Document__r.Type__c !=\'RMA Receipt For Repair\' and Quantity_Still_Due_For_Putaway__c > 0 ';
            }

            SOQLUtil soql = new SOQLUtil('Receipt_Line__c');
            soql.addFields('PutawayReceipts');
            soql.addFields(fieldStrings);
            soql.setWhereClause(whereClause);

            if(includeChildRelationShips){
                SOQLUtil.ChildRelationship woQuery = new SOQLUtil.ChildRelationship(soql,'Work_Orders__r');
                woQuery.addAllCustomFields();
                woQuery.setWhereClause('Status__c = \'Draft\'');
                soql.addChildRelationship(woQuery);
            }
            
            refreshedSObjects.putAll( new Map<id,SObject>(Database.query(soql.getQuery())));
        }
        
        if(docTypes.contains('ASN_Line__c'.toLowerCase())){
            set<String> fieldStrings = new set<string>{'Id', 'Name', 'company__c', 'company__r.comp_currency__c','company__r.Serial_Control__c', 'Company__r.Use_Warranty_Repairs__c','item__c','ASN__r.Name','ASN__r.FOB__r.FOB_Point__c','ASN__r.Packing_Slip_Number__c','ASN__r.Number_of_Boxes__c','ASN__r.Tracking_Number__c','ASN__r.Date_Shipped__c',
                'ASN__r.Currency__c','ASN__r.Carrier__c','ASN__r.supplier__c', 'Location__r.Facility__c','purchase_order__c','purchase_order__r.Currency__c' ,'purchase_order__r.supplier__c','purchase_order__r.supplier__r.name','purchase_order__r.status__c','purchase_order_line__r.id',
                'purchase_order_line__r.delivery_Facility__c','purchase_order_line__r.company__c','purchase_order_line__r.Type__c','purchase_order_line__r.purchase_order__r.Type__c','purchase_order_line__r.need_date__c','purchase_order_line__r.delivery_location__c','purchase_order_line__r.purchase_uom__r.name','unit_price__c', 'purchase_order_line__r.overage_quantity__c','purchase_order__r.fob_term__c',
                'purchase_order_line__r.delivery_location__r.facility__c','purchase_order_line__r.status__c', 'purchase_order_line__r.Quantity_Returned_to_Supplier__c', 'purchase_order_line__r.Order_Quantity__c', 'purchase_order_line__r.Quantity_Still_Due__c','purchase_order_line__r.purchase_uom__c','purchase_order_line__r.purchase_order__r.fob_term__r.fob_point__c','purchase_order_line__r.purchase_order__r.supplier__r.name',
                'item__r.item_attribute__c', 'supplier__c', 'purchase_order_line__r.consigned__c','purchase_order_line__r.item__r.stocking_uom__c','item__r.stocking_uom__c','item__r.stocking_uom__c','item__r.Stocking_uom__r.name','purchase_order_line__r.purchase_order__r.supplier__c',
                'item__r.non_inventory__c','item__r.class__r.minimum_shelf_life_in_days__c', 'purchase_order_line__c','purchase_order_line__r.quantity_received__c','item__r.source__c',
                'purchase_order_line__r.material_tracking__r.name','purchase_order_line__r.material_tracking__r.Quantity_Allocated__c','purchase_order_line__r.material_tracking__r.quantity_issued__c','purchase_order_line__r.material_tracking__r.quantity_required__c','purchase_order_line__r.material_tracking__r.allocation_required__c','purchase_order__r.approval_status__c','purchase_order__r.status__c','item__r.Stocking_uom__r.name','item__r.stocking_uom__c',
                'purchase_order_line__r.material_tracking__r.work_order__r.status__c','purchase_order_line__r.material_tracking__r.work_order__r.company__c','purchase_order_line__r.material_tracking__r.work_order__r.company__r.serial_control__c','purchase_order_line__r.work_order__c','purchase_order_line__r.item_specification__c', 'purchase_order_line__r.item_specification__r.item__c',
    			'purchase_order_line__r.item_specification__r.item__r.non_inventory__c', 'purchase_order_line__r.item_specification__r.item__r.item_attribute__r.serial_number__c','purchase_order__r.type__c',
                'Purchase_order_line__r.Item_Specification__r.Item__r.Stocking_UOM__c','purchase_order_line__r.work_order__r.assembly_item_specification__c', 'purchase_order_line__r.Quantity_Shipped__c','purchase_order_line__r.operation_tracking__c','purchase_order_line__r.material_tracking__r.quantity_short__c','purchase_order_line__r.material_tracking__r.allocate_on_receipt__c',
                'purchase_order_line__r.purchase_order__r.status__c', 'purchase_order_line__r.purchase_order__r.Approval_Status__c', 'purchase_order_line__r.purchase_order__r.Name',
                'purchase_order_line__r.Supplier__c','Purchase_Order_Line__r.Sales_Order_Line__c','Purchase_Order_Line__r.delivery_location__r.Facility__r.Default_Work_Order_Complete_to_Location__c','Purchase_Order_Line__r.delivery_location__r.Facility__r.Default_Work_Order_MRB_Location__c',
                'Purchase_Order_Line__r.delivery_location__r.Facility__r.Default_Work_Order_WIP_Location__c','item__r.Lead_Time__c','Purchase_Order_Line__r.Operation_Tracking__r.Work_Order__c',
                'Purchase_Order_Line__r.Operation_Tracking__c','Purchase_order_line__r.Purchase_UOM__c','Purchase_Order_Line__r.Work_Order__r.Type__c','purchase_order_line__r.Purchase_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c',
                'Purchase_Order_Line__r.Item_Specification__r.item__r.Container_Item__r.Container_Package_Class__c','Purchase_Order_Line__r.Item_Specification__r.item__r.Container_Item__c','item__r.Container_Item__c','Item__r.Container_Item__r.Container_Package_Class__c','item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Purchase_order_line__r.Purchase_UOM__r.Package_Class__c','Purchase_order_line__r.Purchase_UOM__r.Package_Class__r.Level__c',
                'item__r.Packaging_UOM__c', 'Item__r.Container__c','Purchase_order_line__r.Item__r.Container__c','purchase_order_line__r.item_specification__r.item__r.Container__c',
                'Purchase_Order_Line__r.Item_Specification__r.item__r.Container_Item__r.Item_Attribute__c', 'Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c', 'Purchase_Order_Line__r.Item__r.Packaging_UOM__c'
            };
            
            fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('purchase_order_line__r.item__r.item_attribute__r.','item_attribute__c') );
            fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('item__r.item_attribute__r.','item_attribute__c') );
            fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('','ASN_Line__c') );
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('purchase_order_line__r.item_specification__r.item__r.item_attribute__r.','item_attribute__c') );
            
            for(string s :SkidService3.getStockMovementRuleFields('Work Order')){
               s =  'Purchase_Order_Line__r.Material_Tracking__r.'+s;
               fieldStrings.add(s);
            }
            
            for( Stock_Movement_Rule_Settings__c smrs : Stock_Movement_Rule_Settings__c.getAll().values() ){
            
                if( smrs.Source_Document__c == 'Purchase Order' ){
                    
                    if( smrs.Source_Document_Path__c == null || smrs.Source_Document_Path_Putaway__c == null ){
                        throw new ReceivingDocumentServiceV2Exception(Label.Source_Document_Path_Fields_Not_Populated);
                    }
                    
                    fieldStrings.add( 'purchase_order_line__r.'+(smrs.Source_Document_Path__c).toLowerCase() );
                    fieldStrings.add( 'purchase_order_line__r.'+(smrs.Source_Document_Path_Putaway__c).toLowerCase() );
                }
            }
           
            //if(subquery != null ){ fieldStrings.add(subquery); }
            if( headerIds != null ){
                inClause = 'ASN__c IN:headerIds';
            }            

            String whereClause = inClause+' and Status__c = \'Open\' and Purchase_Order_Line__r.Quantity_Still_Due__c > 0.0';

            SOQLUtil soql = new SOQLUtil('ASN_Line__c');
            soql.addFields('ASN_Line');
            soql.addFields(fieldStrings);
            soql.setWhereClause(whereClause);

            if(includeChildRelationShips){
                set<String> skidFields = new set<String>{ 'Id', 'Name', 'Item__r.Container_item__c','item__r.container__c','Item__r.Container_Item__r.Container_Package_Class__c','Item__r.Container_item__r.Name','Container_item__r.Name','Container_item__c', 'Location__c', 'Order_Line__r.Ship_From_Location__c' , 'Bin__r.Location__c', 'Shipment_Line__r.Company__c','Shipment_Line__r.Facility__c','Shipment_Line__r.Item__c','Packaging_UOM__c','Packaging_UOM__r.Name',
                                        'Shipment_Line__r.Shipment__c','Shipment_Line__r.Shipment__r.Status__c', 'Shipment_Line__c', 'Item__r.Item_Attribute__c','Item__r.Non_Inventory__c','Item__r.Source__c','Company__c','Location__r.Facility__r.Company__c','License_Plate_Number__c','License_Plate_Number__r.Name'};
                skidFields.addAll(util.getAllCustomFieldsFromObject(null, 'Skid__c'));
                skidFields.addAll( util.getAllCustomFieldsFromObject('Item__r.item_attribute__r.','item_attribute__c') );

                SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
                skids.addFields(skidFields);
                skids.setWhereClause('Quantity__c>0');
                soql.addChildRelationship(skids);
            }

            /*refreshedSObjects.putAll( new Map<id,SObject>(Database.query( util.generateQueryFromFieldSet( 'ASN_Line__c', new set<string>{'ASN_Line'}, fieldStrings,
                        inClause+' and Status__c = \'Open\' and Purchase_Order_Line__r.Quantity_Still_Due__c > 0.0') )));*/
			refreshedSObjects.putAll( new Map<id,SObject>(Database.query(soql.getQuery())));
        }
        
        if( docTypes.contains('Order_Line__c'.toLowerCase())){
            
            set<String> fieldStrings = new set<string>{'ID','Name','Shipping_Company__c','Shipping_Item__c','Receiving_Item__c','Receiving_Item__r.Description__c','Receiving_Item__r.Name','Receiving_Item__r.Class__c',
            	 			  'Quantity_To_Receive__c','Order__r.Currency__c','Order__r.Status__c','Receiving_Company__c','Receiving_Company__r.Serial_Control__c','Order__r.Shipping_Company__c','Description__c','packaging_uom__c','packaging_uom__r.name',
            				  'Quantity_Backordered__c','Deliver_To_Location__c','Deliver_To_Location__r.Facility__c','Receiving_Item__r.Item_Attribute__c','putaway_location__r.Id','putaway_location__c',
                              'Quantity_Ordered__c','Quantity_Shipped__c','Ship_From_Location__c','Receiving_Item__r.Item_Attribute__r.Serial_Number__c',
                              'Required_Date__c','Order__c','Status__c','Receiving_Item__r.item_attribute__c','Receiving_Item__r.Non_Inventory__c','Receiving_Item__r.Source__c',
                              'SystemModStamp','Receiving_Item__r.non_inventory__c','Receiving_Item__r.class__r.minimum_shelf_life_in_days__c',
                              'Receiving_Item__r.Packaging_UOM__c','Receiving_Item__r.Container__c','Receiving_Item__r.Stocking_uom__c','Receiving_Item__r.Stocking_uom__r.name','Receiving_Item__r.Stocking_uom__r.Package_Class__c',
                              'Receiving_Item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c','Receiving_Item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
                              'Receiving_Item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
                              'Receiving_Item__r.Container_Item__c','Receiving_Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
                			  'Receiving_Item__r.Container_Item__r.Container_Package_Class__c','Receiving_Item__r.Container_Item__r.Container_Package_Class__c',
                              'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
                              'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Receiving_Item__r.Container_Item__r.item_attribute__c',
                              'Packaging_UOM__c','Packaging_UOM__r.Name','Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__c','Receiving_Item__r.Stocking_uom__r.Package_Class__r.Fractional_Quantities_Allowed__c',
                			  'Packaging_UOM__r.Package_Class__c','Packaging_UOM__r.Package_Class__r.Level__c','Receiving_Item__r.Stocking_uom__r.Package_Class__r.Level__c','Receiving_Item__r.Stocking_uom__r.Package_Class__r.Level__c',
                			  'Deliver_To_Facility__r.Facility_Identifier__c', 'Ship_From_Facility__r.Facility_Identifier__c'};
            					
	            
	            
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('Receiving_Item__r.item_attribute__r.','item_attribute__c') );
            fieldStrings.addAll( SkidService3.getStockMovementRuleFields('Transfer Order'));
           
            //if(subquery != null ){ fieldStrings.add(subquery); }
            if( headerIds != null ){
                inClause = 'Order__c IN:headerIds';
            }  
            
            String whereClause = inClause+' and  Quantity_To_Receive__c > 0';
            
            SOQLUtil soql = new SOQLUtil('Order_Line__c');
            soql.addFields('Order_Receive');
            soql.addFields(fieldStrings);
            soql.setWhereClause(whereClause);
            refreshedSObjects.putAll( new Map<id,SObject>(Database.query(soql.getQuery())));
        }
        
        return refreshedSObjects;
    }
    
    public static map<Id,sObject> queryLinesfordisplay( set<id> headerIds, set<Id> lineIds, set<String> docTypes, Boolean includeChildRelationShips ){
        
        map<Id,SObject> refreshedSObjects = new map<Id,SObject>();
        String inClause = 'Id IN:lineIds';

        if (docTypes.contains('purchase_order_line__c') == true) {
            SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c');
            
            Set<String> fieldStrings = new Set<String>{'Id','Name','material_tracking__c', 'material_tracking__r.allocation_required__c','material_tracking__r.quantity_allocated__c','material_tracking__r.quantity_short__c','material_tracking__r.allocate_on_receipt__c',
                'material_tracking__r.name','material_tracking__r.work_order__c','material_tracking__r.quantity_issued__c','material_tracking__r.quantity_required__c','material_tracking__r.work_order__r.status__c','material_tracking__r.work_order__r.company__c','material_tracking__r.work_order__r.company__r.serial_control__c',
                'Item_Specification__r.Item__r.Stocking_UOM__c','item__c','purchase_order__c','purchase_Order__r.status__c','delivery_location__c','Item_Specification__r.Item__r.Stocking_UOM__r.Package_Class__c',
                'item__r.Container_Item__c','item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c','item__r.Container_Item__r.Container_Package_Class__c','delivery_location__r.facility__c','status__c','unit_price__c', 'overage_quantity__c','purchase_order__r.type__c',
                'item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__r.Item_attribute__c','item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__r.Item_attribute__r.License_Plate_Number__c','item__r.Stocking_uom__r.Package_Class__r.Fractional_Quantities_Allowed__c','item__r.item_attribute__c', 'consigned__c','item__r.Stocking_uom__c','item__r.Stocking_uom__r.name','item__r.Stocking_uom__r.Package_Class__c','item__r.Stocking_uom__r.Package_Class__r.Level__c', 'item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c','item__r.source__c',
                'item_specification__r.item__r.Stocking_uom__c','item_specification__r.item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c','item__r.non_inventory__c','item__r.class__r.minimum_shelf_life_in_days__c','delivery_facility__c','work_order__r.assembly_item_specification__c',
                'item__r.Container_Item__r.item_attribute__c','item_specification__r.item__r.Container_Item__r.item_attribute__c','item_specification__r.item__r.item_attribute__c','item_specification__r.item__r.Packaging_UOM__c','work_order__c','item_specification__c', 'item_specification__r.item__c', 'item_specification__r.item__r.non_inventory__c', 'item_specification__r.item__r.item_attribute__r.serial_number__c',
                'Quantity_Shipped__c','purchase_Order__r.approval_status__c','delivery_location__r.Facility__r.Default_Work_Order_Complete_to_Location__c','delivery_location__r.Facility__r.Default_Work_Order_MRB_Location__c','delivery_location__r.Facility__r.Default_Work_Order_WIP_Location__c','item__r.Lead_Time__c','Operation_Tracking__r.Work_Order__c', 'Item__r.Packaging_UOM__c',
                'item_specification__r.item__r.Container_Item__c','item_specification__r.item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c','item_specification__r.item__r.Container_Item__r.Container_Package_Class__c','Item__r.Container__c','item_specification__r.item__r.Container__c', 'Delivery_Facility__r.Facility_Identifier__c',

                'Company__r.Comp_Currency__c', 'Company__r.Serial_Control__c',

                'Purchase_Order__r.Company__c', 'Purchase_Order__r.Company__r.Comp_Currency__c', 'Purchase_Order__r.Company__r.Serial_Control__c',
                'Purchase_Order__r.Currency__c', 'Purchase_Order__r.Currency__r.Currency__c', 'Purchase_Order__r.Supplier__c',

                'Purchase_UOM__c','Purchase_UOM__r.Package_Class__c', 'Purchase_UOM__r.Package_Class__r.Default_Container_Item__c',
                'Purchase_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
                'Purchase_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
                'Purchase_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
                'Purchase_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c', 'Purchase_UOM__r.Package_Class__r.Level__c' };

            soql.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
            soql.addAllCustomFields(Item_Attribute__c.sObjectType, 'Purchase_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
            soql.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item_Specification__r.Item__r.Item_Attribute__r');
            
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('','purchase_order_line__c') );
            fieldStrings.addAll( SkidService3.getStockMovementRuleFields('Purchase Order'));
            //if(subquery != null ){ fieldStrings.add(subquery); }
            if( headerIds != null ){
                inClause = 'Purchase_Order__c IN :headerIds';
            }

            String whereClause = inClause + ' and Quantity_Still_Due__c > 0 and Status__c = \'Open\' and Purchase_Order__r.Status__c = \'Open\'  and Purchase_Order__r.Type__c != \'Drop Ship\' and Purchase_Order__r.FOB_Term__r.FOB_Point__c != \'Origin\'';
        
            soql.addFields('Receiving_RO');
            soql.addFields(fieldStrings);
            soql.setWhereClause(whereClause);

            if(includeChildRelationShips){
                set<String> skidFields = new set<String>{ 'Id', 'Name', 'Location__c', 'Order_Line__r.Ship_From_Location__c' , 'Bin__r.Location__c', 'Shipment_Line__r.Company__c','Shipment_Line__r.Facility__c','Shipment_Line__r.Item__c', 'Item__r.Packaging_UOM__c', 'Shipment_Line__r.Product__r.Item__r.Packaging_UOM__c',
                                        'Shipment_Line__r.Shipment__c','Container_Item__c','Container_Item__r.Name','Shipment_Line__r.Shipment__r.Status__c', 'Shipment_Line__c', 'Item__r.Item_Attribute__c','Item__r.Non_Inventory__c','Item__r.Source__c','Company__c','Location__r.Facility__r.Company__c'};
                skidFields.addAll(util.getAllCustomFieldsFromObject(null, 'Skid__c'));
                skidFields.addAll( util.getAllCustomFieldsFromObject('Item__r.item_attribute__r.','item_attribute__c') );

                SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
                skids.addFields(skidFields);
                skids.setWhereClause('Quantity__c>0');
                soql.addChildRelationship(skids);
            }

            refreshedSObjects.putAll( new Map<id,SObject>(Database.query(soql.getQuery())));
            
        }
        
        if( docTypes.contains('Sales_Order_Line__c'.toLowerCase())){
            
            set<String> fieldStrings = new set<string>{'Id','Name', 'Related_Sales_Order_Line__c', 'Related_Sales_Order_Line__r.Fulfillment_Source__c', 'Fulfillment_Source__c','Quantity_Fulfilled__c', 'Status__c','Line__c','Product__r.Item__c', 'Product__r.Item__r.Non_Inventory__c','Product__r.Item__r.Description__c','Product__r.Item__r.Name',
                              'Product__r.Item__r.Class__c', 'Product__r.Item__r.Track_Install_Base__c', 'Product__r.Item__r.Source__c',
                              'Quantity_From_Stock__c','Quantity_Available_to_Ship__c','Quantity_Backordered__c','Company__c', 'Company__r.Serial_Control__c', 'Company__r.Use_Warranty_Repairs__c', 'Selling_UOM__r.Name', 'Ship_From_Location__r.Facility__c', 'Ship_From_Location__r.Facility__r.RMA_Receipt_Routing__c',
                              'Product__c','Product__r.Name','Quantity_Ordered__c','Quantity_Shipped__c','Quantity_to_Ship__c','Ship_From_Location__c','Product__r.Item__r.Stocking_UOM__r.Name',
                              'Required_Date__c','Sales_Order__c','Sales_Order__r.Customer__r.Top_Parent_Customer__c','Status__c','Discount_Percent__c',
                              'Unit_Price__c','SystemModStamp','Sales_Order__r.Customer__r.Top_Parent_Customer__r.Status__c','Product__r.Item__r.Track_Install_Base__c',
                              'Product__r.item__r.Container__c','Sales_Order__r.Currency__c','Sales_Order__r.Company__c', 'Sales_Order__r.Status__c', 'Sales_Order__r.Type__c', 'Description__c','Selling_UOM__c','Sales_Order__r.Name',
                              'Ship_From_Location__r.Facility__r.Default_Work_Order_Complete_to_Location__c','Ship_From_Location__r.Facility__r.Default_Work_Order_MRB_Location__c','Product__r.item__r.Stocking_UOM__r.Package_Class__c','Product__r.item__r.Stocking_UOM__r.Package_Class__r.Level__c','Product__r.item__r.Stocking_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c',
                              'Product__r.item__r.Container_Item__c','Product__r.item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Product__r.item__r.Container_Item__c','Product__r.item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Product__r.item__r.Container_Item__r.Container_Package_Class__c',
                              'Product__r.item__r.Container_Item__r.Container_Package_Class__c','Product__r.item__r.Stocking_uom__r.Package_Class__c','Product__r.item__r.Stocking_uom__r.Package_Class__r.Level__c', 'Product__r.item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c','Product__r.Item__r.Container__c','Selling_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
                              'Selling_UOM__r.Package_Class__c','Selling_UOM__r.Package_Class__r.Level__c','Selling_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c','Selling_UOM__r.Package_Class__r.Default_Container_Item__r.Item_attribute__c','Selling_UOM__r.Package_Class__r.Default_Container_Item__r.Item_attribute__r.License_Plate_Number__c','Ship_From_Location__r.Facility__r.Default_Work_Order_WIP_Location__c','Product__r.item__r.Lead_Time__c','Packaging_UOM__c','Product__r.Item__r.Packaging_UOM__c','Packaging_UOM__r.Package_class__r.Level__c',
                              'Ship_From_Location__r.Facility__r.Facility_Identifier__c',
                'Sales_Order__r.Customer__c'
            };
            
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('product__r.item__r.item_attribute__r.','item_attribute__c') );
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('product__r.','product__c') );
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('','sales_order_line__c') );
            //fieldStrings.addAll( util.getAllCustomFieldsFromObject('Ship_From_Facility__r.','Facility__c') );
            fieldStrings.addAll( SkidService3.getStockMovementRuleFields('Sales Order'));
            
            if( headerIds != null ){
                inClause = 'Sales_Order__c IN:headerIds';
            }

            String whereClause = inClause+' and Status__c = \'Open\' and Quantity_Ordered__c < 0';

            SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
            soql.addFields('RMA_Receiving');
            soql.addFields(fieldStrings);
            soql.setWhereClause(whereClause);

            refreshedSObjects.putAll( new Map<id,SObject>(Database.query(soql.getQuery())));
        }
        
         if( docTypes.contains('Receipt_Line__c'.toLowerCase())){
            
            set<String> fieldStrings = new set<string>{'Id','Name', 'Packaging_UOM__r.Name','Packaging_UOM__c','Packaging_UOM__r.Package_Class__c','Packaging_UOM__r.Package_Class__r.Level__c','item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c','Sales_Order_Line__r.Selling_UOM__r.Package_Class__r.Default_Container_Item__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_attribute__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_attribute__r.License_Plate_Number__c','Quantity_Received__c', 'Status__c','Line__c','Item__c','Item__r.Description__c', 'Item__r.Stocking_UOM__c', 'Item__r.Name','Item__r.Class__c', 'Item__r.Non_Inventory__c', 'Item__r.Source__c',
                              'Number_of_Boxes__c','Location__c','Quantity_To_Stock__c','Quantity_Still_Due_For_Putaway__c', 'Company__c', 'Facility__c', 'Location__r.Facility__r.RMA_Receipt_Routing__c','Sales_Order_Line__r.Sales_Order__r.Type__c',
                              'Sales_Order__c','Sales_Order__r.Name','Sales_Order_Line__c','Sales_Order_Line__r.Name', 'Sales_Order_Line__r.Fulfillment_Source__c', 'Sales_Order_Line__r.Returned_To_Vendor__c', 'Sales_Order_Line__r.Related_Sales_Order_Line__c','Sales_Order_Line__r.Related_Sales_Order_Line__r.Fulfillment_Source__c', 'Item__r.Stocking_UOM__r.Name','Company__r.Serial_Control__c','Item__r.Track_Install_Base__c',
                              'Sales_Order_Line__r.Selling_UOM__r.Name','Receiving_Document__c','Receiving_Document__r.Name', 'Receiving_Document__r.Type__c', 'Receiving_Document__r.Transaction_Date__c', 'purchase_order__r.Name', 'purchase_order__c', 'purchase_order__r.Currency__c', 'Sales_Order__c','Sales_Order__r.Customer__r.Top_Parent_Customer__c','Status__c',
                              'Unit_Price__c','Sales_Order__r.Customer__r.Top_Parent_Customer__r.Status__c', 'Receiving_Document__r.Currency__c','Sales_Order__r.Currency__c','Sales_Order__r.Company__c','Sales_Order_Line__r.Product__r.Item__r.Stocking_UOM__c', 'Sales_Order_Line__r.Selling_UOM__c',
							  'Sales_Order_Line__r.Selling_UOM__r.Package_Class__c','Sales_Order_Line__r.Selling_UOM__r.Package_Class__r.Level__c','Sales_Order__r.Status__c', 'Sales_Order__r.Type__c', 'Description__c','Supplier__c','Sales_Order__r.Name','Sales_Order_Line__r.Ship_From_Location__r.Facility__c','Sales_Order_Line__r.Company__c','Sales_Order_Line__r.Packaging_UOM__c',
                              'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c','item__r.Container_Item__c','item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c','item__r.Container_Item__c','item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c','item__r.Container_Item__r.Container_Package_Class__c','item__r.Container_Item__r.Container_Package_Class__c','item__r.Stocking_uom__r.Package_Class__c','item__r.Stocking_uom__r.Package_Class__r.Level__c', 'item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c',
                              'Location__r.Facility__r.Default_Work_Order_Complete_to_Location__c','Location__r.Facility__r.Default_Work_Order_MRB_Location__c','item__r.Packaging_UOM__c','Sales_Order_Line__r.Packaging_UOM__r.Package_class__r.Level__c','Sales_Order_Line__r.Packaging_UOM__r.Package_Class__c ',
                              'Location__r.Facility__r.Default_Work_Order_WIP_Location__c','item__r.Lead_Time__c', 'Company__r.Default_Transaction_Currency__c', 'Item__r.Container__c', 'Sales_Order_Line__r.Ship_From_Location__r.Facility__r.Facility_Identifier__c',
                              'Sales_Order__r.Status__c', 'Sales_Order__r.Type__c', 'Description__c','Supplier__c','Sales_Order__r.Name','Sales_Order_Line__r.Ship_From_Location__r.Facility__c','Sales_Order_Line__r.Company__c','Sales_Order_Line__r.Product__r.Item__r.Packaging_UOM__c', 'Facility__r.Facility_Identifier__c'
                              
            };
            
            fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('sales_order_line__r.product__r.item__r.item_attribute__r.','item_attribute__c') ); 
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('item__r.item_attribute__r.','item_attribute__c') );
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('','receipt_line__c') );
            fieldStrings.addAll( SkidService3.getStockMovementRuleFields('Receiving Document'));
            
            if( headerIds != null ){
                inClause = 'Sales_Order__c IN:headerIds';
            }

             String filterType;
             

            String whereClause = inClause + ' and Quantity_Still_Due_For_Putaway__c > 0';

            
            if(docTypes.contains('Receiving Document'.toLowerCase())){
                whereClause = 'Id IN:lineIds and Status__c != \'Closed\' and Receiving_Document__r.Type__c !=\'RMA Receipt\' and Receiving_Document__r.Type__c !=\'RMA Receipt For Repair\' and Quantity_Still_Due_For_Putaway__c > 0 ';
            }

            SOQLUtil soql = new SOQLUtil('Receipt_Line__c');
            soql.addFields('PutawayReceipts');
            soql.addFields(fieldStrings);
            soql.setWhereClause(whereClause);

            if(includeChildRelationShips){
                SOQLUtil.ChildRelationship woQuery = new SOQLUtil.ChildRelationship(soql,'Work_Orders__r');
                woQuery.addAllCustomFields();
                woQuery.setWhereClause('Status__c = \'Draft\'');
                soql.addChildRelationship(woQuery);
            }
            
            refreshedSObjects.putAll( new Map<id,SObject>(Database.query(soql.getQuery())));
        }
        
        if(docTypes.contains('ASN_Line__c'.toLowerCase())){
            set<String> fieldStrings = new set<string>{'Id', 'Name','company__r.comp_currency__c','company__r.Serial_Control__c','item__c','ASN__r.Name',
                 'Item__r.Container__c','Item__r.Packaging_UOM__c','ASN__r.FOB__r.FOB_Point__c','putaway_location__r.Id','putaway_location__c','Location__r.Facility__c','purchase_order__c','purchase_order__r.supplier__c','purchase_order_line__r.supplier__c','ASN__r.Packing_Slip_Number__c','ASN__r.Number_of_Boxes__c','ASN__r.Tracking_Number__c','ASN__r.Date_Shipped__c',
                 'ASN__r.Currency__c','ASN__r.Carrier__c','purchase_order_line__r.sales_order_line__c','purchase_order_line__r.operation_tracking__c','purchase_order_line__r.work_order__r.assembly_item_specification__c','purchase_order_line__r.delivery_Facility__c','purchase_order_line__r.company__c','purchase_order_line__r.Type__c','purchase_order_line__r.purchase_order__r.Type__c','purchase_order_line__r.need_date__c','purchase_order_line__r.delivery_location__c','purchase_order_line__r.purchase_uom__r.name','unit_price__c', 'purchase_order_line__r.overage_quantity__c','purchase_order__r.fob_term__c',
                 'Purchase_order_line__r.purchase_uom__r.Package_Class__r.Fractional_Quantities_Allowed__c','Purchase_order_line__r.purchase_uom__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Purchase_order_line__r.purchase_uom__r.Package_Class__r.Default_Container_Item__c','item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c','purchase_order_line__r.delivery_location__r.facility__c','purchase_order_line__r.status__c', 'purchase_order_line__r.Order_Quantity__c', 'purchase_order_line__r.Quantity_Still_Due__c','purchase_order_line__r.purchase_order__r.supplier__r.name','Purchase_order_line__r.Purchase_UOM__c',
                 'Purchase_order_line__r.Item_Specification__r.Item__r.Packaging_UOM__c','Purchase_order_line__r.Item_Specification__r.Item__r.Stocking_UOM__c','Purchase_order_line__r.Item_Specification__r.Item__r.Stocking_UOM__r.Package_Class__c','item__r.Item_Attribute__r.License_Plate_Number__c','item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c','item__r.Container_Item__r.Container_Package_Class__c','item__r.class__r.minimum_shelf_life_in_days__c','purchase_order_line__r.item_specification__r.item__r.non_inventory__c','purchase_order_line__r.item_specification__r.item__r.source__c','item__r.non_inventory__c','item__r.stocking_uom__c','item__r.item_attribute__c','purchase_order_line__r.consigned__c','item__r.Stocking_uom__r.name','purchase_order_line__r.purchase_order__r.supplier__c','purchase_order_line__r.item_specification__r.item__r.name',
                 'Purchase_order_line__r.item__r.item_attribute__c','purchase_order_line__r.item__r.packaging_uom__c','purchase_order_line__r.item__r.stocking_uom__c','Item__r.Container_item__c','item__r.item_attribute__r.used__c','item__r.item_attribute__r.rental__c','item__r.item_attribute__r.lot_number__c','item__r.item_attribute__r.date_received__c','item__r.item_attribute__r.expiration_date__c','item__r.item_attribute__r.minimum_shelf_life_in_days__c','item__r.item_attribute__r.serial_number__c','purchase_order_line__c','purchase_order_line__r.quantity_received__c','purchase_order_line__r.purchase_order__r.Approval_Status__c','item__r.source__c','purchase_order_line__r.purchase_order__r.status__c'
                 ,'Purchase_Order_Line__r.Item_Specification__r.item__r.Container_Item__r.Container_Package_Class__c','Purchase_Order_Line__r.Item_Specification__r.item__r.Container_Item__c','item__r.item_attribute__r.Name','item__r.item_attribute__c','item__r.Stocking_UOM__r.Package_Class__c','item__r.Stocking_UOM__r.Package_Class__r.Level__c','Purchase_order_line__r.Purchase_UOM__r.Package_Class__c','Purchase_order_line__r.Purchase_UOM__r.Package_Class__r.Level__c','Purchase_Order_Line__r.Item__r.Container__c','purchase_order_line__r.item_specification__r.item__r.Container__c',
                 'Purchase_Order_Line__r.Item_Specification__r.item__r.Container_Item__r.Item_Attribute__c', 'Purchase_Order_Line__r.Item_Specification__r.item__r.Item_Attribute__c','Purchase_Order_Line__r.Item_Specification__r.item__r.Item_Attribute__r.License_Plate_Number__c',
                 'Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c'
                };
            
            //fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('purchase_order_line__r.item__r.item_attribute__r.','item_attribute__c') );
              fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('item__r.item_attribute__r.','item_attribute__c') );
            //fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('','ASN_Line__c') );
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('purchase_order_line__r.item_specification__r.item__r.item_attribute__r.','item_attribute__c') );
            for( Stock_Movement_Rule_Settings__c smrs : Stock_Movement_Rule_Settings__c.getAll().values() ){
            
                if( smrs.Source_Document__c == 'Purchase Order' ){
                    
                    if( smrs.Source_Document_Path__c == null || smrs.Source_Document_Path_Putaway__c == null ){
                        throw new ReceivingDocumentServiceV2Exception(Label.Source_Document_Path_Fields_Not_Populated);
                    }
                    
                    fieldStrings.add( 'purchase_order_line__r.'+(smrs.Source_Document_Path__c).toLowerCase() );
                    fieldStrings.add( 'purchase_order_line__r.'+(smrs.Source_Document_Path_Putaway__c).toLowerCase() );
                }
            }
           
            //if(subquery != null ){ fieldStrings.add(subquery); }
            if( headerIds != null ){
                inClause = 'ASN__c IN:headerIds';
            }            

            String whereClause = inClause+' and Status__c = \'Open\' and Purchase_Order_Line__r.Quantity_Still_Due__c > 0.0';

            SOQLUtil soql = new SOQLUtil('ASN_Line__c');
            soql.addFields('ASN_Line');
            soql.addFields(fieldStrings);
            soql.setWhereClause(whereClause);
			
            refreshedSObjects.putAll( new Map<id,SObject>(Database.query(soql.getQuery())));
        }
        
        if( docTypes.contains('Order_Line__c'.toLowerCase())){
            
            set<String> fieldStrings = new set<string>{'ID','Name','Shipping_Company__c','Shipping_Item__c','Receiving_Item__c','Receiving_Item__r.Description__c','Receiving_Item__r.Name','Receiving_Item__r.Class__c',
            	 			  'Quantity_To_Receive__c','Order__r.Currency__c','Order__r.Status__c','Receiving_Company__c','Receiving_Company__r.Serial_Control__c','Order__r.Shipping_Company__c','Description__c','packaging_uom__c','packaging_uom__r.name',
            				  'Quantity_Backordered__c','Deliver_To_Location__r.Facility__c','Receiving_Item__r.Item_Attribute__c','putaway_location__r.Id','putaway_location__c',
                              'Quantity_Ordered__c','Quantity_Shipped__c','Ship_From_Location__c','Receiving_Item__r.Item_Attribute__r.Serial_Number__c',
                              'Required_Date__c','Order__c','Status__c','Receiving_Item__r.item_attribute__c','Receiving_Item__r.Non_Inventory__c','Receiving_Item__r.Source__c',
                              'SystemModStamp','Receiving_Item__r.non_inventory__c','Receiving_Item__r.class__r.minimum_shelf_life_in_days__c',
                              'Receiving_Item__r.Packaging_UOM__c','Receiving_Item__r.Container__c','Receiving_Item__r.Stocking_uom__c','Receiving_Item__r.Stocking_uom__r.name','Receiving_Item__r.Stocking_uom__r.Package_Class__c',
                              'Receiving_Item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c','Receiving_Item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
                              'Receiving_Item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
                              'Receiving_Item__r.Container_Item__c','Receiving_Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
                			  'Receiving_Item__r.Container_Item__r.Container_Package_Class__c','Receiving_Item__r.Container_Item__r.Container_Package_Class__c',
                              'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
                              'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Receiving_Item__r.Container_Item__r.item_attribute__c',
                              'Packaging_UOM__c','Packaging_UOM__r.Name','Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__c','Receiving_Item__r.Stocking_uom__r.Package_Class__r.Default_Container_Item__c','Receiving_Item__r.Stocking_uom__r.Package_Class__r.Fractional_Quantities_Allowed__c',
                			  'Packaging_UOM__r.Package_Class__c','Packaging_UOM__r.Package_Class__r.Level__c','Receiving_Item__r.Stocking_uom__r.Package_Class__r.Level__c',
                			  'Deliver_To_Facility__r.Facility_Identifier__c','Ship_From_Facility__r.Facility_Identifier__c', 'Shipping_Item__r.Packaging_UOM__c','Receiving_Item__r.Packaging_UOM__c'};
	            
	            
            fieldStrings.addAll( util.getAllCustomFieldsFromObject('Receiving_Item__r.item_attribute__r.','item_attribute__c') );
            fieldStrings.addAll( SkidService3.getStockMovementRuleFields('Transfer Order'));
           
            //if(subquery != null ){ fieldStrings.add(subquery); }
            if( headerIds != null ){
                inClause = 'Order__c IN:headerIds';
            }  
            
            String whereClause = inClause+' and  Quantity_To_Receive__c > 0';
            
            SOQLUtil soql = new SOQLUtil('Order_Line__c');
            soql.addFields('Order_Receive');
            soql.addFields(fieldStrings);
            soql.setWhereClause(whereClause);
            refreshedSObjects.putAll( new Map<id,SObject>(Database.query(soql.getQuery())));
        }
        return refreshedSObjects;
    }
    
    public static map<String, Integer> populateIcrMinimumShelfLife( set<Id> supplierIds ){
        
         map<String, Integer> icrKeys = new map<String, Integer>();
         
         for( Item_Cross_Reference__c icr : [ SELECT id,Name, Active__c, Approval_Status__c, Item__c, Item__r.Name, Item__r.Approved_Supplier_Required__c,
          Supplier__c, 
          Ship_to_Facility__c, Consigned__c, Minimum_Shelf_Life_In_Days__c 
          FROM Item_Cross_Reference__c where Supplier__c IN:supplierIds and Active__c = true and Approval_Status__c = 'Approved' and Minimum_Shelf_Life_In_Days__c != null]){
            
            
            if( icr.Ship_to_Facility__c == null ){
                icrKeys.put( icr.Supplier__c+','+icr.Item__c, Integer.valueOf(icr.Minimum_Shelf_Life_In_Days__c) );
            }
            else{
                icrKeys.put( icr.Supplier__c+','+icr.Item__c+','+icr.Ship_to_Facility__c, Integer.valueOf(icr.Minimum_Shelf_Life_In_Days__c) );
            }
            
        }
        
        return icrKeys;
    }
    
    public static void calculateMinimumShelfLife( receivingWrapper rw, map<String, Integer> icrKeys ){
        
        if( rw.pol!= null && icrKeys.containsKey( rw.pol.get('Supplier__c')+','+rw.item.id+','+rw.pol.get('Delivery_Facility__c') ) )
            rw.minimumShelfLife = icrKeys.get(rw.pol.get('Supplier__c')+','+rw.item.id+','+rw.pol.get('Delivery_Facility__c'));
        else if( icrKeys.containsKey( rw.pol.get('Supplier__c')+','+rw.item.id ) )
            rw.minimumShelfLife = icrKeys.get(rw.pol.get('Supplier__c')+','+rw.item.id);  
        else if( rw.item.getSObject('Class__r') != null && rw.item.getSObject('Class__r').get('Minimum_Shelf_Life_In_Days__c') != null )
            rw.minimumShelfLife = Integer.valueOf(rw.item.getSObject('Class__r').get('Minimum_Shelf_Life_In_Days__c'));
        else
            rw.minimumShelfLife = 0;    
    }
    
    
    public static UOM__c getPkgUOMObj(Item__c itemObj,UOM__c stockingUOM, UOM__c lineUOM, String key,SObject pol,String objName){
    	Set<Id> pkgUOMSetIds = new Set<Id>();
        UOM__c uomObj = new UOM__c();
       
    	pkgUOMSetIds = (set<Id>)JSON.deserialize(String.valueOf(itemObj.get('Packaging_UOM__c')), set<Id>.Class);
    	if(!pkgUOMSetIds.contains(key)){
			if(stockingUOM !=null)
				uomObj = stockingUOM;
			
		}
		else if(pkgUOMSetIds.contains(key)){
			if(lineUOM !=null)
				uomObj = lineUOM;
		}
		
		if(!String.isBlank(objName) && objName == 'ASN_Line__c' && pol !=null && pol.getSObject('Purchase_Order__r').get('Type__c') == 'SubContract'){
			UOM__c tempUOM = new UOM__c(Id=uomObj.Id);
			uomObj = tempUOM;
		}
		
		return uomObj;
    } 
    
    
    public static list<ReceivingWrapper> getReceivingLines( set<Id> headerIds, set<Id> lineIds, set<String> docTypes ){
        
        list<ReceivingWrapper> rwList = new List<ReceivingWrapper>();
        
        try{
            map<Id, SObject> rLines = new map<Id,SObject>();
            Boolean asnFlag = false;
            /*if(docTypes.contains('ASN_Line__c') || docTypes.contains('asn_line__c')){
                asnFlag = true;
             }*/
            if(headerIds != null){
                //rLines = queryLines( headerIds, null, docTypes, false);
                rLines = queryLinesfordisplay( headerIds, null, docTypes,false);  
            }
            else{
                //rLines = queryLines( null, lineIds, docTypes,false);   
                rLines = queryLinesfordisplay( null, lineIds, docTypes,false);         
            }
            
            if( rLines.size() == 0 ){
                throw new ReceivingDocumentServiceV2Exception(Label.No_Lines_For_Receiving);
            }
            
            Set<Id>asnlineIds = new Set<Id>();
            Set<Id>solLineIds = new Set<Id>();
            Set<Id>tolLineIds = new Set<Id>();
            
            Boolean serialTracked = false;
            
            for( SObject rl : rLines.values() ){
            	    
                    if(rl.getSObjectType() == ASN_Line__c.sObjectType || rl.getSObjectType() == Purchase_Order_Line__c.sObjectType){
                        if(rl.getSObject('Item__r') != null && rl.getSObject('Item__r').get('Item_Attribute__c')!= null && 
                            rl.getSObject('Item__r').getSObject('Item_Attribute__r') != null &&
                            (Boolean)rl.getSObject('Item__r').getSObject('Item_Attribute__r').get('Serial_Number__c')
                            && rl.getSObject('Company__r').get('Serial_Control__c') == 'At receipt and all processes'){
                            
                                serialTracked = true;
                        }  
                    }
                  
                    if(rl.getSObjectType() == ASN_Line__c.sObjectType){
                        asnlineIds.add(rl.Id);
                    }
                
                    if(rl.getSObjectType() == Sales_Order_Line__c.sObjectType){
                            if(rl.getSObject('Ship_From_Location__r').getSObject('Facility__r').get('RMA_Receipt_Routing__c') == 'Inspect')
                                    RMAReceiptRouting = 'Inspect';
                 
                    }

                    if( rl.getSObjectType() == Receipt_Line__c.sObjectType && (Id)rl.get('Sales_Order_Line__c') != null ){
                            solLineIds.add((Id)rl.get('Sales_Order_Line__c'));
                    }
                    if( rl.getSObjectType() == Order_Line__c.sObjectType){
                            tolLineIds.add(rl.Id);
                    }

                 
            }

            map<Id,List<SKID__c>> lineskidmap = new map<Id,List<SKID__c>>();
            Map<Id,List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
            Set<String> additionalfields;
            if (asnLineIds.size() > 0 || solLineIds.size() > 0 || tolLineIds.size()>0) {

                SOQLUtil skidQuery = new SOQLUtil('SKID__c');
                skidQuery.addAllCustomFields();
                skidQuery.addFields(new set<String>{'Purchase_Order_Line__r.Consigned__c','Mixed_Palletized__c','License_Plate_Number__c','Stocking_UOM__c','Item__r.Stocking_UOM__c','item__r.Container_Item__c','Item__r.Container_Item__r.Container_Package_Class__c', 'Facility2__r.Facility_Identifier__c',
                                                'Container_Item__c','Container_Item__r.Name','Container_Item__r.Container_Package_Class__c','Packaging_UOM__r.Package_Class__c','Container_Item__r.Container_Package_Class__r.Level__c',
                                                'Packaging_UOM__r.Name','Packaging_UOM__r.Package_Class__r.Level__c','Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c','Packaging_UOM__r.Package_Class__r.Default_Container_Item__c','Item__r.Packaging_UOM__c','Packaging_UOM__c'});
                additionalfields = new Set<String>{'id','Name','SKID__c','Company__c','Item__c', 'Skid__r.ASN_Line__c','Skid__r.Sales_Order_Line__c' };
                
                

                skidQuery.setWhereClause('(ASN_Line__c IN :asnLineIds AND (Type__c = \'' + SkidService3.SKID_TYPE_INTRANSIT + '\' OR Type__c = \'' + 'Draft In-Transit' + '\')) OR (Sales_Order_Line__c IN :solLineIds AND Type__c = \'' + SkidService3.SKID_TYPE_INSTALLBASE + '\') OR (Order_Line__c IN :tolLineIds AND Type__c = \'' + SkidService3.SKID_TYPE_INTRANSIT + '\')');


                Map<Id,SKID__c> skidList = new Map<Id,SKID__c>((List<SKID__c>)Database.query(skidQuery.getQuery()));
                Set<Id> skidIds = skidList.keySet();
                //Set<String> additionalfields = new Set<String>{'id','Name','SKID__c','Company__c','Item__c', 'Skid__r.ASN_Line__c','Skid__r.Sales_Order_Line__c' };
                for( String serAttr : SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'Serial_Attributes') ){
                	additionalfields.add(serAttr); 
			    }
                
                SOQLUtil serialQuery = new SOQLUtil('Serial__c');
                serialQuery.addFields(additionalfields);
			    serialQuery.setWhereClause('SKID__c IN :skidIds ');
			    
			    for (Serial__c serial:Database.query(serialQuery.getQuery())) {
		    	    if (!serialMap.containsKey(serial.SKID__c)) {
                        serialMap.put(serial.SKID__c,new List<Serial__c>());
                    }
                    serialMap.get(serial.SKID__c).add(serial);
			    }
			    
                for (SKID__c skid: skidList.values() ) {
                    if (skid.ASN_Line__c != null) {
                        if (!lineSkidMap.containsKey(skid.ASN_Line__c)) {
                            lineSkidMap.put(skid.ASN_Line__c,new List<SKID__c>());
                        }
                        lineSkidMap.get(skid.ASN_Line__c).add(skid);
                    } else if (skid.Sales_Order_Line__c != null) {
                        if (!lineSkidMap.containsKey(skid.Sales_Order_Line__c)) {
                            lineSkidMap.put(skid.Sales_Order_Line__c,new List<SKID__c>());
                        }
                        lineSkidMap.get(skid.Sales_Order_Line__c).add(skid);
                    
                    }
                    else if(skid.Order_Line__c != null){
                    	if (!lineSkidMap.containsKey(skid.Order_Line__c)) {
                            lineSkidMap.put(skid.Order_Line__c,new List<SKID__c>());
                        }
                        lineSkidMap.get(skid.Order_Line__c).add(skid);
                    }
                }

             }


            
            map<Id, SObject> linesForComputing = new map<Id,SObject>(); // same map as rlines except for ASN's as ASN needs the poLines for computing values and not the ASN Line
            set<Id> supplierIds = new set<Id>();
            list<String> attributes = new list<String>(Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c'));
            
            Map<Id, List<SKID__c>> inTransitSKidmap = new Map<Id, List<SKID__c>>();
            map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
            Map<Id,Id> lineUOMmap = new Map<Id,Id>();
            
            for( SObject rl : rLines.values() ){
                Purchase_Order_Line__c pol;
                UOM__c uomObj = new UOM__c();
                if(rl.getSObjectType() == ASN_Line__c.sObjectType){
                    linesForComputing.put( rl.id, rl.getSObject('Purchase_Order_Line__r'));
                    inTransitSKidmap.put(rl.id, lineskidmap.get(rl.id));
                }
                else if(rl.getSObjectType() == Order_Line__c.sObjectType){
                    linesForComputing.put( rl.id, rl);
                    inTransitSKidmap.put(rl.id, lineskidmap.get(rl.id));
                }
                else{
                    linesForComputing.put( rl.id, rl);
                    if(rl.getSObjectType() == Receipt_Line__c.sObjectType && lineskidmap.containsKey((Id)rl.get('Sales_Order_Line__c'))){
                        inTransitSKidmap.put(rl.id, lineskidmap.get((Id)rl.get('Sales_Order_Line__c')));
                    }
                }
                
                    
                if(skipPutaway != true && rl.getSObjectType() == Sales_Order_Line__c.sObjectType && RMAReceiptRouting == 'Inspect'){
                    skipPutaway = true;
                }
                Set<Id> pkgUOMSetIds = new Set<Id>();
                    
                if(rl.getSObjectType() == Sales_Order_Line__c.sObjectType || rl.getSObjectType() == Receipt_Line__c.sObjectType){
                	
	    			Item__c itemObj;
	    			UOM__c stockingUOM = new UOM__c();
	    			UOM__c sellingUOM = new UOM__c();
	    			String key;
	    			UOM__c pkgUOMObj = new UOM__c();
	    			
	    			if(rl.getSObjectType() == Sales_Order_Line__c.sObjectType){
	    				itemObj = (Item__c)rl.getSObject('Product__r').getSObject('Item__r');
	    				key = String.valueOf(rl.get('Selling_UOM__c'));
	    				sellingUOM = (UOM__c)rl.getSObject('Selling_UOM__r');
	    				if(itemObj.getSObject('Stocking_UOM__r') !=null){
			    			stockingUOM = (UOM__c)itemObj.getSObject('Stocking_UOM__r');
		    			}
	    			}
	    			else if(rl.getSObjectType() == Receipt_Line__c.sObjectType){
	    				itemObj = (Item__c)rl.getSObject('Item__r');
	    				if(rl.getSObject('Receiving_Document__r').get('Type__c') != 'Miscellaneous Receipt'){
	    					key = String.valueOf(rl.getSObject('Sales_Order_Line__r').get('Selling_UOM__c'));
		    				if(rl.getSObject('Sales_Order_Line__r').getSObject('Selling_UOM__r') !=null){
			    				sellingUOM = (UOM__c)rl.getSObject('Sales_Order_Line__r').getSObject('Selling_UOM__r');
			    			}
			    			if(itemObj.getSObject('Stocking_UOM__r') !=null){
			    				stockingUOM = (UOM__c)itemObj.getSObject('Stocking_UOM__r');
			    			}
	    				}
	    				else if(rl.getSObject('Receiving_Document__r').get('Type__c') == 'Miscellaneous Receipt'){
	    					key = String.valueOf(rl.get('Packaging_UOM__c'));
		    				if(rl.getSObject('Packaging_UOM__r') !=null){
			    				sellingUOM = (UOM__c)rl.getSObject('Packaging_UOM__r');
			    			}
	    				}
	    				
	    			}
	    			
	    			pkgUOMObj = getPkgUOMObj(itemObj,stockingUOM,sellingUOM,key,null,null);
	    			
	    			if(pkgUOMObj !=null){
	    				if(!itemsWithPackagingUOM.containskey(itemObj)){
							itemsWithPackagingUOM.put(itemObj,new Set<UOM__c>{});	
						}
						itemsWithPackagingUOM.get(itemObj).add(pkgUOMObj);	
						lineUOMmap.put(rl.Id,pkgUOMObj.Id);
	    			}
	    			
                }
                
                if(rl.getSObjectType() != Order_Line__c.sObjectType && rl.getSObjectType() != Sales_Order_Line__c.sObjectType && rl.getSObjectType() != Receipt_Line__c.sObjectType){
                    supplierIds.add((Id)rl.getSObject('Purchase_Order__r').get('Supplier__c'));
                    
                    Item__c itemObj = (Item__c)rl.getSObject('Item__r');
                    UOM__c stockingUOM = new UOM__c();
	    			UOM__c purchaseUOM = new UOM__c();
	    			String key;
	    			UOM__c pkgUOMObj = new UOM__c();
                    
                    if(rl.getSObjectType() == Purchase_Order_Line__c.sObjectType){
                    	pol = (Purchase_Order_Line__c) rl;
                    }
                    else if(rl.getSObjectType() == ASN_Line__c.sObjectType){
                    	pol = (Purchase_Order_Line__c) rl.getSObject('Purchase_Order_Line__r');
                    }
                
                    if(pol.Purchase_Order__r.Type__c == 'SubContract'){
                		itemObj = (Item__c)pol.getSObject('Item_Specification__r').getSObject('Item__r');
                	}
	    				
	    			key = String.valueOf(pol.get('Purchase_UOM__c'));
	    			if(itemObj.getSObject('Stocking_UOM__r') !=null){
	    				stockingUOM = (UOM__c)itemObj.getSObject('Stocking_UOM__r');
	    			}
	    		    if(pol.getSObject('Purchase_UOM__r') !=null){
	    				purchaseUOM = (UOM__c)pol.getSObject('Purchase_UOM__r');
	    			}
	    			string objectName = rl.getSObjectType().getDescribe().getLocalName();
	    			pkgUOMObj = getPkgUOMObj(itemObj,stockingUOM,purchaseUOM,key,pol,objectName);
	    			
	    			if(pkgUOMObj !=null){
		    			if(!itemsWithPackagingUOM.containskey(itemObj)){
		    				itemsWithPackagingUOM.put(itemObj,new Set<UOM__c>{});	
		    			}
						itemsWithPackagingUOM.get(itemObj).add(pkgUOMObj);	
						lineUOMmap.put(rl.Id,pkgUOMObj.Id);
	    			}
                    
                }
                
                if(rl.getSObjectType() == Order_Line__c.sObjectType){
                	
                	Item__c itemObj = (Item__c)rl.getSObject('Receiving_Item__r');
                    UOM__c stockingUOM = new UOM__c();
	    			UOM__c packagingUOM = new UOM__c();
	    			String key;
	    			UOM__c pkgUOMObj = new UOM__c();
                    
                    
	    			key = String.valueOf(rl.get('Packaging_UOM__c'));
	    			if(itemObj.getSObject('Stocking_UOM__r') !=null){
	    				stockingUOM = (UOM__c)itemObj.getSObject('Stocking_UOM__r');
	    			}
	    		    if(rl.getSObject('Packaging_UOM__r') !=null){
	    				packagingUOM = (UOM__c)rl.getSObject('Packaging_UOM__r');
	    			}
	    			string objectName = rl.getSObjectType().getDescribe().getLocalName();
	    			pkgUOMObj = getPkgUOMObj(itemObj,stockingUOM,packagingUOM,key,null,null);
	    			
	    			if(pkgUOMObj !=null){
		    			if(!itemsWithPackagingUOM.containskey(itemObj)){
		    				itemsWithPackagingUOM.put(itemObj,new Set<UOM__c>{});	
		    			}
						itemsWithPackagingUOM.get(itemObj).add(pkgUOMObj);	
						lineUOMmap.put(rl.Id,pkgUOMObj.Id);
	    			}
                }
                if(!skipPutaway){
                    rl.put('Putaway_Location__c',null);
                    rl.putSObject('Putaway_Location__r',null);
                }
                
            }
            
            map<String, Integer> icrKeys = populateIcrMinimumShelfLife(supplierIds);
            map<String, List<Location__c> > locationsByHeader = new map<String, List<Location__c> >();
            
            try{
                if(!skipPutaway){
                    locationsByHeader = SkidService3.locationsFromStockMovementRules( linesForComputing.values(), 'Putaway',docTypes, null,null);
                }
            }
            catch(Exception e){
                //stock movement rules are not mandatory for putaways, so just adding a warning message!
                ExceptionService.addMessage(ApexPages.Severity.WARNING.name(),e.getMessage(),e.getMessage());
            }
            
            map<Id, map<Id, Item__c>> containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
            for(  SObject rl : rLines.values() ){
                
                String sObjType = String.valueOf(rl.getSObjectType()).replace(KSE.namespaceUU,'');
                SObject headerRecord;
                Item__c item;
                Item__c assemblyitem;
                
                if( locationsByHeader.containsKey((Id)linesForComputing.get(rl.id).id) && locationsByHeader.get((Id)linesForComputing.get(rl.id).id).size() > 0 ){
                    rl.put('Putaway_Location__c',locationsByHeader.get((Id)linesForComputing.get(rl.id).id)[0].id);
                    rl.putSObject('Putaway_Location__r',(Location__c)locationsByHeader.get((Id)linesForComputing.get(rl.id).id)[0]);
                }
                
                Purchase_Order_Line__c pol;
                
                if(rl.getSObjectType() == Sales_Order_Line__c.sObjectType){
                    headerRecord = rl.getSObject('Sales_Order__r');
                    item = (Item__c)rl.getSObject('Product__r').getSObject('Item__r');
                }
                else if(rl.getSObjectType() == Receipt_Line__c.sObjectType){
                    headerRecord = rl.getSObject('Receiving_Document__r');
                    item = (Item__c)rl.getSObject('Item__r');
                }
                else if(rl.getSObjectType() != Order_Line__c.sObjectType){
                    pol = (Purchase_Order_Line__c) linesForComputing.get(rl.id);
                    headerRecord = (SObject)pol.Purchase_Order__r;
                    item = (Item__c)rl.getSObject('Item__r');
                    if(pol.Purchase_Order__r.Type__c == 'SubContract'){
                        assemblyitem = (Item__c)pol.getSObject('Item_Specification__r').getSObject('Item__r');
                        
                    }
                }
                else{
                    headerRecord = rl.getSObject('Order__r');
                    item = (Item__c)rl.getSObject('Receiving_Item__r');
                }
                
                if(rl.getSObjectType() != Receipt_Line__c.sObjectType)
                    checkLoadErrors(rl, pol, headerRecord);
                
                List<String> trackedAttributes = new List<String>(); 
               	Item__c containerItem = new Item__c();
                    Set<String> attributeSet = new Set<String>();
                    Id itemId = item.Id;
                if(!skipPutaway){
                    
                    if(assemblyitem !=null){
                    	itemId = assemblyitem.Id;
                    }
                    
                    if(containersByItem.containskey(itemId))
                    	containerItem = containersByItem.get(itemId).get(lineUOMmap.get(rl.Id));
                    
                    if(assemblyitem != null){
                        attributeSet.addAll(SkidService3.trackedAttributes(attributes,(Location__c)rl.getSObject('Putaway_Location__r'),assemblyitem,containerItem));//TO DO container Item
                    }
                    else{
                        attributeSet.addAll(SkidService3.trackedAttributes(attributes,(Location__c)rl.getSObject('Putaway_Location__r'),item,containerItem));//,containerItem
                    }
                    
                    
                    if (pol != null && pol.Purchase_Order__r != null && pol.Purchase_Order__r.Type__c == 'Drop Ship'){
                        attributeSet.remove('Bin__c');
                    }
                    
                    if (rl.getSObjectType() == Sales_Order_Line__c.sObjectType && (String)rl.getSObject('Sales_Order__r').get('Type__c') == 'RMA-Customer-Repair') trackedAttributes.add('Customer__c');
                    trackedAttributes.addAll(new List<String>(attributeSet));
                }
                else if(skipPutaway && rl.getSObjectType() == Receipt_Line__c.sObjectType){
                    if(containersByItem.containskey(itemId))
                    	containerItem = containersByItem.get(itemId).get(lineUOMmap.get(rl.Id));
                    
                    
                   	attributeSet.addAll(SkidService3.trackedAttributes(attributes,(Location__c)rl.getSObject('Putaway_Location__r'),item,containerItem));//,containerItem
                   	trackedAttributes = new List<String>(attributeSet);
                    
                }
       
                //Pass Map of ASNLine and List of SKIDs 
                List<SkidService3.serialWrapper> swlist = createSerialWrapper(rl, pol, trackedAttributes, inTransitSKidmap, serialMap);
                ReceivingWrapper rw = new ReceivingWrapper( rl, pol, item,trackedAttributes, headerRecord, swlist);
                if(rw.lineType == 'Purchase_Order_Line__c' || rw.lineType == 'ASN_Line__c'){
                	rw.rcl = new Receipt_Line__c(Item__c = rw.item.id, Supplier__c = rw.pol.Purchase_Order__r.Supplier__c, Purchase_Order_Line__c = rw.pol.id, Status__c = 'Closed',
                        	 putaway_location__c = (id)rw.rl.get('Putaway_Location__c'),
                        	 Purchase_Order__c = rw.pol.Purchase_Order__c, Location__c = rw.pol.Delivery_Location__c,Facility__c = rw.pol.Delivery_Location__r.Facility__c );   
            
                }
                else if(rw.lineType == 'Sales_Order_Line__c'){
                	rw.rcl = new Receipt_Line__c( Item__c = rw.item.id, Sales_Order_Line__c = (Id)rw.rl.id, Sales_Order__c = (Id)rw.rl.get('Sales_Order__c'), Status__c = 'Closed', 
                    		 Location__c = (Id)rw.rl.get('Ship_From_Location__c'), Facility__c = (Id)rw.rl.getSObject('Ship_From_Location__r').get('Facility__c')); 
        
                }
                else if(rw.lineType == 'Order_Line__c'){
                	rw.rcl = new Receipt_Line__c( Item__c = rw.item.id, Order_Line__c = (Id)rw.rl.id, Order__c = (Id)rw.rl.get('Order__c'), Status__c = 'Closed',
                              putaway_location__c = (id)rw.rl.get('Putaway_Location__c'), Location__c = (Id)rw.rl.get('Deliver_To_Location__c'), Facility__c = (Id)rw.rl.get('Deliver_To_Facility__c'));
                }
				
				
                if(!skipPutaway && (rw.lineType != 'Receipt_Line__c' && rw.lineType != 'Sales_Order_Line__c' && rw.lineType != 'Order_Line__c'))
                    calculateMinimumShelfLife(rw, icrKeys);
                if(rw.lineType == 'Sales_Order_Line__c' && RMAReceiptRouting == ''){
                    rw.putawayType = 'Inventory';
                }
                
                if(rw.serialWrapperList.size() > 0){
                	SKID__c sk = rw.serialWrapperList[0].skid;
                	sk.Input_Quantity__c = rw.conversionFactor;
                }
                    
                rwList.add(rw);
            }
        }
        catch(Exception e){
            
            throw e;
        }
        return rwList;
    }
    
    public static List<SkidService3.SerialWrapper> createSerialWrapper(SObject rl, Purchase_Order_Line__c pol, list<String> trackedAttributes, Map<Id,List<SKID__c>> intransitmap, Map<Id,List<Serial__c>> serialMap){
        
        List<SkidService3.SerialWrapper> serialwrapperlist = new List<SkidService3.SerialWrapper>();
        Id rlineId = rl.Id;
        List<Serial__c> serialList = new List<Serial__c>();
        SkidService3.SerialWrapper serialwrapper;
        
        List<SKID__c> skidlist = new List<SKID__c>();         
        if(intransitmap.values().size() > 0 && intransitmap.containskey(rl.Id)){
            skidlist = intransitmap.get(rl.Id);
        }
        
        Boolean consigned = false;
       
        if(skidlist !=null && skidlist.size() > 0){
        
            for(SObject sk: skidlist){   
                Id companyId;
                Item__c itemObj;
                if(rl.getSObjectType().getDescribe().getLocalName() == 'Order_Line__c'){
                 	companyId = (Id)rl.get('Receiving_Company__c');
                 	itemObj = (Item__c)rl.getSObject('Receiving_Item__r');
                }
                else{
                	companyId = (Id)rl.get('Company__c');
                	itemObj = (Item__c)rl.getSObject('Item__r');
                }
                	
                if((Id)sk.get('Consigned_Owner__c') != null && consigned == false){
                    consigned = true;
                    trackedAttributes.add('Consigned_Owner__c');
                }
                SKID__c skid = new SKID__c( Company__c = companyId,Facility2__c = (Id)sk.get('Facility2__c'),  Item__c = itemObj.Id, Quantity__c = (Decimal)sk.get('Quantity__c'));
                skid.putSObject('Item__r', itemObj); 
                if(sk.get('Mixed_Palletized__c')==true && rl.getSObjectType().getDescribe().getLocalName() == 'Order_Line__c'){
                    skid.put('Mixed_Palletized__c', sk.get('Mixed_Palletized__c'));
                }
                
                if(sk.get('Container_Item__c') !=null){
                	
                	skid.put('Container_Item__c', (Id)sk.get('Container_Item__c'));
                	if(sk.getSObject('Container_Item__r') !=null)
                		skid.putSObject('Container_Item__r', (Item__c)sk.getSObject('Container_Item__r'));
                }          
                //Copy attributes
                skid = copySKidAttributes( rl, pol, skid, sk, trackedAttributes);
                
                 if((pol != null && pol.purchase_order__r.type__c == 'SubContract' && pol.getSObject('Item_Specification__r').getSObject('Item__r').get('Item_Attribute__c')!= null && (Boolean)pol.getSObject('Item_Specification__r').getSObject('Item__r').getSObject('Item_Attribute__r').get('Serial_Number__c')) || itemObj.get('Item_Attribute__c')!= null && (Boolean)itemObj.getSObject('Item_Attribute__r').get('Serial_Number__c')){
                    Serial__c ser = new Serial__c();
                    
                    //serialList = sk.getSObjects('Serials__r').clone();
                    if ( serialMap.containsKey(sk.Id) ) {
                    	serialList.addAll( serialMap.get(sk.Id));
                    }
                    if(serialList.size()==0)
                		serialList.add(ser);
               
                    
                }
                
                serialwrapper = new SkidService3.SerialWrapper(skid, serialList);
                serialwrapperlist.add(serialwrapper);
            }
        } else {
            Id companyId;
            Item__c item;
            SKID__c skid = new SKID__c();
            if (rl.getSObjectType().getDescribe().getLocalName() == 'Sales_Order_Line__c') {
                companyId = (Id)rl.get('Company__c');
                item = (Item__c)rl.getSObject('Product__r').getSObject('Item__r');
                if ((String)rl.getSObject('Sales_Order__r').get('Type__c') == 'RMA-Customer-Repair') {
                    skid.Customer__c = (Id)rl.getSObject('Sales_Order__r').get('Customer__c');
                    skid.Customer__r = (Customer__c)rl.getSObject('Sales_Order__r').getSObject('Customer__r');
                }
            } else if (rl.getSObjectType().getDescribe().getLocalName() == 'Order_Line__c') {
                companyId = (Id)rl.getSObject('Order__r').get('Receiving_Company__c');
                item = (Item__c)rl.getSObject('Receiving_Item__r');
            } else{
                companyId = (Id)rl.get('Company__c');
                item = (Item__c)rl.getSObject('Item__r');
            }
            
            skid.Company__c = companyId;
            skid.Item__c = item.Id;
            skid.Item__r = item;
            skid.Quantity__c = item.Non_Inventory__c == true && rl.getSObjectType().getDescribe().getLocalName() == 'ASN_Line__c' ? (Decimal)rl.get('Quantity_Shipped__c') : 0;
            if (new Set<String>(trackedAttributes).contains('Date_Received__c')) skid.Date_Received__c = System.today();
            copySkidAttributes(rl, pol, skid, null, trackedAttributes);

            if (item.Item_Attribute__c != null && item.Item_Attribute__r.Serial_Number__c) serialList.add(new Serial__c());
            
            serialwrapperlist.add(new SkidService3.SerialWrapper(skid, serialList));
        }
        
        return serialwrapperlist;
    }
    
    public static void checkLoadErrors(SObject rl, Purchase_Order_Line__c pol, SObject headerRecord){
                       
        if (headerRecord.get('Status__c') != 'Open') {
            throw new ReceivingDocumentServiceV2Exception(Label.Order_Not_Open +headerRecord.get('Name'));
        }
        
        if (pol != null && headerRecord.get('Approval_Status__c') != 'Approved') {
            throw new ReceivingDocumentServiceV2Exception(Label.Purchase_order_is_not_approved+' : '+headerRecord.get('Name'));
        }
        
        if (pol!= null && pol.get('Status__c') != 'Open') {
            throw new ReceivingDocumentServiceV2Exception(Label.Purchase_order_line_is_not_open +pol.get('Name'));
        }
    }
    
    //checks user errors and throws exceptions if it finds any errors.
    //If there are no errors, it collects all the lots that need to be created and returns the list.
    public static List<receivingWrapper> checkUserErrors(List<receivingWrapper> rlWrapperList) { 
        map<Id,UOM__c> packagingUOMMap = new map<Id, UOM__c>();
        set<Id> packagingUOMSet = new set<Id>();
        map<Id,sObject> transitLineIds = new map<Id,sObject>(); //used to check for in-transit skids if fob is origin
        List<receivingWrapper> refreshedWrapperList = new List<receivingWrapper>(rlWrapperList);
        map<String, List<Location__c> > wOPickLocation = new map<String, List<Location__c> >();
        list<Material_Tracking__c> material = new list<Material_Tracking__c>();
      	map<String,LPN__c> lpnMap = new map<String,LPN__c>();
        Map<Id, List<Id>> itemPackagingUoms = new Map<Id, List<Id>>();
        try{
            Boolean anyQuantityEntered = false;
            map<Id, Decimal> totalQuantityMap = new map<Id, Decimal>();
            set<String> docTypes = new set<String>();
            set<Id> lineIds = new set<Id>();
            
            for( receivingWrapper rw : refreshedWrapperList ){
                lineIds.add(rw.rl.id);
                docTypes.add(rw.lineType.toLowerCase());
                
                for(Integer i=0;i<rw.trackedAttributes.size();i++){
                	if(rw.trackedAttributes[i].tolowercase() == 'Consigned_Owner__c'.tolowercase()){
                		rw.trackedAttributes.remove(i);
                	}
                }
                if (rw.headerRecord.getSobjectType().getDescribe().getLocalName() == 'Sales_Order__c') {
                    Sales_Order__c salesOrder = (Sales_Order__c) rw.headerRecord;
                    docTypes.add(salesOrder.Type__c.toLowerCase());
                }
                if (rw.rl.getSobjectType().getDescribe().getLocalName() == 'Receipt_Line__c') {
                    Receipt_Line__c receiptLine = (Receipt_Line__c) rw.rl;
                    if( receiptLine.Sales_Order__c != null && (String) rw.rl.getSObject('Receiving_Document__r').get('Type__c') != RD_TYPE_RETURN ){
                        docTypes.add(receiptLine.Sales_Order__r.Type__c.toLowerCase());
                    }
                    else{
                        docTypes.add('Receiving Document'.toLowerCase());
                    }
                }
                if(rw.lineType == 'Sales_Order_Line__c'){
                    if(rw.rl.getSObject('Ship_From_Location__r').getSObject('Facility__r').get('RMA_Receipt_Routing__c') == 'Inspect')
                        {
                            RMAReceiptRouting = 'Inspect';
                        }
                 }
                if(skipPutaway != true && rw.lineType == 'Sales_Order_Line__c' && RMAReceiptRouting == 'Inspect'){
                    skipPutaway = true;
                }
                
                for(SkidService3.serialWrapper sw : rw.serialWrapperList){
                	if (sw.skid.License_Plate_Number__c == null && sw.skid.Temporary_LPN_Holder__c != null) lpnMap.put(sw.skid.Temporary_LPN_Holder__c, new LPN__c(Name = sw.skid.Temporary_LPN_Holder__c));
                	
                	if(sw.skid.Packaging_UOM__r == null || (sw.skid.Packaging_UOM__r !=null && sw.skid.Packaging_UOM__r.Package_Class__r == null)){
                        
                        packagingUOMSet.add(sw.skid.Packaging_UOM__c);
                    }
                }
            }
            lpnMap = lpnMap.size() > 0 ? SkidService3.createLPNs(lpnMap) : new Map<String, LPN__c>();
            if( packagingUOMSet.size() > 0 ){
	            SOQLUtil uomQuery = new SOQLUtil('UOM__c');
	            uomQuery.addFields(new set<String>{'Id','Name','Package_Class__c','Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Package_Class__r.Default_Container_Item__c',
	                'Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Package_Class__r.Fractional_Quantities_Allowed__c'
	            });
	            uomQuery.addAllCustomFields(Package_Class__c.sObjectType,'Package_Class__r');
	            uomQuery.setWhereClause('Id IN :packagingUOMSet');
	            packagingUOMMap = new map<Id,UOM__c>((list<UOM__c>) Database.Query(uomQuery.getQuery()));
	        }
            
            map<Id,SObject> refreshedSObjects = queryLines( null, lineIds, docTypes, true);
            map<Id, SObject> polinesmap = new map<Id,SObject>(); // same map as rlines except for ASN's as ASN needs the poLines for computing values and not the ASN Line
            
            String lineType;
            Map<Id,Set<Id>> worderOpIdsmap = new Map<Id,Set<Id>>();
            for( SObject rl : refreshedSObjects.values() ){
            	Id woKey;
            	Id opId;
		    	Boolean repairWO = false;
		    	if(rl.getSObjectType() == Purchase_Order_Line__c.sObjectType){
					woKey = (Id)rl.get('Work_Order__c');
					opId = (Id)rl.get('Operation_Tracking__c');
					if(rl.getSObject('Work_Order__r') != null && rl.getSObject('Work_Order__r').get('Type__c') == 'Repair')
						repairWO = true;
					
		    	}
            	
            	if(rl.getSObjectType() == ASN_Line__c.sObjectType && rl.getSObject('Purchase_Order_Line__r').getSObject('Purchase_Order__r').get('Type__c') == 'SubContract'){
            	  material.add( (Material_Tracking__c)rl.getSObject('Purchase_Order_Line__r').getSObject('Material_Tracking__r'));//--KNDY-15208  
            	} 
            	else if(rl.getSObjectType() == Purchase_Order_Line__c.sObjectType && rl.getSObject('Purchase_Order__r').get('Type__c') == 'SubContract' ){
            	   material.add( (Material_Tracking__c)rl.getSObject('Material_Tracking__r')); 
            	}
            	
            	if(rl.getSObjectType() == ASN_Line__c.sObjectType){
	                polinesmap.put( rl.id, rl.getSObject('Purchase_Order_Line__r')); 
	                woKey = (Id)rl.getSObject('Purchase_Order_Line__r').get('Work_Order__c');
	                opId = (Id)rl.getSObject('Purchase_Order_Line__r').get('Operation_Tracking__c');
	                
					if(rl.getSObject('Purchase_Order_Line__r').getSObject('Work_Order__r') != null && rl.getSObject('Purchase_Order_Line__r').getSObject('Work_Order__r').get('Type__c') == 'Repair')
						repairWO = true;
	            }
	            else{
	                polinesmap.put( rl.id, rl);
	            }
	            
	            if(repairWO == true){
	            	if(!worderOpIdsmap.containskey(woKey)){
						worderOpIdsmap.put(woKey,new set<Id>{opId});
					}
					else if (worderOpIdsmap.containskey(woKey)) {
						worderOpIdsmap.get(woKey).add(opId);
						if(worderOpIdsmap.get(woKey).size()>1){
							throw new ReceivingDocumentServiceV2Exception(Label.Receive_One_Line_Per_Operation);
		            	}
				   }
                 }
            }
            
               //collecting workorder pick location in a Map --KNDY-15208
             
            if(!material.isEmpty() ){
                wOPickLocation = SkidService3.locationsFromStockMovementRules(material,'Pick',new Set<String>{'material_tracking__c'},null,null);   
            }
            
            for( receivingWrapper rw : refreshedWrapperList ){
                lineType = rw.lineType;
                Location__c putawayLocation;
                String putawayType;
                
                if(!skipPutaway){
                    putawayLocation = (Location__c)rw.rl.getSObject('Putaway_Location__r');
               
                }

                if(rw.lineType == 'Receipt_Line__c' || rw.lineType == 'Sales_Order_Line__c'){
                    putawayType = rw.putawayType;
                }
         
                sObject temprl = rw.rl;
 
               
                rw.rl = refreshedSObjects.get(rw.rl.id);
                if(putawayLocation != null){
                    rw.rl.put('Putaway_Location__c',putawayLocation.id);
                    rw.rl.putSObject('Putaway_Location__r',putawayLocation);
                }
                
         
                if(rw.lineType == 'Purchase_Order_Line__c') { 
            
                   list<String> editableFields = new list<String>(SchemaUtil.getInstance().getFieldsFromFieldSetString(Purchase_Order_Line__c.sObjectType, 'Receiving_RO_EditableFields'));

                    for(String str : editableFields){
                        if(str != 'Putaway_Location__c')
                            rw.rl.put(str, temprl.get(str));
                      
                    }
                }
                
                SObject po;
                if(rw.pol!=null){
                    rw.pol = (Purchase_Order_Line__c) polinesmap.get(rw.rl.id);
                    po = rw.pol.getSObject('Purchase_Order__r');
                }
                
                Decimal totalQuantity = 0;
                if((lineType == 'ASN_Line__c' && rw.item.get('Non_Inventory__c') == false) && po != null && po.getSObject('FOB_Term__r') != null && po.getSObject('FOB_Term__r').get('fob_point__c') == 'Origin' ||
                   lineType == 'Order_Line__c'){
                   	
                    transitLineIds.put(rw.rl.id, rw.rl);// ,asnLineIds
                }
                list<String> attributesList = new list<String>();
                if(po != null && po.get('Type__c') == 'SubContract'){
                    attributesList.addAll(SkidService3.trackedAttributes(null, null, rw.rl.getSobject('item__r')));
                }
                
                
                
                for( Integer i = 0; i < rw.serialWrapperList.size() ; i ++ ){
                    
                    SKID__c skid = rw.serialWrapperList[i].skid;
                    Decimal conversionFactor = rw.conversionFactor;
                    if( conversionFactor == null || skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c){
	                    conversionFactor = 1;
	                }
                    
                    List<Serial__c> serialList = rw.serialWrapperList[i].serialList;
                    map<String,Serial__c> userSpecifiedSerials = new map<String,Serial__c>();
                    
                    if( skid.Quantity__c != null && skid.Quantity__c > 0  ){
                        if (skid.License_Plate_Number__c == null && skid.Temporary_LPN_Holder__c != null && lpnMap.containsKey(skid.Temporary_LPN_Holder__c)) {
	                        skid.License_Plate_Number__c = lpnMap.get(skid.Temporary_LPN_Holder__c).Id; 
	                    }
                        for( Serial__c ser : serialList){
                        
                            Id companyId = (Id)skid.Company__c;
                            Id itemId = (Id)skid.get('Item__c');
                            String uniqueKey = companyId+'-'+itemId+'-'+ser.Name;
                            
                            if(!userSpecifiedSerials.containsKey( uniqueKey )){
                                userSpecifiedSerials.put(uniqueKey, ser);
                            }
                            else{
                                throw new ReceivingDocumentServiceV2Exception(ser.Name+': '+Label.Serial_Number_Specified_More_than_Once);
                            }
                                
                        }
                        
                        if(po != null && po.get('Type__c') == 'SubContract'){
                            
                             //Error handling when putway and wo pick(stock movement rule) doesn't match--KNDY-15208
                            boolean foundLoc = false;
                            
                            list<location__c> pickLocation = new list<location__c>();
                              
                            if(!wOPickLocation.isEmpty() && wOPickLocation.containsKey(rw.pol.material_tracking__c) ){
                             pickLocation =  wOPickLocation.get(rw.pol.material_tracking__c) ; 
                            }
                            if(!pickLocation.isEmpty() && putawayLocation != null){  
                              for(location__c loc:pickLocation){
                               if(loc.id == putawayLocation.id){
                                    foundLoc = true;
                                }
                              }
                             }
                            if(foundLoc == false){
                                 throw new ReceivingDocumentServiceV2Exception(Label.Putaway_and_Pick_location_doesnot_match); 
                            }
                            Set<String> ignoreAttributes= new Set<String>();
                            ignoreAttributes.addAll(SkidService3.attributesToExclude);
                            for(String s:ignoreAttributes){
                                    
                                if(s == 'Serial_Number__c'){
                                    ignoreAttributes.remove(s);
                                }
                            } 
                            
                            for (String attributeName:attributesList) {
                                if (!ignoreAttributes.contains(attributeName.toLowerCase()) && rw.rl.getSObject('item__r').getSObject('item_attribute__r') != null && rw.rl.getSObject('item__r').getSObject('item_attribute__r').get(attributeName) == true) {
                                    throw new ReceivingDocumentServiceV2Exception(rw.rl.getSObject('Item__r').get('Name')+Label.OSP_Item_Cannot_Have_Item_Attributes);
                                }
                            }
                            
                            if(rw.rl.getSObject('item__r').getSObject('item_attribute__r') != null && rw.rl.getSObject('item__r').getSObject('item_attribute__r').get('Serial_Number__c') == true){
                                throw new ReceivingDocumentServiceV2Exception(rw.rl.getSObject('Item__r').get('Name')+Label.OSP_Item_Cannot_Be_Serial_Tracked);
                            }
                            
                            if(rw.pol.getSObject('item_specification__r').getSObject('item__r').getSObject('item_attribute__r') != null && rw.pol.getSObject('item_specification__r').getSObject('item__r').getSObject('item_attribute__r').get('Serial_Number__c') == true
                                && rw.pol.getSObject('item_specification__r').getSObject('item__r').get('Non_Inventory__c') == false && rw.rl.getSObject('Company__r').get('Serial_Control__c') == 'At receipt and all processes' 
                                && (( skid.Quantity__c * conversionFactor ) != serialList.size())){
                                    
                                throw new ReceivingDocumentServiceV2Exception(rw.rl.get('Name')+': '+Label.Quantity_Received_Not_Matching_Number_Of_Serials);
                            }
                            
                            
                        }

                        if(lineType == 'Order_Line__c') {
                            if ( !itemPackagingUoms.containsKey (rw.item.Id)) {
                                itemPackagingUoms.put(rw.item.Id, (List<Id>) JSON.deserialize( rw.item.Packaging_UOM__c, List<Id>.class ));
                            }
                            Decimal facilityIdentifier ;
                            if(rw.rl.getSObject('Ship_From_Facility__r').get('Facility_Identifier__c') !=null){
                                facilityIdentifier = Decimal.valueOf(String.valueOf(rw.rl.getSObject('Ship_From_Facility__r').get('Facility_Identifier__c')));
                            }
                            totalQuantity += (skid.Quantity__c / KSE.getConversionFactor( skid.Item__c, facilityIdentifier, String.ValueOf(rw.rl.get('Packaging_UOM__c')), skid.Packaging_UOM__c, itemPackagingUoms.get(rw.item.Id)) );
                        } else {
                            totalQuantity += (skid.Quantity__c);
                        }


                        anyQuantityEntered =true;
                        
                        Company__c companyObj;
                        
                        if(lineType == 'Order_Line__c'){
                        	companyObj = (Company__c)rw.rl.getSObject('Receiving_Company__r');
                        }
                        else
                        	companyObj = (Company__c)rw.rl.getSObject('Company__r');
                        	
                        if(!skipPutaway ){
                        	if(skid.item__r.item_attribute__r != null && skid.item__r.Non_Inventory__c == false && skid.item__r.item_attribute__r.Serial_Number__c == true
                                && companyObj.get('Serial_Control__c') == 'At receipt and all processes' 
                                && (( skid.Quantity__c * conversionFactor ) != serialList.size())){
                                    
                                throw new ReceivingDocumentServiceV2Exception(rw.rl.get('Name')+': '+Label.Quantity_Received_Not_Matching_Number_Of_Serials);
                            }
                            if(lineType == 'Receipt_Line__c' && rw.putawayType == null){
                                throw new ReceivingDocumentServiceV2Exception(Label.Specify_Putaway_Type_For_Line+(String)rw.rl.get('Name'));
                            }
                            
                            if(lineType == 'Receipt_Line__c' && rw.serialWrapperList[i].transactionUnitCost < 0){
                                throw new ReceivingDocumentServiceV2Exception(Label.Transaction_Unit_Cost_cannot_be_negative+(String)rw.rl.get('Name'));
                            }

                            if( rw.item.get('Non_Inventory__c') == false && (skid.Location__c != rw.rl.get('putAway_Location__c') || skid.Location__c == null ||  rw.rl.get('putAway_Location__c') == null) ){
                                throw new ReceivingDocumentServiceV2Exception(Label.Specify_Putaway_Location_For_Line+(String)rw.rl.get('Name'));
                            }

                            if(rw.item.get('Non_Inventory__c') == false || rw.item.get('Source__c') =='Outside Processing'){
                                SkidService3.checkRequiredAttributes( skid, rw.trackedAttributes, rw.rl, rw.minimumShelfLife, null ) ;
                            }
                        }
                    }
                }
                
                SObject line = rw.rl;
                if( rw.pol != null ){ line = rw.pol; }
				
				Decimal convertFactor = rw.conversionFactor;
                if( convertFactor == null){
                    convertFactor = 1;
                }
                if(!totalQuantityMap.containsKey(line.Id)) totalQuantityMap.put( line.Id , 0);
                    totalQuantityMap.put(line.Id, totalQuantityMap.get(line.Id)+totalQuantity );    

                if(lineType == 'Receipt_Line__c' && totalQuantityMap.get(line.Id) > (Decimal)line.get('Quantity_Still_Due_For_Putaway__c')*convertFactor){
                    throw new ReceivingDocumentServiceV2Exception(Label.Cannot_Over_Receive_For_Putaway + (String)line.get('Name'));                                    
                }
               
                if(lineType == 'Sales_Order_Line__c' && totalQuantityMap.get(line.Id) > KSE.subtractDecimals(math.abs((Decimal)line.get('Quantity_Ordered__c')) , math.abs((Decimal)line.get('Quantity_Fulfilled__c')))*convertFactor){
                    throw new ReceivingDocumentServiceV2Exception(Label.Cannot_Over_Receive_Quantity_Ordered + (String)line.get('Name'));                                    
                }
                if ( lineType == 'Order_Line__c' ) {
                    if (totalQuantityMap.get(line.Id) > KSE.addQuantityToField((Decimal) line.get('Quantity_To_Receive__c'), (Decimal) line.get('Overage_Quantity__c')) * convertFactor) {
                        throw new ReceivingDocumentServiceV2Exception(Label.Cannot_Over_Receive + (String) line.get('Name')  );
                    }
                }
				
                if( lineType != 'Order_Line__c' && lineType != 'Receipt_Line__c' && lineType != 'Sales_Order_Line__c' && !skipPutaway && totalQuantityMap.get(line.Id) > KSE.addQuantityToField( (Decimal)line.get('Quantity_Still_Due__c'), (Decimal)line.get('Overage_Quantity__c'))*convertFactor){
                    throw new ReceivingDocumentServiceV2Exception(Label.Cannot_Over_Receive + (String)line.get('Name'));                                    
                }
            }
            
            if( !anyQuantityEntered){
                throw new ReceivingDocumentServiceV2Exception(Label.No_Quantities_Entered_To_Receive);
            }          
            set<Id> transitLineIdSet = new set<Id>(transitLineIds.keySet());
            
            if(transitLineIdSet.size() > 0 ){                
                


                String whereClause = '(Type__c = \'In-Transit\' OR Type__c = \'Draft In-Transit\')  and '+lineType+ ' IN : transitLineIdSet';


                SOQLUtil soql = new SOQLUtil('SKID__c');
                soql.addFields(new Set<String>{'id', 'License_Plate_Number__c'});
                soql.addAllCustomFields();
                soql.setWhereClause(whereClause);
                
                List<SKID__c> transitSkidlist = Database.query(soql.getQuery());
                
                for( SKID__c transitSkid : transitSkidlist){
                     String removekey = '';
                     String removekey1 = '';
                     if(lineType == 'ASN_Line__c'){
                        removekey = transitSkid.ASN_Line__c;
                     }  
                     if(lineType == 'Order_Line__c'){
                     	removekey = transitSkid.Order_Line__c;
                     	removekey1 = transitSkid.Shipment_Line__c;
                     }
                     transitLineIds.remove(removekey);
                     if(!String.isBlank(removekey1)){
                     	transitLineIds.remove(removekey1);
                     }  
                }                
                
            }
            

            if(transitLineIds.size() > 0){
                String msg = Label.InTransit_Skids_Not_Found;
                for(Id lineId : transitLineIds.keySet()){
                    msg+= transitLineIds.get(lineId).get('Name')+',';

                }
                msg = msg.subString(0,msg.length()-1);
                throw new ReceivingDocumentServiceV2Exception(msg);
            }
        }
        catch( Exception ex ){
           throw ex;
        }
       
        return refreshedWrapperList;   
    }
    
    public static List<receivingWrapper> prepBeforeCommittingReceipt(List<receivingWrapper> rlWrapperList, list<Lot__c> lots, map<Id, Receiving_Document__c> headerToRDMap, set<Id> itemIds, set<Id> facilityIds ){
        
        List<receivingWrapper> wrappersToReceive = new List<receivingWrapper>();
        
        for( receivingWrapper rw : rlWrapperList ){
            
            List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
            
            Id companyId, supplierId, currencyId;
            Boolean lineHasQuantity = false;
            String type;
            Company__c objCompany = new Company__c();
            
            if(rw.lineType != 'Receipt_Line__c'){
                
                if( rw.pol == null && rw.lineType != 'Sales_Order_Line__c'){
                    companyId = (Id)rw.rl.get('Receiving_Company__c');
                    //currencyId = (Id)rw.rl.get('Sales_Order__r.Currency__c');
                    currencyId = (Id)rw.rl.getSobject('Order__r').get('Currency__c');
                    type = 'Transfer Order Receipt';
                }
                else if(rw.lineType == 'Sales_Order_Line__c'){
                    companyId = (Id)rw.rl.get('Company__c');
                    //currencyId = (Id)rw.rl.get('Sales_Order__r.Currency__c');
                    currencyId = (Id)rw.rl.getSobject('Sales_Order__r').get('Currency__c');
                    type = 'RMA Receipt';
                }
                else if(rw.lineType == 'ASN_Line__c'){
                    companyId = (Id)rw.rl.get('Company__c');
                    objCompany = (Company__c)rw.rl.getSObject('Company__r');
                    //currencyId = (Id)rw.rl.get('ASN__r.Currency__c');
                    currencyId = (Id)rw.rl.getSobject('ASN__r').get('Currency__c');
                    supplierId = (Id)rw.rl.getSobject('ASN__r').get('Supplier__c');
                    type = 'Purchase Order Receipt';
                }
                else if(rw.lineType == 'Purchase_Order_Line__c'){
                    companyId = (Id)rw.rl.get('Company__c');
                    objCompany = (Company__c)rw.rl.getSObject('Company__r');
                    //currencyId = (Id)rw.rl.get('Purchase_Order__r.Currency__c');
                    currencyId = (Id)rw.rl.getSobject('Purchase_Order__r').get('Currency__c');
                    supplierId = (Id)rw.rl.getSobject('Purchase_Order__r').get('Supplier__c');
                    type = 'Purchase Order Receipt';
                }
                else if(rw.lineType == 'Order_Line__c'){
                	companyId = (Id)rw.rl.get('Receiving_Company__c');
                	objCompany = (Company__c)rw.rl.getSObject('Receiving_Company__r');
                    currencyId = (Id)rw.rl.getSobject('Order__r').get('Currency__c');
                    type = 'Transfer Order Receipt';
                }
                else{
                    companyId = (Id)rw.pol.get('Company__c');
                    supplierId = (Id)rw.pol.get('Supplier__c');
                   // currencyId = (Id)rw.headerRecord.get('Currency__c');
                    type = 'Purchase Order Receipt';
                }
                if(! headerToRDMap.containsKey(rw.headerRecord.id) ){
                    Receiving_Document__c rd = new Receiving_Document__c( Company__c = companyId, Company__r = objCompany != null ? objCompany :null,Supplier__c = supplierId, Date_Created__c = system.today(), Date_Received__c = system.now() ,
                                                Type__c = type, Currency__c = currencyId, Finalized__c = false, Status__c = 'Closed', Transaction_Date__c = system.now());
                    headerToRDMap.put(rw.headerRecord.id, rd );
                }
            }
            
            
            
            for (SkidService3.serialWrapper sw : rw.serialWrapperList){
                
                SKID__c skid = sw.skid;
                
                if( skid.Quantity__c != null && skid.Quantity__c > 0  ){
                    
                    lineHasQuantity = true;
                    
                    if( rw.item.get('Non_Inventory__c') == false || rw.item.get('Source__c') =='Outside Processing'  ){
                        if( rw.pol != null && rw.pol.getSObject('Purchase_Order__r').get('Type__c') == 'SubContract'){
                            skid.Item__c = (Id)rw.pol.getSObject('Item_Specification__r').get('Item__c');
                            skid.Item__r = (Item__c)rw.pol.getSObject('Item_Specification__r').getSObject('Item__r');
                        }
                        
                        
                        Lot__c lot = SkidService3.populateLotNames(skid, supplierId);
                        if( lot != null) lots.add(lot);
                        skid.Item__c = rw.Item.id;
                        skid.Item__r = rw.Item;
                    }
                    
                    swList.add( sw );
                }
            }
            
            if(lineHasQuantity){
                itemIds.add(rw.Item.id);
                
                if(rw.lineType == 'Receipt_Line__c'){
                    Id rlinefacilityId =  (Id)rw.rl.get('Facility__c');
                    
                    if( rw.rl.get('Sales_Order_Line__c') != null ){
                        rlinefacilityId = (Id)rw.rl.getSObject('Sales_Order_Line__r').getSObject('Ship_From_Location__r').get('Facility__c');
                    }
                    
                    facilityIds.add(rlinefacilityId);
                }
                else if(rw.lineType == 'Sales_Order_Line__c'){
                    Id facilityId = (Id)rw.rl.getSObject('Ship_From_Location__r').get('Facility__c');
                    facilityIds.add(facilityId);
                }
                else{
                    facilityIds.add(rw.pol.Delivery_Location__r.Facility__c);
                }
                
                rw.serialWrapperList = swList;
                wrappersToReceive.add(rw);
            }
        }
        return wrappersToReceive;
    }
    
    public static void Receive(List<receivingWrapper> rlWrapperList, map<Id, Receiving_Document__c> headerToRDMap){
        
        
        //Query again for all the additional fields.
        
        set<String> docTypes = new set<String>();
        set<Id> lineIds = new set<Id>();
        Location__c putawayLocation;
        for( receivingWrapper rw : rlWrapperList ){
            lineIds.add(rw.rl.id);
            docTypes.add(rw.lineType.toLowerCase());
            
            if(!skipPutaway){
            	putawayLocation = (Location__c)rw.rl.getSObject('Putaway_Location__r');
         	} 
            
        }
        
        map<Id,SObject> refreshedSObjects = queryLines( null, lineIds, docTypes, true);
     
        List<Lot__c> lots = new List<Lot__c>();
        map< List<String>, Lot__c > createdLotMap;
        List<SObject> sObjectsForUpdate = new List<SObject>();
        List<SObject> sObjectsForUpdate1 = new List<SObject>();

        set<Id> itemIds = new set<Id>();
        set<Id> facilityIds = new set<Id>();
        set<Id> headerIds = new set<Id>();
        Map<Id,Fulfillment__c> fulfillmentMap = new Map<Id,Fulfillment__c>();
        map<Id,Receipt_Line__c> receiptLines = new map<Id,Receipt_Line__c>();
        List<receivingWrapper> rlWrappersubcontractlineList = new List<receivingWrapper>();
        map<Id, Work_Order__c> workOrderMap = new map<Id, Work_Order__c>();
        set<Id> checkRDsForClosing = new set<Id>();
        Savepoint sp = Database.setSavepoint();
        list<SkidService3.SerialWrapper> serialWrappers = new list<SkidService3.SerialWrapper>();
        //map<Id,SkidService3.SerialWrapper> inTransitmap = new map<Id,SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> negativeSkidsSerialWrapperlist = new list<SkidService3.SerialWrapper>();

        Map<Id,SkidService3.ParameterData> data = new Map<Id,SkidService3.ParameterData>();
        list<Inventory_Transaction__c> inventoryTransactions = new list<Inventory_Transaction__c>();

        List<String> attributesForService = SkidService3.attributesForPutaway();
                        
        list<String> attributesForNegativeSkids = new list<String>();  
        
        List<String> attributesForNegativeTOSkids = SkidService3.attributesForPutaway(null,new Set<String>{'shipment_line__c'});        
        attributesForNegativeTOSkids.add('Order_Line__c');
        Map<list<String>, SKID__c> transitSkidsMap;  
        attributesForNegativeSkids = attributesForService.clone();
        attributesForNegativeSkids.add('ASN_Line__c');
        

        Boolean alreadyInsertedRD = false;
        
        if(headerToRDMap == null){
            headerToRDMap = new map<Id,Receiving_Document__c>();
        }
        else{           
            alreadyInsertedRD = true;           
        }
        List<receivingWrapper> wrappersToReceive = new List<receivingWrapper>();
        String objName;
        Map<Id,SObject>orderLines = new Map<Id,SObject>();
        try{
        		for( receivingWrapper rw : rlWrapperList ){  
            		sObject temprl = rw.rl;
        			rw.rl = refreshedSObjects.get(rw.rl.Id);
        			if(putawayLocation != null){
		                rw.rl.put('Putaway_Location__c',putawayLocation.id);
		                rw.rl.putSObject('Putaway_Location__r',putawayLocation);
		    		}
		    		if(rw.lineType == 'Purchase_Order_Line__c') { 
		                   list<String> editableFields = new list<String>(SchemaUtil.getInstance().getFieldsFromFieldSetString('Purchase_Order_Line__c', 'Receiving_RO_EditableFields'));
		
		                    for(String str : editableFields){
		                        String s = str.replace( KSE.namespaceUU, '').toLowerCase();
		                        if(s != 'putaway_location__c')
		                            rw.rl.put(str, temprl.get(str));
		                   }
		            }
		        	if(rw.lineType == 'Sales_Order_Line__c'){
		                if(rw.rl.getSObject('Ship_From_Location__r').getSObject('Facility__r').get('RMA_Receipt_Routing__c') == 'Inspect')
		                    {
		                        RMAReceiptRouting = 'Inspect';
		                    }
		             }
		           
		            //Only supporting two step receiving for now ...Add RMA_Receipt_Routing__c' filter once we enable Direct option
		          	if(skipPutaway != true && rw.lineType == 'Sales_Order_Line__c' && RMAReceiptRouting == 'Inspect'){
		                skipPutaway = true;
		            }
		            if(rw.lineType == 'Order_Line__c'){
		            	orderLines.put(rw.rl.Id,rw.rl);
		            }
		            if(objName == null)
		                objName = rw.rl.getSObjectType().getDescribe().getLocalName();
		            
		            break;
		                
		        }
        
		        wrappersToReceive = prepBeforeCommittingReceipt(rlWrapperList, lots, headerToRDMap, itemIds, facilityIds);
		
		        if(lots.size() > 0){
		            createdLotMap = SkidService3.createLots(lots);
		        }
		        
		        if(!alreadyInsertedRD)
		            DML.insertAsUser(headerToRDMap.values());
		        List<SKID__c> inTransitSkidList = new List<SKID__c>();
		        
		        List<DateTime> rdocdates = new List<DateTime>();
		        Set<Id> rdocCurrIds = new Set<Id>();
		        Set<Id> companyCurrIds = new Set<Id>();
		        for(Receiving_Document__c rdoc:headerToRDMap.values()){
		        	rdocdates.add(rdoc.Transaction_Date__c);
		        	
		        	if(rdoc.Company__r.Comp_Currency__c != null && rdoc.Currency__c != null && rdoc.Currency__c != rdoc.Company__r.Comp_Currency__c){
		        		rdocCurrIds.add(rdoc.Currency__c);
		        		companyCurrIds.add(rdoc.Company__r.Comp_Currency__c);
		        	}
		        	
		        }
	        
		        //Call ExchangeService to load exchange rates only if RD and Company Currency's are different.
				if(rdocCurrIds.size() >0 && companyCurrIds.size()>0){
					ExchangeRateService.loadExchangeRates(companyCurrIds,rdocCurrIds,rdocdates);
				}
	        	map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>(); 
	        	Map<Id, List<Id>> itemPackagingUOMCache = new Map<Id, List<Id>> ();
		        for( receivingWrapper rw : wrappersToReceive ){
	                   Decimal QuantityReceived = 0;
	                   Decimal QuantityToStockUOM = 0;
	
			            headerIds.add(rw.headerRecord.Id);
			            
			            Id lineUOMId;
			            if(rw.pol !=null){
			            	lineUOMId = (Id)rw.pol.get('Purchase_UOM__c');
			            }
			            else if(rw.lineType == 'Sales_Order_Line__c'){
			            	lineUOMId = (Id)rw.rl.get('Selling_UOM__c');
			            }
			            else if(rw.lineType == 'Receipt_Line__c' && rw.rl.getSObject('Receiving_Document__r').get('Type__c') != 'Miscellaneous Receipt'){
			            	lineUOMId = (Id)rw.rl.getSObject('Sales_Order_Line__r').get('Selling_UOM__c');
			            }
			            else if(rw.lineType == 'Receipt_Line__c' && rw.rl.getSObject('Receiving_Document__r').get('Type__c') == 'Miscellaneous Receipt'){
			            	lineUOMId = (Id)rw.rl.get('Packaging_UOM__c');
			            }
						Decimal conversionFactor = 1.0;
			            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
			                    
			                SKID__c skid = sw.skid;
			                
			                conversionFactor = rw.conversionFactor;
			                
			                if ( !itemPackagingUOMCache.containsKey (skid.Item__c) ) {
			                    List<Id> lstPkgUom = (List<Id>) JSON.deserialize( skid.Item__r.Packaging_UOM__c, List<Id>.class );
			                    itemPackagingUOMCache.put(skid.Item__c, lstPkgUom);
			                }
			                
			                //Get Conv factor skid line uom to packagin uom 
			
			                Decimal cf = 1;
			                Decimal cf1 = 1;
			
			                if(lineUOMId !=null){
			                	cf = KSE.getConversionFactor(skid.item__c, skid.Facility2__r.Facility_Identifier__c, lineUOMId,skid.Packaging_UOM__c, itemPackagingUOMCache.get(skid.Item__c));
			                }
			                else if(rw.lineType == 'Order_Line__c'){
			                	cf1 = KSE.getConversionFactor(skid.item__c, skid.Facility2__r.Facility_Identifier__c, skid.Packaging_UOM__c,skid.Item__r.Stocking_UOM__c, itemPackagingUOMCache.get(skid.Item__c));
			                }
			
			                QuantityToStockUOM += skid.Quantity__c*cf1;
			               
			                QuantityReceived += (skid.Quantity__c/cf).setscale(6,System.RoundingMode.HALF_UP); //convert the qty Received into line's UOM
			                
			                if(skid.Packaging_UOM__c !=null){
			            		if(!itemsWithPackagingUOM.containskey(skid.item__r)){
			        				itemsWithPackagingUOM.put(skid.item__r,new Set<UOM__c>());
			        			}
				        		itemsWithPackagingUOM.get(skid.item__r).add(skid.Packaging_UOM__r);
				        	}
			                if( rw.pol!= null && rw.pol.getSObject('Purchase_Order__r').get('Type__c') == 'SubContract'){
			                	itemsWithPackagingUOM.get(skid.item__r).add(skid.Item__r.Stocking_UOM__r);
			                       rlWrappersubcontractlineList.add(rw);
			                }
			                id inTransitLot;
			                if( skid.Lot_Number__c != null && (rw.item.get('Non_Inventory__c') == false || rw.item.get('Source__c') =='Outside Processing' ) ){
			                    
			                    if( rw.pol!= null && rw.pol.getSObject('Purchase_Order__r').get('Type__c') == 'SubContract'){
			                        skid.Item__c = (Id)rw.pol.getSObject('Item_Specification__r').get('Item__c');
			                    }
			                    
			                    List<String> uniqueString = SkidService3.lotUniqueKey(skid );    
			                    //to match lot of Outside processing item with assembly item .
			                    if(skid.lot__r.name == createdLotMap.get( uniqueString ).name ){
			                    	inTransitLot = skid.lot__c;  
			                        sw.lotValueHolder = inTransitLot;
			                    }
			                    
			                    skid.Lot__c = createdLotMap.get( uniqueString ).id;// this map should always contain the unique string and the created lot as we have already created the ones that didnt exist.   
			                    skid.Lot_Number__c = createdLotMap.get( uniqueString ).Name;
			                    skid.Item__c = rw.item.id;
			                   
			               }                  
			                    
			               //Negative SKID creation should only be done for ASN Lines.
			               if((rw.rl.getSObjectType().getDescribe().getLocalName() == 'ASN_Line__c' && (rw.item.get('Non_Inventory__c') == false || rw.item.get('Source__c') =='Outside Processing'))|| rw.rl.getSObjectType().getDescribe().getLocalName() == 'Order_Line__c'){
			                
			                    Skid__c clonedSkid = sw.skid.clone(false, true);
			                    
			                    clonedSkid.Bin__c = null;
			                    if(rw.pol !=null && rw.pol.getSObject('Purchase_Order__r').get('Type__c') == 'Drop Ship'){
			                    	clonedSkid.Type__c = SkidService3.SKID_TYPE_DRAFTINTRANSIT;
			                    }
			                    else
			                    	clonedSkid.Type__c = SkidService3.SKID_TYPE_INTRANSIT;
			                    	
			                    if(inTransitLot != null  ){
			                        clonedSkid.Lot__c = inTransitLot;
			                        sw.lotValueHolder = inTransitLot;
			                    }
			                    
			                    
			                    if(rw.rl.getSObjectType().getDescribe().getLocalName() == 'ASN_Line__c'){
			                    	clonedSkid.Location__c = (Id)rw.rl.get('location__c');
			                    	clonedSkid.ASN_line__c = (Id)rw.rl.Id;
			                    	for(Integer i=0;i<attributesForNegativeSkids.size();i++){
				                        if(attributesForNegativeSkids.get(i) == 'Bin__c'){
				                            attributesForNegativeSkids.remove(i);
				                        }
				                    } 
			                    }
			                    else if(rw.rl.getSObjectType().getDescribe().getLocalName() == 'Order_Line__c'){
			                    	clonedSkid.Location__c = (Id)rw.rl.get('Deliver_To_Location__c');
			                    	clonedSkid.Order_line__c = (Id)rw.rl.Id;
			                    	clonedSkid.Shipment_line__c = null;
			                    }
			                  		
			                    
			                    inTransitSkidList.add(clonedSkid);
			               }
			                    
			            }
		            
		            
			            if(rw.lineType == 'Receipt_Line__c'){
			                
			                if( rw.rl.get('Sales_Order_Line__c') == null || (String)rw.rl.getSObject('Receiving_Document__r').get('Type__c') == RD_TYPE_RETURN ){ //not rma
			                      rw.rl.put('Quantity_Received__c', KSE.addQuantityToField((Decimal)rw.rl.get('Quantity_Received__c') , QuantityReceived));
			                }
			                
			                Decimal qtytoStock = (Decimal)rw.rl.get('Quantity_Received__c') * rw.conversionFactor;
			                rw.rl.put('Quantity_To_Stock__c', qtytoStock);
			                rw.rl.put('Quantity_Still_Due_For_Putaway__c', KSE.subtractDecimals((Decimal)rw.rl.get('Quantity_Still_Due_For_Putaway__c'), QuantityReceived));
			                
			                if((Decimal)rw.rl.get('Quantity_Still_Due_For_Putaway__c') == 0){
			                    rw.rl.put('Status__c','Closed');
			                    
			                    if((String)headerToRDMap.get(rw.headerRecord.Id).Status__c != 'Closed'){
			                        checkRDsForClosing.add(rw.headerRecord.Id);
			                    }
			                }
			                
			                receiptLines.put((Id)rw.rl.get('Id'),(Receipt_Line__c)rw.rl);
			            }
			            
			            //Create Receipt Lines
			            if(rw.lineType != 'Receipt_Line__c'){
			                Receipt_Line__c receipt = createReceiptLine(rw, QuantityReceived, QuantityToStockUOM, headerToRDMap.get(rw.headerRecord.id), itemIds, facilityIds);
			                if(rw.lineType == 'Sales_Order_Line__c'){//This would be taken care as of fullfillment creation.
			                    fulfillmentMap.put(rw.rl.Id, new Fulfillment__c(Type__c = 'RMA', Quantity__c = receipt.Quantity_Received__c * -1, Receipt_Line__c = receipt.Id, Fulfillment_Date__c = headerToRDMap.get(rw.headerRecord.id).Transaction_Date__c));
			                }
			                else if(rw.lineType == 'Order_Line__c'){
			                	rw.rl.put('Quantity_Received__c', KSE.addQuantityToField((Decimal)rw.rl.get('Quantity_Received__c') ,receipt.Quantity_To_Stock__c)) ;
			                }
			                else{
			                    rw.rl.put('Quantity_Received__c', KSE.addQuantityToField((Decimal)rw.rl.get('Quantity_Received__c') ,receipt.Quantity_Received__c)) ;
			                }
			                
			                if(rw.lineType == 'Purchase_Order_Line__c'){
			                    rw.rl.put('Date_Last_Changed__c' , system.today()); 
			                    if(rw.rl.get('Short_Close__c') == true) {
			                       rw.rl.put('Status__c','Closed');
			                    }
			                }
			                
			                sObjectsForUpdate.add(rw.rl);
			                           
			                if( rw.pol!= null && rw.rl.getSObjectType().getDescribe().getLocalName() == 'ASN_Line__c'){
			                    receiptLines.put(rw.pol.id, receipt);
			                    rw.pol.put('Quantity_Received__c', KSE.addQuantityToField((Decimal)rw.pol.get('Quantity_Received__c') ,receipt.Quantity_Received__c)) ;
			                    sObjectsForUpdate1.add(rw.pol);
			                }                
			                else
			                    receiptLines.put(rw.rl.id, receipt);
			                    
			            }
			            
			            if( rw.putawayType == 'Inspection'){
			                
			                Receipt_Line__c rLine = receiptLines.get(rw.rl.Id);
			                Work_Order__c wo = new Work_Order__c(Order_Quantity__c = 0);
			                
			                if( rLine.Work_Orders__r != null && rLine.Work_Orders__r.size() > 0 ){
			                    wo = rLine.Work_Orders__r[0];
			                }
			                
			                wo.Company__c = rLine.Company__c;
			                wo.Currency__c = rLine.Company__r.Default_Transaction_Currency__c;
			                wo.Facility__c = rLine.Location__r.Facility__c;
			                wo.Order_Quantity__c += (QuantityReceived * rw.conversionFactor.setscale(6,System.RoundingMode.HALF_UP));
			                wo.Need_Date2__c = system.now();
			                if (rLine.Item__r.Lead_Time__c != null) {
			                    wo.Start_Date2__c = wo.Need_Date2__c.addDays(0 - (Integer)rLine.Item__r.Lead_Time__c);
			                }
			                wo.Type__c = WorkOrderService.WO_TYPE_REPAIR;
			                wo.Item__c = rLine.Item__c;
			                wo.Complete_To_Location__c = rLine.Location__r.Facility__r.Default_Work_Order_Complete_to_Location__c;
			                wo.MRB_Location__c = rLine.Location__r.Facility__r.Default_Work_Order_MRB_Location__c;
			                wo.Default_WIP_Location__c = rLine.Location__r.Facility__r.Default_Work_Order_WIP_Location__c;
			                if(rLine.Id != null){
			                    wo.Receipt_Line__c = rLine.Id;
			                }
			                workOrderMap.put(rw.rl.Id, wo);
			             }
			         	}
			
				         map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
				         if(itemsWithPackagingUOM.values().size()>0)
				         	containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
				
						 if(docTypes.contains('Order_Line__c'.toLowerCase())){
						 	transitSkidsMap = SkidService3.generateExistingSkidMap( attributesForNegativeTOSkids, inTransitSkidList, true, null);
						 }
						 else if(docTypes.contains('ASN_Line__c'.toLowerCase())){
						 	transitSkidsMap = SkidService3.generateExistingSkidMap( attributesForNegativeSkids, inTransitSkidList, true, null);
						 }
			
				         //Inserting Receipt Lines:
				         Set<Receiving_Document__c> rdocSet = new Set<Receiving_Document__c>();
				         List<Receiving_Document__c> rdoclisttoUpdate = new List<Receiving_Document__c>();
				         if(objName != 'Receipt_Line__c'){
				            System.debug(Logginglevel.Info,'Before DML receiptLines.values():'+receiptLines.values());
				            DML.insertAsUser(receiptLines.values());
				       		System.debug(Logginglevel.Info,'After DML receiptLines.values():'+receiptLines.values());
				            for(Id lineId:receiptLines.keyset() ){
				                
				                if(fulfillmentMap.containskey(lineId)){
				                    fulfillmentMap.get(lineId).Receipt_Line__c = receiptLines.get(lineId).Id;
				                }
				                
				                if( workOrderMap.containsKey(lineId)){
				                    workOrderMap.get(lineId).Receipt_Line__c = receiptLines.get(lineId).Id;
				                }
				            }
				                
				            
				            for( Receiving_Document__c rd : headerToRDMap.values() ){
				                rd.finalized__c = true;
				                rdocSet.add(rd);
				            }
				            
				            rdoclisttoUpdate.addAll(rdocSet);  
				            
				         }
				         //Call
				        if (!skipPutaway) {
				            putAwayInventory(wrappersToReceive,attributesForNegativeSkids,attributesForNegativeTOSkids,attributesForService,transitSkidsMap, receiptLines,containersByItem);
				        }
				        
				        if(objName == 'Order_Line__c'){
				        	
				        	for(sObject ol: sObjectsForUpdate)
				            {
				                if((orderlineKeyMismatchExceptionList!=null)&&(orderlineKeyMismatchExceptionList.size()>0))
				                {
				                    if(orderlineKeyMismatchExceptionList.containsKey(ol.Id))
				                    {   
				                        ol.put('Exceptions_Count__c',1);
				                    }
				                }
				                    
				            }
				        }
				        //Updates
				        if(objName != 'Receipt_Line__c'){
				            
				            if(rdoclisttoUpdate.size()>0)      
				                DML.updateAsUser(rdoclisttoUpdate);
				            
				            if(sObjectsForUpdate.size()>0)
				                DML.updateAsUser(sObjectsForUpdate);
				
				            if(sObjectsForUpdate1.size()>0)
				                DML.updateAsUser(sObjectsForUpdate1);
				
				            if(objName == 'Sales_Order_Line__c')
				                FulfillmentService.fulfillSalesOrders(fulfillmentMap.keyset(), fulfillmentMap);
				            }
				            else{
				                
				                DML.updateAsUser(receiptLines.values());
				            }
				            
				            if(objName == 'Order_Line__c'){
				            
				                if(orderlineKeyMismatchExceptionList.keySet().size()>0)
				                {
				                   ReceivingDocumentService.LogException(orderLines,orderlineKeyMismatchExceptionList, SkidService2.SKID_LOT_EXCEPTION);
				                   
				                }
				            }
				            if( checkRDsForClosing.size() > 0 ){
				                checkAndCloseRDs(checkRDsForClosing, headerToRDMap);
				            }
				            
				            WorkOrderService.allowWorkOrderUpdate = true;
				            DML.checkUpsertAsUser(workOrderMap.values()); upsert workOrderMap.values();
				            WorkOrderService.allowWorkOrderUpdate = false;
        }
        catch(exception e)
        {   system.debug(LoggingLevel.ERROR, e.getStackTraceString());
            Database.rollback(sp);
            throw e;
        }
        
            
    }
    
    
    public static void putAwayInventory(List<receivingWrapper> wrappersToReceive,
                                        list<String> attributesForNegativeSkids,list<String> attributesForNegativeTOSkids,
                                        list<string> attributesForService,
                                        map<list<String>, SKID__c > transitSkidsMap,
                                        map<Id, Receipt_Line__c> receiptLines, map<Id, map<Id, Item__c>> containersByItem)
    {
        Map<List<String>,List<String>> keyMap = new Map<List<String>,List<String>>();
        list<SkidService3.SerialWrapper> inTransitWrapperList = new list<SkidService3.SerialWrapper>();
        list<Inventory_Transaction__c> inventoryTransactions = new list<Inventory_Transaction__c>(); 
        list<SkidService3.SerialWrapper> serialWrappers = new list<SkidService3.SerialWrapper>();
        map<String,String> configMap =  new map<String,String>{'adjustFromSkidQuantity'=>'none','putawayDirection'=>'to'};

        Map<Id,SkidService3.ParameterData> data = new Map<Id,SkidService3.ParameterData>();
        Map<Id,SkidService3.ParameterData> dataRMAInv = new Map<Id,SkidService3.ParameterData>();
        //List<receivingWrapper> rlWrappersubcontractlineList = new List<receivingWrapper>();
        set<Id> headerIds = new set<Id>();
        List<ReceivingWrapper> dropShipWrappers = new List<ReceivingWrapper>();
        Set<Id> dropShipSOLIds = new Set<Id>();
        Map<Id, Receipt_Line__c> dropShipRTVmap = new Map<Id, Receipt_Line__c>();
        Map<Id, List<SkidService3.serialWrapper>> dropShipRTVSKIDmap = new Map<Id, List<SkidService3.serialWrapper>>();
        Map<Id, Sales_Order_Line__c> dropShipRelatedSOmap = new Map<Id, Sales_Order_Line__c>();
        Map<Id, Sales_Order_Line__c> soRelatedSOmap = new Map<Id, Sales_Order_Line__c>();
        List< ReturnToVendorService.POLineWrapper > POLinesToReturn = new List< ReturnToVendorService.POLineWrapper >();
		set<String> docTypes = new set<String>();
        Map<String,Boolean> putawayConfigMap = new Map<String,Boolean>{ SkidService3.CREATE_SERIAL => true };
        map<id,List<string>> itemToAttributesMap = new map<id,List<string>>();
        
        ID transcurrency;
        if(receiptLines.values().size()>0){
            for(Receipt_Line__c rcl:receiptLines.values()){
                if(transcurrency == null){
                    transcurrency = rcl.Receiving_Document__r.Currency__c;
                    break;
                }
                
            }
            
        }
        
        /* create map only for install base sol: RMA SOL -> Original Sales Order Line */
        Set<Id> rmalSol = new Set<Id>();
        Map <Id, Id> rmaSOLToOriginalSOL = new Map <Id, Id>();
        List<Skid__c> ibSkidList = new List<Skid__c>();

        Sales_Order_Line__c solx;

        Map<Id,Id> solToPol = new Map<Id,Id>();
        Set<Id> locationIds = new Set<Id>();
        Map<id,sObject> orderLines=new Map<id,sObject>();
        for (ReceivingWrapper rw:wrappersToReceive) {
            
            if (rw.pol != null && rw.pol.Sales_Order_Line__c != null && rw.pol.Type__c == 'Back To Back') {
                solToPol.put(rw.pol.Sales_Order_Line__c,rw.pol.Id);
            }
             
             solx = null;

             if(rw.lineType == 'Sales_Order_Line__c') 
                 solx = (Sales_Order_Line__c)rw.rl;
                 
             if(rw.lineType == 'Receipt_Line__c' && rw.rl.get('Sales_Order_Line__c') != null) 
                 solx = (Sales_Order_Line__c)rw.rl.getSObject('Sales_Order_Line__r');


            if ((rw.lineType == 'Receipt_Line__c' || (rw.lineType == 'Sales_order_line__c' && !skipPutaway)) && solx != null ){
                if (rw.item.get('Track_Install_Base__c') != null && (Boolean) rw.item.get('Track_Install_Base__c')){
                          rmalSol.add(solx.Id);
                }
            }
			docTypes.add(rw.lineType.toLowerCase());
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                if (sw.skid.Location__c != null) {
                    locationIds.add(sw.skid.Location__c);
                }
            }
            if(rw.lineType == 'Order_Line__c'){ 
            	itemToAttributesMap.put((id)rw.rl.get('Receiving_Item__c'),rw.trackedAttributes);
            	orderLines.put(rw.rl.Id,rw.rl);
            }
        }

        Map<Id,Location__c> locationMap = new Map<Id,Location__c>();
        if (locationIds.size() > 0) {
            SOQLUtil locationQuery = new SOQLUtil('Location__c');
            locationQuery.addAllCustomFields();
            locationQuery.addField('Facility__r.Facility_Identifier__c');
            locationQuery.setWhereClause('Id IN :locationIds');
            locationMap = new Map<Id,Location__c>((List<Location__c>)Database.query(locationQuery.getQuery()));
        }

        if (!rmalSol.isEmpty()){
            for ( Sales_order_line__c sol : [select id, Related_Sales_Order_Line__c
                                                from Sales_Order_Line__c
                                                where Id IN :rmalSol]){
                rmaSOLToOriginalSOL.put(sol.id, sol.Related_Sales_Order_Line__c);
            }

            for (receivingWrapper rw : wrappersToReceive){
                
                Id solId = rw.rl.Id;
                if(rw.lineType == 'Receipt_Line__c'){
                    solId = (Id)rw.rl.get('Sales_Order_Line__c');
          
                    if( (String)rw.rl.getSObject('Receiving_Document__r').get('Type__c') == RD_TYPE_RETURN){

                        rmaSOLToOriginalSOL.put(solId, solId);
                    }
                }
                
                if (rmaSOLToOriginalSOL.containsKey(solId)) {
                    for (SkidService3.serialWrapper sw : rw.serialWrapperList){
                        Skid__c clonedSkid = sw.skid.clone(false, true);
                        clonedSkid.Type__c = SkidService3.SKID_TYPE_INSTALLBASE;
                        clonedSkid.Sales_Order_Line__c = rmaSOLToOriginalSOL.get(solId);
                        clonedSkid.Location__c = null;
                        clonedSkid.Bin__c = null;
                        ibSkidList.add(clonedSkid);
                    }
                }
            }
        }

        Map<list<String>, SKID__c> installBaseSkidsMap;

        list<String> attributesForInstallBaseSkids = new list<String>();
        attributesForInstallBaseSkids = SkidService3.attributesForPutaway(null, new set<String>{'shipment_line__c', 'purchase_order_line__c'});
        attributesForInstallBaseSkids.add('Sales_Order_Line__c');
        

        if (!rmaSOLToOriginalSOL.values().isEmpty()) {
            installBaseSkidsMap = SkidService3.generateExistingSkidMap( attributesForInstallBaseSkids, ibSkidList, true, null);
        }
		
        Set<Id> skidIds = new Set<Id>();
		if ( installBaseSkidsMap != null ) {
	        for ( Skid__c sk: installBaseSkidsMap.values()  ) {
	        	skidIds.add(sk.id);
	        }
		}
		
        Map<Id,List<Serial__c>> skidToSerial = new Map<Id,List<Serial__c>>();
        if (skidIds.size() > 0) {
    		SOQLUtil serialQuery = new SOQLUtil('Serial__c');
            serialQuery.addAllCustomFields();
            serialQuery.setWhereClause('Skid__c IN :skidIds ');
            for (Serial__c serial:Database.query(serialQuery.getQuery())) {
            	if (!skidToSerial.containsKey(serial.SKID__c)) {
            		skidToSerial.put(serial.SKID__c,new List<Serial__c>());
            	}
            	skidToSerial.get(serial.SKID__c).add(serial);
            }
        }

        Map<Id,Map<Id,List<SkidService3.SerialWrapper>>> skidsToAllocate = new Map<Id,Map<Id,List<SkidService3.SerialWrapper>>>();
        Map<Id,Shipment_Line__c> shlMap = new Map<Id,Shipment_Line__c>();
        if (solToPol.size() > 0) {
            Set<Id> solSet = solToPol.keySet();
            SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
            shlQuery.addAllCustomFields();
            shlQuery.addFields(new Set<String>{ 'Sales_Order_Line__r.Quantity_From_Stock__c','Sales_Order_Line__r.Quantity_Ordered__c','Product__r.Item__r.Non_Inventory__c','Shipment__r.Status__c', 'Facility__r.Facility_Identifier__c', 'Sales_Order_Line__r.Ship_from_Location__r.Facility__r.Facility_Identifier__c' });
            shlQuery.setWhereClause('Sales_Order_Line__c IN :solSet AND Product__r.Item__r.Non_Inventory__c = false AND Shipment__r.Status__c != \'Confirmed\'');
            for (Shipment_Line__c shl:Database.query(shlQuery.getQuery())) {
                shlMap.put(solToPol.get(shl.Sales_Order_Line__c),shl);
            }
        }

        if(orderLines.size()>0)//Check for only Transfer Orders
        	TOManageExceptions(wrappersToReceive,orderLines, itemToAttributesMap);
            
        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        List<ReceivingWrapper> subcontractWrappers = new List<ReceivingWrapper>();
        List<Serial__c> serialsToDelete = new List<Serial__c>();
        for (ReceivingWrapper rw:wrappersToReceive) {
            Purchase_Order_Line__c pol = rw.pol;
            Item__c item = rw.item;

            if (packagingUoms.containsKey(item.Id) == false) packagingUoms.put(item.Id, (List<Id>)JSON.deserialize(item.Packaging_UOM__c, List<Id>.Class));
            List<Id> pkgUoms = packagingUoms.get(item.Id);
            
            List<SkidService3.SerialWrapper> subcontractSwList = new List<SkidService3.SerialWrapper>();

             list<String> key;
             String type;
             List<SkidService3.serialWrapper> rtvwrapperlist = new List<SkidService3.serialWrapper>();
             String objName = rw.rl.getSObjectType().getDescribe().getLocalName();
             if(objName == 'ASN_Line__c' && rw.item.get('Non_Inventory__c') == true && rw.item.get('Source__c') !='Outside Processing'){
             	continue;
             }
             for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                Decimal conversionFactor = 1.0;
                SKID__c fromSkid;
                SKID__c skid = sw.skid;
                Skid__c transitSkid = skid.clone(false, true);
                SKID__c skidClone = skid.clone(false, true);
                skid.Type__c = 'Location';
                if (skid.Location__c != null) {
                    Location__c loc = locationMap.get(skid.Location__c);
                    skid.Location__r = loc;
                    skid.Facility2__c = loc.Facility__c;
                    skid.Facility2__r = loc.Facility__r;
                }
                
                if (objName == 'Order_Line__c' || objName == 'ASN_Line__c') {
                	
                    if( sw.lotValueHolder != null && transitSkid.Lot__c != null){
                        transitSkid.Lot__c = sw.lotValueHolder;
                    }
					
                    if (objName == 'Order_Line__c') {
                        transitSkid.Order_Line__c = rw.rl.Id;
                        transitSkid.Order_Line__r = (Order_Line__c)rw.rl;
                        transitSkid.Location__c = (Id)rw.rl.get('Deliver_To_Location__c');
                        transitSkid.Bin__c = null;
                        transitSkid.Type__c = SkidService3.SKID_TYPE_INTRANSIT;
                        key = SkidService3.generateKey(transitSkid, attributesForNegativeTOSkids);
                    }
					else if(objName == 'ASN_Line__c'){
						transitSkid.ASN_Line__c = rw.rl.Id;
                    	transitSkid.Location__c = (Id)rw.rl.get('Location__c'); 
						key = SkidService3.generateKey(transitSkid, attributesForNegativeSkids);
					}
                    SKID__c negativeSkid;
                    if(transitSkidsMap !=null && transitSkidsMap.values().size() > 0 && transitSkidsMap.containskey(key)){
                        fromSkid = transitSkidsMap.get(key);  
                        negativeSkid = fromskid.clone(true,true);
                    }
                    else if(objName == 'Order_Line__c' && transitSkidsMap.values().size() == 0 && fromSkid == null){
                    	fromSkid = null;
                    	negativeSkid = transitSkid.clone(true,true);
                    	if(negativeSkid.Location__c != rw.rl.get('deliver_to_location__c')){
                    		negativeSkid.Location__c = (Id)rw.rl.get('deliver_to_location__c');
                    	}
                    }

                    if (objName == 'Order_Line__c' && skid.Mixed_Palletized__c == true) {
                        skid.Mixed_Palletized__c = false;
                        skid.License_Plate_Number__c = null;
                        skid.License_Plate_Number__r = null;
                        skid.Container_Item__r = null;
                        skid.Container_Item__c = null;
                    }
                    
                    negativeSkid.Quantity__c = -skid.Quantity__c;
					
					inTransitWrapperList.add( new SkidService3.SerialWrapper(negativeSkid, new list<Serial__c>()));
					
                }

                if (pol != null && pol.Purchase_Order__r.Type__c == PurchaseOrderService.PO_TYPE_SUBCONTRACT && item.Source__c == ItemService.ITEM_SOURCE_OSP) {
                    SkidService3.SerialWrapper subcontractSw = new SkidService3.SerialWrapper(skid.clone(false, true));

                    skid.Quantity__c *= KSE.getConversionFactor(skid.Item__c, pol.Delivery_Facility__r.Facility_Identifier__c, skid.Packaging_UOM__c, item.Stocking_UOM__c, pkgUoms);
                    skid.Packaging_UOM__c = item.Stocking_UOM__c;
                    skid.License_Plate_Number__c = null;

                    if (sw.serialList != null) {
                        for (Serial__c serial:sw.serialList) {
                            subcontractSw.serialList.add(new Serial__c(Name = serial.Name));
                            if (serial.Id != null) serialsToDelete.add(new Serial__c(Id = serial.Id));
                        }
                        sw.serialList = new List<Serial__c>();
                    }
                    
                    subcontractSwList.add(subcontractSw);
                }
                                                                               
                type = 'Purchase Order Receipt';
                if(rw.pol == null ) type = 'Transfer Order Receipt';
                else if (rw.pol.Purchase_Order__r.Type__c == PurchaseOrderService.PO_TYPE_DROP_SHIP && rw.pol.Sales_Order_Line__c != null)
                    type = InventoryTransactionService.LOGICAL_PURCHASE_ORDER_RECEIPT;
                
                string objectName = rw.rl.getSObjectType().getDescribe().getLocalName();
                
                Inventory_Transaction__c it;
                ID RMADocId;
                      
                Receipt_Line__c receiptline;
                Sales_Order_Line__c sol;
             	if(objectName == 'Sales_Order_Line__c') {
                 	sol = (Sales_Order_Line__c)rw.rl;
                 	receiptline = receiptLines.get(rw.rl.Id);
             	}
             	if(objectName == 'Receipt_Line__c' && rw.rl.get('Sales_Order_Line__c') != null ) {
                 	sol = (Sales_Order_Line__c)rw.rl.getSObject('Sales_Order_Line__r');
                    receiptline = (Receipt_Line__c)rw.rl;
                 	if( (String)rw.rl.getSObject('Receiving_Document__r').get('Type__c') == RD_TYPE_RETURN ){
                     	type = RD_TYPE_RETURN;
                 	}
             	}

                Item__c containerItem; 
                
                if(sw.skid.Container_item__r != null){
                	containerItem = sw.skid.Container_item__r;
                	containerItem.Id = sw.skid.Container_item__c;
                }
                else if(sw.skid.Packaging_UOM__c !=null){
                	containerItem = containersByItem.get(sw.skid.Item__c).get(sw.skid.Packaging_UOM__c);
                }
                if(containerItem !=null){
                	sw.skid.Container_Item__c = containerItem.Id;
                	sw.skid.Container_Item__r = containerItem;
                }
                else{
                	throw new ReceivingDocumentServiceV2Exception('Container Item needs to defined on Item or package class.');
                }
                
                if(objectName == 'Sales_Order_Line__c' || (objectName == 'Receipt_Line__c'  && rw.rl.get('Sales_Order_Line__c') != null) ){
                   conversionFactor = KSE.getConversionFactor(sol);
                   Boolean logical = false;
                   String rmaSOtype;
                   Set<String> rmareceiptTypes = new Set<String>{SalesOrderService.SO_TYPE_RMA, SalesOrderService.SO_TYPE_RMA_REPLACEMENT};
                   if(objectName == 'Sales_Order_Line__c'){
                        if(rmareceiptTypes.contains((String)rw.headerRecord.get('Type__c')) && rw.rl.getSObject('Related_Sales_Order_Line__r') != null && rw.rl.getSObject('Related_Sales_Order_Line__r').get('Fulfillment_Source__c') == 'Drop Ship' && rw.rl.get('Returned_To_Vendor__c') == true){
                            logical = true;
                            
                            rtvwrapperlist.add(sw);
                        }
                        rmaSOtype = (String)rw.headerRecord.get('Type__c');
                    }
                    else if(objectName == 'Receipt_Line__c'){//Need to check if it is needed
                        if(rw.rl.get('Sales_Order_Line__c') != null && rmareceiptTypes.contains((String)rw.rl.getSObject('Sales_Order__r').get('Type__c')) && rw.rl.getSObject('Sales_Order_Line__r').getSobject('Related_Sales_Order_Line__r') != null && rw.rl.getSObject('Sales_Order_Line__r').getSobject('Related_Sales_Order_Line__r').get('Fulfillment_Source__c') == 'Drop Ship' && rw.rl.getSObject('Sales_Order_Line__r').get('Returned_To_Vendor__c') == true){
                            logical = true;
                            rtvwrapperlist.add(sw);
                        }
                        
                        rmaSOType = (String)rw.rl.getSObject('Sales_Order__r').get('Type__c');
                        
                    }
                    if(rw.putawayType == 'Inventory'){       
                        if (rw.headerRecord.get('Type__c') == 'RMA Receipt' || rmareceiptTypes.contains(rmaSOType)) {
                               
                                if(logical){
                                 type = InventoryTransactionService.LOGICAL_RMA_RECEIPT;
                                 RMADocId = 'rma0000000LRECEIPT';
                                }
                                else{
                                 type = 'RMA Receipt';
                                 RMADocId = 'rma00000000RECEIPT';
                                }   
                         } else if (rw.headerRecord.get('Type__c') == SalesOrderService.SO_TYPE_RMA_REPAIR || rw.headerRecord.get('Type__c') == 'RMA Receipt For Repair') {
                                type = 'RMA Receipt For Repair';
                                if(objectName == 'Sales_Order_Line__c'){
                                	sw.skid.Sales_Order_Line__c = (Id)rw.rl.get('Id');
                                }
                                else if(objectName == 'Receipt_Line__c' && sol!=null){
                                	sw.skid.Sales_Order_Line__c = sol.Id;
                                }
                                
                                RMADocId = 'rma000000INVREPAIR';
                         }
                    }
                    else if(rw.putawayType == 'Scrap'){
                        
                        if(logical){
                            type = InventoryTransactionService.LOGICAL_RMA_SCRAP;
                            RMADocId = 'rma000000000LSCRAP';
                        }
                        else{
                            type = 'RMA Scrap';
                            RMADocId = 'rma0000000000SCRAP';
                        }
                    }
                    

                    if (installBaseSkidsMap != null && rw.item.get('Track_Install_Base__c') != null && (Boolean) rw.item.get('Track_Install_Base__c') ){

                        
                        SKID__c clonedSkid = skid.clone(false, true);
                        clonedSkid.Type__c = SkidService3.SKID_TYPE_INSTALLBASE;
                        clonedSkid.Sales_Order_Line__c = rmaSOLToOriginalSOL.get( sol.Id);
                        clonedSkid.Location__c = null;
                        clonedSkid.Receipt_Line__c = null;
                        
                        key = SkidService3.generateKey(clonedSkid, attributesForInstallBaseSkids);
                        clonedSkid.Sales_Order_Line__c = null;
                        List<String> keyWithoutSOL = SkidService3.generateKey(clonedSkid, attributesForInstallBaseSkids);
                        
                        if (installBaseSkidsMap.containsKey(key) || installBaseSkidsMap.containsKey(keyWithoutSOL)){
                            fromSkid = installBaseSkidsMap.get(key);
                            
                            if(fromSkid == null){
                                fromSkid = installBaseSkidsMap.get(keyWithoutSOL);
                            }
                            configMap.remove('adjustFromSkidQuantity'); //skidservice will default to deducting from skids as we need to deduct installbase skids
                        }
                    }
                    //it = SkidService3.createIT(fromSkid, type, 'Sales_Order_Line__c', sol.Id, skid,attributesForService, skid.Quantity__c );
                    it = SkidService3.createInventoryTransaction(sol, type, skid.Quantity__c, fromSkid, skid, attributesForService);
                    it.Receipt_Line__r = receiptline; 
                    it.Receipt_Line__c = receiptline.Id;
                    it.sales_order_line__r = sol; 
                    it.Transaction_Unit_Cost__c = sw.transactionUnitCost;
                    it.Purchase_Order_Line__c = skid.Purchase_Order_Line__c;
                    it.Purchase_Order_Line__r = skid.Purchase_Order_Line__r;
                    if(receiptline.Receiving_Document__r.Transaction_Date__c != null){
                    	it.Transaction_Date__c =  receiptline.Receiving_Document__r.Transaction_Date__c;
                    }
                } else if (objectName != 'Order_Line__c' && objectName != 'Receipt_Line__c' && objectName != 'Sales_Order_Line__c') {
                    //PO Receipt (PO and ASN), Logical PO Receipt
                    it = SkidService3.createInventoryTransaction(rw.pol,type,skid.Quantity__c,fromSkid,skid,attributesForService);
                    it.Purchase_Order_Line__r = rw.pol;

                    Receipt_Line__c rl = receiptLines.get(it.Purchase_Order_Line__c);
                    it.Receipt_Line__c = rl.Id;
                    if (rl.Receiving_Document__r.Transaction_Date__c != null) {
                        it.Transaction_Date__c = rl.Receiving_Document__r.Transaction_Date__c;
                    }

                    if (!rw.pol.Consigned__c) {
                        it.Purchase_Order_Line__c = null;
                    }

                    putawayConfigMap.put(SkidService3.ALLOW_SERIAL_REENTRY, false);
                }
                else if(objectName == 'Receipt_Line__c' && rw.rl.get('Sales_Order_Line__c') == null ){
                    //it = SkidService3.createIT(null, (String)rw.rl.getSObject('Receiving_Document__r').get('Type__c'), 'Receipt_Line__c', (Id)rw.rl.Id, skid,attributesForService, skid.Quantity__c );
                    it = SkidService3.createInventoryTransaction(rw.rl, (String)rw.rl.getSObject('Receiving_Document__r').get('Type__c'), skid.Quantity__c, null, skid, attributesForService );
                    it.Receipt_Line__r = (Receipt_Line__c)rw.rl; 
                    it.Transaction_Unit_Cost__c = sw.transactionUnitCost;
                    if(rw.rl.getSObject('Receiving_Document__r').get('Transaction_Date__c') != null){
                    	it.Transaction_Date__c = (DateTime)rw.rl.getSObject('Receiving_Document__r').get('Transaction_Date__c');
                    }
                }
                else if(objectName == 'Order_Line__c'){
                	
					it = SkidService3.createInventoryTransaction(rw.rl, type, skid.Quantity__c, fromSkid, skid, attributesForService );
                    Receipt_Line__c rl = receiptLines.get(it.Order_Line__c);
                    it.Receipt_Line__c = rl.Id;
                    if(skid.Purchase_Order_Line__c !=null){
                    	it.Purchase_Order_Line__c = skid.Purchase_Order_Line__c;
                    	it.Purchase_Order_Line__r = skid.Purchase_Order_Line__r;
                    }
                    if (rl.Receiving_Document__r.Transaction_Date__c != null) {
                        it.Transaction_Date__c = rl.Receiving_Document__r.Transaction_Date__c;
                    }
                    
                    if (skidClone.Mixed_Palletized__c == true) {
                        it.Mixed_Palletized__c = true;
                        it.From_License_Plate_Number__c = skidClone.License_Plate_Number__c;
                        it.From_License_Plate_Number__r = skidClone.License_Plate_Number__r;
                        it.From_Container_Item__c = skidClone.Container_Item__c;
                        it.From_Container_Item__r = skidClone.Container_Item__r;
                    }
                }

                keyMap.put(SkidService3.generateKey(it,attributesForService),SkidService3.generateKey(skid,attributesForService));
                
                
                if( rw.putawayType == 'Inspection'){
                    skid.Receipt_Line__c = rw.rl.Id;
                }
                 
                sObjectType objType = rw.rl.getSObjectType();
                Id companyId;
                Id sourceDocId;
                
		        
                if (objType == Purchase_Order_Line__c.sObjectType) {
                    sourceDocId = (Id)rw.rl.get('Purchase_Order__c');
                    companyId = (Id)rw.rl.get('Company__c');
                } else if (objType == Order_Line__c.sObjectType) {
                    sourceDocId =(Id)rw.rl.get('Order__c');
                	companyId = (Id)rw.rl.get('Receiving_Company__c');
                } else if (objType == ASN_Line__c.sObjectType) {
                    sourceDocId = (Id)rw.rl.get('ASN__c');
                    companyId = (Id)rw.rl.get('Company__c');
                }     
                else if(objType == Sales_Order_Line__c.sObjectType && skipPutaway == true){
                    sourceDocId = (Id)rw.rl.get('Sales_Order__c');
                    companyId = (Id)rw.rl.get('Company__c');
                }   
                else if(objType == Receipt_Line__c.sObjectType || skipPutaway == false){
                    //sourceDocId = (Id)rw.rl.getSObject('Sales_Order__r').get('Id');
                    //throw new ReceivingDocumentServiceV2.ReceivingDocumentServiceV2Exception('sourceDocId:'+sourceDocId);
                    sourceDocId = RMADocId;
                    companyId = (Id)rw.rl.get('Company__c');
                }
                if(objType == Receipt_Line__c.sObjectType && (rw.rl.get('Sales_Order_Line__c')==null || (String)rw.rl.getSObject('Receiving_Document__r').get('Type__c') == RD_TYPE_RETURN)){
                    sourceDocId = (Id)rw.rl.get('Receiving_Document__c');
                    companyId = (Id)rw.rl.get('Company__c');
                }
                
                
                SkidService3.ParameterData d = data.get(sourceDocId);
                
                if( sourceDocId == 'rma000000INVREPAIR' || rw.putawayType == 'Inspection' ){
                    d = dataRMAInv.get(sourceDocId);
                }
                
                sw.it = it;
                if (d == null) {
                    d = new SkidService3.ParameterData();
                    d.sourceDoc = new Receiving_Document__c(Company__c = companyId);
                    if (it.Type__c == 'RMA Receipt' || it.Type__c == 'RMA Receipt For Repair' || it.Type__c == 'RMA Scrap' || it.Type__c == 'Purchase Order Receipt'){
                        d.icType = it.type__c;
                        if(skidToSerial.size() >0)
                            d.fromSerialListBySkid = skidToSerial;
                    }
                     if (rw.lineType == 'ASN_Line__c' && it.Type__c != 'Logical Purchase Order Receipt')
                        d.icType = 'In-Transit Purchase Order Receipt';
                    
                    if(it.Type__c == 'Purchase Order Receipt' || it.Type__c == 'Transfer Order Receipt' || it.Type__c == InventoryTransactionService.LOGICAL_PURCHASE_ORDER_RECEIPT || d.icType == 'In-Transit Purchase Order Receipt'){
                    	 d.sourceDoc.put('Currency__c', transcurrency);
                    }
                    if( sourceDocId == 'rma000000INVREPAIR' || rw.putawayType == 'Inspection'  ){
                        dataRMAInv.put(sourceDocId,d);
                    }
                    else{
                        data.put(sourceDocId,d);
                    }
                }
                else{
                    if( skidToSerial != null && skidToSerial.keySet().size() > 0 ){
                        if( d.fromSerialListBySkid == null ){
                            d.fromSerialListBySkid = new map<Id, List<Serial__c>>();
                        }
                        d.fromSerialListBySkid.putAll(skidToSerial);
                    }
                }
                
                if( rw.item.get('Non_Inventory__c') == false){
                    d.itList.add(it);
                    inventoryTransactions.add(it); 
                    serialWrappers.add(sw);
                }
                
             }
             if (type == InventoryTransactionService.LOGICAL_PURCHASE_ORDER_RECEIPT)
                    dropShipWrappers.add(rw);
            if (rw.pol != null) {
                Id headerId;
                Id lineId;
                Decimal qtyToAllocate;
                if ((objName == 'ASN_Line__c' || objName == 'Purchase_Order_Line__c') && rw.pol.Material_Tracking__r != null && rw.pol.Material_Tracking__r.Allocation_Required__c && rw.pol.Material_Tracking__r.Allocate_On_Receipt__c) {
                    headerId = rw.pol.Material_Tracking__r.Work_Order__c;
                    lineId = rw.pol.Material_Tracking__c;
                    qtyToAllocate = KSE.subtractDecimals(rw.pol.Material_Tracking__r.Quantity_Short__c,rw.pol.Material_Tracking__r.Quantity_Allocated__c);
                } else if (rw.pol.Type__c == 'Back To Back' && shlMap.containsKey(rw.pol.Id)) {
                    Shipment_Line__c shl = shlMap.get(rw.pol.Id);
                    Decimal sellingConvFactor = KSE.getConversionFactorFromQuantity(shl.Sales_Order_Line__r.Quantity_From_Stock__c,shl.Sales_Order_Line__r.Quantity_Ordered__c);
                    headerId = shl.Shipment__c;
                    lineId = shl.Id;
                    qtyToAllocate = KSE.subtractDecimals(shl.Quantity_Planned__c,KSE.addQuantityToField(KSE.addQuantityToField(shl.Quantity_Allocated__c,shl.Quantity_Picked__c / sellingConvFactor),shl.Quantity_Shipped__c)) * sellingConvFactor;
                }

                if (qtyToAllocate > 0) {
                    List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
                    for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                        if (qtyToAllocate <= 0) {
                            break;
                        }

                        SkidService3.SerialWrapper swToAllocate = new SkidService3.SerialWrapper(sw.skid.clone(false,true),new List<Serial__c>());
                        //Convert to stocking uom
                        Decimal cf= 1;
                        cf = KSE.getConversionFactor(sw.skid.item__c, sw.skid.Facility2__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c,sw.skid.Item__r.Stocking_UOM__c, pkgUoms);
                        swToAllocate.skid.Input_Quantity__c = Math.min(sw.skid.Quantity__c*cf,qtyToAllocate);
                        if (sw.serialList.size() > 0) {
                            for (Integer i=0;i<swToAllocate.skid.Input_Quantity__c;i++) {
                                swToAllocate.serialList.add(sw.serialList[i]);
                            }
                        }
                        swList.add(swToAllocate);
                    }

                    if (swList.size() > 0) {
                        if (!skidsToAllocate.containsKey(headerId)) skidsToAllocate.put(headerId,new Map<Id,List<SkidService3.SerialWrapper>>());
                        if (!skidsToAllocate.get(headerId).containsKey(lineId)) skidsToAllocate.get(headerId).put(lineId,new List<SkidService3.SerialWrapper>());
                        skidsToAllocate.get(headerId).get(lineId).addAll(swList);
                    }
                }                   
            }

            if (subcontractSwList.size() > 0) subcontractWrappers.add(new ReceivingWrapper(pol, pol, null, null, null, subcontractSwList));
             
             if(rtvwrapperlist.size()>0 && rw.lineType == 'Sales_Order_Line__c'){
                dropShipRTVSKIDmap.put((Id)rw.rl.get('Related_Sales_Order_Line__c'),rtvwrapperlist);
             }
             else if(rtvwrapperlist.size()>0 && rw.lineType == 'Receipt_Line__c'){
                 dropShipRTVSKIDmap.put((Id)rw.rl.getSObject('Sales_Order_Line__r').get('Related_Sales_Order_Line__c'),rtvwrapperlist);
             }
            
             if(rw.lineType == 'Sales_Order_Line__c' && (rw.headerRecord.get('Type__c') == SalesOrderService.SO_TYPE_RMA || rw.headerRecord.get('Type__c') == SalesOrderService.SO_TYPE_RMA_REPLACEMENT) && rw.rl.getSObject('Related_Sales_Order_Line__r')!=null && rw.rl.getSObject('Related_Sales_Order_Line__r').get('Fulfillment_Source__c') == 'Drop Ship' && rw.rl.get('Returned_To_Vendor__c') == true){
                dropShipRTVmap.put((Id)rw.rl.get('Related_Sales_Order_Line__c'),receiptLines.get(rw.rl.Id));
                dropShipRelatedSOmap.put((Id)rw.rl.get('Related_Sales_Order_Line__c'),(Sales_Order_Line__c)rw.rl);
                
             }
             else if(rw.lineType == 'Receipt_Line__c' && rw.rl.get('Sales_Order_Line__c') != null && (rw.rl.getSObject('Sales_Order__r').get('Type__c') == SalesOrderService.SO_TYPE_RMA || rw.rl.getSObject('Sales_Order__r').get('Type__c') == SalesOrderService.SO_TYPE_RMA_REPLACEMENT) && rw.rl.getSObject('Sales_Order_Line__r').getSObject('Related_Sales_Order_Line__r') != null && rw.rl.getSObject('Sales_Order_Line__r').getSObject('Related_Sales_Order_Line__r').get('Fulfillment_Source__c') == 'Drop Ship' && rw.rl.getSObject('Sales_Order_Line__r').get('Returned_To_Vendor__c') == true){
                dropShipRTVmap.put((Id)rw.rl.getSObject('Sales_Order_Line__r').get('Related_Sales_Order_Line__c'),(Receipt_Line__c)rw.rl);
                dropShipRelatedSOmap.put((Id)rw.rl.getSObject('Sales_Order_Line__r').get('Related_Sales_Order_Line__c'),(Sales_Order_Line__c)rw.rl.getSObject('Sales_Order_Line__r'));
             }
         }  
         for( Inventory_Transaction__c it : inventoryTransactions ){
            
            Id lineId = (Id)it.get('Purchase_Order_Line__c');

             if (it.Type__c == 'RMA Receipt' || it.Type__c == 'RMA Receipt For Repair' || it.Type__c == 'RMA Scrap') {
                lineId = (Id)it.get('Receipt_Line__c');
            }
            else{
                if(lineId == null) lineId = (Id)it.get('Order_Line__c');
                else{
                    if( it.getSObject('purchase_order_line__r').get('Consigned__c') == false ){
                    
                        it.Purchase_Order_Line__c = null;
                    }
                }
            }
            
           if(it.get('Receipt_Line__c') == null)
                it.put('Receipt_Line__c' , receiptLines.get(lineId).id);
        }
        
        map<List<String>, SkidService3.SerialWrapper > inTransitSkMap;
        
        if( inTransitWrapperList.size() > 0){
        	if( docTypes.contains('Order_Line__c'.toLowerCase())){
        		inTransitSkMap = SkidService3.putAwayService(inTransitWrapperList,attributesForNegativeTOSkids, new map<String,Boolean>{SkidService3.CREATE_SERIAL=>false }); 
        	}
        	else
        		inTransitSkMap = SkidService3.putAwayService(inTransitWrapperList,attributesForNegativeSkids, new map<String,Boolean>{SkidService3.CREATE_SERIAL=>false }); 
            
            map<Id,SKID__c> intransitSkidsByIdMap = new map<Id,SKID__c>();
            
            for(SkidService3.SerialWrapper sw : inTransitSkMap.values()){
            	intransitSkidsByIdMap.put(sw.skid.Id, sw.skid);
            }
            
            for( Inventory_Transaction__c it : inventoryTransactions ){
	                
	        	if(it.From_SKID__c != null && intransitSkidsByIdMap.containsKey(it.From_SKID__c) ){        
	                                        
                        it.From_Skid__r = intransitSkidsByIdMap.get(it.From_SKID__c);          	                    	              
	        	}	        	
            }       
        }
		
        Map<List<String>,SkidService3.SerialWrapper> toSkidsMap = SkidService3.putAwayService(serialWrappers,attributesForService,putawayConfigMap);
        map<Id,List<SKID__c>> skidsReceiptsmap = new map<Id,List<SKID__c>>();
        for(SkidService3.SerialWrapper swrapper:toSkidsMap.values()){
            if(!skidsReceiptsmap.containskey(swrapper.it.Receipt_Line__c)){
                skidsReceiptsmap.put(swrapper.it.Receipt_Line__c,new list<SKID__c>{swrapper.skid});
            }
            else{
                skidsReceiptsmap.get(swrapper.it.Receipt_Line__c).add(swrapper.skid);
            }	
        }
        
        for (List<String> itKey:keyMap.keySet()) {
            List<String> skidKey = keyMap.get(itKey);
            if (toSkidsMap.containsKey(skidKey)) {
                toSkidsMap.put(itKey,toSkidsMap.get(skidKey));
            }
        }
        
        if (data.size() > 0) SkidService3.inventoryTransactionsForPutAway(data,attributesForService,toSkidsMap,configMap);
        if (dataRMAInv.size() > 0) SkidService3.inventoryTransactionsForPutAway(dataRMAInv,attributesForService,toSkidsMap,configMap);

        if (dropShipWrappers.size() > 0)
            SalesOrderService.confirmDropShip(dropShipWrappers);

        if (skidsToAllocate.size() > 0) {
            try {
                AllocationService.autoAllocate(skidsToAllocate);
            } catch (Exception e) {
                throw new ReceivingDocumentServiceV2Exception('Unable to auto-allocate: ' + e.getMessage());
            }
        }

        if (subcontractWrappers.size() > 0) {
            try {
                WorkOrderService.autoComplete(subcontractWrappers);
            } catch (Exception e) {
                throw new CustomException('Unable to auto-complete: ' + e.getMessage());
            }
        }
        
        Set<Id> rdIds = new Set<Id>();
        Set<Id> receiptIds = new Set<Id>();
        for(Receipt_Line__c rcline:dropShipRTVmap.values()){
            rdIds.add(rcline.Receiving_Document__c);
            receiptIds.add(rcline.Id);
        }
        Map<Id,Purchase_Order_Line__c> relatedPOLmap = new Map<Id,Purchase_Order_Line__c>();
        Map<Id,Sales_Order_Line__c> solPOLmap = new Map<Id,Sales_Order_Line__c>();
        Map<Id,Receipt_Line__c> receiptpolinemap   = new Map<Id,Receipt_Line__c>();   
        if(dropShipRTVmap.keyset().size() > 0){
            POLinesToReturn = ReturnToVendorService.getreturningLines(dropShipRTVmap.keyset(),new set<Id>(),new Set<String>{'Sales_Order_Line__c'.toLowerCase()});

    
            //Adding Quantity to return/replacement depending upon the SO Type
            for(ReturnToVendorService.POLineWrapper poreturnlines: POLinesToReturn){
                if(dropShipRTVSKIDmap.containskey(poreturnlines.polRecord.Sales_Order_Line__c) && dropShipRelatedSOmap.containskey(poreturnlines.polRecord.Sales_Order_Line__c) &&  dropShipRelatedSOmap.get(poreturnlines.polRecord.Sales_Order_Line__c).Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA){
                    for(SkidService3.SerialWrapper skwrapper:dropShipRTVSKIDmap.get(poreturnlines.polRecord.Sales_Order_Line__c)){
                        poreturnlines.newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c += skwrapper.skid.Quantity__c;
                    }
                }
                else if(dropShipRTVSKIDmap.containskey(poreturnlines.polRecord.Sales_Order_Line__c) && dropShipRelatedSOmap.containskey(poreturnlines.polRecord.Sales_Order_Line__c) &&  dropShipRelatedSOmap.get(poreturnlines.polRecord.Sales_Order_Line__c).Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA_REPLACEMENT){
                    poreturnlines.newPolRecord.Quantity_Returned_To_Supplier__c = dropShipRTVmap.get(poreturnlines.polRecord.Sales_Order_Line__c).Quantity_Received__c;
                    poreturnlines.newPolRecord.Need_Date__c = System.today();
        
                    poreturnlines.newPolRecord.Quantity_Returned_To_Supplier__c = 0;
                    for(SkidService3.SerialWrapper skwrapper:dropShipRTVSKIDmap.get(poreturnlines.polRecord.Sales_Order_Line__c)){
                        poreturnlines.newPolRecord.Quantity_Returned_To_Supplier__c += skwrapper.skid.Quantity__c;
                    }
                    
                } 
                poreturnlines.logical = true;//drop ship automated flow                                        
                relatedPOLmap.put(poreturnlines.solRecord.Id, poreturnlines.polRecord); 
               // receiptpolinemap.put(poreturnlines.polRecord.Id, dropShipRTVmap.get(poreturnlines.solRecord.Id).Id);
                receiptpolinemap.put(poreturnlines.polRecord.Id, dropShipRTVmap.get(poreturnlines.solRecord.Id));
            }
            Map<String, List<SObject>> sObjectmap = new Map<String,List<SObject>>();
            List<Receiving_Document__c> newRDlist = new List<Receiving_Document__c>();
            List<Receipt_Line__c> newRLineslist = new List<Receipt_Line__c>();
            
            Set<Id> rdocIds = new Set<Id>();
            
            sObjectmap.putAll( new Map<String,List<SObject>>(ReturnToVendorService.returnToVendor(POLinesToReturn, receiptpolinemap, dropShipRelatedSOmap)));
            
            
            for(String s:sObjectmap.keyset()){
                if(s.contains('rdoclist')){
                    newRDlist.addAll((List<Receiving_Document__c>)sObjectmap.get(s));
                }
                if(s.contains('newRLines')){
                    newRLineslist.addAll((List<Receipt_Line__c>)sObjectmap.get(s));
                }
            }
            
            for(Receiving_Document__c rdoc:newRDlist){
                rdocIds.add(rdoc.Id);
            }
            
            
            //Second step choosing the inventory to return
            
            List<LineWrapper> linewrappers = getRTVData(rdocIds);
            
            Map<Id, List<Inventory_Transaction__c>> receiptITmap = new map<Id, List<Inventory_Transaction__c>>();
            receiptITmap = getInventoryTransactionsForRTV(receiptIds,true);
            List<LineWrapper> rlWrappers = new List<LineWrapper>();
            for(LineWrapper linewrap:linewrappers){
                
                Receipt_Line__c rl = (Receipt_Line__c)linewrap.line;
                //Receipt PO SOLine will be RSOL on RMA SOL
                //linewrap.logical = true;
                List<SkidService3.SerialWrapper> serialWrapperList = new List<SkidService3.SerialWrapper>();
                    for (SkidService3.SerialWrapper sw: linewrap.serialWrappers) {
                        if(skidsReceiptsmap.containskey(rl.Related_Receipt_Line__c)){
                            for(SKID__c skid: skidsReceiptsmap.get(rl.Related_Receipt_Line__c)){
                                
                                if(skid.Id == sw.skid.Id){
                                   		if(rl.Quantity_Returned_to_Supplier_for_Credit__c >0){
                                            skid.Quantity_To_Return__c = rl.Quantity_Returned_to_Supplier_for_Credit__c;
                                        }
                                        else if(rl.Quantity_returned_to_supplier__c > 0){
                                            skid.Quantity_To_Return__c = rl.Quantity_returned_to_supplier__c;
                                        }
                                        skid.Quantity_Available__c = sw.skid.Quantity_Available__c;
                                        skid.Total_Material__c = sw.skid.Total_Material__c ;
                                        List<Serial__c> serialList = new List<Serial__c>();
                                        if(receiptITmap.containskey(rl.Purchase_Order_Line__r.Sales_Order_Line__c)){
                                            List<Inventory_Transaction__c> invtranslist = receiptITmap.get(rl.Purchase_Order_Line__r.Sales_Order_Line__c);
                                            for(Inventory_Transaction__c inv:invtranslist){
                                                
                                                for(Serial_Transaction__c st:inv.Serial_Transactions__r){
                                                    Serial__c serial = new Serial__c(unique_Key2__c = st.Serial__r.Unique_Key2__c);
                                                    serial.Name = st.Serial__r.Name;
                                                    serial.Company__c = st.Serial__r.Company__c;
                                                    serial.Item__c = st.Serial__r.Item__c;
                                                    serial.Id = st.Serial__c;
                                                    serialList.add(serial);
                                                }
                                            }
                                        }
                                        
                                        sw.serialList = serialList;  
                                    	serialWrapperList.add(new SkidService3.SerialWrapper(skid,serialList));
                                    	LineWrapper rlinewrap = new LineWrapper(rl,serialWrapperList);
                                    	rlinewrap.logical = true;
                                    	rlWrappers.add(rlinewrap);
                                    	
                                }
                            	
                                }
                            }
                            
                                
                    
                   }
                
            }

            checkRTVErrors(rlWrappers);
            returnToVendor(rlWrappers);
        }

        if (serialsToDelete.size() > 0) DML.deleteAsSystem(serialsToDelete);
      }
      
      public static void checkAndCloseRDs( set<Id> checkRDsForClosing, map<Id, Receiving_Document__c> headerToRDMap ){
        
        Map<Id,Receiving_Document__c> receivingDocs = new Map<Id,Receiving_Document__c>();
                                                        
        set<String> rdFields = new set<String>{'Id', 'name', 'Company__c','Type__c','Transaction_Type__c', 'Currency__c','Transaction_Date__c'};                                                
        SOQLUtil soql = new SOQLUtil('Receiving_Document__c');
        soql.addFields(rdFields);
        soql.setWhereClause('Id IN :checkRDsForClosing and Status__c = \'Open\'');
        
        set<String> rlFields = new set<String>{'id', 'name', 'Status__c'};
        SOQLUtil.ChildRelationship rlQuery = new SOQLUtil.ChildRelationship(soql, 'Receipt_Lines__r');
        rlQuery.addFields(rlFields);
        rlQuery.setWhereClause('Status__c != \'Closed\'');
        soql.addChildRelationship(rlQuery);
        
        for( Receiving_Document__c rdQueried : (List<Receiving_Document__c>)Database.Query(soql.getQuery()) ){
            
            Receiving_Document__c rd = headerToRDMap.get(rdQueried.Id);
            
            if( rdQueried.Receipt_Lines__r != null && rdQueried.Receipt_Lines__r.size() == 0 ){
                
                rdQueried.Status__c = 'Closed';
                rdQueried.Finalized__c = true;
                if( rdQueried.Transaction_Date__c == null ){
                    rdQueried.Transaction_Date__c = system.now();
                }
                rd = rdQueried;
                receivingDocs.put(rd.Id,rd);
            }
        }

        
        if( receivingDocs.values().size() > 0 ){                                                
            DML.updateAsUser(receivingDocs.values());                                                
        }
    }

    
    public static Receipt_Line__c createReceiptLine(receivingWrapper rw,Decimal QuantityReceived, Decimal QuantityToStockUOM, Receiving_Document__c rd, set<Id> itemIds, set<Id> facilityIds ){
        
        Receipt_Line__c receipt;
        receipt = rw.rcl;
        if( rw.pol!= null ){
        	
            
            receipt.Location__r = rw.pol.Delivery_Location__r;
            receipt.Purchase_Order_Line__r = rw.pol;
            receipt.Item__r = rw.item;
            receipt.unit_price__c = (Decimal)rw.rl.get('unit_price__c'); 
            
            if(rw.pol.get('Consigned__c') == true){
                receipt.Line_Type__c = 'Consigned';
                receipt.Uninvoiced_Quantity__c = null;
            }
                       
            receipt.put(rw.lineType, rw.rl.Id);
            
        }
        else if(rw.lineType == 'Sales_Order_Line__c'){
            receipt.item__r = rw.item;
            receipt.Location__r = (Location__c)rw.rl.getSObject('Ship_From_Location__r');
            if(skipPutaway)
                receipt.Quantity_Still_Due_For_Putaway__c = QuantityReceived;
            else
                receipt.Quantity_Still_Due_For_Putaway__c = 0;
        }
        else{
            receipt.Quantity_To_Stock__c = QuantityToStockUOM;
        }
        
        receipt.Receiving_Document__c = rd.id;
        receipt.Receiving_Document__r = rd;
        receipt.Company__c = rd.company__c;
        receipt.Company__r = rd.company__r;
        receipt.Status__c = 'Closed';
        if(rw.lineType == 'Order_Line__c')
        	receipt.Quantity_Received__c = QuantityToStockUOM;
        else
        	receipt.Quantity_Received__c = QuantityReceived;
        	
        Double stdCost = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,receipt.Company__c,receipt.Facility__c,rd.Transaction_Date__c,receipt.Item__c);
        
        if( receipt.Uninvoiced_Quantity__c == null && receipt.Line_Type__c != 'Consigned') receipt.Uninvoiced_Quantity__c = receipt.Quantity_Received__c ;
        
        //Call ExchangeService for conversion
        Decimal convertedStandardCost;
        if(rd.Company__r.Comp_Currency__c != null && rd.Currency__c != null && rd.Company__r.Comp_Currency__c != rd.Currency__c && stdCost >0){
        	convertedStandardCost = ExchangeRateService.convertAmount(rd.Company__r.Comp_Currency__c,rd.Currency__c,rd.Transaction_Date__c, stdCost);
            convertedStandardCost = convertedStandardCost != null ? convertedStandardCost : 0;
        }
        
        if(convertedStandardCost != null){
        	receipt.Extended_Cost__c = convertedStandardCost * receipt.Quantity_Received__c * rw.conversionFactor;
        } 
        else{
        	receipt.Extended_Cost__c = stdCost * receipt.Quantity_Received__c * rw.conversionFactor;
        }
        
        if(rw.lineType != 'Sales_Order_Line__c' && rw.lineType !='Order_Line__c')
        	receipt.Quantity_To_Stock__c = receipt.Quantity_Received__c * rw.conversionFactor; //This will be updated on putaway step.
        
        return receipt;
    }
    public static SKID__c copySkidAttributes( SObject rl, Purchase_Order_Line__c pol, SKID__c skid, SObject sk, list<String> attributeFields){
            List<String> pkgUOMList = new List<String>();
            
            //Copy attribute mapping part into a common function..Also create dummy skid incase of POL and also if ASN Line doesn't have any skid at all.
            if( !skipPutaway && rl.get('Putaway_Location__c') != null ){
                skid.Location__c = (Id)rl.get('Putaway_Location__c');
                skid.Location__r = (Location__c)rl.getSObject('Putaway_Location__r');  
            }  
            Set<Id> pkgUOMSetIds = new Set<Id>();        
    		if((rl.getSObjectType() == Purchase_Order_Line__c.sObjectType || rl.getSObjectType() == ASN_Line__c.sObjectType) && pol.getSObject('Purchase_UOM__r') != null){
    			//validate if Purchase_UOM__c
    			Item__c itemObj;
    			
    			itemObj = (Item__c)pol.getSObject('Item__r');
                if(rl.getSObjectType() == ASN_Line__c.sObjectType){
            		itemObj = (Item__c)rl.getSObject('Item__r');
            	}
            	
            	if(pol.Purchase_Order__r.Type__c == 'SubContract'){
            		itemObj = (Item__c)pol.getSObject('Item_Specification__r').getSObject('Item__r');
            	}
            	
            	pkgUOMSetIds = (set<Id>)JSON.deserialize(String.valueOf(itemObj.get('Packaging_UOM__c')), set<Id>.Class);
                if(!pkgUOMSetIds.contains((Id)pol.get('Purchase_UOM__c'))){
    				skid.Packaging_UOM__c = (Id)itemObj.get('Stocking_UOM__c');
    				if(itemObj.getSObject('Stocking_UOM__r') !=null){
    					skid.Packaging_UOM__r = (UOM__c)itemObj.getSObject('Stocking_UOM__r');
    				}	
    			}
    			else if(pkgUOMSetIds.contains((Id)pol.get('Purchase_UOM__c'))){
    				skid.Packaging_UOM__c = (Id)pol.get('Purchase_UOM__c');
    				if(pol.getSObject('Purchase_UOM__r') !=null){
    					skid.Packaging_UOM__r = (UOM__c)pol.getSObject('Purchase_UOM__r');
    				}	
    			}
    			
    		}
            if( pol != null && pol.get('Consigned__c') == true ){
                attributeFields.add( 'Consigned_Owner__c');   
                skid.consigned_owner__c = (Id)pol.getSObject('Purchase_Order__r').get('Supplier__c');
                skid.putSObject('consigned_owner__r' ,pol.getSObject('Purchase_Order__r').getSObject('Supplier__r'));
                skid.Purchase_Order_Line__c = pol.id;
                
            }
            
            if((rl.getSObjectType() == Sales_Order_Line__c.sObjectType) && rl.getSObject('Selling_UOM__r') != null){//Need to do for Transfer Orders
    			pkgUOMSetIds = (set<Id>)JSON.deserialize(String.valueOf(rl.getSObject('Product__r').getSObject('Item__r').get('Packaging_UOM__c')), set<Id>.Class);
                if(!pkgUOMSetIds.contains((Id)rl.get('Selling_UOM__c'))){
    				skid.Packaging_UOM__c = (Id)rl.getSObject('Product__r').getSObject('Item__r').get('Stocking_UOM__c');
    				if(rl.getSObject('Product__r').getSObject('Item__r').getSObject('Stocking_UOM__r') !=null)
    					skid.Packaging_UOM__r = (UOM__c)rl.getSObject('Product__r').getSObject('Item__r').getSObject('Stocking_UOM__r');
    			}
    			else if(pkgUOMSetIds.contains((Id)rl.get('Selling_UOM__c'))){
    				skid.Packaging_UOM__c = (Id)rl.get('Selling_UOM__c');
	    			if(rl.getSObject('Selling_UOM__r') !=null)
	    				skid.Packaging_UOM__r = (UOM__c)rl.getSObject('Selling_UOM__r');
	    			} 
    		}
    		
    		if(rl.getSObjectType() == Receipt_Line__c.sObjectType && rl.getSObject('Receiving_Document__r').get('Type__c') == 'Miscellaneous Receipt'){
    			
    			//Misc Receipt RDs packaging UOM will defined on Receipt Line and validated
            	
            	if(rl.get('Packaging_UOM__c') !=null){
            		skid.Packaging_UOM__c = (Id)rl.get('Packaging_UOM__c');
            		if(rl.getSObject('Packaging_UOM__r') !=null){
            			skid.Packaging_UOM__r = (UOM__c)rl.getSObject('Packaging_UOM__r');
            		}
            	}
            	
            	
    		}
    		else if((rl.getSObjectType() == Receipt_Line__c.sObjectType) && rl.getSObject('Sales_Order_Line__r').getSObject('Selling_UOM__r') != null){//Need to do for Transfer Orders
    			pkgUOMSetIds = (set<Id>)JSON.deserialize(String.valueOf(rl.getSObject('Item__r').get('Packaging_UOM__c')), set<Id>.Class);
                
            	if(!pkgUOMSetIds.contains((Id)rl.getSObject('Sales_Order_Line__r').get('Selling_UOM__c'))){
    				skid.Packaging_UOM__c = (Id)rl.getSObject('Item__r').get('Stocking_UOM__c');
    				if(rl.getSObject('Item__r').getSObject('Stocking_UOM__r') !=null)
    					skid.Packaging_UOM__r = (UOM__c)rl.getSObject('Item__r').getSObject('Stocking_UOM__r');
    			}
    			else if(pkgUOMSetIds.contains((Id)rl.getSObject('Sales_Order_Line__r').get('Selling_UOM__c'))){
    				skid.Packaging_UOM__c = (Id)rl.getSObject('Sales_Order_Line__r').get('Selling_UOM__c');
	    			if(rl.getSObject('Sales_Order_Line__r').getSObject('Selling_UOM__r') !=null)
	    				skid.Packaging_UOM__r = (UOM__c)rl.getSObject('Sales_Order_Line__r').getSObject('Selling_UOM__r');
	    		 }
                
                 
    		}
    		
    	
    		
    		if(sk != null){
                if( attributeFields != null ){
                    for( String attr: attributeFields ){             
                         skid.put( attr, sk.get(attr));             
                    }                   
                }
                if(sk.get('Lot__c') !=null){
                    skid.Lot_Number__c = (String)sk.getSobject('Lot__r').get('Name');
                    skid.Lot__c = (Id)sk.get('Lot__c');
                    skid.putSObject('Lot__r' ,sk.getSobject('Lot__r'));
                }
                if(sk.get('License_Plate_Number__c') !=null){
                	skid.putSObject('License_Plate_Number__r' ,sk.getSobject('License_Plate_Number__r'));
                	skid.put('License_Plate_Number__c', sk.get('License_Plate_Number__c'));
                }
                if(sk.get('Packaging_UOM__c') != null && skid.getSObject('Packaging_UOM__r') == null){
                    skid.putSObject('Packaging_UOM__r',sk.getSObject('Packaging_UOM__r'));
                }
                
                if(sk.get('Stocking_UOM__c') != null){
                	skid.put('Stocking_UOM__c',sk.get('Stocking_UOM__c'));
                }
                
                if( skid.consigned_owner__c != null ){
                    skid.putSObject('consigned_owner__r' ,sk.getSObject('consigned_owner__r'));
                    skid.put('Purchase_Order_Line__c' ,(Id)sk.get('Purchase_Order_Line__c'));
                    skid.putSObject('Purchase_Order_Line__r' ,sk.getSObject('Purchase_Order_Line__r'));
                }
            }

            if (rl.getSObjectType() == Purchase_Order_Line__c.sObjectType) skid.Rental__c = pol.Rental__c;
            
            return skid;
    }
    
    //Method to manage Lot and Quantity exceptions -PTM-165
    public static void TOManageExceptions(List<receivingWrapper> rlWrapperList,Map<id,sObject> orderLines, map<id,List<string>> itemToAttributesMap)
    {
        //public variable getting cleared when ever receive is clicked
        orderlineKeyMismatchExceptionList =new map<id,string>();
        map<Id,set<String>> orderlineIntransitKeyMap = new map<Id,set<String>>();
        set<id> orderLinesTemp=new set<Id>();
        set<string> intransitKeySet = new set<string>();
        
        Map<String, Schema.SObjectField> skidsFieldsMap = SchemaUtil.getInstance().getFieldsMap('Skid__c');
        
        //Original transit-skids of the order lines before modification in the UI during receive.
        list<string> attrList = skidservice2.attributesForPutaway(new list<String>(Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c')));
        set<Id> olIds= orderLines.keyset();
        
        String whereClause = 'Type__c = \'In-Transit\' and Order_Line__c IN :olIds ORDER BY Order_Line__c';
        
        SOQLUtil soql = new SOQLUtil('Skid__c');
        soql.addFields(new Set<String>(attrList));
        soql.addFields(new Set<String>{'id', 'Lot_Number__c', 'Quantity__c', 'License_Plate_Number__c','Lot__r.Name',  'Facility2__r.Facility_Identifier__c',
                        'Type__c', 'Order_Line__r.Id', 'Order_Line__r.Name', 'Item__r.Item_Attribute__c', 'Order_Line__c','Packaging_UOM__c','Packaging_UOM__r.Name'
                      });
        soql.setWhereClause(whereClause);
        
        for( sObject transitSkid : Database.query(soql.getQuery())){
            
            Id olId = (Id)transitSkid.get('Order_Line__c');
            List<string> attributesList = itemToAttributesMap.get((id)transitSkid.get('Item__c'));
            string attributeKey='';
            
            for(String attr: attributesList)
            {
                if(attr != 'Bin__c'){
                   if(attr == 'Lot_Number__c'){    
                    
                        if(transitSkid.get('Lot__c')!=null){    
                            attributeKey+= attr + ': ' + transitSkid.get('Lot__c') + ' | ';
                        }
                   }
                   else{
                       attributeKey+= attr + ': ' + transitSkid.get(attr) + ' | ';
                   }
                }
            }
            
            if(attributesList.size()==0){
                attributeKey = 'NO ATTRIBUTES';
            }
            
            if(!orderlineIntransitKeyMap.containsKey(olId)){
                orderlineIntransitKeyMap.put(olId, new Set<String>());
            }

            orderlineIntransitKeyMap.get(olId).add(attributeKey);
            
        }
        
        for( receivingWrapper rw : rlWrapperList ){
            
            String allKeys= '';
            
            if( (Boolean)rw.rl.getSObject('Receiving_Item__r').get('Non_Inventory__c') == false){
                
                List<string> attributes= rw.trackedAttributes;
                
                for( Integer i = 0; i < rw.serialWrapperList.size(); i ++ ){
                    
                    String key='';
                    String attributeKeyLabel='';
                    SKID__c skid = rw.serialWrapperList[i].skid;
                    
                    for(String attr: attributes){
                    	
                        if(attr != 'Bin__c'){
                            if(attr == 'Lot_Number__c'){    
                                key+= attr + ': ' + skid.Lot__c + ' | ';
                                attributeKeyLabel+= skidsFieldsMap.get(attr).getDescribe().getLabel() + ': ' + skid.Lot_Number__c + ' | ';
                                
                           }
                           else if(attr == 'Packaging_UOM__c'){
                           		key+= attr + ': ' + skid.get(attr) + ' | ';
                           		attributeKeyLabel+= skidsFieldsMap.get(attr).getDescribe().getLabel() + ': ' + skid.Packaging_UOM__r.Name + ' | ';
                           }
                           else{
                               key+= attr + ': ' + skid.get(attr) + ' | ';
                               attributeKeyLabel+= skidsFieldsMap.get(attr).getDescribe().getLabel() + ': ' + skid.get(attr) + ' | ';
                           }
                        }
                    }
                    
                    if(attributes.size()==0){
                        key = 'NO ATTRIBUTES';
                        attributeKeyLabel = 'NO ATTRIBUTES';
                    }
                    
                    if(!orderlineIntransitKeyMap.containsKey(rw.rl.Id) || (orderlineIntransitKeyMap.containsKey(rw.rl.Id) && 
                       !orderlineIntransitKeyMap.get(rw.rl.Id).contains(key)) ){
                            
                        allKeys +=attributeKeyLabel;
                        orderlineKeyMismatchExceptionList.put(rw.rl.Id,allKeys);
                   }
                }
            }
        }
    }
    
    public void voidOrderReceipts(Set<Id> voidReceivingDocuments, String action){
        if(action == null) {action = RD_STATUS_VOID;}
            
        Map<Id, sObject> mOrderLines = new Map<Id, sObject>();
        Map<Id, sObject> mOrders = new Map<Id, sObject>();
        Set<Id> receiptLineIds = new Set<Id>();
        List<Receiving_Document__c> updateReceivingDocuments = new List<Receiving_Document__c>();
        Map<id,Receipt_Line__c> getReceiptLine = new Map<Id,Receipt_Line__c>();
        List<Receipt_Line__c> updateReceiptLines = new List<Receipt_Line__c>();
        List<ASN_Line__c> updateASNLines = new List<ASN_Line__c>();        
        List<Accounting_Entry__c> voidAccountingEntries = new List<Accounting_Entry__c>();
        Map<Id, Decimal> oIdToReceiptLineMap = new Map<Id, Decimal>(); //KNDY-3448
        Map<Id, Decimal> oIdToReceiptLineStockingMap = new Map<Id, Decimal>();
        Map<Id,Decimal> qtyToReceiveByOLMap = new map<Id,Decimal>();
        list<String> attributesForService = new list<String>();
        
        list<SkidService3.SerialWrapper> supplySkidsPO = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> inTransitSkids = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> inTransitPOSkids = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> voidSerialWrappers = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> skidWrapperList = new list<SkidService3.SerialWrapper>();
        Map<Id,SkidService3.ParameterData> data = new Map<Id,SkidService3.ParameterData>();
        map<Id, Decimal> quantityByOL = new map<Id, Decimal>();
        Boolean TransferOrderflag = false;
        List<Inventory_Transaction__c> itsToUpdate = new List<Inventory_Transaction__c>();
        Map<Id,Fulfillment__c> fulfillmentMap = new Map<Id,Fulfillment__c>();
        

 	list<String> attributesForNegativeSkids = SkidService3.attributesForPutaway();

        list<String> attributesForSupply = SkidService3.attributesForPutaway();
        list<String> attributesforRDVoid = SkidService3.attributesForPutaway();
        List<String> attributesForTOSkids = SkidService3.attributesForPutaway(null,new Set<String>{'shipment_line__c'});        
        attributesForTOSkids.add('Order_Line__c');
        
        Set<Id> rmaReceiptIDs = new Set<Id>();
        Set<Id> rlswithCIsublines = new Set<Id>();
      
         Set<Id>solIDs = new Set<Id>();
         Map<ID,ID>rmaSOLineMap = new Map<Id,ID>();
         Map<ID,ID>rlswithOpenRepairSOLs = new Map<Id,ID>();
        
        Map<id,Map<string,string>>  mapReceivingDocTypeParameters = new Map<id,Map<string,string>>();
        Savepoint sp = Database.setSavepoint();

        Map<String,String> configMap =  new Map<String,String>{ 'adjustFromSkidQuantity'=>'none','putawayDirection' => 'from', 'serialTransactionType' => 'Void Receipt' };
        Map<String,Boolean> putawayConfigMap = new Map<String,Boolean>{ SkidService3.UNDO_SERIAL => true, SkidService3.VOID_SERIALS => true };
        Map<List<String>,List<String>> keyMap = new Map<List<String>,List<String>>();

        try {
            SOQLUtil rdQuery = new SOQLUtil('Receiving_Document__c');
            rdQuery.addFields(new Set<String>{ 'Id','Name','Company__c','Type__c','Transaction_Type__c' });
            rdQuery.setWhereClause('Id IN :voidReceivingDocuments');

            SOQLUtil.ChildRelationship rlQuery = new SOQLUtil.ChildRelationship(rdQuery,'Receipt_Lines__r');
            rlQuery.addFields(new Set<String>{ 'Id','Name','Purchase_Order_Line__c','Purchase_Order_Line__r.Stocking_UOM__c','Purchase_Order_Line__r.Item__r.Stocking_UOM__c','Purchase_Order_Line__r.Item__r.Packaging_UOM__c','Purchase_order_line__r.Purchase_UOM__c','Invoiced__c','Uninvoiced_Quantity__c','Sales_Order_Line__c','Sales_Order_Line__r.Related_Sales_Order_Line__c', 'Sales_Order_Line__r.Related_Sales_Order_Line__r.Status__c','Order_Line__c','Item__r.Non_Inventory__c','Item__r.Stocking_UOM__c',
                'Quantity_To_Stock__c','Quantity_Received__c','Quantity_Shipped__c','Quantity_Returned_to_Supplier_for_Credit__c','Quantity_Returned_to_Supplier__c','Line_Type__c','Quantity_to_Consume__c','Purchase_Order_Line__r.Purchase_Order__c','Purchase_Order_Line__r.Item__r.Container__c',
                'Purchase_Order_Line__r.Type__c','Purchase_Order_Line__r.Item__c','Purchase_Order_Line__r.Quantity_Still_Due__c','Purchase_Order_Line__r.Quantity_Received__c',
                'Purchase_Order_Line__r.Delivery_Location__c','Purchase_Order_Line__r.Delivery_Location__r.Facility__c','Purchase_Order_Line__r.Quantity_Shipped__c','Purchase_Order_Line__r.Quantity_Returned_to_Supplier_for_Credit__c',
                'Purchase_Order_Line__r.Quantity_Returned_to_Supplier__c','Purchase_Order_Line__r.Purchase_Order__r.Type__c','ASN_Line__r.Quantity_Received__c','ASN_Line__r.Status__c',
                'Purchase_Order_Line__r.Sales_Order_Line__r.Fulfillment_Source__c','Order_Line__r.Quantity_To_Receive__c','Order_Line__r.Quantity_Ordered__c','Order_Line__r.Order__c','Order_Line__r.Deliver_To_Facility__c', 'Order_Line__r.Receiving_Item__r.Packaging_UOM__c',
                'Order_Line__r.Receiving_Item__r.Non_Inventory__c','Order_Line__r.Receiving_Item__r.Stocking_UOM__c','Order_Line__r.Shipping_Item__r.Packaging_UOM__c','Order_Line__r.Receiving_Item__c','Order_Line__r.Quantity_Received__c','Order_Line__r.Deliver_To_Location__c','Order_Line__r.Quantity_Shipped__c',
                'Order_Line__r.Shipping_Item__c','Order_Line__r.Receiving_Item__r.Packaging_UOM__c','Order_Line__r.Shipping_Item__r.Non_Inventory__c','Order_Line__r.Shipping_Item__r.Stocking_UOM__c', 'Purchase_Order_Line__r.Item__r.Non_Inventory__c'});
            rdQuery.addChildRelationship(rlQuery);

            SOQLUtil.ChildRelationship aeQuery = new SOQLUtil.ChildRelationship(rdQuery,'Accounting_Entries__r');
            aeQuery.addFields(new Set<String>{ 'Id','Name' });
            aeQuery.setWhereClause('Void__c = false');
            rdQuery.addChildRelationship(aeQuery);

            List<Receiving_Document__c> receivingDocs = Database.query(rdQuery.getQuery());
            
            for(Receiving_Document__c rd : receivingDocs){
              if(rd.Type__c.toLowerCase() == 'RMA Receipt'.toLowerCase()  || rd.Type__c.toLowerCase() == 'Logical RMA Receipt'.toLowerCase() || rd.Type__c.toLowerCase() == 'RMA Receipt For Repair'.toLowerCase()){
                    for(Receipt_Line__c rl : rd.Receipt_Lines__r){
                            rmaReceiptIDs.add(rl.Id);
                    }
                }
     
              if(rd.Type__c.toLowerCase() == 'RMA Receipt For Repair'.toLowerCase()){
                    for(Receipt_Line__c rl : rd.Receipt_Lines__r){
                            if (rl.Sales_Order_Line__c != null) {
                                solIDs.add(rl.Sales_Order_Line__c);
                                rmaSOLineMap.put(rl.Sales_Order_Line__c,rl.Id);
                            }    
                    }                 
                }
    
             }
             
             SOQLUtil ciQuery = new SOQLUtil('Customer_Invoice_Sub_Line__c',false);
             ciQuery.addFields(new Set<String>{ 'Id','Fulfillment__r.Receipt_Line__c' });
             ciQuery.setWhereClause('Fulfillment__r.Receipt_Line__c in :rmaReceiptIDs and Customer_Invoice_Line__r.Customer_Invoice__r.Status__c != \'Cancelled\' and Customer_Invoice_Line__r.Customer_Invoice__r.Void__c = false');
              
             for(Customer_Invoice_Sub_Line__c cisubLine : Database.query(ciQuery.getQuery())){
                  rlswithCIsublines.add(cisubLine.Fulfillment__r.Receipt_Line__c);
             }
		
		// Cannot void/cancel RD of type RMA Receipt for Repair if there are open SO lines.
		
			 SOQLUtil solQuery = new SOQLUtil('Sales_Order_Line__c',false);
             solQuery.addFields(new Set<String>{ 'Id','Status__c','Related_Sales_Order_Line__c', 'Product__r.Item__r.Packaging_UOM__c' });
             solQuery.setWhereClause('Related_Sales_Order_Line__c in :solIDs and (Status__c != \'Closed\' and Status__c != \'Cancelled\')');	
			 System.debug(Logginglevel.info,'solIDs:'+solIDs);
			 System.debug(Logginglevel.info,'solQuery.getQuery():'+solQuery.getQuery());
            for(Sales_Order_Line__c repairSOL : Database.query(solQuery.getQuery())){
                  ID rmaRCLID = rmaSOLineMap.get(repairSOL.Related_Sales_Order_Line__c);
                  rlswithOpenRepairSOLs.put(rmaRCLID,repairSOL.Id);
             }
             
             
             
      //Set void status on header and lines, organize data for later reference
            Map<Id,Id> solToPol = new Map<Id,Id>();
           for(Receiving_Document__c rd : receivingDocs){
                
                rd.status__c = action;
                Map<string,string> mapParameters=new Map<string,string>();
                if(rd.Type__c.toLowerCase()=='Transfer Order Receipt'.toLowerCase())
                {
                    attributesForSupply.add('Order_Line__c');
                } else if (rd.Type__c.toLowerCase() == 'purchase order receipt') {
                    attributesForSupply.add('Purchase_Order_Line__c');
                }

                if (rd.Type__c.toLowerCase() == 'purchase order receipt' && rd.Transaction_Type__c != null && rd.Transaction_Type__c.toLowerCase() == 'logical purchase order receipt') {
                    mapParameters.put('sourceDocVoid','Void - ' + rd.Transaction_Type__c);
                }
                else if(rd.Transaction_Type__c!= null && rd.Transaction_Type__c.toLowerCase()=='In-Transit Purchase Order Receipt'.toLowerCase()){
                    mapParameters.put('sourceDocVoid','Void - In-Transit Purchase Order Receipt');
                } else {
                    mapParameters.put('sourceDocVoid','Void - ' + rd.Type__c);
                }
                 
                mapReceivingDocTypeParameters.put(rd.Id,mapParameters);
                updateReceivingDocuments.add(rd);

                for (Receipt_Line__c rl:rd.Receipt_Lines__r) {
                    if (rl.Purchase_Order_Line__c != null && rl.Purchase_Order_Line__r.Sales_Order_Line__c != null && rl.Purchase_Order_Line__r.Type__c == 'Back To Back') {
                        solToPol.put(rl.Purchase_Order_Line__r.Sales_Order_Line__c,rl.Purchase_Order_Line__c);
                    }
                    
                    //check if receipt is invoiced in full or uninvoiced quantity is > 0

                    if ((!rl.Invoiced__c) && (((rl.Line_Type__c!= 'Consigned' && rl.Uninvoiced_Quantity__c == rl.Quantity_Received__c) || (rl.line_Type__c == 'Consigned' && rl.Quantity_To_Consume__c == rl.Quantity_Received__c)) || rd.Type__c == RD_STATUS_INTRANSIT ||
                                                rd.Type__c == RD_TYPE_RETURN || rd.Type__c == RD_TYPE_MISCELLANEOUS )) //KNDY-2365
                    {
                        rl.status__c = action;
                        Decimal updatedQtyShipped = 0;//rl.order_line__r.Quantity_Shipped__c - rl.Quantity_Shipped__c;
                        receiptLineIds.add(rl.Id);
                        updateReceiptLines.add(rl);
                        getReceiptLine.put(rl.Id,rl);
                        if(rd.Type__c.toLowerCase()=='Transfer Order Receipt'.toLowerCase())
                        {
                            updatedQtyShipped = rl.order_line__r.Quantity_Shipped__c - rl.Quantity_Shipped__c;
                            mOrderLines.put(rl.order_line__c, new Order_Line__c(Id = rl.order_line__c, status__c = 'Open', Shipping_Company__c = rd.Company__c,
                             quantity_received__c = rl.order_line__r.quantity_received__c, deliver_to_location__c = rl.order_line__r.deliver_to_location__c, deliver_to_facility__c = rl.order_line__r.deliver_to_facility__c,
                            Receiving_Item__c = rl.order_line__r.Receiving_Item__c, Receiving_Item__r = rl.order_line__r.Receiving_Item__r, Quantity_Shipped__c = updatedQtyShipped));
                            mOrders.put(rl.order_line__r.order__c, new Order__c(Id = rl.order_line__r.order__c, Status__c = 'Open'));
                        
                            if(!oIdToReceiptLineMap.containsKey(rl.order_line__c) ){
                                oIdToReceiptLineMap.put(rl.Order_Line__c,0 );
                            }
                            
                            if(!oIdToReceiptLineStockingMap.containsKey(rl.order_line__c) ){
                                oIdToReceiptLineStockingMap.put(rl.Order_Line__c,0 );
                            }

                            qtyToReceiveByOLMap.put(rl.Order_Line__c,rl.Order_Line__r.Quantity_To_Receive__c);
                            oIdToReceiptLineStockingMap.put(rl.Order_Line__c, KSE.addQuantityToField(oIdToReceiptLineStockingMap.get(rl.Order_Line__c), rl.Quantity_To_Stock__c));
                            oIdToReceiptLineMap.put(rl.Order_Line__c, KSE.addQuantityToField(oIdToReceiptLineMap.get(rl.Order_Line__c), rl.Quantity_Received__c));
                        }
                        else if(rd.Type__c.toLowerCase()=='Purchase Order Receipt'.toLowerCase() 
                            || ( rd.Transaction_Type__c!= null && rd.Transaction_Type__c.toLowerCase()=='Logical Purchase Order Receipt'.toLowerCase() ))
                        {
                            updatedQtyShipped = rl.Purchase_order_line__r.Quantity_Shipped__c - rl.Quantity_Shipped__c;
                            mOrderLines.put(rl.Purchase_order_line__c, new Purchase_Order_Line__c(Id = rl.Purchase_order_line__c, status__c = 'Open', Company__c = rd.Company__c,
                            quantity_received__c = rl.Purchase_order_line__r.quantity_received__c, delivery_location__c = rl.Purchase_order_line__r.delivery_location__c,
                            Item__c = rl.Purchase_order_line__r.Item__c, Item__r = rl.Purchase_order_line__r.Item__r, Quantity_Shipped__c = updatedQtyShipped,
                                      Packaging_UOM__c = rl.Purchase_order_line__r.Purchase_UOM__c,
                                      Stocking_UOM__c = rl.Purchase_order_line__r.Stocking_UOM__c,
                                      Delivery_Location__r=rl.Purchase_Order_Line__r.Delivery_Location__r));//, Packaging_UOM__c = rl.Purchase_order_line__r.Purchase_UOM__c,Stocking_UOM__c = rl.Purchase_order_line__r.Stocking_UOM__c
                            mOrders.put(rl.Purchase_order_line__r.Purchase_order__c, new Purchase_Order__c(Id = rl.Purchase_order_line__r.Purchase_order__c, Status__c = 'Open'));
                             if(!oIdToReceiptLineMap.containsKey(rl.Purchase_order_line__c) ){
                                oIdToReceiptLineMap.put(rl.Purchase_order_line__c,0 );
                             }
                            qtyToReceiveByOLMap.put(rl.Purchase_Order_Line__c,rl.Purchase_Order_Line__r.Quantity_Still_Due__c);
                            oIdToReceiptLineMap.put(rl.Purchase_order_line__c, KSE.addQuantityToField(oIdToReceiptLineMap.get(rl.Purchase_order_line__c), rl.Quantity_Received__c));

                            if(rl.ASN_Line__c != null ){
                                rl.ASN_Line__r.Status__c = 'Open';
                                rl.ASN_Line__r.Quantity_Received__c = KSE.subtractDecimals(rl.ASN_Line__r.Quantity_Received__c,rl.Quantity_Received__c);
                                updateASNLines.add(rl.ASN_Line__r);
                            }
                        }
                        else if (rd.Type__c == 'Purchase Order Return' || rd.Type__c == 'Logical Purchase Order Return') {
                            Purchase_Order_Line__c poLine;
                            if (mOrderLines.containsKey(rl.Purchase_Order_Line__c))
                                poLine = (Purchase_Order_Line__c)mOrderLines.get(rl.Purchase_Order_Line__c);
                            else
                                poLine = new Purchase_Order_Line__c(Id = rl.Purchase_Order_Line__c,Item__c=rl.Purchase_Order_Line__r.Item__c,Item__r=rl.Purchase_Order_Line__r.Item__r, Quantity_Returned_to_Supplier_for_Credit__c = rl.Purchase_Order_Line__r.Quantity_Returned_to_Supplier_for_Credit__c,Quantity_Returned_to_Supplier__c = rl.Purchase_Order_Line__r.Quantity_Returned_to_Supplier__c);
                            poLine.Quantity_Returned_to_Supplier_for_Credit__c = KSE.subtractDecimals(poLine.Quantity_Returned_to_Supplier_for_Credit__c,rl.Quantity_Returned_to_Supplier_for_Credit__c);
                            poLine.Quantity_Returned_to_Supplier__c = KSE.subtractDecimals(poLine.Quantity_Returned_to_Supplier__c,rl.Quantity_Returned_to_Supplier__c);
                            mOrderLines.put(poLine.Id,poLine);
                        }
                    }
                    else
                    {
                        throw new ReceivingDocumentServiceV2Exception(rd.name + Label.Cannot_Void_this_Document);
                    } 
  
                   if(rlswithOpenRepairSOLs.get(rl.ID) != null ) 
                        throw new ReceivingDocumentServiceV2Exception(rd.name + Label.Cannot_void_or_cancel_if_open_repair_Sales_order_lines);  
                        
                   if(rlswithCIsublines.contains(rl.Id))   
                        throw new ReceivingDocumentServiceV2Exception(rd.name + Label.Cannot_Void_this_Document);     
                        
                    
                    if(rd.Type__c.toLowerCase() == 'RMA Receipt'.toLowerCase()  || rd.Type__c.toLowerCase() == 'Logical RMA Receipt'.toLowerCase() || rd.Type__c.toLowerCase() == 'RMA Receipt For Repair'.toLowerCase()){
                        fulfillmentMap.put(rl.Sales_Order_Line__c, new Fulfillment__c(Type__c = 'RMA', Quantity__c = rl.Quantity_Received__c, Receipt_Line__c = rl.Id, Fulfillment_Date__c = system.today())); //need to check date on fulfillment
                    }  
                }
                voidAccountingEntries.addAll(rd.Accounting_Entries__r);
            }

            Map<Id,Map<Id,List<SkidService3.SerialWrapper>>> skidsToUnallocate = new Map<Id,Map<Id,List<SkidService3.SerialWrapper>>>();
            Map<Id,Shipment_Line__c> shlMap = new Map<Id,Shipment_Line__c>();
            if (solToPol.size() > 0) {
                Set<Id> solSet = solToPol.keySet();
                SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
                shlQuery.addAllCustomFields();
                shlQuery.addFields(new Set<String>{ 'Sales_Order_Line__r.Quantity_From_Stock__c','Sales_Order_Line__r.Quantity_Ordered__c','Product__r.Item__r.Non_Inventory__c','Shipment__r.Status__c', 'Item__r.Packaging_UOM__c' });
                shlQuery.setWhereClause('Sales_Order_Line__c IN :solSet AND Product__r.Item__r.Non_Inventory__c = false AND Shipment__r.Status__c != \'Confirmed\'');
                for (Shipment_Line__c shl:Database.query(shlQuery.getQuery())) {
                    shlMap.put(solToPol.get(shl.Sales_Order_Line__c),shl);
                }
            }
            
            if(fulfillmentMap.values().size() > 0){
                FulfillmentService.fulfillSalesOrders(fulfillmentMap.keyset(), fulfillmentMap);
            }

            SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
            itQuery.addAllCustomFields();
            itQuery.addAllCustomFields(Receipt_Line__c.sObjectType,'Receipt_Line__r');
            itQuery.addAllCustomFields(Material_Tracking__c.sObjectType,'Receipt_Line__r.Purchase_Order_Line__r.Material_Tracking__r');
            itQuery.addFields(new Set<String>{'Item__r.Container_Item__r.Container_Package_Class__c','Item__r.Container_Item__r.Container_Package_Class__r.Level__c','Container_Item__r.Container_Package_Class__r.Level__c', 'Packaging_UOM__r.Package_Class__c', 'Packaging_UOM__r.Package_Class__r.Level__c', 'Item__r.Packaging_UOM__c', 'Quantity_Stocking_UOM__c','Packaging_UOM__c','Packaging_UOM__r.Name','From_Lot__r.Name','To_Location__r.Facility__c','From_Location__r.Facility__c','From_Location__r.Mixed_Bins_Allowed__c','To_Location__r.Mixed_Bins_Allowed__c','To_Location__r.Track_Bin_Capacity__c','From_Location__r.Track_Bin_Capacity__c','Item__r.Item_Attribute__r.Serial_Number__c','Item__r.Stocking_UOM__c','Item__r.Container__c',
                'Receipt_Line__r.Receiving_Document__r.Type__c','Receipt_Line__r.Order_Line__r.Deliver_To_Location__c','Receipt_Line__r.ASN_Line__r.Purchase_Order_Line__r.Stocking_UOM__c','Receipt_Line__r.ASN_Line__r.Item__c','Receipt_Line__r.ASN_Line__r.Purchase_order_line__r.Purchase_UOM__c','Receipt_Line__r.ASN_Line__r.Purchase_order_line__r.Purchase_UOM__r.Name','Receipt_Line__r.Receiving_Document__r.Transaction_Type__c','Receipt_Line__r.Purchase_Order_Line__r.Sales_Order_Line__c','Receipt_Line__r.Purchase_Order_Line__r.Type__c',
                'consigned_owner__c','purchase_order_line__c','Item__r.Container_Package_Class__r.Level__c','Mixed_Palletized__c',
                'Receipt_Line__r.ASN_Line__r.Item__r.Stocking_UOM__c','Receipt_Line__r.Purchase_Order_Line__r.Material_Tracking__c','Receipt_Line__r.Receiving_Document__r.Currency__c', 'Receipt_Line__r.Receiving_Document__r.Transaction_Date__c', 'From_Facility__r.Facility_Identifier__c', 'To_Facility__r.Facility_Identifier__c',

                'From_Container_Item__r.Container_Package_Class__c', 'From_Container_Item__r.Container_Package_Class__r.Level__c',

                'Order_Line__r.Order__c' });
            itQuery.setWhereClause('Receipt_Line__c IN :receiptLineIds AND Type__c IN (\'RMA Receipt\',\'RMA Receipt For Repair\',\'Logical RMA Receipt\',\'Purchase Order Receipt\',\'Purchase Order Return\',\'Logical Purchase Order Return\',\'Transfer Order Receipt\',\'Logical Purchase Order Receipt\',\'Miscellaneous Receipt\',\'Return Receipt\')');

            SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
            stQuery.addAllCustomFields();
            stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
            itQuery.addChildRelationship(stQuery);

            List<Inventory_Transaction__c> receivingTransactions = Database.query(itQuery.getQuery());

            List<SKID__c> skids = new List<SKID__c>();
            Map<Id, List<Id>> itemPackagingUOMCache = new Map<Id, List<Id>> ();
            for (Inventory_Transaction__c it:receivingTransactions) {
                SKID__c skid = new SKID__c(Type__c = SkidService3.SKID_TYPE_LOCATION);
                SkidService3.copyItAttributesToSkid(skid, it, null);

            	if(it.Type__c == 'RMA Receipt For Repair'){
            		skid.Sales_Order_Line__c = it.Sales_Order_Line__c;
            	}
                
                if (it.Consigned_Owner__c != null) skid.Purchase_Order_Line__c = it.Purchase_Order_Line__c;
                if (it.Type__c == 'Logical Purchase Order Receipt') skid.Shipment_Line__c = it.Shipment_Line__c;
                skids.add(skid);
                if(it.Receipt_Line__r.Receiving_Document__r.Type__c != 'Purchase Order Return' && it.Receipt_Line__r.Receiving_Document__r.Type__c != 'Logical Purchase Order Return'){
                	SKID__c putawaySkid;
	                putawaySkid = skid.clone(true,true);
	                putawaySkid.Quantity__c = -it.Quantity__c;//negative
	                	
	                putawaySkid.Company__c = it.Company__c;
	                skidWrapperList.add(new SkidService3.SerialWrapper(putawaySkid, new list<Serial__c>()));
                }
                
            }
            
            Map<List<String>,SKID__c> existingSkids = new Map<List<String>,SKID__c>();
            Map<Id,Set<Id>> existingSerials = new Map<Id,Set<Id>>();
            if (skids.size() > 0) {
                existingSkids = SkidService3.generateExistingSkidMap(null,skids,false,null);

                if (existingSkids.size() > 0) {
                    Set<Id> skidIds = (new Map<Id,SKID__c>(existingSkids.values())).keySet();
                    SOQLUtil serialQuery = new SOQLUtil('Serial__c');
                    serialQuery.addAllCustomFields();
                    serialQuery.setWhereClause('SKID__c IN :skidIds');
                    for (Serial__c serial:Database.query(serialQuery.getQuery())) {
                        if (!existingSerials.containsKey(serial.SKID__c)) {
                            existingSerials.put(serial.SKID__c,new Set<Id>());
                        }
                        existingSerials.get(serial.SKID__c).add(serial.Id);
                    }
                }
            }
            
            for (Inventory_Transaction__c it:receivingTransactions) {
                List<Serial__c> serialList = new List<Serial__c>();
                List<Serial__c> inTransitSerialList = new List<Serial__c>();
                
                for( Serial_Transaction__c st : it.Serial_Transactions__r ){
                    st.Serial__r.allow_reentry__c = false;
                    serialList.add(st.Serial__r);
                    inTransitSerialList.add(st.Serial__r.clone(true,true));
                }
                
                SKID__c inTransitSkid;
                SKID__c inTransitPOSkid;
                SKID__c poAllocatedSkid;
                
                Inventory_Transaction__c voidIt;
                
                if (it.Type__c.toLowerCase() == 'transfer order receipt') {  
                    inTransitSkid = new SKID__c(
                        Company__c = it.Company__c,
                        Type__c = SkidService3.SKID_TYPE_INTRANSIT,
                        Order_Line__c = it.Order_Line__c,
                        Order_Line__r = it.Order_Line__r,
                        Shipment_Line__c = it.Receipt_Line__r.Shipment_Line__c
                    );
                    
                    if(!quantityByOL.containsKey(it.receipt_line__r.Order_Line__c)){
                        quantityByOL.put(it.receipt_line__r.Order_Line__c,0 );
                    }
                    quantityByOL.put(it.receipt_line__r.Order_Line__c, KSE.addQuantityToField(quantityByOL.get(it.receipt_line__r.Order_Line__c), it.Quantity__c));
                    
                    SkidService3.copyITAttributesToSkid( inTransitSkid, it, null );
                    inTransitSkid.Location__c = it.receipt_line__r.order_line__r.deliver_to_location__c;
                    inTransitSkid.Bin__c = null;
                    inTransitSkid.Quantity__c =  it.Quantity__c;
                    inTransitSkid.Lot_Number__c =  it.From_Lot__r.Name;
                    if(it.Consigned_Owner__c !=null){
                     	inTransitSkid.Consigned_Owner__c = it.Consigned_Owner__c;
                    }
                    if(it.Purchase_Order_Line__c !=null){
                        inTransitSkid.Purchase_Order_Line__c = it.Purchase_Order_Line__c;
                    }
                    inTransitSkid.Stocking_UOM__c = it.Stocking_UOM__c;
                    inTransitSkid.Item__r = it.Item__r;

                    if (it.Mixed_Palletized__c == true) {
                        inTransitSkid.Mixed_Palletized__c = true;
                        inTransitSkid.License_Plate_Number__c = it.From_License_Plate_Number__c;
                        inTransitSkid.License_Plate_Number__r = it.From_License_Plate_Number__r;
                        inTransitSkid.Container_Item__c = it.From_Container_Item__c;
                        inTransitSkid.Container_Item__r = it.From_Container_Item__r;
                    }
                    
                    SkidService3.SerialWrapper swIntransit = new SkidService3.SerialWrapper( inTransitSkid, null, null);
                    
                    inTransitSkids.Add(swIntransit);
                    TransferOrderflag = true;
                }
                else if(it.Type__c.toLowerCase()=='Purchase Order Receipt'.toLowerCase())
                {
                    if(!quantityByOL.containsKey(it.receipt_line__r.Purchase_Order_Line__c)){
                        quantityByOL.put(it.receipt_line__r.Purchase_Order_Line__c,0 );
                    }
                    quantityByOL.put(it.receipt_line__r.Purchase_Order_Line__c, KSE.addQuantityToField(quantityByOL.get(it.receipt_line__r.Purchase_Order_Line__c), it.Quantity__c));
         
                    if(it.Receipt_Line__r.Receiving_Document__r.Transaction_Type__c!= null && it.Receipt_Line__r.Receiving_Document__r.Transaction_Type__c.toLowerCase() == 'In-Transit Purchase Order Receipt'.toLowerCase()){

                        attributesforRDVoid.add('ASN_Line__c');
                        inTransitPOSkid = new SKID__c(Type__c = SkidService3.SKID_TYPE_INTRANSIT,ASN_Line__c = it.receipt_line__r.ASN_Line__c,company__c = it.receipt_line__r.company__c, Item__c = it.receipt_line__r.ASN_Line__r.Item__c,//,Item__r = it.receipt_line__r.ASN_Line__r.Item__r
                        								Stocking_UOM__c = it.receipt_line__r.ASN_Line__r.Purchase_Order_Line__r.Stocking_UOM__c, Packaging_UOM__c = it.receipt_line__r.ASN_Line__r.Purchase_order_line__r.Purchase_UOM__c);
                        SkidService3.copyITAttributesToSkid( inTransitPOSkid, it, null );
                        inTransitPOSkid.Location__c = it.From_Location__c;
                        inTransitPOSkid.Quantity__c =  it.Quantity__c;
                        inTransitPOSkid.Lot_Number__c =  it.From_Lot__r.Name;
                        inTransitPOSkid.Item__r = it.Item__r;
                        if(inTransitPOSkid.Bin__c != null){
                        	inTransitPOSkid.Bin__c = null;
                        	inTransitPOSkid.Bin__r = null;
                        }

                        SkidService3.SerialWrapper swPOIntransit = new SkidService3.SerialWrapper( inTransitPOSkid, inTransitSerialList);
                        inTransitPOSkids.Add(swPOIntransit);
                        
                    }
                }
                
                String type = mapReceivingDocTypeParameters.get(getReceiptLine.get(it.receipt_Line__r.id).Receiving_Document__c).get('sourceDocVoid');
                
                if (it.Type__c != 'Purchase Order Return' && it.Type__c != 'Logical Purchase Order Return') {
                    Inventory_Transaction__c itClone = it.clone(false, true);
                    itClone.Receipt_Line__c = null;
                    //if (it.Type__c != 'RMA Receipt For Repair') itClone.Receipt_Line__c = null;
                    if (it.Consigned_Owner__c == null) itClone.Purchase_Order_Line__c = null;
                    if (it.Type__c != 'Logical Purchase Order Receipt') itClone.Shipment_Line__c = null;
                    if (it.Type__c == 'Logical Purchase Order Receipt') itClone.Sales_Order_Line__c = null;
                    
                    List<String> key = SkidService3.generateKey(itClone,null);

                    if (!existingSkids.containsKey(key)) {
                        throw new ReceivingDocumentServiceV2Exception(Label.Cannot_void_this_Receiving_Document_does_not_have_matching_inventory + Label.Item_attributes_dont_match + ' for ' + it.Receipt_Line__r.Name);
                    }

                    SKID__c existingSkid = existingSkids.get(key).clone(true, true);
                    if (existingSkid.Quantity__c < it.Quantity__c) {
                        throw new ReceivingDocumentServiceV2Exception(Label.Cannot_void_this_Receiving_Document_does_not_have_matching_inventory + Label.Inventory_do_not_match + ' for ' + it.Receipt_Line__r.Name);
                    }
                    if (existingSerials.containsKey(existingSkid.Id) && !existingSerials.get(existingSkid.Id).containsAll((new Map<Id,Serial__c>(serialList)).keySet())) {
                        throw new ReceivingDocumentServiceV2Exception(Label.Cannot_void_this_Receiving_Document_does_not_have_matching_inventory + Label.Serials_do_not_match_inventory + ' for ' + it.Receipt_Line__r.Name);
                    }
     
                    voidIt = SkidService3.createInventoryTransaction(it.Receipt_Line__r,type,it.Quantity__c,existingSkid,existingSkid,null);
                    voidIt.To_SKID__c = null;
                    voidIt.To_SKID__r = null;
                    if(it.Order_Line__c != null)
                    	voidIt.Order_Line__c = it.Order_Line__c;
                    
                    if(it.Receipt_Line__r.ASN_Line__c !=null && (voidIt.Bin__c !=null)){
                    	voidIt.Bin__c = null;
                    	voidIt.Bin__r = null;
                    }
                    voidIT.Receipt_Line__r = it.Receipt_Line__r;
                    if(inTransitPOSkid !=null){
                    	configmap.put('retainToSkidInfo','true');
                    	
                    }
                    voidSerialWrappers.add(new SkidService3.SerialWrapper(voidIt,serialList));
                } else {
                    SKID__c skid = new SKID__c(
                        Company__c = it.Company__c,
                        Type__c = SkidService3.SKID_TYPE_LOCATION,
                        Quantity__c = it.Quantity__c
                    );
                    SkidService3.copyITAttributesToSkid(skid,it,null);
                    skid.Facility2__c = it.From_Facility__c;
                    skid.Location__c = it.From_Location__c;
                    skid.Lot__c = it.From_Lot__c;
                    skid.Lot_Number__c = it.From_Lot__r.Name;
                    skid.Bin__c = it.From_Bin__c;
                    skid.Item__r = it.Item__r;
                    if((skid.Container_Item__c == it.Item__r.Container_Item__c)){
                        skid.Container_Item__r = it.Item__r.Container_Item__r;
                    }
                    voidSerialWrappers.add(new SkidService3.SerialWrapper(skid,serialList));

                    voidIt = SkidService3.createInventoryTransaction(it.Receipt_Line__r,type,it.Quantity__c,null,skid,null);

                    configMap.put('serialTransactionType','Void Return');
                    configMap.remove('putawayDirection');
                    
                	putawayConfigMap.remove(SkidService3.UNDO_SERIAL);
                	putawayConfigMap.remove(SkidService3.VOID_SERIALS);
                	
                	keyMap.put(SkidService3.generateKey(voidIt, null), SkidService3.generateKey(skid, null));
                }
                
                if(it.Receipt_Line__r.Receiving_Document__r.Transaction_Date__c !=null)
                	voidIt.Transaction_Date__c = it.Receipt_Line__r.Receiving_Document__r.Transaction_Date__c;
                else
                	voidIt.Transaction_Date__c = it.Transaction_Date__c;

                if (it.Receipt_Line__r.Purchase_Order_Line__c != null) {
                    Id headerId;
                    Id lineId;
                    Decimal qtyToUnallocate;
                    if (it.Receipt_Line__r.Purchase_Order_Line__r.Material_Tracking__c != null && it.Receipt_Line__r.Purchase_Order_Line__r.Material_Tracking__r.Allocation_Required__c && it.Receipt_Line__r.Purchase_Order_Line__r.Material_Tracking__r.Allocate_On_Receipt__c) {
                        headerId = it.Receipt_Line__r.Purchase_Order_Line__r.Material_Tracking__r.Work_Order__c;
                        lineId = it.Receipt_Line__r.Purchase_Order_Line__r.Material_Tracking__c;
                        qtyToUnallocate = KSE.addQuantityToField(it.Receipt_Line__r.Purchase_Order_Line__r.Material_Tracking__r.Quantity_Allocated__c,0);
                    } else if (it.Receipt_Line__r.Purchase_Order_Line__r.Type__c == 'Back To Back' && shlMap.containsKey(it.Receipt_Line__r.Purchase_Order_Line__c)) {
                        Shipment_Line__c shl = shlMap.get(it.Receipt_Line__r.Purchase_Order_Line__c);
                        Decimal sellingConvFactor = KSE.getConversionFactorFromQuantity(shl.Sales_Order_Line__r.Quantity_From_Stock__c,shl.Sales_Order_Line__r.Quantity_Ordered__c);
                        headerId = shl.Shipment__c;
                        lineId = shl.Id;
                        qtyToUnallocate = KSE.addQuantityToField(shl.Quantity_Allocated__c * sellingConvFactor,0);
                    }

                    if (qtyToUnallocate > 0) {
                    	//Convert to stocking uom
                        Decimal cf= 1;
                        cf = KSE.getConversionFactor(it.item__c,it.To_Facility__r.Facility_Identifier__c, it.Packaging_UOM__c,it.Stocking_UOM__c, itemPackagingUOMCache.get(it.Item__c));
                        SKID__c skidToUnallocate = new SKID__c(
                            Company__c = it.Company__c,
                            Type__c = SkidService3.SKID_TYPE_LOCATION,
                            Quantity__c = it.Quantity__c*cf,
                            Input_Quantity__c = Math.min(it.Quantity__c*cf,qtyToUnallocate),
                            Item__r = it.Item__r
                        );
                        SkidService3.copyItAttributesToSkid(skidToUnallocate,it,null);

                        if (!skidsToUnallocate.containsKey(headerId)) skidsToUnallocate.put(headerId,new Map<Id,List<SkidService3.SerialWrapper>>());
                        if (!skidsToUnallocate.get(headerId).containsKey(lineId)) skidsToUnallocate.get(headerId).put(lineId,new List<SkidService3.SerialWrapper>());
                        skidsToUnallocate.get(headerId).get(lineId).add(new SkidService3.SerialWrapper(skidToUnallocate,serialList));
                    }
                }
                
                Id companyId = it.Receipt_Line__r.Company__c;
                Id sourceDocId = it.Receipt_Line__r.Receiving_Document__c;
                
                SkidService3.ParameterData d = data.get(sourceDocId);
                
                if (d == null) {
                    d = new SkidService3.ParameterData();
                    d.sourceDoc = new Receiving_Document__c(Company__c = companyId);
                    data.put(sourceDocId,d);
                }
                
                if(voidIt.Type__c == 'Void - Logical Purchase Order Receipt'){
                    voidIt.Purchase_Order_Line__c = it.Purchase_Order_Line__c;
                }
                d.itList.add(voidIt);
                itsToUpdate.add( new Inventory_Transaction__c(Id = it.id, Reversed__c = true));
            }
            
            decimal quantityReceived=0; 
            
            if (receivingDocs[0].Type__c != 'Purchase Order Return' && receivingDocs[0].Type__c != 'Logical Purchase Order Return') {
                for( sObject ol : mOrderLines.values() ) {
                    quantityReceived = 0;
                    
                    string sObjectApIName = '';
                    sObjectAPIName = ol.getSObjectType().getDescribe().getLocalName();
                    
                    SKID__c supplySkid;
                   	
                    if(sObjectAPIName.toLowerCase() =='purchase_order_line__c'.toLowerCase()){

                        Purchase_Order_Line__c pol = (Purchase_Order_Line__c) ol;
                        
                        if(pol.Sales_Order_Line__r.Fulfillment_Source__c != 'Drop Ship'){
                            supplySkid  = new SKID__c(  Location__c = (Id)ol.get('Delivery_Location__c'), Item__c = (Id)ol.get('Item__c'), Item__r = (Item__c)ol.getSObject('Item__r'),
                                    Quantity__c = 0,  Purchase_order_line__c = ol.id, Type__c = 'PO Supply', Company__c = (Id)ol.get('Company__c'),
                                    Stocking_UOM__c = pol.Item__r.Stocking_UOM__c, Packaging_UOM__c = pol.Item__r.Stocking_UOM__c,
                                    Facility2__c = pol.Delivery_Location__r.Facility__c
                                    );
                            if( quantityByOL.containsKey( ol.id )){
                             supplySkid.Quantity__c = quantityByOL.get(ol.id);
                            }
                            else if( (boolean)ol.getsobject('Item__r').get('Non_Inventory__c')){
                                supplySkid.Quantity__c = oIdToReceiptLineMap.get(ol.id);
                            }
                            SkidService3.SerialWrapper swSupply = new SkidService3.SerialWrapper( supplySkid, null, null);
                            supplySkidsPO.add(swSupply);
                        }
                    }
                    Decimal oldReceiptQty;
                    if(oIdToReceiptLineStockingMap !=null && oIdToReceiptLineStockingMap.containskey(ol.Id)){
                    	oldReceiptQty = oIdToReceiptLineStockingMap.get(ol.id);
                    }
                    else
                    	oldReceiptQty = oIdToReceiptLineMap.get(ol.id);
                    	
                    quantityReceived = (decimal)ol.get('Quantity_Received__c') - oldReceiptQty;
                    
                    ol.put('Quantity_Received__c', quantityReceived) ;
                }
            }

            if (skidsToUnallocate.size() > 0) {
                try {
                    AllocationService.autoUnallocate(skidsToUnallocate);
                } catch (Exception e) {
                    throw new ReceivingDocumentServiceV2Exception('Unable to auto-unallocate: ' + e.getMessage());
                }
            }
            
            if(inTransitSkids.size()>0)
            {
                SkidService3.putAwayService( inTransitSkids, attributesForTOSkids, null);
                orderService.ClearExceptions(mOrderLines.values());
            }
            
            if(supplySkidsPO.size()>0)
            {    
                SkidService3.putAwayService( supplySkidsPO, attributesForSupply, null);
            }
            //Deducting the inventory from location skid..
            map<List<String>, SkidService3.SerialWrapper > locationSkidMap;
            if(skidWrapperList.size()>0){
            	locationSkidMap = SkidService3.putAwayService( skidWrapperList, attributesForNegativeSkids, new map<String,Boolean>{SkidService3.CREATE_SERIAL=>false});
            }
          
            map< list<String>, SkidService3.SerialWrapper> inTransitWrappers;
            if(inTransitPOSkids.size()>0)
            {
                inTransitWrappers =SkidService3.putAwayService( inTransitPOSkids, attributesforRDVoid, null);
            }
            
            map<Id,SKID__c> SkidsByIdMap = new map<Id,SKID__c>();
            
            if(locationSkidMap !=null && locationSkidMap.values().size()>0){
            	
            	for(SkidService3.SerialWrapper sw : locationSkidMap.values()){
	            	SkidsByIdMap.put(sw.skid.Id, sw.skid);
	            }
	            
	            for (Id sourceDocId:data.keySet()) {
            	
	            for( Inventory_Transaction__c it : data.get(sourceDocId).itList ){
			            if(it.From_SKID__c != null && SkidsByIdMap.containsKey(it.From_SKID__c) ){        
			                                        
		                        it.From_Skid__r = SkidsByIdMap.get(it.From_SKID__c);      	              
			        	}
			        	
			        	Inventory_Transaction__c itrans = it.clone(false, true);
			        
			        	if(it.Receipt_Line__r != null && it.Receipt_Line__r.ASN_Line__c !=null){
			        		itrans.ASN_Line__c = it.Receipt_Line__r.ASN_Line__c;
                    		itrans.Receipt_Line__c = null;
			        	}
			        	
                    	
                    	List<String> itkey = SkidService3.generateKey(itrans,attributesforRDVoid);
			        	//Match IT and skid key and populate toskid info on void it...
			        	if(inTransitWrappers !=null && inTransitWrappers.containskey(itkey)){
			        		it.To_Skid__r = inTransitWrappers.get(itkey).skid;
			        		it.To_Skid__c = inTransitWrappers.get(itkey).skid.Id;
			        	}        	
		            } 
	            }
            }
            
            Map<List<String>,SkidService3.SerialWrapper> toSkids = SkidService3.putAwayService(voidSerialWrappers,null,putawayConfigMap);
            
            for (List<String> itKey:keyMap.keySet()) {
            	List<String> skidKey = keyMap.get(itKey);
            	if (toSkids.containsKey(skidKey)) toSkids.put(itKey,toSkids.get(skidKey));
            }
            
            SkidService3.inventoryTransactionsForPutAway(data,null,toSkids,configMap);
            
            
            DML.updateAsUser(updateReceivingDocuments);
            DML.updateAsUser(updateReceiptLines);
            DML.updateAsUser(updateASNLines);
            DML.updateAsUser(mOrders.values());
            DML.updateAsUser(mOrderLines.values());
            DML.updateAsUser(itsToUpdate);

            if(inTransitSkids.size()>0 && TransferOrderflag == true)
            {
                Map<id,Skid__c> zeroSkids = new Map<id,Skid__c>([select id from Skid__c WHERE order_line__c in :mOrderLines.keyset() and Quantity__c=0]);
                if(zeroSkids.size()>0)
                    DML.deleteAsSystem(zeroSkids.values());
            }
            else{
                //PTM-645
                Map<id,Skid__c> deleteinTransitSkids = new Map<id,Skid__c>([select id from Skid__c WHERE Receipt_Line__c in :receiptLineIds and type__c =: SkidService2.SKID_TYPE_INTRANSIT]);
                if(deleteinTransitSkids.size()>0)
                    DML.deleteAsSystem(deleteinTransitSkids.values());
            }

        }
        catch(exception e)
        {   system.debug(LoggingLevel.ERROR, e.getStackTraceString());
            Database.rollback(sp);
            throw e;
        }
        
    }
    
    public static map<Id, List<Inventory_Transaction__c>> getInventoryTransactionsForRTV(set<Id> receiptlinesIds, Boolean logical){
        
        map<Id, List<Inventory_Transaction__c>> inventoryTransactionsMap = new map<Id, List<Inventory_Transaction__c>>();
        
        // Build Serial Transaction subquery string 
        Set<String> serialFieldStrings = new set<String>();
        serialFieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject( 'Serial__r.', 'Serial__c'));
        serialFieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.','Item_Attribute__c') );
        serialFieldStrings.addAll(new Set<String>{' Name', 'Serial__r.Unique_Key2__c','Serial__c', 'Serial__r.Id', 'Serial__r.Name', 'Serial__r.Skid__c', 'Serial__r.Skid__r.Name'});
        
          
        set<String> itFields = new set<String>{ 'Id', 'Name','Item__c', 'Receipt_Line__r.Receiving_Document__c', 'Type__c','Item__r.Stocking_UOM__c','From_Location__c','From_Skid__c','From_Skid__r.Lot__c',
                                'To_Location__c','Company__c','To_Location__r.Facility__c',
                                'Quantity__c', 'To_Skid__r.Location__r.Facility__c','To_Skid__r.Company__c',
                                'To_Skid__c','To_Skid__r.Id','To_Skid__r.Type__c','To_Skid__r.Lot__c','To_Skid__r.Expiration_Date__c','To_Skid__r.Item__c',
                                'To_Skid__r.Quantity__c','To_Skid__r.Sales_Order_line__c','To_Skid__r.Location__c',
                                'Sales_Order_Line__c', 'Sales_Order_Line__r.Related_Sales_Order_Line__c','Sales_Order_Line__r.Related_Sales_Order_Line__r.Name'};
            
        itFields.addAll(util.getAllCustomFieldsFromObject(null, 'Inventory_Transaction__c'));
        itFields.addAll(util.getAllCustomFieldsFromObject('To_Skid__r.', 'Skid__c'));
        
        String typeClause = 'Type__c = \'RMA Receipt\'';
        if( logical ) typeClause = ' (Type__c = \'Logical RMA Receipt\') ';
        
        SOQLUtil soql = new SOQLUtil('Inventory_Transaction__c');
        
        soql.addFields(itFields);
        soql.setWhereClause(typeClause+' and Finalized__c = true and Receipt_Line__c IN :receiptlinesIds');
        
        SOQLUtil.ChildRelationship serials = new SOQLUtil.ChildRelationship(soql, 'Serial_Transactions__r');
        serials.addFields(serialFieldStrings);
        soql.addChildRelationship(serials);
        
        for( Inventory_Transaction__c it : (List<Inventory_Transaction__c>) Database.query(soql.getQuery())){
            
            if(!inventoryTransactionsMap.containsKey(it.Sales_Order_Line__r.Related_Sales_Order_Line__c)){
                inventoryTransactionsMap.put(it.Sales_Order_Line__r.Related_Sales_Order_Line__c, new List<Inventory_Transaction__c>());
            }
            inventoryTransactionsMap.get(it.Sales_Order_Line__r.Related_Sales_Order_Line__c).add(it);
        }                            
        
        return inventoryTransactionsMap;                            
    }
    
    
    
    public static List<LineWrapper> getRTVData(Set<Id> rdIds) {
        SOQLUtil receiptLineQuery = new SOQLUtil('Receipt_Line__c');
        receiptLineQuery.addAllCustomFields();
        receiptLineQuery.addAllCustomFields(Purchase_Order_Line__c.sObjectType,'Purchase_Order_Line__r');
        receiptLineQuery.addAllCustomFields(Sales_Order_Line__c.sObjectType,'Sales_Order_Line__r');
        receiptLineQuery.addAllCustomFields(Sales_Order_Line__c.sObjectType,'Sales_Order_Line__r.Related_Sales_Order_Line__r');
        receiptLineQuery.addAllCustomFields(Item__c.sObjectType,'Item__r');
        receiptLineQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item__r.Item_Attribute__r');
        receiptLineQuery.addField('Company__r.Serial_Control__c');
        receiptLineQuery.addField('Related_Receipt_Line__r.Receiving_Document__r.Transaction_Date__c');
        receiptLineQuery.addField('Sales_Order_Line__r.Related_Sales_Order_Line__c');
        receiptLineQuery.addField('Purchase_Order_Line__r.Sales_Order_Line__c');
        receiptLineQuery.addField('Purchase_Order__r.Currency__c');
        receiptLineQuery.addField('Purchase_Order_Line__r.Item__r.Stocking_UOM__c');
        receiptLineQuery.addField('Purchase_Order_Line__r.Item__r.Packaging_UOM__c');
        receiptLineQuery.addField('Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c');
        receiptLineQuery.addField('Facility__r.Facility_Identifier__c');
        receiptLineQuery.setWhereClause('Receiving_Document__c IN :rdIds AND Item__r.Non_Inventory__c = false');
        List<Receipt_Line__c> receiptLines = (List<Receipt_Line__c>)Database.query(receiptLineQuery.getQuery());
        
        if (receiptLines.size() == 0) {
            throw new ReceivingDocumentServiceV2Exception(Label.You_do_not_have_any_lines_to_return);
        }
        Map<Id,Id> receiptSOLmap = new Map<Id,Id>();
        Map<Id,Purchase_Order_Line__c> receiptPOLmap = new Map<Id,Purchase_Order_Line__c>();
        List<Purchase_Order_Line__c> polinelist = new List<Purchase_Order_Line__c>();
        
        for(Receipt_Line__c rcl:receiptLines){
            if(rcl.Sales_Order_Line__r != null && rcl.Sales_Order_Line__r.Related_Sales_Order_Line__r != null)
                receiptSOLmap.put(rcl.Sales_Order_Line__r.Related_Sales_Order_Line__c,rcl.Id);
        }
        if(receiptSOLmap.size()>0){
        
            polinelist = (List<Purchase_Order_Line__c>) ReturnToVendorService.queryPOlines(receiptSOLmap.keyset(), new Set<Id>(), new Set<String>{'Sales_Order_Line__c'.toLowerCase()}, false);
        }
        
        for(Purchase_Order_Line__c poline:polinelist){
            if(receiptSOLmap.containskey(poline.Sales_Order_Line__c)){
                receiptPOLmap.put(receiptSOLmap.get(poline.Sales_Order_Line__c), poline);
            }
        }
        
        
        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        set<id> UOMId = new set<id>();
        Set<Id> pkgUOMSetIds = new Set<Id>();
        map<Id,id> receiptLineToUOM = new map<Id,id>();
        map<Id,decimal> receiptLineToConvFactor = new map<Id,decimal>();
        for (Receipt_Line__c rl:receiptLines) {
            itemIds.add(rl.Item__c);
            facilityIds.add(rl.Facility__c);
            
            Decimal convFactor = 1;
            Purchase_Order_Line__c polrec;
            if(receiptPOLmap.containskey(rl.Id)){
                polrec = receiptPOLmap.get(rl.Id);
            }
            else{
                polrec = rl.Purchase_Order_Line__r; 
            }
            convFactor = KSE.getConversionFactor(polrec);
            pkgUOMSetIds = (set<Id>)JSON.deserialize(String.valueOf(rl.getSObject('Item__r').get('Packaging_UOM__c')), set<Id>.Class);  
            
            if(!pkgUOMSetIds.contains(rl.Purchase_Order_Line__r.purchase_uom__c)){
               if(rl.Purchase_Order_Line__r.Item__r.Stocking_UOM__c != null)
                    UOMId.add(rl.Purchase_Order_Line__r.Item__r.Stocking_UOM__c);  
                    if(!receiptLineToUOM.containsKey(rl.Id)){
                        receiptLineToUOM.put(rl.Id,rl.Purchase_Order_Line__r.Item__r.Stocking_UOM__c);
                    }
                    if(!receiptLineToConvFactor.containsKey(rl.Id)){
                      receiptLineToConvFactor.put(rl.Id,convFactor);
                    }
            } else {
                if(rl.Purchase_Order_Line__r.purchase_uom__c != null)     
                    UOMId.add(rl.Purchase_Order_Line__r.purchase_uom__c);    
                    if(!receiptLineToUOM.containsKey(rl.ID)){
                        receiptLineToUOM.put(rl.Id,rl.Purchase_Order_Line__r.purchase_uom__c);
            		}
            }

            //rl.Quantity_Actually_Returned__c = rl.Quantity_Actually_Returned__c / convFactor;
        }

        Map<String,Set<Id>> filters = new Map<String,Set<Id>>{ 'Item__c' => itemIds,'Location__r.Facility__c' => facilityIds ,'Packaging_UOM__c' => UOMId};
        
        Map<List<String>,List<SKID__c>> skids = SkidService3.pullSkidsQuery(null,filters,null,SkidService3.SKID_TYPE_LOCATION,null,null);
        Map<List<String>,List<SKID__c>> skidsByItemFacility = new Map<List<String>,List<SKID__c>>();
        Set<Id> skidIds = new Set<Id> ();
        Id companyId;
        Map<Id, Item__c> items = new Map<Id, Item__c>();
        for (List<SKID__c> skidList:skids.values()) {
            for (SKID__c skid:skidList) {
            	skidIds.add( skid.id);
                List<String> skidKey = new List<String>{ skid.Item__c, skid.Location__r.Facility__c,skid.Packaging_UOM__c };
                if (!skidsByItemFacility.containsKey(skidKey)) {
                    skidsByItemFacility.put(skidKey,new List<SKID__c>());
                }
                skidsByItemFacility.get(skidKey).add(skid);
                items.put(skid.Item__c, skid.Item__r);
                companyId = skid.Company__c;
            }
        }
        //added following query and maps to take care of Quantity Available on skids.which takes care of allocated qty .
        Map<Id, List<String>> allocAttributes = AllocationService.getSkidAttributes(companyId, items);
        List<String> planAttributes = SkidService3.attributesForPutaway(null, new Set<String>{ 'license_plate_number__c' });
        Map<List<String>, List<SKID__c>> allSkids = new Map<List<String>, List<SKID__c>>();
        Map<List<String>, Decimal> allocatedQtys = new Map<List<String>, Decimal>();
        set<String> attributesForUniqueKey = new set<String>(SkidService3.attributesForUniqueKey);
        
        Set<String> skidTypes = new Set<String>{ SkidService3.SKID_TYPE_ALLOCATED, SkidService3.SKID_TYPE_PLANNED,SkidService3.SKID_TYPE_LOCATION  };
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Lot_Number__c', 'Type__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c',
            'Stocking_UOM__c', 'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c',
            'Packaging_UOM__r.Package_Class__c', 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c','License_Plate_Number__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
            'Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c', 'Packaging_UOM__r.Package_Class__r.Level__c', 'Item__r.Packaging_UOM__c',
            'Facility2__r.Facility_Identifier__c'
        });
        skidQuery.addFields(attributesForUniqueKey);
        string whereClause = ' Type__c IN : skidTypes  AND Item__c IN : itemIds AND Facility2__c IN : facilityIds';
        skidQuery.setWhereClause(whereClause);  
        
        
        for (SKID__c skid:Database.query(skidQuery.getQuery())) {
            skid.shipment_line__c = null;
            skid.Material_Tracking__c = null;
            List<String> allocKey = SkidService3.generateKey(skid, allocAttributes.get(skid.Item__c));
            List<String> planKey = SkidService3.generateKey(skid, planAttributes);
            
            if (skid.Type__c == SkidService3.SKID_TYPE_LOCATION) {

                if (!allSkids.containsKey(allocKey)) allSkids.put(allocKey, new List<SKID__c>{ skid });
                else allSkids.get(allocKey).add(skid);

                if (!allSkids.containsKey(planKey)) allSkids.put(planKey, new List<SKID__c>{ skid });
                else allSkids.get(planKey).add(skid);

            } else if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                allocatedQtys.put(allocKey, KSE.addQuantityToField(allocatedQtys.get(allocKey), skid.Quantity__c));
                
            } else if (skid.Type__c == SkidService3.SKID_TYPE_PLANNED) {
                allocatedQtys.put(planKey, KSE.addQuantityToField(allocatedQtys.get(planKey), skid.Quantity_Stocking_UOM__c));
            }
        }
        
        
        SOQLUtil serialQuery = new SOQLUtil('Serial__c');
        serialQuery.addAllCustomFields();
        serialQuery.setWhereClause('Skid__c IN :skidIds ');
        
        Map<Id,List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
        for (Serial__c serial:Database.query(serialQuery.getQuery())) {
        	if (!serialMap.containsKey(serial.SKID__c)) {
        		serialMap.put(serial.SKID__c,new List<Serial__c>());
        	}
        	serialMap.get(serial.SKID__c).add(serial);
        }
        
        List<LineWrapper> rlWrappers = new List<LineWrapper>();
        for (Receipt_Line__c rl:receiptLines) {
            List<SkidService3.SerialWrapper> serialWrapperList = new List<SkidService3.SerialWrapper>();
            List<String> skidKey = new List<String>{ rl.Item__c, rl.Facility__c,receiptLineToUOM.get(rl.Id)};
            if (skidsByItemFacility.containsKey(skidKey)) {
                for (SKID__c skid:skidsByItemFacility.get(skidKey)) {
                    
                    Set<Id> skidsProcessed = new Set<Id>();
                    List<String> allocKey = SkidService3.generateKey(skid, allocAttributes.get(skid.Item__c));
                    List<String> planKey = SkidService3.generateKey(skid, planAttributes);
                    
                    skid.Total_Material__c = 0;
                    
                    if(allSkids.containskey(allocKey)){
                       for (SKID__c sk:allSkids.get(allocKey)) {
                            skid.Total_Material__c += sk.Quantity_Stocking_UOM__c;
                            skidsProcessed.add(sk.Id);
                        } 
                    }
                    
                    if(allSkids.containskey(planKey)){
                        for (SKID__c sk:allSkids.get(planKey)) {
                            if (!skidsProcessed.contains(sk.Id)) skid.Total_Material__c += sk.Quantity_Stocking_UOM__c;
                        }
                    }
                   
                    if (allocatedQtys.containsKey(allocKey)) skid.Total_Material__c -= allocatedQtys.get(allocKey);
                    if (allocatedQtys.containsKey(planKey)) skid.Total_Material__c -= allocatedQtys.get(planKey);
                    
                    List<Id> lstPkgUom = (List<Id>) JSON.deserialize( skid.Item__r.Packaging_UOM__c, List<Id>.class );
                    Decimal conversionFactor = KSE.getConversionFactor(skid.Item__c, skid.Facility2__r.Facility_Identifier__c, skid.Packaging_UOM__c, skid.Stocking_UOM__c, lstPkgUom);
                    skid.Quantity_Available__c = Math.min(skid.Total_Material__c, skid.Quantity_Stocking_UOM__c)/conversionFactor;
                    
                    serialWrapperList.add(new SkidService3.SerialWrapper(skid, serialMap.containsKey (skid.id) ? serialMap.get(skid.id) : new List<Serial__c>() ));
                }
            }
            decimal convFactor = 1;
            if(receiptLineToConvFactor.get(rl.Id) != null){
                convFactor = receiptLineToConvFactor.get(rl.Id);
            }
            LineWrapper rw = new LineWrapper(rl,serialWrapperList);
            rw.convFactor = convFactor;
            rlWrappers.add(rw);
        }
        
        return rlWrappers;
    }
    
    public static void checkRTVErrors(List<LineWrapper> rlWrappers) {
        Map<String,Serial__c> userSpecifiedSerials = new Map<String,Serial__c>();
        Map<Id,Decimal> skMap = new Map<Id,Decimal>();
        
        List<Item__c> items = new List<Item__c>();
        List<Receipt_Line__c> receiptLines = new List<Receipt_Line__c>();
        List<SKID__c> skids = new List<SKID__c>();
        Id companyId;
        Map<Id, Item__c> itemsMap = new Map<Id, Item__c>();
        
        for (LineWrapper rlWrapper:rlWrappers) {
            Receipt_Line__c rline = (Receipt_Line__c)rlWrapper.line;
            companyId = rline.Company__c;
            for (SkidService3.SerialWrapper sw:rlWrapper.serialWRappers) {
                if (sw.skid.Quantity_To_Return__c > 0) {
                    //items.add((Item__c)rlWrapper.line.getSObject('Item__r'));
                    receiptLines.add((Receipt_Line__c)rlWrapper.line);
                    skids.add(sw.skid);
                    itemsMap.put(sw.skid.Item__c, sw.skid.Item__r);
                }
            }
        }
        
        Map<Id, List<String>> allocAttributes = AllocationService.getSkidAttributes(companyId, itemsMap);
        List<String> planAttributes = SkidService3.attributesForPutaway(null, new Set<String>{ 'license_plate_number__c' });
        Map<List<String>, List<SKID__c>> qtyTaken = new Map<List<String>, List<SKID__c>>();
        
        Set<Id> serialTracked = SkidService3.getSerialTrackedItems(receiptLines, false); 
        Map<Id,Receipt_Line__c> updatedRls = new Map<Id,Receipt_Line__c>([SELECT Id,Quantity_Actually_Returned__c,Quantity_Returned_to_Supplier_for_Credit__c,Quantity_returned_to_supplier__c FROM Receipt_Line__c WHERE Id IN :receiptLines]);
        Map<List<String>,SKID__c> existingSkids = SkidService3.generateExistingSkidMap(null,skids,true,null);
        id  UOMId ;
        Map<Id, List<Id>> itemPackagingUOMCache = new Map<Id, List<Id>> ();
        for (LineWrapper rlWrapper:rlWrappers) {
            Receipt_Line__c rl = (Receipt_Line__c)rlWrapper.line;
            
            if (!updatedRls.containsKey(rl.Id)) {
                throw new ReceivingDocumentServiceV2Exception(rl.Name + ' could not be found');
            }
            
            rl.Quantity_Returned_to_Supplier_for_Credit__c = updatedRls.get(rl.Id).Quantity_Returned_to_Supplier_for_Credit__c;
            rl.Quantity_Actually_Returned__c = updatedRls.get(rl.Id).Quantity_Actually_Returned__c;
            
            Decimal qtyReturning = 0;
            Decimal qtyToReturn = KSE.subtractDecimals(KSE.addQuantityToField(rl.Quantity_Returned_to_Supplier_for_Credit__c,rl.Quantity_returned_to_supplier__c),rl.Quantity_Actually_Returned__c);
            
            if ( !itemPackagingUOMCache.containsKey (rl.Item__c ) ) {
                List<Id> lstPkgUom = (List<Id>) JSON.deserialize(rl.Item__r.Packaging_UOM__c, List<Id>.class);
                itemPackagingUOMCache.put(rl.Item__c, lstPkgUom );
            }
            
            Set<Id> pkgUOMSetIds = new Set<Id> ( itemPackagingUOMCache.get(rl.Item__c) ); 
                        
            if(!pkgUOMSetIds.contains(rl.Purchase_Order_Line__r.purchase_uom__c)){
                if(rl.Purchase_Order_Line__r.Item__r.Stocking_UOM__c != null)
                     UOMId = rl.Purchase_Order_Line__r.Item__r.Stocking_UOM__c; 
             } else {
                 if(rl.Purchase_Order_Line__r.purchase_uom__c != null)     
                     UOMId = rl.Purchase_Order_Line__r.purchase_uom__c; 
             }
             
            decimal conFac = KSE.getConversionFactor(rl.item__c, rl.Facility__r.Facility_Identifier__c,rl.purchase_order_line__r.Purchase_UOM__c,UOMId, itemPackagingUOMCache.get(rl.Item__c));
            if(conFac == null){
            	conFac = 1;
            }  
            qtyToReturn = qtyToReturn * conFac;
            for (SkidService3.SerialWrapper sw:rlWrapper.serialWrappers) {
                if (sw.skid.Quantity_To_Return__c < 0) {
                    throw new ReceivingDocumentServiceV2Exception(rl.Name + ': Quantity to return cannot be negative');
                } else if (sw.skid.Quantity_To_Return__c > 0) {
                    
                    List<Id> lstPkgUom = (List<Id>) JSON.deserialize( sw.skid.Item__r.Packaging_UOM__c, List<Id>.class );
                    Decimal convFactor = KSE.getConversionFactor(sw.skid.Item__c, sw.skid.Facility2__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, sw.skid.Stocking_UOM__c, lstPkgUom);
                    List<String> allocKey = SkidService3.generateKey(sw.skid, allocAttributes.get(sw.skid.Item__c));
                    List<String> planKey = SkidService3.generateKey(sw.skid, planAttributes);
                    
                    Set<Id> skidsProcessed = new Set<Id>();
                    if (qtyTaken.containsKey(allocKey)) {
                        for (SKID__c sk:qtyTaken.get(allocKey)) {
                            
                            sw.skid.Total_Material__c -= sk.Quantity__c;
                            skidsProcessed.add(sk.Id);
                        }
                    }
                    
                    if (qtyTaken.containsKey(planKey)) {
                        for (SKID__c sk:qtyTaken.get(planKey)) {
                            if (!skidsProcessed.contains(sk.Id)) sw.skid.Total_Material__c -= sk.Quantity__c;
            }  
                    }
                    
                    sw.skid.Quantity_Available__c = sw.skid.Quantity_Available__c * convFactor;
                    sw.skid.Quantity_Available__c = Math.min(sw.skid.Total_Material__c, sw.skid.Quantity_Available__c);
                        
                    qtyReturning += sw.skid.Quantity_To_Return__c;
                    
                    if ((sw.skid.Quantity_To_Return__c  * convFactor)  > sw.skid.Quantity_Available__c) {
                        throw new ReceivingDocumentServiceV2Exception(rl.Name + ': Cannot return more quantity (' + sw.skid.Quantity_To_Return__c + ') than available (' + sw.skid.Quantity_Available__c + ')');
                    }
                    //for serial conversion we are getting conversion from serial wrapper.eg 1 case = 2 EA then Qty will be 1 but serial will be 2.
                    Decimal cf = 1;
                    if(sw.conversionFactor != null){
                        cf = sw.conversionFactor;
                    }
                    if (serialTracked.contains(rl.Item__c)) {
                        if (sw.serialList.size() != sw.skid.Quantity_To_Return__c * cf) {
                            throw new ReceivingDocumentServiceV2Exception(rl.Name + ': ' + Label.Number_Of_Serials_Not_Matching_Quantity + ' Number Of Serials: ' + sw.serialList.size() + ' Specified Quantity: ' + sw.skid.Quantity_To_Return__c);
                        }
                        
                        for (Serial__c ser:sw.serialList) {
                            String uniqueKey = rl.Company__c + '-' + rl.Item__c + '-' + ser.Name;
                            if (!userSpecifiedSerials.containsKey(uniqueKey)) {
                                userSpecifiedSerials.put(uniqueKey,ser);
                            } else {
                                throw new ReceivingDocumentServiceV2Exception(ser.Name + ': ' + Label.Serial_Number_Specified_More_than_Once);
                            }
                        }
                    }
                    SKID__c sk = new SKID__c(Id = sw.skid.Id, Quantity__c = sw.skid.Quantity_To_Return__c  * convFactor);
                    
                    if (!qtyTaken.containsKey(allocKey)) qtyTaken.put(allocKey, new List<SKID__c>());
                    qtyTaken.get(allocKey).add(sk);

                    if (!qtyTaken.containsKey(planKey)) qtyTaken.put(planKey, new List<SKID__c>());
                    qtyTaken.get(planKey).add(sk);
                }
            }
            
            if (qtyReturning.setScale(6)>qtyToReturn.setScale(6)) {
                throw new ReceivingDocumentServiceV2Exception(rl.Name + ': Cannot return more quantity (' + qtyReturning + ') than quantity to return (' + qtyToReturn + ')');
            }
        }
    }
    
    public static void returnToVendor(List<LineWrapper> rlWrappers) {
        List<SkidService3.SerialWrapper> serialWrappersForPutaway = new List<SkidService3.SerialWrapper>();
        List<SkidService3.SerialWrapper> negativeskidsForPutaway = new List<SkidService3.SerialWrapper>();
        Map<Id,Receipt_Line__c> receiptLinesToUpdate = new Map<Id,Receipt_Line__c>();
        Map<Id,SkidService3.ParameterData> itData = new Map<Id,SkidService3.ParameterData>();
        Map<List<String>,SkidService3.SerialWrapper> toSkids = new Map<List<String>,SkidService3.SerialWrapper>();
        Map<String,String> configMap =  new Map<String,String>{ 'adjustFromSkidQuantity'=>'none'};

        List<String> attributes = SkidService3.attributesForPutaway(null,new Set<String>{'shipment_line__c'});
        attributes.add('Receipt_Line__c');
        
        //List<Item__c> items = new List<Item__c>();
        List<SObject> receiptLines = new List<SObject>();
        
        for (LineWrapper rlWrapper:rlWrappers) {
            //items.add((Item__c)rlWrapper.line.getSObject('Item__r'));
            receiptLines.add(rlWrapper.line);
        }
        
        Set<Id> serialTracked = SkidService3.getSerialTrackedItems(receiptLines,false);
        
        Map<Id, List<Id>> itemPackagingUOMCache = new Map<Id, List<Id>>();
        for (LineWrapper rlWrapper:rlWrappers) {
            Receipt_Line__c rl = (Receipt_Line__c)rlWrapper.line;
            if ( !itemPackagingUOMCache.containsKey(rl.Item__c)){
                List<Id> lstPkgUom = (List<Id>) JSON.deserialize(rl.Item__r.Packaging_UOM__c, List<Id>.class);
                itemPackagingUOMCache.put( rl.Item__c, lstPkgUom );
            }
            Decimal conversionFactor = KSE.getConversionFactor(rl.Item__c, rl.Facility__r.Facility_Identifier__c, rl.Purchase_Order_Line__r.Purchase_UOM__c, rl.Item__r.Stocking_UOM__c, itemPackagingUOMCache.get(rl.Item__c) );
            for (SkidService3.SerialWrapper sw:rlWrapper.serialWrappers) {
                if (!(sw.skid.Quantity_To_Return__c > 0))
                    continue;
				
				SKID__c negativeSkid;
                negativeSkid = sw.skid.clone(true,true);
                negativeSkid.Quantity__c = -sw.skid.Quantity_To_Return__c;
                negativeskidsForPutaway.add(new SkidService3.SerialWrapper(negativeSkid,sw.serialList));
                String itType;
                if(rlWrapper.logical == true)
                    itType = 'Logical Purchase Order Return';
                else
                    itType = 'Purchase Order Return';
                        
                //Inventory_Transaction__c it = SkidService3.createIT(sw.skid,itType,'Receipt_Line__c',rl.Id,null,null,sw.skid.Quantity_To_Return__c);
                Inventory_Transaction__c it = SkidService3.createInventoryTransaction(rl, itType, sw.skid.Quantity_To_Return__c, sw.skid, sw.skid, null);
                if(itType == 'Logical Purchase Order Return' && rl.Related_Receipt_Line__c != null){
                  it.Transaction_Date__c = rl.Related_Receipt_Line__r.Receiving_Document__r.Transaction_Date__c ; 
                }
                it.to_skid__c = null;
                it.to_facility__c = null;
                it.to_location__c = null;
                it.Bin__c = null;
                it.Item__c = rl.Item__c;
                it.Item__r = rl.Item__r;
                it.Purchase_Order_Line__c = rl.Purchase_Order_Line__c;
                Id currencyId;
                
                if(rl.Purchase_Order__r != null)
                	currencyId = rl.Purchase_Order__r.Currency__c;
                
                if (!itData.containsKey(rl.Receiving_Document__c)) {
                    SkidService3.ParameterData itInfo = new SkidService3.ParameterData();
                    itInfo.sourceDoc = new Receiving_Document__c(Company__c = rl.Company__c);
                    if(currencyId !=null){
                    	itInfo.sourceDoc.put('Currency__c', currencyId); //KNDY-14655
                    }
                    itData.put(rl.Receiving_Document__c,itInfo);
                }
                itData.get(rl.Receiving_Document__c).itList.add(it);
                
                toSkids.put(SkidService3.generateKey(it,attributes),new SkidService3.SerialWrapper(it,sw.serialList));
                Decimal cf = KSE.getConversionFactor(rl.Item__c, rl.Facility__r.Facility_Identifier__c, rl.Purchase_Order_Line__r.Purchase_UOM__c, it.Packaging_UOM__c, itemPackagingUOMCache.get(rl.Item__c) );
                if (!receiptLinesToUpdate.containsKey(rl.Id)) {
                    Receipt_Line__c updatedRL = new Receipt_Line__c(Id = rl.Id);
                    updatedRL.Quantity_Actually_Returned__c = KSE.addQuantityToField(rl.Quantity_Actually_Returned__c,it.Quantity__c / cf );
                    updatedRL.Quantity_To_Stock__c = updatedRL.Quantity_Actually_Returned__c  * conversionFactor ;
                    receiptLinesToUpdate.put(rl.Id,updatedRL);
                } else {
                    Receipt_Line__c updatedRL = receiptLinesToUpdate.get(rl.Id);
                    updatedRL.Quantity_Actually_Returned__c += (it.Quantity__c / cf );
                    updatedRL.Quantity_To_Stock__c = updatedRL.Quantity_Actually_Returned__c  * conversionFactor ; 
                }
                
                if (serialTracked.contains(rl.Item__c)) {
                    serialWrappersForPutaway.add(new SkidService3.SerialWrapper(it,sw.serialList));
                }
            }
        }
        map<List<String>, SkidService3.SerialWrapper > locationSkidMap;
        if(negativeskidsForPutaway.size()>0){
        	locationSkidMap = SkidService3.putAwayService(negativeskidsForPutaway,attributes,new Map<String,Boolean>{SkidService3.UNDO_SERIAL => true});
        }
        
        map<Id,SKID__c> SkidsByIdMap = new map<Id,SKID__c>();
            
        for(SkidService3.SerialWrapper sw : locationSkidMap.values()){
        	SkidsByIdMap.put(sw.skid.Id, sw.skid);
        }
        
        for (Id sourceDocId:itData.keySet()) {
            	
            for( Inventory_Transaction__c it : itData.get(sourceDocId).itList ){
	            if(it.From_SKID__c != null && SkidsByIdMap.containsKey(it.From_SKID__c) ){        
	                                        
                        it.From_Skid__r = SkidsByIdMap.get(it.From_SKID__c);  	                    	              
	        	}	        	
            } 
        }
        
        SkidService3.inventoryTransactionsForPutaway(itData,attributes,toSkids,configMap);
        
        if (serialWrappersForPutaway.size() > 0) {
            SkidService3.putAwayService(serialWrappersForPutaway,attributes,new Map<String,Boolean>{SkidService3.UNDO_SERIAL => true});
        }
        
        DML.updateAsUser(receiptLinesToUpdate.values());
    }
}