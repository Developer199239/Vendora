## STEP 1 — FEATURE FREEZE (OPTION A: Clean & Solid)

### Auth Module
**CUSTOMER**
- Register account (email + password)
- Login (JWT access token + refresh token)
- Refresh token (rotate refresh tokens)
- Logout (invalidate refresh token)
- View own profile (`/me`)
- Change password

**SELLER**
- Same as CUSTOMER
- Create seller profile (display name, phone)
- View/update own seller profile

**ADMIN**
- Create admin user (bootstrap via DB/env, then managed in-app)
- List/search users
- Activate/deactivate users
- Assign/remove roles (CUSTOMER/SELLER/ADMIN)
- Force logout (invalidate all refresh tokens for a user)

---

### Product Module
**CUSTOMER**
- Browse products (paged list)
- View product detail
- Search by name (simple query param)
- Filter by category + price range (basic query params)
- List all categories (for filter dropdowns)

**SELLER**
- Create product (draft/active)
- Update own product (name, description, price, category, images)
- Manage inventory stock for own product
- List own products (paged)
- Soft-deactivate/reactivate own products

**ADMIN**
- View all products (including inactive)
- Deactivate/reactivate any product (moderation)
- Create/update/delete categories

---

### Order Module
**CUSTOMER**
- Create order (items + shipping address snapshot)
- View order detail (own orders only)
- List own orders (paged)
- Cancel order (only if still `PENDING/CONFIRMED`)

**SELLER**
- View orders that include seller’s items (paged)
- View order item lines for own products
- Update fulfillment status for own order items (`READY_TO_SHIP` → `SHIPPED`) *(kept minimal; no carrier integration)*

**ADMIN**
- View all orders
- Update overall order status (override/resolve)
- Cancel/refund flag (internal bookkeeping only; no payment gateway)

---

## STEP 2 — SYSTEM ARCHITECTURE DESIGN

### Architectural decisions
- **Modular Monolith**: one Spring Boot app + one DB, split into **strict modules** under `com.vendora.modules.*`.
- **Microservice-ready boundaries**: each module owns its domain model, persistence, and business rules; cross-module interaction only via **service interfaces**.
- **Hexagonal-ish inside each module** (lightweight):
  - `api`: controllers + request/response DTOs + API mappers
  - `domain`: entities, value objects, domain exceptions, enums
  - `repository`: Spring Data JPA repositories (module-private usage)
  - `service`: business services + module “facade” interfaces exposed to other modules

### Module responsibilities
- **auth**
  - Identity: users, roles, credentials, refresh tokens
  - JWT issuance/validation, password hashing, role checks
- **product**
  - Product catalog: product lifecycle, categories, pricing, images
  - Inventory (stock) management
- **order**
  - Order creation, order totals, order status
  - Per-item fulfillment statuses (seller-scoped)

### Boundaries between modules (hard rules)
- A module **must not** import/use another module’s `repository` package.
- Cross-module calls go through **service interfaces only**:
  - Example: `order` calls `product.service.ProductQueryService` (interface) to validate product availability/price at order time.
  - Example: `product` calls `auth.service.UserQueryService` to verify seller exists/active.
- DTOs are **module-local** (no shared DTOs across modules). Only primitives/value objects cross boundaries.

### Service communication rules (practical)
- Expose **two interface types per module** (still inside that module’s `service` package):
  - `*CommandService` for state changes (transactional)
  - `*QueryService` for reads (read-only where possible)
- Keep module-to-module calls **synchronous in-process** (no messaging).
- Avoid cyclic dependencies:
  - `order` depends on `auth` (customer identity) and `product` (catalog snapshot)
  - `product` depends on `auth` (seller identity)
  - `auth` depends on nobody

### Exception handling strategy
- Define **domain exceptions** per module in `domain` (e.g., `ProductNotFoundException`, `OrderNotCancelableException`).
- Map exceptions centrally via **global `@RestControllerAdvice`** (in `com.vendora.common`):
  - 400: validation failures, illegal state transitions
  - 401: unauthenticated
  - 403: role/ownership violations
  - 404: entity not found (do not leak cross-tenant data)
  - 409: conflicts (unique constraints, stock conflicts)
  - 500: unexpected errors (generic message)
