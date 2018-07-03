/**
 * Generates barcode to be consumed by the KDOC extension package
 * 
 */ 
global class LabelsApi {
    public class LabelsApiException extends Exception {}
    
    private LabelsApi () {}
    
    public static List<Label__c> generateLabels ( List<SObject> sobjs ) {
        if ( sobjs == null || sobjs.isEmpty() ) {
            return new List<Label__c>();
        }
        sObjectType type = sobjs[0].getSObjectType();
        
        if ( type == Work_Order__c.sObjectType) {
            return generateWorkOrderLabels(sobjs, new Map<Id, List<LabelWrapper>>());
        } else if ( type == Sales_Order__c.sObjectType ) {
            return generateSalesOrderLabels(sobjs, new Map<Id, List<LabelWrapper>>());
        } else if ( type == Shipment__c.sObjectType) {
            return generateShipmentLabels(sobjs, new Map<Id, List<LabelWrapper>>());
        } else {
            throw new LabelsApiException ('Unsupported SObject for Labels');
        }
    }

    /**
     * Generate labels for specific case Index
     */
    public static List<Label__c> generateSingleLabels ( Map<Id, List<LabelWrapper>> mapLabelWrapper ) {
        if ( mapLabelWrapper == null || mapLabelWrapper.isEmpty()) {
            return new List<Label__c>();
        }
        List<SObject> sobjs = new List<SObject> ();
        for ( Id key : mapLabelWrapper.keySet() ) {
            for ( LabelWrapper lbl : mapLabelWrapper.get(key)) {
                sobjs.add(lbl.record);
            }
        }
        sObjectType type = sobjs[0].getSObjectType();
        if ( type == Work_Order__c.sObjectType) {
            return generateWorkOrderLabels(sobjs,mapLabelWrapper);
        } else if ( type == Sales_Order_Line__c.sObjectType ) {
            return generateSalesOrderLabels(sobjs, mapLabelWrapper);
        } else if ( type == Shipment_Line__c.sObjectType) {
            return generateShipmentLabels(sobjs, mapLabelWrapper);
        } else {
            throw new LabelsApiException ('Unsupported SObject for Labels');
        }
    }

    public static List<Label__c> generateHeterogeneousLabels ( Map<Id, List<LabelWrapper>> mapLabelWrapper ) {
        if ( mapLabelWrapper == null || mapLabelWrapper.isEmpty()) {
            return new List<Label__c>();
        }

        requeryLabelWrapperRecords (mapLabelWrapper);

        List<Label__c> labels = new List<Label__c> ();
        Map<Id, List<Id>> mapItemPackagingUOM = new Map<Id, List<Id>> ();

        for ( Id key : mapLabelWrapper.keySet() ) {
            for ( LabelWrapper lbl : (List<LabelWrapper>) mapLabelWrapper.get(key)) {
                Item__c itm;
                SObjectType type = lbl.record.getSObjectType();
                if (type == Work_Order__c.sObjectType) {
                    Work_Order__c rec = (Work_Order__c) lbl.record;
                    itm = rec.Item__r;
                } else if (type == Sales_Order_Line__c.sObjectType) {
                    Sales_Order_Line__c rec = (Sales_Order_Line__c) lbl.record;
                    itm = rec.Product__r.Item__r;
                } else if (type == Shipment_Line__c.sObjectType) {
                    Shipment_Line__c rec = (Shipment_Line__c) lbl.record;
                    itm = rec.Item__r;
                } else if ( type == Sales_Order__c.sObjectType || type == Order__c.sObjectType) {
                    itm = lbl.item;
                }

                if (!mapItemPackagingUOM.containsKey (itm.Id)) {
                    List<Id> lstPkgUom = (List<Id>) JSON.deserialize(itm.Packaging_UOM__c, List<Id>.class);
                    mapItemPackagingUOM.put(itm.Id, lstPkgUom);
                }
            }
        }

        for ( Id key : mapLabelWrapper.keySet() ) {
            for ( LabelWrapper lbl : (List<LabelWrapper>) mapLabelWrapper.get(key)) {
                SObjectType type = lbl.record.getSObjectType();
                if ( type == Work_Order__c.sObjectType) {
                    labels.add( createWorkOrderLabels((Work_Order__c)lbl.record, lbl, mapItemPackagingUOM));
                } else if ( type == Sales_Order_Line__c.sObjectType ) {
                    labels.add( createSalesOrderLineLabel((Sales_Order_Line__c)lbl.record, lbl, mapItemPackagingUOM));
                } else if ( type == Shipment_Line__c.sObjectType) {
                    labels.add( createShipmentLineLabel((Shipment_Line__c)lbl.record, lbl, mapItemPackagingUOM));
                } else if ( type == Sales_Order__c.sObjectType ) {
                    labels.add( createOrderLabel((Sales_Order__c)lbl.record, lbl, mapItemPackagingUOM));
                } else if (type == Order__c.sObjectType) {
                    labels.add( createOrderLabel((Order__c)lbl.record, lbl, mapItemPackagingUOM));
                }
            }
        }

        DML.insertAsUser (labels);
        return labels;

    }

    static void requeryLabelWrapperRecords ( Map<Id, List<LabelWrapper>> mapLabelWrapper ) {
        Set<Id> solIds = new Set<Id>(),
                woIds = new Set<Id>(),
                shlIds = new Set<Id>(),
                soIds = new Set<Id>(),
                ordIds = new Set<Id>(),
                itemIds = new Set<Id>();

        for ( Id key : mapLabelWrapper.keySet() ) {
            List<LabelWrapper> lbls = mapLabelWrapper.get(key);
            for ( LabelWrapper lbl : lbls ) {
                SObjectType type = lbl.record.getSObjectType();
                if (type == Work_Order__c.sObjectType) {
                    woIds.add(lbl.record.Id);
                } else if (type == Sales_Order_Line__c.sObjectType) {
                    solIds.add(lbl.record.Id);
                } else if (type == Shipment_Line__c.sObjectType) {
                    shlIds.add(lbl.record.Id);
                } else if ( type == Sales_Order__c.sObjectType ) {
                    soIds.add(lbl.record.Id);
                    itemIds.add(lbl.item.id);
                } else if (type == Order__c.sObjectType) {
                    ordIds.add(lbl.record.Id);
                    itemIds.add(lbl.item.id);
                } else {
                    throw new LabelsApiException('Unsupported SObject for Labels');
                }
            }
        }
        SOQLUtil util;
        Map<Id, SObject> sobjMap = new Map<Id, SObject> ();

        if ( !woIds.isEmpty()) {
            util = new SOQLUtil('Work_Order__c', true);
            util.addFields(new Set<String>{
                    'id', 'name', 'Order_Quantity__c', 'Item__r.Item_Identifier__c', 'Packaging_UOM__c', 'Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c', 'Facility__c', 'Facility__r.Facility_Identifier__c'
            });
            util.setWhereClause('id in :woIds');
            sobjMap.putAll(new Map<Id, Work_Order__c>((List<Work_Order__c>) Database.query(util.getQuery())));
        }

        if ( !solIds.isEmpty()) {
            util = new SOQLUtil('Sales_Order_Line__c', true);
            util.addFields(new Set<String>{
                    'id', 'Name', 'Sales_Order__r.Name', 'Selling_UOM__c', 'Product__r.Item__r.Item_Identifier__c', 'Product__r.Item__r.Stocking_UOM__c', 'Product__r.Item__r.Packaging_UOM__c', 'Quantity_Ordered__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
            });
            util.setWhereClause('Id IN :solIds');
            sobjMap.putAll(new Map<Id, Sales_Order_Line__c>((List<Sales_Order_Line__c>) Database.query (util.getQuery())));
        }

        if ( !shlIds.isEmpty()) {
            util = new SOQLUtil('Shipment_Line__c', true);
            util.addFields(new Set<String>{
                    'id', 'Name', 'Order__c', 'Order__r.Name', 'Sales_Order_Line__r.Sales_Order__r.Name', 'Sales_Order_Line__r.Selling_UOM__c', 'Item__c', 'Item__r.Item_Identifier__c', 'Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c', 'Quantity_Planned__c', 'Facility__r.Facility_Identifier__c'
            });
            util.setWhereClause('Id IN : shlIds');
            sobjMap.putAll(new Map<Id, Shipment_Line__c>((List<Shipment_Line__c>) Database.query (util.getQuery())));
        }

        if ( !soIds.isEmpty()) {
            util = new SOQLUtil('Sales_Order__c', true);
            util.addFields(new Set<String>{
                    'id', 'Name', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
            });
            util.setWhereClause('Id IN : soIds');
            sobjMap.putAll(new Map<Id, Sales_Order__c>((List<Sales_Order__c>) Database.query (util.getQuery())));
        }

        if ( !ordIds.isEmpty()) {
            util = new SOQLUtil('Order__c', true);
            util.addFields(new Set<String>{
                    'id', 'Name', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
            });
            util.setWhereClause('Id IN : ordIds');
            sobjMap.putAll(new Map<Id, Order__c>((List<Order__c>) Database.query (util.getQuery())));
        }

        if ( !soIds.isEmpty() || !ordIds.isEmpty()) {
            util = new SOQLUtil('Item__c', true);
            util.addFields(new Set<String>{
                    'id', 'Name', 'Item_Identifier__c', 'Packaging_UOM__c', 'Stocking_UOM__c','Source__c'
            });
            util.setWhereClause('Id IN : itemIds');
            sobjMap.putAll(new Map<Id, Item__c>((List<Item__c>) Database.query (util.getQuery())));
        }

        for ( Id key : mapLabelWrapper.keySet() ) {
            List<LabelWrapper> lbls = mapLabelWrapper.get(key);
            for ( LabelWrapper lbl : lbls ) {
                SObjectType type = lbl.record.getSObjectType();
                if (type == Work_Order__c.sObjectType) {
                    lbl.record = sobjMap.get(lbl.record.Id);
                } else if (type == Sales_Order_Line__c.sObjectType) {
                    lbl.record = sobjMap.get(lbl.record.Id);
                } else if (type == Shipment_Line__c.sObjectType) {
                    lbl.record = sobjMap.get(lbl.record.Id);
                } else if ( type == Sales_Order__c.sObjectType ) {
                    lbl.record = sobjMap.get(lbl.record.Id);
                    lbl.item = (Item__c)sobjMap.get(lbl.item.id);
                } else if ( type == Order__c.sObjectType) {
                    lbl.record = sobjMap.get(lbl.record.Id);
                    lbl.item = (Item__c)sobjMap.get(lbl.item.id);
                } else {
                    throw new LabelsApiException('Unsupported SObject for Labels');
                }
            }
        }

    }

    /**
     * Generate labels for sales order or transfer order
     *
     * @param order
     * @param wrapper
     * @param mapItemPackagingUOM
     *
     * @return
     */
    static Label__c createOrderLabel (SObject order, LabelWrapper wrapper, Map<Id, List<Id>> mapItemPackagingUOM ) {
        Label__c label = new Label__c();
        Item__c itm = wrapper.item;
        Decimal fID = null;
        String name;

        label.Item__c = wrapper.item.Id;
        if ( order.getSObjectType() == Sales_Order__c.sObjectType ) {
            Sales_Order__c so = (Sales_Order__c) order;
            fID = so.Ship_From_Location__r.Facility__r.Facility_Identifier__c;
            name = so.Name;
            label.Sales_Order__c = so.Id;
        } else {
            Order__c ord = (Order__c) order;
            fID = ord.Ship_From_Location__r.Facility__r.Facility_Identifier__c;
            name = ord.Name;
            label.Order__c = ord.Id;
        }
        label.Item__c = itm.Id;

        Decimal qtyInStockingUom = wrapper.quantity *
                KSE.getConversionFactor(itm.ID, fID , wrapper.packagingUom.Id, itm.Stocking_UOM__c, mapItemPackagingUOM.get(itm.Id));
        qtyInStockingUom = qtyInStockingUom.setScale(0); // assuming always an integer in stocking uom qty
        Integer caseQtyPadding = wrapper.fromType != null && wrapper.fromType == 'Item__c'  && itm.Source__c != 'Manufactured' ? 5 : 3;

        label.Name = '01' + itm.Item_Identifier__c.right(12).rightPad(12, ' ')
                + KSE.prefixStringWithZeros (String.valueOf(qtyInStockingUom), caseQtyPadding)
                + KSE.prefixStringWithZeros (String.valueOf(wrapper.caseIndex), 3)
                + KSE.prefixStringWithZeros (name.right(8), 8);

        label.Quantity_Per_Label__c = qtyInStockingUom;
        return label;
    }

    /**
     * generate labels for Work Order 
     * Label record will be tagged with work order 
     *  
     */ 
    static List<Label__c> generateWorkOrderLabels (List<Work_Order__c> wos, Map<Id, List<LabelWrapper>> mapLabelWrapper) {
        List<Label__c> labels = new List<Label__c> ();
        SOQLUtil util = new SOQLUtil ('Work_Order__c', true);
        util.addFields(new Set<String> {'id', 'name',  'Order_Quantity__c', 'Item__r.Item_Identifier__c', 'Packaging_UOM__c', 'Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c', 'Facility__c', 'Facility__r.Facility_Identifier__c' });
        util.setWhereClause('id in :wos');
        wos = Database.query(util.getQuery());
        
        Map<Id, List<Id>> mapItemPackagingUOM = new Map<Id, List<Id>> ();
        for ( Work_Order__c wo : wos ){
            if (!mapItemPackagingUOM.containsKey (wo.Item__c)) {
                List<Id> lstPkgUom = (List<Id>) JSON.deserialize(wo.Item__r.Packaging_UOM__c, List<Id>.class);
                mapItemPackagingUOM.put(wo.Item__c, lstPkgUom);
            }

            if ( mapLabelWrapper.containsKey(wo.Id)) {
                for ( LabelWrapper wrapper : mapLabelWrapper.get(wo.Id) ) {
                    labels.add( createWorkOrderLabels(wo, wrapper, mapItemPackagingUOM));
                }
            } else {
                Decimal orderQty = wo.Order_Quantity__c;
                Integer labelCount = Math.ceil(orderQty).intValue();
                for (Integer i = 1; i <= labelCount; i++) {
                    Decimal qty = orderQty >= 1 ? 1 : orderQty;
                    LabelWrapper wrapper = new LabelWrapper();
                    wrapper.caseIndex = i;
                    wrapper.quantity = qty;
                    wrapper.packagingUom = new UOM__c(Id=wo.Packaging_UOM__c);
                    labels.add(createWorkOrderLabels(wo, wrapper, mapItemPackagingUOM));
                    orderQty -= 1;
                }
            }
        }
        
        DML.insertAsUser(labels);
        return labels;
    }

    static Label__c createWorkOrderLabels (Work_Order__c wo, LabelWrapper wrapper,Map<Id, List<Id>> mapItemPackagingUOM ) {

        Decimal qtyInStockingUom = wrapper.quantity * KSE.getConversionFactor(wo.Item__c, wo.Facility__r.Facility_Identifier__c, wrapper.packagingUom.Id, wo.Item__r.Stocking_UOM__c, mapItemPackagingUOM.get(wo.Item__c));
        qtyInStockingUom = qtyInStockingUom.setScale(0); // assuming always an integer in stocking uom qty

        Integer caseQtyPadding = wrapper.fromType != null && wrapper.fromType == 'Item__c' ? 5 : 3;
        Label__c label = new Label__c();
        label.Name = '01' + wo.Item__r.Item_Identifier__c.right(12).rightPad(12, ' ')
                + KSE.prefixStringWithZeros (String.valueOf(qtyInStockingUom), caseQtyPadding)
                + KSE.prefixStringWithZeros (String.valueOf(wrapper.caseIndex), 3)
                + KSE.prefixStringWithZeros (wo.Name.right(8), 8);
        label.Work_Order__c = wo.Id;
        label.Quantity_Per_Label__c = qtyInStockingUom;
        return label;
    }

    /**
     * generate labels for Sales Order 
     * Label record will be tagged with sales order 
     *  
     */ 
    static List<Label__c> generateSalesOrderLabels (List<Sales_Order__c> sos, Map<Id, List<LabelWrapper>> mapLabelWrapper) {
        List<Label__c> labels = new List<Label__c> ();
        Set<Id> solIds = new Set<Id>();
        SOQLUtil util = new SOQLUtil ('Sales_Order_Line__c', true);
        util.addFields( new Set<String>{'id','Name', 'Sales_Order__r.Name', 'Selling_UOM__c', 'Product__r.Item__r.Item_Identifier__c', 'Product__r.Item__r.Stocking_UOM__c','Product__r.Item__r.Packaging_UOM__c', 'Quantity_Ordered__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'});
        if (mapLabelWrapper.isEmpty() ) {
            util.setWhereClause('Sales_Order__c in :sos');
        } else {
            solIds = mapLabelWrapper.keySet();
            util.setWhereClause('Id IN :solIds');
        }
        List<Sales_Order_Line__c> sols = Database.query (util.getQuery());
        
        Map<Id, List<Id>> mapItemPackagingUOM = new Map<Id, List<Id>> ();
        for ( Sales_Order_Line__c sol : sols ) {
            if ( !mapItemPackagingUOM.containsKey (sol.Product__r.Item__c) ) {
                List<Id> lstPkgUom = (List<Id>) JSON.deserialize( sol.Product__r.Item__r.Packaging_UOM__c, List<Id>.class );
                mapItemPackagingUOM.put(sol.Product__r.Item__c, lstPkgUom);
            }

            if ( mapLabelWrapper.containsKey(sol.Id)) {
                for ( LabelWrapper wrapper : mapLabelWrapper.get(sol.Id) ) {
                    labels.add( createSalesOrderLineLabel(sol, wrapper, mapItemPackagingUOM));
                }
            } else {
                Decimal orderQty = sol.Quantity_Ordered__c;
                Integer labelCount = Math.ceil(orderQty).intValue();
                for (Integer i = 1; i <= labelCount; i++) {
                    Decimal qty = orderQty >= 1 ? 1 : orderQty;
                    LabelWrapper wrapper = new LabelWrapper();
                    wrapper.caseIndex = i;
                    wrapper.quantity = qty;
                    wrapper.packagingUom = new UOM__c(Id=sol.Selling_UOM__c);
                    labels.add(createSalesOrderLineLabel(sol, wrapper, mapItemPackagingUOM));
                    orderQty -= 1;
                }
            }
        }
        
        DML.insertAsUser(labels);
        return labels;
    }

    static Label__c createSalesOrderLineLabel (Sales_Order_Line__c sol, LabelWrapper wrapper,Map<Id, List<Id>> mapItemPackagingUOM ) {
        Decimal qtyInStockingUom = wrapper.quantity * KSE.getConversionFactor( sol.Product__r.Item__c, sol.Ship_From_Location__r.Facility__r.Facility_Identifier__c, wrapper.packagingUom.Id, sol.Product__r.Item__r.Stocking_UOM__c, mapItemPackagingUOM.get(sol.Product__r.Item__c));
        qtyInStockingUom = qtyInStockingUom.setScale(0);

        Integer caseQtyPadding = wrapper.fromType != null && wrapper.fromType == 'Item__c' ? 5 : 3;
        Label__c label = new Label__c ();
        label.Name = '01'   + sol.Product__r.Item__r.Item_Identifier__c.right(12).rightPad(12, ' ')
                + KSE.prefixStringWithZeros ( String.valueOf( qtyInStockingUom ), caseQtyPadding )
                + KSE.prefixStringWithZeros ( String.valueOf(wrapper.caseIndex), 3 )
                + KSE.prefixStringWithZeros(sol.Sales_Order__r.Name.right(8), 8);
        label.Sales_Order_Line__c = sol.Id;
        label.Quantity_Per_Label__c = qtyInStockingUom;
        return label;
    }

    /**
     * generate labels for Shipment
     * Label record will be tagged with shipment
     *  
     */ 
    static List<Label__c> generateShipmentLabels (List<Shipment__c> shipments, Map<Id, List<LabelWrapper>> mapLabelWrapper) {
        List<Label__c> labels = new List<Label__c> ();
        Set<Id> shlIds = new Set<Id>();
        SOQLUtil util = new SOQLUtil ('Shipment_Line__c', true);
        util.addFields( new Set<String>{'id','Name', 'Order__c', 'Order__r.Name', 'Sales_Order_Line__r.Sales_Order__r.Name', 'Sales_Order_Line__r.Selling_UOM__c', 'Item__c', 'Item__r.Item_Identifier__c', 'Item__r.Stocking_UOM__c','Item__r.Packaging_UOM__c', 'Quantity_Planned__c', 'Facility__r.Facility_Identifier__c'});
        if (mapLabelWrapper.isEmpty() ) {
            util.setWhereClause('Shipment__c in :shipments');
        } else {
            shlIds = mapLabelWrapper.keySet();
            util.setWhereClause('Id IN : shlIds');
        }
        List<Shipment_Line__c> shls = Database.query (util.getQuery());
        
        Map<Id, List<Id>> mapItemPackagingUOM = new Map<Id, List<Id>> ();
        for ( Shipment_Line__c shl : shls ) {
            if ( !mapItemPackagingUOM.containsKey (shl.Item__c) ) {
                List<Id> lstPkgUom = (List<Id>) JSON.deserialize( shl.Item__r.Packaging_UOM__c, List<Id>.class );
                mapItemPackagingUOM.put(shl.Item__c, lstPkgUom);
            }

            if ( mapLabelWrapper.containsKey(shl.Id)) {
                for ( LabelWrapper wrapper : mapLabelWrapper.get(shl.Id) ) {
                    labels.add( createShipmentLineLabel(shl, wrapper, mapItemPackagingUOM));
                }
            } else {
                Decimal orderQty = shl.Quantity_Planned__c;
                Integer labelCount = Math.ceil(orderQty).intValue();
                Id uomId = shl.Order__c != null ? shl.Item__r.Stocking_UOM__c : shl.Sales_Order_Line__r.Selling_UOM__c;

                for (Integer i = 1; i <= labelCount; i++) {
                    Decimal qty = orderQty >= 1 ? 1 : orderQty;
                    LabelWrapper wrapper = new LabelWrapper();
                    wrapper.caseIndex = i;
                    wrapper.quantity = qty;
                    wrapper.packagingUom = new UOM__c(Id=uomId);
                    labels.add(createShipmentLineLabel(shl, wrapper, mapItemPackagingUOM));
                    orderQty -= 1;
                }
            }
        }
        
        DML.insertAsUser(labels);
        return labels;
    }

    static Label__c createShipmentLineLabel (Shipment_Line__c shl, LabelWrapper wrapper,Map<Id, List<Id>> mapItemPackagingUOM) {
        Decimal qtyInStockingUom = wrapper.quantity * KSE.getConversionFactor( shl.Item__c, shl.Facility__r.Facility_Identifier__c, wrapper.packagingUom.Id, shl.Item__r.Stocking_UOM__c, mapItemPackagingUOM.get(shl.Item__c));
        qtyInStockingUom = qtyInStockingUom.setScale(0);
        Label__c label = new Label__c ();
        String orderName = '';
        if ( shl.Order__c != null ) {
            orderName = shl.Order__r.Name;
        } else {
            orderName = shl.Sales_Order_Line__r.Sales_Order__r.Name;
        }
        Integer caseQtyPadding = wrapper.fromType != null && wrapper.fromType == 'Item__c' ? 5 : 3;
        label.Name = '01'   + shl.Item__r.Item_Identifier__c.right(12).rightPad(12, ' ')
                + KSE.prefixStringWithZeros ( String.valueOf( qtyInStockingUom), caseQtyPadding )
                + KSE.prefixStringWithZeros ( String.valueOf(wrapper.caseIndex), 3 )
                + KSE.prefixStringWithZeros(orderName.right(8), 8);
        label.Shipment_Line__c = shl.Id;
        label.Quantity_Per_Label__c = qtyInStockingUom;
        return label;
    }

    public static void purgeLabels ( List<Label__c> labels ) {
        if ( labels != null && !labels.isEmpty() )
            delete labels;
    }

    public class GenerateSingleLabels implements Action.Target {
        public Action.Response execute(Object obj) {
            Action.Response resp = new Action.Response ();
            try {
                Map<Id, List<LabelWrapper>> mapLabelWrapper = (Map<Id, List<LabelWrapper>>) JSON.deserialize(String.valueOf(obj), Map<Id, List<LabelWrapper>>.class);
                resp.result = new Action.Result();
                resp.result.resultObject = LabelsApi.generateSingleLabels(mapLabelWrapper);
                resp.success = true;
            } catch ( Exception ex) {
                System.debug(LoggingLevel.DEBUG, ex.getMessage());
                System.debug(LoggingLevel.DEBUG, ex.getStackTraceString());
                resp.success = false;
            }
            return resp;
        }
    }

    global class GenerateLabels implements Action.Target {
        global Action.Response execute(Object obj){
            
            List<Sobject> sobjs = (List<SObject>) JSON.deserialize(String.valueof(obj), List<SObject>.class);
            Action.Response resp = new Action.Response ();
            try {
                resp.result = new Action.Result();
                resp.result.resultObject = LabelsApi.generateLabels(sobjs);
                resp.success = true;
            } catch ( Exception ex) {
                System.debug(LoggingLevel.DEBUG, ex.getMessage());
                System.debug(LoggingLevel.DEBUG, ex.getStackTraceString());
                resp.success = false;
            }
            return resp;
        }
    }

    public class GenerateHeterogeneousLabels implements Action.Target {
        public Action.Response execute(Object obj){
            Action.Response resp = new Action.Response ();
            try {
                Map<Id, List<LabelWrapper>> mapLabelWrapper = (Map<Id, List<LabelWrapper>>) JSON.deserialize(String.valueOf(obj), Map<Id, List<LabelWrapper>>.class);
                resp.result = new Action.Result();
                resp.result.resultObject = LabelsApi.generateHeterogeneousLabels(mapLabelWrapper);
                resp.success = true;
            } catch ( Exception ex) {
                System.debug(LoggingLevel.DEBUG, ex.getMessage());
                System.debug(LoggingLevel.DEBUG, ex.getStackTraceString());
                resp.success = false;
            }
            return resp;
        }
    }
    
    global class PurgeLabels implements Action.Target {
        global Action.Response execute(Object obj){
            List<Sobject> sobjs = (List<SObject>) JSON.deserialize(String.valueof(obj), List<SObject>.class);
            Action.Response resp = new Action.Response ();
            try {
                LabelsApi.purgeLabels(sobjs);
                resp.result = new Action.Result();
                resp.success = true;
            } catch ( Exception ex) {
                resp.success = false;
            }
            return resp;
        }
    }
}