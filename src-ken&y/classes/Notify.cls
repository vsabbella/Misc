global with sharing class Notify {
    
    
    //KNDY-7362 two methods below are overloaded to allow for manually passing in a failure
    global static void sendEmailBatchFinish(string subject, List<Message> messages, Database.BatchableContext info) {    	
		sendEmailBatchFinishBuildBody(null, subject, messages, info);
    }
    
    global static void sendEmailBatchFinish(Integer batchErrorCount, string subject, List<Message> messages, Database.BatchableContext info) {    	
		sendEmailBatchFinishBuildBody(batchErrorCount, subject, messages, info);
    }    
  
  	public static void sendEmailBatchFinishBuildBody (Integer batchErrorCount, string subject, List<Message> messages, Database.BatchableContext info) {
		string body = 'Batch Messages<dl>';
        if(messages != null && messages.size()>0) {
            for (Message message :messages ) {
                body += '<dt>'+message.title + '</dt><dd>'+message.body+'</dd><br/>';
            }
        }
        body += '</dl>';
  		sendEmailBatchFinish(batchErrorCount, subject, body, info);	
  	}
  
  
    // look for evidence (extendedStatus) in AsyncApexJob, report any status errors we see    
    public static void checkFailedAsyncStatus() { 
    	// we must enable this feature with a custom setting, check for that now, any value will enable
        if ( Configuration__c.getValues('AsyncApexJobNotify') == null ) return;
        
        // high water allows us to avoid duplicate messages
        Id AsyncApexHighWaterId = null;        
        Configuration__c AsyncApexJobId = Configuration__c.getValues('AsyncApexJobId');
        if ( AsyncApexJobId != null && AsyncApexJobId.Value__c != null ) 
            AsyncApexHighWaterId = AsyncApexJobId.Value__c;
        list<AsyncApexJob> jobs = new list<AsyncApexJob>();
        map<id,ApexClass> classNameMap = new map<id,ApexClass>();
        try { 
	
            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('AsyncApexJob', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','ApexClassID','CompletedDate','extendedStatus','JobItemsProcessed','JobType','MethodName','NumberOfErrors','Status',
                'TotalJobItems'
            });
            soql.setWhereClause('extendedStatus != null // extended status contains errors and id > :AsyncApexHighWaterId');
            soql.setOrderByClause('id desc');
            soql.setLimit(100);
            jobs = Database.query(soql.getQuery());


            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            soql = new SOQLUtil('ApexClass', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','name'
            });
            soql.setWhereClause('id = :KSE.grepRelatedIdSetFromList(jobs, \'ApexClassID\')');
            classNameMap = new Map<id,ApexClass>((List<ApexClass>)Database.query(soql.getQuery()));



        } catch ( Exception e) {
            system.debug(LoggingLevel.INFO, 'could not query AsyncApexJob table '+e.getMessage() + e.getStackTraceString());
        } 
        if ( jobs.size() == 0 ) { 
            //system.debug(LoggingLevel.INFO, 'all done, no more to report');
            return; // all done here, no new messages
        }

        string subject = 'Failed Async Jobs Notification';
        string htmlBody = '';
        for ( AsyncApexJob job : jobs) {
            string completeDate ='';
            if ( job.CompletedDate != null ) 
                completeDate = job.CompletedDate.format();
            string classname = '';
            if ( job.ApexClassId != null && classNameMap.containsKey(job.ApexClassId) 
                && classNameMap.get(job.ApexClassId) != null) {
                classname = classNameMap.get(job.ApexClassId).Name;
            }
                
            htmlBody += '<hr/>Status :'+job.Status+'<br/>'+
                'ExtendedStatus :'+ job.ExtendedStatus +'<br/>'+
                'JobType :'+job.JobType+'<br/>'+
                'ApexClassName :'+classname+'<br/>'+
                'TotalJobItems :'+job.TotalJobItems+'<br/>'+
                'JobItemsProcessed :'+job.JobItemsProcessed+'<br/>'+
                'NumberOfErrors :'+job.NumberOfErrors+'<br/>'+
                'CompletedDate :'+completeDate + '<br/>' +
                'Organization :'+UserInfo.getOrganizationName() +' ( ' +UserInfo.getOrganizationId() + ' ) ';              
        }
        
        doEmail(htmlBody, subject);  // tell the world
        
        // set the high water mark, or create one first time
        if ( AsyncApexJobId == null ) AsyncApexJobId = new Configuration__c(Name = 'AsyncApexJobId');
        AsyncApexJobId.Value__c = jobs[0].id; // we reported this one, dont report again
        DML.upsertAsSystem(); upsert AsyncApexJobId;
    }
    	
    // if a batch fails to start, go ahead and send email
    public static void sendEmailBatchFail( Process_Job__c job ) {
        List<String> additionalEmails = new List<String>();
        if(job.Additional_Emails_Notified__c != null) {
            additionalEmails = job.Additional_Emails_Notified__c.split(',');
        }
        string subject = 'Process Job - FAILURE - <'+job.Name + '>';
        string htmlBody = 'Process Job Name: ' + job.Name +'<br/>'+
                'Apex Class Name: '+job.Name +'<br/>'+
                'Start Time: '+system.now().format() + '<br/>' +
                'End Time  : '+system.now().format() + '<br/>' +
				'Duration  : 0<br/>' +
                'Total Batches : 0<br/>'+
                'Total Batches Processed : 0<br/>'+
                'Total Batches in Error : 0<br/>'+            
                'Error Detail : Failed to start :'+job.Exception__c+'<br/>'+
                'Organization :'+UserInfo.getOrganizationName() +' ( ' +UserInfo.getOrganizationId() + ' ) <br/>'+
            	'User: ' +UserInfo.getName() +'<br/>' ;
        doEmail(htmlBody, subject, job.User_Notified__c, additionalEmails);
    }
    

 	//KNDY-7362 two methods below are overloaded to allow for manually passing in a failure
    global static void sendEmailBatchFinish(string subject, string body, Database.BatchableContext info) {    	
		//we overloaded this method, if no batchErrorCount param is passed, we call the worker with that param as null
		sendEmailBatchFinishWorker(null, subject, body, info);
    } 
    
    global static void sendEmailBatchFinish(Integer batchErrorCount, string subject, string body, Database.BatchableContext info) {    	
		//we overloaded this method, if batchErrorCount param is passed, we call the worker with that param
		sendEmailBatchFinishWorker(batchErrorCount, subject, body, info);
    } 
    
    
    // after a batch is done, we will send email, assumes a good exit, and some message to include in the mail.
    // with no subject and no body, we will construct one from the info asyncapexjob id provided    
    public static void sendEmailBatchFinishWorker(Integer batchErrorCount, string subject, string body, Database.BatchableContext info) {    	
        AsyncApexJob  job = null;
        Process_Job__c processJob = null;
        string aclassName = '';
        if ( info != null ) { 
            try { // try to fetch info from the job that just finished
               

                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
                SOQLUtil soql = new SOQLUtil('AsyncApexJob', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'id','ApexClassID','CreatedDate','CompletedDate','extendedStatus','JobItemsProcessed','NumberOfErrors','Status','TotalJobItems'
                });
                string jId = info.getJobId();
                soql.setWhereClause('id = :jId');
                soql.setLimit(1);
                job = Database.query(soql.getQuery());



                /*
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
                soql = new SOQLUtil('ApexClass', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'id','name'
                });
                string aID = job.ApexClassID;
                soql.setWhereClause('id = :aID');
                soql.setLimit(1);
                ApexClass aclass = Database.query(soql.getQuery());
                aclassName = aclass.Name;

                soql = new SOQLUtil('Process_Job__c');
                soql.addFields(new Set<String>{'Id', 'Name', 'Apex_Class__c', 'Queueable_Id__c', 'Additional_Emails_Notified__c', 'User_Notified__c', 'User_Notified__r.Name'});
                soql.setWhereClause('Apex_Class__c = :aclassName');
                soql.setOrderByClause('Last_Run__c DESC');
                soql.setLimit(1);
                processJob = Database.query(soql.getQuery());


            } catch( System.QueryException qe ) {                // bad job id, not much we can do.
                system.debug(LoggingLevel.INFO, qe.getMessage());
            }
        }
        
        //KNDY-7362, let number of errors be optionally passed in if we want to do error handling in the batch itself
        Integer numberOfErrors = 0;
        if (batchErrorCount != null) {
        	numberOfErrors = batchErrorCount;	
        } else {
        	if (job != null) {
    			if (job.NumberOfErrors != null) {
    				numberOfErrors = job.NumberOfErrors;	
    			}
        	}	
        }
        
        // form the email Subject
        boolean success = true;
        string  emailSubject = 'Process Job - ';
        if ( job != null && (numberOfErrors > 0 || job.Status != 'Completed' || job.ExtendedStatus != null)) { 
            emailSubject += 'FAILURE - ';
            success= false;
        } else {
            emailSubject += 'SUCCESS - ';           
        }        
        emailSubject = emailSubject + '<' + aclassName + '> '; 
        if ( subject != null ) { emailSubject += subject; }
        subject = emailSubject;

        Id notifiedUserId = UserInfo.getUserId();
        List<String> additionalEmails = new List<String>();
        // form the body
        string htmlBody = '';
        if ( job != null ) {

            String jobName = aclassName;

            if(processJob != null) {
                jobName = processJob.Name;
                notifiedUserId = processJob.User_Notified__c != null ? processJob.User_Notified__c : notifiedUserId;
                if(processJob.Additional_Emails_Notified__c != null) {
                    additionalEmails = processJob.Additional_Emails_Notified__c.split(',');
                }
            }

            datetime completedDateTime;
            if(job.Status!='Aborted'){
                completedDateTime=job.CompletedDate;
            }else{
                completedDateTime=system.now();
            }
                
            Decimal delta = completedDateTime.getTime() - job.CreatedDate.getTime();
            delta = delta / 1000;// ms=> seconds
            
            htmlBody = 'Process Job Name: ' + jobName +'<br/>'+
                'Apex Class Name: '+aclassName +'<br/>'+
                'Start Time: '+job.CreatedDate.format() + '<br/>' +
                'End Time  : '+completedDateTime.format() + '<br/>' +
				'Duration  : '+delta + ' seconds<br/>' +
                'Total Batches :'+job.TotalJobItems+'<br/>'+
                'Total Batches Processed :'+job.JobItemsProcessed+'<br/>'+
                'Total Batches in Error :'+numberOfErrors+'<br/>'+          
                'Error Detail :'+ (job.ExtendedStatus != null ? job.ExtendedStatus:'')+'<br/>'+
                'Organization :'+UserInfo.getOrganizationName() +' ( ' +UserInfo.getOrganizationId() + ' ) <br/>' +
                'Job ID : '+job.Id+'<br/>' +
            	'User: ' + UserInfo.getUserName() +'<br/>'+ body;
        } else { 
            htmlBody = 'null job '+  info;         	
        }

        doEmail(htmlBody, subject, notifiedUserId, additionalEmails);
    }     
    
    private static void doEmail( string htmlBody, string subject) {
        if ( Limits.getEmailInvocations() >= Limits.getLimitEmailInvocations() ) return; // KNDY-6835  
        Messaging.SingleEmailMessage singleRequest = new Messaging.SingleEmailMessage();
        singleRequest.setTargetObjectId(UserInfo.getUserId());
        singleRequest.setSaveAsActivity(false);
        singleRequest.setSubject(subject);
        singleRequest.setHtmlBody( htmlBody ); 
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{singleRequest});        
    }

    private static void doEmail( string htmlBody, string subject, id userId, List<String> additionalEmails) {
        Id emailId = userId == null ? UserInfo.getUserId() : userId;
        if ( Limits.getEmailInvocations() >= Limits.getLimitEmailInvocations() ) return; // KNDY-6835
        Messaging.SingleEmailMessage singleRequest = new Messaging.SingleEmailMessage();
        singleRequest.setTargetObjectId(emailId);
        singleRequest.setCcAddresses(additionalEmails);
        singleRequest.setSaveAsActivity(false);
        singleRequest.setSubject(subject);
        singleRequest.setHtmlBody( htmlBody );
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{singleRequest});
        } catch(Exception e) {
            Messaging.SingleEmailMessage errorRequest = new Messaging.SingleEmailMessage();
            errorRequest.setTargetObjectId(emailId);
            errorRequest.setSaveAsActivity(false);
            errorRequest.setSubject(subject);

            htmlBody +=  e +'<br/>';
            errorRequest.setHtmlBody( htmlBody );
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{errorRequest});
        }
    }

    /* 
     * utility to offer various types of notification to be generated from within or the package 
     * or by customer code that would like to send email or post chatter
     * 
     * FUTURE add emailMe, emailGroup, chatterGroup, etc...
     *  
     */
    
    global class Message{
        
            global Message(string messageTitle, string messageBody){
                title = messageTitle;
                body = messageBody;
            }
            
            global string title;
            global string body;
            
            global string getBody() { return body; } 
            global string getTitle() { return title; } 
    }
    
    global static Map<Id, String> chatterOnMe(  object thisClass, List<Message> messages) {
        return chatterOn( thisClass, 'me', messages);                                                                   
    }
    
    global static Map<Id, String> chatterOn(    object thisClass, 
                                                                    string sobjectid ,  // 'me'  or record ID  
                                                                    List<Message> messages) {  
        
        string processName = getClassName( thisClass ); 
        
        Map<Id, String> mChatterBodies = new Map<Id, String>();
        string body = '';
        
        ConnectAPI.TextSegmentInput overviewSegment = new ConnectAPI.TextSegmentInput();
        overviewSegment.text = ' - ' + processName + ' ' + Label.Chatter_Done + ' \r\n';
        
        ConnectAPI.TextSegmentInput issuesDetailSegment = new ConnectAPI.TextSegmentInput();
        issuesDetailSegment.text = Label.Chatter_Prelude; 
        
        integer length = 0;
        List<ConnectAPI.TextSegmentInput> processMessageSegments = new List<ConnectAPI.TextSegmentInput>();
        ConnectAPI.TextSegmentInput endSegment;
                    
        for(integer i=0; i<messages.size(); i++) {
            
            ConnectAPI.TextSegmentInput msgSegment = new ConnectAPI.TextSegmentInput();
            
            msgSegment.text = messages[i].title + ' - ' + messages[i].body + '\r\n';
            
            processMessageSegments.add(msgSegment);
            length += messages[i].title.length() + messages[i].body.length();
            if(length > 500){
                endSegment = new ConnectAPI.TextSegmentInput();
                endSegment.text = string.valueOF(messages.size()-i-1) + Label.Chatter_Postlude;
                processMessageSegments.add(endSegment);
                break;
            }
            
        }
        
        //Construct the post body input
        
        body += overviewSegment.text + '\r\n';
        
        if(messages.size()>0){
            body+= issuesDetailSegment.text + '\n';
            
            for(ConnectAPI.TextSegmentInput seg : processMessageSegments){
                body += seg.text + '\n';
            }
            
        }
        
        //ConnectAPI.FeedItemInput feedItemInput = new ConnectAPI.FeedItemInput();
        //feedItemInput.body = messageBodyInput;
        
        ConnectAPI.FeedElement feedElement;
    
        try{
            if ( body.length() >1000)  body=body.substring(0,1000);
            
            feedElement = ConnectApi.ChatterFeeds.postFeedElement( null, // community id, internal or null 
                                                SOBJECTID,
                                                ConnectApi.FeedElementType.FeedItem,
                                                body
                                                );
                        
        } catch(exception ex) {
            // TEST CATCH: system.UnsupportedOperationException: ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true).
            // Catching exceptions to avoid using seealldata=true and test.isRunningTest
            // system.debug(Logginglevel.info,' ConnectAPI.ChatterFeeds.postFeedItem fail  '  + ex);
        }
        
        if (feedElement != null) {
            mChatterBodies.put(feedElement.Id, body);
        }
        
        return mChatterBodies;      
    }
 
 	private static string getClassName( object thisclass ) { // TODO duplicated code in Inspect()
		return string.valueOf(thisClass).substringBefore(':');  // should we do error checking
	}    
	
	public static Notify.Message getErrorMessage(List<SObject> scope, String errorMessage, String errorDetails){
		String recordNames = '';
		
		for(SObject record : scope){
			recordNames += record.get('Name') + ',';
		}
		
		recordNames.removeEnd(',');
		
		String message = 'Records picked up in this batch: (' + recordNames + ')\n';
		message += 'Exception message: ' + errorMessage;
		
		return new Notify.Message(message, errorDetails);
	}     
}