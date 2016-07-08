# Parse the input arguments
function ParseArguments($input_args) {
	$defaultQueryPath = "Shared%20Queries/Current%20Sprint/Work%20in%20Progress"
	$local:fileName = GetUserConfigFileName
	
    $local:fileExists = Test-Path $local:fileName
	if ($local:fileExists -eq $true) {
		$result = Get-Content -Raw -Path $local:fileName | ConvertFrom-Json
		$result.printHelp = $false;
		$result.debug = $false;
	} else {
		$result = New-Object System.Object
		$result | Add-Member -type NoteProperty -name debug -value $false
		$result | Add-Member -type NoteProperty -name printHelp -value $false
		$result | Add-Member -type NoteProperty -name doNotCopyToClipboard -value $false
		$result | Add-Member -type NoteProperty -name user -value $null
		$result | Add-Member -type NoteProperty -name password -value $null
		$result | Add-Member -type NoteProperty -name host -value $null
		$result | Add-Member -type NoteProperty -name project -value $null
		$result | Add-Member -type NoteProperty -name queryPath -value $defaultQueryPath
	}

	For ($i = 0; $i -lt $input_args.Length; $i++) {
		# Parse the current and next arguments
		$arg = $input_args[$i]
		$hasNextArg = $i -lt $input_args.Length-1
		$nextArg = $null
		if ($hasNextArg) {
			$nextArg = $input_args[$i+1]
		}

		if ($arg -eq "--debug" -or $arg -eq "-D") {
			$result.debug = $true
		}

		if ($arg -eq "--help" -or $arg -eq "-h") {
			$result.printHelp = $true
		}
		
		if ($arg -eq "--doNotCopyToClipboard" -or $arg -eq "-d") {
			$result.doNotCopyToClipboard = $true
		}

		if ($arg -eq "--user" -or $arg -eq "-u") {
			$result.user = "$($nextArg)"
		}
		
		if ($arg -eq "--password" -or $arg -eq "-p") {
			$result.password = "$($nextArg)"
		}

		if ($arg -eq "--host" -or $arg -eq "-h") {
			$result.host = "$($nextArg)"
		}
		
		if ($arg -eq "--project" -or $arg -eq "-r") {
			$result.project = "$($nextArg)"
		}

		if ($arg -eq "--queryPath" -or $arg -eq "-q") {
			$result.queryPath = "$($nextArg)"
		}
	}

	return $result
}

# Check if the arguments used require the help to be printed
function CheckIfMustPrintHelp($printHelp) {
	if ($printHelp) {
		Write-Host ""
		Write-Host "--help `t`t`t -h `t Print usage options"
		Write-Host "--doNotCopyToClipboard `t -d `t If informed, do not copy the result to the clipboard"
		Write-Host "--user `t`t`t -u `t Inform your user name"
		Write-Host "--password `t`t -p `t Inform your authentication token/password"
		Write-Host "--host `t`t`t -h `t Inform your Visual Studio online host"
		Write-Host "--project `t`t -r `t Inform your current project"
		Write-Host "--queryPath `t`t -q `t Inform path of the query used to get the in progress work items in your current project"
		Write-Host "`t`t`t`t Default: Shared%20Queries/Current%20Sprint/Work%20in%20Progress"
		Write-Host ""
		return $true
	}
	return $false
}

# Check, request and store mandatory parameters
function CheckRequestAndStoreMandatoryParameters($arguments) {
	$updateFile = $false

	# This command must be executed four times in order to the curl alias be successfully removed
	If (Test-Path Alias:curl) {Remove-Item Alias:curl}
	If (Test-Path Alias:curl) {Remove-Item Alias:curl}	
	If (Test-Path Alias:curl) {Remove-Item Alias:curl}	
	If (Test-Path Alias:curl) {Remove-Item Alias:curl}	
	
    if (Test-Path Alias:curl) {
        Write-Host 'You need to remove the curl alias and install the real curl utility in order to run this script!'
        return $false
    }

	if ($arguments.host -eq $null) {
		Write-Host 'Informe your host name: (https://{hostname}.visualstudio.com/DefaultCollection/)'
		$arguments.host = Read-Host;
		$updateFile = $true;
	}
	if ($arguments.user -eq $null) {
		Write-Host 'Informe your email:'
		$arguments.user = Read-Host;
		$updateFile = $true;
	}
	if ($arguments.password -eq $null) {
		Write-Host 'Informe your password or authentication token:'
		$arguments.password = Read-Host;
		$updateFile = $true;
	}
	if ($arguments.project -eq $null) {
		Write-Host 'Informe your current project:'
		$arguments.project = Read-Host;
		$updateFile = $true;
	}
	if ($arguments.queryPath -ne $defaultQueryPath) {
		$updateFile = $true;
	}
	if ($arguments.doNotCopyToClipboard -ne $false) {
		$updateFile = $true;
	}
	if ($updateFile) {
		$local:fileName = GetUserConfigFileName
        $local:fileExists = Test-Path $local:fileName
		if ($local:fileExists -eq $true) {
			Remove-Item $local:fileName
		}
		New-Item $local:fileName -type file
		$arguments | ConvertTo-Json | out-file -filepath $local:fileName
	}

	if ($arguments.debug) {
		Write-Host ""
		Write-Host ($arguments | ConvertTo-Json)
		Write-Host ""
	}
	
	return $true
}

