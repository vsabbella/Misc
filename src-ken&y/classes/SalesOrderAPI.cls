global with sharing class SalesOrderAPI {
    global static Map<Id,SalesOrderAPIStatus> release(Map<Id,SalesOrderWrapper> salesOrderWrappers) {
        if (salesOrderWrappers == null || salesOrderWrappers.size() == 0)
            return null;
        salesOrderWrappers = salesOrderWrappers.clone();
        Map<Id,SalesOrderAPIStatus> result = new Map<Id,SalesOrderAPIStatus>();
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        Set<Id> soIds = salesOrderWrappers.keySet();
        
        SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id'
        });
        soql.setWhereClause('Id IN :soIds');

        Map<Id,Sales_Order__c> salesOrders = new Map<Id,Sales_Order__c>((List<Sales_Order__c>)Database.query(soql.getQuery()));

        for (Id salesOrderId:salesOrderWrappers.keySet()) {
            SalesOrderService sos = new SalesOrderService();
            if (!salesOrders.containsKey(salesOrderId)) {
                result.put(salesOrderId,createErrorResult(Label.Invalid_sales_order_Id));
                continue;
            }
            try {
                sos.plan(salesOrderId);
                if (ExceptionService.hasErrors) {
                    Set<Map<String,String>> messages = ExceptionService.messages;
                    String errorMessage = '';
                    Integer i=0;
                    for (Map<String,String> message:messages) {
                        if (i != 0)
                            errorMessage += ' // ';
                        errorMessage += message.get('message');
                        i++;
                    }
                    result.put(salesOrderId,createErrorResult(errorMessage));   
                } else {
                    result.put(salesOrderId,createSuccessResult());
                }
            } catch (Exception e) {
                result.put(salesOrderId,createErrorResult(e.getMessage()));
            }
        }
        return result;
    }

    global static Map<Id,SalesOrderAPIStatus> close(Map<Id,SalesOrderWrapper> salesOrderWrappers) {
        if (salesOrderWrappers == null || salesOrderWrappers.size() == 0)
            return null;
        salesOrderWrappers = salesOrderWrappers.clone();
        Map<Id,SalesOrderAPIStatus> result = new Map<Id,SalesOrderAPIStatus>();

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        Set<Id> soIds = salesOrderWrappers.keySet();
        
        SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Status__c'
        });
        soql.setWhereClause('Id IN :soIds');

        Map<Id,Sales_Order__c> salesOrders = new Map<Id,Sales_Order__c>((List<Sales_Order__c>)Database.query(soql.getQuery()));

        List<Sales_Order_Line__c> linesToClose = new List<Sales_Order_Line__c>();
        for (Id salesOrderId:salesOrderWrappers.keySet()) {
            String errorMessage = '';
            if (!salesOrders.containsKey(salesOrderId)) {
                errorMessage = Label.Invalid_sales_order_Id;
            } else {
                Sales_Order__c salesOrder = salesOrders.get(salesOrderId);
                if (salesOrder.Status__c != 'Open')
                    errorMessage = Label.SO_not_open;
                else
                    salesOrder.Status__c = SalesOrderService.SO_STATUS_CLOSED;
            }
            if (errorMessage != '') {
                result.put(salesOrderId,createErrorResult(errorMessage));
                salesOrderWrappers.remove(salesOrderId);
                salesOrders.remove(salesOrderId);
            }
        }
        List<Database.SaveResult> saveResults = DML.updateAsUser(salesOrders.values(), false);
        for (Integer i=0;i<salesOrders.values().size();i++) {
            Database.SaveResult sr = saveResults[i];
            Sales_Order__c salesOrder = salesOrders.values()[i];
            if (sr.isSuccess())
                result.put(salesOrder.Id,createSuccessResult());
            else
                result.put(salesOrder.Id,createErrorResult(sr.getErrors()[0].getMessage()));
        }
        return result;
    }


    global class SalesOrderWrapper {
        global Id salesOrderId { get; private set; }
        global Map<Id,SalesOrderLineWrapper> lines { get; private set; }
        global SalesOrderWrapper(Id soId) { 
            salesOrderId = soId;
            lines = new Map<Id,SalesOrderLineWrapper>(); 
        }
    }
    global class SalesOrderAPIStatus {
        global Boolean success { get; set; }
        global String errorMessage { get; set; }
    }
    private static SalesOrderAPIStatus createErrorResult(String errorMessage) {
        SalesOrderAPIStatus status = new SalesOrderAPIStatus();
        status.success = false;
        status.errorMessage = errorMessage;
        return status;
    }
    private static SalesOrderAPIStatus createSuccessResult() {
        SalesOrderAPIStatus status = new SalesOrderAPIStatus();
        status.success = true;
        return status;
    }


    // DEPRECATED
    global static Map<Id, SalesOrderAPIStatus> allocate(Map<Id, SalesOrderWrapper> salesOrderWrappers) { throw new CustomException('Deprecated'); }
    global static Map<Id, SalesOrderAPIStatus> unallocate(Map<Id, SalesOrderWrapper> salesOrderWrappers) { throw new CustomException('Deprecated'); }
    global static Map<Id, SalesOrderAPIStatus> pick(Map<Id ,SalesOrderWrapper> salesOrderWrappers) { throw new CustomException('Deprecated'); }
    global static Map<Id, SalesOrderAPIStatus> confirmShip(Map<Id, SalesOrderWrapper> salesOrderWrappers) { throw new CustomException('Deprecated'); }
    global static void ship(SalesOrderWrapper salesOrder, Boolean allocate) { throw new CustomException('Deprecated'); }

    global class SalesOrderLineWrapper {
        global List<PickedQuantity> quantities { get; private set; }
        global Set<Id> allocatedSkids { get; private set; }
        global SalesOrderLineWrapper() { throw new CustomException('Deprecated'); }
    }

    global class PickedQuantity {
        global Decimal qtyShipped { get; set; }
        global String lot { get; set; }
        global Date expirationDate { get; set; }
        global Date dateReceived { get; set; }
        global String bin { get; set; }
        global Map<String,Object> attributes { get; private set; }
        global PickedQuantity() { throw new CustomException('Deprecated'); }
    }

    global class SalesOrderAPIException extends Exception {
        public SalesOrderAPIException(Object obj) { throw new CustomException('Deprecated'); }
    }
}