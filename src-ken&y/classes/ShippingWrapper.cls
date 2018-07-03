public class ShippingWrapper {
    public boolean selected {get; set;}

    public Shipment_Line__c shpLine { get; set; }
    public list<SkidService3.SerialWrapper> serialWrapperList { get; set; }
    public boolean logical { get; set; } //indicates whether this shipment line is only for logical reasons. 
    // Currently,this is used to undo logical shipments and this should not be set in the undo ship UI as unconfirming the ASN is the action that 
    // should set this to undo the logial shipment.

    public ShippingWrapper(Shipment_Line__c shpLine, list<SkidService3.SerialWrapper> swList) {
        this.shpLine = shpLine;
        this.serialWrapperList = swList;
        this.logical = false;
    }
 }