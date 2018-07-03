<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Journal_Entry_Status_Closed</fullName>
        <field>Status__c</field>
        <literalValue>Closed</literalValue>
        <name>Journal Entry - Status Closed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Journal_Entry_Status_Open</fullName>
        <field>Status__c</field>
        <literalValue>Open</literalValue>
        <name>Journal Entry - Status Open</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_JE_Name</fullName>
        <field>Name</field>
        <formula>&apos;JE-&apos; &amp; Autonumber__c</formula>
        <name>Set JE Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Journal Entry - Closed on Finalize</fullName>
        <actions>
            <name>Journal_Entry_Status_Closed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Journal_Entry__c.Finalized__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Journal Entry - Open on Unfinalize</fullName>
        <actions>
            <name>Journal_Entry_Status_Open</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Journal_Entry__c.Finalized__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Journal_Entry__c.Status__c</field>
            <operation>notEqual</operation>
            <value>Cancelled</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Journal Entry Name</fullName>
        <actions>
            <name>Set_JE_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
