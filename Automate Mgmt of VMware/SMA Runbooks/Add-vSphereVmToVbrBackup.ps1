workflow Add-vSphereVmToVbrBackup
{
    param (
		$PSCredName,
		$VBRMgmtServer,
		$BackupJobName,
		$ViServer,
		$VM
	)
	
	# Retrieve the previously created SMA/AA Credential object "VbrMgmtServerCred" 
	# for use when invoking the InlineScript block on the remote VBR Mgmt Server
	$PSUserCred = Get-AutomationPSCredential -Name $PSCredName
	
	$Result = InlineScript
	{
		# load variables for use in the InlineScript block
		$BackupJobName = $Using:BackupJobName
		$ViServer = $Using:ViServer
		$VM = $Using:VM
		
		# Loads Veeam Powershell Snapin
		Add-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue

        # Get an existing backup job
		$BackupJob = Get-VBRJob | Where {$_.Name -eq $BackupJobName}

        # Get the VBR managed virtualization host
		$VbrManagedServer = Get-VBRServer | where {$_.Name -eq $ViServer}

        # Find the VM that needs to be added to the backup job on the VBR managed virtualization host
		$VbrVmToBackup = Find-VBRViEntity -Server $VbrManagedServer -VMsAndTemplates -Name $VM

        # Add the VM to the backup job
		Add-VBRViJobObject -Job $BackupJob -Entities $VbrVmToBackup

		#Check if VM was sucessfully added to the backup job
		$JobCheck = $VM -match (Get-VBRJob -Name $BackupJob | Get-VBRJobObject | where {$_.name -eq $VM}).Name

		IF ($JobCheck -eq $false) 
		{
			# Job did not succeed, return error code
			[int]$ReturnCode = 1
		} 
		ELSE  
		{
			#job succeeded, return success code
			[int]$ReturnCode = 0
		}

        # Create a custom property to store the ReturnCode value for return to the parent runbook		
		New-Object PSObject -Property @{
			ReturnCode = $ReturnCode
		}
			
	} -PSComputerName $VBRMgmtServer -psCredential $PSUserCred # Invoke the InlineScript block on the remote computer

    # Display the Return Code
	$Result.ReturnCode
	
}