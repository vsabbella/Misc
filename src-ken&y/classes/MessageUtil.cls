/**
 * Utility functions for Message classes like ApexPages.Message and ServiceMessage
 */ 
public with sharing class MessageUtil {
    
    public enum Severity{
        CONFIRM, INFO, WARNING, ERROR, FATAL
    }
    
	/**
    *  Converts a JSON Message to an ApexPages.Message
    */
	public static ApexPages.Message toApexPageMessage(Map<String, String> msg) {
	    
	    String severity = msg.get('severity');
	    String summary = msg.get('message');
	    String details = msg.get('details');
	    
	    ApexPages.Severity apexSeverity = null;
	    
	    if (severity == MessageUtil.Severity.ERROR.name()) {
	        apexSeverity = ApexPages.Severity.ERROR;
	    } else if (severity == MessageUtil.Severity.FATAL.name()) {
	        apexSeverity = ApexPages.Severity.FATAL;
	    } else if (severity == MessageUtil.Severity.WARNING.name()) {
	        apexSeverity = ApexPages.Severity.WARNING;
	    } else if (severity == MessageUtil.Severity.CONFIRM.name()) {
	        apexSeverity = ApexPages.Severity.CONFIRM;
	    } else if (severity == MessageUtil.Severity.INFO.name()) {
	        apexSeverity = ApexPages.Severity.INFO;
	    }
	    
	    // clean up the message a bit..
	    // 15:36:21:000 USER_DEBUG caused by: System.DmlException: Update failed. First exception on row 0 with id a1Yo0000000MmgpEAC; first error: 
	    // FIELD_CUSTOM_VALIDATION_EXCEPTION, You cannot have a negative total from all the lines on a Sales Order.: []
	     
	    String pat = 'FIELD_CUSTOM_VALIDATION_EXCEPTION,';
        if ( summary.contains( pat ) ){
            summary = summary.split(pat)[1].replace('[]','').trim();
        }	    
        
        ApexPages.Message pageMsg ;
	    if (!String.isBlank(details)) {
    		pageMsg = new ApexPages.Message(apexSeverity, summary +' ['+ details +']');
	    } else {
    		pageMsg = new ApexPages.Message(apexSeverity, summary);
	    }
	    
	    return pageMsg;
	}

	public static String toFriendlyErrorMessage(String errorMessage) {
		String returnMessage;
		if(errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
			returnMessage = errorMessage.substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION');

			if(returnMessage.contains(': []')) {
				returnMessage = returnMessage.substringBefore(': []');
			}

			//Use Regex to trim special chars and spaces from beginning of string.
			returnMessage = returnMessage.replaceAll('^[^a-zA-Z0-9\\s]', '');
		} else {
			returnMessage = errorMessage;
		}

		return returnMessage;
	}
}