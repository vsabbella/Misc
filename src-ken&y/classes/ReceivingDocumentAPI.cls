global with sharing class ReceivingDocumentAPI {
    global static ReceivingDocumentAPIStatus release(Set<Id> rdIds) {
        try {
            ReceivingDocumentService.release(rdIds);
        } catch(Exception e) { 
            return createErrorResult(e.getMessage());
        }
        return createSuccessResult();
    }
    global static Map<Id,ReceivingDocumentAPIStatus> close(Map<Id,ReceivingDocumentWrapper> receivingDocumentWrappers) {
        if (receivingDocumentWrappers == null || receivingDocumentWrappers.size() == 0)
            return null;
        receivingDocumentWrappers = receivingDocumentWrappers.clone();

        Map<Id,ReceivingDocumentAPIStatus> result = new Map<Id,ReceivingDocumentAPIStatus>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Set<Id> rdIds = receivingDocumentWrappers.keySet();
		
		SOQLUtil soql = new SOQLUtil('Receiving_Document__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		soql.setWhereClause('Id IN :rdIds');

		Map<Id,Receiving_Document__c> receivingDocuments = new Map<Id,Receiving_Document__c>((List<Receiving_Document__c>)Database.query(soql.getQuery()));

        for (Id receivingDocumentId:receivingDocumentWrappers.keySet()) {
            ReceivingDocumentWrapper receivingDocumentWrapper = receivingDocumentWrappers.get(receivingDocumentId);
            if (!receivingDocuments.containsKey(receivingDocumentId)) {
                result.put(receivingDocumentId,createErrorResult('Invalid receiving document Id'));
                receivingDocumentWrappers.remove(receivingDocumentId);
                continue;
            }
        }
        ReceivingDocumentService.close(receivingDocumentWrappers.keySet(),'Receipt_Line__c','Receiving_Document__c','Receiving_Document__c',new List<String>{ SkidService2.SKID_TYPE_INTRANSIT },false,false,'Closed');
        for (Id receivingDocumentId:receivingDocumentWrappers.keySet())
            result.put(receivingDocumentId,createSuccessResult());
        return result;
    }
    global static Map<Id,ReceivingDocumentAPIStatus> receive(Map<Id,ReceivingDocumentWrapper> receivingDocumentWrappers) {
        if (receivingDocumentWrappers == null || receivingDocumentWrappers.size() == 0)
            return null;
        receivingDocumentWrappers = receivingDocumentWrappers.clone();
        
        Map<Id,ReceivingDocumentAPIStatus> result = new Map<Id,ReceivingDocumentAPIStatus>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Set<Id> rdIds = receivingDocumentWrappers.keySet();
		
		SOQLUtil soql = new SOQLUtil('Receiving_Document__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Status__c','Transaction_Date__c'
		});
		soql.setWhereClause('Id IN :rdIds');
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Receipt_Lines__r');
		childRel.addFields(new set<string>{
			'Id','Purchase_Order_Line__c','Purchase_Order__r.Supplier__c'
		});
		soql.addChildRelationship(childRel);
		
		Map<Id,Receiving_Document__c> receivingDocuments = new Map<Id,Receiving_Document__c>((List<Receiving_Document__c>)Database.query(soql.getQuery()));

        Set<Id> supplierIds = new Set<Id>(); 
        for (Id receivingDocumentId:receivingDocumentWrappers.keySet()) {
            ReceivingDocumentWrapper receivingDocumentWrapper = receivingDocumentWrappers.get(receivingDocumentId);
            if (!receivingDocuments.containsKey(receivingDocumentId)) {
                result.put(receivingDocumentId,createErrorResult('Invalid receiving document Id'));
                receivingDocumentWrappers.remove(receivingDocumentId);
                continue;
            }
            Receiving_Document__c receivingDocument = receivingDocuments.get(receivingDocumentId);
            if (receivingDocument.Status__c != ReceivingDocumentService.RD_STATUS_OPEN) {
                result.put(receivingDocumentId,createErrorResult('Receiving document is not open'));
                receivingDocumentWrappers.remove(receivingDocumentId);
                receivingDocuments.remove(receivingDocumentId);
            } else {
                for (Receipt_Line__c receiptLine:receivingDocument.Receipt_Lines__r)
                    supplierIds.add(receiptLine.Purchase_Order__r.Supplier__c);
            }
        }
        if (receivingDocumentWrappers.size() == 0)
            return result;

		ReceivingDocumentService.flush();
        Map<Id,Receipt_Line__c> receiptLines = (Map<Id,Receipt_Line__c>)ReceivingDocumentService.cachedReceiptLines(receivingDocumentWrappers.keySet(),'Status__c = \'Open\' AND Purchase_Order_Line__r.Quantity_Still_Due__c > 0 AND Purchase_Order__r.Approval_Status__c = \'Approved\' AND Purchase_Order__r.Status__c = \'Open\' AND Purchase_Order_Line__r.Status__c = \'Open\'');
        if (receiptLines.values().size() == 0) {
            for (Id receivingDocumentId:receivingDocumentWrappers.keySet())
                result.put(receivingDocumentId,createErrorResult('No lines are available for receiving'));
            return result;
        }

        Map<Id,Id> receiptLineToPoLine = new Map<Id,Id>();
        Set<Id> poLineIds = new Set<Id>();
        List<Purchase_Order_Line__c> purchaseOrderLines = new List<Purchase_Order_Line__c>();
        for (Receipt_Line__c receiptLine:receiptLines.values()) {
            receiptLineToPoLine.put(receiptLine.Id,receiptLine.Purchase_Order_Line__c);
            poLineIds.add(receiptLine.Purchase_Order_Line__c);
            purchaseOrderLines.add(receiptLine.Purchase_Order_Line__r);
        }
        Map<Id,List<Location__c>> locationsByHeader = SkidService2.locationsFromStockMovementRules(purchaseOrderLines,'Putaway','Purchase Order',new Map<Id,Stock_Movement_Rule__c>());
        Map<String,Integer> icrKeys = ReceivingDocumentService.populateIcrMinimumShelfLife(supplierIds);
        Map<Id,Skid__c> fromSkids = (Map<Id,SKID__c>)ReceivingDocumentService.cachedFromSkids(poLineIds);
        List<String> attributeFields = new List<String>(SchemaUtil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c'));
        Map<Id,ReceivingDocumentService.receivingWrapper> records = new Map<Id,ReceivingDocumentService.receivingWrapper>();
        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        Set<Id> uniqueLocations = new Set<Id>();
        for (Integer i=0;i<receiptLines.values().size();i++) {
            Receipt_Line__c receiptLine = receiptLines.values()[i];
            Id polId = receiptLineToPoLine.get(receiptLine.Id);
            
            Location__c loc;
            
            if( locationsByHeader.containsKey(polId) && locationsByHeader.get(polId).size() > 0 )
                loc = locationsByHeader.get(polId)[0];
            
            ReceivingDocumentService.receivingWrapper rw = new ReceivingDocumentService.receivingWrapper(receiptLine,i,fromSkids.get(polId),loc,attributeFields,'Receiving Document');
            ReceivingDocumentService.calculateMinimumShelfLife(rw,'Receiving Document',icrKeys,receiptLine.Purchase_Order__r.Supplier__c);
            if (rw.rl.get('Quantity_Received__c') == null)
                rw.rl.put('Quantity_Received__c',0);
            if (rw.skidList != null && rw.skidList.size() > 0)
                rw.skidList[0].Quantity__c = 0;
            records.put(receiptLine.Id,rw);
            itemIds.add(rw.receipt.Item__c);
            facilityIds.add(rw.receipt.Facility__c);
            uniqueLocations.add((Id)rw.rl.get('Putaway_Location__c'));
        }

        Map<Id,SKID__c> transitSkids = new Map<Id,SKID__c>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Set<Id> recordIds = records.keySet();
		
		soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Quantity__c','Type__c','Receipt_Line__c'
		});
		soql.setWhereClause('Type__c = \'In-Transit\' AND Receipt_Line__c IN :recordIds');
		
		for (SKID__c transitSkid:Database.query(soql.getQuery())){
            transitSkids.put(transitSkid.Receipt_Line__c,transitSkid);
        }

		Decimal conversionFactor;
        Map<String,Lot__c> lotMap = new Map<String,Lot__c>();
        Set<String> lotNames = new Set<String>();
        Map<Id,Decimal> totalQuantityByPoLine = new Map<Id,Decimal>();
        Map<Id,SKID__c> skidsToDelete = new Map<Id,SKID__c>();
        Map<Id,SKID__c> skidsToUpdate = new Map<Id,SKID__c>();
        Map<Id,Purchase_Order_Line__c> poLinesToUpdate = new Map<Id,Purchase_Order_Line__c>();
        Map<Id,Receipt_Line__c> receiptLinesToUpdate = new Map<Id,Receipt_Line__c>();
        for (Id receivingDocumentId:receivingDocumentWrappers.keySet()) {
            ReceivingDocumentWrapper receivingDocumentWrapper = receivingDocumentWrappers.get(receivingDocumentId);
            Receiving_Document__c receivingDocument = receivingDocuments.get(receivingDocumentId);
            Boolean hasError = false;
            for (Id receiptLineId:receivingDocumentWrapper.lines.keySet()) {
                ReceiptLineWrapper receiptLineWrapper = receivingDocumentWrapper.lines.get(receiptLineId);
                if (!records.containsKey(receiptLineId)) {
                    result.put(receivingDocumentId,createErrorResult('One or more receipt lines are not available for receiving'));
                    hasError = true;
                    break;
                }
                ReceivingDocumentService.receivingWrapper rw = records.get(receiptLineId);
                Double stdCost = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,rw.receipt.Company__c,rw.receipt.Facility__c,System.Now(),rw.receipt.Item__c);
                if (rw.skidList == null || rw.skidList.size() == 0) {
                    result.put(receivingDocumentId,createErrorResult('One or more receipt lines is missing a receiving line'));
                    hasError = true;
                    break;
                }
                if (rw.itList == null || rw.itList.size() == 0) {
                    result.put(receivingDocumentId,createErrorResult('One or more receipt lines is missing an inventory transaction'));
                    hasError = true;
                    break;
                }
                if (receiptLineWrapper.receivingLines == null || receiptLineWrapper.receivingLines.size() == 0 || receiptLineWrapper.receivingLines.size() > 1) {
                    result.put(receivingDocumentId,createErrorResult('Each receipt line must have exactly one receiving line'));
                    hasError = true;
                    break;
                }
                if (rw.skidList[0].Location__c == null || rw.rl.get('Putaway_Location__c') == null) {
                    result.put(receivingDocumentId,createErrorResult('Stock movement rule is not set up'));
                    hasError = true;
                    break;
                }
                if (receiptLineWrapper.receivingLines[0].qtyReceived == null || receiptLineWrapper.receivingLines[0].qtyReceived <= 0) {
                    result.put(receivingDocumentId,createErrorResult('Receiving line has a quantity less than or equal to zero'));
                    hasError = true;
                    break;
                }
                rw.rl.put('Quantity_Received__c',(Decimal)rw.rl.get('Quantity_Received__c')+receiptLineWrapper.receivingLines[0].qtyReceived);
                if (rw.itList[0].Purchase_Order_Line__c != null)
                    rw.itList[0].putSObject('Purchase_Order_Line__r',rw.rl.getSObject('Purchase_Order_Line__r'));
                
                
                if(rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c')==null || (decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c')==0)
                {   
                	conversionFactor = KSE.getConversionFactor(rw.rl.getSObject('Purchase_Order_Line__r'));
                    rw.rl.getSObject('Purchase_Order_Line__r').put('Quantity_To_Stock__c', ((decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Order_Quantity__c') * conversionFactor).setscale(6,System.RoundingMode.HALF_UP));
                }
                
                
                rw.skidList[0].Quantity__c = (receiptLineWrapper.receivingLines[0].qtyReceived * KSE.getConversionFactorFromQuantity((decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c'),(decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Order_Quantity__c'))).setscale(6,System.RoundingMode.HALF_UP);
                rw.itList[0].Quantity__c = rw.skidList[0].Quantity__c;
                if (rw.skidList[0].Item__r.Item_Attribute__r.Expiration_Date__c)
                    rw.skidList[0].Expiration_Date__c = receiptLineWrapper.receivingLines[0].expirationDate;
                if (rw.skidList[0].Item__r.Item_Attribute__r.Date_Received__c)
                    rw.skidList[0].Date_Received__c = receiptLineWrapper.receivingLines[0].dateReceived;
                if (rw.skidList[0].Item__r.Item_Attribute__r.Lot_Number__c) {
                    rw.skidList[0].Lot_Number__c = receiptLineWrapper.receivingLines[0].lot;
                    SkidService2.populateLotNames(rw.skidList[0],(Id)rw.rl.get('Supplier__c'),lotMap,lotNames);
                }
                for (String attributeField:receiptLineWrapper.receivingLines[0].attributes.keySet())
                    if ((Boolean)rw.skidList[0].Item__r.Item_Attribute__r.get(attributeField))
                        rw.skidList[0].put(attributeField,receiptLineWrapper.receivingLines[0].attributes.get(attributeField));
                for (String trackedAttribute:rw.trackedAttributes) {
                    if (rw.skidList[0].get(trackedAttribute) == null) {
                        result.put(receivingDocumentId,createErrorResult('Receiving line is missing attribute ' + trackedAttribute));
                        hasError = true;
                        break;
                    }
                }
                if (rw.rl.getSObject('Purchase_Order__r').getSObject('FOB_Term__r') != null && rw.rl.getSObject('Purchase_Order__r').getSObject('FOB_Term__r').get('FOB_Point__c') == 'Origin' && transitSkids.get(rw.rl.id) == null) {
                    result.put(receivingDocumentId,createErrorResult('No in-transit SKIDs found'));
                    hasError = true;
                    break;
                }
                if (!totalQuantityByPoLine.containsKey((Id)rw.rl.get('Purchase_Order_Line__c')))
                    totalQuantityByPoLine.put((Id)rw.rl.get('Purchase_Order_Line__c'),0);
                if (totalQuantityByPoLine.get((Id)rw.rl.get('Purchase_Order_Line__c')) + rw.skidList[0].Quantity__c  > KSE.addQuantityToField((Decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_Still_Due__c'),(Decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Overage_Quantity__c'))) {
                    result.put(receivingDocumentId,createErrorResult('Cannot receive more quantity than the quantity still due + overage quantity'));
                    hasError = true;
                    break;
                }
                if (!(Boolean)rw.rl.getSObject('Purchase_Order_Line__r').get('Consigned__c'))
                    rw.rl.put('Uninvoiced_Quantity__c',(Decimal)rw.rl.get('Quantity_Received__c'));
                else
                    rw.rl.put('Line_Type__c','Consigned');
                totalQuantityByPoLine.put((Id)rw.rl.get('Purchase_Order_Line__c'),totalQuantityByPoLine.get((Id)rw.rl.get('Purchase_Order_Line__c'))+rw.skidList[0].Quantity__c); 
                rw.rl.getSObject('Purchase_Order_Line__r').put('Quantity_Received__c',KSE.addQuantityToField((Decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_Received__c'),rw.skidList[0].Quantity__c));
                rw.rl.getSObject('Purchase_Order_Line__r').put('Date_Last_Changed__c',System.today());
                poLinesToUpdate.put((Id)rw.rl.get('Purchase_Order_Line__c'),(Purchase_Order_Line__c)rw.rl.getSObject('Purchase_Order_Line__r'));
                rw.rl.put('Extended_Cost__c',(stdCost * (Decimal)rw.rl.get('Quantity_Received__c') * KSE.getConversionFactorFromQuantity((decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c'),(decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Order_Quantity__c'))).setscale(6,System.RoundingMode.HALF_UP));
                rw.rl.put('Quantity_To_Stock__c',((Decimal)rw.rl.get('Quantity_Received__c') * KSE.getConversionFactorFromQuantity((decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c'),(decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Order_Quantity__c'))).setscale(6,System.RoundingMode.HALF_UP));
                if ((Decimal)rw.rl.get('Quantity_Declared__c') <= KSE.subtractDecimals((Decimal)rw.rl.get('Quantity_Received__c'),(Decimal)rw.rl.get('Quantity_Returned_To_Supplier__c')))
                    rw.rl.put('Status__c','Closed');
                receiptLinesToUpdate.put(rw.rl.Id,(Receipt_Line__c)rw.rl);
                if (transitSkids.get(rw.rl.Id) != null) {
                    SKID__c transitSkid = transitSkids.get(rw.rl.Id);
                    transitSkid.Quantity__c -= rw.itList[0].Quantity__c;
                    if (transitSkid.Quantity__c <= 0)
                        skidsToDelete.put(rw.rl.Id,transitSkid);
                    else
                        skidsToUpdate.put(rw.rl.Id,transitSkid);  
                } 
            }   
            if (hasError) {
                for (Receipt_Line__c receiptLine:receivingDocument.Receipt_Lines__r) {
                    receiptLines.remove(receiptLine.Id);
                    records.remove(receiptLine.Id);
                    receiptLinesToUpdate.remove(receiptLine.Id);
                    skidsToDelete.remove(receiptLine.Id);
                    skidsToUpdate.remove(receiptLine.Id);
                    poLinesToUpdate.remove(receiptLine.Purchase_Order_Line__c);
                }
                receivingDocumentWrappers.remove(receivingDocumentId);
                receivingDocuments.remove(receivingDocumentId);
            }
        }
        DML.updateAsUser(receiptLinesToUpdate.values());
        DML.updateAsSystem(skidsToUpdate.values());
        DML.deleteAsSystem(skidsToDelete.values());

        Map<String,Lot__c> createdLotMap = SkidService2.createLots(lotMap,lotNames);
        List<String> attributesForService = new List<String>(SkidService2.attributesForPutaway(attributeFields));
        Map<Id,sObject> sourceDocs = new Map<Id,sObject>();        
        Map<Id,List<Inventory_Transaction__c>> itMap = new Map<Id,List<Inventory_Transaction__c>>();
        List<SKID__c> skidsForService = new List<SKID__c>();
        Map<String,Schema.SObjectField> itFields = SchemaUtil.getInstance().getFieldsMap('Inventory_Transaction__c');
        for (ReceivingDocumentService.receivingWrapper rw:records.values()) {
            if (rw.skidList == null || rw.skidList.size() == 0 || rw.skidList[0].Quantity__c == 0)
                continue;
            if (rw.skidList[0].Item__r.Item_Attribute__r.Lot_Number__c) {
                String uniqueLotString = SkidService2.lotUniqueKey(rw.skidList[0],(Id)rw.rl.get('Supplier__c'));
                rw.skidList[0].Lot__c = createdLotMap.get(uniqueLotString).Id;
            }
            for (String attribute:attributesForService) {
                if (attribute == 'Facility2__c') {
                    rw.itList[0].put('To_Facility__c',rw.skidList[0].get(attribute));
                } else if (attribute == 'Location__c') {
                    rw.itList[0].put('To_Location__c',rw.skidList[0].get(attribute));
                } else if (attribute != 'Purchase_Order_Line__c') {
                    if (itFields.get(attribute.toLowerCase()).getDescribe().getType() == Schema.DisplayType.Boolean && rw.skidList[0].get(attribute) == null) {
                        rw.itList[0].put(attribute,false);
                    } else {
                        rw.itList[0].put(attribute,rw.skidList[0].get(attribute));
                    }
                }
            }
            Id sourceDocId = (Id)rw.rl.get('Receiving_Document__c');
            sourceDocs.put(sourceDocId,new Receiving_Document__c(Company__c = (Id)rw.rl.get('Company__c')));
        	if (!itMap.containsKey(sourceDocId))
        		itMap.put(sourceDocId,new List<Inventory_Transaction__c>());
        	itMap.get(sourceDocId).add(rw.itList[0]);
            skidsForService.add(rw.skidList[0]);
        }

        Map<String,SKID__c> toSkidsMap = SkidService2.putAwayService(skidsForService,attributesForService,uniqueLocations,'Location',false);
        SkidService2.inventoryTransactionsForPutAway(sourceDocs,itMap,null,null,attributesForService,toSkidsMap,null,null);
        //Update PO lines after service calls to ensure that PO supply SKIDs that are needed for service calls aren't deleted
        DML.updateAsUser(poLinesToUpdate.values());
        List<Receiving_Document__c> receivingDocumentsToUpdate = new List<Receiving_Document__c>();
        for(Receiving_Document__c receivingDocument:receivingDocuments.values()){
            //Receiving doc could have been updated by triggers, so only update transaction date and finalized
            Receiving_Document__c tempReceivingDocument = new Receiving_Document__c(Id = receivingDocument.Id,Transaction_Date__c = receivingDocument.Transaction_Date__c);
            if (tempReceivingDocument.Transaction_Date__c == null)
                tempReceivingDocument.Transaction_Date__c = System.now();
            tempReceivingDocument.Finalized__c = true;
            receivingDocumentsToUpdate.add(tempReceivingDocument);
        }
        DML.updateAsUser(receivingDocumentsToUpdate);
        for (Id receivingDocumentId:receivingDocumentWrappers.keySet())
            result.put(receivingDocumentId,createSuccessResult());
        return result;
    }


    global class ReceivingDocumentWrapper {
        global Id ReceivingDocumentId { get; private set; }
        global Map<Id,ReceiptLineWrapper> lines { get; private set; }
        global ReceivingDocumentWrapper(Id rdId) { 
            receivingDocumentId = rdId;
            lines = new Map<Id,ReceiptLineWrapper>(); 
        }
    }
    global class ReceiptLineWrapper {
        global List<ReceivingLine> receivingLines { get; set; }
        global ReceiptLineWrapper() { receivingLines = new List<ReceivingLine>(); }
    }
    global class ReceivingLine {
        global Decimal qtyReceived { get; set; }
        global String lot { get; set; }
        global Date expirationDate { get; set; }
        global Date dateReceived { get; set; }
        global Map<String,Object> attributes { get; private set; }
        global ReceivingLine() { 
            attributes = new Map<String,Object>(); 
            qtyReceived = 0;
        }
    }
    global class ReceivingDocumentAPIException extends Exception {  }
    global class ReceivingDocumentAPIStatus {
        global Boolean success { get; set; }
        global String errorMessage { get; set; }
    }
    private static ReceivingDocumentAPIStatus createErrorResult(String errorMessage) {
        ReceivingDocumentAPIStatus status = new ReceivingDocumentAPIStatus();
        status.success = false;
        status.errorMessage = errorMessage;
        return status;
    }
    private static ReceivingDocumentAPIStatus createSuccessResult() {
        ReceivingDocumentAPIStatus status = new ReceivingDocumentAPIStatus();
        status.success = true;
        return status;
    }
}