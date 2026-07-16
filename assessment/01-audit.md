# BUG-001 – Generated Interview Invitation URL Points to Backend Instead of Frontend

## Severity
**P0 – Blocker**

## Area
Assessment → Invite Candidate

## Summary
The generated interview invitation URL points to the Rails backend (`localhost:3001`) instead of the React frontend (`localhost:5173`). As a result, candidates cannot access the interview page using the generated link.

---

## Impact

Candidates are unable to start the interview because the generated invitation URL returns a Rails routing error. This blocks the primary interview workflow.

---

## Steps to Reproduce

1. Login as an administrator.
2. Create a new Assessment.
3. Create an interview session (Invite Candidate).
4. Copy the generated invitation URL.
5. Open the URL in the browser.

---

## Expected Result

The generated invitation URL should open the candidate interview page.

Example:

http://localhost:5173/interview/<invite_token>

---

## Actual Result

The generated URL is:

http://localhost:3001/interview/<invite_token>

Opening the URL returns:

Routing Error

No route matches [GET] "/interview/<invite_token>"

---

## Root Cause Analysis

The backend generates the invitation URL using the backend base URL.

Current implementation:

```ruby
def invite_url
  base = ENV.fetch('APP_BASE_URL', 'http://localhost:3001')
  "#{base}/interview/#{invite_token}"
end
```

However, the interview page is implemented in the frontend application:

```tsx
<Route path="/interview/:token" element={<InterviewPage />} />
```

Therefore, generated invitation links point to the wrong application.

---

## Recommendation

Use a dedicated frontend base URL when generating invitation links.

Example:

```ruby
base = ENV.fetch("FRONTEND_URL", "http://localhost:5173")
```

and configure:

```env
FRONTEND_URL=http://localhost:5173
```

---

## Evidence

- Generated invitation URL points to `localhost:3001`
- Browser returns Rails Routing Error
- Backend `invite_url` uses `APP_BASE_URL`
- Frontend route `/interview/:token` exists
- Manually replacing `3001` with `5173` successfully opens the interview page

---

## Status
Open


# BUG-002 – Assessment API Allows Creation Without Any Skills

## Severity
**P1 – Major**

## Area
Assessment → Create Assessment (Backend API)

## Summary

The Assessment API allows creating an assessment without any associated skills when requests are sent directly to the backend API. Although the frontend prevents users from submitting the form without at least one skill, the backend does not enforce the same business rule.

---

## Impact

Users can bypass the frontend validation by sending requests directly to the API (e.g., using Postman), allowing invalid assessment data to be created.

This violates the application's business rules because an assessment should contain at least one skill to evaluate candidates. Invalid assessments may cause unexpected behavior during interview generation, AI prompt generation, portfolio creation, or future reporting.

---

## Steps to Reproduce

1. Login as an administrator.
2. Obtain a valid JWT access token.
3. Send a `POST` request to:

```
POST /api/v1/assessments
```

Request Body:

```json
{
  "assessment": {
    "name": "Backend Engineer",
    "time_limit_min": 45,
    "language": "en",
    "assessment_skills_attributes": []
  }
}
```

4. Submit the request.

---

## Expected Result

The API should reject the request and return a validation error indicating that an assessment must contain at least one skill.

Example:

```http
HTTP/1.1 422 Unprocessable Entity
```

```json
{
  "errors": [
    "Assessment must contain at least one skill."
  ]
}
```

---

## Actual Result

The API returns:

```http
HTTP/1.1 201 Created
```

The assessment is successfully created despite having **0 skills**.

The assessment is visible in the application and can still be used to generate interview sessions.

---

## Root Cause Analysis

The frontend correctly prevents users from creating an assessment without selecting at least one skill.

However, the backend API does not perform the same validation. Since backend validation is missing, requests sent directly to the API bypass the frontend restriction and create invalid business data.

This indicates that the business rule is enforced only in the frontend instead of being validated on the server side.

---

## Recommendation

Implement server-side validation to ensure every assessment contains at least one associated skill before it can be created or updated.

Example:

