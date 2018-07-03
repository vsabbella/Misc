<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Work_Center_Resource</fullName>
        <field>Work_Center_Resource_Unique__c</field>
        <formula>Name +&apos;-&apos; +Company__c +&apos;-&apos; +CASESAFEID(Facility__c) +&apos;-&apos; +CASESAFEID(Work_Center__c) +&apos;-&apos; +CASESAFEID(Resource__c)</formula>
        <name>Work Center Resource</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Work Center Resource Unique</fullName>
        <actions>
            <name>Work_Center_Resource</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
