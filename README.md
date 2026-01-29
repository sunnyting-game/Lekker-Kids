# Lekker Kids

A discontinued multi-tenant daycare management system MVP. This project is preserved as an engineering portfolio piece.

**Tech Stack:** Flutter (client), Firebase (Auth, Firestore, Cloud Functions, Storage)  
**Architecture:** MVVM  
**Status:** Discontinued

---

## Problem & Users

Daycare centers manage attendance, parent communication, and government reporting through a mix of paper forms, spreadsheets, and WhatsApp groups. This creates fragmented records and manual overhead.

Lekker Kids was built to consolidate these workflows into a single system, targeting daycare operators with three user roles:


- **School Admin** – manages teachers and students within a school
- **Teacher** – tracks attendance, uploads photos, creates weekly plans
- **Parent** – views child status, receives photos, communicates with teachers

---

## Technical Architecture

This structure was sufficient for a single-developer project,
but some cross-cutting concerns (e.g. auth state propagation)
were handled pragmatically rather than through strict abstraction.

```
View (Screens) → ViewModel (State) → Repository (Data) → Services (Firebase)
```

**Multi-tenancy** is implemented using Firebase Custom Claims. Each user token contains `schoolId` and `role` claims. Firestore Security Rules validate these claims on every read and write, ensuring tenant isolation at the database layer—not just the UI.

**Role-based access control** uses the same claims mechanism. Sensitive write operations (user creation, role assignment) are centralized in Cloud Functions, which re-validate permissions server-side.

---

## Key Engineering Decisions

### 1. Single-Tenant to Multi-Tenant Migration

The initial prototype was a single-school app. When the scope expanded to support multiple schools under one deployment, the data model needed restructuring.

**Approach:**
- Introduced a hierarchical path: `organizations/{orgId}/schools/{schoolId}/...`
- Embedded `schoolId` in user tokens via Custom Claims
- Added `request.auth.token.schoolId == resource.data.schoolId` checks in Firestore Security Rules

**Limitations:**
- Custom Claims require a server-side call to update. Users must re-authenticate to see claim changes.
- Security Rules complexity increased. Each new collection requires explicit rule writing.

### 2. Solving the N+1 Real-Time Listener Problem

The teacher dashboard initially subscribed to one Firestore listener per student to show real-time status. For a class of 20 students, this created 20 concurrent connections—an N+1 problem that scaled linearly with class size.

**Symptoms:** High Firestore read counts, increased client battery usage, sluggish UI on larger classrooms.

**Fix:** Denormalized the data model. Daily student statuses were aggregated into a single document per classroom-date combination. The dashboard now subscribes to one listener per view, reducing read complexity from O(N) to O(1).

### 3. Operations-First Product Direction

Early user interviews revealed that social features (photo sharing, messaging) were less valued than operational reliability (attendance accuracy, report generation). The product pivoted toward administrative tooling.

**Result:** Built CSV export pipelines via Cloud Functions for monthly government reporting, instead of investing in real-time chat polish.

---

## Trade-offs & Limitations

| Decision | Trade-off |
|----------|-----------|
| Defense-in-depth (UI + Security Rules) | Slower development velocity due to duplicate validation logic |
| Denormalized data model | Write complexity increased; updates require touching multiple documents |
| Firebase-only backend | No relational joins; data modeling requires careful planning |

**Conscious scope cut:** Audit logging was deprioritized. Admin actions are not recorded, which would be required for compliance in a production system.

---

## Project Status

**Discontinued.**

Reasons:
- Government reporting systems in the target market improved, reducing the value of third-party digitization
- Trust barrier: daycare operators were hesitant to share child data with a new vendor
- ROI assessment: Reaching feature parity with established competitors would require resources exceeding projected returns

This was a business decision, not a technical failure. The codebase remains functional.

---

## How to Run

This repository is for architectural reference only.
Live demo access is not publicly available.

If you would like to walk through the system behavior,
please refer to the screenshots and architecture notes.
