<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Budget_Line_Unique</fullName>
        <field>Budget_Line_Unique__c</field>
        <formula>ExtId__c</formula>
        <name>Budget Line Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Budget_Line_Name</fullName>
        <field>Name</field>
        <formula>&quot;BL-&quot; &amp; Autonumber__c</formula>
        <name>Set Budget Line Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Budget Line Unique</fullName>
        <actions>
            <name>Budget_Line_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Budget Line Name</fullName>
        <actions>
            <name>Set_Budget_Line_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
