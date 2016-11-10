/*
   martes, 19 de enero de 201619:07:57
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
ALTER TABLE dbo.cancellationpolicy
	DROP CONSTRAINT DF__cancellat__Refun__01A9287E
GO
CREATE TABLE dbo.Tmp_cancellationpolicy
	(
	CancellationPolicyID int NOT NULL,
	LanguageID int NOT NULL,
	CountryID int NOT NULL,
	CancellationPolicyName varchar(50) NOT NULL,
	CancellationPolicyDescription varchar(1000) NULL,
	HoursRequired int NULL,
	CancellationFeeAfter decimal(5, 2) NULL,
	CancellationFeeBefore decimal(5, 2) NULL,
	CreatedDate datetime NOT NULL,
	UpdatedDate datetime NOT NULL,
	ModifiedBy varchar(25) NOT NULL,
	Active bit NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_cancellationpolicy SET (LOCK_ESCALATION = TABLE)
GO
IF EXISTS(SELECT * FROM dbo.cancellationpolicy)
	 EXEC('INSERT INTO dbo.Tmp_cancellationpolicy (CancellationPolicyID, LanguageID, CountryID, CancellationPolicyName, CancellationPolicyDescription, HoursRequired, CancellationFeeAfter, CancellationFeeBefore, CreatedDate, UpdatedDate, ModifiedBy, Active)
		SELECT CancellationPolicyID, LanguageID, CountryID, CancellationPolicyName, CancellationPolicyDescription, HoursRequired, CONVERT(decimal(5, 2), RefundIfCancelledBefore), CONVERT(decimal(5, 2), RefundIfCancelledAfter), CreatedDate, UpdatedDate, ModifiedBy, Active FROM dbo.cancellationpolicy WITH (HOLDLOCK TABLOCKX)')
GO
ALTER TABLE dbo.booking
	DROP CONSTRAINT FK__booking__cancellationPolicy
GO
DROP TABLE dbo.cancellationpolicy
GO
EXECUTE sp_rename N'dbo.Tmp_cancellationpolicy', N'cancellationpolicy', 'OBJECT' 
GO
ALTER TABLE dbo.cancellationpolicy ADD CONSTRAINT
	PK__cancella__4BAA8CCE7A0806B6 PRIMARY KEY CLUSTERED 
	(
	CancellationPolicyID,
	LanguageID,
	CountryID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
COMMIT
select Has_Perms_By_Name(N'dbo.cancellationpolicy', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.cancellationpolicy', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.cancellationpolicy', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.booking ADD CONSTRAINT
	FK__booking__cancellationPolicy FOREIGN KEY
	(
	CancellationPolicyID,
	LanguageID,
	CountryID
	) REFERENCES dbo.cancellationpolicy
	(
	CancellationPolicyID,
	LanguageID,
	CountryID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.booking SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.booking', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.booking', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.booking', 'Object', 'CONTROL') as Contr_Per 