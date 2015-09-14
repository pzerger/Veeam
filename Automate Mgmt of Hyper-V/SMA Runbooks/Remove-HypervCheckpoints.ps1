workflow Remove-HypervCheckpoints
{
	param(
		$VmmMgmtServer,
		$VMName
	)
	InlineScript
	{
        # load variables for use in the InlineScript block
        $VmmMgmtServer = $Using:VmmMgmtServer
        $VMName = $Using:VMName
        
        # Import the VMM and Hyper-V modules
    	Import-Module VirtualMachineManager
    	Import-Module Hyper-V
    
    	# Connect to VMM Server to get the Hyper-V server currently hosting the VM
    	Get-SCVMMServer -ComputerName $VmmMgmtServer
    	$HypervHost = (Get-SCVirtualMachine -Name $VMName).VMHost.Name
    
        <#
    	Connect to the Hyper-V server and delete all snapshots on the VM.
    	We are using the Hyper-V "Remove-VMSnapshot" cmdlet for this step rather 
        than the SCVMM "Remove-SCVMCheckpoint" cmdlet because the entire snapshot 
        tree can be deleted in one pass using the Hyper-V cmdlet and 
        the -IncludeAllChildSnapshots parameter.
        
        Get the VM properties, select the first (root) snapshot (which will be the oldest), 
        delete the snapshot and all child snapshots.  This has the practical effect of 
        deleting ALL snapshots on the VM.
    	#>
        Hyper-V\Get-VM -Name $VMName -ComputerName $HypervHost | Hyper-V\Get-VMSnapshot | Select-Object -First 1 | Hyper-V\Remove-VMSnapshot -IncludeAllChildSnapshots -Confirm:$false
	}
}