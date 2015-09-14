workflow ScaleUp-HypervVM
{
	param(
		$VmmMgmtServer,
		$VMName,
		[int]$RamToAddMB,
		[int]$vCpuToAdd
	)

	InlineScript
	{
		# load variables for use in the InlineScript block
		$VmmMgmtServer = $Using:VmmMgmtServer
		$VMName = $Using:VMName
		$RamToAddMB = $Using:RamToAddMB
		$vCpuToAdd = $Using:vCpuToAdd
        
        # Import the VMM module
		Import-Module VirtualMachineManager

		# Connect to the VMM Server
		Get-SCVMMServer -ComputerName $VmmMgmtServer

		# Get the properties of the VM to be scaled up
		$VM = Get-SCVirtualMachine -Name $VMName

		# If the VM is running, shut it down
		IF ($VM.Status -ne "PowerOff")
		{
			Stop-SCVirtualMachine -VM $VM
		}

		# Calculate the new RAM and CPU counts
		# this script assumes the Hyper-V VM is configured with Dynamic Memory
		[int]$NewRAMCount = $VM.DynamicMemoryMaximumMB + $RamToAddMB
		[int]$NewCpuCount = $VM.CPUCount + $vCpuToAdd

		# Update the VM configuration with the new settings
		Set-SCVirtualMachine -VM $VM -DynamicMemoryMaximumMB $NewRAMCount -CPUCount $NewCpuCount

		# Start the VM
		Start-SCVirtualMachine -VM $VM
	}
}