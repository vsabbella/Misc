<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Is_Facility_Cost</fullName>
        <field>Facility_Cost__c</field>
        <formula>&apos;FALSE&apos;</formula>
        <name>Is Facility Cost</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Item_Cost_Unique</fullName>
        <description>Item Cost Unique</description>
        <field>Item_Cost_Unique__c</field>
        <formula>&apos;FALSE&apos;</formula>
        <name>Item Cost Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Item_Cost_Name</fullName>
        <description>Update Item Cost Name</description>
        <field>Name</field>
        <formula>Item__r.Name</formula>
        <name>Update Item Cost Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Standard_Cost</fullName>
        <description>Update Standard Cost</description>
        <field>Standard_Cost__c</field>
        <formula>Material_Cost__c +
IF (ISNULL(Labor_Cost__c), 0, Labor_Cost__c) +
IF (ISNULL(Outside_Processing_Cost__c), 0, Outside_Processing_Cost__c) +
IF (ISNULL(Overhead_Cost__c), 0, Overhead_Cost__c)</formula>
        <name>Update Standard Cost</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Is Facility Cost</fullName>
        <actions>
            <name>Is_Facility_Cost</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>TRUE</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Item Cost Unique</fullName>
        <actions>
            <name>Item_Cost_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Item_Cost__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Item Cost Unique</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update Item Cost Name</fullName>
        <actions>
            <name>Update_Item_Cost_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Item__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Update Item Cost Name</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update Standard Cost</fullName>
        <actions>
            <name>Update_Standard_Cost</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Item__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Update Standard Cost</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