- Use a consistent error response shape:
  - `timestamp`, `status`, `errorCode`, `message`, `path`, `fieldErrors[]` (for validation)

### Validation strategy
- **API layer**: Bean Validation on request DTOs (`@NotBlank`, `@Email`, `@Positive`, `@Size`, etc.).
- **Service/domain layer**: enforce invariants and state transitions (e.g., order status changes).
- Validate **ownership** (seller can only modify own products; customer can only view own orders) in service layer, not controllers.

### CORS strategy
- Configure allowed origins via environment variable (`CORS_ALLOWED_ORIGINS`)
- Dev: allow `http://localhost:3000,http://localhost:5173` (React/Vite)
- Prod: restrict to actual frontend domain(s)

### Operational endpoints strategy
- Include Spring Boot Actuator for `/actuator/health`, `/actuator/info`
- Secure other actuator endpoints (metrics, env) for ADMIN-only or disable in prod

### Image storage strategy (Option A)
- Product images: **URL-only** (no upload endpoint)
- Sellers provide externally hosted image URLs (CDN, Cloudinary, etc.)
- Validate URLs in DTOs (format, max length)
- **Future enhancement**: add upload endpoint with local/S3 storage

### Email strategy (Option A)
- **No email integration** for this phase
- No forgot password / email verification
- **Future enhancement**: SMTP + forgot password flow

### Soft delete strategy
- **Users**: `status=DISABLED` (never hard-deleted, compliance/audit)
- **Products**: `status=INACTIVE` (soft deactivation)
- **Orders**: never deleted (permanent record for legal/accounting)
- **Categories**: soft delete with `deleted_at` timestamp (optional; can be hard-deleted if no products reference)

### Order status state machine
- `PENDING` → `CONFIRMED` (payment verified / admin approval)
- `CONFIRMED` → `PARTIALLY_SHIPPED` (some items shipped)
- `CONFIRMED` → `SHIPPED` (all items shipped)
- `PARTIALLY_SHIPPED` → `SHIPPED`
- `PENDING/CONFIRMED` → `CANCELLED` (customer or admin)
- **No backwards transitions** except cancellation

---

## STEP 3 — DATABASE DESIGN (PostgreSQL) + Flyway

### ERD (text description)
- `users` have many `roles` via `user_roles`.
- `users` (SELLER role) can own many `products`.
- `products` have many `product_images`.
- `orders` belong to a `customer` (user).
- `orders` have many `order_items`; each item references a product and also stores seller ownership snapshot.

### Tables (columns, types, constraints, indexes)

#### `users`
- `id` UUID PK
- `email` VARCHAR(255) NOT NULL UNIQUE
- `password_hash` VARCHAR(255) NOT NULL
- `status` VARCHAR(30) NOT NULL  *(ACTIVE, DISABLED)*
- `created_at` TIMESTAMPTZ NOT NULL
- `updated_at` TIMESTAMPTZ NOT NULL
**Indexes**
- unique index on `email`

#### `roles`
- `id` SMALLINT PK (or UUID, but SMALLINT is fine)
- `name` VARCHAR(30) NOT NULL UNIQUE  *(CUSTOMER, SELLER, ADMIN)*

#### `user_roles`
- `user_id` UUID NOT NULL FK → `users(id)` ON DELETE CASCADE
- `role_id` SMALLINT NOT NULL FK → `roles(id)` ON DELETE RESTRICT
PK: (`user_id`, `role_id`)
**Indexes**
- index on `role_id`

#### `refresh_tokens`
- `id` UUID PK
- `user_id` UUID NOT NULL FK → `users(id)` ON DELETE CASCADE
- `token_hash` VARCHAR(255) NOT NULL UNIQUE
- `expires_at` TIMESTAMPTZ NOT NULL
- `revoked_at` TIMESTAMPTZ NULL
- `created_at` TIMESTAMPTZ NOT NULL
**Indexes**
- index on `user_id`
- unique index on `token_hash`

