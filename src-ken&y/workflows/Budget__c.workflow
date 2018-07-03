<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Budget_Current_Check</fullName>
        <field>Current_Check__c</field>
        <formula>IF( Current_Working_Budget__c , CASESAFEID(Company__c), CASESAFEID(Company__c) +Autonumber__c)</formula>
        <name>Budget Current Check</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Budget_Name</fullName>
        <field>Name</field>
        <formula>&quot;B-&quot; &amp; Autonumber__c</formula>
        <name>Set Budget Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Budget Current Check</fullName>
        <actions>
            <name>Budget_Current_Check</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>TRUE</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Budget Name</fullName>
        <actions>
            <name>Set_Budget_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
