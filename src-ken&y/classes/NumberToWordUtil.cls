public with sharing class NumberToWordUtil {
    
    /** 
     * This is the custom util method which is used only when we need to append cents as 
     * value/100 eg: 50/100 at the end of the number to word convertion
     * The convertion is only done for integer part of the decimal value
     */
    public static string numberToWordsWithDecimal(decimal decNum){
        
        decNum = decNum.setscale(2);
        string valAfterDecimal = '';
        valAfterDecimal = (String.valueof(decNum)).substring(String.valueof(decNum).lastIndexOf('.') + 1);
        integer num = decNum.intValue();
      
        /**
         * Return when supplied number is zero
         */
        if (decNum == 0)
            return 'Zero' + ' and ' +  valAfterDecimal + '/100';
        
        /**
         * Perform the covertion on absolute format of number if negative numeber is supplied
         */
        if (decNum < 0)
            return 'minus ' + numberToWords(Math.Abs(num)) + ' and ' +  valAfterDecimal + '/100';    
        
        return numberToWords(num) + ' and ' +  valAfterDecimal + '/100';
        
    }
    
    /** 
     * The numberToWords can directly be used when we need to convert any integer number to its word format
     * this will work only upto 9 billion as that is the max size that an integer variable can hold.
     * This method recurcively calls itself till whole number is converted to its word representation
     */
    public static string numberToWords(integer num){
        /**
         * Return when supplied number is zero
         */
        if (num == 0)
            return 'Zero';
        
        /**
         * Perform the covertion on absolute format of number if negative numeber is supplied
         */ 
        if (num < 0)
            return 'minus ' + numberToWords(Math.Abs(num));
    
        string words = '';
        
        if ((num / 1000000000) > 0)
        {
            words += numberToWords(num / 1000000000) + ' Billion ';
            num = Math.MOD(num,1000000000);
        }
    
        if ((num / 1000000) > 0)
        {
            words += numberToWords(num / 1000000) + ' Million ';
            num = Math.MOD(num,1000000);
        }
    
        if ((num / 1000) > 0)
        {
            words += numberToWords(num / 1000) + ' Thousand ';
            num = Math.MOD(num,1000);
        }
    
        if ((num / 100) > 0)
        {
            words += numberToWords(num / 100) + ' Hundred ';
            num = Math.MOD(num,100);
        }
    
        if (num > 0)
        {
            /**
             * Uncomment this below code if we need and in between two integer representations
             * eg: 232: Two hundred and thirty two
             * now it would be returned as two hundered thirty two
             */
            //if (words != '')
                //words += 'and ';
    
            List<String> unitsMap = new List<String> { 'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen' };
            List<String> tensMap = new List<String> { 'Zero', 'Ten', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety' };
    
            if (num < 20)
                words += unitsMap[num];
            else
            {
                words += tensMap[num / 10];
                if(Math.MOD(num,10) > 0)
                    words += ' ' + unitsMap[Math.MOD(num,10)];
            }
        }
        
        return words;
}
    
}