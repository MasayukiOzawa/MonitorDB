DECLARE @offset int = 540;		-- localtime �p�I�t�Z�b�g (JST)
DECLARE @range int = -12;		-- ���� 12 ���Ԃ̃f�[�^���擾

WITH performance_info
AS(
SELECT
	ROW_NUMBER() OVER (PARTITION BY server_name, object_name,counter_name ORDER BY measure_date_local ASC ) AS No,
	measure_date_local,
	server_name,
	object_name,
	counter_name,
	instance_name,
	cntr_value
FROM
	 performance_counters WITH(NOLOCK)
WHERE 
	measure_date_local >= DATEADD(hh, @range, (DATEADD(mi, @offset, GETUTCDATE())))
	AND
	object_name = 'Batch Resp Statistics'
	AND
	instance_name = 'CPU Time:Requests'
)
SELECT
	T1.measure_date_local,
	T1.server_name,
	T1.object_name,
	T1.counter_name,
	T1.instance_name,
	T1.cntr_value,
	COALESCE(T1.cntr_value - T2.cntr_value,0) AS measure_cntr_value
FROM
	performance_info T1 WITH(NOLOCK)
	LEFT HASH JOIN
		performance_info T2 WITH(NOLOCK)
	ON
		T2.No = T1.No - 1
		AND
		T2.server_name = T1.server_name
		AND
		T2.counter_name = T1.counter_name
		AND
		T2.object_name = T1.object_name
		AND
		T2.instance_name = T1.instance_name