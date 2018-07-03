<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UOM_Unique</fullName>
        <description>UOM Unique</description>
        <field>UOM_Unique__c</field>
        <formula>Name</formula>
        <name>UOM Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>updateuom</fullName>
        <description>Default to uppercase</description>
        <field>Name</field>
        <formula>UPPER(Name)</formula>
        <name>Update UOM</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>UOM Unique</fullName>
        <actions>
            <name>UOM_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>UOM__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>UOM Unique</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Upper case</fullName>
        <actions>
            <name>updateuom</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Change the value to upper case</description>
        <formula>IF(UPPER( Name )!=Name, TRUE,FALSE)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
