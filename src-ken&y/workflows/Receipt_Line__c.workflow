<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Receipt_Line_Subtransaction</fullName>
        <field>Subtransaction_Type__c</field>
        <formula>TEXT(Item__r.Class__r.Type__c)</formula>
        <name>Receipt Line - Subtransaction</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_RL_Name</fullName>
        <field>Name</field>
        <formula>&apos;RCL-&apos; &amp; Autonumber__c</formula>
        <name>Set RL Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Receipt Line - Subtransaction</fullName>
        <actions>
            <name>Receipt_Line_Subtransaction</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( (ISNEW() ||  ISCHANGED( Item__c )) , (Subtransaction_Type__c &lt;&gt; &apos;Return&apos; &amp;&amp; Subtransaction_Type__c &lt;&gt; &apos;Receipt&apos;))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Receipt Line Name</fullName>
        <actions>
            <name>Set_RL_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
