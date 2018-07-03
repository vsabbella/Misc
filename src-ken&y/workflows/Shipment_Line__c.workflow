<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_SHL_Name</fullName>
        <field>Name</field>
        <formula>&apos;SHL-&apos; &amp; Autonumber__c</formula>
        <name>Set SHL Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Shipment_Line_Subtransaction</fullName>
        <field>Subtransaction_Type__c</field>
        <formula>TEXT(Product__r.Item__r.Class__r.Type__c)</formula>
        <name>Shipment Line - Subtransaction</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Inventory Transaction - Subtransaction</fullName>
        <actions>
            <name>Shipment_Line_Subtransaction</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>(ISNEW() ||  ISCHANGED( Product__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Shipment Line Name</fullName>
        <actions>
            <name>Set_SHL_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
