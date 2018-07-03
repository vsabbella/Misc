public with sharing class SalesOrderAdjustmentExt {
	@TestVisible
	private ApexPages.StandardController controller;
	private Sales_Order__c originalSO = new Sales_Order__c();
        
	public Sales_Order__c adjustmentSO {get;set;}{adjustmentSO = new Sales_Order__c(Type__c = ''); }
	public boolean disableSave {get;set;}
	public static final list<String> MANUAL_ADJUSTMENT_ORDER_TYPES = new List<String>{
			SalesOrderService.ADJUSTMENT_PRICE_CLAIM,
			SalesOrderService.ADJUSTMENT_QUANTITY_CLAIM,
			SalesOrderService.ADJUSTMENT_PRICE_AR,
			SalesOrderService.ADJUSTMENT_QUANTITY_AR,
			SalesOrderService.ADJUSTMENT_QUANTITY_CLAIM_RETURN,
			SalesOrderService.ADJUSTMENT_QUANTITY_AR_RETURN,
			SalesOrderService.ADJUSTMENT_QUANTITY_RECALL
	};

	public SelectOption[] getAdjustmentTypes() {
        List<SelectOption> adjustmentTypes = new List<SelectOption>();
		
        for (String orderType : MANUAL_ADJUSTMENT_ORDER_TYPES ) {
            adjustmentTypes.add(new SelectOption(orderType, orderType));
        }
        
        return adjustmentTypes;
    }
    
   	public SalesOrderAdjustmentExt(ApexPages.StandardController sCon) {
        
        controller = sCon;
        
        if(controller.getId() != null){
        	Id originalSOId = (Id) controller.getId();
        	
        	/*String query = SchemaUtil.getInstance().generateQueryFromFieldSet('Sales_Order__c', 
													new Set<String>{'Adjustment_Order'},
													new Set<String>{'Id', 'Status__c', 'Type__c', 'Company__c', 'Bracket_Price_Field_In_Use__c','Agreement__c'},
													'Id = :originalSOId LIMIT 1');
        	*/
        	String whereClause =  'Id = :originalSOId LIMIT 1';
        
	        SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	        soql.addFields('Adjustment_Order');
	        soql.addFields(new Set<String>{'Id', 'Status__c', 'Type__c', 'Company__c', 'Bracket_Price_Field_In_Use__c','Agreement__c','Billing_UOM__c','Recurrence_Start_Date__c'});
	        soql.setWhereClause(whereClause);
	        
        	originalSO = (Sales_Order__c) Database.query(soql.getQuery());
        	
        	String originalBracketField = originalSO.Bracket_Price_Field_In_Use__c;
        	
        	if(SalesOrderService.STANDARD_ORDER_TYPES.contains(originalSO.Type__c) == false){
        		ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'Adjustment order cannot be created for Sales Orders of type: ' + originalSO.Type__c));
        		disableSave = true;
        		return;
        	}
        														
        	adjustmentSO = originalSO.clone(false,true);
        	adjustmentSO.Date_Time_Ordered__c = system.now();
        	adjustmentSO.Price_Determination_Date__c = 'Manual';
	        adjustmentSO.Related_Sales_Order__c = originalSO.Id;
	        adjustmentSO.Status__c = 'Draft';  
	        adjustmentSO.Agreement__c = originalSO.Agreement__c;
	        
	        if(String.isBlank(originalBracketField)){
	        	adjustmentSO.Pricing_Bracket__c = '';
	        }
	        else
	        if(originalBracketField.equalsIgnoreCase('Price__c')){
				adjustmentSO.Pricing_Bracket__c = 'Base Price';
			}
			else 
			if(originalBracketField.equalsIgnoreCase('Price_2__c')){
				adjustmentSO.Pricing_Bracket__c = 'Bracket 2';
			}
			else 
			if(originalBracketField.equalsIgnoreCase('Price_3__c')){
				adjustmentSO.Pricing_Bracket__c = 'Bracket 3';
			}
			else 
			if(originalBracketField.equalsIgnoreCase('Price_4__c')){
				adjustmentSO.Pricing_Bracket__c = 'Bracket 4';
			}
			else 
			if(originalBracketField.equalsIgnoreCase('Price_5__c')){
				adjustmentSO.Pricing_Bracket__c = 'Bracket 5';
			}
		}
    }
    
    public PageReference save(){
    	
        List<Sales_Order_Line__c> SOLList = new List<Sales_Order_Line__c> ();
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            
            // KNDY-1762
            DML.insertAsUser(adjustmentSO);
            
            Id relatedSoId = adjustmentSO.Related_Sales_Order__c;
            SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode

            soql.addFields(AllowanceRuleService.salesOrderLineFields); soql.addField('Weight__c, Weight_UOM__c, Weight_UOM_Name__c, Volume__c, VAT_Amount__c, Value_Added_Tax_Rate__c, Unit_Price__c, UPC_Code__c, Currency__c, SystemModstamp, Step__c, Status__c, Sales_Order__r.Pricing_Date__c, Ship_From_Location__c, Selling_UOM__c, Sales_Order__c, Sales_Order_Number__c, Required_Date__c, Quantity_Shipped__c, Quantity_Ordered__c, Product__c, Product_Weight__c, Pricebook__c, Off_Invoice_Rate__c, Number_of_stackable_pallets__c, Number_of_Pallets__c, Number_of_Floor_Spaces__c, Name,  Memo__c, List_Price__c, Line__c, Line_Type__c, Latest_Ship_Date__c, Latest_Delivery_Date__c,  Id, Has_Exceptions__c, Freight_Allowance__c, Extended_Price__c, Expected_Price__c, Earliest_Ship_Date__c, Earliest_Delivery_Date__c, Sales_Tax_Rate__c, Discount_Percent__c, Dimension_UOM__c, Dimension_UOM_Name__c, Description__c, Days_from_Promised__c,Days_Due__c, Customer_Item_Number__c, Customer_ID__c, CreatedDate, CreatedById, Company__c, Sales_Order__r.Company__c, Company_Identifier__c, BillBack_Rate__c, Backorder_Value__c, Available_Inventory__c, Allowances__c, Allocation_Rule__c, Accounting_Segment__c, Autonumber__c, Product__r.Id, Product__r.Name, Product__r.Product_Group__c, Sales_Order__r.Customer__r.Customer_Group__c, Sales_Order__r.Ship_to__r.Customer_Group__c,Sales_Order__r.Bill_to__c, Sales_Order__r.Bill_to__r.Customer_Group__c, Sales_Order__r.Customer__r.Top_Parent_Customer__r.Customer_Group__c, Product__r.Sales_Hierarchy__c, Product__r.Sales_Hierarchy__r.Code__c, Product__r.Sales_Hierarchy__r.Path__c, Product__r.Product_group__r.Hierarchy__c, Product__r.Product_group__r.Hierarchy__r.Path__c, Product__r.Product_group__r.Hierarchy__r.Code__c, Occurrence__c, Start_Date__c, End_Date__c, Rate_Basis__c, Agreement_Line__c, Billing_Category__c, Fulfillment_Category__c, Customer_Site__c');
            soql.setWhereClause('Sales_Order__c = :relatedSoId');
            soql.setOrderByClause('Line__c');

            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Allowances_Applied__r');
            childRel.addFields(AllowanceRuleService.allowanceAppliedFields);
            childRel.setWhereClause('Source__c!=\'Trade\'');
            soql.addChildRelationship(childRel);


            // TODO:  Check if the sales order is "closed"
            for (Sales_Order_Line__c oldSOLObject : Database.query(soql.getQuery()) ) {
            	
        	    Sales_Order_Line__c newSOLObject = new Sales_Order_Line__c();          
                newSOLObject = oldSOLObject.clone(false,true);
                newSOLObject.Quantity_Shipped__c = 0;
                newSOLObject.Quantity_Fulfilled__c = 0;
                newSOLObject.Sales_Order__c = adjustmentSO.Id;
                newSOLObject.Status__c = 'Draft';
                newSOLObject.Product__r = oldSOLObject.Product__r;
                newSOLObject.Sales_Order__r = oldSOLObject.Sales_Order__r;
                newSOLObject.Related_Sales_Order_Line__c = oldSOLObject.Id;

                SOLList.add(newSOLObject);
            }            
           
            //KNDY-1762
            DML.insertAsUser(SOLList);
            
            // Copy all allowances from original sales order document.
            Map<id,id> fromToMap = new Map<id,id>{adjustmentSO.Related_Sales_Order__c => adjustmentSO.id};
            for (Sales_Order_Line__c sol : SOLList){
                if (sol.Related_Sales_Order_Line__c != null && sol.Id != null){
                fromToMap.put(sol.Related_Sales_Order_Line__c, sol.Id);
            }
            }

            AllowanceService.copyAllowancesFromDocument(fromToMap);
        
        } catch (Exception e) {
            System.debug(loggingLevel.Error, e.getMessage() + ' ' + e.getStackTraceString());
            ApexPages.addMessages(e);
            Database.rollback(sp);
            return null;
        }          

        PageReference SOPage = new PageReference('/' + adjustmentSO.Id);
        SOPage.setRedirect(true);
        return SOPage;
    }
}