/*
   miércoles, 23 de septiembre de 201521:48:24
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
CREATE TABLE dbo.Tmp_pricingSummaryDetail
	(
	PricingSummaryID int NOT NULL,
	PricingSummaryRevision int NOT NULL,
	ServiceProfessionalServiceID int NOT NULL,
	ServiceProfessionalDataInput varchar(100) NULL,
	ClientDataInput varchar(500) NULL,
	HourlyPrice decimal(5, 2) NULL,
	Price decimal(7, 2) NULL,
	ServiceDurationMinutes int NULL,
	FirstSessionDurationMinutes int NULL,
	ServiceName varchar(50) NULL,
	ServiceDescription varchar(1000) NULL,
	NumberOfSessions int NULL,
	CreatedDate datetime NOT NULL,
	UpdatedDate datetime NOT NULL,
	ModifiedBy varchar(25) NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_pricingSummaryDetail SET (LOCK_ESCALATION = TABLE)
GO
IF EXISTS(SELECT * FROM dbo.pricingSummaryDetail)
	 EXEC('INSERT INTO dbo.Tmp_pricingSummaryDetail (PricingSummaryID, PricingSummaryRevision, ServiceProfessionalServiceID, ServiceProfessionalDataInput, ClientDataInput, HourlyPrice, Price, ServiceDurationMinutes, FirstSessionDurationMinutes, CreatedDate, UpdatedDate, ModifiedBy)
		SELECT PricingSummaryID, PricingSummaryRevision, ServiceProfessionalServiceID, ServiceProfessionalDataInput, ClientDataInput, HourlyPrice, Price, ServiceDurationMinutes, FirstSessionDurationMinutes, CreatedDate, UpdatedDate, ModifiedBy FROM dbo.pricingSummaryDetail WITH (HOLDLOCK TABLOCKX)')
GO
DROP TABLE dbo.pricingSummaryDetail
GO
EXECUTE sp_rename N'dbo.Tmp_pricingSummaryDetail', N'pricingSummaryDetail', 'OBJECT' 
GO
ALTER TABLE dbo.pricingSummaryDetail ADD CONSTRAINT
	PK_pricingestimatedetail_1 PRIMARY KEY CLUSTERED 
	(
	PricingSummaryID,
	PricingSummaryRevision,
	ServiceProfessionalServiceID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
COMMIT
select Has_Perms_By_Name(N'dbo.pricingSummaryDetail', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.pricingSummaryDetail', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.pricingSummaryDetail', 'Object', 'CONTROL') as Contr_Per 