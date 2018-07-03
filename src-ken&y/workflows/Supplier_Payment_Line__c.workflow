<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_SP_Line_Name</fullName>
        <field>Name</field>
        <formula>&apos;SPL-&apos; &amp; Autonumber__c</formula>
        <name>Set SP Line Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Supplier_Payment_Line_Subtransaction</fullName>
        <field>Subtransaction_Type__c</field>
        <formula>TEXT(Type__c)</formula>
        <name>Supplier Payment Line - Subtransaction</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Supplier Payment Line Name</fullName>
        <actions>
            <name>Set_SP_Line_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Supplier Payment Line - Subtransaction</fullName>
        <actions>
            <name>Supplier_Payment_Line_Subtransaction</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>(ISNEW() || ISCHANGED( Type__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
