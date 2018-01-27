DECLARE @offset int = 540;		-- localtime 用オフセット
DECLARE @range int = -1;		-- 直近何時間のデータを取得

WITH file_io_info
AS
(
	SELECT
		RANK() OVER (PARTITION BY database_name, file_id ORDER BY measure_date_local ASC) AS No,
		*
	FROM
		file_io
)

SELECT
	T1.No,
	T1.measure_date_local, 
	T1.measure_date_utc, 
	COALESCE(DATEDIFF(ss, T2.measure_date_local, T1.measure_date_local), 0) AS time_diff_sec,
	T1.server_name, 
	T1.database_name,
	T1.file_id,
	T1.num_of_reads,
	COALESCE(T1.num_of_reads - T2.num_of_reads,0) AS measure_num_of_reads,
	T1.num_of_bytes_read,
	COALESCE(T1.num_of_bytes_read - T2.num_of_bytes_read,0) AS measure_num_of_bytes_read,
	T1.io_stall_read_ms,
	COALESCE(T1.io_stall_read_ms - T2.io_stall_read_ms,0) AS measure_io_stall_read_ms,
	T1.io_stall_queued_read_ms,
	COALESCE(T1.io_stall_queued_read_ms - T2.io_stall_queued_read_ms,0) AS measure_io_stall_queued_read_ms,
	T1.num_of_writes,
	COALESCE(T1.num_of_writes - T2.num_of_writes,0) AS measure_num_of_writes,
	T1.num_of_bytes_written,
	COALESCE(T1.num_of_bytes_written - T2.num_of_bytes_written,0) AS measure_num_of_bytes_written,
	T1.io_stall_write_ms,
	COALESCE(T1.io_stall_write_ms - T2.io_stall_write_ms,0) AS measure_io_stall_write_ms,
	T1.io_stall_queued_write_ms,
	COALESCE(T1.io_stall_queued_write_ms - T2.io_stall_queued_write_ms,0) AS measure_io_stall_queued_write_ms,
	T1.io_stall,
	COALESCE(T1.io_stall - T2.io_stall,0) AS measure_io_stall,
	T1.size_on_disk_bytes,
	COALESCE(T1.size_on_disk_bytes - T2.size_on_disk_bytes,0) AS measure_size_on_disk_bytes
FROM
	file_io_info T1 WITH(NOLOCK)
	LEFT JOIN
	file_io_info T2 WITH(NOLOCK)
	ON
		T2.No = T1.No - 1
		AND
		T2.server_name = T1.server_name
		AND
		T2.database_name = T1.database_name
		AND
		T2.file_id = T1.file_id
WHERE
	T1.measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
ORDER BY 
	T1.database_name ASC, 
	T1.file_id ASC,
	T1.measure_date_local ASC
