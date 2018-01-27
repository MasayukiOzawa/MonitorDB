DECLARE @offset int = 540　-- localtime 用オフセット

-- ****************************************
-- ** Wait Stats
-- ****************************************
INSERT INTO wait_stats 
SELECT 
	DATEADD(mi, @offset, GETUTCDATE()) AS measure_date_local, 
	GETUTCDATE() AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	* 
FROM 
	sys.dm_os_wait_stats
WHERE
	waiting_tasks_count > 0

-- ****************************************
-- ** Performance Counters
-- ****************************************
INSERT INTO performance_counters 
SELECT 
	DATEADD(mi, @offset, GETUTCDATE()) AS measure_date_local, 
	GETUTCDATE() AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	SUBSTRING(object_name, PATINDEX('%:%', object_name) + 1, LEN(object_name)) AS object_name, counter_name, instance_name, cntr_value,cntr_type 
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
INSERT INTO scheduler
SELECT 
	DATEADD(mi, @offset, GETUTCDATE()) AS measure_date_local, 
	GETUTCDATE() AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	* 
FROM 
	sys.dm_os_schedulers
WHERE
	is_online = 1
	AND
	scheduler_id < 1048576

-- ****************************************
-- ** Sessio / Connection / Worker
-- ****************************************
INSERT INTO session_connection_worker
SELECT
	DATEADD(mi, @offset, GETUTCDATE()) AS measure_date_local, 
	GETUTCDATE() AS measure_date_utc, 
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
INSERT INTO file_io
SELECT
	DATEADD(mi, @offset, GETUTCDATE()) AS measure_date_local, 
	GETUTCDATE() AS measure_date_utc, 
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
