<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Facility_Assignment_Unique</fullName>
        <field>Customer_Facility_Assignment_Unique__c</field>
        <formula>Company__c +&apos;-&apos; +CASESAFEID(Ship_to_Customer__c) +&apos;-&apos; + CASESAFEID(Product_Group__c) +&apos;-&apos; +TEXT( Start_Date__c )</formula>
        <name>Facility Assignment Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Facility_Assignment_Name</fullName>
        <field>Name</field>
        <formula>&apos;FA-&apos; &amp; AutoNumber__c</formula>
        <name>Set Facility Assignment Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Facility Assignment Unique</fullName>
        <actions>
            <name>Facility_Assignment_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Facility Assignment Name</fullName>
        <actions>
            <name>Set_Facility_Assignment_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
