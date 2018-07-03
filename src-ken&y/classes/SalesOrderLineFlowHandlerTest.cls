@isTest
public with sharing class SalesOrderLineFlowHandlerTest {
	class TestFlowData {
		
		public Process__c salesOrderLineProcess {
			get{
				if(salesOrderLineProcess == null){
					salesOrderLineProcess = new Process__c();
					
					salesOrderLineProcess.Name = 'Sales Order Line';
					salesOrderLineProcess.Active__c = true;
					salesOrderLineProcess.Automated__c = true;
					salesOrderLineProcess.Object__c = KSE.NamespaceUU + 'Sales_Order_Line__c';
					
					salesOrderLineProcess.Object_Step__c = KSE.NamespaceUU + 'Step__c';
					salesOrderLineProcess.State__c = 'SalesOrderLineFlowHandler.SalesOrderLineState';
					salesOrderLineProcess.Sequence__c = 10;
					
					salesOrderLineProcess.Before__c = true;
					salesOrderLineProcess.Insert__c = true;
					salesOrderLineProcess.Update__c = true;
					
					insert salesOrderLineProcess;
				}
				return salesOrderLineProcess;
			}
			set;
		}
		
		public Step__c salesOrderLineStep {
			get{
				if(salesOrderLineStep == null){
					salesOrderLineStep = new Step__c();
					
					salesOrderLineStep.Name = 'Sales Order Line - Means of Transport';
					salesOrderLineStep.Sequence__c = 10;
					salesOrderLineStep.Process__c = salesOrderLineProcess.Id;
					
					insert salesOrderLineStep;
				}
				return salesOrderLineStep;
			}
			set;
		}
		
		public Action__c setMoTAction {
			get{
				if(setMoTAction == null){
					setMoTAction = new Action__c();
					
					setMoTAction.Name = 'Sales Order Line - Means of Transport';
					setMoTAction.Action__c = 'SalesOrderLineFlowHandler.SetMeansOfTransport';
					setMoTAction.Sequence__c = 10;
					setMoTAction.Step__c = salesOrderLineStep.Id;
					
					insert setMoTAction;
				}
				return setMoTAction;
			}
			set;
		}
		
		public Criteria__c statusIsChangingCriteria {
			get{
				if(statusIsChangingCriteria == null){
					statusIsChangingCriteria = new Criteria__c();
					
					statusIsChangingCriteria.Name = 'Status is changing';
					statusIsChangingCriteria.Field__c = 'Status__c';
					statusIsChangingCriteria.Operator__c = 'is changing';
					statusIsChangingCriteria.Value_Field__c = 'Field';
					statusIsChangingCriteria.Step__c = salesOrderLineStep.Id;
					
					insert statusIsChangingCriteria;
				}
				return statusIsChangingCriteria;
			}
			set;
		}
		
		public Criteria__c lineTypeCriteria {
			get{
				if(lineTypeCriteria == null){
					lineTypeCriteria = new Criteria__c();
					
					lineTypeCriteria.Name = 'Line type is military';
					lineTypeCriteria.Field__c = 'Line_Type__c';
					lineTypeCriteria.Operator__c = 'equals';
					lineTypeCriteria.Value_Field__c = 'Value';
					lineTypeCriteria.Reference__c = 'Military';
					lineTypeCriteria.Step__c = salesOrderLineStep.Id;
					
					insert lineTypeCriteria;
				}
				return lineTypeCriteria;
			}
			set;
		}
			
		public Substitution__c substitution {
			get{
				if(substitution == null){
					substitution = new Substitution__c();
					substitution.Name = 'Primary Product Sub';
					substitution.Current_Product__c = globalTestData.product.Id;
					substitution.Start_Date__c = system.today() - 1;
					substitution.End_Date__c = system.today() + 720;
					
					insert substitution;
				}
				return substitution;
			}
			set;
		}
	}
	
	static TestFlowData localTestData = new TestFlowData();
	static TestFuel globalTestData = new TestFuel();
	 
	// The following method tests that if the record is selected by
	// the process engine, then it should skip the "managed actions" in the trigger.
	static testMethod void testSalesOrderLineFlow(){
		
		system.assert(localTestData.statusIsChangingCriteria.Id != null);
		system.assert(localTestData.lineTypeCriteria.Id != null);
		system.assert(localTestData.setMoTAction.Id != null);
		system.assert(localTestData.salesOrderLineStep.Id != null);
		system.assert(localTestData.salesOrderLineProcess.Id != null);
		system.assert(localTestData.substitution.Id != null);
	
		// Change the product upc
		globalTestData.product2.UPC_Code__c = globalTestData.product.UPC_Code__c;
		update globalTestData.product2;
		
		localTestData.substitution.Substitute_Product__c = globalTestData.product2.Id;
		update localTestData.substitution;
		
		system.assert(globalTestData.salesOrder.Id != null);
		system.assert(globalTestData.salesOrderLines.size() > 0);
		
		for(Sales_Order_Line__c sol : globalTestData.salesOrderLines){
			system.assert(sol.Id != null);
		}
		
		globalTestData.salesOrder.Status__c = 'Open';

		update globalTestData.salesOrder;
		
		Map<Id, Sales_Order_Line__c> oldMap = new Map<Id, Sales_Order_Line__c>(
													  [SELECT Id, Product__c, Weight__c
													     FROM Sales_Order_Line__c 
													    WHERE Id IN :globalTestData.salesOrderLines]); 
		
		system.assert(oldMap.size() > 0);
		
		for(Sales_Order_Line__c sol : oldMap.values()){
			// Since we have a substituiton rule, both lines should have product 2
			system.assertEquals(globalTestData.product2.Id, sol.Product__c);
		}
			
		// Change the status to check that the so line
		// will be picked up by the process engine.
		Sales_Order_Line__c sol = oldMap.get(globalTestData.salesOrderLines[0].Id);
		sol.Status__c = 'Open';
		sol.Line_Type__c = 'Standard';
		sol.Quantity_Ordered__c = 8;
		sol.Quantity_Change_Reason__c = globalTestData.deductionCode.Id;
		
		Sales_Order_Line__c sol2 = oldMap.get(globalTestData.salesOrderLines[1].Id);
		sol2.Status__c = 'Open';
		sol2.Line_Type__c = 'Military';
		sol2.Quantity_Ordered__c = 8;
		sol2.Quantity_Change_Reason__c = globalTestData.deductionCode.Id;
		 
		// Clear out the dispatches
		ProcessHandler.dispatches.clear();
        
		// Changed the status from Draft to Open.
		// Normally, it will go through the "managed actions" in the trigger and updates the weight of the lines.
		update oldmap.values();

		// One of the records will be selected by the process engine and
		// no step has been setup for updating the weight on the sales order line in the process, 
		// so the weight should not be recalculated for one of the sales order lines.
		Map<Id, Sales_Order_Line__c> newMap = new Map<Id, Sales_Order_Line__c>(
												  [SELECT Id, Product__c, Weight__c, Line_Type__c
												     FROM Sales_Order_Line__c 
												    WHERE Id IN :globalTestData.salesOrderLines]); 
		system.assert(newMap.size() > 0);
		system.debug(LoggingLevel.INFO, newMap);
		system.assertNotEquals(oldMap.get(globalTestData.salesOrderLines[0].Id).Weight__c, newMap.get(globalTestData.salesOrderLines[0].Id).Weight__c);
		system.assertEquals(oldMap.get(globalTestData.salesOrderLines[1].Id).Weight__c, newMap.get(globalTestData.salesOrderLines[1].Id).Weight__c);										      
													    
	}	
}