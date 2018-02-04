DECLARE @offset int = 540;		-- localtime 用オフセット (JST)
DECLARE @range int = -6;		-- 直近 6 時間のデータを取得

WITH wait_info_time
AS
(
	
	SELECT
		ROW_NUMBER() OVER (PARTITION BY wait_type ORDER BY measure_date_local ASC) AS No,
		measure_date_local,
		server_name,
		RTRIM(wait_type) AS wait_type,
		SUM(wait_time_ms) AS total_wait_time_ms
	FROM(
		SELECT
			measure_date_local,
			server_name,
			CASE 
				WHEN wait_type LIKE 'LCK%'			THEN 'LOCKS' 
				WHEN wait_type LIKE 'PAGEIO%'		THEN 'PAGE I/O LATCH' 
				WHEN wait_type LIKE 'PAGELATCH%'	THEN 'PAGE LATCH (non-I/O)' 
				WHEN wait_type LIKE 'LATCH%'		THEN 'LATCH (non-buffer)' 
				ELSE wait_type
			END AS wait_type,
			SUM(wait_time_ms) AS wait_time_ms
		FROM
			wait_stats
		WHERE
			measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
			AND
			(
				wait_type LIKE 'LCK%'
				OR
				wait_type LIKE 'PAGEIO%'
				OR
				wait_type LIKE 'PAGELATCH%'
				OR
				wait_type LIKE 'LATCH%'
				OR
				wait_type IN ('CXPACKET', 'CXCONSUMER', 'SOS_SCHEDULER_YIELD', 'RESOURCE_GOVERNOR_IDLE', 'IO_QUEUE_LIMIT', 'LOG_RATE_GOVERNOR', 'THREADPOOL', 'WRITELOG', 'ASYNC_NETWORK_IO') 
			) 
		GROUP BY
			measure_date_local,
			server_name,
			wait_type
	) AS T
	GROUP BY
		measure_date_local,
		server_name,
		wait_type
)

SELECT
	*
FROM(
	SELECT 
		T1.measure_date_local,
		T1.server_name,
		T1.wait_type,
		COALESCE(T1.total_wait_time_ms - T2.total_wait_time_ms, 0) AS measure_total_wait_time_ms
	FROM 
		wait_info_time AS T1 WITH (NOLOCK)
		LEFT JOIN
			wait_info_time AS T2 WITH (NOLOCK)
		ON
			T2.No = T1.No - 1
			AND
			T2.server_name = T1.server_name
			AND
			T2.wait_type = T1.wait_type
) AS T
PIVOT(
	SUM(measure_total_wait_time_ms)
	FOR wait_type IN([CXPACKET], [CXCONSUMER], [SOS_SCHEDULER_YIELD], [RESOURCE_GOVERNOR_IDLE], [IO_QUEUE_LIMIT],[LOG_RATE_GOVERNOR], [THREADPOOL], 
	[PAGE I/O LATCH], [WRITELOG], [PAGE LATCH (non-I/O)], [LATCH (non-buffer)], [LOCKS], [ASYNC_NETWORK_IO])
) AS PVT

