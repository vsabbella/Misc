public class LineWrapper {
    public sObject header { get; set; }
    public sObject line { get; set; }
    public List<SkidService3.SerialWrapper> serialWrappers { get; set; } { serialWrappers = new List<SkidService3.SerialWrapper>(); }
    public Decimal convFactor { get; set; } { convFactor = 1; }
    public Boolean logical { get; set; } { logical = false; }
    public List<FieldInfo> skidFields { get; set; }
    public String uom { get; set; }
    
    public LineWrapper(sObject line) { this(null, line, null); }
    public LineWrapper(sObject header, sObject line) { this(header, line, null); }
    public LineWrapper(sObject line, List<SkidService3.SerialWrapper> serialWrappers) { this(null, line, serialWrappers); }
    public LineWrapper(sObject header, sObject line, List<SkidService3.SerialWrapper> serialWrappers) {
        this.header = header;
        this.line = line;
        if (serialWrappers != null) this.serialWrappers = serialWrappers;

        if (line.getSObjectType() == Shipment_Line__c.sObjectType && line.getSObject('Sales_Order_Line__r') != null) {
            Shipment_Line__c shl = (Shipment_Line__c)line;
            List<Id> lstPkgUom = (List<Id>) JSON.deserialize( shl.Item__r.Packaging_UOM__c, List<Id>.class );
            this.convFactor = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c,shl.Sales_Order_Line__r.Selling_UOM__c, shl.Item__r.Stocking_UOM__c, lstPkgUom);
        }
    }
}