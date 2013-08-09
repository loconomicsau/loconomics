﻿using System;
using System.Collections.Generic;
using WebMatrix.Data;
using System.Web;
using System.Web.WebPages;
using System.Web.Helpers;
using System.Text;

/// <summary>
/// Extension of LcPricingModel
/// </summary>
public static partial class LcPricingModel
{
    public class PackageModHourly : PackageMod
    {
        double formulaA, formulaB, formulaC;
        string type;
        int sliderStep = 20;
        public PackageModHourly()
        {
        }
        /// <summary>
        /// Calculate and returns the time in minutes for the given values
        /// </summary>
        /// <param name="numbedrooms"></param>
        /// <param name="numbathrooms"></param>
        /// <returns></returns>
        private double ApplyFormula(int numbedrooms = 2, int numbathrooms = 2)
        {
            return (formulaA * numbedrooms + formulaB * numbathrooms + formulaC);
        }
        private double GetProviderCleaningRate(PackageBaseData package)
        {
            // return .8; // 140.34 / formulaAverageT
            return (new PackageVariables(package.ProviderUserID, package.ID)).Get<double>("CleaningRate", 1.0);
        }
        #region Customer form part
        public void CalculateCustomerData(PackageBaseData package, FeeRate fee, PricingModelData modelData, System.Web.WebPages.Html.ModelStateDictionary ModelState)
        {
            /* IMPORTANT: we calculate here the service duration for one session based on some custom variables for housekeeper pricing,
             * final price and fees are calculated in the standard code using the package Duration field, because of that
             * we only update package.Duration here for later complete price calculation */

            // Get customer input
            var nbeds = Request[String.Format("bedrooms-number[{0}]", package.ID)].AsInt();
            var nbaths = Request[String.Format("bathrooms-number[{0}]", package.ID)].AsInt();
            // get provider rate
            var providerRate = GetProviderCleaningRate(package);
            // Apply formula, changed by the providerRate (variation from the average)
            var duration = ApplyFormula(nbeds, nbaths) * providerRate;
            // Create time object from duration, rounded to quarter-hours (15 minutes blocks)
            var timeDuration = ASP.LcHelpers.RoundTimeToQuarterHour(TimeSpan.FromMinutes(duration), ASP.LcHelpers.RoundingType.Up);
            // Create variables object with the specific data used in this calculation (will be saved later by the normal packages process)
            // Provider values get included in the object, something that is wanted for historic purposes on database.
            var vars = new PackageVariables(package.ProviderUserID, package.ID);
            vars["BathsNumber"] = nbaths;
            vars["BedsNumber"] = nbeds;
            // Change package with the information:
            package.Duration = timeDuration;
            modelData.ProviderInput = providerRate;
            modelData.CustomerInput = vars;
        }
        public string GetCustomerHtml(PackageBaseData package, FeeRate fee)
        {
            // get provider rate
            var providerRate = GetProviderCleaningRate(package);
            // Get HourlyRate for client-side calculation, and fees
            var price = new Price(package.PriceRate ?? 0M, fee, 1);
            var hourlyFee = price.FeePrice;
            var hourlyRate = price.TotalPrice;

            var s = new StringBuilder();

            s.AppendFormat("<div class='housekeeper-pricing' data-formula-a='{0}' data-formula-b='{1}' data-formula-c='{2}' data-hourly-rate='{3}' data-hourly-fee='{4}' data-provider-rate='{5}'>", formulaA, formulaB, formulaC, hourlyRate, hourlyFee, providerRate);
            s.Append(@"<div>Help us determine an accurate 
                <span class='has-tooltip' title='You and your provider will review this estimate and finalize before the work begins.'>
                price estimate</span></div>");

            s.AppendFormat(@"<div data-slider-value='3' data-slider-step='1' class='housekeeper-pricing-bedrooms customer-slider'><label>Bedrooms: <input name='bedrooms-number[{0}]' type='text' /></label></div>", package.ID);
            s.AppendFormat(@"<div data-slider-value='3' data-slider-step='1' class='housekeeper-pricing-bathrooms customer-slider'><label>Bathrooms: <input name='bathrooms-number[{0}]' type='text' /></label></div>", package.ID);
            s.Append("</div>");

            return s.ToString();
        }
        #endregion
        #region Provider form part
        public string GetProviderHtml(PackageBaseData package)
        {
            // Get variables
            PricingVariables provars;
            if (package.ID == 0)
                provars = PricingVariables.ForNewProviderPackage(package.ProviderUserID, 0, package.PositionID, package.PricingTypeID);
            else
                provars = PricingVariables.FromProviderPackage(package.ProviderUserID, package.ID);

            // Create html for form elements, variables values organized per sections
            var hValues = new StringBuilder();
            var hSurcharges = new StringBuilder();
            var hIncludes = new StringBuilder();
            var hRestrictions = new StringBuilder();
            // Iterating provider variables:
            foreach (var provar in provars)
            {
                if (provar.Value.Def.IsProviderVariable)
                {
                    if (!String.IsNullOrEmpty(provar.Value.Def.HourlySurchargeLabel))
                    {
                        hSurcharges.AppendFormat("<li><label>$ <input type='text' name='{1}-value' value='{3}' /></label> <span class='has-tooltip' title='{2}'>{0}</span></li>",
                            provar.Value.Def.HourlySurchargeLabel,
                            provar.Value.Def.InternalName,
                            provar.Value.Def.HourlySurchargeLabelPopUp,
                            provar.Value.Value);
                    }
                    else
                    {
                        // Is not a surcharge, is a value
                        hValues.AppendFormat("<li><label><span class='has-tooltip' title='{2}'>{0}</span>: $ <input type='text' name='{1}-value' value='{3}' /></label></li>",
                            provar.Value.Def.VariableLabel,
                            provar.Value.Def.InternalName,
                            provar.Value.Def.VariableLabelPopUp,
                            provar.Value.Value);
                    }
                    if (!String.IsNullOrEmpty(provar.Value.Def.NumberIncludedLabel))
                    {
                        hIncludes.AppendFormat("<li><label>{0} <input type='text' name='{1}-numberincluded' value='{3}' /></label> <span class='has-tooltip' title='{2}'>{4}/{5}</span></li>",
                            provar.Value.Def.NumberIncludedLabel,
                            provar.Value.Def.InternalName,
                            provar.Value.Def.NumberIncludedLabelPopUp,
                            provar.Value.ProviderNumberIncluded,
                            provar.Value.Def.VariableNameSingular,
                            provar.Value.Def.VariableNamePlural);
                    }
                    if (!String.IsNullOrEmpty(provar.Value.Def.MinNumberAllowedLabel))
                    {
                        hRestrictions.AppendFormat("<li><label><span class='has-tooltip' title='{2}'>{0}</span> <input type='text' name='{1}-minnumberallowed' /></label></li>",
                            provar.Value.Def.MinNumberAllowedLabel,
                            provar.Value.Def.InternalName,
                            provar.Value.Def.MinNumberAllowedLabelPopUp,
                            provar.Value.ProviderMinNumberAllowed);
                    }
                    if (!String.IsNullOrEmpty(provar.Value.Def.MaxNumberAllowedLabel))
                    {
                        hRestrictions.AppendFormat("<li><label><span class='has-tooltip' title='{2}'>{0}</span> <input type='text' name='{1}-maxnumberallowed' /></label></li>",
                            provar.Value.Def.MaxNumberAllowedLabel,
                            provar.Value.Def.InternalName,
                            provar.Value.Def.MaxNumberAllowedLabelPopUp,
                            provar.Value.ProviderMaxNumberAllowed);
                    }
                }
            }

            // Creating HTML
            var s = new StringBuilder();
            s.Append("<div class='hourly-pricing'>");
            if (hValues.Length > 0)
            {
                s.Append("<ul class='var-values'>");
                s.Append(hValues);
                s.Append("</ul>");
            }
            if (hIncludes.Length > 0)
            {
                s.Append("<h4>Includes:</h4>");
                s.Append("<ul class='var-includes'>");
                s.Append(hIncludes);
                s.Append("</ul>");
            }
            if (hSurcharges.Length > 0)
            {
                s.Append("<h4>Hourly surcharge(s):</h4>");
                s.Append("<ul class='var-surcharges'>");
                s.Append(hSurcharges);
                s.Append("</ul>");
            }
            if (hRestrictions.Length > 0)
            {
                s.Append("<h4>Booking restrictions:</h4>");
                s.Append("<ul class='var-restrictions'>");
                s.Append(hRestrictions);
                s.Append("</ul>");
            }
            s.Append("</div>");

            return s.ToString();
        }
        public bool ValidateProviderData(PackageBaseData package, System.Web.WebPages.Html.ModelStateDictionary modelState)
        {
            return Request["provider-average-time"].AsFloat() > 0;
        }
        public void SaveProviderData(PackageBaseData package, Database db)
        {
            var provTime = Request["provider-average-time"].AsFloat();
            var provRate = provTime / ApplyFormula();
            // Save rate on DB
            var vars = new PackageVariables(package.ProviderUserID, package.ID);
            vars.Set("CleaningRate", provRate);
            vars.Save();
        }
        #endregion
        #region Pricing Summary
        /// <summary>
        /// It shows the customer variables values
        /// </summary>
        /// <param name="package"></param>
        /// <returns></returns>
        public string GetPackagePricingDetails(int packageID, int pricingEstimateID, int pricingEstimateRevision)
        {
            var pv = PricingVariables.FromPricingEstimatePackage(packageID, pricingEstimateID, pricingEstimateRevision);
            var res = new List<string>();
            var summaryFormat = "{0}: {1}";
            foreach (var v in pv)
            {
                // If value is a number
                var val = v.Value.GetValue<double?>(null);
                if (val.HasValue)
                {
                    // Show singular or plural depending on the value
                    if (val.Value == 1)
                    {
                        res.Add(String.Format(summaryFormat, v.Value.Def.VariableNameSingular, 1));
                    }
                    else
                    {
                        res.Add(String.Format(summaryFormat, v.Value.Def.VariableNamePlural, val.Value));
                    }
                }
                else
                {
                    // Is another kind of value (string, datetime, ...) use singular variable name
                    res.Add(String.Format(summaryFormat, v.Value.Def.VariableNameSingular, v.Value.Value));
                }
            }
            return ASP.LcHelpers.JoinNotEmptyStrings(", ", res);
        }
        #endregion
    }
}