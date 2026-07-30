param(
    [string]$SiteUrl = "https://data4matgroup.sharepoint.com/sites/data4matoperations",
    [string]$ClientId = "9ab7f9fd-440f-4f3b-aab0-84e1a10218c0",
    [switch]$ResetDevelopmentRuntime
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$configRoot = Join-Path $repoRoot "config\takeover-audit"

function Write-Step { param([string]$Message) Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Read-JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Required file not found: $Path" }
    Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100
}
function ConvertTo-CompactJson { param($Value) if ($null -eq $Value) { return $null }; $Value | ConvertTo-Json -Depth 100 -Compress }
function Remove-NullValues {
    param([hashtable]$Values)
    $clean = @{}
    foreach ($key in $Values.Keys) { if ($null -ne $Values[$key]) { $clean[$key] = $Values[$key] } }
    $clean
}
function Add-ConfigurationRow {
    param([string]$List,[hashtable]$Values)
    Add-PnPListItem -List $List -Values (Remove-NullValues $Values) | Out-Null
}
function Get-ItemsForDeployment {
    param([string]$List,[string]$DeploymentID)
    $escaped = [System.Security.SecurityElement]::Escape($DeploymentID)
    $query = "<View><Query><Where><Eq><FieldRef Name='DeploymentID'/><Value Type='Text'>$escaped</Value></Eq></Where></Query><RowLimit Paged='TRUE'>5000</RowLimit></View>"
    @(Get-PnPListItem -List $List -Query $query -PageSize 500)
}
function Set-DeploymentRowsActive {
    param([string]$List,[string]$DeploymentID,[bool]$IsActive)
    foreach ($item in Get-ItemsForDeployment -List $List -DeploymentID $DeploymentID) {
        Set-PnPListItem -List $List -Identity $item.Id -Values @{ IsActive = $IsActive } | Out-Null
    }
}
function Get-ActiveDeploymentItems {
    $query = "<View><Query><Where><Eq><FieldRef Name='IsActive'/><Value Type='Boolean'>1</Value></Eq></Where></Query><RowLimit Paged='TRUE'>5000</RowLimit></View>"
    @(Get-PnPListItem -List "ConfigurationDeployments" -Query $query -PageSize 500)
}
function Clear-ListRows {
    param([Parameter(Mandatory)][string]$List)
    $items = @(Get-PnPListItem -List $List -PageSize 500)
    foreach ($item in $items) {
        Remove-PnPListItem -List $List -Identity $item.Id -Force | Out-Null
    }
    Write-Host "  Cleared $($items.Count) rows from $List"
}
function Get-OptionalArray {
    param($Object,[string]$Name)
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return @() }
    return @($property.Value)
}
function Get-OptionalValue {
    param($Object,[string]$Name)
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}
function Get-RequiredProperty {
    param($Object,[string]$Name)
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value -or "$($property.Value)" -eq "") { throw "Required JSON property is missing or empty: $Name" }
    $property.Value
}

Write-Step "Running repository validation"
Push-Location $repoRoot
try {
    & npm run validate
    if ($LASTEXITCODE -ne 0) { throw "npm run validate failed with exit code $LASTEXITCODE." }
}
finally { Pop-Location }

Write-Step "Reading source configuration"
$process = Read-JsonFile (Join-Path $configRoot "process.json")
$questions = Read-JsonFile (Join-Path $configRoot "questions.json")
$valueSets = Read-JsonFile (Join-Path $configRoot "value-sets.json")
$runtimeStorage = Read-JsonFile (Join-Path $configRoot "runtime-storage.json")

$processId = Get-RequiredProperty $process "processId"
$processVersion = Get-RequiredProperty $process "processVersion"
$catalogueId = Get-RequiredProperty $questions "catalogueId"
$catalogueVersion = Get-RequiredProperty $questions "catalogueVersion"
$runtimeStorageVersion = if ($runtimeStorage.PSObject.Properties["storageVersion"]) { $runtimeStorage.storageVersion } elseif ($runtimeStorage.PSObject.Properties["version"]) { $runtimeStorage.version } elseif ($runtimeStorage.PSObject.Properties["schemaVersion"]) { $runtimeStorage.schemaVersion } else { "1.0.0" }

