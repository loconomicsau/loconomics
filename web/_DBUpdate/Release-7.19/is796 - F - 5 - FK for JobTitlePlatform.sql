/*
   viernes, 09 de marzo de 201817:44:06
   User: 
   Server: ESTUDIO-I3\SQLEXPRESS
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
ALTER TABLE dbo.Platform SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.Platform', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.Platform', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.Platform', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.JobTitlePlatform ADD CONSTRAINT
	FK_JobTitlePlatform_Platform FOREIGN KEY
	(
	PlatformID,
	LanguageID,
	CountryID
	) REFERENCES dbo.Platform
	(
	PlatformID,
	LanguageID,
	CountryID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.JobTitlePlatform SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.JobTitlePlatform', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.JobTitlePlatform', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.JobTitlePlatform', 'Object', 'CONTROL') as Contr_Per 