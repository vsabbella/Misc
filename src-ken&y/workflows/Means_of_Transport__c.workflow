<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Means_of_Transport_Unique</fullName>
        <description>Update means of transport unique field.</description>
        <field>Means_of_Transport_Unique__c</field>
        <formula>Name</formula>
        <name>Update Means of Transport Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Means of Transport Unique</fullName>
        <actions>
            <name>Update_Means_of_Transport_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates the unique key with a unique value to prevent duplicates.</description>
        <formula>ISNEW() || ISCHANGED( Name )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
