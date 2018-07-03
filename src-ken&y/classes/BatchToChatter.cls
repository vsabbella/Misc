global with sharing class BatchToChatter {
	/***
	 * 	Description: call this method from the finish of a batch, passing the jobId, the name of the batch and a list of messages from a stateful variable used to collect errors
	 * we will chatter on the groups mentioned OR on the individual user
	 * if you want to turn off chatter on the running user, job by job simply create a group and specify that group and the classname in the Message_Configuration__c custom setting
	 *
	 * the interface to Chatter is provided by Notify.cls
	 */
	global static Map<Id, String> processBatchInformation(Id AsyncApexJobId, object thisClass, List<Notify.Message> messages){
		string processName = string.valueOf(thisClass).substringBefore(':');
		Map<Id, String> mChatterBodies = new Map<Id, String>();
		string body = '';
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('AsyncApexJob', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','TotalJobItems','Status','ParentJobId','NumberOfErrors','MethodName','LastProcessedOffset','LastProcessed','JobType',
			'JobItemsProcessed','ExtendedStatus','CreatedDate','CreatedById','createdBy.Name','CompletedDate','ApexClassId','ApexClass.Name'
		});
		soql.setWhereClause('Id = :AsyncApexJobId');
		AsyncApexJob a = Database.query(soql.getQuery());
		
		Map<String, Message_Configuration__c> msgConfig = Message_Configuration__c.getAll();
		
		Set<Id> groupIds = new Set<Id>();
		for(String configVal : msgConfig.keySet()){
			if(processName == msgConfig.get(configVal).process_name__c && msgConfig.get(configVal).group__c != null && msgConfig.get(configVal).group__c != ''){
				groupIds.add(msgConfig.get(configVal).group__c);
			}
		}
							
		//ConnectAPI - Define FeedType and post contents
		//ConnectAPI.FeedType feedType = ConnectAPI.FeedType.Record;
		
		ConnectAPI.MessageBodyInput messageBodyInput = new ConnectAPI.MessageBodyInput();
		messageBodyInput.messageSegments = new List<ConnectAPI.MessageSegmentInput>();
		
		ConnectAPI.MentionSegmentInput mentionSegment = new ConnectAPI.MentionSegmentInput();
		mentionSegment.Id = a.createdById;
		
		ConnectAPI.TextSegmentInput overviewSegment = new ConnectAPI.TextSegmentInput();
		overviewSegment.text = ' - ' + a.JobType + ' job ' + a.ApexClass.Name + ' completed. \r\n';
		// with ' + a.NumberOfErrors + ' errors out of a total of ' + a.JobItemsProcessed + ' job items processed. \r\n' ;
		
		ConnectAPI.TextSegmentInput statusTextSegment = new ConnectAPI.TextSegmentInput();
		statusTextSegment.text = a.ExtendedStatus + '\r\n';
		
		ConnectAPI.TextSegmentInput issuesDetailSegment = new ConnectAPI.TextSegmentInput();
		issuesDetailSegment.text = '\r\n The following jobs had issues: \r\n' ;
		
		integer length = 0;
		List<ConnectAPI.TextSegmentInput> processMessageSegments = new List<ConnectAPI.TextSegmentInput>();
		ConnectAPI.TextSegmentInput endSegment;
		
		for(integer i=0; i<messages.size(); i++){
			
			ConnectAPI.TextSegmentInput msgSegment = new ConnectAPI.TextSegmentInput();
			msgSegment.text = messages[i].title + ': ' + messages[i].body + '\r\n';
			processMessageSegments.add(msgSegment);
			length += messages[i].title.length() + messages[i].body.length();
			if(length > 500){
				endSegment = new ConnectAPI.TextSegmentInput();
				endSegment.text = 'and ' + string.valueOF(messages.size()-i-1) + ' more...';
				processMessageSegments.add(endSegment);
				break;
			}
			
		}
		
		//Construct the post body input
		messageBodyInput.messageSegments.add(mentionSegment);
		messageBodyInput.messageSegments.add(overviewSegment);
		body += overviewSegment.text + '<br/><br/>';
		if(a.extendedStatus != null){
			messageBodyInput.messageSegments.add(statusTextSegment);
			body += statusTextSegment.text + '<br/>';
		}
		if(messages.size()>0){
			messageBodyInput.messageSegments.add(issuesDetailSegment);
			body+= issuesDetailSegment.text + '<br/>';
			for(ConnectAPI.TextSegmentInput seg : processMessageSegments){
				messageBodyInput.messageSegments.add(seg);
				body += seg.text + '<br/>';
			}
			if(endSegment != null){
				body += endSegment.text + '<br/>';
			}
		}
		
		//Link attachment not needed
		/*
		//Add a link to the apex jobs monitoring page
		ConnectAPI.LinkAttachmentInput linkAttachment = new ConnectAPI.LinkAttachmentInput();
		linkAttachment.url = URL.getSalesforceBaseUrl().toExternalForm() + '/apexpages/setup/listAsyncApexJobs.apexp';
		linkAttachment.urlName = 'Monitor all Apex Jobs';
		*/
		
		ConnectAPI.FeedItemInput feedItemInput = new ConnectAPI.FeedItemInput();
		feedItemInput.body = messageBodyInput;
		//feedItemInput.attachment = linkAttachment;
		
		ConnectApi.FeedElement feedElement;
		if (groupIds.size()>0) {
			//Chatter up to 100 groups
			integer counter = 0;
			for (Id groupId : groupIds) {
				if (counter < 100) {
					try {
						feedItemInput.subjectId = groupId ;
						feedElement = ConnectAPI.ChatterFeeds.postFeedElement(null, feedItemInput);//api v36 changes
						mChatterBodies.put(feedElement.Id, body);
					} catch(Exception ex) {
						//TEST CATCH: system.UnsupportedOperationException: ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true).
						//Catching exceptions to avoid using seealldata=true and test.isRunningTest
						//Move on - email will also be sent from the batch
					}
				} else {
					break;
				}
			}
		} else {
			try{
				feedItemInput.subjectId = a.CreatedById;
				feedElement = ConnectAPI.ChatterFeeds.postFeedElement(null, feedItemInput); //api v36 changes
			} catch(exception ex) {
				//TEST CATCH: system.UnsupportedOperationException: ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true).
				//Catching exceptions to avoid using seealldata=true and test.isRunningTest
				//Move on - email will also be sent from the batch
			}
			if(feedElement != null) {
				mChatterBodies.put(feedElement.Id, body);
			}
		}
		return mChatterBodies;
		/* Chatter commenting code if needed */
		/*
			ConnectAPI.CommentInput commentInput = new ConnectAPI.CommentInput();
			ConnectAPI.MessageBodyInput messageBodyInputComment = new ConnectAPI.MessageBodyInput();
			messageBodyInputComment.messageSegments = new List<ConnectAPI.MessageSegmentInput>();
			
			ConnectAPI.LinkSegmentInput linkCommentSegment = new ConnectAPI.LinkSegmentInput();
			linkCommentSegment.url = 'Or add error links in comments: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/[RECORDID]';
			messageBodyInputComment.messageSegments.add(linkCommentSegment);
			
			commentInput.body = messageBodyInputComment;
			
			ConnectAPI.Comment commentItemPost = ConnectAPI.ChatterFeeds.postComment(null, feedItemPost.Id, commentInput, null);
		*/
	}
	
}