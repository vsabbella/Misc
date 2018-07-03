public with sharing class FacilityAssignmentNewExt {

     private ApexPages.StandardController controller;
     public Facility_Assignment__c fa;

    public FacilityAssignmentNewExt(ApexPages.StandardController c) {
    
        controller = c;
        fa = (Facility_Assignment__c)controller.getRecord();
        fa.Company__c =  CompanyService.getDefaultCompanyId(); 

    }

}