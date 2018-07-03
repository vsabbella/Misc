<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Generate_PDF_Update_False</fullName>
        <description>Update Generate PDF to False</description>
        <field>Merge__c</field>
        <literalValue>0</literalValue>
        <name>Generate PDF Update False</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Generate PDF not allowed when exclude %3D true</fullName>
        <actions>
            <name>Generate_PDF_Update_False</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Generate PDF not allowed when Exclude is true</description>
        <formula>ISCHANGED(Exclude__c ) &amp;&amp; (Exclude__c = TRUE)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
