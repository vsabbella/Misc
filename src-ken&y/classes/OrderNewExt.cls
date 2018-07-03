public with sharing class OrderNewExt {
    public Order__c newObj {get;set;}
    private ApexPages.Standardcontroller con; 
    
    public OrderNewExt(ApexPages.StandardController controller) {
        
        con = controller;  
        newObj = (Order__c) controller.getRecord();
        Id userId = UserInfo.getUserId();
       
        SOQLUtil userPrefQuery = new SOQLUtil('User_Preference__c');
        userPrefQuery.addFields(new Set<String>{ 'Id', 'Name', 'Transfer_Order_Deliver_to_Facility__c', 'Transfer_Order_Deliver_to_Location__c',
            'Transfer_Order_Ship_from_Facility__c', 'Transfer_Order_Ship_from_Location__c', 'Default_Company__c',
            'Transfer_Order_Deliver_to_Facility__r.Name', 'Transfer_Order_Deliver_to_Location__r.Name',
            'Transfer_Order_Ship_from_Facility__r.Name', 'Transfer_Order_Ship_from_Location__r.Name', 'Default_Company__r.Name'
        });
        userPrefQuery.setWhereClause('User__c =:userId');
        userPrefQuery.setLimit(1);
        
        User_Preference__c up;
        List<User_Preference__c> upList = Database.Query(userPrefQuery.getQuery());
        if(upList.size() > 0){
            up = upList[0];
            
            newObj.Shipping_Company__c = up.Default_Company__c;
            newObj.Shipping_Company__r= up.Default_Company__r;
            newObj.Receiving_Company__c = up.Default_Company__c;
            newObj.Receiving_Company__r = up.Default_Company__r;
            newObj.Ship_from_Facility__c = up.Transfer_Order_Ship_from_Facility__c;
            newObj.Ship_from_Facility__r = up.Transfer_Order_Ship_from_Facility__r;
            newObj.Deliver_to_Facility__c = up.Transfer_Order_Deliver_to_Facility__c;
            newObj.Deliver_to_Facility__r = up.Transfer_Order_Deliver_to_Facility__r;
            newObj.Ship_from_Location__c = up.Transfer_Order_Ship_from_Location__c;
            newObj.Ship_from_Location__r = up.Transfer_Order_Ship_from_Location__r;
            newObj.Deliver_to_Location__c = up.Transfer_Order_Deliver_to_Location__c;
            newObj.Deliver_to_Location__r = up.Transfer_Order_Deliver_to_Location__r;
        }
        
    }

    public void chg_save(){
        Id companyId = (Id)ApexPages.currentPage().getParameters().get('companyId');
        newObj.Receiving_Company__c = companyId;
    }
    
    public pageReference save(){
        if(newObj.Shipping_Company__c != newObj.Receiving_Company__c){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                                     Label.Shipping_Company_must_match_the_Receiving_Company));
            return null; 
        }
        return con.save();
    }
}