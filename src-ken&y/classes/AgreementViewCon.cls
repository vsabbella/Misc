global with sharing  class AgreementViewCon extends BaseController {
    private static SchemaUtil util = SchemaUtil.getInstance();
    public string NamespaceUU { get { return KSE.NamespaceUU; } } 
    public String agreementPrefix {get; set;}
    public String agreementLinePrefix {get; set;}
    public Agreement__c agreement {get; set; }
    public String planId {get; set;}
    public String agreementId {get; set;}
    public GridRelatedListController.GridRelatedListConfig agreementConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig agreementLinesConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig segmentLinesConfig {get; set;} 
    public string agreementFieldList {get; set;}
    public string agreementLineFieldList {get; set; }
    public String segmentLinesFieldList = null;
    public List<Grid_Views_Config__c> agreementLinegridViews = null;
    private Map<String, Agreement_Actions__c> agreementActionMap ;
    private Map<String, Agreement_Line_Actions__c> agreementLineActionMap ;
    public decimal thresholdpercentage {get; set;}

    global AgreementViewCon() {

        Set<String> segmentFields = new Set<String>();
        Set_Rental_Approval_Threshold__c thresholdCS = Set_Rental_Approval_Threshold__c.getOrgDefaults();
        if(thresholdCS != null){
        	thresholdpercentage =  thresholdCS.Variation_Percentage__c;
        }else{
            thresholdpercentage = 0;
        }

        // Segment Lines Grid config
        segmentLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        segmentLinesConfig.uniqueId = 'SegmentLinesGrid';
        segmentLinesConfig.objectName = 'Accounting_Default__c'; 

        // get the available segements
        List<FieldInfo> availableSegments = (List<FieldInfo>) JSON.deserialize(KSE.getSegmentLinesFieldList(segmentLinesFieldList, segmentLinesConfig), List<FieldInfo>.class);
        
        // get the agreement field info list
        List<FieldInfo> agreementfieldInfoList = FieldInfo.fetchJsonFieldInfos('Agreement__c', 'Agreement_View');
        agreementFieldList = JSON.serialize(agreementfieldInfoList);

        // get the agreement lines field info list
        //List<FieldInfo> agreementLinefieldInfoList = FieldInfo.fetchJsonFieldInfos('Agreement_Line__c', 'Master');
        getGridViewFields();
        List<FieldInfo> agreementLinefieldInfoList = allFieldsMap.values();

        agreementConfig = new GridRelatedListController.GridRelatedListConfig();
        agreementConfig.uniqueId = 'promotions';
        agreementConfig.objectName = 'Agreement__c';  
        agreementConfig.buttons = 'search';

        agreementLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        agreementLinesConfig.uniqueId = 'pprod';
        agreementLinesConfig.objectName = 'Agreement_Line__c';
        agreementLinesConfig.parentField = 'Agreement__c';  
        agreementLinesConfig.buttons = '';

        List<Integer> accountSegmentFieldIndexes = new List<Integer>();

        // set the wrapper class prefix
        for(Integer i = 0; i < agreementLinefieldInfoList.size(); i++){
            
            //If the agreementLineFieldList has any Accounting segment fields then add the field name to segmentFields list and 
            //also add the indexes of the segment fields to the accountSegmentFieldIndexes
            if(agreementLinefieldInfoList[i].field.toLowerCase().contains('accounting_segment__r.')){

                segmentFields.add(agreementLinefieldInfoList[i].field.toLowerCase().substringAfter('accounting_segment__r.'));
                accountSegmentFieldIndexes.add(i);
            }

            agreementLinefieldInfoList[i].field = 'agl.' + agreementLinefieldInfoList[i].field;
            agreementLinefieldInfoList[i].hidden = true;
        }

        //Remove Account Segment fields from the field set as we are handling 
        //Accounting Segments separately while saving the line
        for(Integer i = accountSegmentFieldIndexes.size() - 1; i >= 0 ; i--) {
            
            agreementLinefieldInfoList.remove(accountSegmentFieldIndexes[i]);
        }

        //Add segment fields if any
        for(Integer i = 0; i < availableSegments.size(); i++){
            
            if(segmentFields.contains(availableSegments[i].field.toLowerCase())){
                
                FieldInfo segmentField = availableSegments[i];
            
                if (segmentField.field == 'Id') {

                    segmentField.hidden = true;
                }
                segmentField.hidden = true;
                segmentField.field = 'segments.' + segmentField.field;
                agreementLinefieldInfoList.add(segmentField);
            }
        }

        agreementLineFieldList = JSON.serialize(agreementLinefieldInfoList);

        Schema.DescribeSObjectResult dsrPromo = Agreement__c.SObjectType.getDescribe();
        agreementPrefix = dsrPromo.getKeyPrefix();       
        
        Schema.DescribeSObjectResult dsrAgreementLine = Agreement_Line__c.SObjectType.getDescribe();
        agreementLinePrefix = dsrAgreementLine.getKeyPrefix();    
        
        //get the agreement custom action custom settings
        agreementActionMap = Agreement_Actions__c.getAll(); 
        agreementLineActionMap = Agreement_Line_Actions__c.getAll();
    }

    /*
     *  getGridViews method prepares the list of views to be listed on the dropdown box in the UI
     *
     *  @param  fieldInfoList
     *  @param  fieldName
     *  @return Integer    
     *
     */
    public String getGridViews() {
        List<SelectListItem> viewList = new List<SelectListItem>();
        this.agreementLinegridViews = this.agreementLinegridViews == null ? KSE.getGridViews('pprod') : this.agreementLinegridViews;

        Set<String> existingViews = new Set<String>();

        for(Grid_Views_Config__c gvConfig: this.agreementLinegridViews){

            if (!existingViews.contains(gvConfig.Fieldset_Name__c.toLowerCase())){
                viewList.add(new SelectListItem(gvConfig.Fieldset_Name__c, gvConfig.View_Name__c));
                existingViews.add(gvConfig.Fieldset_Name__c.toLowerCase());
            }
        }

        return JSON.serialize(viewList);
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
            fieldNames.add('agl.' + f.field);
        }
        return fieldNames;
    }


    public String getAllFields(){
        if (allFieldsMap.keySet().isEmpty()){
            getGridViewFields();
        }

        return JSON.serialize(allFieldsMap.keySet());
    }

    /*
     *  getGridViewFields method fetches list of fields on associated with a fieldset that are part of the grid views
     *
     *  @return String    
     *
     */
    public Map<String, FieldInfo> allFieldsMap = new Map<String, FieldInfo>();

    public String getGridViewFields() {

        Map<String, List<String>> gridViewFieldsMap = new Map<String, List<String>>();
        
        this.agreementLinegridViews = this.agreementLinegridViews == null ? KSE.getGridViews('pprod') : this.agreementLinegridViews;
        //this.agreementLinegridViews = this.agreementLinegridViews == null ? new List<Grid_Views_Config__c>() : this.agreementLinegridViews;

        if (this.agreementLinegridViews.isEmpty() || agreementLinegridViews[0].View_Dropdown_Index__c == 0){
            this.agreementLinegridViews.add(new Grid_Views_Config__c(Fieldset_Name__c = 'Agreement_View', View_Name__c='Default')); // set to 0 to maintain the same name, 'default'
        } else {
            this.agreementLinegridViews.add(0, new Grid_Views_Config__c(Fieldset_Name__c = 'Agreement_View', View_Name__c='Default')); // set to 0 to maintain the same name, 'default'
        }

        for(Grid_Views_Config__c gvConfig: this.agreementLinegridViews){

            List<String> fieldNames = new List<String>();
            //Ignore the fieldset that has been loaded already
            if(gridViewFieldsMap.containsKey(gvConfig.Fieldset_Name__c)){
                continue;
            }

            try {

                List<FieldInfo> fieldList = FieldInfo.fetchJsonFieldInfos('Agreement_Line__c', gvConfig.Fieldset_Name__c);
                
                for (FieldInfo fi : fieldList){
                    if (!allFieldsMap.containsKey(fi.field) || fi.required){
                        allFieldsMap.put(fi.field, fi);
                    }
                }

                fieldNames = getUIFieldNames(fieldList);

            } catch (FieldInfo.EmptyFieldSetMemberException e) {
                //ignnore invalid fieldsets
            }
            
            gridViewFieldsMap.put(gvConfig.Fieldset_Name__c, fieldNames);
        }
        
        //gridViewFieldsMap.put('Master', new List<String>(getUIFieldNames(new List<FieldInfo>(allFieldsMap))));

        return JSON.serialize(gridViewFieldsMap);
    }

    @RemoteAction
    public static JsonResult getAgreementData(String agreementId, String planId) {
        JsonResult result = new JsonResult();
        SOQLUtil soql;
        if (!String.isEmpty(agreementId)) {
            //system.debug(agreementId);
            soql = new SOQLUtil('Agreement__c', TRUE);
            soql.addFields('Agreement_View');
            soql.setWhereClause('Id = :agreementId');
            List<Agreement__c> agreementList = database.query(soql.getQuery());

            //system.debug(agreementList);

            result.records = agreementList;
            result.total = agreementList.size();
        }

        if (!String.isEmpty(planId)) {
            soql = new SOQLUtil('Agreement__c', TRUE);
            soql.addFields('Agreement_View');
            soql.setWhereClause('Plan__c = :planId');
            List<Agreement__c> agreementList = database.query(soql.getQuery());

            result.records = agreementList;
            result.total = agreementList.size();
        }

        return result;
    }
    @RemoteAction
    public static JsonResult getAglDetailsFromProduct( String productId, Agreement_Line__c agl, String agreementId) {
        JsonResult result = new JsonResult();
       // Agreement__c agmt = (Agreement__c)JSON.deserialize(agreement, Agreement__c.class);
        try {
            List<agLineWrapper> agLineWrappers = new List<agLineWrapper>();
            Agreement_Line__c agreementLine = getAgmtLineDetails(productId, agl, agreementId);
            agLineWrapper agLineWrapper = new agLineWrapper(agreementLine);
            agLineWrappers.add(agLineWrapper);
            result.records = agLineWrappers;
            result.total = agLineWrappers.size();
            }catch(Exception e){
                result.success = false;
                result.addMessage('An Error occured :' + e.getMessage(), ApexPages.Severity.ERROR);
            }
            return result;
    }

    @RemoteAction 
    public static JsonResult getAglDetailsFromCrossRef( String productReferenceId, 
                                                                  Agreement_Line__c agl, 
                                                                  String agreementId ){
        JsonResult result = new JsonResult();
      //  Agreement__c agmt = (Agreement__c)JSON.deserialize(agreement, Agreement__c.class);
        Map<Id, Cross_Reference__c> crMap = new Map<Id, Cross_Reference__c>();

        Set<String> crossRefQueryFields = new Set<String>{ 'Id', 'Name', 'Product__c', 'Product__r.Id', 'Product__r.name', 'Customer__c', 'Active__c', 'Customer__r.Name ' };
        String crossRefqueryWhereClause = ('Id = \'' + productReferenceId + '\' AND Active__c = true AND Cross_Reference_Type__c = \'Customer\' AND Reference_Object__c = \'Product\'');

        SOQLUtil soql = new SOQLUtil('Cross_Reference__c');
        soql.addFields(crossRefQueryFields);
        soql.setWhereClause(crossRefqueryWhereClause);

        List<Cross_Reference__c> crossRefList = Database.query(soql.getQuery());

        try {
            List<AGLineWrapper> agLineWrappers = new List<AGLineWrapper>();

            Agreement_Line__c agreementLine = getAgmtLineDetails(crossRefList[0].Product__c, agl, agreementId);
            agLineWrapper agLineWrapper = new agLineWrapper(agreementLine);
            
            agLineWrappers.add(agLineWrapper);
            result.records = agLineWrappers;
            result.total = agLineWrappers.size();
        }
        catch (Exception e) {
            result.success = false;
            result.addMessage('An Error occured :' + e.getMessage(), ApexPages.Severity.ERROR);
        } 
        return result;
    }
    public  static Agreement_Line__c getAgmtLineDetails( String productValue, 
                                                                Agreement_Line__c agmtline,
                                                                String agreementId) {
        Agreement_Line__c agLine = new Agreement_Line__c();

        //Fetch Product information
        Set<String> productQueryFields = new Set<String>{'Id', 
                                                         'Name',
                                                         'Description__c',
                                                         'Item__c', 
                                                         'Item__r.Name',
                                                         'Item__r.Fulfillment_Source__c',
                                                         'Item_Specification__c',
                                                         'Item_Specification__r.Name',
                                                         'Pricebook_Line_Required__c',
                                                         'Product_Group__c',
                                                         'Selling_UOM__r.Name', 
                                                         'Units_per_Layer__c',
                                                         'Units_per_Pallet__c',
                                                         'UPC_Code__c',
                                                         'Invoiceable__c',
                                                         'Item__r.Source__c'};
       

         String productQueryWhereClause = ' id = \''+ String.escapeSingleQuotes(productValue) +'\' Limit 1 ';
        
        SOQLUtil soql = new SOQLUtil('Product__c');
        soql.addFields(productQueryFields);
        soql.setWhereClause(productQueryWhereClause);
        
                      
        Product__c[] products = Database.query( soql.getQuery() ); 
                      
        if (products == null || products.isEmpty()) {
            // Return empty agreement Line object
            return agLine;
        }

        Product__c product = products[0]; 
        agmtline.Product__c = product.id;
        agmtline.Product__r = product;

        if(agmtline.Id == null) {
            agmtline.Agreement__c = agreementId;
        }
        Set<String> agQueryFields = new set<String> {'Id', 'Company__c', 'Customer__c', 'Customer__r.Pricebook__c', 'Currency__c', 'Sold_to__c', 'Sold_to__r.Customer_Group__c', 'Sold_to__r.Pricebook__c' }; 
        String agQueryWhereClause = ' id =  :agreementId ';
        SOQLUtil agSoql = new SOQLUtil('Agreement__c');
        agSoql.addFields(agQueryFields);
        agSoql.setWhereClause(agQueryWhereClause);

        Agreement__c[] agreement = Database.query( agSoql.getQuery() );
        
        agmtline.Agreement__r = agreement[0];

        Cross_Reference__c crossReference =  fetchCrossReferenceDetails(product, agreementId);
        Pricebook_Line__c priceBookLine;
        Map<String,Pricebook_Line__c> priceBookLineMap = pricingService.fetchSOLinesPriceBookInfo(new List<Agreement_Line__c> {agmtline});
        priceBookLine = priceBookLineMap.containsKey(agreementId + '-' + agmtLine.Line__c) ? priceBookLineMap.get(agreementId + '-' + agmtline.Line__c) : new Pricebook_Line__c();

        //Update Price on tabbing out of Product
        if(priceBookLine != new Pricebook_Line__c()) {
            if(agmtLine.Pricebook__c == priceBookLine.Pricebook__c || agmtLine.Pricebook__c == null) {
                agLine.List_Price__c = priceBookLine.Price__c;
                agLine.Pricebook__c = priceBookLine.Pricebook__c;
                agLine.Pricebook__r = priceBookLine.Pricebook__r;
            } else {
                agLine.Pricebook__c = agmtLine.Pricebook__c;
                agLine.Pricebook__r = agmtLine.Pricebook__r;
                agLine.List_Price__c = null; //PBL not found for AGL and PB combo
            }
        }
                       
        agLine.Product__c = product.Id;
        agLine.Product__r = product;
        agLine.Item_Specification__c = product.Item_Specification__c;
        agLine.Item_Specification__r = product.Item_Specification__r;
        agLine.Product_Reference__c = crossReference.Id;
        agLine.Product_Reference__r = crossReference;
        return agLine; 
    }

    public static Cross_Reference__c fetchCrossReferenceDetails( Product__c product,  string agId){
        Cross_Reference__c crossRef = new Cross_Reference__c();

        Set<String> crossRefQueryFields = new Set<String>{ 'Id', 'Name', 'Product__c', 'Product__r.name', 'Customer__c', 'Active__c', 'Customer__r.Name ' };
        String crossRefqueryWhereClause = ('product__c = \'' +  product.id  + '\' AND Active__c = true AND Cross_Reference_Type__c = \'Customer\' AND Reference_Object__c = \'Product\'');
        String crossRefqueryOrderByClause = 'Name';

        SOQLUtil soql = new SOQLUtil('Cross_Reference__c');
        soql.addFields(crossRefQueryFields);
        soql.setWhereClause(crossRefqueryWhereClause);
        soql.setOrderByClause(crossRefqueryOrderByClause);

        List<Cross_Reference__c> crossRefList = Database.query(soql.getQuery());

        Set<String> agQueryFields = new set<String> {'Id', 'Name', 'Customer__c', 'Start_Date__c', 'Agreement_Type__c', 'Company__c' }; 
        String agQueryWhereClause = ' id =  :agId ';
        SOQLUtil agSoql = new SOQLUtil('Agreement__c');
        agSoql.addFields(agQueryFields);
        agSoql.setWhereClause(agQueryWhereClause);

        Agreement__c[] aglist = Database.query( agSoql.getQuery() );
        for(Cross_Reference__c cr : crossRefList){
            if(cr.Customer__c == aglist[0].Customer__c){
                crossRef = cr;
                break;
            }
        }

        return crossRef;
   
    }

    @RemoteAction
    public static JsonResult getAgreementLineData(String agreementId, List<String> allFields) {
        JsonResult result = new JsonResult();
        List<AGLineWrapper> wrapperList = new List<AGLineWrapper>();

        SOQLUtil soql = new SOQLUtil('Agreement_Line__c', TRUE);
        soql.addFields(new set<String>(allFields));
        soql.addFields(new Set<String>{'Parent_Agreement_Line__c', 'Accounting_Segment__c', 'Customer_PO__c','Agreement__r.Status__c'});
        soql.setWhereClause('Agreement__c = :agreementId');
        List<Agreement_Line__c> agreementLineList = database.query(soql.getQuery());
        
        for (Integer i = 0; i< agreementLineList.size() ; i++) {
            AGLineWrapper agLineWrapper = new AGLineWrapper(agreementLineList[i]);
            wrapperList.add(agLineWrapper);
        }

        result.records = wrapperList;
        result.total = wrapperList.size();
        return result;
    }

    public String getAgreementConfigJson() {
        String configStr = JSON.serialize(this.agreementConfig);
          
        return configStr;
    }

    public String getAgreementLinesConfigJson() {
        String configStr = JSON.serialize(this.agreementLinesConfig);
          
        return configStr;
    }

    public String getAgreementJson() {
        String configStr = JSON.serialize(this.agreement);
          
        return configStr;
    }
    
    public List<String> getCustomAgreementActionIds() {
        List<String> customAgreementActionIds = new List<String>();
        
        for(Agreement_Actions__c pa: agreementActionMap.values()) {
            customAgreementActionIds.add(pa.Id);
        }                   
        
        return customAgreementActionIds;
    }  
    
    public List<String> getCustomAgreementLineActionIds() {
        List<String> CustomAgreementLineActionIds = new List<String>();
        
        for(Agreement_Line_Actions__c ppa: agreementLineActionMap.values()) {
            CustomAgreementLineActionIds.add(ppa.Id);
        }                   
        
        return CustomAgreementLineActionIds;
    }           
    
    
    
    public String getCustomAgreementActionsDropdown() {
        //build the dropdown from the custom settings.  the page appends these to the standard dropdown
        String customAgreementActions = '';

        for(Agreement_Actions__c pa: agreementActionMap.values()) {
            AgreementAction action = new AgreementAction();
            action.text = pa.Name;
            action.value = pa.Id;
            customAgreementActions += (',' + JSON.serialize(action));       
        }           
        
        return customAgreementActions;
    }
    
    
    public String getCustomAgreementActionsConfig() {
        //build the custom JSON structure that defines the windows to launch
        
        String customAgreementActionsConfig = '';
        Map<String, AgreementActionConfig> configMap = new Map<String, AgreementActionConfig>();
        
        for(Agreement_Actions__c pa: agreementActionMap.values()) {
            AgreementActionConfig config = new AgreementActionConfig();
            config.div = pa.Id;
            config.title = pa.Name;
            config.width = pa.Width__c + 'px';
            config.height = pa.Height__c + 'px';
            config.content = pa.URL__c + '?id=';
            configMap.put(pa.Id, config);
        }               
        
        customAgreementActionsConfig = JSON.serialize(configMap);
        
        //small text hack to get the JSON to have the javascript variable in it:
        customAgreementActionsConfig = customAgreementActionsConfig.replace('?id=', '?id=');
        
        //remove the map start/end since we are injecting this into an existing map 
        customAgreementActionsConfig = (',' + customAgreementActionsConfig.removeStart('{').removeEnd('}'));
        
        return customAgreementActionsConfig;
    }    
    
    

    
    
    
    //============ custom objects to hold custom action data
    public class AgreementAction {
        String text {get; set;}
        String value {get; set;}
        public AgreementAction(){}
    }    
        
    
    public class AgreementActionConfig {
        String div {get; set;}
        String title {get; set;}
        String width {get; set;}
        String height {get; set;}
        String content {get; set;}
        public AgreementActionConfig(){}
    }
    //============ end custom objects to hold custom action data 

  //***
  public String getCustomAgreementLineActionsDropdown() {
        //build the dropdown from the custom settings.  the page appends these to the standard dropdown
        String customAgreementLineActions = '';

        for(Agreement_Line_Actions__c ppa: agreementLineActionMap.values()) {
            AgreementLineAction paction = new AgreementLineAction();
            paction.text = ppa.Name;
            paction.value = ppa.Id;
            customAgreementLineActions += (',' + JSON.serialize(paction));          
        }           
        
        return customAgreementLineActions; 
    }
    
    
    public String getCustomAgreementLineActionsConfig() {
        //build the custom JSON structure that defines the windows to launch
        
        String customAgreementLineActionsConfig = '';
        Map<String, AgreementLineActionConfig> pconfigMap = new Map<String, AgreementLineActionConfig>();
        
        for(Agreement_Line_Actions__c ppa: agreementLineActionMap.values()) {
            AgreementLineActionConfig pconfig = new AgreementLineActionConfig();
            pconfig.div = ppa.Id;
            pconfig.title = ppa.Name;
            pconfig.width = ppa.Width__c + 'px';
            pconfig.height = ppa.Height__c + 'px';
            pconfig.content = ppa.URL__c + '?id=';
            pconfigMap.put(ppa.Id, pconfig);
        }               
        
        customAgreementLineActionsConfig = JSON.serialize(pconfigMap);
        
        //small text hack to get the JSON to have the javascript variable in it:  
        customAgreementLineActionsConfig = customAgreementLineActionsConfig.replace('?id="', '?id=');
        
        //remove the map start/end since we are injecting this into an existing map 
        customAgreementLineActionsConfig = (',' + customAgreementLineActionsConfig.removeStart('{').removeEnd('}'));
        
        return customAgreementLineActionsConfig;
    }
    
    @RemoteAction
    public static DataSourceResult saveAgreementList(List<Agreement__c> updatedList, List<Agreement__c> newList, List<Agreement__c> deletedList, List<String> dateFields) {
        
        DataSourceResult result = new DataSourceResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            if (updatedList.size() > 0) {
                for(Agreement__c a:updatedList){
                   KendoUtils.UpdateDateFields(a, dateFields); 
                }
                DML.checkUpsertAsUser(updatedList); upsert updatedList;
            }
            
            if (newList.size() > 0) {
                for(Agreement__c a:newList){
                   KendoUtils.UpdateDateFields(a, dateFields); 
                }
                DML.checkUpsertAsUser(newList); upsert newList;
            }
            
            if (deletedList.size() > 0) {
                DML.deleteAsUser(deletedList); 
            }
            // Leave it from here and let JS handle !
            result.addMessage('Changes Saved', ApexPages.Severity.CONFIRM);

        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            system.debug(e);
            result.addMessage(e, ApexPages.Severity.ERROR);
        }

        return result;
    }

    @RemoteAction
    public static DataSourceResult saveAgreementLine(AGLineWrapper agLineWrapper, List<String> dateFields, String context) {
        Map<string, Cross_Reference__c> crMap = new Map<string, Cross_Reference__c>();
        Agreement_Line__c agl = agLineWrapper.agl;

        KendoUtils.UpdateDateFields(agl, dateFields);

        Accounting_Default__c segments = agLineWrapper.segments;
        List<Accounting_Default_Segment_Definition__c> segmentDefinitions = Accounting_Default_Segment_Definition__c.getAll().Values();

        Boolean isSegmentEmpty = true;
        Boolean hasError = false;
    
        DataSourceResult result = new DataSourceResult();
        if (result.success == false){
            return result;
        }
        // looping through the Segment Def to compare against segments entered
        for(Accounting_Default_Segment_Definition__c sd : segmentDefinitions){ 

            if (segments != null && segments.get(sd.accounting_default_field__c) != null){ //A segment is entered since value is not null (blanks == null)
                isSegmentEmpty = false; //Even if one of the segments is filled in then set the flag in order to validate that invoice line
                break;
            }
        }
        
        Savepoint sp = Database.setSavepoint();

        if(!isSegmentEmpty){

            try {
                DML.checkUpsertAsUser(segments); upsert segments;

                //Link the Accounting Default to the updated AG line
                if (segments != null) {

                    agl.Accounting_Segment__c = segments.Id;
                }

            } catch(Exception e){
                Database.rollback(sp);
                hasError = true;
                result.success = false;
                result.addMessage(e, ApexPages.Severity.ERROR);
            }
        }

        if(!hasError) {
            try {
                if (agl != null) {
                    if(context == 'create' || context == 'update'  ) {
                        DML.checkUpsertAsUser(agl); upsert agl;
                    }
                    if(context == 'delete') {
                        DML.deleteAsUser(agl);
                    }

                    // Leave it from here and let JS handle !
                    result.addMessage('Changes Saved', ApexPages.Severity.CONFIRM);
                }

            } catch (Exception e) {
                Database.rollback(sp);
                result.success = false;
                result.addMessage(e, ApexPages.Severity.ERROR);
            }
        }

        return result;
    }

    //============ custom objects to hold custom action data
    public class AgreementLineAction {
        String text {get; set;}
        String value {get; set;}
        public AgreementLineAction(){}
    }    
    
    public class AgreementLineActionConfig {
        String div {get; set;}
        String title {get; set;}
        String width {get; set;}
        String height {get; set;}
        String content {get; set;}
        public AgreementLineActionConfig(){}
    }
    //============ end custom objects to hold custom action data 

    
