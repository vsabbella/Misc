<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Bin_Unique</fullName>
        <description>Updates the Bin &apos;s unique field.</description>
        <field>Bin_Unique__c</field>
        <formula>Name  +  CASESAFEID(Location__c)</formula>
        <name>Update Bin Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Bin Unique</fullName>
        <actions>
            <name>Update_Bin_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Populates a unique value in the Bin_Unique__c field on BIn__c object.</description>
        <formula>AND(    NOT(ISNULL(Name)),    NOT(ISNULL(Location__c))  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
