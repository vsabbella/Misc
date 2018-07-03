public with sharing class SDAccountingCon extends BaseController{
    
 
    public string theSourceDocId { set;get;}
    public string theSourceDocTypeName{get;set;}
    public string SourceDocName { get; private set; }
    public id FromCompanyId{ get; private set; }
    public id ToCompanyId{ get; private set; }
    public string FromCompanyName{ get; private set; }
    public string ToCompanyName{ get; private set; }

    private static String kHexChars = '0123456789abcdefABCDEF';
    private static string safeChars = 'ABCDFGHJKLMNPQRSTUVWXYZ123456789';
    
    //Vars to get the sobject details
    public Schema.Sobjecttype sType;
    public List<sObject> sObjLines;
    public type t;
    private SchemaUtil util = SchemaUtil.getInstance();
    public static SchemaUtil util = SchemaUtil.getInstance();
    public sObject sObj; 
    public datetime loaddt;
    public List<Sobject> sObjList;   
    public string NamespaceUU { get { return KSE.NamespaceUU; }} 
    public boolean hasHistorical;
    public boolean hasTotalNumberOfLines;


    //Serialized Var used by page javascript vars
    public string AutonumberChunks{set;}
    public string recordser{get;set;}      

    
    //Boolean Vars controlling page remote method invocation
    public boolean RenderExisting {get; set;}
    public boolean RenderReview{get; set;}
    public boolean deletePoller{get;set;}
    public boolean isValidAE{get;set;}


    //AE vars
    public Apexpages.StandardController con;
    public Accounting_Entry__c record {get; set; }  
    public id draftAEIdToDel{get;set;}
    public list<id> draftAEIdsToDel{get;set;}
    public string draftAEIdsSer{get;set;}
    public string guid{get;set;}
    

    //Progress bar metrics
    public Integer pollCounter=0;
    public decimal Linecount{get;set;}
    public decimal DraftLineCount{get;set;}
    public integer size{get;set;}//Number of chunks
    public integer NumberOfRetries{get;set;}

    public class SDAEException extends Exception{}


    
    public class resultChunkObject
    {
        Integer NextChunkIndex=0;
        decimal progress=0;
        
        list<accounting_entry__c> AEs;
        list<Id> AEIDs;
        list<Id> AESDraftIds;
        decimal draftCount;
        
        boolean RenderReview=false;
        boolean hasDrafts=false;
 
        @testvisible integer reverseSize;
        @testvisible string reverseChunkMap;
        @testvisible boolean hasReverse  =false;
        decimal AELineCount;
        @testvisible ID voidAEId;       
        string Messages='';
        string logs='';
       
    }
    
    public class ResultChunkDel
    {
        Boolean ChunkDelete=false;
        Boolean AllDone=false;
        Boolean AESDraftDel=false;
        Decimal Progress;
        string Messages='';

        
    }
/*    public class ResultChunkReverse
    {
        Integer NextChunkIndex=0;
        Boolean ChunkReverse=false;
        Boolean AllDone=false;
        Decimal Progress;
        @testvisible string Messages='';
       
    }*/
        
        
   public SDAccountingCon()
    { 
        loadDt = system.now();
        deletePoller=false;
        RenderExisting=false;
        
        theSourceDocId = ApexPages.currentPage().getParameters().get('id');
        sType =util.getSObjectType(theSourceDocId); 
        theSourceDocTypeName =sType.getDescribe().getLocalName(); 
    }
    
    /* the following allow this controller to be called from several pages and send 
     * the user to the actual preview page with the ID passed along
     */
    public SDAccountingCon(Apexpages.standardcontroller c) 
    {
        loadDt = system.now();
        deletePoller=false;
        RenderExisting=false;
        
        theSourceDocId = ApexPages.currentPage().getParameters().get('id');
        sType =util.getSObjectType(theSourceDocId); 
        theSourceDocTypeName =sType.getDescribe().getLocalName(); 

    } 
    
    public string getAEHeaderFieldList() {
        String aeHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        
        // get the ae header field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Accounting_Entry__c', 'Preview');
        
        for (Integer i = 0; i < fieldInfoList.size(); i++){
            fieldInfoList[i].editable = false;
        }
        
        fieldInfoList.remove(0); // Remove Id field from the list
        
        aeHeaderFieldList = JSON.serialize(fieldInfoList);
        
        return aeHeaderFieldList;
    }
    
    /*List of getter setter required by remote actions*/
    public id gettheSourceDocIdPg()
    {
        return ApexPages.currentPage().getParameters().get('id');
    }
    public string gettheSourceDocNamePg()
    {
        Schema.Sobjecttype sType=util.getSObjectType(gettheSourceDocIdPg());
        
        return sType.getDescribe().getLocalName();
    }
   //Commenting out as we are not using GUID
    public string getGUID()

    {

    Blob b = Crypto.GenerateAESKey(128);
    String h = EncodingUtil.ConvertTohex(b);
    guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
    system.debug('guid: ' + guid);
    return guid;
    }
    
    //Page Action Method--
    //1-->gets Sobj details 
    //2-->Handles Drafts and creates Stub Header
    //3-->Validates sobj and calls chunking Logic
    public void populateSobjDetails()
    {
        try
        {
            isValidAE=true;
            id rid = theSourceDocId; 
            
            SchemaUtil util = SchemaUtil.getInstance();
            Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(sType.getDescribe().fields.getMap());
            hasHistorical = fieldsMap.containsKey('historical__c');                     
            hasTotalNumberOfLines = fieldsMap.containsKey('Total_Number_of_Lines__c'); 
            
            SOQLUtil soql = new SOQLUtil(theSourceDocTypeName,false); 
            set<string> QueryFields = new set<string>();                          
            
            if(hasHistorical) 
            {
                QueryFields.add('Historical__c');
            }            
            if(hasTotalNumberOfLines)   
            {
                QueryFields.add('Total_Number_of_Lines__c');                
            }    
            
            //FIN-1149 add status filter to ensure that only Active entries are picked to validate if the associated period is closed.If period closed we display the the active AE.
            if(mSourceDocToType.get(theSourceDocTypeName)!='NoType')
            {
                string SDType = mSourceDocToType.get(theSourceDocTypeName);   
                QueryFields.addAll(new set<string>{'id', 'name', 'finalized__c','Finalized_Date__c' , 'Transaction_Date__c','Posting_Date__c' ,
                                                         'Currency__c' ,SDType});
      
                soql.addFields(QueryFields);            
                soql.setWhereclause ('id = :rid') ;
                soql.setLimit(2);
                soql.setOrderBy(new map<string,soqlutil.SortOrder>{'CreatedDate'=>soqlutil.SortOrder.SORTASC});
                
                SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');                
                childRel.addFields ( new set<string>{'Id', 'Period__r.Closed__c', 'Period__r.Permanently_Closed__c'});
                childRel.setWhereClause ( 'status__c=\'Active\'');
                soql.addChildRelationship(childRel);                      
                sObjList = Database.Query(SOQL.getQuery());           
            }
            else
            {
                QueryFields.addAll(new set<string>{'id', 'name', 'finalized__c','Finalized_Date__c' , 'Transaction_Date__c','Posting_Date__c' ,'From_Company__c' ,'To_Company__c' ,
                                                    'From_Company__r.Name' ,'To_Company__r.Name' , 'Currency__c' });
                soql.addFields(QueryFields);
                soql.setWhereClause ('id = :rid');
                soql.setLimit(1);
                
                SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');                
                childRel.addFields( new set<string>{'Id', 'Period__r.Closed__c', 'Period__r.Permanently_Closed__c'});
                childRel.setWhereClause ( 'status__c=\'Active\'');
                soql.addChildRelationship(childRel);    
               
                sObjList = Database.Query(SOQL.getQuery());           
            }
            sObj = sObjList[0];
            SourceDocName = (string) sObj.get('Name');
            list<Id> companyIdList= new list<Id>();
            if(util.fieldExists(theSourceDocTypeName,'From_Company__c')){          
                FromCompanyId  = (id)sObj.get('From_Company__c');
                companyIdList.add(FromCompanyId);
            }
            if(util.fieldExists(theSourceDocTypeName,'To_Company__c' )){          
                ToCompanyId = (id)sObj.get('To_Company__c');
                companyIdList.add(ToCompanyId);
            }
            map<Id,Company__c> companyMap = new Map<Id, Company__c> ([select id, name from Company__c where id in:companyIdList]);
            if(companyMap.containsKey(FromCompanyId)){
                FromCompanyName = companyMap.get(FromCompanyId).Name;
            }
            
            if(companyMap.containsKey(ToCompanyId)){
                ToCompanyName = companyMap.get(ToCompanyId).Name;
            }

            if(hasTotalNumberOfLines)
            {
             Linecount = (decimal)sObj.get('Total_Number_of_Lines__c')  * 2;                   
            }
            else
            {
             Linecount=1000;
            }

            SOQLUtil soql1 = new SOQLUtil('accounting_entry__c',false);                
            
            soql1.addFields(new set<string>{'id','name','status__c','total_lines__c','batchjobid__c' });
            soql1.setWhereClause (string.escapeSingleQuotes(theSourceDocTypeName) + ' = :theSourceDocId '+'and status__c =\'Draft\'');      
            String DraftAEQuery = soql1.getQuery();    
            list<accounting_entry__c> AEinDraft = database.query(DraftAEQuery);
            if(AEInDraft.size()>0)
            {
              checkDraftSourceThreads(new map<id,accounting_entry__c>(AEinDraft));
            }

            ValidateSobj();
           
            getAutonumberChunks();

            getGUID();
            
            NumberOfRetries=getRetries();

        }
        catch(Exception Ex)
        {
            fatal( 'Error Generating Accounting Entry -'+ ex.getMessage() + ex.getLineNumber() );
            
        }
                            
    }

    public void checkDraftSourceThreads(map<id,Accounting_Entry__c> mDraftAEs)
    {
        //Check if these drafts are part of Accounting batch jobs
        //KNDY-10268 - deprecating bank file and bank file line objects so removed BankAccountingBatch class//'BankFileAccountingBatch', 
        set<string> accountingJobNames = new set<string>{'JournalEntryAccountingBatch', 'CustomerInvoiceAccountingBatch', 'CustomerReceiptAccountingBatch',  
                                                            'POReceiptAccountingBatch', 'InvoiceAccountingBatch', 'SupplierInvoiceAccountingBatch', 'SupplierPaymentAccountingBatch', 
                                                            'InventoryChangeAccountingBatch', 'FixedAssetDepreciationAccountingBatch', 'FixedAssetAdjustmentAccountingBatch',
                                                            'AccountingEntryVoidBatch'};
        set<string> runningJobIds = new set<string>();
        //Check with RS .Should we consider queued also?
        List<AsyncApexJob> runningJobs = [SELECT Id FROM AsyncApexJob WHERE ApexClass.Name IN :accountingJobNames AND JobType = 'BatchApex' AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')];
        for(AsyncApexJob job : runningJobs){
            runningJobIds.add(job.Id); //Check with RS: AsyncApexJob only stores 15 Chars
        }

        //Accumulate draft Ids generated by Batch runs.
        SOQLUtil soql = new SOQLUtil('accounting_entry__c',false);                
        soql.addFields(new set<string>{'id','name','status__c','total_lines__c','batchjobid__c' });
        soql.setWhereClause (string.escapeSingleQuotes(theSourceDocTypeName) + ' = :theSourceDocId '+'and status__c =\'Draft\' and   (batchjobid__c NOT IN  :runningJobIds AND  ( NOT batchjobid__c  like \'%-%\'))');      
        String DraftAEQuery = soql.getQuery();                      
        system.debug('DraftAEQuery'+DraftAEQuery);      
        list<accounting_entry__c> CleanUpDrafts = database.query(DraftAEQuery);
        map<id,accounting_entry__c> mcleanupDraft = new map<id,Accounting_Entry__c>(CleanUpDrafts);        
        draftAEIdsToDel= new list<id>();
        DraftLineCount=0;
//        for(accounting_entry__c de:mcleanupDraft.values())
//       {
//          draftAEIdsToDel.add(de.id);
//          DraftLineCount=DraftLineCount+de.total_lines__c;
//        }

        draftAEIdsSer=JSON.serialize(draftAEIdsToDel);

        //Check if this SD in scope for any of the batches.
        SOQLUtil soql1 = new SOQLUtil('accounting_entry__c',false);                
        soql1.addFields ( new set<string>{'id','name','status__c','total_lines__c','batchjobid__c' });
        soql1.setWhereClause ( string.escapeSingleQuotes(theSourceDocTypeName) + ' = :theSourceDocId '+'and status__c =\'Draft\' and  (batchjobid__c  IN  :runningJobIds )');      
                  
        String BatchAEQuery = soql1.getQuery();        

        system.debug('batchjobid'+runningJobIds);
        list<accounting_entry__c> AEsInBatch = database.query(BatchAEQuery);
        if(AEsInBatch.size()>0)
        {
                    fatal( 'The Accounting is being generated by a batch.Please try again later.' );
        }

    }   
    //Get number of retries for parallel chunks from custom setting
    public static Integer getRetries() {
        Integer batchSize = 4; 

        Integer minValue = 1;   
        Integer maxValue = 100; 
        
        Configuration__c c = Configuration__c.getValues('GenerateAERetries');
        //attempt to parse the string config value into an integer and make sure it is between min/max
        //if not we are just going to use the default
        if (c != null) {
            Integer configBatch;
            try {configBatch = Integer.valueOf(c.Value__c);} catch (Exception e) {}
            if (configBatch != null) {
                if ( (configBatch >= minValue) && (configBatch <= maxValue) ) {
                    batchSize = configBatch;
                }
            }
        }
        return batchSize;               
    }   
     public void ValidateSobj()
     {
                    
            List<Accounting_Entry__c> aes = sObj.getSObjects('Accounting_Entries__r');
            if(aes != null){
                for(Accounting_Entry__c ae : aes){
                    if(ae.Period__r.Closed__c || ae.Period__r.Permanently_Closed__c){
                        //closedPeriod = true;
                        setAEData();

                    }
                }
            }
            // check for finalized and accounted flags now
            if ( (boolean) sObj.get('Finalized__c') == false )
            {

                      fatal( Label.Record_not_finalized );

            }
            
            
            if(hasHistorical){
                if((Boolean)sObj.get('Historical__c'))
                {
                    fatal( 'Accounting cannot be generated on a Historical ' + sObj.getSobjectType().getDescribe().getLabel() );
                }
            }
            
     }
    void fatal( string msg ) { 
        isValidAE=false;
        ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.FATAL,msg));
    }
    /*Delete Drafts*/
    @remoteaction
    public static ResultChunkDel deleteDrafts(id theSourceDocId,list<list<id>> DraftAEsToDel,decimal DraftCount)
    {
           
           //check scope of batch then dont do remoting     
        string rid = theSourceDocId; 
        // by listing all the document object names we can work with any related record passed in
        string wherestr = String.join(util.relatedCustomObjects('Accounting_Entry__c'),' =:rid OR ') +' = :rid ';
        
        string q = util.generateQueryFromFieldSet( 'Accounting_Entry__c',
                                                  new set<string>{'Preview'}, 
                                                  new set<string>{'id','Transaction_Type__c', 'Company__c', 'Company__r.Id', 'total_lines__c','Company__r.Name'}, '(' + wherestr + ')  AND related_accounting_entry__c = null '); 
        
       SOQLUtil soql = new SOQLUtil('accounting_entry__c',false);                
       soql.addFields(new set<string>{'id','Transaction_Type__c', 'Company__c', 'Company__r.Id', 'total_lines__c','Company__r.Name'});
       soql.addFields('Preview');
      
       list<string> instr = new list<string>(); 
       list<id> aeids = new list<id>(DraftAEsToDel[0]); 
       system.debug('instr ****  ' + DraftAEsToDel[0]);
        
       soql.setWhereClause ( '('+wherestr +') AND related_accounting_entry__c = null ' + ' AND ID IN: aeids' );
       soql.setSearchRecycle(true);
       soql.setOrderBy(new map<string,soqlutil.sortOrder>{'CreatedDate'=>soqlutil.sortOrder.SORTDESC});  
                
       list<accounting_entry__c> tmpAE = database.query(soql.getQuery());     
        
        system.debug('tmpAE'+tmpAE + '  soql.getQuery() ' + soql.getQuery() + '  DraftAEsToDel' + DraftAEsToDel + '  rid' +rid);

        ResultChunkDel Result = new ResultChunkDel();
        if(tmpAE.size()>0)
       {
            decimal currLineCount =tmpAE[0].total_lines__c;
            list<accounting_entry_line__c> tmpAELines=[select id,name from accounting_entry_line__c where accounting_entry__c in :DraftAEsToDel[0] limit 1000];
            try
            {
           system.debug('tmpAELines'+tmpAELines);
                if(tmpAELines.size()>0)
                {
                    ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.INFO, 'There were draft accounting  entries found.Deleting Drafts.Please dont refresh the page'));
                    result.Progress=DraftCount-currLineCount;
                    delete tmpAELines;
                    result.ChunkDelete=true;
                    result.AllDone=false;
    
                }
                else //All Lines Deleted
                {
                    result.Progress=DraftCount;
                    delete tmpAE;
                    result.ChunkDelete=true;
                    result.AllDone=true;
    
                } 
                  result.Messages='Accounting generated.Deleting Draft Accounting entries.Please dont refresh the page';                    
               
           }
            catch(Exception ex)
           {//Expecting any concurrency del issues if delete batch has also got same scope
               ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.INFO, 'Error Generating Accounting Entry'+ex.getMessage()));
               result.ChunkDelete=false;
               result.AllDone=false;
               result.Messages='Error Generating Accounting Entry - '+ex.getMessage() + ex.getLineNumber() ;
               
           }

       }
       else
       {
               result.Messages='Error Generating Accounting Entry in draft deletion';
               result.ChunkDelete=false;
               result.AllDone=false;

       }

         return result;
    }
    //Used to render AE if it already exists and is in closed period
    public void setAEData()
    {


        string rid = theSourceDocId; 
        // by listing all the document object names we can work with any related record passed in
        string wherestr = String.join(util.relatedCustomObjects('Accounting_Entry__c'),' =:rid OR ') +' = :rid ';
        
        
       SOQLUtil soql = new SOQLUtil('accounting_entry__c',false);                
       soql.addFields ( new set<string>{'id','Transaction_Type__c', 'Company__c', 'Company__r.Id', 'total_lines__c','Company__r.Name'});
       soql.addFields( 'Preview');
       soql.setWhereClause ( '('+wherestr +') AND related_accounting_entry__c = null AND status__c=\'Active\'');
       soql.setOrderBy(new map<string,SOQLUtil.SortOrder>{'CreatedDate'=>SOQLUtil.SortOrder.SORTDESC});
       soql.setLimit(1);
       
       string q = soql.getQuery();      
        
        List <Accounting_Entry__c> tmp = database.query ( q );
        system.debug('tmp'+tmp);
        system.debug('rid'+rid);
        system.debug('q'+q);
        if(tmp.size()>0)
        {
          record=tmp[0];
          system.debug('record'+record);
          recordser=json.serialize(record);
          RenderExisting=true;              
        }
        else
        {
            //TODO:This happens only if data fixes on customer side go wrong.Check with SK If it is valid scenario to display.
             fatal( 'The period is closed but no active Accounting Entry is found.');           
        } 
                

    }
    /*Reverse AEL*/
 /*   @remoteaction
    public static ResultChunkReverse reverseAE(id voidAE,integer CurrChunkIndex,Integer TotalChunks,string min,string max,boolean doVoid,string guid)
    {
        ResultChunkReverse revObj = new ResultChunkReverse();
        try
        {
            if(currChunkIndex>=TotalChunks)
            {
                    //Empty remote call.Defering and waiting for del drafts to complete
            }
            else 
            {
                 list<accounting_entry_line__c> AELReverseInScope=[select id,name from accounting_entry_line__c
                                                                  where Accounting_Entry__c=:voidAE
                                                                  and autonumber__c>=:min and autonumber__c<=:max];

                if(doVoid)//Indicates SD is  not JournalEntry-AccrualManual
                {
                   AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELReverseInScope,guid);
                }
                else
                {
                   AccountingEntryService.getInstance().AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEReverse, AELReverseInScope,guid);
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

                revObj.progress=reverseAEGenProgress(voidAE);
                revObj.messages='Creating Reversal accounting entries.Please dont refresh the page';
                revObj.ChunkReverse=true;
        }
        catch(Exception ex)
        {
            revObj.messages=ex.getMessage()+ ' on Line '+ex.getLineNumber();
            revObj.ChunkReverse=false;
            revObj.progress=-1;
            revObj.AllDone=false;

        }
        return revObj;

    }*/
    

    /*Generate Accounting Remoting method and two static Helpers*/
    @RemoteAction 
    public  static resultChunkObject generateAccounting(id SDID,string guid,string SDName,integer CurrChunkIndex,Integer TotalChunks,string max,string min){
       // system.debug('CurrMinMaxSer'+CurrMinMaxSer);
        Id sourceDocId = SDID;
        string sourceDocName = SDName;

         system.debug('min'+min);                
         system.debug('SDID'+SDID);
         system.debug('SDName'+SDName);
         system.debug('CurrChunkIndex'+CurrChunkIndex);
         system.debug('max'+max);
         resultChunkObject obj = new resultChunkObject();
        AccountingService asv;

       try
       {
            if(AccountingService.mAccountingWorkers.containsKey(sourceDocName)){
                //string sdlQuery = 'SELECT Id, name, '+sourceDocName+' FROM ' + AccountingService.mHeaderToLines.get(sourceDocName) + ' WHERE ' + sourceDocName + ' = :sourceDocId AND autonumber__c >= :min AND autonumber__c <= :max';
                SOQLUtil soql = new SOQLUtil(AccountingService.mHeaderToLines.get(sourceDocName),false);
                soql.addFields(new set<string>{'id',sourceDocName, 'name'});
                soql.setWhereClause (string.escapeSingleQuotes(sourceDocName) +' = :sourceDocId AND autonumber__c >= :min AND autonumber__c <= :max');
                
                string sdlQuery =soql.getQuery();
                List<sObject> sourceDocLines = Database.query(sdlQuery);
                system.debug('sourceDocLines: ' + sourceDocLines);
                Type t = Type.forName(AccountingService.mAccountingWorkers.get(sourceDocName));
                asv = (AccountingService)t.newInstance();
                //pass guid here
                asv.batchJobID=guid;
                asv.isPreview = true;
                asv.execute(sourceDocLines);    

                
            }
            obj.AEIDs = new list<id> ();
            obj.AEs=new list<accounting_entry__c>();
            if(CurrChunkIndex==TotalChunks-1)
            {
                list<accounting_entry__c> activeAEs = loadInterCompanyAE(SDID,sourceDocName);
                //Additional Check to see if AE exist before rendering review
                If(activeAEs != null){
                    if(activeAEs[0]!=null)
                    {
    
                        list<Id> delAEId = new list<Id>(asv.deleteAEIds);
                        for(accounting_entry__c ae : activeAEs){
                        obj.AEIDs.add(ae.id);
                        obj.AEs.add(ae);                                        
                        }
                        obj.renderReview=true;//Controls del draft or grid render remote calls
                        if(delAEId.size()!=0)
                        {
                            obj.AESDraftIds= new list<id>(delAEId);//As there is Only one AE for this SD
                            list<accounting_entry__c> draftAE=[select id,total_lines__c from accounting_entry__c where id in :delAEId];
                            if(draftAE.size()>0)
                            {
                              obj.hasDrafts=true;
                              for(accounting_entry__c ae:draftAE){
                                if(obj.draftCount != null)
                                    obj.draftCount = obj.draftCount + ae.total_lines__c;
                                else
                                    obj.draftCount = ae.total_lines__c;
                              }
     
                            }
                        }
                        else
                        {
                            obj.hasDrafts=false;//Replay has resulted in Active AE.No Need to push in this id
                        }
                    }
                    list<id> voidAEIds=new list<id>();

                    util = SchemaUtil.getInstance();
                    Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(util.getSObjectType(sourceDocId).getDescribe().fields.getMap());
                    boolean hasVoid = fieldsMap.containsKey('void__c');                         
                    
                    Boolean  hasAccrual= sourceDocName=='Journal_Entry__c'?true:false;
                    string AccrualField = hasAccrual ? 'type__c' : '';
                    string voidField = hasVoid? 'void__c':'';
                    SOQLUtil soql = new SOQLUtil(sourceDocName,false);
                    set<string> queryFields = new set<string>{'id','name'};                                         
                    if(hasVoid)
                    {
                     queryFields.add(voidField) ;                       
                    }
                    if(hasAccrual)
                    {
                     queryFields.add(AccrualField);                         
                    }
                    soql.addFields(queryFields);
                    soql.setWhereClause ( 'id=:sourcedocid');
                    sobject sobj= database.query (soql.getQuery()) ;
                                    
                    if(hasVoid){
                        if((Boolean)sobj.get('void__c')){

                            //If AE is just header without lines call header reversal method of service
                               voidAEIds.add(activeAEs[0].Id);
                        }
                    }
                    if(hasAccrual)
                    {

                            if((string)sobj.get('type__c')=='Accrual - Manual')
                            {
                            //If AE is just header without lines call header reversal method of service
                            //If AE is just header without lines call header reversal method of service
                            //Uncommented below as Accounting Service doesnt handle Journal Accruals.Check with SK if we need to make service change instead as Accounting Batch doesn't handle this scenario.
                              if(activeAEs[0].total_lines__c==0)
                                {
                                   AccountingEntryService.getInstance().AccountingEntryReversal(AccountingEntryService.AEReverseType.AEReverse,new list<accounting_entry__c>{activeAEs[0]} );
                                }
                               else //Call chunk remote method for calling line reversal method
                                {
                                   voidAEIds.add(activeAEs[0].Id);
     
                                }
                            }
                    }


                    if(voidAEIds.size()>0)
                    {
                        integer chunkSize = 2000;

                        //Get autonumber chunks for AEL to reverse.
                        List<Map<string, string>> chunks = new List<Map<string, string>>();
                        
                        if(activeAEs[0].total_lines__c>0)
                        {
                            list<sobject> sobjMin=[select id,autonumber__c from accounting_entry_line__c where Accounting_Entry__c in :voidAEIds ORDER BY autonumber__c ASC limit 1];
                            list<sobject> sobjMax=[select id,autonumber__c from accounting_entry_line__c where Accounting_Entry__c in :voidAEIds ORDER BY autonumber__c DESC limit 1];
    
    
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
                            string ChunkJSON = JSON.serialize(chunks);
                            obj.hasReverse=true;
                            obj.reverseChunkMap=ChunkJSON;
                            obj.voidAEId=voidAEIds[0];
                            obj.AELineCount=activeAEs[0].total_lines__c;
                        }
                        else
                        {
                             obj.hasReverse=false;//No Need to call line reversal chunk remote method.Accounting Service takes care of reversing the header.
                            
                        }
                    }
                    obj.messages='Accounting is being generated.Please do not refresh page or press  Back button of browser';

                   
                }
                else
                {
                    obj.renderReview=false;
                    obj.messages='Error Generating Accounting entry in Accounting worker ';
                    obj.logs=string.join(asv.getLogs(),', ');
                    //Some error as still Active AE has not been generated.User gets this displayed if there is no exception.

                }
                
            }
           else
           {
               obj.progress=AEGenProgress(SDID,guid);
               obj.messages='Accounting is being generated.Please do not refresh page or press  Back button of browser';
           }
           Integer nextChunkStrt = CurrChunkIndex+1;
           obj.NextChunkIndex=nextChunkStrt;
           
               
       }
        catch(Exception ex)
        {
            obj.renderReview=false;
            obj.progress=-1;  //Prevents Next chunk call.       
            obj.messages=ex.getMessage()+ ' on Line '+ex.getLineNumber()+' Logs '+asv.getLogs();
        }
           
        return obj;

    }
    
    public  static Accounting_Entry__c loadAE(id theSourceDocId, id theCompanyID) { 
        system.debug('loadAE');

        string rid = theSourceDocId; 
        // by listing all the document object names we can work with any related record passed in
        string wherestr = String.join(util.relatedCustomObjects('Accounting_Entry__c'),' =:rid OR ') +' = :rid ';
        
        SOQLUtil soql = new SOQLUtil('Accounting_Entry__c',false);
        soql.addFields ( new set<string>{'id','Transaction_Type__c', 'Company__c', 'Company__r.Id', 'total_lines__c','Company__r.Name'});
        soql.addFields( 'Preview');
        soql.setWhereClause ( '('+wherestr +') AND related_accounting_entry__c = null AND status__c=\'Active\' AND company__c = \'' + theCompanyID +'\'');
        soql.setLimit(2);
        soql.setOrderBy(new map<string,soqlutil.SortOrder>{'CreatedDate'=>soqlutil.SortOrder.SORTASC});
        String q =  soql.getQuery();
        system.debug('q'+q);
               
        List <Accounting_Entry__c> tmp = database.query ( q );
        system.debug('tmp'+tmp);
        if ( tmp.size() == 0   ) {
           ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.INFO, 'Accounting is being generated.Please dont refresh the page.'));                 
            return null;
        } else {
            return tmp[0];
        }
    }
    public  static list<Accounting_Entry__c> loadInterCompanyAE(id theSourceDocId, string sourceDocName) { 
        system.debug('loadInterCompanyAE');

        string rid = theSourceDocId; 
        // by listing all the document object names we can work with any related record passed in
        string wherestr = String.join(util.relatedCustomObjects('Accounting_Entry__c'),' =:rid OR ') +' = :rid ';
        
        SOQLUtil soql = new SOQLUtil('Accounting_Entry__c',false);
        soql.addFields ( new set<string>{'id','Transaction_Type__c', 'Company__c', 'Company__r.Id', 'total_lines__c','Company__r.Name'});
        if(sourceDocName == 'Invoice__c' || sourceDocName == 'Payment__c'){
                soql.addFields(new set<string>{sourceDocName.replace('__c','__r') +'.from_company__c',sourceDocName.replace('__c','__r')+ '.to_company__c'});                   
        }
        soql.addFields( 'Preview');
        soql.setWhereClause ( '('+wherestr +') AND related_accounting_entry__c = null AND status__c=\'Active\' ');
        soql.setLimit(2);
        soql.setOrderBy(new map<string,soqlutil.SortOrder>{'CreatedDate'=>soqlutil.SortOrder.SORTASC});
        String q =  soql.getQuery();
        system.debug('q'+q);
               
        List <Accounting_Entry__c> tmp = database.query ( q );
        List <Accounting_Entry__c> tmpToReturn = new list<Accounting_Entry__c>();
        for (Accounting_Entry__c ae: tmp){
            Id fromCompany;
            if(sourceDocName == 'Invoice__c'){ 
                Invoice__c inv = (invoice__c)ae.getSobject(sourceDocName.replace('__c','__r'));
                fromCompany = (id)inv.get('from_company__c');               
                
            }else if(sourceDocName == 'Payment__c'){ 
                Payment__c payment = (Payment__c)ae.getSobject(sourceDocName.replace('__c','__r'));
                fromCompany = (id)payment.get('from_company__c');               
                
            }
            if(fromCompany != null && ae.company__c == fromCompany){
                tmpToReturn.add(ae);
            }
        }
        for (Accounting_Entry__c ae: tmp){
            Id toCompany;
            if(sourceDocName == 'Invoice__c'){ 
                Invoice__c inv = (invoice__c)ae.getSobject(sourceDocName.replace('__c','__r'));
                toCompany = (id)inv.get('to_company__c');               
                
            }else if(sourceDocName == 'Payment__c'){ 
                Payment__c payment = (Payment__c)ae.getSobject(sourceDocName.replace('__c','__r'));
                toCompany = (id)payment.get('to_company__c');               
                
            }
            if(toCompany != null && ae.company__c == toCompany){
                tmpToReturn.add(ae);
            }
        }
        
        system.debug('tmpToReturn'+tmpToReturn);
        if ( tmpToReturn.size() == 0   ) {
           ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.INFO, 'Accounting is being generated.Please dont refresh the page.'));                 
            return null;
        } else {
            return tmpToReturn;
        }
    }
      //Returns source doc line processed count for draft AE in construction
      //If -1 then some error has occured in the chunk.User gets exception message if thrown  and processing stops
      public static decimal AEGenProgress(id SDID,string Guid)
    {
        string rid = SDID; 
      
        // by listing all the document object names we can work with any related record passed in
        string wherestr = String.join(util.relatedCustomObjects('Accounting_Entry__c'),' =:rid OR ') +' = :rid ';
  
        SOQLUtil soql = new SOQLUtil('Accounting_Entry__c',false);
        soql.addFields(new set<string>{'id','Transaction_Type__c', 'Company__c', 'Company__r.Id', 'total_lines__c','Company__r.Name','Source_Lines_Processed__c','batchjobid__c'});
        soql.addFields('Preview');
        soql.setWhereClause ('('+wherestr +') AND related_accounting_entry__c = null AND ( status__c=\'Draft\') AND batchjobid__c=:guid');
        soql.setLimit(2);
        soql.setOrderBy(new map<string,SOQLUTIL.SortOrder>{'CreatedDate' => SOQLUTIL.SortOrder.SORTASC});
        soql.setSearchRecycle(true);
        list<Accounting_Entry__c> tmpAE = database.query ( soql.getQuery() ) ;                  


        if(tmpAE.size()>0)
        {   decimal currcount;
                        
            for(Accounting_Entry__c ae: tmpAE) {
                if(currcount != null){
                    currcount = currcount + ae.Source_Lines_Processed__c;
                }else{
                    currcount = ae.Source_Lines_Processed__c;
                }
          
          }           
          ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.INFO, 'Accounting is being generated.Please dont refresh the page.'));                 
          system.debug('inside update'+ currcount);
          return currcount;
            
        }
     
        else //Check if Active AE is generated
        {
            SOQLUtil soql1 = new SOQLUtil('Accounting_Entry__c',false);
            soql1.addFields( new set<string>{'id','Transaction_Type__c', 'Company__c', 'Company__r.Id', 'total_lines__c','Company__r.Name','Source_Lines_Processed__c','batchjobid__c'});
            soql1.addFields('Preview');
            soql1.setWhereClause ('('+wherestr +') AND related_accounting_entry__c = null AND ( status__c=\'Active\') ');
            soql1.setLimit(2);
            soql1.setOrderBy(new map<string,SOQLUTIL.SortOrder>{'CreatedDate' => SOQLUTIL.SortOrder.SORTASC});          
            soql1.setSearchRecycle(true);        
            list<accounting_entry__c> ActiveAE = database.query (soql1.getQuery());            
            if(ActiveAE.size()>0)
            {
                throw new SDAEException('Active AE');
                ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.FATAL, 'Active AE'));           
            }
            else//No Active nor draft
            {
                throw new SDAEException('Error generating Accounting Entry. No Active or Draft entry found.');                       
                ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.FATAL, 'Error generating Accounting Entry. No Active or Draft entry found.'));           

            }
            return -1;
        
           
        }
   

    }   
      //Returns AEL count for reversal AE in construction
      //If -1 then some error has occured in the chunk.User gets exception message if thrown  and processing stops
