public with sharing class ShipmentManageDeliveryExtV2 extends GridRelatedListController {
    public String namespaceUU { get; set; } { namespaceUU = KSE.NamespaceUU; }
    public String shipmentJson { get; set; }
    public Boolean serialTracked { get; set; } { serialTracked = false; }
    public Boolean shipMode { get; set; } { shipMode = true; }
    public Boolean disable { get; set; } { disable = false; }

    private Shipment__c shipment;

    public ShipmentManageDeliveryExtV2(ApexPages.StandardController con) {
        shipment = getShipment(con.getId());
        
        if (shipment.Company__r.Serial_Control__c == SkidService3.AT_SHIPMENT || (shipment.Status__c == 'Confirmed' && shipment.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT)) {
            serialTracked = true;
        }
        if (shipment.Status__c == 'Confirmed') shipMode = false;
        if (shipment.Date_Shipped__c == null) shipment.Date_Shipped__c = System.now();

        shipmentJson = JSON.serialize(shipment);

        Map<Id, String> validateErrors = ShipmentInventoryService.validateForShip(new List<Shipment__c>{ shipment }, shipMode);
        if (validateErrors.containsKey(shipment.Id)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(validateErrors.get(shipment.Id))));
            disable = true;
        }
    }

    public static Shipment__c getShipment(Id shipmentId) { return Database.query(getShipmentQuery('Id = :shipmentId')); }
    public static String getShipmentQuery(String whereClause) {
        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addFields('ManageDeliveryHeader');
        shipmentQuery.addFields('ManageDeliveryHeaderRO');
        shipmentQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Date_Shipped__c', 'Status__c', 'Transaction_Date__c', 'Company__r.Serial_Control__c',
            'Customer__r.Top_Parent_Customer__r.Status__c' });
        shipmentQuery.setWhereClause(whereClause);

        SOQLUtil.ChildRelationship shlQuery = new SOQLUtil.ChildRelationship(shipmentQuery, 'Shipment_Lines__r');
        shlQuery.addFields(new Set<String>{ 'Id', 'Name', 'Item__c', 'Quantity_Picked__c', 'Sales_Order__c', 'Sales_Order_Line__c', 'Item__r.Non_Inventory__c',
            'Item__r.Stocking_UOM__c', 'Sales_Order__r.Hold__c', 'Sales_Order__r.Released_to_3PL__c', 'Sales_Order__r.Ship_Complete__c',
            'Sales_Order_Line__r.Quantity_Ordered__c', 'Sales_Order_Line__r.Selling_UOM__c','Product__r.Item__c','Product__r.Item__r.Packaging_UOM__c','Product__r.Item__r.Stocking_UOM__c',
            'Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c', 'Facility__r.Facility_Identifier__c'
        });
        shipmentQuery.addChildRelationship(shlQuery);

        return shipmentQuery.getQuery();
    }

    @RemoteAction
    public static JsonResult getShipmentLineData(Id shipmentId, Boolean shipMode) {
        JsonResult result = new JsonResult();
        try {
            List<LineWrapper> shlWrappers = ShipmentInventoryService.getLinesForShip(new Set<Id>{ shipmentId }, shipMode);

            if (shipMode) {
                for (LineWrapper shlWrapper:shlWrappers) {
                    Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;

                    Decimal totalPicked = 0;
                    for (SkidService3.SerialWrapper sw:shlWrapper.serialWrappers) totalPicked += sw.skid.Quantity_Stocking_UOM__c;

                    if (totalPicked != shl.Quantity_Picked__c) throw new CustomException(shl.Name + ': ' + Label.Quantity_picked_does_not_match_total_quantity_on_skids);
                }
            }

            result.records = shlWrappers;
            result.total = result.records.size();
        } catch (Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static Id queueSave(Shipment__c shipment, List<LineWrapper> shlWrappers, List<String> shipmentDateFields, List<String> skidDateFields, List<String> serialDateFields, Boolean shipMode) {
        return System.enqueueJob(new ShipJob(shipment, shlWrappers, shipmentDateFields, skidDateFields, serialDateFields, shipMode));
    }

    @RemoteAction
    public static AsyncApexJob getJobStatus(Id jobId) {
        SOQLUtil jobQuery = new SOQLUtil('AsyncApexJob');
        jobQuery.addFields(new Set<String>{ 'Id', 'Status', 'ExtendedStatus' });
        jobQuery.setWhereClause('Id = :jobId');
        AsyncApexJob job = Database.query(jobQuery.getQuery());
        return job;
    }

    private class ShipJob implements Queueable {
        private Shipment__c shipment;
        private List<LineWrapper> shlWrappers;
        private List<String> shipmentDateFields;
        private List<String> skidDateFields;
        private List<String> serialDateFields;
        private Boolean shipMode;

        public ShipJob(Shipment__c shipment, List<LineWrapper> shlWrappers, List<String> shipmentDateFields, List<String> skidDateFields, List<String> serialDateFields, Boolean shipMode) {
            this.shipment = shipment;
            this.shlWrappers = shlWrappers;
            this.shipmentDateFields = shipmentDateFields;
            this.skidDateFields = skidDateFields;
            this.serialDateFields = serialDateFields;
            this.shipMode = shipMode;
        }

        public void execute(QueueableContext qc) {
            JsonResult result = ShipmentManageDeliveryExtV2.save(shipment, shlWrappers, shipmentDateFields, skidDateFields, serialDateFields, shipMode);
            if (!result.success) throw new CustomException(result.messages[0].get('message'));
        }
    }

    public static JsonResult save(Shipment__c shipment, List<LineWrapper> shlWrappers, List<String> shipmentDateFields, List<String> skidDateFields, List<String> serialDateFields, Boolean shipMode) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try {
            if (shipMode == false && shipment.Transaction_Type__c == 'Logical Sales Order Shipment') throw new CustomException(shipment.Name + ': ' + Label.Cannot_undo_shipment_for_a_drop_ship_sales_order);
            
            List<String> attributes = SkidService3.attributesForPutaway();

            KendoUtils.UpdateDateFields(shipment, shipmentDateFields);
            shipment.Company__c = shipment.Company__r.Id;

            Map<Id, LineWrapper> wrapperMap = new Map<Id, LineWrapper>();
            for (LineWrapper wrapper:ShipmentInventoryservice.getLinesForShip(new Set<Id>{ shipment.Id }, shipMode)) wrapperMap.put(wrapper.line.Id, wrapper);

            for (LineWrapper wrapper:shlWrappers) {
                wrapper.header = shipment;
                Shipment_Line__c shl = (Shipment_Line__c)wrapper.line;

                if (wrapperMap.containsKey(shl.Id) == false) throw new CustomException(shl.Name + ': Shipment line is not available');

                LineWrapper queriedWrapper = wrapperMap.get(shl.Id);
                shl = (Shipment_Line__c)queriedWrapper.line;
                wrapper.line = shl;

                Map<List<String>, SkidService3.SerialWrapper> requeriedSkidMap = new Map<List<String>, SkidService3.SerialWrapper>();
                for (SkidService3.SerialWrapper sw:queriedWrapper.serialWrappers) requeriedSkidMap.put(SkidService3.generateKey(sw.skid, attributes), sw);

                List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    KendoUtils.UpdateDateFields(sw.skid, skidDateFields);

                    List<String> skidKey = SkidService3.generateKey(sw.skid, attributes);
                    if (requeriedSkidMap.containsKey(skidKey) == false) throw new CustomException(shl.Name + ': Inventory could not be found');

                    SkidService3.SerialWrapper requeriedSkid = requeriedSkidMap.get(skidKey);
                    requeriedSkid.skid.Quantity__c = sw.skid.Quantity__c;
                    requeriedSkid.skid.Item__r = shl.Item__r;

                    Map<Id, Serial__c> requeriedSerials = new Map<Id, Serial__c>(requeriedSkid.serialList);
                    for (Serial__c serial:sw.serialList) {
                        KendoUtils.UpdateDateFields(serial, serialDateFields);

                        if ((shipment.Company__r.Serial_Control__c != SkidService3.AT_SHIPMENT || shipMode == false) && requeriedSerials.containsKey(serial.Id) == false) {
                            throw new CustomException(shl.Name + ': Serial ' + serial.Name + ' could not be found');
                        }
                    }

                    requeriedSkid.serialList = sw.serialList;
                    swList.add(requeriedSkid);
                }

                wrapper.serialWrappers = swList;
            }

            if (shipMode) ShipmentInventoryService.confirmShip(shlWrappers);
            else ShipmentInventoryService.undoShip(shlWrappers);
        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult rerelease(Id shipmentId) {
        return ShipmentRereleaseService.rerelease(new Set<Id>{ shipmentId });
    }
    
    public String headerFieldListJson {
        get {
            if (headerFieldListJson == null) {
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('Shipment__c', 'ManageDeliveryHeaderRO', null, true);
                fiList.remove(0);   //Remove id

                List<FieldInfo> editableFields = FieldInfo.fetchJsonFieldInfos('Shipment__c', 'ManageDeliveryHeader');
                editableFields.remove(0);   //Remove id
                for (FieldInfo fi:editableFields) {
                    if (fi.field == 'Date_Shipped__c' && shipMode == false) {
                        fi.editable = false;
                        break;
                    }
                }
                fiList.addAll(editableFields);

                headerFieldListJson = JSON.serialize(fiList);
            }
            return headerFieldListJson;
        } set;
    }

    public String shipmentLineConfigJson {
        get {
            if (shipmentLineConfigJson == null) {
                GridRelatedListConfig config = new GridRelatedListConfig();
                config.buttons = 'Expand All,Collapse All';
                shipmentLineConfigJson = JSON.serialize(config);
            }
            return shipmentLineConfigJson;
        } set;
    }

    public String shipmentLineFieldListJson {
        get {
            if (shipmentLineFieldListJson == null) {
                List<FieldInfo> shipmentLineFields = FieldInfo.fetchJsonFieldInfos('Shipment_Line__c', 'ConfirmShip', null, true);
                shipmentLineFields.remove(0);   //Remove id
                for (FieldInfo fi:shipmentLineFields) fi.field = 'line.' + fi.field;
                shipmentLineFieldListJson = JSON.serialize(shipmentLineFields);
            }
            return shipmentLineFieldListJson;
        } set;
    }

    public String skidFieldListJson {
        get {
            if (skidFieldListJson == null) {
                List<String> skidFields = SkidService3.attributesForPutaway();
                skidFields.addAll(new List<String>{ 'Quantity__c', 'Quantity_Stocking_UOM__c' });

                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c', skidFields);
                for (FieldInfo fi:fiList) fi.field = 'skid.' + fi.field;
                skidFieldListJson = JSON.serialize(fiList);
            }
            return skidFieldListJson;
        } set;
    }

    public String serialFieldListJson {
        get {
            if (serialFieldListJson == null) serialFieldListJson = JSON.serialize(serialFieldList);
            return serialFieldListJson;
        } set;
    }

    public String serialAttributesJson {
        get {
            if (serialAttributesJson == null) serialAttributesJson = JSON.serialize(SkidService3.serialAttributes);
            return serialAttributesJson;
        } set;
    }

    public List<FieldInfo> serialFieldList {
        get {
            if (serialFieldList == null) {
                FieldInfo fi = new FieldInfo('','','integer');
                fi.editable = false;
                serialFieldList = new List<FieldInfo>{ fi };
                serialFieldList.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c', 'Serial', SkidService3.serialAttributes.size() > 0 ? String.join(SkidService3.serialAttributes, ',') : null, false));

                for (FieldInfo fInfo:serialFieldList) {
                    if (fInfo.field.toLowerCase() == 'fixed_asset__c') {
                        fInfo.editable = false;
                        break;
                    }
                }
            }
            return serialFieldList;
        } set;
    }

    public Integer gridSize {
        get {
            if (gridSize == null) gridSize = serialFieldList.size() * 150;
            return gridSize;
        } set;
    }

    public PageReference cancel() { return new PageReference('/' + shipment.Id); }
}