#!powershell
# This file is part of Ansible.
#
# (c) 2015, Mick McGrellis <mpmcgrellis@gmail.com>
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON



# Functions
#
#

# Determine if destination is existing repo
# We do this based on the result of a call to "svn info"
function IsSvnRepo
{
    Invoke-Expression "$executable info $options $dest"
    return ($LastExitCode -eq 0)
}

# Create a new working directory at destination.
# Destination should not already exist
function Checkout($options, $revision, $repo, $dest, $force)
{
    $options += if($force){" --force"} else {""}
    $cmdout = Invoke-Expression "$executable checkout $options -r $revision $repo $dest 2>&1"
    if($LastExitCode -ne 0)
    {
        Fail-Json $result ("checkout failed: " + $cmdout)
    }
}

# Export (rather than checkout) repo to destination
function Export($options, $revision, $repo, $dest, $force)
{
    $options += if($force){" --force"} else {""}
    $cmdout = Invoke-Expression "$executable export $options -r $revision $repo $dest 2>&1"
    if($LastExitCode -ne 0)
    {
        Fail-Json $result ("export failed: " + $cmdout)
    }
}

# Use "svn switch" to change repo of working (destination) directory
function SwitchRepo($options, $revision, $repo, $dest)
{
    $cmdout = Invoke-Expression "$executable switch $options -r $revision $repo $dest 2>&1"
    if($LastExitCode -ne 0)
    {
        Fail-Json $result ("switch failed: " + $cmdout)
    }
}

# Update working (destination) directory with specified revision
function Update
{
    $cmdout = Invoke-Expression "$executable update $options -r $revision $dest 2>&1"
    if($LastExitCode -ne 0)
    {
        Fail-Json $result ("update failed: " + $cmdout)
    }
}

# Revert any changes in working (destination) directory
function Revert
{
    $cmdout = Invoke-Expression "$executable revert -R $dest 2>&1"
    if($LastExitCode -ne 0)
    {
        Fail-Json $result ("revert failed: " + $cmdout)
    }
}

# Get the URL and revision of the working (destination) directory
function GetRevision
{
    $cmdout = Invoke-Expression "$executable info $dest 2>&1"

    $info = New-Object psobject @{
        url = $cmdout -match "^URL:.*$" -replace "^URL: ", ""
        revision = $cmdout -match "^Revision:.*$" -replace "^Revision: ", ""
    }

    return $info
}

# Determine if working (destination) directory contains added, modified, or deleted files
# Unrevisioned files are ignored
function HasLocalMods
{
    $cmdout = Invoke-Expression "$executable status --quiet --ignore-externals $dest"
    
    # The --quiet option will return on modified files.
    # We consider that local modifications have occurred if we find modifiled files (M lines)
    return ($cmdout -and ($cmdout.count -gt 0))
}

# Determine if working (destination) directory is older than HEAD
function NeedsUpdate
{
    $destInfo = GetRevision

    $cmdout = Invoke-Expression "$executable info -r HEAD $dest"
    $repoInfo = New-Object psobject @{
        url = $cmdout -match "^URL:.*$" -replace "^URL: ", ""
        revision = $cmdout -match "^URL:.*$" -replace "^URL: ", ""
    }

    return ($destInfo.revision -lt $repoInfo.revision)
}



# Initialize result object and parse args provided by Ansible
#
#
$result = New-Object psobject @{
	failed = $false
    changed = $false
}

$params = Parse-Args $args

#repo aliases = name, repository
$repo = Get-AnsibleParam -obj $params -name "repo" -default $false
if( $repo -eq $false )
{
    $repo = Get-AnsibleParam -obj $params -name "repository" -default $false
    if( $repo -eq $false )
    {
        $repo = Get-AnsibleParam -obj $params -name "name" -default $false
        if( $repo -eq $false )
        {
            Fail-Json $result "missing required argument: repo"
        }
    }

}

#revision aliases = version
$revision = Get-AnsibleParam -obj $params -name "revision" -default $false
if( $revision -eq $false )
{
    $revision = Get-AnsibleParam -obj $params -name "version" -default $false
    if( $revision -eq $false )
    {
        $revision = Get-AnsibleParam -obj $params -name "revision" -default "HEAD"
    }
}

$dest = Get-AnsibleParam -obj $params -name "dest" -default $null -resultobj $result -failifempty $true
$username = Get-AnsibleParam -obj $params -name "username" -default $null
$password = Get-AnsibleParam -obj $params -name "password" -default $null
$executable = Get-AnsibleParam -obj $params -name "executable" -default "svn"
$export = Get-AnsibleParam -obj $params -name "export" -default "no" -resultobj $result -failifempty $false -ValidateSet $true,$false
$force = Get-AnsibleParam -obj $params -name "force" -default "no" -resultobj $result -failifempty $false -ValidateSet $true,$false
$switch = Get-AnsibleParam -obj $params -name "switch" -default "yes" -resultobj $result -failifempty $false -ValidateSet $true,$false



# Main
#
#
$options = "--non-interactive --trust-server-cert --no-auth-cache"
if( $username )
{
    $options += (" --username " + $username)
}

if( $password )
{
    # Passwords with special characters or sequences (like $$) get munged unless we quote
    $options += (" --password " + "'" + $password + "'")
}

if($export)
{
    Export $options $revision $repo $dest $force
    Set-Attr $result "changed" $true
}
elseif(Test-Path $dest)
{
    if(IsSvnRepo)
    {
        $beforeInfo = GetRevision
        $hasLocalMods = HasLocalMods

        if($switch)
        {
            SwitchRepo $options $revision $repo $dest
        }
        
        if($hasLocalMods)
        {
            if($force)
            {
                Revert
            }
            else
            {
                Fail-Json $result "ERROR: modified files exist in the destination"
            }
        }
        
        Update
        $afterInfo = GetRevision
        $changed = [bool]($beforeInfo.revision -ne $afterInfo.revision)
        Set-Attr $result "changed" $changed
        Set-Attr $result "before" $beforeInfo
        Set-Attr $result "after" $afterInfo
    }
    else
    {
        # TODO: Current subversion module does not support forcing checkout
        Fail-Json $result ("ERROR: " + $dest + " already exists and is not a subversion repository.")
    }

}
else
{
    $beforeInfo = GetRevision
    Checkout $options $revision $repo $dest $force
    $afterInfo = GetRevision
    $changed = [bool]($beforeInfo.revision -ne $afterInfo.revision)
    Set-Attr $result "changed" $changed
    Set-Attr $result "before" $beforeInfo
    Set-Attr $result "after" $afterInfo
}

# We're done
Exit-Json $result
