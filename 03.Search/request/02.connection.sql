DECLARE @offset int = 540;		-- localtime 用オフセット (JST)
DECLARE @range int = -12;		-- 直近 12 時間のデータを取得

SELECT 
	measure_date_local,
	measure_date_utc,
	server_name,
	RTRIM(object_name) AS object_name,
	RTRIM(counter_name) AS counter_name,
	RTRIM(instance_name) AS instance_name,
	cntr_value
FROM 
	performance_counters WITH(NOLOCK)
WHERE
	measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
	AND
	counter_name = 'User Connections'