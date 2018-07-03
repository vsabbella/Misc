<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Invoice_Line_Autonumber</fullName>
        <field>Name</field>
        <formula>&apos;INL-&apos; &amp; Autonumber__c</formula>
        <name>Invoice Line - Autonumber</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Invoice Line - Autonumber</fullName>
        <actions>
            <name>Invoice_Line_Autonumber</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>True</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
