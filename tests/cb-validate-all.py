import re, pathlib,sys
from lupa.lua54 import LuaRuntime
r=pathlib.Path(__file__).resolve().parents[2]
names=['cb-libs','cb-bountyhunter','cb-lawarchives','cb-marchives','cb-telegram','cb-wilderness']
tokens=re.compile(r"--\[(=*)\[.*?\]\1\]|\[(=*)\[.*?\]\2\]|--[^\r\n]*|'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\"|`[^`\r\n]*`",re.S)
lua=LuaRuntime(encoding=None)
check=lua.eval(b"function(s,n) local f,e=load(s,n,'t'); return f~=nil,e end")
errors=0
for name in names:
    count=0; failures=[]
    for p in (r/name/name).rglob('*.lua'):
        count+=1
        try:
            src=tokens.sub(lambda m:'0' if m.group(0).startswith('`') else m.group(0),p.read_text(encoding='utf-8-sig'))
            ok,err=check(src.encode(),str(p.relative_to(r)).encode())
            if not ok: failures.append(err.decode('utf-8','replace'))
        except Exception as e: failures.append(str(e))
    print(name,count,'files',len(failures),'errors')
    for e in failures: print(e)
    errors+=len(failures)
sys.exit(bool(errors))
