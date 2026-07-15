---
title: Data4Mat Operations App Architecture and Implementation Plan
document_status: Working architecture plan
version: 1.0
date: 2026-07-15
owner: Data4Mat AB
initial_implementation_focus: Takeover Audit module
---

DATA4MAT OPERATIONS APP

Architecture and Implementation Plan

*Approved direction for structured operational processes, Power Apps, SharePoint, Power Automate, Word outputs, JSON configuration, and GitHub source control*

| Document status | Working architecture plan |
| --- | --- |
| Version | 1.0 |
| Date | 2026-07-15 |
| Owner | Data4Mat AB |
| Initial implementation focus | Takeover Audit module |

| The core decision is that structured records are the source of truth. Word documents are guidance and generated presentation outputs, not operational data stores. |
| --- |

# 1. Executive Summary

Data4Mat will build one internal Data4Mat Operations App with separate business modules. The first module will be Takeover Audit. Later modules will include Change Control, Security, Maintenance, Client Communication, Supplier Management, Quality Gates, Issues, and Remediation.

The application will initially be implemented as a responsive Power Apps canvas app. It will be available in a browser and through the Power Apps mobile application on iPhone. SharePoint Lists will store structured operational data, SharePoint document libraries will store evidence and generated documents, and Power Automate will orchestrate workflows and generate document outputs.

The process configuration will be defined in versioned JSON files stored in GitHub. JSON will define stages, questions, validation, hard stops, evidence requirements, output mappings, and app behavior. It will not store client responses or operational records.

| Long-term direction: the Power Apps interface may later be replaced or complemented by an ASP.NET Core application. The structured data model and stable identifiers are being designed now so migration to Dataverse or SQL remains practical. |
| --- |

# 2. Approved Architectural Decisions

| Area | Decision | Reason |
| --- | --- | --- |
| Application model | One Data4Mat Operations App with modules | Shared clients, navigation, permissions, findings, and workflows |
| Initial app technology | Power Apps canvas app | Fast internal delivery with browser and iPhone access |
| Operational data | Structured SharePoint Lists | Searchable, reusable, reportable, and migration-friendly |
| Files and evidence | SharePoint document libraries | Existing Data4Mat structure and Microsoft 365 integration |
| Workflow | Power Automate solution-aware flows | Direct orchestration, document generation, and approvals |
| Process configuration | Versioned JSON | Process changes without rebuilding the entire app |
| Source control | Private GitHub repository | Review, history, validation, rollback, and deployment automation |
| Word documents | Guidance and generated outputs only | Word is not the source of truth |
| Future platform | ASP.NET Core with Dataverse or SQL as needed | Custom application growth without discarding the process model |

# 3. Governing Operating Principles

The system design must reinforce Data4Mat operating rules rather than merely record activity. The following principles apply across modules:

- Evidence before action.

- No access without documentation.

- No change without a verified backup.

- No assumptions without verification.

- No undocumented work.

- All work must be traceable.

- All decisions must be reversible where technically possible.

- All risks must be explicit.

Takeover work must follow the approved order. Access, backups, and DNS are hard gates. Skipping a gate is not permitted. Security requirements include MFA for administrative systems, unique credentials, least privilege, and explicit escalation when minimum controls cannot be enforced.

Client-facing communication must be derived from internal records, avoid unexplained jargon and blame, and never make unsupported promises.

# 4. Data4Mat Operations App

## 4.1 Application scope

- Home and assigned-work dashboard

- Client selection and client workspace

- Takeover Audit

- Change Control

- Security

- Maintenance

- Client Communication

- Supplier Management

- Quality Gates

- Issues and Remediation

- Documents and Reports

- Administration

Only the Takeover Audit module will be built initially. The application shell, navigation, shared client context, and data conventions will be designed so additional modules can be added without creating separate apps.

## 4.2 User experience

