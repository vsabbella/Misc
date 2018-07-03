public with sharing class ClaimSettleAgainstClaimsExt extends BaseController{
	 
	public Apexpages.Standardcontroller con {get;set;}
	public string NamespaceUU { get { return KSE.NamespaceUU; }}
	public boolean isValid {get;set;}
	/*KNDY-15530 This feature is not currently supported. 
	public Decimal amountLeft {get;set;}
	public class ClaimWrapper {
		
	 	public Claim__c claim {get;set;}
		public Decimal amountApplied {get;set;}
		
		public ClaimWrapper(Claim__c claim){
			
			this.claim = claim;
			amountApplied = 0; 
			
		}
		
		
	}
	public GridRelatedListController.GridRelatedListConfig claimsGridConfig {get; set;}
	public String claimFieldList ;
	
	public list<SelectOption> options{ //this would later be initialized from a custom setting. 
		get{
			 options = new list<SelectOption>{new SelectOption('R','Write Off'), new SelectOption('C','Chargeback'), new SelectOption('N','Split The Claim')};
			 return options;
		}
		set ;
	}
	public String selectedOption {get;set;}*/
	public ClaimSettleAgainstClaimsExt()
	{
		//EMPTY CONSTRUCTOR
	}
	public ClaimSettleAgainstClaimsExt(ApexPages.standardController controller)
	{
		con =controller;
		/*KNDY-15530 This feature is not currently supported. 
		selectedOption = 'R';
		
		claimsGridConfig = new GridRelatedListController.GridRelatedListConfig();
        claimsGridConfig.uniqueId = 'claimsGrid';
        claimsGridConfig.title = 'Claims';
        claimsGridConfig.objectName = 'Claim__c';
        claimsGridConfig.fieldset = 'Settle_against_Invoices';
        claimsGridConfig.buttons = 'cancel, search';
        claimsGridConfig.alwaysUseFullDateTimeFormat = false;
        */
        validate();
        /*KNDY-15530 This feature is not currently supported. 
        if(isValid)
        {
        	Claim__c claim = (Claim__c)con.getRecord();
        	amountLeft = claim.Claim_Balance__c;
        }
		*/
	}
	
	public void validate()
	{
		//KNDY-15530 - this feature is not supported so we are setting up error message on load
		isValid =false;
		Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.Error, Label.Feature_Not_Supported));
		
		/*KNDY-15530 This feature is not currently supported. 
		Claim__c claim = (Claim__c)con.getRecord();
		system.debug('CLAIM EXT VALIDATE: '+claim.Claim_Balance__c +' '+ claim.Amount__c);
		if(claim.status__c == ClaimService.STATUS_CLOSED || claim.status__c == ClaimService.STATUS_CANCELLED)
		{
			isValid =false;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.Error, Label.Claim_is_closed));
		}
		else if(claim.Claim_Balance__c != claim.Amount__c)
		{
			isValid =false;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.Error, 'Cannot settle Claims if it already has lines associated with it'));
		}
		else
			isValid = true;
			*/
	}
	
	  /*KNDY-15530 This feature is not currently supported. 
	public String getclaimFieldList() {
        if (String.isBlank(claimFieldList) && claimsGridConfig != null) {
        	
        	// get the credit memo field info list
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();
        	
        	// get the Payment line details field info list
            fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos(claimsGridConfig.objectName, claimsGridConfig.fieldset));
            
            Set<String> hiddenFields = new Set<String> { 'Id','Bill_To_Customer__c','Sold_To_Customer__c','Company__c','Parent_Customer__c'};
            
            FieldInfo selectFieldInfoItem = new FieldInfo();
        	selectFieldInfoItem.field = 'amountApplied';
        	selectFieldInfoItem.title = 'Amount Applied';
        	selectFieldInfoItem.fieldtype = 'double';
        	selectFieldInfoItem.editable = true;
        	selectFieldInfoItem.scale = 6;
        	selectFieldInfoItem.precision = 2;
        	fieldInfoList.add(selectFieldInfoItem);
            
            // set all the fields as readonly
            for(Integer i = 1; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	if(fieldName != 'amountApplied')
            		fieldInfoList[i].field = 'claim.' + fieldName;
                fieldInfoList[i].editable = false;
                fieldInfoList[i].filterable = true;
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            	
            	
            	
            	if(fieldName == 'amountApplied'){
            	    fieldInfoList[i].editable = true;    
            	}
            }
            
            claimFieldList = JSON.serialize(fieldInfoList);
        }
        
        return claimFieldList;
    }
    
    public String getclaimsGridConfigJson() {
        String configStr = JSON.serialize(this.claimsGridConfig);
        return configStr;
    }
    
    @RemoteAction
	public static JsonResult getClaims(String claimId){
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Claim__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Claim_Balance__c','Bill_To_Customer__c','Sold_To_Customer__c','Parent_Customer__c','Source__c'
		});
		soql.setWhereClause('id = :claimId');
		soql.setLimit(1);
		Claim__c c = Database.query(soql.getQuery());

		SchemaUtil shUtil = new SchemaUtil();
		Id billToId = c.Bill_To_Customer__c;
		Id soldTo = c.Sold_To_Customer__c;
		id customerId = c.Parent_Customer__c;
		system.debug('bill to and sold to : '+ billtoId+' '+soldTo);
		String whereClause = 'Claim_Balance__c != 0 and Status__c != \'Closed\' and Status__c != \'Cancelled\' and Parent_Customer__c = :customerId  and  Id not in (Select Claim__c from Claim_Line__c)'; //dont query claims that have lines on them. need to know how to lock the selected
																																											  //claims after save is hit. 
		//ensure we show only those claims that can be used to settle the CI
		if(c.Claim_Balance__c > 0)
			whereClause += ' and Claim_Balance__c < 0 ';
		else
			whereClause += ' and Claim_Balance__c > 0 ';
		
		soql = new SOQLUtil('Claim__c', TRUE);
		soql.addFields('Settle_against_Invoices');
		soql.addFields(new Set<String> { 'Id','Bill_To_Customer__c','Sold_To_Customer__c','Company__c','Parent_Customer__c'});
		soql.setWhereClause(whereClause);

		system.debug('query: '+soql.getQuery())	;
		list<ClaimWrapper> listClaimWrapper = new list<ClaimWrapper>();			 
		for(Claim__c claim : (List<Claim__c>) Database.query(soql.getQuery())){
		    listClaimWrapper.add(new ClaimWrapper(claim));
		    
		}
			
		JsonResult result = new JsonResult();
		result.records = listClaimWrapper;
        result.total = listClaimWrapper.size();
        
        
		
        
        return result;   
	}
	
	@RemoteAction
	public static JSONResult settleClaims(list<ClaimWrapper> updatedClaims, String claimId)
	{
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Claim__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Amount__c','Parent_Customer__c','Bill_To_Customer__c','Sold_to_Customer__c','Status__c','Source__c','Type__c','SubType__c',
			'Company__c'
		});
		soql.setWhereClause('id = :claimId');
		soql.setLimit(1);
		Claim__c claim = Database.query(soql.getQuery());

		//split the source claim here 
		JsonResult result = new JsonResult();
		try
		{
			ClaimSettleAgainstClaimsExt ext = new ClaimSettleAgainstClaimsExt();
			ext.settleClaims(updatedClaims,claim);
			result.addMessage('Claims have been settled against each other', ApexPages.Severity.CONFIRM);
			
		
		}catch(Exception ex)
		{
			result.success = false;
			result.addMessage(ex.getMessage(), ApexPages.Severity.ERROR);
		}
		return result;   
	}
	
	@RemoteAction
	public static JSONResult proceedOnAmountLeft(list<ClaimWrapper> updatedClaims, String claimId, String selectedOption, String resolutionCodeId, Decimal amountLeft)
	{
		JsonResult result = new JsonResult();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Claim__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Company__c','Amount__c','Parent_Customer__c','Bill_To_Customer__c','Sold_to_Customer__c','Status__c','Source__c','Type__c',
			'SubType__c','Claim_Date__c'
		});
		soql.setWhereClause('id = :claimId');
		soql.setLimit(1);
		Claim__c claim = Database.query(soql.getQuery());
		
		//first we need to split into 2 claims: one that is settled and the other we decide what to do with it
		ClaimSettleAgainstClaimsExt ext = new ClaimSettleAgainstClaimsExt();
		Claim__c settledClaim, leftOutClaim;
		
		Savepoint sp = Database.setSavepoint();
		try
		{
			
			ext.settleClaims(updatedClaims,claim);
			
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			soql = new SOQLUtil('Claim__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id'
			});
			Id claimId2 = claim.Id;
			soql.setWhereClause('Related_Claim__c = :claimId2');
			soql.setLimit(1);
			leftOutClaim = Database.query(soql.getQuery());

			//Just map any data before we call the methods
			if(selectedOption.equals('R'))
			{
				if(resolutionCodeId.trim() != '')
				{
					leftOutClaim.Resolution_Code__c = resolutionCodeId;
				}
				
				DML.updateAsUser(leftOutClaim);
			}
			
			
			if(selectedOption.equals('R'))
			{
				ClaimService.resolve(new set<Id>{leftOutClaim.Id});
				result.addMessage('Claims have been settled against each other', ApexPages.Severity.CONFIRM); //KNDY-15529
				result.addMessage(Label.Split_Claim_Resolved, ApexPages.Severity.CONFIRM);
			}
			else if(selectedOption.equals('C'))
			{
				Map<Id, Customer_Invoice__c> mChargeBacks = ClaimService.chargeback(new set<Id>{leftOutClaim.Id});
				system.debug('error in chargeback');
				result.addMessage('Claims have been settled against each other', ApexPages.Severity.CONFIRM);//KNDY-15529
				result.addMessage(Label.Split_Claim_Chargebacked, ApexPages.Severity.CONFIRM);
			}
			else
			{
				result.addMessage('Claims have been settled against each other', ApexPages.Severity.CONFIRM);//KNDY-15529
				result.addMessage(Label.Split_Claim_Created, ApexPages.Severity.CONFIRM);
			}
			
			
			
			
		}catch(Exception ex)
		{
			system.debug('on exception=='+result);
			Database.rollBack(sp);
			result.success = false;
			result.addMessage(ex.getMessage(), ApexPages.Severity.ERROR);
		}
		
		
		return result;
	}
	
	
	public void settleClaims(list<ClaimWrapper> updatedClaims, Claim__c sourceClaim)
	{
		list<Claim_Line__c> insertCLaimLines = new list<Claim_Line__c>();
		list<Claim__c> settleAgainstClaims = new list<Claim__c>();
		
		for(ClaimWrapper cW : updatedClaims)
		{
			if(cw.amountApplied != 0) {
				insertCLaimLines.add(new Claim_Line__c(Claim__c = sourceClaim.ID, Total_Amount__c = (-1)*cw.amountApplied, Settling_Claim__c = cW.claim.Id));
				settleAgainstClaims.add(cW.claim);
			}
			
		}
		Savepoint sp = Database.setSavepoint();
		try
		{
			if(!insertCLaimLines.isEmpty()) 
				DML.insertAsUser(insertCLaimLines);
			ClaimService.settleClaims(new set<Id> {sourceClaim.Id});
		}catch(Exception ex)
		{
			Database.rollback(sp);
			throw ex;
		}
		
		
	}
	public Claim__c createClaimSplit(Claim__c c, Decimal Amount)
	{
		Claim__c tmpClaim = c.clone(false, true, false, false);
		tmpClaim.Amount__c = Amount;
		tmpClaim.Related_Claim__c = c.Id;
		system.debug('tmpClaim: '+tmpClaim);
		return tmpClaim;
		
	}
	
	public void reset()
	{
		system.debug('HELLO');
		con.reset();
		amountLeft =0;
	}*/

}