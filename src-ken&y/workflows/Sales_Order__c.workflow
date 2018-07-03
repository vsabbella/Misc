<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_SO_Name</fullName>
        <field>Name</field>
        <formula>&apos;SO-&apos; &amp; Autonumber__c</formula>
        <name>Set SO Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_no_of_floor_spaces</fullName>
        <field>Number_of_Floor_Spaces__c</field>
        <formula>IF( MOD( Number_of_Floor_Spaces__c ,2)== 0, Number_of_Floor_Spaces__c , CEILING(Number_of_Floor_Spaces__c)  
)</formula>
        <name>Set no. of floor spaces</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_no_of_pallets</fullName>
        <field>Number_of_pallets__c</field>
        <formula>if( MOD( Number_of_pallets__c ,2) == 0, Number_of_pallets__c,
 CEILING(Number_of_pallets__c)
)</formula>
        <name>Set no. of pallets</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Sales Order Name</fullName>
        <actions>
            <name>Set_SO_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Set the number of floor spaces</fullName>
        <actions>
            <name>Set_no_of_floor_spaces</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISNEW() ||  ISCHANGED( Number_of_Floor_Spaces__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set the number of pallets</fullName>
        <actions>
            <name>Set_no_of_pallets</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISNEW() ||  ISCHANGED( Number_of_pallets__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
