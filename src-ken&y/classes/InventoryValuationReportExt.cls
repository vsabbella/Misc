public with sharing class InventoryValuationReportExt extends BaseController {
	
	public string hierDataJson { get; set; }
	public static string companyCurrency {get;set;}
	public static string NamespaceUU { get { return KSE.NamespaceUU; }} 
	public Boolean allowAllFacilities { get; set; } { allowAllFacilities = false; }
    public String defaultFacility { get; set; } { defaultFacility = ''; }
    public String defaultCompany { get; set; } { defaultCompany = ''; }
    
	public static integer ivChunkSize { get{ return getIVChunkSize('IV-ChunkSize');}}
   
    public InventoryValuationReportExt() {   
 
        UserPreference up = UserPreference.getInstance();
        defaultCompany = up.preference.Default_Company__c;
        defaultFacility = up.preference.Default_Facility__c;

        allowAllFacilities = up.preference.Allow_Access_to_all_Facilities__c;

        if( up.preference == null ||  defaultCompany == null || (allowAllFacilities == false && defaultFacility == null) ){
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, Label.Default_facility_not_setup));
            return;
        }
    }
   
    public class resultChunkObject
    {
        List<sObject> sObjects=new list<sObject>();
        public decimal draftCount;
        string objectName='';
        public boolean hasRecords=false;
        public string Messages='';
    }
    // KNDY-13067 - support for custom cost buckets
    class CostBucket {
        public String field {get;set;}
        public String label {get;set;}
    }
    // KNDY-13067 - support for custom cost buckets
    // get the available item cost buckets
    public String availableCostBucketsJson {
        get {
            if (availableCostBucketsJson == null) {
                List<CostBucket> costBuckets = new List<CostBucket>();
                for ( Schema.FieldSetMember f : ItemService.costRollupFields ){
                    CostBucket bucket = new CostBucket();
                    bucket.field = f.fieldPath; //.replace(NamespaceUU,'');
                    bucket.label = stripField(f);
                    costBuckets.add ( bucket);
                }
                availableCostBucketsJson = JSON.serialize ( costBuckets);
            }
            return availableCostBucketsJson;
        } private set;}
    
    
    public static integer getIVChunkSize(string key)
    {
    	Configuration__c c = Configuration__c.getValues(key);
    	integer chunkSize = 0;
		//attempt to parse the string config value into an integer and make sure it is between min/max
		//if not we are just going to use the default
		if (c != null) {
			Integer configChunk;
			try {configChunk = Integer.valueOf(c.Value__c);} catch (Exception e) {}
			if (configChunk != null) {
				chunkSize = configChunk;
			}
		}
		return chunkSize;				
    	
    }
    
    private static String stripField(Schema.FieldSetMember f) {
        if (f.fieldPath.contains(NamespaceUU) ) {
            return f.fieldPath.replace(NamespaceUU,'').replace('Cost','').replace('__c','').replace('_',' ').trim();
        } else {
            // support for user configured field with namespace
            List<String> strList = f.fieldPath.split('__');
            String fieldName ;
            if ( strList.size () == 2 ) {
                fieldName = strList[0];
            }
            else {
                fieldName = strList[1];
            }
            return fieldName.replace('Cost','').replace('__c','').replace('_',' ').trim();
        }
            
    }
    
    @RemoteAction 
    public  static resultChunkObject getAllTransactions(string facilityID,string asOFDate,string min,string max,Integer TotalChunks,string objectName,boolean isLast, boolean transflag){
        resultChunkObject obj=new resultChunkObject();
        string sdlQuery;   
        String dateFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
		string asOf ='';  
		string icStatus = 'Approved';
		string searchfield = 'CreatedDate';
		
		if(transflag){
			searchfield = 'Transaction_Date__c';
		}
		try
    	{	
			SOQLUtil soql;    		
    		
    		asOf = datetime.parse(asOFDate).addSeconds(59).Format(dateFormat,'GMT');
    		
    		obj.Messages = '';
       		if (objectName == NamespaceUU + 'Facility__c') {
				soql = new SOQLUtil('Facility__c');
				soql.addFields(new set<string>{'id','Company__r.Comp_Currency__c','Company__r.Comp_Currency__r.ISO_code__c'});
				soql.setWhereClause('id =: facilityID');
           	}
       		if (objectName == NamespaceUU + 'Item__c') { 
       			soql = new SOQLUtil('Item__c');
       			soql.addFields(new set<string>{
					'Id','name','Class__c','Class__r.Name','Purchasing_UOM__c','Purchasing_UOM__r.Name','Stocking_UOM__c','Stocking_UOM__r.Name'       			
       			});
	           	if(isLast){
	           		soql.setWhereClause('Id >=:min AND id <=:max');
	           	} else {
					soql.setWhereClause('Id >=:min AND id <: max');
				}
				soql.setOrderByClause('id DESC');
           	}
           	if (objectName == NamespaceUU + 'Location__c') {
       			soql = new SOQLUtil('Location__c');
       			soql.addFields(new set<string>{
					'Id','name'	      			
       			});           		
	           	if(isLast){
	           		soql.setWhereClause('Facility__c = :facilityId AND Id >=:min AND id <=:max');
	           	} else { 
					soql.setWhereClause('Facility__c = :facilityId AND Id >=:min AND id <: max');
				}
				soql.setOrderByClause('id DESC');
           	}

            if (objectName == NamespaceUU + 'Inventory_Transaction__c') {
                soql = new SOQLUtil('Inventory_Transaction__c');
                soql.addFields(new Set<String>{ 'Id', 'Name', 'Consigned_Owner__c', 'CreatedDate', 'From_Location__c', 'From_SKID__c', 'Item__c', 'Net_Quantity__c',
                    'Quantity__c', 'Quantity_Stocking_UOM__c', 'To_Location__c', 'To_SKID__c', 'Transaction_Date__c', 'Type__c',

                    'Item__r.Class__c', 'Item__r.Purchasing_UOM__c', 'Item__r.Stocking_UOM__c' });
                soql.setWhereClause((isLast == true ? 'Id >= :min AND Id <= :max' : 'Id >= :min AND Id < :max') + ' AND ' + searchfield + ' > ' + asOf + ' AND Non_Inventory__c != true and (From_Facility__c = :facilityId OR To_Facility__c = :facilityId) AND (Type__c = \'Sales Order Shipment\' OR (Type__c = \'Work Order Issue From WIP\' OR Customer__c = null))');
                soql.setOrderByClause(searchfield + ', Item__c, From_Location__c, To_Location__c DESC');
            }

            if (objectName == NamespaceUU + 'SKID__c') {
                Set<String> skidTypes = new Set<String>{ SkidService3.SKID_TYPE_LOCATION, SkidService3.SKID_TYPE_INTRANSIT, SkidService3.SKID_TYPE_WIP };
                soql = new SOQLUtil('SKID__c');
                soql.addFields(new Set<String>{ 'Id', 'Consigned_Owner__c', 'Item__c', 'Location__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Type__c' });           			
                soql.setWhereClause((isLast == true ? 'Id >= :min AND Id <= :max' : 'Id >= :min AND Id < :max') + ' AND Quantity_Stocking_UOM__c <> 0 AND Type__c IN :skidTypes AND Location__r.Facility__c = :facilityId AND Consigned_Owner__c = null AND Customer__c = null');
                soql.setOrderByClause('Item__c, Location__c');
            }
		   
			if (objectName == NamespaceUU + 'Item_Cost__c') {
				SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
				facilityQuery.addAllCustomFields();
				facilityQuery.setWhereClause('Id = :facilityId');
				Facility__c facility = Database.query(facilityQuery.getQuery());
				
				soql = new SOQLUtil('Item_Cost__c');		
       			soql.addAllCustomFields();       	
		   		String whereClause = 'Start_Date__c <= ' + asOf + ' and Invalid_Flag__c = false and Status__c = :icStatus and (Facility__c = :facilityId OR (Facility__c = null AND Item__r.Company__c = \'' + facility.Company__c + '\'))';
		   		if(isLast){
					soql.setWhereClause('Id >=:min AND id <=:max AND ' + whereClause);
		   	   	} else {
		       		soql.setWhereClause('Id >=:min AND id <: max AND ' + whereClause);
		   		}
		   		soql.setOrderByClause('Item__c,start_date__c, Date_Approved__c desc');
		   }
			List<sObject> sourceDocLines = Database.query(soql.getQuery());
			obj.objectName = objectName; 
	       	obj.draftCount = sourceDocLines.size();
	       	if(sourceDocLines.size()>0)
	       	{
	       		obj.sObjects.addall(sourceDocLines);
	       		obj.hasRecords =true;
	       	}
	       	obj.messages = 'Success';
               
	   } catch(Exception ex) {
	   		obj.messages = sdlQuery  +'-----> '+ ex.getmessage() + '---->' + ex.getstacktracestring();
	   }
        return obj;

    }

}