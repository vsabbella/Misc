public with sharing class BudgetLineService {
    
	public static void assignBudgetLineUniqueKeys(List<Budget_Line1__c> budgetLines){
		for(Budget_Line1__c budgetLine : budgetLines){
			list<String> keyIds = new list<String>();
			String budgetLineKey = '';
			
			SegmentService segServ = new SegmentService();
			List<String> segments = segServ.getSegmentFields();
			
			for(String segmentField : segments){
				budgetLineKey += budgetLine.get(segmentField) != null ? (String) budgetLine.get(segmentField) : null;
				budgetLineKey += '|';
			}
			budgetLineKey += budgetLine.Period__c;
			budgetLineKey += budgetLine.Budget__c;
			
			budgetLine.ExtId__c = budgetLineKey;
			budgetLine.Budget_Line_Unique__c = budgetLineKey;
		}
	}
}