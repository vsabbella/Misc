// User-defined class for KendoUI utility functions
global with sharing class KendoUtils {
    
    global static final String DATE_FORMAT = 'M/d/yyyy';
    global static final String DATETIME_FORMAT = 'M/d/yyyy h:mm tt';
    
    public class FilterDescriptor {
    	public String field {get;set;} 
    	public String fieldType {get;set;}
    	public Object value {get;set;} 
    	public String operator {get;set;}
    }
    
    /*
    	Utility to handle the null date/datetime fields coming from a remoting call
 
    */
    global static void UpdateDateFields(SObject obj, List<String> dateFields) {
    	if (dateFields != null) {
    		for(String fieldName : dateFields){
        		try {
        		    
        		    String[] RefStringArray = fieldName.split('\\.');
		            String lastField = RefStringArray.get(RefStringArray.size()-1);
        		    
	        		if (obj.get(lastField) == Datetime.newInstance(0)) {
		        		obj.put(lastField, null);
	        		}
	        	}
				catch(Exception e) {
					// Ignore if it doesn't find the matching field
				}
	    	}
    	}
    }
    
    /*
    	JSON serializer to exclude the namespace prefix
    */
    // This method is obsolete and no longer being used
    /*
    public static string Serialize(Object obj) {
    	string namespace = KSE.NamespaceUU;
    	String jsonString = JSON.serialize(obj);
    	
		jsonString = jsonString.replaceAll('"' + namespace + '([a-zA-Z0-9_-]+":)', '"$1');

    	return jsonString;
    }*/
    
    /**
	 *  @description Returns the filter criteria for a given list of filters  
	 *     	Note: Use the following syntax when comparing dates using dynamic SOQL
	 *	   	date: dt.format('yyyy-MM-dd')
	 *		datetime: dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
	 *
	 */
    public static List<String> getFilterCriteria(List<FilterDescriptor> filters) {
    	List<String> filterCriteria = new List<String>();
        	        	
		for (FilterDescriptor filter : filters) {
			String operatorType = filter.operator.toLowerCase();
	        String field = filter.field;
	        Object value = filter.value;
	        String fieldType = String.isNotBlank(filter.fieldType) ? filter.fieldType.toLowerCase() : '';
	       	String dateFormat = (fieldType == 'datetime') ? 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' : 'yyyy-MM-dd';
			
			if (operatorType == 'eq') {
				if (fieldType == 'id' || fieldType == 'string') {
                	filterCriteria.add(field + ' = \'' + String.escapeSingleQuotes(String.valueOf(value)) + '\'');
				}
				else {
					filterCriteria.add(field + ' = ' + value);
				}
			}
	        else if (operatorType == 'neq') {
	        	if (fieldType == 'id' || fieldType == 'string') {
                	filterCriteria.add(field + ' != \'' + String.escapeSingleQuotes(String.valueOf(value)) + '\'');
				}
				else {
					filterCriteria.add(field + ' != ' + value);
				}
	        }
	        else if (operatorType == 'gt') {
	        	filterCriteria.add(field + ' > ' + value);
	        }
	        else if (operatorType == 'gte') {
	        	if (fieldType == 'date' || fieldType == 'datetime') {
	        		String dateValue = String.valueOf(value);
	        	
		        	if (fieldType == 'date') {
		        		dateValue += ' 12:00 AM';
		        	}
		        	
		        	DateTime dtValue = DateTime.parse(dateValue);
		        	
		        	filterCriteria.add(field + ' >= ' + dtValue.format(dateFormat, 'GMT'));
	        	}
	        	else {
	        		filterCriteria.add(field + ' >= ' + value);
	        	}
	        }
	        else if (operatorType == 'lt') {
	        	filterCriteria.add(field + ' < ' + value);
	        }
	        else if (operatorType == 'lte') {
	        	if (fieldType == 'date' || fieldType == 'datetime') {
	        		String dateValue = String.valueOf(value);
	        	
		        	if (fieldType == 'date') {
		        		dateValue += ' 12:00 AM';
		        	}
		        	
		        	DateTime dtValue = DateTime.parse(dateValue);
		        	
		        	filterCriteria.add(field + ' <= ' + dtValue.format(dateFormat, 'GMT'));
	        	}
	        	else {
	        		filterCriteria.add(field + ' <= ' + value);
	        	}
	        }
	        else if (operatorType == 'contains') {
	        	if (fieldType == 'string') {
	        		filterCriteria.add(field + ' LIKE \'%' + String.escapeSingleQuotes(String.valueOf(value)) + '%\'');
	        	}
	        	else {
	        		List<Object> arryaList = (List<Object>)JSON.deserializeUntyped(String.valueOf(value));
	        		String inClause = '(\'';

					for (Object item : arryaList){
					    inClause += item + '\',\'';
					}
					
					inClause = inClause.substring(0, inClause.length()-2);
					inClause += ')';
					
	        		filterCriteria.add(field + ' IN ' + inClause);
	        	}
	        }
	        else if (operatorType == 'doesnotcontain') {
	        	if (fieldType == 'string') {
	        		filterCriteria.add('(NOT (' + field + ' LIKE \'%' + String.escapeSingleQuotes(String.valueOf(value)) + '%\'))');
	        	}
	        	else {
	        		List<Object> arryaList = (List<Object>)JSON.deserializeUntyped(String.valueOf(value));
	        		String inClause = '(\'';

					for (Object item : arryaList){
					    inClause += item + '\',\'';
					}
					
					inClause = inClause.substring(0, inClause.length()-2);
					inClause += ')';
					
	        		filterCriteria.add('(NOT (' + field + ' IN ' + inClause + '))');
	        	}
	        }
	        else if (operatorType == 'between' || operatorType == 'mtd' || operatorType == 'ytd' || operatorType == 'fmtd' || operatorType == 'fytd') {
	        	List<Object> dates = new List<Object>();
	        	DateTime dtFrom;
	        	DateTime dtTo;
	        	
	        	if (operatorType == 'mtd') {
	        		dtFrom = system.today().toStartOfMonth();
	        		filterCriteria.add(field + ' >= ' + dtFrom.format(dateFormat, 'GMT') + ' AND ' + field + ' <= TODAY');
	        	}
	        	else if (operatorType == 'ytd') {
	        		dtFrom = Date.newinstance(system.today().year(), 1, 1);
	        		filterCriteria.add(field + ' >= ' + dtFrom.format(dateFormat, 'GMT') + ' AND ' + field + ' <= TODAY');
	        	}
	        	else if (operatorType == 'fmtd') {
	        		Id companyId = CompanyService.getDefaultCompanyId();
	        		dtFrom = system.today().toStartOfMonth();
	        	
                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
                SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'Period_Start__c','Period_End__c'
                });
                soql.setWhereClause('Company__c = :companyId AND Type__c = \'Fiscal\' AND (Period_Start__c <= TODAY AND Period_End__c >= TODAY)');
                soql.setLimit(1);
                List<Period__c> periodList = Database.query(soql.getQuery());
	        		
	        		if (periodList.size() > 0) {
	        			Period__c period = periodList[0];
	        			
	        			if (period.Period_Start__c != null) {
	        				dtFrom = period.Period_Start__c;
	        			}
	        		}
	        		
	        		filterCriteria.add(field + ' >= ' + dtFrom.format(dateFormat, 'GMT') + ' AND ' + field + ' <= TODAY');
	        	}
	        	else if (operatorType == 'fytd') {	        			        	    
	        		Id companyId = CompanyService.getDefaultCompanyId();
	        		dtFrom = Date.newinstance(system.today().year(), 1, 1);
	        	
                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
                SOQLUtil soql = new SOQLUtil('Fiscal_Year__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'Fiscal_Year_Start_Date__c','Fiscal_Year_End_Date__c'
                });
                soql.setWhereClause('Company__c = :companyId AND (Fiscal_Year_Start_Date__c <= TODAY AND Fiscal_Year_End_Date__c >= TODAY)');
                soql.setLimit(1);
                List<Fiscal_Year__c> fiscalYearList = Database.query(soql.getQuery());

	        		if (fiscalYearList.size() > 0) {
	        			Fiscal_Year__c fiscalYear = fiscalYearList[0];
	        			
	        			if (fiscalYear.Fiscal_Year_Start_Date__c != null) {
	        				dtFrom = fiscalYear.Fiscal_Year_Start_Date__c;
	        			}
	        		}
	        		
	        		filterCriteria.add(field + ' >= ' + dtFrom.format(dateFormat, 'GMT') + ' AND ' + field + ' <= TODAY');
	        	}
	        	else {
	        		dates = (List<Object>)JSON.deserializeUntyped(String.valueOf(value));
	        	
		        	String fromDate = String.valueOf(dates[0]);
		        	String toDate = String.valueOf(dates[1]);
		        	
		        	if (fieldType == 'date') {
		        		fromDate += ' 12:00 AM';
		        		toDate += ' 12:00 AM';
		        	}
		        	
		        	dtFrom = DateTime.parse(fromDate);
		        	dtTo = DateTime.parse(toDate);
	        	
	        		filterCriteria.add(field + ' >= ' + dtFrom.format(dateFormat, 'GMT') + ' AND ' + field + ' <= ' + dtTo.format(dateFormat, 'GMT'));
	        	}	
			}
		}
		
		return filterCriteria;
    }
}