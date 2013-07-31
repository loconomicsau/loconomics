/*
   miércoles, 31 de julio de 201313:40:18
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
ALTER TABLE dbo.pricingestimatedetail
	DROP CONSTRAINT PK_pricingestimatedetail
GO
ALTER TABLE dbo.pricingestimatedetail ADD CONSTRAINT
	PK_pricingestimatedetail_1 PRIMARY KEY CLUSTERED 
	(
	PricingEstimateID,
	PricingEstimateRevision,
	ProviderPackageID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.pricingestimatedetail
	DROP COLUMN PricingVariableID, PricingSurchargeID, PricingOptionID, ServiceAttributeID, SystemPricingDataInput
GO
ALTER TABLE dbo.pricingestimatedetail SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.pricingestimatedetail', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.pricingestimatedetail', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.pricingestimatedetail', 'Object', 'CONTROL') as Contr_Per 