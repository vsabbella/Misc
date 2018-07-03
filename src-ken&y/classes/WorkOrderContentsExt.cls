public class WorkOrderContentsExt {
   public String completeCases { get; private set; } 
   public String missingCases { get; private set; } 
   public Integer totalMissingCases { get; private set; } 
    public WorkOrderContentsExt(ApexPages.StandardController con) {
        Work_Order__c wo;
        SOQLUtil woQuery = new SOQLUtil('Work_Order__c');
        woQuery.addAllCustomFields();
        woQuery.setWhereClause('Id = \'' + con.getId() + '\'');
        woQuery.setLimit(1);
        try {
            wo = (Work_Order__c)Database.query(woQuery.getQuery());
        } catch (Exception e) {
            throw new WorkOrderContentException(Label.Invalid_work_order_Id);
        }
        Set<String> contents = new Set<String>();
        String contentString = wo.Contents__c;
        if(!String.isBlank(contentString)){
            contents = new Set<String>(contentString.split(','));
        }
        List<Integer> caseNumbers = new List<Integer>();
        for(String content : contents){
           caseNumbers.add(Integer.valueOf(content));
        }
        caseNumbers.sort();
        if(caseNumbers.size() > 0){
           completeCases =  getCompletedCases(caseNumbers);
           missingCases =   getMissingCases(caseNumbers); 
        }
        Set<String> missingContents = new Set<String>();
        if(!String.isBlank(missingCases )){
            missingContents = new Set<String>(missingCases.split(','));
            totalMissingCases = missingContents.size();  
        }
        
    }
    
    public static String getCompletedCases(List<Integer> caseNumbers){
       string completeCases ;
       string singleSubset ;  
       Integer minNumber ;
       set<string> subsetOfNumbers = new set<string>();
       minNumber= caseNumbers[0];
       for(Integer i = 1; i< caseNumbers.size(); i++){
           if(caseNumbers[i] - caseNumbers[i-1] > 1){
               if(String.valueOf(minNumber) == String.valueOf(caseNumbers[i-1]) ){
                  singleSubset = String.valueOf(minNumber); 
               }else {
                  singleSubset = String.valueOf(minNumber)+'-'+String.valueOf(caseNumbers[i-1]) ; 
               }
               subsetOfNumbers.add(singleSubset);  
               minNumber= caseNumbers[i];
           }
       }
       //checks the last one in list it could be single or range of numbers.
      if(minNumber == caseNumbers[caseNumbers.size()-1]){
         singleSubset = String.valueOf(minNumber) ;
         subsetOfNumbers.add(singleSubset);
        } else{
            singleSubset = String.valueOf(minNumber)+'-'+String.valueOf(caseNumbers[caseNumbers.size()-1]) ; 
            subsetOfNumbers.add(singleSubset);
        }
       for(string str:subsetOfNumbers){
           if(completeCases == null){
               completeCases = str;
           }else {
              completeCases = completeCases +','+str ;  
           }
        }
       return completeCases;
    }
    public static String getMissingCases( List<Integer> caseNumbers){
       string missingCases ;
      
       List<String> missingNumberList = new List<String>();
        for(Integer i = 1; i< caseNumbers.size(); i++){
            Integer diff = caseNumbers[i] - caseNumbers[i-1] ;
            for( Integer j = 1 ; j < diff  ; j++ ){
                Integer missingNumber =caseNumbers[i-1]+j;
                missingNumberList.add((String.valueOf(missingNumber)));
            }
        } 
        if(!missingNumberList.isEmpty()){
         for(String str:missingNumberList){  
             if(missingCases == null){
                 missingCases = str;
             } else {
                missingCases = missingCases +','+ str;  
             }
         }
        }
        
       return missingCases;
    }

    private class WorkOrderContentException extends Exception { }
}