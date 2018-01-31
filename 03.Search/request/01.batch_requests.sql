DECLARE @offset int = 540;		-- localtime 用オフセット (JST)
DECLARE @range int = -12;		-- 直近 12 時間のデータを取得

WITH performance_info
AS
(
	SELECT
		RANK() OVER (PARTITION BY object_name, counter_name, instance_name ORDER BY measure_date_local ASC) AS No,
		*
	FROM
		performance_counters
	WHERE
		measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
)
SELECT 
	T1.measure_date_local,
	T1.measure_date_utc,
	COALESCE(DATEDIFF(ss, T2.measure_date_local, T1.measure_date_local), 0) AS time_diff_sec,
	T1.server_name,
	T1.object_name,
	T1.counter_name,
	T1.cntr_value,
	COALESCE(T1.cntr_value - T2.cntr_value,0) AS measure_cntr_value,
	CASE COALESCE(T1.cntr_value - T2.cntr_value,0)
	WHEN 0 THEN 0
	ELSE 
		COALESCE(T1.cntr_value - T2.cntr_value,0) / COALESCE(DATEDIFF(ss, T2.measure_date_local, T1.measure_date_local), 0)
	END
	AS measure_batch_request_sec
FROM 
	performance_info T1 WITH(NOLOCK)
	LEFT HASH JOIN
		performance_info T2 WITH(NOLOCK)
	ON
		T2.No = T1.No - 1
		AND
		T2.server_name = T1.server_name
		AND
		T2.counter_name = T1.counter_name
		AND
		T2.object_name = T1.object_name
		AND
		T2.instance_name = T1.instance_name
WHERE
	T1.counter_name = 'Batch Requests/sec'
ORDER BY 
	T1.measure_date_local ASC
