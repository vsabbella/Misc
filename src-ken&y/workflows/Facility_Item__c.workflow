<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Facility_Item_Unique</fullName>
        <field>Facility_Item_Unique__c</field>
        <formula>CASESAFEID(Item__c) +&apos;-&apos; +CASESAFEID(Company__c) +&apos;-&apos; +CASESAFEID(Facility__c)</formula>
        <name>Facility Item Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Facility Item Unique</fullName>
        <actions>
            <name>Facility_Item_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
