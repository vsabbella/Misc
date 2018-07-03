public with sharing class ReceivingWrapper { // used for Purchase Order, ASN, Transfer Order Receiving
    
    //foundation for source document agnostic receiving service to a certain extent, all receiving processes should use the same service methods everywhere
    
    public SObject rl{ get; set; } //PO line for PO Receiving , Receipt line for RD receiving, order line for TO Receiving
    public Purchase_Order_Line__c pol {get;set;} //used to store purchase order line to avoid conditionals of whether its PO or ASN everywhere as for ASN we need the associated POline too
    public Receipt_Line__c rcl {get;set;} 
    public Item__c item { get;set;} //for storing item to avoid figuring out the path and field names based on source document
    public SObject headerRecord{get;set;}
    public list<SkidService3.SerialWrapper> serialWrapperList { get; set; }
    public list<skid__c> skidList {get;set;}
    public list<String> trackedAttributes { get; set; }
    public Integer minimumShelfLife { get; set; } { minimumShelfLife = 0; }
    public Decimal conversionFactor{get;set;} { conversionFactor = 1; }
    public String lineType { get; set; } //types can be PurchaseOrder, AdvanceShipmentNotice, TransferOrder
    public String putawayType { get; set; }
    public Boolean blockAttributeChange { get;set;} {blockAttributeChange = false;} //used in rental return where what went out must be what is received
    public Boolean addLine { get;set;}
    
    public receivingWrapper( SObject rLine, Purchase_Order_Line__c poLine, Item__c itemRec, List<String> trackedAttr, SObject headerRec, list<SkidService3.SerialWrapper> swlist ){ 
        
        rl = rLine;
        pol = poLine;
        item = itemRec;
        trackedAttributes = trackedAttr;
        lineType = String.valueOf(rl.getSObjectType()).replace(KSE.namespaceUU,'');
        headerRecord = headerRec;

        if(pol != null ){
        	conversionFactor = KSE.getConversionFactor(pol);
        }
        else if(lineType == 'Receipt_Line__c'){
        	conversionFactor = 1;
        	
        	if((Id)rl.get('Sales_Order_Line__c') != null){
        	    conversionFactor = KSE.getConversionFactor(rl.getSObject('Sales_Order_Line__r'));
        	}
        	else if(rl.getSObject('Receiving_Document__r').get('Type__c') == 'Miscellaneous Receipt'){
        		 conversionFactor = KSE.getConversionFactor(rl);
        	}
        	
        	if((Id)rl.get('Sales_Order_Line__c') != null && swlist.size() > 0 && swlist[0].skid.Quantity__c > 0){ //ensure data exists
        	    blockAttributeChange = true;
        	}
        	else{
        	    addLine = true;
        	}
        }
        else if(lineType == 'Sales_Order_Line__c'){
        	conversionFactor = KSE.getConversionFactor(rl);
        	addLine = true;
        }

        if(serialWrapperList == null ) serialWrapperList = new List<SkidService3.SerialWrapper>();
        
        serialWrapperList.addAll(swlist);
        
    }

    public ReceivingWrapper(ReceivingWrapper rWrapper) {
        if (rWrapper.rl != null) this.rl = rWrapper.rl.clone(true, true, true, true);
        if (rWrapper.pol != null) this.pol = rWrapper.pol.clone(true, true, true, true);
        if (rWrapper.rcl != null) this.rcl = rWrapper.rcl.clone(true, true, true, true);
        if (rWrapper.item != null) this.item = rWrapper.item.clone(true, true, true, true);
        if (rWrapper.headerRecord != null) this.headerRecord = rWrapper.headerRecord.clone(true, true, true, true);
        if (rWrapper.serialWrapperList != null) {
            this.serialWrapperList = new List<SkidService3.SerialWrapper>();
            for (SkidService3.SerialWrapper sw:rWrapper.serialWrapperList) this.serialWrapperList.add(new SkidService3.SerialWrapper(sw));
        }
        if (rWrapper.skidList != null) this.skidList = rWrapper.skidList.deepClone(true, true, true);
        if (rWrapper.trackedAttributes != null) this.trackedAttributes = rWrapper.trackedAttributes.clone();
        this.minimumShelfLife = rWrapper.minimumShelfLife;
        this.conversionFactor = rWrapper.conversionFactor;
        this.lineType = rWrapper.lineType;
        this.putawayType = rWrapper.putawayType;
        this.blockAttributeChange = rWrapper.blockAttributeChange;
        this.addLine = rWrapper.addLine;
    }
}