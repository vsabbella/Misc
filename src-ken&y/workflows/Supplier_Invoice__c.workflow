<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Copy_Autonumber_Into_SI_AutoGen</fullName>
        <field>Supplier_Invoice__c</field>
        <formula>IF(
  ( CONTAINS(Supplier_Invoice__c, &quot;-PO&quot;) &amp;&amp; (LEFT(Supplier_Invoice__c,2) &lt;&gt; &quot;SI&quot;)),
   
      Autonumber__c &amp; 
      
         RIGHT(Supplier_Invoice__c, 
         (LEN(Supplier_Invoice__c)- FIND(&quot;-PO&quot;, Supplier_Invoice__c))),

   Supplier_Invoice__c
)</formula>
        <name>Copy Autonumber Into SI AutoGen</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Finalized_True</fullName>
        <field>Finalized__c</field>
        <literalValue>1</literalValue>
        <name>Finalized True</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_SI_Name</fullName>
        <field>Name</field>
        <formula>&apos;SI-&apos; &amp; Autonumber__c</formula>
        <name>Set SI Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Transaction_Date</fullName>
        <description>Set the transaction date based on the date invoiced of the supplier invoice record</description>
        <field>Transaction_Date__c</field>
        <formula>Date_Invoiced__c</formula>
        <name>Set Transaction Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Supplier_and_Invoice</fullName>
        <description>Updates the Supplier and Invoice field with the Supplier and Supplier Invoice which enforces uniqueness across this domain.</description>
        <field>Supplier_and_Invoice__c</field>
        <formula>IF((ISPICKVAL(Status__c ,&quot;Cancelled&quot;)||ISPICKVAL(Status__c,&quot;Void&quot;)), null, Supplier__r.Id &amp; Supplier_Invoice__c)</formula>
        <name>Supplier and Invoice</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Supplier_and_Invoice_AutoGen</fullName>
        <field>Supplier_and_Invoice__c</field>
        <formula>CASESAFEID (Supplier__r.Id) &amp; CASESAFEID(Supplier_Invoice__c)</formula>
        <name>Supplier and Invoice AutoGen</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Invoice_Number</fullName>
        <description>This field update updates Invoice number for all credit memo created via RTV process</description>
        <field>Supplier_Invoice__c</field>
        <formula>&quot;RTV-&quot; + Autonumber__c</formula>
        <name>Update Invoice Number</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Autonumber Into Supplier Invoice AutoGen</fullName>
        <actions>
            <name>Copy_Autonumber_Into_SI_AutoGen</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Supplier_and_Invoice_AutoGen</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Auto_Generated__c=true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Finalize Invoice</fullName>
        <actions>
            <name>Finalized_True</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Supplier_Invoice__c.Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <description>Finalize the invoice when the status goes to &quot;Approved&quot;</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Supplier Invoice Name</fullName>
        <actions>
            <name>Set_SI_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set Transaction Date</fullName>
        <actions>
            <name>Set_Transaction_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Supplier_Invoice__c.Date_Invoiced__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Supplier_Invoice__c.Finalized__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Set the transaction date based on date invoiced from the supplier invoice record</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Supplier Supplier Invoice Unique</fullName>
        <actions>
            <name>Supplier_and_Invoice</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>(ISNEW() || ISCHANGED(Supplier__c)   || ISCHANGED(Supplier_Invoice__c) || ISCHANGED(Status__c) ) &amp;&amp;  Auto_Generated__c = false</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update Invoice No for RTV Credit Memos</fullName>
        <actions>
            <name>Update_Invoice_Number</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This workflow is used to update the invoice number for all the credit memos created from RTV process</description>
        <formula>Id = LEFT(Supplier_Invoice__c, 15)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
