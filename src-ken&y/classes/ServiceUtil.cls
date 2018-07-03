public with sharing class ServiceUtil {
	
	public static Object getParameters(Object paramObject, String parameterType){
		return JSON.deserialize(JSON.serialize(paramObject), Type.forName('List<' + parameterType + '>'));
	}   
}