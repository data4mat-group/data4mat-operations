#Requires -Version 7.4

[CmdletBinding()]
param(
    [string]$SiteUrl = "https://data4matgroup.sharepoint.com/sites/data4matoperations",

    [string]$EntraApplicationId = $env:ENTRAID_APP_ID,

    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ViewDefinitions = @(
    [pscustomobject]@{
        ResourceName = "TakeoverAudits"
        Fields = @(
            "AuditID",
            "ClientID",
            "Status",
            "CurrentStageID",
            "AssignedTo",
            "StartedDate",
            "CompletedDate",
            "Modified"
        )
    },
    [pscustomobject]@{
        ResourceName = "AuditStageRecords"
        Fields = @(
            "StageRecordID",
            "AuditID",
            "StageID",
            "Status",
            "StartedDate",
            "CompletedDate",
            "ReviewedBy",
            "ReviewedDate",
            "Modified"
        )
    },
    [pscustomobject]@{
        ResourceName = "AuditResponses"
        Fields = @(
            "ResponseID",
            "AuditID",
            "StageRecordID",
            "QuestionID",
            "CollectionItemID",
            "FieldID",
            "ResponseType",
            "TextValue",
            "NumberValue",
            "BooleanValue",
            "DateValue",
            "PersonValue",
            "ItemOrder",
            "AnsweredBy",
            "AnsweredDate",
            "Modified"
        )
    },
    [pscustomobject]@{
        ResourceName = "Findings"
        Fields = @(
            "FindingID",
            "AuditID",
            "StageRecordID",
            "QuestionID",
            "FindingType",
            "Reference",
            "FindingTitle",
            "Severity",
            "Priority",
            "Status",
            "Owner",
            "TargetDate",
            "Modified"
        )
    },
    [pscustomobject]@{
        ResourceName = "EvidenceRegister"
        Fields = @(
            "EvidenceID",
            "AuditID",
            "StageRecordID",
            "QuestionID",
            "ResponseID",
            "FindingID",
            "EvidenceType",
            "EvidenceTitle",
            "DocumentURL",
            "RecordedBy",
            "RecordedDate",
            "Modified"
        )
    },
    [pscustomobject]@{
        ResourceName = "RemediationActions"
        Fields = @(
            "RemediationActionID",
            "AuditID",
            "StageRecordID",
            "QuestionID",
            "FindingID",
            "RecordType",
            "ActionReference",
            "ActionTitle",
            "Priority",
            "Owner",
            "TargetDate",
            "Status",
            "ApprovalRequired",
            "Blocking",
            "Modified"
        )
    },
    [pscustomobject]@{
        ResourceName = "Approvals"
        Fields = @(
            "ApprovalID",
            "AuditID",
            "StageRecordID",
            "QuestionID",
            "FindingID",
            "RemediationActionID",
            "ApprovalType",
            "Reference",
            "Decision",
            "Accepted",
            "ApprovedBy",
            "ApprovalDate",
            "ReviewDate",
            "Modified"
        )
    },
    [pscustomobject]@{
        ResourceName = "GeneratedDocuments"
        Fields = @(
            "DocIcon",
            "LinkFilename",
            "DocumentID",
            "AuditID",
            "StageRecordID",
            "DocumentType",
            "DocumentVersion",
            "Status",
            "GeneratedBy",
            "GeneratedDate",
            "ClientVisible",
            "Modified"
        )
    }
)

function Get-DefaultView {
    param(
        [Parameter(Mandatory)]
        [string]$ResourceName
    )

    $views = Get-PnPView `
        -List $ResourceName `
        -Includes DefaultView, ViewFields

    $defaultView = $views |
        Where-Object { $_.DefaultView -eq $true } |
        Select-Object -First 1

    if ($null -eq $defaultView) {
        throw "No default view was found for $ResourceName."
    }

    return $defaultView
}

function Assert-FieldsExist {
    param(
        [Parameter(Mandatory)]
        [string]$ResourceName,

        [Parameter(Mandatory)]
        [string[]]$RequiredFields
    )

    $availableFields = Get-PnPField -List $ResourceName
    $availableInternalNames = @(
        $availableFields | ForEach-Object { $_.InternalName }
    )

    $missingFields = @(
        $RequiredFields |
            Where-Object { $_ -notin $availableInternalNames }
    )

    if ($missingFields.Count -gt 0) {
        throw (
            "$ResourceName is missing fields required by its default view: " +
            ($missingFields -join ", ")
        )
    }
}

function Get-ViewFieldNames {
    param(
        [Parameter(Mandatory)]
        $View
    )

    return @($View.ViewFields | ForEach-Object { [string]$_ })
}

function Test-FieldSequenceEqual {
    param(
        [Parameter(Mandatory)]
        [string[]]$Current,

        [Parameter(Mandatory)]
        [string[]]$Expected
    )

    if ($Current.Count -ne $Expected.Count) {
        return $false
    }

    for ($index = 0; $index -lt $Expected.Count; $index++) {
        if ($Current[$index] -ne $Expected[$index]) {
            return $false
        }
    }

    return $true
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
    $pendingChanges = [System.Collections.Generic.List[object]]::new()

    foreach ($definition in $ViewDefinitions) {
        Assert-FieldsExist `
            -ResourceName $definition.ResourceName `
            -RequiredFields $definition.Fields

        $defaultView = Get-DefaultView -ResourceName $definition.ResourceName
        $currentFields = Get-ViewFieldNames -View $defaultView

        if (-not (Test-FieldSequenceEqual `
            -Current $currentFields `
            -Expected $definition.Fields
        )) {
            $pendingChanges.Add(
                [pscustomobject]@{
                    Definition = $definition
                    View = $defaultView
                    CurrentFields = $currentFields
                }
            )
        }
    }

    if ($ValidateOnly) {
        Write-Host "View validation completed successfully." -ForegroundColor Green
        Write-Host "Views already correct: $($ViewDefinitions.Count - $pendingChanges.Count)"
        Write-Host "Views to update: $($pendingChanges.Count)"

        foreach ($change in $pendingChanges) {
            Write-Host (
                "- $($change.Definition.ResourceName): " +
                "$($change.View.Title)"
            )
        }

        return
    }

    foreach ($change in $pendingChanges) {
        Write-Host (
            "Configuring $($change.Definition.ResourceName) default view " +
            "'$($change.View.Title)'..."
        )

        Set-PnPView `
            -List $change.Definition.ResourceName `
            -Identity $change.View.Id `
            -Fields $change.Definition.Fields |
            Out-Null
    }

    $validationErrors = [System.Collections.Generic.List[string]]::new()

    foreach ($definition in $ViewDefinitions) {
        $defaultView = Get-DefaultView -ResourceName $definition.ResourceName
        $currentFields = Get-ViewFieldNames -View $defaultView

        if (-not (Test-FieldSequenceEqual `
            -Current $currentFields `
            -Expected $definition.Fields
        )) {
            $validationErrors.Add(
                "$($definition.ResourceName) default view does not match the approved field sequence."
            )
        }
    }

    if ($validationErrors.Count -gt 0) {
        Write-Host "Post-configuration validation failed:" -ForegroundColor Red

        foreach ($validationError in $validationErrors) {
            Write-Host "- $validationError" -ForegroundColor Red
        }

        throw "SharePoint view configuration did not complete cleanly."
    }

    Write-Host ""
    Write-Host "Takeover Audit SharePoint views configured successfully." -ForegroundColor Green
    Write-Host "Site: $SiteUrl"
    Write-Host "Default views configured: $($ViewDefinitions.Count)"
    Write-Host "Title removed from working list views: yes"
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
