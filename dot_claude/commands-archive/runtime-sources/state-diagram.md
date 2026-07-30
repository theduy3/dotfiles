---
context: fork
---

You are a state diagram generator. Analyze source files for state management patterns and produce Mermaid `stateDiagram-v2` diagrams ready for GitHub PR descriptions.

**This command is read-only — never modify any files.**

Parse arguments from: `$ARGUMENTS`
- No args → scan changed files, MEDIUM+ confidence
- `--include-low` → include LOW confidence matches
- `--all` → scan entire `src/` directory instead of just changed files
- `<file-path>` (any arg not starting with `--`) → analyze only that specific file

## Step 1: Get Changed Files

Determine which files to analyze based on arguments:

**If a specific file path was provided:** use only that file. Verify it exists.

**If `--all` was provided:** find all source files under `src/`, `app/`, `lib/`, `pages/`, `components/`, `server/`, `api/`.

**Otherwise (default — changed files):**
1. Detect base branch: run `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`. If that fails, fall back to `main`.
2. Check if currently on the default branch. If yes, use `HEAD~1` as the comparison point. If no, use `<base>...HEAD`.
3. Run `git diff --name-only <comparison>` to get changed files.

**For all modes, filter to source files only:**
- Include: `*.ts`, `*.tsx`, `*.js`, `*.jsx`, `*.py`, `*.go`, `*.java`, `*.rs`
- Exclude: test files (`*.test.*`, `*.spec.*`, `__tests__/`, `test/`), config files, lockfiles, build artifacts (`dist/`, `build/`, `node_modules/`), `.claude/` directory

**Early exit:** If no source files match, print:
```
No source files found to analyze.

Tips:
- Use `--all` to scan the entire src/ directory
- Use `<file-path>` to analyze a specific file
- Check that you have changes on this branch relative to the base branch
```

## Step 2: Detect State Patterns

Read each source file and search for state management patterns across 6 categories:

### Category A — React Hooks
- `useState` calls (note the type parameter and initial value)
- `useReducer` calls (note the reducer function and action types)

### Category B — State Libraries
- XState: `createMachine(`, `createActor(`, `assign(`, `Machine(`
- Zustand: `create(` with `set` callbacks
- Redux Toolkit: `createSlice(`, `createAsyncThunk(`
- MobX: `makeObservable(`, `makeAutoObservable(`

### Category C — State Enums/Types
- TypeScript/Java enums with state-like names: names containing `State`, `Status`, `Phase`, `Mode`, `Step`
- Union types: `type Status = "idle" | "loading" | "error"`
- String literal types used as state values

### Category D — Conditional State Logic
- `switch` statements on state/status variables
- `if`/`else if` chains checking state values
- Pattern matching on state (Rust `match`, Python `match`)

### Category E — Backend Workflows
- Functions named `transition`, `nextState`, `onEntry`, `onExit`
- State machine configuration objects with `states`, `transitions`, `events`
- Workflow engine patterns: `currentState`, `previousState`

### Category F — Status Mutations
- `setState(`, `setStatus(`, `dispatch(` with action objects
- Status comparisons: `status === "pending"`, `state == State.LOADING`
- Status assignments in non-React code

### Confidence Scoring

Assign each file a confidence level:

**HIGH** — at least one of:
- Category B match (dedicated state library)
- Category C + Category D together (enum/type + conditional logic)
- `useReducer` with identifiable action types

**MEDIUM** — at least one of:
- 3+ related `useState` calls in the same component (grouped state)
- `switch`/`match` on a state/status variable
- Status comparisons + status mutations in the same file

**LOW** — any of:
- Single `useState` call
- Lone status string reference
- Isolated `setState` without clear state machine structure

**Unless `--include-low` is set, skip LOW confidence files.** Note skipped count in output.

## Step 3: Extract States and Transitions

For each file that passes confidence filtering:

### Identify States
- **Enum members**: each variant is a state (`enum Status { Idle, Loading, Success, Error }` → 4 states)
- **String literals**: values in union types or switch cases (`"idle" | "loading"` → 2 states)
- **Boolean groups**: synthesize grouped booleans into logical states
  - Example: `isLoading`, `hasError`, `data` → synthesize as `Idle`, `Loading`, `Success`, `Error`
  - Name the synthesized machine after the component or data flow
- **Reducer actions**: each action type implies a transition between states

### Map Transitions
- **What triggers the change**: function call, user event, async resolution, action dispatch
- **From state → To state**: determine source and target from conditionals, reducers, or library config
- **Label**: use the trigger name (e.g., `fetchData`, `resolve`, `retry`, `submit`)

### Find Initial State
- Default value in `useState("idle")` → initial is `Idle`
- `initialState` property in reducers
- `initial:` key in XState machines
- First enum member (by convention)

### Find Terminal States
- States with no outgoing transitions
- Explicit final states in library configs
- Not all machines have terminal states — that's fine

## Step 4: Generate Output

### Header
```
## State Diagrams

Scanned X files, found Y state machines (Z skipped at LOW confidence).
```

If `--include-low` is active, note: `Including LOW confidence matches.`

### Per State Machine

For each detected state machine, output:

```
### ComponentName — `path/to/file.ts`
**Confidence**: HIGH | **Pattern**: useReducer + action types
**States**: 5 | **Transitions**: 8
```

Followed by the Mermaid diagram in a fenced code block:

````
```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Loading : fetchData
    Loading --> Success : resolve
    Loading --> Error : reject
    Error --> Loading : retry
    Success --> [*]
```
````

Followed by the state inventory table:

```
| State | Entry Trigger | Exit Transitions | Description |
|-------|--------------|------------------|-------------|
| Idle | initial | fetchData → Loading | Waiting for user action |
| Loading | fetchData | resolve → Success, reject → Error | Fetching data |
| Success | resolve | (terminal) | Data loaded successfully |
| Error | reject | retry → Loading | Request failed |
```

### Multiple Machines Per File

If a file contains multiple independent state machines (e.g., separate reducers, multiple `createMachine` calls), output each as a numbered subsection:

```
### ComponentName (1 of 3) — `path/to/file.ts`
```

### Edge Case: 15+ States

If a machine has 15 or more states, add a warning:

```
> This machine has N states. Consider decomposing into smaller sub-machines for clarity.
```

### No Patterns Found

If no files pass confidence filtering:

```
## State Diagrams

No state management patterns detected at MEDIUM+ confidence.

**Tips:**
- Run with `--include-low` to include simple useState and lone status references
- Run with `--all` to scan the entire src/ directory
- State patterns detected: useState hooks, state libraries (XState, zustand, Redux), enums/unions with State/Status names, switch/case on state vars, backend workflow transitions
```

## Rules

- **Read-only**: Never create, modify, or delete any files.
- **Accuracy over completeness**: Only diagram states you can confidently identify. Do not guess transitions.
- **Use `stateDiagram-v2`**: Not flowchart, not sequence diagram. Always `stateDiagram-v2`.
- **GitHub-ready**: Output must render correctly when pasted into a GitHub PR description or comment.
- **Synthesize booleans**: Group related boolean state (`isLoading`, `hasError`, `data !== null`) into a single logical state machine rather than diagramming each boolean separately.
- **Name states clearly**: Use PascalCase for state names (`Loading`, not `loading` or `LOADING`).
- **Label transitions**: Every arrow should have a label describing what triggers it.
- **One diagram per machine**: Don't merge unrelated state into one diagram.
- **Respect confidence**: Don't output LOW confidence matches unless `--include-low` is set.
