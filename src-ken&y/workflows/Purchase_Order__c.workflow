<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Copy_Remit_to_City</fullName>
        <field>Remit_to_City__c</field>
        <formula>Supplier__r.Address__r.BillingCity</formula>
        <name>Copy Remit-to City</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Copy_Remit_to_Country</fullName>
        <field>Remit_to_Country__c</field>
        <formula>Supplier__r.Address__r.BillingCountry</formula>
        <name>Copy Remit-to Country</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Copy_Remit_to_State</fullName>
        <field>Remit_to_State__c</field>
        <formula>Supplier__r.Address__r.BillingState</formula>
        <name>Copy Remit-to State</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Copy_Remit_to_Street</fullName>
        <field>Remit_to_Street__c</field>
        <formula>Supplier__r.Address__r.BillingStreet</formula>
        <name>Copy Remit-to Street</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Copy_Remit_to_Zip_Code</fullName>
        <field>Remit_to_Zip_Code__c</field>
        <formula>Supplier__r.Address__r.BillingPostalCode</formula>
        <name>Copy Remit-to Zip Code</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_PO_Closed</fullName>
        <description>Close the PO when all the lines are closed</description>
        <field>Date_Closed__c</field>
        <formula>Today()</formula>
        <name>Date PO Closed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PO_Bill_to_City</fullName>
        <description>Default PO Bill-to City</description>
        <field>Bill_to_City__c</field>
        <formula>IF(OR(ISBLANK(Bill_to_City__c) , ISNULL(Bill_to_City__c)),  Company__r.Address__r.BillingCity ,Bill_to_City__c)</formula>
        <name>PO Bill-to City</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PO_Bill_to_Country</fullName>
        <description>Default PO Bill-to Country</description>
        <field>Bill_to_Country__c</field>
        <formula>IF(OR(ISBLANK(Bill_to_Country__c), ISNULL(Bill_to_Country__c)),  Company__r.Address__r.BillingCountry ,Bill_to_Country__c)</formula>
        <name>PO Bill-to Country</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PO_Bill_to_State</fullName>
        <description>Default PO Bill-to State</description>
        <field>Bill_to_State__c</field>
        <formula>IF(OR(ISBLANK(Bill_to_State__c), ISNULL(Bill_to_State__c)),  Company__r.Address__r.BillingState ,Bill_to_State__c)</formula>
        <name>PO Bill-to State</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PO_Bill_to_Street</fullName>
        <description>Default PO Bill-to Street</description>
        <field>Bill_to_Street__c</field>
        <formula>IF(OR(ISBLANK(Bill_to_Street__c), ISNULL(Bill_to_Street__c)),  Company__r.Address__r.BillingStreet ,Bill_to_Street__c)</formula>
        <name>PO Bill-to Street</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PO_Bill_to_Zip_Code</fullName>
        <description>Default PO Bill-to Zip Code</description>
        <field>Bill_to_Zip_Code__c</field>
        <formula>IF(OR(ISBLANK(Bill_to_Zip_Code__c), ISNULL(Bill_to_Zip_Code__c)),  Company__r.Address__r.BillingPostalCode  ,Bill_to_Zip_Code__c)</formula>
        <name>PO Bill-to Zip Code</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PO_Cancelled</fullName>
        <description>Set the PO Status to Cancel</description>
        <field>Status__c</field>
        <literalValue>Cancelled</literalValue>
        <name>PO Cancelled</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PO_Closed</fullName>
        <description>When all the lines are closed - close the PO</description>
        <field>Status__c</field>
        <literalValue>Closed</literalValue>
        <name>PO Closed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Purchase_Order_Transaction_Date</fullName>
        <field>Transaction_Date__c</field>
        <formula>NOW()</formula>
        <name>Purchase Order - Transaction Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_PO_Name</fullName>
        <field>Name</field>
        <formula>&apos;PO-&apos; &amp; Autonumber__c</formula>
        <name>Set PO Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Cancel PO</fullName>
        <actions>
            <name>PO_Cancelled</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>If all the lines are cancelled, then set PO status to Cancelled</description>
        <formula>NOT(ISNEW()) &amp;&amp;  NOT(ISCHANGED(Status__c)) &amp;&amp; Open_Purchase_Order_Lines__c  == 0 &amp;&amp;  Total_Number_Of_Lines__c  &gt;0 &amp;&amp; Total_Number_Of_Lines__c =  Cancelled_Purchase_Order_Lines__c</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Close PO</fullName>
        <actions>
            <name>Date_PO_Closed</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>PO_Closed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>If all the lines are closed - close the PO</description>
        <formula>NOT ISPICKVAL( Status__c , &apos;Closed&apos;) &amp;&amp; NOT(ISNEW()) &amp;&amp;  NOT(ISCHANGED(Status__c)) &amp;&amp; Open_Purchase_Order_Lines__c  == 0 &amp;&amp;  Total_Number_Of_Lines__c  &gt; 0 &amp;&amp; Total_Number_Of_Lines__c  &gt;  Cancelled_Purchase_Order_Lines__c</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Default PO Addresses</fullName>
        <actions>
            <name>PO_Bill_to_City</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>PO_Bill_to_Country</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>PO_Bill_to_State</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>PO_Bill_to_Street</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>PO_Bill_to_Zip_Code</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Purchase_Order__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Default PO Bill-to and Ship-to addresses</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Default Remit-to Address on PO</fullName>
        <actions>
            <name>Copy_Remit_to_City</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Copy_Remit_to_Country</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Copy_Remit_to_State</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Copy_Remit_to_Street</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Copy_Remit_to_Zip_Code</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Supplier__c != null</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Purchase Order - Transaction Date</fullName>
        <actions>
            <name>Purchase_Order_Transaction_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Purchase_Order__c.Order_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Purchase_Order__c.Transaction_Date__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Purchase Order Name</fullName>
        <actions>
            <name>Set_PO_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
