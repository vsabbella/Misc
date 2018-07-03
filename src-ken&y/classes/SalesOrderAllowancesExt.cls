public with sharing class SalesOrderAllowancesExt {
	ApexPages.StandardController con;
	Sales_Order__c sorder = new Sales_Order__c();

	public string retUrl {
		get{
			return Page.SalesOrderAllowances.getUrl();
		}
	}

	public SalesOrderAllowancesExt(ApexPages.StandardController con) {
		this.con = con;
		loadLines();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id conId = con.getId();

		SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(AllowanceRuleService.salesOrderFields);
		soql.setWhereClause('id = :conId');
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Allowances_Applied__r');
		childRel.addFields(AllowanceRuleService.allowanceAppliedFields);
		soql.addChildRelationship(childRel);
		soql.setLimit(1);

		sorder = Database.query(soql.getQuery());

	}

	public PageReference deleteRecord() {
		DML.deleteAsUser(new Allowance_Applied__c(id = ApexPages.currentPage().getParameters().get('did')));
		PageReference ret = Page.SalesOrderAllowances;
		ret.getParameters().put('id', con.getId());
		// loadLines();
		return ret.setRedirect(true);
		//return null;
	}

	public void setAllowances() {
		//Map<Id, Map<String, List<Allowance_Applied__c>>> currentAllowancesMap = new Map<Id, Map<String, List<Allowance_Applied__c>>>();

		// for auto allowances during reset
		List<Allowance_Applied__c> existingAllowance = new List<Allowance_Applied__c>();

		Id conId = con.getId();

		loadLines();

		SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(AllowanceRuleService.salesOrderFields);
		soql.setWhereClause('id = :conId');
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Allowances_Applied__r');
		childRel.addFields(AllowanceRuleService.allowanceAppliedFields);
		soql.addChildRelationship(childRel);
		soql.setLimit(1);

		sorder = Database.query(soql.getQuery());

		existingAllowance.addAll(sorder.Allowances_Applied__r);

		for (Sales_Order_Line__c sol : allLines) {
			existingAllowance.addAll(sol.Allowances_Applied__r);
		}

		AllowanceApplicator applicator = new AllowanceApplicator(
			    new Map<Id, Sales_Order__c>( new List<Sales_Order__c> {sorder} ),
			    new Map<id, Sales_Order_Line__c[]> { sorder.id => allLines },
			    existingAllowance,
			    null
			);

		applicator.validateAndApply();

	}

	public void createAutomaticAllowance() {
		// create any automatic allowances now, using the rule service so they show up on the page
		// this service avoids duplicates
		try {
			if (autoAllowancesEnabled) {
				setAllowances();
			}
		} catch (Exception e) {
			System.debug( logginglevel.error, e.getMessage() + ' ' + e.getStackTraceString() );
			ApexPages.addmessages(e);
		}

		loadLines(); // new allowances exist now
	}


	public Boolean autoAllowancesEnabled {
		get {
			return (AllowanceRuleService.SO_TYPES_FOR_AUTO.contains(sorder.Type__c)); // hide Reset button if SO Type supports auto apply allowances.
		}
	}

	public void reset() {
		// create any automatic allowances now, using the rule service so they show up on the page
		// this service avoids duplicates
		try {

			setAllowances();

		} catch (Exception e) {
			ApexPages.addmessages(e);
			system.debug(LoggingLevel.ERROR, e.getMessage() + ' ' + e.getStackTraceString());
		}

		loadLines(); // new allowances exist now
	}

	public List<Sales_Order_Line__c> allLines {get; set;}
	public List<Allowance_Applied__c> tradeAllowances {get; set;}
	public Map<Id, List<Allowance_Applied__c>> solToTradeAllowanceMap {get; set;}
	public List<wrapSOL> wSOLlist {get; set;}


	void loadLines() {
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id conId = con.getId();

		SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode

		soql.addFields(AllowanceRuleService.salesOrderLineFields);
		soql.setWhereClause('Sales_Order__c = :conId');
		soql.setOrderByClause('Line__c');

		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Allowances_Applied__r');
		childRel.addFields(AllowanceRuleService.allowanceAppliedFields);
		childRel.setWhereClause('Source__c!=\'Trade\'');
		soql.addChildRelationship(childRel);
		allLines = Database.query(soql.getQuery());


		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		soql = new SOQLUtil('Allowance_Applied__c', true); //enforceFLS=true, running in user mode
		soql.addFields(AllowanceRuleService.allowanceAppliedFields);
		soql.setWhereClause('Source__c =\'Trade\' AND Sales_Order_Line__r.Sales_Order__c = :conId');
		soql.setOrderByClause('Sales_Order_Line__c, Off_Invoice_Paid__c DESC, BillBack_Commitment__c DESC');

		tradeAllowances = Database.query(soql.getQuery());

		//organize the SOL allowances into a map where the key is the SOL Id and the value is a list of the allowances
		Map<Id, List<Allowance_Applied__c>> solToTradeAllowanceMap = new Map<Id, List<Allowance_Applied__c>>();
		for (Allowance_Applied__c aa : tradeAllowances) {
			if (solToTradeAllowanceMap.containsKey(aa.Sales_Order_Line__c)) {
				List<Allowance_Applied__c> aaTempList = solToTradeAllowanceMap.get(aa.Sales_Order_Line__c);
				aaTempList.add(aa);
				solToTradeAllowanceMap.put(aa.Sales_Order_Line__c, aaTempList);
			} else {
				solToTradeAllowanceMap.put(aa.Sales_Order_Line__c, new List<Allowance_Applied__c> {aa});
			}
		}

		//now loop through all the non trade and trade allowances and add them to a list of wrappers
		wSOLlist = new List<wrapSOL> ();

		for (Sales_Order_Line__c sol : allLines) {
			wrapSOL wSOL = new wrapSOL();
			wSOL.sol = sol;

			List<allowanceAppliedItem> aaiList = new List<allowanceAppliedItem>();
			//nontrade
			for (Allowance_Applied__c aa : sol.Allowances_Applied__r) {
				allowanceAppliedItem aai = new allowanceAppliedItem();
				aai.allowanceApplied = aa;
				aai.aaId = aa.Id;
				aai.typeId = aa.Allowance_Type__c;
				aai.ruleId = aa.Allowance_Rule2__c;
				aai.beneficiaryId = aa.Beneficiary__c;
				aai.salesOrderId = sol.Sales_Order__c;
				aai.Name = aa.Name;
				aai.stackingOrder = aa.Stacking_Group__c;
				aai.arCode = aa.Allowance_Code__c;
				aai.manual = aa.Allowance_Type__r.Manual__c;
				aai.allowanceType = aa.Allowance_Type__r.Name;
				aai.allowanceRule = aa.Allowance_Rule2__r.Name;
				aai.basis = aa.Allowance_Type__r.Basis__c;
				aai.oneTime = aa.Allowance_Type__r.One_Time__c;
				aai.offInvoiceRate = 'N/A';
				aai.billBackRate = 'N/A';
				aai.offInvoiceAmount = 'N/A'; //formatDecimal(aa.Allowance_Amount__c);
				aai.allowanceAmount = formatDecimal(aa.Allowance_Amount__c);
				aai.billBackAmount = formatDecimal(aa.BillBack_Commitment__c);
				aai.beneficiary = aa.Beneficiary__r.Name;
				aai.isTrade = false;
				aai.source = aa.Source__c;
				aai.aaType = aa.Allowance_Type__r;
				aaiList.add(aai);
			}

			//trade
			if (solToTradeAllowanceMap.containsKey(sol.Id)) {
				for (Allowance_Applied__c aa : solToTradeAllowanceMap.get(sol.Id)) {
					allowanceAppliedItem aai = new allowanceAppliedItem();
					aai.aaId = aa.Id;
					aai.allowanceApplied = aa;
					aai.salesOrderId = sol.Sales_Order__c;
					aai.Name = aa.Name;
					aai.stackingOrder = aa.Stacking_Group__c;
					aai.manual = false;
					aai.allowanceRuleId = null;
					aai.allowanceRule = aa.Description__c;
					aai.offInvoiceRate = percentAndDollarToRate(aa.Off_Invoice_Percent__c, aa.Off_Invoice_Rate__c);
					aai.offInvoiceAmount = formatDecimal(aa.Off_Invoice_Paid__c);
					aai.billBackRate = percentAndDollarToRate(aa.BillBack_Percent__c, aa.BillBack_Rate__c);
					aai.allowanceAmount = formatDecimal(aa.Allowance_Amount__c); // this field will be null for trade? Change to N/A?
					aai.billBackAmount = formatDecimal(aa.BillBack_Commitment__c);
					aai.isTrade = true;
					aai.source = aa.Source__c;
					aai.aaType = aa.Allowance_Type__r;
					aaiList.add(aai);
				}
			}

			wSOL.aaiList = aaiList;
			wSOLlist.add(wSOL);
		}
	}


	//TPM-178, lets us to a mashup of trade and non-trade allowances for display in the VF page
	public class wrapSOL {
		public Sales_Order_Line__c sol {get; set;}
		public List<allowanceAppliedItem> aaiList {get; set;}

		public wrapSOL() {

		}
	}

	public class allowanceAppliedItem {
		public Id aaId {get; set;}
		public Allowance_Applied__c allowanceApplied {get; set;}
		public Id salesOrderId {get; set;}
		public String Name {get; set;}
		public Decimal stackingOrder {get; set;}
		public Boolean manual {get; set;}
		public Id allowanceRuleId {get; set;}
		public String allowanceRule {get; set;}
		public String allowanceType {get; set;}
		public Id typeId {get; set;}
		public Id ruleId {get; set;}
		public Id beneficiaryId {get;set;}
		public String offInvoiceRate {get; set;}
		public String billBackRate {get; set;}
		public String offInvoiceAmount {get; set;}
		public String allowanceAmount {get; set;}
		public String billBackAmount {get; set;}
		public String beneficiary {get; set;}
		public Boolean isTrade {get; set;}
		public String source {get; set;}
		public String basis {get; set;}
		public boolean oneTime {get; set;}
		public Allowance_Type__c aaType {get; set;}
		public String arCode {get;set;}

		public allowanceAppliedItem() {

		}
	}

	//helper method to take in a percent and dollar value and return one or the other (only one should be populated)
	//in a formatted manner
	private String percentAndDollarToRate(Decimal percentVal, Decimal dollarVal) {
		String rateVal = '';
		if ( (percentVal != null) && (percentVal != 0) ) {
			Decimal stripped = percentVal.stripTrailingZeros();
			rateVal = stripped.toPlainString() + '%';
		}
		if ( (dollarVal != null) && (dollarVal != 0) ) {
			Decimal stripped = dollarVal.stripTrailingZeros();
			rateVal = '$' + stripped.toPlainString();
		}
		return rateVal;
	}

	private String formatDecimal(Decimal dAmt) {
		String sAmt = '';
		if (dAmt != null) {
			Decimal stripped = dAmt.stripTrailingZeros().setScale(2);
			sAmt = stripped.toPlainString();
		}
		return sAmt;
	}

}