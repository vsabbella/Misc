global with sharing class SelectListItem { 
    global string text { get; set; }
    global string value { get; set; } 
    global boolean selected = false;
    
    global SelectListItem(string value, string text) { 
        this.text = text;
        this.value = value;
    }
        
    global SelectListItem(Schema.PicklistEntry pe) { 
        this.text = pe.getLabel();
        this.value = pe.getValue(); 
        this.selected = pe.isDefaultValue();
    }
}