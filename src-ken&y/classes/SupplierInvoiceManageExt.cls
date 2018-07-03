public with sharing class SupplierInvoiceManageExt extends BaseController {
    ApexPages.StandardController con;
    
    private static SchemaUtil util = SchemaUtil.getInstance();
    public string pageTitle { get; set; }
    public string pageSubTitle { get; set; }
    public Supplier_Invoice__c si { get; set; }
    public String invoiceType { get; set; }
    public SegmentService segmentSvc = new SegmentService();
    public transient Boolean displayExceptions {get;private set;}
    private static TaxService taxation = TaxService.getInstance();
    // Segment Validation Exception Fields
    public static Boolean saveException = false;
    public static String errorMessage = '';
    public static Set<String> listOfInvalidSegments = new Set<String>();
    public static Set<String> listOfInvalidRowGUID = new Set<String>();
    public static String segmentErrors = '';
    public static Integer numberOfLinesWithSegmentErrors = 0;
    
    public GridRelatedListController.GridRelatedListConfig supplierInvoiceLinesConfig {get; set;}      
    public String supplierInvoiceLinesFieldList = null;
    public GridRelatedListController.GridRelatedListConfig segmentLinesConfig {get; set;} 
    public String segmentLinesFieldList = null;
    public GridRelatedListController.GridRelatedListConfig purchaseOrderLinesConfig {get; set;}      
    public String purchaseOrderLinesFieldList = null;
    public List<Grid_Views_Config__c> customViewList = null;
    public GridRelatedListController.GridRelatedListConfig exceptionsConfig {get; set;}      
    public String exceptionsFieldList = null;
    public ExceptionTasksExtNew exceptionTasksExtNew = null;
    public List<String> segmentFieldsList { get;set; }
    public string actionsMap{set;}
    public string nspace { get { return KSE.Namespace; }}
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
	public string supplierInvoiceLineTaxFieldList { get;set; }    //KNDY-18171
        
    private static TaxService taxSvc = TaxService.getInstance();
    public Boolean HasTax{
        get;private set;
    }
        
    public string getActionsMap(){
        System.debug(logginglevel.error,'si.id--->'+si.id);  
        return  SupplierInvoiceService.populateSISaveAndActions(si.id);
    }
    
    // Called by page for a new si (si with no id)
    public string getUserSIActionsMap(){//KNDY-17757
        return  SupplierInvoiceService.populateUserSIActions();
    }
    public string getSILActionsMap(){//KNDY-17757
        System.debug(logginglevel.error,'si--->'+si);  
        return SupplierInvoiceService.populateSILActions(si);
    }
    public SupplierInvoiceManageExt(ApexPages.StandardController controller) {
        con = controller;
        
        if( controller.getRecord().id != null ){
            si = (Supplier_Invoice__c) controller.getRecord();
            si = (Supplier_Invoice__c) getSupplierInvoiceDetails(si.id ,'0').records[0];   
            
            invoiceType = si.Invoice_Type__c;
            pageTitle = Label.Supplier_Invoice_Edit;
            pageSubTitle = si.name;
            if (si.Has_Exceptions__c || si.Has_Line_Exceptions__c){
                displayExceptions = true;
            }
            else{
                displayExceptions = false;
            }
            
            if (ApexPages.currentPage().getParameters().containsKey('clone') && 
                ApexPages.currentPage().getParameters().get('clone') == '1'){
                si = (Supplier_Invoice__c) controller.getRecord();
                invoiceType = si.Invoice_Type__c;
                pageTitle = Label.Clone_of + ' ' +Schema.Supplier_Invoice__c.getSObjectType().getDescribe().getLabel();
                si.Status__c = 'Incomplete';
                displayExceptions = false;
            }else{
                checkUserErrorsOnSI();  
            }
        }else{
            invoiceType = 'Invoice';
            si = new Supplier_Invoice__c();
            si.Company__c = CompanyService.getDefaultCompanyId();
            Map<Id, Company__c> companyMap = CompanyService.getCompanyMap(new Set<Id>{si.Company__c}); //KNDY-14504
            
            si.Company__r = companyMap.get(si.Company__c);
            si.Invoice_Type__c = invoiceType;
            si.Status__c = 'Incomplete';
	        si.Currency__r = CompanyService.defaultTransactionCurrencyRec(si.Company__c);
	        if(si.Currency__r != null)
	        	si.Currency__c = CompanyService.defaultTransactionCurrencyRec(si.Company__c).id;

            pageTitle = Schema.Supplier_Invoice__c.getSObjectType().getDescribe().getLabel();
            pageSubTitle = Label.New_Supplier_Invoice;  
            displayExceptions = false;
        }
        
        HasTax = taxSvc.taxServiceConfigured(Supplier_Invoice__c.getSobjectType().getDescribe().getLocalName(), si) ; 
        
        List<String> segmentsList = new List<String>(); 
        try{ 
	        segmentsList = segmentSvc.segmentNameListForAP(true, 'Invoice');
        } catch(Exception ex){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Cannot_load_segment_data + ' ' + MessageUtil.toFriendlyErrorMessage(ex.getMessage()))); //ToDo this msg is not showing up on SI UI
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
        }  
        Set<String> invoiceLinesAdditionalFields = new Set<String>();

        invoiceLinesAdditionalFields.addAll(new set<string>{'id','Name','Has_Exceptions__c','Item__r.Source__c','Purchase_Order_Line__r.Company__c','Purchase_Order_Line__r.Order_Quantity__c','Purchase_Order_Line__r.Delivery_Facility__c','Purchase_Order_Line__r.Need_Date__c','Purchase_Order_Line__r.Item__c','Item__r.Name',
                            'Supplier_Invoice__r.Name', 'Supplier_Invoice__r.Supplier__c', 'Supplier_Invoice__r.Supplier_Invoice__c', 'Supplier_Invoice__r.Invoice_Type__c', 'Supplier_Invoice__r.Total_Extended_Price__c','Supplier_Invoice__r.Status__c','Supplier_Invoice__r.Total_Invoice__c','Accounting_Segment__c',
                            'Line_Type__c', 'Item__r.Class__c','Purchase_Order_Line__r.Name', 'Purchase_Order_Line__r.Invoice_Status__c', 'Item__r.Class__r.Type__c'});
        invoiceLinesAdditionalFields.addAll(segmentsList);
        //KNDY-18171
        if(HasTax){
        	list<FieldInfo> taxFields = taxSvc.getDisplayFieldSet(Supplier_Invoice__c.getSobjectType());
        	supplierInvoiceLineTaxFieldList = taxFields!=null?JSON.serialize(taxFields):null;
        	if(taxFields != null){
        		for(FieldInfo taxField: taxFields){
        			invoiceLinesAdditionalFields.add(taxField.field);
        		}
        	}
        }
        system.debug(logginglevel.DEBUG,'***supplierInvoiceLineTaxFieldList***'+supplierInvoiceLineTaxFieldList);
        
        segmentFieldsList = new List<String>();
        for (Integer i = 0; i < segmentsList.size(); i++) {
            invoiceLinesAdditionalFields.add(segmentsList[i].replace('__c', '__r.Name'));
            segmentFieldsList.add(segmentsList[i]);
    		segmentFieldsList.add(segmentsList[i].replace('__c' ,'__r')); 

        }
        
        // Supplier Invoice Lines Grid config
        supplierInvoiceLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        supplierInvoiceLinesConfig.uniqueId = 'InvoiceLinesGrid';
        supplierInvoiceLinesConfig.title = invoiceType + ' Lines';
        supplierInvoiceLinesConfig.parentRecord = si;
        supplierInvoiceLinesConfig.objectName = 'Supplier_Invoice_Line__c';  
        supplierInvoiceLinesConfig.parentField = 'Supplier_Invoice__c';
        supplierInvoiceLinesConfig.fieldset = 'Supplier_Invoice_Line';
        supplierInvoiceLinesConfig.buttons = 'create, cancel, delete, clone, columnmenu, search';
        supplierInvoiceLinesConfig.additionalFields = String.join(new List<String>(invoiceLinesAdditionalFields), ',');  
                
        // Segment Lines Grid config
        segmentLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        segmentLinesConfig.uniqueId = 'SegmentLinesGrid';
        segmentLinesConfig.objectName = 'Accounting_Default__c'; 
    	
    	// Purchase Order Lines Grid config
        purchaseOrderLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        purchaseOrderLinesConfig.uniqueId = 'POLinesGrid';
        purchaseOrderLinesConfig.title = 'Purchase Order Lines';
        purchaseOrderLinesConfig.objectName = 'Purchase_Order_Line__c';  
        purchaseOrderLinesConfig.fieldset = 'Supplier_Invoice_New';
        purchaseOrderLinesConfig.buttons = 'columnmenu, search';
        purchaseOrderLinesConfig.additionalFields = String.join(new List<String>(purchaseOrderLinesAdditionalFields()), ',');  
  
        // KNDY-7636 Exceptions Grid config
        exceptionTasksExtNew = new ExceptionTasksExtNew();
        exceptionTasksExtNew.parent = si;
        exceptionsConfig = exceptionTasksExtNew.config;
    }
    
    public List<Grid_Views_Config__c> getCustomViewList() {
    	if (customViewList == null) { //KNDY-15488
        customViewList =  KSE.getGridViews('SupplierInvoiceLinesGrid');
    	}
    	
    	return customViewList;
    }
    
     public PageReference checkUserErrorsOnSI(){
        if (si == null) {
            return null;
        }else {
            if(si.Status__c == SupplierInvoiceService.STATUS_VOID || si.Status__c == SupplierInvoiceService.STATUS_CANCELLED) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Cannot_edit_CILines_VoidCancel_CI));
                return null;
            }
        }
        return null;
    }
    
    public String getCustomViews() {
    	List<SelectListItem> viewList = new List<SelectListItem>();
        List<Grid_Views_Config__c> customViewList = getCustomViewList();
        // use for preventing duplicate field set values in grid views
        Set<String> existingViews = new Set<String>();

        for(Grid_Views_Config__c gvConfig: customViewList){
            if (!existingViews.contains(gvConfig.Fieldset_Name__c.toLowerCase())){
                viewList.add(new SelectListItem(gvConfig.Fieldset_Name__c, gvConfig.View_Name__c));
                existingViews.add(gvConfig.Fieldset_Name__c.toLowerCase());
            }
        }

        if (customViewList.isEmpty() || customViewList[0].View_Dropdown_Index__c == 0){
            viewList.add(new SelectListItem('', Label.All_Fields));
        } else {
            viewList.add(0,new SelectListItem('', Label.All_Fields));
        }
        return JSON.serialize(viewList);
    }
    
    public String getCustomViewFields() {
    	Map<String, List<String>> customViewFieldsMap = new Map<String, List<String>>();
    	List<Grid_Views_Config__c> customViewList = getCustomViewList();
    	
    	if (customViewList.size() > 0) {
        	for (Integer i = 0; i < customViewList.size(); i++){
				List<String> fieldNames = new List<String>();
        					        
        		try {
	        		List<FieldInfo> fieldList = FieldInfo.fetchJsonFieldInfos('Supplier_Invoice_Line__c', customViewList[i].Fieldset_Name__c);
			        
			        for(Integer j = 0; j < fieldList.size(); j++){
			        	if (fieldList[j].field != 'Id') {
			            	fieldNames.add('invoiceLine.' + fieldList[j].field);
			        	}
			        }
		        }
		        catch (FieldInfo.EmptyFieldSetMemberException e) {
		            
		        }
		        
		        customViewFieldsMap.put(customViewList[i].Fieldset_Name__c, fieldNames);
        	}
        }
        
        return JSON.serialize(customViewFieldsMap);
    }
    
    public static Set<String> purchaseOrderLinesAdditionalFields() {
    	Set<String> poLinesAdditionalFields = new Set<String>();
        Set<String> accSegFieldsSet = new Set<String>();
        SegmentService sgService = new SegmentService();
        poLinesAdditionalFields.addAll( new set<string>{'id','Company__c','Delivery_Facility__c','Need_Date__c','Name','Item__r.Name','Item__r.Description__c','Item__r.Source__c','Item__r.Class__c','Item__r.Class__r.Type__c',
            'Purchase_Order__c', 'Purchase_Order__r.Name', 'Purchase_Order__r.Currency__c', 'Description__c','Item__c','Order_Quantity__c', 'Purchase_UOM__c', 'Unit_Price__c','Accounting_Segment__c','Invoice_Matching__c','Quantity_Received__c','Invoice_Status__c'});
        
        List<String> accSegFieldsList = sgService.segmentNameListForAP(true, 'Invoice');
        for(String segField: accSegFieldsList){
            poLinesAdditionalFields.add(segField);
    		poLinesAdditionalFields.add(segField.replace('__c' ,'__r.Name')); 
        }
       
        for (String fieldName: util.getFieldsFromFieldSetString(Supplier_Invoice_Line__c.sObjectType , 'Supplier_Invoice_Line')) {
        	if (fieldName.contains('Purchase_Order_Line__r.')) {
				poLinesAdditionalFields.add(fieldName.split('\\.')[1]);
        	}
    	}
    	
    	return util.removeNSfromSetString(poLinesAdditionalFields); //strip out the NS
    }
    
    public string getSupplierInvoiceJson() {
        return JSON.serialize(si);  
    }
    
    public string getSupplierInvoiceHeaderFieldList() {
        String supplierInvoiceHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        
        // get the supplier invoice header field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Supplier_Invoice__c', 'Supplier_Invoice_Header');
        List<FieldInfo> finalizeFieldInfoList = FieldInfo.fetchJsonFieldInfos('Supplier_Invoice__c', 'Finalize');
        List<FieldInfo> pymtIssuedFieldInfoList = FieldInfo.fetchJsonFieldInfos('Supplier_Invoice__c', 'Payment_Issued');
        map<string,FieldInfo> mapPaymentIssuedFieldInfo = new map<string,FieldInfo>();
        if(!pymtIssuedFieldInfoList.isEmpty()){
        	for(FieldInfo fi: pymtIssuedFieldInfoList){
        		mapPaymentIssuedFieldInfo.put(fi.field,fi);
        	}
        }
        Set<String> finalizedFields = new Set<String>();
        
        for(Integer i = 0; i < finalizeFieldInfoList.size(); i++){
            finalizedFields.add(finalizeFieldInfoList[i].field);
        }

        // check the void/Cancelled status and set the fieldset
        System.debug(logginglevel.error,'Inside getSupplierInvoiceHeaderFieldList--> '+si.status__c +' '+si.id );  
        if(!String.isBlank(si.id) && (si.status__c=='Cancelled' || si.Void__c==true ))  {
              for(FieldInfo f:fieldInfoList ){
                    f.editable=false;
              }
              fieldInfoList.remove(0); // Remove Id field from the list
              return  JSON.serialize(fieldInfoList);
        }
        
        for (Integer i = 0; i < fieldInfoList.size(); i++){
            if ( fieldInfoList[i].field == 'Status__c' || fieldInfoList[i].field == 'Finalized__c') {  
                fieldInfoList[i].editable = false;
            }
            
            if (si.Finalized__c && (si.status__c == 'Approved' || si.status__c == 'Closed') && finalizedFields.contains(fieldInfoList[i].field)){  
               fieldInfoList[i].editable = false;
        }
        
            if(si.Finalized__c && (si.status__c == 'Approved' || si.status__c == 'Closed') && mapPaymentIssuedFieldInfo.containsKey(fieldInfoList[i].field)){ 
                if(si.Invoice_Type__c == 'Invoice'){ 
                    fieldInfoList[i].editable = (si.Invoice_Amount__c != si.Balance_Due__c) ? 
                    							false :
                    							(mapPaymentIssuedFieldInfo.get(fieldInfoList[i].field).editable);  // false - Payment is found, true - no payment found
                }
                if(si.Invoice_Type__c == 'Credit Memo'){   
                    fieldInfoList[i].editable = (si.Credit_Memo_Amount__c != si.Credit_Memo_Balance__c) ? 
                    							false : 
                    							(mapPaymentIssuedFieldInfo.get(fieldInfoList[i].field).editable); // false - Payment is found, true - no payment found
                }
            }
        }
        
		fieldInfoList.remove(0); // Remove Id field from the list
        
        supplierInvoiceHeaderFieldList = JSON.serialize(fieldInfoList);
        
        return supplierInvoiceHeaderFieldList;
    }
    
    public string getSupplierInvoiceAddlHeaderFieldList() {
        String supplierInvoiceAddlHeaderFieldList = '';
        List<FieldInfo> result = new List<FieldInfo>();
        Set<String> headerFields = new Set<String>();
        List<FieldInfo> headerList = (List<FieldInfo>) JSON.deserialize(getSupplierInvoiceHeaderFieldList(), List<FieldInfo>.class);
        
        for(Integer i = 0; i < headerList.size(); i++){
            headerFields.add(headerList[i].field);
        }
        
        try {
            // get the supplier invoice header field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Supplier_Invoice__c', 'Supplier_Invoice_Additional_Info_Header');
            
            fieldInfoList.remove(0);    // Remove Id field from the list
            if(!String.isBlank(si.id) && (si.status__c=='Cancelled' || si.Void__c==true ))  {
	              for(FieldInfo f:fieldInfoList ){
	                    f.editable=false;
	              }
	              return  JSON.serialize(fieldInfoList);
            }
            
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                if (!headerFields.contains(fieldInfoList[i].field)) {
                	if (fieldInfoList[i].field == 'Status__c' || fieldInfoList[i].field == 'Finalized__c') {  
                		fieldInfoList[i].editable = false;
                	}
                	
                    result.add(fieldInfoList[i]);
                }
            }
            
            supplierInvoiceAddlHeaderFieldList = (result.size() > 0) ? JSON.serialize(result) : '';
        }
        catch (FieldInfo.EmptyFieldSetMemberException e) {
            supplierInvoiceAddlHeaderFieldList = '';
        }
        
        return supplierInvoiceAddlHeaderFieldList;
    }
    
    public string getVATFieldList() {
        String VATFieldList = '';
        List<FieldInfo> result = new List<FieldInfo>();
        Set<String> uiFields = new Set<String>();
        List<FieldInfo> uiHdrFieldList = (List<FieldInfo>) JSON.deserialize(getSupplierInvoiceHeaderFieldList(), List<FieldInfo>.class);
        List<FieldInfo> uiAddlHdrFieldList = (List<FieldInfo>) JSON.deserialize(getSupplierInvoiceAddlHeaderFieldList(), List<FieldInfo>.class);
        
        for(Integer i = 0; i < uiHdrFieldList.size(); i++){
            uiFields.add(uiHdrFieldList[i].field);
        }
        for(Integer i = 0; i < uiAddlHdrFieldList.size(); i++){
            uiFields.add(uiAddlHdrFieldList[i].field);
        }
        try {
            // get the supplier invoice VAT fields
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Supplier_Invoice__c', 'VAT');
            system.debug(LoggingLevel.Error, '>>> fieldInfoList: ' + fieldInfoList);
            fieldInfoList.remove(0);    // Remove Id field from the list
            system.debug(LoggingLevel.Error, '>>> 2 fieldInfoList: ' + fieldInfoList);
            if (fieldInfoList != null && fieldInfoList.size() > 0){
                for(Integer i = 0; i < fieldInfoList.size(); i++) {
                    if (!uiFields.contains(fieldInfoList[i].field)) {
                        result.add(fieldInfoList[i]);
                    }
                }
                VATFieldList = (result.size() > 0) ? JSON.serialize(result) : '';
            }
            else{
                VATFieldList = '';
            }
        }
        catch (FieldInfo.EmptyFieldSetMemberException e) {
            VATFieldList = '';
        }
        
        return VATFieldList;
    }
    
    public string getSupplierInvoiceLinesConfigJson() {
        String configStr = JSON.serialize(this.supplierInvoiceLinesConfig);
          
        return configStr;
    }
    
    public string getSupplierInvoiceLinesFieldList() {
        if (supplierInvoiceLinesFieldList == null && supplierInvoiceLinesConfig != null) {
            // get the supplier invoice lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(supplierInvoiceLinesConfig.objectName, supplierInvoiceLinesConfig.fieldset);
            List<FieldInfo> segmentList = (List<FieldInfo>) JSON.deserialize(getSegmentLinesFieldList(), List<FieldInfo>.class);
            List<FieldInfo> finalizeFieldInfoList = FieldInfo.fetchJsonFieldInfos(supplierInvoiceLinesConfig.objectName, 'Finalize');
            
            Set<String> finalizedFields = new Set<String>();
            for(Integer i = 0; i < finalizeFieldInfoList.size(); i++){
               finalizedFields.add('invoiceLine.' + finalizeFieldInfoList[i].field);
            }
            
            // set the wrapper class prefix
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                if (fieldInfoList[i].field == 'Extended_Price__c') {
                	fieldInfoList[i].title = 'Amount';
                    fieldInfoList[i].field = 'invoicedAmount';
                }
                else {
                	if (fieldInfoList[i].field == 'Invoice_Quantity__c') {
	                	fieldInfoList[i].title = 'Quantity';
                	}
	            	else if (fieldInfoList[i].field == 'Unit_Price__c') {//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price.
	            		fieldInfoList[i].title = 'Unit Price';
	            	}
	            	else if(fieldInfoList[i].field.contains('Purchase_Order_Line__r') || fieldInfoList[i].field.contains('Purchase_Order__r')){
	            	    fieldInfoList[i].editable = false; 
	            	}

                	fieldInfoList[i].field = 'invoiceLine.' + fieldInfoList[i].field; 
                }               
            }
            
            for(Integer i = 0; i < segmentList.size(); i++){
                FieldInfo segmentField = segmentList[i];
                if(segmentField.field.equalsIgnorecase('Company__c') ) { segmentField.hidden =true;}//KNDY-15943
                segmentField.field = 'segments.' + segmentField.field;
                fieldInfoList.add(segmentField);
            }
            
            if(taxSvc.taxServiceConfigured(Supplier_Invoice__c.getSobjectType().getDescribe().getLocalName(), si) == true){
                List<FieldInfo> taxFields = taxSvc.getDisplayFieldSet(Supplier_Invoice__c.getSobjectType());

                if(taxFields != null){
                    for( FieldInfo tx : taxFields ){
                        boolean found = false;
                        tx.field = 'invoiceLine.' + tx.field;
                        for(FieldInfo f : fieldInfoList){
                            if(tx.field == f.field){
                                found = true;
                                f.editable = tx.editable;  
                            }else{ //KNDY-18171
                            	tx.editable = true;
                            }
                        }
                        if(found == false){
                            fieldInfoList.add(tx);
                        }
                    }
                }
            }
             
            if ((si.Finalized__c || si.status__c == 'Approved')  && !(ApexPages.currentPage().getParameters().containsKey('clone') && ApexPages.currentPage().getParameters().get('clone') == '1')){
                for(Integer i = 0; i < fieldInfoList.size(); i++){  
		            if(finalizedFields.contains(fieldInfoList[i].field)){
		                fieldInfoList[i].editable = false;
		            }else if(fieldInfoList[i].field == 'invoiceLine.' + 'Track_as_Asset__c'){ //since this field is not in the finalized fieldset
		                fieldInfoList[i].editable = false; 
		            }
                }    
            }    
            
            //KNDY-7636 Add error column to the grid
            //KNDY-10372 fielInfo type is RowInfo
            FieldInfo fi = new FieldInfo('errors', 'Errors', 'RowInfo');
            fieldInfoList.add(0, fi);
            
            if(!String.isBlank(si.id) && (si.status__c == 'Cancelled' || si.Void__c == true ))  {  
                  for(FieldInfo f:fieldInfoList ){
                        f.editable=false;
                  }
                return  JSON.serialize(fieldInfoList);
            } 
            
            supplierInvoiceLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return supplierInvoiceLinesFieldList;
    }
   
    public string getExceptionsFieldList() { // KNDY-7636
        if (!String.isBlank(si.Id) &&  exceptionsFieldList == null && exceptionsConfig != null) {
            exceptionsFieldList = exceptionTasksExtNew.getFieldList();
            List<FieldInfo> fieldInfoList = (List<FieldInfo>) JSON.deserialize(exceptionsFieldList, List<FieldInfo>.class);
            FieldInfo fi = new FieldInfo('name', 'Name', 'RowInfo');
            fieldInfoList.add(0, fi);
            exceptionsFieldList = JSON.serialize(fieldInfoList);
        }       
        return exceptionsFieldList;
    }
    
    // called on page load
    public String getWhatIdNameMapJson() {    	
        return exceptionTasksExtNew.getWhatIdNameMapJson();    
    }   

    @RemoteAction
    public static DataSourceResult getTaskRelatedList(GridRelatedListController.GridRelatedListConfig config) { // KNDY-7636
        DataSourceResult dsr = GridRelatedListController.getTaskRelatedList(config);
        return dsr;        
    }
    
    public string getSegmentLinesFieldList() {
        if (segmentLinesFieldList == null && segmentLinesConfig != null) {
            list<String> segments = new list<String>();
            
            try{
            	segments.addAll(segmentSvc.segmentNameListForAP(false, 'Invoice')) ;
            }catch(Exception ex){
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Cannot_load_segment_data + ' ' + MessageUtil.toFriendlyErrorMessage(ex.getMessage()))); //ToDo this msg is not showing up on SI UI
                system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            }
    
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(segmentLinesConfig.objectName, segments);
            
            segmentLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return segmentLinesFieldList;
    }
    
    public string getPurchaseOrderLinesConfigJson() {
        String configStr = JSON.serialize(this.purchaseOrderLinesConfig);
          
        return configStr;
    }
    
    public string getPurchaseOrderLinesFieldList() {
        if (purchaseOrderLinesFieldList == null && purchaseOrderLinesConfig != null) {
        	// get the purchase order lines field info list that are required for the copy po lines
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(purchaseOrderLinesConfig.objectName, purchaseOrderLinesConfig.fieldset);
            
            // set the wrapper class prefix
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	if (fieldInfoList[i].field == 'Name') {
            		fieldInfoList[i].field = 'Purchase_Order_Line__c';
            		fieldInfoList[i].fieldtype = 'reference';
                }else{ 
                    fieldInfoList[i].field = 'Purchase_Order_Line__r.' + fieldInfoList[i].field; 
            	}
                fieldInfoList[i].field = 'invoiceLine.' + fieldInfoList[i].field;  
                fieldInfoList[i].editable = false;              
                fieldInfoList[i].filterable = true;     
            }
            purchaseOrderLinesFieldList = String.escapeSingleQuotes(JSON.serialize(fieldInfoList));
        }
        
        return purchaseOrderLinesFieldList;
    }

    public string getExceptionsConfigJson() { // KNDY-7636
        String configStr = JSON.serialize(this.exceptionsConfig);          
        return configStr;
    }
    @RemoteAction
    public static JsonResult getCompanyDetails(String companyId) {
    	List<Company__c> companies = new List<Company__c>();
    	string whereClause = 'Id  = :companyId LIMIT 1';
    	
    	SOQLUtil soql = new SOQLUtil('Company__c');
	    soql.addFields(new Set<String>{'Id','Default_Transaction_Currency__c','Default_Transaction_Currency__r.name',
	    								'Name','City__c','Street__c','State__c','Zip_Code__c','Country__c'});
	    soql.setWhereClause(whereClause);
	    
    	companies = Database.query(soql.getQuery());
    	return new JsonResult(companies, companies.size());
    }
       
     public class PaymentTermsWrapper {
        public DateTime paymentDueOverrideDate{ get;set; }
        public Payment_Term__c paymentTerm{ get;set; }
        
        public PaymentTermsWrapper(DateTime paymentDueOverrideDate, Payment_Term__c paymentTerm) {
            this.paymentDueOverrideDate = paymentDueOverrideDate;
            this.paymentTerm = paymentTerm;
        }
    }   
    
    
    @RemoteAction
    public static JsonResult getPaymentTermDetailsAndSetDueDates(String paymentTermId, String dateInvoiced ) {
        JsonResult result = new JsonResult();
        List<PaymentTermsWrapper> pymtTermDetailsList = new List<PaymentTermsWrapper>();
        try{
            Payment_Term__c paymentTermDetails = new Payment_Term__c();
        SOQLUtil soql = new SOQLUtil('Payment_Term__c', false);
        soql.addFields(new set<string>{
            'Id','Type__c','Due_Days__c','Day_of_month__c','Cut_off_Day__c','Months_Ahead__c','Discount_Days__c'
        });
	        soql.setWhereClause('id = :paymentTermId Limit 1');
	        paymentTermDetails =  Database.query(soql.getQuery());
	        system.debug(logginglevel.error,'paymentTermDetails--->> '+paymentTermDetails);
	        DateTime dtValue = DateTime.parse(dateInvoiced);
	        system.debug(logginglevel.error,'dtValue--->> '+dtValue);
	        
	        Date paymentDueOverrideDate = KSE.getDueDate (dtValue, paymentTermDetails);
	        system.debug(logginglevel.error,'paymentDueOverrideDate--->> '+paymentDueOverrideDate);
	        pymtTermDetailsList.add(new PaymentTermsWrapper(paymentDueOverrideDate, paymentTermDetails));
	        result.records = pymtTermDetailsList;
	    } catch(Exception e) {
	        result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
       
    @RemoteAction
    public static JsonResult getSupplierInvoiceDetails(Id supplierInvoiceId, String clone) { 
        String objectName = 'Supplier_Invoice__c';
        String headerFieldset = 'Supplier_Invoice_Header';  
        String addlHeaderFieldset = 'Supplier_Invoice_Additional_Info_Header';  

        String VATFieldset = 'VAT' ;
        Set<String> addlFields = new Set<String> { 'name', 'Company__c', 'Company__r.City__c', 'Company__r.Street__c', 'Company__r.State__c', 'Company__r.Country__c', 'Company__r.Zip_Code__c', 'Finalized__c', 'Currency__c', 'Exception__c', 'Supplier__r.Status__c', 'Has_Exceptions__c', 'Has_Line_Exceptions__c', 'Void__c' , 'Invoice_Amount__c', 'Balance_Due__c', 'Credit_Memo_Amount__c', 'Credit_Memo_Balance__c' };

        string whereClause = 'Id  = :supplierInvoiceId LIMIT 1';
        
		SOQLUtil soql = new SOQLUtil(objectName);
	    soql.addFields(headerFieldset);
	    soql.addFields(addlHeaderFieldset);
	    soql.addFields(addlFields);
	    soql.addFields(VATFieldset);
	    soql.setWhereClause(whereClause);
	    
        List<Supplier_Invoice__c> si = Database.query(soql.getQuery());
        Company__c co = si[0].Company__r;
        if ( clone != null && clone == '1'){ // KNDY-7558
            // Copy the SI
            Supplier_Invoice__c siClone = si[0].clone(false, true);
            // reset fields
            siClone.Status__c = 'Incomplete';
            siClone.Supplier_Invoice__c = ''; // Invoice Number
            siClone.Date_Invoiced__c = DateTime.now();
            siClone.Finalized__c = false;
            siClone.Finalized_Hidden__c = false;
            siClone.Finalized_Date__c = null;
            siClone.Exceptions_Count__c = 0;
            siClone.Void__c = false;
            si.clear();
            si.add(siClone);	
        }
      
        return new JsonResult(si, si.size());
    }
    
    @RemoteAction 
    public static JsonResult getPaymentDefaults(String supplierId, String companyId) {
        List<Supplier__c> suppliers = new List<Supplier__c>();
        String whereClause = (supplierId != null) ? 'Id = :supplierId LIMIT 1': '( Company__c = :companyId or Company__c = null )  and Type__c = \'Remit-To\' and Status__c = \'Active\'';
        
        SOQLUtil soql = new SOQLUtil('Supplier__c');
        //SI Refactoring : Move the Fields to FieldSet as part of the code refactoring JIRA - KKK
	    soql.addFields(new Set<String>{'Name','Always_Take_Discount__c', 'Payment_Term__c', 'Payment_Term__r.Name', 'Payment_Method_G__c', 'Currency__c', 'Currency__r.name', 
	    								'Address__c', 'Address__r.Name', 'Street__c', 'City__c', 'State__c', 'Country__c', 'Zip_Code__c'});
	    soql.setWhereClause(whereClause);
        
        suppliers = Database.query(soql.getQuery());
        
        return new JsonResult(suppliers, suppliers.size());
    }
    
    @RemoteAction
    public static JsonResult getPurchaseOrderDetails(Id poId){
        List<Purchase_Order__c> purchaseOrders = new List<Purchase_Order__c>();
        
        String whereClause = 'Id = :poId LIMIT 1';
        
	    SOQLUtil soql = new SOQLUtil('Purchase_Order__c');
	    //SI Refactoring : Move the Fields to FieldSet as part of the code refactoring JIRA - KKK
	    soql.addFields(new Set<String>{'Company__c', 'Company__r.Name', 'Remit_To_Supplier__c', 'Remit_To_Supplier__r.Always_Take_Discount__c', 
	    								'Remit_To_Supplier__r.Name', 'Payment_Term__c', 'Payment_Term__r.Name', 'Currency__c', 
	    								'Remit_To_Supplier__r.Payment_Method_G__c', 'Remit_To_Supplier__r.Address__c', 'Remit_To_Supplier__r.Address__r.Name', 
	    								'Remit_To_Supplier__r.Street__c', 'Remit_To_Supplier__r.City__c', 'Remit_To_Supplier__r.State__c', 
	    								'Remit_To_Supplier__r.Country__c', 'Remit_To_Supplier__r.Zip_Code__c'});
	    soql.setWhereClause(whereClause);
	    
        purchaseOrders = Database.query(soql.getQuery());
        
        return new JsonResult(purchaseOrders, purchaseOrders.size());
    }
    
    // Display all lines for viewing an SI
    // For a clone, display valid si lines only
    @RemoteAction 
    public static JsonResult getInvoiceLines(GridRelatedListController.GridRelatedListConfig config, String clone) {
        list<InvoiceLineWrapper> result = new list<InvoiceLineWrapper>();
        Id parentId = (config.parentRecord != null && String.isNotBlank(config.parentRecord.Id)) ? config.parentRecord.Id : '';
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        set<string> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
        String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';
        Boolean hasLines = false; //KNDY-12258
        String invoiceType = ((Supplier_Invoice__c)config.parentRecord).Invoice_Type__c;//KNDY-12258
        
        string whereClause = parentfield + ' = :parentId';
        
        if(String.isNotBlank(config.sortField)){
            whereClause += ' ORDER BY ' + config.sortField;
            if(String.isNotBlank(config.sortOrder)){
                whereClause += ' ' + config.sortOrder;
            }
        }
        
        if (String.isNotBlank(config.namespace)) {
            util.namespace = config.namespace;
        }
        
        SOQLUtil soql = new SOQLUtil(config.objectName);
	    soql.addFields(fieldset);
	    soql.addFields(addlFields);
	    soql.setWhereClause(whereClause);
	    
        List<Supplier_Invoice_Line__c> invoiceLinesList = Database.query(soql.getQuery());   
        if (invoiceLinesList.size() > 0){// KNDY-7558
            hasLines = true;
        }
        if ( clone != null && clone == '1'){ // KNDY-7558
            List<Supplier_Invoice_Line__c> clonedInvoiceLines = new List<Supplier_Invoice_Line__c>();
            for (Supplier_Invoice_Line__c sil : invoiceLinesList){
                if (invoiceType == 'Invoice' && sil.Purchase_Order_Line__c != null){//KNDY-12258
                    if (sil.Purchase_Order_Line__r.Invoice_Status__c == 'Closed for Invoicing'){
                        continue; 
                    }
                }
                // Copy the line
                Supplier_Invoice_Line__c cloneSIL = sil.clone(false,true);
                // Reset field values
                cloneSIL.Name = '';
                cloneSIL.Matched__c = false;
                cloneSIL.Quantity_Received__c = 0;
                cloneSIL.Exceptions_Count__c = 0;
                if(sil.Accounting_Segment__c != null ){
                    Accounting_Default__c accountingDefault = new Accounting_Default__c();
                    cloneSIL.Accounting_Segment__c = null;
                    if (sil.Accounting_Segment__r != null){
	                    accountingDefault = sil.Accounting_Segment__r.clone(false,true);
	                    cloneSIL.Accounting_Segment__r = accountingDefault;
                    }
                }
                clonedInvoiceLines.add(cloneSIL);
            }
            invoiceLinesList.clear();
            invoiceLinesList.addAll(clonedInvoiceLines);
        } 

        system.debug(Logginglevel.info, result);


        for (Integer i = 0; i< invoiceLinesList.size() ; i++) {
            InvoiceLineWrapper lineWrapper = new InvoiceLineWrapper(invoiceLinesList[i]);
            // KNDY-7558 This will create a new Accounting Default Record for clones
            if ( clone != null && clone == '1' && lineWrapper.invoiceLine.Accounting_Segment__r != null){ 
                lineWrapper.segments = lineWrapper.invoiceLine.Accounting_Segment__r; 
            }
            result.add(lineWrapper);
        }

        system.debug(Logginglevel.error, result);
        JsonResult jsonRes = new JsonResult(result, result.size());
        
        
        // Displays error message only if silines exist and all silines are associated with closed for invoicing pols
        if (clone == '1' && hasLines && result.size() == 0){
            jsonRes.addMessage(Label.All_invoice_lines_cannot_be_cloned, ApexPages.Severity.INFO);
        }
        return jsonRes;
    }

    @ReadOnly @RemoteAction 
    public static JsonResult getInvoiceLinesByPurchaseOrderId(String poIds, String invType) {

        List<InvoiceLineWrapper> result = new List<InvoiceLineWrapper>();
        List<Purchase_Order_Line__c> polList = new List< Purchase_Order_Line__c >();

        System.debug(logginglevel.error,'poIds---->>'+poIds);
        //KNDY-18171
        boolean taxEnabled = taxSvc.taxServiceConfigured(Supplier_Invoice__c.getSobjectType().getDescribe().getLocalName(),new Supplier_Invoice__c());
        list<FieldInfo> taxFields = new list<FieldInfo>();
        List<Id> porderIds = (List<Id>)JSON.deserialize(poIds, List<Id>.class);
        if( (porderIds != null && porderIds.size() > 0)){ 
        
            String whereClause = 'Status__c != \'Cancelled\' AND Purchase_Order__c in :porderIds';  
        	// Get POlines that are open for invoicing
            if (invType == 'Invoice' || invType == 'Prepayment') {
                whereClause += ' AND Invoice_Status__c = \'Open for Invoicing\'';
            }
            
        	SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
        	soql.addFields('Supplier_Invoice_New');
            soql.addFields(purchaseOrderLinesAdditionalFields());
            //KNDY-18171
            if(taxEnabled){
            	taxFields = taxSvc.getDisplayFieldSet(Supplier_Invoice__c.getSobjectType());
            	if(taxFields != null){
		            soql.addFields(new set<string>{'Purchase_Order__r.Type__c','Delivery_Facility__r.City_Name__c',
		            'Quantity_Matched__c', 'Order_Quantity__c', 'Quantity_Received__c','Invoice_Matching__c', //KNDY-19417
		            'Delivery_Facility__r.Country_Name__c','Delivery_Facility__r.Street_Address__c','Delivery_Facility__r.State_Province_Name__c',
		            'Delivery_Facility__r.Zip_Postal_Code__c','Purchase_Order__r.Deliver_to_Customer__r.City__c','Purchase_Order__r.Deliver_to_Customer__r.Country__c',
		            'Purchase_Order__r.Deliver_to_Customer__r.State__c','Purchase_Order__r.Deliver_to_Customer__r.Street__c',
		            'Purchase_Order__r.Deliver_to_Customer__r.Zip_Code__c','Purchase_Order__r.Supplier__r.City__c',
		            'Purchase_Order__r.Supplier__r.Country__c','Purchase_Order__r.Supplier__r.State__c','Purchase_Order__r.Supplier__r.Street__c',
		            'Purchase_Order__r.Supplier__r.Zip_Code__c'});
            	}
            }
        	soql.setWhereClause(whereClause);
        	
        	System.debug(logginglevel.error,soql.getQuery());
		    polList = Database.query(soql.getQuery()); 
        	        	
        }

		System.debug(logginglevel.error,'polList--->'+polList);  
        if(polList != null && polList.size() == 0 ){ 
            JsonResult jsonRes = new JsonResult(new List<InvoiceLineWrapper>(), result.size());
            jsonRes.addMessage(Label.The_purchase_order_has_no_lines, ApexPages.Severity.INFO);
            return jsonRes;
        }

        System.debug(logginglevel.error,'polList--->'+polList);
        List<Supplier_Invoice_Line__c> rilNewList = new List<Supplier_Invoice_Line__c>();
        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        List<Date> dateList = new List<Date>();
        Set<Id> polIds = new Set<Id>();
        
        if (polList.size() > 0) {
        	for(Purchase_Order_Line__c poLine : polList) {
        		itemIds.add(poLine.Item__c);
        		facilityIds.add(poLine.Delivery_Facility__c);        
        		dateList.add(poLine.Need_Date__c);		
        		polIds.add(poLine.Id);		
        	}
        	
        	ItemService.preCacheCostRecords(dateList, itemIds, facilityIds);
        	
            for (Purchase_Order_Line__c poLine: polList) {
                Supplier_Invoice_Line__c rilNew = new Supplier_Invoice_Line__c();
                
                rilNew.Purchase_Order__c = poLine.Purchase_Order__c;
                rilNew.Purchase_Order__r = poLine.Purchase_Order__r;
                
                rilNew.Purchase_Order_Line__c = poLine.id;
                rilNew.Purchase_Order_Line__r = poLine;
                
                rilNew.Item__c = poLine.Item__c;
                rilNew.Item__r = poLine.Item__r;
                
                rilNew.Purchase_UOM__c = poLine.Purchase_UOM__c; //KNDY-10605
                rilNew.Purchase_UOM__r = poLine.Purchase_UOM__r; //KNDY-10605
                
                if (poLine.Item__r.Source__c == 'Miscellaneous')
                    rilNew.Miscellaneous__c = true;
                else
                    rilNew.Miscellaneous__c = false;
                
                rilNew.Description__c = poLine.Description__c;
                
                rilNew.Invoice_Quantity__c = 0.0;
                if (invType == 'Invoice'){ //KNDY-19417
                    Decimal silQty = 0.0;
                    if(poLine.Invoice_Matching__c != null && poLine.Invoice_Matching__c == 'Two Way' ){
                        silQty = poLine.Order_Quantity__c - poLine.Quantity_Matched__c;
                    }else{
                        silQty = poLine.Quantity_Received__c - poLine.Quantity_Matched__c;
                    }
                    if(silQty > 0){
                        rilNew.Invoice_Quantity__c = silQty;
                    }
                    System.debug(logginglevel.error,'rilNew.Invoice_Quantity__c--'+poLine.Invoice_Matching__c + ' -->'+rilNew.Invoice_Quantity__c);
                }

                rilNew.Unit_Price__c = poLine.Unit_Price__c;//KNDY-14371
                
                //KNDY-12463
                rilNew.Accounting_Segment__c = poLine.Accounting_Segment__c; 
                rilNew.Accounting_Segment__r = poLine.Accounting_Segment__r; 
                

                DateTime costDate;
                if(poLine.Need_Date__c != null)
                	costDate = datetime.newInstance(poLine.Need_Date__c.year(), poLine.Need_Date__c.month(),poLine.Need_Date__c.day());
                
                Decimal tmpCost = ItemService.getActiveStandardCost(itemIds,facilityIds,poLine.Company__c,poLine.Delivery_Facility__c,costDate).get(poLine.Item__c);
				if(tmpCost == null) tmpCost = 0;               
                rilNew.Extended_Cost__c = KSE.addQuantityToField(rilNew.Invoice_Quantity__c, 0) * tmpCost;
                rilNewList.add(rilNew);
            }   
             //KNDY-18171
	        if(taxEnabled){
	        	if(taxFields != null){
	        		SupplierInvoiceService.populateShipToShipFromFieldsOnSIL(rilNewList,polList);
	        	}
	        } 
        }
        Map<Id, Item__c> itemDetailsMap = getItemDetailsMap(itemIds);
        
        for (Integer i = 0; i< rilNewList.size() ; i++) {
            rilNewList[i].Item__r = itemDetailsMap.get(rilNewList[i].Item__c);
            
            result.add(new InvoiceLineWrapper(rilNewList[i]));
        }
        JsonResult jsonRes = new JsonResult(result, result.size());
        if (result.size() == 0){//KNDY-12258
            jsonRes.addMessage(Label.All_purchase_order_lines_are_closed_for_invoicing, ApexPages.Severity.INFO);
        }
        return jsonRes;
     }
     
     @RemoteAction
     public static JsonResult getSegments(Id itemId, String lineType) {
        List<InvoiceLineWrapper> invoiceLines = new List<InvoiceLineWrapper>();
        Boolean hasSegments = false;
        Accounting_Default__c segments = new Accounting_Default__c();
        Map<Id, Item__c> itemDetailsMap = getItemDetailsMap(new Set<Id>{ itemId });
        Item__c item = itemDetailsMap.get(itemId);
        
        if (item != null) {
            if( ProcessConfigService.configResult('Supplier_Invoice_Line__c', item.Class__r.Type__c, lineType, true) ) { 
                hasSegments = true;
            }
        }
        
        invoiceLines.add(new InvoiceLineWrapper(hasSegments, segments));

        return new JsonResult(invoiceLines, invoiceLines.size());
    }
     
    public String getReturnUrl(){
        PageReference pageRef;
        
        if (si != null && si.id != null ){
            pageRef =  new PageReference('/' + si.Id);
        }
        else{
            Schema.DescribeSObjectResult dsr = Supplier_Invoice__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        }
        
        return pageRef.getUrl();
    }
    
    @RemoteAction 
    public static JsonResult headerActions(Id siId, String actionType) {         
        JsonResult result = new JsonResult();
        if (actionType == 'Validate'){ // KNDY-7636
            result = SupplierInvoiceService.inspectSI(siId);
        } else if(actionType == 'Tax'){

            SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c');
            soql.addFields(new Set<String>{'Id', 'Company__c','Invoice_Type__c'});
            soql.setWhereClause('Id=:siId');

            Supplier_Invoice__c supInv = Database.query(soql.getQuery());
            if(taxSvc.taxServiceConfigured(Supplier_Invoice__c.getSobjectType().getDescribe().getLocalName(), supInv) == true){
                TaxService.TaxResult tr = taxSvc.getTax(siId);
                result.success = tr.isSuccess;
                result.addMessage(tr.message, ApexPages.Severity.INFO);
                if(tr.obj != null){
                    result.records = new List<Object>{tr.obj};
        } 
            }else{
                result.success = true;
                result.addMessage('', ApexPages.Severity.INFO); 
            }
            
        }
        return result;
    }   
 
    @RemoteAction    
    public static JSONResult massOverrideTasks(list<Task> selectedTasks){
        JSONResult result = TasksMassOverride.massOverrideTasks(selectedTasks);
        return result;
    }
    
     @RemoteAction    
     public static JsonResult saveAndInspect(Supplier_Invoice__c si, List<String> headerDateFields, 
                                        List<InvoiceLineWrapper> updatedList, List<InvoiceLineWrapper> newList, 
                                        List<InvoiceLineWrapper> deletedList, List<String> dateFields, 
                                        boolean hasHeaderPOChanged) { // KNDY-12325 KNDY-12490
		JsonResult result = new JsonResult();
		result = saveAction(si,  headerDateFields, updatedList, newList,deletedList, dateFields,hasHeaderPOChanged);
		if (result.success){
			JSONResult inspectResult = SupplierInvoiceService.inspectSI(si.Id);
			if ( inspectResult.messages.size() > 0){
			   result.success = inspectResult.success;
			   for (Map<String, String> error : inspectResult.messages) {
	               result.addMessage(error.get('message'), ApexPages.Severity.ERROR);
	           }	
			}
		}
        return result;
     }
     
     @RemoteAction    
     public static JsonResult saveAction(Supplier_Invoice__c si, List<String> headerDateFields, List<InvoiceLineWrapper> updatedList, List<InvoiceLineWrapper> newList, List<InvoiceLineWrapper> deletedList, List<String> dateFields, boolean hasHeaderPOChanged) {
        KendoUtils.UpdateDateFields(si, headerDateFields);
        
        if (updatedList.size() > 0) {
            for (InvoiceLineWrapper line : updatedList) {
                KendoUtils.UpdateDateFields(line.invoiceLine, dateFields);
            }
        }
        
        if (newList.size() > 0) {
            for (InvoiceLineWrapper line : newList) {
                KendoUtils.UpdateDateFields(line.invoiceLine, dateFields);
            }
            
            
        }
        
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        list<Supplier_Invoice__c> records = new list<Supplier_Invoice__c>();        
              
        try {    
			if (SupplierInvoiceService.validateSave(si, null,result) == false){   
			    Database.rollback(sp);
                result.success = false;
                return result;
            }
            
            if(si.Invoice_Type__c == 'Credit Memo') {
            	si.Credit_Memo_Balance__c = si.Invoice_Amount__c;
            	si.Credit_Memo_Amount__c = si.Invoice_Amount__c;
            }else if(si.Invoice_Type__c == 'Prepayment') {//KNDY-9376
            	si.Credit_Memo_Balance__c = -si.Invoice_Amount__c;
            	si.Credit_Memo_Amount__c = -si.Invoice_Amount__c;
            }
            
            if (!si.finalized__c && si.Status__c != 'Void' && si.Status__c != 'Cancelled') //KNDY-2512 only update status on unfinalized invoices. Finalized invoices don't allow edits except hold
                si.Status__c = 'Incomplete';
            

            if (si.Id != null){
                DML.updateAsUser(si);//KNDY-17757
            }
            else{
                DML.insertAsUser(si); //KNDY-17757
            }
            
            // delete supplier invoice lines if the purchase order header has changed
            if (hasHeaderPOChanged) {
                
				Id siId = si.Id;//KNDY-11786
				SOQLUtil soql = new SOQLUtil('Supplier_Invoice_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id'
				});
				soql.setWhereClause('Supplier_Invoice__c = :siId'); //KNDY-11786

				List<Supplier_Invoice_Line__c> siLinesForDeletion = Database.query(soql.getQuery());
                
                if (siLinesForDeletion.size() > 0) {
                	//delete supplier invoice lines;
                    DML.deleteAsUser(siLinesForDeletion);
                }
            }
            
            // save invoice lines
            Set<String> invalidRowGUIDs = new Set<String>();
            if (newList.size() > 0 || updatedList.size() > 0 || deletedList.size() > 0){
                 invalidRowGUIDs = saveInvoiceLines(si, updatedList, newList, deletedList, result);
            }
            if(SupplierInvoiceManageExt.saveException == false){
                   if (result.success) {
                       records.add(si);
                       result.records = records;
                       result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
                   }
                   else {
                           Database.rollback(sp);
                   }
            }else{
                   Database.rollback(sp);
                   result.records = new List<String>(invalidRowGUIDs);
                   result.success = false;
                   result.addMessage(' ' +'Not able to save the supplier invoice as there are '+numberOfLinesWithSegmentErrors+' segment validation errors. Please correct the highlighted line(s). ', ApexPages.Severity.ERROR);
            }
        }
        catch (Exception e) {
            Database.rollback(sp);
            system.debug(LoggingLevel.Error, 'exception '+e.getMessage()+' '+e.getStackTraceString());
            result.success = false;
            if (e.getTypeName() == 'System.DmlException'){ //KNDY-9677
               String supplierAndInvoiceField = KSE.NamespaceUU + 'Supplier_and_Invoice__c';
               if (e.getMessage().contains('DUPLICATE_VALUE, duplicate value found: ' + supplierAndInvoiceField)){
                   e.setMessage(Label.Duplicate_supplier_invoice_exists_for_supplier);
               }
            }
            result.addMessage('An Error occured : ' + e.getMessage() , ApexPages.Severity.ERROR);
        }

        return result;
     }
        
     public static Set<String> saveInvoiceLines(Supplier_Invoice__c si, List<InvoiceLineWrapper> updatedList, List<InvoiceLineWrapper> newList, List<InvoiceLineWrapper> deletedList, JsonResult result) {
     	Set<String> invalidRowGuids = new Set<String>();
        map<Id, Purchase_Order_Line__c> poLineDetailsMap = new map<Id, Purchase_Order_Line__c>();
        map<Id, Item__c> itemDetailsMap = new map<Id, Item__c>();
        Set<Id> poLineIds = new Set<Id>();
        Set<Id> itemIds = new Set<Id>();
        
        if (updatedList.size() > 0) {
            for (InvoiceLineWrapper line: updatedList) {
                poLineIds.add(line.invoiceLine.Purchase_Order_Line__c);
                itemIds.add(line.invoiceLine.Item__c);
                line.invoiceLine.Tax_Included__c  =  line.invoiceLine.Tax_Included__c ? true : false; //checkbox field defaulted to false
            }    
        }
        
        if (newList.size() > 0) {
            for (InvoiceLineWrapper line: newList) {
                poLineIds.add(line.invoiceLine.Purchase_Order_Line__c);
                itemIds.add(line.invoiceLine.Item__c);
                line.invoiceLine.Tax_Included__c  =  line.invoiceLine.Tax_Included__c ? true : false;
            }    
        }
        
         //Adding CRUD/FLS checks with SOQLUtil
         String whereClause;
         if (si.Invoice_Type__c == 'Invoice'){
            whereClause = 'Id IN :poLineIds AND Invoice_Status__c = \'Open for Invoicing\''; 
         } else{
            whereClause = 'Id IN :poLineIds';  
         }
        	
        SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c',true);
        soql.addFields(new Set<String>{'Id','Approved__c','Invoice_Matching__c','Company__c', 'Quantity_Credited__c', 'Amount_Credited__c', 'Delivery_Facility__c', 'Quantity_Returned_to_Supplier_for_Credit__c', 'Order_Quantity__c', 'Need_Date__c', 'Item__c', 'Unit_Price__c', 'Invoice_Status__c' });
        soql.setWhereClause(whereClause); 
        List<Purchase_Order_Line__c> poLinesQueried = Database.query(soql.getQuery()); 
        for (Purchase_Order_Line__c lineItem : poLinesQueried) {
            poLineDetailsMap.put(lineItem.Id, lineItem);
        }
        
		 soql = new SOQLUtil('Item__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Source__c'
		});
		soql.setWhereClause('Id IN :itemIds');

		for (Item__c item : Database.query(soql.getQuery())){
            itemDetailsMap.put(item.Id, item);
        }
        
        // set the related fields
        if (updatedList.size() > 0) {
            for (InvoiceLineWrapper line: updatedList) {
                line.invoiceLine.Purchase_Order_Line__r = poLineDetailsMap.get(line.invoiceLine.Purchase_Order_Line__c);
                line.invoiceLine.Item__r = itemDetailsMap.get(line.invoiceLine.Item__c);
            }    
        }
        
        if (newList.size() > 0) {
            for (InvoiceLineWrapper line: newList) {
                line.invoiceLine.Purchase_Order_Line__r = poLineDetailsMap.get(line.invoiceLine.Purchase_Order_Line__c);
                line.invoiceLine.Item__r = itemDetailsMap.get(line.invoiceLine.Item__c);
            }    
        }
        //updated list and deleted list are handled in trigger
        if (si.Invoice_Type__c != 'Prepayment'){ // KNDY-9649
        		updatePurchaseOrderLines(poLineDetailsMap, newList);
        }
        
        List<InvoiceLineWrapper> invoiceLines = new List<InvoiceLineWrapper>();
        
        invoiceLines.addAll(updatedList);
        invoiceLines.addAll(newList);
        
        //building collections to hold all relevant data sets
        List<Accounting_Default__c> segmentsToBeValidated = new List<Accounting_Default__c>();
        List<Accounting_Default_Segment_Definition__c> segDefs = Accounting_Default_Segment_Definition__c.getAll().Values();
		Map<String, String> mapOfCounterToRowGUID = new Map<String, String>();
        Map<String, InvoiceLineWrapper> mapOfInvLineWrapperWithSegments = new Map<String, InvoiceLineWrapper>(); //list of wrappers with segments
        
        if (invoiceLines.size() > 0) {
            // validate invoice lines
            Integer counter = 0; 
            List<Supplier_Invoice_Line__c> invLines = new List<Supplier_Invoice_Line__c>();
            for(InvoiceLineWrapper line : invoiceLines) {
            	line.invoiceLine.Supplier_Invoice__r = si;
            	invLines.add(line.invoiceLine);
            	
            	//Collect all segments from all lines in question and if weed out the null or blank lines
            	Accounting_Default__c segment = line.segments;
            	
            	Boolean SegmentNotBlank = false; // Setting a boolean flag indicator even if one of the segments has data in it
            	for(Accounting_Default_Segment_Definition__c sd : segDefs){ // looping through the Segment Def to compare against segments entered
            		if (segment.get(sd.accounting_default_field__c) != null){ //A segment is entered since value is not null (blanks == null)
            			SegmentNotBlank = true; //Even if one of the segments is filled in then set the flag in order to validate that invoice line
            		}
            	}
            	if (SegmentNotBlank){
            		segmentsToBeValidated.add(segment); // Add to a list of segments to be validated
            		mapOfCounterToRowGUID.put(string.valueof(counter), line.rowGUID); // building a map of RowGUIDs
            		mapOfInvLineWrapperWithSegments.put(line.rowGUID, line); // this map is only used to do some quick searching for a hit on the wrapper
            		line.hasSegments = true; // set the status on the wrapper line
            	}else{
            		line.segments = null; // Segments are blank so null out reference to prevent creation of Accounting Default record and mark hasSegments as false
            		line.hasSegments = false;
            	}
            	counter++; // Next invoice wrapper
            
            } // end of loop iterating over invoice line wrappers
            
            List<String> invalidCounters = new List<String>(); // create a list of all invalid record ids coming back from segment validation response
            //Validating segments outside of a loop
        	if (segmentsToBeValidated.size() > 0){
        		//Peek into segments to see if they are valid or not. If not valid, mark them so that UI can show an error msg
        		SegmentValidationService svs = SegmentValidationService.getInstance();
       			List<SegmentValidationService.SegmentValidationResponse> svrList = new List<SegmentValidationService.SegmentValidationResponse>();
        		svrList = svs.beforeValidateAccountingDefaults(segmentsToBeValidated);
        	
        		//Iterate over the responses to figure out which ones are bad
        		for (SegmentValidationService.SegmentValidationResponse svrLocal: svrList) {
                    if(svrLocal.isValid == false){
                    	invalidCounters.add(svrLocal.recordId); // If its an invalid segment, collect the recordId which would match the counter that we set earlier
                    }
				}
        	}
			
			// Now we have a list of Invalid counters, iterate and compare with RowGUID Map to figure out which RowGUID --> Invoice Wrapper to mark on UI
        	for (String invalidSegDefRecordId: invalidCounters){
        		//Get the RowGuid with invalid segments
        		if (mapOfCounterToRowGUID.containsKey(invalidSegDefRecordId)){
        			String invalidSegmentRowGuid = mapOfCounterToRowGUID.get(invalidSegDefRecordId);
        			//Now use this Row GUId to figure out which wrapper line is in question
        			InvoiceLineWrapper lineInQuestion = mapOfInvLineWrapperWithSegments.get(invalidSegmentRowGuid);
        			
        			//We found the invoice line wrapper with invalid segments, add it to the error string to display it on UI
        			if(lineInQuestion.invoiceLine.item__r.name != null){
                       listOfInvalidSegments.add(lineInQuestion.invoiceLine.item__r.name+';   ');
                   }
                   if(lineInQuestion.rowGUID != null){
                       listOfInvalidRowGUID.add(lineInQuestion.rowGUID);
                   }
        		}
            }
            
			if (SupplierInvoiceService.validateSave(si, invLines, result) == false){
				result.success = false;
                return null;
            }
            
            // save lines
            invalidRowGuids = saveLines(si, invoiceLines);
        }
        
        if (deletedList.size() > 0) {
            // delete lines
            invalidRowGuids = deleteLines(si, deletedList);
        }
        
        return invalidRowGuids;
     }
     
     public static Set<String> saveLines(Supplier_Invoice__c si, List<InvoiceLineWrapper> invoiceLines) {

        List<Accounting_Default__c> segments = new List<Accounting_Default__c>();
        List<ID> DelSegments = new List<ID>();
        Map<Id, Supplier_Invoice__c> invoiceMap = new Map<Id, Supplier_Invoice__c>();
        
        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        List<Date> dateList = new List<Date>();
         
        //KNDY-17757
        List<Supplier_Invoice_Line__c> newSILs = new List<Supplier_Invoice_Line__c>();
        List<Supplier_Invoice_Line__c> existingSILs = new List<Supplier_Invoice_Line__c>();

        
        for (InvoiceLineWrapper item: invoiceLines) {
        	 Supplier_Invoice_Line__c line = item.invoiceLine;
        	itemIds.add(line.Item__c);
        	facilityIds.add(line.Purchase_Order_Line__r.Delivery_Facility__c);
        	dateList.add(line.Purchase_Order_Line__r.Need_Date__c);		
        }
        
        ItemService.preCacheCostRecords(dateList, itemIds, facilityIds);        
        
        for (InvoiceLineWrapper item: invoiceLines) {
            Supplier_Invoice_Line__c line = item.invoiceLine;
            Accounting_Default__c segment = item.segments;
            
            line.Supplier_Invoice__c = si.Id;
            
            // KNDY-2802
            if (line.Purchase_Order_Line__c != null ) {    
                if (line.Item__r.Source__c == 'Miscellaneous')
                    line.Miscellaneous__c = true;  
                else
                    line.Miscellaneous__c = false;
                                 
                DateTime costDate;
                if(line.Purchase_Order_Line__r.Need_Date__c != null)
                	costDate = datetime.newInstance(line.Purchase_Order_Line__r.Need_Date__c.year(), line.Purchase_Order_Line__r.Need_Date__c.month(),line.Purchase_Order_Line__r.Need_Date__c.day());
                
                Decimal tmpCost = ItemService.getActiveStandardCost(itemIds,facilityIds,line.Purchase_Order_Line__r.Company__c,line.Purchase_Order_Line__r.Delivery_Facility__c,costDate).get(line.Item__c) ;
                if(tmpCost == null) tmpCost = 0;
                line.Extended_Cost__c = KSE.addQuantityToField(line.Invoice_Quantity__c, 0) * tmpCost;
            }
    
            if (segment != null) {
            	segments.add(segment);
            }
            else {
            	if( line.id != null && line.Accounting_Segment__c != null)
                {
	            	DelSegments.add(line.Accounting_Segment__c);
	            	line.Accounting_Segment__c = null;  
                }	          	
            }
            
            if( line.Id != null){ //KNDY-17757
                existingSILs.add(line);
            }
            else{
                newSILs.add(line);
            }  
            System.debug(logginglevel.error,'line 1161--->'+line.Supplier_Invoice__r.Status__c);
            }
        
			if(listOfInvalidSegments.size()>0){
					for(String localString: listOfInvalidSegments){
					   segmentErrors = segmentErrors + localString ;
					   numberOfLinesWithSegmentErrors = numberOfLinesWithSegmentErrors + 1 ;
			   		}
			}
        
        DML.checkUpsertAsUser(segments); //why are we checking up here?
       try{
               errorMessage = 'before the upsert '+segments;
               DML.checkUpsertAsUser(segments); upsert segments;
               if(DelSegments.size() > 0)
               	DML.deleteAsUser(DelSegments);
       }catch( Exception e){
           saveException = true;
           errorMessage = 'An Error Occured  now : '+e.getMessage();
           if(errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'))
               {
                   List<String> tempErr = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
                   errorMessage = tempErr[1];
               }
       }
        
        for (InvoiceLineWrapper item: invoiceLines) {
            Supplier_Invoice_Line__c line = item.invoiceLine;
            Accounting_Default__c segment = item.segments;
            if (segment != null) {
           		line.Accounting_Segment__c = segment.Id;
            }
        }
        
        //KNDY-17757
        if(existingSILs.size() > 0){
            DML.updateAsUser(existingSILs);
        }
        if(newSILs.size() > 0){
            DML.insertAsUser(newSILs);
        }
   
        return listOfInvalidRowGUID;
    }
    
    public static void updatePurchaseOrderLines(map<Id, Purchase_Order_Line__c> poLinesMap, List<InvoiceLineWrapper> newList) {
    	List<Purchase_Order_Line__c> poLines = new List<Purchase_Order_Line__c>();
    	Map<Id,Supplier_Invoice_Line__c> silMap = new Map<Id,Supplier_Invoice_Line__c>();

    	for(InvoiceLineWrapper line : newList) {
    		if(line.invoiceLine.Purchase_Order_Line__c != null) {
    			silMap.put(line.invoiceLine.Purchase_Order_Line__c,line.invoiceLine);
    		}
    	}
    	
    	Map<Id, decimal> invoiceQuantities = new Map<Id, decimal>();
    	Map<Id, decimal> invoicePrices = new Map<Id, decimal>();
        if (newList.size() > 0) {
            for (InvoiceLineWrapper item: newList) {
            	Supplier_Invoice_Line__c line = item.invoiceLine;
            	
            	if (line.Purchase_Order_Line__c != null ) {
            		decimal invoiceQuantity = 0;
            		decimal invoicePrice = 0;
            		
            		if (invoiceQuantities.containsKey(line.Purchase_Order_Line__c)) {
		        		invoiceQuantity = invoiceQuantities.get(line.Purchase_Order_Line__c);
		        		invoicePrice = invoicePrices.get(line.Purchase_Order_Line__c);
		        	}
		        	
		        	invoiceQuantity -= line.Invoice_Quantity__c;
		            invoiceQuantities.put(line.Purchase_Order_Line__c, invoiceQuantity);
		            
		            invoicePrice -= line.Unit_Price__c * line.Invoice_Quantity__c;//KNDY-14371
		            invoicePrices.put(line.Purchase_Order_Line__c, invoicePrice);
            	}
            }    
        }
        
        if (!poLinesMap.isEmpty()) {
	    	for (Purchase_Order_Line__c item: poLinesMap.values()) {
    			Purchase_Order_Line__c polToUpdate = new Purchase_Order_Line__c(id = item.Id);
                    
                polToUpdate.Quantity_Credited__c = (item.Quantity_Credited__c == null ? 0 : item.Quantity_Credited__c);
            	polToUpdate.Amount_Credited__c = (item.Amount_Credited__c == null ? 0 : item.Amount_Credited__c);
                
                decimal invoiceQuantity = 0;
                decimal invoicePrice = 0;
            		
        		if (invoiceQuantities.containsKey(item.Id)) {
	        		invoiceQuantity = invoiceQuantities.get(item.Id);
	        	}
	        	
	        	if (invoicePrices.containsKey(item.Id)) {
	        		invoicePrice = invoicePrices.get(item.Id);
	        	}
	        	
	        	Supplier_Invoice_Line__c sil = silMap.get(item.Id);
	        	if (sil != null){ // safe guarding against a null pointer exception if the SIL is a deleted line
	        	if(sil.Invoice_Quantity__c * sil.Unit_Price__c < 0) {//KNDY-14371
	        		if(sil.Invoice_Quantity__c < 0) {
	        			polToUpdate.Quantity_Credited__c -= invoiceQuantity;
	        		}
	        		polToUpdate.Amount_Credited__c -= KSE.addQuantityToField(invoicePrice,0);
	        	}
	         }
                
                    
				poLines.add(polToUpdate);
	    	}
	    	
	    	DML.updateAsUser(poLines);
        }
    }
    
    public static Set<String> deleteLines(Supplier_Invoice__c si, List<InvoiceLineWrapper> invoiceLines) {
		List<Supplier_Invoice_Line__c> siLines = new List<Supplier_Invoice_Line__c>();
        List<Accounting_Default__c> segments = new List<Accounting_Default__c>();
        List<InvoiceLineWrapper> invoiceLinesToDelete = new List<InvoiceLineWrapper>();
    	
        //PTP-596 Make sure only lines committed to DB are processed for delete
        for (InvoiceLineWrapper item: invoiceLines) {
            if (item.invoiceLine.id != null){
                invoiceLinesToDelete.add(item);
            }
        }
    	
        for (InvoiceLineWrapper item: invoiceLinesToDelete) {
            Supplier_Invoice_Line__c line = item.invoiceLine;
            Accounting_Default__c segment = item.segments;
            
            line.Supplier_Invoice__c = si.Id;
            
            if (line.Accounting_Segment__c != null && line.Accounting_Segment__r != null ){
                segments.add(line.Accounting_Segment__r);
            }
                
            siLines.add(line);  
        }
        
        if (segments.size() > 0) {
        	// delete segments
        	DML.deleteAsUser(segments);
        }
        
        if (siLines.size() > 0) {
        	//delete supplier invoice lines;
            DML.deleteAsUser(siLines);
        }
        return null;
    }

     public static Map<Id, Item__c> getItemDetailsMap(Set<Id> itemIds) {
        map<Id, Item__c> itemList = new map<Id, Item__c>();
            
		SOQLUtil soql = new SOQLUtil('Item__c', true);
		soql.addFields(new set<string>{
			'Id','name','class__c','class__r.type__c'
		});
		soql.setWhereClause('Id IN :itemIds');
		
		for (Item__c item : Database.query(soql.getQuery())){
            itemList.put(item.Id, item);
        }
    
        return itemList;
     }
     
     //Wrapper to capture the Invoice Lines.
     public class InvoiceLineWrapper {
        public Supplier_Invoice_Line__c invoiceLine { get; set; }
        public boolean hasSegments { get; set; } { hasSegments = false; }
        public Accounting_Default__c segments { get; set; }
        String errors { get; set; }
        public double invoicedAmount { get; set; } { invoicedAmount = 0; }
        public String rowGUID{get;set;}
        
        public InvoiceLineWrapper(boolean hasSegments, Accounting_Default__c segments) {
            this.hasSegments = hasSegments;
            this.segments = segments;   
        }
        
        public InvoiceLineWrapper(Supplier_Invoice_Line__c invoiceLine) {
            Accounting_Default__c ad = new Accounting_Default__c();
            this.invoiceLine = invoiceLine;
            this.hasSegments = true;
            
            if (invoiceLine.Accounting_Segment__c != null) { 
                ad = invoiceLine.Accounting_Segment__r; 
            }
                    
            this.segments = ad;
            this.invoicedAmount = (KSE.addQuantityToField(invoiceLine.Invoice_Quantity__c, 0) * KSE.addQuantityToField(invoiceLine.Unit_Price__c, 0)).setScale(2, RoundingMode.HALF_UP);//KNDY-14371
        }
     }
}