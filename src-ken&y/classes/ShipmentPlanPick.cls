public with sharing class ShipmentPlanPick implements Database.Batchable<Shipment__c>, Database.Stateful {

    public List<Id> shipmentIds;
    public ShipmentPlanPick(ApexPages.StandardSetController con) { shipmentIds = new List<Id>((new Map<Id, Shipment__c>((List<Shipment__c>)con.getSelected())).keySet()); }
    public PageReference massRedirect() {
        PageReference pr = Page.ShipmentPlanPick;
        pr.getParameters().put('recs', String.join(shipmentIds, ','));
        return pr;
    }

    public List<Shipment__c> shipments { get; set; }
    public ShipmentPlanPick() {
        String idString = ApexPages.currentPage().getParameters().get('recs');
        if (String.isNotBlank(idString) == true) {
            List<String> ids = idString.split(',');
            SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
            shipmentQuery.addFields(new Set<String>{ 'Id', 'Name' });
            shipmentQuery.setWhereClause('Id IN :ids');
            shipments = Database.query(shipmentQuery.getQuery());
        }

        if (shipments == null || shipments.size() == 0) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No shipments were selected.'));
    }

    public void executeBatch() {
        if (shipments != null && shipments.size() > 0) {
            Integer batchSize = 1;
            try { batchSize = Integer.valueOf(Configuration__c.getInstance('SHIPMENTPLANPICKBATCH').Value__c); } catch (Exception e) { }
            Database.executeBatch(this, batchSize);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Shipments are being planned for pick. You will receive an email when the job has completed.'));
        }
    }
    public List<Shipment__c> start(Database.BatchableContext bc) { return shipments; }

    List<Notify.Message> errors = new List<Notify.Message>();
    public void execute(Database.BatchableContext bc, List<Shipment__c> shipments) {
        for (Shipment__c shipment:shipments) {
            try {
                ScannerService.planShipment(shipment.Id);
            } catch (Exception e) {
                errors.add(new Notify.Message(shipment.Name + ' can\'t be planned.', e.getMessage()));
            }
        }
    }
    public void finish(Database.BatchableContext bc) {
        Notify.sendEmailBatchFinishBuildBody(errors.size(), null, errors, bc);
    }
}