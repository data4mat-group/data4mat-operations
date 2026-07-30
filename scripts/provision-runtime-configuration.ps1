param(
  [string]$SiteUrl = "https://data4matgroup.sharepoint.com/sites/data4matoperations",
  [string]$ClientId = "9ab7f9fd-440f-4f3b-aab0-84e1a10218c0"
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Ensure-List {
  param(
    [Parameter(Mandatory)] [string]$Title,
    [Parameter(Mandatory)] [string]$Description
  )

  $list = Get-PnPList -Identity $Title -ErrorAction SilentlyContinue

  if (-not $list) {
    Write-Host "Creating list: $Title"
    New-PnPList `
      -Title $Title `
      -Template GenericList `
      -EnableVersioning `
      -OnQuickLaunch:$false | Out-Null
  }
  else {
    Write-Host "List already exists: $Title"
  }

  Set-PnPList `
    -Identity $Title `
    -Description $Description `
    -EnableVersioning $true `
    -MajorVersions 50 | Out-Null

  Set-PnPField `
    -List $Title `
    -Identity "Title" `
    -Values @{
    Title    = "Configuration Row"
    Required = $false
  } | Out-Null
}

function Ensure-FieldFromXml {
  param(
    [Parameter(Mandatory)] [string]$ListTitle,
    [Parameter(Mandatory)] [string]$InternalName,
    [Parameter(Mandatory)] [string]$DisplayName,
    [Parameter(Mandatory)] [ValidateSet("Text", "Note", "Boolean", "Number", "DateTime")] [string]$Type,
    [bool]$Required = $false,
    [bool]$Indexed = $false,
    [bool]$Unique = $false
  )

  $existing = Get-PnPField -List $ListTitle -Identity $InternalName -ErrorAction SilentlyContinue
  if ($existing) {
    Write-Host "  Field already exists: $ListTitle.$InternalName"
    return
  }

  $requiredValue = if ($Required) { "TRUE" } else { "FALSE" }
  $indexedValue = if ($Indexed -or $Unique) { "TRUE" } else { "FALSE" }
  $uniqueValue = if ($Unique) { "TRUE" } else { "FALSE" }

  $attributes = @(
    "Type=`"$Type`""
    "Name=`"$InternalName`""
    "StaticName=`"$InternalName`""
    "DisplayName=`"$DisplayName`""
    "Required=`"$requiredValue`""
    "Indexed=`"$indexedValue`""
    "EnforceUniqueValues=`"$uniqueValue`""
    "Group=`"Data4Mat Runtime Configuration`""
  )

  if ($Type -eq "Note") {
    $attributes += "NumLines=`"12`""
    $attributes += "RichText=`"FALSE`""
    $attributes += "AppendOnly=`"FALSE`""
  }

  if ($Type -eq "DateTime") {
    $attributes += "Format=`"DateTime`""
  }

  $fieldXml = "<Field $($attributes -join ' ') />"

  Write-Host "  Creating field: $ListTitle.$InternalName"
  Add-PnPFieldFromXml -List $ListTitle -FieldXml $fieldXml | Out-Null
}

function Add-StandardRuntimeFields {
  param([string]$ListTitle)

  Ensure-FieldFromXml -ListTitle $ListTitle -InternalName "ConfigurationRowID" -DisplayName "Configuration Row ID" -Type Text -Required $true -Unique $true
  Ensure-FieldFromXml -ListTitle $ListTitle -InternalName "DeploymentID" -DisplayName "Deployment ID" -Type Text -Required $true -Indexed $true
  Ensure-FieldFromXml -ListTitle $ListTitle -InternalName "SourceCommitSHA" -DisplayName "Source Commit SHA" -Type Text
  Ensure-FieldFromXml -ListTitle $ListTitle -InternalName "IsActive" -DisplayName "Is Active" -Type Boolean -Required $true -Indexed $true
}

function Ensure-View {
  param(
    [Parameter(Mandatory)] [string]$ListTitle,
    [Parameter(Mandatory)] [string[]]$Fields
  )

  $viewTitle = "Runtime Configuration"
  $view = Get-PnPView -List $ListTitle -Identity $viewTitle -ErrorAction SilentlyContinue

  if (-not $view) {
    Add-PnPView `
      -List $ListTitle `
      -Title $viewTitle `
      -Fields $Fields `
      -SetAsDefault | Out-Null
  }
  else {
    Set-PnPView `
      -List $ListTitle `
      -Identity $viewTitle `
      -Fields $Fields | Out-Null
  }
}

