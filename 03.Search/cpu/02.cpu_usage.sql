DECLARE @offset int = 540;		-- localtime 用オフセット (JST)
DECLARE @range int = -12;		-- 直近 12 時間のデータを取得

SELECT 
	T1.measure_date_local,
	T1.server_name,
	T1.object_name,
	T1.instance_name,
	T1.counter_name,
	CAST((T1.cntr_value * 1.0 / T2.cntr_value) * 100 AS numeric(10, 2)) AS cpu_usage
FROM 
	performance_counters T1 WITH(NOLOCK)
	LEFT HASH JOIN
	performance_counters T2 WITH(NOLOCK)
	ON
	T2.measure_date_local = T1.measure_date_local
	AND
	T2.server_name = T1.server_name
	AND
	T2.object_name = T1.object_name
	AND
	T2.instance_name = T1.instance_name
	AND
	T2.counter_name = RTRIM(T1.counter_name) + ' Base'
WHERE
	T1.measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
	AND
	T1.object_name = 'Resource Pool Stats'
	AND
	T1.counter_name IN ('CPU Usage %', 'CPU effective %', 'CPU delayed %')
	AND
	T1.instance_name <> 'internal'
ORDER BY
	T1.instance_name ASC, 
	T1.measure_date_local ASC
