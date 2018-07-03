public with sharing class CustomerInvoiceManageExt extends BaseController {
    public String inputFields { get; set; } 
    public static String NameSpaceUU{get{return KSE.NamespaceUU;}set;} 
    public GridRelatedListController.GridRelatedListConfig KendoSampleGridConfig {get; set;}
    public string CustInvId{get;set;}
    public String getGridConfigJson() {
        String configStr = JSON.serialize(this.KendoSampleGridConfig);
        return configStr;
    }
    public boolean isCloneRequest{get;set;}
    public Boolean hasTaxService{get;private set;}
    public Boolean isRebill {get;set;}
    public String invoiceType {get;set;}
    public boolean transIdSettledStatus {get;set;} { transIdSettledStatus = false;}  
    public Boolean pgError { get; set;} { pgError = false;}
    public Customer_Invoice__c custInvoice { get; set;} 
    public string actionsMap{set;}
    public string pageTitle { get; set; }
    public string pageSubTitle { get; set; }

    public  String getCustInvoiceJson(){
        return JSON.serialize(custInvoice);
    }
    
    public string getActionsMap(){
        System.debug(logginglevel.error,'custInvoice.id--->'+custInvoice.id);  
        return  CustomerInvoiceService.populateCIActions(custInvoice.id);
    }
    
	public CustomerInvoiceManageExt(ApexPages.StandardController controller) {
        pgError = false;
        IsCloneRequest=false;
        custInvoice = (Customer_Invoice__c)controller.getRecord();
        CustInvId=	custInvoice.id ;
        if(!String.IsBlank(custInvoice.id )){
            custInvoice = (Customer_Invoice__c) getInvoice(controller.getRecord().id ,false).records[0];
            pageTitle = Label.Customer_Invoice_Edit;
            pageSubTitle = custInvoice.name;  
            
        }else{
           custInvoice.company__c = CompanyService.getDefaultCompanyId();
            custInvoice.Bill_to_Customer__r=new Customer__c();
            custInvoice.Bill_to_Customer__c = null; 
            custInvoice.Customer__r =new Customer__c();
            custInvoice.Customer__c =null;
            custInvoice.Date_Invoiced__c = Datetime.Now();
            custInvoice.Status__c = 'Open';

            custInvoice.Currency__r = CompanyService.defaultTransactionCurrencyRec(custInvoice.company__c);
            if(custInvoice.Currency__r != null){
              custInvoice.Currency__c = custInvoice.Currency__r.Id;
        }
            pageTitle = Schema.Customer_Invoice__c.getSObjectType().getDescribe().getLabel();
            pageSubTitle = Label.New_Customer_Invoice;
            
        }
        if(custInvoice.company__c!=null ){
          custInvoice.company__r = [select id,name from company__c where id = :custInvoice.company__c ];// for the Kendo Lookup to work on new Cust Inv
        }
        
        hasTaxService = TaxService.getInstance().taxServiceConfigured(custInvoice);
          
        isRebill = custInvoice.Credited_Invoice__c != null ? true : false;
      
		checkUserErrors();
        KendoSampleGridConfig = new GridRelatedListController.GridRelatedListConfig();
        KendoSampleGridConfig.uniqueId = 'kendoSampleGrid1';
        KendoSampleGridConfig.title = 'Customer Invoice';
        KendoSampleGridConfig.objectName = 'Customer_invoice_Line__c';
        KendoSampleGridConfig.fieldset = '';
        KendoSampleGridConfig.buttons = 'create, delete, clone';
        KendoSampleGridConfig.alwaysUseFullDateTimeFormat = false;
       }
    private SchemaUtil util = SchemaUtil.getInstance();

    public String getReturnURL(){
       
       PageReference pageRef;
       System.debug(logginglevel.error, 'Inside the else if condition: '+custInvoice);
       System.debug(logginglevel.error, 'custInvoice--->'+custInvoice.id);  
       if ( custInvoice != null && custInvoice.id != null ){
            pageRef =  new PageReference('/' + custInvoice.Id);
            
        }else if(custInvoice.id == null && ApexPages.currentPage().getParameters().containsKey('retURL') ){
            System.debug(logginglevel.error, ApexPages.currentPage().getParameters().get('retURL'));
            pageRef =  new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
        }else{
            Schema.DescribeSObjectResult dsr = Customer_Invoice__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        }      
       System.debug(logginglevel.error, 'pageRef--->'+pageRef.getUrl());
       return pageRef.getUrl();
    }
    
   public string getCustomerInvoiceHeaderFieldList() {
        String CustomerInvoiceHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Customer_Invoice__c', 'New_Customer_Invoice_Type');
        fieldInfoList.remove(0);
       
         if(!String.isBlank(custInvoice.id) && (custInvoice.Finalized__c ==true  || custInvoice.status__c=='Cancelled' || custInvoice.Void__c==true ))  {
             for(FieldInfo f:fieldInfoList ){
                f.editable=false;
          }
           return  JSON.serialize(fieldInfoList);
         }
        for(FieldInfo f:fieldInfoList ){
            if(f.field=='Invoice_Type__c'){
                f.editable=false;
            }
            if(f.field=='Status__c'){
                f.editable=false;
            }
        }
        CustomerInvoiceHeaderFieldList = JSON.serialize(fieldInfoList);
        return CustomerInvoiceHeaderFieldList;
    }
    public string getCustomerInvoiceAdditionalInfoList() {
     String CustomerInvoiceAdditionalInfoList = '';
        FieldInfo fieldInfoItem;
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Customer_Invoice__c', 'Additional_Information');
        fieldInfoList.remove(0);
        
        if(!String.isBlank(custInvoice.id) && (custInvoice.status__c=='Cancelled' || custInvoice.Void__c==true )) {
             for(FieldInfo f:fieldInfoList ){
                f.editable=false;
          }
         }
CustomerInvoiceAdditionalInfoList = JSON.serialize(fieldInfoList);        
        return CustomerInvoiceAdditionalInfoList;    
    }
   public string getCustomerInvoiceAddressFieldList() {
        String CustomerInvoiceHeaderFieldList = '';
        FieldInfo fieldInfoItem;
         if(String.isBlank(custInvoice.id)) {
            return JSON.serialize(new List<FieldInfo>());
         }
       List<FieldInfo> fieldInfoList =new  List<FieldInfo>();
       for(FieldInfo f:FieldInfo.fetchJsonFieldInfos('Customer_Invoice__c', 'Clone_Address_Information')){
           f.editable=false;
           fieldInfoList.add(f);
       }
       
        fieldInfoList.remove(0);
        CustomerInvoiceHeaderFieldList = JSON.serialize(fieldInfoList);
        return CustomerInvoiceHeaderFieldList;
    }
    
    public string getCustomerInvoiceTaxFieldList() {
        String CustomerInvoiceTaxFieldList = '';
        FieldInfo fieldInfoItem;
         if(String.isBlank(custInvoice.id)) {
            return JSON.serialize(new List<FieldInfo>());
         }
       try {
	       List<FieldInfo> fieldInfoList =new  List<FieldInfo>();
	       for(FieldInfo f:FieldInfo.fetchJsonFieldInfos('Customer_Invoice__c', 'Tax')){
	           f.editable=false;
	           fieldInfoList.add(f);
	       }
	       
	        fieldInfoList.remove(0);
	        CustomerInvoiceTaxFieldList = JSON.serialize(fieldInfoList);
	        return CustomerInvoiceTaxFieldList;
       }catch (FieldInfo.EmptyFieldSetMemberException e) {
            CustomerInvoiceTaxFieldList = '';
            return CustomerInvoiceTaxFieldList;
        }
       
    }
   public string getCustomerInvoiceAmountFieldList() {
        if(String.isBlank(custInvoice.id)) {
            return JSON.serialize(new List<FieldInfo>());
         }
        String CustomerInvoiceHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Customer_Invoice__c', 'Clone_Invoice_Amount');
        fieldInfoList.remove(0);
        for(FieldInfo finfo : fieldInfoList ){
             finfo.editable=false;
        }
        CustomerInvoiceHeaderFieldList = JSON.serialize(fieldInfoList);
        return CustomerInvoiceHeaderFieldList;
    }
   public string getCustomerInvoiceLinesFieldList() {
        FieldInfo fieldInfoItem;
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Customer_Invoice_Line__c', 'Line_Edit');
              List<FieldInfo> fieldInfoListToReturn = new  List<FieldInfo> ();
 		for(FieldInfo f:fieldInfoList){
          f.field = 'shiLine.' + f.field;
           fieldInfoListToReturn.add(f);
        }
  		List<FieldInfo>  segmentList  =FieldInfo.fetchJsonFieldInfos('Accounting_Default__c',SS.segmentNameList());
        for(FieldInfo segmentField: segmentList){
            if(segmentField.field.equalsIgnorecase('Id'  ) ){ continue;}
            if(segmentField.field.equalsIgnorecase('Company__c') ) { segmentField.hidden =true;}
                segmentField.field = 'segments.' + segmentField.field;
                fieldInfoListToReturn.add(segmentField);
            }
       
        if(TaxService.getInstance().taxServiceConfigured(custInvoice)){
            List<FieldInfo> fi = TaxService.getInstance().getDisplayFieldSet(Customer_Invoice__c.getSobjectType());

            if(fi != null){
            for(FieldInfo f : fi){
                f.field = 'shiLine.' + f.field;
	                boolean foundF = false;
	                for(FieldInfo fil : fieldInfoListToReturn){
	                	if(fil.field == f.field){
	                		fil.editable = f.editable;
	                		foundF = true;
	                		break;
	                	}
	                }

	                if(foundF == false){
                fieldInfoListToReturn.add(f);
            }

        }
        }
        }
       
       fieldInfoListToReturn[0].hidden= true;
      
        if(!String.isBlank(custInvoice.id) && (custInvoice.Finalized__c ==true  || custInvoice.status__c=='Cancelled' || custInvoice.Void__c==true )) {
             for(FieldInfo f:fieldInfoListToReturn ){
                f.editable=false;
          }
           return  JSON.serialize(fieldInfoListToReturn);
         }
       
       
       return JSON.serialize(fieldInfoListToReturn);
    }  
    
    @RemoteAction
    public static JsonResult getCompanyDetails(String companyId) {
    	List<Company__c> companies = new List<Company__c>();
    	SOQLUtil soql = new SOQLUtil('Company__c');
	    soql.addFields(new Set<String>{'Default_Transaction_Currency__c'});
	    soql.setWhereClause('id = :companyId');
	    
    	companies = Database.query(soql.getQuery());
    	return new JsonResult(companies, companies.size());
    }
    
    @remoteAction
    public static JSONResult getInvoice(String custInvoiceid,Boolean isCloneRequest) {
        JsonResult jr = new JsonResult();
        SOQLUtil soql = new SOQLUtil('Customer_Invoice__c');
        soql.addField('Name');
	    soql.addFields('New_Customer_Invoice_Type');
        soql.addFields('Clone_Address_Information');
        soql.addFields('Additional_Information');
        soql.addFields('Clone_Invoice_Amount');
        soql.addFields('Tax');
        soql.addFields(new Set<String>{'Transaction_date__c','Invoice_Type__c','Status__c','Void__c'}); //,'Customer_Receipt__c','Customer_Receipt__r.Transaction_ID__c'
	    soql.setWhereClause('id =:custInvoiceid'  );
        if(isCloneRequest){
          List<Customer_invoice__c> c1=  Database.query(soql.getQuery());
        Jr.records = new List<Sobject>();
         Customer_invoice__c newCI =   c1.get(0);
        newCI.Date_Invoiced__c = system.now();
        newCI.Status__c = 'Open';        
        newCI.Date_Time_Paid__c=null;
        newCI.Finalized__c=false;
        newCI.Finalized_hidden__c= false;
        newCI.Transaction_Date__c =system.now();
        newCI.Amount_Paid__c=0; //KNDY-15690
        newCI.Credit_Applied__c = 0;
        newCI.Debit_Applied__c = 0;
        newCI.Deduction_Amount__c = 0;
        newCI.Write_Off_Amount__c = 0;
        newCI.Discount_Taken__c = 0;
        newCI.changed_flag__c = false;
        newCI.Amount_Applied__c = 0;
        Jr.records.add(newCI.clone(false, false, false, false));
        }else{
        Jr.records =   Database.query(soql.getQuery());
        }
        jr.success=true;
        return jr;
        }    

    //KNDY-14524
    @remoteAction
    public static JsonResult getCustomerInfo(String billToCustomerId) {
        List<Customer__c> customers = new List<Customer__c>();
        SOQLUtil soql = new SOQLUtil('Customer__c');
        soql.addFields(new Set<String>{'Parent_Customer__c','Parent_Customer__r.Name','Payment_Term__c','Payment_Term__r.Name','Currency__c','Company__c','Company__r.Default_Transaction_Currency__c','Company__r.Default_Transaction_Currency__r.Name'});
        soql.setWhereClause('id = :billToCustomerId');
        
        customers = Database.query(soql.getQuery());
        return new JsonResult(customers, customers.size());
    }
    private Apexpages.StandardController controller;
        
    public SegmentService SS = new SegmentService();
	
    public pageReference checkUserErrors(){
    	if (custInvoice == null) {
            return null;
        }
        else {
        	invoiceType = custInvoice.Invoice_Type__c;
           // this.shiLineWrapperList = new List<SHILineWrapper>();
            
       		
	    	/*if (custInvoice.Finalized__c){
	    		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Info, 'Cannot edit finalized customer Invoice.'));
		        pgError = true;
	    		return null;
	    		
	    	} else*/ if(custInvoice.Status__c == CustomerInvoiceService.STATUS_CANCEL || custInvoice.Status__c == CustomerInvoiceService.STATUS_VOID) {
	    		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Cannot_edit_CILines_VoidCancel_CI));
		        pgError = true;
		        return null;
	    	}
	  		
        }
       
        return null;
    }
    @remoteAction 
    public static JsonResult getCustomerInvoiceLines(string cid ,Boolean isCloneRequest){
        JsonResult jr = new JsonResult();
          list<Customer_Invoice_Line__c> cil = new  list<Customer_Invoice_Line__c>();
        SOQLUtil soql = new SOQLUtil('Customer_Invoice_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields('Line_Edit');
		set<String> addFields = new set<string>{
			'Id','Name','Company__c','SystemModstamp','Description__c','Accounting_Segment__r.company__r.name','Shipment_Line__c','Product__r.Name',
			'Product__r.Item__c','Product__r.Item__r.Source__c','Product__c','Quantity_Shipped__c','Accounting_Segment__r.company__C',
			'Product__r.Item__r.Class__r.Type__c','Product__r.Item__r.Class__c','Accounting_Segment__r.id','Accounting_Segment__c',
			'Extended_Price__c','Discount_Percent__c','Unit_Price__c','Line_Type__c','Accounting_Segment__r.GL_Account__r.name','Off_Invoice_Rate__c',
			'BillBack_Rate__c'
		};
		SegmentService SS = new SegmentService();
		for(String fieldName : SS.segmentNameList()) {
			addFields.add('Accounting_Segment__r.'+fieldName);
		}
		soql.addFields(addFields);

      if(TaxService.getInstance().HasTaxService == true){
          List<FieldInfo> fi = TaxService.getInstance().getDisplayFieldSet(Customer_Invoice__c.getSobjectType());

          for(FieldInfo f : fi){
              soql.addField(f.field);
          }
      }
	soql.setWhereClause('customer_invoice__c = :cid');
	soql.setOrderByClause('createdDate');
	Database.query(soql.getQuery());
        for(Customer_Invoice_Line__c cl:  Database.query(soql.getQuery())){
         if(isCloneRequest){
           Customer_Invoice_Line__c cilclone=cl.clone(false,false,false,false);
           cilclone.customer_invoice__c =null;
           cil.add(cilclone) ; 
         }else{
          cil.add(cl);
         }
         
                                                  	
        
    }
     List<SHILineWrapper>   shiLineWrapperList = new List<SHILineWrapper> ();
      integer  count =0;
        for (Customer_Invoice_Line__c shiLine : cil){
            	SHILineWrapper shiLineWrapper = new SHILineWrapper(shiLine);
       			shiLineWrapper.shiLine = shiLine;

                    shiLineWrapper.c = new Customer_invoice__C(id=cid);

       			shiLineWrapper.rowindex = count;
       			shiLineWrapperList.add(shiLineWrapper);
	        	count++;
	       	}
        jr.success = true;
        jr.records = shiLineWrapperList;
        return jr;
    }
    /*
    private static SHILineWrapper setAccountingDefault(Customer_Invoice__c iv, SHILineWrapper il){
		Accounting_Default__c ad = new Accounting_Default__c();
		ad.Company__c = iv.Company__c;
		ad.GL_Account__c = il.segments.GL_Account__c;
		Accounting_Default__c oldAd = il.segments;

		if(oldAd == null || oldAd.GL_Account__c != ad.GL_Account__c || oldAd.Company__c != ad.Company__c ){
			//il.segments = null;
			//il.segments.Accounting_Default__r = ad;
		}
     return null;
	}
   */
    
    @RemoteAction
	public static JsonResult saveAction(Customer_Invoice__c inv, List<String> headerDateFields, List<SHILineWrapper> updatedList, List<SHILineWrapper> newList, List<SHILineWrapper> deletedList, List<String> dateFields){
		JsonResult jr = new JsonResult();

		Savepoint sp = Database.setSavepoint();
        List<Customer_Invoice__c> records = new List<Customer_Invoice__c>();

		KendoUtils.UpdateDateFields(inv, headerDateFields);
		for(SHILineWrapper invLine : updatedList) {
			KendoUtils.UpdateDateFields(invLine.shiLine, dateFields);
		}
		for(SHILineWrapper invLine : newList) {
			KendoUtils.UpdateDateFields(invLine.shiLine, dateFields);
		}
		for(SHILineWrapper invLine : deletedList) {
			KendoUtils.UpdateDateFields(invLine.shiLine, dateFields);
		}
        
        try{ 
        	
        	Boolean newAndFinalize = false;
    		if(String.isEmpty(inv.Id)){
    			//The Id is coming in as an empty string and not null. This breaks upsert
    			inv.Id = null;
             }
            
    			if( (inv.Finalized__c == true && inv.Id==null ) || (inv.Finalized__c == true && inv.Id!=null  && ( newList.size()>0 || updatedList.size()>0 )  )){
    				inv.Finalized__c = false;
    				newAndFinalize = true;
    			}
    	    DML.checkUpsertAsUser(inv);
        	upsert inv;

        	// save invoice lines
        	Set<String> errorLines = saveInvoiceLines(inv, updatedList, newList, deletedList, jr);
            system.debug('errorLines:::' + errorLines);
            for(String str :errorLines){
                jr.success = false;
                jr.addMessage(str,ApexPages.Severity.ERROR);
            }
            if(errorLines.size()>0){
                Database.rollback(sp);
                return jr;
            }
        	if(newAndFinalize == true){
        		inv.Finalized__c = true;
        		upsert inv;
        	}
    		records.add(inv);
			jr.records = records;
        }catch(DMLException dmlex){
            for (Integer idx = 0; idx < dmlex.getNumDml() ; idx++) {
                jr.addMessage( dmlex.getDmlMessage(idx), ApexPages.severity.ERROR);
            }
			jr.success = false;
            Database.rollback(sp);
            return jr;   
        }
        catch(Exception ex){
              jr.addMessage( ex.getMessage() +' '+ex.getStackTraceString(), ApexPages.Severity.ERROR);
			jr.success = false;
            Database.rollback(sp);
            return jr;
          
		}
			if(jr.messages.size()==0){
			jr.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
            jr.success=true;
            }else{
            jr.success=false;   
            }
		return jr;
	}
  @RemoteAction
	public static JsonResult getTaxAction(Id ciId){
	     
	    SOQLUtil cisSOQL = new SOQLUtil('Customer_Invoice__c');
	    cisSOQL.addFields(new Set<String>{'Id','name','Invoice_Type__c','Company__c'});
	    cisSOQL.setWhereClause('id = :ciId');
	    List<Customer_Invoice__c> cis = Database.query(cisSOQL.getQuery()); 
	     
	    
		TaxService ts = TaxService.getInstance();

		if(ts.taxServiceConfigured(cis[0])==true){
              TaxService.TaxResult tr = ts.getTax(ciId);
        
              JsonResult jr = new JsonResult();
              jr.success = tr.isSuccess;
              jr.addMessage(tr.message, ApexPages.Severity.CONFIRM);
        
              return jr;
		}else{
			return null;
		}
  }

    private static Set<String> saveInvoiceLines(Customer_Invoice__c inv, List<SHILineWrapper> updatedList, List<SHILineWrapper> newList, List<SHILineWrapper> deletedList, JSONResult result){
		Set<String> LineErrors = new Set<String>();
		List<SHILineWrapper> invoiceLines = new List<SHILineWrapper>();
        invoiceLines.addAll(updatedList);
        invoiceLines.addAll(newList);
		system.debug('inv, invoiceLines :' + inv + '   #     '+ invoiceLines);
        if (invoiceLines.size() > 0) {
         LineErrors = saveLines(inv, invoiceLines);
        } 
        if (deletedList.size() > 0) {
            // delete lines
          LineErrors.addAll(remove(inv, deletedList));
        }
         system.debug('LineErrors :::::'  + LineErrors);
         
		return LineErrors;
         }

     public static Set<String> remove(Customer_Invoice__c inv, List<SHILineWrapper> slwList) {     
           Set<String> retErrors = new Set<String>();
        for (SHILineWrapper slw : slwList) {
            Sobject ob = slw.shiLine;
            if (ob.id !=null) {
                try {
                    DML.deleteAsUser(ob);
                }
                catch(Exception e) { // could be caused by validations
                    retErrors.add(slw.shiLine.Name +': '+e.getMessage());
                }
            }          
        } 
        return retErrors;
    }
   
     public static Set<String> saveLines(Customer_invoice__c inv,List<SHILineWrapper> slwList ){
     		//need to create a counter, unlike SI where we use grid's rowUId, here we create an internal count. this will help mapping segments to invoiceLine
     		map<Integer,SHILineWrapper> mInvLineWrappers = new map<Integer,SHILineWrapper>();
     		for(integer i = 0; i < slwList.size(); ++i)
     			mInvLineWrappers.put(i,slwList[i]);
     			
        	List<String> SILNamesWarning = new List<String>();
            Set<String> SILErrors = new Set<String>();
		    List<Customer_Invoice_Line__c> shiLinesToSave = new List<Customer_Invoice_Line__c>();
		    list<Accounting_Default__c> segmentsToUpsert =  new list<Accounting_Default__c>();
		    list<Accounting_Default__c> segmentsToDelete =  new list<Accounting_Default__c>(); 
		    map<integer, Accounting_Default__c> mSegments2Validate = new map<integer, Accounting_Default__c>();
	    	List<ID> prodIds = new List<ID>();
	    	SegmentService SS = new SegmentService();
	    	list<String> segmentNames = SS.segmentNameList();
       		for (Integer i : mInvLineWrappers.keySet()) {
       			SHILineWrapper shil =  mInvLineWrappers.get(i);
       			system.debug(Logginglevel.ERROR,'shil.segments '+shil.segments);
       			system.debug(Logginglevel.ERROR,'shil.Product__c '+shil.shiLine.Product__c);
       			
       			boolean segmentIsEmpty = true;//KNDY-14061
   				
   				sObject accDefault = shil.segments;
   				system.debug(Logginglevel.ERROR,'accDefault '+accDefault);

   				if(accDefault != null){
   					system.debug(Logginglevel.ERROR,'accounting Default : ' + accDefault);
   					for(String fieldName : segmentNames) {
       					system.debug(Logginglevel.ERROR,'fieldName  '+fieldName);
       					
       					if( fieldName != 'Company__c' && fieldName != 'Id' ) {
       						system.debug(Logginglevel.ERROR,'accDefault.get(fieldName)  '+accDefault.get(fieldName));
       						if((accDefault.get(fieldName) != null && accDefault.get(fieldName) != '')) {
       						segmentIsEmpty = false; //KNDY-14061
       						break;
       					}
       				}
   				}
   				}
       			if (shil.shiLine.Product__c != null){
       				prodIds.add(shil.shiLine.Product__c);
       			}
       			
       			else if(shil.shiLine.Product__c == null && segmentIsEmpty)
       			{
               		 SILErrors.add(Label.Cannot_leave_both_product_and_accounting_segments_blank);
	        		 return SILErrors;
       			}
       			system.debug(Logginglevel.ERROR,'segmentIsEmpty '+segmentIsEmpty);
       			if(!segmentIsEmpty) {
       				 shil.segments.Company__c = inv.Company__c;
       				mSegments2Validate.put(i, shil.segments);
       			}else if(segmentIsEmpty && shil.segments != null && shil.segments.Id != null){
       				segmentsToDelete.add(shil.segments);
       				shil.shiLine.Accounting_Segment__c = null;
       			}
       			
       		}
       		system.debug(Logginglevel.ERROR,'mSegments2Validate '+mSegments2Validate);
       		if(!mSegments2Validate.isEmpty()) {
       			SegmentValidationService svs = SegmentValidationService.getInstance();
       			for(SegmentValidationService.SegmentValidationResponse svrLocal : svs.beforeValidateAccountingDefaults(mSegments2Validate.values())) {
       				 if(svrLocal.isValid == false){
       				 	system.debug(Logginglevel.ERROR,'segment validation is false');
       					SILErrors.add(Label.Segments_entered_are_not_valid);
	        		    return SILErrors;
       				 }
       			}
       		}
       		
       		// querying their item sources	
       		List<Product__c> prods = [Select id, Name, Item__c, Item__r.Source__c from Product__c where id =: prodIds];
       		
       		for (Product__c prod: prods){
	       		    if (prod.Item__r.Source__c != 'Miscellaneous') {   // TODO should this be Non_Inventory__c ~~!!
			        	 SILErrors.add(Label.Only_items_of_source_miscellanous_can_be_added);
			        	 return SILErrors;
			         } 
	       		}
		    	DML.checkUpsertAsUser(mSegments2Validate.values()); 
		    		upsert mSegments2Validate.values();
		    	DML.deleteAsUser(segmentsToDelete);
		        for (Integer i : mInvLineWrappers.keySet() ) {
		        	SHILineWrapper shil =  mInvLineWrappers.get(i);
		        	system.debug(Logginglevel.ERROR,' mSegments2Validate.get(i) '+ mSegments2Validate.get(i));
		        	shil.shiLine.Accounting_Segment__c = mSegments2Validate.get(i) != null ? mSegments2Validate.get(i).Id : shil.shiLine.Accounting_Segment__c;
                    shil.shiLine.customer_invoice__C = inv.id;
                    shil.c = inv;
		       		shiLinesToSave.add(shil.shiLine);
		        
		       } // end for each CIL
            DML.checkUpsertAsUser(shiLinesToSave); upsert shiLinesToSave;	  			
	   		return SILErrors;
    }
    

     public PageReference setCIName(){
      if(!String.isBlank(CustInvId)){
          custInvoice= (Customer_Invoice__c) getInvoice(CustInvId,false).records[0];
          system.debug(logginglevel.error,'custInvoice in setCIName '+ CustInvId + '- '+custInvoice);
          pgError=false;
      }
         
      if(isCloneRequest){
	      pageTitle = Label.Clone_of + ' ' +Schema.Customer_Invoice__c.getSObjectType().getDescribe().getLabel();
	      //custInvoice.name = Label.Clone_of +' '+ custInvoice.name;
	      System.debug(logginglevel.error,'custInvoice.name- in SetCI Name-->'+custInvoice.name); 
          System.debug(logginglevel.error,'isCloneRequest--->'+isCloneRequest); 
          custInvoice.finalized__c=false;
          ApexPages.getMessages().clear();
          isCloneRequest=false;  
      return null;  
      }else{
	      PageReference pgref = Page.CustomerInvoiceManage; 
	      System.debug(logginglevel.error,'pgref--->'+pgref); 
	      pgref.getParameters().put('id', custInvoice.Id);
	      pgref.getParameters().put('retURL', '/'+Customer_Invoice__c.sobjecttype.getDescribe().getKeyPrefix());    
	      pgref.setRedirect(true);
	      return pgref;
      }  
    }
    
     
    

    // wrapper class to hold the ship invoice line to pass the information when the addSegments is called.    
	public class SHILineWrapper{
		
		public Accounting_Default__c segments {get; set ; } 
	    public boolean showSegments {get; private set; } { showSegments = false; } 
	    public Customer_Invoice_Line__c shiLine { get; set;}
	    public Customer_Invoice__c c { get; set;}
	    public ID loc;
	    public integer rowindex {get; set;}
    	    	
        public SHILineWrapper(Customer_Invoice_Line__c shiL){
            this.shiLine = shiL; 
            if(this.c!=null) this.shiLine.customer_invoice__c =  this.c.id;
			if(shiL.Accounting_Segment__c != null){
				system.debug('shiL.Accounting_Segment__r '+shiL.Accounting_Segment__r);
				segments= shiL.Accounting_Segment__r  ;
			}
		}
	
	}   
   
}