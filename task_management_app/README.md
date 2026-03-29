# Task Management App

A functional, visually polished Task Management App built with Flutter.

## Features
- **Task Data Model:** Title, Description, Due Date, Status, Blocked By.
- **Main List View:** Displays all tasks. Tasks blocked by uncompleted prerequisites are visually distinct (greyed out and flattened).
- **Task Creation/Edit Screen:** Fully implemented CRUD capabilities.
- **Drafts:** Auto-saves typed text for new tasks to `SharedPreferences`, restoring context if you accidentally minimize or pop the creation screen.
- **Search & Filter:** Search by Title with a Debounced Autocomplete implementation, and filter by Status.
- **Simulated Latency:** 2-second simulated delay on all Task Creations and Updates, complete with a modal loading UI preventing double interaction.

## Technical Track
**Track B**: The Mobile Specialist
- **Frontend:** Flutter & Dart
- **Database:** Local SQLite (`sqflite`)
- **State Management:** `provider`
- **Reactive Extensions:** `rxdart`

## Stretch Goal
**Debounced Autocomplete Search**: 
As the user types in the search bar, the underlying search stream relies on `rxdart`'s `debounceTime` (waiting 300ms) before updating the filter state. Additionally, search matches are dynamically highlighted within the `TaskCard` title for an elevated UX.

## Setup Instructions
1. Ensure you have [Flutter](https://flutter.dev/docs/get-started/install) installed.
2. Navigate into this application folder (`task_management_app`).
3. Run `flutter pub get` to fetch necessary dependencies.
4. Run `flutter run` to launch the application.

## AI Usage Report
- **Orchestration:** I utilized AI (specifically, an advanced agent) to architect the initial `sqflite` database schema, abstracting away SQL boilerplate and standardizing the `TaskItem` data model.
- **Prompts used:** The agent translated the overarching prompt requirements to systematically divide the logic into Models, Providers (State), Database Services, and UI components.
- **Hallucinations / Corrections:** Initially, relying on collection extensions like `firstOrNull` required strict tracking of the Dart SDK version. I corrected this by using conventional iterable patterns (e.g. `where` combined with standard iterators) to guarantee compatibility on older and newer SDKs.
