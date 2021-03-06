/*
   viernes, 02 de febrero de 201818:53:49
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
ALTER TABLE dbo.Platform
	DROP CONSTRAINT FK_Platform_language
GO
ALTER TABLE dbo.language SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.language', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.language', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.language', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.Platform
	DROP CONSTRAINT DF_Platform_Active
GO
CREATE TABLE dbo.Tmp_Platform
	(
	PlatformID int NOT NULL,
	LanguageID int NOT NULL,
	CountryID int NOT NULL,
	Name nvarchar(20) NOT NULL,
	ShortDescription nvarchar(50) NOT NULL,
	LongDescription text NOT NULL,
	FeesDescription text NOT NULL,
	PositiveAspects text NOT NULL,
	NegativeAspects text NOT NULL,
	Advice text NOT NULL,
	SignUpURL nvarchar(255) NOT NULL,
	SignInURL nvarchar(255) NOT NULL,
	CreatedDate datetimeoffset(7) NOT NULL,
	UpdatedDate datetimeoffset(0) NOT NULL,
	ModifiedBy nvarchar(4) NOT NULL,
	Active bit NOT NULL
	)  ON [PRIMARY]
	 TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_Platform SET (LOCK_ESCALATION = TABLE)
GO
ALTER TABLE dbo.Tmp_Platform ADD CONSTRAINT
	DF_Platform_Active DEFAULT ((1)) FOR Active
GO
IF EXISTS(SELECT * FROM dbo.Platform)
	 EXEC('INSERT INTO dbo.Tmp_Platform (PlatformID, LanguageID, CountryID, Name, ShortDescription, LongDescription, FeesDescription, PositiveAspects, NegativeAspects, Advice, SignUpURL, SignInURL, CreatedDate, UpdatedDate, ModifiedBy, Active)
		SELECT PlatformID, LanguageID, CountryID, Name, ShortDescription, LongDescription, FeesDescription, PositiveAspects, NegativeAspects, Advice, SignUpURL, SignInURL, CreatedDate, UpdatedDate, ModifiedBy, Active FROM dbo.Platform WITH (HOLDLOCK TABLOCKX)')
GO
ALTER TABLE dbo.UserExternalListing
	DROP CONSTRAINT FK_UserExternalListing_Platform
GO
ALTER TABLE dbo.UserEarnings
	DROP CONSTRAINT FK_UserEarnings_Platform
GO
DROP TABLE dbo.Platform
GO
EXECUTE sp_rename N'dbo.Tmp_Platform', N'Platform', 'OBJECT' 
GO
ALTER TABLE dbo.Platform ADD CONSTRAINT
	PK_Platform PRIMARY KEY CLUSTERED 
	(
	PlatformID,
	LanguageID,
	CountryID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.Platform ADD CONSTRAINT
	FK_Platform_language FOREIGN KEY
	(
	LanguageID,
	CountryID
	) REFERENCES dbo.language
	(
	LanguageID,
	CountryID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
COMMIT
select Has_Perms_By_Name(N'dbo.Platform', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.Platform', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.Platform', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.UserEarnings SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.UserEarnings', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.UserEarnings', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.UserEarnings', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.UserExternalListing SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.UserExternalListing', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.UserExternalListing', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.UserExternalListing', 'Object', 'CONTROL') as Contr_Per 