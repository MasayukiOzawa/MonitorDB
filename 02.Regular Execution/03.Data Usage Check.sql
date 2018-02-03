SELECT
	OBJECT_NAME(p.object_id) as objbect_name,
	i.name AS index_name,
	SUM(p.row_count) AS row_count,
	SUM(p.reserved_page_count) * 8 AS reserved_page_size_KB,
	SUM(p.used_page_count) * 8 AS used_page_size_KB,
	CASE SUM(p.used_page_count)
	WHEN 0 THEN 0
		ELSE CAST((SUM(p.used_page_count) * 8.0) / SUM(p.row_count) * 1024 AS int)
	END AS avg_row_size_bytes
FROM 
	sys.dm_db_partition_stats AS p
	LEFT JOIN
	sys.indexes AS i
	ON
	i.object_id = p.object_id
	AND
	i.index_id = p.index_id
WHERE p.object_id IN(
	OBJECT_ID('wait_stats'), 
	OBJECT_ID('file_io'), 
	OBJECT_ID('performance_counters'), 
	OBJECT_ID('scheduler'),
	OBJECT_ID('session_connection_worker')
)
GROUP BY
	p.object_id,
	i.index_id,
	i.name
ORDER BY
	p.object_id ASC,
	i.index_id ASC

/*
EXEC sp_spaceused 'wait_stats'
EXEC sp_spaceused 'file_io'
EXEC sp_spaceused 'performance_counters'
EXEC sp_spaceused 'scheduler'
EXEC sp_spaceused 'session_connection_worker'
*/