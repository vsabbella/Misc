public with sharing class SalesOrderNewExt {
    
    public Sales_Order__c newObj {get;set;}
    private ApexPages.Standardcontroller con; 
    public String customerFieldName{get;set;}
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    
    public SalesOrderNewExt (ApexPages.StandardController controller) { 
        con = controller;  
        newObj = (Sales_Order__c) controller.getRecord();       // use the record that the controller has for us
        newObj.Company__c = CompanyService.getDefaultCompanyId(); 
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id companyId = newObj.Company__c;
		
		SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Default_Transaction_Currency__c',
          'Default_Sales_Order_Weight_UOM__c',
          'Default_Sales_Order_Dimension_UOM__c'
		});
		soql.setWhereClause('Id = :companyId');

		List<Company__c> companyInfo = Database.query(soql.getQuery());

        if (companyInfo.size() > 0){
          newObj.Currency__c = companyInfo[0].Default_Transaction_Currency__c; //OTC-740
          newObj.Weight_UOM__c = companyInfo[0].Default_Sales_Order_Weight_UOM__c;
          newObj.Dimension_UOM__c = companyInfo[0].Default_Sales_Order_Dimension_UOM__c;
        }

        customerFieldName = KSE.NamespaceUU + 'Customer__c';      
    }
    
    @RemoteAction
    public static Sales_Order__c updateCompanyDefaults(Id compId){

        Sales_Order__c so = new Sales_Order__c();

        if(compId != null){
            SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Default_Transaction_Currency__c',
                'Default_Transaction_Currency__r.Name'
            });
            soql.setWhereClause('Id = :compId');

            List<Company__c> companyInfo = Database.query(soql.getQuery());

            if (companyInfo.size() > 0){
              so.Currency__c = companyInfo[0].Default_Transaction_Currency__c;
              so.Currency__r = companyInfo[0].Default_Transaction_Currency__r;
            }   
        }

        return so;
    }

    @RemoteAction
    public static Sales_Order__c updateCustomerDefaults(Id custId){

        Sales_Order__c so = new Sales_Order__c();
        if(custId != null){
            SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id',
                'Currency__c',
                'Currency__r.Name',
                'Price_Determination_Date__c', 
                'Top_Parent_Customer__c'
            });

            soql.setWhereClause('ID = :custId');
            soql.setLimit(1);

            Customer__c soldToCust = Database.query(soql.getQuery());

            if(soldToCust.Price_Determination_Date__c != null){
                so.Price_Determination_Date__c = soldToCust.Price_Determination_Date__c;
            }

            if (soldToCust.Currency__c != null){

                so.Currency__c = soldToCust.Currency__c;
                so.Currency__r = soldToCust.Currency__r;

            } else if(soldToCust.Top_Parent_Customer__c != null){

                String corpCustId = soldToCust.Top_Parent_Customer__c;
            
                SOQLUtil soql1 = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode

                soql1.addFields(new set<string>{
                    'id', 
                    'Currency__c',
                    'Currency__r.Name'
                });
                soql1.setWhereClause('ID = :corpCustId');
                soql1.setLimit(1);

                Customer__c corpCustomer = Database.query(soql1.getQuery());
                
                if (corpCustomer.Currency__c != null){
                    so.Currency__c = corpCustomer.Currency__c;
                    so.Currency__r = corpCustomer.Currency__r;
                }
            }
            
        }

        return so;
    }

    public pageReference save(){
 		//KNDY-1149 Pulling payment terms from Bill-to customer who is the parent of a Sold-to customer
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id customerId = newObj.Customer__c;
		
		SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Street__c','City__c','State__c','Zip_Code__c','Country__c','Parent_Customer__r.Payment_Term__c','Parent_Customer__r.Payment_Term__r.Name',
			'Parent_Customer__c'
		});
		soql.setWhereClause('Id = :customerId');

		List<Customer__c> cList = Database.query(soql.getQuery());

        if (cList.size() > 0) {
            newObj.Street__c = cList[0].Street__c != null ? cList[0].Street__c.replace('<br>', '\n') : cList[0].Street__c;
            newObj.City__c = cList[0].City__c;
            newObj.State__c = cList[0].State__c;
            newObj.Zip_Code__c = cList[0].Zip_Code__c;
            newObj.Country__c = cList[0].Country__c;
            newObj.Bill_to__c = cList[0].Parent_Customer__c;    // bill to is always the parent of sold to
            
        }  

        // see if there is exactly one ship to, if so use it
        // if not ask the customer to fill this in
        if ( newObj.Customer__c != null && newObj.Ship_to__c == null ) {
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'ID','name'
			});
			soql.setWhereClause('Parent_customer__c = :customerId');

			List<Customer__c> stList = Database.query(soql.getQuery());

            if ( stList.size() == 1 ) {
                newObj.Ship_to__c = stList[0].id;
            } 
            
        }
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id shipToId =  newObj.Ship_to__c;
		soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Street__c','City__c','State__c','Zip_Code__c','Country__c'
		});
		soql.setWhereClause('ID = :shipToId');
		
		List<Customer__c> sList = Database.query(soql.getQuery());

        if (sList.size() > 0) {
            newObj.Ship_to_Street__c = sList[0].Street__c != null ? sList[0].Street__c.replace('<br>', '\n') : sList[0].Street__c;
            newObj.Ship_to_City__c = sList[0].City__c;
            newObj.Ship_to_State__c = sList[0].State__c;
            newObj.Ship_to_Zip_Code__c = sList[0].Zip_Code__c;
            newObj.Ship_to_Country__c = sList[0].Country__c;
        }
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id billToId =  newObj.Bill_to__c;
		
		soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Street__c','City__c','State__c','Zip_Code__c','Country__c'
		});
		soql.setWhereClause('ID = :billToId');

		List<Customer__c> bList = Database.query(soql.getQuery());

        if (bList.size() > 0) {
            newObj.Bill_to_Street__c = bList[0].Street__c != null ? bList[0].Street__c.replace('<br>', '\n') : bList[0].Street__c;
            newObj.Bill_to_City__c = bList[0].City__c;
            newObj.Bill_to_State__c = bList[0].State__c;
            newObj.Bill_to_Zip_Code__c = bList[0].Zip_Code__c;
            newObj.Bill_to_Country__c = bList[0].Country__c;
        }
        
        if (newObj.Payment_Term__c == null  && cList.size() > 0 && cList[0].Parent_Customer__r.Payment_Term__c != null) {
           newObj.Payment_Term__c = cList[0].Parent_Customer__r.Payment_Term__c; //KNDY-1149 Pulling payment terms from Bill-to customer who is the parent of a Sold-to customer
            
        }
        
        return con.save(); // standard controller knows how to save the new record
    }
    
}