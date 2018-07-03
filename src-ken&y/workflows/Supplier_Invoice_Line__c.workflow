<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Amount_on_Supplier_Invoice_Line</fullName>
        <field>Amount__c</field>
        <formula>ROUND( ((Invoice_Quantity__c * Unit_Price__c) +  if (ISNULL(VAT_Amount__c),0,VAT_Amount__c)), 2 )</formula>
        <name>Set Amount on Supplier Invoice Line</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_SIL_Name</fullName>
        <field>Name</field>
        <formula>&apos;SIL-&apos; &amp; Autonumber__c</formula>
        <name>Set SIL Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Supplier_Invoice_Line_Subtransaction</fullName>
        <field>Subtransaction_Type__c</field>
        <formula>IF( ISPICKVAL(Supplier_Invoice__r.Invoice_Type__c, &apos;Prepayment&apos;), null,

    if (ISBLANK(Item__c),
         IF(ISBLANK(Purchase_Order_Line__c ),
         		&quot;Miscellaneous&quot;,
         		&quot;Miscellaneous - Purchase Order&quot;
         ),
         IF(ISBLANK(TEXT(Item__r.Class__r.Type__c)),
                IF(ISBLANK(Purchase_Order_Line__c ),
                      &quot;Miscellaneous&quot;,
         		      &quot;Miscellaneous - Purchase Order&quot;
                ),
                IF(NOT(ISBLANK(TEXT(Item__r.Class__r.Type__c))) &amp;&amp; ISBLANK(Purchase_Order_Line__c ),
                		TEXT(Item__r.Class__r.Type__c),
                		TEXT(Item__r.Class__r.Type__c)+&quot; - Purchase Order&quot;
                )
         
        )
    )
)</formula>
        <name>Supplier Invoice Line - Subtransaction</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Amount on Supplier Invoice Line</fullName>
        <actions>
            <name>Set_Amount_on_Supplier_Invoice_Line</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISNEW() || ISCHANGED( Invoice_Quantity__c ) || ISCHANGED( Unit_Price__c ) ||  ISCHANGED(VAT_Amount__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Supplier Invoice Line Name</fullName>
        <actions>
            <name>Set_SIL_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Supplier Invoice Line - Subtransaction</fullName>
        <actions>
            <name>Supplier_Invoice_Line_Subtransaction</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>(ISNEW() || ISCHANGED( Purchase_Order_Line__c ) || ISCHANGED( Item__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
