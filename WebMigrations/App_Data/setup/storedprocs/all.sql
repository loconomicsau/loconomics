/****** Object:  StoredProcedure [dbo].[CheckUserEmail]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CheckUserEmail]
	-- Add the parameters for the stored procedure here
	@Email nvarchar(56)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT Email FROM UserProfile WHERE LOWER(Email) = LOWER(@Email)
    
    
    
    
    
END

GO
/****** Object:  StoredProcedure [dbo].[CreateCustomer]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 16/04/2012
-- Description:	Create a Loconomics User as
-- only Customer profile and minimum information
-- (from the Register page or Facebook Login).
-- =============================================
CREATE PROCEDURE [dbo].[CreateCustomer]
	-- Add the parameters for the stored procedure here
	
		@UserID int,
		@Firstname varchar(45),
        @Lastname varchar(145),
		@Lang int,
		@CountryId int,
        @GenderID int = -1,
		@PublicBio varchar(500) = null,
		@Phone varchar(20) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    INSERT INTO dbo.users (
		UserID,
		FirstName,
		LastName,
		MiddleIn,
		SecondLastName,
		GenderID,
		PreferredLanguageID,
		PreferredCountryID,
		PublicBio,
		IsProvider,
		IsCustomer,
		IsAdmin,
		IsCollaborator,
		MobilePhone,
		CanReceiveSms,
		SMSBookingCommunication,
		PhoneBookingCommunication,
		LoconomicsMarketingCampaigns,
		ProfileSEOPermission,
		CreatedDate,
		UpdatedDate,
		ModifiedBy,
		Active,
		LoconomicsCommunityCommunication,
		LoconomicsDBMCampaigns,
		AccountStatusID,
		CoBrandedPartnerPermissions,
		IsHipaaAdmin,
		TrialEndDate
	) VALUES (
		@UserID,
		@Firstname,
		@Lastname,
		'',
		'',
		coalesce(@GenderID, -1),
		@Lang,
		@CountryId,
		@PublicBio,
		0,
		1,
		0,
		0,
		@Phone,
		0,
		0,
		0,
		0,
		0,
		GETDATE(),
		GETDATE(),
		'SYS',
		1,
		0,
		0,
		1,
		0,
		0,
		DATEADD(DAY, 14, SYSDATETIMEOFFSET())
	)
	
	-- Check alerts for the user to get its state updated
	EXEC TestAllUserAlerts @UserID
END


GO
/****** Object:  StoredProcedure [dbo].[CreateProviderFromUser]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-03
-- Description:	Converts an existing user 
-- (a customer) into a provider, allowing
-- update some user data and setting needed
-- provider fields as in CreateProvider proc.
-- =============================================
CREATE PROCEDURE [dbo].[CreateProviderFromUser] (
	@UserID int,
	@Firstname varchar(45),
    @Lastname varchar(145),
    @PostalCodeID int,
    @StateProvinceID int,
    @LangID int,
    @CountryID int,
    @emailcontact bit,
    @BookCode varchar(64)
) AS BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE Users SET
		FirstName = coalesce(@FirstName, FirstName),
		LastName = coalesce(@LastName, LastName),
		PreferredLanguageID = coalesce(@LangID, PreferredLanguageID),
		PreferredCountryID = coalesce(@CountryID, PreferredCountryID),
		BookCode = @BookCode,
		IsProvider = 1,
		-- This proc is used most of time by providers registered from facebook, or users
		-- that start using the normal register form and then continues with the provider-sign-up,
		-- but only wants be providers: here we update the IsCustomer field based on if user
		-- have activity as customer of not (if it have bookingrequests, is customer, else
		-- only provider)
		IsCustomer = (CASE WHEN (
			SELECT	count(*)
			FROM	BookingRequest
			WHERE	BookingRequest.CustomerUserID = @UserID
		) = 0 THEN Cast(0 As bit) ELSE Cast(1 As bit) END),
		UpdatedDate = getdate(),
		ModifiedBy = 'sys',
		Active = 1
	WHERE	UserID = @UserID
	
	-- Set the address
	EXEC SetHomeAddress @UserID, '', '', '', @StateProvinceID, @PostalCodeID, @CountryID, @LangID
	
	-- Check alerts for the user to get its state updated
	EXEC TestAllUserAlerts @UserID
END

GO
/****** Object:  StoredProcedure [dbo].[DeleteBookingRequest]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-12-28
-- Description:	Allow fully remove a Booking 
-- Request and related records created for it
-- based on our general rules for booking 
-- invalidation and removing all.
-- This MUST NOT be used normally, only because
-- errors on system, corrupt bookings or testing
-- IMPORTANT: Procedure cannot Refund or Void
-- the Braintree transaction, the booking
-- TransactionID is returned to do it manually,
-- or use the app method LcData.Booking.InvalidateBookingRequest
-- previous deletion to ensure is done auto.
-- =============================================
CREATE PROCEDURE [dbo].[DeleteBookingRequest]
	@BookingRequestID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @invalidOk int
	DECLARE @tranID varchar(250)
	DECLARE @returnMessage varchar(1000)
	
	-- Invalidate the booking request with the general procedure, with a temporary
	-- 'timed out' status, this ensure all related records not need are removed
	-- and all remains clean.
	EXEC @invalidOk = dbo.InvalidateBookingRequest @BookingRequestID, 3

	IF @invalidOk = 0 BEGIN
		-- Get TransactionID to be returned later
		SELECT	@tranID = coalesce(PaymentTransactionID, '__THERE IS NO TRANSACTION__')
		FROM	bookingrequest
		WHERE	BookingRequestID = @BookingRequestID

		-- Remove the request
		DELETE FROM bookingrequest WHERE BookingRequestID = @BookingRequestID
		
		SET @returnMessage = 'Braintree cannot be Refunded or Void from here, do it manually for the next TransactionID if is not a Test: ' + @tranID
	END ELSE
		SET @returnMessage = 'Not deleted, could not be Invalidated becuase error number: ' + Cast(coalesce(@invalidOk, -1) as varchar)

	SELECT @returnMessage As [Message]
	PRINT @returnMessage
END

GO
/****** Object:  StoredProcedure [dbo].[DeleteUser]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/* CAUTION!
 * Delete all data from an user
 * account
 * TODO: need be update with all
 * the tables (calendar, pricing, etc.)
 */
-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 17/04/2012
-- Description:	Delete all data from an user
-- account
-- TODO: need be update with all
-- the tables (calendar, pricing, etc.)
-- =============================================
CREATE PROCEDURE [dbo].[DeleteUser]
	(
	@UserId int
	)
AS
	SET NOCOUNT ON
	
DELETE PPD 
FROM providerpackagedetail PPD
INNER JOIN providerpackage PP
ON PP.ProviderPackageID = PPD.ProviderPackageID
AND (PP.ProviderUserID = @UserId OR PP.visibleToClientID = @UserId)

DELETE
FROM providerpackage
WHERE ProviderUserID = @UserId OR VisibleToClientID = @UserId

delete
FROM	CalendarProviderAttributes
WHERE userid = @UserID

delete
FROM			UserAlert
WHERE userid = @UserID

delete
FROM            UserLicenseCertifications
where provideruserid =  @UserId

delete
from	userstats
where userid = @userid

delete
from userbackgroundcheck
where userid = @userid

delete
from	serviceaddress
where addressid IN (
	select addressid
	from [address]
	where userid = @userid
)

delete
from	address
where userid = @userid

delete
from			booking
where clientuserid = @userid or serviceprofessionaluserid = @userid

delete
from			ServiceProfessionalClient
where clientuserid = @userid or serviceprofessionaluserid = @userid

delete
from			[messages]
where threadid IN (
	select threadid
	from messagingthreads
	where customeruserid = @userid or provideruserid = @userid
)

delete
FROM            messagingthreads
where provideruserid =  @UserId OR customeruserid = @UserID

delete
FROM            providerpaymentpreference
where provideruserid =  @UserId

delete
FROM            usereducation
where userid =  @UserId

delete
FROM            userreviews
where provideruserid =  @UserId OR customeruserId = @UserId

delete
FROM            providertaxform
where provideruserid =  @UserId

delete
FROM            userverification
where userid =  @UserId

delete
FROM            userprofileserviceattributes
where userid =  @UserId

delete
FROM            userprofilepositions
where userid =  @UserId

delete
FROM            userprofile
where userid =  @UserId

delete
FROM            users
where userid = @UserId

delete
FROM            webpages_usersinroles
where userid =  @UserId

delete
FROM            webpages_oauthmembership
where userid =  @UserId

delete
FROM            webpages_membership
where userid = @UserId

delete
FROM            webpages_facebookcredentials
where userid = @UserId



