<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Stock_Movement_Unique_Key</fullName>
        <description>Priority-Rule Type-Source Document combination</description>
        <field>Unique_Key__c</field>
        <formula>TEXT(Priority__c) &amp; &apos;-&apos; &amp; TEXT(Rule_Type__c) &amp; &apos;-&apos; &amp; TEXT(Source_Document__c) &amp; &apos;-&apos; &amp;  Company__c &amp; &apos;-&apos; &amp;  CASESAFEID(Facility__c)</formula>
        <name>Set Stock Movement Unique Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Unique Key</fullName>
        <actions>
            <name>Set_Stock_Movement_Unique_Key</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>sets the unique key for stock movement rules.</description>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
