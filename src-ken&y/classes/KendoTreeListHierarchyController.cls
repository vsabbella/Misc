public with sharing class KendoTreeListHierarchyController extends baseController
{
    public string NamespaceUU { get { return KSE.NamespaceUU; }} 
    public static SchemaUtil util = SchemaUtil.getInstance();
     
    public string fieldList = null;
    public List<FieldInfo> fieldInfoList;
    public string CompHierarchyType { get; set; }
    public string AsOfDateSer{get;set;}
    public string CompObjectName{get;set;}
    public string CompFieldset{get;set;} 
    public string CompWhereClause{get;set;}     
    public string CompButtons{get;set;}
    public string compSobjectListSer{get;set;}
    public string compHierField{get;set;}
    
	public class KendoTreeHierarchyException extends Exception{}

    

    public KendoTreeListHierarchyController() {
        system.debug('The attribute values will not be loaded here as order of executin is constructor->getter-->setter Eg:-'+'CompFieldset:'+CompFieldset);
    }
    

    @remoteaction 
     public static JSONResult getFieldInfoList(string objectName,string fieldset,string sobjectlistser,string NamespaceUU) {
      
       try{
           if(String.isBlank(objectName)){
               if(String.isBlank(sobjectListSER)){
                   throw new KendoTreeHierarchyException('Custom Exception:Must specify value for either objectName or sobjectList attributes.');    
               }
               else{
                   list<sobject>  sobjectlist = (list<sobject>)JSON.deserialize(sobjectListSER, list<sobject>.class);
                   objectName=schemautil.getinstance().getLocalNameFromObject(sobjectlist[0]);//Expecting atleast 1 rec.If one or more tables are part of the sobjectlist using the first sobject API as it is just field reference.
               }
           }
           list<FieldInfo> fieldInfoList = new list<fieldInfo>();
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
           return new JSONResult(new list<string>{JSON.serialize(fieldInfoList)},1);         
       }
       catch(Exception Ex){
          return throwError(Ex);
       }
           
    }   
    
    
    
    @remoteaction
    public static jsonresult treeListRead( string asOfDateSer , String ObjectName , string fieldset ,string whereclause,string sobjectListSER,string HierField)
    {
        try{
            String querystring;
            Datetime asOfdATE;
            list<sobject> sobjectList = new list<sobject>();
            map<id,sobject>  mSobjects  = new map<id,sobject>();

            list<HierarchyResultWrapper> resultList = new list<HierarchyResultWrapper>();
            HierarchyResult HierResultObj ;
            
            //Check if sObjectList or objectName is passed as attribute value.
            //If objectName - Construct querystring and get mSobjects 
            if(!String.isBlank(sobjectListSer)){
              system.debug('sobjectListSer'+sobjectListSer);
              sobjectlist = (list<sobject>)JSON.deserialize(sobjectListSER, list<sobject>.class);
              mSobjects= new map<id,sobject>(sobjectlist); 
              system.debug('sobjectlist'+sobjectlist);
            }
            else{
                if(String.isBlank(objectName)){
             		throw new KendoTreeHierarchyException('Custom Exception:Must specify values for either objectName or sobjectList attribute on kendoTreeList Component.');     	       		              
                }
                else{
                	
				    SOQLUtil soql = new SOQLUtil(ObjectName);
				    soql.addFields(fieldset);
				    soql.setWhereClause(whereClause);
				    
                    if(!String.isBlank(HierField)){
                    	soql.addField(HierField);
                        //querystring = schemautil.getinstance().generateQueryFromFieldSet(ObjectName,new set<String>{fieldset},new set<string>{HierField},whereclause);
                    }
                    else{
                        //querystring = schemautil.getinstance().generateQueryFromFieldSet(ObjectName,new set<String>{fieldset},null,whereclause);
                    } 
                    
                    mSobjects = new map<id,sobject>(Database.query(soql.getQuery()));
                    
                    if(mSobjects.size()==0){             
             		   throw new KendoTreeHierarchyException('Custom Exception:No records found for the segment type.');     	       		                                  
                    }                    
                }       
            }
            //Check if either Hierfield or asOfDate attribute values are passed
            //These are parameters to call HierarchyService.
            if(!String.isBlank(HierField)){
                /*system.debug('JSON '+JSON.serialize(mSobjects.values()[0]));
                if(!JSON.serialize(mSobjects.values()[0]).contains(HierField) && !JSON.serialize(mSobjects.values()[0]).contains(KSE.NameSpaceUU+HierField) ){
                   throw new KendoTreeHierarchyException('Must query Hierarchy Field '+HierField+ ' as part of sobjectList attribute value.');     	       		                               
                }*/
                HierResultObj  = HierarchyService.buildHierarchy(mSobjects,HierField);

            }
            else{
                if(String.isBlank(asOfDateSer)){
             		throw new KendoTreeHierarchyException('Custom Exception:Must specify value for asOfDate if HierField attribute is not specified .');     	       		              
                }
                asOfDate=(datetime)JSON.deserialize(asOfDateSer, Datetime.class);
                HierResultObj  = HierarchyService.buildHierarchy(mSobjects,asOfDate);
            }
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
            wrapperList.add(wrapperObj);
        }
        for(id rootId:HierResultobj.rootNodes.values()){
            HierarchyResultWrapper wrapperObj = new HierarchyResultWrapper();
            wrapperObj.HierRec = mSobjects.get(rootId);
            wrapperObj.parentIdHier   = null ; 
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
          
            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('hierarchy__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','name','parentcodeId__c','codeId__c'
            });
            soql.setWhereClause('(codeId__c in :sobjectIds or parentcodeId__c in :sobjectIds ) and (End_DateTime__c<=:asOfdATE or start_dateTime__c>:asOfdATE)');
            list<hierarchy__c> sobjectsWithOutdatedHier = Database.query(soql.getQuery());



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
        @testvisible
        Boolean isInvalid;
        @testvisible
        String Message;
    }
    


}