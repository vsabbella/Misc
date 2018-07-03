public with sharing class CustomerInvoiceService {
    set<ID> newcustInvoiceIds;
    set<ID> invCustomerID;
    
    //Customer Invoice Record Type Names
    public static final string RT_INVOICE = 'Invoice';
    public static final string RT_CREDIT_MEMO = 'Credit_Memo';
    
    //Customer Invoice - Invoice Types
    public static final string TYPE_CREDIT_MEMO = 'Credit Memo';
    public static final string TYPE_SHIP_INVOICE = 'Ship Invoice';
    public static final string TYPE_MANUAL = 'Manual';
    public static final string TYPE_ADJUSTMENT = 'Adjustment';
    public static final string TYPE_SETTLEMENT = 'Settlement';
    public static final string TYPE_CHARGEBACK = 'Chargeback';
    public static final string TYPE_RMA = 'RMA';
    
    //Credit Memo Types
    public static final string CM_OVERPAYMENT = 'Overpayment';
    public static final string CM_PREPAYMENT = 'Prepayment';
    public static final string CM_MISC = 'Miscellaneous';
    public static final string CM_INVOICE = 'Invoice';
    
    //Invoice Statuses
    public static final string STATUS_CLOSED = 'Closed';
    public static final string STATUS_OPEN = 'Open';
    public static final string STATUS_CANCEL = 'Cancelled';
    public static final string STATUS_VOID = 'Void';
    
    //Payment Term Types
    
    
    public static ExceptionService exService = new ExceptionService();
    
    public class CustomerInvoiceException extends Exception{}

    /* 
     *  we record the period that an invoice is paid so that we can calc the Days To Pay by period
     */
    public void setPeriodPaid( ) {
        if ( ! trigger.isBefore ) return; 
        
        list<Customer_Invoice__c> invoiceList = new list<Customer_Invoice__c>();
        Datetime min = system.today() , max = system.today(); 
        
        for( Customer_Invoice__c obj: (list<Customer_Invoice__c>)trigger.new) {
            if ( KSE.isFieldChanging('Date_Time_Paid__c', obj, trigger.oldMap) && 
                obj.Date_Time_Paid__c != null ) {
                invoiceList.add( obj ); // we will work on this invoice
                if ( obj.Date_Time_Paid__c > max ) max = obj.Date_Time_Paid__c;
                if ( obj.Date_Time_Paid__c < min ) min = obj.Date_Time_Paid__c;
            } else if ( obj.Date_Time_Paid__c == null ) { 
                // null out the period paid
                obj.Period_Paid__c = null; 
            }
        }
        if ( invoiceList.size() == 0 ) return;
        
        set<id> companyIds = KSE.grepRelatedIdSetFromList( invoiceList, 'Company__c');
        
        // all periods we care about
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name','year_start_date__c','period_start__c','period_end__c','year_end_date__c','company__c'
		});
		soql.setWhereClause('company__c IN :companyIds AND ( period_start__c <= :max AND period_end__c >= :min )');
		soql.setOrderByClause('period_end__c asc');
		list<Period__c> allPeriods = Database.query(soql.getQuery());

            
        Map<Period__c, Period__c> enclosingPeriodMap = getenclosingPeriodMap(invoiceList, allPeriods);
        
        for( Customer_Invoice__c obj: invoiceList ) { 
            Period__c p = enclosingPeriodMap.get( mapKey( obj.Company__c, obj.Date_Time_Paid__c) );
            if ( p != null ) { 
                obj.Period_Paid__c = p.id;
            }
        }
    } 
    
    // make a multi part key so that we can find the correct period when we access this map 
    private Period__c mapKey( id co, datetime da ) { 
        return new Period__c( Company__c = co, Period_Start__c=da);
    }
    
    /* generate a map of periods by dates found in the list of invoices */
    private Map<Period__c, Period__c> getenclosingPeriodMap ( 
                                                        List<Customer_Invoice__c> scope, 
                                                        List<Period__c> plist ) {
                                                            
        Map<Period__c, Period__c> enclosingPeriodMap = new Map<Period__c, Period__c>(); 
        for ( Customer_Invoice__c ci: scope ) { 
                datetime inputDate = ci.Date_Time_Paid__c; // (Date)ci.get(date_paid); 
                if ( inputDate == null ) continue; 
                for(Period__c period : plist ) {
                if( period.Period_Start__c <= inputDate && 
                        period.Period_End__c >= inputDate) 
                    {
                        enclosingPeriodMap.put( mapKey( ci.Company__c,inputDate), period);
                    break;  
                }
            }
            }
        return enclosingPeriodMap;
    }
    
    public void setCustomerInformation( ) 
    {
    	list<Customer_invoice__c> lCI = new list<Customer_invoice__c>();
    	Set<Id> companyIds = new Set<Id>();
    	for(Customer_invoice__c ci :(list<Customer_Invoice__c>)trigger.new)
    	{
    		
    		if ( trigger.isInsert || KSE.isFieldChanging('Bill_To_Customer__c', ci, trigger.oldMap) 
    							  || ci.Customer__c == null 
    						      || KSE.isFieldChanging('Sold_To_Customer__c', ci, trigger.oldMap)
    						      || KSE.isFieldChanging('Ship_To__c', ci, trigger.oldMap) 
    						      ) {
    			companyIds.add(ci.company__c);
    			lCI.add(ci);
    		}
    		
    			
    	}
    	
    	if(!lCI.isEmpty())
    	{
        Set<id> BillToCustomerSet = KSE.grepRelatedIdSetFromList( lCI, 'Bill_To_Customer__c');
        Set<id> ShipToCustomerSet = KSE.grepRelatedIdSetFromList( lCI, 'Ship_To__c'); 
        Set<id> sCustomerIds      = KSE.grepRelatedIdSetFromList( lCI, 'Sold_To_Customer__c');
        sCustomerIds.addAll(BillToCustomerSet); //add all the bill to set ids 
        sCustomerIds.addAll(ShipToCustomerSet); //add all the ship to cust ids
        
        Set<id> SalesOrderSet = KSE.grepRelatedIdSetFromList( lCI, 'Sales_Order__c');
		
        Map<id, Customer__c> customerMap = new Map<id, Customer__c>();
        
        if(!sCustomerIds.isEmpty()) {
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Street__c','City__c','State__c','Zip_Code__c','Country__c','Payment_Term__c','Top_Parent_Customer__c', 'Currency__c'
			});
			soql.setWhereClause('id in :sCustomerIds');
			customerMap = new map<id, Customer__c>((List<Customer__c>)Database.query(soql.getQuery()));
        }


                                               
         Map<Id, Sales_Order__c> salesOrderMap = new Map<Id,Sales_Order__c>();
         if(!SalesOrderSet.isEmpty()) {
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Payment_Term__c', 'Currency__c'
			});
			soql.setWhereClause('Id IN : SalesOrderSet');
			salesOrderMap = new Map<Id,Sales_Order__c> ((List<Sales_Order__c>)Database.query(soql.getQuery()));         	
         }
	            
	            Map<Id,Id> companyCurrencyMap = CompanyService.setDefaultCurrency(companyIds); //getting the default currency tagged to company 
            for( Customer_Invoice__c obj: lCI) {
                        
           			//KNDY-2873 - Should pull payment terms from related Sales Order not the related Customer 
		            Sales_Order__c relatedSO = salesOrderMap.get(obj.Sales_Order__c);
		            if(relatedSO != null) {
		                System.Debug(relatedSO);
		                if(obj.Payment_Term__c == null) //as part of grouping rules, payment term should come from fulfillment and not SO
		                obj.Payment_Term__c = relatedSO.Payment_Term__c;
		                System.Debug(obj.Payment_Term__c);
		            }
		            
               
                    if (  obj.Bill_To_Customer__c != null && customerMap.containsKey( obj.Bill_To_Customer__c ) )
                    {
                        Customer__c tmp = customerMap.get( obj.Bill_To_Customer__c );
                        
                        if ( tmp != null ){ // collect these values from the customer KNDY-1884
                        	if(tmp.Top_Parent_Customer__c != null){
                            	obj.Customer__c = tmp.Top_Parent_Customer__c;
                        	}
                            obj.Bill_To_Street__c = tmp.Street__c != null ? tmp.Street__c.replace('<br>', '\n') : tmp.Street__c;
                            obj.Bill_To_City__c = tmp.City__c;
                            obj.Bill_To_State__c = tmp.State__c;
                            obj.Bill_To_Zip_Code__c = tmp.Zip_Code__c;
                            obj.Bill_To_Country__c = tmp.Country__c;
                            
                            System.debug(logginglevel.error,'tmp.Currency__c-->'+tmp.Currency__c);
	                            obj.Currency__c = (obj.Currency__c != null) ? obj.Currency__c : ((tmp.Currency__c != null) ? tmp.Currency__c :  companyCurrencyMap.get(obj.company__c));  
                            
                            if(relatedSO == null && obj.Payment_Term__c == null)
                            	obj.Payment_Term__c = tmp.Payment_Term__c; //OTC-602  If Ci is not linked To an SO, then the payment Term should be copied from the Bill To 
                            //obj.Payment_Term__c = tmp.Payment_Term__c; //KNDY-2873 - Should pull payment terms from related Sales Order not the related Customer
                        }
                    }
                    //AR-89
                    if (  obj.Sold_To_Customer__c != null && customerMap.containsKey( obj.Sold_To_Customer__c ) )
                    {
                        Customer__c tmp = customerMap.get( obj.Sold_To_Customer__c );
                        
                        if ( tmp != null ){ // collect these values from the customer KNDY-1884
                        	
                            obj.Sold_To_Street__c = tmp.Street__c != null ? tmp.Street__c.replace('<br>', '\n') : tmp.Street__c;
                            obj.Sold_To_City__c = tmp.City__c;
                            obj.Sold_To_State__c = tmp.State__c;
                            obj.Sold_To_Zip_Code__c = tmp.Zip_Code__c;
                            obj.Sold_To_Country__c = tmp.Country__c;
                            
                        }
                    }
                    //KNDY-10889
                     if (  obj.Ship_To__c != null && customerMap.containsKey( obj.Ship_To__c ) )
                    {
                         Customer__c tmp = customerMap.get( obj.Ship_To__c );
                          if ( tmp != null ){  
                            obj.Ship_to_Street__c = tmp.Street__c != null ? tmp.Street__c.replace('<br>', '\n') : tmp.Street__c;
                            obj.Ship_to_City__c = tmp.City__c;
                            obj.Ship_to_State__c = tmp.State__c;
                            obj.Ship_to_Zip_Code__c = tmp.Zip_Code__c;
                            obj.Ship_to_Country__c = tmp.Country__c;
                            
                        }
                    }
                }
            }
    	}
    
    /** 
     * @description manage the date paid and status of a customer invoice or credit memo
     * KNDY-1889
     */ 
     
     // ZS: across all Invoice types: status should be open if balance != 0, status should be closed if balance is 0, for void and cancelled these conditions should not be evaluated. //AR-134
    public void setStatus()   
    {
        for(Customer_Invoice__c obj: (list<Customer_Invoice__c>)trigger.New) {
    		
    		if(trigger.isUpdate)
    		{
    			if((KSE.isFieldChanging('Balance__c', obj, trigger.oldMap)||(KSE.isFieldChanging('Finalized__c', obj, trigger.oldMap) && obj.Finalized__c))
    			  && obj.Balance__c  == 0 && obj.Status__c != STATUS_CANCEL && obj.Status__c != STATUS_VOID){
    				obj.Status__c = STATUS_CLOSED;
                	obj.Date_Time_Paid__c = System.now();//OTC-621
    			}
    			else if(KSE.isFieldChanging('Balance__c', obj, trigger.oldMap) && obj.Balance__c  != 0)
    			{
    				obj.Status__c = STATUS_OPEN;
               		obj.Date_Time_Paid__c = null;
    			}
    			else if(KSE.isFieldChanging('Status__c', obj, trigger.oldMap) && obj.Status__c != STATUS_CANCEL && obj.Status__c != STATUS_VOID && obj.Balance__c  != 0)
    			{
    				obj.Status__c = STATUS_OPEN;
               		obj.Date_Time_Paid__c = null;
    			}
    		}
    	}
    }
    
    /** 
     * @description review the incoming or changed invoice and set any exceptions
     * that should prevent accounting, called from the CustomerInvoice trigger
     */
    public static void setExceptions(List<Customer_Invoice__c> custInvs) {
        
        for( Customer_Invoice__c ci : custInvs){
            
            if (ci.Company__c == null)   {
                exService.setException(ci, ExceptionUtil.CI_MISSING_COMPANY);
            }else{
                exService.clearException(ci, ExceptionUtil.CI_MISSING_COMPANY);
            }
            
            if (ci.Bill_To_Customer__c == null && (ci.Invoice_Type__c != CM_PREPAYMENT && ci.Invoice_Type__c != CM_OVERPAYMENT && ci.Invoice_Type__c != TYPE_SETTLEMENT && ci.Invoice_Type__c != TYPE_CHARGEBACK)) { //Chargeback part of OTC-729 //TYPE_SETTLEMENT addition part of OTC-656
                exService.setException(ci, ExceptionUtil.CI_MISSING_BILLTO);
            }else{
                exService.clearException(ci, ExceptionUtil.CI_MISSING_BILLTO);
            }
        }
    }
    
    //Actions dropdown options depend on this method
    public static String populateCIActions(Id customerInvoiceId){ 
        
        Map<String,boolean> actionsMapOnCI = new Map<String,boolean>();
        SOQLUtil soql = new SOQLUtil('Customer_Invoice__c',true);
        soql.addFields(new set<string>{'Id', 'Total_Amount__c', 'Balance__c', 'Invoice_Type__c', 'Status__c', 'Finalized__c'});
        soql.setWhereClause('Id = :customerInvoiceId');
        
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
            childRel.addFields(new set<string>{'Id'});
        childRel.setWhereClause('Status__c = \'Active\' and Has_Exceptions__c = false');
        soql.addChildRelationship(childRel);
        system.debug(loggingLevel.error, 'query on populateCIActions-->' + soql.getQuery());  
        
        List<Customer_Invoice__c> invoiceSelected = Database.query(soql.getQuery());
        System.debug(logginglevel.error,'invoiceSelected-->'+invoiceSelected);
        for (Customer_Invoice__c invoice: invoiceSelected){
            //for (Accounting_Entries__c line: invoice.Accounting_Entries__r){}
            if(invoice.Status__c == 'Open'){
	           if(invoice.Finalized__c){ 
	               if(invoice.Invoice_Type__c == 'Manual'){ 
	                actionsMapOnCI.put('Clone',true);
	               }else{
	                  actionsMapOnCI.put('Clone',false);
	               }  
		            actionsMapOnCI.put('Write_Off',true);
		            actionsMapOnCI.put('Settle_Against_Claims',true);
		            if(invoice.Invoice_Type__c == 'Manual' && invoice.Balance__c == invoice.Total_Amount__c){
	                    actionsMapOnCI.put('Unfinalize',true);
	                }else{
	                    actionsMapOnCI.put('Unfinalize',false);
	                }
		            if(invoice.Accounting_Entries__r != null && invoice.Accounting_Entries__r.size() > 0 && invoice.Balance__c == invoice.Total_Amount__c){
		                actionsMapOnCI.put('Void',true);
		            }else{
		                actionsMapOnCI.put('Void',false);
		            }
		            if(invoice.Balance__c == invoice.Total_Amount__c){  
	                    actionsMapOnCI.put('Cancel',true);
	                }else{
	                    actionsMapOnCI.put('Cancel',false);
	                }
	                if(invoice.Balance__c < 0){
	                    actionsMapOnCI.put('Refund_Credit',true);
	                }else{
	                    actionsMapOnCI.put('Refund_Credit',false);
	                }
	                actionsMapOnCI.put('Get_Tax',false);
	           }else{
	                if(invoice.Invoice_Type__c == 'Manual'){ 
	                actionsMapOnCI.put('Clone',true);
                    }else{
                      actionsMapOnCI.put('Clone',false);
                    }
                    actionsMapOnCI.put('Write_Off',false);
                    actionsMapOnCI.put('Settle_Against_Claims',false);
                    actionsMapOnCI.put('Unfinalize',false);
                    actionsMapOnCI.put('Void',false);
                    actionsMapOnCI.put('Cancel',true);
                    actionsMapOnCI.put('Refund_Credit',false);
                    actionsMapOnCI.put('Get_Tax',true);
	           }
            }else if(invoice.Status__c == 'Closed' || invoice.Status__c == 'Cancelled' ||  invoice.Status__c == 'Void'){
                    if(invoice.Invoice_Type__c == 'Manual'){  
                    actionsMapOnCI.put('Clone',true);
                    }else{
                      actionsMapOnCI.put('Clone',false);
                    }
                    actionsMapOnCI.put('Write_Off',false);
                    actionsMapOnCI.put('Settle_Against_Claims',false);
                    actionsMapOnCI.put('Unfinalize',false);
                    actionsMapOnCI.put('Void',false);
                    actionsMapOnCI.put('Cancel',false);
                    actionsMapOnCI.put('Refund_Credit',false);
                    actionsMapOnCI.put('Get_Tax',false);
            }
        }        
      System.debug(logginglevel.error,'actionsMapOnCI--->'+actionsMapOnCI);  
      String actionMapStr = JSON.serialize(actionsMapOnCI);
      return actionMapStr; //actionsMapOnCI
    }
    
    //KNDY-735 RS - Need to handle "Credit and Rebill" Process - Entire Invoice
    public void creditEntireInvoice(List<Customer_Invoice__c> custInvoices){
        
        List<Customer_Invoice__c> insertRebillCustInvoices = new List<Customer_Invoice__c>();
        Map<Customer_Invoice__c, Decimal> mCustInvoices = new Map<Customer_Invoice__c, Decimal>();
        SOQLUtil soql = new SOQLUtil('Customer_Invoice_Line__c', TRUE);
        soql.addFields('Credit_Rebill_RO');
        soql.addFields(new Set<String>{'Id', 'Name' ,'sales_order_line__c' , 'product__c', 'product__r.item__c' ,
                                                        'quantity_shipped__c' , 'unit_price__c', 'extended_price__c', 'createdDate' , 
                                                        'customer_invoice__c', 'credited__c', 
                                                    'shipment__c', 'shipment__r.status__c', 'Off_Invoice_Rate__c', 'BillBack_Rate__c', 'discount_percent__c' });
        soql.setWhereClause('customer_invoice__c IN :custInvoices');
        List<Customer_Invoice_Line__c> sils = Database.Query(soql.getQuery());
        Map<Id, List<Customer_Invoice_Line__c>> mSILs = new Map<Id, List<Customer_Invoice_Line__c>>();
        for(Customer_Invoice_Line__c sil : sils){
            if(mSILs.containsKey(sil.customer_invoice__c)){
                mSILs.get(sil.customer_invoice__c).add(sil);
            }else{
                mSILs.put(sil.customer_invoice__c, new List<Customer_Invoice_Line__c>{sil});
            }
        }                                    
                                         
                             
        for(Customer_Invoice__c ci : custInvoices){
            ci.credited__c = true;
            ci.status__c = STATUS_CLOSED;
            //KNDY-1714 - Customer credit memo created during "credit and re-bill process" is not updating Balance Due field
            //if(ci.Credit_Memo_Amount_Applied__c == null){
            //    ci.Credit_Memo_Amount_Applied__c = 0;
            //}
            decimal amount = ci.balance__c == null ? 0 : ci.balance__c;
            //ci.Credit_Memo_Amount_Applied__c += amount;
            
            mCustInvoices.put(ci, ci.balance__c);
        }
        
        Map<Id,Customer_Invoice__c> mCreditMemos = generateCustomerInvoicesCreditMemo(mCustInvoices);
        DML.insertAsUser(mCreditMemos.values());
        
        List<Customer_Invoice_Line__c> creditMemoLines = new List<Customer_Invoice_Line__c>();
        for(Id custInvId : mSILs.keySet()){
        	decimal creditApplied = 0;
            if(mCreditMemos.containsKey(custInvId)){
                for(Customer_Invoice_Line__c sil : mSILs.get(custInvId)){
                    Customer_Invoice_Line__c cloneSIL = sil.clone(false, true, false, false);
                    cloneSIL.quantity_shipped__c = (-1)* cloneSIL.quantity_shipped__c;
                    cloneSIL.customer_invoice__c = mCreditMemos.get(custInvId).Id;
                    
                	creditApplied += cloneSIL.Extended_Price__c;
                    creditMemoLines.add(cloneSIL);
                }
                
                	//mCreditMemos.get(custInvId).Credit_Memo_Applied__c = creditApplied;
                	mCreditMemos.get(custInvId).Finalized__c = true;
            }
            
            
            
        }
        
        if(creditMemoLines.size() > 0){
            DML.insertAsUser(creditMemoLines);
        }
        
    	DML.updateAsUser(mCreditMemos.values());
        	
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		soql = new SOQLUtil('Accounting_Entry__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id'
		});
		soql.setWhereClause('customer_invoice__c IN :custInvoices');
		List<Accounting_Entry__c> acctEntries = Database.query(soql.getQuery());

        AccountingEntryService aes = AccountingEntryService.getInstance();
        aes.accountingEntryReverse(acctEntries, mCreditMemos);
        
        DML.updateAsUser(  custInvoices );
        
    }

    //KNDY-735 RS - Handle Customer Invoice Credit Memos - returns map of original invoice id and the new invoice credit memo
    public Map<Id,Customer_Invoice__c> generateCustomerInvoicesCreditMemo(Map<Customer_Invoice__c, Decimal> mCustInvoices){
        Map<Id,Customer_Invoice__c> creditMemos = new Map<Id,Customer_Invoice__c>();
        string custInvName = SchemaUtil.getInstance().getLocalNameFromObject(new Customer_Invoice__c());
        
        for(Customer_Invoice__c ci : mCustInvoices.keySet()){
            Customer_Invoice__c iCM = new Customer_Invoice__c();
            iCM.Company__c = ci.Company__c;
            iCM.currency__c = ci.currency__c;
            iCM.bill_to_customer__c = ci.bill_to_customer__c;
            iCM.Invoice_Type__c = CM_INVOICE;
            //iCM.Credit_Memo_Type__c = CM_INVOICE;
            iCM.Apply_to_Invoice__c = ci.Id;
            iCM.Date_Invoiced__c = system.now();
            iCM.status__c = STATUS_CLOSED;
            //iCM.Finalized__c = true;
            iCM.transaction_date__c = system.now();
            creditMemos.put(ci.Id, iCM);
        }
        return creditMemos;
    }

    //KNDY-1713 - Need to be able to edit the unit price or quantity during credit and rebill process
    public void rebillAdjustedInvoiceLines(set<Id> customerInvoiceIds, Map<Id, Customer_Invoice_Line__c> mShipInvoiceLines){
        
        Map<Id, Customer_Invoice__c> mRebillCustInvoices = new Map<Id, Customer_Invoice__c>();
        List<Customer_Invoice_Line__c> insertSILs = new List<Customer_Invoice_Line__c>();
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name','company__c','invoice_type__c','sales_order__c','sold_to_customer__c','bill_to_customer__c','status__c','customer_purchase_order__c',
			'currency__c','balance__c'
		});
		soql.setWhereClause('Id IN :customerInvoiceIds');
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Customer_Invoice_Lines__r');
		childRel.addFields(new set<string>{
			'Id','name','company__c','sales_order__c','sales_order_line__c','shipment__c','product__c','description__c',
			'weight__c','weight_uom__c','shipment_line__c','discount_percent__c','unit_price__c',
			'facility__c','location__c','quantity_shipped__c','customer_invoice__c','Off_Invoice_Rate__c','BillBack_Rate__c'
		});
		Set<Id> shipIds = mShipInvoiceLines.keySet();
		childRel.setWhereClause('Id IN :shipIds');
		soql.addChildRelationship(childRel);
		Map<Id, Customer_Invoice__c> mCustInvoices = new Map<Id, Customer_Invoice__c>((List<Customer_Invoice__c>)Database.query(soql.getQuery()));
                
        for(Customer_Invoice__c ci : mCustInvoices.values()){
            
            Customer_Invoice__c iCI = ci.clone(false, true, false, false);
            iCI.Date_Invoiced__c = system.now();
            iCI.Credited__c = false;
            iCI.Finalized__c = false;
            iCI.Credited_Invoice__c = ci.Id;
            iCI.Currency__c = ci.Currency__c;
            mRebillCustInvoices.put(ci.Id, iCI);
            
        }
        
        try{
            DML.insertAsUser( mRebillCustInvoices.values() );
            
            for(Customer_Invoice__c ci : mCustInvoices.values()){
                if(mRebillCustInvoices.containsKey(ci.Id)){
                    
                    for(Customer_Invoice_Line__c sil : ci.Customer_Invoice_Lines__r){
                        if(mShipInvoiceLines.containsKey(sil.Id)){
                        
                            Customer_Invoice_Line__c iSIL = mShipInvoiceLines.get(sil.Id);
                            iSIL.credited__c = false;
                            iSIL.Customer_Invoice__c = mRebillCustInvoices.get(ci.Id).Id;
                            insertSILs.add(iSIL);
                            
                        }
                    }
                }
            }
            
            if(insertSILs.size() > 0) {
                DML.insertAsUser( insertSILs );
            }
        }catch(Exception ex){
            throw new CustomerInvoiceException(ex.getMessage(), ex);
        }
        
    }

    /** 
     * @description run a sum of payment lines updating the Credit_Memo_Amount_Applied__c, 
     * Amount_Paid__c, Deduction_Amount__c, Write_Off_Amount__c, Discount_Taken__c
     * on a Customer Invoice
     * performs an update of the database, 
     * called from ApplyPaymentsBatch ,  AutoCashApplication, CustomerReceiptUnapply  
     */
    public static void sumInvoicePayments(list<Customer_Invoice__c> inputList){
        system.debug(logginglevel.error,'Inside the sumInvoicePayments');
        String baseFieldString = 'id, name, Amount_Paid__c, Write_off_Amount__c, Deduction_Amount__c, Amount_Applied__c, Currency__c,Total_Amount__c';
        Set<String> baseFieldPaths = new Set<String>(baseFieldString.split(','));

        String subQuery1FieldString = 'id, name, amount__c, type__c';
        Set<String> subQuery1FieldPaths = new Set<String>(subQuery1FieldString.split(','));

        String subQuery2FieldString = 'Id, name, amount__c, type__c';
        Set<String> subQuery2FieldPaths = new Set<String>(subQuery2FieldString.split(','));

        SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', TRUE);
        soql.addFields(baseFieldPaths);
        soql.setWhereClause('Id IN :inputList');

        SOQLUtil.ChildRelationship subQuery1 = new SOQLUtil.ChildRelationship(soql, 'Customer_Receipt_Lines__r');
        subQuery1.addFields(subQuery1FieldPaths);
        subQuery1.setWhereClause('Customer_Receipt__r.Finalized__c = true and Customer_Receipt__r.Void__c = false');

        /*KNDY-13995
        SOQLUtil.ChildRelationship subQuery2 = new SOQLUtil.ChildRelationship(soql, 'Customer_Credit_Memos_Applied__r');
        subQuery2.addFields(subQuery2FieldPaths);
        subQuery2.setWhereClause('Customer_Receipt__r.Finalized__c = true and Customer_Receipt__r.Void__c = false');*/

        soql.addChildRelationship(subQuery1);
        //soql.addChildRelationship(subQuery2); KNDY-13995

        List<Customer_Invoice__c> invoices = database.query(soql.getQuery());
        
        list<Customer_Invoice__c> ciList = new list<Customer_Invoice__c>();
        for(Customer_Invoice__c ci : invoices){
            // TODO Need to exclude receipts with exceptions on them ?
            
            decimal payment_sum = 0;
            decimal creditApplied_sum = 0;
            decimal debitApplied_sum = 0;
            decimal deduction_sum = 0;
            decimal writeoff_sum = 0;
            decimal discount_sum = 0;
            decimal earnedDiscount =0;
			system.debug('sumInvoicePayments Customer_Receipt_Lines__r=='+ci.Customer_Receipt_Lines__r);
            for(Customer_Receipt_Line__c p:ci.Customer_Receipt_Lines__r){ 
                // TODO Need to calculate earned and unearned based based on payment terms/discount taken
                
                if (p.Type__c == PaymentService.TYPE_REFUND_APPLIED_PREPAYMENT ||
                    p.Type__c == PaymentService.TYPE_REFUND_APPLIED_PAYMENT){ //KNDY-12536 KNDY-12895
                    //p.Amount__c will be negative, want to reduce ci amount paid
                    payment_sum +=  p.Amount__c;
                } 
                else if(p.Type__c == PaymentService.TYPE_PAYMENT){
                    payment_sum += p.Amount__c;          
                }else if(p.Type__c == PaymentService.TYPE_INVOICE_DEDUCTION){
                    deduction_sum += p.Amount__c;
                }else if(p.Type__c == PaymentService.TYPE_WRITEOFF){ //KNDY-13995 
                    writeoff_sum += p.Amount__c;
                }else if(p.Type__c == PaymentService.TYPE_EARNED_DISCOUNT || p.Type__c == PaymentService.TYPE_UNEARNED_DISCOUNT){
                    discount_sum += p.Amount__c;
                    if(p.Type__c == PaymentService.TYPE_EARNED_DISCOUNT )
                    	earnedDiscount += p.Amount__c;
                }//KNDY-13995
                else if(p.Type__c == PaymentService.TYPE_CREDIT_MEMO || p.Type__c == PaymentService.TYPE_PREPAYMENT_CREDIT || p.Type__c == PaymentService.TYPE_OVERPAYMENT_CREDIT || p.Type__c == PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED){//KNDY-15028
                    creditApplied_sum += p.Amount__c;
                }else if(p.Type__c == PaymentService.TYPE_DEBIT_MEMO || p.Type__c == PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT || p.Type__c == PaymentService.TYPE_REFUND_UNAPPLIED_OVERPREPAYMENT || p.Type__c == PaymentService.TYPE_REFUND_ALLOWANCE_ACCRUAL || p.Type__c == PaymentService.TYPE_REFUND_CREDIT){ //KNDY-12895, KNDY-15033
                	debitApplied_sum += p.Amount__c;

                }else if(p.Type__c == PaymentService.TYPE_WRITEOFF_CREDIT){ //KNDY-13995 KNDY-19379
                    writeoff_sum += -1 * p.Amount__c; //
                }//END KNDY-13995
                
                }
            
            /*KNDY-13995
            for(Customer_Receipt_Line__c p:ci.Customer_Credit_Memos_Applied__r){ 
                // TODO Need to calculate earned and unearned based based on payment terms/discount taken
                if(p.Type__c == PaymentService.TYPE_CREDIT_MEMO || p.Type__c == PaymentService.TYPE_PREPAYMENT_CREDIT || p.Type__c == PaymentService.TYPE_OVERPAYMENT_CREDIT || p.Type__c == PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED){//KNDY-15028
                    creditApplied_sum += p.Amount__c;
                }else if(p.Type__c == PaymentService.TYPE_DEBIT_MEMO || p.Type__c == PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT || p.Type__c == PaymentService.TYPE_REFUND_UNAPPLIED_OVERPREPAYMENT || p.Type__c == PaymentService.TYPE_REFUND_ALLOWANCE_ACCRUAL || p.Type__c == PaymentService.TYPE_REFUND_CREDIT){ //KNDY-12895, KNDY-15033
                	debitApplied_sum += p.Amount__c;
                }else if(p.Type__c == PaymentService.TYPE_WRITEOFF){
                    writeoff_sum += -1 * p.Amount__c; //
                }
            }*/
            
            ci.Amount_Paid__c = payment_sum;
            ci.Credit_Applied__c = creditApplied_sum;
            ci.Debit_Applied__c = debitApplied_sum;
            ci.Deduction_Amount__c = deduction_sum;
            ci.Write_Off_Amount__c = writeoff_sum;
            ci.Discount_Taken__c = discount_sum;
            ci.changed_flag__c = false;
            ci.Amount_Applied__c = 0;
            
            // TODO Handle concurrency challenges ?
            
            // TODO need to handle overpayments as a condition ?
            
            ciList.add(ci);
        }
        
        // DML.updateAsUser( ciList ); // FIN-346
        try
        {
        	DML.updateAsSystem(ciList);
        }catch(Exception ex)
        {
        	throw ex;
        }           
    }
    
    /*
    	Description: Create a zero dollar receipt and write off the balance of the specified invoice
    				Note:	This method creates one receipt per invoice, could be consolidated based on customer
	*/
	public void writeOffInvoices(List<Customer_Invoice__c> custInvs){
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Company__c','Balance__c','Bill_to_Customer__c','Currency__c','Total_Amount__c','Resolution_Code__c'
		});
		soql.setWhereClause('ID IN :custInvs AND Balance__c != 0'); //OTC-674 should be able to write off credit invoices as well
		List<Customer_Invoice__c> invoices = Database.query(soql.getQuery());
		
		system.debug('write off services: Invoices -> '+ invoices);										
		Map<Id, Customer_Receipt__c> mCustReceipts = new Map<Id, Customer_Receipt__c>();
		List<Customer_Receipt_Line__c> insertCustReceiptLines = new List<Customer_Receipt_Line__c>();
		
		for(Customer_Invoice__c ci : invoices){
			Customer_Receipt__c iCR = new Customer_Receipt__c();
			iCR.Company__c = ci.Company__c;
			iCR.Type__c = CustomerReceiptService.TYPE_RECEIPT;
			iCR.Currency__c = ci.Currency__c;
			iCR.Amount_Received__c = 0;
			iCR.Customer__c = ci.Bill_to_Customer__c;
			iCR.Transaction_Date__c = System.now();
			mCustReceipts.put(ci.Id, iCR);
		}
		system.debug('write off services: mCustReceipts -> '+ mCustReceipts.values() );
		Savepoint sp = Database.setSavepoint();
		try{
			DML.insertAsUser( mCustReceipts.values() );
			for(Customer_Invoice__c ci : invoices){
				if(mCustReceipts.containsKey(ci.Id)){
					Customer_Receipt_Line__c iCRL = new Customer_Receipt_Line__c();
					iCRL.Customer_Receipt__c = mCustReceipts.get(ci.Id).Id;
					iCRL.Customer_Invoice__c = ci.Id; //KNDY-13995
					if(ci.Total_Amount__c < 0) {
					 iCRL.Amount__c =  -1 * ci.Balance__c;
					 iCRL.Type__c = PaymentService.TYPE_WRITEOFF_CREDIT; //KNDY-19379
					}
				    else {
				     iCRL.Amount__c = ci.Balance__c;
				     iCRL.Type__c = PaymentService.TYPE_WRITEOFF;
				    }

				    iCRL.Reason_Code__c = ci.Resolution_Code__c;
                    System.debug(logginglevel.error,'iCRL--->'+iCRL.Reason_Code__c);
					insertCustReceiptLines.add(iCRL);
					
					//Update the invoice status and write off amount
					//ci.write_off_amount__c = ci.Balance__c;
					//ci.status__c = STATUS_CLOSED;
				}
			}
			
			DML.insertAsUser( insertCustReceiptLines );
			//DML.updateAsUser( invoices );
			for(Customer_Receipt__c cr : mCustReceipts.values()) //OTC-687
			{
				cr.Finalized__c = true;
				cr.Finalized_Date__c = system.now();
			}
			DML.updateAsUser(mCustReceipts.values());
		}catch(Exception ex){
			database.rollback(sp);
			throw ex;
		}
	}
	
	
	//AR-3 calculate payment due date, depends on the type of payment term
	//on insert calculate if both invoiced date and payment term is populated
	//on update if either one is changed
	// you can check the google sheet linked to the jira number. 
	public static void setPaymentDueDate() {
		list<Customer_Invoice__c> lCIs = new list<Customer_Invoice__c>();
		set<Id> sPaymentTerms = new set<id>();
		for(Customer_Invoice__c ci : (list<Customer_Invoice__c>)trigger.new)
		{
			if(trigger.isBefore)
			{
				if((trigger.isInsert && ci.Date_Invoiced__c != null && ci.Payment_Term__c!= null) || 
					(trigger.isUpdate && (KSE.isFieldChanging('Date_Invoiced__c',ci,trigger.oldmap) || KSE.isFieldChanging('Payment_Term__c',ci,trigger.oldmap) )))
				{
					lCIs.add(ci);
					sPaymentTerms.add(ci.Payment_Term__c);
				}
			}
			
			
		}
		system.debug('sPaymentTerms '+sPaymentTerms);
		if(!sPaymentTerms.isEmpty())
		{
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Payment_Term__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Type__c','Due_Days__c','Day_of_month__c','Cut_off_Day__c','Months_Ahead__c'
			});
			soql.setWhereClause('id in :sPaymentTerms');
			map<Id,Payment_Term__c> mPaymentTerms = new map<id,Payment_Term__c> ((List<Payment_Term__c>)Database.query(soql.getQuery()));

			system.debug('mPaymentTerms '+mPaymentTerms);
			for(Customer_Invoice__c ci : lCIs)
			{
				if(mPaymentTerms.containsKey(ci.Payment_Term__c))
				{
					try{	
						ci.Due_Date__c = KSE.getDueDate (ci.Date_Invoiced__c, mPaymentTerms.get(ci.Payment_Term__c));
					}catch (Exception ex){ //KNDY-11659 KNDY-11688
						if (ex.getMessage() ==  Label.Payment_Term_Type_is_blank){
							ci.addError(Label.Please_enter_Type_on_associated_Payment_Term);
						}
						else{
							ci.addError(ex.getMessage());
						}
					}
				}
			}
		}
		
	}
	
	public static boolean preventMultipleExecutions = false;
	public static void updatePrepaymentReceivedOnSO() { 
		
		if(trigger.isUpdate && trigger.isAfter && !preventMultipleExecutions) {
			set<Id> sSOIds = new set<Id>();
			for(Customer_Invoice__c ci : (list<Customer_Invoice__c>) trigger.new) {
				system.debug('ci '+ci);
				if(ci.Invoice_Type__c == CM_PREPAYMENT) {
					
					if(KSE.isFieldChanging('Finalized__c',ci,trigger.oldmap) || KSE.isFieldChanging('Sales_Order__c',ci,trigger.oldmap) || (KSE.isFieldChanging('Status__c',ci,trigger.oldmap) && (ci.Status__c == 'Void' || ci.Status__c == 'Cancelled')))
					{
						if(ci.Sales_Order__c != null)
						sSOIds.add(ci.Sales_Order__c);
						if((Id)trigger.oldmap.get(ci.Id).get('Sales_Order__c') != null)
						sSOIds.add((Id)trigger.oldmap.get(ci.Id).get('Sales_Order__c'));

					}
					
				}
				
			}
			system.debug('so '+sSOIds);
			if(!sSOIds.isEmpty()) {
				preventMultipleExecutions = true;
				map<Id, Sales_Order__c> mSOs = new map<Id,Sales_Order__c>();
				for(Id soId : sSOIds) {
					mSOs.put(soId, new Sales_Order__c(Id = soId, Prepayments_Received__c = 0));
				}
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true, true); //enforceFLS=true, running in user mode.  is aggregate query = true
				soql.addFields(new set<string>{
					'Sum(Total_Amount__c) invoiceBalance','Sales_Order__c orderId'
				});
				soql.setWhereClause('Invoice_Type__c = \'Prepayment\' and Finalized__c = true and Status__c in (\'Open\',\'Closed\') and Sales_Order__c in :sSOIds Group By Sales_Order__c');
				for(AggregateResult ag : Database.query(soql.getQuery())) {

					system.debug('ag '+ag);
					if(mSOs.containsKey((Id)ag.get('orderId')))
						mSOs.put((Id)ag.get('orderId'), new Sales_Order__c(Id = (Id)ag.get('orderId'), Prepayments_Received__c = Math.abs((Decimal)ag.get('invoiceBalance'))));					 	
				}
				
				if(!mSOs.isEmpty()) 
					DML.updateAsSystem(mSOs.values());
			}
			
		}
		
	}
	
	public static void checkIfQuantityShippedIsZero() {
		
		if(trigger.isUpdate && trigger.isBefore) {
			
			set<ID> sCIs = new set<Id>();
			for(Customer_Invoice__c ci : (list<Customer_Invoice__c>) trigger.new) {
				if(KSE.isFieldChanging('Finalized__c',ci,trigger.oldMap) && ci.Finalized__c ) 
					sCIs.add(ci.Id);
			}
			
			if(!sCIs.isEmpty()) {
				SOQLUtil soql = new SOQLUtil('Customer_Invoice_Line__c', false); //enforceFLS=false, running in system mode
				soql.addFields(new set<string>{
					'id','Customer_Invoice__c'
				});
				soql.setWhereClause('Customer_Invoice__c in : sCIs and (Quantity_Shipped__c = 0.00 or Quantity_Shipped__c = null)');
				
				system.debug(logginglevel.error,'Database.query(soql.getQuery()) '+Database.query(soql.getQuery()));
				for(Customer_Invoice_Line__c cil : Database.query(soql.getQuery())) {
					trigger.newMap.get(cil.Customer_Invoice__c).addError(Label.Quantity_fulfilled_cannot_be_zero);
				}
			}
			
		}
	}
	
    	
}