#### `seller_profiles`
- `user_id` UUID PK FK → `users(id)` ON DELETE CASCADE
- `display_name` VARCHAR(120) NOT NULL
- `phone` VARCHAR(30) NULL
- `created_at` TIMESTAMPTZ NOT NULL
- `updated_at` TIMESTAMPTZ NOT NULL

#### `categories`
- `id` UUID PK
- `name` VARCHAR(120) NOT NULL UNIQUE
- `created_at` TIMESTAMPTZ NOT NULL

#### `products`
- `id` UUID PK
- `seller_id` UUID NOT NULL FK → `users(id)` ON DELETE RESTRICT
- `category_id` UUID NOT NULL FK → `categories(id)` ON DELETE RESTRICT
- `name` VARCHAR(200) NOT NULL
- `description` TEXT NULL
- `price_amount` NUMERIC(12,2) NOT NULL CHECK (`price_amount` > 0)
- `currency` CHAR(3) NOT NULL DEFAULT 'USD'
- `status` VARCHAR(30) NOT NULL *(DRAFT, ACTIVE, INACTIVE)*
- `stock_quantity` INTEGER NOT NULL CHECK (`stock_quantity` >= 0)
- `created_at` TIMESTAMPTZ NOT NULL
- `updated_at` TIMESTAMPTZ NOT NULL
**Indexes**
- index on `seller_id`
- index on `category_id`
- index on (`status`, `created_at`)
- optional search index: `GIN` on `to_tsvector('simple', name)` *(still “Option A” acceptable, but can be skipped)*

#### `product_images`
- `id` UUID PK
- `product_id` UUID NOT NULL FK → `products(id)` ON DELETE CASCADE
- `url` TEXT NOT NULL
- `sort_order` INTEGER NOT NULL DEFAULT 0
**Indexes**
- index on `product_id`
**Constraints**
- unique (`product_id`, `sort_order`)

#### `orders`
- `id` UUID PK
- `customer_id` UUID NOT NULL FK → `users(id)` ON DELETE RESTRICT
- `status` VARCHAR(30) NOT NULL *(PENDING, CONFIRMED, CANCELLED, PARTIALLY_SHIPPED, SHIPPED)*
- `subtotal_amount` NUMERIC(12,2) NOT NULL
- `shipping_amount` NUMERIC(12,2) NOT NULL DEFAULT 0
- `total_amount` NUMERIC(12,2) NOT NULL
- `currency` CHAR(3) NOT NULL
- `ship_to_name` VARCHAR(200) NOT NULL
- `ship_to_phone` VARCHAR(30) NULL
- `ship_to_address1` VARCHAR(200) NOT NULL
- `ship_to_address2` VARCHAR(200) NULL
- `ship_to_city` VARCHAR(120) NOT NULL
- `ship_to_postal_code` VARCHAR(30) NOT NULL
- `ship_to_country` CHAR(2) NOT NULL
- `created_at` TIMESTAMPTZ NOT NULL
- `updated_at` TIMESTAMPTZ NOT NULL
**Indexes**
- index on `customer_id`
- index on (`status`, `created_at`)

#### `order_items`
- `id` UUID PK
- `order_id` UUID NOT NULL FK → `orders(id)` ON DELETE CASCADE
- `product_id` UUID NOT NULL FK → `products(id)` ON DELETE RESTRICT
- `seller_id` UUID NOT NULL FK → `users(id)` ON DELETE RESTRICT  *(snapshot for seller scoping)*
- `product_name_snapshot` VARCHAR(200) NOT NULL
- `unit_price_amount_snapshot` NUMERIC(12,2) NOT NULL
- `quantity` INTEGER NOT NULL CHECK (`quantity` > 0)
- `line_total_amount` NUMERIC(12,2) NOT NULL
- `fulfillment_status` VARCHAR(30) NOT NULL *(PENDING, READY_TO_SHIP, SHIPPED, CANCELLED)*
**Indexes**
- index on `order_id`
- index on `seller_id`
- index on `product_id`
**Constraints**
- unique (`order_id`, `product_id`, `seller_id`) *(optional; depends on whether you allow same product repeated as separate lines)*

