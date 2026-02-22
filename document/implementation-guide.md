# Vendora Backend - Step-by-Step Implementation Guide

## 📊 PLAN ASSESSMENT

**vendora-backend-plan.md: ✅ APPROVED**
- Complete feature freeze with role separation
- Solid architecture decisions (modular monolith)
- Comprehensive database design
- All API endpoints defined
- Testing, deployment, and documentation strategies covered
- Future enhancements properly documented

**github-backlog.md: ✅ APPROVED**
- 37 well-defined issues with acceptance criteria
- Proper milestone organization (7 weeks)
- Clear complexity estimates
- All critical gaps addressed

---

## 🎯 STEP-BY-STEP IMPLEMENTATION PLAN

### **WEEK 1: FOUNDATION (Days 1-7)**

#### **Day 1: Project Bootstrap** 🚀
**Issue #1:** Project initialization and strict modular package structure

**Tasks:**
- Use Spring Initializr (Spring Boot 3.3.x, Java 21, Maven)
- Add dependencies: Web, Security, JPA, PostgreSQL, Flyway, Validation, Actuator, Springdoc
- Create exact package structure:
  ```
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
  ```
- Add `.gitignore`, `README.md` stub, `LICENSE` (MIT or Apache 2.0)
- Verify app starts

**Deliverable:** ✅ App boots, shows Swagger UI at `/swagger-ui.html`

---

#### **Day 2: Base Configuration** ⚙️
**Issue #2:** Base configuration (profiles, PostgreSQL, logging)

**Tasks:**
- Create `application.yml`, `application-dev.yml`, `application-prod.yml`
- Configure datasource (env vars: `DB_URL`, `DB_USER`, `DB_PASSWORD`)
- Set up logging patterns (INFO for app, WARN for framework)
- Disable Hibernate DDL (Flyway-only): `spring.jpa.hibernate.ddl-auto=none`
- Test with local PostgreSQL or Docker Postgres

**Deliverable:** ✅ App connects to database successfully

**Issue #3:** Global API error handling contract

**Tasks:**
- Create `ErrorResponse` DTO in `common` package with fields:
  - `timestamp`, `status`, `errorCode`, `message`, `path`, `fieldErrors[]`
- Implement `@RestControllerAdvice` in `common` with handlers for:
  - 400: `MethodArgumentNotValidException`, `IllegalArgumentException`
  - 401: `AuthenticationException`
  - 403: `AccessDeniedException`
  - 404: Domain `NotFoundException`
  - 409: `DataIntegrityViolationException`
  - 500: Generic `Exception`
- Add basic test

**Deliverable:** ✅ Consistent error JSON structure

**Issue #4:** CORS configuration

**Tasks:**
- Add `CorsConfig` bean in `config` package
- Use `CORS_ALLOWED_ORIGINS` env var
- Default dev: `http://localhost:3000,http://localhost:5173`
- Configure allowed methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
- Configure allowed headers: Authorization, Content-Type

**Deliverable:** ✅ Frontend can call API from configured origins

**Issue #5:** Spring Boot Actuator

**Tasks:**
- Add `spring-boot-starter-actuator` dependency
- Configure in `application.yml`:
  ```yaml
  management:
    endpoints:
      web:
        exposure:
          include: health,info
    endpoint:
      health:
        show-details: when-authorized
  ```
- Add security rules to allow public access to health
- Add build info to `/actuator/info`

**Deliverable:** ✅ Health endpoint returns UP status

---

#### **Day 3-4: Database Schema** 🗄️
**Issue #6:** Flyway baseline migrations (schema init)

**Tasks:**
- Create directory: `src/main/resources/db/migration/`
- Create `V1__init.sql` with all tables:
  
  **Auth tables:**
  - `users` (id UUID, email unique, password_hash, status, timestamps)
  - `roles` (id, name unique: CUSTOMER/SELLER/ADMIN)
  - `user_roles` (user_id, role_id, composite PK)
  - `refresh_tokens` (id UUID, user_id, token_hash unique, expires_at, revoked_at, created_at)
  - `seller_profiles` (user_id PK, display_name, phone, timestamps)
  
  **Product tables:**
  - `categories` (id UUID, name unique, created_at)
  - `products` (id UUID, seller_id FK, category_id FK, name, description, price_amount, currency, status, stock_quantity, timestamps)
  - `product_images` (id UUID, product_id FK, url, sort_order, unique constraint on product+sort_order)
  
  **Order tables:**
  - `orders` (id UUID, customer_id FK, status, subtotal/shipping/total amounts, currency, ship_to fields, timestamps)
  - `order_items` (id UUID, order_id FK, product_id FK, seller_id FK, snapshots, quantity, line_total, fulfillment_status)

- Add all indexes:
  - users(email), refresh_tokens(token_hash, user_id)
  - products(seller_id, category_id, status+created_at)
  - orders(customer_id, status+created_at)
  - order_items(order_id, seller_id, product_id)

- Add constraints:
  - CHECK constraints on price > 0, stock >= 0, quantity > 0
  - ON DELETE CASCADE/RESTRICT as per design

**Deliverable:** ✅ Flyway creates schema, app starts without errors

**Issue #7:** Seed roles and admin bootstrap

**Tasks:**
- Create `V2__seed_roles.sql`:
  ```sql
  INSERT INTO roles (id, name) VALUES 
    (1, 'CUSTOMER'),
    (2, 'SELLER'),
    (3, 'ADMIN');
  ```
- Document admin bootstrap strategy in README:
  - Option A: Manual SQL insert with BCrypt hash
  - Option B: One-time startup command (bean or CLI)

**Deliverable:** ✅ Roles exist in DB after migration

---

### **WEEK 2: AUTH MODULE (Days 8-14)**

#### **Day 5-6: Security Foundation** 🔐
**Issue #8:** Spring Security baseline + role model

**Tasks:**
- Create `SecurityConfig` class in `config` package
- Configure stateless security filter chain:
  ```java
  http
    .csrf(csrf -> csrf.disable())
    .sessionManagement(session -> session.sessionCreationPolicy(STATELESS))
    .authorizeHttpRequests(auth -> auth
      .requestMatchers("/api/v1/auth/**", "/actuator/health", "/swagger-ui/**").permitAll()
      .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
      .anyRequest().authenticated()
    )
  ```
- Add `BCryptPasswordEncoder` bean
- Create `UserRole` enum: CUSTOMER, SELLER, ADMIN
- Allow public access to auth endpoints + health + Swagger

**Deliverable:** ✅ Unauthorized requests return 401, forbidden roles return 403

---

#### **Day 7-9: Auth Domain & Persistence** 🎫
**Issue #9:** Auth domain + persistence (users, roles, refresh tokens)

**Tasks:**
- Create entities in `modules.auth.domain`:
  - `User` (id UUID, email, passwordHash, status enum, roles ManyToMany, timestamps)
  - `Role` (id, name)
  - `RefreshToken` (id UUID, user, tokenHash, expiresAt, revokedAt, createdAt)
  - `SellerProfile` (userId PK, displayName, phone, timestamps)
  
