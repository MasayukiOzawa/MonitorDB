USE [MonitorDB]
GO

-- ****************************************
-- ** Wait Stats
-- ****************************************
DROP TABLE IF EXISTS wait_stats
GO

/*
SELECT 
	GETUTCDATE() AS measure_date_local, 
	GETUTCDATE() AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	* 
INTO wait_stats
FROM sys.dm_os_wait_stats 
WHERE 0 = 1
GO
*/

CREATE TABLE [dbo].[wait_stats](
	[measure_date_local] [datetime] NOT NULL,
	[measure_date_utc] [datetime] NOT NULL,
	[server_name] [nvarchar](128) NULL,
	[wait_type] [nvarchar](60) NOT NULL,
	[waiting_tasks_count] [bigint] NOT NULL,
	[wait_time_ms] [bigint] NOT NULL,
	[max_wait_time_ms] [bigint] NOT NULL,
	[signal_wait_time_ms] [bigint] NOT NULL
) 
GO

CREATE CLUSTERED INDEX [CIX_wait_stats] ON [dbo].[wait_stats]
(
	[measure_date_local] ASC,
	[measure_date_utc] ASC,
	[server_name] ASC,
	[wait_type] ASC
)WITH (DATA_COMPRESSION=PAGE)

CREATE NONCLUSTERED INDEX [NCIX_wait_type]
ON [dbo].[wait_stats] (
	[wait_type]
)
WITH (DATA_COMPRESSION=PAGE)


-- ****************************************
-- ** Performance Counters
-- ****************************************
DROP TABLE IF EXISTS performance_counters
GO
/*
SELECT
	GETUTCDATE() AS measure_date_local, 
	GETUTCDATE() AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	* 
INTO performance_counters
FROM sys.dm_os_performance_counters
WHERE 0 = 1
GO
*/

CREATE TABLE [dbo].[performance_counters](
	[measure_date_local] [datetime] NOT NULL,
	[measure_date_utc] [datetime] NOT NULL,
	[server_name] [nvarchar](128) NULL,
	[object_name] [nchar](128) NOT NULL,
	[counter_name] [nchar](128) NOT NULL,
	[instance_name] [nchar](128) NULL,
	[cntr_value] [bigint] NOT NULL,
	[cntr_type] [int] NOT NULL
) 
GO

CREATE CLUSTERED INDEX [CIX_performance_counters] ON [dbo].[performance_counters]
(
	[measure_date_local] ASC,
	[measure_date_utc] ASC,
	[object_name] ASC,
	[counter_name] ASC
)WITH (DATA_COMPRESSION=PAGE)

CREATE NONCLUSTERED INDEX [NCIX_counter_name] ON [dbo].[performance_counters]
(
	[counter_name] ASC
)
INCLUDE ([server_name],[instance_name],[cntr_value])
WITH (DATA_COMPRESSION=PAGE)
GO

-- ****************************************
-- ** Scheduler
-- ****************************************
DROP TABLE IF EXISTS scheduler
GO
/*
SELECT 
	GETUTCDATE() AS measure_date_local, 
	GETUTCDATE() AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	*
INTO scheduler 
FROM sys.dm_os_schedulers
WHERE 0 = 1
*/

