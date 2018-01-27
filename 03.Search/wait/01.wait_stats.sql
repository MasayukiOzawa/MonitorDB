DECLARE @offset int = 540;		-- localtime 用オフセット
DECLARE @range int = -1;		-- 直近何時間のデータを取得

WITH wait_info
AS
(
	SELECT
		RANK() OVER (PARTITION BY wait_type ORDER BY measure_date_local ASC) AS No,
		*
	FROM
		wait_stats
	WHERE
		measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
)
SELECT 
	T1.No,
	T1.measure_date_local,
	T1.measure_date_utc,
	COALESCE(DATEDIFF(ss, T2.measure_date_local, T1.measure_date_local), 0) AS time_diff_sec,
	T1.server_name,
	T1.wait_type,
	T1.waiting_tasks_count,
	COALESCE(T1.waiting_tasks_count - T2.waiting_tasks_count,0) As measure_waiting_tasks_count,
	T1.wait_time_ms,
	COALESCE(T1.wait_time_ms - T2.wait_time_ms, 0) AS measure_wait_time_ms,
	T1.max_wait_time_ms,
	T1.signal_wait_time_ms,
	COALESCE(T1.signal_wait_time_ms - T2.signal_wait_time_ms, 0) AS measure_signal_wait_time_ms
FROM 
	wait_info T1  WITH(NOLOCK)
	LEFT JOIN 
	wait_info T2  WITH(NOLOCK)
	ON
	T2.No = T1.No - 1
	AND
	T2.server_name = T1.server_name
	AND
	T2.wait_type = T1.wait_type
WHERE
	T1.waiting_tasks_count >= 0
	AND
	T1.wait_type IN ('CXPACKET', 'SOS_SCHEDULER_YIELD', 'RESOURCE_GOVERNOR_IDLE') 
ORDER BY 
	T1.wait_type ASC, 
	T1.measure_date_local ASC