- Create repositories in `modules.auth.repository`:
  - `UserRepository extends JpaRepository<User, UUID>`
    - `Optional<User> findByEmail(String email)`
    - `boolean existsByEmail(String email)`
  - `RoleRepository extends JpaRepository<Role, Long>`
    - `Optional<Role> findByName(String name)`
  - `RefreshTokenRepository extends JpaRepository<RefreshToken, UUID>`
    - `Optional<RefreshToken> findByTokenHash(String hash)`
    - `void deleteByUserId(UUID userId)`
  - `SellerProfileRepository extends JpaRepository<SellerProfile, UUID>`

- Use UUID generator for IDs: `@GeneratedValue(strategy = GenerationType.UUID)`

**Deliverable:** ✅ Entities can be persisted, repositories work

**Issue #10:** JWT implementation (access + refresh rotation)

**Tasks:**
- Create `JwtUtil` in `modules.auth.service` for:
  - `generateAccessToken(User user)` - include roles in claims, short TTL (15min)
  - `generateRefreshToken()` - random secure token, long TTL (7 days)
  - `validateAccessToken(String token)` - verify signature + expiration
  - `getUserIdFromToken(String token)`
  
- Create `JwtAuthenticationFilter` extends `OncePerRequestFilter`:
  - Extract Bearer token from Authorization header
  - Validate token
  - Set SecurityContext with authenticated user
  
- Create `AuthService` with:
  - `register(email, password)` - hash password, assign CUSTOMER role, generate tokens
  - `login(email, password)` - verify credentials, generate tokens
  - `refreshTokens(refreshToken)` - validate, rotate (revoke old, issue new), return new tokens
  - `logout(refreshToken)` - revoke token
  
- Store refresh tokens hashed (SHA-256) in database
  
- Configure in `application.yml`:
  ```yaml
  jwt:
    secret: ${JWT_SECRET:changeme-dev-secret-256-bits-long}
    access-ttl: ${JWT_ACCESS_TTL:15m}
    refresh-ttl: ${JWT_REFRESH_TTL:7d}
  ```

**Deliverable:** ✅ JWT auth works, refresh rotates tokens correctly

---

#### **Day 10-11: Auth REST APIs** 🌐
**Issue #11:** Auth REST API (register/login/refresh/logout/me/change-password)

**Tasks:**
- Create DTOs in `modules.auth.api.dto`:
  - `RegisterRequest` (@Email, @NotBlank email, @Size(min=8, max=72) password)
  - `LoginRequest` (@NotBlank email, @NotBlank password)
  - `AuthResponse` (accessToken, refreshToken, user: {id, email, roles, status})
  - `RefreshRequest` (@NotBlank refreshToken)
  - `TokenResponse` (accessToken, refreshToken)
  - `MeResponse` (id, email, roles, status)
  - `ChangePasswordRequest` (@NotBlank currentPassword, @Size(min=8) newPassword)

- Create `AuthController` in `modules.auth.api`:
  - `POST /api/v1/auth/register` → AuthResponse
  - `POST /api/v1/auth/login` → AuthResponse
  - `POST /api/v1/auth/refresh` → TokenResponse
  - `POST /api/v1/auth/logout` → 204 No Content
  - `GET /api/v1/auth/me` → MeResponse (authenticated)
  - `POST /api/v1/auth/change-password` → 204 No Content (authenticated)

- Add Swagger/OpenAPI annotations:
  - `@Tag(name = "Authentication")`
  - `@Operation(summary = "...")`
  - `@SecurityRequirement` where needed

- Test with Postman/curl or write MockMvc tests

**Deliverable:** ✅ All auth endpoints work end-to-end against Postgres

---

#### **Day 12: Admin & Seller Management** 👥
**Issue #12:** Admin user management API (list users, roles, activate/deactivate)

**Tasks:**
- Create DTOs:
  - `UserResponse` (id, email, roles, status, createdAt)
  - `UserPageResponse` (items[], page metadata)
  - `UpdateUserStatusRequest` (status enum)
  - `UpdateUserRolesRequest` (roleNames[])

- Create `AdminUserController` in `modules.auth.api`:
  - `GET /api/v1/admin/users?page=0&size=20&search={email}` → UserPageResponse (ADMIN only)
  - `PATCH /api/v1/admin/users/{userId}/status` → UserResponse (ADMIN only)
  - `PUT /api/v1/admin/users/{userId}/roles` → UserResponse (ADMIN only)

- Implement `AdminUserService` in `modules.auth.service`:
  - `listUsers(Pageable pageable, String search)`
  - `updateStatus(UUID userId, UserStatus status)`
  - `updateRoles(UUID userId, Set<String> roleNames)`

- Add `@PreAuthorize("hasRole('ADMIN')")` or configure in SecurityConfig

**Deliverable:** ✅ Admin can list/search users, change status, manage roles

**Issue #13:** Seller profile management APIs (CRUD)

**Tasks:**
- Create DTOs:
  - `CreateSellerProfileRequest` (@NotBlank @Size(max=120) displayName, @Size(max=30) phone)
  - `UpdateSellerProfileRequest` (displayName?, phone?)
  - `SellerProfileResponse` (userId, displayName, phone, createdAt, updatedAt)

- Create `SellerProfileController` in `modules.auth.api`:
  - `POST /api/v1/seller/profile` → SellerProfileResponse (SELLER only)
  - `GET /api/v1/seller/profile` → SellerProfileResponse (SELLER only)
  - `PUT /api/v1/seller/profile` → SellerProfileResponse (SELLER only)

- Implement `SellerProfileService`:
  - `createProfile(UUID userId, CreateRequest req)` - enforce one profile per user
  - `getProfile(UUID userId)`
  - `updateProfile(UUID userId, UpdateRequest req)` - enforce ownership

- Enforce SELLER role + ownership (user can only manage own profile)

**Deliverable:** ✅ Seller can create/view/update own profile

---

#### **Day 13-14: Auth Module Testing** ✅
**Tasks:**
- Write unit tests for `AuthService` using Mockito:
  - Test register with duplicate email (409)
  - Test login with wrong password (401)
  - Test refresh token rotation (old token revoked)
  - Test logout (token revoked)
  - Test change password

- Write controller tests for auth endpoints:
  - Test validation errors (400)
  - Test 401 for protected endpoints without token
  - Test 403 for ADMIN endpoints with CUSTOMER token

**Deliverable:** ✅ Auth module has solid test coverage (85%+)

---

### **WEEK 3: PRODUCT MODULE (Days 15-21)**

#### **Day 15-16: Product Domain & Categories** 📦
**Issue #14:** Category + Product domain model

