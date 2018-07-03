<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Agreement_Line_Name</fullName>
        <field>Name</field>
        <formula>&quot;AL-&quot;&amp;Autonumber__c</formula>
        <name>Agreement Line - Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_agreementline_approval_required_chec</fullName>
        <field>Approval_Required__c</field>
        <literalValue>1</literalValue>
        <name>Set_agreementline_approval_required_chec</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_agreementline_revision_approval_date</fullName>
        <field>Revision_Approval_date__c</field>
        <formula>NOW()</formula>
        <name>Set_agreementline_revision_approval_date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Agreement Line - Name</fullName>
        <actions>
            <name>Agreement_Line_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set_Agreement_revision_approval_date</fullName>
        <actions>
            <name>Set_agreementline_revision_approval_date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Agreement_Line__c.Revision_Status__c</field>
            <operation>equals</operation>
            <value>Approved</value>
        </criteriaItems>
        <description>Once agreement line revision is approved it sets revision approval date .</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set_agreementline_approval_required_checkbox</fullName>
        <actions>
            <name>Set_agreementline_approval_required_chec</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Variation_Percentage__c &gt;= $Setup.Set_Rental_Approval_Threshold__c.Variation_Percentage__c</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