Write-Step "Connecting to SharePoint"
Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

$lists = @(
  @{
    Title       = "ConfigurationDeployments"
    Description = "Generated deployment records for runtime configuration synchronized from GitHub. Do not edit manually."
  },
  @{
    Title       = "ProcessConfigurations"
    Description = "Generated process-level runtime configuration synchronized from process.json. Do not edit manually."
  },
  @{
    Title       = "ProcessStageConfigurations"
    Description = "Generated process-stage runtime configuration synchronized from process.json. Do not edit manually."
  },
  @{
    Title       = "ProcessRuleConfigurations"
    Description = "Generated process and stage rule configuration synchronized from process.json. Do not edit manually."
  },
  @{
    Title       = "QuestionConfigurations"
    Description = "Generated question definitions synchronized from questions.json. Do not edit manually."
  },
  @{
    Title       = "QuestionChoiceConfigurations"
    Description = "Generated top-level question choices synchronized from questions.json. Do not edit manually."
  },
  @{
    Title       = "QuestionBlockingRuleConfigurations"
    Description = "Generated question blocking rules synchronized from questions.json. Do not edit manually."
  },
  @{
    Title       = "CollectionConfigurations"
    Description = "Generated repeating-collection definitions synchronized from questions.json. Do not edit manually."
  },
  @{
    Title       = "CollectionFieldConfigurations"
    Description = "Generated repeating-collection field definitions synchronized from questions.json. Do not edit manually."
  },
  @{
    Title       = "CollectionFieldChoiceConfigurations"
    Description = "Generated repeating-collection field choices synchronized from questions.json. Do not edit manually."
  },
  @{
    Title       = "ValueSetConfigurations"
    Description = "Generated reusable value-set definitions synchronized from value-sets.json. Do not edit manually."
  },
  @{
    Title       = "ValueSetChoiceConfigurations"
    Description = "Generated reusable value-set choices synchronized from value-sets.json. Do not edit manually."
  }
)

Write-Step "Creating runtime configuration lists"
foreach ($listDefinition in $lists) {
  Ensure-List -Title $listDefinition.Title -Description $listDefinition.Description
}

Write-Step "Configuring ConfigurationDeployments"
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "DeploymentID" -DisplayName "Deployment ID" -Type Text -Required $true -Unique $true
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "ProcessID" -DisplayName "Process ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "ProcessVersion" -DisplayName "Process Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "CatalogueID" -DisplayName "Catalogue ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "CatalogueVersion" -DisplayName "Catalogue Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "RuntimeStorageVersion" -DisplayName "Runtime Storage Version" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "SourceCommitSHA" -DisplayName "Source Commit SHA" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "DeploymentStatus" -DisplayName "Deployment Status" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "IsActive" -DisplayName "Is Active" -Type Boolean -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "DeployedDate" -DisplayName "Deployed Date" -Type DateTime -Required $true
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "ActivatedDate" -DisplayName "Activated Date" -Type DateTime
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "VerificationSummary" -DisplayName "Verification Summary" -Type Note
Ensure-FieldFromXml -ListTitle "ConfigurationDeployments" -InternalName "ErrorDetails" -DisplayName "Error Details" -Type Note

