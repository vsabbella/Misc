public with sharing class FinancialReportExt {

    public Apexpages.Standardcontroller con { get; private set; }
    public String runtime { get; private set; } //KNDY-2515: Add date/time to financial report
    
    public FinancialReportExt(ApexPages.StandardController controller) { 
        con = controller;
        runtime = String.valueOf(Datetime.now());   //KNDY-2515: Add date/time to financial report
        loadLines();
    }

    public Pagereference cloneFR() { // and it's children sections/ items
        String serializedData = SObjectDataLoader.serialize( 
                                                    new set<id>{con.getId()}, 
                                                    new SObjectDataLoader.SerializeConfig().
                                                        followChild( Financial_Report_Section__c.Financial_Report__c).
                                                        followChild( Report_Item__c.Financial_Report_Section__c).
                                                        includeLookups(true)      );
        //system.debug( LoggingLevel.INFO, 'data '+serializedData );
        //system.debug( LoggingLevel.INFO, 'data length '+serializedData.length() );
        Set<ID> resultIds = SObjectDataLoader.deserialize(serializedData, 
                                                    null , 
                                                    new TransformNewRecords()    );
        List<id> fid = new List<id>(resultIds); 
        return new ApexPages.standardController(new Financial_Report__c(id=fid[0] ) ).view();                                                               
        //return null;  
    }
    
    // called for each recod we are about to insert by deserialize
    private class TransformNewRecords implements SObjectDataLoader.ITransformCallback {
        public TransformNewRecords() { } 
        public boolean transformRecord (Schema.SObjectType sObjectType, sobject record ) { 
            //system.debug( logginglevel.info, 'transform '+ record);
            if ( sObjectType == Financial_Report__c.sObjectType) {
                record.put('Company__c',null);
                record.put('Period_Name__c','');
            }
            if ( sObjectType == Report_Item__c.sObjectType) {
                record.put('Key__c',null);
            }
            return true;
        }
    }
    
    private void loadLines() {
    	List<Schema.FieldSetMember> fsFields = SObjectType.Financial_Report__c.FieldSets.Report_Filters.getFields();
    	Map<String,String> fsPathToLabel = new Map<String,String>(); 
    	filterFields = new Map<Id,List<String>>();
    	Set<String> tempSegments = new Set<String>();
    	


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
//V2
SOQLUtil soql = new SOQLUtil('Financial_Report_Section__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','Name','Display_Section_Name__c','Financial_Report__c','Order__c'
});
    string cId = con.getId();        
    soql.setWhereClause('Financial_Report__c = :cId');
soql.setOrderByClause('Order__c ASC');
SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Report_Items__r');
childRel.addFields(new set<string>{
	'Id','Name','Asynchronous__c','Column_Total_Label__c','Company__c','Date_Field__c','Display_Column_Labels__c',
	'Display_Column_Totals__c','Display_Name__c','Report_Key__c','Display_Total__c','End_Date__c','Financial_Report_Section__c',
	'Numeric_Scale__c','Order__c','Period_Name__c','Report_Id__c','Show_Details__c','Start_Date__c','Total_Label__c',
	'Total_On_Top__c','Financial_Report_Section__r.Financial_Report__r.Show_Symbols__c','Financial_Report_Section__r.Financial_Report__r.Symbols_First_Last__c'
});
soql.addChildRelationship(childRel);
records = Database.query(soql.getQuery());



        for (Financial_Report_Section__c sec:records) {
            for (Report_Item__c item:sec.Report_Items__r) {
                if (item.Report_Key__c == null || item.Report_Key__c == '')
                    item.Report_Key__c = ((String)item.Id).substring(8,18);
                    
                
                if (!filterFields.containsKey(item.Id))
                	filterFields.put(item.Id,new List<String>());
                
                List<String> flds = new List<String>();
                 /*
                String query = 'SELECT Id,Name,Financial_Report_Section__r.Financial_Report__r.Report_Object_Name__c';            
    			for (Schema.FieldSetMember fsField:fsFields) {
		    		//TODO:HANDLE NON LOOKUP FILTERS
		       		query += ',Financial_Report_Section__r.Financial_Report__r.' + fsField.getFieldPath().replaceAll('__c','__r') + '.Name';
		       		query += ',Financial_Report_Section__r.Financial_Report__r.' + fsField.getFieldPath();
		       		flds.add(fsField.getFieldPath());
		       		fsPathToLabel.put(fsField.getFieldPath(),fsField.getLabel());
		    	}
    			query += ' FROM Report_Item__c WHERE Id = \'' + item.Id + '\'';    */
    			
                Set<String> cusFields = new Set<String>();
                for (Schema.FieldSetMember fsField:fsFields) {
		    		//TODO:HANDLE NON LOOKUP FILTERS
		       		cusFields.add( ',Financial_Report_Section__r.Financial_Report__r.' + fsField.getFieldPath().replaceAll('__c','__r') + '.Name');
		       		cusFields.add( ',Financial_Report_Section__r.Financial_Report__r.' + fsField.getFieldPath());
		       		flds.add(fsField.getFieldPath());
		       		fsPathToLabel.put(fsField.getFieldPath(),fsField.getLabel());
		    	}
                
                
                
                String whereClause = 'Id = \'' + item.Id + '\'';//KNDY-8796
                 soql = new SOQLUtil('Report_Item__c');
                soql.addFields(new Set<String>{'Id', 'Name', 'Financial_Report_Section__r.Financial_Report__r.Report_Object_Name__c'});
                soql.addFields(cusFields);
                soql.setWhereClause(whereClause);
                
    			
    			//Report_Item__c ri = ((List<Report_Item__c>)Database.query(query))[0];
                Report_Item__c ri = ((List<Report_Item__c>)Database.query(soql.getQuery()))[0];
		    	for (String fieldName:flds) {
		    		String column,value;
		    		
		    		Financial_Report_Section__c section = (Financial_Report_Section__c)ri.getSObject('Financial_Report_Section__r');
		    		
		    		Financial_Report__c report = (Financial_Report__c)section.getSObject('Financial_Report__r');
		    		
		    		if ((String)report.get('Report_Object_Name__c') == null)
		    			break;
		    			
		    		sObject obj = (sObject)report.getSObject(fieldName.replaceAll('__c','__r'));
		    		if (obj == null)
		    			continue;
		    		
		    		column = (String)report.get('Report_Object_Name__c') + '.' + fieldName;
		    		
		    		value = (String)obj.get('Name');
		    		
		    		filterFields.get(item.Id).add(column + '::' + value);
		    		tempSegments.add(fsPathToLabel.get(fieldName) + ' : ' + value);
		    	}
            }
        }
        segments = new List<String>(tempSegments);  
    }
    public List<Financial_Report_Section__c> records { get; private set;}
    public Map<Id,List<String>> filterFields { get; private set; }
    public List<String> segments { get; private set; }
    
    @remoteAction 
    public static id addNewReportItem( string lineid, string reportid, string nam) {
        Report_item__c ri = new Report_item__c();
        ri.name = nam.replaceAll('&amp;','&'); // replace &amp; ==> & TODO use html escape string method
        ri.report_id__c = reportid; 
        ri.Financial_Report_Section__c = lineid; 
        DML.insertAsUser( new List<sobject>{ ri } ); 
        return ri.id; // need the new id back in the client
    } 
    
    @remoteAction 
    public static void removeReportItem ( string reportid ) {
        DML.deleteAsUser( new List<Sobject>{ new Report_Item__c( id = reportid ) } );
    }
    
    public void saveOrder() { 
        DML.checkUpsertAsUser(records); upsert records;
        list<Report_Item__c> itemsList = new list<Report_Item__c>();  
        for (Financial_Report_Section__c f : records ) {
            itemsList.addAll ( f.Report_Items__r );
        }
        DML.checkUpsertAsUser(itemsList); upsert itemsList;
        loadLines();    
    }
    public void reLoad() { loadLines(); }  
    
}