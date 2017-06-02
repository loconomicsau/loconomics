/**
  * AlertLink objects are view models for buttons or links representing profile alerts
  *
  * Do not create AlertLink objects directly, but use the exported factory function
  * createAlertLink. Some AlertLink objects require additional objects beyond ProfileAlerts
  * to build their properties. See documentation for createAlertLink below.
  *
  * @module
  */
'use strict';

var RouteParser = require('../utils/Router').RouteParser;

/**
 * Mapping of ProfileAlert alertName values to the properties specific to them used
 * in initializing an AlertLink.
 *
 * @private
 **/
var alertPresets = {
        positionservices: {
            label: 'Add details to your listing',
            route: new RouteParser('/servicesOverview/:jobTitleID')
        },
        availability: {
            label: 'When are you available to work?',
            route: new RouteParser('/schedulingPreferences')
        },
        personalinfo: {
            label: 'How do we reach you?',
            route: new RouteParser('/aboutMe')
        },
        photo: {
            label: 'Add your profile photo',
            route: new RouteParser('/aboutMe')
        },
        payment: {
            label: 'How do you want to be paid?',
            route: new RouteParser('/paymentAccount')
        },
        pricingdetails: {
            label: 'Add at least one bookable offering',
            route: new RouteParser('/serviceProfessionalService/:jobTitleID?mustReturn=marketplaceJobtitles/:jobTitleID')
        },
        publicbio: {
            label: 'Add a personal bio to your listing',
            route: new RouteParser('/aboutMe')
        },
        professionallicense: {
            label: 'Verify your professional license or certification',
            route: new RouteParser('/licensesCertifications/:jobTitleID')
        },
        location: {
            label: 'Where can your clients book you?',
            route: new RouteParser('/serviceAddresses/:jobTitleID')
        },
        'add-education': {
            label: 'Add training or education to your listing',
            route: new RouteParser('/education')
        },
        verifyemail: {
              label: 'Verify your account (check your e-mail)',
              route: new RouteParser('/verifications')
        },
        showcasework: {
            label: 'Add photos of your work',
            route: new RouteParser('/workPhotos/:jobTitleID')
        },
        'required-professionallicense': {
              label: 'Verify your professional license or certification',
              route: new RouteParser('/licensesCertifications/:jobTitleID')
        }
    },
    undefinedPreset = { label: '', route: { reverse: function() { return ''; } } };

/*
 * Creates an AlertLink. Do not initialize directly.
 *
 * @class
 */
var AlertLink = function(label, href) {
    this._label = label;
    this._href = href;
};

AlertLink.prototype.href = function() {
    return this._href;
};

AlertLink.prototype.label = function() {
    return this._label;
};

/**
 * Factory function for creating AlertLink objects from ProfileAlerts. Some
 * types of ProfileAlerts require additional information to build their properties.
 * These are passed via options.
 *
 * @param {Object} options object with additional data used to create AlertLinks.
 * @param {string} options.jobTitleID the job title ID pertinent to the corresponding profile alert
 **/
var createAlertLink = function(profileAlert, options) {
    var preset = alertPresets[profileAlert.alertName()] || undefinedPreset;

    return new AlertLink(preset.label, preset.route.reverse({ jobTitleID: options.jobTitleID }));
};

module.exports = createAlertLink;
