// JIRA - 2831
public with sharing class PricebookLineUpdateExt extends GridRelatedListController {
    public static final String DATE_FORMAT = 'MM/dd/yyyy';
    public static final Integer FROM_DATE_OFFSET = -7;
    public static final Integer TO_DATE_OFFSET = 7;
    
    /*
        This would be a custom setting in future !
        As of now it controls Pricebook line searching behaviour i.e. 
        When setting is TRUE :
        ======================
            It will load all linked products and groups for given filters, if USER selected Product 1, this setting will also
            fetch all pricebook lines related with the product group of that product.
    */
    public static Boolean FindRelatedProductAndGroups = false;
    
    // in case company is not given
    public class NoCompanyProvidedException extends Exception{}

    static {
        // We want to use different format for Date and DateTime
        FieldInfo.AlwaysUseFullDateTimeFormat = false;
    }

    static final String Pricebook_FieldSet_Name = 'Pricebook_Line_Update';
    
    @TestVisible transient Id companyId;

    public PricebookLineUpdateExt(ApexPages.StandardController sc) {         
        companyId = sc.getId();
        if (companyId == null) {
            throw new NoCompanyProvidedException(Label.Bad_page_access_Try_accessing_via_link_on_Company_detail_page);
        }
        config.uniqueId = 'kendoGridDiv';
        config.title = 'Pricebook Lines';
        config.objectName = 'Pricebook_Line__c';
        config.fieldset = Pricebook_FieldSet_Name;
        config.buttons = 'save,cancel,delete,create,search';
        //KNDY-3296: Make bracket price fields readonly
        config.readOnlyFields = 'Price_2__c,Price_3__c,Price_4__c,Price_5__c';
    }

    public String getFromDate() {        
        // 1 week back
        return System.now().addDays(FROM_DATE_OFFSET).format(DATE_FORMAT);
    }

    public String getToDate() {        
        // 1 week forward
        return System.now().addDays(TO_DATE_OFFSET).format(DATE_FORMAT);
    }


    public class InvalidMMDDYYYDateException extends Exception{}
    static Date parseDateInFormat_MM_DD_YYYY(String dateStr) {
        String[] dateParts = dateStr.split('/', 0);
        if (dateParts.size() != 3) throw new InvalidMMDDYYYDateException(Label.Not_a_valid_date + dateStr);
        //MM/dd/yyyy
        return Date.newInstance(Integer.valueOf(dateParts[2]), Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]));    
    }
    
    public class PricebookLineFilterInfo {
        public Id companyId {get;set;}
	    public Id productId {get;set;}
	    public Id productGroupId {get;set;}
	    public Id hierarchyId {get;set;}
	    public Id pricebookId {get;set;}
	    public String fromDateStr {get;set;}
	    public String toDateStr {get;set;}
	    public Decimal price {get;set;}
	    
	    public Boolean hasDatesOrPrices() {
	        return !String.isBlank(fromDateStr) || !String.isBlank(toDateStr) || (price != null && price > 0);
	    }
    }
    
    @RemoteAction 
    public static DataSourceResult getPricebookLinesUsingFilters(PricebookLineFilterInfo filterInfo) {
        return getPricebookLines(filterInfo.companyId, filterInfo.productId, filterInfo.productGroupId, filterInfo.hierarchyId, 
                                                        filterInfo.pricebookId, filterInfo.fromDateStr, filterInfo.toDateStr, filterInfo.price);
    }
    
    @RemoteAction 
    public static DataSourceResult getPricebookLines(Id companyId, Id productId, Id productGroupId, Id hierarchyId, 
                                                        Id pricebookId, String fromDateStr, String toDateStr, Decimal price) {
        Date fromDate, toDate;
        if (!String.isBlank(fromDateStr)) {
            fromDate = parseDateInFormat_MM_DD_YYYY(fromDateStr);
        }
        
        if (!String.isBlank(toDateStr)) {            
            toDate = parseDateInFormat_MM_DD_YYYY(toDateStr);
        }
        
        Set<Id> productIds = new Set<Id>();
        Set<Id> productGroupIds = new Set<Id>();
        
        // Load all related product and product groups for the passed in data
        if (FindRelatedProductAndGroups) {
            if (productId != null || productGroupId != null) {
            	
		        SOQLUtil soql = new SOQLUtil('Product__c');
			    soql.addFields(new Set<String>{'Id', 'Product_Group__c'});
			    
                //String productSoql = 'Select Id, Product_Group__c from Product__c Where ';
                String productSoqlWhereClause = '';
            
                if (productId != null) {
                    productSoqlWhereClause += ' ID =:productId';
                }
                if (productGroupId != null) {
                    if (!String.isBlank(productSoqlWhereClause)) {
                        productSoqlWhereClause += ' OR ';    // OR it with product id
                    } 
                    productSoqlWhereClause += '  Product_Group__c =:productGroupId';                    
    
                    // safe side backup of a situation when product group doesn't has any products
                    productGroupIds.add(productGroupId);
                }        
                // create complete soql
                //productSoql += productSoqlWhereClause;
                
                soql.setWhereClause(productSoqlWhereClause);
	    
                for (Product__c prod : Database.query(soql.getQuery())) {
                    productIds.add(prod.Id);
                    
                    if (prod.Product_Group__c != null) 
                    	productGroupIds.add(prod.Product_Group__c);
                }
            }
        } else {
            if (productId != null) {
                productIds.add(productId);
            }
            
            if (productGroupId != null) {
                productGroupIds.add(productGroupId);
            }
        }
 
        // Create where clause for loading Pricebook lines

        String whereClause = ' Pricebook__r.Company__c  = :companyId '; // to avoid AND issues

        // OTC-343
            if (!productIds.isEmpty()) {
                whereClause += ' AND Product__c IN :productIds';
            }
            if (!productGroupIds.isEmpty()) {
            whereClause += ' AND (Product__r.Product_Group__c IN :productGroupIds OR Product_Group__c IN :productGroupIds)';
            }        
        
        if (fromDate != null && toDate != null) {
            // EFED > FD && EFSD < TD
            whereClause += ' AND End_Date__c >= :fromDate AND Start_Date__c <= :toDate';
        } else {
            if (fromDate != null) {            
                whereClause += ' AND Start_Date__c <= :fromDate AND End_Date__c >= :fromDate';
            }
            
            if (toDate != null) {
                whereClause += ' AND Start_Date__c <= :toDate AND End_Date__c >= :toDate';
            }    
        }
        
        set<id> hierarchyChildren = new set<id>();
        if (hierarchyId != null) {
            hierarchyChildren.add(hierarchyId );
            
            //try { // OTC-377 we need a list of all children which have this hierarchy record as a parent
                // the property we use is that ==> Path of my children contains my path, starting from position 0
                // 

				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('Hierarchy__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','path__c'
				});
				soql.setWhereClause('id = :hierarchyId');
				soql.setLimit(1);

				Hierarchy__c tmp = Database.query(soql.getQuery());

                string likestr = tmp.Path__c+ '%';            
                
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Hierarchy__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id'
				});
				soql.setWhereClause('path__c like :likestr and current_bool__c = true');
				
				hierarchyChildren.addAll ( KSE.grepIdSetFromList(Database.query(soql.getQuery())));
            //} catch( exception e ) { 
            
            //} 
            
            whereClause += ' AND (Product__r.Sales_Hierarchy__c in :hierarchyChildren OR Product_Group__r.Hierarchy__c = :hierarchyId) ';
            
        }
        
        if (pricebookId != null) {
            whereClause += ' AND Pricebook__c = :pricebookId ';
        }
        
        if (price != null) {
            whereClause += ' AND Price__c = :price ';
        }
        
        whereClause += ' ORDER BY Product_Group__r.Name NULLS LAST';
        
        SOQLUtil soql = new SOQLUtil('Pricebook_Line__c');
        soql.addFields(Pricebook_FieldSet_Name);
        soql.addFields(new Set<String>{'Product__r.Sales_Hierarchy__c','Product__r.Sales_Hierarchy__r.Path__c','Product_Group__r.Hierarchy__c'});
        soql.setWhereClause(whereClause);
        
        List<sObject> result = Database.query(soql.getQuery());   

        return new DataSourceResult(result, result.size());
    }
    
    public abstract class BaseRelatedFilterLimiter implements KendoExt.I_RelatedFilterLimiter {
        public Set<Id> recordIds;
        public KendoExt.LoadRecordsRelatedFilterInfo filterInfo;
        public PricebookLineFilterInfo pblFilterInfo;
        
        public void setLoadRecordsRelatedFilterInfo(KendoExt.LoadRecordsRelatedFilterInfo filterInfo) {
            this.filterInfo = filterInfo;
            FindRelatedProductAndGroups = false;
            this.pblFilterInfo =  (PricebookLineFilterInfo)JSON.deserialize( JSON.serialize(filterInfo.relatedFilterValues), PricebookLineFilterInfo.class);
        }
    }


    public class HierarchyRelatedFilterLimiter extends BaseRelatedFilterLimiter {
        public Boolean hasRelevantIds() {
            return  pblFilterInfo.pricebookId != null || pblFilterInfo.productId != null || pblFilterInfo.productGroupId != null || pblFilterInfo.hasDatesOrPrices();
        }
        
        public Set<Id> getRelevantIds() {
            DataSourceResult result = getPricebookLinesUsingFilters(pblFilterInfo);
            Set<Id> recordIds = new Set<Id>();
            if (result.total > 0) {
                
                set<string>allParentsSet = new set<string>();
                for (Pricebook_Line__c pbl : (Pricebook_Line__c[])result.records) {

                    if (pbl.Product__r.Sales_Hierarchy__c != null) {
                        recordIds.add(pbl.Product__r.Sales_Hierarchy__c);
                        
                        string tmp =  pbl.Product__r.Sales_Hierarchy__r.Path__c; // OTC-377
                        if ( tmp != null ) {	                    		
                            allParentsSet.addAll( tmp.split( '\\|' ) );
                        }
                    }
                
                    if (pbl.Product_Group__r.Hierarchy__c  != null){ 
                    	recordIds.add(pbl.Product_Group__r.Hierarchy__c );
                    }                    
                    
                } 
                
                //  OTC-377 pull the parents from here to top so that we can filter by larger groups
                // this depends on path being somewhat correct
                if ( ! allParentsSet.isEmpty() ){

					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					
					SOQLUtil soql = new SOQLUtil('Hierarchy__c', true); //enforceFLS=true, running in user mode
					soql.addFields(new set<string>{
						'id'
					});
					soql.setWhereClause('Name in :allParentsSet and Current_bool__c = true');
					
					recordIds.addAll( KSE.grepIdSetFromList( Database.query(soql.getQuery())));
            	}
            }
            return recordIds;
        }
    }

    
    
    public class PricebookRelatedFilterLimiter extends BaseRelatedFilterLimiter {
        public Boolean hasRelevantIds() {
            return  pblFilterInfo.hierarchyId != null || pblFilterInfo.productId != null || pblFilterInfo.productGroupId != null || pblFilterInfo.hasDatesOrPrices();
        }
        
        public Set<Id> getRelevantIds() {
            DataSourceResult result = getPricebookLinesUsingFilters(pblFilterInfo);
            Set<Id> pricebookIds = new Set<Id>();
            if (result.total > 0) {
                for (Pricebook_Line__c pbl : (Pricebook_Line__c[])result.records) {
                    if (pbl.Pricebook__c != null) pricebookIds.add(pbl.Pricebook__c);
                } 
            }
            return pricebookIds;
        }
    }
    
    public class ProductGroupRelatedFilterLimiter extends BaseRelatedFilterLimiter {
        public Boolean hasRelevantIds() {
            return pblFilterInfo.hierarchyId != null || pblFilterInfo.productId != null || pblFilterInfo.pricebookId != null || pblFilterInfo.hasDatesOrPrices();
        }
        
        public Set<Id> getRelevantIds() {
            DataSourceResult result = getPricebookLinesUsingFilters(pblFilterInfo);
            Set<Id> recordIds = new Set<Id>();
            if (result.total > 0) {
                for (Pricebook_Line__c pbl : (Pricebook_Line__c[])result.records) {
                    if (pbl.Product_Group__c != null) recordIds.add(pbl.Product_Group__c);
                } 
            }
                
            return recordIds;
        }
    }
    
    public class ProductRelatedFilterLimiter extends BaseRelatedFilterLimiter {
        public Boolean hasRelevantIds() {
            return pblFilterInfo.hierarchyId != null || pblFilterInfo.productGroupId != null || pblFilterInfo.pricebookId != null || pblFilterInfo.hasDatesOrPrices();
        }
        
        public Set<Id> getRelevantIds() {
            DataSourceResult result = getPricebookLinesUsingFilters(pblFilterInfo);
            Set<Id> recordIds = new Set<Id>();
            if (result.total > 0) {
                for (Pricebook_Line__c pbl : (Pricebook_Line__c[])result.records) {
                    if (pbl.Product__c != null) recordIds.add(pbl.Product__c);
                } 
            }
            return recordIds;
        }
    }
    
}