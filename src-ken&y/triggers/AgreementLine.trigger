trigger AgreementLine on Agreement_Line__c (before insert, before update,after insert, after update, after delete, after undelete) {
	if(DML.checkTriggerDispatch(Agreement_Line__c.getSobjectType())){return;}
		if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
        AgreementLineService.setLineNumbers(); //line numbers are required for agreement pricing to work
		
		AgreementLineService.getProductCategory(trigger.new) ;
        list<Product__c> prList = new list<Product__c>();
        
        set<id> cusSet = new set<id>();
        set<id> pSet = KSE.grepRelatedIdSetFromList(Trigger.new, 'Product__c', true);
        set<Id> agreementIds = KSE.grepRelatedIdSetFromList(Trigger.new, 'Agreement__c', true);
        

		SOQLUtil soql = new SOQLUtil('Product__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
            'id','Item__c','Usage_Based__c', 'Product_Group__c'
		});
		soql.setWhereClause('id in :pSet');

		list<Product__c> pList = Database.query(soql.getQuery());

		Map<Id, Product__c> mProducts = new Map<Id, Product__c>(pList);

        
        soql = new SOQLUtil('Agreement__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
            'id','company__c','status__c','Ship_To__c','Site__c', 'sold_to__c', 'Sold_to__r.Pricebook__c', 'Sold_to__r.Customer_Group__c', 'currency__c', 'customer__c',
			'start_date__c','end_date__c','Recurrence_Start_Date__c'
		});
		soql.setWhereClause('Id IN :agreementIds');

		Map<Id, Agreement__c> mAgreements = new Map<Id, Agreement__c>((List<Agreement__c>)Database.query(soql.getQuery()));

        List<Agreement_Line__c> aglList = Trigger.New;

        for (Agreement_Line__c agl : aglList){
            agl.Product__r = mProducts.get(agl.Product__c);
            agl.Agreement__r = mAgreements.get(agl.Agreement__c);
        }

		//KNDY-14394: Pricebook on agreement Line
		/*
		Invoke the PricingService.fetchSOLinesPriceBookInfo with following info
			1. Product's product group
			2. Agreement's sold to customer
			3. Agreement's sold to customer's pricebook
			4. Agreement's sold to customer's customer group
			5. Agreement's currency
		Method returns a map with key as 'Agreement ID - Line number'
		*/
		Map<String,Pricebook_Line__c> pbLineRentalPriceMap = new Map<String,Pricebook_Line__c>();
		pbLineRentalPriceMap = PricingService.fetchSOLinesPriceBookInfo(aglList);

        for(Agreement_Line__c al : Trigger.new){

            if (pbLineRentalPriceMap.containsKey(al.Agreement__c + '-' + al.Line__c)) {
                al.List_Price__c = pbLineRentalPriceMap.get(al.Agreement__c + '-' + al.Line__c).Price__c;
                al.Pricebook__c = pbLineRentalPriceMap.get(al.Agreement__c + '-' + al.Line__c).Pricebook__c;
			}

			if (al.list_price__c == null){
				al.list_price__c = 0;
			}

			if (al.agreement_price__c == null ||
					(al.Price_Type__c  == 'Recurring' && KSE.isFieldChanging('Pricing_UOM__c', al, Trigger.oldMap)) ||
					(KSE.isFieldChanging('list_price__c', al, Trigger.oldMap))) {
				if(al.agreement_Price__c == null){
					al.agreement_price__c = al.List_Price__c;	
				}
				
			}

            if (al.agreement_price__c == null){
				al.addError('Cannot find Agreement Price for Agreement Line.');
			}

			if (al.Price_Type__c  == 'Recurring' && al.Pricing_UOM__c == null){
				al.addError('Pricing UOM cannot be blank for recurring agreement line');
			}

            if(mAgreements.containsKey (al.Agreement__c)){
            	if(al.Unit_Cost__c == null && al.Start_Date__c != null){
            		Date stDt = Date.newInstance(al.Start_Date__c.year(), al.Start_Date__c.month(), al.Start_Date__c.day());
            		if(al.Product__c != null){
	            		al.Unit_Cost__c = ItemService.getActiveStandardCost(mProducts.get(al.Product__c).Item__c,  mAgreements.get(al.Agreement__c).company__c, null, stDt);
            		}else{
            			al.addError('Product cannot be blank for an Agreement Line');
            		}
	            }
                if( al.Ship_To__c == null && mAgreements.get(al.Agreement__c).Ship_To__c != null)  {
                    al.Ship_To__c = mAgreements.get(al.Agreement__c).Ship_To__c;            
                } 
                if( al.Customer_Site__c == null && mAgreements.get(al.Agreement__c).Site__c  != null)  {
                    al.Customer_Site__c  = mAgreements.get(al.Agreement__c).Site__c ;            
                } 
            	
               /* if(al.Start_Date__c == null && mAgreements.get(al.Agreement__c).Start_Date__c != null)  {
                    al.Start_Date__c = mAgreements.get(al.Agreement__c).Start_Date__c;            
                } 

                if(al.End_Date__c == null && mAgreements.get(al.Agreement__c).End_Date__c != null) {
                    al.End_Date__c = mAgreements.get(al.Agreement__c).End_Date__c;
                } */

                if(mAgreements.get(al.Agreement__c).Status__c == 'Draft' || (al.Revision_Status__c != 'Approved'&& al.Revision_Status__c != 'Revised' && al.Revision_Status__c != null)) {
                    if(PricingService.getOccurrence(al.Pricing_UOM_Recurrence__c)  == PricingService.Occurrence.IMMEDIATE){
                    al.Remaining_Quantity__c = al.Sales_Agreement_Quantity__c;
                     al.Sold_Quantity__c = 0;
                }
               		else{
                     al.Remaining_Quantity__c = al.Total_Agreement_Quantity__c ;
                    al.Sold_Quantity__c = 0;   
        	}
        
                }
        	}
                
        }
          
          AgreementLineService.agreementLinePricing(trigger.new);
          PricingService.agreementLinePricing(trigger.new);
        }
    if (trigger.isBefore && trigger.isInsert  ){
        
        set<Id> agreementIds = KSE.grepRelatedIdSetFromList(Trigger.new, 'Agreement__c', true);
        
   		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Agreement__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','company__c','start_date__c','end_date__c','status__c'
		});
		soql.setWhereClause('Id IN :agreementIds');
		
		Map<Id, Agreement__c> mAgreements = new Map<Id, Agreement__c>((List<Agreement__c>)Database.query(soql.getQuery()));
    
        integer revNumber = 0;
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Set<Id> aggrementIds = mAgreements.keySet();
		
		soql = new SOQLUtil('Agreement_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Revision_Number__c','Revision_Status__c'
		});
		soql.setWhereClause('Agreement__c IN :aggrementIds AND Agreement__r.status__c = \'Approved\' AND Revision_Number__c != null');
		soql.setOrderByClause('Revision_Number__c DESC');
		soql.setLimit(1);
	
		list<Agreement_Line__c> agreementLine = Database.query(soql.getQuery());
	
        for(Agreement_Line__c al : agreementLine){
            if( al.Revision_Number__c != 0 && al.Revision_Status__c == 'Pending Approval'){
                revNumber = al.Revision_Number__c.intValue();
            }else{
                revNumber = al.Revision_Number__c.intValue() + 1;
            }
        }
    
    
        for(Agreement_Line__c al : Trigger.new){
            if(mAgreements.containsKey (al.Agreement__c)){
            	
                if(mAgreements.get(al.Agreement__c).Status__c == 'Approved' && al.Revision_Status__c == null) {
                    al.Revision_Status__c = 'Pending Approval';
                    al.Updatable__c = true;
                   al.Revision_Number__c = revNumber;
                }
        	}
        }
 
  }
    
    
