SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'payment' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
ALTER PROCEDURE [dbo].[TestAlertPayment]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 5
	
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		
		/* Marketplace Way */
		EXISTS (
			SELECT	ProviderUserID
			FROM	ProviderPaymentAccount
			WHERE	ProviderUserID = @UserID
					 AND
					-- Braintree given status must be exactly 'active'
					[Status] like 'active'
		)
		
		/* OLD WAY:
		-- Check all required personal data
		EXISTS (
			SELECT ProviderUserID FROM ProviderPaymentPreference
			WHERE ProviderUserID = @UserID
				AND ProviderPaymentPreferenceTypeID is not null
				AND (
				 ProviderPaymentPreferenceTypeID <> 4
				  OR (
					dbo.fx_IfNW(AccountName, null) is not null
					AND dbo.fx_IfNW(ABANumber, null) is not null
					AND dbo.fx_IfNW(LastThreeAccountDigits, null) is not null
				  )
				)
		)*/
	BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID
END
