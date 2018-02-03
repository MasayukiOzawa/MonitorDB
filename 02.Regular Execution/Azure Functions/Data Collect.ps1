[CmdletBinding()] 
Param(
    [String]$SourceDB = $ENV:SQLAZURECONNSTR_SourceDB,
    [String]$TargetDB = $ENV:SQLAZURECONNSTR_DestinationDB
)

# SQL の取得 (BOM 無し UTF-8)
$sql = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MasayukiOzawa/MonitorDB/master/02.Regular%20Execution/01.Regular%20execution%20Select%20Only.sql" -UseBasicParsing).Content

# モニタリング対象から情報を取得
$SourceConnection = New-Object System.Data.SqlClient.SqlConnection
$SourceConnection.ConnectionString = $SourceDB
$SourceConnection.Open()

$cmd = $SourceConnection.CreateCommand()
$cmd.CommandType = [System.Data.CommandType]::Text
$cmd.CommandText = $sql

$Adapter = New-Object System.Data.SqlClient.SqlDataAdapter -ArgumentList $cmd

$DataSet = New-Object System.Data.DataSet
$Adapter.Fill($DataSet)

$SourceConnection.Close()
$SourceConnection.Dispose()


# モニタリング情報格納報 DB への情報登録
$TargetConnection = New-Object System.Data.SqlClient.SqlConnection
$TargetConnection.ConnectionString = $TargetDB
$TargetConnection.Open()

$sqlbulk = New-Object System.Data.SqlClient.SqlBulkCopy -ArgumentList $TargetConnection

$sqlbulk.DestinationTableName = "wait_stats"
$sqlbulk.WriteToServer($DataSet.Tables[0])

$sqlbulk.DestinationTableName = "performance_counters"
$sqlbulk.WriteToServer($DataSet.Tables[1])

$sqlbulk.DestinationTableName = "scheduler"
$sqlbulk.WriteToServer($DataSet.Tables[2])

$sqlbulk.DestinationTableName = "session_connection_worker"
$sqlbulk.WriteToServer($DataSet.Tables[3])

$sqlbulk.DestinationTableName = "file_io"
$sqlbulk.WriteToServer($DataSet.Tables[4])

$TargetConnection.Dispose()
$TargetConnection.Close()