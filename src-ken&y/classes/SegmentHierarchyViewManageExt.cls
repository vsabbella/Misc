public class SegmentHierarchyViewManageExt extends baseController{

    public string fieldsetName{get;set;}
    public string hierField{get;set;}
    public String hierarchyFieldList ;
    public String SegmentFieldList ;
    public string NamespaceUU { get { return KSE.NamespaceUU; }} 
    public static SchemaUtil util = SchemaUtil.getInstance();

    public string HelpURL{get;set;}
	public class KendoTreeHierarchyException extends Exception{}
    
	
    public class ResultFetchHierarchy
    {
        string Message='';
        boolean showBlockTwo;
        boolean showBlockThree;
		string sObjectListJSON;     
    }
    
    
    
	public class HierarchyWrapper{
	 	public String HierarchyName{get;set;}
	 	public Id RecId{get;set;}
	 	public String SegmentType{get;set;}
	 	HierarchyWrapper(String hName,String SegmentType ){
	 		this.HierarchyName = hName;
	 		this.SegmentType = SegmentType;
	 	}
	 	HierarchyWrapper(String hName,String SegmentType, Id recId ){
	 		this.HierarchyName = hName;
	 		this.SegmentType = SegmentType;
	 		this.RecId = recId;
	 	}
	}
    public SegmentHierarchyViewManageExt(){
    	//KNDY-10322 Adding Help page
        HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpHierarchy';  
        fieldsetName='HierarchyView';
    }

    
    @RemoteAction
    public static boolean checkHierarchyNameAvailability(string selectedHierarchyName, string selectedHierarchyType){
	    if(selectedHierarchyType != null && selectedHierarchyType != '' && selectedHierarchyType.contains('__c')){
        	selectedHierarchyType = util.getGlobalDescribe(selectedHierarchyType).getDescribe().getLabel();
        }
        SOQLUtil soql = new SOQLUtil('Hierarchy__c');
        boolean nameExists;
        string whereClause = 'Name =  \'' + selectedHierarchyName + '\'  and Type__c = ' + '\'' +selectedHierarchyType + '\'';
		soql.addField('Id');
		soql.setlimit(2);
		soql.setWhereClause(whereClause);
		list<Hierarchy__c> hRecs = Database.query(soql.getQuery());
		if(hRecs != null && hRecs.size()>=1){
			nameExists = true;
		}else{
			nameExists = false;			
		}
            system.debug('nameExists:  ' + nameExists);
				
		return nameExists;		
    
    }
				

    @RemoteAction
    public static ResultFetchHierarchy FetchHierarchy(string selectedHierarchyName, string selectedHierarchyType, string asOfDateJSON,string asOfDateNewJSON){
        ResultFetchHierarchy resultobj = new ResultFetchHierarchy();
	    if(selectedHierarchyType != null && selectedHierarchyType != '' && selectedHierarchyType.contains('__c')){
        	selectedHierarchyType = util.getGlobalDescribe(selectedHierarchyType).getDescribe().getLabel();
        }
        try{
            dateTime asOfDateOld;
            dateTime asOfDate;
            system.debug('Inside remoteaction **** ');
        	list<sobject> sobjectList = new list<sobject>();
        	if(asOfDateNewJSON != null && asOfDateNewJSON != ''){
				asOfDate = (dateTime)JSON.deserialize(asOfDateNewJSON, dateTime.class);
				asOfDateOld = (dateTime)JSON.deserialize(asOfDateJSON, dateTime.class);
						system.debug('asOfDate:  '+ asOfDate);
						system.debug('asOfDateOld:  '+ asOfDateOld);
        	}
        	else{
				asOfDate = (dateTime)JSON.deserialize(asOfDateJSON, dateTime.class);
			}
            if(selectedHierarchyType == 'Select Segment Type'){   
            	resultobj.message = 'Please select Segment type.';	
            }
             else {
                system.debug('here **** ');
                SOQLUtil soql = new SOQLUtil('Hierarchy__c');
                string whereClause;
                //if(!selectedHierarchyType.contains('Cross'))
                	//selectedHierarchyType = util.getGlobalDescribe(selectedHierarchyType).getDescribe().getLabel();
                if(selectedHierarchyName != null && selectedHierarchyName != ''){
					whereClause = 'Type__c = ' + '\'' +selectedHierarchyType + '\'' + ' AND Name like  \'%' + selectedHierarchyName + '%\''; 
					list<Hierarchy__c> hRecsended = new list<Hierarchy__c>();
					if(asOfDateOld != null){
						string whereClauseForOldDate	= ' AND (start_datetime__c <=:asOfDate  AND (End_DateTime__c <=: asOfDateOld OR End_DateTime__c = null))';
					    soql.addAllFields();
						soql.setWhereClause(whereClause+whereClauseForOldDate);
						system.debug('hRecsended getQuery():  '+ soql.getQuery());
						hRecsended = database.query(soql.getQuery());
						system.debug('hRecsended:  '+ hRecsended);
					}
					whereClause	+= ' AND start_datetime__c <=:asOfDate  AND (End_DateTime__c >: asOfDate  OR End_DateTime__c = null) AND Id not in: hRecsended ';
                	
				    soql.addAllFields();
					soql.setWhereClause(whereClause);
					map<string,set<Id>> mObjectIds = new map<string,set<Id>>();
					set<string> HierName = new set<String>();
					system.debug('soql.getQuery():  '+ soql.getQuery());
					list<Hierarchy__c> hRecs = new list<Hierarchy__c>();
					hRecs = Database.query(soql.getQuery());
	                system.debug('hRecs:  '+hRecs);
	                if(hRecsended != null && hRecsended.size()>1){
	                	hRecs.addAll(hRecsended);
	                }
	                system.debug('hRecs total:  '+hRecs);
					for(Hierarchy__c hr:hRecs){
						HierName.add(hr.Name); 
					}
					if((HierName.size() <= 1)){
		                  	resultobj.showBlockThree=false;
						if(HierName.size() == 1){
		                  	resultobj.showBlockThree=false;
							selectedHierarchyName = hRecs[0].name;
						}
						for(Hierarchy__c hr:hRecs){
							if(hr.CodeId__c != null){
								if(mObjectIds.containskey(util.getObjectNameFromId(Id.valueOf(hr.CodeId__c)))){
									mObjectIds.get(util.getObjectNameFromId(Id.valueOf(hr.CodeId__c))).add(Id.valueOf(hr.CodeId__c));
								}else{
									mObjectIds.put(util.getObjectNameFromId(Id.valueOf(hr.CodeId__c)), new set<Id>{Id.valueOf(hr.CodeId__c)});													
									
								}
							}
							if(hr.ParentCodeId__c != null){
								if(mObjectIds.containskey(util.getObjectNameFromId(Id.valueOf(hr.ParentCodeId__c)))){
									mObjectIds.get(util.getObjectNameFromId(Id.valueOf(hr.ParentCodeId__c))).add(Id.valueOf(hr.ParentCodeId__c));
								}else{
									mObjectIds.put(util.getObjectNameFromId(Id.valueOf(hr.ParentCodeId__c)), new set<Id>{Id.valueOf(hr.ParentCodeId__c)});													
									
								}
							}
						}
					
						for(string objName: mObjectIds.keyset()){
			                soql = new SOQLUtil(objName);
				            string str = string.join(new list<id> (mObjectIds.get(objName)),',');
				            list<string> strList = str.split(',');
				            list<string> Idset = new list<string>();
				            for(string s:strList){
				                string sid = '\'' + id.valueof(s) + '\'';
				                Idset.add(sid);
				                system.debug('sid: ' + sid);
				            }
				                system.debug('Idset: ' + Idset.size());
				                system.debug('Idset joined: ' + string.join(Idset,','));
				                string Idsetjoined = '('+ string.join(Idset,',') + ')';
				            whereClause = 'Id IN ' + Idsetjoined;
							
						    soql.addField('Id');
						    soql.addField('Name');
							soql.setWhereClause(whereClause);
							list<sObject> intermediateSobjectList = Database.query(soql.getQuery());
							if(intermediateSobjectList.size()>0 && intermediateSobjectList != null){
								sobjectList.addAll(intermediateSobjectList);
							}
							
						
						}
	                	system.debug('sobjectList:  '+sobjectList);
		                if(sobjectList.size()>=0){
		                  resultobj.ShowBlockThree=false;
		                  resultobj.ShowBlockTwo=true;
		                }
		                else{
						  resultobj.message = 'No records found for this Hierarchy Name,Hierarchy type and As Of Date combination. Please select segments to add new Hierarchy or change your filter criteria. ';
		                  resultobj.ShowBlockThree=false;
		                  resultobj.ShowBlockTwo=true;
		                }
	
		            }else{
							resultobj.message = 'More than one Hierarchy found for this Hierarchy Name,Segment type and As Of Date combination. Please selet one to continue or give new name to add new Hierarchy';
							resultobj.ShowBlockThree=true;
							resultobj.ShowBlockTwo=false;
		            	
		            }
             			            
                }else{
 		        	resultobj.ShowBlockThree=false;
		            resultobj.ShowBlockTwo=true;
                
                }
        	} 
					resultobj.sObjectListJSON=JSON.serialize(sobjectList);	
					return resultobj;
        }
        catch(Exception ex){
			resultobj.message = ex.getMessage()+ex.getLineNumber();
			return resultobj;
        }
    }


    @RemoteAction
    public static JsonResult FetchHierarchyList(string selectedHierarchyType){
		JsonResult Jresult = new JsonResult();
        //if(!selectedHierarchyType.contains('Cross') && selectedHierarchyType != null && selectedHierarchyType != '')
        	//selectedHierarchyType = util.getGlobalDescribe(selectedHierarchyType).getDescribe().getLabel();
	    SOQLUtil soql = new SOQLUtil('Hierarchy__c');
	    if(selectedHierarchyType != null && selectedHierarchyType != ''){
		    string whereClause = 'Type__c = ' + '\'' +selectedHierarchyType + '\''; 
			soql.setWhereClause(whereClause);
	    }               
	    soql.addAllFields();
		map<string,set<Id>> mObjectIds = new map<string,set<Id>>();
		set<string> HierName = new set<String>();
		system.debug('soql.getQuery():  '+ soql.getQuery());
		list<Hierarchy__c> hRecs = new list<Hierarchy__c>();
		hRecs = Database.query(soql.getQuery());
	    system.debug('hRecs:  '+hRecs);
    	map<string, set<string>> mHierarchyName = new map<string, set<string>>();
		for(Hierarchy__c hr:hRecs){
			//Hierarchy__c hrec= new Hierarchy__c(name=hr.name,type__c = hr.type__c);
			if(mHierarchyName.containskey(hr.name)){
				mHierarchyName.get(hr.name).add(hr.type__c);
			}else{
				mHierarchyName.put(hr.name, new set<string>{hr.type__c});													
				
			}
		}
		list<HierarchyWrapper> HierarchyWrapperlist=new list<HierarchyWrapper>();
		for(string hName:mHierarchyName.keyset()){
			set<string> hList = mHierarchyName.get(hName);
			for(string hrtype: hList){
				HierarchyWrapper HW = new HierarchyWrapper(hName, hrtype);
				HierarchyWrapperlist.add(HW);
			}
		}
		if(HierarchyWrapperlist != null && HierarchyWrapperlist.size()>0){
			Jresult.records = HierarchyWrapperlist;
			Jresult.total = HierarchyWrapperlist.size();
		}
		return Jresult ;
		    
    }
    @RemoteAction
    public static list<SelectListItem> getHierarchyTypeList(){
        list<segment_definition__c> segments = new list<segment_definition__c>();
        list<SelectListItem> segValPicklist = new list<SelectListItem>();
        SegmentService segObj = new SegmentService();
        segments = segObj.segments;
        segValPicklist.add(new SelectListItem('Select Segment Type','Select Segment Type'));       
        for(Schema.PicklistEntry SegmentType : util.getPickListEntriesFromField('Hierarchy__c','Type__c')){
          	//segValPicklist.add(new SelectListItem(SegmentType.getLabel(),SegmentType.getLabel()));       
        }
        for(segment_definition__c segment :segments){
        	String ObjAPIName = segment.Object_API_Name__c;
                system.debug('ObjAPIName:  ' +ObjAPIName);
        	if(!ObjAPIName.equalsIgnoreCase('Intercompany__c')){
	          	segValPicklist.add(new SelectListItem(ObjAPIName,util.getGlobalDescribe(ObjAPIName).getDescribe().getLabel()));
        	}       
        }
        return segValPicklist;
    }
    
    @remoteaction 
	public static EventResult addSegmentToTreelist(string SegRecsToBeInsertedJSON, string HierarchyName, string asofDateSer, string HierarchyType){
	
    	EventResult result = new EventResult();
	    if(HierarchyType != null && HierarchyType != '' && HierarchyType.contains('__c')){
        	HierarchyType = util.getGlobalDescribe(HierarchyType).getDescribe().getLabel();
        }
		list<Hierarchy__c> HirecsToBeInsertedList = new list<Hierarchy__c>();
		 try{	
 //           datetime asOfDate=(datetime)JSON.deserialize(asOfDateSer, Datetime.class);
			if(SegRecsToBeInsertedJSON != null && SegRecsToBeInsertedJSON != '' && HierarchyName != null && HierarchyName != ''){
				system.debug('SegRecsToBeInsertedJSON: ' + SegRecsToBeInsertedJSON);
	    		list<Id> SegRecsToBeInserted = (list<Id>)JSON.deserialize(SegRecsToBeInsertedJSON, list<Id>.class);
	        	Datetime asOfDate =(datetime)JSON.deserialize(asOfDateSer, Datetime.class);
		    	SOQLUtil soql = new SOQLUtil('Hierarchy__c');
				string whereClause = ' Start_DateTime__c >:asOfDate  AND End_DateTime__c = null AND Type__c =' + '\'' + HierarchyType + '\' AND Name = ' + '\'' + HierarchyName + '\''  ;
			    soql.addFields(new set<string>{'Id','Name'});
				soql.setWhereClause(whereClause);
				list<Hierarchy__c> hRecs = Database.query(soql.getQuery());
				system.debug('SegRecsToBeInserted: ' + SegRecsToBeInserted);
				for(Id SegId :SegRecsToBeInserted){
					Hierarchy__c hrRec =  new Hierarchy__c(Name = HierarchyName, Code__c = (string)SegId, Start_DateTime__c = asOfDate, type__c = HierarchyType);
					HirecsToBeInsertedList.add(hrRec);
				}
				if(HirecsToBeInsertedList != null && HirecsToBeInsertedList.size() >0)
					DML.insertAsSystem(HirecsToBeInsertedList);
			
				result.AllDone = true;
				result.segIdsAdded  = new list<Id>();
				result.segIdsAdded.addAll(SegRecsToBeInserted);
				result.Messages = 'Selected segments were added successfully to the Hierarchy';	
			}
			else if(HierarchyName == null || HierarchyName == ''){
				result.AllDone = false;
				result.Messages = 'Please enter Hierarchy Name.';		 
			
			}	
			else if(SegRecsToBeInsertedJSON == null || SegRecsToBeInsertedJSON == ''){
				result.AllDone = false;
				result.Messages = 'No segment value selected to be added to Hierarchy.';		 
			
			}	
		 }
		 catch(exception e){
			result.AllDone = false;
			result.Messages = e.getMessage();		 
		 }	
		 return result;					
	 
	}

    @remoteaction 
     public static JSONResult getFieldInfoList(string objectName,string fieldset,string sobjectlistser,string NamespaceUU) {
      system.debug('inside fieldinfo ****');
       try{
           list<FieldInfo> fieldInfoList = new list<fieldInfo>();
           if(!String.isBlank(objectName)){
               if(String.isBlank(sobjectListSER)){
                   throw new KendoTreeHierarchyException('Custom Exception:Must specify value for either objectName or sobjectList attributes.');    
               }
		   	   map<string,string> mFieldNameNSToFieldLabel = schemautil.getinstance().getFieldNamesMap(ObjectName);
	           if(fieldset!=null){
	             fieldInfoList = FieldInfo.fetchJsonFieldInfos(ObjectName, fieldset);         
	           }
	           else{ 
	             throw new KendoTreeHierarchyException('Custom Exception:Fieldset not defined in component');     	       		              
	           }
           //TODO:FieldInfo throws a exception if fieldsetmember is empty.Need to revisit the exception message in fieldInfo.
	           if(fieldInfoList.size()==0){
	              throw new KendoTreeHierarchyException('Custom Exception:Please enter fields in the HierarchyView fieldset');     	       		               
	           }
	           for (FieldInfo fi: fieldInfoList){
	               if(fi.field.contains('__c') ){
	                   //TODO:Check if we can modify FieldInfo to return with NS instead of stripping it.
	                   if(mFieldNameNSToFieldLabel.containskey(NamespaceUU + fi.field)){
	                      fi.field = NamespaceUU + fi.field;                      
	                   }
	                }
	                fi.field = 'HierRec.' + fi.field;
	           } 
               system.debug('fieldInfoList:    '+ fieldInfoList);
           	return new JSONResult(new list<string>{JSON.serialize(fieldInfoList)},1);         
           } else{
               list<FieldInfo> fieldListnew = new list<FieldInfo>();
               fieldListnew.add(new FieldInfo( 'HierRec.Name', 'Segment Value', 'String'));
               fieldListnew.add(new FieldInfo( 'HierRec.Id', 'Id', 'Id'));
                system.debug('fieldListnew:    '+ fieldListnew);
            return new JSONResult(new list<string>{JSON.serialize(fieldListnew)},1);         
           }

       }
       catch(Exception Ex){
          return throwError(Ex);
       }
           
    }   


    @RemoteAction
    public static list<SelectListItem> getSegmentValueList(String selectedHierarchy){
        list<segment_definition__c> segments = new list<segment_definition__c>();
        list<SelectListItem> segValPicklist = new list<SelectListItem>();
        SegmentService segObj = new SegmentService();
        segments = segObj.segments;
        segValPicklist.add(new SelectListItem('Select Segment','Select Segment'));       
        if(selectedHierarchy.contains('Cross')){
	        for(segment_definition__c segment :segments){
	        	String ObjAPIName = segment.Object_API_Name__c;
	        	if(!ObjAPIName.equalsIgnoreCase('Intercompany__c')){	        
	          		segValPicklist.add(new SelectListItem(segment.Object_API_Name__c,util.getGlobalDescribe(ObjAPIName).getDescribe().getLabel())); 
	        	}
	        }     
        }else{
	        for(segment_definition__c segment :segments){
	          	if(!segment.Object_API_Name__c.equalsIgnoreCase('Intercompany__c')){
		        	if(selectedHierarchy == util.getGlobalDescribe(segment.Object_API_Name__c).getDescribe().getLabel()){	        
		          		segValPicklist.add(new SelectListItem(segment.Object_API_Name__c,util.getGlobalDescribe(segment.Object_API_Name__c).getDescribe().getLabel())); 
		        	}
	          	}
	        }     
        	
        }

        return segValPicklist;
    }


    @RemoteAction
    public static JsonResult FetchSegmentList(string sobjectListSER,String ObjectName){
		JsonResult Jresult = new JsonResult();
		list<sObject> sobjectList = (list<sObject>)JSON.deserialize(sobjectListSER, list<sObject>.class);
		list<HierarchyWrapper> HierarchyWrapperlist=new list<HierarchyWrapper>();
 		system.debug('ObjectName:  ' + ObjectName);      
        string selectedSegment;
		try{
			if(ObjectName != 'Select Segment Type' && ObjectName != 'Cross Segment'){
	            if(ObjectName.contains('Company')){
	            	selectedSegment='Company__c';
	            }else{
	            	selectedSegment=ObjectName;}
				if(selectedSegment != null && selectedSegment != ''){               
		            SOQLUtil soql = new SOQLUtil(selectedSegment);
				    soql.addField('Id');			    
		 		    soql.addField('Name');	
					soql.setWhereClause('Id NOT IN :sobjectList ');
		            list<sobject> sobjects = Database.query(soql.getQuery());
		         
			        for(sobject sObj: sobjects){
			        	
						HierarchyWrapper HW = new HierarchyWrapper((string)sObj.get('Name'), util.getGlobalDescribe(selectedSegment).getDescribe().getLabel(), sObj.id);
						HierarchyWrapperlist.add(HW);
					}
				}
				if(HierarchyWrapperlist != null && HierarchyWrapperlist.size()>0){
					Jresult.records = HierarchyWrapperlist;
					Jresult.total = HierarchyWrapperlist.size();
					Jresult.message = '';
				}else{
					//Jresult.message = 'No More values of selected segment available. ';
					Jresult.total = HierarchyWrapperlist.size();
					Jresult.records = HierarchyWrapperlist;
				}
			}
			return Jresult ;
		}
			    
       catch(Exception Ex){
          return throwError(Ex);
       }
    }


    
    
    @remoteaction
    public static jsonresult treeListRead( string asOfDateSer, string asOfDateNewSer , String ObjectName , string fieldset ,string whereclause,string sobjectListSER,string HierField,string HierarchyType,string HierarchyName)
    {
	            system.debug('in treeListRead: ' );
        try{
            //if(!HierarchyType.contains('Cross'))
        		//HierarchyType = util.getGlobalDescribe(HierarchyType).getDescribe().getLabel();
	        if(HierarchyType != null && HierarchyType != '' && HierarchyType.contains('__c')){
	        	HierarchyType = util.getGlobalDescribe(HierarchyType).getDescribe().getLabel();
	        }
            String querystring;
            Datetime asOfdATE;
            Datetime asOfDateNew;
            list<sobject> sobjectList = new list<sobject>();
            map<id,sobject>  mSobjects  = new map<id,sobject>();

            list<HierarchyResultWrapper> resultList = new list<HierarchyResultWrapper>();
            HierarchyResult HierResultObj ;
            
            //Check if sObjectList or objectName is passed as attribute value.
            if(!String.isBlank(sobjectListSer)){
              	sobjectlist = (list<sobject>)JSON.deserialize(sobjectListSER, list<sobject>.class);
   				system.debug('sobjectlist in treelist read' + sobjectlist);
              	mSobjects= new map<id,sobject>(sobjectlist); 
	            system.debug('mSobjects: ' + mSobjects);
	            system.debug('mSobjects: ' + mSobjects.size());
            }
            else{
                if(String.isBlank(objectName)){
             		throw new KendoTreeHierarchyException('Custom Exception:Must specify values for either objectName or sobjectList attribute on kendoTreeList Component.');     	       		              
                }
                else{
                	
				    SOQLUtil soql = new SOQLUtil(ObjectName);
				    soql.addFields(fieldset);
				    //soql.setWhereClause(whereClause);
				    
                    if(!String.isBlank(HierField)){
                    	soql.addField(HierField);
                    }
                    else{
                    } 
                    
                    mSobjects = new map<id,sobject>(Database.query(soql.getQuery()));
                    system.debug('mSobjects in tree list read: ' + mSobjects);
                    system.debug('mSobjects size in tree list read: ' + mSobjects.size());
                    if(mSobjects.size()==0){             
             		   throw new KendoTreeHierarchyException('Custom Exception:No records found for the segment type.');     	       		                                  
                    }                    
                }       
            }
            //Check if either Hierfield or asOfDate attribute values are passed
            //These are parameters to call HierarchyService.
            if(!String.isBlank(HierField)){
                HierResultObj  = HierarchyService.buildHierarchy(mSobjects,HierField);

            }
            else{
                if(String.isBlank(asOfDateSer)){
             		throw new KendoTreeHierarchyException('Custom Exception:Must specify value for asOfDate if HierField attribute is not specified .');     	       		              
                }
                asOfDate=(datetime)JSON.deserialize(asOfDateSer, Datetime.class);
                if(asOfDateNewSer != null && asOfDateNewSer!= ''){
                	asOfDateNew=(datetime)JSON.deserialize(asOfDateNewSer, Datetime.class);
                }
             	system.debug('asOfDate here: ' + asOfDate);
             	if(HierarchyType != null && HierarchyName != null)
              		if(asOfDateNew != null)
                		HierResultObj  = HierarchyService.buildHierarchy(mSobjects,asOfDateNew,HierarchyType,HierarchyName);
                	else
                		HierResultObj  = HierarchyService.buildHierarchy(mSobjects,asOfDate,HierarchyType,HierarchyName);
                	
            }
             system.debug('HierResultObj: ' + HierResultObj);
             system.debug('HierResultObj.getChildNodes: ' + HierResultObj.getChildNodes('a0e36000000BSIvAAO'));
             if(asOfDateNew != null)
             	resultList = buildSobjectsForTreelist(HierResultObj,mSobjects,asOfDateNew);
             else
             	resultList = buildSobjectsForTreelist(HierResultObj,mSobjects,asOfdATE);
             return new JSONResult(resultList,resultList.size());           
        }
        catch(Exception ex){
            return throwError(ex);
        }

         
    } 
    
    public static list<HierarchyResultWrapper> buildSobjectsForTreelist(HierarchyResult HierResultObj,map<id,sobject> mSobjects,datetime asOfdATE){
        list<HierarchyResultWrapper> wrapperList = new list<HierarchyResultWrapper>();
        for(ID ChildId:HierResultObj.mChildParent.keyset()){
            HierarchyResultWrapper wrapperObj = new HierarchyResultWrapper();
            wrapperObj.HierRec = mSobjects.get(ChildId);
            wrapperObj.parentIdHier   = HierResultObj.mChildParent.get(ChildId) ; 
            wrapperObj.SegmentName = util.getSObjectType(wrapperObj.HierRec.Id).getDescribe().getLabel();
            wrapperList.add(wrapperObj);
            
        }
        for(id rootId:HierResultobj.rootNodes.values()){
            HierarchyResultWrapper wrapperObj = new HierarchyResultWrapper();
            wrapperObj.HierRec = mSobjects.get(rootId);
            wrapperObj.parentIdHier   = null ; 
            wrapperObj.SegmentName = util.getSObjectType(wrapperObj.HierRec.Id).getDescribe().getLabel();
            wrapperList.add(wrapperObj);          
        }
        //Check for any records without Hierarchy defined.
        //Assuming the otherway matching viz if anything is defined in hierarchy exists in DB/msobjects as we dont provide whereclause handling.
        string SFDCBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        set<id> sobjectIds = new set<id>(mSobjects.keyset());
        set<id> sobjectWithHierIds = new set<Id>(HierResultObj.mChildParent.keyset());
        sobjectWithHierIds.addAll(HierResultObj.rootNodes.values());
        
        if(!sobjectWithHierIds.containsAll(sobjectIds)){
            sobjectIds.removeAll(sobjectWithHierIds);
            string ErrorMsg = 'The following  segments do not have a relationship defined in the Hierarchy object. ';
            list<string> ErrorRuleLinks = new list<string>();
            //Check if they are any sobjects with outdated hier recs.
            list<hierarchy__c> sobjectsWithOutdatedHier = [select id,name,parentcodeId__c,codeId__c from hierarchy__c 
                                                           where (codeId__c in :sobjectIds or parentcodeId__c in :sobjectIds )                                                           
                                                           and (End_DateTime__c<=:asOfdATE  or start_dateTime__c>:asOfdATE)];
            System.debug('sobjectsWithOutdatedHier --' +sobjectsWithOutdatedHier);
            for(hierarchy__c OutdatedHier :sobjectsWithOutdatedHier){
                if(sobjectIds.contains(OutdatedHier.codeId__c)){//Multiple occurences of the id for various outdated ranges will also get filtered here
                   sobjectIds.remove(OutdatedHier.codeId__c) ;
                   System.debug('OutdatedHier.code__c --' +OutdatedHier.codeId__c);
                }
                else if(sobjectIds.contains(OutdatedHier.parentcodeId__c)){
                   sobjectIds.remove(OutdatedHier.parentcodeId__c) ; 
                    System.debug('OutdatedHier.parent_code__c --' +OutdatedHier.parentcodeId__c);
                  
                }
                    
            }
            for(Id sobjWithoutHierId:sobjectIds)
            {
                
                ErrorRuleLinks.add(' <a href=\''+SFDCBaseURL+'/'+sobjWithoutHierId+'\'>' + msobjects.get(sobjWithoutHierId).get('name') +' </a>');
                
            }
            ErrorMsg = ErrorMsg+String.join(ErrorRuleLinks,',')+ '.';
            
            HierarchyResultWrapper wrapperObj = new HierarchyResultWrapper();
            wrapperObj.HierRec = null;
            wrapperObj.parentIdHier   = null ; 
            wrapperobj.isInvalid=true;
            wrapperObj.Message=ErrorMsg;
            wrapperList.add(wrapperObj);               
        }        
        system.debug('wrapperList '+wrapperList);
        return wrapperList;
    }
    
    public static JSONResult throwError(Exception Ex){
        JSONResult JSONResultObj = new JSONResult();
        JSONResultObj.hasExceptions= true;
        if(ex.getMessage().contains('Custom Exception:')){
         JSONResultObj.message =  ex.getMessage().remove('Custom Exception:') ;           
        }
        else{
         JSONResultObj.message = 'Error ' + ex.getMessage() + ' on ' + ex.getLineNumber();
        }
        JSONResultObj.records = new list<object>();
        return JSONResultObj ;
    }
    public class HierarchyResultWrapper{
        sobject HierRec;
        Id  parentIdHier;
        string SegmentName;
        @testvisible
        Boolean isInvalid;
        @testvisible
        String Message;
    }

    public class SegmentResultWrapper{
        sobject SegRec;
        Id  parentIdSeg;
        string SegmentName;
        @testvisible
        Boolean isInvalid;
        @testvisible
        String Message;
    }
    


/*    @remoteaction 
    public static EventResult EventUpdate(string HierRecSer,Id HierRecSerId) {
    	EventResult result = new EventResult();
    	sObject sobj;
    	type t = type.forname(string.valueOf(util.getSObjectType(HierRecSerId)));
        sObj = (sObject)json.deserialize(HierRecSer, t);
		Try{
        	if(sObj != null){
        		DML.updateAsUser(sObj);
				result.AllDone=true;
        	}else{
				result.AllDone=false;        	
        	}
        	
		}
		Catch(exception e){
			result.Messages = e.getMessage();
    		system.debug('result.Messages: ' + result.Messages);
			result.AllDone=false;
		
		}
    	system.debug('sObj: ' + sObj);
    	return result;
    }*/
    
    public class EventResult
    {
        Boolean AllDone=false;
        Boolean FoundPastHirec=false;
        Boolean FoundFutureHirec=false;
        Boolean FoundHirec=false;
        string Messages='';
		list<hierarchy__c> HierarchyRecToBeInserted = new list<hierarchy__c>();
		list<hierarchy__c> HierarchyRecToBeUpdated = new list<hierarchy__c>();
        datetime asofdatenew;
        string asofdatenewSer;
		list<Id> segIdsAdded;
		
        
    }
    @remoteaction 
    public static EventResult CheckHierarchyExists(string HierarchyName,string HierarchyType,string asOfDateSer) {
     	EventResult result = new EventResult();
		try{
        	if(HierarchyName != null && HierarchyName != '' && HierarchyType != null && HierarchyType != '' && asOfDateSer != null && asOfDateSer != ''){
	        	Datetime asOfDate =(datetime)JSON.deserialize(asOfDateSer, Datetime.class);
		    	SOQLUtil soql = new SOQLUtil('Hierarchy__c');
				string whereClause = ' (Start_DateTime__c <=:asOfDate OR Start_DateTime__c >:asOfDate)  AND (End_DateTime__c >: asOfDate  OR End_DateTime__c = null) AND Type__c =' + '\'' + HierarchyType + '\' AND Name = ' + '\'' + HierarchyName + '\''  ;
			    soql.addFields(new set<string>{'Id','Name','Start_DateTime__c'});
				soql.setWhereClause(whereClause);
				list<Hierarchy__c> hRecs = Database.query(soql.getQuery());
				system.debug('hRecs here: ' + hRecs);
				if(hRecs.size()>0){
        			result.FoundHirec=true;
					for(Hierarchy__c hr: hRecs){
						if(hr.Start_DateTime__c <=asOfDate){
							result.FoundPastHirec = true;
							result.FoundFutureHirec = false;
							break;
						}else{
							result.FoundPastHirec = false;
							result.FoundFutureHirec = true;
							break;
						
						}
						
					}
				}					
				else
					result.FoundHirec = false;
        	}else{
				result.FoundHirec = false;
        	
        	}
				result.AllDone = true;
		}
		catch(exception e){
			result.Messages = e.getMessage();
			result.AllDone=false;
		
		}
			
    	return result;
    }

    @remoteaction 
    public static EventResult EventDeleteRow(string asOfDateSer, string HierRecSer,Id HierRecSerId,string HierarchyType,string HierarchyName,string sobjectListSER, list<id> IdList) {
 	    		system.debug('IdList: ' + IdList);
    	
    	EventResult result = new EventResult();
 	    result.HierarchyRecToBeUpdated = new list<hierarchy__c>();
        HierarchyResult HierResultObj ;
        list<sobject> sobjectList = new list<sobject>();
        map<id,sobject>  mSobjects  = new map<id,sobject>();
        Datetime asOfDate =(datetime)JSON.deserialize(asOfDateSer, Datetime.class);
     	if(HierarchyType != null && HierarchyName != null && !String.isBlank(sobjectListSer)){
        	HierResultObj  = HierarchyService.buildHierarchy(mSobjects,asOfDate,HierarchyType,HierarchyName);
		    if(HierarchyType != null && HierarchyType != '' && HierarchyType.contains('__c')){
	        	HierarchyType = util.getGlobalDescribe(HierarchyType).getDescribe().getLabel();
	        }
          	sobjectlist = (list<sobject>)JSON.deserialize(sobjectListSER, list<sobject>.class);
          	mSobjects= new map<id,sobject>(sobjectlist);
            HierResultObj  = HierarchyService.buildHierarchy(mSobjects,asOfDate,HierarchyType,HierarchyName);
          	 
/*	        SOQLUtil soql = new SOQLUtil('Hierarchy__c');
			string whereClause = '(codeId__c = ' + '\'' + HierRecSerId + '\'  OR ParentCodeId__c = \'' + HierRecSerId + '\')'  
								+ ' AND Start_DateTime__c <=:asOfDate  AND (End_DateTime__c >: asOfDate  OR End_DateTime__c = null)'  ;
		    if(HierarchyType!= null){
		    	WhereClause += ' AND Type__c =' + '\'' + HierarchyType + '\'' ;
		    }
		    if(HierarchyName!= null){
		    	WhereClause += ' AND Name like ' + '\'%' + HierarchyName + '%\'';
		    }
	    
		    soql.addAllFields();
			soql.setWhereClause(whereClause);
			list<Hierarchy__c> hRecs = Database.query(soql.getQuery());
			list <id> pCodelistnew = new list<Id>();
			pCodelist.add(HierRecSerId);
			list<node> childnodelislnew = new list<node>();		
			list<node> childnodelist = HierResultObj.getChildNodes(HierRecSerId);
			
			integer initialcounter = 0;
			integer lmt = 4;
 			childnodelislnew.addall(childnodelist);
			for(integer i=0; i<lmt; i++){
				childnodelislnew.addAll(SegmentHierarchyViewManageExt.forloopfunction(childnodelislnew.size(),childnodelislnew));
	    		system.debug('childnodelislnew: ' + childnodelislnew);
				
			}
			pCodelist.add(HierRecSerId);
			for(node nd:childnodelislnew){
				pCodelist.add(nd.id);
			}
*/			IdList.add(HierRecSerId);
	    	SOQLUtil soql = new SOQLUtil('Hierarchy__c');
		    string str = string.join(IdList,',');
		    list<string> strList = str.split(',');
		    list<string> Idset = new list<string>();
		    for(string s:strList){
		        string sid = '\'' + id.valueof(s) + '\'';
		        Idset.add(sid);
		        system.debug('sid: ' + sid);
		    }
	        system.debug('Idset: ' + Idset.size());
	        system.debug('Idset joined: ' + string.join(Idset,','));
	        string Idsetjoined = '('+ string.join(Idset,',') + ')';
			string whereClause = 'CodeId__c IN ' + Idsetjoined  
								+ ' AND Start_DateTime__c <=:asOfDate  AND (End_DateTime__c >: asOfDate  OR End_DateTime__c = null)'  ;
		    if(HierarchyType!= null){
		    	WhereClause += ' AND Type__c =' + '\'' + HierarchyType + '\'' ;
		    }
		    if(HierarchyName!= null){
		    	WhereClause += ' AND Name like ' + '\'%' + HierarchyName + '%\'';
		    }
		    
		    soql.addAllFields();
			soql.setWhereClause(whereClause);
			list<Hierarchy__c> hRecs = Database.query(soql.getQuery());
			//if(hRecsextra != null && hRecsextra.size()> 0)
			//hrecs.addall(hRecsextra);
	    	system.debug('hRecs now:  ' + hRecs.size());
			Try{
				if(hRecs.size()>1){
					//result.Messages = 'All the child segments of this segment wiil be removed from hierarchy. To continue click save changes or to Cancel click Cancel changes';
				}
				for(Hierarchy__c hr:hRecs){
					if(hr.Start_DateTime__c >= asOfDate)
						hr.End_DateTime__c = hr.Start_DateTime__c;
					else
						hr.End_DateTime__c = asOfDate;
				}
			if(hRecs != null && hRecs.size() >0){
				//result.HierarchyRecToBeUpdated.addAll(hRecs);
			}
	    	system.debug('result.HierarchyRecToBeUpdated:  ' + result.HierarchyRecToBeUpdated);
			DML.updateAsUser(hRecs);
			result.AllDone=true;
	    	result.asofdatenew = asOfDate;
	    	result.asofdatenewSer = JSON.serialize(result.asofdatenew);
	    	if(result.Messages== null || result.Messages == '')
				result.Messages = 'Selected segment value was removed from hierarchy successfully.';
	    	system.debug('result.asofdatenew:  ' + string.valueOf(result.asofdatenew));
			}
			Catch(exception e){
				result.Messages = e.getMessage();
	    		system.debug('result.Messages: ' + result.Messages);
				result.AllDone=false;
			
			}
     	}else{
			result.Messages = 'Error occurred while deleting Hierarchy records. Please try again';
			result.AllDone=false;
     	}
    	return result;
    }
    
    public static list<node> forloopfunction(integer size, list<node> nodeslist){
		list <node> tempnodelist = new list<node>();
		for(integer i=0; i<size; i++){
			if(nodeslist[i].nodes.size()>=1){
				tempnodelist.addAll(nodeslist[i].nodes);
			}
		}
		return   tempnodelist;
    }
    
    @remoteaction 
    public static EventResult EventDragAndDrop(string asOfDateSer,string HierRecSourceSer, Id HierRecSourceSerId, string HierRecDestinationSer, Id HierRecDestinationSerId,string HierarchyType,string HierarchyName) {
     	list<Hierarchy__c> HirecsToBeInserted =new list <Hierarchy__c> ();
	    if(HierarchyType != null && HierarchyType != '' && HierarchyType.contains('__c')){
        	HierarchyType = util.getGlobalDescribe(HierarchyType).getDescribe().getLabel();
        }
    	EventResult result = new EventResult();
    	result.HierarchyRecToBeInserted = new list<hierarchy__c>();
     	result.HierarchyRecToBeUpdated = new list<hierarchy__c>();
    	sObject sobjSource;
    	sObject sobjDestination;

        if(HierRecSourceSerId != null && HierRecDestinationSerId != null){
        	if(util.getSObjectType(HierRecSourceSerId) == company__c.getSObjectType()){
        		if(HierRecDestinationSerId != null  && util.getSObjectType(HierRecDestinationSerId) != company__c.getSObjectType())	{
        			result.AllDone = false;
 					result.Messages = 'Company Segment Value can be child of only company segment value.';
        		
        		}
        	
        	}
        }
        if(result.Messages == null || result.Messages == ''){
	        Datetime asOfDate =(datetime)JSON.deserialize(asOfDateSer, Datetime.class);
            //if(!HierarchyType.contains('Cross'))
        		//HierarchyType = util.getGlobalDescribe(HierarchyType).getDescribe().getLabel();
	        SOQLUtil soql = new SOQLUtil('Hierarchy__c');
			string whereClause = '(codeId__c = ' + '\'' + HierRecSourceSer + '\'  AND ParentCodeId__c = \'' + HierRecDestinationSer + '\')'  
								+ ' AND Start_DateTime__c <=:asOfDate  AND (End_DateTime__c >: asOfDate  OR End_DateTime__c = null)'  ;
		    	system.debug('HierarchyType: ' + HierarchyType);
		    if(HierarchyType!= null){
		    	WhereClause += ' AND Type__c =' + '\'' + HierarchyType + '\'' ;
		    }
		    if(HierarchyName!= null){
		    	WhereClause += ' AND Name like ' + '\'%' + HierarchyName + '%\'';
		    }
		    
		    soql.addFields(new set<string>{'Id','Name','End_DateTime__c','Start_DateTime__c','codeId__c','ParentCodeId__c'});
			soql.setWhereClause(whereClause);
			list<Hierarchy__c> hRecsOld = Database.query(soql.getQuery());
			
	     	if((hRecsOld==null) || (hRecsOld.size()==0)){   	
	    	
	    	
		    	//HirecsToBeInserted = new list <Hierarchy__c> ();
		    	type t = type.forname(string.valueOf(util.getSObjectType(HierRecSourceSerId)));
		        sobjSource = (sObject)json.deserialize(HierRecSourceSer, t);
		        if(HierRecDestinationSerId != null && string.valueOf(HierRecDestinationSerId).length() != 0){
			    	t = type.forname(string.valueOf(util.getSObjectType(HierRecDestinationSerId)));
		        	sobjDestination = (sObject)json.deserialize(HierRecDestinationSer, t);
		        
		        }
		    	system.debug('sobjSource: ' + sobjSource);
		    	system.debug('sobjDestination: ' + sobjDestination);
		    	
		        soql = new SOQLUtil('Hierarchy__c');
				whereClause = 'codeId__c = ' + '\'' + HierRecSourceSerId + '\'' ;
			    if(HierarchyType!= null){
			    	WhereClause += ' AND Type__c =' + '\'' + HierarchyType + '\'' ;
			    }
			    if(HierarchyName!= null){
			    	WhereClause += ' AND Name like ' + '\'%' + HierarchyName + '%\'';
			    }
			    
			    soql.addAllFields();
				soql.setWhereClause(whereClause);
				list<Hierarchy__c> hRecs = Database.query(soql.getQuery());
		    	
		    	for(Hierarchy__c hr: hRecs){
			    	
			    	Hierarchy__c hrNew = new Hierarchy__c();
			    	if(sobjDestination != null){
			    		if(sobjDestination.id != hr.ParentCodeId__c){
			    	system.debug('in if ');
		
			    			hrNew = hr.clone(false,true);
			    			system.debug('hrnew: ' + hrnew);
			    			hrnew.Start_DateTime__c = asOfDate;
			    			hrnew.Parent_Code__c = sobjDestination.id;
			    			hr.end_dateTime__c = asOfDate;
			    			HirecsToBeInserted.add(hrnew);
			    		}
			    	}else if(hr.ParentCodeId__c != null){
			    			system.debug('in else ');
			    			hrnew.Start_DateTime__c = asOfDate;
			    			hrNew = hr.clone(false,true);
			    			hrNew.Parent_Code__c = null;
			    			hr.end_dateTime__c = asOfDate;
			    			HirecsToBeInserted.add(hrnew);
			    			}
			    	system.debug('hrnew.Code__c: ' + hrnew.Code__c);
			    	system.debug('hrnew.Parent_Code__c: ' + hrnew.Parent_Code__c);
		    	}
		    	
				Try{
			    	system.debug('HirecsToBeInserted: ' + HirecsToBeInserted);
			    	system.debug('hRecs: ' + hRecs);
					if(HirecsToBeInserted != null && HirecsToBeInserted.size() >0){
						result.HierarchyRecToBeInserted.addAll(HirecsToBeInserted);
						result.HierarchyRecToBeUpdated.addAll(hRecs);
					}
					result.Messages = 'Changes made to the hierarchy temporarily. Click save to save the changes permanently or cancel to cancel changes.';
					result.AllDone=true;
				}
				Catch(exception e){
					result.Messages = e.getMessage();
		    		system.debug('result.Messages: ' + result.Messages);
					result.AllDone=false;
				
				}
	     	}else{
		    		system.debug('result.Messages: ' + result.Messages);
					result.AllDone=true;
	     	}
        }
    	return result;
    }
    
    
    @remoteaction 
	public static EventResult DeleteHierarchy(string HierarchyName,string HierarchyType, string asOfDateSer){
    	EventResult result = new EventResult();
	    if(HierarchyType != null && HierarchyType != '' && HierarchyType.contains('__c')){
        	HierarchyType = util.getGlobalDescribe(HierarchyType).getDescribe().getLabel();
        }
		if(HierarchyName == null || HierarchyType == null || HierarchyName == '' || HierarchyType == ''){
			result.Messages = 'Either Hierarchy Name or Segment Type is missing';
			result.AllDone = false;
		}else{
			try{
		     	result.HierarchyRecToBeUpdated = new list<hierarchy__c>();
		        Datetime asOfDate =(datetime)JSON.deserialize(asOfDateSer, Datetime.class);
		        SOQLUtil soql = new SOQLUtil('Hierarchy__c');
				string whereClause;//	=  ' Start_DateTime__c <=:asOfDate  AND (End_DateTime__c >: asOfDate  OR End_DateTime__c = null)'  ;
			    if(HierarchyType!= null){
			    	WhereClause = ' Type__c =' + '\'' + HierarchyType + '\'  AND Name = ' + '\'' + HierarchyName + '\'';
			    }
			    
			    soql.addAllFields();
				soql.setWhereClause(whereClause);
				list<Hierarchy__c> hRecs = Database.query(soql.getQuery());
				if(hRecs != null && hRecs.size() >0){
					DML.deleteAsUser(hRecs);
				}
				result.AllDone=true;
		    	if(result.Messages== null || result.Messages == '')
					result.Messages = 'Hierarchy Records Deleted Successfully.';
			
			
			}
			catch(exception e){
				result.Messages = e.getMessage();
	    		system.debug('result.Messages: ' + result.Messages);
				result.AllDone=false;
			
			}		
		}
		return result;
	}
    
    @remoteaction 
	public static EventResult SaveResult(string HirecsToBeInsertedJSON, string HirecsToBeUpdatedJSON){
    	EventResult result = new EventResult();
		list<Hierarchy__c> HirecsToBeInsertedList = new list<Hierarchy__c>();
		list<Hierarchy__c> HirecsToBeUpdatedList = new list<Hierarchy__c>();
		 try{	
			if(HirecsToBeInsertedJSON != null && HirecsToBeInsertedJSON != '' && !string.isBlank(HirecsToBeInsertedJSON) ){
				system.debug('HirecsToBeInsertedJSON: ' + HirecsToBeInsertedJSON);
	    		list<list<Hierarchy__c>> HirecsToBeInserted = (list<list<Hierarchy__c>>)JSON.deserialize(HirecsToBeInsertedJSON, list<list<Hierarchy__c>>.class);
				for(list<Hierarchy__c> hrlist :HirecsToBeInserted){
					HirecsToBeInsertedList.addAll(hrlist);
				}
				system.debug('HirecsToBeInserted: ' + HirecsToBeInserted);
				if(HirecsToBeInsertedList != null && HirecsToBeInsertedList.size() >0)
					DML.insertAsSystem(HirecsToBeInsertedList);
		
			
				if(HirecsToBeUpdatedJSON != null && HirecsToBeUpdatedJSON != ''){
		 			system.debug('HirecsToBeUpdatedJSON: ' + HirecsToBeUpdatedJSON);
		    		list<list<Hierarchy__c>> HirecsToBeUpdated = (list<list<Hierarchy__c>>)JSON.deserialize(HirecsToBeUpdatedJSON, list<list<Hierarchy__c>>.class);
					for(list<Hierarchy__c> hrlist :HirecsToBeUpdated){
						HirecsToBeUpdatedList.addAll(hrlist);
					}
					system.debug('HirecsToBeUpdated: ' + HirecsToBeUpdated);
					if(HirecsToBeUpdatedList != null && HirecsToBeUpdatedList.size() >0)
						DML.updateAsSystem(HirecsToBeUpdatedList);
					
				}	
				result.AllDone = true;
				result.Messages = 'Change were saved successfully';	
			}	
			else if(HirecsToBeInsertedJSON == null || HirecsToBeInsertedJSON == '' || HirecsToBeInsertedJSON.length()==0){
				result.AllDone = false;
				result.Messages = 'No changes to save.';		 
			
			}	
		 }
		 catch(exception e){
			result.Messages = e.getMessage();		 
		 }	
		 return result;
	}


    public String getHierarchyFieldList() {
        if (String.isBlank(hierarchyFieldList)) {
            // get the credit memo field info list
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();
            FieldInfo selectFieldInfoItem = new FieldInfo();
            selectFieldInfoItem.field = 'HierarchyName';
            selectFieldInfoItem.title = 'Hierarchy Name';
            selectFieldInfoItem.fieldtype = 'String';
            selectFieldInfoItem.filterable=true;
            fieldInfoList.add(selectFieldInfoItem);

            FieldInfo selectFieldInfoItem1 = new FieldInfo();
            selectFieldInfoItem1.field = 'SegmentType';
            selectFieldInfoItem1.title = 'Segment Type';
            selectFieldInfoItem1.fieldtype = 'String';
            selectFieldInfoItem.filterable=true;
            fieldInfoList.add(selectFieldInfoItem1);
                
            HierarchyFieldList = JSON.serialize(fieldInfoList);
            }
            
        
        return HierarchyFieldList;
    }

    public String getsegmentFieldList() {
        if (String.isBlank(SegmentFieldList)) {
            // get the credit memo field info list
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();
            FieldInfo selectFieldInfoItem = new FieldInfo();
            selectFieldInfoItem.field = 'HierarchyName';
            selectFieldInfoItem.title = 'Segment Value';
            selectFieldInfoItem.fieldtype = 'String';
            selectFieldInfoItem.filterable=true;
            fieldInfoList.add(selectFieldInfoItem);

            /*FieldInfo selectFieldInfoItem1 = new FieldInfo();
            selectFieldInfoItem1.field = 'SegmentType';
            selectFieldInfoItem1.title = 'Segment Type';
            selectFieldInfoItem1.fieldtype = 'String';
            selectFieldInfoItem.filterable=true;
            fieldInfoList.add(selectFieldInfoItem1);*/
                
            SegmentFieldList = JSON.serialize(fieldInfoList);
            }
            
        
        return SegmentFieldList;
    }
}