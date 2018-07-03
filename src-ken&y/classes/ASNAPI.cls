global with sharing class ASNAPI {
    private static final Set<String> requiredASNFields = new Set<String>{ 'Company__c','FOB__c','Supplier__c','Facility__c' };
    private static final Set<String> requiredASNLineFields = new Set<String>{ 'Purchase_Order__c','Purchase_Order_Line__c','Quantity_Shipped__c' };
    private static final Set<String> requiredSKIDFields = new Set<String>{ 'Quantity__c' };
    
    global static Map<String,Status> createASN(Map<String,ASN__c> asnHeaders,Map<String,Map<ASN_Line__c,List<SKID__c>>> asnLines) {
        if (asnHeaders == null || asnHeaders.size() == 0 || asnLines == null || asnLines.size() == 0)
            return new Map<String,Status>();
        
        asnHeaders = asnHeaders.clone();
        asnLines = asnLines.clone();
        Map<String,Status> result = new Map<String,Status>();
        
        Set<Id> poLineIds = new Set<Id>();
        for (String key:asnHeaders.keySet()) {
            ASN__c asn = asnHeaders.get(key);
        
            //Validate header
            if (!asnLines.containsKey(key) || asnLines.get(key).size() == 0) {
                result.put(key,new Status(Label.No_ASN_lines_provided));
                asnHeaders.remove(key);
                continue;
            }
            for (String asnField:requiredASNFields) {
                if (String.isBlank(String.valueOf(asn.get(asnField)))) {
                    result.put(key,new Status(asnField + ' ' + Label.Required_for_ASN));
                    asnHeaders.remove(key);
                    continue;
                }
            }
            
            Set<ASN_Line__c> lines = asnLines.get(key).keySet();
        
            //Set default header values
            asn.Transaction_Type__c = 'Purchase Order ASN';
            asn.Status__c = 'Draft';
            if (asn.Currency__c == null)
        		asn.Currency__c = CompanyService.defaultTransactionCurrencyId(asn.Company__c);
            if (asn.Transaction_Date__c == null)
                asn.Transaction_Date__c = System.today();
        
            Boolean hasError = false;
            Set<Id> tempPOLineIds = new Set<Id>();
            for (ASN_Line__c line:lines) {
                List<SKID__c> skids = asnLines.get(key).get(line);
            
                //Validate lines
                if (skids == null || skids.size() == 0) {
                    result.put(key,new Status(Label.No_SKIDs_provided_for_one_or_more_ASN_lines));
                    hasError = true;
                    break;
                }
                for (String asnLineField:requiredASNLineFields) {
                    if (String.isBlank(String.valueOf(line.get(asnLineField)))) {
                        result.put(key,new Status(asnLineField + ' ' + Label.Required_for_ASN_line));
                        hasError = true;
                        break;
                    }
                }
            
                Decimal totalQty = 0;
                for (SKID__c skid:skids) {
                    //Validate SKIDs
                    for (String skidField:requiredSKIDFields) {
                        if (String.isBlank(String.valueOf(skid.get(skidField)))) {
                            result.put(key,new Status(skidField + ' ' + Label.Required_for_SKID));
                            hasError = true;
                            break;
                        }
                    }
                    if (hasError)
                        break;
                    totalQty += skid.Quantity__c;
                }
                if (hasError)
                    break;
            
                //Validate SKID quantities
                if (totalQty != line.Quantity_Shipped__c) {
                    result.put(key,new Status(Label.Total_quantity_on_SKIDs_must_match_quantity_shipped));
                    hasError = true;
                    break;
                }
                tempPOLineIds.add(line.Purchase_Order_Line__c);
            }
            if (!hasError)
                poLineIds.addAll(tempPOLineIds);
            else
                asnHeaders.remove(key);
        }
        
        //Get purchase order lines
        Set<String> poLineFields = new Set<String>{ 'Id','Name','Item__c','Item__r.Name','Item__r.Non_Inventory__c','Item__r.Source__c','Item__r.Item_Attribute__c','Item__r.Stocking_UOM__c',
            'Item__r.Packaging_UOM__c', 'Unit_Price__c','Purchase_UOM__c','Delivery_Location__c','Purchase_Order__c','Status__c','Purchase_Order__r.Approval_Status__c','Item__r.Container__c' };
        poLineFields.addAll(SchemaUtil.getInstance().getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.','Item_Attribute__c'));
        String whereClause = 'Id IN :poLineIds';

        SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', TRUE);
        soql.addFields(poLineFields);
        soql.setWhereClause(whereClause);
        Map<Id,Purchase_Order_Line__c> poLines = new Map<Id,Purchase_Order_Line__c>((List<Purchase_Order_Line__c>)Database.query(soql.getQuery()));

        List<Lot__c> lots = new List<Lot__c>();
        for (String key:asnHeaders.keySet()) {
            ASN__c asn = asnHeaders.get(key);
            Set<ASN_Line__c> lines = asnLines.get(key).keySet();

            Boolean hasError = false;
            List<Lot__c> tempLots = new List<Lot__c>();
            Integer lineNumber = 1;
            for (ASN_Line__c line:lines) {
                if (!poLines.containsKey(line.Purchase_Order_Line__c)) {
                    result.put(key,new Status(Label.Invalid_purchase_order_line_Id));
                    hasError = true;
                    break;
                } 
                
                Purchase_Order_Line__c poLine = poLines.get(line.Purchase_Order_Line__c);
                
                if (poLine.Status__c != 'Open') {
                    result.put(key,new Status(Label.Purchase_order_line_is_not_open));
                    hasError = true;
                    break;
                } else if (poLine.Purchase_Order__r.Approval_Status__c != 'Approved') {
                    result.put(key,new Status(Label.Purchase_order_is_not_approved));
                    hasError = true;
                    break;
                }
            
                List<SKID__c> skids = asnLines.get(key).get(line);
                
                asnLines.get(key).remove(line);
                
                //Set default line values
                line.Company__c = asn.Company__c;   
                line.Supplier__c = asn.Supplier__c;
                line.Facility__c = asn.Facility__c;
                line.Item__c = poLine.Item__c;
                line.Unit_Price__c = poLine.Unit_Price__c;
                line.UOM__c = poLine.Purchase_UOM__c;
                line.Location__c = poLine.Delivery_Location__c;
                line.Quantity_Received__c = 0;
                line.Status__c = 'New';
                line.Line__c = Decimal.valueOf(lineNumber);
                lineNumber++;
            
                List<String> trackedAttributes = SkidService3.trackedAttributes(null,null,poLine.Item__r);
            
                for (SKID__c skid:skids) {
                    //Validate attributes
                    if (!poLine.Item__r.Non_Inventory__c || poLine.Item__r.Source__c == 'Outside Processing') {
                        for (String attr:trackedAttributes) {
                            if (!SkidService3.attributesToExclude.contains(attr) && String.isBlank(String.valueOf(skid.get(attr)))) {
                                result.put(key,new Status(attr + ' ' + Label.Required_for_SKID + ' for item ' + poLine.Item__r.Name));
                                hasError = true;
                                break;
                            }
                        }
                    }
                
                    //Set default SKID values
                    skid.Company__c = asn.Company__c;
                    skid.Facility2__c = asn.Facility__c;
                    skid.Location__c = line.Location__c;
                    skid.Type__c = 'Draft In-Transit';
                    skid.Item__c = poLine.Item__c;
                    skid.Item__r = poLine.Item__r;
                
                    Lot__c lot = ASNService.populateLotNames(skid,asn.Supplier__c,asn.Company__c);
                    if (lot != null)
                        tempLots.add(lot);
                }
                if (hasError)
                    break;
                else
                    asnLines.get(key).put(line,skids);
            }
            if (!hasError)
                lots.addAll(tempLots);
            else
                asnHeaders.remove(key);
        }
        
        Map<List<String>,Lot__c> createdLotMap = SkidService3.createLots(lots);
    
		DML.insertAsUser(asnHeaders.values());        
    
        List<ASN_Line__c> asnLinesToInsert = new List<ASN_Line__c>();
        Map<String,Map<Decimal,List<SKID__c>>> skidMap = new Map<String,Map<Decimal,List<SKID__c>>>();
        for (String key:asnHeaders.keySet()) {
            Id asnId = asnHeaders.get(key).Id;
            skidMap.put(key,new Map<Decimal,List<SKID__c>>());
            for (ASN_Line__c line:asnLines.get(key).keySet()) {
                skidMap.get(key).put(line.Line__c,asnLines.get(key).get(line));
                
                line.ASN__c = asnId;
                asnLinesToInsert.add(line);
            }
        }

        DML.insertAsUser(asnLinesToInsert);        
        
        List<SkidService3.SerialWrapper> serialWrappers = new List<SkidService3.SerialWrapper>();
        List<SKID__c> skids = new List<SKID__c>();
        for (String key:asnHeaders.keySet()) {
            ASN__c asn = asnHeaders.get(key);
            for (ASN_Line__c line:asnLines.get(key).keySet()) {
                for (SKID__c skid:skidMap.get(key).get(line.Line__c)) {
                    skid.ASN_Line__c = line.Id;
                    if (skid.Lot_Number__c != null) {
                        List<String> uniqueString = ASNService.lotUniqueKey(skid); 
                        skid.Lot__c = createdLotMap.get(uniqueString).Id; 
                        skid.Lot_Number__c = createdLotMap.get(uniqueString).Name;
                    }
                    serialWrappers.add(new SkidService3.SerialWrapper(skid,null,null));
                }
            }
            result.put(key,new Status(asn.Id));
        }
        Map<String,Boolean> configMap = new Map<String,Boolean>{ 'createSerial' => false };
        List<String> attributes = SKIDService3.attributesForPutaway();
        attributes.add('ASN_Line__c');
        SkidService3.putAwayService(serialWrappers,attributes,configMap);
        return result;
    }
    
    global static Map<Id,Status> confirm(Set<Id> asnIds) {
        if (asnIds == null || asnIds.size() == 0)
            return new Map<Id,Status>();
        
        Map<Id,Status> result = new Map<Id,Status>();
        SOQLUtil asnQuery = new SOQLUtil('ASN__c', TRUE);
        asnQuery.addFields(new Set<String>{'Id', 'Name', 'Status__c', 'Company__r.Comp_Currency__c','Company__c', 'Facility__c', 'Supplier__c', 'FOB__c', 'FOB__r.FOB_Point__c', 'Currency__c','Currency__r.ISO_Code__c', 'Packing_Slip_Number__c',
                                            'Number_of_Boxes__c', 'Tracking_Number__c', 'Carrier__c', 'Date_Shipped__c', 'Transaction_Date__c' });
        asnQuery.setWhereClause('Id IN :asnIds');
        SOQLUtil.ChildRelationship asnLinesSubQuery = new SOQLUtil.ChildRelationship(asnQuery, 'ASN_Lines__r');
        asnLinesSubQuery.addFields(new Set<String>{'Id', 'Name', 'Purchase_Order__c', 'Company__c','Facility__c','Supplier__c', 'Purchase_Order_Line__c', 'Purchase_Order_Line__r.Quantity_Shipped__c','Purchase_Order__r.Type__c', 'Location__c', 'Quantity_Shipped__c', 'Quantity_Received__c', 'Status__c', 'Is_Changed__c', 'Item__c',
                                                    'Unit_Price__c', 'ASN__r.Company__c', 'ASN__r.Facility__c', 'ASN__r.Supplier__c', 'Item__r.Packaging_UOM__c' });
        asnLinesSubQuery.setWhereClause('Status__c != \'Cancelled\' and Status__c != \'Closed\'');
        asnQuery.addChildRelationship(asnLinesSubQuery);
        Map<Id,ASN__c> asns = new Map<Id,ASN__c>((List<ASN__c>) Database.query(asnQuery.getQuery()));
        
        List<ASN_Line__c> asnLinesToUpdate = new List<ASN_Line__c>();
        List<Purchase_Order_Line__c> polinestoUpdate = new List<Purchase_Order_Line__c>();
        Set<Id> dropShipLineIds = new Set<Id>();
        Map<Id,Receiving_Document__c> rdMap = new map<Id,Receiving_Document__c>();
        Map<Id,Receiving_Document__c> rdsToInsert = new Map<Id,Receiving_Document__c>();
        Map<Id,List<Receipt_Line__c>> rlsToInsert = new Map<Id,List<Receipt_Line__c>>(); 
        List<ASN_Line__c> changedASNLines = new List<ASN_Line__c>();
        Set<Id>asnLineIds = new Set<Id>();
        ASN__c asn;
        for (Id asnId:asnIds) {
            if (!asns.containsKey(asnId)) {
                result.put(asnId,new Status(Label.Invalid_ASN_Id));
                continue;
            }
            asn = asns.get(asnId);
            if (asn.Status__c == ASNService.ASN_STATUS_CONFIRMED) {
                result.put(asnId,new Status(Label.Only_Unconfirmed_ASNs_can_be_confirmed));
                asns.remove(asnId);
                continue;
            }
            
            asn.Status__c = ASNService.ASN_STATUS_CONFIRMED;
            
            if (asn.ASN_Lines__r != null && asn.ASN_Lines__r.size() > 0) {
                for (ASN_Line__c asnLine:asn.ASN_Lines__r) {
                	if (asnLine.Is_Changed__c) {
                		if (asnLine.Status__c == ASNService.ASN_LINE_STATUS_NEW)
                        	asnLine.Status__c = ASNService.ASN_LINE_STATUS_OPEN;
                        asnLine.Is_Changed__c = false;
                        asnLine.Purchase_Order_Line__r.Quantity_Shipped__c = KSE.addQuantityToField(asnLine.Purchase_Order_Line__r.Quantity_Shipped__c,asnLine.Quantity_Shipped__c);
                        polinestoUpdate.add(asnLine.Purchase_Order_Line__r);
                        asnLinesToUpdate.add(asnLine);
                        asnLineIds.add(asnLine.Id);
                        if (asnLine.Purchase_Order__r.Type__c != 'Drop Ship')
                            changedASNLines.add(asnLine);
                	}
                	if (asnLine.Purchase_Order__r.Type__c == 'Drop Ship') {
                		dropShipLineIds.add(asnLine.Id);

                        if (asn.Transaction_Date__c == null && asn.Date_Shipped__c == null) {
                            asn.Transaction_Date__c = System.now();
                            asn.Date_Shipped__c = System.now();
                        } else if (asn.Transaction_Date__c != null && asn.Date_Shipped__c == null) {
                            asn.Date_Shipped__c = asn.Transaction_Date__c;
                        } else {
                            asn.Transaction_Date__c = asn.Date_Shipped__c;
                        }
                        
                		if (!rdMap.containsKey(asnLine.Purchase_Order__c))
                			rdMap.put(asnLine.Purchase_Order__c,new Receiving_Document__c(
                				Company__c = asn.Company__c,
                				Company__r = asn.Company__r,
            					Supplier__c = asn.Supplier__c,
            					Date_Created__c = System.today(),
                                Date_Received__c = asn.Date_Shipped__c,
                                Transaction_Date__c = asn.Date_Shipped__c,
            					Type__c = 'Purchase Order Receipt',            					
            					Transaction_Type__c = ReceivingDocumentService.RD_TRANSACTION_TYPE_LOGICAL,
            					Currency__c = asn.Currency__c,
            					Finalized__c = false,
            					Status__c = 'Closed',
            					Packing_Slip_Number__c = asn.Packing_Slip_Number__c,
            					Number_of_Boxes__c = asn.Number_of_Boxes__c,
            					Tracking_Number__c = asn.Tracking_Number__c,
            					Carrier__c = asn.Carrier__c
                    		));
                	}
                }
            }
            if (changedASNLines.size() > 0 && asn.FOB__r.FOB_Point__c == ASNService.ASN_FOB_ORIGIN) {
                //rdsToInsert.put(asnId,ASNService.createRD(asn));
                //rlsToInsert.put(asnId,ASNService.createRLs(changedASNLines));
            }
            result.put(asnId,new Status(asnId));
        }
        
        DML.updateAsUser(asns.values());
        DML.updateAsUser(asnLinesToUpdate);
        DML.updateAsUser(poLinesToUpdate);
        
        ASNService.createICandITsforASN(changedASNLines,asnLineIds,asn);//IC IT creation on confirm ASN
        
        if (rdsToInsert.size() > 0) {
            DML.insertAsUser(rdsToInsert.values());
            List<Receipt_Line__c> receiptLines = new List<Receipt_Line__c>();
            for (Id asnId:rdsToInsert.keySet()) {
                Receiving_Document__c rd = rdsToInsert.get(asnId);
                for (Receipt_Line__c rl:rlsToInsert.get(asnId)) {
                    rl.Receiving_Document__c = rd.Id;
                    receiptLines.add(rl);
                }
                rd.Finalized__c = true;
            }
            DML.insertAsUser(receiptLines);
            DML.updateAsUser(rdsToInsert.values());
        }
        
        if (dropShipLineIds.size() > 0) {
        	List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,dropShipLineIds,new Set<String>{'asn_line__c'});
        	rWrappers = ReceivingDocumentServiceV2.checkUserErrors(rWrappers);

        	if (rdMap.values().size() > 0) {
        		DML.insertAsUser(rdMap.values());
        	}
        	ReceivingDocumentServiceV2.receive(rWrappers,rdMap);
        }
        return result;
    }
    
    global static Map<Id,Status> receive(Map<Id,Map<Id,List<ReceivingLine>>> asnsToReceive) {
        if (asnsToReceive == null || asnsToReceive.size() == 0)
            return new Map<Id,Status>();
            
        asnsToReceive.clone();
        Map<Id,Status> result = new Map<Id,Status>();

        Set<Id> tempSet = asnsToReceive.keySet();
        SOQLUtil asnQuery = new SOQLUtil('ASN__c', TRUE);
        asnQuery.addFields(new Set<String>{'Id'});
        asnQuery.setWhereClause('Id IN :tempSet');
        Map<Id,ASN__c> asns = new Map<Id,ASN__c>((List<ASN__c>) Database.query(asnQuery.getQuery()));

        Set<Id> asnLineIds = new Set<Id>();
        for (Id asnId:asnsToReceive.keySet()) {
            if (!asns.containsKey(asnId)) {
                result.put(asnId,new Status(Label.Invalid_ASN_Id));
                asnsToReceive.remove(asnId);
                continue;
            }
            Map<Id,List<ReceivingLine>> linesMap = asnsToReceive.get(asnId);
            if (linesMap == null || linesMap.size() == 0) {
                result.put(asnId,new Status(Label.No_ASN_lines_provided));
                asnsToReceive.remove(asnId);
                continue;
            }
            Boolean hasError = false;
            for (Id asnLineId:linesMap.keySet()) {
                List<ReceivingLine> rLines = linesMap.get(asnLineId);
                if (rLines == null || rLines.size() == 0) {
                    result.put(asnId,new Status(Label.No_receiving_lines_provided));
                    hasError = true;
                    break;
                }
                for (ReceivingLine rLine:rLines) {
                    SKID__c skid = rLine.skid;
                    if (skid == null) {
                        result.put(asnId,new Status(Label.Receiving_line_missing_SKID));
                        hasError = true;
                        break;
                    } else if (skid.Quantity__c == null || skid.Quantity__c <= 0) {
                        result.put(asnId,new Status(Label.SKIDs_must_have_quantity_greater_than_zero));
                        hasError = true;
                        break;
                    }
                }
                if (hasError)
                    break;
            }
            if (hasError) {
                asnsToReceive.remove(asnId);
                continue;
            }
            asnLineIds.addAll(asnsToReceive.get(asnId).keySet());
        }
        if (asnLineIds.size() == 0)
            return result;
        
        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,asnLineIds,new Set<String>{'asn_line__c'});
        Map<Id,ReceivingWrapper> rWrapperMap = new Map<Id,ReceivingWrapper>();
        for (ReceivingWrapper rWrapper:rWrappers)
            rWrapperMap.put(rWrapper.rl.Id,rWrapper);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c', TRUE);
        skidQuery.addFields(new Set<String>{'Id', 'ASN_Line__c'});
        skidQuery.setWhereClause('Type__c = \'In-Transit\' AND ASN_Line__c IN :asnLineIds');

        Map<Id,List<SKID__c>> inTransitSKIDs = new Map<Id,List<SKID__c>>();
        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        for (SKID__c skid:skids) {
            if (!inTransitSKIDs.containsKey(skid.ASN_Line__c))
                inTransitSKIDs.put(skid.ASN_Line__c,new List<SKID__c>());
            inTransitSKIDs.get(skid.ASN_Line__c).add(skid);
        }
            
        Map<Id,Receiving_Document__c> receivingDocuments = new Map<Id,Receiving_Document__c>();
        List<ReceivingWrapper> rWrappersToProcess = new List<ReceivingWrapper>();
        for (Id asnId:asnsToReceive.keySet()) {
            Boolean hasError = false;
            Map<Id,Receiving_Document__c> tempRDs = new Map<Id,Receiving_Document__c>();
            List<ReceivingWrapper> tempWrappers = new List<ReceivingWrapper>();
            for (Id asnLineId:asnsToReceive.get(asnId).keySet()) {
                if (!rWrapperMap.containsKey(asnLineId)) {
                    result.put(asnId,new Status(Label.Invalid_ASN_line_Id));
                    hasError = true;
                    break;
                }
                
                ReceivingWrapper rWrapper = rWrapperMap.get(asnLineId);
                
                if ((String)rWrapper.rl.get('Status__c') != 'Open') {
                    result.put(asnId,new Status(Label.ASN_line_not_open));
                    hasError = true;
                    break;
                } else if ((String)rWrapper.pol.Purchase_Order__r.Approval_Status__c != 'Approved') {
                    result.put(asnId,new Status(Label.Purchase_order_is_not_approved));
                    hasError = true;
                    break;
                } else if (rWrapper.rl.get('Putaway_Location__c') == null) {
                    result.put(asnId,new Status(Label.ASN_line_missing_putaway_location));
                    hasError = true;
                    break;
                } else if (!inTransitSkids.containsKey(rWrapper.rl.Id) || inTransitSkids.get(rWrapper.rl.Id).size() == 0) {
                    result.put(asnId,new Status(Label.In_transit_SKIDs_not_found));
                    hasError = true;
                    break;
                }
                
                List<ReceivingLine> rLines = asnsToReceive.get(asnId).get(asnLineId);
                Decimal totalReceiving = 0;
                List<SkidService3.SerialWrapper> newSerialWrappers = new list<SkidService3.SerialWrapper>();
                for (ReceivingLine rLine:rLines) {
                    SKID__c skid = rLine.skid;
                    
                    if (!rWrapper.item.Non_Inventory__c || rWrapper.item.Source__c == 'Outside Processing') {
                        for (String attr:rWrapper.trackedAttributes) {
                            if (!SkidService3.attributesToExclude.contains(attr) && String.isBlank(String.valueOf(skid.get(attr)))) {
                                result.put(asnId,new Status(attr + ' ' + Label.Required_for_SKID + ' for item ' + rWrapper.item.Name));
                                hasError = true;
                                break;
                            }
                        }
                    }
                    
                    skid.Company__c = (Id)rWrapper.rl.get('Company__c');
                    skid.Item__c = (Id)rWrapper.rl.get('Item__c');
                    skid.Item__r = (Item__c)rWrapper.rl.getSObject('Item__r');
                    skid = ReceivingDocumentServiceV2.copySkidAttributes(rWrapper.rl,rWrapper.pol,skid,null,rWrapper.trackedAttributes);

                    newSerialWrappers.add(new SkidService3.SerialWrapper(skid,new List<Serial__c>()));
                    totalReceiving += skid.Quantity__c;
                }
                if (hasError)
                    break;
                if (totalReceiving > KSE.addQuantityToField((Decimal)rWrapper.pol.Quantity_Still_Due__c,(Decimal)rWrapper.pol.Overage_Quantity__c)) {
                    result.put(asnId,new Status(Label.Cannot_receive_more_quantity_than_the_quantity_still_due_overage_quantity));
                    hasError = true;
                    break;
                }
                
                rWrapper.serialWrapperList = newSerialWrappers;
                tempWrappers.add(rWrapper);
                
                if (!tempRDs.containsKey(rWrapper.pol.Purchase_Order__c)) {
                    Receiving_Document__c rd = new Receiving_Document__c(
                        Type__c = 'Purchase Order Receipt',
                        Company__c = (Id)rWrapper.rl.get('Company__c'),
                        Company__r = (Company__c)rWrapper.rl.getSObject('Company__r'),
                        Supplier__c = (Id)rWrapper.rl.get('Supplier__c'),
                        Supplier__r = (Supplier__c)rWrapper.rl.getSObject('Supplier__r'),
                        Transaction_Date__c = System.now(),
                        Packing_Slip_Number__c = (String)rWrapper.rl.getSObject('ASN__r').get('Packing_Slip_Number__c'),
                        Number_of_Boxes__c = (Decimal)rWrapper.rl.getSObject('ASN__r').get('Number_of_Boxes__c'),
                        Tracking_Number__c = (String)rWrapper.rl.getSObject('ASN__r').get('Tracking_Number__c'),
                        Currency__c = (Id)rWrapper.rl.getSObject('ASN__r').get('Currency__c'),
                        Carrier__c = (String)rWrapper.rl.getSObject('ASN__r').get('Carrier__c')
                    );
                    if ((String)rWrapper.rl.getSObject('ASN__r').getSObject('FOB__r').get('FOB_Point__c') == 'Origin')
                        rd.Transaction_Type__c = 'In-Transit Purchase Order Receipt';    
                    else
                        rd.Transaction_Type__c = 'Purchase Order Receipt';
                    tempRDs.put(rWrapper.pol.Purchase_Order__c,rd);
                }
            }
            if (!hasError) {
                rWrappersToProcess.addAll(tempWrappers);
                receivingDocuments.putAll(tempRDs);
                result.put(asnId,new Status(asnId));
            }
        }
        if(receivingDocuments.values().size() >0)
        	DML.insertAsUser( receivingDocuments.values() );
        
        ReceivingDocumentServiceV2.receive(rWrappersToProcess,receivingDocuments);
        return result;
    }
    
    global class Status {
        global Boolean success { get; private set; }
        global String errorMessage { get; private set; }
        global Id recordId { get; private set; }
        global Status(Id recId) {
            success = true;
            recordId = recId;
        }
        global Status(String errorMsg) {
            success = false;
            errorMessage = errorMsg;
        }
    }
    //Class will provide the ability to add serials if needed
    global class ReceivingLine {
        global SKID__c skid { get; set; }
    }
}