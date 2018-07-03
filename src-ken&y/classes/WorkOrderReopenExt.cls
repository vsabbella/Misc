public with sharing class WorkOrderReopenExt {
    private Id woId;
    
    public Boolean disable { get; set; } { disable = false; }

    public WorkOrderReopenExt(ApexPages.StandardController con) {
        try {
            Work_Order__c wo;
            try {
                woId = con.getId();
                wo = WorkOrderService.getWorkOrders(new Set<Id>{ woId }, null, null, null)[0];
            } catch (Exception e) {
                throw new WorkOrderReopenException(Label.Invalid_work_order_Id);
            }

            if (wo.Status__c != WorkOrderService.WO_STATUS_CLOSED) {
                throw new WorkOrderReopenException(Label.Cannot_Reopen_Work_Order + wo.Status__c);
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            disable = true;
        }
    }
    
    public PageReference reopen() {
        try {
            WorkOrderService.reopen(new Set<Id>{ woId });
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            return null;
        }
        return new PageReference('/' + woId);
    }

    private class WorkOrderReopenException extends Exception { }
}