# Personal AI Usage Charter (DWP Desktop/Endpoint Engineer)

Version: 1.1  
Date: 2026-08-03  
Owner: [Your Name]

## Purpose
I use public AI assistants to speed up desktop/endpoint engineering work while protecting DWP data, users, and services. This charter supports, and does not replace, DWP policy, security standards, and change controls.

## 1) DWP Tasks Appropriate for Public LLM Help
I will use public LLMs only for low-risk, generic work with no internal identifiers.

Appropriate examples:
- Drafting command patterns for routine endpoint tasks (service checks, event log filtering, file operations).
- Producing starter scripts using dummy values and placeholder hostnames.
- Explaining Windows, Intune, GPO, patching, certificate, and networking concepts.
- Creating checklists, runbook templates, rollback templates, and incident note structures.
- Rewriting technical updates for end users in plain language.
- Brainstorming likely root-cause paths from anonymised symptoms.

## 2) DWP Tasks Not Appropriate for Public LLM Help
I will not use public LLMs for any work that exposes internal, sensitive, or security-relevant operational detail.

Not appropriate examples:
- Pasting real incident logs, screenshots, or command output from DWP devices.
- Sharing production hostnames, device names, usernames, IP ranges, tenant details, asset tags, ticket IDs, or architecture details.
- Requesting advice on privileged access workflows, security controls, detection logic, vulnerabilities, or bypass techniques.
- Uploading real scripts/configuration tied to DWP environment controls.
- Using AI outputs as direct authority for production decisions without standard approval and review.

## 3) Data-Handling Rule for End-User PII and Credentials
Absolute rule: I never enter end-user PII, credentials, or secrets into a public AI assistant.

This includes:
- Personal data (name, NI number, date of birth, address, email, phone, case reference).
- Account identifiers linked to individuals.
- Passwords, MFA codes, API keys, tokens, certificates, private keys, cookies, recovery codes.

Handling standard:
- Use synthetic examples only.
- Redact all potentially identifying values with placeholders (for example, `<USER_ID>`, `<DEVICE_ID>`, `<IP_X>`).
- If safe redaction is not possible, stop and use approved internal support channels.

## 4) Personal Generate-Then-Verify Rule (Scripts and System Changes)
I treat AI output as a draft, never as a final instruction.

Generate:
- Ask for draft scripts/commands with assumptions, prerequisites, and rollback notes.
- Ask for least-privilege and dry-run options where relevant.

Verify before any execution:
- Read and understand every line.
- Validate against trusted references (Microsoft documentation, DWP standards, internal runbooks).
- Test in sequence: lab/sandbox -> pilot endpoint -> controlled rollout.
- Record expected outcome, blast radius, and rollback path.
- Use peer review for high-impact changes (security baseline, startup scripts, encryption, identity, patch rings).
- If anything is unclear, do not run it.

## Quick Decision Gate
Before using public AI, I ask:
1. Does this contain PII, credentials, or internal identifiers? If yes, stop.
2. Would disclosure create security or operational risk? If yes, stop.
3. Can I rewrite it as a generic synthetic problem? If no, stop.
4. Have I planned verification before execution? If no, stop.

## Commitment
I remain accountable for correctness, safety, and data protection. Public AI is a drafting aid, not an approval path.
