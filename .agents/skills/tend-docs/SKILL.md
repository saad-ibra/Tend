---
name: tend-docs
description: >-
  MANDATORY FOR TEND PROJECT: Automatically records, updates, and consolidates all architecture decisions,
  data models, business logic algorithms, and proposed REST API contracts for every feature into DOCUMENTATION.md.
---

# Tend Project Documentation Skill

This skill enforces continuous, consolidated documentation for the Tend Flutter project.

## Core Rule
**Never scatter documentation across random notes or markdown files.** All feature specs, data models, state management logic, business rules, and API contracts MUST be consolidated into:
`DOCUMENTATION.md` at the root of the project.

---

## Workflow for New Features or Changes

Whenever a feature or structural change is implemented in the Tend application:

### 1. Update Domain Models Section
Document every new or modified model in Section 2:
* Class name and purpose
* Fields table (Field, Type, Description, Nullability)
* Business rules or validation methods (e.g., recurrence rules, calculation helpers)
* Clean separation of entity definitions from event/history records

### 2. Document Business Logic & Algorithms
Document algorithms in Section 3:
* Step-by-step description of computation (e.g. streaks, aggregation, score calculation)
* Edge case handling (e.g., weekends, non-scheduled intervals, timezone handling)

### 3. Maintain Proposed JSON REST API Contracts
Document endpoints in Section 4:
* HTTP Method and Endpoint path (e.g. `POST /api/v1/habits`)
* Headers / Query parameters
* Request payload example in strict JSON format
* Response payload example in strict JSON format
* HTTP status codes (200, 201, 204, 400, 404, etc.)

### 4. Record Architecture & Persistence Updates
Document changes in Section 1 or 5:
* Layer placement (Model, Repository, Controller, Widget, Screen)
* Storage keys, serialization formats, or schema migration strategies

### 5. Update Versioning & Changelog
Update `pubspec.yaml` and append the new version entry to the Changelog table in `DOCUMENTATION.md`.
