/** 
 * @description simple new record extension that defaults the company 
 */ 
public with sharing class CompanyDefaultExt {
    
    public Sobject newObj;
    public boolean pageSubmitted {get;set;}
    
    // apply a company default to this record
    public CompanyDefaultExt(ApexPages.StandardController controller) { 
        ID companyID;
        newObj = controller.getRecord();        
        // use the existing record that the controller has created for us
        companyID = CompanyService.getDefaultCompanyId();
        system.debug('inside COmapny default: newObj: '+newObj.get('Id') );
        newObj.put('Company__c', companyID);
        if(string.valueof(newObj.getSObjectType()) == KSE.NamespaceUU + 'Supplier_Payment__c'){
            id bankAccount = companyservice.getBankAccount(companyID);
            newObj.put('Bank_Account__c', bankAccount);
        }
        else if(string.valueof(newObj.getSObjectType()) == KSE.NamespaceUU + 'Work_Order__c'){
            fillLocations();
        }
        
        else if((string.valueof(newObj.getSObjectType()) == KSE.NamespaceUU + 'Customer_Receipt__c') && newObj.get('Id') == null){
            newObj.put('Currency__c',CompanyService.defaultTransactionCurrency(companyID));
        }
        
    }
    
    public void fillLocations() {
        
        //Id companyID = CompanyService.getDefaultCompanyId();
        Id facilityId;
        
        if((Id)ApexPages.currentPage().getParameters().get('selectedID') !=null)
            facilityId = (Id)ApexPages.currentPage().getParameters().get('selectedID');
        else if((Id) newObj.get('Facility__c') != null)
            facilityId = (Id) newObj.get('Facility__c');
           
        if(string.valueof(newObj.getSObjectType()) == KSE.NamespaceUU + 'Work_Order__c'){
            if(facilityId != null) {

				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','Default_Work_Order_MRB_Location__c','Default_Work_Order_Complete_to_Location__c','Default_Work_Order_WIP_Location__c'
				});
				soql.setWhereClause('Id = :facilityId');
				soql.setLimit(1);
				Facility__c facility = Database.query(soql.getQuery());

                newObj.put('Complete_to_Location__c', facility.Default_Work_Order_Complete_to_Location__c);
                newObj.put('MRB_Location__c', facility.Default_Work_Order_MRB_Location__c);     
                newObj.put('Default_WIP_Location__c', facility.Default_Work_Order_WIP_Location__c);
            }
        }
        
        if(newObj.get('Complete_to_Location__c') == null){
            id locID = facilityService.getCompleteLoc(facilityId);
            newObj.put('Complete_to_Location__c', locID);
        }
        if(newObj.get('MRB_Location__c') == null){
            id locID = facilityService.getScrapLoc(facilityId);
            newObj.put('MRB_Location__c', locID);
        }
        if(newObj.get('Default_WIP_Location__c') == null) {
            id locId = facilityService.getWIPLoc(facilityId);
            newObj.put('Default_WIP_Location__c',locId);
        }
        
    }
    
    public PageReference save(){
        boolean error = false;
        pageSubmitted = true;
        
        DML.insertAsUser(newObj);
        return new PageReference('/'+newObj.Id);
    }
}