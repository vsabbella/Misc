<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Fulfillment_Name</fullName>
        <field>Name</field>
        <formula>&quot;F-&quot;&amp;Autonumber__c</formula>
        <name>Fulfillment - Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_invoice_ready_when_fulfillment_compl</fullName>
        <field>Invoice_Ready__c</field>
        <literalValue>1</literalValue>
        <name>Set_invoice_ready_when_fulfillment_compl</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Fulfillment - Name</fullName>
        <actions>
            <name>Fulfillment_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set_invoice_ready_when_fulfillment_complete</fullName>
        <actions>
            <name>Set_invoice_ready_when_fulfillment_compl</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Fulfillment__c.Status__c</field>
            <operation>equals</operation>
            <value>Complete</value>
        </criteriaItems>
        <description>Sets invoice ready to true when fulfillment status changes to complete.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
