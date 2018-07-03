@isTest
public with sharing class BudgetImportConTest {
    
    public class BudgetImportTestData {
    	public TestFuel fuel = new TestFuel();
    	
    	public Budget__c budget {
    		get{
    			if(budget == null){
    				budget = new Budget__c(Company__c = fuel.company.Id, Budget_From__c = fuel.periodList[0].Id, Budget_To__c = fuel.periodList[fuel.periodList.size() - 1].Id);
    				insert budget;
    			}
    			return budget;
    		}
    		set;
    	}
    	
    	public List<Map<String, String>> budgetLinesToImport {
    		get{
    			if(budgetLinesToImport == null){
    				
    				System.JSONGenerator jsonGen = JSON.createGenerator(false);
    				jsonGen.writeStartArray();
    				
    				for(Period__c period : fuel.periodList){
    					jsonGen.writeStartObject();
    					
    					jsonGen.writeStringField('GL_Account__c', fuel.expenseGL.Name);
    					//jsonGen.writeStringField('Product__c', fuel.product.Name);
    					jsonGen.writeNumberField('Budget_Amount__c', 1);
    					jsonGen.writeStringField('Period__c', period.Name);
    					
    					jsonGen.writeEndObject();
    				}
    				
    				jsonGen.writeEndArray();
    				jsonGen.close();
    				
    				budgetLinesToImport = (List<Map<String, String>>) JSON.deserialize(jsonGen.getAsString(), List<Map<String, String>>.class);
    				
    			}
    			return budgetLinesToImport;
    		}
    		set;
    	}
    	
    }

    static testMethod void testBudgetImportCon(){
    	BudgetImportConTest.BudgetImportTestData biTestFuel = new BudgetImportConTest.BudgetImportTestData();
    	
    	delete [SELECT Id FROM Segment_Definition__c WHERE Name='Intercompany__c'];
    	
    	system.assert(! String.isBlank(BudgetImportCon.segmentsJSON));
    	
    	BudgetImportCon biCon = new BudgetImportCon(new ApexPages.StandardController(new Budget__c()));
    	
    	system.assert(ApexPages.hasMessages());
    	
    	biCon = new BudgetImportCon(new ApexPages.StandardController(biTestFuel.budget));
    	
    	system.assert(biTestFuel.budget.Id != null);
    	
    	JSONResult result = BudgetImportCon.saveBudgetLines(biTestFuel.budget.Id, new List<String>{'GL Account', 'Period'}, biTestFuel.budgetLinesToImport);
    	
    	system.assert(result.success == false);
    	system.assert([SELECT Id FROM Budget_Line1__c WHERE Budget__c = :biTestFuel.budget.Id].size() == 0);
    	
    	biTestFuel.fuel.expenseGL.Include_in_Budgets__c = true;
    	update biTestFuel.fuel.expenseGL;
    	
    	result = BudgetImportCon.saveBudgetLines(biTestFuel.budget.Id, new List<String>{'GL Account', 'Period'}, biTestFuel.budgetLinesToImport);
    	
    	system.assert(result.success == true, result.messages);
    	system.assertEquals(biTestFuel.fuel.periodList.size(), [SELECT Id FROM Budget_Line1__c WHERE Budget__c = :biTestFuel.budget.Id].size());
    }
}