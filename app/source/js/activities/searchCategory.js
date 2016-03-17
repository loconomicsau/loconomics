/**
    Category Search activity
**/
'use strict';

var 
    ko = require('knockout'),
    Activity = require('../components/Activity');

var A = Activity.extend(function SearchCategoryActivity() {

    Activity.apply(this, arguments);

    this.accessLevel = null;
    //pass in the app model so the view model can use it
    this.viewModel = new ViewModel(this.app.model);
    this.navBar = Activity.createSubsectionNavBar('Back');

});

exports.init = A.init;

// get jobTitleID from the URL that's passed in from the search results preview
A.prototype.show = function show(options) {
    Activity.prototype.show.call(this, options);
    var params = this.requestData.route.segments || [];
    var categoryID = params[0] || '';
    var origLat = params[1] || '';
    var origLong = params[2] || '';
    var searchDistance = params[3] || '';
    this.viewModel.load(categoryID, origLat, origLong, searchDistance);
};

function ViewModel(appModel) {
    this.isLoading = ko.observable(false);
    this.isCategoryLoading = ko.observable(false);
    //create an observable variable to hold the search term
    this.categoryID = ko.observable(); 
    //create an observable variable to hold the search term
    this.origLat = ko.observable(); 
    //create an observable variable to hold the search term
    this.origLong = ko.observable(); 
    //create an observable variable to hold the search term
    this.searchDistance = ko.observable(); 
    //create an object named ServiceProfessionalSearchResult to hold the search results returned from the API
    this.jobTitleSearchResult = ko.observableArray();
    this.categorySearchResult = ko.observable();
    //create a pure computed ko observable to change the background image when the categoryID changes
    this.categoryBackgroundImage = ko.pureComputed(function(){
        var id = this.categoryID();
        return id ? 'CategoryBackground-' + id : '';
    }, this); //add this so that the context is the current one (special ko syntax)
    
    // PRIVATE load functions, that use parameters we will internally ensure are the same values
    // as the observables we have for them
    var loadCategoryData = function(categoryID, origLat, origLong, searchDistance){
        this.isCategoryLoading(true);
        //Call the get rest API method for api/v1/en-US/search/categories/by-categoryID
        return appModel.rest.get('search/categories/' + categoryID, {
            origLat: origLat, 
            origLong: origLong,
            searchDistance: searchDistance
        })
        .then(function(data) {
            this.categorySearchResult(data);
            this.isCategoryLoading(false);
        }.bind(this))
        .catch(function(/*err*/) {
            this.isCategoryLoading(false);
        }.bind(this));
    }.bind(this);
    var loadData = function(categoryID, origLat, origLong, searchDistance) {
        this.isLoading(true);
        //Call the get rest API method for api/v1/en-US/search/job-titles/by-category
        return appModel.rest.get('search/job-titles/by-category', {
            categoryID: categoryID, 
            origLat: origLat, 
            origLong: origLong,
            searchDistance: searchDistance
        })
        .then(function(list) {
            this.jobTitleSearchResult(list);
            this.isLoading(false);
        }.bind(this))
        .catch(function(/*err*/) {
            this.isLoading(false);
        }.bind(this));
    }.bind(this);
    // PUBLIC load function; the given parameters are stored in observables and used
    // to perform all data loading tasks.
    // @return Promise
    this.load = function(categoryID, origLat, origLong, searchDistance) {
        // Update observables with given data, so them reflects the same data we are loading
        this.categoryID(categoryID);
        this.origLat(origLat);
        this.origLong(origLong);
        this.searchDistance(searchDistance);
        // Call specific load functions.
        // The returned promise fulfilles when both are completed
        return Promise.all([
            loadCategoryData(categoryID, origLat, origLong, searchDistance),
            loadData(categoryID, origLat, origLong, searchDistance)
        ]);
    };
}