Push-Location $repoRoot
try {
    $sourceCommitSha = (& git rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($sourceCommitSha)) { throw "Unable to determine the current Git commit SHA." }
}
finally { Pop-Location }

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ")
$deploymentId = "$processId-$processVersion-$catalogueVersion-$timestamp-$($sourceCommitSha.Substring(0,8))"
$deployedDate = (Get-Date).ToUniversalTime()
$runtimeLists = @("ProcessConfigurations","ProcessStageConfigurations","ProcessRuleConfigurations","QuestionConfigurations","QuestionChoiceConfigurations","QuestionBlockingRuleConfigurations","CollectionConfigurations","CollectionFieldConfigurations","CollectionFieldChoiceConfigurations","ValueSetConfigurations","ValueSetChoiceConfigurations")

$expectedCounts = [ordered]@{
    ProcessConfigurations = 1
    ProcessStageConfigurations = @($process.stages).Count
    ProcessRuleConfigurations = 0
    QuestionConfigurations = @($questions.questions).Count
    QuestionChoiceConfigurations = 0
    QuestionBlockingRuleConfigurations = 0
    CollectionConfigurations = 0
    CollectionFieldConfigurations = 0
    CollectionFieldChoiceConfigurations = 0
    ValueSetConfigurations = @($valueSets.valueSets).Count
    ValueSetChoiceConfigurations = 0
}
foreach ($stage in @($process.stages)) { $expectedCounts.ProcessRuleConfigurations += @(Get-OptionalArray $stage "hardStopRules").Count }
foreach ($question in @($questions.questions)) {
    $expectedCounts.QuestionChoiceConfigurations += @(Get-OptionalArray $question "choices").Count
    $expectedCounts.QuestionBlockingRuleConfigurations += @(Get-OptionalArray $question "blockingRules").Count
    if ($question.PSObject.Properties["collection"] -and $null -ne $question.collection) {
        $expectedCounts.CollectionConfigurations++
        $expectedCounts.CollectionFieldConfigurations += @($question.collection.fields).Count
        foreach ($field in @($question.collection.fields)) { $expectedCounts.CollectionFieldChoiceConfigurations += @(Get-OptionalArray $field "choices").Count }
    }
}
foreach ($valueSet in @($valueSets.valueSets)) {
    $expectedCounts.ValueSetChoiceConfigurations += @($valueSet.values).Count
}

Write-Step "Connecting to SharePoint"
Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

if ($ResetDevelopmentRuntime) {
    Write-Step "Resetting development runtime configuration"
    foreach ($list in $runtimeLists) { Clear-ListRows -List $list }
    Clear-ListRows -List "ConfigurationDeployments"
}

$deploymentItem = $null

