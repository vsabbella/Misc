<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Inventory_Transaction_Line_Type_Dec</fullName>
        <field>Line_Type__c</field>
        <literalValue>Decrease</literalValue>
        <name>Inventory Transaction - Line Type = Dec</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Inventory_Transaction_Line_Type_Inc</fullName>
        <field>Line_Type__c</field>
        <literalValue>Increase</literalValue>
        <name>Inventory Transaction - Line Type = Inc</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Inventory_Transaction_Line_Type_Null</fullName>
        <field>Line_Type__c</field>
        <name>Inventory Transaction - Line Type = Null</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Inventory_Transaction_Subtransaction</fullName>
        <field>Subtransaction_Type__c</field>
        <formula>IF(TEXT(Type__c) == &apos;Inventory To Rental&apos; || TEXT(Type__c) == &apos;Rental To Inventory&apos;,
               TEXT(Type__c),
               IF(Rental__c==true,
                  TEXT(Type__c)+&apos;-Rental&apos;+IF(Consigned_Owner__c!=null,&apos;-Consigned&apos;,&apos;&apos;),
                  IF(Consigned_Owner__c!=null, TEXT(Type__c)+&apos;-Consigned&apos;,IF(  Item__r.Non_Inventory__c == true &amp;&amp;  (TEXT(Type__c) == &apos;In-Transit&apos; || TEXT(Type__c) == &apos;Void - In-Transit&apos;) &amp;&amp;  Item__r.Class__r.Id !=null ,
TEXT(Item__r.Class__r.Type__c),

TEXT(Type__c)) )
                 )
               )</formula>
        <name>Inventory Transaction - Subtransaction</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Inventory_Transaction_Subtransaction_R</fullName>
        <field>Subtransaction_Type__c</field>
        <formula>Subtransaction_Type__c + &apos;-Rental&apos;</formula>
        <name>Inventory Transaction - Subtransaction R</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_From_SKID_Identifier</fullName>
        <field>From_SKID_Identifier__c</field>
        <formula>IF(OR(ISBLANK(From_SKID_Identifier__c),ISNULL(From_SKID_Identifier__c)),CASESAFEID(From_SKID__c) + &apos;-&apos; + TEXT(From_SKID__r.CreatedDate),From_SKID_Identifier__c)</formula>
        <name>Set From SKID Identifier</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_IT_Name</fullName>
        <field>Name</field>
        <formula>&apos;IT-&apos; &amp; Autonumber__c</formula>
        <name>Set IT Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_To_SKID_Identifier</fullName>
        <field>To_SKID_Identifier__c</field>
        <formula>IF(OR(ISBLANK(To_SKID_Identifier__c),ISNULL(To_SKID_Identifier__c)),CASESAFEID(To_SKID__c) + &apos;-&apos; + TEXT(To_SKID__r.CreatedDate),To_SKID_Identifier__c)</formula>
        <name>Set To SKID Identifier</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Extended_Cost</fullName>
        <field>Extended_Cost__c</field>
        <formula>Standard_Cost__c * Quantity__c</formula>
        <name>Update Extended Cost</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Extended_Price_on_IT</fullName>
        <field>Extended_Price__c</field>
        <formula>IF((ISBLANK( Receipt_Line__c) || ISNULL( Receipt_Line__c)),  Purchase_Order_Line__r.Unit_Price__c *  Quantity__c , Receipt_Line__r.Purchase_Price__c)</formula>
        <name>Update Extended Price on IT</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected> 
    </fieldUpdates>
    <rules>
        <fullName>Calculate Extended Price</fullName>
        <actions>
            <name>Update_Extended_Price_on_IT</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>FALSE</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>IT Create</fullName>
        <actions>
            <name>Set_From_SKID_Identifier</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_IT_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Set_To_SKID_Identifier</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Inventory Transaction - Subtransaction</fullName>
        <actions>
            <name>Inventory_Transaction_Subtransaction</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>(ISNEW() ||   ISCLONE() || ISCHANGED( Type__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Inventory Transaction - Subtransaction R</fullName>
        <actions>
            <name>Inventory_Transaction_Subtransaction_R</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>(Rental__c == TRUE) &amp;&amp;  Subtransaction_Type__c != null</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Inventory_Transaction_Line_Type_Decrease</fullName>
        <actions>
            <name>Inventory_Transaction_Line_Type_Dec</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>false</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Inventory_Transaction_Line_Type_Increase</fullName>
        <actions>
            <name>Inventory_Transaction_Line_Type_Inc</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>false</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Inventory_Transaction_Line_Type_Null</fullName>
        <actions>
            <name>Inventory_Transaction_Line_Type_Null</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>false</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Extended Cost</fullName>
        <actions>
            <name>Update_Extended_Cost</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>false</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
