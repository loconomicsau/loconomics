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
ALTER TABLE dbo.userprofilepositions
	DROP CONSTRAINT FK_userprofilepositions_accountstatus
GO
ALTER TABLE dbo.accountstatus SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.accountstatus', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.accountstatus', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.accountstatus', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.userprofilepositions
	DROP CONSTRAINT FK_userprofilepositions_positions
GO
ALTER TABLE dbo.positions SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.positions', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.positions', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.positions', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.userprofilepositions
	DROP CONSTRAINT FK_userprofilepositions_users
GO
ALTER TABLE dbo.users SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
select Has_Perms_By_Name(N'dbo.users', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.users', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.users', 'Object', 'CONTROL') as Contr_Per BEGIN TRANSACTION
GO
ALTER TABLE dbo.userprofilepositions
	DROP CONSTRAINT DF_userprofilepositions_StatusID
GO
ALTER TABLE dbo.userprofilepositions
	DROP CONSTRAINT DF_userprofilepositions_InstantBooking
GO
ALTER TABLE dbo.userprofilepositions
	DROP CONSTRAINT DF_userprofilepositions_bookMeButtonReady
GO
ALTER TABLE dbo.userprofilepositions
	DROP CONSTRAINT DF_userprofilepositions_collectPaymentAtBookMeButton
GO
CREATE TABLE dbo.Tmp_userprofilepositions
	(
	UserListingID int NOT NULL IDENTITY (1, 1),
	UserID int NOT NULL,
	PositionID int NOT NULL,
	LanguageID int NOT NULL,
	CountryID int NOT NULL,
	CreateDate datetime NULL,
	UpdatedDate datetime NULL,
	ModifiedBy varchar(3) NULL,
	Active bit NULL,
	PositionIntro varchar(2000) NULL,
	StatusID int NOT NULL,
	CancellationPolicyID int NULL,
	additionalinfo1 nvarchar(500) NULL,
	additionalinfo2 nvarchar(500) NULL,
	additionalinfo3 nvarchar(500) NULL,
	InstantBooking bit NOT NULL,
	bookMeButtonReady bit NOT NULL,
	collectPaymentAtBookMeButton bit NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_userprofilepositions SET (LOCK_ESCALATION = TABLE)
GO
ALTER TABLE dbo.Tmp_userprofilepositions ADD CONSTRAINT
	DF_userprofilepositions_StatusID DEFAULT ((1)) FOR StatusID
GO
ALTER TABLE dbo.Tmp_userprofilepositions ADD CONSTRAINT
	DF_userprofilepositions_InstantBooking DEFAULT ((0)) FOR InstantBooking
GO
ALTER TABLE dbo.Tmp_userprofilepositions ADD CONSTRAINT
	DF_userprofilepositions_bookMeButtonReady DEFAULT ((0)) FOR bookMeButtonReady
GO
ALTER TABLE dbo.Tmp_userprofilepositions ADD CONSTRAINT
	DF_userprofilepositions_collectPaymentAtBookMeButton DEFAULT ((1)) FOR collectPaymentAtBookMeButton
GO
SET IDENTITY_INSERT dbo.Tmp_userprofilepositions ON
GO
IF EXISTS(SELECT * FROM dbo.userprofilepositions)
	 EXEC('INSERT INTO dbo.Tmp_userprofilepositions (UserListingID, UserID, PositionID, LanguageID, CountryID, CreateDate, UpdatedDate, ModifiedBy, Active, PositionIntro, StatusID, CancellationPolicyID, additionalinfo1, additionalinfo2, additionalinfo3, InstantBooking, bookMeButtonReady, collectPaymentAtBookMeButton)
		SELECT UserListingID, UserID, PositionID, LanguageID, CountryID, CreateDate, UpdatedDate, ModifiedBy, Active, PositionIntro, StatusID, CancellationPolicyID, additionalinfo1, additionalinfo2, additionalinfo3, InstantBooking, bookMeButtonReady, collectPaymentAtBookMeButton FROM dbo.userprofilepositions WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_userprofilepositions OFF
GO
DROP TABLE dbo.userprofilepositions
GO
EXECUTE sp_rename N'dbo.Tmp_userprofilepositions', N'userprofilepositions', 'OBJECT' 
GO
ALTER TABLE dbo.userprofilepositions ADD CONSTRAINT
	PK_userprofilepositions PRIMARY KEY CLUSTERED 
	(
	UserListingID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
CREATE UNIQUE NONCLUSTERED INDEX IX_userprofilepositions ON dbo.userprofilepositions
	(
	UserID,
	PositionID,
	LanguageID,
	CountryID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE dbo.userprofilepositions ADD CONSTRAINT
	FK_userprofilepositions_users FOREIGN KEY
	(
	UserID
	) REFERENCES dbo.users
	(
	UserID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.userprofilepositions ADD CONSTRAINT
	FK_userprofilepositions_positions FOREIGN KEY
	(
	PositionID,
	LanguageID,
	CountryID
	) REFERENCES dbo.positions
	(
	PositionID,
	LanguageID,
	CountryID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.userprofilepositions ADD CONSTRAINT
	FK_userprofilepositions_accountstatus FOREIGN KEY
	(
	StatusID
	) REFERENCES dbo.accountstatus
	(
	AccountStatusID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Execute all user tests on insert
--  to active all the alerts
-- =============================================
CREATE TRIGGER trigInitialProviderPositionAlertTest
   ON  dbo.userprofilepositions
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @UserID int, @PositionID int
	
	SELECT @UserID = UserID, @PositionID = PositionID FROM INSERTED

    EXEC TestAllUserAlerts @UserID, @PositionID

END
GO
COMMIT
select Has_Perms_By_Name(N'dbo.userprofilepositions', 'Object', 'ALTER') as ALT_Per, Has_Perms_By_Name(N'dbo.userprofilepositions', 'Object', 'VIEW DEFINITION') as View_def_Per, Has_Perms_By_Name(N'dbo.userprofilepositions', 'Object', 'CONTROL') as Contr_Per 