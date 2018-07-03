/**
 * Created by ryansieve on 1/13/17.
 */

public with sharing class APIGateway {

    public class APIGatewayException extends Exception{}

    private static map<string, APIGateway__mdt> mRoutes = new map<string, APIGateway__mdt>();
    public static APIGateway__mdt getRoute(string actionName){
        APIGateway__mdt route;
        if(!mRoutes.containsKey(actionName)){ 
            List<APIGateway__mdt> routes = [SELECT developerName, target__c, namespace__c, namespacePrefix
                                        FROM APIGateway__mdt
                                        WHERE developerName = :actionName
                                        LIMIT 1];
            if(routes.size() > 0){
                mRoutes.put(actionName, routes[0]);
            }
        }
        return mRoutes.get(actionName);
    }

    public static Action.Response doAction(string actionTarget, string obj){

        system.debug('actionTarget: ' + actionTarget);
        system.debug('object: ' + obj);

        Action.Target actionType;
        long thenTime = system.now().getTime();
        APIGateway__mdt route = APIGateway.getRoute(actionTarget);
        if(route != null){
            Type t;
            if(!string.isBlank(route.Namespace__c)){
                t = Type.forName(route.Namespace__c, route.Target__c);
            }else{
                t = Type.forName(route.Target__c);
            }
            actionType = (Action.Target)t.newInstance();
        }else{
            throw new APIGatewayException('Unknown target');
        }
        Action.Response r = actionType.execute(obj);
        if(!r.success){
            String errString = 'ERROR ';
            for (Object errMessage: r.error.values() ) {
                if ( String.valueOf(errMessage).contains('Record Currently Unavailable')  ) {
                    errString += 'Record Currently Unavailable';
                    break;
                } else {
                    errString += String.valueOf(errMessage) + ' , ';
                }
            }
            throw new APIGatewayException( errString );
        }
        long nowTime = system.now().getTime();

        system.debug('TIME: '  + (nowTime - thenTime));
        system.debug('resp: ' + r);
        return r;
    }
}