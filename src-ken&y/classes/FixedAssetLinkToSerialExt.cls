public with sharing class FixedAssetLinkToSerialExt extends BaseController{
    private ApexPages.StandardController stdCon;
    public string HelpURL{get;set;}
    public String NamespaceUU { get { return KSE.NamespaceUU; }}
    public Id defaultCompany{ get; set;}
    public GridRelatedListController.GridRelatedListConfig faLinesConfig {get; set;}
    public String faLinesFieldList = null; 
    public  Id currentFAId {get;set;} 
    public  Id companyId {get;set;}
    public string ReturnUrl{set;}
    public Boolean showSearch {get;set;}
    public class CannotLinkSerialException extends Exception {}
     
    public FixedAssetLinkToSerialExt(ApexPages.StandardController stdController) {
        stdCon = stdController;
        HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpSerials';
        
        if(this.stdCon !=null){
           
            if(!test.isRunningTest()){
                this.stdCon.addFields(new List<String>{'Id','Company__c'});
            }
            if(stdCon.getRecord().id!=null){
                currentFAId = stdCon.getRecord().id;     
            }
            Fixed_Asset__c currentFA = (Fixed_Asset__c) stdCon.getRecord(); 
            companyId                = currentFA.Company__c;
            
            //-------Check if the fixed asset has any serials already linked--------------//
            SOQLUtil soql = new SOQLUtil('Serial__c',true);
            soql.addFields(new set<string>{'id'});
            soql.setWhereClause('Fixed_Asset__c=:currentFAId');
            soql.setLimit(1);
            List<Serial__c> serialsLinkedToCurrentAsset =Database.query(soql.getQuery());
            
           if(serialsLinkedToCurrentAsset.size()>0){
               ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR,
                                    'This asset is already linked to a serial number and cannot be linked more'));
               showSearch = false;
           } else{ showSearch = true;}
        }else{ 
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, Label.No_serials_found));} 
        
        // Fa Lines Grid config
        faLinesConfig                             =  new GridRelatedListController.GridRelatedListConfig();
        faLinesConfig.uniqueId                    = 'faLinesConfig';
        faLinesConfig.title                       = 'Serials Found';
        faLinesConfig.objectName                  = 'Serial__c';
        faLinesConfig.fieldset                    = 'Attach_Serials';
        faLinesConfig.buttons                     = 'columnmenu,search';  
        faLinesConfig.alwaysUseFullDateTimeFormat = false;
    }
    public String getReturnUrl(){
        PageReference faDetailPage = new PageReference('/'+currentFAId);
        return faDetailPage.getUrl();
    }
     public String getFaLinesConfigJson() {
        String configStr = JSON.serialize(this.faLinesConfig);
        return configStr; 
    }
    // Get serial (Serial__c) field Sets
    public String getFaLinesFieldList(){
         if (faLinesFieldList == null && faLinesConfig != null) {
            FieldInfo fieldInfoItem;
            try{
                //Get Name, Company, SKID from Serial to make sure some fields are shown in the serials grid
                List<String> fields                      = new List<String>{'Id'};
                List<FieldInfo> fieldInfoList            = FieldInfo.fetchJsonFieldInfos('Serial__c',fields);
                //Get the list of serial  fields from the  Serials fieldset
                List<FieldInfo> fieldInfoFromFieldSet    = FieldInfo.fetchJsonFieldInfos(faLinesConfig.objectName, faLinesConfig.fieldset);
                fieldInfoList.addAll(fieldInfoFromFieldSet);
                fieldInfoList.remove(0); // Remove the ID element from the list
                Set<String> hiddenFields                 = new Set<String> { 'Id' };
               
               // set all the fields as readonly
                for(Integer i = 0; i < fieldInfoList.size(); i++){
                    String fieldName = fieldInfoList[i].field;
                    fieldInfoList[i].field          = fieldName;
                    /*if(fieldName.contains('Rental')){
                        fieldInfoList[i].editable   = true; 
                    }
                    else{*/
                        fieldInfoList[i].editable   = false;     
                    //}
                    fieldInfoList[i].hidden         = hiddenFields.contains(fieldName);
                } 
                //Set<FieldInfo> FieldInfoSet     = new Set<FieldInfo>(fieldInfoList);
                faLinesFieldList                = JSON.serialize(fieldInfoList); 
            }
            catch(FieldInfo.EmptyFieldSetMemberException  emptyFieldsets){
                faLinesFieldList = '';
            } 
              
        }
        return faLinesFieldList;
    } 
    //------------------------Retrieve all serials based on filter conditions------------------------//
    @RemoteAction
    public static JsonResult getFALines(List<KendoUtils.FilterDescriptor> filters,
                                        GridRelatedListController.GridRelatedListConfig config,String compId){
     
     String filterType ;
     Boolean cannotLink = false;
     Id companyId = compId;
     String filterVal;
     String whereClause = '';
     Id filterCrit ;
     JsonResult result              = new JsonResult();    
     List<Serial__c> serialsList    = new List<Serial__c>();
     List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
     
     try {
      for(KendoUtils.FilterDescriptor fd: filters){
        String tmp = (String)fd.value;
        filterVal = tmp.trim(); //make sure only if the value is available add it to the filters that form the query  
            if(filterVal.length()>0){
             newFilters.add(fd);
            }  
       }
       List<String> filterCriteria = KendoUtils.getFilterCriteria(newFilters);
       filterCrit = filterVal; 
      
       //-------------------Additional filters--------------------------
       //---------------These filters applies only to Item filter-------
       //if(filterCrit.getSobjectType().getDescribe().getName()=='Item__c'){
        // filterType = 'Item';
         filterCriteria.add('Company__c= :companyId');
         filterCriteria.add('Item__r.Item_Attribute__r.Fixed_Asset__c = true');
         filterCriteria.add('Item__r.Item_Attribute__r.Serial_Number__c = true');
         filterCriteria.add('Fixed_Asset__c = null');
         filterCriteria.add('SKID__c != null');
         filterCriteria.add('Allow_Reentry__c = false'); 
         filterCriteria.add('SKID__r.Consigned_Owner__c = null'); 
       //}
       //---------------These filters applies only to serials------------
      // else{
        //  filterType = 'Serial';
         // filterCriteria.add('Company__c= :companyId');
         // filterCriteria.add('Fixed_Asset__c = null');
         // filterCriteria.add('SKID__c != null');
         // filterCriteria.add('Allow_Reentry__c = false'); 
         // filterCriteria.add('SKID__r.Consigned_Owner__c = null'); 
        //  }
      
        if (filterCriteria.size() > 0) {
            whereClause += String.join(filterCriteria, ' AND ');
        }    
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        SOQLUtil soql = new SOQLUtil(config.objectName);
        soql.addFields(fieldset);
        soql.setWhereClause(whereClause);
        serialsList = Database.query(soql.getQuery());    
        /*for(Serial__c eachSrl: serialsList){
          eachSrl.Temporary_Value_Holder__c = eachSrl.SKID__r.Rental__c==true ? 'YES' : null;
        }*/
        result.records = serialsList; 
        result.total   = serialsList.size();
        
        if(result.total>0 ){
           result.success =true; 
        }
        else{
            result.success = false;   
            result.message = Label.No_serials_found;     
        }
        }
        catch(Exception retrieveSerialsException){
             result.success = false;   
             result.message = retrieveSerialsException.getMessage();   
        }
        return result;
    }
    @RemoteAction
    public static JsonResult attachSerialsTOFA(String currentAssetId,List<Serial__c> selectedSerials){
        JsonResult result;
        Savepoint sp     = Database.setSavepoint() ; 
        
        /*        
        Boolean rentalFlagChange;
        List<id> skidIds = new List<id>();
        List<SkidService3.SerialWrapper> serialWrapperList = new List<SkidService3.SerialWrapper>();
        Map<Id,List<Serial__c>> serialsSKIDsMap            =  new Map<Id,List<Serial__c>>(); 
        Map<Id,SKID__c> skidsMap = new Map<Id,SKID__c>(); 
        Map<Id,Boolean> rentalFlagMap = new Map<Id,Boolean>();
         
        
        try{
            
            for( Serial__c eachSerial:selectedSerials){
               skidIds.add(eachSerial.SKID__C);
               //rentalFlagMap.put(eachSerial.SKID__c,eachSerial.SKID__r.Rental__c);
               //eachSerial.Temporary_Value_Holder__c = null;
            } 
             SOQLUtil skidsQuery = new SOQLUtil('SKID__c');
             skidsQuery.addFields(new Set<String>{'id','Name','Company__c','Item__c','Location__c','Bin__c','Rental__c',
                                               'Date_Received__c','Quantity__c','Expiration_Date__c','Lot_Number__c'});
             skidsQuery.setWhereClause('Id in :skidIds');
                
            for(SKID__c eachSKID:Database.Query(skidsQuery.getQuery()) ){
                skidsMap.put(eachSKID.ID,eachSKID);
            } 
            for(Serial__c eachSerial:selectedSerials){
                List<Serial__c> eachSerialList ; 
                eachSerial.Fixed_Asset__c = currentAssetId;
                //---Skids Vs its serials map
                if(serialsSKIDsMap.containsKey(eachSerial.SKID__c)){
                   eachSerialList = serialsSKIDsMap.get(eachSerial.SKID__c);
                   eachSerialList.add(eachSerial);
                }else{
                   eachSerialList= new List<Serial__c>();
                   eachSerialList.add(eachSerial);
                }
                 serialsSKIDsMap.put(eachSerial.SKID__c,eachSerialList);   
            } 
            for(Id  eachSerialSkidId:serialsSKIDsMap.keySet()){
                 SKID__c currentSKID      = skidsMap.get(eachSerialSkidId);
                 // #---Check if the rental flag is changed by user when linking serial-------#
                 if((rentalFlagMap.get(currentSKID.Id) != currentSKID.Rental__c)  && (currentSKID.Rental__c ==false) ){
                     rentalFlagChange         = true;
                     currentSKID.Quantity__c  = serialsSKIDsMap.get(eachSerialSkidId).size();
                     currentSKID.Rental__c    = rentalFlagMap.get(currentSKID.Id);
                     serialWrapperList.add(new SkidService3.SerialWrapper(skidsMap.get(eachSerialSkidId),serialsSKIDsMap.get(eachSerialSkidId) ));     
                 }
                /* //---#-----If there is flag change and the Rental__c flag was checked, Then throw exception and prevent user from linking
                 else if((currentSKID.Rental__c ==true) && (rentalFlagMap.get(currentSKID.Id) != currentSKID.Rental__c)  ){
                        throw new CannotLinkSerialException('Cannot uncheck  Rental flag, Undo the selection to proceed');
                 }*/
                 
            /*}
            // #------ Call this service only if any chnage in Rental flag ------------#
            if(rentalFlagChange==true){
                Map<String,String> config = new Map<String,String>{
                    'ICType' => 'Inventory to Rental',
                    'ITType' => 'Inventory to Rental',
                    'STType' => 'Inventory to Rental'
                    }; 
                InventoryChangeService.transfer(serialWrapperList,null,config);    
            }*/
        try{
            for(Serial__c eachSerial:selectedSerials){
                eachSerial.Fixed_Asset__c = currentAssetId;
            }
            //-#---------Else just Link serial to Asset---------------#
             result = new JsonResult();
             DML.updateAsUser(selectedSerials); 
             //--Negatve case testing
              //throw new CannotLinkSerialException('Sample--Validation Error!!!');
             result.success = true;
             result.message = Label.Successfully_added_the_selected_Serial_numbers_to_the_Asset;
        }
        catch(Exception cannotUpdateSerialExp){
            Database.rollback(sp);
            result =new JsonResult();
            result.success  = false;
            result.message  = Label.These_serials_could_not_be_linked_to_this_Asset_Reason + cannotUpdateSerialExp.getMessage(); 
        }
        return result;
    }
}