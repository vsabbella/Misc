global with sharing class OrderAPI {
    public static final String SKID_TYPE_LOCATION = SkidService2.SKID_TYPE_LOCATION;
    public static final String SKID_TYPE_INTRANSIT = SkidService2.SKID_TYPE_INTRANSIT;
    private static SchemaUtil util = SchemaUtil.getInstance();
    private static List<String> attributeFields = new List<String>(util.getAllCustomFieldsFromObject(null,'Item_Attribute__c'));
    private static List<String> attributesForDisplay = new List<String>(SkidService2.attributesForPutaway(attributeFields));

    global static Map<Id,OrderAPIStatus> close(Map<Id,OrderWrapper> orderWrappers) {
        if (orderWrappers == null || orderWrappers.size() == 0)
            return null;
        orderWrappers = orderWrappers.clone();
        Map<Id,OrderAPIStatus> result = new Map<Id,OrderAPIStatus>();
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Order__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Status__c'
        });
        set<id> oWrapperSet = orderWrappers.keySet();
        soql.setWhereClause('Id IN :oWrapperSet');
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Order_Lines__r');
        childRel.addFields(new set<string>{
            'Id'
        });
        soql.addChildRelationship(childRel);
        Map<Id,Order__c> orders = new Map<Id,Order__c>((list<Order__c>)Database.query(soql.getQuery()));

        List<Order_Line__c> orderLines = new List<Order_Line__c>();

        for (Id orderId:orderWrappers.keySet()) {
            String errorMessage = '';
            if (!orders.containsKey(orderId)) {
                errorMessage = Label.Invalid_order_Id;
            } else {
                Order__c order = orders.get(orderId);
                if (order.Status__c == 'Draft')
                    errorMessage = Label.Transfer_Order_cannot_be_closed;
                else if (order.Status__c == 'Closed' || order.Status__c == 'Cancelled')
                    errorMessage = Label.Transfer_Order_cancelled_closed;
                else
                    orderLines.addAll(order.Order_Lines__r);
            }
            if (errorMessage != '') {
                result.put(orderId,createErrorResult(errorMessage));
                orderWrappers.remove(orderId);
                orders.remove(orderId);
            } else {
                result.put(orderId,createSuccessResult());
            }
        }
        
        if (orderLines.size() > 0){
            OrderService.ClearExceptions(orderLines);
            ReceivingDocumentService.close(orderWrappers.keySet(),'Order_Line__c','Order__c','Order__c',null, true,false,Label.Closed);               
        }
        return result;
    }
    global static Map<Id,OrderAPIStatus> release(Map<Id,OrderWrapper> orderWrappers) {
        if (orderWrappers == null || orderWrappers.size() == 0)
            return null;
        orderWrappers = orderWrappers.clone();
        Map<Id,OrderAPIStatus> result = new Map<Id,OrderAPIStatus>();
        
        Map<Id,Id> orderToShipment = new Map<Id,Id>();
        
        for (Shipment_Line__c shl:[SELECT Id,Order__c,Shipment__c FROM Shipment_Line__c WHERE Order__c IN :orderWrappers.keySet()]) {
          orderToShipment.put(shl.Order__c,shl.Shipment__c);
        }

        for (Id orderId:orderWrappers.keySet()) {
          if (!orderToShipment.containsKey(orderId)) {
            orderToShipment.put(orderId,null);
          }
        }
        
        OrderService.release(orderToShipment);
        
        for (Id orderId:orderWrappers.keySet()) {
          result.put(orderId,createSuccessResult());
        }

        return result;
    }
    global static Map<Id,OrderAPIStatus> receive(Map<Id,OrderWrapper> orderWrappers) {
         if (orderWrappers == null || orderWrappers.size() == 0)
            return null;
        orderWrappers = orderWrappers.clone();
        Map<Id,OrderAPIStatus> result = new Map<Id,OrderAPIStatus>();
       

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        
        //V2
        SOQLUtil soql = new SOQLUtil('Order__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Receiving_Company__c', 'Receiving_Company__r.Default_Transaction_Currency__c'
        });
        set<id> orderWrapperSet = orderWrappers.keySet();        
        soql.setWhereClause('Id IN :orderWrapperSet');
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Order_Lines__r');
        childRel.addFields(new set<string>{
            'Id'
        });
        soql.addChildRelationship(childRel);
        Map<Id,Order__c> orders = new Map<Id,Order__c>((list<Order__c>)Database.query(soql.getQuery()));



        for (Id orderId:orderWrappers.keySet()) {
            if (!orders.containsKey(orderId)) {
                result.put(orderId,createErrorResult(Label.Invalid_order_Id));
                orderWrappers.remove(orderId);
            }
        }
        if (orderWrappers.size() == 0)
            return result;
        Map<Id,ReceivingWrapper> records = getOrderLinesForReceive(orderWrappers.keySet());
        Map<String,Lot__c> lotMap = new Map<String,Lot__c>();
        Set<String> lotNames = new Set<String>();
        Map<Id,Receiving_Document__c> receivingDocumentsToInsert = new Map<Id,Receiving_Document__c>();
        ExceptionService exServ = new ExceptionService();
        Set<Id> itemIds = new Set<Id>();
        set<Id> facilityIds = new set<Id>();
        Set<Id> uniqueLocations = new Set<Id>();
        for (Id orderId:orderWrappers.keySet()) {
            OrderWrapper orderWrapper = orderWrappers.get(orderId);
            Order__c order = orders.get(orderId);
            String errorMessage = '';
            for (Id orderLineId:orderWrapper.lines.keySet()) {
                OrderLineWrapper orderLineWrapper = orderWrapper.lines.get(orderLineId);
                if (!records.containsKey(orderLineId)) {
                    errorMessage = 'One or more order lines are not available for receiving';
                    break;
                }
                ReceivingWrapper rw = records.get(orderLineId);
                Order_Line__c orderLine = rw.orderLine;
                itemIds.add(orderLine.Receiving_Item__c);
                facilityIds.add(rw.receiptLine.Facility__c);
                uniqueLocations.add(orderLine.Putaway_Location__c);
                if (orderLine.Putaway_Location__c == null) {
                    errorMessage = Label.Stock_movement_rules_are_not_setup;
                    break;
                }
                if (rw.supplySkid == null) {
                    errorMessage = 'Missing TO supply SKID';
                    break;
                }
                if (rw.inTransitSkids == null || rw.inTransitSkids.size() == 0) {
                    errorMessage = 'Missing in-transit SKIDs';
                    break;
                }
                for (Quantity qty:orderLineWrapper.quantities) {
                    if (qty.quantity == null || qty.quantity<= 0) {
                        errorMessage = Label.One_or_more_quantities_has_a_quantity_of_less_than_or_equal_to_zero;
                        break;
                    }
                    
                    SKID__c toSkid = new SKID__c();
                    toSkid.Quantity__c = qty.quantity;
                    toSkid.Item__c = rw.inTransitSkids[0].Item__c;
                    toSkid.Item__r = rw.inTransitSkids[0].Item__r;
                    toSkid.Order_Line__c = rw.inTransitSkids[0].Order_Line__c;
                    toSkid.Order_Line__r = rw.inTransitSkids[0].Order_Line__r;
                    toSkid.Shipment_Line__c = rw.inTransitSkids[0].Shipment_Line__c;
                    toSkid.Shipment_Line__r = rw.inTransitSkids[0].Shipment_Line__r;
                    toSkid.Bin__r = rw.inTransitSkids[0].Bin__r;
                    toSkid.Location__c = orderLine.Putaway_Location__c;
                    toSkid.Location__r = orderLine.Putaway_Location__r;
                    toSkid.Type__c = SkidService2.SKID_TYPE_LOCATION;
                    toSkid.Company__c = orderLine.Shipping_Company__c;
                    
                    if (orderLine.Receiving_Item__r.Item_Attribute__r.Expiration_Date__c) {
                        if (qty.expirationDate == null) {
                            errorMessage = Label.One_or_more_quantities_is_missing_an_expiration_date;
                            break;
                        }
                        toSkid.Expiration_Date__c = qty.expirationDate;
                    }
                    if (orderLine.Receiving_Item__r.Item_Attribute__r.Date_Received__c) {
                        if (qty.dateReceived == null) {
                            errorMessage = Label.One_or_more_quantities_is_missing_a_date_received;
                            break;
                        }
                        toSkid.Date_Received__c = qty.dateReceived;
                    }
                    if (orderLine.Receiving_Item__r.Item_Attribute__r.Lot_Number__c) {
                        if (qty.lot == null || qty.lot == '') {
                            errorMessage = Label.One_or_more_quantities_is_missing_a_lot;
                            break;
                        }
                        toSkid.Lot_Number__c = qty.lot;
                        SkidService2.populateLotNames(toSkid,null,lotMap,lotNames);
                    }
                    for (String attributeField:qty.attributes.keySet())
                        if ((Boolean)orderLine.Receiving_Item__r.Item_Attribute__r.get(attributeField))
                            toSkid.put(attributeField,qty.attributes.get(attributeField));
                    rw.receivingSkids.add(toSkid);
                    
                    //Inventory_Transaction__c it = SkidService2.createIT(rw.supplySkid,orderLine.Receiving_Item__c,'Transfer Order Receipt',null,null,null,orderLine.Putaway_Location__c,toSkid,attributesForDisplay);
                    Inventory_Transaction__c it = SkidService3.createInventoryTransaction(orderLine,'Transfer Order Receipt',qty.quantity,rw.supplySkid,toSkid,attributesForDisplay);   
                    //it.Order_Line__c = orderLine.Id;
                    //it.Quantity__c = qty.quantity;
                    rw.itList.add(it);
                }
                if (errorMessage != '')
                    break;
                if (rw.overReceipt) {
                    errorMessage = Label.Cannot_receive_more_quantity_than_the_quantity_still_due_overage_quantity;
                    break;
                }
                rw.receiptLine.Quantity_Received__c = rw.totalReceived;
                if (rw.quantityException) {
                    ExceptionUtil.TO_QTYEXCEEDED.label = 'Quantity Mismatch while receiving the Order Line ' ;
                    ExceptionUtil.TO_QTYEXCEEDED.description = 'Quantity Mismatch while receiving the Order Line ' ;
                    exServ.setException(orderLine,ExceptionUtil.TO_QTYEXCEEDED);
                }
                if (rw.lotException) {
                    ExceptionUtil.TO_LOTMISMATCH.label = 'LOT Mismatch while receiving the Order Line ';
                    ExceptionUtil.TO_LOTMISMATCH.description = 'LOT Mismatch while receiving the Order Line ' ;
                    exServ.setException(orderLine,ExceptionUtil.TO_LOTMISMATCH);
                }
            }
            if (errorMessage != '') {
                result.put(orderId,createErrorResult(errorMessage));
                for (Order_Line__c orderLine:order.Order_Lines__r)
                    records.remove(orderLine.Id);
                orderWrappers.remove(orderId);
                orders.remove(orderId);
            } else {
                Receiving_Document__c receivingDocument = new Receiving_Document__c(Company__c = order.Receiving_Company__c,Date_Created__c = System.today(),Date_Received__c = System.now(),Type__c = 'Transfer Order Receipt',
                                                                                    Currency__c = order.Receiving_Company__r.Default_transaction_Currency__c,Finalized__c = false,Status__c = 'Closed');
                receivingDocumentsToInsert.put(orderId,receivingDocument);
            }
        }
        exServ.finish();
        Map<String,Lot__c> createdLotMap = SkidService2.createLots(lotMap,lotNames);
        DML.insertAsUser(receivingDocumentsToInsert.values());
        Map<Id,Order_Line__c> orderLinesToUpdate = new Map<Id,Order_Line__c>();
        Map<Id,Receipt_Line__c> receiptLines = new Map<Id,Receipt_Line__c>();
        List<SKID__c> skidsForService = new List<SKID__c>();
        Map<Id,sObject> sourceDocs = new Map<Id,sObject>();
        Map<Id,List<Inventory_Transaction__c>> itMap = new Map<Id,List<Inventory_Transaction__c>>();
        for (ReceivingWrapper rw:records.values()) {
            if (rw.receivingSkids == null || rw.receivingSkids.size() == 0)
                continue;
            Double stdCost = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,rw.receiptLine.Company__c,rw.receiptLine.Facility__c,System.now(),rw.receiptLine.Item__c);
            Order_Line__c orderLine = rw.orderLine;
            Receipt_Line__c receiptLine = rw.receiptLine;
            for (Integer i=0;i<rw.receivingSkids.size();i++) {
                SKID__c receivingSkid = rw.receivingSkids[i];
                Inventory_Transaction__c it = rw.itList[i];
                if (receivingSkid.Item__r.Item_Attribute__r.Lot_Number__c && (!orderLine.Receiving_Item__r.Non_Inventory__c || orderLine.Receiving_Item__r.Source__c == 'Outside Processing')) {
                    String uniqueLotString = SkidService2.lotUniqueKey(receivingSkid,null);
                    receivingSkid.Lot__c = createdLotMap.get(uniqueLotString).Id;
                    receivingSkid.Lot_Number__c = createdLotMap.get(uniqueLotString).Name;
                    it.Lot__c = createdLotMap.get(uniqueLotString).Id;
                }
            }
            receiptLine.Receiving_Document__c = receivingDocumentsToInsert.get(orderLine.Order__c).Id;
            receivingDocumentsToInsert.get(orderLine.Order__c).Finalized__c = true;
            receiptLine.Uninvoiced_Quantity__c = receiptLine.Quantity_Received__c;
            if (orderLine.Quantity_Received__c == null)
                orderLine.Quantity_Received__c = 0;
            orderLine.Quantity_Received__c += receiptLine.Quantity_Received__c;
            receiptLine.Extended_Cost__c = stdCost * receiptLine.Quantity_Received__c;
            receiptLine.Quantity_To_Stock__c = receiptLine.Quantity_Received__c;
            orderLinesToUpdate.put(orderLine.Id,orderLine);
            if (!orderLine.Receiving_Item__r.Non_Inventory__c) {
                skidsForService.addAll(rw.receivingSkids);
                Id sourceDocId = orderLine.Order__c;
                sourceDocs.put(sourceDocId,new Sales_Order__c(Company__c = orderLine.Receiving_Company__c));
                if (!itMap.containsKey(sourceDocId))
                    itMap.put(sourceDocId,new List<Inventory_Transaction__c>());
                itMap.get(sourceDocId).addAll(rw.itList);
            }
            receiptLines.put(orderLine.Id,receiptLine);

        }
        DML.insertAsUser(receiptLines.values());
        for (List<Inventory_Transaction__c> itList:itMap.values())
            for (Inventory_Transaction__c it:itList) 
                if (receiptLines.containsKey(it.Order_Line__c))
                    it.Receipt_Line__c = receiptLines.get(it.Order_Line__c).Id;
        List<SKID__c> negativeSkidsforService = new List<SKID__c>();
        Set<Id> uniqueLocationIds = new Set<Id>();
        for(SKID__c skid:skidsForService) {
            SKID__c negativeSkid = skid.clone(false,true);
            if (orderLinesToUpdate.containsKey(skid.Order_Line__c)) {
                negativeSkid.Location__c = orderLinesToUpdate.get(skid.Order_Line__c).Deliver_To_Location__c;
                uniqueLocationIds.add(negativeSkid.Location__c);
            }
            negativeSkid.Quantity__c = negativeSkid.Quantity__c * -1;
            negativeSkid.Type__c = SkidService2.SKID_TYPE_INTRANSIT;
            negativeSkidsforService.add(negativeSkid);
            skid.Order_Line__c = null;
            skid.Shipment_Line__c = null;
        }
        List<String> attributesForServiceForNegativeSkids = attributesForDisplay.clone();
        attributesForServiceForNegativeSkids.add('Order_Line__c');
        attributesForServiceForNegativeSkids.add('Shipment_Line__c');
        Map<String,SKID__c> negativeToSkidsMap = SkidService2.putAwayService(negativeSkidsforService,attributesForServiceForNegativeSkids,uniqueLocationIds,'In-Transit',false);
        Map<String,SKID__c> toSkidsMap = SkidService2.putAwayService(skidsForService,attributesForDisplay,uniqueLocations,'Location',false);  
        SkidService2.inventoryTransactionsForPutAway(sourceDocs,itMap,null,null,attributesForDisplay,toSkidsMap,null,null);
        DML.updateAsUser(orderLinesToUpdate.values());
        List<Id> skidsToDelete = new List<Id>();
        for (SKID__c skid:negativeToSkidsMap.values())
            if (skid.Quantity__c == 0)
                skidsToDelete.add(skid.Id);
        if (skidsToDelete.size() > 0)
            DML.deleteAsSystem(skidsToDelete);
        DML.updateAsUser(receivingDocumentsToInsert.values());
        for (Id orderId:orderWrappers.keySet())
            result.put(orderId,createSuccessResult());
        return result;
    }
    private static Map<Id,ReceivingWrapper> getOrderLinesForReceive(Set<Id> orderIds) {
        Map<Id,ReceivingWrapper> records = new Map<Id,ReceivingWrapper>();
        
        Set<String> skidFields = new set<String>{ 'Id','Name','Order_Line__r.Ship_From_Location__c','Bin__r.Location__c','Shipment_Line__r.Company__c','Shipment_Line__r.Facility__c','Shipment_Line__r.Item__c', 'Facility2__r.Facility_Identifier__c',
                                                     'Item__r.Packaging_UOM__c', 'Shipment_Line__r.Item__r.Packaging_UOM__c', 'Shipment_Line__r.Shipment__c','Shipment_Line__r.Shipment__r.Status__c','Item__r.Item_Attribute__c','Item__r.Non_Inventory__c','Item__r.Source__c','Item__r.Stocking_UOM__c',
                                                     'Company__c','Location__r.Facility__r.Company__c' };
        skidFields.addAll(util.getAllCustomFieldsFromObject(null,'SKID__c'));
        skidFields.addAll(util.getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.','Item_Attribute__c'));
        
        Set<String> skidTypes = new Set<String>{ SkidService2.SKID_TYPE_INTRANSIT,SkidService2.SKID_TYPE_TO_SUPPLY };
        
        /*String skidSubquery = util.generateQueryFromFieldSet('SKID__c',new Set<String>{ 'Receipt_Info' },skidFields,'Type__c IN :skidTypes AND Quantity__c > 0').toLowerCase();
        skidSubquery = '(' + skidSubquery.replace('from skid__c','FROM SKIDs__r') + ')';*/
        
        Set<String> orderLineFieldList = new Set<String>{ 'Id','Name','Shipping_Item__r.Description__c','Shipping_Item__r.Name','Shipping_Item__r.Class__c','Deliver_To_Location__r.Facility__c','Shipping_Item__r.Packaging_UOM__c', 
                                                          'Receiving_Item__r.Stocking_UOM__c','Receiving_Item__r.Stocking_UOM__r.Name','Receiving_Item__r.Item_Attribute__c','Receiving_Item__r.Non_Inventory__c','Receiving_Item__r.Packaging_UOM__c', 
                                                          'Receiving_Item__r.Source__c','SystemModStamp','Receiving_Item__r.Class__r.Minimum_Shelf_Life_in_Days__c','Order__r.Currency__c',
                                                          'Order__r.Receiving_Company__c','Order__r.Shipping_Company__c', 'Ship_From_Facility__r.Facility_Identifier__c', 'Deliver_To_Facility__r.Facility_Identifier__c' };
        orderLineFieldList.addAll(util.getAllCustomFieldsFromObject(null,'Order_Line__c'));
        orderLineFieldList.addAll(util.getAllCustomFieldsFromObject('Receiving_Item__r.Item_Attribute__r.','Item_Attribute__c'));
        
        String whereClause = 'Order__c IN :orderIds and Quantity_To_Receive__c > 0';
        
      SOQLUtil soql = new SOQLUtil('Order_Line__c');
      soql.addFields('Order_Receive');
      soql.addFields(orderLineFieldList);
      soql.setWhereClause(whereClause);
      
      SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
      skids.addFields('Receipt_Info');
      skids.addFields(skidFields);
      skids.setWhereClause('Type__c IN :skidTypes AND Quantity__c > 0');
      soql.addChildRelationship(skids);
      
      Map<Id,Order_Line__c> orderLineMap = new Map<Id,Order_Line__c>((List<Order_Line__c>)Database.query(soql.getQuery()));
        //Map<Id,Order_Line__c> orderLineMap = new Map<Id,Order_Line__c>((List<Order_Line__c>)Database.query(util.generateQueryFromFieldSet('Order_Line__c',new set<string>{ 'Order_Receive' },orderLineFieldList,'Order__c IN :orderIds and Quantity_To_Receive__c > 0')));   
        if (orderLineMap.size() == 0)
            return records;
        Map<Id,List<Location__c>> locationsByHeader = SkidService2.locationsFromStockMovementRules(orderLineMap.values(),'Putaway','Transfer Order',new Map<Id,Stock_Movement_Rule__c>());
        for (Order_Line__c orderLine:orderLineMap.values()) {
            Location__c putawayLocation;
            if (locationsByHeader.containsKey(orderLine.Id) && locationsByHeader.get(orderLine.Id).size() > 0)
                putawayLocation = locationsByHeader.get(orderLine.Id)[0];
            Id putawayLocationId = putawayLocation != null ? putawayLocation.Id : null;
            orderLine.Putaway_Location__c = putawayLocationId;
            orderLine.Putaway_Location__r = putawayLocation;

            SKID__c supplySkid;
            List<SKID__c> inTransitSkids = new List<SKID__c>();
            for (SKID__c skid:orderLine.SKIDs__r) {
                if (skid.Type__c == SkidService2.SKID_TYPE_TO_SUPPLY)
                    supplySkid = skid;
                else if (skid.Type__c == SkidService2.SKID_TYPE_INTRANSIT)
                    inTransitSkids.add(skid);
            }
            if (orderLine.Receiving_Item__r.Non_Inventory__c)
            	
                inTransitSkids.add(new SKID__c(Item__c = orderLine.Receiving_Item__c,Order_Line__c = orderLine.Id,Quantity__c = orderLine.Quantity_Ordered__c, Company__c = orderLine.Receiving_Company__c));
            Receipt_Line__c receiptLine = new Receipt_Line__c(Company__c = orderLine.Receiving_Company__c,Item__c = orderLine.Receiving_Item__c, Item__r=orderLine.Receiving_Item__r,Order_Line__c = orderLine.Id,Order__c = orderLine.Order__c,
                                                              Location__c = orderLine.Deliver_To_Location__c,Facility__c = orderLine.Deliver_To_Facility__c,Uninvoiced_Quantity__c = 0,Status__c = 'Closed',
                                                              Shipment_Line__c = inTransitSkids[0].Shipment_Line__c,Shipment_Line__r = inTransitSkids[0].Shipment_Line__r,Putaway_Location__c = orderLine.Putaway_Location__c);
            ReceivingWrapper rw = new ReceivingWrapper(supplySkid,inTransitSkids,receiptLine,orderLine);
            records.put(orderLine.Id,rw);
        }
        return records;
    }
    public class ReceivingWrapper {
        public SKID__c supplySkid { get; set; }
        public List<SKID__c> inTransitSkids { get; set; }
        public Receipt_Line__c receiptLine { get; set; }
        public Order_Line__c orderLine { get; set; }
        public List<SKID__c> receivingSkids { get; set; }
        public List<Inventory_Transaction__c> itList { get; set; }
        public Decimal totalShipped {
            get {
                Decimal amountShipped = 0;
                for (SKID__c inTransitSkid:inTransitSkids)
                    amountShipped += inTransitSkid.Quantity__c;
                return amountShipped;
            }
        }
        public Decimal totalReceived {
            get {
                Decimal amountReceived = 0;
                for (SKID__c receivingSkid:receivingSkids)
                    amountReceived += receivingSkid.Quantity__c;
                return amountReceived;
            }
        }
        public Boolean overReceipt {
            get {
                if (totalReceived > KSE.addQuantityToField(orderLine.Quantity_Still_Due__c,orderLine.Overage_Quantity__c))
                    return true;
                return false;
            }
        }
        public Boolean quantityException {
            get {
                if (totalShipped != totalReceived)
                    return true;
                return false;
            }
        }
        public Boolean lotException {
            get {
                Set<String> shippedLots = new Set<String>();
                for (SKID__c inTransitSkid:inTransitSkids)
                    if (inTransitSkid.Lot_Number__c != null && inTransitSkid.Lot_Number__c != '')
                        shippedLots.add(inTransitSkid.Lot_Number__c);
                for (SKID__c receivingSkid:receivingSkids)
                    if (receivingSkid.Lot_Number__c != null && receivingSkid.Lot_Number__c != '' && !shippedLots.contains(receivingSkid.Lot_Number__c))
                        return true;
                return false;
            }
        }
        public ReceivingWrapper(SKID__c supplySkid,List<SKID__c> inTransitSkids,Receipt_Line__c receiptLine,Order_Line__c orderLine) {
            this.supplySkid = supplySkid;
            this.inTransitSkids = inTransitSkids;
            this.receiptLine = receiptLine;
            this.orderLine = orderLine;
            receivingSkids = new List<SKID__c>();
            itList = new List<Inventory_Transaction__c>();
        }
    }
    

    global class OrderWrapper {
        global Id orderId { get; private set; }
        global Map<Id,OrderLineWrapper> lines { get; private set; }
        global OrderWrapper(Id orderId) { 
            this.orderId = orderId;
            lines = new Map<Id,OrderLineWrapper>(); 
        }
    }
    global class OrderLineWrapper {
        global List<Quantity> quantities { get; private set; }
        global OrderLineWrapper() { quantities = new List<Quantity>(); }
    }
    global class Quantity {
        global Decimal quantity { get; set; }
        global String lot { get; set; }
        global Date expirationDate { get; set; }
        global Date dateReceived { get; set; }
        global Map<String,Object> attributes { get; private set; }
        global Quantity() { 
            attributes = new Map<String,Object>(); 
            quantity = 0;
        }
    }
    global class OrderAPIStatus {
        global Boolean success { get; set; }
        global String errorMessage { get; set; }
    }
    private static OrderAPIStatus createErrorResult(String errorMessage) {
        OrderAPIStatus status = new OrderAPIStatus();
        status.success = false;
        status.errorMessage = errorMessage;
        return status;
    }
    private static OrderAPIStatus createSuccessResult() {
        OrderAPIStatus status = new OrderAPIStatus();
        status.success = true;
        return status;
    }


    // DEPRECATED
    global static Map<Id, OrderAPIStatus> allocate(Map<Id, OrderWrapper> orderWrappers) { throw new CustomException('Deprecated'); }
    global static Map<Id, OrderAPIStatus> pick(Map<Id, OrderWrapper> orderWrappers) { throw new CustomException('Deprecated'); }
    global static Map<Id, OrderAPIStatus> confirmShip(Map<Id, OrderWrapper> orderWrappers) { throw new CustomException('Deprecated'); }

    global class OrderAPIException extends Exception {
        public OrderAPIException(Object obj) { throw new CustomException('Deprecated'); }
    }
}