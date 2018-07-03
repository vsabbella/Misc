<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Bank_Transaction_Match_Name</fullName>
        <field>Name</field>
        <formula>&apos;BTM-&apos; &amp; Autonumber__c</formula>
        <name>Set Bank Transaction Match Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Assign Bank Transaction Match Name</fullName>
        <actions>
            <name>Set_Bank_Transaction_Match_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