### Flyway migration strategy
- Use versioned migrations: `V1__init.sql`, `V2__seed_roles.sql`, `V3__add_indexes.sql`…
- Keep migrations **forward-only**; no editing applied migrations.
- Include **seed migration** for roles + admin bootstrap guidance.
- In tests, run Flyway automatically against Testcontainers Postgres.

---

## STEP 4 — API DESIGN (REST, DTOs, Validation, Authorization)

### Auth Module (`/api/v1/auth`)
1) `POST /register`
- Req: `RegisterRequest { email, password }`
- Res: `AuthResponse { accessToken, refreshToken, user }`
- Validation: email format, password min 8 / max 72
- AuthZ: public

2) `POST /login`
- Req: `LoginRequest { email, password }`
- Res: `AuthResponse`
- Validation: not blank
- AuthZ: public

3) `POST /refresh`
- Req: `RefreshRequest { refreshToken }`
- Res: `TokenResponse { accessToken, refreshToken }`
- Validation: not blank
- AuthZ: public (token-based)

4) `POST /logout`
- Req: `LogoutRequest { refreshToken }` *(or logout current session from header)*
- Res: `204 No Content`
- AuthZ: authenticated

5) `GET /me`
- Res: `MeResponse { id, email, roles, status }`
- AuthZ: authenticated

6) `POST /change-password`
- Req: `ChangePasswordRequest { currentPassword, newPassword }`
- Res: `204 No Content`
- Validation: new password strength rules
- AuthZ: authenticated

**Admin (`/api/v1/admin/users`)**
- `GET /` list users (paged) — ADMIN only
- `PATCH /{userId}/status` — ADMIN only
- `PUT /{userId}/roles` — ADMIN only

**Seller (`/api/v1/seller/profile`)**
7) `POST /`
- Req: `CreateSellerProfileRequest { displayName, phone? }`
- Res: `SellerProfileResponse`
- AuthZ: SELLER

8) `GET /`
- Res: `SellerProfileResponse`
- AuthZ: SELLER

9) `PUT /`
- Req: `UpdateSellerProfileRequest { displayName?, phone? }`
- Res: `SellerProfileResponse`
- AuthZ: SELLER

---

### Product Module (`/api/v1/products`)
**Customer-facing**
1) `GET /`
- Query: `page,size,sort,q,categoryId,minPrice,maxPrice`
- Res: `ProductPageResponse { items[], page }`
- AuthZ: public

2) `GET /{productId}`
- Res: `ProductDetailResponse`
- AuthZ: public (only ACTIVE visible)

**Categories (`/api/v1/categories`)**
3) `GET /`
- Res: `CategoryListResponse { items[] }`
- AuthZ: public

**Seller (`/api/v1/seller/products`)**
3) `POST /`
- Req: `CreateProductRequest { name, description, priceAmount, currency, categoryId, stockQuantity, imageUrls[] }`
- Res: `ProductDetailResponse`
- Validation: name not blank, price positive, stock >=0, max images limit
- AuthZ: SELLER

4) `PUT /{productId}`
- Req: `UpdateProductRequest { name?, description?, priceAmount?, categoryId?, stockQuantity?, status?, imageUrls? }`
- Res: `ProductDetailResponse`
- AuthZ: SELLER (owner only)

5) `GET /`
- Res: seller’s products page
- AuthZ: SELLER

**Admin (`/api/v1/admin/products`)**
6) `GET /` — ADMIN (all statuses)
7) `PATCH /{productId}/status` — ADMIN

**Admin (`/api/v1/admin/categories`)**
8) `POST /`
- Req: `CreateCategoryRequest { name }`
- Res: `CategoryResponse`
- AuthZ: ADMIN

9) `PUT /{categoryId}`
- Req: `UpdateCategoryRequest { name }`
- Res: `CategoryResponse`
- AuthZ: ADMIN

10) `DELETE /{categoryId}`
- Res: `204 No Content`
- AuthZ: ADMIN