**Tasks:**
- Create entities in `modules.product.domain`:
  - `Category` (id UUID, name unique, createdAt)
  - `Product` (id UUID, seller FK User, category FK, name, description, priceAmount, currency, status enum, stockQuantity, timestamps)
  - `ProductImage` (id UUID, product FK, url, sortOrder, unique product+sortOrder)
  - `ProductStatus` enum: DRAFT, ACTIVE, INACTIVE

- Create repositories in `modules.product.repository`:
  - `CategoryRepository extends JpaRepository<Category, UUID>`
    - `Optional<Category> findByName(String name)`
  - `ProductRepository extends JpaRepository<Product, UUID>`
    - `Page<Product> findByStatus(ProductStatus status, Pageable pageable)`
    - `Page<Product> findBySellerId(UUID sellerId, Pageable pageable)`
    - `Page<Product> findByStatusAndCategoryIdAndPriceAmountBetween(..., Pageable pageable)`
  - `ProductImageRepository extends JpaRepository<ProductImage, UUID>`

- Create service interfaces in `modules.product.service`:
  - `ProductQueryService` (interface) for cross-module calls:
    - `Optional<ProductDto> findById(UUID productId)`
    - `boolean isAvailable(UUID productId, int quantity)` - check ACTIVE + stock
  - `ProductCommandService` (interface):
    - `ProductDto createProduct(...)`
    - `ProductDto updateProduct(...)`
    - `void decrementStock(UUID productId, int quantity)` - for order creation

**Deliverable:** ✅ Product entities persist correctly, repositories work

**Issue #15:** Category management APIs (CRUD)

**Tasks:**
- Create DTOs:
  - `CategoryResponse` (id, name, createdAt)
  - `CategoryListResponse` (items[])
  - `CreateCategoryRequest` (@NotBlank @Size(max=120) name)
  - `UpdateCategoryRequest` (@NotBlank @Size(max=120) name)

- Create `CategoryController` in `modules.product.api`:
  - `GET /api/v1/categories` → CategoryListResponse (public)

- Create `AdminCategoryController`:
  - `POST /api/v1/admin/categories` → CategoryResponse (ADMIN only)
  - `PUT /api/v1/admin/categories/{id}` → CategoryResponse (ADMIN only)
  - `DELETE /api/v1/admin/categories/{id}` → 204 (ADMIN only, check no products reference it or set null)

**Deliverable:** ✅ Categories can be managed, customers can list them

---

#### **Day 17-18: Public Product APIs** 🛍️
**Issue #16:** Product APIs (public browse + detail)

**Tasks:**
- Create DTOs:
  - `ProductResponse` (id, seller: {id, displayName}, category, name, description, price, currency, stockQuantity, images[], createdAt)
  - `ProductPageResponse` (items[], page metadata)
  - `ProductDetailResponse` (extends ProductResponse with more details)

- Create `ProductController` in `modules.product.api`:
  - `GET /api/v1/products?page=0&size=20&q={search}&categoryId={uuid}&minPrice=0&maxPrice=1000` → ProductPageResponse (public, only ACTIVE)
  - `GET /api/v1/products/{id}` → ProductDetailResponse (public, only ACTIVE, 404 if INACTIVE/DRAFT)

- Implement `ProductService`:
  - `browseProducts(String query, UUID categoryId, BigDecimal minPrice, BigDecimal maxPrice, Pageable pageable)`
  - `getProductDetail(UUID productId)` - throw NotFoundException if not found or not ACTIVE

**Deliverable:** ✅ Customers can browse and view product details

---

#### **Day 19-20: Seller Product Management** 🏪
**Issue #17:** Seller product management APIs (create/update/list/activate)

**Tasks:**
- Create DTOs:
  - `CreateProductRequest` (@NotBlank name, description, @Positive priceAmount, currency="USD", @NotNull categoryId, @Min(0) stockQuantity, imageUrls[])
  - `UpdateProductRequest` (name?, description?, priceAmount?, categoryId?, stockQuantity?, status?, imageUrls?)
  - `SellerProductResponse` (full product details including DRAFT/INACTIVE)

- Create `SellerProductController` in `modules.product.api`:
  - `POST /api/v1/seller/products` → SellerProductResponse (SELLER only)
  - `PUT /api/v1/seller/products/{id}` → SellerProductResponse (SELLER only, ownership check)
  - `GET /api/v1/seller/products?page=0&size=20` → ProductPageResponse (SELLER only, own products)
  - `PATCH /api/v1/seller/products/{id}/status` → SellerProductResponse (SELLER only, can activate/deactivate own)

- Implement ownership checks in service:
  - `verifySellerOwnsProduct(UUID sellerId, UUID productId)`
  - Throw `AccessDeniedException` if seller doesn't own product

- **Cross-module call:** Use `UserQueryService` from auth module to verify seller exists and has SELLER role

**Deliverable:** ✅ Sellers can CRUD own products, cannot modify others' products

---

#### **Day 21: Admin Product Moderation** 🛡️
**Issue #18:** Admin product moderation API (activate/deactivate)

**Tasks:**
- Create `AdminProductController` in `modules.product.api`:
  - `GET /api/v1/admin/products?page=0&size=20` → ProductPageResponse (ADMIN only, all statuses visible)
  - `PATCH /api/v1/admin/products/{id}/status` → ProductResponse (ADMIN only, can override any product status)

- Add audit logging (optional): log who changed what product status

**Deliverable:** ✅ Admin can view all products and moderate status

---

### **WEEK 4: ORDER MODULE (Days 22-28)**

#### **Day 22-23: Order Domain** 📋
**Issue #19:** Order domain + persistence (orders + order_items)

**Tasks:**
- Create entities in `modules.order.domain`:
  - `Order` (id UUID, customer FK User, status enum, subtotalAmount, shippingAmount, totalAmount, currency, shipTo fields, timestamps)
  - `OrderItem` (id UUID, order FK, product FK, seller FK User, productNameSnapshot, unitPriceSnapshot, quantity, lineTotalAmount, fulfillmentStatus enum)
  - `OrderStatus` enum: PENDING, CONFIRMED, CANCELLED, PARTIALLY_SHIPPED, SHIPPED
  - `FulfillmentStatus` enum: PENDING, READY_TO_SHIP, SHIPPED, CANCELLED

- Define valid state transitions:
  - PENDING → CONFIRMED, CANCELLED
  - CONFIRMED → PARTIALLY_SHIPPED, SHIPPED, CANCELLED
  - PARTIALLY_SHIPPED → SHIPPED

- Create repositories in `modules.order.repository`:
  - `OrderRepository extends JpaRepository<Order, UUID>`
    - `Page<Order> findByCustomerId(UUID customerId, Pageable pageable)`
    - `Page<Order> findByStatus(OrderStatus status, Pageable pageable)`
  - `OrderItemRepository extends JpaRepository<OrderItem, UUID>`
    - `List<OrderItem> findByOrderId(UUID orderId)`
    - `Page<OrderItem> findBySellerId(UUID sellerId, Pageable pageable)`

