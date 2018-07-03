<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Allocation_Profile_Unique</fullName>
        <field>Unique__c</field>
        <formula>CASESAFEID(Company__c) + CASESAFEID(Item__c)</formula>
        <name>Set Allocation Profile Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Allocation Profile Create Edit</fullName>
        <actions>
            <name>Set_Allocation_Profile_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>