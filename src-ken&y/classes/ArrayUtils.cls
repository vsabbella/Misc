/**
 * @description generic array utitity methods, mostly static methods that 
 * accept or return lists, sets or arrays.
 */
public with sharing class ArrayUtils {
 
    /**
     * @description generate a list of integers, given a comma seperated list of strings that 
     * look like numbers.  provide them in decending order so that these can be used 
     * to remove items from a list of sobjects.
     */
    static public list<integer> getIntegerList(string csv) {
        List<integer> ret = new List<Integer>();
        if ( csv == null ) return ret; 
        for ( string s : csv.split(',') ) { 
            try { ret.add( integer.valueof( s.trim() ) );   } 
            catch( System.Typeexception te) {   
				// we are going to ignore invalid strings passed in, just catch type exceptions
			}
        } 
        ret.sort(); 
        return (List<Integer>)ArrayUtils.reverse( ret ); 
    }   
    
    public static Object[] reverse(Object[] anArray) {
        if (anArray == null) {
            return null;
        }
        Integer i = 0;
        Integer j = anArray.size() - 1;
        Object tmp;
        while (j > i) {
            tmp = anArray[j];
            anArray[j] = anArray[i];
            anArray[i] = tmp;
            j--;
            i++;
        }
        return anArray;
    }


    /** 
     * @description sort a list of sobjects, given a field to sort on.  The list is sorted inplace, no return value
     */
    public static void sortList(List<Sobject> items, String sortField, String order){
       List<Sobject> resultList = new List<Sobject>();   
        //Create a map that can be used for sorting 
       Map<object, List<Sobject>> objectMap = new Map<object, List<Sobject>>();
       for(Sobject ob : items){
                object val;
                // allow sorting by fields on a compound sort field (field of a related list)
                if ( sortField.indexOf('.')>0) {
                    string[] aa = sortField.split('\\.');
                    sobject f1 = (sobject)ob.getSObject( aa[0] ); 
                    val = f1.get( aa[1] );
                } else { 
                    // normal sort field
                    val = ob.get(sortField);
                }
                
                if(objectMap.get( val ) == null){  
                    objectMap.put( val , new List<Sobject>()); 
                }
                objectMap.get( val ).add(ob);
        }       
        //Sort the keys
        List<object> keys = new List<object>(objectMap.keySet());
        keys.sort();
       
        for(object key : keys){ 
            resultList.addAll(objectMap.get(key)); 
        }
        
        //Apply the sorted values to the source list
        items.clear();
        if(order.toLowerCase() == 'asc'){
            for(Sobject ob : resultList){
                items.add(ob); 
            }
        } else if(order.toLowerCase() == 'desc') {
            for(integer i = resultList.size()-1; i >= 0; i--){
                items.add(resultList[i]);  
            }
        }
    }
    
    /**
    	Returns given List as CSV
    */
    public static String toCSV(List<Object> vals) {
    	return split(vals, ',');
    } 
    
    /**
    	Splits the given list by delimeter
    */
    public static String split(List<Object> vals, String delimeter) {
    	String splt = '';
    	if (vals != null) {
	    	for (Object val : vals) {
	    		splt += (splt.length() == 0) ? val : delimeter + val;
	    	}
    	}
    	return splt;
    }

}