DECLARE @offset int = 540;		-- localtime 用オフセット
DECLARE @range int = -1;		-- 直近何時間のデータを取得

SELECT
	measure_date_local,
	measure_date_utc,
	server_name,
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
	scheduler WITH(NOLOCK)
WHERE
	measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
GROUP BY
	measure_date_local,
	measure_date_utc,
	server_name
ORDER BY
	measure_date_local ASC