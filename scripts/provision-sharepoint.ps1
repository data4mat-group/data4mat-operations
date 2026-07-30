#Requires -Version 7.4

[CmdletBinding()]
param(
    [string]$SiteUrl = "https://data4matgroup.sharepoint.com/sites/data4matoperations",

    [string]$EntraApplicationId = $env:ENTRAID_APP_ID,

    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$FieldGroup = "Data4Mat Takeover Audit"

$ProvisioningModelJson = @'
{
  "siteUrl": "https://data4matgroup.sharepoint.com/sites/data4matoperations",
  "externalResources": [
    {
      "physicalName": "Client Register",
      "resourceType": "List",
      "primaryKey": "ClientID",
      "columns": [
        {
          "internalName": "ClientID",
          "fieldType": "Text",
          "requiredForApplication": true,
          "indexed": true,
          "enforceUniqueValues": true
        }
      ]
    }
  ],
  "resources": [
    {
      "logicalKey": "clientContact",
      "physicalName": "ClientContacts",
      "resourceType": "List",
      "primaryKey": "ContactID",
      "titleColumn": {
        "required": false
      },
      "columns": [
        {
          "internalName": "ContactID",
          "displayName": "Contact ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": true,
          "active": true,
          "maximumLength": 100,
          "fieldId": "ffb57ac8-0448-5670-980b-1ba092c8a2e0"
        },
        {
          "internalName": "ClientID",
          "displayName": "Client ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "951c7d8d-190b-5126-8968-162b29d5fae0"
        },
        {
          "internalName": "FullName",
          "displayName": "Full Name",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "74a6d5b9-4b38-5de8-924c-bf9adfbc1097"
        },
        {
          "internalName": "JobTitle",
          "displayName": "Job Title",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "6fe8f2d8-1659-5b8b-905c-d20eb5bf1a32"
        },
        {
          "internalName": "Email",
          "displayName": "Email",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "9bf23239-562d-5f4a-9a4f-570d540c6d85"
        },
        {
          "internalName": "Phone",
          "displayName": "Phone",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "26ac81c7-6e4a-5c75-807c-df502dcc9d1c"
        },
        {
          "internalName": "IsPrimaryContact",
          "displayName": "Is Primary Contact",
          "fieldType": "Boolean",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "defaultValue": false,
          "fieldId": "232e3e7f-f1b4-5499-a4d0-7ec3c2ed4869"
        },
        {
          "internalName": "ContactType",
          "displayName": "Contact Type",
          "fieldType": "MultiChoice",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "choices": [
            "Primary",
            "Commercial",
            "Technical",
            "Finance",
            "Legal",
            "Security",
            "Other"
          ],
          "fieldId": "b519752a-f553-5b87-aade-3750eb369976"
        },
        {
          "internalName": "IsActive",
          "displayName": "Is Active",
          "fieldType": "Boolean",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "defaultValue": true,
          "fieldId": "bf59a307-ac89-55d3-acc8-7ab2dc375f68"
        },
        {
          "internalName": "Notes",
          "displayName": "Notes",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "fb409bde-6fb5-59b8-8ef4-ca3e0c96ecda"
        }
      ],
      "relationships": [
        {
          "field": "ClientID",
          "targetResource": "Client Register",
          "targetField": "ClientID",
          "external": true
        }
      ],
      "logicalUniqueConstraints": []
    },
    {
      "logicalKey": "audit",
      "physicalName": "TakeoverAudits",
      "resourceType": "List",
      "primaryKey": "AuditID",
      "titleColumn": {
        "required": false
      },
      "columns": [
        {
          "internalName": "AuditID",
          "displayName": "Audit ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": true,
          "active": true,
          "maximumLength": 100,
          "fieldId": "0e6077a3-3e61-5dd3-bccd-8d6f057cce57"
        },
        {
          "internalName": "ClientID",
          "displayName": "Client ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "c22dcebe-0576-56be-9f1d-ade8e5da9e95"
        },
        {
          "internalName": "ProcessID",
          "displayName": "Process ID",
          "fieldType": "Text",
          "required": true,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "8637dc1b-4619-5727-aec6-84b58f862169"
        },
        {
          "internalName": "ProcessVersion",
          "displayName": "Process Version",
          "fieldType": "Text",
          "required": true,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "fe5292d6-e352-525c-b379-6b19da5aa260"
        },
        {
          "internalName": "CatalogueVersion",
          "displayName": "Catalogue Version",
          "fieldType": "Text",
          "required": true,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "75e444a4-6a0a-5ade-b9fc-9a55a607c6e2"
        },
        {
          "internalName": "Status",
          "displayName": "Status",
          "fieldType": "Choice",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "choices": [
            "NotStarted",
            "InProgress",
            "Blocked",
            "ReadyForReview",
            "Completed",
            "Reopened",
            "Cancelled"
          ],
          "defaultValue": "NotStarted",
          "fieldId": "63ec956f-5e17-5fd8-84c9-1235d46df899"
        },
        {
          "internalName": "CurrentStageID",
          "displayName": "Current Stage ID",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "37d7026d-6681-5ac2-855b-cfb21a959a53"
        },
        {
          "internalName": "StartedDate",
          "displayName": "Started Date",
          "fieldType": "DateTime",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "a7d420dd-0aff-5dde-aeaa-51ea8b0b581b"
        },
        {
          "internalName": "CompletedDate",
          "displayName": "Completed Date",
          "fieldType": "DateTime",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "1cf758e0-c9cd-5b46-b568-f2703cfd9294"
        },
        {
          "internalName": "AssignedTo",
          "displayName": "Assigned To",
          "fieldType": "Person",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "allowMultipleValues": false,
          "fieldId": "99a6432e-6912-5018-b5cb-fe33e84b1e3b"
        },
        {
          "internalName": "Notes",
          "displayName": "Notes",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "842d406c-9467-5d2b-a543-f72dc840981a"
        }
      ],
      "relationships": [
        {
          "field": "ClientID",
          "targetResource": "Client Register",
          "targetField": "ClientID",
          "external": true
        }
      ],
      "logicalUniqueConstraints": []
    },
    {
      "logicalKey": "stage",
      "physicalName": "AuditStageRecords",
      "resourceType": "List",
      "primaryKey": "StageRecordID",
      "titleColumn": {
        "required": false
      },
      "columns": [
        {
          "internalName": "StageRecordID",
          "displayName": "Stage Record ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": true,
          "active": true,
          "maximumLength": 150,
          "fieldId": "c3f37d8a-cd3a-5fb8-a217-0166b7a8bb56"
        },
        {
          "internalName": "AuditID",
          "displayName": "Audit ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "09602c2e-8d7a-5b0a-aa26-13c2514e86a3"
        },
        {
          "internalName": "StageID",
          "displayName": "Stage ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "28a780a9-9b92-5621-a709-9dd62c6de2f1"
        },
        {
          "internalName": "Status",
          "displayName": "Status",
          "fieldType": "Choice",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "choices": [
            "NotStarted",
            "InProgress",
            "Blocked",
            "ReadyForReview",
            "Completed",
            "Reopened"
          ],
          "defaultValue": "NotStarted",
          "fieldId": "4770cf2d-a7d1-5316-a37b-b7ea14a2fd21"
        },
        {
          "internalName": "StartedDate",
          "displayName": "Started Date",
          "fieldType": "DateTime",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "f0531e64-f91a-5da6-abe9-10deb5b7290d"
        },
        {
          "internalName": "CompletedDate",
          "displayName": "Completed Date",
          "fieldType": "DateTime",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "509529c4-5ea1-54bc-8529-e1664b5acbd4"
        },
        {
          "internalName": "ReviewedBy",
          "displayName": "Reviewed By",
          "fieldType": "Person",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "allowMultipleValues": false,
          "fieldId": "19d2c3b1-12a7-5ddb-940f-380a752b7964"
        },
        {
          "internalName": "ReviewedDate",
          "displayName": "Reviewed Date",
          "fieldType": "DateTime",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "92c425cc-4ffd-5159-b945-f7123aa68e68"
        },
        {
          "internalName": "BlockedReason",
          "displayName": "Blocked Reason",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "60f2cfd7-0894-5088-93ef-62f78747d417"
        }
      ],
      "relationships": [
        {
          "field": "AuditID",
          "targetResource": "TakeoverAudits",
          "targetField": "AuditID",
          "external": false
        }
      ],
      "logicalUniqueConstraints": [
        [
          "AuditID",
          "StageID"
        ]
      ]
    },
    {
      "logicalKey": "response",
      "physicalName": "AuditResponses",
      "resourceType": "List",
      "primaryKey": "ResponseID",
      "titleColumn": {
        "required": false
      },
      "columns": [
        {
          "internalName": "ResponseID",
          "displayName": "Response ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": true,
          "active": true,
          "maximumLength": 180,
          "fieldId": "44311e77-0b29-5b9a-ab4f-ebfbb9643ef2"
        },
        {
          "internalName": "AuditID",
          "displayName": "Audit ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "4505f0be-13df-54a6-936e-81fb506544c6"
        },
        {
          "internalName": "StageRecordID",
          "displayName": "Stage Record ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 150,
          "fieldId": "5db1ae3e-6482-50b5-9be2-d7818dea804c"
        },
        {
          "internalName": "QuestionID",
          "displayName": "Question ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "1ae87d4a-3e2f-5f31-9a9e-6e4167699643"
        },
        {
          "internalName": "CollectionItemID",
          "displayName": "Collection Item ID",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 180,
          "fieldId": "ba2b9cee-e311-51bd-8c87-c19e31ec85a3"
        },
        {
          "internalName": "FieldID",
          "displayName": "Field ID",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "f6aa6c55-09f7-5d1d-9685-25829eaf2943"
        },
        {
          "internalName": "ResponseType",
          "displayName": "Response Type",
          "fieldType": "Choice",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "choices": [
            "Boolean",
            "Choice",
            "MultiChoice",
            "ShortText",
            "LongText",
            "Number",
            "Date",
            "Url",
            "ClientPerson",
            "ClientPersonMulti",
            "CompanyPerson",
            "CompanyPersonMulti",
            "EvidenceReference",
            "EvidenceReferenceMulti",
            "RepeatingCollection"
          ],
          "fieldId": "1eb3e3ec-a7d9-5c9c-bee3-c1055439ca33"
        },
        {
          "internalName": "TextValue",
          "displayName": "Text Value",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "f44fc3e2-a2d3-54b0-aa04-f92d3f523868"
        },
        {
          "internalName": "NumberValue",
          "displayName": "Number Value",
          "fieldType": "Number",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "decimalPlaces": "Automatic",
          "fieldId": "602f69bf-3c3a-5ef1-a39a-70cc6f40fd07"
        },
        {
          "internalName": "BooleanValue",
          "displayName": "Boolean Value",
          "fieldType": "Boolean",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "72ea0f28-8ddb-59c7-a75c-f749d7150976"
        },
        {
          "internalName": "DateValue",
          "displayName": "Date Value",
          "fieldType": "DateTime",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "dateOnly": true,
          "fieldId": "723958a4-2e53-5253-8317-1f57677802ab"
        },
        {
          "internalName": "ReferenceID",
          "displayName": "Reference ID",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 180,
          "fieldId": "e67564a0-253f-5671-af7a-f61912729f23"
        },
        {
          "internalName": "ReferenceIDsJSON",
          "displayName": "Reference IDs JSON",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "305b1017-45ee-5faf-9005-1f3b0c8cc80f"
        },
        {
          "internalName": "ItemOrder",
          "displayName": "Item Order",
          "fieldType": "Number",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "decimalPlaces": 0,
          "fieldId": "95500e90-80c3-57a4-9201-0e7f941547c7"
        },
        {
          "internalName": "AnsweredBy",
          "displayName": "Answered By",
          "fieldType": "Person",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "allowMultipleValues": false,
          "fieldId": "ffadc9d2-19fb-5b40-9470-d0003a07603b"
        },
        {
          "internalName": "AnsweredDate",
          "displayName": "Answered Date",
          "fieldType": "DateTime",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "6ecf8b55-0d7f-5c34-b87d-4b0915e3d7b0"
        }
      ],
      "relationships": [
        {
          "field": "AuditID",
          "targetResource": "TakeoverAudits",
          "targetField": "AuditID",
          "external": false
        },
        {
          "field": "StageRecordID",
          "targetResource": "AuditStageRecords",
          "targetField": "StageRecordID",
          "external": false
        }
      ],
      "logicalUniqueConstraints": [
        [
          "AuditID",
          "QuestionID",
          "CollectionItemID",
          "FieldID"
        ]
      ]
    },
    {
      "logicalKey": "finding",
      "physicalName": "Findings",
      "resourceType": "List",
      "primaryKey": "FindingID",
      "titleColumn": {
        "required": false
      },
      "columns": [
        {
          "internalName": "FindingID",
          "displayName": "Finding ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": true,
          "active": true,
          "maximumLength": 150,
          "fieldId": "358830fc-6015-599b-89b4-d44173b59f0c"
        },
        {
          "internalName": "AuditID",
          "displayName": "Audit ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "16767903-019b-544e-92d1-874df60c249c"
        },
        {
          "internalName": "StageRecordID",
          "displayName": "Stage Record ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 150,
          "fieldId": "9c048afa-b9a3-57a0-9797-6d520a9a72cc"
        },
        {
          "internalName": "QuestionID",
          "displayName": "Question ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "78ee8b23-c0d4-5226-a407-60c3cbe7ac45"
        },
        {
          "internalName": "FindingType",
          "displayName": "Finding Type",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "165bb837-eead-5510-8797-cea9c6b5cbbc"
        },
        {
          "internalName": "Reference",
          "displayName": "Reference",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "66644f70-3580-5c7c-b2a6-4e85ceeec502"
        },
        {
          "internalName": "FindingTitle",
          "displayName": "Finding Title",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "459f230d-cf48-5b6b-9311-dd0db4b4b74f"
        },
        {
          "internalName": "Description",
          "displayName": "Description",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "ee1e8d7b-3e77-54e6-90f0-8c1b502991ec"
        },
        {
          "internalName": "Observation",
          "displayName": "Observation",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "decbc1b9-ec40-570f-a7fb-675d39454f2a"
        },
        {
          "internalName": "Impact",
          "displayName": "Impact",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "1f7c6fb4-dc1d-50fd-9777-75e78f65a78f"
        },
        {
          "internalName": "Risk",
          "displayName": "Risk",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "06d8035f-a133-571c-b5f2-0ca351b7d0ea"
        },
        {
          "internalName": "Severity",
          "displayName": "Severity",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "5c1c3e4a-6b6a-5d0c-a51c-a40adca287fe"
        },
        {
          "internalName": "Priority",
          "displayName": "Priority",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "ec6be017-6321-5852-b0dc-82ea8bbbbe93"
        },
        {
          "internalName": "Status",
          "displayName": "Status",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "0bf8af03-e8d3-550d-b98d-932a881c4fe0"
        },
        {
          "internalName": "Owner",
          "displayName": "Owner",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "17d66b1b-b3ae-596a-ba7e-c3a3ed6b083c"
        },
        {
          "internalName": "TargetDate",
          "displayName": "Target Date",
          "fieldType": "DateTime",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "dateOnly": true,
          "fieldId": "b4567d25-7423-5bbb-b24a-7d0679f0ff41"
        },
        {
          "internalName": "NextAction",
          "displayName": "Next Action",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "ad5e135f-c3b5-554c-a039-574a27b0d9c0"
        },
        {
          "internalName": "RequiredAction",
          "displayName": "Required Action",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "a09c0318-78c1-549e-9d8d-bd132f85365b"
        },
        {
          "internalName": "LikelyCause",
          "displayName": "Likely Cause",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "4b3afa39-7e08-5e29-89e5-8c750311f5e4"
        },
        {
          "internalName": "AffectedArea",
          "displayName": "Affected Area",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "8d8dd359-6ebf-5655-be36-8d9ebea18806"
        },
        {
          "internalName": "RequiredConfirmation",
          "displayName": "Required Confirmation",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "f2d2b082-300e-5f71-88c0-59b1a940494b"
        },
        {
          "internalName": "ConfirmationType",
          "displayName": "Confirmation Type",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "7107c780-121d-5a47-a5ec-47de8884a4e4"
        },
        {
          "internalName": "BlockedBy",
          "displayName": "Blocked By",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "d833cdf5-1557-54da-b1c8-943810f23457"
        },
        {
          "internalName": "ResponsibleParty",
          "displayName": "Responsible Party",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "0cdb6e5d-4653-5a5c-a719-67aab76264f7"
        },
        {
          "internalName": "SourceStageID",
          "displayName": "Source Stage ID",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "9d6d7b2d-888f-5b88-8606-79708249a717"
        },
        {
          "internalName": "SourceQuestionID",
          "displayName": "Source Question ID",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "3c63c1f9-89ed-55e4-befa-fb4e07fc6834"
        },
        {
          "internalName": "EvidenceReference",
          "displayName": "Evidence Reference",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "6ff3adb4-2f9e-503d-8bbd-d6037201edc4"
        }
      ],
      "relationships": [
        {
          "field": "AuditID",
          "targetResource": "TakeoverAudits",
          "targetField": "AuditID",
          "external": false
        },
        {
          "field": "StageRecordID",
          "targetResource": "AuditStageRecords",
          "targetField": "StageRecordID",
          "external": false
        }
      ],
      "logicalUniqueConstraints": []
    },
    {
      "logicalKey": "evidence",
      "physicalName": "EvidenceRegister",
      "resourceType": "List",
      "primaryKey": "EvidenceID",
      "titleColumn": {
        "required": true
      },
      "columns": [
        {
          "internalName": "EvidenceID",
          "displayName": "Evidence ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": true,
          "active": true,
          "maximumLength": 150,
          "fieldId": "77b62e31-5b55-5bbd-98e9-ee50b04b9a40"
        },
        {
          "internalName": "AuditID",
          "displayName": "Audit ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "386b4a12-cda8-5795-abc6-2c4196b3ea44"
        },
        {
          "internalName": "ClientID",
          "displayName": "Client ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "fc062e21-baa2-59a8-8206-774469ef23d1"
        },
        {
          "internalName": "Description",
          "displayName": "Description",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "1ebf9274-04a8-5353-a501-da4bf90be287"
        },
        {
          "internalName": "EvidenceType",
          "displayName": "Evidence Type",
          "fieldType": "Choice",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "choices": [
            "Document",
            "Screenshot",
            "Email",
            "URL",
            "Configuration export",
            "Interview note",
            "System record",
            "Other"
          ],
          "fieldId": "e7b1ffee-1d16-5c96-b3ca-a83d500eed27"
        },
        {
          "internalName": "Reference",
          "displayName": "Reference",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "50ddb7c2-8760-5403-9054-5fdbed00ad88"
        },
        {
          "internalName": "CollectedDate",
          "displayName": "Collected Date",
          "fieldType": "DateTime",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "dateOnly": true,
          "fieldId": "3864823f-518d-5790-adf2-54be03804746"
        },
        {
          "internalName": "CollectedBy",
          "displayName": "Collected By",
          "fieldType": "Person",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "allowMultipleValues": false,
          "fieldId": "3d67985f-9329-5ca9-82bf-f60a0cc6d8d6"
        },
        {
          "internalName": "IsActive",
          "displayName": "Is Active",
          "fieldType": "Boolean",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "defaultValue": true,
          "fieldId": "3185cb10-efe7-5786-a6b9-be0040e2b2a2"
        },
        {
          "internalName": "Notes",
          "displayName": "Notes",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "4f9862ea-0a56-5130-907b-ab7c5ce1be06"
        }
      ],
      "relationships": [
        {
          "field": "AuditID",
          "targetResource": "TakeoverAudits",
          "targetField": "AuditID",
          "external": false
        },
        {
          "field": "ClientID",
          "targetResource": "Client Register",
          "targetField": "ClientID",
          "external": true
        }
      ],
      "logicalUniqueConstraints": []
    },
    {
      "logicalKey": "remediationAction",
      "physicalName": "RemediationActions",
      "resourceType": "List",
      "primaryKey": "RemediationActionID",
      "titleColumn": {
        "required": false
      },
      "columns": [
        {
          "internalName": "RemediationActionID",
          "displayName": "Remediation Action ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": true,
          "active": true,
          "maximumLength": 150,
          "fieldId": "6127036c-1ccc-5a00-837a-8eb65a17919e"
        },
        {
          "internalName": "AuditID",
          "displayName": "Audit ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "9be1907c-9086-5655-ad79-be7941b7bd8b"
        },
        {
          "internalName": "StageRecordID",
          "displayName": "Stage Record ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 150,
          "fieldId": "6d3708a8-707b-5a4d-9ab7-ec78cefbccbc"
        },
        {
          "internalName": "QuestionID",
          "displayName": "Question ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "0feb456b-fa04-5004-8c07-8d919f8402b0"
        },
        {
          "internalName": "FindingID",
          "displayName": "Finding ID",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 150,
          "fieldId": "ef7e8adb-cfe0-57a4-a714-f22384aaef9c"
        },
        {
          "internalName": "RecordType",
          "displayName": "Record Type",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "a80e7c7a-c3d5-5eae-a656-9a9c53cfd466"
        },
        {
          "internalName": "ActionReference",
          "displayName": "Action Reference",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "21b815f4-2254-5bd1-9a0e-49c3085a5fec"
        },
        {
          "internalName": "IssueReference",
          "displayName": "Issue Reference",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "6e449d88-14e5-52b5-bdbd-ce419880e67a"
        },
        {
          "internalName": "ActionTitle",
          "displayName": "Action Title",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "21e9c20d-701d-5287-ae15-5dae214d6bc6"
        },
        {
          "internalName": "Description",
          "displayName": "Description",
          "fieldType": "Note",
          "required": true,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "d4f94c0e-4e73-5cc9-9bc5-1b768de8db76"
        },
        {
          "internalName": "ExpectedOutcome",
          "displayName": "Expected Outcome",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "6cf8cffd-a08e-5a4b-b339-0942d4bd293b"
        },
        {
          "internalName": "RiskOrDependency",
          "displayName": "Risk or Dependency",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "c7b7ffb8-1c55-5383-a5f3-55166e1e0aee"
        },
        {
          "internalName": "Recommendation",
          "displayName": "Recommendation",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "16a4f01a-93d0-5d1e-9c12-d2e53d39b7ac"
        },
        {
          "internalName": "Priority",
          "displayName": "Priority",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "214dd157-161f-51fb-92ff-ceaa20f8cedf"
        },
        {
          "internalName": "Owner",
          "displayName": "Owner",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "9597c1c2-95f9-5328-9159-040fbb998807"
        },
        {
          "internalName": "TargetDate",
          "displayName": "Target Date",
          "fieldType": "DateTime",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "dateOnly": true,
          "fieldId": "c2eec21e-f959-5eca-b3b7-a1b232ad4a4e"
        },
        {
          "internalName": "CommercialTreatment",
          "displayName": "Commercial Treatment",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "5c994b42-0a77-5838-bf90-4467ef1cb208"
        },
        {
          "internalName": "ApprovalRequired",
          "displayName": "Approval Required",
          "fieldType": "Boolean",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "62cfe9b0-3bbc-5d97-927d-4828e5e203bf"
        },
        {
          "internalName": "Status",
          "displayName": "Status",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "40f09463-f5f5-5ef7-9a62-90a330b73abf"
        },
        {
          "internalName": "VerificationMethod",
          "displayName": "Verification Method",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "7dcf6774-754f-5376-9b4b-5d02174bc1fd"
        },
        {
          "internalName": "Notes",
          "displayName": "Notes",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "3b52e468-671f-5ae0-9f18-3f9e466a285e"
        },
        {
          "internalName": "DependsOnActionID",
          "displayName": "Depends On Action ID",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 150,
          "fieldId": "977e303e-9ba4-5a45-8484-04331100412c"
        },
        {
          "internalName": "DependencyType",
          "displayName": "Dependency Type",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "e84dc2a1-bc2f-5a0f-bbed-696bcaec79c8"
        },
        {
          "internalName": "Blocking",
          "displayName": "Blocking",
          "fieldType": "Boolean",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "151414ff-cf3f-50c1-ac40-d38ce380a11c"
        }
      ],
      "relationships": [
        {
          "field": "AuditID",
          "targetResource": "TakeoverAudits",
          "targetField": "AuditID",
          "external": false
        },
        {
          "field": "StageRecordID",
          "targetResource": "AuditStageRecords",
          "targetField": "StageRecordID",
          "external": false
        },
        {
          "field": "FindingID",
          "targetResource": "Findings",
          "targetField": "FindingID",
          "external": false,
          "optional": true
        },
        {
          "field": "DependsOnActionID",
          "targetResource": "RemediationActions",
          "targetField": "RemediationActionID",
          "external": false,
          "optional": true
        }
      ],
      "logicalUniqueConstraints": []
    },
    {
      "logicalKey": "approval",
      "physicalName": "Approvals",
      "resourceType": "List",
      "primaryKey": "ApprovalID",
      "titleColumn": {
        "required": false
      },
      "columns": [
        {
          "internalName": "ApprovalID",
          "displayName": "Approval ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": true,
          "active": true,
          "maximumLength": 150,
          "fieldId": "f14f483e-ffb6-595e-9fb3-dfa65df69520"
        },
        {
          "internalName": "AuditID",
          "displayName": "Audit ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "0c4228fe-2c71-5184-9880-2a03ef6729aa"
        },
        {
          "internalName": "StageRecordID",
          "displayName": "Stage Record ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 150,
          "fieldId": "c9780a16-f1cd-5102-9d0e-ee8a5835b1a3"
        },
        {
          "internalName": "QuestionID",
          "displayName": "Question ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "cec22110-b9d8-5763-8f75-eb593d4a1768"
        },
        {
          "internalName": "FindingID",
          "displayName": "Finding ID",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 150,
          "fieldId": "fe518b72-a1a1-51f1-aed3-97f268891447"
        },
        {
          "internalName": "RemediationActionID",
          "displayName": "Remediation Action ID",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 150,
          "fieldId": "07e6a24d-84e4-5607-9d78-1b4b5ebaa729"
        },
        {
          "internalName": "ApprovalType",
          "displayName": "Approval Type",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "a927b78f-7c81-54c4-8aa6-fce5c86d9e1c"
        },
        {
          "internalName": "Reference",
          "displayName": "Reference",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "c9630b1d-658f-5bd6-9a90-8f764d66999e"
        },
        {
          "internalName": "Decision",
          "displayName": "Decision",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "c614a63c-aef7-5484-a218-0fcf3133751f"
        },
        {
          "internalName": "Accepted",
          "displayName": "Accepted",
          "fieldType": "Boolean",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "d148ed15-785e-5a10-9c36-d0665a2c5dde"
        },
        {
          "internalName": "ApprovedBy",
          "displayName": "Approved By",
          "fieldType": "Person",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "allowMultipleValues": false,
          "fieldId": "83ae1146-a16a-5154-9ba3-1e80498e7ce1"
        },
        {
          "internalName": "ApprovalDate",
          "displayName": "Approval Date",
          "fieldType": "DateTime",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "dateOnly": true,
          "fieldId": "969520e3-a622-5e1b-8669-3eda950c11c0"
        },
        {
          "internalName": "ReviewDate",
          "displayName": "Review Date",
          "fieldType": "DateTime",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "dateOnly": true,
          "fieldId": "fe8d0eb6-a953-5208-911c-ad232d897e7f"
        },
        {
          "internalName": "Reason",
          "displayName": "Reason",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "28b7b8c5-d6d9-5e04-886d-ce28983cf724"
        },
        {
          "internalName": "RemainingRisk",
          "displayName": "Remaining Risk",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "49ae5893-663a-57a6-a38b-d70dd6e167ce"
        },
        {
          "internalName": "Conditions",
          "displayName": "Conditions",
          "fieldType": "Note",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "52dd3dec-4da3-538f-9107-9b68757d5a9c"
        },
        {
          "internalName": "EvidenceReference",
          "displayName": "Evidence Reference",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 255,
          "fieldId": "7325a30d-4a5f-5013-8722-1ad22bc6e52d"
        }
      ],
      "relationships": [
        {
          "field": "AuditID",
          "targetResource": "TakeoverAudits",
          "targetField": "AuditID",
          "external": false
        },
        {
          "field": "StageRecordID",
          "targetResource": "AuditStageRecords",
          "targetField": "StageRecordID",
          "external": false
        },
        {
          "field": "FindingID",
          "targetResource": "Findings",
          "targetField": "FindingID",
          "external": false,
          "optional": true
        },
        {
          "field": "RemediationActionID",
          "targetResource": "RemediationActions",
          "targetField": "RemediationActionID",
          "external": false,
          "optional": true
        }
      ],
      "logicalUniqueConstraints": []
    },
    {
      "logicalKey": "generatedDocument",
      "physicalName": "GeneratedDocuments",
      "resourceType": "DocumentLibrary",
      "primaryKey": "DocumentID",
      "titleColumn": {
        "required": false
      },
      "columns": [
        {
          "internalName": "DocumentID",
          "displayName": "Document ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": true,
          "active": true,
          "maximumLength": 150,
          "fieldId": "50d27d7c-bd64-54d8-8b92-ff6ad95b5d1d"
        },
        {
          "internalName": "AuditID",
          "displayName": "Audit ID",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "422dd14a-7b4d-5ac3-82ef-83fe2bc586af"
        },
        {
          "internalName": "StageRecordID",
          "displayName": "Stage Record ID",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 150,
          "fieldId": "445185e0-33ff-5866-b444-2db225379e72"
        },
        {
          "internalName": "DocumentType",
          "displayName": "Document Type",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 100,
          "fieldId": "6d640df8-dc2c-521d-b4bf-9c5aa7832f40"
        },
        {
          "internalName": "ProcessVersion",
          "displayName": "Process Version",
          "fieldType": "Text",
          "required": true,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "41013cd0-4251-5652-afab-6c0e0537394a"
        },
        {
          "internalName": "CatalogueVersion",
          "displayName": "Catalogue Version",
          "fieldType": "Text",
          "required": true,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "a38f626c-1c36-506d-96d2-23d1ec41bc4a"
        },
        {
          "internalName": "TemplateID",
          "displayName": "Template ID",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 150,
          "fieldId": "6f300f42-c3a8-59d3-8890-dfab9277eaa5"
        },
        {
          "internalName": "TemplateVersion",
          "displayName": "Template Version",
          "fieldType": "Text",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "d19e8f76-3584-5be1-8d9a-87d2124c1aad"
        },
        {
          "internalName": "DocumentVersion",
          "displayName": "Document Version",
          "fieldType": "Text",
          "required": true,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "76f90eb7-0658-558d-bcbe-1a722d9ee939"
        },
        {
          "internalName": "Status",
          "displayName": "Status",
          "fieldType": "Text",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 50,
          "fieldId": "96e5b48f-fda6-58d0-90b1-55b9c40286ca"
        },
        {
          "internalName": "GeneratedBy",
          "displayName": "Generated By",
          "fieldType": "Person",
          "required": false,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "allowMultipleValues": false,
          "fieldId": "b1358f55-f2b0-5b37-8f52-27341e1f943b"
        },
        {
          "internalName": "GeneratedDate",
          "displayName": "Generated Date",
          "fieldType": "DateTime",
          "required": true,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "fieldId": "1667a0b5-9738-5754-bd6e-f2160bceb896"
        },
        {
          "internalName": "ClientVisible",
          "displayName": "Client Visible",
          "fieldType": "Boolean",
          "required": true,
          "indexed": false,
          "enforceUniqueValues": false,
          "active": true,
          "defaultValue": false,
          "fieldId": "a526634c-421d-58d6-a3f3-057e7fb552d5"
        },
        {
          "internalName": "SupersedesDocumentID",
          "displayName": "Supersedes Document ID",
          "fieldType": "Text",
          "required": false,
          "indexed": true,
          "enforceUniqueValues": false,
          "active": true,
          "maximumLength": 150,
          "fieldId": "33af6b3c-701c-55de-89e2-b5a483ab428c"
        }
      ],
      "relationships": [
        {
          "field": "AuditID",
          "targetResource": "TakeoverAudits",
          "targetField": "AuditID",
          "external": false
        },
        {
          "field": "StageRecordID",
          "targetResource": "AuditStageRecords",
          "targetField": "StageRecordID",
          "external": false,
          "optional": true
        },
        {
          "field": "SupersedesDocumentID",
          "targetResource": "GeneratedDocuments",
          "targetField": "DocumentID",
          "external": false,
          "optional": true
        }
      ],
      "logicalUniqueConstraints": []
    }
  ]
}
'@

$ProvisioningModel = $ProvisioningModelJson | ConvertFrom-Json -Depth 100

function ConvertTo-XmlAttribute {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return [System.Security.SecurityElement]::Escape([string]$Value)
}

function Get-BooleanLiteral {
    param(
        [bool]$Value
    )

    if ($Value) {
        return "TRUE"
    }

    return "FALSE"
}

function Get-ExpectedSharePointType {
    param(
        [string]$FieldType
    )

    switch ($FieldType) {
        "Text"      { return "Text" }
        "Note"      { return "Note" }
        "Number"    { return "Number" }
        "Boolean"   { return "Boolean" }
        "DateTime"  { return "DateTime" }
        "Choice"    { return "Choice" }
        "Person"    { return "User" }
        "Hyperlink" { return "URL" }
        default {
            throw "Unsupported provisioning field type: $FieldType"
        }
    }
}

function New-FieldXml {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Definition
    )

    $sharePointType = Get-ExpectedSharePointType -FieldType $Definition.fieldType

    $attributes = [ordered]@{
        ID                  = "{$($Definition.fieldId)}"
        Type                = $sharePointType
        Name                = $Definition.internalName
        StaticName          = $Definition.internalName
        DisplayName         = $Definition.displayName
        Group               = $FieldGroup
        Required            = Get-BooleanLiteral -Value ([bool]$Definition.required)
        Indexed             = Get-BooleanLiteral -Value ([bool]$Definition.indexed)
        EnforceUniqueValues = Get-BooleanLiteral -Value ([bool]$Definition.enforceUniqueValues)
    }

    switch ($Definition.fieldType) {
        "Text" {
            $attributes.MaxLength = [string]$Definition.maximumLength
        }

        "Note" {
            $attributes.NumLines = "6"
            $attributes.RichText = "FALSE"
            $attributes.RichTextMode = "Compatible"
            $attributes.AppendOnly = "FALSE"
        }

        "Number" {
            if ($Definition.PSObject.Properties.Name -contains "decimalPlaces") {
                $attributes.Decimals = [string]$Definition.decimalPlaces
            }
            else {
                $attributes.Decimals = "Automatic"
            }
        }

        "DateTime" {
            $attributes.Format = if (
                $Definition.PSObject.Properties.Name -contains "dateOnly" -and
                [bool]$Definition.dateOnly
            ) {
                "DateOnly"
            }
            else {
                "DateTime"
            }

            $attributes.FriendlyDisplayFormat = "Disabled"
        }

        "Choice" {
            $attributes.Format = "Dropdown"
            $attributes.FillInChoice = "FALSE"
        }

        "Person" {
            $attributes.List = "UserInfo"
            $attributes.UserSelectionMode = "PeopleOnly"
            $attributes.UserSelectionScope = "0"
            $attributes.Mult = Get-BooleanLiteral -Value ([bool]$Definition.allowMultipleValues)
        }

        "Hyperlink" {
            $attributes.Format = "Hyperlink"
        }
    }

    $attributeText = (
        $attributes.GetEnumerator() |
            ForEach-Object {
                '{0}="{1}"' -f $_.Key, (ConvertTo-XmlAttribute -Value $_.Value)
            }
    ) -join " "

    $childXml = ""

    if ($Definition.fieldType -eq "Choice") {
        $choicesXml = (
            @($Definition.choices) |
                ForEach-Object {
                    "<CHOICE>$(ConvertTo-XmlAttribute -Value $_)</CHOICE>"
                }
        ) -join ""

        $childXml += "<CHOICES>$choicesXml</CHOICES>"
    }

    if ($Definition.PSObject.Properties.Name -contains "defaultValue") {
        $defaultValue = $Definition.defaultValue

        if ($Definition.fieldType -eq "Boolean") {
            $defaultValue = if ([bool]$defaultValue) { "1" } else { "0" }
        }

        $childXml += "<Default>$(ConvertTo-XmlAttribute -Value $defaultValue)</Default>"
    }

    if ([string]::IsNullOrEmpty($childXml)) {
        return "<Field $attributeText />"
    }

    return "<Field $attributeText>$childXml</Field>"
}

