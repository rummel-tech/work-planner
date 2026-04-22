# Feature: Goal Management

## Overview
**Slug**: `goal-management`
**Narrative**: *"Define and dominate your ambitions. Whether it's a corporate milestone or a personal side-hustle, keep your 'why' front and center with structured goal tracking."*

## User Value
Goal Management provides the high-level "why" behind every task. By categorizing goals (Corporate, Farm, App Dev, Home Auto), users can maintain a balanced portfolio of ambitions and track progress over time.

## Implementation Details
- **Repository**: [goal_repository.dart](../../lib/src/services/goal_repository.dart)
- **UI Screen**: [goal_form_screen.dart](../../lib/src/screens/goals/goal_form_screen.dart)
- **Data Model**: [goal.dart](../../lib/src/models/goal.dart)

## Verification
- **Integration Test**: `app_test.dart` (Group: `Goal creation flow [goal-management]`)
- **Unit Test**: `goal_test.dart`

## Marketing Highlights
- Unified tracking for corporate and entrepreneurial goals.
- Status-based progression (Not Started -> In Progress -> Completed).
- Target date management with upcoming/overdue alerts.
