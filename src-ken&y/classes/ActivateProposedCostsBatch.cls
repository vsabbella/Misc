public with sharing class ActivateProposedCostsBatch implements Database.Batchable<sObject>, Database.Stateful, Process.Runnable2 {
    private static DateTime now = DateTime.now();

    public List<Notify.Message> errors = new List<Notify.Message>();
    public String query = 'SELECT Id, Name, Company__c, Item__c, Start_Date__c, Company__r.Allow_Retro_Active_Standard_Cost__c FROM Item_Cost__c WHERE Status__c = \'Proposed\' ';
    public Id companyId;
    public Id facilityId;
    public Id itemId;
    public String scopeRange;
    public Boolean isUICall = false;

    public void runBatch(Process_Job__c job) {
        this.companyId = job.Company__c;
        this.facilityId = job.Facility__c;

        if (this.facilityId != null) this.scopeRange = 'FACILITY';
        else if (this.companyId != null) this.scopeRange = 'COMPANY';

        Database.executebatch(this, (job.Batch_Size__c != null && Integer.valueOf(job.Batch_Size__c) <= 200 && Integer.valueOf(job.Batch_Size__c) >= 1) ? Integer.valueOf(job.Batch_Size__c) : 200);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (scopeRange == 'FACILITY' && facilityId != null) query += 'AND Facility__c = :facilityId';
        else if (scopeRange == 'COMPANY' && companyId != null) query += 'AND Company__c = :companyId AND Facility__c = null';
        else if (scopeRange == 'SINGLE') query += 'AND Item__c = :itemId AND Facility__c = :facilityId AND Company__c = :companyId';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Item_Cost__c> costs) {
        try {
            Set<DateTime> futureDates = new Set<DateTime>();
            Set<Id> itemIds = new Set<Id>();
            for (Item_Cost__c cost:costs) {
                if (cost.Start_Date__c > now) futureDates.add(cost.Start_Date__c);
                itemIds.add(cost.Item__c);
            }

            String costWhereClause;
            String itWhereClause;
            if (scopeRange == 'SINGLE' && itemId != null) {
                costWhereClause = 'AND Company__c = :companyId ' + (facilityId != null ? 'AND Facility__c = :facilityId' : '');
                itWhereClause = 'AND Company__c = :companyId ' + (facilityId != null ? 'AND (From_Facility__c = :facilityId OR To_Facility__c = :facilityId)' : '');
            } else if (scopeRange == 'FACILITY' && facilityId != null) {
                costWhereClause = 'AND Facility__c = :facilityId';
                itWhereClause = 'AND (From_Facility__c = :facilityId OR To_Facility__c = :facilityId)'; 
            } else if (scopeRange == 'COMPANY' && companyId != null) {
                costWhereClause = 'AND Facility__c = null AND Company__c = :companyId';
                itWhereClause = 'AND Company__c = :companyId';
            }

            SOQLUtil itemQuery = new SOQLUtil('Item__c');
            itemQuery.addField('Id');
            itemQuery.setWhereClause('Id IN :itemIds AND Company__c = :companyId');

            SOQLUtil.ChildRelationship costQuery = new SOQLUtil.ChildRelationship(itemQuery, 'Item_Costs__r');
            costQuery.addFields(new Set<String>{ 'Id', 'Start_Date__c' });
            costQuery.setWhereClause('Status__c = \'Approved\' AND Start_Date__c <= :now AND Invalid_Flag__c = false ' + costWhereClause);
            costQuery.setOrderByClause('Start_Date__c DESC');
            costQuery.setLimit(1);
            itemQuery.addChildRelationship(costQuery);

            Map<Id, Item__c> items = new Map<Id, Item__c>((List<Item__c>)Database.query(itemQuery.getQuery()));

            SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c', true, true);
            itQuery.addFields(new Set<String>{ 'MIN(Transaction_Date__c) minDate', 'MAX(Transaction_Date__c) maxDate', 'Item__c itemId' });
            itQuery.setWhereClause('Item__c IN :itemIds ' + itWhereClause + ' GROUP BY Item__c');

            Map<Id, DateTime> minDates = new Map<Id, DateTime>();
            Map<Id, DateTime> maxDates = new Map<Id, DateTime>();
            for (AggregateResult ar:Database.query(itQuery.getQuery())) {
                Id itemId = (Id)ar.get('itemId');
                minDates.put(itemId, (DateTime)ar.get('minDate'));
                maxDates.put(itemId, (DateTime)ar.get('maxDate'));
            }

            Map<Id, Item__c> futureItems;
            if (futureDates.size() > 0) {
                SOQLUtil futureItemQuery = new SOQLUtil('Item__c');
                futureItemQuery.addField('Id');
                futureItemQuery.setWhereClause('Id IN :itemIds AND Company__c = :companyId');

                SOQLUtil.ChildRelationship futureCostQuery = new SOQLUtil.ChildRelationship(futureItemQuery, 'Item_Costs__r');
                futureCostQuery.addFields(new Set<String>{ 'Id', 'Start_Date__c' });
                futureCostQuery.setWhereClause('Status__c = \'Approved\' AND Start_Date__c IN :futureDates AND Invalid_Flag__c = false ' + costWhereClause);
                futureCostQuery.setOrderByClause('Start_Date__c ASC');
                futureItemQuery.addChildRelationship(futureCostQuery);

                futureItems = new Map<Id, Item__c>((List<Item__c>)Database.query(futureItemQuery.getQuery()));
            }
        
            List<Item_Cost__c> costsToUpdate = new List<Item_Cost__c>();
            for (Item_cost__c cost:costs) {
                Item__c item = items.get(cost.Item__c);
                Item_Cost__c lastCost = item.Item_Costs__r.size() > 0 ? item.Item_Costs__r[0] : null;
                DateTime firstItDate = minDates.get(item.Id);
                DateTime lastItDate = maxDates.get(item.Id);

                if (lastCost == null) {
                    if (firstItDate == null) {
                        if (cost.Start_Date__c > now) {
                            /*
                             * If there are no existing costs and no ITs and the proposed start date is in the future, set start date to approval
                             * date. If we approve a start date in the future, then the user transacts before the start date, then the user tries
                             * to approve another cost after the first start date with a proposed start date before the IT (to give it a cost),
                             * the system will move the start date to the first start and the IT will never have a cost.
                             *
                             *                        first approval         start date 
                             * |---------------------------|---------------------|--------------------|
                             *
                             *                            first IT           start date
                             * |------------------------------|------------------|--------------------|
                             *
                             *         second start date  first IT           start date   second approval
                             * |--------------|---------------|------------------|---------------|----|
                             *
                             *                            first IT           start date   second approval
                             * |------------------------------|------------------|---------------|----|
                             *                                           second start date
                             */

                            cost.Start_Date__c = now;
                            cost.Change_Reason__c = 'The start date has been updated to the approval date as the proposed start date was in the future';
                        }
                    } else if (cost.Start_Date__c > firstItDate) {
                        //If there are no existing costs but there are ITs and the proposed start date is after the first IT date, set start date to first IT date.
                        cost.Start_Date__c = firstItDate;
                        cost.Change_Reason__c = 'The start date has been updated to the first inventory transaction date as the proposed start date was after that inventory transaction date.';
                    }
                } else if (cost.Start_Date__c <= now) {
                    DateTime lastDate = cost.Company__r.Allow_Retro_Active_Standard_Cost__c == false && lastItDate != null && lastItDate > lastCost.Start_Date__c ? lastItDate : lastCost.Start_Date__c;
                    if (cost.Start_Date__c < lastDate) {
                        cost.Start_Date__c = lastDate;
                        cost.Change_Reason__c = cost.Company__r.Allow_Retro_Active_Standard_Cost__c == false ? Label.Non_Retro_Item_Cost_start_date_change_message : Label.Retro_Item_Cost_start_date_change_message;
                    }

                    if (cost.Start_Date__c == lastCost.Start_Date__c) costsToUpdate.add(new Item_Cost__c(Id = lastCost.Id, Invalid_Flag__c = true));
                } else if (futureItems != null && futureItems.containsKey(cost.Item__c)) {
                    for (Item_Cost__c futureCost:futureItems.get(cost.Item__c).Item_Costs__r) {
                        if (cost.Start_Date__c == futureCost.Start_Date__c) costsToUpdate.add(new Item_Cost__c(Id = futureCost.Id, Invalid_Flag__c = true));
                        if (futureCost.Start_Date__c >= cost.Start_Date__c) break;
                    }
                }

                cost.Status__c = 'Approved';
                cost.Date_Approved__c = now;
                costsToUpdate.add(cost);
            }

            ItemService.allowItemCostUpdate = true;
            DML.updateAsUser(costsToUpdate);
            ItemService.allowItemCostUpdate = false;
        } catch (Exception e) {
            errors.add(Notify.getErrorMessage(costs, e.getMessage(), e.getStackTraceString()));
            throw e;
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        Notify.sendEmailBatchFinish(errors.size(), null, errors, bc);
        if (isUICall == false) MasterControlProgram.finishedBatch(this);
    }   
}