---

### Order Module (`/api/v1/orders`)
**Customer**
1) `POST /`
- Req: `CreateOrderRequest { items: [{ productId, quantity }], shippingAddress }`
- Res: `OrderResponse { orderId, status, totals, items[] }`
- Validation: at least 1 item, quantity > 0
- AuthZ: CUSTOMER

2) `GET /`
- Res: `OrderPageResponse`
- AuthZ: CUSTOMER (own only)

3) `GET /{orderId}`
- Res: `OrderResponse`
- AuthZ: CUSTOMER (own only)

4) `POST /{orderId}/cancel`
- Res: `OrderResponse` or `204`
- Rules: only `PENDING/CONFIRMED`
- AuthZ: CUSTOMER (own only)

**Seller (`/api/v1/seller/orders`)**
5) `GET /`
- Res: orders containing seller items (paged, seller-scoped view DTO)
- AuthZ: SELLER

6) `PATCH /{orderId}/items/{itemId}/fulfillment-status`
- Req: `UpdateFulfillmentStatusRequest { status }`
- Res: `SellerOrderItemResponse`
- Rules: allowed transitions only
- AuthZ: SELLER (item’s seller only)

**Admin (`/api/v1/admin/orders`)**
7) `GET /` — ADMIN
8) `PATCH /{orderId}/status` — ADMIN

---

## STEP 5 — GITHUB PROJECT STRUCTURE (Milestones → Epics → Issues)

### Milestones
1) Foundation (Week 1)
2) Auth (Week 2)
3) Product (Week 3)
4) Order (Week 4)
5) Testing (Week 5)
6) Docker & Deployment (Week 6)
7) Documentation & Cleanup (Week 7)

### Epics + Issues (implementation order)
Use labels: `epic`, `backend`, `security`, `database`, `api`, `testing`, `docker`, `docs`, `good-first-issue`  
Complexity: `S` (≤1 day), `M` (2–3 days), `L` (4–6 days)

**EPIC: Foundation**
- Issue: “Initialize Spring Boot 3 project skeleton (modular packages)”
  - Description: Create Maven project, Java 21, base packages, modules folders, basic health endpoint.
  - Acceptance Criteria: app starts; package structure matches spec; formatting/lint baseline.
  - Technical Notes: Spring Web, Validation, Spring Data JPA, Security, Flyway, Lombok (optional), PostgreSQL driver.
  - Labels: `backend`, `epic`
  - Complexity: M
  - Subtasks: pom deps; base config; module package stubs

- Issue: “Add Flyway + baseline migrations”
  - AC: migrations run; tables created in dev DB
  - Notes: V1 init, V2 seed roles
  - Labels: `database`
  - Complexity: M

- Issue: “Global error handling + API error contract”
  - AC: consistent error JSON for validation + domain exceptions
  - Labels: `api`
  - Complexity: S
- Issue: "CORS configuration for frontend integration"
  - AC: CORS enabled with env-configurable origins
  - Labels: `backend`
  - Complexity: S

- Issue: "Spring Boot Actuator + operational endpoints"
  - AC: health and info endpoints exposed, others secured
  - Labels: `backend`
  - Complexity: S
**EPIC: Auth**
- Issue: “User/Role domain + persistence”
  - AC: user CRUD primitives; unique email enforced
  - Notes: entities + repositories + mapping
  - Labels: `security`, `database`
  - Complexity: M

- Issue: “JWT security configuration”
  - AC: protected endpoints require JWT; role-based access works
  - Notes: access+refresh tokens, password encoder
  - Labels: `security`
  - Complexity: L

- Issue: “Auth API: register/login/refresh/logout/me”
  - AC: endpoints work; refresh rotation; logout revokes token
  - Labels: `api`, `security`
  - Complexity: L

- Issue: “Admin user management endpoints”
  - AC: list users, set status, manage roles
  - Labels: `api`
  - Complexity: M
- Issue: "Seller profile management APIs (CRUD)"
  - AC: seller can create/view/update own profile
  - Labels: `api`, `security`
  - Complexity: M
