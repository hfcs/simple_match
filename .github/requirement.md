# Overview

# Architecture and Principles
- Follow MVVM app architecture described in https://docs.flutter.dev/app-architecture/guide, seperating UI and data layer, and package them into different modules
    - Views only handle UI
    - Business logic in View Models
    - Repositories handle data model as source of truth
    - Services handles API calls, platform calls and local file
- Use shared_preferences to persist data defined in the data model

# Modules and Requirement

## Data model

- Match set up: A list of {Stage, Scoring shoots}
- Shooter set up: A list of {Name, Handicap factor}
- Stage input: A list of {Stage, Shooter, Time, A, C, D, Misses, No Shoots, Procedure Errors}

## Scope

This program will set up a mini match of IPSC with following pages
- Main menu
- Match set up
- Shooter set up
- Stage input

Also implement a single button clearing data input and persisted
- Clear all data

We implement
- Proposed UI for each of the pages and button
- All the logic and validations triggered by UI update, also connect logic to UI update
- Data model update and write to persistent layer


## Main menu
- 4 buttons
    - Button to Match set up
    - Button to Shooter set up
    - Button to Stage input
    - Clear all data, a single button that ask user to confirm, allow user to cancel before proceeding to clear data model and the persistent storage

## Match set up
- Input:
    - Stage, an interger between 1 - 30, reject input and remind user if they enter value out of range
        - Stage are unique, reject input and remind user if they enter a value already exist in the list from data model
    - Scoring shoots, an integer between 1 - 32, reject input and remind user if they enter value out of range
- Function:
    - The input entry is stored in the data model
    - The list from data model is displayed in the page and allow add, remove, edit of entries
- Output:
    - entries add, update deleted on the list in data model is written to data presistence layer immediately

## Shooter set up
- Input:
    - Name, the name of the shooter participate in a match
        - Name for each shooters are unique, reject input and remind user if they enter a value already exist in the list from the data model
    - Handicap factor, a scaling factor between 0 - 1 in 2 digits decimals
        - Handicap factor is initialize to 1 and allow user input of a new value, any removal of input value would reset the value to 1
- Function:
    - The input entry is stored in the data model
    - The list from data model is displayed in the page and allow add, remove, edit of entries
- Output:
    - entries add, update deleted on the list in data model is written to data presistence layer immediately

## Stage input

Take a player's result in a certain stage as input

- Input:
    - Stage: a selector that select from one of "stage" set up in the Match set up
    - Shooter: a select that select from one of the "shooters" set up in the Shooter setup
    - Time: in format of seconds and 2 decimal sub-seconds, initialize to 0.00
    - A: integer, initialize to 0
    - C: integer, initialize to 0
    - D: integer, initialize to 0
    - Misses: integer, initialize to 0
    - No Shoots: integer, initialize to 0
    - Procedure Errors: integer, initialize to 0
    - Any removal of input value would reset the value to 0
    - Submit button
- Function:
    - The input entry is stored in the data model
    - Validate the record is a valid entry
        - Read from data model Scoring shoots of the selected Stage
        - if A + C + D + Misses == Scoring shoots, this is a valid record
        - If record is valid 
            - then calculate hit factor, adjusted hit factor, display them and enable Submit button.
                - Definition of hit factor =  Time / Total score
                    - "Total score" is an integer defined below
                    - Each "A" scored is 5 points
                    - Each "C" scored is 3 points
                    - Each "D scored is 1 point
                    - Each "Misses" deduct 10 points
                    - Each "No Shoots" deduct 10 points
                    - Each "Procedure Errors" deduct 10 points
                - Definition of adjusted hit factor =  hit factor * handicap factor of the shooter from data model
            - else disable Submit button and display an error message indicating the Scoring shoots of the selected Sage
    - When either a Stage or Shooter is selected, this page will refresh it's input
        - If a corresponding record in data model exist, this page will load the value and refresh UI
        - If a corrpesonding record in data model does not exist, initialize this page with value specified in input section
    - "Submit" button will be enabled when the record is a valid entry
        - Hitting the "Submit" button will write this record to data model
    - The list from data model is displayed in the page and allow add, remove, edit of entries
- Output:
    - entries add, update deleted on the list in data model is written to data presistence layer immediately


