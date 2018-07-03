global with sharing class PackageClassService {


	public PackageClassService(ApexPages.StandardController sc) { }
    public PackageClassService() { }
    
    
    public static Map<Id,Id> uomsWithInventory( Set<Id> UOMIds ){
        
        //Finding the inventory related to UOMs..
        List<SKID__c> skids = new List<SKID__c>();
		SOQLUtil skidsquery = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
        skidsquery.addFields(new Set<String>{ 'Id', 'Name','Packaging_UOM__c' });
        skidsquery.setWhereClause('Packaging_UOM__c In: UOMIds');
        
        skids = Database.query(skidsquery.getQuery());
        
        Map<Id,Id> UOMskidmap = new Map<Id,Id>();
        for(SKID__c sk:skids){
        	UOMskidmap.put(sk.Packaging_UOM__c,sk.Id);
        }
        return UOMskidmap;
    }
    public static Map<Id,Package_Class__c> getPkgClassUOMDetails(Set<Id> pkgClassIds){
    	
		//Query the Packaging Class and related UOMs
	  	SOQLUtil soql = new SOQLUtil('Package_Class__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Name','Level__c','Parent_Package_Class__c','Parent_Package_Class__r.Level__c','Default_Container_Item__c','Parent_Package_Class__r.Default_Container_Item__c','Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c'
        });
        if(pkgClassIds.size()>0)
        	soql.setWhereClause('Id IN :pkgclassIds');
        
        SOQLUtil.ChildRelationship uomQuery = new SOQLUtil.ChildRelationship(soql,'UOMs__r');
        uomQuery.addFields(new Set<String>{ 'Id', 'Name' });
        soql.addChildRelationship(uomQuery);
        
        Map<Id,Package_Class__c> pkgClassmap = new Map<Id, Package_Class__c>((List<Package_Class__c>)Database.query(soql.getQuery()));
        return pkgClassmap;
    }
    
    public static void validateandupdatePkgClass(){
    	
    	//Updating the Level on the Parent Package Class.
       	List<Package_Class__c> pkgClstobeUpdated = new List<Package_Class__c>();
	  	Map<Id,Id> pkgUOMIds = new Map<Id,Id>();
        Set<Id>UOMIds = new Set<Id>();
        
        Map<Id,Package_Class__c> pkgClassmap = getPkgClassUOMDetails(new Set<Id>());
        Map<Id,Package_Class__c> parentPkgClassmap = new Map<Id,Package_Class__c>();
        
        for(Package_Class__c cl:pkgClassmap.values()){
        	if(!parentPkgClassmap.containskey(cl.Id)){
        		parentPkgClassmap.put(cl.Id,cl.Parent_Package_Class__r);
        	}
        }
        for(Package_Class__c cl:(List<Package_Class__c>)trigger.new){
        	Package_Class__c pkgCls = pkgClassmap.get(cl.Id);
        	Package_Class__c parentCls = pkgCls.Parent_Package_Class__r;
        	if(KSE.isFieldChanging('Default_Container_Item__c', cl, trigger.oldMap) && pkgCls.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c == true && (parentCls !=null)){// || pkgCls.Level__c == 1
				cl.addError('You can only choose a default container item which is lpn tracked on the highest level. ');
				
			}
			else if(KSE.isFieldChanging('Parent_Package_Class__c', cl, trigger.oldMap)){
				if(parentCls !=null && parentCls.Level__c != pkgCls.Level__c +1){
					parentCls.Level__c = pkgCls.Level__c +1;
					if(parentCls.Level__c >1 && parentCls.Default_Container_Item__c == null){
						cl.addError('Please choose a default container item on the parent package class: '+parentCls.Name);
					}
					pkgClstobeUpdated.add(parentCls);
					
					Id parentPkgClassId;
					//Find if Parent Package Class exists...
					if(parentPkgClassmap.containskey(parentCls.Id) && parentPkgClassmap.get(parentCls.Id) !=null)
	            		parentPkgClassId = parentCls.Id;
	            		
	            	//Loop through till Parent Package Class is not present.
	            	while(parentPkgClassId != null){
	            		
	            		if(parentPkgClassmap.containskey(parentPkgClassId) && parentPkgClassmap.get(parentPkgClassId) != null){
	            			Package_Class__c pk = parentPkgClassmap.get(parentPkgClassId);
		            		parentPkgClassId = pk.Id;
		            		//Update the Level
		            		pk.Level__c += 1;
		            		pkgClstobeUpdated.add(pk);
	            		}
	            		else{
	            			parentPkgClassId = null;
	            		}
	            	}
				}
				
				for(UOM__c uom:pkgCls.UOMs__r){
			    	UOMIds.add(uom.Id);
			    	pkgUOMIds.put(pkgCls.Id,uom.Id);
			    }
			}
			
        }
        
        if(trigger.isUpdate && pkgUOMIds.size()>0){
        		
        		Map<Id,Id> UOMskidmap = uomsWithInventory(UOMIds);
		        
		        for(Package_Class__c cl: (List<Package_Class__c>)trigger.new){
		        	if(pkgUOMIds !=null && pkgUOMIds.containskey(cl.Id) && UOMskidmap !=null && UOMskidmap.containskey(pkgUOMIds.get(cl.Id))){
		        		cl.addError('You cannot update the parent package class if there is any inventory for the related items. ');
		        	}
		        }
        }
        
        if(pkgClstobeUpdated.size()>0){
        	DML.updateAsUser(pkgClstobeUpdated);
		}
		        
        
    }
    
    public static void allowPkgClassDelete(Map<id,Package_Class__c> oldMap){
    	if(trigger.isBefore && trigger.isDelete){
    		
    		set<Id> pkgClassToBeDeleteIds = new set<Id>();
    		Map<Id,Id> pkgUOMIds = new Map<Id,Id>();
        	Set<Id>UOMIds = new Set<Id>();
    		
    		for(Package_Class__c pkgCl : oldMap.values()){
    			pkgClassToBeDeleteIds.add(pkgCl.Id);
    		}
    		
			Map<Id,Package_Class__c> pkgClassmap = getPkgClassUOMDetails(pkgClassToBeDeleteIds);
		    for(Package_Class__c cl: (List<Package_Class__c>)trigger.old){
	        	Package_Class__c pkgCls = pkgClassmap.get(cl.Id);
	        	for(UOM__c uom:pkgCls.UOMs__r){
			    	UOMIds.add(uom.Id);
			    	pkgUOMIds.put(pkgCls.Id,uom.Id);
			    }	
	        }
			Map<Id,Id> UOMskidmap = uomsWithInventory(UOMIds);
			System.debug(Logginglevel.Info,'UOMskidmap:'+UOMskidmap);
			for(Package_Class__c cl: (List<Package_Class__c>)trigger.old){
	        	if(pkgUOMIds !=null && pkgUOMIds.containskey(cl.Id) && UOMskidmap !=null && UOMskidmap.containskey(pkgUOMIds.get(cl.Id))){
	        		cl.addError('You cannot delete the package class if there is any inventory for the related items. ');
	        	}
	        }
    		
    	}
    }
}