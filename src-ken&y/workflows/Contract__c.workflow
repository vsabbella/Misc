<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Purchase_Agreement_Name</fullName>
        <description>KNDY-4844 auto-populate purchase agreement name with prefix followed by the</description>
        <field>Name</field>
        <formula>&quot;PA-&quot;&amp;Contract_Number__c</formula>
        <name>Purchase Agreement Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PurchasingContractActivationStatusUpdate</fullName>
        <description>Mark the contract as active</description>
        <field>Status__c</field>
        <literalValue>Open</literalValue>
        <name>PurchasingContractActivationStatusUpdate</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PurchasingContractExpirationStatusUpdate</fullName>
        <description>Updates the status field to mark it as expired.</description>
        <field>Status__c</field>
        <literalValue>Expired</literalValue>
        <name>PurchasingContractExpirationStatusUpdate</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Purchase Agreement Name</fullName>
        <actions>
            <name>Purchase_Agreement_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>PurchasingContractActivationStatusUpdate</fullName>
        <actions>
            <name>PurchasingContractActivationStatusUpdate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Mark the contract as active based on date validity</description>
        <formula>Contract_End__c  &gt;= TODAY()</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>PurchasingContractValidityCheck</fullName>
        <actions>
            <name>PurchasingContractExpirationStatusUpdate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Mark the contract as inactive if end date criteria is met</description>
        <formula>Contract_End__c &lt; TODAY()</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
