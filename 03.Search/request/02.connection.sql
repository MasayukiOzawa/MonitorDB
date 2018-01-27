DECLARE @offset int = 540;�@-- localtime �p�I�t�Z�b�g

SELECT 
	measure_date_local,
	measure_date_utc,
	server_name,
	object_name,
	counter_name,
	instance_name,
	cntr_value
FROM 
	performance_counters WITH(NOLOCK)
WHERE
	measure_date_local >= DATEADD(mi, -30, (DATEADD(mi, @offset, GETUTCDATE())))
	AND
	counter_name = 'User Connections'