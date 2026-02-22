# Vendora — GitHub Backlog (Option A: Clean & Solid)

Repo: `Developer199239/Vendora`

Conventions
- **Milestones** match the roadmap weeks.
- **Epics** are tracking issues labeled `epic`.
- All implementation issues reference an epic in the body.
- Complexity: **S** (≤1 day), **M** (2–3 days), **L** (4–6 days)

---

## Milestones
1. Foundation (Week 1)
2. Auth (Week 2)
3. Product (Week 3)
4. Order (Week 4)
5. Testing (Week 5)
6. Docker & Deployment (Week 6)
7. Documentation & Cleanup (Week 7)

---

## EPICS (create these first)

### Epic
**Title:** [EPIC] Foundation

**Description**
Establish a production-ready Spring Boot 3 / Java 21 modular monolith foundation for Vendora. This includes project structure, configuration, shared infrastructure (error handling, validation), database migrations baseline, and the minimal operational endpoints.

**Requirements & Technical Specifications**
- Spring Boot 3.x, Java 21, Maven
- PostgreSQL + Flyway
- Strict modular packages under `com.vendora.modules.*`

**To-Do List**
- Define dependency set and baseline configuration
- Add global API error contract
- Add base operational endpoints (health)

**Acceptance Criteria**
- Application boots with no errors
- Flyway runs successfully against PostgreSQL
- Base endpoints respond as expected

**Labels:** `epic`, `backend`
**Complexity:** M
**Milestone:** Foundation (Week 1)

---

### Epic
**Title:** [EPIC] Auth

**Description**
Implement authentication and authorization using JWT access tokens and refresh token rotation. Provide CUSTOMER/SELLER/ADMIN roles, admin user management, and secure defaults.

**Requirements & Technical Specifications**
- Spring Security 6 (via Boot 3)
- JWT access + refresh tokens
- Password hashing with BCrypt

**To-Do List**
- Implement auth domain + persistence
- Implement token issuance/validation and role-based access
- Implement admin user management endpoints

**Acceptance Criteria**
- Role-based access enforced across modules
- Refresh token rotation + logout revocation works

**Labels:** `epic`, `security`, `backend`
**Complexity:** L
**Milestone:** Auth (Week 2)

---

### Epic
**Title:** [EPIC] Product

**Description**
Implement product catalog and inventory management with role separation. Customers can browse, sellers manage their own products, admins can moderate.

**Requirements & Technical Specifications**
- JPA entities + Flyway schema
- Validation via Bean Validation

**To-Do List**
- Product and category schema
- Public browse/detail endpoints
- Seller product management endpoints
- Admin moderation endpoint

**Acceptance Criteria**
- Customers see only ACTIVE products
- Sellers can manage only their own products

**Labels:** `epic`, `backend`
**Complexity:** L
**Milestone:** Product (Week 3)

---

### Epic
**Title:** [EPIC] Order

**Description**
Implement order creation and lifecycle with item-level seller fulfillment. Ensure stock checks and atomic stock decrement in a transaction.

**Requirements & Technical Specifications**
- Transactional order creation
- Stock validation
- Snapshot product name + unit price at purchase time

**To-Do List**
- Order schema
- Create/list/detail/cancel for customer
- Seller item fulfillment updates
- Admin override endpoints

**Acceptance Criteria**
- No overselling under concurrency (within Option A constraints)
- Authorization and ownership checks enforced

**Labels:** `epic`, `backend`
**Complexity:** L
**Milestone:** Order (Week 4)

---

### Epic
**Title:** [EPIC] Testing

**Description**
Create a production-quality automated test suite using JUnit 5, Mockito, and Testcontainers.

**Requirements & Technical Specifications**
- JUnit 5 + Mockito
- Testcontainers PostgreSQL

**To-Do List**
- Service unit tests
- Repository integration tests
- Controller/security tests

**Acceptance Criteria**
- Tests run reliably locally and in CI
- Core business rules covered

**Labels:** `epic`, `testing`
**Complexity:** L
**Milestone:** Testing (Week 5)

---

### Epic
**Title:** [EPIC] Docker & Deployment

**Description**
Containerize the app with Docker and provide docker-compose for local and production-like runs.

**Requirements & Technical Specifications**
- Dockerfile (multi-stage)
- docker-compose (app + postgres)

