<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_SH_Name</fullName>
        <field>Name</field>
        <formula>&apos;SH-&apos; &amp; Autonumber__c</formula>
        <name>Set SH Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Transaction_Date</fullName>
        <description>Set the transaction date based on the date shipped on the shipment record.</description>
        <field>Transaction_Date__c</field>
        <formula>Date_Shipped__c</formula>
        <name>Set Transaction Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Shipment_Finalized</fullName>
        <description>Set the shipment finalized flag to true when the shipment status is confirmed</description>
        <field>Finalized__c</field>
        <literalValue>1</literalValue>
        <name>Shipment Finalized</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Finalize Shipment</fullName>
        <actions>
            <name>Shipment_Finalized</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>false</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Shipment Name</fullName>
        <actions>
            <name>Set_SH_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Transaction Date</fullName>
        <actions>
            <name>Set_Transaction_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Shipment__c.Date_Shipped__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Shipment__c.Finalized__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Set the transaction date based on the date shipped on the shipment</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
