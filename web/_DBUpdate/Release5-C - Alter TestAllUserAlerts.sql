SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Execute all user alert tests and
-- the profile activation at the end.
-- =============================================
ALTER PROCEDURE [dbo].[TestAllUserAlerts] 
	@UserID int
	,@PositionID int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    EXEC TestAlertPersonalInfo				@UserID
    EXEC TestAlertPhoto						@UserID
    EXEC TestAlertPayment					@UserID
	--EXEC TestAlertTaxDocs					@UserID
	EXEC TestAlertAvailability				@UserID
	EXEC TestAlertSocialMediaVerification	@UserID
	EXEC TestAlertBackgroundCheck			@UserID
	EXEC TestAlertBasicInfoVerification		@UserID	
	EXEC TestAlertVerifyEmail				@UserID
	EXEC TestAlertPublicBio					@UserID
	EXEC TestAlertEducation					@UserID

	-- All positions alerts:
    IF @PositionID = 0 BEGIN
		DECLARE @cur CURSOR
		SET @cur = CURSOR FOR 
			SELECT DISTINCT
			 PositionID
			FROM
			 UserProfilePositions
			WHERE
		     UserID = @UserID
		     AND PositionID <> 0
			 
		OPEN @cur
		FETCH NEXT FROM @cur INTO @PositionID
		WHILE @@FETCH_STATUS = 0 BEGIN
			-- Same batch of test than when a positionid is provider by parameter:
			EXEC TestAlertPricingDetails		@UserID, @PositionID
			EXEC TestAlertPositionServices		@UserID, @PositionID
			EXEC TestAlertReferenceRequests		@UserID, @PositionID
			EXEC TestAlertProfessionalLicense	@UserID, @PositionID
			EXEC TestAlertLocation				@UserID, @PositionID
			EXEC TestAlertShowcaseWork			@UserID, @PositionID
			
			FETCH NEXT FROM @cur INTO @PositionID
		END
		CLOSE @cur
		DEALLOCATE @cur

    END ELSE BEGIN
		EXEC TestAlertPricingDetails		@UserID, @PositionID
		EXEC TestAlertPositionServices		@UserID, @PositionID
		EXEC TestAlertReferenceRequests		@UserID, @PositionID
		EXEC TestAlertProfessionalLicense	@UserID, @PositionID
		EXEC TestAlertLocation				@UserID, @PositionID
		EXEC TestAlertShowcaseWork			@UserID, @PositionID
    END
    
    EXEC TestProfileActivation @UserID, @PositionID
END
