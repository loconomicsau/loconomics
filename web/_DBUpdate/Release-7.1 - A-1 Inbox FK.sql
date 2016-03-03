/*
   martes, 23 de febrero de 201618:19:45
   User: DB_31755_dev_user
   Server: s09.winhost.com
   Database: DB_31755_dev
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
ALTER TABLE dbo.messagethreadstatus SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.messagethreadstatus', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.messagethreadstatus', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.messagethreadstatus', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.Messages SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.Messages', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.Messages', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.Messages', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.users SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.users', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.users', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.users', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.MessagingThreads ADD CONSTRAINT
	Fk_MessagingThreads_2 FOREIGN KEY
	(
	CustomerUserID
	) REFERENCES dbo.users
	(
	UserID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.MessagingThreads ADD CONSTRAINT
	FK_MessagingThreads_users FOREIGN KEY
	(
	ProviderUserID
	) REFERENCES dbo.users
	(
	UserID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.MessagingThreads ADD CONSTRAINT
	FK_MessagingThreads_Messages FOREIGN KEY
	(
	LastMessageID
	) REFERENCES dbo.Messages
	(
	MessageID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.MessagingThreads ADD CONSTRAINT
	FK_MessagingThreads_messagethreadstatus FOREIGN KEY
	(
	ThreadID
	) REFERENCES dbo.messagethreadstatus
	(
	MessageThreadStatusID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
COMMIT