Write-Step "Configuring ProcessConfigurations"
Add-StandardRuntimeFields -ListTitle "ProcessConfigurations"
Ensure-FieldFromXml -ListTitle "ProcessConfigurations" -InternalName "ProcessID" -DisplayName "Process ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ProcessConfigurations" -InternalName "ProcessName" -DisplayName "Process Name" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "ProcessConfigurations" -InternalName "ProcessVersion" -DisplayName "Process Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ProcessConfigurations" -InternalName "SchemaVersion" -DisplayName "Schema Version" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "ProcessConfigurations" -InternalName "EffectiveDate" -DisplayName "Effective Date" -Type DateTime -Required $true
Ensure-FieldFromXml -ListTitle "ProcessConfigurations" -InternalName "ConfigurationStatus" -DisplayName "Configuration Status" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "ProcessConfigurations" -InternalName "Description" -DisplayName "Description" -Type Note
Ensure-FieldFromXml -ListTitle "ProcessConfigurations" -InternalName "AllowedProcessStatusesJson" -DisplayName "Allowed Process Statuses JSON" -Type Note
Ensure-FieldFromXml -ListTitle "ProcessConfigurations" -InternalName "AllowedStageStatusesJson" -DisplayName "Allowed Stage Statuses JSON" -Type Note
Ensure-FieldFromXml -ListTitle "ProcessConfigurations" -InternalName "ProgressionPolicyJson" -DisplayName "Progression Policy JSON" -Type Note
Ensure-FieldFromXml -ListTitle "ProcessConfigurations" -InternalName "DefaultStorageMappingsJson" -DisplayName "Default Storage Mappings JSON" -Type Note

Write-Step "Configuring ProcessStageConfigurations"
Add-StandardRuntimeFields -ListTitle "ProcessStageConfigurations"
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "ProcessID" -DisplayName "Process ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "ProcessVersion" -DisplayName "Process Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "StageID" -DisplayName "Stage ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "StageCode" -DisplayName "Stage Code" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "StageName" -DisplayName "Stage Name" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "StageOrder" -DisplayName "Stage Order" -Type Number -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "RequiredStage" -DisplayName "Required Stage" -Type Boolean -Required $true
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "PreviousStageID" -DisplayName "Previous Stage ID" -Type Text
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "NextStageID" -DisplayName "Next Stage ID" -Type Text
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "HardStopStage" -DisplayName "Hard Stop Stage" -Type Boolean -Required $true
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "StorageMappingsJson" -DisplayName "Storage Mappings JSON" -Type Note
Ensure-FieldFromXml -ListTitle "ProcessStageConfigurations" -InternalName "CompletionRuleJson" -DisplayName "Completion Rule JSON" -Type Note

Write-Step "Configuring ProcessRuleConfigurations"
Add-StandardRuntimeFields -ListTitle "ProcessRuleConfigurations"
Ensure-FieldFromXml -ListTitle "ProcessRuleConfigurations" -InternalName "ProcessID" -DisplayName "Process ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ProcessRuleConfigurations" -InternalName "ProcessVersion" -DisplayName "Process Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ProcessRuleConfigurations" -InternalName "StageID" -DisplayName "Stage ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ProcessRuleConfigurations" -InternalName "RuleID" -DisplayName "Rule ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ProcessRuleConfigurations" -InternalName "RuleType" -DisplayName "Rule Type" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "ProcessRuleConfigurations" -InternalName "Condition" -DisplayName "Condition" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "ProcessRuleConfigurations" -InternalName "Message" -DisplayName "Message" -Type Note -Required $true

