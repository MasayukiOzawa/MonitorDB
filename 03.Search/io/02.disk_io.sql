DECLARE @offset int = 540;		-- localtime 用オフセット (JST)
DECLARE @range int = -12;		-- 直近 12 時間のデータを取得

WITH performance_info
AS(
	SELECT
		*
	FROM
		performance_counters
	WHERE
		measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
		AND
		object_name = 'Resource Pool Stats'
		AND
		instance_name <> 'internal'
		AND
		counter_name IN ('Avg Disk Read IO (ms)', 'Avg Disk Write IO (ms)', 'Avg Disk Read IO (ms) Base', 'Avg Disk Write IO (ms) Base',
		'Disk Read IO/sec', 'Disk Write IO/sec', 'Disk Read Bytes/sec', 'Disk Write Bytes/sec')
)
SELECT
	*
FROM(
	SELECT
		T1.measure_date_local,
		T1.server_name,
		T1.object_name,
		T1.counter_name,
		T1.instance_name,
		CASE T1.cntr_value
			WHEN 0 THEN 0
			ELSE COALESCE(T1.cntr_value,0) / T2.cntr_value 
		END AS cntr_value
	FROM
		performance_info AS T1
		LEFT JOIN
			performance_info AS T2
		ON
			T2.measure_date_local = T1.measure_date_local
			AND
			T2.server_name = T1.server_name
			AND
			T2.object_name = T1.object_name
			AND
			T2.counter_name = RTRIM(T1.counter_name) + ' Base'
			AND
			T2.instance_name = T1.instance_name
	WHERE
		T1.counter_name IN ('Avg Disk Read IO (ms)', 'Avg Disk Write IO (ms)')
	UNION
	SELECT
		T1.measure_date_local,
		T1.server_name,
		T1.object_name,
		T1.counter_name,
		T1.instance_name,
		T1.cntr_value
	FROM
		performance_info AS T1
	WHERE
		T1.counter_name IN ('Disk Read IO/sec', 'Disk Write IO/sec', 'Disk Read Bytes/sec', 'Disk Write Bytes/sec')
) AS T
PIVOT(
	AVG(cntr_value)
	FOR counter_name IN([Avg Disk Read IO (ms)],[Avg Disk Write IO (ms)],[Disk Read Bytes/sec],[Disk Read IO/sec],[Disk Write Bytes/sec],[Disk Write IO/sec])
) AS PVT
ORDER BY
	instance_name ASC,
	measure_date_local ASC
