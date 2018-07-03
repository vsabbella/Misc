@isTest
/**
 * Utility functions for help in test cases
 */ 
public class TestHelper {
    /**
     *  Checks if current ApexPages.messages are having a message of given severity and summary
     */ 
    public static boolean hasPageMessage(ApexPages.Severity sev, String summary) {
        for ( ApexPages.Message msg : ApexPages.getMessages() ) {
            if (sev == msg.getSeverity() && msg.getSummary().indexOfIgnoreCase(summary) > -1) return true;
        }
        return false;
    }
}