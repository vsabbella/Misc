<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Routing_Unique</fullName>
        <field>Assembly_Item_Specification_Sequence__c</field>
        <formula>CASESAFEID(Assembly_Item_Specification__c) +&apos;-&apos; + TEXT(Resource_Sequence__c)</formula>
        <name>Routing Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_RT_Name</fullName>
        <field>Name</field>
        <formula>&apos;RT-&apos; &amp; Autonumber__c</formula>
        <name>Set RT Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Routing Unique</fullName>
        <actions>
            <name>Routing_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Routing Name</fullName>
        <actions>
            <name>Set_RT_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
