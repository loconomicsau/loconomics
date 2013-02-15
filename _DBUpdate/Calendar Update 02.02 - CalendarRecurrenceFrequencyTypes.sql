/*
   viernes, 15 de febrero de 201310:40:51
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
CREATE TABLE dbo.CalendarRecurrenceFrequencyTypes
	(
	ID int NOT NULL,
	Name nvarchar(30) NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.CalendarRecurrenceFrequencyTypes ADD CONSTRAINT
	PK_CalendarRecurrenceFrequencyTypes PRIMARY KEY CLUSTERED 
	(
	ID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.CalendarRecurrenceFrequencyTypes SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.CalendarRecurrenceFrequencyTypes', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.CalendarRecurrenceFrequencyTypes', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.CalendarRecurrenceFrequencyTypes', 'Object', 'CONTROL') as Contr_Per 

GO

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
EXECUTE sp_rename N'dbo.CalendarRecurrenceFrequencyTypes.Name', N'Tmp_FrequencyType', 'COLUMN' 
GO
EXECUTE sp_rename N'dbo.CalendarRecurrenceFrequencyTypes.Tmp_FrequencyType', N'FrequencyType', 'COLUMN' 
GO
ALTER TABLE dbo.CalendarRecurrenceFrequencyTypes ADD CONSTRAINT
	FK_CalendarRecurrenceFrequencyTypes_CalendarRecurrenceFrequencyTypes FOREIGN KEY
	(
	ID
	) REFERENCES dbo.CalendarRecurrenceFrequencyTypes
	(
	ID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.CalendarRecurrenceFrequencyTypes SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.CalendarRecurrenceFrequencyTypes', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.CalendarRecurrenceFrequencyTypes', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.CalendarRecurrenceFrequencyTypes', 'Object', 'CONTROL') as Contr_Per 
