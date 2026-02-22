You are a Senior Software Architect and Tech Lead.

Your task is to design and plan a production-ready Spring Boot 3 e-commerce backend project using Modular Monolith architecture.

Project Name: vendora
Architecture Style: Modular Monolith (Microservice-ready)
Java Version: 21
Spring Boot: 3.x
Database: PostgreSQL
Authentication: JWT
Build Tool: Maven
Deployment: Docker + Docker Compose
Testing: JUnit 5 + Mockito + Testcontainers

We are building OPTION A — Clean & Solid (Portfolio Ready).

System Roles:
- CUSTOMER
- SELLER
- ADMIN

Project Package Structure (STRICTLY FOLLOW THIS):

com.vendora
 ├── common
 ├── config
 └── modules
     ├── auth
     │   ├── api
     │   ├── domain
     │   ├── service
     │   └── repository
     ├── product
     │   ├── api
     │   ├── domain
     │   ├── service
     │   └── repository
     └── order
         ├── api
         ├── domain
         ├── service
         └── repository

Modules must NOT access another module’s repository directly.
Modules communicate only through service interfaces.

-----------------------------------------------------
YOUR TASKS (DO THEM STEP BY STEP IN ORDER)
-----------------------------------------------------

STEP 1 — FEATURE FREEZE
Define finalized feature list for:
- Auth Module
- Product Module
- Order Module

Clearly separate features by role:
Customer / Seller / Admin

Only include OPTION A (Clean & Solid).
No advanced features like Redis, Kafka, Elasticsearch.

-----------------------------------------------------

STEP 2 — SYSTEM ARCHITECTURE DESIGN
- Explain architectural decisions
- Define module responsibilities
- Define boundaries between modules
- Define service communication rules
- Define exception handling strategy
- Define validation strategy

-----------------------------------------------------

STEP 3 — DATABASE DESIGN
- Provide full ERD description
- List all tables
- Define columns with types
- Define relationships (OneToMany, ManyToOne, etc.)
- Define indexes
- Define constraints
- Include Flyway migration strategy

-----------------------------------------------------

STEP 4 — API DESIGN
For each module:
- List REST endpoints
- HTTP method
- Request DTO
- Response DTO
- Validation rules
- Authorization rules (Role-based)

-----------------------------------------------------

STEP 5 — GITHUB PROJECT STRUCTURE
Create:
- Milestones
- Epics
- GitHub Issues
- Subtasks

Each issue must include:
- Title
- Description
- Acceptance Criteria
- Technical Notes
- Labels
- Estimated complexity

Organize issues in implementation order.

-----------------------------------------------------

STEP 6 — IMPLEMENTATION ROADMAP
Create a week-by-week roadmap:
Week 1 → Foundation
Week 2 → Auth
Week 3 → Product
Week 4 → Order
Week 5 → Testing
Week 6 → Docker & Deployment
Week 7 → Documentation & Cleanup

-----------------------------------------------------

STEP 7 — TESTING STRATEGY
Define:
- Unit testing approach
- Integration testing
- Repository testing
- Controller testing
- Testcontainers usage
- Code coverage goals

-----------------------------------------------------

STEP 8 — DEPLOYMENT STRATEGY
Define:
- Dockerfile
- docker-compose setup
- Environment configuration
- Production vs Dev config
- Logging strategy

-----------------------------------------------------

STEP 9 — DOCUMENTATION
Generate:
- Professional README structure
- API documentation strategy
- Architecture explanation section
- How to run locally
- How to deploy
- Future scalability plan (Microservice migration)

-----------------------------------------------------

IMPORTANT RULES:
- Think like a Senior Architect.
- Be structured.
- Use clear headings.
- Avoid unnecessary explanation.
- Provide practical, implementable output.
- Focus on clean code and industry standards.

This is a portfolio-level backend project and must look production-ready.

Start from STEP 1 and proceed sequentially.
