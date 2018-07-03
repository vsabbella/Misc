<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Primary_Key_Update</fullName>
        <description>To Update the primary key on object period</description>
        <field>Primary_Key__c</field>
        <formula>IF(
ISPICKVAL(Type__c, &apos;Zero&apos;), 

Company__c &amp;&apos;ZERO&apos;&amp; FiscalYear__c, 

Company__c &amp; Name &amp;
If(Corporate__c = true,&quot;True&quot;,&quot;False&quot;) &amp;
If(Fiscal__c=true,&quot;True&quot;,&quot;False&quot;) &amp;
If(Tax__c = true,&quot;True&quot;,&quot;False&quot;) &amp;
text( Year_Start_Date__c )
)</formula>
        <name>Primary Key Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Populate Primary Key on Period</fullName>
        <actions>
            <name>Primary_Key_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Period__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>This Rule is created to populate the primary key on the Period object</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
