public with sharing class SalesOrderLineFlowHandler {
    
    public class SalesOrderLineState implements ProcessService.State{
        
        public integer stepcounter;
        private List<Sales_Order_Line__c> salesOrderLines;
        private Map<string, Group> mGroups;
        
        public SalesOrderLineState(){
            stepcounter = 0;
        }
        
        public Map<string, Group> queueSelector(){
            if(mGroups == null){
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('QueueSObject', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','queue.name','queue.developername','sobjecttype'
				});
				soql.setWhereClause('sobjecttype = \'Sales_Order_Line__c\'');

				List<QueueSobject> salesOrderLinesQueues = Database.query(soql.getQuery());

                mGroups = new Map<string, Group>();
                for(QueueSobject qso : salesOrderLinesQueues){
                    mGroups.put(qso.queue.developerName, qso.queue);
                }
            }
            return mGroups;
        }
        
        public List<Sales_Order_Line__c> salesOrderLineselector(List<Sales_Order_Line__c> stepsalesOrderLines){
            if(salesOrderLines == null){
                
                Schema.DescribesobjectResult obj = SchemaUtil.getInstance().getGlobalDescribe('Sales_Order_Line__c').getDescribe();
                set<String> fieldsToQuery = obj.fields.getMap().keySet();
                
                String whereClause =  'Id = :originalSOId LIMIT 1';
        
		        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c',true);
		        soql.addFields(fieldsToQuery);
		        soql.setWhereClause(whereClause);
	                
                salesOrderLines = Database.query(soql.getQuery());
            }
            
            return salesOrderLines;
        }
        
    }
    
    public class SetMeansOfTransport implements ProcessService.Action{
        
        public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
            
            SalesOrderLineState cs = (SalesOrderLineState) processState;
            cs.stepcounter++;
            
            ProcessService.Response resp = new ProcessService.Response();
            resp.state = cs;
            resp.step = null;
            
            system.debug(LoggingLevel.INFO, 'Before set means of transport');
            
            SalesOrderLineService.setMeansOfTransport(records);
            
            system.debug(LoggingLevel.INFO, 'After set means of transport');
            
            return resp;
        }
        
    }
    
    public class GenerateCustomerInvoices implements ProcessService.Action{
        
        public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
            
            SalesOrderLineState cs = (SalesOrderLineState) processState;
            cs.stepcounter++;
            
            ProcessService.Response resp = new ProcessService.Response();
            resp.state = cs;
            resp.step = null;
            
            system.debug(LoggingLevel.INFO, 'Before generating customer invoicing ...');
            
            SalesOrderService.generateCustomerInvoices(records);
            
            system.debug(LoggingLevel.INFO, 'After generating customer invoicing ...');
            
            return resp;
        }
        
    }
    
    public class ReleaseandAllocate implements ProcessService.Action{
        
        public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
            
            SalesOrderLineState cs = (SalesOrderLineState) processState;
            cs.stepcounter++;
            
            ProcessService.Response resp = new ProcessService.Response();
            resp.state = cs;
            resp.step = null;
            
            system.debug(LoggingLevel.INFO, 'Before releasing sales Order ...');
            
            SalesOrderService sorderservice = new SalesOrderService();
            sorderservice.planAllocate(records);
            
            system.debug(LoggingLevel.INFO, 'After releasing sales Order ...');
            
            return resp;
        }
        
    }
 
}