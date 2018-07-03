<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_RT_Name</fullName>
        <field>Name</field>
        <formula>&apos;RT-&apos; &amp; Autonumber__c</formula>
        <name>Set RT Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Transit_Route_Primary_Unique</fullName>
        <field>Transit_Route_Primary_Unique__c</field>
        <formula>IF(Primary__c = true, 
   &apos;true&apos; + CASESAFEID(Origin__c) + CASESAFEID(Destination__c),
   &apos;&apos;)</formula>
        <name>Transit Route Primary Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Transit Route Name</fullName>
        <actions>
            <name>Set_RT_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Transit Route Primary Unique</fullName>
        <actions>
            <name>Transit_Route_Primary_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISNEW() || ISCHANGED( Primary__c ) || ISCHANGED( Origin__c ) || ISCHANGED( Destination__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
