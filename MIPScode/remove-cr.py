import os

def remove_cr(path):
    with open(path, "rb") as f:
        s = f.read()
    with open(path + ".bak", "wb") as f:
        f.write(s)
    with open(path, "wb") as f:
        f.write(s.replace(b"\r", b""))

def search_dir(path):
    files = [os.path.join(path, f) for f in os.listdir(path)]
    ret = []
    for f in files:
        if f.endswith(".txt"):
            ret.append(f)
        elif os.path.isdir(f):
            ret += search_dir(f)
        else:
            continue # skip other files
    return ret

def process_dir(path):
    files = search_dir(path)
    print("The following files will have their CR (carriage return) characters removed.",
          "Each file will be backed up to <filename>.bak before modification.\n",
          *files, sep="\n")
    if input("Proceed? [y/N] ") in ("y", "Y"):
        for f in files:
            remove_cr(f)
        print("CR characters removed.")
    else:
        print("Aborted.")


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        path = sys.argv[1]
        if not os.path.isdir(path):
            print("Argument has to be a directory.")
            exit(1)
        process_dir(path)
    else:
        process_dir(".")