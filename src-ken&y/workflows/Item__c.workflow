<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Company_and_Item</fullName>
        <field>Company_Item_Unique__c</field>
        <formula>Company__c &amp; Name</formula>
        <name>Company and Item</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>set_item_source_to_outside_processing</fullName>
        <field>Item_Type__c</field>
        <literalValue>Outside Processing</literalValue>
        <name>set item source to outside processing</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Item Type Outside Processing</fullName>
        <actions>
            <name>set_item_source_to_outside_processing</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>copy item source to item type if the item source is &apos;outside processing&apos;</description>
        <formula>AND ( OR( ISNEW() ,  ISCHANGED( Source__c )  ),  TEXT(Source__c)  = &apos;Outside Processing&apos;)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Unique Item per Company</fullName>
        <actions>
            <name>Company_and_Item</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
