# Implement User Authentication and User-Specific Tasks

## Goal Description
The user wants to add authentication to the application so that users can have their own tasks and not see tasks from other users. This requires adding a user management system to the backend (FastAPI + SQLite) and an authentication flow to the frontend (Flutter).

## User Review Required
> [!IMPORTANT]
> Adding authentication involves creating new screens for Login and Registration in the Flutter app. I will use a standard username and password flow.
> The easiest way to migrate the database is to recreate the `tasks` table with a `user_id` column. Because the current database only has test data, I will drop the old table. **Is it okay to clear the current tasks during this update?**

## Proposed Changes

### Backend (Python FastAPI)

#### [MODIFY] `e:/flodoai/task_management_app/backend/requirements.txt`
- Add dependencies for authentication: `passlib`, `bcrypt`, `pyjwt`, `python-multipart`.

#### [MODIFY] `e:/flodoai/task_management_app/backend/main.py`
- **Database Schema**:
  - Create a new `users` table: `id`, `username`, `hashed_password`.
  - Update the `tasks` table to include a `user_id` foreign key.
- **Authentication**:
  - Implement password hashing and JWT token generation.
  - Create `POST /register` to create new users.
  - Create `POST /token` for login (returns a JWT access token).
- **Task Endpoints**:
  - Add a dependency to extract and verify the JWT token from the `Authorization` header.
  - Update `GET /tasks` to only return tasks where `user_id` matches the authenticated user.
  - Update `POST /tasks` to automatically assign the `user_id` of the authenticated user to the new task.
  - Update `PUT /tasks/{id}` and `DELETE /tasks/{id}` to ensure the user owns the task before modifying it.

### Frontend (Flutter)

#### [NEW] `e:/flodoai/task_management_app/lib/providers/auth_provider.dart`
- Create a provider to manage authentication state (login, register, logout, reading/writing JWT token from `shared_preferences`).

#### [NEW] `e:/flodoai/task_management_app/lib/screens/login_screen.dart`
- Create a login UI with username, password, and a link to the registration screen.

#### [NEW] `e:/flodoai/task_management_app/lib/screens/register_screen.dart`
- Create a registration UI.

#### [MODIFY] `e:/flodoai/task_management_app/lib/providers/task_provider.dart`
- Modify all HTTP requests (`GET`, `POST`, `PUT`, `DELETE`) to include the `Authorization: Bearer <token>` header.
- Add error handling for 401 Unauthorized responses to trigger a logout.

#### [MODIFY] `e:/flodoai/task_management_app/lib/main.dart`
- Add `AuthProvider` to the app's provider list.
- Implement routing logic: If the user is authenticated (token exists), show `TaskListScreen`; otherwise, show `LoginScreen`.

## Verification Plan
### Automated Tests
- Run FastAPI server and test endpoints `/register` and `/token` using `curl`.
- Verify that accessing `/tasks` without a valid token returns a 401 Unauthorized error.
- Verify that users can only fetch, update, and delete their own tasks.

### Manual Verification
- Launch the Flutter app. It should start at the Login screen.
- Register a new user, log in, create a task.
- Log out, register a second user, log in, and verify the first user's tasks are not visible.
