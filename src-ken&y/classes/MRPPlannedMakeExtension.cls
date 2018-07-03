public with sharing class MRPPlannedMakeExtension {

    ApexPages.StandardSetController setCon;
    public Boolean selecterror {get; set;}
    set <ID> planset = new set<ID>();
    List<MRP__c> MRPList = new List<MRP__c>();
    List<Work_Order__c> WOList = new List<Work_Order__c>();
       
    public MRPPlannedMakeExtension(ApexPages.StandardSetController controller) {
        
        setCon = controller;
        selecterror = false;
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_Plans_Selected) );
            selecterror = true;
        }
        for (MRP__c plan: (List<MRP__c>)setCon.getSelected() ) {      
            planset.add(plan.ID);
        }
       
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('MRP__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'ID','Name','Company__c','Company__r.Default_Work_Order_Facility__c','Company__r.Default_Work_Order_Facility__r.Facility_Identifier__c','Company__r.Default_Work_Order_Facility__r.Default_Work_Order_Complete_to_Location__c',
            'Company__r.Default_Work_Order_Facility__r.Default_Work_Order_MRB_Location__c','Company__r.Default_Work_Order_Facility__r.Default_Work_Order_WIP_Location__c',
            'Demand__C','Facility__c','Facility__r.Default_Work_Order_Complete_to_Location__c','Facility__r.Default_Work_Order_MRB_Location__c', 'Facility__r.Facility_Identifier__c',
            'Facility__r.Default_Work_Order_WIP_Location__c','Item__c','Item__r.Source__c','Modified_Quantity__c','Planned__c','Required_Date__c',
            'Item__r.Stocking_UOM__c', 'Start_Date__c','Item__r.Packaging_UOM__c'
        });
        soql.setWhereClause('ID in : planset');
        MRPList = Database.query(soql.getQuery());
        
        Set<Id> itemIds = new Set<Id> ();
        Set<Id> facilityIds = new Set<Id> ();
        
        for (MRP__c plan: MRPList) {
            itemIds.add(plan.Item__c);
            facilityIds.add(plan.Facility__c);
        }
        
        SOQLUtil itemSpecQuery = new SOQLUtil('Item_Specification__c', true); //enforceFLS=true, running in user mode
        itemSpecQuery.addFields(new set<string>{
            'ID', 'Name', 'Default_Work_Order_Packaging_UOM__c', 'Start_Date2__c', 'Item__c', 'Facility__c', 'Facility__r.Facility_Identifier__c', 'Active__c'
        });
        itemSpecQuery.setWhereClause('Item__c IN :itemIds and (Facility__c in :facilityIds OR Facility__c = null) AND Production__c = true AND Active__c = true AND Type__c != \'Repair\' ');
        itemSpecQuery.setOrderByClause('Facility__c DESC NULLS LAST, Start_Date2__c DESC'); 
        
        Map<Id, List<Item_Specification__c>> mapItemSpecs = new Map<Id, List<Item_Specification__c>>();
        for ( Item_Specification__c itemSpec : Database.query ( itemSpecQuery.getQuery() ) ) {
            if ( !mapItemSpecs.containsKey ( itemSpec.Item__c ) ) {
                mapItemSpecs.put( itemSpec.Item__c, new List<Item_Specification__c> () );
            }
            mapItemSpecs.get (itemSpec.Item__c).add(itemSpec);
        }

        for (MRP__c plan: MRPList) {
            if (plan.Planned__c != true) {
                selecterror = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                    Label.Only_MRP_Planed_records_can_be_selected  +plan.Name));
                break;
            }
            if (plan.Modified_Quantity__c <= 0.0) {
                selecterror = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                    Label.Only_plans_with_positive_modified_quantities_can_be_selected +plan.Name));
                break;
            }
           if (plan.Item__r.Source__c == 'Purchased') {
                selecterror = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                    Label.Items_with_source_purchased_cannot_be_selected +plan.Name));
                break;
            }
            
            Work_Order__c WOObj = new Work_Order__c();
            if ( mapItemSpecs.containsKey  ( plan.Item__c)) {
                for ( Item_Specification__c itemSpec : mapItemSpecs.get(plan.Item__c) ) {
                    // Facility of item spec has to match plan facility. itemspec with no facility is allowed too
                    if ( itemSpec.Facility__c == plan.Facility__c || itemSpec.Facility__c == null  ) {
                        if ( itemSpec.Start_Date2__c.date() < plan.Start_Date__c ) {
                            WOObj.Assembly_Item_Specification__c = itemSpec.Id;
                            WOObj.Assembly_Item_Specification__r = itemSpec;
                            WOObj.Packaging_UOM__c = itemSpec.Default_Work_Order_Packaging_UOM__c;
                            break;
                        }
                    }
                }
            }
            
            if ( WOObj.Assembly_Item_Specification__c == null ) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                    Label.Plan_Item_has_no_ItemSpecification_as_of_Plan_Release_Date  +plan.Name));
            }
            
            if ( WOObj.Packaging_UOM__c == null ) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                    plan.Name + ': Please configure the Default Work Order Packaging UOM for Item Specification ' + WOObj.Assembly_Item_Specification__r.Name  ));
            }
            
            // WOObj.Assembly_Item_Specification__c = ISList[0].ID;
            WOObj.Item__c = plan.Item__c;
            WOObj.Item__r = plan.Item__r;
            WOObj.Company__c = plan.Company__c;
            
            if (plan.Facility__c == null) {  // MRP by Company
                if (plan.Company__r.Default_Work_Order_Facility__r.Default_Work_Order_Complete_to_Location__c == null) {
                    selecterror = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                        Label.Company_has_no_default_WorkOrder_Complete_to_location  +plan.Name));
                    break;
                }
                if (plan.Company__r.Default_Work_Order_Facility__r.Default_Work_Order_MRB_Location__c == null) {
                    selecterror = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                        Label.Company_has_no_default_WorkOrder_MRB_location  +plan.Name));
                    break;
                }
                if (plan.Company__r.Default_Work_Order_Facility__r.Default_Work_Order_WIP_Location__c == null) {
                    selecterror = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                        Label.Company_has_no_default_WorkOrder_WIP_location  +plan.Name));
                    break;
                }
                WOObj.Facility__c = plan.Company__r.Default_Work_Order_Facility__c;
                WOObj.Facility__r = plan.Company__r.Default_Work_Order_Facility__r;
                WOObj.Complete_to_Location__c = plan.Company__r.Default_Work_Order_Facility__r.Default_Work_Order_Complete_to_Location__c;
                WOObj.MRB_Location__c = plan.Company__r.Default_Work_Order_Facility__r.Default_Work_Order_MRB_Location__c;
                WOObj.Default_WIP_Location__c = plan.Company__r.Default_Work_Order_Facility__r.Default_Work_Order_WIP_Location__c;
            }
            else { // MRP by Facility
                if (plan.Facility__r.Default_Work_Order_Complete_to_Location__c == null) {
                    selecterror = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                        Label.Facility_has_no_default_WorkOrder_Complete_to_location +plan.Name));
                    break;
                }
                if (plan.Facility__r.Default_Work_Order_MRB_Location__c == null) {
                    selecterror = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                        Label.Facility_has_no_default_WorkOrder_MRB_location  +plan.Name));
                    break;
                }
                if (plan.Facility__r.Default_Work_Order_WIP_Location__c == null) {
                    selecterror = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                        Label.Facility_has_no_default_WorkOrder_WIP_location +plan.Name));
                    break;
                }
                WOObj.Facility__c = plan.Facility__c;
                WOObj.Facility__r = plan.Facility__r;
                WOObj.Complete_to_Location__c = plan.Facility__r.Default_Work_Order_Complete_to_Location__c;
                WOObj.MRB_Location__c = plan.Facility__r.Default_Work_Order_MRB_Location__c;
                WOObj.Default_WIP_Location__c = plan.Facility__r.Default_Work_Order_WIP_Location__c;
            }
           WOObj.MRP_Demand__c = plan.Demand__c;
           WOObj.Earliest_Completion_Date2__c = DateTime.newInstance(plan.Required_Date__c,Time.newInstance(0,0,0,0));
           WOObj.MRP_Plan__c = plan.Name;
           WOObj.Need_Date2__c = DateTime.newInstance(plan.Required_Date__c,Time.newInstance(0,0,0,0));             
           List<Id> lstPkgUom = (List<Id>) JSON.deserialize( WOObj.Item__r.Packaging_UOM__c, List<Id>.class );
           WOObj.Order_Quantity__c = plan.Modified_Quantity__c / KSE.getConversionFactor( WOObj.Item__c, WOObj.Facility__r.Facility_Identifier__c, WOObj.Packaging_UOM__c, plan.Item__r.Stocking_UOM__c, lstPkgUom);
           WOObj.Start_Date2__c = DateTime.newInstance(plan.Start_Date__c,Time.newInstance(0,0,0,0));
           WOObj.Status__c = Label.Draft;
           if(WOObj.Assembly_Item_Specification__c != null &&  WOObj.Packaging_UOM__c != null){
           WOList.add(WOObj);
           plan.Modified_Quantity__c = 0.0;
           }
        }
    }
    
    public pageReference generate(){
       DML.insertAsUser( WOList ,false );
       DML.updateAsUser( MRPList );
        
       return setcon.cancel();
    }
}