try {
    Write-Step "Creating inactive deployment record"
    $deploymentItem = Add-PnPListItem -List "ConfigurationDeployments" -Values @{
        Title=$deploymentId; DeploymentID=$deploymentId; ProcessID=$processId; ProcessVersion=$processVersion;
        CatalogueID=$catalogueId; CatalogueVersion=$catalogueVersion; RuntimeStorageVersion="$runtimeStorageVersion";
        SourceCommitSHA=$sourceCommitSha; DeploymentStatus="Loading"; IsActive=$false; DeployedDate=$deployedDate
    }

    Write-Step "Writing process configuration"
    Add-ConfigurationRow "ProcessConfigurations" @{
        Title=$process.processName; ConfigurationRowID="$deploymentId|process|$processId"; DeploymentID=$deploymentId;
        SourceCommitSHA=$sourceCommitSha; IsActive=$false; ProcessID=$processId; ProcessName=$process.processName;
        ProcessVersion=$processVersion; SchemaVersion=$process.schemaVersion; EffectiveDate=[datetime]$process.effectiveDate;
        ConfigurationStatus=$process.status; Description=$process.description;
        AllowedProcessStatusesJson=(ConvertTo-CompactJson $process.allowedProcessStatuses);
        AllowedStageStatusesJson=(ConvertTo-CompactJson $process.allowedStageStatuses);
        ProgressionPolicyJson=(ConvertTo-CompactJson $process.stageProgressionPolicy);
        DefaultStorageMappingsJson=(ConvertTo-CompactJson $process.defaultStorageMappings)
    }

    Write-Step "Writing process stages and rules"
    foreach ($stage in @($process.stages)) {
        Add-ConfigurationRow "ProcessStageConfigurations" @{
            Title="$($stage.code) - $($stage.name)"; ConfigurationRowID="$deploymentId|stage|$($stage.stageId)";
            DeploymentID=$deploymentId; SourceCommitSHA=$sourceCommitSha; IsActive=$false; ProcessID=$processId;
            ProcessVersion=$processVersion; StageID=$stage.stageId; StageCode=$stage.code; StageName=$stage.name;
            StageOrder=[double]$stage.order; RequiredStage=[bool]$stage.required; PreviousStageID=$stage.previousStageId;
            NextStageID=$stage.nextStageId; HardStopStage=[bool]$stage.hardStopStage;
            StorageMappingsJson=(ConvertTo-CompactJson $stage.storageMappings);
            CompletionRuleJson=(ConvertTo-CompactJson $stage.completionRule)
        }
        foreach ($rule in @(Get-OptionalArray $stage "hardStopRules")) {
            Add-ConfigurationRow "ProcessRuleConfigurations" @{
                Title=$rule.ruleId; ConfigurationRowID="$deploymentId|process-rule|$($rule.ruleId)";
                DeploymentID=$deploymentId; SourceCommitSHA=$sourceCommitSha; IsActive=$false; ProcessID=$processId;
                ProcessVersion=$processVersion; StageID=$stage.stageId; RuleID=$rule.ruleId; RuleType=$rule.ruleType;
                Condition=$rule.condition; Message=$rule.message
            }
        }
    }

    Write-Step "Writing reusable value sets"
    foreach ($valueSet in @($valueSets.valueSets)) {
        Add-ConfigurationRow "ValueSetConfigurations" @{
            Title=$valueSet.valueSetId;
            ConfigurationRowID="$deploymentId|value-set|$($valueSet.valueSetId)";
            DeploymentID=$deploymentId; SourceCommitSHA=$sourceCommitSha; IsActive=$false;
            CatalogueID=$valueSets.catalogueId; CatalogueVersion=$valueSets.catalogueVersion;
            ValueSetID=$valueSet.valueSetId; ValueSetLabel=$valueSet.label
        }
        foreach ($choice in @($valueSet.values)) {
            Add-ConfigurationRow "ValueSetChoiceConfigurations" @{
                Title="$($valueSet.valueSetId) - $($choice.value)";
                ConfigurationRowID="$deploymentId|value-set-choice|$($valueSet.valueSetId)|$($choice.value)";
                DeploymentID=$deploymentId; SourceCommitSHA=$sourceCommitSha; IsActive=$false;
                CatalogueID=$valueSets.catalogueId; CatalogueVersion=$valueSets.catalogueVersion;
                ValueSetID=$valueSet.valueSetId; ChoiceValue=$choice.value; ChoiceLabel=$choice.label;
                ChoiceOrder=[double]$choice.order; ChoiceActive=[bool]$choice.active
            }
        }
    }

    Write-Step "Writing question catalogue"
    foreach ($question in @($questions.questions)) {
        $defaultValueJson = if ($question.PSObject.Properties["defaultValue"]) { ConvertTo-CompactJson $question.defaultValue } else { $null }
        $validationJson = if ($question.PSObject.Properties["validation"]) { ConvertTo-CompactJson $question.validation } else { $null }
        $helpText = if ($question.PSObject.Properties["helpText"]) { $question.helpText } else { $null }
        $evidenceGuidance = if ($question.PSObject.Properties["evidenceGuidance"]) { $question.evidenceGuidance } else { $null }
        $clientSafeLabel = if ($question.PSObject.Properties["clientSafeLabel"]) { $question.clientSafeLabel } else { $null }
        Add-ConfigurationRow "QuestionConfigurations" @{
            Title=$question.questionId; ConfigurationRowID="$deploymentId|question|$($question.questionId)";
            DeploymentID=$deploymentId; SourceCommitSHA=$sourceCommitSha; IsActive=$false; CatalogueID=$catalogueId;
            CatalogueVersion=$catalogueVersion; QuestionID=$question.questionId; StageID=$question.stageId;
            QuestionOrder=[double]$question.order; RequiredQuestion=[bool]$question.required; QuestionText=$question.text;
            HelpText=$helpText; ResponseType=$question.responseType; DefaultValueJson=$defaultValueJson;
            ValidationJson=$validationJson; EvidenceRequired=[bool]$question.evidenceRequired;
            EvidenceGuidance=$evidenceGuidance; CreatesFinding=[bool]$question.createsFinding;
            StorageEntity=$question.storageEntity; InternalReport=[bool]$question.internalReport;
            ClientReport=[bool]$question.clientReport; ClientSafeLabel=$clientSafeLabel
        }
        foreach ($choice in @(Get-OptionalArray $question "choices")) {
            Add-ConfigurationRow "QuestionChoiceConfigurations" @{
                Title="$($question.questionId) - $($choice.value)";
                ConfigurationRowID="$deploymentId|question-choice|$($question.questionId)|$($choice.value)";
                DeploymentID=$deploymentId; SourceCommitSHA=$sourceCommitSha; IsActive=$false; CatalogueID=$catalogueId;
                CatalogueVersion=$catalogueVersion; QuestionID=$question.questionId; ChoiceValue=$choice.value;
                ChoiceLabel=$choice.label; ChoiceOrder=[double]$choice.order; ChoiceActive=[bool]$choice.active
            }
        }
        foreach ($rule in @(Get-OptionalArray $question "blockingRules")) {
            Add-ConfigurationRow "QuestionBlockingRuleConfigurations" @{
                Title=$rule.ruleId; ConfigurationRowID="$deploymentId|question-rule|$($question.questionId)|$($rule.ruleId)";
                DeploymentID=$deploymentId; SourceCommitSHA=$sourceCommitSha; IsActive=$false; CatalogueID=$catalogueId;
                CatalogueVersion=$catalogueVersion; QuestionID=$question.questionId; RuleID=$rule.ruleId;
                Operator=$rule.operator; ValuesJson=(ConvertTo-CompactJson $rule.values); Message=$rule.message
            }
        }
        if ($question.PSObject.Properties["collection"] -and $null -ne $question.collection) {
            $collection = $question.collection
            Add-ConfigurationRow "CollectionConfigurations" @{
                Title="$($question.questionId) - $($collection.entityType)";
                ConfigurationRowID="$deploymentId|collection|$($question.questionId)"; DeploymentID=$deploymentId;
                SourceCommitSHA=$sourceCommitSha; IsActive=$false; CatalogueID=$catalogueId;
                CatalogueVersion=$catalogueVersion; QuestionID=$question.questionId; EntityType=$collection.entityType;
                MinimumItems=[double]$collection.minimumItems; MaximumItems=(Get-OptionalValue $collection "maximumItems");
                AllowAdd=[bool]$collection.allowAdd; AllowEdit=[bool]$collection.allowEdit;
                AllowDelete=[bool]$collection.allowDelete; EmptyMessage=$collection.emptyMessage;
                AddButtonLabel=$collection.addButtonLabel; SummaryFieldID=$collection.summaryFieldId;
                SummaryPrefix=(Get-OptionalValue $collection "summaryPrefix");
                SummaryFallback=(Get-OptionalValue $collection "summaryFallback")
            }
            foreach ($field in @($collection.fields)) {
                $fieldHelpText = if ($field.PSObject.Properties["helpText"]) { $field.helpText } else { $null }
                $fieldValidationJson = if ($field.PSObject.Properties["validation"]) { ConvertTo-CompactJson $field.validation } else { $null }
                $fieldDefaultValueJson = if ($field.PSObject.Properties["defaultValue"]) { ConvertTo-CompactJson $field.defaultValue } else { $null }
                Add-ConfigurationRow "CollectionFieldConfigurations" @{
                    Title="$($question.questionId) - $($field.fieldId)";
                    ConfigurationRowID="$deploymentId|collection-field|$($question.questionId)|$($field.fieldId)";
                    DeploymentID=$deploymentId; SourceCommitSHA=$sourceCommitSha; IsActive=$false;
                    CatalogueID=$catalogueId; CatalogueVersion=$catalogueVersion; QuestionID=$question.questionId;
                    FieldID=$field.fieldId; FieldLabel=$field.label; FieldHelpText=$fieldHelpText;
                    ResponseType=$field.responseType; RequiredField=[bool]$field.required; FieldOrder=[double]$field.order;
                    ValidationJson=$fieldValidationJson; DefaultValueJson=$fieldDefaultValueJson;
                    ValueSetID=(Get-OptionalValue $field "valueSetId")
                }
                foreach ($choice in @(Get-OptionalArray $field "choices")) {
                    Add-ConfigurationRow "CollectionFieldChoiceConfigurations" @{
                        Title="$($question.questionId) - $($field.fieldId) - $($choice.value)";
                        ConfigurationRowID="$deploymentId|collection-field-choice|$($question.questionId)|$($field.fieldId)|$($choice.value)";
                        DeploymentID=$deploymentId; SourceCommitSHA=$sourceCommitSha; IsActive=$false;
                        CatalogueID=$catalogueId; CatalogueVersion=$catalogueVersion; QuestionID=$question.questionId;
                        FieldID=$field.fieldId; ChoiceValue=$choice.value; ChoiceLabel=$choice.label;
                        ChoiceOrder=[double]$choice.order; ChoiceActive=[bool]$choice.active
                    }
                }
            }
        }
    }

 Write-Step "Verifying deployment row counts"
$actualCounts = [ordered]@{}
$verificationErrors = @()

foreach ($list in $runtimeLists) {
    $items = @(Get-ItemsForDeployment $list $deploymentId)
    $actualCounts[$list] = $items.Count

    if ($actualCounts[$list] -ne $expectedCounts[$list]) {
        $verificationErrors += "$list expected $($expectedCounts[$list]) rows but found $($actualCounts[$list])."
    }
}

$verificationSummary = [ordered]@{
    deploymentId = $deploymentId
    sourceCommitSha = $sourceCommitSha
    expectedCounts = $expectedCounts
    actualCounts = $actualCounts
    verifiedAt = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json -Depth 20 -Compress

if (@($verificationErrors).Count -gt 0) {
    throw "Deployment verification failed: $($verificationErrors -join ' ')"
}

    Write-Step "Deactivating previous deployment"
    foreach ($activeDeploymentItem in Get-ActiveDeploymentItems) {
        $oldDeploymentId = "$($activeDeploymentItem.FieldValues.DeploymentID)"
        if ($oldDeploymentId -eq $deploymentId) { continue }
        foreach ($list in $runtimeLists) { Set-DeploymentRowsActive $list $oldDeploymentId $false }
        Set-PnPListItem -List "ConfigurationDeployments" -Identity $activeDeploymentItem.Id -Values @{ IsActive=$false; DeploymentStatus="Superseded" } | Out-Null
    }

    Write-Step "Activating verified deployment"
    foreach ($list in $runtimeLists) { Set-DeploymentRowsActive $list $deploymentId $true }
    Set-PnPListItem -List "ConfigurationDeployments" -Identity $deploymentItem.Id -Values @{
        DeploymentStatus="Active"; IsActive=$true; ActivatedDate=(Get-Date).ToUniversalTime();
        VerificationSummary=$verificationSummary; ErrorDetails=""
    } | Out-Null

    Write-Host "`nRuntime configuration synchronization completed." -ForegroundColor Green
    Write-Host "Deployment ID: $deploymentId"
    Write-Host "Source commit: $sourceCommitSha"
    $actualCounts.GetEnumerator() | Sort-Object Name | Format-Table Name,Value -AutoSize
}
catch {
    $failureMessage = $_.Exception.Message
    if ($null -ne $deploymentItem) {
        try { Set-PnPListItem -List "ConfigurationDeployments" -Identity $deploymentItem.Id -Values @{ DeploymentStatus="Failed"; IsActive=$false; ErrorDetails=$failureMessage } | Out-Null }
        catch { Write-Warning "Unable to update the failed deployment record: $($_.Exception.Message)" }
    }
    throw $failureMessage
}
