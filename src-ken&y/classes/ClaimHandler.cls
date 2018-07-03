public with sharing class ClaimHandler {
	
	public class ClaimState implements ProcessService.State{
		
		public integer stepcounter;
		private List<Claim__c> claims;
		private Map<string, Group> mGroups;
		public ClaimState(){
			stepcounter = 0;
		}
		
		public Map<string, Group> queueSelector(){
			if(mGroups == null){
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				SOQLUtil soql = new SOQLUtil('QueuesObject', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','queue.name','queue.developername','sobjecttype'
				});
				soql.setWhereClause('sobjecttype = \'Claim__c\'');
				List<QueueSobject> claimsQueues = Database.query(soql.getQuery());

				mGroups = new Map<string, Group>();
				for(QueueSobject qso : claimsQueues){
					mGroups.put(qso.queue.developerName, qso.queue);
				}
			}
			return mGroups;
		}
		
		public List<Claim__c> claimSelector(List<Claim__c> stepClaims){
			if(claims == null){
				SOQLUtil soql = new SOQLUtil('Claim__c', TRUE);
				soql.addAllFields();
				soql.addFields(new Set<String>{'Customer_Receipt_Line__r.Customer_Invoice__r.Sales_Order__r.Ship_From_Location__r.Facility__c', 'Customer_Invoice__r.Balance__c',
												'Customer_Invoice__r.Invoice_Type__c'});
				soql.setWhereClause('Id IN :stepClaims');
				system.debug('claimsQuery: ' + soql.getQuery());
				claims = Database.query(soql.getQuery());
			}
			system.debug('claimSelector: ' + claims);
			return claims;
		}
		
	}
	
	public class CreateLines implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, list<SObject> records)
		{
			ClaimState cs = (ClaimState)processState;
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			cs.claims = cs.ClaimSelector(records);
			map<Id,Claim__c> mapClaims = new map<Id,Claim__c>(cs.claims);
			system.debug('inside action createLines: mapClaims '+mapClaims);
			ClaimService.createClaimLines(mapClaims.keyset());
			
			
			return resp;
		}
	}
	
	public class AddCustomerInvoiceToClaimLines implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, list<SObject> records)
		{
			ClaimState cs = (ClaimState)processState;
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			map<Id,Claim__c> mapClaims = new map<Id,Claim__c>(cs.claims);
			system.debug('inside action AddCustomerInvoiceToClaimLines: mapClaims '+mapClaims);
			list<Claim_Line__c>claimLines = new list<Claim_Line__c>();

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Claim_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'ID','Claim__c','Claim__r.Amount__c','Total_Amount__c','Claim__r.Customer_Invoice__c'
			});
			Set<Id> claimIds = mapClaims.keyset();
			soql.setWhereClause('Claim__c = :claimIds');
			for(Claim_Line__c claimLine : Database.query(soql.getQuery())) {
				claimLine.Customer_Invoice__c = claimLine.Claim__r.Customer_Invoice__c;
				claimLines.add(claimLine);
			}
			system.debug('inside action AddCustomerInvoiceToClaimLines: mapClaims '+claimLines);
			DML.updateAsUser(claimLines);
			
			
			return resp;
		}
	}
	
	/*public class ConsumeCredit implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, list<SObject> records)
		{
			ClaimState cs = (ClaimState)processState;
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			map<Id,Claim__c> mapClaims = new map<Id,Claim__c>(cs.claims);
			system.debug('inside action AddCustomerInvoiceToClaimLines: mapClaims '+mapClaims);
			ClaimService.credit(new set<set<Id>>{mapClaims.keyset()});
			
			
			
			return resp;
		}
	}*/
	
	public class ChatterOnFacility implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			
			Map<Id, Claim__c> mClaims = new Map<Id, Claim__c>(cs.claimSelector(records));
			
			for(Claim__c c : (List<Claim__c>)records){
					
				Notify.chatterOn(	this, 
									mClaims.get(c.Id).Customer_Receipt_Line__r.Customer_Invoice__r.Sales_Order__r.Ship_From_Location__r.Facility__c, 
									new List<Notify.Message>{new Notify.Message(Label.Warehouse_research_required , Label.Review_quantity_on_hand_for_Claim + mClaims.get(c.Id).Name)});
					
				
			}
			
			return resp;
		}
		
	} 
	
	public class UpdateRecords implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			DML.updateAsUser(records);
			return resp;
		}
		
	}
	/* AR-13
	public class Adjustment implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			Map<Id, Claim__c> mClaims = new Map<Id, Claim__c>((List<Claim__c>)records);
			ClaimService.createInvoiceAdjustments(mClaims.keySet());
			for(Claim__c c : (List<Claim__c>)records){
				c.Settlement_Method__c = 'Adjustment';
				c.Status__c = 'Closed';
				c.Settlement_Date__c = system.today();
			}
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			//resp.step = new Step__c(Id = step.next_step__c);
			
			return resp;
		}
		
	}*/
	
	public class Resolve implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			system.debug('WRITE OFF');
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			Map<Id, Claim__c> mClaims = new Map<Id, Claim__c>((List<Claim__c>)records);
			system.debug('WRITE OFF--' + mClaims.keySet());
			ClaimService.resolve(mClaims.keySet());
			//KNDY-15529 - Commented out because even after error in resolve method it will change the state of claim as closed. 
			/*for(Claim__c c : (List<Claim__c>)records){
				c.Settlement_Method__c = ClaimService.SETTLE_AUTO;
				c.Status__c = ClaimService.STATUS_CLOSED;
				c.Settlement_Date__c = system.today();
			}*/
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			//resp.step = new Step__c(Id = step.next_step__c);
			
			return resp;
		}
		
	}
	
	
	public class Open implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			for(Claim__c c : (List<Claim__c>)records){
				System.Debug('Claim object'+c);
				c.Status__c = ClaimService.STATUS_OPEN;
				c.Settlement_Date__c = null;
				c.Settlement_Method__c = 'Automatic';
			}
			
			DML.updateAsUser(records);
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			
			return resp;
		}
	}
	
	public class Reopen implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			Map<Id, Claim__c> mClaims = new Map<Id, Claim__c>((List<Claim__c>)records);
			
			ClaimService.reopen(mClaims.keySet());
			
			for(Claim__c c : (List<Claim__c>)records){
				c.Status__c = ClaimService.STATUS_OPEN;
    			c.Settlement_Method__c = null;
    			c.Settlement_Date__c = null;
			}
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			
			return resp;
			
		}
		
	}
	
	public class Review implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			Map<Id, Claim__c> mClaims = new Map<Id, Claim__c>(cs.claimSelector(records));
			system.debug(mClaims);
			List<Task> insertTasks = new List<Task>();
			for(Claim__c c : (List<Claim__c>)records){
				Task iTask = new Task();
				iTask.whatId = c.Id;
				iTask.status = 'Not Started';
				iTask.priority = 'Normal';
				iTask.activityDate = system.today() + 7;
				iTask.subject = 'Review Claim ' + mClaims.get(c.Id).Name;
				system.debug('mClaims ownerid: ' + mClaims.get(c.Id).ownerId);
				if(string.valueOf(mClaims.get(c.Id).ownerId).left(3) == '005'){
					iTask.ownerId = mClaims.get(c.Id).ownerId;
				}
				insertTasks.add(iTask);
			}
			
			DML.insertAsUser(insertTasks);
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			
			return resp;
		}
		
	}
	
	public class SubmitApproval implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			for(sObject rec : records){
				Approval.Processsubmitrequest req = new Approval.Processsubmitrequest();
				req.setObjectId(rec.Id);		
				Approval.Processresult result = Approval.process(req);
			}	
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			
			return resp;
		}
		
	}
	
	/*
	
	
	public class ChargeBack implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			Map<Id, Claim__c> mClaims = new Map<Id, Claim__c>((List<Claim__c>)records);
			ClaimService.createChargebacks(mClaims.keySet());
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			
			return resp;
		}
		
	}
	
	public class AssignToOSDClaims implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			
			Id overShortQueueId = cs.queueSelector().get('OSD_Claims').Id;
			
			for(Claim__c c : (List<Claim__c>)records){
				c.ownerId = overShortQueueId;
				//c.owner = cs.queueSelector().get('OSD_Claims');
				DML.updateAsUser(c.owner);
				
				c.Status__c = 'Open';
			}
			
			DML.updateAsUser(records);
			
			return resp;
		}
		
	} 
	
	public class SendOSDRPODEmail implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			
			Map<Id, Claim__c> mClaims = new Map<Id, Claim__c>(cs.claimSelector(records));
			
			//Messaging.reserveSingleEmailCapacity(records.size());
			
			//List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
			
			system.debug('email records: ' + records);
			
			for(Claim__c c : (List<Claim__c>)records){
				//c.Reason__c = 'OSDR POD';
					
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		
				String[] toAddresses = new String[] {'ryan.sieve@kenandy.com'}; 
				String[] ccAddresses = new String[] {'ryan.sieve@kenandy.com'};
				mail.setToAddresses(toAddresses);
				mail.setCcAddresses(ccAddresses);
				
				mail.setReplyTo('noreply@kenandy.com');
				
				mail.setSenderDisplayName('Kenandy Support');
				
				// Specify the subject line for your email address.
				//mail.setSubject('New Case Created : ' + case.Id);
				
				// Set to True if you want to BCC yourself on the email.
				mail.setBccSender(false);
				
				// Optionally append the salesforce.com email signature to the email.
				// The email address of the user executing the Apex Code will be used.
				mail.setUseSignature(false);
				
				//Hard coding for demo...
				mail.setTemplateId('00Xi0000000IzUr');
				mail.setTargetObjectId('003i000000Xf7Pl');
				mail.setWhatId(c.Id);
				//emails.add(mail);
				system.debug('sending email: ' + mail);
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
				//Messaging.Sendemailresult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
				//system.debug('results: ' + results);
					
			}
			
			return resp;
		}
		
	}
	
	public class Close implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			for(Claim__c c : (List<Claim__c>)records){
				c.Status__c = 'Closed';
				c.Settlement_Date__c = system.today();
			}
			
			DML.updateAsUser(records);
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			
			return resp;
		}
	}
	
	public class AssignToTradeClaims implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			
			Id tradeQueueId = cs.queueSelector().get('Trade_Claims').Id;
			
			for(Claim__c c : (List<Claim__c>)records){
				c.ownerId = tradeQueueId;
				c.Status__c = 'Open';
			}
			
			DML.updateAsUser(records);
			
			return resp;
		}
		
	} 
	
	
	public class ClaimStatusValidation implements ProcessService.Action{
		
		public ProcessService.Response execute(ProcessService.State processState, List<sObject> records){
			
			ClaimState cs = (ClaimState)processState;
			cs.stepcounter++;
			
			Map<Id, Claim__c> mOldClaims = trigger.oldMap;
			
			for(Claim__c c : (List<Claim__c>)records){
				if(mOldClaims.containsKey(c.Id)){
					if(ClaimService.claimStatusMods.contains(c.Id)){
						
					}
				}
			}	
			
			ProcessService.Response resp = new ProcessService.Response();
			resp.state = cs;
			resp.step = null;
			
			return resp;
		}
		
	}
	*/
	
}