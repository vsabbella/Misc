public with sharing class ItemSpecificationNewExt {
    private Id prevSpec;
    private Item_Specification__c spec;

    public ItemSpecificationNewExt(ApexPages.StandardController con) {
        if (con.getId() != null) {
            prevSpec = con.getId();
            spec = (Item_Specification__c)con.getRecord();
            spec.Id = null;
        } else {
            spec = (Item_Specification__c)con.getRecord();
            spec.Company__c = CompanyService.getDefaultCompanyId();
        }
    }
    
    public PageReference save() {
        Savepoint sp = Database.setSavepoint();
		Item__c itemRec;
		Id itemId;
        if (spec.Type__c == 'Template' && spec.Name == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.Item_specification_name_is_required));
            return null;
        }

        try {
        	itemId = spec.Item__c;
        	SOQLUtil soql = new SOQLUtil('Item__c', true);
            soql.addFields(new set<string>{
                'Id','Packaging_UOM__c','Stocking_UOM__c'
            });
            soql.setWhereClause('Id =: itemId');
            itemRec = Database.query(soql.getQuery());
            
            List<Id> pkgUOMIds = (List<Id>)JSON.deserialize(itemRec.Packaging_UOM__c,List<Id>.class);
            
            if(pkgUOMIds.size()==1 && (spec.Default_Work_Order_Packaging_UOM__c == null || spec.Packaging_UOM__c == null)){
            	if(spec.Default_Work_Order_Packaging_UOM__c ==null)
            		spec.Default_Work_Order_Packaging_UOM__c = itemRec.Stocking_UOM__c;
            	if(spec.Packaging_UOM__c ==null)
            		spec.Packaging_UOM__c = itemRec.Stocking_UOM__c;
            }
            else if(pkgUOMIds.size() > 1 && (spec.Default_Work_Order_Packaging_UOM__c == null || spec.Packaging_UOM__c == null)){
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.Default_WO_PkgUOM_and_Packaging_UOM_is_required));
            	return null;
            }
            DML.insertAsUser(new List<sObject>{spec}); 
            
            if (prevSpec != null) {
                SOQLUtil componentQuery = new SOQLUtil('Component__c');
                componentQuery.addAllCustomFields();
                componentQuery.setWhereClause('Assembly_Item_Specification__c = :prevSpec');
            
                SOQLUtil routingQuery = new SOQLUtil('Routing__c');
                routingQuery.addAllCustomFields();
                routingQuery.setWhereClause('Assembly_Item_Specification__c = :prevSpec');
            
                List<Component__c> componentsToInsert = new List<Component__c>();
                Map<Id,Routing__c> routingMap = new Map<Id,Routing__c>();
            
                for (Routing__c routing:Database.query(routingQuery.getQuery())) {
                    Routing__c newRouting = routing.clone(false,true);
                    newRouting.Assembly_Item_Specification_Sequence__c = null;
                    newRouting.Assembly_Item_Specification__c = spec.Id;
                    newRouting.ExtId__c = null;
                    routingMap.put(routing.Id,newRouting);
                }
            
                DML.insertAsUser(routingMap.values());
            
                for (Component__c component:Database.query(componentQuery.getQuery())) {
                    Component__c newComponent = component.clone(false,true);
                    newComponent.Assembly_Item_Specification__c = spec.Id;
                    newComponent.Primary_Key__c = null;
                    newComponent.ExtId__c = null;
                    if (component.Routing__c != null) {
                        newComponent.Routing__c = routingMap.get(component.Routing__c).Id;
                    }
                    componentsToInsert.add(newComponent);
                }
                
                DML.insertAsUser(componentsToInsert);
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
            Database.rollback(sp);
            return null;
        }

        return new PageReference('/' + spec.Id);
    }  
}