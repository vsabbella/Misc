<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>ECO_Unique</fullName>
        <description>ECO Unique</description>
        <field>ECO_Unique__c</field>
        <formula>Name</formula>
        <name>ECO Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>ECO Unique</fullName>
        <actions>
            <name>ECO_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>ECO__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>ECO Unique</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
