BEGIN TRY
	BEGIN TRANSACTION

	EXEC sp_rename 'userprofilepositions', 'userprofilepositions_OLD';

	CREATE TABLE [dbo].[userprofilepositions](
		[UserListingID] [int] IDENTITY(1,1) NOT NULL,
		[UserID] [int] NOT NULL,
		[PositionID] [int] NOT NULL,
		[LanguageID] [int] NOT NULL,
		[CountryID] [int] NOT NULL,
		[CreateDate] [datetime] NULL,
		[UpdatedDate] [datetime] NULL,
		[ModifiedBy] [varchar](3) NULL,
		[Active] [bit] NULL,
		[PositionIntro] [varchar](400) NULL,
		[StatusID] [int] NOT NULL,
		[CancellationPolicyID] [int] NULL,
		[additionalinfo1] [nvarchar](500) NULL,
		[additionalinfo2] [nvarchar](500) NULL,
		[additionalinfo3] [nvarchar](500) NULL,
		[InstantBooking] [bit] NOT NULL,
		[bookMeButtonReady] [bit] NOT NULL,
		[collectPaymentAtBookMeButton] [bit] NOT NULL
	CONSTRAINT [PK_userprofilepositions_userlistingid] PRIMARY KEY CLUSTERED
	(
		[UserListingID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	;

	CREATE UNIQUE NONCLUSTERED INDEX [IX_userprofilepositions] ON [dbo].[userprofilepositions]
	(
		[UserID] ASC,
		[PositionID] ASC,
		[LanguageID] ASC,
		[CountryID] ASC
	);

	INSERT INTO userprofilepositions (
		[UserID]
		,[PositionID]
		,[LanguageID]
		,[CountryID]
		,[CreateDate]
		,[UpdatedDate]
		,[ModifiedBy]
		,[Active]
		,[PositionIntro]
		,[StatusID]
		,[CancellationPolicyID]
		,[additionalinfo1]
		,[additionalinfo2]
		,[additionalinfo3]
		,[InstantBooking]
		,[bookMeButtonReady]
		,[collectPaymentAtBookMeButton]
	)
	SELECT [UserID]
		,[PositionID]
		,[LanguageID]
		,[CountryID]
		,[CreateDate]
		,[UpdatedDate]
		,[ModifiedBy]
		,[Active]
		,[PositionIntro]
		,[StatusID]
		,[CancellationPolicyID]
		,[additionalinfo1]
		,[additionalinfo2]
		,[additionalinfo3]
		,[InstantBooking]
		,[bookMeButtonReady]
		,[collectPaymentAtBookMeButton]
	FROM userprofilepositions_OLD

	IF OBJECT_ID('dbo.userprofilepositions_OLD', 'U') IS NOT NULL
	  DROP TABLE dbo.userprofilepositions_OLD

	COMMIT TRANSACTION
	PRINT 'DONE'
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
	PRINT 'FAILED'
	PRINT ERROR_MESSAGE()
END CATCH
