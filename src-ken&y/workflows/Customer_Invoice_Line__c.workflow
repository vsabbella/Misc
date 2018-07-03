<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Customer_Invoice_Line_Autonumber</fullName>
        <field>Name</field>
        <formula>&apos;CIL-&apos; &amp; Autonumber__c</formula>
        <name>Customer Invoice Line - Autonumber</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Customer_Invoice_Line_Subtransaction</fullName>
        <field>Subtransaction_Type__c</field>
        <formula>if (ISPICKVAL(Customer_Invoice__r.Invoice_Type__c, &apos;Manual&apos;) &amp;&amp; ISBLANK(Product__c), 
     &apos;Miscellaneous&apos;,
     TEXT(Product__r.Item__r.Class__r.Type__c)
)</formula>
        <name>Customer Invoice Line - Subtransaction</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Amount_on_Customer_Invoice_Line</fullName>
        <field>Amount__c</field>
        <formula>ROUND(((( Unit_Price__c -   Off_Invoice_Rate__c ) *  Quantity_Shipped__c  * Prorate_Factor__c) -   BLANKVALUE(Discount_Amount__c, 0) +  BLANKVALUE(Sales_Tax__c, 0) +  BLANKVALUE(Value_Added_Tax__c, 0) +  BLANKVALUE(Allowances__c, 0)),2)</formula>
        <name>Set Amount on Customer Invoice Line</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Extended_Price</fullName>
        <field>Extended_Price__c</field>
        <formula>ROUND(
(Quantity_Shipped__c*
  (Unit_Price__c - NULLVALUE(Off_Invoice_Rate__c, 0))) *
   (1- NULLVALUE(Discount_Percent__c, 0)) -NULLVALUE(Freight_Allowance__c,0) -NULLVALUE(Allowances__c,0)
,2)</formula>
        <name>Update Extended Price</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Customer Invoice Line - Autonumber</fullName>
        <actions>
            <name>Customer_Invoice_Line_Autonumber</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>True</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Customer Invoice Line - Subtransaction</fullName>
        <actions>
            <name>Customer_Invoice_Line_Subtransaction</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>(ISNEW() || ISCHANGED( Product__c )) &amp;&amp;  (NOT(ISPICKVAL(Customer_Invoice__r.Invoice_Type__c, &apos;Settlement&apos;))) &amp;&amp;  (Subtransaction_Type__c != &apos;Liability Increase&apos;) &amp;&amp;  (Subtransaction_Type__c != &apos;Liability Decrease&apos;)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Amount on Customer Invoice Line</fullName>
        <actions>
            <name>Set_Amount_on_Customer_Invoice_Line</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISNEW() ||  ISCHANGED( Unit_Price__c ) || ISCHANGED( Off_Invoice_Rate__c )  || ISCHANGED( Quantity_Shipped__c ) || ISCHANGED( Sales_Tax__c ) || ISCHANGED( Value_Added_Tax__c ) || ISCHANGED( Allowances__c ) || ISCHANGED( Discount_Amount__c ) || ISCHANGED( Prorate_Factor__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Extended Price</fullName>
        <actions>
            <name>Update_Extended_Price</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>ISCHANGED(Unit_Price__c) || ISCHANGED(Quantity_Shipped__c) || ISCHANGED(Off_Invoice_Rate__c) || ISCHANGED(Discount_Percent__c) || ISCHANGED(Allowances__c) ||  ISCHANGED( Freight_Allowance__c ) || ISNEW()</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
