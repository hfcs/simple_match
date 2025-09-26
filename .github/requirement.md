# Overview

# Architecture and Principles
- Follow MVVM app architecture described in https://docs.flutter.dev/app-architecture/guide, seperating UI and data layer, and package them into different modules
    - Views only handle UI
    - Business logic in View Models
    - Repositories handle data model as source of truth
    - Services handles API calls, platform calls and local file
    - All state changes must trigger persistence (using SharedPreferences)
    - All features must be implemented with logic and widget tests (test-driven development)
    

# Modules and Requirement

## UI
- Modern, visually appealing style (e.g., cards, spacing, icons)

## Data model

- Match set up: A list of {Stage, Scoring shoots}
- Shooter set up: A list of {Name, Scale factor}
- Stage input: A list of {Stage, Shooter, Time, A, C, D, Misses, No Shoots, Procedure Errors}

## Scope

This program will set up a mini match of IPSC with following pages
- Main menu
- Match set up
- Shooter set up
- Stage input
- Stage result
- Overall result

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
    - Button to Overall result
    - Clear all data, a single button that ask user to confirm, allow user to cancel before proceeding to clear data model and the persistent storage

## Match set up
- With back button returning to main menu
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
- With back button returning to main menu
- Input:
    - Name, the name of the shooter participate in a match
        - Name for each shooters are unique, reject input and remind user if they enter a value already exist in the list from the data model
    - Scale factor, a scaling factor between 0 - 2 in 2 digits decimals
        - Scale factor is initialize to 1 and allow user input of a new value, any removal of input value would reset the value to 1
- Function:
    - The input entry is stored in the data model
    - The list from data model is displayed in the page and allow add, remove, edit of entries
- Output:
    - entries add, update deleted on the list in data model is written to data presistence layer immediately

## Stage input
- With back button returning to main menu
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
    - Input fields for Time, A, C, D are arranged vertically; Misses and No Shoots are on one row, Procedure Errors and Submit button are on the next row
- Function:
    - The input entry is stored in the data model
    - Calculate hit factor, adjusted hit factor, display them
        - Definition of hit factor =  Time / Total score
            - "Total score" is an integer defined below
            - Each "A" scored is 5 points
            - Each "C" scored is 3 points
            - Each "D scored is 1 point
            - Each "Misses" deduct 10 points
            - Each "No Shoots" deduct 10 points
            - Each "Procedure Errors" deduct 10 points
        - Definition of adjusted hit factor =  hit factor * scale factor of the shooter from data model
    - When any input is changed, we validate if the record is valid
        - Read from data model Scoring shoots of the selected Stage
        - if A + C + D + Misses == Scoring shoots, this is a valid record
            - then enable Submit button.
            - else disable Submit button and display an error message indicating the Scoring shoots of the selected Stage
    - When either a Stage or Shooter is selected, this page will refresh it's input
        - If a corresponding record in data model exist, this page will load the value and refresh UI
        - If a corrpesonding record in data model does not exist, initialize this page with value specified in input section
    - Hitting the "Submit" button will write this record to data model
    - The list from data model is displayed in the page and allow add, remove, edit of entries
- Output:
    - entries add, update deleted on the list in data model is written to data presistence layer immediately

## Stage result
- With back button returning to main
- Function:
    - For each stage, calculate hit factor for each shooters, as well as adjusted hit factor
- Output:
    - For each stage
        - Rank the hit factor, highest first, and display a list of {Name, hit factor, adjusted hit factor}

## Overall result
- With back button returning to main menu
- Function:
    - For each shooter, calculate stage point in the stage
        - Find out the highest adjusted hit factor ever scored in that stage
        - stage point for shooter = (adjusted hit factor / highest adjust hit factor ever score d in that stage) x Scoring shotts in that stage x 5
    - For each shooter, add up stage point of all stages as total adjusted stage point
- Output:
    -Rank the total adjusted stage point, highest first, and display a list of {Name, total adjusted stage point}