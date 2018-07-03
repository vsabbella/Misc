/*
*   Test methods for GridRelatedListController
*/
@isTest
public with sharing class PricebookLineUpdateExtTest {
        
    static testMethod void testPBLinesGridFieldList(){

    	TestFuel data = new TestFuel();

		system.assert( data.pricebook != null , 'Pricebook not found');

		Test.startTest();

    	PricebookRelatedListExt pExtn = new PricebookRelatedListExt(new Apexpages.Standardcontroller(data.pricebook));

    	system.assert( pExtn.getPriceBookLinesFieldList() != null, 'Fieldset \'Pricebook_Related_List\' under \'Pricebook_Line__c\' object is invalid or does not have any fields in it');

    	Test.stopTest();
    }
}