public with sharing class AllowanceRuleService {

    public static boolean testAllowances = false;
    final public static Boolean useFulfillmentInKey = false;

    final static String Rule_Key_Separator = '-';

    public static String SFDCBaseURL = URL.getSalesforceBaseUrl().toExternalForm();


    /*
    *  Allowance Types
    */
    final public static String TYPE_CHARGE = 'Charge';
    final public static String TYPE_DISCOUNT = 'Discount';
    final public static String TYPE_ACCRUAL = 'Accrual';
    final public static String TYPE_NEW_PRICE = 'New Price';
    final public static set<String> ALL_TYPES = new set<String> {TYPE_CHARGE, TYPE_ACCRUAL, TYPE_DISCOUNT, TYPE_NEW_PRICE};

    /*
    *  Basis values
    */
    final public static String BASIS_FLAT_AMOUNT = 'Flat';
    final public static String BASIS_RATE_BY = 'Rate By';
    final public static String BASIS_TARGET_PERCENT = 'Percentage';
    final public static String BASIS_MARKUP = 'Markup';
    final public static String BASIS_MARKDOWN = 'Markdown';
    final public static String BASIS_MULTIPLIER = 'Multiplier';
    final public static Set<String> ALL_BASIS = new Set<String> {BASIS_FLAT_AMOUNT, BASIS_RATE_BY, BASIS_TARGET_PERCENT, BASIS_MARKUP, BASIS_MARKDOWN, BASIS_MULTIPLIER};


    final public static String RATE_FIELD_WEIGHT = 'Weight';
    final public static String RATE_FIELD_QUANTITY = 'Quantity';
    final public static Set<String> RATE_FIELDS = new Set<String> {RATE_FIELD_WEIGHT, RATE_FIELD_QUANTITY};


    final public static String TARGET_FIELD_NET = 'Net';
    final public static String TARGET_FIELD_GROSS = 'Gross';
    final public static Set<String> TARGET_FIELDS = new Set<String> {TARGET_FIELD_NET, TARGET_FIELD_GROSS};

    // doesn't include New Price and Accruals.
    final public static Set<String> typesForInvoicing = new Set<String> {TYPE_CHARGE, TYPE_DISCOUNT};
    final public static Set<String> basisForManualRecalc = new Set<String> {BASIS_TARGET_PERCENT, BASIS_RATE_BY};
    final public static Set<String> positiveAllowanceTypes = new Set<String> {TYPE_CHARGE, TYPE_ACCRUAL, TYPE_NEW_PRICE};
    final public static Set<String> newPriceBasis = new Set<String> {BASIS_FLAT_AMOUNT, BASIS_MARKUP, BASIS_MARKDOWN, BASIS_MULTIPLIER};
    final public static Set<String> SO_TYPES_FOR_AUTO = new Set<String> {'Standard', 'Back To Back', 'Resale'};
    //final public static Set<String> negitiveSOTypes = new Set<String> {'rma','adjustment'};


    // Fulfillment Type for accrual
    final public static String ALLOWANCE_ACCRUAL = 'Allowance Accrual';

    // Which customer to accrue
    final public static String ACCRUE_CUSTOMER = 'Customers';
    final public static String ACCRUE_END_CUSTOMER = 'End Customers';
    final public static Set<String> ACRRUAL_RULES_OPTIONS = new set<String> {ACCRUE_CUSTOMER, ACCRUE_END_CUSTOMER};





    public static set<String> allowanceTypeFields {
        get {
            if (allowanceTypeFields == null) {
                allowanceTypeFields = new Set<String> {
                    'id', 'name',
                    'allowance_class__c', 'amount__c','Value__c',
                    'apply_at_header__c', 'Type__c', 'one_time__c', 'ordered_quantity__c', 'manual__c', 'allow_override__c',
                    'basis__c', 'percent_of_target_field__c', 'rate_field__c', 'target_field__c'
                };
            }
            return allowanceTypeFields;
        }
        set;
    }

    /* Allowance Query Helper functions */
    public static set<String> allowanceRuleFields {
        get {
            if (allowanceRuleFields == null) {
                allowanceRuleFields = new Set<String> {
                    'Name', 'Id', 'Sales_Order_Type__c', 'End_Customer__c', 'End_Customer__r.Name', 'Beneficiary__r.Name',
                    'Customer2__c', 'Customer2__r.Top_Parent_Customer__c', 'Customer_Group__c', 'Pricebook__c',
                    'Product__c', 'Product_Group__c', 'Product__r.Name', 'Product_Hierarchy__c','Allowance_Rule_Unique_Key__c',
                    'Product_Group__r.Name', 'Beneficiary__c', 'Accrue_To__c', 'Allowance_Code__c',
                    'Start_Date__c', 'End_Date__c'
                };

                allowanceRuleFields.addAll(getFieldsFromRelatedFieldList('Allowance_Type__r', allowanceTypeFields));
            }
            return allowanceRuleFields;
        }
    }

    public static set<String> allowanceAppliedFields {
        get {
            if (allowanceAppliedFields == null) {
                allowanceAppliedFields = new Set<String> {
                    'Id', 'Name', 'Unique_Key__c', 'Beneficiary__c', 'BillBack_Commitment__c', 'Beneficiary__r.Top_Parent_Customer__c',
                    'Stacking_Group__c', 'Source__c', 'Beneficiary__r.Name', 'Allowance_Applied__c',
                    'Override_Value__c', 'Allowance_Class__c', 'Allowance_Code__c',
                    'Allowance_Type__c', 'Allowance_Amount__c',
                    'Customer_Invoice2__c', 'Customer_Invoice_Line__c', 'Sales_Order__c', 'Sales_Order_Line__c',
                    'Sales_Order_Line__r.Sales_Order__c',
                    'Customer_Invoice_Line__r.Sales_Order__c',
                    'Customer_Invoice_Line__r.Customer_Invoice__r.Sales_Order__c',
                    'Customer_Invoice_Line__r.Sales_Order_Line__c'
                };

                allowanceAppliedFields.addAll(new SchemaUtil().getFieldsFromFieldSetString('Allowance_Applied__c', 'Manage_Line_Allowances'));
                allowanceAppliedFields.addAll(new SchemaUtil().getFieldsFromFieldSetString('Allowance_Applied__c', 'New'));
                allowanceAppliedFields.addAll(getFieldsFromRelatedFieldList('Allowance_Type__r', allowanceTypeFields));
                allowanceAppliedFields.addAll(getFieldsFromRelatedFieldList('Allowance_Rule2__r', allowanceRuleFields));
            }
            return allowanceAppliedFields;
        }
        set;
    }

    public static set<String> salesOrderLineFields {
        get {
            if (salesOrderLineFields == null) {
                salesOrderLineFields = new Set<String> {
                    'allowances__c', 'freight_allowance__c', 'id', 'name', 'Selling_UOM__c',
                    'extended_price__c', 'expected_price__c', 'discount_percent__c', 'ordered_date_time__c', 'off_invoice_rate__c', 'End_Customer__c', 'Currency__c', 'End_Customer__r.Name',
                    'unit_price__c', 'type__c', 'status__c', 'sales_order__c', 'company__c', 'List_Price__c','Agreement_Line__c',
                    'product__c', 'Description__c', 'New_Pricing_Rule__c','Related_Sales_Order_Line__c',
                    'BillBack_Commitment__c', 'Rate_Basis__c', 'Pricebook__c',
                    'quantity_fulfilled__c', 'quantity_shipped__c', 'quantity_ordered__c', 'weight__c', 'product_weight__c', 'non_shippable__c'
                };
				salesOrderLineFields.addAll(getFieldsFromRelatedFieldList('Product__r', productFields));
                salesOrderLineFields.addAll(getFieldsFromRelatedFieldList('Sales_Order__r', salesOrderFields));
            }
            return salesOrderLineFields;
        }
        set;
    }

	public static set<String> productFields {
		get {
			if (productFields == null) {
				productFields = new Set<String>{
					'id', 'name', 'product_group__c',
					'product_group__r.hierarchy__c', 'product_group__r.hierarchy__r.code__c',
					'product_group__r.hierarchy__r.path__c','Pricebook_Line_Required__c',
					'sales_hierarchy__c', 'sales_hierarchy__r.code__c', 'sales_hierarchy__r.path__c'
				};
			}
			return productFields;
		}
	}

    public static set<String> salesOrderFields {
        get {
            if (salesOrderFields == null) {
                salesOrderFields = new set<string> {
                    'bill_to__c', 'bill_to__r.customer_group__c', 'Company__c','Agreement__c',
                    'customer__c', 'customer__r.customer_group__c', 'bill_to__r.Name',
                    'customer__r.top_parent_customer__c', 'customer__r.top_parent_customer__r.customer_group__c',
                    'ship_to__c', 'ship_to__r.customer_group__c', 'Status__c', 'Pricebook__c',
                    'pricing_date__c', 'date_time_ordered__c', 'price_determination_date__c',
                    'delivery_method__c', 'means_of_transport__c', 'Currency__c',
                    'id', 'name', 'subtotal__c', 'Type__c', 'Payment_Term__c',
                    'total_product_weight__c', 'total_quantity_ordered__c', 'total_quantity_shipped__c'
                };
            }
            return salesOrderFields;
        }
        set;
    }

    public static set<String> customerInvoiceLineFields {
        get {
            if (customerInvoiceLineFields == null) {
                customerInvoiceLineFields = new set<string> {
                    'id',
                    'Product__r.Sales_Hierarchy__c', 'Product__r.Sales_Hierarchy__r.Path__c', 'Rate_Basis__c',
                    'Product__c', 'Product__r.Product_Group__c', 'extended_price__c', 'discount_percent__c',
                    'Total_Weight__c', 'Weight__c', 'Off_Invoice_Rate__c', 'Quantity_Shipped__c', 'Unit_Price__c',
                    'Sales_Order__c', 'Sales_Order_Line__c', 'Customer_Invoice__c', 'Shipment_Line__c', 'Customer_Invoice__r.Status__c',
                    'Customer_Invoice__r.Currency__c', 'Customer_Invoice__r.Sales_Order__c', 'Customer_Invoice__r.Total_Line_Amount__c'
                };

                customerInvoiceLineFields.addAll(getFieldsFromRelatedFieldList('Sales_Order_Line__r', salesOrderLineFields));
            }
            return customerInvoiceLineFields;
        }
        set;
    }

    public static set<String> customerInvoiceFields {
        get {
            if (customerInvoiceFields == null) {
                customerInvoiceFields = new set<string> {
                    'id', 'Currency__c', 'Sales_Order__c', 'Total_Line_Amount__c'
                };

                customerInvoiceFields.addAll(getFieldsFromRelatedFieldList('Sales_Order__r', salesOrderFields));
            }
            return customerInvoiceFields;
        }
        set;
    }

    public static Set<String> getFieldsFromRelatedFieldList(String rObjectAPIName, Set<String> objectFields) {

        Set<String> relatedObjFields = new Set<String>();

        if (objectFields == null) return relatedObjFields;

        else {
            String tmpObjectAPIName =  rObjectAPIName.endsWith('__c') ? rObjectAPIName : rObjectAPIName.removeEnd('__r') + '__c';
            relatedObjFields.add(tmpObjectAPIName);
        }


        for (String field : new List<String>(objectFields)) {
            // looping through the related fields splice '__c' with '__r' and then add the field to it
            rObjectAPIName = rObjectAPIName.endsWith('__c') ? rObjectAPIName.removeEnd('__c') + '__r' : rObjectAPIName;
            relatedObjFields.add(rObjectAPIName + '.' + field);
        }


        return relatedObjFields;
    }

    /**
    * Context class to make it easier to incorporate new rule types, without breaking exising code and clients. Rename to AllowanceContext or CalculationContext
    */
    public class RuleContext {
        public Allowance_Type__c allowanceType;
        public Allowance_Rule__c allowanceRule;

        public Allowance_Applied__c existingAA;

        public Decimal overrideValue;

        public Boolean reverseAmount;
        public Map<Id, Decimal> preferredQtyMap = new Map<Id, Decimal>(); // for header calculations
        public Decimal preferredQty;

        public SObject header;
        public List<SObject> lines;
        public Id parentId; // either SO, SOL, CI, CIL



        public Fulfillment__c[] fulfillments;

        public RuleContext( Allowance_Rule__c allowanceRule,
                            List<SObject> lines,
                            Decimal overrideValue)  {

            this.lines = lines;
            this.overrideValue = overrideValue;
            this.allowanceRule = allowanceRule;
            this.allowanceType = allowanceRule.Allowance_Type__r;

            populateValues(null);

        }

        /* Used only by accruals when recalculating for fulfillments using changed fulfilment qty */
        public RuleContext( Allowance_Rule__c allowanceRule,
                            List<SObject> lines,
                            Decimal overrideValue,
                            Map<Id, Decimal> fulfillmentQtyMap )  {

            this.allowanceRule = allowanceRule;
            this.allowanceType = allowanceRule.Allowance_Type__r;
            this.lines = lines;
            this.overrideValue = overrideValue;


            populateValues(fulfillmentQtyMap);

        }

        public void populateValues(Map<Id, Decimal> fulfillmentQtyMap) {
            Sales_Order__c tmpSo;
            Sales_Order_Line__c tmpSol;

			if (lines == null || lines.size() == 0){
				return;
			}

            if (lines[0].getsobjectType() == Sales_Order_Line__c.getsobjectType() ) {
                header = lines[0].getSobject('Sales_Order__r');
                tmpSo = (Sales_Order__c) header;
                tmpSol = (Sales_Order_Line__c ) lines[0];
            } else {
                header = lines[0].getSobject('Customer_Invoice__r');
                tmpSol = (Sales_Order_Line__c ) lines[0].getSobject('Sales_Order_Line__r');
                tmpSo = tmpSol.Sales_Order__r;// (Sales_Order__c) lines[0].getSobject('Sales_Order__r');
            }

            // if qty is negative, reverse allowance amt
            reverseAmount = allowanceType.apply_at_header__c ? (tmpSo.Total_Quantity_Ordered__c < 0) : (tmpSol.Quantity_Ordered__c < 0);

            parentId = allowanceType.Apply_at_header__c ? (Id) header.get('Id') : (Id) this.lines[0].get('Id');

            for (SObject line : lines) {
                Id lineId  = (Id) line.get('Id');
                Decimal lineQty;
                if (line.getsobjectType() == Customer_Invoice_Line__c.getsobjectType() ) {
                    lineQty = (Decimal) line.get('Quantity_Shipped__c');
                } else {
                    if (fulfillmentQtyMap != null && fulfillmentQtyMap.containsKey( lineId )) {
                        lineQty = fulfillmentQtyMap.get( lineId );
                    } else {
                        lineQty = ( (Decimal) line.get('Quantity_Fulfilled__c') > 0) ? (Decimal) line.get('Quantity_Fulfilled__c') : (Decimal) line.get('Quantity_Ordered__c');
                    }
                }

                preferredQtyMap.put( lineId , lineQty );
            }

            preferredQty = this.preferredQtyMap.get(parentId);
        }

    }

    public static Date getPricingDate(Sales_order__c so, Sales_Order_line__c sol) {
        Date allowanceDate = system.today();

        //System.debug(loggingLevel.Error, '*** header date null: ' + so.Pricing_Date__c != null);

        if (so.Pricing_Date__c != null) {

            allowanceDate = so.Price_Determination_Date__c == SalesOrderService.PRICE_DET_ORDER && sol != null && sol.Ordered_Date_Time__c != null ? sol.Ordered_Date_Time__c.date() : so.Pricing_Date__c;
        }

        return allowanceDate;
    }

    // constructs key: SO id or SOL id, AR Id, AT id
    public static String getValidationKey(Allowance_Applied__c aa) {
        String key = '';

        if (aa.Sales_order__c != null) {
            key += aa.Sales_Order__c;

        } else if (aa.Sales_order_Line__c != null) {
            key += aa.Sales_order_Line__c;
        }

        key += '-' + aa.Allowance_Rule2__c + '-' + aa.Allowance_Type__c;

        return key;
    }

    /*
    *    Used to be called from AllowanceApplied Trigger. Unused?
    */
    public static string genUniqueKey(List<Fulfillment__c> fulfillments, Allowance_Applied__c aa, Allowance_Type__c originalAt ) {
        return genUniqueKey(fulfillments, aa, null, originalAt);
    }

    public static string genUniqueKey(List<Fulfillment__c> fulfillments, Allowance_Applied__c aa, Allowance_Applied__c originalAA, Allowance_Type__c originalAt ) {
        String key = '';

        // Manual CI OT will need a unique key
        // Manual SO OT dont need a unique key
        if (originalAt.Manual__c && !aa.Allowance_Type__r.One_Time__c) return null; //&& !at.One_Time__c

        // One Time Allowance Key generation. Uses 'SO/SOL + AT'
        if ( aa.Allowance_Type__r.One_Time__c && (aa.Customer_invoice2__r != null || aa.Customer_Invoice_Line__c != null)) {
            // Key specific for One-Time AA on CI/CIL

            //if (useFulfillmentInKey && fulfillments != null && fulfillments.size() > 0){
            //    key = fulfillments[0].Parent_Fulfillment__c != null ? fulfillments[0].Parent_Fulfillment__c : fulfillments[0].id;
            //    key += Rule_Key_Separator;
            //}

            // header
            if (aa.Customer_Invoice2__c != null) {
                key += aa.Customer_Invoice2__r.Sales_Order__c  + Rule_Key_Separator
                       + originalAt.id + Rule_Key_Separator
                       + aa.Allowance_Rule2__c + Rule_Key_Separator
                       + aa.Beneficiary__c;

            }
            // line
            else if (aa.Customer_Invoice_Line__c != null) {
                key += aa.Customer_Invoice_Line__r.Sales_Order_Line__c + Rule_Key_Separator
                       + originalAt.id + Rule_Key_Separator
                       + aa.Allowance_Rule2__c + Rule_Key_Separator
                       + aa.Beneficiary__c;
            }

            // use Allowance Applied record of AA on the SO/SOL. Used during Invoicing?
            if (originalAA != null && originalAA.Id != null) {
                key += Rule_Key_Separator + originalAA.Id;
            }
        }

        else if (!aa.Allowance_Type__r.Manual__c) {
            // All automatic allowances should use this key sequence.
            // Standard Allowance Key generation. Uses 'Type + SO + SOL + CI + CIL'

            key = aa.Allowance_Type__c + Rule_Key_Separator  //KNDY-5971
                  + aa.Allowance_Rule2__c + Rule_Key_Separator
                  + aa.Sales_Order__c + Rule_Key_Separator
                  + aa.Sales_Order_Line__c + Rule_Key_Separator
                  + aa.Customer_Invoice2__c + Rule_Key_Separator
                  + aa.Customer_Invoice_line__c + Rule_Key_Separator
                  + aa.Beneficiary__c;
        }

        return key;

    }

    /**
     *  Creates a OTC Custom setting key based on company id
     */
    static final String OTC_SETTING_NAME_TEMPLATE = 'CompanyId={0}';
    public static String getOTCConfigKeyForCompanyId(String compId) {
        if (compId.length() > 15) {
            compId = compId.substring(0, 15);
        }

        String configName = String.format(OTC_SETTING_NAME_TEMPLATE, new String[] {compId});
        return configName;
    }

    public static void clearUniqueKeys(List<Customer_invoice__c> lCIs) {
        Set<id> ciIds = KSE.grepIdSetFromList(lCis);
        List<Allowance_Applied__c> invoiceAllowances = [select id, Unique_Key__c from Allowance_Applied__c where Customer_Invoice2__c IN :ciIds or Customer_Invoice_Line__r.Customer_invoice__c IN :ciIds];
        for (Allowance_Applied__c aa : invoiceAllowances) {
            aa.Unique_Key__c = null;
        }
        update invoiceAllowances;
    }

}