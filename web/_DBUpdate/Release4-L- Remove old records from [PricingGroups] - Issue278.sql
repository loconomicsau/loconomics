-- Delete now unused pricing groups: services, variables and options
DELETE FROM [PricingGroups] WHERE PricingGroupID IN (1, 2, 3)
