<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Reason_Code_Unique</fullName>
        <description>Reason Code Unique</description>
        <field>Reason_Code_Unique__c</field>
        <formula>TEXT(Type__c) + &quot;_&quot; + Company__c + &quot;_&quot; + Name</formula>
        <name>Reason Code Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Reason Code Unique</fullName>
        <actions>
            <name>Reason_Code_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Reason_Code__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Reason Code Unique</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
