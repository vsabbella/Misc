<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Work_Center_Unique</fullName>
        <description>Work Center Unique</description>
        <field>Work_Center_Unique__c</field>
        <formula>Name +&apos;-&apos; +Company__c +&apos;-&apos; +CASESAFEID(Facility__c)</formula>
        <name>Work Center Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Work Center Unique</fullName>
        <actions>
            <name>Work_Center_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Work Center Unique</description>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
