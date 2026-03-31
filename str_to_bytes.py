string = 'echo'
print(len(string))
out = []
for char in string:
    out.append("$" + hex(ord(char) - 32)[2:])

print(f".byte {', '.join(out)}, $ff")