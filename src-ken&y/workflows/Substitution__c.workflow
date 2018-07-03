<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_product_substitution_index</fullName>
        <description>Populate the index on the product substitution record.</description>
        <field>Product_Selection_Index__c</field>
        <formula>CASESAFEID(Facility__c) + 
CASESAFEID(Customer__c) +  
CASESAFEID(Current_Product__c)</formula>
        <name>Update product substitution index</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set production selection index</fullName>
        <actions>
            <name>Update_product_substitution_index</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets the index for the substitution records to find it easily.</description>
        <formula>NOT(ISNULL(Current_Product__c))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
