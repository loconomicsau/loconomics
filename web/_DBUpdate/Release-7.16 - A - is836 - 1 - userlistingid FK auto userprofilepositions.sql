BEGIN TRY
	BEGIN TRANSACTION

	ALTER TABLE userprofilepositions
	ADD UserListingID [int] IDENTITY(1,1) NOT NULL
	;

	ALTER TABLE userprofilepositions
	DROP CONSTRAINT PK_userprofilepositions
	;

	ALTER TABLE userprofilepositions
	ADD CONSTRAINT [PK_userprofilepositions_userlistingid] PRIMARY KEY
	(UserListingID ASC)

	CREATE UNIQUE NONCLUSTERED INDEX [IX_userprofilepositions] ON [dbo].[userprofilepositions]
	(
		[UserID] ASC,
		[PositionID] ASC,
		[LanguageID] ASC,
		[CountryID] ASC
	)

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH
