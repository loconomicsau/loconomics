
/**
 * Used for adding, editing, and copying earnings entries.
 * @module kocomponents/earnings/editor
 *
 */

import '../../client/editor';
import '../../client/list';
import '../../utilities/icon-dec';
import '../../input/duration';
import '../../../utils/autofocusBindingHandler';
import Komponent from '../../helpers/KnockoutComponent';
import getObservable from '../../../utils/getObservable';
import ko from 'knockout';
import template from './template.html';

const TAG_NAME = 'earnings-editor';
const dummyData = {};
dummyData[0] =
{
    'Total': null,
    'PaidDate': null,
    'Duration': null,
    'PlatformID': null,
    'JobTitleID': null,
    'Notes': null,
    'ClientID': null,
    'ClientFirstName': null,
    'ClientLastName': null,
    'ClientEmail': null,
    'ClientPhoneNumber': null
};
dummyData[123] =
{
    'Total': 320.00,
    'PaidDate': '1/15/2018', 
    'Duration': 180,
    'PlatformID': 2,
    'JobTitleID': 106,
    'Notes': 'Really enjoyed meeting Kyra and hope to work with her again.',
    'ClientID': 141,
    'ClientFirstName': 'Kyra',
    'ClientLastName': 'Harrington',
    'ClientEmail': 'kyra@loconomics.com',
    'ClientPhoneNumber': '4159026022'
};


/**
 * Component
 */
export default class EarningsEditor extends Komponent {

    static get template() { return template; }

    /**
     * @param {object} params
     * @param {(string|KnockoutObservable<string>)} 
     * [params.editorMode]
     * @param {(number|KnockoutObservable<number>)} 
     * [params.earningsEntryID]
     * @param {(number|KnockoutObservable<number>)} 
     * [params.platformID]
     */
    constructor(params) {
        /* eslint max-statements:"off" */
        super();
        
        /**
         * Captures from the activity which "mode" the editor
         * component is to be used. 
         * Add: no values 
         * Edit:
         * Copy:
         * @member {KnockoutObservable<string>}
         */
        this.editorMode = getObservable(params.editorMode || null);
    
        /**
         * Holds the ID for an earnings entry if being edited or 
         * copied.
         * @member {KnockoutObservable<number>}
         */
        this.earningsEntryID = getObservable(params.earningsEntryID || null);

        /**
         * Holds the ID for a platform if being added from the
         * external-listing-view activity.
         * @member {KnockoutObservable<number>}
         */
        this.platformID = getObservable(params.platformID || null);

        /// Form data
        /**
         * Holds the email user to register the current anonymous 
         * user after atStep One
         * @member {KnockoutObservable<number>}
         */
        this.total = ko.observable(null);

        /**
         * @member {KnockoutObservable<date>}
         */                 
        this.date = ko.observable('');

        /**
         * @member {KnockoutObservable<number>}
         */
        this.duration = ko.observable(60);

        /**
         * @member {KnockoutObservable<number>}
         */
        this.platformID = ko.observable(0);

        /**
         * @member {KnockoutObservable<string>}
         */

        this.notes = ko.observable('');
        /**
         * @member {KnockoutObservable<number>}
         */
        this.clientID = ko.observable(0);
        
        /**
         * Stores the client's first name.
         * @member {KnockoutObservable<string>}
         */
        this.clientFirstName = ko.observable('');

        /**
         * Stores the client's last name.
         * @member {KnockoutObservable<string>}
         */
        this.clientLastName = ko.observable('');

        /**
         * Stores the client's email address.
         * @member {KnockoutObservable<string>}
         */
        this.clientEmail = ko.observable('');

        /**
         * Stores the client's phone number.
         * @member {KnockoutObservable<string>}
         */
        this.clientPhoneNumber = ko.observable('');

        /**
         * Earnings summary returned given query parameters.
         * @member {KnockoutObservable<object>}
         */
        this.earningsEntry = ko.observable();

        /// Steps management
        /**
         * Keeps track of the current step being displayed
         * @member {KnockoutObservable<number>}
         */
        this.currentStep = ko.observable(1);

        /**
         * Returns which step the user is on in the form.
         * @member {KnockoutComputed<boolean>}
         */
        this.isAtStep = function(number) {
            return ko.pureComputed( () => this.currentStep() === number);
        }; 

        /**
         * Takes the user to the next step in the form.
         * @member {KnockoutComputed<number>}
         */
        this.goNextStep = function() {
            this.currentStep(this.currentStep() + 1);
        }; 

        this.goToStep = (step) => {
            this.currentStep(step);
        };

        this.goToSummary = function() {
            this.currentStep(0);
            this.editorMode('Edit');
            this.stepButtonLabel = 'Save';
        }; 

        /**
         * Takes the user to the next step in the form.
         * @member {KnockoutComputed<string>}
         */
        this.stepButtonLabel = ko.observable('Save and Continue');

        /**
         * Takes the user to the next step in the form.
         * @member {KnockoutComputed<string>}
         */
        // this.stepButtonLabel = ko.pureComputed( () => {
        //     if (this.editorMode() == 'Add') {
        //         return 'Save and Continue';
        //     }
        //     else {
        //         return 'Save';
        //     }
        // }); 
        
        /**
         * Takes the user to the next step in the form.
         * @member {KnockoutComputed<number>}
         */
        this.saveStep = function() {
            if (this.editorMode() == 'Add') {
                this.goNextStep();
                this.stepButtonLabel = 'Save and Continue';
            }
            else {
                this.currentStep(0);
                this.stepButtonLabel = 'Save';
            }
        }; 

        /// Statuses

        /**
         * Error message from last 'save' operation
         * @member {KnockoutObservable<string>}
         */
        this.errorMessage = ko.observable('');

        /**
         * When a saving request it's on the works
         * @member {KnockoutObservable<boolean>}
         */
        this.isSaving = ko.observable(false);

        /**
         * When edition must be locked because of in progress 
         * operations. Just an alias for saving in this case, but 
         * expected to be used properly at the data-binds
         * @member {KnockoutComputed<boolean>}
         */
        this.isLocked = this.isSaving;
 
        this.observeChanges(() => {
            const data = dummyData[0];
            this.earningsEntry(data);
        });
    }
}

ko.components.register(TAG_NAME, EarningsEditor);