/*      public static decimal reverseAEGenProgress(id voidAE)
    {
                

        list<accounting_entry__c> reverseAE = [select id,name,total_lines__c from Accounting_Entry__c where related_accounting_entry__c=:voidAE];
        if(reverseAE.size()>0)
        {               
                      
          decimal currcount = reverseAE[0].total_lines__c;
          system.debug('inside update'+ currcount);
          return currcount;
            
        }
     
        else //Check if Active AE is generated
        {

            return 0;
        }

    }*/     
    
    
        
    public string getAutonumberChunks(){
        integer chunkSize = 0;
        Configuration__c c = Configuration__c.getValues('AEChunksize');
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
        
       
        Id sourceDocId = Apexpages.currentPage().getParameters().get('Id');
        string sourceDocName = sourceDocId.getSObjectType().getDescribe().getLocalName();        
        string SourceDocLine = AccountingService.mHeaderToLines.get(sourceDocName);
        
        List<Map<string, string>> chunks = new List<Map<string, string>>();
        
        SOQLUtil soql1 = new SOQLUtil(AccountingService.mHeaderToLines.get(sourceDocName),false);
        soql1.addFields( new set<string>{'id','autonumber__c'});
        soql1.setWhereClause(String.escapeSingleQuotes(sourceDocName)+ ' = :sourceDocId ');
        soql1.setOrderBy(new map<string,SOQLUtil.SortOrder>{'autonumber__c'=>SOQLUtil.SortOrder.SORTASC});
        soql1.setLimit(1);
        
        SOQLUtil soql2 = new SOQLUtil(AccountingService.mHeaderToLines.get(sourceDocName),false);
        soql2.addFields ( new set<string>{'id','autonumber__c'});
        soql2.setWhereClause (String.escapeSingleQuotes(sourceDocName)+ ' = :sourceDocId ');
        soql2.setOrderBy(new map<string,SOQLUtil.SortOrder>{'autonumber__c'=>SOQLUtil.SortOrder.SORTDESC});        
        soql2.setLimit(1);        

        string minQuery = soql1.getQuery() ;
        string maxQuery = soql2.getQuery();

        system.debug('minQuery'+minQuery+'maxQuery'+maxQuery);
        
        list<sobject> sobjMin=Database.Query(minQuery);
        list<sobject> sobjMax=Database.Query(maxQuery);

        if(sobjMin.size()>0 && sobjMax.size()>0 )
        {
            integer min=(integer)integer.valueOf(sobjMin[0].get('autonumber__c'));
            integer max=(integer)integer.valueOf(sobjMax[0].get('autonumber__c'));
    
            system.debug('min: ' +min + ' max: ' + max);
            
            integer ref = min;
            while(ref <= max){
                
                Map<string, string> iMap = new Map<string, string>();
                iMap.put('min', prefixIntWithZeros(ref, 10));
                iMap.put('max', prefixIntWithZeros(ref+chunkSize, 10));
                
                ref += chunkSize + 1;
                chunks.add(iMap);
            }
            size=chunks.size();
            string ChunkJSON = JSON.serialize(chunks);  
            return ChunkJSON;

        }
        else
        {
            return null;
        }

        
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
    
    public static String drop_leading_zeros(String passedValue) {
        String return_string = null; //return string for passing back
        if (passedValue != null) { //if the passed value is not null
            return_string = passedValue.trim(); //trim the whitespace from the start and end of the value
            Pattern valid_characters = Pattern.compile('([0-9]+)'); //only numbers
            Matcher check_chars = valid_characters.matcher(return_string); //compare the string to the set of valid characters
            if (check_chars.matches()) { //if we have a somewhat valid number
                if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with a 0 and the length is greater than 1
                    boolean keepChecking = true; //create a boolean variable
                    while (keepChecking) { //if boolean is true
                        if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with 0 and there is more than 1 character
                            return_string = return_string.substring(1); //drop the first character
                        } else { //either the string doesn't begin with 0 or the length is less than or equal to 1
                            keepChecking = false; //stop the loop
                        }
                    }
                }
                if (return_string == '0') { //if the resulting string is now a single '0'
                    return_string = null; //set the string to null
                }
            } else { //otherwise the value passed was not valid
                return_string = null; //set the string to null
            }
        }
        return return_string; //pass back a value
    }    
    /*Kendo Grids */
    @RemoteAction
    public static GridWrapper getGridConfig(Id sourceDocId, Id aeId){
        Accounting_Entry__c ae = [SELECT Id FROM Accounting_Entry__c WHERE Id = :aeId];
        
        // Contract Lines Grid config
        GridRelatedListController.GridRelatedListConfig  config = new GridRelatedListController.GridRelatedListConfig();
        config.uniqueId = 'aeLinesGrid';
        config.title = Label.Accounting_Entry_Lines_Generated;
        config.parentRecord = ae;
        config.parentField = 'Accounting_Entry__c';
        config.objectName = 'Accounting_Entry_Line__c';
        config.fieldset = 'Preview';
        config.readOnlyFields = string.join(SchemaUtil.getInstance().getFieldsFromFieldSetString(Accounting_Entry_Line__c.getSObjectType(), 'Preview'), ',');
        config.buttons = 'search';
        
        List<FieldInfo> fieldInfos = FieldInfo.fetchJsonFieldInfos(config.objectName, config.fieldset, config.readOnlyFields);
        
        return new GridWrapper(config, fieldInfos);
    }
    
    @RemoteAction 
    public static JsonResult getAELines(GridRelatedListController.GridRelatedListConfig config) {
        List<Accounting_Entry_Line__c> result = new List<Accounting_Entry_Line__c>();
        Id parentId = (config.parentRecord != null && String.isNotBlank(config.parentRecord.Id)) ? config.parentRecord.Id : '';
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        //RS - prevent empty field refs in the query from unspecified additional fields in the component
        set<string> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : new Set<String>();
        String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';
         //User can click review AE entry button to view rest of the lines       
        string whereClause = 'Accounting_Entry__c = :parentId limit 5000';
        map<string,SOQLUtil.sortOrder> mFieldToSortOrder = new map<string,SOQLUtil.sortOrder>();
        
        //RS - add sort order and sequence for returned records based on optional component inputs
        if(String.isNotBlank(config.sortField)){
            
            if(String.isNotBlank(config.sortOrder)){
                if(config.sortOrder.toUpperCase()=='ASC')
                {
                  mFieldToSortOrder.put(config.sortField,SOQLUtil.sortOrder.SORTASC);
                }
                else if(config.sortOrder.toUpperCase()=='DESC')
                {
                  mFieldToSortOrder.put(config.sortField,SOQLUtil.sortOrder.SORTDESC);                  
                }
                
            }
        }
        
        if (String.isNotBlank(config.namespace)) {
                util.namespace = config.namespace;
        }
        SOQLUtil soql = new SOQLUtil(config.objectName,false);
        soql.addFields(fieldset);
        soql.addFields(addlFields);
        soql.setWhereClause (whereClause);
        soql.setOrderBy(mFieldToSortOrder);

        String queryString = soql.getQuery();
        result = database.query(queryString);   
        system.debug('result: ' + result);
        
        return new JsonResult(result, result.size());
    }
    
    
    @RemoteAction
    public static GridWrapper getRulesGridConfig(Id sourceDocId, Id aeId){
        Accounting_Entry__c ae = [SELECT Id, Company__c, Company__r.Name, Company__r.Id FROM Accounting_Entry__c WHERE Id = :aeId];
        
        // Contract Lines Grid config
        GridRelatedListController.GridRelatedListConfig  config = new GridRelatedListController.GridRelatedListConfig();
        config.uniqueId = 'rulesGrid';
        config.title = Label.Accounting_Entry_Lines_Generated;
        config.parentRecord = ae.getSObject('Company__r');
        config.parentField = 'Company__c';
        config.objectName = 'Accounting_Rule__c';
        config.fieldset = 'Preview';
        config.readOnlyFields = string.join(SchemaUtil.getInstance().getFieldsFromFieldSetString(Accounting_Rule__c.getSObjectType(), 'Preview'), ',');
        config.buttons = 'search';
        config.addlWhereClause = 'Id IN (SELECT Accounting_Rule__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__c = \'' + String.escapeSingleQuotes(ae.Id) +'\')';
        List<FieldInfo> fieldInfos = FieldInfo.fetchJsonFieldInfos(config.objectName, config.fieldset, config.readOnlyFields);
        
        return new GridWrapper(config, fieldInfos);
    }
    
    @RemoteAction 
    public static JsonResult getRules(GridRelatedListController.GridRelatedListConfig config) {
        List<Accounting_Rule__c> result = new List<Accounting_Rule__c>();
        Id parentId = (config.parentRecord != null && String.isNotBlank(config.parentRecord.Id)) ? config.parentRecord.Id : '';
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        //RS - prevent empty field refs in the query from unspecified additional fields in the component
        set<string> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : new Set<String>();
        String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';
        
        string whereClause = 'Company__c = :parentId ';
        if(config.addlWhereClause != null && config.addlWhereClause != ''){
            whereClause += ' AND (' + config.addlWhereClause.replace('\\', '') + ')';
        }
        map<string,SOQLUtil.sortOrder> mFieldToSortOrder = new map<string,SOQLUtil.sortOrder>();
        
        
        //RS - add sort order and sequence for returned records based on optional component inputs
        if(String.isNotBlank(config.sortField)){
            if(String.isNotBlank(config.sortOrder)){
                if(config.sortOrder.toUpperCase()=='ASC')
                {
                  mFieldToSortOrder.put(config.sortField,SOQLUtil.sortOrder.SORTASC);
                }
                else if(config.sortOrder.toUpperCase()=='DESC')
                {
                  mFieldToSortOrder.put(config.sortField,SOQLUtil.sortOrder.SORTDESC);                  
                }
            }
        }
        
        if (String.isNotBlank(config.namespace)) {
                util.namespace = config.namespace;
        }
        
        SOQLUtil soql = new SOQLUtil(config.objectName,false);
        soql.addFields(fieldset);
        soql.addFields(addlFields);
        soql.setWhereClause(whereClause);
        soql.setOrderBy(mFieldToSortOrder);


        String queryString=  soql.getQuery() ;       
        result = database.query(queryString);   
        
        return new JsonResult(result, result.size());
    }
    
    @RemoteAction
    public static JsonResult saveAction(List<object> updatedList, List<object> newList, List<object> deletedList, List<String> dateFields) {
        
        JsonResult result = new JsonResult();
        return result;
    }
    
    public class GridWrapper{
        public string config;
        public string fieldInfoList;
        
        public GridWrapper(GridRelatedListController.GridRelatedListConfig config, List<FieldInfo> fieldInfoList){
            this.config = JSON.serialize(config);
            this.fieldInfoList = JSON.serialize(fieldInfoList);
        }
    }
    
    public pageReference review(){ 
        
            string company = ApexPages.CurrentPage().getParameters().get('company'); 
            if(company != null && company == 'fromCompany' && FromCompanyid != null){
                return new pageReference('/' + loadAE(theSourceDocId,FromCompanyid).id);
            }
            else if(company != null && company == 'toCompany' && toCompanyid != null){
                return new pageReference('/' + loadAE(theSourceDocId,toCompanyid).id);
            }
            else
                return null;
    }


    public Pagereference close() { return new PageReference( '/' +theSourceDocId ); }


    public PageReference navigateToPreview() { 
        id rid = ApexPages.CurrentPage().getParameters().get('id'); 
        PageReference p = Page.SDAccounting;
        p.getParameters().put('id', rid);
        return p.setRedirect(true);
    }
      //FIN-749 Large data accounting  
      //KNDY-10268 - deprecating bank file and bank file line objects
    public static final map<string, string> mSDToBatchClass = new map<string, string>{
        'Journal_Entry__c'      => 'JournalEntryAccountingBatch',
        'Customer_Invoice__c'   => 'CustomerInvoiceAccountingBatch',
        'Customer_Receipt__c'   => 'CustomerReceiptAccountingBatch',
        'Purchase_Order__c'    => 'PurchaseOrderAccountingBatch',
        'Receiving_Document__c' => 'POReceiptAccountingBatch',
        'Fixed_Asset_Adjustment__c' => 'FixedAssetAdjustmentAccountingBatch',
        'Fixed_Asset_Depreciation__c'   => 'FixedAssetDepreciationAccountingBatch ',
        //'Bank_File__c'          => 'BankFileAccountingBatch',           
        'Invoice__c'            => 'InvoiceAccountingBatch',
        'PAyment__c'            => 'PaymentAccountingBatch',
        'Supplier_Invoice__c'   => 'SupplierInvoiceAccountingBatch',
        'Supplier_Payment__c'   => 'SupplierPaymentAccountingBatch',
        'Shipment__c'           => 'ShipmentAccountingBatch',
        'Work_Order__c'         => 'WorkOrderAccountingBatch',
        'Inventory_Change__c'   => 'InventoryChangeAccountingBatch' 
        //more...
    }; 
    //KNDY-10268 - deprecating bank file and bank file line objects 
    public static final map<string, string> mSourceDocToType = new map<string, string>{
        'Journal_Entry__c'          =>  'Type__c',
        'Customer_Invoice__c'       =>  'Invoice_Type__c',
        'Customer_Receipt__c'       =>  'NoType',
        //'Bank_File__c'              =>  'Type__c',
        'Supplier_Invoice__c'       =>  'Invoice_Type__c',
        'Supplier_Payment__c'       =>  'NoType',
        'Purchase_Order__c'         =>  'Type__c',
        'Work_Order__c'             =>  'NoType',
        'Inventory_Change__c'       =>  'Type__c',
        'Shipment__c'               =>  'NoType',
        'Receiving_Document__c'     =>  'Type__c',
        'Fixed_Asset_Adjustment__c' =>  'NoType',
        'Fixed_Asset_Depreciation__c'=> 'NoType',
        'Invoice__c'                =>  'NoType',
        'Payment__c'                =>  'NoType'
    };  
    
}