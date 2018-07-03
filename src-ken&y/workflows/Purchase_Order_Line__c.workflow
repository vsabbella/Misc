<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>ClosedDateUpdateAction</fullName>
        <field>Date_Closed__c</field>
        <formula>IF(ISPICKVAL(Status__c,&quot;Closed&quot;),TODAY(),null)</formula>
        <name>ClosedDateUpdateAction</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Purchase_Order_Line_Close_Date</fullName>
        <description>This field update is used to set the closed date on a purchase order line.</description>
        <field>Date_Closed__c</field>
        <formula>TODAY()</formula>
        <name>Purchase Order Line Close Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Purchase_Order_Line_Subtransaction_Type</fullName>
        <field>Subtransaction_Type__c</field>
        <formula>TEXT( Purchase_Order__r.FOB_Term__r.FOB_Point__c )</formula>
        <name>Purchase Order Line-Subtransaction Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_PO_Line_Name</fullName>
        <field>Name</field>
        <formula>&apos;PL-&apos; &amp; Autonumber__c</formula>
        <name>Set PO Line Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>podetailcloseaction</fullName>
        <description>Action to update status of PO detail</description>
        <field>Status__c</field>
        <literalValue>Closed</literalValue>
        <name>PODetailCloseAction</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>ClosedDateUpdate</fullName>
        <actions>
            <name>ClosedDateUpdateAction</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Purchase Order Line - Update Closed Date based on Status</description>
        <formula>OR(ISCHANGED( Status__c ),AND(ISNEW(),ISPICKVAL(Status__c,&quot;Closed&quot;)))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>PODetailCloseRule</fullName>
        <actions>
            <name>Purchase_Order_Line_Close_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>podetailcloseaction</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Purchase_Order_Line__c.Quantity_Still_Due__c</field>
            <operation>lessOrEqual</operation>
            <value>0</value>
        </criteriaItems>
        <criteriaItems>
            <field>Purchase_Order_Line__c.Status__c</field>
            <operation>notEqual</operation>
            <value>Cancelled</value>
        </criteriaItems>
        <description>Rule to close PO detail</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Purchase Order Line - Subtransaction Type</fullName>
        <actions>
            <name>Purchase_Order_Line_Subtransaction_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Purchase Order Line Name</fullName>
        <actions>
            <name>Set_PO_Line_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
