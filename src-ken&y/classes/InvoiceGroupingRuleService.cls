public with sharing class InvoiceGroupingRuleService {
	
	public static InvoiceGroupingRuleService getInstance(){
        if ( instance == null ) instance = new InvoiceGroupingRuleService();
        return instance;
    } 
   	private static InvoiceGroupingRuleService instance = null;
	public static map<Id,FlErrMsgWrapper> mapFlErrorMsgWrapper = new map<Id,FlErrMsgWrapper>();
	public static final String FREQUENCY_PERIOD_DAY = 'Day';
	public static final String FREQUENCY_PERIOD_WEEK = 'Weekly';
	public static final String FREQUENCY_PERIOD_MONTH = 'Monthly';
	public static final String FREQUENCY_PERIOD_QUARTER = 'Quarterly';
	public static final String FREQUENCY_PERIOD_ANNUAL = 'Annual';
	public static final String FREQUENCY_PERIOD_IMMEDIATE = 'Immediate';
	public static boolean requestFromUI = false;   //KNDY-15790
	
	public class InvoiceGroupingRuleWrapper{
		
		String groupingCriteriaStr ;
		DateTime startDate;
		DateTime endDate;
		Invoice_Grouping_Rule__c igrRecord;
		Id igrId;
		Set<Id> forAgreements;
		Set<Id> forCategories ;
		Set<Id> forCustomers;
		Set<Id> forProducts;
		
		public InvoiceGroupingRuleWrapper(Invoice_Grouping_Rule__c igr){
			startDate = igr.Start_Date__c;
			endDate = igr.End_Date__c;
			igrId = igr.Id;
			groupingCriteriaStr = getGroupingCriteriaDescription(igr);
			igrRecord = igr;
			forAgreements = (igr.For_Agreements__c != null) ? (Set<Id>)JSON.deserialize(String.valueOf(igr.For_Agreements__c), Set<Id>.Class) : null;
			forCategories = (igr.For_Categories__c != null) ? (Set<Id>)JSON.deserialize(String.valueOf(igr.For_Categories__c), Set<Id>.Class) : null;
			forCustomers =  (igr.For_Customers__c != null) ? (Set<Id>)JSON.deserialize(String.valueOf(igr.For_Customers__c), Set<Id>.Class) : null;
			forProducts =   (igr.For_Products__c != null) ? (Set<Id>)JSON.deserialize(String.valueOf(igr.For_Products__c), Set<Id>.Class)  : null;
		}
	}
	
	public class SoqlStructure{
		Set<String> dateFields = new Set<String>{'Start_Date__c', 'End_Date__c', 'Recurrence_Start_Date__c'};
		Set<string> fieldsGrouped =  new Set<String> {
		'for_agreement__c','for_category__c','for_customer__c','for_product__c',
		'group_by_agreements__c','group_by_category__c','group_by_customer_hierarchy__c',
		'group_by_product__c','group_by_sales_order_if__c','group_by_sales_order_types__c',
		'group_by_sales_orders__c','group_by_shipments__c', 
		'for_customers__c', 'For_Categories__c','For_Agreements__c','For_Products__c'};
		Set<String> additionalFields = new Set<String> {
			'Name', 'company__c','For_Customer__r.name', 'For_Category__r.Name',
			'For_Product__r.Name', 'For_Agreement__r.Name'};
		String soql='';
	}
	
	public static final String GROUP_ENTIRE_SO = 'Order is closed';// Entire Sales Order Is Closed
	public static final String GROUP_ENTIRE_SOL = 'Order line is closed'; // Entire Sales Order Line is Closed
	//public static final String GROUP_AS_FULFILLED = 'Neither (invoice lines as fulfilled)';

	
	
	public class InvoiceGroupingRuleServiceException extends Exception{}
	public class ConsolidatedInvoiceException extends Exception{}
	public enum FulfillmentType { RECURRING, AGGREGATE, ALLOWANCE_ACCRUAL } //KNDY-14714
	public static final map<FulfillmentType, string> mFulfillmentTypeWorkers = new map<FulfillmentType, string>{FulfillmentType.RECURRING => 'RecurringConsolidateInvoicing', FulfillmentType.AGGREGATE => 'AggregateConsolidateInvoicing', FulfillmentType.ALLOWANCE_ACCRUAL => 'AllowanceAccrualConsolidateInvoicing'}; //KNDY-14713
	
	SchemaUtil util = SchemaUtil.getInstance();
	private dateTime timeNow = system.now();
	private string immediate = FrequencyService.FREQUENCY_PERIOD_IMMEDIATE;
	private string  allowanceAccrual = AllowanceRuleService.ALLOWANCE_ACCRUAL;
	private Date dateToday =  Date.today();
	
	@TestVisible 
	public DateTime testFFEndDate = DateTime.newInstance(dateToday.year()+1,5,30,10,0,0);
	private Datetime tomorrowStartDateTime = Test.isRunningTest()? testFFEndDate: Datetime.newInstance(dateToday,Time.newInstance(0,0,0,0)).addDays(1);
	private String tomorrowStartDateTimeStr = util.formatDateTimeForSOQL(tomorrowStartDateTime);
	
	private String whereClause = 'Id not in (Select Fulfillment__c from Customer_Invoice_Sub_Line__c where (Customer_Invoice_Line__r.Customer_Invoice__r.Status__c in(\'Open\',\'Closed\') or Customer_Invoice_Line__r.Has_Exceptions__c = true '+
								 'or Customer_Invoice_Line__r.Customer_Invoice__r.Has_Exceptions__c = true)  AND (Fulfillment__r.Price_Type__c = \'Sales\' or Fulfillment__r.Type__c = :allowanceAccrual) AND '+
								 'Fulfillment__r.Fulfillment_Date__c < ' + tomorrowStartDateTimeStr + ')'+
								 ' AND Id NOT IN (Select Fulfillment__c from Customer_Invoice_Sub_Line__c where (Fulfillment__r.Start_Date__c > :timeNow OR Fulfillment__r.Last_Bill_Date__c > :timeNow OR '+
								 ' Fulfillment__r.Fulfillment_Fully_Invoiced_2__c = true) AND Fulfillment__r.Price_Type__c = \'Recurring\') '+
								 ' and Invoice_Ready__c = true and Invoice_Hold__c = false and Status__c = \'Complete\' and Quantity__c != 0'; //KNDY-12820	
																			
	private set<String> fieldsForFulfillment = new set<String>{'Id', ' Name', ' Unit_Price__c', ' Quantity__c', ' Fulfillment_Date__c', ' Company__c', ' Customer__c', ' Agreement_Line__c', ' Sales_Order_Line__c', ' Shipment_Line__c', ' Category__c', 'Rate_Basis__c', 
																'Product__c', 'Currency__c','Currency__r.ISO_Code__c','Currency__r.ID' ,'Company__r.comp_currency__c','Company__r.comp_currency__r.ISO_Code__c','Company__r.consol_currency__c','Company__r.consol_currency__r.ISO_Code__c','Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c', 'Company__r.Subs_Currency__r.ISO_Code__c', 'Sales_Order_Line__r.Occurrence__c', 'Sales_Order_Line__r.Rate_Basis__c', 'Sales_Order_Line__r.Start_Date__c', 'Sales_Order_Line__r.End_Date__c',
																'Payment_Term__c', 'Sales_Order_Line__r.Status__c', ' Sales_Order_Line__r.Sales_Order__c', ' Sales_Order_Line__r.Sales_Order__r.Type__c','Sales_Order_Line__r.Description__c', 
																'Sales_Order_Line__r.Product_Reference__c','Sales_Order_Line__r.Customer_ID__c','Sales_order_line__r.Pricebook__c','Pricing_Uom__c','Agreement__c',
																'Sales_Order_Line__r.Sales_Order__r.Status__c', 'Sales_Order_line__r.Sales_Order__r.Currency__c',' Agreement_Line__r.Agreement__c', 'Start_Date__c', ' End_Date__c', 'Invoice_Ahead__c', 'Agreement_Line__r.Pricing_UOM__c', 'Agreement_Line__r.Agreement_Price__c',
																'Allowance_Applied__c','Last_Bill_Date__c', ' Type__c', 'Customer__r.RecordType.DeveloperName', ' Customer__r.Parent_Customer__c', ' Customer__r.Parent_Customer__r.Parent_Customer__c', 'Customer__r.Parent_Customer__r.Parent_Customer__r.Parent_Customer__c',
																'Agreement_Line__r.Agreement__r.Billing_Uom__c','Agreement_Line__r.Start_Date__c', 'Parent_Fulfillment__r.Start_Date__c', 'Parent_Fulfillment__c',

																'Shipment_Line__r.Shipment__c', ' Occurrence__c', ' Sales_Order_Line__r.Discount_Percent__c', 'Sales_Order_Line__r.Off_Invoice_Rate__c',
																'Sales_Order_Line__r.BillBack_Rate__c', ' Sales_Order_Line__r.List_Price__c', ' Sales_Order_Line__r.Line_Type__c', 'Customer__r.Top_Parent_Customer__r.Default_Bill_To_Customer__c',
																'Customer__r.Top_Parent_Customer__c', ' Agreement_Line__r.Agreement__r.Activation_Date__c' ,'Invoice_Hold__c','Sales_Order_Line__r.Sales_Order__r.Has_Exceptions__c','Shipment_Line__r.Shipment__r.Has_Exceptions__c',
																'Shipment_Line__r.Shipment__r.Customer__c','Shipment_Line__r.Shipment__r.Customer__r.Parent_Customer__c', 'Sales_Order_Line__r.Sales_Order__r.Customer__c','Shipment_Line__r.Sales_Order_Line__r.Sales_Order__c',
																'Pricing_UOM__r.Every__c', 'Pricing_UOM__r.Recurrence__c', 'Recurrence_Start_Date__c','Billing_UOM__r.Every__c', 'Billing_UOM__r.Recurrence__c','Price_Type__c','Sales_Order_Line__r.Discount_Amount__c'};
	
	public static final map<string, string> mObjectPaths = new map<string, string>{
		'Fulfillment__c'  => 'Id',
		'Sales_Order__c'  => 'Sales_Order_Line__r.Sales_Order__c',
		'Shipment__c'     => 'Shipment_Line__r.Shipment__c',
		'Agreement__c'    => 'Agreement_Line__r.Agreement__c',
		'Product__c'      => 'Product__c',
		'Category__c'     => 'Category__c'
	};
	
	public interface ConsolidatedInvoice {
		//Should be implemented by all types of FulfillmentTypeclass
		void consolidate(map<InvoiceGroupingRuleContainer,list<Fulfillment__c>> containerToFulfillments, map<String,Customer_Invoice__c> mCIs, map<String,Customer_Invoice_Line__c> mCILs, 
								     Id batchJObId, map<String,Customer_Invoice_Sub_Line__c> mFulfillmentMap, map<Id,Fulfillment__c> mFulfillmentsToUpdate);
	
	}
	
		
	public map<Id,Fulfillment__c> getFulfillments(String objectName, set<Id> objIds) {
		
		String query = getBasicQuery() + ' and '+mObjectPaths.get(objectName)+' in :objIds';
		query = query + ' FOR UPDATE'; //locking fulfillments
		system.debug(logginglevel.error,' igr query: '+query);
		return new map<Id,Fulfillment__c>((list<Fulfillment__c>)Database.query(query));
	}
	
	public set<String> getFieldsForFulfillment () {
		return fieldsForFulfillment;
	}
	public String getWhereClause() {
		return whereClause;
	}
	
	private String getBasicQuery() {
		return util.generateQueryFromFieldSet('Fulfillment__c', new set<String>{},fieldsForFulfillment, whereClause);
	}
	
	public class FlErrMsgWrapper{
		public id FlId;
		public list<string> lstErrorMsg;
		public string FlName;
		public FlErrMsgWrapper(){}
		public FlErrMsgWrapper(id FlId, list<string> lstErrorMsg, string FlName){
			this.FlId = FlId;
			this.lstErrorMsg = lstErrorMsg;
			this.FlName = FlName;
		}
	}
	
	public map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>> buildTypeToFulfillments(map<Id,Fulfillment__c> mFulfillments, list<InvoiceGroupingRuleDefinition> sortedRules) {
		map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>> typeToFulfillments  = new map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>>();
		sortedRules.sort(); //will sort in descending as modified the comaprable. 
		map<id, Id> mapCorpToOneBillTo = new map<Id,Id>();
		set<Id> topParentCustomerIds = KSE.grepRelatedIdSetFromList( mFulfillments.values() , 'Customer__r.Top_Parent_Customer__c', true);
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		soql.setWhereClause('recordType.DeveloperName = \'Corporate_Parent\' and Id in :topParentCustomerIds');
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Customers__r');
		childRel.addFields(new set<string>{
			'Id','Name'
		});
		childRel.setWhereClause('recordType.DeveloperName = \'Bill_To\' ');
		soql.addChildRelationship(childRel);
		
        for(Customer__c corP : Database.query(soql.getQuery())){
             if(corp.Customers__r != null && corp.Customers__r.size() == 1)
					mapCorpToOneBillTo.put(corp.Id, corp.Customers__r[0].Id);
		
		}
		for(Fulfillment__c f : mFulfillments.values()) {
			system.debug(logginglevel.error,'f '+ f);
			for(InvoiceGroupingRuleDefinition ruleDef : sortedRules) {
					InvoiceGroupingRuleContainer container;
					InvoiceGroupingRuleDefinition.status status = InvoiceGroupingRuleDefinition.isQualifiedWithMessage(f,ruleDef);
					boolean dateIssues = false;
					System.debug(logginglevel.error,'status--->'+status);
				   if(status.qualifies) {
					system.debug(logginglevel.error,' i qualified!');
					
					System.debug(logginglevel.error,'mapFlErrorMsgWrapper---before---***>'+mapFlErrorMsgWrapper);
					if(status.qualifies && mapFlErrorMsgWrapper != null && mapFlErrorMsgWrapper.size() > 0 && mapFlErrorMsgWrapper.containsKey(f.Id)) {
	                     if(mapFlErrorMsgWrapper.get(f.Id).lstErrorMsg != null && mapFlErrorMsgWrapper.get(f.Id).lstErrorMsg.size() > 0){
	                       mapFlErrorMsgWrapper.get(f.Id).lstErrorMsg.clear(); 
	                     } 
					}  
					System.debug(logginglevel.error,'mapFlErrorMsgWrapper---after---***>'+mapFlErrorMsgWrapper);  
					
					if(f.Type__c == AllowanceRuleService.ALLOWANCE_ACCRUAL){ //KNDY-14713
						container = new InvoiceGroupingRuleContainer(f, mapCorpToOneBillTo);
					}
					else{
						container = new InvoiceGroupingRuleContainer(f, ruleDef, mapCorpToOneBillTo);
					}
					system.debug(logginglevel.error,'container '+container);
					if (f.Type__c == AllowanceRuleService.ALLOWANCE_ACCRUAL ){ //KNDY-14713
						// IGR container recurrence start date is set null , 
						// and periodicity is set to FREQUENCY_PERIOD_IMMEDIATE 
						// for Allowance Accrual FFs
						Date recurrenceStartDate = container.recurrenceStartDate;
						Integer dateOn = recurrenceStartDate == null ? null : recurrenceStartDate.day();
						Date dateInvoiced = container.periodicity == FrequencyService.FREQUENCY_PERIOD_IMMEDIATE ? system.today() : FrequencyService.closestFutureBillingDate(f.Fulfillment_Date__c.date(), recurrenceStartDate, container.periodicity, 
																																										  dateOn, container.everyPeriodicity);
					
						if(dateInvoiced > system.today()) { //KNDY-9322 If the rule dictates the fulfillmnet should be invoiced in the future, then do not invoice it now!
							if(InvoiceGroupingRuleService.mapFlErrorMsgWrapper.containskey(f.Id)){
								InvoiceGroupingRuleService.mapFlErrorMsgWrapper.get(f.Id).lstErrorMsg.add('Fulfillment can only be invoiced on '+dateInvoiced);
							}else{
								InvoiceGroupingRuleService.mapFlErrorMsgWrapper.put(f.Id,new InvoiceGroupingRuleService.FlErrMsgWrapper(f.Id, 
																			  new list<string>{'Fulfillment can only be invoiced on '+dateInvoiced}, 
																			  f.name));
							}
						}
						else{
							pushToMap(typeToFulfillments, InvoiceGroupingRuleService.FulfillmentType.ALLOWANCE_ACCRUAL, f, container);
						}
					}
					else if(f.Price_Type__c == 'Recurring' && f.Start_Date__c != null) { // implies Recurring fulfillment type 
						System.debug(logginglevel.error, f.Start_Date__c +'  '+ f.Price_Type__c);
						pushToMap(typeToFulfillments, InvoiceGroupingRuleService.FulfillmentType.RECURRING, f, container);
						
					}else if(f.Price_Type__c == 'Sales' && f.Fulfillment_Date__c < tomorrowStartDateTime) {
						pushToMap(typeToFulfillments, InvoiceGroupingRuleService.FulfillmentType.AGGREGATE, f, container);
					}else
						dateIssues = true;
					
					if(dateIssues) {
					    system.debug(logginglevel.error,'mapFlErrorMsgWrapper'+mapFlErrorMsgWrapper);
					if(mapFlErrorMsgWrapper.containskey(f.Id)){
						if(f.Start_Date__c == null && f.Price_Type__c == 'Recurring'){
							mapFlErrorMsgWrapper.get(f.Id).lstErrorMsg.add('Fulfillment doesnt have start date');
						}else if(f.Price_Type__c == 'Sales' &&  f.Fulfillment_Date__c < tomorrowStartDateTime){
							mapFlErrorMsgWrapper.get(f.Id).lstErrorMsg.add(status.message);//No errors
						}else{
							mapFlErrorMsgWrapper.get(f.Id).lstErrorMsg.add('Fulfillment date is in future');
						}
					}else{
						if(f.Start_Date__c == null && f.Price_Type__c == 'Recurring'){ 
							mapFlErrorMsgWrapper.put(f.Id,new FlErrMsgWrapper(f.Id, 
																			  new list<string>{'Fulfillment doesnt have start date'}, 
																			  f.name));
						}else if(f.Price_Type__c == 'Sales' && f.Fulfillment_Date__c < tomorrowStartDateTime){ //No errors
							mapFlErrorMsgWrapper.put(f.Id,new FlErrMsgWrapper(f.Id, new list<string>{status.message}, f.name));
						}else{
							mapFlErrorMsgWrapper.put(f.Id,new FlErrMsgWrapper(f.Id, 
																			  new list<string>{'Fulfillment date is in future'}, 
																			  f.name));
						}
					}
					system.debug('mapFlErrorMsgWrapper after'+mapFlErrorMsgWrapper);
					}
					
					
					
					break;//no need to match this fulfillment to other ruleDefs. move on to next fulfillment. 
				}else {
					//system.debug(logginglevel.error,'mapFlErrorMsgWrapper'+mapFlErrorMsgWrapper);
					if(mapFlErrorMsgWrapper.containskey(f.Id)){
						mapFlErrorMsgWrapper.get(f.Id).lstErrorMsg.add(status.message);
					}else{
						mapFlErrorMsgWrapper.put(f.Id,new FlErrMsgWrapper(f.Id, new list<string>{status.message}, f.name));
					}
					system.debug(logginglevel.error,'mapFlErrorMsgWrapper'+mapFlErrorMsgWrapper);
				}
			}//END OF RULES LOOP
		}//END OF FULFILLMENTS LOOP		
		return typeToFulfillments;
	}
	
	private void pushToMap(map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>> typeToFulfillments, InvoiceGroupingRuleService.FulfillmentType  fType, Fulfillment__c f, InvoiceGroupingRuleContainer container) {
		System.debug(logginglevel.error,'typeToFulfillments--->'+typeToFulfillments);
		System.debug(logginglevel.error,'fType--->'+fType);
		if(typeToFulfillments.containsKey(fType)) {
			map<InvoiceGroupingRuleContainer,list<Fulfillment__c>> mFs = typeToFulfillments.get(fType);
			if(mFs.containsKey(container)) {
				list<Fulfillment__c> lFs = mFs.get(container);
				lFs.add(f);
				mFs.put(container,lFs);
			}
			else
				mFs.put(container,new list<Fulfillment__c>{f});
			
			typeToFulfillments.put(fType,mFs);
		}
		else {
			map<InvoiceGroupingRuleContainer,list<Fulfillment__c>> mFs = new map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>();
			mFs.put(container, new list<Fulfillment__c>{f});
			typeToFulfillments.put(fType,mFs);
		}
		System.debug(logginglevel.error,'typeToFulfillments--->'+typeToFulfillments);
		
	}
	
	public void createInvoices(map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>> typeToFulfillments, Id batchJobId, map<String,Customer_Invoice__c> mCIs, map<String,Customer_Invoice_Line__c> mCILs, 
							   map<String,Customer_Invoice_Sub_Line__c> mFulfillmentMap, map<Id, Fulfillment__c> mFulfillmentsToUpdate) {
		
		if(!typeToFulfillments.isEmpty()) {
	   		for(InvoiceGroupingRuleService.FulfillmentType fType : typeToFulfillments.keySet()) {
	   			if(!typeToFulfillments.get(fType).isEmpty()) {
	   				Type t = Type.ForName(InvoiceGroupingRuleService.mFulfillmentTypeWorkers.get(fType));
            		InvoiceGroupingRuleService.ConsolidatedInvoice consolidateService = (InvoiceGroupingRuleService.ConsolidatedInvoice)t.newInstance();
            		System.debug(logginglevel.error, 'mFulfillmentMap-->'+mFulfillmentMap);
            		consolidateService.consolidate(typeToFulfillments.get(fType), mCIs, mCILs, batchJobId, mFulfillmentMap, mFulfillmentsToUpdate);
	   			}
	   		}
	  	 }
		
	}
	
	public void finishConsolidate(map<String,Customer_Invoice__c> mCIs, map<String,Customer_Invoice_Line__c> mCILs, map<String,Customer_Invoice_Sub_Line__c> mFulfillmentMap, map<Id,Fulfillment__c> mFulfillmentsToUpdate) {
		
		system.debug(logginglevel.error,'mCIs '+mCIs);
		system.debug(logginglevel.error,'mCILs '+mCILs);
		system.debug(logginglevel.error,'mFulfillmentMap '+mFulfillmentMap);
		system.debug(logginglevel.error,'mFulfillmentsToUpdate '+mFulfillmentsToUpdate);
		if(!mCIs.isEmpty())
			DML.checkUpsertAsUser(mCIs.values()); upsert mCIs.values() Source_Key__c;
		
		if(!mCILs.isEmpty())
			DML.checkUpsertAsUser(mCILs.values()); upsert mCILs.values() Source_Key__c;
		
		if(!mFulfillmentMap.isEmpty())
			DML.insertAsUser(mFulfillmentMap.values());
		
		if(!mFulfillmentsToUpdate.isEmpty())
			DML.updateAsUser(mFulfillmentsToUpdate.values());
		
		//Consolidate Quantities from sub lines
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Customer_Invoice_Sub_Line__c', true,true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'sum(Fulfillment__r.Quantity__c) qty','Customer_Invoice_Line__c cilId'
		});
        List<Customer_Invoice_Line__c>  cilList =  mCILs.values();      
        soql.setWhereClause('Customer_Invoice_Line__c IN :cilList GROUP BY Customer_Invoice_Line__c');
		List<AggregateResult> arSublineTotals = Database.query(soql.getQuery());

		map<Id, AggregateResult> mARs = new map<Id, AggregateResult>();
		for(AggregateResult ar : arSublineTotals){
			mARs.put((Id)ar.get('cilId'), ar);
		}
		for(Customer_Invoice_Line__c cil : mCILs.values()){
			if(mARs.containsKey(cil.Id)){
				cil.Quantity_Shipped__c = decimal.valueOf(string.valueOf(mARs.get(cil.Id).get('qty')));
			}
		}
		DML.updateAsUser(mCILs.values());
		
	}
	
	
					
					
	public static void validateRuleForProductAndCategory() {
		
		if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
			for(Invoice_Grouping_Rule__c igr : (list<Invoice_Grouping_Rule__c>) trigger.new) {
				integer count = 0;
				if(igr.For_Categories__c != null)
					count++;
				if(igr.For_Products__c != null)
					count++;
				if(igr.Group_By_Category__c != false)
					count++;
				if(igr.Group_By_Product__c != false)
					count++;
				
				if(count > 1)
					igr.addError('Cannot select more than one criteria for Categories and Products');
					
				
				
			
			}
		}
		
	}

	public static void setRankKey() {
        list<Invoice_Grouping_Rule__c> igrsToSetRownums= new list<Invoice_Grouping_Rule__c>();
		if(trigger.isBefore && trigger.isUpdate) {
			for(Invoice_Grouping_Rule__c igr : (list<Invoice_Grouping_Rule__c>) trigger.new) {
                if( ( (Invoice_Grouping_Rule__c)trigger.oldmap.get(igr.id)).is_active__c ==False  && igr.is_Active__c  == true ){
                   igrsToSetRownums.add(igr);
                }else{
				igr.Rank_Key__c = igr.is_Active__c  == true ? igr.Company__c+'|'+igr.Rank__c : null;
				igr.Rank__c = igr.is_Active__c  == true ? igr.Rank__c : null;  
                }
				system.debug('igr.Rank_Key__c '+igr.Rank_Key__c);
			}
            if(igrsToSetRownums.size()>0){
                setLineNumbers(igrsToSetRownums);
            }
		}
		else if(trigger.isBefore && trigger.isInsert) {
			setLineNumbers((list<Invoice_Grouping_Rule__c>) trigger.new);
		}
	}
	
    public static void checkDuplicates() {
        boolean changed = false;
        Invoice_Grouping_Rule__c errRec;
        
        if(trigger.isafter && (trigger.isUpdate || trigger.isInsert) ){
            SoqlStructure soqlStruct = new SoqlStructure();
            for( sobject rec:trigger.new ){
                Set<String> igrFields = new Set<String>();
                igrFields.addAll(soqlStruct.fieldsGrouped);
                igrFields.addAll(soqlStruct.dateFields);
                for(String pStringField: igrFields){ 
                    if(trigger.isInsert){
                        changed=true;
                    }
                    else{
                        changed=  KSE.isFieldChanging(pStringField, rec, trigger.oldmap);
                    }
                    if(changed){
                        errRec= (Invoice_Grouping_Rule__c)rec; 
                        break;
                    }
                }
            }
            //Assumption: 1 IGR will be inserted or updated at a time
            if(changed){
                String error = validateIGRs(errRec);
                if (!String.isBlank(error)){
                    errRec.addError(error);
                }
            }
        }
    }
    
    // Check for duplicates among all existing igrs
    public static String validateIGRs(Invoice_Grouping_Rule__c newIgr){
         String error = '';
         SoqlStructure soqlStruct = createSoql(newIgr.Company__c);
         
         // query all IGRs
         List<Invoice_Grouping_Rule__c> igrs = Database.query(soqlStruct.soql);//running in system mode
         //system.debug(LoggingLevel.Error, '>>> query igrs: ' + igrs);
         Map<Id, InvoiceGroupingRuleWrapper> igrWrapperMap = new Map<Id, InvoiceGroupingRuleWrapper>();
         Map<Id, InvoiceGroupingRuleWrapper> existingDuplicateIgrWrapperMap = new Map<Id, InvoiceGroupingRuleWrapper>();
         		
         for (Invoice_Grouping_Rule__c igr :igrs){
         	InvoiceGroupingRuleWrapper igrWrapper = new InvoiceGroupingRuleWrapper(igr);
         	igrWrapperMap.put(igr.Id, igrWrapper);
         }
         system.debug(LoggingLevel.Error, '>>> igrWrapperMap: ' + igrWrapperMap);
         
         InvoiceGroupingRuleWrapper newIgrWrapper = igrWrapperMap.get(newIgr.Id);
         
         // get existing igrs for same grouping criteria
         String newIgrGroupingCriteria = igrWrapperMap.get(newIGR.Id).groupingCriteriaStr;
         for (InvoiceGroupingRuleWrapper igrWrapper :igrWrapperMap.values()){
             if (igrWrapper.igrRecord.Id != newIgr.Id){
                if (igrWrapper.groupingCriteriaStr == newIgrGroupingCriteria){
                    existingDuplicateIgrWrapperMap.put(igrWrapper.igrRecord.Id, igrWrapper);

                    if (newIgrGroupingCriteria.contains('Multiple Customers') && 
                            newIgrWrapper.forCustomers != igrWrapper.forCustomers){
                        system.debug(LoggingLevel.Error,'>>> Multi Customers removing igr');
                        existingDuplicateIgrWrapperMap.remove(igrWrapper.igrRecord.Id);
                    }
                    else if (newIgrGroupingCriteria.contains('Multiple Agreements') && 
                           newIgrWrapper.forAgreements!= igrWrapper.forAgreements){
                        system.debug(LoggingLevel.Error,'>>> Multi Agreements removing igr');
                        existingDuplicateIgrWrapperMap.remove(igrWrapper.igrRecord.Id);
                    }
                    else if (newIgrGroupingCriteria.contains('Multiple Categories') && 
                            newIgrWrapper.forCategories != igrWrapper.forCategories){
                        system.debug(LoggingLevel.Error,'>>> Multi Categories removing igr');
                        existingDuplicateIgrWrapperMap.remove(igrWrapper.igrRecord.Id);
                    }
                    else if (newIgrGroupingCriteria.contains('Multiple Products') && 
                            newIgrWrapper.forProducts != igrWrapper.forProducts){
                       system.debug(LoggingLevel.Error,'>>> Multi Products removing igr');
                        existingDuplicateIgrWrapperMap.remove(igrWrapper.igrRecord.Id);
                    }
                }
             }
         }
         
         // validate dates
         if (existingDuplicateIgrWrapperMap.size() > 0){
            for (InvoiceGroupingRuleWrapper igrWrapper : existingDuplicateIgrWrapperMap.values()){
                error = validateIGRDates(igrWrapper, igrWrapperMap.get(newIGR.Id));
                if (!String.isBlank(error)){
                    break;
                }
            }
         }
         return error;
    }
    
    public static String validateIGRDates(InvoiceGroupingRuleWrapper existingIGRWrapper, 
                                          InvoiceGroupingRuleWrapper newIGRWrapper){
        String error = '';
        DateTime existingIgrEndDate = existingIGRWrapper.EndDate;
        DateTime existingIgrStartDate = existingIGRWrapper.StartDate;
        DateTime newIgrStartDate = newIGRWrapper.startDate;
        DateTime newIgrEndDate = newIGRWrapper.endDate;
        system.debug(LoggingLevel.Error, '>>>newIgrStartDate IGR wrapper: ' + newIgrStartDate);
        system.debug(LoggingLevel.Error, '>>>newIgrEndDate  IGR wrapper: ' + newIgrEndDate);
        system.debug(LoggingLevel.Error, '>>>existingIgrStartDate: ' + existingIgrStartDate);
        system.debug(LoggingLevel.Error, '>>>existingIgrEndDate: ' + existingIgrEndDate);
        if (newIgrEndDate == null){
            if (existingIgrEndDate == null){
                return getErrorMessage(existingIGRWrapper);
            }
            else{//start date exists, end date not null
                error = checkDuplicateIGRDates(existingIGRWrapper,newIGRWrapper);
                if (!String.isBlank(error)){
                    return error;
                }
            }
         }
         else{//newIgrEndDate is not null
            if (existingIgrEndDate != null){
                error = checkDuplicateIGRDates(existingIGRWrapper,newIGRWrapper);
                if (!String.isBlank(error)){
                    return error;
                }
            }
            else{//existingIgrEndDate is null
                if (newIgrEndDate > existingIgrStartDate ){
                    return getErrorMessage(existingIGRWrapper);
                }
            }
         }
         return error;
    }
    
    private static String checkDuplicateIGRDates(InvoiceGroupingRuleWrapper existingIGRWrapper,
                                                 InvoiceGroupingRuleWrapper newIGRWrapper) {
        String error = '';
        DateTime newIgrStartDate = newIGRWrapper.startDate;
        DateTime newIgrEndDate = newIGRWrapper.endDate;
        DateTime existingIgrStartDate = existingIGRWrapper.StartDate;
        DateTime existingIgrEndDate = existingIGRWrapper.EndDate;
        system.assert(existingIgrEndDate != null);
        
        if(newIgrEndDate == null){
            if(newIgrStartDate < existingIgrEndDate){
                return getErrorMessage(existingIGRWrapper);
            }
        }
        //start and end dates overlap with another IGR
        if (newIgrStartDate >= existingIgrStartDate && newIgrEndDate <= existingIgrEndDate){
            return getErrorMessage(existingIGRWrapper);
        }
        //  start date or end date perior is between a period not covered by other other IGRs
        // igr1 ------          igr2---------
        // newigr     ----------
        if (newIgrStartDate >= existingIgrEndDate || newIgrEndDate <= existingIgrStartDate){
            //valid dates
        }
        else{
            return getErrorMessage(existingIGRWrapper);
        }
        return error;
    }
    
    private static String getErrorMessage(InvoiceGroupingRuleWrapper existingIGRWrapper){
       String hyperlink = '<a href="/'+ existingIGRWrapper.igrRecord.Id + '">' + existingIGRWrapper.igrRecord.Name + '</a>';
       String error = Label.Change_dates_on_IGR + hyperlink ;
       return error;
    }
    
    public static SoqlStructure createSoql(Id companyId){
        SoqlStructure soqlStruct= new SoqlStructure();
        String retStr= '';
        String fieldsToQuery = '';
        for (String s : soqlStruct.fieldsGrouped){
            fieldsToQuery += ',' + s;
        }
        for (String s : soqlStruct.dateFields){
            fieldsToQuery += ',' + s;
        }
        for (String s : soqlStruct.additionalFields){
            fieldsToQuery += ',' + s;
        }
        retStr = 'Select Id, Rank__c ' + fieldsToQuery + ' from Invoice_Grouping_Rule__c';
        retStr += ' where Company__c = \'' + companyId + '\'';
        soqlStruct.soql=retStr;
        system.debug(logginglevel.error,retStr);
        return soqlStruct;
    }
    
    public static void setLineNumbers(List<Invoice_Grouping_Rule__c> groupLines) {
        
        //KNDY-2700: assigning line numbers must be thread-safe
        set<Id> parentIds = KSE.grepRelatedIdSetFromList(groupLines,'Company__c');
        system.debug('parentIds '+parentIds);
        map<Id,Decimal> parentValueMap = new Map<Id,Decimal>();
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Invoice_Grouping_Rule__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Rank__c','Company__c'
		});
		soql.setWhereClause('Company__c IN :parentIds FOR UPDATE');
		list<Invoice_Grouping_Rule__c> groupingRules = Database.query(soql.getQuery());
        
        system.debug('groupingRules '+groupingRules);
        // Get the max line number for each sales order
                    
        for (Invoice_Grouping_Rule__c rule : groupingRules) {
            if( !parentValueMap.containsKey(rule.Company__c)  ){
                  parentValueMap.put(rule.Company__c,0);
            }
            if (rule.Rank__c > parentValueMap.get(rule.Company__c)){
                    parentValueMap.put(rule.Company__c,rule.Rank__c);
                
            }
        }
        system.debug('parentValueMap '+parentValueMap);
        // Assign line numbers
        for (SObject rule : groupLines) {
        	if((boolean)rule.get('Is_Active__c') != true) {
        		rule.put('Rank_Key__c',null);
        	}else {
        		Id myCompany = (Id)rule.get('Company__c');
            
	            if (!parentValueMap.containsKey(myCompany)){
	                parentValueMap.put(myCompany,0);
	            }
	            
	            Decimal val = parentValueMap.get(myCompany);
	            ++val;              
	            parentValueMap.put(myCompany,val);
	            rule.put('Rank__c',val);
	            //Update Unique Sales Order Line field
	            rule.put('Rank_Key__c', myCompany+'|'+val);
	            system.debug('rule '+rule);
			}
		}
	}

	public void calculateBestPrice( Map<String, Customer_Invoice_Line__c> mCILs, List<Customer_Invoice_Sub_Line__c> mCISLs, List<Map<InvoiceGroupingRuleContainer,List<Fulfillment__c>>> fulMapList  ){

		Map<id,Fulfillment__c> fMap = new Map<id,Fulfillment__c>();
		for (Map<InvoiceGroupingRuleContainer,List<Fulfillment__c>> fIgrMap : fulMapList){
			for (List<Fulfillment__c> fulList : fIgrMap.values()){
				for (Fulfillment__c ful : fulList){
					fMap.put(ful.id, ful);
				}
			}
		}

		Map<String, DateTime> cilFulfShipDateMap = new Map<String, DateTime>();
		for (Customer_Invoice_Sub_Line__c cilSubLine : mCISLs){
			String sourceKey = cilSubLine.Customer_invoice_line__r.Source_Key__c;
			DateTime fulSD = (fMap.get(cilSubLine.Fulfillment__c).Parent_Fulfillment__c != null) ? fMap.get(cilSubLine.Fulfillment__c).Parent_Fulfillment__r.Start_Date__c : fMap.get(cilSubLine.Fulfillment__c).Start_date__c;

			Customer_Invoice_Line__c cil = mCILs.get(sourceKey);

			if ( sourceKey != null && (!cilFulfShipDateMap.containsKey(sourceKey) || fulSD < cilFulfShipDateMap.get(sourceKey))) {
				cilFulfShipDateMap.put( sourceKey, fulSD );
			}
		}

		System.debug( '~*~ cilFulfShipDateMap :' + cilFulfShipDateMap );

		// calculate best price only on recurring lines. Otherwise, if none, no need to waste resources.
		list<Customer_Invoice_Line__c> recurringInvoiceLines = new list<Customer_Invoice_Line__c>();
		for (Customer_Invoice_Line__c cil : mCILs.values()) {
			if(cil.Price_Type__c == PricingService.PriceType.RECURRING.name()) {
				recurringInvoiceLines.add(cil);
			}
		}

		if (!recurringInvoiceLines.isEmpty()){
			PricingService.customerInvoiceBestPricing( recurringInvoiceLines, cilFulfShipDateMap );
		}
	}


	// GenerateInvoiceExt and IGRS
	public void allowancesOperations(list<Customer_Invoice_Line__c> lstMCILs,string objectName,boolean flag, List<Customer_Invoice_Sub_Line__c> subLinesList){
		allowancesOperations(lstMCILs, objectName, flag, subLinesList, null);
	}


	// batch
	public void allowancesOperations(list<Customer_Invoice_Line__c> lstMCILs,string objectName,boolean flag, List<Customer_Invoice_Sub_Line__c> subLinesList, Map<Id, Fulfillment__c> oldFulfillmentMap){
		Set<id> cilIds = KSE.grepIdSetFromList(lstMCILs);

		Set<Id> ciSubLine = new Set<Id>();
		System.debug(loggingLevel.Error, '*** subLinesList: ' + subLinesList);
		if (subLinesList != null){
		    for (Customer_Invoice_Sub_Line__c subLine : subLinesList){
			    ciSubLine.add(subLine.id);
			}
		}

		System.debug(loggingLevel.Error, '*** oldFulfillmentMap: ' + oldFulfillmentMap);
	  	AllowanceService.copyAllowancesFromOrderToInvoice( cilIds, KSE.grepRelatedIdSetFromList(lstMCILs,objectName, flag), ciSubLine, oldFulfillmentMap);
	}
	

	public static void defaultGroupBySOType() {
		
		if(trigger.isBefore && (trigger.IsInsert || trigger.isUpdate)) {
			
			for(Invoice_Grouping_Rule__c igr : (list<Invoice_Grouping_Rule__c>)trigger.new) {
				
				if(!igr.Group_By_Sales_Orders__c) 
					igr.Group_By_Sales_Order_Types__c = true;
				
			}
		}
	}

    public static List<Invoice_Grouping_Rule__c> generateRuleDescription(List<Invoice_Grouping_Rule__c> groupLines){
         set<Id> billingID = new set<id>();
         map<Id,UOM__c> billingUOM = new map<Id,UOM__c>();
         for(Invoice_Grouping_Rule__c groupingObj : groupLines){
         	billingId.add(groupingObj.Billing_UOM__c);
         }
         if(!billingID.isempty())
         	billingUOM = new map<Id,UOM__c>([Select Name from UOM__c where ID in :billingId]);
         
         for(Invoice_Grouping_Rule__c groupingObj : groupLines){
            String ruleText = null;
            System.debug(logginglevel.info,groupingObj.For_Customers__c);
            System.debug(logginglevel.info,groupingObj.For_Customers__c);
            System.debug(logginglevel.info,groupingObj.Group_By_Customer_Hierarchy__c);
             
            ruleText = 'by Currency, by Payment Terms '; 
            if(!billingUOM.isEMPTY() && billingUOM.containsKey(groupingObj.Billing_UOM__c))
            	ruleText += ', every '+billingUOM.get(groupingObj.Billing_UOM__c).Name;
            
            if(groupingObj.Recurrence_Start_Date__c != null)
            	ruleText += ' starting '+ groupingObj.Recurrence_Start_Date__c.format('MM/dd/YYYY');
            
            ruleText += getGroupingCriteriaDescription(groupingObj);
            groupingObj.Rule_Description__c = ruleText; 
            System.debug(logginglevel.info,'ruleText-->'+ruleText);
         }    
         return groupLines; 
    }
    
    public static String getGroupingCriteriaDescription(Invoice_Grouping_Rule__c groupingObj){
        String ruleText = '';
        List<String> customersList = new List<String>();
        List<String> agreementsList = new List<String>();
        List<String> categoriesList = new List<String>();
        List<String> productsList = new List<String>();

        ruleText += (groupingObj.Group_By_Customer_Hierarchy__c != null && !(groupingObj.Group_By_Customer_Hierarchy__c == '')) ? ', by '+ groupingObj.Group_By_Customer_Hierarchy__c +' Customer' : '';

        if(groupingObj.For_Customers__c != null) customersList = (groupingObj.For_Customers__c).Split(',');
        System.debug(logginglevel.info,groupingObj.For_Customer__c);
        System.debug(logginglevel.info,groupingObj.For_Customer__r.name);
        if (customersList != null && customersList.size() > 0) if (customersList.size() == 1) ruleText += ', for '+ groupingObj.For_Customer__r.Name; else ruleText += ', for Multiple Customers';

        ruleText += (groupingObj.Group_By_Agreements__c) ? ', by Agreement' : ''; 
             
        if(groupingObj.For_Agreements__c != null) agreementsList = (groupingObj.For_Agreements__c).Split(',');
        if (agreementsList != null && agreementsList.size() > 0) if (agreementsList.size() == 1) ruleText += ', for '+ groupingObj.For_Agreement__r.Name; else ruleText += ', for Multiple Agreements';
             
        ruleText += (groupingObj.Group_By_Sales_Orders__c) ? ', by Sales Order' : ''; 
            
        //ruleText += (groupingObj.Group_By_Sales_Order_Types__c) ? ', by Sales Order Type' : '';
             
        ruleText += (groupingObj.Group_By_Sales_Order_If__c != null && !(groupingObj.Group_By_Sales_Order_If__c == '')) ? ', by Sales Order Type, by Sales Order if '+ groupingObj.Group_By_Sales_Order_If__c : '';
             
        ruleText += (groupingObj.Group_By_Shipments__c) ? ', by Shipment' : '';
            
        ruleText += (groupingObj.Group_By_Category__c) ? ', by Category' : '';
             
        if(groupingObj.For_Categories__c != null) categoriesList = (groupingObj.For_Categories__c).Split(',');
        if (categoriesList != null && categoriesList.size() > 0) if (categoriesList.size() == 1) ruleText += ', for '+ groupingObj.For_Category__r.Name; else ruleText += ', for Multiple Categories';

        ruleText += (groupingObj.Group_By_Product__c) ? ', by Product' : '';
            
        if(groupingObj.For_Products__c != null) productsList = (groupingObj.For_Products__c).Split(',');
        if (productsList != null && productsList.size() > 0) if (productsList.size() == 1) ruleText += ', for '+ groupingObj.For_Product__r.Name; else ruleText += ', for Multiple Products';
        
        return ruleText;
    }
    
    //KNDY-15790
    public static void restrictUpdationAndDeletionOfIGR(){
    	if(trigger.isBefore && trigger.isUpdate && !requestFromUI){
			restrictUpdationAndDeletionOfIGR((list<Invoice_Grouping_Rule__c>)trigger.new);
    	}else if(trigger.isBefore && trigger.isDelete){
    		restrictUpdationAndDeletionOfIGR((list<Invoice_Grouping_Rule__c>)trigger.old);
    	}
    }
    
    public static void restrictUpdationAndDeletionOfIGR(list<Invoice_Grouping_Rule__c> lstIGR){
    	if(!lstIGR.isEmpty()){
			for(Invoice_Grouping_Rule__c igr : lstIGR){
				igr.addError(Label.Can_t_update_delete_IGR);
			}
    	}
    }
}