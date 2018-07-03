public with sharing class ItemCostRevaluationBatch implements Database.Batchable<sObject>, Database.Stateful, Process.Runnable2 {
    private Id companyId;
    private Id facilityId;
    private DateTime now = DateTime.now();

    public void runBatch(Process_Job__c job) {
        companyId = job.Company__c;
        facilityId = job.Facility__c;
        Database.executebatch(this, job.Batch_Size__c >= 1 && job.Batch_Size__c <= 200 ? (Integer)job.Batch_Size__c : 200);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addFields(new Set<String>{ 'Id', 'Name', 'Item__c', 'Standard_Cost__c', 'Start_Date__c' });
        costQuery.setWhereClause('Status__c = \'Approved\' AND On_hand_Revaluation__c = false AND Start_Date__c <= :now AND Company__c = :companyId AND Facility__c = ' + (facilityId != null ? ':facilityId' : 'null'));
        costQuery.setOrderByClause('Start_Date__c ASC, Date_Approved__c ASC');
        return Database.getQueryLocator(costQuery.getQuery());
    }

    public void execute(Database.BatchableContext bc, List<Item_Cost__c> costs) {
        Map<Id, List<Item_Cost__c>> costMap = new Map<Id, List<Item_Cost__c>>();
        DateTime minStartDate = costs[0].Start_Date__c;
        for (Item_Cost__c cost:costs) {
            if (costMap.containsKey(cost.Item__c) == false) costMap.put(cost.Item__c, new List<Item_Cost__c>{ cost });
            else costMap.get(cost.Item__c).add(cost);

            if (cost.Start_Date__c < minStartDate) minStartDate = cost.Start_Date__c;
        }

        Set<Id> itemIds = costMap.keySet();
        SOQLUtil itemQuery = new SOQLUtil('Item__c');
        itemQuery.addFields(new Set<String>{ 'Id', 'Name', 'Stocking_UOM__c' });
        itemQuery.setWhereClause('Id IN :itemIds AND Company__c = :companyId AND Active__c = true');

        SOQLUtil.ChildRelationship costQuery = new SOQLUtil.ChildRelationship(itemQuery, 'Item_Costs__r');
        costQuery.addFields(new Set<String>{ 'Id', 'Name', 'Standard_Cost__c' });
        costQuery.setWhereClause('Status__c = \'Approved\' AND On_hand_Revaluation__c = true AND Company__c = :companyId AND Facility__c = ' + (facilityId != null ? ':facilityId' : 'null'));
        costQuery.setOrderByClause('Start_Date__c DESC, Date_Approved__c DESC');
        costQuery.setLimit(1);
        itemQuery.addChildRelationship(costQuery);

        Set<String> skidTypes = new Set<String>{ SkidService3.SKID_TYPE_LOCATION, SkidService3.SKID_TYPE_WIP, SkidService3.SKID_TYPE_INTRANSIT };
        SOQLUtil.ChildRelationship skidQuery = new SOQLUtil.ChildRelationship(itemQuery, 'SKIDs__r');
        skidQuery.addFields(new Set<String>{ 'Id', 'Name', 'Facility2__c', 'Quantity_Stocking_UOM__c', 'Type__c' });
        skidQuery.setWhereClause('Type__c IN :skidTypes AND Quantity_Stocking_UOM__c != 0 AND Consigned_Owner__c = null AND Customer__c = null AND ' + (facilityId != null ? 'Facility2__c = :facilityId' : 'Company__c = :companyId'));
        itemQuery.addChildRelationship(skidQuery);

        Set<String> itTypes = new Set<String>{ 'In-Transit', 'Void - In-Transit', 'Work Order Component Issue', 'Work Order Component Return', 'Work Order Component Scrap', 'Transfer of Ownership', 'Undo Transfer of Ownership' };
        SOQLUtil.ChildRelationship itQuery = new SOQLUtil.ChildRelationship(itemQuery, 'Inventory_Transactions__r');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'From_Facility__c', 'To_Facility__c', 'Net_Quantity__c', 'Quantity_Stocking_UOM__c', 'Receipt_Line__c', 'Receipt_Line__r.ASN_Line__c', 'Transaction_Date__c', 'Type__c' });
        itQuery.setWhereClause('Transaction_Date__c >= :minStartDate AND (Consigned_Owner__c = null OR Type__c = \'Undo Transfer of Ownership\') AND (Customer__c = null OR (Type__c = \'Sales Order Shipment\' AND Sales_Order_Line__r.Customer__c = null)) AND (Type__c IN :itTypes OR Net_Quantity__c != 0) AND ' + (facilityId != null ? '(From_Facility__c = :facilityId OR To_Facility__c = :facilityId)' : 'Company__c = :companyId'));
        itQuery.setOrderByClause('Transaction_Date__c DESC');
        itemQuery.addChildRelationship(itQuery);

        List<Inventory_Transaction__c> itsToInsert = new List<Inventory_Transaction__c>();
        List<Inventory_Change__c> icsToUpdate = new List<Inventory_Change__c>();
        for (Item__c item:Database.query(itemQuery.getQuery())) {
            Map<Id, Decimal> currentQty = new Map<Id, Decimal>();
            Map<Id, Decimal> wipQty = new Map<Id, Decimal>();
            Map<Id, Decimal> inTransitQty = new Map<Id, Decimal>();
            for (SKID__c skid:item.SKIDs__r) {
                Map<Id, Decimal> qtyMap = skid.Type__c == SkidService3.SKID_TYPE_LOCATION ? currentQty : (skid.Type__c == SkidService3.SKID_TYPE_WIP ? wipQty : inTransitQty);
                qtyMap.put(skid.Facility2__c, KSE.addQuantityToField(qtyMap.get(skid.Facility2__c), skid.Quantity_Stocking_UOM__c));
            }

            List<Item_Cost__c> itemCosts = costMap.get(item.Id);
            for (Integer i = 0; i < itemCosts.size(); i++) {
                Item_Cost__c cost = itemCosts[i];
                Item_Cost__c prevCost = i == 0 ? (item.Item_Costs__r.size() > 0 ? item.Item_Costs__r[0] : new Item_Cost__c(Standard_Cost__c = 0)) : itemCosts[i - 1];

                Map<Id, Decimal> currentQtys = currentQty.clone();
                Map<Id, Decimal> wipQtys = wipQty.clone();
                Map<Id, Decimal> inTransitQtys = inTransitQty.clone();

                Inventory_Change__c ic = new Inventory_Change__c(
                    Company__c = companyId,
                    Facility__c = facilityId,
                    Item__c = item.Id,
                    Transaction_Date__c = cost.Start_Date__c,
                    Type__c = 'Activate Proposed Costs'
                );

                for (Inventory_Transaction__c it:item.Inventory_Transactions__r) {
                    if (it.Transaction_Date__c < cost.Start_Date__c) break;

                    if (it.Type__c == 'Transfer of Ownership') {
                        currentQtys.put(it.To_Facility__c, KSE.subtractDecimals(currentQtys.get(it.To_Facility__c), it.Quantity_Stocking_UOM__c));
                    } else if (it.Type__c == 'Undo Transfer of Ownership') {
                        currentQtys.put(it.From_Facility__c, KSE.addQuantityToField(currentQtys.get(it.From_Facility__c), it.Quantity_Stocking_UOM__c));
                    } else if (it.Type__c == 'In-Transit' || it.Type__c == 'Void - In-Transit Purchase Order Receipt' || it.Type__c == 'Transfer Order Shipment' || it.Type__c == 'Void - Transfer Order Receipt') {
                        inTransitQtys.put(it.To_Facility__c, KSE.subtractDecimals(inTransitQtys.get(it.To_Facility__c), it.Quantity_Stocking_UOM__c));
                        if (it.Type__c != 'In-Transit') currentQtys.put(it.From_Facility__c, KSE.addQuantityToField(currentQtys.get(it.From_Facility__c), it.Quantity_Stocking_UOM__c));
                    } else if (it.Type__c == 'Void - In-Transit' || it.Type__c == 'In-Transit Purchase Order Receipt' || (it.Type__c == 'Purchase Order Receipt' && it.Receipt_Line__r.ASN_Line__c != null) || it.Type__c == 'Transfer Order Undo Shipment' || it.Type__c == 'Transfer Order Receipt') {
                        inTransitQtys.put(it.From_Facility__c, KSE.addQuantityToField(inTransitQtys.get(it.From_Facility__c), it.Quantity_Stocking_UOM__c));
                        if (it.Type__c != 'Void - In-Transit') currentQtys.put(it.To_Facility__c, KSE.subtractDecimals(currentQtys.get(it.To_Facility__c), it.Quantity_Stocking_UOM__c));
                    } else if (it.Type__c == 'Work Order Component Issue' || it.Type__c == 'Work Order Return To WIP') {
                        wipQtys.put(it.To_Facility__c, KSE.subtractDecimals(wipQtys.get(it.To_Facility__c), it.Quantity_Stocking_UOM__c));
                        if (it.Type__c != 'Work Order Return To WIP') currentQtys.put(it.From_Facility__c, KSE.addQuantityToField(currentQtys.get(it.From_Facility__c), it.Quantity_Stocking_UOM__c));
                    } else if (it.Type__c == 'Work Order Component Return' || it.Type__c == 'Work Order Component Scrap' || it.Type__c == 'Work Order Issue From WIP') {
                        wipQtys.put(it.From_Facility__c, KSE.addQuantityToField(wipQtys.get(it.From_Facility__c), it.Quantity_Stocking_UOM__c));
                        if (it.Type__c != 'Work Order Issue From WIP') currentQtys.put(it.To_Facility__c, KSE.subtractDecimals(currentQtys.get(it.To_Facility__c), it.Quantity_Stocking_UOM__c));
                    } else {
                        Id facId = it.Net_Quantity__c > 0 ? it.To_Facility__c : it.From_Facility__c;
                        currentQtys.put(facId, KSE.subtractDecimals(currentQtys.get(facId), it.Net_Quantity__c));
                    }
                }

                itsToInsert.addAll(generateIts(currentQtys, 'Inventory', ic, cost, prevCost, item));
                itsToInsert.addAll(generateIts(wipQtys, 'WIP', ic, cost, prevCost, item));
                itsToInsert.addAll(generateIts(inTransitQtys, 'In-Transit', ic, cost, prevCost, item));

                if (ic.Id != null) icsToUpdate.add(ic);

                cost.On_hand_Revaluation__c = true;
            }
        }

        if (itsToInsert.size() > 0) DML.insertAsUser(itsToInsert);
        if (icsToUpdate.size() > 0) DML.updateAsUser(icsToUpdate);
        ItemService.allowItemCostUpdate = true;
        DML.updateAsUser(costs);
        ItemService.allowItemCostUpdate = false;
    }

    private List<Inventory_Transaction__c> generateIts(Map<Id, Decimal> qtyMap, String type, Inventory_Change__c ic, Item_Cost__c cost, Item_Cost__c prevCost, Item__c item) {
        List<Inventory_Transaction__c> itsToInsert = new List<Inventory_Transaction__c>();
        for (Id facId:qtyMap.keySet()) {
            Decimal qty = qtyMap.get(facId);
            if (qty == 0) continue;

            if (ic.Id == null) {
                DML.insertAsSystem(ic);
                ic.Finalized__c = true;
            }

            Decimal costDiff = cost.Standard_Cost__c - prevCost.Standard_Cost__c;

            itsToInsert.add(new Inventory_Transaction__c(
                Company__c = companyId,
                Inventory_Change__c = ic.Id,
                Type__c = 'Activate Proposed Costs - ' + type,
                Transaction_Date__c = cost.Start_Date__c,
                Item__c = item.Id,
                Packaging_UOM__c = item.Stocking_UOM__c,
                Stocking_UOM__c = item.Stocking_UOM__c,
                Quantity__c = qty,
                Quantity_Stocking_UOM__c = qty,
                From_Facility__c = facId,
                To_Facility__c = facId,
                Standard_Cost__c = costDiff,
                From_Standard_Cost__c = prevCost.Standard_Cost__c,
                To_Standard_Cost__c = cost.Standard_Cost__c,
                Extended_Cost__c = qty * costDiff
            ));
        }
        return itsToInsert;
    }

    public void finish(Database.BatchableContext bc) {
        Notify.sendEmailBatchFinish(null, new List<Notify.Message>(), bc);
    }
}