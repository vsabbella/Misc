public with sharing class FacilityService {
    /** 
     * @description methods used to read the custom setting and save or change it 
     * used by KenandySetup page
     */
    public Facility__c Facility {get; set; } { facility = new Facility__c(); }

    public boolean doedit { get; set; } { doedit = false; } 
    
    public  UserPreference defaults { get; set; }  
        
    public Pagereference editFacility() {    doedit = true;  return null; }
    
    public void saveFacility() { 
        try { 
            defaults.updateUserPreference();        // modify the user preference record 
            fetchFacilityName();                     // fetch the facility they selected
            doedit = false; 
        } catch( Exception e ) { Apexpages.addmessages(e); }   
    }

    public PageReference manageDefaults() { 
        // simple navagiate to the preferences record, but must save first if there is none
        saveFacility(); 
        return ( Apexpages.hasMessages() ? 
            null : 
            new Apexpages.Standardcontroller(defaults.preference).view()
            );
    }
    
    private void fetchFacilityName() { 
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name'
		});
		Id dfId = defaults.preference.Default_Facility__c;
		soql.setWhereClause('id = :dfId');
		soql.setLimit(1);
		Facility = ((List<Facility__c>)Database.query(soql.getQuery()))[0];
    }
    /**
     * @description constructor for the Kenandy Getting Around page , note the getRecord() is not used
     */ 
    public FacilityService(ApexPages.standardController c) { 
        defaults = UserPreference.getInstance();
        if ( defaults.preference.Default_Facility__c == null ) {
            // switch to edit mode so user can specify a default facility
            doedit=true; 
            // pick a facility for the user if we can
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name'
			});
			soql.setLimit(2);
			List<Facility__c> tmp = Database.query(soql.getQuery());

            //system.debug( Logginglevel.INFO, tmp );
            if ( tmp.size() > 0 ) { 
                Facility = tmp[0];
                defaults.preference.Default_Facility__c = Facility.id;
            }
            ApexPages.addMessage( new ApexPages.Message(Apexpages.Severity.INFO, Label.Confirm_a_default_facility_and_Save));
        } else { 
            fetchFacilityName();
        }
       
    }

    /** 
     * @description pull the user preference record, return the default facility id 
    */
    public static Id getDefaultFacilityId() { 
        UserPreference defaults = UserPreference.getInstance();
        return defaults.preference.Default_Facility__c;
    }
    
    public static id getCompleteLoc(id facilityID){
        if(facilityID!=null){
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','Default_Work_Order_Complete_to_Location__c'
			});
			soql.setWhereClause('id=:facilityID');
			Facility__c facility = ((List<Facility__c>)Database.query(soql.getQuery()))[0];

            return facility.Default_Work_Order_Complete_to_Location__c;
        }else{
            return null;
        }
    }
    
    public static id getScrapLoc(id facilityID){
        if(facilityID!=null){
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','Default_Work_Order_MRB_Location__c'
			});
			soql.setWhereClause('id=:facilityID');
			Facility__c facility = ((List<Facility__c>)Database.query(soql.getQuery()))[0];

            return facility.Default_Work_Order_MRB_Location__c;
        }else{
            return null;
        }
    }
    
    public static Id getWIPLoc(id facilityId) {
        if(facilityId != null) {
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','Default_Work_Order_WIP_Location__c'
			});
			soql.setWhereClause('id=:facilityID');
			Facility__c facility = ((List<Facility__c>)Database.query(soql.getQuery()))[0];

            return facility.Default_Work_Order_WIP_Location__c;
        }
        else{
            return null;
        }
    }
    
   /**
    * Sets the facility identifier on the Facility record.
    *
    */
    private static Map<String,Object> facilityCache = new Map<String,Object>();
    public static Decimal cachedFacilityIdentifier () {
        Map<Id, Facility__c> oldMap = (Map<Id, Facility__c>)trigger.oldMap;
        if (!facilityCache.containsKey('facilityIdentifier') ) {
            Boolean fetchFacility = trigger.isInsert ? true : false;
            if ( trigger.isUpdate ) {
                for (Facility__c f : (List<Facility__c>) trigger.new) {
                    if ( oldMap != null && oldMap.containsKey(f.Id) && oldMap.get(f.Id).Facility_Identifier__c == null) {
                        fetchFacility = true;
                        break;
                    }
                }
            }

            List<Facility__c> facilities = new List<Facility__c> ();
            Decimal facilityIdentifier = 0;
            if ( fetchFacility && !test.isRunningTest() ) {
                SOQLUtil util = new SOQLUtil('Facility__c', true);
                util.addFields(new Set<String>{
                        'Id', 'Facility_Identifier__c'
                });
                util.setWhereClause('Facility_Identifier__c != null');
                util.setOrderByClause('Facility_Identifier__c DESC');
                util.setLimit(1);

                facilities = Database.query(util.getQuery());

                if ( !facilities.isEmpty() && facilities[0].Facility_Identifier__c != null ) {
                    facilityIdentifier = facilities[0].Facility_Identifier__c ;
                }
            }
            facilityCache.put('facilityIdentifier', facilityIdentifier);
        }
        return (Decimal)facilityCache.get('facilityIdentifier');

    }

    public static void setFacilityIdentifier () {
        Decimal facilityIdentifier = FacilityService.cachedFacilityIdentifier();
        Map<Id, Facility__c> facilityMap = (Map<Id, Facility__c>) trigger.oldMap;
        for (SObject f : trigger.new) {
            if (facilityMap != null && facilityMap.containsKey(f.Id) && facilityMap.get(f.Id).Facility_Identifier__c != null) {
                f.put('Facility_Identifier__c', facilityMap.get(f.Id).Facility_Identifier__c);
            } else {
                f.put('Facility_Identifier__c', ++facilityIdentifier);
            }
        }
        facilityCache.put('facilityIdentifier', facilityIdentifier);
    }
}