<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_GL_Account_Name</fullName>
        <field>Name</field>
        <formula>if( ISBLANK(GL_Account_Number__c), GL_Account_Name__c ,if( ISBLANK(GL_Account_Name__c),GL_Account_Number__c, GL_Account_Number__c+&apos; - &apos;+GL_Account_Name__c))</formula>
        <name>Set GL Account Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_GL_Account_Unique</fullName>
        <description>Populates the GL Account Unique field with Name so that no two GL Accounts have the same name.</description>
        <field>GL_Account_Unique__c</field>
        <formula>IF( Active__c, GL_Account_Number__c+&apos; - &apos;+GL_Account_Name__c, &apos;&apos;)</formula>
        <name>Update GL Account Unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>GL Account Unique</fullName>
        <actions>
            <name>Update_GL_Account_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Populates the GL_Account_Unique__c field on the GL_Account__c.object</description>
        <formula>ISNULL(GL_Account_Name__c) == FALSE</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set GL Account Name</fullName>
        <actions>
            <name>Set_GL_Account_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_GL_Account_Unique</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 OR 2</booleanFilter>
        <criteriaItems>
            <field>GL_Account__c.GL_Account_Name__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>GL_Account__c.GL_Account_Number__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Set the GL Account Name field with the GL Account Number and GL Account Name</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
