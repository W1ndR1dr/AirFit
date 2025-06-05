# 00_Project_Overview.md

This document provides a high-level overview of the AirFit project structure and its main components.

## Top-Level Directory Structure:

*   **`/AirFit`**: The main application target for iOS. Contains all core logic, UI, services, and modules.
*   **`/AirFitTests`**: Unit and integration tests for the AirFit iOS application.
*   **`/AirFitUITests`**: UI tests for the AirFit iOS application.
*   **`/AirFitWatchApp`**: The Apple Watch companion application.
*   **`/.github`**: GitHub Actions workflows (e.g., for testing).
*   **`/.claude`**: Claude-specific settings.
*   **`/Docs`**: Project documentation, research reports, and architectural notes.
*   **`/Scripts`**: Utility scripts for development, building, or testing.
*   **Root Files**: Configuration files like `.gitignore`, `project.yml`, `Package.swift` (implied by `package.json`), etc.

## Architectural Layers (Conceptual):

The project appears to follow a layered architecture:

1.  **Application Layer (`/AirFit/Application`)**: Entry point, main content view, app state management.
2.  **Modules Layer (`/AirFit/Modules`)**: Feature-specific modules like Onboarding, Dashboard, FoodTracking, etc. Each module often contains its own Coordinators, ViewModels, Views, and sometimes module-specific Services or Models.
3.  **Services Layer (`/AirFit/Services`)**: Shared business logic, external API integrations (AI, Weather), HealthKit interaction, speech processing, and security.
4.  **Core Layer (`/AirFit/Core`)**: Foundational utilities, constants, enums, extensions, base protocols, UI theme, and common UI components shared across the app.
5.  **Data Layer (`/AirFit/Data`)**: SwiftData models, data management, and migrations.

## Primary Targets:

*   **AirFit (iOS App)**: The main fitness application.
    *   **Purpose**: To provide AI-powered fitness coaching, food tracking, workout planning, and health monitoring.
*   **AirFitTests (iOS Unit/Integration Tests)**:
    *   **Purpose**: To ensure the correctness and reliability of the AirFit iOS app's components and their interactions.
*   **AirFitUITests (iOS UI Tests)**:
    *   **Purpose**: To automate UI interactions and verify the visual and functional aspects of the AirFit iOS app.
*   **AirFitWatchApp (watchOS App)**:
    *   **Purpose**: To offer a companion experience on Apple Watch, likely focused on workout tracking and quick logging.

## High-Level Dependency Flow (Typical):
Use code with caution.
Markdown
+---------------------+ +---------------------+ +-------------------+
| Application Layer | --> | Modules Layer | --> | Services Layer |
+---------------------+ +---------------------+ +-------------------+
| ^ | |
| | | v
v +----------+ +-----------+
+-----------+ | Core Layer|
| Data Layer| +-----------+
+-----------+
*   **Application** uses **Modules**.
*   **Modules** use **Services**, **Data Layer**, and **Core Layer**. Modules aim to be self-contained features.
*   **Services** use **Core Layer** and sometimes the **Data Layer** (e.g., for context).
*   **Data Layer** uses **Core Layer** (e.g., for extensions or base protocols).
*   **Core Layer** aims to be foundational with minimal outgoing dependencies to other app-specific layers.

**Note:** More detailed dependency information will be explored in `09_Dependency_Hints.md` and within specific layer/module documents.