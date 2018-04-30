/**
 * Testing activity '_test'. Do temporary trials here but without commit them,
 * or do it copying with another name (keep the leading underscore if is
 * just for testing).
 *
 * IMPORTANT: Any activity starting with underscore must not being published.
 */
'use strict';

import '../../kocomponents/solution/autocomplete';
import * as activities from '../index';
import Activity from '../../components/Activity';
import ko from 'knockout';
import template from './template.html';

const ROUTE_NAME = '_test';

export default class _TestActivity extends Activity {

    static get template() { return template; }

    constructor($activity, app) {
        super($activity, app);
        this.accessLevel = null;
        this.title = 'Testing area';

        this.selectedSolution = ko.observable(null);
    }
}

activities.register(ROUTE_NAME, _TestActivity);
