trigger Company on Company__c (before insert, before update, before delete) {
    if (DML.checkTriggerDispatch(Company__c.getSObjectType())) return;

    if (Trigger.isBefore) {
        Map<Id, Company__c> companies = new Map<Id, Company__c>();
        for (Company__c company:Trigger.isDelete ? Trigger.old : Trigger.new) {
            if (Trigger.isInsert || Trigger.isUpdate) {
                if (CompanyService.checkValidName(company.Name) == false) company.Name.addError(Label.Only_alphanumeric_characters_allowed);

                if (Trigger.isInsert) {
                    company.Auto_Plan_Pick__c = true;
                } else if (company.Auto_Plan_Pick__c != Trigger.oldMap.get(company.Id).Auto_Plan_Pick__c) {
                    if (CompanyService.allowAutoPlanPickUpdate == false) company.Auto_Plan_Pick__c.addError(company.Name + ': Unable to change Auto Plan-Pick');
                    else companies.put(company.Id, company);
                }
            } else {
                company.addError(Label.Cannot_delete_Company);
            }
        }

        if (companies.size() > 0) {
            Set<Id> companyIds = companies.keySet();
            SOQLUtil skidQuery = new SOQLUtil('SKID__c');
            skidQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c' });
            skidQuery.setWhereClause('Type__c IN (\'' + SkidService3.SKID_TYPE_ALLOCATED + '\',\'' + SkidService3.SKID_TYPE_PLANNED + '\') AND Company__c IN :companyIds');
            for (SKID__c skid:Database.query(skidQuery.getQuery())) {
                if (companies.size() == 0) break;
                if (companies.containsKey(skid.Company__c)) {
                    Company__c company = companies.get(skid.Company__c);
                    company.Auto_Plan_Pick__c.addError(company.Name + ': Unable to change Auto Plan-Pick when there are existing allocated or planned pick skids');
                    companies.remove(company.Id);
                }
            }
        }
    }
}