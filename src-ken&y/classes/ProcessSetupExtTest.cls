@isTest
private class ProcessSetupExtTest {
	
	@isTest static void returnObjectFlows_returns_empty_list() {

		List<Process.ProcessFlow> flows = Process.returnObjectFlows('Sales_Order__c');

		system.assert(flows.size() == 0, ' with no records, this should return a list of 0 records' );
	}
	
	@isTest static void returnObjectFlows_builds_simple_flow() { 
		Process__c p = new Process__c(name='foo' , Object__c='Sales_Order__c');
		insert p;
		system.assert( p.id != null);
		Criteria__c c = new Criteria__c( name='cry', Process__c = p.id);
		insert c; 

		Step__c st = new Step__c(name='st', Process__c=p.id); 
		insert st;

		Action__c ac = new Action__c(name='act', Step__c= st.id);
		insert ac; 

		List<Process.ProcessFlow> flows = Process.returnObjectFlows('Sales_Order__c');

		system.assert(flows.size() == 1, ' this should return a list of 1 flow' );
		system.assert(flows[0].criteria.size() == 1, ' this should return a list of 1 criteria' );
		system.assert(flows[0].steps.size() == 1, ' this should return a list of 1 step' );
		system.assert(flows[0].steps[0].actions.size() == 1, ' this should return a list of 1 action' );

	}
	
}