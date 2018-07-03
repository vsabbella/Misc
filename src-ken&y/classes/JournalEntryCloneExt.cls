public with sharing class JournalEntryCloneExt {
	
	public string namespace {get;set;}
    public Apexpages.Standardcontroller con {get;set;}
    public integer NumberOfRetries{get;set;}
    public list<Journal_Entry__c> JEtoClone;
    public integer NumberOfLines{get;set;}
	public Journal_Entry__c clonedJE;
	public ID clonedJEId{get;set;}
    public string cloneChunkMap{get;set;}	
	public ID JEToCloneId{get;set;}
    public integer cloneSize{get;set;}
    public decimal JELineCount{get;set;} 
    public JournalEntryCloneExt(Apexpages.Standardcontroller controller){
        this.con = controller;			
		this.namespace = KSE.NamespaceUU;
        id rid = ApexPages.CurrentPage().getParameters().get('id');
        if (rid != null){

            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','Name','Total_Number_Of_Lines__c'
            });
            soql.setWhereClause('id =:rid');
            JEtoClone = Database.query(soql.getQuery());



        	NumberOfLines = integer.valueOf(JEtoClone[0].Total_Number_Of_Lines__c);
 			JEToCloneId = JEtoClone[0].id;
        } 
	}
	
    public class ChunkCloneResult
    {
        public Integer NextChunkIndex=0;
        public Boolean ChunkJEL=false;
        public Boolean AllDone=false;
        public Decimal Progress;
        public string Messages='';
		public integer cloneSize;
        public string cloneChunkMap;
        public decimal JELineCount;
        public ID cloneJEId;
        public ID JEToCloneId;
    }

    public class DeleteCloneResult
    {
        public Boolean AllDone=false;
    }

	public void navigateToClone() {
        id rid = ApexPages.CurrentPage().getParameters().get('id'); 
        Journal_Entry__c oldJE;
        Journal_Entry__c newJE;
        list <Journal_Entry_Line__c> newJELs = new list <Journal_Entry_Line__c>();
        if (rid != null){ 
            string whereClause = 'Journal_Entry__c =: rid';
            string objectName = 'Journal_Entry_Line__c';
			
			SOQLUtil soql = new SOQLUtil(objectName,false);
			soql.addAllFields();
			soql.setWhereClause(whereClause);				
			
			oldJE = (Journal_Entry__c)con.getRecord();
	      	newJE = oldJE.Clone(false,true);
	      	newJE.name = oldJE.name + ' - Clone';
        	newJE.finalized__c = false;
        	newJE.Status__c = 'Open';
        	
        	list<Journal_Entry_Line__c> JELList = Database.query(soql.getQuery()); 
        	if(JELList.size() <= 500){
	        	DML.insertAsUser(newJE);	        	
	        	for(Journal_Entry_Line__c oldjel: JELList){
	        		Journal_Entry_Line__c newjel = oldjel.Clone(false,true,false,false);
	        		newjel.Journal_Entry__c = newJE.id;
	        		newJELs.add(newjel);
	        	}
        		DML.insertAsUser(newJELs);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, '<a href="/'+ newJE.Id+'">' + newJE.Name + '</a>' + ' was created successfully'));
	        }else{
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This Journal Entry Cannot be cloned as it has more than 500 Journal entry Lines.'));
        	}
        }else {
            //return null;
        }
	
	}

   public void prepareJEClone(){
        integer chunkSize = 0;
        Journal_Entry__c oldJE;
		Configuration__c c = Configuration__c.getValues('cloneChunksize');
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
    	NumberOfRetries=KSE.getRetries('cloneAERetries');
        ChunkCloneResult obj = new ChunkCloneResult();
        list <Journal_Entry_Line__c> newJELs = new list <Journal_Entry_Line__c>();

		string fieldstringJE = Schemautil.getInstance().getFieldsforQuery('Journal_Entry__c');
		string fieldstringJEL = Schemautil.getInstance().getFieldsforQuery('Journal_Entry_Line__c');
  		oldJE = (Journal_Entry__c)con.getRecord();
   		clonedJE = oldJE.Clone(false,true,false,false);
      	clonedJE.name = oldJE.name + ' - Clone';
    	clonedJE.finalized__c = false;
        clonedJE.Status__c = 'Open';
    	try {
    	
    		DML.insertAsUser(clonedJE);
	        if(JEtoClone[0].Total_Number_Of_Lines__c > 0){
	            List<Map<string, string>> chunks = new List<Map<string, string>>();
	        
	           
                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
                SOQLUtil soql = new SOQLUtil('Journal_Entry_Line__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'id','autonumber__c'
                });
                soql.setWhereClause('Journal_Entry__c in :JEtoClone');
                soql.setOrderByClause('autonumber__c ASC');
                soql.setLimit(1);
                list<sobject> sobjMin= Database.query(soql.getQuery());



	           
                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
                 soql = new SOQLUtil('Journal_Entry_Line__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'id','autonumber__c'
                });
                soql.setWhereClause('Journal_Entry__c in :JEtoClone');
                soql.setOrderByClause('autonumber__c DESC');
                soql.setLimit(1);
                list<sobject> sobjMax= Database.query(soql.getQuery());



	            
	            integer minRev=(integer)integer.valueOf(sobjMin[0].get('autonumber__c'));
	            integer maxRev=(integer)integer.valueOf(sobjMax[0].get('autonumber__c'));
	            system.debug('min:**** ' +minRev + ' max:**** ' + maxRev);
	                
	            integer ref = minRev;
	            while(ref <= maxRev){
	                
	                Map<string, string> iMap = new Map<string, string>();
	                iMap.put('min', prefixIntWithZeros(ref, 10));
	                iMap.put('max', prefixIntWithZeros(ref+chunkSize, 10));
	                
	                ref += chunkSize + 1;
	                chunks.add(iMap);
	            }
	            
	            obj.cloneSize=chunks.size();
	            string ChunkJSON = JSON.serialize(chunks);
	            obj.cloneChunkMap = ChunkJSON;
	            obj.JELineCount = JEtoClone[0].Total_Number_Of_Lines__c; 
	            obj.cloneJEId = clonedJE.id;
	        }else {
	            obj.cloneJEId=clonedJE.id;            
	            obj.cloneSize = 0;            
	        }
		}
		catch(exception e){
			if(clonedJE.id != null)
            	obj.cloneJEId=clonedJE.id;            
            obj.cloneSize = 0;            
		
		}
 			clonedJEId = obj.cloneJEId;
  			cloneSize = obj.cloneSize;
	        JELineCount = obj.JELineCount; 
	        cloneChunkMap = obj.cloneChunkMap;
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
    public static ChunkCloneResult cloneJE(id JEtoCloneId,id clonedJEID,integer CurrChunkIndex,Integer TotalChunks,string min,string max)
    {
		ChunkCloneResult cloneObj = new ChunkCloneResult();
        try
        {
	 		system.debug('currChunkIndex **** ' + currChunkIndex);
	 		system.debug('TotalChunks **** ' + TotalChunks);
            if(currChunkIndex>=TotalChunks)
            {
                    //Empty remote call.Defering and waiting for del drafts to complete
            }
            else 
            {
           	 	string whereClause = 'Journal_Entry__c =:JEToCloneId and autonumber__c>=:min and autonumber__c<=:max';
            	string objectName = 'Journal_Entry_Line__c';
				
				SOQLUtil soql = new SOQLUtil(objectName,false);
				soql.addAllFields();
				soql.setWhereClause(whereClause);				
				
            	list<Journal_Entry_line__c> JELCloneInScope= Database.query(soql.getQuery());
                JournalEntryService.getInstance().JournalEntryClone(clonedJEID,JELCloneInScope);

                cloneObj.NextChunkIndex=CurrChunkIndex+1;
                if(CurrChunkIndex==TotalChunks-1)
                {
                	cloneObj.AllDone=true;
                }
                else
                {
                  	cloneObj.AllDone=false;

                }


            }

                cloneObj.progress=cloneJEGenProgress(clonedJEID);
                cloneObj.ChunkJEL=true;
        }
        catch(Exception ex)
        {
            cloneObj.messages=ex.getMessage()+ 'on Line'+ex.getLineNumber();
 		system.debug('cloneObj.messages **** ' + cloneObj.messages);
            cloneObj.ChunkJEL=false;
            cloneObj.progress=-1;
            cloneObj.AllDone=false;

        }
        return cloneObj;

    }    
      public static decimal cloneJEGenProgress(id clonedJEID)
    {
      
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','name','Total_Number_Of_Lines__c'
        });
        soql.setWhereClause('id=:clonedJEID');
        list<Journal_Entry__c> cloneJE = Database.query(soql.getQuery());



        if(cloneJE.size()>0)
        {               
                      
          decimal currcount = cloneJE[0].Total_Number_Of_Lines__c;
          system.debug('inside update'+ currcount);
          return currcount;
            
        }
     
        else //Check if Active AE is generated
        {

            return 0;
        }
    }

 	@RemoteAction
    public static DeleteCloneResult deleteClonedJE(id clonedJEId){
      	
        DeleteCloneResult cloneObj = new DeleteCloneResult();
       
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','name','Total_Number_Of_Lines__c'
        });
        soql.setWhereClause('id=:clonedJEID');
        list<Journal_Entry__c> clonedJE = Database.query(soql.getQuery());



  		if (clonedJE.size() != 0){
  			DML.deleteAsUser(clonedJE[0]);
  		}
        cloneObj.Alldone = true;
        return cloneObj;
      
      }
}