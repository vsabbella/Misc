<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Transaction_Date</fullName>
        <description>Set the transaction date based on the created date of the work order record.</description>
        <field>Transaction_Date__c</field>
        <formula>NOW()</formula>
        <name>Set Transaction Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_WO_Name</fullName>
        <field>Name</field>
        <formula>&apos;WO-&apos; &amp; Autonumber__c</formula>
        <name>Set WO Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>WorkOrderEarliestCompletionDate</fullName>
        <description>Set Work Order Earliest Completion Date if null at creation</description>
        <field>Earliest_Completion_Date2__c</field>
        <formula>IF(ISNULL(Earliest_Completion_Date2__c) , Need_Date2__c, Earliest_Completion_Date2__c)</formula>
        <name>WorkOrderEarliestCompletionDate</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>WorkOrderStartDate</fullName>
        <description>Update Work Order Start Date if null at creation</description>
        <field>Start_Date2__c</field>
        <formula>IF(ISNULL(Start_Date2__c), 
  Need_Date2__c -  IF(ISNULL(Assembly_Item_Specification__r.Item__r.Lead_Time__c),0,Assembly_Item_Specification__r.Item__r.Lead_Time__c), 
Start_Date2__c)</formula>
        <name>WorkOrderStartDate</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Set Transaction Date</fullName>
        <actions>
            <name>Set_Transaction_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Set the transaction date based on the status of the work order record</description>
        <formula>((ISCHANGED( Status__c )  &amp;&amp; ISPICKVAL(Status__c , &apos;Complete&apos;)) || (ISCHANGED( Quantity_Complete__c ) &amp;&amp;  Quantity_Complete__c &gt; NULLVALUE (PRIORVALUE(Quantity_Complete__c) , 0) &amp;&amp; Quantity_Complete__c &gt; 0 )) &amp;&amp;  NOT(Finalized__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Work Order Name</fullName>
        <actions>
            <name>Set_WO_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>WorkOrderDate</fullName>
        <actions>
            <name>WorkOrderEarliestCompletionDate</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>WorkOrderStartDate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Set Start and Earliest Completion dates when work order is created</description>
        <formula>ISNULL(Earliest_Completion_Date2__c )  || ISNULL(Start_Date2__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
