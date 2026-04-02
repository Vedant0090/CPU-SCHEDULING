# ⚡ CPU Scheduling Simulator — Bash Script

A fully interactive **CPU Process Scheduling Simulator** written in pure Bash.
Runs directly on Ubuntu/Linux — **no compiler, no dependencies** required.

---

## 📋 Algorithms Supported

| # | Algorithm | Type |
|---|-----------|------|
| 1 | **FCFS** — First Come First Serve | Non-Preemptive |
| 2 | **SJF** — Shortest Job First | Non-Preemptive |
| 3 | **Priority Scheduling** | Non-Preemptive |
| 4 | **Round Robin** | Preemptive (with Time Quantum) |

---

## 🚀 How to Run

```bash
# Step 1: Give execute permission
chmod +x cpu_scheduling.sh

# Step 2: Run
./cpu_scheduling.sh
```

> **Requires:** Bash + `awk` (both pre-installed on all Ubuntu/Linux systems)

---

## 🖥️ Output for Each Algorithm

- ✅ Color-coded **Gantt Chart** with timestamps
- ✅ **Completion Time** — when the process finishes
- ✅ **Turnaround Time (TAT)** = Completion − Arrival
- ✅ **Waiting Time (WT)** = TAT − Burst
- ✅ **Response Time** = First CPU access − Arrival
- ✅ **Average Waiting Time**
- ✅ **Average Turnaround Time**
- ✅ **CPU Utilization %**
- ✅ **Total Time Span**

---

## 📥 Sample Input

```
Number of processes: 4

Process 1 → PID: P1  | Arrival: 0 | Burst: 8
Process 2 → PID: P2  | Arrival: 1 | Burst: 4
Process 3 → PID: P3  | Arrival: 2 | Burst: 9
Process 4 → PID: P4  | Arrival: 3 | Burst: 5
```

---

## 📤 Sample Output (FCFS)

```
  +--------+--------+--------+--------+
  |   P1   |   P2   |   P4   |   P3   |
  +--------+--------+--------+--------+
  0        8        12       17       26

  PID      Arrival    Burst      Completion   Turnaround     Waiting        Response
  ──────────────────────────────────────────────────────────────────────────────────
  P1       0          8          8            8              0              0
  P2       1          4          12           11             7              7
  P3       2          9          26           24             15             15
  P4       3          5          17           14             9              9

  ► Average Waiting Time     : 7.75
  ► Average Turnaround Time  : 14.25
  ► CPU Utilization          : 100.00%
  ► Total Processes          : 4
  ► Total Time Span          : 26 units
```

---

## 📌 Notes

- **Priority Scheduling:** Lower number = Higher priority (e.g., priority 1 runs before priority 5)
- **Round Robin:** You will be prompted to enter the Time Quantum before process input
- **SJF & Priority** are implemented as **non-preemptive**
- **Idle gaps** are shown in the Gantt chart when CPU has no process to run
- After each run, press **Enter** to return to the main menu

---

## 📁 File Structure

```
cpu_scheduling.sh     ← Main script (single file, no dependencies)
README.md             ← This file
```

---

## 🧠 Concepts Covered

- Process scheduling and CPU burst allocation
- Idle time handling between processes
- Gantt chart visualization
- Performance metrics: WT, TAT, Response Time, CPU Utilization
- Queue-based Round Robin with dynamic enqueue

---

## 🛠️ Tested On

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS
- Any system with Bash 4+ and awk

---

## 📄 License

MIT License — free to use, modify, and distribute.
