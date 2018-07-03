// User-defined class to serialize the JSON expected by the Kendo api
global with sharing class JsonResult {
    
    global boolean success = true;
    
    global string message { get; set; }    
    global string reason { get; set; }
    public string additionalInfo { get;set; }
    public boolean hasExceptions { get;set; }
    global List<Object> records { get; set; }
    global long total { get; set; }
    /*
        Abhinav: As this class is global, keeping the error model flexible as Map instead of fixed error class.
        As required in different scenarios error handling blocks in apex, can create required representation of error model.
        We can always keep one field to distinguish if its error, info or other type of message, where we could use ApexPages.Severity
        with following values

        CONFIRM
        ERROR
        FATAL
        INFO
        WARNING
     */
    global List<Map<String, String>> messages { get; set; }
    
    // Initaliser block to set defaults
    {
        this.success = true; // default 
        this.messages = new List<Map<String, String>>();    
    }
    
    global JsonResult() {
        
    }
    
    global JsonResult(List<Object> records, long total) {
        this.records = records;
        this.total = total;
    }

    
    global void addMessage(Object msg, ApexPages.Severity severity) {        
        String severityStr =  String.valueOf(severity);

        if (msg instanceof DmlException) {            
            DmlException ex = (DmlException) msg;
            for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {
                Map<String, String> error = new Map<String, String>{
                    //Returns the ID of the failed record that caused the error described by the ith failed row.
                    'recordId' => ex.getDmlId(idx),
                    // Returns the original row position of the ith failed row.
                    'rowIndex' => String.valueOf(ex.getDmlIndex(idx)), 
                    'message' => MessageUtil.toFriendlyErrorMessage(ex.getDmlMessage(idx)),
                    'code' => String.valueOf(ex.getDmlType(idx)),
                    'severity' => severityStr
                };
                this.messages.add(error);    
            }            
        } else if (msg instanceof Exception) {            
            Exception ex = (Exception) msg;
            Map<String, String> error = new Map<String, String>{                    
                'message' => MessageUtil.toFriendlyErrorMessage(ex.getMessage()),
                'severity' => severityStr                    
            };
            this.messages.add(error);   
        } else {
            Map<String, String> msgObj = new Map<String, String>{                    
                // serialise what ever it is string or anything else
                'message' => MessageUtil.toFriendlyErrorMessage(String.valueOf(msg)),
                'severity' => severityStr                    
            };
            this.messages.add(msgObj);   
        }       
        
    }
}