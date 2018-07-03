global with sharing class AddChildProductsCon extends BaseController {
    
    //TODO Listprice and smart search,fix search query
    public ApexPages.StandardController con {get; set;}
    public Agreement_Line__c agl  {get; set;}
    public List<ProductWrapper> pwList {get;set;}
    private String soql {get;set;}
    public String searchName {get;set;}
    public List<Product__c> pList {get;set;}
    public String errorMsg{get;set;}
    public boolean isSuccess {get;set;}
    public string agreementLineId {get;set;}
    
    public String iFieldList ;
    public GridRelatedListController.GridRelatedListConfig KendoGridConfig {get; set;}
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    private static SchemaUtil util = SchemaUtil.getInstance();

    
    public AddChildProductsCon(Apexpages.Standardcontroller controller) {
        this.con = controller;
        this.agl = (Agreement_Line__c)con.getRecord();
        Agreement_Line__c a  = (Agreement_Line__c) con.getRecord();
        agreementLineId = a.Id; 
       
       KendoGridConfig = new GridRelatedListController.GridRelatedListConfig();
        KendoGridConfig.uniqueId = 'kendoSampleGrid1';
        KendoGridConfig.title = '';
        KendoGridConfig.objectName = 'Product__c';
        KendoGridConfig.fieldset = 'Add_Product';
        //KendoGridConfig.buttons = 'cancel, delete';
       //KendoGridConfig.alwaysUseFullDateTimeFormat = false;
    }
    
 
    public String getIGridConfigJson() {
        String configStr = JSON.serialize(this.KendoGridConfig);
        return configStr;
    }
 
    @remoteAction
     global static JsonResult searchProd(String searchName) {
        JsonResult jr = new JsonResult();

        String whereClause = '';
        if(!searchName.equals('')){
           whereClause += 'Name LIKE ';
           whereClause += '\'' + String.escapeSingleQuotes(searchName.trim()) + '%\'';
        }
        SOQLUtil soql = new SOQLUtil('Product__c', TRUE);
        soql.addFields(new Set<String>{'Id', 'Name', 'Item__c', 'Product_Type__c', 'Description__c', 'Selling_UOM__c'});
        soql.setWhereClause(whereClause);
        List<Product__c>    pList = Database.query(soql.getQuery());

        List<ProductWrapper>   pwList = new List<ProductWrapper>(); 
        
         for(Product__c p :pList){
           ProductWrapper pw = new ProductWrapper();
           pw.p = p;
           pwList.add(pw); 
        }
         system.debug(pwList);
         jr.records =pwList;
         jr.success=true; 
         return jr;
    }
    

    @RemoteAction
    global static DataSourceResult createProducts (List<ProductWrapper> pwList, String agreementLineId) {
    system.debug(pwList);
    system.debug(agreementLineId);    
    DataSourceResult result = new DataSourceResult();

	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
	SOQLUtil soql = new SOQLUtil('Agreement_Line__c', true); //enforceFLS=true, running in user mode
	soql.addFields(new set<string>{
		'id','Agreement__c','Agreement__r.Customer__c','Agreement__r.Customer__r.Record_Type_Name__c','Revision_Number__c','Agreement_Price__c',
		'List_Price__c','Product__c','End_Date__c','Start_Date__c'
	});
	soql.setWhereClause('id = :agreementLineId');
	Agreement_Line__c agl = Database.query(soql.getQuery());

    list<Agreement_Line__c> agllist = new list<Agreement_Line__c>();
        
       for(ProductWrapper p :pwList){
           if( p.qty != null && p.qty != 0){ 
            Agreement_Line__c ag = new Agreement_Line__c();
                ag.Agreement__c = agl.agreement__c;
                ag.Agreement_Price__c = p.agreementPrice;
                ag.Sales_Agreement_Quantity__c = p.qty;
                ag.Parent_Agreement_Line__c = agl.Id;
                //ag.Revision_Number__c = agl.Revision_Number__c;
                ag.Start_Date__c = agl.Start_Date__c;
                ag.End_Date__c = agl.End_Date__c;
                ag.Product__c = p.p.id;
                ag.Product_Type__c = p.p.Product_Type__c;
                ag.List_Price__c = p.listPrice;
                agllist.add(ag);
              
           }
           else{
                result.success = false;
                String message = 'There are no selected lines with quantity specified.'; 
                result.addMessage(message, ApexPages.Severity.ERROR);
                return result;
           }    
        }
        try{
        if(!agllist.isEmpty()){
            DML.insertAsUser(agllist);  
            result.success = true;
            result.message = 'Products Configured';
            return result;
        }
           
        }catch(Exception e){
            result.success = false;
            result.addMessage(e, ApexPages.Severity.ERROR);
        }
        system.debug(agllist);
        return result;
    }
    global class ProductWrapper{
        
        public Product__c p {get;set;}
        public boolean selected {get;set;}
        public decimal listPrice {get;set;}
        public integer qty {get;set;}
        public decimal agreementPrice {get;set;}
        global ProductWrapper(){
            this.qty = 0;
            this.agreementPrice = 0;
        }
          
    }
    public String getiFieldList() {
        if (String.isBlank(iFieldList) && KendoGridConfig != null) {
            // get the  field info list
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();
            // get the  details field info list
          FieldInfo selectFieldInfoItem = new FieldInfo();
            selectFieldInfoItem.field = 'qty';
            selectFieldInfoItem.title = 'Quantity ';
            selectFieldInfoItem.fieldtype = 'Integer';
          //  selectFieldInfoItem.filterable=true;
            selectFieldInfoItem.editable = true;
            selectFieldInfoItem.width = 60;
            fieldInfoList.add(selectFieldInfoItem);
           

           FieldInfo selectFieldInfoItem1 = new FieldInfo();
            selectFieldInfoItem1.field = 'agreementPrice';
            selectFieldInfoItem1.title = 'Agreement Price';
            selectFieldInfoItem1.fieldtype = 'Integer';
            selectFieldInfoItem1.editable = true;
            selectFieldInfoItem1.width = 60;
            fieldInfoList.add(selectFieldInfoItem1);
            
            fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos(KendoGridConfig.objectName, KendoGridConfig.fieldset));
  
            for(Integer i = 2; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                fieldInfoList[i].editable = false;
            }
            
            for(Integer i = 1; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                if(!(fieldName == 'agreementPrice' || fieldName == 'qty') ){
                    fieldInfoList[i].field = 'p.' + fieldName;
                    fieldInfoList[i].filterable=true;
                }
                
            }
            
            iFieldList = JSON.serialize(fieldInfoList);
        }
         system.debug(iFieldList);
        return iFieldList;
    }

    public void FirstPage() {     
        //OffsetSize = 0;     
    }     
    public void previous() {     
        //OffsetSize = OffsetSize - LimitSize;        
    }     
    public void next() {     
        //OffsetSize = OffsetSize + LimitSize;        
    }     
    public void LastPage() {     
        // OffsetSize = totalrecs - math.mod(totalRecs,LimitSize);     
    }     
    public boolean getprev() {     
        //-        if(OffsetSize == 0)       
        //-        return true;      
        //-        else      
        return false;     
    }

    public boolean getnxt() {
        //if((OffsetSize + LimitSize) > totalRecs)
        //return true;
        //    else 
        return false;     
    }

    public void search() {

    }

    public void createProducts() {
        
    }

}