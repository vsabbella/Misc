public with sharing class ItemCostCloneExt {
    
    public Boolean clone { get; private set; } { clone = false; }
    public List<Item_Cost__c> itemCosts { get; private set; }
    public Boolean saveDisabled { get; private set; } { saveDisabled = false; }
    public String targetStatus { get; set; }
    public String namespaceUU { get; private set; } { namespaceUU = KSE.NamespaceUU; }
    
    private Map<Id,Item_Cost__c> itemCostMap = new Map<Id,Item_Cost__c>();
    private String retURL;

    public List<Id> costIds;
    public ItemCostCloneExt(ApexPages.StandardSetController con) { costIds = new List<Id>((new Map<Id, Item_Cost__c>((List<Item_Cost__c>)con.getSelected())).keySet()); }
    public PageReference massRedirect() {
        PageReference pr = Page.ItemCostClone;
        Map<String, String> params = pr.getParameters();
        params.put('recs', String.join(costIds, ','));
        if (ApexPages.currentPage().getUrl().containsIgnoreCase('itemcostclonemass') == true) params.put('clone', '1');
        return pr;
    }
    
    public ItemCostCloneExt() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        if (params.get('clone') == '1') clone = true;

        String idString = params.get('recs');
        if (String.isNotBlank(idString) == true) {
            List<String> ids = idString.split(',');
            SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
            costQuery.addAllCustomFields();
            costQuery.setWhereClause('Id IN :ids');
            itemCosts = Database.query(costQuery.getQuery());
        }

        if (itemCosts == null || itemCosts.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.No_item_costs_were_selected));
            saveDisabled = true;
            return;
        }

        if (itemCosts.size() == 1) retURL = itemCosts[0].Id;

        if (!clone) {
        	for (Item_Cost__c cost:itemCosts) {
        		if (cost.Status__c == 'Approved' || cost.Status__c == 'Proposed') {
        			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.You_cannot_propose_a_proposed_or_approved_cost));
            		saveDisabled = true;
            		return;
        		}
        	}
        }
        for (Item_Cost__c cost:itemCosts) {
            itemCostMap.put(cost.Id,cost);
            cost.Id = null;
        }
    }
    public PageReference saveClone() {
        if (targetStatus == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.Target_status_has_not_been_selected));
            saveDisabled = true;
            return null;
        }
        List<Id> newItemCostIds;
        for (Id costId:itemCostMap.keySet())
            itemCostMap.get(costId).Id = costId;
        try {
            newItemCostIds = ItemService.cloneItemCosts(itemCosts,targetStatus);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            for (Item_Cost__c cost:itemCosts)
                cost.Id = null;
            saveDisabled = true;
            return null;
        }
        return (newItemCostIds != null && newItemCostIds.size() == 1) ? (new PageReference('/' + newItemCostIds[0])) : cancel();
    }
    public PageReference propose() {
        List<Id> newItemCostIds;
        for (Id costId:itemCostMap.keySet())
            itemCostMap.get(costId).Id = costId;
        try {
            newItemCostIds = ItemService.cloneItemCosts(itemCosts,'Proposed');
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            for (Item_Cost__c cost:itemCosts)
                cost.Id = null;
            return null;
        }
        return (newItemCostIds != null && newItemCostIds.size() == 1) ? (new PageReference('/' + newItemCostIds[0])) : cancel();
    } 
    public void enableSave() { saveDisabled = false; }
    public List<SelectOption> getItemCostStatuses() {
        List<SelectOption> itemCostStatuses = new List<SelectOption>();
        for (Schema.PickListEntry ple:Item_Cost__c.Status__c.getDescribe().getPicklistValues())
            if (ple.getValue() != 'Proposed' && ple.getValue() != 'Approved')
                itemCostStatuses.add(new SelectOption(ple.getValue(),ple.getValue()));  
        return itemCostStatuses;  
    }
    public PageReference cancel() { return (retURL != null && retURL != '') ? (new PageReference('/' + retURL)) : (new PageReference('/' + Item_Cost__c.sObjectType.getDescribe().getKeyPrefix())); }
}