function GetUserConfigFileName() {
	$local:directoryName = $env:appdata + '/GetInProgressWorkItemIds/'
	$local:directoryExists = Test-Path $local:directoryName
    if ($local:directoryExists -eq $false) {
		New-Item $local:directoryName -type directory
	}
	$local:fileName = $local:directoryName + 'user.config'
	return $local:fileName
}

# Get the ids of the work items in progress
function GetInProgressWorkItemIds($arguments) {
	$contentType = 'Content-Type: application/json'
	$baseUri = 'https://' + $arguments.host + '.visualstudio.com/DefaultCollection/'
	$workItemsQueryUri = $baseUri + $arguments.project + '/_apis/wit/queries/' + $arguments.queryPath
	$auth = $arguments.user + ':' + $arguments.password
	if ($arguments.debug) {
		Write-Host "baseUri: $baseUri" 
		Write-Host "auth: $auth" 
		Write-Host "contentType: $contentType" 
		Write-Host "workItemsQueryUri: $workItemsQueryUri" 
	}
    $response = curl -k -u $auth -H $contentType $workItemsQueryUri
	if ($arguments.debug) {
		Write-Host "response: $response" 
	}
	$queryId = $response | ConvertFrom-Json | Select-Object -ExpandProperty id
	if ($arguments.debug) {
		Write-Host "queryId: $queryId" 
	}
	$workItemsInProgressIdsUri = $baseUri + '/' + $arguments.project + '/_apis/wit/wiql/' + $queryId
	if ($arguments.debug) {
		Write-Host "workItemsInProgressIdsUri: $workItemsInProgressIdsUri" 
	}
	$workItemsInProgressIds = curl -k -u $auth -H $contentType $workItemsInProgressIdsUri | ConvertFrom-Json | Select-Object -ExpandProperty workItems | Select-Object -ExpandProperty id
	if ($arguments.debug) {
		Write-Host "workItemsInProgressIds: $workItemsInProgressIds" 
	}
	$workItemsUri = $baseUri + '_apis/wit/workItems?fields=System.Id,System.AssignedTo&ids=' + ($workItemsInProgressIds -join ",")
	if ($arguments.debug) {
		Write-Host "workItemsUri: $workItemsUri" 
	}
	$response = curl -k -u $auth -H $contentType $workItemsUri
	if ($arguments.debug) {
		Write-Host "response: $response" 
	}
	$filter = '*' + $arguments.user + '*'
	if ($arguments.debug) {
		Write-Host "filter: $filter" 
	}
	$myInProgressWorkItemsIds = $response | ConvertFrom-Json | Select-Object -ExpandProperty value | Select-Object -ExpandProperty fields | Where-Object -Property System.AssignedTo -like $filter | Select-Object -ExpandProperty System.Id
	if ($arguments.debug) {
		Write-Host "myInProgressWorkItemsIds: $myInProgressWorkItemsIds" 
	}
	$myInProgressWorkItemsIdsInCommit = '#' + ($myInProgressWorkItemsIds -join " #")
	if ($arguments.debug) {
		Write-Host "myInProgressWorkItemsIdsInCommit: $myInProgressWorkItemsIdsInCommit" 
	}
	return $myInProgressWorkItemsIdsInCommit
}

function Get-MyInProgressWorkItems() {
	# Parse the input arguments
	$arguments = ParseArguments $args
	if ($arguments.debug) {
		Set-PSDebug -Trace 1
	} else {
		Set-PSDebug -Trace 0
	}
	# Check if the arguments used require the help to be printed
	$help = CheckIfMustPrintHelp $arguments.printHelp
	if ($help -ne $true) {
		# Check, request and store mandatory parameters
		$validated = CheckRequestAndStoreMandatoryParameters $arguments
		if ($validated -eq $true) {
			# Get the ids of the work items in progress
			$result = GetInProgressWorkItemIds $arguments
			# Return the ids
			if ($arguments.doNotCopyToClipboard -ne $true) {
				[Windows.Forms.Clipboard]::SetText($result)
			}
			Write-Host $result
		}
	}
}