**Deliverable:** ✅ Orders with items can be persisted and loaded

---

#### **Day 24-26: Order Creation (CRITICAL)** ⚡
**Issue #20:** Order creation transaction (stock validation + atomic decrement)

**Tasks:**
- Create DTOs:
  - `CreateOrderRequest` (items: [{productId, quantity}], shippingAddress: {name, phone, address1, address2, city, postalCode, country})
  - `OrderItemRequest` (@NotNull productId, @Min(1) quantity)
  - `ShippingAddressRequest` (@NotBlank fields)
  - `OrderResponse` (orderId, status, totals, items[], shippingAddress, createdAt)

- Implement `OrderCommandService.createOrder()` with **strict transactional guarantees**:
  
  ```java
  @Transactional
  public OrderResponse createOrder(UUID customerId, CreateOrderRequest req) {
    // 1. Validate items not empty
    // 2. For each item:
    //    - Call productQueryService.findById(productId)
    //    - Verify product is ACTIVE (throw if DRAFT/INACTIVE)
    //    - Verify stock >= quantity (throw if insufficient)
    // 3. Lock products for update (pessimistic lock or careful query)
    // 4. Create Order entity with status PENDING
    // 5. For each item:
    //    - Create OrderItem with snapshots (productName, unitPrice, sellerId)
    //    - Call productCommandService.decrementStock(productId, quantity)
    // 6. Calculate totals (subtotal = sum of item totals, shipping = 0 for now, total = subtotal + shipping)
    // 7. Save order
    // 8. Return OrderResponse
  }
  ```

- Implement `ProductCommandService.decrementStock()` with careful update:
  ```java
  @Transactional
  public void decrementStock(UUID productId, int quantity) {
    Product product = productRepository.findById(productId)
      .orElseThrow(() -> new NotFoundException("Product not found"));
    
    if (product.getStockQuantity() < quantity) {
      throw new InsufficientStockException("Not enough stock");
    }
    
    product.setStockQuantity(product.getStockQuantity() - quantity);
    productRepository.save(product);
    
    // OR use direct update query for extra safety:
    // int updated = productRepository.decrementStockIfAvailable(productId, quantity);
    // if (updated == 0) throw new InsufficientStockException();
  }
  ```

- Add custom repository method for atomic decrement (optional but recommended):
  ```java
  @Modifying
  @Query("UPDATE Product p SET p.stockQuantity = p.stockQuantity - :quantity " +
         "WHERE p.id = :productId AND p.stockQuantity >= :quantity")
  int decrementStockIfAvailable(@Param("productId") UUID productId, 
                                 @Param("quantity") int quantity);
  ```

- Write integration test with Testcontainers:
  - Test concurrent order creation for same product
  - Verify no overselling (total orders <= initial stock)

**Deliverable:** ✅ Orders create correctly, stock decrements atomically, no overselling under test

---

#### **Day 27: Customer Order APIs** 🛒
**Issue #21:** Customer order APIs (create/list/detail/cancel)

**Tasks:**
- Create `OrderController` in `modules.order.api`:
  - `POST /api/v1/orders` → OrderResponse (CUSTOMER only)
  - `GET /api/v1/orders?page=0&size=20` → OrderPageResponse (CUSTOMER only, own orders)
  - `GET /api/v1/orders/{id}` → OrderResponse (CUSTOMER only, ownership check)
  - `POST /api/v1/orders/{id}/cancel` → OrderResponse or 204 (CUSTOMER only, only if PENDING/CONFIRMED)

- Implement `OrderService`:
  - `listOrders(UUID customerId, Pageable pageable)` - only customer's orders
  - `getOrderDetail(UUID orderId, UUID customerId)` - verify ownership, throw 404 if not customer's order
  - `cancelOrder(UUID orderId, UUID customerId)` - verify ownership, verify status allows cancellation, set status to CANCELLED

- Enforce ownership in service layer, not controllers

**Deliverable:** ✅ Customers can create, list, view, and cancel own orders

---

#### **Day 28: Seller & Admin Order Management** 📊
**Issue #22:** Seller order view + fulfillment updates

**Tasks:**
- Create DTOs:
  - `SellerOrderItemResponse` (orderId, itemId, productName, quantity, lineTotal, fulfillmentStatus, customer: {name, address}, createdAt)
  - `UpdateFulfillmentStatusRequest` (@NotNull status enum)

- Create `SellerOrderController` in `modules.order.api`:
  - `GET /api/v1/seller/orders/items?page=0&size=20` → Page<SellerOrderItemResponse> (SELLER only, items where seller owns product)
  - `PATCH /api/v1/seller/orders/{orderId}/items/{itemId}/fulfillment-status` → SellerOrderItemResponse (SELLER only, own items only)

- Implement `SellerOrderService`:
  - `listSellerOrderItems(UUID sellerId, Pageable pageable)` - query items where item.sellerId = sellerId
  - `updateFulfillmentStatus(UUID orderId, UUID itemId, UUID sellerId, FulfillmentStatus newStatus)` - verify seller owns item, validate transition

- Validate fulfillment status transitions:
  - PENDING → READY_TO_SHIP, CANCELLED
  - READY_TO_SHIP → SHIPPED, CANCELLED
  - SHIPPED → (no further transitions)

**Deliverable:** ✅ Sellers can view orders containing their items and update fulfillment status

**Issue #23:** Admin order status override

**Tasks:**
- Create `AdminOrderController` in `modules.order.api`:
  - `GET /api/v1/admin/orders?page=0&size=20&status={status}` → OrderPageResponse (ADMIN only, all orders)
  - `PATCH /api/v1/admin/orders/{id}/status` → OrderResponse (ADMIN only, can override order status)

- Implement `AdminOrderService`:
  - `listAllOrders(OrderStatus status, Pageable pageable)`
  - `updateOrderStatus(UUID orderId, OrderStatus newStatus)` - admin can force any transition (with validation or override)

**Deliverable:** ✅ Admin can view all orders and override status

---

### **WEEK 5: COMPREHENSIVE TESTING (Days 29-35)**

#### **Day 29-30: Service Unit Tests** 🧪
**Issue #24:** Unit tests for services (Mockito)

**Tasks:**
- **Auth Service Tests:**
  - Test register with valid data → success
  - Test register with duplicate email → 409
  - Test login with correct credentials → tokens returned
  - Test login with wrong password → 401
  - Test refresh token rotation → old token revoked, new tokens issued
  - Test refresh with revoked token → 401
  - Test logout → token revoked
  - Test change password with correct old password → success
  - Test change password with wrong old password → 403

- **Product Service Tests:**
  - Test create product by seller → success
  - Test update product owner → success
  - Test update product non-owner → 403
  - Test seller can only see own products
  - Test admin can see all products
  - Test customers only see ACTIVE products
  - Test stock validation

