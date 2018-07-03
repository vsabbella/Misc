public with sharing class KendoExt {

    public KendoExt(ApexPages.StandardSetController scon) {
    	// just to support integration with vf pages
    }

    public KendoExt(ApexPages.StandardController scon) {
    	// just to support integration with vf pages
    }
    
    public class LoadRecordsRelatedFilterInfo {
        public String relatedFilterLimiter {get;set;}
    	// K: Object Name LowerCase V: Value of that object in filter section
    	public Map<String, Object> relatedFilterValues {get;
    	    set {
    	        // Convert keys to lowercase to avoid any confusions in fetching
    	        relatedFilterValues = new Map<String, Object>();
    	        if (value != null) {
    	            for (String key : value.keySet()) {
    	                relatedFilterValues.put(key.toLowerCase(), value.get(key));        
    	            }
    	        }
    	    }
    	}
    }
    
    
    /**
     * Limits the fetched records by #loadRecords(..) based on information from related filters on the screen.
     */ 
    public interface I_RelatedFilterLimiter {
        void setLoadRecordsRelatedFilterInfo(LoadRecordsRelatedFilterInfo filterInfo);
        Boolean hasRelevantIds();
        Set<Id> getRelevantIds();
    }
    
    
    public class LoadRecordsContext {
    	public String sobjectName {get;set;} 
    	public String valueFieldName {get;set;} 
    	public String textFieldName {get;set;} 
    	public List<Map<String, String>> criterias {get;set;} 
    	public String orderByField {get;set;} 
    	public String sortOrder {get;set;} 
    	public Integer recordLimit {get;set;}
    	public LoadRecordsRelatedFilterInfo filterInfo {get;set;}
        public String additionalFields {get; set;}
    }  
      
    @RemoteAction    
    public static Object[] loadRecords(LoadRecordsContext sobjInfo) {
    	String soqlWhereClause = sobjInfo.textFieldName + ' != null '; // Text field should be something visible and not null

    	for (Map<String, String> crit : sobjInfo.criterias) {
    		Boolean wrapValueInQuotes = crit.get('wrapValueInQuotes') != null ? Boolean.valueOf(crit.get('wrapValueInQuotes')) : false;    		
    		String rhs = String.escapeSingleQuotes(crit.get('value'));
    		if (wrapValueInQuotes) rhs = '\'' + rhs + '\'';

    		soqlWhereClause += String.format(' {0} {1} {2} {3} ', 
    								new String[] {
    								    ' AND ', // 0
    									String.escapeSingleQuotes(crit.get('field')), // 1
    									String.escapeSingleQuotes(crit.get('operator')), // 2
    									rhs // 3
    								} 
    							);
    	}
        
        Set<Id> relatedIds;
        
        if (sobjInfo.filterInfo != null && !String.isBlank(sobjInfo.filterInfo.relatedFilterLimiter)) {
            System.Type relatedFilterLimiterType = Type.forName(sobjInfo.filterInfo.relatedFilterLimiter);
            I_RelatedFilterLimiter limiter = (I_RelatedFilterLimiter) relatedFilterLimiterType.newInstance();
            limiter.setLoadRecordsRelatedFilterInfo(sobjInfo.filterInfo);
            if (limiter.hasRelevantIds()) {
                relatedIds = limiter.getRelevantIds();    
                if (relatedIds == null || relatedIds.isEmpty()) {
                    return new object[]{};
                } else {
                    soqlWhereClause += ' AND Id IN :relatedIds ';                        
                }
            }
        }
        
    	String soqlOrderByClause = '';
    	if (!String.isBlank(sobjInfo.orderByField)) {
    		soqlOrderByClause = ' ORDER BY ' + String.escapeSingleQuotes(sobjInfo.orderByField);
    		if (!String.isBlank(sobjInfo.sortOrder)) {
    			soqlOrderByClause += ' ' + String.escapeSingleQuotes(sobjInfo.sortOrder);
    		}
    	}

    	String soqlLimitClause = '';
    	if (sobjInfo.recordLimit != null && sobjInfo.recordLimit > 0) {
    		soqlLimitClause += ' LIMIT ' + sobjInfo.recordLimit;
    	}

        String additionalFields = String.isBlank(sobjInfo.additionalFields) ? ''  : ', ' + sobjInfo.additionalFields; 
    	/*String soql = String.format('SELECT {0},{1}{6} FROM {2} WHERE {3} {4} {5}', 
    									new String[]{
    										sobjInfo.valueFieldName, // 0
    										sobjInfo.textFieldName,  // 1
    										sobjInfo.sobjectName,  // 2
    										soqlWhereClause,  // 3
    										soqlOrderByClause,	// 4	
    										soqlLimitClause, //5
                                            additionalFields  // 6
    									} 
    								);*/
    	
    	Set<String> fieldSet = new Set<String>();
    	
    	if(sobjInfo != null && sobjInfo.additionalFields != null){
    		fieldSet.addAll(sobjInfo.additionalFields.split(','));
    	}
    	
    	String whereClause = '' + soqlWhereClause + soqlOrderByClause + soqlLimitClause;
        
	    SOQLUtil soql = new SOQLUtil(sobjInfo.sobjectName);
	    soql.addFields(new Set<String>{sobjInfo.valueFieldName, sobjInfo.textFieldName});
	    soql.addFields(fieldSet);
	    soql.setWhereClause(whereClause);
	    
        return Database.query(soql.getQuery());
	}
	
	public String getNamespacePrefix(){
    	return KSE.NamespaceUU;
    }
    
    public String getNamespace(){
    	return KSE.Namespace;
    }
}