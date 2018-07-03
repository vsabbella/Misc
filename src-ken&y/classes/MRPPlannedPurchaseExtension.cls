public with sharing class MRPPlannedPurchaseExtension {

    ApexPages.StandardSetController setCon;
    public Boolean selectError { get; set; } { selectError = false; }
    List<MRP__c> mrpList = new List<MRP__c>();
    Set<Id> itemIds = new Set<Id>();
    Set<Id> facilityIds = new Set<Id>();
    Boolean bySupplier = false;
       
    public MRPPlannedPurchaseExtension(ApexPages.StandardSetController controller) {
        setCon = controller;
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,Label.No_Plans_Selected));
            selectError = true;
            return;
        }

        Set<Id> planSet = new Set<Id>();
        for (MRP__c plan:(List<MRP__c>)setCon.getSelected()) {      
            planSet.add(plan.Id);
        }

        SOQLUtil mrpQuery = new SOQLUtil('MRP__c',true);
        mrpQuery.addAllCustomFields();
        mrpQuery.addAllCustomFields(Item__c.sObjectType,'Item__r');
        mrpQuery.addFields(new set<String>{ 'Company__r.Default_Purchasing_Deliver_To_Facility__c','Company__r.Default_Purchasing_Deliver_To_Facility__r.Facility_Identifier__c','Company__r.Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__c',
            'Facility__r.Default_Work_Order_Complete_to_Location__c','Facility__r.Default_Purchasing_Delivery_Location__c','Facility__r.Facility_Identifier__c','Item__r.Supplier__r.Remit_to__c','Item__r.Supplier__r.Status__c',
            'Next_Level_MRP__r.Item__c', 'Next_Level_MRP__r.Material_Tracking__c','Next_Level_MRP__r.Material_Tracking__r.Allocation_Required__c','Next_Level_MRP__r.Material_Tracking__r.Allocate_on_Receipt__c',
            'Item__r.Purchasing_UOM__c', 'Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c' });
        mrpQuery.setWhereClause('Id IN :planset');
        mrpQuery.setOrderByClause('Item__r.Supplier__c, Item__r.Name, Required_Date__c ASC');
        mrpList = Database.query(mrpQuery.getQuery());

        for (MRP__c plan:mrpList) {
            itemIds.add(plan.Item__c);
            facilityIds.add(plan.Facility__c);
        }

        for (MRP__c plan:MRPList) {
            if (plan.Planned__c != true) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,plan.Name + ': ' + Label.Only_MRP_Planed_records_can_be_selected));
            } else if (plan.Modified_Quantity__c <= 0.0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,plan.Name + ': ' + Label.Only_plans_with_positive_modified_quantities_can_be_selected));
            } else if (plan.Item__r.Source__c != 'Purchased') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,plan.Name + ': ' + Label.Only_items_with_Source_Purchased_can_be_selected));
            } else if (plan.Item__r.Supplier__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,plan.Name + ': ' + Label.No_Supplier_for_Item));
            } else if (plan.Item__r.Supplier__r.Remit_to__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,plan.Name + ': ' + Label.No_Remit_to_Supplier_for_Item));
            } else if (plan.Item__r.Supplier__r.Status__c != 'Active') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,plan.Name + ': ' + Label.Supplier_for_Item_is_not_Active));
            } else if (plan.Item__r.Buyer_Planner__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,plan.Name + ': ' + Label.No_buyer_Planner_for_item));
            } else if (plan.Item__r.Purchasing_UOM__c == null) { //only purchased items are allowed anyway
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,plan.Name + ': ' + Label.Item_has_no_Purchasing_UOM));
            } else if (plan.Facility__c == null && plan.Company__r.Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,plan.Name + ': ' + Label.Company_has_no_Default_Purchasing_Delivery_Location));
            } else if (plan.Facility__c != null && plan.Facility__r.Default_Purchasing_Delivery_Location__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,plan.Name + ': ' + Label.Facility_has_no_Default_Purchasing_Delivery_Location));
            } else {
                Decimal activeStandardCost = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,plan.Company__c,plan.Facility__c,System.now(),plan.Item__c);
                if (activeStandardCost == null || activeStandardCost == 0.0) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,plan.Name + ': ' + Label.Standard_Cost_zero));
                }
                bySupplier = false;
            }
        }

        if (ApexPages.hasMessages(ApexPages.Severity.FATAL)) {
            selectError = true;
        }
    }
    
    public PageReference generate1() {
        bySupplier = true;
        generate();
        return setcon.cancel();
    }
    
    public PageReference generate() {
        Map<Id,Purchase_Order__c> poMap = new Map<Id,Purchase_Order__c>();
        Map<Id,List<Purchase_Order_Line__c>> polMap = new Map<Id,List<Purchase_Order_Line__c>>();
        for (MRP__c plan:mrpList) {
            Id key = bySupplier ? plan.Item__r.Supplier__c : plan.Id;

            Purchase_Order__c po = poMap.get(key);
            if (po == null) {
                po = new Purchase_Order__c(
                    Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_PENDING,
                    Buyer__c = plan.Item__r.Buyer_Planner__c,
                    Company__c = plan.Company__c,
                    MRP_Plan__c = plan.Name,
                    Order_Date__c = System.today(),
                    Status__c = 'Open',
                    Supplier__c = plan.Item__r.Supplier__c,
                    Remit_To_Supplier__c = plan.Item__r.Supplier__r.Remit_to__c
                );
                if (plan.Facility__c == null) {
                    po.Delivery_Location__c = plan.Company__r.Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__c;
                    po.Delivery_Facility__c = plan.Company__r.Default_Purchasing_Deliver_To_Facility__c;
                    po.Delivery_Facility__r = plan.Company__r.Default_Purchasing_Deliver_To_Facility__r;
                } else {
                    po.Delivery_Location__c = plan.Facility__r.Default_Purchasing_Delivery_Location__c;
                    po.Delivery_Facility__c = plan.Facility__c;
                    po.Delivery_Facility__r = plan.Facility__r;
                }
                poMap.put(key,po);
                polMap.put(key,new List<Purchase_Order_Line__c>());
            }
            
            List<Id> lstPkgUom = (List<Id>) JSON.deserialize( plan.Item__r.Packaging_UOM__c, List<Id>.class );
            Purchase_Order_Line__c pol = new Purchase_Order_Line__c(
                Company__c = po.Company__c,
                Date_Added__c = System.today(),
                Date_Last_Changed__c = System.today(),
                Description__c = plan.Item__r.Description__c,
                Item__c = plan.Item__c,
                Supplier__c = plan.Item__r.Supplier__c,
                Line__c = polMap.get(key).size() + 1,
                MRP_Plan__c = plan.Name,
                Need_Date__c = plan.Required_Date__c,
                Order_Quantity__c = plan.Modified_Quantity__c / KSE.getConversionFactor( plan.Item__c, plan.Facility__r.Facility_Identifier__c, plan.Item__r.Purchasing_UOM__c, plan.Item__r.Stocking_UOM__c, lstPkgUom ),
                Purchase_UOM__c = plan.Item__r.Purchasing_UOM__c,
                Status__c = 'Open',
                Invoice_Matching__c = 'Three Way',
                Unit_Price__c = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,plan.Company__c,plan.Facility__c,System.now(),plan.Item__c),
                Delivery_Location__c = po.Delivery_Location__c,
                Delivery_Facility__c = po.Delivery_Facility__c
            );
            
            // KNDY-13458 Tag the PO Line with material tracking
            if ( plan.Next_Level_MRP__r.Material_Tracking__c != null && plan.Next_Level_MRP__r.Material_Tracking__r.Allocate_on_Receipt__c && plan.Next_Level_MRP__r.Material_Tracking__r.Allocation_Required__c ) {
                pol.Material_Tracking__c = plan.Next_Level_MRP__r.Material_Tracking__c;
            }
             
            polMap.get(key).add(pol);

            plan.Modified_Quantity__c = 0;
        }

        DML.insertAsUser(poMap.values());   //Insert should not be in loop

        List<Purchase_Order_Line__c> polsToInsert = new List<Purchase_Order_Line__c>();
        for (Id key:poMap.keySet()) {
            for (Purchase_Order_Line__c pol:polMap.get(key)) {
                pol.Purchase_Order__c = poMap.get(key).Id;
                polsToInsert.add(pol);
            }
        }
        DML.insertAsUser(polsToInsert);

        DML.updateAsUser(mrpList);

        return setCon.cancel();
    }
}