**To-Do List**
- Dockerfile
- compose setup
- env configuration

**Acceptance Criteria**
- `docker compose up` starts app + db
- App connects to db and runs migrations

**Labels:** `epic`, `docker`
**Complexity:** M
**Milestone:** Docker & Deployment (Week 6)

---

### Epic
**Title:** [EPIC] Documentation & Cleanup

**Description**
Write portfolio-grade documentation and do final cleanup for a production-ready impression.

**To-Do List**
- README overhaul
- Architecture explanation
- API docs strategy

**Acceptance Criteria**
- New developer can run locally in ≤10 minutes

**Labels:** `epic`, `docs`
**Complexity:** M
**Milestone:** Documentation & Cleanup (Week 7)

---

## IMPLEMENTATION ISSUES

### Issue
**Title:** Project initialization and strict modular package structure

**Description**
Initialize the `vendora` backend as a Spring Boot 3 / Java 21 Maven project and create the strict package structure required for a modular monolith.

**Requirements & Technical Specifications**
- Spring Boot 3.x, Java 21, Maven
- Dependencies:
  - Spring Web
  - Spring Validation
  - Spring Data JPA
  - Spring Security
  - PostgreSQL Driver
  - Flyway
  - Springdoc OpenAPI
  - (Optional) Lombok

**To-Do List**
- Generate project with Maven wrapper (or document Maven version)
- Create base packages:
  - `com.vendora.common`
  - `com.vendora.config`
  - `com.vendora.modules.auth.{api,domain,service,repository}`
  - `com.vendora.modules.product.{api,domain,service,repository}`
  - `com.vendora.modules.order.{api,domain,service,repository}`
- Add a minimal `HealthController` (or Actuator health)
- Add Springdoc and verify Swagger UI

**Acceptance Criteria**
- Application starts without errors
- Swagger UI loads and shows health endpoint
- Package structure matches the spec exactly

**Technical Notes**
- Keep modules independent; no cross-module repository access.

**Labels:** `backend`, `api`
**Complexity:** M
**Milestone:** Foundation (Week 1)
**Epic:** [EPIC] Foundation

---

### Issue
**Title:** Base configuration (profiles, PostgreSQL, logging)

**Description**
Create production-ready configuration using `application.yml` plus profile overrides for dev/prod.

**Requirements & Technical Specifications**
- PostgreSQL datasource config
- Separate `application-dev.yml` and `application-prod.yml`

**To-Do List**
- Configure datasource via env vars (`SPRING_DATASOURCE_URL`, user, password)
- Disable Hibernate DDL auto (Flyway only)
- Configure logging levels (avoid SQL logging in prod)
- Add `server.error.include-message=never` equivalent behavior via error handler

**Acceptance Criteria**
- App runs with `dev` profile locally and connects to Postgres
- Prod profile fails fast if required secrets are missing

**Labels:** `backend`
**Complexity:** S
**Milestone:** Foundation (Week 1)
**Epic:** [EPIC] Foundation

---

### Issue
**Title:** Global API error handling contract

**Description**
Introduce a consistent JSON error response for validation errors and domain exceptions.

**Requirements & Technical Specifications**
- `@RestControllerAdvice`
- Bean Validation error mapping

**To-Do List**
- Define error response DTO in `com.vendora.common`
- Implement exception handler mapping 400/401/403/404/409/500
- Add at least 2 sample tests (controller slice) validating error response format

**Acceptance Criteria**
- Validation errors return structured `fieldErrors[]`
- Domain exceptions map to the correct HTTP codes

**Labels:** `api`
**Complexity:** S
**Milestone:** Foundation (Week 1)
**Epic:** [EPIC] Foundation

---

### Issue
**Title:** CORS configuration for frontend integration

**Description**
Configure CORS to allow frontend applications to call the API from different origins.

**Requirements & Technical Specifications**
- Environment-based origin configuration
- Dev: allow `http://localhost:3000`, `http://localhost:5173` (React/Vite)
- Prod: restrict to actual frontend domain(s) via `CORS_ALLOWED_ORIGINS` env var

**To-Do List**
- Add CORS configuration bean in `com.vendora.config`
- Configure allowed origins, methods, headers
- Test with browser preflight requests

