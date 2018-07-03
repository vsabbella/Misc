/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ReportNameConTest {

    static testMethod void myUnitTest() {
        ReportNameCon con = new ReportNameCon(); 
        
        con.developerName = 'foo';
        string rid = con.reportId; 
        system.assert( rid== null);
        system.assert( con.getToday() != null);
        system.assert( con.weeksFromToday.size() == 10);
        system.assert( con.weeksBeforeToday.size() == 10);
    }
}