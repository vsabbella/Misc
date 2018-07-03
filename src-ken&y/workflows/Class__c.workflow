<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Class_Unique</fullName>
        <description>Class Unique</description>
        <field>Class_Unique__c</field>
        <formula>Name</formula>
        <name>Class Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Class Unique</fullName>
        <actions>
            <name>Class_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Class__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Class Unique</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
