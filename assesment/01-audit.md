# BUG-001 – Generated Interview Invitation URL Points to Backend Instead of Frontend

## Severity
**P1 – Major**

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
**P2 – Minor**

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