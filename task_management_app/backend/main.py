from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from typing import Optional, List
import sqlite3
import os
import bcrypt
from datetime import datetime, timedelta
import jwt

app = FastAPI(title="Task Management API")

# Enable CORS for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_FILE = "tasks.db"

# Security Configurations
SECRET_KEY = "super_secret_key_change_in_production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7 # 7 Days

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def get_db():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    # Create Users table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            hashed_password TEXT NOT NULL
        )
    ''')
    # Backup existing tasks just in case, or drop and recreate. Let's drop and recreate as agreed.
    cursor.execute('DROP TABLE IF EXISTS tasks')
    cursor.execute('''
        CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            due_date TEXT NOT NULL,
            status TEXT NOT NULL,
            blocked_by INTEGER,
            user_id INTEGER NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    ''')
    conn.commit()
    conn.close()

@app.on_event("startup")
def startup():
    if not os.path.exists(DB_FILE + ".init"):
        init_db()
        # Create a file so we don't drop tasks on every startup!
        open(DB_FILE + ".init", "w").close()

# --- Auth Models & Logic ---
class Token(BaseModel):
    access_token: str
    token_type: str

class UserCreate(BaseModel):
    username: str
    password: str

class UserInDB(BaseModel):
    id: int
    username: str
    hashed_password: str

def verify_password(plain_password, hashed_password):
    try:
        return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
    except Exception:
        return False

def get_password_hash(password):
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)) -> UserInDB:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except jwt.PyJWTError:
        raise credentials_exception
        
    conn = get_db()
    user_row = conn.execute("SELECT * FROM users WHERE username = ?", (username,)).fetchone()
    conn.close()
    
    if user_row is None:
        raise credentials_exception
    return UserInDB(**dict(user_row))

@app.post("/register")
def register_user(user: UserCreate):
    conn = get_db()
    try:
        existing = conn.execute("SELECT * FROM users WHERE username = ?", (user.username,)).fetchone()
        if existing:
            raise HTTPException(status_code=400, detail="Username already registered")
            
        hashed_password = get_password_hash(user.password)
        cursor = conn.cursor()
        cursor.execute("INSERT INTO users (username, hashed_password) VALUES (?, ?)", 
                       (user.username, hashed_password))
        conn.commit()
        return {"message": "User created successfully"}
    finally:
        conn.close()

@app.post("/token", response_model=Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    conn = get_db()
    user_row = conn.execute("SELECT * FROM users WHERE username = ?", (form_data.username,)).fetchone()
    conn.close()
    
    if not user_row or not verify_password(form_data.password, user_row['hashed_password']):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    access_token = create_access_token(data={"sub": user_row['username']})
    return {"access_token": access_token, "token_type": "bearer"}

# --- Task Models & Endpoints ---
class TaskBase(BaseModel):
    title: str
    description: str
    due_date: str
    status: str
    blocked_by: Optional[int] = None

class Task(TaskBase):
    id: int
    user_id: int

@app.post("/tasks", response_model=Task)
def create_task(task: TaskBase, current_user: UserInDB = Depends(get_current_user)):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO tasks (title, description, due_date, status, blocked_by, user_id)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (task.title, task.description, task.due_date, task.status, task.blocked_by, current_user.id))
    conn.commit()
    new_id = cursor.lastrowid
    conn.close()
    
    return Task(id=new_id, user_id=current_user.id, **task.dict())

@app.get("/tasks", response_model=List[Task])
def get_tasks(current_user: UserInDB = Depends(get_current_user)):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM tasks WHERE user_id = ?', (current_user.id,))
    rows = cursor.fetchall()
    conn.close()
    return [Task(**dict(row)) for row in rows]

@app.put("/tasks/{task_id}", response_model=Task)
def update_task(task_id: int, task: TaskBase, current_user: UserInDB = Depends(get_current_user)):
    conn = get_db()
    cursor = conn.cursor()
    # Check ownership
    existing = cursor.execute('SELECT id FROM tasks WHERE id = ? AND user_id = ?', (task_id, current_user.id)).fetchone()
    if not existing:
        conn.close()
        raise HTTPException(status_code=404, detail="Task not found or not owned by user")
        
    cursor.execute('''
        UPDATE tasks
        SET title = ?, description = ?, due_date = ?, status = ?, blocked_by = ?
        WHERE id = ? AND user_id = ?
    ''', (task.title, task.description, task.due_date, task.status, task.blocked_by, task_id, current_user.id))
    conn.commit()
    conn.close()
    return Task(id=task_id, user_id=current_user.id, **task.dict())

@app.delete("/tasks/{task_id}")
def delete_task(task_id: int, current_user: UserInDB = Depends(get_current_user)):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM tasks WHERE id = ? AND user_id = ?', (task_id, current_user.id))
    if cursor.rowcount == 0:
        conn.close()
        raise HTTPException(status_code=404, detail="Task not found or not owned by user")
    conn.commit()
    conn.close()
    return {"message": "Task deleted"}
