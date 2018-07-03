<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Resource_Unique</fullName>
        <field>Resource_Unique__c</field>
        <formula>Name +&apos;-&apos; +Company__c +&apos;-&apos; + CASESAFEID(Facility__c)</formula>
        <name>Resource Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Resource Unique</fullName>
        <actions>
            <name>Resource_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
