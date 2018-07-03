//@isTest(SeeAllData='false')
public with sharing class ReconciliationBatchForAccrualsTest {
	
	/*public class SampleData{
        
        public TestFuel fuel = new TestFuel();
        //public TestData.Accounting accting = new TestData.Accounting(fuel.company.Id);
        public Period__c p;
        public Receiving_Document__c rd;
        public Reconciliation_Topic__c rt;
        public Reconciliation__c recon;
        public SampleData(){
            //updateRD();
        	updateReconciliation();
        	updateReconciliationTopic();
        }
        
        public void updateReconciliation(){ 
			recon = new Reconciliation__c();
            recon.period__c= updatePeriod().id;
			recon.name = 'Test Recon';
			recon.Company__c = fuel.company.Id;
			recon.GL_Account__c = fuel.FGInventoryGL.Id;
            
			Report testReport =  [SELECT id, name 
	                                    FROM Report LIMIT 1];	
		    system.assertNotEquals(null, testReport.Id, 'We should have reports in the package');							
	        
	        //Report testReport = reportList[0];
	 		//recon.ReportID__c = testReport.Id;        
		
			insert recon; 
        }
        
        public void updateReconciliationTopic(){ 
			rt = new Reconciliation_Topic__c();
			rt.reconciliation__c = recon.Id;
			rt.Type__c = 'Customer Invoice';
		//	rt.action__c = 'Accrual';
			insert rt; 
        }
        
        
        
        public period__c updatePeriod(){ 
            List<Period__c> periods = fuel.periodList;
            for(Period__c thisPeriod : periods){
            	if(thisPeriod.open__c){
                    //system.assertNotEquals(null, thisPeriod, thisPeriod); 
            		period__c period = thisPeriod;
                    Period__c up = [SELECT Id, ar_subledger_closed__c, ap_subledger_closed__c, fa_subledger_closed__c, Closed__c ,inventory_subledger_closed__c, shipment_subledger_closed__c, receiving_subledger_closed__c 
                                    FROM Period__c WHERE Id = :period.Id FOR UPDATE ];
                    PeriodService.systemEditable.add(up.Id);
                    
                    up.ar_subledger_closed__c = system.now();
                    up.ap_subledger_closed__c = system.now();
                    up.shipment_subledger_closed__c = system.now();
                    up.receiving_subledger_closed__c = system.now();
                    up.fa_subledger_closed__c = system.now();
                    up.inventory_subledger_closed__c = system.now();
                    up.gl_close__c = system.now();
                    up.Closed__c =true;
                    up.Open__c=false;
                    update up;
                    return up;
                    //integer month = system.now().month();
                    //period.Period_Start__c = datetime.newInstance(month, 1, 1, 0, 0, 0);
                    //period.Period_End__c = datetime.newInstance((1 == 12 ? month + 1 : month), (1 == 12 ? 1 : 1 + 1), 1, 0, 0, 0);
                    //period.Period_Start__c = system.now().toStartOfMonth();
                    //update period;
            	}
            }
             return null;

        }
        
        public void updateRD(){
            rd = fuel.receivingDocumentASN;
            
            List<Receipt_Line__c> rls = fuel.receivingDocumentASNLines;
            for(Receipt_Line__c rl : rls){
                rl.extended_cost__c = 10;
            }
            update rls;
            
            rd.transaction_date__c = system.now();
            rd.finalized__c = true;
            rd.Date_Received__c = system.now();
            update rd;
            
            for(Accounting_Rule__c ar : fuel.rdAccountingRuleList){
                if(ar.Object_Name__c == 'Receiving_Document__c' && !ar.Default_GL_Account__c){
                    ar.Default_GL_Account__c = true;
                    ar.GL_Account_Reference_Value__c = null;
                    ar.GL_Account__c = fuel.FGInventoryGL.Id;
                }
            }
            
            update fuel.rdAccountingRuleList;
        }
    }
	
	public static testMethod void testValidate(){
        
        SampleData sd = new SampleData();
        List<Reconciliation_Topic__c> rts = [SELECT Id, name ,Reconciliation__c,Type__c
        								FROM Reconciliation_Topic__c];
        system.assertNotEquals(0, rts.size(), 'We should see an accounting entry for the test Receiving Document');
        
        test.startTest();
            ReconciliationBatchForAccruals batch = new ReconciliationBatchForAccruals(sd.recon);
            database.executebatch(batch);
        test.stopTest();
        
    }*/

}