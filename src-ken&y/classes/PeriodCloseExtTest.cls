@isTest
public with sharing class PeriodCloseExtTest {
    
    public class SampleData{
        
        public TestFuel fuel = new TestFuel();
        public TestData.Accounting accting = new TestData.Accounting(fuel.company.Id);
        public Period__c p1, p2, p3;
        public SampleData(){
            updatePeriod_SLCSuccess();
        }
        
        public void updatePeriod_SLCSuccess(){ 
            List<Period__c> periodListLastYear = fuel.periodListLastYear;
            p1 = periodListLastYear[0];
            p1.Open__c = true;
            update p1;
        }
        
    }
    
    static testMethod void testAR1(){
        SampleData sd = new SampleData();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.p1);
        pageReference pr = page.PeriodCloseExceptions;
        Test.setCurrentPage(pr);
        PeriodCloseExt ext = new PeriodCloseExt(con);
        pr.getParameters().put('SubledgerType','AR');
        pr.getParameters().put('IsValidateOnly','true');
        ext.currDate = system.now().addseconds(1);
        ext.refresh();
        test.startTest();
        ext.runAR();
        pr.getParameters().put('IsValidateOnly','true');
        ext.IsValidateOnly = boolean.valueOf(pr.getParameters().get('IsValidateOnly'));
        //ext.validateAR();
       // ext.closeAR(); 
        ext.goBack();
        ext.closeSubledger();
         ext.getLastValidated();
        string getPeriodJson = JSON.serialize(sd.p1);
        JsonResult result =  PeriodCloseExt.getExceptions('AR',getPeriodJson,'True');
        JsonResult result1 =  PeriodCloseExt.getExceptions('AR',getPeriodJson,'False');
        test.stopTest();
        Period__c p = [Select id, Name, AR_Subledger_job__c, AR_Subledger_cutoff__c, AR_subledger_Closed__c, Open__c
        			from Period__c
        			where id = :sd.p1.id ];
//        system.assert(p.AR_Subledger_closed__c == null,'p:'+p);
        ext.reopenAR();
    }
    
    static testMethod void testAP(){
        SampleData sd = new SampleData();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.p1);
        pageReference pr = page.PeriodCloseExceptions;
        Test.setCurrentPage(pr);        
        PeriodCloseExt ext = new PeriodCloseExt(con);
        pr.getParameters().put('SubledgerType','AP');
        pr.getParameters().put('IsValidateOnly','true');
        ext.currDate = system.now().addseconds(1);
        ext.refresh();
        test.startTest();
        ext.runAP();
        //ext.validateAP();
       // ext.closeAP();                
        ext.goBack();   
        ext.closeSubledger();
         ext.getLastValidated();
        string getPeriodJson = JSON.serialize(sd.p1);
        JsonResult result =  PeriodCloseExt.getExceptions('AP',getPeriodJson,'True');
        JsonResult result1 =  PeriodCloseExt.getExceptions('AP',getPeriodJson,'False');
        test.stopTest();
        Period__c p = [Select id, Name, AP_Subledger_cutoff__c, AP_subledger_Closed__c, 
                                Open__c,prior_period__c,prior_period__r.name
        			from Period__c
        			where id = :sd.p1.id ];
        system.debug('closd'+p);
        system.debug('closd'+p.prior_period__c);
        system.assert(p.AP_Subledger_closed__c != null,'p:'+p);
        ext.reopenAP();
    }
    
    static testMethod void testShipment(){
        SampleData sd = new SampleData();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.p1);
        pageReference pr = page.PeriodCloseExceptions;
        Test.setCurrentPage(pr);        
        PeriodCloseExt ext = new PeriodCloseExt(con);
        pr.getParameters().put('SubledgerType','SH');
        pr.getParameters().put('IsValidateOnly','true');
        ext.currDate = system.now().addseconds(1);
        ext.refresh();
        test.startTest();
        ext.runShipment();
         ext.getLastValidated();
        //ext.validateShipment();
        //ext.closeShipment();                
        ext.goBack(); 
        ext.closeSubledger();
        string getPeriodJson = JSON.serialize(sd.p1);
        JsonResult result =  PeriodCloseExt.getExceptions('SH',getPeriodJson,'True');
        JsonResult result1 =  PeriodCloseExt.getExceptions('SH',getPeriodJson,'False');
        test.stopTest();
        Period__c p = [Select id, Name, Shipment_Subledger_cutoff__c, Shipment_subledger_Closed__c, Open__c
        			from Period__c
        			where id = :sd.p1.id ];