**EPIC: Product**
- Issue: “Category + Product domain model”
  - AC: product lifecycle, stock, status
  - Labels: `backend`, `database`
  - Complexity: M

- Issue: “Product APIs (public browse + detail)”
  - AC: paging/filtering; only ACTIVE visible
  - Labels: `api`
  - Complexity: M

- Issue: “Seller product management APIs”
  - AC: create/update/list own; ownership checks
  - Labels: `api`, `security`
  - Complexity: L

- Issue: “Admin product moderation APIs”
  - AC: deactivate/reactivate any product
  - Labels: `api`
  - Complexity: S
- Issue: "Category management APIs (CRUD)"
  - AC: admin creates/updates/deletes categories; public lists them
  - Labels: `api`, `database`
  - Complexity: M
**EPIC: Order**
- Issue: “Order domain + persistence (orders + items)”
  - AC: constraints, totals stored, item snapshots
  - Labels: `database`
  - Complexity: L

- Issue: “Order creation service (stock validation + snapshot pricing)”
  - AC: prevents ordering inactive/out-of-stock items; reduces stock atomically
  - Notes: use transaction + `SELECT ... FOR UPDATE` via JPA locking where needed
  - Labels: `backend`
  - Complexity: L

- Issue: “Customer order APIs (create/list/detail/cancel)”
  - AC: ownership enforced; cancel rules enforced
  - Labels: `api`
  - Complexity: M

- Issue: “Seller order view + fulfillment updates”
  - AC: seller sees only own lines; can update item status
  - Labels: `api`, `security`
  - Complexity: M

- Issue: “Admin order status override”
  - AC: admin can set order status with validation
  - Labels: `api`
  - Complexity: S

**EPIC: Testing**
- Issue: “Unit tests for services (Mockito)”
  - AC: core business rules covered; negative paths included
  - Labels: `testing`
  - Complexity: M

- Issue: “Integration tests with Testcontainers Postgres”
  - AC: Flyway runs; repositories tested; transactional behavior validated
  - Labels: `testing`
  - Complexity: L

- Issue: “Controller tests (MockMvc + Security)”
  - AC: authz rules validated; 401/403/400/404 cases covered
  - Labels: `testing`
  - Complexity: L

**EPIC: Docker & Deployment**
- Issue: “Dockerfile (multi-stage)”
  - AC: produces runnable image; small size
  - Labels: `docker`
  - Complexity: S

- Issue: “docker-compose (app + postgres) with env vars”
  - AC: one-command local run; persistent volume
  - Labels: `docker`
  - Complexity: S
- Issue: "GitHub Actions CI pipeline (test + build)"
  - AC: runs tests on PR, builds Docker image
  - Labels: `ci-cd`
  - Complexity: M
**EPIC: Documentation & Cleanup**
- Issue: “README + architecture + API docs”
  - AC: clear setup/run/deploy instructions; module boundaries described
  - Labels: `docs`
  - Complexity: M

---

## STEP 6 — IMPLEMENTATION ROADMAP (Week-by-week)

- **Week 1 (Foundation)**: Maven + project skeleton, base config, Flyway init, global errors, security scaffolding, Docker dev compose (optional early).
- **Week 2 (Auth)**: user/role tables, JWT access/refresh, auth endpoints, admin user management, security tests baseline.
- **Week 3 (Product)**: product/category schema, seller product APIs, public browse/detail, moderation.
- **Week 4 (Order)**: order schema, order creation transaction/locking, customer order APIs, seller fulfillment APIs, admin overrides.
- **Week 5 (Testing)**: service unit tests, repository integration tests (Testcontainers), controller tests with security.
- **Week 6 (Docker & Deployment)**: finalize Dockerfile, compose profiles, env config, logging, production settings hardening.
- **Week 7 (Docs & Cleanup)**: README, ADR-style architecture notes, API docs, refactoring for clarity, remove dead code, polish.

---

## STEP 7 — TESTING STRATEGY

