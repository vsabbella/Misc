/**
 * Created by venkata.sabbella on 6/20/20.
 */


public class jsonRegexBuilder {
    public  enum jsontype {
        numbervalue, stringvalue, booleanvalue
    }

    public Static String getRegex(String key, jsontype valuetype) {

        String regexStr = '';
        if (valuetype == jsontype.booleanvalue) {
            regexStr = ': [true|false]+,';
        }
        if (valuetype == jsontype.numbervalue) {
            regexStr = ': \\d.+';
        }
        if (valuetype == jsontype.stringvalue) {
            regexStr = ': \\".+\\",+';
        }
        regexStr = key+regexStr;


        return regexStr;
    }

}