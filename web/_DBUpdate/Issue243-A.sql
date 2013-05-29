/*
   miércoles, 29 de mayo de 201311:59:34
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
ALTER TABLE dbo.UserAlert ADD
	Dismissed bit NOT NULL CONSTRAINT DF_UserAlert_Dismissed DEFAULT 0
GO
ALTER TABLE dbo.UserAlert SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.UserAlert', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.UserAlert', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.UserAlert', 'Object', 'CONTROL') as Contr_Per 