GO
/****** Object:  StoredProcedure [dbo].[DeleteUserPosition]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteUserPosition] (
	@UserID int,
	@PositionID int
) AS BEGIN

delete from [ServiceAttributeLanguageLevel]
where userid = @UserID AND PositionID = @PositionID

delete from ServiceAttributeExperienceLevel
where userid = @UserID AND PositionID = @PositionID

delete from userprofileserviceattributes
where userid = @UserID AND PositionID = @PositionID

delete from userprofilepositions
where userid = @UserID AND PositionID = @PositionID

END

GO
/****** Object:  StoredProcedure [dbo].[DelUserVerification]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2013-07-15
-- Description:	Delete a user-verification
-- record, if there is one.
-- =============================================
CREATE PROCEDURE [dbo].[DelUserVerification]
	@UserID int,
	@VerificationID int,
    @PositionID int = 0
AS
BEGIN
	DELETE FROM userverification
	WHERE UserID = @UserID
		AND VerificationID = @VerificationID
        AND PositionID = @PositionID
END

GO
/****** Object:  StoredProcedure [dbo].[GetPosition]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPosition]
	-- Add the parameters for the stored procedure here
	
	@PositionID int,
	@LanguageID int = 1,
	@CountryID int = 1

-- exec getuserprofile 2,14

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
			SELECT 
				PositionSingular,
				PositionDescription
			FROM dbo.positions b
			WHERE b.PositionID = @PositionID
			and b.LanguageID = @LanguageID
			and b.CountryID = @CountryID

END

GO
/****** Object:  StoredProcedure [dbo].[GetSearchResults]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetSearchResults]
@LanguageID int, @CountryID int, @SearchTerm varchar(300), @SubCategory varchar(300)
 WITH EXEC AS CALLER
AS

--EXEC dbo.GetSearchResults 1,1,'%',''

IF @SubCategory <> ''
BEGIN
	DECLARE @ServiceCategoryID AS INT

	SELECT @ServiceCategoryID = ServiceCategoryID 
	FROM servicecategory 
	WHERE Name = @SubCategory 
		AND LanguageID = @LanguageID 
		AND CountryID = @CountryID

	SELECT 
		d.UserID
		,d.FirstName
		,d.LastName
		,a.PositionID
		,c.PositionSingular
		,a.UpdatedDate
		,Positions=STUFF((SELECT ', ' + PositionSingular FROM Positions As P0 INNER JOIN UserProfilePositions As UP0 ON P0.PositionID = UP0.PositionID WHERE UP0.UserID = D.UserID AND P0.LanguageID = @LanguageID AND P0.CountryID = @CountryID FOR XML PATH('')) , 1 , 1 , '' )
		,S.Name as ServiceName 
	FROM dbo.users d 
	JOIN dbo.userprofilepositions a 
		ON d.UserID = a.UserID 
	JOIN  positions c 
		ON a.PositionID = c.PositionID
		AND a.LanguageID = c.LanguageID
		AND a.CountryID = c.CountryID
	JOIN dbo.servicecategoryposition SCP
		ON C.PositionID = SCP.PositionID
		AND a.LanguageID = SCP.LanguageID
		AND a.CountryID = SCP.CountryID
	JOIN dbo.servicecategory S
		ON SCP.ServiceCategoryID = S.ServiceCategoryID
		AND a.LanguageID = S.LanguageID
		AND a.CountryID = S.CountryID
	WHERE S.ServiceCategoryID = @ServiceCategoryID
		AND a.LanguageID = @LanguageID and a.CountryID = @CountryID
		AND d.Active = 1
		AND a.Active = 1
		AND a.StatusID = 1
		AND c.Active = 1
		AND s.Active = 1
		AND scp.Active = 1
		AND (
			@SearchTerm like ''
			 OR
			c.PositionSingular like @SearchTerm
			 OR
			c.PositionPlural like @SearchTerm
			 OR
			c.PositionDescription like @SearchTerm
			 OR
			c.Aliases like @SearchTerm
			 OR
			c.GovPosition like @SearchTerm
			 OR
			c.GovPositionDescription like @SearchTerm
		)
END

ELSE --IF @SearchTerm <> '%'
BEGIN
	SELECT 
		d.UserID
		,d.FirstName
		,d.LastName
		,a.PositionID
		,c.PositionSingular
		,a.UpdatedDate
		,Positions=STUFF((SELECT ', ' + PositionSingular FROM Positions As P0 INNER JOIN UserProfilePositions As UP0 ON P0.PositionID = UP0.PositionID WHERE UP0.UserID = D.UserID AND P0.LanguageID = @LanguageID AND P0.CountryID = @CountryID FOR XML PATH('')) , 1 , 1 , '' )
		--,rs.Rating1
		--,rs.Rating2
		--,rs.Rating3
		--,rs.Rating4 
	FROM dbo.users d 
	JOIN dbo.userprofilepositions a 
		ON d.UserID = a.UserID 
	JOIN  positions c 
		ON a.PositionID = c.PositionID 
		AND a.LanguageID = c.LanguageID
		AND a.CountryID = c.CountryID
	--LEFT JOIN dbo.UserReviewScores rs ON (d.UserID = rs.UserID)
	WHERE
		a.LanguageID = @LanguageID
		AND a.CountryID = @CountryID
		AND d.Active = 1
		AND a.Active = 1
		AND c.Active = 1
		AND (
			c.PositionSingular like @SearchTerm
			 OR
			c.PositionPlural like @SearchTerm
			 OR
			c.PositionDescription like @SearchTerm
			 OR
			c.Aliases like @SearchTerm
			 OR
			c.GovPosition like @SearchTerm
			 OR
			c.GovPositionDescription like @SearchTerm
			 OR
			a.PositionIntro like @SearchTerm
			 OR
			EXISTS (
				SELECT *
				FROM	UserProfileServiceAttributes As UA
						 INNER JOIN
						ServiceAttribute As SA
						  ON UA.ServiceAttributeID = SA.ServiceAttributeID
							AND UA.Active = 1
							AND SA.Active = 1
							AND SA.LanguageID = UA.LanguageID
							AND SA.CountryID = UA.CountryID
				WHERE
						UA.UserID = a.UserID
						AND UA.PositionID = a.PositionID
						AND UA.LanguageID = @LanguageID
						AND UA.CountryID = @CountryID
						AND (
						 SA.Name like @SearchTerm
						  OR
						 SA.ServiceAttributeDescription like @SearchTerm
						)
			)
		)
END

GO
/****** Object:  StoredProcedure [dbo].[GetServiceAttributeCategories]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetServiceAttributeCategories]
	-- Add the parameters for the stored procedure here

	@PositionID int,
	@LanguageID int = 1,
	@CountryID int = 1,
	@OnlyBookingPathSelection bit = 0

-- exec GetServiceAttributeCategories 14,1,1

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	   SELECT DISTINCT
	   a.DisplayRank,
	   a.ServiceAttributeCategoryID,
	   a.ServiceAttributeCategory as ServiceCat,
	   a.ServiceAttributeCategoryDescription,
	   a.RequiredInput,
	   a.SideBarCategory
	   FROM serviceattributecategory a
	   join servicecategorypositionattribute c
	   on a.ServiceAttributeCategoryID = c.ServiceAttributeCategoryID
	   and a.LanguageID = c.LanguageID
	   and a.CountryID = c.CountryID
	   WHERE  c.PositionID = @PositionID
	   and c.LanguageID  = @LanguageID
	   and c.CountryID = @CountryID
	   and (a.PricingOptionCategory is null OR a.PricingOptionCategory = 1)
	   -- only actived
	   and a.Active = 1
	   and c.Active = 1
	   -- booking path selection
	   and (@OnlyBookingPathSelection = 0 OR BookingPathSelection = 1)
	   ORDER BY a.DisplayRank ASC, a.ServiceAttributeCategory ASC
	   
	


END

GO
/****** Object:  StoredProcedure [dbo].[GetServiceAttributes]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetServiceAttributes]
	-- Add the parameters for the stored procedure here

	@PositionID int,
	-- CategoryID can be Zero (0) to retrieve all attributes without regarding the category
	@ServiceAttributeCategoryID int,
	@LanguageID int = 1,
	@CountryID int = 1,
	@UserID int = 0,
	@OnlyUserChecked bit = 0

-- exec GetServiceAttributes 14,2,1,1

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		  SELECT 
		  se.ServiceAttributeCategoryID, 
		  se.ServiceAttributeCategory as ServiceCat,
		  s.ServiceAttributeDescription,
		  s.ServiceAttributeID, 
		  s.Name as ServiceAttribute,
		  
		  -- iagosrl: added UserChecked to know if is an attribute
		  -- assigned to the @UserID
		  (case when @UserID <= 0 OR us.UserID is null then cast(0 as bit)
				else cast(1 as bit)
		  end) as UserChecked
		  ,coalesce(se.EligibleForPackages, cast(0 as bit)) As EligibleForPackages
		  
		  from servicecategorypositionattribute d
		  join serviceattribute s 
		  on d.ServiceAttributeID = s.ServiceAttributeID 
		  join serviceattributecategory se 
		  on d.ServiceAttributeCategoryID = se.ServiceAttributeCategoryID 
		  and d.LanguageID = se.LanguageID
		  and d.CountryID = se.CountryID
		  and se.LanguageID = s.LanguageID
		  and se.CountryID = s.CountryID
		  
		  -- iagosrl: I added param @UserID to optionally (left join) get
		  --  attributes selected by the user, not filtering else adding a
		  --  new result field 'UserChecked' as true/false
		  left join userprofileserviceattributes as us
		  on d.ServiceAttributeID = us.ServiceAttributeID
		  and d.ServiceAttributeCategoryID = us.ServiceAttributeCategoryID
		  and d.PositionID = us.PositionID
		  and d.LanguageID = us.LanguageID
		  and d.CountryID = us.CountryID
		  and us.Active = 1
		  and us.UserID = @UserID
		  
		  WHERE  d.PositionID = @PositionID  
		  -- iagosrl: 2012-07-20, added the possibility of value Zero of CategoryID parameter to retrieve position attributes from all position-mapped categories
		  and (@ServiceAttributeCategoryID = 0 OR d.ServiceAttributeCategoryID = @ServiceAttributeCategoryID)
		  and d.LanguageID  = @LanguageID
		  and d.CountryID = @CountryID
		  -- only actived
		  and d.Active = 1
		  and se.Active = 1
		  and s.Active = 1
		  and (@OnlyUserChecked = 0 OR us.UserID > 0)
		  ORDER BY s.DisplayRank ASC, s.Name ASC

END

GO
/****** Object:  StoredProcedure [dbo].[GetUserCalendarProviderAttributes]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetUserCalendarProviderAttributes]

@UserID int


as

SELECT AdvanceTime,MinTime,MaxTime,BetweenTime,UseCalendarProgram,CalendarType,CalendarURL, PrivateCalendarToken, IncrementsSizeInMinutes
FROM CalendarProviderAttributes
WHERE UserID = @UserID

GO
/****** Object:  StoredProcedure [dbo].[GetUserDetails]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE PROC [dbo].[GetUserDetails]

@UserID int


as




select 

FirstName, 
LastName,
SecondLastName,
MiddleIn,
PostalCode,
Photo,
PreferredLanguageID,
PreferredCountryID,
ADD_Details 
from users a 
join dbo.userprofilepositionadditional b 
on a.userid = b.userid  where a.UserID = @UserID

GO
/****** Object:  StoredProcedure [dbo].[GetUserProfile]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetUserProfile]
	-- Add the parameters for the stored procedure here
	@UserID int,
	@PositionID int,
	@LanguageID int = 1,
	@CountryID int = 1

-- exec getuserprofile 2,14

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
			SELECT 
			FirstName + ' ' + LastName as ProviderName,
			PostalCode,
			Photo,
			PreferredLanguageID,
			PreferredCountryID,
			ADD_Details 
			FROM users a 
			JOIN dbo.userprofilepositionadditional b 
			ON a.userid = b.userid  
			WHERE a.UserID = @UserID
			and b.PositionID = @PositionID
			and b.LanguageID = @LanguageID
			and b.CountryID = @CountryID

END

GO
/****** Object:  StoredProcedure [dbo].[InsertUserProfilePositions]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[InsertUserProfilePositions]

@UserID int,
@PositionID int,
@LanguageID int,
@CountryID int,
@CancellationPolicyID int,
@Intro varchar(400) = '',
@InstantBooking bit = 0,
@collectPaymentAtBookMeButton bit = 0

AS

DECLARE @ResultMessage varchar(50)

BEGIN TRY

	INSERT INTO userprofilepositions (
		UserID, PositionID, LanguageID, CountryID, CreateDate, UpdatedDate, ModifiedBy, Active, StatusID, PositionIntro, CancellationPolicyID, InstantBooking,
		collectPaymentAtBookMeButton
	) VALUES(
		@UserID,@PositionID,@LanguageID,@CountryID, GETDATE(), GETDATE(), 'sys', 1, 2, @Intro, @CancellationPolicyID, @InstantBooking,
		@collectPaymentAtBookMeButton
	)
	
	-- Check alerts for the position to get its state updated
	EXEC TestAllUserAlerts @UserID, @PositionID

	SELECT  'Success' as Result

END TRY

BEGIN CATCH

 SET @ResultMessage =  ERROR_MESSAGE();

IF @ResultMessage like 'Violation of PRIMARY KEY%'
 
BEGIN

	-- SELECT 'You already have this position loaded' as Result

	IF EXISTS (SELECT * FROM UserProfilePositions WHERE
		UserID = @UserID AND PositionID = @PositionID
		AND LanguageID = @LanguageID AND CountryID = @CountryID
		AND Active = 0) BEGIN
		
		SELECT 'Position could not be added' As Result
		
	END ELSE BEGIN
	
		-- Enable this position and continue, no error
		UPDATE UserProfilePositions
		SET StatusID = 2
			,UpdatedDate = GETDATE()
			,ModifiedBy = 'sys'
			,PositionIntro = @Intro
			,CancellationPolicyID = @CancellationPolicyID
			,InstantBooking = @InstantBooking
			,collectPaymentAtBookMeButton = @collectPaymentAtBookMeButton
		WHERE 
			UserID = @UserID AND PositionID = @PositionID
			AND LanguageID = @LanguageID AND CountryID = @CountryID
			
		-- Check alerts for the position to get its state updated
		EXEC TestAllUserAlerts @UserID, @PositionID

		SELECT  'Success' as Result
	END
END

ELSE
BEGIN

	SELECT 'Sorry, it appears we have an error: ' + @ResultMessage as Result
	
END

END CATCH
 
 


GO
/****** Object:  StoredProcedure [dbo].[ListPositions]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE PROC [dbo].[ListPositions]

@LanguageID int = 1,
@CountryID int  = 1

as



select  
a.positionid,  
a.PositionSingular  as position  
from positions a 
where a.LanguageID = @LanguageID and a.CountryID = @CountryID
and a.PositionSingular is not null
order by 2 asc

GO
/****** Object:  StoredProcedure [dbo].[SearchCategories]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE PROC [dbo].[SearchCategories]

@LanguageID int = 1,
@CountryID int  = 1,
@ServiceCategoryID int = 1
as

--exec [dbo].[SearchCategories]

select  
ServiceSubCategoryID,
Name,
Rank as ServiceRank
from dbo.servicesubcategory
where LanguageID = @LanguageID and CountryID = @CountryID
and ServiceCategoryID = @ServiceCategoryID
and rank <=5



--b.positionid,  
--a.PositionSingular  as position  
--from positions a join servicecategoryposition  b   
--on a.positionid = b.positionid  
--join servicesubcategory c  on b.ServiceSubCategoryID = c.ServiceSubCategoryID    
--where a.LanguageID = @LanguageID and a.CountryID = @CountryID

GO
/****** Object:  StoredProcedure [dbo].[SearchCategoriesPositions]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SearchCategoriesPositions]

@LanguageID int = 1,
@CountryID int  = 1,
@ServiceCategoryID int = 1,
@ServiceSubCategoryID int = 1
as

--exec [dbo].[SearchCategoriesPositions] 1,1

-- Need a rank attribute for each user position for preferred provider

SELECT  
c.ServiceSubCategoryID,
c.Name,
c.Rank as ServiceRank,
b.positionid,  
a.PositionSingular  as position,
tpur.PrivateReview,
tpur.PublicReview, 
tpur.Rating1,
tpur.Rating2,
tpur.Rating3,
MIN(up.UserID),
COUNT(DISTINCT BookingID) AS ReviewCount,
0 as VerificationsCount,
0 as LicensesCount

FROM  positions a 

LEFT JOIN servicecategoryposition  b   
  ON a.positionid = b.positionid  

LEFT JOIN servicesubcategory c  
  ON b.ServiceCategoryID = c.ServiceCategoryID  

LEFT JOIN dbo.userprofilepositions up
  ON a.positionid = up.PositionID
  AND a.LanguageID = up.LanguageID
  AND a.CountryID = up.CountryID

LEFT JOIN UserReviews ur
  ON a.PositionID = ur.PositionID
  AND up.UserID = ur.ProviderUserID

LEFT JOIN (SELECT TOP 1 ProviderUserID,
                        PositionID,
                        PrivateReview,
                        PublicReview ,
                        Rating1,
                        Rating2,
                        Rating3
           FROM dbo.UserReviews ORDER BY CreatedDate) tpur
           
on ur.PositionID = tpur.PositionID 
and ur.ProviderUserID = tpur.ProviderUserID

WHERE a.LanguageID = @LanguageID and a.CountryID = @CountryID
and c.ServiceCategoryID = @ServiceCategoryID
and c.ServiceSubCategoryID = @ServiceSubCategoryID
and c.rank <=5
GROUP BY c.ServiceSubCategoryID,
c.Name,
c.Rank,
b.positionid,  
a.PositionSingular,
tpur.PrivateReview,
tpur.PublicReview, 
tpur.Rating1,
tpur.Rating2,
tpur.Rating3


GO
/****** Object:  StoredProcedure [dbo].[SearchPositions]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SearchPositions]
/*
Highlight and execute the following statement to drop the procedure
before executing the create statement.

DROP PROCEDURE dbo.SearchPositions;

*/

