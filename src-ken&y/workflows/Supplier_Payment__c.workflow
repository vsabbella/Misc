<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_SP_Name</fullName>
        <field>Name</field>
        <formula>&apos;SP-&apos; &amp; Autonumber__c</formula>
        <name>Set SP Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Transaction_Date</fullName>
        <description>Set the transaction date based on the date paid for the supplier payment record</description>
        <field>Transaction_Date__c</field>
        <formula>Date_Paid__c</formula>
        <name>Set Transaction Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Supplier Payment Name</fullName>
        <actions>
            <name>Set_SP_Name</name>
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
            <field>Supplier_Payment__c.Date_Paid__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Supplier_Payment__c.Finalized__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Set the transaction date based on the date paid on the supplier payment record.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
