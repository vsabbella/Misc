<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_OL_Name</fullName>
        <field>Name</field>
        <formula>&apos;OL-&apos; &amp; Autonumber__c</formula>
        <name>Set OL Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Order Line Name</fullName>
        <actions>
            <name>Set_OL_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>sets the order line name</description>
        <formula>TRUE</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