function Get-FieldValidationErrors {
    param(
        [Parameter(Mandatory)]
        [string]$ListName,

        [Parameter(Mandatory)]
        [pscustomobject]$Definition,

        [Parameter(Mandatory)]
        [object]$Field
    )

    $errors = [System.Collections.Generic.List[string]]::new()

    [xml]$schemaXml = $Field.SchemaXml
    $fieldNode = $schemaXml.Field

    $expectedType = Get-ExpectedSharePointType -FieldType $Definition.fieldType

    if ([string]$Field.InternalName -cne [string]$Definition.internalName) {
        $errors.Add(
            "$ListName.$($Definition.internalName): internal name is '$($Field.InternalName)'."
        )
    }

    if ([string]$Field.Title -cne [string]$Definition.displayName) {
        $errors.Add(
            "$ListName.$($Definition.internalName): display name is '$($Field.Title)'; expected '$($Definition.displayName)'."
        )
    }

    if ([string]$Field.TypeAsString -ne $expectedType) {
        $errors.Add(
            "$ListName.$($Definition.internalName): type is '$($Field.TypeAsString)'; expected '$expectedType'."
        )
    }

    if ([bool]$Field.Required -ne [bool]$Definition.required) {
        $errors.Add(
            "$ListName.$($Definition.internalName): Required is '$($Field.Required)'; expected '$($Definition.required)'."
        )
    }

    if ([bool]$Field.Indexed -ne [bool]$Definition.indexed) {
        $errors.Add(
            "$ListName.$($Definition.internalName): Indexed is '$($Field.Indexed)'; expected '$($Definition.indexed)'."
        )
    }

    if ([bool]$Field.EnforceUniqueValues -ne [bool]$Definition.enforceUniqueValues) {
        $errors.Add(
            "$ListName.$($Definition.internalName): EnforceUniqueValues is '$($Field.EnforceUniqueValues)'; expected '$($Definition.enforceUniqueValues)'."
        )
    }

    if ([guid]$Field.Id -ne [guid]$Definition.fieldId) {
        $errors.Add(
            "$ListName.$($Definition.internalName): field ID is '$($Field.Id)'; expected '$($Definition.fieldId)'."
        )
    }

    if ($Definition.fieldType -eq "Text") {
        $actualMaximumLength = [int]$fieldNode.MaxLength

        if ($actualMaximumLength -ne [int]$Definition.maximumLength) {
            $errors.Add(
                "$ListName.$($Definition.internalName): MaxLength is '$actualMaximumLength'; expected '$($Definition.maximumLength)'."
            )
        }
    }

    if ($Definition.fieldType -eq "Choice") {
        $actualChoices = @(
            $fieldNode.CHOICES.CHOICE |
                ForEach-Object { [string]$_ }
        )

        $expectedChoices = @($Definition.choices)

        if (($actualChoices -join "`n") -cne ($expectedChoices -join "`n")) {
            $errors.Add(
                "$ListName.$($Definition.internalName): choice values do not match the provisioning definition."
            )
        }
    }

    if ($Definition.fieldType -eq "DateTime") {
        $expectedFormat = if (
            $Definition.PSObject.Properties.Name -contains "dateOnly" -and
            [bool]$Definition.dateOnly
        ) {
            "DateOnly"
        }
        else {
            "DateTime"
        }

        if ([string]$fieldNode.Format -ne $expectedFormat) {
            $errors.Add(
                "$ListName.$($Definition.internalName): date format is '$($fieldNode.Format)'; expected '$expectedFormat'."
            )
        }
    }

    if ($Definition.fieldType -eq "Person") {
        $actualMultipleValues = [string]$fieldNode.Mult -eq "TRUE"

        if ($actualMultipleValues -ne [bool]$Definition.allowMultipleValues) {
            $errors.Add(
                "$ListName.$($Definition.internalName): multiple-person setting does not match."
            )
        }
    }

    if ($Definition.fieldType -eq "Number") {
        $expectedDecimals = if (
            $Definition.PSObject.Properties.Name -contains "decimalPlaces"
        ) {
            [string]$Definition.decimalPlaces
        }
        else {
            "Automatic"
        }

        if ([string]$fieldNode.Decimals -ne $expectedDecimals) {
            $errors.Add(
                "$ListName.$($Definition.internalName): decimal setting is '$($fieldNode.Decimals)'; expected '$expectedDecimals'."
            )
        }
    }

    return $errors
}

