@echo off
cd /d "%~dp0"
call D:\miniconda\condabin\conda.bat run -n flavorlog uvicorn main:app --host 127.0.0.1 --port 8001 > backend_8001.log 2>&1