-- =============================================
-- Author:      <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
-- =============================================
    -- Add the parameters for the stored procedure here
    @SearchTerm varchar(150),
    @LanguageID int = 1,
    @CountryID int = 1

--exec dbo.GetPositions '%Cleaner%',1,1

AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
    SELECT DISTINCT 
        c.PositionSingular, c.PositionID, c.PositionDescription
    FROM positions c
    WHERE  
        c.LanguageID = @LanguageID 
        AND c.CountryID = @CountryID
        AND c.Active = 1
        AND (c.Approved = 1 Or c.Approved is null) -- Avoid not approved, allowing pending (null) and approved (1)
        AND dbo.fx_IfNW(c.PositionSingular, null) is not null
        AND (
            c.PositionSingular like @SearchTerm
             OR
            c.PositionPlural like @SearchTerm
             OR
            c.PositionDescription like @SearchTerm
             OR
            c.Aliases like @SearchTerm
             OR
            c.GovPosition like @SearchTerm
             OR
            c.GovPositionDescription like @SearchTerm
             OR
            EXISTS (
                SELECT *
                FROM    ServiceCategoryPositionAttribute As SP
                         INNER JOIN
                        ServiceAttribute As SA
                          ON SP.ServiceAttributeID = SA.ServiceAttributeID
                            AND SP.Active = 1
                            AND SA.Active = 1
                            AND SA.LanguageID = SP.LanguageID
                            AND SA.CountryID = SP.CountryID
                WHERE
                        SP.PositionID = c.PositionID
                        AND SA.LanguageID = @LanguageID
                        AND SA.CountryID = @CountryID
                        AND (
                         SA.Name like @SearchTerm
                          OR
                         SA.ServiceAttributeDescription like @SearchTerm
                        )
            )
        )

    ORDER BY PositionSingular
END

GO
/****** Object:  StoredProcedure [dbo].[SearchPositionsByCategory]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2013-01-03
-- Description:	Get the list of positions 
-- inside the CategoryID given, for categorized
-- search results page
-- =============================================
CREATE PROCEDURE [dbo].[SearchPositionsByCategory]
	@LanguageID int
	,@CountryID int
	,@Category nvarchar(400)
	,@City nvarchar(400)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @ServiceCategoryID AS INT
	SELECT @ServiceCategoryID = ServiceCategoryID 
	FROM servicecategory 
	WHERE Name = @Category
		AND LanguageID = @LanguageID 
		AND CountryID = @CountryID

    SELECT	P.PositionID as jobTitleID
			,P.PositionPlural as pluralName
			,P.PositionSingular as singularName
			,P.PositionDescription as description
			,P.PositionSearchDescription as searchDescription

			,coalesce((SELECT
				avg( (coalesce(UR2.Rating1, 0) + coalesce(UR2.Rating2, 0) + coalesce(UR2.Rating3, 0)) / 3) As AVR
			  FROM UserReviews As UR2
				INNER JOIN
				  UserProfilePositions As UP2
				  ON UP2.PositionID = UR2.PositionID
				    AND UR2.ProviderUserID = UP2.UserID
					AND UP2.LanguageID = @LanguageID
					AND UP2.CountryID = @CountryID
					AND UP2.Active = 1
					AND UP2.StatusID = 1
			  WHERE UR2.PositionID = P.PositionID
			), 0) As averageRating
			
			,coalesce(sum(ur.TotalRatings), 0) As totalRatings
			,avg(US.ResponseTimeMinutes) As averageResponseTimeMinutes
			,avg(PHR.HourlyRate) As averageHourlyRate
			,count(UP.UserID) As serviceProfessionalsCount
			
	FROM	Positions As P
			 INNER JOIN
			ServiceCategoryPosition As SCP
			  ON P.PositionID = SCP.PositionID
				AND P.LanguageID = SCP.LanguageID
				AND P.CountryID = SCP.CountryID
				
			 LEFT JOIN
			UserProfilePositions As UP
			  ON UP.PositionID = P.PositionID
			    AND UP.LanguageID = P.LanguageID
			    AND UP.CountryID = P.CountryID
			    AND UP.Active = 1
			    AND UP.StatusID = 1
			 LEFT JOIN
			UserReviewScores AS UR
			  ON UR.UserID = UP.UserID
				AND UR.PositionID = UP.PositionID
			 LEFT JOIN
			UserStats As US
			  ON US.UserID = UP.UserID
			 LEFT JOIN
			(SELECT	ProviderPackage.ProviderUserID As UserID
					,ProviderPackage.PositionID
					,min(PriceRate) As HourlyRate
					,LanguageID
					,CountryID
			 FROM	ProviderPackage
			 WHERE	ProviderPackage.Active = 1
					AND ProviderPackage.PriceRateUnit like 'HOUR' 
					AND ProviderPackage.PriceRate > 0
			 GROUP BY	ProviderPackage.ProviderUserID, ProviderPackage.PositionID
						,LanguageID, CountryID
			) As PHR
			  ON PHR.UserID = UP.UserID
			    AND PHR.PositionID = UP.PositionID
				AND PHR.LanguageID = P.LanguageID
				AND PHR.CountryID = P.CountryID
	WHERE
			SCP.ServiceCategoryID = @ServiceCategoryID
			 AND
			SCP.Active = 1
			 AND
			P.Active = 1
			 AND
			P.LanguageID = @LanguageID
			 AND
			P.CountryID = @CountryID
	GROUP BY P.PositionID, P.PositionPlural, P.PositionSingular, P.PositionDescription, P.PositionSearchDescription, P.DisplayRank
	ORDER BY serviceProfessionalsCount DESC, P.DisplayRank, P.PositionPlural
END

GO
/****** Object:  StoredProcedure [dbo].[SearchProvidersByPositionSingular]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SearchProvidersByPositionSingular]
@LanguageID int,
@CountryID int,
@PositionSingular varchar(300),
@City nvarchar(400)
 WITH EXEC AS CALLER
AS

--EXEC dbo.SearchProvidersByPositionSingular 1,1,'Cleaner', 'San Francisco'

	SELECT 
		d.userID
		,d.firstName
		,d.lastName
		,d.secondLastName
		,d.businessName
		,a.PositionID As jobTitleID
		--,c.PositionSingular
		--,a.UpdatedDate
		,jobTitles=STUFF((SELECT ', ' + PositionSingular FROM Positions As P0 INNER JOIN UserProfilePositions As UP0 ON P0.PositionID = UP0.PositionID WHERE UP0.UserID = D.UserID AND P0.LanguageID = @LanguageID AND P0.CountryID = @CountryID AND UP0.StatusID = 1 AND UP0.Active = 1 AND P0.Active = 1 AND P0.Approved <> 0 FOR XML PATH('')) , 1 , 1 , '' )
		--,rs.Rating1
		--,rs.Rating2
		--,rs.Rating3
		--,rs.Rating4 
	FROM dbo.users d 
	JOIN dbo.userprofilepositions a 
		ON d.UserID = a.UserID 
	JOIN  positions c 
		ON a.PositionID = c.PositionID 
		AND a.LanguageID = c.LanguageID
		AND a.CountryID = c.CountryID
	--LEFT JOIN dbo.UserReviewScores rs ON (d.UserID = rs.UserID)
	WHERE
		a.LanguageID = @LanguageID
		AND a.CountryID = @CountryID
		AND d.Active = 1
		AND a.Active = 1
		AND a.StatusID = 1
		AND c.Active = 1
		AND c.PositionSingular like @PositionSingular

GO
/****** Object:  StoredProcedure [dbo].[SearchTopProvidersByPosition]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro	
-- Create date: 2013-01-07
-- Description:	Get a short list of providers
-- in the specific position for the search page
-- results. List is limited to the top most
-- rated providers.
-- Minimum information is returned, not full
-- user information.
-- =============================================
CREATE PROCEDURE [dbo].[SearchTopProvidersByPosition]
	@LanguageID int,
	@CountryID int,
	@PositionID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT TOP 8 UserID
		,FirstName
		--, Rating -- returning Rating for testing only
	FROM (

		SELECT	UP.UserID
				,U.FirstName
				,((coalesce(Rating1, 0) + coalesce(Rating2, 0) + coalesce(Rating3, 0)) / 3) As Rating
		FROM	Users As U
				 INNER JOIN
				UserProfilePositions As UP
				  ON UP.UserID = U.UserID
				 LEFT JOIN
				UserReviewScores AS UR
				  ON UR.UserID = UP.UserID
					AND UR.PositionID = UP.PositionID
		WHERE
				U.Active = 1
				 AND
				UP.PositionID = @PositionID
				 AND
				UP.Active = 1
				 AND
				UP.StatusID = 1
				 AND
				UP.LanguageID = @LanguageID
				 AND
				UP.CountryID = @CountryID
	) As T
	-- The top best rated providers:
	ORDER BY Rating DESC 

END

GO
/****** Object:  StoredProcedure [dbo].[SetCalendarProviderAttributes]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2014-02-12
-- Description:	It sets (insert or update) the
-- given calendar attributes for the provider,
-- each field is optional to be set, if null is
-- given, current db value is preserved.
--
-- NOTE: minTime and maxTime fields are being 
-- gradually removed, firstly from user use and 
-- later totally from code and db #279.
-- This proc doesn't provide way to set both of
-- that since code is not using it already.
-- NOTE: with standard iCal support, fields
-- UseCalendarProgram and CalendarType gets
-- unused, with fixed values of 1 and ''.
-- =============================================
CREATE PROC [dbo].[SetCalendarProviderAttributes] (
	@UserID int,
	@AdvanceTime decimal(10, 2),
	@BetweenTime decimal(10, 2),
	@CalendarURL varchar(500),
	@PrivateCalendarToken varchar(128),
	@IncrementsSizeInMinutes int = null
) AS BEGIN

	IF EXISTS (SELECT * FROM CalendarProviderAttributes WHERE UserID = @UserID)
        
        UPDATE CalendarProviderAttributes SET
			AdvanceTime = coalesce(@AdvanceTime, AdvanceTime),
            BetweenTime = coalesce(@BetweenTime, BetweenTime),
            CalendarURL = coalesce(@CalendarURL, CalendarURL),
            PrivateCalendarToken = dbo.fx_IfNW(@PrivateCalendarToken, PrivateCalendarToken),
            IncrementsSizeInMinutes = coalesce(@IncrementsSizeInMinutes, IncrementsSizeInMinutes)
            
            -- Deprecated fields, to be removed:
            ,CalendarType = ''
            ,UseCalendarProgram = 1
         WHERE UserID = @UserID 
 
	ELSE
      
		INSERT INTO CalendarProviderAttributes (
			UserID,
			AdvanceTime,
			BetweenTime,
			CalendarURL,
			PrivateCalendarToken,
			IncrementsSizeInMinutes
			
			-- Deprecated fields, to be removed:
			,CalendarType
			,UseCalendarProgram
			,MinTime
			,MaxTime
		) VALUES (
			@UserID,
			coalesce(@AdvanceTime, 0),
			coalesce(@BetweenTime, 0),
			@CalendarURL,
			@PrivateCalendarToken,
			@IncrementsSizeInMinutes
			
			-- Deprecated fields
			,''
			,1
			,0
			,0
		)

END

GO
/****** Object:  StoredProcedure [dbo].[SetHomeAddress]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2013-04-08
-- Description:	Sets the data for the user
-- special 'Home' address, updating the
-- address or inserting a new record if
-- not exists
-- =============================================
CREATE PROCEDURE [dbo].[SetHomeAddress]
	@UserID int,
	@AddressLine1 varchar(100),
	@AddressLine2 varchar(100),
	@City varchar(100),
	@StateProvinceID int,
	@PostalCodeID int,
	@CountryID int,
	@LanguageID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE  Address WITH (serializable)
    SET     AddressLine1 = @AddressLine1
            ,AddressLine2 = @AddressLine2
            ,City = @City
            ,StateProvinceID = @StateProvinceID
            ,PostalCodeID = @PostalCodeID
            ,CountryID = @CountryID

            ,Active = 1
            ,UpdatedDate = getdate()
            ,ModifiedBy = 'sys'
    WHERE   UserId = @UserID
                AND
            AddressTypeID = 1 -- Ever Type: Home

    IF @@rowcount = 0
    BEGIN
        DECLARE @AddressName nvarchar(50)
        SELECT @AddressName = AddressType
        FROM AddressType
        WHERE AddressTypeID = 1 -- Home
                AND LanguageID = @LanguageID
                AND CountryID = @CountryID

        INSERT INTO Address (UserID, AddressTypeID, AddressName,
            AddressLine1, AddressLine2, City, StateProvinceID, PostalCodeID, CountryID,
            Active, CreatedDate, UpdatedDate, ModifiedBy)
        VALUES (@UserID, 1 /* Type: Home */, @AddressName, 
            @AddressLine1, @AddressLine2, @City, @StateProvinceID, @PostalCodeID, @CountryID, 
            1, getdate(), getdate(), 'sys')
    END
