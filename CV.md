

Daycare Multi-Tenant Admin & Workflow System (MVP)

Tech Stack: Flutter · Firebase (Auth, Firestore, Cloud Functions, Storage)
Architecture: MVVM · Role-Based Access Control · Multi-Tenant Design

Project Overview

Designed and built a multi-tenant admin and workflow system for daycare centers to replace manual, paper-based, and messaging-driven (SMS / WhatsApp) administrative processes.
The system focuses on attendance tracking, role-based workflows, document handling, and parent communication with strict tenant-level data isolation.

Target Users

Super Admin (managing multiple organizations)

School Admin

Teacher

Parent

Core Engineering Challenges & Decisions
1. Single-Tenancy → Multi-Tenancy Migration

Problem:
The initial MVP was built as a single-tenant app focused on white-labeled teacher–parent communication.
After product validation, the scope shifted to operational and administrative workflows across multiple daycare centers, which required a multi-tenant architecture to support centralized management and onboarding.

Solution:

Introduced tenant-isolated data model:
organizations/{orgId}/schools/{schoolId}

Implemented Firebase Auth Custom Claims for role and tenant context

Enforced tenant boundaries at Firestore Security Rules level

Centralized sensitive write operations via Cloud Functions

Trade-offs:

Increased authentication and rule complexity

Additional validation logic required in backend functions

Outcome:

Clear and enforceable tenant isolation

Secure scalability to multiple organizations

Standardized onboarding via invitation tokens

2. Role-Based Admin Workflow Design

Problem:
Daycare operations involve multiple roles with overlapping responsibilities, increasing risk of permission misuse and data leakage.

Solution:

Defined four explicit roles: Super Admin, Admin, Teacher, Parent

All write operations validated through Cloud Functions with role checks

Read access strictly controlled via Firestore Security Rules

Trade-offs:

Slower initial development velocity

Higher testing and maintenance cost

Outcome:

Predictable permission boundaries

New roles can be added without refactoring core data structures

Major Bug & Key Lesson
N+1 Real-Time Stream Issue

Issue:
Initial implementation created one Firestore real-time listener per student for teacher status tracking, leading to a classic N+1 problem.

Discovery:
Identified during code review when listener count scaled linearly with student count, posing performance and billing risks.

Fix:

Refactored to a denormalized data model

Aggregated daily student status into a single document

Reduced number of active listeners per view

Lesson Learned:
Real-time updates should be designed around view requirements, not raw data granularity.

Explicit Engineering Trade-offs

Prioritized data schema and system correctness over UI polish

Chose eventual consistency for admin reporting instead of real-time sync

Intentionally limited feature scope to avoid premature optimization

Design Principle: Maintainability > Feature completeness

Why the MVP Was Discontinued

Existing mature systems already dominate the market

High switching costs for daycare operators

Projected ROI could not justify continued development effort

This was a deliberate business decision, not a technical failure.

What This Project Demonstrates

Hands-on experience designing multi-tenant systems

Strong understanding of authentication, authorization, and data isolation

Practical experience identifying and fixing scalability issues

Ability to balance technical decisions with business constraints

Potential Future Improvements

Audit logs for admin actions

Optimized reporting and export pipelines

Feature flags for tenant-level rollout control