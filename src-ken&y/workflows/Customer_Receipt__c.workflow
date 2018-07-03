<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Company_Blank_Exception</fullName>
        <description>Company could not be translated correctly, so an exception should be flagged</description>
        <field>Exception_Detail__c</field>
        <formula>Exception_Detail__c + &quot;Company could not be mapped; &quot;</formula>
        <name>Company Blank Exception</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Customer_Receipt_Finalized_Field_Update</fullName>
        <field>Finalized__c</field>
        <literalValue>1</literalValue>
        <name>Customer Receipt Finalized Field Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Customer_Receipt_Status_Closed</fullName>
        <field>Status__c</field>
        <literalValue>Closed</literalValue>
        <name>Customer Receipt - Status Closed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Customer_Receipt_Status_Open</fullName>
        <field>Status__c</field>
        <literalValue>Open</literalValue>
        <name>Customer Receipt - Status Open</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Exception_Customer_Not_Found</fullName>
        <description>Customer not found exception</description>
        <field>Exception_Detail__c</field>
        <formula>Exception_Detail__c + &quot; Customer could not be found based on Originator information&quot;</formula>
        <name>Exception - Customer Not Found</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Exception_True</fullName>
        <description>Set the</description>
        <field>Exception__c</field>
        <literalValue>1</literalValue>
        <name>Exception True</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_CR_Name</fullName>
        <field>Name</field>
        <formula>&apos;CR-&apos; &amp; Autonumber__c</formula>
        <name>Set CR Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Transaction_Date</fullName>
        <description>Set Transaction Date from Date Received from the Customer Receipt</description>
        <field>Transaction_Date__c</field>
        <formula>Date_Received__c</formula>
        <name>Set Transaction Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Customer Receipt - Closed on Finalize</fullName>
        <actions>
            <name>Customer_Receipt_Status_Closed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Customer_Receipt__c.Finalized__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Customer Receipt - Open on Unfinalize</fullName>
        <actions>
            <name>Customer_Receipt_Status_Open</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Customer_Receipt__c.Finalized__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Customer_Receipt__c.Status__c</field>
            <operation>notEqual</operation>
            <value>Cancelled</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Customer Receipt Finalized</fullName>
        <actions>
            <name>Customer_Receipt_Finalized_Field_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND 2 AND 3</booleanFilter>
        <criteriaItems>
            <field>Customer_Receipt__c.Finalized__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Customer_Receipt__c.Amount_Unapplied__c</field>
            <operation>equals</operation>
            <value>0</value>
        </criteriaItems>
        <criteriaItems>
            <field>Customer_Receipt__c.Total_Number_Of_Lines__c</field>
            <operation>greaterThan</operation>
            <value>0</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Exception - No Company Found</fullName>
        <actions>
            <name>Company_Blank_Exception</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Exception_True</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Company cannot be correctly mapped on the customer receipt, so the customer receipt should be flagged as an exception</description>
        <formula>isblank(Company__c) || isnull(Company__c)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Exception - No Customer Found</fullName>
        <actions>
            <name>Exception_Customer_Not_Found</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Exception_True</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Customer could not be mapped based on the data provided</description>
        <formula>isblank(Customer__c) || isnull(Customer__c)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Customer Receipt Name</fullName>
        <actions>
            <name>Set_CR_Name</name>
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
            <field>Customer_Receipt__c.Date_Received__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Customer_Receipt__c.Finalized__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Set the transaction date from Date Received</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
