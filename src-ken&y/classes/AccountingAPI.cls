global with sharing class AccountingAPI { 

    global class AccountingAPIException extends Exception{}
    global AccountingAPI() { 
    }
    
    global void generateAccounting(List<sObject> sourceDocuments){
        if(sourceDocuments.size() > 0){
        	string sourceDocName = sourceDocuments[0].getsObjectType().getDescribe().getLocalName();
        	string query;
        	if(AccountingService.mHeaderToLines.containsKey(sourceDocName)){
                SOQLUtil soql;
        		if(AccountingService.mHeaderToLines.get(sourceDocName) != null){
                    soql = new SOQLUtil(AccountingService.mHeaderToLines.get(sourceDocName), TRUE);
                    soql.addFields(new Set<String>{'Id', sourceDocName});
                    soql.setWhereClause(sourceDocName + ' IN :sourceDocuments');
        		}else{
                    soql = new SOQLUtil(sourceDocName, TRUE);
                    soql.addFields(new Set<String>{'Id'});
                    soql.setWhereClause('Id IN :sourceDocuments');
        		}
        		List<sObject> sdLines = Database.Query(soql.getQuery());
        		AccountingService accserv;
                if(AccountingService.mAccountingWorkers.containsKey(sourceDocName)){
                	Type t = Type.forName(AccountingService.mAccountingWorkers.get(sourceDocName));
                	accserv = (AccountingService)t.newInstance();
                }
                accserv.execute(sdLines);
        	}
        }
    } 
    
    global class UnfinalizeResponse {
        global Id recordId;
        global boolean success;
        global string message;
        
        global UnfinalizeResponse(){}
        public UnfinalizeResponse(UnfinalizeService.UnfinalizeResponse response){
            this.recordId = response.recordId;
            this.success = response.success;
            this.message = response.message;
        }
    }
    
    global static Map<Id, UnfinalizeResponse> unfinalizeSourceDocs(List<sObject> sObjRecs){
        Map<Id, UnfinalizeResponse> responses = new  Map<Id, UnfinalizeResponse>();
        for(UnfinalizeService.UnfinalizeResponse response : UnfinalizeService.unfinalizeSourceDocs(sObjRecs).values()) {
            responses.put(response.recordId,new UnfinalizeResponse(response));
        }
        return responses;
    }
}