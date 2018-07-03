<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Claim_Line_Autonumber</fullName>
        <field>Name</field>
        <formula>&apos;CL-&apos; &amp; Autonumber__c</formula>
        <name>Claim Line - Autonumber</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Claim Line - Autonumber</fullName>
        <actions>
            <name>Claim_Line_Autonumber</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
