# PowerShell Script to move VM's with a pattern 'Red Hat' to an affinity rule called 'Red Hat Vms'
#
# Ultan Lankford
# Version 1.0 - First iteration with hardcoded location
# Verison 2.0 - Added prompt to set location manually via shell
# Version 2.1 - Added more robust checks and made it Site independant


# Variables hardcoded
$DrsVMGroup = 'Red Hat Vms'

# Check if we are connected to a Vcenter server, if not prompt to connect
$VC = $global:defaultviserver  | Select-String -Pattern tafe
if ($VC)
  {
    Write-Host "We are currently connected to" -NoNewLine $VC
  }
  ELSE
  {
    $VCenter = Read-Host -prompt "Please enter the vCenter Host you want to connect to: "
    $Username = Read-Host -prompt "Please enter your vSphere username: "
    $Password = Read-Host -prompt "Please enter your vsphere password: "
    Connect-VIServer $VCenter -User $Username -Password $Password
    Write-Host "Now connected to" $global:defaultviserver
    $VC = $global:defaultviserver  | Select-String -Pattern tafe
  }

# Get vCenter server we are connected to for site location
$VCLocation = $VC.ToString().SubString(0,2)

# Case to ask for the correct DataCenter
if ($VCLocation -eq 'zs')
  {
    $DataCenter = Read-Host -Prompt "`n`nPlease enter the DataCenter: DC1 (Prod) or DC1NP (Non-Prod)"
  }
  Elseif ($VCLocation -eq 'zu')
  {
    $DataCenter = Read-Host -Prompt "`n`nPlease enter the DataCenter: DC2 (Prod) or DC2NP (Non-Prod)"
  }

# Get all the RedHat VM's from the datacenter
$vms = Get-VM -location $DataCenter |Get-VMGuest | Select-String -pattern 'Red hat' | %{ $_.ToString().Split(':')[0]; }

# For loop to move the VM's to the appropriate VMGroup to set the affinity rule up correctly
foreach($vm in $vms)
{
    Get-DrsVMGroup -Name $DrsVMGroup -Cluster $DataCenter | Set-DrsVMGroup -AddVM $vm
    Write-Host "Moving VM $vm to affinity rule $DrsVMGroup on cluster $VC in Datacenter" $VCLocation.ToUpper()
}