function Get-ListField {
    param(
        [Parameter(Mandatory)]
        [string]$ListName,

        [Parameter(Mandatory)]
        [string]$InternalName
    )

    return Get-PnPField `
        -List $ListName `
        -Identity $InternalName `
        -Includes "InternalName", "Title", "TypeAsString", "Required", "Indexed", "EnforceUniqueValues", "Id", "SchemaXml" `
        -ErrorAction SilentlyContinue
}

function Assert-ExternalClientRegister {
    $clientList = Get-PnPList `
        -Identity "Client Register" `
        -Includes "BaseTemplate" `
        -ThrowExceptionIfListNotFound

    if ([int]$clientList.BaseTemplate -ne 100) {
        throw "'Client Register' exists but is not a SharePoint list."
    }

    $clientIdField = Get-ListField `
        -ListName "Client Register" `
        -InternalName "ClientID"

    if ($null -eq $clientIdField) {
        throw "Client Register is missing the required ClientID field."
    }

    $errors = [System.Collections.Generic.List[string]]::new()

    if ([string]$clientIdField.TypeAsString -ne "Text") {
        $errors.Add(
            "Client Register.ClientID is '$($clientIdField.TypeAsString)'; expected Text."
        )
    }

    if (-not [bool]$clientIdField.Indexed) {
        $errors.Add("Client Register.ClientID must be indexed.")
    }

    if (-not [bool]$clientIdField.EnforceUniqueValues) {
        $errors.Add("Client Register.ClientID must enforce unique values.")
    }

    if ($errors.Count -gt 0) {
        throw ($errors -join [Environment]::NewLine)
    }
}

function Assert-ResourceShell {
    foreach ($resource in $ProvisioningModel.resources) {
        $list = Get-PnPList `
            -Identity $resource.physicalName `
            -Includes "BaseTemplate", "EnableVersioning" `
            -ThrowExceptionIfListNotFound

        $expectedTemplate = if ($resource.resourceType -eq "DocumentLibrary") {
            101
        }
        else {
            100
        }

        if ([int]$list.BaseTemplate -ne $expectedTemplate) {
            throw (
                "'$($resource.physicalName)' has SharePoint base template " +
                "'$($list.BaseTemplate)'; expected '$expectedTemplate' for " +
                "'$($resource.resourceType)'."
            )
        }
    }
}