**Acceptance Criteria**
- Frontend can call API from configured origins
- Other origins are blocked with CORS error

**Technical Notes**
- Use `CorsConfiguration` + `CorsConfigurationSource`

**Labels:** `backend`
**Complexity:** S
**Milestone:** Foundation (Week 1)
**Epic:** [EPIC] Foundation

---

### Issue
**Title:** Spring Boot Actuator + operational endpoints

**Description**
Add Spring Boot Actuator for health checks and operational monitoring.

**Requirements & Technical Specifications**
- Expose `/actuator/health` publicly
- Expose `/actuator/info` publicly
- Secure or disable other endpoints (metrics, env) in prod

**To-Do List**
- Add `spring-boot-starter-actuator` dependency
- Configure in `application.yml`: expose health + info
- Add security rules to allow public access to health
- Add build info to `/actuator/info`

**Acceptance Criteria**
- `/actuator/health` returns UP status
- `/actuator/info` shows app name + version
- Other actuator endpoints require ADMIN role or are disabled

**Labels:** `backend`
**Complexity:** S
**Milestone:** Foundation (Week 1)
**Epic:** [EPIC] Foundation

---

### Issue
**Title:** Flyway baseline migrations (schema init)

**Description**
Create the initial PostgreSQL schema using Flyway migrations.

**Requirements & Technical Specifications**
- Flyway `db/migration` directory
- UUID primary keys
- Monetary values as `NUMERIC(12,2)` (Option A)

**To-Do List**
- Add Flyway configuration
- Create `V1__init.sql` to create:
  - `users`, `roles`, `user_roles`, `refresh_tokens`, `seller_profiles`
  - `categories`, `products`, `product_images`
  - `orders`, `order_items`
- Add indexes and constraints per design

**Acceptance Criteria**
- App starts and creates schema without errors
- `flyway_schema_history` is present

**Labels:** `database`
**Complexity:** L
**Milestone:** Foundation (Week 1)
**Epic:** [EPIC] Foundation

---

### Issue
**Title:** Seed roles and admin bootstrap strategy

**Description**
Seed default roles and define a safe admin bootstrap approach.

**Requirements & Technical Specifications**
- Roles: CUSTOMER, SELLER, ADMIN

**To-Do List**
- Create `V2__seed_roles.sql`
- Document admin bootstrap options:
  - Seed one admin user using env-provided password hash, or
  - Provide a one-time bootstrap endpoint protected by a startup secret (dev-only)

**Acceptance Criteria**
- Roles exist in DB after migration
- Admin bootstrap approach is documented and implementable

**Labels:** `database`, `security`
**Complexity:** S
**Milestone:** Foundation (Week 1)
**Epic:** [EPIC] Foundation

---

### Issue
**Title:** Spring Security baseline + role model

**Description**
Add Spring Security configuration baseline to support module APIs and role-based access.

**Requirements & Technical Specifications**
- Stateless security for APIs
- Role-based authorization rules

**To-Do List**
- Configure security filter chain
- Configure password encoder
- Define role constants and mapping strategy

**Acceptance Criteria**
- Unauthorized requests return 401
- Forbidden role returns 403

**Labels:** `security`
**Complexity:** M
**Milestone:** Auth (Week 2)
**Epic:** [EPIC] Auth

---

### Issue
**Title:** Auth domain + persistence (users, roles, refresh tokens)

**Description**
Implement JPA entities, repositories, and core services for auth.

**Requirements & Technical Specifications**
- Unique email constraint
- Refresh token storage as hash

**To-Do List**
- Implement entities in `modules/auth/domain`
- Implement repositories in `modules/auth/repository`
- Implement services in `modules/auth/service`

**Acceptance Criteria**
- Users can be created with roles
- Refresh token records can be issued/revoked

**Labels:** `security`, `database`
**Complexity:** M
**Milestone:** Auth (Week 2)
**Epic:** [EPIC] Auth

---

### Issue
**Title:** JWT implementation (access + refresh rotation)

**Description**
Implement JWT access token creation/validation and refresh token rotation.

**Requirements & Technical Specifications**
- Access token: short TTL
- Refresh token: longer TTL, rotated on refresh
- Store refresh tokens hashed

**To-Do List**
- Implement JWT utility + signing key config
- Implement authentication filter extracting Bearer token
- Implement refresh token rotation logic (revoke old, issue new)

