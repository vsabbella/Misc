@RestResource(urlMapping='/KenandyREST/*')

global with sharing class KenandyREST {

	@HttpPost
	global static String doPost() {	
		
		//=============== BEGIN GET THE REQUEST, METHOD, AND BODY
		RestRequest req = RestContext.request;
		RestResponse res = RestContext.response;
	   
		Map<String, Object> requestMap;
		Map<String, Object> bodyMap;
		String method;
		
		List<String> errorList = new List<String>();

		//get / deserialize the request obj
		try {
			requestMap = (Map<String, Object>)JSON.deserializeUntyped(req.requestBody.toString());
		} catch (Exception e) {
			errorList.add('error deserializing request: ' + e.getMessage());	
		}
		
		//get the method and body of the request, if no errors
		if (errorList.isEmpty()) {
			try {
				 method = ((String)requestMap.get('method')).toLowerCase();
			} catch (Exception e) {
				errorList.add('method error: ' + e.getMessage());	
			} finally {
				try {
					bodyMap = (Map<String, Object>)requestMap.get('body');	
				} catch (Exception e) {
					errorList.add('body error: ' + e.getMessage());	
				}				
			}		
		}

		if (!errorList.isEmpty()) {
			return 'ERROR: ' + String.join(errorList, ', ');
		}
		//=============== END GET THE REQUEST, METHOD, AND BODY



		//=============== BEGIN CALL THE METHOD REQUESTED WITH THE PARAMS SPECIFIED
		Boolean validMethodFound = false;
		
		//QA-12 - Add web services capability and global methods exposure to Purchase Order and Receiving Document objects
		if (method == 'PurchaseOrderReceive'.toLowerCase()) {
			//this needs to be set in all methods
			validMethodFound = true; 
			
			return PurchaseOrderReceive(bodyMap);
		}else 
		if(method.toLowerCase() == 'MRPPlanData'.toLowerCase()){
			validMethodFound = true;
			return MRPPlanData(bodyMap);
		}else
		if(method.toLowerCase() == 'getPutawayBin'.toLowerCase()){
			validMethodFound = true;
			return ScannerService.getPutawayBin(bodyMap);
		}else
		if(method.toLowerCase() == 'getpalletcapacity'.toLowerCase()){
			validMethodFound = true;
			return ScannerService.getPalletCapacity(bodyMap);
		}else
		if(method.toLowerCase() == 'putaway'.toLowerCase()){
			validMethodFound = true;
			return ScannerService.putaway(bodyMap);
		}else
		if(method.toLowerCase() == 'palletize'.toLowerCase()){
			validMethodFound = true;
			return ScannerService.palletize(bodyMap);
		}else
		if(method.toLowerCase() == 'depalletize'.toLowerCase()){
			validMethodFound = true;
			return ScannerService.dePalletize(bodyMap);
		}else
		if(method.toLowerCase() == 'getlpn'.toLowerCase()){
			validMethodFound = true;
			return ScannerService.getLPN(bodyMap);
		}
		
		//more methods can go here
		
		//=============== END CALL THE METHOD REQUESTED WITH THE PARAMS SPECIFIED



		//=============== BEGIN FINAL ERROR HANDLING
		if (!validMethodFound) {
			errorList.add('method invalid: ' + method);	
		}

		String sRet = 'unknown error';
		if (!errorList.isEmpty()) {
			return 'ERROR: ' + String.join(errorList, ', ');
		}
		return sRet;
		//=============== END FINAL ERROR HANDLING
	}
	
	
	
	
	
	
	
	//BEGIN Helper methods for the REST methods above
    public static String PurchaseOrderReceive(Map<String, Object> bodyMap) {
        Id poId;
        List<KenandyREST.poLineReceiveObj> poLineRecList;
        
        List<String> errorList = new List<String>();

        try {
            poId = (Id)bodyMap.get('poId');
        } catch (Exception e) {
            errorList.add('poId error: ' + e.getMessage()); 
        }
    
        if (poId == null) {
            errorList.add('poId is null');      
        }
            
        try {
            //re-serialize the object so we can deserialize typed.
            String sPoLineRecList = JSON.serialize(bodyMap.get('poLineRecList'));
            
            poLineRecList = (List<KenandyREST.poLineReceiveObj>)JSON.deserialize(sPoLineRecList, List<KenandyREST.poLineReceiveObj>.class);

        } catch (Exception e) {
            errorList.add('poLineRecList error: ' + e.getMessage());    
        }   
        
        if (poLineRecList == null) {
            errorList.add('poLineRecList is null');     
        }   
        
        if (poLineRecList.isEmpty()) {
            errorList.add('poLineRecList is empty');        
        }                       
            
        if (!errorList.isEmpty()) {
            return 'ERROR: ' + String.join(errorList, ', ');
        }           

        JsonResult jr = PurchaseOrderReceiveExtV2.getList(poId);
        if (jr.success = false) {
            return 'ERROR: ' + JSON.serialize(jr.messages);
        }
        
        List<ReceivingWrapper> rwListForPO;
        try {
            rwListForPO = (List<ReceivingWrapper>)jr.records;
        } catch (Exception e) {
            return 'ERROR: get receivingWrapper: ' + e.getMessage();
        }


        //pivot the list into a map where key is Id and value is a list of poLineReceiveObj's
        Map<Id, List<poLineReceiveObj>> polIdReceiveObjMap = new Map<Id, List<poLineReceiveObj>>();
        Set<Id> recIds = new Set<Id>(); 
        for (KenandyREST.poLineReceiveObj p: poLineRecList) {
            recIds.add(p.polId);
            if (polIdReceiveObjMap.containsKey(p.polId)) {
                List<poLineReceiveObj> tempList = polIdReceiveObjMap.get(p.polId);
                tempList.add(p);
                polIdReceiveObjMap.put(p.polId, tempList);
            } else {
                polIdReceiveObjMap.put(p.polId, new List<poLineReceiveObj>{p});
            }
        }

        for (Id polId: polIdReceiveObjMap.keySet()) {
            if (polIdReceiveObjMap.get(polId).size() > 1) {
                return 'ERROR: same POL Id in the list twice';  
            }
        }

        //loop through the rlWrapperList and find any matching items, and set their quanities and add to new short list of POLs to receive
        //also build a set of all the POLids in it
        List<ReceivingWrapper> rwListForPOfiltered = new List<ReceivingWrapper>();      
        Set<Id> rwPOLIds = new Set<Id>(); 
        for (ReceivingWrapper rw: rwListForPO) {
            rwPOLIds.add(rw.rl.Id);

            try {
                if (polIdReceiveObjMap.containsKey(rw.rl.Id)) {
                    Id putAway = polIdReceiveObjMap.get(rw.rl.Id)[0].putAwayLocationId;

                    rw.serialWrapperList[0].skid.Quantity__c = polIdReceiveObjMap.get(rw.rl.Id)[0].receiveQuantity;
                    rw.serialWrapperList[0].skid.Location__c = putAway;
                    rw.rl.put('putAway_Location__c', putAway);
                    
                    rwListForPOfiltered.add(rw);                
                }
            } catch (Exception e) {
                errorList.add('set quantity / putaway location error: ' + e.getMessage());  
            }           
        }
        

        Set<Id> polMissingIds = new Set<Id>();
        for (Id polId: polIdReceiveObjMap.keySet()) {
            if (!rwPOLIds.contains(polId)) {
                polMissingIds.add(polId);   
            }
        }
        
        //make sure all the Ids passed in are in the rwList
        if (!polMissingIds.isEmpty()) {
            errorList.add('these POL Ids not in the wrapper: ' + JSON.serialize(polMissingIds));    
        }
        
        if (!errorList.isEmpty()) {
            return 'ERROR: ' + String.join(errorList, ', ');
        }
        
        String sRet = 'success';
        
        try {
            ReceivingDocumentServiceV2.receive(rwListForPOfiltered,null);
        } catch (Exception e) {
            sRet = e.getMessage();
        }
        
        return sRet;        
    }
	
	public static string MRPPlanData(Map<String, Object> bodyMap){
		
		//mrpRunId => Id (MRP_Run__c Id)
		//itemIds => string (comma delimited due to casting issues)
		//level => integer
		//receivingCalendarId => Id (Business Hours)
		//planningCalendarId => Id (Business Hours)
		
		string response = '';
		Savepoint sp = Database.setSavepoint();
		try{
			integer level = integer.valueOf(bodyMap.get('level'));
			List<string> itemIdList = string.valueOf(bodyMap.get('itemIds')).split(',', -1);
			Id mrpRunId = (Id)bodyMap.get('mrpRunId');
			Id receivingCalendarId = (Id)bodyMap.get('receivingCalendarId');
			Id planningCalendarId = (Id)bodyMap.get('planningCalendarId');
			
			
            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Item__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id'
            });
            soql.setWhereClause('Id IN :itemIdList');
            List<Item__c> items = Database.query(soql.getQuery());
			
			GenerateMRPPlanData mrpPlan = new GenerateMRPPlanData(level, mrpRunId, planningCalendarId, receivingCalendarId);
			mrpPlan.execute(items);
			response += 'success';
		}catch(Exception ex){
			Database.rollback(sp);
			response += 'ERROR: ' + ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
		return response;
	}
	
	//BEGIN user defined types
	public class poLineReceiveObj {
		public Id polId {get; set;}
		public Integer receiveQuantity {get; set;}
		public Id putAwayLocationId {get; set;}
		public poLineReceiveObj() {
		}
	}
	
	
}