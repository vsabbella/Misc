public with sharing class FacilityAssignmentExt {
    
    private apexpages.StandardController con;
    public Boolean selecterror {get; set;}
    List<Sales_Order__c> soList = new List<Sales_Order__c>();
    List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
    Set<ID> pgSet = new Set<ID>();

    public FacilityAssignmentExt(ApexPages.StandardController controller) {
        con = controller;
        Sales_Order__c so =(Sales_Order__c)controller.getRecord();
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Company__c','Ship_From_Location__c','Ship_to__c','Status__c'
		});
		Id soId = so.ID;
		soql.setWhereClause('ID =: soId');
		soList = Database.query(soql.getQuery());

        if (soList[0].Status__c  != 'Draft') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.To_proceed_SalesOrder_status_must_be_set_to_Draft));
            selecterror = true;
            return;
        }

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Product__r.Name','Product__r.Product_Group__c','Ship_From_Location__c'
		});
		soId = so.ID;
		soql.setWhereClause('Sales_Order__c =: soId and Status__c != \'Closed\' and Status__c != \'Cancelled\'');
		solList = Database.query(soql.getQuery());

        if (solList.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.SalesOrder_has_no_open_lines));
            selecterror = true;
            return;
        }
        for (Sales_Order_Line__c sol : solList) {
            if (sol.Product__r.Product_Group__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Product_Group_is_missing_for_product +sol.Product__r.Name ));
                selecterror = true;
                return;
            }
            pgSet.add(sol.Product__r.Product_Group__c);
        }
                   
    }
    
     public pagereference fassign() {
     
        Date todaysdate = System.today();
        ID hid;
     
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Facility_Assignment__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Facility__c','Facility__r.Name','Product_Group__c'
		});
		Id cId = soList[0].Company__c;
		Id sId = soList[0].Ship_to__c;
		soql.setWhereClause(
			'Company__c =: cId and ' +
			'Ship_to_Customer__c =: sId and ' +
			'Product_Group__c in: pgSet and ' +
			'Active__c = true and ' +                                            
			'Start_Date__c <=: todaysdate'	
		);
		List<Facility_Assignment__c> faList = Database.query(soql.getQuery());
        
        hid = null;
        for (Integer i = 0; I < faList.size(); ++i) {  // get rid of duplicates for the same product group
            if (hid == faList[i].Product_Group__c) falist.remove(i);
            else hid = faList[i].Product_Group__c;
        }

        if (faList.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_FacilityAssignment_records_found));
         selecterror = true;
        return null;
        }
         
        if (faList.size() != pgSet.size()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Not_all_Product_Groups_have_FacilityAssignment_records));
            selecterror = true;
            return null;
        }
         
        for (Facility_Assignment__c fa : faList) {
            if (faList[0].Facility__c != fa.Facility__c) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Different_Facilities_Found));
                selecterror = true;
                return null;
            }
        }
         
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Default_Sales_Order_Ship_From_Location__c'
		});
		Id fId = faList[0].Facility__c;
		soql.setWhereClause('ID =: fId');
		List<Facility__c> fList = Database.query(soql.getQuery());

        if (fList.size() == 0 || flist[0].Default_Sales_Order_Ship_From_Location__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                                 Label.Default_SalesOrder_ShipFromLocation_not_on_file_for_Facility +faList[0].Facility__r.Name));
            selecterror = true;
            return null;
        }
         
        soList[0].Ship_From_Location__c = flist[0].Default_Sales_Order_Ship_From_Location__c;
        for (Sales_Order_Line__c sol : solList) {
            sol.Ship_From_Location__c = flist[0].Default_Sales_Order_Ship_From_Location__c;
        }
        DML.updateAsUser(soList);
        DML.updateAsUser(solList);
        
        return ( ApexPages.hasMessages() ? null : new PageReference('/'+this.con.getId()) );
    }

}