if(trigger.isAfter ){
	if(trigger.isInsert){
 		set<id> aglId = new set<id>();
        
        for (Agreement_Line__c al: Trigger.new) {
			aglId.add(al.id);
		}
       
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Agreement_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Start_Date__c','End_Date__c','Occurrence_Count__c','Occurrence__c','Agreement__r.Activation_Date__c'
		});
		soql.setWhereClause('ID IN :aglId');

		list<Agreement_Line__c> aList = Database.query(soql.getQuery());

       	AgreementLineService.setEndDate(aList) ; //sets end date based on occurence count,occurence,start date or acceptance date.(insert)

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Agreement_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Agreement_Price__c','list_price__c','Sales_Agreement_Quantity__c','Product_Type__c','Agreement__c','Agreement__r.Start_Date__c',
			'Agreement__r.End_Date__c','Unit_Cost__c','Product__c'
		});
		soql.setWhereClause('ID IN :aglId AND Product_Type__c = \'Configurable\'');
		
		list<Agreement_Line__c> arlList = Database.query(soql.getQuery());
		
        AgreementLineService.getParentAgreementLineAgPrice(arlList);
           
	}
      
		if(trigger.isUpdate ){//sets end date based on occurence count,occurence,start date or acceptance date.(update)  
	        set<id> aglId =new set<id>();
	        set<id> aId = new set<id>();   
	        set<id> allId = new set<id>();   
	        for (Agreement_Line__c al: Trigger.new) {
	            if (KSE.isFieldChanging('Start_Date__c', al, Trigger.oldMap) || 
	                KSE.isFieldChanging('Occurrence_Count__c', al, Trigger.oldMap) ||
	                KSE.isFieldChanging('Occurrence__c', al, Trigger.oldMap)){
	                  aglId.add(al.id);  
	                }
				if (KSE.isFieldChanging('Revision_Status__c', al, Trigger.oldMap) &&(al.Revision_Status__c =='Approved') ){
	                  aId.add(al.id);  
	                }
	            allId.add(al.id);
	            
			}
	        
	        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Agreement_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Start_Date__c','End_Date__c','Occurrence_Count__c','Occurrence__c','Agreement__r.Activation_Date__c'
			});
			soql.setWhereClause('ID IN :aglId AND Occurrence_Count__c != null');
			
			list<Agreement_Line__c> arlList = Database.query(soql.getQuery());
			
	      	AgreementLineService.setEndDate(arlList) ;  
	           
	        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			soql = new SOQLUtil('Agreement_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Revised_Agreement_Line__c','Revision_Approval_date__c','Start_Date__c','End_Date__c','Occurrence_Count__c','Occurrence__c',
				'Agreement__r.Activation_Date__c'
			});
			soql.setWhereClause('ID IN :aId');
			
			list<Agreement_Line__c> aglineList = Database.query(soql.getQuery());
			
			AgreementLineService.setEndDateOFRevisedAgreementLine(aglineList) ;   
	           
	        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			soql = new SOQLUtil('Agreement_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Updatable__c'
			});
			soql.setWhereClause('ID IN :allId AND (Revision_Status__c =\'Revised\') AND Updatable__c = true');
			
			list<Agreement_Line__c> allList = Database.query(soql.getQuery());
	
	        AgreementLineService.setUpdatable(allList) ;  
    	}
    }   
}