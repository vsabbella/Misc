<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_1099_Box</fullName>
        <description>Set the default value to Number 7</description>
        <field>X1099_Box__c</field>
        <literalValue>7 Nonemployee Compensation</literalValue>
        <name>Set 1099 Box</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Supplier_Unique</fullName>
        <field>Supplier_Unique__c</field>
        <formula>Name +&apos;-&apos; + Company__c + &apos;-&apos; +  TEXT(Type__c) +  CASESAFEID(Top_Parent_Supplier__c)</formula>
        <name>Supplier Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set 1099 Box default</fullName>
        <actions>
            <name>Set_1099_Box</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>This rule will be setting default value on 1099 box.</description>
        <formula>1 != 1</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Supplier Unique</fullName>
        <actions>
            <name>Supplier_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Supplier__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <description>Supplier Unique</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