**Acceptance Criteria**
- Refresh rotates token and invalidates old one
- Expired/revoked refresh tokens are rejected

**Labels:** `security`
**Complexity:** L
**Milestone:** Auth (Week 2)
**Epic:** [EPIC] Auth

---

### Issue
**Title:** Auth REST API (register/login/refresh/logout/me/change-password)

**Description**
Expose the auth endpoints with DTO validation and correct error codes.

**Requirements & Technical Specifications**
- DTOs in `modules/auth/api`
- Validation annotations

**To-Do List**
- Implement controllers and request/response DTOs
- Ensure consistent error handling
- Add Swagger annotations where helpful

**Acceptance Criteria**
- All endpoints function end-to-end against Postgres
- `GET /me` returns current user and roles

**Labels:** `api`, `security`
**Complexity:** L
**Milestone:** Auth (Week 2)
**Epic:** [EPIC] Auth

---

### Issue
**Title:** Admin user management API (list users, roles, activate/deactivate)

**Description**
Implement admin endpoints to manage users.

**Requirements & Technical Specifications**
- Admin-only endpoints
- Pagination for listing

**To-Do List**
- Implement list/search users
- Implement update status
- Implement set roles
- Add tests for authz

**Acceptance Criteria**
- Only ADMIN can access
- Role changes reflect in token claims after re-login

**Labels:** `api`, `security`
**Complexity:** M
**Milestone:** Auth (Week 2)
**Epic:** [EPIC] Auth

---

### Issue
**Title:** Seller profile management APIs (CRUD)

**Description**
Allow sellers to create and manage their seller profile with display name and contact info.

**Requirements & Technical Specifications**
- SELLER-only access
- Endpoints: POST, GET, PUT `/api/v1/seller/profile`
- Validation: display name required (max 120 chars)

**To-Do List**
- Implement `SellerProfileController` in `modules/auth/api`
- Implement `SellerProfileService`
- Add request/response DTOs
- Enforce one profile per user
- Add tests for ownership enforcement

**Acceptance Criteria**
- SELLER can create profile once
- SELLER can view/update own profile
- Non-sellers cannot access endpoint

**Technical Notes**
- Profile creation can happen after registration or on-demand

**Labels:** `api`, `security`
**Complexity:** M
**Milestone:** Auth (Week 2)
**Epic:** [EPIC] Auth

---

### Issue
**Title:** Product domain + persistence (categories, products, images)

**Description**
Implement the product module JPA entities and repositories.

**Requirements & Technical Specifications**
- Product status (DRAFT/ACTIVE/INACTIVE)
- Stock non-negative

**To-Do List**
- Implement entities in `modules/product/domain`
- Implement repositories in `modules/product/repository`
- Add basic service interfaces in `modules/product/service`

**Acceptance Criteria**
- Products can be persisted with category and images

**Labels:** `database`, `backend`
**Complexity:** M
**Milestone:** Product (Week 3)
**Epic:** [EPIC] Product

---

### Issue
**Title:** Public product APIs (browse, detail, search/filter)

**Description**
Expose customer-facing product read endpoints.

**Requirements & Technical Specifications**
- Paging and sorting
- Filter by category and price range

**To-Do List**
- Implement `GET /api/v1/products`
- Implement `GET /api/v1/products/{id}`
- Validate that only ACTIVE products are visible

**Acceptance Criteria**
- Returns paged results
- Inactive products are not accessible

**Labels:** `api`
**Complexity:** M
**Milestone:** Product (Week 3)
**Epic:** [EPIC] Product

---

### Issue
**Title:** Seller product management APIs (create/update/list/activate)

**Description**
Allow sellers to manage their own products, including stock.

**Requirements & Technical Specifications**
- Ownership enforcement
- Validation for price/stock/name

**To-Do List**
- Implement seller endpoints under `/api/v1/seller/products`
- Enforce seller ownership checks in service layer
- Ensure module boundaries: no auth repository access from product module

**Acceptance Criteria**
- Seller can CRUD own products
- Seller cannot modify others’ products

**Labels:** `api`, `security`
**Complexity:** L
**Milestone:** Product (Week 3)
**Epic:** [EPIC] Product

---

