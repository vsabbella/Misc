public with sharing class WOUndoReleaseExtension {

    private ApexPages.StandardSetController setCon;
    private Set<Id> woIds = new Set<Id>();
    public Boolean disable { get; set; } { disable = false; }

    public WOUndoReleaseExtension(ApexPages.StandardSetController controller) {
        setCon = controller;
        if (setCon.getSelected().size() == 0)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.No_Work_Orders_Selected));
        else if (setCon.getSelected().size() > 10)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.You_can_only_process_up_to_10_records_at_a_time));
        if (ApexPages.hasMessages()) {
        	disable = true;
        	return;
        }
        
        for (Work_Order__c wo:(List<Work_Order__c>)setCon.getSelected())
            woIds.add(wo.Id);

        try {
            WorkOrderPlanningService.validateForUndoRelease(WorkOrderService.getWorkOrders(woIds,null,null,new Set<String>{ 'Material_Trackings__r','Operation_Trackings__r' }));
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            disable = true;
        }
    }

    public PageReference undoRelease() {
        Savepoint sp = Database.setSavepoint();
        try { 
            WorkOrderPlanningService.undoRelease(woIds);
        } catch(Exception e) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            disable = true;
        }
        return ApexPages.hasMessages(ApexPages.Severity.FATAL) ? null : setCon.cancel();
    }
}