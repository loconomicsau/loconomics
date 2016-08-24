/*
   miércoles, 24 de agosto de 201614:03:57
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
ALTER TABLE dbo.ServiceProfessionalClient ADD
	DeletedByServiceProfessional bit NOT NULL CONSTRAINT DF_ServiceProfessionalClient_DeletedByServiceProfessional DEFAULT 0
GO
ALTER TABLE dbo.ServiceProfessionalClient SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.ServiceProfessionalClient', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.ServiceProfessionalClient', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.ServiceProfessionalClient', 'Object', 'CONTROL') as Contr_Per 