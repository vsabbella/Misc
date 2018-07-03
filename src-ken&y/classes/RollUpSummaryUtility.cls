//need without sharing so we can roll child fields up to parents the user may not have access to
public without sharing class RollUpSummaryUtility {

    //  used to house the field names and desired operations
    public class fieldDefinition {
        public String operation {get;set;}
        public String childField {get;set;}
        public String parentField {get;set;}
         
        public fieldDefinition (String o, String c, String p) {
            operation = o;
            childField = c;
            parentField = p;
        }
    }
    
    public static List<SObject> rollUpTrigger(		list<fieldDefinition> fieldDefinitions,
													    list<sObject> records, 
													    String childObject, 
													    String childParentLookupField, 
													    String parentObject, 
													    String queryFilter,
													    boolean doUpdate) {
		//Limit the size of list by using Sets which do not contain duplicate
        //elements prevents hitting governor limits
        Set<Id> parentIds = new set<Id>();


        //list of parent object records to update
        List<sObject> parentsToUpdate = new list<sObject>();

        for(sObject s : records) {
            if ( s.get(childParentLookupField)!= null ){
                parentIds.add( (Id) s.get(childParentLookupField));
            }
        }
        
        if (parentIds.isEmpty()){
            return parentsToUpdate;
        } 

        //populate query text strings to be used in child aggregrator and 
        //parent value assignment
        Set<String> fieldsToAggregate = new Set<String>{childParentLookupField};
        Set<String> parentFields = new Set<String>{'Id'};
         
        for(fieldDefinition d : fieldDefinitions) {
            fieldsToAggregate.add( d.operation + '(' + d.childField + ')' );
            parentFields.add( d.parentField );
        }
         
        //Using dynamic SOQL with aggergate results to populate parentValueMap
        /*String aggregateQuery = 'Select ' + fieldsToAggregate + 
        childParentLookupField + ' from ' + childObject + ' where  ' + 
        childParentLookupField + ' IN :parentIds ' + queryFilter + ' ' +
        ' group by ' + childParentLookupField;*/
        
        String aggregateWhereClause = childParentLookupField + ' IN :parentIds ' + queryFilter + ' group by ' + childParentLookupField ;
        
	    SOQLUtil soql = new SOQLUtil(childObject, true, true);
	    soql.addFields(fieldsToAggregate);
	    soql.setWhereClause(aggregateWhereClause);
	     
        //Map will contain one parent record Id per one aggregate object
        map<Id, AggregateResult> parentValueMap = new map <Id, AggregateResult>();
         
        for(AggregateResult q : Database.query(soql.getQuery())) {
   	
            parentValueMap.put((Id)q.get( KSE.NamespaceUU + childParentLookupField), q);
        }
        
        String parentWhereClause =  'Id IN :parentIds';
        
        soql = new SOQLUtil(parentObject);
        soql.addFields(parentFields);
        soql.setWhereClause(parentWhereClause);
        
        /*String parentQuery = 'select ' + parentFields + ' Id ' +
         ' from ' + parentObject + ' where Id IN :parentIds';*/
         
        //for each affected parent object, retrieve aggregate results and 
        //for each field definition add aggregate value to parent field
        for(sObject s : Database.query(soql.getQuery())) {
             
            Integer row = 0; //row counter reset for every parent record
            for(fieldDefinition d : fieldDefinitions) {
                String field = 'expr' + row.format();
                AggregateResult r = parentValueMap.get(s.Id);

                //r will be null if no records exist 
                //(e.g. last record deleted)
                if((r != null) ) {
                    // In order Calculate MAX of UOM, The Code below is Put into Try and Catch Block.
                    try{ 
                        Decimal value = ((Decimal)r.get(field) == null ) ? 0 : (Decimal)r.get(field);
                        s.put(d.parentField, value);
                    }
                    catch(Exception e){ // Throws an Exception if Value is not Decimal(Number)
                        s.put(d.parentField, r.get(field));
                    }
                } else {
                    try { 
                    	 s.put(d.parentField, 0);
                    } catch(Exception e){ 
                    	s.put(d.parentField, null);  // was 0, but sometimes we get an ID 
                    } 
                }
                row += 1; //plus 1 for every field definition after first
            }
            parentsToUpdate.add(s);
        }
         
        //if parent records exist, perform update of all parent records 
        //with a single DML statement
        
        if(doUpdate == true && parentsToUpdate.Size() > 0 ) {
        	try{
        		
        		DML.updateAsSystem(parentsToUpdate);
        	} catch(Exception e){ 
            	system.debug('Exception : ' + e);
            } 
        }
        
        return parentsToUpdate;											    
	}
	 
    public static void rollUpTrigger(		list<fieldDefinition> fieldDefinitions,
													    list<sObject> records, 
													    String childObject, 
													    String childParentLookupField, 
													    String parentObject, 
													    String queryFilter) {
         
        
         rollUpTrigger(	fieldDefinitions,records,childObject,childParentLookupField,parentObject,queryFilter, true); 
    }
 
 
 
}