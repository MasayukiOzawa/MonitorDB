DECLARE @offset int = 540;		-- localtime 用オフセット (JST)
DECLARE @range int = -12;		-- 直近 12 時間のデータを取得

SELECT 
	measure_date_local,
	measure_date_utc,
	server_name,
	object_name,
	counter_name,
	instance_name,
	cntr_value
FROM 
	performance_counters WITH(NOLOCK)
WHERE
	measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
	AND
	counter_name = 'User Connections'