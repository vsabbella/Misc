@RestResource(urlMapping='/Gateway/*')

global with sharing class Gateway {
    @HttpPost
    global static String doPost() {

        //=============== BEGIN GET THE REQUEST, METHOD, AND BODY
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        Map<String, Object> requestMap;
        Map<String, Object> bodyMap;
        String method;

        List<String> errorList = new List<String>();

        //get / deserialize the request obj
        try {
            requestMap = (Map<String, Object>)JSON.deserializeUntyped(req.requestBody.toString());
            if(requestMap.containsKey('action')){
                return JSON.serialize(BaseController.doAction(string.valueOf(requestMap.get('action')),string.valueOf(requestMap.get('params'))));
            }
        } catch (Exception e) {
            errorList.add('error deserializing request: ' + e.getMessage());
        }

        if (!errorList.isEmpty()) {
            return 'ERROR: ' + String.join(errorList, ', ');
        }
        //=============== END GET THE REQUEST, METHOD, AND BODY


        String sRet = 'unknown error';
        if (!errorList.isEmpty()) {
            return 'ERROR: ' + String.join(errorList, ', ');
        }
        return sRet;
        //=============== END FINAL ERROR HANDLING
    }
}