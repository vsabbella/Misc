/**
 * PickAssignmentExt: Assign picker for the Shipment/Sales Order
 * Assignment can be done for all the Skids of type Planned Pick
 */

public with sharing class PickAssignmentExt extends BaseController{
    private static final String TRANSFER_ORDER_LABEL='Transfer Order';
    public String namespaceUU {get; set;} {namespaceUU = KSE.namespaceUU; }
    public String gridFieldsJson {get;set;}
    public String defaultFacility{ get; set; }
    public PickAssignmentExt ( ) {
        List<FieldInfo> gridFields = FieldInfo.fetchJsonFieldInfos('Skid__c', 'PickAssignment_Grid');
        list<String> addlFields = new list<String>();
        addlFields.add('Shipment_Line__r.Sales_Order_Line__r.Sales_Order__r.Parcel__c');  
        addlFields.add('Picker__c'); 
        gridFields.addAll(FieldInfo.fetchJsonFieldInfos('Skid__c', addlFields));

        for ( FieldInfo f : gridFields ){
            if ( !f.field.equalsIgnoreCase('Picker__c')) {
                f.editable =false;
            }
            if(f.field.equalsIgnoreCase('Shipment_Line__r.Order__c'))
            {
                f.title= TRANSFER_ORDER_LABEL;
            }
            f.required = false;
        }

        gridFieldsJson = JSON.serialize(gridFields);
        User_Preference__c up = UserPreference.getInstance().preference;

        if (up != null ) {
            if  (up.Default_Facility__c != null ) {
                defaultFacility = up.Default_Facility__c;
            }
        }
    }

    public String gridConfigJson {get {
        if ( gridConfigJson == null ) {
            GridRelatedListController.GridRelatedListConfig config = new GridRelatedListController.GridRelatedListConfig();
            config.objectName = 'Skid__c';
            config.fieldset = 'PickAssignment_Grid';
            config.buttons='';
            config.pageSize =10;
            gridConfigJson = JSON.serialize(config);
        }
        return gridConfigJson;
    } set;}

    // getter for grid
    @RemoteAction
    public static JsonResult getPickAssignmentData ( String filterStr ) {
        JsonResult result = new JsonResult();
        result.records = new List<Object> ();
        if ( String.isNotEmpty(filterStr)) {
            Map<String, String> filter = (Map<String,String>) JSON.deserialize(filterStr, Map<String, String>.class);

            List<String> filterCriteria = new List<String>();
            if(filter.containsKey('facility') && filter.get('facility') != null){
                filterCriteria.add( 'Shipment_Line__r.Facility__c =\'' + filter.get('facility') + '\'' );
            }
            if ( filter.containsKey('location') && filter.get('location') != null ) {
                filterCriteria.add( 'Location__c =\'' + filter.get('location') + '\'' );
            }
            if ( filter.containsKey('salesOrder') && filter.get('salesOrder') != null) {
                filterCriteria.add( 'Shipment_Line__r.Sales_Order__c =\'' + filter.get('salesOrder') + '\'');
            }
            if ( filter.containsKey('customer') && filter.get('customer') != null) {
                filterCriteria.add('Shipment_Line__r.Shipment__r.Customer__c =\'' + filter.get('customer') + '\'' );
            }
            if ( filter.containsKey('transferOrder') && filter.get('transferOrder') != null) {
                filterCriteria.add('Shipment_Line__r.Order__c =\'' + filter.get('transferOrder') + '\'' );
            }


            if ( !filterCriteria.isEmpty() ) {
                filterCriteria.addAll( new List<String> {
                        'Shipment_Line__r.Shipment__c != null',
                        'Type__c= \''+ SkidService3.SKID_TYPE_PLANNED +'\''
                });

                SOQLUtil util = new SOQLUtil('Skid__c', true);
                util.addFields(new Set<String>{
                        'id', 'name', 'Sales_Order_Line__r.Sales_Order__c', 'Shipment_Line__r.Shipment__c','Shipment_Line__r.Sales_Order_Line__r.Sales_Order__r.Parcel__c','Picker__c',  
                        'Location__c'
                });
                util.addFields('PickAssignment_Grid');

                util.setWhereClause(String.join( filterCriteria ,' AND '));
                Set<Id> shipmentId = new Set<Id>();
                List<Skid__c> skidRecords = new List<Skid__c>();
                //System.assert(false, util.getQuery());
                for (Skid__c skid : Database.query(util.getQuery() )) {
                    if ( !shipmentId.contains(skid.Shipment_Line__r.Shipment__c) ) {
                        shipmentId.add(skid.Shipment_Line__r.Shipment__c);
                        skidRecords.add(skid);
                    }
                }
                result.records = skidRecords;
            }
            result.success= true;
        } else {
            result.success = false;
        }
        return result;
    }

    // assinging picker for the plan pick
    @RemoteAction
    public static JsonResult saveAssignment ( String pickAssignmentString, Id location) {
        JsonResult result = new JsonResult();
        if ( String.isEmpty (pickAssignmentString)) {
            result.addMessage('No rows to save.',ApexPages.Severity.ERROR);
            result.success = false;
            return result;
        }

        try {
            Map<Id,Id> assignmentData = (Map<Id,Id>) JSON.deserialize(pickAssignmentString, Map<Id,Id>.class);

            Set<Id> shipIds = new Set<Id>();
            for ( Id shipId : assignmentData.keySet() ) {
                shipIds.add(shipId);
            }

            SOQLUtil util = new SOQLUtil('Skid__c', true);
            util.addFields(new Set<String>{
                    'id', 'name', 'Shipment_Line__r.Shipment__c'
            });
            util.setWhereClause('Shipment_Line__r.Shipment__c = :shipIds AND Location__c =:location');

            List<Skid__c> skidsToUpdate = new List<Skid__c>();
            for (Skid__c skid : Database.query(util.getQuery())) {
                if ( assignmentData.containsKey(skid.Shipment_Line__r.Shipment__c)) {
                    skid.Picker__c = assignmentData.get(skid.Shipment_Line__r.Shipment__c);
                    skidsToUpdate.add(skid);
                }
            }

            DML.updateAsUser(skidsToUpdate);
            result.success = true;
        } catch (Exception e) {
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
            result.success = false;
        }
        return result;
    }

}