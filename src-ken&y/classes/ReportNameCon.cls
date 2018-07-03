global with sharing class ReportNameCon {
    
    global string developerName { get; set; }  
    
    global string errorMsg { get; private set; }  
    
    global Report ReportItem { get; set; } 
    
    global string reportId { get    { errorMsg = null;
        if ( reportId == null ) {     
            try { 
                // look up a report by it's developer name
                
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('Report', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'SystemModstamp','OwnerId','NamespacePrefix','Name','LastViewedDate','LastRunDate','LastReferencedDate','LastModifiedDate',
					'LastModifiedById','IsDeleted','Id','DeveloperName','Description','CreatedDate','CreatedById'
				});
				soql.setWhereClause('DeveloperName = :developerName');
				soql.setLimit(1);

				ReportItem = Database.query(soql.getQuery());
       
            } catch ( Exception ex ) {
                errorMsg = ex.getMessage() + '>' +  developerName;
            } 
            reportId = ( ReportItem!=null? ReportItem.Id:null );
        
        }
        return reportId;
    }   private set; } 
    
    
    // some date primitives for a page to use
    global Date getToday()  { return system.today(); } 
    global Map<integer,date> weeksBeforeToday { get { 
            return datesFromToday( -7 );
    } }
    global Map<integer,date> weeksFromToday { get { 
            return datesFromToday( 7 );
    } } 
        
    
    // private utility methods
    private date reportStartOfThisWeek() { 
        return system.today().toStartOfWeek().addDays(1); 
    }
    
    // ten dates in an array, of given increment between them
    private Map<integer,date> datesFromToday( integer increment )
    {  
            Map<integer,date> ret = new Map<integer,date>();  
            date start = reportStartOfThisWeek();   
            for ( integer i = 0; i < 10 ;  i++ ) { 
            ret.put( i , start ); 
            start = start.addDays(increment); 
            }
            return ret;
    } 
    
    
}