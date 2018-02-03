DECLARE @offset int = 540
DECLARE @datetime datetime = (SELECT GETUTCDATE())

-- ****************************************
-- ** Wait Stats
-- ****************************************

SELECT 
	DATEADD(mi, @offset, @datetime) AS measure_date_local, 
	@datetime AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	wait_type,
	waiting_tasks_count,
	wait_time_ms,
	max_wait_time_ms,
	signal_wait_time_ms
FROM 
	sys.dm_os_wait_stats
WHERE
	waiting_tasks_count > 0

-- ****************************************
-- ** Performance Counters
-- ****************************************
SELECT 
	DATEADD(mi, @offset, @datetime) AS measure_date_local, 
	@datetime AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	SUBSTRING(object_name, PATINDEX('%:%', object_name) + 1, LEN(object_name)) AS object_name, 
	counter_name, instance_name, 
	cntr_value,cntr_type 
FROM 
	sys.dm_os_performance_counters
WHERE
	SUBSTRING(object_name, PATINDEX('%:%', object_name) + 1, LEN(object_name)) 
	IN (
		'Resource Pool Stats',
		'General Statistics', 
		'Buffer Manager', 
		'Access Methods',
		'Databases',
		'Locks',
		'Memory Manager',
		'Plan Cache',
		'SQL Statistics',
		'Transactions',
		'Wait Statistics',
		'Workload Group Stats'
	)

-- ****************************************
-- ** Scheduler
-- ****************************************
SELECT 
	DATEADD(mi, @offset, @datetime) AS measure_date_local, 
	@datetime AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	scheduler_address,
	parent_node_id,
	scheduler_id,
	cpu_id,
	status,
	is_online,
	is_idle,
	preemptive_switches_count,
	context_switches_count,
	idle_switches_count,
	current_tasks_count,
	runnable_tasks_count,
	current_workers_count,
	active_workers_count,
	work_queue_count,
	pending_disk_io_count,
	load_factor,
	yield_count,
	last_timer_activity,
	failed_to_create_worker,
	active_worker_address,
	memory_object_address,
	task_memory_object_address,
	quantum_length_us,
	total_cpu_usage_ms,
	total_cpu_idle_capped_ms,
	total_scheduler_delay_ms
FROM 
	sys.dm_os_schedulers
WHERE
	is_online = 1
	AND
	scheduler_id < 1048576

-- ****************************************
-- ** Sessio / Connection / Worker
-- ****************************************
SELECT
	DATEADD(mi, @offset, @datetime) AS measure_date_local, 
	@datetime AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	(SELECT COUNT_BIG(*) FROM sys.dm_exec_sessions) AS total_sessions,
	(SELECT COUNT_BIG(*) FROM sys.dm_exec_connections) AS total_connections,
	(SELECT COUNT_BIG(*) FROM sys.dm_os_workers) AS total_workers,
	(SELECT COUNT_BIG(*) FROM sys.dm_os_tasks) AS total_tasks,
	(SELECT MAX(task) AS max_parallel
		FROM
		(
			SELECT session_id, request_id, COUNT(*) AS task 
			FROM sys.dm_os_tasks
			WHERE
			session_id IS NOT NULL
			GROUP BY session_id, request_id
		) AS T
	 ) AS max_parallel

-- ****************************************
-- ** File I/O
-- ****************************************
SELECT
	DATEADD(mi, @offset, @datetime) AS measure_date_local, 
	@datetime AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	DB_NAME(database_id) AS database_name,
	file_id,
	num_of_reads,
	num_of_bytes_read,
	io_stall_read_ms,
	io_stall_queued_read_ms,
	num_of_writes,
	num_of_bytes_written,
	io_stall_write_ms,
	io_stall_queued_write_ms,
	io_stall,
	size_on_disk_bytes
FROM
	sys.dm_io_virtual_file_stats(NULL, NULL)
WHERE 
	DB_NAME(database_id) IS NOT NULL
	AND
	database_id NOT IN(1,3,4)
