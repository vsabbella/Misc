<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_OP_Name</fullName>
        <field>Name</field>
        <formula>&quot;OP-&quot; + Autonumber__c</formula>
        <name>Set OP Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_OP_Unique</fullName>
        <field>Unique__c</field>
        <formula>CASESAFEID(Work_Order__c) + TEXT(Sequence__c)</formula>
        <name>Set OP Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>OP Create</fullName>
        <actions>
            <name>Set_OP_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>OP Create Edit</fullName>
        <actions>
            <name>Set_OP_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
