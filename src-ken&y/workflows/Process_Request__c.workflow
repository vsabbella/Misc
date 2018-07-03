<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Process_Request_External_Id</fullName>
        <field>ExtId__c</field>
        <formula>Target_Document_Id__c + TEXT(Process_Call__c) + TEXT(Status__c) + Parameter_Name__c +  Parameter_Value__c</formula>
        <name>Set Process Request External Id</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Process Request Unique</fullName>
        <actions>
            <name>Set_Process_Request_External_Id</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
