<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_SL_Name</fullName>
        <field>Name</field>
        <formula>&apos;SL-&apos; &amp; Autonumber__c</formula>
        <name>Set SL Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Sales_Order_Line_Usage_Flag</fullName>
        <field>Usage_Based__c</field>
        <literalValue>1</literalValue>
        <name>Set Sales Order Line Usage Flag</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Amount_on_Sales_Order_Line</fullName>
        <description>Updated Amount field on Sales Order Line object</description>
        <field>Amount__c</field>
        <formula>((Quantity_Ordered__c * (Unit_Price__c -  IF(ISNULL(Off_Invoice_Rate__c), 0, Off_Invoice_Rate__c))) + (Allowances__c + IF(ISNULL(Sales_Tax__c), 0, Sales_Tax__c)+ IF(ISNULL(VAT_Amount__c), 0, VAT_Amount__c))) - IF(ISNULL(Discount_Amount__c), 0, Discount_Amount__c)</formula>
        <name>Update Amount on Sales Order Line</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Sales Order Line Name</fullName>
        <actions>
            <name>Set_SL_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Sales Order Line Usage Flag</fullName>
        <actions>
            <name>Set_Sales_Order_Line_Usage_Flag</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Product__r.Usage_Based__c</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Update Sales Order Line Amount</fullName>
        <actions>
            <name>Update_Amount_on_Sales_Order_Line</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates the Amount field on the Sales order line object</description>
        <formula>(ISNEW() &amp;&amp; !ISPICKVAL(Type__c, &apos;Kit-Child&apos;)) || (!ISPICKVAL(Type__c, &apos;Kit-Child&apos;) &amp;&amp; (ISCHANGED(Quantity_Ordered__c)|| ISCHANGED( Unit_Price__c ) || ISCHANGED( Sales_Tax__c ) || ISCHANGED( VAT_Amount__c ) || ISCHANGED(Discount_Amount__c) || ISCHANGED(Allowances__c)))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
