SET NOCOUNT ON
GO
DECLARE @offset int = 540;　		-- localtime 用オフセット
DECLARE @delete_target int = -1 	-- 何日前のデータを削除するか
DECLARE @delete_size int = 40000     -- 1 処理の削除レコード数
DECLARE @cnt int = 0
DECLARE @success_cnt bigint = 0

-- ****************************************
-- ** Wait Stats
-- ****************************************
WHILE ((SELECT COUNT(*) FROM wait_stats WHERE measure_date_local <= CAST(DATEADD(dd, @delete_target + 1, (DATEADD(mi, @offset, GETUTCDATE()))) AS date)) > 0)
BEGIN
	SET @cnt += 1
	DELETE TOP (@delete_size) FROM wait_stats WHERE measure_date_local <= CAST(DATEADD(dd, @delete_target + 1, (DATEADD(mi, @offset, GETUTCDATE()))) AS date)

	SET @success_cnt = @cnt * @delete_size
	RAISERROR(N'[%s] %I64d Record Delete Success!!', 0, 0, N'wait_stats', @success_cnt) WITH NOWAIT
END

-- ****************************************
-- ** Performance Counters
-- ****************************************
SET @cnt = 0
WHILE ((SELECT COUNT(*) FROM performance_counters WHERE measure_date_local <= CAST(DATEADD(dd, @delete_target + 1, (DATEADD(mi, @offset, GETUTCDATE()))) AS date)) > 0)
BEGIN
	SET @cnt += 1
	DELETE TOP (@delete_size) FROM performance_counters WHERE measure_date_local <= CAST(DATEADD(dd, @delete_target + 1, (DATEADD(mi, @offset, GETUTCDATE()))) AS date)
	
	SET @success_cnt = @cnt * @delete_size
	RAISERROR(N'[%s] %I64d Record Delete Success!!', 0,0, N'performance_counters', @success_cnt ) WITH NOWAIT
END

-- ****************************************
-- ** Scheduler
-- ****************************************
SET @cnt = 0
WHILE ((SELECT COUNT(*) FROM scheduler WHERE measure_date_local <= CAST(DATEADD(dd, @delete_target + 1, (DATEADD(mi, @offset, GETUTCDATE()))) AS date)) > 0)
BEGIN
	SET @cnt += 1
	DELETE TOP (@delete_size) FROM scheduler WHERE measure_date_local <= CAST(DATEADD(dd, @delete_target + 1, (DATEADD(mi, @offset, GETUTCDATE()))) AS date)
	
	SET @success_cnt = @cnt * @delete_size
	RAISERROR(N'[%s] %I64d Record Delete Success!!', 0,0, N'scheduler', @success_cnt ) WITH NOWAIT
END

-- ****************************************
-- ** Sessio / Connection / Worker / Task
-- ****************************************
SET @cnt = 0
WHILE ((SELECT COUNT(*) FROM session_connection_worker WHERE measure_date_local <= CAST(DATEADD(dd, @delete_target + 1, (DATEADD(mi, @offset, GETUTCDATE()))) AS date)) > 0)
BEGIN
	SET @cnt += 1
	DELETE TOP (@delete_size) FROM session_connection_worker WHERE measure_date_local <= CAST(DATEADD(dd, @delete_target + 1, (DATEADD(mi, @offset, GETUTCDATE()))) AS date)
	
	SET @success_cnt = @cnt * @delete_size
	RAISERROR(N'[%s] %I64d Record Delete Success!!', 0,0, N'session_connection_worker', @success_cnt ) WITH NOWAIT
END

-- ****************************************
-- ** File I/O
-- ****************************************
SET @cnt = 0
WHILE ((SELECT COUNT(*) FROM file_io WHERE measure_date_local <= CAST(DATEADD(dd, @delete_target + 1, (DATEADD(mi, @offset, GETUTCDATE()))) AS date)) > 0)
BEGIN
	SET @cnt += 1
	DELETE TOP (@delete_size) FROM file_io WHERE measure_date_local <= CAST(DATEADD(dd, @delete_target + 1, (DATEADD(mi, @offset, GETUTCDATE()))) AS date)
	
	SET @success_cnt = @cnt * @delete_size
	RAISERROR(N'[%s] %I64d Record Delete Success!!', 0,0, N'file_io', @success_cnt ) WITH NOWAIT
END