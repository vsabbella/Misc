<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Invoice_Autonumber</fullName>
        <field>Name</field>
        <formula>&apos;INV-&apos; &amp; Autonumber__c</formula>
        <name>Invoice - Autonumber</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Invoice_Amt</fullName>
        <field>Invoice_Amount__c</field>
        <formula>Total_Line_Amount__c</formula>
        <name>Update Invoice Amt</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Invoice - Autonumber</fullName>
        <actions>
            <name>Invoice_Autonumber</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>True</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Line Amount Changed</fullName>
        <actions>
            <name>Update_Invoice_Amt</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED(Total_Line_Amount__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
