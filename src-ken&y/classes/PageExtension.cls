/** 
 * @description superclass that is used to build page extensions that have constructor, save and remove lines methods 
 * already implemented and tested
 */
public with sharing abstract class PageExtension {
	public SObject sobj {get; set;} 
    public list<SObject> objectList { 
    	get{
    		if(objectList==null){
    			objectList = new List<SObject>();
    		}
    		return objectList;
    	}
    	set;
    }
    public  apexpages.StandardController con;

	public PageExtension() { }
	public PageExtension(ApexPages.StandardController r){
		try{
			this.con = r;
			if ( ! Test.isRunningTest() ) {
				this.con.addFields( new List<String>{ 'Company__c'} );
			}
			this.sobj = con.getRecord();
			// do something standard in your class that extends this
		}
		catch(Exception e){
			ApexPages.addMessages ( e );
		}	
	}

	public pageReference save() {
        try{
            DML.checkUpsertAsUser(objectList); upsert objectList;
        } catch( Exception e) { 			// could be caused by validations
            Apexpages.addMessages(e);
        }
        return ( ApexPages.hasMessages() ? null : new PageReference('/'+this.con.getId()) );
    }

    public List<Integer> selected_indexes { 
    	get {
	    	String selected_indexes = Apexpages.currentPage().getParameters().get('selected_indexes');
		    	return ArrayUtils.getIntegerList( selected_indexes ); 
     	}
    }
	
	public pageReference remove() {     
        try{
        	List<SObject> recordsToDelete = new List<SObject>();
        	for ( Integer i : selected_indexes ) {
	            Sobject ob = this.objectList.remove(i);
	            if ( ob.id !=null  ) 
	            		recordsToDelete.add( ob );	
	        }
	        DML.deleteAsUser( recordsToDelete ); 
        }catch(Exception e){
        		ApexPages.addMessages(e);
        		ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Error, 'Cannot delete records with related transactions.'));
        }
        return null;
    }

}