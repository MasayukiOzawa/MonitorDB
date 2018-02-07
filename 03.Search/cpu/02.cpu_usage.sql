/*
Memo : 
現状のクエリは、S1 以上でないと実行時間に難あり。
*/

DECLARE @offset int = 540;		-- localtime 用オフセット (JST)
DECLARE @range int = -12;		-- 直近 12 時間のデータを取得

WITH performance_info
AS(
SELECT
	measure_date_local,
	server_name,
	RTRIM(object_name) AS object_name,
	RTRIM(instance_name) AS instance_name,
	RTRIM(counter_name) AS counter_name,
	cntr_value
FROM
	performance_counters
WHERE
	measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
	AND
	object_name = 'Resource Pool Stats'
	AND
	counter_name IN (
		'CPU Usage %', 'CPU effective %', 'CPU delayed %',
		'CPU Usage % base', 'CPU effective % base', 'CPU delayed % base'
	)
	AND
	instance_name <> 'internal'
)

SELECT 
	T1.measure_date_local,
	T1.server_name,
	T1.object_name,
	T1.instance_name,
	T1.counter_name,
	CAST((T1.cntr_value * 1.0 / T2.cntr_value) * 100 AS numeric(10, 2)) AS cpu_usage
FROM 
	performance_info T1 WITH(NOLOCK)
	LEFT JOIN
	performance_info T2 WITH(NOLOCK)
	ON
	T2.measure_date_local = T1.measure_date_local
	AND
	T2.server_name = T1.server_name
	AND
	T2.object_name = T1.object_name
	AND
	T2.counter_name IN ('CPU Usage % base', 'CPU effective % base', 'CPU delayed % base')
	AND
	T2.counter_name = RTRIM(T1.counter_name) + ' base'
	AND
	T2.instance_name = T1.instance_name
WHERE
	T1.counter_name IN ('CPU Usage %', 'CPU effective %', 'CPU delayed %')
