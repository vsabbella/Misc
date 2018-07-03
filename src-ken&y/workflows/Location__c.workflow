<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Location_Facility_Unique</fullName>
        <description>Update location unique field</description>
        <field>Location_Facility__c</field>
        <formula>Name &amp;&quot;-&quot;&amp; Facility__r.Name &amp;&quot;-&quot;&amp; Facility__r.Company__r.Name</formula>
        <name>Location Facility Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Location Facility Unique</fullName>
        <actions>
            <name>Location_Facility_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Update the name field and check for duplicate</description>
        <formula>OR(ISNEW(), ISCHANGED(Facility__c),  ISCHANGED(Name))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
