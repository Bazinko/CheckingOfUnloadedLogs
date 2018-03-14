Add-Type -Path “C:\Oracle\odp.net\managed\common\Oracle.ManagedDataAccess.dll"

$con = New-Object Oracle.ManagedDataAccess.Client.OracleConnection("User Id=system;Password=oracle;Data Source=localhost/orcl122")
$a=get-content C:\Temp\dwh_oadm_in_imp.log
$DBUsers=@("BAZIN", "HR")    #Константа для юзеров
$Arr=@()
$DBArr=@()
$LOGArr=@()

$cmd=$con.CreateCommand()
$con.open()

for ($i=0; $i -lt $DBUsers.Count; $i++) {

    $cmd.CommandText = "select owner,table_name from dba_tables where OWNER='$($DBUsers[$i])' and PARTITIONED='NO'"
    $rdr=$cmd.ExecuteReader()

    while ($rdr.Read()) {
        $DBArr += '"' + $rdr.GetString(0) + '"' + "." + '"' + $rdr.GetString(1) + '"'
    }

    $cmd.CommandText = "select table_owner, table_name, partition_name from dba_tab_partitions where " + 
                            "table_OWNER='$($DBUsers[$i])'"
    $rdr=$cmd.ExecuteReader()

    while ($rdr.Read()) {
        $DBArr += '"' + $rdr.GetString(0) + '"' + "." + '"' + $rdr.GetString(1) + '"' + ":" + '"' + $rdr.GetString(2) + '"'
    }

}

$con.Close()

foreach ($lines in $a) {
    $lines=$lines.split(" ")
    if ($lines[2] -eq "exported") {
        $LOGArr += $lines[3]
    }
    $lines=""
}

$Arr=Compare-Object -ReferenceObject $LOGArr -DifferenceObject $DBArr | `
    ?{$_.sideIndicator -eq "=>"} | select-object -ExpandProperty inputobject

foreach ($lines in $Arr) {
    $lines=$lines.split(".").split(":")
    if ([string]::IsNullOrEmpty($lines[2])) {
        write-host "TABLE_OWNER:"$lines[0]"TABLE_NAME:"$lines[1]
    } else {
        write-host "TABLE_OWNER:"$lines[0]"TABLE_NAME:"$lines[1]"PARTITION_NAME:"$lines[2]
    }
}


