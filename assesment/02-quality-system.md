# Quality System

## Overview

A lightweight quality gate was implemented to improve the pull request workflow and prevent changes from being merged without minimum quality requirements.

The system combines:
- GitHub Actions
- Pull Request Template
- Automated RSpec execution
- Pull Request requirement validation

The goal is to ensure that every Pull Request includes the necessary project context before code review and automatically verifies that backend tests pass.

---

# Definition of Ready

A Pull Request is considered ready for review only if it contains:

- Specification / PRD reference
- Acceptance Criteria
- Solution / Design Plan

These items are required through the Pull Request Template.

---

# Definition of Done

A Pull Request is considered complete when:

- Quality Gate passes
- RSpec tests pass
- Required Pull Request sections are provided

---

# Automated Checks

The GitHub Actions workflow automatically performs:

1. Validate Pull Request description
2. Check required documentation sections
3. Execute backend RSpec tests

If one of these checks fails, the Pull Request is blocked.

---

# How to Run

Run backend tests locally:

```bash
cd api
bundle install
bundle exec rspec
```

GitHub Actions automatically executes the same validation on every Pull Request.

---

# Protected Risks

This quality system helps reduce:

- Missing project documentation
- Missing acceptance criteria
- Missing implementation plan
- Regression detected by RSpec

---

# Red → Green Demonstration

The workflow gate was demonstrated using two Pull Requests.

### Failed Pull Request

A Pull Request without the required documentation was submitted.

Result:

- Quality Gate failed
- Pull Request was blocked

### Successful Pull Request

A Pull Request with all required sections completed was submitted.

Result:

- Quality Gate passed
- RSpec passed
- Pull Request became mergeable

This demonstrates that the workflow gate is functioning correctly by preventing incomplete Pull Requests while allowing compliant changes to proceed.


# Red → Green Notes

## BUG-001 – Generated Interview Invitation URL Points to Backend Instead of Frontend

### RED

Verified that generated interview invitation URLs pointed to the Rails backend instead of the React frontend.

Result:

- Generated invitation URL used `http://localhost:3001/interview/<invite_token>`.
- Opening the URL returned a Rails Routing Error.
- Candidates were unable to access the interview page.

Root cause:

- The `Session#invite_url` method generated invitation links using `APP_BASE_URL`, which pointed to the backend application instead of the frontend.

### GREEN

Updated the invitation URL generation to use the frontend base URL:

```ruby
base = ENV.fetch("FRONTEND_URL", "http://localhost:5173")
```

Result:

- Generated invitation URLs now point to the React frontend.
- Opening the invitation URL successfully loads the interview page.
- Candidates can access the interview using the generated link.

------

## BUG-002 – Assessment API Allows Creation Without Any Skills

### RED

Added a regression model test to verify that an Assessment without any associated skills should be invalid.

Result:

- Test failed.
- Assessment was still considered valid without any skills.

Root cause:

- The Assessment model did not enforce the business rule requiring at least one associated AssessmentSkill.

### GREEN

Implemented a model validation:

```ruby
validate :must_have_at_least_one_skill
```

which rejects assessments without associated skills.

Result:

- Regression test passes.
- Assessment without skills is now rejected before being persisted.
- Business rule is enforced on the server side.