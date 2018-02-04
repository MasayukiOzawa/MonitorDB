DECLARE @offset int = 540;		-- localtime 用オフセット (JST)
DECLARE @range int = -12;		-- 直近 12 時間のデータを取得

SELECT
	T.*,
	T2.total_connections,
	T2.total_sessions,
	T2.total_tasks,
	T2.total_workers,
	T2.max_parallel
FROM(
	SELECT
		T1.measure_date_local,
		T1.measure_date_utc,
		T1.server_name,
		COUNT(*) AS core_count,
		SUM(current_tasks_count) AS total_current_tasks_count,
		SUM(runnable_tasks_count) AS total_runnable_tasks_count,
		SUM(current_workers_count) AS total_current_workers_count,
		SUM(active_workers_count) AS total_active_workers_count,
		SUM(work_queue_count) AS total_work_queue_count,
		SUM(pending_disk_io_count) AS total_pending_disk_io_count,
		SUM(total_cpu_usage_ms) AS total_cpu_usage_ms,
		SUM(total_scheduler_delay_ms) AS total_scheduler_delay_ms
	FROM
		scheduler AS T1 WITH(NOLOCK)
	WHERE
		T1.measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
	GROUP BY
		T1.measure_date_local,
		T1.measure_date_utc,
		T1.server_name
) AS T
LEFT JOIN
	session_connection_worker AS T2 WITH (NOLOCK)
	ON
	T2.measure_date_local = T.measure_date_local
	AND
	T2.server_name = T.server_name
ORDER BY
	T.server_name ASC,
	T.measure_date_local ASC