<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Product_Unique</fullName>
        <description>Product Unique</description>
        <field>Product_Unique__c</field>
        <formula>Name +&apos;-&apos;+Status__c+&apos;-&apos;+UPC_Code__c+&apos;-&apos; +Company__c</formula>
        <name>Product Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Product_UPC_Unique_field</fullName>
        <description>Update Product_Unique_UPC__c field on the Product__c object ever time a user changes the Primary__c field value</description>
        <field>Product_Unique_UPC__c</field>
        <formula>IF(Primary__c &amp;&amp; UPC_Code__c != null, UPC_Code__c + &apos;true&apos;, null)</formula>
        <name>Update Product UPC Unique field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Product Unique</fullName>
        <actions>
            <name>Product_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Product_UPC_Unique_field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Product__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Product Unique</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
