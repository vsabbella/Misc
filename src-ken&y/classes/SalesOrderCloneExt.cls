public with sharing class SalesOrderCloneExt {
    ID oldISID;
    private ApexPages.StandardController controller;
    
    public SalesOrderCloneExt(ApexPages.StandardController c) {
        controller = c;

        if (!Test.isRunningTest()) {
            
            List<String> additionalFields = new List<String>{'Required_Date__c',
                                                             'Ship_From_Location__c'};

            controller.addFields(additionalFields);
        }

        oldISID = controller.getRecord().id;
    }
    
     public Pagereference save(){
     
        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c> ();
        
        Sales_Order__c oldSO = (Sales_Order__c)controller.getRecord();    
        Sales_Order__c newSO = oldSO.clone(false,true);
        newSO.Date_Time_Ordered__c = system.now();
        newSO.Status__c = 'Draft';        
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            //KNDY-1762
            DML.insertAsUser(newSO);

            Map<Id, Sales_Order_Line__c> solMap = new Map<Id, Sales_Order_Line__c>();
            Map<Id, List<Sales_Order_Line__c>> solParentToChildMap = new Map<Id, List<Sales_Order_Line__c>>();
            List<Id> solParentList = new List<Id>();
            Map<Id, Sales_Order_Line__c> oldSOLtoNewSOL = new Map<Id, Sales_Order_Line__c>();

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			Id oldSOId = oldSO.Id;
			SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Company__c','Description__c','Discount_Percent__c','Currency__c','Line__c','Product__c','Quantity_Backordered__c',
				'Quantity_Ordered__c','Quantity_Shipped__c','Ship_From_Location__c','Required_Date__c','Sales_Order__c','Status__c','Selling_UOM__c',
				'Unit_Price__c','Memo__c','Weight_UOM__c','Dimension_UOM__c','Line_Type__c','Fulfillment_Source__c','Parent_Sales_Order_Line__c', 
                'Customer_Site__c', 'Item_Specification__c', 'Invoiceable__c', 'Non_Shippable__c', 'Work_Order__c', 'Usage_Based__c', 'End_Customer__c',
                'UPC_Code__c', 'Start_Date__c', 'End_Date__c', 'Pricebook__c', 'Component__c', 'Item_Source__c','Parent_Sales_Order_Line__r.Item_Source__c'
			});
			soql.setWhereClause('Sales_Order__c = :oldSOId and Parent_Sales_Order_Line__r.Item_Source__c != \'Kit\'');

			for (Sales_Order_Line__c sol :Database.query(soql.getQuery())){
			    // KNDY-14102
			    sol.Work_Order__c = null;
                // populate Parent -> child map
                if (sol.Parent_Sales_Order_Line__c != null) {
                    if (!solParentToChildMap.containsKey(sol.Parent_Sales_Order_Line__c)) {
                        solParentToChildMap.put(sol.Parent_Sales_Order_Line__c, new List<Sales_Order_Line__c>());
                    }
                    solParentToChildMap.get(sol.Parent_Sales_Order_Line__c).add(sol);
                } else {
                    solParentList.add(sol.id);
                }

                // collect all sols
                solMap.put(sol.id, sol);
            }
                    
            // insert parent lines
            for (Id parentSOLId : solParentList) {
                	             
                Sales_Order_Line__c newSOL = buildSOL(solMap.get(parentSOLId), newSO);

                oldSOLtoNewSOL.put(parentSOLId, newSOL);
            }
            
            DML.insertAsUser(oldSOLtoNewSOL.values());

            List<Sales_Order_Line__c> childLines = new List<Sales_Order_Line__c>();


            for (Id solId : solParentToChildMap.keySet()) {
                for (Sales_Order_Line__c sol : solParentToChildMap.get(solId)) {

                    Sales_Order_Line__c newSOL = buildSOL(solMap.get(sol.id), newSO);

                    newSOL.Parent_Sales_Order_Line__c = oldSOLtoNewSOL.get(sol.Parent_Sales_Order_Line__c).id;
                    childLines.add(newSOL);
                }
            }

            if (!childLines.isEmpty()) {
                DML.insertAsUser(childLines);
            }

            //system.assert(false);

        } catch (DmlException e) {

           ApexPages.addMessages(e);
           Database.rollback(sp);
           return null;
        }          

        PageReference SOPage = new PageReference('/'+newSO.Id);
        SOPage.setRedirect(true);
        return SOPage;
    }

    public Sales_Order_Line__c buildSOL(Sales_Order_Line__c oldSOLObject, Sales_Order__c newSO) {

        Sales_Order_Line__c newSOLObject = oldSOLObject.clone(false, true);

        if (oldSOLObject.Start_Date__c != null && oldSOLObject.End_date__c != null){
        Integer diff = oldSOLObject.Start_Date__c.date().daysBetween(oldSOLObject.End_date__c.date());

        newSOLObject.Start_Date__c = system.now();
        newSOLObject.End_date__c = system.now() + diff;
        }

        newSOLObject.Sales_Order__c = newSO.id;
        newSOLObject.Quantity_Shipped__c = 0;
        newSOLObject.Status__c = 'Draft';
        newSOLObject.Required_Date__c = newSO.Required_Date__c; //OTC-373


        if (newSO.Ship_From_Location__c != null) {
            newSOLObject.Ship_From_Location__c = newSO.Ship_From_Location__c; //OTC-944
        }

        if (newSO.Weight_UOM__c != null) { //KNDY -3621 UOM Conversion
            newSOLObject.Weight_UOM__c = newSO.Weight_UOM__c;
        }

        if (newSO.Dimension_UOM__c != null) {
            newSOLObject.Dimension_UOM__c = newSO.Dimension_UOM__c;
        }

        return newSOLObject;
        //solList.add(newSOLObject);
    }
}