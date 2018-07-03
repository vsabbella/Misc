global class TaxService {

	global class TaxServiceException extends Exception{}

	global interface ITaxAction{

		List<FieldInfo> getDisplayFieldSet(Schema.sObjectType objectType);
		List<TaxResult> getTaxes(List<Id>ids);
		List<TaxResult> voidTaxes(List<Id>ids); 

	}

	global class TaxResult{

		global SObject obj{get;set;}
		global Boolean isSuccess{get;set;}
		global String message{get;set;}
	}


	private static TaxService instance = null;
	private ITaxAction taxAction = null;
	private Set<String> taxableObjects = null;
 
	//----Blacklist as per KNDY-16286---//
	Map<String,Set<String>> mapTaxBlckListedInvTyp = new Map<String,Set<String>>();
	static Set<String> taxBlackListedInvoiceTypesForCI = new Set<String>{'Overpayment','Prepayment', 'Allowance Accrual',
	                                                                'Chargeback','Settlement'};
	static Set<String> taxBlackListedInvoiceTypesForSO = new Set<String>{'RMA-Replacement','Resale'};
    static Set<String> taxBlackListedInvoiceTypesForSI = new Set<String>{'Prepayment'};  

	private Set<Id> configCompany = null;

	private TaxService(){
		Process__c p = Process__c.getAll().get('TaxService');
		mapTaxBlckListedInvTyp.put('Customer_Invoice__c',taxBlackListedInvoiceTypesForCI); 
        mapTaxBlckListedInvTyp.put('Supplier_Invoice__c',taxBlackListedInvoiceTypesForSI);
	    mapTaxBlckListedInvTyp.put('Sales_Order__c'     ,taxBlackListedInvoiceTypesForSO);
	

		if(p!= null && p.Active__c == true){
			Type t = Type.forName(p.Namespace__c, p.Object_Step__c);
			if(t != null){
				taxAction= (ITaxAction)t.newInstance();
				system.debug('taxAction'+taxAction);//DefaultSalesTax
			}

			if(String.isNotEmpty(p.Object__c)){
				taxableObjects = new Set<String>();
				for(String s : p.Object__c.split(',')){
					taxableObjects.add(s.trim().toLowercase());
		}
				//taxableObjects = SchemaUtil.getInstance().removeNSfromSetString(taxableObjects);
			}

			if(String.isNotEmpty(p.State__c)){
				List<String> cId = new List<String>();

				for(String s : p.State__c.split(',')){
					cId.add(s.trim());
	}

				SoqlUtil soql = new SoqlUtil('Company__c');
				soql.addFields(new Set<String>{'Id'});
				soql.setWhereclause('Id in:cId');

				List<Company__c> companies = Database.query(soql.getQuery());

				if(companies.size() > 0){
					configCompany = new Set<Id>();
					for(Company__c c : companies){
						System.debug(LoggingLevel.ERROR, '#### Com Id: ' + c.Id);
						configCompany.add(c.Id);
					}
				}
				System.debug(LoggingLevel.ERROR, '#### avail companies' + configCompany);
			}
		}
	}

	public static TaxService getInstance(){
		if(instance == null){
			instance = new TaxService();
		}
		return instance;
	}

	public Boolean HasTaxService{get{return taxAction != null;}}

	public Boolean taxServiceConfigured(SObject sd){
		 
		return taxServiceConfigured('otc',sd);
	}

	public Boolean taxServiceConfigured(String sobj,SObject sd){
	   
	    String sdName = sd.getsObjectType().getDescribe().getLocalName();
	    ID CompanyId ;
	    String InvType ='';
	     
	     if(sdName.contains('Customer_Invoice__c')){
	        Customer_Invoice__c ciInContext =  (Customer_Invoice__c)sd;
	        InvType                         = ciInContext.Invoice_Type__c;
	        CompanyId                       = ciInContext.Company__C;
	     }else if(sdName.contains('Supplier_Invoice__c')){
	        Supplier_Invoice__c siInContext =  (Supplier_Invoice__c)sd;
	        InvType                         = siInContext.Invoice_Type__c;
	        CompanyId                       = siInContext.Company__C; 
	     }else if(sdName.contains('Sales_Order__c')){
	        Sales_Order__c soInContext      =  (Sales_Order__c)sd;
	        InvType                         = soInContext.Type__c;
	        CompanyId                       = soInContext.Company__C; 
	     }
	    
	   
	    if(taxBlackListedInvoiceTypesForCI.contains(InvType) 
    	                                                     ||taxBlackListedInvoiceTypesForSO.contains(InvType) 
	                                                         ||taxBlackListedInvoiceTypesForSI.contains(InvType)){
	       return false;
	        
	    }
	
		if(sobj == Supplier_Invoice__c.getSobjectType().getDescribe().getLocalName() 
		                || sobj == Purchase_Order__c.getSobjectType().getDescribe().getLocalName()){
			sobj = 'ptp';
		}

		if(HasTaxService == false){
			//no configuration
			return false;
		}else if(sobj != null && taxableObjects != null && taxableObjects.size() > 0 && taxableObjects.contains(sobj) == false){
			//optional objects not configured
			return false;
		}else if(configCompany != null && configCompany.size() > 0 && configCompany.contains(CompanyId) == false && CompanyId!=null ){
			//not the correct company
			return false;
		}else{
			return true;
		}
	}

	public TaxResult getTax(Id id){
		return getTax(new List<Id>{id}).get(0);
	}

	public List<TaxResult> getTax(List<Id> ids){

		if(HasTaxService == false){
			throw new TaxServiceException('Tax Service not implemented.');
		}
		List<TaxResult>results = taxAction.getTaxes(ids);
		
		system.debug('results'+results);

		if(results == null){
			results = new List<TaxResult>();
			TaxResult tr = new TaxResult();
			tr.isSuccess = false;
			tr.message = 'Tax Service not implemented for this document.';
			results.add(tr);
		}
		return results;
	}

	public List<FieldInfo> getDisplayFieldSet(Schema.sObjectType objectType){
		if(HasTaxService == false){
			throw new TaxServiceException('Tax Service not implemented.');
		}
		return taxAction.getDisplayFieldSet(objectType);
	}

	public List<TaxResult> voidTaxes(List<SObject>objs){
		List<Id>ids = new List<Id>();

		for(SObject o : objs){
			ids.add(o.Id);
		}
		return voidTaxes(ids);
	}

	public List<TaxResult> voidTaxes(List<Id> ids){
		if(HasTaxService == false){
			throw new TaxServiceException('Tax Service not implemented.');
		}
		return taxAction.voidTaxes(ids);
	}

	public BatchInjector getInvoicingBatch(){
		if(HasTaxService == false){
			throw new TaxServiceException('Tax Service not implemented.');
		}

		Process__c p = new Process__c();
		p.Sequence__c = 0;
		p.Namespace__c = '';
		p.Object_Step__c = 'TaxService.CustomerInvoiceTaxBatch';
		p.State__c = '50';
		
		return BatchInjector.getNextBatch(p);
	}

	public class CustomerInvoiceTaxBatch implements ICustomAction{
		@TestVisible private integer count;
		public List<Object> executeAction(List<SObject> scope){
			count = 0;
			List<Notify.Message>             messages = new List<Notify.Message>();
			TaxService                             ts = TaxService.getInstance();
			Map<Id, List<Id>>       companyInvoicemap = new Map<Id, List<Id>>();

	        try{
	        	//String soql = 'Select Id, Company__c,Invoice_Type__c From Customer_Invoice__c Where Id in:scope';
	        	String soql = 'Select Id, Company__c,Invoice_Type__c From Customer_Invoice__c Where Id in:scope AND Invoice_Type__c NOT IN :taxBlackListedInvoiceTypesForCI';
	        	List<Customer_Invoice__c>cis = Database.query(soql);
	         	
	        	for(Customer_Invoice__c ci : cis){
	        		 if ( ts.taxServiceConfigured(ci) == true ){
						 if(companyInvoicemap.containsKey(ci.Company__c) == false){
							 companyInvoicemap.put(ci.Company__c, new List<Id>());
						 }
						 companyInvoicemap.get(ci.Company__c).add(ci.Id);
                  	 }
	        	}
				for(list<Id> sCIs : companyInvoicemap.values()) {
					List<TaxService.TaxResult> results = TaxService.getInstance().getTax(sCIs);
					count++;
					for(TaxService.TaxResult r : results){
						if(r.isSuccess == false){
							messages.add(new Notify.Message(r.obj.Id, r.message));
						}
					}
				}


        	   
	        }catch(Exception ex){
	            messages.add(new Notify.Message(ex.getMessage(), ex.getStackTraceString()));
	        }

	        return messages;
		}
	}

}