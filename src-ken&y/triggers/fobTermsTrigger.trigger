trigger fobTermsTrigger on FOB_Terms__c (before Update) {
	
		if ( DML.checkTriggerDispatch( FOB_Terms__c.getSobjectType() ) ) {
			return;
		}
		Set<Id> fobTermIds = new Set<Id>();
		if (trigger.isBefore && trigger.isUpdate){
			for(FOB_Terms__c fobObj : Trigger.new){
	           if (KSE.isFieldChanging('FOB_Point__c', fobObj, Trigger.oldMap)) {
					fobTermIds.add(fobObj.Id);
				}
			}
		}
		//List<Purchase_Order_Line__c> poLines = new List<Purchase_Order_Line__c>();
		
		if(fobTermIds.size()>0){
			Map<Id,List<Purchase_Order_Line__c>> powithFOBMap = new Map<Id,List<Purchase_Order_Line__c>>();
			powithFOBMap = PurchaseOrderService.queryPOLinesWithASN(fobTermIds,'FOB_Terms__c');
			for(FOB_Terms__c fobObj : Trigger.new){
	           if (powithFOBMap.containskey(fobObj.Id) && powithFOBMap.get(fobObj.Id).size()>0) {
					fobObj.addError('You cannot change the FOB Point associated with the asn or purchase order with quantity received greater than 0');
				}
			}
		}
		
}