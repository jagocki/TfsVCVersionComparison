param($csvOuput="folderDiff.csv", $leftFolder="C:\Users\USER\Source\Workspaces\DemoScrum\ConsoleApplication1", $rightFolder="C:\Users\USER\Source\Workspaces\DemoScrum\ConsoleApplication1-v2")

#global setting
$tf = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe"


function GetTfsVCHisotryRecord 
{
    param (
        $fileFullName
    )
    write-host $file.Name
    $command = """$tf"" vc hist ""$($fileFullName)"" /noprompt /stopafter:1 /format:detailed"
    $resultArr = @()
    $result = cmd /c $command
    $resultArr += $result
    return $resultArr
}

function GetRelativeFullName 
{
    param ($file, $rootFolderPath)
    return $file.FullName.Replace($rootFolderPath,"")
}

function CreateRecord 
{
    param ($file, $historyResult, $isLeft, $rootFolderPath)
    $record = $null;
    $result = @()
    $result += $historyResult
    if ($result[0].Contains("----") -eq $true)
    {
        $record = @{
            FullName = $file.FullName
            FileName = $file.Name
            RelativeFullName = GetRelativeFullName $file $rootFolderPath
            ParentFolder = $file.DirectoryName
            LeftChangeSetNumber = if ($isLeft -eq $true) {[int]$result[1].Split(" ")[1]} else { 0}
            RightChangeSetNumber =  if ($isLeft -eq $false) { 0 } else { [int]$result[1].Split(" ")[1] }
        }
        $record = New-Object PSObject -Property $record
    }
    else
    {
        write-host "For ""$($file.FullName)"" there was following error:"
        write-host $result
    }
    return $record
}

$leftFiles = Get-ChildItem -Path $leftFolder -Recurse -File
$rightFiles = Get-ChildItem -Path $rightFolder -Recurse -File

$records = @()
foreach($file in $leftFiles)
{
    $historyResult = GetTfsVCHisotryRecord $file.FullName
    $temp = CreateRecord $file $historyResult $true $leftFolder
    if($temp -ne $null)
    {
        $records += $temp
    }
}


foreach($file in $rightFiles)
{
    $historyResult = GetTfsVCHisotryRecord $file.FullName
    if($historyResult -ne $null)
    {
        $relativeName = GetRelativeFullName $file $rightFolder
        $searchResult = $records | where-object {$_.RelativeFullName -eq $relativeName}
        if ($searchResult -eq $null)
        {
            $temp = CreateRecord $file $historyResult $false $rightFolder
            if($temp -ne $null)
            {
                $records += $temp
            }
        }
        else
        {
            $searchResult.RightChangeSetNumber = [int]$historyResult[1].Split(" ")[1]
        }
    }

}
$records | export-csv -Path $csvOuput -NoTypeInformation -Delimiter ";"