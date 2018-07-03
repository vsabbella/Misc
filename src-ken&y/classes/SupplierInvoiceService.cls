public with sharing class SupplierInvoiceService {
    
    public static ExceptionService exService = new ExceptionService();
    public static SchemaUtil util = SchemaUtil.getInstance();
    public static string NamespaceUU { get { return KSE.NamespaceUU; }}
    public class SIException extends Exception{}
    //User Access Permissions
    private static Boolean hasSICreateAccess; //KNDY-17757
    private static Boolean hasSIEditAccess; //KNDY-17757
    private static Boolean hasSILCreateAccess;//KNDY-17757
    private static Boolean hasSILDeleteAccess;//KNDY-17757
    
    
    //Invoice Types
    public static String invTypeInvoice = 'Invoice';
    public static String invTypeCM = 'Credit Memo';
    public static String invTypePrepymt = 'Prepayment';
    
    public static String poLineInvStatusOpen = 'Open for Invoicing';
    public static boolean voidedFlag = false;
    public static boolean resetFlag = false;
    public static boolean lineResetFlag = false; 
	public static boolean polQtyFlag = false;
    public static boolean unfinalizeFlag = false;

    //Invoice Statuses
    public static final string STATUS_CLOSED = 'Closed';
    public static final string STATUS_OPEN = 'Open';
    public static final string STATUS_CANCELLED = 'Cancelled';
    public static final string STATUS_VOID = 'Void';
    public static final string STATUS_APPROVED = 'Approved';

    // Validates the save action 
    public static Boolean validateSave(Supplier_Invoice__c si, List<Supplier_Invoice_Line__c> siLines, JSONResult result){
        result.success = true;
        if (si != null){
            validateSI(si, result);
        }
        if(result.messages.size() > 0){
            result.success = false;
        }
        if (result.success == true && siLines != null && siLines.size() > 0){
            validateSILs(si, siLines, result);
        }
        if(result.messages.size() > 0){
            result.success = false;
        }
        return result.success;
    }
    
    // These checks should be done for saving SI via API
    public static void validateSI(Supplier_Invoice__c si, JSONResult result){ 
        if(si.Company__c == null){  
            result.addMessage(ExceptionUtil.MISSING_COMPANY.description, ApexPages.Severity.ERROR);
        }
        if(si.Supplier__c == null){
            result.addMessage(ExceptionUtil.MISSING_SUPPLIER.description, ApexPages.Severity.ERROR);
        }
        if(si.Date_Invoiced__c == null){                  
            result.addMessage(ExceptionUtil.MISSING_DATE_INVOICED.description, ApexPages.Severity.ERROR);
        }
        if(si.Supplier_Invoice__c == null){                   
            result.addMessage(ExceptionUtil.MISSING_INVOICE_NUMBER.description, ApexPages.Severity.ERROR);
        }
        
        //Assumption: Invoice Type is not blank
        if(si.Invoice_Type__c == invTypeInvoice){  
            if(si.Invoice_Amount__c == null || si.Invoice_Amount__c < 0){                       
                result.addMessage(ExceptionUtil.NEGATIVE_INVOICE_AMOUNT.description, ApexPages.Severity.ERROR);
            }
        }
        //START OF CREDIT MEMO SPECIFIC HEADER VALIDATIONS
        else if(si.Invoice_Type__c ==  invTypeCM){ 
            if(si.Invoice_Amount__c == null){                             
                result.addMessage(ExceptionUtil.MISSING_CREDIT_MEMO_AMT.description, ApexPages.Severity.ERROR);
            }
            if(si.Invoice_Amount__c == null || si.Invoice_Amount__c > 0){                       
                result.addMessage(ExceptionUtil.POSITIVE_INVOICE_AMOUNT.description, ApexPages.Severity.ERROR);
            }
        } 
        //START OF Prepayment INVOICE SPECIFIC HEADER VALIDATIONS
        else if(si.Invoice_Type__c == invTypePrepymt){  
            if(si.Invoice_Amount__c == null || si.Invoice_Amount__c < 0){                       
                result.addMessage(ExceptionUtil.NEGATIVE_INVOICE_AMOUNT.description, ApexPages.Severity.ERROR);
            }
        } 
    }
    
    //Validates the invoice lines from the UI
    public static void validateSILs(Supplier_Invoice__c si, List<Supplier_Invoice_Line__c> siLines, JSONResult result){  
        for(Supplier_Invoice_Line__c sil : siLines){
            if (si.Invoice_Type__c == invTypeInvoice && sil.Purchase_Order_Line__r.Invoice_Status__c == 'Closed for Invoicing'){ 
                result.addMessage(' (' + sil.Item__r.Name + '):  ' + ExceptionUtil.POLINE_INVOICE_STATUS_CLOSED.description, ApexPages.Severity.ERROR);
            }
            if(sil.Item__c == null && sil.Purchase_Order_Line__c != null){
                result.addMessage(' (' + sil.Item__r.Name + '):  ' + ExceptionUtil.MISSING_ITEM.description, ApexPages.Severity.ERROR);
            }
            if(sil.Purchase_Order__c != null && sil.Purchase_Order_Line__c == null){
                result.addMessage(' (' + sil.Item__r.Name + '):  ' + ExceptionUtil.MISSING_POLINE.description, ApexPages.Severity.ERROR);
            }
            if(sil.Unit_Price__c < 0 && sil.Invoice_Quantity__c < 0){//KNDY-14371
                result.addMessage(' (' + sil.Item__r.Name + '):  ' + ExceptionUtil.SI_NEGATIVE_PRICE_QTY.description, ApexPages.Severity.ERROR);
            }
            if(sil.Invoice_Quantity__c == 0 || sil.Invoice_Quantity__c == null){
                result.addMessage(' (' + sil.Item__r.Name + '):  ' + ExceptionUtil.SI_ZERO_QUANTITY.description, ApexPages.Severity.ERROR);
            }
            if(si.Invoice_Type__c ==  invTypePrepymt && (sil.Invoice_Quantity__c * sil.Unit_Price__c < 0)){//KNDY-14371
                result.addMessage(' (' + sil.Item__r.Name + '):  ' + ExceptionUtil.NEGATIVE_LINE_AMOUNT.description, ApexPages.Severity.ERROR);
            }
            if(si.Invoice_Type__c ==  invTypeInvoice){
                if(sil.Purchase_Order_Line__c != null && sil.Purchase_Order_Line__r.Item__c != sil.Item__c && sil.Item__r.Source__c != 'Miscellaneous'){                    
                    result.addMessage(' (' + sil.Item__r.Name + '):  ' + ExceptionUtil.INVALID_ITEM.description, ApexPages.Severity.ERROR);
                }
            }
        }
    }

    //Actions dropdown options depend on this method
    // Called from page for SI with Id
    public static String populateSISaveAndActions(Id supplierInvoiceId){ 
        
        Map<String,boolean> actionsMapOnSI = new Map<String,boolean>();
        SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c',true);
        soql.addFields(new set<string>{'Id', 'Invoice_Amount__c', 'Balance_Due__c', 'Invoice_Type__c', 'Status__c', 'Finalized__c', 'Credit_Memo_Amount__c', 'Credit_Memo_Balance__c', 'Exception__c'});
        soql.setWhereClause('Id = :supplierInvoiceId');
        
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
        childRel.addFields(new set<string>{'Id'});
        childRel.setWhereClause('Status__c = \'Active\' and Has_Exceptions__c = false');
        soql.addChildRelationship(childRel);
        
        system.debug(loggingLevel.error, 'query on populateSIActions-->' + soql.getQuery());  
        
        List<Supplier_Invoice__c> invoiceSelected = Database.query(soql.getQuery());
        System.debug(logginglevel.error,'invoiceSelected-->'+invoiceSelected);
        for (Supplier_Invoice__c invoice: invoiceSelected){
              if(invoice.Status__c == 'Incomplete' || invoice.Status__c == 'Draft'){
                    
                    actionsMapOnSI.put('Save',true);
                    actionsMapOnSI.put('Save_New',true);
                    actionsMapOnSI.put('Save_Return',true);
                    actionsMapOnSI.put('Save_Validate',true);
                    
                    actionsMapOnSI.put('Clone',true);
                    actionsMapOnSI.put('Validate',true);
                    if(invoice.Status__c == 'Incomplete'){
                        actionsMapOnSI.put('Get_Tax',true);
                    }else{
                        actionsMapOnSI.put('Get_Tax',false);
                    }    
                    actionsMapOnSI.put('Unfinalize',false);
                    actionsMapOnSI.put('Void',false);
                    actionsMapOnSI.put('Cancel',true);
                    actionsMapOnSI.put('Pay_Invoice',false);
               }else if(invoice.Status__c == 'Approved' && invoice.Finalized__c){
                   
                    actionsMapOnSI.put('Save',true);
                    actionsMapOnSI.put('Save_New',true);
                    actionsMapOnSI.put('Save_Return',true);
                    actionsMapOnSI.put('Save_Validate',false);
                   
                    actionsMapOnSI.put('Clone',true);
                    actionsMapOnSI.put('Validate',false);
                    actionsMapOnSI.put('Get_Tax',false);
                    if(((invoice.Invoice_Type__c == 'Invoice' || invoice.Invoice_Type__c == 'Prepayment')  && invoice.Invoice_Amount__c == invoice.Balance_Due__c)
                          || ((invoice.Invoice_Type__c == 'Credit Memo') && invoice.Credit_Memo_Amount__c == invoice.Credit_Memo_Balance__c ) ){ 
                        actionsMapOnSI.put('Unfinalize',true);
                    }else{
                        actionsMapOnSI.put('Unfinalize',false); 
                    } 
                    if(((invoice.Invoice_Type__c == 'Invoice' || invoice.Invoice_Type__c == 'Prepayment')  && invoice.Invoice_Amount__c == invoice.Balance_Due__c)
                          || ((invoice.Invoice_Type__c == 'Credit Memo') && invoice.Credit_Memo_Amount__c == invoice.Credit_Memo_Balance__c ) ){ 
                        actionsMapOnSI.put('Cancel',true);
                    }else{
                        actionsMapOnSI.put('Cancel',false);
                    } 
                    
                    if((((invoice.Invoice_Type__c == 'Invoice' || invoice.Invoice_Type__c == 'Prepayment')  && invoice.Invoice_Amount__c == invoice.Balance_Due__c)
                          || ((invoice.Invoice_Type__c == 'Credit Memo') && invoice.Credit_Memo_Amount__c == invoice.Credit_Memo_Balance__c ))
                          && (invoice.Accounting_Entries__r != null && invoice.Accounting_Entries__r.size() > 0) ){ 
                        actionsMapOnSI.put('Void',true);
                    }else{
                        actionsMapOnSI.put('Void',false);
                    }

                  if((invoice.get('Invoice_Type__c') == 'Invoice' || invoice.get('Invoice_Type__c') == 'Prepayment') && invoice.get('Exception__c') == false){
                      actionsMapOnSI.put('Pay_Invoice',true);
                    }else{
                       actionsMapOnSI.put('Pay_Invoice',false);
                    }  
              }else if(invoice.Status__c == 'Closed' || invoice.Status__c == 'Cancelled' ||  invoice.Status__c == 'Void'){
                   
                    actionsMapOnSI.put('Save',false);
                    actionsMapOnSI.put('Save_New',false);
                    actionsMapOnSI.put('Save_Return',false);
                    actionsMapOnSI.put('Save_Validate',false);
                    actionsMapOnSI.put('Clone',true);
                    actionsMapOnSI.put('Validate',false);
                    actionsMapOnSI.put('Get_Tax',false);
                    actionsMapOnSI.put('Unfinalize',false);
                    actionsMapOnSI.put('Cancel',false);
                    actionsMapOnSI.put('Void',false);
                    actionsMapOnSI.put('Get_Tax',false);
                    actionsMapOnSI.put('Pay_Invoice',false);
                    if(invoice.Status__c == 'Closed'){
	                    actionsMapOnSI.put('Save',true);
	                    actionsMapOnSI.put('Save_New',true);
	                    actionsMapOnSI.put('Save_Return',true);
                    }    
            }
        }
        disableSIActionsForUser(actionsMapOnSI);//KNDY-17757

      System.debug(logginglevel.error,'actionsMapOnSI--->'+actionsMapOnSI);  
      String actionMapStr = JSON.serialize(actionsMapOnSI);
      return actionMapStr; //actionsMapOnSI
    }
    
    // Called from page for new SI without id
    public static String populateUserSIActions(){//KNDY-17757
        Map<String,boolean> actionsMapOnSI = new Map<String,boolean>();
        setDefaultActionsForNewSI(actionsMapOnSI);
        disableSIActionsForUser(actionsMapOnSI);
        String actionMapStr = JSON.serialize(actionsMapOnSI);
        return actionMapStr;
    }
    
    // Save action - With create permissions only, save a new si should be allowed
    // With edit permissions only, save a new si should not be allowed, but saving changes on si should be allowed.
    private static void disableSIActionsForUser(Map<String,boolean> actionsMapOnNewSI){//KNDY-17757
        setUserAccessDetails();
        if (!hasSICreateAccess){
             actionsMapOnNewSI.put('Save_New',false);
             actionsMapOnNewSI.put('Clone',false);
        }
        if (!hasSIEditAccess){
             actionsMapOnNewSI.put('Save_Validate',false);
             actionsMapOnNewSI.put('Validate',false);
             actionsMapOnNewSI.put('Get_Tax',false);
             actionsMapOnNewSI.put('Finalize',false);
             actionsMapOnNewSI.put('Unfinalize',false);
             actionsMapOnNewSI.put('Cancel',false);
             actionsMapOnNewSI.put('Pay_Invoice',false);
        }
    }
    
    private static void setDefaultActionsForNewSI(Map<String,boolean> actionsMapOnNewSI){//KNDY-17757
        // Save Drop down
        if (!actionsMapOnNewSI.containsKey('Save')) {actionsMapOnNewSI.put('Save',true);}
        if (!actionsMapOnNewSI.containsKey('Save_New')) {actionsMapOnNewSI.put('Save_New',true);}
        if (!actionsMapOnNewSI.containsKey('Save_Return')) {actionsMapOnNewSI.put('Save_Return',true);}
        if (!actionsMapOnNewSI.containsKey('Save_Validate')) {actionsMapOnNewSI.put('Save_Validate',true);}
        
        // Action drop down
        if (!actionsMapOnNewSI.containsKey('Clone')) { actionsMapOnNewSI.put('Clone',false);}
        if (!actionsMapOnNewSI.containsKey('Validate')) {actionsMapOnNewSI.put('Validate',false);}
        if (!actionsMapOnNewSI.containsKey('Get_Tax')) {actionsMapOnNewSI.put('Get_Tax',false);}
        if (!actionsMapOnNewSI.containsKey('Finalize')) {actionsMapOnNewSI.put('Finalize',false);}
        if (!actionsMapOnNewSI.containsKey('Unfinalize')) {actionsMapOnNewSI.put('Unfinalize',false);}
        if (!actionsMapOnNewSI.containsKey('Cancel')) {actionsMapOnNewSI.put('Cancel',false);}
        if (!actionsMapOnNewSI.containsKey('Void')) {actionsMapOnNewSI.put('Void',false);}
        if (!actionsMapOnNewSI.containsKey('Pay_Invoice')) {actionsMapOnNewSI.put('Pay_Invoice',false);}
    }
    
    //Grid Icons depend on this method
    public static String populateSILActions(Supplier_Invoice__c si){ //KNDY-17757
         Map<String,boolean> actionsMapOnSIL = new Map<String,boolean>();
         actionsMapOnSIL.put('Create',true);
         actionsMapOnSIL.put('Clone',true);
         actionsMapOnSIL.put('Delete',true);
         actionsMapOnSIL.put('MatchToPO', true);
         actionsMapOnSIL.put('Cancel', true);
         if( si.Status__c == 'Cancelled' ||  si.Status__c == 'Void'){
             actionsMapOnSIL.put('Create',false);
             actionsMapOnSIL.put('Clone',false);
             actionsMapOnSIL.put('Delete',false);
        }
        setUserAccessDetails();
        if (!hasSILCreateAccess){
             actionsMapOnSIL.put('Create',false);
             actionsMapOnSIL.put('Clone',false);
             actionsMapOnSIL.put('MatchToPO', false);
        }
        If (!hasSILDeleteAccess){
             actionsMapOnSIL.put('Delete',false);
        }
        System.debug(logginglevel.error,'actionsMapOnSIL--->'+actionsMapOnSIL);  
        String actionMapStr = JSON.serialize(actionsMapOnSIL);
        return actionMapStr; 
    }
    
    // user access details
    private static void setSICreateAccess(){ //KNDY-17757
        try{
            hasSICreateAccess = true;
            Supplier_Invoice__c siTest = new Supplier_Invoice__c();
            DML.checkInsert(siTest);
        }catch (Exception ex){
            hasSICreateAccess = false;
        }
    }

    private static void setSIEditAccess(){ //KNDY-17757
        try{
            hasSIEditAccess = true;
            Supplier_Invoice__c siTest = new Supplier_Invoice__c();
            DML.checkUpdate(siTest);
        }catch (Exception ex){
            hasSIEditAccess = false;
        }
    }
    
    private static void setSILDeleteAccess(){ //KNDY-17757
        try{
            hasSILDeleteAccess = true;
            Supplier_Invoice_Line__c silTest = new Supplier_Invoice_Line__c();
            DML.checkDelete(silTest);
        }catch (Exception ex){
            hasSILDeleteAccess = false;
        }
    }
    
    private static void setSILCreateAccess(){ //KNDY-17757
        try{
            hasSILCreateAccess = true;
            Supplier_Invoice_Line__c silTest = new Supplier_Invoice_Line__c();
            DML.checkInsert(silTest);
        }catch (Exception ex){
            hasSILCreateAccess = false;
        }
    }
    
    private static void setUserAccessDetails(){ //KNDY-17757
        setSICreateAccess();
        setSIEditAccess();
        setSILCreateAccess();
        setSILDeleteAccess();
    }
    // end user access details
    
    
    private static map<ID,Currency__c> currencyMap  = new map<ID,Currency__c>();
    public static Currency__c getSICurrency(id siCurrency){
        if(siCurrency != null){
            if(currencyMap.containsKey(siCurrency) == false){
	            SOQLUtil soql = new SOQLUtil('Currency__c', true); //enforceFLS=true, running in user mode
	            soql.addFields(new set<string>{
	                'id','Name'
	            });
	            soql.setWhereClause('Id = :siCurrency');
	            List<Currency__c> currs = ((List<Currency__c>)Database.query(soql.getQuery()));
		        if(currs.size() > 0){
		            currencyMap.put(siCurrency,currs.get(0));
		        }
            }
            return currencyMap.get(siCurrency);
        }else{
            return null;
        }
    }

    //Validates the SI on the SI, if succeeds turns the SI to approved.
    public static JsonResult inspectSI (Id siId) {
       JsonResult result = new JsonResult();
       Supplier_Invoice__c si = new  Supplier_Invoice__c ();   
       result = validateInspect(siId);
       if (result.records != null && result.records.size() > 0){
            si = (Supplier_Invoice__c)result.records[0];
       }
       
       if (result.success == true){        
           if (si.Status__c == 'Incomplete') {
                Savepoint sp = Database.setSavepoint();     
                try{
                    SupplierInvoiceService.inspectIncompleteInvoices(new List<Supplier_Invoice__c>{si});
                }catch(DMLException ex) {
                    Database.rollback(sp);
                    result.success = false;
                    //result.addMessage((Label.Validate_draft_SI + e.getMessage() + ',' + Label.Error_occurred_contact_support ), ApexPages.Severity.FATAL); 
                     for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {
                        string errorMessage = ex.getDmlMessage(idx);
                        Integer location;    
                        if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                        list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
    
                        if(!msgArray.isEmpty()){
                            errorMessage = msgArray.get(msgArray.size()-1);
    
                            if(errorMessage.contains(': []: []')){
                                location = errorMessage.lastIndexOf(': []: []');
                                errorMessage = errorMessage.mid(0, location);
                            }
                            if(errorMessage.contains(': []')){
                                location = errorMessage.lastIndexOf(': []');
                                errorMessage = errorMessage.mid(0, location);
                            }
                        }
                     } 
                    result.addMessage(errorMessage + ' ' + Label.Error_occurred_contact_support, ApexPages.severity.FATAL);
                  }       
                }catch(Exception e) {
                    Database.rollback(sp);
                    result.success = false;
                    string errorMessage = e.getMessage();
                    integer location;    
                    if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                        list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
                        if(!msgArray.isEmpty()){
                            errorMessage = msgArray.get(msgArray.size()-1);
                            if(errorMessage.contains(': []: []')){
                                location = errorMessage.lastIndexOf(': []: []');
                                errorMessage = errorMessage.mid(0, location);
                            }
                            if(errorMessage.contains(': []')){
                                location = errorMessage.lastIndexOf(': []');
                                errorMessage = errorMessage.mid(0, location);
                            }
                        }
                    }    
                    result.addMessage(errorMessage + ' ' + Label.Error_occurred_contact_support, ApexPages.Severity.FATAL);
                } 
            }
            
            if (result.success == true && si.Status__c == 'Draft') {
                Savepoint sp2 = Database.setSavepoint();    
                try{
					Id sinvId = si.Id;//KNDY-11661
					SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
					soql.addFields(new set<string>{
						'Id','Name','Invoice_Type__c','Company__c','Supplier__c','Date_Invoiced__c','Supplier_Invoice__c','Memo__c','Invoice_Amount__c',
						'Total_Extended_Price__c','Status__c','Purchase_Order__c','Purchase_Order__r.Supplier__c'
					});
					soql.setWhereClause('Id = :sinvId  and Hold__c = false FOR UPDATE');
					
					si = Database.query(soql.getQuery());

                    SupplierInvoiceService.inspectDraftInvoices(new List<Supplier_Invoice__c>{si});
                }catch(DMLException ex) {
                    Database.rollback(sp2);
                    result.success = false;
                    //result.addMessage((Label.Validate_draft_SI + e.getMessage() + ',' + Label.Error_occurred_contact_support ), ApexPages.Severity.FATAL); 
                     for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {
                        string errorMessage = ex.getDmlMessage(idx);
                        Integer location;    
                        if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                        list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
    
                        if(!msgArray.isEmpty()){
                            errorMessage = msgArray.get(msgArray.size()-1);
    
                            if(errorMessage.contains(': []: []')){
                                location = errorMessage.lastIndexOf(': []: []');
                                errorMessage = errorMessage.mid(0, location);
                            }
                            if(errorMessage.contains(': []')){
                                location = errorMessage.lastIndexOf(': []');
                                errorMessage = errorMessage.mid(0, location);
                            }
                        }
                     } 
                    result.addMessage(errorMessage + ' ' + Label.Error_occurred_contact_support, ApexPages.severity.FATAL);
                  }       
                }catch(Exception e) {
                    Database.rollback(sp2);
                    result.success = false;

                    string errorMessage = e.getMessage();
                    integer location;    
	                if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
	                    list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
	                    if(!msgArray.isEmpty()){
	                        errorMessage = msgArray.get(msgArray.size()-1);
	                        if(errorMessage.contains(': []: []')){
	                            location = errorMessage.lastIndexOf(': []: []');
	                            errorMessage = errorMessage.mid(0, location);
	                        }
	                        if(errorMessage.contains(': []')){
	                            location = errorMessage.lastIndexOf(': []');
	                            errorMessage = errorMessage.mid(0, location);
	                        }
	                    }
	                }    
	                result.addMessage(errorMessage + ' ' + Label.Error_occurred_contact_support, ApexPages.Severity.FATAL);
                }
           }
       }
       return result;      
    }

    // Validates the SI
    private static JsonResult validateInspect(Id siId){
        JsonResult result = new JsonResult();
        result.success = true;
        if ( String.isBlank(siId) ) { 
            result.success = false;
            result.addMessage(Label.Cannot_perform_any_action_save_the_supplier_invoice_to_proceed, ApexPages.Severity.FATAL);       
        } 
        else {
            set<String> fieldStrings = new set<string>{'Id','Name','CreatedById'};
            fieldStrings.addAll(util.getAllCustomFieldsFromObject('','Supplier_Invoice__c'));
            fieldStrings.addAll(util.getAllCustomFieldsFromObject('Purchase_Order__r.','Purchase_Order__c'));
            fieldStrings.addAll(util.getAllCustomFieldsFromObject('Purchase_Order__r.Purchase_Agreement__r.','Contract__c'));

            String whereClause = 'Id=' + '\''+siId + '\'' + ' FOR UPDATE';
        
		    SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c');
		    soql.addFields(fieldStrings);
		    soql.setWhereClause(whereClause);
	    	
	    	List<Supplier_Invoice__c> sis = Database.query(soql.getQuery());
            if(sis.size() == 0){
                result.success = false;
                result.addMessage('Invoice not found', ApexPages.Severity.FATAL);                          
            }else{
                Supplier_Invoice__c si = sis[0];
                list<Supplier_Invoice__c> records = new list<Supplier_Invoice__c>();  
                records.add(si);
                result.records = records;              
                if ((si.Status__c != 'Incomplete') && (si.Status__c != 'Draft')) {
                    result.success = false;
                    result.addMessage(Label.Record_not_in_Incomplete_Draft_status, ApexPages.Severity.FATAL);        
                }  
                if(si.Hold__c == true) {
                    result.success = false;
                    result.addMessage('Invoice is on Hold.', ApexPages.Severity.FATAL);        
                }                
            }                          
        }
        return result;
    }
    
    // This method inspects the incomplete invoices
    public static boolean inspectIncompleteInvoices(List<Supplier_Invoice__c> incompleteInvoices){  
        Set<Id> supplierInvoiceIds = new Set<Id>();
    	
        for(Supplier_Invoice__c si : incompleteInvoices){
            supplierInvoiceIds.add(si.Id);
    		
			//START OF SUPPLIER INVOICE AND CREDIT MEMO GENERIC HEADER VALIDATIONS
			//Assumption: Invoice Type is not blank and is either Invoice or Credit Memo
            if(si.Company__c == null){  
                exService.setException(si,ExceptionUtil.MISSING_COMPANY);
            } 
            else{
                exService.clearException(si,ExceptionUtil.MISSING_COMPANY);
            }
            
            if(si.Supplier__c == null){                                                  
                exService.setException(si,ExceptionUtil.MISSING_SUPPLIER);
            } 
            else{
                exService.clearException(si,ExceptionUtil.MISSING_SUPPLIER);
            }
            
            if(si.Date_Invoiced__c == null){                  
                exService.setException(si,ExceptionUtil.MISSING_DATE_INVOICED);
            }
            else{
                exService.clearException(si,ExceptionUtil.MISSING_DATE_INVOICED);
            }
            
            if(si.Supplier_Invoice__c == null){                   
                exService.setException(si,ExceptionUtil.MISSING_INVOICE_NUMBER);   
            }
            else{
                exService.clearException(si,ExceptionUtil.MISSING_INVOICE_NUMBER);
            }
            
            if(si.Payment_Due_Override_Date__c == null){
                exService.setException(si,ExceptionUtil.SI_PAYMENT_DUE_DATE);  
            }else{
                exService.clearException(si,ExceptionUtil.SI_PAYMENT_DUE_DATE);
            }
            
            //START OF SUPPLIER INVOICE SPECIFIC HEADER VALIDATIONS
            if(si.Invoice_Type__c == invTypeInvoice){  
                if(si.Invoice_Amount__c == null || si.Invoice_Amount__c < 0){                       
                    exService.setException(si,ExceptionUtil.NEGATIVE_INVOICE_AMOUNT);  
                }
                else{
                    exService.clearException(si,ExceptionUtil.NEGATIVE_INVOICE_AMOUNT);
                }
                if(si.Total_Extended_Price__c != si.Invoice_Amount__c){                                   
                    exService.setException(si,ExceptionUtil.MISMATCH_SI_SUM);  
                }
                else{
                    exService.clearException(si,ExceptionUtil.MISMATCH_SI_SUM);
                }
            }
            //START OF CREDIT MEMO SPECIFIC HEADER VALIDATIONS
            else if(si.Invoice_Type__c ==  invTypeCM){ 
                if(si.Invoice_Amount__c == null){                             
                    exService.setException(si,ExceptionUtil.MISSING_CREDIT_MEMO_AMT);   
                }
                else{
                    exService.clearException(si,ExceptionUtil.MISSING_CREDIT_MEMO_AMT);
                }
                
                if(si.Total_Extended_Price__c != si.Invoice_Amount__c){                                                  
                    exService.setException(si,ExceptionUtil.MISMATCH_CREDIT_MEMO_AMT);     
                }
                else{
                    exService.clearException(si,ExceptionUtil.MISMATCH_CREDIT_MEMO_AMT);
                }
                
                if(si.Invoice_Amount__c == null || si.Invoice_Amount__c > 0){                       
                    exService.setException(si,ExceptionUtil.POSITIVE_INVOICE_AMOUNT);     
                }
                else{
                    exService.clearException(si,ExceptionUtil.POSITIVE_INVOICE_AMOUNT);
                }
                
                }
            //START OF Prepayment INVOICE SPECIFIC HEADER VALIDATIONS
            if(si.Invoice_Type__c == invTypePrepymt){  
                if(si.Invoice_Amount__c == null || si.Invoice_Amount__c < 0){                       
                    exService.setException(si,ExceptionUtil.NEGATIVE_INVOICE_AMOUNT);  
                }
                else{
                    exService.clearException(si,ExceptionUtil.NEGATIVE_INVOICE_AMOUNT);
                }
                
                if(si.Total_Extended_Price__c != si.Invoice_Amount__c){                                   
                    exService.setException(si,ExceptionUtil.MISMATCH_SI_SUM);  
                }else{
                    exService.clearException(si,ExceptionUtil.MISMATCH_SI_SUM);
        }
        
            } 
        }
        
        //DETERMINE IF ANY NEW EXCEPTIONS ARE LOGGED, IF NOT THEN THEN CONTINUE TO LINE LEVEL EXCEPTIONS
        exService.newExceptionsAlreadyOverridden(supplierInvoiceIds, new set<String>{TaskType.EXCEPTION_STATUS_OVERRIDDEN});
		Map<Id,Integer> taskExceptionsPerRecord = exService.taskExceptionsPerRecord;
		Map<Id, Supplier_Invoice__c> cleanSupplierInvoices = new Map<Id, Supplier_Invoice__c>();

        // Approved SIs may be processed when edited and saved from UI
		for(Supplier_Invoice__c si : IncompleteInvoices){
	        	if(taskExceptionsPerRecord.get(si.Id) == 0 && si.Status__c != 'Approved'){
	        	   	si.Status__c = 'Draft';
	        	}
	        	cleanSupplierInvoices.put(si.Id, si);
		}
		
		Map<String, Supplier_Invoice_Line__c> supplierInvoiceLines = new Map<String, Supplier_Invoice_Line__c>();
		Set<Id> SILIds = new Set<Id>(); 
        

          Set<String> additionalFields = new set<string>{'Id','Name','CreatedById','Supplier_Invoice__r.Name'};
          additionalFields.addAll(util.getAllCustomFieldsFromObject('','Supplier_Invoice_Line__c'));
          additionalFields.addAll(util.getAllCustomFieldsFromObject('Item__r.','Item__c'));
          additionalFields.addAll(util.getAllCustomFieldsFromObject('Item__r.Class__r.','Class__c'));
          additionalFields.addAll(util.getAllCustomFieldsFromObject('Supplier_Invoice__r.','Supplier_Invoice__c'));
          additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order__r.','Purchase_Order__c'));
          additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order__r.Purchase_Agreement__r.','Contract__c'));
          additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order_Line__r.Purchase_Order__r.Purchase_Agreement__r.','Contract__c'));
          additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order_Line__r.Purchase_Order__r.','Purchase_Order__c'));
          additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order_Line__r.','Purchase_Order_Line__c'));
      
          	Set<Id> keys = cleanSupplierInvoices.keySet();
          	
          	String whereClause = 'Supplier_Invoice__c IN :keys';
        
		    SOQLUtil soql = new SOQLUtil('Supplier_Invoice_Line__c');
		    soql.addFields('Supplier_Invoice_Line');
		    soql.addFields(additionalFields);
		    soql.setWhereClause(whereClause);
		    
		    supplierInvoiceLines = new Map<String, Supplier_Invoice_Line__c>((List<Supplier_Invoice_Line__c>) Database.query(soql.getQuery()));

		for(Supplier_Invoice_Line__c sil : supplierInvoiceLines.values()){

            // POL exists, as missing POL is an exception condition
            if(sil.Purchase_Order_line__c != null && sil.Purchase_Order__c != null) {
            	if(!(sil.Purchase_Order_Line__r.Approved__c && sil.Purchase_Order__r.Approval_Status__c == 'Approved')){
                	exService.setException(sil,ExceptionUtil.SI_PO_NOT_APPROVED);
                    system.debug('>>> setting sil exception SI_PO_NOT_APPROVED');
                }
                else{
                	exService.clearException(sil,ExceptionUtil.SI_PO_NOT_APPROVED);
                }
            }

		 	if (sil.Supplier_Invoice__r.Invoice_Type__c == invTypeInvoice && sil.Purchase_Order_Line__r.Invoice_Status__c == 'Closed for Invoicing'){ //KNDY-8790
                exService.setException(sil,ExceptionUtil.POLINE_INVOICE_STATUS_CLOSED);      
            }else{
                exService.clearException(sil,ExceptionUtil.POLINE_INVOICE_STATUS_CLOSED);          
            }
                
			if(sil.Item__c == null && sil.Purchase_Order_Line__c != null){
                exService.setException(sil,ExceptionUtil.MISSING_ITEM);      
            }
            else{
                exService.clearException(sil,ExceptionUtil.MISSING_ITEM);          
            }

            if(sil.Purchase_Order__c != null && sil.Purchase_Order_Line__c == null){
                exService.setException(sil,ExceptionUtil.MISSING_POLINE);      
            }
            else{
                exService.clearException(sil,ExceptionUtil.MISSING_POLINE);          
            }

			//Segment validation on Save
			if(sil.Accounting_Segment__c == null && sil.Subtransaction_Type__c == 'Miscellaneous' && sil.Item__c == null){
				exService.setException(sil,ExceptionUtil.SI_MISSING_SEGMENT_FRGHTMISC);      
			}
			else{
				exService.clearException(sil,ExceptionUtil.SI_MISSING_SEGMENT_FRGHTMISC);          
			}
			
            if(sil.Unit_Price__c < 0 && sil.Invoice_Quantity__c < 0){//KNDY-14371
                exService.setException(sil,ExceptionUtil.SI_NEGATIVE_PRICE_QTY);      
            }
            else{
                exService.clearException(sil,ExceptionUtil.SI_NEGATIVE_PRICE_QTY);          
            }
            
            if(sil.Invoice_Quantity__c == 0 || sil.Invoice_Quantity__c == null){
                exService.setException(sil,ExceptionUtil.SI_ZERO_QUANTITY);       
            }
            else{
                exService.clearException(sil,ExceptionUtil.SI_ZERO_QUANTITY);          
            }
            
            if(sil.Supplier_Invoice__r.Invoice_Type__c ==  invTypePrepymt && (sil.Invoice_Quantity__c * sil.Unit_Price__c < 0)){//KNDY-14371
                exService.setException(sil,ExceptionUtil.NEGATIVE_LINE_AMOUNT);       
            }
            else{
                exService.clearException(sil,ExceptionUtil.NEGATIVE_LINE_AMOUNT);         
            }
			
            if(sil.Supplier_Invoice__r.Invoice_Type__c ==  invTypeInvoice){
                if(sil.Purchase_Order_Line__c != null && sil.Purchase_Order_Line__r.Item__c != sil.Item__c && sil.Item__r.Source__c != 'Miscellaneous'){                    
                    exService.setException(sil,ExceptionUtil.INVALID_ITEM);    
                }
                else{
                    exService.clearException(sil,ExceptionUtil.INVALID_ITEM);          
                }       
            }
		}
		
		exService.newExceptionsAlreadyOverridden(SILIds, new set<String>{TaskType.EXCEPTION_STATUS_OVERRIDDEN});
		taskExceptionsPerRecord = exService.taskExceptionsPerRecord;

		for(Supplier_Invoice_Line__c sil : supplierInvoiceLines.values()){
		    if(taskExceptionsPerRecord.get(sil.Id) > 0){
                 if(cleanSupplierInvoices.containsKey(sil.Supplier_Invoice__c)){
                    cleanSupplierInvoices.remove(sil.Supplier_Invoice__c);
                 }   
		    }
		}
		
        if(cleanSupplierInvoices.size() > 0){
            DML.updateAsUser(cleanSupplierInvoices.values());
        }
        exService.finishTasks(true);
        return false;
    }
    
    public static boolean inspectDraftInvoices(List<Supplier_Invoice__c> draftInvoices){ 
        return inspectDraftInvoices(draftInvoices, null, null, null);
    }

    public static boolean inspectDraftInvoices(List<Supplier_Invoice__c> draftInvoices, Id batchId){
        return inspectDraftInvoices(draftInvoices, null, null, batchId);
    }
    
    public static boolean inspectDraftInvoices(List<Supplier_Invoice__c> draftInvoices, List<Supplier_Invoice_Line__c> draftInvoiceLines, JSONResult result){ 
        return inspectDraftInvoices(draftInvoices, draftInvoiceLines, result, null);   
    } 
    
    //Validates the SIs in draft status, to overcome the exceptions encountered
    public static boolean inspectDraftInvoices(List<Supplier_Invoice__c> draftInvoices, List<Supplier_Invoice_Line__c> draftInvoiceLines, JSONResult result, Id batchId){ 
        Map<Id, Supplier_Invoice__c> cleanSupplierInvoices = new Map<Id, Supplier_Invoice__c>(); 
        Map<Id, Supplier_Invoice_Line__c> supplierInvoiceLines = new Map<Id, Supplier_Invoice_Line__c>();
        Map<Id, Boolean> freightAllowedPerInvoice = new Map<Id, Boolean>(); 
        Map<id,Purchase_Order_Line__c> FreightExpMap = new Map<id,Purchase_Order_Line__c>(); //PTP-281 Map created to store the reference of Supplier Invoice Id, PO Line ID which doesnt allow FREIGHT line
        
        for(Supplier_Invoice__c si: draftInvoices){
            cleanSupplierInvoices.put(si.id, si);
            freightAllowedPerInvoice.put(si.Id, true);
        }
        
		SOQLUtil soql = new SOQLUtil('ApexClass', true); 
		soql.addFields(new set<string>{
			'Name','NameSpacePrefix'
		});
		soql.setWhereClause('Name = \'SupplierInvoiceSACValidation\'');
		soql.setLimit(1);
		
		for(ApexClass apex : Database.query(soql.getQuery())){
            Type apexType = Inspect.forName(apex.Name); //KNDY-7111 Switching to Inspect helper method which checks for empty string and null 
            SupplierInvoiceFactory sacBatch = (SupplierInvoiceFactory) apexType.newInstance();
          
            sacBatch.execute(draftInvoices);
        }
        
        Set<String> additionalFields = new set<string>{'Id','Name','CreatedById','Supplier_Invoice__r.Name'};
        additionalFields.addAll(util.getAllCustomFieldsFromObject('','Supplier_Invoice_Line__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Item__r.','Item__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Item__r.Class__r.','Class__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Supplier_Invoice__r.','Supplier_Invoice__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order__r.','Purchase_Order__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order__r.Purchase_Agreement__r.','Contract__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order_Line__r.Purchase_Order__r.Purchase_Agreement__r.','Contract__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order_Line__r.Purchase_Order__r.','Purchase_Order__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order_Line__r.Purchase_Order__r.FOB_Term__r.','FOB_Terms__c'));
        additionalFields.addAll(util.getAllCustomFieldsFromObject('Purchase_Order_Line__r.','Purchase_Order_Line__c'));
		
		additionalFields.remove('has_exceptions__c');
		additionalFields.remove('exceptions_count__c');
		additionalFields.remove('supplier_invoice__r.has_exceptions__c');
		additionalFields.remove('supplier_invoice__r.exceptions_count__c');
		additionalFields.remove('supplier_invoice__r.line_exceptions_count__c');
		
		Set<Id> keys = cleanSupplierInvoices.keySet();
		
		String whereClause = 'Supplier_Invoice__r.Hold__c = false AND Supplier_Invoice__c IN :keys';
        
	    soql = new SOQLUtil('Supplier_Invoice_Line__c');
	    soql.addFields('Supplier_Invoice_Line');
	    soql.addFields(additionalFields);
	    soql.setWhereClause(whereClause);
	    
	    supplierInvoiceLines = new Map<Id, Supplier_Invoice_Line__c>((List<Supplier_Invoice_Line__c>) Database.query(soql.getQuery()));
	    
        if(supplierInvoiceLines.size() > 0){ 
            
            List<Supplier_Invoice_Line__c> creditMemoLines = new List<Supplier_Invoice_Line__c>();
            List<Supplier_Invoice_Line__c> receiptInvoiceLines = new List<Supplier_Invoice_Line__c>();
           
            for (Supplier_Invoice_Line__c line: supplierInvoiceLines.values()){
                if(line.Purchase_Order_Line__c != null && line.Purchase_Order_Line__r.Purchase_Order__c != null){
                    if(line.Purchase_Order_Line__r.Purchase_Order__r.FOB_Term__r != null){
                        if(!line.Purchase_Order_Line__r.Purchase_Order__r.FOB_Term__r.Freight__c){
                            freightAllowedPerInvoice.put(line.Supplier_Invoice__c, false);
                            FreightExpMap.put(line.supplier_invoice__c, line.Purchase_Order_Line__r);
                        }
                    }
                    else{
                        freightAllowedPerInvoice.put(line.Supplier_Invoice__c, false);
                        FreightExpMap.put(line.supplier_invoice__c, line.Purchase_Order_Line__r);
                    }
                }
            }
             
            for (Supplier_Invoice_Line__c line: supplierInvoiceLines.values()){
                if(line.Item__r.Class__r.Type__c == 'Freight'){
                    if(!freightAllowedPerInvoice.get(line.Supplier_Invoice__c)){
                        if (FreightExpMap.containsKey(line.Supplier_Invoice__c))
                            line.Purchase_Order_Line__c = FreightExpMap.get(line.supplier_invoice__c).Id;
                        line.Purchase_Order_Line__r = FreightExpMap.get(line.supplier_invoice__c); 
                        exService.setException(line,ExceptionUtil.SI_FREIGHT);
                        if(result != null){
                            result.addMessage(' (' + line.Item__r.Name + '):  ' + ExceptionUtil.SI_FREIGHT.description, ApexPages.Severity.ERROR);
                        } 
                        line.Purchase_Order_Line__c = null; 
                    }
                    else{
                        exService.clearException(line,ExceptionUtil.SI_FREIGHT);    
                    }
                }
                else{
                    exService.clearException(line,ExceptionUtil.SI_FREIGHT);    
                }    
                //Throw CM Qty exception and Qty credited exception as part of Draft batch processing
                if(line.Supplier_Invoice__r.Invoice_Type__c ==  invTypeCM){         
                    if (result == null){ //Throw exception only for batch processing
                        if(line.Purchase_Order_Line__c != null && (math.abs(line.Invoice_Quantity__c) > line.Purchase_Order_Line__r.Order_Quantity__c)){        
                            exService.setException(line,ExceptionUtil.CM_INVOICE_QUANTITY);               
                        }
                        else{
                            exService.clearException(line,ExceptionUtil.CM_INVOICE_QUANTITY);          
                        }
                        if(line.Purchase_Order_Line__c != null && (math.abs(line.Purchase_Order_Line__r.Quantity_Credited__c)) > KSE.addQuantityToField(line.Purchase_Order_Line__r.Quantity_Returned_to_Supplier_for_Credit__c,0)){ //PTP-408         
                            exService.setException(line,ExceptionUtil.CM_QUANTITY_CREDITED);                
                        }
                        else{
                            exService.clearException(line,ExceptionUtil.CM_QUANTITY_CREDITED);          
                        } 
                    }  
                }
                if(line.Supplier_Invoice__c != null && line.Purchase_Order_Line__c != null && line.Purchase_Order_Line__r.Purchase_Order__c != null){
                    if(line.Purchase_Order_Line__r.Purchase_Order__r.Payment_Term__c != line.Supplier_Invoice__r.Payment_Term__c){
                        exService.setException(line,ExceptionUtil.SI_PAYMENT_TERMS);
                        if(result != null){
                            result.addMessage(' (' + line.Item__r.Name + '):  ' + ExceptionUtil.SI_PAYMENT_TERMS.description, ApexPages.Severity.ERROR);
                        } 
                    }
                    else{
                        exService.clearException(line,ExceptionUtil.SI_PAYMENT_TERMS);
                    }
                }
                else{
                    exService.clearException(line,ExceptionUtil.SI_PAYMENT_TERMS);
                }
                
                if(line.Supplier_Invoice__r.Invoice_Type__c == invTypeCM || line.Supplier_Invoice__r.Invoice_Type__c == invTypePrepymt){ //KNDY-9376 
                    creditMemoLines.add(line);
                }
                else{
                    receiptInvoiceLines.add(line);
                }
            }

	       

            if(creditMemoLines != null && creditMemoLines.size() > 0){
                if(result == null) {
                    validateCreditMemoInvoices(creditMemoLines, null, batchId);
                }
                else {
                    validateCreditMemoInvoices(creditMemoLines, result, batchId);
                }
            }

            if(receiptInvoiceLines != null && receiptInvoiceLines.size() > 0){
                if(result == null) {
                    validateReceiptInvoices(receiptInvoiceLines, null, batchId);
                }
                else {
                    validateReceiptInvoices(receiptInvoiceLines, result, batchId);
                }
            }
        }
    	
		if(result == null){
            list<Database.UpsertResult> results = exService.finishTasks(true);
	    	if(!results.isEmpty()){
	    		throw new SIException('An exception occured while saving the task.'); 
	    	}
            return false;
        }
        else{
            if(result.messages.size() > 0){
                result.success = false;
                return true;
            }
            else{
                result.success = true;
                return false;
            }
        }
    }
    
    public static void validateCreditMemoInvoices(list<Supplier_Invoice_Line__c> creditMemoLines){
        validateCreditMemoInvoices(creditMemoLines, null, null);
    }
    
    // validates the credit memos.
    public static void validateCreditMemoInvoices(list<Supplier_Invoice_Line__c> creditMemoLines, JSONResult result, Id batchId){
		Map<Id,Supplier_Invoice_Line__c> cleanCreditMemoLines = new Map<Id,Supplier_Invoice_Line__c>();
        Map<Id, Supplier_Invoice__c> cleanCreditMemos = new Map<Id, Supplier_Invoice__c>();
        Set<ID> updateLastVisitedTimeOnCMs = new Set<ID>(); 
        
        Set<Id> cmLineIds = new Set<Id>();
        
        exService.newExceptionsAlreadyOverridden(cmLineIds, new set<String>{TaskType.EXCEPTION_STATUS_OVERRIDDEN});
		Map<Id,Integer> taskExceptionsPerRecord = exService.taskExceptionsPerRecord;
			
        
        for (Supplier_Invoice_Line__c cmLine: creditMemoLines){
			if(taskExceptionsPerRecord.get(cmLine.id) == 0){
                cmLine.Matched__c = true;
	                
                if(!cleanCreditMemos.containsKey(cmLine.Supplier_Invoice__c)){
                    cleanCreditMemos.put(cmLine.Supplier_Invoice__c, new Supplier_Invoice__c(ID = cmLine.Supplier_Invoice__c));
                }

                if(!cleanCreditMemoLines.containsKey(cmLine.Id)) {
                    cleanCreditMemoLines.put(cmLine.id,cmLine);
                }
			}
			else {	                    
                if(cleanCreditMemos.containsKey(cmLine.Supplier_Invoice__c)){
                    cleanCreditMemos.remove(cmLine.Supplier_Invoice__c);
                }
            }
		}
		list<Database.UpsertResult> results = exService.finishTasks(true);
	    if(!results.isEmpty()){
	    	throw new SIException('An exception occured while saving the task.'); 
	    }
        
		Set<Id> siIds = cleanCreditMemos.keyset();
		SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Has_Exceptions__c','Has_Line_Exceptions__c'
		});
		soql.setWhereClause('Id IN :siIds');

		for(Supplier_Invoice__c si : Database.query(soql.getQuery())){
            for(String newCodes : exService.newOpenExceptionCodes) {
                if(exService.newOpenExceptionCodesPerRecord.containsKey(si.Id) && (exService.newOpenExceptionCodesPerRecord.get(si.Id).contains(newCodes))) {
                    if(cleanCreditMemos.containsKey(si.Id)){
                        cleanCreditMemos.remove(si.Id);
                        updateLastVisitedTimeOnCMs.add(si.Id); //PTP-420
                    }
                }
            }
            if(si.Has_Exceptions__c || si.Has_Line_Exceptions__c) {
                if(cleanCreditMemos.containsKey(si.Id)){
                    cleanCreditMemos.remove(si.Id);
                    updateLastVisitedTimeOnCMs.add(si.Id); //PTP-420
                }
            }
        }
        
        if(!cleanCreditMemoLines.isEmpty()) {
            DML.updateAsUser(cleanCreditMemoLines.values());
        }

        updateSupplierInvoices(cleanCreditMemos, updateLastVisitedTimeOnCMs,batchId);
 
    }  
    
    public static void validateReceiptInvoices(list<Supplier_Invoice_Line__c> supplierInvoiceLineList){
        validateReceiptInvoices(supplierInvoiceLineList, null, null);
    }

    public static void validateReceiptInvoices(list<Supplier_Invoice_Line__c> supplierInvoiceLineList, JSONResult result, Id batchId){
        Set<Id> poLineIds = new Set<Id>();

        List<Purchase_Order_Line__c> purchaseOrderLines = new List<Purchase_Order_Line__c>();
        List<Supplier_Invoice_Line__c> cleanReceiptInvoiceLines = new List<Supplier_Invoice_Line__c>();
        Map<Id, Supplier_Invoice__c> cleanReceiptInvoices = new Map<Id, Supplier_Invoice__c>();

        // KNDY-9637
        Map<Id, List<Supplier_Invoice_Line__c>> mapPOLIdSILines = new Map<Id, List<Supplier_Invoice_Line__c>>();
        Map<Id, List<Receipt_Line__c>> mapPOLIdReceiptLines = new Map<Id, List<Receipt_Line__c>>();

        for (Supplier_Invoice_Line__c line: supplierInvoiceLineList){
            if(!cleanReceiptInvoices.containsKey(line.Supplier_Invoice__c)){
                cleanReceiptInvoices.put(line.Supplier_Invoice__c, new Supplier_Invoice__c(ID = line.Supplier_Invoice__c));
            }
            cleanReceiptInvoiceLines.add(line);
            if(line.Purchase_Order_Line__c != null) {
                poLineIds.add(line.Purchase_Order_Line__c);
            }     
        }
    
        fetchRecordsByPOL(poLineIds, purchaseOrderLines, mapPOLIdSILines, mapPOLIdReceiptLines); // KNDY-9637
       
        List<Purchase_Order_Line__c> twoWayPOLines = new List<Purchase_Order_Line__c>();
        List<Purchase_Order_Line__c> threeWayPOLines = new List<Purchase_Order_Line__c>();
        
        for(Purchase_Order_Line__c poLine : purchaseOrderLines) {
            if(poLine.Invoice_Matching__c == 'Two Way') {
                twoWayPOLines.add(poLine);
            }
            else {
                threeWayPOLines.add(poLine);
            }
        }

        if(twoWayPOLines.size()> 0){
            twoWayMatching(twoWayPOLines, mapPOLIdSILines);
        }
        if(threeWayPOLines.size() > 0){
            threeWayMatching(threeWayPOLines,supplierInvoiceLineList, mapPOLIdSILines, mapPOLIdReceiptLines);
        }
        finish(supplierInvoiceLineList, batchId);
    }
    
    // Get Tolerances from PO, Calculate allowed Quantity/Price/Amount as per tolerances
    // Calculage the invoice Qty, and invoice Amount total across all approved & Closed invoice lines 
    // loop thru individual draft to flag which ones are over or under tolerances
    // Qty Tolerances are calculated against POLine`s Order Quantity 
    // if there is no qty or price exceptions, flag the invoice line as matched 
    //   so as to not pick it up again in subsequent batches.     
    public static void twoWayMatching(List<Purchase_Order_Line__c> poLines, Map<Id, List<Supplier_Invoice_Line__c>> mapPOLIdSILines){
        
        List<Supplier_Invoice_Line__c> invoiceLines = new List<Supplier_Invoice_Line__c>();
        
        for(Purchase_Order_Line__c pol : poLines) {
            // KNDY-9637
            if (!mapPOLIdSILines.containsKey(pol.Id)){
                continue;
            }
            List<Supplier_Invoice_Line__c> supplierInvoiceLines =  mapPOLIdSILines.get(pol.Id);
            if (!supplierInvoiceLines.isEmpty()){
                // Get Tolerances from PO
                Decimal overTolerancePercent = pol.Purchase_Order__r.Quantity_Tolerance_Over__c == null ? 0 : pol.Purchase_Order__r.Quantity_Tolerance_Over__c;
                //Decimal underTolerancePercent = pol.Purchase_Order__r.Quantity_Tolerance_Under__c == null ? 0 : pol.Purchase_Order__r.Quantity_Tolerance_Under__c;
                Decimal unitPriceOverTolerancePercent = pol.Purchase_Order__r.Unit_Price_Tolerance_Over__c == null ? 0 : pol.Purchase_Order__r.Unit_Price_Tolerance_Over__c;
                //Decimal unitPriceUnderTolerancePercent = pol.Purchase_Order__r.Unit_Price_Tolerance_Under__c == null ? 0 : pol.Purchase_Order__r.Unit_Price_Tolerance_Under__c;
                
                // Calculate allowed Quantity/Price/Amount based on POL`s Order Quantity and Unit Price
                Decimal maxAllowedInvQtyPerPOL = 0.0;
                Decimal minAllowedInvQtyPerPOL = 0.0;
                Decimal maxAllowedUnitPricePerPOL = 0.0;
                Decimal minAllowedUnitPricePerPOL = 0.0;
                Decimal amountAllowedPerPOL = 0.0; 
                
                maxAllowedInvQtyPerPOL = (pol.Order_Quantity__c + (pol.Order_Quantity__c * (overTolerancePercent/100))).setScale(2,System.RoundingMode.HALF_UP);
               //minAllowedInvQtyPerPOL = (pol.Order_Quantity__c - (pol.Order_Quantity__c * (underTolerancePercent/100))).setScale(2,System.RoundingMode.HALF_UP);
                maxAllowedUnitPricePerPOL = (pol.Unit_Price__c + (pol.Unit_Price__c * (unitPriceOverTolerancePercent/100))).setScale(2,System.RoundingMode.HALF_UP);
                //minAllowedUnitPricePerPOL = (pol.Unit_Price__c - (pol.Unit_Price__c * (unitPriceUnderTolerancePercent/100))).setScale(2,System.RoundingMode.HALF_UP);
                amountAllowedPerPOL = ((pol.Order_Quantity__c * pol.Unit_Price__c) + KSE.addQuantityToField(pol.Purchase_Order__r.Amount_Tolerance__c,0)).setScale(2,System.RoundingMode.HALF_UP);
                
                Decimal invQtyPerPOL = 0;
                Decimal invAmountPerPOL = 0;
                List<Supplier_Invoice_Line__c> draftSILs = new List<Supplier_Invoice_Line__c>();
                
                // Calculate buckets totals for all approved and closed lines: total invoice qty, amount	        
                for(Supplier_Invoice_Line__c sil : supplierInvoiceLines) { // KNDY-9637
                    if (sil.Supplier_Invoice__r.Status__c != 'Draft'){

                        invQtyPerPOL += (KSE.addQuantityToField(sil.Invoice_Quantity__c,0)).setScale(2,System.RoundingMode.HALF_UP);
                        invAmountPerPOL += (KSE.addQuantityToField(sil.Invoice_Quantity__c,0) * KSE.addQuantityToField(sil.Unit_Price__c,0)).setScale(2,System.RoundingMode.HALF_UP);
                    }
                    else{
                        draftSILs.add(sil); //ONLY NEED TO VALIDATE Draft INVOICE LINES WHICH ARE RELATED TO A PO LINE.  
                    }
                }
                
                //MANUAL INVOICE LINES WILL STILL GO THROUGH THE FINISH() METHOD TO MOVE FORWARD
                // Calculage the total across all approved & Closed invoice lines 
                // invQtyPerPOL is set to above total to kick things off
                // loop thru individual draft to flag which ones are over or under tolerances        
                for(Supplier_Invoice_Line__c sil : draftSILs) { 	          
                    invoiceLines.add(sil);

                    invQtyPerPOL += (KSE.addQuantityToField(sil.Invoice_Quantity__c,0)).setScale(2,System.RoundingMode.HALF_UP);
                    invAmountPerPOL += (KSE.addQuantityToField(sil.Invoice_Quantity__c,0) * KSE.addQuantityToField(sil.Unit_Price__c,0)).setScale(2,System.RoundingMode.HALF_UP);
                    
                    //QUANTITY TOLERANCE VALIDATION
                    if(invQtyPerPOL > (pol.Order_Quantity__c).setScale(2,System.RoundingMode.HALF_UP)) { 
                        if (pol.Purchase_Order__r.Quantity_Tolerance_Over__c == null) {
                            exService.setException(sil,ExceptionUtil.SI_INVOICED_QTY_MORE_THAN_PURCHASED);
                            exService.clearException(sil,ExceptionUtil.SI_QTY_OVER_TOLERANCE);
                        }
                        else if(invQtyPerPOL > maxAllowedInvQtyPerPOL) { 
                            exService.setException(sil,ExceptionUtil.SI_QTY_OVER_TOLERANCE); 
                            exService.clearException(sil,ExceptionUtil.SI_INVOICED_QTY_MORE_THAN_PURCHASED);
                        }
                        else { 
                            exService.clearException(sil,ExceptionUtil.SI_INVOICED_QTY_MORE_THAN_PURCHASED);
                            exService.clearException(sil,ExceptionUtil.SI_QTY_OVER_TOLERANCE);
                        }
                    }
                    else if(invQtyPerPOL < (pol.Order_Quantity__c).setScale(2,System.RoundingMode.HALF_UP)) {
                        /*if (pol.Purchase_Order__r.Quantity_Tolerance_Under__c == null) {
                            exService.clearException(sil,ExceptionUtil.SI_INVOICED_QTY_MORE_THAN_PURCHASED);
                            exService.clearException(sil,ExceptionUtil.SI_QTY_UNDER_TOLERANCE);
                            exService.clearException(sil,ExceptionUtil.SI_QTY_OVER_TOLERANCE);
                        }
                        else */ if(invQtyPerPOL < minAllowedInvQtyPerPOL){
                            //exService.setException(sil,ExceptionUtil.SI_QTY_UNDER_TOLERANCE);
                            exService.clearException(sil,ExceptionUtil.SI_QTY_OVER_TOLERANCE);
                            exService.clearException(sil,ExceptionUtil.SI_INVOICED_QTY_MORE_THAN_PURCHASED);
                        }
                        else{
                            exService.clearException(sil,ExceptionUtil.SI_INVOICED_QTY_MORE_THAN_PURCHASED);
                            //exService.clearException(sil,ExceptionUtil.SI_QTY_UNDER_TOLERANCE);
                            exService.clearException(sil,ExceptionUtil.SI_QTY_OVER_TOLERANCE);
                        }
                    }
                    else {
                        exService.clearException(sil,ExceptionUtil.SI_INVOICED_QTY_MORE_THAN_PURCHASED);
                        //exService.clearException(sil,ExceptionUtil.SI_QTY_UNDER_TOLERANCE);
                        exService.clearException(sil,ExceptionUtil.SI_QTY_OVER_TOLERANCE);
                    }
                  
                    //UNIT PRICE TOLERANCE VALIDATIONS

                    if((sil.Unit_Price__c).setScale(2,System.RoundingMode.HALF_UP) > (pol.Unit_Price__c).setScale(2,System.RoundingMode.HALF_UP)) {
                        if(pol.Purchase_Order__r.Unit_Price_Tolerance_Over__c == null) {
                            exService.setException(sil,ExceptionUtil.SI_UNIT_PRICE);
                            exService.clearException(sil,ExceptionUtil.SI_PRICE_OVER_TOLERANCE);
                            //exService.clearException(sil,ExceptionUtil.SI_PRICE_UNDER_TOLERANCE);       
                        }
                        else if (sil.Unit_Price__c > maxAllowedUnitPricePerPOL) {
                            exService.setException(sil,ExceptionUtil.SI_PRICE_OVER_TOLERANCE);
                            exService.clearException(sil,ExceptionUtil.SI_UNIT_PRICE);
                            //exService.clearException(sil,ExceptionUtil.SI_PRICE_UNDER_TOLERANCE);
                        }
                        else {
                            exService.clearException(sil,ExceptionUtil.SI_UNIT_PRICE);
                            exService.clearException(sil,ExceptionUtil.SI_PRICE_OVER_TOLERANCE);
                            //exService.clearException(sil,ExceptionUtil.SI_PRICE_UNDER_TOLERANCE);       
                        }
                    }

                    else if((sil.Unit_Price__c).setScale(2,System.RoundingMode.HALF_UP) < (pol.Unit_Price__c).setScale(2,System.RoundingMode.HALF_UP)) {
                       /* if (pol.Purchase_Order__r.Unit_Price_Tolerance_Under__c == null) {
                            exService.setException(sil,ExceptionUtil.SI_UNIT_PRICE);
                            exService.clearException(sil,ExceptionUtil.SI_PRICE_UNDER_TOLERANCE);
                            exService.clearException(sil,ExceptionUtil.SI_PRICE_OVER_TOLERANCE);
                        }
                        else */
                        if(sil.Unit_Price__c < minAllowedUnitPricePerPOL){//KNDY-14371
                            //exService.setException(sil,ExceptionUtil.SI_PRICE_UNDER_TOLERANCE);
                            exService.clearException(sil,ExceptionUtil.SI_PRICE_OVER_TOLERANCE);
                            exService.clearException(sil,ExceptionUtil.SI_UNIT_PRICE);
                        }
                        else {
                            exService.clearException(sil,ExceptionUtil.SI_UNIT_PRICE);
                            //exService.clearException(sil,ExceptionUtil.SI_PRICE_UNDER_TOLERANCE);
                            exService.clearException(sil,ExceptionUtil.SI_PRICE_OVER_TOLERANCE);
                        }
                    }
                    else {
                        //exService.clearException(sil,ExceptionUtil.SI_PRICE_UNDER_TOLERANCE);
                        exService.clearException(sil,ExceptionUtil.SI_PRICE_OVER_TOLERANCE);
                        exService.clearException(sil,ExceptionUtil.SI_UNIT_PRICE);
                    }
    
                    if(invAmountPerPOL > amountAllowedPerPOL) {
                        exService.setException(sil,ExceptionUtil.SI_AMOUNT_ORDER_OVER_TOLERANCE);
                    }
                    else {
                        exService.clearException(sil,ExceptionUtil.SI_AMOUNT_ORDER_OVER_TOLERANCE);
                    }
               } // end draft SILs loop
           } // end if SILs not empty
        }// end POL loop
    }

    
    public static void finish(List<Supplier_Invoice_Line__c> invoiceLines, Id batchId) {
    	system.debug('***finish***'+invoiceLines+'*'+batchId);
        Set<Id> invoiceLineIds = new Set<Id>();
        Map<Id,Supplier_Invoice__c> cleanInvoices = new Map<Id,Supplier_Invoice__c>();
        Map<Id,Supplier_Invoice_Line__c> cleanInvoiceLines = new Map<Id,Supplier_Invoice_Line__c>();
        Set<Id> updateLastVisitedTime = new Set<ID>();
      
        // if no exceptions found, mark invoice line as matched
        // and update sils with Quantity Received values, and matched status
        exService.newExceptionsAlreadyOverridden(invoiceLineIds, new set<String>{TaskType.EXCEPTION_STATUS_OVERRIDDEN});
        Map<Id,Integer> taskExceptionsPerRecord = exService.taskExceptionsPerRecord;
        for(Supplier_Invoice_Line__c sil : invoiceLines) {
            invoiceLineIds.add(sil.Id);
            cleanInvoices.put(sil.Supplier_Invoice__c, new Supplier_Invoice__c(Id = sil.Supplier_Invoice__c));
            if(taskExceptionsPerRecord.containsKey(sil.id) && taskExceptionsPerRecord.get(sil.id) == 0){
                sil.Matched__c = true;
            }
            cleanInvoiceLines.put(sil.Id, sil);        
            updateLastVisitedTime.add(sil.Supplier_Invoice__c);
        }
        // Insert Exception Tasks
        list<Database.UpsertResult> results = exService.finishTasks(true);
	    if(!results.isEmpty()){
	    	throw new SIException('An exception occured while saving the task.'); 
	    }
      
		SOQLUtil soql = new SOQLUtil('Supplier_Invoice_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Supplier_Invoice__c'
		});
		soql.setWhereClause('Id IN :invoiceLineIds AND (Has_Exceptions__c = true OR Supplier_Invoice__r.Has_Exceptions__c = true)');

		for(Supplier_Invoice_Line__c sil : Database.query(soql.getQuery())){
            if(cleanInvoices.containsKey(sil.Supplier_Invoice__c)){
                cleanInvoices.remove(sil.Supplier_Invoice__c);
            }
        }
        system.debug('***cleanInvoiceLines***'+cleanInvoiceLines);
        if(!cleanInvoiceLines.isEmpty()) {
            DML.updateAsUser(cleanInvoiceLines.values());
        }

        // if there is no qty or price exceptions, flag the invoice line as matched 
        // so as to not pick it up again in subsequent batches.    
        updateSupplierInvoices(cleanInvoices, updateLastVisitedTime,batchId);

    }
    
     /*  Get all the related PO lines to the input invoice lines. Build maps of relevant record details needed. 
        Loop over the PO lines, retrieving and matching related receipt and invoice lines. 
        For price matching, check PO line unit price against invoice line unit price and flag exception accordingly
        For qty matching, use a qty variable to build all the qty received in this batch of records. Flag if qty is not received in its entirety. 
        Update corresponding buckets on receipt and invoice lines.
        if there is no qty or price exceptions, flag the invoice line as matched so as to not pick it up again in subsequent batches.
    */   
    public static void threeWayMatching( list<Purchase_Order_Line__c> inputPOLinesList , List<Supplier_Invoice_Line__c> supplierInvoiceLineList, Map<Id, List<Supplier_Invoice_Line__c>> mapPOLIdSILines, Map<Id, List<Receipt_Line__c>> mapPOLIdReceiptLines){
        Map<Id, List<Receipt_Line__c>> mapReceiptLines = new Map<Id, List<Receipt_Line__c>>();
        Map<Id, List<Supplier_Invoice_Line__c>> mapReceiptInvLines = new Map<Id, List<Supplier_Invoice_Line__c>>();
        Map<Id, Receipt_Line__c> mapRLToUpdate = new Map<Id, Receipt_Line__c>();
        
        Map<Id, Supplier_Invoice_Line__c> mapRILToUpdate = new Map<Id, Supplier_Invoice_Line__c>();

        Set<ID> updateLastVisitedTimeOnSIs = new Set<ID>(); //PTP-420
        Map<String,Boolean> setException = new Map<String,Boolean>();
        Map<String,TaskType> exceptionTypes = new Map<String,TaskType>();
        
        Map<Id, Supplier_Invoice_Line__c> invoiceLineIds = new Map<Id, Supplier_Invoice_Line__c>();
        for(Supplier_Invoice_Line__c sil : supplierInvoiceLineList) {
          invoiceLineIds.put(sil.Id, sil);// draft, approved and closed
        }
        
        Map<Id,Decimal> quantityMatchedByPOL = new Map<Id,Decimal>();
        Map<Id,Decimal> invAmountMatchedByPOL = new Map<Id,Decimal>();
        
        for(Purchase_Order_Line__c poLine: inputPOLinesList){  
            quantityMatchedByPOL.put(poLine.id,0);
            invAmountMatchedByPOL.put(poLine.id,0);
            
            if (mapPOLIdReceiptLines.containsKey(poLine.Id) && mapPOLIdReceiptLines.get(poLine.Id).size() > 0){// KNDY-9637
                mapReceiptLines.put(poLine.Id, mapPOLIdReceiptLines.get(poLine.Id)); 
            }
            
            if ( mapPOLIdSILines.containsKey(poLine.Id) &&  mapPOLIdSILines.get(poLine.id).size() > 0){ // KNDY-9637
                for (Supplier_Invoice_Line__c receiptInvLine: mapPOLIdSILines.get(poLine.id)){ // KNDY-9637
                    if(receiptInvLine.Supplier_Invoice__r.Status__c == 'Draft') {
                        if(mapReceiptInvLines.containsKey(poLine.id)){
                           mapReceiptInvLines.get(poLine.id).add(receiptInvLine);
                        }else{
                           mapReceiptInvLines.put(poLine.id, new List<Supplier_Invoice_Line__c>{receiptInvLine});
                        }
                    }
                    else { // QTY matched by approved or closed inv lines

                        quantityMatchedByPOL.put(poLine.id, (quantityMatchedByPOL.get(poLine.id) + KSE.addQuantityToField(receiptInvLine.Invoice_Quantity__c,0)).setScale(2,System.RoundingMode.HALF_UP));
                        invAmountMatchedByPOL.put(poLine.id, (invAmountMatchedByPOL.get(poLine.id) + KSE.addQuantityToField(receiptInvLine.Extended_Price__c,0)).setScale(2,System.RoundingMode.HALF_UP));
                    }
               }
            }

           decimal receiptInvLineInvQtyTotal = 0; // draft invoice lines qty running total
           decimal draftInvLine_InvAmountTotal = 0;
           
           //Process draft inv lines
           if(mapReceiptInvLines.get(poLine.id) != null){
                for (Supplier_Invoice_Line__c receiptInvLine: mapReceiptInvLines.get(poLine.id)){
                  if(invoiceLineIds.containsKey(receiptInvLine.Id)) {
                      decimal receiptInvLineQtyTotal = KSE.addQuantityToField(receiptInvLine.Quantity_Received__c,0); // total of qty recd so far 
                      decimal receiptLineReceivedQty = 0;
                      receiptInvLineInvQtyTotal += KSE.addQuantityToField(receiptInvLine.Invoice_Quantity__c,0);

                      draftInvLine_InvAmountTotal += KSE.addQuantityToField(receiptInvLine.Extended_Price__c,0);
                      //draftInvLine_InvAmountTotal = draftInvLine_InvAmountTotal.setScale(2,System.RoundingMode.HALF_UP);
                      system.debug(logginglevel.error,'>>>> draftInvLine_InvAmountTotal:' + draftInvLine_InvAmountTotal);  
                      // qty matching against receipt line
                      if(!mapReceiptLines.isEmpty() && mapReceiptLines.containsKey(receiptInvLine.Purchase_Order_Line__c) && mapReceiptLines.get(receiptInvLine.Purchase_Order_Line__c).size() > 0){ 
                          // PTP-650, if receipts exist, clear exception, else set exception
                          setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_INVOICE_QUANTITY.code, false);   
                          exceptionTypes.put(ExceptionUtil.SI_INVOICE_QUANTITY.code,ExceptionUtil.SI_INVOICE_QUANTITY);   

                          for (Receipt_Line__c receiptLine: mapReceiptLines.get(receiptInvLine.Purchase_Order_Line__c)){  //1 line
                              if(!receiptLine.Matched__c) {
                                  receiptLineReceivedQty += KSE.addQuantityToField(receiptLine.Quantity_Received__c,0);
                              }
                              //receipt line Uninvoiced qty is full matched with invoice line qty needed
                              if((receiptInvLine.Invoice_Quantity__c - KSE.addQuantityToField(receiptInvLine.Quantity_Received__c,0)) - KSE.addQuantityToField(receiptLine.Uninvoiced_Quantity__c,0) >= 0){
                                  
                                  receiptInvLineQtyTotal += KSE.addQuantityToField(receiptLine.Uninvoiced_Quantity__c,0); //increment the ril qty recd to continue matching
                                   //mark receipt line as matched
                                  receiptLine.Uninvoiced_Quantity__c = 0;
                                  receiptInvLine.Quantity_Received__c = receiptInvLineQtyTotal;
                                  
                                    
                                  if(receiptInvLine.Purchase_Order_Line__r.Purchase_Order__r.Quantity_Tolerance_Over__c == null){
                                      if(receiptInvLine.Invoice_Quantity__c - KSE.addQuantityToField(receiptInvLine.Quantity_Received__c,0) > 0){ // stil need more qty to receive
                                          setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_INVOICE_QUANTITY.code, true);
                                          exceptionTypes.put(ExceptionUtil.SI_INVOICE_QUANTITY.code,ExceptionUtil.SI_INVOICE_QUANTITY);
                                      }
                                      else {
                                        setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_INVOICE_QUANTITY.code, false);
                                        exceptionTypes.put(ExceptionUtil.SI_INVOICE_QUANTITY.code,ExceptionUtil.SI_INVOICE_QUANTITY);
                                      }                              
                                  }
  
                                  if((receiptInvLineQtyTotal).setScale(2,System.RoundingMode.HALF_UP) == (receiptInvLine.Invoice_Quantity__c).setScale(2,System.RoundingMode.HALF_UP)){ //SIL Qty Received == SIL invoice qty
                                      setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_INVOICE_QUANTITY.code, false);
                                      exceptionTypes.put(ExceptionUtil.SI_INVOICE_QUANTITY.code,ExceptionUtil.SI_INVOICE_QUANTITY);
                                      system.debug('clearException--'+receiptInvLine.Id);
                                  }
                                  
                              }else if(receiptInvLine.Invoice_Quantity__c - KSE.addQuantityToField(receiptInvLine.Quantity_Received__c,0) > 0){// PTP-267 invoice line qty needed is full matched within receipt line qty uninvoiced
                                  // the entire inv qty should've been matched
                                  receiptInvLineQtyTotal += (receiptInvLine.Invoice_Quantity__c - KSE.addQuantityToField(receiptInvLine.Quantity_Received__c,0));
                                    
                                  receiptLine.Uninvoiced_Quantity__c -= (receiptInvLine.Invoice_Quantity__c - KSE.addQuantityToField(receiptInvLine.Quantity_Received__c,0)).setScale(2,System.RoundingMode.HALF_UP);
                                  receiptInvLine.Quantity_Received__c = receiptInvLineQtyTotal.setScale(2,System.RoundingMode.HALF_UP);
                                  setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_INVOICE_QUANTITY.code, false);
                                  exceptionTypes.put(ExceptionUtil.SI_INVOICE_QUANTITY.code,ExceptionUtil.SI_INVOICE_QUANTITY);
                              }
                              
                              if(receiptLine.Uninvoiced_Quantity__c == 0){
                                  receiptLine.Matched__c = true;
                              } 
                                        
                              if(!mapRLToUpdate.containsKey(receiptLine.id))
                                  mapRLToUpdate.put(receiptLine.id,receiptLine);
                              
                          }// end of for loop iterating over receipt lines
                          if(receiptInvLine.Purchase_Order_Line__c != null){
                              if(receiptInvLine.Purchase_Order_Line__r.Purchase_Order__r.Quantity_Tolerance_Over__c != null){
                                  // draft siL total inv qty + quantityMatchedByPOL > POL qty received + its percentage
                                  if((receiptInvLineInvQtyTotal + quantityMatchedByPOL.get(poLine.Id)).setScale(2,System.RoundingMode.HALF_UP) > (receiptInvLine.Purchase_Order_Line__r.Quantity_Received__c  + (receiptInvLine.Purchase_Order_Line__r.Quantity_Received__c * (receiptInvLine.Purchase_Order_Line__r.Purchase_Order__r.Quantity_Tolerance_Over__c/100)).setScale(2,System.RoundingMode.HALF_UP))){
                                      setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_QTY_OVER_TOLERANCE.code, true);
                                      exceptionTypes.put(ExceptionUtil.SI_QTY_OVER_TOLERANCE.code,ExceptionUtil.SI_QTY_OVER_TOLERANCE);
                                  }
                                  else{
                                      setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_QTY_OVER_TOLERANCE.code, false);
                                      exceptionTypes.put(ExceptionUtil.SI_QTY_OVER_TOLERANCE.code,ExceptionUtil.SI_QTY_OVER_TOLERANCE);
                                  }
                              }
                              else{
                                  setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_QTY_OVER_TOLERANCE.code, false);
                                  exceptionTypes.put(ExceptionUtil.SI_QTY_OVER_TOLERANCE.code,ExceptionUtil.SI_QTY_OVER_TOLERANCE);
                                  
                              }
                             /* if(receiptInvLine.Purchase_Order_Line__r.Purchase_Order__r.Quantity_Tolerance_Under__c != null){
                                  if((receiptInvLineInvQtyTotal + quantityMatchedByPOL.get(poLine.Id)).setScale(2,System.RoundingMode.HALF_UP) < (receiptInvLine.Purchase_Order_Line__r.Quantity_Received__c - (receiptInvLine.Purchase_Order_Line__r.Quantity_Received__c * (receiptInvLine.Purchase_Order_Line__r.Purchase_Order__r.Quantity_Tolerance_Under__c/100))).setScale(2,System.RoundingMode.HALF_UP)){
                                      setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_QTY_UNDER_TOLERANCE.code, true);
                                      exceptionTypes.put(ExceptionUtil.SI_QTY_UNDER_TOLERANCE.code,ExceptionUtil.SI_QTY_UNDER_TOLERANCE);
                                  }
                                  else{
                                      setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_QTY_UNDER_TOLERANCE.code, false);
                                      exceptionTypes.put(ExceptionUtil.SI_QTY_UNDER_TOLERANCE.code,ExceptionUtil.SI_QTY_UNDER_TOLERANCE);
                                  }
                              }
                              else{
                                  setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_QTY_UNDER_TOLERANCE.code, false);
                                  exceptionTypes.put(ExceptionUtil.SI_QTY_UNDER_TOLERANCE.code,ExceptionUtil.SI_QTY_UNDER_TOLERANCE);
                              } */
                              
                              if(receiptInvLine.Purchase_Order_Line__r.Purchase_Order__r.Unit_Price_Tolerance_Over__c != null){

                                  if((receiptInvLine.Unit_Price__c).setScale(2,System.RoundingMode.HALF_UP) > (receiptInvLine.Purchase_Order_Line__r.Unit_Price__c + (receiptInvLine.Purchase_Order_Line__r.Unit_Price__c * (receiptInvLine.Purchase_Order_Line__r.Purchase_Order__r.Unit_Price_Tolerance_Over__c/100))).setScale(2,System.RoundingMode.HALF_UP)){
                                      setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_PRICE_OVER_TOLERANCE.code, true);
                                      exceptionTypes.put(ExceptionUtil.SI_PRICE_OVER_TOLERANCE.code,ExceptionUtil.SI_PRICE_OVER_TOLERANCE);
                                  }
                                  else{
                                      setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_PRICE_OVER_TOLERANCE.code, false);
                                      exceptionTypes.put(ExceptionUtil.SI_PRICE_OVER_TOLERANCE.code,ExceptionUtil.SI_PRICE_OVER_TOLERANCE);
                                  }
                              }
                              else{
                                  setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_PRICE_OVER_TOLERANCE.code, false);
                                  exceptionTypes.put(ExceptionUtil.SI_PRICE_OVER_TOLERANCE.code,ExceptionUtil.SI_PRICE_OVER_TOLERANCE);
                              }
                              
                            /*  if(receiptInvLine.Purchase_Order_Line__r.Purchase_Order__r.Unit_Price_Tolerance_Under__c != null){

                                  if((receiptInvLine.Unit_Price__c).setScale(2,System.RoundingMode.HALF_UP) < (receiptInvLine.Purchase_Order_Line__r.Unit_Price__c - (receiptInvLine.Purchase_Order_Line__r.Unit_Price__c * (receiptInvLine.Purchase_Order_Line__r.Purchase_Order__r.Unit_Price_Tolerance_Under__c/100))).setScale(2,System.RoundingMode.HALF_UP)){
                                      setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_PRICE_UNDER_TOLERANCE.code, true);
                                      exceptionTypes.put(ExceptionUtil.SI_PRICE_UNDER_TOLERANCE.code,ExceptionUtil.SI_PRICE_UNDER_TOLERANCE);
                                  }
                                  else{
                                      setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_PRICE_UNDER_TOLERANCE.code, false);
                                      exceptionTypes.put(ExceptionUtil.SI_PRICE_UNDER_TOLERANCE.code,ExceptionUtil.SI_PRICE_UNDER_TOLERANCE);
                                  }
                              }
                              else{
                                  setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_PRICE_UNDER_TOLERANCE.code, false);
                                  exceptionTypes.put(ExceptionUtil.SI_PRICE_UNDER_TOLERANCE.code,ExceptionUtil.SI_PRICE_UNDER_TOLERANCE);
                              } */
                              
                              // Amount Tolerance
                              system.debug(logginglevel.error,'>>>> draftInvLine_InvAmountTotal:' + draftInvLine_InvAmountTotal);
                              system.debug(logginglevel.error,'>>>> invAmountMatchedByPOL.get(poLine.Id):' + invAmountMatchedByPOL.get(poLine.Id));
                              Decimal amtTolerance = KSE.addQuantityToField (0,receiptInvLine.Purchase_Order_Line__r.Purchase_Order__r.Amount_Tolerance__c);
                              system.debug(logginglevel.error,'>>>> amtTolerance:' + amtTolerance);
                              system.debug(logginglevel.error,'>>>> dreceiptInvLine.Purchase_Order_Line__r.Unit_Price__c * receiptInvLine.Purchase_Order_Line__r.Quantity_Received__c:' + receiptInvLine.Purchase_Order_Line__r.Unit_Price__c * receiptInvLine.Purchase_Order_Line__r.Quantity_Received__c);
                              Decimal maxInvoiceAmount = (receiptInvLine.Purchase_Order_Line__r.Unit_Price__c * receiptInvLine.Purchase_Order_Line__r.Quantity_Received__c) + amtTolerance;
                              maxInvoiceAmount = maxInvoiceAmount.setScale(2,System.RoundingMode.HALF_UP);
                              system.debug(logginglevel.error,'>>>> maxInvoiceAmount:' + maxInvoiceAmount);
                              Decimal receiptInvLineAmount = draftInvLine_InvAmountTotal + invAmountMatchedByPOL.get(poLine.Id);
                              receiptInvLineAmount = receiptInvLineAmount.setScale(2,System.RoundingMode.HALF_UP);
                              system.debug(logginglevel.error,'>>>> receiptInvLineAmount:' + receiptInvLineAmount);

                              if( receiptInvLineAmount > maxInvoiceAmount ){
                                  setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_AMOUNT_OVER_TOLERANCE.code, true);
                                  exceptionTypes.put(ExceptionUtil.SI_AMOUNT_OVER_TOLERANCE.code,ExceptionUtil.SI_AMOUNT_OVER_TOLERANCE);
                              }else{
                                  setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_AMOUNT_OVER_TOLERANCE.code, false);
                                  exceptionTypes.put(ExceptionUtil.SI_AMOUNT_OVER_TOLERANCE.code,ExceptionUtil.SI_AMOUNT_OVER_TOLERANCE);
                              }                          
                          }
                      }
                      else{ // no matching receipt lines found, flag as qty exception
                          setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_INVOICE_QUANTITY.code, true);   
                          exceptionTypes.put(ExceptionUtil.SI_INVOICE_QUANTITY.code,ExceptionUtil.SI_INVOICE_QUANTITY);   
                      }
                      
                        
                      if(receiptInvLine.Purchase_Order_Line__r.Purchase_Order__r.Unit_Price_Tolerance_Over__c == null){
                          // price matching against PO line
                          if(receiptInvLine.Unit_Price__c == poLine.Unit_Price__c){//KNDY-14371
                              setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_UNIT_PRICE.code, false);
                              exceptionTypes.put(ExceptionUtil.SI_UNIT_PRICE.code,ExceptionUtil.SI_UNIT_PRICE);
                          }
                          else{
                              setException.put(receiptInvLine.Id+'~'+ExceptionUtil.SI_UNIT_PRICE.code, true);
                              exceptionTypes.put(ExceptionUtil.SI_UNIT_PRICE.code,ExceptionUtil.SI_UNIT_PRICE);
                          }
                      }        
                  }// end of if conditional 
                   
                  // Save the SIL to update Quantity Received regardless of exceptions
                  mapRILToUpdate.put(receiptInvLine.Id,receiptInvLine);
                   
                }//end of for loop iterating over receipt invoice lines
           }   
        }// end of for loop iterating over poLines
        
        for(String key : setException.keyset()) {
            Id invoiceId = key.split('~')[0];
            String exCode = key.split('~')[1];
            if(invoiceLineIds.containsKey(invoiceId)) {
                if(setException.get(key)) {
                    exService.setException(invoiceLineIds.get(invoiceId),exceptionTypes.get(exCode)); 
                }
                else {
                   exService.clearException(invoiceLineIds.get(invoiceId),exceptionTypes.get(exCode)); 
                }
            } 
        }
               
        for(Supplier_Invoice_Line__c sil : supplierInvoiceLineList) {
            if(mapRILToUpdate.containsKey(sil.Id)) {
                sil.Quantity_Received__c = mapRILToUpdate.get(sil.Id).Quantity_Received__c;
            }
        }
        
        DML.updateAsUser(mapRLToUpdate.values());
    }
        
    /*
        Loop through all invoice lines for a given supplier invoice and move it to Approved status if all lines have been matched
    */
    public static void updateSupplierInvoices(Map<Id, Supplier_Invoice__c> invoicesToUpdateStatus, Set<ID> updateLastVisitedTimeOnInvs, Id batchId){
        system.debug('***updateSupplierInvoices***'+invoicesToUpdateStatus+'*'+updateLastVisitedTimeOnInvs+'*'+batchId);
        Map<Id,Supplier_Invoice__c> invoicesToMoveForward = new Map<Id,Supplier_Invoice__c>();
		Map<ID, Purchase_Order_Line__c> mapOfPOLsToUpdate = new Map<ID, Purchase_Order_Line__c>();

        if(!invoicesToUpdateStatus.isEmpty() || !updateLastVisitedTimeOnInvs.isEmpty())  {
            
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			Set<Id> siIds = invoicesToUpdateStatus.keySet();
			
			SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','Status__c','Invoice_Type__c'
			});
			soql.setWhereClause('status__c =\'Draft\' and Hold__c = false and Id IN :siIds');

			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Supplier_Invoice_Lines__r');
			childRel.addFields(new set<string>{//KNDY-14371
				'id','Exceptions_Count__c','Invoice_Quantity__c','Unit_Price__c','Purchase_Order_Line__c'
			});
			soql.addChildRelationship(childRel);
			
			List<Supplier_Invoice__c> invoicesToSelect = Database.query(soql.getQuery());
            system.debug('***invoicesToSelect***'+invoicesToSelect);
            Map<ID, Supplier_Invoice_Line__c> mapOfSIL = new Map<ID, Supplier_Invoice_Line__c>();
            List<ID> polsToUpdate = new List<ID>();
            List<ID> linesInError = new List<Id>();
            for (Supplier_Invoice__c invoice: invoicesToSelect){
                linesInError.clear(); //DP: added this, I think it was a bug waiting to be discovered
                for (Supplier_Invoice_Line__c line: invoice.Supplier_Invoice_Lines__r){
                    if(line.Exceptions_Count__c > 0)
                        linesInError.add(line.id);
                    else{//KNDY-8790 collecting all SIL & POLs to update buckets on POL
                    	mapOfSIL.put(line.id, line); 
                    	
                	}
                }
                system.debug('***linesInError***'+linesInError);
                if(linesInError.size() == 0){
                    invoice.Status__c = 'Approved';
                    invoice.Exception__c = false;
                    invoice.Exception_Details__c = null;
                    invoice.Last_Visited_By_Batch__c = system.now(); //PTP-420
                    invoice.Batch_Job_Id__c = batchId;
                    invoicesToMoveForward.put(invoice.Id, invoice);
                    if (invoice.Invoice_Type__c == invTypeInvoice){//KNDY-8790
                    for (Supplier_Invoice_Line__c line: invoice.Supplier_Invoice_Lines__r){
                    	if (line.Purchase_Order_Line__c != null)
                    		polsToUpdate.add(line.Purchase_Order_Line__c);
                    }
                }
            }
            }
            //KNDY-8790
            if (!polsToUpdate.isEmpty()){
            	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','Quantity_Matched__c','Amount_Matched__c'
				});
				soql.setWhereClause('ID in :polsToUpdate');
				
				List<Purchase_Order_Line__c> listOfPOLsToUpdate = Database.query(soql.getQuery());
            	
            	mapOfPOLsToUpdate.putAll(listOfPOLsToUpdate);
            	// Loop through the SIs approved then check if SIL Map contains that. 
            	// check if SIL POL exists in aboce map. if so, then update buckets
            	for (Supplier_Invoice__c invoice: invoicesToMoveForward.values()){
            		if (invoice.Invoice_Type__c == invTypeInvoice){//KNDY-8790
	            		for (Supplier_Invoice_Line__c line: invoice.Supplier_Invoice_Lines__r){
	            			if (mapOfPOLsToUpdate.containsKey(line.Purchase_Order_Line__c)){
	            				mapOfPOLsToUpdate.get(line.Purchase_Order_Line__c).Quantity_Matched__c = KSE.addQuantityToField(mapOfPOLsToUpdate.get(line.Purchase_Order_Line__c).Quantity_Matched__c, line.Invoice_Quantity__c);
	            				mapOfPOLsToUpdate.get(line.Purchase_Order_Line__c).Amount_Matched__c = KSE.addQuantityToField(mapOfPOLsToUpdate.get(line.Purchase_Order_Line__c).Amount_Matched__c, line.Invoice_Quantity__c * line.Unit_Price__c);//KNDY-14371
	            			}
	            				
	            		}
	            	}
            	}
            
            }
            system.debug('>>>>linesInError: ' + linesInError);

          //PTP-420
            if (updateLastVisitedTimeOnInvs.size() > 0){
             for (ID siID: updateLastVisitedTimeOnInvs) {
               if(!invoicesToMoveForward.containsKey(siID)) {
                  invoicesToMoveForward.put(siId, new Supplier_Invoice__c(ID = siID, Last_Visited_By_Batch__c = system.now()));   
               }
             }
            }
            
            if (!invoicesToMoveForward.isEmpty()){ 	  
                DML.updateAsUser(invoicesToMoveForward.values());
                DML.updateAsUser(mapOfPOLsToUpdate.values());
            }
        }   
    }


    public static void ReceiptInvoicedInFull(List<Receipt_Line__c> records){
        
        for(  Receipt_Line__c rl : records ){
            
            if( rl.Uninvoiced_Quantity__c != 0 ){
                
                rl.Invoiced__c = false;
            }
            else{
                rl.Invoiced__c = true;
            }
        }
        
    }
  
    //Prevents the change of Supplier.
    public static void preventChangeSupplier(List<Supplier_Invoice__c> invoices, Map<Id,Supplier_Invoice__c> oldmap){
        
        //Initilize a list of records to process
        List<Supplier_Invoice__c> recordsToProcess = new List<Supplier_Invoice__c>();
        
        //Initilize a set of ids
        Set<Id> recordsIds = new Set<Id>();
        
        //Loop through the records and check if the change is the supplier
        for(Supplier_Invoice__c record:invoices){
            
            if(record.Supplier__c != oldmap.get(record.Id).Supplier__c){
                
                recordsToProcess.add(record);
                recordsIds.add(record.Id);
                
            }
            
        }
        
        if(recordsToProcess.size() == 0){
            return;
        }
        
		SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		soql.setWhereClause('Id IN :recordsIds');
		
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Supplier_Invoice_Lines__r');
		childRel.addFields(new set<string>{
			'Id'
		});
		soql.addChildRelationship(childRel);
		
		Map<Id,Supplier_Invoice__c> supplierInvoicesMap = new Map<Id,Supplier_Invoice__c>((List<Supplier_Invoice__c>)Database.query(soql.getQuery()));
		        
                    
    }
    
 
    /**
    *   @description    Defaults the payment method on the supplier invoice to the default payment method on supplier
    */
    public static void setDefaultPaymentMethod(){
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
            List<Supplier_Invoice__c> newList = (List<Supplier_Invoice__c>) trigger.new;
            Map<Id, Supplier_Invoice__c> newMap = (Map<Id, Supplier_Invoice__c>) trigger.newMap; 
            
            Set<Id> supplierIds = new Set<Id>();
            
            for(Supplier_Invoice__c supplierInvoice : newList){
                if(supplierInvoice.Payment_Method_G__c == null){
                    supplierIds.add(supplierInvoice.Supplier__c);
                }
            } 
            
            if(! supplierIds.isEmpty()){
				
				SOQLUtil soql = new SOQLUtil('Supplier__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','Payment_Method_G__c','RecordType.Name','RecordType.DeveloperName','RecordTypeId'
				});
				soql.setWhereClause('Id IN :supplierIds');
				
				Map<Id, Supplier__c> suppliersMap = new Map<Id, Supplier__c>((List<Supplier__c>) Database.query(soql.getQuery()));
	            
	            for(Supplier_Invoice__c supplierInvoice : newList){
	                if(supplierInvoice.Payment_Method_G__c == null && supplierInvoice.Supplier__c != null && suppliersMap.containsKey(supplierInvoice.Supplier__c) ){
	                    supplierInvoice.Payment_Method_G__c = suppliersMap.get(supplierInvoice.Supplier__c).Payment_Method_G__c;
	                }
	            } 
            } 
        }
    }
    
    //isVoidCancel - isUnfinalized/isVoided/isCancelled
    //This method would return the matched quanity on voiding the SI.
    public static void returnMatchedQuantityUponVoid(Map<Id, Supplier_Invoice__c> siVoidedInputs, boolean isVoidCancel, boolean isReset, boolean isUnfinalize){
        if(!siVoidedInputs.isEmpty()){
            Map<Id, Supplier_Invoice_Line__c> mapRILs = new Map<Id, Supplier_Invoice_Line__c>();
            Map<Id, Supplier_Invoice_Line__c> map2WaySILs = new Map<Id, Supplier_Invoice_Line__c>();
            
			Set<Id> siIDs = siVoidedInputs.keySet();
			
			SOQLUtil soql = new SOQLUtil('Supplier_Invoice_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{//KNDY-14371
				'Id','Name','Purchase_Order_Line__c','Purchase_Order_Line__r.Invoice_Matching__c',
				'Supplier_Invoice__r.Invoice_Type__c','Purchase_Order_Line__r.Invoice_Status__c','Purchase_Order_Line__r.Quantity_Matched__c',
				'Purchase_Order_Line__r.Amount_Matched__c','Unit_Price__c','Invoice_Quantity__c','Quantity_Received__c','Matched__c',
				'Supplier_Invoice__r.Finalized__c'
			});
			soql.setWhereClause('Supplier_Invoice__c in :siIDs');
			
			List<Supplier_Invoice_Line__c> voidedSIRILs = Database.query(soql.getQuery());
        
            if(voidedSIRILs.size() > 0){
                for (Supplier_Invoice_Line__c sil : voidedSIRILs){
                    if (sil.Purchase_Order_Line__r.Invoice_Matching__c == 'Two Way'){
                        map2WaySILs.put(sil.Id, sil);
                    }
                    else{
                        mapRILs.put(sil.Id, sil);
                    }
                }
            }
            if (!map2WaySILs.isEmpty()){
                voidCancelUnfinalize_2WaySIls(map2WaySILs, false, isVoidCancel, isReset, isUnfinalize);  
            }
            if(!mapRILs.isEmpty()){
                returnMatchedQuantity(mapRILs.values(), mapRILs, false, isVoidCancel, isReset, isUnfinalize);  
            }
        }
        
    }
    
    public static void voidCancelUnfinalize_2WaySIls( Map<Id, Supplier_Invoice_Line__c> sils, Boolean isDelete, Boolean isVoidCancel, Boolean isReset, boolean isUnfinalize){
         Map<Id, Purchase_Order_Line__c> polLineMap = new Map<Id, Purchase_Order_Line__c>();
         list<Supplier_Invoice_Line__c> SILtoUpdate = new list<Supplier_Invoice_Line__c>();
         Map<Id, Double> poLine_QtyMatchedMap = new Map<Id, Double>();
         Map<Id, Double> poLine_AmtMatchedMap = new Map<Id, Double>();
         Map<ID, Purchase_Order_Line__c> mapOfPOLsToUpdate = new Map<ID, Purchase_Order_Line__c>();
         
         for(Supplier_Invoice_Line__c sil: sils.values()){
             if(!isDelete && (isVoidCancel || isUnfinalize) ){
             	
                 sil.Matched__c = false;
                 SILtoUpdate.add(sil);
                 
                 if (sil.Supplier_Invoice__r.Invoice_Type__c == invTypeInvoice){
	                 //set initial value of POL Qty Matched
	                 if (!poLine_QtyMatchedMap.containsKey(sil.Purchase_Order_Line__c)){
	                     poLine_QtyMatchedMap.put(sil.Purchase_Order_Line__c, sil.Purchase_Order_Line__r.Quantity_Matched__c);
	                 }
		             //Reset the Quantity Matched & Amt matched fields on POL, deducting the invoice quantity from SIL
		             Decimal polNewQtyMatched = KSE.subtractDecimals (poLine_QtyMatchedMap.get(sil.Purchase_Order_Line__c), sil.Invoice_Quantity__c);
		             poLine_QtyMatchedMap.put(sil.Purchase_Order_Line__c, polNewQtyMatched);
		             
	                 //set initial value of POL Amt Matched
	                 if (!poLine_AmtMatchedMap.containsKey(sil.Purchase_Order_Line__c)){
	                     poLine_AmtMatchedMap.put(sil.Purchase_Order_Line__c, sil.Purchase_Order_Line__r.Amount_Matched__c);
	                 }
		             Decimal polNewAmtMatched = KSE.subtractDecimals (poLine_AmtMatchedMap.get(sil.Purchase_Order_Line__c), (sil.Invoice_Quantity__c * sil.Unit_Price__c));//KNDY-14371
		             poLine_AmtMatchedMap.put(sil.Purchase_Order_Line__c, polNewAmtMatched);
	             }
             }
                 
                 
             }
         
         if (poLine_QtyMatchedMap.size() > 0){
             for (Id polId: poLine_QtyMatchedMap.keyset()){
             	if (!mapOfPOLsToUpdate.containsKey(polId)){
                 	mapOfPOLsToUpdate.put(polId, new Purchase_Order_Line__c(Id = polId, Quantity_Matched__c = poLine_QtyMatchedMap.get(polId)));
             	}else{
             		mapOfPOLsToUpdate.get(polId).Quantity_Matched__c = poLine_QtyMatchedMap.get(polId);
             	}
             }
         }
         
         if (poLine_AmtMatchedMap.size() > 0){
             for (Id polId: poLine_AmtMatchedMap.keyset()){
             	if (!mapOfPOLsToUpdate.containsKey(polId)){
                 	mapOfPOLsToUpdate.put(polId, new Purchase_Order_Line__c(Id = polId, Amount_Matched__c = poLine_AmtMatchedMap.get(polId)));
             	}else{
             		mapOfPOLsToUpdate.get(polId).Amount_Matched__c = poLine_AmtMatchedMap.get(polId);
             	}
             }
         }    
         if (!mapOfPOLsToUpdate.isEmpty())
         	DML.updateAsUser( mapOfPOLsToUpdate.values() ); //upsert pols
         
         if(SILtoUpdate.size()>0){
             DML.updateAsUser( SILtoUpdate );
         }
    }
    
    private static set<Id> matchedQtyRLIds = new set<Id>();
    //Added flag isUnfinalized
    public static void returnMatchedQuantity(List<Supplier_Invoice_Line__c> silInputs, Map<Id, Supplier_Invoice_Line__c> oldRecords, Boolean isDelete, Boolean isVoidCancel, Boolean isReset, boolean isUnfinalize){
        // build set of assocaited PO Lines and build map of PO Line to Receipt Line
        map<id, list<Receipt_Line__c>> POLtoReceiptLineMap = new map<id, list<Receipt_Line__c>>();
        map<id, Purchase_Order_Line__c> polMap = new map<id, Purchase_Order_Line__c>(); // KNDY-2730
        List<Supplier_Invoice_Line__c> beforeUpdateLineRecords = new List<Supplier_Invoice_Line__c>();
        //KNDY-8790 Build maps, reset buckets and update POLs
         Map<Id, Double> poLine_QtyMatchedMap = new Map<Id, Double>();
         Map<Id, Double> poLine_AmtMatchedMap = new Map<Id, Double>();
        
        for(Supplier_Invoice_Line__c silNew: silInputs){
            Supplier_Invoice_Line__c sil = oldRecords.get(silNew.id);
            beforeUpdateLineRecords.add(sil);
            if(POLtoReceiptLineMap.containskey(sil.Purchase_Order_Line__c)==false){
                POLtoReceiptLineMap.put(sil.Purchase_Order_Line__c, new list<Receipt_Line__c>());
            }     
        }
          
		Set<Id> polIds = POLtoReceiptLineMap.keyset();
		
		SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Invoice_Matching__c','Quantity_Credited__c','Amount_Credited__c','Quantity_Received__c','Quantity_Matched__c',
			'Amount_Matched__c'
		});
		soql.setWhereClause('id in :polIds FOR UPDATE');

		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Receipt_Lines__r');
		childRel.addFields(new set<string>{
			'id','Name','Quantity_Received__c','Uninvoiced_Quantity__c'
		});
		childRel.setWhereClause('Status__c != \'Void\' and Status__c != \'Cancelled\' and Receiving_Document__r.Type__c = \'Purchase Order Receipt\'');
		soql.addChildRelationship(childRel);

		for(Purchase_Order_Line__c poLine:Database.query(soql.getQuery())){
            POLtoReceiptLineMap.get(POline.id).addall(poLine.Receipt_Lines__r);    
            
            polMap.put(poLine.Id, poLine); // KNDY-2730
        }
        
        set<Receipt_Line__c> rlToUpdate = new set<Receipt_Line__c>();
        list<Supplier_Invoice_Line__c> SILtoUpdate = new list<Supplier_Invoice_Line__c>();
        
        for(Supplier_Invoice_Line__c silNew:silInputs){
            double QtyReceived = (silNew.Quantity_Received__c==null?0:silNew.Quantity_Received__c);
            if(polMap.containsKey(silNew.Purchase_Order_Line__c) && !isVoidCancel){
                QtyReceived = polMap.get(silNew.Purchase_Order_Line__c).Quantity_Received__c;
            }
	            
            decimal quantityReceived = 0;

            Supplier_Invoice_Line__c silOld = oldRecords.get(silNew.id);
            //Invoking the subract function instead of Add with a -ve parameter which results in error when one of the parameter is null
            Decimal deltaQuantity = KSE.subtractDecimals(silNew.Invoice_Quantity__c, silOld.Invoice_Quantity__c); 
            if( (isVoidCancel && !isUnfinalize) || isDelete) {
                deltaQuantity = -KSE.addQuantityToField(silNew.Invoice_Quantity__c,0);
            }
	         
	        Decimal quantityLeftToReturn = KSE.addQuantityToField(silNew.Quantity_Received__c, 0); 
	            
            // iterate over new RIL records coming in but get the PO line reference for the old record that was modified
	            
            if((silNew.Quantity_Received__c != 0 && silOld.Invoice_Quantity__c != silNew.Invoice_Quantity__c) || isReset || isVoidCancel || isUnfinalize) {
               // Use the PO Line id to grab the Receipt Lines and loop through:
               for(Receipt_Line__c receiptLine:POLtoReceiptLineMap.get(silOld.Purchase_Order_Line__c)){
                  // Quantity Received (Receipt) - Quantity Uninvoiced = Maximum that can be applied to this Receipt Line
                  Double max = (receiptLine.Quantity_Received__c!=null?receiptLine.Quantity_Received__c:0) - (receiptLine.Uninvoiced_Quantity__c!=null?receiptLine.Uninvoiced_Quantity__c:0);
                  
                  if(receiptLine.Uninvoiced_Quantity__c != null && quantityLeftToReturn > 0){ 
                      if(silNew.Quantity_Received__c <= max){   // If QtyReceived is less or equal to max then apply all of quantity received
                          if(isReset || isVoidCancel || isUnfinalize) {
                             receiptLine.Uninvoiced_Quantity__c += quantityLeftToReturn; // PTP-614
                          }
                          quantityReceived =0;
                          quantityLeftToReturn -= KSE.addQuantityToField(silNew.Quantity_Received__c, 0); 
                      }
                      else{
                          // If QtyReceived is more than Maximum, subtract maximum from 
                          if(quantityLeftToReturn <= max) {
                              receiptLine.Uninvoiced_Quantity__c += quantityLeftToReturn;
                              QtyReceived -= max;
                              quantityReceived +=  KSE.addQuantityToField(receiptLine.Quantity_Received__c, -receiptLine.Uninvoiced_Quantity__c);
                              quantityLeftToReturn = 0;
                          }
                          else {
                              receiptLine.Uninvoiced_Quantity__c += max;
                              quantityLeftToReturn -= max;
                          }
                     }
	                    
                     if(receiptLine.Uninvoiced_Quantity__c > 0)
                          receiptLine.matched__c = false;
                  }        
  
                  if(QtyReceived==0) break;
               }
            }
           
            // KNDY - 2730 : Put the quantity back to the POL so that a new supplier invoice can be created against this POL.
            
            if(silOld.Purchase_Order_Line__c != null){
                if(polMap.containsKey(silOld.Purchase_Order_Line__c) == false){
                    polMap.put(silOld.Purchase_Order_Line__c, silOld.Purchase_Order_Line__r);
                }
                
                if(silNew.Invoice_Quantity__c != null && silNew.Unit_Price__c != null){//KNDY-14371
                    if(silNew.Invoice_Quantity__c * silNew.Unit_Price__c < 0){//KNDY-14371
                        if(silNew.Invoice_Quantity__c < 0) {
                            polMap.get(silOld.Purchase_Order_Line__c).Quantity_Credited__c = KSE.addQuantityToField(polMap.get(silOld.Purchase_Order_Line__c).Quantity_Credited__c, deltaQuantity);
                        }
                        polMap.get(silOld.Purchase_Order_Line__c).Amount_Credited__c = KSE.addQuantityToField(polMap.get(silOld.Purchase_Order_Line__c).Amount_Credited__c, deltaQuantity * silNew.Unit_Price__c);//KNDY-14371                      
                    }
                }
                
            }
            
            if(!isDelete){
                silNew.Quantity_Received__c = quantityReceived;
                if(isVoidCancel || isReset || isUnfinalize) {
                    SILtoUpdate.add(silNew);
                }
                silNew.Matched__c = false;
            }
            RLtoUpdate.addall(POLtoReceiptLineMap.get(silOld.Purchase_Order_Line__c));
        }
        
        //KNDY-8790
        if(isVoidCancel || isUnfinalize) {
	        for(Supplier_Invoice_Line__c sil: oldRecords.values()){
	        	if (sil.Purchase_Order_Line__c != null){//KNDY-10813
	        		//KNDY-13512: do no reset POL qty matched fields for sil resets
		        	if ( sil.Supplier_Invoice__r.Invoice_Type__c == invTypeInvoice){

				    	//KNDY-8790 set initial value of POL Qty Matched
			             if (!poLine_QtyMatchedMap.containsKey(sil.Purchase_Order_Line__c)){
			                 poLine_QtyMatchedMap.put(sil.Purchase_Order_Line__c, sil.Purchase_Order_Line__r.Quantity_Matched__c);
			             }
			             //Reset the Quantity Matched field on POL, deducting the invoice quantity from SIL
			             Decimal polNewQtyMatched = KSE.subtractDecimals (poLine_QtyMatchedMap.get(sil.Purchase_Order_Line__c), sil.Invoice_Quantity__c);
			             poLine_QtyMatchedMap.put(sil.Purchase_Order_Line__c, polNewQtyMatched);
			             
			             //KNDY-8790 set initial value of POL Amt Matched
			             if (!poLine_AmtMatchedMap.containsKey(sil.Purchase_Order_Line__c)){
			                 poLine_AmtMatchedMap.put(sil.Purchase_Order_Line__c, sil.Purchase_Order_Line__r.Amount_Matched__c);
			             }
			             //Reset the Amount Matched field on POL, deducting the invoice amount from SIL
			             Decimal polNewAmtMatched = KSE.subtractDecimals (poLine_AmtMatchedMap.get(sil.Purchase_Order_Line__c), (sil.Invoice_Quantity__c * sil.Unit_Price__c));//KNDY-14371
			             poLine_AmtMatchedMap.put(sil.Purchase_Order_Line__c, polNewAmtMatched);
			             
			             if (polMap.containsKey(sil.Purchase_Order_Line__c)){
			             	polMap.get(sil.Purchase_Order_Line__c).Quantity_Matched__c = poLine_QtyMatchedMap.get(sil.Purchase_Order_Line__c);
			             	polMap.get(sil.Purchase_Order_Line__c).Amount_Matched__c = poLine_AmtMatchedMap.get(sil.Purchase_Order_Line__c);
			             }else{
			             	polMap.put(sil.Purchase_Order_Line__c, new Purchase_Order_Line__c(Id = sil.Purchase_Order_Line__c, Quantity_Matched__c = poLine_QtyMatchedMap.get(sil.Purchase_Order_Line__c), Amount_Matched__c = poLine_AmtMatchedMap.get(sil.Purchase_Order_Line__c)));
			             }
			             system.debug(LoggingLevel.ERROR, ' Updated POL infor: ' + polMap.get(sil.Purchase_Order_Line__c));
			                      
			      	}
	        	}
	        }
        }
        if(polMap.values().size() > 0){
            DML.updateAsUser( polMap.values());
        }

        if(RLtoUpdate.size()>0){
            list<Receipt_Line__c> RL_List = new list<Receipt_Line__c>();
            for(Receipt_Line__c rl : RLtoUpdate){
                if(!matchedQtyRLIds.contains(rl.Id)){
                    RL_List.add(rl);
                    matchedQtyRLIds.add(rl.Id);
                }
            }
            DML.updateAsUser( RL_List );
        }
        if(SILtoUpdate.size()>0){
            DML.updateAsUser( SILtoUpdate );
        }
    }
    
    // This method updates the Invoice Quantity to Stock field on the Receipt invoice line.  THis field is used for accounting and must be in the stocking UOM.
    // The invoice quantity is captured in Purchasing UOM, so this may be different. This should only be called from a before insert trigger.
    public static void updateQuantitytoStock(list<Supplier_Invoice_Line__c> inputList){
        map<id,Item__c> itemMap = new map<id,Item__c>();
        // Build a map of all items in trigger.new
        for(Supplier_Invoice_Line__c sil:inputList){
            if(itemMap.containskey(sil.Item__c)==false){
                itemMap.put(sil.Item__c, new Item__c());
            }
        }   
         // Build converstion factors for all items mentioned
        map<id,decimal> itemconversionFactor = new map<id,decimal>(); 
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Set<Id> itemIds = itemMap.keyset();
		SOQLUtil soql = new SOQLUtil('Item__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','Purchasing_UOM__c','Stocking_UOM__c','Stocking_UOM__r.Name','Purchasing_UOM__r.Name', 'Packaging_UOM__c'
		});
		soql.setWhereClause('id in :itemIds');

		for(Item__c item:Database.query(soql.getQuery())){

            decimal convFactor = KSE.getConversionFactor(item);
            itemConversionFactor.put(item.id,convFactor);
            
        }
        // Update Quantity to Stock
        for(Supplier_Invoice_Line__c sil:inputList){
            if(itemConversionFactor.containsKey(sil.Item__c) && sil.Invoice_Quantity__c!=null){
                sil.Invoice_Quantity_To_Stock__c = sil.Invoice_Quantity__c * itemConversionFactor.get(sil.Item__c); 
            }else{
                sil.Invoice_Quantity_To_Stock__c = 0;
            }
        }
        
    }
          
    //Header level erros for an SI.
    public static boolean checkHeaderErrors(Supplier_Invoice__c si, JsonResult result){
        if(si.Company__c == null){
            result.addMessage('Company is required', ApexPages.Severity.ERROR );
        }
        
        if(si.Supplier__c == null){
            result.addMessage('Supplier is required', ApexPages.Severity.ERROR );
        }
        
        if(si.Date_Invoiced__c == null){
            result.addMessage('Date invoiced is required', ApexPages.Severity.ERROR );
        }
        
        if(si.Supplier_Invoice__c == null){
            result.addMessage('Supplier invoice is required', ApexPages.Severity.ERROR );
        }
        
        if(si.Invoice_Type__c == invTypeInvoice && si.Credit_Memo_Amount__c == null ){
            result.addMessage('Invoice amount is invalid', ApexPages.Severity.ERROR );
        }
        else if(si.Invoice_Type__c == invTypeCM && si.Credit_Memo_Amount__c == null ){
            result.addMessage('Credit Memo amount is required', ApexPages.Severity.ERROR );
        }

        if(si.Apply_to_Invoice__c == null){
            result.addMessage('Invoice to apply is required', ApexPages.Severity.ERROR );
        }
        

        if(result.messages.size() > 0){
            result.success = false;
            return true;
        }
        else{
            return false;
        }
     }
     
     //This methods pulls up records based on the POL
     public static void fetchRecordsByPOL(Set<Id> poLineIds, 
                                          List<Purchase_Order_Line__c> purchaseOrderLines, 
                                          Map<Id, List<Supplier_Invoice_Line__c>>mapPOLIdSILines, 
                                          Map<Id, List<Receipt_Line__c>> mapPOLIdReceiptLines){
        if(poLineIds.size() > 0){ 
            
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','Status__c','Quantity_Received__c','Unit_Price__c','Order_Quantity__c','Purchase_Order__r.Quantity_Tolerance_Over__c',
				'Purchase_Order__r.Amount_Tolerance__c','Purchase_Order__r.Unit_Price_Tolerance_Over__c',
				'Purchase_Order__r.Buyer__c','Purchase_Order__r.Purchase_Agreement__r.Corporate_Buyer__c',
				'Invoice_Matching__c','Invoice_Status__c','Quantity_Matched__c','Amount_Matched__c'
			});
			soql.setWhereClause('id IN :poLineIds AND Invoice_Status__c = :poLineInvStatusOpen');
			
			for (List<Purchase_Order_Line__c> pols: Database.query(soql.getQuery())){
                purchaseOrderLines.addAll(pols);
            }
            
			soql = new SOQLUtil('Receipt_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Name','Matched__c','Purchase_Order_Line__c','Quantity_Received__c','Uninvoiced_Quantity__c','Receiving_Document__r.Transaction_Date__c'
			});
			soql.setWhereClause('Purchase_Order_Line__c in :poLineIds and Quantity_Received__c != null AND Quantity_Received__c != 0 AND Status__c != \'Void\' and Status__c != \'Cancelled\' and Receiving_Document__r.Type__c = \'Purchase Order Receipt\'');
			soql.setOrderByClause('Receiving_Document__r.Transaction_Date__c ASC');

			for (List<Receipt_Line__c> receiptLines : Database.query(soql.getQuery())){
	             for (Receipt_Line__c line: receiptLines){ 
	                if (!mapPOLIdReceiptLines.containsKey(line.Purchase_Order_Line__c)){
	                    mapPOLIdReceiptLines.put(line.Purchase_Order_Line__c, new List<Receipt_Line__c>());
	                }
	                mapPOLIdReceiptLines.get(line.Purchase_Order_Line__c).add(line);
	             }
	        }
	        
			soql = new SOQLUtil('Supplier_Invoice_Line__c', true); 
			soql.addFields(new set<string>{//KNDY-14371
				'id','name','Historical__c','Exception_Details__c','Invoice_Quantity__c','Matched__c','Purchase_Order_Line__c','Price_Exception__c',
				'Quantity_Received__c','Supplier_Invoice__r.Name','Supplier_Invoice__c','Supplier_Invoice__r.Status__c','Quantity_Exception__c',
				'Unit_Price__c','Supplier_Invoice__r.Exception_Details__c','Supplier_Invoice__r.Exception__c','Purchase_Order__r.Buyer__c',
				'Purchase_Order_Line__r.Purchase_Order__r.Buyer__c','Purchase_Order__r.Purchase_Agreement__r.Corporate_Buyer__c','Purchase_Order_Line__r.Purchase_Order__r.Purchase_Agreement__r.Corporate_Buyer__c',
				'Purchase_Order_Line__r.Purchase_Order__r.Quantity_Tolerance_Over__c',
				'Purchase_Order_Line__r.Purchase_Order__r.Unit_Price_Tolerance_Over__c',
				'Purchase_Order_Line__r.Purchase_Order__r.Amount_Tolerance__c','Purchase_Order_Line__r.Quantity_Received__c','Purchase_Order_Line__r.Order_Quantity__c',
				'Purchase_Order_Line__r.Unit_Price__c','Extended_Price__c'
			});
			soql.setWhereClause('Purchase_Order_Line__c in :poLineIds and Supplier_Invoice__r.Status__c != \'Incomplete\' '
								+' and Supplier_Invoice__r.Status__c != \'Void\' and Supplier_Invoice__r.Status__c != \'Cancelled\''
								+'and Supplier_Invoice__r.Invoice_Type__c !=\'Prepayment\'');//KNDY-13949 KNDY-13435 condition for not including prepayment added

			for (List<Supplier_Invoice_Line__c> invoiceLines : Database.query(soql.getQuery())){
	            for (Supplier_Invoice_Line__c line: invoiceLines){ 
	                if (!mapPOLIdSILines.containsKey(line.Purchase_Order_Line__c)){
	                    mapPOLIdSILines.put(line.Purchase_Order_Line__c, new List<Supplier_Invoice_Line__c>());
	                }
	                mapPOLIdSILines.get(line.Purchase_Order_Line__c).add(line);
	            }
	        }
        }
   	}
   	
     //Calculate payment due date, depends on the type of payment term
    //on insert calculate if both invoiced date and payment term is populated
    //on update if either one is changed
    public static void setPaymentDueDate() {
        
        list<Supplier_Invoice__c> siRecs = new list<Supplier_Invoice__c>();
        if(trigger.isDelete){
              siRecs =  (List<Supplier_Invoice__c>)Trigger.old;
          }else if(trigger.isInsert || trigger.isUpdate){
              siRecs =  (List<Supplier_Invoice__c>)Trigger.new;
        }
        list<Supplier_Invoice__c> lSIs = new list<Supplier_Invoice__c>();
        set<Id> sPaymentTerms = new set<id>();
        for(Supplier_Invoice__c si : siRecs)
        {
            if(trigger.isBefore)
            {
                if((trigger.isInsert && si.Date_Invoiced__c != null && si.Payment_Term__c != null) 
                     || (trigger.isUpdate && (KSE.isFieldChanging('Date_Invoiced__c',si,trigger.oldmap) || KSE.isFieldChanging('Payment_Term__c',si,trigger.oldmap)))){ 
                           lSIs.add(si);
                           sPaymentTerms.add(si.Payment_Term__c);
                }    
            }
        }
        system.debug(logginglevel.error,'sPaymentTerms --->'+sPaymentTerms);
        if(!sPaymentTerms.isEmpty())
        {
            
            SOQLUtil soql = new SOQLUtil('Payment_Term__c', false);
            soql.addFields(new set<string>{
                'Id','Type__c','Due_Days__c','Day_of_month__c','Cut_off_Day__c','Months_Ahead__c'
            });
            soql.setWhereClause('id in :sPaymentTerms');
            map<Id,Payment_Term__c> mPaymentTerms = new map<id,Payment_Term__c> ((List<Payment_Term__c>)Database.query(soql.getQuery()));

            system.debug(logginglevel.error,'mPaymentTerms -->'+mPaymentTerms);
            for(Supplier_Invoice__c si : lSIs)
            {
                if(mPaymentTerms.containsKey(si.Payment_Term__c))
                {
                    try{
                        si.Payment_Due_Override_Date__c = KSE.getDueDate (si.Date_Invoiced__c, mPaymentTerms.get(si.Payment_Term__c));
                        system.debug(logginglevel.error,'si.Payment_Due_Override_Date__c---->'+si.Payment_Due_Override_Date__c);
                    }catch (Exception ex){
                        if (ex.getMessage() ==  Label.Payment_Term_Type_is_blank){
                            si.addError(Label.Please_enter_Type_on_associated_Payment_Term);
                        }
                        else{
                            si.addError(ex.getMessage());
                        }
                    }
                }
            }
        }
    }
    // KNDY-16326 Called by the SI/SIL Trigger
    private static Map<Id, Supplier_Invoice__c> getSIStatusMap(Set<Id> siIds){
            SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Status__c','Void__c'
            });
            soql.setWhereClause('Id in :siIds and Status__c in ( \'Void\' , \'Cancelled\')');
            Map<Id, Supplier_Invoice__c> siStatusMap = new Map<Id, Supplier_Invoice__c>((List<Supplier_Invoice__c>)Database.query(soql.getQuery()));
        return siStatusMap;
    }
    
    // KNDY-16326 Called by the SIL Trigger
    public static void restrictEditOnVoidAndCancelSIL(){
         Set<Id> siIds = new Set<Id>();
         Map<Id, Supplier_Invoice__c> siStatusMap = new Map<Id, Supplier_Invoice__c>();
         if(trigger.isDelete){
             for(Supplier_Invoice_Line__c sinvoiceLine: (List<Supplier_Invoice_Line__c>)Trigger.old){
                  siIds.add(sinvoiceLine.Supplier_Invoice__c);
             }
             
             if(siIds != null && siIds.size() > 0){
                siStatusMap =  SupplierInvoiceService.getSIStatusMap(siIds);      
             } 

             if(siStatusMap != null && siStatusMap.size() > 0){ 
                for(Supplier_Invoice_Line__c sinvoiceLine: (List<Supplier_Invoice_Line__c>)Trigger.old){  
                    if(siStatusMap.containsKey(sinvoiceLine.Id)){
                       sinvoiceLine.addError(Label.Cannot_edit_CILines_VoidCancel_CI);
                    }
                }      
            }
         }else if(trigger.isInsert || trigger.isUpdate){
             for(Supplier_Invoice_Line__c sinvoiceLine: (List<Supplier_Invoice_Line__c>)Trigger.new){
                  siIds.add(sinvoiceLine.Supplier_Invoice__c);
             }
             if(siIds != null && siIds.size() > 0){
               siStatusMap =  getSIStatusMap(siIds);
               System.debug(logginglevel.error,'siStatusMap-->'+siStatusMap);
             } 
           
             if(siStatusMap != null && siStatusMap.size() > 0){
                for(Supplier_Invoice_Line__c sinvoiceLine: (List<Supplier_Invoice_Line__c>)Trigger.new){   
                    System.debug(logginglevel.error, siStatusMap.get(sinvoiceLine.Id));
                    if(siStatusMap.containsKey(sinvoiceLine.Id)){
                       sinvoiceLine.addError(Label.Cannot_edit_CILines_VoidCancel_CI);
                    }  
                }
            }
         }
    }
    
    // KNDY-16326 Called by the SIL Trigger
    public static void restrictEditOnVoidAndCancelSI(){
        if(trigger.isDelete){
            for(Supplier_Invoice__c SInvoice: (List<Supplier_Invoice__c>)Trigger.old){  
                if (((KSE.isFieldChanging('Status__c', SInvoice, Trigger.oldMap)) == False) && (SInvoice.Void__c || SInvoice.Status__c == SupplierInvoiceService.STATUS_CANCELLED)){
                        SInvoice.addError(Label.Voided_SupplierInvoice_cannot_be_Deleted);
                }
            }
         }else if(trigger.isInsert || trigger.isUpdate){
            for(Supplier_Invoice__c SInvoice: (List<Supplier_Invoice__c>)Trigger.new){
                if (((KSE.isFieldChanging('Status__c', SInvoice, Trigger.oldMap)) == False) && (SInvoice.Void__c || SInvoice.Status__c == SupplierInvoiceService.STATUS_CANCELLED)){
                        SInvoice.addError(Label.Cannot_edit_CILines_VoidCancel_CI);  
                }
            }
         }
    }
    
     //Sets the credit memo to balance zero
     public static void setCreditMemoBalance() {
    	if(trigger.isBefore  && (trigger.isInsert || trigger.isUpdate)) {
    		
    		for(Supplier_Invoice__c si : (list<Supplier_Invoice__c>) trigger.new) {
    			
    			if(si.Credit_Memo_Balance__c != null && (si.Status__c =='Cancelled' || si.Status__c == 'Void')) {
    				si.Credit_Memo_Balance__c = 0.00;
    			}
    			
    			
    		}
    	}
    }	
	//KNDY-18171
	public static void populateShipToShipFromFieldsOnSIL(list<Supplier_Invoice_Line__c> lstSIL,list<Purchase_Order_Line__c> lstPOL){
		system.debug('***populateShipToShipFromFieldsOnSIL***'+lstSIL+'*'+lstPOL);
		if(!lstSIL.isEmpty() && !lstPOL.isEmpty()){
            map<Id,Purchase_Order_Line__c> mapPOL = new map<Id,Purchase_Order_Line__c>(lstPOL);
            if(!mapPOL.isEmpty()){
            	for(Supplier_Invoice_Line__c sil: lstSIL){
            		Purchase_Order_Line__c poLine = mapPOL.get(sil.Purchase_Order_Line__c);
            		if(poLine!=null){
            			//PO Type Drop Ship, Ship To Will be Deliver to Customer fields
						if(string.isNotBlank(poLine.Purchase_Order__r.Type__c) && poLine.Purchase_Order__r.Type__c.equalsIgnoreCase('Drop Ship')){
		                	sil.Ship_To_City__c = string.isNotBlank(sil.Ship_To_City__c)?sil.Ship_To_City__c
		                						  :poLine.Purchase_Order__r.Deliver_to_Customer__r.City__c;
		                	sil.Ship_To_Country__c = string.isNotBlank(sil.Ship_To_Country__c)?sil.Ship_To_Country__c
		                							 :poLine.Purchase_Order__r.Deliver_to_Customer__r.Country__c;
		                	sil.Ship_To_State__c = string.isNotBlank(sil.Ship_To_State__c)?sil.Ship_To_State__c
		                						   :poLine.Purchase_Order__r.Deliver_to_Customer__r.State__c;
		                	sil.Ship_To_Street__c = string.isNotBlank(sil.Ship_To_Street__c)?sil.Ship_To_Street__c
		                						    :poLine.Purchase_Order__r.Deliver_to_Customer__r.Street__c;
		                	sil.Ship_To_Zip_Code__c = string.isNotBlank(sil.Ship_To_Zip_Code__c)?sil.Ship_To_Zip_Code__c
		                							  :poLine.Purchase_Order__r.Deliver_to_Customer__r.Zip_Code__c;
		                							  
		                }else if(string.isNotBlank(poLine.Purchase_Order__r.Type__c)){ //Ship To Will be Delivery Facility on POL
		                	sil.Ship_To_City__c = string.isNotBlank(sil.Ship_To_City__c)?sil.Ship_To_City__c
		                						  :poLine.Delivery_Facility__r.City_Name__c;
		                	sil.Ship_To_Country__c = string.isNotBlank(sil.Ship_To_Country__c)?sil.Ship_To_Country__c
		                							 :poLine.Delivery_Facility__r.Country_Name__c;
		                	sil.Ship_To_State__c = string.isNotBlank(sil.Ship_To_State__c)?sil.Ship_To_State__c
		                						   :poLine.Delivery_Facility__r.State_Province_Name__c;
		                	sil.Ship_To_Street__c = string.isNotBlank(sil.Ship_To_Street__c)?sil.Ship_To_Street__c
		                							:poLine.Delivery_Facility__r.Street_Address__c;
		                	sil.Ship_To_Zip_Code__c = string.isNotBlank(sil.Ship_To_Zip_Code__c)?sil.Ship_To_Zip_Code__c
		                							  :poLine.Delivery_Facility__r.Zip_Postal_Code__c;
		                }
		                //Ship From is Purchased From Supplier On PO
		                sil.Ship_From_City__c = string.isNotBlank(sil.Ship_From_City__c)?sil.Ship_From_City__c
		                						:poLine.Purchase_Order__r.Supplier__r.City__c;
		                sil.Ship_From_Country__c = string.isNotBlank(sil.Ship_From_Country__c)?sil.Ship_From_Country__c
		                						   :poLine.Purchase_Order__r.Supplier__r.Country__c;
		                sil.Ship_From_State__c = string.isNotBlank(sil.Ship_From_State__c)?sil.Ship_From_State__c
		               							 :poLine.Purchase_Order__r.Supplier__r.State__c;
		               	sil.Ship_From_Street__c = string.isNotBlank(sil.Ship_From_Street__c)?sil.Ship_From_Street__c
		                						  :poLine.Purchase_Order__r.Supplier__r.Street__c;
		                sil.Ship_From_Zip_Code__c = string.isNotBlank(sil.Ship_From_Zip_Code__c)?sil.Ship_From_Zip_Code__c
		                						    :poLine.Purchase_Order__r.Supplier__r.Zip_Code__c;
		                						    
		                //striping html tags from address values
		                sil.Ship_To_City__c = string.isNotBlank(sil.Ship_To_City__c)?sil.Ship_To_City__c.stripHtmlTags():null;
		                sil.Ship_To_Country__c = string.isNotBlank(sil.Ship_To_Country__c)?sil.Ship_To_Country__c.stripHtmlTags():null;
		                sil.Ship_To_State__c = string.isNotBlank(sil.Ship_To_State__c)?sil.Ship_To_State__c.stripHtmlTags():null;
		                sil.Ship_To_Street__c = string.isNotBlank(sil.Ship_To_Street__c)?sil.Ship_To_Street__c.stripHtmlTags():null;
		                sil.Ship_To_Zip_Code__c = string.isNotBlank(sil.Ship_To_Zip_Code__c)?sil.Ship_To_Zip_Code__c.stripHtmlTags():null;	
		                
		                sil.Ship_From_City__c = string.isNotBlank(sil.Ship_From_City__c)?sil.Ship_From_City__c.stripHtmlTags():null;
		                sil.Ship_From_Country__c = string.isNotBlank(sil.Ship_From_Country__c)?sil.Ship_From_Country__c.stripHtmlTags():null;
		                sil.Ship_From_State__c = string.isNotBlank(sil.Ship_From_State__c)?sil.Ship_From_State__c.stripHtmlTags():null;
		                sil.Ship_From_Street__c = string.isNotBlank(sil.Ship_From_Street__c)?sil.Ship_From_Street__c.stripHtmlTags():null;
		                sil.Ship_From_Zip_Code__c = string.isNotBlank(sil.Ship_From_Zip_Code__c)?sil.Ship_From_Zip_Code__c.stripHtmlTags():null;				  
            		}
				}
            }
		}
	}
}