- **Order Service Tests:**
  - Test create order with valid items → success, stock decremented
  - Test create order with inactive product → 400
  - Test create order with insufficient stock → 400
  - Test cancel order PENDING → success
  - Test cancel order SHIPPED → 400
  - Test order totals calculation
  - Test status transitions validation

**Deliverable:** ✅ Service layer has 85%+ coverage with positive and negative test cases

---

#### **Day 31-33: Integration Tests** 🔬
**Issue #25:** Integration tests with Testcontainers PostgreSQL

**Tasks:**
- Set up Testcontainers in test scope:
  ```java
  @SpringBootTest
  @Testcontainers
  class IntegrationTests {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
      .withDatabaseName("vendora_test")
      .withUsername("test")
      .withPassword("test");
    
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
      registry.add("spring.datasource.url", postgres::getJdbcUrl);
      registry.add("spring.datasource.username", postgres::getUsername);
      registry.add("spring.datasource.password", postgres::getPassword);
    }
  }
  ```

- **Migration Tests:**
  - Test V1__init.sql runs successfully
  - Test V2__seed_roles.sql creates 3 roles
  - Test all constraints are created (unique, FK, check constraints)

- **Repository Tests:**
  - Test UserRepository.findByEmail
  - Test unique email constraint (DataIntegrityViolationException)
  - Test ProductRepository queries with pagination
  - Test OrderRepository with complex filters

- **Transaction Tests (CRITICAL):**
  - Test order creation transaction:
    - Create order with 2 items
    - Verify stock decremented for both products
    - Verify order and items persisted
  - Test concurrent order creation:
    - Start with product stock = 10
    - Create 5 concurrent threads each ordering quantity 3
    - Only 3 orders should succeed (3×3 = 9 ≤ 10)
    - 2 orders should fail with insufficient stock
    - Final stock should be 1 (10 - 9)

- **Cross-Module Integration Tests:**
  - Test order creation calls product module correctly
  - Test product creation validates seller exists via auth module

**Deliverable:** ✅ Integration tests pass reliably, transaction safety verified

---

#### **Day 34-35: Controller/Security Tests** 🎭
**Issue #26:** Controller/security tests (MockMvc)

**Tasks:**
- Set up MockMvc test configuration:
  ```java
  @WebMvcTest(AuthController.class)
  @Import(SecurityConfig.class)
  class AuthControllerTests {
    @Autowired
    MockMvc mockMvc;
    
    @MockBean
    AuthService authService;
  }
  ```

- **Authentication Tests:**
  - Test POST /api/v1/auth/register with valid data → 200
  - Test POST /api/v1/auth/register with invalid email → 400 with fieldErrors
  - Test POST /api/v1/auth/login with valid credentials → 200 with tokens
  - Test GET /api/v1/auth/me without token → 401
  - Test GET /api/v1/auth/me with valid token → 200

