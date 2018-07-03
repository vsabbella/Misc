<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>setAssetTagNumber</fullName>
        <description>Automate Assignment of Asset Tag Number to ID of the record</description>
        <field>Asset_Tag_Number__c</field>
        <formula>Id</formula>
        <name>setAssetTagNumber</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>PopulateAssetTagNumber</fullName>
        <actions>
            <name>setAssetTagNumber</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Fixed_Asset__c.Asset_Tag_Number__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Automate Assignment of Asset Tag Number as per KNDY-10884.
As a Fixed Assets Accountant, every time I enter a new fixed asset into the system,System needs to  copy the Salesforce ID and paste the ID to Asset Tag Number</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
