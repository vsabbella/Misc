<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Primary_Key_Update</fullName>
        <field>Primary_Key__c</field>
        <formula>Company__c &amp; TEXT(Fiscal_Year_Start_Date__c)  &amp;  TEXT(Fiscal_Year_End_Date__c)</formula>
        <name>Primary Key Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Populate primary key on Fiscal Year</fullName>
        <actions>
            <name>Primary_Key_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Fiscal_Year__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>This Rule is created to populate the primary key on the Fiscal Year object</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
