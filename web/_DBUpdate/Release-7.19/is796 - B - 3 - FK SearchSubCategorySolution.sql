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
ALTER TABLE dbo.Solution SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.Solution', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.Solution', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.Solution', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.SearchSubCategory SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.SearchSubCategory', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.SearchSubCategory', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.SearchSubCategory', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.language SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.language', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.language', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.language', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.SearchSubCategorySolution ADD CONSTRAINT
	FK_SearchSubCategorySolution_language FOREIGN KEY
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
ALTER TABLE dbo.SearchSubCategorySolution ADD CONSTRAINT
	FK_SearchSubCategorySolution_SearchSubCategory FOREIGN KEY
	(
	SearchSubCategoryID,
	LanguageID,
	CountryID
	) REFERENCES dbo.SearchSubCategory
	(
	SearchSubCategoryID,
	LanguageID,
	CountryID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.SearchSubCategorySolution ADD CONSTRAINT
	FK_SearchSubCategorySolution_Solution FOREIGN KEY
	(
	SolutionID,
	LanguageID,
	CountryID
	) REFERENCES dbo.Solution
	(
	SolutionID,
	LanguageID,
	CountryID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.SearchSubCategorySolution SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.SearchSubCategorySolution', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.SearchSubCategorySolution', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.SearchSubCategorySolution', 'Object', 'CONTROL') as Contr_Per 