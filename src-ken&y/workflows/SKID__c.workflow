<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>MRP_Demand_field_update</fullName>
        <field>Is_Demand__c</field>
        <literalValue>1</literalValue>
        <name>MRP Demand field update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>MRP_Nettable_field_update</fullName>
        <description>MRP Nettable</description>
        <field>MRP_Nettable__c</field>
        <literalValue>1</literalValue>
        <name>MRP Nettable field update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>MRP_Non_Nettable_field_update</fullName>
        <description>SKID not used in MRP</description>
        <field>MRP_Nettable__c</field>
        <literalValue>0</literalValue>
        <name>MRP Non Nettable field update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>MRP_Supply_field_update</fullName>
        <field>Is_Demand__c</field>
        <literalValue>0</literalValue>
        <name>MRP Supply field update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_SKID_Name</fullName>
        <field>Name</field>
        <formula>&apos;SKID-&apos; &amp; Autonumber__c</formula>
        <name>Set SKID Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>MRP Demand</fullName>
        <actions>
            <name>MRP_Demand_field_update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Make the SKID an MRP demand</description>
        <formula>false</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>MRP Nettable</fullName>
        <actions>
            <name>MRP_Nettable_field_update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Used to update the MRP Nettable field, to determine whether the SKID should be used in MRP calculation or not.</description>
        <formula>false</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>MRP Non Nettable</fullName>
        <actions>
            <name>MRP_Non_Nettable_field_update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Used to update the MRP Nettable field, to determine whether the SKID should be used in MRP calculation or not.</description>
        <formula>false</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>MRP Supply</fullName>
        <actions>
            <name>MRP_Supply_field_update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>makes a SKID supply for the MRP</description>
        <formula>false</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set SKID Name</fullName>
        <actions>
            <name>Set_SKID_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
