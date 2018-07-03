public with sharing class WOPrintPageExt {
    public Work_Order__c wo { get; private set; }
    public List<SKID__c> skids { get; private set; } { skids = new List<SKID__c>(); }
    public Boolean disable { get; private set; } { disable = false; }
    public List<String> attributesForDisplay { get; private set; } { attributesForDisplay = SkidService3.attributesForDisplay(null,null,null); }

    public WOPrintPageExt() {
        Id woId,opId;
        Operation_Tracking__c op;
        Boolean lastOp = false;
        Decimal maxOp;
        List<WorkOrderWrapper> mWrappers = new List<WorkOrderWrapper>();

        try {
            woId = (Id)ApexPages.currentPage().getParameters().get('wo');
            wo = WorkOrderService.getWorkOrders(new Set<Id>{woId},null,new Set<String>{'Assembly_Item_Specification__r.Name'},new Set<String>{'Operation_Trackings__r'})[0];
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.Invalid_work_order_Id + ': ' + woId));
            disable = true;
            return;
        }

        for (Operation_Tracking__c ot:wo.Operation_Trackings__r) {
            if (maxOp == null || ot.Sequence__c > maxOp) {
                maxOp = ot.Sequence__c;
            }
        }

        try {
            opId = (Id)ApexPages.currentPage().getParameters().get('op');

            SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
            opQuery.addAllCustomFields();
            opQuery.setWhereClause('Id = :opId');
            op = (Operation_Tracking__c)Database.query(opQuery.getQuery())[0];
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Invalid operation tracking Id: ' + opId));
            disable = true;
            return;
        }

        if (op.Sequence__c == maxOp) {
            lastOp = true;
        }

        String whereClause = ' AND (Operation_Tracking__c = \'' + opId + '\' ';
        if (lastOp) {
            whereClause += ' OR Operation_Tracking__c = null) ';
        } else {
            whereClause += ') ';
        }

        try {
            List<Material_Tracking__c> materials = WorkOrderService.getMaterials(new Set<Id>{woId},null,new Set<String>{ WorkOrderService.MATERIAL_TYPE_BACKFLUSH, WorkOrderService.MATERIAL_TYPE_KIT },null,null,whereClause);
            
            Set<Id> itemIds = new Set<Id>();
            for (Material_Tracking__c mt:materials) {
                itemIds.add(mt.Item__c);
            }

            Set<Id> locationIds = new Set<Id>();
            Set<Id> skidIds = new Set<Id> ();

            List<String> sortFields = new List<String>();
            Map<String,List<Location__c>> locationsByHeader = SkidService3.locationsFromStockMovementRules(materials,'Pick',new Set<String>{'Material_Tracking__c'},null,locationIds);
            if(materials.size()>0)
            	sortFields = SkidService3.populateSortCriteria(null,materials[0].Work_Order__r.Company__c); 

            Map<String,Set<Id>> filters = new Map<String,Set<Id>>{ 'Item__c' => itemIds,'Location__c' => locationIds };
            Map<List<String>,List<SKID__c>> skidsByItemLocation = SkidService3.pullSkidsQuery(sortFields,filters,null,SkidService3.SKID_TYPE_LOCATION,50000,null);
            
            // KNDY-14414
			for ( List<Skid__c> skids: skidsByItemLocation.values()  ) {
            	for ( Skid__c sk : skids) {
            		skidIds.add(sk.id);
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
			
            for (Material_Tracking__c mt:materials) {
                List<SkidService3.SerialWrapper> serialWrapperList = new List<Skidservice3.SerialWrapper>();

                if (!locationsByHeader.containsKey(mt.Id)) {
                    throw new WOPrintPageException(mt.Name + ': ' + 'Matching stock movement rule not found');
                }
                
                for (Location__c loc:locationsByHeader.get(mt.Id)) {
                    List<String> key = new List<String>{ mt.Item__c, loc.Id };
                    
                    if (skidsByItemLocation.containsKey(key)) {
                        for (SKID__c sk:skidsByItemLocation.get(key)) {
                            serialWrapperList.add(new SkidService3.SerialWrapper(sk.clone(true,true), serialMap.containsKey(sk.Id) ? serialMap.get(sk.Id) : new List<Serial__c>() ));
                        }
                    }
                }

                mWrappers.add(new WorkOrderWrapper(wo,mt,serialWrapperList));
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            disable = true;
            return;
        }

        if (wo.Status__c == WorkOrderService.WO_STATUS_CLOSED) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.WorkOrder_already_closed));
        } else if (wo.Status__c == WorkOrderService.WO_STATUS_DRAFT) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.WorkOrder_not_released));
        } else if (wo.Status__c == WorkOrderService.WO_STATUS_COMPLETE || wo.Status__c == WorkOrderService.WO_STATUS_CANCELLED) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.WorkOrder_completed_or_cancelled));
        } else if (mWrappers.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.No_records_to_display));
        }
        if (ApexPages.hasMessages(ApexPages.Severity.FATAL)) {
            disable = true;
            return;
        }

        for (WorkOrderWrapper wow:mWrappers) {
            if (wow.serialWrapperList != null) {
                if (wow.serialWrapperList.size() == 0) {
                    SKID__c skid = new SKID__c(
                        Item__c = wow.material.Item__c,
                        Item__r = wow.material.Item__r,
                        Quantity__c = 0,
                        Quantity_Required__c = wow.material.Quantity_Required__c,
                        Quantity_Short__c = KSE.addQuantityToField(KSE.subtractDecimals(wow.material.Quantity_Required__c,wow.material.Quantity_Issued__c),wow.material.Quantity_Scrapped__c),
                        Company__c = wo.Company__c
                    );
                    if (skid.Quantity_Short__c < 0) {
                        skid.Quantity_Short__c = 0;
                    }
                    skids.add(skid);
                } else {
                    for (Integer i=0;i<wow.serialWrapperList.size();i++) {
                        SkidService3.SerialWrapper sw = wow.serialWrapperList[i];
                        SKID__c skid = sw.skid.clone(true,true);
                        if (i == 0) {
                            skid.Item__r = wow.material.Item__r;
                            skid.Quantity_Required__c = wow.material.Quantity_Required__c;
                            skid.Quantity_Short__c = KSE.addQuantityToField(KSE.subtractDecimals(wow.material.Quantity_Required__c,wow.material.Quantity_Issued__c),wow.material.Quantity_Scrapped__c);
                            if (skid.Quantity_Short__c < 0) {
                                skid.Quantity_Short__c = 0;
                            }
                        }
                        skids.add(skid);
                    }
                }
            }
        }
    }

    public class WOPrintPageException extends Exception { }
}