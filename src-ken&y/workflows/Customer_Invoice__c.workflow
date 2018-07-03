<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Customer_Invoice_Autonumber</fullName>
        <field>Name</field>
        <formula>&apos;CI-&apos; &amp; Autonumber__c</formula>
        <name>Customer Invoice - Autonumber</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Customer_Invoice_Subtotal</fullName>
        <field>Subtotal__c</field>
        <formula>Total_Line_Amount__c</formula>
        <name>Customer Invoice - Subtotal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Transaction_Date</fullName>
        <description>Set the transaction date from the dat invoiced on the customer invoice</description>
        <field>Transaction_Date__c</field>
        <formula>Date_Invoiced__c</formula>
        <name>Set Transaction Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Customer Invoice - Autonumber</fullName>
        <actions>
            <name>Customer_Invoice_Autonumber</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Customer Invoice - Subtotal</fullName>
        <actions>
            <name>Customer_Invoice_Subtotal</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Transaction Date</fullName>
        <actions>
            <name>Set_Transaction_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Customer_Invoice__c.Date_Invoiced__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Customer_Invoice__c.Finalized__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Set the Transaction date based on the Date invoiced of the Customer Invoice</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
