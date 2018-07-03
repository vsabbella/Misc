// User-defined class for supplying field info for setting up the kendo grid
global with sharing class FieldInfo {
	public class EmptyFieldSetMemberException extends Exception {}
    public static Boolean AlwaysUseFullDateTimeFormat = true;

    global string field { get; set; }
    global string title { get; set; }
    global string fieldtype { get; set; }
    global boolean editable = false;
    global boolean sortable = true;
    global boolean filterable = false;
    global boolean nullable = false;
    global boolean hidden = false;
    global boolean required = false;
    global List<SelectListItem> selectList { get; set; }
    global string referenceTo { get; set; }
    global integer precision {get; set; } 
    global integer scale { get; set; } 
    global String format { get; set; } 
    global Integer width { get; set; }
    global boolean validateLookupOnBlur = false;
    global Map<String, Object> validation {get; set;}

    global FieldInfo() {
    	this.precision = 0;
    	this.scale = 0;
    }
    
    global FieldInfo(string field, string title, string ftype) {
    	this.precision = 0;
    	this.scale = 0;
	    	this.field = field;
	    	this.title = title;
	    	this.fieldtype = ftype;
    }
    
    global FieldInfo(string field, string title, string ftype, boolean hidden) {
    	this.precision = 0;
    	this.scale = 0;
    	this.field = field;
    	this.title = title;
    	this.fieldtype = ftype;
    	this.hidden = hidden;
    }

    private static SchemaUtil util = SchemaUtil.getInstance();

    public static List<FieldInfo> fetchJsonFieldInfos(String objectName) { return fetchJsonFieldInfos(objectName, new List<String>(util.getAllCustomFieldsFromObject('', objectName))); }
    public static List<FieldInfo> fetchJsonFieldInfos(String objectName, List<String> fieldNames) { return fetchJsonFieldInfos(objectName, fieldNames, false); }
    public static List<FieldInfo> fetchJsonFieldInfos(String objectName, List<String> fieldNames, Boolean readOnly) { return fetchJsonFieldInfos(objectName, null, String.join(fieldNames, ','), readOnly); }
    
    public static List<FieldInfo> fetchJsonFieldInfos(String objectName, String fieldSet) { return fetchJsonFieldInfos(objectName, fieldSet, ''); }
    public static List<FieldInfo> fetchJsonFieldInfos(String objectName, String fieldSet, String readOnlyFields) {
        Schema.SObjectType objectType = util.getGlobalDescribe(objectName);

        readOnlyFields = String.isNotBlank(readOnlyFields) ? readOnlyFields : '';
        Set<String> readOnlyFieldList = new Set<String>(readOnlyFields.split(','));

        List<FieldInfo> fieldInfoList = new List<FieldInfo>{ new FieldInfo('Id', 'Id', 'string', true) };
        for (Schema.FieldSetMember fsm:util.getFieldsFromFieldSet(objectType, fieldset)) {
            String field = fsm.getFieldPath().replace(KSE.NamespaceUU, '');
            FieldInfo fi = getFieldInfo(field, objectType, !readOnlyFields.contains(field));
            fi.required = fsm.getDbRequired() || fsm.getRequired();      
            fieldInfoList.add(fi);
        }
        
        return fieldInfoList;
    }
    
    public static List<FieldInfo> fetchJsonFieldInfos(String objectName, String fieldSet, String additionalFields, Boolean allFieldsReadOnly) {
        Schema.sObjectType objectType = util.getGlobalDescribe(objectName);

        List<Schema.FieldSetMember> fieldSetMemberList;
        List<FieldInfo> fieldInfoList;
        if (String.isNotBlank(fieldSet)) {
            fieldSetMemberList = util.getFieldsFromFieldSet(objectType, fieldset);
            if (fieldSetMemberList.size() == 0) throw new EmptyFieldSetMemberException('Could not locate Field Set :' + fieldset + ' Namespace: ' + util.namespace);

            fieldInfoList = new List<FieldInfo>{ new FieldInfo('Id', 'Id', 'string', true) };
        } else {
            fieldSetMemberList = new List<Schema.FieldSetMember>();
            fieldInfoList = new List<FieldInfo>();
        }
        
        for (Schema.FieldSetMember fsm:fieldSetMemberList) {
            FieldInfo fi = getFieldInfo(fsm.getFieldPath().replace(KSE.NamespaceUU, ''), objectType, !allFieldsReadOnly);
            fi.required = fsm.getDbRequired() || fsm.getRequired(); // Should we also check the fieldset required?        
            fieldInfoList.add(fi);
        }
        
        if (additionalFields != null && additionalFields != '' ) {
            for (String f:additionalFields.split(',')) {
                fieldInfoList.add(getFieldInfo(f.replace(KSE.NamespaceUU, ''), objectType, !allFieldsReadOnly));
            }
        }
        
        return fieldInfoList;
    }

    public static FieldInfo getFieldInfo(String field, sObjectType obj) { return getFieldInfo(field, obj, null); }
    private static FieldInfo getFieldInfo(String field, sObjectType obj, Boolean editable) {
        Map<String, sObjectField> fieldMap = util.addNoNSfieldsToMap(obj.getDescribe().fields.getMap());
        FieldInfo fi = new FieldInfo();
        
        if( field != null && field != '' ){
            if (field.contains('.')) {
                List<String> fieldParts = field.split('\\.');
                for (Integer i = 0; i < fieldParts.size(); i++) {
                    String fieldName = fieldParts[i].replace('__r', '__c');
                    fieldMap = util.addNoNSfieldsToMap(obj.getDescribe().fields.getMap());
                    obj = fieldMap.get(fieldName).getDescribe().getReferenceTo()[0];
                    if ((fieldParts.size() - i) == 2) {
                        fieldMap = util.addNoNSfieldsToMap(obj.getDescribe().fields.getMap());
                        fi = getFieldInfo(util.addNoNSfieldsToMap(obj.getDescribe().fields.getMap()).get(fieldParts[i + 1]).getDescribe(), editable);
                        fi.field = field;
                        break;
                    }
                }
                
                if (fi == null) throw new CustomException('Invalid field ' + field + ' on object ' + obj.getDescribe().getName());
            } else if(fieldMap.containsKey(field)) {
                fi = getFieldInfo(fieldMap.get(field).getDescribe(), editable);
            }
        }
        return fi;
    }
    
    public static FieldInfo getFieldInfo(Schema.DescribeFieldResult dfr) { return getFieldInfo(dfr, null); }
    public static FieldInfo getFieldInfo(Schema.DescribeFieldResult dfr, Boolean editable) {
        FieldInfo fi = new FieldInfo();
        
        fi.field = dfr.getName().replace(KSE.NamespaceUU, '');
        fi.title = dfr.getLabel();
        fi.fieldtype = String.valueOf(dfr.getType()).toLowerCase();
        fi.editable = editable != null && !editable ? editable : (dfr.isCreateable() || dfr.isUpdateable());
        fi.sortable = dfr.isSortable();
        fi.nullable = dfr.isNillable();
        
        if (dfr.getType() == Schema.DisplayType.Picklist || dfr.getType() == Schema.DisplayType.MultiPicklist) {
            fi.selectList = new List<SelectListItem>();
            
            // add empty string option if picklist allows null values
            if (dfr.isNillable()) {
                fi.selectList.add(new SelectListItem(null, '--None--'));
            }
            
            for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                if (pe.isActive()) {
                    fi.selectList.add(new SelectListItem(pe));
                }
            }
        }
        else if (dfr.getType() == Schema.DisplayType.Reference) {
            List<Schema.SObjectType> parentObjects = dfr.getReferenceTo();
            fi.referenceTo = (parentObjects.size() > 0) ? String.valueOf(parentObjects[0]).replace(KSE.NamespaceUU, '') : null;
        }
        else if (dfr.getType() == Schema.DisplayType.Date || dfr.getType() == Schema.DisplayType.DateTime ) {
        	if (AlwaysUseFullDateTimeFormat != null) {
                fi.format = KendoUtils.DATETIME_FORMAT;
            } else {
                if (dfr.getType() == Schema.DisplayType.Date) {
                    fi.format = KendoUtils.DATE_FORMAT;
                } else {
                    fi.format = KendoUtils.DATETIME_FORMAT;
                }
            }
            
        }
        
        fi.precision = dfr.getPrecision();
        fi.scale = dfr.getScale();
        
        return fi;
    }
}