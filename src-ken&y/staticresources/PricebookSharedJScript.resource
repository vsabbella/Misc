// Used in two Pages: PricebookRelatedList and PricebookLineUpdate
// returns all price fields i.e. Price__c to Price_N__c
 function getAllPriceFields (rec) {
     var priceFields = new Array();
     for (var key in rec) {
         if(! rec.hasOwnProperty( key ) )  continue;
         if (/Price_?\d?__c$/i.test(key) == false) continue;
         priceFields.push(key);
     }

     return priceFields;
 }

 // returns the search box value
 function getSearchVal () {
     return $(getKendoGridDomId()).find('.gridsearchcommand').val();
 }

 // converts date in compatible format for passing to VF remoting
 function vfRemotingDateString(mydate){
     if (!mydate) return null;
     var d = mydate.getDate();
     var m = mydate.getMonth()+1;
     var y = mydate.getFullYear();
     return ''+ (m<=9?'0'+m:m) +'/' + (d<=9?'0'+d:d)+'/' + y;
 }

 // Gives handle to the grid object
 function getKendoGridObject() {
     return $(getKendoGridDomId()).data("kendoGrid");
 }

 function getCurrentGridData(pbGrid) {
     var searchVal = getSearchVal();
     var currentData; // searched data or whole grid data
     if (searchVal) {
         currentData = pbGrid.dataSource.view();
     } else {
         currentData = pbGrid.dataSource.data();
     }
     return currentData;
 }

 /*
     Called by EDIT event on Kendo GRID. This will add 5 years to the end date of pricebook line
 */
 function onAddNewRow(e) {
     // Abhinav: renamed from Effective_End_Date__c to End_Date__c (KNDY4171)
     var edFldName = 'End_Date__c';


     if (e.model.isNew()) {

         // set min and max to null values instead of 0.
         if (!e.model.dirty){

             e.model.set('Use_Fixed_Pricing__c',true);
             e.model.set('Price_Type__c','Sales');
         }


         var ed = e.model.get(edFldName);
         if (ed && ed.getFullYear() == new Date().getFullYear() ) {
             // Increment end date by 5 years
             var newED = new Date();
             newED.setFullYear(ed.getFullYear() + 5);
             e.model.set(edFldName, newED);
             e.sender.refresh();
         }
     }


     if (e.model.get('Use_Fixed_Pricing__c') == true){
         e.model.set('Min__c', null);
         e.model.set('Max__c', null);
     }
 }


