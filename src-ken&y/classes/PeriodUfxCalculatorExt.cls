public with sharing class PeriodUfxCalculatorExt {

    public static String NameSpaceUU{get{return KSE.NamespaceUU;}set;} 
    
	public Id UfxAccountId{get;set;}
	public Id RfxAccountId{get;set;}
	public Boolean HasBeginingExchangeRate{get;private set;}
	public Boolean HasEndExchangeRate{get;private set;}
	public Boolean HasGlAccounts{get;private set;}
	public string HelpURL{get;set;}
	//added by Sohini -- KNDY-14994 Start
 
	public Boolean ufxPanel{get;set;}
	public Id period;
	
    public Integer ChunkSize{get;set;}
    public Integer JELInsert{get;set;}
    
    public List<JournalEntryWrapper> journalEntries{get;private set;}
	public Boolean canCreateJEs{get;private set;}
 		
 	public void ufxButton()
     {	
       ufxPanel = false;
     }
    
 //added by Sohini -- KNDY-14994 End

	public PeriodUfxCalculatorExt(ApexPages.StandardController controller) {

		SOQLUtil soql;

		period = controller.getId();

		soql = new SOQLUtil('Period__c');
		soql.addFields(new Set<String>{'Id', 'Period_Start__c', 'Period_End__c', 'GL_Close__c'});
		soql.setWhereClause('Id=:period');

		Period__c p = Database.query(soql.getQuery());

		//Period__c p = [Select Id, Period_Start__c, Period_End__c From Period__c Where Id=:period];

		DateTime pStart = p.Period_Start__c;
		DateTime pEnd = p.Period_End__c;
		
		//added by Sohini -- KNDY-14994 Start
 
		ufxPanel = true;
		//added by Sohini -- KNDY-14994 End

		soql = new SOQLUtil('Exchange_Rate__c');
		soql.addFields(new Set<String>{'Id','Rate_Start_DateTime__c', 'Rate_End_DateTime__c'});
		soql.setWhereClause('Daily_Monthly__c = \'Daily\' and ((Rate_Start_DateTime__c <=:pEnd and ( Rate_End_DateTime__c >=:pEnd or Rate_End_DateTime__c = null ) ) or ' +
							'(Rate_Start_DateTime__c <=:pStart and (Rate_End_DateTime__c >=:pStart or Rate_End_DateTime__c = null) ))');

		List<Exchange_Rate__c> startEnd = Database.query(soql.getQuery());

		/*List<Exchange_Rate__c>startEnd = [Select Id,Rate_Start_DateTime__c, Rate_End_DateTime__c
											From Exchange_Rate__c 
											Where (Rate_Start_DateTime__c <=:p.Period_End__c and Rate_End_DateTime__c >=:p.Period_End__c) or
											(Rate_Start_DateTime__c <=:p.Period_Start__c and Rate_End_DateTime__c >=:p.Period_Start__c)];*/

		HasBeginingExchangeRate = false;
		HasEndExchangeRate = true;

		for(Exchange_Rate__c er : startEnd){
			System.debug(LoggingLevel.ERROR, er.Rate_Start_DateTime__c + '\t' + p.Period_Start__c + '\t' + er.Rate_End_DateTime__c);
			if(er.Rate_Start_DateTime__c <= p.Period_Start__c && (er.Rate_End_DateTime__c == null || er.Rate_End_DateTime__c >= p.Period_Start__c) ){
				HasBeginingExchangeRate = true;
			}
			if(er.Rate_Start_DateTime__c <= p.Period_End__c && (er.Rate_End_DateTime__c == null ||er.Rate_End_DateTime__c >= p.Period_End__c) ){
				//HasEndExchangeRate = true;
			}
		}

		try{
			soql = new SOQLUtil('GL_Account__c');
			soql.addFields(new Set<String>{'Id'});
			soql.setWhereClause('FX_Type__c=\'UFX\'');
			soql.setLimit(1);
			UfxAccountId = ((GL_Account__c)Database.query(soql.getQuery())).Id;
			//UfxAccountId = [Select Id From GL_Account__c Where FX_Type__c='UFX' limit 1].Id;
			HasGlAccounts = true;
		}catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'UFX or RFX GL Account is missing.'));
			HasGlAccounts = false;
		}
		HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpPeriodufxCalculator'; 
        
        JELInsert = getValue(Configuration__c.getAll().get('UfxJELInsert'), 200);
        ChunkSize = getValue(Configuration__c.getAll().get('UfxChunk'), 5000);

		List<Journal_Entry__c>jes = getJournalsForVoid(period);
		VoidCancelService voidCancelSvc = new JournalEntryVoidCancelService(jes);

		Set<String> reasons = new Set<String>();
		journalEntries = new List<JournalEntryWrapper>();
		canCreateJEs = p.GL_Close__c != null ? false : true;

		if(canCreateJEs == false){
			reasons.add(label.UFX_Journal_Entry_cannot_be_created_in_a_closed_period);
		}

		for(Journal_Entry__c j : jes){
			VoidCancelService.VoidCancelDetail d = voidCancelSvc.getVoidCancelDetails().get(j.Id);

			if(d.isCancellable == false){
				canCreateJEs = false;
				for(String s : d.cancelMessages){
					if(s != null){
						reasons.add(s);
					}
				}
			}
			journalEntries.add(new JournalEntryWrapper(j, d));
		}

		if(HasBeginingExchangeRate == false){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, label.UFX_There_is_no_exchange_rate_for_the_beginning_of_the_period));
		}

		if(HasEndExchangeRate == false){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, label.UFX_There_is_no_exchange_rate_for_the_end_of_the_period));
		}

		if(HasBeginingExchangeRate == true && HasEndExchangeRate == true){
			if(canCreateJEs == false && reasons.size() > 0){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, label.UFX_Journal_Entries_will_not_be_created));
				for(String r : reasons){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, r));
				}
			}
		}
	}

	private static List<Journal_Entry__c> getJournalsForVoid(Id pId){
		//get existing JEs
		SOQLUtil soql = new SOQLUtil('Journal_Entry__c');
		soql.addFields(new Set<String>{'Id', 'Name', 'Transaction_Date__c', 'Finalized_Date__c', 'Posting_Date__c', 'Status__c', 'Finalized__c', 'Void__c' });
		soql.setWhereClause('(description__c = \'UFX\' OR type__c = \'UFX\') and Status__c = \'Closed\' and period__r.Id =:pId');
		return Database.query(soql.getQuery());
	}


    private Integer getValue(Configuration__c c, Integer defaultVal){
        Integer value = defaultVal;
        if(c != null && String.isNotEmpty(c.Value__c)){
            try{
                value = Integer.valueOf(c.Value__c);
            }catch(Exception ex){
                value = defaultVal;
            }
        }
        return value;
    }

	private static final Set<String> Required_Columns = new Set<String>{'Id', 'Amount_CR__c', 'Amount_DR__c', 'GL_Account__r.GL_Account_Unique__c', 'GL_Account__c',
						'COMP_Transaction_Currency_Amount_CR__c', 'COMP_Transaction_Currency_Amount_DR__c',
						'COMP_Functional_Currency_Amount_CR__c', 'COMP_Functional_Currency_Amount_DR__c',
						'COMP_Functional_Currency__c', 'COMP_Transaction_Currency__c', 'COMP_Functional_Conversion_Rate__c'};


	private static map<String, Decimal>exRatesmap;

	private static void initExchangeRates(DateTime d){

		SOQLUtil soql = new SOQLUtil('Exchange_Rate__c');
		soql.addFields(new Set<String>{'Id','Multiplier_Exchange_Rate__c', 'From_Currency__r.ISO_Code__c','To_Currency__r.ISO_Code__c'});
		soql.setWhereClause('Daily_Monthly__c = \'Daily\' and Rate_Start_DateTime__c <: d and (Rate_End_DateTime__c = null or Rate_End_DateTime__c >=: d)');

		List<Exchange_Rate__c>rates = Database.query(soql.getQuery());		

		/*List<Exchange_Rate__c>rates = [Select Id,Multiplier_Exchange_Rate__c, Currency_From__c,Currency_To__c 
										From Exchange_Rate__c 
										Where Rate_Start_DateTime__c <=: d and Rate_End_DateTime__c >=: d];*/
		exRatesmap = new map<String, Decimal>();
		for(Exchange_Rate__c r : rates){
			String k = (r.From_Currency__r.ISO_Code__c + r.To_Currency__r.ISO_Code__c).toLowercase();
			exRatesmap.put(k, r.Multiplier_Exchange_Rate__c);
		}

		System.debug(LoggingLevel.INFO, '#### Rate map: ' + exRatesmap);

	}

	@readonly
	@RemoteAction
	public static List<AEResults> getEntriesForUfx(Map<String, String> idRange, Id pId, Boolean isLast){
		
		SOQLUtil soql = new SOQLUtil('Period__c');
		soql.addFields(new Set<String>{'Id', 'Company__c', 'Period_End__c'});
		soql.setWhereClause('Id=:pId');
		Period__c p = Database.query(soql.getQuery());

		String lastClause = 'AND Id < \''+ idRange.get('last') +'\'  ';
		if (isLast) {
			lastClause = 'AND Id <= \''+ idRange.get('last') +'\'  ';	
		}

		soql = new SOQLUtil('Accounting_Entry_Line__c');
		soql.addFields(Required_Columns);

		//AR fields
		soql.addFields(new Set<String>{'Customer_Receipt_Line__c', 'Customer_Receipt_Line__r.Customer_Invoice__c',
							'Customer_Invoice_Line__r.Customer_Invoice__c', 'Customer_Receipt_Line__r.Customer_Invoice__r.Id', 'Customer_Receipt_Line__r.Customer_Invoice__r.Name',
							'Customer_Receipt_Line__r.Customer_Invoice__r.Company__c', 'Customer_Receipt_Line__r.Customer_Invoice__r.Company__r.Name', 'Customer_Invoice_Line__r.Customer_Invoice__r.Id','Customer_Invoice_Line__r.Customer_Invoice__r.Name',
							'Customer_Invoice_Line__r.Customer_Invoice__r.Company__c', 'Customer_Invoice_Line__r.Customer_Invoice__r.Company__r.Name'});
		//AP Fields
		soql.addFields(new Set<String>{'Supplier_Payment_Line__c', 'Supplier_Payment_Line__r.Supplier_Invoice__c', 'Supplier_Invoice_Line__r.Supplier_Invoice__c',
						'Supplier_Payment_Line__r.Supplier_Invoice__r.Id','Supplier_Payment_Line__r.Supplier_Invoice__r.Name', 'Supplier_Payment_Line__r.Supplier_Invoice__r.Company__c','Supplier_Payment_Line__r.Supplier_Invoice__r.Company__r.Name',
						'Supplier_Invoice_Line__r.Supplier_Invoice__r.Id','Supplier_Invoice_Line__r.Supplier_Invoice__r.Name', 'Supplier_Invoice_Line__r.Supplier_Invoice__r.Company__c', 'Supplier_Invoice_Line__r.Supplier_Invoice__r.Company__r.Name'});

		//GRNI fields
		soql.addFields(new Set<String>{'Supplier_Invoice_Line__r.Purchase_Order__c','Supplier_Invoice_Line__r.Purchase_Order__r.Id','Supplier_Invoice_Line__r.Purchase_Order__r.Name', 'Supplier_Invoice_Line__r.Purchase_Order__r.Company__c', 'Supplier_Invoice_Line__r.Purchase_Order__r.Company__r.Name',
						'Receipt_Line__r.Purchase_Order__c', 'Supplier_Invoice_Line__c','Receipt_Line__r.Purchase_Order__r.Id','Receipt_Line__r.Purchase_Order__r.Name', 'Receipt_Line__r.Purchase_Order__r.Company__c','Receipt_Line__r.Purchase_Order__r.Company__r.Name'});

		//Journal entries
		soql.addFields(new Set<String>{
			'Journal_Entry_Line__c', 'Journal_Entry_Line__r.Journal_Entry__c', 'Journal_Entry_Line__r.Journal_Entry__r.Company__c', 
			'Journal_Entry_Line__r.Journal_Entry__r.Company__r.Name', 'Journal_Entry_Line__r.Journal_Entry__r.Name', 'Journal_Entry_Line__r.Journal_Entry__r.Id'
		});

		soql.setWhereClause(
			'Id >= \'' + idRange.get('first') + '\' ' + lastClause + ' and Company__c =:compId and GL_Account__r.FX_Type__c = \'Monetary Non-cash\' and ' +
						'Status__c = \'Active\' and Accounting_Entry__r.Transaction_Date__c <: pend ' +
			' and (' +
				'(Customer_Invoice_Line__c != null and (Customer_Invoice_Line__r.Customer_Invoice__r.Status__c != \'Void\' or Customer_Invoice_Line__r.Customer_Invoice__r.Void_Date__c >:pend) ) or ' +
				'(Customer_Receipt_Line__c != null and (Customer_Receipt_Line__r.Customer_Receipt__r.Status__c != \'Void\' or Customer_Receipt_Line__r.Customer_Receipt__r.Void_Date__c >:pend) ) or ' +
				'(Supplier_Invoice_Line__c != null and (Supplier_Invoice_Line__r.Supplier_Invoice__r.Status__c != \'Void\' or Supplier_Invoice_Line__r.Supplier_Invoice__r.Void_Date__c >:pend) ) or ' +
				'(Supplier_Payment_Line__c != null and (Supplier_Payment_Line__r.Supplier_Payment__r.Status__c != \'Void\' or Supplier_Payment_Line__r.Supplier_Payment__r.Void_Date__c >:pend) ) or ' +
				'(Receipt_Line__r.Purchase_Order__c != null and ( Receipt_Line__r.Receiving_Document__r.Status__c != \'Void\' or Receipt_Line__r.Receiving_Document__r.Void_Date__c >:pend ) ) or ' +
				'(Journal_Entry_Line__c != null and (Journal_Entry_Line__r.Journal_Entry__r.Status__c != \'Void\' or Journal_Entry_Line__r.Journal_Entry__r.Void_Date__c >:pend) )' +
			')'
		);

		Datetime pend = p.Period_End__c;
		Id compId = p.Company__c;

		initExchangeRates(p.Period_End__c);

		System.debug(LoggingLevel.ERROR, '#### query: ' + soql.getQuery());

		List<Accounting_Entry_Line__c>aels = (List<Accounting_Entry_Line__c>)Database.query(soql.getQuery());

		map<String, AEResults> aelAggr = new map<String, AEResults>();

		for(Accounting_Entry_Line__c ael : aels){

			if(ael.COMP_Functional_Currency__c != ael.COMP_Transaction_Currency__c){
				map<string,string> objRef = null;
				System.debug(LoggingLevel.ERROR, '#### AEL: ' + JSON.serialize(ael));
				for(String oref : OBJECT_REFS.keyset()){
					System.debug(LoggingLevel.ERROR, '#### Checking: ' + oref);
					if(ael.get(oref) != null){
						objRef = OBJECT_REFS.get(oref);
						System.debug(LoggingLevel.ERROR, '#### found');
						break;
					}
				}

				Sobject so = null;
				Sobject so2 = null;
				System.debug(LoggingLevel.ERROR, '#### objref: ' + objRef);
				if(objRef.get('line').equalsIgnoreCase('Customer_Receipt_Line__r')){
					so = ael.getSobject(objRef.get('line')).getSobject(objRef.get('header')+'__r');
				}else{
					so = ael.getSobject(objRef.get('line')).getSobject(objRef.get('header')+'__r');
				}

				System.debug(LoggingLevel.ERROR, '#### Header 2: ' + objRef.get('header2'));
				System.debug(LoggingLevel.ERROR, '#### Header 2: ' + objRef.get('header2'));

				if(objRef.get('header2') != null && SchemaUtil.getInstance().fieldExists( objRef.get('linename'), objRef.get('header2') +'__c')){
					so2 = ael.getSobject(objRef.get('line')).getSobject(objRef.get('header2')+'__r');
				}

				System.debug(LoggingLevel.ERROR, '#### Has sObj2? ' + String.valueOf(so2 != null));

				String siId = (String)so.get('Id') + ael.GL_Account__c;

				if(aelAggr.containsKey(siId)==false){
					Decimal revalRate = exRatesmap.get((ael.COMP_Transaction_Currency__c+ael.COMP_Functional_Currency__c).toLowercase());
					aelAggr.put(siId, new AEResults(so, so2, ael.COMP_Functional_Conversion_Rate__c, ael.GL_Account__r.GL_Account_Unique__c, ael.GL_Account__c, revalRate, '', ael.COMP_Transaction_Currency__c));
				}
				aelAggr.get(siId).addAccountingEntryLine(ael);
			}
		}
		return aelAggr.values();
	}

	private static final map<String,map<String,String>> OBJECT_REFS = new map<String,map<String,String>>{
			'Customer_Invoice_Line__c'	=> new map<String,String>{ 'line' => 'Customer_Invoice_Line__r', 	'header' => 'Customer_Invoice'},
			'Customer_Receipt_Line__c'	=> new map<String,String>{ 'line' => 'Customer_Receipt_Line__r', 	'header' => 'Customer_Invoice'},
			'Supplier_Invoice_Line__c'	=> new map<String,String>{ 'line' => 'Supplier_Invoice_Line__r',	'header' => 'Supplier_Invoice', 'header2' => 'Purchase_Order', 'linename' => 'Supplier_Invoice_Line__c'},
			'Supplier_Payment_Line__c'	=> new map<String,String>{ 'line' => 'Supplier_Payment_Line__r', 	'header' => 'Supplier_Invoice'},
			'Receipt_Line__c'			=> new map<String,String>{ 'line' => 'Receipt_Line__r',				'header' => 'Purchase_Order'},
			'Journal_Entry_Line__c'		=> new map<String,String>{ 'line' => 'Journal_Entry_Line__r', 		'header' =>'Journal_Entry'}
	};

	@RemoteAction
	public static List<Journal_Entry__c> createJournalEntryHeader(List<String>compIds, Id pID, String type){

		SOQLUtil soql = new SOQLUtil('Period__c');
		soql.addFields(new Set<String>{'Id', 'Period_End__c', 'Period_Start__c'});
		soql.setWhereClause('Id=:pId');
		Period__c p = Database.query(soql.getQuery());

		List<Journal_Entry__c>voidEntries = getJournalsForVoid(pId);

		VoidCancelService voidCancelSvc = new JournalEntryVoidCancelService(voidEntries);
		voidCancelSvc.cancelSourceDocuments(voidEntries);

		if(compIds != null && compIds.size() > 0){
		soql = new SOQLUtil('Company__c');
		soql.addFields(new Set<String>{'Id', 'Comp_Currency__c'});
		
		soql.setWhereClause('Id in:compIds');
		List<Company__c> temp = Database.query(soql.getQuery());

		map<Id, Company__c> companies = new Map<Id,Company__c>();
		for(Company__c c : temp){
			companies.put(c.Id, c);
		}

		List<Journal_Entry__c> jes = new List<Journal_Entry__c>();

		for(String c : compIds){
			Journal_Entry__c je = new Journal_Entry__c();
			je.Company__c = c;
			je.Type__c = type;
            je.Description__c = type.trim();
			je.Currency__c = companies.get(c).Comp_Currency__c;
			je.Transaction_Date__c = p.Period_End__c.addHours(-3);

			if(type.trim().equalsIgnoreCase('ufx')){
				je.Auto_Reverse__c = true;
			}

			jes.add(je);
		}

		DML.insertAsUser(jes);

		Set<Id>jesIds = new Set<Id>();
		for(Journal_Entry__c j : jes){
			jesIds.add(j.Id);
		}

		soql = new SOQLUtil('Journal_Entry__c');
		soql.addAllFields();
		soql.setWhereClause('Id in:jesIds');

		jes = Database.query(soql.getQuery());

		return jes;
		}else{
			return null;
		}
	}

	@RemoteAction
	public static String createeJournalEntryLines(List<Journal_Entry_Line__c> objs){
		system.debug('#### JE Id: ' + objs.size());
		system.debug(objs);

		DML.insertAsUser(objs);

		return 'Inserted ' + objs.size() + ' - CPU: ' + Limits.getCpuTime() + ' - Limit: ' + Limits.getLimitCpuTime() + ' - DML: ' + Limits.getDMLRows() + ' - Limit: ' + Limits.getLimitDMLRows();
	}

	@RemoteAction
	public static String finalizeJournalEntries(List<Journal_Entry__c>jes){

		try{
			DML.updateAsUser(jes);
			return '';
		}catch(Exception ex){
			return ex.getMessage();
		}
	}

	public String message {get; set;}

	public void showPageMessage() {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
	} 

	public class ExRateAverage{

		public ExRateAverage(Currency__c toC, Currency__c fromC){
			ToCurrency = toC.ISO_Code__c;
			FromCurrency = fromC.ISO_Code__c;
            
            FromCurrencyId = fromC.Id;
            ToCurrencyId = toC.Id;

            firstDate = null;
            lastDate = null;
		}

		public String ToCurrency{get;set;}
		public String FromCurrency{get;set;}
        public String ToCurrencyId{get;set;}
        public String FromCurrencyId{get;set;}
		public DateTime firstDate{get;set;}
		public DateTime lastDate{get;set;}

		public Decimal firstRate{get;set;}
		public Decimal lastRate{get;set;}
		public Decimal avg{get{
			if(firstRate == null || lastRate == null){
				return -1;
			}else{
				return ((firstRate + lastRate)/2);
			}
		}}

		public void checkRate(Exchange_Rate__c er){
			if(firstDate == null || firstDate > er.Rate_End_DateTime__c){
				firstDate = er.Rate_End_DateTime__c;
				firstRate = er.Multiplier_Exchange_Rate__c;
			}

			if(er.Rate_End_DateTime__c == null || lastDate == null || lastDate < er.Rate_End_DateTime__c){
				lastDate = er.Rate_End_DateTime__c;
				lastRate = er.Multiplier_Exchange_Rate__c;
			}
		}


	}

	public class AEResults{
		public Sobject ParentObj{get;set;}
		public SObject ParentObj2{get;set;}
		public String AccountDisplayName{get;set;}
		public String AccountName{get;set;}
		public String GLId{get;set;}
		public Id CompanyId{get;set;}
		public List<Accounting_Entry_Line__c> AccountingEntryLines{get;set;}
		public Double TotalDR{get;set;}
		public Double TotalCR{get;set;}

		public Double FunctTotalDR{get;set;}
		public Double FunctTotalCR{get;set;}

		public Decimal OriginalExchangeRate{get;set;}
		public Decimal RevalExchangeRate{get;set;}
		public String Type{get;set;}

		public AEResults(){}

		public AEResults(Sobject po, Sobject po2, Decimal exRate, String glName, Id gl, Decimal revalRate, String t, String transcurr){
			ParentObj = po;
			ParentObj2 = po2;
			TotalDR = 0;
			TOtalCR = 0;

			FunctTotalDR = 0;
			FunctTotalCR = 0;

			Type = t;

			RevalExchangeRate = revalRate;
			OriginalExchangeRate = exRate;
			AccountDisplayName = glName + ' - ' + po.getSobject('Company__r').get('Name') + ' - ' + transcurr;
			AccountName = glName + '-' + (String)po.get('Company__c') + '-' + transcurr;
			GLId = gl;
			AccountingEntryLines = new List<Accounting_Entry_Line__c>();
		}

		public void addAccountingEntryLine(Accounting_Entry_Line__c ael){
			AccountingEntryLines.add(ael);
            if(ael.Amount_CR__c != null && ael.Amount_DR__c != null){
				TotalCR += ael.Amount_CR__c.setScale(2);
                TotalDR += ael.Amount_DR__c.setScale(2);
            }

			FunctTotalCR += ael.COMP_Functional_Currency_Amount_CR__c != null?ael.COMP_Functional_Currency_Amount_CR__c.setScale(2) :0;
			FunctTotalDR += ael.COMP_Functional_Currency_Amount_DR__c != null?ael.COMP_Functional_Currency_Amount_DR__c.setScale(2) :0;
		}

	}

	public class JournalEntryWrapper{
		public Journal_Entry__c journal{get;private set;}
		public VoidCancelService.VoidCancelDetail detail{get;private set;}

		public JournalEntryWrapper(Journal_Entry__c j, VoidCancelService.VoidCancelDetail d){
			journal = j;
			detail = d;
		}
	}
}