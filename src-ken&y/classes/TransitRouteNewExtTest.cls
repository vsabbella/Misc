@isTest
private class TransitRouteNewExtTest { 
    
   static testmethod void testSave(){ 
       Means_of_Transport__c objMT = new Means_of_Transport__c();
       objMT.Name = 'Truck';
       objMT.Maximum_cube__c = 10;
       insert objMT;
    
       Account objact = new Account();
       objact.Name = 'TestOrigin';
       insert objact;
    
       Account objact1 = new Account();
       objact1.Name = 'TestDestination';
       insert objact1;
    
       ApexPages.standardcontroller sc = new ApexPages.standardcontroller(new transit_route__c());
       TransitRouteNewExt trExt = new TransitRouteNewExt(sc);
       trExt.newObj.Origin__c = objact.Id;
       trExt.newObj.Destination__c = objact1.Id;
       trExt.newObj.Means_Of_Transport__c = objMT.Id;
       trExt.newObj.Transit_Time__c = 5;
    
       test.startTest();
       trExt.save();
       system.assertNotEquals(null,trExt.newObj.Id);
       
       trExt.deleteRoute();
       test.stopTest();
       transit_route__c[] tmp = [ select id from transit_route__c where id = :trExt.newObj.id limit 1];
       system.assert( tmp.size() == 0, ' expected to be able to delete');
   }
    
    static testmethod void testSaveandNew(){
       Means_of_Transport__c objMT = new Means_of_Transport__c();
       objMT.Name = 'Truck';
       objMT.Maximum_cube__c = 10;
       insert objMT;
    
       Account objact = new Account();
       objact.Name = 'TestOrigin';
       insert objact;
    
       Account objact1 = new Account();
       objact1.Name = 'TestDestination';
       insert objact1;
    
       ApexPages.standardcontroller sc = new ApexPages.standardcontroller(new transit_route__c());
       TransitRouteNewExt trExt = new TransitRouteNewExt(sc);
       trExt.newObj.Origin__c = objact.Id;
       trExt.newObj.Destination__c = objact1.Id;
       trExt.newObj.Means_Of_Transport__c = objMT.Id;
       trExt.newObj.Transit_Time__c = 5;
    
       PageReference returnPageRef = trExt.saveandnew();
       
       system.assertNotEquals(null,trExt.newObj.Id);
    
       PageReference pageRef = Page.TransitRouteNew;
        system.assertEquals(returnPageRef.getURL(), pageRef.getUrl());
    }
   
   /**
   *    @description Test to check that we cannot create two primary 
   *    transit routes for the same origin and destination
   */ 
   static testmethod void testPrimaryKey(){
       Means_of_Transport__c objMT = new Means_of_Transport__c();
       objMT.Name = 'Truck';
       objMT.Maximum_cube__c = 10;
       insert objMT;
    
       Means_of_Transport__c objMT2 = new Means_of_Transport__c();
       objMT2.Name = 'Truck2';
       objMT2.Maximum_cube__c = 10;
       insert objMT2;

       Account objact = new Account();
       objact.Name = 'TestOrigin';
       insert objact;
    
       Account objact1 = new Account();
       objact1.Name = 'TestDestination';
       insert objact1;
    
       Transit_Route__c objTR = new Transit_Route__c();
       objTR.Origin__c = objact.Id;
       objTR.Destination__c = objact1.Id;
       objTR.Means_Of_Transport__c = objMT2.Id;
       objTR.Transit_Time__c = 5;
       objTR.Primary__c = true;
       insert objTR;
       system.assertEquals(true,objTR.Primary__c);
    
       Transit_Route__c objTR1 = new Transit_Route__c();
       objTR1.Origin__c = objact.Id;
       objTR1.Destination__c = objact1.Id;
       objTR1.Means_Of_Transport__c = objMT.Id;
       objTR1.Transit_Time__c = 8;
       objTR1.Primary__c = true;
        
        try{
           insert objTR1;
           system.assert(false);
        }
        catch(exception e){
           system.assert(e.getmessage().contains('DUPLICATE_VALUE'),e.getmessage());
        }
        system.assertEquals(null, objTR1.Id);
    }
}