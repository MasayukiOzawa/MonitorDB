# https://docs.microsoft.com/ja-jp/azure/log-analytics/log-analytics-data-collector-api

Param(
    $CustomerId = $ENV:WorkspaceID,　　　# Replace with your Workspace ID
    $SharedKey = $ENV:SharedKey,    # Replace with your Primary Key
    $ConnectionString = $ENV:SQLAZURECONNSTR_DestinationDB
)

# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}


# Create the function to create and post the request
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}

$ErrorAction = "Stop"

$Con = New-Object System.Data.SqlClient.SqlConnection
$con.ConnectionString = $ConnectionString
$con.Open()

$cmd = $con.CreateCommand()
$cmd.CommandType = [System.Data.CommandType]::Text
$cmd.CommandText = @"
/*
Interpreting the counter values from sys.dm_os_performance_counters
https://blogs.msdn.microsoft.com/psssql/2013/09/23/interpreting-the-counter-values-from-sys-dm_os_performance_counters/

2.2.4.2 _PERF_COUNTER_REG_INFO
https://msdn.microsoft.com/en-us/library/cc238313.aspx
*/
-- PERF_COUNTER_LARGE_RAWCOUNT / PERF_COUNTER_COUNTER / PERF_COUNTER_BULK_COUNT
SELECT
        @@SERVERNAME AS server_name,
	DB_NAME() AS db_name,
        RTRIM(SUBSTRING(object_name, PATINDEX('%:%', object_name) + 1, 256)) AS object_name,
        RTRIM(counter_name) AS counter_name,
        CASE
                WHEN RTRIM(instance_name) = '' THEN 'None'
                ELSE RTRIM(instance_name)
        END AS instance_name,
        cntr_value,
        NULL AS cntr_value_base,
        cntr_type
FROM
        sys.dm_os_performance_counters
WHERE
        cntr_type IN (65792, 272696320, 272696576)

-- PERF_LARGE_RAW_FRACTION
SELECT
        @@SERVERNAME AS server_name,
	DB_NAME() AS db_name,
        RTRIM(SUBSTRING(T1.object_name, PATINDEX('%:%', T1.object_name) + 1, 256)) AS object_name,
        RTRIM(T1.counter_name) AS counter_name,
        CASE
                WHEN RTRIM(T1.instance_name) = '' THEN 'None'
                ELSE RTRIM(T1.instance_name)
        END AS instance_name,
        CASE
                WHEN T1.cntr_value = 0 THEN 0
                ELSE (T1.cntr_value * 1.0 / T2.cntr_value * 1.0) * 100
        END AS cntr_value,
        NULL AS cntr_value_base,
        T1.cntr_type
FROM
        sys.dm_os_performance_counters as T1
        LEFT JOIN
        sys.dm_os_performance_counters as T2
        ON
                T2.object_name = T1.object_name
                AND
                T2.instance_name = T1.instance_name
                AND
                (
                REPLACE(LOWER(RTRIM(T2.counter_name)), 'base', 'ratio') = LOWER(RTRIM(T1.counter_name))
                OR
                LOWER(RTRIM(T2.counter_name)) = LOWER(RTRIM(T1.counter_name)) + ' base'
                )
                AND
                T2.cntr_type = 1073939712
WHERE
        T1.cntr_type IN (537003264)

-- PERF_AVERAGE_BULK
SELECT
        @@SERVERNAME AS server_name,
	DB_NAME() AS db_name,
        RTRIM(SUBSTRING(T1.object_name, PATINDEX('%:%', T1.object_name) + 1, 256)) AS object_name,
        RTRIM(T1.counter_name) AS counter_name,
        CASE
                WHEN RTRIM(T1.instance_name) = '' THEN 'None'
                ELSE RTRIM(T1.instance_name)
        END AS instance_name,
        T1.cntr_value,
        T2.cntr_value AS cntr_value_base,
        T1.cntr_type
FROM
        sys.dm_os_performance_counters as T1
        LEFT JOIN
        sys.dm_os_performance_counters as T2
        ON
                T2.object_name = T1.object_name
                AND
                T2.instance_name = T1.instance_name
                AND
                (
                REPLACE(LOWER(RTRIM(T2.counter_name)), 'base', '(ms)') = LOWER(RTRIM(T1.counter_name))
                OR
                REPLACE(LOWER(RTRIM(T2.counter_name)), ' base', '/Fetch') = LOWER(RTRIM(T1.counter_name))
                OR
                LOWER(RTRIM(T2.counter_name)) = LOWER(RTRIM(T1.counter_name)) + ' base'
                )
                AND
                T2.cntr_type = 1073939712
WHERE
        T1.cntr_type = 1073874176
        AND
        T2.cntr_value IS NOT NULL

"@

$adapter = New-Object System.Data.SqlClient.SqlDataAdapter -ArgumentList $cmd
$ds = New-Object System.Data.DataSet
$adapter.Fill($ds) | Out-Null


$Con.Close()
$con.Dispose()

<#
$ArrayList  = New-Object System.Collections.ArrayList

foreach ($row in $ds.Tables[0].Rows){
    $ArrayList.Add(
       [PSCustomObject]@{
        "Computer" = "$($row.server_name)"
        "db_name" =  "$($row.db_name)"
        "wait_type" = "$($row.wait_type)"
        "waiting_tasks_count" = $row.waiting_tasks_count
        "wait_time_ms" = $row.wait_time_ms
        "max_wait_time_ms" = $row.max_wait_time_ms
        "signal_wait_time_ms" = $row.signal_wait_time_ms
        }
    ) | Out-Null
}


$json = $ArrayList | ConvertTo-Json

$LogType = "SQLPerformance_Wait"
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType

#>

$ArrayList  = New-Object System.Collections.ArrayList

foreach ($row in $ds.Tables[0..2].Rows){
    $ArrayList.Add(
        [PSCustomObject]@{
        "Computer" = "$($row.server_name)"
        "db_name" =  "$($row.db_name)"
        "object_name" = "$($row.object_name)"
        "counter_name" = "$($row.counter_name)"
        "instance_name" = "$($row.instance_name)"
        "cntr_value" = $row.cntr_value
        "cntr_value_base" = $row.cntr_value_base
        "cntr_type" = $row.cntr_type

        }
    ) | Out-Null
}
$json = $ArrayList | ConvertTo-Json

$LogType = "SQLPerformance_Perf"
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType

$ds.Dispose()