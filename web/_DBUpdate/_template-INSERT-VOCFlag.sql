INSERT INTO [VOCFlag]
           ([VOCFlagID]
           ,[LanguageID]
           ,[CountryID]
           ,[VOCFlagName]
           ,[VOCFlagNDescription]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[ModifiedBy]
           ,[Active])
     VALUES
           (@VOCFlagID
           ,@LanguageID
           ,@CountryID
           ,@VOCFlagName
           ,@VOCFlagNDescription
           ,@CreatedDate
           ,@UpdatedDate
           ,@ModifiedBy
           ,@Active)
