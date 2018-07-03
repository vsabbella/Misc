public with sharing class ClaimSplitExt{ // extends BaseController
	
	public Apexpages.Standardcontroller con {get;set;}
	public List<ClaimDetail> splitClaims {get;set;}
	public boolean disabled {get;private set;}
	public boolean isTrade {get;set;}
	public boolean enableUndo {get;private set;}
	public string NamespaceUU { get { return KSE.NamespaceUU; }} 
	private set<string> addlFields = new set<String>{'settlement_method__c', 'amount__c', 'status__c', 'Claim_Date__c', 'aging_date__c', 'Company__c', 'customer_receipt_line__c', 'payment_amount__c', 
											'currency__c', 'description__c', 'resolution_code__c',
											'type__c', 'subtype__c', 'customer_receipt__c', 'sold_to_customer__c', 'bill_to_customer__c', 'parent_customer__c', 'ar_reason_code__c', 'track__c', 'reference__c', 'correspondant__c','Source__c'}; //TPM-301 adding source field to carry the data over to split claims
	//public GridRelatedListController.GridRelatedListConfig config {get;set;}
	public   boolean isSplitComplete {get; set;}
	public boolean redirect {get;private set;}
	public ClaimSplitExt(Apexpages.Standardcontroller controller){
		con = controller;
		splitClaims = new List<ClaimDetail>();
		isTrade = false;
		
		system.debug('in constructor:isSplitComplete  '+isSplitComplete);
		if(!test.isRunningTest()){
			//This is a hack, but prevents us from having to load this in the standardcontroller via the markup
			con.addFields(new List<string>(addlFields));
		}
		Claim__c claim = (Claim__c)con.getRecord();
		if(claim.status__c == ClaimService.STATUS_CLOSED || claim.status__c == ClaimService.STATUS_CANCELLED) //OTC-710
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,Label.Claim_is_closed));
			isSplitComplete =true;
		}
		else
			isSplitComplete =false;
		if(claim.Source__c == 'Trade')
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,Label.Cannot_split_trade_claims));
			isTrade = true;
				//return;
		}
		else
		{
			validateSplit();
			updateSplitClaims();
		}
		
		
		
	}
	
	public void updateSplitClaims(){
		Id claimId = con.getId();
		//claimIds = new List<Id>();
		SOQLUtil soql = new SOQLUtil('Claim__c', TRUE);
		soql.addFields('Split');
		soql.addFields(addlFields);
		soql.setWhereClause('related_claim__c = :claimId');
		soql.setOrderByClause('createddate asc');
		List<Claim__c> relatedClaims = database.query(soql.getQuery());
		set<ClaimDetail> templist = new set<ClaimDetail>(splitClaims);
		system.debug('tempList: '+tempList);
		for(ClaimDetail cd : splitClaims)
		{
			if(cd.claim.Id !=null)
			{
				templist.remove(cd);
			}
			
		}
		
		splitClaims = new list<ClaimDetail>(tempList);
		system.debug('splitClaims: '+splitClaims);
		
		if(relatedClaims.size() > 0){
			for(Claim__c c : relatedClaims){
				splitClaims.add(new ClaimDetail(false, c));	
				//claimIds.add(c.Id);
			}
		}else{
			addClaim();
		}
	}
	
	public void addClaim(){
		Claim__c claim = (Claim__c)con.getRecord();
		Claim__c tmpClaim = claim.clone(false, true, false, false);
		tmpClaim.name = null;
		tmpClaim.Amount__c = 0;
		tmpClaim.Resolution_Code__c = null; //AR-39 
		tmpClaim.Related_Claim__c = claim.Id;
		splitClaims.add(new ClaimDetail(false, tmpClaim));
	}
	
	
	public void saveClaims(){ //OTC-560
		
		List<Claim__c> upsertClaims = new List<Claim__c>();
		Claim__c claim = (Claim__c)con.getRecord();
		
		decimal SplitBalance = getSplitBalance();
		for(ClaimDetail cd : splitClaims){
			if(cd.claim.Amount__c == 0 || cd.claim.Amount__c == null )
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,Label.Cannot_save_Claim_0_Amount_Split));
				return;
			}else if(cd.claim.Amount__c<0 && claim.amount__c>0 ||(cd.claim.Amount__c>0 && claim.amount__c<0)){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,label.Claim_amount_cannot_be_split_using_reverse_amounts+' ('+ claim.amount__c+' => ' +cd.claim.Amount__c + ')' ));
					return;
	
			}
			else
			{
				upsertClaims.add(cd.claim);
				
			}
			
			
				
		}
		
		Savepoint sp = Database.setSavepoint();
		try{
			if(SplitBalance == 0)
			{
				DML.checkUpsertAsUser(upsertClaims); upsert upsertClaims;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, Label.Changes_saved));
				updateSplitClaims();
			}
			else
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, Label.Changes_not_saved + Label.Total_split_amount_doesnot_equal_to_claim_amount + ' ' +claim.Name +', '+ (claim.Amount__c - SplitBalance) + ' / ' + claim.Amount__c));				
		}catch(Exception ex){
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Changes_not_saved + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
		}
		
		//updateSplitClaims();
	}
	
	public pageReference goBack(){
		List<Claim__c> deleteClaims = new List<Claim__c>();
		Claim__c claim = (Claim__c)con.getRecord();
		//decimal SplitBalance = getSplitBalance();
		system.debug('is split: '+isSplitComplete);		
		Savepoint sp = Database.setSavepoint();
		try{
			if(!isSplitComplete)
			{	
				for(ClaimDetail cd : splitClaims){
					if(cd.claim.id != null)
						deleteClaims.add(cd.claim);
				}
				if(!deleteClaims.isEmpty()){
					DML.deleteAsUser(deleteClaims);
					
				}
			}
				
			
			
			PageReference cancel = con.cancel();
			system.debug('cancel '+cancel);
			redirect = true;
        	return null;
		}catch(Exception ex){
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Claims_were_not_deleted + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
			redirect = false;
			return null;
		}		
		
	}
	
	public void deleteClaims(){
		
		List<Claim__c> deleteClaims = new List<Claim__c>();
		set<claimDetail> deleteRecs = new set<ClaimDetail>();
		for(ClaimDetail cd : splitClaims){
			if(cd.selected ){
				if(cd.claim.Id != null)
					deleteClaims.add(cd.claim);
				else
					deleteRecs.add(cd);
			}
			
		}
		
		Savepoint sp = Database.setSavepoint();
		try{
			if(deleteClaims.size() > 0){
				DML.deleteAsUser(deleteClaims);
				
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, Label.Selected_claims_were_deleted));
			}else{
				if(deleteRecs.isEmpty())
					ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, Label.Select_one_or_more_claims));
			}
			
			if (deleteRecs.size() >0 ){ //KNDY-12871
				set<ClaimDetail> temp = new set<ClaimDetail>(splitClaims);
				temp.removeAll(deleteRecs);
				system.debug('temp=='+temp.size() );
				splitClaims = new list<ClaimDetail>(temp);
			
				
			}
			system.debug('splitClaims=='+splitClaims.size());
			if (splitClaims.size() == 0 || deleteClaims.size() > 0) updateSplitClaims(); //KNDY-12871
		}catch(Exception ex){
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Claims_were_not_deleted + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
		}
		
		
		
	}
	
	public void validateSplit(){
		Claim__c claim = (Claim__c)con.getRecord();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Claim_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id'
		});
		Id cId = claim.id;
		soql.setWhereClause('Claim__c = :cId');
		list<Claim_Line__c> lCLs = Database.query(soql.getQuery());

		enableUndo = false;
		disabled = false;
		if(claim.status__c == ClaimService.STATUS_CLOSED || claim.status__c == ClaimService.STATUS_CANCELLED){
			disabled = true;
			if(claim.Settlement_Method__c == ClaimService.SETTLE_SPLIT){
				enableUndo = true;
			}
		}
		else if(lCLs != null && lCLs.size()>0)
		{
			disabled= true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Cannot_split_claim_if_they_have_lines));
		}
	}
	
	public void finishSplit(){
		Claim__c claim = (Claim__c)con.getRecord();
		
		Savepoint sp = Database.setSavepoint();
		try{
			ClaimService.finishSplit(new set<Id>{con.getId()});
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, Label.Claim_successfully_split));
		}catch(Exception ex){
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Claim_has_not_been_split + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
			return; //OTC-595
		}
		
		claim.Status__c = ClaimService.STATUS_CLOSED;
		claim.Settlement_Date__c = system.today();
		claim.Settlement_Method__c = ClaimService.SETTLE_SPLIT;
		isSplitComplete =true;
		system.debug('iscomplete '+isSplitComplete);
		validateSplit();
		
	}
	
	public void resolve(){
		
		List<Claim__c> resolveClaims = new List<Claim__c>();
		for(ClaimDetail cd : splitClaims){
			if(cd.selected){
				resolveClaims.add(cd.claim);
				if(cd.claim.resolution_code__c == null){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, Label.Choose_resolution_code_for_selected_claims));
					return;
				}
				else if (cd.claim.Source__c == ClaimService.SOURCE_MANUAL){//KNDY-15529
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Cannot_Chargeback_Writeoff_Manual_Claim));
					return;
				}
			}
		}
		
		Savepoint sp = Database.setSavepoint();
		try{
			if(resolveClaims.size() > 0){
				DML.checkUpsertAsUser(resolveClaims); upsert resolveClaims;
				Map<Id, Claim__c> mResolveClaims = new Map<Id, Claim__c>(resolveClaims);
			 	ClaimService.resolve(mResolveClaims.keySet());
			 	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, Label.Claim_was_resolved));
			}else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, Label.Select_one_or_more_claims));
			}
			
		}catch(Exception ex){
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Claims_were_not_resolved + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
		}
		
		if(resolveClaims.size() > 0) updateSplitClaims(); //KNDY-12871
	}
	
	public decimal getSplitBalance(){
		Claim__c claim = (Claim__c)con.getRecord();
		decimal splitBalance = claim.amount__c;
		splitBalance.setScale(6);
		for(ClaimDetail cd : splitClaims){ 
			if(cd.claim.amount__c != null){
				splitBalance -= cd.claim.amount__c;
			
			}
		}
		system.debug('splitBalance: ' + splitBalance);
		return splitBalance;
		
	}
	
	public pageReference undoSplit(){
		pageReference undoSplitPage = Page.ClaimUndoSplit;
		undoSplitPage.getParameters().put('Id', con.getId());
		return undoSplitPage;
	}
	
	public class ClaimDetail{
		public boolean selected {get;set;}
		public Claim__c claim {get;set;}
		
		public ClaimDetail(boolean inSelected, Claim__c inClaim){
			selected = inSelected;
			claim = inClaim;
		}
	}
	
}