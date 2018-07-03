/**
 * This class contains unit tests for validating the behavior of test methods in TransitRouteService.cls
 */
@isTest
private class TransitRouteServiceTest {
	
	static testMethod void testDuplicateMeansOfTransport(){
	    
	    Means_of_Transport__c mot = new Means_of_Transport__c();
		mot.Code__c = '123';
		mot.Mode_of_Transport__c = 'Land';
		mot.Name = 'LTL';
		
		try{
			insert mot;
		}catch(Exception e){
			system.assert(false, 'Unexpected exception thrown: ' + e.getMessage());
		}
		
		Means_of_Transport__c mot2 = new Means_of_Transport__c();
		mot2.Code__c = '123';
		mot2.Mode_of_Transport__c = 'Land';
		mot2.Name = 'LTL';
		
		try{
			insert mot2;
			system.assert(false, 'Expected an exception to be thrown: ');
		}catch(DMLException e){
			system.assertEquals(StatusCode.DUPLICATE_VALUE, e.getDmlType(0), 'Unexpected exception thrown: ' + e.getMessage());
		}
	} 
}