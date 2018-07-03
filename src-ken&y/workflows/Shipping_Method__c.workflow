<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Shipping_Method_Unique</fullName>
        <description>Shipping Method Unique</description>
        <field>Shipping_Method_Unique__c</field>
        <formula>Name+&apos;-&apos;+Supplier__c</formula>
        <name>Shipping Method Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Shipping Method Unique</fullName>
        <actions>
            <name>Shipping_Method_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Shipping_Method__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Shipping Method Unique</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
