@isTest
private class AgreementViewConTest {
    
    static testMethod void testAgreementViewCon(){
        
        TestFuel data = new TestFuel();
        Agreement__c ag = data.agreement;
        Agreement_Line__c agl = data.agreementLine;

        //KNDY-15054 - Check if rental agreement line has pricing UOM on it
        Agreement_Line__c agl2 = data.agreementLine;
        agl2.Price_Type__c = 'Recurring';
        agl2.Pricing_UOM__c = null;
        try{
            update agl2;
        }
        catch(DmlException e){
            //assert should fail as the save should fail when the pricing UOM is blank during save
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' , e.getDmlStatusCode(0) ); 
        }

        AgreementViewCon con = new AgreementViewCon();
        con.agreementId = ag.Id;
        con.getAgreementConfigJson();
        con.getAgreementLinesConfigJson();
        con.getAgreementJson();
        con.getCustomAgreementActionIds();
        con.getCustomAgreementLineActionIds();
        con.getCustomAgreementActionsDropdown();
        con.getCustomAgreementActionsConfig();
        con.getCustomAgreementLineActionsDropdown();
        con.getCustomAgreementLineActionsConfig();
        con.getGridViews();
        AgreementViewCon.getAgreementData(ag.Id, null);
        AgreementViewCon.getAgreementLineData(agl.Id, (List<String>) JSON.deserialize(con.getAllFields(), List<String>.class));
        Test.startTest();
        List<String> dateFields = new List<String>();
        Agreement_Line__c agl1 = data.agreementLine1;
        Cross_Reference__c crf = data.crossRef;
        AgreementViewCon.AGLineWrapper agLineWrapper = new AgreementViewCon.AGLineWrapper(agl1);
        AgreementViewCon.saveAgreementLine(agLineWrapper, dateFields, 'create');
        AgreementViewCon.saveAgreementLine(agLineWrapper, dateFields, 'update');
        AgreementViewCon.saveAgreementLine(agLineWrapper, dateFields, 'delete');
        List<Agreement__c> updatedList = new List<Agreement__c>();
        List<Agreement__c> newList = new List<Agreement__c>(); 
        List<Agreement__c> deletedList = new List<Agreement__c>(); 
        
        DataSourceResult result = AgreementViewCon.saveAgreementList(updatedList, newList, deletedList, dateFields);
        system.assertEquals(true, result.success);
        Test.stopTest();
    }
    /**
     *  testGetAgreementLineDetails method tests the getAglDetailsFromProduct and getAglDetailsFromProductRef methods 
     *  under AgreementViewCon class
     */
    public static testmethod void testGetAgreementLineDetails() {

        TestFuel testData = new TestFuel();
        Agreement__c ag = testData.agreement;

        Test.startTest();

        Agreement_Line__c agl = testdata.agreementLine;

        JsonResult productResult = AgreementViewCon.getAglDetailsFromProduct( testData.product.id, 
                                                                                                 agl,
                                                                                                 ag.Id);
        system.assertEquals(true, productResult.success);
        JsonResult productRefresult = AgreementViewCon.getAglDetailsFromCrossRef(testData.crossRef.Id, 
                                                                                     agl,
                                                                                     ag.Id);
        system.assertEquals(true, productRefresult.success);

        Test.stopTest();

    }
    
}