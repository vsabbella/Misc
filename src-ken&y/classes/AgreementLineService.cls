public class AgreementLineService {

    /**
     * @description  called from sales agreement line trigger when inserting new records,
     * task is to set the line numbers on each record
     */
    public static void setLineNumbers() {
        if(trigger.isBefore) {

            Boolean setLineNumbers = false;
            if(trigger.isInsert){

                setLineNumbers = true;

            } else if(trigger.isUpdate){

                setLineNumbers = false;

                for(Agreement_Line__c soLine: (list<Agreement_Line__c>)trigger.new) {
                    if(KSE.isFieldChanging('Line__c',soLine,trigger.oldMap)){
                        setLineNumbers = true;
                        break;
                    }
                }
            }

            if(setLineNumbers){

                List<SObject> soLines = KSE.setLineNumbers((List<SObject>)trigger.new);
            }
        }
    }

 //sets list price of product from pricebook for customer   
  

/*
public static Map<String,Decimal> fetchPrice(List<Product__c> pList,set<Id> agreementIds ) {
    
    SOQLUtil soql = new SOQLUtil('Agreement__c', true); //enforceFLS=true, running in user mode
	soql.addFields(new set<string>{
			'id','company__c','start_date__c','end_date__c','status__c','Ship_To__c','Site__c','Currency__c','Sold_To__c' 
	 });
	soql.setWhereClause('Id IN :agreementIds');

	Map<Id, Agreement__c> mAgreements = new Map<Id, Agreement__c>((List<Agreement__c>)Database.query(soql.getQuery()));
    
    set<Id> custIds = new set<Id>();
    set<Id> companyIds = new set<Id>(); 
    set <Id> transactionCurrency = new set<Id>(); 
    for(Agreement__c a: mAgreements.values()){
        if(a.Sold_To__c != null){
           custIds.add(a.Sold_To__c); 
        }  
        if(a.company__c != null){
           companyIds.add(a.company__c); 
        }
        if(a.Currency__c != null){
            transactionCurrency.add(a.Currency__c);
        }
    }
    
    soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Pricebook__c','Record_Type_Name__c'
		});
		soql.setWhereClause('id in :custIds AND Pricebook__c != null');

		list<Customer__c> cusList = Database.query(soql.getQuery());
    
    
    set<id> productIds = new set<id>();
    set<id> pricebookIds = new set<id>();
    
    for(Product__c p: pList){
        productIds.add(p.id);
    }   
    
    Date efd = system.today();
    
    soql = new SOQLUtil('Pricebook_Line__c', true); //enforceFLS=true, running in user mode
	soql.addFields(new set<string>{
		'Id','Price__c','Pricebook__c','Product__c','Pricebook__r.Company__c','Pricebook__r.Default__c','Price_Type__c','Pricing_UOM__c'     
	});
	soql.setWhereClause('product__c in :productIds  AND Start_date__c <= :efd AND (End_date__c = null OR End_date__c >= :efd) AND Pricebook__r.Company__c in :companyIds AND Pricebook__r.Currency__c in :transactionCurrency');
	List<Pricebook_Line__c> pblList = Database.query(soql.getQuery());
											
	Map<String,Decimal> pbLineRentalPriceMap = new Map<String,Decimal>();
	Map<id,Pricebook_Line__c> pbidToPricebookLineMap = new Map<id,Pricebook_Line__c>();	
    
    
    for (Pricebook_Line__c pbl: pblList) {
        pbidToPricebookLineMap.put(pbl.Pricebook__c, pbl);
        if(!cusList.isEmpty()){
        for(Customer__c c: cusList){
              if(pbidToPricebookLineMap.containsKey(c.Pricebook__c)  ){
                  if(pbl.Pricing_UOM__c != null && pbl.Price__c != null && pbl.Price_Type__c  == 'Recurring'){
                   pbLineRentalPriceMap.put(pbidToPricebookLineMap.get(c.Pricebook__c).Product__c +'-'+ pbidToPricebookLineMap.get(c.Pricebook__c).Pricing_UOM__c, pbidToPricebookLineMap.get(c.Pricebook__c).Price__c);   
                  }else if(pbl.Pricing_UOM__c == null && pbl.Price__c != null && pbl.Price_Type__c  == 'Sales'){
                    pbLineRentalPriceMap.put(pbidToPricebookLineMap.get(c.Pricebook__c).Product__c +'-'+ pbidToPricebookLineMap.get(c.Pricebook__c).Pricing_UOM__c, pbidToPricebookLineMap.get(c.Pricebook__c).Price__c);  
                  }
                  
              }
         }  
    }else if(pbl.Pricebook__r.Default__c == true){
          if(pbl.Pricing_UOM__c != null && pbl.Price__c != null && pbl.Price_Type__c  == 'Recurring'){
               pbLineRentalPriceMap.put(pbl.Product__c +'-'+ pbl.Pricing_UOM__c,pbl.Price__c); 
          } else if(pbl.Pricing_UOM__c == null && pbl.Price__c != null && pbl.Price_Type__c  == 'Sales'){
              pbLineRentalPriceMap.put(pbl.Product__c +'-'+ pbl.Pricing_UOM__c,pbl.Price__c);
          } 
        }
            
     } 
   
    return pbLineRentalPriceMap; 
      
	}  
    */
//sets product category on agreement lines    
public static void  getProductCategory(List <Agreement_Line__c> arlList) { 
    set<id> pId = new set<id>();
    for(Agreement_Line__c al:arlList){
        if(al.Product__c != null){
         pId.add(al.Product__c);   
        }
    }    
    List<product__c> pList = [SELECT Id,Billing_Category__c,Fulfillment_Category__c FROM Product__c
                             WHERE Id IN :pId];
    map<id,string> pToBCMap = new map<id,string>();
    map<id,string> pToFCMap = new map<id,string>();
    for(product__c p:pList){
        pToBCMap.put(p.id,p.Billing_Category__c);
        pToFCMap.put(p.id,p.Fulfillment_Category__c);
    }
    for(Agreement_Line__c al:arlList){
        if(pToBCMap.containsKey(al.Product__c) && al.Billing_Category__c == null){
          al.Billing_Category__c   = pToBCMap.get(al.Product__c);  
        }
        if(pToFCMap.containsKey(al.Product__c) && al.Fulfillment_Category__c == null){
          al.Fulfillment_Category__c   = pToFCMap.get(al.Product__c);  
        }
        
    }
    
}   
    
   
 //sets agreement price depending on item spec price spec flag   
    public static void  getParentAgreementLineAgPrice(List <Agreement_Line__c> arlList) {
    set<Id> pIds = KSE.grepRelatedIdSetFromList(arlList,'Product__c',true);
    list<Product__c> pList = [Select id, name, product_type__c, Item__c From Product__c
                                            WHERE id IN :pIds ]; 
    set<id> itemSet = new set<id>();    
     for(Product__c p:pList ){
        itemSet.add(p.Item__c);    
     }   
     LIST<Item_Specification__c > speclist = [Select Item__c,Price_Spec_Only__c  
                                            From Item_Specification__c
                                            WHERE Item__c  IN :itemSet];  
      boolean priceFlag = false;  
     for(Item_Specification__c iSp: speclist){
         if(iSp.Price_Spec_Only__c == true){
            priceFlag = true; 
         }    
     } 
        
     for(Agreement_Line__c a:arlList){
        if(a.Agreement_Price__c == null){   
           if(priceFlag){
            a.Agreement_Price__c = a.List_Price__c;
           } else {
               a.Agreement_Price__c = 0;
           }
        }   
      }   
       DML.updateAsUser(arlList);
    }       
 
 public static void  setUpdatable(List <Agreement_Line__c> arlList) {  
        list<Agreement_Line__c> aList = new list<Agreement_Line__c>();
        for(Agreement_Line__c al:arlList){
            al.Updatable__c = false;
            aList.add(al);
        }
        DML.updateAsUser(aList);
    
 }  
    
    //
    @future
    public static void  setUpdatableAsync(set <id> arlId) {
    
     list<Agreement_Line__c> arlList = [SELECT id FROM Agreement_Line__c
                                     WHERE ID IN :arlId];
        for(Agreement_Line__c al:arlList){
           al.Updatable__c = false; 
        }   
         DML.updateAsUser(arlList);
    }  
//set end date according to new revised agreement line
public static void  setEndDateOFRevisedAgreementLine(List <Agreement_Line__c> arlList) {
    system.debug('arlList'+arlList);
    set<id> aglIds = new set<id>(); 
	list<Agreement_Line__c> aList = new list<Agreement_Line__c>();
    list<Agreement_Line__c> aNewList = new list<Agreement_Line__c>();
    Map<id,Agreement_Line__c> aglRevToAglMap = new Map<id,Agreement_Line__c> (); 
    for(Agreement_Line__c al:arlList){
        aglIds.add(al.Revised_Agreement_Line__c);
        aglRevToAglMap.put(al.Revised_Agreement_Line__c,al);
    }
    system.debug('aglRevToAglMap'+aglRevToAglMap);
    list<Agreement_Line__c> agllist = [SELECT id,start_date__c,End_date__c 
                                      FROM Agreement_Line__c
                                      WHERE ID IN :aglIds];
   system.debug('agllist'+agllist);
    for(Agreement_Line__c a: agllist){
        if(aglRevToAglMap.get(a.id).Revision_Approval_date__c != null){
           if(aglRevToAglMap.get(a.id).Revision_Approval_date__c <= aglRevToAglMap.get(a.id).start_date__c){
                a.End_Date__c =  aglRevToAglMap.get(a.id).start_date__c;
                //a.End_Date__c =  aglRevToAglMap.get(a.id).start_date__c.addMinutes(-1);
                a.Revised__c = true; 
                a.Revision_Status__c = 'Revised' ;
                a.Occurrence_Count__c = null;
            }else{
               a.End_Date__c =  aglRevToAglMap.get(a.id).Revision_Approval_date__c; 
               //a.End_Date__c =  aglRevToAglMap.get(a.id).Revision_Approval_date__c.addMinutes(-1);
               aglRevToAglMap.get(a.id).start_date__c = aglRevToAglMap.get(a.id).Revision_Approval_date__c;
               a.Revised__c = true; 
               a.Revision_Status__c = 'Revised' ; 
               a.Occurrence_Count__c = null; 
           }    
        }
     
     aNewList.add(aglRevToAglMap.get(a.id));
     aList.add(a);   
    }
    DML.updateAsUser(aNewList);
    DML.updateAsUser(aList);	
    
}            
    
     
//set end date according to occurence count
public static void  setEndDate(List <Agreement_Line__c> arlList) {
    list<Agreement_Line__c> agllist = new list<Agreement_Line__c>();
	  
    	for(Agreement_Line__c al:arlList){
            decimal val = al.Occurrence_Count__c;
    		if(al.Start_Date__c != null && al.Agreement__r.Activation_Date__c == null && val != null){
                
                if(al.Occurrence__c == 'Monthly'){
                    al.End_Date__c = al.Start_Date__c.addMonths(val.intValue()) - 1;
                }
	         	if(al.Occurrence__c == 'Quarterly'){
                     al.End_Date__c = al.Start_Date__c .addMonths((val.intValue()* 3)) - 1; 
                }
            }else{
                    if(al.Occurrence__c == 'Monthly' && al.Agreement__r.Activation_Date__c != null && val != null){
                      al.End_Date__c = al.Agreement__r.Activation_Date__c.addMonths(val.intValue()) - 1;  
                    }
                    if(al.Occurrence__c == 'Quarterly' && al.Agreement__r.Activation_Date__c != null && val != null ){
                      al.End_Date__c = al.Agreement__r.Activation_Date__c.addMonths((val.intValue()* 3)) - 1;  
                    }
               }
                
                 agllist.add(al);   
                
    		
        }
    	if(!agllist.isEmpty()){
        	DML.updateAsUser(agllist);
    	}
    
}     
 public static void setQuantities(Set<Id> aglIds, List<Fulfillment__c> fulfillments) {
        Map<Id, Agreement_Line__c> mAgreementLines = new Map<Id, Agreement_Line__c>([SELECT Id, Sold_Quantity__c, Remaining_Quantity__c
                                                    FROM Agreement_Line__c
                                                    WHERE Id in :aglIds]);

        for (Fulfillment__c f : fulfillments) {
            if(mAgreementLines.containsKey(f.Agreement_Line__c)) {
            	
                Agreement_Line__c parentAgl = mAgreementLines.get(f.Agreement_Line__c);
                
                //parentAgl.Sold_Quantity__c = parentAgl.Sold_Quantity__c == null ? 0 : parentAgl.Sold_Quantity__c;
                parentAgl.Sold_Quantity__c += f.Quantity__c;

                //parentAgl.Remaining_Quantity__c = parentAgl.Remaining_Quantity__c == null ? 0 : parentAgl.Remaining_Quantity__c;
                parentAgl.Remaining_Quantity__c -= f.Quantity__c;
                
            }
        }
        DML.updateAsUser(mAgreementLines.values());

    }
	/*  KNDY-12306
		1. Build a query on agreement line, get all the params required
		2. double loop on agreement lines and fulfillments
		3. set activation date (label is acceptance) on agreement based on wether fulfillment has price type of recurring or not
		4. if we are releasing our first set of fulfillments (plural), then the one with the earliest data (start date or fulfillment date based on price type)
		   gets set as acceptance date.
		5. separate method on AgreementService that sets RecurrenceStartDate on AG!
	
	*/
    public static void setAcceptanceDate(set<id> aglineIds , List<Fulfillment__c> fulfillments) {
        Map<Id, Agreement__c> mAgreement = new Map<Id, Agreement__c>();
        SOQLUtil soql = new SOQLUtil('Agreement_line__c', false); //enforceFLS=false, running in system mode
		soql.addFields(new set<string>{
			'Id','Price_type__c','Agreement__r.Activation_Date__c','Agreement__r.Agreement_Type__c','Agreement__r.Company__r.Populate_Acceptance_Date_On_Agreement__c',
			'Agreement__r.Recurrence_Start_Date__c','Agreement__r.Billing_UOM__c',  'Agreement__c',
			'Agreement__r.Company__r.Populate_Acceptance_Date_On_Agreement__c','Agreement__r.Recurrence_Start_Date__c','Agreement__r.Billing_UOM__c'
		});
		soql.setWhereClause('Id in :aglineIds');

        for(Agreement_Line__c agl : Database.query(soql.getQuery())) {
        	system.debug('agl');
	        for (Fulfillment__c f : fulfillments) {
	            
                 if(f.Agreement_Line__c == agl.ID) {
                    if(agl.Agreement__r.Activation_Date__c == null && agl.Agreement__r.Company__r.Populate_Acceptance_Date_On_Agreement__c == true){
					  Date activationDate = agl.Price_Type__c == 'Recurring'? f.Start_Date__c.date() : f.Fulfillment_Date__c.date();
					  
					  if(!mAgreement.containsKey(agl.Agreement__c))
                     	mAgreement.put(agl.Agreement__c, new Agreement__c (Id = agl.Agreement__c, Activation_Date__c = activationDate));  
                      else {
                    	Date activationDateOnAg = mAgreement.get(f.Agreement__c).Activation_Date__c;
                    	if(activationDateOnAg > activationDate)
                    		mAgreement.put(agl.Agreement__c, new Agreement__c (Id = agl.Agreement__c, Activation_Date__c = activationDate));
	                    }
                    }
                }   
            }
        }
        if(!mAgreement.isEmpty())
        	DML.updateAsUser(mAgreement.values());


} 

 public static void agreementLinePricing(List<Agreement_Line__c> agreementLines){

		for(Agreement_Line__c agl : agreementLines){
		    
			Date sd = agl.Start_Date__c == null ? system.today() : Date.newInstance(agl.Start_Date__c.year(), agl.Start_Date__c.month(), agl.Start_Date__c.day());
			Date ed = agl.End_Date__c == null ? system.today() : Date.newInstance(agl.End_Date__c.year(), agl.End_Date__c.month(), agl.End_Date__c.day());
			
			if(agl.Sales_Agreement_Quantity__c != null){
				decimal occMult = PricingService.occurrenceMultiplier(sd, ed, PricingService.getOccurrence(agl.Pricing_UOM_Recurrence__c), sd.day(),PricingService.getEvery(agl.Pricing_UOM_Every__c));
            if(agl.revision_status__c != 'Revised'){
               if(PricingService.getOccurrence(agl.Pricing_UOM_Recurrence__c) == PricingService.Occurrence.IMMEDIATE){
                  agl.Total_Agreement_Quantity__c  = agl.Sales_Agreement_Quantity__c;  
                }else{
                   agl.Total_Agreement_Quantity__c  = agl.Sales_Agreement_Quantity__c * occMult;
                } 
            }
           } 

		}

    }
    
    
}