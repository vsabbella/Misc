<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Company_Unique</fullName>
        <description>Company Unique</description>
        <field>Company_Unique__c</field>
        <formula>Name</formula>
        <name>Company Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Company Unique</fullName>
        <actions>
            <name>Company_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Company__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Company Unique</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