- **Unit tests (JUnit5 + Mockito)**:
  - Focus: service layer business rules (status transitions, ownership checks, stock validation, token rotation).
  - Mock repositories + cross-module service interfaces.
- **Integration tests**:
  - Use **Testcontainers PostgreSQL**; run Flyway migrations on startup.
  - Validate transactional behavior (order creation + stock decrement).
- **Repository tests**:
  - `@DataJpaTest` + Testcontainers; verify constraints, indexes assumptions, custom queries.
- **Controller tests**:
  - `@WebMvcTest` for controller slice + mocked service interfaces, plus security filter chain.
  - Alternatively `@SpringBootTest` + MockMvc for end-to-end authz coverage (slower but realistic).
- **Security tests**:
  - Explicit tests for 401 vs 403.
  - Role-based endpoint access matrix (CUSTOMER/SELLER/ADMIN).
- **Coverage goals (practical)**:
  - Overall: 75%+ line coverage
  - Service layer: 85%+
  - Controllers: focus on authz + validation paths rather than pure coverage

---

## STEP 8 — DEPLOYMENT STRATEGY

### Dockerfile
- Multi-stage build:
  - Stage 1: build JAR with Maven
  - Stage 2: run with JRE 21 base image
- Expose `8080`
- Healthcheck endpoint optional (`/actuator/health` if Actuator included)

### docker-compose
- Services: `vendora-app`, `postgres`
- Postgres volume for persistence
- Env vars (app):
  - `SPRING_PROFILES_ACTIVE=dev|prod`
  - `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`
  - `JWT_SECRET` (prod only, long random)
  - `JWT_ACCESS_TTL`, `JWT_REFRESH_TTL`

### Environment configuration
- `application.yml` common defaults
- `application-dev.yml`: local-friendly logging, ddl disabled (Flyway only), show SQL optional
- `application-prod.yml`: strict settings, no SQL logs, secure headers, strong JWT secret required

### Logging strategy
- Default Logback with:
  - structured-ish pattern including `traceId` (if you add Spring Boot tracing later)
  - separate log levels: `INFO` app, `WARN` framework noise
- Avoid logging secrets/tokens; mask Authorization headers.

---

## STEP 9 — DOCUMENTATION

### Professional README structure (portfolio-ready)
- Project Overview (what Vendora is)
- Tech Stack (Java 21, Spring Boot 3, PostgreSQL, JWT, Flyway, Testcontainers, Docker)
- Architecture
  - Modular Monolith overview
  - Module boundaries + communication rules
- Domain Model (high-level entities)
- API Documentation
  - Link to OpenAPI/Swagger UI (Springdoc)
  - Auth flow explanation (access/refresh)
- Local Development
  - Prereqs (Docker, JDK 21)
  - Run with Docker Compose
  - Run tests
- Deployment
  - Build image, run compose, prod env vars
- Security Notes
  - Password hashing, token rotation, least privilege
- Future Scalability (microservice migration plan)

### API documentation strategy
- Add **OpenAPI** via Springdoc:
  - Group endpoints by module (`auth`, `product`, `order`)
  - Define security scheme (Bearer JWT)
  - Document role requirements per endpoint

### Architecture explanation (microservice migration plan)
- Each module can become a service by:
  - Extracting module package into separate repo
  - Replacing service-interface calls with REST/gRPC calls
  - Introducing outbox/events later (explicitly “future”, not in Option A)
- Database split plan:
  - Start with schema-per-module conventions
  - Later split into separate DBs by module with data duplication where necessary
### Future enhancements (documented, not implemented in Option A)
- **Forgot password / password reset**: email-based token flow
- **Email verification**: verify email on registration
- **Rate limiting**: API rate limits (Bucket4j or Spring Cloud Gateway)
- **Audit logging**: track who changed what when (separate audit table)
- **Advanced search**: Postgres full-text search or Elasticsearch
- **File upload**: product image upload with S3/local storage
- **Payment gateway integration**: Stripe/PayPal for actual payments
- **Inventory alerts**: low stock notifications
- **Order notifications**: email/SMS on order status changes
- **Admin dashboard**: analytics, reports