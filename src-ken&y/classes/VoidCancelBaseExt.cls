global virtual with sharing class VoidCancelBaseExt {

    public  string guid{get;set;}
    public static DateTime voidDate{get;set;}
    private static String kHexChars = '0123456789abcdefABCDEF';
    private static string safeChars = 'ABCDFGHJKLMNPQRSTUVWXYZ123456789';
    private static map<string, VoidCancelService> mVoidCancelWorkers = new map<string, VoidCancelService>();
    public static Savepoint sp1;
    public integer NumberOfRetries{get;set;}
//    public boolean stopRetry{get;set;}
    public class ChunkReverseResult
    {
        public Integer NextChunkIndex=0;
        public Boolean ChunkReverse=false;
        public Boolean AllDone=false;
        public Decimal Progress;
        public string Messages='';
		public integer reverseSize;
        public string reverseChunkMap;
        public decimal AELineCount;
        public ID voidedAEId;
    }
    
     public class ResultActualVoid
    {
        public Boolean AllDone=false;       
        @testvisible public string Messages='';
    }
    public class ResultVoidWithoutAEL
    {
        public Boolean AllDone=false;       
        @testvisible public string Messages='';
    }
    public ChunkReverseResult prepreVoidDoc(id sObjectId){
             ChunkReverseResult obj = new ChunkReverseResult();
            integer chunkSize = 0;
            Configuration__c c = Configuration__c.getValues('VoidChunksize');
            if (c == null) {
                chunkSize=200;          
            } 
            else {
                if (c.Value__c == null)
                    {
                    chunkSize=200;
                    } 
                else {
                       chunkSize = Integer.valueof(c.Value__c);
                    } 
            }
            NumberOfRetries=KSE.getRetries('VoidAERetries');
            string sObjName = sObjectId.getSObjectType().getDescribe().getName();
            set<string> queryFields = new set<string> {'id','Name','total_lines__c'};
            string whereClause = sObjName.replace('__c','__r') + '.Id =' + '\'' +sObjectId + '\'' + ' and Related_Accounting_Entry__c = null and status__c = \'Active\' ';
            string objectName = 'Accounting_Entry__c';
        
            SOQLUtil soql = new SOQLUtil(objectName,false);
            soql.addFields(queryFields);
            soql.setWhereClause(whereClause);               
            
            //string q = soql.getQuery();
            //system.debug('q is ****' + q);
            list<Accounting_Entry__c> voidedAE = new list<Accounting_Entry__c>();
            voidedAE = database.query ( soql.getQuery() );

            //Get autonumber chunks for AEL to reverse.
            if(voidedAE[0].total_lines__c > 0){
                List<Map<string, string>> chunks = new List<Map<string, string>>();
                
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                
                soql = new SOQLUtil('accounting_entry_line__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'id','autonumber__c'
                });
                soql.setWhereClause('Accounting_Entry__c in :voidedAE');
                soql.setOrderByClause('autonumber__c ASC');
                soql.setLimit(1);
                
                list<sobject> sobjMin = Database.query(soql.getQuery());

                soql.setOrderByClause ('autonumber__c DESC') ;
                list<sobject> sobjMax = Database.query ( soql.getQuery () ) ;

                integer minRev=(integer)integer.valueOf(sobjMin[0].get('autonumber__c'));
                integer maxRev=(integer)integer.valueOf(sobjMax[0].get('autonumber__c'));
                system.debug('min: ' +minRev + ' max: ' + maxRev);
                    
                integer ref = minRev;
                while(ref <= maxRev){
                    
                    Map<string, string> iMap = new Map<string, string>();
                    iMap.put('min', prefixIntWithZeros(ref, 10));
                    iMap.put('max', prefixIntWithZeros(ref+chunkSize, 10));
                    
                    ref += chunkSize + 1;
                    chunks.add(iMap);
                }
                
                obj.reverseSize=chunks.size();
                obj.allDone = true;
                string ChunkJSON = JSON.serialize(chunks);
                obj.reverseChunkMap = ChunkJSON;
                obj.AELineCount =voidedAE[0].total_lines__c; 
                obj.voidedAEId = voidedAE[0].id;
            }else {
                obj.voidedAEId=voidedAE[0].id;            
                obj.reverseSize = 0;            
            }
           return obj;
    }
    
    public static string prefixIntWithZeros(Integer intInput, Integer totalLength) {
        String sOutput = '';
        
        if (intInput != null) {
            sOutput = intInput+'';
        }
        
        //prepend with however many zeros we need to get up to total length
        Integer zerosToAdd = (totalLength - sOutput.length());
        if (zerosToAdd > 0) {
            for (Integer i=0; i<zerosToAdd; i++) {
                sOutput = '0'+sOutput;  
            }
        }
        
        return sOutput;
    }
    @RemoteAction
    public static ChunkReverseResult reverseAE(id voidedAE,integer CurrChunkIndex,Integer TotalChunks,string min,string max,boolean doVoid, string guid)
    {
        ChunkReverseResult revObj = new ChunkReverseResult();
        try
        {
            if(currChunkIndex>=TotalChunks)
            {
                    //Empty remote call.Defering and waiting for del drafts to complete
            }
            else 
            {
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('accounting_entry_line__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','name'
				});
				soql.setWhereClause('Accounting_Entry__c=:voidedAE and autonumber__c>=:min and autonumber__c<=:max');

				list<accounting_entry_line__c> AELReverseInScope= Database.query(soql.getQuery());

                if(doVoid)//Indicates SD is  not JournalEntry-AccrualManual
                {
                   AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELReverseInScope, guid);
                }
                else
                {
                   AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEReverse, AELReverseInScope, guid);
                }


                revObj.NextChunkIndex=CurrChunkIndex+1;
                if(CurrChunkIndex==TotalChunks-1)
                {
                revObj.AllDone=true;

                }
                else
                {
                  revObj.AllDone=false;

                }


            }

                revObj.progress=reverseAEGenProgress(voidedAE,guid);
                revObj.ChunkReverse=true;
        }
        catch(Exception ex)
        {
            revObj.messages=ex.getMessage()+ 'on Line'+ex.getLineNumber();
            revObj.ChunkReverse=false;
            revObj.progress=-1;
            revObj.AllDone=false;

        }
        return revObj;

    }    
 
    @RemoteAction
    public static ChunkReverseResult reverseAEWithDates(id voidedAE,integer CurrChunkIndex,Integer TotalChunks,string min,string max,boolean doVoid, string guid,string VoidDatetime, string tranDateTime)
    {
        if(VoidDatetime != null){
	        DateTime acceptableDateTime = DateTime.Valueof(VoidDatetime.replace('T', ' '));         
	        voidDate = acceptableDateTime;
	        AccountingEntryService.VoidDate = voidDate;
        }
        datetime tranDate;
        
        if(tranDatetime != null){
	        DateTime acceptableDateTime = DateTime.Valueof(tranDateTime.replace('T', ' '));         
	        tranDate = acceptableDateTime;
        }
        
        ChunkReverseResult revObj = new ChunkReverseResult();
            //je.void_date__c = system.now();            
        try
        {
            if(currChunkIndex>=TotalChunks)
            {
                    //Empty remote call.Defering and waiting for del drafts to complete
            }
            else 
            {
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                
                SOQLUtil soql = new SOQLUtil('accounting_entry_line__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'id','name','accounting_entry__r.company__c','accounting_entry__r.Source_Document_Object_Name__c'
                });
                soql.setWhereClause('Accounting_Entry__c=:voidedAE and autonumber__c>=:min and autonumber__c<=:max');

                list<accounting_entry_line__c> AELReverseInScope= Database.query(soql.getQuery());

	            id companyId = AELReverseInScope[0].accounting_entry__r.company__c;
	        	map<string,list<datetime>> inputMap = new map <string,list<datetime>>();
	        	string objectName = AELReverseInScope[0].accounting_entry__r.Source_Document_Object_Name__c;
	        	inputMap.put(objectName, new list<datetime>{voidDate});
	            
				map<string, list<map<datetime,PeriodService.checkPeriodResult>>> resultMap = periodService.checkOpenPeriodAndSubledgerForDate(inputMap,companyId);
                if(resultMap != null && resultMap.containskey(objectName)){
                    list<map<datetime,PeriodService.checkPeriodResult>> newResult = resultMap.get(objectName);
                    PeriodService.checkPeriodResult result = new PeriodService.checkPeriodResult();
                    
                    for(map<datetime,PeriodService.checkPeriodResult> rmap: newResult){
                        if (rmap.containsKey(voidDate)){
                            Result = rmap.get(voidDate);
                            break;
                        }
                    }
                    	
                    if( result.periodOpen != true){
                        revObj.AllDone=false;
                        revObj.messages=label.Void_Date_Period_not_open;
                        return revObj;
                        
                    }
                    if( result.subledgerOpen != true){
                        revObj.AllDone=false;
                        revObj.messages=label.void_date_Subledger_not_open;
                        return revObj;
                        
                    }
                }
 	            if(voidDate < tranDate ){
	            	revObj.AllDone=false;
            		revObj.messages=label.Void_date_cannot_before_Transaction_date;
	            	return revObj;
	            	
	            }
                
                if(doVoid)//Indicates SD is  not JournalEntry-AccrualManual
                {
                   AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELReverseInScope, guid);
                }
                else
                {
                   AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEReverse, AELReverseInScope, guid);
                }


                revObj.NextChunkIndex=CurrChunkIndex+1;
                if(CurrChunkIndex==TotalChunks-1)
                {
                revObj.AllDone=true;

                }
                else
                {
                  revObj.AllDone=false;

                }


            }

                revObj.progress=reverseAEGenProgress(voidedAE,guid);
                revObj.ChunkReverse=true;
        }
        catch(Exception ex)
        {
            revObj.messages=ex.getMessage()+ 'on Line'+ex.getLineNumber();
            revObj.ChunkReverse=false;
            revObj.progress=-1;
            revObj.AllDone=false;

        }
        return revObj;

    }    
      public static decimal reverseAEGenProgress(id voidedAE, string guid)
    {

        SOQLUtil soql = new SOQLUtil ( 'Accounting_Entry__c' ) ;
        soql.addFields ( new Set<String> { 'id','name','total_lines__c' } ) ;
        soql.setWhereClause ( ' related_accounting_entry__c=:voidedAE AND status__c = \'Draft\' AND batchjobid__c = :guid ') ;
        List<accounting_entry__c> reversedAE = Database.query ( soql.getQuery ()  ) ;
        
        if(reversedAE.size()>0)
        {               
                      
          decimal currcount = reversedAE[0].total_lines__c;
          system.debug('inside update'+ currcount);
          return currcount;
            
        }
     
        else //Check if Active AE is generated
        {

            return 0;
        }
    }

     public static Map<Id, VoidCancelService.VoidCancelResponse> AccountingVoid(list<sObject> sObjRecs){
    	
        Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
        Map<String,List<sObject>> mObjectRecs = new Map<String,List<sObject>> ();
        List<Accounting_Entry__c> finishedAccountingEntries = new List<Accounting_Entry__c>();
        set<Id> voidIds = new set<Id>();
        
        for(sObject s : sObjRecs){
            voidIds.add(s.Id);            
        }
        
        string wherestr = String.join(SchemaUtil.getInstance().relatedCustomObjects('Accounting_Entry__c'),' IN :voidIds OR ') +' IN :voidIds ';
        set<string> queryFields = new set<string> {'id','Source_Document_Object_Name__c','Transaction_Type__c','Company__c','Company__r.Id','Company__r.Name'};
        string whereClause = '(' + wherestr + ') and (Status__c=\'Active\' or Status__c=\'Draft\')';
        string objectName = 'Accounting_Entry__c';
        SOQLUtil soql = new SOQLUtil(objectName,false);
        soql.addFields('Source_Documents');
        soql.addFields(queryfields);
        soql.setWhereClause(whereClause);               
        //string q = soql.getQuery();
        //system.debug('q: ' + q);
        finishedAccountingEntries = database.query ( soql.getQuery() );
        
        Map<Id, List<Accounting_Entry__c>> mAEs = new Map<Id, List<Accounting_Entry__c>>();
        for(Accounting_Entry__c ae : finishedAccountingEntries){
            Id sourceDocId = (Id)ae.get(AccountingEntryService.SourceDocPathMap.get(ae.Source_Document_Object_Name__c));
            if(mAEs.containsKey(sourceDocId)){
                mAEs.get(sourceDocId).add(ae);
            }else{
                mAEs.put(sourceDocId, new List<Accounting_Entry__c>{ae});
            }
        }
        
        for(sObject s : sObjRecs){
            
            VoidCancelService.VoidCancelResponse iVCR = new VoidCancelService.VoidCancelResponse();
            iVCR.recordId = s.Id;
            iVCR.recordName = (string)s.get('Name');
            iVCR.action = VoidCancelService.Action.VOIDDOC;
            
            if(mAEs.containsKey(s.Id)){
                //simple test, each SD should have 2 AEs, the original and the voiding entry
                iVCR.success = mAEs.get(s.Id).size() >= 2;
            }else{
                iVCR.success = false;
            }
            
            if(!iVCR.success){
                iVCR.messages.add('Unable to complete accounting void');
            }
//            system.debug('iVCR.messages ****' + iVCR.messages);
            mResponses.put(iVCR.recordId, iVCR);
        }
        
        
        return mResponses;
    } 
    
        @RemoteAction
    public static ResultActualVoid ActualVoidSD(List<sObject> sObjRecs,string guid){
	    ResultActualVoid revObj = new ResultActualVoid();
        set<string> queryFields;
        try{
            List<Accounting_Entry__c> updateVoidAE = new List<Accounting_Entry__c>();
            Map<String,List<sObject>> mObjectRecs = new Map<String,List<sObject>> ();
            Map<String,List<sObject>> mObjectRecsNew = new Map<String,List<sObject>> ();
            for(sObject s : sObjRecs){
                Schema.SObjectType objectSchema= s.getSObjectType();
                Schema.DescribeSObjectResult sObjectResult = objectSchema.getDescribe();
                String objectName = sObjectResult.getLocalName();
                if(mObjectRecs.containsKey(objectName)){
                    mObjectRecs.get(objectName).add(s);
                }else{
                    mObjectRecs.put(objectName, new List<sObject>{s});
                }
            }
            if(voidDate == null){
                voidDate = system.now();
            }
            
            for(String sObjectName : mObjectRecs.keySet()){
                list<sobject> solist = mObjectRecs.get(sObjectName);
                queryFields = new set<string> {'id','Name'};
                string whereClause = 'Id in : solist and (Void__c = false or Void__c = null)';
                SOQLUtil soql = new SOQLUtil(sObjectName,false);
                soql.addFields(queryfields);
                soql.setWhereClause(whereClause);               
                //string query = soql.getQuery();
                //system.debug('query: ' + query);
                list<sObject> sObjectList = database.query ( soql.getQuery() );
            
                 mObjectRecsNew.put(sObjectName, sObjectList);
            }
            
            for(String sObjectName : mObjectRecsNew.keySet()){
                
                if(VoidCancelService.mVoidCancelServices.containsKey(sObjectName)){
                    VoidCancelService voidCancelSvc;
                    String factoryClassName = VoidCancelService.mVoidCancelServices.get(sObjectName);
                    if(mVoidCancelWorkers!= null && mVoidCancelWorkers.containsKey(factoryClassName)){
                        voidCancelSvc = mVoidCancelWorkers.get(factoryClassName);
                    }else{
                        Type t = Type.ForName(factoryClassName);
                        voidCancelSvc = (VoidCancelService)t.newInstance();
                        voidCancelSvc.setSourceDocuments(mObjectRecs.get(sObjectName));
                    }
                    string query;
                    List<sObject> sObjRec = mObjectRecs.get(sObjectName);
                    if(sObjectName.contains('Journal_Entry')){
                        queryFields = new set<string> {'id','Name','Transaction_Date__c', 'Void__c', 'Status__c', 'Finalized_Date__c', 'Company__c', 'Posting_Date__c', 'Finalized__c'};
                    }else{
                        queryFields = new set<string> {'id','Name','Transaction_Date__c', 'Void__c', 'Status__c', 'Finalized_Date__c', 'Company__c', 'Posting_Date__c', 'Finalized__c','Historical__c'};                    
                    }
                    string whereClause = 'Id in : sObjRec';
                    SOQLUtil soql = new SOQLUtil(sObjectName,false);
                    soql.addFields(queryfields);
                    soql.setWhereClause(whereClause);               
                    //query = soql.getQuery();
                    //system.debug('query: ' + query);
                    list<sObject> sObjects = new list<sObject>();
                    sObjects = database.query ( soql.getQuery() );
            
                    List<sObject> businessVoidSourceDocs = new List<sObject>();
                    List<sObject> voidSourceDocs = new List<sObject>();
                    set<Id> voidIds = new set<Id>();
                    set<Id> bvoidIds = new set<Id>();
                    for(sObject sObj : sObjects){
                        if(voidCancelSvc.getVoidCancelDetails().get(sObj.Id).isVoidable){               
                            voidIds.add(sObj.Id);
                            voidSourceDocs.add(sObj);
                        }
                    }
                    FinalizeService.voidIds.addAll(voidIds);
                    sp1 = Database.setSavepoint();
                    Map<Id, VoidCancelService.VoidCancelResponse> mAccountingVoidResponses = AccountingVoid(voidSourceDocs);
                    for(sObject sObj : voidSourceDocs){
                        VoidCancelService.VoidCancelResponse iVCR = new VoidCancelService.VoidCancelResponse();
                        if(mAccountingVoidResponses.containsKey(sObj.Id)){
                            iVCR.Success = mAccountingVoidResponses.get(sObj.Id).Success;
                            if(iVCR.success){
                                sObj.put('Finalized__c', true);
                                sObj.put('Void__c', true);
                                sObj.put('Void_Date__c', voidDate);
                                sObj.put('Status__c', 'Void');
                                businessVoidSourceDocs.add(sObj);
                                bvoidIds.add(sObj.id);                  
                            }
                        }
                    }
                    DML.updateAsUser(businessVoidSourceDocs);
                    system.debug(logginglevel.INFO,'bvoidIds:  ****' + bvoidIds + '**** ' +  businessVoidSourceDocs);
                    
                    Map<Id, VoidCancelService.VoidCancelResponse> mBusinessVoidResponses = voidCancelSvc.businessVoid(businessVoidSourceDocs);
                    List<Accounting_Entry__c> finishedAccountingEntries = new List<Accounting_Entry__c>();
                    
                    string wherestr = String.join(SchemaUtil.getInstance().relatedCustomObjects('Accounting_Entry__c'),' IN :bvoidIds OR ') +' IN :bvoidIds ';
                    Set<String> setFieldSets = new set<string>{'Source_Documents'} ;
                    Set<String> addlFields = new set<string>{'id','Source_Document_Object_Name__c','Has_Exceptions__c','Period__r.AP_Subledger_Closed__c','Period__r.AR_Subledger_Closed__c','Period__r.FA_Subledger_Closed__c','Period__r.Inventory_Subledger_Closed__c','Period__r.Period_Closed__c','Period__r.Receiving_Subledger_Closed__c','Period__r.open__c'} ;
                    String aeWhereClause = '(' + wherestr + ') and (Status__c=\'Active\') and related_accounting_entry__c != null and batchjobid__c  =: guid limit 1' ;
                    
                    //string q = SchemaUtil.getInstance().generateQueryFromFieldSet( 'Accounting_Entry__c',
                        //new set<string>{'Source_Documents'}, 

                        //As part of FIN-903 AE is swapped to active in Accounting Entry Service                                                         
                        //new set<string>{'id','Source_Document_Object_Name__c','Has_Exceptions__c'}, '(' + wherestr + ') and (Status__c=\'Active\') and related_accounting_entry__c != null and batchjobid__c  =: guid limit 1');
                    
                    //system.debug('Accounting Void q: ****' + q);
                    //finishedAccountingEntries = database.query ( q );
                    finishedAccountingEntries = Database.query ( SchemaUtil.getInstance().generateQueryFromFieldSet( 'Accounting_Entry__c', setFieldSets , addlFields , aeWhereClause ) ) ;
    //              system.debug(logginglevel.INFO,'finishedAccountingEntries:  ****' + finishedAccountingEntries);
            
                    Map<Id, Accounting_Entry__c> mAEs = new Map<Id, Accounting_Entry__c>();
                    for(Accounting_Entry__c ae : finishedAccountingEntries){
                        Id sourceDocId = (Id)ae.get(AccountingEntryService.SourceDocPathMap.get(ae.Source_Document_Object_Name__c));            
                            mAEs.put(sourceDocId, ae);
                    }
                    for(sObject sObj : voidSourceDocs){
                        VoidCancelService.VoidCancelResponse iVCR = mAccountingVoidResponses.get(sObj.Id);
                        if(mBusinessVoidResponses.containsKey(sObj.Id)){
                            iVCR.success = mBusinessVoidResponses.get(sObj.Id).Success && iVCR.success;
                            iVCR = mBusinessVoidResponses.get(sObj.Id);
                            Accounting_Entry__c ae = mAEs.get(sObj.id);
                            if(iVCR.success){
                                if(ae != null){
                                    if(ae.has_exceptions__c){
                                        Database.rollback(sp1); 
                                        revObj.messages='Document is not voided. Voided accounting entry has exceptions';
                                        revObj.AllDone = false;
                                        ae.status__c = 'Obsolete';
                                        updateVoidAE.add(ae);
                                    }else if(ae.Period__r.open__c != true){
                                        Database.rollback(sp1); 
                                        revObj.messages='Document is not voided. For this void Date period is not open';
                                        revObj.AllDone = false;
                                        ae.status__c = 'Obsolete';
                                        updateVoidAE.add(ae);
                                    }else if(ae.Period__r.open__c != true){
                                        Database.rollback(sp1); 
                                        revObj.messages='Document is not voided. For this void Date period is not open';
                                        revObj.AllDone = false;
                                        ae.status__c = 'Obsolete';
                                        updateVoidAE.add(ae);
                                    }else{
                                        revObj.AllDone = true;
                                    //As part of FIN-903  this is done in service
                                    //Accounting_Entry__c ae = mAEs.get(sObj.id);
                                    //ae.status__c = 'Active';
                                    //updateVoidAE.add(ae);
                                    }
                                }
                            }
                            else{
                                Database.rollback(sp1);                            
                                if(ae.has_exceptions__c){
                                    revObj.messages='Document is not voided. Voided accounting entry has exceptions';
                                }else{
                                    revObj.messages='Document is not voided. ' +iVCR.messages;
                                }revObj.AllDone = false; 
                                ae.status__c = 'Obsolete';
                                updateVoidAE.add(ae);
                            }
                        }else{
                            Database.rollback(sp1); 
                            Accounting_Entry__c ae = mAEs.get(sObj.id);
                            ae.status__c = 'Obsolete';
                            updateVoidAE.add(ae);
                            revObj.messages='Document is not voided. ' + iVCR.messages;
                            revObj.AllDone = false;             
                        }
                    }
                }
            }
            DML.updateAsUser(updateVoidAE);
            return revObj;
        }
        catch(exception e){
            system.debug('e '+e.getmessage() +' '+e.getStacktraceString());
            Database.rollback(sp1); 
            set<id> scope = new set<id>();
            
            for(sobject sobj:sobjrecs)
            {
                scope.add(sobj.id);
            }
            queryFields = new set<string>{'id','Source_Document_Object_Name__c'};
            string wherestr = String.join(SchemaUtil.getInstance().relatedCustomObjects('Accounting_Entry__c'),' IN :scope OR ') +' IN :scope ';
            //TODO:Add batchjobid filter to get that guid.
            string whereClause = '(' + wherestr + ') and (Status__c=\'Active\') and related_accounting_entry__c != null and batchjobid__c  =: guid limit 1';
            string objectName = 'Accounting_Entry__c';
            SOQLUtil soql = new SOQLUtil(objectName,false);
            soql.addFields('Source_Documents');
            soql.addFields(queryfields);
            soql.setWhereClause(whereClause);               
            string q = soql.getQuery();                 
            system.debug('q: in catch ****' + q);
            system.debug('message is ****  ' + q + e.getmessage() + '  '+ e.getlineNumber());
            list<accounting_entry__c> finishedAccountingEntries = database.query ( soql.getQuery() );
            for(accounting_entry__c ae:finishedAccountingEntries)
            {
                ae.status__c='Obsolete';
            }
            DML.updateAsUser(finishedAccountingEntries);
            revObj.AllDone = false;             
            revObj.messages='Document is not voided. ' + e + ' ' + e.getLineNumber();
            return revObj;
        
        }



    }
    
    
    @RemoteAction
    public static ResultActualVoid ActualVoidSDWithDates(List<sObject> sObjRecs,string guid,string VoidDateTime){
        if(VoidDateTime != null){
	        DateTime acceptableDateTime = DateTime.Valueof(VoidDatetime.replace('T', ' '));         
	        voidDate = acceptableDateTime;
        }
	    ResultActualVoid revObj = new ResultActualVoid();
        //system.assert(1==2,'In actual void ' + VoidDateTime);
        set<string> queryFields;
        try{
            List<Accounting_Entry__c> updateVoidAE = new List<Accounting_Entry__c>();
            Map<String,List<sObject>> mObjectRecs = new Map<String,List<sObject>> ();
            Map<String,List<sObject>> mObjectRecsNew = new Map<String,List<sObject>> ();
            for(sObject s : sObjRecs){
            	s.put('Void_Date__c', voidDate);
                Schema.SObjectType objectSchema= s.getSObjectType();
                Schema.DescribeSObjectResult sObjectResult = objectSchema.getDescribe();
                String objectName = sObjectResult.getLocalName();
                if(mObjectRecs.containsKey(objectName)){
                    mObjectRecs.get(objectName).add(s);
                }else{
                    mObjectRecs.put(objectName, new List<sObject>{s});
                }
            }
            if(voidDate == null){
                voidDate = system.now();
            }
            
            for(String sObjectName : mObjectRecs.keySet()){
                list<sobject> solist = mObjectRecs.get(sObjectName);
                queryFields = new set<string> {'id','Name'};
                string whereClause = 'Id in : solist and (Void__c = false or Void__c = null)';
                SOQLUtil soql = new SOQLUtil(sObjectName,false);
                soql.addFields(queryfields);
                soql.setWhereClause(whereClause);               
                //string query = soql.getQuery();
                //system.debug('query: ' + query);
                list<sObject> sObjectList = database.query ( soql.getQuery() );
            
                 mObjectRecsNew.put(sObjectName, sObjectList);
            }
            
            for(String sObjectName : mObjectRecsNew.keySet()){
                
                if(VoidCancelService.mVoidCancelServices.containsKey(sObjectName)){
                    VoidCancelService voidCancelSvc;
                    String factoryClassName = VoidCancelService.mVoidCancelServices.get(sObjectName);
                    if(mVoidCancelWorkers!= null && mVoidCancelWorkers.containsKey(factoryClassName)){
                        voidCancelSvc = mVoidCancelWorkers.get(factoryClassName);
                    }else{
                        Type t = Type.ForName(factoryClassName);
                        voidCancelSvc = (VoidCancelService)t.newInstance();
                        voidCancelSvc.setSourceDocuments(mObjectRecs.get(sObjectName));
                    }
                    string query;
                    List<sObject> sObjRec = mObjectRecs.get(sObjectName);
                    if(sObjectName.contains('Journal_Entry')){
                        queryFields = new set<string> {'id','Name','Transaction_Date__c', 'Void__c', 'Status__c', 'Finalized_Date__c', 'Company__c', 'Posting_Date__c', 'Finalized__c'};
                    }else{
                        queryFields = new set<string> {'id','Name','Transaction_Date__c', 'Void__c', 'Status__c', 'Finalized_Date__c', 'Company__c', 'Posting_Date__c', 'Finalized__c','Historical__c'};                    
                    }
                    string whereClause = 'Id in : sObjRec';
                    SOQLUtil soql = new SOQLUtil(sObjectName,false);
                    soql.addFields(queryfields);
                    soql.setWhereClause(whereClause);               
                    //query = soql.getQuery();
                    //system.debug('query: ' + query);
                    list<sObject> sObjects = new list<sObject>();
                    sObjects = database.query ( soql.getQuery() );
            
                    List<sObject> businessVoidSourceDocs = new List<sObject>();
                    List<sObject> voidSourceDocs = new List<sObject>();
                    set<Id> voidIds = new set<Id>();
                    set<Id> bvoidIds = new set<Id>();
                    for(sObject sObj : sObjects){
                        if(voidCancelSvc.getVoidCancelDetails().get(sObj.Id).isVoidable){               
                            voidIds.add(sObj.Id);
                            voidSourceDocs.add(sObj);
                        }
                    }
                    FinalizeService.voidIds.addAll(voidIds);
                    sp1 = Database.setSavepoint();
                    Map<Id, VoidCancelService.VoidCancelResponse> mAccountingVoidResponses = AccountingVoid(voidSourceDocs);
                    for(sObject sObj : voidSourceDocs){
                        VoidCancelService.VoidCancelResponse iVCR = new VoidCancelService.VoidCancelResponse();
                        if(mAccountingVoidResponses.containsKey(sObj.Id)){
                            iVCR.Success = mAccountingVoidResponses.get(sObj.Id).Success;
                            if(iVCR.success){
                                sObj.put('Finalized__c', true);
                                sObj.put('Void__c', true);
                                sObj.put('Void_Date__c', voidDate);
                                sObj.put('Status__c', 'Void');
                                businessVoidSourceDocs.add(sObj);
                                bvoidIds.add(sObj.id);                  
                            }
                        }
                    }
                    DML.updateAsUser(businessVoidSourceDocs);
                    system.debug(logginglevel.INFO,'bvoidIds:  ****' + bvoidIds + '**** ' +  businessVoidSourceDocs);
                    
                    Map<Id, VoidCancelService.VoidCancelResponse> mBusinessVoidResponses = voidCancelSvc.businessVoid(businessVoidSourceDocs);
                    List<Accounting_Entry__c> finishedAccountingEntries = new List<Accounting_Entry__c>();
                    
                    string wherestr = String.join(SchemaUtil.getInstance().relatedCustomObjects('Accounting_Entry__c'),' IN :bvoidIds OR ') +' IN :bvoidIds ';
                    Set<String> setFieldSets = new set<string>{'Source_Documents'} ;
                    Set<String> addlFields = new set<string>{'id','Source_Document_Object_Name__c','Has_Exceptions__c','Period__r.AP_Subledger_Closed__c','Period__r.AR_Subledger_Closed__c','Period__r.FA_Subledger_Closed__c','Period__r.Inventory_Subledger_Closed__c','Period__r.Period_Closed__c','Period__r.Receiving_Subledger_Closed__c','Period__r.open__c'} ;
                    String aeWhereClause = '(' + wherestr + ') and (Status__c=\'Active\') and related_accounting_entry__c != null and batchjobid__c  =: guid limit 1' ;
                    
                    //string q = SchemaUtil.getInstance().generateQueryFromFieldSet( 'Accounting_Entry__c',
                        //new set<string>{'Source_Documents'}, 

                        //As part of FIN-903 AE is swapped to active in Accounting Entry Service                                                         
                        //new set<string>{'id','Source_Document_Object_Name__c','Has_Exceptions__c'}, '(' + wherestr + ') and (Status__c=\'Active\') and related_accounting_entry__c != null and batchjobid__c  =: guid limit 1');
                    
                    //system.debug('Accounting Void q: ****' + q);
                    //finishedAccountingEntries = database.query ( q );
                    finishedAccountingEntries = Database.query ( SchemaUtil.getInstance().generateQueryFromFieldSet( 'Accounting_Entry__c', setFieldSets , addlFields , aeWhereClause ) ) ;
    //              system.debug(logginglevel.INFO,'finishedAccountingEntries:  ****' + finishedAccountingEntries);
            
                    Map<Id, Accounting_Entry__c> mAEs = new Map<Id, Accounting_Entry__c>();
                    for(Accounting_Entry__c ae : finishedAccountingEntries){
                        Id sourceDocId = (Id)ae.get(AccountingEntryService.SourceDocPathMap.get(ae.Source_Document_Object_Name__c));            
                            mAEs.put(sourceDocId, ae);
                    }
                    for(sObject sObj : voidSourceDocs){
                        VoidCancelService.VoidCancelResponse iVCR = mAccountingVoidResponses.get(sObj.Id);
                        if(mBusinessVoidResponses.containsKey(sObj.Id)){
                            iVCR.success = mBusinessVoidResponses.get(sObj.Id).Success && iVCR.success;
                            iVCR = mBusinessVoidResponses.get(sObj.Id);
                            Accounting_Entry__c ae = mAEs.get(sObj.id);
                            if(iVCR.success){
                                if(ae != null){
                                    if(ae.has_exceptions__c){
                                        Database.rollback(sp1); 
                                        revObj.messages='Document is not voided. Voided accounting entry has exceptions';
                                        revObj.AllDone = false;
                                        ae.status__c = 'Obsolete';
                                        updateVoidAE.add(ae);
                                    }else if(ae.Period__r.open__c != true){
                                        Database.rollback(sp1); 
                                        revObj.messages='Document is not voided. For this void Date period is not open';
                                        revObj.AllDone = false;
                                        ae.status__c = 'Obsolete';
                                        updateVoidAE.add(ae);
                                    }else if(ae.Period__r.open__c != true){
                                        Database.rollback(sp1); 
                                        revObj.messages='Document is not voided. For this void Date period is not open';
                                        revObj.AllDone = false;
                                        ae.status__c = 'Obsolete';
                                        updateVoidAE.add(ae);
                                    }else{
                                        revObj.AllDone = true;
                                    //As part of FIN-903  this is done in service
                                    //Accounting_Entry__c ae = mAEs.get(sObj.id);
                                    //ae.status__c = 'Active';
                                    //updateVoidAE.add(ae);
                                    }
                                }
                            }
                            else{
                                Database.rollback(sp1);                            
                                if(ae.has_exceptions__c){
                                    revObj.messages='Document is not voided. Voided accounting entry has exceptions';
                                }else{
                                    revObj.messages='Document is not voided. ' +iVCR.messages;
                                }revObj.AllDone = false; 
                                ae.status__c = 'Obsolete';
                                updateVoidAE.add(ae);
                            }
                        }else{
                            Database.rollback(sp1); 
                            Accounting_Entry__c ae = mAEs.get(sObj.id);
                            ae.status__c = 'Obsolete';
                            updateVoidAE.add(ae);
                            revObj.messages='Document is not voided. ' + iVCR.messages;
                            revObj.AllDone = false;             
                        }
                    }
                }
            }
            DML.updateAsUser(updateVoidAE);
            return revObj;
        }
        catch(exception e){
            system.debug('e '+e.getmessage() +' '+e.getStacktraceString());
            Database.rollback(sp1); 
            set<id> scope = new set<id>();
            
            for(sobject sobj:sobjrecs)
            {
                scope.add(sobj.id);
            }
            queryFields = new set<string>{'id','Source_Document_Object_Name__c'};
            string wherestr = String.join(SchemaUtil.getInstance().relatedCustomObjects('Accounting_Entry__c'),' IN :scope OR ') +' IN :scope ';
            //TODO:Add batchjobid filter to get that guid.
            string whereClause = '(' + wherestr + ') and (Status__c=\'Active\') and related_accounting_entry__c != null and batchjobid__c  =: guid limit 1';
            string objectName = 'Accounting_Entry__c';
            SOQLUtil soql = new SOQLUtil(objectName,false);
            soql.addFields('Source_Documents');
            soql.addFields(queryfields);
            soql.setWhereClause(whereClause);               
            string q = soql.getQuery();                 
            system.debug('q: in catch ****' + q);
            system.debug('message is ****  ' + q + e.getmessage() + '  '+ e.getlineNumber());
            list<accounting_entry__c> finishedAccountingEntries = database.query ( soql.getQuery() );
            for(accounting_entry__c ae:finishedAccountingEntries)
            {
                ae.status__c='Obsolete';
            }
            DML.updateAsUser(finishedAccountingEntries);
            revObj.AllDone = false;             
            revObj.messages='Document is not voided. ' + e + ' ' + e.getLineNumber();
            return revObj;
        
        }



    }
    @RemoteAction
    public static ResultVoidWithoutAEL VoidWithoutAEL(id voidAEId, string guid){
        ResultVoidWithoutAEL revObj = new ResultVoidWithoutAEL();
    
        try{
            SOQLUtil soql = new SOQLUtil ( 'Accounting_Entry__c' ) ;
            soql.addFields ( new Set<String> { 'id','Name','total_lines__c' } ) ;
            soql.setWhereClause ( ' Id =: voidAEId and Related_Accounting_Entry__c = null ' ) ;
            List<Accounting_Entry__c> voidAE = Database.query ( soql.getQuery () ) ;
            AccountingEntryService.getInstance().AccountingEntryReversal(AccountingEntryService.AEReverseType.AEVoid, voidAE, guid); 
            revObj.AllDone = true;              
            revObj.messages='Document is successfully voided.';            
        }
        catch(exception e){
            revObj.AllDone = false;             
            revObj.messages='Document is not voided. ' + e + ' ' + e.getLineNumber();            
        }
            return revObj;
    }
    
    
    
    public string getguid(){
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        system.debug('guid: ' + guid);
        return guid;
    }
    
}