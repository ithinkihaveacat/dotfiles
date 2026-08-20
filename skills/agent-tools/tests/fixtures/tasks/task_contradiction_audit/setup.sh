#!/usr/bin/env bash
set -euo pipefail

git init -q .
git config user.email "benchmark@test.local"
git config user.name "Benchmark Runner"

mkdir -p policies

cat <<'SUBEOF' >policies/data_retention.md
# Corporate Data Retention Policy

## Audit Logging
User activity and authentication audit logs must be permanently purged after exactly 90 days to minimize storage liability and privacy risk. No exceptions are granted without legal department sign-off.
SUBEOF

cat <<'SUBEOF' >policies/security_access.md
# Security & Access Control Policy

## Compliance Audit Trails
All access control logs, authentication records, and privileged session recordings must be preserved for a minimum duration of 365 days to comply with regulatory security auditing frameworks.

## Personnel Screening
All new personnel requesting system credentials must undergo a security clearance background investigation with a mandatory 14-business-day review window before account activation.
SUBEOF

cat <<'SUBEOF' >policies/remote_work.md
# Remote Work Guidelines

## Home Office Setup
Full-time remote employees are eligible for a $500 one-time home office equipment stipend upon onboarding. Subsequent equipment upgrades must be self-funded.
SUBEOF

cat <<'SUBEOF' >policies/expenses.md
# Employee Expense Reimbursement Policy

## Office Equipment
Remote staff may submit expense reports for home office equipment reimbursement up to $1,200 annually, subject to manager pre-approval.
SUBEOF

cat <<'SUBEOF' >policies/hiring_onboarding.md
# Hiring and Onboarding Procedures

## Candidate Screening
Standard candidate background checks must conclude within 5 business days prior to the agreed employee start date. Credentials will be issued on Day 1.
SUBEOF

git add policies/
git commit -q -m "Initial company policy documents"
