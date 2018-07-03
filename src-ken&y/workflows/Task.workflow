<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Task_Primary_Key</fullName>
        <description>Update the primary key of the task record.</description>
        <field>Primary_Key__c</field>
        <formula>IF(
   (ISPICKVAL(Status, &apos;Open&apos;) || ISPICKVAL(Status, &apos;Overridden&apos;)),
   CASESAFEID(WhatId) + Exception_Code__c ,
   &apos;&apos;
)</formula>
        <name>Update Task Primary Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set task primary key</fullName>
        <actions>
            <name>Update_Task_Primary_Key</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Set the value of the primary key of a task record.</description>
        <formula>ISPICKVAL(Type, &apos;Exception&apos;) &amp;&amp; (ISNEW() ||   ISCHANGED( Status ) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
