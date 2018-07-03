/* SetupSampleData
* called from the company detail page in a link, will construct sample data for a given compay
* today uses the TestData class to build data, but can be independent in the future
*/
public with sharing class SetupSampleData {
                                    
    public Company__c company{get;set;}
	public string namespace {get;set;}
    public Id companyId{get;set;}
    public Document document{get;set;}
    public string sourceFile = 'SampleData';
    public integer NumberOfRetries{get;set;}
    public string ChunkStr{get;set;}	
    public integer chunkSize{get;set;}

    public static final map<String,Schema.sObjectType> mFileNamesToSobjectNames = new Map<String,Schema.sObjectType>{
		'TestData_GLType' => GL_type__c.sobjecttype,
		'TestData_GLAccount' => GL_Account__c.sobjecttype,
		'TestData_Periods' => Period__c.sobjecttype,
		'TestData_FiscalYear' => Fiscal_year__c.sobjecttype,
		'TestData_PreconfiguredAccountingRules' => Accounting_rule__c.sobjecttype,
		'SampleData_GLType' => GL_type__c.sobjecttype,
		'SampleData_GLAccount' => GL_Account__c.sobjecttype,
		'SampleData_Periods' => Period__c.sobjecttype,
		'SampleData_FiscalYear' => Fiscal_year__c.sobjecttype,
		'SampleData_PreconfiguredAccountingRules' => Accounting_rule__c.sobjecttype
	};
    
    public SetupSampleData( Apexpages.StandardController con ) { 
        company = (Company__c)con.getRecord(); 
        document = new Document();
        document.FolderId = UserInfo.getUserId(); 
        this.namespace = KSE.NamespaceUU;
              
    }

    // set of objects that are not related to any company
   	private static set<Schema.SObjectType> globalTypes = new set<Schema.SObjectType>{
   		Account.sObjectType, Class__c.sObjectType, UOM__c.sObjectType, Payment_Term__c.sObjectType, Product_Group__c.sObjectType,
        GL_Account__c.sObjectType, Segment_Definition__c.sObjectType, Segment_Validation__c.sObjectType, 
        Accounting_Default_Segment_Definition__c.sObjectType, Stock_Movement_Rule_Settings__c.sObjectType, UOM_Conversion_Details__c.sObjectType, 
        Custom_Tab_Settings__c.sObjectType
    };
    
    /** 
     * called from the SetupCustomData.vfp 
     * take a user supplied load file and insert those records into the org and company
     */
    public class ChunkDataLoad
    {
        public Integer NextChunkIndex=0;
        public Boolean AllDone=false;
        public Decimal Progress;
        public list<string> Messages= new list<string>();
		public integer totalchunks;
        public string ChunkStr;
    }

    public void CustomDataLoad( ) {
        
        if ( document.body == null ) {
            ApexPages.addMessage( new Apexpages.Message( Apexpages.Severity.INFO, 'No file specified'));
            return ;
        }

        CsvToSObjectParser parser = new CsvToSObjectParser();
        parser.bodyText = document.body.toString();
        parser.extIdMap.put('COMPANY',company);            
        
        list<sobject> solist = new list<sobject>(), globalList = new list<sobject>();
        for ( sobject s: parser.parseCsv() ) {
            if ( globalTypes.contains(s.getSObjectType()) ) 
                globalList.add(s);
            else 
                solist.add(s);
        } 

        try { 
            DML.upsertAsSystem(); DML.insertSobjectList( globalList );
            DML.upsertAsSystem(); DML.insertSobjectList( solist); 
        } catch( Exception ex ) { 
            ApexPages.addMessage( new Apexpages.Message( Apexpages.Severity.INFO, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
        }
        if ( ApexPages.hasMessages() == false ) {
            ApexPages.addMessage( new Apexpages.Message( Apexpages.Severity.INFO, Label.Test_data_created) );
        }        
    	return ;
    }
    
    @TestVisible string testBody;
    
    /* normal data loaded by our sample set ( pulled from a resource file ) */
    public PageReference TestDataBuild( ) {
        list<sobject> solist = new list<sobject>(), globalList = new list<sobject>();

        CsvToSObjectParser        parser = new CsvToSObjectParser(); 
        if (testBody==null) {
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('StaticResource', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Body'
			});
			soql.setWhereClause('name = :sourceFile');
			soql.setLimit(1);
			
			StaticResource theStaticResource = Database.query(soql.getQuery());

            parser.bodyText = theStaticResource.body.toString();
        } ELSE { parser.bodyText = testBody; }

		parser.objsToInsert.clear();
        parser.extIdMap.clear();            
        parser.extIdMap.put('COMPANY',company); 
        
        try {
            for ( sobject s: parser.parseCsv() ) {
                if ( globalTypes.contains(s.getSObjectType()) ) 
                    globalList.add(s);
                else 
                    solist.add(s);
            }             
        } catch( Exception ex ) {
            ApexPages.addMessage( new Apexpages.Message( Apexpages.Severity.INFO, Label.Sample_Data_created ) ); 
            //system.debug(LoggingLevel.INFO,'exception on SOLIST'+ ex.getStackTraceString() );
            //ApexPages.addMessage( new Apexpages.Message( Apexpages.Severity.INFO, ex.getMessage()));
            return null;
        }
        try { 
            // do not insert globals if we know there are already there, 
            // because the custom settings we insert use addMessage() and we can't clean up after that
            // the error looks like this : Name: There is already an item in this list with the name Company__c
            
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Segment_Definition__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name'
			});
			soql.setWhereClause('name = \'Company__c\'');

			Segment_Definition__c[] sd = Database.query(soql.getQuery());

            if ( sd.size() == 0 ) { 
                // all clear, insert globals
                DML.upsertAsSystem(); DML.insertSobjectList( globalList ); 
            }
        } catch( Exception e ) { 
            system.debug(LoggingLevel.INFO,'global duplicates detected, not an error');
        }
        
        try {    
            DML.upsertAsSystem(); DML.insertSobjectList( solist); // insert company specific list of data
            
        } catch( Exception ex ) {
            ApexPages.addMessage( new Apexpages.Message( Apexpages.Severity.INFO, Label.Sample_Data_created + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            //ApexPages.addMessage( new Apexpages.Message( Apexpages.Severity.INFO, ex.getMessage()));
            return null; 
        }
        
        // all went as expected message
        ApexPages.addMessage( new Apexpages.Message( Apexpages.Severity.INFO, Label.Test_data_created) );
        return null; 
    } 
      
    // parser from blog article, ported to latest API, add error checking
    public class CsvToSObjectParser {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 

        // Map instead of list since I need the .remove() method AND
        // Map instead of set since DML can't be performed on set of SObject
        public Map<string,sobject> objsToInsert = new Map<string,sobject>();
        
        // A map to associate our external Ids as defined in the CSV with SObject Ids.
        // This helps the code associate related objects. Using two similar maps
        // since this one will hold ALL records (think reference-Map) but the one
        // above holds a running list of uncommited records (think action-Map)
        public Map<string,sobject> extIdMap = new Map<string,sobject>();
        
        public String bodyText;
                
        map<string,sobject> globalMapCache = new map<string,sobject>();
        
        // Run over the lines in the files
        public List<sobject> parseCsv() {
            
            // query the global tables, used to avoid too many queries later
            globalMapCache.clear();
            
            for (Schema.SObjectType typ : globalTypes) {
            	Schema.DescribeSObjectResult r = typ.getDescribe();
                //string qry = 'select id, name from '+ r.getName() + ' limit 1000';
                
                SOQLUtil soql = new SOQLUtil(r.getName());
			    soql.addFields(new Set<String>{'id', 'name'});
			    soql.setLimit(1000);
			    
                for (sobject s: database.query(soql.getQuery())) {
               		globalMapCache.put(r.getName()+(string)s.get('Name'), s);
                }
            }
            
            // Break the body into it's constituent lines
            for (String line: bodyText.split('[\n\r]') ) {                // Ignore comment and empty lines
                line = line.trim();
                if (line.length() == 0)   continue;
                if (line.startsWith('#')) continue; // comment char must be at first pos on a line
                SObject s = munch(line);                   
            }
            
            return objsToInsert.values();
        }
        
        // Robotic muncher. Eats CSV lines and returns SObjects
        private SObject munch(String s){
            SObject obj;            
            String eId; 

            for(String pairString: s.split(',')){
                // Some boilerplate splitting
                List<String> pairs = pairString.split(':');
                
                String key = pairs[0].trim(); // Don't forget to Trim!

                // if pairs array has no second element, then null was passed
                String value = pairs.size()>1? pairs[1].trim():null; // Waste not, want not.
               
                // Reserved keyword in the CSV markup - used
                // to denote the object name
                if(key.equalsIgnoreCase('object')) {
                    
                    Schema.SObjectType sot = Schema.getGlobalDescribe().get(value);
                    if ( sot == null ) sot = Schema.getGlobalDescribe().get(KSE.NamespaceUU+value);
                    obj = sot.newSObject(); 

                // Reserved keyword - denotes the parent record Id
                } else if(key.equalsIgnoreCase('relatedTo')) {
                    
                    // More boilerplate
                    string[] referenceFields = value.split('#');
                    String fieldName = referenceFields[0];
                    String extId = referenceFields[1];
                    
                    // Find the parent record, look in the map, and in the database
                    SObject parentObj = extIdMap.get(extId);
                    
                    if ( parentObj == null ) {                        
                        Schema.SObjectType relatedType =  getTypeFromTableAndField(obj.getSObjectType(),fieldName);
                    	Schema.DescribeSObjectResult r = relatedType.getDescribe();
                    	parentObj = extIdMap.get(r.getName()+extId);		// see if this form of extId is in the map 
                    
                        if ( parentObj==null ) {  // still missing ? perhaps extId is a name in the DB
                            // store this in the extId map using the object name AND the record name
                            //string qry = 'select id, name from '+ r.getName() + ' limit 1000';
                            
                            SOQLUtil soql = new SOQLUtil(r.getName());
						    soql.addFields(new Set<String>{'id', 'name'});
						    soql.setLimit( 1000 );
	    
                            for (sobject tmp: database.query(soql.getQuery())) {
                                extIdMap.put(r.getName()+(string)tmp.get('Name'), tmp);
                            }
                            // finaly, see if we now have the related parent 
                            // after using name to find it in the DB
                            parentObj = extIdMap.get(r.getName()+extId);
                        }
                    }
                    system.assert( parentObj != null,' could not locate record with extId :'+extId);
                    
                    if ( parentObj.id == null ) {
                        Schema.DescribeSObjectResult r = parentObj.getSObjectType().getDescribe();
                        if ( globalMapCache.containsKey(r.getName()+(string)parentObj.get('Name')) ) { 
                            parentObj = globalMapCache.get(r.getName()+(string)parentObj.get('Name'));
                        }
                    }
                    
                    // Find the parent record id. Now here we violate the
                    // 'No DML in a loop' golden rule because the parent
                    // record Id is required for the association. There is
                    // way to get around this by using a few lists and a map
                    // or two. I don't deem it necessary since I have direct
                    // control over the number of records in the sample file,
                    if ( parentObj.id == null ) {
                        DML.insertAsSystem(parentObj); 
                        objsToInsert.remove(extId);
                    }
                    
                    obj.put(fieldName, parentObj.id);
                    
                } else if( key.equalsIgnoreCase('extId')) {
                    // Reserved keyword - used to associate my CSV record to others in the file (or DB by name)
                    eId = value;
                    
                } else {
                    // Everything else i.e. the real field values
                    // need to type this value, enhance with all data types 
                    
			        //KNDY-7410
			        //Map<String, Schema.SobjectField> fmap = obj.getSObjectType().getDescribe().fields.getMap();
			        SchemaUtil util = SchemaUtil.getInstance();
					Map<String, sObjectField> fmap = util.addNoNSfieldsToMap(obj.getSObjectType().getDescribe().fields.getMap());
                    
                    if(key != null && key != ''){
                    	system.assert( fmap.containsKey( key), 'could not find field :'+key);
                    
                        Schema.DescribeFieldResult dfr = fmap.get(key).getDescribe(); 
                        
                        if ( dfr.getType() == Schema.DisplayType.Boolean ) {
                            obj.put(key, Boolean.valueOf(value)) ;
                        } else if ( dfr.getType() == Schema.DisplayType.DOUBLE ) {
                            obj.put(key, Decimal.valueOf(value));
                        } else if ( dfr.getType() == Schema.DisplayType.PERCENT ) {
                            obj.put(key, Decimal.valueOf(value));
                        } else if ( dfr.getType() == Schema.DisplayType.DATE ) {                        
                            obj.put(key, DateVal( value));
                        } else if ( dfr.getType() == Schema.DisplayType.DATETIME ) {  
                            Date d = DateVal( value); 
                            obj.put(key, DateTime.newInstance(d.year(),d.month(),d.day(),0,0,0));
                        }
                    
                        // Text and, picklist ==text ok, textarea ==text ok
                        else {

                            if ( value != null && value.containsIgnoreCase('YEAR') ) {
                                value=String.valueOf(System.now().year());
                            }
                            if ( value != null && value.containsIgnoreCase('{!COMPANY.NAME}' ) ) {
                                value = value.replaceAll('\\{\\!COMPANY\\.NAME\\}', (String)extIdMap.get('COMPANY').get('Name') );
                            }
                            
                            obj.put(key, checkValueSubstitute( value )); 
                        }
                    }
                }
            }
            
            // we will require this so that we don't have nulls in the map...
            // actually, if we get a null , just don't add that row..  some rows 
            // look like this ,,,,,,,,,            
            if ( eId != null && obj != null ) {
                system.assert( eId != null , 'Expected extId for line :'+ obj + '  line:'+s);
                objsToInsert.put(eId, obj);
                
                system.assert( extIdMap.get(eID) == null , 'Duplicate extId on line :'+obj + ' line:'+s);
                extIdMap.put(eId, obj);
            }
            return obj;
        }
        
        // perform a string substitution so we can expand extId's to actual record ids
        public string checkValueSubstitute( string value ) {
            if ( value != null && value.containsIgnoreCase('{!') && value.containsIgnoreCase('}') ) {
                string extId = value.substringAfter('{!').substringBefore('}');
                if ( extIdMap.containsKey( extId ) ) {
                    sobject tmpValue = extIdMap.get(extId);
                    if ( tmpValue.id == null ) {
                        DML.insertAsSystem(tmpValue); 
                        objsToInsert.remove(extId);
                    }
                    if ( tmpValue.id != null ) {
                        value = value.replace( extId , tmpValue.id).replace('{!','').replace('}','');
                    }
                }
            }
            return value;
        }

        public Date DateVal( string input ) {  
            // need to deal with syntax like this DATE(YEAR,1,1)
            if ( input.containsIgnoreCase('DATE') ) {
                input = input.trim().replaceFirst('DATE','');     // (YEAR, 1, 1)
                input = input.replaceAll('[\\(\\)]','');
                string[] rr = input.split('-');
                if ( rr[0].trim() == 'YEAR') rr[0]= string.valueof(system.now().year());
                return Date.newInstance(integer.valueof(rr[0]), integer.valueof(rr[1]),integer.valueof(rr[2]));
            } else if (input.containsIgnoreCase('TODAY') ) { 
                // parse a  pattern ~= TODAY +/- 30 
                // remove the TODAY 
                input = input.trim().replaceFirst('TODAY','').trim();
                string addedDaysStr = input.replaceAll('[^-\\d]','');
                // remove extra chars , keeping digits and any minus sign
                return System.today().addDays((addedDaysStr == null || addedDaysStr == '') ? 0: Integer.valueof(addedDaysStr));
            } else 
                return system.today();
        }
        
        // find the related object name given an object and field name
        Schema.SObjectType getTypeFromTableAndField( Schema.SObjectType table, string field) {
            String obj = table.getDescribe().getName();
            Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
            Schema.SObjectType sobjType = gd.get(obj); 
            Schema.DescribeSObjectResult describeResult = sobjType.getDescribe(); 

	        //KNDY-7410
    		//Map<String,Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
	        SchemaUtil util = SchemaUtil.getInstance();
			Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(describeResult.fields.getMap());            
             
            
            Schema.SObjectField matched;
            for ( Schema.SObjectField f: fieldsMap.values() ) { 
                if ( f.getDescribe().getName() == KSE.NamespaceUU + field) { 
                    matched = f;
                }
            }
            system.assert( matched != null, 'could not loate field :'+field +' in table '+obj);
        	return matched.getDescribe().getReferenceTo()[0];
        }
    } 
   
   
   public Pagereference prepareDataLoad(){
    	NumberOfRetries=KSE.getRetries('dataLoadRetries');
        ChunkDataLoad obj = new ChunkDataLoad();
        list<string> fileNameChunks = new list<string>();
        list<StaticResource> totalchunksToBeSorted = [SELECT id, Body,Name FROM StaticResource WHERE name like '%TestData%' OR name like '%SampleData%'];		
		system.debug('totalchunksToBeSorted:  ' + totalchunksToBeSorted);
        list<StaticResource> totalchunks = new list<StaticResource>();
		for(integer i=0; i<totalchunksToBeSorted.size(); i++){
			totalchunks.add(new StaticResource());
		
		}
		for(StaticResource st:totalchunksToBeSorted){
			if(st.name.contains('GLType') && totalchunks.size()>0 && st.name.contains('TestData')){
				totalchunks.set(0,st);
				continue;
			}else if(st.name.contains('GLAccount') && totalchunks.size()>1 && st.name.contains('TestData')){
				totalchunks.set(1,st);
				continue;
				
			}else if(st.name.contains('FiscalYear')  && totalchunks.size()>2 && st.name.contains('TestData')){
				totalchunks.set(2,st);
				continue;
			}else if(st.name.contains('Periods') && totalchunks.size()>3 && st.name.contains('TestData')){
				totalchunks.set(3,st);
				continue;
			}else if(st.name.contains('PreconfiguredAccountingRules') && totalchunks.size()>4 && st.name.contains('TestData')){
				totalchunks.set(4,st);
				continue;
			}else if(st.name.contains('GLType') && totalchunks.size()>5 && st.name.contains('SampleData')){
				totalchunks.set(5,st);
				continue;
			}else if(st.name.contains('GLAccount') && totalchunks.size()>6 && st.name.contains('SampleData')){
				totalchunks.set(6,st);
				continue;
			}else if(st.name.contains('FiscalYear') && totalchunks.size()>7 && st.name.contains('SampleData')){
				totalchunks.set(7,st);
				continue;
			}else if(st.name.contains('Periods') && totalchunks.size()>8 && st.name.contains('SampleData')){
				totalchunks.set(8,st);
				continue;
			}else if(st.name.contains('PreconfiguredAccountingRules') && totalchunks.size()>9 && st.name.contains('SampleData')){
				totalchunks.set(9,st);
				continue;
			}
		}
		
		system.debug('totalchunksToBeSorted :' + totalchunksToBeSorted);
		system.debug('totalchunks :' + totalchunks);
		
		for(StaticResource st:totalchunks){
			fileNameChunks.add(st.name);
		}
		companyId = company.id;
	    string ChunkJSON = JSON.serialize(fileNameChunks);
		obj.totalchunks = totalchunks.size();
  	    obj.ChunkStr = ChunkJSON;
  	    chunkStr = obj.ChunkStr;
  		chunkSize = obj.totalchunks;
  			return null;
    }
 
    @RemoteAction
    public static ChunkDataLoad InsertSampleData(integer CurrChunkIndex,string fileName,Integer TotalChunks, id companyId)
    {
	    system.debug('In InsertSampleData');
		ChunkDataLoad obj = new ChunkDataLoad();
		map<string,period__c> mPeriods = new map<string,period__c>();
        try
        {
            if(currChunkIndex>=TotalChunks)
            {
                    //Empty remote call.Defering and waiting for del drafts to complete
            }
            else 
            {

         		list<StaticResource> staticFile = [SELECT id, Body,name FROM StaticResource WHERE name =: fileName limit 1];
         		list<sObject> parsedRecordsToCommitList = new list<sObject>();
         		list<sobject> parsedRecordsToCommitListTypecasted;
         		if(staticFile != null && staticFile.size() != 0){
           			map<string,object> mFieldToValuesMap = new map<string,object>();
         			list<fiscal_year__c> fiscalyear = [select id,name from fiscal_year__c where company__c =:companyId limit 1];
         			if(fiscalyear != null && fiscalyear.size() > 0){
	          			mFieldToValuesMap.put('{FiscalYear}', fiscalyear[0].id);
         			}
         			mFieldToValuesMap.put('{Company}', companyId);
         			mFieldToValuesMap.put('{Start Date}', datetime.newInstance(System.Today().year(), 1,1));
         			mFieldToValuesMap.put('{End Date}', datetime.newInstance(System.Today().year()+1, 1,1));
         			mFieldToValuesMap.put('YEAR-1-1', datetime.newInstance(System.Today().year(), 1,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-2-1', datetime.newInstance(System.Today().year(), 2,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-3-1', datetime.newInstance(System.Today().year(), 3,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-4-1', datetime.newInstance(System.Today().year(), 4,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-5-1', datetime.newInstance(System.Today().year(), 5,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-6-1', datetime.newInstance(System.Today().year(), 6,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-7-1', datetime.newInstance(System.Today().year(), 7,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-8-1', datetime.newInstance(System.Today().year(), 8,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-9-1', datetime.newInstance(System.Today().year(), 9,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-10-1', datetime.newInstance(System.Today().year(), 10,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-11-1', datetime.newInstance(System.Today().year(), 11,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-12-1', datetime.newInstance(System.Today().year(), 12,1,0,0,0));
         			mFieldToValuesMap.put('YEAR-12-31', datetime.newInstance(System.Today().year(), 12,31,0,0,0));
         			if(mFileNamesToSobjectNames.containskey(staticFile[0].name)){
	   					 system.debug('In InsertSampleData here mFileNamesToSobjectNames: ' + mFileNamesToSobjectNames.get(staticFile[0].name));
	   					 system.debug('In InsertSampleData here staticFile: ' + staticFile[0].body.toString());                        
	   					 system.debug('In InsertSampleData here mFieldToValuesMap: ' + mFieldToValuesMap);
         				parsedRecordsToCommitList = CSVParser.parseRecords(mFileNamesToSobjectNames.get(staticFile[0].name),staticFile[0].body.toString(),mFieldToValuesMap);
         			}
         		}
	   					 system.debug('In InsertSampleData here again : ' + parsedRecordsToCommitList);
				if(parsedRecordsToCommitList != null && parsedRecordsToCommitList.size() != 0){
					system.debug('parsedRecordsToCommitList:  ' + parsedRecordsToCommitList);
					if(mFileNamesToSobjectNames.get(staticFile[0].name) == GL_type__c.sobjecttype){
						parsedRecordsToCommitListTypecasted = new list<gl_type__c>();
						for(sobject sobj:parsedRecordsToCommitList){
							parsedRecordsToCommitListTypecasted.add((gl_type__c)sobj);
						}
						Schema.SObjectField extId = gl_type__c.Fields.Primary_Key__c;
						database.upsert((list<gl_type__c>)parsedRecordsToCommitListTypecasted,false); 
					}
					if(mFileNamesToSobjectNames.get(staticFile[0].name) == GL_Account__c.sobjecttype){
						parsedRecordsToCommitListTypecasted = new list<GL_Account__c>();
						for(sobject sobj:parsedRecordsToCommitList){
							parsedRecordsToCommitListTypecasted.add((GL_Account__c)sobj);
						}
						Schema.SObjectField extId = GL_Account__c.Fields.GL_Account_Unique__c;
						
                        List<Database.upsertResult> Results = database.upsert((list<GL_Account__c>)parsedRecordsToCommitListTypecasted,false); 
					}
					if(mFileNamesToSobjectNames.get(staticFile[0].name) == Fiscal_Year__c.sobjecttype){
						parsedRecordsToCommitListTypecasted = new list<Fiscal_Year__c>();
						for(sobject sobj:parsedRecordsToCommitList){
							parsedRecordsToCommitListTypecasted.add((Fiscal_Year__c)sobj);
						}
						Schema.SObjectField extId = Fiscal_Year__c.Fields.Primary_Key__c;
						List<Database.upsertResult> Results = database.upsert((list<Fiscal_Year__c>)parsedRecordsToCommitListTypecasted,false); 
					}
					if(mFileNamesToSobjectNames.get(staticFile[0].name) == Period__c.sobjecttype){
						parsedRecordsToCommitListTypecasted = new list<Period__c>();
						for(sobject sobj:parsedRecordsToCommitList){
							parsedRecordsToCommitListTypecasted.add((Period__c)sobj);
						}
						Schema.SObjectField extId = Period__c.Fields.Primary_Key__c;
						List<Database.upsertResult> Results = database.upsert((list<Period__c>)parsedRecordsToCommitListTypecasted,false); 
					//system.debug('upsert done' + Results );
					}
					if(mFileNamesToSobjectNames.get(staticFile[0].name) == Accounting_Rule__c.sobjecttype){
						parsedRecordsToCommitListTypecasted = new list<Accounting_Rule__c>();
						for(sobject sobj:parsedRecordsToCommitList){
							parsedRecordsToCommitListTypecasted.add((Accounting_Rule__c)sobj);
						}
						Schema.SObjectField extId = Accounting_Rule__c.Fields.Unique_Key__c;
						database.upsert((list<Accounting_Rule__c>)parsedRecordsToCommitListTypecasted,false); 
					}
          		}
                obj.NextChunkIndex=CurrChunkIndex+1;
                if(CurrChunkIndex==TotalChunks-1)
                {
                	obj.AllDone=true;
                }
                else
                {
                  	obj.AllDone=false;

                }


            }

        }
        catch(Exception ex)
        {
            obj.messages.add(ex.getMessage()+ 'on Line'+ex.getLineNumber());
 		system.debug('obj.messages **** ' + obj.messages);
            obj.progress=-1;
            obj.AllDone=false;

        }
        return obj;

    }    

}