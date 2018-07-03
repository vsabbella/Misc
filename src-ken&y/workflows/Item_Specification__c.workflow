<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Item_Spec_Costing_Start_Date</fullName>
        <field>Unique_Costing_Start_Date__c</field>
        <formula>IF(ISPICKVAL(Type__c, &quot;Template&quot;), Id, CASESAFEID(Item__c) &amp; &quot;-&quot; &amp; CASESAFEID(Facility__c) &amp; &quot;-&quot; &amp; TEXT(Start_Date2__c) &amp; &quot;-&quot; &amp; TEXT(Type__c) &amp; &quot;-&quot; &amp; IF(Costing__c, &apos;TRUE&apos;, &apos;FALSE&apos;))</formula>
        <name>Item Spec Costing Start Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Item_Spec_Production_Start_Date</fullName>
        <field>Unique_Production_Start_Date__c</field>
        <formula>IF(ISPICKVAL(Type__c, &quot;Template&quot;), Id, CASESAFEID(Item__c) &amp; &quot;-&quot; &amp; CASESAFEID(Facility__c) &amp; &quot;-&quot; &amp; TEXT(Start_Date2__c) &amp; &quot;-&quot; &amp; TEXT(Type__c) &amp; &quot;-&quot; &amp; IF(Production__c, &apos;TRUE&apos;, &apos;FALSE&apos;))</formula>
        <name>Item Spec Production Start Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Item_Revision_unique</fullName>
        <field>Item_Revision__c</field>
        <formula>IF(ISPICKVAL(Type__c,&quot;Template&quot;),Id,CASESAFEID(Item__c) &amp; &quot;-&quot; &amp; CASESAFEID(Facility__c) &amp; &quot;-&quot; &amp; Revision__c &amp; &quot;-&quot; &amp; TEXT(Type__c) &amp; &quot;-&quot; &amp; IF(Production__c,&apos;TRUE&apos;,&apos;FALSE&apos;) &amp; &quot;-&quot; &amp; IF(Costing__c,&apos;TRUE&apos;,&apos;FALSE&apos;))</formula>
        <name>Update Item Revision unique</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Item_Specification_Name</fullName>
        <description>Update Item Specification Name based on the item lookup and this specifications revision</description>
        <field>Name</field>
        <formula>IF(ISPICKVAL(Type__c,&quot;Template&quot;),Name,Item__r.Name)</formula>
        <name>Update Item Specification Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Item Specification Name and Unique</fullName>
        <actions>
            <name>Item_Spec_Costing_Start_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Item_Spec_Production_Start_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Item_Revision_unique</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Item_Specification_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Update the name field and check for duplicate</description>
        <formula>OR(ISCHANGED(Start_Date2__c), ISCHANGED(Name), ISCHANGED(Facility__c), ISCHANGED(Item__c), ISCHANGED(Production__c), ISCHANGED(Costing__c), ISCHANGED(Revision__c), ISNEW())</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
