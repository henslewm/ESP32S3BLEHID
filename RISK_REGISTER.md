# Risk Register

| ID | Risk | Likelihood | Impact | Mitigation | Owner | Status |
|---|---|---|---|---|---|---|
| ESP-R01 | Baseline overwritten | Medium | High | Hash before/after; fresh import destinations; isolated editable sketch | Codex | Controlled during import |
| ESP-R02 | Duplicate full sketches compiled together | Medium | High | Build only firmware/BLEScanner_WORKING_v7; evidence is not a build target | Codex | Mitigated |
| ESP-R03 | Input causes unintended host actions, stuck modifiers or reset | Medium | High | Observe first; no modifiers; mouse-only t after fresh mouse_sub=yes; operator authority | Operator/Codex | Open |
| ESP-R04 | History/compile mistaken for hardware proof | Medium | High | Label source and evidence level; exact-build operator observations for acceptance | Integrator | Open |
| ESP-R05 | Wrong core/backend, cache or security assumptions | Medium | High | Inspect exact implementation/recipe; capture subscriptions/security and host/unit identity | Codex/operator | Open |
| ESP-R06 | Publish to template origin | Medium | High | Use explicit verified henslewm/ESP32S3BLEHID target; origin now points there | Codex | New private project created at user's request; no template repository write |
| ESP-R07 | Old template task queue or setup mistaken for authority | Medium | High | Archived controls; project records; unchanged foundation activated using carried Winston approval | Codex | ACTIVE validated; no inherited issue execution |
| ESP-R08 | Independent acceptance reviewer unavailable | Medium | Medium | Arrange eligible cross-family review; no invented waiver | Integrator | Pending |
| ESP-R09 | External fallback Python disappears | Medium | Medium | Record and recheck exact runtime each session | Codex | Known limitation |
| ESP-R10 | Wrong-target or uncertain pairing mutation | Medium | High | Explicit address, AEP kind, duplicate rejection, fresh postchecks, cancellation, no retries | Codex/operator | Mocked checks pass; live evidence pending |
| ESP-R11 | Telemetry absence or observer activity misread as detection evidence | High | Medium | Lifetime/GUID correlation, coverage gaps, fragment flags, explicit target links, local-only claims | Codex/operator | Sysmon missing; Wazuh stopped; configuration unchanged |
| ESP-R12 | Running firmware assumed identical to preserved v7 | Medium | High | Label operator observations separately; require exact flashed artifact before firmware acceptance | Operator/Codex | Supplied serial has address/type99 instrumentation absent from checked-in printSystemInfo; do not infer type99 meaning |
| ESP-R13 | Command-tool console windows steal user keyboard focus | High | Medium | Captured managed-session output and hidden child helpers; report unverified window behavior honestly | Codex | Background-check command exited 0; silence/focus behavior not separately confirmed; earlier inferred shell hold withdrawn |
