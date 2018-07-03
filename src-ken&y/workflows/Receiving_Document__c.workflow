<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>SetFinalizedFlag</fullName>
        <description>Sets the finalized flag on the Receiving Document</description>
        <field>Finalized__c</field>
        <literalValue>1</literalValue>
        <name>SetFinalizedFlag</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_RD_Name</fullName>
        <field>Name</field>
        <formula>&apos;RD-&apos; &amp; Autonumber__c</formula>
        <name>Set RD Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Transaction_Date</fullName>
        <description>Set the transaction date based on the date received on the receiving document</description>
        <field>Transaction_Date__c</field>
        <formula>Date_Received__c</formula>
        <name>Set Transaction Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Receiving Document Name</fullName>
        <actions>
            <name>Set_RD_Name</name>
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
            <field>Receiving_Document__c.Date_Received__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Receiving_Document__c.Transaction_Date__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Receiving_Document__c.Finalized__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Set the transaction date based on the date received of the receiving document.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>SetFinalizedFlag</fullName>
        <actions>
            <name>SetFinalizedFlag</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Receiving_Document__c.Status__c</field>
            <operation>equals</operation>
            <value>Closed</value>
        </criteriaItems>
        <description>Set the finalized flag to true when the header is closed</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
