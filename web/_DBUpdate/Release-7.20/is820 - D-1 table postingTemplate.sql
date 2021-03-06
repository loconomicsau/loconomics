/*
   martes, 29 de mayo de 201813:55:52
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
CREATE TABLE dbo.postingTemplate
	(
	postingTemplateID int NOT NULL,
	name nvarchar(200) NOT NULL,
	languageID int NOT NULL,
	countryID int NOT NULL,
	createdDate datetimeoffset(0) NOT NULL,
	updatedDate datetimeoffset(0) NOT NULL,
	modifiedBy nchar(5) NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.postingTemplate ADD CONSTRAINT
	PK_postingTemplate PRIMARY KEY CLUSTERED 
	(
	postingTemplateID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.postingTemplate SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.postingTemplate', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.postingTemplate', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.postingTemplate', 'Object', 'CONTROL') as Contr_Per 