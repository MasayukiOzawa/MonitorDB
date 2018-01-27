DECLARE @offset int = 540;　-- localtime 用オフセット

SELECT 
	measure_date_local,
	measure_date_utc,
	server_name,
	total_sessions,
	total_connections,
	total_workers,
	total_tasks,
	max_parallel
FROM 
	session_connection_worker WITH(NOLOCK)
WHERE
	measure_date_local >= DATEADD(mi, -30, (DATEADD(mi, @offset, GETUTCDATE())))
