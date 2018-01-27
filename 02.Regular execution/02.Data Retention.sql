SET NOCOUNT ON
GO
DECLARE @offset int = 540;�@-- localtime �p�I�t�Z�b�g
DECLARE @delete_target int = -3 -- 3 ����

WHILE ((SELECT COUNT(*) FROM wait_stats WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))) > 0)
BEGIN
	DELETE TOP (5000) FROM wait_stats WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))
END

WHILE ((SELECT COUNT(*) FROM performance_counters WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))) > 0)
BEGIN
	DELETE TOP (5000) FROM performance_counters WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))
END

WHILE ((SELECT COUNT(*) FROM scheduler WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))) > 0)
BEGIN
	DELETE TOP (5000) FROM scheduler WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))
END