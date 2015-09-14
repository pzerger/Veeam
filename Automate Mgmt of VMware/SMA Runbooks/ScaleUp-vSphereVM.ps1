workflow ScaleUp-vSphereVM
{
	param(
		$vSphereMgmtAcct_avName,
        $vSphereMgmtAcctPwd_avName,
        $ViServer,
		$VMName,
		[int]$RamToAddGB,
		[int]$vCpuToAdd
	)
	InlineScript
	{
		# load variables for use in the InlineScript block
        $ViServer = $Using:ViServer
        $VMName = $Using:VMName
        $RamToAddGB = $Using:RamToAddGB
        $vCpuToAdd = $Using:vCpuToAdd
        
        #Add the PowerCli Snapin
		Add-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue
		Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
        
        <#
        Get the previously created Automation variables for the vSphere Mgmt account and password
        "vSphereMgmtAcct" is an automation variable that contains the vSphere mgmt user account
        "vSphereMgmtAcctPwd" is an encrypted automation variable that contains the password for the 
        vSphereMgmtAcct account
        #>
        $vSphereMgmtAcct = Get-AutomationVariable -Name $vSphereMgmtAcct_avName
        $vSphereMgmtAcctPwd = Get-AutomationVariable -Name $vSphereMgmtAcctPwd_avName

		#Connect to VI Server (vCnenter Server or ESXi Host)
		Connect-VIServer -Server $ViServer -User $vSphereMgmtAcct -Password $vSphereMgmtAcctPwd | Out-Null

        # Get the properties of the VM to be scaled up
		$VM = VMware.VimAutomation.Core\Get-VM -Name $VMName

        # If the VM is running, shut it down
		IF ($VM.PowerState -ne "PoweredOff")
		{
			VMware.VimAutomation.Core\Shutdown-VMGuest -VM $VM -Confirm:$false

            # PowerCLI cmdlets run asynchronously, so loop until the VM is shut down.  No changes
            # can be made to the VM settings until the VM is powered off.
			Do 
			{
				Start-Sleep -Seconds 30
				$VmPowerState = (VMware.VimAutomation.Core\Get-VM -Name $VMName).PowerState
			} While ($VmPowerState -ne "PoweredOff")
		}

        # Calculate the new RAM and CPU counts
		[int]$NewRAMCount = $VM.MemoryGB + $RamToAddGB
		[int]$NewCpuCount = $VM.NumCpu + $vCpuToAdd

        # Update the VM configuration with the new settings
		VMware.VimAutomation.Core\Set-VM -VM $VM -MemoryGB $NewRAMCount -NumCPU $NewCpuCount -Confirm:$false

        # Start the VM
		VMware.VimAutomation.Core\Start-VM -VM $VM -Confirm:$false

        # PowerCLI cmdlets run asynchronously, so loop until the VM is running.
		Do 
		{
			Start-Sleep -Seconds 30
			$VmPowerState = (VMware.VimAutomation.Core\Get-VM -Name $VMName).PowerState
		} While ($VmPowerState -ne "PoweredOn")

        # disconnect the VI Server session
		Disconnect-VIServer -Confirm:$False
	}
}