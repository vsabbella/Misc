public with sharing class PriceBookService {

	// TODO move these error messages into Labels
    public static string START_END_BLANK = 'start date and end date cannot be blank !';
    public static string END_LESSER_THAN_START = Label.End_date_should_be_greater_than_the_Start_date;
    public static string DATE_OVERLAP = Label.Start_and_End_dates_specified_overlap_with_existing_pricebook_lines;
	public static string DATE_OVERLAP_PRICE_TYPE = 'has overlaping date and price type with existing line';
	public static string DATE_OVERLAP_PRICING_UOM = 'has overlaping date, price type, and pricing UOM with existing line';
	public static string DATE_OVERLAP_TIERED_PRICING = 'has overlaping date and quantity range with existing line';

	public static String CHANGE_IN_HISTORIC_RULE = '{0} is active on past dates, so cannot be changed !';
	public static String ERROR_COMPANY_CANNOT_BE_MODIFIED = Label.Price_Book_Company_field_cannot_be_modified;
	/**
	 * This collection is a static placeholder to keep pricebook lines cloned out of EXPIRED lines. So that it could be used at 
	 * later time to insert. 
	 */
	public static List<Pricebook_Line__c> ClonedLinesForExpiry = new List<Pricebook_Line__c>();
    
    /**
     *  List of fields whose change will cause a pricebook line to expire. 
     *  Its kept it field set to make it easy to remove or add fields later wihtout code change.
     */
    public static List<String> FieldsLeading2ExpiryOfLine {
        get {
            if (FieldsLeading2ExpiryOfLine == null) {
                FieldsLeading2ExpiryOfLine = new List<String>();
                for (Schema.FieldSetMember fsm : Schema.SObjectType.Pricebook_Line__c.fieldSets.Field_Changes_For_Line_Expiry.getFields()) {
                    FieldsLeading2ExpiryOfLine.add(fsm.getFieldPath());
                }
            } 
            return FieldsLeading2ExpiryOfLine;    
        } private set;
    }
	
	public static Date today = System.today();
	/**
	 * Clears all the Price_2__c .... Price_n__c fields from the Pricebook_Line__c record
	 */ 
	public static void clearSubPriceFields(Pricebook_Line__c pbl) {
	    pbl.Price_2__c = null;
        pbl.Price_3__c = null;
        pbl.Price_4__c = null;                
        pbl.Price_5__c = null;
	}
	
	public static void areLinesValid( List< Pricebook_Line__c > pbLines, Boolean isInsert ){
		
		Set<Id> ListOfPriceBookIds = new Set<Id>(); 
		Set<Id> ListOfProductIds = new Set<Id>(); 
		Set<Id> ListOfProductGroupIds = new Set<Id>(); 
		Set<Id> customerIds = new Set<Id>();

		map<String, List<Pricebook_Line__c> > priceBookLinesByPriceBookProduct = new map<String, List<Pricebook_Line__c> >();

		Map<Id,Pricebook_line__c> updatePBLinesMap = new Map<Id,Pricebook_line__c>();
		
		for( Pricebook_Line__c pbLine : pbLines ){
			ListOfPriceBookIds.add(pbLine.PriceBook__c);
			ListOfProductIds.add( pbLine.Product__c);
			ListOfProductGroupIds.add( pbLine.Product_Group__c);
			
			customerIds.add(pbLine.Customer__c);

			// map of pbLines being updated
			if (pbLine.id != null && !isInsert){
				updatePBLinesMap.put(pbLine.id, pbLine);
			}
		}
	

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Pricebook_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Name','Customer__c','Product__c','Product_Group__c','Pricebook__c','Price__c','End_date__c','Min__c','Max__c','Use_Fixed_Pricing__c','Price_Type__c' ,'Pricing_UOM__c',
            'Start_date__c','Pricebook__r.Name'
        });
        soql.setWhereClause('( Product__c IN: ListOfProductIds OR Product_Group__c IN :ListOfProductGroupIds ) and (PriceBook__c IN: ListOfPriceBookIds) and Customer__c IN :customerIds');
        soql.setOrderByClause('End_date__c asc nulls last');
        for( Pricebook_Line__c pbl : Database.query(soql.getQuery())){




        	// create separate keys for Products and Product Groups


        	// if a line is being updated, use that line instead of existing line
        	Pricebook_Line__c selectedLine;
        	if (updatePBLinesMap.containsKey(pbl.id)){
        		selectedLine = updatePBLinesMap.get(pbl.id);
        	} else {
        		selectedLine = pbl;
        	}

        	// NOTE: BA - We could create the key with both Product and Product group instead of checking of values.
        	// create map of existing PBLs for for Products or Product Groups.
			if (!String.isBlank( selectedLine.Product_Group__c )) {
				checkAndUpdateMapForPricebookLine(priceBookLinesByPriceBookProduct, selectedLine, selectedLine.Product_Group__c);

			} else if (!String.isBlank(selectedLine.Product__c)) {
				checkAndUpdateMapForPricebookLine(priceBookLinesByPriceBookProduct, selectedLine, selectedLine.Product__c);									
			}			
		}

		
		for( Pricebook_Line__c pbLine : pbLines ){
			List< Pricebook_Line__c > relatedLines = new List<Pricebook_Line__c>();
			String key;

			if (!String.isBlank( pbLine.Product_Group__c )) {
			
				key = String.valueOf( pbLine.Pricebook__c ) + pbLine.Product_Group__c + '-' + pbLine.Customer__c ;
				
				if (priceBookLinesByPriceBookProduct.containsKey(key)) {
					relatedLines.addAll(priceBookLinesByPriceBookProduct.get(key));
				} else {
					priceBookLinesByPriceBookProduct.put(key, new List<Pricebook_Line__c>{pbLine});
				}

			} 

			else if (!String.isBlank(pbLine.Product__c)) {

				key = String.valueOf( pbLine.Pricebook__c ) + pbLine.Product__c + '-' +  pbLine.Customer__c;

				if (priceBookLinesByPriceBookProduct.containsKey(key)) {
					relatedLines.addAll(priceBookLinesByPriceBookProduct.get(key));
				} else {
					priceBookLinesByPriceBookProduct.put(key, new List<Pricebook_Line__c>{pbLine});
				}
			}

			if( !relatedLines.isEmpty())
				isLineValid( pbLine, relatedLines , isInsert );			
			
		}														 
		
	}
	
	// utility private method to check construct required map structure correctly
	static void checkAndUpdateMapForPricebookLine(	Map<String, List<Pricebook_Line__c>> priceBookLinesByPriceBookProduct, 
													Pricebook_Line__c pbl, 
													String keySuffix) {

		// add group as a key incase they are having any product
		String key = String.valueOf( pbl.Pricebook__c ) + keySuffix + '-' + pbl.Customer__c;
		List< Pricebook_Line__c > relatedPbLines = priceBookLinesByPriceBookProduct.get(key);

		if (relatedPbLines == null) {
			relatedPbLines = new List< Pricebook_Line__c >();
			priceBookLinesByPriceBookProduct.put( key, relatedPbLines );
		}
		relatedPbLines.add(pbl);
	}

	public static void isLineValid( Pricebook_Line__c newPBLine , List< Pricebook_Line__c > existingLines, Boolean isInsert ){
		
		if (!newPBLine.Use_Fixed_Pricing__c && (newPBLine.Min__c != null && newPBLine.max__c != null) && (newPBLine.Min__c != 0 && newPBLine.Max__c != 0) )  {

			if (newPBLine.Max__c < newPBLine.Min__c || newPBLine.Min__c == newPBLine.Max__c) {
				newPBLine.addError('Invalid min or max value - min: ' + newPBLine.min__c + ', max: ' + newPBLine.max__c);
				return;
			} 
		}

		if (newPBLine.Price_Type__c == 'Recurring' && newPBLine.Pricing_UOM__c == null){
			newPBLine.addError('Piricing UOM cannot be empty for recurring price type.');
		}

		if (newPBLine.Price_Type__c == 'Sales' ||  newPBLine.Price_Type__c == null){
			newPBLine.Price_Type__c = 'Sales';
			newPBLine.Pricing_UOM__c = null;
		}

		if (newPBLine.Use_Fixed_Pricing__c){
			newPBLine.Max__c = null;
			newPBLine.Min__c = null;
		}

		if( newPBLine.Start_Date__c == null || newPBLine.End_Date__c == null ){
			
			newPBLine.addError( START_END_BLANK );
		}
		if( newPBLine.End_Date__c < newPBLine.Start_Date__c ){
			
			newPBLine.addError( END_LESSER_THAN_START );
		}


		for( Pricebook_Line__c pbl : existingLines ){
			if( (isInsert) || ( !isInsert && newPBLine.id != pbl.id )){
			    
				if(
                     ( ( newPBLine.Start_Date__c >= pbl.Start_Date__c ) && ( newPBLine.Start_Date__c <= pbl.End_Date__c ) )
                  || ( ( newPBLine.End_Date__c >= pbl.Start_Date__c ) && ( newPBLine.End_Date__c <= pbl.End_Date__c) )
                  || ( ( newPBLine.Start_Date__c <= pbl.Start_Date__c ) && ( newPBLine.End_Date__c >= pbl.End_Date__c) ) 
				  ){
				  	
					String newPBLName = newPBLine.Name == null ? ' New pricebook line' : newPBLine.Name;
					// if Tiered PBLs
					if (!newPBLine.Use_Fixed_Pricing__c && !pbl.Use_Fixed_Pricing__c
						&& (pbl.Min__c != null && pbl.Max__c != null)) {
						
						if ( newPBLine.Min__c != null && (
	                    	(newPBLine.Min__c >= pbl.Min__c && newPBLine.Min__c <= pbl.Max__c) ||
	                    	(newPBLine.Max__c >= pbl.Min__c && newPBLine.Max__c <= pbl.Max__c) ||
	                    	(newPBLine.Min__c <= pbl.Min__c && (newPBline.Max__c >= pbl.Max__c || newPBLine.Max__c == null)) 
						)) {
							newPBLine.addError(newPBLName + ' ' + DATE_OVERLAP_TIERED_PRICING + ': ' + pbl.Name + '.');

						}
                            }

					// If recurring PBLs
					else if (newPBLine.Price_Type__c == 'Recurring' || pbl.Price_Type__c == 'Recurring') { //KNDY-11668 checks combination of pricing type and pricing UOM for rental pricing structure
						if (newPBLine.Pricing_UOM__c == pbl.Pricing_UOM__c && newPBLine.Price_Type__c == pbl.Price_Type__c) {
							newPBLine.addError( newPBLName + ' ' + DATE_OVERLAP_PRICING_UOM  + ': ' + pbl.Name + '.');
                         }
                    }

					// if standard PBL
					else {
						system.debug(newPBLine);
						system.debug(pbl);
						newPBLine.addError( newPBLName + ' ' + DATE_OVERLAP_PRICE_TYPE + ': ' + pbl.Name + '.');
					}
				} 
			}
		}
	}

    /* 
     * KNDY-6022  There should be code preventing deletion of an active PN Line.
     * called from pricebooklinetrigger.trigger
     */ 
    public static void checkActiveBeforeDelete( ) {
        if ( Trigger.isBefore && Trigger.isDelete ) {		
            for( Pricebook_Line__c pbl : (list<Pricebook_Line__c>)Trigger.old ) {

                // since we cannot re-query deleted objects, we must verify that the object passed in has a start date
                // if someone wants to delete a pbl, they will have to have the start_date field populated in that object
                // so that we can actually verify the record is not active
                // this assert is for the developers who would like to delete
                system.assert( pbl.Start_Date__c != null , 'expected a start date or we cannot delete a pricebook line'); // DO NOT TRANSLATE
                
                if ( pbl.Start_Date__c <= system.today() && (pbl.End_Date__c == null || pbl.End_Date__c >= system.today()) ) {
                    pbl.addError( Label.Cannot_delete_active_line );
                }
            }
        } 	
    }
    
	/*
		KNDY-2125: Bracket pricing, update pricebook lines as per bracket pricing.
	*/
	public static void populatePricesUsingBrackets(Pricebook_Line__c[] lines) {		        
        List<Pricebook_Line__c> relevantLines = new List<Pricebook_Line__c>();
		for (Pricebook_Line__c pbl : lines) {
			if (pbl.Use_Fixed_Pricing__c) continue;

			if (pbl.Price_2__c == null || pbl.Price_2__c == 0 || pbl.Price_3__c == null || pbl.Price_3__c == 0 
				|| pbl.Price_4__c == null || pbl.Price_4__c == 0 || pbl.Price_5__c == null || pbl.Price_5__c == 0 ) {
				relevantLines.add(pbl);	
			}			
		}

		if (relevantLines.isEmpty()) {
			System.debug('No bracket pricebook lines found for update');
			// no relevant change
			return;
		}
        
		Set<Id> pricebookIds = KSE.grepRelatedIdSetFromList(lines, 'Pricebook__c');
	
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Pricebook__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Company__c'
        });
        soql.setWhereClause('Id IN :pricebookIds');
        Map<Id, Pricebook__c> pricebooksById = new Map<Id, Pricebook__c>((list<Pricebook__c>)Database.query(soql.getQuery()));

		Set<Id> companyIds = new Set<Id>(KSE.grepRelatedIdSetFromList(pricebooksById.values(), 'Company__c'));
		Map<Id, BracketPricingService.BracketPrice[]> bracketsByCompanyId = BracketPricingService.loadBracketPrices(companyIds);
		if (bracketsByCompanyId.isEmpty()){
			// no brackets configured, so nothing to change as such in pricebook line
			return;
		}
		
		Integer intPrecision = getRoundingPrecision();

		for (Pricebook_Line__c pbl: relevantLines) {
			Id companyId = pricebooksById.get(pbl.Pricebook__c).Company__c; 
			for (BracketPricingService.BracketPrice bracket: bracketsByCompanyId.get(companyId)) {
				Decimal priceFieldVal = (Decimal)pbl.get(bracket.pricebookLineField); 
				// only non empty price fields should be updated 
				if (priceFieldVal != null && priceFieldVal > 0 ) continue;

				priceFieldVal = pbl.Price__c + pbl.Price__c * bracket.percentUpCharge / 100;
				priceFieldVal = roundPrice(priceFieldVal, intPrecision); //OTC-421 / OTC-481
				 
				System.debug ('Updating value of Pricebook Line field =' + bracket.pricebookLineField + ' oldVal=' + pbl.get(bracket.pricebookLineField) + ' newVal=' + priceFieldVal);
				pbl.put(bracket.pricebookLineField, priceFieldVal); 
			}
		}
	}	
	
	/* OTC-421 / OTC-481
	* this reads the Configuration custom setting called pricebooklinePrecision if it exists
	* and returns a precision of 0-6.  2 is the default.
	*/
	public static Integer getRoundingPrecision() {
		Integer intPrecision = 2; //default to 2
		Set<String> allowedValues = new Set<String>{'0','1','2','3','4','5','6'};
		Configuration__c c = Configuration__c.getValues('pricebooklinePrecision');
		if (c != null) {
			if (allowedValues.contains(c.Value__c)) {
				intPrecision = Integer.valueOf(c.Value__c);
			}
		}
		return intPrecision;				
	}
	
	
	public static void roundPrice(List<Pricebook_Line__c> pbLines){	
		Integer intPrecision = getRoundingPrecision();
	    for (Pricebook_Line__c pbl: pbLines) {
	    	if (pbl.Price__c != null) {
	    		pbl.Price__c = pbl.Price__c.setScale(intPrecision, System.RoundingMode.HALF_UP); //ENHANCE: future could pull the rounding mode from a custom setting.
	    	}
	    }
	}
	
	
	public static Decimal roundPrice(Decimal price, Integer intPrecision){	
    	Decimal retPrice = price;
    	if (retPrice != null) {
    		retPrice = retPrice.setScale(intPrecision, System.RoundingMode.HALF_UP); //ENHANCE: future could pull the rounding mode from a custom setting.
    	}
    	return retPrice;
	}	
	
	public static void expireLines(){

		if (Trigger.isBefore && Trigger.isUpdate) {
	        // KNDY-3687
	        List<Pricebook_Line__c> linesToExpire = new List<Pricebook_Line__c>();
	        // KNDY-3296 Clear other bracket price fields on change in Fixed Pricing 

        	Set<Id> pricebookSOLMatchingIds = SalesOrderLineService.findMatchingPBLSOL((List<Pricebook_Line__c>) Trigger.new);
        	
	        for (Pricebook_Line__c pbl : (List<Pricebook_Line__c>) Trigger.new) {

	            Pricebook_Line__c oldPbl = (Pricebook_Line__c) Trigger.oldMap.get(pbl.Id);
	            if ( (oldPbl.End_Date__c <= today) && (oldPbl.End_Date__c != null) )  {
	                // it was historic rule, so it couldn't be changed 
	                pbl.addError( String.format(PricebookService.CHANGE_IN_HISTORIC_RULE, new String[]{pbl.Name}) );
	            } else if (oldPbl.Start_Date__c <= today && oldPbl.End_Date__c > today) {
                    
                    // OTC-805: If no SOL linked, don't create new PBL
	                if (!pricebookSOLMatchingIds.contains(pbl.Id)){
	                	PricebookService.clearSubPriceFields(pbl);
	                	continue;
	                }

	                // means change is done in currently effective rule, so it couldnt be changed and has to be expired
	                for (String fldPath : PricebookService.FieldsLeading2ExpiryOfLine) {
	                    
	                    // OTC-484
	                    if (fldPath == 'End_Date__c' && PricebookService.FieldsLeading2ExpiryOfLine.size() == 1){
	                    	// OTC-530 Only End date changing
	                        continue; // In the event the field exists in the fieldset
	                    }

	                    if ( KSE.isFieldChanging(fldPath, pbl, Trigger.oldMap) ) {
	                        linesToExpire.add(pbl);
	                        break;
	                    }
	                } 
	            } else if (oldPbl.End_Date__c > today) { // Any changes are fine in future dates 
	                if (pbl.Use_Fixed_Pricing__c || KSE.isFieldChanging('Price__c', pbl, Trigger.oldMap)) {
	                    // clear sub price fields to get best one from Brackets 
	                    PricebookService.clearSubPriceFields(pbl);
	                }
	            }               

	        }
	
	        if (!linesToExpire.isEmpty()) {
	
	            for (Pricebook_Line__c pbl : linesToExpire) {
	                Pricebook_Line__c oldPbl = (Pricebook_Line__c) Trigger.oldMap.get(pbl.Id);
	                // clone the line
	                Pricebook_Line__c clonedPbl = pbl.clone();
	
	                if (KSE.isFieldChanging('End_Date__c', pbl, Trigger.oldMap) && KSE.isFieldChanging('Price__c', pbl, Trigger.oldMap)) {
	                    // Case where end date is changed, and we need to expire it differently
	                    
	                    // Add 1 day to the original pbl end date
	                    clonedPbl.Start_Date__c = pbl.End_Date__c.addDays(1);
	                    // Use Old end date for new line
	                    clonedPbl.End_Date__c = oldPbl.End_Date__c;
	                    
	                    Date pblEndDate = pbl.End_Date__c;
	                    
	                    // Restore old values from the original pricebook line
	                    for (String fldPath : PricebookService.FieldsLeading2ExpiryOfLine) {
	                        pbl.put(fldPath, oldPbl.get(fldPath));
	                    }
	                    // Use original end date
	                    pbl.End_Date__c = pblEndDate;
	                    
	                } else {
	                    clonedPbl.Start_Date__c = today.addDays(1);
	                    
	                    // Restore old values from the original pricebook line
	                    for (String fldPath : PricebookService.FieldsLeading2ExpiryOfLine) {
	                        pbl.put(fldPath, oldPbl.get(fldPath));
	                    }
	                    // Clear sub price fields again
	                    PricebookService.clearSubPriceFields(pbl);
	                    PricebookService.clearSubPriceFields(clonedPbl);
	                    // End original pricebook line on TODAY
	                    pbl.End_Date__c = today;
	                    
	                }
	                
	                // Store all cloned lines here, so that in after triggers we can insert them
	                // This is needed to make sure expired lines are saved correctly, so that new inserted lines don't fail validations for 
	                // invalid date overlaps
	                PriceBookService.ClonedLinesForExpiry.add(clonedPbl);
	            }
	        }
	    }
	}
	
	public static void populateBrackets(){

		if (Trigger.isBefore && ( Trigger.isUpdate || Trigger.isInsert )) {
	        PriceBookService.areLinesValid( trigger.new, trigger.isInsert ); 
	        // KNDY 2125: Bracket based price field discovery
	        PriceBookService.populatePricesUsingBrackets(Trigger.new);
	        
	        Relate.setLookupUsingField(Trigger.new, Trigger.isBefore, 
	                                   'Pricebook__c', 
	                                   'Pricebook__c', 
	                                   'Pricebook_Identifier__c',
	                                   'Primary_Key__c');
	        
	        Relate.setLookupUsingField(Trigger.new, Trigger.isBefore,  
	                                   'Product__c',
	                                   'Product__c',
	                                   'Product_Identifier__c', 
	                                   'Primary_Key__c');
	    }
	}
	
	public static void insertClonedLines(){

		if (Trigger.isAfter && Trigger.isUpdate) {
	        // Check if some cloned lines need to be inserted
	        if (!PriceBookService.ClonedLinesForExpiry.isEmpty()){ 
	            SObject[] clonedLines = PriceBookService.ClonedLinesForExpiry.clone();
	            // clear the lines before DML to avoid confusions later 
	            PriceBookService.ClonedLinesForExpiry.clear();
	            
	            DML.insertAsUser(clonedLines);     // TODO this is business logic , should be in the page controller, not trigger rh
	        }
	    }
	}

	//KNDY-7936: We should not allow a company in a pricebook to be changed
	public static void validateCompany(){

		if (Trigger.isBefore && Trigger.isUpdate) {

			for(PriceBook__c priceBook: (List<PriceBook__c>)Trigger.new) {
				String oldValue = (String)Trigger.oldMap.get(priceBook.Id).get('Company__c');

				if(oldValue != null){

					if(KSE.isFieldChanging('Company__c', priceBook, trigger.oldMap)){

						priceBook.addError(ERROR_COMPANY_CANNOT_BE_MODIFIED);
					}
				}
				
			}
		}
	}

	public static Map<String,Decimal> setListPrice(List<Product__c> pList,List<Customer__c> cList) {
    
	    set<id> productIds = new set<id>();
	    set<id> pricebookIds = new set<id>();
	    
	    for(Product__c p: pList){
	        productIds.add(p.id);
	    }
	    
	    for(Customer__c c: cList){
	       // if(c.Record_Type_Name__c  == 'Sold TO'){
	          pricebookIds.add(c.Pricebook__c);  
	        //}
	        
	    }
	    Date efd = system.today();
	   
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Pricebook_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Price__c','Pricebook__c','Product__c'
        });
        soql.setWhereClause('product__c in :productIds AND Pricebook__c in :pricebookIds AND Start_date__c <= :efd AND (End_date__c = null OR End_date__c >= :efd)');
        List<Pricebook_Line__c> pblList = Database.query(soql.getQuery());


		Map<String,Decimal> pbLineListPriceMap = new Map<String,Decimal>();
		
		for (Pricebook_Line__c pbl: pblList) {
            if(pbl.Product__c != null){
                pbLineListPriceMap.put(pbl.Product__c, pbl.Price__c);
            }		
		}
		
	    return pbLineListPriceMap;
	      /*  for(Product__c p: pList){
	            listPrice = null;
	           if (pbLineListPriceMap.containsKey(p.id)) {
	                    listPrice = pbLineListPriceMap.get(p.id);
	                }  
	        }*/
	}
}