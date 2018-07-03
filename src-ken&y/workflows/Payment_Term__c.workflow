<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Payment_Term_Unique</fullName>
        <description>Payment Term Unique</description>
        <field>Payment_Term_Unique__c</field>
        <formula>Name</formula>
        <name>Payment Term Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Payment Term Unique</fullName>
        <actions>
            <name>Payment_Term_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Payment_Term__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Payment Term Unique</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
