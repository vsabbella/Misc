public with sharing class SupplierPaymentService {

    public static map<String, List<InvoiceWrapper>> InvoiceWrapBySupplier;  
    public static set< Id > invIDs = new set< Id >(); 
    public static set<Id> validSupInvIds = new set<Id>();
    public static SchemaUtil util = SchemaUtil.getInstance();
    public static Boolean totalCreditsExceedsDebits = false;
    public static Date discountDateFromUI = system.today();
    public static Date paymentDueDateFromUI = system.today();
    public static String paymentMethod = PaymentService.PAYMENT_METHOD_CHECK;
    public static Id companyId;
    public static String bankAccountIdSentViaBatchUI;
    public static Id supplierChosenFromBatchUI;
    public static Datetime paymentDateFromUI = system.now();
    public static Map<Id, Supplier_Invoice__c> originalCreditMemosMap = new Map<Id, Supplier_Invoice__c>();
    public static Map<Id, List<Supplier_Invoice__c>> listOfCMsAppliedToAnInvoice = new Map<Id, List<Supplier_Invoice__c>>();
    public static Boolean payPerInvoice = false;
    public static Map<Id, Supplier_Invoice__c> originalPrepymtInvsMap = new Map<Id, Supplier_Invoice__c>();
    public static Map<Id, List<Supplier_Invoice__c>> listOfPrepymtsAppliedToAnInvoice = new Map<Id, List<Supplier_Invoice__c>>();
    public static map<id,InvoiceWrapper> orginalInvoicesFromUI = new map<id,InvoiceWrapper>();
    public static string timeNow  = string.valueOf(system.now()); 
    //KNDY-16750 -added public variables to make it more scalable. user can add amount to payout/consume per SI
    public class InvoiceWrapper{
        
        public Id SupplierId {get;set;}
        public string SupplierName {get;set;}
        public string Invoice_Type {get;set;}
        public string Invoice_Status {get;set;}
        public decimal Amount_To_Apply {get;set;}
        public decimal Amount_Applied {get;set;}
        public decimal Discount_Earned {get;set;} 
        public boolean EligibleForDiscount {get;set;} //can be used if at all invoice is eligible for disc and can be calculated runtime when amount to apply changes
        public boolean calculateDiscount {get;set;} //can be used for select/deselect func on grid 
        public Supplier_Invoice__c invoiceRecord { get; set; }
        public Supplier_Invoice__c newInvoiceRecord { get; set; }
        
        public InvoiceWrapper(){
            
            this.newInvoiceRecord = new Supplier_Invoice__c();
            
        }
        public  integer hashCode(){
            return HashCodeGenerator.getHashCode(this);  
        }
        
    }     
    //KNDY-17712 payment preview wrapper class
    public class paymentWithLinesWrapper{
		public Supplier_Payment__c supplierPayment;
		public list<Supplier_Payment_Line__c> lstPaymentLines;
		public List<string> messages;
		public paymentWithLinesWrapper(){
		}
		
		public paymentWithLinesWrapper(Supplier_Payment__c supplierPayment, list<Supplier_Payment_Line__c> lstPaymentLines){
			this.supplierPayment = supplierPayment;
			this.lstPaymentLines = lstPaymentLines;
		}
	}
	//KNDY-17712 master wrapper with invoice wrapper and payment wrapper for immediate mode
	public class invoicePaymentWrapper{
		public List<InvoiceWrapper> invWrapperList;
		public List<paymentWithLinesWrapper> paymentWrapperList;
		public string dateTimeNow;
		public invoicePaymentWrapper(){
		}
		
		public invoicePaymentWrapper(List<InvoiceWrapper> invWrapperList,List<paymentWithLinesWrapper> paymentWrapperList){
			this.paymentWrapperList = paymentWrapperList;
			this.invWrapperList = invWrapperList;
		}
	}
    /*** Constructor ***/
    public SupplierPaymentService(){}
    /**** START Common Methods ******************************************/
    
    /* Description : get/build supplier payment key using supplier invoice
    @param : string : batch job id for batches
    		 sObject : type of supplier invoice
    @return param : String :generated key
    */
    //KNDY-16750 - get supplier payment key with batch job and SI Id
    public static String getSupplierPaymentKey(string batchJobId,Supplier_Invoice__c supplierInvoice){
        
        InvoiceWrapper invWrapper = new InvoiceWrapper();
        string key = String.valueOf(invWrapper.hashCode())+'|'+(batchJobId == null ? String.valueOf(timeNow) : batchJobId);
        String supName = key + (supplierInvoice.supplier__c==null?'':supplierInvoice.supplier__c);
        supName = supName + (supplierInvoice.Payment_Method_G__c==null?'':supplierInvoice.Payment_Method_G__c);
        String invTypeCM = PaymentService.TYPE_CREDITMEMO; //KNDY-2520 Need to check if its a CM 
        
        if(supplierInvoice.Supplier__r.Pay_Per_Invoice__c == true){
            if (supplierInvoice.Invoice_Type__c != invTypeCM){
                supName += supplierInvoice.Id;
            }else{//KNDY-2520
                //if this is a CM, then look up associated RIL ID to which it was applied and then use that to create payment key. 
                supName += supplierInvoice.Apply_to_Invoice__c;
            }
        }
        system.debug(LoggingLevel.Info,'supplier payment key :' + supName);
        return supName;
    }    
    /* Description : set transaction date used in Supplierpayment Trigger
    @param : List<sObject> : Type of supplier payments
    @return param : Void
    */     
    public static void setTransactionDate (List<Supplier_Payment__c> triggerNewList){ //KNDY-10280 KNDY-12343
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate) ){
            for (Supplier_Payment__c sp : triggerNewList){
                if(sp.Transaction_Date__c == null){
                    if(trigger.isUpdate && sp.Finalized__c == true){
                        continue;
                    }
                    sp.Transaction_Date__c = system.now();
                }
            }
        }
    }
    /*********END  Common Methods ************************/
    
    /* Description : get supplier invoices. used in paymentbatch.page
    @param : List<KendoUtils.FilterDescriptor> : pass filters from layout end users has selected
    		 GridRelatedListController.GridRelatedListConfig : config param for grid related list
    @return param : List<InvoiceWrapper> : invoice wrapper list
    */    
    //KNDY-16197, KNDY-16751 -fetch SIs with filter criteria also applies discount if eligible depending on the payment date selected
    public static List<InvoiceWrapper> getSupplierInvoices(List<KendoUtils.FilterDescriptor> filters, GridRelatedListController.GridRelatedListConfig config) {
        system.debug(LoggingLevel.Info,'config ==' + config);
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        set<String> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        String sortClause = ' Supplier__r.Name asc, Date_Invoiced__c ASC';//KNDY-13561
        String paymentDueDateStrFromUI;
        String discountDateStrFromUI;
        for(KendoUtils.FilterDescriptor fd: filters){
            system.debug(LoggingLevel.Error,'Filter: ' + fd);
            if ( fd.field != 'totalCreditsExceedsDebits' && fd.field != 'Bank_Account__c' && fd.field != 'PaymentDate' && fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c'){
            	if (fd.value != null)
                	newFilters.add(fd);
            }
            //KNDY-7916
            if (fd.field == 'Payment_Due_Date__c'){
                paymentDueDateFromUI = Date.parse(String.valueOf(fd.value));
                paymentDueDateStrFromUI = String.valueOf(fd.value);  //KNDY-13561
            }
            else if (fd.field == 'Discount_Date__c'){
                discountDateFromUI = Date.parse(String.valueOf(fd.value));
                discountDateStrFromUI = String.valueOf(fd.value);  //KNDY-13561
            }
            else if (fd.field == 'PaymentDate')
                paymentDateFromUI = Datetime.parse(String.valueOf(fd.value));   
            
            if (fd.fieldType == 'picklist' || fd.fieldType == 'reference') //KNDY-7621 putting in a quickfix to support matching to IDs in the where clause
                fd.fieldType = 'string';    
        }
        List<String> filterCriteria = KendoUtils.getFilterCriteria(newFilters);
        filterCriteria.add( 'Hold__c = false');
        filterCriteria.add('Supplier__r.Hold_Payment__c = false');
        filterCriteria.add('Has_Exceptions__c = false');
        
        String balanceFilters = '';
        balanceFilters += '(Invoice_Type__c = \'Invoice\' and Balance_Due__c > 0 and Status__c = \'Approved\')';
        balanceFilters += 'or';
        balanceFilters += '(Invoice_Type__c = \'Prepayment\' and Credit_Memo_Balance__c != 0  and '+
            '(Status__c = \'Approved\' or Status__c = \'Closed\'))'; //KNDY-13561
        balanceFilters += 'or';
        balanceFilters += '(Invoice_Type__c = \'Credit Memo\' and Credit_Memo_Balance__c != 0 and Status__c = \'Approved\')';
        filterCriteria.add('(' + balanceFilters+')');
        
        String whereClause = '';
        
        if (filterCriteria.size() > 0) {
            whereClause += String.join(filterCriteria, ' AND ');
        }
        
        //KNDY-7916 KNDY-13561
        String paymentDueDateFilter = '';
        String discountDateFilter = '';
        String dateFilters = '';
        if (!String.isBlank(paymentDueDateStrFromUI)){
            paymentDueDateFilter += 'Payment_Due_Date__c <= :paymentDueDateFromUI';
        }
        if (!String.isBlank(discountDateStrFromUI)){
            discountDateFilter += 'Discount_Date__c <= :discountDateFromUI';
        }
        if (!String.isBlank(paymentDueDateFilter)&& !String.isBlank(discountDateFilter)){
            dateFilters += ' AND (' + paymentDueDateFilter + ' OR ' + discountDateFilter+ ') ';
        }
        else if (!String.isBlank(paymentDueDateFilter)){
            dateFilters += ' AND ' +  paymentDueDateFilter + ' ';
        }
        else if (!String.isBlank(discountDateFilter)){
            dateFilters +=  ' AND ' +  discountDateFilter + ' ';
        }
        if (!String.isBlank(dateFilters)){
            whereClause +=  dateFilters;
        }
        //whereClause += sortClause; //KNDY-13561
        
        //KNDY-16751 - Adding CRUD/FLS checks with SOQLUtil		
        SOQLUtil supplierInvoiceSOQL = new SOQLUtil ( config.objectName,true) ;//enforceFLS=true, running in user mode
        supplierInvoiceSOQL.addFields (fieldset ) ;       
        supplierInvoiceSOQL.addFields(addlFields);
        supplierInvoiceSOQL.setWhereClause ( whereClause ) ;
        supplierInvoiceSOQL.setOrderByClause ( sortClause ) ;
        system.debug(LoggingLevel.Info, 'queryString: ' + supplierInvoiceSOQL.getQuery ());  
        List<Supplier_Invoice__c> result = Database.query( supplierInvoiceSOQL.getQuery () ) ;                    
        
        List<InvoiceWrapper> invoiceWrapperList = new list<InvoiceWrapper>();
        for( Supplier_Invoice__c supplierInvoice : result){//security review: running in system mode
            
            system.debug(LoggingLevel.Info,'get supplierInvoice: ' + supplierInvoice);
            //KNDY-2596 Looking up to see if parent or top parent is set to hold
            if ((supplierInvoice.Supplier__r.Parent_Supplier__c == null ) || (supplierInvoice.Supplier__r.Parent_Supplier__c != null && !(supplierInvoice.Supplier__r.Parent_Hold_Payment__c == true))){
                if ((supplierInvoice.Supplier__r.Top_Parent_Supplier__c == null ) || (supplierInvoice.Supplier__r.Top_Parent_Supplier__c != null && !(supplierInvoice.Supplier__r.Top_Parent_Hold_Payment__c == true))){ 
                    
                    invIDs.add( supplierInvoice.id );
                    validSupInvIds.add( supplierInvoice.id ); //PTP-241
                    InvoiceWrapper invWrap = new InvoiceWrapper();
                    
                    invWrap.invoiceRecord = supplierInvoice;
                    invWrap.SupplierName = supplierInvoice.Supplier__r.Name;
                    invWrap.calculateDiscount = true;
                    invWrap.EligibleForDiscount = false;
                    Datetime invoicedate = supplierInvoice.Date_invoiced__c;
                    
                    if (supplierInvoice.Amount_Paid__c == null) supplierInvoice.Amount_Paid__c = 0;
                    if (supplierInvoice.Discount_Taken__c == null) supplierInvoice.Discount_Taken__c = 0;
                    //Condition included to prevent test failures 
                    Date DiscountDate = supplierInvoice.Discount_Override_Date__c != null ? supplierInvoice.Discount_Override_Date__c :  (invoicedate != null && supplierInvoice.Payment_term__r.Discount_Days__c !=null) ? (invoicedate + supplierInvoice.Payment_term__r.Discount_Days__c).date() : date.today() ;
                    if (supplierInvoice.Invoice_Type__c == PaymentService.TYPE_INVOICE){
                        if (!supplierInvoice.Always_Take_Discount__c){//PTP-133
                            system.debug('paymentDateFromUI=='+paymentDateFromUI.date() + 'DiscountDate=='+DiscountDate + 'companre : ' + (paymentDateFromUI.Date() > DiscountDate));
                            if (paymentDateFromUI != null && paymentDateFromUI.date() > DiscountDate){ //KNDY-17276-Compare dates only ignore timestamp from payment date
                                invWrap.Discount_Earned = 0;	                                
                            }
                            else { 
                                invWrap.EligibleForDiscount = true;
                                invWrap.Discount_Earned = 0.01 * supplierInvoice.Early_Payment_Rate__c * (supplierInvoice.Invoice_Amount__c - (supplierInvoice.Amount_Paid__c + supplierInvoice.Discount_Taken__c));
                            }
                        }else { 
                            invWrap.EligibleForDiscount = true;
                            invWrap.Discount_Earned = 0.01 * supplierInvoice.Early_Payment_Rate__c * (supplierInvoice.Invoice_Amount__c - (supplierInvoice.Amount_Paid__c + supplierInvoice.Discount_Taken__c));
                        }
                        invWrap.Discount_Earned = KSE.addQuantityToField(invWrap.Discount_Earned,0).setScale(2,RoundingMode.HALF_UP); //PTP-222, PTP-560
                    }
                    
                    if (invWrap.invoiceRecord.invoice_type__c == PaymentService.TYPE_INVOICE || (invWrap.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT && invWrap.invoiceRecord.Status__C == PaymentService.STATUS_APPROVED)){
                        invWrap.Amount_To_Apply = invWrap.invoiceRecord.invoice_type__c == PaymentService.TYPE_INVOICE ? (supplierInvoice.Invoice_Amount__c - (supplierInvoice.Amount_Paid__c + supplierInvoice.Discount_Taken__c)) : invWrap.invoiceRecord.Balance_Due__c;
                    }else if (invWrap.invoiceRecord.invoice_type__c == PaymentService.TYPE_CREDITMEMO || (invWrap.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT && invWrap.invoiceRecord.Status__C == PaymentService.STATUS_CLOSED)){
                        invWrap.Amount_To_Apply =  invWrap.invoiceRecord.Credit_Memo_Balance__c;
                    }
                    system.debug(LoggingLevel.Info,'invWrap=='+invWrap);
                    invoiceWrapperList.add(invWrap);	
                }
                
                
            }
        }
        return invoiceWrapperList;
    }      
    /* Description : 
    * this is very, very similar to CustomerInvoiceService.sumInvoicePayments(inputList)
	* but is actually different due to the different object passed in, could merge the code in the 
	* future ?
	* Called by trigger insert or update SPLs and also when SP is voided
    @param : List<Supplier_Invoice__c> : List of supplier invoices to be summed up and updated with relavent status    		 
    @return param : Void        
	*/
    public static void sumInvoicePayments(list<Supplier_Invoice__c> inputList){
    	Savepoint sp = Database.setSavepoint();
    	try{    
	        list<Supplier_Invoice__c> siList = new list<Supplier_Invoice__c>();
	        for(Supplier_Invoice__c si:inputList){
	            // TODO Need to exclude receipts with exceptions on them
	            system.debug(LoggingLevel.Error,'SP Line trigger before SumofInvoices check for SI : ' + si);
	            decimal payment_sum = 0;
	            decimal CreditMemo_Sum = 0;
	            decimal deduction_sum = 0;
	            decimal writeoff_sum = 0;
	            decimal discount_sum = 0;
	            decimal prepaymentsApplied_sum = 0;//KNDY-13087
	            system.debug(LoggingLevel.Error,'SP Line trigger SP Lines : ' + si.Supplier_Payment_Lines__r);
	            if (si.Supplier_Payment_Lines__r.size() == 0) break;
	            for(Supplier_Payment_Line__c p: si.Supplier_Payment_Lines__r){ 
	                system.debug(LoggingLevel.Error,'Inside summation : '+ p.Supplier_Payment__r.Finalized__c + '==' +p.Supplier_Payment__r.Status__c);    
	                if(p.Supplier_Payment__r.Finalized__c && p.Supplier_Payment__r.Status__c != PaymentService.STATUS_VOID && p.Supplier_Payment__r.Status__c != PaymentService.STATUS_CANCELLED){
	                	system.debug(LoggingLevel.Info,'Inside summation : '+ p);    
	                    if(p.Type__c =='Payment'){
	                        payment_sum= payment_sum+ p.Amount__c;          
	                    }else if(p.Type__c == PaymentService.TYPE_CREDITMEMO){
	                        creditMemo_Sum += p.Amount__c;
	                    }else if(p.Type__c == PaymentService.TYPE_EARNED_DISCOUNT ){//KNDY-16750 - removed unearned disc , no more used 
	                        discount_sum += p.Amount__c;
	                    }else if (p.Type__c == PaymentService.TYPE_PREPAYMENT){//KNDY-13087
	                        prepaymentsApplied_sum += p.Amount__c;//-ve 
	                    }
	                }
	            }
	            
	            si.Amount_Paid__c = payment_sum;
	            si.Credit_Memo_Applied__c = CreditMemo_Sum;
	            system.debug(LoggingLevel.Info,'SI amount paid and credit memo applied updated =' + si );
	            if (si.Invoice_Type__c != PaymentService.TYPE_PREPAYMENT) //KNDY-9385
	            {    
	            	system.debug(LoggingLevel.Error,'Sum of CM :' +CreditMemo_Sum + '=si.Credit_Memo_Balance__c :' +si.Credit_Memo_Balance__c + 'si.Credit_Memo_Amount__c=' +si.Credit_Memo_Amount__c);
	                if(CreditMemo_Sum == 0.0){
	                    si.Credit_Memo_Balance__c = si.Credit_Memo_Amount__c;
	                }else{
	                    si.Credit_Memo_Balance__c = KSE.subtractDecimals(si.Credit_Memo_Amount__c, CreditMemo_Sum);
	                }
	                //KNDY-3335
	                si.Status__c = PaymentService.STATUS_APPROVED; //PTP-188
	                
	            }
	            else if (si.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT){ //KNDY-13087
	                system.debug( LoggingLevel.Error, '>>> prepaymentsApplied_sum:' + prepaymentsApplied_sum + ' si.Credit_Memo_Amount__c ==' +si.Credit_Memo_Amount__c + ' si.Credit_Memo_Applied__c=='+si.Credit_Memo_Applied__c + '=si.Amount_Paid__c='+si.Amount_Paid__c);
	                si.Credit_Memo_Applied__c = prepaymentsApplied_sum;
	                si.Credit_Memo_Balance__c  = KSE.addQuantityToField(si.Credit_Memo_Amount__c, 0) - si.Credit_Memo_Applied__c;
	                if (si.Amount_Paid__c == 0){
	                    si.Status__c = PaymentService.STATUS_APPROVED;
	                }
	            }
	            
	            si.Discount_Taken__c = discount_sum;
	            //close SIs in case those are consumed
	            if ((si.Invoice_Type__c == PaymentService.TYPE_INVOICE || (si.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT && si.Status__C == PaymentService.STATUS_APPROVED))
                    && (KSE.addQuantityToField(si.Amount_Paid__c,0) + KSE.addQuantityToField(si.Discount_Taken__c,0)) == si.Invoice_Amount__c ){
                    	
                    si.status__c = PaymentService.STATUS_CLOSED;
                    si.Date_Time_Paid__c = System.now();
                    system.debug(LoggingLevel.Error,' SIs status : ' + si.status__c);
                }else if ((si.Invoice_Type__c == PaymentService.TYPE_CREDITMEMO || (si.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT && si.Status__C == PaymentService.STATUS_CLOSED))
                          && si.Credit_Memo_Balance__c == 0 ){
                    si.status__c = PaymentService.STATUS_CLOSED;
                    si.Date_Time_Paid__c = System.now();
                }
	            system.debug(LoggingLevel.Error,'SI Line update invoices SumofInvoices : ' + si);
	            siList.add(si);
	        }
	        
	        //KNDY-1747
	        DML.allowUpdateFields( new list<string>{'Amount_Paid__c', 'Credit_Memo_Applied__c','Credit_Memo_Balance__c','Discount_Taken__c','Status__c','Date_Time_Paid__c'}, Supplier_Invoice__c.SObjectType );
	        DML.sobjectUpdate( siList );  
        }catch(DMLException ex) {          
        	database.rollback(sp);          
            for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {
                
                    string errorMessage = ex.getDmlMessage(idx);
                    string statusCode = ex.getDmlStatusCode(idx);
                    Integer location;    
                    system.debug(LoggingLevel.Error,'errorMessage=='+ ex.getStackTraceString() + '-message = ' + ex.getMessage() +'getDmlStatusCode' + ex.getDmlStatusCode(idx));
                    if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('REQUIRED_FIELD_MISSING')){
                    list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
					msgArray = errorMessage.split('REQUIRED_FIELD_MISSING,');
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
                system.debug(LoggingLevel.Error,'errorMessage=='+errorMessage);
               	throw new CustomException(errorMessage);                  
        	}
        	
		}
        catch ( DML.InsuffientAccessException e ) { 
        	database.rollback(sp);
 			throw new CustomException(Label.Insufficient_access_contact_administrator_for_permissions); 
 		}catch (Exception e) { //AR-15 JSONResult addMessage handles DML Exception        	
 			database.rollback(sp); 	
 			throw new CustomException(e.getMessage()); //AR-15
        } 
    }    
    
    /*Have a supplier to pay, intial scope of invoices to use and filters set
	Steps to pre-process data: 
	1) start creating payments in the system
	2) If include credits is turned off then dont fire off CM query, just create payments
	Steps to create payments:
	1) To create payments, build data structures that hold invoices and credit memos seperately
	2) Sort these by highest amounts first, maybe query them like that
	3) first consume prepayments and then credit memo to pay out invoices
	
	As a first cut try to leverage existing service methods. Next up figure out discount amount math including pay per invoice, 
	discount override date & always take discount. 
	
	@param : List<KendoUtils.FilterDescriptor> : pass filters from layout end users has selected
    		 map<id,InvoiceWrapper> : scope of all invoices selected from batch	 
    		 List<Supplier_Invoice__c> : supplier invoices chosen to be paid as per the batch size . right now 1 invoice per batch
    		 List<Supplier__c> : supplier chosen to be paid
    		 ID : batch job id for batch
    		 
    @return param : Void       
	*/
    public  List<invoicePaymentWrapper> processPayments( List<KendoUtils.FilterDescriptor> filters, map<id,InvoiceWrapper> scopeInvoicesFromBatch,List<Supplier_Invoice__c> supplierInvoiceChosenToBePaid, List<Supplier__c> supplierChosenToBePaid, Id batchJobId){
        set<id> SIset = new set<Id>();
        
        SIset.addAll(scopeInvoicesFromBatch.keyset() );
        orginalInvoicesFromUI = scopeInvoicesFromBatch;
        for(KendoUtils.FilterDescriptor fd: filters){
            if (fd.field == 'totalCreditsExceedsDebits')
                totalCreditsExceedsDebits = String.valueOf(fd.value).toLowerCase() == 'true' ? True : False;
            else if (fd.field == 'Payment_Method_G__c')
                paymentMethod = String.valueOf(fd.value); 
            else if (fd.field == 'Payment_Due_Date__c')
                paymentDueDateFromUI = Date.parse(String.valueOf(fd.value));
            else if (fd.field == 'Discount_Date__c')
                discountDateFromUI = Date.parse(String.valueOf(fd.value));
            else if (fd.field == 'Bank_Account__c')
                bankAccountIdSentViaBatchUI = String.valueOf(fd.value); 
            else if (fd.field == 'PaymentDate')
                paymentDateFromUI = Datetime.parse(String.valueOf(fd.value));               
        }
        
        if (bankAccountIdSentViaBatchUI == null || bankAccountIdSentViaBatchUI == ''){
            throw new CustomException(Label.Missing_Bank_Account); 
        }
        
        
        supplierChosenFromBatchUI = supplierChosenToBePaid[0].id;
        system.debug(LoggingLevel.Info,'supplier choosen to be paid =' + supplierChosenToBePaid);
        Date today = Date.today();
        system.debug(LoggingLevel.Info,'supplier invoice choosen to be paid =' + supplierInvoiceChosenToBePaid);
        system.debug(LoggingLevel.Info,'All invoices from UI -' +orginalInvoicesFromUI);
        payPerInvoice = supplierChosenToBePaid[0].Pay_Per_Invoice__c;
        system.debug(LoggingLevel.Info,'payPerInvoice=='+payPerInvoice);        
        
        // KNDY-10473 FLS Security Fixes for SOQL queries
        SOQLUtil suppInvSoql = new SOQLUtil ( 'Supplier_Invoice__c') ;
        Set<String> queryInvStrBaseFields = new Set<String> {'Id','Always_Take_Discount__c','Company__c','credit_memo_amount_applied__c',
            'Memo__c','status__c','Supplier__c','Supplier__r.Hold_Payment__c','Supplier__r.Name',
            //KNDY-17192 added supplier address fields to populate while creating SP
            'Supplier__r.Address__c','Supplier__r.Address__r.BillingStreet','Supplier__r.Address__r.BillingCity',
            'Supplier__r.Address__r.BillingState','Supplier__r.Address__r.BillingPostalCode',
            'Supplier__r.Address__r.BillingCountry','Supplier__r.Supplier_Street__c',
            'Supplier__r.Street_1__c','Supplier__r.Street_2__c',
            'Supplier__r.Supplier_City__c','Supplier__r.Supplier_State__c','Supplier__r.Supplier_Zip_Code__c',
            'Supplier__r.Supplier_Country__c',
            //end KNDY-17192
            'Payment_Due_Date__c','Supplier__r.Pay_Per_Invoice__c','Invoice_type__c','Date_Invoiced__c',
            'Name','Payment_Term__c','Payment_Method_G__c','Balance_Due__c','Payment_Term__r.Name',
            //KNDY-17277 - discount earned deprecated
            'Payment_Term__r.Discount_Days__c','Discount_date__c','Discount_Taken__c',
            'Discount_Override_Date__c','Early_Payment_Rate__c','Amount_Due__c','Invoice_Amount__c','Amount_Paid__c',
            'Currency__c'
            };
        suppInvSoql.addFields ( queryInvStrBaseFields ) ;
        String invQWhereClause = ' Status__c = \'Approved\'  AND Hold__c = false ' +
            'AND Invoice_Type__c NOT IN (\'Credit Memo\') AND Payment_Method_G__c = : paymentMethod  ' +
            'AND Supplier__r.Hold_Payment__c = false and Supplier__c IN : supplierChosenToBePaid  And Id in :supplierInvoiceChosenToBePaid ' +
            'AND Has_Exceptions__c = false ';
        suppInvSoql.setWhereClause ( invQWhereClause );
        suppInvSoql.setOrderByClause ( 'Date_Invoiced__c ASC' ) ;
        

        
        List<Supplier_Invoice__c> invToPay = new List<Supplier_Invoice__c>();
        
        system.debug(LoggingLevel.Info,'Pay out invoices' + suppInvSoql.getQuery() );
                
        // approved invoices and prepayments selected from UI
        invToPay = Database.query (  suppInvSoql.getQuery() ) ;

       
        originalCreditMemosMap = new Map<Id, Supplier_Invoice__c>();
        originalPrepymtInvsMap = new Map<Id, Supplier_Invoice__c>();
        //fill original CM/Prepayment list
        for (InvoiceWrapper invWrap : orginalInvoicesFromUI.values()){ 
        	if (invWrap.Invoice_Type == PaymentService.TYPE_CREDITMEMO)
        		originalCreditMemosMap.put(invWrap.invoiceRecord.id, invWrap.invoiceRecord);
        	else if (invWrap.Invoice_Type == PaymentService.TYPE_PREPAYMENT && invWrap.Invoice_Status == PaymentService.STATUS_CLOSED)
        		originalPrepymtInvsMap.put(invWrap.invoiceRecord.id, invWrap.invoiceRecord);   
        		
        }
        system.debug(LoggingLevel.error, 'Populated the original CM map: ' + originalCreditMemosMap);
        system.debug(LoggingLevel.error, 'Populated the original Prepymt map: ' + originalPrepymtInvsMap);
                
        //Create payment headers
        List<invoicePaymentWrapper> invPayWrapperList = createPayments(invToPay, batchJobId);      
        system.debug(LoggingLevel.Error,'invPayWrapperList=='+invPayWrapperList);     
        return invPayWrapperList;
    }//End of method
    
    /*
    Description : this method is wrapper for creating payment headers, payment lines and returns supplier payments in draft format
    @param : List<Supplier_Invoice__c> : supplier invoices chosen to be paid , ideally it will be 1 as per the batch scope 
    		 ID : batch job id for batch    		 
    @return param : List<Supplier_Payment__c> : return payment headers created for invoice to be paid
      
    */     
    public List<invoicePaymentWrapper> createPayments(List<Supplier_Invoice__c> invoicesToBePaid, Id batchJobId){	
        InvoiceWrapper invWrapper;
        List<InvoiceWrapper> invWrapperList = new List<InvoiceWrapper>();
        Map<String, List<InvoiceWrapper>> mapOfInvoicesToBePaid = new Map<String, List<InvoiceWrapper>>();
        system.debug(LoggingLevel.ERROR,'invoicesToBePaid=='+invoicesToBePaid);
        for (Supplier_Invoice__c si: invoicesToBePaid){
            String pymtKey = getSupplierPaymentKey(batchJobId,si);
            invWrapper = orginalInvoicesFromUI.get(si.id);
            invWrapper.invoiceRecord = si;
            if (mapOfInvoicesToBePaid.containsKey(pymtkey))
                mapOfInvoicesToBePaid.get(pymtKey).add(invWrapper);
            else	
                mapOfInvoicesToBePaid.put(pymtKey, new List<InvoiceWrapper>{invWrapper});
        }
        system.debug(LoggingLevel.error, 'SI Map created: ' + mapOfInvoicesToBePaid);
        Set<Id> paymentIds = new Set<Id>();
        
        
        // create payment header records	
        map< String, Supplier_Payment__c > supplierPaymentBySupplierMap = createPaymentHeaders( mapOfInvoicesToBePaid, batchJobId );
        system.debug(LoggingLevel.error, 'created a list of pymt headers it seems: ' + supplierPaymentBySupplierMap.values().size()); 
        
        // create payment line records and set the amount fields on header
        List<Supplier_Payment_Line__c> listOfPayments = createPaymentLines( supplierPaymentBySupplierMap,invoicesToBePaid, batchJobId);
        system.debug(LoggingLevel.error, 'created a list of pymt lines it seems: ' + listOfPayments); 
            
        //KNDY-10280 KNDY-12343: Not sending Transaction Date in update DML,
        // so that trigger gets latest value from database
        system.debug(LoggingLevel.error, 'payment headers/lines created ready for finalize batch : '  + supplierPaymentBySupplierMap.values());
        List<invoicePaymentWrapper> invPayWrapperList;
        if (batchJobId != null){
        	insertPaymentInDB (supplierPaymentBySupplierMap.values(),listOfPayments);        	
        }else { //immediate mode
        	List<paymentWithLinesWrapper> paymentWrapperList = new List<paymentWithLinesWrapper>();
        	paymentWithLinesWrapper payWrapper;
        	for (Supplier_Payment__c payment : supplierPaymentBySupplierMap.values()){
        		payWrapper = new paymentWithLinesWrapper(payment,listOfPayments);
        		paymentWrapperList.add(payWrapper);
        	}
        	invoicePaymentWrapper invPayWrapper = new invoicePaymentWrapper(orginalInvoicesFromUI.values(),paymentWrapperList);
        	invPayWrapperList = new List<invoicePaymentWrapper>();
        	
        	invPayWrapperList.add(invPayWrapper);
        	return invPayWrapperList;
        }
        return null;
       
    }
    
    /*
		Description : create payment header data
		@param : map< String, Supplier_Payment__c > : map of payment key as a string and supplier payment object type
				Id : batch job id in case of batch
		return param map< String, Supplier_Payment__c > : map of supplier payment key and supplier payment to be finalized
	*/
    private map< String, Supplier_Payment__c > createPaymentHeaders( Map<String, List<InvoiceWrapper>> mapOfInvoicesToBePaid, Id batchJobId ){	
        
        map< String, Supplier_Payment__c > supplierPaymentByPymtKeyMap = new map< String, Supplier_Payment__c >(); 
        Map<String, Supplier_Payment__c> mapOfPymtHeaders = initializePymtHeaders( mapOfInvoicesToBePaid);
        if (!payPerInvoice){ //if not pay per invoice
            
            system.debug(LoggingLevel.Error,'mapOfInvoicesToBePaid==' + mapOfInvoicesToBePaid.values());
            system.debug(LoggingLevel.Error,'mapOfPymtHeaders==' + mapOfPymtHeaders);
            for (String pymtKey: mapOfPymtHeaders.keySet()){
	           
                Supplier_Payment__c supplierPaymentHeader = mapOfPymtHeaders.get(pymtKey);	                
                supplierPaymentHeader.Bank_Account__c = bankAccountIdSentViaBatchUI;
                supplierPaymentHeader.Date_Paid__c = paymentDateFromUI != null ? paymentDateFromUI : System.now();  // FIN-657
                supplierPaymentHeader.Batch_Job_ID__c = batchJobId;
                supplierPaymentHeader.Source_Key__c = pymtKey;
                supplierPaymentHeader.status__c = PaymentService.STATUS_APPLIED;
	            
	            system.debug(LoggingLevel.Info, 'SP header created: ' + supplierPaymentHeader);
	            supplierPaymentByPymtKeyMap.put( pymtKey, supplierPaymentHeader ); //ToDo this key is wrong to use, doesnt match up in create pymt lines
            }
        }else{
            for (String pymtKey: mapOfPymtHeaders.keySet()){
                Supplier_Payment__c supplierPaymentHeader = mapOfPymtHeaders.get(pymtKey);
                supplierPaymentHeader.Bank_Account__c = bankAccountIdSentViaBatchUI;
                
                supplierPaymentHeader.Date_Paid__c = paymentDateFromUI != null ? paymentDateFromUI : System.now();
                supplierPaymentHeader.Batch_Job_ID__c = batchJobId; //KNDY-13859
                supplierPaymentHeader.Source_Key__c = pymtKey;
                supplierPaymentHeader.status__c = PaymentService.STATUS_APPLIED;
                supplierPaymentByPymtKeyMap.put( pymtKey, supplierPaymentHeader ); // do we need a seperate map here?
                system.debug(LoggingLevel.Info, 'PPI SP header created: ' + supplierPaymentHeader);
                
            }
            
        }        
        system.debug(LoggingLevel.Error,'supplier Payment By Pymt Key Map=>'+supplierPaymentByPymtKeyMap);
        return supplierPaymentByPymtKeyMap;
    }
    
    /*
		Description : create payment header data
		@param : map< String, List<InvoiceWrapper> > : map of payment key as a string and list of invoice wrapper type
		return param map< String, Supplier_Payment__c > : map of supplier payment key and supplier payment to be finalized
	*/
    //used for pay-per-invoice payment headers
    private Map<String, Supplier_Payment__c> initializePymtHeaders(Map<String, List<InvoiceWrapper>> mapOfInvoicesToBePaid){
        Map<String, Supplier_Payment__c> supplierPaymentHeaders = new Map<String, Supplier_Payment__c>();
        for (String pymtKey: mapOfInvoicesToBePaid.keySet()){
            Supplier_Payment__c supplierPaymentHeader = new Supplier_Payment__c();
            supplierPaymentHeader.Company__c = (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Company__c; //KNDY-13532
            supplierPaymentHeader.Currency__c = (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Currency__c;
            supplierPaymentHeader.Supplier__c =  (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__c; //supplierChosenFromBatchUI;
            supplierPaymentHeader.Payment_Amount__c = 0;
            supplierPaymentHeader.Payment_Method_G__c = paymentMethod; 
            //KNDY-17192 fetch address from supplier
            system.debug(LoggingLevel.INFO, 'supplier address details while setting payment header : ' + (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r);
            supplierPaymentHeader.Supplier_Street__c  = (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__c != null ? (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__r.BillingStreet : (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Supplier_Street__c;
            supplierPaymentHeader.Supplier_Street_1__c  = (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__c != null ? '' : (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Street_1__c;
            supplierPaymentHeader.Supplier_Street_2__c  = (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__c != null ? '' : (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Street_2__c;
            supplierPaymentHeader.Supplier_City__c = (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__c != null ? (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__r.BillingCity : (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Supplier_City__c ;
            supplierPaymentHeader.Supplier_State__c = (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__c != null ? (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__r.BillingState : (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Supplier_State__c;
            supplierPaymentHeader.Supplier_Postal_Code__c = (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__c != null ? (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__r.BillingPostalCode : (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Supplier_Zip_Code__c;
            supplierPaymentHeader.Supplier_Country__c = (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__c != null ? (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Address__r.BillingCountry : (mapOfInvoicesToBePaid.get(pymtKey))[0].invoiceRecord.Supplier__r.Supplier_Country__c; 
            supplierPaymentHeaders.put(pymtKey, supplierPaymentHeader);
        }
        
        return supplierPaymentHeaders;
    }
    /******************************START OF PAYMENT LINE PROCESSING METHODS ************************/
    /*
		Description : create payment line data
		@param : map< String, Supplier_Payment__c >  : map of payment key as a string and supplier payment
				 List<Supplier_Invoice__c> : list of all supplier invoices
				 ID : batch job id in case of batch
		return param List<Supplier_Payment_Line__c> : List of supplier payment lines
	*/
    public  List<Supplier_Payment_Line__c> createPaymentLines( map< String, Supplier_Payment__c > supplierPaymentBySupplierMap,List<Supplier_Invoice__c> allInvoices,string batchJobId){
        
        List<Supplier_Payment_Line__c> listOfPayments = new List<Supplier_Payment_Line__c>();
        
        system.debug(LoggingLevel.Info,'createPaymentLinesForBatchPayments Method allInvoices == ' +allInvoices);
            
        for( Supplier_Invoice__c supplierInv : allInvoices ){
            system.debug(LoggingLevel.Error, 'createPaymentLinesForBatchPayments Method allInvoices == ' +orginalInvoicesFromUI.get(supplierInv.id));
            InvoiceWrapper SIWrap = orginalInvoicesFromUI.get(supplierInv.id);
            String siKey = getSupplierPaymentKey (batchJobId,supplierInv);
            system.debug(LoggingLevel.Error,'siKey='+siKey);
            Supplier_Payment_Line__c payment = new Supplier_Payment_Line__c();
            payment.Supplier_Invoice__c = supplierInv.Id;
            if (supplierPaymentBySupplierMap.containsKey(siKey)){
                //Pull the supplier payment header from the map
                payment.Supplier_Payment__r  = new Supplier_Payment__c(Source_Key__c = siKey);
                system.debug(LoggingLevel.error, 'Reached a stage where SP headers can be retrieved for si: ' + SIWrap + ', SI =' + supplierInv + ', SP: ' + supplierPaymentBySupplierMap.get(siKey));
	                
                //KNDY-12336
                //Excluding discounts, CMs & other pre-pymt balances while calculating amount to pay out for pre-payment advance
                //KNDY-18888 - allow prepayments type of invoice to be consumed thru credit memos
                /*if (supplierInv.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT){
                    payment.amount__c = SIWrap.Amount_To_Apply; //Invoice_Amount__c - KSE.addQuantityToField(invWrap.Amount_Paid__c,0);
                    payment.type__c = 'Payment';
                    system.debug(LoggingLevel.ERROR, 'Created a new SP Line: ' + payment);
                    supplierPaymentBySupplierMap.get(siKey).Payment_Amount__c += payment.amount__c;
                    system.debug(LoggingLevel.error, 'Payment amount so far on SP: ' + supplierPaymentBySupplierMap.get(siKey).Payment_Amount__c);
                    
                    listOfPayments.add( payment );                    
                    Supplier_Invoice__c inv = updateInvoicePymtBatchMode(supplierInv );                    
                    system.debug(LoggingLevel.error, 'si updated: ' + inv);
                    supplierPaymentBySupplierMap.get(siKey).Amount_In_Words__c = NumberToWordUtil.numberToWordsWithDecimal(supplierPaymentBySupplierMap.get(siKey).Payment_Amount__c);
	                    
               }else{*/	               
                    payment.amount__c = SIWrap.Amount_To_Apply; 
                    payment.type__c = 'Payment';

                    // storing Net amount based on discount taken.
                    system.debug(LoggingLevel.ERROR, 'Created a new SP Line: ' + payment);
                    supplierPaymentBySupplierMap.get(siKey).Payment_Amount__c += payment.amount__c;
                    
                    listOfPayments.add( payment );	                 
                    Supplier_Invoice__c inv = updateInvoicePymtBatchMode(supplierInv);
                    SIWrap = orginalInvoicesFromUI.get(inv.id);    
                    system.debug(LoggingLevel.error, 'invoice after applying credit/prepayment: ' + SIWrap);
	                    
                    if( SIWrap.Discount_Earned > 0  ){
                        
                        Supplier_Payment_Line__c paymentDiscount = new Supplier_Payment_Line__c();
                        paymentDiscount.Supplier_Invoice__c = inv.Id;
                        paymentDiscount.Supplier_Payment__r = new Supplier_Payment__c(Source_Key__c = siKey);
                        paymentDiscount.type__c = PaymentService.TYPE_EARNED_DISCOUNT;	
                        paymentDiscount.amount__c = SIWrap.Discount_Earned;
                        
                        system.debug(LoggingLevel.ERROR, 'Created a new discount SP Line: ' + paymentDiscount);
                        
                        listOfPayments.add(paymentDiscount);
                    }
                    // if invoice type = invoice and status is not closed
                    // apply prepayemnt against this invoice
                    // create a payment line of type pre-payment
                    system.debug(LoggingLevel.error, 'Getting a list of Prepymt per Inv: ' + listOfPrepymtsAppliedToAnInvoice.get(inv.id));
                    if (listOfPrepymtsAppliedToAnInvoice.get(inv.id) != null && listOfPrepymtsAppliedToAnInvoice.get(inv.id).size() > 0){
                        //Loop through the list of Prepymts and assume that the Prepymt balance is the amount totally consumed so just blindly create Prepymt lines
                        for (Supplier_Invoice__c prepymt: listOfPrepymtsAppliedToAnInvoice.get(inv.id)){
                            Supplier_Payment_Line__c prepymtPayment = new Supplier_Payment_Line__c();
                            prepymtPayment.Supplier_Payment__r = new Supplier_Payment__c(Source_Key__c = siKey);
                            prepymtPayment.Supplier_Invoice__c = prepymt.Id;
                            prepymtPayment.credit_amount_applied__c = prepymt.Credit_Memo_Applied__c;//orginalInvoicesFromUI.get(prepymt.id).Amount_Applied; 
                            prepymtPayment.amount__c  = prepymt.Credit_Memo_Applied__c;//orginalInvoicesFromUI.get(prepymt.id).Amount_Applied; 
                            prepymtPayment.type__c = PaymentService.TYPE_PREPAYMENT;
                            supplierPaymentBySupplierMap.get(siKey).Payment_Amount__c += prepymtPayment.amount__c;
                            supplierPaymentBySupplierMap.get(siKey).Supplier_Payment_Lines__r.add( prepymtPayment);
                            listOfPayments.add( prepymtPayment );
                            system.debug(LoggingLevel.ERROR, 'Created a new Prepymt SP Line: ' + prepymtPayment);
                        }
                    }
	                    
                    system.debug(LoggingLevel.error, 'Getting a list of CM per Inv: ' + listofCMsAppliedToAnInvoice.get(inv.id));
                    if (listofCMsAppliedToAnInvoice.get(inv.id) != null && listofCMsAppliedToAnInvoice.get(inv.id).size() > 0){
                        //Loop through the list of CMs and assume that the CM balance is the amount totally consumed so just blindly create CM lines
                        for (Supplier_Invoice__c cm: listofCMsAppliedToAnInvoice.get(inv.id)){
                            Supplier_Payment_Line__c cmPayment = new Supplier_Payment_Line__c();
                            cmPayment.Supplier_Payment__r = new Supplier_Payment__c(Source_Key__c = siKey);
                            cmPayment.Supplier_Invoice__c = cm.Id;
                            cmPayment.credit_amount_applied__c = cm.Credit_Memo_Applied__c; //orginalInvoicesFromUI.get(cm.id).Amount_Applied; 
                            cmPayment.amount__c  = cm.Credit_Memo_Applied__c;//orginalInvoicesFromUI.get(cm.id).Amount_Applied; 
                            cmPayment.type__c = PaymentService.TYPE_CREDITMEMO;
                            supplierPaymentBySupplierMap.get(siKey).Payment_Amount__c += cmPayment.amount__c;
                            supplierPaymentBySupplierMap.get(siKey).Supplier_Payment_Lines__r.add( cmPayment);
                            system.debug(LoggingLevel.error, 'Payment amount so far on SP, after CM: ' + supplierPaymentBySupplierMap.get(siKey).Payment_Amount__c);
                            
                            listOfPayments.add( cmPayment );
                            system.debug(LoggingLevel.ERROR, 'Created a new CM SP Line: ' + cmPayment);
                        }
                    }
                    supplierPaymentBySupplierMap.get(siKey).Amount_In_Words__c = NumberToWordUtil.numberToWordsWithDecimal(supplierPaymentBySupplierMap.get(siKey).Payment_Amount__c);
                //}//end of pre-pymt invoice check else condition
            }
        }//end of for loop over all invoices
        system.debug(logginglevel.INFO, 'create payment lines Exit ' );
        
        return listOfPayments; 
    }
    
    /*
		Description : consume prepayments/credit memos if any for the same supplier against supplier invoice chosen to be paid out
		@param : Supplier_Invoice__c : supplier invoice to be paid out
		return param Supplier_Invoice__c : supplier invoice paid out
	*/
    public static Supplier_Invoice__c updateInvoicePymtBatchMode(Supplier_Invoice__c SupplierInv){
        /*
		Maybe should pass in a list of CMs, maintain a seperate list of inv to CM amount applied map. 
		then back in create pymt lines method, retrieve the original CM map, apply the amount to buckets and update the CM list.
		SI buckets already gets updated in this method. back in create lines method, look at things needed to be created and update both SI and CM
		Dont update the Credit Memo Amount applied field on an SI. Roll back formula field change on balance due on an SI
		
		*/
        InvoiceWrapper invWrapper = orginalInvoicesFromUI.get(SupplierInv.id);
        system.debug(LoggingLevel.error, 'Invoice original started to be consumed: ' + orginalInvoicesFromUI.get(SupplierInv.id));
       	//KNDY-18888 - allow prepayments type of invoice to be consumed thru credit memos
        //if(SupplierInv.Invoice_Type__c != PaymentService.TYPE_PREPAYMENT){
            //loop through the CMs and apply them to this invoice
            Decimal amountToCredit = 0;
            amountToCredit = invWrapper.Amount_To_Apply;
            amountToCredit.setScale(2);
            system.debug(LoggingLevel.error, 'amountToCredit: ' + amountToCredit);
            
            //call apply to prepayment/credit memos respectively
            //KNDY-18888 - allow prepayments type of invoice to be consumed thru credit memos
            if(SupplierInv.Invoice_Type__c != PaymentService.TYPE_PREPAYMENT){
            	amountToCredit = applyPrepayments(SupplierInv,amountToCredit);
            }
            system.debug('amountToCredit after prepayment utilization ' +amountToCredit);
            if (amountToCredit <> 0) {
                applyCreditMemos(SupplierInv,amountToCredit);
            }
            orginalInvoicesFromUI.get(SupplierInv.id).Amount_To_Apply -= KSE.addQuantityToField(amountToCredit,0);
            system.debug(LoggingLevel.error, 'Invoice original: ' + orginalInvoicesFromUI.get(SupplierInv.id));
            system.debug(LoggingLevel.ERROR,'Amt paid: ' +  SupplierInv.Amount_Paid__c);   
                                
        /*}else if(SupplierInv.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT){
            
            system.debug(LoggingLevel.ERROR,'Amt paid (prepayment): ' +  SupplierInv.Amount_Paid__c);             
        }*/
        
        return SupplierInv;
        
    }
    /*
		Description : consume prepayments if any for the same supplier against supplier invoice chosen to be paid out
		@param : Supplier_Invoice__c : supplier invoice to be paid out
				 amountToCredit : amount to be consumed
		return param Decimal : returns amount left out to be consumed in credit memo
	*/
    private static decimal applyPrepayments(Supplier_Invoice__c SupplierInv,Decimal amountToCredit){
        system.debug(LoggingLevel.WARN, 'applying prepayments : ' + amountToCredit + ' originalPrepymtInvsMap =' +originalPrepymtInvsMap);
        if (!originalPrepymtInvsMap.values().isEmpty() && amountToCredit > 0){
            //Figure out what is the max prepayment that you can apply to this invoice
            for(Supplier_Invoice__c prepymt: originalPrepymtInvsMap.values()){
                if (KSE.addQuantityToField(orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply,0) != 0 && supplierInv.Supplier__c == prepymt.Supplier__c){ //if prepymt balance is 0 or null then dont iterate over loop
                    system.debug(LoggingLevel.debug,'prepymt balance is not zero' + prepymt);
                    if (amountToCredit > Math.abs(KSE.addQuantityToField(orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply,0))){ //prepymt balance is less than amt to credit
                        //mark the prepymt as consumed and update the inv's credit memo applied field
                        //update the global lists and maps
                        system.debug(LoggingLevel.error,'prepymt balance is less than amountToCredit');
                        system.debug(LoggingLevel.error,'prepymt balance:' + KSE.addQuantityToField(orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply,0));			
                        Supplier_Invoice__c prepymtApplied = new Supplier_Invoice__C();
                        prepymtApplied.id = prepymt.id;
                        prepymtApplied.Credit_Memo_Balance__c = KSE.addQuantityToField(orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply,0) ;
                        prepymtApplied.Credit_Memo_Applied__c = KSE.addQuantityToField(orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply,0) ;
                        
                        if (originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Applied__c == null || originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Applied__c == 0)
                            originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Applied__c = prepymt.Credit_Memo_Balance__c;
                        else
                            originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Applied__c += prepymt.Credit_Memo_Balance__c;	
                        
                        amountToCredit += KSE.addQuantityToField(orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply,0); //deduct from amount to credit using Prepymts
                        if (orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply == null  || orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply == 0)
                            orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply = KSE.addQuantityToField(prepymt.Credit_Memo_Balance__c,0);
                        else{
                            system.debug(LoggingLevel.ERROR,'updating original invoice for prepayment  ='+prepymt.Credit_Memo_Balance__c);
                            orginalInvoicesFromUI.get(prepymt.id).Amount_Applied = prepymtApplied.Credit_Memo_Applied__c;
                            orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply -= KSE.addQuantityToField(prepymtApplied.Credit_Memo_Applied__c,0);                            
                        }
                        
                        system.debug(LoggingLevel.error, 'amountToCredit after prepymt applied: ' + amountToCredit);
                        
                        
                        system.debug(LoggingLevel.error,'reached here. prepymt from UI: ' + orginalInvoicesFromUI.get(prepymt.id));
                        originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Balance__c = 0;
                        system.debug(LoggingLevel.error,'reached here. original prepymt: ' + originalPrepymtInvsMap.get(prepymt.id));
                        
                        if(listOfPrepymtsAppliedToAnInvoice.containsKey(SupplierInv.id))
                            listOfPrepymtsAppliedToAnInvoice.get(SupplierInv.id).add(prepymtApplied);
                        else
                            listOfPrepymtsAppliedToAnInvoice.put(SupplierInv.id, new List<Supplier_Invoice__c>{prepymtApplied});
                        
                        system.debug(LoggingLevel.error,'reached here. Prepymts per Inv: ' + listOfPrepymtsAppliedToAnInvoice.get(SupplierInv.id));
                    }else{
                        //if Prepymet balance is greater than amountToCredit. 
                        system.debug(LoggingLevel.error,'prepymt is greater than or equal to amount to credit.');
                        system.debug(LoggingLevel.error,'prepymt balance:' + KSE.addQuantityToField(orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply,0));		
                        Supplier_Invoice__c prepymtApplied = new Supplier_Invoice__C();
                        prepymtApplied.id = prepymt.id;
                        prepymtApplied.Credit_Memo_Balance__c = -amountToCredit;
                        prepymtApplied.Credit_Memo_Applied__c = -amountToCredit;
                        system.debug(LoggingLevel.error, 'prepymtApplied: ' + prepymtApplied);
                        
                        if (originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Applied__c == null)
                            originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Applied__c = -amountToCredit;
                        else
                            originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Applied__c += amountToCredit;	
                        
                        if (originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Balance__c == null || originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Balance__c == 0)
                            originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Balance__c = (prepymt.Credit_Memo_Balance__c + amountToCredit);
                        else
                            originalPrepymtInvsMap.get(prepymt.id).Credit_Memo_Balance__c += amountToCredit;
                        
                        system.debug(LoggingLevel.error, 'prepymt original: ' + originalPrepymtInvsMap.get(prepymt.id));
                        
                        orginalInvoicesFromUI.get(prepymt.id).Amount_To_Apply -= KSE.addQuantityToField(prepymtApplied.Credit_Memo_Balance__c,0);
                        orginalInvoicesFromUI.get(prepymt.id).Amount_Applied = -KSE.addQuantityToField(amountToCredit,0);
                        system.debug(LoggingLevel.error, 'prepymt original after update: ' + orginalInvoicesFromUI.get(prepymt.id));         
                        
                        if(listOfPrepymtsAppliedToAnInvoice.containsKey(SupplierInv.id))
                            listOfPrepymtsAppliedToAnInvoice.get(SupplierInv.id).add(prepymtApplied);
                        else
                            listOfPrepymtsAppliedToAnInvoice.put(SupplierInv.id, new List<Supplier_Invoice__c>{prepymtApplied});
                        
                        amountToCredit = 0;	//assuming that amount to credit is <= prepymt balance hence marking SI as consumed by credit
                        system.debug(LoggingLevel.error,'List of Prepymts per Inv: ' + listOfPrepymtsAppliedToAnInvoice.get(SupplierInv.id));
                        
                    }
                }
                if(amountToCredit == 0) // if amount to apply is 0 then break and move forward else continue iterating over Prepymts
                    break;
            }
            
        }
        return amountToCredit;
    }
    /*
		Description : consume credit memos if any for the same supplier against supplier invoice chosen to be paid out
		@param : Supplier_Invoice__c : supplier invoice to be paid out
				 amountToCredit : amount to be consumed
		return param Void
	*/
    private static void applyCreditMemos(Supplier_Invoice__c SupplierInv,Decimal amountToCredit){
    	system.debug(LoggingLevel.WARN, 'applying CMs : ' + amountToCredit + ' originalCreditMemosMap =' +originalCreditMemosMap);
        if (!originalCreditMemosMap.values().isEmpty() && amountToCredit > 0){
        	for(Supplier_Invoice__c cm: originalCreditMemosMap.values()){
	            decimal creditMemoBalance  = 0;                        
	            system.debug(LoggingLevel.error,'CM considered: ' + cm);
	            if (KSE.addQuantityToField(orginalInvoicesFromUI.get(cm.id).Amount_To_Apply,0) != 0 && supplierInv.Supplier__c == cm.Supplier__c){ //if CM balance is 0 or null then dont iterate over loop
	                system.debug(LoggingLevel.debug,'CM balance is not zero' + amountToCredit);
	                if ( amountToCredit > Math.abs(KSE.addQuantityToField(orginalInvoicesFromUI.get(cm.id).Amount_To_Apply,0))){ //CM balance is less than amt to pay
	                    //mark the CM as consumed and update the inv's credit memo applied field
	                    //update the global lists and maps
		                    system.debug(LoggingLevel.error,'CM balance is less than amounttocredit, CM balance:' + KSE.addQuantityToField(orginalInvoicesFromUI.get(cm.id).Amount_To_Apply,0));                    
	                    
	                    Supplier_Invoice__c cmConsumed = new Supplier_Invoice__C();
	                    cmConsumed.id = cm.id;
	                    cmConsumed.Credit_Memo_Balance__c = KSE.addQuantityToField(orginalInvoicesFromUI.get(cm.id).Amount_To_Apply,0) ;
	                    cmConsumed.Credit_Memo_Applied__c = KSE.addQuantityToField(orginalInvoicesFromUI.get(cm.id).Amount_To_Apply,0) ;
	                    system.debug(LoggingLevel.error, 'CM original before update: ' + originalCreditMemosMap.get(cm.id));
	                    
	                    if (originalCreditMemosMap.get(cm.id).Credit_Memo_Applied__c == null || originalCreditMemosMap.get(cm.id).Credit_Memo_Applied__c == 0)
	                        originalCreditMemosMap.get(cm.id).Credit_Memo_Applied__c = cm.Credit_Memo_Balance__c;
	                    else
	                        originalCreditMemosMap.get(cm.id).Credit_Memo_Applied__c += cm.Credit_Memo_Balance__c;	
	                    
	                    amountToCredit += KSE.addQuantityToField(orginalInvoicesFromUI.get(cm.id).Amount_To_Apply,0); //deduct from amount to credit using CMs
		                system.debug(LoggingLevel.error, 'amountToCredit after CM: ' + amountToCredit + ' CM original: ' + originalCreditMemosMap.get(cm.id));
	                    if (orginalInvoicesFromUI.get(cm.id).Amount_To_Apply == null  || orginalInvoicesFromUI.get(cm.id).Amount_To_Apply == 0)
	                        orginalInvoicesFromUI.get(cm.id).Amount_To_Apply = KSE.addQuantityToField(cm.Credit_Memo_Balance__c,0);
	                    else{
	                    	if (orginalInvoicesFromUI.get(cm.id).Amount_Applied == null) orginalInvoicesFromUI.get(cm.id).Amount_Applied = 0;
	                    	orginalInvoicesFromUI.get(cm.id).Amount_Applied += orginalInvoicesFromUI.get(cm.id).Amount_To_Apply;
	                        orginalInvoicesFromUI.get(cm.id).Amount_To_Apply -= KSE.addQuantityToField(cmConsumed.Credit_Memo_Balance__c,0);                        
	                    }
		                system.debug(LoggingLevel.WARN,'reached here. original CM from UI: ' + orginalInvoicesFromUI.get(cm.id));
	                    
	                    originalCreditMemosMap.get(cm.id).Credit_Memo_Balance__c = 0;
	                    
		                system.debug(LoggingLevel.WARN,'reached here. original cm: ' + originalCreditMemosMap.get(cm.id));
	
	                    if(listOfCMsAppliedToAnInvoice.containsKey(SupplierInv.id))
	                        listOfCMsAppliedToAnInvoice.get(SupplierInv.id).add(cmConsumed);
	                    else
	                        listOfCMsAppliedToAnInvoice.put(SupplierInv.id, new List<Supplier_Invoice__c>{cmConsumed});
	                    
	                }else{
	                    //if CM is greater than invoice. 
		                system.debug(LoggingLevel.error,'CM is greater than amount to credit. CM balance:' + KSE.addQuantityToField(orginalInvoicesFromUI.get(cm.id).Amount_To_Apply,0));
	                    
	                    Supplier_Invoice__c cmConsumed = new Supplier_Invoice__C();
	                    cmConsumed.id = cm.id;
	                    cmConsumed.Credit_Memo_Balance__c = -amountToCredit;//cm.Credit_Memo_Balance__c  + amountToCredit;
	                    cmConsumed.Credit_Memo_Applied__c = -amountToCredit;
	                    
	                    orginalInvoicesFromUI.get(cm.id).Amount_To_Apply -= KSE.addQuantityToField(cmConsumed.Credit_Memo_Balance__c,0);
	                    orginalInvoicesFromUI.get(cm.id).Amount_Applied = -KSE.addQuantityToField(amountToCredit,0);
	                    
	                    system.debug(LoggingLevel.error, 'CM from UI: ' + orginalInvoicesFromUI.get(cmConsumed.id));
	                    if (originalCreditMemosMap.get(cm.id).Credit_Memo_Applied__c == null)
	                        originalCreditMemosMap.get(cm.id).Credit_Memo_Applied__c = -amountToCredit;
	                    else
	                        originalCreditMemosMap.get(cm.id).Credit_Memo_Applied__c += -amountToCredit;	
	                    
	                    if (originalCreditMemosMap.get(cm.id).Credit_Memo_Balance__c == null || originalCreditMemosMap.get(cm.id).Credit_Memo_Balance__c == 0)
	                        originalCreditMemosMap.get(cm.id).Credit_Memo_Balance__c = (cm.Credit_Memo_Balance__c + amountToCredit);
	                    else
	                        originalCreditMemosMap.get(cm.id).Credit_Memo_Balance__c += amountToCredit;
	                    
		                system.debug(LoggingLevel.WARN, 'CM original: ' + originalCreditMemosMap.get(cm.id));
		                system.debug(LoggingLevel.WARN,'reached here. original cm: ' + cmConsumed);
	                    if(listOfCMsAppliedToAnInvoice.containsKey(SupplierInv.id))
	                        listOfCMsAppliedToAnInvoice.get(SupplierInv.id).add(cmConsumed);
	                    else
	                        listOfCMsAppliedToAnInvoice.put(SupplierInv.id, new List<Supplier_Invoice__c>{cmConsumed});
	                    amountToCredit = 0;	//assuming that amount to credit is <= prepymt balance hence marking SI as consumed by credit
	                   
	                }
		            system.debug(LoggingLevel.error,'reached here. CMs per Inv: ' + listOfCMsAppliedToAnInvoice.get(SupplierInv.id));
	            }      
	            if(amountToCredit == 0) // if amount to apply is 0 then break and move forward else continue iterating over Prepymts
	                break;              	
    		}
        }
    }
    private void insertPaymentInDB(List<Supplier_Payment__c > supplierPaymentList,List<Supplier_Payment_Line__c> listOfPayments){
    	DML.upsertAsSystem(); upsert supplierPaymentList  Source_Key__c;
        //insert payment lines
        DML.insertAsSystem( listOfPayments);
    }
    /******************************END OF PAYMENT LINE PROCESSING METHODS ************************/
    
    /**************************** START OF PRE-FINALIZE/FINALIZE METHODS ******************************/
    
    public List<paymentWithLinesWrapper> CreateFinalizePaymentsForImmediate(boolean totalCreditsExceedsDebits ,GridRelatedListController.GridRelatedListConfig config,List<Supplier_Payment__c> spList,List<Supplier_Payment_Line__c> spLineList) {
    	List<Notify.Message> messages = new List<Notify.Message>();
    	set<string> sourceKeySet = new set<string>();

    	system.debug(LoggingLevel.error, 'payment headers created ready for finalize batch : '  + spList);
    	system.debug(LoggingLevel.error, 'payment lines created ready for finalize batch : '  + spLineList);
    	for (Supplier_Payment__c suppPayment :spList)
    		sourceKeySet.add(suppPayment.Source_Key__c);
    		
    	//create payment and lines
    	insertPaymentInDB(spList,spLineList);
    	
		String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        set<String> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
        string whereClause = '  Finalized__c = false And Status__c =\'Applied\'' +
					   ' and Batch_Job_Id__C = null  and Source_Key__c IN :sourceKeySet';
		
		SOQLUtil supplierPaymentSOQL = new SOQLUtil ( config.objectName,true) ;//enforceFLS=true, running in user mode
		supplierPaymentSOQL.addFields(new set<string> {'Name','Status__c','Status_Reason__c'});
        supplierPaymentSOQL.addFields (fieldset ) ;       
        supplierPaymentSOQL.addFields(addlFields);
        supplierPaymentSOQL.setWhereClause ( whereClause ) ;
        //SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(supplierPaymentSOQL, 'Supplier_Payment_Lines__r');
        //childRel.addFields('Payment_Lines_Preview');
        //supplierPaymentSOQL.addChildRelationship(childRel);
	    spList = Database.query( supplierPaymentSOQL.getQuery () ) ;                   
	    set<Id> SPIdSet = new set<Id>();
		
		for (Supplier_Payment__C sp :spList){
			SPIdSet.add(sp.id);
		}              
        Set<string> paymentMethodSet = new Set<string>(KSE.grepFieldFromList(spList,'Payment_Method_G__c',true));
        
        //create another query to fetch payment lines because of error "Aggregate query has too many rows for direct assignment, use FOR loop = External entry point "
        SOQLUtil supplierPaymentLineSOQL = new SOQLUtil ( 'Supplier_Payment_Line__c',true) ;//enforceFLS=true, running in user mode		      
        supplierPaymentLineSOQL.addFields('Payment_Lines_Preview');
        supplierPaymentLineSOQL.addFields(new set<string> {'Name','Supplier_Payment__c','Amount__c','Type__c','Supplier_Invoice__c'});
        supplierPaymentLineSOQL.setWhereClause ( ' Supplier_Payment__c IN :SPIdSet' ) ;
        system.debug(LoggingLevel.Info,'SP Line Query : '+supplierPaymentLineSOQL.getQuery ());
	    List<Supplier_Payment_Line__c> spLinesList = Database.query( supplierPaymentLineSOQL.getQuery () ) ;    
	    system.debug(LoggingLevel.Debug,'Finalize Batch find lines fetched : ' + spLinesList.Size());
	    Map<Id,List<Supplier_Payment_Line__c>> SPLineToFinalizeMap = new Map<Id,List<Supplier_Payment_Line__c>>();
	    List<Supplier_Payment_Line__C> spLineAppend = new List<Supplier_Payment_Line__C>(); 
        for (Supplier_Payment_Line__C spLine :spLinesList){     
        	spLineAppend = new List<Supplier_Payment_Line__C>(); 
        	spLineAppend.add(spLine);
        	if (SPLineToFinalizeMap.containsKey(spLine.Supplier_Payment__c))  {
        		spLineAppend.addAll(SPLineToFinalizeMap.get(spLine.Supplier_Payment__c));        		
        	}
    		SPLineToFinalizeMap.put(spLine.Supplier_Payment__c,spLineAppend);        
        }
               
        system.debug(LoggingLevel.Error,'SPLineToFinalizeMap == ' +SPLineToFinalizeMap.size());
    	messages = FinalStepToFinalize(totalCreditsExceedsDebits,spList,SPLineToFinalizeMap);
    	system.debug(LoggingLevel.Debug,'messages='+messages);
    	system.debug(LoggingLevel.Info, 'final SP queryString: ' + supplierPaymentSOQL.getQuery ()); 

    	List<string> str = new List<String>();
    	for (string sourceKey:sourceKeySet){
    		str.add(sourceKey + '%');
    	}
    	whereClause = ' Batch_Job_Id__C = null  and Source_Key__c Like :str';   
	    supplierPaymentSOQL.setWhereClause ( whereClause ) ; 	
    	spList = Database.query( supplierPaymentSOQL.getQuery () ) ;    
    	List<paymentWithLinesWrapper> paymentWrapperList = new List<paymentWithLinesWrapper>();
    	if (paymentMethodSet.size() == 1 && paymentMethodSet.contains(PaymentService.PAYMENT_METHOD_CHECK)){
    		//KNDY-17923 - deperecated 'payment_number__c' 	
    		KSE.sortList( spList, 'Reference__c', 'asc' );  
    	}
    	paymentWithLinesWrapper payWrapper;
    	for (Supplier_Payment__c payment : spList){
    		system.debug(LoggingLevel.Info,'Payment lines to be sent back == ' +SPLineToFinalizeMap.get(payment.id));
    		payWrapper = new paymentWithLinesWrapper(payment,SPLineToFinalizeMap.get(payment.id));
    		paymentWrapperList.add(payWrapper);
    	}
    	if (paymentWrapperList != null){
	    	paymentWrapperList[0].messages = new list<string>();
	    	if (messages != null){
		    	for (Notify.Message msg :messages){
		    		paymentWrapperList[0].messages.add(msg.getTitle() + ' ' + msg.getBody());
		    	}
	    	}
    	}
    	system.debug(LoggingLevel.Error,'immediate mode final wrapper to send back to page : '+ paymentWrapperList);
    	return paymentWrapperList;
    }
    
    public List<Notify.Message> FinalStepToFinalize(boolean totalCreditsExceedsDebits,List<Supplier_Payment__c> SPToFinalize,Map<Id,List<Supplier_Payment_Line__c>> SPLinesToFinalize){
    	List<Notify.Message> messages = new List<Notify.Message>();
    	system.debug (LoggingLevel.ERROR,'totalCreditsExceedsDebits ='+ totalCreditsExceedsDebits + ' final step making SP on final stage Execute : ' + SPToFinalize);
		List<Supplier_Payment__c> SPToFinalizeList = null;
		string zeroPaymentMsg = '';
		list<string> SPNames = new list<String>();
		try {
			//check if total credits exceeds debits checkbox is not checked  find zero amount payments and cancel those 
			//else if allow zero amount checkbox checked, go directly to finalize method since we don't need to cancel payments even if zero amount payment created 
			if (!totalCreditsExceedsDebits)	{
				SPToFinalizeList = FindZeroAmountPayments(totalCreditsExceedsDebits,SPToFinalize);
				Set<string> batchJobIds = new Set<string>(KSE.grepFieldFromList(SPToFinalizeList,'Batch_Job_Id__c',true));
				system.debug(LoggingLevel.Error,'grep batchJobIds ='+batchJobIds);
				//KNDY-17206 -add zero payment msg with cancelled SPs list
				if (batchJobIds.size() == 1) {
					zeroPaymentMsg = Label.Payment_amount_was_zero_Create_Zero_Amount_Payments_checkbox_unselected + ' ';
					for (Supplier_Payment__c cancelledpayment :SPToFinalizeList){
						if (String.isNotBlank(cancelledpayment.Batch_Job_ID__c) && cancelledpayment.Status__c == PaymentService.STATUS_CANCELLED 
							&& cancelledpayment.Status_Reason__c == PaymentService.STATUS_REASON_ZERO_AMT_PAYMENT_NOT_ALLOWED){
							SPNames.add(cancelledpayment.Name);
						}
					}
					system.debug(LoggingLevel.Info,'SPNames=' +SPNames.size() + '='+SPNames);
					if (SPNames.size() >0) {
						zeroPaymentMsg = zeroPaymentMsg + String.join(SPNames, ', ');
						messages.add(new Notify.Message(zeroPaymentMsg, ''));
					}
				}
			}else
				SPToFinalizeList = SPToFinalize;
	
			system.debug(LoggingLevel.ERROR,'Finalize SP Execute before identifying skipped check: ' + SPToFinalizeList);
			Set<string> paymentMethodSet = new Set<string>(KSE.grepFieldFromList(SPToFinalizeList,'Payment_Method_G__c',true));
			Set<string> bankAccountSet = new Set<string>(KSE.grepFieldFromList(SPToFinalizeList,'Bank_Account__c',true));
			
			system.debug(LoggingLevel.Error,' payment method list =' +paymentMethodSet.size() + ' bankAccountSet= '+bankAccountSet);
			if (paymentMethodSet.size() == 1 && paymentMethodSet.contains(PaymentService.PAYMENT_METHOD_CHECK) && bankAccountSet.size()  == 1){
				SPToFinalizeList = identifySkippedChecksForPayments(SPToFinalizeList,new list<string> (paymentMethodSet) [0],new list<string> (bankAccountSet) [0]);
			}else{
				// notify exception in message  and cancel payments
				if (paymentMethodSet.size() > 1)
					throw new CustomException (Label.Multiple_Payment_Methods_Found);
				if (bankAccountSet.size() > 1)
					throw new CustomException (Label.Multiple_Bank_Account_Found); 
			}
			system.debug(LoggingLevel.ERROR,'Finalize SP Execute : ' + SPToFinalizeList);
	        FinalizePayments(SPToFinalizeList,SPLinesToFinalize);
        }catch(CustomException ex){
        	cancelSPs(SPToFinalizeList);
 			messages.add(new Notify.Message(ex.getMessage(), ''));
 			system.debug(LoggingLevel.ERROR, 'error in finalize payments in custom exception : ' + ex.getMessage() +  ex.getStackTraceString() );
        }catch(DMLException ex) {
			cancelSPs(SPToFinalizeList);            
            for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {
                
                    string errorMessage = ex.getDmlMessage(idx);
                    string statusCode = ex.getDmlStatusCode(idx);
                    Integer location;    
                    system.debug(LoggingLevel.Error,'errorMessage=='+ ex.getStackTraceString() + '-message = ' + ex.getMessage() +'getDmlStatusCode' + ex.getDmlStatusCode(idx));
                    if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('REQUIRED_FIELD_MISSING')){
                    list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
					msgArray = errorMessage.split('REQUIRED_FIELD_MISSING,');
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
                    
                messages.add(new Notify.Message( statusCode + '-' + errorMessage, ''));
        	}        	
        	system.debug(LoggingLevel.ERROR, 'error in finalize payments in dml exception: ' + ex );
		}
        catch ( DML.InsuffientAccessException e ) { 
 			cancelSPs(SPToFinalizeList);
 			messages.add(new Notify.Message(Label.Insufficient_access_contact_administrator_for_permissions, '')); 
 		}catch (Exception e) { //AR-15 JSONResult addMessage handles DML Exception
        	cancelSPs(SPToFinalizeList);
 			messages.add(new Notify.Message(e.getMessage(), '')); //AR-15
 			system.debug(LoggingLevel.ERROR, 'error in finalize payments in exception: ' + e.getMessage() + ' = '+ e.getStackTraceString() );
        }        
        return messages;
    }
    public void cancelSPs(List<Supplier_Payment__c> SPToFinalizeList){
    	for (Supplier_Payment__c payment :SPToFinalizeList){
			payment.Status__c = PaymentService.STATUS_CANCELLED;
			payment.Finalized__c = false;
			payment.Finalized_Hidden__c = false;
		}
		DML.updateAsSystem(SPToFinalizeList, false);
		system.debug(LoggingLevel.Error,'Cancel errorneous SPs : ' +SPToFinalizeList);
    }
     /*
		Description : find zero amount payments and if allow zero credit payment checked allow or cancel it
		@param : List<Supplier_Payment__c>  : List of supplier payments to be finalized
		return param List<Notify.Message>  : return failure/success message if any 
	*/
    public List<Supplier_Payment__c>  FindZeroAmountPayments(Boolean totalCreditsExceedsDebits,List<Supplier_Payment__c> SPToVerifyList){
    	List<Supplier_Payment__c>  SPToFinalize = new List<Supplier_Payment__c>();    	
    	if (!totalCreditsExceedsDebits){
    		for(Supplier_Payment__c sp : SPToVerifyList) {
    			if (sp.Payment_Amount__c == 0) {
    				sp.Status__c  = PaymentService.STATUS_CANCELLED;
    				sp.Status_Reason__c = PaymentService.STATUS_REASON_ZERO_AMT_PAYMENT_NOT_ALLOWED;
    			}
    		}
    	}
    	system.debug(LoggingLevel.Error,'Verified zero amount list = ' +SPToVerifyList);
    	return SPToVerifyList;
    	
    }
    //KNDY-17564
	/*
		Desc : identify skipped supplier payment depending on the advice lines defined on bank and update bank check/ach/eft details. Also creates cancelled SPs 
				in case of check numbers are skipped because of overflow of advice lines per page allowed 
		@param List<Supplier_Payment__c> : list of payments before it goes to finalize
		return param List<Supplier_Payment__c> : list of supplier payment finalized
	*/
	public static List<Supplier_Payment__c>  identifySkippedChecksForPayments(List<Supplier_Payment__c> SPListForSkipChecks,String paymentMethod,Id bankAccountID){
		//KNDY-17564
		Set<Id> paymentIds = new Set<Id>();
		List<Supplier_Payment__c> resultingPayments = new List<Supplier_Payment__c>();
		Map<Id,integer> supplierPaymentLineAggregateMap = new Map<id,integer>();
		
		
		Map<id,Map<decimal,sObject>> skippedCheckNoIdMap = new Map<id,Map<decimal,sObject>>();
		Map<decimal,sObject> skippedCheckSObj = new Map<decimal,sObject>();
		Map<decimal,sObject> skippedCheckSObjTemp = new Map<decimal,sObject>();
		List<Supplier_Payment__c> sps = new List<Supplier_Payment__c>();
	    Map<Id,integer> sObjectChildLinesAggregateMap = new map<Id,Integer>();
	    for (Supplier_Payment__c suppPayment :SPListForSkipChecks ){
	    	if (suppPayment.Status__c == PaymentService.STATUS_APPLIED){
	    		sObjectChildLinesAggregateMap.put(suppPayment.Id,(Integer)suppPayment.Total_Number_of_Lines__c);
	    	}
	    }
	    
	    system.debug(LoggingLevel.Error,'Supplier payment Map with id and number of lines' +sObjectChildLinesAggregateMap);
		decimal nextNumberFromBank = 0;
		
			
		Bank_Account__c ba = PaymentService.getPaymentNumber( bankAccountID );
		//KNDY-18900 Replace next check number (number) field with text field
		nextNumberFromBank = ba.Next_Check_Number_2__c == null ? 1 :  Decimal.valueOf(ba.Next_Check_Number_2__c);
		if (ba.Use_Pre_Printed_Check_Stock__c && ba.Number_of_Advice_Lines_Per_Page__c > 0){
			skippedCheckNoIdMap = CheckService.getSkippedCheckDetails(sObjectChildLinesAggregateMap,ba);
		}
				
		if( nextNumberFromBank == null ) { nextNumberFromBank = 0; }
		
        for(Supplier_Payment__c payment:SPListForSkipChecks){
        	if (payment.Status__c == PaymentService.STATUS_APPLIED){
	            paymentIds.add(payment.Id);
	            system.debug(LoggingLevel.Info,'nextNumberFromBank before assigning to SP : ' +nextNumberFromBank);
	            //Supplier_Payment__c sp = new Supplier_Payment__c (Id = payment.Id);
	            //KNDY-17923 - deperecated 'payment_number__c' 	
	            if (payment.Reference__c == null) {
	            	payment.Reference__c = String.ValueOf(nextNumberFromBank);	            	
	            }else{
	            	nextNumberFromBank =  String.isNotBlank(payment.Reference__c) ? Decimal.valueOf(payment.Reference__c) : null;
	            	//KNDY-18900 Replace next check number (number) field with text field
	            	ba.Next_Check_Number_2__c = String.ValueOf(nextNumberFromBank); 
	            }
	            system.debug(LoggingLevel.Info,'nextNumberFromBank before assigning to SP1 : ' +nextNumberFromBank);
				//KNDY-17923 - deperecated 'Check_Number__c' 
	        	//if (payment.check_number__c == null)  payment.check_number__c = nextNumberFromBank;
	        	if (payment.Reference__c == null)  payment.Reference__c = string.valueOf(nextNumberFromBank);
				if (ba.Use_Pre_Printed_Check_Stock__c && ba.Number_of_Advice_Lines_Per_Page__c > 0){
					skippedCheckSObj = skippedCheckNoIdMap.get(payment.Id);
					skippedCheckSObjTemp = new Map<decimal,sObject>();
					system.debug(LoggingLevel.Info,'inside finalizeSupplierPayment skippedCheckSObj='+skippedCheckSObj);
					decimal checknumberCurrent = 0;
					if (skippedCheckSObj != null){
						checknumberCurrent = nextNumberFromBank + 1;
						for (integer i = 0; i < skippedCheckNoIdMap.get(payment.Id).size() ; i++){
							
							system.debug(LoggingLevel.Info,'checknumberCurrent='+checknumberCurrent);								
							skippedCheckSObjTemp.put(checknumberCurrent,null);
							checknumberCurrent++;
						}
						
						system.debug(LoggingLevel.Error,'inside finalizeSupplierPayment skippedCheckSObjTemp after ='+skippedCheckSObjTemp);
						skippedCheckSObj = CheckService.updateClonedObject((sObject) payment,skippedCheckSObjTemp);
						List<Supplier_Payment__c> clonedSPList = new List<Supplier_Payment__c>();
						system.debug(LoggingLevel.Info,'skippedCheckSObj.values()=='+skippedCheckSObj.values());
						for (sObject sobjPayment : skippedCheckSObj.values()){
							clonedSPList.add((Supplier_Payment__c) sobjPayment);
							//KNDY-17923 - deperecated 'Check_Number__c' 
							//nextNumberFromBank = (decimal)sobjPayment.get('check_number__c');
							nextNumberFromBank = sobjPayment.get('Reference__c') != null ? Decimal.valueOf(String.ValueOf(sobjPayment.get('Reference__c'))) : null;
						}
						sps.addAll(clonedSPList);
						system.debug(LoggingLevel.ERROR,'nextNumberFromBank = '+ nextNumberFromBank  +'=clonedSPList=='+clonedSPList);
					}
				}					                  
	            nextNumberFromBank++;                      
        	}
        }
        SPListForSkipChecks.addAll(sps);
        system.debug(LoggingLevel.Error,'SPListForSkipChecks==' + SPListForSkipChecks);
        CheckService.updateBankAccount(ba,nextNumberFromBank,paymentMethod);        
		return SPListForSkipChecks;
       
	}
	
    /*
		Description : finalize payments. used in SupplierPaymentFinalizeBatch class
		@param : List<Supplier_Payment__c>  : List of supplier payments to be finalized
		return param List<Notify.Message>  : return failure/success message if any 
	*/
    private void FinalizePayments(List<Supplier_Payment__c> SPToFinalizeList,Map<Id,List<Supplier_Payment_Line__c>> SPLinesToFinalize){
    	 	
    	decimal amount = 0;
    	Set<String>  supplierInvoiceIds = new Set<String>();
    	Set<String>  supplierPaymentIds = new Set<String>();
    	system.debug(LoggingLevel.Error,'Finalized SPs before update: '+SPToFinalizeList);
    	
    	
		for(Supplier_Payment__c sp : SPToFinalizeList) {
			amount = 0;
			system.debug(LoggingLevel.Error,'Finalized SPlines before update: '+SPLinesToFinalize.get(sp.id));
			if (SPLinesToFinalize.containsKey(sp.id)){
			
				for (Supplier_Payment_Line__c paymentLine :SPLinesToFinalize.get(sp.id)){
					supplierInvoiceIds.add(paymentLine.Supplier_Invoice__c);
					if (paymentLine.Type__c != PaymentService.TYPE_EARNED_DISCOUNT){
						//KNDY-19448 - set scale with 2 digits
						amount += paymentLine.Amount__c != null ? paymentLine.Amount__c.setScale(2) : 0;
					}
				}
			}
			if (sp.Status__c == PaymentService.STATUS_APPLIED){
				sp.Payment_Amount__c = amount;
				sp.Amount_In_Words__c = NumberToWordUtil.numberToWordsWithDecimal(sp.Payment_Amount__c);
				sp.Finalized__c = true;
				supplierPaymentIds.add(sp.id);  
	        }
		}

		system.debug(LoggingLevel.Error,'Finalized SPs : '+SPToFinalizeList);
		//upsert newly created skipped check payments else update payment with status
		DML.upsertAsSystem(); upsert SPToFinalizeList id;
		//for batch mode call updateSupplierInoiceForFinalizedPayments Method else vf page will call as seperate remoting call.
		Set<string> batchJobId = new Set<string>(KSE.grepFieldFromList(SPToFinalizeList,'Batch_Job_Id__c',true));
		system.debug(LoggingLevel.Info,'batchJobId before updateSI called (Last call for create SP flow): ' + batchJobId);
		if (batchJobId.size() == 1){
			updateSupplierInoiceForFinalizedPayments(supplierInvoiceIds,supplierPaymentIds);
		}
		
		
    }
    public void updateSupplierInoiceForFinalizedPayments(Set<String> supplierInvoiceIds,Set<String> supplierPaymentIds){
    	//update supplier invoices
        system.debug(LoggingLevel.WARN,'Supplier invoice ids to update statuses and amount fields : '+ supplierInvoiceIds);
        try{
	        if (!supplierInvoiceIds.isEmpty()){
	            SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
	            soql.addFields(new set<string>{
	                'Id','Supplier__r.X1099_Box__c','Invoice_Type__c','Credit_Memo_Balance__c','Invoice_Amount__c','Status__c','Discount_Taken__c',
	                'Credit_Memo_Amount__c', 'Amount_Paid__c', 'Credit_Memo_Applied__c'
	            });
	            soql.setWhereClause('Id IN :supplierInvoiceIds');
	            
	            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Supplier_Payment_Lines__r');
	            childRel.addFields(new set<string>{
	                'Id','name','amount__c','type__c','supplier_payment__r.finalized__c','Supplier_Payment__r.Status__c'
	            });            
	            //childRel.setWhereClause(' supplier_payment__r.finalized__c = true And supplier_payment__r.Void__c = false ');
	            soql.addChildRelationship(childRel);
	            
	            Map<Id, Supplier_Invoice__c> mSupplierInvoices = new Map<Id, Supplier_Invoice__c>((List<Supplier_Invoice__c>)Database.query(soql.getQuery()));
	            system.debug(LoggingLevel.Error,' before suminvoicepayment method : ' + mSupplierInvoices.values().size());
	            sumInvoicePayments(mSupplierInvoices.values());
	            //requery updated date from supplier invoice to update statuses
	            /*soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
	            soql.addFields(new set<string>{
	                'Id','Supplier__r.X1099_Box__c','Invoice_Type__c','Credit_Memo_Balance__c','Invoice_Amount__c','Status__c','Discount_Taken__c',
	                'Credit_Memo_Amount__c', 'Amount_Paid__c', 'Credit_Memo_Applied__c'
	            });
	            soql.setWhereClause('Id IN :supplierInvoiceIds');
	            mSupplierInvoices = new Map<Id, Supplier_Invoice__c>((List<Supplier_Invoice__c>)Database.query(soql.getQuery()));   
	            for (Supplier_Invoice__c SIs: mSupplierInvoices.values() ){
	            	system.debug(LoggingLevel.Error,' SIs Type : ' + SIs.Invoice_Type__c);
	                if ((SIs.Invoice_Type__c == PaymentService.TYPE_INVOICE || (SIs.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT && SIs.Status__C == PaymentService.STATUS_APPROVED))
	                    && (KSE.addQuantityToField(SIs.Amount_Paid__c,0) + KSE.addQuantityToField(SIs.Discount_Taken__c,0)) == SIs.Invoice_Amount__c ){
	                    	
	                    SIs.status__c = PaymentService.STATUS_CLOSED;
	                    SIs.Date_Time_Paid__c = System.now();
	                    system.debug(LoggingLevel.Error,' SIs status : ' + SIs.status__c);
	                }else if ((SIs.Invoice_Type__c == PaymentService.TYPE_CREDITMEMO || (SIs.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT && SIs.Status__C == PaymentService.STATUS_CLOSED))
	                          && SIs.Credit_Memo_Balance__c == 0 ){
	                    SIs.status__c = PaymentService.STATUS_CLOSED;
	                    SIs.Date_Time_Paid__c = System.now();
	                }
	            }
	            DML.updateAsSystem(mSupplierInvoices.values(), false);
	            system.debug(LoggingLevel.Error,'updated status invoices : '+ mSupplierInvoices.values());*/
	        }  
        }catch (exception ex){
        	system.debug(LoggingLevel.Error,'Error while updating SIs : ' + ex.getMessage()  + ' Stack trace:  ' +  ex.getStacktraceString());
        	//if exception occurs cancel those SPs
        	List<Supplier_Payment__c> SPToCancel = [select Id,Status__c, Finalized__c,Finalized_Hidden__c from Supplier_Payment__c where Id IN :supplierPaymentIds];
        	CancelSPs(SPToCancel);
        	throw new CustomException(ex.getMessage());
        }
        
    } 
    /**************************** END OF PRE-FINALIZE/FINALIZE METHODS ******************************/
    
    
    /***************** START Methods used in SupplierPaymentVoidCancelExt class*/
    public static List<String> getSPVoidCancelErrors(Id spId){ //KNDY-13654
        List<String> errors = new List<String>();
        Map<Id, String> errorMap = validatePrepaymentSPVoidCancel(new List<Id>{spId});
        if(errorMap.containsKey(spId)){
            errors.add (errorMap.get(spId));
        }
        return errors;
    }
    public static void onVoidCancel(List<Supplier_Payment__c> lSPs){
	
        SOQLUtil soql = new SOQLUtil('Supplier_Payment_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Name','Amount__c','Supplier_Invoice__c','Supplier_Payment__c','Type__c','Supplier_Payment__r.Finalized__c','Supplier_Payment__r.Status__c'
        });
        soql.setWhereClause('Supplier_Payment__c IN :lSPs and (Type__c = \'Payment\' or Type__c = \'Credit Memo\' or Type__c = \'Prepayment\')');
        List<Supplier_Payment_Line__c> lSPLs = Database.query(soql.getQuery());

                Set<Id> invoiceIds = new Set<Id>();
        for(Supplier_Payment_Line__c splRec : lSPLs){
           invoiceIds.add(splRec.Supplier_Invoice__c);  
                }

                soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'Status__c','Name','Invoice_Type__c','Invoice_Amount__c','Id','Company__c','Credit_Memo_Applied__c','Supplier__c','Supplier_Invoice__c',
                    'Exception__c','Balance_Due__c','Date_Invoiced__c','Payment_Term__c','Memo__c','Credit_Memo_Amount__c',
                    'Credit_Memo_Balance__c', 'Amount_Paid__c'
                });
                soql.setWhereClause('id IN :invoiceIds');
                
                SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Supplier_Payment_Lines__r');
                childRel.addFields(new set<string>{
                    'id','Name','Amount__c','Type__c','Supplier_Payment__r.Finalized__c','Supplier_Payment__r.Status__c'
                });
                soql.addChildRelationship(childRel);
        List<Supplier_Invoice__c> SInvoiceList = Database.query(soql.getQuery());
        SupplierPaymentService.sumInvoicePayments(SInvoiceList);

        soql = new SOQLUtil('Bank_Transaction_Match__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{'Id'});
        List<String> spIds = KSE.grepFieldFromList(lSPLs, 'Supplier_Payment__c', true);
        soql.setWhereClause('Supplier_Payment__c in :spIds');
        list<Bank_Transaction_Match__c> lBTM2Delete = Database.query(soql.getQuery());
                                
        Savepoint sp = Database.setSavepoint();
        try {
               
            DML.allowUpdateFields( new list<string>{'Status__c', 'Finalized__c'}, Supplier_Payment__c.SObjectType );
            DML.sobjectUpdate(lSPs);
            if(!lBTM2Delete.isEmpty())
                DML.deleteAsUser(lBTM2Delete);      
        }
        catch(Exception ex)
        {
            system.debug('SP service exception: '+ex.getMessage());
            database.rollback(sp);
            throw ex;
        }
	    
	}
	
    //KNDY-13654 Validate void/cancel for SP that paid off a prepayment SI 
    public static Map<Id, String> validatePrepaymentSPVoidCancel(List<Id> spIds){
        Map<Id, String> errors = new Map<Id,String>();
        
        // Get SP with its spls of type payment and SI of type 'Prepayment'
        List<Supplier_Payment__c> sps = getPrepaymentSIFromSP(spIds);
        
        if (sps.size() > 0){
            for (Supplier_Payment__c sp : sps){
                // if SP has no lines, its not a SP Payment made to pay off a prepayment SI
                if (sp.Supplier_Payment_Lines__r != null){
                    for (Supplier_Payment_Line__c spl : sp.Supplier_Payment_Lines__r){
                        Supplier_Invoice__c prepaymentSI = spl.Supplier_Invoice__r;
                        if ( prepaymentSI.Credit_Memo_Amount__c != prepaymentSI.Credit_Memo_Balance__c){
                            errors.put(sp.Id, Label.SP_Void_is_not_allowed);
                            break;
                        }
                    }
                }
            }
        }
        return errors;
    }
    
    private static List<Supplier_Payment__c> getPrepaymentSIFromSP(List<Id> paymentIds){//KNDY-13654
        Set<String> spFields = new Set<String> {'Id','Name'};
        String whereClause = ' id in :paymentIds and Status__c != \'Void\' and Status__c != \'Cancelled\'';
        SOQLUtil soql = new SOQLUtil ( 'Supplier_Payment__c' ) ;
        soql.addFields (spFields) ;
        soql.setWhereClause (whereClause);
        
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Supplier_Payment_Lines__r');
        childRel.addFields(new Set<String>{'Id', 'Name', 'Supplier_Invoice__c', 'Supplier_Invoice__r.Id', 
            'Supplier_Invoice__r.Credit_Memo_Balance__c', 'Supplier_Invoice__r.Credit_Memo_Amount__c'});
        childRel.setWhereClause ('Type__c = \'Payment\' and Supplier_Invoice__c != null and Supplier_Invoice__r.Invoice_Type__c = \'Prepayment\'');
        soql.addChildRelationship(childRel);
        
        List<Supplier_Payment__c> sps = Database.query (soql.getQuery()) ;
        return sps; 
    }
     /***************** END Methods used in SupplierPaymentVoidCancelExt class*/
    public class CustomException extends Exception{}   
}