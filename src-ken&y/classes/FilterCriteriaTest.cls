//Deprecated as per KNDY-10059
//@isTest(SeeAllData='true')
public with sharing class FilterCriteriaTest {
    
//    @isTest
//    static void mainTest(){
//        
//        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
//        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
//        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
//        LocaleSidKey='en_US', ProfileId = p.Id, 
//        TimeZoneSidKey='America/Los_Angeles', UserName=string.valueOf(math.random()) + '@t' + string.valueOf(math.random()) + '.com');
//        insert u;
//        PermissionSet kndyAdmin = [SELECT Id FROM PermissionSet WHERE Name = 'Kenandy_Admin_Permissions' LIMIT 1];
//        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = kndyAdmin.Id);
//        insert psa;
//        
//        system.runAs(u){
//	        ReportServiceTest.ReportSampleData rsd = new ReportServiceTest.ReportSampleData();
//	        Report_Item__c ri = new Report_Item__c();
//	        Financial_Report_Section__c frs = new Financial_Report_Section__c();
//	        Financial_Report__c fr = new Financial_Report__c();
//	        List<Report> reportList =  [SELECT id, name 
//	                                    FROM Report 
//	                                    WHERE DeveloperName = 'Financial_Reports_Balance_Sheet' LIMIT 1];
//	                                    
//	        fr.Company__c = rsd.fuel.company.Id;
//	        fr.GL_Account__c = rsd.fuel.cashGL.id;
//	        List<Period__c> periodListtest = rsd.fuel.periodList;
//	        fr.Period_Name__c = periodListtest[0].Name;
//
//	        insert fr;
//
//	        // Financial Report Section Data
//
//	        frs.Financial_Report__c  = fr.Id;
//
//	        insert frs;
//
//	        // Report Item Data
//
//	        ri.Financial_Report_Section__c = frs.Id;
//	        //ri.Report_Id__c = testReport.Id;
//	        insert ri;
//	        List<String> filterFieldstest =  new List<String>();
//	        ri.Filter_1__c = 'equals';
//	        ri.Filter_Operator_1__c = 'equals';
//	        ri.Filter_Value_1__c = 'cash';
//
//	        ri.Filter_2__c  = 'equals';
//	        ri.Filter_Operator_2__c = 'equals';
//	        ri.Filter_Value_2__c = 'cash';
//
//	        ri.Filter_3__c = 'equals';
//	        ri.Filter_Operator_3__c = 'equals';
//	        ri.Filter_Value_3__c = 'cash';
//
//	        ri.Filter_4__c  ='equals';
//	        ri.Filter_Operator_4__c = 'equals';
//	        ri.Filter_Value_4__c = 'cash';
//
//	        ri.Filter_5__c  = 'equals';
//	        ri.Filter_Operator_5__c = 'equals';
//	        ri.Filter_Value_5__c = 'cash';
//
//	        ri.Filter_6__c  = 'equals';
//	        ri.Filter_Operator_6__c = 'equals';
//	        ri.Filter_Value_6__c = 'cash';
//
//	        ri.Filter_7__c  = 'equals';
//	        ri.Filter_Operator_7__c = 'equals';
//	        ri.Filter_Value_7__c = 'cash';
//
//	        ri.Filter_8__c  = 'equals';
//	        ri.Filter_Operator_8__c = 'equals';
//	        ri.Filter_Value_8__c = 'cash';
//
//	        ri.Filter_9__c  = 'equals';
//	        ri.Filter_Operator_9__c = 'equals';
//	        ri.Filter_Value_9__c = 'cash';
//
//	        ri.Filter_10__c  ='equals';
//	        ri.Filter_Operator_10__c = 'equals';
//	        ri.Filter_Value_10__c = 'cash';
//
//	        ri.Filter_11__c  = 'equals';
//	        ri.Filter_Operator_11__c = 'equals';
//	        ri.Filter_Value_11__c = 'cash';
//
//	        ri.Filter_12__c  = 'equals';
//	        ri.Filter_Operator_12__c = 'equals';
//	        ri.Filter_Value_12__c = 'cash';
//
//	        update ri;
//	        Apexpages.Standardcontroller conTest = new Apexpages.Standardcontroller(ri);
//	        FilterCriteria fctest = new FilterCriteria(conTest);
//	        test.setCurrentPage(page.FilterCriteria);
//	        fctest.save();
//	        //FilterCriteria.appendErrorMessage('String message');
//	        fctest.cancel();
//	        fctest.addFilter();       
//	        if (!reportList.isEmpty()) {
//	        	Report testReport = reportList[0];	
//		       // Financial Reports Data
//		        fr.Company__c = rsd.fuel.company.Id;
//		        fr.GL_Account__c = rsd.fuel.cashGL.id;
//		        List<Period__c> periodList = rsd.fuel.periodList;
//		        fr.Period_Name__c = periodList[0].Name;
//		        insert fr;
//		        // Financial Report Section Data
//		        frs.Financial_Report__c  = fr.Id;
//		        insert frs;
//		        // Report Item Data
//		        ri.Financial_Report_Section__c = frs.Id;
//		        ri.Report_Id__c = testReport.Id;
//		        insert ri;
//		        Set<Id> financialReportIds = new Set<Id>();
//		        financialReportIds.add(frs.Id);
//		        //Id reportId = testReport.Id;
//		        //Reports.ReportMetaData metaData = Reports.ReportManager.describeReport(ri.Report_Id__c).getReportMetaData();
//		        test.startTest();
//		        //Reports.ReportInstance instance = Reports.ReportManager.runAsyncReport(ri.Report_Id__c,metaData); 
//		        ReportService rs = new ReportService();
//		        system.assertNotEquals(null, ri.report_id__c, 'this report item should have a report id');
//		        rs.runReport(ri);
//		        update rs.updatedReportItems;
//		        test.stopTest(); 
//		        ri.Async_Report_Instance_Id__c = rs.updatedReportItems[0].Async_Report_Instance_Id__c;
//		        //update ri;
//		        String reportStatus = Reports.ReportManager.getReportInstance(ri.Async_Report_Instance_Id__c).getStatus();
//		        Reports.ReportResults runReportResults = Reports.ReportManager.getReportInstance(ri.Async_Report_Instance_Id__c).getReportResults() ;
//		        List<String> filterFields =  new List<String>();
//		        for(string field : Reports.ReportManager.describeReport(ri.Report_Id__c).getReportMetaData().getDetailColumns()){
//		            filterFields.add(field);
//		        }
//		        ri.Filter_1__c = filterFields[0];
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
//		        update ri;
//		
//		        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(ri);
//		
//		        FilterCriteria fc = new FilterCriteria(con);
//		        test.setCurrentPage(page.FilterCriteria);
//		        fc.save();
//		        //FilterCriteria.appendErrorMessage('String message');
//		        fc.cancel();
//		        fc.addFilter();  
//	        }
//		}
//	}
//

}