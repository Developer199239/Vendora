can you create all task like below example

example 1:
title: Project Initialization and Base Infrastructure Setup

description
The goal of this task is to initialize the backend of our e-commerce platform, Bazario, using Spring Boot 3.x. We need to establish a solid foundation following the 3-layer architecture (Controller, Service, Repository) to ensure scalability and maintainability.

Requirements & Technical Specifications:

Framework: Spring Boot 3.3.x (or latest stable)
Java Version: JDK 17 or 21
Build Tool: Maven
Dependencies to Include:
Spring Web (For REST APIs)
Spring Data JPA (For ORM)
PostgreSQL Driver (For DB connectivity)
Lombok (To reduce boilerplate code)
Spring Validation (For request body validation)
Springdoc OpenAPI (Swagger) (For API documentation)
To-Do List:


Initialize the project using Spring Initializr.


Configure application.yml for PostgreSQL connection.


Create the basic package structure:

com.bazario.api.controller

com.bazario.api.service

com.bazario.api.repository

com.bazario.api.model.entity

com.bazario.api.model.dto


Implement a HealthCheckController to verify the API is up.


Integrate Swagger UI and verify it's accessible at /swagger-ui.html.


Ensure the project compiles and runs successfully.

Acceptance Criteria:

The application should start without errors.
Database connection must be established successfully.
API documentation (Swagger) should show the health check endpoint.
Code must follow standard Java naming conventions.

example 2:
title: Database Infrastructure Setup with Flyway Migration

descrption:
To ensure a robust and scalable foundation for Bazario, we are implementing our database schema using Flyway. This approach allows us to version control our database changes, ensuring consistency across all development and production environments.

Technical Requirements:

Migration Tool: Flyway (Spring Boot integration).
Database: PostgreSQL.
Data Types: Primary keys must use UUID for security and scalability; monetary values must use DECIMAL(19, 4) for precision.
To-Do List:


Add Flyway dependencies (flyway-core and flyway-database-postgresql) to pom.xml.

Create the directory: src/main/resources/db/migration/.

Create a file named V1__init_schema.sql and paste the SQL script provided below.

Configure application.yml to enable Flyway and set database credentials.

Run the application and verify that the tables are generated correctly in the database.
SQL Script for V1__init_schema.sql:

-- Enable UUID extension for PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Categories Table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(120) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Products Table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    base_price DECIMAL(19, 4) NOT NULL,
    discount_price DECIMAL(19, 4),
    sku VARCHAR(100) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Inventory Table
CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID UNIQUE REFERENCES products(id) ON DELETE CASCADE,
    stock_quantity INT NOT NULL DEFAULT 0,
    low_stock_threshold INT DEFAULT 10,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Performance Indexes
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_categories_slug ON categories(slug);
Acceptance Criteria:

Application starts successfully without migration errors.
Database contains categories, products, inventory, and flyway_schema_history tables.
Share a screenshot of the database schema from your DB client (pgAdmin/DBeaver).


can you direct create on my github for this project?