Write-Step "Configuring QuestionConfigurations"
Add-StandardRuntimeFields -ListTitle "QuestionConfigurations"
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "CatalogueID" -DisplayName "Catalogue ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "CatalogueVersion" -DisplayName "Catalogue Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "QuestionID" -DisplayName "Question ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "StageID" -DisplayName "Stage ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "QuestionOrder" -DisplayName "Question Order" -Type Number -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "RequiredQuestion" -DisplayName "Required Question" -Type Boolean -Required $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "QuestionText" -DisplayName "Question Text" -Type Note -Required $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "HelpText" -DisplayName "Help Text" -Type Note
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "ResponseType" -DisplayName "Response Type" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "DefaultValueJson" -DisplayName "Default Value JSON" -Type Note
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "ValidationJson" -DisplayName "Validation JSON" -Type Note
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "EvidenceRequired" -DisplayName "Evidence Required" -Type Boolean -Required $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "EvidenceGuidance" -DisplayName "Evidence Guidance" -Type Note
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "CreatesFinding" -DisplayName "Creates Finding" -Type Boolean -Required $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "StorageEntity" -DisplayName "Storage Entity" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "InternalReport" -DisplayName "Internal Report" -Type Boolean -Required $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "ClientReport" -DisplayName "Client Report" -Type Boolean -Required $true
Ensure-FieldFromXml -ListTitle "QuestionConfigurations" -InternalName "ClientSafeLabel" -DisplayName "Client Safe Label" -Type Text

Write-Step "Configuring QuestionChoiceConfigurations"
Add-StandardRuntimeFields -ListTitle "QuestionChoiceConfigurations"
Ensure-FieldFromXml -ListTitle "QuestionChoiceConfigurations" -InternalName "CatalogueID" -DisplayName "Catalogue ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionChoiceConfigurations" -InternalName "CatalogueVersion" -DisplayName "Catalogue Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionChoiceConfigurations" -InternalName "QuestionID" -DisplayName "Question ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionChoiceConfigurations" -InternalName "ChoiceValue" -DisplayName "Choice Value" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "QuestionChoiceConfigurations" -InternalName "ChoiceLabel" -DisplayName "Choice Label" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "QuestionChoiceConfigurations" -InternalName "ChoiceOrder" -DisplayName "Choice Order" -Type Number -Required $true -Indexed $true
Ensure-FieldFromXml `
  -ListTitle "QuestionChoiceConfigurations" `
  -InternalName "ChoiceActive" `
  -DisplayName "Choice Active" `
  -Type Boolean `
  -Required $true

Write-Step "Configuring QuestionBlockingRuleConfigurations"
Add-StandardRuntimeFields -ListTitle "QuestionBlockingRuleConfigurations"
Ensure-FieldFromXml -ListTitle "QuestionBlockingRuleConfigurations" -InternalName "CatalogueID" -DisplayName "Catalogue ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionBlockingRuleConfigurations" -InternalName "CatalogueVersion" -DisplayName "Catalogue Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionBlockingRuleConfigurations" -InternalName "QuestionID" -DisplayName "Question ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionBlockingRuleConfigurations" -InternalName "RuleID" -DisplayName "Rule ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "QuestionBlockingRuleConfigurations" -InternalName "Operator" -DisplayName "Operator" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "QuestionBlockingRuleConfigurations" -InternalName "ValuesJson" -DisplayName "Values JSON" -Type Note -Required $true
Ensure-FieldFromXml -ListTitle "QuestionBlockingRuleConfigurations" -InternalName "Message" -DisplayName "Message" -Type Note -Required $true

Write-Step "Configuring CollectionConfigurations"
Add-StandardRuntimeFields -ListTitle "CollectionConfigurations"
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "CatalogueID" -DisplayName "Catalogue ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "CatalogueVersion" -DisplayName "Catalogue Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "QuestionID" -DisplayName "Question ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "EntityType" -DisplayName "Entity Type" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "MinimumItems" -DisplayName "Minimum Items" -Type Number -Required $true
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "MaximumItems" -DisplayName "Maximum Items" -Type Number
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "AllowAdd" -DisplayName "Allow Add" -Type Boolean -Required $true
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "AllowEdit" -DisplayName "Allow Edit" -Type Boolean -Required $true
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "AllowDelete" -DisplayName "Allow Delete" -Type Boolean -Required $true
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "EmptyMessage" -DisplayName "Empty Message" -Type Note
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "AddButtonLabel" -DisplayName "Add Button Label" -Type Text
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "SummaryFieldID" -DisplayName "Summary Field ID" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "SummaryPrefix" -DisplayName "Summary Prefix" -Type Text
Ensure-FieldFromXml -ListTitle "CollectionConfigurations" -InternalName "SummaryFallback" -DisplayName "Summary Fallback" -Type Text

Write-Step "Configuring CollectionFieldConfigurations"
Add-StandardRuntimeFields -ListTitle "CollectionFieldConfigurations"
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "CatalogueID" -DisplayName "Catalogue ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "CatalogueVersion" -DisplayName "Catalogue Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "QuestionID" -DisplayName "Question ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "FieldID" -DisplayName "Field ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "FieldLabel" -DisplayName "Field Label" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "FieldHelpText" -DisplayName "Field Help Text" -Type Note
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "ResponseType" -DisplayName "Response Type" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "RequiredField" -DisplayName "Required Field" -Type Boolean -Required $true
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "FieldOrder" -DisplayName "Field Order" -Type Number -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "ValidationJson" -DisplayName "Validation JSON" -Type Note
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "DefaultValueJson" -DisplayName "Default Value JSON" -Type Note
Ensure-FieldFromXml -ListTitle "CollectionFieldConfigurations" -InternalName "ValueSetID" -DisplayName "Value Set ID" -Type Text -Indexed $true

Write-Step "Configuring CollectionFieldChoiceConfigurations"
Add-StandardRuntimeFields -ListTitle "CollectionFieldChoiceConfigurations"
Ensure-FieldFromXml -ListTitle "CollectionFieldChoiceConfigurations" -InternalName "CatalogueID" -DisplayName "Catalogue ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionFieldChoiceConfigurations" -InternalName "CatalogueVersion" -DisplayName "Catalogue Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionFieldChoiceConfigurations" -InternalName "QuestionID" -DisplayName "Question ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionFieldChoiceConfigurations" -InternalName "FieldID" -DisplayName "Field ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "CollectionFieldChoiceConfigurations" -InternalName "ChoiceValue" -DisplayName "Choice Value" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "CollectionFieldChoiceConfigurations" -InternalName "ChoiceLabel" -DisplayName "Choice Label" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "CollectionFieldChoiceConfigurations" -InternalName "ChoiceOrder" -DisplayName "Choice Order" -Type Number -Required $true -Indexed $true
Ensure-FieldFromXml `
  -ListTitle "CollectionFieldChoiceConfigurations" `
  -InternalName "ChoiceActive" `
  -DisplayName "Choice Active" `
  -Type Boolean `
  -Required $true

