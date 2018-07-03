<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Pricebook_Is_Default_Unique</fullName>
        <description>Creates a unique value for a Pricebook using combination of Default flag and Company</description>
        <field>Pricebook_Default_Unique__c</field>
        <formula>IF(Default__c,  Company__c + Currency__c + &apos;1&apos;, null)</formula>
        <name>Update Pricebook Is Default Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Pricebook_Unique</fullName>
        <description>Update the Pricebook_Unique__c with a unique combination of two fields i.e. Name + Company</description>
        <field>Pricebook_Unique__c</field>
        <formula>Name + Company__c</formula>
        <name>Update Pricebook Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Pricebook Unique</fullName>
        <actions>
            <name>Update_Pricebook_Is_Default_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Pricebook_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Pricebook__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Populates Pricebook_Unique__c field on Pricebook__c object with a unique value.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
