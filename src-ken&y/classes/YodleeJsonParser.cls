public with sharing class YodleeJsonParser extends JSONImprovedSerializer{
	public static YodleeJsonParser jsonParser {get; private set;}

    static {
        jsonParser = new YodleeJsonParser();  
    }

    private YodleeJsonParser() {
        //setup mappings for reserve words in apex
        super(
            new Map<String,String>{
                'currencyCode' => 'currency',   
                'valueField'  => 'value',
                'transactionWrapper' => 'transaction',
                'countValue' => 'count'   
            }
        );
        //turn off null serialization
        setSerializeNulls(false);   
    }
    
    public static string ParseJsonToken(JSonParser parser,String queryToken){
        String retToken='';
        while (parser.nextToken() != JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != JSONToken.VALUE_NULL ) {
                    if (text == queryToken) {   //'sessionToken'
                        retToken = parser.getText();//cobrandSessionToken
                    } else {
                    }
                }
            }
        }
        return retToken ;            
    }
}