END

GO
/****** Object:  StoredProcedure [dbo].[SetUserAlert]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Allow active or disactive
--  (remove) an alert for an user and position
--  (PositionID=0 for alerts not related with
--  a position), with current Date-Time.
--  
-- =============================================
CREATE PROCEDURE [dbo].[SetUserAlert]
	@UserID int
	,@PositionID int
	,@AlertID int
	,@Active bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF @Active = 1 BEGIN
		UPDATE UserAlert WITH (Serializable) SET
			Active = 1,
			UpdatedDate = getdate(),
			ModifiedBy = 'sys'
		WHERE
			UserID = @UserID
			 AND
			PositionID = @PositionID
			 AND
			AlertID = @AlertID
			
		IF @@RowCount = 0
			INSERT INTO UserAlert (
				UserID, PositionID, AlertID, CreatedDate, UpdatedDate,
				ModifiedBy, Active, Dismissed
			) VALUES (
				@UserID, @PositionID, @AlertID, getdate(), getdate(),
				'sys', 1, 0
			)

    END ELSE BEGIN
		DELETE FROM UserAlert
		WHERE UserID = @UserID AND PositionID = @PositionID
			AND AlertID = @AlertID
    END
END

GO
/****** Object:  StoredProcedure [dbo].[SetUserVerification]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-07-17
-- Description:	Inserts or update a user 
-- verification record.
-- =============================================
CREATE PROCEDURE [dbo].[SetUserVerification]
	@UserID int
	,@VerificationID int
	,@VerifiedDate datetime
	,@VerificationStatusID int
	,@PositionID int = 0
AS
BEGIN
    UPDATE UserVerification WITH (serializable) SET
        UpdatedDate = getdate(),
        VerifiedBy = 'sys',
        LastVerifiedDate = @VerifiedDate,
        Active = 1,
        VerificationStatusID = @VerificationStatusID,
        PositionID = @PositionID
    WHERE
        UserID = @UserID
         AND
        VerificationID = @VerificationID

    IF @@rowcount = 0 BEGIN
        INSERT INTO UserVerification (
            UserID, VerificationID, DateVerified, CreatedDate, 
            UpdatedDate, VerifiedBy, LastVerifiedDate, Active, VerificationStatusID
        ) VALUES (
            @UserID, @VerificationID, @VerifiedDate, getdate(), getdate(), 'sys', getdate(), 1, @VerificationStatusID
        )
    END
END

GO
/****** Object:  StoredProcedure [dbo].[sp_MSforeachtable]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[sp_MSforeachtable]
	@command1 nvarchar(2000), @replacechar nchar(1) = N'?', @command2 nvarchar(2000) = null,
  @command3 nvarchar(2000) = null, @whereand nvarchar(2000) = null,
	@precommand nvarchar(2000) = null, @postcommand nvarchar(2000) = null
AS
	declare @mscat nvarchar(12)
	select @mscat = ltrim(str(convert(int, 0x0002)))
	if (@precommand is not null)
		exec(@precommand)
   exec(N'declare hCForEachTable cursor global for select ''['' + REPLACE(schema_name(syso.schema_id), N'']'', N'']]'') + '']'' + ''.'' + ''['' + REPLACE(object_name(o.id), N'']'', N'']]'') + '']'' from dbo.sysobjects o join sys.all_objects syso on o.id = syso.object_id '
         + N' where OBJECTPROPERTY(o.id, N''IsUserTable'') = 1 ' + N' and o.category & ' + @mscat + N' = 0 '
         + @whereand)
	declare @retval int
	select @retval = @@error
	if (@retval = 0)
		exec @retval = dbo.sp_MSforeach_worker @command1, @replacechar, @command2, @command3, 0
	if (@retval = 0 and @postcommand is not null)
		exec(@postcommand)
	return @retval


GO
/****** Object:  StoredProcedure [dbo].[TestAlertAvailability]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'availability' are satisfied, 
-- updating user alert and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertAvailability]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 2
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		-- #735 ATTRIBUTES DISABLED (TEMPORARLY MAYBE)
		-- EXISTS (SELECT UserID FROM [CalendarProviderAttributes]
		-- WHERE UserID = @UserID)
		-- AND
		-- Updated script to follow new Calendar back-end that use events
		-- with a specific type instead of the special -and deleted- table 'FreeEvents':
		--AND EXISTS (SELECT UserID FROM [CalendarProviderFreeEvents]
		--WHERE UserID = @UserID)
		EXISTS (SELECT UserID FROM [CalendarEvents]
		WHERE UserID = @UserID AND EventType = 2)
	BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID, 0
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertBackgroundCheck]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Modified date: 2013-04-11
-- Description:	Test if the conditions for the
-- alert type 'backgroundcheck' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- There are 2 alerts for this test:
--  12: backgroundcheck  (optional)
--  18: required-backgroundcheck  (required)
-- Because lookup backgroundacheck tables can
-- be required or not, any required one is 
-- related to the aler 18 and others to the
-- alert 12.
-- FROM DATE 2013-04-11:
-- Alerts will be off when almost a request
-- was done from provider, passing the test
-- request with state 'verified:2' and too
-- 'pending:1' and 'contact us:3; but not 
-- 'rejected/unable to verified:4'.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertBackgroundCheck]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 0
	
	DECLARE @OptionalAlertID int
	SET @OptionalAlertID = 12
	DECLARE @RequiredAlertID int
	SET @RequiredAlertID = 18
	DECLARE @IsRequired bit
    
    /* Background check must be checked per position, but is not saved
		on userverification per position. This means special treatment,
		and we must too ensure that is enabled only on positions affected
		by background-check according to the table PositionBackgroundCheck.
	   A position can satisfy a required background check if user has
	   already a background check with greater ID.
     */
    DECLARE @cur CURSOR
    DECLARE @PositionID int
    DECLARE @HigherBackgroundCheckID int
    
	SET @cur = CURSOR FOR 
		SELECT DISTINCT
		 PositionID
		FROM
		 UserProfilePositions
		WHERE
	     UserID = @UserID
	     
	OPEN @cur
	FETCH NEXT FROM @cur INTO @PositionID
	WHILE @@FETCH_STATUS = 0 BEGIN
		
		/* Go to a 2-steps loop, first for Optional and second for Required alert.
			allowing only tweak to vars preserving unduplicated the important code
		 */
		DECLARE @i int
		SET @i = 0
		WHILE @i < 2 BEGIN
			-- Setting up loop vars
			IF @i = 0 BEGIN
				-- Setting up vars for Optional
				SET @AlertID = @OptionalAlertID
				SET @IsRequired = 0
			END ELSE IF @i = 1 BEGIN
				-- Setting up vars for Required
				SET @AlertID = @RequiredAlertID
				SET @IsRequired = 1
			END ELSE
				BREAK

			/***
				RUN TEST CODE
			 ***/
			-- Reset var to avoid residual data
			SET @HigherBackgroundCheckID = null
			-- Get the higher background check that this position request for this user
			-- Or the lower background check if is a non-required alert
			SELECT	@HigherBackgroundCheckID = (CASE
						WHEN @IsRequired = 1
						 THEN MAX(PB.BackgroundCheckID)
						WHEN @IsRequired = 0
						 THEN MIN(PB.BackgroundCheckID)
					END)
			FROM	PositionBackgroundCheck As PB
			WHERE	PB.PositionID = @PositionID
				AND PB.[Required] = @IsRequired AND PB.Active = 1
				AND PB.CountryID = (SELECT TOP 1 CountryID FROM vwUsersContactData WHERE UserID = @UserID)
				AND PB.StateProvinceID = (SELECT TOP 1 StateProvinceID FROM vwUsersContactData WHERE UserID = @UserID)	

			-- First ever check if this type of alert affects this type of user
			IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
				-- if there is no a required background check, test passed
				@HigherBackgroundCheckID is null
				 OR
				-- if there is a required background check, check if user
				-- possess this or a greater background check to pass the test
				EXISTS (
					SELECT	UserID
					FROM	UserBackgroundCheck
					WHERE	UserID = @UserID
						-- Valid requests to off alert, depending on Status:
						AND StatusID IN (1, 2, 3)
						AND (
							-- For No-required, must have almost one background check, independently
							-- of is equals or greater, almost one
							@IsRequired = 0
							OR
							-- For required, must have a background check equals or greater than
							-- the higher one required for the position
							BackgroundCheckID >= @HigherBackgroundCheckID
						)
			) BEGIN
				-- PASSED: disable alert
				EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 0
			END ELSE BEGIN
				-- NOT PASSED: active alert
				EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 1
			END
		

			-- Next loop:
			SET @i = @i + 1
		END
		
		-- Next Position
		FETCH NEXT FROM @cur INTO @PositionID
	END
	CLOSE @cur
	DEALLOCATE @cur
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID
	
			/* Old code: In-loop-inside-if check based on UserVerification; deprecated by a better, more controlled, background check
			EXISTS (
				SELECT	UserID
				FROM	UserVerification As UV
				WHERE	UV.UserID = @UserID
						 AND
						UV.VerificationID = 7
						 AND
						UV.Active = 1
						 AND
						UV.VerificationStatusID = 1 -- 1:confirmed
				*/
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertBasicInfoVerification]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'basicinfoverification' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertBasicInfoVerification]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 10
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		3 = ( -- 3 Verifications being checked (1, 2, 4)
			SELECT	count(*)
			FROM	UserVerification As UV
			WHERE	UV.UserID = @UserID
					 AND
					UV.VerificationID IN (1, 2, 4)
					 AND
					UV.Active = 1
					 AND
					UV.VerificationStatusID = 1 -- 1:confirmed
	) BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertEducation]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2013-06-12
