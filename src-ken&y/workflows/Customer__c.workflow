<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Customer_Unique</fullName>
        <field>Customer_Unique__c</field>
        <formula>Name +&apos;-&apos; +Company__c+&apos;-&apos; +RecordTypeId+&apos;-&apos; +  CASESAFEID (Top_Parent_Customer__c)</formula>
        <name>Customer Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Customer Unique</fullName>
        <actions>
            <name>Customer_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Customer__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Customer Unique</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
