public with sharing class UserPreference {
    
    /** 
    * implements a Singleton interface to the user preference record 
    */    
    public static UserPreference getInstance() {        // lazy load the record only if it doesn't already exist
        if ( instance == null ) {
            instance = new UserPreference();  // builds instance.preference             
        }
        return instance;
    } 
    
    public User_Preference__c preference { get; set; } 
    
    // private static variable referencing the class
    private static UserPreference instance = null;
    
    // The constructor is private and initializes the user 'preference' record
    private UserPreference() {        getUserPreference( UserInfo.getUserId() );     }
    
    // get from database or create it
    private void getUserPreference(id UserID){      
        if ( UserID == null ) 
        	UserID = UserInfo.getUserId();
        
        preference =  getExistingUserPreference(UserID);
        
        if ( preference == null ) { 
            // no preference created yet for this user, create one
            
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('User', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','FirstName','LastName','UserType'
			});
			soql.setWhereClause('id = :UserID');

			User usr = Database.query(soql.getQuery());

            preference = new User_Preference__c();
            if(usr.UserType == 'Standard'){
                preference.Name = usr.FirstName + ' ' + usr.LastName;
                preference.ownerID = UserID;
                preference.User__c = UserID;
            }            
            // still cannot insert here since we are in a DML blackout zone, called from many constructors            
        }   
    }
    
    private User_Preference__c getExistingUserPreference(Id userId) {
        if (userId == null) userId = UserInfo.getUserId();

        SOQLUtil upQuery = new SOQLUtil('User_Preference__c');
        upQuery.addAllFields();
        upQuery.addFields(new Set<String>{ 'Default_Company__r.Consol_Currency__c', 'Default_Company__r.Default_Rollup_Basis__c',
            'Default_Company__r.Default_Transaction_Currency__c', 'Default_Company__r.Auto_Plan_Pick__c', 'Default_Company__r.Stat_Currency__c',
            'Default_Facility__r.Default_Work_Order_Complete_to_Location__c', 'Default_Facility__r.Facility_Identifier__c' });
        upQuery.setWhereClause ('User__c = :userId or OwnerId = :UserId');

        try { return (User_Preference__c)Database.query(upQuery.getQuery())[0]; } catch (Exception e) { }

        User_Preference__c up;
        return up;
    }
    
    private SegmentService service = new SegmentService();
    public List<Segment_Definition__c> special_segments { get { return service.segments;  }}
    
    public void updateUserPreference() {        // set or throw an error
        preference.OwnerId = UserInfo.getUserId(); // only set your own
        if ( preference.id == null ) { // we are inserting for the first time
            
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			Id ownerId = preference.ownerid;
			
			SOQLUtil soql = new SOQLUtil('User', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Name'
			});
			soql.setWhereClause('id = :ownerId');
			soql.setLimit(1);
			
			User userRecord = Database.query(soql.getQuery());
			preference.name = userRecord.name;
        }
        DML.checkUpsertAsUser(preference); upsert preference; 
    }  
    
    public void assignDefaultOrganization(sobject obj, id UserID){      // used by SupplierExt.cls 
        if(preference==null || preference.ownerID!=UserID){   
            getUserPreference(UserID);
        }
        if(preference.Default_Company__c!=null){
            obj.put('Company__c', preference.Default_Company__c);
        }        
    }
    
    public Id getDefaultFacility(Id UserId)     {                       // used by FacilityService.cls
        Id result;
        if(preference==null || preference.ownerID!=UserID){
            getUserPreference(UserID);
        }
        if( preference.Default_Facility__c != null) {
            result = preference.Default_Facility__c;
        }
        return result;        
    }
}