Write-Step "Configuring ValueSetConfigurations"
Add-StandardRuntimeFields -ListTitle "ValueSetConfigurations"
Ensure-FieldFromXml -ListTitle "ValueSetConfigurations" -InternalName "CatalogueID" -DisplayName "Catalogue ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ValueSetConfigurations" -InternalName "CatalogueVersion" -DisplayName "Catalogue Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ValueSetConfigurations" -InternalName "ValueSetID" -DisplayName "Value Set ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ValueSetConfigurations" -InternalName "ValueSetLabel" -DisplayName "Value Set Label" -Type Text -Required $true

Write-Step "Configuring ValueSetChoiceConfigurations"
Add-StandardRuntimeFields -ListTitle "ValueSetChoiceConfigurations"
Ensure-FieldFromXml -ListTitle "ValueSetChoiceConfigurations" -InternalName "CatalogueID" -DisplayName "Catalogue ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ValueSetChoiceConfigurations" -InternalName "CatalogueVersion" -DisplayName "Catalogue Version" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ValueSetChoiceConfigurations" -InternalName "ValueSetID" -DisplayName "Value Set ID" -Type Text -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ValueSetChoiceConfigurations" -InternalName "ChoiceValue" -DisplayName "Choice Value" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "ValueSetChoiceConfigurations" -InternalName "ChoiceLabel" -DisplayName "Choice Label" -Type Text -Required $true
Ensure-FieldFromXml -ListTitle "ValueSetChoiceConfigurations" -InternalName "ChoiceOrder" -DisplayName "Choice Order" -Type Number -Required $true -Indexed $true
Ensure-FieldFromXml -ListTitle "ValueSetChoiceConfigurations" -InternalName "ChoiceActive" -DisplayName "Choice Active" -Type Boolean -Required $true

