public with sharing class CSVParser {
 
   public class CSVParserException extends Exception{}	

    public static List<List<String>> parse(String contents, Boolean skipHeaders) {
        
    	List<List<String>> allFields = new List<List<String>>();
    
    	// replace instances where a double quote begins a field containing a comma
    	// in this case you get a double quote followed by a doubled double quote
    	// do this for beginning and end of a field
    	contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
    	// now replace all remaining double quotes - we do this so that we can reconstruct
    	// fields with commas inside assuming they begin and end with a double quote
    	contents = contents.replaceAll('""','DBLQT');
    	// we are not attempting to handle fields with a newline inside of them
    	// so, split on newline to get the spreadsheet rows
    	List<String> lines = new List<String>();
    	try {

            //system.debug('contents:'+contents);

            //Check for EOF as \n\r vs \n.This doesn't work as 'contains' doesnt 'see' the EOF chars.
            /*if(contents.contains('[\n\r]')){
     		  lines = contents.split('[\n\r]');                               
            }
            else{
              lines = contents.split('\n');  
            }*/
            //Sometimes \n\r is made as EOF based on which OS the static resource is edited and saved.So replacing it with \n for uniformity.
            //contents =contents.replaceAll('[\n\r]','\n');
     		//lines = contents.split('[\n\r]');         
            /*The above methods of doing EOF doesnt work as CONTAINS and REPLACEALL dont "see" regExp[\n\r]
             * current uploaded static resource have EOf \n\r Adding additional BELOW logic defense layer 
             * in case they are edited in windows system*/
            //Split it first by \n and if split is improper make it by \n\r
      		lines = contents.split('[\n\r]');                  
             if(lines.size()==1){//Split has not occured properly due to improper EOF .We will get size atleast 2 for file with 1 record.
    		  lines = contents.split('\n');                
            } 		
    		system.debug(LOGGINGLEVEL.INFO,'lines:'+lines);
    		system.debug(LOGGINGLEVEL.INFO,'lines:'+lines.size());

    		//bodyText.split('[\n\r]')
    	} catch (System.ListException e) {
    		System.debug('Limits exceeded?' + e.getMessage());
    	}
    	Integer num = 0;
    	for(String line : lines) {
    		// check for blank CSV lines (only commas)
    		if (line.replaceAll(',','').trim().length() == 0) break;
    		
    		List<String> fields = line.split(',');	
    		List<String> cleanFields = new List<String>();
    		String compositeField;
    		Boolean makeCompositeField = false;
    		for(String field : fields) {
    			if (field.startsWith('"') && field.endsWith('"')) {
    				cleanFields.add(field.replaceAll('DBLQT','"'));
    			} else if (field.startsWith('"')) {
    				makeCompositeField = true;
    				compositeField = field;
    			} else if (field.endsWith('"')) {
    				compositeField += ',' + field;
    				cleanFields.add(compositeField.replaceAll('DBLQT','"'));
    				makeCompositeField = false;
    			} else if (makeCompositeField) {
    				compositeField +=  ',' + field;
    			} else {
    				cleanFields.add(field.replaceAll('DBLQT','"'));
    			}
    		}
    		
    		allFields.add(cleanFields);
    	}
    	if (skipHeaders) allFields.remove(0);
        system.debug('allFields: ' + allFields);
	    return allFields;		
    }
    /*Class to faciliate replacing name/ext id string in reference fields with saleforce id.*/
    public class RelatedSourceObjDefinition{
    	final String SourceFieldName; 
    	final String SourceObjName;
    	final String ChildFieldToUpdate;
  		private integer hash;
  	
    	public RelatedSourceObjDefinition(string SourceFieldName,string SourceObjName, string ChildFieldToUpdate){
    		this.SourceFieldName = SourceFieldName;
    		this.SourceObjName   = SourceObjName;
    		this.ChildFieldToUpdate = ChildFieldToUpdate;
    	}
        public boolean equals(object obj){
            RelatedSourceObjDefinition rd = (RelatedSourceObjDefinition)obj;
            if(SourceFieldName == rd.SourceFieldName
               && SourceObjName == rd.SourceObjName
               && ChildFieldToUpdate == rd.ChildFieldToUpdate){
                   return true;			
               }else{
                   return false;
               }
        }
        public integer hashCode(){
            if(hash == null){
                hash = HashCodeGenerator.getHashCode(this);  
            }
            return hash;
        }
		
    	
    }
     public static List<sObject> parseRecords(Schema.sObjectType sObjType, string csv,map<string,object> mStrValsToReplaceVals){
    	return parseRecords(sObjType,csv,mStrValsToReplaceVals,null);
    }
    public static List<sObject> parseRecords(Schema.sObjectType sObjType, string csv){
     	return parseRecords(sObjType,csv,null,null);
   
    }    
    public static List<sObject> parseRecords(Schema.sObjectType sObjType, string csv,map<string,object> mStrValsToReplaceVals,list<RelatedSourceObjDefinition> InputSourceObjDefList){
   	
	    system.debug('In parse records');
    	long n = system.now().getTime();
    	//Map which stores reference source field def for the list of foreignkeyvalues in input csv string.Name field and Ext Fields of type string are only handled.
    	map<RelatedSourceObjDefinition,list<string>> mSourceDefToSourceRefValFromChild = new map<RelatedSourceObjDefinition,list<String>>();
    	//Map of reference fieldname on csv file to its RelatedSourceObjDef 
    	map<String,RelatedSourceObjDefinition> mChildFieldToSourceDef = new map<String,RelatedSourceObjDefinition>();    	
    	map<string,id> mSourceRefValToSourceId = new map<string,id>();
    	
    	if(InputSourceObjDefList!=null){
	    	//Build this map from input list sourceobjdefs.
	    	for(RelatedSourceObjDefinition relatedSourceDef:InputSourceObjDefList){
	    		if(relatedSourceDef.ChildFieldToUpdate != null){
	    		  mChildFieldToSourceDef.put(relatedSourceDef.ChildFieldToUpdate,relatedSourceDef);
	    		}
	    		else{
	    			throw new CSVParserException('Invalid RelatedSourceObjDefinition :'+relatedSourceDef+' Need to populate attribute ChildFieldToUpdate with reference fieldAPI Name');
	    		}
	    	}
	    }
	    system.debug('mChildFieldToSourceDef :'+mChildFieldToSourceDef);

    	List<sObject> recs = new List<sObject>();
		List<List<String>> rows = parse(csv, false);

		//system.debug('rows: ' + rows);		
		system.debug('rows size: ' + rows.size());
		
        //Build inputfields map from CSV header.
		map<integer, string> mFieldMaps = new map<integer, string>();
		for(integer i=0; i < rows[0].size(); i++){
			mFieldMaps.put(i, rows[0][i]);    
			//system.debug('i: ' + i + ' ' + rows[0][i]);
		}
		rows.remove(0);
		 
        //Get fields map for the sobjectype passed.
        SchemaUtil util = SchemaUtil.getInstance();		
        Map<String, sObjectField> fmap = util.addNoNSfieldsToMap(sobjType.getDescribe().fields.getMap());
		
        //Iterate thru each CSV Line and populate sobject recs.

		for(List<String> row : rows){
			//system.debug('row: ' + row);
		    sObject sObj = sObjType.newSObject() ;

		    //system.debug('fmap: ' + fmap);

		    for(integer i=0; i < row.size(); i++){
		    	String iFieldVal = row[i].trim();
		    	String iFieldName =mFieldMaps.get(i).trim() ;
		        //sObj.put(mFieldMaps.get(i), iFieldObj);
		        //system.debug('mFieldMaps:'+iFieldName.tolowercase());		
		        Schema.DescribeFieldResult dfr;
                sObjectField sObjfield = fmap.get(iFieldName.tolowercase());//TODO with SK:RS -It was failing as addNoNSfieldsToMap --returns Lowercase.
                if(sObjfield!=null){
                  dfr = sObjfield.getDescribe();                   
                }
                else{
                    throw new CSVParserException('Unable to find field '+iFieldName+ ' in sobject '+sObjType);
                }
                
                if(mStrValsToReplaceVals!=null && mStrValsToReplaceVals.containskey(iFieldVal)){
           		//system.debug('dfr:  ' + dfr.getType());
           		//system.debug('iFieldVal:  ' + iFieldVal);
           		//system.debug('value :  ' + mStrValsToReplaceVals.get(iFieldVal));
                	iFieldVal=String.valueof(mStrValsToReplaceVals.get(string.valueof(iFieldVal)));
                	if(dfr.getType() == Schema.DisplayType.REFERENCE){
 	                    sObj.put(iFieldName, iFieldVal); 	               		
                		continue;//Skipping the downstream to  build relatedsourceobjdefs for Id replacement as id is already replaced.
                	}
                    else if(dfr.getType() == Schema.DisplayType.DATETIME){
// 	                    system.debug('Skipping -'+iFieldVal+'-'+mStrValsToReplaceVals.get(iFieldVal));
                        sObj.put(iFieldName,Datetime.valueof(iFieldVal)); //Skipping generating date as user has given valid Date instance.	               		                        
                        continue;
                    }
                    else if(dfr.getType() == Schema.DisplayType.DATE){
 	                    sObj.put(iFieldName,Date.valueof(iFieldVal)); //Skipping generating date as user has given valid Date instance.	               		                        
                        continue;  
                    }

                	else{
                		//Let it go thru downstream if-else checks to get appropriately type-casted.
                	}
                }
                
                        
                if ( dfr.getType() == Schema.DisplayType.Boolean ) {
                    sObj.put(mFieldMaps.get(i), Boolean.valueOf(iFieldVal)) ;
                } else if ( dfr.getType() == Schema.DisplayType.DOUBLE ) {
                    sObj.put(mFieldMaps.get(i), DOUBLE.valueOf(iFieldVal));
                } else if ( dfr.getType() == Schema.DisplayType.PERCENT ) {
                    sObj.put(mFieldMaps.get(i), DOUBLE.valueOf(iFieldVal));
                } else if ( dfr.getType() == Schema.DisplayType.DATE ) { 
                     Date d = DateVal(iFieldVal);
                     sObj.put(iFieldName,d);

               } else if ( dfr.getType() == Schema.DisplayType.DATETIME ) {  
                   // Date d = DateVal( mFieldMaps.get(i)); 
                     Datetime d = DateTimeVal(iFieldVal);
                     sObj.put(iFieldName,d);

                }
                else if ( dfr.getType() == Schema.DisplayType.REFERENCE ){
                	  RelatedSourceObjDefinition relSrcObjDef;
                	  if(mChildFieldToSourceDef.size()>0){//Use custom sourceobjdef passed in by caller.
                	  	 if(mChildFieldToSourceDef.containskey(iFieldName)){
                	  	 	relSrcObjDef = mChildFieldToSourceDef.get(iFieldName);

                	  	 }
                	  	 else{
		            		 if(!dfr.isNamePointing()){//isNamePointing = true if the relationship is to multiple object --example task whatid can be leads /contacts anything.
			                	relSrcObjDef = new RelatedSourceObjDefinition('Name',String.valueof(dfr.getReferenceTo()[0]),mFieldMaps.get(i));	                	
		                	}
	                	 }
                	  }
                	  else{
	            		 if(!dfr.isNamePointing()){//isNamePointing = true if the relationship is to multiple object --example task whatid can be leads /contacts anything.
		                	relSrcObjDef = new RelatedSourceObjDefinition('Name',String.valueof(dfr.getReferenceTo()[0]),mFieldMaps.get(i));	                	
	                	}
                	  }
	        	  	   if(mSourceDefToSourceRefValFromChild.containskey(relSrcObjDef)){
	                	 mSourceDefToSourceRefValFromChild.get(relSrcObjDef).add(iFieldVal);
	                   }
	                   else{
	                	 mSourceDefToSourceRefValFromChild.put(relSrcObjDef,new list<string>{iFieldVal});
	                   }
	                  sObj.put(iFieldName, iFieldVal); 	

                	  //system.debug('relSrcObjDef :'+relSrcObjDef);                	
                }
            
                // Text and, picklist ==text ok, textarea ==text ok
                else {                    
                    sObj.put(iFieldName,String.valueof(iFieldVal)); 

                }
//		        system.debug(mFieldMaps.get(i) + ' ' + iFieldVal);
		    }
		    //system.debug('sObj: ' + sObj);
		    recs.add(sObj); 
		}
//        system.debug('mSourceDefToSourceRefValFromChild'+mSourceDefToSourceRefValFromChild.keySet());
		//Iterate mSourceDefToSourceRefValFromChild to query for ids based on source def and replace the same in the sobj list.
		for( RelatedSourceObjDefinition relSourceDef : mSourceDefToSourceRefValFromChild.keyset()){
//			 system.debug('relSourceDef'+relSourceDef);

            //BuildQuery;
			list<string> SourceRefValsFromChild = new list<string>(mSourceDefToSourceRefValFromChild.get(relSourceDef));
			String SourceObjQuery = ' SELECT Id,'+relSourceDef.SourceFieldName +' FROM ' + relSourceDef.SourceObjName + ' where ' + relSourceDef.SourceFieldName + ' in :SourceRefValsFromChild' ;
			//system.debug('SourceObjQuery'+SourceObjQuery);
			
			//Grab the Source Recs matching the Ref String Vals from child
			list<sObject> SourceRecs = new list<sObject>(Database.Query(SourceObjQuery));
			//system.debug('SourceRecs'+SourceRecs);
			
			//Get Source Ids for respective Ref String Vals from child
			for(sObject SourceRec:SourceRecs){
					mSourceRefValToSourceId.put((string)SourceRec.get(relSourceDef.SourceFieldName),SourceRec.Id);
			}
			//system.debug('mSourceRefValToSourceId'+mSourceRefValToSourceId);
			//Iterate thru sobjects and put the related field with Source Ref Id
			for(sObject rec :recs ){
				string valfield = KSE.NamespaceUU+relSourceDef.ChildFieldToUpdate.trim();
				//system.debug('valfield'+valfield +'rec'+rec);
				rec.put(relSourceDef.ChildFieldToUpdate.trim(),mSourceRefValToSourceId.get((string)rec.get(relSourceDef.ChildFieldToUpdate.trim())));
			}
			
		}
		system.debug('recs: ' + recs);
		long t = system.now().getTime();
//		system.debug('millis: ' + (t - n));
		return recs;
    }
 
    public static Datetime DateTimeVal( string input ) {  
//       		system.debug('datetime val: ' + input);

            try{
	            list<string> dateValsList = new list<string>();
	            list<string> DayTimeList = new list<string>();
	            list<string> TimeValsList = new list<string>();
		        if(input.containsIgnoreCase('Now')){
		        	return system.now();                 		        
		        } 		            
	            else if(input.contains('-')){//Userinput is in YYYY-MM-DDZHH:MM:SS format
	                dateValsList = input.split('-');
	            }
	            else if(input.contains('/')){//Userinput is in YYYY/MM/DDZHH:MM:SS format                 
	                dateValsList = input.split('/');                
	            }    
	            else{
  	              throw new CSVParserException('Expecting datetime format as YYYY-MM-DDTHH:MM:SS or YYYY/MM/DDTHH:MM:SS  for value '+input);    

  	              return null;  	            	
	            }	
            
	            //Split last string into year followed by time val	            
	            DayTimeList = dateValsList[2].split('T');
	            
//	            system.debug('dateValsList:'+dateValsList);	            
//	            system.debug('DayTimeList:'+DayTimeList);		            

	            if(DayTimeList!=null && DayTimeList.size()==2 ){
	            	dateValsList.remove(2);
	            	dateValsList.add(DayTimeList[0]);
	            	TimeValsList = DayTimeList[1].split(':');
	            }
	            else{
  	              throw new CSVParserException('Expecting datetime format as YYYY-MM-DDTHH:MM:SS or YYYY/MM/DDTHH:MM:SS  for value '+input);    
	              return null;        		            		            	
	            }
//	            system.debug('dateValsList:'+dateValsList);	            
//	            system.debug('DayTimeList:'+DayTimeList);	
//	            system.debug('TimeValsList:'+TimeValsList);	

	            	            
	            if(dateValsList.size()==3 && TimeValsList.size()==3){
		 	        Integer year = Integer.valueof(dateValsList[0]);
		            if ((year/1000)==0){//User has given YY instead of YYY.So quotient is < 0 .Integer so trucated to 0.
		                year = year +2000;
		            }
		            Integer month =Integer.valueof(dateValsList[1]);
		            Integer day =  Integer.valueof(dateValsList[2]);    
		            
		            Integer Hours = Integer.valueof(TimeValsList[0]);    
		            Integer Minutes = Integer.valueof(TimeValsList[1]);           	
		            Integer Seconds = Integer.valueof(TimeValsList[2].trim());           	
                    return Datetime.newInstance(year, month,day,Hours,minutes,seconds);                 
		                   	
	            }
	            else{
  	              throw new CSVParserException('Expecting datetime format as YYYY-MM-DDTHH:MM:SS or YYYY/MM/DDTHH:MM:SS  for value '+input);    

  	              return null;        		            	
	            }

            }   
            catch(Exception ex) 
            {

//            	system.debug('Exception occured on datetimeVal '+ex.getMessage()+ex.getLineNumber());
  	            throw new CSVParserException('Expecting datetime format as YYYY-MM-DDTHH:MM:SS or YYYY/MM/DDTHH:MM:SS  for value '+input);    
            	system.debug('Exception occured on datetimeVal '+ex.getMessage()+ex.getLineNumber());
  	            return null;        		            	
            }    
    }        
    public static Date DateVal( string input ) {  
//       		system.debug('date val: ' + input);

            list<object> dateValsList = new list<string>();
            try{
	            if(input.containsIgnoreCase('Today')){
	            	return system.today();                             
	            } 	
	            else if(input.contains('-')){//Userinput is in YYYY-MM-DD format
	                dateValsList = input.split('-');
	            }
	            else if(input.contains('/')){//Userinput is in YYYY/MM/DD format                 
	                dateValsList = input.split('/');                
	            }
	            else{
  	               throw new CSVParserException('Expecting date format as YYYY-MM-DD or YYYY/MM/DD  for value '+input);            	
  	               return null;   	            	
	            }
//	            system.debug('dateValsList:'+dateValsList);

	            if(dateValsList.size()==3){
	                //TODO:Need to come up with a way to ensure if we get valid Integer .Below always returns false.
	                // Integer year = dateValsList[2] instanceof Integer ?Integer.valueof(dateValsList[2]):system.today().year();
	                // Integer month =dateValsList[1] instanceof Integer ?Integer.valueof(dateValsList[1]):system.today().month();
	                // Integer day =  dateValsList[0] instanceof Integer ?Integer.valueof(dateValsList[0]):system.today().day();
	                Integer year = Integer.valueof(dateValsList[0]);
	                if ((year/1000)==0){//User has given YY instead of YYY.So quotient is < 0 .Integer so trucated to 0.
	                    year = year +2000;
	                }
	                Integer month =Integer.valueof(dateValsList[1]);
	                Integer day =  Integer.valueof(dateValsList[2]);                
	                return Date.newInstance(year, month,day);                 
	            } 
	            else{
  	               throw new CSVParserException('Expecting date format as MM-DD-YYYY or MM/DD/YYYY  for value '+input);            	
  	               return null;        		            	
	            }	                       	
            }
            catch(Exception ex){
            	system.debug('Exception occured on dateval '+ex.getMessage()+ex.getLineNumber());
  	            throw new CSVParserException('Expecting date format as MM-DD-YYYY or MM/DD/YYYY  for value '+input);            	
  	            return null;             	
            }


			/*
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
                return system.today();*/
        }
    
}