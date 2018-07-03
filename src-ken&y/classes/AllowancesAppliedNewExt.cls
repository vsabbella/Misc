public with sharing class AllowancesAppliedNewExt {
    public class AllowancesAppliedNewExtException extends Exception {}
    /*
    * Only manual allowances should be allowed to be created using the New page
    * other allowances are added automaticaly by the system and do not use this page.
    * Only Sales Order Header or Line can be created, all allowances on the invoice header or line are
    * generated by the system using a calculation or in the case of manual allowances by a clone from
    * the related sales order header or line.
    */
    public Allowance_Applied__c allowance {get; set; }

    public map<id, Allowance_Rule__c> validRulesMap {get; set; }
    public map<String, Allowance_Rule__c> validCodeMap {get; set; }
    public boolean hasError { get { return ApexPages.hasMessages(); }}
    public boolean disableSave {get; set;}
    public String selectedRule { get; set; }        // which rule was selected by the user
    public String selectedCode {get; set; }

    public Boolean disableOverride { get; private set;}
    public Boolean fixedBasis { get; private set;}

    public Sales_Order__c sorder {get; set;}
    public Sales_Order_Line__c soline {get; set;}
    public Map<id, Sales_Order_Line__c> allLines {get; set;}

    ApexPages.StandardController con;       // Allowance_Applied__c standard controller
    id relatedId;           // order header or line id, depending
    id sales_order_id;      // track this so we can send the user back to the correct page after a save
    id sales_order_line_id;

    public AllowancesAppliedNewExt(ApexPages.StandardController con) {
        this.con = con;
        this.allowance = (Allowance_Applied__c)con.getRecord();
        disableOverride = true; // disable override value on page load by default. Changes if editing an overridable allowance
        disableSave = false;
        this.allowance.Source__c = 'Other'; //KNDY-6032

        // this controller depends on 'rid', fetch that and store it in the field on the record
        // if it is not set, we need to add an error as we cannot proceed
        string rid = ApexPages.currentPage().getParameters().get('rid');

        try {

            // for existing allowances
            if (this.allowance.Id != null ){
                SOQLUtil soql = new SOQLUtil('Allowance_Applied__c', true); //enforceFLS=true, running in user mode
                Set<String> queryFields = new Set<String>(); // creating new set to query to avoid updating fieldset.
                queryFields.addAll(AllowanceRuleService.allowanceAppliedFields);

                queryFields.addAll(AllowanceRuleService.getFieldsFromRelatedFieldList('Sales_Order_Line__r', AllowanceRuleService.salesOrderLineFields));
                queryFields.addAll(AllowanceRuleService.getFieldsFromRelatedFieldList('Sales_Order__r', AllowanceRuleService.salesOrderFields));

                soql.addFields(queryFields);
                Id allowanceId = this.allowance.id;
                soql.setWhereClause('Id = :allowanceId');

                this.allowance = (Allowance_Applied__c) Database.query(soql.getQuery())[0];
                system.debug(logginglevel.error, 'allowance type: ' + this.allowance.Allowance_Type__r);
                if (!this.allowance.Allowance_Type__r.Manual__c && !this.allowance.Allowance_Type__r.Allow_Override__c){
                    system.debug(logginglevel.error, 'throw error');
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Cannot edit this type of allowance.'));
                    disableSave = true;
                    return;
                }

                this.allowance.Allowance_Rule2__r.Allowance_Type__r = this.allowance.Allowance_Type__r;

                // header rules
                if (this.allowance.Sales_order__c != null){
                    this.sales_order_id = relatedId = this.allowance.Sales_order__c;
                    sorder = this.allowance.Sales_Order__r;
                    allLines = getAllLines(sales_order_id);
                }
                // line rules
                else if (this.allowance.Sales_Order_Line__c != null ){
                    this.sales_order_line_id = relatedId = this.allowance.Sales_Order_Line__c;
                    soLine = this.allowance.Sales_Order_Line__r;
                    sorder =  this.allowance.Sales_Order_Line__r.Sales_Order__r;
                    this.sales_order_id = sorder.Id;
                }
            }

            // for new allowances
            else if ( rid != null ) {
                // check that the id is a header id
                relatedId = (id)rid;
                if ( relatedId.getSObjectType() == Sales_Order__c.getSObjectType() ) {
                    this.sales_order_id = this.allowance.Sales_order__c = relatedId;

                } else if ( relatedId.getSObjectType() == Sales_Order_Line__c.getSObjectType() ) {
                    this.sales_order_line_id = this.allowance.Sales_Order_Line__c = relatedId;
                    //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                    SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
                    soql.addFields(new set<string> {
                        'sales_order__c'
                    });
                    soql.setWhereClause('id = :relatedId');
                    soql.setLimit(1);
                    sales_order_id = ((Sales_Order_Line__c) Database.query(soql.getQuery())).sales_order__c;
                } else {
                    // else it's an error ( CI or CIL )
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Manual_allowances_are_only_added_to_SalesOrders));
                }
            } 

            // if no related id using the getRecord() info...
            else { 
                relatedId = allowance.Sales_order__c != null ? allowance.Sales_order__c : allowance.Sales_Order_Line__c;
            }

            if ( relatedId == null ) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.No_record_ID_found));
                return;
            }
            //system.debug(LoggingLevel.INFO, relatedId );
            //system.assert( relatedId != null , ' expected an order or order line id passed in');
            validRulesMap = new Map<id, Allowance_Rule__c>();
            validCodeMap = new Map<String,Allowance_Rule__c>();

            // if editing / updating the allowance
            System.debug(logginglevel.error, '*** AA Id (check not null) :' + this.allowance.Id);
            if (this.allowance.Id != null) {
                validRulesMap.put(this.allowance.Allowance_Rule2__c, this.allowance.Allowance_Rule2__r);
                selectedRule = validRulesMap.values()[0].Id;

                // when editing a manual rule, show other manual rules. if automatic, don't show any other rules.
                System.debug(logginglevel.error, '*** AT Manual: :' + this.allowance.Allowance_Type__r.Manual__c);
                if (this.allowance.Allowance_Type__r.Manual__c){
                    System.debug(logginglevel.error, '*** Loaded Rules :' + AllowanceService.loadManualRules(relatedId));
                    for (Allowance_rule__c ar : AllowanceService.loadManualRules( relatedId )) {
                        if (ar.Allowance_Type__r.Manual__c) { //  && ar.Id != selectedRule
                            System.debug( logginglevel.error, '***  rule:' + ar.Allowance_Code__c + ' ' + ar.Id + ' ' + ar );
                            validRulesMap.put(ar.Id, ar);
                            validCodeMap.put(ar.Allowance_Code__c, ar);
                        }
                    }
                }
                System.debug( logginglevel.error, '*** validCodeMap list size :' + validCodeMap.values().size() );
                disableOverride = !allowance.Allowance_Type__r.Allow_Override__c;
            }

            // if new allowance
            else {
                for (Allowance_rule__c ar : AllowanceService.loadManualRules( relatedId )) {
                    if (ar.Allowance_Type__r.Manual__c) {
                        validRulesMap.put(ar.Id, ar);
                        validCodeMap.put(ar.Allowance_Code__c, ar);
                    }
                }

                // if there is only one, it is selected by visualforce ??? why
                // we specify a select list, if the size is one VF shows me a picklist instead, bogus.
                if (validRulesMap.values().size() == 1 ) {
                    selectedRule = validRulesMap.values()[0].Id;
                    didChange();
                }
                //  zero rules for this header or line, provide an error message
                if ( validRulesMap.values().size() == 0 ) {
                    ApexPages.AddMessage(new ApexPages.Message(
                                             ApexPages.Severity.INFO, Label.No_ManualAllowances_available_for_this_record));
                }
            }
	
			didchange();

        } catch ( Exception e ) {
            system.debug(logginglevel.error, e + ' ' + e.getStackTraceString());
            //ApexPages.addMessages(e);
            throw new AllowancesAppliedNewExtException(e.getMessage());
        }
    }

    public static Sales_Order__c getHeader(Id salesOrderId) {
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
        soql.addFields(AllowanceRuleService.salesOrderFields);
        soql.setWhereClause('id = :salesOrderId');
        soql.setLimit(1);
        return Database.query(soql.getQuery());

        //system.debug('sorder populated: ' + sorder);
    }
   public static Map<Id,Sales_Order_Line__c> getAllLines(Id salesOrderId) {
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(AllowanceRuleService.salesOrderLineFields);
        soql.setWhereClause('Sales_Order__c = :salesOrderId');
        soql.setOrderByClause('Line__c');
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Allowances_Applied__r');
        childRel.addFields(AllowanceRuleService.allowanceAppliedFields);
        soql.addChildRelationship(childRel);
        return new map<id, Sales_Order_Line__c>((List<Sales_Order_Line__c>)Database.query(soql.getQuery()));

        //system.debug('AllLines populated: ' + allLines);
    }

    public PageReference saveAllowance() {          // save button on the AllowanceAppliedNew page

        try {
            DML.checkUpsertAsUser(allowance); upsert allowance;

        } catch (DMLException dmle) {
            system.debug(logginglevel.info, 'Catch dmlexception: ' +  dmle);

            if (dmle.getMessage().contains('duplicate')) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Cannot_apply_same_rule_twice));
            } else {ApexPages.AddMessages(dmle);} // Some other dml exception that was caught. Possibly a validation issue.

        } catch ( Exception e ) {
            system.debug(logginglevel.info, 'Catch exception: ' +  e);
            ApexPages.addMessages(e);
        }

        System.debug(ApexPages.getMessages());

        if ( ApexPages.hasMessages() ) {
            return null;
        }
        PageReference ret = Page.SalesOrderAllowances;      // go back to this page if all is well
        ret.getParameters().put('id', sales_order_id );
        return ret.setRedirect(true);
    }

    public List<SelectOption> Rules  { get {    // used to show a select list on VF page
            if (Rules != null) return Rules;
            Rules = new List<SelectOption>();
            if (validRulesMap == null) {return null;}
            for ( Allowance_Rule__c rule : validRulesMap.values()) {
                Rules.add( new SelectOption( rule.Id, rule.Name) );
            }
            Rules.sort();
            return Rules;
        } set;
    }

    public List<SelectOption> Codes  { get {    // used to show a select list on VF page
            if (Codes != null) return Codes;
            Codes = new List<SelectOption>();
            if (validRulesMap == null) {return null;}
            for ( Allowance_Rule__c rule : validRulesMap.values()) {
                if (rule.Allowance_Code__c != null){
                    Codes.add( new SelectOption( rule.Allowance_Code__c, rule.Allowance_Code__c) );
                }
            }
            Codes.sort();
            return Codes;
        } set;
    }

    public PageReference allowanceCodeChange(){
        System.debug(logginglevel.error, '*** selectedCode :' + selectedCode);
        System.debug(logginglevel.error, '*** validateCodeMap    :' + validCodeMap);
        if (validCodeMap!= null && validCodeMap.containsKey(selectedCode)) {
			System.debug( logginglevel.error, '***  : entered 1' );
            if (selectedRule != validCodeMap.get(selectedCode).Id) {
				System.debug( logginglevel.error, '***  : entered 2' );
                selectedRule = validCodeMap.get(selectedCode).Id;
                didChange();
            }
        }

        return null;
    }


    public pageReference overrideValueChange() {
        didChange();
        return null;
    }

    public PageReference didchange() {              // onchange from the select list of the page
        // find that rule, see if it needs to set the amount
        // or require the user to set the amount ?

        // automatic and manual rules to support overriding automatic rules
        Allowance_Rule__c rule = validRulesMap.get((id) selectedRule);

        if (rule == null) return null;

        System.debug(logginglevel.error, '*** rule :' + rule);
        System.debug(logginglevel.error, '*** Id + rulemap :' + selectedRule + ' ' + validRulesMap);
        if (selectedCode != rule.Allowance_Code__c){
            selectedCode = rule.Allowance_Code__c;
        }

        if (rule.Allowance_Type__r.Allow_Override__c) {
            // clear amount if type changed to Override allowance with null amount. Do not inhert previous type's amount
            this.allowance.Allowance_Amount__c = null;
            disableOverride = false;
        } else {
            // clear override value if Type was changed
            this.allowance.Override_Value__c = null;
            disableOverride = true;
        }

        allLines = allLines == null ? getAllLines(sales_order_id) : allLines;
        sorder = sorder == null ? getHeader(sales_order_id) : sorder;


        List<Sales_Order_Line__c> allSoLines;

        if (rule.Allowance_Type__r.Apply_At_Header__c){
            allSoLines = new List<Sales_Order_Line__c>(allLines.values());
        } else {
            allSoLines = new List<Sales_Order_Line__c>{ allLines.get(sales_order_line_id) };
        }

		Id allowanceId = this.allowance.Id;
		this.allowance = new AllowanceCalcService.AllowanceCreation(
				new AllowanceRuleService.RuleContext(
						rule,
						allSoLines,
						this.allowance.Override_Value__c )
		).getAllowanceRecord();
		this.allowance.Id = allowanceId;

        return null;
    }
}