- **Authorization Tests (Role Matrix):**
  - Test CUSTOMER accessing /api/v1/admin/** → 403
  - Test CUSTOMER accessing /api/v1/seller/** without SELLER role → 403
  - Test ADMIN accessing /api/v1/admin/** → 200
  - Test SELLER accessing own products → 200
  - Test SELLER accessing other's products → 403

- **Validation Tests:**
  - Test create product with negative price → 400
  - Test create order with empty items → 400
  - Test create order with quantity < 1 → 400

- **Error Handling Tests:**
  - Test accessing non-existent product → 404
  - Test duplicate email registration → 409
  - Test invalid JWT token → 401

**Deliverable:** ✅ Controller layer has comprehensive security and validation coverage

---

### **WEEK 6: DOCKER, CI/CD & PRODUCTION HARDENING (Days 36-42)**

#### **Day 36-37: Docker** 🐳
**Issue #27:** Dockerfile (multi-stage) for vendora backend

**Tasks:**
- Create `Dockerfile` at project root:
  ```dockerfile
  # Stage 1: Build
  FROM maven:3.9-eclipse-temurin-21 AS builder
  WORKDIR /app
  COPY pom.xml .
  COPY src ./src
  RUN mvn clean package -DskipTests
  
  # Stage 2: Runtime
  FROM eclipse-temurin:21-jre-alpine
  WORKDIR /app
  COPY --from=builder /app/target/*.jar app.jar
  
  EXPOSE 8080
  
  ENV SPRING_PROFILES_ACTIVE=prod
  
  HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1
  
  ENTRYPOINT ["java", "-jar", "app.jar"]
  ```

- Build and test image:
  ```bash
  docker build -t vendora-backend:latest .
  docker run --rm -p 8080:8080 \
    -e DB_URL=jdbc:postgresql://host.docker.internal:5432/vendora \
    -e DB_USER=vendora \
    -e DB_PASSWORD=secret \
    -e JWT_SECRET=your-256-bit-secret-key-here \
    vendora-backend:latest
  ```

**Deliverable:** ✅ Docker image builds successfully and runs

**Issue #28:** docker-compose (app + postgres) for local and prod-like runs

**Tasks:**
- Create `docker-compose.yml`:
  ```yaml
  version: '3.9'
  
  services:
    postgres:
      image: postgres:16-alpine
      environment:
        POSTGRES_DB: ${DB_NAME:-vendora}
        POSTGRES_USER: ${DB_USER:-vendora}
        POSTGRES_PASSWORD: ${DB_PASSWORD:-vendora123}
      ports:
        - "5432:5432"
      volumes:
        - postgres_data:/var/lib/postgresql/data
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U vendora"]
        interval: 10s
        timeout: 5s
        retries: 5
    
    app:
      build: .
      depends_on:
        postgres:
          condition: service_healthy
      ports:
        - "8080:8080"
      environment:
        SPRING_PROFILES_ACTIVE: ${SPRING_PROFILES_ACTIVE:-dev}
        DB_URL: jdbc:postgresql://postgres:5432/${DB_NAME:-vendora}
        DB_USER: ${DB_USER:-vendora}
        DB_PASSWORD: ${DB_PASSWORD:-vendora123}
        JWT_SECRET: ${JWT_SECRET:-dev-secret-change-me-in-production}
        JWT_ACCESS_TTL: ${JWT_ACCESS_TTL:-15m}
        JWT_REFRESH_TTL: ${JWT_REFRESH_TTL:-7d}
        CORS_ALLOWED_ORIGINS: ${CORS_ALLOWED_ORIGINS:-http://localhost:3000,http://localhost:5173}
  
  volumes:
    postgres_data:
  ```

- Create `.env.example`:
  ```env
  # Database
  DB_NAME=vendora
  DB_USER=vendora
  DB_PASSWORD=changeme
  
  # JWT
  JWT_SECRET=your-256-bit-secret-key-change-in-production
  JWT_ACCESS_TTL=15m
  JWT_REFRESH_TTL=7d
  
  # CORS
  CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
  
  # Spring Profile
  SPRING_PROFILES_ACTIVE=dev
  ```

- Test:
  ```bash
  cp .env.example .env
  docker compose up -d
  # Wait for app to start
  curl http://localhost:8080/actuator/health
  curl http://localhost:8080/swagger-ui.html
  ```

**Deliverable:** ✅ `docker compose up` brings up both services successfully

---

#### **Day 38-39: CI/CD Pipeline** 🚀
**Issue #29:** GitHub Actions CI pipeline (test + build)

**Tasks:**
- Create `.github/workflows/ci.yml`:
  ```yaml
  name: CI
  
  on:
    push:
      branches: [ main, develop ]
    pull_request:
      branches: [ main, develop ]
  
  jobs:
    test:
      runs-on: ubuntu-latest
      
      steps:
        - uses: actions/checkout@v4
        
        - name: Set up JDK 21
          uses: actions/setup-java@v4
          with:
            java-version: '21'
            distribution: 'temurin'
            cache: maven
        
        - name: Run tests
          run: mvn clean verify
        
        - name: Upload coverage reports
          uses: codecov/codecov-action@v4
          if: success()
    
    build-docker:
      runs-on: ubuntu-latest
      needs: test
      if: github.ref == 'refs/heads/main'
      
      steps:
        - uses: actions/checkout@v4
        
        - name: Set up Docker Buildx
          uses: docker/setup-buildx-action@v3
        
        - name: Build Docker image
          run: docker build -t vendora-backend:${{ github.sha }} .
        
        # Optional: Push to registry
        # - name: Login to Docker Hub
        #   uses: docker/login-action@v3
        #   with:
        #     username: ${{ secrets.DOCKER_USERNAME }}
        #     password: ${{ secrets.DOCKER_PASSWORD }}
        # 
        # - name: Push image
        #   run: |
        #     docker tag vendora-backend:${{ github.sha }} yourusername/vendora-backend:latest
        #     docker push yourusername/vendora-backend:latest
  ```

- Add status badge to README:
  ```markdown
  ![CI](https://github.com/Developer199239/Vendora/workflows/CI/badge.svg)
  ```

- Configure branch protection rules:
  - Require PR reviews
  - Require status checks to pass (CI)
  - Require branches to be up to date

**Deliverable:** ✅ Tests run automatically on PR, Docker image builds on main push

---

#### **Day 40-42: Production Hardening** 🔒
**Tasks:**
- **Security Headers:** Add to `SecurityConfig`:
  ```java
  http.headers(headers -> headers
    .contentSecurityPolicy(csp -> csp.policyDirectives("default-src 'self'"))
    .frameOptions(HeadersConfigurer.FrameOptionsConfig::deny)
    .xssProtection(xss -> xss.headerValue(XXssProtectionHeaderWriter.HeaderValue.ENABLED_MODE_BLOCK))
  );
  ```

- **Logging Review:**
  - Mask Authorization headers in logs
  - Never log passwords, tokens, or sensitive data
  - Add MDC for request tracing (optional)

- **CORS for Production:**
  - Update `application-prod.yml`:
    ```yaml
    cors:
      allowed-origins: ${CORS_ALLOWED_ORIGINS:https://yourdomain.com}
    ```

- **Environment Validation:**
  - Add startup validation for required env vars in prod profile
  - Fail fast if JWT_SECRET not set in prod

- **Rate Limiting (Optional):**
  - Add Bucket4j for rate limiting on auth endpoints

- **Test Prod Profile Locally:**
  ```bash
  export SPRING_PROFILES_ACTIVE=prod
  export JWT_SECRET=$(openssl rand -base64 32)
  export DB_URL=jdbc:postgresql://localhost:5432/vendora
  export DB_USER=vendora
  export DB_PASSWORD=secure_password
  mvn spring-boot:run
  ```

**Deliverable:** ✅ App is production-ready with security hardening

---

### **WEEK 7: DOCUMENTATION & POLISH (Days 43-49)**

#### **Day 43-45: Comprehensive Documentation** 📚
**Issue #30:** README + architecture + API docs strategy

**Tasks:**
- Write portfolio-grade `README.md` with:
  
  **1. Project Overview**
  - Brief description: "Vendora is a production-ready e-commerce backend built with Spring Boot 3 and modular monolith architecture."
  - Key features list
  - Tech stack badges
  - CI status badge
  - Screenshots/diagrams (optional)
  
  **2. Tech Stack**
  - Java 21
  - Spring Boot 3.3.x
  - PostgreSQL 16
  - JWT Authentication
  - Flyway Migrations
  - JUnit 5 + Mockito + Testcontainers
  - Docker & Docker Compose
  - GitHub Actions CI
  
  **3. Architecture**
  - Modular Monolith explanation
  - Package structure diagram
  - Module boundaries rules:
    - No direct repository access across modules
    - Communication via service interfaces only
  - Microservice-ready design
  
  **4. Domain Model**
  - High-level entity relationship description
  - Users → Roles (ManyToMany)
  - Products → Categories, Sellers
  - Orders → OrderItems → Products
  
  **5. API Documentation**
  - Link to Swagger UI: `http://localhost:8080/swagger-ui.html`
  - Brief overview of endpoint groups:
    - `/api/v1/auth` - Authentication
    - `/api/v1/products` - Public product browsing
    - `/api/v1/seller/**` - Seller management
    - `/api/v1/admin/**` - Admin operations
    - `/api/v1/orders` - Order management
  
  **6. Authentication Flow**
  - Diagram or steps:
    1. Register → get access + refresh tokens
    2. Login → get access + refresh tokens
    3. Access protected endpoints with Bearer token
    4. Refresh tokens before expiry
    5. Logout → revoke refresh token
  
  **7. Local Development Setup**
  ```markdown
  ### Prerequisites
  - JDK 21
  - Docker & Docker Compose
  - Maven 3.9+
  
  ### Quick Start
  1. Clone the repository:
     ```bash
     git clone https://github.com/Developer199239/Vendora.git
     cd Vendora
     ```
  
  2. Copy environment variables:
     ```bash
     cp .env.example .env
     ```
  
  3. Start with Docker Compose:
     ```bash
     docker compose up -d
     ```
  
  4. Access the application:
     - API: http://localhost:8080
     - Swagger UI: http://localhost:8080/swagger-ui.html
     - Health: http://localhost:8080/actuator/health
  
  ### Running Locally Without Docker
  1. Start PostgreSQL:
     ```bash
     docker run -d -p 5432:5432 \
       -e POSTGRES_DB=vendora \
       -e POSTGRES_USER=vendora \
       -e POSTGRES_PASSWORD=vendora123 \
       postgres:16-alpine
     ```
  
  2. Run the application:
     ```bash
     export DB_URL=jdbc:postgresql://localhost:5432/vendora
     export DB_USER=vendora
     export DB_PASSWORD=vendora123
     export JWT_SECRET=$(openssl rand -base64 32)
     mvn spring-boot:run
     ```
  ```
  
  **8. Running Tests**
  ```bash
  # All tests (uses Testcontainers)
  mvn clean verify
  
  # Unit tests only
  mvn test
  
  # With coverage report
  mvn clean verify jacoco:report
  # Open target/site/jacoco/index.html
  ```
  
  **9. Deployment**
  ```markdown
  ### Production Deployment
  1. Build Docker image:
     ```bash
     docker build -t vendora-backend:latest .
     ```
  
  2. Set production environment variables:
     ```bash
     export SPRING_PROFILES_ACTIVE=prod
     export DB_URL=jdbc:postgresql://your-db-host:5432/vendora
     export DB_USER=your_user
     export DB_PASSWORD=your_secure_password
     export JWT_SECRET=$(openssl rand -base64 32)
     export CORS_ALLOWED_ORIGINS=https://yourdomain.com
     ```
  
  3. Run with Docker:
     ```bash
     docker run -d -p 8080:8080 \
       -e SPRING_PROFILES_ACTIVE=prod \
       -e DB_URL=$DB_URL \
       -e DB_USER=$DB_USER \
       -e DB_PASSWORD=$DB_PASSWORD \
       -e JWT_SECRET=$JWT_SECRET \
       -e CORS_ALLOWED_ORIGINS=$CORS_ALLOWED_ORIGINS \
       vendora-backend:latest
     ```
  ```
  
  **10. Security Notes**
  - Passwords hashed with BCrypt (strength 10)
  - JWT tokens with short expiry (15min access, 7 days refresh)
  - Refresh token rotation on each refresh request
  - Role-based access control (CUSTOMER, SELLER, ADMIN)
  - CORS configured per environment
  - Security headers enabled (CSP, XSS protection, frame options)
  - SQL injection protected via JPA/Hibernate
  
  **11. Project Structure**
  ```
  src/main/java/com/vendora/
  ├── common/              # Shared utilities, DTOs, exceptions
  ├── config/              # Spring configuration (Security, CORS, etc.)
  └── modules/
      ├── auth/            # Authentication & user management
      │   ├── api/         # Controllers & DTOs
      │   ├── domain/      # Entities (User, Role, RefreshToken)
      │   ├── service/     # Business logic
      │   └── repository/  # Data access (JPA)
      ├── product/         # Product catalog & inventory
      │   ├── api/
      │   ├── domain/      # Entities (Product, Category)
      │   ├── service/
      │   └── repository/
      └── order/           # Order management
          ├── api/
          ├── domain/      # Entities (Order, OrderItem)
          ├── service/
          └── repository/
  
  src/main/resources/
  ├── application.yml
  ├── application-dev.yml
  ├── application-prod.yml
  └── db/migration/        # Flyway migrations
      ├── V1__init.sql
      └── V2__seed_roles.sql
  ```
  
  **12. Future Enhancements (Roadmap)**
  - [ ] Email notifications (forgot password, order confirmations)
  - [ ] Payment gateway integration (Stripe/PayPal)
  - [ ] File upload for product images (S3/local storage)
  - [ ] Advanced search (Elasticsearch)
  - [ ] Rate limiting (Bucket4j)
  - [ ] Audit logging
  - [ ] Admin dashboard with analytics
  - [ ] Inventory alerts (low stock notifications)
  - [ ] Microservice migration (extract modules to separate services)
  
  **13. Contributing**
  - Contributions welcome! Please open an issue first to discuss changes.
  - Follow existing code style and conventions.
  - Write tests for new features.
  - Update documentation as needed.
  
  **14. License**
  MIT License - see LICENSE file for details.
  
  **15. Contact**
  - Email: your-email@example.com
  - GitHub: [@Developer199239](https://github.com/Developer199239)
  ```

- Add `ARCHITECTURE.md` (optional separate file):
  - Deep dive into modular monolith design
  - Module dependency graph
  - Service interface contracts
  - Migration path to microservices

- Add `API.md` or rely on Springdoc:
  - For portfolio, Swagger UI may be sufficient
  - Add endpoint examples with curl commands

**Deliverable:** ✅ New developer can set up and run the project in <10 minutes using README

---

#### **Day 46-47: Code Review & Refactoring** 🔍
**Tasks:**
- **Code Review Checklist:**
  - [ ] All classes have meaningful names
  - [ ] No magic numbers (use constants)
  - [ ] No commented-out code
  - [ ] Consistent formatting (run `mvn spotless:apply` if using Spotless)
  - [ ] JavaDocs for public interfaces and service methods
  - [ ] DTOs use validation annotations consistently
  - [ ] No System.out.println (use logger)
  - [ ] Exceptions have clear messages
  - [ ] Test names follow `shouldDoSomethingWhenCondition` pattern

- **Refactoring:**
  - Extract common validation logic to utility methods
  - Consolidate repeated code in services
  - Improve DTOs naming consistency (Request suffix for inputs, Response for outputs)
  - Add missing @Transactional annotations
  - Extract constants for magic strings (role names, statuses)

- **Add JavaDocs for Exposed Interfaces:**
  ```java
  /**
   * Query service for product catalog operations.
   * This interface is exposed for cross-module communication.
   * 
   * @since 1.0
   */
  public interface ProductQueryService {
    /**
     * Find product by ID if it exists and is active.
     * 
     * @param productId the product UUID
     * @return Optional containing product DTO if found and active
     */
    Optional<ProductDto> findById(UUID productId);
    
    /**
     * Check if product has sufficient stock for order.
     * 
     * @param productId the product UUID
     * @param quantity requested quantity
     * @return true if product is ACTIVE and stock >= quantity
     */
    boolean isAvailable(UUID productId, int quantity);
  }
  ```

**Deliverable:** ✅ Clean, maintainable, well-documented code

---

#### **Day 48-49: Final Testing & Demo Preparation** 🎬
**Tasks:**
- **Run Full Test Suite:**
  ```bash
  mvn clean verify
  # Verify all tests pass
  # Check coverage report
  ```

- **End-to-End Manual Testing:**
  - Start app with Docker Compose
  - Test full user flow:
    1. Register as customer
    2. Register as seller
    3. Create seller profile
    4. Create a category (admin)
    5. Create products as seller
    6. Browse products as customer
    7. Create an order
    8. View order as customer
    9. View order items as seller
    10. Update fulfillment status
    11. View all orders as admin

- **Create Demo Script / Postman Collection:**
  - Export Postman collection with:
    - Register user
    - Login
    - Create product (seller)
    - Browse products (customer)
    - Create order (customer)
    - Update fulfillment (seller)
  - Add environment variables for base URL and tokens

- **Create Sample Data (Optional):**
  - Add Flyway migration `V3__sample_data.sql` (dev profile only):
    ```sql
    -- Sample categories
    INSERT INTO categories (id, name, created_at) VALUES 
      (gen_random_uuid(), 'Electronics', NOW()),
      (gen_random_uuid(), 'Books', NOW()),
      (gen_random_uuid(), 'Clothing', NOW());
    
    -- Sample admin user (password: Admin123!)
    -- Sample seller user (password: Seller123!)
    -- Sample products
    ```

- **Prepare Demo Video (Optional):**
  - Record 3-5 minute walkthrough showing:
    - Architecture overview
    - Running the app with Docker Compose
    - API calls via Swagger UI
    - Code structure
    - Test execution

- **Final Checklist:**
  - [ ] All tests pass
  - [ ] Docker Compose works
  - [ ] README is complete
  - [ ] GitHub CI is green
  - [ ] Swagger UI is functional
  - [ ] No TODO comments in production code
  - [ ] All issues closed on GitHub
  - [ ] Project tagged with v1.0.0 release

**Deliverable:** ✅ Project is demo-ready and portfolio-ready

---

## 📌 ADDITIONAL RECOMMENDATIONS

### **Add to Week 1 (Repository Setup):**

**New Task: Comprehensive `.gitignore`**
```gitignore
# Maven
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties
.mvn/wrapper/maven-wrapper.jar