-- Description:	Test if the conditions for the
-- alert type 'add-education' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertEducation]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 20
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		EXISTS (SELECT UserID FROM UserEducation
				WHERE UserID = @UserID
					AND Active = 1
					/* Only require activation and InstitutionID, and this
					last is not-null and foreign key */
					/*AND FromYearAttended is not null
					AND (
						dbo.fx_IfNW(DegreeCertificate , null) is not null
						OR
						dbo.fx_IfNW(FieldOfStudy , null) is not null
					)*/
	) BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertLocation]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'location' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertLocation]
	@UserID int
	,@PositionID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 16
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		-- Check that user has that position (this is a position related alert). If it has not (=0), alert will off because doesn't affect:
		(SELECT count(*) FROM userprofilepositions WHERE UserID=@UserID AND PositionID=@PositionID) = 0 OR
		EXISTS (SELECT AddressID FROM ServiceAddress
	WHERE UserID = @UserID
		AND PositionID = @PositionID
		AND ( -- Must have almost one address to perfor work Or from it travel
			ServicesPerformedAtLocation = 1
			 OR
			TravelFromLocation = 1
		)
		AND Active = 1
	) BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID, @PositionID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertPayment]    Script Date: 17/10/2017 9:51:19 PM ******/
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
CREATE PROCEDURE [dbo].[TestAlertPayment]
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
		dbo.isMarketplacePaymentAccountActive(@UserID) = Cast(1 as bit)
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

