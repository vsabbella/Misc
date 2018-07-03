//class will be used in two areas
// 1: maps JSON props to class props
// 2: remove null values from serialized strings
// 
//NOTE: For mapping it is VERY important that the new class prop
// does not exsist anywhere else in the JSON
public abstract class JSONImprovedSerializer {
	private Map<String,String> mapKeys;

    private boolean serializeNulls = true;

    /* SETUP METHODS */
    //constructor
    protected JSONImprovedSerializer(Map<String,String> mapping){
        this.mapKeys = mapping;
    }

    //use to set how nulls are serialized.
    // Set false to remove nulls from string.
    public void setSerializeNulls(boolean b){
        this.serializeNulls = b;
    }

    public String serialize(Object obj){
        String retString = JSON.serialize(obj);
        retString = transformStringForSerilization(retString);
        if(!serializeNulls){
            retString = removeNullsFromJSON(retString);
        }
        return retString;
    }

    public Object deserialize(String jsonString, System.Type type){
        jsonString = transformStringForDeserilization(jsonString);
        system.debug('type='+ type +'jsonString='+jsonString);
        return JSON.deserialize(jsonString, type);
    }

    private String transformStringForSerilization(String s){
        return replaceAll(s, mapKeys);
    }

    private String transformStringForDeserilization(String s){
        Map<String,String> flippedMap = new Map<String,String>();
        for(String key : mapKeys.keySet()){
            flippedMap.put(mapKeys.get(key), key);
        }
        system.debug('transformStringForDeserilization=S='+ s +'flippedMap='+flippedMap);
        return replaceAll(s, flippedMap);
    }

    private String removeNullsFromJSON(String s){
    	system.debug('called removeNullsFromJSON');
        return s.replaceAll('("[\\w]*":null,)|(,?"[\\w]*":null)','');
    }

    private String replaceAll(String s, Map<String,String> toFromMap){
        for(String key : toFromMap.keySet()){
            s = s.replaceAll('"'+key+'":', '"'+toFromMap.get(key)+'":');
        }
        return s;
    }
}