| Desktop/browser | iPhone/mobile |
| --- | --- |
| Client navigation, stage list, form, findings, and evidence can be visible together. | One focused task, stage, or question at a time. |
| Suitable for detailed review, management views, and remediation planning. | Suitable for short observations, status updates, evidence capture, and field work. |
| Multi-column responsive layout. | Large controls, simple navigation, and minimal horizontal scrolling. |

## 4.3 Primary user journey

1. Open the Data4Mat Operations App.

1. Select a client.

1. Open the client workspace.

1. Select the relevant operational module.

1. Create or open a process record.

1. Complete required stages and questions.

1. Record findings and attach evidence.

1. Create remediation actions and approvals.

1. Generate internal and client-facing documents.

# 5. Data Architecture

SharePoint Lists will initially store structured data. The design will use stable identifiers and separate entities rather than one oversized list. This makes later migration to Dataverse or SQL significantly easier.

| Entity | Purpose |
| --- | --- |
| Client Register | Existing client identity and operational reference |
| Takeover Audits | One record per client audit |
| Audit Stage Records | One record per audit stage |
| Audit Responses | Question responses and response metadata |
| Findings | Observed facts, risks, assessments, and recommendations |
| Evidence Register | Evidence metadata and links to files |
| Remediation Actions | Actions created from approved findings |
| Approvals | Review and approval records |
| Generated Documents | Document metadata, type, version, and storage link |

## 5.1 Migration principles

- Use stable business identifiers such as AuditID, StageRecordID, QuestionID, FindingID, EvidenceID, and ActionID.

- Do not use visible question text as an identifier.

- Avoid storing several unrelated values in one text field.

- Avoid business logic hidden only in SharePoint formatting or calculated columns.

- Use person fields for convenience, but retain durable user identifiers where needed.

- Store files in libraries and metadata in lists.

- Keep SharePoint-specific column names behind a logical entity model.

# 6. JSON-Driven Process Configuration

JSON defines how a process should work. SharePoint Lists record what happened in a specific client engagement.

| JSON controls | Lists store |
| --- | --- |
| Stages, sequence, dependencies, and hard stops | Audit instances and current stage |
| Question catalogue and response types | Actual client responses |
| Validation and evidence requirements | Evidence records and links |
| Finding and blocking rules | Findings, severity, risk, and status |
| Document output mappings | Generated-document records |
| Help text and feature configuration | Operational history and approvals |

## 6.1 Configuration files

