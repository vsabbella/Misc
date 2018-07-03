/**
	Hides the mapping between Reason_Code__c table and Bracket Price. Exposes minimum internals outside the service.
*/
public with sharing class BracketPricingService {
    public static final String TypeBracketPricingUpcharge = 'BracketPricing';

    public static final Decimal MaxVolumeRangeValue = Math.pow(2, 62);

    /*
        Expexct data in this format of ranges
        43,000# and Up = List Price (no upcharge)
        20,000-42,999 lb = 1% upcharge
        10,000-19,999 lb = 3% upcharge
        5,000#- 9,999 lb = 5% upcharge
        0-4,999 lb = 5% upcharge    
    */
    // K: Company Id
    public static Map<Id, BracketPriceRange[]> loadBracketPricesWithRange(Set<Id> companyIds) {
        Map<Id, BracketPriceRange[]> bracketsByCompanyId = new Map<Id, BracketPriceRange[]>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Reason_Code__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Type__c','Company__c','Code__c','Description__c','Numeric_Field_1__c','Reason_Code_Unique__c'
		});
		soql.setWhereClause('Type__c =:TypeBracketPricingUpcharge and Company__c IN :companyIds');
		soql.setOrderByClause('Numeric_Field_1__c asc');
		
		for( Reason_Code__c rc : Database.query(soql.getQuery())) {
            List<BracketPriceRange> brackets = bracketsByCompanyId.get(rc.Company__c);
            if (brackets == null) {
                brackets = new List<BracketPriceRange>();    
                bracketsByCompanyId.put(rc.Company__c, brackets); 
            }
            brackets.add(new BracketPriceRange(rc));
        }
        
        for (BracketPriceRange[] brackets : bracketsByCompanyId.values()) {
            BracketPriceRange previousOne = null;
            for( BracketPriceRange currentOne : brackets) {
                if (previousOne != null) {
                    // Previous bracket's high is next's LOW - 1 
                    previousOne.volumeRangeHigh = currentOne.volumeRangeBottom - 1;
                }
                previousOne = currentOne;
            }
            if (previousOne != null) {
                // update the last item
                previousOne.volumeRangeHigh = MaxVolumeRangeValue; // a reasonabily high value for max of last ranage
            }
        }

        return bracketsByCompanyId;
    }

    public static Map<Id, Reason_Code__c[]> loadBrackets(Set<Id> companyIds) {
        Map<Id, Reason_Code__c[]> reasonCodesByCompanyId = new Map<Id, Reason_Code__c[]>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Reason_Code__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Type__c','Company__c','Code__c','Description__c','Numeric_Field_1__c','Reason_Code_Unique__c'
		});
		soql.setWhereClause('Type__c =:TypeBracketPricingUpcharge and Company__c IN :companyIds');
		soql.setOrderByClause('Numeric_Field_1__c asc');
		for (Reason_Code__c rc : Database.query(soql.getQuery())) {
            Reason_Code__c[] codes = reasonCodesByCompanyId.get(rc.Company__c);
            if (codes == null) {
                codes = new List<Reason_Code__c>();
                reasonCodesByCompanyId.put(rc.Company__c, codes);
            }    
            codes.add(rc);

        }

        return reasonCodesByCompanyId;
    }

	public static Map<Id, BracketPrice[]> loadBracketPrices(Set<Id> companyIds) {
    	Map<Id, BracketPrice[]> bracketsByCompanyId = new Map<Id, BracketPrice[]>();

        SOQLUtil soql = new SOQLUtil('Reason_Code__c');
        soql.addFields(new set<string>{
			'Id','Name','Type__c','Company__c','Code__c', 
			'Description__c','Numeric_Field_1__c','Reason_Code_Unique__c'         
        });
        soql.setWhereClause('Type__c =:TypeBracketPricingUpcharge and Company__c IN :companyIds');
        soql.setOrderByClause('Numeric_Field_1__c ASC'); 	

        for (Reason_Code__c rc : Database.query(soql.getQuery())) {
            List<BracketPrice> brackets = bracketsByCompanyId.get(rc.Company__c);
            if (brackets == null) {
                brackets = new List<BracketPrice>();    
                bracketsByCompanyId.put(rc.Company__c, brackets); 
            }
            brackets.add(new BracketPrice(rc));
        }
        return bracketsByCompanyId;
    }



    /*
        Type__c                 = 'BracketPricing'
        Name                    = Pricebook Line field name i.e. Price__c | Price2__c
        Code__c                 = Percent value ex. 5
        Company__c              = Company Id to which this tuple belongs
        Description__c          = 
        Numeric_Field_1__c      = Upper value of data range for ex. range 5000 - 9999 we will store 9999. This is kept here to make queries work quickly
        
         Represents a single Bracket price i.e. 
         0-4,999 lb = 5% upcharge Price__c
    */    
    public virtual class BracketPrice {
        // backing data source
        public Reason_Code__c reasonCode {get; private set;}

        public BracketPrice(Reason_Code__c rc) {
            this.reasonCode = rc;
        }

        public BracketPrice(Id companyId) {
            
            this.reasonCode = new Reason_Code__c(
                    Type__c = TypeBracketPricingUpcharge,
                    Company__c = companyId, 
                    Name = 'Price__c' // default to Price__c
                    );
        }
        // derived attributes
        public Decimal volumeRangeBottom {
            get {
                return reasonCode.Numeric_Field_1__c;
            }
            set {
                reasonCode.Numeric_Field_1__c = value;
            }
        }

        public Decimal percentUpCharge {
            get {
                return String.isBlank(reasonCode.Code__c) ? 0 : Decimal.valueOf(reasonCode.Code__c);
            }
            set {
                reasonCode.Code__c = String.valueOf(value);
            }
        }

        public String pricebookLineField {
            get {
                return reasonCode.Name;
            }
            set {
                reasonCode.Name = value;
            }
        }

        public override String toString() {            
            return JSON.serializePretty(this);
        }
    }

    /* Enhances bracket price with range information.
     As we are storing the stuff in a plain range bottom, this class gives ranges for keeping dependent client code simple
     */
    public class BracketPriceRange extends BracketPrice {        
        public Decimal volumeRangeHigh {get;set;}

        public BracketPriceRange(Reason_Code__c rc) {
            super(rc);
        }
    }
}