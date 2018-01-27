DECLARE @offset int = 540;		-- localtime 用オフセット
DECLARE @range int = -1;		-- 直近何時間のデータを取得

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
	measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
