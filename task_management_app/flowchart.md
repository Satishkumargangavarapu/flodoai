# Application Flowchart

Here is the flowchart representing the task management application's functionality. The code analysis confirmed that all buttons (filters, search, add task, edit task, delete, date pickers, drop downs) are fully wired up in the code.

```mermaid
graph TD
    A[Launch App: TaskListScreen] --> B{Tasks Exist?};
    B -- Yes --> C[List of TaskCards];
    B -- No --> D[No Tasks Found UI];
    
    A --> E[AppBar Filter Dropdown];
    E -->|Select Status| F[Filter Tasks by Status];
    
    A --> G[Search Bar];
    G -->|Type Text| H[Filter Tasks by Title];
    
    A --> I[FAB: Add Task];
    I --> J[TaskEditScreen Create Mode];
    
    C --> K[Tap TaskCard];
    K --> L[TaskEditScreen Edit Mode];
    
    C --> M[Tap Delete Button];
    M --> N[Delete Task & Refresh List];
    
    J --> O[Fill Form: Title, Desc, Due, Status, BlockedBy];
    L --> O;
    O --> P[Tap Save Task];
    P -- Valid --> Q[Save to SQLite DB];
    Q --> R[Return to TaskListScreen];
    P -- Invalid --> S[Show Validation Error];
```
