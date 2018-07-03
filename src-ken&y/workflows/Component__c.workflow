<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>ComponentYield</fullName>
        <description>Set component yeild to 100 if null at insert</description>
        <field>Yield__c</field>
        <formula>1</formula>
        <name>ComponentYield</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_CP_Name</fullName>
        <field>Name</field>
        <formula>&apos;CP-&apos; &amp; Autonumber__c</formula>
        <name>Set CP Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>ComponentYield</fullName>
        <actions>
            <name>ComponentYield</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Set component yield to 100 if null at insert</description>
        <formula>ISNULL(Yield__c )</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Component Name</fullName>
        <actions>
            <name>Set_CP_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
