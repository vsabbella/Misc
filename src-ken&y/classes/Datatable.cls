public with sharing class Datatable {
	public class fieldSetData { 
		public String FieldPath; 
		public string Label; 
		public string Type; 
		public fieldSetData() {} 
		public fieldSetData( string FieldPath, string Label, String Type) {
			this.FieldPath = FieldPath;
			this.Label = Label;
			this.Type = Type; 
		}
		public fieldSetData( Schema.FieldSetMember fsm ) {
			this.FieldPath = fsm.getFieldPath();
			this.Label = fsm.getLabel();
			this.Type = fsm.getType().name(); 
		}
	} 	
	
	public class RemoteReturn { 
		public list<sobject> lines; 
		public list<fieldSetData> fieldset;
	}
}