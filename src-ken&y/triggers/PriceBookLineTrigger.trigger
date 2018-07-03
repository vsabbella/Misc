trigger PriceBookLineTrigger on Pricebook_Line__c (before insert, before update, after update, before delete) {

    if(DML.checkTriggerDispatch(Pricebook_Line__c.getSobjectType())){return;}    // OTC-827

    Date today = System.today();
    // KNDY-3687     
    if (Trigger.isBefore && Trigger.isInsert) {
        for (Pricebook_Line__c pbl : Trigger.new) {
            // clear sub price fields to get best one from Brackets 
            PricebookService.clearSubPriceFields(pbl);
        }
    }


    //OTC-421 / OTC-481
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        //round the price field to the appropriate precision
        PricebookService.roundPrice(Trigger.new);
    }
    
    // KNDY-3687 / KNDY-3296 / OTC-484
    PriceBookService.expireLines();
    
    // KNDY 2125
    PriceBookService.populateBrackets();

    // insert cloned lines after update
    PriceBookService.insertClonedLines();

    // before delete
    PriceBookService.checkActiveBeforeDelete();  // prevent delete on active pricebook lines
}