# IDE
.idea/
*.iml
.vscode/
*.code-workspace
.DS_Store

# Environment
.env
.env.local
*.log

# Test
*.log
hs_err_pid*
replay_pid*

# Spring Boot
spring-boot-devtools.properties
```

### **Weekly Progress Tracking:**

At the end of each week, create GitHub milestone review:
- Close completed issues
- Update project board
- Document any blockers or decisions
- Adjust next week's plan if needed

---

## 🎯 SUCCESS CRITERIA CHECKLIST

**Week 1:** ✅ App starts, DB connected, Swagger works, Flyway migrations run  
**Week 2:** ✅ Can register, login, get JWT, access protected endpoints, role-based access works  
**Week 3:** ✅ Can browse products, sellers can create products, categories work  
**Week 4:** ✅ Can create orders, stock decrements correctly, no overselling  
**Week 5:** ✅ Tests pass, coverage ≥75%, CI pipeline green  
**Week 6:** ✅ Docker works, docker-compose works, CI/CD pipeline functional  
**Week 7:** ✅ Documentation complete, code clean, demo ready, v1.0.0 tagged  

---

## ⚠️ RISK MITIGATION

### **High-Risk Areas:**

1. **Order Creation Transaction (Week 4, Day 24-26)** ⚠️
   - **Risk:** Race conditions leading to overselling
   - **Mitigation:**
     - Use pessimistic locking: `@Lock(LockModeType.PESSIMISTIC_WRITE)`
     - OR use atomic update queries: `UPDATE ... SET stock = stock - ? WHERE stock >= ?`
     - Write concurrent test with Testcontainers
     - Test with multiple threads attempting to order same product

2. **JWT Refresh Rotation (Week 2, Day 7-9)** ⚠️
   - **Risk:** Security vulnerability if not done correctly
   - **Mitigation:**
     - Store refresh tokens hashed (SHA-256 minimum)
     - Revoke old token atomically when issuing new one
     - Set appropriate expiry times
     - Test token reuse prevention

3. **Module Boundaries (Ongoing)** ⚠️
   - **Risk:** Developers accidentally break modular architecture
   - **Mitigation:**
     - Code reviews enforce boundaries
     - Clear documentation in README
     - Consider ArchUnit tests to enforce package rules (advanced)
     - Service interfaces clearly marked as "cross-module API"

4. **Database Performance (Week 4+)** ⚠️
   - **Risk:** Slow queries with large datasets
   - **Mitigation:**
     - All foreign keys have indexes (already in migration)
     - Use pagination for all list endpoints
     - Test with realistic data volume (1000+ products, orders)
     - Monitor query performance with `show-sql` in dev

---

## 🚀 QUICK START COMMANDS

### **Day 1 (Project Initialization):**
```bash
# Create project directory
mkdir vendora-backend
cd vendora-backend