//        system.assert(p.Shipment_Subledger_closed__c != null,'p:'+p);
        ext.reopenShipment();
    }
    
    static testMethod void testReceiving(){
        SampleData sd = new SampleData();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.p1);
        pageReference pr = page.PeriodCloseExceptions;
        Test.setCurrentPage(pr);        
        PeriodCloseExt ext = new PeriodCloseExt(con);
        pr.getParameters().put('SubledgerType','RC');
        pr.getParameters().put('IsValidateOnly','true');
        ext.currDate = system.now().addseconds(1);
        ext.refresh();
        test.startTest();
        ext.runReceiving();
        //ext.validateReceiving();
        //ext.closeReceiving(); 
        ext.closeSubledger();
         ext.getLastValidated();
        ext.goBack();               
        string getPeriodJson = JSON.serialize(sd.p1);
        JsonResult result =  PeriodCloseExt.getExceptions('RC',getPeriodJson,'True');
        JsonResult result1 =  PeriodCloseExt.getExceptions('RC',getPeriodJson,'False');
        test.stopTest();
        Period__c p = [Select id, Name, Receiving_Subledger_cutoff__c, Receiving_subledger_Closed__c, Open__c
        			from Period__c
        			where id = :sd.p1.id ];
//        system.assert(p.Receiving_Subledger_closed__c != null,'p:'+p);
        ext.reopenReceiving();
    }
    
    static testMethod void testInventory(){
        SampleData sd = new SampleData();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.p1);
        pageReference pr = page.PeriodCloseExceptions;
        Test.setCurrentPage(pr);        
        PeriodCloseExt ext = new PeriodCloseExt(con);
        pr.getParameters().put('SubledgerType','IN');
        pr.getParameters().put('IsValidateOnly','true');
        ext.currDate = system.now().addseconds(1);
        ext.refresh();
        test.startTest();
        ext.runInventory();
        ext.closeSubledger();
         ext.getLastValidated();
        //ext.validateInventory();
        //ext.closeInventory();                
        ext.goBack(); 
        string getPeriodJson = JSON.serialize(sd.p1);
        JsonResult result =  PeriodCloseExt.getExceptions('IN',getPeriodJson,'True');
                
        test.stopTest();
        Period__c p = [Select id, Name, Inventory_Subledger_cutoff__c, Inventory_subledger_Closed__c, Open__c
        			from Period__c
        			where id = :sd.p1.id ];
//        system.assert(p.Inventory_Subledger_closed__c != null,'p:'+p);
        ext.reopenInventory();
    }
    
    static testMethod void testFA(){
      
        boolean sawError = false;

        SampleData sd = new SampleData();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.p1);
        pageReference pr = page.PeriodCloseExceptions;
        Test.setCurrentPage(pr);        
        PeriodCloseExt ext = new PeriodCloseExt(con);
        //--- Expect error since SubledgerType is not defined----//
        ext.closeSubledger(); 
         ext.getLastValidated();
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('None has been specified')) sawError = true;
        }
        system.assert(sawError);
        
        pr.getParameters().put('SubledgerType','FA');
        pr.getParameters().put('IsValidateOnly','true');
        ext.currDate = system.now().addseconds(1);
        ext.refresh();
        test.startTest();
        ext.runFA();
        ext.closeSubledger();
        ext.getLastValidated();
        ext.getExceptionLinesFieldList(); 
        //ext.validateFA();
        //ext.closeFA();                
        string getPeriodJson = JSON.serialize(sd.p1);
        JsonResult result =  PeriodCloseExt.getExceptions('FA',getPeriodJson,'True');
        JsonResult result1 =  PeriodCloseExt.getExceptions('FA',getPeriodJson,'False');
        test.stopTest();
        Period__c p = [Select id, Name, FA_Subledger_cutoff__c, FA_subledger_Closed__c, Open__c
        			from Period__c
        			where id = :sd.p1.id ];
//        system.assert(p.FA_Subledger_closed__c != null,'p:'+p);
        ext.reopenFA();
    }
        static testMethod void testJE(){
        SampleData sd = new SampleData();
        Apexpages.standardcontroller con = new Apexpages.Standardcontroller(sd.p1);
        pageReference pr = page.PeriodCloseExceptions;
        Test.setCurrentPage(pr);        
        PeriodCloseExt ext = new PeriodCloseExt(con);
        pr.getParameters().put('SubledgerType','JE');
        pr.getParameters().put('IsValidateOnly','true');
        ext.currDate = system.now().addseconds(1);
        ext.refresh();
        test.startTest();
        ext.runJE();
        ext.closeSubledger();
         ext.getLastValidated();
        //ext.validateJE();
        //ext.closeJE();                
        string getPeriodJson = JSON.serialize(sd.p1);
        JsonResult result =  PeriodCloseExt.getExceptions('JE',getPeriodJson,'True');
        JsonResult result1 =  PeriodCloseExt.getExceptions('JE',getPeriodJson,'False');
        test.stopTest();
        Period__c p = [Select id, Name,JE_Cutoff__c,GL_Close__c, Open__c
        			from Period__c
        			where id = :sd.p1.id ];
        ext.reopenJE();
    }
}