//**** 

    // used to generate a URL for the visualforce page to navigate to another page
    public string AgreementReleasePage { get { 
        PageReference p = Page.AgreementReleasePage; 
        return p.getUrl();
    }}
       
    public string AddChildProducts { get { 
        PageReference p = Page.AddChildProducts; 
        return p.getUrl();
    }}
    
    public string AgreementRevise { get { 
        PageReference p = Page.AgreementRevise;
        return p.getUrl();
    }}
    
    public string AgreementRevisionApproval { get { 
        PageReference p = Page.AgreementRevisionApproval; 
        return p.getUrl();
    }}
     
    
    public string DownPaymentInvoice { get { 
        PageReference p = Page.DownPaymentInvoice; 
        return p.getUrl();
    }}
     
    public string GenerateInvoice { get { 
        PageReference p = Page.AgreementGenerateInvoice; 
        return p.getUrl();
    }}

    public string AgreementConsole { get {
        PageReference p = Page.AgreementConsole;
        return p.getUrl();
    }}
    
    public string AgreementClone { get { 
        PageReference p = Page.AgreementClone;
        return p.getUrl();
    }}

    public string AgreementReturn { get {
        PageReference p = Page.AgreementReturn;
        return p.getUrl();
    }}

    public string AgreementExchange { get {
        PageReference p = Page.AgreementExchange;
        return p.getUrl();
    }}

    public class AGLineWrapper{

        public Agreement_Line__c agl { get; set; }

        public Accounting_Default__c segments { get; set; }
        
        //Constructor 1
        public AGLineWrapper(){
            Accounting_Default__c ad = new Accounting_Default__c();
            
            this.agl = new Agreement_Line__c();
            this.segments = ad;
        }
        
        //Constructor 2
        public AGLineWrapper(Agreement_Line__c agl) {
            Accounting_Default__c ad = new Accounting_Default__c();
            this.agl = agl;     
            
            if (agl.Accounting_Segment__c != null) { 
                ad = agl.Accounting_Segment__r; 
            }
                    
            this.segments = ad;
        }
    }
}