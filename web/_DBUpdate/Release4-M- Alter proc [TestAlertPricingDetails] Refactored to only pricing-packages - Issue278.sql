/****** Object:  StoredProcedure [dbo].[TestAlertPricingDetails]    Script Date: 07/31/2013 13:46:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'pricingdetails' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
ALTER PROCEDURE [dbo].[TestAlertPricingDetails]
	@UserID int,
	@PositionID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 1
    
    -- First ever check if this type of alert affects this type of user
    IF	dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		-- Check that user has that position (this is a position related alert). If it has not (=0), alert will off because doesn't affect:
		(SELECT count(*) FROM userprofilepositions WHERE UserID=@UserID AND PositionID=@PositionID) = 0 OR
		
		-- Check that there are almost one pricing package defined
		EXISTS (SELECT * FROM ProviderPackage
			WHERE ProviderUserID = @UserID
				AND PositionID = @PositionID
				AND Active = 1
		)
	
		BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID, @PositionID
END

