/***
Need custom setting: Purchase Order Line Custom Views
***/
public with sharing class PurchaseOrderManageExt extends BaseController {
    ApexPages.StandardController con;
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    private static SchemaUtil util = SchemaUtil.getInstance();
    public string pageTitle { get; set; }
    public string approvalStatus{ get; set;}
    public string status{ get; set;}
    public Purchase_Order__c po { get; set; }
    public GridRelatedListController.GridRelatedListConfig poLinesConfig {get; set;}      
    public String poLinesFieldList = null;
    public GridRelatedListController.GridRelatedListConfig segmentLinesConfig {get; set;} 
    public String segmentLinesFieldList = null;
    public SegmentService segmentSvc = new SegmentService();
    public List<Grid_Views_Config__c> customViewList = null;
    public Map<String, FieldInfo> allFieldsMap = new Map<String, FieldInfo>();
    public Boolean isUsingCustomApprovalProcess { get; set;}	
    
    // Segment Validation Exception Fields
    public static Boolean saveException = false;
    public static String errorMessage = '';
    public static Set<String> listOfInvalidSegments = new Set<String>();
    public static Set<String> listOfInvalidRowGUID = new Set<String>();
    public static String segmentErrors = '';
    public static Integer numberOfLinesWithSegmentErrors = 0;

    private static TaxService taxSvc = TaxService.getInstance();
    public Boolean HasTax{get;private set;}

    public PurchaseOrderManageExt(ApexPages.StandardController controller) {
        con = controller;
        isUsingCustomApprovalProcess = false;
        if (KSE.getSourceDocumentApprovals().containsKey('Purchase Order')){
        	Source_Document_Approval__c sda = Source_Document_Approval__c.getValues('Purchase Order');
        	isUsingCustomApprovalProcess = sda.Allow_Approval__c; //set the approval to true if the custom setting says so
        	
        }
        if( controller.getRecord().id != null ){
            po = (Purchase_Order__c) controller.getRecord();
            pageTitle = 'Purchase Order '  + po.Name;
            approvalStatus = po.Approval_Status__c;
            status = po.Status__c;
            Company__c company = new Company__c();
            if (po.Company__c != null){
                company = CompanyService.getCompanyInfo(po.Company__c);        
            }
            po.Company__r = company;
            if (ApexPages.currentPage().getParameters().containsKey('clone') && 
                ApexPages.currentPage().getParameters().get('clone') == '1'){// KNDY-10509
                pageTitle = 'Clone of Purchase Order ' + po.Name;
                status = 'Open';
                approvalStatus = 'Pending Authorization';
                po.Approval_Status__c = approvalStatus;
                po.Status__c = status;
                User u = [select Id, Name from User where Id = :UserInfo.getUserID()];
                po.Buyer__c = u.Id;
                po.Buyer__r = u;
            }
            
        }
        else{
            approvalStatus = 'Pending Authorization';
            status = 'Open';
            
            CompanyService compServ = new CompanyService(controller);
            po = new Purchase_Order__c();
            po.Company__c = CompanyService.getDefaultCompanyId();
            po.Company__r = compServ.Company;
            if (po.Company__c != null){ //KNDY-11133
                Company__c defaultCompany = CompanyService.getCompanyInfo(po.Company__c);
                po.Company__r = defaultCompany;
                UserPreference defaults = UserPreference.getInstance(); 
                if(defaults.preference.Default_Facility__c != null){
                    Facility__c facility = [Select Id, Default_Purchasing_Delivery_Location__c, Default_Purchasing_Delivery_Location__r.Name From Facility__c Where Id =:defaults.preference.Default_Facility__c];
                	po.Delivery_Facility__c = defaults.preference.Default_Facility__c;
                	po.Delivery_Facility__r = defaults.preference.Default_Facility__r;
                	po.Delivery_Location__c = facility.Default_Purchasing_Delivery_Location__c;
                    po.Delivery_Location__r = facility.Default_Purchasing_Delivery_Location__r;
                }else {
                    po.Delivery_Facility__c = defaultCompany.Default_Purchasing_Deliver_To_Facility__c;
                    po.Delivery_Facility__r = defaultCompany.Default_Purchasing_Deliver_To_Facility__r; 
                    po.Delivery_Location__c = defaultCompany.Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__c;
                    po.Delivery_Location__r = defaultCompany.Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__r;
                    
                }
                
                if(CompanyService.defaultTransactionCurrencyRec(po.Company__c) != null){
                po.Currency__c = CompanyService.defaultTransactionCurrencyRec(po.Company__c).Id;
                po.Currency__r = CompanyService.defaultTransactionCurrencyRec(po.Company__c);
                }
            }
            
            if(ApexPages.currentPage().getParameters().containsKey('reqs')){
                String reqStr = ApexPages.currentPage().getParameters().get('reqs');
                reqStr = reqStr.substring(0, reqStr.indexOf('?'));

                List<String>reqIds = (List<String>)JSON.deserialize(reqStr, List<String>.class);        

                if(reqIds.size() > 0){
                    String whereClause = 'Id=:reqIds';
                    Set<String> fields = new Set<String>{'Id', 'Requisition__r.Currency__c', 'Requisition__r.Currency__r.Id', 
                                                'Supplier__r.Name', 'Supplier__c', 'Supplier__r.Remit_To__c', 'Supplier__r.Remit_To__r.Name',
                                                'Requisition__r.Currency__r.Name', 'Requisition__r.Source__c', 'Requisition__r.Ship_To_Customer__c',
                                                'Requisition__r.Ship_To_Customer__r.Address__c','Requisition__r.Deliver_To_City__c', 'Requisition__r.Deliver_Street__c',
                                                'Requisition__r.Deliver_To_State__c', 'Requisition__r.Deliver_To_Country__c', 'Requisition__r.Deliver_To_Zip_Code__c',
                                                'Requisition__r.Sales_Order__c'};
                    
                    SOQLUtil soql = new SOQLUtil('Requisition_Line__c');
                    soql.addFields(fields);
                    soql.setWhereClause(whereClause);
                    List<Requisition_Line__c> req = database.query(soql.getQuery());
                    po.Currency__c = req[0].Requisition__r.Currency__r.Id;
                    po.Currency__r = req[0].Requisition__r.Currency__r;
                    
                    for (Requisition_Line__c rql : req){
                        if (rql.Supplier__c != null){
                            po.Supplier__c = rql.Supplier__c;
                            po.Supplier__r = rql.Supplier__r;
                            po.Remit_To_Supplier__c = rql.Supplier__r.Remit_To__c;
                            po.Remit_To_Supplier__r = rql.Supplier__r.Remit_To__r;
                        }
                        if (rql.Requisition__r.Source__c == 'Drop Ship' || rql.Requisition__r.Source__c == 'Back To Back'){
                        	
	                        if (rql.Requisition__r.Source__c == 'Drop Ship')
	                        	po.Type__c = 'Drop Ship'; 
	                        else
	                            po.Type__c = 'Standard'; //KNDY-13443
                                     
	                        po.Sales_Order__c = rql.Requisition__r.Sales_Order__c;  
	                        po.Deliver_to_Customer__c = rql.Requisition__r.Ship_To_Customer__c;
	                        po.Deliver_to_Address__c = rql.Requisition__r.Ship_To_Customer__r.Address__c;
	                        po.Deliver_To_City__c = rql.Requisition__r.Deliver_To_City__c;
	                        po.Deliver_To_Street__c = rql.Requisition__r.Deliver_Street__c;
	                        po.Deliver_To_State__c = rql.Requisition__r.Deliver_To_State__c;
	                        po.Deliver_To_Country__c = rql.Requisition__r.Deliver_To_Country__c;
	                        po.Deliver_To_Zip_Code__c = rql.Requisition__r.Deliver_To_Zip_Code__c;
	                    }
	                    system.debug(LoggingLevel.ERROR,'po: ' + po);
                    }
                    system.debug(LoggingLevel.ERROR,'po after: ' + po);
                }
            }
            
            po.Approval_Status__c = approvalStatus;
            po.Status__c = status;
           // po.Type__c = 'Standard';
            User u = [select Id, Name from User where Id = :UserInfo.getUserID()];
            po.Buyer__c = u.Id;
            po.Buyer__r = u;
            pageTitle = 'Purchase Order ';
        }
        List<String> segmentsList = new List<String>(); 
        try{ 
            segmentsList = segmentSvc.segmentNameListForAP(true, 'Invoice');
        } catch(Exception ex){
            // if SS service returns exceptions then nothing to do, UI should show No Segments required msg
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Cannot_load_segment_data + ' ' + MessageUtil.toFriendlyErrorMessage(ex.getMessage()))); //ToDo this msg is not showing up on SI UI
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
        }  
        
        Set<String> poLinesAdditionalFields = new Set<String>();
        poLinesAdditionalFields.addAll(new set<string>{'Id', 'Name', 'Approved__c', 'Contract_Line__c', 'Accounting_Segment__c', 'Company__c', 'Status__c', 'Supplier__c', 'Supplier__r.Id', 'Supplier__r.Name', 'Item__r.Source__c', 'Delivery_Facility__r.Facility_Identifier__c'});
        
        HasTax = taxSvc.taxServiceConfigured(Purchase_Order__c.getSobjectType().getDescribe().getLocalName(),po);
        
        if(HasTax){
            List<FieldInfo> taxFields = taxSvc.getDisplayFieldSet(Purchase_Order__c.getSobjectType());

            if(taxFields != null){
                for(FieldInfo tf : taxFields){
                    poLinesAdditionalFields.add(tf.field);
                }
            }
        }

        poLinesAdditionalFields.addAll(segmentsList);
        for (Integer i = 0; i < segmentsList.size(); i++) {
            poLinesAdditionalFields.add(segmentsList[i].replace('__c', '__r.Name'));
        }
        // Purchase Order Lines Grid config
        poLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        poLinesConfig.uniqueId = 'POLinesGrid';
        poLinesConfig.title = 'Purchase Order Lines';
        poLinesConfig.parentRecord = po;
        poLinesConfig.objectName = 'Purchase_Order_Line__c';  
        poLinesConfig.parentField = 'Purchase_Order__c';

        poLinesConfig.buttons = 'columnmenu, search';
        if (po.Type__c != PurchaseOrderService.PO_TYPE_SUBCONTRACT) {
            poLinesConfig.buttons = 'create, delete, clone, ' + poLinesConfig.buttons;
        }
        
        poLinesConfig.sortField = 'Line__c'; //KNDY-8783
        poLinesConfig.sortOrder = 'ASC'; //KNDY-8783
        poLinesConfig.additionalFields = String.join(new List<String>(poLinesAdditionalFields), ',');  
        
        // Segment Lines Grid config
        segmentLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        segmentLinesConfig.uniqueId = 'SegmentLinesGrid';
        segmentLinesConfig.objectName = 'Accounting_Default__c'; 
 
    }

    public string getPurchaseOrderJson() {
        return JSON.serialize(po);  
    }
    
    public string getPurchaseOrderHeaderFieldList() {
        String purchaseOrderHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        Set<String> readOnlyFields = new Set<String>();
        
        // get the po header field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Purchase_Order__c', 'Purchase_Order_Header');
        // get the read only fields
        List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('Purchase_Order__c', 'Purchase_Order_RO');
        for (Integer i = 0; i<fieldInfoListRO.size(); i++){
            readOnlyFields.add(fieldInfoListRO[i].field);
        } 
        // if read only fields contains any of the header fields, disable editing
        for(Integer i = 0; i < fieldInfoList.size(); i++) {
            String fld = fieldInfoList[i].field.toLowerCase();
            if (po.Type__c == PurchaseOrderService.PO_TYPE_SUBCONTRACT && fld == 'type__c') {
                fieldInfoList[i].selectList.add(new SelectListItem(PurchaseOrderService.PO_TYPE_SUBCONTRACT,PurchaseOrderService.PO_TYPE_SUBCONTRACT));
            }
            
            if (readOnlyFields.contains(fieldInfoList[i].field)){
                fieldInfoList[i].editable = false;
            }
        }
        fieldInfoList.remove(0); // Remove Id field from the list
        purchaseOrderHeaderFieldList = JSON.serialize(fieldInfoList);
        return purchaseOrderHeaderFieldList;
    }
    
    public string getPurchaseOrderAddlHeaderFieldList() {
        String purchaseOrderAddlHeaderFieldList = '';
        List<FieldInfo> result = new List<FieldInfo>();
        Set<String> headerFields = new Set<String>();
        List<FieldInfo> headerList = (List<FieldInfo>) JSON.deserialize(getPurchaseOrderHeaderFieldList(), List<FieldInfo>.class);
        Set<String> readOnlyFields = new Set<String>();
        
        for(Integer i = 0; i < headerList.size(); i++){
            headerFields.add(headerList[i].field);
        }
        
        try {
            // get the supplier invoice header field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Purchase_Order__c', 'Purchase_Order_Additional_Info_Header');
            
            // get the read only fields
            List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('Purchase_Order__c', 'Purchase_Order_RO');
            for (Integer i = 0; i<fieldInfoListRO.size(); i++){
                readOnlyFields.add(fieldInfoListRO[i].field);
            } 
            
            fieldInfoList.remove(0);    // Remove Id field from the list
            
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                if (!headerFields.contains(fieldInfoList[i].field)) {
                    if (fieldInfoList[i].field == 'Approval_Status__c' || fieldInfoList[i].field == 'Status__c' || (po.Type__c == PurchaseOrderService.PO_TYPE_SUBCONTRACT && fieldInfoList[i].field == 'Delivery_Facility__c')) {  
                        fieldInfoList[i].editable = false;
                    }
                    else if (readOnlyFields.contains(fieldInfoList[i].field)){
                        fieldInfoList[i].editable = false;
                    }
                    
                    result.add(fieldInfoList[i]);
                }
            }
            purchaseOrderAddlHeaderFieldList = (result.size() > 0) ? JSON.serialize(result) : '';
        }
        catch (FieldInfo.EmptyFieldSetMemberException e) {
            purchaseOrderAddlHeaderFieldList = '';
        }
        
        return purchaseOrderAddlHeaderFieldList;
    }
    
    @RemoteAction
    public static JsonResult getPODetails(Id poId, String clone) { 
        String objectName = 'Purchase_Order__c';
        String headerFieldset = 'Purchase_Order_Header';  
        String addlHeaderFieldset = 'Purchase_Order_Additional_Info_Header';  
        Set<String> addlFields = new Set<String>{'Supplier__c', 'Supplier__r.Id', 'Supplier__r.Name', 'Supplier__r.Invoice_Matching__c', 'Supplier__r.Default_Receiving_Tolerance__c', 'Company__r.Id','Company__r.Name','Purchase_Agreement__c'};
        string whereClause = 'Id  = :poId';
        
        String queryString = util.generateQueryFromFieldSet(objectName, new Set<string>{ headerFieldset, addlHeaderFieldset }, addlFields, whereClause);
        List<Purchase_Order__c> po = database.query(queryString);   
        
        if ( clone != null && clone == '1'){ // KNDY-10509
            // Copy the PO
            Purchase_Order__c poClone = po[0].clone(false, true);
            // reset fields
            poClone.Status__c = 'Open';
            poClone.Approval_Status__c = 'Pending Authorization';
            poClone.Need_Date__c = null;
            poClone.Order_Date__c = null;
            poClone.Date_Closed__c = null;
            poClone.Transaction_Date__c = null;
            poClone.Purchase_Agreement__c = null;
            poClone.MRP_Plan__c = null;
            User u = [select Id, Name from User where Id = :UserInfo.getUserID()];
            poClone.Buyer__c = u.Id;
            poClone.Buyer__r = u;
            po.clear();
            po.add(poClone);	
        }
        return new JsonResult(po, po.size());
    }
    
    @RemoteAction 
    public static JSONResult getCompanyInfo(Id companyId){ //KNDY-11133
        JSONResult result = new JSONResult();
        if (companyId != null){
            Company__c company = CompanyService.getCompanyInfo(companyId);
            result.success = true;
            result.records = new List<Company__c>{company};
            result.total = 1;
        }
        return result;
    }
    
    @RemoteAction
    public static JSONResult getSupplierDefaults( Id supplierId){
        JSONResult result = new JSONResult();
        list<Supplier__c> suppliers = [ select Id, Payment_Term__c, Payment_Term__r.Id, Payment_Term__r.Name, Invoice_Matching__c, Default_Receiving_Tolerance__c, Currency__c, Currency__r.Id, Currency__r.Name, Remit_To__c, Remit_To__r.Id, Remit_To__r.Name,FOB_Term__c, FOB_Term__r.Id, FOB_Term__r.Name
                                     From Supplier__c where Id = :supplierId ];
        
        if( suppliers.size() == 1 ){
            Supplier__c supp = suppliers[0];
            result.success = true;
            result.total = 1;
            result.records = new List<Supplier__c>{supp};
        }
        return result;
    }
    
    public String getReturnUrl(){
        String pageRef;
        
        if (po != null && po.id != null ){
            pageRef =  '/' + po.Id;
        }
        else{
            Schema.DescribeSObjectResult dsr = Purchase_Order__c.SObjectType.getDescribe();
            pageRef = '/' + dsr.getKeyPrefix();
        }
        
        return pageRef;
    }

    public String getDeleteUrl(){
        String pageRef;
        Schema.DescribeSObjectResult dsr = Purchase_Order__c.SObjectType.getDescribe();
        pageRef = '/' + dsr.getKeyPrefix();
        return pageRef;
    }
    
    // Returns List of POLines records order by Line__c Asc
    // the max line number is last record in list
    @RemoteAction 
    public static JsonResult getPOLines(GridRelatedListController.GridRelatedListConfig config, String clone, List<String>allFields) {
        list<POLineWrapper> result = new list<POLineWrapper>();
        Id parentId = (config.parentRecord != null && String.isNotBlank(config.parentRecord.Id)) ? config.parentRecord.Id : '';
        set<string> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
        String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';
        
        string whereClause = parentfield + ' = :parentId';
        
        if(String.isNotBlank(config.sortField)){
            whereClause += ' ORDER BY ' + config.sortField;
            if(String.isNotBlank(config.sortOrder)){
                whereClause += ' ' + config.sortOrder;
            }
        }
        
        SOQLUtil soql = new SOQLUtil(config.objectName);
        soql.addFields(new Set<String>(allFields));
        soql.addFields(addlFields);
        soql.setWhereClause(whereClause);
        List<Purchase_Order_Line__c> poLinesList = database.query(soql.getQuery());

        if ( clone != null && clone == '1'){ // KNDY-10509
            List<Purchase_Order_Line__c> clonedLines = new List<Purchase_Order_Line__c>();
            for (Purchase_Order_Line__c line : poLinesList){
                // Copy the line
                Purchase_Order_Line__c clonedLine = line.clone(false,true);
                // Reset field values
                clonedLine.Approved__c = false;
                clonedLine.Name = '';
                clonedLine.Date_Added__c = system.today();
                clonedLine.Date_Closed__c = null;
                clonedLine.Date_Last_Changed__c = system.today();
                clonedLine.Need_Date__c = null;
                clonedLine.Promise_Date__c = null;
                clonedLine.Latest_Promise_Date__c = null;
                clonedLine.Quantity_Received__c = 0;
                clonedLine.Status__c = 'Open';
                clonedLine.Sales_Order_Line__c = null;
                clonedLine.Sales_Order__c = null;
                clonedLine.Purchase_Order__c = null;
                clonedLine.Contract_Line__c = null;
                clonedLine.MRP_Plan__c = null; 
                clonedLine.Requisition_Number__c = null; 
                clonedLine.Work_Order__c = null;
                clonedLine.Quantity_Returned_to_Supplier__c = null;
                clonedLine.Quantity_Returned_to_Supplier_for_Credit__c = null;
                clonedLine.Quantity_Shipped__c = 0;
                clonedLine.Quantity_Matched__c = 0;
                clonedLine.Quantity_Credited__c = 0;
                clonedLine.Quantity_To_Stock__c = 0;
                clonedLine.Amount_Credited__c = null;
                clonedLine.Putaway_Location__c = null;
                //clonedLine.Quantity_Uninvoiced__c = null;
                 
                if(line.Accounting_Segment__c != null ){
                    Accounting_Default__c accountingDefault = new Accounting_Default__c();
                    clonedLine.Accounting_Segment__c = null;
                    if (line.Accounting_Segment__r != null){
                        accountingDefault = line.Accounting_Segment__r.clone(false,true);
                        clonedLine.Accounting_Segment__r = accountingDefault;
                    }
                }
                clonedLines.add(clonedLine);
            }
            poLinesList.clear();
            poLinesList.addAll(clonedLines);
        } 

        for (Integer i = 0; i< poLinesList.size() ; i++) {
            POLineWrapper lineWrapper = new POLineWrapper(poLinesList[i]);
            // KNDY-10509 This will create a new Accounting Default Record for clones
            if ( clone != null && clone == '1' && lineWrapper.poLine.Accounting_Segment__r != null){ 
                lineWrapper.segments = lineWrapper.poLine.Accounting_Segment__r; 
            }
            result.add(lineWrapper);
        }
        return new JsonResult(result, result.size());
    }
    
    public String getAllFields(){
        if (allFieldsMap.keySet().isEmpty()){
            getCustomViewFields();
        }

        return JSON.serialize(allFieldsMap.keySet());
    }
    @RemoteAction
    public static JsonResult createPOLines(String reqIdsStr){
       
       List<POLineWrapper> result = new List<POLineWrapper>();
       Map<Requisition_Line__c,Purchase_Order_Line__c> poLinesMap = new Map<Requisition_Line__c,Purchase_Order_Line__c>();

       List<Id> reqLineIds = (List<Id>)JSON.deserialize(reqIdsStr, List<Id>.class);
       if(reqLineIds != null && reqLineIds.size() > 0){ 
            String whereClause = ' Id = :reqLineIds ORDER BY Line__c ASC '; 
            List<Requisition_Line__c> reqLinesList = new List<Requisition_Line__c>();
           
			SOQLUtil soql = new SOQLUtil('Requisition_Line__c');
            soql.addFields('Requisition_Release');
            soql.addFields(new set<string>{'Id','Item__r.Id','Item__r.Description__c','Purchasing_UOM__r.Id','Purchasing_UOM__r.Id','Purchasing_UOM__c','Delivery_Location__c','Delivery_Location__r.Id','Delivery_Location__r.name','Facility__c','Facility__r.Id','Facility__r.name','Facility__r.Facility_Identifier__c' ,'Requisition__r.Sales_Order__c','Requisition__r.Company__c'});
			soql.setWhereClause(whereClause);
			reqLinesList = Database.query(soql.getQuery());   
 			Integer count = 0; 

            List<String> polineFields = new List<String>();
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            String polineObjName = '';
            if (KSE.Namespace != ''){
                polineObjName = KSE.Namespace + '__purchase_order_line__c';
            }else{
                polineObjName = 'purchase_order_line__c';
            }
            Schema.SObjectType leadSchema = schemaMap.get(polineObjName);
            Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap(); //get all fields from purchase order line

            for (String fieldName: fieldMap.keySet()) {
                if ((fieldMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.Boolean) &&
                    (fieldName.endsWith('__c')) &&
                    (fieldMap.get(fieldName).getDescribe().isUpdateable())) {
                    polineFields.add(fieldName); //add just the boolean types to the list
                }
            }

            for(Requisition_Line__c reqLine : reqLinesList){
                    count++;
                    Purchase_Order_Line__c POLObj = new Purchase_Order_Line__c();
                
              //  if(reqLine.Requisition__r.Source__c != 'Drop Ship'){
                    //fields in the Fieldset of Req. Line
					POLObj.Line__c = count;
                    POLObj.Requisition_Number__c = reqLine.Requisition__c;
                    POLObj.Item__c = reqLine.Item__r.id;
                    POLObj.Item__r = reqLine.Item__r;
                    POLObj.Description__c = reqLine.Item__r.Description__c;
                	POLObj.Requestor_Notes__c = reqLine.Requester_Notes__c;
                    POLObj.Purchase_UOM__c = reqLine.Purchasing_UOM__r.Id;
                    POLObj.Purchase_UOM__r = reqLine.Purchasing_UOM__r;
                    POLObj.Delivery_Facility__c = reqLine.Facility__r.Id;
                    POLObj.Delivery_Facility__r = reqLine.Facility__r;
                    
                    if(reqLine.Delivery_Location__r.Id != null){
                    POLObj.Delivery_Location__c = reqLine.Delivery_Location__r.Id;
                    POLObj.Delivery_Location__r = reqLine.Delivery_Location__r;
                    }else{
                        Company__c defaultCompany = CompanyService.getCompanyInfo(reqLine.Requisition__r.Company__c);
						POLObj.Delivery_Location__c = defaultCompany.Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__c;
                        POLObj.Delivery_Location__r = defaultCompany.Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__r;
                    }
                

                    POLObj.Supplier__c = reqLine.Supplier__c;
                    POLObj.Sales_Order_Line__c = reqLine.Sales_Order_Line__c;
                    POLObj.Unit_Price__c = reqLine.Unit_Price__c;
                    POLObj.Status__c = 'Open';
                    
                    POLObj.Approved__c = false;
					POLObj.Date_Added__c = system.today();
                    POLObj.Date_Closed__c = null;
                    POLObj.Date_Last_Changed__c = system.today();

                    POLObj.Contract_Line__c = null;
                    POLObj.Contracted__c = true;
                    POLObj.Need_Date__c = reqLine.Need_Date__c;
                    POLObj.Order_Quantity__c = reqLine.Quantity_Ordered__c;
                    POLObj.Consigned__c = false;
                    
                    for (string booleanfield : polineFields){
                        if (POLObj.get(booleanfield) == null){
                            POLObj.put(booleanfield, false);
                        }
                    }
                    
                    if (reqLine.Requisition__r.Source__c == 'Drop Ship'){
                    	POLObj.Invoice_Matching__c = 'Two Way';
                    }
                    POLObj.Accounting_Segment__c = null;
                poLinesMap.put(reqLine,POLObj);       
              /*  }else{
                    poLinesMap.clear();
                    break; // don't do any thing.
                }*/     
           }
           
       }
       for (Requisition_Line__c reqLine : poLinesMap.keySet() ) {
            POLineWrapper lineWrapper = new POLineWrapper(reqLine, poLinesMap.get(reqLine));
            lineWrapper.amount = reqLine.Quantity_Ordered__c * KSE.addQuantityToField(reqLine.Unit_Price__c,0);
            result.add(lineWrapper);
       } 
      return new JsonResult(result, result.size());
    }
    
    public string getPOLinesConfigJson() {
        String configStr = JSON.serialize(this.poLinesConfig);
        return configStr;
    }
    
    public string getPOLinesFieldList() {
        if (poLinesFieldList == null && poLinesConfig != null) {
            // get the purchase agreement lines field info list
            List<FieldInfo> fieldInfoList = allFieldsMap.values();
            List<FieldInfo> segmentList = (List<FieldInfo>) JSON.deserialize(getSegmentLinesFieldList(), List<FieldInfo>.class);

            List<FieldInfo> taxFields = null;
            if(HasTax){
                try{
                    taxFields = taxSvc.getDisplayFieldSet(Purchase_Order__c.getSobjectType());
                    if(taxFields != null){
                        fieldInfoList.addAll(taxFields);
                    }
                }catch(FieldInfo.EmptyFieldSetMemberException e) {
                    System.debug('#### Has Exception');
                    System.debug(e);
                }
            }
            
            // set the wrapper class prefix
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                if (fieldInfoList[i].field == 'Line_Value__c') {
                    fieldInfoList[i].title = 'Amount';
                    fieldInfoList[i].field = 'amount';
                }
                else{
                    fieldInfoList[i].field = 'poLine.' + fieldInfoList[i].field;
                }
            }
            
            for(Integer i = 0; i < segmentList.size(); i++){
                FieldInfo segmentField = segmentList[i];
                segmentField.field = 'segments.' + segmentField.field;
                fieldInfoList.add(segmentField);
            }
            poLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return poLinesFieldList;
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
            
    
            // get the segment lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(segmentLinesConfig.objectName, segments);
            
            segmentLinesFieldList = JSON.serialize(fieldInfoList);
        }
        return segmentLinesFieldList;
    }
    /*
     *  getUIFieldNames method prepares and puts the UI field names in a list and returns it.
     *
     *  @param  fieldInfoList
     *  @return List<String>    
     *
     */
    private List<String> getUIFieldNames(List<FieldInfo> fieldInfoList){
        List<String> fieldNames = new List<String>();

        for(FieldInfo f: fieldInfoList){
            if(f.field != 'Id'){
                fieldNames.add('poLine.' + f.field);   
            }
            
        }

        return fieldNames;
    }
    
    /*
     *  getCustomViews method prepares the list of views to be listed on the dropdown box in the UI
     *
     *  @param  fieldInfoList
     *  @param  fieldName
     *  @return Integer    
     *
     */
    public String getCustomViews() { 
        List<SelectListItem> viewList = new List<SelectListItem>();
        List<Grid_Views_Config__c> customViewList = this.customViewList == null ? KSE.getGridViews('POLinesGrid') : this.customViewList;
        system.debug(logginglevel.info, 'customViewList-----' +customViewList);
        // use for preventing duplicate field set values in grid views
        Set<String> existingViews = new Set<String>();

        existingViews.add('default');

        for(Grid_Views_Config__c gvConfig: customViewList){

            if (!existingViews.contains(gvConfig.Fieldset_Name__c.toLowerCase())){

                viewList.add(new SelectListItem(gvConfig.Fieldset_Name__c, gvConfig.View_Name__c));
                existingViews.add(gvConfig.Fieldset_Name__c.toLowerCase());
                system.debug(logginglevel.info, 'existingViews-----' +existingViews);

            }
        }

        if (customViewList.isEmpty() || customViewList[0].View_Dropdown_Index__c == 0){
            viewList.add(new SelectListItem('Default', 'Default'));
        } else {
            viewList.add(0,new SelectListItem('Default', 'Default'));
        }
        system.debug(logginglevel.info, 'viewList-----' +customViewList+ '---JSON.serialize(viewList)--'+ JSON.serialize(viewList));
        return JSON.serialize(viewList);
    }
    /*
     *  getCustomViewFields method fetches list of fields on associated with a fieldset that are part of the custom views
     *
     *  @return String    
     *
     */
    public String getCustomViewFields() {

        Map<String, List<String>> customViewFieldsMap = new Map<String, List<String>>();
        
        List<Grid_Views_Config__c> customViewList = this.customViewList == null ? KSE.getGridViews('POLinesGrid') : this.customViewList;

        customViewList.add(new Grid_Views_Config__c(Fieldset_Name__c = 'Default'));

        for(Grid_Views_Config__c gvConfig: customViewList){

            List<String> fieldNames = new List<String>();
            //Ignore the fieldset that has been loaded already
            if(customViewFieldsMap.containsKey(gvConfig.Fieldset_Name__c)){
                continue;
            }

            try {

                List<FieldInfo> fieldList = FieldInfo.fetchJsonFieldInfos('Purchase_Order_Line__c', gvConfig.Fieldset_Name__c);
                for (FieldInfo fi : fieldList){
                    if (!allFieldsMap.containsKey(fi.field) || fi.required){
                        allFieldsMap.put(fi.field, fi);
                    }
                }
               
                fieldNames = getUIFieldNames(fieldList);

            } catch (FieldInfo.EmptyFieldSetMemberException e) {
                //ignnore invalid fieldsets
            }
            
            customViewFieldsMap.put(gvConfig.Fieldset_Name__c, fieldNames);
        }
        return JSON.serialize(customViewFieldsMap);
    }
    
    @RemoteAction
    public static JSONResult getServiceItem( Id itemSpecId, Id companyId, Id facilityid, Date activeStandardCostDate){
        JSONResult result = new JSONResult();
        list<Component__c> serviceComponents = [ select Id, Component_Item__c, Component_Item__r.Source__c, 
                Component_Item__r.Name,
                Component_Item__r.Description__c,
                Component_Item__r.Purchasing_UOM__r.Name, Component_Item__r.Purchasing_UOM__c, Component_Item__r.Stocking_UOM__c, Component_Item__r.Stocking_UOM__r.Name 
                From Component__c where Assembly_Item_Specification__c=:itemSpecId and Component_Item__r.Source__c = 'Outside Processing'];
        
        if( serviceComponents.size() == 1 ){
            Item__c item = serviceComponents[0].Component_Item__r;
            result.total = 1;
            result.records = new List<Item__c>{item};
        }
        return result;
    }
    
    
    @RemoteAction 
    public static JsonResult cancelPO(Id poId ) { 
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try{
            result = PurchaseOrderService.headerActions(poId, 'Cancelled');
            if(!result.success){
                result.addMessage(Label.Unable_to_cancel_the_purchase_order , ApexPages.Severity.ERROR);
            }
        }
        catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage('An Error occured : ' + e.getMessage() , ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    @RemoteAction
    public static JsonResult closePO(id poId ) { 
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try{
            result = PurchaseOrderService.headerActions(poId, 'Closed');
            if(!result.success){
                result.addMessage(Label.Unable_to_close_the_purchase_order, ApexPages.Severity.ERROR);
            }
        }
        catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage('An Error occured : ' + e.getMessage() , ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult approvePO(Id poId ) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        
        Set<String> objectName = new Set<String>();

        if (KSE.NamespaceUU != ''){
            objectName.add(KSE.NamespaceUU+'Purchase_Order__c');
            objectName.add(KSE.NamespaceUU+'Purchase_Order_Line__c');
        }
        else{
            objectName.add('Purchase_Order__c');
            objectName.add('Purchase_Order_Line__c');
        }

        Boolean isAdmin = false;
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(profileName != null && profileName.equalsIgnoreCase('System Administrator')){
            isAdmin = true;
        }

        List<ProcessDefinition> ProcessDefinitionList = [SELECT TableEnumOrId FROM ProcessDefinition WHERE State = 'Active' and TableEnumOrId in :objectName] ;
        if(!isAdmin && ProcessDefinitionList.size() > 0) {
            result.success = false;
            String errorMsg = Label.You_cant_approve_the_source_document;
            errorMsg = errorMsg.replaceAll('<SOURCE DOC>', 'purchase order');
            result.addMessage(errorMsg, ApexPages.Severity.ERROR);
        }else{
        	try{
	            result = PurchaseOrderService.headerActions(poId, 'Approved');
	            if(!result.success){
	                result.addMessage(Label.Unable_to_approve_the_purchase_order, ApexPages.Severity.ERROR);
	            }
	        }
	        catch (Exception e) {
	            Database.rollback(sp);
	            result.success = false;
	            result.addMessage('An Error occured : ' + e.getMessage() , ApexPages.Severity.ERROR);
	        }
        }
        return result;
       /* try{
            result = PurchaseOrderService.headerActions(poId, 'Approved');
            if(!result.success){
                result.addMessage(Label.Unable_to_approve_the_purchase_order, ApexPages.Severity.ERROR);
            }
        }
        catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage('An Error occured : ' + e.getMessage() , ApexPages.Severity.ERROR);
        }
        return result;*/
    }

    @RemoteAction
    public static JsonResult deletePO(Id poId ) { 
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try{
            result = PurchaseOrderService.headerActions(poId, 'Delete');
            if(!result.success){
                result.addMessage(Label.Unable_to_delete_the_purchase_order, ApexPages.Severity.ERROR);
            }
        }
        catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage('An Error occured : ' + e.getMessage() , ApexPages.Severity.ERROR);
        }
        return result;
    }
    
//  Precondition - Argument poId is not null
    @RemoteAction
    public static JsonResult cancelLines(Id poId, List<POLineWrapper> poLineWrappers, List<String> dateFields ) { 
        JsonResult result = new JsonResult();
        List<Purchase_Order_Line__c> poLines = new List<Purchase_Order_Line__c>();
        List<Purchase_Order_Line__c> invalidLines = new List<Purchase_Order_Line__c>();
        Savepoint sp = Database.setSavepoint();
        try{
            for (POLineWrapper line : poLineWrappers) {
                KendoUtils.UpdateDateFields(line.poLine, dateFields);
                if (line.poLine.Status__c == 'Open'){
                    poLines.add(line.poLine);
                }
                else{
                    invalidLines.add(line.poLine);
                }
            }
            if (poLines.size() > 0){
                result = PurchaseOrderService.cancelPOLines(poLines,false);
                if (result.success){
                    JSONResult poResult = getPODetails(poId, null);
                    result.records = poResult.records;
                    result.success = true;
                }
            }
            else{
                if (invalidLines.size() > 0){
                    result.success = false;
                    String lineNumbersStr = getErrorLineNumbers(invalidLines);
                    result.addMessage(Label.Selected_Lines_are_already_closed_or_cancelled + '- Lines ' + lineNumbersStr , ApexPages.Severity.ERROR);
                }
            }
        }
        catch (Exception e){
            Database.rollback(sp);
            result.success = false;
            result.addMessage('An Error occured : ' + e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

//  Precondition - Argument poId is not null
    @RemoteAction
    public static JsonResult closeLines(Id poId, List<POLineWrapper> poLineWrappers, List<String> dateFields ) { 
        JsonResult result = new JsonResult();
        List<Purchase_Order_Line__c> poLines = new List<Purchase_Order_Line__c>();
        List<Purchase_Order_Line__c> invalidLines = new List<Purchase_Order_Line__c>();
        Savepoint sp = Database.setSavepoint();
        try{
            for (POLineWrapper line : poLineWrappers) {
                KendoUtils.UpdateDateFields(line.poLine, dateFields);
                if (line.poLine.Status__c == 'Open'){
                    poLines.add(line.poLine);
                }
                else{
                    invalidLines.add(line.poLine);
                }
            }
            if (poLines.size() > 0){
                result = PurchaseOrderService.closePOLines(poLines,false);
                if (result.success){
                    JSONResult poResult = getPODetails(poId, null);
                    result.records = poResult.records;
                    result.success = true;
                }
            }
            else{
                if (invalidLines.size() > 0){
                    result.success = false;
                    String lineNumbersStr = getErrorLineNumbers(invalidLines);
                    result.addMessage(Label.Selected_Lines_are_already_closed_or_cancelled + '- Lines ' + lineNumbersStr , ApexPages.Severity.ERROR);
                }
            }
        }
        catch (Exception e){
            Database.rollback(sp);
            result.success = false;
            result.addMessage('An Error occured : ' + e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult getTax(Id poId, Purchase_Order__c po){
        JsonResult jr = new JsonResult();
        jr.records = new List<SObject>();
        if(taxSvc.taxServiceConfigured(Purchase_Order__c.getSobjectType().getDescribe().getLocalName(),po)){

            TaxService.TaxResult tr = taxSvc.getTax(poId);

            if(tr != null){
                jr.success = tr.isSuccess;
                jr.addMessage(tr.message, ApexPages.Severity.ERROR);
                

                if(tr.obj == null){
                    jr.records.add(new Purchase_Order__c(id=poId) );
                }else{
                jr.records.add(tr.obj);
                }
            }else{
                jr.success = true;
                jr.records.add(new Purchase_Order__c(id=poId));
            }
        }else{
            jr.success = false;
            jr.addMessage('Tax Service not implemented', ApexPages.Severity.ERROR);
            jr.records.add(new Purchase_Order__c(id=poId));
        }
        return jr;
    }
    
     @RemoteAction    
     public static JsonResult saveAction(Purchase_Order__c po, List<String> headerDateFields, List<POLineWrapper> updatedList, List<POLineWrapper> newList, List<POLineWrapper> deletedList, List<String> dateFields) {
        KendoUtils.UpdateDateFields(po, headerDateFields);
        
        if (updatedList.size() > 0) {
            for (POLineWrapper line : updatedList) {
                KendoUtils.UpdateDateFields(line.poLine, dateFields);
            }
        }
        
        if (newList.size() > 0) {
            for (POLineWrapper line : newList) {            	
                KendoUtils.UpdateDateFields(line.poLine, dateFields);
            }
        }
        
        JsonResult result = validateSave(po, updatedList, newList);
        if (result.success == false){
            return result;
        }
        Savepoint sp = Database.setSavepoint();
        list<Purchase_Order__c> records = new list<Purchase_Order__c>();        
              
        try {    
            DML.checkUpsertAsUser(po); upsert po;
            if (deletedList.size() > 0) {
                for (POLineWrapper line : deletedList) {
                    KendoUtils.UpdateDateFields(line.poLine, dateFields);
                }
            }
            // save invoice lines
            Set<String> invalidRowGUIDs = savePOLines(po, updatedList, newList, deletedList);

            if(PurchaseOrderManageExt.saveException == false){
                   if (result.success) {
                       records.add(po);
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
                   result.addMessage(' ' +'Not able to save the purchase order as there are '+numberOfLinesWithSegmentErrors+' segment validation errors. Please correct the highlighted line(s). ', ApexPages.Severity.ERROR);
                   result.addMessage(errorMessage, ApexPages.Severity.ERROR);
            }
        }
        catch (DMLException e){
            Database.rollback(sp);
            result.success = false;
            for(integer i=0; i<e.getNumDml(); i++) {
                result.addMessage(e.getDmlMessage(i), ApexPages.Severity.ERROR);
            }    
        }

        return result;
     }

     public static JSONResult validateSave(Purchase_Order__c po, List<POLineWrapper> updatedList, List<POLineWrapper> newList) {
        List<Purchase_Order_Line__c> poLinesWithErrors = new List<Purchase_Order_Line__c>();
        List<Purchase_Order_Line__c> poLinesWithMissingRequiredFields = new List<Purchase_Order_Line__c>();
        
        Set<Id> itemSpecIds = new Set<Id>();
        List<Purchase_Order_Line__c> polsToSave = new List<Purchase_Order_Line__c>();
        
        JSONResult result = new JSONResult();
        result.success = true;
        
        if (newList.size() > 0){
            for (POLineWrapper line : newList){
                itemSpecIds.add( line.poLine.Item_Specification__c );
                polsToSave.add(line.poLine);
                
                // If Header fields are entered after fields on a new line in UI
                // javascript will not default fields on new line from header
                // Checking here for any missing field defaults
                if (po.Delivery_Facility__c != null && line.poLine.Delivery_Facility__c == null){
                    line.poLine.Delivery_Facility__c = po.Delivery_Facility__c;
                }
                if (po.Delivery_Location__c != null && line.poLine.Delivery_Location__c == null){
                    line.poLine.Delivery_Location__c = po.Delivery_Location__c;
                }
                if (line.poLine.Item__c == null ||
                    line.poLine.Order_Quantity__c == null ||
                    line.poLine.Need_Date__c == null ||
                    line.poLine.Unit_Price__c == null ||
                    line.poLine.Delivery_Facility__c == null ||
                    line.poLine.Delivery_Location__c == null){
                    poLinesWithMissingRequiredFields.add(line.poLine);
                }
                
                if ( (line.poLine.Order_Quantity__c != null && line.poLine.Order_Quantity__c < 0)
                    || (line.poLine.Unit_Price__c != null &&line.poLine.Unit_Price__c < 0)){
                       poLinesWithErrors.add(line.poLine);
                }
            }
        }
        if(updatedList.size() > 0){
             for (POLineWrapper line : updatedList){
                itemSpecIds.add( line.poLine.Item_Specification__c );
                polsToSave.add(line.poLine);
                if (line.poLine.Item__c == null ||
                    line.poLine.Order_Quantity__c == null ||
                    line.poLine.Need_Date__c == null ||
                    line.poLine.Unit_Price__c == null ||
                    line.poLine.Delivery_Facility__c == null ||
                    line.poLine.Delivery_Location__c == null){
                    poLinesWithMissingRequiredFields.add(line.poLine);
                }
                
                if ( (line.poLine.Order_Quantity__c != null && line.poLine.Order_Quantity__c < 0)
                    || (line.poLine.Unit_Price__c != null &&line.poLine.Unit_Price__c < 0)){
                    poLinesWithErrors.add(line.poLine);
                }
             }
        }
        
        // process lines
        if (poLinesWithMissingRequiredFields.size() > 0){
            result.success = false;
            String lineNumbersStr1 = getErrorLineNumbers(poLinesWithMissingRequiredFields);
            result.addMessage(Label.Please_enter_required_fields + '- Lines ' + lineNumbersStr1 , ApexPages.Severity.ERROR);
        }
        
        if (poLinesWithErrors.size() > 0){
            result.success = false;
            String lineNumbersStr2 = getErrorLineNumbers(poLinesWithErrors);
            result.addMessage(Label.Order_Quantity_and_Unit_Price_cannot_be_negative + '- Lines ' + lineNumbersStr2 , ApexPages.Severity.ERROR);
        }
        
        //KNDY-10080 - Allow adding an item which is not a part of Purchase Agreement for drop ship PO
        if (po.Purchase_Agreement__c != null && po.Type__c != 'Drop Ship'){
            validatePurchaseAgreementRequirements(po, polsToSave, result);
        }
        
        JSONResult result2 = new JSONResult();
        if (po.Type__c == 'Drop Ship'){
            result2 = validateDropShipPOSave(po);
        }
        
        if (!result2.success){
            result.success = false;
            for (Map<String, String> error: result2.messages){
                result.addMessage(error.get('message'), ApexPages.Severity.ERROR);
            }
        }
        return result;
     }
     
     //PTP-62 - Prevent adding an item/UOM line which is not a part of Purchase Agreement
     // Lines to validate may or may not have Ids
     private static void validatePurchaseAgreementRequirements(Purchase_Order__c po, List<Purchase_Order_Line__c> polsToSave, JSONResult result){
        List<Purchase_Order_Line__c> linesNotInAgreement = new List<Purchase_Order_Line__c>();
        Set<String> itemUOMKeys = new Set<String>();//KNDY-11176
        for (Purchase_Order_Line__c pol : polsToSave){ 
            String itemId = (pol.Item__c != null)? String.ValueOf(pol.Item__c).substring(0, 15): '';
            String uomId = (pol.Purchase_UOM__c != null)? String.ValueOf(pol.Purchase_UOM__c).substring(0, 15): '';
            String key = itemId + '/' + uomId;
            itemUOMKeys.add(key);
        }
            
        //KNDY-10604 Initilize a Map to store the contract items based on its item (item -> Purchase UOM -> list of Lines)
        Map<String,List<Contract_Line__c>> mapItemIdUOMIdlistPALines = new Map<String,List<Contract_Line__c>>();
        mapItemIdUOMIdlistPALines =  ContractService.getContractLinesMap( new Set<Id> {po.Purchase_Agreement__c}, itemUOMKeys);
        
        for (Purchase_Order_Line__c pol : polsToSave){
                String itemId = (pol.Item__c != null)? String.ValueOf(pol.Item__c).substring(0, 15): '';
                String uomId = (pol.Purchase_UOM__c != null)? String.ValueOf(pol.Purchase_UOM__c).substring(0, 15): '';
                String key = itemId + '/' + uomId;

                if (mapItemIdUOMIdlistPALines.containsKey(key) &&
                    mapItemIdUOMIdlistPALines.get(key).size() != 0){
                    // Contract line with Item/UOM combination on POLine exists
                    List<Contract_Line__c> cls = mapItemIdUOMIdlistPALines.get(key);
                    if (cls.size() > 0){ 
                        // Many agreement lines for same item/uom combination
                        // can exist with different start and end dates
                        for (Contract_Line__c agreementLine : cls){
                             if (pol.Need_Date__c >= agreementLine.Contract_Start__c &&
                                     pol.Need_Date__c <= agreementLine.Contract_End__c){
                                     pol.Contract_Line__c = agreementLine.Id;
                                 break;
                             }
                        }
                        if (pol.Contract_Line__c == null){
                            // KNDY-10604 only look for item/uom combination on contract
                             pol.Contract_Line__c = cls[0].Id;
                        }
                    }
                }
                else{
                    linesNotInAgreement.add(pol); 
                }
         }
         if (linesNotInAgreement.size() > 0){
                result.success = false;
                String lineNumbersStr = getErrorLineNumbers(linesNotInAgreement);
                result.addMessage(Label.Cannot_add_lines_with_item_UOM_combination_not_in_Purchase_Agreement + ' - Lines ' + lineNumbersStr , ApexPages.Severity.ERROR);
         }
     }
     
     private static String getErrorLineNumbers(List<Purchase_Order_Line__c> poLinesWithErrors){
         List<Decimal> lineNumbers = new List<Decimal>();
         for (Purchase_Order_Line__c line: poLinesWithErrors) {
               lineNumbers.add(line.Line__c);
         }
         lineNumbers.sort();
         String lineNumbersStr = String.join(lineNumbers, ',');
         lineNumbersStr = lineNumbersStr.removeEnd(',');
         return lineNumbersStr;
     }
     
     
     private static JSONResult validateDropShipPOSave(Purchase_Order__c po){
        JSONResult result = new JSONResult();
        result.success = true;
        if (po.Type__c == 'Drop Ship' && po.Sales_Order__c == null){
           if (po.Id == null){
               result.success = false;
               result.addMessage(Label.Purchase_Order_creation_failed_Cannot_create_Drop_Ship_PO, ApexPages.Severity.ERROR);
           } 
        }
        return result;
     }
     
     public static Set<String> savePOLines(Purchase_Order__c po, List<POLineWrapper> updatedList, List<POLineWrapper> newList, List<POLineWrapper> deletedList) {
        Set<String> invalidRowGuids = new Set<String>();
        map<Id, Item__c> itemDetailsMap = new map<Id, Item__c>();
        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();

        if (updatedList.size() > 0) {
            for (POLineWrapper line: updatedList) {
                itemIds.add(line.poLine.Item__c);
                facilityIds.add(line.poLine.Delivery_Facility__c);
            }    
        }
        
        if (newList.size() > 0) {
            for (POLineWrapper line: newList) {
                itemIds.add(line.poLine.Item__c);
                facilityIds.add(line.poLine.Delivery_Facility__c);
                line.poLine.Purchase_Order__c = po.Id;
                line.poLine.Company__c = po.Company__c;
                line.poLine.Supplier__c = po.Supplier__c;
            }
            
            //Set consigned for all new lines. Query from Item cross reference and assign it
            map<string,Item_Cross_Reference__c> itemCrossReferenceMap = new map<string,Item_Cross_Reference__c>();
            Set<String> icrFields = new Set<String> { 'id','Name','Active__c','Approval_Status__c','Item__c','Item__r.Name','Item__r.Approved_Supplier_Required__c','Supplier__c','Ship_to_Facility__c','Consigned__c' } ;
            SOQLUtil icrSoql = new SOQLUtil ( 'Item_Cross_Reference__c' ) ;
            icrSoql.addFields ( icrFields ) ;
            icrSoql.setWhereClause ( 'Item__c IN :itemIds AND Active__c = true AND Approval_Status__c = \'Approved\'' ) ;

            for ( Item_Cross_Reference__c icr: Database.query ( icrSoql.getQuery() )  ) {
                itemCrossReferenceMap.put(''+icr.Item__c+icr.Ship_to_Facility__c+icr.Supplier__c,icr);      
            }

            for (POLineWrapper pol: newList){ // PTP-388
                String facilityKey = '' + pol.poLine.Item__c + pol.poLine.Delivery_Facility__c + pol.poLine.Supplier__c;
                string companyKey = '' + pol.poLine.Item__c + 'null' + pol.poLine.Supplier__c;
                pol.poLine.Consigned__c = false;
                pol.poLine.Item_Cross_Reference__c = null;
                if(itemCrossReferenceMap.containsKey(facilityKey)) { // FACILITY SPECIFIC
                    pol.poLine.Consigned__c = itemCrossReferenceMap.get(facilityKey).Consigned__c;
                    pol.poLine.Item_Cross_Reference__c = itemCrossReferenceMap.get(facilityKey).Id;
                }
                else if(itemCrossReferenceMap.containsKey(companyKey)) { // COMPANY WIDE
                    pol.poLine.Consigned__c = itemCrossReferenceMap.get(companyKey).Consigned__c;
                    pol.poLine.Item_Cross_Reference__c = itemCrossReferenceMap.get(companyKey).Id;
                }
            }
            
        }
        
        if (deletedList.size() > 0) {
            for (POLineWrapper line: deletedList) {
                itemIds.add(line.poLine.Item__c);
            }    
        }

         SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
         facilityQuery.addFields(new Set<String>{'Id', 'Name', 'Facility_Identifier__c'});
         facilityQuery.setWhereClause('Id in :facilityIds');
         Map<Id, Facility__c> mapFacility = new Map<Id,Facility__c>( (List<Facility__c>) Database.query(facilityQuery.getQuery()));

        Map<Id,Item__c> itemsMap = new Map<Id,Item__c>([select Id, Name, Source__c, Purchasing_UOM__c, Purchasing_UOM__r.Name, Stocking_UOM__c, Stocking_UOM__r.Name, Packaging_UOM__c from Item__c where Id IN :itemIds]);
        decimal conversionFactor;

        List<POLineWrapper> poLines = new List<POLineWrapper>();
        poLines.addAll(updatedList);
        poLines.addAll(newList);
        Map<Id, List<Id>> mapItemPackagingUOM = new Map<Id, List<Id>> ();
        for (POLineWrapper line: poLines) {
            if ( !mapItemPackagingUOM.containsKey (line.poline.Item__c) ) {
                List<Id> lstPkgUom = (List<Id>) JSON.deserialize( itemsMap.get(line.poline.Item__c).Packaging_UOM__c, List<Id>.class );
                mapItemPackagingUOM.put(line.poline.Item__c, lstPkgUom);
            }
            line.poLine.Item__r = itemsMap.get(line.poLine.Item__c);
            if ( line.poLine.Delivery_Facility__r == null || line.poline.Delivery_Facility__r.Facility_Identifier__c == null ) {
                line.poLine.Delivery_Facility__r = mapFacility.get(line.poLine.Delivery_Facility__c);
            }
            conversionFactor = KSE.getConversionFactor(itemsMap.get(line.poline.Item__c).Id, line.poline.Delivery_Facility__r.Facility_Identifier__c,line.poline.Purchase_UOM__c,itemsMap.get(line.poline.Item__c).Stocking_UOM__c, mapItemPackagingUOM.get(line.poline.Item__c) );
            line.poline.Quantity_To_Stock__c = (line.poline.Order_Quantity__c *  conversionFactor).setscale(6,System.RoundingMode.HALF_UP);
        }   

        
        //PTP-258 & PTP-270
        //building collections to hold all relevant data sets
        List<Accounting_Default__c> segmentsToBeValidated = new List<Accounting_Default__c>();
        List<Accounting_Default_Segment_Definition__c> segDefs = Accounting_Default_Segment_Definition__c.getAll().Values();
        Map<String, String> mapOfCounterToRowGUID = new Map<String, String>();
        Map<String, POLineWrapper> mapOfPOLineWrapperWithSegments = new Map<String, POLineWrapper>(); //list of wrappers with segments
        
        if (poLines.size() > 0) {
            // validate invoice lines
            Integer counter = 0; //Using a counter to keep tabs on wrappers being iterated over and use as key to store RowGuids in a map
            List<Purchase_Order_Line__c> lines = new List<Purchase_Order_Line__c>();
            for(POLineWrapper line : poLines) {
                line.poLine.Purchase_Order__r = po;
                lines.add(line.poLine);
                
                //Collect all segments from all lines in question and if weed out the null or blank lines
                Accounting_Default__c segment = line.segments;
                
                Boolean SegmentNotBlank = false; // Setting a boolean flag indicator even if one of the segments has data in it
                for(Accounting_Default_Segment_Definition__c sd : segDefs){ // looping through the Segment Def to compare against segments entered
                    if (segment != null && segment.get(sd.accounting_default_field__c) != null){ //A segment is entered since value is not null (blanks == null)
                        SegmentNotBlank = true; //Even if one of the segments is filled in then set the flag in order to validate that invoice line
                    }
                }
                if (SegmentNotBlank){
                    segmentsToBeValidated.add(segment); // Add to a list of segments to be validated
                    mapOfCounterToRowGUID.put(string.valueof(counter), line.rowGUID); // building a map of RowGUIDs
                    mapOfPOLineWrapperWithSegments.put(line.rowGUID, line); // this map is only used to do some quick searching for a hit on the wrapper
                    line.hasSegments = true; // set the status on the wrapper line
                }else{
                    line.segments = null; // Segments are blank so null out reference to prevent creation of Accounting Default record and mark hasSegments as false
                    line.hasSegments = false;
                }
                counter++; // Next invoice wrapper
            
            } // end of loop iterating over invoice line wrappers
            
            List<String> invalidCounters = new List<String>(); // create a list of all invalid record ids coming back from segment validation response
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
                    POLineWrapper lineInQuestion = mapOfPOLineWrapperWithSegments.get(invalidSegmentRowGuid);
                    
                    //We found the invoice line wrapper with invalid segments, add it to the error string to display it on UI
                    if(lineInQuestion.poLine.item__r.name != null){
                       listOfInvalidSegments.add(lineInQuestion.poLine.item__r.name+';   ');
                   }
                   if(lineInQuestion.rowGUID != null){
                       listOfInvalidRowGUID.add(lineInQuestion.rowGUID);
                   }
                }
            }
            // save lines
            invalidRowGuids = saveLines(po, poLines);
        }
        
        if (deletedList.size() > 0) {
            // delete lines
            invalidRowGuids = deleteLines(po, deletedList);
        }
        
        return invalidRowGuids;
     }
     
     public static Set<String> saveLines(Purchase_Order__c po, List<POLineWrapper> poLineWrappers) {
        List<Purchase_Order_Line__c> poLines = new List<Purchase_Order_Line__c>();
        List<Requisition_Line__c> reqLines = new List<Requisition_Line__c>();
        List<Accounting_Default__c> segments = new List<Accounting_Default__c>();
        List<Requisition_Cross_Reference__c> reqCrossRefs = new List<Requisition_Cross_Reference__c>();
         
        List<ID> DelSegments = new List<ID>();
        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        List<Date> dateList = new List<Date>();
        
        for (POLineWrapper item: poLineWrappers) {
            Purchase_Order_Line__c line = item.poLine;
            itemIds.add(line.Item__c);
            facilityIds.add(line.Delivery_Facility__c);
            dateList.add(line.Need_Date__c);     
        }
        
        ItemService.preCacheCostRecords(dateList, itemIds, facilityIds);        
        
        for (POLineWrapper item: poLineWrappers) {
            Purchase_Order_Line__c line = item.poLine;
            Accounting_Default__c segment = item.segments;
            if (segment != null) {
                segments.add(segment);
            }
            else {
                if( line.id != null && line.Accounting_Segment__c != null){
                    DelSegments.add(line.Accounting_Segment__c);
                    line.Accounting_Segment__c = null;  
                }
            }
            poLines.add(line);   
        }
        
        if(listOfInvalidSegments.size()>0){
            system.debug('there are invalid listOfInvalidSegments listOfInvalidSegments:'+listOfInvalidSegments);
            for(String localString: listOfInvalidSegments){
                segmentErrors = segmentErrors + localString ;
                numberOfLinesWithSegmentErrors = numberOfLinesWithSegmentErrors + 1 ;
                system.debug('there are invalid segments segmentErrors:'+segmentErrors);
            }
        }
        
        DML.checkUpsertAsUser(segments);
        try{
             errorMessage = 'before the upsert '+segments;
             DML.checkUpsertAsUser(segments); upsert segments;
             if(DelSegments.size() > 0){
                DML.deleteAsUser(DelSegments);
             }
        }catch( Exception e){
            saveException = true;
            errorMessage = 'An Error Occured  now : '+e.getMessage();
            if(errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                List<String> tempErr = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
                errorMessage = tempErr[1];
            }
        }
        
        for (POLineWrapper poLineWrapper: poLineWrappers) {
            Purchase_Order_Line__c line = poLineWrapper.poLine;
            Accounting_Default__c segment = poLineWrapper.segments;
            if (segment != null) {
                line.Accounting_Segment__c = segment.Id;
            }
        }
       
        DML.checkUpsertAsUser(poLines); upsert poLines;

         
        //KNDY-10084 Handling the Req. to PO without agreement
        for(POLineWrapper poLineWrapper: poLineWrappers){
            if(poLineWrapper.reqLine != null && poLineWrapper.poLine != null){
                //closing the req. lines after the PO created successfully.
                Requisition_Line__c reqLine = poLineWrapper.reqLine;
                reqLine.Quantity_Released__c = reqLine.Quantity_Ordered__c; //Req. Lines are always released fully.
                reqLine.Status__c = 'Closed';
                reqLines.add(reqLine);
                
                //Creating the cross refernce between  po and req. line
                Requisition_Cross_Reference__c reqRefs = new Requisition_Cross_Reference__c();
                reqRefs.Requisition_Line__c = poLineWrapper.reqLine.Id;
                reqRefs.Purchase_Order_Line__c = poLineWrapper.poLine.Id;
                reqCrossRefs.add(reqRefs);
            }        
        }
        DML.updateAsUser(reqLines);
        DML.insertAsUser(reqCrossRefs);
       
        return listOfInvalidRowGUID;
    }
    
    public static Set<String> deleteLines(Purchase_Order__c po, List<POLineWrapper> poLineWrappers) {
        List<Purchase_Order_Line__c> poLines = new List<Purchase_Order_Line__c>();
        List<Accounting_Default__c> segments = new List<Accounting_Default__c>();
        List<POLineWrapper> poLinesToDelete = new List<POLineWrapper>();
        
        //PTP-596 Make sure only lines committed to DB are processed for delete
        for (POLineWrapper item: poLineWrappers) {
            if (item.poLine.id != null){
                poLinesToDelete.add(item);
            }
        }
        
        for (POLineWrapper item: poLinesToDelete) {
            Purchase_Order_Line__c line = item.poLine;
            Accounting_Default__c segment = item.segments;
            if (line.Accounting_Segment__c != null && line.Accounting_Segment__r != null ){
                segments.add(line.Accounting_Segment__r);
            }
            poLines.add(line);
        }
        
        if (segments.size() > 0) {
            // delete segments
            DML.deleteAsUser(segments);
        }
        if (poLines.size() > 0) {
            //delete supplier invoice lines;
            DML.deleteAsUser(poLines);
        }
        return null;
    }
    
    public class POLineWrapper {
        public Purchase_Order_Line__c poLine { get; set; }
        public boolean hasSegments { get; set; } { hasSegments = false; }
        public Accounting_Default__c segments { get; set; }
        public double amount { get; set; } { amount = 0; }
        public String rowGUID{get;set;}
        public Requisition_Line__c reqLine{get;set;}
        
        public POLineWrapper(boolean hasSegments, Accounting_Default__c segments) {
            this.hasSegments = hasSegments;
            this.segments = segments;   
        }
        
        public POLineWrapper(Requisition_Line__c reqLine, Purchase_Order_Line__c poLine) {
            this.reqLine = reqLine;
            this.poLine = poLine;
        }
        
        public POLineWrapper(Purchase_Order_Line__c poLine) {
            Accounting_Default__c ad = new Accounting_Default__c();
            this.poLine = poLine;
            this.hasSegments = true;
            
            if (poLine.Accounting_Segment__c != null) { 
                ad = poLine.Accounting_Segment__r; 
            }
                    
            this.segments = ad;
            this.amount = (KSE.addQuantityToField(poLine.Order_Quantity__c, 0) * KSE.addQuantityToField(poLine.Unit_Price__c, 0)).setScale(2, RoundingMode.HALF_UP);
        }
     }
}
