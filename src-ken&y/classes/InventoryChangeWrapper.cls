public with sharing class InventoryChangeWrapper {

    public Inventory_Change__c inventoryChange { get; set; }
    public list<SkidService3.SerialWrapper> serialWrapperList { get; set; }

    public Map<String, Object> mAttributes = new Map<String, Object>(); 

    public InventoryChangeWrapper(Inventory_Change__c invChange, list<SkidService3.SerialWrapper> swList) {
        this.inventoryChange = invChange;
        this.serialWrapperList = swList;
    }
 }