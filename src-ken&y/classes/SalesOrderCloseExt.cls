public with sharing class SalesOrderCloseExt {
	
	public boolean showConfirm {get;set;} {showConfirm = true;}
	public ApexPages.StandardController con {get;set;} 
	public Sales_Order__c conSalesOrder; 
	
	public list<Sales_Order_Line__c> backorderedLines {get;set;}{ backorderedLines = new list<Sales_Order_Line__c>(); }
	
	public class SalesOrderCloseExtException extends Exception{
		
	}
	
	public SalesOrderCloseExt(ApexPages.StandardController sc){
		
		con = sc;
		conSalesOrder = (Sales_Order__c) con.getRecord();
		
		try{
			if(conSalesOrder.Status__c == 'Closed'){
				throw new SalesOrderCloseExtException(Label.SO_already_closed);
			}	
			
			if(conSalesOrder.Status__c == 'Cancelled'){
				throw new SalesOrderCloseExtException(Label.SO_already_cancelled);
			}
			
			String whereClause = 'Sales_Order__c = \''+conSalesOrder.Id+'\' and Status__c = \'Open\' and Quantity_Backordered__c > 0';
			
			SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
	        soql.addFields('Close_RO');
	        soql.addFields('Close_WR');
	        soql.setWhereClause(whereClause);

			backorderedLines.addAll((List<Sales_Order_Line__c>)Database.query(soql.getQuery()));
			
		}catch(Exception e){
			showConfirm = false;
			ApexPages.addMessages(e);
			return;
		}
		
	}

	public static string Quantity_Shipped_Error = ': cannot be closed. Only open sales order lines with back ordered quantity can be closed.';
	public void closeSalesOrder(){
		try{
			//KNDY-1761
			DML.updateAsUser(backorderedLines);
			SalesOrderService.close(new Set<Id>{conSalesOrder.Id});
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Sales order closed successfully'));
		}catch(Exception e){
			ApexPages.addMessages(e);
		}

	}
}