public with sharing class WorkOrderCancelExt {
    private Id woId;

    public WorkOrderCancelExt(ApexPages.StandardController con) { woId = con.getId(); }
    
    public PageReference cancel() {
        Savepoint sp = Database.setSavepoint();
        try {
            WorkOrderService.validateForCancel(new Set<Id>{ woId });
            WorkOrderService.closeCancel(new Set<Id>{ woId }, WorkOrderService.WO_STATUS_CANCELLED);
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        return null;
    }
}