<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Pick_Sort_Unique_Key</fullName>
        <description>Priority-Company-Customer combination</description>
        <field>Unique_Key__c</field>
        <formula>TEXT( Sort_Priority__c )  &amp; &apos;-&apos; &amp;  Company__c &amp; &apos;-&apos; &amp;  Customer__c</formula>
        <name>Set Pick Sort Unique Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Unique Key</fullName>
        <actions>
            <name>Set_Pick_Sort_Unique_Key</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>sets the unique key for pick sort criteria</description>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
