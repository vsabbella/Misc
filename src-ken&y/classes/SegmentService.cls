public with sharing class SegmentService {
	
    public class SegmentException extends Exception {}
    
    public list<Segment_Definition__c> segments{
        get{
            if(segments==null){
            	
                segments = Segment_Definition__c.getAll().values();
            

	            SegmentDefinitionWrapper[] segmentWrapperList = new List<SegmentDefinitionWrapper>();
	            SchemaUtil util = SchemaUtil.getInstance();
	            for (Segment_Definition__c segment: segments) {
	            	String ObjAPIName = segment.Object_API_Name__c;
	            	if(ObjAPIName.equalsIgnoreCase('Intercompany__c')){
	            		ObjAPIName = 'Company__c';
	            	}
	                if(!util.objectExists(ObjAPIName)){
	                    throw new SegmentException('The object "' + ObjAPIName + '" does not exist for the ' + segment.name + ' segment. Please correct the Object API Name in the Accounting Entry Segment Definition custom setting.');
	                }
	                
	                if(!util.fieldExists('Accounting_Entry_Line__c', segment.accounting_entry_field__c)){
	                    throw new SegmentException('The field "' + segment.accounting_entry_field__c + '" does not exist on the Accounting Entry Line object for the ' + segment.name + ' segment. Please correct the Accounting Entry Field in the Accounting Entry Segment Definition custom setting.');
	                }
	                
	                segmentWrapperList.add(new SegmentDefinitionWrapper(segment));
	            }
	            
	            segmentWrapperList.sort();
	            segments.clear();
	            
	            for (SegmentDefinitionWrapper sd: segmentWrapperList) {
	                 segments.add(sd.segment);
	            }
            }

            return segments;
        }
        set;
    }
    
    public list<string> getSegmentFields(){
		List<string> segmentFields = new list<string>();
		for(Segment_Definition__c sd : segments){
			segmentFields.add(sd.Accounting_Entry_Field__c);
		}
		return segmentFields;
    }
     
    // return a list of the segment names ,  ex; Company__c, GL_Account__c 
    // used to construct queries against Accounting_Default, Account_Entry 
    public List<String> segmentNameList () { 
        List<string> fields_s = new List<String>{'Id'}; 
        for ( Segment_Definition__c sg : segments ) {           fields_s.add( sg.Name );        }
        return new List<String>(fields_s); 
    }
     
    public List<String> segmentNameListForAP ( Boolean includePrefix, String type ) { 
        List<string> fields_s = new List<String>();
        String str;
        
        String nspace = KSE.NamespaceUU;
        
        if( type == 'Credit') str = 'Invoice_line__r.Accounting_Segment__r.';
        else{
            str = 'Accounting_Segment__r.';
        }
         
        for (Segment_Definition__c sg : segments) {            
            if (includePrefix) {
                fields_s.add(str+sg.Name);
            } else {
                fields_s.add( sg.Name );
            }
        }        
        
        
        return new List<String>(fields_s); 
    }
    
    //The following method is a refactor of insertCustomSegments
    public void assignSegments(Accounting_Rule__c ar, sObject rec, Accounting_Entry_Line__c ael){
        system.debug(logginglevel.info,'ar: ' + ar+'  for ael id:'+ael.id);
        if(ar == null){
            return;
        }
        
        for(Segment_Definition__c s : segments){
            
            Id segmentId;
            string refVal;
            if(s.Accounting_Rule_Reference_Value__c != null && s.Accounting_Rule_Reference_Value__c != ''){
                refVal = (string)ar.get(s.Accounting_Rule_Reference_Value__c);
            }
            
            if(s.Accounting_Entry_Field__c == 'Company__c'){
                //This is safe as long as the line is generated from the AccountingService template line
                segmentId = ael.Company__c;
            }else if(refVal != '' && refVal != null){
                system.debug(logginglevel.info,'refVal: ' + refVal);
                segmentId = AccountingRuleService.getValue(refVal, rec);
                if(segmentId == null && s.Accounting_Rule_Default__c != null && s.Accounting_Rule_Default__c != ''
                    && s.Accounting_Rule_Segment__c != null && s.Accounting_Rule_Segment__c != ''){
                		if((boolean)ar.get(s.Accounting_Rule_Default__c)){
                    		segmentId = (Id)ar.get(s.Accounting_Rule_Segment__c);
                    		system.debug(logginglevel.info,'ar.get(s.Accounting_Rule_Segment__c)'+ar.get(s.Accounting_Rule_Segment__c));
                		}
                }
            }else if(segmentId == null && s.Accounting_Rule_Default__c != null && s.Accounting_Rule_Default__c != ''
                    && s.Accounting_Rule_Segment__c != null && s.Accounting_Rule_Segment__c != ''){
                    	system.debug(logginglevel.info, 'Inside the loop for ref path returns null, go ahead and get the default segment');
                //Check if the segment is unpopulated and if a default can be applied
                system.debug(logginglevel.info, 'Inside (boolean)ar.get(s.Accounting_Rule_Default__c)'+(boolean)ar.get(s.Accounting_Rule_Default__c));
                if((boolean)ar.get(s.Accounting_Rule_Default__c)){
                    segmentId = (Id)ar.get(s.Accounting_Rule_Segment__c);
                    //system.debug(logginglevel.info,'ar.get(s.Accounting_Rule_Segment__c)'+ar.get(s.Accounting_Rule_Segment__c));
                }
            }

            system.debug(logginglevel.info,'segment name: ' + s.name);
            system.debug(logginglevel.info,'segmentId: ' + segmentId);
            if(s.accounting_entry_field__c != null && s.accounting_entry_field__c != ''){
            	system.debug(logginglevel.info,'s.accounting_entry_field__c: '+ s.accounting_entry_field__c+'-----segmentId: '+segmentId);
                ael.put(s.Accounting_Entry_Field__c, segmentId);
                system.debug(logginglevel.info,'ael within last loop of assignsegments: '+ael);
            }
        }
                                            
    }
    
    public string returnSCOAIDString(Accounting_Entry_Line__c ael){
		List<Id> segmentIds = new List<Id>();
		for(Segment_Definition__c sd : segments){
			segmentIds.add((Id)ael.get(sd.accounting_entry_field__c));
		}	
		return string.join(segmentIds, '|');
	}
    
    public class SegmentDefinitionWrapper implements Comparable {

        public Segment_Definition__c segment;
    
        public SegmentDefinitionWrapper(Segment_Definition__c sd) {
            segment = sd;
        }
        
        // Compare segment definitions based on the display order
        public Integer compareTo(Object compareTo) {
            // Cast argument to SegmentDefinitionWrapper
            SegmentDefinitionWrapper compareToSegment = (SegmentDefinitionWrapper)compareTo;
            
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (segment.Display_Order__c > compareToSegment.segment.Display_Order__c) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (segment.Display_Order__c < compareToSegment.segment.Display_Order__c) {
                // Set return value to a negative value.
                returnValue = -1;
            }
            
            return returnValue;       
        }
    }
    
}