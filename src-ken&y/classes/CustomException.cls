public class CustomException extends Exception {
    public CustomException(Object obj) { throw new Custom2Exception('' + obj); }

    public static void addError(Exception e) { addError(getMessage(e)); }
    public static void addError(String msg) { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg)); }
    public static void addError(JsonResult result, Exception e) { addError(result, getMessage(e)); }
    public static void addError(JsonResult result, String msg) {
        result.success = false;
        result.addMessage(msg, ApexPages.Severity.ERROR);
    }
    
    public static String getMessage(Exception e) { return MessageUtil.toFriendlyErrorMessage(e.getMessage()) + (Configuration__c.getValues('STACKTRACE') != null ? ('\n' + e.getStackTraceString()) : ''); }

    private class Custom2Exception extends Exception { }
}