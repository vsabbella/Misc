@isTest
public with sharing class WorkOrderCancelExtTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.workOrder != null);

        Product__c product = f.newProduct();
        product.Item__c = f.itemList[5].Id;
        insert product;
        f.product = product;

        System.assert(f.salesOrder != null);
        System.assert(f.salesOrderLines != null);
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void alreadyCancelled() {
        fuel.workOrder.Status__c = WorkOrderService.WO_STATUS_CANCELLED;
        update fuel.workOrder;

        WorkOrderCancelExt ext = new WorkOrderCancelExt(new ApexPages.StandardController(fuel.workOrder));
        ext.cancel();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.FATAL),ApexPages.getMessages());
    }

    private static testMethod void hasQuantity() {
        insert new SKID__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.workOrder.Item__c,
            Location__c = fuel.workOrder.Complete_To_Location__c,
            Quantity__c = 1,
            Type__c = SkidService3.SKID_TYPE_WIP,
            Work_Order__c = fuel.workOrder.Id
        );

        WorkOrderCancelExt ext = new WorkOrderCancelExt(new ApexPages.StandardController(fuel.workOrder));
        ext.cancel();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.FATAL),ApexPages.getMessages());

        Work_Order__c wo = [SELECT Id,Status__c FROM Work_Order__c WHERE Id = :fuel.workOrder.Id];
        System.assert(wo.Status__c != WorkOrderService.WO_STATUS_CANCELLED,'Expected WO status: "Not Cancelled" // WO status: ' + wo.Status__c);
    }

    public static testMethod void cancelSuccess() {
        WorkOrderCancelExt ext = new WorkOrderCancelExt(new ApexPages.StandardController(fuel.workOrder));
        ext.cancel();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.FATAL),ApexPages.getMessages());

        Work_Order__c wo = [SELECT Id,Status__c FROM Work_Order__c WHERE Id = :fuel.workOrder.Id];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_CANCELLED,'Expected WO status: Cancelled // WO status: ' + wo.Status__c);
    }
    public static testMethod void cancelWORemovesSOllink() {
        Date reqdDate = System.today();
        
        Sales_Order__c salesOrder = fuel.salesOrder;
        
        fuel.salesOrderLine.Fulfillment_Source__c = 'Build To Order';
        fuel.salesOrderLine.Required_Date__c = reqdDate;
        fuel.salesOrderLine.Item_Specification__c = fuel.itemSpec.Id;
        fuel.salesOrderLine.Selling_UOM__c = fuel.uomList[8].ID;
        fuel.salesOrderLine.Work_Order__c = fuel.workOrder.ID;
        
        update new List<Sales_Order_Line__c>{fuel.salesOrderLine};
        WorkOrderCancelExt ext = new WorkOrderCancelExt(new ApexPages.StandardController(fuel.workOrder));
        ext.cancel();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.FATAL),ApexPages.getMessages());

        Work_Order__c wo = [SELECT Id,Status__c FROM Work_Order__c WHERE Id = :fuel.workOrder.Id];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_CANCELLED,'Expected WO status: Cancelled // WO status: ' + wo.Status__c);
        list<Sales_Order_Line__c>soline = [select id,Work_Order__c from Sales_Order_Line__c where id = :fuel.salesOrderLine.id];
        system.assertEquals(soline[0].Work_Order__c, null);
    }
}