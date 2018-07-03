public with sharing class WOComponentAvailabiltyExt {
    private SchemaUtil util = SchemaUtil.getInstance();
    
    public Map<Id,Decimal> quantityShort { get; private set; } { quantityShort = new Map<Id,Decimal>(); }
    public String woTitle { get; private set; }

    public WOComponentAvailabiltyExt(ApexPages.StandardController con) {
        SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
        woQuery.addAllCustomFields();
        woQuery.setWhereClause('Id = \'' + con.getId() + '\'');
        woQuery.setLimit(1);
        
        SOQLUtil.ChildRelationship materialSubquery = new SOQLUtil.ChildRelationship(woQuery,'Material_Trackings__r');
        materialSubquery.addAllCustomFields();
        materialSubquery.addFields('ComponentAvailability');
        materialSubquery.setWhereClause('Type__c NOT IN (\'Repair\',\'By-product\')');
        materialSubquery.setOrderByClause('Item__r.Name');
        woQuery.addChildRelationship(materialSubquery);
    	
        Work_Order__c wo;
        try {
            wo = (Work_Order__c)Database.query(woQuery.getQuery());
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.Invalid_work_order_Id));      
            return;
        }  
        if (wo.Status__c  == WorkOrderService.WO_STATUS_DRAFT)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.WorkOrder_not_released));
        else if (wo.Status__c == WorkOrderService.WO_STATUS_COMPLETE || wo.Status__c == WorkOrderService.WO_STATUS_CANCELLED)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.WorkOrder_completed_or_cancelled));
        else if (wo.Status__c == WorkOrderService.WO_STATUS_CLOSED)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.WorkOrder_already_closed));
        else if (wo.Material_Trackings__r == null || wo.Material_Trackings__r.size() == 0)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.No_material_tracking_records_on_file));
        if (ApexPages.hasMessages(ApexPages.Severity.FATAL))
            return;
            
        Set<Id> itemIds = new Set<Id>();
        for (Material_Tracking__c material:wo.Material_Trackings__r)
            itemIds.add(material.Item__c);
        
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id','Item__c','Quantity__c','Type__c' });
        skidQuery.setWhereClause('Item__c IN :itemIds AND Location__r.Facility__c = \'' + wo.Facility__c + '\' AND Type__c IN (\'Location\',\'Allocated\') AND Location__r.Nettable__c = true');

        Map<Id,Decimal> availableQuantity = new Map<Id,Decimal>();
        for (SKID__c skid:(List<SKID__c>)Database.query(skidQuery.getQuery())) {
            if (!availableQuantity.containsKey(skid.Item__c)) 
                availableQuantity.put(skid.Item__c,0);
            if (skid.Type__c == 'Location')
                availableQuantity.put(skid.Item__c,availableQuantity.get(skid.Item__c) + skid.Quantity__c);
            else if (skid.Type__c == 'Allocated')
                availableQuantity.put(skid.Item__c,availableQuantity.get(skid.Item__c) - skid.Quantity__c);
        }
        
        Decimal maxQty = wo.Order_Quantity__c;
        for (Material_Tracking__c material:wo.Material_Trackings__r) {
            quantityShort.put(material.Id,KSE.subtractDecimals(material.Quantity_Required__c,material.Quantity_Issued__c));
            if (availableQuantity.containsKey(material.Item__c)) {
                Decimal tempQty = availableQuantity.get(material.Item__c);
                if (tempQty > quantityShort.get(material.Id)) {
                    availableQuantity.put(material.Item__c,KSE.subtractDecimals(availableQuantity.get(material.Item__c),quantityShort.get(material.Id))); 
                    quantityShort.put(material.Id,0);
                } else {
                    quantityShort.put(material.Id,KSE.subtractDecimals(quantityShort.get(material.Id),tempQty));
                    availableQuantity.remove(material.Item__c);
                }
                if (quantityShort.get(material.Id) > 0) {
                    Decimal tempMaxQty = wo.Order_Quantity__c - (quantityShort.get(material.Id) / (material.Quantity_Required__c / wo.Order_Quantity__c));
                    if (tempMaxQty < maxQty) 
                        maxQty = tempMaxQty;
                }
            }
        }
        
        woTitle = 'Order Quantity: ' + wo.Order_Quantity__c + '           Default WIP Location: ' + wo.Default_WIP_Location__r.Name +'          Maximum Build Quantity: ' + maxQty.setScale(6);
        setCon = new ApexPages.StandardSetController(wo.Material_Trackings__r);                
        setCon.setPageSize(pageSize);
        first();
    }
    
    public ApexPages.StandardSetController setCon { get; private set; }
    public Integer pageSize { get; private set; } { pagesize = 20; }
    public List<Material_Tracking__c> mList { 
        get { 
            if (setCon != null) 
                return setCon.getRecords(); 
            else 
                return null; 
        } 
    }
    public Boolean hasNext { get { return setCon.getHasNext(); } }
    public Boolean hasPrevious { get { return setCon.getHasPrevious(); } }
    public Integer pageNumber { get { return setCon.getPageNumber(); } }
    public Integer numberOfPages { get { return (Integer)((Decimal)setCon.getResultSize()).divide(pageSize,0,System.RoundingMode.UP); } }
    public void first() { setCon.first(); }
    public void last() { setCon.last(); }
    public void previous() { setCon.previous(); }
    public void next() { setCon.next(); }
}