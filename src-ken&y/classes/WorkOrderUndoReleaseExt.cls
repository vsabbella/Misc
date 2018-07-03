public with sharing class WorkOrderUndoReleaseExt {

    private ApexPages.StandardController con;
    
    public WorkOrderUndoReleaseExt(ApexPages.StandardController controller) {
        con = controller;
    }
     
    public PageReference undoRelease() {
        Savepoint sp = Database.setSavepoint();
        try {
            WorkOrderPlanningService.undoRelease(new Set<Id>{ con.getId() });
        } catch(Exception e) {
            Database.rollback(sp);

            String msg;
            if (e instanceof DMLException) {
                msg = e.getDmlMessage(0);
            } else {
                msg = e.getMessage();
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(msg)));
        }
        return ApexPages.hasMessages() ? null : con.cancel(); 
    }
}