SELECT
	CAST(measure_date_local AS date) AS collect_date,
	server_name,
	COUNT(*) AS connect_count
FROM
	session_connection_worker
GROUP BY
	CAST(measure_date_local AS date),
	server_name
ORDER BY
	server_name ASC,
	collect_date ASC