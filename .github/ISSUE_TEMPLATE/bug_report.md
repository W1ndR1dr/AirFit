name: Bug report
description: File a bug report
title: "bug: <summary>"
labels: [bug]
body:
  - type: textarea
    id: description
    attributes:
      label: Description
      description: What happened and what did you expect?
    validations:
      required: true
  - type: textarea
    id: repro
    attributes:
      label: Reproduction steps
      description: Minimal steps to reproduce, including commands and environment
      placeholder: |
        1. ...
        2. ...
        3. ...
    validations:
      required: true
  - type: textarea
    id: logs
    attributes:
      label: Logs / Screenshots
  - type: input
    id: version
    attributes:
      label: Environment
      description: iOS version, device/simulator, Xcode version

