# IPC 2020 domains — test problems for aria-planner

This directory is the [panda-planner-dev/ipc2020-domains](https://github.com/panda-planner-dev/ipc2020-domains) repository, added as a git submodule. It contains HDDL domains and problem instances from the International Planning Competition (IPC) 2020.

**Use in aria-planner:** These are **reference test problems**. We do not ingest or parse HDDL in the glTF Interactivity pipeline. Domains are **ported** (e.g. via LLM or manual translation) to our interactivity domain and exported as glTF Interactivity (GLB). The submodule provides canonical HDDL so we can:

- Port selected domains/problems to glTF Interactivity and add them as fixtures for export and C executor tests.
- Compare or document behavior against known HTN benchmarks.
- Run tests that require a set of domain/problem names or paths (e.g. list `total-order/` and `partial-order/` domains).

**To update the submodule:** `git submodule update --remote thirdparty/ipc2020-domains`
