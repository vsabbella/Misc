/**
 * Created by ryansieve on 4/12/17.
 */

public with sharing class Scale {
    public static void govern(sObject rec){
        govern(new List<sObject>{rec});
    }

    public static void govern(List<sObject> recs){
        //todo - mixed types?
        Schema.SObjectType sObjType = recs.getSObjectType();
        Schema.DescribeSObjectResult sObjDescribe = sObjType.getDescribe();
        string sObjectName = sObjDescribe.getLocalName();
        system.debug(sObjDescribe);
        set<string> refs = new set<string>();
        set<Id> uomIds = new set<Id>();
        set<Id> currencyIds = new set<Id>();
        set<string> numberFields = retrieveSObjectNumberFields(sObjType);
        map<string, Scale__mdt> mScaleFields = new map<string, Scale__mdt>();
        List<Scale__mdt> scales = retrievePrecision(sObjType);
        system.debug(scales);

        for(sObject rec : recs){
            for(Scale__mdt p : scales){
                if(string.isBlank(p.Control_Field_Definition__c) || string.isBlank(p.Field_Definition__c)) continue;
                mScaleFields.put(p.Field_Definition__r.QualifiedAPIName, p);
                try{
                    Schema.DescribeFieldResult iDFR = SchemaUtil.getInstance().retrieveFieldDescribeResult(sObjectName, p.Control_Field_Definition__r.QualifiedAPIName);
                    system.debug(iDFR);
                    if(iDFR.getReferenceTo()[0] == UOM__c.getSObjectType()){
                        uomIds.add(string.valueOf(rec.get(p.Control_Field_Definition__r.QualifiedAPIName)));
                    }else if(iDFR.getReferenceTo()[0] == Currency__c.getSObjectType()){
                        currencyIds.add(string.valueOf(rec.get(p.Control_Field_Definition__r.QualifiedAPIName)));
                    }

                    system.debug(uomIds);
                    system.debug(currencyIds);
                }catch(Exception ex){
                    //there is something wrong with the custom mdt
                    //todo - get angry
                    system.debug('EXCEPTION: ' + ex.getMessage() + ' - ' + ex.getStackTraceString());
                    system.debug(rec);
                    system.debug(p);
                }
            }
        }

        system.debug(refs);
        map<Id, UOM__c> mUOMs = UOM.retrieveUOMs(uomIds);
        map<Id, Currency__c> mCurrencies = new map<Id, Currency__c>();

        for(sObject rec : recs){
            for(string numberField : numberFields){

                //if the field is null - move on, these are not the droids you're looking for
                if(rec.get(numberField) == null) continue;

                Schema.DescribeFieldResult iDFR = SchemaUtil.getInstance().retrieveFieldDescribeResult(sObjectName, numberField);
                integer schemaScale = iDFR.getScale();
                if(mScaleFields.containsKey(numberField)){
                    Scale__mdt p = mScaleFields.get(numberField);
                    try{
                        integer refScale = null;
                        if(string.isBlank(p.Control_Field_Definition__c)){
                            //assign db scale because there is no controlling field...
                            system.debug('assign db scale because there is no controlling field... ' + schemaScale);
                            refScale = schemaScale;
                        }else if(p.Scale__c != null){
                            //assign mdt scale, as long as the schema supports it
                            refScale = integer.valueOf(p.Scale__c);
                            system.debug('assign mdt scale, as long as the schema supports it: ' + refScale);
                        }else if(mUOMs.containsKey((Id)rec.get(p.Control_Field_Definition__r.QualifiedAPIName))){
                            //assign controlling uom scale
                            refScale = integer.valueOf(mUOMs.get((Id)rec.get(p.Control_Field_Definition__r.QualifiedAPIName)).Scale__c);
                            if(refScale == null){
                                refScale = schemaScale;
                            }
                            system.debug('assign controlling uom scale: ' + refScale);
                        }else if(mCurrencies.containsKey((Id)rec.get(p.Control_Field_Definition__r.QualifiedAPIName))){
                            refScale = integer.valueOf(mCurrencies.get((Id)rec.get(p.Control_Field_Definition__r.QualifiedAPIName)).Scale__c);
                            if(refScale == null){
                                refScale = schemaScale;
                            }
                            system.debug('assign controlling currency scale: ' + refScale);
                        }else{
                            refScale = schemaScale;
                        }

                        integer scale = (schemaScale < refScale && refScale != null) ? schemaScale : refScale;
                        system.debug('rec: ' + rec);
                        system.debug('field: ' + p.Field_Definition__r.QualifiedAPIName);
                        system.debug('control: ' + p.Control_Field_Definition__r.QualifiedAPIName);
                        system.debug('scale: ' + scale);
                        rec.put(p.Field_Definition__r.QualifiedAPIName, decimal.valueOf(string.valueOf(rec.get(p.Field_Definition__r.QualifiedAPIName))).setScale(scale, System.RoundingMode.HALF_EVEN));

                    }catch(Exception ex){
                        //there is something wrong with the custom mdt
                        //todo - get angry
                        system.debug('PRECISION EXCEPTION: ' + ex.getMessage() + ' - ' + ex.getStackTraceString());
                        throw ex;
                    }
                }else{
                    system.debug('mScaleFields: ' + mScaleFields);
                    system.debug('assign db scale because there is no additional metadata for ' + numberField + ': ' + schemaScale);
                    rec.put(numberField, decimal.valueOf(string.valueOf(rec.get(numberField))).setScale(schemaScale, System.RoundingMode.HALF_EVEN));
                }
            }
        }
    }

    private static map<Schema.sObjectType, set<string>> mSObjectNumberFields = new map<Schema.sObjectType, set<string>>();
    public static set<string> retrieveSObjectNumberFields(Schema.sObjectType sObjType){
        if(!mSObjectNumberFields.containsKey(sObjType)){
            Schema.DescribeSObjectResult sObjDescribe = sObjType.getDescribe();
            string sObjectName = sObjDescribe.getLocalName();
            set<string> numberFields = new set<string>();
            for(string fieldName : sObjDescribe.fields.getMap().keySet()){
                Schema.DescribeFieldResult iDFR = SchemaUtil.getInstance().retrieveFieldDescribeResult(sObjectName, fieldName);
                if(iDFR.getType() == Schema.DisplayType.DOUBLE
                        && iDFR.isUpdateable()){
                    numberFields.add(iDFR.getLocalName());
                }
            }
            mSObjectNumberFields.put(sObjType, numberFields);
        }
        return mSObjectNumberFields.get(sObjType);
    }

    private static map<Schema.sObjectType, list<Scale__mdt>> mSObjectScales = new map<Schema.sObjectType, list<Scale__mdt>>();
    public static list<Scale__mdt> retrievePrecision(Schema.sObjectType sObjType){
        if(!mSObjectScales.containsKey(sObjType)){
            mSObjectScales.put(sObjType, [SELECT Id, Label, NamespacePrefix, DeveloperName, Entity_Definition__c, Entity_Definition__r.QualifiedAPIName,
                    Scale__c, Field_Definition__c, Field_Definition__r.QualifiedAPIName,
                    Control_Field_Definition__c, Control_Field_Definition__r.QualifiedAPIName
            FROM Scale__mdt
            WHERE Entity_Definition__r.QualifiedAPIName = :sObjType.getDescribe().getName()]);
        }
        return mSObjectScales.get(sObjType);
    }
}