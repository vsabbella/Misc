public with sharing class ServiceRouter {
    
	public static ServiceResponse route(ServiceRequest serviceRequest){
    	
    	String requestHandlerName = mRoutes.get(serviceRequest.actionName);
    	
    	if(String.isBlank(requestHandlerName)){
    		ServiceResponse serviceResponse = new ServiceResponse();
    		serviceResponse.isSuccess = false;
    		serviceResponse.addErrorMessage('Process not supported yet.');
    		return serviceResponse;
    	}
    	
    	System.Type requestHandlerType = Type.forName(requestHandlerName);
    	ServiceRequestHandler requestHandlerClass = (ServiceRequestHandler) requestHandlerType.newInstance();
    	
    	return requestHandlerClass.handleRequest(serviceRequest);
    }

	private static map<string, string> mRoutes = new map<string, string>{
		'Pick Shipment Line' => 'ShipmentLineService',
		'UndoPick Shipment Line' => 'ShipmentLineService',
		'Cycle Count' => 'InventoryChangeService'
			//todo - more...
	};
	
	/* Use to override the default in future.
    public static void register(String requestType, String serviceName){
    	mRoutes.put(requestType, serviceName);
    }*/
}