public without sharing class Permissions {
    
    //@TestVisible private static ReadCustomPermissions rcp = null;
    @TestVisible private static Boolean inSystemMode = false;
    @TestVisible private static Map<String, PermAction> permActions = null;
    
    public class CustomPermissionsException extends Exception {}
    
    public static Boolean checkSystemMode() {
        return inSystemMode;
    }
    
    //startAction is required.  If that action runs for the duration of the transaction, no endAction is needed.
    public static void startAction(String action) {
        lazyInit();
        
        Boolean hasPerm = FeatureManagement.checkPermission(KSE.namespaceUU + action);//rcp.hasPermission(action);
        System.debug(LoggingLevel.INFO, 'PERM: Start Custom Permission: ' + action + ', SystemMode: ' + hasPerm);

        permActions.put(action, new PermAction(true, hasPerm));
        setSystemMode();
    }
    
    //endAction is optional, if you want to end the action before the transaction is over.
    //in case 1 transaction is doing more than 1 action you can end one and start another one.
    //they can overlap as well.
    public static void endAction(String action) {
        lazyInit();

        Boolean hasPerm = FeatureManagement.checkPermission(KSE.namespaceUU + action);//rcp.hasPermission(action);
        System.debug(LoggingLevel.INFO, 'PERM: End Custom Permission: ' + action + ', SystemMode: ' + hasPerm);        
        
        permActions.put(action, new PermAction(false, hasPerm));
        setSystemMode();        
    }    
    
    private static void lazyInit() {   
        if (permActions == null) {
            permActions = new Map<String, PermAction>();  
        }                
    }
    
    private static void setSystemMode() {
        //iterate through permActions and see if there is any perm left isExecuting they have access to
        //if there is at least 1 leave them in System mode.
        Boolean newSystemMode = false;
        
        for (String action: permActions.keySet()) {
            PermAction pa = permActions.get(action);
            if (pa.isExecuting && pa.hasAccess) {
                newSystemMode = true;
                break; //we found at least 1 isExecuting action they have access to, no need to look further
            }
        }
        inSystemMode = newSystemMode;
        System.debug(LoggingLevel.INFO, 'PERM: Permissions setSystemMode: ' + inSystemMode);
    }
    
    
    //custom object so we can have strongly typed attributes
    private class PermAction {
        public Boolean isExecuting {get; set;}
        public Boolean hasAccess {get; set;}
        public PermAction(Boolean e, Boolean h) {
            isExecuting = e;
            hasAccess = h;
        }
    }

    
}