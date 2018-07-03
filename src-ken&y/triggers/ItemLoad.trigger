trigger ItemLoad on Item__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (DML.checkTriggerDispatch(Item__c.getSObjectType()) == true || ExceptionService.ignoreTrigger('Item__c') == true) return;

    if (Trigger.isBefore == true) {
        if (Trigger.isInsert == true || Trigger.isUpdate == true) {
        	if(Trigger.isInsert)
        		ItemService.setPackagingUOM(Trigger.new);
            ItemService.sortPackagingUOMByLevels(Trigger.new);
            if (Trigger.isUpdate == true) ItemService.allowChangeinUOM(Trigger.newMap, Trigger.oldMap);
        }
    } else {
        Map<Id, Item__c> items = Trigger.isDelete ? Trigger.oldMap : Trigger.newMap;
        Set<Id> companyIds = new Set<Id>();
        Map<Id, Company__c> companiesToUpdate = new Map<Id, Company__c>();
        for (Item__c item:items.values()) {
            if ((Trigger.isUpdate && item.Packaging_UOM__c == Trigger.oldMap.get(item.Id).Packaging_UOM__c) || (!Trigger.isDelete && companiesToUpdate.containsKey(item.Company__c)) || (Trigger.isDelete && companyIds.contains(item.Company__c))) continue;

            List<Id> packageUoms = item.Packaging_UOM__c != null ? (List<Id>)JSON.deserialize(item.Packaging_UOM__c, List<Id>.Class) : new List<Id>();
            if (!Trigger.isDelete && packageUoms.size() > 1) {
                companiesToUpdate.put(item.Company__c, new Company__c(Id = item.Company__c, Auto_Plan_Pick__c = false));
                companyIds.remove(item.Company__c);
            } else if (Trigger.isUpdate || (Trigger.isDelete && packageUoms.size() > 1)) {
                companyIds.add(item.Company__c);
            }
        }

        companiesToUpdate.putAll(CompanyService.setAutoPlanPick(companyIds, items.keySet()));

        if (companiesToUpdate.size() > 0) {
            CompanyService.allowAutoPlanPickUpdate = true;
            DML.updateAsUser(companiesToUpdate.values());
            CompanyService.allowAutoPlanPickUpdate = false;
        }
    }

    if ( Trigger.isDelete ) { 
        ItemService.allowItemDelete( Trigger.oldMap );
    } else {
        //When inserting an object with no company lookup filled in, make an attempt to locate the correct company in the system.
        //This depends on the Company_Identifier__c field filled in correctly and on this field being unique
        CompanyService.setDefaultCompany(Trigger.new, Trigger.isBefore );
    }
    
    
    if ( trigger.isBefore &&  (  trigger.isinsert || trigger.isupdate ) )  {
        // ensure that the facility can find a company if loaded using a data load  
        Relate.setLookupUsingField(Trigger.New,Trigger.isBefore,
                                            'Class__c' ,
                                            'Class__c', 
                                            'Class_Identifier__c',
                                            'Class_Unique__c' );  // actually the name or class_unique works                                    
         ItemService.VerifyItemType(trigger.new);
    }
    
    if( (trigger.isBefore && trigger.isUpdate) || (trigger.isAfter && trigger.isInsert)){
        ItemService.allowChangeInItemAttributeOnItem(trigger.newMap, trigger.oldMap);
    }
    
    ItemService.populateItemIdentifier();
}