# AI-Powered DevOps Assistant — Technical Document

> A local-first DevOps AI agent that lets you ask natural-language questions about your live Kubernetes cluster and Docker host, powered by **Ollama (qwen3-coder)**, **LangChain 1.x**, and Python's `subprocess`.
>
> Reference walkthrough: [YouTube — *AI-Powered DevOps Assistant with Ollama + LangChain*](https://www.youtube.com/watch?v=5hjgZuRGT2A).

---

## 1. Executive Summary

This project implements a **chat-driven DevOps copilot** in a single Python file (`agent.py`). The user types a free-form question at the prompt (e.g., *"Which pods are crash-looping?"* or *"How many nginx containers are running?"*). A LangChain **agent** decides whether the question needs live infrastructure state, and if so, calls one of two locally-defined **tools**:

| Tool                  | Underlying command                | Purpose                                  |
|-----------------------|-----------------------------------|------------------------------------------|
| `get_pods`            | `kubectl get pods -A`             | List every pod in every namespace        |
| `get_docker_containers` | `docker ps`                      | List running Docker containers locally   |

The tool output is fed back to the LLM, which produces a final human-readable answer (often highlighting `CrashLoopBackOff`, `Error`, high restart counts, `Exited`, etc.). The model runs **locally via Ollama** — no data leaves the host.

The whole stack is intentionally minimal: **one Python script, three pip packages, one local LLM**.

---

## 2. Repository Layout

```
AI-Powered-masterclass/
├── agent.py              # The entire application (LLM + tools + agent + CLI)
├── requirements.txt      # Python dependencies (LangChain + Ollama bindings)
├── readme.md             # Operator runbook (install, serve, run)
├── .gitignore            # Standard Python + venv ignores
└── venv/                 # Python virtual environment (not committed)
```

There is **no** Dockerfile, no Kubernetes manifest, and no front-end. Everything runs from the operator's shell.

---

## 3. Prerequisites

### 3.1 Hardware / OS

| Requirement | Notes |
|-------------|-------|
| Linux / macOS / WSL2 | Tested on Linux 6.8 (Ubuntu 22.04). |
| RAM            | ≥ 16 GB recommended for `qwen3-coder:30b` (~18 GB on disk; will spill to disk if RAM is short). |
| Disk           | ~20 GB free for the Ollama model cache. |
| (Optional) GPU | Dramatically speeds up inference; not required. |

### 3.2 Software

| Tool          | Minimum version | Why |
|---------------|-----------------|-----|
| **Python**    | 3.10+           | `python3.10-venv` package is referenced in `readme.md`. |
| **Ollama**    | 0.31+           | Runs the local LLM server. |
| **kubectl**   | any recent      | Required for the `get_pods` tool. |
| **Docker**    | any recent      | Required for the `get_docker_containers` tool; the Docker daemon must be running. |
| **A Kubernetes cluster** | kind / minikube / k3d / EKS / GKE — any reachable via `kubectl` | Optional but needed to see real pod data. |
| **jq / curl / bash** | standard      | Used by the setup script in `readme.md`. |

### 3.3 Python packages (from `requirements.txt`)

```
langchain
langchain-core
langchain-ollama
```

Confirmed in this environment:
- `langchain` 1.3.13
- `langchain-core` 1.4.9
- `langchain-ollama` 1.1.0

> **Note on the LangChain version**: this project uses the new **LangChain v1 `create_agent`** factory (imported as `from langchain.agents import create_agent`). In older LangChain versions the equivalent helper lived at `langgraph.prebuilt.create_react_agent`; the underlying ReAct loop is the same.

### 3.4 Ollama model

The `readme.md` install path pulls two models, but the script itself uses only one:

| Model              | Pulled for | Actually used by `agent.py`? |
|--------------------|-----------|------------------------------|
| `llama3.2`         | chat / general | No (left as a reference) |
| `qwen3-coder` / `qwen3-coder:30b` | coding + tool calling | **Yes** (`model="qwen3-coder"`) |

Pull commands:

```bash
ollama serve                                    # start the Ollama daemon
ollama pull qwen3-coder:30b                     # ~18 GB, one-time
ollama list                                     # confirm it is installed
```

---

## 4. Core Components

### 4.1 The LLM — `ChatOllama`

```python
from langchain_ollama import ChatOllama

llm = ChatOllama(
    model="qwen3-coder",          # alias for qwen3-coder:30b
    temperature=0,                # deterministic — best for tool routing
    num_ctx=8192,                 # big enough to fit kubectl/docker output
)
```

* `temperature=0` removes sampling variance, so the agent reliably picks the right tool.
* `num_ctx=8192` is a deliberate buffer — `kubectl get pods -A` on a busy cluster can easily exceed 2-3 K tokens.
* `ChatOllama` speaks the **OpenAI-compatible chat schema** over Ollama's HTTP API (`POST /api/chat`).

### 4.2 The Tools — `@tool`-decorated Python callables

```python
from langchain_core.tools import tool
import subprocess

@tool
def get_pods():
    """Lists the pods of a running kubernetes cluster"""
    result = subprocess.run(["kubectl", "get", "pods", "-A"],
                            capture_output=True, text=True)
    return result.stdout or result.stderr

@tool
def get_docker_containers():
    """Lists the running docker containers"""
    result = subprocess.run(["docker", "ps"],
                            capture_output=True, text=True)
    return result.stdout or result.stderr
```

Key design points:

1. **`@tool` decorator** — wraps the function in a LangChain `BaseTool`. The docstring becomes the tool's natural-language description, which is sent to the LLM so it can decide *when* to call the tool. This is the **single most important piece of metadata** for tool-routing quality.
2. **`subprocess.run(..., capture_output=True, text=True)`** — captures stdout as a string. If stdout is empty (e.g., `docker ps` with no containers, or a kubectl error), the function returns `result.stderr` instead, so the LLM always sees *some* signal.
3. **Read-only by design** — neither tool mutates state. There is no `kubectl delete`, no `docker rm`. This is a safety property of the architecture: even a hallucinated tool call can't harm the cluster.

### 4.3 The Agent — `create_agent`

```python
from langchain.agents import create_agent

agent = create_agent(
    model=llm,
    tools=[get_pods, get_docker_containers],
    system_prompt=( ... )
)
```

`create_agent` is LangChain v1's **prebuilt ReAct agent factory**. Under the hood it:

1. Wraps the LLM in a **tool-aware chat model** that can emit structured tool-call messages.
2. Runs a **ReAct loop**: `think → tool_call → observe → think → ... → final_answer`.
3. Maintains a `messages` list as the agent state — every turn appends to it.

The `system_prompt` is the *contract* that governs tool selection. From `agent.py`:

> *"You are a DevOps assistant … ALWAYS call the relevant tool. Never invent pod or container names … Call out problem states (CrashLoopBackOff, Error, high restarts, Exited) and keep the rest concise … If the question isn't about Kubernetes or Docker, answer briefly and note no tool was needed."*

This single block of text is what turns a generic chat model into a domain expert.

### 4.4 The CLI Loop

```python
question = input("Ask your Kubernetes Agent a Question: >")
response = agent.invoke({"messages": [("user", question)]})
print(response["messages"][-1].content)
```

* `input()` — synchronous REPL prompt.
* `agent.invoke({...})` — runs the full ReAct loop and returns the final state.
* `response["messages"][-1].content` — the last `AIMessage`, i.e. the assistant's final answer.

---

## 5. End-to-End Workflow

The complete request lifecycle, from `> ` prompt to printed answer, is:

```
┌────────────────────────────────────────────────────────────────────────┐
│  1. USER                                                               │
│     Types: "Which pods are crash-looping in the prod namespace?"       │
└────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│  2. agent.py (CLI)                                                     │
│     • Reads input via input()                                          │
│     • Builds initial state:                                            │
│         {"messages": [("user", "<question>")]}                        │
│     • Calls agent.invoke(state)                                        │
└────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│  3. LangChain create_agent — ReAct loop                                │
│     Iteration 1:                                                       │
│       a) LLM (ChatOllama) receives: system_prompt + tools + user msg   │
│       b) LLM decides tool= get_pods, args={}                           │
│       c) Agent executes get_pods()                                     │
│       d) Tool result appended as ToolMessage                           │
│     Iteration 2:                                                       │
│       e) LLM sees tool output, emits final AIMessage                   │
│       f) Agent returns state with [SystemMessage, HumanMessage,        │
│                                    AIMessage(tool_call), ToolMessage, │
│                                    AIMessage(final)]                   │
└────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│  4. Tool execution (subprocess)                                        │
│     get_pods()  →  $ kubectl get pods -A                               │
│                     (or docker ps)                                     │
│     Captures stdout/stderr, returns string to the agent                │
└────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│  5. LLM final synthesis                                                │
│     Reads kubectl output, filters for "CrashLoopBackOff",              │
│     formats a concise answer with problem-state callouts.              │
└────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│  6. CLI prints response["messages"][-1].content                        │
└────────────────────────────────────────────────────────────────────────┘
```

### 5.1 Concrete example trace

User input: `> Are any pods in CrashLoopBackOff?`

1. **HumanMessage**: *"Are any pods in CrashLoopBackOff?"*
2. **AIMessage** (tool call):
   ```json
   {"name": "get_pods", "args": {}}
   ```
3. **ToolMessage** (stdout):
   ```
   NAMESPACE     NAME                       READY   STATUS             RESTARTS   AGE
   kube-system   coredns-66bff467f8-abcde    1/1     Running            0          2d
   prod          checkout-7f9d-xkj2p        0/1     CrashLoopBackOff   14         1h
   prod          payment-5c44-mq7rt          1/1     Running            0          2d
   ```
4. **AIMessage** (final):
   > *"Yes — `prod/checkout-7f9d-xkj2p` is in `CrashLoopBackOff` with 14 restarts. The other pods (`coredns`, `payment`) are healthy."*

---

## 6. Sequence Diagram (text form)

```
User           agent.py        create_agent       ChatOllama        Tool (subprocess)       kubectl/docker
 │                │                  │                 │                    │                       │
 │─ input()  ────▶│                  │                 │                    │                       │
 │                │── invoke()  ────▶│                 │                    │                       │
 │                │                  │── chat() ──────▶│                    │                       │
 │                │                  │                 │                    │                       │
 │                │                  │◀─ AIMessage(tool_call: get_pods) ──│                       │
 │                │                  │── run()  ─────────────────────────▶│                       │
 │                │                  │                                         ────── exec ─────▶│
 │                │                  │                                         ◀──── stdout ────│
 │                │                  │◀─ ToolMessage(stdout) ─────────────────────│                       │
 │                │                  │── chat() ──────▶│                    │                       │
 │                │                  │◀─ AIMessage(final) ──│                       │
 │                │◀─ state ─────────│                 │                    │                       │
 │◀─ print ──────│                  │                 │                    │                       │
```

---

## 7. Workflow Diagram

A **simple, colorful draw.io (mxGraph) XML** diagram accompanies this document at:

> `.kimchi/docs/architecture.drawio`  (80 mxCells · 65 vertices · 13 edges · 12 unique icons · 29 KB · page 1600×900)

Open the file in <https://app.diagrams.net> (drag-and-drop) or with the **Draw.io Integration** VS Code extension.

### 7.1 Layout — four left-to-right lanes

The diagram is a **horizontal workflow** with four coloured swim-lanes. Read left → right:

| Lane | Header colour | Icon | Purpose |
|------|--------------|------|---------|
| **① USER** | Deep blue (`#1E40AF`) | `aws4.user` + `aws4.terminal` + `aws4.client` | Operator types the question, terminal captures input, response prints back |
| **② AGENT** | Purple (`#7C3AED`) | `aws4.ec2` + `aws4.sagemaker` + `aws4.lambda_function` + 2× `aws4.cli` | Python runtime, LangChain `create_agent` block (ChatOllama client, tool registry, system prompt, `messages[]` state), `subprocess.run()`, kubectl & docker CLIs |
| **③ LLM** | Orange (`#EA580C`) | `aws4.ec2` + `cylinder3` GGUF + tool-picker callout | Ollama server on `:11434`, `qwen3-coder:30b` model weights (~18 GB), the brain that picks tools and emits final answers |
| **④ INFRASTRUCTURE** | Green (`#059669`) | `aws4.eks` + `aws4.ecs` + `mxgraph.kubernetes.pod` ×2 + `mxgraph.docker.container` ×2 | Live Kubernetes cluster (with sample pods including a `CrashLoopBackOff` example) and live Docker host (with `nginx:1.27` containers) |

Each lane has a coloured header band and a light-tinted background so the four zones read instantly at a glance.

### 7.2 Colourful arrows — the 6-step workflow

The diagram uses **six thick, colourful arrows** plus one dashed loop-back arrow to tell the end-to-end story:

```
① blue     USER    ──▶  AGENT         "question"
② purple   AGENT   ──▶  LLM           "chat request (prompt + tools)"
②b purple  LLM     ──▶  AGENT         "tool_call JSON (or final answer)"
③ orange   AGENT   ──▶  INFRA         "exec argv: [kubectl, get, pods, -A]"
④ green    INFRA   ──▶  AGENT         "stdout (pod table / container list)"
⑤ teal     ┌──── ReAct loop ─────┐    "iterate until final answer"
⑥ blue     AGENT  ──▶  USER          "final answer printed to stdout"
```

| Arrow | Colour | Stroke | Meaning |
|-------|--------|--------|---------|
| ① | `#2563EB` blue | 3 px solid | User prompt (CLI input) |
| ② / ②b | `#7C3AED` purple | 3 px solid | LLM HTTP traffic — `POST /api/chat`, JSON in both directions |
| ③ | `#EA580C` orange | 3 px solid | `subprocess.exec` — argv passed to kubectl / docker |
| ④ | `#059669` green | 3 px solid | External API — HTTPS to K8s `:6443`, unix socket to Docker |
| ⑤ | `#0EA5E9` teal | 2 px dashed | ReAct control loop — iterate back to LLM with new context |
| ⑥ | `#2563EB` blue | 3 px solid | Final answer returned to user |

Each arrow has a **white-background label** (`labelBackgroundColor=#FFFFFF`) so the protocol annotations read cleanly across the colored lanes.

### 7.3 Footer legend

A dark navy legend band at the bottom of the diagram shows all six arrow styles with their semantic meanings, so the diagram is self-explanatory without a separate readme.

### 7.4 Key visual elements

* **Drop shadows** on every box give the diagram a modern, polished look.
* **AWS4 resource icons** are used throughout — they ship with built-in brand colours so the diagram is colorful by default (no extra fill tweaking needed).
* **Native K8s pod icons** (`mxgraph.kubernetes.icon`) and **Docker container icons** (`mxgraph.docker.container`) appear directly in the Infrastructure lane, making the actual outputs of `kubectl get pods` and `docker ps` instantly recognisable.
* **A "🔒 local-only · no data egress" badge** in green sits in the USER lane to reinforce the most important security property of the system.
* **A yellow sample-question callout** (`"Which pods are in CrashLoopBackOff?"`) anchors the diagram to a concrete worked example.

---

## 8. Security & Safety Considerations

| Concern | Mitigation in this project |
|---------|---------------------------|
| LLM hallucinating destructive commands | Tools are **read-only** (`get`, `ps`). No `delete`, `exec`, `apply`, or `run` is exposed. |
| Prompt injection via tool output | Tool output is rendered as a `ToolMessage` and is *not* re-injected as instructions. The system prompt reinforces "answer only from tool output". |
| Local data exfiltration | The LLM runs entirely on-host via Ollama. No outbound calls to OpenAI / Anthropic / cloud LLM. |
| Privilege escalation via kubectl/docker | Whatever the user can run in their shell, the agent can run. Run as a low-privilege user if exposing beyond dev. |
| Sensitive data in tool output | `kubectl get pods -A` may surface namespace/pod names. Treat the model's printed output as if it were `kubectl` output directly. |

---

## 9. Extending the Project

Common next steps (not implemented, but architecturally straightforward):

1. **Add more tools** — wrap `kubectl describe`, `kubectl logs`, `kubectl top`, `docker stats`, `docker inspect` in `@tool` functions. The agent will route to them automatically based on docstring + system prompt.
2. **Switch model** — change `model="qwen3-coder"` to `llama3.2`, `mistral`, `gemma3`, etc. (Any model Ollama serves that supports tool/function calling.)
3. **Persistent memory** — wrap the `invoke` call so `messages` accumulates across turns (chat session).
4. **Web UI** — replace `input()/print()` with a FastAPI endpoint + simple HTML page.
5. **MCP upgrade path** — the project name (`AI-Powered-masterclass`) and folder structure (`.kimchi/`) hint at a follow-up: swap the in-process `@tool` functions for an **MCP server** (e.g., the official `kubernetes-mcp-server`) and connect via `langchain-mcp-adapters`. The `agent.py` interface stays the same.

---

## 10. Quick-Start Runbook

```bash
# 1. Install Ollama and the model
curl -fsSL https://ollama.com/install.sh | sh
ollama serve &                              # daemon on :11434
ollama pull qwen3-coder:30b                 # ~18 GB

# 2. Spin up some demo workloads (optional)
for i in {1..10}; do docker run -d --name "my-container-$i" nginx; done

# 3. Set up Python
apt install python3.10-venv                 # one-time
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. Run the agent
python3 agent.py
# Ask your Kubernetes Agent a Question: > How many nginx containers are running?
```

---

## 11. Glossary

| Term | Meaning |
|------|---------|
| **ReAct** | "Reason + Act" — an agent pattern where the LLM alternates between natural-language reasoning and tool calls. |
| **Tool / Function calling** | An LLM feature where the model emits a structured JSON payload naming a function and its arguments instead of free-form text. |
| **Ollama** | A local LLM runner that exposes an OpenAI-compatible HTTP API and stores GGUF model weights on disk. |
| **LangChain `create_agent`** | A v1 factory that builds a ReAct agent from a model + tools + prompt in one call. |
| **System prompt** | A persistent instruction message prepended to every conversation; here it defines the agent's role and tool-routing rules. |
| **`@tool` decorator** | Turns a Python function into a LangChain `BaseTool`, using the docstring as the tool description. |

---

*Document version 1.0 — generated for the `AI-Powered-masterclass` project. Source video: <https://www.youtube.com/watch?v=5hjgZuRGT2A>.*
