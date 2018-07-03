public with sharing class RequisitionService {

    public static final String RQ_TYPE_PURCHASE_REQUISITION = 'Purchase Requisition'; 
    public static final String RQ_STATUS_DRAFT = 'Draft';
    public static final String RQ_STATUS_OPEN = 'Open'; 
    public static final String RQ_STATUS_CANCELLED = 'Cancelled';
    public static final String RQ_STATUS_CLOSED = 'Closed';
    public static final String RQ_APPROVAL_STATUS_APPROVED = 'Approved'; 
    public static final String RQ_APPROVAL_STATUS_PENDING = 'Pending Authorization'; 
    public static final String RQ_APPROVAL_STATUS_REJECTED = 'Rejected'; 
    public static final String RQ_SOURCE_DROPSHIP = 'Drop Ship'; 
    public static final String RQ_APPROVAL_FIELDSET_NAME = 'FlipReqApprovalStatus';
    public static final String RQ_DELETE = 'Delete';
    public static final String RQ_CLONE = 'Clone';
    private static SchemaUtil util = SchemaUtil.getInstance();
    public boolean isFacilityChecked = false;
    public static final String RQ_SOURCE_BACKTOBACK = 'Back To Back'; 


    public static void updateDeliveryAccount(){
        // Updates Requisition Delivery Account 
        // Address fields are taken from the Delivery Account
        // Delivery Account should be Ship to Customer for Drop Ship
        // Delivery Account should be Delivery Facility o/w

        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {

            List<Requisition__c> roList = new List<Requisition__c>();
            for (Requisition__c RQ : (List<Requisition__c>) Trigger.new){
                if (Trigger.isBefore && Trigger.isInsert) {
                    roList.add(RQ);
                } 
            }
            
            if(!roList.isEmpty()){
                updateDeliveryAccount(roList);
            }
        }
    }

    public static void updateDeliveryAccount(List<Requisition__c> requisitions){

        Set<Id> salesOrderIds = new Set<Id>();

        for (Requisition__c RQ : requisitions){
            if (RQ.Sales_Order__c != null){
                salesOrderIds.add(RQ.Sales_Order__c);
            }
        }
        Map<Id, Sales_Order__c> salesOrderMap = new Map<Id, Sales_Order__c>([SELECT Id, Ship_to_City__c, Ship_to_Street__c, Ship_to_State__c, Ship_to_Zip_Code__c, Ship_to_Country__c  FROM Sales_Order__c WHERE Id IN :salesOrderIds]);
        
        for(Requisition__c RQ : requisitions){
            if(RQ.Type__c == RQ_TYPE_PURCHASE_REQUISITION){
                if(RQ.Sales_Order__c != null){
                    RQ.Deliver_To_City__c = salesOrderMap.get(RQ.Sales_Order__c).Ship_to_City__c;
                    RQ.Deliver_Street__c = salesOrderMap.get(RQ.Sales_Order__c).Ship_to_Street__c;
                    RQ.Deliver_To_State__c = salesOrderMap.get(RQ.Sales_Order__c).Ship_to_State__c;
                    RQ.Deliver_To_Zip_Code__c = salesOrderMap.get(RQ.Sales_Order__c).Ship_to_Zip_Code__c;
                    RQ.Deliver_To_Country__c = salesOrderMap.get(RQ.Sales_Order__c).Ship_to_Country__c;
                }
            }
        
        }
    }

    public static void updateRequisitionLinestoApproved(){

        set<Id> poIds = new set<Id>();
        for( SObject p: Trigger.New) {
            if (KSE.isFieldChanging('Approval_Status__c',p,Trigger.oldMap) && (p.get('Approval_Status__c') == 'Approved')){
                poIds.add(p.id);
            }
        }
        
        List<Requisition_Line__c> reqLinestoUpdate = [select id, name, Approved__c, Status__c from Requisition_Line__c where Requisition__c IN :poIds AND Approved__c = false AND Status__c = 'Open'];
        if (reqLinestoUpdate.size()!=0){
            for (Requisition_Line__c reqLine : reqLinestoUpdate){
                reqLine.Approved__c = True;
            }
            DML.updateAsUser(reqLinestoUpdate);
        }
        
    }
    
    public static void updateReqStatusonApproval(){
        
        if (Trigger.isUpdate){
            List<Requisition__c> ReqListNew = Trigger.New;
            List<Requisition__c> ReqListOld = Trigger.Old;
            for (integer i=0; i<ReqListNew.size(); i++){
                if((ReqListNew[i].Approval_Status__c <> ReqListOld[i].Approval_Status__c) 
                    && (ReqListNew[i].Approval_Status__c == 'Approved')
                    && (ReqListNew[i].Status__c == 'Draft')) {
                    ReqListNew[i].Status__c = 'Open';
                }
            }
        }
    }

    //PTP-690 Approval process for Requisition header
    public static void flipReqApprovalStatus_headerchange(){
        
        if (Trigger.isUpdate){
            List<Requisition__c> ReqListNew = Trigger.New;
            for (Requisition__c p : ReqListNew){
                Boolean flipReqStatus = false;
                for(String str: util.getFieldsFromFieldSetString(Requisition__c.sObjectType , RQ_APPROVAL_FIELDSET_NAME)){
                    if (KSE.isFieldChanging(str, p, Trigger.oldMap)){
                        flipReqStatus = true;
                        break;
                    }
                }
                 if (flipReqStatus && p.Approval_Status__c == RQ_APPROVAL_STATUS_APPROVED)
                    p.Approval_Status__c = RQ_APPROVAL_STATUS_PENDING;
            }
        }
    }

    //PTP-690 Approval process for Requisition Lines
    public static void flipReqApprovalStatus_linechange(){
        
        Set<id> reqIds = new Set<id>();
        Map<id, Requisition__c> reqMap = new Map<id, Requisition__c>();
        List<Requisition_Line__c> ReqLineListNew = Trigger.New;
        Boolean updateReq = false;
        if (Trigger.isInsert || Trigger.isUpdate){
            for (Requisition_Line__c rl : ReqLineListNew){
                reqIds.add(rl.Requisition__c);
            }
            //Drop ship requisitions cannot be updated, so ignore drop ship reqs
            List<Requisition__c> reqList = [select id, name, Status__c, Approval_Status__c, Source__c from Requisition__c where id in :reqIds and (Source__c != :RQ_SOURCE_DROPSHIP and Source__c != :RQ_SOURCE_BACKTOBACK)]; //KNDY-13447
            reqMap.putAll(reqList);
            //for all req line insert just flip the approval status to pending
            if (Trigger.isInsert){
                for (Requisition_Line__c rl : ReqLineListNew){
                    if (reqMap.containsKey(rl.Requisition__c)){
                        if (reqMap.get(rl.Requisition__c).Approval_Status__c == RQ_APPROVAL_STATUS_APPROVED){
                            reqMap.get(rl.Requisition__c).Approval_Status__c = RQ_APPROVAL_STATUS_PENDING;
                            updateReq = true;
                        }
                    }
                }
            }
            //for req line updates, check if the field updated belongs to flipApprovalStatus field set and flip accordingly
            else {
                for (Requisition_Line__c rl : ReqLineListNew){
                    Boolean flipReqStatus = false;
                    for(String str: util.getFieldsFromFieldSetString(Requisition_Line__c.sObjectType , RQ_APPROVAL_FIELDSET_NAME)){
                        if (KSE.isFieldChanging(str, rl, Trigger.oldMap)){
                            flipReqStatus = true;
                            break;
                        }
                    }
                    if (flipReqStatus){
                        if (reqMap.containsKey(rl.Requisition__c)){
                            if (reqMap.get(rl.Requisition__c).Approval_Status__c == RQ_APPROVAL_STATUS_APPROVED){
                                reqMap.get(rl.Requisition__c).Approval_Status__c = RQ_APPROVAL_STATUS_PENDING;
                                updateReq = true;
                            } 
                        }
                    }  
                }
            }

            if (updateReq)
                DML.updateAsUser(reqMap.values());
        }
    }

    public JsonResult headerActions (id requisitionId, string status){

        JsonResult result = new JsonResult();
        List<Requisition_Line__c> reqLinestoUpdate = new List<Requisition_Line__c>();
        Boolean saveReq = false;
        Boolean deleteReq = true;
            
        if (!String.isEmpty(requisitionId)){
            Requisition__c req = [select Id, Name, Status__c, Approval_Status__c, (select Id, Name, Line__c, Status__c, Approved__c, Requisition__c, Requisition__r.Id, Requisition__r.Source__c, Quantity_Released__c, Quantity_Ordered__c, Sales_Order_Line__c, Sales_Order_Line__r.Fulfillment_Source__c, Sales_Order_Line__r.Quantity_Planned__c from Requisition_Lines__r) from Requisition__c where id = :requisitionId];
        
            //For Approval, just set the header to approved and exit the function
            if (status == RQ_APPROVAL_STATUS_APPROVED) {
                req.Approval_Status__c = req.Approval_Status__c == RQ_APPROVAL_STATUS_PENDING ? status : req.Approval_Status__c;
                saveReq = true;
            }
            else if (status == RQ_STATUS_CLOSED){
                req.Status__c = req.Status__c == RQ_STATUS_OPEN ? status : req.Status__c;
                saveReq = true;
                if (req.Requisition_Lines__r.size() > 0){
                    result = closeReqLines(req.Requisition_Lines__r);
                }
            }
            else if (status == RQ_STATUS_CANCELLED) {
                req.Status__c = req.Status__c == RQ_STATUS_OPEN ? status : req.Status__c;
                saveReq = true;
                if (req.Requisition_Lines__r.size() > 0){
                    result = cancelReqLines(req.Requisition_Lines__r);
                }
            }
            else if (status == RQ_DELETE) {
                for (Requisition_Line__c reql : req.Requisition_Lines__r){
                    if (reql.Approved__c){
                        deleteReq = false;
                        break;
                    }
                }
                if (deleteReq){
                    DML.deleteAsUser(new List<Requisition__c>{req});
                }
                else{
                    result.success = false;
                    result.addMessage(Label.Cannot_delete_requisition,ApexPages.Severity.ERROR);
                }
            }

            if (result.success == true){
                //Update the Requisition
                if (saveReq)
                    DML.updateAsUser(new List<Requisition__c>{req});
                
            }
        }
        else{
            result.success = false;
            result.addMessage(Label.Cannot_perform_any_action_save_the_requisition_to_proceed, ApexPages.Severity.ERROR);
        }

        return result;
    }

    public JsonResult cancelReqLines (List<Requisition_Line__c> reqLines){

        JsonResult result = new JsonResult();
        List<Requisition_Line__c> reqLinestoUpdate = new List<Requisition_Line__c>();
        List<Requisition_Line__c> openReqLineList = new List<Requisition_Line__c>();
        String errorReqLines = '';
        
        for(Requisition_Line__c reqLine : reqLines){
            if(reqLine.Status__c == 'Open'){
                openReqLineList.add(reqLine);
            }
            else{
                result.addMessage('Cannot cancel a closed/Cancelled Line' ,ApexPages.Severity.ERROR);
                result.success = false;
                return result;  
            }
        }
        for(Requisition_Line__c reqLine : openReqLineList){
            if(reqLine.Quantity_Released__c == 0 && reqLine.Approved__c){
                if(reqLine.Requisition__r.Source__c == RQ_SOURCE_DROPSHIP ||  reqLine.Requisition__r.Source__c == RQ_SOURCE_BACKTOBACK){
					result.addMessage('Cannot cancel a Drop Ship/Back to Back line' ,ApexPages.Severity.ERROR);
					result.success = false;
                }else{
                    reqLine.Status__c = 'Cancelled';
                    reqLinestoUpdate.add(reqLine);    
                }
                
            }
            else{
                errorReqLines = errorReqLines + reqLine.Line__c + ', ';
            }
        }
        
        if (!String.isBlank(errorReqLines)){
            errorReqLines = errorReqLines.subString(0,errorReqLines.length()-2);
            result.addMessage(Label.Only_approved_and_open_requisition_lines_with_no_purchase_order_lines_can_be_can+ errorReqLines ,ApexPages.Severity.ERROR);
            result.success = false;
            return result;
        }

        Savepoint sp = Database.setSavepoint();
        try{
            if (reqLinestoUpdate.size() >0 )
                DML.updateAsUser(reqLines);
        }
        catch(Exception e){
            Database.rollback( sp );
            result.success = false;
            result.addMessage('Cannot close/cancel', ApexPages.Severity.ERROR);
        }
        return result; 
    }


    public JsonResult closeReqLines (List<Requisition_Line__c> reqLines){

        JsonResult result = new JsonResult();
        List<Requisition_Line__c> reqLinestoUpdate = new List<Requisition_Line__c>();
        String errorReqLines = '';
        for (Requisition_Line__c rl : reqLines){
            if (rl.Approved__c && rl.Status__c == RQ_STATUS_OPEN){
                rl.Status__c = 'Closed';
                reqLinestoUpdate.add(rl);
            }
            else{
                errorReqLines = errorReqLines + rl.Line__c + ', ';
            }
        }

        if (!String.isBlank(errorReqLines)){
            errorReqLines = errorReqLines.subString(0,errorReqLines.length()-2);
            result.addMessage(Label.Only_approved_and_open_requisition_lines_can_be_closed + errorReqLines ,ApexPages.Severity.ERROR);
            result.success = false;
            return result;
        }

        Savepoint sp = Database.setSavepoint();
        try{
            if (reqLinestoUpdate.size() >0 )
                DML.updateAsUser(reqLines);
        }
        catch(Exception e){
            Database.rollback( sp );
            result.success = false;
            result.addMessage('Cannot close/cancel', ApexPages.Severity.ERROR);
        }
        return result; 
    }

    public JsonResult clone (id requisitionId){

        JsonResult result = new JsonResult();
        List<Requisition_Line__c> reqLinestoClone = new List<Requisition_Line__c>();
        Requisition__c reqtoClone = new Requisition__c();
            
        if (!String.isEmpty(requisitionId)){

            SOQLUtil soql_reqheader = new SOQLUtil('Requisition__c', TRUE);
            soql_reqheader.addFields(new Set<String>{'Id', 'name'});
            soql_reqheader.addFields(util.getAllCustomFieldsFromObject('','Requisition__c'));
            soql_reqheader.setWhereClause('id = :requisitionId');
            Requisition__c req = (Requisition__c)database.query(soql_reqheader.getQuery())[0]; 

            List<Requisition_Line__c> reqLineList = new List<Requisition_Line__c>();
            SOQLUtil soql_reqLine = new SOQLUtil('Requisition_Line__c', TRUE);
            soql_reqLine.addFields(new Set<String>{'Id', 'name'});
            soql_reqLine.addFields(util.getAllCustomFieldsFromObject('','Requisition_Line__c'));
            soql_reqLine.setWhereClause('Requisition__c = :requisitionId');
            reqLineList = database.query(soql_reqLine.getQuery()); 


            if (req.Source__c == 'Back To Back'){
                result.success = false;
                result.addMessage(label.Cannot_clone_a_Back_To_Back_Requisition, ApexPages.Severity.ERROR);

            }
            else if(req.Source__c != 'Drop Ship'){
            	system.debug(LoggingLevel.ERROR,'Cloning a back to back req with source: ' + req.Source__c);
                //Copy the requisition - use the clone function and clone the requisition
                reqtoClone = req.clone(false, false, false, false);
                reqtoClone.Transaction_Date__c = system.today();
                reqtoClone.Status__c = RQ_STATUS_DRAFT;
                reqtoClone.Approval_Status__c = RQ_APPROVAL_STATUS_PENDING;

                if (reqLineList.size() > 0){
                    for (Requisition_Line__c rl : reqLineList){
                        Requisition_Line__c reqLine = new Requisition_Line__c();
                        reqLine = rl.clone(false, false, false, false);
                        reqLine.Status__c = 'Open';
                        reqLine.Approved__c = false;
                        reqLine.Need_Date__c = system.today();
                        reqLine.Quantity_Released__c = 0;
                        reqLinestoClone.add(reqLine);
                    }
                }

                Savepoint sp = Database.setSavepoint();
                try {
                    //Insert the requisition
                    DML.insertAsUser(new List<Requisition__c>{reqtoClone});

                    if (reqLinestoClone.size() > 0){
                        for (Requisition_Line__c rlt : reqLinestoClone){
                            rlt.Requisition__c = reqtoClone.id;
                        }
                        DML.insertAsUser(reqLinestoClone);
                    }
                }
                catch(Exception e){
                    Database.rollback( sp );
                    result.success = false;
                    result.addMessage('An error occured: '+ e.getMessage(), ApexPages.Severity.ERROR);
                }

            }else{
                result.success = false;
                result.addMessage(label.Cannot_clone_a_Drop_Ship_Requisition, ApexPages.Severity.ERROR);

            }   
        }else{
            result.success = false;
            result.addMessage(Label.Cannot_perform_any_action_save_the_requisition_to_proceed, ApexPages.Severity.ERROR);   
        }

        if (result.success == true){
            result.records = new List<Requisition__c>{reqtoClone};
        }
        return result;
    }

    public JsonResult createPOfromReqLines (ID companyId, ID facilityId, List<Requisition_Line__c> reqLines){
        
        system.debug('inside req service');
        JsonResult result = new JsonResult();
        Set<id> reqIDs = new set<id>();
        Set<id> itemIDs = new set<id>();
        //list<Requisition_Line__c> reqLines = new list<Requisition_Line__c>();
        List<Contract_Line__c> ctLines = new List<Contract_Line__c>();
        Map<id, Contract_Line__c> ctLineMap = new map<id, Contract_Line__c>();
        Map<id,List<Contract_Line__c>> ctLineItemMap = new map<id,List<Contract_Line__c>>();
        Map<Id,Id> facDefaultLocMap = new Map<Id,Id>();
        set<Id> reqFacilities = new set<Id>();

        //Facility__c defaultFacilityLocation = null;
       
        //Collect all the item ids and get the agreement lines corresponding to the item ids collected
        for (Requisition_Line__c reqLine : reqLines){
            itemIDs.add(reqLine.Item__c);
            reqFacilities.add(reqLine.Facility__c); 
        }
        
        //KNDY-9478 - Removed the below from query
        //and Contract__r.Ship_to_Facility__c = :facilityId

        //ctLines = [select id, name, Company__c, Contract__c, Item__c, Contract_Quantity__c, Purchased_Quantity__c, Remaining_Quantity__c, Contract__r.Supplier__c from Contract_Line__c where Status__c = 'Open' and Item__c in :itemIDs];
        
        String whereClause = ' Item__c in :itemIDs and Status__c = \'Open\' and Remaining_Quantity__c > 0 ' 
                             + ' and Contract__r.Approval_Status__c = \'Approved\' and Contract__r.Status__c = \'Open\' and Contract__r.Company__c = :companyId  order by Line__c asc';
        

        SOQLUtil soql = new SOQLUtil('Contract_Line__c');
        soql.addFields('Line_Release');
        soql.addFields('Tiers');
        soql.addFields(new set<string>{'Id','Line__c','UOM__c','Purchased_Quantity__c','Invoice_Matching__c','Contract__r.Company__c','Contract__r.Company__r.Default_transaction_currency__c','Contract__r.Ship_to_Facility__c','Contract_Quantity__c', 'Location__c', 'Status__c','Contract__r.Payment_Term__c', 'Contract__r.Payment_Term__r.id', 'Contract__r.FOB_Term__c', 
                        'Contract__r.FOB_Term__r.id', 'Contract__r.Supplier__c','Contract__r.Supplier__r.Remit_To__c', 'Contract__r.Transportation_Mode__c', 'Consigned__c', 'Type__c','Contract__r.Contract_Number__c','Contract__c','Contract__r.Supplier__r.Remit_To__c',
                        'Contract__r.Unit_Price_Tolerance_Over__c','Contract__r.Quantity_Tolerance_Over__c','Contract__r.Amount_Tolerance__c',
                        'Contract__r.Supplier__r.Default_Receiving_Tolerance__c', 'Contract__r.Supplier__r.Invoice_Matching__c', 'Contract__r.Approval_Status__c','Contract__r.Status__c',
                        'Item__r.Description__c','Item__r.Purchasing_UOM__c', 'Contract__r.Company__r.Comp_currency__c', 'Contract__r.Currency__c'});
        soql.setWhereClause(whereClause);
        
        ctLines = Database.query(soql.getQuery());
        
        //It there are no contract lines for the selected requisition lines, then throw an error and exit from the process
        if (ctLines.size() == 0){
            result.success = false;
            result.addMessage(Label.No_Agreement_to_fulfill_Requisition, ApexPages.Severity.ERROR);
            return result;
        }

        //Verify the default Delivery location for the facility and throw error if the location is blank
        if(reqLines != null && reqLines.size() >0 ){
                facDefaultLocMap  = facilityLocationMap(companyId);
                system.debug(logginglevel.info,'facDefaultLocMap--->>'+facDefaultLocMap);
               // for(Id facilityId : reqFacilities){ 
                    Id defaultFacilityLocation = (facDefaultLocMap != null && facDefaultLocMap.size() >0) ? facDefaultLocMap.get(facilityId) : null;
        if (defaultFacilityLocation == null){
            result.success = false;
            result.addMessage(Label.Default_purchasing_delivery_location_is_not_available_for_the_facility, ApexPages.Severity.ERROR);
            return result;
        }
           
            }

        isFacilityChecked = true ;

        //Build a map of Item to List<Contract_Line__c> for further processing
        for (Contract_Line__c ctLine : ctLines){
            ctLineMap.put(ctLine.id, ctLine);
            List<Contract_Line__c> contractLines = new List<Contract_Line__c>();
            if(!ctLineItemMap.containsKey(ctLine.Item__c)){
                contractLines.add(ctLine);
                ctLineItemMap.put(ctLine.Item__c, contractLines.clone());
            }
            else {
                contractLines = ctLineItemMap.get(ctLine.Item__c);
                contractLines.add(ctLine);
                ctLineItemMap.put(ctLine.Item__c, contractLines.clone());
            }
        }
        
        //Loop through the Requisitions to find if they can be fulfilled, collect the list of requisitions that can be fulfilled
        Map<Id,boolean> hasReqLineFulfilled = new Map<Id,boolean>();
        List<RequisitionLineWrapper> reqLineWrapperList = new List<RequisitionLineWrapper>();
        for (Requisition_Line__c reqLine : reqLines){
            boolean isReqLineFulfilled = false;
            if (ctLineItemMap.containsKey(reqLine.Item__c)){
                List<Contract_Line__c> ctLinesTemp = ctLineItemMap.get(reqLine.Item__c);
                for (Contract_Line__c ctLinetoCheck : ctLinesTemp){
                    //PTP-617 include supplier check during release, if supplier is null do not consider, else check for supplier against agreement
                    ID supplierId = reqLine.Supplier__c == null ? ctLinetoCheck.Contract__r.Supplier__c : reqLine.Supplier__c;
                    if (reqLine.Quantity_Ordered__c <= ctLineToCheck.Remaining_Quantity__c && isReqLineFulfilled == false && supplierId == ctLineToCheck.Contract__r.Supplier__c && ctLineToCheck.Consigned__c == false){ 
                        //Build a wrapper list with Item ID, Req Line and contract line
                        //TODO: Modify the logic to create wrapper based on build option selected in the UI
                        RequisitionLineWrapper reqLineWrapper = new RequisitionLineWrapper();
                        reqLineWrapper.itemID = reqLine.Item__c;
                        reqLineWrapper.ctLine = ctLineToCheck;
                        reqLineWrapper.reqLine = reqLine;
                        reqLineWrapperList.add(reqLineWrapper);
                        //To make sure same contract line is not used to fulfill more than one requisition line
                        ctLinetoCheck.Purchased_Quantity__c += reqLine.Quantity_Ordered__c;
                        //to make sure same requisition is not fulfilled by more than one contract line
                        isReqLineFulfilled = true;
                    }
                }
            }
            //PTP-578 Show error when no contract or not enough qty on the contract
            if (isReqLineFulfilled == false)
                hasReqLineFulfilled.put(reqLine.Id,isReqLineFulfilled);
        }
        //PTP-578 Show error when no contract or not enough qty on the contract
        String errorReqLines = '';
        for (Requisition_Line__c reqLine : reqLines){
            if (hasReqLineFulfilled.containsKey(reqLine.id))
                errorReqLines = errorReqLines + reqLine.Name + ',';
        }

        if (errorReqLines != ''){
            errorReqLines = errorReqLines.subString(0,errorReqLines.length()-1);
            //PTP-665 Do not block the release when agreeent lines are not available to release req lines.
            //result.success = false;
            result.addMessage(Label.No_Agreement_to_fulfill_all_the_Requisitions , ApexPages.Severity.ERROR);
            //return result; 
        }

        result = createPOsfromReqWrapper(reqLineWrapperList, isFacilityChecked, reqFacilities); 
                
        return result;
    }
        
    //To get the default delivery location for all the facilities present in the company
    public static map<Id,Id> facilityLocationMap(Id companyId){
        
        map<Id,Id> facLocMap  = new map<Id,Id>();
        list<Facility__c> facList = new List<Facility__c>([select Id, Default_Purchasing_Delivery_Location__c from Facility__c where Company__c = :companyId]);
        for(Facility__c facility : facList){
               facLocMap.put(facility.id,facility.Default_Purchasing_Delivery_Location__c);                         
        }
        
        return facLocMap;
    }
        
    /*
    1. The PO Creation part is seperated out from the above method.
    2. No agreement validation is removed in the below function as the validation happens in the UI, before the user hits Generate PO button
    3. Supplier is always taken from the Agreement as the user selects the agreement in the UI
    4. Above method is not commented and will be reused when build options to create PO manually and automatically is introduced
    */
    public JsonResult createPOsfromReqWrapper(List<RequisitionLineWrapper> reqLineWrapperList, Boolean isFacilityChecked, set<Id> reqFacilities){

        Map<String, List<RequisitionLineWrapper>> uniquePOMap = new Map<String, List<RequisitionLineWrapper>>();
        JsonResult result = new JsonResult();
        Map<id,id> reqTocLine = new map<id,id>(); //Map of Req Line to Contract Line - this will be used to create the Req Cross Reference records
        Map<Integer, reqLinetoPOLineWrapper> reqLinetoPOLineConfig = new map<Integer, reqLinetoPOLineWrapper>();
        Map<Id,Id> facDefaultLocMap = new Map<Id,Id>();
        
        
        //Loop through the wrapper and create map of requisition wrappers grouped by Contract, so POs can be created for each contract
        for (RequisitionLineWrapper reqLineWrappertoRelease : reqLineWrapperList){
            string typeKey;
            if(reqLineWrappertoRelease.reqLine.Requisition__r.Source__c == 'Drop Ship' || reqLineWrappertoRelease.reqLine.Requisition__r.Source__c == 'Back To Back'){//KNDY-13447
                typeKey = reqLineWrappertoRelease.reqLine.Requisition__r.name;
                //Req lines with Sales order on credit hold should not be processed
                if(reqLineWrappertoRelease.reqLine.Requisition__r.Sales_Order__c != null && 
                    reqLineWrappertoRelease.reqLine.Requisition__r.Sales_Order__r.Credit_Hold__c &&
                    !reqLineWrappertoRelease.reqLine.Requisition__r.Sales_Order__r.Override_Credit_Hold__c){

                    result.success = false;
                    result.addMessage('Sales order(' + reqLineWrappertoRelease.reqLine.Requisition__r.Sales_Order__r.name + ') related to Requisition Line(' + 
                                    reqLineWrappertoRelease.reqLine.name + ') is on credit hold. Please override or clear the credit hold inorder to proceed.',
                                    ApexPages.Severity.ERROR);
                    return result;
                }

            }
            else
                typekey = '0';

            String uKey = typeKey + reqLineWrappertoRelease.ctLine.Contract__c;
            List<RequisitionLineWrapper> reqLineWrapperTemp = new List<RequisitionLineWrapper>();
            if(!uniquePOMap.containsKey(uKey)){
                reqLineWrapperTemp.add(reqLineWrappertoRelease);
                uniquePOMap.put(uKey, reqLineWrapperTemp.clone());
            }
            else {
                reqLineWrapperTemp = uniquePOMap.get(uKey);
                reqLineWrapperTemp.add(reqLineWrappertoRelease);
                uniquePOMap.put(uKey, reqLineWrapperTemp.clone());
            }
        }

        //if this function is invoked from createPOfromReqLines function, do not perform the facility check
        if (!isFacilityChecked){
            
            // Check and get the facility default delivery location for the requistions, throw error if you get null/empty value.
            if(reqLineWrapperList != null && reqLineWrapperList.size() >0 ){
                //Company Id would be the same for the Requisition or the Purchase Agreement
                Id companyId = reqLineWrapperList.get(0).reqLine.Requisition__r.Company__c == null ? reqLineWrapperList.get(0).ctLine.Contract__r.Company__c : reqLineWrapperList.get(0).reqLine.Requisition__r.Company__c;
                facDefaultLocMap  = facilityLocationMap(companyId);
                for(Id facilityId : reqFacilities){ 
                    Id defaultFacilityLocation = (facDefaultLocMap != null && facDefaultLocMap.size() >0) ? facDefaultLocMap.get(facilityId) : null;
                    if (defaultFacilityLocation == null){
                result.success = false;
                result.addMessage(Label.Default_purchasing_delivery_location_is_not_available_for_the_facility, ApexPages.Severity.ERROR);
                return result;
            }
        }
            }
        }

        //Create POs based on the unique PO map created in the above step
        Map<String, Purchase_Order__c> mapOfUniqueKeyToPO = new Map<String, Purchase_Order__c>();
        Map<String, List<Purchase_Order_Line__c>> mapOfUniqueKeyToPOLines = new Map<String, List<Purchase_Order_Line__c>>();
        Map<Id,Requisition_Line__c> mapOfUniqueReqLines = new Map<Id,Requisition_Line__c>();
        ID ctLineId;
        Integer tmp = 1;
        Purchase_Order_Line__c polTemp;
        for (String uKey : uniquePOMap.keyset()){
            for (RequisitionLineWrapper reqLineWrapper : uniquePOMap.get(uKey)){
                //Create PO Header only if it doesnt exist already
                if (!mapOfUniqueKeyToPO.containsKey(uKey)){
                    Purchase_Order__c POObj = new Purchase_Order__c();       
                    POObj.Approval_Status__c = 'Approved';
                    POObj.Company__c = reqLineWrapper.ctLine.Contract__r.Company__c;
                    POObj.Date_Closed__c = null;
                    // POObj.Last_Change_Date__c = system.today(); //KNDY-7997 - Deprecating Last_Change_Date__c field.
                    POObj.Order_Date__c = system.today();
                    POObj.Status__c = 'Open';
                    POObj.Supplier__c = reqLineWrapper.ctLine.Contract__r.Supplier__c;
                    //set PO Type to Drop ship for Drop Ship Requisitions
                    if (reqLineWrapper.reqLine.Requisition__r.Source__c == 'Drop Ship' || reqLineWrapper.reqLine.Requisition__r.Source__c == 'Back To Back'){
                        if (reqLineWrapper.reqLine.Requisition__r.Source__c == 'Drop Ship')
                        	POObj.Type__c = 'Drop Ship'; 
                        else
                            POObj.Type__c = 'Standard'; //KNDY-13443
                                 
                        POObj.Sales_Order__c = reqLineWrapper.reqLine.Requisition__r.Sales_Order__c;  
                        POObj.Deliver_to_Customer__c = reqLineWrapper.reqLine.Requisition__r.Ship_To_Customer__c;
                        POObj.Deliver_to_Address__c = reqLineWrapper.reqLine.Requisition__r.Ship_To_Customer__r.Address__c;
                        POObj.Deliver_To_City__c = reqLineWrapper.reqLine.Requisition__r.Deliver_To_City__c;
                        POObj.Deliver_To_Street__c = reqLineWrapper.reqLine.Requisition__r.Deliver_Street__c;
                        POObj.Deliver_To_State__c = reqLineWrapper.reqLine.Requisition__r.Deliver_To_State__c;
                        POObj.Deliver_To_Country__c = reqLineWrapper.reqLine.Requisition__r.Deliver_To_Country__c;
                        POObj.Deliver_To_Zip_Code__c = reqLineWrapper.reqLine.Requisition__r.Deliver_To_Zip_Code__c;
                    }
                    POObj.Purchase_Agreement__c = reqLineWrapper.ctLine.Contract__c;
                    POObj.Remit_To_Supplier__c = reqLineWrapper.ctLine.Contract__r.Supplier__r.Remit_To__c;
                    POObj.Delivery_Facility__c = reqLineWrapper.ctLine.Contract__r.Ship_to_Facility__c;

                    POObj.Currency__c = reqLineWrapper.reqLine.Requisition__r.Currency__c;
                    //POObj.Delivery_Location__c = f.Default_Purchasing_Delivery_Location__c;
                    POObj.Sales_Order__c = reqLineWrapper.reqLine.Requisition__r.Sales_Order__c;
                    POObj.FOB_Term__c = reqLineWrapper.ctLine.Contract__r.FOB_Term__r.id;
                    POObj.Payment_Term__c = reqLineWrapper.ctLine.Contract__r.Payment_Term__r.id;
                    POObj.Transportation_Mode__c = reqLineWrapper.ctLine.Contract__r.Transportation_Mode__c;
                    POObj.Need_Date__c = reqLineWrapper.reqLine.Need_Date__c;
                    POObj.Amount_Tolerance__c = (reqLineWrapper.ctLine.Contract__r.Amount_Tolerance__c != null) ? reqLineWrapper.ctLine.Contract__r.Amount_Tolerance__c : null;
                    POObj.Quantity_Tolerance_Over__c = (reqLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Over__c != null) ? reqLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Over__c : null;
                    //POObj.Quantity_Tolerance_Under__c = (reqLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Under__c != null) ? reqLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Under__c : null;
                    POObj.Unit_Price_Tolerance_Over__c = (reqLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Over__c != null) ? reqLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Over__c : null;
                    //POObj.Unit_Price_Tolerance_Under__c = (reqLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Under__c != null) ? reqLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Under__c : null;               
                    mapOfUniqueKeyToPO.put(uKey, POObj);
                }
                
                //Below condition needs to modified to consolidate multiple req lines to single PO Line
                //if (ctLineId != reqLineWrapper.ctLine.id || reqLineWrapper.reqLine.Requisition__r.Source__c == 'Drop Ship'){
                    reqTocLine.put(reqLineWrapper.reqLine.id, reqLineWrapper.ctLine.Id);
                    //Building PO Lines
                    Purchase_Order_Line__c POLObj = new Purchase_Order_Line__c();
                    POLObj.Approved__c = true;
                    POLObj.Company__c = reqLineWrapper.ctLine.Contract__r.Company__c;
                    POLObj.Date_Added__c = system.today();
                    POLObj.Date_Closed__c = null;
                    POLObj.Date_Last_Changed__c = system.today();
                    POLObj.Delivery_Facility__c = reqLineWrapper.reqLine.Facility__c;
                    POLObj.Delivery_Location__c = facDefaultLocMap.get(reqLineWrapper.reqLine.Facility__c);
                    POLObj.Sales_Order_Line__c = reqLineWrapper.reqLine.Sales_Order_Line__c;     
                    POLObj.Sales_Order__c = reqLineWrapper.reqLine.Requisition__r.Sales_Order__c;  
                    POLObj.Description__c = reqLineWrapper.ctLine.Item__r.Description__c;
                    POLObj.Item__c = reqLineWrapper.reqLine.Item__c;
                    POLObj.Contract_Line__c = reqLineWrapper.ctLine.ID;
                    POLObj.Contracted__c = true;
                    POLObj.Need_Date__c = reqLineWrapper.reqLine.Need_Date__c;
                    POLObj.Order_Quantity__c = reqLineWrapper.reqLine.Quantity_Ordered__c;
                    POLObj.Purchase_UOM__c = reqLineWrapper.ctLine.Purchase_UOM__c;//KNDY-10904
                    if (reqLineWrapper.reqLine.Requisition__r.Source__c == 'Drop Ship'){
                        POLObj.Invoice_Matching__c = 'Two Way';
                        POLObj.Type__c = 'Drop Ship';
                    }else if (reqLineWrapper.ctLine != null) {
                        POLObj.Invoice_Matching__c = reqLineWrapper.ctLine.Invoice_Matching__c;
                    }else{
                    	POLObj.Invoice_Matching__c = reqLineWrapper.ctLine.Contract__r.Supplier__r.Invoice_Matching__c;
                    }
                    if (reqLineWrapper.reqLine.Requisition__r.Source__c == 'Back To Back') //KNDY-13443
                    	POLObj.Type__c = 'Back To Back';
                   
                    POLObj.Status__c = 'Open';
                    POLObj.Supplier__c = reqLineWrapper.reqLine.Supplier__c;
                    POLObj.Overage_Percentage__c = reqLineWrapper.ctLine.Contract__r.Supplier__r.Default_Receiving_Tolerance__c;
                    POLObj.Unit_Price__c = KSE.addQuantityToField(getUnitPriceBasedOnTiers(ReqLineWrapper.ctLine, (Double)reqLineWrapper.reqLine.Quantity_Ordered__c), 0); 
                    POLObj.Consigned__c = reqLineWrapper.ctLine.Consigned__c;
   
                    polTemp = POLObj;
                    if (!mapOfUniqueKeyToPOLines.containsKey(uKey)){ // create new PO line
                        mapOfUniqueKeyToPOLines.put(uKey, new List<Purchase_Order_Line__c>{POLObj});
                    }else{ // create new PO line and add to existing list of PO lines
                        mapOfUniqueKeyToPOLines.get(uKey).add(POLObj);
                    }
                    ctLineId = reqLineWrapper.ctLine.id;
                    //After PO Line is build, update the Requisition Released Quantity
                    reqLineWrapper.reqLine.Quantity_Released__c = reqLineWrapper.reqLine.Quantity_Ordered__c; //TODO: Req Lines are always released fully, need to revisit when we do partial release against req lines
                    reqLineWrapper.reqLine.Status__c = 'Closed';
                    mapOfUniqueReqLines.put(reqLineWrapper.reqLine.id,reqLineWrapper.reqLine);
                    reqLinetoPOLineWrapper  rqpol = new reqLinetoPOLineWrapper();
                    rqpol.poLine = POLObj;
                    rqpol.reqLine = reqLineWrapper.reqLine;
                    reqLinetoPOLineConfig.put(tmp,rqpol);
                    tmp++;
            }
        }
        List<Purchase_Order_Line__c> POLinesToInsert = new List<Purchase_Order_Line__c>();
        List<Requisition_Cross_Reference__c> reqCRs = new List<Requisition_Cross_Reference__c>();
        map<id, id> cLineTopoLine = new map<id,id>();
        Set<ID> poHeadersCreated = new Set<ID>();
        Savepoint sp = Database.setSavepoint();
        try{
            //insert all PO headers
            DML.insertAsUser(mapOfUniqueKeyToPO.values());
            
            for (String uKey: uniquePOMap.keySet()){
                ID poheaderId = mapOfUniqueKeyToPO.get(uKey).id;
                poHeadersCreated.add(poheaderId);
                for (Purchase_Order_Line__c pol: mapOfUniqueKeyToPOLines.get(uKey)){
                    pol.Purchase_Order__c = poheaderId;
                    POLinesToInsert.add(pol); // adding the POL to a list for insertion
                }
            }
            DML.insertAsUser(POLinesToInsert);

            for (Purchase_Order_Line__c poLine : POLinesToInsert){
                cLineTopoLine.put(poLine.Contract_Line__c, poLine.id);
            }
            //Create Requisition Cross reference records using the ReqtoCLine map and cLinetoPOLine map
            for (Id reqID : reqTocLine.keyset()){
                Requisition_Cross_Reference__c rcr = new Requisition_Cross_Reference__c();
                rcr.Requisition_Line__c = reqID;
                rcr.Purchase_Order_Line__c = cLineTopoLine.get(reqTocLine.get(reqID)); 
                //reqCRs.add(rcr);
            }

            //Update Requisition Lines
            DML.updateAsUser(mapOfUniqueReqLines.values());

            for (reqLinetoPOLineWrapper r : reqLinetoPOLineConfig.values()){
                Requisition_Cross_Reference__c rcr = new Requisition_Cross_Reference__c();
                rcr.Requisition_Line__c = r.reqLine.id;
                rcr.Purchase_Order_Line__c = r.poLine.id; 
                reqCRs.add(rcr);
            }

            //Insert Requisition Cross Reference Records
            DML.insertAsUser(reqCRs);

        }catch(Exception ex){
            Database.rollback( sp );
            result.success = false;
            result.addMessage(ex, ApexPages.Severity.ERROR);
        }
        return result;

    }
        
    public class RequisitionLineWrapper{
        
        public Contract_Line__c ctLine { get; set;}
        public Requisition_Line__c reqLine { get; set;}
        public Id itemID {get; set;}
                
        public RequisitionLineWrapper(){
            this.ctLine = new Contract_Line__c(); 
            this.reqLine = new Requisition_Line__c();
        }   
    }   

    public class reqLinetoPOLineWrapper {

        public Requisition_Line__c reqLine {get; set;}
        public Purchase_Order_Line__c poLine {get; set;}

        public reqLinetoPOLineWrapper(){
            this.poLine = new Purchase_Order_Line__c(); 
            this.reqLine = new Requisition_Line__c();
        }
    }

    public static Double getUnitPriceBasedOnTiers(Contract_Line__c cLine, Double quantityGiven){
        Double unitPriceBasedOnTier = 0.0;
        if (cLine.Type__c == 'Tiered'){
            if ((quantityGiven > cLine.Tier_9_Max__c && quantityGiven <= cLine.Tier_10_Max__c) || (quantityGiven > cLine.Tier_10_Max__c && (cLine.Tier_10_Max__c != null && cLine.Tier_10_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_10_Price__c; //test fails as it gets this price due to or condition above
            else if ((quantityGiven > cLine.Tier_8_Max__c && quantityGiven <= cLine.Tier_9_Max__c)|| (quantityGiven > cLine.Tier_9_Max__c && (cLine.Tier_9_Max__c != null && cLine.Tier_9_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_9_Price__c;
            else if ((quantityGiven > cLine.Tier_7_Max__c && quantityGiven <= cLine.Tier_8_Max__c)|| (quantityGiven > cLine.Tier_8_Max__c && (cLine.Tier_8_Max__c != null && cLine.Tier_8_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_8_Price__c;       
            else if ((quantityGiven > cLine.Tier_6_Max__c && quantityGiven <= cLine.Tier_7_Max__c)|| (quantityGiven > cLine.Tier_7_Max__c && (cLine.Tier_7_Max__c != null && cLine.Tier_7_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_7_Price__c;
            else if ((quantityGiven > cLine.Tier_5_Max__c && quantityGiven <= cLine.Tier_6_Max__c)|| (quantityGiven > cLine.Tier_6_Max__c && (cLine.Tier_6_Max__c != null && cLine.Tier_6_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_6_Price__c;
            else if ((quantityGiven > cLine.Tier_4_Max__c && quantityGiven <= cLine.Tier_5_Max__c) || (quantityGiven > cLine.Tier_5_Max__c && (cLine.Tier_5_Max__c != null && cLine.Tier_5_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_5_Price__c;
            else if ((quantityGiven > cLine.Tier_3_Max__c && quantityGiven <= cLine.Tier_4_Max__c) || (quantityGiven > cLine.Tier_4_Max__c && (cLine.Tier_4_Max__c != null && cLine.Tier_4_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_4_Price__c;
            else if ((quantityGiven > cLine.Tier_2_Max__c && quantityGiven <= cLine.Tier_3_Max__c)|| (quantityGiven > cLine.Tier_3_Max__c && (cLine.Tier_3_Max__c != null && cLine.Tier_3_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_3_Price__c;
            else if ((quantityGiven > cLine.Tier_1_Max__c && quantityGiven <= cLine.Tier_2_Max__c)|| (quantityGiven > cLine.Tier_2_Max__c && (cLine.Tier_2_Max__c != null && cLine.Tier_2_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_2_Price__c;
            else if ((quantityGiven >= 0 && quantityGiven <= cLine.Tier_1_Max__c)|| (quantityGiven > cLine.Tier_1_Max__c && (cLine.Tier_1_Max__c != null && cLine.Tier_1_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_1_Price__c;
        } else 
            unitPriceBasedOnTier = KSE.addQuantityToField(cLine.Negotiated_Price__c, 0);
        
        return unitPriceBasedOnTier;
    } 
    public static void updateRequisitionStatus(){     //KNDY-10640
        
        Set<Id> reqIdSet = new Set<Id>(); 
        List<Requisition_Line__c> reqLineList = (List<Requisition_Line__c>)trigger.new; 
        List<Requisition__c>reqStatustoUpdate = new List<Requisition__c>();
        if(reqLineList.size() > 0){
            for(Requisition_Line__c reqLine : reqLineList){
                if( KSE.isFieldChanging('Status__c', reqLine, Trigger.oldMap) ){
                    reqIdset.add(reqLine.Requisition__c); 
                }
            }
        }   
        if(reqIdSet.size() > 0){
            
            SOQLUtil soql = new SOQLUtil('Requisition__c', true);
            soql.addFields(new set<string>{'Id', 'Status__c'});
            soql.setWhereClause('Id IN :reqIdSet');
            
            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Requisition_Lines__r');
            childRel.addFields(new set<string>{'Id', 'Status__c'});
            soql.addChildRelationship(childRel);
            List<Requisition__c> requisitionList = Database.query(soql.getQuery());
            
            for(Requisition__c requisition : requisitionList){
                Boolean hasRequisitionLines = false;
                for(Requisition_Line__c reqLine : requisition.Requisition_Lines__r){
                    hasRequisitionLines = true;
                    break;
                }
                    //Flip the status of the Requisition based on the status of all Requisition Lines
                if(hasRequisitionLines){
                    Integer openLines = 0;
                    Integer closedLines = 0;
                    Integer cancelledLines = 0;
                    Integer totalLines = 0;
                            
                    for(Requisition_Line__c rl : requisition.Requisition_Lines__r){
                                
                        totalLines += 1;
                                
                        if(rl.Status__c == 'Open'){
                            openLines += 1;
                        }
                        if(rl.Status__c == 'Closed'){
                            closedLines += 1;
                        }
                        if(rl.Status__c == 'Cancelled'){
                            cancelledLines += 1;
                        }
                                    
                    }
                    if(closedLines + cancelledLines == totalLines && closedLines > 0){
                            
                        if(requisition.Status__c == 'Closed') continue;
                        requisition.Status__c = 'Closed';
                        reqStatustoUpdate.add(requisition); 
                    }else if(cancelledLines == totalLines){
                            
                        if(requisition.Status__c == 'Cancelled')continue;
                        requisition.Status__c = 'Cancelled';
                        reqStatustoUpdate.add(requisition);
                    }else if((openLines + closedLines == totalLines || openLines + cancelledLines == totalLines) && openLines > 0){
                            
                        if(requisition.Status__c == 'Open') continue;
                        requisition.Status__c = 'Open';
                        reqStatusToUpdate.add(requisition);
                    }
                }
            }
            if(reqStatustoUpdate.size() > 0){
                DML.updateAsUser(reqStatustoUpdate);
            }
        }   
    }
    public static void validateDropShipReq(){
        
        Set<String> ReqFields = util.getAllCustomFieldsFromObject(null,'Requisition__c'); 
        Set<String> ReqEditableFields = new Set<String>{'status__c','autonumber__c','transaction_date__c'};
         
        ReqFields.RemoveAll(ReqEditableFields);
         
        for(Requisition__c req : (List<Requisition__c>)trigger.new){
            if(req.Source__c == 'Drop Ship'){
                for(String field : reqFields){
                    if(KSE.isFieldChanging(field, req, trigger.oldMap)){
                     req.addError(Label.Cannot_update_Drop_Ship_Requisition);
                     break;
                    }
                } 
            }else if(req.Source__c == 'Back To Back'){
                for(String field : reqFields){
                    if(KSE.isFieldChanging(field, req, trigger.oldMap)){
                     req.addError(Label.Cannot_update_Back_To_Back_Requisition);
                     break;
                    }
                } 
            }
        }       
                   
    }
    public static void validateDropShipReqLine(){
        
        Set<String> ReqLineFields = util.getAllCustomFieldsFromObject(null,'Requisition_Line__c'); 
        Set<String> ReqLineEditableFields = new Set<String>{'autonumber__c','status__c','quantity_ordered__c','quantity_released__c', 'remaining_quantity__c', 'default_purchase_agreement_line__c'};
        List<Id>reqIds = new List<Id>();
        
        ReqLineFields.removeAll(util.removeNSfromSetString(ReqLineEditableFields)); 
        for(Requisition_Line__c reqLine : (List<Requisition_Line__c>)trigger.new){
            if(reqLine.Requisition__c != null){
                reqIds.add(reqLine.Requisition__c);
            }
        }
        Map<Id,Requisition__c> reqMap = new Map<Id,Requisition__c>([select id, Source__c from Requisition__c where Id IN :reqIds AND (Source__c = 'Drop Ship' or Source__c = 'Back To Back')]);
        
        for(Requisition_Line__c reqLine : (List<Requisition_Line__c>)trigger.new){
            if(reqMap.containsKey(reqLine.Requisition__c)){             
                for(String field : reqLineFields){
                	if (reqMap.get(reqLine.Requisition__c).Source__c == 'Drop Ship'){
	                    if(KSE.isFieldChanging(field, reqLine, trigger.oldMap)){
	                        reqLine.addError(Label.Cannot_update_Drop_Ship_Requisition);
	                        break;
	                    }
                	}else if (reqMap.get(reqLine.Requisition__c).Source__c == 'Back To Back'){
	                    if(KSE.isFieldChanging(field, reqLine, trigger.oldMap)){
	                        reqLine.addError(Label.Cannot_update_Back_To_Back_Requisition);
	                        break;
	                    }
                	}
                }
            }
        }
    }
    
}