public with sharing class PricingService {

    private static final String QRY_PBL_PRICING_COMP_IDS = 'companyIds';
    private static final String QRY_PBL_PRICING_CUST_IDS = 'customerIds';
    private static final String QRY_PBL_PRICING_CUST_GRP_IDS = 'customerGroupIds';
    private static final String QRY_PBL_PRICING_PROD_IDS = 'productIds';
    private static final String QRY_PBL_PRICING_PROD_GRP_IDS = 'productGroupIds';
    private static final String QRY_PBL_PRICING_PRICEBOOK_IDS = 'pricebookIds';
    private static final String QRY_PBL_PRICING_SO_TRANS_CUR = 'soTrasactionCurrency';
    private static final String QRY_PBL_PRICING_MIN_DATE = 'minDate';
    private static final String QRY_PBL_PRICING_MAX_DATE = 'maxDate';
    private static final String QRY_PBL_PRICING_MIN_QTY = 'minQty';
    private static final String QRY_PBL_PRICING_MAX_QTY = 'maxQty';
    public static final String PRICE_TYPE_SALES = 'Sales';
    public static final String PRICE_TYPE_RECURRING = 'Recurring';

	public class PricingServiceException extends Exception{}

    private static Map<String, Set<Id>> getPBLPricingQueryInfoMap(List<SObject> sObjects){

        Map<String, Set<Id>> pblQueryInfoMap = new Map<String, Set<Id>>();
        Set<id> companyIds = new Set<id>();
        Set<Id> customerIds = new Set<Id>();
        Set<id> productIds = new Set<Id>();
        Set<Id> productGroupIds = new Set<Id>();
        Set<Id> pricebookIds =  new Set<Id>();
        Set<Id> soTrasactionCurrency = new Set<Id>();
        Set<Id> customerGroupIds = new Set<Id>();

        Schema.SObjectType sObjectType = sObjects.getSObjectType();

        for (SObject sobj : sObjects) {
            if(sObjectType == Sales_Order_Line__c.sObjectType){
                Sales_Order_Line__c sol = (Sales_Order_Line__c)sobj;
                // skip lines that have AGL associated to them
                if (sol.Agreement_Line__c != null){
                    continue;
                }
                Sales_Order__c so = sol.Sales_Order__r;
                Product__c prod = sol.Product__r;

                soTrasactionCurrency.add( so.currency__c );

                if(so.Customer__c != null){
                    customerIds.add(so.Customer__c);
                    if(so.customer__r.Customer_Group__c != null){
                        customerGroupIds.add(so.customer__r.Customer_Group__c);
                    }
                }

                if(so.Company__c != null){
                    companyIds.add(so.Company__c);
                }

                if (prod != null){
                    productIds.add(prod.Id);
                    if(prod.Product_Group__c != null){
                        productGroupIds.add(prod.Product_Group__c);
                    }
                }

                if(so.Pricebook__c != null){
                    pricebookIds.add(so.Pricebook__c);
                }

                if(so.Customer__r.Pricebook__c != null){
                    pricebookIds.add(so.Customer__r.Pricebook__c);
                }

                if(sol.Pricebook__c != null){
                    pricebookIds.add(sol.Pricebook__c);
                }
            } else if(sObjectType == Agreement_Line__c.sObjectType){

                Agreement_Line__c agl = (Agreement_Line__c)sObj;
                Agreement__c ag = agl.Agreement__r;
                Product__c prod = agl.Product__r;

                soTrasactionCurrency.add( ag.currency__c );

                if(ag.Sold_To__c != null){
                    customerIds.add(ag.Sold_To__c);
                    if(ag.Sold_To__r.Customer_Group__c != null){
                        customerGroupIds.add(ag.Sold_To__r.Customer_Group__c);
                    }

                    if(ag.Sold_To__r.Pricebook__c != null){
                        pricebookIds.add(ag.Sold_To__r.Pricebook__c);
                    }
                }

                if(ag.Company__c != null){
                    companyIds.add(ag.Company__c);
                }

                if (prod != null){
                    productIds.add(prod.Id);
                    if(prod.Product_Group__c != null){
                        productGroupIds.add(prod.Product_Group__c);
                    }
                }

                if(agl.Pricebook__c != null){
                    pricebookIds.add(agl.Pricebook__c);
                }

            }
        }

        pblQueryInfoMap.put(PricingService.QRY_PBL_PRICING_COMP_IDS, companyIds);
        pblQueryInfoMap.put(PricingService.QRY_PBL_PRICING_CUST_IDS, customerIds);
        pblQueryInfoMap.put(PricingService.QRY_PBL_PRICING_PROD_IDS, productIds);
        pblQueryInfoMap.put(PricingService.QRY_PBL_PRICING_PROD_GRP_IDS, productGroupIds);
        pblQueryInfoMap.put(PricingService.QRY_PBL_PRICING_PRICEBOOK_IDS, pricebookIds);
        pblQueryInfoMap.put(PricingService.QRY_PBL_PRICING_CUST_GRP_IDS, customerGroupIds);
        pblQueryInfoMap.put(PricingService.QRY_PBL_PRICING_SO_TRANS_CUR, soTrasactionCurrency);

        return pblQueryInfoMap;
    }

    private static Map<String, Date> getPBLPricingQueryDates(List<SObject> sObjects){
        Map<String, Date> pricingDatesMap = new Map<String, Date>();
        Schema.SObjectType sObjectType = sObjects.getSObjectType();
        Date minDate, maxDate;
        for (SObject sobj : sObjects) {
            if (sObjectType == Sales_Order_Line__c.sObjectType) {
                Sales_Order_Line__c sol = (Sales_Order_Line__c) sobj;
                Sales_Order__c so = sol.Sales_Order__r;

                if (minDate == null || minDate > so.Pricing_Date__c){
                    minDate = so.Pricing_Date__c;
                }
                if (maxDate == null || maxDate < so.Pricing_Date__c){
                    maxDate = so.Pricing_Date__c;
                }

                if (so.Price_Determination_Date__c == SalesOrderService.PRICE_DET_ORDER && sol.Ordered_Date_Time__c != null){
                    if (minDate > sol.Ordered_Date_Time__c.date()){
                        minDate = sol.Ordered_Date_Time__c.date();
                    }
                    if (maxDate < sol.Ordered_Date_Time__c.date()){
                        maxDate = sol.Ordered_Date_Time__c.date();
                    }
                }
            } else if(sObjectType == Agreement_Line__c.sObjectType){

                minDate = System.today();
                maxDate = System.today();
            }
        }

        if(minDate != null){
            pricingDatesMap.put(PricingService.QRY_PBL_PRICING_MIN_DATE, minDate);
        } else {
            pricingDatesMap.put(PricingService.QRY_PBL_PRICING_MIN_DATE, System.today());
        }

        if(maxDate != null){
            pricingDatesMap.put(PricingService.QRY_PBL_PRICING_MAX_DATE, maxDate);
        } else {
            pricingDatesMap.put(PricingService.QRY_PBL_PRICING_MAX_DATE, System.today());
        }

        return pricingDatesMap;
    }

    private static Map<String, Decimal> getPBLPricingQueryQty(List<SObject> sObjects){
        Map<String, Decimal> pricingQtyMap = new Map<String, Decimal>();
        Schema.SObjectType sObjectType = sObjects.getSObjectType();
        Decimal solMinQty, solMaxQty;
        for (SObject sobj : sObjects) {

            if (sObjectType == Sales_Order_Line__c.sObjectType) {

                Sales_Order_Line__c sol = (Sales_Order_Line__c) sobj;

                if (sol.Quantity_Ordered__c != null && (solMinQty == null || sol.Quantity_Ordered__c < solMinQty)){
                    solMinQty = Math.abs(sol.Quantity_Ordered__c);
                }

                if (sol.Quantity_Ordered__c != null && (solMaxQty == null ||  sol.Quantity_Ordered__c > solMaxQty)){
                    solMaxQty = Math.abs(sol.Quantity_Ordered__c);
                }

            } else if(sObjectType == Agreement_Line__c.sObjectType){

                Agreement_Line__c agl = (Agreement_Line__c)sObj;

                if (agl.Sales_Agreement_Quantity__c != null && (solMinQty == null || agl.Sales_Agreement_Quantity__c < solMinQty)){
                    solMinQty = Math.abs(agl.Sales_Agreement_Quantity__c);
                }

                if (agl.Sales_Agreement_Quantity__c != null && (solMaxQty == null ||  agl.Sales_Agreement_Quantity__c > solMaxQty)){
                    solMaxQty = Math.abs(agl.Sales_Agreement_Quantity__c);
                }
            }
        }

        if(solMinQty != null){
            pricingQtyMap.put(PricingService.QRY_PBL_PRICING_MIN_QTY, solMinQty);
        } else{
            pricingQtyMap.put(PricingService.QRY_PBL_PRICING_MIN_QTY, 0);
        }

        if(solMaxQty != null){
            pricingQtyMap.put(PricingService.QRY_PBL_PRICING_MAX_QTY, solMaxQty);
        } else{
            pricingQtyMap.put(PricingService.QRY_PBL_PRICING_MAX_QTY, 0);
        }
        return pricingQtyMap;
    }

    private static Set<Id> getPBIdsFromCustHierarchy(Map<String, Map<String, Hierarchy__c>> custHierPBMap){

        Set<Id> custHierPBs = new Set<Id>();

        if(!custHierPBMap.isEmpty()){

            for(String custHierTopParent: custHierPBMap.keySet()) {

                for(String custHierNode: custHierPBMap.get(custHierTopParent).keyset()) {

                    if(custHierPBMap.get(custHierTopParent).get(custHierNode).Pricebook__c != null){

                        custHierPBs.add(custHierPBMap.get(custHierTopParent).get(custHierNode).Pricebook__c);
                    }
                }
            }
        }

        return custHierPBs;
    }

    private static List<Pricebook_Line__c> getPBLines(Map<String, Set<Id>> pblQryIds,
                                                      Map<String, Date> pblQryDte,
                                                      Map<String, Decimal> pblQryQty){
        Set<id> companyIds,customerIds,productIds,productGroupIds,
                pricebookIds,soTrasactionCurrency,customerGroupIds;

        Date minDate, maxDate;
        Decimal solMinQty, solMaxQty;

        List<Pricebook_Line__c> pbls = new List<Pricebook_Line__c>();

        companyIds = pblQryIds.get(PricingService.QRY_PBL_PRICING_COMP_IDS);
        customerIds = pblQryIds.get(PricingService.QRY_PBL_PRICING_CUST_IDS);
        customerGroupIds = pblQryIds.get(PricingService.QRY_PBL_PRICING_CUST_GRP_IDS);
        productIds = pblQryIds.get(PricingService.QRY_PBL_PRICING_PROD_IDS);
        productGroupIds = pblQryIds.get(PricingService.QRY_PBL_PRICING_PROD_GRP_IDS);
        soTrasactionCurrency = pblQryIds.get(PricingService.QRY_PBL_PRICING_SO_TRANS_CUR);
        pricebookIds = pblQryIds.get(PricingService.QRY_PBL_PRICING_PRICEBOOK_IDS);

        minDate = pblQryDte.get(PricingService.QRY_PBL_PRICING_MIN_DATE);
        maxDate = pblQryDte.get(PricingService.QRY_PBL_PRICING_MAX_DATE);

        solMinQty = pblQryQty.get(PricingService.QRY_PBL_PRICING_MIN_QTY);
        solMaxQty = pblQryQty.get(PricingService.QRY_PBL_PRICING_MAX_QTY);

        if (!productIds.isEmpty() || !productGroupIds.isEmpty()) {

            SOQLUtil soql = new SOQLUtil('Pricebook_Line__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                    'id', 'Pricebook__c', 'Pricebook__r.Default__c', 'Min__c', 'Max__c', 'Price__c', 'Price_2__c', 'Price_3__c', 'Price_4__c', 'Price_5__c',
                    'Product__c', 'Use_Fixed_Pricing__c', 'Customer__c', 'Pricebook__r.Name', 'Pricebook__r.Currency__c', 'Pricebook__r.Company__c',
                    'Product_Group__c', 'Start_Date__c', 'End_Date__c', 'Price_Type__c', 'Pricing_UOM__c'
            });
            soql.setWhereClause('Pricebook__r.Company__c IN :companyIds and (product__c in :productIds OR Product_Group__c in : productGroupIds) '
                    + ' AND (Pricebook__c IN :pricebookIds OR Pricebook__r.Default__c = true OR Customer__c in :customerIds) '
                    + ' AND ( (Start_Date__c <= :minDate AND (End_Date__c >= : minDate OR End_Date__c = null)) OR '
                    + ' (Start_Date__c <= :maxDate and (End_Date__c >= : maxDate OR End_Date__c = null)) OR '
                    + ' (Start_Date__c >= :minDate AND (End_Date__c <=: maxDate)) ) And '
					+ ' (Use_Fixed_pricing__c = true or ( (Min__c <=:solMinQty or Min__c <= :solMaxQty or min__c = null)  and (Max__c >= :solMinQty or Max__c >= :solMaxQty or Max__c = null) )  )'
//                    + ' (Use_Fixed_pricing__c = true or (Min__c <=:solMinQty and (Max__c >= :solMaxQty OR max__c = null)) OR (Max__c = null AND Min__c = null) )'
                   // + ' and (Price_Type__c = \'Sales\' or Price_Type__c = NULL )'
            );

            try {
                pbls = Database.query(soql.getQuery());
            } catch (Exception e) {
                System.debug(loggingLevel.Error, '*** e.getMessage(): ' + e.getMessage());
                throw e;
            }
        }

        return pbls;
    }

	/**
     *  fetchSOLinesPriceBookInfo will determine the right pricebook line to be matched with the Sales Order line
     *  and returns a map of Sales order line Id and the corresponging Price book line detail.
     *  @param soLines List<Sales_Order_Line__c>
     *  @return Map<Id, Pricebook_Line__c>
     */
	public static Map<String, Pricebook_Line__c> fetchSOLinesPriceBookInfo(List<SObject> sObjects){

        Map<String, Pricebook_Line__c> solIdToPblMap = new Map<String, Pricebook_Line__c>();
        Map<String, Map<String, hierarchy__c>>  custHierPBMap = new Map<String, Map<String, hierarchy__c>>();

        Schema.SObjectType sObjectType = sObjects.getSObjectType();

        Map<String, Set<Id>> pblQryIds = getPBLPricingQueryInfoMap(sObjects);
        Map<String, Date> pblQryDte = getPBLPricingQueryDates(sObjects);
        Map<String, Decimal> pblQryQty = getPBLPricingQueryQty(sObjects);


		if(!pblQryIds.get(PricingService.QRY_PBL_PRICING_CUST_GRP_IDS).isEmpty()){
			//Populate customer hierarchy Pricebooks
			custHierPBMap = getCustomerHierarchyPBPriorityMap(pblQryIds.get(PricingService.QRY_PBL_PRICING_CUST_GRP_IDS));
            pblQryIds.get(PricingService.QRY_PBL_PRICING_PRICEBOOK_IDS).addAll(getPBIdsFromCustHierarchy(custHierPBMap));
		}

        List<Pricebook_Line__c> pbls = getPBLines(pblQryIds, pblQryDte, pblQryQty);

        if (!pbls.isEmpty()){
            solIdToPblMap = mapPBLtoSOBJ(pbls, sObjects, custHierPBMap);
        }

		return solIdToPblMap;
	}

	private static Pricebook_Line__c matchPbl(Pricebook_Line__c pbl, SObject sObj){

        Pricebook_Line__c returnPbl;
        Schema.SObjectType sObjectType = sObj.getSObjectType();
        String priceDeterminationDate = 'NONE';
        Date pricingDate = System.today();
        Decimal pricingQty = 0;

        if(sObjectType == Sales_Order_Line__c.sObjectType){

            Sales_Order_Line__c sol = (Sales_Order_Line__c)sObj;
            pricingDate = sol.Sales_Order__r.Price_Determination_Date__c == SalesOrderService.PRICE_DET_ORDER &&
                            sol.Ordered_Date_Time__c != null ?
                            sol.Ordered_Date_Time__c.date() : sol.Sales_Order__r.Pricing_Date__c;
            pricingDate = pricingDate != null ? pricingDate : system.today();
            pricingQty = sol.Quantity_Ordered__c;

        } else if(sObjectType == Agreement_Line__c.sObjectType){

            Agreement_Line__c agl = (Agreement_Line__c)sObj;
            pricingQty = agl.Sales_Agreement_Quantity__c;
        }

		if (pbl.Start_date__c <= pricingDate && (pbl.End_date__c >= pricingDate || pbl.End_date__c == null)) {
			// assumes if size is greater than 1, using tiered pricing
			if (!pbl.Use_Fixed_Pricing__c &&
					(pbl.Min__c <= pricingQty &&
							(pbl.Max__c >= pricingQty || pbl.Max__c == null))
					&& (pbl.Min__c != null && pbl.Max__c != 0) ) {

				returnPbl = pbl;

			} else if (pbl.Use_Fixed_Pricing__c) {
				returnPbl = pbl;
			} else if (!pbl.Use_Fixed_Pricing__c
					&& ((pbl.Min__c == null && pbl.Max__c == null) || (pbl.Min__c == 0 && pbl.Max__c == 0)))
			{     // bracketted price
				returnPbl = pbl;
			} else if (!pbl.Use_Fixed_Pricing__c && pricingQty == null){
				returnPbl = pbl;
			}

			else {
				System.debug(logginglevel.Error, 'Incorrect pbl: ' + pbl);
			}
		}

		return returnPbl;
	}

    /*
     *
     *
     *
     */
	public static Map<String, Map<String, Hierarchy__c>> getCustomerHierarchyPBPriorityMap(Set<Id> customerGroupIds){

		if(customerGroupIds.isEmpty()){
			return new Map<String, Map<String, Hierarchy__c>>();
		}
		Set<String> custGroupIds = new Set<String>();
		for(Id customerGroupId: customerGroupIds) {
			custGroupIds.add(String.valueOf(customerGroupId).substring(0,15));
		}

		//Check if the customer is part of a customer group
		List<Hierarchy__c> hierarchyNodes = [Select id,
				name,
				code__c,
				parent_code__c,
				top_parent_code__c,
				pricebook__c
		from hierarchy__c
		where Type__c = 'Customer Hierarchy'
		and code__c in :custGroupIds];

		Map<String, Map<String, Hierarchy__c>> customerHierarchiesMap = new Map<String, Map<String, Hierarchy__c>>();
		if(!hierarchyNodes.isEmpty()){

			Set<String> topParentCodes = new Set<String>();
			//Fetch unique top parent code (Means more than one customer hierarchy)
			for(Hierarchy__c hNode: hierarchyNodes){
				topParentCodes.add(hNode.top_parent_code__c);
			}

			//If top parent codes set is empty return
			if(topParentCodes.isEmpty()){
				return customerHierarchiesMap;
			}

			//Check if the customer group is part of a hierarchy
			List<Hierarchy__c> customerHierarchies = [Select id,
					name,
					code__c,
					parent_code__c,
					top_parent_code__c,
					pricebook__c
			from hierarchy__c
			where Type__c = 'Customer Hierarchy'
			and top_parent_code__c in :topParentCodes];

			if(customerHierarchies.size() > 0){

				for(Hierarchy__c cHierarchy: customerHierarchies){

					Map<String, Hierarchy__c> custHierMap;
					if(customerHierarchiesMap.containsKey(cHierarchy.Top_Parent_Code__c)){
						custHierMap = customerHierarchiesMap.get(cHierarchy.Top_Parent_Code__c);
						//custHierMap.put(cHierarchy.Code__c, cHierarchy);
						//customerHierarchiesMap.put(cHierarchy.Top_Parent_Code__c, custHierMap);
					} else {
						custHierMap = new Map<String, Hierarchy__c>();

					}
					custHierMap.put(cHierarchy.Code__c, cHierarchy);
					customerHierarchiesMap.put(cHierarchy.Top_Parent_Code__c, custHierMap);
				}
			}
		}

		//Build Pricebook priority map for customer hierarchy
		return customerHierarchiesMap;
	}

	private static Integer priceBookIndexOnCustomerHierarchy(Map<String, Map<String, hierarchy__c>> custHierPBMap,
			Id custGroupId,
			Id priceBookId){

		Integer retIndx = 10000;
		if(custGroupId == null){
			return retIndx;
		}

		String customerGroupId = String.valueOf(custGroupId).substring(0,15);

		for(String custHierTopParent: custHierPBMap.keySet()) {

			Integer tempIndex = -1;
			Boolean traverseHierarchy = true;
			Map<String, hierarchy__c> hierMap = custHierPBMap.get(custHierTopParent);

			Boolean pbHierNodeMatch = false;
			while(hierMap.containsKey(customerGroupId)){
				hierarchy__c custHierNode = hierMap.get(customerGroupId);

				tempIndex = tempIndex + 1;
				if(custHierNode.Pricebook__c != null && custHierNode.Pricebook__c == priceBookId){
					pbHierNodeMatch = true;
					break;
				}

				if(custHierNode.Parent_Code__c != null){
					customerGroupId = custHierNode.Parent_Code__c;
				} else{
					break;
				}
			}
			//On first match break out of loop. Avoid looking at other customer hierarchies
			if(pbHierNodeMatch){
				retIndx = tempIndex;
				break;
			}

		}

		return retIndx;
	}

	private static Map<String, Pricebook_Line__c> mapPBLtoSOBJ(List<Pricebook_Line__c> pbls,
                                                              List<SObject> sObjects,
                                                              Map<String, Map<String, Hierarchy__c>> cGPBPriorityMap){

        Schema.SObjectType sObjectType = sObjects.getSObjectType();
        Map<String, Pricebook_Line__c> sObjIdToPblMap = new Map<String, Pricebook_Line__c>();

		Map<Id, List<Pricebook_Line__c>> prodIdToPBLSMap = mapProdIdToPBLS(pbls);

		//Get customer hierarchy priority map
		Map<String, Map<String, Hierarchy__c>> custHierarchyPBPriority = cGPBPriorityMap;
		try {

			for(SObject sObj: sObjects) {
                string key;
                Product__c prod;
                Sales_Order_Line__c soLine;
                Agreement_Line__c agLine;

                if(sObjectType == Sales_Order_Line__c.sObjectType) {
                    soLine = (Sales_Order_Line__c)sObj;
                    //Product is available on both SO Line and Agreement Line
                    prod = soLine.Product__r;
                } else if(sObjectType == Agreement_Line__c.sObjectType){
                    agLine = (Agreement_Line__c)sObj;
                    //Product is available on both SO Line and Agreement Line
                    prod = agLine.Product__r;
                }

				Pricebook_Line__c priceBookLine = new Pricebook_Line__c();

				List<Pricebook_line__c> solPbls = new List<Pricebook_line__c>();

				//Add product PBLs
				if(prodIdToPBLSMap.containsKey(prod.Id)){
					solPbls.addAll(prodIdToPBLSMap.get(prod.Id));
				}

				//Add product group PBLs
				if(prod.Product_Group__c != null && prodIdToPBLSMap.containsKey(prod.Product_Group__c)){

					solPbls.addAll(prodIdToPBLSMap.get(prod.Product_Group__c));
				}

				if(!solPbls.isEmpty()){
					String soPricebookId = null;
					String customerSoldToPricebookId = null;
					String soldToCustomer = null;
					String soCurrency = null;
                    String sObjPriceType = '';
					Id custGroupId = null;

                    if(sObjectType == Sales_Order_Line__c.sObjectType){
                        Sales_Order__c salesOrder = soLine.Sales_Order__r;
                        if(salesOrder != null){
                            if (salesOrder.Id != null) {
                                key = salesOrder.Id;
                            }else{
                                key = 'newso';
                            }
                            custGroupId = salesOrder.Customer__c != null ? salesOrder.Customer__r.Customer_Group__c : null;
                            soPricebookId = salesOrder.Pricebook__c == null ? null : salesOrder.Pricebook__c;
                            customerSoldToPricebookId = salesOrder.Customer__r != null && salesOrder.Customer__r.Pricebook__c != null ? salesOrder.Customer__r.Pricebook__c : null;
                            soldToCustomer = salesOrder.Customer__c == null ? null : String.valueOf(salesOrder.Customer__c);
                            soCurrency = salesOrder.Currency__c;
                        }
                    } else if(sObjectType == Agreement_Line__c.sObjectType){
                        Agreement__c agreement = agLine.Agreement__r;
                        if(agreement != null){
                            key = agreement.Id;
                            custGroupId = agreement.Sold_To__c != null ? agreement.Sold_To__r.Customer_Group__c : null;
                            customerSoldToPricebookId = agreement.Sold_To__r != null && agreement.Sold_To__r.Pricebook__c != null ? agreement.Sold_To__r.Pricebook__c : null;
                            soldToCustomer = agreement.Sold_To__c == null ? null : String.valueOf(agreement.Sold_To__c);
                            soCurrency = agreement.Currency__c;
                            sObjPriceType = agLine.Price_Type__c != null ? agLine.Price_Type__c : '';
                        }
                    }

                    /*
                     * priceBookPriority map is used to find the right price book for a product based on conditions
                     * and priority. Eg. If the Sales Order Line has a price book then the price of the product
                     * should be pulled out from the Sales Order Line price book, provided the product is there on
                     * the price book line. If the product is not available then we will find the price from the
                     * next best priority Price book. If none of the price book has product information then we will return
                     * empty price book information.
                     *
                     */
					Map<String, Integer> priceBookPriority = new Map<String, Integer>{'PBLCustomer' => 0,
					'line' => 1,
					'header' => 2,
					'customer' => 3,
					'customerHierarchy' => 4,
					'company' => 5,
					'others' => 6};
					Integer currentPriceBookPriority = 9999;
					Integer currentCHPriority = 9999;

					for(Pricebook_Line__c pbLine: solPbls){
                        //Skip PBL if following conditions are met
                        if((pbLine.Price_Type__c != null &&
                            pbLine.Price_Type__c.equals(PricingService.PRICE_TYPE_RECURRING) &&
                            !sObjPriceType.equals(PricingService.PRICE_TYPE_RECURRING)) ||

                           (pbLine.Price_Type__c != null &&
                            pbLine.Price_Type__c.equals(PricingService.PRICE_TYPE_SALES) &&
                            sObjPriceType.equals(PricingService.PRICE_TYPE_RECURRING) ||

                           (pbLine.Price_Type__c == null &&
                            sObjPriceType.equals(PricingService.PRICE_TYPE_RECURRING))) ||

                           (pbLine.Price_Type__c != null &&
                            pbLine.Price_Type__c.equals(PricingService.PRICE_TYPE_RECURRING) &&
                            sObjPriceType.equals(PricingService.PRICE_TYPE_RECURRING) &&
                            pbLine.Pricing_UOM__c != null &&
                            pbLine.Pricing_UOM__c != sObj.get('Pricing_UOM__c'))){

                            continue;
                        }

						if (pbLine.Pricebook__r.Currency__c == soCurrency){

							Pricebook_Line__c tempPBLine;
							if (priceBookPriority.get('PBLCustomer') <= currentPriceBookPriority &&
									pbLine.Customer__c != null &&
									pbLine.Customer__c == soldToCustomer){

								if (priceBookLine.price__c == null || priceBookLine.Customer__c == null || pbLine.price__c < priceBookLine.price__c){
									tempPBLine = matchPbl(pbLine, sObj);
									priceBookLine = tempPBLine != null ? tempPBLine : priceBookLine;
									currentPriceBookPriority = priceBookPriority.get('PBLCustomer');
								}

							} else if(priceBookPriority.get('line') <= currentPriceBookPriority &&
									pbLine.Pricebook__r.Id == sObj.get('Pricebook__c') &&
                                    pbLine.Customer__c == null){

								tempPBLine = matchPbl(pbLine, sObj);

								if(tempPBLine != null){
									priceBookLine = tempPBLine;
									currentPriceBookPriority = priceBookPriority.get('line');
								}
							} else if(priceBookPriority.get('header') <= currentPriceBookPriority &&
									pbLine.Pricebook__r.Id == soPricebookId &&
                                    pbLine.Customer__c == null){

								if (priceBookPriority.get('header') < currentPriceBookPriority) {
									tempPBLine = matchPbl(pbLine, sObj);
									if(tempPBLine != null){
										priceBookLine = tempPBLine;
										currentPriceBookPriority = priceBookPriority.get('header');
									}
								}
							} else if(priceBookPriority.get('customer') <= currentPriceBookPriority &&
									pbLine.Pricebook__r.Id == customerSoldToPricebookId &&
                                    pbLine.Customer__c == null){

								if (priceBookPriority.get('customer') < currentPriceBookPriority) {
									tempPBLine = matchPbl(pbLine, sObj);
									if(tempPBLine != null){
										priceBookLine = tempPBLine;
										currentPriceBookPriority = priceBookPriority.get('customer');
									}
								}
							} else if(priceBookPriority.get('customerHierarchy') <= currentPriceBookPriority &&
									currentCHPriority >= priceBookIndexOnCustomerHierarchy(custHierarchyPBPriority, custGroupId, pbLine.Pricebook__r.Id) &&
                                    pbLine.Customer__c == null){

								tempPBLine = matchPbl(pbLine, sObj);
								if(tempPBLine != null){
									priceBookLine = tempPBLine;
									currentPriceBookPriority = priceBookPriority.get('customerHierarchy');
									currentCHPriority = priceBookIndexOnCustomerHierarchy(custHierarchyPBPriority, custGroupId, pbLine.Pricebook__r.Id);
								}
							} else if(priceBookPriority.get('company') <= currentPriceBookPriority &&
									pbLine.Pricebook__r.Default__c == true &&
                                    pbLine.Customer__c == null){

								tempPBLine = matchPbl(pbLine, sObj);
								if(tempPBLine != null){
									priceBookLine = tempPBLine;
									currentPriceBookPriority = priceBookPriority.get('company');
								}
							}
						}
					}
				}
				if(priceBookLine != null){

                    sObjIdToPblMap.put(key + '-' + sObj.get('Line__c'), priceBookLine);
				}
			}
		} catch(Exception e) {
			System.debug(loggingLevel.Error, '*** e.getMessage(): ' + e.getMessage());
		}

		return sObjIdToPblMap;
	}
	//To Do add product group clause
	private static Map<id, List<Pricebook_Line__c>> mapProdIdToPBLS(List<Pricebook_Line__c> pbls){

		Map<id, List<Pricebook_Line__c>> prodIdToPBLSMap = new Map<id, List<Pricebook_Line__c>>();
		try {
			for(Pricebook_Line__c pbl: pbls) {
				List<Pricebook_Line__c> tPbls;
				Id pblKey;

				if(pbl.Product__c != null){
					pblKey = pbl.Product__c;

				} else if(pbl.Product_Group__c != null){
					pblKey = pbl.Product_Group__c;
				}

				if(prodIdToPBLSMap.containsKey(pbl.Product__c)){

					tPbls = prodIdToPBLSMap.get(pbl.Product__c);
				} else{

					tPbls = new List<Pricebook_Line__c>();
				}

				if(tPbls != null && pblKey != null){
					tPbls.add(pbl);
					prodIdToPBLSMap.put(pblKey,tPbls);
				}

			}
		} catch(Exception e) {
			System.debug(loggingLevel.Error, '*** e.getMessage(): ' + e.getMessage());
		}

		return prodIdToPBLSMap;

	}

	public static void agreementLinePricing(List<Agreement_Line__c> agreementLines){

		List<PricingDefinition> pds = new List<PricingDefinition>();

		for(Agreement_Line__c agl : agreementLines){

			//clean the data
			agl.Agreement_Price__c = agl.Agreement_Price__c == null ? 0 : agl.Agreement_Price__c;
			agl.Sales_Agreement_Quantity__c = agl.Sales_Agreement_Quantity__c == null ? 0 : agl.Sales_Agreement_Quantity__c;

			PricingDefinition iPD = new PricingDefinition();
			iPD.recordId = agl.Id;
			iPD.rateBasis = getRateBasis(agl.Rate_Basis__c);
			iPD.occurrence = getOccurrence(agl.Pricing_UOM_Recurrence__c);
			iPD.every = getEvery(agl.Pricing_UOM_Every__c);
			iPD.customerId = agl.Agreement__r.Customer__c;
			iPD.pricebookId = null;
			iPD.productId = agl.Product__c;
			iPD.quantity = agl.Sales_Agreement_Quantity__c;
			iPD.startDate = agl.Start_Date__c;
			iPD.endDate = agl.End_Date__c;
			iPD.recurrenceDate = agl.Agreement__r.Recurrence_Start_Date__c;
			pds.add(iPD);

			//TODO: Stub out SOLs from AGLs to feed SOLS.validateSalesOrderLinePrices... - map back to List Price field
			Date sd = iPD.startDate == null ? system.today() : Date.newInstance(iPD.startDate.year(), iPD.startDate.month(), iPD.startDate.day());
			Date ed = iPD.endDate == null ? system.today() : Date.newInstance(iPD.endDate.year(), iPD.endDate.month(), iPD.endDate.day());
			decimal qtyMult = iPD.rateBasis == RateBasis.FLAT ? 1 : iPD.quantity;
			decimal occMult = occurrenceMultiplier(sd, ed, iPD.occurrence, sd.day(),iPD.every);
			//system.debug('qtyMult: ' + qtyMult);
			//system.debug('occMult: ' + occMult);
			//system.debug('agreementPrice: ' + agl.Agreement_Price__c);
			//Simple solution:
			//KNDY-10358: Added if conditions for Usage Scenario
			if(agl.Usage_Based__c == TRUE && agl.Rate_Basis__c != 'Flat') {
				agl.line_total__c = qtyMult * agl.Agreement_Price__c;
			} else {
				agl.line_total__c = qtyMult * occMult * agl.Agreement_Price__c;
			}

		}

	}

	public static void salesOrderLinePricing(List<Sales_Order_Line__c> salesOrderLines){

		List<PricingDefinition> pds = new List<PricingDefinition>();

		for(Sales_Order_Line__c sol : salesOrderLines){

			//clean the data
			//sol.Unit_Price__c = sol.Unit_Price__c == null ? 0 : sol.Unit_Price__c;
			sol.Quantity_Ordered__c = sol.Quantity_Ordered__c == null ? 0 : sol.Quantity_Ordered__c;
			sol.Off_Invoice_Rate__c = sol.Off_Invoice_Rate__c == null ? 0 : sol.Off_Invoice_Rate__c;
			sol.Allowances__c = sol.Allowances__c == null ? 0 : sol.Allowances__c;
			sol.Freight_Allowance__c = sol.Freight_Allowance__c == null ? 0 : sol.Freight_Allowance__c;
			sol.Discount_Percent__c = sol.Discount_Percent__c == null ? 0 : sol.Discount_Percent__c;

			PricingDefinition iPD = new PricingDefinition();
			iPD.recordId = sol.Id;
			iPD.rateBasis = getRateBasis(sol.Rate_Basis__c);
			iPD.occurrence = getOccurrence(sol.Pricing_UOM_Recurrence__c);
			iPD.every = getEvery(sol.Pricing_UOM_Every__c);
			iPD.customerId = sol.Customer_ID__c;
			iPD.pricebookId = sol.Pricebook__c;
			iPD.productId = sol.Product__c;
			iPD.quantity = sol.Quantity_Ordered__c;
			iPD.startDate = sol.Start_Date__c;
			iPD.endDate = sol.End_Date__c;
			iPD.recurrenceDate = sol.Sales_Order__r.Recurrence_Start_Date__c;
			pds.add(iPD);

			Date sd = iPD.startDate == null ? system.today() : Date.newInstance(iPD.startDate.year(), iPD.startDate.month(), iPD.startDate.day());
			Date ed = iPD.endDate == null ? system.today() : Date.newInstance(iPD.endDate.year(), iPD.endDate.month(), iPD.endDate.day());
			decimal qtyMult = iPD.rateBasis == RateBasis.FLAT ? 1 : iPD.quantity;
			decimal occMult = occurrenceMultiplier(sd, ed, iPD.occurrence, sd.day(),ipd.every);
			//system.debug('qtyMult: ' + qtyMult);
			//system.debug('occMult: ' + occMult);
			//Simple solution:
			//KNDY-10358: Added if conditions for Usage Scenario
			if (sol.Quantity_Fulfilled__c == 0) {
                if(sol.Usage_Based__c == TRUE && sol.Rate_Basis__c != 'Flat') {
                    sol.Line_Total__c = returnPrice(qtyMult, sol.Unit_Price__c == null ? 0 : sol.Unit_Price__c, sol.Off_Invoice_Rate__c, sol.Allowances__c, sol.Freight_Allowance__c, sol.Discount_Percent__c);
                } else {
                    sol.Line_Total__c = occMult * returnPrice(qtyMult, sol.Unit_Price__c == null ? 0 : sol.Unit_Price__c, sol.Off_Invoice_Rate__c, sol.Allowances__c, sol.Freight_Allowance__c, sol.Discount_Percent__c);
                }
		    }
	    }
	}

	public static void customerInvoiceBestPricing(List<Customer_Invoice_Line__c> lstMCILs, Map<String, DateTime> cilFulfShipDateMap){
		System.debug( '\n');

		Map<SObject, List<PricingResult>> mBestPrices = new Map<SObject, List<PricingResult>>();

		try {
			Map<SObject, List<Pricebook_Line__c>> mCustomerInvoiceLines = PricingService.getPriceBookLines( lstMCILs, PriceType.RECURRING );
			// if no pricebook lines are found, error will be thrown and we will not continue.
			mBestPrices = PricingService.calculateBestPrice( mCustomerInvoiceLines, cilFulfShipDateMap );
		} catch (Exception e){
			system.debug( e + '\n\n' + e.getStackTraceString());
			return;
		}

		System.debug( logginglevel.error, '~*~ Final mBestPrice :' + PricingService.debugBestPricesString(mBestPrices) );

		// update CIL Unit Price to be used in the AllowancesOperations later on
		for(Customer_Invoice_Line__c cil : lstMCILs){
			if(cil.Price_Type__c == PriceType.RECURRING.name()) {

				if(mBestPrices.containsKey(cil) && !mBestPrices.get( cil ).isEmpty() ) {

					decimal bestPrice;
					Decimal cilSize = mBestPrices.get( cil ).size();
					Uom__c pricingUOM;
					// When running through invocing, we will have multiple pricingResults if bestprice is used.
					// Inovoicing doesn't properly separate the pricing UOMs according to bestprice

					for ( PricingResult mPR : mBestPrices.get( cil ) ) {
						pricingUOM = mPR.pricingUOM;
						if ( bestPrice == null ) {
							bestPrice = mPR.bestPrice;
						}
						else {
							bestPrice += mPR.bestPrice;
						}
						System.debug(  '~*~ pLogic - assigning pricing UOM to CIL: ' + mPR.pricingUOM.Name + ' ' + bestPrice );

					}

					// since CIL is the key to the bestPrice map, we have to be careful as modifying it below will render the keycomp useless.
					if (bestPrice != null) {
						cil.Unit_Price__c = bestPrice;
					}
					// in the instance that multiple UOMs are assigned to a CIL period, we know then that Best Price was used. For this reason, that this period is the billing period.
					if (cilSize > 1 ) {
						cil.Pricing_UOM__c = cil.Agreement_Line__r.Agreement__r.Billing_Uom__c;
					}
					// in the instance that only one UOM is assigned to the CIL period, then we know that the pricing UOM for the CIL is that UOM
					else if ( cilSize == 1 ) {
						cil.Pricing_UOM__c = pricingUOM.Id;
					}
				}

			}
		}
	}

	public static void customerInvoiceLinePricing(List<Customer_Invoice_Line__c> customerInvoiceLines){

		List<PricingDefinition> pds = new List<PricingDefinition>();

		Map<SObject, List<Pricebook_Line__c>> mCilPbl = new Map<SObject, List<Pricebook_Line__c>>();
		Boolean useBestPrice = false;
		try {
			mCilPbl = PricingService.getPriceBookLines(customerInvoiceLines, PriceType.RECURRING);

		} catch (Exception e) {
			useBestPrice = false;
			system.debug(e + ' - ' + e.getStackTraceString());
		}

		Configuration__c bpPblConfig = Configuration__c.getValues('Best_Price_Pricebook_Required');
		Boolean usePricebook = True;
		if (bpPblConfig != null) {
			try {
				usePricebook = Boolean.valueOf(bpPblConfig.Value__c);
			} catch (Exception e) {
				System.debug( logginglevel.error, '~*~ \n' + e.getStackTraceString() );
			}
		}

		for(Customer_Invoice_Line__c cil : customerInvoiceLines){
			System.debug( '\n');

			if(cil.Price_Type__c == PriceType.RECURRING.name()) {
				if(mCilPbl != null && mCilPbl.containsKey(cil)) {
					if ((mCilPbl.get(cil) != null && mCilPbl.get(cil).size() > 0) || !usePricebook) {
						useBestPrice = true;
					}
				}
			}

			system.debug('cil.Unit_Price__c' + cil.Unit_Price__c);
			//clean the data
			cil.Unit_Price__c = cil.Unit_Price__c == null ? 0 : cil.Unit_Price__c;
			cil.Quantity_Shipped__c = cil.Quantity_Shipped__c == null ? 0 : cil.Quantity_Shipped__c;
			cil.Off_Invoice_Rate__c = cil.Off_Invoice_Rate__c == null ? 0 : cil.Off_Invoice_Rate__c;
			cil.Allowances__c = cil.Allowances__c == null ? 0 : cil.Allowances__c;
			cil.Freight_Allowance__c = cil.Freight_Allowance__c == null ? 0 : cil.Freight_Allowance__c;
			cil.Discount_Percent__c = cil.Discount_Percent__c == null ? 0 : cil.Discount_Percent__c;

			PricingDefinition iPD = new PricingDefinition();
			iPD.recordId = cil.Id;
			iPD.rateBasis = getRateBasis(cil.Rate_Basis__c);
			iPD.occurrence = getOccurrence(cil.Pricing_UOM_Recurrence__c);
			iPD.every = getEvery(cil.Pricing_UOM_Every__c);
			//iPD.customerId = cil.Customer_ID__c;
			//iPD.pricebookId = cil.Pricebook__c;
			iPD.productId = cil.Product__c;
			iPD.quantity = cil.Quantity_Shipped__c;
			iPD.startDate = cil.Start_Date__c;
			iPD.endDate = cil.End_Date__c;
			iPD.recurrenceDate = cil.Recurrence_Start_Date__c;
			pds.add(iPD);
			system.debug('iPd '+iPD);
			Date sd = iPD.startDate == null ? system.today() : Date.newInstance(iPD.startDate.year(), iPD.startDate.month(), iPD.startDate.day());
			Date ed = iPD.endDate == null ? system.today() : Date.newInstance(iPD.endDate.year(), iPD.endDate.month(), iPD.endDate.day());
			decimal qtyMult = iPD.rateBasis == RateBasis.FLAT ? 1 : iPD.quantity;
			decimal occMult = occurrenceMultiplier(sd, ed, iPD.occurrence, cil.Recurrence_Start_Date__c == null ? 0 : cil.Recurrence_Start_Date__c.date().day(),ipd.every);

			System.debug( '\n');
			system.debug('qtyMult: ' + qtyMult);
			system.debug('occMult: ' + occMult);

			//Simple solution:
			//KNDY-10358: Added if conditions for Usage Scenario
			system.debug('useBestPrice '+useBestPrice);
			if( useBestPrice == true || (cil.Usage_Based__c == TRUE && cil.Rate_Basis__c != 'Flat')) { //KNDY-15051 re-arranged the condition to consider best price first and added proper brackets
				cil.Extended_Price__c = returnPrice(qtyMult, cil.Unit_Price__c, cil.Off_Invoice_Rate__c, cil.Allowances__c, cil.Freight_Allowance__c, cil.Discount_Percent__c).setScale(2, System.RoundingMode.HALF_UP);//KNDY-11850,KNDY-19118;
			} else {
				cil.Extended_Price__c = (occMult * returnPrice(qtyMult, cil.Unit_Price__c, cil.Off_Invoice_Rate__c, cil.Allowances__c, cil.Freight_Allowance__c, cil.Discount_Percent__c)).setScale(2, System.RoundingMode.HALF_UP);//KNDY-11850;
			}
		}
	}

	public static decimal returnPrice(decimal qtyMult, decimal unitPrice, decimal offInvoiceRate, decimal allowances, decimal freightAllowances, decimal discountPercent){

		qtyMult = qtyMult == null ? 1 : qtyMult;
		unitPrice = unitPrice == null ? 0 : unitPrice;
		offInvoiceRate = offInvoiceRate == null ? 0 : offInvoiceRate;
		allowances = allowances == null ? 0 : allowances;
		freightAllowances = freightAllowances == null ? 0 : freightAllowances;
		discountPercent = discountPercent == null ? 0 : discountPercent;

		return (qtyMult * (unitPrice - offInvoiceRate) * (1 - (discountPercent / 100)) + allowances - freightAllowances).setScale(2,System.RoundingMode.HALF_UP);//KNDY-19536
	}

	public static decimal occurrenceMultiplier(Date startDate, Date endDate, Occurrence occ, integer invoiceOn, Integer every){
		map<Occurrence, Integer> mOccMult = new map<Occurrence, Integer>{Occurrence.MONTH => 1, Occurrence.QUARTER => 3, Occurrence.YEAR => 12};
		map<Occurrence, String> mOcc = new map<Occurrence, String> {Occurrence.MONTH => FrequencyService.FREQUENCY_PERIOD_MONTH, Occurrence.QUARTER => FrequencyService.FREQUENCY_PERIOD_QUARTER, Occurrence.YEAR => FrequencyService.FREQUENCY_PERIOD_ANNUAL};
		decimal occMult = 1;
		decimal everyD = Decimal.valueOf(every);
		if(occ == Occurrence.DAY) {
			occMult = (decimal.valueOf(startDate.daysBetween(endDate)))/everyD;

		} else if(occ == Occurrence.WEEK) {
			occMult = decimal.valueOf(startDate.daysBetween(endDate)) / (7 * everyD);

		}else if(mOccMult.containsKey(occ) && endDate != null && endDate > startDate){

			integer intervalBetween = startDate.monthsBetween(endDate);
			integer totalOccurrences = integer.valueOf(math.floor(intervalBetween/(mOccMult.get(occ) * everyD)));
			system.debug(LoggingLevel.INFO, 'total full Occurrences: ' + totalOccurrences);
			Date toDate = startDate;// = startDate.addMonths(totalOccurrences*mOccMult.get(occ));
			system.debug('invoiceOn '+invoiceOn);
			system.debug('toDate '+toDate);
			for(integer i= 1; i <= totalOccurrences; ++i) {
				toDate  =  FrequencyService.nextBillingDate(mOcc.get(occ), toDate,invoiceOn,every);
			}

			decimal proRate = 0;
			if(endDate != toDate){
				//+1 to be inclusive of the final date
				system.debug('numDays: ' + decimal.valueOf(toDate.daysBetween(endDate) + 1));
				system.debug('overDays: ' + decimal.valueOf(toDate.daysBetween(toDate.addMonths(mOccMult.get(occ)))));
				proRate = decimal.valueOf(toDate.daysBetween(endDate) + 1)/decimal.valueOf(toDate.daysBetween(toDate.addMonths(mOccMult.get(occ))));
				system.debug('proRate: ' + proRate);
			}
			occMult = totalOccurrences + proRate;
		}
		return occMult;
	}


	public static Map<SObject, List<PricingResult>> calculateBestPrice(Map<SObject, List<Pricebook_Line__c>> mRecordsToPBLineMap){
		return calculateBestPrice(mRecordsToPBLineMap, null);
	}

	public static Map<SObject, List<PricingResult>>  calculateBestPrice(Map<SObject, List<Pricebook_Line__c>> mRecordsToPBLineMap, Map<String, DateTime> cilFulfShipDateMap) {

		Map<SObject, List<PricingResult>> mBestPrices = new Map<SObject, List<PricingResult>>();

		Configuration__c bpPblConfig = Configuration__c.getValues('Best_Price_Pricebook_Required');
		Boolean usePricebook = True;
		if (bpPblConfig != null) {
			try {
				usePricebook = Boolean.valueOf(bpPblConfig.Value__c);
			} catch (Exception e) {
				System.debug( logginglevel.error, '~*~ \n' + e.getStackTraceString() );
			}
		}

		for(SObject s : mRecordsToPBLineMap.keySet()) {
			List<Pricebook_Line__c> pbLines =  new List<Pricebook_Line__c>();
			if(mRecordsToPBLineMap.containsKey(s)){
				pbLines = mRecordsToPBLineMap.get(s);
			}
            system.debug('pLogic - pbLines at cil '+pbLines);
			if(pbLines != null && !pbLines.isEmpty()) {

				DateTime rSDT = ( DateTime ) s.get( 'Start_Date__c' );
				Date rStartDate = rSDT.Date();

				DateTime rEDT = ( DateTime ) s.get( 'End_Date__c' );
				Date rEndDate = rEDT.Date();

				List<Pricebook_Line__c> validPbls = new List<Pricebook_Line__c>();
				for (Pricebook_Line__c pbl: pbLines) {

					if ((pbl.Start_Date__c <= rStartDate || rStartDate == null) && (pbl.End_Date__c >= rEndDate || rEndDate == null)) {
						validPbls.add( pbl );
					} else {
						System.debug(   '~*~ pbl :' + pbl.Start_Date__c + ' ' +  pbl.End_Date__c + '\n' + pbl );
					}
				}

				if (validPbls.isEmpty()){
					throw new PricingServiceException('Matching Pricebook Lines have expired dates. Unable to calculate best price.');
				}

				List<PricingResult> bestPrice = calculateBestPrice(s, validPbls, cilFulfShipDateMap);
				mBestPrices.put(s, bestPrice);
			}
			else if (!usePricebook){
				List<PricingResult> bestPrice = calculateBestPrice(s, new List<Pricebook_Line__c>(), cilFulfShipDateMap);
				mBestPrices.put(s, bestPrice);
			}

			else {
				throw new PricingServiceException('No Matching Pricebook Lines found to calculate the best price');
			}
		}

		return mBestPrices;
	}

	public static Integer getMaxPBLIndex(List<PblSortByPricingUOM> pbLines, string sObjectName, SObject record, Id agreementBillingUId, Map<Integer, Decimal> mLinePrices){
		Integer i = null;

		// determine pbl treshhold. Work downward.
		for (Integer pbLInx = pbLines.size() - 1; pbLInx >= 0; pbLInx --){

			Boolean fulfillmentBillingUomMatchesPBL = (util.fieldExists(sObjectName, 'Billing_UOM__c') && pbLines[pbLInx].pbLine.Pricing_UOM__c == (Id) record.get('Billing_Uom__c'));
			Boolean cilAgreementBillingUomMatchesPBL = agreementBillingUId == pbLines[pbLInx].pbLine.Pricing_UOM__c;
			Boolean agreementLinePricingUomMatchesPBL = pbLines[pbLInx].pbLine.Pricing_UOM__c == (Id) record.get('Pricing_Uom__c');

			// perform this task only once (iterating backwards)
			if ( i == null && (fulfillmentBillingUomMatchesPBL || agreementLinePricingUomMatchesPBL || cilAgreementBillingUomMatchesPBL)){
				i = pbLInx; // starting Index
				System.debug( logginglevel.error, '~*~ Pricing threshold met: ' + pbLInx + ' - ' + pbLines[pbLInx].pbLine.Pricing_UOM__r.Name + ' ' + mLinePrices.get(i));
			}
			System.debug( '\n');
		}


		if (i == null &&  pbLines.size() != 0){
			System.debug( logginglevel.error,  '~*~ plogic No Index found :');
			i =  pbLines.size()-1;
		}

		return i;


	}

	static SchemaUtil util = SchemaUtil.getInstance();

	public static List<PricingResult> calculateBestPrice(SObject record, List<Pricebook_Line__c> pricebookLines, Map<String, DateTime> aglEarliestShippedDate) {


		string sObjectName = record.getSObjectType().getDescribe().getName();

		//Aggregated Best Price for comparison
		List<PblSortByPricingUOM> pbLines = new List<PblSortByPricingUOM>();

		for(Pricebook_Line__c pbl : pricebookLines) {
			PblSortByPricingUOM pbLine = new PblSortByPricingUOM(pbl);
			pbLines.add(pbLine);
		}
		//Sort the Pricebook lines so we can iterate through them in order of number of days
		pbLines.sort();

		Agreement_Line__c agl = (Agreement_Line__c) record.getSObject('Agreement_Line__r');

		Integer pricesFound = pricebookLines.size() == 0 && agl.Agreement_Price__c != null ? 1 : pbLines.size();
		Map<Integer, Decimal> mLinePrices = getLinePrices(record, pbLines);
		Map<Integer, Decimal> mpriceBreakingPoints = getPriceBreakingPoints(mLinePrices);

		System.debug( logginglevel.error, '~*~ mLinePrices :' + mLinePrices );
		System.debug( logginglevel.error, '~*~ mpriceBreakingPoints :' + mpriceBreakingPoints );



		Date cilExeStartDate;
		Id agreementBillingUId;
		if ( record.getSObjectType() == Customer_Invoice_Line__c.getSObjectType() && record.get('Source_Key__c') != null){

			if (agl != null && agl.Agreement__r != null && agl.Agreement__r.Billing_UOM__c != null){
				agreementBillingUId = agl.Agreement__r.Billing_UOM__c;
			}
			cilExeStartDate = aglEarliestShippedDate.get( (string) record.get('Source_Key__c') ).date(); //((DateTime) record.getSObject('Agreement_Line__r').get('Start_Date__c')).date();
		}

		Map<Id,PricingDefinition> iPDMap = new Map<Id,PricingDefinition>();

		System.debug(   '~*~ pLogic pbLines.size(): ' + pbLines.size() );
		Integer i = getMaxPBLIndex(pbLines, sObjectName, record, agreementBillingUId, mLinePrices); //

		Uom__c pricingUom = i != null ? pbLines[i].pbLine.Pricing_UOM__r : (UOM__c) record.getSObject('Pricing_UOM__r');

		System.debug( logginglevel.error, '~*~ agl :' + agl );
		System.debug( logginglevel.error, '~*~ pricingUom :' + pricingUom );

		PricingDefinition iPD = new PricingDefinition();
//		iPD.recordId = record.Id;
		iPD.occurrence = getOccurrence(pricingUom.Recurrence__c);
//		iPD.pricebookId = pbLines[i].pbLine.Pricebook__c;
//		iPD.productId = (Id)record.get('Product__c');
//		iPD.quantity = getQuantity(record);
		iPD.startDate = (Datetime)record.get('Start_Date__c');
		iPD.endDate = (Datetime)record.get('End_Date__c');
		iPD.recurrenceDate = (Datetime)record.get('Recurrence_Start_Date__c');
		iPDMap.put(pricingUom.Id, iPD);

		system.debug('(dtTest) iPD.startDate: ' + iPD.startDate);
		system.debug('(dtTest) iPD.endDate: ' + iPD.endDate);
		system.debug('(dtTest) iPD.recurrenceDate: ' + iPD.recurrenceDate);

		Datetime lastBillDate = util.fieldExists(sObjectName, 'Last_Bill_Date__c') ? (Datetime)record.get('Last_Bill_Date__c') : null;

		Date sd = iPD.startDate == null ? system.today() : Date.newInstance(iPD.startDate.year(), iPD.startDate.month(), iPD.startDate.day());

		// used for the case when no End Date specified but fulfillment is billed. Use this to determine where to prorate last month or use not.
		Date originalStartDate = cilExeStartDate != null ? cilExeStartDate : sd;

		Date ed = iPD.endDate == null ? system.today() : Date.newInstance(iPD.endDate.year(), iPD.endDate.month(), iPD.endDate.day());
		Date rd = iPD.recurrenceDate == null ? system.today() : Date.newInstance(iPD.recurrenceDate.year(), iPD.recurrenceDate.month(), iPD.recurrenceDate.day());

		List<PricingResult> mPriceResultList = new List<PricingResult>();

		if ( lastBillDate != null && (lastBillDate.date() == ed || lastBillDate.date() ==  SD)){
			return mPriceResultList;
		}

		//If the Last Bill Date is there, we should use that as the effective start date for this billing.
		sd = lastBillDate == null ? sd : Date.newInstance(lastBillDate.year(), lastBillDate.month(), lastBillDate.day());

		System.debug( logginglevel.error, '~*~\n\n\n pLogic STARTING BP Calc -- '
				+ pricingUom.Name + ' -- '
				+ record.getSObjectType().getDescribe().getName()
				+ ': ' + sd + ' - ' + ed
				+ ' (' + sd.daysBetween(ed) + ')'
				+ '\noriginalStartDate (' + originalStartDate + ')'
				+ '\n\n'
		);


		// get determines the equivlence of the UOM. ie: Month = 28 Days, Week = 1 Week. Every would be 28 and 1 accordingly
		decimal every = getEvery(pricingUom.Every__c);

		// get the occurrence of UOM in days. ie: week = 7 days, day = 1, month = 1 month or 28 days (SPS).
		Integer term = Integer.valueOf( getMultiplier(iPD.occurrence) * every);

		// SPS uses fixed monthly intervals of 28 days.
		Boolean useActualMonthlyIntervals = iPD.occurrence == Occurrence.MONTH;

		System.debug(  '~*~ term :' + term );
		System.debug(  '~*~ useActualMonthlyIntervals :' + useActualMonthlyIntervals );


		Date firstRecurrenceDate;
		if (useActualMonthlyIntervals) {
			firstRecurrenceDate = Date.newInstance( sd.year(), sd.Month(), rd.Day() );
			firstRecurrenceDate = firstRecurrenceDate < sd ? firstRecurrenceDate.addMonths(1) : firstRecurrenceDate;
		} else {
			Decimal decimalTerm = term;
			Integer period = Integer.valueOf(Math.ceil( rd.daysBetween(sd)/decimalTerm ) * decimalTerm);
			System.debug( '~*~ first period :' + period );
			firstRecurrenceDate = rd.addDays(period);

		}
		System.debug( '~*~ firstRecurrenceDate :' + firstRecurrenceDate );

		Date lastRecurrenceDate;
		if (useActualMonthlyIntervals) {
			lastRecurrenceDate = Date.newInstance( ed.year(), ed.Month(), rd.Day() );
			lastRecurrenceDate = lastRecurrenceDate > ed ? lastRecurrenceDate.addMonths(-1) : lastRecurrenceDate;
		} else {
			Decimal decimalTerm = term;
			Integer period = Integer.valueOf(Math.floor(rd.daysBetween(ed)/decimalTerm) * decimalTerm);
			System.debug( '~*~ last period :' + period );
			lastRecurrenceDate = rd.addDays(period);
		}

		System.debug( '~*~ lastRecurrenceDate :' + lastRecurrenceDate );

		/*
			conceptually, we divide everything into 3 durations. Inital, middle, and last.
				Conditions based on 1 month treated as dynamic 1 month or fixed days. Recurrence_Start_date is 8/1/17
					The inital cycle ranges from the SD till the first covered recurring date (future/approached date). ie: Start_Date is 8/17. So the firstRecurrenceDate is 9/1/17 or 8/29/17
					The last cycle ranges from the last covered date (most recent recurrence date) till the end_date. ie: End_Date is 9/15. So the lastRecurrenceDate is 9/1 or 8/29
					The mid cycle ranges from all the days between firstRecurrenceDate till the lastRecurrenceDate.
				Using the init cycle range, we derive best price by using a combination of breaking point and modular math
				Using the last cycle range, we determine best price or prorate if our total range exceeds the billingCycleTerm. billingCycleTerm is billing UOMs period. ie: Month is 1 month or fixed days depending on setup
				Using the mid cycle range, we determine the interval using floor or months between.

		 */

		// Always true statements else range is 0.
		Boolean edGreaterThanFR = firstRecurrenceDate <= ed; // if 0, no days in the last cycle
		Boolean sdLessThanLD = sd < lastRecurrenceDate;
		Boolean sdEqualLD = sd == lastRecurrenceDate;

		Date firstIntervalEndDate, lastIntervalStartDate;
		if (firstRecurrenceDate <= ed && sd < lastRecurrenceDate){// && sd != lastRecurrenceDate){ // ie: 8/2 8/24
			firstIntervalEndDate = firstRecurrenceDate; // ie: 8/17 to 9/1
			lastIntervalStartDate = lastRecurrenceDate;
		} else {
			lastIntervalStartDate = sd;
			firstIntervalEndDate = ed; // ie: 8/17 to 8/20.
		}

		System.debug( logginglevel.error, '~*~ lastIntervalStartDate:' + lastIntervalStartDate);
		System.debug( logginglevel.error, '~*~ firstIntervalEndDate :' + firstIntervalEndDate );
//		System.debug( '~*~ edGreaterThanFR :' + edGreaterThanFR + ', sdGreaterThanLD :' + sdLessThanLD + ', sdEqualLD :' + sdEqualLD);

		// get the initial range of days covered. Has to be 1 if sd == ed. Expecting least 1. If ed is less than the firstRecurrenceDate, this total range doesn't exceed the first Cycle Interval
		Decimal initCycleRange = (edGreaterThanFR && sdLessThanLD) ? sd.daysBetween(firstRecurrenceDate) : getRange(sd, ed, Occurrence.DAY); // : getRange(sd, ed, iPD.occurrence); // sd.daysBetween(firstRecurrenceDate);
//		Decimal initCycleRange = getRange(sd, firstIntervalEndDate, Occurrence.DAY); // sd.daysBetween(firstIntervalEndDate);

		// if recurrence is 8/1 and start date is on 8/17. The first RecurrenceDate will be 9/1. So we offset this by 1 to 8/1 to get the days total August
		Integer firstCycleOffSetValue = sd == firstRecurrenceDate ? 0 : -1;
		System.debug( '~*~ pLogic firstCycleMonthValueOffSet :' + firstCycleOffSetValue + ' firstRecurrenceDate month: ' + firstRecurrenceDate.month());
		// get days in first Month for prorating. use first previous recurrenceDate not sd as that period determines the days. ie: Recurrence date is 9/10 and sd is 10/3.
		Decimal initCycleTotalDays = useActualMonthlyIntervals ? term * Date.daysInMonth(firstRecurrenceDate.addMonths(firstCycleOffSetValue).year(), firstRecurrenceDate.addMonths(firstCycleOffSetValue).month()) : term;
		System.debug( '~*~ initCycleTotalDays :' + initCycleTotalDays );



		// get the last range of days from the last breached recurrence interval date till the end date. Set to 0 to avoid negative
		Decimal lastCycleRange = lastIntervalStartDate != sd ? lastIntervalStartDate.daysBetween(ed) : 0;

		// get days in last Month for prorating. use last recurrenceDate not ed as that period determines the days.  ie: Recurrence date is 9/10 and ed is 10/3.
		Decimal lastCycleTotalDays = useActualMonthlyIntervals ? term * Date.daysInMonth(lastRecurrenceDate.year(), lastRecurrenceDate.month()) : term;
		System.debug( '~*~ lastCycleTotalDays :' + lastCycleTotalDays );


		// firstRecurrenceDate is always greater than sd since it's defined that way.
		// However, if it's greater than the endDate, then we don't pass the first cycle interval
		// get the middle range of days from the start date till the first breached recurrence interval cycle. 0 or positive.
		Decimal midCycleInterval = getIntervalCount(useActualMonthlyIntervals, firstRecurrenceDate, lastRecurrenceDate, rd, term);

		System.debug( logginglevel.error, '~*~ pLogic CycleRange (init, mid, last): ' + initCycleRange + ', ' + midCycleInterval + ', ' + lastCycleRange );

		/*
			HOW BREAKING POINTS WORK:

			Get the floor and ceiling ranges, and modulus for our best price calculations.
		   	Whether we use the floor or the ceiling is determined by our priceBreakingPoints.
		   	i.e:
		   	Our priceBreakingPoint is 4 days,
		   	If we have 16 days, that's:
		   		floor of 2 weeks, and a modulus of 2 days.
		   		Since 2 < 4, breaking point hasn't been met. There for, our price is 2 weeks, 2 days.
		   	If we have 19 days, that's:
		   		floor of 2 weeks, and a modulus of 5 days
		   		Since 5 > 4 breakingPoint has been breached, we switch to use the ceiling of 3 weeks since that is now a better price.
		*/


		decimal currentLinePrice = pricebookLines.size() == 0 ? agl.Agreement_Price__c : mLinePrices.get(i);
		system.debug(logginglevel.error, '~*~ currentLinePrice '+currentLinePrice);


		// ba-todo: add custom setting of company value to use prorate here.
		Boolean prorateOnFirstMonthOverride = false;
		Boolean firstCycleProrateCondition = ( (prorateOnFirstMonthOverride || pricesFound == 1)); // || prorateFirstIntervalAsLastInterval);
		System.debug( '\n\n~*~ firstCycleProrateCondition :' + firstCycleProrateCondition );
		if (firstCycleProrateCondition == false){
			System.debug(  '~*~ prorateOnFirstMonth :' + prorateOnFirstMonthOverride );
			System.debug( '~*~ pricesFound :' + pricesFound );
		}
		Decimal firstCycleProrateValue = firstCycleProrateCondition ? currentLinePrice * initCycleRange / initCycleTotalDays : 0;

		Boolean lastMonthProrateCondition = (pricesFound == 1 || midCycleInterval > 0) && lastCycleRange > 0;
		System.debug( '\n\n~*~ pLogic lastMonthProrateCondition: ' + lastMonthProrateCondition );
		if (!lastMonthProrateCondition){
			System.debug( logginglevel.error, '~*~ (pricesFound == 1) :' + (pricesFound == 1) );
			System.debug( logginglevel.error, '~*~ (midCycleInterval > 0) :' + (midCycleInterval > 0) );
			System.debug( logginglevel.error, '~*~ (lastCycleRange > 0) :' + (lastCycleRange > 0) );
		}
		Decimal lastCycleProrateValue = lastMonthProrateCondition ? currentLinePrice * lastCycleRange / lastCycleTotalDays : 0;


		// Difficult to determine last month's CIL prorate.
		// 		Using this logic which uses the Agreement Line as a key, we get the earliest CIL start date in this execution cycle (invoice run)
		//		With this Start Date, we can determine if we exceed the period set by the billing UOM in order to prorate the last month
		// in the case where Last bill date is populated and we want to prorate the Last Interval, we want to use the original SD on the fulfillment to check if there is an interal
		Boolean prorateFirstIntervalAsLastInterval = false;
		if (midCycleInterval == 0 & lastCycleRange == 0 && !firstCycleProrateCondition){ // skip if we're already prorating

			Decimal originalStartDateMidCycleIntervalCount = getIntervalCount(useActualMonthlyIntervals, originalStartDate, ed, rd, term);
			System.debug( logginglevel.error,  '~*~ originalStartDate :' + originalStartDate );
			System.debug(  '~*~ originalStartDateMidCycleIntervalCount :' + originalStartDateMidCycleIntervalCount );
			prorateFirstIntervalAsLastInterval = originalStartDateMidCycleIntervalCount > 0;
		}

		System.debug( logginglevel.error, '~*~ \n');
		System.debug( logginglevel.error, '~*~ pLogic first Cycle: ' + firstCycleProrateValue.setScale( 2, RoundingMode.HALF_UP ) + ' = ' + currentLinePrice + ' * ' + initCycleRange + ' / ' + initCycleTotalDays);
		System.debug( logginglevel.error, '~*~ pLogic mid interval: ' + (midCycleInterval * currentLinePrice) + ' = ' + midCycleInterval + ' * ' +  currentLinePrice);

		// using the lastCycle so the date ranges in the pricing result are correct. This is also more logical.
		if (prorateFirstIntervalAsLastInterval){
			System.debug( logginglevel.error, '~*~ pLogic OVERRIDE last Cycle: ' + lastCycleProrateValue.setScale( 2, RoundingMode.HALF_UP ) + ' + ' + currentLinePrice + ' * ' + initCycleRange + ' / ' + initCycleTotalDays );
			lastCycleProrateValue = currentLinePrice * initCycleRange / initCycleTotalDays;
		} else {
			System.debug( logginglevel.error, '~*~ pLogic last Cycle :' + lastCycleProrateValue.setScale( 2, RoundingMode.HALF_UP ) + ' = ' + currentLinePrice + ' * ' + lastCycleRange + ' / ' + lastCycleTotalDays);
		}



		System.debug( '~*~\n\n');
		System.debug( '~*~ pLogic firstCycleProrateCondition: ' + firstCycleProrateCondition);
		System.debug( '~*~ pLogic prorateFirstIntervalAsLastInterval: ' + prorateFirstIntervalAsLastInterval);
		System.debug( '~*~ pLogic lastMonthProrateCondition: ' + lastMonthProrateCondition);
		// initial cycle PricingResults
		if ((firstCycleProrateValue == 0 ||firstCycleProrateValue == null) && !prorateFirstIntervalAsLastInterval &&  pricesFound > 1) {
			System.debug( logginglevel.error,  '~*~  \nCalculate Initial Interval Best Price: ' + firstCycleProrateValue);
			calculateBP(
					mPriceResultList,
					initCycleRange,
					sd,
					pbLines,
					mpriceBreakingPoints,
					mLinePrices,
					firstIntervalEndDate,
					record, i
			);
		} else if (firstCycleProrateValue != 0){
			PricingResult result = new PricingResult();
			result.recordId = record.Id;
			result.name = pricingUom.Name;
			result.pricingUOM = pricingUom;
			result.unitPrice = firstCycleProrateValue;


			// uses startDate as the initial cursor date and adds the firstIntervalrange to get the endDate on the fulfillment
			result.startDate = sd;
			result.endDate = firstIntervalEndDate;

			result.bestPrice = firstCycleProrateValue;

			result.intervals = 1;


			System.debug( '~*~  First interval prorate - pLogic:' + PricingService.debugPricingResultString( result ) );


			mPriceResultList.add(result);
		}


		// Mid Cycle PricingResults
		if ( midCycleInterval > 0 ){
			// init detail pricingResult data
			PricingResult result = new PricingResult();
			result.recordId = record.Id;
			result.name = pricingUom.Name;
			result.pricingUOM = pricingUom;
			result.unitPrice = currentLinePrice;


			result.startDate = firstRecurrenceDate;
			result.endDate = lastRecurrenceDate;

			result.intervals = Integer.valueOf( midCycleInterval );

			result.bestPrice = midCycleInterval * currentLinePrice;

			System.debug( '~*~  Mid Cycle - pLogic:' + PricingService.debugPricingResultString( result ) );


			mPriceResultList.add(result);

		}

		// End cycle PricingResults
		if ((lastCycleProrateValue == 0 || lastCycleProrateValue == null) && pricesFound > 1) {
			System.debug(  '~*~  \nCalculate Last Interval Best Price');
			// initial Best Price
			calculateBP(
				mPriceResultList,
				lastCycleRange,
				lastRecurrenceDate,
				pbLines,
				mpriceBreakingPoints,
				mLinePrices,
				firstRecurrenceDate,
				record, i
			);
		} else if (lastCycleProrateValue != 0){
			// init detail pricingResult data
			PricingResult result = new PricingResult();
			result.recordId = record.Id;
			result.name = pricingUom.Name;
			result.pricingUOM = pricingUom;
			result.unitPrice = lastCycleProrateValue;



			// uses startDate as the initial cursor date and adds the firstIntervalrange to get the endDate on the fulfillment
			result.startDate = lastIntervalStartDate;
			result.endDate = ed;

			result.intervals = 1;

			result.bestPrice = lastCycleProrateValue;

			System.debug( '~*~  Last Cycle - pLogic:' + PricingService.debugPricingResultString( result ) );


			mPriceResultList.add(result);
		}


		System.debug( '\n');
		System.debug( logginglevel.error, '~*~ pLogic mBestPrice :' + PricingService.debugBestPriceString(record, mPriceResultList) );


		decimal price = 0;
		for(PricingResult p : mPriceResultList) {
			price += p.bestPrice;
		}

		System.debug( logginglevel.error, '~*~\n\n');
		System.debug( 'pLogic ENDING BP Calc -- '
			+ pricingUOM.Name + ' -- '
			+ price + ' -- '
			+ record.getSObjectType().getDescribe().getName() + ': '
			+ sd + ' - ' + ed
			+ '\n\n\n'
		);


		return mPriceResultList;
	}
	
	public static decimal getIntervalCount(Boolean useActualMonthlyIntervals, Date sd, Date ed, Date rd, Decimal term){
		System.debug( logginglevel.error, '\n\n~*~ getIntervalCount');
		Date firstRecurrenceDate;

		if ( useActualMonthlyIntervals ) {
			firstRecurrenceDate = Date.newInstance( sd.year(), sd.Month(), rd.Day() );
			firstRecurrenceDate = firstRecurrenceDate < sd ? firstRecurrenceDate.addMonths( 1 ) : firstRecurrenceDate;
		}
		else {
			Decimal decimalTerm = term;
			// Math - RD is 8/1, SD is 8/17. Term is 28 days. (Ceiling(17/28)) * 28 = 28. With 28 we add to the RD to get the next Rec Date.
			Integer fulOriginalPeriod = Integer.valueOf( Math.ceil( rd.daysBetween( sd ) / decimalTerm ) * decimalTerm );
			firstRecurrenceDate = rd.addDays( fulOriginalPeriod );
		}
		System.debug( logginglevel.error, '~*~ Interval Range :' + firstRecurrenceDate + ' - ' + ed);
		Date nextRecurrenceDate = (useActualMonthlyIntervals) ? firstRecurrenceDate.addMonths(1) : firstRecurrenceDate.addDays(Integer.valueOf(term));
		Decimal fulOrigMidCycleRange;

		if (nextRecurrenceDate <= ed){
			if(useActualMonthlyIntervals){
				fulOrigMidCycleRange = firstRecurrenceDate.monthsBetween( ed );
			}
			else {
				fulOrigMidCycleRange = firstRecurrenceDate.daysBetween( ed );
			}
		} else {
			fulOrigMidCycleRange = 0;
		}

		System.debug( logginglevel.error, '~*~ floor of fulOrigMidCycleRange / term: ' + fulOrigMidCycleRange + ' / ' + term + '\n');
		return math.floor( fulOrigMidCycleRange / term );

	} 

	public static List<PricingResult> calculateBP(
			List<PricingResult> mPriceResultList,
			Decimal remainder,
			Date cursorDate,
			List<PblSortByPricingUOM> pbLines,
			Map<Integer,Decimal> mpriceBreakingPoints,
			Map<Integer,Decimal> mLinePrices,
			Date firstRecurrenceDate,
			sObject record,
			Integer i
	){
		// if only 1 uom, return. i is the index value of the PBLs regresenting the max treshhold (billing Uom).
		if (i == 0 || remainder == 0){
			return mPriceResultList;
		}

		System.debug( logginglevel.error, '~*~ \n\nCalculating Best Price ~ remainder :' + remainder );


		// start with Max uom incase of breaking point is reached.
		for(Integer pblIndex = i; pblIndex >= 0; pblIndex--) {

			if ( remainder == 0 ) {
				break;
			}

			Uom__c thisUom = pbLines[ pblIndex ].pbLine.Pricing_UOM__r;
			System.debug( logginglevel.error, '~*~ thisUom.Name :' + thisUom.Name );

			Decimal uomTerm = getEvery( thisUom.Every__c ) * getMultiplier( getOccurrence( thisUom.Recurrence__c ) );
			if (thisUom.Recurrence__c == 'Month(s)'){
				System.debug( '~*~ old Uomterm :' + uomTerm );
				uomTerm = uomTerm * Date.daysInMonth(firstRecurrenceDate.year(), firstRecurrenceDate.month());
			}
			System.debug( '~*~ uomTerm :' + uomTerm );

			Decimal nextUomTerm = 1; // initialize
			Boolean nextUomExists = (pblIndex - 1) >= 0;
			if ( nextUomExists) {
				Uom__c nextUom = pbLines[ pblIndex - 1 ].pbLine.Pricing_UOM__r;
				nextUomTerm = getEvery( nextUom.Every__c ) * getMultiplier( getOccurrence( nextUom.Recurrence__c ) );
			}

			// priceBreakingPoint which works in conjuncture with module to determine price choice breaking point
			decimal priceBreakingPoint = mpriceBreakingPoints.get( pblIndex ) * nextUomTerm;

			decimal uomLinePrice = mLinePrices.get( pblIndex );

			Integer uomMod = Math.mod( Integer.valueOf( remainder ), Integer.valueOf( uomTerm ) );
			Decimal uomFloorValue = math.floor( remainder / uomTerm );
			System.debug( logginglevel.error, '~*~ pLogic - remainder ' + '(' + remainder + ') - floor:' + uomFloorValue + ', mod: ' + uomMod  + ', priceBreakingPoint: ' +  priceBreakingPoint );

			Integer uomDuration = Integer.valueOf(uomTerm * uomFloorValue);

			// if breaking point reached or if no more PBLs
			if ( priceBreakingPoint < uomMod || (pblIndex == 0 && uomMod > 0)) {
				System.debug( logginglevel.error, '~*~  Excced Breaking point? ' + (priceBreakingPoint < uomMod));
				System.debug( logginglevel.error, '~*~  No More PBLs? ' + (pblIndex == 0 && uomMod > 0) );
				uomDuration += uomMod;
				uomMod = 0;
				uomFloorValue += 1; // essentially taking the ceiling since there exists a mod value
			}

			if ( uomFloorValue > 0 ) {
				PricingResult result = new PricingResult();
				result.recordId = record.Id;
				result.name = thisUom.Name;

				result.pricingUOM = thisUom;

				result.unitPrice = uomLinePrice;
				result.bestPrice = uomLinePrice * uomFloorValue;

				result.intervals = Integer.valueOf( uomFloorValue );

				result.startDate = cursorDate;
				cursorDate = cursorDate.addDays(uomDuration);
				result.endDate = cursorDate;

				mPriceResultList.add(result);

				System.debug( '~*~ Init / Last - pLogic:' + PricingService.debugPricingResultString( result ) );
			}
			remainder = uomMod;
		}

		return mPriceResultList;
	}

	//Will get Pricebook lines by type. If the second argument is null, will fetch all pricebook lines that match the record
	public static Map<SObject, List<Pricebook_Line__c>> getPriceBookLines(List<SObject> records, PriceType priceType) {
		Map<SObject, List<Pricebook_Line__c>> mPricebookLines = new Map<SObject, List<Pricebook_Line__c>>();

		Set<id> companyIds = new Set<id>();
		Set<Id> customerIds = new Set<Id>();
		Set<id> productIds = new Set<Id>();
		Set<Id> productGroupIds = new Set<Id>();
		Set<Id> pricebookIds =  new Set<Id>();
		Date minDate, maxDate;
		String companyDefaultPricebookId;

		SchemaUtil util = SchemaUtil.getInstance();

		set<Id> solIds = new set<Id>();
		for (sobject s : records) {
			if ( s.get('Sales_Order_Line__c') != null && s.getSObject('Sales_Order_Line__r') == null) {
				solIds.add( (Id) s.get( 'Sales_Order_Line__c' ) );
			}
		}

		if (!solIds.isEmpty()) {
			Map<Id,Sales_Order_Line__c> solMap = new Map<Id,Sales_Order_Line__c>(cachedRecurringSOL(solIds));

			for (sobject s : records) {
				if ( s.get( 'Sales_Order_Line__c' ) != null && s.getSObject( 'Sales_Order_Line__r' ) == null ) {
					s.putSObject('Sales_Order_Line__r', solMap.get( (Id) s.get('Sales_Order_Line__c')) );
				}
				System.debug( '~*~ sol: :' + s.getSObject( 'Sales_Order_Line__r' ) );
			}
		}

		for(SObject s : records) {

			string sObjectName = s.getSObjectType().getDescribe().getName();

			if(util.fieldExists(sObjectName, 'Company__c') && s.get('Company__c') != null) {
				companyIds.add((Id)s.get('Company__c'));
			}

			// TODO: Address different Custom api names for different objects
			if(util.fieldExists(sObjectName, 'Sales_Order_Line__c') && s.getSObject('Sales_Order_Line__r') != null && s.getSObject('Sales_Order_Line__r').get('Customer_ID__c') != null) {
				customerIds.add((Id)s.getSObject('Sales_Order_Line__r').get('Customer_ID__c'));
			}

			if(util.fieldExists(sObjectName, 'Product__c') && s.get('Product__c') != null) {
				productIds.add((Id)s.get('Product__c'));
			}

			if(util.fieldExists(sObjectName, 'Product_Group__c') && s.get('Product_Group__c') != null) {
				productGroupIds.add((Id)s.get('Product_Group__c'));
			}

			if(util.fieldExists(sObjectName, 'Pricebook__c') && s.get('Pricebook__c') != null) {
				pricebookIds.add((Id)s.get('Pricebook__c'));
			}

			// Ba-todo: doesn't work in CIL trigger to verify if PBLs exist for this CIL. Would need PB on CIL.
			if(util.fieldExists(sObjectName, 'Sales_Order_Line__c')){

				if (s.getSObject('Sales_Order_Line__r') != null) {

					if ( s.getSObject( 'Sales_Order_Line__r' ).get( 'Pricebook__c' ) != null ) {
						pricebookIds.add( ( Id ) s.getSObject( 'Sales_Order_Line__r' ).get( 'Pricebook__c' ) );
					}
				} else {
					System.debug( logginglevel.error, '~*~ alert found null SOL :');
				}
			}

			if(util.fieldExists(sObjectName, 'Start_Date__c')  && s.get('Start_Date__c') != null) {
				Datetime recordStartDate = (Datetime)s.get('Start_Date__c');
				if(minDate > recordStartDate.date() || minDate == null) {
					minDate = recordStartDate.date();
				}
			}

			if(util.fieldExists(sObjectName, 'End_Date__c')  && s.get('End_Date__c') != null) {
				Datetime recordEndDate = (Datetime)s.get('End_Date__c');
				if(maxDate < recordEndDate.date()  || maxDate == null) {
					maxDate = recordEndDate.date();
				}
			}
		}


		System.debug( '~*~'
				+ '\ncustomerIds :' + customerIds
				+ '\nproductIds :' + productIds
				+ '\npricebookIds :' + pricebookIds
				+ '\ncompanyIds :' + companyIds
				+ '\nminDate :' + minDate
				+ '\nmaxDate :' + maxDate
				+ '\npriceType :' + priceType);


		List<Pricebook_Line__c> myPblList = cachedRecurringPBLs(customerIds, productIds, productGroupIds, pricebookIds, companyIds);

		Pricebook_Line__c[] pbls = cachedRecurringPBLs(customerIds, productIds, productGroupIds, pricebookIds, companyIds); //pricebookIds != null ? Database.query(soql.getQuery()) : new List<Pricebook_Line__c>();

		Map<String, List<Pricebook_Line__c>> mPBLines = new Map<String, List<Pricebook_Line__c>>();
		String keySeparator = '-';
		for(Pricebook_Line__c pbl : pbls) {

			if (pbl.Pricebook__r.Default__c) {
				companyDefaultPricebookId = pbl.Pricebook__c;
			}

			String stringkey = ''
					+ keySeparator + (pbl.Product__c != null ? pbl.Product__c : pbl.Product_Group__c)
					+ keySeparator + pbl.Pricebook__c
					+ (pbl.Customer__c != null ? (keySeparator + pbl.Customer__c) : '');

			if (!mPBLines.containsKey(stringkey)) {
				System.debug( '~*~ INITIALIZING: ' + stringkey);
				mPBLines.put(stringkey, new List<pricebook_line__c>());
			}
			mPBLines.get(stringkey).add(pbl);

			System.debug( '~*~ \n');
		}

//		System.debug( '~*~ companyDefaultPricebookId :' + companyDefaultPricebookId );
		System.debug( '~*~ mPBLines :' + mPBLines );

		for(SObject record : records) {

			string sObjectName = record.getSObjectType().getDescribe().getName();

			List<String> keys = new List<String>();

			String key = '';

			if (util.fieldExists(sObjectName, 'Product__c') && record.get('Product__c') != null) {
				key += keySeparator + ( (Id)record.get('Product__c') );

			}
			else if (util.fieldExists(sObjectName, 'Product_Group__c')  && record.get('Product_Group__c') != null) {
				key += keySeparator + ( (Id)record.get('Product_Group__c') );
			}

//			System.debug( '~*~ record key :' + key );

			if(util.fieldExists(sObjectName, 'Sales_Order_Line__c') && record.getSObject('Sales_Order_Line__r') != null) {
				if(record.getSObject('Sales_Order_Line__r').get('Pricebook__c') != null) {
					key += keySeparator + ((Id) record.getSObject('Sales_Order_Line__r').get('Pricebook__c') );
				} else {
					key += keySeparator + companyDefaultPricebookId;
				}

				// create PBL key that don't have any customer reference
				keys.add(key);

				// get PBL that have customer reference
				if(record.getSObject('Sales_Order_Line__r').get('Customer_ID__c') != null) {
					String custKey = key;
					System.debug( '~*~ init custKey :' + custKey );
					custKey = keySeparator + ( (Id)record.getSObject('Sales_Order_Line__r').get('Customer_ID__c') );
					System.debug( '~*~ final custKey :' + custKey );
					keys.add(custKey);
				}
			}
			else {

				// this only gets called during testMethods where there is no SOL reference

				if(companyDefaultPricebookId != null) {
					key += keySeparator + (companyDefaultPricebookId);
				}

				keys.add(key);
			}


			// init map with null value
			mPricebookLines.put( record, null );


			for (String objKey : keys){
				if (mPBLines.containsKey(objKey)) {
					mPricebookLines.put( record, mPBLines.get( objKey ) );
					System.debug( '~*~ KEY FOUND :' + objKey);
					break;
				} else {
					System.debug( '~*~ obj Key :' + objKey );
				}
			}

		}

		return mPricebookLines;
	}

	public static Sales_Order_Line__c[] cachedRecurringSOL(Set<Id> idSet){

		set<id> missing = missing(idSet);

		if (missing.isEmpty() != true ) {
			for( Sales_Order_Line__c obj: [select id, Customer_ID__c, Pricebook__c
			from Sales_Order_Line__c
			where Id in :idSet]
			){
				recordCache.put( obj.id, obj );
			}
		}
		return KSE.filter( recordCache.values(), Sales_Order_Line__c.sObjectType);
	}

	private static Map<id, sObject> recordCache = new Map<id, sObject>();
	private static set<id> missing( set<id> lookingFor ) {
		set<id>missing = new set<id>();
		for ( id oid : lookingFor) {
			if ( recordCache.containsKey( oid ) == false ) missing.add( oid );
		}
		return missing;
	}

	// Maps product to list<PBL>
	private static Map<Id, List<sObject>> pricebookCache = new Map<Id, List<sObject>>();

	private static set<id> missingProductInPBL( set<id> lookingFor ) {
		set<id>missing = new set<id>();
		for ( id oid : lookingFor) {
			if ( pricebookCache.containsKey( oid ) == false ){
				missing.add( oid );
			}
		}
		return missing;
	}

	// Ba-Todo - Need to improve missingIds. Currently only using product Ids. Need to support all Ids (customer, pg, pb, company)
	public static Pricebook_Line__c[] cachedRecurringPBLs(Set<Id> customerIds, Set<Id> productIds, Set<Id> productGroupIds, Set<Id> pricebookIds, Set<id> companyIds){

		// collects missing products
		set<Id> missing = missingProductInPBL( productIds );

		if (missing.isEmpty() != true ) {

			System.debug( '~*~ cachedRecurringPBLs missing:' + missing );

			SOQLUtil soql = new SOQLUtil('Pricebook_Line__c', true);
			soql.addFields(new set<string>{
					'id','Pricebook__c','Pricing_UOM__c','Pricing_UOM__r.Name','Pricing_UOM__r.Recurrence__c',
					'Pricing_UOM__r.Every__c','Pricebook__r.Default__c','Min__c','Max__c','Price__c','Price_2__c','Price_3__c','Price_4__c','Price_5__c',
					'Product__c','Use_Fixed_Pricing__c','Customer__c','Pricebook__r.Name', 'pricebook__r.Currency__c', 'Pricebook__r.Company__c',
					'Product_Group__c','Start_Date__c','End_Date__c'
			});
			String whereClause = ''
					+' Pricebook__r.Company__c IN :companyIds '
					+' aNd (product__c in :productIds OR Product_Group__c in : productGroupIds) '
					+' and (Pricebook__c IN :pricebookIds OR Pricebook__r.Default__c = true) '
					+' anD (Customer__c in :customerIds or Customer__c = null) '
					+ ' And Price_Type__c = \'Recurring\'';

			soql.setWhereClause(whereClause);

			// In the case where there is no pricebook for a product, it better to capture an empty list pricebook line.
			// initialize here
			for(Id prodId : productIds){
				if (!pricebookCache.containskey(prodId)) {
					pricebookCache.put( prodId, new List<Pricebook_Line__c>() );
				}
			}

			for( Pricebook_Line__c obj: (List<Pricebook_Line__c>) Database.query(soql.getQuery())) {
				pricebookCache.get(obj.product__c).add(obj);
			}
		}

		List<Pricebook_line__c> returnList = new List<Pricebook_line__c>();
		for (List<Pricebook_Line__c> pblList : pricebookCache.values()){
			returnList.addAll(pblList);
		}
		return KSE.filter( returnList, Pricebook_Line__c.sObjectType);
	}

	private static Map<Integer, Decimal> getLinePrices(SObject record, List<PblSortByPricingUOM> pbLines) {

		map<Integer, Decimal> mLinePrices = new map<Integer, Decimal>();
		Integer pricesFound = pbLines.size();

		System.debug( '~*~ pricesFound :' + pricesFound );
		for(Integer i = 0; i <  pricesFound; i++) {
			Decimal price = getLinePrice(record, pbLines[i]);
			mLinePrices.put(i, price);
		}

		return mLinePrices;
	}


	private static decimal getLinePrice(SObject record, PblSortByPricingUOM pbl){
		decimal price = 0;
        system.debug(logginglevel.error, '\n\n~*~ getLinePrice - pricing UOM: ' + record.get('Pricing_UOM__c') + ', record Type: ' + record.getSObjectType().getDescribe().getName());
        system.debug('~*~ pbl uom '+pbl.pbLine.Pricing_UOM__r.Id+'  '+pbl.pbLine.Pricing_UOM__c);

		System.debug( '~*~ record :' + record );
		System.debug( '~*~ condition 1:' + record.get('Agreement_Line__c') );
		System.debug( '~*~ condition 2:' + record.getSObject('Agreement_Line__r'));

		if( (record.get('Agreement_Line__c') != null || record.getSObject('Agreement_Line__r') != null)	// some weird issue where AGL Id is lost but the record reference isn't.
				&& record.getSObject('Agreement_Line__r').get('Pricing_UOM__c')  == pbl.pbLine.Pricing_UOM__r.Id
				&& (Decimal)record.getSObject('Agreement_Line__r').get('Agreement_Price__c') != null) {

			System.debug( '~*~  1b');

			price = (Decimal)record.getSObject('Agreement_Line__r').get('Agreement_Price__c');

			system.debug('~*~ getLinePrice - First Condition');

		}
        else {
			price = pbl.pbLine.Price__c;
			system.debug('~*~ getLinePrice - Third Condition');
		}
		System.debug( logginglevel.error, '~*~ price :' + price );
		return price;
	}

	private static Map<Integer, Decimal> getPriceBreakingPoints(Map<Integer, Decimal> mLinePrices) {

		Map<Integer, Decimal> mpriceBreakingPoints = new Map<Integer, Decimal>();
		List<Decimal> linePrices = mLinePrices.values();
		System.debug( '~*~ linePrices :' + linePrices );

		Integer linePriceSize = linePrices.size();

		for(Integer i = 0; i < linePriceSize; i++) {
			if(i == 0) {
				mpriceBreakingPoints.put(i, 0);
			} else {
				Decimal currentLinePrice = mLinePrices.get(i);
				Decimal previousLinePrice = mLinePrices.get(i - 1);
				mpriceBreakingPoints.put(i, currentLinePrice/previousLinePrice ); // divide by zero error possible if 0 unit price exists on previous price

				System.debug( '~*~' + currentLinePrice + '/' + ' = ' + currentLinePrice/previousLinePrice );

			}
		}

		return mpriceBreakingPoints;
	}

	public static decimal getMultiplier(Occurrence occ) {
		map<Occurrence, Integer> mOccMult = new map<Occurrence, Integer>{Occurrence.MONTH => 1, Occurrence.QUARTER => 3, Occurrence.YEAR => 12};
		decimal occMult = 1;
		if(occ == Occurrence.DAY) {
			occMult = 1;
		} else if(occ == Occurrence.WEEK) {
			occMult = 7;
		}else if(mOccMult.containsKey(occ)){
			occMult = mOccMult.get(occ);
		}
		return occMult;
	}

	public static decimal getRange(Date startDate, Date endDate, Occurrence occ) {
		decimal occMult = getMultiplier(occ);
		decimal range = 0;
		if(occ == Occurrence.DAY || occ == Occurrence.WEEK) {

			if (startDate == endDate ){
				return 1;
			}

			range = decimal.valueOf(startDate.daysBetween(endDate));
		}
		else {
			// questionable definition as month could be defined as other values.
			range = startDate.monthsBetween(endDate);
		}

		return range;
	}

	private static decimal getQuantity(SObject record) {

		String sObjectName = record.getSobjectType().getDescribe().getLocalName();
		decimal quantity = null;
		system.debug(LoggingLevel.INFO, 'getQuantity -- sObjectName: ' + sObjectName);

		if(sObjectName == 'Fulfillment__c') {
			quantity = (decimal)record.get('Quantity__c');
		} else if(sObjectName == 'Customer_Invoice_Line__c') {
			quantity = (decimal)record.get('Quantity_Shipped__c');
		}
		return quantity;
	}

	public static Occurrence getOccurrence(string occur){

		Occurrence occ = Occurrence.IMMEDIATE;
		occur = occur == null ? '' : occur;
		if(occur.equalsIgnoreCase('immediate')){
			occ = Occurrence.IMMEDIATE;
		}else if(occur.equalsIgnoreCase('Day(s)')) {
			occ = Occurrence.DAY;
		}else if(occur.equalsIgnoreCase('Week(s)')){
			occ = Occurrence.WEEK;
		}else if(occur.equalsIgnoreCase('Month(s)')){
			occ = Occurrence.MONTH;
		}else if(occur.equalsIgnoreCase('Quarter(s)')){
			occ = Occurrence.QUARTER;
		}else if(occur.equalsIgnoreCase('Year(s)')){
			occ = Occurrence.YEAR;
		}
		return occ;
	}

	public static Integer getEvery(Decimal every) {
		return every == null ? 1 : Integer.valueOf(every);
	}

	public static RateBasis getRateBasis(string rateBase){
		RateBasis rb = RateBasis.QTY;
		rateBase = rateBase == null ? '' : rateBase;
		if(rateBase.equalsIgnoreCase('Flat')){
			rb = RateBasis.FLAT;
		}else if(rateBase.equalsIgnoreCase('Quantity')){
			rb = RateBasis.QTY;
		}
		return rb;
	}


	public static string debugBestPricesString(Map<SObject, List<PricingService.PricingResult>> mBestPrices) {
		String debugBestPrices = '';
		for ( SObject obj : mBestPrices.keySet() ) {
			debugBestPrices += debugBestPriceString( obj);
			for ( PricingService.PricingResult mPR : mBestPrices.get( obj ) ) {
				debugBestPrices += debugPricingResultString( mPR);
			}
		}
		return debugBestPrices;
	}

	public static string debugBestPriceString(SObject obj, List<PricingService.PricingResult> mPRList) {
		String debugBestPrices = '';

		debugBestPrices += debugBestPriceString( obj);
		for ( PricingService.PricingResult mPR : mPRList ) {
			debugBestPrices += debugPricingResultString( mPR);
		}

		return debugBestPrices;
	}

	public static string debugBestPriceString(Sobject obj){
		String debugBestPrices = '\n';

		dateTime startDate = (dateTime)  obj.get( 'start_date__c' );
		dateTime endDate = (dateTime) obj.get( 'end_date__c' );

		string sObjectName = obj.getSObjectType().getDescribe().getName();

		Decimal qty;
		if (new SchemaUtil().fieldExists(sObjectName, 'Quantity__c')){
			qty = (Decimal) obj.get('Quantity__c');
		} else {
			qty = (Decimal) obj.get('Quantity_Shipped__c');
		}

		debugBestPrices += '\nRecord Details: '
				+ (qty != null ? qty.setScale( 2, RoundingMode.HALF_UP ) : null) + '\t'
				+ (obj.get('Name')!= null ? obj.get('Name') : obj.get('Source_Key__c')) + '\t';

		debugBestPrices += '\nRecord Dates:'
				+ startDate.year() + '-' + startDate.month() + '-' + startDate.day() + '\t'
				+ endDate.year() + '-' + endDate.month() + '-' + endDate.day()
				+ ' (' + startDate.date().daysBetween(endDate.date()) + ')';

		debugBestPrices += '\n\t\t ' +
				+ 'Name   \t\t'
				+ 'BstPrce\t\t'
				+ 'UntPrce\t\t'
				+ 'Int\t\t'
				+ 'Start Date\t\t'
				+ 'End Date  \t\t';

		return debugBestPrices;
	}

	public static string debugPricingResultString(PricingService.PricingResult pr){
		String debugStatement = '';
		debugStatement += '\n\t\t'
				+ pr.Name + (pr.Name.length() <7 ? '\t\t\t' : '\t\t')
				+ pr.bestPrice.setScale( 2, RoundingMode.HALF_UP ) + '\t\t'
				+ pr.unitPrice.setScale( 2, RoundingMode.HALF_UP ) + '\t\t'
				+ pr.intervals + '  \t\t'
				+ pr.startDate.year() + '-' + pr.startDate.month() +  '-' + pr.startDate.day() + '\t\t'
				+ pr.endDate.year() + '-' + pr.endDate.month() + '-' + pr.endDate.day()  + '\t\t';

		return debugStatement;
	}

	public static string debugCIL(Customer_Invoice_Line__c cil ){
		string debugStatement = '';

		debugStatement +=  'cil - '
			+ cil.Extended_Price__c.setScale( 2, RoundingMode.HALF_UP )
			+ ' (' +  cil.Quantity_Shipped__c + ' * ' + cil.Unit_Price__c.setScale( 2, RoundingMode.HALF_UP ) + ') - '
			+ cil.Start_Date__c + ' - ' + cil.End_Date__c + ' - '
			+ cil.Recurrence_Start_Date__c
			+ ' - Pricing: ' + cil.Pricing_UOM__r.Name;

		return debugStatement;
	}

	public static String debugFulfillment(Fulfillment__c ful){
		String debugString = '';

		debugString += 'ful - '
				+ 'Qty: ' + ful.Quantity__c
				+ ', Unit Price: ' +  ful.Unit_Price__c
				+ ', SD: ' +  ful.Start_date__c
				+ ', ED: ' +  ful.End_Date__c
				+ ', Parent: ' + ful.Parent_Fulfillment__c
				+ ', Id: ' + ful.Id;

		return debugString;
	}

	public enum RateBasis {FLAT, QTY}
	public enum Occurrence {IMMEDIATE, DAY, WEEK, MONTH, QUARTER, YEAR}
	public enum PriceType {RECURRING, SALES}

	public class PricingDefinition{

		public RateBasis rateBasis;
		public Occurrence occurrence;
		public integer every;
		public string customerId;
		public string recordId;//string for guids
		public Id pricebookId;
		public Id productId;
		public decimal quantity;
		public DateTime startDate;
		public DateTime endDate;
		public DateTime recurrenceDate;
		public Date pricingDate;

	}

	public class PricingResult{
		public string recordId; //string for guiIDs
		public UOM__c pricingUOM;

		public string name;

		public decimal unitPrice;
		public decimal bestPrice;

		public Date startDate;
		public Date endDate;

		public Integer intervals;
	}

	public class PblSortByPricingUOM implements Comparable {
		Pricebook_Line__c pbLine;

		public PblSortByPricingUOM(Pricebook_Line__c pbLine) {
			this.pbLine = pbLine;
		}

		public Integer compareTo(Object obj) {
			map<Occurrence, Integer> mOccMult = new map<Occurrence, Integer>{	Occurrence.DAY => 1,
			Occurrence.WEEK => 7,
			Occurrence.MONTH => 30,
			Occurrence.QUARTER => 91,
			Occurrence.YEAR => 365};
			PblSortByPricingUOM compareToPbl = (PblSortByPricingUOM)obj;
			Decimal numOfDays = 0;
			Decimal compareToNumOfDays = 0;
			Occurrence occ = this.pbLine.Pricing_UOM__c == null ? null : getOccurrence(this.pbLine.Pricing_UOM__r.Recurrence__c);
			Occurrence compareToOcc =this.pbLine.Pricing_UOM__c == null ? null : getOccurrence(compareToPbl.pbLine.Pricing_UOM__r.Recurrence__c);
			if(mOccMult.containsKey(occ)) {
				numOfDays = mOccMult.get(occ) * this.pbLine.Pricing_UOM__r.Every__c;
			}
			if(mOccMult.containsKey(compareToOcc)) {
				compareToNumOfDays = mOccMult.get(compareToOcc) * compareToPbl.pbLine.Pricing_UOM__r.Every__c;
			}

			if(numOfDays > compareToNumOfDays) {
				return 1;
			} else if ( numOfDays == compareToNumOfDays) {
				return 0;
			} else {
				return -1;
			}
		}
	}
}