# Initialize git
git init
git remote add origin https://github.com/Developer199239/Vendora.git

# Generate Spring Boot project (or use start.spring.io)
# Then create package structure as per plan

# First commit
git add .
git commit -m "Initial project structure"
git push -u origin main
```

### **Day 2 (Database Setup):**
```bash
# Start PostgreSQL with Docker
docker run -d --name vendora-postgres \
  -e POSTGRES_DB=vendora \
  -e POSTGRES_USER=vendora \
  -e POSTGRES_PASSWORD=vendora123 \
  -p 5432:5432 \
  postgres:16-alpine

# Test connection
psql -h localhost -U vendora -d vendora
```

### **Week 7 (Final Demo):**
```bash
# Clean build and test
mvn clean verify

# Start with Docker Compose
docker compose up --build

# Access application
open http://localhost:8080/swagger-ui.html

# Tag release
git tag -a v1.0.0 -m "Version 1.0.0 - Production Ready"
git push origin v1.0.0
```

---

## 📊 ESTIMATED TIME BREAKDOWN

| Week | Focus Area | Hours | Complexity |
|------|------------|-------|------------|
| 1 | Foundation | 40-50 | Medium |
| 2 | Auth Module | 50-60 | High |
| 3 | Product Module | 40-50 | Medium |
| 4 | Order Module | 50-60 | High |
| 5 | Testing | 40-50 | Medium |
| 6 | Docker & CI/CD | 30-40 | Low-Medium |
| 7 | Documentation | 30-40 | Low |
| **Total** | **7 weeks** | **280-350 hours** | **Full-Time** |

**Part-Time Schedule (20 hrs/week):** 14-18 weeks  
**Aggressive Schedule (60 hrs/week):** 5 weeks  

---

## 🎓 LEARNING RESOURCES (Optional)

If you need to brush up on any concepts:
- **Spring Boot 3:** https://spring.io/guides
- **Spring Security 6:** https://docs.spring.io/spring-security/reference/
- **JWT Best Practices:** https://tools.ietf.org/html/rfc8725
- **JPA/Hibernate:** https://www.baeldung.com/learn-jpa-hibernate
- **Testcontainers:** https://www.testcontainers.org/
- **Docker:** https://docs.docker.com/get-started/

---

## ✅ FINAL CHECKLIST (Before Considering Complete)

- [ ] All 37 GitHub issues closed
- [ ] All tests pass (mvn clean verify)
- [ ] Code coverage ≥75%
- [ ] Docker Compose starts successfully
- [ ] GitHub Actions CI is green
- [ ] README is complete and accurate
- [ ] Swagger UI is fully functional
- [ ] No System.out.println in production code
- [ ] No TODO comments in main branches
- [ ] All environment variables documented in .env.example
- [ ] Security review completed (no secrets in code)
- [ ] Demo Postman collection created
- [ ] Project tagged with v1.0.0
- [ ] License file added
- [ ] Dependencies up to date (no critical vulnerabilities)

---

**Your plan is excellent and ready for implementation. This guide provides a realistic, day-by-day path to completion. Good luck building Vendora! 🚀**
