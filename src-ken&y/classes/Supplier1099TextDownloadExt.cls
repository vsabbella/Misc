public with sharing class Supplier1099TextDownloadExt
{ 
	public Supplier1099TextDownloadExt(ApexPages.StandardController controller) {
		fetch();
	}
	
	public list <Supplier__c> sup;
	public transient list <string> rows {get;private set;}
	
	public void fetch(){
	    String TIN_Type;
	    String nameFormatted;
	    String newTaxID;
	    String newSupplierID;
	
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Supplier__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Tax_ID__c','Supplier_ID__c','Name','Alternate_Name__c','RecordType.Name','RecordType.DeveloperName','RecordTypeId'
		});
		soql.setWhereClause('X1099_Supplier__C = TRUE');
	
		sup = Database.query(soql.getQuery());
	
	    rows = new list <string> ();
        
        for (Supplier__c s:sup){
            // getting TIN type
            if(s.Tax_ID__c !=NULL){
				//KNDY-18898 Bulk TIN Matching file needs fix to always set first value equal to 3
				/*
                if (s.Tax_Id__c.length() == 11){
                    TIN_Type = '2';    // 2 means SSN number
                }
                else if (s.Tax_Id__c.length() == 10){
                    TIN_Type = '1';    // 1 means EIN number
                }
                else {*/
                    TIN_Type = '3'; // means unknown
                //}
            }    
            
            //pxp if Alternate Name exists, use the Alternate name
            if(s.Alternate_Name__c != NULL)
                nameFormatted = s.Alternate_Name__c;    
            else nameFormatted = s.Name;
            
            //formatting Name - 40 char govt limit
            // nameFormatted = s.Name.replace(' ',''); // pxp replaced
            nameFormatted = nameFormatted.replace(' ','');
            nameFormatted = nameFormatted.replace('.','');
            nameFormatted = nameFormatted.replace(',','');
            nameFormatted = nameFormatted.replace('@','');
            nameFormatted = nameFormatted.replace(';','');
            nameFormatted = nameFormatted.replace('/','');
            nameFormatted = nameFormatted.replace('-','');
            
            if (nameFormatted.length() > 40){
                nameFormatted = nameFormatted.SubString(0,40);
            }          
            
            //formatting TaxID
            if (s.Tax_Id__c != NULL){
                newTaxID = s.Tax_Id__c.replace('-','') ;
            }
            else 
            	newTaxID = '';
        
            // building text rows
            string irow = TIN_Type + ';' +  newTaxID + ';' + NameFormatted + ';' ;
            
            if (s.Supplier_ID__c != null)         // don't print NULL
                irow += s.Supplier_ID__c  ;
            
            irow += '\r';   
            
            rows.add(irow);
            
        } //end for
    }
}