### Issue
**Title:** Admin product moderation API (activate/deactivate)

**Description**
Allow admins to deactivate or reactivate any product.

**To-Do List**
- Implement admin endpoint to change status
- Add audit-friendly logging (no sensitive data)

**Acceptance Criteria**
- Only ADMIN can change status

**Labels:** `api`, `security`
**Complexity:** S
**Milestone:** Product (Week 3)
**Epic:** [EPIC] Product

---

### Issue
**Title:** Category management APIs (CRUD)

**Description**
Implement category management for admins and public listing for customers.

**Requirements & Technical Specifications**
- Public: `GET /api/v1/categories` (list all)
- Admin: `POST/PUT/DELETE /api/v1/admin/categories`
- Validation: unique category name

**To-Do List**
- Implement `CategoryController` (public) and `AdminCategoryController`
- Implement `CategoryService` + `CategoryCommandService`
- Add category CRUD in `modules/product/service`
- Prevent deletion if products reference the category (or cascade set null)
- Add tests

**Acceptance Criteria**
- Public can list all categories
- Only ADMIN can create/update/delete
- Cannot delete category with active products (or handle gracefully)

**Technical Notes**
- Categories reference is already in DB schema

**Labels:** `api`, `database`
**Complexity:** M
**Milestone:** Product (Week 3)
**Epic:** [EPIC] Product

---

### Issue
**Title:** Order domain + persistence (orders + order_items)

**Description**
Implement order entities and repositories and ensure constraints align with the database design.

**Requirements & Technical Specifications**
- Store shipping address snapshot on order
- Store product name + unit price snapshot on items

**To-Do List**
- Implement entities in `modules/order/domain`
- Implement repositories in `modules/order/repository`
- Define status enums and allowed transitions

**Acceptance Criteria**
- Orders with items can be persisted and loaded

**Labels:** `database`, `backend`
**Complexity:** M
**Milestone:** Order (Week 4)
**Epic:** [EPIC] Order

---

### Issue
**Title:** Order creation transaction (stock validation + atomic decrement)

**Description**
Implement order creation logic that validates stock and decrements inventory atomically.

**Requirements & Technical Specifications**
- Single DB transaction
- Prevent overselling using row-level locking (JPA pessimistic lock) or safe update queries

**To-Do List**
- Add `OrderCommandService` create order
- Query products and validate status + stock
- Decrement stock safely
- Persist order + items with snapshots

**Acceptance Criteria**
- Cannot order inactive product
- Cannot order more than available stock

**Labels:** `backend`
**Complexity:** L
**Milestone:** Order (Week 4)
**Epic:** [EPIC] Order

---

### Issue
**Title:** Customer order APIs (create/list/detail/cancel)

**Description**
Expose customer endpoints for orders with strict ownership.

**Requirements & Technical Specifications**
- CUSTOMER-only access
- Ownership checks

**To-Do List**
- Implement endpoints under `/api/v1/orders`
- Implement cancel rules (only PENDING/CONFIRMED)

**Acceptance Criteria**
- Customer can only see their own orders
- Cancel transitions status correctly

**Labels:** `api`, `security`
**Complexity:** M
**Milestone:** Order (Week 4)
**Epic:** [EPIC] Order

---

### Issue
**Title:** Seller order view APIs + fulfillment status updates

**Description**
Allow sellers to view orders containing their items and update item fulfillment status.

**Requirements & Technical Specifications**
- SELLER-only access
- Seller can only access their own order items

**To-Do List**
- Implement endpoints under `/api/v1/seller/orders`
- Implement allowed fulfillment transitions

**Acceptance Criteria**
- Seller sees only their item lines
- Updates rejected if seller doesn’t own item

**Labels:** `api`, `security`
**Complexity:** M
**Milestone:** Order (Week 4)
**Epic:** [EPIC] Order

---

### Issue
**Title:** Admin order APIs (list all, status override)

**Description**
Allow admins to list all orders and override order status when required.

**To-Do List**
- Implement admin endpoints under `/api/v1/admin/orders`
- Validate allowed status transitions (or document override power)

**Acceptance Criteria**
- Only ADMIN can access

**Labels:** `api`, `security`
**Complexity:** S
**Milestone:** Order (Week 4)
**Epic:** [EPIC] Order

---

