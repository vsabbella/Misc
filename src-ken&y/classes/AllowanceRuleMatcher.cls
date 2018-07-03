public with sharing class AllowanceRuleMatcher {

    public class AllowanceRuleMatcherException extends Exception {}

    public static String SFDCBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
    final static String Rule_Key_Separator = '-';

    private Map<String, Allowance_Rule__c[]> keyedAllowanceRulesMap = new Map<String, Allowance_Rule__c[]>();

    final public static set<String> ALLOWANCE_RULE_SO_TYPES = new set<String> {'Standard', 'Resale'};

    public AllowanceRuleMatcher(Sales_Order__c[] soList, List<Sales_Order_Line__c[]> solLinesList, Boolean manualOnly) {
        populateData(soList, solLinesList);
        List<Allowance_Rule__c> rulesList = loadRules(manualOnly);
        System.debug(loggingLevel.Error, '~*~ AllowanceRuleMatcher rulesList size: ' + rulesList.size() );
        generateKeyedRules(rulesList);

    }

//	public AllowanceRuleMatcher(Sales_Order__c[] soList, Map<Id, Sales_Order_Line__c[]> solLinesBySoMap, Boolean manualOnly) {
//		populateData(soList, solLinesBySoMap);
//		List<Allowance_Rule__c> rulesList = loadRules(manualOnly);
//		System.debug(loggingLevel.Error, '~*~ AllowanceRuleMatcher rulesList size: ' + rulesList.size() );
//		generateKeyedRules(rulesList);
//
//	}

    private Set<id> billSoldShipToCustomerIds = new Set <Id>();
    private Set<id> topParentCustomerIds = new Set <Id>();
    private Set<id> customerGroupIds = new Set<id>();

    private Set<id> solProducts = new Set<Id>();
    private Set<Id> productGrpIds = new Set<Id>();

    private Set<Id> pricebookIds = new Set<Id>();

    private Set<Id> hierarchyId = new Set<Id>();
    private Set<Hierarchy__c> productHier = new Set<Hierarchy__c>();

    private Map<id, id[]> hierarchyToProduct = new Map<id, id[]>();

    private Date minDate;
    private Date maxDate;

	private void populateData(Sales_Order__c[] soList, List<Sales_Order_Line__c[]> solLines) {

        // iterate through all SOLs collect necessary info. SO will need lines for Allowances to Apply on header
		for (Sales_Order_Line__c[] solList : solLines) {
            for (Sales_order_line__c sol : solList) {
                // gather Product relavant info for fetching applicable rules
                solProducts.add(sol.Product__c);
                pricebookIds.add(sol.Pricebook__c);
                productGrpIds.add(sol.Product__r.Product_Group__c);
                productHier.add(sol.Product__r.Sales_Hierarchy__r);
                productHier.add(sol.Product__r.Product_Group__r.Hierarchy__r);

                // gather Customer relavant info for fetching applicable rules
                topParentCustomerIds.add(sol.Sales_Order__r.Customer__r.Top_Parent_Customer__c);
                billSoldShipToCustomerIds.addAll(new set<id> {
                    sol.Sales_Order__r.Customer__c,
                    sol.Sales_Order__r.Ship_to__c,
                    sol.Sales_Order__r.Bill_to__c
                });

                customerGroupIds.addAll(new set<Id> {
                    sol.Sales_Order__r.Bill_to__r.Customer_Group__c,
                    sol.Sales_Order__r.Customer__r.Customer_Group__c,
                    sol.Sales_Order__r.Ship_to__r.Customer_Group__c,
                    sol.Sales_Order__r.Customer__r.Top_Parent_Customer__r.Customer_Group__c
                });

                // determine pricing date range for fetching applicable rules
                Date pricingDate = AllowanceRuleService.getPricingDate(sol.Sales_Order__r, sol);
                minDate = (pricingDate < minDate || minDate == null) ? pricingDate : minDate;
                maxDate = (pricingDate > maxDate || maxDate == null) ? pricingDate : maxDate;

            }

            maxDate =  maxDate == null ? system.today() : maxDate;
            minDate =  minDate == null ? system.today() : minDate;
		}


        if (!productHier.isEmpty()) {
            hierarchyToProduct = getHierarchyProducts(new List<Hierarchy__c>(productHier));

            hierarchyId = hierarchyToProduct.keySet();
        }
    }

    // used for loading Allowance Rules in bulk using Date range
    private List<Allowance_Rule__c> loadRules(Boolean manaul) {

        solProducts.remove(null);
        pricebookIds.remove(null);
        productGrpIds.remove(null);

        billSoldShipToCustomerIds.remove(null);
        topParentCustomerIds.remove(null);
        customerGroupIds.remove(null);

        String whereClause = '' +
                             '( ' +
                             '(Customer_Group__c IN: customerGroupIds OR Customer_Group__c = null) ' +
                             '    AND ( Customer2__c IN :billSoldShipToCustomerIds ' +
                             'OR (Customer2__c IN :topParentCustomerIds) ' +
                             'OR Customer2__c = null) ' +
                             ') ' +
                             'AND (Pricebook__c IN:pricebookIds OR Pricebook__c = null) ' +
                             'AND (Product__c IN :solProducts OR Product__c = null) ' +
                             'AND (Product_Group__c IN :productGrpIds OR Product_Group__c = Null) ' +
                             'AND (Product_Hierarchy__c IN : hierarchyId OR Product_Hierarchy__c = Null) ' +
                             'AND ( ' +
                             '    (Start_Date__c <= :minDate and End_Date__c >= : minDate) ' +
                             '    OR (Start_Date__c <= :maxDate and End_Date__c >= :maxDate) ' +
                             '    OR (Start_Date__c >= :minDate AND End_Date__c  <=: maxDate) ' +
                             '    )';
        if (manaul) {
            whereClause += ' AND Allowance_Type__r.Manual__c = true';
        }

        //System.debug(loggingLevel.Error, '*** whereClause: ' + whereClause);
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Allowance_Rule__c', true); //enforceFLS=true, running in user mode
        soql.addFields(AllowanceRuleService.allowanceRuleFields);
        soql.setWhereClause(whereClause);

        return (List<Allowance_Rule__c>) Database.query( soql.getQuery() ) ;
    }

    /**
     *  Creates a map for all Rules that are related to the SO/Sols. renamed from organiserulesByPriorityKeys
     */
    private void generateKeyedRules( List<Allowance_Rule__c> rulesList ) {

        if (rulesList.isEmpty()) return;

        for (Allowance_Rule__c ar : rulesList) {

            // initialize key with SO Type
            Set<String> keys = new Set <String>();

            String key = '';
            //key += ar.Allowance_Type__r.Apply_At_Header__c ? 'HDR' : 'LN';
            //key += Rule_Key_Separator;

            key += ar.Sales_Order_Type__c + Rule_Key_Separator;

            key += ar.Pricebook__c != null ? ar.Pricebook__c + Rule_Key_Separator : '';

            key += ar.End_Customer__c != null ? ar.End_Customer__c + Rule_Key_Separator : '';

            // supports only customer group or customer
            key += ar.Customer_Group__c != null ? ar.Customer_Group__c : ar.Customer2__c;


            // Only one type (product, pg, ph is allowed)
            if (ar.Product__c != null || ar.Product_Group__c != null || ar.Product_Hierarchy__c != null) {
                key += Rule_Key_Separator;

                if (ar.Product__c != null) {
                    keys.add(key + ar.Product__c);

                } else if (ar.Product_Group__c != null) {
                    keys.add(key + ar.Product_Group__c);

                } else if ( ar.Product_Hierarchy__c != null ) {

                    if (hierarchyToProduct.containsKey(ar.Product_Hierarchy__c)) {
                        for (Id prodId : hierarchyToProduct.get(ar.Product_Hierarchy__c)) {
                            keys.add(key + prodId);
                        }
                    }
                }
            } else {
                keys.add(key);
            }

            for (String keyValue : keys) {

                if (!keyedAllowanceRulesMap.containsKey(keyValue)) {
                    keyedAllowanceRulesMap.put(keyValue, new List<Allowance_Rule__c>());
                }
                keyedAllowanceRulesMap.get(keyValue).add(ar);
            }
        }
    }

    /**
     * Gives best matching rules which can be applied based on customer and product combo.
     * Please note, this method takes rules in form of priority key map created by method organiserulesByPriorityKeys(...)
     * Renamed from findBestMatchingAllowanceTypes
     */

    public Allowance_Rule__c[] fetchMatchingRules (
        Date soPricingDate, String soType, Id pricebookId,
        Id endCustomer, List<String> customerIds, List<String> customerGroupIds,
        List<Id> productIds, List<Id> productGroupIds, Boolean header
    ) {

        //System.debug(loggingLevel.Error, '*** soPricingDate: ' + soPricingDate);

        // Add null values for filter values to pick up null value on AR if applicable
        customerIds.add(null);
        customerGroupIds.add(null);
        productIds.add(null);
        productGroupIds.add(null);

        // creates key using order info: customer, product, pg, ph
        Set <String> priorityKeys = new Set<String>();

        String baseKey = '';
        //baseKey += header ? 'HDR' : 'LN';
        //baseKey += Rule_Key_Separator;

        // if it's a SO type we don't recognize, treat it like a standard SO. Typically, these should be Adjustments, RMAs, so the Stardard Allowance rules will apply to
        if (!ALLOWANCE_RULE_SO_TYPES.contains(soType)) {
            soType = 'Standard';
        }

        baseKey += soType + Rule_Key_Separator;

        String baseKeyWithEndCustomer = baseKey + endCustomer + Rule_Key_Separator;
        String basekeyWithPBkey = baseKey + pricebookId + Rule_Key_Separator;


        // for rules with only customer
        for (Id customerId : customerIds) {
            priorityKeys.add(baseKey + customerId);
            priorityKeys.add(baseKeyWithEndCustomer + customerId);
            priorityKeys.add(basekeyWithPBkey + customerId);
        }

        // for rules with only customer groups
        for (Id customerGroupId : customerGroupIds) {
            priorityKeys.add(baseKey + customerGroupId);
            priorityKeys.add(baseKeyWithEndCustomer + customerGroupId);
            priorityKeys.add(basekeyWithPBkey + customerGroupId);
        }

        if (productIds != null && !productIds.isEmpty()) {
            for (Id productId : productIds) {
                //priorityKeys.add(Null + Rule_Key_Separator + productId);
                for (Id custId : customerIds) {
                    String cKey = custId  + Rule_Key_Separator + productId;
                    priorityKeys.add(baseKey + cKey);
                    priorityKeys.add(baseKeyWithEndCustomer + cKey);
                    priorityKeys.add(basekeyWithPBkey + cKey);
                }

                for (Id custGroupId : customerGroupIds) {
                    String cgKey = custGroupId  + Rule_Key_Separator + productId;
                    priorityKeys.add(baseKey + cgKey);
                    priorityKeys.add(baseKeyWithEndCustomer + cgKey);
                    priorityKeys.add(basekeyWithPBkey + cgKey);
                }
            }
        }

        if (productGroupIds != null && !productGroupIds.isEmpty()) {
            for (Id productGroupId : productGroupIds) {
                //priorityKeys.add(Null + Rule_Key_Separator + productGroupId);
                for (Id custId : customerIds) {
                    String cKey = custId  + Rule_Key_Separator + productGroupId;
                    priorityKeys.add(baseKey + cKey);
                    priorityKeys.add(baseKeyWithEndCustomer + cKey);
                    priorityKeys.add(basekeyWithPBkey + cKey);
                }
                for (Id custGroupId : customerGroupIds) {
                    String cgKey = custGroupId  + Rule_Key_Separator + productGroupId;
                    priorityKeys.add(baseKey + cgKey);
                    priorityKeys.add(baseKeyWithEndCustomer + cgKey);
                    priorityKeys.add(basekeyWithPBkey + cgKey);
                }
            }
        }

        set <Allowance_Rule__c> bestMatchingAllowances = new set <Allowance_Rule__c>();

        for (String pk : priorityKeys) {
            if (keyedAllowanceRulesMap.containsKey(pk)) {
                for (Allowance_Rule__c ar : keyedAllowanceRulesMap.get(pk)) {

                    if (ar.Allowance_Type__r.Apply_At_Header__c == header) {

                        //Boolean validDate = (ar.Start_Date__c <= soPricingDate && (ar.End_date__c == null || ar.End_date__c >= soPricingDate) && ar.Allowance_Type__r != null);
                        //System.debug(loggingLevel.Error, '*** 1: ' + (ar.Start_Date__c <= soPricingDate));
                        //System.debug(loggingLevel.Error, '*** 2: ' + (ar.End_date__c == null || ar.End_date__c >= soPricingDate));
                        //System.debug(loggingLevel.Error, '*** 3: ' + (ar.Allowance_Type__r != null));
                        //System.debug(loggingLevel.Error, '*** Valid date: ' + validDate + ' == ' + ar.Start_Date__c + ' <= ' + soPricingDate + ' <= ' + ar.End_Date__c);

                        if (ar.Start_Date__c <= soPricingDate && (ar.End_date__c == null || ar.End_date__c >= soPricingDate) && ar.Allowance_Type__r != null) {
                            bestMatchingAllowances.add(ar);
                        }
                    }
                }
            }
        }

        //System.debug(loggingLevel.Error, '*** bestMatchingAllowances: ' + bestMatchingAllowances);
        return new list<Allowance_Rule__c>(bestMatchingAllowances);
    }


    static HierarchyController.Node top = null;

    /*
     * Using the hierarchy path, retrieve ancestor code and query to get ancestor list with product and product group information.
     * Using
     */
    public static Map<Id, Id[]> getHierarchyProducts(Hierarchy__c[] hieList) {
        Map<Id, Id[]> hierarchyToProduct = new Map<Id, Id[]>();

        // Map: k:Ancestor -> v:current node
        Map <Id, String[]> hieCodePath = new Map<Id, String[]>();
        Set<String> allCodes = new set<String>();
        for (Hierarchy__c hie : hieList) {
            if (hie == null)
                continue; // no hierarchy on product. We can ignore this. No need for an exception

            if (hie.Path__c != null) {
                hieCodePath.put(hie.Id, hie.Path__c.split('\\|'));
                allCodes.addAll(hie.Path__c.split('\\|'));

            } else {
                String link = ' <a href=\'' + SFDCBaseURL + '/' + hie.Id + '\'>' + hie.name + ' </a>';
                throw new AllowanceRuleMatcherException('No hierarchy path found on hierarchy record. ' + link);
            }
        }

        if (allCodes.isEmpty()) return hierarchyToProduct;

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Hierarchy__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string> {
            'Id', 'Path__c', 'Code__c', 'Parent_code__c'
        });
        soql.setWhereClause('Code__c in :allCodes');
        SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Products__r');
        childRel1.addFields(new set<string> {
            'Id', 'Name', 'Sales_hierarchy__c', 'Sales_Hierarchy__r.Path__c'
        });
        soql.addChildRelationship(childRel1);
        SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Product_Groups__r');
        childRel2.addFields(new set<string> {
            'Id', 'Name', 'Hierarchy__c', 'Hierarchy__r.Path__c'
        });
        soql.addChildRelationship(childRel2);
        Hierarchy__c[] hrhchyList = Database.query(soql.getQuery());

        if (hrhchyList.isEmpty()) return hierarchyToProduct;

        //system.debug(LoggingLevel.info, 'hrhchyList: ' + hrhchyList);

        // return map. K: product hierarchy -> v: hierarchy ancestors
        Map<Id, Id[]> hiAncestorMap = new Map<Id, Id[]>();
        Map<String, Id> codeToHierarchy = new Map<String, Id>();

        for (Hierarchy__c hie : hrhchyList) {
            // retrieves current decendant using ancestor.
            if (!codeToHierarchy.containsKey(hie.Code__c)) {
                codeToHierarchy.put(hie.Code__c, hie.Id);
            }
        }

        for (Hierarchy__c hie : hieList) {
            if (hie == null)
                continue;

            if (hieCodePath.containsKey(hie.id)) {
                for (String code : hieCodePath.get(hie.id)) {
                    if (!hiAncestorMap.containsKey(hie.id)) {
                        hiAncestorMap.put(hie.id, new list<Id>());
                    }
                    hiAncestorMap.get(hie.id).add( codeToHierarchy.get(code));
                }
            }
        }

        //return hiAncestorMap;
        Set<Id> allRelatedHies = new Set<Id>();

        for (Id hie : hiAncestorMap.keySet()) {
            for (Id desendant : hiAncestorMap.get(hie)) {
                allRelatedHies.add(desendant);
            }
        }

        // products and product groups belonging to hierarchy
        Set<Product__c> allHierarhcyProducts = new Set<Product__c>();
        Set<Product_Group__c> allHierarchyProductGroups = new Set<Product_Group__c>();

        //system.debug(LoggingLevel.info, 'hrhchyList: ' + hrhchyList );
        //  get products and product groups in hierarchy
        for (Hierarchy__c hie : hrhchyList) {
            codeToHierarchy.put(hie.Code__c, hie.id);
            if (!hie.products__r.isEmpty()) {
                allHierarhcyProducts.addAll(hie.Products__r);
            }
            if (!hie.product_groups__r.isEmpty()) {
                allHierarchyProductGroups.addAll(hie.Product_Groups__r);
            }
        }
        // retrieves the Path__c from each product's hierarchy
        for (Product__c prod : allHierarhcyProducts) {
            if (prod.Sales_Hierarchy__r.Path__c != null) {
                List<String> codeList = prod.Sales_Hierarchy__r.Path__c.split('\\|');

                for (String code : codeList) {
                    Id hieId = codeToHierarchy.get(code);

                    if (!hierarchyToProduct.containsKey(hieId)) {
                        hierarchyToProduct.put(hieId, new List<Id> {});
                    }
                    hierarchyToProduct.get(hieId).add(prod.id);
                }
            } else {
                String link = ' <a href=\'' + SFDCBaseURL + '/' + prod.Sales_Hierarchy__c + '\'>' + prod.Sales_Hierarchy__r.name + ' </a>';
                throw new AllowanceRuleMatcherException('No hierarchy path found on hierarchy record. ' + link);
            }
        }

        for (Product_Group__c pg : allHierarchyProductGroups) {
            if (pg.Hierarchy__r.Path__c != null) {
                List<String> codeList = pg.Hierarchy__r.Path__c.split('\\|');

                for (String code : codeList) {
                    Id hieId = codeToHierarchy.get(code);

                    if (!hierarchyToProduct.containsKey(hieId)) {
                        hierarchyToProduct.put(hieId, new List<Id> {});
                    }
                    hierarchyToProduct.get(hieId).add(pg.id);
                }
            } else {
                String link = ' <a href=\'' + SFDCBaseURL + '/' + pg.Hierarchy__c + '\'>' + pg.Hierarchy__r.name + ' </a>';
                throw new AllowanceRuleMatcherException('No hierarchy path found on hierarchy record. ' + link);
            }
        }
        return hierarchyToProduct;
    }
}