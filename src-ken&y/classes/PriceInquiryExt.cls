/**
 * Created by jeromeisrael on 6/21/17.
 */

public with sharing class PriceInquiryExt {
    public Sales_Order__c salesOrder { get; set; }
    public List<Sales_Order_Line__c> soLines { get; set; }
    public Integer maxLineNumber { get; set; }

    public PriceInquiryExt(Apexpages.StandardController con){
        this.salesOrder = initSalesOrder();
        this.maxLineNumber = 0;
        this.soLines = new List<Sales_Order_Line__c>();
        this.addNewSOLine();
    }

    private Sales_Order__c initSalesOrder(){
        Sales_Order__c so = new Sales_Order__c();

        Id companyId = CompanyService.getDefaultCompanyID();

        SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
                'Id','Default_Transaction_Currency__c'
        });
        soql.setWhereClause('Id = :companyId');

        List<Company__c> companyInfo = Database.query(soql.getQuery());

        //Get default company, Currency and pricing date
        so.Company__c = companyId;
        so.Pricing_Date__c = System.today();
        if(companyInfo.size() > 0){
            so.Currency__c = companyInfo[0].Default_Transaction_Currency__c;
            so.Currency__r = companyInfo[0].Default_Transaction_Currency__r;
            so.Company__r = companyInfo[0];
        }

        return so;
    }

    private Map<Id, Product__c> getProductInfo(Set<Id> prodIds){

        Map<Id, Product__c> productMap = new Map<Id, Product__c>();

        SOQLUtil soql = new SOQLUtil('Product__c', true); //enforceFLS=true, running in user mode

		Set<String> productQueryFields = new set<string>{'Id','Product_Group__c', 'Description__c', 'Selling_UOM__c'
        };

		productQueryFields.addAll(AllowanceRuleService.productFields);
		soql.addFields(productQueryFields);

        soql.setWhereClause('Id in :prodIds');

        List<Product__c> productInfoList = Database.query(soql.getQuery());

        for (Product__c prod: productInfoList) {
            productMap.put(prod.Id, prod);
        }

        return productMap;
    }

    public void addNewSOLine(){
        Sales_Order_Line__c soLine = new Sales_Order_Line__c();
        maxLineNumber = maxLineNumber + 1;
        soLine.Sales_Order__c = this.salesOrder.Id;
        soLine.Sales_Order__r = this.salesOrder;
        soLine.Line__c = maxLineNumber;
        soLine.Company__c = this.salesOrder.Company__c;
        soLine.Company__r = this.salesOrder.Company__r;
		soLine.Quantity_Ordered__c = 1;
        this.soLines.add(soLine);
    }

    private Set<Id> getProdIds(List<Sales_Order_Line__c> sols){
        Set<Id> prodIds = new Set<Id>();

        for (Sales_Order_Line__c sol : sols) {
            prodIds.add(sol.Product__c);
        }

        return prodIds;
    }
    public void getPrice(){

        Map<Id, Product__c> productInfoMap = getProductInfo(getProdIds(this.soLines));

		if (this.salesOrder.Customer__c != null){

			SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode

			Set<String> customerQueryFields = new set<string>{
					'Id', 'customer_group__c', 'Pricebook__c',
					'Parent_Customer__c', 'Parent_Customer__r.customer_group__c','Parent_Customer__r.Name',
					'top_parent_customer__c', 'top_parent_customer__r.customer_group__c','top_parent_customer__r.Name'
			};

			soql.addFields(customerQueryFields);

			soql.setWhereClause('Id = \'' + salesOrder.Customer__c + '\' LIMIT 1');

			Customer__c customer = Database.query(soql.getQuery());

			this.salesOrder.Customer__r = customer;
			this.salesOrder.Bill_to__c = customer.Parent_Customer__c;
			this.salesOrder.Bill_to__r = customer.Parent_Customer__r;
		}


        if(!productInfoMap.isEmpty()){
            for (Sales_Order_Line__c sol : soLines) {
                if(productInfoMap.containsKey(sol.Product__c)){
                    Product__c tProduct = productInfoMap.get(sol.Product__c);
                    sol.Product__r = tProduct;
                    sol.Selling_UOM__c = tProduct.Selling_UOM__c;
                }

				if (sol.Pricebook__c != null){
					sol.Pricebook__c = null;
				}
            }

            Map<String, Pricebook_Line__c> pblMap = PricingService.fetchSOLinesPriceBookInfo(soLines);

            for (Sales_Order_Line__c sol : soLines) {
                String tKey = 'newso-' + sol.Line__c;
                if(pblMap.containsKey(tKey)){
                    Pricebook_Line__c tPbl = pblMap.get(tKey);
                    sol.Pricebook__c = tPbl.Pricebook__c;
                    sol.Unit_Price__c = tpbl.Price__c;
                    sol.List_Price__c = tpbl.Price__c;
                }
            }

			AllowanceService.previewNewPrice(salesOrder, soLines);
        }

    }
}