| File | Purpose |
| --- | --- |
| config/takeover-audit/process.json | Stages, order, dependencies, statuses, hard stops, and storage mappings |
| config/takeover-audit/questions.json | Questions, response types, validation, evidence, and blocking behavior |
| config/takeover-audit/output-mapping.json | Mappings for internal, management, and client documents |
| config/takeover-audit/schema/*.schema.json | JSON Schema validation |

## 6.2 Versioning rules

- Every process and question catalogue has a semantic version and effective date.

- Each audit stores the configuration version used when it was created.

- Active audits remain on their starting version unless explicitly upgraded.

- Completed audits are never retroactively changed.

- Retired questions are marked inactive; identifiers are never reused.

- JSON must pass schema and integrity validation before release.

# 7. Word Document Strategy

Word documents have three approved purposes. They are not the source of truth and are not the primary data-entry interface.

| Document set | Audience | Purpose |
| --- | --- | --- |
| Guidance set | Data4Mat personnel | Procedures, definitions, evidence requirements, hard stops, examples, and completion criteria |
| Internal client set | Employees, managers, specialists, and authorized contractors | Detailed findings, evidence references, risk, uncertainty, recommendations, effort, dependencies, and internal remediation planning |
| Client set | Client decision-makers and non-technical stakeholders | Clear findings, business relevance, recommendations, decisions required, and next steps |

Internal and client documents will be generated from the same verified structured records, but they will not be simple copies. Internal assessment, internal notes, and client-safe explanation must be stored separately.

# 8. Takeover Audit Module

## 8.1 Approved stage sequence

| Code | Stage | Purpose |
| --- | --- | --- |
| 00 | Commercial Scope | Defines engagement boundaries and commercial dependencies |
| 01 | Access | Confirms required administrative and operational access |
| 02 | Backups | Verifies that usable backups exist |
| 03 | DNS | Confirms DNS control and inventory |
| 04 | Hosting | Assesses hosting ownership, platform, and dependencies |
| 05 | Application | Assesses application architecture, components, and condition |
| 06 | Security | Assesses access controls, vulnerabilities, and prohibited states |
| 07 | Performance | Assesses measurable performance and bottlenecks |
| 08 | Compliance | Assesses applicable privacy, legal, and policy obligations |
| 09 | Issues | Consolidates and reviews findings |
| 10 | Remediation Plan | Creates approved actions, priorities, and dependencies |

## 8.2 Hard stops

- If access is unclear, stop.

- If a usable backup has not been verified, stop.

- If DNS control is unknown, stop.

The app and automation must enforce these gates. They cannot be bypassed merely by navigating to the next screen.

## 8.3 Status model

- Not Started

- In Progress

- Blocked

- Ready for Review

- Completed

- Reopened

# 9. Client Provisioning Automation

The existing client folder structure remains fixed. Provisioning will use one orchestrator flow that directly calls child flows in sequence. The Automation Queue may remain as a status and audit record, but it will not control which flow runs next.

1. 00 - Initialize client provisioning sequence

1. 01 - Create Client Main folder structure

1. 02 - Create Client subfolder structure

1. 03 - Generate Takeover Audit documents

1. 04 - Generate Change Control documents

1. 05 - Generate Client Communication documents

1. 06 - Generate Security documents

1. 07 - Generate Maintenance documents

1. 08 - Generate Supplier Management documents

1. 99 - Finalize client provisioning

Flows 01 and 02 have been created and tested successfully. Flow 01 creates the client main folder. Flow 02 creates all approved client subfolders. Both use the solution SharePoint connection reference.

## 9.1 Fixed client folder structure

| Folder | Folder |
| --- | --- |
| 00 Commercial Scope | 01 Access |
| 02 Backups | 03 DNS |
| 04 Hosting | 05 Application |
| 06 Security | 07 Performance |
| 08 Compliance | 09 Issues |
| 10 Plan | 11 Change Control |
| 12 Client Communication | 13 Maintenance |
| 14 Suppliers | 15 Quality Gates |
| 16 Invoices | 17 Reports |
| 18 Notes | 99 Archive |

# 10. Power Platform Solution

Solution name: Data4Mat Client Provisioning. The current environment is Data4Mat AB (Default), with Dataverse enabled.

- Use solution-aware cloud flows.

- Use connection references instead of direct personal connections.

- Use environment variables for site URLs, list names, library names, and configuration paths.

- Create child flows in the same solution as the parent orchestrator.

- Use consistent child-flow inputs and outputs.

- Stop progression on failure and preserve completed work.

- Make folder and document operations idempotent before production use.

The SharePoint connection reference is named D4M SharePoint Connection and is mapped to the verified working SharePoint connection.

# 11. GitHub and Source Control

Repository: https://github.com/data4mat-group/data4mat-operations

GitHub is the authoritative source for process configuration, schemas, validation scripts, Power Platform solution source, deployment configuration, and technical documentation. SharePoint will hold deployed runtime JSON copies and operational data.

| Path | Purpose |
| --- | --- |
| .github/workflows | GitHub Actions |
| config/takeover-audit | Process, questions, mappings, and schemas |
| config/change-control | Future Change Control configuration |
| config/security | Future Security configuration |
| config/maintenance | Future Maintenance configuration |
| config/supplier-management | Future Supplier Management configuration |
| solutions/Data4MatOperations | Unpacked Power Platform solution source |
| deployment | Environment and deployment settings |
| scripts | Validation and deployment scripts |
| docs | Architecture, data model, and operating documentation |

## 11.1 Current repository status

- Private repository created under the data4mat-group account.

- Initial folder structure committed and pushed.

- Node-based validation project initialized.

- AJV and ajv-formats installed as development dependencies.

- node_modules excluded through .gitignore.

- Takeover Audit process definition and schema created and validated.

- Takeover Audit question catalogue foundation and schema created and validated.

- Validation scripts available through npm run validate.

## 11.2 Preferred integration path

1. Edit configuration in GitHub through branches and pull requests.

1. Validate JSON syntax, schemas, identifiers, references, and business rules.

1. Merge approved changes to main.

1. Use GitHub Actions to publish approved runtime JSON to SharePoint through Microsoft Graph.

1. Export and unpack Power Platform solutions into the repository.

1. Run solution checks and package deployment artifacts.

1. Deploy connection references and environment variables using deployment settings.

# 12. Planned ASP.NET Evolution

The initial Power Apps implementation is not intended to lock Data4Mat into Power Apps. The long-term application may use ASP.NET Core for a richer internal system and a separate client portal.

- ASP.NET Core can consume the same logical entities through Microsoft Graph while SharePoint remains the storage layer.

- Structured records can later be migrated to Dataverse or SQL Server.

- SharePoint may continue as the evidence and generated-document repository.

- The JSON process definitions and stable identifiers remain reusable.

- Client-facing access should be a separate portal, not part of the internal operations app.

# 13. Current Implementation Status

| Area | Status | Notes |
| --- | --- | --- |
| Architecture direction | Approved | One modular internal operations app |
| Word document strategy | Approved | Guidance, internal client, and client sets |
| Data storage direction | Approved | SharePoint Lists initially |
| JSON configuration direction | Approved | GitHub source; SharePoint runtime copy |
| GitHub repository | Complete | Created, structured, and pushing successfully |
| Process JSON and schema | Complete | Validated |
| Question catalogue foundation | Complete | Validated; actual questions not yet populated |
| Flow 01 | Tested | Creates client main folder |
| Flow 02 | Tested | Creates all client subfolders |
| Takeover Audit app | Not started | Planning and data model first |
| SharePoint audit lists | Not started | To be defined from approved entities |
| Document output mappings | Not started | To follow data and reporting requirements |

# 14. Immediate Next Steps

1. Extend the question schema with a controlled RepeatingCollection response type.

1. Define the actual questions for 00 Commercial Scope.

1. Classify Commercial Scope data into single responses, repeating collections, findings, and approvals.

1. Add cross-file integrity validation so every question stageId exists in process.json and all IDs are unique.

1. Define the SharePoint list columns and relationships from the logical entity model.

1. Create output-mapping.json and its schema.

1. Create a GitHub Actions validation workflow.

1. Create the SharePoint Configuration/Operations App library path for deployed runtime JSON.

1. Build the Power Apps shell, client selection, client workspace, and Takeover Audit overview.

1. Implement Commercial Scope, Access, Backups, and DNS before expanding the remaining stages.

# 15. Definitions and Boundaries

| Term | Meaning in this architecture |
| --- | --- |
| Source of truth | Structured operational records in SharePoint Lists initially |
| Process configuration | Versioned JSON defining what the process contains and how it behaves |
| Runtime configuration | Approved JSON copy deployed to SharePoint for the app and flows |
| Evidence | Files in SharePoint libraries plus structured metadata records |
| Guidance document | Reusable operating instruction, not client-specific data |
| Internal client document | Detailed generated report for Data4Mat personnel |
| Client document | Generated client-safe report based on approved internal records |
| Solution | Power Platform container for flows, connection references, environment variables, and the app |

| This document records the approved direction as of Version 1.0. Future changes should be made through controlled updates to the architecture, configuration schemas, and repository documentation rather than through undocumented changes in Power Apps, SharePoint, or Power Automate. |
| --- |
