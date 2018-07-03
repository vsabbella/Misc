<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_IC_Name</fullName>
        <field>Name</field>
        <formula>&apos;IC-&apos; &amp; Autonumber__c</formula>
        <name>Set IC Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Transaction_Date</fullName>
        <description>Set the transaction date based on the created date of the inventory change record.</description>
        <field>Transaction_Date__c</field>
        <formula>CreatedDate</formula>
        <name>Set Transaction Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Inventory Change Name</fullName>
        <actions>
            <name>Set_IC_Name</name>
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
            <field>Inventory_Change__c.CreatedDate</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Inventory_Change__c.Transaction_Date__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Inventory_Change__c.Finalized__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Set the transaction date based on the created date of the inventory change record.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
