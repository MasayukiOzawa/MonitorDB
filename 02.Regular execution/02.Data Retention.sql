SET NOCOUNT ON
GO
DECLARE @offset int = 540;　		-- localtime 用オフセット
DECLARE @delete_target int = -3 	-- 3 ヶ月

-- ****************************************
-- ** Wait Stats
-- ****************************************
WHILE ((SELECT COUNT(*) FROM wait_stats WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))) > 0)
BEGIN
	DELETE TOP (5000) FROM wait_stats WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))
END

-- ****************************************
-- ** Performance Counters
-- ****************************************
WHILE ((SELECT COUNT(*) FROM performance_counters WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))) > 0)
BEGIN
	DELETE TOP (5000) FROM performance_counters WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))
END

-- ****************************************
-- ** Scheduler
-- ****************************************
WHILE ((SELECT COUNT(*) FROM scheduler WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))) > 0)
BEGIN
	DELETE TOP (5000) FROM scheduler WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))
END

-- ****************************************
-- ** Sessio / Connection / Worker / Task
-- ****************************************
WHILE ((SELECT COUNT(*) FROM session_connection_worker WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))) > 0)
BEGIN
	DELETE TOP (5000) FROM session_connection_worker WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))
END

-- ****************************************
-- ** File I/O
-- ****************************************
WHILE ((SELECT COUNT(*) FROM file_io WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))) > 0)
BEGIN
	DELETE TOP (5000) FROM file_io WHERE measure_date_local <= DATEADD(mm, @delete_target, (DATEADD(mi, @offset, GETUTCDATE())))
END