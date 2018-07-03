// Label Wrapper class which will be consumed in extension packages
public class LabelWrapper {
    public SObject record {get; set;}
    public Integer caseIndex {get;set;}
    public Decimal quantity {get;set;}
    public UOM__c packagingUom {get;set;}
    public String fromType;
    public Item__c item;
}