### Issue
**Title:** Unit tests for service layer (Mockito)

**Description**
Add unit tests for core business rules across auth/product/order services.

**Requirements & Technical Specifications**
- JUnit 5
- Mockito

**To-Do List**
- Auth: password change, refresh rotation
- Product: ownership checks
- Order: cancel rules, totals, stock validation

**Acceptance Criteria**
- Core service rules covered with positive and negative tests

**Labels:** `testing`
**Complexity:** M
**Milestone:** Testing (Week 5)
**Epic:** [EPIC] Testing

---

### Issue
**Title:** Integration tests with Testcontainers PostgreSQL

**Description**
Use Testcontainers to validate migrations, repositories, and transactional behavior.

**Requirements & Technical Specifications**
- Testcontainers Postgres
- Flyway migrations run on startup

**To-Do List**
- Configure reusable Postgres container
- Add repository tests (`@DataJpaTest`) as needed
- Add at least one order creation integration test verifying stock decrement

**Acceptance Criteria**
- Tests pass consistently without local Postgres dependency

**Labels:** `testing`, `database`
**Complexity:** L
**Milestone:** Testing (Week 5)
**Epic:** [EPIC] Testing

---

### Issue
**Title:** Controller/security tests (MockMvc)

**Description**
Add controller tests validating authn/authz, validation errors, and happy paths.

**To-Do List**
- Add tests for 401/403 behaviors
- Add tests for request validation (400)
- Add tests for role restrictions per endpoint group

**Acceptance Criteria**
- Key endpoints have security regression coverage

**Labels:** `testing`, `security`
**Complexity:** L
**Milestone:** Testing (Week 5)
**Epic:** [EPIC] Testing

---

### Issue
**Title:** Dockerfile (multi-stage) for vendora backend

**Description**
Create a production-ready Dockerfile for building and running the service.

**Requirements & Technical Specifications**
- Multi-stage build
- Runtime image with Java 21

**To-Do List**
- Add Dockerfile at repo root
- Ensure image starts with correct profile and env vars

**Acceptance Criteria**
- Image builds successfully
- Container starts and serves health endpoint

**Labels:** `docker`
**Complexity:** S
**Milestone:** Docker & Deployment (Week 6)
**Epic:** [EPIC] Docker & Deployment

---

### Issue
**Title:** docker-compose (app + postgres) for local and prod-like runs

**Description**
Provide docker-compose for running backend and PostgreSQL locally.

**Requirements & Technical Specifications**
- Persistent volume for Postgres
- Env var-based configuration

**To-Do List**
- Add `docker-compose.yml`
- Add `.env.example`
- Validate that Flyway runs on container startup

**Acceptance Criteria**
- `docker compose up` brings up both services successfully

**Labels:** `docker`
**Complexity:** S
**Milestone:** Docker & Deployment (Week 6)
**Epic:** [EPIC] Docker & Deployment

---

### Issue
**Title:** GitHub Actions CI pipeline (test + build)

**Description**
Set up GitHub Actions workflow to run tests on pull requests and build Docker image on push to main.

**Requirements & Technical Specifications**
- GitHub Actions workflow file
- Trigger: on push to main, on pull request
- Jobs: test (Maven + Testcontainers), build Docker image

**To-Do List**
- Create `.github/workflows/ci.yml`
- Configure Java 21 setup
- Run `mvn clean verify` with Testcontainers
- Build Docker image (optional: push to registry)
- Add status badge to README

**Acceptance Criteria**
- Tests run automatically on PR
- Docker image builds on main push
- Failures block PR merge

**Labels:** `ci-cd`
**Complexity:** M
**Milestone:** Docker & Deployment (Week 6)
**Epic:** [EPIC] Docker & Deployment

---

### Issue
**Title:** Documentation: README + architecture + API docs strategy

**Description**
Write portfolio-grade documentation and ensure new developers can run and test the project quickly.

**To-Do List**
- Add README sections: overview, stack, architecture, run locally, run tests, deploy
- Document module boundaries and cross-module service interface rule
- Document JWT flow (access/refresh)

**Acceptance Criteria**
- Fresh machine setup doable using README

**Labels:** `docs`
**Complexity:** M
**Milestone:** Documentation & Cleanup (Week 7)
**Epic:** [EPIC] Documentation & Cleanup
