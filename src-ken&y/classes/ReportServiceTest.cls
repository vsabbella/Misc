//Deprecated based on KNDY-10059

@isTest(SeeAllData='true')
public with sharing class ReportServiceTest {
	
//	public class ReportSampleData{
//        public TestFuel fuel = new TestFuel();
//        public Company__c company = fuel.company;
//        public List<Period__c> periodList = fuel.periodList;
//		public List<Item__c> itemList = fuel.itemList;
//		public GL_Account__c cashGL = fuel.cashGL;
//		
//		//SampleData
//		public ReportSampleData(){
//			updateData();
//		}
//		
//		public void updateData(){
//			
//			List<Inventory_Change__c> invChangeList = new List<Inventory_Change__c>();
//
//	        //TestFuel fuel = new TestFuel();
//	        Inventory_Change__c invchange1=new Inventory_Change__c();
//	        invchange1.Company__c=company.Id; 
//	        invchange1.Finalized__c = false;
//	        invchange1.Transaction_Date__c = system.now();
//	        invchange1.Finalized_Date__c = system.now();
//	        invchange1.Type__c = 'Adjustment';
//	        invchange1.Item__c = itemList[0].id;
//	        invchange1.Reason_Code__c = null;
//	        invchange1.count_quantity__c = 3;
//	        invchange1.computer_Quantity__c = 3;
//	        invChangeList.add(invchange1);
//	        insert invChangeList;        
//	                                                         
//			List<Inventory_Transaction__c> invtransList = new List<Inventory_Transaction__c>();
//			Inventory_Transaction__c invtrans1 = new Inventory_Transaction__c();	
//			
//			invtrans1.Inventory_Change__c = invChangeList[0].id;
//			invtrans1.Item__c = itemList[0].id;			
//			invtrans1.Extended_Cost__c = null;
//			invtrans1.Type__c = 'Cycle Count';
//			invtrans1.Subtransaction_Type__c = 'Cycle Count';
//			invtrans1.Line_Type__c = 'Increase';
//			invtrans1.Standard_Cost__c = 3;
//			invtrans1.Quantity__c = 10;
//			invtransList.add(invtrans1); 
//			insert invtransList;
//
//			invChangeList[0].Finalized__c = true;
//			update invChangeList;
//			
//            //InventoryChangeAccounting ica = new InventoryChangeAccounting();
//            //ica.execute(invChangeList);       
//
//            AccountingAPI accAPI = new AccountingAPI();
//            accAPI.generateAccounting((List<sObject>)invChangeList);    
//                
//            Set<Id> icIds = new Set<Id>();
//            for(Inventory_Change__c ic: invChangeList){
//                icIds.add(ic.id);
//            }
//            //system.debug('invChangeList: '+ invChangeList);      
//            List<Accounting_Entry__c> accountingEntryListIT = [Select id, Name, Inventory_Change__c 
//                                                                        //Total_Debit__c, Total_Credit__c
//                                                                        from Accounting_Entry__c
//                                                                        where Inventory_Change__c in :icIds];
//                                                                        
//                                                                    
//            system.debug('accountingEntryListIT: '+ accountingEntryListIT);     
//            system.assertNotEquals(null, accountingEntryListIT);
//            system.assertEquals(1, accountingEntryListIT.size());
//		}
//	}
//	
//	@isTest
//    static void mainTest(){
//    	
//    
//		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
//		User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
//  		EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
//  		LocaleSidKey='en_US', ProfileId = p.Id, 
//  		TimeZoneSidKey='America/Los_Angeles', UserName=string.valueOf(math.random()) + '@t' + string.valueOf(math.random()) + '.com');
//		insert u;
//		PermissionSet kndyAdmin = [SELECT Id FROM PermissionSet WHERE Name = 'Kenandy_Admin_Permissions' LIMIT 1];
//		PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = kndyAdmin.Id);
//		insert psa;
//		
//		system.runAs(u){
//	        ReportSampleData rsd = new ReportSampleData();
//	        
//	      	Report_Item__c ri = new Report_Item__c();
//	      	Financial_Report_Section__c frs = new Financial_Report_Section__c();
//	      	Financial_Report__c fr = new Financial_Report__c();
//	                            	
//	                            	
//	        // Financial Reports Data
//	        fr.Company__c = rsd.company.Id;
//	        fr.GL_Account__c = rsd.fuel.cashGL.id;
//	        List<Period__c> periodList = rsd.periodList;
//	        fr.Period_Name__c = periodList[0].Name;
//	
//	        insert fr;
//	
//	        // Financial Report Section Data
//	
//	        frs.Financial_Report__c	 = fr.Id;
//	        frs.Name = 'Assets';
//	
//	        insert frs;
//	
//	        // Report Item Data
//	
//	        ri.Financial_Report_Section__c = frs.Id;
//	        ri.Report_Id__c = null;
//	        ri.Name = 'Current Assets';
//	
//	       	insert ri;
//	
//	       	Set<Id> financialReportIds = new Set<Id>();
//	       	financialReportIds.add(frs.Id);
//	       	ReportService.ReportDefinition rd = new ReportService.ReportDefinition(fr.Company__c, 'Report_Item__c',  ri.Name, frs.Name, 'Balance Sheet');
//			rd.hashCode();
//			rd.equals(rd);
//			rd.generatekey(ri);
//	                            	
//	                            	
//            ReportService rs = new ReportService();
//	                            	
//            //TODO: Filter
//            List<Report> reportList =  [SELECT id, name 
//	                                    FROM Report 
//	                                    WHERE DeveloperName = 'AELs_Grouped_By_GL_w_Balance' LIMIT 1];
//					            
//            if (!reportList.isEmpty()) {
//            	
//            	test.startTest();
//            	
//            	Report testReport = reportList[0];	
//            	
// 				ri.Report_Id__c = testReport.Id;            	
//            
//		       	Reports.ReportMetaData metaData = Reports.ReportManager.describeReport(ri.Report_Id__c).getReportMetaData();
//		       	metaData = new Reports.ReportMetaData();
//		       	metaData.setReportFilters(new List<Reports.ReportFilter>());
//		       	system.debug(logginglevel.info, 'metaData: ' + metaData);
//		       	Reports.ReportInstance instance = Reports.ReportManager.runAsyncReport(ri.Report_Id__c); //,metaData
//		        Id reportId = testReport.Id;
//		        rs.runReport(ri);
//		
//		        //String reportStatus = Reports.ReportManager.getReportInstance(ri.Async_Report_Instance_Id__c).getStatus();
//		
//		        //Reports.ReportResults runReportResults = Reports.ReportManager.getReportInstance(ri.Async_Report_Instance_Id__c).getReportResults() ;
//		        List<String> filterFields =  new List<String>();
//			    for(string field : Reports.ReportManager.describeReport(ri.Report_Id__c).getReportMetaData().getDetailColumns()){
//			        filterFields.add(field);
//			    }
//				
//				
//			    ri.Filter_1__c = filterFields[0];
//		        ri.Filter_Operator_1__c = 'equals';
//		        ri.Filter_Value_1__c = 'cash';
//		
//		        ri.Filter_2__c  = filterFields[0];
//		        ri.Filter_Operator_2__c = 'equals';
//		        ri.Filter_Value_2__c = 'cash';
//		
//		        ri.Filter_3__c = filterFields[0];
//		        ri.Filter_Operator_3__c = 'equals';
//		        ri.Filter_Value_3__c = 'cash';
//		
//		        ri.Filter_4__c  =filterFields[0];
//		        ri.Filter_Operator_4__c = 'equals';
//		        ri.Filter_Value_4__c = 'cash';
//		
//		        ri.Filter_5__c  = filterFields[0];
//		        ri.Filter_Operator_5__c = 'equals';
//		        ri.Filter_Value_5__c = 'cash';
//		
//		        ri.Filter_6__c  = filterFields[0];
//		        ri.Filter_Operator_6__c = 'equals';
//		        ri.Filter_Value_6__c = 'cash';
//		
//		        ri.Filter_7__c  = filterFields[0];
//		        ri.Filter_Operator_7__c = 'equals';
//		        ri.Filter_Value_7__c = 'cash';
//		
//		        ri.Filter_8__c  = filterFields[0];
//		        ri.Filter_Operator_8__c = 'equals';
//		        ri.Filter_Value_8__c = 'cash';
//		
//		        ri.Filter_9__c  = filterFields[0];
//		        ri.Filter_Operator_9__c = 'equals';
//		        ri.Filter_Value_9__c = 'cash';
//		
//		        ri.Filter_10__c  =filterFields[0];
//		        ri.Filter_Operator_10__c = 'equals';
//		        ri.Filter_Value_10__c = 'cash';
//		
//		        ri.Filter_11__c  = filterFields[0];
//		        ri.Filter_Operator_11__c = 'equals';
//		        ri.Filter_Value_11__c = 'cash';
//		
//		        ri.Filter_12__c  = filterFields[0];
//		        ri.Filter_Operator_12__c = 'equals';
//		        ri.Filter_Value_12__c = 'cash';
//				
//				update ri;
//
//		        rs.runReport(ri);
//		        
//		        test.stopTest();
//		       	rs.loadLines(financialReportIds);
//		       	rs.financialReportSectionDetails(frs.Id,fr.Id);
//		       	Reports.ReportResults runReportResults = Reports.ReportManager.getReportInstance(rs.updatedReportItems[0].Async_Report_Instance_Id__c).getReportResults();
//		       	ReportService.parseColumns(runReportResults, ri);              
//            
//            	
//            }	                            	
//	
//
//		}
//	}


}