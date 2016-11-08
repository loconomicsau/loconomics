# Contributor Guidelines

## Communications
We prefer to keep all communications in each related Github issue and converse with each other using our @username so that conversations are well documented and stay within the project even if it requires a new issue for it.

## General coding style
All source files use 4 spaces indentation, UTF8 file enconding.

## CSS Naming Conventions

We use Bootstrap as CSS framework and it has it's own naming rules, for anything related to Boostrap (like adding changes, modifiers on top of Bootstrap classes) or files under /utils folder, we follow the simple Boostrap naming.

But for *components* styles, the classes at /components folder that start with uppercase letter, we use [SUIT naming convention](https://github.com/suitcss/suit/blob/master/doc/naming-conventions.md)

**Disclaimer**: this rules were not strictly followed in the past or there is code created before we set this rules, then current source code needs some clean-up/refator. New code must follow the rules.

We use a preprocessor, [Stylus](http://stylus-lang.com/); it's similar so SASS. We prefer the syntax more similar to CSS (use of semi-colons, brackets, etc.) while taking advantage of the features it provides (mixims, nesting, etc.).

## JS

We use ES5 (Ecmascript 5 edition) syntax in strict mode, with the addition of the ES6/ES2015 Promise pattern (we have an spec-compliant polyfill in place to support old engines).

We use [jshint](http://jshint.com/) to validate and enforce some good practices, helping reduce the number of bugs. Every commit must pass the jshint rules.

We split source files in modules, following the [CommonJS](http://wiki.commonjs.org/wiki/Modules/1.1) syntax.
We use a preprocessor, [Browserify](http://browserify.org/), to bundled the modules in a few files.

**Hint**: the *[debugger;](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/debugger)* javascript statement can be used for easier debugging, but remember to remove before commit your changes.

## HTML

We use HTML5.

Since we use the [KnockoutJS](http://knockoutjs.com/) library, there are a lot of 'data-bind' attributes, with javascript syntax in the value; this is used to connect elements with data generated from javascript files, while the javascript inside the 'data-bind' attribute must be kept at minimum as needed (avoid large or complex expressions, if can be just a variable assignement the better).
We use 'custom-elements' syntax sometimes at the HTML, for components created with KnockoutJS.

We use a preprocessor, [Bliss](https://github.com/cstivers78/bliss) at the minimum; it uses Asp.net Razor-like syntax, adapted for javascript. Generally, we use it only at the files wrapping all the html (examples: app.js.html, web.js.html).

## Changes to the database

Any proposed changes to the database should be made by placing a .sql file in the web/_DBUpdate folder of your branch with the file named with these three attributes:
- issue123 (the branch name) +
- A1 (order of the changes made to the database. Start a new letter if unrelated.) +
- short title (something describing the changes)

### Example
```
issue1076 - A1 - new customertransactiontype table.sql
```

## Use of Github

We use Github to track all user stories, development issues, marketing tasks, project management, product roadmaps, and a repository for for other related project information.

### Branch use and pull requests

#### Master
Only [@iagosrl](mailto:iagosrl@gmail.com) should commit to the master branch. 

#### New branches
If you are working on a specific Github issue, please create a new branch named issue123 if one doesn't already exist and merge master into it periodically. When you're finished, ask [@iagosrl](mailto:iagosrl@gmail.com) to review, and he'll merge it into master.

#### Pull requests
We prefer you create a Github issue for a specific topic/task to discuss about, with it's own issueXX branch where to commit, but if you want to make general updates or suggests a change by doing a pull request we are open to it.

### Adding user stories
We have a repository of user stories for [Service Professionals](/User Stories/User Stories - Service Professionals.md), [Clients](/User Stories/User Stories - Clients.md), and [Cooperatives](/User Stories/User Stories - Cooperatives.md).

#### Step 1: Review current user stories
Review the repositories to see if the feedback is already recorded by reviewing the existing Epic Stories and corresponding Child Stories.

#### Step 2: Determine if the story already fits into the repository 
Usually, the feedback can be translated into a Test Case for an existing Child Story or as a Child Story to an existing Epic Story.

#### Step 3: Add missing feedback
Feedback from users should be translated using the [User Story Template](/Agile Templates/User Story.md) to make it actionable into one of three types of stories:
##### Test Case
If recording a Test Case for an exisitng Child Story, copy the last Test Case, change the letter/number combination by adding 1 to the number, and overwrite with the new Test Case.
##### Child Story (most common)
Find the Epic Story the Child Story fits into, and copy the last Child Story, change the letter to the next letter in the alphabet, and overwrite with the new Child Story, any specific Persona(s) for the Child Story, and overwrite Test Cases with the new one(s).
##### Epic Story
Go to the bottom of the appropriate repository and copy the last Epic Story, change the number by adding 1, and overwrite with the new Epic Story, Child Stories, and Test Cases. 

### Bugs
Before reporting a bug:
* Please have a look in [Known Bugs](https://github.com/joshdanielson/Loconomics/milestone/74) and the current release folder to see if the bug has already been reported. If so please add any extra, clarifying information you can to the existing issue. 

The first thing we do with a bug report is confirm we can reproduce the bug. Please try to give us enough information so that we can produce the buggy experience ourselves:

Try to include:
* What steps you took just before the bug.
* What you were expecting to happen when the bug happened.
* What actually happened - the buggy behaviour itself.
* What web browser you were using.
* Screen shots.
* UserIDs, BookingIDs, JobTitleIDs involved.
* The /activityName from the URL.

[File a new Github issue](https://github.com/joshdanielson/Loconomics/issues/new) with two labels and include the severity in the title, e.g. Bug S1: Short description of bug:
#### Severity Level Label
![bug](https://cloud.githubusercontent.com/assets/1202838/19402991/2f2ddefe-9219-11e6-86ac-5a05a520e5e0.png)

##### Definitions:
- Bug: S1 (The issue is blocking an impending release.)
- Bug: S2 (The issue causes data loss, crashes or hangs salt processes, makes the system unresponsive, etc.)
- Bug: S3 (The issue reports incorrect functionality, bad functionality, a confusing user experience, etc.)
- Bug: S4 (The issue reports cosmetic items, formatting, spelling, colors, etc.)

#### Feature Area Label
![feature](https://cloud.githubusercontent.com/assets/1202838/19402990/2f27ec6a-9219-11e6-9a1e-2bb962c00c6a.png)

#### Milestone
Place into [Known Bugs](https://github.com/joshdanielson/Loconomics/milestone/74)

### Filing development issues
[File a new Github issue](https://github.com/joshdanielson/Loconomics/issues/new) with four labels:

#### Priority Level Label
![p labels](https://cloud.githubusercontent.com/assets/1202838/19402985/2f10bc02-9219-11e6-8b7b-e09ffd633c0a.png)
##### Definitions:
- P1 (The issue will be seen by all users.)
- P2 (The issue will be seen by most users.)
- P3 (The issue will be seen by about half of users.)
- P4 (The issue will not be seen by most users. Usually the issue is a very specific use case or corner case.)

#### Category Label
![category](https://cloud.githubusercontent.com/assets/1202838/19403470/70112afe-921c-11e6-8c01-1c2019871c48.png)

#### Feature Label (matching the area of the app)
![feature](https://cloud.githubusercontent.com/assets/1202838/19402990/2f27ec6a-9219-11e6-9a1e-2bb962c00c6a.png)

#### Readiness Label
![r labels](https://cloud.githubusercontent.com/assets/1202838/19402983/2ee1929c-9219-11e6-8860-cba1e935c955.png)

#### Milestone
@joshdanielson will place into Product Roadmap. R1 issues will be place into Releases based on developer feedback.

### Filing marketing issues
[File a new Github issue](https://github.com/joshdanielson/Loconomics/issues/new) with two labels:

#### Category Label
![marketing label](https://cloud.githubusercontent.com/assets/1202838/19402986/2f12a206-9219-11e6-91ed-e3bba17a1e59.png)

#### Marketing Label
![marketing](https://cloud.githubusercontent.com/assets/1202838/19402984/2f0919fc-9219-11e6-959d-c800044cec3e.png)

#### Milestone
@joshdanielson will place into Marketing Roadmap and issues will be place into Releases based on Staff discussion.

### Filing Information 
We store information related to the project but not development or marketing issues as issues in an [Information Repository](https://github.com/joshdanielson/Loconomics/milestone/34) for future reference.
[File a new Github issue](https://github.com/joshdanielson/Loconomics/issues/new) with two labels:

#### Category Label
![ir label](https://cloud.githubusercontent.com/assets/1202838/19402987/2f136e34-9219-11e6-8bc6-7aa786799856.png)

#### Information Repository Label
![information](https://cloud.githubusercontent.com/assets/1202838/19402988/2f14ec46-9219-11e6-811a-0434cbc146f0.png)

#### Milestone
Place into the [Information Repository](https://github.com/joshdanielson/Loconomics/milestone/34) 

