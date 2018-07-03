public with sharing class ComponentIssueBatch implements Database.Batchable<sObject>, Database.Stateful, Process.Runnable2 {
    private Process_Job__c job;
    public void runBatch(Process_Job__c job) {
        this.job = job;
        Database.executeBatch(this, 1);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<String> woStatuses = new Set<String>{ WorkOrderService.WO_STATUS_IN_PROCESS, WorkOrderService.WO_STATUS_COMPLETE, WorkOrderService.WO_STATUS_CLOSED };
        String whereClause = 'Has_Contents__c = true AND Completed__c > 0 AND Status__c IN :woStatuses ';
        if (job.Facility__c != null) whereClause += 'AND Facility__c = \'' + job.Facility__c + '\'';
        else if (job.Company__c != null) whereClause += 'AND Company__c = \'' + job.Company__c + '\'';
        return Database.getQueryLocator(WorkOrderCompleteExtV2.getWorkOrderQuery(whereClause));
    }

    public List<Notify.Message> messages = new List<Notify.Message>();
    public void execute(Database.BatchableContext bc, List<Work_Order__c> workOrders) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<String> itemAttrFields = SkidService3.getAttributeFields();

            List<WorkOrderService.CompleteWrapper> wrappers = new List<WorkOrderService.CompleteWrapper>();
            for (Work_Order__c wo:workOrders) wrappers.add(new WorkOrderService.CompleteWrapper(wo, wo.Operation_Trackings__r[0], null, null, null, null, true));

            Map<Id, List<SkidService3.SerialWrapper>> assemblyMap = WorkOrderService.getCompleteAssemblyData(wrappers);
            Map<Id, List<WorkOrderWrapper>> componentMap = WorkOrderService.getCompleteBackflushData(wrappers);
            Map<Id, List<WorkOrderWrapper>> wipMap = WorkOrderService.getCompleteWipData((new Map<Id, Work_Order__c>(workOrders)).keySet(), true);
            for (Id woId:wipMap.keySet()) {
                if (componentMap.containsKey(woId)) componentMap.get(woId).addAll(wipMap.get(woId));
                else componentMap.put(woId, wipMap.get(woId));
            }

            Map<Id, Map<Id, WorkOrderWrapper>> materials = new Map<Id, Map<Id, WorkOrderWrapper>>();
            List<Material_Tracking__c> materialList = new List<Material_Tracking__c>();
            Map<Id, Decimal> skidQtys = new Map<Id, Decimal>();
            Map<List<String>, List<SKID__c>> qtyTaken = new Map<List<String>, List<SKID__c>>();
            Map<List<String>, Decimal> allocQtys = new Map<List<String>, Decimal>();
            List<String> planAttributes = SkidService3.attributesForPutaway(null, new Set<String>{ 'license_plate_number__c' });
            List<Work_Order__c> wosToUpdate = new List<Work_Order__c>();
            for (Integer i = 0; i < wrappers.size(); i++) {
                WorkOrderService.CompleteWrapper wrapper = wrappers[i];
                Work_Order__c wo = wrapper.wo;
                Operation_Tracking__c op = wrapper.op;

                wosToUpdate.add(new Work_Order__c(Id = wo.Id, Completed__c = 0 , status__c = wo.status__c ));
                

                if (componentMap.containsKey(wo.Id) == false) {
                    wrappers.remove(i--);
                    continue;
                }

                List<SkidService3.SerialWrapper> assemblies = assemblyMap.get(op.Id);
                if (assemblies.size() == 0 || assemblies[0].skid.Quantity_Required__c == 0) throw new CustomException(wo.Name + ': No completed assemblies found.');

                wrapper.assemblyInfo = assemblies[0];
                wrapper.assemblyInfo.skid.Quantity_Used__c = 0;
                wrapper.assemblyInfo.skid.Quantity_Scrapped__c = 0;
                wrapper.assemblyInfo.skid.Input_Quantity__c = 0;
                
                List<WorkOrderWrapper> components = componentMap.get(wo.Id);
                for (Integer j = 0; j < components.size(); j++) {
                    WorkOrderWrapper component = components[j];
                    Material_Tracking__c mt = component.material;
                    Decimal yield = mt.Yield__c != null ? (mt.Yield__c / 100) : 1;

                    if (mt.Item__r.Item_Attribute__c != null && mt.Item__r.Item_Attribute__r.Serial_Number__c == true) {
                        components.remove(j--);
                        continue;
                    }

                    if (component.serialWrapperList == null || component.serialWrapperList.size() == 0) {   //This will only happen if backflush
                        if (SkidService3.trackedAttributes(itemAttrFields, null, mt.Item__r, null).size() > 1) {    //Packaging UOM is always an attribute
                            throw new CustomException(wo.Name + ': There are no components in inventory for one or more material(s)');
                        } else {
                            if (!materials.containsKey(wo.Id)) materials.put(wo.Id, new Map<Id, WorkOrderWrapper>{ mt.Id => component });
                            else materials.get(wo.Id).put(mt.Id, component);
                            materialList.add(mt);
                        }
                    } else {
                        Decimal qtyToIssue = (mt.Quantity_Per_Assembly__c * wo.Completed__c) / yield;
                        Decimal qtyToIssueWip = Math.min(qtyToIssue, mt.Quantity_Issued__c - mt.Quantity_Used__c);
                        List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
                       
                        for (SkidService3.SerialWrapper sw:component.serialWrapperList) {
                            if (sw.skid.Type__c == SkidService3.SKID_TYPE_LOCATION) {
                                qtyToIssueWip = 0;
                                if (qtyToIssue == 0) break;

                                Decimal skidQty = skidQtys.containsKey(sw.skid.Id) ? skidQtys.get(sw.skid.Id) : sw.skid.Quantity__c;
                                sw.skid.Quantity_Available__c = Math.min(sw.skid.Quantity_Available__c, skidQty);

                                Id allocId;
                                List<String> allocKey;
                                List<String> planKey;
                                Decimal allocQty;
                                if (sw.skid.Temporary_Value_Holder__c != null) {
                                    if (mt.Allocation_Required__c == true) {
                                        allocId = (Id)sw.skid.Temporary_Value_Holder__c;
                                        allocQty = skidQtys.containsKey(allocId) == true ? skidQtys.get(allocId) : sw.skid.Quantity_Allocated__c;
                                        sw.skid.Quantity_Available__c = Math.min(sw.skid.Quantity_Available__c, allocQty);
                                    } else {
                                        allocKey = (List<String>)JSON.deserialize(sw.skid.Temporary_Value_Holder__c,List<String>.Class);
                                        planKey = SkidService3.generateKey(sw.skid, planAttributes);
                                        //allocQty = allocQtys.containsKey(allocKey) == true ? allocQtys.get(allocKey) : sw.skid.Quantity_Allocated__c;
                                        
                                        Set<Id> skidsProcessed = new Set<Id>();
                                        if (qtyTaken.containsKey(allocKey)) {
                                            for (SKID__c sk:qtyTaken.get(allocKey)) {
                                                
                                                sw.skid.Total_Material__c -= sk.Quantity__c;
                                                skidsProcessed.add(sk.Id);
                                            }
                                        }
                                        
                                        if (qtyTaken.containsKey(planKey)) {
                                            for (SKID__c sk:qtyTaken.get(planKey)) {
                                                if (!skidsProcessed.contains(sk.Id)) sw.skid.Total_Material__c -= sk.Quantity__c;
                                            }
                                        }
                                        
                                        sw.skid.Quantity_Available__c = Math.min(sw.skid.Total_Material__c, sw.skid.Quantity_Available__c);
                    
                                        SKID__c sk = new SKID__c(Id = sw.skid.Id, Quantity__c = qtyToIssue);
                    
                                        if (!qtyTaken.containsKey(allocKey)) qtyTaken.put(allocKey, new List<SKID__c>());
                                        qtyTaken.get(allocKey).add(sk);
                    
                                        if (!qtyTaken.containsKey(planKey)) qtyTaken.put(planKey, new List<SKID__c>());
                                        qtyTaken.get(planKey).add(sk);
                                    }
                                    
                                }

                                sw.skid.Quantity_to_Issue__c = Math.min(sw.skid.Quantity_Available__c, qtyToIssue);

                                qtyToIssue -= sw.skid.Quantity_to_Issue__c;
                                skidQtys.put(sw.skid.Id, skidQty - sw.skid.Quantity_To_Issue__c);
                                if (allocId != null) skidQtys.put(allocId, allocQty - sw.skid.Quantity_to_Issue__c);

                                swList.add(sw);
                            } else if (sw.skid.Type__c == SkidService3.SKID_TYPE_WIP) {
                                qtyToIssue = 0;
                                if (qtyToIssueWip == 0) break;

                                sw.skid.Quantity_to_Issue__c = Math.min(sw.skid.Quantity_Available__c, qtyToIssueWip);
                                qtyToIssueWip -= qtyToIssueWip;
                                swList.add(sw);
                            }
                        }

                        if (swList.size() > 0) {
                            if (qtyToIssue > 0) swList[0].skid.Quantity_to_Issue__c += qtyToIssue;
                            component.serialWrapperList = swList;
                        } else {
                            components.remove(j--);
                        }
                    }
                }

                if (components.size() > 0) wrapper.componentInfo = components;
                else wrappers.remove(i--);
            }

            if (materialList.size() > 0) {
                Map<String, List<Location__c>> locations = SkidService3.locationsFromStockMovementRules(materialList, 'Pick', new Set<String>{ 'material_tracking__c' }, null, null);

                Set<Id> locIds = new Set<Id>();
                for (List<Location__c> locList:locations.values()) {
                    Location__c loc = locList[0];
                    if (loc.Bin_Tracked__c == true) locIds.add(loc.Id);
                }

                Map<Id, Id> bins = new Map<Id, Id>();
                if (locIds.size() > 0) {
                    SOQLUtil binQuery = new SOQLUtil('Bin__c');
                    binQuery.addFields(new Set<String>{ 'Id', 'Name', 'Location__c' });
                    binQuery.setWhereClause('Location__c IN :locIds');
                    for (Bin__c bin:Database.query(binQuery.getQuery())) {
                        if (!bins.containsKey(bin.Location__c)) bins.put(bin.Location__c, bin.Id);
                    }
                }

                for (WorkOrderService.CompleteWrapper wrapper:wrappers) {
                    Work_Order__c wo = wrapper.wo;
                    if (materials.containsKey(wo.Id) == false) continue;

                    for (Id mtId:materials.get(wo.Id).keySet()) {
                        WorkOrderWrapper component = materials.get(wo.Id).get(mtId);
                        Material_Tracking__c mt = component.material;
                        Decimal yield = mt.Yield__c != null ? (mt.Yield__c / 100) : 1;

                        if (!locations.containsKey(mt.Id)) throw new CustomException(wo.Name + ': ' + Label.Matching_stock_movement_rule_not_found);

                        component.serialWrapperList = new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(new SKID__c(
                            Company__c = wo.Company__c,
                            Type__c = SkidService3.SKID_TYPE_LOCATION,
                            Quantity_Stocking_UOM__c = 0,
                            Item__c = mt.Item__c,
                            Item__r = mt.Item__r,
                            Container_Item__c = mt.Item__c,
                            Packaging_UOM__c = mt.Item__r.Stocking_UOM__c,
                            Stocking_UOM__c = mt.Item__r.Stocking_UOM__c,
                            Facility2__c = wo.Facility__c,
                            Facility2__r = wo.Facility__r,
                            Location__c = locations.get(mt.Id)[0].Id,
                            Bin__c = bins.get(locations.get(mt.Id)[0].Id),
                            Quantity__c = 0,
                            Quantity_Allocated__c = 0,
                            Quantity_Available__c = 0,
                            Quantity_to_Issue__c = ((mt.Quantity_Per_Assembly__c * wo.Completed__c) / yield) - mt.Quantity_Issued__c,
                            Quantity_to_Scrap__c = 0
                        ), new List<Serial__c>()) };
                    }
                }
            }

            if (wrappers.size() > 0) WorkOrderService.completeV2(wrappers);
            if (wosToUpdate.size() > 0) {
                WorkOrderService.allowWorkOrderUpdate = true;
                DML.updateAsUser(wosToUpdate);
                WorkOrderService.allowWorkOrderUpdate = false;
            }
        } catch (Exception e) {
            Database.rollback(sp);
            messages.add(Notify.getErrorMessage(workOrders, e.getMessage(), ''));
        }
    }

    public void finish(Database.BatchableContext bc) {
        Notify.sendEmailBatchFinishBuildBody(messages.size(), job.Name, messages, bc);
        MasterControlProgram.finishedBatch(this);
    }
}