--Intention is to catch only severe errors and startup failures
--Specifically because before Service Broker starts, some error Alerts may not send emails.

--Check TODO's for mail profile and recipient

USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'Startup error check', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'Startup error check', @server_name = N'(local)'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Startup error check', @step_name=N'check for errors', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--Intention is to catch only severe errors and startup failures
--Specifically because before Service Broker starts, some error Alerts may not send emails.

WAITFOR DELAY ''00:01'';  --wait one minute

declare @readerrorlog table 
( LogDate datetime2(2) not null   
, LogProcessInfo nvarchar(255)  null 
, [LogMessageText] nvarchar(4000) not null 
)

declare @readerrorlog_found table 
( LogDate datetime2(2) not null  
, LogProcessInfo nvarchar(255)  null 
, [LogMessageText] nvarchar(4000) not null 
)

INSERT INTO @readerrorlog (LogDate, LogProcessInfo, LogMessageText)
	EXEC master.dbo.xp_readerrorlog  
	  0					--current log file
	, 1					--SQL Error Log
	, N''''				--search string 1, must be unicode. Leave empty on purpose, as we do filtering later on.
	, N''''				--search string 2, must be unicode. Leave empty on purpose, as we do filtering later on.
	, null, null --time filter. Should be @oldestdate < @now
	, N''desc''			--sort

--select * from @readerrorlog order by logdate asc

INSERT INTO @readerrorlog_found  (LogDate, LogProcessInfo, LogMessageText)
select * from @readerrorlog
where  (logmessagetext like ''%Error%''
or logmessagetext like ''%corruption%''
or logmessagetext like ''%prevent%''
or logmessagetext like ''%could not register the Service Principal Name%''
or logmessagetext like ''%could not be decrypted%''
or LogMessageText like ''%warning%''
or LogMessageText like ''%Could not open file%''
or LogMessageText like ''%Unable to open%''
or LogMessageText like ''%cannot be opened%''
or LogMessageText like ''%insufficient%''
or LogMessageText like ''%exception%''
or LogMessageText like ''%transaction log for database%is full%''
or LogMessageText like ''%non-yielding%''
or LogMessageText like ''%Stack signature%''
or LogMessageText like ''%aborted%''
or LogMessageText like ''%Access is denied%''
or LogMessageText like ''%Run DBCC%.''
or LogMessageText like ''%Attempt to fetch%failed%''
or LogMessageText like ''%An error occurred during recovery%''
or LogMessageText like ''%marked SUSPECT%''
or LogMessageText like ''%I/O error%''
or LogMessageText like ''%could not redo%''
or LogMessageText like ''%* DBCC database corruption%''

)
and (logmessagetext not like ''Registry startup parameters%''
and logmessagetext not like ''Logging SQL Server messages in file%''
and LogMessageText not like ''%without errors%''
and LogMessageText not like ''%found 0 errors%''
and LogMessageText not like ''Login failed%''
and LogMessageText not like ''%informational message only%''
and LogMessageText not like ''%no user action is required%''
and LogMessageText not like ''Error: 18456, Severity: 14%''
and LogMessageText not like ''%because it is read-only.%''
and LogMessageText not like ''%Could not find a login matching the name provided%''

and LogMessageText not like ''%The server will automatically attempt to re-establish listening.%''
and LogMessageText not like ''%Error: 26050, Severity: 17%''

and LogMessageText not like ''%Database%cannot be opened because it is offline.%''
and LogMessageText not like ''Error: 942, Severity: 14, State: 4.''

and LogMessageText not like ''The login packet used to open the connection is structurally invalid%''
and LogMessageText not like ''Error: 17832, Severity: 20, State: 18.''

and LogMessageText not like ''Error: 3041, Severity: 16, State: 1.''

and LogMessageText not like ''Setting database option ANSI_%''

)
order by logdate

--select * from @readerrorlog_found order by logdate asc

IF EXISTS  (Select * from sys.databases d where STATE = 4)
INSERT INTO @readerrorlog_found (LogDate, LogProcessInfo, LogMessageText)
select sysdatetime(), NULL, ''Database name '' + d.name + ''is in SUSPECT mode!''
from sys.databases d where STATE = 4;

IF NOT EXISTS  (Select * from @readerrorlog_found) 
INSERT INTO @readerrorlog_found (LogDate, LogProcessInfo, LogMessageText)
VALUES (sysdatetime(), NULL, ''No listed startup errors found.'');

declare @body nvarchar(4000) = ''SQL Server instance startup detected '' + @@SERVERNAME
select @body = @body + ''
<table border=0>''
select 	@body = @body + ''
<tr><td>'' + convert(nvarchar(30), LogDate) + ''</td>
<td>'' + isnull(LogProcessInfo, '''')+ ''</td>
<td>'' + LogMessageText+ ''</td></tr>''
--, *
from @readerrorlog_found order by logdate asc;
select @body = @body + ''</table>''

select @body = LEFT(@body, 4000) --Safety

--Send email
exec msdb.dbo.sp_send_dbmail 
	@profile_name = ''sh-tenroxsql''  --TODO: must configure this server-specific
, @recipients = ''william.assaf@sparkhound.com'' --TODO: Must configure this for the sql.alerts@sparkhound.com or internal distribution group
, @subject = ''SQL Server instance Startup Report'', @body = @body, @exclude_query_output = 0
, @body_format =''html''', 
		@database_name=N'master', 
		@flags=4
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'Startup error check', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'Startup error check', @name=N'sql startup', 
		@enabled=1, 
		@freq_type=64, 
		@freq_interval=1, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190305, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
USE [msdb]
GO

