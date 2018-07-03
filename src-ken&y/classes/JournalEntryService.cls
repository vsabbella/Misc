public with sharing class JournalEntryService {
	public class JESException extends Exception {}
	private Date todaysDate = system.today(); 
	AccountingEntryService AES = AccountingEntryService.getInstance();
	private static JournalEntryService instance = null;
	Schemautil util = schemautil.getInstance();
	SegmentService SS = new SegmentService();
	public static boolean VoidAE = false;  // Set this flag when the accounting entry is about to be voided 
	public static boolean ReverseAE = false; // Set this flag when the accounting entry is about to be reversed
	public class JournalEntryServiceException extends Exception{ }
    public static ExceptionService exService = new ExceptionService();
	
	@TestVisible
    private DateTime VoidDate;

	public list<Period__c> openPeriods{
        get{
            if(openPeriods==null){
            
            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','name','Period_Start__c','Period_End__c','JE_Cutoff__c','Open__c','Company__c','Period_Number__c'
            });
            soql.setWhereClause('Open__c = true');
            soql.setOrderByClause('Company__c, Period_Number__c asc');
            openPeriods = Database.query(soql.getQuery());
            }
            return openPeriods;
        }
        set;
    }
    
    public map<Id, Period__c> openPeriodMap {
        get {
            if (openPeriodMap == null) {
			    SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
			    soql.addFields(new set<string>{
			        'Id','Name','Company__c','Period_Start__c','Period_End__c','JE_Cutoff__c','Period_Number__c'
			    });
			    soql.setWhereClause('Open__c = true');
			   	openPeriodMap = new map<Id, Period__c>((List<Period__c>)Database.query(soql.getQuery()));               	
            }
            return openPeriodMap;
        }
        set;
    }    
    
	public void setDateforTest(Date inputDate){
    	if(Test.isRunningTest()){
    		todaysDate = inputDate;	
    	}
    }
    
    public static JournalEntryService getInstance(){
    	if(instance == null){
    		instance = new JournalEntryService();
    	}
    	return instance;
    }
    
    List<Segment_Definition__c> segments = SS.segments; 
    
    public list<String> sourceDocsList{
    	
     	get{
     		List<String> SDList = new List<String>();
    		if(SDList.size() < 1){
    			for(String str: util.getFieldsFromFieldSetString( Accounting_Entry__c.sObjectType , 'Source_documents')){
    				//system.debug(logginglevel.info,'str:'+ str);
					SDList.add(str);
					//system.debug(logginglevel.info,'SDList Inside for loop:'+SDList);
    			}
    		}
    		//system.debug(logginglevel.info,'SDList :'+SDList);
    		return SDList;
    	}
    	set;
    }
    
    public list<String> JEsourceDocsList{
    	
     	get{
     		List<String> SDList = new List<String>();
    		if(SDList.size() < 1){
    			for(String str: util.getFieldsFromFieldSetString( Journal_Entry__c.sObjectType , 'Source_documents')){
    				//system.debug(logginglevel.info,'str:'+ str);
					SDList.add(str);
					//system.debug(logginglevel.info,'SDList Inside for loop:'+SDList);
    			}
    		}
    		//system.debug(logginglevel.info,'SDList :'+SDList);
    		return SDList;
    	}
    	set;
    }
    
    // This function takes the AE to adjust and reverse the AE and creates a new JE from the original AE and return it
   /* SK -This function was created to be used if the adjustment happens at the source doc but with current approach the 
   adjustment is happening at the accounting entry line level so this function is not being used at the moment.
   
    public Journal_Entry__c adjustAE(Accounting_Entry__c AEtoAdjust){
    
		//Add all configured segments to the query
		string segFields = '';
		for(Segment_Definition__c sd : segments){
			segFields += ', ' + sd.Accounting_entry_field__c ;
		}
		
		string sourceDocs = '';
		for(String str: sourceDocsList){
			sourceDocs += ', ' + str; 
		}
		system.debug(logginglevel.info,'sourceDocs before AE query:'+sourceDocs);
		Savepoint sp = Database.setSavepoint();
    	try{
		Id AEID = AEtoAdjust.id;
    	// TODO: build a query from source documents field set on AE so that it can be used for reversal of AE for any source document
    	string query = 'SELECT Id, name, company__c, currency__c, total_debit__c, total_credit__c, '
						+ ' transaction_type__c, Posted__c, Period__c, Period__r.Open__c, Period__r.Closed__c, Customer__c, Supplier__c '
						+ 	sourceDocs
						+ ' , Related_Accounting_Entry__c, '
						+ ' (SELECT Id, subtransaction_type__c, line_type__c, Transaction_Date__c, '
    					+ '	amount_dr__c, amount_cr__c, source_id__c, source_name__c '	
    					+   segFields
    					+ ' FROM Accounting_Entry_Lines__r) '
    					+ ' FROM Accounting_Entry__c '
						+ ' WHERE Id = :AEID';
    	
    	AEtoAdjust =  database.query(query);
      	
    	List<Accounting_Entry__c> AEListtoReverse = new List<Accounting_Entry__c>();
    	AEListtoReverse.add(AEtoAdjust);

    	// AES.reverseAccountingEntry(AEListtoReverse);
    	Journal_Entry__c JEtonavigate = generateJEfromAE(AEtoAdjust);
    	return JEtonavigate;
	   	} catch(Exception ex){
    		Database.rollback(sp);
          	throw new JESException(ex.getMessage(), ex);
    	}
    }
    */
    
    
    /* SK - This is used in the logic below in method : ValidateJELines. As the below function is commented which uses this one hence commented this method as well.
    public Set<Id> SourceDocsAEIds(Journal_Entry__c JE){ 
  		system.debug(logginglevel.info,'JE:'+JE);
    	List<Schema.FieldsetMember> objFields = Schemautil.getInstance().getFieldsFromFieldSet( Journal_Entry__c.sObjectType , 'Source_documents');
    	Id sourceDocId;
    	Set<Id> AEIds = new Set<Id>();
    	sObject sObjJE = JE;
    	system.debug(logginglevel.info,'sObjJE:'+sObjJE);
    	system.debug(logginglevel.info,'objFields:'+objFields);
    	for(Schema.FieldsetMember f :objFields){
    		system.debug(logginglevel.info,'f.getfieldpath():'+f.getfieldpath());
    		system.debug(logginglevel.info,'fieldpath:'+sObjJE.get(f.getfieldpath()));
    		if( sObjJE.get(f.getfieldpath()) != null){
    			sourceDocId = (Id) sObjJE.get(f.getfieldpath());
    		}
    	}
    	system.debug(logginglevel.info,'sourceDocId:'+sourceDocId);
    	Schema.SObjectType token = sourceDocId.getSObjectType();
        
        // Using the token, do a describe 
        // and construct a query dynamically. 
        Schema.DescribeSObjectResult dr = token.getDescribe();
        
        system.debug(logginglevel.info,'dr:'+dr);
        
        //TODO: Need to think @ child relationship name for supplier / customer credit memo
        String queryString = 'SELECT id, (Select id, Name from Accounting_Entries__r) FROM ' + dr.getName() + 
            ' WHERE ';
             queryString += 'Id=\'' + sourceDocId + '\'';
        sObject[] objDBList = Database.query(queryString);  
        
        system.debug(logginglevel.info,'objDBList:'+objDBList);
		
        // loop over the Accounting entries and collect the AE ids
        for(sObject sobj: objDBList){
        	//List<Accounting_Entry__c> AEList = (List<Accounting_Entry__c>) sobj.get('Accounting_Entries__r');
        	List<Accounting_Entry__c> AEList = (List<Accounting_Entry__c>) sobj.getSObjects('Accounting_Entries__r');
        	system.debug('AEList:'+AEList);
        	for(Accounting_Entry__c AE: AEList ){
        		AEIds.add(AE.id);
        	}
        }
		
		return AEIds;
 
    }
    */
    
    /* SK - This logic needs to be revisted. Currently we have validation commented out in the journalentrylinesmanageext.
    DO Not remove yet as we might need to logic to perform validations and this can be reworked.
    public set<Id> ValidateJELines(List<Journal_Entry_Line__c> JELineList){
    	// Step 1: loop thru the JE Lines and collect JE Header and build a map of source id, JE Line Object List (segments, Amount CR, Amount DR, JE Line Type ( reversing / adjustment))
    	Map<Id, List<Journal_Entry_Line__c>> JELMap = new Map <Id, List<Journal_Entry_Line__c>>();
    	Map<Id, List<Accounting_Entry_Line__c>> AELMap = new Map <Id, List<Accounting_Entry_Line__c>>();
    	Map<Id, List<Journal_Entry_Line__c>> JELSCMap = new Map <Id, List<Journal_Entry_Line__c>>();
    	Map<Id, List<Accounting_Entry_Line__c>> AELSCMap = new Map <Id, List<Accounting_Entry_Line__c>>();
    	
    	
    	Id JEID;
    	Set<Id> JEIdstoReturn = new Set<Id>();
    	
    	string segFields = '';
		for(Segment_Definition__c sd : segments){
			segFields += ', ' + sd.Accounting_entry_field__c ;
		}
		
		String JELineListQuery = ' Select id, Name, Journal_Entry__c, Amount_CR__c, Amount_DR__c, Reversing_Line__c, Source_Id__c ' + 
								 segFields +
    							 ' from Journal_Entry_Line__c ' +
    							 ' where id in :JELineList';
		
		List<Journal_Entry_Line__c> JELList = Database.Query(JELineListQuery);
		
	
    	Set<Id> JEIds = new set<Id>();
    	for(Journal_Entry_Line__c JELine: JELList){
    		JEIds.add(JELine.Journal_Entry__c);
    		JEID = JELine.Journal_Entry__c;
    		// Map to store the SCOA combination against the list of the JELines
    		if(JELSCMap.containsKey(returnSegments(JELine))){
     			JELSCMap.get(returnSegments(JELine)).add(JELine)	;						
     		}	else{													
    			JELSCMap.put(returnSegments(JELine),new List<Journal_Entry_Line__c> {JELine} );
     		}
    		// Map to store the source id against the list of the JELines
 	   		if(JELMap.containsKey(JELine.source_id__c)){
     			JELMap.get(JELine.source_id__c).add(JELine)	;						
     		}	else{													
    			JELMap.put(JELine.source_id__c,new List<Journal_Entry_Line__c> {JELine} );
     		}
    	}
    	system.debug(logginglevel.info,'JELMap:'+JELMap);
    	
    	
    	// Step 2: loop thru the JE Header to find out the associated source document
      	// Step 3: query source document to find all associated AEs
      	string sourceDocs = '';
		for(String str: sourceDocsList){
			sourceDocs += ', ' + str; 
		}
      	String JEQueryStr = 'Select id, Name , Period__c, Company__c '+
      						sourceDocs +
      						' from Journal_Entry__c where id = :JEID';
      	
      	Journal_Entry__c JE = Database.Query(JEQueryStr);
      	
      	Set<Id> AEIds = SourceDocsAEIds(JE);
      	//List<Accounting_Entr>new List<Accounting_Entry__c>
      	system.debug(logginglevel.info,'AEIds:'+AEIds);
      	
      	String AELineListQuery = ' Select id, Name, Accounting_Entry__c, Amount_CR__c, Amount_DR__c, source_id__c ' + 
								 segFields +
    							 ' from Accounting_Entry_Line__c ' +
    							 ' where Accounting_Entry__c in :AEIds';
		
		List<Accounting_Entry_Line__c> AELList = Database.Query(AELineListQuery);
		system.debug(logginglevel.info,'AELList:'+AELList);
		
    	// Step 4: Query all AEs to get all AE Lines and build a map of source id, AE Line object (segments, Amount CR, Amount DR)
    	for(Accounting_Entry_Line__c AELine: AELList){
    		
    		// Map to store the SCOA combination against the list of the AELines
    		if(AELSCMap.containsKey(returnSegments(AELine))){
     			AELSCMap.get(returnSegments(AELine)).add(AELine)	;						
     		}	else{													
    			AELSCMap.put(returnSegments(AELine),new List<Accounting_Entry_Line__c> {AELine} );
    			
     		}
     		
     		// Map to store the source id against the list of the AELines
			If(AELMap.containsKey(AELine.source_id__c)){
				AELMap.get(AELine.source_id__c).add(AELine)	;							
			}else{
				AELMap.put(AELine.source_id__c, new List<Accounting_Entry_Line__c> { AELine	});
			}
 		
    	}
    	
    	system.debug(logginglevel.info,'AELMap:'+AELMap);
    	
    	// Step 5: loop thru JE map and check if that source id exists in AE Map if yes compare the segments and Amount CR and Amount DR values 
    	for(List<Journal_Entry_Line__c> JELineListV: JELMap.values()){
    		for(Journal_Entry_Line__c JELine: JELineListV){
    			if(AELSCMap.containsKey(returnSegments(JELine))){
    				
    			
    			
    			}
    			if(AELMap.containsKey(JELine.source_id__c)){
    				for(Accounting_Entry_Line__c AELine: AELMap.get(JELine.source_id__c)){
    					
    					system.debug(logginglevel.info,'JELine.Amount_CR__c:'+JELine.Amount_CR__c+'  AELine.Amount_DR__c:'+AELine.Amount_DR__c );
    					system.debug(logginglevel.info,'JELine.Amount_DR__c:'+JELine.Amount_DR__c+' AELine.Amount_CR__c:'+AELine.Amount_CR__c);
    					system.debug(logginglevel.info,'compareSegments(AELine,JELine):'+compareSegments(AELine,JELine));
						system.debug(logginglevel.info,'JEIdstoReturn before if loops:'+JEIdstoReturn);
						
						
						if(compareSegments(AELine,JELine)){
							system.debug(logginglevel.info,'Inside the else loop for compareSegments');
							if((JELine.Amount_CR__c > 0 && JELine.Amount_CR__c > AELine.Amount_DR__c) )
							{
								system.debug(logginglevel.info,'Inside the loop JELine.Amount_CR__c > 0');
								JEIdstoReturn.add(JELine.id);
							} else if((JELine.Amount_DR__c > 0 && JELine.Amount_DR__c > AELine.Amount_CR__c)){
								system.debug(logginglevel.info,'Inside the loop JELine.Amount_DR__c > 0');
								JEIdstoReturn.add(JELine.id);	
							} 
						}
						//else { 
						//	system.debug(logginglevel.info,'Inside the else loop for compareSegments');
						//	JEIdstoReturn.add(JELine.id);	
						//}
						system.debug(logginglevel.info,'JEIdstoReturn after if loops:'+JEIdstoReturn);
 
    				}
    			}
    		}
    	}
    	// Step 6: If comparison fails add JEline id to a set... either this set can be returned and ids can be used to throw meaningful error message or bool value can be returned if set is not empty
    	system.debug(logginglevel.info,'JEIdstoReturn:'+JEIdstoReturn);
    	return JEIdstoReturn;
    } */
    
    /* SK - Used in above method ValidateJELines hence commented for now.
    public boolean compareSegments(Accounting_Entry_Line__c AELine, Journal_Entry_Line__c JELine){
    	for(Segment_Definition__c sg: segments){
    		if(AELine.get(sg.Accounting_Entry_field__c) != JELine.get(sg.Accounting_Entry_field__c)){
    			return false ;
    		}
    	}
    	return true;
    }
    
    public String returnSegments(sObject sObj){
    	String segString = '';
    	for(Segment_Definition__c sg: segments){
    		if(sObj.get(sg.Accounting_Entry_field__c) != sObj.get(sg.Accounting_Entry_field__c)){
    			segString += '-' + sObj.get(sg.Accounting_Entry_field__c);
    		}
    	}
    	system.debug(logginglevel.info,'segString:'+segString);
    	segString.replaceFirst(segString, '-');
    	system.debug(logginglevel.info,'segString:'+segString);
    	return segString;
    }
    */
    
    public Journal_Entry__c generateJEfromAELs(List<Accounting_Entry_Line__c> AELList){
    	try{
	    	Set<String> segFields = new Set<String>();
			for(Segment_Definition__c sd : segments){
				segFields.add(sd.Accounting_entry_field__c) ;
			}
			
			Set<String> sourceDocs = new Set<String>();
			for(String str: JEsourceDocsList){
				sourceDocs.add(str); 
			}
			
			/*String AELineListQuery = ' Select id, Name, Accounting_Entry__c, Amount_CR__c, Amount_DR__c, source_id__c, '+
									' Transaction_Date__c,  SubTransaction_Type__c, Source_Name__c , Line_Type__c ' + 
									 segFields +
	    							 ' from Accounting_Entry_Line__c ' +
	    							 ' where id in :AELList';*/
			
			SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c');
		    soql.addFields(new Set<String>{ 'id', 'Name', 'Accounting_Entry__c', 'Amount_CR__c', 'Amount_DR__c', 'source_id__c', 
		    								'Transaction_Date__c', 'SubTransaction_Type__c', 'Source_Name__c', 'Line_Type__c'});
		    soql.addFields(segFields);
		    soql.setWhereClause('id in :AELList');
		    
			AELList = Database.query(soql.getQuery());
			//system.debug(logginglevel.info,'AELList:'+AELList);
			//system.debug(logginglevel.info,'segFields:'+segFields);
			
			Id AEID = AELList[0].Accounting_Entry__c;
			//system.debug(logginglevel.info,'AEID:'+AEID);
			
			/*String AEQueryStr = 'Select id, Name , Period__c, Company__c, Customer__c, Supplier__c, Currency__c, Transaction_Type__c '+
	      						sourceDocs +
	      						' from Accounting_Entry__c where id = :AEID';*/
	      	
	      	soql = new SOQLUtil('Accounting_Entry__c');
		    soql.addFields(new Set<String>{ 'id', 'Name', 'Period__c', 'Company__c', 'Customer__c', 'Supplier__c', 'Currency__c', 'Transaction_Type__c'});
		    soql.addFields(sourceDocs);
		    soql.setWhereClause('id = :AEID');
		    
	      	Accounting_Entry__c AE = Database.query(soql.getQuery());
			//system.debug(logginglevel.info,'AE:'+AE);
			
			Journal_Entry__c JE = new Journal_Entry__c();
	    	//JE.GL_Date__c = system.today();
	    	JE.Transaction_Date__c = system.now();
	    	JE.Company__c = AE.Company__c;
	    	JE.Type__c = 'SCOA Adjustment';
	    	JE.Customer__c = AE.Customer__c;
	    	JE.Supplier__c = AE.Supplier__c;
	    	//JE.Finalized__c = true;
	    	for(String str: JEsourceDocsList){
				 JE.put(str, AE.get(str));
			}
	
	    	JE.Currency__c = AE.Currency__c;
	    	JE.Transaction_Type__c = AE.Transaction_Type__c;
	    	//system.debug(logginglevel.info,'JE:'+JE);
	    	
	    	DML.insertAsSystem(JE);
	    	//system.debug(logginglevel.info,'JE:'+JE);
	    	
	    	List<Journal_Entry_Line__c> JELList = new List<Journal_Entry_Line__c>();
	    	
	    	for(Accounting_Entry_Line__c AEL: AELList){
	    		//system.debug(logginglevel.info,'Inside AELList for loop to create JELs');
	    		Journal_Entry_Line__c JEL = new Journal_Entry_Line__c();
	    		JEL.Reversing_Line__c = true;
				JEL.Transaction_Date__c = AEL.Transaction_Date__c;
				JEL.SubTransaction_Type__c = AEL.SubTransaction_Type__c;	
				JEL.Line_Type__c = AEL.Line_Type__c;
				JEL.Journal_Entry__c = JE.Id;
				JEL.Amount_CR__c = AEL.Amount_DR__c;
	            JEL.Amount_DR__c = AEL.Amount_CR__c;
	            JEL.source_id__c = AEL.Source_ID__c;
	            JEL.source_name__c = AEL.Source_Name__c;
	            //system.debug(logginglevel.info,'Segments:'+Segments);
	            for(Segment_Definition__c sgd: Segments){
	            	//system.debug(logginglevel.info,'sgd.Accounting_Entry_Field__c:'+sgd.Accounting_Entry_Field__c);
	            	//system.debug(logginglevel.info,'AEL.get(sgd.Accounting_Entry_Field__c):'+AEL.get(sgd.Accounting_Entry_Field__c));
	            	JEL.put(sgd.Accounting_Entry_Field__c, AEL.get(sgd.Accounting_Entry_Field__c));
	            	
	            }
	     		JELList.add(JEL);
	    	}
	    	DML.insertAsSystem(JELList);
	    	//system.debug(logginglevel.info,'JELList:'+JELList);
	    	
	    	return JE;
    	}catch(Exception e){
    		//system.debug(logginglevel.info,'e:'+e);
    		
    		return null;
    	}
            
    }
    
    //Function to restrict JE update for voided JEs called from JournalEntry.Trigger
    public void ValidateJE(List<Journal_Entry__c> JournalEntryListNew, List<Journal_Entry__c> JournalEntryListOld, Map<id, Journal_Entry__c> oldMap,Boolean isUpdate,Boolean isInsert){
        for(Journal_Entry__c journalEntry: JournalEntryListNew){
            
            //FIN-416 Changes

           /* Commented as they conflict with FinalizeService
            if( (KSE.isFieldChanging('Void__c', journalEntry, oldMap)  &&  journalEntry.Void__c == false)  
                || ( (KSE.isFieldChanging('Void_Date__c', journalEntry, oldMap)) && journalEntry.Void_Date__c == null)
            ){
                journalEntry.addError(Label.Voided_JournalEntry_cannot_be_modified);
            }*/
            if(journalEntry.Type__c.equalsIgnoreCase('Recurring Journal') && KSE.IsFieldChanging('Transaction_date__c',journalEntry,oldMap)){
                journalEntry.addError('Transaction date on the Recurring Journal can not be modified');
            }
            if( ((String) (oldMap.get(journalEntry.id)).get('Type__c')).equalsIgnoreCase('Recurring Journal') 
                && journalEntry.Recurring_Template__c != null 
                && KSE.IsFieldChanging('Type__c',journalEntry,oldMap))
            {
                journalEntry.addError('Recurring Journal Type can not be modified');
        }
        }
  
    }
    
    // function to validate the JE period while finalizing the document.
    public static void validateJEFinalize(List<Journal_Entry__c> JEList, Map<Id,Journal_Entry__c> oldMap_JE){
    	if(trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
			for(Journal_Entry__c thisJE: JEList){
	   			if(thisJE.finalized__c == true && KSE.isFieldChanging('Finalized__c',thisJE, oldMap_JE)){
	   				if(thisJE.Period__c == null && thisJE.GL_Date_Time__c == null){
	   					thisJE.addError(Label.Record_cannot_be_finalized);
	   				}
	   			}
	       	}
    	}
       	
	}
	
    // function to validate the JE status for Void or Cancelled before updating the JE.
    public static void validateJEStatus(List<Journal_Entry__c> JEListOld,Map<Id,Journal_Entry__c> JEMapNew){
			for(Journal_Entry__c je: JEListOld){
	   			Journal_Entry__c jeNew = JEMapNew.get(je.id);
	   			if(je.Status__c == 'Cancelled' || je.Status__c == 'Void'){
	   					jeNew.addError(Label.JournalEntries_Cancelled_Voided_cannot_be_changed);
	   			}
	       	}
    	
       	
	}
	
	// function to set or clear the information on journal entry 
	static Map<Id,Id> companyTransactionCurrencyMap = new Map<Id,Id>();
	public void setOrClearJEInformation(List<Journal_Entry__c> JEList, map<Id,Journal_Entry__c> JEMapOld){
		if(trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){

            if ( ! companyTransactionCurrencyMap.keySet().containsAll(KSE.grepIdSetFromList( JEList)) ) {
                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
                SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'id','Name','company__c','company__r.Default_Transaction_Currency__c'
                });
                soql.setWhereClause('id in :JEList');
                for(Journal_Entry__c thisJE: Database.query(soql.getQuery())){



                    companyTransactionCurrencyMap.put(thisJE.id, thisJE.Company__r.Default_Transaction_Currency__c);
                }
            }
			for(Journal_Entry__c thisJE: JEList){
                
				if(thisJE.Type__c == null){
					thisJE.Type__c = 'Manual';
                    //FIN-954 Adding transaction_type__c on all source docs.TODO:Remove this once we deprecate type__c
                    thisJE.Transaction_Type__c='Manual'; 
				}
                else
                {
                	if(thisJE.Finalized__c != true){
                   		thisJE.Transaction_Type__c=thisJE.Type__c; }
                    
                }
	            // SK: Source_Document_Object_Name__c on JEs will always be the same object name is is required for deriving the GL Date Tiem and the period on the record.
                thisJE.Source_Document_Object_Name__c = 'Journal_Entry__c';
                
                if(companyTransactionCurrencyMap.containsKey(thisJE.id) && thisJE.currency__c == null){
					thisJE.currency__c = companyTransactionCurrencyMap.get(thisJE.id);
				}
                	
                // IF the record has exceptions then that can not be finalized
	            if(thisJE.has_exceptions__c == true && thisJE.finalized__c == true){
	            	thisJE.Finalized__c = false;
	            	thisJE.addError(Label.JournalEntries_with_exceptions_cannot_be_Finalized);
            	}
            	if(thisJE.Type__c.equalsIgnoreCase('Accrual - Manual')){
                	thisJE.Auto_Reverse__c = true;
                }
                if(thisJE.Finalized__c == false && !thisJE.Type__c.equalsIgnoreCase('Year End Adjustment')){
	            		thisJE.GL_Date_Time__c = null;
	            		thisJE.Period__c = null;
	            }
                if(JEMapOld != null && JEMapOld.containsKey(thisJE.id)){
                	Journal_Entry__c JEOld = JEMapOld.get(thisJE.id);
	                if(JEOld.Finalized__c == true && thisJE.Finalized__c == false && thisJE.Type__c.equalsIgnoreCase('Year End Adjustment')){
		            		thisJE.GL_Date_Time__c = null;
		            }
                }
	    	}
		}
	}
    
    public static void ValidateJEFields(List<Journal_Entry__c> JEList){
    	
    	// Query for parent source docs and set exception based on hasExceptions
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','name','customer_invoice__r.has_exceptions__c','customer_receipt__r.has_exceptions__c','shipment__r.has_exceptions__c',
            'supplier_invoice__r.has_exceptions__c'
        });
        soql.setWhereClause('Id IN :JEList');
        Map<Id, Journal_Entry__c> mJEs = new Map<Id, Journal_Entry__c>((List<Journal_Entry__c>)Database.query(soql.getQuery()));



    	for(Journal_Entry__c je : JEList){
    		
    		if(je.Company__c==null)
    			exService.setException(je, ExceptionUtil.JE_MISSING_COMPANY);
    		else
    			exService.clearException(je, ExceptionUtil.JE_MISSING_COMPANY);
    		
    		if(je.Transaction_Date__c==null)
    			exService.setException(je, ExceptionUtil.JE_MISSING_TRANSACTION_DATE);
    		else
    			exService.clearException(je, ExceptionUtil.JE_MISSING_TRANSACTION_DATE);
    			
    		if(je.Currency__c==null)
    			exService.setException(je, ExceptionUtil.JE_MISSING_TRANSACTION_CURRENCY);
    		else
    			exService.clearException(je, ExceptionUtil.JE_MISSING_TRANSACTION_CURRENCY);
    			
    		/*if(je.Total_Debit__c != je.Total_Credit__c)
    			exService.setException(je, ExceptionUtil.JE_CREDIT_DEBIT_UNMATCHED);
    		else
    			exService.clearException(je, ExceptionUtil.JE_CREDIT_DEBIT_UNMATCHED);
    		*/
    		
    		if(!KSE.isEqualDecimal(je.Total_Debit__c, je.Total_Credit__c))
    			exService.setException(je, ExceptionUtil.JE_CREDIT_DEBIT_UNMATCHED);
    		else
    			exService.clearException(je, ExceptionUtil.JE_CREDIT_DEBIT_UNMATCHED);
    			
    		if(!(je.Type__c.equalsIgnoreCase('Accrual - Manual') || je.Type__c.equalsIgnoreCase('UFX')) && je.auto_reverse__c == true){
    			je.addError('Auto Reverse can be checked only for the Accrual - Manual or UFX type of journal entries');
    		}
    			
    		// TODO: check for appropriate source document when the Accrual for source document is implemented
    		
    	}
    }  
    
    
    public static void OnUnfinalize() {
    	if(trigger.isAfter && trigger.isUpdate) {
    		list<Journal_Entry__c> lJEs = new list<Journal_Entry__c>();
    		for(Journal_Entry__c je : (list<Journal_Entry__c>)trigger.new) {
    			if(!je.Finalized__c && KSE.isFieldChanging('Finalized__c', je, trigger.oldMap))
    				lJEs.add(je);
    		}
    		
    		if(!lJEs.isEmpty()){
                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
                SOQLUtil soql = new SOQLUtil('Bank_Transaction_Match__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'Id'
                });
                soql.setWhereClause('Journal_Entry_Line__r.Journal_Entry__c in :lJEs');
                list<Bank_Transaction_Match__c> lBTM2Delete = Database.query(soql.getQuery());

		    	if(!lBTM2Delete.isEmpty()) {
		    		DML.deleteAsUser(lBTM2Delete);
		    	}
    		}
    	}
    }  
    
    
    public boolean JournalEntryVoid (List<Journal_Entry__c> JEList) {
    	Boolean isSuccess = false;
		if(VoidDate == null){
			VoidDate = system.now();
		}
    	
    	// create a list of AEs to be voided based on selected JEs
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Name','Accounting_Entry__r.Period__c','Accounting_Entry__r.Period__r.Open__c','Accounting_Entry__r.Period__r.Closed__c',
            'Accounting_Entry__r.Period__r.Permanently_Closed__c','Accounting_Entry__r.Period__r.Period_Start__c','Accounting_Entry__r.Period__r.Period_End__c'
        });
        soql.setWhereClause('Accounting_Entry__c IN (Select id from Accounting_Entry__c where Journal_Entry__c in :JEList)');
        list <Accounting_Entry_Line__c> aeLineTovoid = Database.query(soql.getQuery());
        
		Savepoint sp = Database.setSavepoint();
		try{
			AES.AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid,aeLineTovoid);
			system.debug(logginglevel.info,'voidDate in JES.JournalEntryVoid:'+voidDate);
			set<Id> voidIds = new set<Id>();
			for(Journal_Entry__c je:JEList){
					je.void__c = true;
					je.void_date__c = VoidDate;
					voidIds.add(je.Id);
			}
			FinalizeService.voidIds.addAll(voidIds);
			DML.updateAsSystem(JEList);
			isSuccess = true;
		}catch(Exception ex){
			isSuccess = false;
		 	Database.rollback(sp);
		 	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,' ' + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
		}
		system.debug(logginglevel.info,'isSuccess'+isSuccess);
		return isSuccess;
    }
    

     public void JournalEntryClone ( Id clonedJEID, list<Journal_Entry_line__c> JELCloneInScope) {
     
	    list<Journal_Entry_line__c> newJELs = new list<Journal_Entry_line__c>();
     	for(Journal_Entry_line__c jel: JELCloneInScope){
//     		jel.Journal_Entry__c = clonedJEID;
    		Journal_Entry_Line__c newjel = jel.Clone(false,true,false,false);
    		newjel.Journal_Entry__c = clonedJEID;
    		newJELs.add(newjel);
     	}
     	
     	DML.insertAsSystem(newJELs);
     
     }
     
     public void CheckYearEndEntry ( list<Journal_Entry__c> JEListInScope) {
     	list <Id> PeriodIDs = new list<Id>();
      	map<Id,Id> mJEPeriod = new map<Id,Id>();
     	List<Journal_Entry__c> YearEndJEs = new list<Journal_Entry__c>();
     	for(Journal_Entry__c je:JEListInScope){
     		if(je.period__c != null)
     			PeriodIDs.add(je.Period__c);
     	}
		     
    	boolean existingYEJournal ;
    	
        SOQLUtil jeSoql = new SOQLUtil ( 'Journal_Entry__c' ) ;
        jeSoql.addFields ( new Set<String> { 'Id','Name','period__c' } ) ;
        jeSoql.setWhereClause ( 'Type__c = \'Year End\' AND Period__c in : PeriodIDs AND Finalized__c = true AND Void__c = false' ) ;
        jeSoql.setLimit (1);
        
        List<Journal_Entry__c> yearEndJournals = Database.query ( jeSoql.getQuery () ) ;
        
		for(Journal_Entry__c je: yearEndJournals){
			mJEPeriod.put(je.period__c,je.id);
		
		}
		
     	for(Journal_Entry__c je:JEListInScope){
     		if(mJEPeriod.containskey(je.period__c))
     			je.addError('You cannot create adjusting journal entries for this year because net income has already been transferred to retained earnings. To create adjusting entries, you must first cancel the balance transfer in the Fiscal Year Close window');
     	}
		if(yearEndJournals.size() > 0){
            existingYEJournal = true;		
		}else{
			existingYEJournal = false;
		}
		
		system.debug('existingYEJournal : ' + existingYEJournal);
 		system.debug('yearEndJournals : ' + yearEndJournals);
     }
 
 
}