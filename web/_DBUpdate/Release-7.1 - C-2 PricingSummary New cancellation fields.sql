/*
   martes, 19 de enero de 201619:15:00
   User: 
   Server: localhost\SQLEXPRESS
   Database: loconomics
   Application: 
*/

/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
EXECUTE sp_rename N'dbo.pricingSummary.DateRefunded', N'Tmp_CancellationDate', 'COLUMN' 
GO
EXECUTE sp_rename N'dbo.pricingSummary.Tmp_CancellationDate', N'CancellationDate', 'COLUMN' 
GO
ALTER TABLE dbo.pricingSummary ADD
	CancellationFeeCharged decimal(7, 2) NULL
GO
ALTER TABLE dbo.pricingSummary
	DROP COLUMN FeeRefunded, TotalRefunded
GO
ALTER TABLE dbo.pricingSummary SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.pricingSummary', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.pricingSummary', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.pricingSummary', 'Object', 'CONTROL') as Contr_Per 