/**
 * This class contains unit tests for Code Coverage.
 */
@isTest
private class FinancialReportTest {

    static testMethod void fnRpt_test() {
		Financial_Report__c fr = new Financial_Report__c();
		fr.name = 'foo';
		insert fr;
		
		Financial_Report_Section__c frs = new Financial_Report_Section__c();
		frs.name = 'bar';
		frs.order__c = 1;
		//frs.report_id__c = null;
		frs.Financial_Report__c = fr.id;
		insert frs;
		
		Report_Item__c  ri = new Report_Item__c();
		ri.name = 'gack';
		ri.Financial_Report_Section__c =frs.id;
		insert ri;
	
		Apexpages.Standardcontroller con = new Apexpages.Standardcontroller( fr);
		FinancialReportExt ext = new FinancialReportExt(con);
		
		ext.saveOrder();
		
		FinancialReportExt.addNewReportItem(frs.id, ri.id, 'nam');
		
		system.assert(fr.id != null);
		system.assertEquals( 2, [ select id from Report_Item__c].size()); 
		
		// clone
		// TODO test setting the company , then it should clear out upon clone
		Pagereference p = ext.cloneFR(); 
		system.debug(loggingLevel.info, p.getUrl() ); 
		id clonedid = (id)p.getUrl().replaceAll('/','');
		system.assert( clonedid!= fr.id,' expected new record');
		list<Financial_Report_Section__c> sections = [ Select Id, Company__c, Name, Financial_Report__c, Order__c ,Display_Section_Name__c , 
            (select id, name,order__c,report_id__c,Financial_Report_Section__c,Show_Details__c,
                Total_Label__c, Display_Name__c, Display_Total__c, 
                Company__c, Asynchronous__c
                from        Report_Items__r order by order__c asc   )
            From Financial_Report_Section__c 
            where Financial_Report__c = :clonedid    order by Order__c asc  limit 1];
         system.debug(LoggingLevel.INFO, sections.size());
         
         system.assertEquals( 4, [ select id from Report_Item__c].size());
         boolean saw = false; 
         for( Report_Item__c rit: sections[0].Report_Items__r ){         	saw= true;         }
         system.assert(saw, ' no report items found after clone');
         
         system.assert(sections[0].Company__c == null);
         
         FinancialReportExt.removeReportItem(ri.id);
         system.assertEquals( 3, [ select id from Report_Item__c].size());
         
    }
}