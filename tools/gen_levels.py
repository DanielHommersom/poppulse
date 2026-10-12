import json, sys
# name, element, board, goal, time, mistakes, si, lt, ma, sim, decoy, pattern, x_end
ring5x6=[0,1,2,3,4,9,14,19,24,29,28,27,26,25,20,15,10,5]
zig5x6=[0,6,2,8,4,9,13,17,21,25,26,22,18,14,10,5]
diag5x6=[[0,4],[6,8],[12],[16,18],[20,24],[25,29],[21,23],[17],[11,13],[5,9]]
cross5x6=[[2],[7],[12],[17],[22],[27],[10],[11],[13],[14]]
L=[
 # Block 1 — more at once
 ("First Pops","basics",[4,5],10,30,5,[1.0,.85],[2.4,2.0],[1,1],1,0,None,20),
 ("Warming Up","basics",[4,5],12,30,5,[.95,.8],[2.2,1.8],[1,2],1,0,None,20),
 ("Two's Company","two targets live",[4,5],14,32,4,[.9,.75],[2.0,1.7],[1,2],1,0,None,25),
 ("Keep Up","two targets live",[4,5],16,34,4,[.85,.7],[1.9,1.6],[2,2],1,0,None,25),
 ("Rush Hour","peak",[4,5],22,36,3,[.75,.6],[1.7,1.4],[2,3],1,0,None,28),
 ("Double Tap","doubles (lit in pairs)",[4,5],14,32,4,[1.0,.9],[2.2,2.0],[2,2],2,0,None,25),
 ("Pairs","doubles",[4,5],18,34,4,[.95,.85],[2.1,1.8],[2,2],2,0,None,25),
 ("Triple Threat","three targets live",[4,5],20,35,4,[.95,.8],[2.0,1.7],[2,3],2,0,None,28),
 ("Crowded","up to four live",[4,5],22,36,3,[.9,.75],[1.9,1.6],[2,4],2,0,None,30),
 ("Swarm","peak",[4,5],28,40,3,[.85,.65],[1.8,1.45],[3,4],2,0,None,32),
 # Block 2 — shorter lifetime
 ("Quick Fade","shorter lifetime",[5,5],16,30,4,[.8,.7],[1.5,1.3],[1,2],1,0,None,22),
 ("Blink","shorter lifetime",[5,5],18,30,4,[.8,.7],[1.4,1.2],[2,2],1,0,None,22),
 ("Flicker","short + two live",[5,5],20,32,4,[.75,.65],[1.3,1.1],[2,3],1,0,None,25),
 ("Snap Pairs","short doubles",[5,5],22,32,3,[.8,.7],[1.25,1.0],[2,3],2,0,None,25),
 ("Lightning","peak",[5,5],28,36,3,[.65,.5],[1.15,.95],[3,4],2,0,None,30),
 ("Breather","short, calm",[5,5],16,32,5,[.9,.8],[1.6,1.45],[1,2],1,0,None,25),
 ("Fast Pairs","short doubles",[5,5],22,34,4,[.8,.7],[1.2,1.05],[2,3],2,0,None,28),
 ("Three Flash","short, three live",[5,5],24,34,3,[.75,.65],[1.15,1.0],[3,3],2,0,None,28),
 ("Strobe","short, four live",[5,5],26,35,3,[.7,.6],[1.1,.95],[3,4],2,0,None,30),
 ("Overdrive","peak",[5,5],32,40,3,[.6,.45],[1.05,.85],[3,4],2,0,None,34),
 # Block 3 — patterns and don't-tap decoys
 ("Merry-go-round","fixed pattern",[5,6],16,32,4,[.85,.75],[1.6,1.4],[1,2],1,0,ring5x6,25),
 ("Don't Touch","decoys",[5,6],18,34,4,[.85,.75],[1.6,1.4],[1,2],1,.15,None,25),
 ("Zigzag","pattern + decoys",[5,6],20,34,4,[.8,.7],[1.5,1.3],[2,2],1,.1,zig5x6,25),
 ("Minefield","decoys in pairs",[5,6],22,35,4,[.85,.75],[1.5,1.3],[2,3],2,.2,None,28),
 ("Trapdoor","peak",[5,6],26,38,3,[.75,.6],[1.3,1.1],[2,3],2,.25,ring5x6,30),
 ("Easy Does It","decoys, calm",[5,6],18,34,4,[.9,.8],[1.7,1.5],[2,2],1,.15,None,25),
 ("Diagonals","paired pattern",[5,6],22,35,4,[.85,.75],[1.5,1.3],[2,3],2,0,diag5x6,28),
 ("Crossfire","pattern + decoys",[5,6],24,36,4,[.8,.7],[1.45,1.25],[3,3],2,.2,cross5x6,30),
 ("Hazard","many decoys",[5,6],26,38,4,[.75,.65],[1.3,1.1],[3,4],2,.25,None,32),
 ("Grand Finale","peak",[5,6],34,44,4,[.7,.55],[1.2,.95],[3,4],2,.25,None,36),
]
bot=None
if len(sys.argv)>1:
    bot=json.load(open(sys.argv[1]))
def med(xs):
    xs=sorted(xs); return xs[len(xs)//2]
levels=[]
for i,(name,el,board,goal,t,mm,si,lt,ma,sim,dc,pat,xe) in enumerate(L,1):
    block=(i-1)//10
    goal=int(round(goal*1.6))
    # shorter lifetimes from block 2 on, faster spawns overall
    lt=[round(lt[0]*(0.92 if block==0 else 0.8),2), round(lt[1]*(0.9 if block==0 else 0.78),2)]
    si=[round(si[0]*0.9,2), round(si[1]*0.85,2)]
    xe=int(round(goal*0.5))
    if bot:
        c=bot["casual"][str(i)]; k=bot["skilled"][str(i)]
        ct=med([r["time"] for r in c]); kt=med([r["time"] for r in k])
        t=int(round(ct*1.45+2))
        st={"3":{"time":round(kt*1.12+0.5,1),"mistakes":1 if mm>=4 else 0},"2":{"time":round(ct*1.1+1,1),"mistakes":max(mm-2,1)}}
    else:
        t=120
        st={"3":{"time":0,"mistakes":0},"2":{"time":0,"mistakes":0}}
    l={"id":i,"name":name,"element":el,"board":board,"goal":goal,"time_limit":t,"max_mistakes":mm,
       "difficulty":{"axis":"time","x_start":0,"x_end":xe,"easing":"linear","params":{"spawn_interval":si,"lifetime":lt,"max_active":ma,"simultaneous_targets":sim}}}
    if dc: l["decoy_chance"]=dc
    if pat:
        l["pattern"]=[[p] if isinstance(p,int) else p for p in pat]; l["pattern_loop"]=True
    l["stars"]=st
    levels.append(l)
out={"defaults":{"board":[4,5],"goal":15,"time_limit":40,"max_mistakes":3,"decoy_chance":0.0,
     "difficulty":{"axis":"time","x_start":0,"x_end":30,"easing":"linear","params":{"spawn_interval":[0.9,0.7],"lifetime":[2.0,1.6],"max_active":[1,2],"simultaneous_targets":1}}},
     "levels":levels}
# compact-ish: one level per line
s='{\n  "defaults": '+json.dumps(out["defaults"])+',\n  "levels": [\n'+',\n'.join('    '+json.dumps(l) for l in levels)+'\n  ]\n}\n'
open(__import__('os').path.join(__import__('os').path.dirname(__file__), '..', 'data', 'stages', 'stages.json'),'w').write(s)
print(len(levels))
