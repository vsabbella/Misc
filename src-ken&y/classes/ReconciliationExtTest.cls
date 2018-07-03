//@isTest(SeeAllData='false')
public with sharing class ReconciliationExtTest {
	
/*	public class SampleData{ 
        
        public TestFuel fuel = new TestFuel();
        //public TestData.Accounting accting = new TestData.Accounting(fuel.company.Id);
        public Period__c period = new Period__c();
        public Receiving_Document__c rd;
        public Reconciliation_Topic__c rt;
        public Reconciliation__c recon;
        public Report testReport;
        public SampleData(){
            //updateRD();
        	updateReconciliation();
        	updateReconciliationTopic();
        } 
        
        public void updateReconciliation(){ 
			recon = new Reconciliation__c();
			recon.name = 'Test Recon';
			recon.Company__c = fuel.company.Id;
            recon.period__c= updatePeriod().id;
			recon.GL_Account__c = fuel.FGInventoryGL.Id;
            //recon.Period__c = sd.period;
			testReport =  [SELECT id, name 
	                                    FROM Report LIMIT 1];	
		    system.assertNotEquals(null, testReport.Id, 'We should have reports in the package');							
	        
			
			insert recon; 
        }
        
        public void updateReconciliationTopic(){ 
			rt = new Reconciliation_Topic__c();
			rt.reconciliation__c = recon.Id;
			rt.Type__c = 'Customer Invoice';
			//rt.action__c = 'Accrual';
			insert rt; 
        }
        public period__c updatePeriod(){ 
            List<Period__c> periods = fuel.periodList;
            for(Period__c thisPeriod : periods){
            	if(thisPeriod.open__c){
                    //system.assertNotEquals(null, thisPeriod, thisPeriod); 
            		period = thisPeriod;
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
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName=string.valueOf(math.random()) + '@t' + string.valueOf(math.random()) + '.com');
        insert u;
        PermissionSet kndyAdmin = [SELECT Id FROM PermissionSet WHERE Name = 'Kenandy_Admin_Permissions' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = kndyAdmin.Id);
        insert psa;
        Reports.ReportInstance instance ;
        system.runAs(u){
            Boolean runningForBeginningBalance = true ;
            Boolean runningForEndingBalance = false ;
            Boolean endingRunFlag = false ;
            SampleData sd = new SampleData();
            List<Reconciliation_Topic__c> rts = [SELECT Id, name ,Reconciliation__c,Type__c
            								FROM Reconciliation_Topic__c];
            system.assertNotEquals(0, rts.size(), 'We should see an accounting entry for the test Receiving Document'); 
            sd.recon.Period__c = sd.period.Id;
            update sd.recon;
            Reconciliation__c localRecon = ReconciliationService.returnReconcilationDetails(new set<Id>{sd.recon.Id}).get(sd.recon.Id);
            system.assertNotEquals(null, localRecon, localRecon); 
            system.assertNotEquals(null, sd.recon.Period__c, sd.recon.Period__c); 

            Reports.ReportMetaData metaData = Reports.ReportManager.describeReport(sd.testReport.Id).getReportMetaData();
            test.startTest();
                //ReconciliationExt reconExt = new ReconciliationExt();
                ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(localRecon);
                ReconciliationExt reconExt = new ReconciliationExt(con);
                test.setCurrentPage(page.Reconciliation);
                
                //Reconciliation__c testRecon = [SELECT Id, name,source_amount__c,type__c,net_change__c
                //                            FROM Reconciliation__c
                //                            WHERE Id = :con.getId() LIMIT 1];
                //system.assertEquals(null, testRecon, testRecon); 
                //List<AggregateResult> arReconItems = [SELECT type__c reconType, reconciliation_topic__c topicId, SUM(source_amount__c) sourceAmount, SUM(net_change__c) netChange
                //                    FROM Reconciliation_Item__c
                //                    WHERE Reconciliation__c = :con.getId()
                //                    GROUP BY reconciliation_topic__c, type__c];
                //system.assertEquals(null, arReconItems, arReconItems); 
               
				reconExt.runBatch();
                //reconExt.runBatch();
                //reconExt.updateSections1();
                reconExt.updateSections();
                //database.executebatch(batch);
                reconExt.cancel();
                reconExt.showDetail();
                reconExt.deleteReconciliationItems();
                //instance = Reports.ReportManager.runAsyncReport(sd.testReport.Id,metaData); 
                //Reports.ReportResults runReportResults;
               // reconExt.runBegBalReports(sd.recon,runningForBeginningBalance,runningForEndingBalance);
                
                //if(asyncReportID != null){
                //    getBeginningBalance();
                //}
                
                //Uncommenting the below hack to test if the issue persists
                //HACK: Platform test issue with report metadata
                ReconRemoteExt.BegEndBalResult begEndBal = ReconRemoteExt.runBegBalReports(sd.recon.id,true,false);
                system.assertEquals(true, begEndBal.isValid,'Expecting succesful Call');
                ReconciliationExt.SummaryItem si = new ReconciliationExt.SummaryItem();
               
            	si.compareTo(si);
            	
            test.stopTest();
            //test.startTest();
            //Reports.ReportResults runReportResults= Reports.ReportManager.getReportInstance(instance.getId()).getReportResults() ; 
            //reconExt.parseRows(runReportResults);
            //test.stopTest();

        }
        
    }
    */

}