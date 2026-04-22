---
name: hightower
version: "1.0.0"
description: "Interact with the Hightower pentest API — start scans, check status, retrieve reports. Hightower is a K8s-deployed penetration testing platform. Use when you need to run a security scan, check scan progress, or retrieve findings."
allowed-tools: Bash, Read
---

# Hightower: Penetration Testing API

Hightower is deployed in the `hightower` namespace on Kubernetes. It exposes a REST API for scan management and a Temporal cluster for workflow orchestration.

## Configuration

All settings come from environment variables:

| Variable | Description |
|----------|-------------|
| `HIGHTOWER_API_URL` | Hightower REST API base URL (e.g., `http://hightower-api.hightower:3000`) |
| `HIGHTOWER_API_TOKEN` | Bearer auth token for the Hightower API |

---

## Common Operations

### List all scans

```bash
curl -s -H "Authorization: Bearer $HIGHTOWER_API_TOKEN" \
  "$HIGHTOWER_API_URL/api/scans"
```

### Start a new scan

```bash
curl -s -X POST "$HIGHTOWER_API_URL/api/scans" \
  -H "Authorization: Bearer $HIGHTOWER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "targetUrl": "https://example.com",
    "gitUrl": "https://github.com/user/repo",
    "workspace": "my-workspace"
  }'
```

Response: `{ "id": "hightower-worker-abc123", "workspace": "my-workspace", "status": "running" }`

### Get scan status by workspace name

```bash
curl -s -H "Authorization: Bearer $HIGHTOWER_API_TOKEN" \
  "$HIGHTOWER_API_URL/api/scans?workspace=my-workspace"
```

The `workspace` filter returns all jobs for that workspace. Look for `status: "completed"` or `status: "running"`.

### Get scan report

```bash
curl -s -H "Authorization: Bearer $HIGHTOWER_API_TOKEN" \
  "$HIGHTOWER_API_URL/api/scans/{workspace}/report"
```

Returns the full markdown report. Use `workspace` name, not job ID.

### Cancel a running scan

```bash
curl -s -X POST "$HIGHTOWER_API_URL/api/scans/{id}/cancel" \
  -H "Authorization: Bearer $HIGHTOWER_API_TOKEN"
```

---

## Report Format

The report is a markdown file with the following structure:

```
# Comprehensive Security Assessment Report

## Executive Summary
- Assessment Date: YYYY-MM-DD
- Target: https://example.com
- Model: MiniMax-M2.7

## Findings

### [CRITICAL|HIGH|MEDIUM|LOW] Title
- **Location:** URL or code reference
- **Description:** ...
- **PoC:** ...
- **Remediation:** ...
```

## Parsing Findings

Extract findings by looking for `### [SEVERITY]` headers:

```bash
# Extract all finding titles and severities
grep -E "^### \[(CRITICAL|HIGH|MEDIUM|LOW)\]" report.md

# Extract CRITICAL and HIGH findings only
grep -A 10 "^### \[CRITICAL\]" report.md
grep -A 10 "^### \[HIGH\]" report.md
```

## Scan Lifecycle

1. **running** — Job is active, worker processing
2. **completed** — Job succeeded, report available at `{workspace}/report`
3. **failed** — Job failed (check pod logs)

Typical runtime: ~36 minutes for a full 13-agent pipeline.

---

## Notes

- Reports are private to the cluster (PVC); fetch via the API
- For Paperclip issues from findings, parse the report and create issues via the Paperclip API