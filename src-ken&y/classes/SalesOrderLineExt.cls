public with sharing class SalesOrderLineExt {
   
    public SalesOrderLineExt(Apexpages.standardController c){}  

    
    public class NoMatchingPricebookException extends Exception{}
     
    @RemoteAction 
    public  static Sales_Order_Line__c getSOLineInfo(String companyId, String priceDate, String product_name, String soPricebookId, 
                    String linePricebookName, String customerSoldToPricebookId) {
        
        product_name = String.escapeSingleQuotes(product_name);
        
        String whereClause = ' Name = \''+product_name +'\' Limit 1 ';
        
        SOQLUtil soql = new SOQLUtil('Product__c');
        soql.addFields(new Set<String>{'ID', 'Name', 'Description__c', 'Item__c', 'Item__r.Name', 'Item__r.Fulfillment_Source__c', 
        								'Selling_UOM__r.Name', 'Pricebook_Line_Required__c', 'Product_Group__c', 'Units_per_Pallet__c', 'Units_per_Layer__c', 'UPC_Code__c'});
        soql.setWhereClause(whereClause);
        Product__c[] products = Database.query(soql.getQuery());
                          
        if (products == null || products.isEmpty()) {
            String term = product_name + '%';
            soql.setWhereClause(' where Name like \''+ term +'\' Limit 1 ');
            products = Database.query(soql.getQuery());    
        }
        
        if (products == null || products.isEmpty()) {
            // still cant find Product throw an error back
            throw new SOLException(Label.No_matching_product + product_name );    
        }

        Product__c product = products[0]; 

        Pricebook__c soLinePricebook;
        if ( !String.isBlank(linePricebookName) ) {
            String pbNameExpr = '%' + linePricebookName + '%';
            try {
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Pricebook__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id'
				});
				soql.setWhereClause('Name LIKE :pbNameExpr');

				soLinePricebook = Database.query(soql.getQuery());

            } catch (Exception ex) {
                throw new SOLException(Label.No_matching_Pricebook + ':' + linePricebookName );           
            }    
        }
        

        Sales_Order_Line__c soLine = new Sales_Order_Line__c();
        
        Date efd;
        // Uses pricing date, then order then, then today's date
        if (priceDate != '' && priceDate != Null){
            efd = date.parse(priceDate);
        } else {
            efd = system.today();
        }
        
        try { 
            // now get the price from the price book, use sales order pricebook first, then company pricebook 
            Pricebook_Line__c[] pbls;  
            Id productCompanyId = companyId;
            Id productGroupId = product.Product_Group__c;
            Id productId = product.Id;
            
            if (soLinePricebook != null) {
                Id pricebookId = soLinePricebook.id;
                
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Pricebook_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','pricebook__c','price__c','product__c','pricebook__r.Name','Use_Fixed_Pricing__c'
				});
				soql.setWhereClause('( product__c = :productId OR (Product_Group__c != null AND Product_Group__c =:productGroupId) ) and Pricebook__c = :pricebookId '
									+' and Start_date__c <= :efd and (End_date__c = null OR End_date__c >= :efd)');
				soql.setLimit(1);

				pbls = Database.query(soql.getQuery());

            } 
            
            if ( (pbls == null || pbls.isEmpty()) && ! String.isBlank(soPricebookId) ) {
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Pricebook_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','pricebook__c','price__c','product__c','pricebook__r.Name','Use_Fixed_Pricing__c'
				});
				soql.setWhereClause('( product__c = :productId OR (Product_Group__c != null AND Product_Group__c =:productGroupId) ) and Pricebook__c = :soPricebookId '
									+' and Start_date__c <= :efd and (End_date__c = null OR End_date__c >= :efd)');
				soql.setLimit(1);

				pbls = Database.query(soql.getQuery());

            } 
            
            if ( (pbls == null || pbls.isEmpty()) && ! String.isBlank(customerSoldToPricebookId) ) {
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Pricebook_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','pricebook__c','price__c','product__c','pricebook__r.Name','Use_Fixed_Pricing__c'
				});
				soql.setWhereClause('( product__c = :productId OR (Product_Group__c != null AND Product_Group__c =:productGroupId) ) and Pricebook__c = :customerSoldToPricebookId '
									+' and Start_date__c <= :efd and (End_date__c = null OR End_date__c >= :efd)');
				soql.setLimit(1);

				pbls = Database.query(soql.getQuery());
            } 
            
            if ( pbls == null || pbls.isEmpty() ) { // pull a default price using the company pricebook, ignore the null pricebook on the sales order
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Pricebook_Line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','pricebook__c','price__c','product__c','pricebook__r.Name','Use_Fixed_Pricing__c'
				});
				soql.setWhereClause('( product__c = :productId OR (Product_Group__c != null AND Product_Group__c =:productGroupId) ) '
									+' and Pricebook__r.company__c = :productCompanyId and Pricebook__r.Default__c = true and Start_date__c <= :efd and (End_date__c = null OR End_date__c >= :efd)');
				soql.setLimit(1);
				
				pbls = Database.query(soql.getQuery());

            }
            
            if (pbls == null || pbls.isEmpty()) {
                throw new NoMatchingPricebookException (Label.No_matching_Pricebook + '.') ;
            }
            
            Pricebook_Line__c pbl = pbls[0] ;
            
            // KNDY-3298
            // No bracket stuff used now, only suggest price from the first pricebook field            
            soLine.Unit_Price__c = pbl.price__c; 
            soLine.Selling_UOM__c = product.Selling_UOM__c;
            soLine.Selling_UOM__r = product.Selling_UOM__r;
            soLine.Description__c = product.Description__c;
            soLine.Product__c = product.Id;
            soLine.Product__r = product;
            soLine.UPC_Code__c = product.UPC_Code__c;
            soLine.Pricebook__c = pbl.Pricebook__c;
            soLine.Pricebook__r = pbl.Pricebook__r;
            soLine.Fulfillment_Source__c = product.Item__r.Fulfillment_Source__c;
            
        } catch ( Exception e ) {  
            System.debug (logginglevel.error, e.getStackTraceString());     
            // KNDY-1061   item.source == Miscellanous will not require a pricebook, so skip the result above
            // KNDY-1259   item.source == Expense , not using pricebook
            // these are now dealt with in a formula, which result we read here
            // TODO offer true customer flexibility, read a "user defined " field here to govern if PB is required
            if ( ! product.Pricebook_Line_Required__c  ) {  // it's ok to be missing if ...
                soLine.Product__c = product.Id;
                soLine.Description__c = product.Description__c;
                soLine.Product__r = product;
                soLine.UPC_Code__c = product.UPC_Code__c;
                soLine.Selling_UOM__c = product.Selling_UOM__c;
                soLine.Selling_UOM__r = product.Selling_UOM__r;
                soLine.Fulfillment_Source__c = product.Item__r.Fulfillment_Source__c;
                return soLine;
            }

            throw( new SOLException (Label.No_active_pricebook ));    
        }
        return soLine;  // returns as JSON
    } 
    
    public class SOLException extends Exception {}
}