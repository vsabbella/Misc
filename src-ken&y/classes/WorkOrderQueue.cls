public class WorkOrderQueue implements Queueable {
    public class WorkOrderQueueException extends Exception {}
    public List<Process_Request__c> prs;
    public WorkOrderQueue (){}
    public WorkOrderQueue (List<Process_Request__c> prs){
        this.prs = prs;
    }
    
    public void execute(QueueableContext context) {
        Configuration__c bulkifyProcessRequest = Configuration__c.getValues('BULKIFY_WORK_ORDER_QUEUE');
        // Check custom settings
        Boolean isBulkifyRequests = bulkifyProcessRequest !=null && bulkifyProcessRequest.Value__c.toUpperCase() == 'TRUE' ? true : false;
        if ( isBulkifyRequests )
	        bulkifyRequestExecution();
        else 
            executeSingleRequest ();
    }
    
    void executeSingleRequest() {
        if ( this.prs != null && !this.prs.isEmpty() && this.prs[0].Status__c == 'Draft'  && (this.prs[0].Process_Call__c =='Work Order Complete' || this.prs[0].Process_Call__c =='Work Order Uncomplete') ) {
            
            SOQLUtil woQuery = new SOQLUtil ('Work_Order__c');
            woQuery.addFields( new Set<String>{'Id','Name','Contents__c', 'Item__c', 'Packaging_UOM__c','Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c'});
            woQuery.setWhereClause('Id = \''+this.prs[0].Work_Order__c+'\'');
            List<Work_Order__c> wos = Database.query(woQuery.getQuery());
            
            if ( wos[0].Contents__c != null && wos[0].Contents__c.contains(this.prs[0].Parameter_Value__c) ) {
                delete prs;
            } else {
                
                Map<String, Object> obj = new Map<String,Object>();
                obj.put('woId', this.prs[0].Work_Order__c);
                obj.put('caseNumber', this.prs[0].Parameter_Value__c);
                obj.put('caseQuantity', this.prs[0].Quantity__c);
                
                try {
                    Action.Response res;
                    if ( this.prs[0].Process_Call__c == 'Work Order Complete')
	                    res = APIGateway.doAction('RUN_WORK_ORDER_COMPLETE', JSON.serialize(obj));
                    else if ( this.prs[0].Process_Call__c == 'Work Order Uncomplete') 
                        res = APIGateway.doAction('RUN_WORK_ORDER_UNCOMPLETE', JSON.serialize(obj));
                    
                    delete prs;
                } catch (Exception e ) {
                    if ( e.getMessage().contains('Record Currently Unavailable')) {
                        System.enqueueJob(new WorkOrderQueue(this.prs));
                    } else {
                        throw e;
                    }
                }
            }
        } else {
            system.debug ('No process request...');
        }
    }
    
    void bulkifyRequestExecution () {
        Boolean reRunJob = false;
           
        SOQLUtil util = new SOQLUtil('Process_Request__c', false);
        util.addAllCustomFields();
        util.setWhereClause(' (Work_Order__r.Exceptions_Count__c = null OR Work_Order__r.Exceptions_Count__c = 0) AND Process_Call__c IN (\'Work Order Complete\', \'Work Order Uncomplete\' ) AND Status__c IN (\'Draft\') AND Work_Order__c=\''+this.prs[0].Work_Order__c+'\'');
        util.setForUpdate();
        List<Process_Request__c> requests = Database.query(util.getQuery());
        List<Process_Request__c> requestsToProcess = new List<Process_Request__c>();
        List<Process_Request__c> requestsToDelete = new List<Process_Request__c>();
        ExceptionService exService = new ExceptionService();

        if ( !requests.isEmpty()) {
            try {
                SOQLUtil woQuery = new SOQLUtil ('Work_Order__c');
                woQuery.addFields( new Set<String>{'Id','Name','Contents__c', 'Item__c', 'Packaging_UOM__c','Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c','Item__r.Name','Facility__r.Facility_Identifier__c' });
                woQuery.setWhereClause('Id = \''+requests[0].Work_Order__c+'\'');
                woQuery.setForUpdate();
                List<Work_Order__c> wos = Database.query(woQuery.getQuery());

                Decimal conversionFactor = 1;
                if ( wos != null && !wos.isEmpty()) {
                    // Ensure that work order is completed in the correct Packaging UOM
                    if (wos[0].Item__r.Packaging_UOM__c == null || wos[0].Item__r.Packaging_UOM__c.contains(wos[0].Packaging_UOM__c) == false) {
                        throw new WorkOrderQueueException('Invalid Packaging UOM for the Work Order ' + wos[0].Name);
                    }

                    List<String> packagingUOMs = (List<String>) JSON.deserialize(wos[0].Item__r.Packaging_UOM__c, List<String>.class);
                    conversionFactor = KSE.getConversionFactor( wos[0].Item__c, wos[0].Facility__r.Facility_Identifier__c, wos[0].Packaging_UOM__c, wos[0].Item__r.Stocking_UOM__c, packagingUOMs );
                } else {
                    // throw wo not found exception
                }
                
                Decimal qty = requests[0].Quantity__c;
                String processCall = requests[0].Process_Call__c;
                Boolean addFullCaseOnly = ScannerService.isfullCase( qty, conversionFactor);
                for ( Process_Request__c pr : requests ) {
                    if ( (wos[0].Contents__c != null && wos[0].contents__c.contains(pr.Parameter_Value__c) && pr.Process_Call__c == 'Work Order Complete') 
                       		|| (( wos[0].Contents__c == null || !wos[0].contents__c.contains(pr.Parameter_Value__c)) && pr.Process_Call__c == 'Work Order Uncomplete') ) {
                        requestsToDelete.add(pr);
                    } else if ( pr.Process_Call__c != processCall) {
                        continue;
                    } else {
                        qty = pr.Quantity__c ;
                        // completing either part cases or full cases only
                        if ( ScannerService.isfullCase( qty, conversionFactor) == addFullCaseOnly ) {
                            requestsToProcess.add(pr);
                        }
                    }
                }

                if ( !requestsToDelete.isEmpty()) {
                    delete requestsToDelete;
                }
                
                if ( requestsToProcess.isEmpty()) {
                    system.debug(LoggingLevel.DEBUG, 'No process request found');
                    return;
                }
                Map<String, Object> obj = new Map<String,Object>();
                String woId;
                List<String> caseNumbers = new List<String>();
                Decimal caseQuantity;
                for ( Process_Request__c pr : requestsToProcess ) {
                    woId = pr.Work_Order__c;
                    caseNumbers.add(pr.Parameter_Value__c);
                    caseQuantity = KSE.addQuantityToField(caseQuantity, pr.Quantity__c);
                }
                obj.put('woId', woId);
                obj.put('caseNumber', String.join(caseNumbers, ','));
                obj.put('caseQuantity', caseQuantity);
                obj.put('isFullCase', addFullCaseOnly);
                
                Action.Response res;

                if ( processCall == 'Work Order Complete') {
	                res = APIGateway.doAction('RUN_WORK_ORDER_COMPLETE', JSON.serialize(obj));
                } else if (processCall == 'Work Order Uncomplete') {
                    res = APIGateway.doAction('RUN_WORK_ORDER_UNCOMPLETE', JSON.serialize(obj));
                }

                if ( res.success ) {
                    delete requestsToProcess;
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, e.getMessage());
                System.debug(LoggingLevel.ERROR, e.getStackTraceString());

                if ( e.getMessage().contains('Record Currently Unavailable')) {
                    reRunJob = true;
                } else {
                    ExceptionUtil.WO_COMPLETE_EXCEPTION.description += e.getMessage();
                    exService.setException( new Work_Order__c(Id=prs[0].Work_Order__c), ExceptionUtil.WO_COMPLETE_EXCEPTION);
                    exService.finishTasks();
                }
            }
        }
        
        if ( !reRunJob ) {
            util = new SOQLUtil('Process_Request__c', false);
            util.addAllCustomFields();
            util.setOrderByClause('CreatedDate ASC');
            util.setWhereClause('Process_Call__c IN (\'Work Order Complete\', \'Work Order Uncomplete\' ) AND Status__c IN (\'Draft\') AND (Work_Order__r.Exceptions_Count__c = null OR Work_Order__r.Exceptions_Count__c = 0) AND Facility__c =\''+this.prs[0].Facility__c +'\'');
            util.setLimit(1);
            requests = Database.query(util.getQuery());
            
            if ( !requests.isEmpty() ) reRunJob = true;
        }          
        
        if ( reRunJob ) {
            System.enqueueJob(new WorkOrderQueue(requests));
        } 
    }
}