workflow Remove-vSphereSnapshots
{
	param(
		$vSphereMgmtAcct_avName,
        $vSphereMgmtAcctPwd_avName,
        $ViServer,
		$VMName
		)
	InlineScript
	{
		# load variables for use in the InlineScript block
        $ViServer = $Using:ViServer
        $VMName = $Using:VMName
        
        #Add the PowerCli Snapin
		Add-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue
		Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

        <#
        Get the previously created Automation Variables for the vSphere Mgmt account and password
        "vSphereMgmtAcct" is an automation variable that contains the vSphere mgmt user account
        "vSphereMgmtAcctPwd" is an encrypted automation variable that contains the password for the 
        vSphereMgmtAcct account
        #>
        $vSphereMgmtAcct = Get-AutomationVariable -Name $vSphereMgmtAcct_avName
        $vSphereMgmtAcctPwd = Get-AutomationVariable -Name $vSphereMgmtAcctPwd_avName

		#Connect to VI Server (vCnenter Server or ESXi Host)
		Connect-VIServer -Server $ViServer -User $vSphereMgmtAcct -Password $vSphereMgmtAcctPwd | Out-Null

        # Get the VM properties, select the first (root) snapshot (which will be the oldest), delete the snapshot and all children snapshots
        # This has the practical effect of deleting ALL snapshots on the VM
		VMware.VimAutomation.Core\Get-VM -Name $VMName | VMware.VimAutomation.Core\Get-Snapshot | Select-Object -First 1 | VMware.VimAutomation.Core\Remove-Snapshot -RemoveChildren -Confirm:$false

        # disconnect the VI Server session
		Disconnect-VIServer -Confirm:$False
	}
}