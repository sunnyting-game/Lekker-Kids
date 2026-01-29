# Lekker Kids: Engineering Retrospective

**Project Type**: Multi-tenant Daycare Management SaaS
**Role**: Junior Full-stack Engineer
**Tech Stack**: Flutter, Firebase (Auth, Firestore, Functions, Storage), MVVM

---

### Project Positioning & Architecture
Developed a comprehensive operational system to digitize administrative workflows (attendance, government reporting, communication) for early childhood education centers.
*   **Architecture**: Adopted **MVVM** architecture to strictly separate UI code from business logic, ensuring testability and maintainability.
*   **Multi-Tenancy**: Engineered a scalable SaaS infrastructure allowing multiple schools to operate in a single environment with strict data isolation.
*   **Security**: Implemented **Role-Based Access Control (RBAC)** using Firebase Custom Claims (`schoolId`, `role`) and Firestore Security Rules, ensuring data security at the database level.

### Key Engineering Decisions & Challenges

#### 1. Solving the N+1 Stream Problem (Scalability)
*   **Problem**: Initially, the teacher dashboard subscribed to individual real-time streams for each student to track status. For a class of 20+ students, this created an **N+1 connection issue**, leading to excessive read operations and client-side battery drain.
*   **Engineering Judgment**: Recognized that client-side joins are inefficient for real-time dashboards.
*   **Solution**: **Data Denormalization**. Redesigned the data model to aggregate daily statuses or utilized efficient "IN" queries/Composite Indexes to batch fetch data. Optimized Firestore listeners to subscribe to collection-level updates rather than document-level.
*   **Outcome**: Reduced dashboard reads from **O(N)** to **O(1)** per view refresh, significantly lowering Firebase costs and improving UI responsiveness.

#### 2. Single-Tenant to Multi-Tenant Migration (Architecture)
*   **Context**: The product needed to pivot from a single-school prototype to a white-label SaaS platform.
*   **Challenge**: Ensuring that a Teacher in School A could never access data from School B, without deploying separate backend instances.
*   **Solution**: Implemented **Custom Claims** in Firebase Auth to embed `tenant_id` directly into the user's secure token. Configured Firestore Security Rules to validate `request.auth.token.schoolId == resource.data.schoolId` for every read/write.
*   **Result**: Achieved strict tenant isolation at the infrastructure layer. Even if the frontend code had a bug, the database rules would prevent data leakage.

#### 3. Operations-First Design (Product Engineering)
*   **Assumption vs Reality**: Initial user interviews revealed that "fancy" social features were less valuable than reliable "administrative" tools.
*   **Action**: Pivoted focus to **Data Consistency** and **Automated Reporting**.
*   **Implementation**: built robust CSV export pipelines using Cloud Functions to handle large dataset aggregations for monthly usage reports, adhering to government standards.

### Engineering Mindset
*   **Goal-Oriented Design**: **Goal -> Solution**. Avoided implementing features just because they are "standard" (e.g., complex chat) unless they solved a specific operational pain point (e.g., direct parent-teacher communication for incident reporting).
*   **Root Cause Analysis**: When encountering bugs, focused on architectural root causes (e.g., "Why is the stream lagging?") rather than applying superficial hotfixes.
*   **Pipeline Optimization**: Built an efficient photo upload pipeline (Picker → Local Compression → Storage → Cloud Function Trigger) to handle high-resolution media seamlessly.

### Project Status: Discontinued
**Why?**
*   **Market Dynamics**: Government reporting systems improved significantly, reducing the core value proposition of manual administrative digitisation.
*   **Privacy Trust Barrier**: Identified significant friction in user adoption due to data privacy concerns with small/new vendors vs. established competitors.
*   **ROI Assessment**: Concluded that achieving feature parity with mature incumbents would require resources exceeding the projected specialized market cap. Decided to sunset the project to focus on high-leverage learning.

### What This Project Demonstrates
*   **Engineering Capability**: Successfully architected and deployed a secure, multi-tenant SaaS solution from scratch.
*   **Product Lifecycle Management**: Managed the full cycle from requirement gathering and architecture design to user feedback analysis and strategic deprecation.
*   **Business Maturity**: Demonstrated the ability to detach emotionally from code to make objective business decisions (avoiding sunk cost fallacy).

### AI-Assisted Development (Tooling)

*   **Used AI-assisted IDEs as a productivity tool for boilerplate generation, refactoring suggestions, and syntax validation.
*   **Treated AI output as a first draft, with all architectural decisions, data modeling, and security logic designed and reviewed manually.
*   **Applied root-cause analysis when AI-generated solutions masked underlying issues (e.g., performance or data consistency problems).
*   **Found that providing logs, error outputs, and constraints to AI produced more reliable debugging results than high-level descriptions.
