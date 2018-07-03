<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Claim_AutoNumber</fullName>
        <field>Name</field>
        <formula>&apos;C-&apos; &amp; Autonumber__c</formula>
        <name>Claim - AutoNumber</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Claim - AutoNumber</fullName>
        <actions>
            <name>Claim_AutoNumber</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
