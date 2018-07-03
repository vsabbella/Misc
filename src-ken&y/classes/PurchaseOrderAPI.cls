global with sharing class PurchaseOrderAPI {
    public class Receive implements Action.Target {
        public Action.Response execute(Object obj) {
            Savepoint sp = Database.setSavepoint();
            Action.Response resp = new Action.Response();
            resp.success = true;
            try {
                Map<String, Object> lineMap = (Map<String, Object>)JSON.deserializeUntyped(String.valueOf(obj));
                if (lineMap.size() == 0) return resp;

                Set<Id> polIds = new Set<Id>();
                Set<Id> locIds = new Set<Id>();
                Map<Id, List<Map<String, Object>>> lines = new Map<Id, List<Map<String, Object>>>();
                for (Id polId:lineMap.keySet()) {
                    polIds.add(polId);
                    lines.put(polId, new List<Map<String, Object>>());

                    for (Object skWrapper:(List<Object>)lineMap.get(polId)) {
                        Map<String, Object> skidWrapper = (Map<String, Object>)skWrapper;
                        if (skidWrapper.containsKey('skid') == true) {
                            SKID__c skid = (SKID__c)JSON.deserialize(JSON.serialize(skidWrapper.get('skid')), SKID__c.Class);
                            if (skid.Location__c != null) locIds.add(skid.Location__c);
                            skidWrapper.put('skid', skid);
                        }
                        if (skidWrapper.containsKey('serials') == true) {
                            skidWrapper.put('serials', (List<Serial__c>)JSON.deserialize(JSON.serialize(skidWrapper.get('serials')), List<Serial__c>.Class));
                        }
                        lines.get(polId).add(skidWrapper);
                    }
                }

                Map<Id, ReceivingWrapper> poLines = new Map<Id, ReceivingWrapper>();
                for (ReceivingWrapper rWrapper:ReceivingDocumentServiceV2.getReceivingLines(null, polIds, new Set<String>{ 'purchase_order_line__c' })) {
                    poLines.put(rWrapper.rl.Id, rWrapper);
                }

                Map<Id, Location__c> locs = new Map<Id, Location__c>();
                if (locIds.size() > 0) {
                    SOQLUtil locQuery = new SOQLUtil('Location__c');
                    locQuery.addFields(new Set<String>{ 'Id', 'Name', 'Bin_Tracked__c', 'Facility__c', 'Mixed_Bins_Allowed__c', 'Track_Bin_Capacity__c' });
                    locQuery.setWhereClause('Id IN :locIds');
                    locs = new Map<Id, Location__c>((List<Location__c>)Database.query(locQuery.getQuery()));
                }

                Map<Id, Receiving_Document__c> rdMap = new Map<Id, Receiving_Document__c>();
                Map<List<String>, ReceivingWrapper> rWrappers = new Map<List<String>, ReceivingWrapper>();
                for (Id polId:lines.keySet()) {
                    if (poLines.containsKey(polId) == false) throw new CustomException('Purchase order line (' + polId + ') is not available for receiving.');

                    ReceivingWrapper rWrapper = poLines.get(polId);
                    Purchase_Order_Line__c pol = (Purchase_Order_Line__c)rWrapper.rl;
                    Purchase_Order__c po = pol.Purchase_Order__r;

                    if (rdMap.containsKey(po.Id) == false) {
                        rdMap.put(po.Id, new Receiving_Document__c(
                            Company__c = po.Company__c,
                            Company__r = po.Company__r,
                            Supplier__c = po.Supplier__c,
                            Supplier__r = po.Supplier__r,
                            Currency__c = po.Currency__c,
                            Currency__r = po.Currency__r,
                            Transaction_Type__c = 'Purchase Order Receipt',
                            Type__c  = 'Purchase Order Receipt',
                            Status__c = 'Closed',
                            Transaction_Date__c = System.now(),
                            Date_Received__c = System.now()
                        ));
                    }

                    for (Map<String, Object> skidWrapper:lines.get(polId)) {
                        if (skidWrapper.containsKey('skid') == false) throw new CustomException(pol.Name + ': SKID is required for receiving.');

                        SKID__c skid = (SKID__c)skidWrapper.get('skid');
                        if (skid.Location__c == null) throw new CustomException(pol.Name + ': Location is required for receiving.');

                        Location__c loc = locs.get(skid.Location__c);
                        if (loc.Facility__c != pol.Delivery_Facility__c) throw new CustomException(pol.Name + ': You can\'t receive into a different facility than the purchase order line\'s delivery facility.');
                        
                        List<Serial__c> serials = skidWrapper.containsKey('serials') == true ? (List<Serial__c>)skidWrapper.get('serials') : null;
                        SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(rWrapper.serialWrapperList[0].skid.clone(false, true), serials);
                        

                        List<String> key = new List<String>{ pol.Id, loc.Id };
                        ReceivingWrapper rw;
                        if (rWrappers.containsKey(key) == true) {
                            rw = rWrappers.get(key);
                        } else {
                            rw = new ReceivingWrapper(rWrapper);
                            rw.rl.put('Putaway_Location__c', loc.Id);
                            rw.rl.putSObject('Putaway_Location__r', loc);
                            rw.serialWrapperList = new List<SkidService3.SerialWrapper>();
                            rw.trackedAttributes = SkidService3.trackedAttributes(null, loc, (Item__c)rw.rl.getSObject('Item__r'), sw.skid.Container_Item__r);
                        }
                        
                        sw.skid.Quantity__c = skid.Input_Quantity__c;
                        sw.skid.Location__c = skid.Location__c;
                        for (String attr:rw.trackedAttributes) {
                            attr = attr.toLowerCase();
                            if (attr != 'packaging_uom__c') {
                                if (attr == 'license_plate_number__c') sw.skid.Temporary_LPN_Holder__c = skid.Temporary_LPN_Holder__c;
                                else sw.skid.put(attr, skid.get(attr));
                            }
                        }
                        rw.serialWrapperList.add(sw);
                        rWrappers.put(key, rw);
                    }
                }

                DML.insertAsUser(rdMap.values());
                ReceivingDocumentServiceV2.receive(ReceivingDocumentServiceV2.checkUserErrors(rWrappers.values()), rdMap);
            } catch (Exception e) {
                Database.rollback(sp);
                resp.success = false;
                resp.error.put('message', CustomException.getMessage(e));
            }
            return resp;
        }
    }


    global static Map<Id,PurchaseOrderAPIStatus> close(Map<Id,PurchaseOrderWrapper> purchaseOrderWrappers) {
        if (purchaseOrderWrappers == null || purchaseOrderWrappers.size() == 0)
            return null;
        purchaseOrderWrappers = purchaseOrderWrappers.clone();
        
        Map<Id,PurchaseOrderAPIStatus> result = new Map<Id,PurchaseOrderAPIStatus>();

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        Set<Id> poIds = purchaseOrderWrappers.keySet();
        SOQLUtil soql = new SOQLUtil('Purchase_Order__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id'
        });
        soql.setWhereClause('Id IN :poIds');

        Map<Id,Purchase_Order__c> purchaseOrders = new Map<Id,Purchase_Order__c>((List<Purchase_Order__c>)Database.query(soql.getQuery()));

        for (Id purchaseOrderId:purchaseOrderWrappers.keySet()) {
            PurchaseOrderWrapper purchaseOrderWrapper = purchaseOrderWrappers.get(purchaseOrderId);
            if (!purchaseOrders.containsKey(purchaseOrderId)) {
                result.put(purchaseOrderId,createErrorResult('Invalid purchase order Id'));
                purchaseOrderWrappers.remove(purchaseOrderId);
                continue;
            }
        }
        ReceivingDocumentService.close(purchaseOrderWrappers.keySet(),'Purchase_Order_Line__c','Purchase_Order__c','Purchase_Order__c',new List<String>{ SkidService2.SKID_TYPE_PO_SUPPLY },false,false,'Closed');
        for (Id purchaseOrderId:purchaseOrderWrappers.keySet())
            result.put(purchaseOrderId,createSuccessResult());
        return result;
    }


    global class PurchaseOrderWrapper {
        global Id purchaseOrderId { get; private set; }
        global Map<Id,PurchaseOrderLineWrapper> lines { get; private set; }
        global PurchaseOrderWrapper(Id poId) { 
            purchaseOrderId = poId;
            lines = new Map<Id,PurchaseOrderLineWrapper>(); 
        }
    }
    global class PurchaseOrderAPIStatus {
        global Boolean success { get; set; }
        global String errorMessage { get; set; }
    }
    private static PurchaseOrderAPIStatus createErrorResult(String errorMessage) {
        PurchaseOrderAPIStatus status = new PurchaseOrderAPIStatus();
        status.success = false;
        status.errorMessage = errorMessage;
        return status;
    }
    private static PurchaseOrderAPIStatus createSuccessResult() {
        PurchaseOrderAPIStatus status = new PurchaseOrderAPIStatus();
        status.success = true;
        return status;
    }

    
    // DEPRECATED
    global static Map<Id, PurchaseOrderAPIStatus> receive(Map<Id, PurchaseOrderWrapper> purchaseOrderWrappers) { throw new CustomException('Deprecated'); }

    global class PurchaseOrderLineWrapper {
        global List<ReceivingLine> receivingLines { get; private set; }
        global PurchaseOrderLineWrapper() { throw new CustomException('Deprecated'); }
    }

    global class ReceivingLine {
        global Decimal qtyReceived { get; set; }
        global String lot { get; set; }
        global String bin { get; set; }
        global Date expirationDate { get; set; }
        global Date dateReceived { get; set; }
        global Map<String,Object> attributes { get; private set; }
        global ReceivingLine() { throw new CustomException('Deprecated'); }
    }

    global class PurchaseOrderAPIException extends Exception {
        public PurchaseOrderAPIException(Object obj) { throw new CustomException('Deprecated'); }
    }
}