CREATE TABLE [dbo].[scheduler](
	[measure_date_local] [datetime] NOT NULL,
	[measure_date_utc] [datetime] NOT NULL,
	[server_name] [nvarchar](128) NULL,
	[scheduler_address] [varbinary](8) NOT NULL,
	[parent_node_id] [int] NOT NULL,
	[scheduler_id] [int] NOT NULL,
	[cpu_id] [int] NOT NULL,
	[status] [nvarchar](60) NOT NULL,
	[is_online] [bit] NOT NULL,
	[is_idle] [bit] NOT NULL,
	[preemptive_switches_count] [int] NOT NULL,
	[context_switches_count] [int] NOT NULL,
	[idle_switches_count] [int] NOT NULL,
	[current_tasks_count] [int] NOT NULL,
	[runnable_tasks_count] [int] NOT NULL,
	[current_workers_count] [int] NOT NULL,
	[active_workers_count] [int] NOT NULL,
	[work_queue_count] [bigint] NOT NULL,
	[pending_disk_io_count] [int] NOT NULL,
	[load_factor] [int] NOT NULL,
	[yield_count] [int] NOT NULL,
	[last_timer_activity] [bigint] NOT NULL,
	[failed_to_create_worker] [bit] NOT NULL,
	[active_worker_address] [varbinary](8) NULL,
	[memory_object_address] [varbinary](8) NOT NULL,
	[task_memory_object_address] [varbinary](8) NOT NULL,
	[quantum_length_us] [bigint] NOT NULL,
	[total_cpu_usage_ms] [bigint] NOT NULL,
	[total_cpu_idle_capped_ms] [bigint] NULL,
	[total_scheduler_delay_ms] [bigint] NOT NULL
)
GO

CREATE CLUSTERED INDEX [CIX_scheduler] ON [dbo].[scheduler]
(
	[measure_date_local] ASC,
	[measure_date_utc] ASC,
	[server_name] ASC
)WITH (DATA_COMPRESSION=PAGE)

-- ****************************************
-- ** Sessio / Connection / Worker / Task
-- ****************************************
DROP TABLE IF EXISTS session_connection_worker
GO

/*
SELECT
	GETUTCDATE() AS measure_date_local, 
	GETUTCDATE() AS measure_date_utc, 
	@@SERVERNAME AS server_name, 
	(SELECT COUNT_BIG(*) FROM sys.dm_exec_sessions) AS total_sessions,
	(SELECT COUNT_BIG(*) FROM sys.dm_exec_connections) AS total_connections,
	(SELECT COUNT_BIG(*) FROM sys.dm_os_workers) AS total_workers,
	(SELECT COUNT(*) FROM sys.dm_os_tasks) AS total_tasks,
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
INTO session_connection_worker
WHERE 0 = 1
*/

CREATE TABLE [dbo].[session_connection_worker](
	[measure_date_local] [datetime] NOT NULL,
	[measure_date_utc] [datetime] NOT NULL,
	[server_name] [nvarchar](128) NULL,
	[total_sessions] [bigint] NULL,
	[total_connections] [bigint] NULL,
	[total_workers] [bigint] NULL,
	[total_tasks] [int] NULL,
	[max_parallel] [int] NULL
)
GO

CREATE CLUSTERED INDEX [CIX_session_connection_worker] ON [dbo].[session_connection_worker]
(
	[measure_date_local] ASC,
	[measure_date_utc] ASC
)WITH (DATA_COMPRESSION=PAGE)


-- ****************************************
-- ** File I/O
-- ****************************************
DROP TABLE IF EXISTS file_io
GO

/*
SELECT
	GETUTCDATE() AS measure_date_local, 
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
INTO file_io
FROM
	sys.dm_io_virtual_file_stats(NULL, NULL)
WHERE 0 = 1
*/

CREATE TABLE [dbo].[file_io](
	[measure_date_local] [datetime] NOT NULL,
	[measure_date_utc] [datetime] NOT NULL,
	[server_name] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[file_id] [smallint] NOT NULL,
	[num_of_reads] [bigint] NOT NULL,
	[num_of_bytes_read] [bigint] NOT NULL,
	[io_stall_read_ms] [bigint] NOT NULL,
	[io_stall_queued_read_ms] [bigint] NOT NULL,
	[num_of_writes] [bigint] NOT NULL,
	[num_of_bytes_written] [bigint] NOT NULL,
	[io_stall_write_ms] [bigint] NOT NULL,
	[io_stall_queued_write_ms] [bigint] NOT NULL,
	[io_stall] [bigint] NOT NULL,
	[size_on_disk_bytes] [bigint] NOT NULL
)
GO

CREATE CLUSTERED INDEX [CIX_file_io] ON [dbo].[file_io]
(
	[measure_date_local] ASC,
	[measure_date_utc] ASC
)WITH (DATA_COMPRESSION=PAGE)