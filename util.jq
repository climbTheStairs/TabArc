def sel(e): select(e);
def len: length;

def obj(k; v): map({key: k | tostring, value: v}) | from_entries;
def grpby_toobj(e): group_by(e) | obj((.[0] | e); .);
def addidxprop: to_entries | map(.value + {i: .key});
def esc: gsub("\\\\"; "\\\\") | gsub("\n"; "\\n") | gsub("\t"; "\\t");
def bool2int: if . then 1 else 0 end;
