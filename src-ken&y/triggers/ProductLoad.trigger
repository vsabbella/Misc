trigger ProductLoad on Product__c (before insert, before update, before delete) {
	
	if(DML.checkTriggerDispatch(Product__c.getSobjectType())){return;}
	
	if ( trigger.isBefore && ( trigger.isInsert || trigger.isUpdate ) ) {
		/*
		 * when loading products with no item or no company, try to match the product up 
		 * with existing items and companies using name or company_identifier
		 */
		Relate.setLookupUsingField(Trigger.New,Trigger.isBefore,
													'Item__c' ,	
													'Item__c', 
													'Item_Identifier__c',
													'Name'		);
													
	 	Relate.setLookupUsingField(Trigger.New,Trigger.isBefore,
						                            'Company__c', 
						                            'Company__c', 
						                            'Company_Identifier__c', 
						                            'Company_Identifier__c');
	
		Relate.setLookupUsingField(Trigger.New,Trigger.isBefore, 
													'Product_Group__c',
													'Product_Group__c',
													'Product_Group_Code__c',
													'Primary_Key__c'	);
		
		Relate.setLookupUsingField(Trigger.New,Trigger.isBefore, 
													'Hierarchy__c',
													'Sales_Hierarchy__c',
													'Sales_Hierarchy_Code__c',
													'Code__c' );
													
        Product__c[] prodsMissingDimensions = new Product__c[]{};
        if (Trigger.isInsert) {
            for (Product__c prd : Trigger.new) {
            	// populate missing product info from item
                if ( ( prd.Length__c == null || prd.Length__c == 0 ) ||
                     ( prd.Width__c == null || prd.Width__c == 0 ) ||
                     ( prd.Height__c == null || prd.Height__c == 0 ) ||
                     ( prd.Dimension_UOM__c == null ) 
                   ) {
                    prodsMissingDimensions.add(prd);       
                }

                //If Item and Item Identifier is empty raise an error
                if(prd.Item__c == null && prd.Item_Identifier__c == null){
                	prd.addError('Please enter a valid Item or Item Identifier');
                }

                //If Company and Company Identifier is empty raise an error
                /*if(prd.Company__c == null && prd.Company_Identifier__c == null){
                	prd.addError('Please enter a valid Company or Company Identifier');
                }*/

            }
        } else if (Trigger.isUpdate) {
            for (Product__c prd : Trigger.new) {
                if ( ( KSE.isFieldChanging('Length__c', prd, Trigger.oldMap) && prd.Length__c == null || prd.Length__c == 0 ) ||
                     ( KSE.isFieldChanging('Width__c', prd, Trigger.oldMap) && prd.Width__c == null || prd.Width__c == 0 ) ||
                     ( KSE.isFieldChanging('Height__c', prd, Trigger.oldMap) && prd.Height__c == null || prd.Height__c == 0 ) ||
                     ( KSE.isFieldChanging('Dimension_UOM__c', prd, Trigger.oldMap) && prd.Dimension_UOM__c == null ) 
                   ) {
                    prodsMissingDimensions.add(prd);       
                }
            }
        }     
        
        if (!prodsMissingDimensions.isEmpty()) {
            ProductService.populateMissingDimensionInfoInProductsFromItems(Trigger.new);
        }

		//Scale.govern(trigger.new);
	}
	
	if(trigger.isBefore && trigger.isDelete){
		KSE.blockRecordDeletion();
	}
}