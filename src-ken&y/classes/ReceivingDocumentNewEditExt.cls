public with sharing class ReceivingDocumentNewEditExt {
    
    public Receiving_Document__c rd {get;set;}
    public Boolean disabled{get;set;}{ disabled = false; }
    private ApexPages.Standardcontroller con;
    public string sectionHeaderText {get;set;} { sectionHeaderText = 'New Receiving Document'; }

    private SchemaUtil util = SchemaUtil.getInstance();
    public List<Schema.FieldSetMember> RDEditFields { get; set; } {
        RDEditFields = new List<Schema.FieldSetMember>(); 
    }
   
    public List<String> readOnlyRDFields{get;set;}

    
    public ReceivingDocumentNewEditExt (ApexPages.StandardController controller) { 
        con = controller; 
   
        ID rdID;
        Map<String, Schema.FieldSet> FieldsetMap =Schema.SObjectType.Receiving_Document__c.fieldSets.getMap();
        
        rd = (Receiving_Document__c) controller.getRecord();       // use the record that the controller has for us
        if( rd.Company__c == null ){
            rd.Company__c = CompanyService.getDefaultCompanyId(); 
        }
        
        if( rd.Id != null ){
         
            rdID = rd.Id;
            List<String> newfieldsetlist = util.getFieldsFromFieldSetString(Receiving_Document__c.sObjectType , 'New_Receiving_Document');
            set<String> fieldStrings = new set<string>{'Id','Name', 'Status__c'};
            fieldStrings.addAll(newfieldsetlist);
            String whereClause = 'Id =:rdID LIMIT 1';

		    SOQLUtil soql = new SOQLUtil('Receiving_Document__c', true, true);
		    soql.addFields(fieldStrings);
		    soql.setWhereClause(whereClause);
		    Receiving_Document__c tempRD = Database.query(soql.getQuery());
		    rd = tempRD;
        
            sectionHeaderText = 'Receiving Document - '+rd.Name;
  
            if(rd.Type__c == 'Miscellaneous Receipt' && (rd.Status__c == 'Draft' || rd.Status__c == 'Open')){
    	          RDEditFields =  FieldsetMap.get( KSE.NamespaceUU + 'New_Receiving_Document').getFields();
    	    }
    	    else
    	    {
    	           RDEditFields =  FieldsetMap.get( KSE.NamespaceUU + 'RD_Editable').getFields();

                   List<String> editfieldsetlist = util.getFieldsFromFieldSetString(Receiving_Document__c.sObjectType , 'RD_Editable');
                   Set <String> editfieldset = new Set<String>();
                   for(String str: editfieldsetlist ){
                       editfieldset.add(str);
                   }

 
                Set<String> readOnlyRDFieldsSet = new Set<String>();
                   for(String str: newfieldsetlist){
                        if (!editfieldset.contains(str)) {
                            readOnlyRDFieldsSet.add(str);
                        }
                   
                   }

                   readOnlyRDFields = new List<String>(readOnlyRDFieldsSet);
    	        
    	    }
  
        }
  
             else
        {   
               RDEditFields =  FieldsetMap.get( KSE.NamespaceUU + 'New_Receiving_Document').getFields();
            

        }
        
		if( rd.Id == null && rd.Company__c != null ){
		    
    		Id companyId = rd.Company__c;
    		
    		SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
    		soql.addFields(new set<string>{
    			'Id','Default_Transaction_Currency__c'
    		});
    		soql.setWhereClause('Id = :companyId');
    
    		List<Company__c> companyInfo = Database.query(soql.getQuery());
    
            if (companyInfo.size() > 0){
            	rd.Currency__c = companyInfo[0].Default_Transaction_Currency__c; //OTC-740
            }
		}
    }
    
    public pageReference save(){
        
        if( rd.Id == null && rd.Type__c != 'Miscellaneous Receipt'){ 
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Editing_is_allowed_only_for_Receiving_Documents_of_type_Miscellaneous));
	        return null;
	    }
        upsert rd;
        pagereference pageRef = new pagereference('/' + rd.id);
        pageRef.setRedirect(true);
        return pageRef;
      
    }
    
}