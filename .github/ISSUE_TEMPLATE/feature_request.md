name: Feature request
description: Propose a new feature or enhancement
title: "feat: <summary>"
labels: [enhancement]
body:
  - type: textarea
    id: summary
    attributes:
      label: Summary
      description: What problem does this solve? Who benefits?
    validations:
      required: true
  - type: textarea
    id: acceptance
    attributes:
      label: Acceptance criteria
      description: Measurable exit criteria and constraints
      placeholder: |
        - [ ] ...
        - [ ] ...
    validations:
      required: true
  - type: textarea
    id: scope
    attributes:
      label: Scope
      description: Modules/files expected to change
  - type: textarea
    id: risks
    attributes:
      label: Risks / Rollback

