public with sharing class PurchaseOrderService {
	
    public static final String PO_STATUS_OPEN = 'Open';
    public static final String PO_STATUS_CANCELLED = 'Cancelled';
    public static final String PO_STATUS_CLOSED = 'Closed';

    public static final String PO_APPROVAL_STATUS_PENDING = 'Pending Authorization';
    public static final String PO_APPROVAL_STATUS_APPROVED = 'Approved';

    public static final String PO_TYPE_SUBCONTRACT = 'SubContract';
    public static final String PO_TYPE_DROP_SHIP = 'Drop Ship';
    
	//public static final String PO_ITEM_SOURCE_EXPENSE = 'Expense' ;
	public static String POType;
	
	public class PurchaseOrderServiceException extends Exception{
		
	}
	
	//KNDY - 1532
	public void updateReceiptLinesPOLinesPriceChange(List<Purchase_Order_Line__c> POLines, Map<Id,Purchase_Order_Line__c> oldMap){
		
		Map<Id,Purchase_Order_Line__c> linesToProcess = new Map<Id,Purchase_Order_Line__c>();
		Set<Id> linesToProcessIds = new Set<Id>();
		
		//Run through the POLines and check if the price has changed
		for(Purchase_Order_Line__c line:POLines){
			
			if(line.Unit_Price__c != oldMap.get(line.Id).Unit_Price__c){
				
				linesToProcess.put(line.Id,line);
				linesToProcessIds.add(line.Id);
				
			}
			
		}
		
		//If we don't have records to process we exit
		if(linesToProcess.size() == 0){
			return;
		}
		
		List<Receipt_Line__c> receiptsToUpdate = new List<Receipt_Line__c>();
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Receipt_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Purchase_Order_Line__c'
		});
		soql.setWhereClause('Purchase_Order_Line__c IN :linesToProcessIds');
		
		for(Receipt_Line__c receipt:Database.query(soql.getQuery())){

			receipt.Unit_Price__c = linesToProcess.get(receipt.Purchase_Order_Line__c).Unit_Price__c;
			receiptsToUpdate.add(receipt);
			
		}
		
		List<Supplier_Invoice_Line__c> receiptsInvoiceToUpdate = new List<Supplier_Invoice_Line__c>();
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Supplier_Invoice_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Purchase_Order_Line__c'
		});
		soql.setWhereClause('Purchase_Order_Line__c IN :linesToProcessIds and Supplier_Invoice__r.Status__c != \'Closed\'');
		
		for(Supplier_Invoice_Line__c receipt:Database.query(soql.getQuery())){
			
			receipt.Unit_Price__c = linesToProcess.get(receipt.Purchase_Order_Line__c).Unit_Price__c;
			receiptsInvoiceToUpdate.add(receipt);
			
		}
		
		
		DML.updateAsUser( receiptsToUpdate);
		DML.updateAsUser( receiptsInvoiceToUpdate);
		
		
	}
	
	public static void approvePOLines(){
	    
	    set<Id> poIds = new set<Id>();
	    //Set Has_POLine_Been_Approved__c on PO Lines when the PO is approved
    	for( SObject p: Trigger.New) {
    		
    		if (KSE.isFieldChanging('Approval_Status__c',p,Trigger.oldMap) && (p.get('Approval_Status__c') == 'Approved')){
    			poIds.add(p.id);
    		}
    	}
    	
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		if(poIds.size() > 0){
			SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','Approved__c','Status__c'
			});
			soql.setWhereClause('Purchase_Order__c IN :poIds AND Approved__c = false AND Status__c = \'Open\'');
	
			List<Purchase_Order_Line__c> poLinestoUpdate = Database.query(soql.getQuery());
	
			if (poLinestoUpdate.size()!=0){
				for (Purchase_Order_Line__c poLine : poLinestoUpdate){
					poLine.Approved__c = True;
				}
				DML.updateAsUser(poLinestoUpdate);
			}
		}
	}

	//KNDY-15740
	public static void updateDefaultPOAmountTolerance(){
        
        Decimal defaultAmountToleranceValue = 0.00;
        Map<String,Configuration__c> mapConfExistingData = Configuration__c.getAll();
        
        if(!mapConfExistingData.isEmpty() && mapConfExistingData.containsKey('Default_PO_Amount_Tolerance') ){
		    System.debug(logginglevel.error,mapConfExistingData.get('Default_PO_Amount_Tolerance').value__c);
		    if(mapConfExistingData.get('Default_PO_Amount_Tolerance').value__c != null)
		       defaultAmountToleranceValue = Decimal.valueOf(mapConfExistingData.get('Default_PO_Amount_Tolerance').value__c);
        }
        
        System.debug(logginglevel.error,'Trigger Size-->'+Trigger.New.Size());
        if(defaultAmountToleranceValue != null && defaultAmountToleranceValue > 0.00){
        	for( Purchase_Order__c po: (list<Purchase_Order__c>)Trigger.New){
              if( po.Amount_Tolerance__c != null && po.Amount_Tolerance__c > 0){
                 // do nothing
                 System.debug(logginglevel.error,'do nothing');
              }else{
                 po.Amount_Tolerance__c =  defaultAmountToleranceValue;  
                 System.debug(logginglevel.error,'po.Amount_Tolerance__c-->'+po.Amount_Tolerance__c);
              }
           }    
        }
    }

    // KNDY-9959
    public static JsonResult closePOLines(List<Purchase_Order_Line__c> poLines,boolean headerCall){
        JsonResult result = new JsonResult();
        List<id> twoWayPOLineids = new List<id>();
        Map<Id, Purchase_Order_Line__c> poLinesToCloseMap = new Map<Id,Purchase_Order_Line__c>();
        List<Purchase_Order_Line__c> errorLines = new List<Purchase_Order_Line__c>();
        set<id> wOToCloseId = new set<id>();
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Line__c','Status__c','Order_Quantity__c','Invoice_Matching__c','Quantity_Received__c','Work_Order__c','Work_Order__r.status__c','Purchase_Order__r.Open_Purchase_Order_Lines__c'
		});
		soql.setWhereClause('Id in :poLines');
		
		for (List<Purchase_Order_Line__c> POLs : Database.query(soql.getQuery())){
            for (Purchase_Order_Line__c pol: POLs){
                poLinesToCloseMap.put(pol.Id, pol);
                //PTP-634 collect all the lines that are 2 way and short closed to check for incomplete/draft invoices
	            if (pol.Invoice_Matching__c == 'Two Way'){
	                twoWayPOLineids.add(pol.id);
	            }
            }
        }

        Set<id> poLineIdswithOpenInvoices = new Set<id> ();
        if (twoWayPOLineids.size() > 0){
            poLineIdswithOpenInvoices = PurchaseOrderService.CheckForInvoicesOnLineClose(twoWayPOLineids);
        }
        
        if (poLineIdswithOpenInvoices.size() == 0){
           for ( Purchase_Order_Line__c pol : poLinesToCloseMap.values()) {
               pol.Status__c = 'Closed';
           }
           DML.updateAsUser(poLinesToCloseMap.values());
            
           result.success = true;
           result.addMessage(Label.Lines_closed_successfully, ApexPages.Severity.CONFIRM); 
        }
        else{
            List<Decimal> lineNumbers = new List<Decimal>();
            for (Id polId : poLineIdswithOpenInvoices){
                errorLines.add(poLinesToCloseMap.get(polId));
                lineNumbers.add(poLinesToCloseMap.get(polId).Line__c);
            }
            lineNumbers.sort();
            String lineNumbersStr = String.join(lineNumbers, ',');
            lineNumbersStr = lineNumbersStr.removeEnd(',');
            result.addMessage(Label.Cannot_close_purchase_order_lines + '- Lines ' + lineNumbersStr , ApexPages.Severity.ERROR);
            result.success = false;
            result.records = errorLines;
        } 
        return result;
    }
    
	//PTP-634 Check if any of the poline has an incomplete/draft invoice
	public static Set<id> CheckForInvoicesOnLineClose(List<id> poLineids) {
		
		List<Supplier_Invoice_Line__c> silList = new List<Supplier_Invoice_Line__c>();
		Set<id> poLinewithIncompleteInvoices = new Set<id>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Supplier_Invoice_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','Supplier_Invoice__c','Purchase_Order_Line__c'
		});
		soql.setWhereClause('Purchase_Order_Line__c IN :poLineids and Supplier_Invoice__r.Status__c in (\'Incomplete\',\'Draft\')');

		silList = Database.query(soql.getQuery());

		for (Supplier_Invoice_Line__c sil : silList){
			poLinewithIncompleteInvoices.add(sil.Purchase_Order_Line__c);
		}

		return poLinewithIncompleteInvoices;
	}

	public static Set<id> CheckForInvoicesOnHeaderClose (id poid) {

		List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>();
		List<id> poLineids = new List<id>();
		Set<id> poLinewithIncompleteInvoices = new Set<id>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','Purchase_Order__c'
		});
		soql.setWhereClause('Purchase_Order__c = :poid and Invoice_Matching__c = \'Two Way\'');

		polList = Database.query(soql.getQuery());

		for (Purchase_Order_Line__c pol : polList){
			poLineids.add(pol.id);
		}
		
		if (poLineids.size() > 0){
			poLinewithIncompleteInvoices = PurchaseOrderService.CheckForInvoicesOnLineClose(poLineids);
		}
		
		return poLinewithIncompleteInvoices;

	}

    public static List<Purchase_Order_Line__c> getASNlinesToPOLs(List<Purchase_Order_Line__c>pols){
		
		
		List<Purchase_Order_Line__c> poLines = new List<Purchase_Order_Line__c>();
		List<String> statusList = new List<String>();
        statusList.add(ASNService.ASN_LINE_STATUS_CANCELLED);
        statusList.add(ASNService.ASN_LINE_STATUS_CLOSED);

		SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c');
        soql.addFields(new set<string>{
			'Id','Line__c','Status__c', 
			'Order_Quantity__c','Invoice_Matching__c','Quantity_Received__c','Work_order__c','Quantity_Matched__c'      
        });
        soql.setWhereClause('Id in :pols');        
        SOQLUtil.ChildRelationship asnlSubquery = new SOQLUtil.ChildRelationship(soql,'ASN_Lines__r');
        asnlSubquery.addFields(new set<string>{
			'Id','Purchase_Order_Line__c','Quantity_Received__c','Status__c','ASN__c'     
        });
        asnlSubquery.setWhereClause('Status__c not in :statusList');
        soql.addChildRelationship(asnlSubquery);

        poLines = Database.query(soql.getQuery());
        
        return poLines;

	}

    // KNDY-9959
    public static JSONResult cancelPOLines(List<Purchase_Order_Line__c> poLines,boolean headerCall){
        List<Purchase_Order_Line__c> poLinesToCancel = new List<Purchase_Order_Line__c>();
        set<id> asnId = new set<id>();
        JsonResult result = new JsonResult(); 

         poLinesToCancel = getASNlinesToPOLs(poLines);

        for(Purchase_Order_Line__c pol :poLinesToCancel){
            for (ASN_Line__c asnLine :pol.ASN_Lines__r) {
              asnId.add(asnLine.asn__c) ; 
            }  
        }
       
        
        List<ASNAddManageExt.ASNLineWrapper> asnlinewrapperlist = new List<ASNAddManageExt.ASNLineWrapper>();
		Map<Id,ASNAddManageExt.ASNLineWrapper> asnlMap = new Map<Id,ASNAddManageExt.ASNLineWrapper>();
        for (ASNAddManageExt.ASNLineWrapper asnlWrapper:ASNService.getASNLineWrappers(asnId,'')) {
            asnlMap.put(asnlWrapper.asnl.Id,asnlWrapper);
        }
              
        for(Purchase_Order_Line__c pol :poLinesToCancel){
            for (ASN_Line__c asnLine :pol.ASN_Lines__r) {
                asnlinewrapperlist.add(asnlMap.get(asnLine.Id));
        	}
        }
        JsonResult asnlResult = ASNService.CancelCloseASNLines(asnlinewrapperlist,ASNService.ASN_STATUS_CANCELLED,true);
        List<Purchase_Order_Line__c> errorPOLs = PurchaseOrderService.validatePOLineCancel(poLinesToCancel);
            
        if (errorPOLs.size() == 0){
           for ( Purchase_Order_Line__c pol : poLinesToCancel) {
               pol.Status__c = 'Cancelled';
               for( ASNAddManageExt.ASNLineWrapper asnWrap :asnlinewrapperlist){
                      if(asnWrap.asnl.Purchase_Order_Line__c == pol.id){
                          asnWrap.asnl.Purchase_Order_Line__r.Status__c = pol.Status__c;
                      }
                }
               system.debug(Logginglevel.info, 'PO Lines Add Manage cancel line, PO Line status set to cancelled. No DB update done. POL: ' + pol);
           }
           DML.updateAsUser(poLinesToCancel);
           //cancelling ASN when POL is cancelled 
           
            
            if(asnlResult.messages.size()> 0){
                throw new purchaseOrderServiceException(''+asnlResult.messages);
            }
            
           result.success = true;
           if(poLinesToCancel.size()>0) {
               PurchaseOrderService.setReqlineValuesonPOLCancel(poLinesToCancel); //KDY-9504
     	   }  
           result.addMessage(Label.Lines_cancelled_successfully, ApexPages.Severity.CONFIRM); 
        }
        else{ 
            List<Decimal> lineNumbers = new List<Decimal>();
            for (Purchase_Order_Line__c line : errorPOLs){
               lineNumbers.add(line.Line__c);
            }
            lineNumbers.sort();
            String lineNumbersStr = String.join(lineNumbers, ',');
            lineNumbersStr = lineNumbersStr.removeEnd(',');
            result.addMessage(Label.Cannot_cancel_PurchaseOrderLines_which_has_been_received_or_invoiced + '- Lines ' + lineNumbersStr , ApexPages.Severity.ERROR);
            result.success = false;
            result.records = errorPOLs;
        }
        return result;
    }
    
    
    // PTP-402 Two Way POLines with receipts can be cancelled provided there are no supplier invoices
    // Three Way POLines with receipts or supplier invoices cannot be cancelled
    public static List<Purchase_Order_Line__c> validatePOLineCancel(List<Purchase_Order_Line__c> pols){
        List<Purchase_Order_Line__c> errorPOLs = new List<Purchase_Order_Line__c>();
        for (Purchase_Order_Line__c POL : pols) {
            // Check for Supplier Invoices
            // Check for receipts for Three Way POLines
            if (POL.Quantity_Matched__c != 0 || POL.Quantity_Received__c != 0 ) { 
                errorPOLs.add(POL);
            }
         }
         return errorPOLs;    	
    }

	public static void updatesupplieronPOLines(Map<Id,Purchase_Order__c>potriggerMap) {
		set<Id>poIds = new set<Id>();
		integer i;
		for(sObject p : Trigger.new){
			if (KSE.isFieldChanging('Supplier__c',p,Trigger.oldMap) || KSE.isFieldChanging('Type__c',p,Trigger.oldMap) ||KSE.isFieldChanging('FOB_Term__c',p,Trigger.oldMap)) {
				poIds.add(p.id);
			}
		}
		if(poIds.size()!=0){
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Purchase_Order__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Name','Status__c','Company__c','Supplier__c','Supplier__r.Name','Type__c','FOB_Term__c'
			});
			soql.setWhereClause('id IN :poIds and Approval_Status__c != \'Approved\'');
			
			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Purchase_Order_Lines__r');
			childRel.addFields(new set<string>{
				'Id','Name','Company__c','Status__c','Supplier__c','Supplier__r.Name','Purchase_Order__c','Purchase_Order__r.Supplier__c',
				'Approved__c'
			});
			soql.addChildRelationship(childRel);
	
			List<Purchase_Order__c> purchaseOrderList = Database.query(soql.getQuery());

        	    if(purchaseOrderList.size()>0){
        	    
        	    		for (Purchase_Order__c p : purchaseOrderList){
        	    			for(Purchase_Order_Line__c pol : p.Purchase_Order_Lines__r) {
        	    			if(KSE.isFieldChanging('Supplier__c',p,Trigger.oldMap)){
        	    					if(pol.Approved__c == false) {
        	    						pol.Supplier__c = pol.Purchase_Order__r.Supplier__c;			
        	    					}
        	    					else {
        	    						potriggerMap.get(pol.Purchase_Order__c).addError(Label.Cannot_change_Supplier_for_Approved_Purchase_Orders);	
        	    					}
        	    			}
        	    				if(KSE.isFieldChanging('Type__c',p,Trigger.oldMap)){  			//Added as part of PTM-137
        	    					if(pol.Approved__c == true){	
        	    						potriggerMap.get(pol.Purchase_Order__c).addError(Label.Cannot_change_Type_for_Approved_Purchase_Orders);	
        	    					}	
        	    				}
        	    				if(KSE.isFieldChanging('FOB_Term__c',p,Trigger.oldMap)){		//Added as part of PTP-364
        	    					if(pol.Approved__c == true){	
        	    						potriggerMap.get(pol.Purchase_Order__c).addError(Label.Cannot_change_FOB_Term_for_Approved_Purchase_Orders);	
        	    					}	
        	    				}
        	    			DML.updateAsUser(pol);	
        	    			
        	    			}
        	    	   }
        	    }
		 }
	}

    // KNDY-9974
    public static JsonResult headerActions (Id poId, String status){
        JsonResult result = new JsonResult();
        if (String.isEmpty(poId)){
            result.success = false;
            result.addMessage(Label.Cannot_perform_any_action_save_the_purchase_order_to_proceed, ApexPages.Severity.ERROR);
        }
        else{
            if (status == 'Closed' || status == 'Cancelled'){
                result = closeCancelPO(poId, status);
            }
            else if (status == 'Delete'){
                result = deletePO(poId);
            }
            else if (status == 'Approved'){
                result = approvePO(poId);
            }
        }
        return result;
    }

    private static JSONResult approvePO(Id poId){
        JSONResult result = new JSONResult();
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Purchase_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Status__c','Approval_Status__c'
		});
		soql.setWhereClause('Id = : poId');

		Purchase_Order__c po = Database.query(soql.getQuery());

        if (po.Approval_Status__c  == 'Pending Authorization'){
            po.Approval_Status__c = 'Approved';
            DML.updateAsUser(new List<Purchase_Order__c>{po});
            result.success = true;
            result.records = new List<Purchase_Order__c>{po};
        }
        else{
            result.success = false;
            if (po.Approval_Status__c == 'Approved'){
                result.addMessage(Label.Purchase_Order_is_already_approved , ApexPages.Severity.ERROR);
            }
            else{
                result.addMessage(Label.Cannot_approve_the_purchase_order, ApexPages.Severity.ERROR);
            }
        }
        return result;
    }
           
    private static JSONResult closeCancelPO(Id poId, String newStatus){
        JSONResult result = new JSONResult();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Purchase_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Status__c','Approval_Status__c'
		});
		soql.setWhereClause('Id = : poId');

		Purchase_Order__c po = Database.query(soql.getQuery());

        List<Purchase_Order_Line__c> openPOLs = new List<Purchase_Order_Line__c>();
        Boolean savePO = false;
        if (po.Status__c == 'Open' ){
            po.Status__c = newStatus;
            
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Name','Line__c','Status__c','Approved__c','Quantity_Still_Due__c','Invoice_Matching__c','Order_Quantity__c',
				'Quantity_Received__c'
			});
			soql.setWhereClause('Status__c = \'Open\' and Purchase_Order__c = :poId');
			
			for (List<Purchase_Order_Line__c> pols : Database.query(soql.getQuery())){
                openPOLs.addAll(pols);
            }
            
            if (openPOLs.size() > 0){
                if (newStatus == 'Closed'){
                    result = closePOLines(openPOLs,true);
                }
                else if (newStatus == 'Cancelled'){
                    result = cancelPOLines(openPOLs,true);
                }
                if (result.success){
                    savePO = true;
                }
            }
            else{
                savePO = true;
            }
            
            // Don`t save the PO, as cancelling all lines will auto-cancel the PO as well.
            if(savePO == true && newStatus == 'Cancelled' && openPOLs.size() > 0){

				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Purchase_Order__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id','Name','Status__c','Approval_Status__c'
				});
				soql.setWhereClause('Id = : poId');

				po = Database.query(soql.getQuery());

                result.records = new List<Purchase_Order__c>{po};
                result.success = true;
            }
            else if (savePO  == true){
                DML.updateAsUser(new List<Purchase_Order__c>{po});
                result.records = new List<Purchase_Order__c>{po};
                result.success = true;
            }
        }
        else{
            result.success = false;
            result.addMessage(Label.Cannot_close_or_cancel_Purchase_Order_that_is_not_open, ApexPages.Severity.ERROR);
        }
        return result;
    }

    private static JSONResult deletePO(Id poId){
        JSONResult result = new JSONResult();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Purchase_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Status__c'
		});
		soql.setWhereClause('Id = : poId');

		Purchase_Order__c po = Database.query(soql.getQuery());

        Boolean savePO = false;

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Approved__c'
		});
		soql.setWhereClause('Approved__c = true and Purchase_Order__c = :poId');
		soql.setLimit(1);

		List<Purchase_Order_Line__c> approvedPOLs = Database.query(soql.getQuery());

        if(approvedPOLs.size() != 0){
            result.success = false;
            result.addMessage(Label.Cannot_delete_purchase_order, ApexPages.Severity.ERROR);
        }
        else{
            DML.deleteAsUser(new List<Purchase_Order__c>{po});
            result.success = true;
        }
        return result;
    }

     //KNDY-9504 
    public static void setReqlineValuesonPOLCancel(List<Purchase_Order_Line__c> poLinesToCancel){
    	Map<id,Requisition_Line__c>reqLinesToUpdate = new Map<id,Requisition_Line__c>();
    	Set<Id>polIdset = new Set<Id>();
    	Map<id,Requisition_Line__c>poLineIdReqLineMap = new Map<id,Requisition_Line__c>();
    	for(Purchase_Order_Line__c pol : poLinesToCancel){
    		polIdset.add(pol.id);
    	}

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Requisition_Cross_Reference__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Purchase_Order_Line__r.Name','Requisition_Line__r.name','Requisition_Line__r.Quantity_Ordered__c','Requisition_Line__r.Quantity_Released__c',
			'Purchase_Order_Line__c'
		});
		soql.setWhereClause('Purchase_Order_line__c IN :polIdset');

		List<Requisition_Cross_Reference__c> reqCrossRefList = Database.query(soql.getQuery());

    		if(reqCrossRefList.size()>0){
    			for(Requisition_Cross_Reference__c reqCrossRef : reqCrossRefList){
    				poLineIdReqLineMap.put(reqCrossRef.Purchase_Order_Line__c, reqCrossRef.Requisition_Line__r);
    			} 
    			for(Purchase_Order_Line__c pol: poLinesToCancel){   
    				if(poLineIdReqLineMap.containsKey(pol.id)){
    					poLineIdReqLineMap.get(pol.id).Quantity_Released__c = poLineIdReqLineMap.get(pol.id).Quantity_Ordered__c - poLineIdReqLineMap.get(pol.id).Quantity_Released__c;
    					poLineIdReqLineMap.get(pol.id).Status__c = 'Open';
    					reqLinesToUpdate.put(poLineIdReqLineMap.get(pol.id).id, poLineIdReqLineMap.get(pol.id));	
    				}
    			}  
    		if( reqLinesToUpdate.values().size() > 0 )
	    		DML.updateAsUser(reqLinesToUpdate.values());	
    		}
    }
    
    public static map<Id,List<Purchase_Order_Line__c>> queryPOLinesWithASN(Set<Id> objIds,String objectName){
    	
    	
    	List<Purchase_Order_Line__c> poLines = new List<Purchase_Order_Line__c>();
		String whereClause;
		if(objectName == 'Purchase_order__c') {
			whereClause = 'Purchase_Order__c in :objIds';
		}
		else if(objectName == 'FOB_Terms__c'){
			whereClause = 'Purchase_Order__r.FOB_Term__c in :objIds';
		}
	
		SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c');
        soql.addFields(new set<string>{
			'Id','Line__c','Status__c', 'Purchase_Order__r.FOB_Term__c','Quantity_Received__c','Work_order__c','Quantity_Matched__c'      
        });
        soql.setWhereClause(whereClause);        
        SOQLUtil.ChildRelationship asnlSubquery = new SOQLUtil.ChildRelationship(soql,'ASN_Lines__r');
        asnlSubquery.addFields(new set<string>{
			'Id','Purchase_Order_Line__c','Quantity_Received__c','Status__c','ASN__c'     
        });
        asnlSubquery.setWhereClause('Status__c != \'Cancelled\'');
        soql.addChildRelationship(asnlSubquery);

        poLines = Database.query(soql.getQuery());
        Map<Id,List<Purchase_Order_Line__c>> powithFOBMap = new Map<Id,List<Purchase_Order_Line__c>>();
        for(Purchase_Order_Line__c pol :poLines){
        	
        	if(!powithFOBMap.containskey(pol.Purchase_Order__c)){
        		
        		if (pol.ASN_Lines__r.size()>0 || pol.Quantity_Received__c>0) {
        			String key;
        			if(objectName == 'Purchase_order__c') {
        				key =pol.Purchase_Order__c; 
        			}
        			else if(objectName == 'FOB_Terms__c'){
        				key =pol.Purchase_Order__r.FOB_Term__c; 
        			}
        			powithFOBMap.put(key,new List<Purchase_Order_Line__c>());
	              	powithFOBMap.get(key).add(pol);
	              	
	            }
        	}
              
        }
        
        return powithFOBMap;
    }				

}