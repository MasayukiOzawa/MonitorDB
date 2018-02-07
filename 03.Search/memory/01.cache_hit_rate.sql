DECLARE @offset int = 540;		-- localtime 用オフセット (JST)
DECLARE @range int = -12;		-- 直近 12 時間のデータを取得

SELECT
	*
FROM(
	SELECT 
		T1.measure_date_local,
--		T1.measure_date_utc,
--		T1.server_name,
--		T1.object_name,
--		T1.counter_name,
		CASE WHEN 
			T1.object_name = 'Buffer Manager' THEN 'Buffer Manager'
		ELSE
			RTRIM(T1.instance_name)
		END AS instance_name,
		CASE T1.cntr_value 
			WHEN 0 THEN 0
		ELSE
			CAST((T1.cntr_value * 1.0 / T2.cntr_value * 100) AS numeric(5,2))
		END AS cntr_value
	FROM 
		performance_counters T1 WITH(NOLOCK)
		LEFT JOIN
			performance_counters T2 WITH(NOLOCK)
		ON
			T2.measure_date_local =  T1.measure_date_local
			AND
			T2.server_name = T1.server_name
			AND
			T2.object_name = T1.object_name
			AND
			T2.instance_name = T1.instance_name
			AND
			T2.counter_name IN ('Buffer cache hit ratio base', 'Cache Hit Ratio Base')
	WHERE
		T1.measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
		AND
		T1.object_name IN ('Buffer Manager', 'Plan Cache')
		AND
		T1.counter_name IN ('Buffer cache hit ratio', 'Cache Hit Ratio')
		AND
		T1.instance_name <> '_Total'
) AS T
PIVOT(
	SUM(cntr_value)
	FOR instance_name IN([Buffer Manager], [SQL Plans], [Object Plans], [Bound Trees], [Extended Stored Procedures], [Temporary Tables & Table Variables])
) AS PVT