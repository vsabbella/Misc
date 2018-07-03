public with sharing class ReceivingDocumentService {
	
	public static final string RD_STATUS_VOID = 'Void';
	public static final string RD_STATUS_OPEN = 'Open';
	public static final String PO_STATUS_OPEN = 'Open' ;
    public static final String PO_APPROVAL_STATUS_APPROVED = 'Approved' ;
    public static final String RD_TRANSACTION_TYPE_LOGICAL = 'Logical Purchase Order Receipt' ;
    public static final String PO_FOB_ORIGIN = 'Origin';
    public static final String SKID_TYPE_INTRANSIT = SkidService2.SKID_TYPE_INTRANSIT;
    
    public static Map<Id,set<Id>> orderLineLotsMap = new Map<Id,set<Id>>();
    public static Map<Id,decimal> orderLineTransitQuantityMap = new Map<Id,decimal>();
        
    public static map<id,string> orderlineKeyMismatchExceptionList = new map<id,string>();
    public static map<id,string> orderlineQtyMismatchExceptionList = new map<id,string>();
    public static map<Id,Map<string,string>> olIdKeyNameMap = new map<Id,Map<string,string>>();
	
	private static ReceivingDocumentService instance = null;
	public static ExceptionService exService = new ExceptionService();
	private ReceivingDocumentService(){
		
	}
	
	public static ReceivingDocumentService getInstance(){
		if(instance == null){
			instance = new ReceivingDocumentService();
		}
		return instance;
	}
	
	public class ReceivingDocumentServiceException extends Exception{
		
	}
	
	/* Description
		This method is called from the ReceivingDocumentVoidCancelExt class to void receiving documents that are closed on a purchase order/Transfer Order
	*/

	public void voidOrderReceipts(Set<Id> voidReceivingDocuments){
		voidOrderReceipts(voidReceivingDocuments, null);
	}
	
    public void voidOrderReceipts(Set<Id> voidReceivingDocuments, String action){
        if(action == null) {action = RD_STATUS_VOID;}
            
        Map<Id, sObject> mOrderLines = new Map<Id, sObject>();
        Map<Id, sObject> mOrders = new Map<Id, sObject>();
        Set<Id> receiptLineIds = new Set<Id>();
        List<Receiving_Document__c> updateReceivingDocuments = new List<Receiving_Document__c>();
        Map<id,Receipt_Line__c> getReceiptLine = new Map<Id,Receipt_Line__c>();
        List<Receipt_Line__c> updateReceiptLines = new List<Receipt_Line__c>();
        List<Accounting_Entry__c> voidAccountingEntries = new List<Accounting_Entry__c>();
        Map<Id, Decimal> oIdToReceiptLineMap = new Map<Id, Decimal>(); //KNDY-3448
        Map<Id,Decimal> qtyToReceiveByOLMap = new map<Id,Decimal>();
        list<String> attributesForService = new list<String>();
        list<SKID__c> supplySkidsTO = new list<SKID__c>();
        list<SKID__c> supplySkidsPO = new list<SKID__c>();
        list<SKID__c> inTransitSkids = new list<SKID__c>();
        list<SKID__c> voidSkids = new list<SKID__c>();
        Map<Id,sObject> sourceDocs = new Map<Id,sObject>();
        Map<Id,List<Inventory_Transaction__c>> itMap = new Map<Id,List<Inventory_Transaction__c>>();
        map<Id, Decimal> quantityByOL = new map<Id, Decimal>();
        Boolean TransferOrderflag = false;
        
        set<Id> uniqueLocations = new set<Id>();
        set<Id> uniqueLocationsSupply = new set<Id>();
        attributesForService.addAll( SkidService2.attributesForPutaway( getAttributeFields() ) );
        list<String> attributesForSupply = attributesForService.clone();
        Map<id,Map<string,string>>  mapReceivingDocTypeParameters = new Map<id,Map<string,string>>();
        try{
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Receiving_Document__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','name','Company__c','Type__c'
			});
			soql.setWhereClause('Id IN :voidReceivingDocuments');
			
			SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Receipt_Lines__r');
			childRel1.addFields(new set<string>{
				'id','name','purchase_order_line__c','purchase_order_line__r.purchase_order__c','purchase_order_line__r.Item__c',
				'Purchase_Order_Line__r.Purchase_Order__r.Type__c','Purchase_order_line__r.Quantity_Still_Due__c','order_line__r.quantity_to_Receive__c',
				'order_line__r.quantity_Ordered__c','purchase_order_line__r.quantity_received__c','purchase_order_line__r.delivery_location__c',
				'purchase_order_line__r.Quantity_Shipped__c','invoiced__c','Uninvoiced_Quantity__c','order_line__c','order_line__r.order__c',
				'order_line__r.Shipping_Item__c','order_line__r.quantity_received__c','quantity_received__c','order_line__r.deliver_to_location__c',
				'item__r.Non_Inventory__c','order_line__r.Quantity_Shipped__c','Quantity_Shipped__c','Purchase_Order_Line__r.Quantity_Returned_to_Supplier_for_Credit__c',
				'Purchase_Order_Line__r.Quantity_Returned_to_Supplier__c','Quantity_Returned_to_Supplier_for_Credit__c',
				'Quantity_Returned_to_Supplier__c'
			});
			soql.addChildRelationship(childRel1);
			
			SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
			childRel2.addFields(new set<string>{
				'id','name'
			});
			childRel2.setWhereClause('void__c = false');
			soql.addChildRelationship(childRel2);
			
			List<Receiving_Document__c> receivingDocs = Database.query(soql.getQuery());

            //Set void status on header and lines, organize data for later reference                                            
            for(Receiving_Document__c rd : receivingDocs){
                
                rd.status__c = action;
                Map<string,string> mapParameters=new Map<string,string>();
                if(rd.Type__c.toLowerCase()=='Transfer Order Receipt'.toLowerCase())
                {
                    
                    attributesForSupply.add('Order_Line__c');
                    mapParameters.put('sourceDocVoid','Void - Transfer Order Receipt');
                }
                else if(rd.Type__c.toLowerCase()=='Purchase Order Receipt'.toLowerCase()){
                    attributesForSupply.add('Purchase_Order_Line__c');
                    mapParameters.put('sourceDocVoid','Void - Purchase Order Receipt');
                } else if (rd.Type__c == 'Purchase Order Return') {
                    mapParameters.put('sourceDocVoid','Void - Purchase Order Return');
                }
                mapReceivingDocTypeParameters.put(rd.id,mapParameters);
                updateReceivingDocuments.add(rd);
                for(Receipt_Line__c rl : rd.Receipt_Lines__r){
                    //check if receipt is invoiced in full or uninvoiced quantity is > 0
                    if ((!rl.Invoiced__c) && (rl.Uninvoiced_Quantity__c == rl.Quantity_Received__c)) //KNDY-2365
                    { 
                        rl.status__c = action;
                        Decimal updatedQtyShipped = 0;//rl.order_line__r.Quantity_Shipped__c - rl.Quantity_Shipped__c;
                        receiptLineIds.add(rl.Id);
                        updateReceiptLines.add(rl);
                        getReceiptLine.put(rl.Id,rl);
                        if(rd.Type__c.toLowerCase()=='Transfer Order Receipt'.toLowerCase())
                        {
                            updatedQtyShipped = rl.order_line__r.Quantity_Shipped__c - rl.Quantity_Shipped__c;
                            mOrderLines.put(rl.order_line__c, new Order_Line__c(Id = rl.order_line__c, status__c = 'Open', Shipping_Company__c = rd.Company__c,
                             quantity_received__c = rl.order_line__r.quantity_received__c, deliver_to_location__c = rl.order_line__r.deliver_to_location__c,
                            Shipping_Item__c = rl.order_line__r.Shipping_Item__c, Shipping_Item__r = rl.Item__r, Quantity_Shipped__c = updatedQtyShipped));
                            mOrders.put(rl.order_line__r.order__c, new Order__c(Id = rl.order_line__r.order__c, Status__c = 'Open'));
                        
                            if(!oIdToReceiptLineMap.containsKey(rl.order_line__c) ){
                                oIdToReceiptLineMap.put(rl.Order_Line__c,0 );
                            }
                            qtyToReceiveByOLMap.put(rl.Order_Line__c,rl.Order_Line__r.Quantity_To_Receive__c);
                            oIdToReceiptLineMap.put(rl.Order_Line__c, KSE.addQuantityToField(oIdToReceiptLineMap.get(rl.Order_Line__c), rl.Quantity_Received__c));
                        }
                        else if(rd.Type__c.toLowerCase()=='Purchase Order Receipt'.toLowerCase())
                        {
                            updatedQtyShipped = rl.Purchase_order_line__r.Quantity_Shipped__c - rl.Quantity_Shipped__c;
                            mOrderLines.put(rl.Purchase_order_line__c, new Purchase_Order_Line__c(Id = rl.Purchase_order_line__c, status__c = 'Open', Company__c = rd.Company__c,
                            quantity_received__c = rl.Purchase_order_line__r.quantity_received__c, delivery_location__c = rl.Purchase_order_line__r.delivery_location__c,
                            Item__c = rl.Purchase_order_line__r.Item__c, Item__r = rl.Item__r, Quantity_Shipped__c = updatedQtyShipped));
                            mOrders.put(rl.Purchase_order_line__r.Purchase_order__c, new Purchase_Order__c(Id = rl.Purchase_order_line__r.Purchase_order__c, Status__c = 'Open'));
                        
                             if(!oIdToReceiptLineMap.containsKey(rl.Purchase_order_line__c) ){
                                oIdToReceiptLineMap.put(rl.Purchase_order_line__c,0 );
                             }
                            qtyToReceiveByOLMap.put(rl.Purchase_Order_Line__c,rl.Purchase_Order_Line__r.Quantity_Still_Due__c);
                            oIdToReceiptLineMap.put(rl.Purchase_order_line__c, KSE.addQuantityToField(oIdToReceiptLineMap.get(rl.Purchase_order_line__c), rl.Quantity_Received__c));
                        } else if (rd.Type__c == 'Purchase Order Return') {
                            Purchase_Order_Line__c poLine;
                            if (mOrderLines.containsKey(rl.Purchase_Order_Line__c))
                                poLine = (Purchase_Order_Line__c)mOrderLines.get(rl.Purchase_Order_Line__c);
                            else
                                poLine = new Purchase_Order_Line__c(Id = rl.Purchase_Order_Line__c,Quantity_Returned_to_Supplier_for_Credit__c = rl.Purchase_Order_Line__r.Quantity_Returned_to_Supplier_for_Credit__c,Quantity_Returned_to_Supplier__c = rl.Purchase_Order_Line__r.Quantity_Returned_to_Supplier__c);
                            poLine.Quantity_Returned_to_Supplier_for_Credit__c = KSE.subtractDecimals(poLine.Quantity_Returned_to_Supplier_for_Credit__c,rl.Quantity_Returned_to_Supplier_for_Credit__c);
                            poLine.Quantity_Returned_to_Supplier__c = KSE.subtractDecimals(poLine.Quantity_Returned_to_Supplier__c,rl.Quantity_Returned_to_Supplier__c);
                            mOrderLines.put(poLine.Id,poLine);
                        }
                    }
                    else
                    {
                        
                        throw new ReceivingDocumentServiceException(rd.name + ': You cannot void this document, it has been partially or fully invoiced.');
                    }   
                }
                voidAccountingEntries.addAll(rd.Accounting_Entries__r);
            }
            
            Set<String> itFields = new Set<String>{ 'Id','From_SKID__r.Id','Receipt_Line__r.Receiving_Document__c','Receipt_Line__r.Company__c',
            										'Type__c','From_Lot__r.Name','Receipt_Line__r.Shipment_Line__c', 'Company__c',
            										'Receipt_Line__r.Order_Line__c','Receipt_Line__r.Purchase_Order_Line__c','Receipt_Line__r.Location__c' };
            										
            itFields.addAll(SchemaUtil.getInstance().getAllCustomFieldsFromObject('','Inventory_Transaction__c'));
            itFields.addAll(SchemaUtil.getInstance().getAllCustomFieldsFromObject('From_SKID__r.','SKID__c'));
            
            String whereClause = 'Receipt_Line__c IN :receiptLineIds AND Type__c IN (\'Purchase Order Receipt\',\'Purchase Order Return\',\'Transfer Order Receipt\')';
        
		    soql = new SOQLUtil('Inventory_Transaction__c');
		    soql.addFields(itFields);
		    soql.setWhereClause(whereClause);
	    
            List<Inventory_Transaction__c> receivingTransactions = Database.query(soql.getQuery());   

            for (Inventory_Transaction__c it:receivingTransactions) {
                if (it.Type__c == 'Purchase Order Return')
                    uniqueLocations.add(it.From_Location__c);
                else
                    uniqueLocations.add(it.To_Location__c);
                    
                SKID__c skid = new SKID__c(Type__c = SkidService2.SKID_TYPE_LOCATION);
                if (it.Type__c == 'Purchase Order Return') {
                    if (it.From_SKID__c != null) {
                        skid = it.From_SKID__r;
                    } else {
                        for (String attr:attributesForService) {
                            if (attr == 'Purchase_Order_Line__c') {
                                continue;
                            } else if (attr == 'Location__c') {
                                skid.Location__c = it.From_Location__c;
                            } else if (attr == 'Lot__c') {
                                skid.Lot__c = it.From_Lot__c;
                                skid.Lot_Number__c = it.From_Lot__r.Name;
                            } else if (attr == 'Bin__c') {
                                skid.Bin__c = it.From_Bin__c;
                            } else {
                                skid.put(attr,it.get(attr));
                            }
                        }
                    }  
                    skid.Quantity__c = it.Quantity__c;  
                } else if (it.Type__c != 'Purchase Order Return') {
                    SkidService2.copyITAttributesToSkid(skid,it,attributesForService);
                    skid.Quantity__c = -it.Quantity__c;
                }
                skid.Company__c = it.Company__c;
                
                voidSkids.add(skid);
                
                Inventory_Transaction__c voidIT;
                if (it.Type__c == 'Purchase Order Return') {
                    //voidIT = SkidService2.createIT(null,skid.Item__c,mapReceivingDocTypeParameters.get(getReceiptLine.get(it.Receipt_Line__r.Id).Receiving_Document__c).get('sourceDocVoid'),it.Purchase_Order_Line__c,null,null,skid.Location__c,skid,attributesForService);
                    voidIT = SkidService3.createInventoryTransaction(it.Receipt_Line__r, mapReceivingDocTypeParameters.get(getReceiptLine.get(it.Receipt_Line__r.Id).Receiving_Document__c).get('sourceDocVoid'), it.Quantity__c, null, skid, attributesForService);
                    voidIT.Purchase_Order_Line__c = it.Purchase_Order_Line__c;
                } else {
                    //voidIT = SkidService2.createIT(null,skid.Item__c,mapReceivingDocTypeParameters.get(getReceiptLine.get(it.Receipt_Line__r.Id).Receiving_Document__c).get('sourceDocVoid'),null,null,null,skid.Location__c,skid,attributesForService);
                    voidIT = SkidService3.createInventoryTransaction(it.Receipt_Line__r, mapReceivingDocTypeParameters.get(getReceiptLine.get(it.Receipt_Line__r.Id).Receiving_Document__c).get('sourceDocVoid'), it.Quantity__c, null, skid, attributesForService);
                    voidIT.From_Bin__c = voidIT.Bin__c;
                }
                //voidIT.Receipt_Line__c = it.Receipt_Line__c;
                //voidIT.Quantity__c = it.Quantity__c;
                Id sourceDocId = it.Receipt_Line__r.Receiving_Document__c;
                sourceDocs.put(sourceDocId,new Receiving_Document__c(Company__c = it.Receipt_Line__r.Company__c));
                if (!itMap.containsKey(sourceDocId))
                    itMap.put(sourceDocId,new List<Inventory_Transaction__c>());
                itMap.get(sourceDocId).add(voidIT);
                
                SKID__c inTransitSkid;
                if(it.Type__c.toLowerCase()=='Transfer Order Receipt'.toLowerCase())
                {  
                    inTransitSkid = new SKID__c(Type__c = SkidService2.SKID_TYPE_INTRANSIT,Shipment_Line__c=it.Receipt_Line__r.Shipment_Line__c,Order_Line__c = It.Order_Line__c);
                    if(!quantityByOL.containsKey(it.receipt_line__r.Order_Line__c)){
                        quantityByOL.put(it.receipt_line__r.Order_Line__c,0 );
                    }
                    quantityByOL.put(it.receipt_line__r.Order_Line__c, KSE.addQuantityToField(quantityByOL.get(it.receipt_line__r.Order_Line__c), it.Quantity__c));
                    SkidService2.copyITAttributesToSkid( inTransitSkid, it, attributesForService );
                    inTransitSkid.Location__c = it.From_Location__c;
                    inTransitSkid.Quantity__c =  it.Quantity__c;
                    inTransitSkid.Lot_Number__c =  it.From_Lot__r.Name;
                    inTransitSkid.Company__c = it.Company__c;
                    
                    inTransitSkids.add(inTransitSkid);
                    TransferOrderflag = true;
                }
                else if(it.Type__c.toLowerCase()=='Purchase Order Receipt'.toLowerCase())
                {
                    if(!quantityByOL.containsKey(it.receipt_line__r.Purchase_Order_Line__c)){
                        quantityByOL.put(it.receipt_line__r.Purchase_Order_Line__c,0 );
                    }
                    quantityByOL.put(it.receipt_line__r.Purchase_Order_Line__c, KSE.addQuantityToField(quantityByOL.get(it.receipt_line__r.Purchase_Order_Line__c), it.Quantity__c));
                }
                uniqueLocationsSupply.add( it.receipt_Line__r.Location__c );
            }
            
            decimal quantityReceived=0; 
            if (receivingDocs[0].Type__c != 'Purchase Order Return') {
                for( sObject ol : mOrderLines.values() ) {
                    quantityReceived = 0;
                    string sObjectApIName = '';
                    sObjectAPIName = ol.getSObjectType().getDescribe().getLocalName();
                    
                
                    SKID__c supplySkid;
                
                
                    if(sObjectAPIName.toLowerCase() =='order_line__c'.toLowerCase())
                    {
                       supplySkid  = new SKID__c(  Location__c = (Id)ol.get('Deliver_To_Location__c'), Item__c = (Id)ol.get('Shipping_Item__c'), 
                                Quantity__c = 0,  order_line__c = ol.id, Type__c = 'TO Supply', Company__c = (Id)ol.get('Shipping_Company__c'));
                        if( quantityByOL.containsKey( ol.id )){
                         supplySkid.Quantity__c = ((decimal)qtyToReceiveByOLMap.get(ol.Id) + quantityByOL.get(ol.id));
                        }
                        else if( (boolean)ol.getsobject('Shipping_Item__r').get('Non_Inventory__c')){
                            supplySkid.Quantity__c = ((decimal)qtyToReceiveByOLMap.get(ol.Id) + oIdToReceiptLineMap.get(ol.id));
                        }
                    
                        supplySkidsTO.add(supplySkid);
                    }
                    else if(sObjectAPIName.toLowerCase() =='purchase_order_line__c'.toLowerCase()){
                        supplySkid  = new SKID__c(  Location__c = (Id)ol.get('Delivery_Location__c'), Item__c = (Id)ol.get('Item__c'), 
                                Quantity__c = 0,  Purchase_order_line__c = ol.id, Type__c = 'PO Supply', Company__c = (Id)ol.get('Company__c'));
                    
                        if( quantityByOL.containsKey( ol.id )){
                         supplySkid.Quantity__c = quantityByOL.get(ol.id);
                        }
                        else if( (boolean)ol.getsobject('Item__r').get('Non_Inventory__c')){
                            supplySkid.Quantity__c = oIdToReceiptLineMap.get(ol.id);
                        }
                    
                        supplySkidsPO.add(supplySkid);
                    }
                
                    quantityReceived = (decimal)ol.get('Quantity_Received__c') - oIdToReceiptLineMap.get(ol.id);
                
                    ol.put('Quantity_Received__c', quantityReceived) ;
                
                
                }
            }
            if(inTransitSkids.size()>0)
            {
                SkidService2.putAwayService( inTransitSkids, attributesForSupply, uniqueLocationsSupply, SkidService2.SKID_TYPE_INTRANSIT, false);
                orderService.ClearExceptions(mOrderLines.values());
            }
            if(supplySkidsTO.size()>0)
            {    
                SkidService2.putAwayService( supplySkidsTO, attributesForSupply, uniqueLocationsSupply, 'TO Supply', false);
            }
            if(supplySkidsPO.size()>0)
            {    
                SkidService2.putAwayService( supplySkidsPO, attributesForSupply, uniqueLocationsSupply, 'PO Supply', false);
            }
            
            if (receivingDocs[0].Type__c == 'Purchase Order Return') {
                Map<String,SKID__c> toSkidsMap = SkidService2.putAwayService(voidSkids,attributesForService,uniqueLocations,'Location',false);
                SkidService2.inventoryTransactionsForPutAway(sourceDocs,itMap,null,null,attributesForService,toSkidsMap,'none','To');
            } else {
                map< String, SKID__c > toSkids = SkidService2.putAwayService( voidSkids, attributesForService, uniqueLocations, 'Location', false);
                SkidService2.inventoryTransactionsForPutAway(sourceDocs,itMap,null,null,attributesForService,toSkids,'none','from');
            }
            
            DML.updateAsUser(updateReceivingDocuments);
            DML.updateAsUser(updateReceiptLines);
            DML.updateAsUser(mOrders.values());
            DML.updateAsUser(mOrderLines.values());

            if(inTransitSkids.size()>0 && TransferOrderflag == true)
            {
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				Set<Id> orderLineIds = mOrderLines.keyset();
				
				soql = new SOQLUtil('Skid__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id'
				});
				soql.setWhereClause('order_line__c in :orderLineIds and Quantity__c = 0');

				Map<id,Skid__c> zeroSkids = new Map<id,Skid__c>((List<Skid__c>)Database.query(soql.getQuery()));

                if(zeroSkids.size()>0)
                    DML.deleteAsSystem(zeroSkids.values());
            }
            else{
                //PTM-645
                
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				soql = new SOQLUtil('Skid__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id'
				});
				soql.setWhereClause('Receipt_Line__c in :receiptLineIds and type__c = :SKID_TYPE_INTRANSIT');

				Map<id,Skid__c> deleteinTransitSkids = new Map<id,Skid__c>((List<Skid__c>)Database.query(soql.getQuery()));

                if(deleteinTransitSkids.size()>0)
                    DML.deleteAsSystem(deleteinTransitSkids.values());
            }

        }
        catch(exception e)
        {
            throw e;
        }
        
    }
	
	//KNDY-3155
	public static void updateReceiptLineLineType(List<Receipt_Line__c> receiptLines, Map<Id,Receipt_Line__c> oldMap){
		//default Line_Type__c to Purchase_Order_Line__r.Line_Type__c
		
		//build a set of all the Purchase_Order_Line__c Ids that we want to query
		Set<Id> polIdSet = new Set<Id>();
		List<Receipt_Line__c> rlsToUpdate = new List<Receipt_Line__c>();
		
		for (Receipt_Line__c rl: receiptLines) {
			if (KSE.isFieldChanging('Purchase_Order_Line__c', rl, trigger.oldMap)) {
				//we don't want to populate the Line Type field in the cases where it is being explicity set on an insert, 
				//or explicitly changed on an update.  we are going to assume the user wants it to be set to something other
				//than the default (from PO line type) in these cases.
				if (!KSE.isFieldChanging('Line_Type__c', rl, trigger.oldMap)) {
					if (rl.Purchase_Order_Line__c != null) {
						polIdSet.add(rl.Purchase_Order_Line__c);
						rlsToUpdate.add(rl);	
					}						
				}			
		    }		    
		}
		
		//build a map of pol Ids to pols so we have the line type available

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Line_Type__c'
		});
		soql.setWhereClause('Id IN :polIdSet');

		Map<Id, Purchase_Order_Line__c> polIdMap = new Map<Id, Purchase_Order_Line__c>((List<Purchase_Order_Line__c>)Database.query(soql.getQuery()));
		
		//loop through the rls to update and set the Line Types
		for (Receipt_Line__c rl: rlsToUpdate) {
			String lineType = null;
			if (polIdMap.containsKey(rl.Purchase_Order_Line__c)) {
				lineType = polIdMap.get(rl.Purchase_Order_Line__c).Line_Type__c;
			}
			rl.Line_Type__c = lineType;
		}		

	}
	
	
	
	
	
	/* Description 
		This method is called from SupplierInvoiceAutomationBatch.  It takes a set of Receipt Line Ids and creates invoices from them.
		Currently used for Suppliers with Auto Invoicing (KNDY-2190), but could be used for other purposes.
	*/	
	public static void generateInvoicesFromReceiptLines(set<Id> rlIdSet) {		
		
				
		//get the receipt line and related records
        Set<String> rlFields = new Set<String>();        
 		rlFields.addAll( new set<string>{'Id','Purchase_Order__r.Company__c','Purchase_Order_Line__r.Company__c','Purchase_Order_Line__r.Delivery_Facility__c','Purchase_Order_Line__r.Need_Date__c','Purchase_Order__r.Remit_To_Supplier__c','Purchase_Order__r.Remit_To_Supplier__r.Payment_Term__c','Receiving_Document__r.Date_Received__c',
						'Purchase_Order__r.Name','Purchase_Order_Line__r.Name','Supplier__r.Payment_Method_G__c','Supplier__r.Remit_To__r.Payment_Term__c','Purchase_Order__c',
						'Purchase_Order_Line__c','Item__c','Description__c','Uninvoiced_Quantity__c','Unit_Price__c','Supplier_Auto_Invoice__c'} ); 
						     
        
		/*string rlQuery = 	'SELECT ' + string.join(new List<string>(rlFields),', ') + ' ' +
			  				'FROM Receipt_Line__c ' +
							'WHERE id in :rlIdSet ' + 
							'AND Supplier_Auto_Invoice__c = null ' + 
							'ORDER BY Purchase_Order__r.Name, Purchase_Order_Line__r.Name';
		*/                       
        //system.debug('rlQuery: ' + rlQuery);
		List<Receipt_Line__c> rlList = new List<Receipt_Line__c>();
        try{
        	String whereClause = ' id in :rlIdSet ' + 
								 ' AND Supplier_Auto_Invoice__c = null ' + 
								 ' ORDER BY Purchase_Order__r.Name, Purchase_Order_Line__r.Name';
        
		    SOQLUtil soql = new SOQLUtil('Receipt_Line__c');
		    soql.addFields(rlFields);
		    soql.setWhereClause(whereClause);
	    
        	rlList = Database.query(soql.getQuery());
        }catch(Exception ex){
        	throw ex;
        }        

      
      	Savepoint sp = Database.setSavepoint();
		try {     
      
	        //loop through and create a Supplier Invoice header for each Receipt Line
	        //save them in a map so we have Receipt Lines linked to Supplier Invoices        
	        Map<Receipt_Line__c, Supplier_Invoice__c> rlSiMap = new Map<Receipt_Line__c, Supplier_Invoice__c>();
			for (Receipt_Line__c rl : rlList) {
				String exceptionMsg;
				Boolean hasException = false;
				Decimal unitPrice = rl.Unit_Price__c;
				if (unitPrice == null) {
					unitPrice = 0;
					hasException = true;
					exceptionMsg = 'Receipt Line Unit Price (from PO Line) is null.';	
				}			
				Supplier_Invoice__c si = new Supplier_Invoice__c();
				si.Exception__c = hasException;
				si.Exception_Details__c = exceptionMsg;			
				si.Auto_Generated__c = true;
				si.Invoice_Type__c = 'Invoice';
				si.Company__c = rl.Purchase_Order__r.Company__c;
				si.Supplier__c = rl.Purchase_Order__r.Remit_To_Supplier__c;
				si.Date_Invoiced__c = System.now();
				si.Date_Received__c = rl.Receiving_Document__r.Date_Received__c;
				si.Supplier_Invoice__c = (KSE.getUniqueNumberString() + '-' + rl.Purchase_Order__r.Name + rl.Purchase_Order_Line__r.Name); //Auto invoices are a concatenation of PO name and PO Line Name (usually 2 autonumbers)		
				if (rl.Uninvoiced_Quantity__c != null) {
					si.Invoice_Amount__c =  (rl.Uninvoiced_Quantity__c * unitPrice);
				}		
				si.Status__c = 'Incomplete';
				si.Hold__c = true;
				si.Payment_Method_G__c = rl.Supplier__r.Payment_Method_G__c;
				si.Payment_Term__c = rl.Purchase_Order__r.Remit_To_Supplier__r.Payment_Term__c;
				si.Purchase_Order__c = rl.Purchase_Order__c;
				rlSiMap.put(rl, si);			
			}		
			if (!rlSiMap.isEmpty()) {
				DML.insertAsUser(rlSiMap.values()); //TODO: add support for partial successes?		
			}			
	
	
			//loop through the Receipt Line / Supplier Invoice map and create 1 Supplier Invoice Line for each Supplier Invoice
			List<Supplier_Invoice_Line__c> silList = new List<Supplier_Invoice_Line__c>();
			
			Set<Id> itemIds = new Set<Id>();
			Set<Id> facilityIds = new Set<Id>();
			List<Date> dateList = new List<Date>();			
			
			for (Receipt_Line__c rl : rlSiMap.keySet()) {
				itemIds.add(rl.Item__c);
				facilityIds.add(rl.Purchase_Order_Line__r.Delivery_Facility__c);
				dateList.add(rl.Purchase_Order_Line__r.Need_Date__c);
			}
			
			ItemService.preCacheCostRecords(dateList, itemIds, facilityIds);
			
			for (Receipt_Line__c rl : rlSiMap.keySet()) {
				Supplier_Invoice_Line__c sil = new Supplier_Invoice_Line__c();
				sil.Supplier_Invoice__c = rlSiMap.get(rl).Id;
				sil.Purchase_Order__c = rl.Purchase_Order__c;
				sil.Purchase_Order_Line__c = rl.Purchase_Order_Line__c;
				sil.Item__c	= rl.Item__c;
				sil.Description__c = rl.Description__c;
				sil.Invoice_Quantity__c = rl.Uninvoiced_Quantity__c;
				sil.Unit_Price__c = rl.Unit_Price__c;//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price.
				DateTime costDate;
				if(rl.Purchase_Order_Line__r.Need_Date__c != null )
					costDate = datetime.newInstance(rl.Purchase_Order_Line__r.Need_Date__c.year(), rl.Purchase_Order_Line__r.Need_Date__c.month(),rl.Purchase_Order_Line__r.Need_Date__c.day());
				Double stdCost = ItemService.getActiveStandardCost(itemIds,facilityIds,rl.Purchase_Order_Line__r.Company__c,rl.Purchase_Order_Line__r.Delivery_Facility__c,costDate).get(rl.Item__c);
				if (stdCost == null) stdCost = 0; 
				if ((stdCost != null) && (rl.Uninvoiced_Quantity__c != null)) {
					sil.Extended_Cost__c = stdCost * rl.Uninvoiced_Quantity__c;	
				}
				silList.add(sil);		
			}
			if (!silList.isEmpty()) {
				DML.insertAsUser(silList); //TODO: add support for partial successes?		
			}		
			
			//now go through and update the lookup relationship on the RLs to point to the newly created SIs so we don't create them again
	 		for (Receipt_Line__c rl: rlSiMap.keySet()) {
	 			rl.Supplier_Auto_Invoice__c = rlSiMap.get(rl).Id;
	 		}
	        if (!rlSiMap.isEmpty()) {	        	
	        	List<Receipt_Line__c> updateRlList = new List<Receipt_Line__c>();
	        	updateRlList.addAll(rlSiMap.keySet()); //convert set to list so we can update it
	        	DML.updateAsUser(updateRlList); //TODO: add support for partial successes?		
	        }
	
	    } catch(Exception ex) {
        	Database.rollback(sp);
        	throw ex;
        }

	    
	}	
	
	
    
    private static Map<Object, Object> recordCache = new Map<Object, Object>();
    private static SchemaUtil util = SchemaUtil.getInstance();

    public static void flush() {
        recordCache.clear();
    }

    public static map<Id,SObject> cachedReceiptLines(Set<Id> recDocIds, String status) {
        
        if (recDocIds == null || recDocIds.isEmpty()) return new map<Id,SObject>();
        map<Id,SObject> rLines = (map<Id,SObject>)recordCache.get(recDocIds);
        
        if (rLines == null) {
            set<String> fieldStrings = new set<string>{'company__c','item__c','purchase_order__c','Purchase_Order_Line__r.Quantity_To_Stock__c','Purchase_Order_Line__r.Order_Quantity__c','purchase_order__r.supplier__c','purchase_order__r.supplier__r.name','purchase_order__r.status__c','purchase_order_line__r.id',
            				'Quantity_To_Stock__c','purchase_order_line__r.delivery_Facility__c','purchase_order_line__r.company__c','purchase_order_line__r.need_date__c','purchase_order_line__r.delivery_location__c','purchase_order_line__r.purchase_uom__r.name','unit_price__c', 'purchase_order_line__r.overage_quantity__c','purchase_order__r.fob_term__c', 'receiving_document__r.type__c',
                            'purchase_order_line__r.delivery_location__r.facility__c','purchase_order_line__r.status__c','purchase_order_line__r.purchase_uom__c','purchase_order__r.fob_term__r.fob_point__c','purchase_order_line__r.purchase_order__r.supplier__r.name',
                            'item__r.item_attribute__c', 'supplier__c', 'purchase_order_line__r.consigned__c','item__r.stocking_uom__c','item__r.Stocking_uom__r.name','purchase_order_line__r.purchase_order__r.supplier__c', 'purchase_order_line__r.item__r.Packaging_UOM__c',
                            'item__r.non_inventory__c','item__r.class__r.minimum_shelf_life_in_days__c','purchase_order_line__r.delivery_facility__c', 'purchase_order_line__c','purchase_order_line__r.quantity_received__c','item__r.source__c',
                            'purchase_order__r.approval_status__c','purchase_order__r.status__c', 'receiving_document__c', 'receiving_document__r.status__c','purchase_order_line__r.item__r.Stocking_uom__r.name','purchase_order_line__r.item__r.stocking_uom__c',
                            'purchase_order_line__r.work_order__c','purchase_order_line__r.item_specification__c', 'purchase_order_line__r.item_specification__r.item__c','purchase_order__r.type__c','purchase_order_line__r.work_order__r.assembly_item_specification__c', 'purchase_order_line__r.Quantity_Shipped__c',
                            'purchase_order_line__r.delivery_Facility__r.facility_identifier__c', 'facility__r.facility_identifier__c'};
            
            fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('purchase_order_line__r.item__r.item_attribute__r.','item_attribute__c') );
            fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('item__r.item_attribute__r.','item_attribute__c') );
            fieldStrings.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('','receipt_line__c') );
            
            for( Stock_Movement_Rule_Settings__c smrs : Stock_Movement_Rule_Settings__c.getAll().values() ){
            
                if( smrs.Source_Document__c == 'Purchase Order' ){
                    
                    if( smrs.Source_Document_Path__c == null || smrs.Source_Document_Path_Putaway__c == null ){
                        throw new ReceivingDocumentServiceException('Source document path fields have not been populated in the stock movement rule custom settings!');
                    }
                    
                	fieldStrings.add( 'purchase_order_line__r.'+(smrs.Source_Document_Path__c).toLowerCase() );
                	fieldStrings.add( 'purchase_order_line__r.'+(smrs.Source_Document_Path_Putaway__c).toLowerCase() );
                }
            }
            
            String whereClause = 'Receiving_Document__c IN :recDocIds and ' + status;
        
		    SOQLUtil soql = new SOQLUtil('Receipt_Line__c');
		    soql.addFields('PO_Receiving');
		    soql.addFields(fieldStrings);
		    soql.setWhereClause(whereClause);
	    
            /*rLines = new Map<id,Receipt_Line__c>((List<Receipt_Line__c>) 
                        Database.query( util.generateQueryFromFieldSet( 'Receipt_Line__c', new set<string>{'PO_Receiving'}, 
                        fieldStrings,
                        'Receiving_Document__c IN:recDocIds and '+status) ));*/
            
            rLines = new Map<id,Receipt_Line__c>((List<Receipt_Line__c>) Database.query(soql.getQuery()));    
                                
            recordCache.put(recDocIds, rLines);
        } 
        return rLines;
    }
    
    public static map<Id,SObject> cachedPOLines(Set<Id> poIds) {
        
        if (poIds == null || poIds.isEmpty()) return new map<Id,SObject>();
        map<Id,SObject> poLines = (map<Id,SObject>)recordCache.get(poIds);
        
        if (poLines == null) {
            
            set<String> polFields = new set<string>{'company__c','item__c','purchase_order__c','purchase_order__r.supplier__c','purchase_order__r.supplier__r.name','purchase_Order__r.status__c','delivery_location__c',
                            'Order_Quantity__c','Quantity_To_Stock__c', 'item__r.Stocking_uom__c', 'Item__r.Packaging_UOM__c',
                            'delivery_location__r.facility__c','status__c','purchase_uom__c','purchase_uom__r.name','unit_price__c', 'overage_quantity__c','purchase_order__r.type__c',
                            'item__r.item_attribute__c', 'supplier__c', 'consigned__c','item__r.Stocking_uom__c','item__r.Stocking_uom__r.name','item__r.source__c',
                            'item__r.non_inventory__c','item__r.class__r.minimum_shelf_life_in_days__c','delivery_facility__c','work_order__r.assembly_item_specification__c', 'Delivery_Facility__r.Facility_Identifier__c',
                            'work_order__c','item_specification__c', 'item_specification__r.item__c', 'Quantity_Shipped__c', 'Purchase_Order__r.Type__c', 'Sales_Order_Line__c', 'Sales_Order_Line__r.Ship_From_Location__c', 'Sales_Order_Line__r.Ship_From_Location__r.Facility__r.Facility_Identifier__c',
                            'Sales_Order_Line__r.Ship_From_Location__r.Id', 'Sales_Order_Line__r.Ship_From_Location__r.Facility__c', 'Sales_Order_Line__r.Ship_From_Location__r.Bin_Tracked__c','Sales_Order_Line__r.Sales_Order__c','Sales_Order_Line__r.Company__c'};
            
            polFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('item__r.item_attribute__r.','item_attribute__c') );
            polFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('','purchase_order_line__c') );
            
            for( Stock_Movement_Rule_Settings__c smrs : Stock_Movement_Rule_Settings__c.getAll().values() ){
            
                if( smrs.Source_Document__c == 'Purchase Order' ){
                    
                    if( smrs.Source_Document_Path__c == null || smrs.Source_Document_Path_Putaway__c == null ){
                        throw new ReceivingDocumentServiceException('Source document path fields have not been populated in the stock movement rule custom settings!');
                    }
                    
                    polFields.add( (smrs.Source_Document_Path__c).toLowerCase() );
                    polFields.add( (smrs.Source_Document_Path_Putaway__c).toLowerCase() );
                }
            }
            
            String whereClause = 'Purchase_Order__c IN :poIds and Quantity_Still_Due__c > 0 and Status__c = \'Open\'';
        
		    SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c');
		    soql.addFields('Receiving_RO');
		    soql.addFields(polFields);
		    soql.setWhereClause(whereClause);
	    
            /*poLines = new Map<id,Purchase_Order_Line__c>((List<Purchase_Order_Line__c>) 
                        Database.query( util.generateQueryFromFieldSet( 'Purchase_Order_Line__c', new set<string>{'Receiving_RO'}, 
                        polFields,
                        'Purchase_Order__c IN:poIds and Quantity_Still_Due__c > 0 and Status__c = \'Open\'') ));
            */
            
            poLines = new Map<id,Purchase_Order_Line__c>((List<Purchase_Order_Line__c>) Database.query(soql.getQuery()));
            recordCache.put(poIds, poLines);
        } 
        return poLines;
    }
    
    public static map<Id, SObject> cachedFromSkids(Set<Id> polIds) {
        if (polIds == null || polIds.isEmpty()) return new map<Id,SObject>();
        
        map<Id,SKID__c> fromSkids = (map<Id,SKID__c>)recordCache.get(polIds);
        
        if (fromSkids == null) {
            String POSupplyType = SkidService2.SKID_TYPE_PO_SUPPLY;
            fromSkids =  new map<Id, SKID__c>();

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Location__c','Location__r.Facility__r.Company__c','Bin__c','Location__r.Facility__c','Purchase_Order_Line__c','Quantity__c',
				'Item__c','Lot__c','Facility2__c','Packaging_UOM__c','Stocking_UOM__c', 'Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c', 'Facility2__r.Facility_Identifier__c'
			});
			soql.setWhereClause('type__c= :POSupplyType and Purchase_Order_Line__c IN:polIds and Quantity__c > 0');

			for( SKID__c fromSkid : Database.query(soql.getQuery())){
                fromSkids.put( fromSkid.Purchase_Order_Line__c, fromSkid );
            }
            
            recordCache.put(polIds, fromSkids);

        } 
        
        return fromSkids;
    }
    
    public static String checkUserErrors(List<receivingWrapper> rlWrapperList, map<String, Lot__c > lotMap, Set<String> lotNames, string sourceDocument, map<Id, SKID__c> transitSkids){
        	
        try{
        	Decimal anyQuantityEntered = 0;
        	map<Id, Decimal> totalQuantityMap = new map<Id, Decimal>();
        	String itemString = 'Item__r';
        	
        	if( sourceDocument == 'Transfer Order' ){
        	    itemString = 'Receiving_Item__r';    
        	}
        	
            for( receivingWrapper rw : rlWrapperList ){
                
            	Decimal totalQuantity = 0;
                
                for( Integer i = 0; i < rw.skidList.size() ; i ++ ){
                    
                    if( rw.skidList[i].Quantity__c != null && rw.skidList[i].Quantity__c > 0  ){
                        
                        totalQuantity += rw.skidList[i].Quantity__c;
                        anyQuantityEntered += rw.skidList[i].Quantity__c;
                      if(rw.rl.getSObject(ItemString).get('Non_Inventory__c') == false){ 	
                    	if( rw.skidList[i].Location__c == null || rw.rl.get('putAway_Location__c') == null ){
                    		
                    		throw new ReceivingDocumentServiceException('Please specify the putaway Location for line : '+(String)rw.rl.get('Name')+' as you are receiving quantity on that line!' );
                    	}
                    	}
                        
                        if( rw.rl.getSObject(ItemString).get('Non_Inventory__c') == false || rw.rl.getSObject(ItemString).get('Source__c') =='Outside Processing'  ){
                            SkidService2.checkRequiredAttributes( rw.skidList[i], rw.trackedAttributes, ' is required for line : '+rw.rl.get('Name'), null ) ;
    	                    
    	                    Date min = system.today()+rw.minimumShelfLife;
    	                    
    	                    if( rw.rl.getSObject(itemString).getSObject('Item_Attribute__r') != null && rw.rl.getSObject(itemString).getSObject('Item_Attribute__r').get('minimum_shelf_life_in_days__c') == true && rw.skidList[i].expiration_Date__c != null && (rw.skidList[i].expiration_Date__c < system.today()+rw.minimumShelfLife) ){
    	                    	
    	                    	throw new ReceivingDocumentServiceException('Expiration date is less than the minimum shelf life ( '+ min.format() +' ) required : ' + (String)rw.rl.get('Name'));                                    
    	                    }   
                            if( sourceDocument != 'Transfer Order'){
                                
                                Id itemId = rw.skidList[i].Item__c;
                                
                                if( sourceDocument == 'Purchase Order' && rw.rl.getSObject('Purchase_Order__r').get('Type__c') == 'SubContract'){
                                    
                                    rw.skidList[i].Item__c = (Id)rw.rl.getSObject('Item_Specification__r').get('Item__c');
                                }
                                SkidService2.populateLotNames(rw.skidList[i], (Id)rw.rl.get('Supplier__c'), lotMap, lotNames);
                                
                                rw.skidList[i].Item__c = itemId;
                            }
                            else{
                                SkidService2.populateLotNames(rw.skidList[i], null, lotMap, lotNames);
                                
                            }
                        }
                    }
                }
                SObject rl;
                if( sourceDocument == 'Receiving Document' && transitSkids != null){
                    rl = rw.rl.getSObject('Purchase_Order_Line__r');
    
                    if( rw.rl.getSObject('Purchase_Order__r').getSObject('FOB_Term__r') != null && rw.rl.getSObject('Purchase_Order__r').getSObject('FOB_Term__r').get('fob_point__c') == 'Origin' && transitSkids.get(rw.rl.id) == null ){
                        throw new ReceivingDocumentServiceException('In-Transit skids not found ');    
                    }
                }
                else if( sourceDocument != 'Receiving Document')
                    rl = rw.rl;
                    
                if(!totalQuantityMap.containsKey( rl.Id)) totalQuantityMap.put( rl.id , totalQuantity);
                else
                    totalQuantityMap.put(rl.id, totalQuantityMap.get(rl.id)+totalQuantity );    
                    
                if( totalQuantityMap.get(rl.id) > KSE.addQuantityToField( (Decimal)rl.get('Quantity_Still_Due__c'), (Decimal)rl.get('Overage_Quantity__c'))){
    
    				throw new ReceivingDocumentServiceException('Cannot receive quantity more than the quantity still due for:' + (String)rw.rl.get('Name'));                                    
                }
    
            }
            
            if( anyQuantityEntered == 0 ){
                	
                throw new ReceivingDocumentServiceException('No quantities have been entered to receive!');
                
            }
        }
        catch( Exception ex ){
    	    return (ex.getMessage());
    	}
        return null;
       
    }
    
    public static map<String, Integer> populateIcrMinimumShelfLife( set<Id> supplierIds ){
        
        map<String, Integer> icrKeys = new map<String, Integer>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Item_Cross_Reference__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Name','Active__c','Approval_Status__c','Item__c','Item__r.Name','Item__r.Approved_Supplier_Required__c','Supplier__c',
			'Ship_to_Facility__c','Consigned__c','Minimum_Shelf_Life_In_Days__c'
		});
		soql.setWhereClause('Supplier__c IN :supplierIds and Active__c = true and Approval_Status__c = \'Approved\' and Minimum_Shelf_Life_In_Days__c != null');

		for( Item_Cross_Reference__c icr : Database.query(soql.getQuery())){
      		if( icr.Ship_to_Facility__c == null ){
	      		icrKeys.put( icr.Supplier__c+','+icr.Item__c, Integer.valueOf(icr.Minimum_Shelf_Life_In_Days__c) );
	      	}
	      	else{
	      		icrKeys.put( icr.Supplier__c+','+icr.Item__c+','+icr.Ship_to_Facility__c, Integer.valueOf(icr.Minimum_Shelf_Life_In_Days__c) );
	      	}
	      	
	    }
	    
	    return icrKeys;
    }
    
    public static list<ReceivingWrapper> receivingDocumentGetWrapperRecords( Id headerId, String sourceDocument ){
        
        list<receivingWrapper> records = new list<receivingWrapper>();
        map<Id, SObject> rLines = new map<Id, SObject >();
        list<string> attributeFields = getAttributeFields();
        map<String, Integer> icrKeys = new map<String, Integer>();
        map<Id, SKID__c> fromSkids = new map<Id, SKID__c>();
        map<Id, List<Location__c> > locationsByHeader = new map<Id, List<Location__c>>();
        map<Id, Stock_Movement_Rule__c> matchedRules = new map<Id, Stock_Movement_Rule__c>();
        map<Id, Id> rlToPol = new map<Id, Id>();
        Set<Id> rlIds = new set<Id>();
        list<SObject> poLines = new list<SObject>();
        Savepoint sp = Database.setSavepoint();
        
        try{
            if( sourceDocument == 'Receiving Document')
                rLines = (map<Id,SObject>)ReceivingDocumentService.cachedReceiptLines(new set<Id>{headerId}, 'Status__c = \'Open\' and Purchase_Order_Line__r.Quantity_Still_Due__c > 0.0 and Purchase_Order__r.Approval_Status__c = \'Approved\' and Purchase_Order__r.Status__c = \'Open\'');
            else
                rLines = (map<Id,SObject>)ReceivingDocumentService.cachedPOLines(new set<Id>{headerId});
        
	        list<SObject> rdLineList = rLines.values();
	        if( rLines.values().size() > 0 ){
         
	           if( sourceDocument == 'Receiving Document'){ 		
    	            
        	       for (SObject obj : rLines.values()) {
        	            if (obj.getSObject('Purchase_Order__r').get('Status__c') != 'Open') {
        	                throw new ReceivingDocumentServiceException('Purchase Order is not Open: ' +obj.getSObject('Purchase_Order__r').get('Name'));
        	            }
        	            
        	            if (obj.getSObject('Purchase_Order__r').get('Approval_Status__c') != 'Approved') {
        	                throw new ReceivingDocumentServiceException('Purchase Order is not Approved: ' +obj.getSObject('Purchase_Order__r').get('Name'));
        	            }
        	            
        	            if (obj.getSObject('Purchase_Order__r').get('Status__c') != 'Open') {
        	                throw new ReceivingDocumentServiceException('Purchase Order Line is not Open: ' +obj.getSObject('Purchase_Order__r').get('Name'));
        	            }
        	            
        	            rlToPol.put( obj.id, (Id)obj.get('Purchase_Order_Line__c') );
            		    rlIds.add( (Id)obj.get('Purchase_Order_Line__c') );	
        	            poLines.add( obj.getSObject('Purchase_Order_Line__r'));
        	        }
                    locationsByHeader = SkidService2.locationsFromStockMovementRules( poLines, 'Putaway', 'Purchase Order', matchedRules);
	           }
	           else{
	               rlIds = rLines.keySet();
	               locationsByHeader = SkidService2.locationsFromStockMovementRules( rdLineList, 'Putaway', 'Purchase Order', matchedRules);
                    for (Purchase_Order_Line__c obj : (List<Purchase_Order_Line__c>) rLines.values()) {
                        if (obj.getSObject('Purchase_Order__r').get('Type__c') == PurchaseOrderService.PO_TYPE_DROP_SHIP
                            && obj.Sales_Order_Line__c != null && obj.Sales_Order_Line__r.Ship_From_Location__r != null) {
                                locationsByHeader.put(obj.Id, new List<Location__c>{obj.Sales_Order_Line__r.Ship_From_Location__r});
	           }
                    }
                    
               }

                Id supplierId = (Id)rLines.values()[0].getSObject('Purchase_Order__r').get('Supplier__c');
                
                icrKeys = ReceivingDocumentService.populateIcrMinimumShelfLife( new set<Id>{ supplierId } );
                
                fromSkids = (map<Id,SKID__c>)ReceivingDocumentService.cachedFromSkids(rlIds);      
                     
                Id companyId = (Id)rLines.values()[0].get('Company__c');
                
                
                //throw new receivingDocumentServiceException(String.valueOf(rdLineList[0].getSObjects('SKIDs__r')));
                

                for( Integer i = 0; i< rdLineList.size() ; i++ ){
                    
                    ReceivingDocumentService.receivingWrapper rw;
                    Id polId;
                    Location__c loc;
                    
                    if( sourceDocument == 'Receiving Document'){
                        polId = rlToPol.get(rdLineList[i].id);
                        if( locationsByHeader.containsKey((Id)rdLineList[i].get('Purchase_Order_Line__c')) && locationsByHeader.get((Id)rdLineList[i].get('Purchase_Order_Line__c')).size() > 0 )
                            loc =locationsByHeader.get((Id)rdLineList[i].get('Purchase_Order_Line__c'))[0];
                            
                        rw = new ReceivingDocumentService.receivingWrapper( rdLineList[i] , i, fromSkids.get( polId ), loc, attributeFields, sourceDocument );
                    }
                    else{
                        polId = rdLineList[i].id;
                        if( locationsByHeader.containsKey((Id)rdLineList[i].id) && locationsByHeader.get((Id)rdLineList[i].id).size() > 0 )
                            loc =locationsByHeader.get((Id)rdLineList[i].id)[0];
                            
                        rw = new ReceivingDocumentService.receivingWrapper( rdLineList[i] , i, fromSkids.get( polId ), loc, attributeFields, sourceDocument );
                    }

                    
                    calculateMinimumShelfLife( rw, sourceDocument, icrKeys, supplierId);            	
	                
                    records.add( rw );
                }

            }
            else{
                throw new ReceivingDocumentServiceException(sourceDocument+' has no lines to be received.');
            }
            return records;
        }
        catch(Exception ex ){
            Database.Rollback(sp);
            throw ex;
        }
    }
    
    public static void calculateMinimumShelfLife( receivingWrapper rw, String sourceDocument, map<String, Integer> icrKeys, Id supplierId ){
        
        SObject pol;
        String itemString;
        
        if( sourceDocument == 'Transfer Order'){
            itemString = 'Receiving_Item';
        }
        else{
            itemString = 'Item';
        }
        
        if( sourceDocument == 'Receiving Document')
            pol = rw.rl.getSObject('Purchase_Order_Line__r');
        else
            pol = rw.rl;

        if( sourceDocument != 'Transfer Order' && icrKeys.containsKey( supplierId+','+rw.rl.get(itemString+'__c')+','+pol.get('Delivery_Facility__c') ) )
        	rw.minimumShelfLife = icrKeys.get(supplierId+','+rw.rl.get(itemString+'__c')+','+pol.get('Delivery_Facility__c'));
        else if( icrKeys.containsKey( supplierId+','+rw.rl.get(itemString+'__c') ) )
        	rw.minimumShelfLife = icrKeys.get(supplierId+','+rw.rl.get(itemString+'__c'));	
        else if( rw.rl.getSObject(itemString+'__r').getSObject('Class__r') != null && rw.rl.getSObject(itemString+'__r').getSObject('Class__r').get('Minimum_Shelf_Life_In_Days__c') != null )
        	rw.minimumShelfLife = Integer.valueOf(rw.rl.getSObject(itemString+'__r').getSObject('Class__r').get('Minimum_Shelf_Life_In_Days__c'));
		else
			rw.minimumShelfLife = 0;    
    }
    
    public static List<String> getAttributeFields() {
        List<String> attributeFields = new List<String>();
        
        attributeFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c') );
        
        return attributeFields; 
    }
    
    public static void populateBeforePutawayRD(List<receivingWrapper> rlWrapperList, list<SKID__c> skidsForService, Map<Id,List<Inventory_Transaction__c>> itMap,
                        map<Id, Id> uniqueLocationMap, list<SObject> polsForUpdate, map<String, Lot__c > createdLotMap, SObject rdRec, map<Id,SKID__c> transitSkids,Map<Id,sObject> sourceDocs){
        Map<String, Schema.SObjectField> fieldMap = SchemaUtil.getInstance().getFieldsMap( 'Inventory_Transaction__c' );
        list<string> attributeFields = ReceivingDocumentService.getAttributeFields();
        list<String> attributesForService = new list<String>();
        map<Id, Purchase_Order_Line__c> polMap = new map<Id, Purchase_Order_Line__c>();
        list<SKID__c> delTransitSkids = new list<SKID__c>();
        list<SKID__c> updateTransitSkids = new list<SKID__c>();
        map<Id, Receipt_Line__c> receiptLines = new map<Id, Receipt_Line__c>(); //poLine Id is the key to match it with IT's
        
        attributesForService.addAll( SkidService2.attributesForPutaway( attributeFields ) );
        
        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        for( ReceivingDocumentService.receivingWrapper rw : rlWrapperList ){
        	itemIds.add((ID) rw.rl.get('Item__c'));
        	facilityIds.add((ID) rw.rl.get('Facility__c'));
        }

        for( ReceivingDocumentService.receivingWrapper rw : rlWrapperList ){
            Double stdCost = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,(Id) rw.rl.get('Company__c'),(Id) rw.rl.get('Facility__c'),System.Now(),(Id) rw.rl.get('Item__c'));
            
            Decimal totalReceivedPerLine = 0;
            
            if( !polMap.containsKey( (Id)rw.rl.get('Purchase_Order_Line__c') )){
                polMap.put( (Id)rw.rl.get('Purchase_Order_Line__c'), (Purchase_Order_Line__c)rw.rl.getSObject('Purchase_Order_Line__r') );
            }
            
            uniqueLocationMap.put( (Id)rw.rl.get('Putaway_Location__c'), (Id)rw.rl.get('Putaway_Location__c') );
            
            for( Integer i = 0; i < rw.skidList.size() ; i ++ ){
                
                if( rw.skidList[i].Quantity__c != null && rw.skidList[i].Quantity__c > 0  ){
                    
                    if( rw.skidList[i].Lot_Number__c != null && (rw.rl.getSObject('Item__r').get('Non_Inventory__c') == false || rw.rl.getSObject('Item__r').get('Source__c') =='Outside Processing' ) ){
                        String uniqueString = SkidService2.lotUniqueKey(rw.skidList[i], (Id)rw.rl.get('Supplier__c'));              
                        
                        rw.skidList[i].Lot__c = createdLotMap.get( uniqueString ).id;   // this map should always contain the unique string and the created lot
                        // as we have already created the ones that didnt exist. 
                        rw.skidList[i].Lot_Number__c = createdLotMap.get( uniqueString ).Name;
                    }
                    rw.rl.put('Quantity_Received__c', KSE.addQuantityToField((Decimal)rw.rl.get('Quantity_Received__c') , rw.skidList[i].Quantity__c));
                    totalReceivedPerLine += rw.skidList[i].Quantity__c;
                    if( i > 0 ){
                        
                        rw.itList.add( createInventoryTransaction( rw.skidList[i], rw, rdRec.Id, 'Receiving Document' ) );
                        
                    }
                    
                    for (String attribute:attributesForService) {
                        if (attribute == 'Facility2__c') {
                            rw.itList[i].put('To_Facility__c',rw.skidList[i].get(attribute));
                        } else if (attribute == 'Location__c') {
                            rw.itList[i].put('To_Location__c' ,rw.skidList[i].get(attribute));
                        } else if (attribute != 'Purchase_Order_Line__c') {
                            if (fieldMap.get(attribute.toLowerCase()).getDescribe().getType() == Schema.DisplayType.Boolean && rw.skidList[i].get(attribute) == null) {
                                rw.itList[i].put(attribute,false);
                            } else {
                                rw.itList[i].put(attribute,rw.skidList[i].get(attribute));
                            }
                        }    
                    }
                    
                    if( rw.itList[i].Purchase_Order_Line__c != null ) rw.itList[i].putSObject('Purchase_Order_Line__r' , rw.rl.getSObject('Purchase_Order_Line__r'));
                    
                    if(rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c')==null || (decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c')==0)
                    {   
                        rw.rl.getSObject('Purchase_Order_Line__r').put('Quantity_To_Stock__c', ((decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Order_Quantity__c') * KSE.getConversionFactor(rw.rl.getSObject('Purchase_Order_Line__r'))).setscale(6,System.RoundingMode.HALF_UP));
                    }
                    rw.skidList[i].Quantity__c = (rw.skidList[i].Quantity__c * (KSE.getConversionFactorFromQuantity((decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c'),(decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Order_Quantity__c')))).setscale(6,System.RoundingMode.HALF_UP);//KSE.getConversionFactor(rw.rl.getSObject('Purchase_Order_Line__r'));
                    rw.itList[i].Quantity__c = rw.skidList[i].Quantity__c;
                    
                    if( transitSkids.get(rw.rl.id) != null ){
                        
                        SKID__c delSkid = (SKID__c)transitSkids.get(rw.rl.id);
                        delSkid.Quantity__c -= rw.itList[i].Quantity__c;
                        if( delSkid.Quantity__c <= 0 )
                            delTransitSkids.add( delSkid );
                        else
                            updateTransitSkids.add( delSkid );
                    }
                    
                }
                else{
                    rw.skidList.remove( i );
                }
            }
            
            if( (Decimal)rw.rl.get('Quantity_Received__c') == 0 )
                continue;

            if( polMap.get((Id)rw.rl.get('Purchase_Order_Line__c')).get('Consigned__c') == false )
                rw.rl.put('Uninvoiced_Quantity__c' , rw.rl.get('Quantity_Received__c')) ;   
            else
                rw.rl.put('Line_Type__c' , 'Consigned');
            
            if( (Decimal)rw.rl.get('Quantity_Declared__c') <= KSE.subtractDecimals( (Decimal)rw.rl.get('Quantity_Received__c') , (Decimal)rw.rl.get('Quantity_Returned_To_Supplier__c') ) ){
                rw.rl.put('Status__c' , 'Closed');
            }    

            polMap.get((Id)rw.rl.get('Purchase_Order_Line__c')).Quantity_Received__c =
                KSE.addQuantityToField((Decimal)polMap.get((Id)rw.rl.get('Purchase_Order_Line__c')).get('Quantity_Received__c'),(Decimal)totalReceivedPerLine );    
             
            
            if(rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c')==null || (decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c')==0)
            {   
                rw.rl.getSObject('Purchase_Order_Line__r').put('Quantity_To_Stock__c', ((decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Order_Quantity__c') * KSE.getConversionFactor(rw.rl.getSObject('Purchase_Order_Line__r'))).setscale(6,System.RoundingMode.HALF_UP));
            }
                    
             
            rw.rl.put('Extended_Cost__c' , (stdCost * (Decimal)rw.rl.get('Quantity_Received__c') * (KSE.getConversionFactorFromQuantity((decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c'),(decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Order_Quantity__c')))).setscale(6,System.RoundingMode.HALF_UP));          //KSE.getConversionFactor(rw.rl.getSObject('Purchase_Order_Line__r')));
            rw.rl.put('Quantity_To_Stock__c' , ((Decimal)rw.rl.get('Quantity_Received__c') * (KSE.getConversionFactorFromQuantity((decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Quantity_To_Stock__c'),(decimal)rw.rl.getSObject('Purchase_Order_Line__r').get('Order_Quantity__c')))).setscale(6,System.RoundingMode.HALF_UP));   
            polMap.get((Id)rw.rl.get('Purchase_Order_Line__c')).put('Date_Last_Changed__c', system.today()); 
            rw.rl.put('unit_price__c', (Decimal)rw.rl.get('unit_price__c'));

            if( rw.rl.getSObject('Item__r').get('Non_Inventory__c') == false ){
                skidsForService.addAll( rw.skidList );
                sourceDocs.put((Id)rw.rl.get('Receiving_Document__c'),new Receiving_Document__c(Company__c = (Id)rw.rl.get('Company__c')));
                if (!itMap.containsKey((Id)rw.rl.get('Receiving_Document__c')))
                    itMap.put((Id)rw.rl.get('Receiving_Document__c'),new List<Inventory_Transaction__c>());
                itMap.get((Id)rw.rl.get('Receiving_Document__c')).addAll(rw.itList);   
            }
            receiptLines.put( rw.rl.id, (Receipt_Line__c)rw.rl );
        }
        polsForUpdate.addAll((List<SObject>)polMap.values()); 
        
        DML.updateAsUser( receiptLines.values() );
        DML.updateAsSystem( updateTransitSkids );
        DML.deleteAsSystem( delTransitSkids );
    }
    
    
    public static void populateBeforePutawayPO(List<receivingWrapper> rlWrapperList, list<SKID__c> skidsForService, Map<Id,List<Inventory_Transaction__c>> itMap,
                                               map<Id, Id> uniqueLocationMap, list<SObject> polsForUpdate, map<String, Lot__c > createdLotMap, SObject headerRec,
                                               String sourceFieldName,Map<Id,sObject> sourceDocs,List<String> attributes,Map<String,String> keyMap) {
        Map<String, Schema.SObjectField> fieldMap = SchemaUtil.getInstance().getFieldsMap( 'Inventory_Transaction__c' );
        map<Id, Receipt_Line__c> receiptLines = new map<Id, Receipt_Line__c>(); //poLine Id is the key to match it with IT's
        String itemString = 'Item__r';
        Receiving_Document__c rd;
        if( sourceFieldName == 'Order_Line__c' ){
          itemString = 'Receiving_Item__r';  
          rd = new Receiving_Document__c( Company__c = (Id)headerRec.get('Receiving_Company__c'), Date_Created__c = system.today(), Date_Received__c = system.now() ,
                                    Type__c = 'Transfer Order Receipt', Currency__c = (Id)headerRec.get('currency__c'), Finalized__c = false, Status__c = 'Closed' );
          
        } else {
            rd = new Receiving_Document__c( Company__c = (Id)headerRec.get('Company__c'), Supplier__c = (Id)headerRec.get('Supplier__c'), Date_Created__c = system.today(), 
                                            Date_Received__c = system.now(), Type__c = 'Purchase Order Receipt', Currency__c = (Id)headerRec.get('currency__c'), Finalized__c = false, 
                                            Status__c = 'Closed' );
            if  (sourceFieldName == 'Purchase_Order_Line__c' && headerRec.get('Type__c') == PurchaseOrderService.PO_TYPE_DROP_SHIP) {
                rd.Transaction_Type__c = RD_TRANSACTION_TYPE_LOGICAL;
        }
        }
        
        DML.insertAsUser( rd);                                      
        
        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        for( receivingWrapper rw : rlWrapperList ){
        	itemIds.add(rw.receipt.Item__c);
        	facilityIds.add(rw.receipt.Facility__c);
        }
        
        
        for( receivingWrapper rw : rlWrapperList ){
        	Double stdCost = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,rw.receipt.Company__c,rw.receipt.Facility__c,System.Now(),rw.receipt.Item__c);
            Decimal conversionFactor = 1;
            Id supplierId= null;
            if( sourceFieldName == 'Purchase_Order_Line__c'){
              //conversionFactor = KSE.getConversionFactor(rw.rl);  
              supplierId = (Id)rw.rl.get('Supplier__c');
            }
            rw.receipt.Quantity_Received__c = 0;
            
            uniqueLocationMap.put( (Id)rw.rl.get('Putaway_Location__c'), (Id)rw.rl.get('Putaway_Location__c') );
            Integer i = 0;
			while (i < rw.skidList.size()){
				
				if(rw.receipt.Shipment_Line__c==null)
                {
                	rw.receipt.Shipment_Line__c =  rw.skidList[i].Shipment_Line__r.Id; 
                }
                
                if( rw.skidList[i].Quantity__c != null && rw.skidList[i].Quantity__c > 0  ){
                    
                    if( rw.skidList[i].Lot_Number__c != null && (rw.rl.getSObject(ItemString).get('Non_Inventory__c') == false || rw.rl.getSObject(ItemString).get('Source__c') =='Outside Processing' ) ){
                        
                        Id itemId = rw.skidList[i].Item__c;
                                
                        if( sourceFieldName == 'Purchase_Order_Line__c' && headerRec.get('Type__c') == 'SubContract'){
                            rw.skidList[i].Item__c = (Id)rw.rl.getSObject('Item_Specification__r').get('Item__c');
                        }
                        
                        String uniqueString = SkidService2.lotUniqueKey(rw.skidList[i],supplierId );              
                        
                        rw.skidList[i].Item__c = itemId;
                        
                        rw.skidList[i].Lot__c = createdLotMap.get( uniqueString ).id;   // this map should always contain the unique string and the created lot
                        // as we have already created the ones that didnt exist. 
                        rw.skidList[i].Lot_Number__c = createdLotMap.get( uniqueString ).Name;
                       
                    }
                    rw.receipt.Quantity_Received__c += rw.skidList[i].Quantity__c;
                    
                    if( sourceFieldName == 'Purchase_Order_Line__c' && i > 0 ){
                        
                        rw.itList.add( createInventoryTransaction( rw.skidList[i], rw, headerRec.Id, 'Purchase Order' ) );
                    }
                    
                    for (String attribute:attributes) {
                        if (attribute == 'Facility2__c') {
                            rw.itList[i].put('To_Facility__c',rw.skidList[i].get(attribute));
                        } else if (attribute == 'Location__c') {
                            rw.itList[i].put('To_Location__c' ,rw.skidList[i].get(attribute));
                        } else if (attribute != sourceFieldName) {
                            if (fieldMap.get(attribute.toLowerCase()).getDescribe().getType() == Schema.DisplayType.Boolean && rw.skidList[i].get(attribute) == null) {
                                rw.itList[i].put(attribute,false);
                            } else {
                                rw.itList[i].put(attribute,rw.skidList[i].get(attribute));
                            }
                        }    
                    }
                    
                    if( rw.itList[i].Purchase_Order_Line__c != null ) {
                        rw.itList[i].Purchase_Order_Line__r = (Purchase_Order_Line__c)rw.rl;
                        rw.itList[i].Sales_Order_Line__c = (Id) rw.rl.get('Sales_Order_Line__c');
                    	rw.itList[i].Sales_Order_Line__r = (Sales_Order_Line__c)rw.rl.getSObject('Sales_Order_Line__r');
                    	rw.skidList[i].Quantity__c = (rw.skidList[i].Quantity__c * (KSE.getConversionFactorFromQuantity((decimal)rw.rl.get('Quantity_To_Stock__c'),(decimal)rw.rl.get('Order_Quantity__c')))).setscale(6,System.RoundingMode.HALF_UP);//conversionFactor;
                    	rw.itList[i].Quantity__c = rw.skidList[i].Quantity__c;
                    }
                    else
                    {
                    	rw.skidList[i].Quantity__c = rw.skidList[i].Quantity__c;//conversionFactor;
                    	rw.itList[i].Quantity__c = rw.skidList[i].Quantity__c;
                    }
                    i++;
                }
                else{
                    rw.skidList.remove( i );
                    if( sourceFieldName == 'Order_Line__c'){
                        rw.itList.remove( i );
                    }
                }
            }
            if( rw.receipt.Quantity_Received__c == 0 )
                continue;

            rw.receipt.Receiving_Document__c = rd.id;
            rw.receipt.Status__c = 'Closed'; //KNDY 3774 Changing the Receipt Line status to 'Closed'. Also changing the RD status to closed above.                
            //PTP-89 Ability to edit putaway location in receipt screen
            rw.receipt.putaway_location__c = (id)rw.rl.get('Putaway_Location__c');           
            
            if( sourceFieldName == 'Purchase_Order_Line__c'){
                if( rw.rl.get('Consigned__c') == false )
                    rw.receipt.Uninvoiced_Quantity__c = rw.receipt.Quantity_Received__c ;   
                else
                    rw.receipt.Line_Type__c = 'Consigned';
                
                rw.receipt.unit_price__c = (Decimal)rw.rl.get('unit_price__c');    
                rw.rl.put('Date_Last_Changed__c' , system.today()); 
                if(rw.rl.get('Short_Close__c') == true) {
                   rw.rl.put('Status__c','Closed');
                }
            
                
               	if( rw.rl.get('Quantity_Received__c') == null ) rw.rl.put('Quantity_Received__c', 0);
		            rw.rl.put('Quantity_Received__c', (Decimal)rw.rl.get('Quantity_Received__c') + rw.receipt.Quantity_Received__c) ;
		            
		            
	            if(rw.rl.get('Quantity_To_Stock__c')==null || (decimal)rw.rl.get('Quantity_To_Stock__c')==0)
	            {   
	                rw.rl.put('Quantity_To_Stock__c', ((decimal)rw.rl.get('Order_Quantity__c') * KSE.getConversionFactor(rw.rl)).setscale(6,System.RoundingMode.HALF_UP));
	            }
	            rw.receipt.Extended_Cost__c = (stdCost * rw.receipt.Quantity_Received__c * (KSE.getConversionFactorFromQuantity((decimal)rw.rl.get('Quantity_To_Stock__c'),(decimal)rw.rl.get('Order_Quantity__c')))).setscale(6,System.RoundingMode.HALF_UP);//conversionFactor;
	            rw.receipt.Quantity_To_Stock__c = (rw.receipt.Quantity_Received__c * (KSE.getConversionFactorFromQuantity((decimal)rw.rl.get('Quantity_To_Stock__c'),(decimal)rw.rl.get('Order_Quantity__c')))).setscale(6,System.RoundingMode.HALF_UP);//conversionFactor;
	            
                
            }
            else{
            	if( rw.rl.get('Quantity_Received__c') == null ) rw.rl.put('Quantity_Received__c', 0);
		            rw.rl.put('Quantity_Received__c', (Decimal)rw.rl.get('Quantity_Received__c') + rw.receipt.Quantity_Received__c) ;
		         
            	rw.receipt.Extended_Cost__c = stdCost * rw.receipt.Quantity_Received__c;
	            rw.receipt.Uninvoiced_Quantity__c = rw.receipt.Quantity_Received__c ;
            }
            
            polsForUpdate.add( rw.rl );    
            if( rw.rl.getSObject(itemString).get('Non_Inventory__c') == false ){
                skidsForService.addAll( rw.skidList );
                String parentRel;
                String companyRel;
                if (sourceFieldName == 'Purchase_Order_Line__c') {
                    parentRel = 'Purchase_Order__c';
                    companyRel = 'Company__c';
                } else if (sourceFieldName == 'Order_Line__c') {
                    parentRel = 'Order__c';
                    companyRel = 'Receiving_Company__c';
                }
                sourceDocs.put((Id)rw.rl.get(parentRel),new Purchase_Order__c(Company__c = (Id)rw.rl.get(companyRel)));
                if(sourceFieldName == 'Order_Line__c'){
                	sourceDocs.put((Id)rw.rl.get(parentRel),new Purchase_Order__c(Company__c = (Id)rw.rl.get(companyRel), Currency__c = (Id)rw.rl.getSObject('Order__r').get('Currency__c')));
                }
                else{
                	sourceDocs.put((Id)rw.rl.get(parentRel),new Purchase_Order__c(Company__c = (Id)rw.rl.get(companyRel)));
                }
                if (!itMap.containsKey((Id)rw.rl.get(parentRel)))
                    itMap.put((Id)rw.rl.get(parentRel),new List<Inventory_Transaction__c>());
                itMap.get((Id)rw.rl.get(parentRel)).addAll(rw.itList);
            }
            receiptLines.put( rw.rl.id, rw.receipt );
        }
        
        DML.insertAsUser( receiptLines.values() );

        for (receivingWrapper rw:rlWrapperList) {
            Integer i = 0;
            while (i < rw.skidList.size()) {
                SKID__c skid = rw.skidList[i];
                Inventory_Transaction__c it = rw.itList[i];

                it.Receipt_Line__c = receiptLines.get((Id)it.get(sourceFieldName)).Id;
                if (sourceFieldName == 'Purchase_Order_Line__c' && !it.Purchase_Order_Line__r.Consigned__c && (String)headerRec.get('Type__c') != PurchaseOrderService.PO_TYPE_DROP_SHIP) {
                    it.Purchase_Order_Line__c = null;
                }

                keyMap.put(SkidService2.generateKeyForIT(it,attributes),SkidService2.generateKeyForSkid(skid,attributes,null,null));

                i++;
            }
        }
        
        rd.finalized__c = true;
        DML.updateAsUser(rd);
    }
    
    
   
    
    public static Receiving_Document__c getReceivingDocumentRecord(Id rdId) {

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Receiving_Document__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Status__c','Type__c','Supplier__c','Company__c','transaction_date__c','currency__c','finalized__c'
		});
		soql.setWhereClause('Id = :rdId');
		soql.setLimit(1);

		Receiving_Document__c rdRec = Database.query(soql.getQuery());
        
        return rdRec;
    }
    
    
    public static Purchase_Order__c getPurchaseOrderRecord(Id poId) {

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Purchase_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Status__c','Type__c','Approval_Status__c','Supplier__c','Company__c','FOB_Term__r.FOB_Point__c','Currency__c'
		});
		soql.setWhereClause('Id = :poId');
		soql.setLimit(1);
		
		SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Receipt_Lines__r');
		childRel1.addFields(new set<string>{
			'id'
		});
		childRel1.setWhereClause('Status__c != \'Closed\' and Status__c != \'Cancelled\' and Status__c != \'Void\'');
		soql.addChildRelationship(childRel1);
		
		SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'ASN_Lines__r');
		childRel2.addFields(new set<string>{
			'id'
		});
		childRel2.setWhereClause('Status__c != \'Close\' and Status__c != \'Cancel\'');
		soql.addChildRelationship(childRel2);

		Purchase_Order__c poRec = Database.query(soql.getQuery());
        
        return poRec;
    }
    
    public static SObject getOrderRecord(Id oId) {

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Status__c','Receiving_Company__c','Currency__c'
		});
		soql.setWhereClause('Id = :oId');
		soql.setLimit(1);

		SObject oRec = Database.query(soql.getQuery());
        
        return oRec;
    }
    
    public static Inventory_Transaction__c createInventoryTransaction(SKID__c sk , ReceivingDocumentService.ReceivingWrapper rw, Id headerId, String sourceDocument ){
        map<Id, SKID__c> fromSkids = new map<Id, SKID__c>();
        Inventory_Transaction__c it;
        
        if( sourceDocument == 'Receiving Document'){
            
            map<Id, Receipt_Line__c> rdLines = new map<Id, Receipt_Line__c >();
            set<Id> rlIds = new set<Id>();
            
            rdLines = (map<Id,Receipt_Line__c>)ReceivingDocumentService.cachedReceiptLines(new set<Id>{headerId}, 'Status__c = \'Open\' and Purchase_Order_Line__r.Quantity_Still_Due__c > 0.0 and Purchase_Order__r.Approval_Status__c = \'Approved\' and Purchase_Order__r.Status__c = \'Open\' ');
        
            if( rdLines.values().size() > 0 ){
                	
            	for( Receipt_Line__c rl : rdLines.values() ){
            		rlIds.add( rl.Purchase_Order_Line__c );	
            	}
            	fromSkids = (map<Id,SKID__c>)ReceivingDocumentService.cachedFromSkids(rlIds);
            }
        
            SKID__c fromSkid = fromSkids.get( (Id)rw.rl.get('Purchase_Order_Line__c') );
            
            //it = SkidService2.createIT(fromSkid, (Id)rw.rl.get('item__c'), 'Purchase Order Receipt', (Id)rw.rl.get('purchase_order_line__c'), null,null, (Id)rw.rl.get('Putaway_Location__c'), null, null );
            it = SkidService3.createInventoryTransaction(rw.rl, 'Purchase Order Receipt', fromSkid.Quantity__c, fromSkid, null, null ); 
            
            if( rw.rl.getSObject('purchase_order_line__r').get('Consigned__c') != true ){
                it.Purchase_Order_Line__c = null;
            }else{
            	it.Purchase_Order_Line__c = (Id) rw.rl.get('Purchase_Order_Line__c');
            }
        }
        else{
            map<Id, Purchase_Order_Line__c> poLines = new map<Id, Purchase_Order_Line__c >();
            
            poLines = (map<Id,Purchase_Order_Line__c>)ReceivingDocumentService.cachedPOLines(new set<Id>{headerId});
            
            if( poLines.values().size() > 0 ){          
                Set<Id> polIds = poLines.keySet();
                
                fromSkids = (map<Id,SKID__c>)ReceivingDocumentService.cachedFromSkids(polIds);
            }
            
            SKID__c fromSkid = fromSkids.get( rw.rl.id );
            String transactionType = '';
            
            if (rw.rl.getSObject('Purchase_Order__r').get('Type__c') == PurchaseOrderService.PO_TYPE_DROP_SHIP) {
                //it = SkidService2.createIT(fromSkid, (Id)rw.rl.get('item__c'), InventoryTransactionService.LOGICAL_PURCHASE_ORDER_RECEIPT, rw.rl.id, null,null,  (Id)rw.rl.get('Putaway_Location__c'), null, null );
                transactionType = InventoryTransactionService.LOGICAL_PURCHASE_ORDER_RECEIPT;
            } else {
            	//it = SkidService2.createIT(fromSkid, (Id)rw.rl.get('item__c'), 'Purchase Order Receipt', rw.rl.id, null,null, (Id)rw.rl.get('Putaway_Location__c'), null, null );
            	transactionType = 'Purchase Order Receipt';
            }
            
            it = SkidService3.createInventoryTransaction(rw.rl, transactionType, fromSkid.Quantity__c, fromSkid, null, null );

        }
        return it;      
    
    }
    
    public static String Receive(Id headerId, List<receivingWrapper> rlWrapperList, String sourceDocument){
        Map<String,String> keyMap = new Map<String,String>();

        list<SKID__c> skidsForService = new list<SKID__c>();
        Map<Id,sObject> sourceDocs = new Map<Id,sObject>();
        Map<Id,List<Inventory_Transaction__c>> itMap = new Map<Id,List<Inventory_Transaction__c>>();
        set<Id> uniqueLocationsIds = new set<id>();
        map<Id, Id> uniqueLocationMap = new map<id, id>();
        map<String, SKID__c > toSkidsMap = new map<String, SKID__c >();
        map<String, SKID__c > toSkidsNegativeMap = new map<String, SKID__c >();
        List<ID> deletableSkids = new List<ID>();
        list<sObject> polsForUpdate = new list<sObject>();
        map<String, Lot__c > lotMap = new map <String, Lot__c >();
        map<String, Lot__c > createdLotMap = new map <String, Lot__c >();
        Set<String> lotNames = new Set<String>();
        String error;
        map<Id, SKID__c> transitSkids = new map<Id, SKID__c>();
        list<String> attributesForService = new list<String>();
        SObject headerRecord;
		Map<id,sObject> orderLines=new Map<id,sObject>();
		
        list<String> attributesForServiceForNegativeSkids = new list<String>();
        attributesForService.addAll( SkidService2.attributesForPutaway( getAttributeFields() ) );
        attributesForServiceForNegativeSkids = attributesForService.clone();
        attributesForServiceForNegativeSkids.add('Order_Line__c');
        attributesForServiceForNegativeSkids.add('Shipment_Line__c');
		
        
		Savepoint sp = Database.setSavepoint();
        
        try{         
        
            list<string> attributeFields = ReceivingDocumentService.getAttributeFields();
            
            //Querying transit skids here because Kendo cannot handle records that have sub query results at this point.
            if( sourceDocument == 'Receiving Document'){
                set<Id> rlIds = new set<Id>();
                for( receivingWrapper rw : rlWrapperList ){
                    rlIds.add( rw.rl.id );
                }
                
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('Skid__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','Company__c','Quantity__c','Shipment_Line__c','Type__c','Receipt_Line__c', 'Item__r.Packaging_UOM__c'
				});
				soql.setWhereClause('type__c = \'In-Transit\' and Receipt_Line__c IN :rlIds');
			
				for( SKID__c transitSkid : Database.query(soql.getQuery())){
                    transitSkids.put( transitSkid.Receipt_Line__c, transitSkid );
                }
                error = checkUserErrors( rlWrapperList, lotMap, lotNames, sourceDocument, transitSkids );// checks user errors and also collects some lot attributes for use in the createLots method.    
            }
            else{
                error = checkUserErrors( rlWrapperList, lotMap, lotNames, sourceDocument, null );// checks user errors and also collects some lot attributes for use in the createLots method.
            }
            
            if( error != null ) { 
                return error;
            }
                
            createdLotMap = SkidService2.createLots( lotMap, lotNames );    //dynamically create lots that do not exist based on uniqueness
            List<Skid__c> negativeSkidsforService = new list<skid__c>();
            if( sourceDocument == 'Receiving Document'){

                headerRecord = (SObject)getReceivingDocumentRecord(headerId);
                populateBeforePutawayRD(rlWrapperList, skidsForService, itMap,uniqueLocationMap, polsForUpdate, createdLotMap, headerRecord, transitSkids,sourceDocs); // populate the uncommited skid and inventory transaction objects with the user supplied attributes
            }
            else if( sourceDocument == 'Purchase Order'){
                headerRecord = (SObject)getPurchaseOrderRecord(headerId);
                populateBeforePutawayPO(rlWrapperList, skidsForService, itMap,uniqueLocationMap, polsForUpdate, createdLotMap, headerRecord, 'Purchase_Order_Line__c',sourceDocs,attributesForService,keyMap); // populate the uncommited skid and inventory transaction objects with the user supplied attributes
            
                if (headerRecord.get('Type__c') == PurchaseOrderService.PO_TYPE_DROP_SHIP) {
                    for (Skid__c sk : skidsForService){
                        sk.Type__c = SkidService2.SKID_TYPE_DROP_SHIP;
            		}
            
		            List<Inventory_Transaction__c> allITs = new List<Inventory_Transaction__c>();
		            
		            for (List<Inventory_Transaction__c> its:itMap.values()){
		                allITs.addAll(its);
		            }
                
                    toSkidsMap = SkidService2.putAwayService(skidsForService, attributesForService, uniqueLocationMap.keySet(), SkidService2.SKID_TYPE_DROP_SHIP, false ); // merges or creates location (To) skids ( i.e putaway )
                    
                    List<Inventory_Transaction__c> itList = allITs.clone();
                    for (Inventory_Transaction__c it : itList){
                        if (it.Type__c == InventoryTransactionService.LOGICAL_PURCHASE_ORDER_RECEIPT){
                            Inventory_Transaction__c itNew = new Inventory_Transaction__c();
                            itNew = it.clone(true, true);
                            itNew.From_Facility__c = it.To_Facility__c;
                            itNew.From_Location__c = it.To_Location__c;
                            itNew.To_Facility__c = it.From_Facility__c;
                            itNew.To_Location__c = it.From_Location__c;
                            itNew.Type__c = InventoryTransactionService.LOGICAL_SALES_ORDER_SHIPMENT;
                            itNew.Company__c = it.Sales_Order_Line__r.Company__c;
                            
                            Id sourceDocId = it.Sales_Order_Line__r.Sales_Order__c;
                            sourceDocs.put(sourceDocId,new Sales_Order__c(Company__c = it.Sales_Order_Line__r.Company__c));
                            
                            if (!itMap.containsKey(sourceDocId))
                                itMap.put(sourceDocId,new List<Inventory_Transaction__c>());
                            itMap.get(sourceDocId).add(itNew);
                        }
                    } 

                    for(SKID__c sk: skidsForService) {
                        SKID__c skNegative = sk.clone(false,true);
                        skNegative.Type__c = SkidService2.SKID_TYPE_DROP_SHIP;
                        skNegative.Quantity__c = skNegative.Quantity__c*-1;
                        negativeSkidsforService.add(skNegative);
                	}

                    toSkidsNegativeMap = SkidService2.putAwayService(negativeSkidsforService, attributesForServiceForNegativeSkids, uniqueLocationsIds, SkidService2.SKID_TYPE_DROP_SHIP, false ); // merges or creates location (To) skids ( i.e putaway )
	            }
			}
            else{
                headerRecord = (SObject)getOrderRecord(headerId);
                populateBeforePutawayPO(rlWrapperList, skidsForService, itMap,uniqueLocationMap, polsForUpdate, createdLotMap, headerRecord, 'Order_Line__c',sourceDocs,attributesForService,keyMap); // populate the uncommited skid and inventory transaction objects with the user supplied attributes
                for( receivingWrapper rw : rlWrapperList ){
                	orderLines.put(rw.rl.Id,rw.rl);
                }
                //The below method should be called before the putawayservice to locate the lot exceptions
                TOManageExceptions(rlWrapperList,orderLines);
                
            	for(Skid__c sk: skidsForService)
            	{
                	Skid__C skNegative = sk.Clone(false,true);
                    skNegative.Bin__c = null;
                	if( orderLines.containsKey(sk.Order_Line__c) ){
                	    skNegative.Location__c = (Id)orderLines.get(sk.Order_Line__c).get('Deliver_To_Location__c');
                	    uniqueLocationsIds.add(skNegative.location__c);
                	}
                	skNegative.Quantity__c = skNegative.Quantity__c*-1;
                	skNegative.Type__c=SkidService2.SKID_TYPE_INTRANSIT;
                	negativeSkidsforService.add(skNegative);
                	sk.Order_line__c=null;
                	sk.Shipment_Line__c=null;
            	}
            
                toSkidsNegativeMap = SkidService2.putAwayService(negativeSkidsforService, attributesForServiceForNegativeSkids, uniqueLocationsIds, 'In-Transit', false ); // merges or creates location (To) skids ( i.e putaway )

            }
                
            toSkidsMap = SkidService2.putAwayService(skidsForService, attributesForService, uniqueLocationMap.keySet(), 'Location', false ); // merges or creates location (To) skids ( i.e putaway )

            for (String itKey:keyMap.keySet()) {
                String skidKey = keyMap.get(itKey);
                if (toSkidsMap.containsKey(skidKey)) {
                    toSkidsMap.put(itKey,toSkidsMap.get(skidKey));
                }
            }
            
            SkidService2.inventoryTransactionsForPutAway(sourceDocs,itMap,null,null,attributesForService,toSkidsMap,null,null); // creates inventory transactions for putaway and decrements the from skids.
            
            for(sObject ol: polsForUpdate)
            {
                if((orderlineKeyMismatchExceptionList!=null)&&(orderlineKeyMismatchExceptionList.size()>0))
                {
                    if(orderlineKeyMismatchExceptionList.containsKey(ol.Id))
                    {   
                        ol.put('Exceptions_Count__c',1);
                    }
                }
                if((orderlineQtyMismatchExceptionList!=null)&&(orderlineQtyMismatchExceptionList.size()>0))
                {
                    if(orderlineQtyMismatchExceptionList.containsKey(ol.Id))
                    {
                        ol.put('Exceptions_Count__c',1);
                    }
                }
                    
            }
            
            if( (sourceDocument == 'Purchase Order' && headerRecord.get('Type__c') == 'SubContract') || (sourceDocument == 'Receiving Document') ){
                
                completeWorkOrders( rlWrapperList, sourceDocument, attributesForService );
            }
            
            DML.updateAsUser( polsForUpdate ); //update the quantity received on PO lines , increment was done in populateBeforePutaway
            // we do the polines update after the service calls because this update might delete some of the po supply skids that are used in the service calls.
             
            if(sourceDocument == 'Transfer Order' ){
            
                if(orderlineKeyMismatchExceptionList.keySet().size()>0)
                {
                   LogException(orderLines,orderlineKeyMismatchExceptionList, SkidService2.SKID_LOT_EXCEPTION);
                   
                }
                if(orderlineQtyMismatchExceptionList.keySet().size()>0)
                {
                   LogException(orderLines,orderlineQtyMismatchExceptionList,SkidService2.SKID_QUANTITY_EXCEPTION);
                   
                }
            }
             
            
            if (sourceDocument == 'Purchase Order' && headerRecord.get('Type__c') == PurchaseOrderService.PO_TYPE_DROP_SHIP){
                SalesOrderService.confirmDropShip(rlWrapperList);
            }

            if( sourceDocument == 'Receiving Document'){

                Receiving_Document__c rdRec = getReceivingDocumentRecord(headerId);
                if(rdRec.transaction_date__c == null){
                	rdRec.transaction_date__c = system.now();
                }
                if(rdRec.status__c == 'Closed'){
                	rdRec.Finalized__c = true;
                }
                DML.updateAsUser(rdRec);
            }
            
            for(skid__c sk: toSkidsNegativeMap.values())
            {
                if(sk.Quantity__c==0)
                    deletableSkids.add(sk.id);
            }
            
            if(deletableSkids.size()>0)
                DML.deleteAsSystem(deletableSkids);
            
                
            decimal keyExceptionListSize = 0;
            decimal qtyExceptionListSize = 0;
            
            if(orderlineKeyMismatchExceptionList!=null && orderlineKeyMismatchExceptionList.size()>0)
            	keyExceptionListSize = orderlineKeyMismatchExceptionList.size();
            if(orderlineQtyMismatchExceptionList!=null && orderlineQtyMismatchExceptionList.size()>0)
            	qtyExceptionListSize = orderlineQtyMismatchExceptionList.size();	
            	
            if(keyExceptionListSize==0 && qtyExceptionListSize==0)  
            	ClearExceptionsAndClose(rlWrapperList,orderLines);   
            
        }
        catch (Exception ex) {
            Database.rollback(sp);
            throw new ReceivingDocumentServiceException( ex.getMessage());
        }
        
        return null;
    }
    
    
    private static void ClearExceptionsAndClose(List<receivingWrapper> rlWrapperList,Map<id,sObject> orderLines)
    {
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Set<Id> orderLineIds = orderLines.keyset();
		
		SOQLUtil soql = new SOQLUtil('Task', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','WhatID','exception_code__c'
		});
		soql.setWhereClause('(exception_code__c like \'%TO-LOTMI%\' or exception_code__c like \'%TO-QTYEX%\') and WhatId IN :orderLineIds');

		List<Task> existingExceptions = Database.query(soql.getQuery());

		Map<id,list<task>> olExceptions = new Map<id,list<task>>();
		Map<id,list<task>> lotExceptions = new Map<id,list<task>>();
		for(task tsk:existingExceptions)
		{	if(tsk.exception_code__c.contains('TO-QTYEX'))
				olExceptions.put(tsk.whatId,new List<task>{tsk});
			else if(tsk.exception_code__c.contains('TO-LOTMI'))
				lotExceptions.put(tsk.whatId,new List<task>{tsk});
		}
		list<task> tskForUpdate=new list<task>();
		if(lotExceptions.size()==0 && olExceptions.size()>0)
		{
			for(sObject ol: orderLines.values())
			{
				if(ol.get('Quantity_ordered__c')==ol.get('Quantity_received__c'))
				{
					tskForUpdate.addall(olExceptions.get(ol.Id));
				}
					
			}
		
			if(tskForUpdate.size()>0)
			{
				for(task tsk: tskForUpdate)
				{
					tsk.Status = 'Closed';
				}
				DML.updateAsUser(tskForUpdate);

			}
		}
            
    }
    
    //Method to manage Lot and Quantity exceptions -PTM-165
    public static void TOManageExceptions(List<receivingWrapper> rlWrapperList,Map<id,sObject> orderLines)
    {
        //public variable getting cleared when ever receive is clicked
        orderlineKeyMismatchExceptionList =new map<id,string>();
        orderlineQtyMismatchExceptionList = new map<id,string>();
        map<Id,map<string,decimal>> orderlineUIKeyMap = new map<Id,map<string,decimal>>();
        map<Id,map<string,decimal>> orderlineIntransitKeyMap = new map<Id,map<string,decimal>>();
        map<id,List<string>> itemToAttributesMap = new map<id,List<string>>();
        map<string,decimal> UISkidKeyMap = new map<string,decimal>();
        map<Id,sObject> olsMap = new map<Id,sObject>();
        set<id> orderLinesTemp=new set<Id>();
        map<string,decimal> intransitKeyMap = new map<string,decimal>();
        decimal existingQuantity = 0;
        decimal totalQuantity = 0;
        decimal intransitQuantity = 0;
        string allKeys='';   
        string allQtyKeys = '';
        
        Map<String, Schema.SObjectField> skidsFieldsMap = SchemaUtil.getInstance().getFieldsMap('Skid__c');
        

        //Exception Handling for Attributes information and Quantity 
        for( receivingWrapper rw : rlWrapperList ){
            
            UISkidKeyMap = new map<string,decimal>();
            totalQuantity = 0;
            if( (Boolean)rw.rl.getSObject('Receiving_Item__r').get('Non_Inventory__c') == false){
                
                List<string> attributes= rw.trackedAttributes;
                
                itemToAttributesMap.put((id)rw.rl.get('Receiving_Item__c'),attributes);
                
                for( Integer i = 0; i < rw.skidList.size() ; i ++ ){
                    
                    String key='';
                    
                    for(integer j=0;j<attributes.size();j++)
                    {
                        if(attributes[j] != 'Bin__c'){
                        if(attributes[j] == 'Lot_Number__c'){    
                            key+= attributes[j] + ': ' + rw.skidList[i].get('Lot__c') + ' | ';
                            
                       }
                       else
                       {
                           key+= attributes[j] + ': ' + rw.skidList[i].get(attributes[j]) + ' | ';
                       }
                    }

                    }
                    if(attributes.size()==0){
                        key = 'NO ATTRIBUTES';
                    }
                        
                    existingQuantity = 0;
                    
                    if(UISkidKeyMap.get(key)!=null)
                        existingQuantity = (decimal)UISkidKeyMap.get(key);
                    
                    UISkidKeyMap.put(key,(existingQuantity + (decimal)rw.skidList[i].get('Quantity__c')));
                }
                orderlineUIKeyMap.put(rw.rl.Id,UISkidKeyMap);
                
            }
        }
        
        //All are non inventory items so no need for any exception check so return
        if(orderlineUIKeyMap.size()==0)
            return;
        
        //Original transit-skids of the order lines before modification in the UI during receive.
        list<string> attrList = skidservice2.attributesForPutaway(new list<String>(Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c')));
        set<Id> olIds= orderLines.keyset();
        //string soqlTransitSkid = 'select id,Lot_Number__c,' + string.join(attrList,',') + ',Quantity__c,Lot__r.Name, Type__c,Order_Line__r.Id,Order_Line__r.Name,Item__r.Item_Attribute__c, Order_Line__c FROM Skid__c where type__c = \'In-Transit\' and Order_Line__c IN:olIds  order by Order_Line__c';
        
        String whereClause = 'Type__c = \'In-Transit\' and Order_Line__c IN :olIds ORDER BY Order_Line__c';
        
        SOQLUtil soql = new SOQLUtil('Skid__c');
        soql.addFields(new Set<String>(attrList));
        soql.addFields(new Set<String>{'id', 'Lot_Number__c', 'Quantity__c', 'Lot__r.Name', 
                        'Type__c', 'Order_Line__r.Id', 'Order_Line__r.Name', 'Item__r.Item_Attribute__c', 'Order_Line__c','Packaging_UOM__c'
                      });
        soql.setWhereClause(whereClause);
        
        Map<string,string> keyIdtoName =new Map<string,string>();
        for( sObject transitSkid : Database.query(soql.getQuery())){
            
            olsMap.put((Id)transitSkid.get('Order_Line__c'),transitSkid.getsObject('Order_Line__r'));
            
            List<string> attributesLst = new List<string>();
            attributesLst = itemToAttributesMap.get((id)transitSkid.get('Item__c'));
            
            string attributeKey='';
            String attributeKeyLabel='';
            
            for(integer k=0;k<attributesLst.size();k++)
            {
                if(attributesLst[k] != 'Bin__c'){
               if(attributesLst[k] == 'Lot_Number__c')
               {    
                
                    if(transitSkid.get('Lot__c')!=null)
                    {    
                        attributeKey+= attributesLst[k] + ': ' + transitSkid.get('Lot__c') + ' | ';
                        attributeKeyLabel+= skidsFieldsMap.get(attributesLst[k]).getDescribe().getLabel() + ': ' + transitSkid.getsObject('Lot__r').get('Name') + ' | ';
                    }
               }
               else
               {
                   attributeKey+= attributesLst[k] + ': ' + transitSkid.get(attributesLst[k]) + ' | ';
                   attributeKeyLabel+= skidsFieldsMap.get(attributesLst[k]).getDescribe().getLabel() + ': ' + transitSkid.get(attributesLst[k]) + ' | ';
               }
            }
            
            }
            
            if(attributesLst.size()==0){
                attributeKey = 'NO ATTRIBUTES';
                attributeKeyLabel = 'NO ATTRIBUTES'; 
            }
            keyIdtoName.put(attributeKey,attributeKeyLabel);
            olIdKeyNameMap.put((Id)transitSkid.get('Order_Line__c'),keyIdtoName);
            if(orderLinesTemp.size()>0 && (!(orderLinesTemp.contains((Id)transitSkid.get('Order_Line__c')))))
            {
                intransitKeyMap = new Map<string,Decimal>();
            }
            intransitQuantity = 0;
            if(intransitKeyMap.get(attributeKey)!=null && ((orderLinesTemp.contains((Id)transitSkid.get('Order_Line__c')))))
            {
                intransitQuantity = (decimal)intransitKeyMap.get(attributeKey);
            }   
            
            
            intransitKeyMap.put(attributeKey,(intransitQuantity + (decimal)transitSkid.get('Quantity__c')));
            
            orderlineIntransitKeyMap.put((Id)transitSkid.get('Order_Line__c'),intransitKeyMap);
            
            orderLinesTemp.add((Id)transitSkid.get('Order_Line__c'));
            
        }
        
        for(Id ol: orderlineIntransitKeyMap.keyset())
        {
            List<string> lotKeys =new List<string>();
            List<string> qtyKeys = new list<string>();
            allKeys= '';
            allQtyKeys= '';
            for(string key: orderlineIntransitKeyMap.get(ol).keyset())
            {
                
                if(orderlineUIKeyMap.get(ol)!=null &&(!orderlineUIKeyMap.get(ol).containsKey(key))){
                    allKeys +=olIdKeyNameMap.get(ol).get(key);
                    orderlineKeyMismatchExceptionList.put(olsMap.get(ol).Id,allKeys);
                }
                else if(orderlineUIKeyMap.get(ol)!=null &&(orderlineUIKeyMap.get(ol).containsKey(key)))
                {   
                    if((Decimal)orderlineIntransitKeyMap.get(ol).get(key) != (Decimal)orderlineUIKeyMap.get(ol).get(key))
                    {   
                        allQtyKeys +=olIdKeyNameMap.get(ol).get(key);
                        orderlineQtyMismatchExceptionList.put(olsMap.get(ol).Id,allQtyKeys);
                    }
                }
            }
        }

    }
    
    public static void LogException(map<id,SObject> orderLines,Map<id,string> exceptionList,string exceptionType)
    {   
        string qtyExceptionMessage;
        for(id olId:exceptionList.keyset())
        {
            if(exceptionType == SkidService2.SKID_LOT_EXCEPTION){
                
                ExceptionUtil.TO_LOTMISMATCH.label = Label.TO_Attributes_Exception + ' ' + exceptionList.get(olId);
                ExceptionUtil.TO_LOTMISMATCH.description = Label.TO_Attributes_Exception  + ' ' +  exceptionList.get(olId);
                exService.setException(orderLines.get(olId), ExceptionUtil.TO_LOTMISMATCH);
            }
            else if(exceptionType == SkidService2.SKID_QUANTITY_EXCEPTION){
                
                qtyExceptionMessage = '';
                
                if(exceptionList.get(olId) != 'NO ATTRIBUTES')
                    qtyExceptionMessage = ' with attributes: ' + exceptionList.get(olId);
                
                ExceptionUtil.TO_QTYEXCEEDED.label = Label.TO_Quantity_Exception + ' ' +  (qtyExceptionMessage.length() > 1 ? qtyExceptionMessage.substring(0,qtyExceptionMessage.length() - 2) : '');
                ExceptionUtil.TO_QTYEXCEEDED.description = Label.TO_Quantity_Exception + ' ' + (qtyExceptionMessage.length() > 1 ? qtyExceptionMessage.substring(0,qtyExceptionMessage.length() - 2) : ''); 
                exService.setException(orderLines.get(olId), ExceptionUtil.TO_QTYEXCEEDED);
            }
        }
        exService.finishTasks();
        
    }    
    
    public static void completeWorkOrders( List<receivingWrapper> rlWrapperList, string sourceDocument, list<String> attributesForService ){
        
        map<Id, list<Skid__c>> completeQuantityByWorkOrder = new map<Id, list<Skid__c>>();
        map<Id, list<Skid__c>> scrapQuantityByWorkOrder = new map<Id, list<Skid__c>>();
        Map<Id, SkidService3.serialWrapper> skidwrappermap = new Map<Id, SkidService3.serialWrapper>();
        
        for( receivingWrapper rw : rlWrapperList ){
            SObject pol = rw.rl;
            if( sourceDocument == 'Receiving Document'){
                if( rw.rl.getSObject('Purchase_Order__r').get('Type__c') != 'SubContract' )
                    continue;
                
                pol = rw.rl.getSObject('Purchase_Order_Line__r');    
            }
            
            if( pol.get('Work_Order__c') == null )
                throw new ReceivingDocumentServiceException('Work Order not specified on Purchase order line : '+pol.get('Name'));
                
            if( pol.getSObject('Work_Order__r').get('Assembly_Item_Specification__c') != pol.get('Item_Specification__c') )
                throw new ReceivingDocumentServiceException('Work Order does not match the item specification on Purchase order line : '+pol.get('Name'));    
            
            List<SKID__c> completeSkidList = new list<SKID__c>();
            
            for( SKID__c sk : rw.skidList ){
            	SkidService3.SerialWrapper skidwrapper;   
                SKID__c completeSkid = new SKID__c( Item__c = (Id)pol.getSObject('Item_Specification__r').get('Item__c'), Quantity__c= sk.Quantity__c, Type__c = SkidService2.SKID_TYPE_LOCATION, Company__c = (Id)pol.get('Company__c') );
                for( String attr: attributesForService ){
                    if( attr != 'Item__c')
                        completeSkid.put(attr, sk.get(attr));
                    if( attr == 'Lot__c'){
                        completeSkid.put('Lot_Number__c', sk.Lot_Number__c);
                    }    
                    
                }
                completeSkid.Location__r = sk.Location__r;
                completeSkidList.add(completeSkid);
                skidwrapper = new SkidService3.SerialWrapper(completeSkid,null);
                
                skidwrappermap.put(sk.Id,skidwrapper);
            }
            completeQuantityByWorkOrder.put( (Id)pol.get('Work_Order__c'), completeSkidList );
            scrapQuantityByWorkOrder.put((Id)pol.get('Work_Order__c'), new List<SKID__c>());
        }
        
        if( completeQuantityByWorkOrder.size() > 0 ){
            //WorkOrderService.autoCompleteWorkOrders( completeQuantityByWorkOrder, scrapQuantityByWorkOrder, skidwrappermap);
        }
    }
    
    public static void checkHeaderErrors( Id headerId, String sourceDocument ){
        
        if( sourceDocument == 'Receiving Document'){    
            Receiving_Document__c rdRec = getReceivingDocumentRecord(headerId);
                
            if (rdRec.Status__c != RD_STATUS_OPEN) {
                
                throw new ReceivingDocumentServiceException('Receiving Document is not Open.');       
            }
        }
        else if( sourceDocument == 'Purchase Order'){
            Purchase_Order__c poRec = getPurchaseOrderRecord(headerId);
            
            if (poRec.Status__c != PO_STATUS_OPEN) {
                throw new ReceivingDocumentServiceException('Purchase Order is not Open.');   
            }
            
            if (poRec.Approval_Status__c !=  PO_APPROVAL_STATUS_APPROVED) {
               throw new ReceivingDocumentServiceException('Purchase Order is not Approved.');   
            }
            

            if (poRec.FOB_Term__r.FOB_Point__c ==  PO_FOB_ORIGIN && poRec.Type__c != 'Drop Ship') {
               throw new ReceivingDocumentServiceException('Cannot receive PO of type FOB Origin');   
            }
            
            if( poRec.Receipt_Lines__r.size() > 0 || poRec.ASN_Lines__r.size() > 0){
                throw new ReceivingDocumentServiceException(Label.Open_Receipt_ASN_Line_against_PO);   
            }
        }    
    }
    
    public static void release( set<Id> recDocIds){
        
        Savepoint sp = Database.setSavepoint();
        try{
            map<Id, Receipt_Line__c> receiptLines = (map<Id,Receipt_Line__c>) cachedReceiptLines( recDocIds, ' (Status__c = \'Draft\' or Status__c = \'Open\') ' );
            List<Receipt_Line__c> rlLinesToUpdate = new List<Receipt_Line__c>();
            map<Id, Receiving_Document__c> rdMap = new map<Id, Receiving_Document__c>();
            
            for( Receipt_Line__c rl : receiptLines.values() ){
                
                if( (rl.Status__c == 'Draft' || rl.Status__c == 'Open') && rl.Receiving_Document__r.Status__c != 'Closed'){
                	
                	rl.Quantity_Still_Due_For_Putaway__c = KSE.subtractDecimals(rl.Quantity_Declared__c, rl.Quantity_Received__c);
                    rl.Status__c = 'Open';
                    rlLinesToUpdate.add( rl );
                    
                    Receiving_Document__c rd = rl.Receiving_Document__r;
                    
                    if( rl.Receiving_Document__r.Status__c != 'Open' && (!rdMap.containsKey(rd.Id))){
                        rd.Status__c = 'Open';
                        rdMap.put(rd.Id, rd);
                    }
                }
            }
            
            
            if( rlLinesToUpdate.size() == 0 ){
                
                throw new ReceivingDocumentServiceException(Label.Cannot_release_Receiving_Document);         
            }
            
            DML.updateAsUser( rlLinesToUpdate );
            DML.updateAsUser( rdMap.values() );
            
        }
        catch( Exception ex ){
            
            Database.Rollback( sp );
            throw ex;
        }
    }
    /*
    * @Description - The below method is used to close/Cancel an Source Document.
    * @Parameters  - 
    *				set<Id>      sObjIds         - contains the list of Ids of an sObject that has to be closed/Cancelled
    *				String       childObjectName - Contains the associated Child Object name of the Sobject
    *				String       parentFieldName - Primary Key of the Parent Object
    *				list<String> deleteSkidTypes - The list of all Skid types that has to be deleted
    *				Boolean      allSkidTypes    - flag that determines all skid types can be deleted
    *				Boolean      noskidDelete    - flag that determines if the Skid can be deleted
    *				Boolean      status          - flag that holds "Cancelled"  or "Closed" Status.
    *
    */
    public static void close( set<Id> sObjIds, String childObjectName, String parentFieldName,String parentObjectName, list<String> deleteSkidTypes, Boolean allSkidTypes, Boolean noskidDelete, string status ){
        
        Savepoint sp = Database.setSavepoint();
        
        try
        {
            set<String> skidFields = new set<string>();
            list<SKID__c> deleteSkids = new list<SKID__c>();
            list<SObject> childSObjects = new list<SObject>();
            list<SObject> parentSObjects = new list<SObject>();
            
            skidFields.addAll( Schemautil.getInstance().getAllCustomFieldsFromObject('',childObjectName) );
            
            /*String skidWhereClause='';
            
            if(!allSkidTypes && deleteSkidTypes != null ){
                skidWhereClause = ' Where Type__c IN:deleteSkidTypes ';
            }
                
            if(!noskidDelete)
                skidFields.add(' ( select id, Type__c From Skids__r '+skidWhereClause+' )');
            
            String query = util.generateQueryFromFieldSet( childObjectName, new set<string>{''}, 
                        skidFields, parentFieldName +' IN:sObjIds AND Status__c NOT IN (\'Closed\',\'Cancelled\')');    // included the status as part of PTP-404.
            */                
            //System.debug(LoggingLevel.INFO, '*** queryString: ' + queryString);
            
            String whereClause = parentFieldName +' IN :sObjIds AND Status__c NOT IN (\'Closed\',\'Cancelled\')';
        
		    SOQLUtil soql = new SOQLUtil(childObjectName);
		    soql.addFields(skidFields);
		    soql.setWhereClause(whereClause);
		    
		    if(!noskidDelete){
	            SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
			    skids.addFields(new Set<String>{'id', 'Type__c'});
			    if(!allSkidTypes && deleteSkidTypes != null ){
            	    skids.setWhereClause('Type__c IN :deleteSkidTypes');
			    }
			    soql.addChildRelationship(skids);
        	}
	    
            list<SObject> sobjLines = Database.query(soql.getQuery());
                        
            for( SObject sObj : sobjLines )
            { 
                sObj.put('Status__c',status);
                List<SKID__c> skList = (list<SKID__c>) sObj.getSObjects('Skids__r');
               
				if( skList != null )
                    deleteSkids.addAll(skList);
                    
                string sObjName = sObj.getSObjectType().getDescribe().getLocalName();
                   
                if(sObjName =='Work_Order__c' && status == 'Draft'){//PTM-600
                	sObj.put('Release_Date__c', null);
                }   
                childSObjects.add( sObj );    
            }    
            if(parentObjectName!='null')
            {
	            for( Id sObjId : sObjIds )
	            {
	                
	                SObject sObj = util.getGlobalDescribe(parentObjectName).newSObject() ;
	                sObj.put( 'Id', sObjId );
	                sObj.put('Status__c', status);
	                if (status == 'Closed'){
	                	String objectName = util.getGlobalDescribe(parentObjectName).getDescribe().getLocalName();
            			if (!objectName.equalsignorecase('Purchase_Order__c') ) //PTP-609
	                	sObj.put('Finalized__c', true); //PTP-400
	                }
	                parentSObjects.add(sObj);
	            }
	        }
            if(deleteSkids.size() > 0 )
                DML.deleteAsSystem(deleteSkids);
            
            if(parentObjectName!='null' && parentSObjects.size() > 0 )
                DML.updateAsUser(parentSObjects);    
            
            if(childSObjects.size() > 0 )
                DML.updateAsUser(childSObjects);
        }
        catch( Exception ex )
        {
            Database.Rollback( sp );
            throw ex;
        }
    }
    
    public class ReceivingWrapper{
            
        public SObject rl{ get; set; } //PO line for PO Receiving , Receipt line for RD receiving
        public Receipt_Line__c receipt { get; set;} //used only for PO Receiving
        public Integer rowIndex { get; set; }
        public List<SKID__c> skidList { get; set; }
        public list<Inventory_Transaction__c> itList { get; set; }
        
        public list<String> trackedAttributes { get; set; }
        public Integer minimumShelfLife { get; set; } { minimumShelfLife = 0; }
        
        public ReceivingWrapper( SObject rLine, Integer index, SKID__c fromSkid, Location__c pal, list<String> attributeFields, String sourceDocument ){ 
            //sourceDoc can be 'Purchase Order' or 'Receiving Document'
            
            Id polId;
            Purchase_Order_Line__c poLineCache;
            rl = rLine;
            
            rl.put('Putaway_Location__c' , (pal != null) ? pal.id : null);
            rl.putSObject('Putaway_Location__r' , (pal != null) ? pal : null);
            rowIndex = index;
            skidList = new list<SKID__c>();
            trackedAttributes = new list<String>();

            SKID__c skid = new SKID__c(Item__c = (Id)rl.get('Item__c'), Type__c = 'Location', Company__c = (Id)rl.get('Company__c'));//Added Type as Location PTM-361
            if( pal != null )
                skid.Location__c = pal.id;
            skid.putSObject('Item__r', rl.getSObject('Item__r')); 
            skid.Location__r = pal;  
            
            trackedAttributes.addAll( SkidService2.trackedAttributes(attributeFields, pal, rl.getSObject('Item__r') ));
            
            if( sourceDocument == 'Purchase Order'){
                polId = rl.Id;
                poLineCache = (Purchase_Order_Line__c) rl;
                
                for( String attr : trackedAttributes ){
                    
                    if( attr == 'Date_Received__c'){
                        
                        skid.put( attr, System.today());
                    }
                }
                
                receipt = new Receipt_Line__c( Company__c = poLineCache.Company__c, Item__c = poLineCache.Item__c, Supplier__c = poLineCache.Purchase_Order__r.Supplier__c, 
                                Purchase_Order_Line__c = poLineCache.id, Purchase_Order__c = poLineCache.Purchase_Order__c, Location__c = poLineCache.Delivery_Location__c, 
                                Facility__c = poLineCache.Delivery_Location__r.Facility__c, Uninvoiced_Quantity__c = 0 );   
                receipt.Purchase_Order_Line__r = poLineCache; 
                receipt.Purchase_Order_Line__r.Status__c = poLineCache.Status__c;      
                receipt.Purchase_Order__r = poLineCache.Purchase_Order__r;     //for test failure
                receipt.Purchase_Order__r.Status__c = poLineCache.Purchase_Order__r.Status__c; //for test failure
            }
            else{
                polId = (Id)rl.get('Purchase_Order_Line__c');
                poLineCache = (Purchase_Order_Line__c)rl.getSObject('Purchase_Order_Line__r');
                skid.Quantity__c = (Decimal)poLineCache.get('Quantity_Still_Due__c');
                
                for( String attr : trackedAttributes ){
                    if( attr != 'Bin__c')
                	    skid.put( attr, rl.get( attr ) );
                }    
             
            }

            itList = new list<Inventory_Transaction__c>();
            Inventory_Transaction__c it;
            Decimal quantity = fromSkid != null ? fromSkid.Quantity__c : 0;
            String transactionType = '';
            
            if (rl.getSObject('Purchase_Order__r').get('Type__c') == PurchaseOrderService.PO_TYPE_DROP_SHIP) {
                //it = SkidService2.createIT(fromSkid, (Id)rl.get('item__c'), InventoryTransactionService.LOGICAL_PURCHASE_ORDER_RECEIPT, polId, null,null, pal.id, null, null );
                it = SkidService3.createInventoryTransaction(rl, InventoryTransactionService.LOGICAL_PURCHASE_ORDER_RECEIPT, quantity, fromSkid, null, null );
                
            	it.Purchase_Order_Line__r = poLineCache;
            } 
            else {
	            /*if( pal != null )
	                //it = SkidService2.createIT(fromSkid, (Id)rl.get('item__c'), 'Purchase Order Receipt', polId, null,null, pal.id, null, null );
	            else
	                //it = SkidService2.createIT(fromSkid, (Id)rl.get('item__c'), 'Purchase Order Receipt', polId, null,null, null, null, null );
	            */    
	            it = SkidService3.createInventoryTransaction(rl, 'Purchase Order Receipt', quantity, fromSkid, null, null );    
            }

            if( poLineCache.get('Consigned__c') == true ){
                trackedAttributes.add( 'Consigned_Owner__c');   
                skid.consigned_owner__c = (Id)poLineCache.getSObject('Purchase_Order__r').get('Supplier__c');
                skid.putSObject('consigned_owner__r' ,poLineCache.getSObject('Purchase_Order__r').getSObject('Supplier__r'));
                skid.Purchase_Order_Line__c = polId;   
            }
            else if( sourceDocument == 'Receiving Document'){
                it.Purchase_Order_Line__c = null;
            }
            
            if( sourceDocument == 'Receiving Document'){
                
                it.Receipt_Line__c = rLine.id;
            }
            
            skidList.add( skid );
            itList.add( it );
        }
        
        public receivingWrapper( SObject recObj, list<SKID__c> skids, list<Inventory_Transaction__c> its, Receipt_Line__c rct, list<String> trackedAttrList )
        {   
            rl = recObj;
            skidList = skids;
            itList = its;
            receipt = rct;
            trackedAttributes = trackedAttrList;
            minimumShelfLife = 0;
        }
       
    }
        
}