```ruby
validate :must_have_at_least_one_skill

private

def must_have_at_least_one_skill
  if assessment_skills.empty?
    errors.add(:assessment_skills, "must contain at least one skill")
  end
end
```

Alternatively, implement an equivalent validation within the model or controller to enforce the business rule regardless of the client application.

---

## Evidence

- Frontend prevents users from saving an assessment without selecting any skills.
- The same request succeeds when sent directly through Postman.
- API returns **201 Created** instead of a validation error.
- The created assessment appears in the assessment list with **0 skills**.
- Candidate invitation can still be generated for the invalid assessment.

---

## Status
Open


# BUG-003 – Assessment Creation Exposes Database Exception for Excessively Long Role Title

## Severity
**P2 – Minor**

## Area
Assessment → Create Assessment

## Summary

Creating an assessment with a Role Title longer than the maximum allowed length causes the application to expose an internal PostgreSQL database exception instead of returning a user-friendly validation error.

The backend does not properly validate the input before attempting to save it to the database.

---

## Impact

Users are unable to create an assessment when the Role Title exceeds the maximum allowed length.

Instead of receiving a clear validation message, the application exposes an internal PostgreSQL exception (`PG::StringDataRightTruncation`) to the user, resulting in poor user experience and leaking internal implementation details.

---

## Steps to Reproduce

1. Login as an administrator.
2. Navigate to **New Assessment**.
3. Enter a Role Title longer than **255 characters**.
4. Fill the remaining required fields.
5. Click **Save & Create Session**.

---

## Expected Result

The application should validate the Role Title length before saving.

Example:

```http
HTTP/1.1 422 Unprocessable Entity
```

```json
{
  "errors": [
    "Role title must not exceed 255 characters."
  ]
}
```

---

## Actual Result

The application displays the following error:

```text
PG::StringDataRightTruncation:
ERROR: value too long for type character varying(255)
```

The assessment is not created, and the internal database exception is exposed to the user.

---

## Root Cause Analysis

The backend does not validate the maximum length of the Role Title before persisting the assessment.

As a result, the oversized value reaches the PostgreSQL database, which rejects it because it exceeds the `VARCHAR(255)` column limit.

The database exception is then returned directly to the client instead of being handled as a validation error.

---

## Recommendation

Implement server-side validation for the Role Title length before saving the assessment.

Example:

```ruby
validates :name,
          presence: true,
          length: { maximum: 255 }
```

Return a validation response such as **HTTP 422 Unprocessable Entity** with a clear and user-friendly error message instead of exposing internal database exceptions.

---

## Evidence

- Enter a Role Title longer than **255 characters**.
- Click **Save & Create Session**.
- The assessment is not created.
- The UI displays:

```
PG::StringDataRightTruncation:
ERROR: value too long for type character varying(255)
```

- No validation message is shown before the request reaches the database.

---

## Status
Open


# BUG-004 – Insufficient Spacing Between "Expected Skills" Label and "Add Skill" Button

## Severity
**P3 – Cosmetic**

## Area
Vacancies → Edit Vacancy

## Summary

The **"Add skill"** button is displayed immediately adjacent to the **"Expected skills"** label without sufficient spacing, resulting in a cluttered and less readable interface.

---

## Impact

This issue does not affect functionality but reduces visual clarity and overall user experience by making the interface appear unpolished.

---

## Steps to Reproduce

1. Login as an administrator.
2. Navigate to **Vacancies**.
3. Open an existing vacancy.
4. Click **Edit**.
5. Observe the **Expected skills** section.

---

## Expected Result

The **"Expected skills"** label and **"Add skill"** button should have adequate spacing or alignment to improve readability.

Example:

```
Expected skills

[ Add skill ]
```

or

```
Expected skills                      [ Add skill ]
```

---

## Actual Result

The label and button are displayed too close together:

```
Expected skillsAdd skill
```

making the UI appear crowded.

---

## Recommendation

Adjust the layout by adding appropriate spacing or alignment between the label and the action button using margin, padding, or layout components.

---

## Evidence

- Open **Edit Vacancy** page.
- Observe the **Expected skills** section.
- The **Add skill** button is rendered immediately next to the label without spacing.

---

## Status
Open