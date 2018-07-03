public class WorkOrderWrapper {
    public Work_Order__c workOrder { get; set; }
    public Material_Tracking__c material { get; set; }
    public List<SkidService3.SerialWrapper> serialWrapperList { get; set; } { serialWrapperList = new List<SkidService3.SerialWrapper>(); }
    public List<FieldInfo> skidFields { get; set; }
    
    public Decimal assemblyQuantityToComplete { get; set; }
    public Decimal assemblyQuantityToScrap { get; set; }

    public WorkOrderWrapper(Work_Order__c wo, Material_Tracking__c mt) { this(wo, mt, null); }
    public WorkOrderWrapper(Work_Order__c wo,Material_Tracking__c mt, list<SkidService3.SerialWrapper> swList) {
        this.workOrder = wo;
        this.material = mt;
        if (swList != null) this.serialWrapperList = swList;
    }
 }