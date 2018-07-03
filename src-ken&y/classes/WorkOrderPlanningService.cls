public with sharing class WorkOrderPlanningService {
    public static final String NO_ROUTING = 'NO ROUTING';
    public static final String NO_SUPPLIER = 'NO SUPPLIER';

    /*
     * RELEASE/CAPACITY PLANNING SECTION
     */
    public static void validateForRelease(List<Work_Order__c> workOrders) {
        if (workOrders == null || workOrders.size() == 0) return;

        for (Work_Order__c wo:workOrders) {
            if (wo.Status__c == WorkOrderService.WO_STATUS_CLOSED || wo.Status__c == WorkOrderService.WO_STATUS_CANCELLED) {
                throw new WorkOrderPlanningException(wo.Name + ': ' + Label.WorkOrder_closed_or_cancelled_or_accounted);
            } else if (!wo.Item__r.Active__c) {
                throw new WorkOrderPlanningException(wo.Name + ': ' + Label.Cannot_release_work_order_for_inactive_item);
            } else if ( wo.Item__r.Packaging_UOM__c.contains(wo.Packaging_UOM__c) == false) {
                // KNDY-19153
                throw new WorkOrderPlanningException(wo.Name + ': ' + Label.Packaging_UOM_not_configured_for_the_Item);
            }
        }
    }
    
    public static void release(Set<Id> woIds){
    	
    	release(woIds,new Map<String,Decimal>{},new Map<String,Decimal>{},new Map<String,SObject>{},new Map<String,Purchase_Order__c>{});
    }
    
    public static void release(Set<Id> woIds,Map<String,Decimal> distributeQtymap,Map<String,Decimal> qtymap,Map<String,SObject> consolidateObjmap,map<String,Purchase_Order__c>poinfomap) {
        if (woIds == null || woIds.size() == 0) return;

        List<Work_Order__c> workOrders = WorkOrderService.getWorkOrders(woIds,null,new Set<String>{ 'Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c', 'Packaging_UOM__c', 'Company__r.Manufacturing_Calendar__c','Facility__r.Default_Purchasing_Delivery_Location__c','Facility__r.Manufacturing_Calendar__c' ,'Assembly_Item_Specification__r.Packaging_UOM__r.Package_Class__r.Level__c' ,'Packaging_UOM__r.Package_Class__c','Packaging_UOM__r.Package_Class__r.Level__c'},new Set<String>{ 'Material_Trackings__r' });
        validateForRelease(workOrders);

        Set<Id> releasedWOs = new Set<Id>();
        Set<Id> assemblyIds = new Set<Id>();
        DateTime earliestStartDate;
        Set<Id> facilityIds = new Set<Id>();
        for (Work_Order__c wo:workOrders) {
            facilityIds.add(wo.Facility__c);

            if (wo.Status__c == WorkOrderService.WO_STATUS_DRAFT && wo.Assembly_Item_Specification__c != null) {
                assemblyIds.add(wo.Assembly_Item_Specification__c);
            } else if (wo.Status__c != WorkOrderService.WO_STATUS_DRAFT) {
                releasedWOs.add(wo.Id);
            }

            if (wo.Start_Date2__c != null && (earliestStartDate == null || wo.Start_Date2__c < earliestStartDate)) {
                earliestStartDate = wo.Start_Date2__c;
            }
        }

        Map<Id,List<Component__c>> componentMap = assemblyIds.size() > 0 ? getComponents(assemblyIds) : new Map<Id,List<Component__c>>();
        Map<Id,List<Routing__c>> routingMap = assemblyIds.size() > 0 ? getRoutings(assemblyIds) : new Map<Id,List<Routing__c>>();
        
        Map<Id,List<Operation_Tracking__c>> existingOps = new Map<Id,List<Operation_Tracking__c>>();
        if (releasedWOs.size() > 0) {
            SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
            opQuery.addAllCustomFields();
            opQuery.addFields(new Set<String>{ 'Work_Center__r.Manufacturing_Calendar__c','Work_Center_Resource__r.Manufacturing_Calendar__c','Work_Order__r.Facility__c','Work_Order__r.Facility__r.Manufacturing_Calendar__c','Work_Order__r.Company__c','Work_Order__r.Company__r.Manufacturing_Calendar__c' });
            opQuery.setWhereClause('Work_Order__c IN :releasedWOs');
            opQuery.setOrderByClause('Work_Order__c,Start_Date__c ASC');

            SOQLUtil.ChildRelationship polQuery = new SOQLUtil.ChildRelationship(opQuery,'Purchase_Order_Lines__r');
            polQuery.addAllCustomFields();
            polQuery.addField('Delivery_Facility__r.Facility_Identifier__c');
            polQuery.addAllCustomFields(Purchase_Order__c.sObjectType,'Purchase_Order__r');
            polQuery.setWhereClause('Status__c != \'Cancelled\'');
            opQuery.addChildRelationship(polQuery);

            SOQLUtil.ChildRelationship mtQuery = new SOQLUtil.ChildRelationship(opQuery,'Material_Trackings__r');
            mtQuery.addAllCustomFields();
            mtQuery.addFields(new Set<String>{'Supplier__r.Name','Operation_Tracking__r.Name','Operation_Tracking__r.Routing__c','Supplier__c' });
            mtQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
            mtQuery.addAllCustomFields(Item__c.sObjectType,'Item__r');
            mtQuery.addFields(new Set<String>{ 'Work_Order__r.Facility__r.Default_Purchasing_Delivery_Location__c','Supplier__r.Remit_To__c','Work_Order__r.Packaging_UOM__c' });
            opQuery.addChildRelationship(mtQuery);

            for (Operation_Tracking__c op:Database.query(opQuery.getQuery())) {
                if (!existingOps.containsKey(op.Work_Order__c)) {
                    existingOps.put(op.Work_Order__c,new List<Operation_Tracking__c>());
                }
                existingOps.get(op.Work_Order__c).add(op);
            }
        }

        Map<Id,Map<Date,Working_Day__c>> calendars = earliestStartDate != null ? getCalendars(earliestStartDate,false) : new Map<Id,Map<Date,Working_Day__c>>();
        
        Map<Id,Map<String,List<Material_Tracking__c>>> materials = new Map<Id,Map<String,List<Material_Tracking__c>>>();
        List<Material_Tracking__c> mtrackingstodelete = new List<Material_Tracking__c>();
        Map<Id,Map<String,Operation_Tracking__c>> operations = new Map<Id,Map<String,Operation_Tracking__c>>();
        Map<Id,Map<String,Purchase_Order__c>> subcontractPOs = new Map<Id,Map<String,Purchase_Order__c>>();
        Map<Id,Map<String,Map<String,Purchase_Order_Line__c>>> subcontractPOLs = new Map<Id,Map<String,Map<String,Purchase_Order_Line__c>>>();
        List<Operation_Tracking__c> otsToUpsert = new List<Operation_Tracking__c>();
        Set<Id> itemIds = new Set<Id>();
        Map<String,Purchase_Order__c> posToUpsert = new Map<String,Purchase_Order__c>();
        Set<Id> poUpsertIds = new Set<Id>();
        Map<Id,Purchase_Order_Line__c> materialPOlinemap = new Map<Id,Purchase_Order_Line__c>();
        Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>>();
        
        for (Work_Order__c wo:workOrders) {
            Map<String,List<Material_Tracking__c>> mts = new Map<String,List<Material_Tracking__c>>();
            Map<String,Operation_Tracking__c> ops = new Map<String,Operation_Tracking__c>();
            Map<String,Purchase_Order__c> purchaseOrders = new Map<String,Purchase_Order__c>();
            Map<String,Map<String,Purchase_Order_Line__c>> poLines = new Map<String,Map<String,Purchase_Order_Line__c>>();
            DateTime lastDate = wo.Start_Date2__c;
            if ( !itemPackagingUomCache.containsKey(wo.Item__c) ) {
                List<Id> lstPkgUom = (List<Id>) JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.class);
                itemPackagingUomCache.put(wo.Item__c, lstPkgUom);
            }
            Decimal cf = KSE.getConversionFactor (wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c,wo.Assembly_Item_Specification__r.Packaging_UOM__c, itemPackagingUomCache.get(wo.Item__c) );
            
            if (wo.Status__c == WorkOrderService.WO_STATUS_DRAFT) {
                if (wo.Assembly_Item_Specification__c != null) {

                    if ( !wo.Assembly_Item_Specification__r.Active__c ) {
                        throw new WorkOrderPlanningException(wo.Name + ': Item Specification is not active.');
                    }
                    
                    List<Component__c> components = new list<Component__c>();
                    
                    List<Routing__c> routings = routingMap.get(wo.Assembly_Item_Specification__c);
                    List<Component__c> componentlist = new List<Component__c>();
                    Map<Id,List<Component__c>> ospCompMap = new Map<Id,List<Component__c>>();
                    
                    if(componentMap.containsKey(wo.Assembly_Item_Specification__c)){
                        components = componentMap.get(wo.Assembly_Item_Specification__c);
                    }
                    
                    if ( components != null ) {
                        for(Component__c comp:components){
                        	String key = '';
                        	
                        	key = (String)comp.Routing__c + (String)comp.Supplier__c;
                        	if(distributeQtymap.containskey(key) && distributeQtymap.get(key) >0){
                        		componentlist.add(comp);
                        	}
                        	else if(!distributeQtymap.containskey(key)){
                        		componentlist.add(comp);
                        	}
                        	
                        }
                    }
					
                    generateMaterialOperations(mts,ops,componentlist,routings,wo,null,null);

                    if (ops.size() > 0) {
                        if (wo.Start_Date2__c == null) {
                            throw new WorkOrderPlanningException(wo.Name + ': ' + Label.Please_provide_a_start_date);
                        }

                        List<Operation_Tracking__c> opList = sortOperations(ops.values(),wo);
                        for (Operation_Tracking__c op:opList) {
                            Id calendarId = getCalendarId(op);
                            Map<Date,Working_Day__c> calendar = calendars.get(calendarId);

                            if (calendar == null) {
                                throw new WorkOrderPlanningException(wo.Name + ': Cannot find manufacturing calendar');
                            }

                            op.Start_Date__c = lastDate;
                            lastDate = setOperationStartAndEnd(op,calendar,calculateMsecsToConsume(op,wo)).get(wo.Id);
                            otsToUpsert.add(op);
                        }
                        
                        opList[0].Quantity_Available__c = wo.Order_Quantity__c;
                        wo.Start_Date2__c = opList[0].Start_Date__c;
                        wo.Earliest_Completion_Date2__c = opList[opList.size() - 1].End_Date__c;
                        if(wo.Start_Date2__c > wo.Need_Date2__c){
                            throw new WorkOrderPlanningException('('+wo.Start_Date2__c + ')  ' + 'Start date cannot be after need date' + ' (' + wo.Need_Date2__c + ')');
                        }
                    }

                    if (mts.size() > 0) {
                        for (String routingId:mts.keySet()) {
                            if (routingId == NO_ROUTING) {
                                continue;
                            }

                            Operation_Tracking__c op = ops.get(routingId);
                            for (Material_Tracking__c mt:mts.get(routingId)) {
                                if (mt.Item__r.Source__c != ItemService.ITEM_SOURCE_OSP) {
                                    continue;
                                }

                                if (mt.Supplier__c == null) {
                                    throw new WorkOrderPlanningException(mt.Item__r.Name + ': Supplier not found for subcontracted operation');
                                }
                                
                                //Check if existing po has been passed:
								String userKey;
								userKey = (String)routingId+(String)mt.Supplier__c;
								
								Purchase_Order__c po;
								if(poinfomap.containskey(userKey)){
									po = poinfomap.get(userKey);
								}
								String pKey;
								
								if(consolidateObjmap!=null && consolidateObjmap.containskey(userKey)){//Consolidate and Save
									if(po!=null)
										pKey = (String)po.Id+(String)mt.Supplier__c;
									else
										pKey = null+(String)mt.Supplier__c;
										
								}
								else{//Only Save
									if(po!=null)
										pKey = (String)po.Id+(String)routingId+(String)mt.Supplier__c;
									else
										pKey = null+(String)routingId+(String)mt.Supplier__c;
										
									
								}
									
								if(poinfomap.containskey(userKey)){
									purchaseOrders.put(pkey,po);
								}
								else{
									po = purchaseOrders.get(pKey);
								}
								
                                if (po == null) {
                                    po = generateSubcontractPO(mt,op);
                                    
                                    purchaseOrders.put(pKey,po);
                                    if(po.Id != null && !poUpsertIds.contains(po.Id)){
                                    	posToUpsert.put('' + wo.Id + pKey,po);
                                    	poUpsertIds.add(po.Id);
                                    }
                                    else if(po.Id==null){
                                    	posToUpsert.put('' + wo.Id + pKey,po);
                                    }
                                    
                                    
                                }
                                String key;
								key = routingId + String.valueof(mt.Supplier__c);

                                if (!poLines.containsKey(pKey)) {
                                    poLines.put(pKey,new Map<String,Purchase_Order_Line__c>());
                                }
								
                                Purchase_Order_Line__c pol = generateSubcontractPOL(mt,op);
                                
                                if(distributeQtymap.containskey(key) && (Decimal)distributeQtymap.get(key) >0){
                                	pol.Order_Quantity__c = (distributeQtymap.get(key) / cf).setscale(6,System.RoundingMode.HALF_UP);
                                }
                                pol.Line__c = poLines.get(pKey).size() + 1;

                                poLines.get(pKey).put(routingId,pol);
                               
								itemIds.add(mt.Item__c);
                            }
                        }
                    }
                }
                
                if (wo.Type__c == WorkOrderService.WO_TYPE_REPAIR) {
                    Material_Tracking__c material = new Material_Tracking__c(
                        Item__c = wo.Item__c,
                        Component_Sequence__c = 0,
                        Quantity_Per_Assembly__c = 1,
                        Quantity_Required__c = wo.Order_Quantity__c,
                        Quantity_Issued__c = 0,
                        Quantity_Used__c = 0,
                        Quantity_Scrapped__c = 0,
                        Type__c = WorkOrderService.MATERIAL_TYPE_REPAIR,
                        Work_Order__c = wo.Id,
                        Required_Date__c = wo.Start_Date2__c
                    );
                    if (!mts.containsKey(NO_ROUTING)) {
                        mts.put(NO_ROUTING,new List<Material_Tracking__c>());
                    }
                    mts.get(NO_ROUTING).add(material);
                }
            
                if (ops.size() == 0) {
                    otsToUpsert.add(new Operation_Tracking__c(
                        Hours_Consumed__c = 0,
                        Description__c = 'Work Order Completion',
                        End_Date__c = wo.Need_Date2__c,
                        Quantity_Available__c = wo.Order_Quantity__c,
                        Quantity_Completed__c = 0,
                        Quantity_Scrapped__c = 0,
                        Resource_Quantity__c = 0,
                        Sequence__c = 0,
                        Standard_Hours__c = 0,
                        Start_Date__c = wo.Start_Date2__c,
                        Work_Order__c = wo.Id
                    ));
                }
                
                operations.put(wo.Id,ops);
            
                wo.Status__c = WorkOrderService.WO_STATUS_RELEASED;
                wo.Release_Date__c = System.now();
            } else {
                mts.put(NO_ROUTING,new List<Material_Tracking__c>());
                
                Set<Id> operationIds = new Set<Id>();
                
                for(Operation_Tracking__c opObj:existingOps.get(wo.Id)){
                	operationIds.add(opObj.Id);
                }
                Decimal orderQuantity = getWorkOrderQuantity(wo, itemPackagingUomCache);
                Decimal assemblyToWOConversion = KSE.getConversionFactor (wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c,wo.Assembly_Item_Specification__r.Packaging_UOM__c, itemPackagingUomCache.get(wo.Item__c));
                Set<Id> materialsToBeDeleted = new Set<Id>();
                for (Material_Tracking__c mt:wo.Material_Trackings__r) {
                    String key = '';
                   
                    if(existingOps.containskey(wo.Id) && operationIds.contains(mt.Operation_Tracking__c)){	
                    	key = String.valueof(mt.Operation_Tracking__c) + String.valueof(mt.Supplier__c);
                    }

                    if(distributeQtymap.containskey(key) && distributeQtymap.get(key) >0){
                    	mt.Quantity_Required__c = distributeQtymap.get(key);
                    	if(qtymap.containskey((String)mt.Item__c+(String)mt.Operation_Tracking__c)){
                    		mt.Quantity_Per_Assembly__c = qtymap.get((String)mt.Item__c+(String)mt.Operation_Tracking__c)/wo.Order_Quantity__c;
                    	}
                    }
                    else if(distributeQtymap.containskey(key) && distributeQtymap.get(key) == 0){
            			//block the release
            			if(mt.Quantity_Issued__c >0){
            				throw new WorkOrderPlanningException('You must undo the activity against '+mt.Name +' before you re-release this work order so the system can delete the material tracking.'); 
            			}
            			else if(mt.Quantity_Issued__c == 0 || mt.Quantity_Issued__c == null){
            				//Material Tracking needs to be removed if there is not any quantity issue against it.
            				mtrackingstodelete.add(mt);
            				materialsToBeDeleted.add(mt.Id);
            			}
            		}
                    else{
                        // orderQuantity is already in terms of wo relative to item spec
                    	mt.Quantity_Required__c = orderQuantity != null
                                                    ? ( mt.Quantity_Per_Assembly__c * (orderQuantity /assemblyToWOConversion) )
                                                    : mt.Quantity_Per_Assembly__c * wo.Order_Quantity__c;
                    }
                    
                    if (mt.Yield__c != null) {
                        mt.Quantity_Required__c /= (mt.Yield__c / 100);
                    }

                    mt.Quantity_Per_Assembly__c = mt.Quantity_Per_Assembly__c.setScale(6, System.RoundingMode.HALF_UP);
                    mt.Quantity_Required__c = mt.Quantity_Required__c.setScale(6, System.RoundingMode.HALF_UP);
                    
                    mts.get(NO_ROUTING).add(mt);
                }
                
                if (existingOps.containsKey(wo.Id)) {
                    List<Operation_Tracking__c> opTrackings = existingOps.get(wo.Id);
                    Map<String,Decimal> maxLine = new Map<String,Decimal>();
                    Map<Id,List<Purchase_Order_Line__c>> opPOLinemap = new Map<Id,List<Purchase_Order_Line__c>>();
                    Map<Id,Purchase_Order_Line__c> mtPOLinemap = new Map<Id,Purchase_Order_Line__c>();
                    
                    for (Operation_Tracking__c op:opTrackings) {
                    	
                		for (Purchase_Order_Line__c pol:op.Purchase_Order_Lines__r) {
                			String userKey = String.valueof(op.Id) + String.valueof(pol.Supplier__c);
                			if(!purchaseOrders.containskey(userKey)){
                				if(pol.Status__c == 'Closed'){
									if(!poinfomap.containskey(userKey) ){
										purchaseOrders.put(null+(String)op.Id+(String)pol.Supplier__c,pol.Purchase_Order__r);
									}
									else if(poinfomap.containskey(userKey)){
									    purchaseOrders.put((String)pol.Purchase_Order__c+(String)op.Id+(String)pol.Supplier__c,pol.Purchase_Order__r);
									}
                				}
                				else
                					purchaseOrders.put((String)pol.Purchase_Order__c+(String)op.Id+(String)pol.Supplier__c,pol.Purchase_Order__r);
                			}
                			
                			if(!mtPOLinemap.containskey(pol.Material_Tracking__c)){
	                			opPOLinemap.put(pol.Supplier__c,op.Purchase_Order_Lines__r);
	                			mtPOLinemap.put(pol.Material_Tracking__c,pol);
	                		}
                		}
                    }
                    
                    for(Operation_Tracking__c op:opTrackings){
                    	for (Material_Tracking__c material:op.Material_Trackings__r){
                    		
                    		if (opPOLinemap.containskey(material.Supplier__c)) {
	                            
		                            for (Purchase_Order_Line__c pol:opPOLinemap.get(material.Supplier__c)) {
		                            	
		                               	if (pol.Purchase_Order__r.Status__c == PurchaseOrderService.PO_STATUS_OPEN) {
		                                   
		                                    if (!maxLine.containsKey((String)pol.Purchase_Order__c)) {
		                                        maxLine.put((String)pol.Purchase_Order__c,pol.Purchase_Order__r.Total_Number_Of_Lines__c);
		                                    }
		                                }
		                            }
                             }   
                    	}
                    }
                    
                    for (Operation_Tracking__c op:opTrackings) {
                        if (op.Work_Center_Resource__c != null) {
                            Id calendarId = getCalendarId(op);
                            Map<Date,Working_Day__c> calendar = calendars.get(calendarId);

                            if (calendar == null) {
                                throw new WorkOrderPlanningException(op.Name + ': Cannot find manufacturing calendar'); 
                            }

                            op.Start_Date__c = lastDate;
                            lastDate = setOperationStartAndEnd(op,calendar,calculateMsecsToConsume(op,wo)).get(wo.Id);
                        }
                        
                      
                        //Loop MTS and see if the pO exist update the PO or create one
                      
                        Material_Tracking__c mt;
                        
                        for (Material_Tracking__c material:op.Material_Trackings__r) {
                             	String userkey;
								userkey = String.valueof(op.Id) + String.valueof(material.Supplier__c);
								Purchase_Order__c po;
								
								
                                if(poinfomap.containskey(userKey)){
									po = poinfomap.get(userKey);
								}
								String pKey;
								
								if(consolidateObjmap!=null && consolidateObjmap.containskey(userKey)){//Consolidate and Save
									if(po!=null)
										pKey = (String)po.Id+(String)material.Supplier__c;
									else
										pKey = null+(String)material.Supplier__c;
										
								}
								else{//Only Save
									
									if(po!=null)
										pKey = (String)po.Id+String.valueof(op.Id)+(String)material.Supplier__c;
									else
										pKey = null+String.valueof(op.Id)+(String)material.Supplier__c;
										
								}
								
	                            if(mtPOLinemap.containskey(material.Id) && (!poinfomap.containskey(userKey) || (poinfomap.containskey(userKey) && mtPOLinemap.get(material.Id).Purchase_Order__c == poinfomap.get(userKey).Id))){
	                            	
	                            	Boolean hasClosedPOL = false;
	                            	Purchase_Order_Line__c curPOL;
	                            	Purchase_Order_Line__c closedPOL;
	                            	Id curPO;
	                            	Purchase_Order_Line__c mtpoline = mtPOLinemap.get(material.Id);
	                            	
	                            	if (mtpoline.Status__c == PurchaseOrderService.PO_STATUS_CLOSED) {
	                                    hasClosedPOL = true;
	                                    closedPOL = mtpoline;
	                                } else if (mtpoline.Status__c == PurchaseOrderService.PO_STATUS_OPEN) {
	                                    curPOL = mtpoline;
	                            	}else if (mtpoline.Purchase_Order__r.Status__c == PurchaseOrderService.PO_STATUS_OPEN) {
	                                    curPO = mtpoline.Purchase_Order__c;
	                                 }
	                                    
	                            	if (!hasClosedPOL) {
		                            	if (curPOL != null) {
		                                	
		                                	if (!poLines.containsKey(NO_SUPPLIER)) {
		                                        poLines.put(NO_SUPPLIER,new Map<String,Purchase_Order_Line__c>());
		                                    }
		                                	
											if(materialsToBeDeleted.contains(curPOL.Material_Tracking__c)){
												curPOL.Status__c = 'Cancelled';
												poLines.get(NO_SUPPLIER).put((String)curPOL.Id,curPOL);
											}
											else{
												
												if (!posToUpsert.containsKey((String)curPOL.Purchase_Order__c)) {
													if(curPOL.Purchase_Order__c !=null && !poUpsertIds.contains(curPOL.Purchase_Order__c)){
														posToUpsert.put((String)curPOL.Purchase_Order__c,new Purchase_Order__c(Id = curPOL.Purchase_Order__c, Delivery_Facility__c = wo.Facility__c, Delivery_Location__c = wo.Facility__r.Default_Purchasing_Delivery_Location__c));
			                                        	poUpsertIds.add(curPOL.Purchase_Order__c);
													}
													else if(curPOL.Purchase_Order__c ==null){
														posToUpsert.put((String)curPOL.Purchase_Order__c,new Purchase_Order__c(Id = curPOL.Purchase_Order__c, Delivery_Facility__c = wo.Facility__c, Delivery_Location__c = wo.Facility__r.Default_Purchasing_Delivery_Location__c));
													}
			                                        
			                                    }
			
			                                    Purchase_Order_Line__c oldpol = new Purchase_Order_Line__c(Id = curPOL.Id, Delivery_Facility__c = wo.Facility__c, Delivery_Location__c = wo.Facility__r.Default_Purchasing_Delivery_Location__c, Order_Quantity__c = curPOL.Order_Quantity__c, Quantity_Received__c = curPOL.Quantity_Received__c);//, Order_Quantity__c = wo.Order_Quantity__c
												String key;
												oldpol.Operation_Tracking__c = curPOL.Operation_Tracking__c;
												oldpol.Material_Tracking__c = curPOL.Material_Tracking__c;
												oldpol.Supplier__c = curPOL.Supplier__c;
												key = String.valueof(op.Id) + String.valueof(material.Supplier__c);
												
												
												if(oldpol.Quantity_Received__c == null){
													oldpol.Quantity_Received__c = 0;
												}
												
												if(distributeQtymap.containskey(key) && (Decimal)distributeQtymap.get(key) < oldpol.Quantity_Received__c){
													
													throw new WorkOrderPlanningException('The quantity on a Subcontract Purchase order cannot be below quantity received: ' + material.Operation_Tracking__r.Name +' Supplier: '+material.Supplier__r.Name);
												}
												else if(distributeQtymap.containskey(key) && (Decimal)distributeQtymap.get(key) >= oldpol.Quantity_Received__c && !KSE.isEqualDecimal(distributeQtymap.get(key), oldpol.Order_Quantity__c)){
													
													oldpol.Order_Quantity__c = ((Decimal)distributeQtymap.get(key)/cf).setscale(6,System.RoundingMode.HALF_UP);
													poLines.get(NO_SUPPLIER).put((String)curPOL.Id,oldpol);
												}
												
											}
											
		                                    itemIds.add(curPOL.Item__c);
		                                    
		                                }
		                                 else {/*Commenting block since cancelled PO lines are not queried..
		                                    	
		                                        if (material.Item__r.Source__c == ItemService.ITEM_SOURCE_OSP) {
		                                            if(!itemIds.contains(material.Item__c))
		                                            	itemIds.add(material.Item__c);
		                                        }
			                                    
			                                    Purchase_Order_Line__c pol = generateSubcontractPOL(mt,op);
												
			                                    if (curPO != null) {
			                                        if (!poLines.containsKey(pKey)) {
			                                            poLines.put(pKey,new Map<String,Purchase_Order_Line__c>());
			                                        }
			
			                                        pol.Purchase_Order__c = curPO;
			                                        pol.Line__c = maxLine.get((String)curPO) + 1;
			                                        poLines.get(pKey).put((String)op.Id,pol);
			
			                                        maxLine.put((String)curPO,pol.Line__c);
			                                        
			                                    }
			                                    else {
	                        						
	                        						if(poinfomap.containskey(userKey)){
														purchaseOrders.put(pkey,po);
													}
													else{
														po = purchaseOrders.get(pKey);
													}
			                                        //po = purchaseOrders.get((String)material.Supplier__c);
			                                        
			                                        if (po == null) {
			                                            po = generateSubcontractPO(material,op);
			                                            purchaseOrders.put(pKey,po);
			                                           
			                                            posToUpsert.put('' + wo.Id + pKey,po);
			                                        }
													
			                                        if (!poLines.containsKey(pKey)) {//&& !materialPOlinemap.containskey((String)material.Supplier__c)
			                                            poLines.put(pKey,new Map<String,Purchase_Order_Line__c>());
			                                        }
			
			                                        pol.Line__c = poLines.get(pKey).size() + 1;
			
			                                        poLines.get(pKey).put((String)op.Id,pol);
			                                        
			                                        
		                       					}
			                                   */
	                                      }
	                           		 }
	                           		 else{ 
	                           		 	//Create new PO for remaining Order Qty if line is closed
	                           		 	
	                           		 		
	                           		 		String key;
											key = String.valueof(op.Id) + String.valueof(material.Supplier__c);
	                           		 		
	                           		 		if(distributeQtymap.containskey(key) && (Decimal)distributeQtymap.get(key) < closedPOL.Quantity_Received__c){
													
												throw new WorkOrderPlanningException('The quantity on a Subcontract Purchase order cannot be below quantity received: ' + material.Operation_Tracking__r.Name +' Supplier: '+material.Supplier__r.Name);
											}
											else{
												//Need to add new po logic in here
												
												po = purchaseOrders.get(pKey);
			                                    if (po == null || po.Status__c == 'Closed') {
				                                    po = generateSubcontractPO(material,op);
				                                    purchaseOrders.put(pKey,po);
				                                }
				
				                                if (!poLines.containsKey(pKey)) {
				                                    poLines.put(pKey,new Map<String,Purchase_Order_Line__c>());
				                                }
				
				                                Purchase_Order_Line__c pol = generateSubcontractPOL(material,op);
				                               
				                                if(distributeQtymap.containskey(key) && (Decimal)distributeQtymap.get(key) >= closedPOL.Quantity_Received__c){
				                                	pol.Order_Quantity__c = KSE.subtractDecimals(distributeQtymap.get(key)/cf,closedPOL.Quantity_Received__c);
		                       					}
		                       					else if(distributeQtymap == null || !distributeQtymap.containskey(key)){
		                       						pol.Order_Quantity__c = KSE.subtractDecimals(material.Quantity_Required__c,closedPOL.Quantity_Received__c);
		                       					}
		                       						
		                       					if(pol.Order_Quantity__c > 0){
		                       						poLines.get(pKey).put((String)op.Id,pol);
		                       						if(po.Id !=null && !poUpsertIds.contains(po.Id)){
				                                    	posToUpsert.put('' + wo.Id + pKey,po);
				                                    	poUpsertIds.add(po.Id);
				                                    }
				                                    else if(po.Id==null){
				                                    	posToUpsert.put('' + wo.Id + pKey,po);
				                                    }
				                                    
		                       					}
		                       					
	                                      }
	                           		 }
	                            
	                            
                        	}
                        	else if((!mtPOLinemap.containskey(material.Id) || (mtPOLinemap.containskey(material.Id) && poinfomap.containskey(userKey) && mtPOLinemap.get(material.Id).Purchase_Order__c != poinfomap.get(userKey).Id)) && material.Item__r.Source__c == ItemService.ITEM_SOURCE_OSP){
                        		    
                                    //Create new PO(If not found) and new POLine
                                    //Check if existing po has been passed:
                                    
									if(poinfomap.containskey(userKey)){
										purchaseOrders.put(pkey,po);
									}
									else{
										po = purchaseOrders.get(pKey);
									}
										
                                    if (po == null) {
	                                    po = generateSubcontractPO(material,op);
	                                    purchaseOrders.put(pKey,po);
	                                    if(po.Id !=null && !poUpsertIds.contains(po.Id)){
	                                    	posToUpsert.put('' + wo.Id + pKey,po);
	                                    	poUpsertIds.add(po.Id);
	                                    }
	                                    else if(po.Id==null){
	                                    	posToUpsert.put('' + wo.Id + pKey,po);
	                                    }
	                                    
	                                }
									
	                                if (!poLines.containsKey(pKey)) {
	                                    poLines.put(pKey,new Map<String,Purchase_Order_Line__c>());
	                                }
	
	                                Purchase_Order_Line__c pol = generateSubcontractPOL(material,op);
	                                
	                                if(distributeQtymap.containskey(userkey)){
										pol.Order_Quantity__c = ((Decimal)distributeQtymap.get(userkey)/cf).setscale(6,System.RoundingMode.HALF_UP);
									}
	                                
	                                pol.Line__c = poLines.get(pKey).size() + 1;
	
	                                poLines.get(pKey).put(op.Id,pol);
	
	                                itemIds.add(material.Item__c);
	                                           
	                       }
                        }
                        

                        
                    }

                    opTrackings[0].Quantity_Available__c = KSE.subtractDecimals(wo.Order_Quantity__c,opTrackings[0].Quantity_Completed__c);
                    if(wo.Status__c == WorkOrderService.WO_STATUS_COMPLETE && wo.Quantity_to_Complete__c > 0 ){
                        wo.Status__c = WorkOrderService.WO_STATUS_IN_PROCESS  ;
                    }
                    otsToUpsert.addAll(opTrackings);
                    wo.Start_Date2__c = opTrackings[0].Start_Date__c;
                    wo.Earliest_Completion_Date2__c = opTrackings[opTrackings.size() - 1].End_Date__c;
                }
            }
            
            materials.put(wo.Id,mts);
            subcontractPOs.put(wo.Id,purchaseOrders);
            subcontractPOLs.put(wo.Id,poLines);
        }
        
        if (otsToUpsert.size() > 0) { DML.checkUpsertAsUser(otsToUpsert); upsert otsToUpsert; }
        if (posToUpsert.size() > 0) { DML.checkUpsertAsUser(posToUpsert.values()); upsert posToUpsert.values(); }

        List<Material_Tracking__c> mtsToUpsert = new List<Material_Tracking__c>();
        List<Purchase_Order_Line__c> polsToUpsert = new List<Purchase_Order_Line__c>();
        for (Work_Order__c wo:workOrders) {
            Map<String,Operation_Tracking__c> ops = operations.get(wo.Id);
            Map<String,List<Material_Tracking__c>> mts = materials.get(wo.Id);
            Map<String,Purchase_Order__c> purchaseOrders = subcontractPOs.get(wo.Id);
            Map<String,Map<String,Purchase_Order_Line__c>> poLines = subcontractPOLs.get(wo.Id);
            if (mts != null) {
                for (String routingId:mts.keySet()) {
                    if (routingId == NO_ROUTING) {
                        mtsToUpsert.addAll(mts.get(routingId));
                    } else {
                        Operation_Tracking__c op = ops.get(routingId);
                        for (Material_Tracking__c mt:mts.get(routingId)) {
                            mt.Operation_Tracking__c = op.Id;
                            mt.Required_Date__c = op.Start_Date__c;
                            String key = '';
                            
                            key = String.valueof(op.Routing__c) + String.valueof(mt.Supplier__c);
                            
                            if(distributeQtymap.containskey(key)){
                            	mt.Quantity_Required__c = distributeQtymap.get(key);
                            	if(mt.Quantity_Required__c >0){
                            		if(qtymap.containskey((String)mt.Item__c+(String)routingId)){
			                    		mt.Quantity_Per_Assembly__c = qtymap.get((String)mt.Item__c+(String)routingId)/wo.Order_Quantity__c;
			                    	}
                            	}

                                mt.Quantity_Per_Assembly__c = mt.Quantity_Per_Assembly__c.setScale(6, System.RoundingMode.HALF_UP);
                                mt.Quantity_Required__c = mt.Quantity_Required__c.setScale(6, System.RoundingMode.HALF_UP);
                            }
                            mtsToUpsert.add(mt);
                        }
                    }
                }
            }

            if (poLines != null) {
                for (String supplierId:poLines.keySet()) {
                    for (String routingId:poLines.get(supplierId).keySet()) {
                        Purchase_Order_Line__c pol = poLines.get(supplierId).get(routingId);
                        pol.Unit_Price__c = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,pol.Company__c,pol.Delivery_Facility__c,System.now(),pol.Item__c);
                        if (supplierId != NO_SUPPLIER || (purchaseOrders.get(supplierId) !=null && purchaseOrders.get(supplierId).Id !=null)) {
                        	pol.Purchase_Order__c = purchaseOrders.get(supplierId).Id;
                        }
                        if (ops != null && ops.containsKey(routingId)) pol.Operation_Tracking__c = ops.get(routingId).Id;
                        polsToUpsert.add(pol);
                    }
                }
            }
        }

        if (mtsToUpsert.size() > 0) { DML.checkUpsertAsUser(mtsToUpsert); upsert mtsToUpsert; }
        //Updating Material Tracking on PO Lines
        Map<String,Material_Tracking__c> materialsmap = new Map<String,Material_Tracking__c>();
        for(Material_Tracking__c mt:mtsToUpsert){
        	String key='';
        	
        	if(mt.Supplier__c != null || mt.Supplier__c != ''){
        		key = (String)mt.Operation_Tracking__c + (String)mt.Supplier__c;
        		materialsmap.put(key,mt);
        		
        	}
        	
        }
        for(Purchase_Order_Line__c poline:polsToUpsert){
        	String strkey = (String)poline.Operation_Tracking__c + (String)poline.Supplier__c;
        	if(materialsmap.containskey(strkey) && poline.Material_Tracking__c == null){
        		poline.Material_Tracking__c = materialsmap.get(strkey).Id;
        	}
        }
        if (polsToUpsert.size() > 0) { DML.checkUpsertAsUser(polsToUpsert); upsert polsToUpsert; }
        
        WorkOrderService.allowWorkOrderUpdate = true;
        DML.updateAsUser(workOrders);
        
        if (mtrackingstodelete.size() > 0) 
        	DML.deleteAsUser(mtrackingstodelete);
        	
        
        WorkOrderService.allowWorkOrderUpdate = false;
    }
    
    public static void generateMaterialOperations(Map<String,List<Material_Tracking__c>> materials,Map<String,Operation_Tracking__c> operations,List<Component__c> components,List<Routing__c> routings,Work_Order__c wo,Component__c phantom, Routing__c pRouting) {
        Set<Id> phantomRts = new Set<Id>();
        Set<Id> componentRts = new Set<Id>();
        Map<Id,Component__c> phantoms = new Map<Id,Component__c>();
        Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>>();

        List<Id> lstPkgUom = (List<Id>) JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.class);
        itemPackagingUomCache.put(wo.Item__c, lstPkgUom);

        Decimal woPkgUOMLevel = 1;
        Decimal itemSpecUOMLevel = 1;
        if(wo.Packaging_UOM__r !=null && wo.Packaging_UOM__r.Package_Class__r.Level__c !=null){
            woPkgUOMLevel = wo.Packaging_UOM__r.Package_Class__r.Level__c;
        }
        if(wo.Assembly_Item_Specification__r.Packaging_UOM__r.Package_Class__r !=null && wo.Assembly_Item_Specification__r.Packaging_UOM__r.Package_Class__r.Level__c !=null){
            itemSpecUOMLevel = wo.Assembly_Item_Specification__r.Packaging_UOM__r.Package_Class__r.Level__c;
        }

        Decimal cf = KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Packaging_UOM__c, wo.Assembly_Item_Specification__r.Packaging_UOM__c, itemPackagingUomCache.get(wo.Item__c));
        Decimal cf1;
        if (woPkgUOMLevel < itemSpecUOMLevel) {
            cf1 = KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wo.Assembly_Item_Specification__r.Packaging_UOM__c, wo.Packaging_UOM__c, itemPackagingUomCache.get(wo.Item__c));
        } else {
            cf1 = cf;
        }

        if (components != null) {
            
            for (Component__c component:components) {
                if (component.Component_Item__r.Source__c == 'Phantom') {
                    Component__c phantomComponent = component.clone(true,true);
                    if (phantom != null) {
                        phantomComponent.Quantity_per_Assembly__c *= phantom.Quantity_per_Assembly__c;
                        phantomComponent.Routing__c = phantom.Routing__c;
                    }
                    if (component.Yield__c != null) phantomComponent.Quantity_per_Assembly__c /= (component.Yield__c / 100);
                    phantoms.put(component.Component_Item__c,phantomComponent);

                    if (component.Routing__c != null) {
                        phantomRts.add(component.Routing__c);
                    }
                } else {
                    Decimal qpa = (component.Quantity_per_Assembly__c * cf).setscale(6, System.RoundingMode.HALF_UP);
                    Decimal orderQuantity = String.isBlank(wo.Quantity_Value_Holder__c)
                                    ? ((woPkgUOMLevel < itemSpecUOMLevel) ? (wo.Order_Quantity__c /cf1) : (cf1 * wo.Order_Quantity__c) )
                                    : getWorkOrderQuantity(wo, itemPackagingUomCache);
                    Material_Tracking__c material = new Material_Tracking__c(
                        Item__c = component.Component_Item__c,
                        Item__r = component.Component_Item__r,
                        Allocate_on_Receipt__c = component.Allocate_on_Receipt__c,
                        Allocation_Required__c = component.Allocation_Required__c,
                        Component_Sequence__c = component.Component_Sequence__c,
                        Quantity_Per_Assembly__c = qpa,
                        Quantity_Required__c = (component.Quantity_per_Assembly__c * orderQuantity).setscale(6, System.RoundingMode.HALF_UP),
                        Supplier__c = component.Supplier__c,
                        Supplier__r = component.Supplier__r,
                        Type__c = component.Type__c,
                        Work_Order__c = wo.Id,
                        Work_Order__r = wo,
                        Yield__c = component.Yield__c,
                        Required_Date__c = wo.Start_Date2__c
                    );
                    if (component.Type__c == 'By-product') {
                        material.Quantity_Completed__c = 0;
                    } else {
                        material.Quantity_Allocated__c = 0;
                        material.Quantity_Issued__c = 0;
                        material.Quantity_Used__c = 0;
                        material.Quantity_Scrapped__c = 0;
                    }
                    if (phantom != null) {
                        material.Quantity_Per_Assembly__c *= phantom.Quantity_per_Assembly__c;
                        material.Quantity_Required__c *= phantom.Quantity_per_Assembly__c;
                    }
                    if (component.Yield__c != null) {
                        material.Quantity_Required__c /= (component.Yield__c / 100);
                    }
                    material.Quantity_Per_Assembly__c = material.Quantity_Per_Assembly__c.setScale(6, System.RoundingMode.HALF_UP);
                    material.Quantity_Required__c = material.Quantity_Required__c.setScale(6, System.RoundingMode.HALF_UP);

                    String routingId;
                    if (phantom == null || wo.Assembly_Item_Specification__r.Copy_Phantom_Routings__c && component.Routing__c != null ) {
                        routingId = component.Routing__c;
                    } else if(pRouting != null){
                         routingId = pRouting.Id;
                         addOperation(operations, pRouting, wo);
                         operations.get(pRouting.Id).Standard_Hours__c = pRouting.Standard_Hours__c * (phantom != null ? phantom.Quantity_per_Assembly__c : 1);  
                    }
                    if (routingId == null) routingId = NO_ROUTING;
                    if (!materials.containsKey(routingId))
                        materials.put(routingId,new List<Material_Tracking__c>());
                    materials.get(routingId).add(material);

                    if (component.Routing__c != null) {
                        componentRts.add(component.Routing__c);
                    }
                }
            }
        }

        if (routings != null && (phantom == null || wo.Assembly_Item_Specification__r.Copy_Phantom_Routings__c)) {
            for (Routing__c routing:routings) {
                if (!wo.Assembly_Item_Specification__r.Copy_Phantom_Routings__c || !phantomRts.contains(routing.Id) || componentRts.contains(routing.Id)) {
                    operations.put(routing.Id,new Operation_Tracking__c(
                        Hours_Consumed__c = 0,
                        Backflush_Resource__c = routing.Backflush_Resource__c,
                        Description__c = routing.Description__c,
                        Fixed_Hours__c = routing.Fixed_Hours__c,
                        Quantity_Available__c = 0,
                        Quantity_Completed__c = 0,
                        Quantity_Scrapped__c = 0,
                        Resource_Quantity__c = routing.Resource_Quantity__c,
                        Routing__c = routing.Id,
                        Routing__r = routing,
                        Sequence__c = routing.Resource_Sequence__c,
                        Standard_Hours__c = (woPkgUOMLevel > itemSpecUOMLevel)?routing.Standard_Hours__c * (phantom != null ? phantom.Quantity_per_Assembly__c : 1) * cf1:(routing.Standard_Hours__c * (phantom != null ? phantom.Quantity_per_Assembly__c : 1)) / cf1,
                        Work_Center__c = routing.Work_Center__c,
                        Work_Center__r = routing.Work_Center__r,
                        Work_Center_Resource__c = routing.Work_Center_Resource__c,
                        Work_Center_Resource__r = routing.Work_Center_Resource__r,
                        Work_Order__c = wo.Id,
                        Work_Order__r = wo
                    ));
                }
            }
        }
        
        if (phantoms.size() > 0) {
            Set<Id> itemIds = phantoms.keySet();
            Date woDate = wo.Start_Date2__c.date();
            
            SOQLUtil itemSpecQuery = new SOQLUtil('Item_Specification__c');
            itemSpecQuery.addAllCustomFields();
            itemSpecQuery.setOrderByClause('Start_Date2__c DESC');
            
            String whereClause = 'Item__c IN :itemIds AND Company__c = \'' + wo.Company__c + '\' AND (Facility__c = null OR Facility__c = \'' + wo.Facility__c + '\') AND Start_Date2__c <= :woDate AND Production__c = true AND ';
            if (wo.Assembly_Item_Specification__r.Type__c == 'Repair') {
                whereClause += 'Type__c != \'Template\'';
            } else {
                whereClause += 'Type__c = \'Assembly\'';
            }
            itemSpecQuery.setWhereClause(whereClause);
            
            Map<Id,Item_Specification__c> itemSpecs = new Map<Id,Item_Specification__c>();
            for (Item_Specification__c itemSpec:Database.query(itemSpecQuery.getQuery())) {
                if (!itemSpecs.containsKey(itemSpec.Item__c) || (itemSpecs.get(itemSpec.Item__c).Facility__c == null && itemSpec.Facility__c != null)) {
                    itemSpecs.put(itemSpec.Item__c,itemSpec);
                }
            }
            
            Map<Id,List<Component__c>> componentMap = getComponents((new Map<Id,Item_Specification__c>(itemSpecs.values())).keySet());
            Map<Id,List<Routing__c>> routingMap = getRoutings((new Map<Id,Item_Specification__c>(itemSpecs.values())).keySet());
            
            for (Id itemId:phantoms.keySet()) {
                Component__c phantomComponent = phantoms.get(itemId);
                Routing__c phantomRouting = phantomComponent.Routing__r;
                if (!itemSpecs.containsKey(itemId)) {
                    throw new WorkOrderPlanningException(Label.No_valid_phantom_item_spec + ' ' + phantomComponent.Component_Item__r.Name);
                }
                
                List<Component__c> phantomComponents = componentMap.get(itemSpecs.get(itemId).Id);
                List<Routing__c> phantomRoutings = routingMap.get(itemSpecs.get(itemId).Id);
                
                generateMaterialOperations(materials,operations,phantomComponents,phantomRoutings,wo,phantomComponent,phantomRouting);
            }
        }
    }

     public static void addOperation(map<String, Operation_Tracking__c> operations, Routing__c routing, Work_Order__c wo){
         
         operations.put(routing.Id,new Operation_Tracking__c(
             Hours_Consumed__c = 0,
             Backflush_Resource__c = routing.Backflush_Resource__c,
             Description__c = routing.Description__c,
             Fixed_Hours__c = routing.Fixed_Hours__c,
             Quantity_Available__c = 0,
             Quantity_Completed__c = 0,
             Quantity_Scrapped__c = 0,
             Resource_Quantity__c = routing.Resource_Quantity__c,
             Routing__c = routing.Id,
             Routing__r = routing,
             Sequence__c = routing.Resource_Sequence__c,
             Standard_Hours__c = routing.Standard_Hours__c,
             Work_Center__c = routing.Work_Center__c,
             Work_Center__r = routing.Work_Center__r,
             Work_Center_Resource__c = routing.Work_Center_Resource__c,
             Work_Center_Resource__r = routing.Work_Center_Resource__r,
             Work_Order__c = wo.Id,
             Work_Order__r = wo
         ));
     }
    private static Purchase_Order__c generateSubcontractPO(Material_Tracking__c mt,Operation_Tracking__c op) {
        return new Purchase_Order__c(
            Company__c = mt.Work_Order__r.Company__c,
            Type__c = PurchaseOrderService.PO_TYPE_SUBCONTRACT,
            Status__c = PurchaseOrderService.PO_STATUS_OPEN,
            Supplier__c = mt.Supplier__c,
            Remit_To_Supplier__c = mt.Supplier__r.Remit_To__c,
            Currency__c = mt.Work_Order__r.Currency__c,
            Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_PENDING,
            Need_Date__c = op.Start_Date__c.date(),
            Delivery_Facility__c = mt.Work_Order__r.Facility__c,
            Delivery_Location__c = mt.Work_Order__r.Facility__r.Default_Purchasing_Delivery_Location__c
        );
    }

    private static Purchase_Order_Line__c generateSubcontractPOL(Material_Tracking__c mt,Operation_Tracking__c op) {
        return new Purchase_Order_Line__c(
            Company__c = mt.Work_Order__r.Company__c,
            Supplier__c = mt.Supplier__c,
            Item__c = mt.Item__c,
            Description__c = mt.Item__r.Description__c,
            Item_Specification__c = mt.Work_Order__r.Assembly_Item_Specification__c,
            Delivery_Facility__c = mt.Work_Order__r.Facility__c,
            Delivery_Location__c = mt.Work_Order__r.Facility__r.Default_Purchasing_Delivery_Location__c,
            Need_Date__c = op.Start_Date__c.date(),
            Purchase_UOM__c = mt.Work_Order__r.Packaging_UOM__c,
            Order_Quantity__c = mt.Work_Order__r.Order_Quantity__c,
            Operation_Tracking__c = op.Id,
            Material_Tracking__c = mt.Id,
            Work_Order__c = op.Work_Order__c
        );
    }
    
    public static void levelLoad(List<Operation_Tracking__c> operations,DateTime startDate) {
        Map<Id,DateTime> lastDates = new Map<Id,DateTime>();
        
        Map<Id,Map<Date,Working_Day__c>> calendars = getCalendars(startDate,false);
        
        for (Operation_Tracking__c op:operations) {
            Id calendarId = getCalendarId(op);
            Map<Date,Working_Day__c> calendar = calendars.get(calendarId);

            if (calendar == null) {
                throw new WorkOrderPlanningException(op.Name + ': Cannot find manufacturing calendar');
            }

            DateTime earliestDate;
            if (lastDates.containsKey(op.Work_Order__c) && lastDates.containsKey(op.Work_Center_Resource__c)) {
                op.Start_Date__c = lastDates.get(op.Work_Order__c) > lastDates.get(op.Work_Center_Resource__c) ? lastDates.get(op.Work_Order__c) : lastDates.get(op.Work_Center_Resource__c);
            } else if (lastDates.containsKey(op.Work_Order__c)) {
                op.Start_Date__c = lastDates.get(op.Work_Order__c);
            } else if (lastDates.containsKey(op.Work_Center_Resource__c)) {
                op.Start_Date__c = lastDates.get(op.Work_Center_Resource__c);
            } else {
                op.Start_Date__c = startDate;
            }
                
            lastDates.putAll(setOperationStartAndEnd(op,calendar,calculateMsecsToConsume(op,op.Work_Order__r)));
        }
    }

    public static Map<Id,DateTime> setOperationStartAndEnd(Operation_Tracking__c op,Map<Date,Working_Day__c> days,Long msecsToConsume) {
        List<Date> sortedDates = new List<Date>(days.keySet()); sortedDates.sort();
        
        DateTime earliestDate = op.Start_Date__c;
        op.Start_Date__c = null;
        
        for (Date d:sortedDates) {
            Working_Day__c day = days.get(d);
            DateTime startDT = day.Start__c;
            Long msecs = day.End__c.getTime() - day.Start__c.getTime();
            
            if (day.End__c < earliestDate) {
                continue;
            }
            
            if (op.Start_Date__c == null) {
                if (day.Start__c >= earliestDate) {
                    op.Start_Date__c = day.Start__c;
                } else {
                    op.Start_Date__c = earliestDate;
                    startDT = earliestDate;
                    msecs -= earliestDate.getTime() - day.Start__c.getTime();
                }
            }
            
            if (msecsToConsume > msecs) {
                msecsToConsume -= msecs;
            } else {
                op.End_Date__c = DateTime.newInstance(startDT.getTime() + msecsToConsume);
                return new Map<Id,DateTime>{ op.Work_Order__c => op.End_Date__c, op.Work_Center_Resource__c => op.End_Date__c };
            }
        }
        
        throw new WorkOrderPlanningException('Please add days to the manufacturing calendar');
        
        return null;
    }
    
    public static Map<Id,DateTime> setOperationStartAndEndBackwards(Operation_Tracking__c op,Map<Date,Working_Day__c> days,Long msecsToConsume) {
        List<Date> sortedDates = new List<Date>(days.keySet()); sortedDates.sort();
        
        DateTime earliestDate = op.End_Date__c;
        op.End_Date__c = null;
        
        for (Integer i=sortedDates.size()-1;i>=0;i--) {
            Working_Day__c day = days.get(sortedDates[i]);
            DateTime endDT = day.End__c;
            Long msecs = day.End__c.getTime() - day.Start__c.getTime();
            
            if (day.Start__c > earliestDate) {
                continue;
            }
            
            if (op.End_Date__c == null) {
                if (day.End__c <= earliestDate) {
                    op.End_Date__c = day.End__c;
                } else {
                    op.End_Date__c = earliestDate;
                    endDT = earliestDate;
                    msecs -= day.End__c.getTime() - earliestDate.getTime();
                }
            }
            
            if (msecsToConsume > msecs) {
                msecsToConsume -= msecs;
            } else {
                op.Start_Date__c = DateTime.newInstance(endDT.getTime() - msecsToConsume);
                return new Map<Id,DateTime>{ op.Work_Order__c => op.Start_Date__c, op.Work_Center_Resource__c => op.Start_Date__c };
            }
        }
        
        throw new WorkOrderPlanningException('Please add days to the manufacturing calendar');
        
        return null;
    }
    
    public static Map<Id,List<Component__c>> getComponents(Set<Id> assemblyIds) {
        SOQLUtil componentQuery = new SOQLUtil('Component__c');
        componentQuery.addAllCustomFields();
        componentQuery.addFields(new set<String>{'Routing__r.Name','Routing__r.Backflush_Resource__c','Routing__r.Description__c',
         'Routing__r.Fixed_Hours__c','Routing__r.Resource_Quantity__c','Routing__r.Resource_Sequence__c','Routing__r.Standard_Hours__c',
         'Routing__r.Work_Center__c','Routing__r.Work_Center_Resource__c'});
        componentQuery.addAllCustomFields(Item__c.sObjectType,'Component_Item__r');
        componentQuery.addFields(new Set<String>{ 'Supplier__r.Remit_To__c' });
        componentQuery.setWhereClause('Assembly_Item_Specification__c IN :assemblyIds');
        
        Map<Id,List<Component__c>> componentMap = new Map<Id,List<Component__c>>();
        for (Component__c component:(List<Component__c>)Database.query(componentQuery.getQuery())) {
            if (!componentMap.containsKey(component.Assembly_Item_Specification__c))
                componentMap.put(component.Assembly_Item_Specification__c,new List<Component__c>());
            componentMap.get(component.Assembly_Item_Specification__c).add(component);
        }
        return componentMap;
    }
    
    public static Map<Id,List<Routing__c>> getRoutings(Set<Id> assemblyIds) {
        SOQLUtil routingQuery = new SOQLUtil('Routing__c');
        routingQuery.addAllCustomFields();
        routingQuery.addFields(new Set<String>{ 'Work_Center_Resource__r.Manufacturing_Calendar__c','Work_Center__r.Manufacturing_Calendar__c' });
        routingQuery.setWhereClause('Assembly_Item_Specification__c IN :assemblyIds');
        
        Map<Id,List<Routing__c>> routingMap = new Map<Id,List<Routing__c>>();
        for (Routing__c routing:Database.query(routingQuery.getQuery())) {
            if (!routingMap.containsKey(routing.Assembly_Item_Specification__c))
                routingMap.put(routing.Assembly_Item_Specification__c,new List<Routing__c>());
            routingMap.get(routing.Assembly_Item_Specification__c).add(routing);
        }
        return routingMap;
    }

    public static Id getCalendarId(Operation_Tracking__c op) {
        if (op.Work_Center_Resource__c != null && op.Work_Center_Resource__r.Manufacturing_Calendar__c != null) {
            return op.Work_Center_Resource__r.Manufacturing_Calendar__c;
        } else if (op.Work_Center__c != null && op.Work_Center__r.Manufacturing_Calendar__c != null) {
            return op.Work_Center__r.Manufacturing_Calendar__c;
        } else if (op.Work_Order__r.Facility__r.Manufacturing_Calendar__c != null) {
            return op.Work_Order__r.Facility__r.Manufacturing_Calendar__c;
        } else if (op.Work_Order__r.Company__r.Manufacturing_Calendar__c != null) {
            return op.Work_Order__r.Company__r.Manufacturing_Calendar__c;
        }
        return null;
    }

    public static Map<Id,Map<Date,Working_Day__c>> getCalendars(DateTime startDate,Boolean backwards) {
        SOQLUtil workDayQuery = new SOQLUtil('Working_Day__c');
        workDayQuery.addAllCustomFields();
        workDayQuery.setOrderByClause('Start__c ASC');
        
        DateTime startDateForQuery;
        String whereClause;
        if (!backwards) {
            startDateForQuery = DateTime.newInstanceGmt(startDate.date(),Time.newInstance(0,0,0,0));
            whereClause = 'Start__c >= :startDateForQuery';
        } else {
            startDateForQuery = DateTime.newInstanceGmt(startDate.date().addDays(1),Time.newInstance(0,0,0,0));
            whereClause = 'End__c < :startDateForQuery';
        }
    
        Map<Id,Map<Date,Working_Day__c>> calendars = new Map<Id,Map<Date,Working_Day__c>>();
        for (Working_Day__c day:Database.query(workDayQuery.getQuery())) {
            if (!calendars.containsKey(day.Calendar__c))
                calendars.put(day.Calendar__c,new Map<Date,Working_Day__c>());
            calendars.get(day.Calendar__c).put(day.Start__c.date(),day);
        }
        
        return calendars;
    }

    public static void validateQuantityChange(List<Work_Order__c> workOrders,Map<Id,Work_Order__c> oldWorkOrders) {
        SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
        opQuery.addAllCustomFields();
        opQuery.setWhereClause('Work_Order__c IN :workOrders AND Quantity_Completed__c > 0');

        Map<Id,Decimal> maxCompleted = new Map<Id,Decimal>();
        for (Operation_Tracking__c op:Database.query(opQuery.getQuery())) {
            if (!maxCompleted.containsKey(op.Work_Order__c) || op.Quantity_Completed__c > maxCompleted.get(op.Work_Order__c)) {
                maxCompleted.put(op.Work_Order__c,op.Quantity_Completed__c);
            }
        }

        for (Work_Order__c wo:workOrders) {
            Decimal maxQty = maxCompleted.get(wo.Id);
            if (KSE.isFieldChanging('Order_Quantity__c',wo,oldWorkOrders) && maxQty != null && wo.Order_Quantity__c < maxQty) {
                wo.addError(wo.Name + ': Order quantity cannot be less than the maximum quantity completed on any operation (' + maxQty + ')');
            }
        }
    }

    /*
     * UNDO RELEASE SECTION
     */
    public static void validateForUndoRelease(List<Work_Order__c> workOrders) {
        if (workOrders == null || workOrders.size() == 0) return;
        
        Set<Id> opIds = new Set<Id>();
        Set<Id> mtIds = new Set<Id>();
        for (Work_Order__c wo:workOrders) {
            if (wo.Status__c != WorkOrderService.WO_STATUS_RELEASED) {
                throw new WorkOrderPlanningException(wo.Name + ': ' + Label.Cannot_undo_released_work_orders);
            }

            for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
                opIds.add(op.Id);
            }
            
            for(Material_Tracking__c mt:wo.Material_Trackings__r){
            	mtIds.add(mt.Id);
            }
        }

        SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
        polQuery.addFields(new Set<String>{ 'Id','Name', 'Material_Tracking__c','Status__c','Material_Tracking__r.Name','Operation_Tracking__c','Operation_Tracking__r.Name' });
        polQuery.setWhereClause('(Material_Tracking__c IN :mtIds AND Status__c != \'Cancelled\') OR (Operation_Tracking__c IN :opIds AND Purchase_Order__r.Approval_Status__c = \'' + PurchaseOrderService.PO_APPROVAL_STATUS_APPROVED + '\')');
		
		Set<String> mtSet = new Set<String>();
        for (Purchase_Order_Line__c pol:Database.query(polQuery.getQuery())) {
        	if(pol.Operation_Tracking__c != null){
        		throw new WorkOrderPlanningException(pol.Operation_Tracking__r.Name + ': Operation is linked to an approved purchase order line');
        	}
        	else if(pol.Material_Tracking__c !=null && pol.Status__c != 'Cancelled'){
        		throw new WorkOrderPlanningException(Label.Material_Tracking_PO_Lines_Cancelled);
        	}
        }
    }

    public static void undoRelease(Set<Id> woIds) {
        if (woIds == null || woIds.size() == 0) return;

        List<Work_Order__c> workOrders = WorkOrderService.getWorkOrders(woIds,null,null,new Set<String>{ 'Material_Trackings__r','Operation_Trackings__r' });
        validateForUndoRelease(workOrders);

        List<Material_Tracking__c> materialsToDelete = new List<Material_Tracking__c>();
        List<Operation_Tracking__c> operationsToDelete = new List<Operation_Tracking__c>();
        List<Work_Order__c> wosToUpdate = new List<Work_Order__c>();
        for (Work_Order__c wo:workOrders) {
            for (Material_Tracking__c mt:wo.Material_Trackings__r) {
                materialsToDelete.add(mt);
            }
            for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
                operationsToDelete.add(op);
            }

            wo.Status__c = WorkOrderService.WO_STATUS_DRAFT;
            wo.Release_Date__c = null;
        }

        SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
        polQuery.addFields(new Set<String>{ 'Id','Name','Purchase_Order__c' });
        polQuery.setWhereClause('Operation_Tracking__c IN :operationsToDelete');

        List<Purchase_Order_Line__c> poLines = Database.query(polQuery.getQuery());
        if (poLines.size() > 0) {
            JsonResult result = PurchaseOrderService.cancelPOLines(poLines,false);

            if (!result.success) {
                throw new WorkOrderPlanningException(result.messages[0].get('message'));
            }
        }

        if (materialsToDelete.size() > 0) DML.deleteAsUser(materialsToDelete);
        DML.deleteAsUser(operationsToDelete);
            
        WorkOrderService.allowWorkOrderUpdate = true;
        DML.updateAsUser(workOrders);
        WorkOrderService.allowWorkOrderUpdate = false; 
    }


    /*
     * UTILITY METHODS
     */
    private static List<Operation_Tracking__c> sortOperations(List<Operation_Tracking__c> operations,Work_Order__c wo) {
        Map<Decimal,Operation_Tracking__c> opSequences = new Map<Decimal,Operation_Tracking__c>();
        for (Operation_Tracking__c op:operations) {
            if (opSequences.containsKey(op.Sequence__c)) {
                throw new WorkOrderPlanningException(wo.Name + ': Duplicate operation sequence ' + op.Sequence__c);
            }
            opSequences.put(op.Sequence__c,op);
        }

        List<Decimal> sequences = new List<Decimal>(opSequences.keySet());
        sequences.sort();
                        
        List<Operation_Tracking__c> opList = new List<Operation_Tracking__c>();
        for (Decimal sequence:sequences) {
            opList.add(opSequences.get(sequence));
        }
        return opList;
    }

    private static Long calculateMsecsToConsume(Operation_Tracking__c op,Work_Order__c wo) {
        Decimal hoursToConsume = op.Standard_Hours__c * 60.0 * 60.0 * 1000.0;
        if (!op.Fixed_Hours__c) hoursToConsume = hoursToConsume * wo.Order_Quantity__c;
        return hoursToConsume.longValue();
    }

    /**
     * Call this method only when the Quantity_Value_Holder__c is present for WO.
     *
     */
    private static Decimal getWorkOrderQuantity (Work_Order__c wo, Map<Id, List<Id>> itemPackagingUomCache) {
        if ( String.isNotEmpty(wo.Quantity_Value_Holder__c)) {
            Map<String, Decimal> qtyByUOM = (Map<String, Decimal>) JSON.deserialize(wo.Quantity_Value_Holder__c ,Map<String,Decimal>.class);
            Decimal qty = 0;
            for ( String key : qtyByUOM.keySet() ) {
                if ( qtyByUOM.get(key) > 0) {
                    qty += ( qtyByUOM.get(key) * KSE.getConversionFactor (wo.Item__c, wo.Facility__r.Facility_Identifier__c, key, wo.Assembly_Item_Specification__r.Packaging_UOM__c, itemPackagingUomCache.get(wo.Item__c)) );
                }
            }
            return qty;
        }
        return null;
    }

    public class WorkOrderPlanningException extends Exception { }
}