function Get-ProvisioningState {
    $state = [pscustomobject]@{
        MissingFields = [System.Collections.Generic.List[object]]::new()
        Errors        = [System.Collections.Generic.List[string]]::new()
    }

    foreach ($resource in $ProvisioningModel.resources) {
        foreach ($definition in $resource.columns) {
            if (-not [bool]$definition.active) {
                continue
            }

            $field = Get-ListField `
                -ListName $resource.physicalName `
                -InternalName $definition.internalName

            if ($null -eq $field) {
                $state.MissingFields.Add(
                    [pscustomobject]@{
                        ListName   = $resource.physicalName
                        Definition = $definition
                    }
                )

                continue
            }

            $validationErrors = Get-FieldValidationErrors `
                -ListName $resource.physicalName `
                -Definition $definition `
                -Field $field

            foreach ($validationError in $validationErrors) {
                $state.Errors.Add($validationError)
            }
        }
    }

    return $state
}

if (-not (Get-Module -ListAvailable -Name "PnP.PowerShell")) {
    throw (
        "PnP.PowerShell is not installed. Open PowerShell 7.4 or later and run: " +
        "Install-Module PnP.PowerShell -Scope CurrentUser"
    )
}

if ([string]::IsNullOrWhiteSpace($EntraApplicationId)) {
    throw (
        "No Entra application ID was supplied. Pass -EntraApplicationId or set " +
        "the ENTRAID_APP_ID environment variable before running this script."
    )
}

Import-Module PnP.PowerShell

Write-Host "Connecting to $SiteUrl..." -ForegroundColor Cyan

Connect-PnPOnline `
    -Url $SiteUrl `
    -Interactive `
    -ClientId $EntraApplicationId `
    -ValidateConnection

try {
    Assert-ExternalClientRegister
    Assert-ResourceShell

    $state = Get-ProvisioningState

    if ($state.Errors.Count -gt 0) {
        Write-Host "Existing SharePoint fields conflict with the approved model:" -ForegroundColor Red

        foreach ($validationError in $state.Errors) {
            Write-Host "- $validationError" -ForegroundColor Red
        }

        throw "Provisioning stopped before making changes."
    }

    if ($ValidateOnly) {
        Write-Host "Validation completed successfully." -ForegroundColor Green
        Write-Host "Fields already correct: $(
            ($ProvisioningModel.resources.columns | Measure-Object).Count -
            $state.MissingFields.Count
        )"
        Write-Host "Fields to create: $($state.MissingFields.Count)"
        return
    }

    foreach ($missingField in $state.MissingFields) {
        $fieldXml = New-FieldXml -Definition $missingField.Definition

        Write-Host (
            "Creating $($missingField.ListName)." +
            "$($missingField.Definition.internalName)..."
        )

        Add-PnPFieldFromXml `
            -List $missingField.ListName `
            -FieldXml $fieldXml |
            Out-Null
    }

    foreach ($resource in $ProvisioningModel.resources) {
        Set-PnPField `
            -List $resource.physicalName `
            -Identity "Title" `
            -Values @{
                Required = $false
            } |
            Out-Null
    }

    Set-PnPList `
        -Identity "GeneratedDocuments" `
        -EnableVersioning $true `
        -EnableMinorVersions $false |
        Out-Null

    $finalState = Get-ProvisioningState

    if ($finalState.MissingFields.Count -gt 0 -or $finalState.Errors.Count -gt 0) {
        Write-Host "Post-provisioning validation failed:" -ForegroundColor Red

        foreach ($missingField in $finalState.MissingFields) {
            Write-Host (
                "- Missing: $($missingField.ListName)." +
                "$($missingField.Definition.internalName)"
            ) -ForegroundColor Red
        }

        foreach ($validationError in $finalState.Errors) {
            Write-Host "- $validationError" -ForegroundColor Red
        }

        throw "Provisioning did not complete cleanly."
    }

    Write-Host ""
    Write-Host "Takeover Audit SharePoint provisioning completed successfully." -ForegroundColor Green
    Write-Host "Site: $SiteUrl"
    Write-Host "Resources configured: $($ProvisioningModel.resources.Count)"
    Write-Host "Custom fields configured: $(
        ($ProvisioningModel.resources.columns | Measure-Object).Count
    )"
    Write-Host "GeneratedDocuments versioning: enabled"
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
