<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Customer_Receipt_Line_Subtransaction</fullName>
        <field>Subtransaction_Type__c</field>
        <formula>TEXT(Type__c)</formula>
        <name>Customer Receipt Line - Subtransaction</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_CR_Line_Name</fullName>
        <field>Name</field>
        <formula>&apos;CRL-&apos; &amp; Autonumber__c</formula>
        <name>Set CR Line Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Customer Receipt Line - Subtransaction</fullName>
        <actions>
            <name>Customer_Receipt_Line_Subtransaction</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>(ISNEW() || ISCHANGED( Type__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Customer Receipt Line Name</fullName>
        <actions>
            <name>Set_CR_Line_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