Write-Step "Configuring default views"
Ensure-View -ListTitle "ConfigurationDeployments" -Fields @(
  "DeploymentID", "ProcessVersion", "CatalogueVersion", "SourceCommitSHA",
  "DeploymentStatus", "IsActive", "DeployedDate"
)

Ensure-View -ListTitle "ProcessConfigurations" -Fields @(
  "ConfigurationRowID", "ProcessID", "ProcessVersion", "ConfigurationStatus",
  "EffectiveDate", "IsActive"
)

Ensure-View -ListTitle "ProcessStageConfigurations" -Fields @(
  "ConfigurationRowID", "ProcessID", "ProcessVersion", "StageCode", "StageID",
  "StageName", "StageOrder", "RequiredStage", "HardStopStage", "IsActive"
)

Ensure-View -ListTitle "ProcessRuleConfigurations" -Fields @(
  "ConfigurationRowID", "ProcessVersion", "StageID", "RuleID", "RuleType",
  "Condition", "IsActive"
)

Ensure-View -ListTitle "QuestionConfigurations" -Fields @(
  "ConfigurationRowID", "CatalogueVersion", "StageID", "QuestionID",
  "QuestionOrder", "ResponseType", "RequiredQuestion", "EvidenceRequired",
  "CreatesFinding", "IsActive"
)

Ensure-View -ListTitle "QuestionChoiceConfigurations" -Fields @(
  "ConfigurationRowID", "CatalogueVersion", "QuestionID", "ChoiceValue",
  "ChoiceLabel", "ChoiceOrder", "IsActive"
)

Ensure-View -ListTitle "QuestionBlockingRuleConfigurations" -Fields @(
  "ConfigurationRowID", "CatalogueVersion", "QuestionID", "RuleID",
  "Operator", "IsActive"
)

Ensure-View -ListTitle "CollectionConfigurations" -Fields @(
  "ConfigurationRowID", "CatalogueVersion", "QuestionID", "EntityType",
  "MinimumItems", "MaximumItems", "AllowAdd", "AllowEdit", "AllowDelete",
  "SummaryFieldID", "SummaryPrefix", "SummaryFallback", "IsActive"
)

Ensure-View -ListTitle "CollectionFieldConfigurations" -Fields @(
  "ConfigurationRowID", "CatalogueVersion", "QuestionID", "FieldID",
  "FieldLabel", "ResponseType", "RequiredField", "FieldOrder", "ValueSetID", "IsActive"
)

Ensure-View -ListTitle "CollectionFieldChoiceConfigurations" -Fields @(
  "ConfigurationRowID", "CatalogueVersion", "QuestionID", "FieldID",
  "ChoiceValue", "ChoiceLabel", "ChoiceOrder", "IsActive"
)

Ensure-View -ListTitle "ValueSetConfigurations" -Fields @(
  "ConfigurationRowID", "CatalogueVersion", "ValueSetID", "ValueSetLabel", "IsActive"
)

Ensure-View -ListTitle "ValueSetChoiceConfigurations" -Fields @(
  "ConfigurationRowID", "CatalogueVersion", "ValueSetID", "ChoiceValue",
  "ChoiceLabel", "ChoiceOrder", "ChoiceActive", "IsActive"
)

Write-Step "Runtime configuration provisioning completed"
Write-Host "Created or verified 12 lists and their fields." -ForegroundColor Green
Write-Host "No configuration rows were synchronized by this script." -ForegroundColor Yellow
