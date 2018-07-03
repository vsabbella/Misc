<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Bank_Transaction_Group_Name</fullName>
        <field>Name</field>
        <formula>&apos;BTG-&apos;&amp;Autonumber__c</formula>
        <name>Set Bank Transaction Group Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Assign Bank Transaction Group Name</fullName>
        <actions>
            <name>Set_Bank_Transaction_Group_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