GO
/****** Object:  StoredProcedure [dbo].[TestAlertPersonalInfo]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Modified date: 2012-08-17
-- Description:	Test if the conditions for the
-- alert type 'personalinfo' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertPersonalInfo]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 3
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
	  (
		EXISTS (
			SELECT UserID
			FROM Users
			WHERE 
				UserID = @UserID
				AND dbo.fx_IfNW(FirstName, null) is not null
				AND dbo.fx_IfNW(LastName, null) is not null
				AND (
				 dbo.fx_IfNW(MobilePhone, null) is not null
				  OR
				 dbo.fx_IfNW(AlternatePhone, null) is not null
				)
				-- GenderID now in TestAlertPublicBio, to match new forms
				--AND GenderID > 0
		)
		 AND
		EXISTS (
			SELECT	AddressID
			FROM	[Address]
			WHERE
				UserID = @UserID AND AddressTypeID = 1
				AND dbo.fx_IfNW(AddressLine1, null) is not null
				AND dbo.fx_IfNW(City, null) is not null
				AND dbo.fx_IfNW(StateProvinceID, null) is not null
				AND dbo.fx_IfNW(CountryID, null) is not null
				AND dbo.fx_IfNW(PostalCodeID, null) is not null
		)
	) BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertPhoto]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'photo' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertPhoto]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 4
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		EXISTS (SELECT UserID FROM Users
	WHERE UserID = @UserID
		AND dbo.fx_IfNW(Photo, null) is not null
	) BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertPositionServices]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'positionservices' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertPositionServices]
	@UserID int,
	@PositionID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 8
	
	DECLARE @CATS TABLE (CatID int)
	
	INSERT INTO @CATS (CatID)
	SELECT DISTINCT A.ServiceAttributeCategoryID
	FROM ServiceAttributeCategory As A
		  INNER JOIN
		 ServiceCategoryPositionAttribute As B
		   ON A.ServiceAttributeCategoryID = B.ServiceAttributeCategoryID
			AND B.PositionID = @PositionID
	WHERE A.RequiredInput = 1
		AND A.Active = 1
		AND B.Active = 1
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		-- Check that user has that position (this is a position related alert). If it has not (=0), alert will off because doesn't affect:
		(SELECT count(*) FROM userprofilepositions WHERE UserID=@UserID AND PositionID=@PositionID) = 0 OR
		-- Check all required data
		-- Must have almost one service attribute selected 
		-- per required category for the position
		@PositionID = 0
		OR (SELECT count(*) FROM (SELECT A.ServiceAttributeCategoryID
		FROM userprofileserviceattributes As A
		 INNER JOIN
		ServiceCategoryPositionAttribute As B
		  ON A.ServiceAttributeCategoryID = B.ServiceAttributeCategoryID
		   AND A.ServiceAttributeID = B.ServiceAttributeID
		  -- We only check the 'RequiredInput' Categories
		   AND B.ServiceAttributeCategoryID IN (SELECT CatID FROM @CATS)
		WHERE A.UserID = @UserID AND A.PositionID = @PositionID
			AND A.Active = 1 AND B.Active = 1
		GROUP BY A.ServiceAttributeCategoryID
	) As Z) = (SELECT count(*) FROM @CATS)
	BEGIN
		--PRINT 'you''re cool!'
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 0
	END ELSE BEGIN
		--PRINT 'buuuhhhh!'
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID, @PositionID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertPricingDetails]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[TestAlertPricingDetails]
	@UserID int,
	@PositionID int
AS
BEGIN
	
	
	SET NOCOUNT ON;
	DECLARE @AlertID int
	SET @AlertID = 1
    
    
    IF	dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		
		(SELECT count(*) FROM userprofilepositions WHERE UserID=@UserID AND PositionID=@PositionID) = 0 OR
		
		
		EXISTS (SELECT * FROM ProviderPackage
			WHERE ProviderUserID = @UserID
				AND PositionID = @PositionID
				AND Active = 1
		)
	
		BEGIN
		
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 0
	END ELSE BEGIN
		
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 1
	END
	
	
	EXEC dbo.TestProfileActivation @UserID, @PositionID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertProfessionalLicense]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[TestAlertProfessionalLicense]
    @UserID int
    ,@PositionID int
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    DECLARE @AlertID int
    SET @AlertID = 0
    
    DECLARE @OptionalAlertID int
    SET @OptionalAlertID = 13
    DECLARE @RequiredAlertID int
    SET @RequiredAlertID = 19
    DECLARE @IsRequired bit
    
    /* Go to a 2-steps loop, first for Optional and second for Required alert.
        allowing only tweak to vars preserving unduplicated the important code
     */
    DECLARE @i int
    SET @i = -1
    WHILE @i < 2 BEGIN
        -- Next loop:
        SET @i = @i + 1
        -- Setting up loop vars
        IF @i = 0 BEGIN
            -- Setting up vars for Optional
            SET @AlertID = @OptionalAlertID
            SET @IsRequired = 0
        END ELSE IF @i = 1 BEGIN
            -- Setting up vars for Required
            SET @AlertID = @RequiredAlertID
            SET @IsRequired = 1
        END ELSE
            BREAK

        /***
            RUN TEST CODE
            
            Global set of conditions to match to pass the alert (disable the alert):
            IF (
                alertAffectsUser = 0
                 OR
                userHasPosition = 0
                 OR
                -- Has all required licenses
                (
                    countryLevel = 0
                     AND
                    stateProvinceLevel = 0
                     AND
                    countyLevel = 0
                     AND
                    municipalLevel = 0
                )
                 OR
                -- There are no required licenses
                (
                    -- User has almost one license of the required list of licenses (changed on 2013-03-26 issue #203)
                    userLicensesOfEachOptionGroup > 0
                )
            )
         ***/
         
        -- GET RESULT FOR EACH INDIVIDUAL QUERY
         
        -- First ever check if this type of alert affects this type of user
        DECLARE @alertAffectsUser bit
        SET @alertAffectsUser = dbo.fxCheckAlertAffectsUser(@UserID, @AlertID)

        -- Check that user has that position (this is a position related alert). If it has not (=0), alert will off because doesn't affect:
        DECLARE @userHasPosition int
        SELECT @userHasPosition = count(*) FROM userprofilepositions WHERE UserID=@UserID AND PositionID=@PositionID

        -- Check if the user has all the required licenses (can be 0 if 0 are required) 
        -- Check Country-level 
        DECLARE @countryLevel int
        SELECT
            @countryLevel = COUNT(*)
        FROM
            jobTitleLicense JL
            INNER JOIN
            Country C
            ON JL.countryID = C.countryID
            LEFT JOIN
            userLicenseCertifications UL
            ON JL.LicenseCertificationID = UL.LicenseCertificationID
            AND UL.ProviderUserID = @userID
        WHERE
            JL.positionID in (@PositionID, -1) 
            AND C.languageID = (SELECT PreferredLanguageID FROM users WHERE UserID = @userID)
            AND C.countryID in (SELECT
            P.countryID
        FROM
            serviceaddress As SA
             INNER JOIN
            address As A
              ON A.AddressID = SA.AddressID
             INNER JOIN
            postalcode As P
            ON A.PostalCodeID = P.PostalCodeID
        WHERE
            SA.UserID = @userID
            AND SA.PositionID = @PositionID
            AND JL.Active = 1
            AND P.countryID not in ('0','-1')
            AND JL.Required = @IsRequired
        GROUP BY
            P.countryID)
        
        -- Check StateProvince-level 
        DECLARE @stateProvinceLevel int
        SELECT
            @stateProvinceLevel = COUNT(*)
            FROM
                jobTitleLicense JL
                INNER JOIN
                StateProvince SP
                ON JL.stateProvinceID = SP.stateProvinceID
                LEFT JOIN
                userLicenseCertifications UL
                ON JL.LicenseCertificationID = UL.LicenseCertificationID
                AND UL.ProviderUserID = @userID
            WHERE
                JL.positionID = @PositionID
                AND SP.stateProvinceID in (SELECT
                P.stateProvinceID
            FROM
                serviceaddress As SA
                 INNER JOIN
                address As A
                  ON A.AddressID = SA.AddressID
                 INNER JOIN
                postalcode As P
                ON A.PostalCodeID = P.PostalCodeID
            WHERE
                SA.UserID = @userID
                AND SA.PositionID = @PositionID
                AND JL.Active = 1
                AND P.stateProvinceID not in ('0','-1')
                AND JL.Required = @IsRequired
            GROUP BY
                P.stateProvinceID)
                
        -- Check County-level
        DECLARE @countyLevel int
        SELECT
            @countyLevel = COUNT(*)
            FROM
                jobTitleLicense JL
                INNER JOIN
                county CT
                ON JL.countyID = CT.countyID
                LEFT JOIN
                userLicenseCertifications UL
                ON JL.LicenseCertificationID = UL.LicenseCertificationID
                AND UL.ProviderUserID = @userID
            WHERE
                JL.positionID = @PositionID
                AND CT.countyID in (SELECT
                P.countyID
            FROM
                serviceaddress As SA
                 INNER JOIN
                address As A
                  ON A.AddressID = SA.AddressID
                 INNER JOIN
                postalcode As P
                ON A.PostalCodeID = P.PostalCodeID
            WHERE
                SA.UserID = @userID
                AND SA.PositionID = @PositionID
                AND JL.Active = 1
                AND P.countyID not in ('0','-1')
                AND JL.Required = @IsRequired
            GROUP BY
                P.countyID)
                
        -- Check Municipal-level 
        DECLARE @municipalLevel int
        SELECT
            @municipalLevel = COUNT(*)
        FROM
            jobTitleLicense JL
            INNER JOIN
            municipality M
            ON JL.MunicipalityID = M.MunicipalityID
            LEFT JOIN
            userLicenseCertifications UL
            ON JL.LicenseCertificationID = UL.LicenseCertificationID
            AND UL.ProviderUserID = @userID
        WHERE
            JL.positionID = @PositionID
            AND M.MunicipalityID in (SELECT
            P.MunicipalityID
        FROM
            serviceaddress As SA
             INNER JOIN
            address As A
              ON A.AddressID = SA.AddressID
             INNER JOIN
            postalcode As P
            ON A.PostalCodeID = P.PostalCodeID
        WHERE
            SA.UserID = @userID
            AND SA.PositionID = @PositionID
            AND JL.Active = 1
            AND P.MunicipalityID not in ('0','-1')
            AND JL.Required = @IsRequired
        GROUP BY
            P.MunicipalityID)
                
        
        -- If there are no (required) licenses
        DECLARE @userLicensesOfEachOptionGroup int
        SELECT 
            @userLicensesOfEachOptionGroup =
            CASE 
                WHEN COUNT(DISTINCT OptionGroup) <= SUM(
                    CASE
                        WHEN numberVerified > 0 AND OptionGroup is NOT NULL
                        THEN 1
                        ELSE 0
                    END
                )
                THEN 1
                ELSE 0
            END
         FROM
            (
                SELECT
                    JL.OptionGroup
                    ,COUNT(DISTINCT(JL.licenseCertificationID)) as numberOfLicenseOptions
                    ,SUM(CASE WHEN UL.StatusID IN (1, 2, 3, 5, 6) THEN 1 ELSE 0 END) as numberVerified
                FROM
                    (
                        SELECT
                            JL.OptionGroup
                            ,JL.licenseCertificationID
                        FROM
                            JobTitleLicense JL
                        WHERE
                            JL.Required = @IsRequired
                            AND JL.PositionID = @PositionID
                            AND licenseCertificationID in
                            (
                                (
                                SELECT
                                    JL.licenseCertificationID
                                FROM
                                    jobTitleLicense JL
                                    INNER JOIN
                                    Country C
                                    ON JL.countryID = C.countryID
                                    LEFT JOIN
                                    userLicenseCertifications UL
                                    ON JL.LicenseCertificationID = UL.LicenseCertificationID
                                    AND UL.ProviderUserID = @userID
                                WHERE
                                    JL.positionID in (@PositionID, -1) 
                                    AND C.languageID = (SELECT PreferredLanguageID FROM users WHERE UserID = @userID)
                                    AND C.countryID in
                                    (
                                        SELECT
                                            P.countryID
                                        FROM
                                            serviceaddress As SA
                                             INNER JOIN
                                            address As A
                                              ON A.AddressID = SA.AddressID
                                             INNER JOIN
                                            postalcode As P
                                            ON A.PostalCodeID = P.PostalCodeID
                                        WHERE
                                            SA.UserID = @userID
                                            AND SA.PositionID = @PositionID
                                            AND JL.Active = 1
                                            AND P.countryID not in ('0','-1')
                                            AND JL.Required = @IsRequired
                                        GROUP BY
                                            P.countryID
                                    )
                                ) UNION (
                                SELECT
                                    JL.licenseCertificationID
                                FROM
                                    jobTitleLicense JL
                                    INNER JOIN
                                    StateProvince SP
                                    ON JL.stateProvinceID = SP.stateProvinceID
                                    LEFT JOIN
                                    userLicenseCertifications UL
                                    ON JL.LicenseCertificationID = UL.LicenseCertificationID
                                    AND UL.ProviderUserID = @userID
                                WHERE
                                    JL.positionID = @PositionID
                                    AND SP.stateProvinceID in
                                    (
                                        SELECT
                                            P.stateProvinceID
                                        FROM
                                            serviceaddress As SA
                                             INNER JOIN
                                            address As A
                                              ON A.AddressID = SA.AddressID
                                             INNER JOIN
                                            postalcode As P
                                            ON A.PostalCodeID = P.PostalCodeID
                                        WHERE
                                            SA.UserID = @userID
                                            AND SA.PositionID = @PositionID
                                            AND JL.Active = 1
                                            AND P.stateProvinceID not in ('0','-1')
                                            AND JL.Required = @IsRequired
                                        GROUP BY
                                            P.stateProvinceID
                                    )
                                ) UNION (
                                SELECT
                                    JL.licenseCertificationID
                                FROM
                                    jobTitleLicense JL
                                    INNER JOIN
                                    county CT
                                    ON JL.countyID = CT.countyID
                                    LEFT JOIN
                                    userLicenseCertifications UL
                                    ON JL.LicenseCertificationID = UL.LicenseCertificationID
                                    AND UL.ProviderUserID = @userID
                                WHERE
                                    JL.positionID = @PositionID
                                    AND JL.Active = 1
                                    AND JL.Required = @IsRequired
                                    AND CT.countyID in
                                    (
                                        SELECT
                                            P.countyID
                                        FROM
                                            serviceaddress As SA
                                             INNER JOIN
                                            address As A
                                              ON A.AddressID = SA.AddressID
                                             INNER JOIN
                                            postalcode As P
                                            ON A.PostalCodeID = P.PostalCodeID
                                        WHERE
                                            SA.UserID = @userID
                                            AND SA.PositionID = @PositionID
                                            AND P.countyID not in ('0','-1')
                                        GROUP BY
                                            P.countyID
                                    )
                                ) UNION (
                                SELECT
                                    JL.licenseCertificationID
                                FROM
                                    jobTitleLicense JL
                                    INNER JOIN
                                    municipality M
                                    ON JL.MunicipalityID = M.MunicipalityID
                                    LEFT JOIN
                                    userLicenseCertifications UL
                                    ON JL.LicenseCertificationID = UL.LicenseCertificationID
                                    AND UL.ProviderUserID = @userID
                                WHERE
                                    JL.positionID = @PositionID
                                    AND M.MunicipalityID in
                                    (
                                        SELECT
                                        P.MunicipalityID
                                        FROM
                                            serviceaddress As SA
                                             INNER JOIN
                                            address As A
                                              ON A.AddressID = SA.AddressID
                                             INNER JOIN
                                            postalcode As P
                                            ON A.PostalCodeID = P.PostalCodeID
                                        WHERE
                                            SA.UserID = @userID
                                            AND SA.PositionID = @PositionID
                                            AND JL.Active = 1
                                            AND P.MunicipalityID not in ('0','-1')
                                            AND JL.Required = @IsRequired
                                        GROUP BY
                                            P.MunicipalityID
                                    )
                                )
                            )
                        GROUP BY
                            JL.OptionGroup
                            ,JL.licenseCertificationID
                    ) as JL
                LEFT JOIN
                (
                    SELECT 
                        V.licenseCertificationID,
                        V.VerificationStatusID as statusID
                    FROM
                        userlicensecertifications As V
                    WHERE
                        V.ProviderUserID = @userID
                         AND
                        V.PositionID = @PositionID
                ) as UL
                ON
                    JL.LicenseCertificationID = UL.LicenseCertificationID
                GROUP BY OptionGroup
            ) as hasAllRequiredLicenses


        -- FINAL CHECK OF CONDITIONS
        IF (
            @alertAffectsUser = 0
             OR
            @userHasPosition = 0
             OR
            -- Has all required licenses
            (
                @countryLevel = 0
                 AND
                @stateProvinceLevel = 0
                 AND
                @countyLevel = 0
                 AND
                @municipalLevel = 0
            )
             OR
            -- There are no required licenses
            (
                -- User has almost one license of the required list of licenses (changed on 2013-03-26 issue #203)
                @userLicensesOfEachOptionGroup > 0
            )
        )
        BEGIN
            -- PASSED: disable alert
            EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 0
        END ELSE BEGIN
            -- NOT PASSED: active alert
            EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 1
        END
    END
    
    -- Test if user profile must be actived or not
    EXEC dbo.TestProfileActivation @UserID, @PositionID
    

END


GO
/****** Object:  StoredProcedure [dbo].[TestAlertPublicBio]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'publicbio' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertPublicBio]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 9
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		EXISTS (
			SELECT UserID
			FROM Users
			WHERE UserID = @UserID
				AND dbo.fx_IfNW(PublicBio, null) is not null
				--AND GenderID > 0
	) BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertReferenceRequests]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'referencerequests' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertReferenceRequests]
	@UserID int
	,@PositionID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 14
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		-- Check that user has that position (this is a position related alert). If it has not (=0), alert will off because doesn't affect:
		(SELECT count(*) FROM userprofilepositions WHERE UserID=@UserID AND PositionID=@PositionID) = 0 OR
		EXISTS (
			SELECT	UserID
			FROM	UserVerification As UV
			WHERE	UV.UserID = @UserID
					 AND
					UV.VerificationID = 12 -- Reference(s) from former clients
				    -- Only 12, 11 is for 'Loconomics' user-reviewed' out of this alert.
					 AND
					UV.Active = 1
					 AND
					-- Check for verifications: 1:confirmed, 2:pending
					-- Pending is enough because means a request done by
					-- provider, and this alert is just for the request not
					-- require confirmations (but confirmation do the work, too)
					UV.VerificationStatusID IN (1, 2)
					 AND
					(
					 -- Its verification for this position..
					 UV.PositionID = @PositionID
					  OR
					 -- or is verification for 'any' position
					 UV.PositionID = 0
					)
					
	) BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID, @PositionID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertShowcaseWork]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'showcasework' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertShowcaseWork]
	@UserID int
	,@PositionID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 17
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		-- Check that user has that position (this is a position related alert). If it has not (=0), alert will off because doesn't affect:
		(SELECT count(*) FROM userprofilepositions WHERE UserID=@UserID AND PositionID=@PositionID) = 0 OR
		EXISTS (SELECT ProviderServicePhotoID FROM ProviderServicePhoto
	WHERE UserID = @UserID
		AND PositionID = @PositionID
		-- Must be almost one photo with address, caption and must be primary photo (to avoid provider has photos but not one chosed as primary)
		AND dbo.fx_IfNW(PhotoAddress, null) is not null
		AND IsPrimaryPhoto = 1
		AND Active = 1
	) BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID, @PositionID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertSocialMediaVerification]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'socialmediaverification' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertSocialMediaVerification]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 11
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		EXISTS (
			SELECT	UserID
			FROM	UserVerification As UV
					 INNER JOIN
					Verification As V
					  ON UV.VerificationID = V.VerificationID
			WHERE	UV.UserID = @UserID
					 AND
					V.VerificationCategoryID = 3
					 AND
					UV.Active = 1
					 AND
					V.Active = 1
					 AND
					UV.VerificationStatusID = 1 -- 1:confirmed
	) BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertTaxDocs]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Test if the conditions for the
-- alert type 'taxdocs' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertTaxDocs]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 6
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		EXISTS (SELECT ProviderUserID FROM ProviderTaxForm
	WHERE ProviderUserID = @UserID
		AND dbo.fx_IfNW(FullName, null) is not null
		AND dbo.fx_IfNW(StreetApt, null) is not null
		AND dbo.fx_IfNW(City, null) is not null
		AND dbo.fx_IfNW(PostalCodeID, null) is not null
		AND dbo.fx_IfNW(StateProvinceID, null) is not null
		AND dbo.fx_IfNW(CountryID, null) is not null
		AND dbo.fx_IfNW([Signature], null) is not null
		AND dbo.fx_IfNW(TINTypeID, null) is not null
		AND dbo.fx_IfNW(DateTimeSubmitted, null) is not null
		AND dbo.fx_IfNW(LastThreeTINDigits, null) is not null
		AND (
		 TaxEntityTypeID = 1
		  OR
		 dbo.fx_IfNW(BusinessName, null) is not null
		)
		AND Active = 1
	) BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAlertVerifyEmail]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-07-17
-- Description:	Test if the conditions for the
-- alert type 'verifyemail' are satisfied, 
-- updating user points and enabling or 
-- disabling it profile.
-- =============================================
CREATE PROCEDURE [dbo].[TestAlertVerifyEmail]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @AlertID int
	SET @AlertID = 15
    
    -- First ever check if this type of alert affects this type of user
    IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 0 OR
		EXISTS (SELECT UserID FROM webpages_Membership
	WHERE UserID = @UserID
		AND ConfirmationToken is null
		AND IsConfirmed = 1
	) BEGIN
		-- PASSED: disable alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 0
	END ELSE BEGIN
		-- NOT PASSED: active alert
		EXEC dbo.SetUserAlert @UserID, 0, @AlertID, 1
	END
	
	-- Test if user profile must be actived or not
	EXEC dbo.TestProfileActivation @UserID
END

GO
/****** Object:  StoredProcedure [dbo].[TestAllUserAlerts]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[TestAllUserAlerts] 
	@UserID int
	,@PositionID int = 0
AS
BEGIN
	
	
	SET NOCOUNT ON;
    EXEC TestAlertPersonalInfo				@UserID
    EXEC TestAlertPhoto						@UserID
    EXEC TestAlertPayment					@UserID
	
	EXEC TestAlertAvailability				@UserID
	EXEC TestAlertSocialMediaVerification	@UserID
	EXEC TestAlertBackgroundCheck			@UserID
	EXEC TestAlertBasicInfoVerification		@UserID	
	EXEC TestAlertVerifyEmail				@UserID
	EXEC TestAlertPublicBio					@UserID
	EXEC TestAlertEducation					@UserID
	
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

GO
/****** Object:  StoredProcedure [dbo].[TestAllUsersAlerts]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description: Execute the TestAllUserAlerts
-- per ALL users on the database and all its
-- positions
-- CAREFUL: database performance can be affected
-- by this, use as an utility on testing or
-- special maintenance / update that can require
-- it.
-- =============================================
CREATE PROCEDURE [dbo].[TestAllUsersAlerts]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @UserID int
    DECLARE @cur CURSOR
    
	SET @cur = CURSOR FOR 
		SELECT UserID
		FROM Users
		WHERE Active = 1
		 
	OPEN @cur
	FETCH NEXT FROM @cur INTO @UserID
	WHILE @@FETCH_STATUS = 0 BEGIN
		-- Execute this same proc but for a concrete positionID
		EXEC TestAllUserAlerts @UserID
		
		FETCH NEXT FROM @cur INTO @UserID
	END
	CLOSE @cur
	DEALLOCATE @cur

END

GO
/****** Object:  StoredProcedure [dbo].[TestProfileActivation]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[TestProfileActivation]
	@UserID int,
	@PositionID int = 0
AS
BEGIN
	
	
	SET NOCOUNT ON;
    DECLARE @cur CURSOR
    
    IF @PositionID = 0 BEGIN
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
			
			EXEC TestProfileActivation @UserID, @PositionID
			
			FETCH NEXT FROM @cur INTO @PositionID
		END
		CLOSE @cur
		DEALLOCATE @cur
    END ELSE BEGIN

		-- StatusID (marketplaceReady and auto switch status)
		IF (SELECT TOP 1 StatusID FROM UserProfilePositions
			WHERE UserID = @UserID AND PositionID = @PositionID)
			IN (1, 2) -- Its a state for automatic activation
		BEGIN	
			
			UPDATE UserProfilePositions SET
				StatusID = 
				CASE WHEN (SELECT count(*)
					FROM UserAlert As UA
						 INNER JOIN
						Alert As A
						  ON UA.AlertID = A.AlertID
					WHERE UA.UserID = @UserID
							AND
						  (UA.PositionID = 0 OR UA.PositionID = @PositionID)
							AND
						  A.Required = 1
							AND
						  UA.Active = 1
				) = 0 THEN 1 
				ELSE 2 
				END,
				
				UpdatedDate = GETDATE(),
				ModifiedBy = 'sys'
			WHERE	
				UserID = @UserID AND PositionID = @PositionID
		END
		
		-- Flag BookMeButtonReady
		UPDATE UserProfilePositions SET
			bookMeButtonReady = 
			CASE WHEN (SELECT count(*)
				FROM UserAlert As UA
					 INNER JOIN
					Alert As A
					  ON UA.AlertID = A.AlertID
				WHERE UA.UserID = @UserID
						AND
					  (UA.PositionID = 0 OR UA.PositionID = @PositionID)
						AND
					  A.bookMeButtonRequired = 1
						AND
					  UA.Active = 1
			) = 0 THEN 1 
			ELSE 0 
			END,
			
			UpdatedDate = GETDATE(),
			ModifiedBy = 'sys'
		WHERE	
			UserID = @UserID AND PositionID = @PositionID
	END
END


GO
/****** Object:  StoredProcedure [dbo].[UnDeleteUser]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-08-17
-- Description:	Restore a user account removed
-- throught the page /Account/$Delete/.
-- Of course, only restore from a 'weak delete'
-- =============================================
CREATE PROCEDURE [dbo].[UnDeleteUser]
	@UserID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE userprofile SET Email = substring(Email, len('DELETED:') + 2, len(Email) - len('DELETED: '))
    WHERE UserID = @UserID
    
    UPDATE users SET Active = 1, AccountStatusID = 1
    WHERE UserID = @UserID
END

GO
/****** Object:  StoredProcedure [dbo].[ut_AutocheckReviewVerifications]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2013-07-15
-- Description:	Automatically checks the reviews
-- providers have from customers to enable or
-- disable the related user-verifications:
-- 11: loconomics user reviewed
-- 12: review from former client
-- =============================================
CREATE PROCEDURE [dbo].[ut_AutocheckReviewVerifications]
AS BEGIN

	DECLARE @cur CURSOR
	DECLARE @UserID int, @PositionID int, @RevDate datetime
	
	----------------------------------
	-- Reviews
	
	SET @cur = CURSOR FOR
		SELECT	UserID, PositionID
		FROM	userprofilepositions
		WHERE	Active = 1

	OPEN @cur
	FETCH NEXT FROM @cur INTO @UserID, @PositionID
	WHILE @@FETCH_STATUS = 0 BEGIN

		-- Check 12: 'review from former client'
		SET @RevDate = null
		SELECT TOP 1 @RevDate = CreatedDate
		FROM UserReviews
		WHERE ProviderUserID = @UserID
			AND BookingID = 0
			AND PositionID = @PositionID

		IF @RevDate is not null
			-- There is reviews from former clients, verification confirmed
			EXEC SetUserVerification @UserID, 12, @RevDate, 1, @PositionID
		ELSE BEGIN
			-- Check if there is a verification already
			SET @RevDate = null
			SELECT TOP 1 @RevDate = CreatedDate
			FROM UserVerification
			WHERE	UserID = @UserID
					AND VerificationID = 12
					AND (PositionID = 0 OR PositionID = @PositionID)
			IF @RevDate is not null
				-- State: Pending, enough to off the provider-alert but not
				-- show the verification as done.
				-- Verification specific for the position
				EXEC SetUserVerification @UserID, 12, @RevDate, 2, @PositionID
		END

		-- Check 11: 'Loconomics user reviewed'
		SET @RevDate = null
		SELECT TOP 1 @RevDate = CreatedDate
		FROM UserReviews
		WHERE ProviderUserID = @UserID
			AND BookingID > 0
			AND PositionID = @PositionID

		IF @RevDate is not null
			EXEC SetUserVerification @UserID, 11, @RevDate, 1, @PositionID
		ELSE
			EXEC DelUserVerification @UserID, 11, @PositionID

		FETCH NEXT FROM @cur INTO @UserID, @PositionID
	END
	CLOSE @cur
	DEALLOCATE @cur

    -------------------------------
	-- Final check
	
	SET @cur = CURSOR FOR
		SELECT	UserID
		FROM	Users
		WHERE	Active = 1 AND IsProvider = 1
	
	OPEN @cur
	FETCH NEXT FROM @cur INTO @UserID
	WHILE @@FETCH_STATUS = 0 BEGIN

		-- Remove old user-verifications for 'loconomics reviews' without positionID,
		-- that doesn't work (and check was already done in previous loop)
		EXEC DelUserVerification @UserID, 11, 0

		-- Remove old user-verifications for 'former customers' without positionID,
		-- that doesn't work (and check was already done in previous loop)
		EXEC DelUserVerification @UserID, 12, 0

		FETCH NEXT FROM @cur INTO @UserID
	END
	CLOSE @cur
	DEALLOCATE @cur

END

GO
/****** Object:  StoredProcedure [dbo].[ut_ModifyUserAlertsState]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-08-18
-- Description:	Allow FORCE enable or disable all
-- the alerts affecting the user given for
-- the position given (or common profile if
-- zero), WITHOUT perform the alert 
-- tests/conditions (what can means data
-- corruption in some cases, waiting that some
-- things are complete because the alert is off
-- and they are not).
-- 
-- NOTE: Utility procedure, not to use
-- from the program, else as sysadmin, tester
-- or developer.
-- 
-- =============================================
CREATE PROCEDURE [dbo].[ut_ModifyUserAlertsState] 
	@UserID int
	,@PositionID int = 0
	,@StateActive bit = 1 -- 0 to disable all alerts
	,@TestProfileActivation bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @AlertID int
	DECLARE @PositionSpecific bit
    DECLARE @cur CURSOR
    
	SET @cur = CURSOR FOR 
		SELECT AlertID, PositionSpecific
		FROM Alert
		
	OPEN @cur
	FETCH NEXT FROM @cur INTO @AlertID, @PositionSpecific
	WHILE @@FETCH_STATUS = 0 BEGIN
	
		IF dbo.fxCheckAlertAffectsUser(@UserID, @AlertID) = 1 BEGIN
			IF @PositionSpecific = 1 BEGIN
				IF @PositionID > 0
					EXEC dbo.SetUserAlert @UserID, @PositionID, @AlertID, @StateActive
			END ELSE
				EXEC dbo.SetUserAlert @UserID, 0, @AlertID, @StateActive
		END

		FETCH NEXT FROM @cur INTO @AlertID, @PositionSpecific
	END
	CLOSE @cur
	DEALLOCATE @cur
    
    IF @TestProfileActivation = 1
		EXEC TestProfileActivation @UserID, @PositionID
END

GO
/****** Object:  UserDefinedFunction [dbo].[fx_concat]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* Iago Lorenzo Salgueiro:
 * Concat two strings with a nexus
 * between if they are not null.
 * If some string is null or empty, only the
 * another will be retrived, without nexus
 */
CREATE function [dbo].[fx_concat] (
 @str1 varchar(8000),
 @str2 varchar(8000),
 @nexo varchar(8000) = ''
)
RETURNS varchar(8000)
AS
BEGIN
 DECLARE @ret varchar(8000)
 if @str1 is null OR @str1 like ''
  SET @ret = @str2
 else if @str2 is null OR @str2 like ''
  SET @ret = @str1
 else
  SET @ret = @str1 + @nexo + @str2

 if @ret is null
  SET @ret = ''

 return @ret

END


GO
/****** Object:  UserDefinedFunction [dbo].[fx_concatBothOrNothing]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* Iago Lorenzo Salgueiro:
 * Concat two strings with a nexus
 * between if they are not null.
 * If some string is null or empty,
 * empty string is returned
 */
CREATE function [dbo].[fx_concatBothOrNothing] (
 @str1 varchar(8000),
 @str2 varchar(8000),
 @nexo varchar(8000) = ''
)
RETURNS varchar(8000)
AS
BEGIN
 DECLARE @ret varchar(8000)
 if @str1 is null OR @str1 like '' OR @str2 is null OR @str2 like ''
  SET @ret = ''
 else
  SET @ret = @str1 + @nexo + @str2

 return @ret

END

GO
/****** Object:  UserDefinedFunction [dbo].[fx_IfNW]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2012-06-01
-- Description:	Returns the @value if is not 
-- null, not empty and not a white spaces string
-- In that cases, the @default value is returned
-- Default can be null, empty, whitespaces
-- really or whatever you want.
-- =============================================
CREATE FUNCTION [dbo].[fx_IfNW]
(
	@value nvarchar(4000),
	@default nvarchar(4000)
)
RETURNS nvarchar(4000)
AS
BEGIN

	DECLARE @ret nvarchar(4000)

	IF @value is null OR @value like ''
		OR RTRIM(LTRIM(@value)) like ''
		SET @ret = @default
	ELSE
		SET @ret = @value

	RETURN @ret

END

GO
/****** Object:  UserDefinedFunction [dbo].[fxCheckAlertAffectsUser]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 06/29/2012
-- Description:	Returns 1 (as bit, means true)
-- if that alert must be checked for
-- that user, because the user type (IsCustomer,
-- IsProvider) and the AlertTypeID (only
-- providers alert, only customers, both)
-- =============================================
CREATE FUNCTION [dbo].[fxCheckAlertAffectsUser] (
	@UserID int,
	@AlertID int
) RETURNS Bit
AS BEGIN
	DECLARE @IsProvider bit, @IsCustomer bit
	DECLARE @AlertTypeID int
	SELECT @IsProvider = IsProvider FROM Users WHERE UserID = @UserID
	SELECT @IsCustomer = IsCustomer FROM Users WHERE UserID = @UserID
	
	DECLARE @Checked bit
	SET @Checked = Cast (0 As bit)
	
	IF @IsProvider = 1 AND @AlertID IN (SELECT AlertID FROM Alert WHERE ProviderAlert = 1)
		SET @Checked = Cast (1 As bit)
	IF @IsCustomer = 1 AND @AlertID IN (SELECT AlertID FROM Alert WHERE CustomerAlert = 1)
		SET @Checked = Cast (1 As bit)
		
	RETURN @Checked
END

GO
/****** Object:  UserDefinedFunction [dbo].[GetPositionString]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetPositionString] ( @UserID INT,@LangaugeID INT, @CountryID INT, @PositionCnt INT )

RETURNS VARCHAR(8000) AS BEGIN

        DECLARE @r VARCHAR(8000), @l VARCHAR(8000)

        SELECT @PositionCnt = @PositionCnt - 1,  @r = a.PositionSingular + ', '
          FROM positions a
          JOIN dbo.userprofilepositions up
              on a.positionid = up.PositionID
              AND a.LanguageID = up.LanguageID
              AND a.CountryID = up.CountryID 
        WHERE up.UserID = @UserID and up.LanguageID = @LangaugeID and up.CountryID = @CountryID
        
              
           AND @PositionCnt = ( SELECT COUNT(*) FROM positions a2
                          JOIN dbo.userprofilepositions up2
                          on a2.positionid = up2.PositionID
                          AND a2.LanguageID = up2.LanguageID
                          AND a2.CountryID = up2.CountryID 
                          
                       WHERE up.UserID = up2.UserID
                         AND a.PositionSingular <= a2.PositionSingular 
                         AND up.LanguageID = up2.LanguageID
                         AND up.CountryID = up2.CountryID
                          
                         
                         
                    ) ;
        IF @PositionCnt > 0 BEGIN
              EXEC @l = dbo.GetPositionString @UserID,@LangaugeID,@CountryID, @PositionCnt ;
              SET @r =  @l + @r ;
END
RETURN @r ;
END

GO
/****** Object:  UserDefinedFunction [dbo].[isMarketplacePaymentAccountActive]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2015-09-15
-- Description:	Checks if the payment account
-- to collect payments on the marketplace
-- bookings for a given userID is active.
-- =============================================
CREATE FUNCTION [dbo].[isMarketplacePaymentAccountActive]
(
	@userID int
)
RETURNS bit
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ret bit

	SET @ret = CASE WHEN EXISTS (
		SELECT	ProviderUserID
		FROM	ProviderPaymentAccount
		WHERE	ProviderUserID = @UserID
				 AND
				-- Braintree given status must be 'active' or 'pending'
                -- Allow for 'pending' is a small risk we take on 2013/12/11 https://github.com/dani0198/Loconomics/issues/408#issuecomment-30338668
				[Status] IN ('active', 'pending')
	) THEN CAST(1 as bit) ELSE CAST(0 as bit) END

	-- Return the result of the function
	RETURN @ret

END

GO
/****** Object:  View [dbo].[vwServiceCategoryPositionAttribute]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwServiceCategoryPositionAttribute] AS

	SELECT TOP 100 PERCENT
		d.PositionID
		,se.ServiceAttributeCategoryID
		,s.ServiceAttributeID
		,s.LanguageID
		,s.CountryID
		
		,d.Active As ServiceCategoryPositionAttributeActive
		,s.Active As ServiceAttributeActive
		,se.Active As ServiceAttributeCategoryActive
		
		,s.SourceID As ServiceAttributeSourceID
		,s.Name As ServiceAttributeName
		,s.ServiceAttributeDescription
		
		,s.DisplayRank As ServiceAttributeDisplayRank
		
		,se.ServiceAttributeCategory
		,se.ServiceAttributeCategoryDescription
		
		,se.SourceID As ServiceAttributeCategorySourceID
		,se.PricingOptionCategory
		,se.RequiredInput As ServiceAttributeCategoryRequiredInput
		,se.EligibleForPackages
		,se.SideBarCategory
		,se.DisplayRank As ServiceAttributeCategoryDisplayRank

	FROM servicecategorypositionattribute d
	  join serviceattribute s 
	  on d.ServiceAttributeID = s.ServiceAttributeID 
	  join serviceattributecategory se 
	  on d.ServiceAttributeCategoryID = se.ServiceAttributeCategoryID 
	  and d.LanguageID = se.LanguageID
	  and d.CountryID = se.CountryID
	  and se.LanguageID = s.LanguageID
	  and se.CountryID = s.CountryID

	ORDER BY s.DisplayRank ASC, s.Name ASC

GO
/****** Object:  View [dbo].[vwUsersContactData]    Script Date: 17/10/2017 9:51:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Iago Lorenzo Salgueiro
-- Create date: 2013-02-27
-- Description:	Gets users records with some
-- common extra information and its contact
-- and location data, getting location from
-- its address list that is assigned as 'home'
-- location.
-- =============================================
CREATE VIEW [dbo].[vwUsersContactData] AS

    SELECT
        -- Basic data
        a.UserID
        ,UP.Email
        ,a.CreatedDate As MemberSinceDate

        -- Name
        ,FirstName
        ,LastName
        ,SecondLastName
        ,MiddleIn
        ,(dbo.fx_concat(dbo.fx_concat(dbo.fx_concat(FirstName, dbo.fx_concatBothOrNothing(MiddleIn, '.', ''), ' '), LastName, ' '), SecondLastName, ' ')) As FullName
    
        -- DEPRECATED PHOTO
        ,Photo

        -- User Type
        ,coalesce(IsAdmin, cast(0 as bit)) As IsAdmin
        ,IsCustomer
        ,IsProvider
        ,AccountStatusID

        -- Only Providers:
        ,(CASE WHEN IsProvider=1 AND (
            SELECT count(*) FROM UserProfilePositions As UPS WHERE UPS.UserID = A.UserID AND UPS.Active=1
            ) > 0 THEN Cast(1 As bit)
            ELSE Cast(0 As bit)
        END) As IsActiveProvider

        ,ProviderWebsiteURL
        ,ProviderProfileURL

        -- Contact data
        ,MobilePhone
        ,AlternatePhone
    
        -- Address
        ,L.AddressLine1
        ,L.AddressLine2
        ,L.City
        ,L.StateProvinceID
        ,SP.StateProvinceName
        ,SP.StateProvinceCode
        ,L.CountryID
        ,PC.PostalCode
        ,L.PostalCodeID

        -- Personal data
        ,PublicBio
        ,A.GenderID
        ,GenderSingular
        ,GenderPlural
        ,SubjectPronoun
        ,ObjectPronoun
        ,PossesivePronoun
                                    
        -- Some preferences
        ,PreferredLanguageID
        ,PreferredCountryID
        ,IAuthZumigoVerification
        ,IAuthZumigoLocation

    FROM Users A
         INNER JOIN
        UserProfile As UP
          ON UP.UserID = A.UserID
         INNER JOIN
        Gender As G
          ON G.GenderID = A.GenderID
          	AND G.LanguageID = A.PreferredLanguageID  
          	AND G.CountryID = A.PreferredCountryID                                
         LEFT JOIN
        Address As L
          ON L.UserID = A.UserID
            AND L.AddressTypeID = 1 -- Only one address with type 1 (home) can exists
         LEFT JOIN
        StateProvince As SP
          ON SP.StateProvinceID = L.StateProvinceID
         LEFT JOIN
        PostalCode As PC
          ON PC.PostalCodeID = L.PostalCodeID

GO
