  -- Delete old-testing invalid rows from pricing estimate detail
  -- (things related to custom pricing services, variables, options)
  DELETE FROM pricingestimatedetail where ProviderPackageID = 0