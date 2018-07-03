@isTest
public with sharing class LotTriggerTest {
	
	static testMethod void testLotExpiration(){
		
		TestData data = new TestData();
		
		Test.startTest();
		
		Lot__c lot = new Lot__c();
		lot.item__c = data.itemList[0].id;
		lot.supplier__c = data.supplier.id;
		lot.expiration_date__c = system.today();
		
		insert lot;
		
		SKID__c sk1 = new SKID__c();
		//sk1.Company__c = data.company.id;
		sk1.Location__c = data.location.id;
		sk1.Item__c = data.itemList[0].id;
		sk1.Lot__c = lot.id;
		sk1.Quantity__c = 199;
		
		sk1.Type__c = 'History';
		sk1.Expiration_Date__c = system.today();
		sk1.Company__c = data.company.id;
		
		insert sk1;
		
		SKID__c sk2 = new SKID__c();
		//sk2.Company__c = data.company.id;
		sk2.Location__c = data.location.id;
		sk2.Item__c = data.itemList[0].id;
		sk2.Lot__c = lot.id;
		sk2.Quantity__c = 199;

		sk2.Type__c = 'History';
		sk2.Expiration_Date__c = system.today();
		sk2.Company__c = data.company.id;
		insert sk2;
		
		lot.expiration_date__c = system.today() + 10;
		update lot;
		
		List< SKID__c > skids = [ select id, lot__c ,type__c, expiration_date__c from SKID__c where lot__c =: lot.id ];
		
		system.assert( skids.size() == 2 );
		
		for( SKID__c skid : skids ){
			
			if( skid.Type__c == 'History' )
				system.assert( skid.Expiration_Date__c  == system.today() );
			
			if( skid.Type__c == 'Location' )
				system.assert( skid.Expiration_Date__c  == system.today() + 10 );
				
		}
		
		Test.stopTest();
	}
	
}