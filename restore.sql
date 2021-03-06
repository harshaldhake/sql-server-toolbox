USE [master]
GO
--Restore template




--RESTORE FILELISTONLY FROM  DISK = N'C:\Conversion\BACKUPS\ProdImplementation\PRISM_backup_200810162300.bak' 
go
ALTER DATABASE [Surveillance_UAT] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
RESTORE DATABASE [Surveillance_UAT] 
FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL10.SQL2K8\MSSQL\Backup\Surveillance_UAT_backup_201003241230.bak' 
WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO
ALTER DATABASE [Surveillance_UAT] SET  MULTI_USER
GO
 
--ALTER DATABASE PCFScratch_William SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
--GO
--RESTORE DATABASE [PCFScratch_William] FROM  DISK = N'C:\Conversion\BACKUPS\ProdImplementation\PRISM_backup_200810131208.bak' 
--WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 5,
-- MOVE 'Prism' to 'c:\Conversion\DATA\PCFScratch_William.mdf',
-- MOVE 'Prism_log' to 'c:\Conversion\DATA\PCFScratch_William_1.ldf'
--GO
--
--ALTER DATABASE PCFScratch_William SET  MULTI_USER
--GO
-- 

/*

--Restore WWI
USE [master]
--https://github.com/Microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers
ALTER DATABASE [WideWorldImporters] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
RESTORE DATABASE [WideWorldImporters] FROM  
DISK = N'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\Backup\WideWorldImporters-Full.bak' 
--DISK = N'E:\Program Files\Microsoft SQL Server\MSSQL13.SQL2K16\MSSQL\Backup\WideWorldImporters-Full.bak' 
WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 5
GO
ALTER DATABASE [WideWorldImporters] SET MULTI_USER
GO
ALTER DATABASE [WideWorldImporters] SET COMPATIBILITY_LEVEL = 140
GO


--initial
USE [master]
RESTORE DATABASE [WideWorldImporters] FROM  DISK = N'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\Backup\WideWorldImporters-Full.bak' WITH  FILE = 1,  MOVE N'WWI_Primary' TO N'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\DATA\WideWorldImporters.mdf',  MOVE N'WWI_UserData' TO N'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\DATA\WideWorldImporters_UserData.ndf',  MOVE N'WWI_Log' TO N'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\DATA\WideWorldImporters.ldf',  MOVE N'WWI_InMemory_Data_1' TO N'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\DATA\WideWorldImporters_InMemory_Data_1',  NOUNLOAD,  STATS = 5
GO

*/