<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Activate_Contract_Line</fullName>
        <field>Status__c</field>
        <literalValue>Open</literalValue>
        <name>Activate Contract Item</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>ContractLineSetExceptionCheckbox</fullName>
        <description>Sets the exception checkbox on the record</description>
        <field>Exception__c</field>
        <literalValue>1</literalValue>
        <name>ContractLineSetExceptionCheckbox</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>ContractLineSetExceptionDetails</fullName>
        <description>Enter exception details for a quantity exception</description>
        <field>Exception_Details__c</field>
        <formula>&quot;Available quantity has been exhausted.&quot;</formula>
        <name>ContractLineSetExceptionDetails</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Expire_Contract_Line</fullName>
        <field>Status__c</field>
        <literalValue>Expired</literalValue>
        <name>Expire Contract Item</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Agreement_Line_to_Closed</fullName>
        <field>Status__c</field>
        <literalValue>Closed</literalValue>
        <name>Set Agreement Line to Closed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Contract_Line_Name</fullName>
        <field>Name</field>
        <formula>Item__r.Name + &apos;/&apos; + Contract__r.Ship_to_Facility__r.Name</formula>
        <name>Set Contract Line Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>ContractLineMarkExpiredStatus</fullName>
        <actions>
            <name>ContractLineSetExceptionCheckbox</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>ContractLineSetExceptionDetails</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Expire_Contract_Line</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Mark the contract line status as Expired if remaining qty goes to 0</description>
        <formula>Remaining_Quantity__c   &lt;=  0</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Set Agreement Line to Closed</fullName>
        <actions>
            <name>Set_Agreement_Line_to_Closed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contract_Line__c.Remaining_Quantity__c</field>
            <operation>equals</operation>
            <value>0</value>
        </criteriaItems>
        <criteriaItems>
            <field>Contract_Line__c.Status__c</field>
            <operation>equals</operation>
            <value>Open</value>
        </criteriaItems>
        <description>WF to update the status to closed when remaining quantity becomes 0</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Contract Line Name</fullName>
        <actions>
            <name>Set_Contract_Line_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
