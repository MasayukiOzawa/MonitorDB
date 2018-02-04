DECLARE @offset int = 540;		-- localtime 用オフセット (JST)
DECLARE @range int = -12;		-- 直近 12 時間のデータを取得

WITH scheduler_info
AS(
	SELECT
		RANK() OVER (PARTITION BY server_name ORDER BY measure_date_local ASC) AS No,
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
		scheduler
	WHERE
		measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))	
	GROUP BY
		measure_date_local,
		measure_date_utc,
		server_name	
)
SELECT
	T1.*,
	COALESCE(T1.total_cpu_usage_ms - T2.total_cpu_usage_ms, 0) AS measure_total_cpu_usage_ms,
	COALESCE(T1.total_scheduler_delay_ms - T2.total_scheduler_delay_ms, 0) AS measure_total_scheduler_delay_ms
FROM
	scheduler_info AS T1 WITH(NOLOCK) 
	LEFT HASH JOIN
		scheduler_info AS T2 WITH(NOLOCK) 
	ON
		T2.server_name = T1.server_name
		AND
		T2.No = T1.No - 1
ORDER BY
	T1.server_name ASC,
	T1.measure_date_local ASC