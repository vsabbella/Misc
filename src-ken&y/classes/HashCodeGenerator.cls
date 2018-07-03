public with sharing class HashCodeGenerator {
	
	public static integer getHashCode(object obj){
            
        Map<string, integer> vals = new Map<string, integer>{'0' => 0, '1' => 1, '2' => 2, '3' => 3, '4' => 4, '5' => 5, '6' => 6, '7' => 7, '8' => 8, '9' => 9, 'A' => 10, 'B' => 11, 'C' => 12, 'D' => 13, 'E' => 14, 'F' => 15};
        
        string objJS = JSON.serialize(obj);
        Blob b = Blob.valueOf(objJS);
        Blob bHash = Crypto.generateMac('hmacSHA1', b, blob.valueOf('Kenandy'));
        string objHex = EncodingUtil.convertToHex(bHash);
 
        long hash = long.valueOf('2166136261');
        long prime = long.valueOf('16777619');
        
        for(string s : objHex.toUpperCase().split('')){
            if(string.isEmpty(s))
                continue;
            hash = ((hash ^ vals.get(s)) * prime);
        }
        
        return (integer)hash;   
    }
    
}