# Example Holdout Scenario: User Authentication

> This is a reference example showing how to write holdout scenarios.
> Copy this format when creating real scenarios in `.copilot/holdout/`.

## Holdout Scenario: H-001

**Actor:** Registered user
**Intent:** Log in with valid credentials and access their dashboard
**Preconditions:** User has an active account with email `user@example.com`
**Action:** User submits login form with valid email and password
**Success Criteria:**

- User is redirected to their personal dashboard within 3 seconds
- Dashboard displays the user's name and last login timestamp
- Session token is set with appropriate expiry (not indefinite)

**Failure Modes:**

- User sees a generic error page instead of the dashboard
- Session token is missing or has no expiry
- Login succeeds but dashboard shows another user's data

**Priority:** Critical

---

## Holdout Scenario: H-002

**Actor:** Registered user
**Intent:** Receive a clear error when entering wrong credentials
**Preconditions:** User has an active account
**Action:** User submits login form with correct email but wrong password
**Success Criteria:**

- User sees a message indicating invalid credentials (not which field is wrong)
- User remains on the login page with email field preserved
- Failed attempt is logged for security monitoring

**Failure Modes:**

- Error message reveals whether the email exists ("password incorrect" vs "user not found")
- User is locked out after a single failed attempt
- Failed login is not logged

**Priority:** High

---

## Holdout Scenario: H-003

**Actor:** Unauthenticated visitor
**Intent:** Access a protected page without logging in
**Preconditions:** User has not authenticated
**Action:** User navigates directly to `/dashboard` via URL
**Success Criteria:**

- User is redirected to the login page
- After successful login, user is redirected back to `/dashboard` (not the homepage)
- No dashboard content is visible before authentication

**Failure Modes:**

- Dashboard content flashes briefly before redirect
- User is redirected to homepage after login instead of originally requested page
- API endpoints return data without authentication check

**Priority:** High


