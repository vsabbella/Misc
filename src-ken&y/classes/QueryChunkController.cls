global with sharing class QueryChunkController {

    Public string NameSpaceUU{get{
    return  KSE.NamespaceUU;}set;} 

	public class QueryException extends Exception {}

	@ReadOnly        
	@RemoteAction
	global static List<sObject> queryFactsChunk(String qry, Id firstId, Id lastId, Boolean isLast, string baseFilter) {    
			boolean qryCameAsMapFlag = false;
			SOQLUtil soql;				
			SOQLUtil.ChildRelationship childRel;  
			String lastIdClause = ' AND Id < \''+ lastId +'\' ';
			if (isLast) {
				lastIdClause = ' AND Id <= \''+ lastId +'\' ';	
			}	
			//KNDY-16492	
			try{
				qryCameAsMapFlag = true;
				system.debug('qry=='+qry);
				Map<string,List<Map<string,string>>> deserializedQueryMap = (Map<string,List<Map<string,string>>>)JSON.deserialize(qry,Map<string,List<Map<string,string>>>.class);
				system.debug('deserializedQueryMap=='+deserializedQueryMap);
				system.debug('deserializedQueryMap=='+deserializedQueryMap.get('ChildRelationShip'));
				system.debug('deserializedQueryMap=='+deserializedQueryMap.get('MainRelationShip'));

				Map<string,string> convertList = new Map<string,string>();
				set<string> fldSet = new set<string>(); 
				if (deserializedQueryMap.get('MainRelationShip') != null ){
			    	for (object instance :(List<Map<string,string>>) deserializedQueryMap.get('MainRelationShip')){ 
						system.debug('instance'+(Map<string,string>) instance);
						convertList = (Map<string,string>) instance;
						soql = new SOQLUtil(convertList.get('sObjectName'));
						fldSet = new set<string>(); 
						if (convertList.get('addFields') != null)
							fldSet = new set<string>(convertList.get('addFields').split(','));				
						
						soql.addFields(fldSet);			   
						string additionalWhereClause = 'Id >= \''+ firstId +'\' ' + lastIdClause + (String.isBlank(baseFilter.trim()) ? '' : ' and ');   
				        soql.setWhereClause(additionalWhereClause + ' '+ convertList.get('whereClause'));
				        soql.setOrderByClause(convertList.get('orderByClause')); 	    	
					}
				}else
					throw new QueryException('Invalid Map: ' + deserializedQueryMap);
					
    			if (deserializedQueryMap.get('ChildRelationShip') != null ){
					for (object instance :(List<Map<string,string>>) deserializedQueryMap.get('ChildRelationShip')){ 
						system.debug('instance'+(Map<string,string>) instance);
						convertList = (Map<string,string>) instance;
						childRel = new SOQLUtil.ChildRelationship(soql,convertList.get('sObjectName') );
						fldSet = new set<string>(); 
						if (convertList.get('addFields') != null)
							fldSet = new set<string>(convertList.get('addFields').split(','));		
						childRel.addFields(fldSet);
						childRel.setWhereClause(convertList.get('whereClause'));
						childRel.setOrderByClause(convertList.get('orderByClause'));  
						soql.addChildRelationship(childRel);        	
					}
				}else
					throw new QueryException('Invalid Map: ' + deserializedQueryMap);  		
						    			
			}catch(Exception e){
				qryCameAsMapFlag = false;
				system.debug('exception deserialize =' +e);
			}
			
			if (qryCameAsMapFlag){
				//do nothing	
				system.debug('qry ' + soql.getQuery()); 
			}	
			else if (!qryCameAsMapFlag){
			//to do CRUD / FLS checks, we need to deconstruct qry into the fields and object to create a SOQLUtil object
			//we should refactor this later to take in a separate set of fields and object name
			String qryDecon = qry.toLowerCase().trim().removeStart('select ').trim();
			List<String> queryList = qryDecon.split(' from ');
			if (queryList.size() == 2) {
				String objName = queryList[1].trim().toLowerCase();
				objName = objName.removeStart(KSE.NamespaceUU.toLowerCase());
				String fieldNameList = queryList[0].trim();
								
				soql = new SOQLUtil(objName, true); //enforce FLS = true
				soql.addField(fieldNameList);		
				soql.setWhereClause(
					'Id >= \''+ firstId +'\' ' + lastIdClause + (String.isBlank(baseFilter.trim()) ? '' : ' and '+	baseFilter)
				);		
				system.debug('qry ' + soql.getQuery()); 
						       
			} else {
				throw new QueryException('Invalid Query: ' + qry);
			}
	    }       
			return Database.query(soql.getQuery());			
	    }       




}