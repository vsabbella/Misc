public with sharing class WorkOrderClosedExt {
    public Boolean disableCloseButton { get; set; } { disableCloseButton = false; }

    
    private ApexPages.StandardController con;
    
    public WorkOrderClosedExt(ApexPages.StandardController controller) {
        con = controller;

        try {
            WorkOrderService.validateForClose(new Set<Id>{ con.getId() });
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            disableCloseButton = true;
        }
    }
    
    public void closeWorkOrder() {
        Savepoint sp = Database.setSavepoint();
        try {
            WorkOrderService.closeCancel(new Set<Id>{ con.getId() }, WorkOrderService.WO_STATUS_CLOSED);
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            disableCloseButton = true;
            return;
        }
        return;
    }
}