public with sharing class ExceptionTasksExtNew extends GridRelatedListController {
    
    public sObject parent {get;set;}
	public String parentType {
		get {
			if(parent != null) {
				parentType = parent.getSObjectType().getDescribe().getLabel();
			}
			return parentType;
		}
		set;
	}
    
    public ExceptionTasksExtNew() {
        super();
        config.uniqueId = 'kendoGridDiv';
        config.title = 'Exception Tasks';
        config.objectName = 'Task';
        config.parentField = 'WhatId';
        config.parentRecord = parent;
        config.fieldset = 'Exception_Tasks';
        config.buttons = 'search';
        //config.readOnlyFields = 'Price_2__c,Price_3__c,Price_4__c,Price_5__c';
        config.additionalFields = 'WhatId';
        config.height = '450';
        config.alwaysUseFullDateTimeFormat = false;
        
    }
    
    public override string getFieldList() {
        if (fieldList == null && config != null) {
            fieldInfoList = FieldInfo.fetchJsonFieldInfos(config.objectName, config.fieldset, config.additionalFields, true);
            
            List<FieldInfo> tempOrderList = new List<FieldInfo>();
            
            //KNDY-10372
            FieldInfo relatedToLinkField = new FieldInfo('relatedToLink', 'Related To', 'RowInfo', false);
	        relatedToLinkField.editable = false;
	        tempOrderList.add(relatedToLinkField);
	        
            //KNDY-10372
            FieldInfo subjectLinkField = new FieldInfo('Subject', 'Subject', 'Name', false);
	        subjectLinkField.referenceTo = 'Id';
	        tempOrderList.add(subjectLinkField);
	        
	        tempOrderList.addAll(fieldInfoList);
	        fieldInfoList = tempOrderList;
	        
	        //KNDY-10372 Hide the native subject field, and not the subjectLinkField mentioned above
	        for(FieldInfo field : FieldInfoList) {
	        	if( (field.field == 'Subject' && field.fieldType != 'Name') || 
	        	      field.field == 'WhatId') {
	        		field.hidden = true;
	        	}
	        }
            
            fieldList = JSON.serialize(fieldInfoList);
            whatIdNameMap = taskWhatIds(parent, config);
            
        }
        
        return fieldList;
    }
    
    public Map<Id,String> whatIdNameMap {get;set;}
    
    public String getWhatIdNameMapJson() {
    	return JSON.serialize(whatIdNameMap);
    }
}